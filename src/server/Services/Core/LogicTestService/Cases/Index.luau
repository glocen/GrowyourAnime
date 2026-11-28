--!strict
-- Index cases (pure): the collection book (TR76; docs/design.md, "The Index"; Rules.Index, Rules.IndexBook). Its tabs
-- and stamps; each stamp earned from the save as it stands and the book's records (a Shade's falls, a gear design seen,
-- auto-salvaged or not, an emblem or jewel held); "Claim all" paying each find once and each milestone its points reach,
-- nothing on a second claim; a claimed stamp kept when what earned it leaves; the milestones' flat points in every
-- Voidkin's stats; reads that never write; section 9's repeat and cut. The numbers are placeholders: these cases read them.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local IndexConfig = require(Shared.Config.Index)
local MasteryConfig = require(Shared.Config.Mastery)
local ChestsConfig = require(Shared.Config.Chests)
local ChestRows = require(Shared.Definitions.Chests)
local VoidkinRows = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local Items = require(Shared.Definitions.Items)
local Tokens = require(Shared.Definitions.Tokens)
local Attributes = require(Shared.Definitions.Attributes)
local Index = require(Shared.Rules.Index)
local IndexBook = require(Shared.Rules.IndexBook)
local Collection = require(Shared.Rules.Collection)
local Chests = require(Shared.Rules.Chests)
local Stats = require(Shared.Rules.Stats)
local Jewels = require(Shared.Rules.Jewels)
local Refusal = require(Shared.Rules.Refusal)

local NOW = 1_800_000_123
local OP = "3c4d5e6f-7081-4923-bcde-f01234567890"
local OTHER_OP = "4d5e6f70-8192-4a34-8def-012345678901"

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

local function foeOf(kind: string): string
	for _, row in Enemies.List do
		if row.Kind == kind then
			return row.Id
		end
	end
	error(`no {kind}`)
end

-- Every chest, stone grade and token a pay row names is real.
local function payReal(row: IndexConfig.Pay): boolean
	for id in row.Chests or {} do
		if ChestRows.ById[id] == nil then
			return false
		end
	end
	for id in row.Tokens or {} do
		if Tokens.ById[id] == nil then
			return false
		end
	end
	return true
end

return {
	{
		Name = "Index: four tabs, each entry's stamps, and pay rows that name real things",
		Run = function(t: any)
			t.Equal("four tabs", #Index.Tabs, 4)
			t.Equal("every Voidkin an entry", #Index.Entries("Voidkin"), #VoidkinRows.List)
			local shades = 0
			for _, row in Enemies.List do
				shades += if row.Kind ~= "Dummy" then 1 else 0
			end
			t.Equal("every foe but the dummy", #Index.Entries("Shades"), shades)
			t.Check("gear designs and emblems and jewels listed", #Index.Entries("Regalia") > 0 and #Index.Entries("Emblems") > 0)
			local real = true
			for _, key in Index.Entries("Regalia") do
				local def, rarity, design = string.match(key, "^([^:]+):([^:]+):(%d+)$")
				real = real and def ~= nil and Items.ById[def :: string] ~= nil and table.find(ChestsConfig.Rarities, rarity :: string) ~= nil and tonumber(design) :: number <= Items.Designs(def :: string, rarity :: string)
			end
			t.Check("every gear entry a real design", real)
			t.Equal("a Voidkin's stamps: found, two stars, Mastery", #Index.Stamps("Voidkin", "rook"), 2 + #IndexConfig.Stars)
			t.Equal("a Shade's: found and its kills", #Index.Stamps("Shades", "brawler"), 1 + #IndexConfig.Kills)
			t.Equal("a design's: found", #Index.Stamps("Regalia", Index.Entries("Regalia")[1]), 1)
			local pays = true
			for _, row in IndexConfig.Find :: { [string]: IndexConfig.Pay } do
				pays = pays and payReal(row)
			end
			local last, attributes = 0, 0
			for _, milestone in IndexConfig.Milestones do
				pays = pays and payReal(milestone.Pay) and milestone.At > last
				last = milestone.At
				attributes += milestone.Pay.Attributes or 0
			end
			t.Check("every pay row names real chests and tokens; milestones climb", pays)
			t.Equal("the milestones' points: 50 to each Basic Attribute in all (placeholder)", attributes, 50)
			t.Check("the rank stamp is a real rank", IndexConfig.MasteryRank <= #MasteryConfig.Ranks)
		end,
	},
	{
		Name = "Index: stamps earned from the save and the book's records; a read never writes",
		Run = function(t: any)
			local data = fresh()
			t.Equal("a new account: nothing earned", next(Index.Earned(data)), nil)
			Collection.Uncover(data, "rook", NOW)
			local owned = Collection.Owned(data, "rook") :: Profile.OwnedVoidkin
			local have = Index.Earned(data)
			t.Check("found on its uncover", have["Voidkin|rook|Found"] == true and not have["Voidkin|rook|Stars3"])
			owned.Stars = 7
			owned.Mastery = MasteryConfig.Ranks[IndexConfig.MasteryRank]
			have = Index.Earned(data)
			t.Check("stars 3 and 7 and Mastery rank 5", have["Voidkin|rook|Stars3"] and have["Voidkin|rook|Stars7"] and have["Voidkin|rook|Mastery5"] or false)
			local foe = foeOf("Ordinary")
			for n = 1, 100 do
				IndexBook.Fell(data, foe)
				if n == 9 then
					t.Check("9 kills: found, not 10", Index.Earned(data)[`Shades|{foe}|Found`] == true and not Index.Earned(data)[`Shades|{foe}|Kills10`])
				end
			end
			have = Index.Earned(data)
			t.Check("100 kills: 10 and 100, not 500", have[`Shades|{foe}|Kills10`] and have[`Shades|{foe}|Kills100`] and not have[`Shades|{foe}|Kills500`] or false)
			IndexBook.Fell(data, nil)
			IndexBook.Fell(data, "")
			t.Equal("a fall with no foe counts nothing", (data.Book :: Profile.Book).Kills[""], nil)
			-- gear seen, auto-salvaged or not
			data.Settings.Salvage = "Legendary" -- everything salvaged
			Chests.Grant(data, "pouch", 0)
			local gearChest = ChestRows.ById["lanternrow_1"] and "lanternrow_1" or nil
			if gearChest then
				Chests.Grant(data, gearChest, 3)
				local n = 0
				local opened = Chests.Open(data, gearChest, 3, function(): number
					n += 1
					return (n * 0.37) % 1
				end)
				t.Check("a chest opened", opened.Ok == true, tostring(opened.Error))
				local seen = 0
				for _ in (data.Book :: Profile.Book).Gear do
					seen += 1
				end
				t.Check("its pieces found, salvaged or not", seen >= 1 and next(Index.Waiting(data).Stamps) ~= nil)
			end
			-- emblems and jewels held, read without writing
			data.Bag.Emblems["tidebreak:Health"] = 1
			local item = next(data.Items)
			data.Bag.Jewels[Jewels.Key("Red", 2)] = 1
			local before = Profile.DeepCopy(data)
			have = Index.Earned(data)
			t.Check("an emblem's set and a jewel found from the bag", have["Emblems|set:tidebreak|Found"] and have["Emblems|jewel:Red:2|Found"] or false)
			t.Check("reading wrote nothing", same(data, before))
			Index.Points(data)
			Index.Waiting(data)
			Index.Done(data, "Voidkin")
			t.Check("nor did Points, Waiting or Done", same(data, before))
			t.Check("(an item stays where it was)", item == next(data.Items))
		end,
	},
	{
		Name = "Index: Claim all pays each find once, its points reach milestones, and a second claim pays nothing",
		Run = function(t: any)
			local data = fresh()
			Collection.Uncover(data, "pip", NOW)
			local keeper = foeOf("Keeper")
			local foe = foeOf("Ordinary")
			IndexBook.Fell(data, keeper)
			IndexBook.Fell(data, foe)
			local credits = data.Currency.Credits
			local claim = Index.Claim(data)
			local find = IndexConfig.Find
			local want = (find.Voidkin.Credits or 0) + (find.Keeper.Credits or 0) + (find.Shade.Credits or 0)
			t.Check("three finds claimed", claim.Ok == true and claim.Stamps == 3, tostring(claim.Error))
			t.Equal("their Credits: a Voidkin's, a Keeper's own, a Shade's", data.Currency.Credits - credits, want)
			t.Equal("the Voidkin's crate", data.Bag.Chests.crate, (find.Voidkin.Chests :: any).crate)
			t.Equal("the Shade's stones", data.Bag.Stones.Low, (find.Shade.Stones :: any).Low)
			local before = Profile.DeepCopy(data)
			local again = Index.Claim(data)
			t.Check("a second claim: Nothing, and nothing changed", again.Ok == false and again.Error == Index.Nothing and same(data, before))
			t.Check("its words", Refusal.Has("Index", Index.Nothing))
			-- points to the first milestones, in one claim
			local first, second = IndexConfig.Milestones[1], IndexConfig.Milestones[2]
			local book = IndexBook.Of(data)
			for n = 1, second.At do
				book.Gear[`x{n}`] = true
			end
			local points = Index.Points(data)
			t.Check("past two milestones", points >= second.At, tostring(points))
			local reached = Index.Claim(data)
			t.Check("both paid in one claim", reached.Ok == true and #reached.Milestones >= 2 and reached.Milestones[1] == first.At and reached.Milestones[2] == second.At)
			t.Equal("their attribute points", IndexBook.Attributes(data), (first.Pay.Attributes or 0) + (second.Pay.Attributes or 0))
			t.Check("the milestones' chests", (data.Bag.Chests.pouch or 0) >= 1 and (data.Bag.Chests.towercase_rare or 0) >= 1)
			t.Equal("none twice", Index.Claim(data).Error, Index.Nothing)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Index: a claimed stamp stays when what earned it leaves; the milestones' points reach every Voidkin's stats",
		Run = function(t: any)
			local data = fresh()
			Collection.Uncover(data, "kirra", NOW)
			local owned = Collection.Owned(data, "kirra") :: Profile.OwnedVoidkin
			owned.Stars = 3
			Index.Claim(data)
			local points = Index.Points(data)
			owned.Stars = 0 -- whatever took the star away
			t.Equal("its points kept", Index.Points(data), points)
			t.Check("its stamp kept", Index.Earned(data)["Voidkin|kirra|Stars3"] == true)
			local block = Stats.Resolve(owned, nil, data)
			IndexBook.Of(data).Milestones[tostring(IndexConfig.Milestones[2].At)] = true
			local raised, lines = Stats.Resolve(owned, nil, data)
			local each = IndexConfig.Milestones[2].Pay.Attributes or 0
			local all, said = true, 0
			for _, id in Attributes.Ids do
				all = all and math.abs(raised.Attributes[id] - block.Attributes[id] - each) < 1e-9
			end
			for _, line in lines do
				said += if line.Source == "Index" then 1 else 0
			end
			t.Check("each Basic Attribute up by the milestone's points", all)
			t.Equal("a line for each, its source the Index", said, #Attributes.Ids)
			t.Check("and nothing without a save", Stats.Resolve(owned, nil, nil).Attributes.Strength == Stats.Resolve(owned, nil, fresh()).Attributes.Strength)
		end,
	},
	{
		Name = "Index: a tab done whole when every stamp of it is earned",
		Run = function(t: any)
			local data = fresh()
			t.Check("not done at first", not Index.Done(data, "Shades"))
			for _, foe in Index.Entries("Shades") do
				IndexBook.Of(data).Kills[foe] = IndexConfig.Kills[#IndexConfig.Kills]
			end
			t.Check("every Shade at its last stamp: done", Index.Done(data, "Shades"))
			t.Check("another tab isn't", not Index.Done(data, "Voidkin"))
		end,
	},
	{
		Name = "Index (section 9): a repeated claim answers its first answer and pays once; a cut changes nothing",
		Run = function(t: any)
			local data = fresh()
			Collection.Uncover(data, "watt", NOW)
			local change = function(draft: Profile.Data): Transaction.Answer
				return Index.Claim(draft)
			end
			local first, changed = Transaction.Run(data, OP, change, 8)
			t.Check("claimed", first.Ok == true and changed)
			local before = Profile.DeepCopy(data)
			local again, againChanged = Transaction.Run(data, OP, change, 8)
			t.Check("the repeat changes nothing and answers the first", not againChanged and same(data, before) and again.Ok == true and again.Credits == first.Credits)
			IndexBook.Fell(data, foeOf("Ordinary"))
			local cut = Profile.DeepCopy(data)
			local _, cutChanged = Transaction.Run(data, OTHER_OP, function(draft: Profile.Data): Transaction.Answer
				Index.Claim(draft)
				error("cut")
			end, 8)
			t.Check("a cut claim changes nothing", not cutChanged and same(data, cut))
		end,
	},
}
