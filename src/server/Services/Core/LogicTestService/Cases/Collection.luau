--!strict
-- Collection cases (pure): the first of a Voidkin is a new record, a duplicate a copy, a copy past the last star sells;
-- stars cost their copies in order, by hand, and the last star sells what's left; the showcase at the gate stands the
-- one picked, else the strongest (TR22).
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Collection = require(Shared.Rules.Collection)
local VoidkinConfig = require(Shared.Config.Voidkin)
local Voidkin = require(Shared.Definitions.Voidkin)
local Stats = require(Shared.Rules.Stats)

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
	{
		Name = "Collection: a Voidkin is marked a favourite or locked and unmarked, and nothing else about it changes",
		Run = function(t: any)
			-- TR17: favourite and lock beside the name on one Voidkin's screen.
			local data = fresh()
			local id = Collection.Uncover(data, "rook", NOW).Id
			local before = Profile.DeepCopy(data.Voidkin[id])
			local answer = Collection.Actions.SetMark(data, { Voidkin = id, Mark = "Favourite", On = true }, NOW, 0)
			t.Check("a favourite", answer.Ok == true and data.Voidkin[id].Favourite == true and answer.Favourite == true)
			t.Check("again, the same", Collection.SetMark(data, id, "Favourite", true).Ok == true and data.Voidkin[id].Favourite)
			t.Check("locked", Collection.SetMark(data, id, "Locked", true).Ok == true and data.Voidkin[id].Locked == true)
			t.Check("the favourite unmarked, the lock kept", Collection.SetMark(data, id, "Favourite", false).Ok == true
				and data.Voidkin[id].Favourite == false and data.Voidkin[id].Locked == true)
			Collection.SetMark(data, id, "Locked", false)
			local after = data.Voidkin[id]
			t.Check("the rest as it was", after.Level == before.Level and after.Stars == before.Stars and after.Copies == before.Copies
				and after.Nickname == before.Nickname and after.Favourite == false and after.Locked == false)
			t.Equal("an unknown mark", Collection.SetMark(data, id, "Level", true).Error, Collection.Unknown)
			t.Equal("not a yes or no", Collection.SetMark(data, id, "Locked", "yes").Error, Collection.Unknown)
			t.Equal("not owned", Collection.SetMark(data, "k99", "Locked", true).Error, Collection.Unknown)
			t.Equal("no args", Collection.Actions.SetMark(data, nil, NOW, 0).Error, Collection.Unknown)
			local problems = Saveable.Problems(data, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Collection: a nickname is kept tidy as written, up to its length, and taken off with an empty one",
		Run = function(t: any)
			-- TR17's rename: stored raw (tidied), filtered by the server before the rule and for each viewer when shown.
			local data = fresh()
			local id = Collection.Uncover(data, "rook", NOW).Id
			local max = VoidkinConfig.Nickname.Max
			local answer = Collection.Actions.SetNickname(data, { Voidkin = id, Name = "  Iron   Fist " }, NOW, 0)
			t.Check("given, its ends trimmed and its spaces one", answer.Ok == true and data.Voidkin[id].Nickname == "Iron Fist" and answer.Nickname == "Iron Fist", tostring(data.Voidkin[id].Nickname))
			t.Equal("its length counted in characters, not bytes", Collection.CleanName(string.rep("é", max)), string.rep("é", max))
			t.Equal("one past the most", select(2, Collection.CleanName(string.rep("a", max + 1))), Collection.TooLong)
			t.Equal("a line break is no name", select(2, Collection.CleanName("Iron\nFist")), Collection.BadName)
			t.Equal("nor broken text", select(2, Collection.CleanName("\255\254")), Collection.BadName)
			t.Equal("nor a number", Collection.SetNickname(data, id, 7).Error, Collection.BadName)
			t.Equal("a refused one leaves the old", data.Voidkin[id].Nickname, "Iron Fist")
			t.Check("an empty one takes it off", Collection.SetNickname(data, id, "   ").Ok == true and data.Voidkin[id].Nickname == "")
			t.Equal("not owned", Collection.SetNickname(data, "k99", "Fist").Error, Collection.Unknown)
			t.Equal("no args", Collection.Actions.SetNickname(data, nil, NOW, 0).Error, Collection.Unknown)
			local problems = Saveable.Problems(data, "profile")
			t.Check("saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Collection: every Voidkin names its signature and its passive in plain words, and Kirra's and Rook's are the roster's",
		Run = function(t: any)
			-- One Voidkin's screen reads them in its Kit tab (TR17): "Name: what it does", the roster's columns.
			for _, row in Voidkin.List do
				for _, kind in { "Signature", "Passive" } do
					local said = (row.Words :: any)[kind]
					local name, words = string.match(said, "^([^:]+): (.+)$")
					t.Check(`{row.Id}'s {kind}`, name ~= nil and words ~= nil and #words > 8, said)
				end
			end
			t.Equal("Rook's", Voidkin.ById.rook.Words.Passive, "Second Wind: takes less damage below 30% health")
			t.Equal("Kirra's", Voidkin.ById.kirra.Words.Signature, "Scarf Step: vanishes, crosses the target, cuts on the way out")
		end,
	},
	{
		Name = "Collection: TR22, the showcase at the gate stands the strongest until one is picked, any owned one, and the strongest again once the pick is gone",
		Run = function(t: any)
			local data = fresh()
			t.Equal("none owned, none shown", Collection.Showcase(data), nil)
			local rook = Collection.Uncover(data, "rook", NOW).Id
			local watt = Collection.Uncover(data, "watt", NOW + 1).Id
			data.Voidkin[watt].Level = 12
			local function power(id: string): number
				local owned = data.Voidkin[id]
				return Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
			end
			local strongest = if power(watt) >= power(rook) then watt else rook
			local shown = Collection.Showcase(data)
			t.Check("the strongest by Combat Power, until a pick", shown ~= nil and shown.Id == strongest, `{power(rook)} against {power(watt)}`)
			local other = if strongest == watt then rook else watt
			local picked = Collection.Actions.SetShowcase(data, { Voidkin = other }, NOW, 0.5)
			t.Check("any owned one may be picked", picked.Ok == true and picked.Id == other)
			t.Equal("and it stands", (Collection.Showcase(data) :: Profile.OwnedVoidkin).Id, other)
			data.Roles.Lead = other
			t.Equal("whatever its role", (Collection.Showcase(data) :: Profile.OwnedVoidkin).Id, other)
			t.Equal("one not owned is refused", Collection.SetShowcase(data, "nobody").Error, Collection.Unknown)
			t.Equal("a number is refused", Collection.SetShowcase(data, 5).Error, Collection.Unknown)
			t.Equal("and the pick stays", data.Base.Showcase, other)
			t.Check("\"\" gives it back to the strongest", Collection.SetShowcase(data, "").Ok == true and (Collection.Showcase(data) :: Profile.OwnedVoidkin).Id == strongest)
			Collection.SetShowcase(data, other)
			data.Voidkin[other] = nil
			t.Equal("a pick that's gone: the strongest again", (Collection.Showcase(data) :: Profile.OwnedVoidkin).Id, strongest)
			local twin = fresh()
			local a = Collection.Uncover(twin, "rook", NOW).Id
			local b = Collection.Uncover(twin, "pip", NOW).Id
			twin.Voidkin[b].Def = "rook"
			local first = (Collection.Showcase(twin) :: Profile.OwnedVoidkin).Id
			t.Check("two alike: always the same one, so it never flickers", first == (if a < b then a else b) and (Collection.Showcase(twin) :: Profile.OwnedVoidkin).Id == first, `{a}, {b}: {first}`)
		end,
	},
}
