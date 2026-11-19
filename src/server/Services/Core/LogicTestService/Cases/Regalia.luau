--!strict
-- Regalia cases (pure): part 10's class rules (docs/engineering-plan.md, "Class rules"; Rules.Regalia, Rules.Stats).
-- Each weapon row is its class's by Gear.Weapons; a wrong-class or wrong-slot equip is refused and changes nothing; a
-- preset applies only the Voidkin's own class's pair; a save edited by hand applies no wrong weapon; a repeated equip is
-- a no-op; the comparison is the resolver run twice. Runs in Studio (LogicTests) and with Studio closed
-- (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local Gear = require(Shared.Definitions.Gear)
local Items = require(Shared.Definitions.Items)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local Regalia = require(Shared.Rules.Regalia)
local Stats = require(Shared.Rules.Stats)
local Collection = require(Shared.Rules.Collection)

local NOW = 1_800_000_000
local OP = "3b241101-e2bb-4255-8caf-4136c566a962"
local OTHER_OP = "6fa459ea-ee8a-3ca4-894e-db77e160355e"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function same(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not same(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

-- A Voidkin of `class` owned by `data`, at level 10.
local function own(data: Profile.Data, class: string): Profile.OwnedVoidkin
	for _, row in Voidkin.List do
		if row.Class == class then
			local owned = data.Voidkin[Collection.Uncover(data, row.Id, NOW).Id]
			owned.Level = 10
			return owned
		end
	end
	error(`no {class} in the roster`)
end

-- An item of row `def` in the bag, worn nowhere.
local function item(data: Profile.Data, def: string, lines: { { Stat: string, Value: number } }): string
	local id = Profile.NewId(data)
	data.Items[id] = { Id = id, Def = def, Tier = 1, Rarity = "Common", Design = 1, Lines = lines :: any, Sockets = {}, Reinforce = 0, Jewels = {} }
	return id
end

-- One source's lines, by stat.
local function from(lines: { Stats.Line }, source: string): { [string]: number }
	local out = {}
	for _, line in lines do
		if line.Source == source then
			out[line.Stat] = (out[line.Stat] or 0) + line.Value
		end
	end
	return out
end

local function equip(data: Profile.Data, slot: string, class: string?, id: string?, preset: number?): { [string]: any }
	return Regalia.Actions.Equip(data, { Preset = preset or 1, Slot = slot, Class = class, Item = id })
end

return {
	{
		Name = "Regalia: one row per kind, each weapon its class's own by Gear.Weapons, each fitting where it goes",
		Run = function(t: any)
			local seen: { [string]: boolean } = {}
			for _, row in Items.List do
				t.Check(`{row.Id}: one row`, not seen[row.Id])
				seen[row.Id] = true
				t.Check(`{row.Id}: a name`, row.Name ~= "")
			end
			for _, slot in Gear.Shared do
				local fits = 0
				for _, row in Items.List do
					if Items.Fits(row, slot, nil) then
						fits += 1
						t.Equal(`{row.Id}: armour shows its slot's kind`, row.Kind, Gear.Family(slot))
					end
				end
				t.Equal(`{slot}: one row of its kind`, fits, 1)
			end
			for class, pair in Gear.Weapons do
				for _, hand in Gear.Hands do
					local found = nil
					for _, row in Items.List do
						if row.Class == class and row.Slot == hand then
							t.Check(`{class} {hand}: one weapon`, found == nil)
							found = row
						end
					end
					t.Check(`{class} {hand}: a row`, found ~= nil)
					if found then
						t.Equal(`{class} {hand}: the kind Gear.Weapons names`, found.Kind, pair[hand])
						t.Check(`{found.Id}: fits its own class`, Items.Fits(found, hand, class))
						for other in Gear.Weapons do
							t.Check(`{found.Id}: never a {other}'s`, other == class or not Items.Fits(found, hand, other))
						end
						for _, slot in Gear.Shared do
							t.Check(`{found.Id}: never in {slot}`, not Items.Fits(found, slot, class))
						end
					end
				end
			end
			for _, row in Items.List do
				if row.Class then
					t.Check(`{row.Id}: its class is a class`, Gear.Weapons[row.Class] ~= nil)
				else
					t.Check(`{row.Id}: armour in no hand`, not Items.Fits(row, "Main Hand", "Tank") and not Items.Fits(row, "Off Hand", "Tank"))
				end
			end
			t.Check("a ring fits either ring", Items.Fits(Items.ById.ring, "Ring I", nil) and Items.Fits(Items.ById.ring, "Ring II", nil))
			t.Check("an earring, either earring, never a ring", Items.Fits(Items.ById.earring, "Earring II", nil) and not Items.Fits(Items.ById.earring, "Ring I", nil))
		end,
	},
	{
		Name = "Regalia: a wrong-class or wrong-slot equip is refused with its reason, and changes nothing",
		Run = function(t: any)
			local data = fresh()
			local axe = item(data, "great_axe", { { Stat = "Attack", Value = 100 } })
			local helmet = item(data, "helmet", { { Stat = "Health", Value = 100 } })
			local shield = item(data, "shield", {})
			local before = Profile.DeepCopy(data)
			local refusals: { { any } } = {
				{ "a Tank's axe in the Warrior's main hand", "Main Hand", "Warrior", axe, Regalia.WrongClass },
				{ "a helmet in a hand", "Main Hand", "Tank", helmet, Regalia.WrongSlot },
				{ "an axe on the head", "Helmet", nil, axe, Regalia.WrongSlot },
				{ "an off hand in the main hand", "Main Hand", "Tank", shield, Regalia.WrongSlot },
				{ "an item that isn't theirs", "Helmet", nil, "k404", Regalia.NotOwned },
				{ "a weapon that isn't theirs, no class named", "Main Hand", nil, "k404", Regalia.NotOwned },
				{ "a slot that isn't one", "Weapon", nil, helmet, Regalia.WrongSlot },
				{ "a hand for a class that isn't one", "Main Hand", "Bard", axe, Regalia.WrongClass },
				{ "a hand emptied for no class", "Main Hand", nil, nil, Regalia.WrongClass },
			}
			for _, case in refusals do
				local answer = equip(data, case[2], case[3], case[4])
				t.Check(`{case[1]}: refused`, answer.Ok == false)
				t.Equal(`{case[1]}: says why`, answer.Error, case[5])
				t.Check(`{case[1]}: nothing changed`, same(data, before))
			end
			t.Equal("no such preset", equip(data, "Helmet", nil, helmet, 2).Error, Regalia.Unknown)
			t.Equal("a preset that isn't a number", Regalia.Actions.Equip(data, { Preset = "1", Slot = "Helmet", Item = helmet }).Error, Regalia.Unknown)
			t.Equal("no request at all", Regalia.Actions.Equip(data, nil).Error, Regalia.Unknown)
			t.Check("still nothing changed", same(data, before))
		end,
	},
	{
		Name = "Regalia: an equip wears it, a ring moves rather than doubles, one item sits in several presets, and none takes it off",
		Run = function(t: any)
			local data = fresh()
			local second: Profile.Preset = { Slots = {}, Hands = {} }
			table.insert(data.Presets, second)
			local ring = item(data, "ring", { { Stat = "Critical", Value = 10 } })
			local axe = item(data, "great_axe", {})
			local answer = equip(data, "Ring I", nil, ring)
			t.Check("worn", answer.Ok == true and data.Presets[1].Slots["Ring I"] == ring)
			equip(data, "Ring II", nil, ring)
			t.Check("moved to Ring II, not worn twice", data.Presets[1].Slots["Ring I"] == nil and data.Presets[1].Slots["Ring II"] == ring)
			equip(data, "Ring I", nil, ring, 2)
			t.Check("the same ring in a second preset", data.Presets[2].Slots["Ring I"] == ring and data.Presets[1].Slots["Ring II"] == ring)
			local hand = equip(data, "Main Hand", nil, axe)
			t.Check("a weapon's class from its row", hand.Ok == true and hand.Class == "Tank" and data.Presets[1].Hands.Tank["Main Hand"] == axe)
			t.Check("the hand under its class only", data.Presets[1].Slots["Main Hand"] == nil and data.Presets[1].Hands.Warrior == nil)
			equip(data, "Ring II", nil, "")
			t.Check("an empty id takes it off", data.Presets[1].Slots["Ring II"] == nil and data.Presets[2].Slots["Ring I"] == ring)
			equip(data, "Main Hand", "Tank", nil)
			t.Check("an emptied pair leaves no table", data.Presets[1].Hands.Tank == nil)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Regalia: a preset applies only the Voidkin's own class's pair, and armour on everyone",
		Run = function(t: any)
			local data = fresh()
			local axe = item(data, "great_axe", { { Stat = "Attack", Value = 100 } })
			local shield = item(data, "shield", { { Stat = "Endurance", Value = 30 } })
			local sword = item(data, "sword", { { Stat = "Attack", Value = 50 } })
			local cloak = item(data, "cloak", { { Stat = "Defence", Value = 7 } })
			equip(data, "Main Hand", nil, axe)
			equip(data, "Off Hand", nil, shield)
			equip(data, "Main Hand", nil, sword)
			equip(data, "Cloak", nil, cloak)
			for _, case in { { "Tank", 100, 30 }, { "Warrior", 50, nil }, { "Assassin", nil, nil } } do
				local owned = own(data, case[1] :: string)
				local _, lines = Stats.Resolve(owned, data.Presets[1], data)
				t.Equal(`{case[1]}: its main hand`, from(lines, "Item:Main Hand").Attack, case[2])
				t.Equal(`{case[1]}: its off hand`, from(lines, "Item:Off Hand").Endurance, case[3])
				t.Equal(`{case[1]}: the cloak on everyone`, from(lines, "Item:Cloak").Defence, 7)
			end
		end,
	},
	{
		Name = "Regalia: a save edited by hand applies no wrong weapon",
		Run = function(t: any)
			local data = fresh()
			local warrior = own(data, "Warrior")
			local axe = item(data, "great_axe", { { Stat = "Attack", Value = 100 } })
			local sword = item(data, "sword", { { Stat = "Attack", Value = 50 } })
			local ring = item(data, "ring", { { Stat = "Attack", Value = 3 } })
			local preset = data.Presets[1]
			local bare = Stats.Resolve(warrior, preset, data)
			local edits: { { string } } = {
				{ "a Tank's axe under the Warrior's pair", "hand", "Warrior", "Main Hand", axe },
				{ "a main-hand sword in the off hand", "hand", "Warrior", "Off Hand", sword },
				{ "a sword in Slots' Main Hand", "slot", "", "Main Hand", sword },
				{ "a sword on the head", "slot", "", "Helmet", sword },
				{ "a ring on the head", "slot", "", "Helmet", ring },
				{ "an item of no row", "slot", "", "Boots", "nowhere" },
			}
			data.Items.nowhere = { Id = "nowhere", Def = "case_none", Tier = 1, Rarity = "Common", Design = 1, Lines = { { Stat = "Attack", Value = 9 } }, Sockets = {}, Reinforce = 0, Jewels = {} }
			for _, edit in edits do
				preset.Slots, preset.Hands = {}, {}
				if edit[2] == "hand" then
					preset.Hands[edit[3]] = { [edit[4]] = edit[5] }
				else
					preset.Slots[edit[4]] = edit[5]
				end
				local block, lines = Stats.Resolve(warrior, preset, data)
				t.Equal(`{edit[1]}: adds nothing`, block.Attack, bare.Attack)
				t.Equal(`{edit[1]}: no item line`, next(from(lines, `Item:{edit[4]}`)), nil)
			end
			preset.Slots, preset.Hands = { ["Ring II"] = ring }, { Warrior = { ["Main Hand"] = sword } }
			local _, lines = Stats.Resolve(warrior, preset, data)
			t.Check("the right ones still apply", from(lines, "Item:Ring II").Attack == 3 and from(lines, "Item:Main Hand").Attack == 50)
		end,
	},
	{
		Name = "Regalia: a repeated equip is a no-op, even after the slot has changed since",
		Run = function(t: any)
			local data = fresh()
			local first = item(data, "ring", {})
			local second = item(data, "ring", {})
			local change = function(id: string): Transaction.Change
				return function(draft: Profile.Data): Transaction.Answer
					return Regalia.Actions.Equip(draft, { Preset = 1, Slot = "Ring I", Item = id })
				end
			end
			local answer = Transaction.Run(data, OP, change(first), 8)
			t.Check("worn", answer.Ok == true and data.Presets[1].Slots["Ring I"] == first)
			local before = Profile.DeepCopy(data)
			local again, changed = Transaction.Run(data, OP, change(first), 8)
			t.Check("the repeat changes nothing", not changed and same(data, before))
			t.Equal("and answers the first answer", again.Item, first)
			Transaction.Run(data, OTHER_OP, change(second), 8)
			local late, lateChanged = Transaction.Run(data, OP, change(first), 8)
			t.Check("a late repeat doesn't put the first back", not lateChanged and data.Presets[1].Slots["Ring I"] == second)
			t.Equal("it answers as the first time", late.Item, first)
		end,
	},
	{
		Name = "Regalia: the comparison is the resolver run twice, picks the better of two rings, and changes nothing",
		Run = function(t: any)
			local data = fresh()
			local tank = own(data, "Tank")
			local warrior = own(data, "Warrior")
			local axe = item(data, "great_axe", { { Stat = "Attack", Value = 80 }, { Stat = "Strength", Value = 20 } })
			local weak = item(data, "ring", { { Stat = "Attack", Value = 5 } })
			local strong = item(data, "ring", { { Stat = "Attack", Value = 40 } })
			local better = item(data, "ring", { { Stat = "Attack", Value = 20 }, { Stat = "Endurance", Value = 10 } })
			local preset = data.Presets[1]
			local kept = Profile.DeepCopy(data)
			local change = Stats.Compare(data, preset, tank, axe)
			t.Check("a weapon compared for its class", change ~= nil and change.Slot == "Main Hand")
			t.Check("it changed nothing", same(data, kept))
			if change then
				local trial = Profile.DeepCopy(preset)
				trial.Hands.Tank = { ["Main Hand"] = axe }
				local after = Stats.Resolve(tank, trial, data)
				local before = Stats.Resolve(tank, preset, data)
				t.Equal("its Combat Power is the resolver's twice, unrounded", change.Power, Stats.Sum(after) - Stats.Sum(before))
				for _, stat in Stats.Names do
					t.Equal(`{stat}'s change`, change.Battle[stat], (after :: any)[stat] - (before :: any)[stat])
				end
				for _, id in Attributes.Ids do
					t.Equal(`{id}'s change`, change.Attributes[id], after.Attributes[id] - before.Attributes[id])
				end
				t.Equal("the Strength it carries", change.Attributes.Strength, 20)
				t.Check("a gain is a gain", change.Power > 0)
			end
			local wrong, why = Stats.Compare(data, preset, warrior, axe)
			t.Check("never for another class", wrong == nil and why == Regalia.WrongClass)
			local none, missing = Stats.Compare(data, preset, tank, "k404")
			t.Check("nothing to compare", none == nil and missing == Regalia.NotOwned)
			equip(data, "Ring I", nil, strong)
			local open = Stats.Compare(data, preset, tank, better)
			t.Equal("an empty ring first", if open then open.Slot else nil, "Ring II")
			equip(data, "Ring II", nil, weak)
			local swap = Stats.Compare(data, preset, tank, better)
			t.Equal("then the weaker one", if swap then swap.Slot else nil, "Ring II")
			local forced = Stats.Compare(data, preset, tank, better, "Ring I")
			t.Check("a slot named is taken, here a loss", forced ~= nil and forced.Slot == "Ring I" and swap ~= nil and forced.Power < swap.Power)
			local worn = Stats.Compare(data, preset, tank, strong)
			t.Check("what's worn compares as no change", worn ~= nil and worn.Slot == "Ring I" and worn.Power == 0)
			local helmet, onHead = Stats.Compare(data, preset, tank, strong, "Helmet")
			t.Check("a ring on the head is no comparison", helmet == nil and onHead == Regalia.WrongSlot)
		end,
	},
}
