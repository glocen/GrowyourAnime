--!strict
-- Chests (shared, pure): what a fall drops and what an opened chest gives (docs/engineering-plan.md, "Chests"; the rework's
-- part 11). Every number is Config.Chests'. The server draws every roll from its own random source inside the transaction
-- (`draw`), never from the client, and runs each open as one transaction with its op id (Services.Main.RegaliaService),
-- so a repeat answers its first answer and nothing is half-granted: the chests leave the bag in the same step that writes
-- every item.
--   A drop     an elite's chest always, a Shade's at its chance, and one sure on the account's Sure-th kill (Drops.Give);
--              a keeper's from its win (Progress.KeeperWon): the better tier on the first
--   A roll     its rarity from the ladder, then one of the fourteen slots alike, a weapon's class (the lead's ClassLean,
--              else one of the other classes owned), the row, its main stat and its lines, each priced in Combat Power
--   Salvage    an opened item of Settings.Salvage's rarity or under turns into Credits, unless it would raise the
--              Combat Power of its class's best Voidkin, or any class's for a piece every class wears (Keep)
--   No gear    an Emblem Case, a Jewel Pouch or a Forge Crate (Definitions.Chests' Others; the director's "ok" of
--              2026-11-24): what it holds into the bag's stacks, so it takes no room in the bag and is never salvaged
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local ChestsConfig = require(Shared.Config.Chests)
local StatsConfig = require(Shared.Config.Stats)
local ChestRows = require(Shared.Definitions.Chests)
local Items = require(Shared.Definitions.Items)
local Gear = require(Shared.Definitions.Gear)
local Grounds = require(Shared.Definitions.Grounds)
local Attributes = require(Shared.Definitions.Attributes)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)
local JewelsConfig = require(Shared.Config.Jewels)
local ReinforceConfig = require(Shared.Config.Reinforce)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Emblems = require(Shared.Rules.Emblems)
local Jewels = require(Shared.Rules.Jewels)

local Chests = {}

Chests.Unknown = "Unknown" -- no such chest, or a count that isn't one, or more than one step opens
Chests.NotEnough = "NotEnough" -- fewer of that chest in the bag than asked
Chests.BagFull = "BagFull" -- the items would pass the bag's cap: nothing rolled, the chests kept
Chests.NotOwned = "NotOwned" -- no such item in the save
Chests.Worn = "Worn" -- a preset wears the item: it's taken off before it can be salvaged

-- A number in [0, 1): the server's random source, or a case's own sequence.
export type Draw = () -> number

export type Rolled = {
	Def: string,
	Tier: number,
	Rarity: string,
	Design: number, -- drawn last, so a design never moves what was drawn before it
	Lines: { Profile.ItemLine }, -- the first is the main stat, fixed by its slot (a jewel's rolled)
	Sockets: { string },
}

local function sorted(keys: { [string]: any }): { string }
	local out = {}
	for key in keys do
		table.insert(out, key)
	end
	table.sort(out)
	return out
end

local SLOTS: { string } = table.clone(Gear.Hands)
for _, slot in Gear.Shared do
	table.insert(SLOTS, slot)
end
local CLASSES = sorted(Gear.Weapons)
local POOL = sorted(ChestsConfig.Pool)

-- One of `keys` by `weights`, for `u` in [0, 1); nil when none weighs anything.
local function pick(weights: { [string]: number }, keys: { string }, u: number): string?
	local total = 0
	for _, key in keys do
		total += math.max(0, weights[key] or 0)
	end
	if total <= 0 then
		return nil
	end
	local at = u * total
	local last = nil
	for _, key in keys do
		local weight = math.max(0, weights[key] or 0)
		if weight > 0 then
			if at < weight then
				return key
			end
			at -= weight
			last = key
		end
	end
	return last
end

local function index(count: number, u: number): number
	return math.clamp(math.floor(u * count) + 1, 1, count)
end

-- What one point of `stat` is worth in Combat Power before its scale, at the generic row (no Main): a Battle
-- Attribute's weight, an attribute's conversion row weighed (the rework's part 2, "A line's price").
function Chests.Price(stat: string): number
	local weights = StatsConfig.Power.Weights
	local row = StatsConfig.Attributes.Convert[stat]
	if row then
		local price = 0
		for into, rate in row do
			price += rate * (weights[into] or 0)
		end
		return price
	end
	return weights[stat] or 0
end

-- The rarity ladder's row a chest reads. A Tower chest reads its own row (Chests.Weights); its step only orders the bag.
function Chests.Step(chest: ChestRows.Row): number
	local ground = Grounds.ById[chest.Ground]
	local past = if chest.Difficulty == "Hard" then ChestsConfig.Hard.Rows else 0
	return math.clamp((if ground then ground.Order else 1) + chest.Tier - 1 + past, 1, #ChestsConfig.Ladder)
end

-- The least shares a ladder chest keeps, by rarity, in percent of its roll (TR48 part 2): every chest's
-- (Config.Chests.Least), and on Hard a keeper's after its first win (its tier-2 chest on the stage the keeper ends) or an
-- elite's (any other tier-2 chest) raised by Config.Chests.Hard.Least.
function Chests.Least(chest: ChestRows.Row): { [string]: number }
	local least = table.clone(ChestsConfig.Least)
	if chest.Difficulty == "Hard" and chest.Tier == ChestsConfig.Keeper.After then
		local keeper = chest.Stage == ChestRows.KeeperStage[chest.Ground]
		for name, share in ChestsConfig.Hard.Least[if keeper then "Keeper" else "Elite"] or {} do
			least[name] = math.max(least[name] or 0, share)
		end
	end
	return least
end

-- The rarity weights a chest rolls by, Common to Legendary: the Tower's own row for a Tower chest; a keeper's first
-- win's chest none under its difficulty's floor (Config.Chests.Keeper.FirstFloor, TR48); else its ladder row, each
-- rarity raised to its least share (Chests.Least), the difference taken from Common.
function Chests.Weights(chest: ChestRows.Row): { number }
	if chest.Tier == ChestRows.Tower then
		return ChestsConfig.Tower
	end
	local row = ChestsConfig.Ladder[Chests.Step(chest)]
	local floor = if chest.Tier == ChestsConfig.Keeper.First then ChestsConfig.Keeper.FirstFloor[chest.Difficulty] else nil
	local lowest = if floor then table.find(ChestsConfig.Rarities, floor) else nil
	local weights = table.clone(row)
	if lowest then
		for i = 1, lowest - 1 do
			weights[i] = 0
		end
		return weights
	end
	local total = 0
	for _, weight in row do
		total += weight
	end
	for name, share in Chests.Least(chest) do
		local i = table.find(ChestsConfig.Rarities, name)
		local want = total * share / 100
		if i and i > 1 and (weights[i] or 0) < want then
			weights[1] -= want - (weights[i] or 0)
			weights[i] = want
		end
	end
	return weights
end

-- Each rarity's chance from a chest, as its roll draws it: a gear chest's item's, an Emblem Case's emblem's (its ladder
-- row's, Common counted as Uncommon), none for a chest that holds neither.
function Chests.Odds(chest: ChestRows.Row): { [string]: number }
	local out = {}
	if chest.Kind == "Emblem" then
		local weights = Emblems.Weights(ChestsConfig.Ladder[Chests.Step(chest)])
		local total = 0
		for _, weight in weights do
			total += weight
		end
		for _, name in ChestsConfig.Rarities do
			out[name] = if total > 0 then (weights[name] or 0) / total else 0
		end
		return out
	elseif chest.Kind ~= "Gear" then
		return out
	end
	local row = Chests.Weights(chest)
	local total = 0
	for _, weight in row do
		total += weight
	end
	for i, name in ChestsConfig.Rarities do
		out[name] = if total > 0 then (row[i] or 0) / total else 0
	end
	return out
end

export type Line = { Name: string, Rarity: string, Chance: number }

-- What a chest's card says it gives, a line each with its chance: a rarity's for gear and an Emblem Case (those it can
-- give), a jewel's level for a Jewel Pouch, the stones for a Forge Crate (each line its own chance).
function Chests.Lines(chest: ChestRows.Row): { Line }
	local out: { Line } = {}
	if chest.Kind == "Jewel" then
		local up = ChestsConfig.Pouch.Up
		table.insert(out, { Name = "A level 1 jewel", Rarity = "", Chance = 1 - up })
		table.insert(out, { Name = "A level 2 jewel", Rarity = "", Chance = up })
		return out
	elseif chest.Kind == "Stone" then
		local crate, grades = ChestsConfig.Crate, ReinforceConfig.Grades
		table.insert(out, { Name = `{crate.Low[1]} to {crate.Low[2]} {grades[1]} stones`, Rarity = "", Chance = 1 })
		table.insert(out, { Name = `A {grades[2]} stone`, Rarity = "", Chance = crate.Mid })
		table.insert(out, { Name = `A {grades[3]} stone`, Rarity = "", Chance = crate.High })
		return out
	end
	local odds = Chests.Odds(chest)
	for _, name in ChestsConfig.Rarities do
		if (odds[name] or 0) > 0 then
			table.insert(out, { Name = name, Rarity = name, Chance = odds[name] })
		end
	end
	return out
end

-- Which class a weapon may be for, by weight: the lead's ClassLean, the rest shared by the other classes the player
-- owns; all the lead's when it's the only one; every class alike with no lead.
function Chests.Classes(data: Profile.Data): { [string]: number }
	local lead = data.Voidkin[data.Roles.Lead]
	local leadRow = if lead then Voidkin.ById[lead.Def] else nil
	local out: { [string]: number } = {}
	if leadRow == nil or Gear.Weapons[leadRow.Class] == nil then
		for _, class in CLASSES do
			out[class] = 1
		end
		return out
	end
	local others: { [string]: boolean } = {}
	for _, owned in data.Voidkin do
		local row = Voidkin.ById[owned.Def]
		if row and row.Class ~= leadRow.Class and Gear.Weapons[row.Class] then
			others[row.Class] = true
		end
	end
	local count = #sorted(others)
	if count == 0 then
		out[leadRow.Class] = 1
		return out
	end
	out[leadRow.Class] = ChestsConfig.ClassLean
	for class in others do
		out[class] = (1 - ChestsConfig.ClassLean) / count
	end
	return out
end

local function line(stat: string, worth: number, draw: Draw): Profile.ItemLine
	local quality = 1 + ChestsConfig.Spread * (2 * draw() - 1)
	local price = Chests.Price(stat)
	local value = if price > 0 then worth / price * quality else 0
	return { Stat = stat, Value = math.max(1, math.floor(value + 0.5)) }
end

-- One item from `chest`, every roll from `draw`, in a fixed order: rarity, slot, a hand's class, the row, a jewel's main,
-- the main's quality, then each line's stat and quality. `classes` is Chests.Classes'. `override`, rarity weights
-- Common to Legendary, stands in for the chest's own (the Void Shop's featured piece, Rules.Shop).
function Chests.Roll(chest: ChestRows.Row, classes: { [string]: number }, draw: Draw, override: { number }?): Rolled
	local ground = Grounds.ById[chest.Ground]
	local tier = if ground then ground.Order else 1
	local top = chest.Level or (if ground then ground.LevelTo else 1) -- a Hard stage's: its own level (TR48)
	local ladder = override or Chests.Weights(chest)
	local weights: { [string]: number } = {}
	for i, name in ChestsConfig.Rarities do
		weights[name] = ladder[i] or 0
	end
	local rarity = pick(weights, ChestsConfig.Rarities, draw()) or ChestsConfig.Rarities[1]
	local slot = SLOTS[index(#SLOTS, draw())]
	local class = if Gear.IsHand(slot) then pick(classes, CLASSES, draw()) else nil
	local fits: { Items.Row } = {}
	for _, row in Items.List do
		if Items.Fits(row, slot, class) then
			table.insert(fits, row)
		end
	end
	local row = fits[index(#fits, draw())]
	local worth = ChestsConfig.PowerPerG * (ChestsConfig.Rarity[rarity] or 1) * Growth.G(top)
	local main = ChestsConfig.Main[row.Slot] or Attributes.Ids[index(#Attributes.Ids, draw())]
	local lines = { line(main, worth * ChestsConfig.MainShare, draw) }
	local pool = table.clone(ChestsConfig.Pool)
	pool[main] = nil
	local classMain = if row.Class then StatsConfig.Attributes.Main[row.Class] else nil
	if classMain and pool[classMain.Attribute] then
		pool[classMain.Attribute] *= ChestsConfig.MainLean
	end
	local count = ChestsConfig.Lines[rarity] or 1
	for _ = 1, count do
		local stat = pick(pool, POOL, draw())
		if stat == nil then
			break
		end
		pool[stat] = nil
		table.insert(lines, line(stat, worth * (1 - ChestsConfig.MainShare) / count, draw))
	end
	local sockets = {}
	for _ = 1, ChestsConfig.Sockets[rarity] or 0 do
		table.insert(sockets, "")
	end
	local design = index(math.max(Items.Designs(row.Id, rarity), 1), draw())
	return { Def = row.Id, Tier = tier, Rarity = rarity, Design = design, Lines = lines, Sockets = sockets }
end

-- What salvaging an item gives, in Credits.
function Chests.Salvage(item: { Tier: number, Rarity: string }): number
	local ground = Grounds.List[item.Tier]
	return math.floor((ChestsConfig.Salvage[item.Rarity] or 0) * Growth.G(if ground then ground.LevelTo else 1) + 0.5)
end

-- Each class's best owned Voidkin, by Combat Power's unrounded sum in its own preset, the first by Id on a tie: who the salvage protects
-- (docs/design.md, "Chests", "Auto-salvage"). A class the player owns none of has no entry.
function Chests.For(data: Profile.Data): { [string]: Profile.OwnedVoidkin }
	local out: { [string]: Profile.OwnedVoidkin } = {}
	local most: { [string]: number } = {}
	for _, id in sorted(data.Voidkin) do
		local owned = data.Voidkin[id]
		local row = Voidkin.ById[owned.Def]
		if row and Gear.Weapons[row.Class] then
			local power = Stats.Sum((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
			if most[row.Class] == nil or power > most[row.Class] then
				out[row.Class], most[row.Class] = owned, power
			end
		end
	end
	return out
end

-- Whether the salvage must keep item `id`: it would raise the Combat Power of its class's best Voidkin, or for a piece
-- every class wears, of any class's best (`best` is Chests.For's). A class owned by nobody protects nothing. The gain is
-- the unrounded sum's (Stats.Compare), so one too small to move the shown figure is still kept (D3, 2026-11-18).
function Chests.Keep(data: Profile.Data, id: string, best: { [string]: Profile.OwnedVoidkin }): boolean
	local item = data.Items[id]
	local row = if item then Items.ById[item.Def] else nil
	if row == nil then
		return false
	end
	for _, class in CLASSES do
		local who = best[class]
		if who and (row.Class == nil or row.Class == class) then
			local change = Stats.Compare(data, Stats.PresetOf(data, who), who, id)
			if change ~= nil and change.Power > 0 then
				return true
			end
		end
	end
	return false
end

-- Puts `count` of chest `id` in the bag.
function Chests.Grant(data: Profile.Data, id: string, count: number)
	data.Bag.Chests[id] = (data.Bag.Chests[id] or 0) + count
end

-- The chest a fall of `kind` in ground `ground` drops for `u` in [0, 1), or nil: on Hard, its `stage`'s own (TR48).
-- `kills` is the account's kills before this one. A keeper's comes from its win, never here.
function Chests.Dropped(kind: string, ground: string, kills: number, u: number?, difficulty: string?, stage: number?): string?
	local drop = ChestsConfig.Drop[kind]
	if drop == nil then
		return nil
	end
	local sure = kind == "Ordinary" and kills + 1 == ChestsConfig.Sure
	if not sure and not (type(u) == "number" and u < drop.Chance) then
		return nil
	end
	local row = ChestRows.Of(ground, drop.Tier, difficulty, stage) or ChestRows.Of(ground, drop.Tier)
	return if row then row.Id else nil
end

-- The chest a keeper's win in ground `ground` on `difficulty` gives, the better on that difficulty's first (`wins`
-- counts this one), or nil. On Hard, the keeper's stage's own (TR48).
function Chests.KeeperChest(ground: string, wins: number, difficulty: string?): string?
	local tier = if wins <= 1 then ChestsConfig.Keeper.First else ChestsConfig.Keeper.After
	local row = ChestRows.Of(ground, tier, difficulty, ChestRows.KeeperStage[ground]) or ChestRows.Of(ground, tier)
	return if row then row.Id else nil
end

-- One no-gear chest's contents for `draw`, as bag keys and counts, in a fixed order: an Emblem Case's rarity, set and
-- stat; a Jewel Pouch's level, then colour; a Forge Crate's Low count, then whether a Mid, then whether a High. Nil
-- only when a case's ladder row weighs nothing.
local function holds(chest: ChestRows.Row, draw: Draw): { [string]: number }?
	if chest.Kind == "Emblem" then
		local key = Emblems.Roll(Emblems.Weights(ChestsConfig.Ladder[Chests.Step(chest)]), draw(), draw(), draw())
		return if key then { [key] = 1 } else nil
	elseif chest.Kind == "Jewel" then
		local level = if draw() < ChestsConfig.Pouch.Up then 2 else 1
		local colours = JewelsConfig.Colours
		return { [Jewels.Key(colours[index(#colours, draw())], level)] = 1 }
	end
	local crate, grades = ChestsConfig.Crate, ReinforceConfig.Grades
	local out = { [grades[1]] = crate.Low[1] + index(crate.Low[2] - crate.Low[1] + 1, draw()) - 1 }
	if draw() < crate.Mid then
		out[grades[2]] = 1
	end
	if draw() < crate.High then
		out[grades[3]] = 1
	end
	return out
end

-- The bag's stack a no-gear chest's contents go into.
local function stackOf(data: Profile.Data, kind: string): { [string]: number }
	return if kind == "Emblem" then data.Bag.Emblems elseif kind == "Jewel" then data.Bag.Jewels else data.Bag.Stones
end

-- Opens `count` of chest `id` (at most Config's Step and what's held), every roll from `draw`. The chests leave the bag
-- and every item is written in this one step; an item of the salvage's rarity or under that wouldn't raise Combat Power
-- turns into Credits. { Ok, Chest, Kind, Opened, Items (the ids kept), Salvaged, Credits }, or a refusal that changed
-- nothing. A chest that holds no gear needs no room and salvages nothing: { Ok, Chest, Kind, Opened, Gave }, Gave its
-- contents by key (an emblem's, a jewel's or a stone's grade) into the bag's stack of that kind.
function Chests.Open(data: Profile.Data, id: any, count: any, draw: Draw): { [string]: any }
	local chest = if type(id) == "string" then ChestRows.ById[id] else nil
	local valid = type(count) == "number" and count == math.floor(count) and count >= 1 and count <= ChestsConfig.Step
	if chest == nil or not valid then
		return { Ok = false, Error = Chests.Unknown }
	end
	local held = data.Bag.Chests[chest.Id] or 0
	if held < count then
		return { Ok = false, Error = Chests.NotEnough }
	end
	if chest.Kind ~= "Gear" then
		local gave: { [string]: number } = {}
		for _ = 1, count do
			local got = holds(chest, draw)
			if got == nil then
				return { Ok = false, Error = Chests.Unknown }
			end
			for key, n in got do
				gave[key] = (gave[key] or 0) + n
			end
		end
		data.Bag.Chests[chest.Id] = if held > count then held - count else nil
		local stack = stackOf(data, chest.Kind)
		for key, n in gave do
			stack[key] = (stack[key] or 0) + n
		end
		return { Ok = true, Chest = chest.Id, Kind = chest.Kind, Opened = count, Gave = gave }
	end
	local items = 0
	for _ in data.Items do
		items += 1
	end
	if items + count > ChestsConfig.Bag then
		return { Ok = false, Error = Chests.BagFull }
	end
	data.Bag.Chests[chest.Id] = if held > count then held - count else nil
	local classes = Chests.Classes(data)
	local below = Rarity.Rank[data.Settings.Salvage]
	local best = if below then Chests.For(data) else {}
	local kept, salvaged, credits = {}, 0, 0
	for _ = 1, count do
		local rolled = Chests.Roll(chest, classes, draw)
		local itemId = Profile.NewId(data)
		data.Items[itemId] = {
			Id = itemId,
			Def = rolled.Def,
			Tier = rolled.Tier,
			Rarity = rolled.Rarity,
			Design = rolled.Design,
			Lines = rolled.Lines,
			Sockets = rolled.Sockets,
			Reinforce = 0,
			Jewels = {},
		}
		if below and (Rarity.Rank[rolled.Rarity] or 0) <= below and not Chests.Keep(data, itemId, best) then
			data.Items[itemId] = nil
			salvaged += 1
			credits += Chests.Salvage(rolled)
		else
			table.insert(kept, itemId)
		end
	end
	data.Currency.Credits += credits
	return { Ok = true, Chest = chest.Id, Kind = chest.Kind, Opened = count, Items = kept, Salvaged = salvaged, Credits = credits }
end

-- Sets the salvage: opened items of rarity `below` or under turn into Credits, "" for none.
function Chests.SetSalvage(data: Profile.Data, below: any): { [string]: any }
	if below ~= "" and not (type(below) == "string" and table.find(ChestsConfig.Rarities, below) ~= nil) then
		return { Ok = false, Error = Chests.Unknown }
	end
	data.Settings.Salvage = below
	return { Ok = true, Salvage = below }
end

-- Whether any preset wears item `id`, in a shared slot or a class's hands.
function Chests.IsWorn(data: Profile.Data, id: string): boolean
	for _, preset in data.Presets do
		for _, worn in preset.Slots do
			if worn == id then
				return true
			end
		end
		for _, pair in preset.Hands do
			for _, worn in pair do
				if worn == id then
					return true
				end
			end
		end
	end
	return false
end

-- Salvages one owned item by the player's own hand: the item leaves the save and its Credits (Chests.Salvage) come in,
-- in this one step, so a full bag can be emptied (the director's design review, 2026-11-18: at the cap a chest is
-- refused, and nothing a player could do removed an item). An item any preset wears is refused, never taken off for
-- them. { Ok, Item, Credits }, or a refusal that changed nothing; a repeated request finds no item and is refused.
function Chests.SalvageItem(data: Profile.Data, id: any): { [string]: any }
	local item = if type(id) == "string" then data.Items[id] else nil
	if item == nil then
		return { Ok = false, Error = Chests.NotOwned }
	end
	if Chests.IsWorn(data, id) then
		return { Ok = false, Error = Chests.Worn }
	end
	local credits = Chests.Salvage(item)
	data.Items[id] = nil
	data.Currency.Credits += credits
	return { Ok = true, Item = id, Credits = credits }
end

return Chests
