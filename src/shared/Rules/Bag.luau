--!strict
-- Bag (shared, pure): what the Items page shows, read from a save (docs/research/rework-2026-11-16.md, part 5; AR18's C,
-- "the case"; docs/design.md, "The bag"). The screen draws these and nothing else, so what a cell says is what a case
-- checks.
--   Kinds    the strip's six: All, Weapons, Armour, Jewellery, Chests, Materials (research's pick on AR18's fix 4)
--   List     a kind's cells for the Voidkin shown, sorted: each item with its rarity, whether its class can wear it,
--            whether it's worn, and what wearing it would change in Combat Power (the up arrow when it's a gain)
--   Groups   the belt's three: the hands, the body, the jewellery; a narrow screen shows the chosen item's group
--   Card     a chosen item against what it replaces: each Basic Attribute and each Battle Attribute it changes
-- Every comparison is Stats.Compare, the resolver run twice, so it never drifts from the fight. No Roblox API: it runs
-- with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Gear = require(Shared.Definitions.Gear)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local ChestRows = require(Shared.Definitions.Chests)
local ChestsConfig = require(Shared.Config.Chests)
local Stats = require(Shared.Rules.Stats)
local Chests = require(Shared.Rules.Chests)
local Regalia = require(Shared.Rules.Regalia)

local Bag = {}

Bag.Kinds = { "All", "Weapons", "Armour", "Jewellery", "Chests", "Materials" }
Bag.Sorts = { "Rarity", "Power", "New" }
Bag.Cap = ChestsConfig.Bag
Bag.Groups = {
	{ "Main Hand", "Off Hand" },
	{ "Helmet", "Shoulders", "Chest Armor", "Gloves", "Bracers", "Boots" },
	{ "Cloak", "Amulet", "Ring I", "Ring II", "Earring I", "Earring II" },
}
Bag.Battle = 6 -- the card's Battle rows at most: the ones the item changes, in the sheet's order

local JEWELLERY: { [string]: boolean } = { Amulet = true, Ring = true, Earring = true }

export type Entry = {
	Kind: string, -- "Item", "Chest" or "Shard"
	Id: string, -- an item's id; a chest's or a shard's definition
	Def: string,
	Rarity: string, -- an item's; the Voidkin a shard holds, or Common; "" for a chest, which takes no rarity's frame
	Count: number, -- 1 for an item
	Fits: boolean, -- the shown Voidkin's class can wear it (always, for what isn't an item)
	Class: string?, -- a weapon's class
	Worn: string?, -- the slot the shown Voidkin wears it in
	Gain: number, -- what wearing it would change in Combat Power for the shown Voidkin; 0 when it can't, or wears it
	Up: boolean, -- a gain: the up arrow
	Slot: string?, -- where it would go: its comparison's slot, its worn slot, or its row's first
	New: number, -- the order it came in (an item's id), 0 for the rest
}

export type Line = { Stat: string, Value: number, Change: number }

export type Card = {
	Id: string,
	Def: string,
	Name: string,
	Rarity: string,
	Kind: string, -- what the row is: "Sword", "Ring"
	Class: string?,
	Fits: boolean,
	Worn: string?,
	Slot: string, -- the slot it would go in, or is in
	Power: number, -- Combat Power's change: wearing it, or taking it off when it's worn
	Basic: { Line }, -- each Basic Attribute, with its change
	Battle: { Line }, -- the Battle Attributes it changes, at most Bag.Battle
	Replaces: string?, -- the item in that slot now, when there's one and it isn't this
	Lines: { Profile.ItemLine }, -- its own rolled lines, the main stat first
}

-- Which of the strip's kinds an item row is.
function Bag.KindOf(row: Items.Row): string
	if row.Class then
		return "Weapons"
	end
	return if JEWELLERY[row.Slot] then "Jewellery" else "Armour"
end

-- The belt's group a slot is in, 1 to 3.
function Bag.GroupOf(slot: string): number
	for index, group in Bag.Groups do
		if table.find(group, slot) then
			return index
		end
	end
	return 1
end

local function classOf(owned: Profile.OwnedVoidkin?): string?
	local row = if owned then Voidkin.ById[owned.Def] else nil
	return if row then row.Class else nil
end

-- What the shown Voidkin wears, slot to item id: its preset's shared slots and its own class's pair.
function Bag.Worn(data: Profile.Data, owned: Profile.OwnedVoidkin?): { [string]: string }
	local out: { [string]: string } = {}
	local preset = if owned then Stats.PresetOf(data, owned) else nil
	if preset == nil then
		return out
	end
	for slot, id in preset.Slots do
		if data.Items[id] then
			out[slot] = id
		end
	end
	local class = classOf(owned)
	local pair = if class and preset.Hands then preset.Hands[class] else nil
	for slot, id in pair or {} do
		if data.Items[id] then
			out[slot] = id
		end
	end
	return out
end

local function number(id: string): number
	return tonumber(string.match(id, "%d+$") or "") or 0
end

local function rank(rarity: string): number
	return Rarity.Rank[rarity] or 0
end

local function items(data: Profile.Data, owned: Profile.OwnedVoidkin?, kind: string): { Entry }
	local worn = Bag.Worn(data, owned)
	local at: { [string]: string } = {}
	for slot, id in worn do
		at[id] = slot
	end
	local class = classOf(owned)
	local preset = if owned then Stats.PresetOf(data, owned) else nil
	local before = if owned then Stats.Resolve(owned, preset, data) else nil
	local out: { Entry } = {}
	for id, item in data.Items do
		local row = Items.ById[item.Def]
		if row == nil or (kind ~= "All" and Bag.KindOf(row) ~= kind) then
			continue
		end
		local fits = row.Class == nil or row.Class == class
		local gain, slot = 0, at[id]
		if owned and fits and slot == nil then
			local change = Stats.Compare(data, preset, owned, id, nil, before)
			if change then
				gain, slot = change.Power, change.Slot
			end
		end
		table.insert(out, {
			Kind = "Item",
			Id = id,
			Def = item.Def,
			Rarity = item.Rarity,
			Count = 1,
			Fits = fits,
			Class = row.Class,
			Worn = at[id],
			Gain = gain,
			Up = gain > 0,
			Slot = slot or Gear.SlotsOf(row.Slot)[1],
			New = number(id),
		})
	end
	return out
end

local ORDER: { [string]: (Entry, Entry) -> boolean } = {
	Rarity = function(a: Entry, b: Entry): boolean
		if rank(a.Rarity) ~= rank(b.Rarity) then
			return rank(a.Rarity) > rank(b.Rarity)
		end
		if a.Gain ~= b.Gain then
			return a.Gain > b.Gain
		end
		return a.New > b.New
	end,
	Power = function(a: Entry, b: Entry): boolean
		if a.Gain ~= b.Gain then
			return a.Gain > b.Gain
		end
		if rank(a.Rarity) ~= rank(b.Rarity) then
			return rank(a.Rarity) > rank(b.Rarity)
		end
		return a.New > b.New
	end,
	New = function(a: Entry, b: Entry): boolean
		return a.New > b.New
	end,
}

-- A kind's cells for `owned` (nil: no Voidkin, so nothing raises anything), sorted by `sort`: items first, then the
-- chests, the richest first, then the materials. An unknown kind or sort reads as All and Rarity.
function Bag.List(data: Profile.Data, owned: Profile.OwnedVoidkin?, kind: string, sort: string): { Entry }
	local known = if table.find(Bag.Kinds, kind) then kind else "All"
	local out: { Entry } = {}
	if known ~= "Chests" and known ~= "Materials" then
		out = items(data, owned, known)
		table.sort(out, ORDER[sort] or ORDER.Rarity)
	end
	if known == "All" or known == "Chests" then
		local chests: { Entry } = {}
		for id, count in data.Bag.Chests do
			local row = ChestRows.ById[id]
			if row and count > 0 then
				-- No rarity: a rarity's frame says what a thing is, and on a chest it would say what it might be (research,
				-- TR29; docs/ui.md, "Stats, shown honestly"). Its odds are on its card.
				table.insert(chests, { Kind = "Chest", Id = id, Def = id, Rarity = "", Count = count, Fits = true, Worn = nil, Gain = 0, Up = false, New = Chests.Step(row) * 10 + row.Tier })
			end
		end
		table.sort(chests, function(a: Entry, b: Entry): boolean
			if a.New ~= b.New then
				return a.New > b.New
			end
			return a.Id < b.Id
		end)
		for _, entry in chests do
			table.insert(out, entry)
		end
	end
	if known == "All" or known == "Materials" then
		local shards: { Entry } = {}
		for id, count in data.Bag.Shards do
			local row = Shards.ById[id]
			if row and count > 0 then
				local holds = if row.Holds ~= "" then Voidkin.ById[row.Holds] else nil
				table.insert(shards, { Kind = "Shard", Id = id, Def = id, Rarity = if holds then holds.Rarity else "Common", Count = count, Fits = true, Worn = nil, Gain = 0, Up = false, New = 0 })
			end
		end
		table.sort(shards, function(a: Entry, b: Entry): boolean
			return a.Id < b.Id
		end)
		for _, entry in shards do
			table.insert(out, entry)
		end
	end
	return out
end

-- How many of the bag's places the items take: the count against Bag.Cap.
function Bag.Held(data: Profile.Data): number
	local held = 0
	for _ in data.Items do
		held += 1
	end
	return held
end

-- A chosen item's card for `owned`: against what it would replace, or for a worn one, what taking it off would do. A
-- weapon of another class gets its lines and Fits false, nothing compared. Nil for an item the save doesn't hold.
function Bag.Card(data: Profile.Data, owned: Profile.OwnedVoidkin?, id: string): Card?
	local item = data.Items[id]
	local row = if item then Items.ById[item.Def] else nil
	if item == nil or row == nil then
		return nil
	end
	local class = classOf(owned)
	local worn = Bag.Worn(data, owned)
	local wornAt: string? = nil
	for slot, at in worn do
		if at == id then
			wornAt = slot
		end
	end
	local card: Card = {
		Id = id,
		Def = item.Def,
		Name = row.Name,
		Rarity = item.Rarity,
		Kind = row.Kind,
		Class = row.Class,
		Fits = row.Class == nil or row.Class == class,
		Worn = wornAt,
		Slot = wornAt or Gear.SlotsOf(row.Slot)[1],
		Power = 0,
		Basic = {},
		Battle = {},
		Replaces = nil,
		Lines = table.clone(item.Lines),
	}
	if owned == nil or not card.Fits then
		return card
	end
	local preset = Stats.PresetOf(data, owned)
	local before = Stats.Resolve(owned, preset, data)
	local after: Stats.Block
	if wornAt then
		local trial: Profile.Preset = { Slots = if preset then table.clone(preset.Slots) else {}, Hands = {} }
		for which, pair in (if preset then preset.Hands else {}) :: { [string]: { [string]: string } } do
			trial.Hands[which] = table.clone(pair)
		end
		Regalia.Put(trial, wornAt, class, nil)
		after = Stats.Resolve(owned, trial, data)
	else
		local change = Stats.Compare(data, preset, owned, id, nil, before)
		if change == nil then
			card.Fits = false
			return card
		end
		card.Slot = change.Slot
		card.Replaces = worn[change.Slot]
		after = change.After
	end
	card.Power = Stats.Power(after) - Stats.Power(before)
	for _, attribute in Attributes.Ids do
		table.insert(card.Basic, { Stat = attribute, Value = before.Attributes[attribute], Change = after.Attributes[attribute] - before.Attributes[attribute] })
	end
	for _, stat in Stats.Names do
		local was, now = (before :: any)[stat] :: number, (after :: any)[stat] :: number
		if math.abs(now - was) > 1e-9 and #card.Battle < Bag.Battle then
			table.insert(card.Battle, { Stat = stat, Value = was, Change = now - was })
		end
	end
	return card
end

-- What the chosen chest's card shows: its name, how many are held, the step one press opens, and each rarity's chance.
function Bag.Chest(data: Profile.Data, id: string): { [string]: any }?
	local row = ChestRows.ById[id]
	local held = data.Bag.Chests[id] or 0
	if row == nil or held <= 0 then
		return nil
	end
	local ground = Grounds.ById[row.Ground]
	local odds = {}
	local chances = Chests.Odds(row)
	for _, name in ChestsConfig.Rarities do
		if (chances[name] or 0) > 0 then
			table.insert(odds, { Rarity = name, Chance = chances[name] })
		end
	end
	return {
		Id = id,
		Name = row.Name,
		Ground = if ground then ground.Name else row.Ground,
		Tier = row.Tier,
		Held = held,
		-- What Open all opens, the number its button says (research, TR28's call 4): as many as are held, as one request
		-- takes, and as the bag has room for; 0 when it's full.
		Step = math.min(held, ChestsConfig.Step, math.max(0, Bag.Cap - Bag.Held(data))),
		Room = math.max(0, Bag.Cap - Bag.Held(data)),
		Odds = odds,
	}
end

return Bag
