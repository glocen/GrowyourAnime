--!strict
-- Logic cases (pure): how many exist (Rules.Exist; docs/design.md, "Voidkin", "How many exist"; the outside review's
-- item 4). A new Voidkin waits for its number, a copy gets none, a number is written once and never reused, the store's
-- write reserves a block and counts only grants, another era's numbers are cleared, and the words. Runs in Studio
-- (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Collection = require(Shared.Rules.Collection)
local Exist = require(Shared.Rules.Exist)
local ExistConfig = require(Shared.Config.Exist)
local Voidkin = require(Shared.Definitions.Voidkin)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	Exist.Fresh(data, ExistConfig.Epoch)
	return data
end

return {
	{
		Name = "Exist: a new Voidkin waits for its number and a copy gets none; a number is written once, in its era, never twice",
		Run = function(t: any)
			local data = fresh()
			for _, id in Exist.Missing(data) do -- a starter, if the template gives one
				Exist.Grant(data, id.Id, 1, ExistConfig.Epoch)
			end
			t.Equal("numbered: nothing waits", #Exist.Missing(data), 0)
			local first = Collection.Uncover(data, Voidkin.List[1].Id, NOW)
			local second = Collection.Uncover(data, Voidkin.List[2].Id, NOW + 5)
			local copy = Collection.Uncover(data, Voidkin.List[1].Id, NOW + 9)
			t.Check("two new and a copy", first.Outcome == "New" and second.Outcome == "New" and copy.Outcome == "Copy")
			local missing = Exist.Missing(data)
			t.Check("the two new wait, in the order they were uncovered; the copy adds none", #missing == 2 and missing[1].Id == first.Id and missing[2].Id == second.Id and missing[1].Def == Voidkin.List[1].Id,
				`{#missing} waiting`)
			local given = Exist.Grant(data, first.Id, 1284, ExistConfig.Epoch)
			t.Check("its number written", given.Ok == true and data.Voidkin[first.Id].No == 1284)
			local again = Exist.Grant(data, first.Id, 1285, ExistConfig.Epoch)
			t.Check("never twice: a second number refused, the first kept", again.Ok == false and again.Error == Exist.Taken and data.Voidkin[first.Id].No == 1284)
			t.Equal("no such Voidkin: refused", Exist.Grant(data, "nobody", 7, ExistConfig.Epoch).Error, Exist.Gone)
			t.Equal("another era's number: refused", Exist.Grant(data, second.Id, 7, "Elsewhere").Error, Exist.Era)
			t.Check("so the second still waits", #Exist.Missing(data) == 1 and data.Voidkin[second.Id].No == nil)
			-- a new era: every number cleared, each to be numbered again
			Exist.Grant(data, second.Id, 40, ExistConfig.Epoch)
			t.Check("an era's change clears its numbers", Exist.Fresh(data, "Launch") and data.ExistEpoch == "Launch" and data.Voidkin[first.Id].No == nil and #Exist.Missing(data) >= 2)
			t.Check("the same era: unchanged", not Exist.Fresh(data, "Launch"))
		end,
	},
	{
		Name = "Exist: the store's write reserves a block and counts only grants; a block hands its numbers out once, in order",
		Run = function(t: any)
			local stored, block = Exist.Reserve(nil, 5, 0)
			t.Check("an empty record starts at 1, none held", stored.Next == 6 and stored.Held == 0 and block ~= nil and block.From == 1 and block.To == 5)
			local taken: { number } = {}
			for _ = 1, 6 do
				table.insert(taken, Exist.Take(block) or 0)
			end
			t.Check("1 to 5, then spent", table.concat(taken, ",") == "1,2,3,4,5,0", table.concat(taken, ","))
			local after, more = Exist.Reserve(stored, 5, 3)
			t.Check("the next block follows, and three grants counted", after.Next == 11 and after.Held == 3 and more ~= nil and more.From == 6 and more.To == 10)
			local counted, none = Exist.Reserve(after, 0, 2)
			t.Check("a count alone reserves nothing", counted.Next == 11 and counted.Held == 5 and none == nil)
			local broken = Exist.Reserve({ Next = "x", Held = -4 }, 2, 1)
			t.Check("a record that isn't one starts over, never below", broken.Next == 3 and broken.Held == 1)
			t.Equal("a server's unused numbers never count: Held is grants, not Next - 1", counted.Held, 5)
		end,
	},
	{
		Name = "Exist: the words, as the Overview's header says them",
		Run = function(t: any)
			t.Equal("a number and its count", Exist.Words(1284, 3912), "No. 1,284 · 3,912 exist")
			t.Equal("the only one: its verb agrees", Exist.Words(1, 1), "No. 1 · 1 exists")
			t.Equal("before the count is read", Exist.Words(7, nil), "No. 7")
			t.Equal("no number yet: nothing", Exist.Words(nil, 3912), "")
			t.Equal("a count of none: the number alone", Exist.Words(3, 0), "No. 3")
		end,
	},
}
