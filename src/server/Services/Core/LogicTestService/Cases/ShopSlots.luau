--!strict
-- Shop slot cases (pure): the Void Shop's six slots (TR76; docs/design.md, "The Void Shop"; Rules.Shop). The three
-- always slots on every stock, the three sometimes ones about their chances; each line's goods real and of its stated
-- grade; each kind of goods landing in its place in the bag; the Power Deal paid from the battery as it stands, refused
-- short with what's missing, and spent once under one op id. The numbers are placeholders: these cases read them.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local ShopConfig = require(Shared.Config.Shop)
local JewelsConfig = require(Shared.Config.Jewels)
local ChestRows = require(Shared.Definitions.Chests)
local Shards = require(Shared.Definitions.Shards)
local Items = require(Shared.Definitions.Items)
local Shop = require(Shared.Rules.Shop)
local Emblems = require(Shared.Rules.Emblems)
local Jewels = require(Shared.Rules.Jewels)
local Breaker = require(Shared.Rules.Breaker)
local Refusal = require(Shared.Rules.Refusal)

local SALT = 556677881
local NOW = 1_800_000_123
local OP = "7d6c5b4a-3928-4170-8f6e-5d4c3b2a1908"
local OTHER_OP = "8e7d6c5b-4a39-4281-907f-6e5d4c3b2a19"
local MANY = 20000

local function fresh(credits: number, charge: number): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	Breaker.Advance(data, NOW) -- the base's stamp at NOW, so a buy's Advance moves nothing
	data.Currency.Credits = credits
	data.Base.Charge = charge
	return data
end

-- The first stock from `from` whose shelf passes `wanted`.
local function find(from: number, wanted: (Shop.Shelf) -> boolean): Shop.Shelf
	local stock = from
	while not wanted(Shop.Shelf(stock, SALT)) do
		stock += 1
	end
	return Shop.Shelf(stock, SALT)
end

local function within(t: any, label: string, seen: number, chance: number, count: number)
	local spread = 4 * math.sqrt(chance * (1 - chance) / count) + 1e-9
	t.Check(label, math.abs(seen / count - chance) <= spread, string.format("%.4f against %.4f ± %.4f", seen / count, chance, spread))
end

local function buy(data: Profile.Data, shelf: Shop.Shelf, name: string): { [string]: any }
	return Shop.Buy(data, shelf, { Stock = shelf.Stock, Line = name, Count = 1 }, NOW)
end

return {
	{
		Name = "Shop slots: the three always slots stand on every stock; the three sometimes ones come about their chances",
		Run = function(t: any)
			local from = Shop.Stock(NOW)
			local always, manuals, featured, crown, legend, ordered = true, 0, 0, 0, 0, true
			local deals: { [string]: number } = {}
			for n = 0, MANY - 1 do
				local shelf = Shop.Shelf(from + n, SALT)
				local lines = shelf.Lines
				always = always and lines.Shard ~= nil and lines.Supply ~= nil and lines.Power ~= nil
				if lines.Supply and lines.Supply.Token == "Manual" then
					manuals += 1
				end
				if lines.Power then
					deals[lines.Power.Chest :: string] = (deals[lines.Power.Chest :: string] or 0) + 1
				end
				featured += if shelf.Featured then 1 else 0
				crown += if shelf.Crown then 1 else 0
				legend += if shelf.Legend then 1 else 0
				for name, line in lines do
					ordered = ordered and ({ Shard = 1, Supply = 2, Power = 3, Featured = 4, Crown = 5, Legend = 6 })[name] == line.Slot
				end
				ordered = ordered and shelf.Featured == (lines.Featured ~= nil) and shelf.Crown == (lines.Crown ~= nil) and shelf.Legend == (lines.Legend ~= nil)
			end
			t.Check("the shard, the supply and the Power Deal, every stock", always)
			t.Check("each line in its slot; the shelf's flags say which stand", ordered)
			within(t, "a Skill Manual in the supply about its chance", manuals, ShopConfig.Supply.Manual.Chance, MANY)
			within(t, "a piece about its chance", featured, ShopConfig.Featured.Chance, MANY)
			within(t, "the crown lit about its chance", crown, ShopConfig.Crown.Chance, MANY)
			within(t, "the legend about its chance (once in four hours)", legend, ShopConfig.Legend.Chance, MANY)
			for _, deal in ShopConfig.Power.Pool do
				within(t, `the Power Deal: {deal.Chest} evenly`, deals[deal.Chest] or 0, 1 / #ShopConfig.Power.Pool, MANY)
			end
			t.Check("the legend about once in four hours", math.abs(ShopConfig.Legend.Chance * 4 * 3600 / ShopConfig.Period - 1) < 0.01)
		end,
	},
	{
		Name = "Shop slots: every line's goods are real, of their stated grade, at their price",
		Run = function(t: any)
			local from = Shop.Stock(NOW)
			local real = true
			local why = ""
			local function need(ok: boolean, label: string)
				if not ok and real then
					real, why = false, label
				end
			end
			for n = 0, 3999 do
				local shelf = Shop.Shelf(from + n, SALT)
				for name, line in shelf.Lines do
					need(line.Price > 0 and line.Limit >= 1 and line.Each >= 1, `{name}: a price, a limit and a count`)
					need(line.Currency == (if name == "Power" then "Kwh" else "Credits"), `{name}: its currency`)
					local goods = 0
					for _, key in { "Shard", "Grade", "Token", "Chest", "Item", "Emblem", "Jewel" } do
						goods += if (line :: any)[key] ~= nil then 1 else 0
					end
					need(goods == 1, `{name}: one kind of goods`)
					if line.Shard then
						need(Shards.ById[line.Shard] ~= nil, `{name}: a real shard`)
					end
					if line.Chest then
						need(ChestRows.ById[line.Chest] ~= nil, `{name}: a real chest`)
					end
					if line.Item then
						need(Items.ById[line.Item.Def] ~= nil and #line.Item.Lines >= 1, `{name}: a real piece`)
					end
				end
				local crown = shelf.Lines.Crown
				if crown and crown.Emblem then
					local parsed = Emblems.Parse(crown.Emblem)
					need(parsed ~= nil and parsed.Set.Rarity == ShopConfig.Crown.Emblem.Rarity, "Crown: an emblem of its stated rarity")
				elseif crown and crown.Jewel then
					local colour, tier = Jewels.Parse(crown.Jewel)
					need(colour ~= nil and table.find(JewelsConfig.Colours, colour) ~= nil and tier == ShopConfig.Crown.Jewel.Tier, "Crown: a jewel of its stated tier")
				end
				local legend = shelf.Lines.Legend
				if legend and legend.Item then
					need(legend.Item.Rarity == ShopConfig.Legend.Gear.Rarity, "Legend: a Legendary piece")
				elseif legend and legend.Shard then
					need(table.find(ShopConfig.Legend.Named.Pool, legend.Shard) ~= nil and Shards.ById[legend.Shard].Grade == "Named", "Legend: a Named shard from its pool")
				end
				local supply = shelf.Lines.Supply
				need(supply.Token == "Manual" or (supply.Grade == ShopConfig.Supply.Stones.Grade and supply.Each == ShopConfig.Supply.Stones.Each), "Supply: a manual or its stone bundle")
			end
			t.Check("every line real", real, why)
			-- both kinds of crown and of legend come
			local emblem = find(from, function(s: Shop.Shelf): boolean return s.Lines.Crown ~= nil and s.Lines.Crown.Emblem ~= nil end)
			local jewel = find(from, function(s: Shop.Shelf): boolean return s.Lines.Crown ~= nil and s.Lines.Crown.Jewel ~= nil end)
			local gear = find(from, function(s: Shop.Shelf): boolean return s.Lines.Legend ~= nil and s.Lines.Legend.Item ~= nil end)
			local named = find(from, function(s: Shop.Shelf): boolean return s.Lines.Legend ~= nil and s.Lines.Legend.Shard ~= nil end)
			t.Check("an emblem, a jewel, a Legendary piece and a Named shard all come", emblem and jewel and gear and named and true or false)
		end,
	},
	{
		Name = "Shop slots: each kind of goods lands in its place, and its price leaves",
		Run = function(t: any)
			local from = Shop.Stock(NOW)
			type Case = { Label: string, Line: string, Wanted: (Shop.Shelf) -> boolean, Landed: (Profile.Data, Shop.Line) -> boolean }
			local function legendary(d: Profile.Data, l: Shop.Line): boolean
				for _, item in d.Items do
					if item.Def == (l.Item :: any).Def and item.Rarity == "Legendary" then
						return true
					end
				end
				return false
			end
			local cases: { Case } = {
				{ Label = "stones", Line = "Supply", Wanted = function(s: Shop.Shelf): boolean return s.Lines.Supply.Grade ~= nil end, Landed = function(d: Profile.Data, l: Shop.Line): boolean return d.Bag.Stones[l.Grade :: string] == l.Each end },
				{ Label = "a Skill Manual", Line = "Supply", Wanted = function(s: Shop.Shelf): boolean return s.Lines.Supply.Token ~= nil end, Landed = function(d: Profile.Data, l: Shop.Line): boolean return d.Bag.Tokens.Manual == l.Each end },
				{ Label = "a pouch or a case", Line = "Power", Wanted = function(_s: Shop.Shelf): boolean return true end, Landed = function(d: Profile.Data, l: Shop.Line): boolean return d.Bag.Chests[l.Chest :: string] == 1 end },
				{ Label = "an emblem", Line = "Crown", Wanted = function(s: Shop.Shelf): boolean return s.Lines.Crown ~= nil and s.Lines.Crown.Emblem ~= nil end, Landed = function(d: Profile.Data, l: Shop.Line): boolean return d.Bag.Emblems[l.Emblem :: string] == 1 end },
				{ Label = "a jewel", Line = "Crown", Wanted = function(s: Shop.Shelf): boolean return s.Lines.Crown ~= nil and s.Lines.Crown.Jewel ~= nil end, Landed = function(d: Profile.Data, l: Shop.Line): boolean return d.Bag.Jewels[l.Jewel :: string] == 1 end },
				{ Label = "a Legendary piece", Line = "Legend", Wanted = function(s: Shop.Shelf): boolean return s.Lines.Legend ~= nil and s.Lines.Legend.Item ~= nil end, Landed = legendary },
				{ Label = "a Named shard", Line = "Legend", Wanted = function(s: Shop.Shelf): boolean return s.Lines.Legend ~= nil and s.Lines.Legend.Shard ~= nil end, Landed = function(d: Profile.Data, l: Shop.Line): boolean return d.Bag.Shards[l.Shard :: string] == 1 end },
			}
			for _, case in cases do
				local shelf = find(from, case.Wanted)
				local name = case.Line
				local line = shelf.Lines[name]
				local data = fresh(1e7, 1000)
				local answer = buy(data, shelf, name)
				t.Check(`{case.Label}: bought`, answer.Ok == true, tostring(answer.Error))
				t.Check(`{case.Label}: landed`, case.Landed(data, line))
				if line.Currency == "Kwh" then
					t.Check(`{case.Label}: its kWh left the battery, no Credits`, data.Base.Charge == 1000 - line.Price and data.Currency.Credits == 1e7 and answer.Kwh == line.Price and answer.Credits == 0)
				else
					t.Check(`{case.Label}: its Credits left, no kWh`, data.Currency.Credits == 1e7 - line.Price and data.Base.Charge == 1000 and answer.Credits == line.Price)
				end
				t.Equal(`{case.Label}: once a stock`, buy(data, shelf, name).Error, Shop.Limit)
				local problems = Saveable.Problems(data, "profile")
				t.Check(`{case.Label}: the save stays whole`, #problems == 0, table.concat(problems, "; "))
			end
		end,
	},
	{
		Name = "Shop slots: the Power Deal is paid from the battery as it stands, refused short with what's missing, and spent once",
		Run = function(t: any)
			local shelf = Shop.Shelf(Shop.Stock(NOW), SALT)
			local deal = shelf.Lines.Power
			local data = fresh(1e7, deal.Price - 3)
			local short = buy(data, shelf, "Power")
			t.Check("3 kWh short: refused, nothing changed", short.Error == Shop.Short and short.Need == 3 and data.Base.Charge == deal.Price - 3 and next(data.Bag.Chests) == nil)
			t.Equal("it says what's missing", Refusal.Of("Shop", short), "Need 3 more kWh in the battery")
			t.Check("the Credits untouched", data.Currency.Credits == 1e7)
			data.Base.Charge = deal.Price + 2
			local change = function(draft: Profile.Data): Transaction.Answer
				return Shop.Buy(draft, shelf, { Stock = shelf.Stock, Line = "Power", Count = 1 }, NOW)
			end
			local first, changed = Transaction.Run(data, OP, change, 8)
			t.Check("bought", first.Ok == true and changed and data.Base.Charge == 2 and data.Bag.Chests[deal.Chest :: string] == 1)
			local again, againChanged = Transaction.Run(data, OP, change, 8)
			t.Check("its repeat spends nothing more and answers the first", not againChanged and again.Ok == true and data.Base.Charge == 2 and data.Bag.Chests[deal.Chest :: string] == 1)
			local over = Transaction.Run(data, OTHER_OP, change, 8)
			t.Equal("a new request: once a stock", over.Error, Shop.Limit)
			local poor = fresh(0, 0)
			local credits = buy(poor, shelf, "Shard")
			t.Check("a Credits line short says how many", credits.Error == Shop.Poor and credits.Need == shelf.Lines.Shard.Price)
			for _, code in { Shop.Short, Shop.Poor, Shop.Limit, Shop.Gone, Shop.Unknown, Shop.BagFull } do
				t.Check(`the Shop words {code}`, Refusal.Has("Shop", code))
			end
		end,
	},
}
