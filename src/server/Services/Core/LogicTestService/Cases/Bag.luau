--!strict
-- Bag cases (pure): what the Items page shows (Rules.Bag; AR18's C; docs/research/rework-2026-11-16.md, part 5). The
-- belt's groups; each kind's cells; the up arrow exactly where the comparison gains; another class's weapon dimmed and
-- never compared; the sorts; the card against what it replaces, and a worn item's card as taking it off; a chest's card.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Items = require(Shared.Definitions.Items)
local ItemDesigns = require(Shared.Definitions.ItemDesigns)
local Gear = require(Shared.Definitions.Gear)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local ChestsConfig = require(Shared.Config.Chests)
local UIKit = require(Shared.Config.UIKit)
local ChestRows = require(Shared.Definitions.Chests)
local Collection = require(Shared.Rules.Collection)
local Regalia = require(Shared.Rules.Regalia)
local Stats = require(Shared.Rules.Stats)
local Chests = require(Shared.Rules.Chests)
local Bag = require(Shared.Rules.Bag)
local Sheet = require(Shared.Rules.Sheet)
local Growth = require(Shared.Rules.Growth)
local StatsConfig = require(Shared.Config.Stats)
local GrowthConfig = require(Shared.Config.Growth)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function uncover(data: Profile.Data, class: string): Profile.OwnedVoidkin
	for _, row in Voidkin.List do
		if row.Class == class then
			local owned = data.Voidkin[Collection.Uncover(data, row.Id, NOW).Id]
			owned.Level = 9
			return owned
		end
	end
	error(`no {class}`)
end

local function give(data: Profile.Data, def: string, rarity: string, lines: { Profile.ItemLine }): string
	local id = Profile.NewId(data)
	data.Items[id] = { Id = id, Def = def, Tier = 1, Rarity = rarity, Design = 1, Lines = lines, Sockets = {}, Jewel = "" }
	return id
end

-- A Warrior wearing a helmet and a sword, and a bag of eight more: better and worse pieces, a ring, another class's
-- weapon, a chest stack and shards.
local function stocked(): (Profile.Data, Profile.OwnedVoidkin, { [string]: string })
	local data = fresh()
	local warrior = uncover(data, "Warrior")
	data.Roles.Lead = warrior.Id
	local ids = {
		helmet = give(data, "helmet", "Uncommon", { { Stat = "Health", Value = 120 } }),
		sword = give(data, "sword", "Rare", { { Stat = "Attack", Value = 30 }, { Stat = "Might", Value = 4 } }),
		better = give(data, "helmet", "Epic", { { Stat = "Health", Value = 400 }, { Stat = "Vigor", Value = 9 } }),
		worse = give(data, "helmet", "Common", { { Stat = "Health", Value = 20 } }),
		boots = give(data, "boots", "Common", { { Stat = "Dodge", Value = 15 } }),
		ring = give(data, "ring", "Legendary", { { Stat = "Finesse", Value = 12 }, { Stat = "Critical", Value = 40 } }),
		staff = give(data, "staff", "Legendary", { { Stat = "Attack", Value = 90 }, { Stat = "Insight", Value = 20 } }),
		short = give(data, "short_sword", "Uncommon", { { Stat = "Attack", Value = 12 } }),
		cloak = give(data, "cloak", "Rare", { { Stat = "Block", Value = 25 } }),
	}
	Regalia.Put(data.Presets[1], "Helmet", nil, ids.helmet)
	Regalia.Put(data.Presets[1], "Main Hand", "Warrior", ids.sword)
	Chests.Grant(data, "lanternrow_1", 7)
	Chests.Grant(data, "drumcourt_3", 2)
	data.Bag.Shards.lanternrow_standard = 3
	return data, warrior, ids
end

local function find(list: { Bag.Entry }, id: string): Bag.Entry?
	for _, entry in list do
		if entry.Id == id then
			return entry
		end
	end
	return nil
end

return {
	{
		Name = "Bag: the belt's three groups hold the fourteen slots once each, and every row has its kind",
		Run = function(t: any)
			local seen: { [string]: number } = {}
			for index, group in Bag.Groups do
				for _, slot in group do
					seen[slot] = (seen[slot] or 0) + 1
					t.Equal(`{slot}: its group`, Bag.GroupOf(slot), index)
				end
			end
			for _, slot in Gear.Hands do
				t.Equal(`{slot}: once`, seen[slot], 1)
			end
			for _, slot in Gear.Shared do
				t.Equal(`{slot}: once`, seen[slot], 1)
			end
			for _, row in Items.List do
				local kind = Bag.KindOf(row)
				t.Check(`{row.Id}: a kind on the strip`, table.find(Bag.Kinds, kind) ~= nil, kind)
				t.Equal(`{row.Id}: a weapon is a weapon`, kind == "Weapons", row.Class ~= nil)
			end
			t.Equal("a ring is jewellery", Bag.KindOf(Items.ById.ring), "Jewellery")
			t.Equal("a cloak is armour", Bag.KindOf(Items.ById.cloak), "Armour")
			t.Equal("six kinds, All first", Bag.Kinds[1], "All")
			t.Equal(`the cap is the chests' bag's`, Bag.Cap, ChestsConfig.Bag)
		end,
	},
	{
		Name = "Bag: each kind's cells, the arrow exactly where wearing gains, another class's weapon dimmed and never compared",
		Run = function(t: any)
			local data, warrior, ids = stocked()
			local all = Bag.List(data, warrior, "All", "Rarity")
			t.Equal("every item, both chest stacks and the shards", #all, 9 + 2 + 1)
			local parts = 0
			for _, kind in { "Weapons", "Armour", "Jewellery" } do
				for _, entry in Bag.List(data, warrior, kind, "Rarity") do
					parts += 1
					t.Equal(`{entry.Id} in {kind}`, Bag.KindOf(Items.ById[entry.Def]), kind)
				end
			end
			t.Equal("the three item kinds split the items", parts, 9)
			t.Equal("chests: two stacks", #Bag.List(data, warrior, "Chests", "Rarity"), 2)
			t.Equal("materials: the shards", #Bag.List(data, warrior, "Materials", "Rarity"), 1)
			t.Equal("an unknown kind reads as All", #Bag.List(data, warrior, "Nonsense", "Rarity"), #all)
			local preset = Stats.PresetOf(data, warrior)
			for _, entry in all do
				if entry.Kind ~= "Item" then
					t.Check(`{entry.Id}: not an item, nothing compared`, entry.Fits and entry.Gain == 0 and not entry.Up)
					continue
				end
				local row = Items.ById[entry.Def]
				if row.Class and row.Class ~= "Warrior" then
					t.Check(`{entry.Id}: another class's, dimmed and never compared`, not entry.Fits and entry.Gain == 0 and not entry.Up and entry.Class == row.Class)
				elseif entry.Worn then
					t.Check(`{entry.Id}: worn, no arrow`, entry.Gain == 0 and not entry.Up and entry.Slot == entry.Worn)
				else
					local change = Stats.Compare(data, preset, warrior, entry.Id)
					t.Check(`{entry.Id}: its gain is the comparison's`, change ~= nil and math.abs(entry.Gain - change.Power) < 1e-9 and entry.Slot == change.Slot)
					t.Equal(`{entry.Id}: the arrow when it gains`, entry.Up, change ~= nil and change.Power > 0)
				end
			end
			t.Equal("the worn helmet", (find(all, ids.helmet) :: Bag.Entry).Worn, "Helmet")
			t.Equal("the worn sword", (find(all, ids.sword) :: Bag.Entry).Worn, "Main Hand")
			t.Check("the better helmet raises it", (find(all, ids.better) :: Bag.Entry).Up)
			t.Check("the worse one doesn't", not (find(all, ids.worse) :: Bag.Entry).Up)
			t.Check("the empty boots slot gains", (find(all, ids.boots) :: Bag.Entry).Up)
			t.Check("the Mage's staff is dimmed", not (find(all, ids.staff) :: Bag.Entry).Fits)
			local alone = Bag.List(data, nil, "All", "Rarity")
			for _, entry in alone do
				t.Check(`no Voidkin: {entry.Id} raises nothing`, not entry.Up and entry.Gain == 0)
			end
			local empty = fresh()
			t.Equal("an empty bag: no cells", #Bag.List(empty, nil, "All", "Rarity"), 0)
			t.Equal("held: the items", Bag.Held(data), 9)
		end,
	},
	{
		Name = "Bag: the sorts order the items by rarity, by gain, by arrival; the chests the richest first",
		Run = function(t: any)
			local data, warrior = stocked()
			local function ordered(sort: string, check: (Bag.Entry, Bag.Entry) -> boolean)
				local list = Bag.List(data, warrior, "All", sort)
				local last: Bag.Entry? = nil
				local items = 0
				for _, entry in list do
					if entry.Kind ~= "Item" then
						continue
					end
					items += 1
					if last then
						t.Check(`{sort}: {last.Id} then {entry.Id}`, check(last, entry))
					end
					last = entry
				end
				t.Equal(`{sort}: every item`, items, 9)
				t.Equal(`{sort}: items before the chests`, list[1].Kind, "Item")
				t.Equal(`{sort}: the shards last`, list[#list].Kind, "Shard")
			end
			ordered("Rarity", function(a: Bag.Entry, b: Bag.Entry): boolean
				local ra, rb = Rarity.Rank[a.Rarity], Rarity.Rank[b.Rarity]
				return ra > rb or (ra == rb and (a.Gain > b.Gain or (a.Gain == b.Gain and a.New > b.New)))
			end)
			ordered("Power", function(a: Bag.Entry, b: Bag.Entry): boolean
				return a.Gain >= b.Gain
			end)
			ordered("New", function(a: Bag.Entry, b: Bag.Entry): boolean
				return a.New > b.New
			end)
			local chests = Bag.List(data, warrior, "Chests", "New")
			t.Equal("Drum Court's Keeper's Chest first", chests[1].Id, "drumcourt_3")
			t.Equal("its count", chests[1].Count, 2)
			-- A chest takes no rarity's frame (research, TR29): it would say what it might be.
			t.Equal("no rarity on a chest, though it can give above Common", chests[1].Rarity, "")
			t.Check("(it can)", (Chests.Odds(ChestRows.ById.drumcourt_3).Rare or 0) > 0)
			t.Equal("Lantern Row's Shade Chest after, no rarity either", chests[2].Rarity, "")
		end,
	},
	{
		Name = "Bag: the card is the comparison against what it replaces, and a worn item's is taking it off",
		Run = function(t: any)
			local data, warrior, ids = stocked()
			local preset = Stats.PresetOf(data, warrior)
			local card = Bag.Card(data, warrior, ids.better) :: Bag.Card
			local change = Stats.Compare(data, preset, warrior, ids.better) :: Stats.Change
			t.Check("a card", card ~= nil and card.Fits and card.Slot == "Helmet")
			t.Check("its Combat Power is the comparison's", math.abs(card.Power - change.Power) < 1e-9 and card.Power > 0)
			t.Equal("it replaces the worn helmet", card.Replaces, ids.helmet)
			t.Equal("five Basic Attributes", #card.Basic, #Attributes.Ids)
			for index, basic in card.Basic do
				t.Equal(`{basic.Stat} in the sheet's order`, basic.Stat, Attributes.Ids[index])
				t.Check(`{basic.Stat}: its change`, math.abs(basic.Change - change.Attributes[basic.Stat]) < 1e-9)
			end
			t.Check("Battle rows, at most six", #card.Battle > 0 and #card.Battle <= Bag.Battle)
			local before = Stats.Resolve(warrior, preset, data)
			local oddsBefore = Sheet.Odds(before)
			local last = 0
			for _, battle in card.Battle do
				local at = table.find(Stats.Names, battle.Stat) :: number
				local want = if Sheet.Rated[battle.Stat] then Sheet.Odds(change.After)[battle.Stat] - oddsBefore[battle.Stat] else change.Battle[battle.Stat]
				t.Check(`{battle.Stat}: changed, in order`, battle.Change ~= 0 and at > last and math.abs(battle.Change - want) < 1e-9)
				last = at
			end
			t.Equal("its lines kept", #card.Lines, 2)
			-- A rating as the sheet shows it, its share against an even foe, never its points (the director, 2026-11-17,
			-- by 00:17: percents only, on every screen).
			for _, id in { ids.ring, ids.boots } do
				local rated = Bag.Card(data, warrior, id) :: Bag.Card
				local after = (Stats.Compare(data, preset, warrior, id) :: Stats.Change).After
				local stat = if id == ids.ring then "Critical" else "Dodge"
				local points = if id == ids.ring then 40 else 15
				local found = false
				for _, battle in rated.Battle do
					if battle.Stat == stat then
						found = true
						t.Check(`{stat}: its share before, and the share it adds`, math.abs(battle.Value - oddsBefore[stat]) < 1e-12 and math.abs(battle.Change - (Sheet.Odds(after)[stat] - oddsBefore[stat])) < 1e-12 and battle.Change > 0 and battle.Change < 1, `{battle.Value} {battle.Change}`)
					end
				end
				t.Check(`{stat}: on the card's comparison`, found)
				for _, line in rated.Lines do
					if line.Stat == stat then
						t.Check(`{stat} {points}: its line shows the share it would add`, math.abs(line.Value - Sheet.Adds(stat, points, before)) < 1e-12 and line.Value > 0 and line.Value < 1, `{line.Value}`)
					elseif line.Stat == "Finesse" then
						t.Equal("an attribute's line keeps its points", line.Value, 12)
					end
				end
			end
			t.Equal("nothing added adds nothing", Sheet.Adds("Dodge", 0, before), 0)
			local worn = Bag.Card(data, warrior, ids.helmet) :: Bag.Card
			t.Equal("the worn helmet's card says where", worn.Worn, "Helmet")
			t.Check("taking it off loses Combat Power", worn.Power < 0)
			t.Equal("and replaces nothing", worn.Replaces, nil)
			local ring = Bag.Card(data, warrior, ids.ring) :: Bag.Card
			t.Check("a ring goes to an empty ring slot, replacing nothing", ring.Slot == "Ring I" and ring.Replaces == nil and ring.Power > 0)
			local staff = Bag.Card(data, warrior, ids.staff) :: Bag.Card
			t.Check("the Mage's staff: its lines, nothing compared", not staff.Fits and staff.Class == "Mage" and staff.Power == 0 and #staff.Basic == 0 and #staff.Lines == 2)
			t.Equal("no such item: no card", Bag.Card(data, warrior, "k9999"), nil)
			local short = Bag.Card(data, warrior, ids.short) :: Bag.Card
			t.Check("the Warrior's off hand, empty: a gain, replacing nothing", short.Fits and short.Slot == "Off Hand" and short.Replaces == nil and short.Power > 0)
		end,
	},
	{
		-- Research's fix 2 to the rebuild in A (TR28, 22:37): the Bracers' +465 over Health +75 alone. It was right: a card
		-- shows every stat behind its number, and Health +75 is worth 0.62 × 75 × 10.
		Name = "Bag: a card's Combat Power is what its shown lines are worth, so none is hidden",
		Run = function(t: any)
			local power = StatsConfig.Power
			t.Equal("Health +75 alone is worth +465", math.floor(power.Weights.Health * 75 * power.Scale + 0.5), 465)
			local data, warrior, ids = stocked()
			local preset = Stats.PresetOf(data, warrior) :: Profile.Preset
			local before = Stats.Resolve(warrior, preset, data)
			local g = Growth.G(math.clamp(before.Level, 1, GrowthConfig.MaxLevel))
			-- The block the card compares against: the item worn in its slot, or a worn item taken off. A rating's row carries
			-- its share (Sheet.Rated), so its worth is read from the two blocks' points.
			local function afterOf(card: Bag.Card): Stats.Block
				if card.Worn then
					local trial: Profile.Preset = { Slots = table.clone(preset.Slots), Hands = {} }
					for which, pair in preset.Hands do
						trial.Hands[which] = table.clone(pair)
					end
					Regalia.Put(trial, card.Worn, Voidkin.ById[warrior.Def].Class, nil)
					return (Stats.Resolve(warrior, trial, data))
				end
				return (Stats.Compare(data, preset, warrior, card.Id) :: Stats.Change).After
			end
			local checked = 0
			for name, id in ids do
				local card = Bag.Card(data, warrior, id)
				if card == nil or not card.Fits or #card.Battle >= Bag.Battle then
					continue -- another class's, or a card at its cap of rows (none in the stock)
				end
				local after = afterOf(card)
				local shown: { [string]: boolean } = {}
				local sum = 0
				for _, line in card.Battle do
					shown[line.Stat] = true
					local weight = (power.Weights[line.Stat] or 0) * (if power.ByLevel[line.Stat] then g else 1)
					local function worth(value: number): number
						return if line.Stat == "CriticalDamage" then math.max(0, value - StatsConfig.CriticalDamage) else value
					end
					sum += weight * (worth((after :: any)[line.Stat]) - worth((before :: any)[line.Stat]))
				end
				for stat, weight in power.Weights do
					local was, now = (before :: any)[stat], (after :: any)[stat]
					if weight ~= 0 and type(was) == "number" and type(now) == "number" and math.abs(now - was) > 1e-9 then
						t.Check(`{name}: {stat} changes its worth, so it has its row`, shown[stat] == true)
					end
				end
				checked += 1
				t.Check(`{name}: its {card.Power} is its lines' {string.format("%.1f", sum * power.Scale)}`, math.abs(sum * power.Scale - card.Power) <= 1)
			end
			t.Check("every item that fits, checked", checked >= 6, `{checked}`)
		end,
	},
	{
		Name = "Bag: a chest's card holds its odds, the step one press opens and the bag's room",
		Run = function(t: any)
			local data = stocked()
			local card = Bag.Chest(data, "lanternrow_1") :: { [string]: any }
			t.Check("a card", card ~= nil and card.Held == 7 and card.Step == 7 and card.Tier == 1)
			local sum = 0
			for _, odds in card.Odds do
				sum += odds.Chance
				t.Check(`{odds.Rarity}: a chance`, odds.Chance > 0)
			end
			t.Check("the odds sum to one", math.abs(sum - 1) < 1e-9)
			t.Equal("the room left", card.Room, Bag.Cap - 9)
			Chests.Grant(data, "lanternrow_1", 100)
			t.Equal("a step is at most the open step", (Bag.Chest(data, "lanternrow_1") :: any).Step, ChestsConfig.Step)
			-- The step is what one press opens, so it never passes the bag's room (research, TR28's call 4).
			local held = Bag.Held(data)
			for index = 1, Bag.Cap - held - 20 do
				data.Items[`filler{index}`] = { Def = "ring", Rarity = "Common", Design = 1, Lines = {}, Tier = 1, Got = 0 } :: any
			end
			local tight = Bag.Chest(data, "lanternrow_1") :: { [string]: any }
			t.Check("with room for 20, the step is 20", tight.Room == 20 and tight.Step == 20, `{tight.Room}, {tight.Step}`)
			for index = 1, 20 do
				data.Items[`more{index}`] = { Def = "ring", Rarity = "Common", Design = 1, Lines = {}, Tier = 1, Got = 0 } :: any
			end
			local full = Bag.Chest(data, "lanternrow_1") :: { [string]: any }
			t.Check("with the bag full, the step is none", full.Room == 0 and full.Step == 0, `{full.Room}, {full.Step}`)
			t.Equal("a chest not held: no card", Bag.Chest(data, "mirrorpavilion_1"), nil)
		end,
	},
	{
		Name = "Bag: an item's cell shows its design's picture, and its card is titled with its design's name",
		Run = function(t: any)
			local data, _, ids = stocked()
			local owned = data.Voidkin[data.Roles.Lead]
			data.Items[ids.better].Design = 2
			local design = Items.Design(data.Items[ids.better]) :: ItemDesigns.Design
			t.Check("the Epic helmet's second design", design ~= nil and design == ItemDesigns.ByKind.Helmet.Epic[2])
			local seen, chests, wrong = 0, 0, ""
			for _, entry in Bag.List(data, owned, "All", "Rarity") do
				local item = data.Items[entry.Id]
				if entry.Kind == "Item" then
					seen += 1
					local own = Items.Design(item)
					if own == nil or entry.Image ~= own.Image or UIKit.Images[entry.Image :: string] == nil then
						wrong = entry.Id
					end
				elseif entry.Kind == "Chest" then
					local row = ChestRows.ById[entry.Def]
					chests += 1
					if row == nil or entry.Image ~= row.Image or UIKit.Images[entry.Image :: string] == nil then
						wrong = entry.Id
					end
				elseif entry.Image ~= nil then
					wrong = entry.Id
				end
			end
			t.Check("every item's cell its own design's picture, in the kit; a chest's its tier's (AR21), in the kit; a shard's none", seen == 9 and chests > 0 and wrong == "", `{seen}, {chests} chests, {wrong}`)
			local card = Bag.Card(data, owned, ids.better) :: Bag.Card
			t.Check("its card's title is its design's name, its picture its design's", card.Name == design.Name and card.Image == design.Image, card.Name)
			t.Check("and its kind stays its row's", card.Kind == "Helmet" and card.Rarity == "Epic")
			local before = card.Power
			data.Items[ids.better].Design = 3
			local again = Bag.Card(data, owned, ids.better) :: Bag.Card
			t.Check("another design: another name, the same comparison", again.Name == ItemDesigns.ByKind.Helmet.Epic[3].Name and again.Power == before)
		end,
	},
}
