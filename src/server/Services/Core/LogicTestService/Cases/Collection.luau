--!strict
-- Collection cases (pure): the first of a Voidkin is a new record, a duplicate a copy, a copy past the last star sells;
-- stars cost their copies in order, by hand, and the last star sells what's left.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Collection = require(Shared.Rules.Collection)
local VoidkinConfig = require(Shared.Config.Voidkin)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function count(t: { [string]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

return {
	{
		Name = "Collection: the first is new, a duplicate is a copy",
		Run = function(t: any)
			local data = fresh()
			local first = Collection.Uncover(data, "rook", NOW)
			t.Equal("new", first.Outcome, "New")
			local owned = data.Voidkin[first.Id]
			t.Check("a record", owned ~= nil and owned.Def == "rook" and owned.Level == 1 and owned.Stars == 0)
			local second = Collection.Uncover(data, "rook", NOW + 5)
			t.Equal("copy", second.Outcome, "Copy")
			t.Equal("the same Voidkin", second.Id, first.Id)
			t.Equal("one copy waiting", owned.Copies, 1)
			t.Equal("owned once", count(data.Voidkin), 1)
			t.Equal("found twice", data.Index.rook.Count, 2)
			t.Equal("first found stays", data.Index.rook.First, NOW)
			t.Equal("stars untouched", owned.Stars, 0)
		end,
	},
	{
		Name = "Collection: an unknown Voidkin is refused",
		Run = function(t: any)
			local data = fresh()
			local answer = Collection.Uncover(data, "nobody", NOW)
			t.Equal("refused", answer.Error, Collection.Unknown)
			t.Equal("nothing indexed", count(data.Index), 0)
		end,
	},
	{
		Name = "Collection: stars cost their copies, in order",
		Run = function(t: any)
			local data = fresh()
			local id = Collection.Uncover(data, "kirra", NOW).Id
			local owned = data.Voidkin[id]
			t.Equal("none to spend", Collection.SpendCopies(data, id).Error, Collection.NotEnough)
			local total = 0
			for star = 1, VoidkinConfig.MaxStars - 1 do
				local cost = VoidkinConfig.StarCopies[star]
				total += cost
				for _ = 1, cost do
					Collection.Uncover(data, "kirra", NOW)
				end
				local answer = Collection.SpendCopies(data, id)
				t.Check(`star {star} for {cost}`, answer.Ok == true and owned.Stars == star and owned.Copies == 0)
			end
			for star = 2, VoidkinConfig.MaxStars do
				t.Equal(`star {star} costs twice star {star - 1}`, VoidkinConfig.StarCopies[star], VoidkinConfig.StarCopies[star - 1] * 2)
			end
			t.Equal("doubling from one", total, 2 ^ (VoidkinConfig.MaxStars - 1) - 1)
		end,
	},
	{
		Name = "Collection: the last star sells the copies left over, then each new copy",
		Run = function(t: any)
			local data = fresh()
			local id = Collection.Uncover(data, "pip", NOW).Id
			local owned = data.Voidkin[id]
			owned.Stars = VoidkinConfig.MaxStars - 1
			owned.Copies = VoidkinConfig.StarCopies[VoidkinConfig.MaxStars] + 3
			local answer = Collection.SpendCopies(data, id)
			local price = VoidkinConfig.SellCredits.Common
			t.Check("the last star", answer.Ok == true and owned.Stars == VoidkinConfig.MaxStars)
			t.Equal("three sold", answer.Credits, 3 * price)
			t.Equal("none left", owned.Copies, 0)
			t.Equal("no star past the last", Collection.SpendCopies(data, id).Error, Collection.MaxStars)
			local after = Collection.Uncover(data, "pip", NOW)
			t.Equal("sold on arrival", after.Outcome, "Sold")
			t.Equal("paid", data.Currency.Credits, 4 * price)
			t.Equal("still none waiting", owned.Copies, 0)
		end,
	},
	{
		Name = "Collection: a bad id is refused, and the profile still saves",
		Run = function(t: any)
			local data = fresh()
			Collection.Uncover(data, "watt", NOW)
			t.Equal("not a string", Collection.SpendCopies(data, 7).Error, Collection.Unknown)
			t.Equal("not owned", Collection.SpendCopies(data, "k99").Error, Collection.Unknown)
			local problems = Saveable.Problems(data, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
}
