--!strict
-- Bag cases (pure): what the Items page shows (Rules.Bag; AR18's C; docs/research/rework-2026-11-16.md, part 5). The
-- belt's groups; each kind's cells; the up arrow exactly where the comparison gains; another class's weapon dimmed and
-- never compared; the sorts; the card against what it replaces, and a worn item's card as taking it off; a chest's card.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Items = require(Shared.Definitions.Items)
local Gear = require(Shared.Definitions.Gear)
local Rarity = require(Shared.Definitions.Rarity)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local ChestsConfig = require(Shared.Config.Chests)
local ChestRows = require(Shared.Definitions.Chests)
local Collection = require(Shared.Rules.Collection)
local Regalia = require(Shared.Rules.Regalia)
local Stats = require(Shared.Rules.Stats)
local Chests = require(Shared.Rules.Chests)
local Bag = require(Shared.Rules.Bag)

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
	data.Items[id] = { Id = id, Def = def, Tier = 1, Rarity = rarity, Lines = lines, Sockets = {}, Jewel = "" }
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
			local best = "Common"
			for rarity, chance in Chests.Odds(ChestRows.ById.drumcourt_3) do
				best = if chance > 0 and Rarity.Rank[rarity] > Rarity.Rank[best] then rarity else best
			end
			t.Equal("its edge is the best it can give, by Config's ladder", chests[1].Rarity, best)
			t.Check("which is above Common", Rarity.Rank[best] > Rarity.Rank.Common, best)
			t.Equal("Lantern Row's Common Chest after, its best an Uncommon", chests[2].Rarity, "Uncommon")
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
			local last = 0
			for _, battle in card.Battle do
				local at = table.find(Stats.Names, battle.Stat) :: number
				t.Check(`{battle.Stat}: changed, in order`, battle.Change ~= 0 and at > last and math.abs(battle.Change - change.Battle[battle.Stat]) < 1e-9)
				last = at
			end
			t.Equal("its lines kept", #card.Lines, 2)
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
				data.Items[`filler{index}`] = { Def = "ring", Rarity = "Common", Lines = {}, Tier = 1, Got = 0 } :: any
			end
			local tight = Bag.Chest(data, "lanternrow_1") :: { [string]: any }
			t.Check("with room for 20, the step is 20", tight.Room == 20 and tight.Step == 20, `{tight.Room}, {tight.Step}`)
			for index = 1, 20 do
				data.Items[`more{index}`] = { Def = "ring", Rarity = "Common", Lines = {}, Tier = 1, Got = 0 } :: any
			end
			local full = Bag.Chest(data, "lanternrow_1") :: { [string]: any }
			t.Check("with the bag full, the step is none", full.Room == 0 and full.Step == 0, `{full.Room}, {full.Step}`)
			t.Equal("a chest not held: no card", Bag.Chest(data, "mirrorpavilion_1"), nil)
		end,
	},
}
