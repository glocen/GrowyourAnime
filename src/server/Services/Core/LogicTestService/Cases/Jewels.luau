--!strict
-- Jewels cases (pure): TR47 part B (Rules.Jewels; Config.Jewels; docs/design.md, "Jewels"). The keys, the points by
-- level, a jewel set into its colour's slot and back, three of a level merged into one of the next, every refusal
-- changing nothing, a repeat through the transaction taking nothing twice, the resolver's flat attribute points, and the
-- save after it. The numbers are TR47's seeds, written here as it gives them, so a Config that drifts fails. Runs in
-- Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Saveable = require(Shared.Data.Saveable)
local Stats = require(Shared.Rules.Stats)
local Jewels = require(Shared.Rules.Jewels)
local Collection = require(Shared.Rules.Collection)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local JewelsConfig = require(Shared.Config.Jewels)
local HudConfig = require(Shared.Config.Hud)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function item(data: Profile.Data, def: string): Profile.OwnedItem
	local id = Profile.NewId(data)
	local made: Profile.OwnedItem = {
		Id = id,
		Def = def,
		Tier = 1,
		Rarity = "Rare",
		Design = 1,
		Lines = { { Stat = "Attack", Value = 300 } },
		Sockets = { "", "", "" },
		Reinforce = 0,
		Jewels = {},
	}
	data.Items[id] = made
	return made
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

return {
	{
		Name = "Jewels: five colours, one an attribute; five levels giving 1, 2, 4, 8 and 16 points; a key names only a jewel that can exist",
		Run = function(t: any)
			local want: { [string]: string } = { Red = "Strength", Green = "Agility", Blue = "Intelligence", Yellow = "Endurance", Purple = "Spirit" }
			t.Equal("five colours", #JewelsConfig.Colours, 5)
			for colour, attribute in want do
				t.Check(`{colour}: {attribute}`, JewelsConfig.Attribute[colour] == attribute and Attributes.ById[attribute] ~= nil)
				for level, points in { 1, 2, 4, 8, 16 } do
					local got, value = Jewels.Points(colour, level)
					t.Check(`{colour} {level}: {points}`, got == attribute and value == points)
					local parsed = Jewels.Parse(Jewels.Key(colour, level))
					t.Check(`{colour}:{level} parses`, parsed ~= nil and parsed.Colour == colour and parsed.Level == level)
				end
			end
			t.Check("the page's order is the config's", HudConfig.Equipment.Jewels.Order == JewelsConfig.Colours)
			for _, odd in { "Red:0", "Red:6", "Red:1.5", "Pink:1", "Red", ":1", "red:1", "Red:01x", "" } do
				t.Check(`{odd}: no jewel`, Jewels.Parse(odd) == nil)
			end
			t.Check("no key at all", Jewels.Parse(nil) == nil and Jewels.Parse(3) == nil)
			t.Check("a level past the top gives nothing", Jewels.Points("Red", 6) == nil and Jewels.Points("Red", 0 / 0) == nil)
		end,
	},
	{
		Name = "Jewels: set from the bag into its colour's slot, one already there back to the bag; unset back; refusals change nothing; a repeat takes nothing twice",
		Run = function(t: any)
			local data = fresh()
			local ring = item(data, "ring")
			data.Bag.Jewels["Red:2"] = 2
			data.Bag.Jewels["Red:3"] = 1
			local set = Jewels.Set(data, { Item = ring.Id, Jewel = "Red:2" })
			t.Check("set", set.Ok == true and ring.Jewels.Red == 2 and data.Bag.Jewels["Red:2"] == 1 and set.Back == "")
			local swap = Jewels.Set(data, { Item = ring.Id, Jewel = "Red:3" })
			t.Check("a higher one in: the old one back", swap.Ok == true and ring.Jewels.Red == 3 and data.Bag.Jewels["Red:2"] == 2 and data.Bag.Jewels["Red:3"] == nil and swap.Back == "Red:2")
			local out = Jewels.Unset(data, { Item = ring.Id, Colour = "Red" })
			t.Check("out: back to the bag, the slot empty", out.Ok == true and ring.Jewels.Red == nil and data.Bag.Jewels["Red:3"] == 1)
			local before = Profile.DeepCopy(data)
			t.Equal("none of it in the bag", Jewels.Set(data, { Item = ring.Id, Jewel = "Blue:1" }).Error, Jewels.NoneLeft)
			t.Equal("an empty slot", Jewels.Unset(data, { Item = ring.Id, Colour = "Blue" }).Error, Jewels.Empty)
			t.Equal("an unknown item", Jewels.Set(data, { Item = "nowhere", Jewel = "Red:3" }).Error, Jewels.Unknown)
			t.Equal("an unknown jewel", Jewels.Set(data, { Item = ring.Id, Jewel = "Red:9" }).Error, Jewels.Unknown)
			t.Equal("an unknown colour", Jewels.Unset(data, { Item = ring.Id, Colour = "Pink" }).Error, Jewels.Unknown)
			t.Equal("no request", Jewels.Set(data, nil).Error, Jewels.Unknown)
			t.Check("and nothing changed", same(data, before))
			local first, changed = Transaction.Run(data, "op-jewel", function(draft: Profile.Data): any
				return Jewels.Set(draft, { Item = ring.Id, Jewel = "Red:2" })
			end, 8)
			t.Check("through the transaction", first.Ok == true and changed and data.Items[ring.Id].Jewels.Red == 2)
			local again, twice = Transaction.Run(data, "op-jewel", function(draft: Profile.Data): any
				return Jewels.Set(draft, { Item = ring.Id, Jewel = "Red:2" })
			end, 8)
			t.Check("the same op id: its first answer, one jewel taken", again.Ok == true and not twice and data.Bag.Jewels["Red:2"] == 1)
			local hand = fresh()
			local cape = item(hand, "ring")
			cape.Jewels.Green = 9 -- a level no jewel has: a hand-edited save
			local cleared = Jewels.Unset(hand, { Item = cape.Id, Colour = "Green" })
			t.Check("a broken level clears and gives nothing back", cleared.Ok == true and cape.Jewels.Green == nil and next(hand.Bag.Jewels) == nil)
		end,
	},
	{
		Name = "Jewels: three of a level make one of the next, many at once; never past level 5, never with too few; 81 level 1s make one level 5",
		Run = function(t: any)
			local data = fresh()
			data.Bag.Jewels["Blue:1"] = 81
			for level = 1, 4 do
				local key = Jewels.Key("Blue", level)
				local held = data.Bag.Jewels[key] :: number
				local made = Jewels.Merge(data, { Jewel = key, Count = held // 3 })
				t.Check(`level {level} into {level + 1}`, made.Ok == true and made.Spent == held and made.Made == Jewels.Key("Blue", level + 1))
			end
			t.Check("one level 5, nothing else", data.Bag.Jewels["Blue:5"] == 1 and data.Bag.Jewels["Blue:1"] == nil and data.Bag.Jewels["Blue:4"] == nil)
			local before = Profile.DeepCopy(data)
			t.Equal("level 5 is the top", Jewels.Merge(data, { Jewel = "Blue:5" }).Error, Jewels.Top)
			data.Bag.Jewels["Red:1"] = 5
			before = Profile.DeepCopy(data)
			t.Equal("five make one, not two", Jewels.Merge(data, { Jewel = "Red:1", Count = 2 }).Error, Jewels.TooFew)
			for _, odd in { 0, -1, 1.5, 0 / 0, math.huge, "2" } do
				t.Equal(`a count of {odd}`, Jewels.Merge(data, { Jewel = "Red:1", Count = odd }).Error, Jewels.Unknown)
			end
			t.Check("and nothing changed", same(data, before))
			local one = Jewels.Merge(data, { Jewel = "Red:1" })
			t.Check("one by default: two left", one.Ok == true and data.Bag.Jewels["Red:1"] == 2 and data.Bag.Jewels["Red:2"] == 1)
			local again, twice = Transaction.Run(data, "op-merge", function(draft: Profile.Data): any
				return Jewels.Merge(draft, { Jewel = "Red:1" })
			end, 8)
			t.Equal("two can't", again.Error, Jewels.TooFew)
			data.Bag.Jewels["Red:1"] = 6
			local ok = Transaction.Run(data, "op-merge-2", function(draft: Profile.Data): any
				return Jewels.Merge(draft, { Jewel = "Red:1", Count = 2 })
			end, 8)
			local repeat_, moved = Transaction.Run(data, "op-merge-2", function(draft: Profile.Data): any
				return Jewels.Merge(draft, { Jewel = "Red:1", Count = 2 })
			end, 8)
			t.Check("a repeat merges once", ok.Ok == true and repeat_.Ok == true and not moved and not twice and data.Bag.Jewels["Red:1"] == nil and data.Bag.Jewels["Red:2"] == 3)
			t.Check("the save is saveable", #Saveable.Problems(data, "profile") == 0)
		end,
	},
	{
		Name = "Jewels in the resolver: each slot's points on its colour's attribute, as Jewel:<slot>, converting like any point; an item not worn gives none",
		Run = function(t: any)
			local data = fresh()
			local def = Voidkin.List[1].Id
			local owned = data.Voidkin[Collection.Uncover(data, def, NOW).Id]
			local ring = item(data, "ring")
			data.Presets[1].Slots["Ring I"] = ring.Id
			local plain = Stats.Resolve(owned, data.Presets[1], data)
			ring.Jewels = { Red = 5, Green = 1, Purple = 3 }
			local block, lines = Stats.Resolve(owned, data.Presets[1], data)
			local got: { [string]: number } = {}
			for _, line in lines do
				if line.Source == "Jewel:Ring I" then
					got[line.Stat] = (got[line.Stat] or 0) + line.Value
				end
			end
			t.Check("Strength 16, Agility 1, Spirit 4", got.Strength == 16 and got.Agility == 1 and got.Spirit == 4 and got.Intelligence == nil, `{got.Strength} {got.Agility} {got.Spirit}`)
			t.Check("the attributes rise by them", math.abs(block.Attributes.Strength - plain.Attributes.Strength - 16) < 1e-9 and math.abs(block.Attributes.Spirit - plain.Attributes.Spirit - 4) < 1e-9)
			t.Check("and they convert: the block's Health rises", block.Health > plain.Health)
			local unworn = fresh()
			local kin = unworn.Voidkin[Collection.Uncover(unworn, def, NOW).Id]
			local loose = item(unworn, "ring")
			loose.Jewels = { Red = 5 }
			local _, none = Stats.Resolve(kin, unworn.Presets[1], unworn)
			local any = false
			for _, line in none do
				any = any or string.sub(line.Source, 1, 6) == "Jewel:"
			end
			t.Check("an item not worn gives nothing", not any)
		end,
	},
}
