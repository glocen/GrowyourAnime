--!strict
-- Shop cases (pure): the Void Shop's rule (AR38; docs/design.md, "The Void Shop"; Rules.Shop). The clock on world time;
-- the shelf for a stock, the same from every server and new with the salt; how often a piece is featured and what it
-- is; a buy, a refusal at the limit and every other refusal changing nothing; a repeated request answering its first
-- answer; the count kept against the stock's number, so a server hop never refills a line and a new stock does; the save
-- after it; and buys seeded over many stocks, pressed late, repeated and cut short, spending each Credit once and never
-- passing a line's limit (section 9). Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local ShopConfig = require(Shared.Config.Shop)
local ChestsConfig = require(Shared.Config.Chests)
local Items = require(Shared.Definitions.Items)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local Growth = require(Shared.Rules.Growth)
local Shop = require(Shared.Rules.Shop)

local SALT = 918273645
local OP = "5e1f0a2b-7c3d-4e9f-8a1b-2c3d4e5f6a7b"
local NOW = 1_800_000_123

local function fresh(credits: number): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	data.Currency.Credits = credits
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

-- The first stock at or after `from` that holds a piece, under `salt`.
local function featuredFrom(from: number, salt: number): number
	local stock = from
	while not Shop.Shelf(stock, salt).Featured do
		stock += 1
	end
	return stock
end

local function top(): number
	local row = Grounds.ById[ShopConfig.Featured.Ground]
	return Growth.G(if row then row.LevelTo else 1)
end

return {
	{
		Name = "Shop: a stock every period on world time, its number the time over the period, floored",
		Run = function(t: any)
			local period = ShopConfig.Period
			local stock = Shop.Stock(NOW)
			t.Equal("its number", stock, math.floor(NOW / period))
			t.Check("it stands from its start to the next's", Shop.Stock(stock * period) == stock and Shop.Stock(Shop.Ends(stock) - 0.001) == stock)
			t.Equal("the next at its end", Shop.Stock(Shop.Ends(stock)), stock + 1)
			t.Equal("its end a period on from its start", Shop.Ends(stock) - stock * period, period)
		end,
	},
	{
		Name = "Shop: the building's five minutes count a stock down, the first first, the running one by its share left",
		Run = function(t: any)
			local each = ShopConfig.Period / 5
			local function all(left: number): string
				local out = {}
				for index = 1, 5 do
					table.insert(out, string.format("%.2f", Shop.Minute(left, index, 5)))
				end
				return table.concat(out, " ")
			end
			t.Equal("a new stock: all five to run", all(ShopConfig.Period), "1.00 1.00 1.00 1.00 1.00")
			t.Equal("half its first minute gone", all(ShopConfig.Period - each / 2), "0.50 1.00 1.00 1.00 1.00")
			t.Equal("the first spent, the second just begun", all(ShopConfig.Period - each), "0.00 1.00 1.00 1.00 1.00")
			t.Equal("a quarter of the last minute left", all(each / 4), "0.00 0.00 0.00 0.00 0.25")
			t.Equal("at its end, all spent", all(0), "0.00 0.00 0.00 0.00 0.00")
			t.Equal("past its end, still spent", Shop.Minute(-1, 5, 5), 0)
		end,
	},
	{
		Name = "Shop: a stock's shelf is the same from every server, new with the salt, and draws in [0, 1)",
		Run = function(t: any)
			local stock = Shop.Stock(NOW)
			t.Check("the same stock and salt, the same shelf", same(Shop.Shelf(stock, SALT), Shop.Shelf(stock, SALT)))
			local inRange, apart, saltApart = true, 0, 0
			for n = 0, 199 do
				local u = Shop.Draw(SALT, stock + n, 2)
				inRange = inRange and u >= 0 and u < 1
				if u ~= Shop.Draw(SALT, stock + n + 1, 2) then
					apart += 1
				end
				if u ~= Shop.Draw(SALT + 1, stock + n, 2) then
					saltApart += 1
				end
			end
			t.Check("every draw in [0, 1)", inRange)
			t.Check("the next stock draws apart", apart == 200, `{apart} of 200`)
			t.Check("another salt draws apart: a client without it can't foresee a stock", saltApart == 200, `{saltApart} of 200`)
			local shelf = Shop.Shelf(stock, SALT)
			t.Equal("its stock", shelf.Stock, stock)
			t.Equal("its end", shelf.Ends, Shop.Ends(stock))
			local shard = shelf.Lines.Shard
			t.Check("a Standard shard from the pool", shard ~= nil and table.find(ShopConfig.Shard.Pool, shard.Shard :: string) ~= nil and Shards.ById[shard.Shard :: string].Grade == "Standard")
			t.Equal("its limit a player", shard.Limit, ShopConfig.Shard.Limit)
			t.Equal("its price, its seed times G at the ground's top", shard.Price, math.floor(ShopConfig.Shard.PricePerG * top() + 0.5))
			t.Check("no piece but on a featured stock", (shelf.Lines.Featured ~= nil) == shelf.Featured)
		end,
	},
	{
		Name = "Shop: a piece is featured about its chance, and it's a real piece of the ladder's rarities at its price",
		Run = function(t: any)
			local stock = Shop.Stock(NOW)
			local featured = 0
			local rarities: { [string]: number }, slots: { [string]: boolean } = {}, {}
			local valid = true
			local count = 6000
			for n = 0, count - 1 do
				local shelf = Shop.Shelf(stock + n, SALT)
				if shelf.Featured then
					featured += 1
					local line = shelf.Lines.Featured
					local item = line.Item :: any
					local row = Items.ById[item.Def]
					local rank = table.find(ChestsConfig.Rarities, item.Rarity)
					valid = valid
						and row ~= nil
						and rank ~= nil
						and (ShopConfig.Featured.Ladder[rank :: number] or 0) > 0
						and item.Tier == Grounds.ById[ShopConfig.Featured.Ground].Order
						and #item.Lines >= 1
						and line.Price == math.floor((ShopConfig.Featured.PricePerG[item.Rarity] or 0) * top() + 0.5)
						and line.Price > 0
						and line.Limit == ShopConfig.Featured.Limit
					rarities[item.Rarity] = (rarities[item.Rarity] or 0) + 1
					slots[row and row.Slot or "?"] = true
				end
			end
			local share = featured / count
			local chance = ShopConfig.Featured.Chance
			local spread = 4 * math.sqrt(chance * (1 - chance) / count)
			t.Check("featured about its chance", math.abs(share - chance) <= spread, string.format("%.4f against %.4f ± %.4f", share, chance, spread))
			t.Check("every piece real, of the ladder, at its ground's tier, priced", valid)
			local odds = Shop.FeaturedOdds()
			for rarity, odd in odds do
				local seen = (rarities[rarity] or 0) / math.max(featured, 1)
				local band = 4 * math.sqrt(math.max(odd * (1 - odd), 1e-6) / math.max(featured, 1)) + 1e-9
				t.Check(`{rarity}: drawn at its weight`, math.abs(seen - odd) <= band, string.format("%.3f against %.3f", seen, odd))
			end
			local sum = 0
			for _, odd in odds do
				sum += odd
			end
			t.Check("the featured odds add up to 1", math.abs(sum - 1) < 1e-9, tostring(sum))
			local kinds = 0
			for _ in slots do
				kinds += 1
			end
			t.Check("pieces of many slots", kinds >= 8, `{kinds} slots`)
		end,
	},
	{
		Name = "Shop: a buy spends its Credits and lands its shards, counted against the stock; the limit refuses the next",
		Run = function(t: any)
			local stock = Shop.Stock(NOW)
			local shelf = Shop.Shelf(stock, SALT)
			local line = shelf.Lines.Shard
			local shard = line.Shard :: string
			local data = fresh(line.Price * 10)
			t.Equal("all left at first", Shop.Left(data, shelf, "Shard"), line.Limit)
			local first = Shop.Buy(data, shelf, { Stock = stock, Line = "Shard", Count = 1 })
			t.Check("bought", first.Ok == true and first.Credits == line.Price and first.Shard == shard)
			t.Equal("the shard in the bag", data.Bag.Shards[shard], 1)
			t.Equal("its Credits gone", data.Currency.Credits, line.Price * 9)
			t.Equal("one fewer left", Shop.Left(data, shelf, "Shard"), line.Limit - 1)
			local rest = Shop.Buy(data, shelf, { Stock = stock, Line = "Shard", Count = line.Limit - 1 })
			t.Check("the rest in one", rest.Ok == true and data.Bag.Shards[shard] == line.Limit)
			local before = Profile.DeepCopy(data)
			local over = Shop.Buy(data, shelf, { Stock = stock, Line = "Shard", Count = 1 })
			t.Equal("past the limit: refused", over.Error, Shop.Limit)
			t.Check("and nothing changed", same(data, before))
			t.Equal("none left", Shop.Left(data, shelf, "Shard"), 0)
		end,
	},
	{
		Name = "Shop: a server hop never refills a line, a new stock does, and another player's buy takes nothing from one's own",
		Run = function(t: any)
			local stock = Shop.Stock(NOW)
			local line = Shop.Shelf(stock, SALT).Lines.Shard
			local data = fresh(line.Price * 10)
			t.Check("bought out", Shop.Buy(data, Shop.Shelf(stock, SALT), { Stock = stock, Line = "Shard", Count = line.Limit }).Ok == true)
			local hop = Shop.Shelf(stock, SALT) -- another server's shelf of the same stock, with the save
			local before = Profile.DeepCopy(data)
			t.Equal("another server: still bought out", Shop.Buy(data, hop, { Stock = stock, Line = "Shard", Count = 1 }).Error, Shop.Limit)
			t.Check("and nothing changed", same(data, before))
			local other = fresh(line.Price * 10)
			t.Equal("another player: their own count", Shop.Left(other, hop, "Shard"), line.Limit)
			local nextShelf = Shop.Shelf(stock + 1, SALT)
			t.Equal("the next stock: all left", Shop.Left(data, nextShelf, "Shard"), nextShelf.Lines.Shard.Limit)
			local again = Shop.Buy(data, nextShelf, { Stock = stock + 1, Line = "Shard", Count = 1 })
			t.Check("and bought", again.Ok == true and data.Shop.Stock == stock + 1 and data.Shop.Bought.Shard == 1 and data.Shop.Bought.Featured == nil)
		end,
	},
	{
		Name = "Shop: a featured piece lands as a new item, the shelf's own, once a stock",
		Run = function(t: any)
			local stock = featuredFrom(Shop.Stock(NOW), SALT)
			local shelf = Shop.Shelf(stock, SALT)
			local line = shelf.Lines.Featured
			local data = fresh(line.Price + 5)
			local bought = Shop.Buy(data, shelf, { Stock = stock, Line = "Featured", Count = 1 })
			t.Check("bought", bought.Ok == true and type(bought.Items) == "table" and #bought.Items == 1)
			local item = data.Items[bought.Items[1]]
			local piece = line.Item :: any
			t.Check("the shelf's piece", item ~= nil and item.Def == piece.Def and item.Rarity == piece.Rarity and item.Tier == piece.Tier and item.Design == piece.Design and same(item.Lines, piece.Lines) and same(item.Sockets, piece.Sockets))
			t.Check("its own copy: the shelf's piece untouched by a change to it", item.Lines ~= piece.Lines)
			t.Equal("its Credits gone", data.Currency.Credits, 5)
			t.Equal("once a stock", Shop.Buy(data, shelf, { Stock = stock, Line = "Featured", Count = 1 }).Error, Shop.Limit)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save is saveable", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Shop and the wallet (Roblox's paid random items): where restricted, a shard takes earned Credits only and the piece shown any; elsewhere a shard takes earned first",
		Run = function(t: any)
			local stock = featuredFrom(Shop.Stock(NOW), SALT)
			local shelf = Shop.Shelf(stock, SALT)
			local shard, piece = shelf.Lines.Shard, shelf.Lines.Featured
			local data = fresh(shard.Price + piece.Price)
			data.Currency.Bought = shard.Price + piece.Price -- every Credit bought
			local before = Profile.DeepCopy(data)
			t.Equal("restricted, all bought: a shard is Restricted", Shop.Buy(data, shelf, { Stock = stock, Line = "Shard", Count = 1 }, true).Error, Shop.Restricted)
			t.Check("and nothing changed", same(data, before))
			local shown = Shop.Buy(data, shelf, { Stock = stock, Line = "Featured", Count = 1 }, true)
			t.Check("restricted: the piece shown is a sure buy, bought Credits pay", shown.Ok == true and data.Currency.Credits == shard.Price and data.Currency.Bought == shard.Price)
			local free = Shop.Buy(data, shelf, { Stock = stock, Line = "Shard", Count = 1 }, false)
			t.Check("unrestricted: bought Credits buy a shard", free.Ok == true and data.Currency.Credits == 0 and data.Currency.Bought == nil)
			local mixed = fresh(shard.Price * 2)
			mixed.Currency.Bought = shard.Price
			local first = Shop.Buy(mixed, shelf, { Stock = stock, Line = "Shard", Count = 1 }, true)
			t.Check("restricted, one shard earned: it buys from the earned", first.Ok == true and mixed.Currency.Credits == shard.Price and mixed.Currency.Bought == shard.Price)
			t.Equal("the next: Restricted", Shop.Buy(mixed, shelf, { Stock = stock, Line = "Shard", Count = 1 }, true).Error, Shop.Restricted)
			local poor = fresh(shard.Price - 1)
			t.Equal("too few Credits at all: Poor, before Restricted", Shop.Buy(poor, shelf, { Stock = stock, Line = "Shard", Count = 1 }, true).Error, Shop.Poor)
		end,
	},
	{
		Name = "Shop: a refused buy changes nothing: the stock turned, too few Credits, a full bag, no such line, a count that isn't one",
		Run = function(t: any)
			local stock = featuredFrom(Shop.Stock(NOW), SALT)
			local shelf = Shop.Shelf(stock, SALT)
			local data = fresh(shelf.Lines.Shard.Price - 1)
			local refusals = {
				{ "the stock turned since the press", { Stock = stock - 1, Line = "Shard", Count = 1 }, Shop.Gone },
				{ "no stock named", { Line = "Shard", Count = 1 }, Shop.Gone },
				{ "too few Credits", { Stock = stock, Line = "Shard", Count = 1 }, Shop.Poor },
				{ "no such line", { Stock = stock, Line = "Rare", Count = 1 }, Shop.Unknown },
				{ "none", { Stock = stock, Line = "Shard", Count = 0 }, Shop.Unknown },
				{ "past the line's limit", { Stock = stock, Line = "Shard", Count = shelf.Lines.Shard.Limit + 1 }, Shop.Unknown },
				{ "a part", { Stock = stock, Line = "Shard", Count = 1.5 }, Shop.Unknown },
				{ "a word", { Stock = stock, Line = "Shard", Count = "two" }, Shop.Unknown },
				{ "no arguments", nil, Shop.Unknown },
			}
			for _, case in refusals do
				local before = Profile.DeepCopy(data)
				local answer = Shop.Buy(data, shelf, case[2])
				t.Check(`{case[1]}: refused, nothing changed`, answer.Ok == false and answer.Error == case[3] and same(data, before), tostring(answer.Error))
			end
			local plain = Shop.Shelf(Shop.Stock(NOW), SALT)
			if not plain.Featured then
				local rich = fresh(10 ^ 9)
				t.Equal("no piece on an ordinary stock", Shop.Buy(rich, plain, { Stock = plain.Stock, Line = "Featured", Count = 1 }).Error, Shop.Unknown)
			end
			local full = fresh(10 ^ 9)
			for i = 1, ChestsConfig.Bag do
				full.Items[`f{i}`] = { Id = `f{i}`, Def = (shelf.Lines.Featured.Item :: any).Def, Tier = 1, Rarity = "Common", Design = 1, Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} }
			end
			local before = Profile.DeepCopy(full)
			t.Equal("a full bag: the piece refused", Shop.Buy(full, shelf, { Stock = stock, Line = "Featured", Count = 1 }).Error, Shop.BagFull)
			t.Check("and nothing changed", same(full, before))
			t.Check("a shard still fits a full bag", Shop.Buy(full, shelf, { Stock = stock, Line = "Shard", Count = 1 }).Ok == true)
		end,
	},
	{
		Name = "Shop: a repeated buy answers its first answer and spends once",
		Run = function(t: any)
			local stock = Shop.Stock(NOW)
			local shelf = Shop.Shelf(stock, SALT)
			local line = shelf.Lines.Shard
			local data = fresh(line.Price * 10)
			local change = function(draft: Profile.Data): Transaction.Answer
				return Shop.Buy(draft, shelf, { Stock = stock, Line = "Shard", Count = 1 })
			end
			local first = Transaction.Run(data, OP, change, 8)
			t.Check("bought", first.Ok == true and data.Bag.Shards[line.Shard :: string] == 1)
			local before = Profile.DeepCopy(data)
			local again, changed = Transaction.Run(data, OP, change, 8)
			t.Check("the repeat changes nothing", not changed and same(data, before))
			t.Check("and answers the first answer", again.Ok == true and again.Credits == first.Credits)
			t.Equal("spent once", data.Currency.Credits, line.Price * 9)
		end,
	},
	{
		Name = "Shop (section 9): buys seeded over many stocks, pressed late, repeated and cut short in any order, spend each Credit once and never pass a line's limit",
		Run = function(t: any)
			local seed = 20261121
			local function roll(n: number): number
				seed = (seed * 16807) % 2147483647
				return seed % n + 1
			end
			local KEEP = 8
			local LIMITS = { Shard = ShopConfig.Shard.Limit, Featured = ShopConfig.Featured.Limit }
			local stock = featuredFrom(Shop.Stock(NOW), SALT)
			local shelf = Shop.Shelf(stock, SALT)
			local data = fresh(3_000)
			local function sum(map: { [string]: number }): number
				local n = 0
				for _, count in map do
					n += count
				end
				return n
			end
			local function count(map: { [string]: any }): number
				local n = 0
				for _ in map do
					n += 1
				end
				return n
			end
			local credits0, shards0, items0 = data.Currency.Credits, sum(data.Bag.Shards), count(data.Items)
			local earned, spent, shards, pieces = 0, 0, 0, 0
			local mine: { [number]: { [string]: number } } = {} -- what the player bought on each stock, by line
			local held: { string } = {}
			local sent: { [string]: { Stock: number, Line: string, Count: number } } = {}
			local bought: { [string]: number } = {}
			local refused: { [string]: number } = {}
			local repeats, cuts, turns, broken = 0, 0, 0, 0
			local function check(): string?
				if data.Currency.Credits ~= credits0 + earned - spent or data.Currency.Credits < 0 then
					return `Credits: {data.Currency.Credits} against {credits0 + earned - spent}`
				elseif sum(data.Bag.Shards) ~= shards0 + shards then
					return `shards: {sum(data.Bag.Shards)} against {shards0 + shards}`
				elseif count(data.Items) ~= items0 + pieces then
					return `items: {count(data.Items)} against {items0 + pieces}`
				end
				for at, lines in mine do
					for name, n in lines do
						if n > LIMITS[name] then
							return `{n} of {name} bought on stock {at}, past its limit {LIMITS[name]}`
						end
					end
				end
				for name in LIMITS do
					local mineHere = if mine[stock] then mine[stock][name] or 0 else 0
					if Shop.Bought(data, stock, name) ~= mineHere then
						return `the save counts {Shop.Bought(data, stock, name)} of {name} on this stock, the player bought {mineHere}`
					end
				end
				return nil
			end
			for step = 1, 400 do
				if roll(12) == 1 then -- the stock turns, half the time onto one with a piece
					stock = if roll(2) == 1 then featuredFrom(stock + 1, SALT) else stock + roll(2)
					shelf = Shop.Shelf(stock, SALT)
					turns += 1
				end
				if roll(25) == 1 then -- Credits come in from elsewhere: a fall, a salvage
					data.Currency.Credits += 1_500
					earned += 1_500
				end
				local op = string.format("%08x-0000-4000-8000-%012x", roll(24), 3)
				local ask = sent[op]
				if ask == nil then
					local pick = roll(10)
					local line = if pick <= 6 then "Shard" elseif pick <= 9 then "Featured" else "Nothing"
					ask = {
						Stock = if roll(8) == 1 then stock - 1 else stock, -- pressed as the stock turned
						Line = line,
						Count = if roll(12) == 1 then 0 else roll((LIMITS[line] or 2) + 1), -- now and then one past the limit
					}
					sent[op] = ask
				end
				local cut = roll(6) == 1 -- the server falls over after the buy, before its change finishes
				local before = Profile.DeepCopy(data)
				local answer, changed = Transaction.Run(data, op, function(draft: Profile.Data): Transaction.Answer
					local done = Shop.Buy(draft, shelf, ask)
					if cut then
						error("interrupted")
					end
					return done
				end, KEEP)
				local again = table.find(held, op) ~= nil
				local wrong: string? = nil
				if again or cut then
					if again then
						repeats += 1
					else
						cuts += 1
					end
					if changed or not same(data, before) then
						wrong = `a {if again then "repeat" else "cut"} changed the save`
					end
				elseif changed then
					local line = shelf.Lines[answer.Line]
					bought[answer.Line] = (bought[answer.Line] or 0) + 1
					mine[stock] = mine[stock] or {}
					mine[stock][answer.Line] = (mine[stock][answer.Line] or 0) + answer.Count
					spent += answer.Credits
					if ask.Stock ~= stock then
						wrong = `a press on stock {ask.Stock} bought from stock {stock}`
					elseif line == nil or answer.Credits ~= line.Price * answer.Count then
						wrong = `{answer.Line} cost {answer.Credits}`
					elseif answer.Line == "Shard" then
						shards += answer.Count
					else
						pieces += answer.Count
						for _, id in answer.Items do
							local piece, shelved = data.Items[id], line.Item :: any
							if piece == nil or piece.Def ~= shelved.Def or piece.Rarity ~= shelved.Rarity or piece.Tier ~= shelved.Tier then
								wrong = `the piece {id} isn't the shelf's own`
							end
						end
					end
					table.insert(held, op)
					if #held > KEEP then
						sent[table.remove(held, 1) :: string] = nil -- its next use is a new request
					end
				else
					refused[answer.Error] = (refused[answer.Error] or 0) + 1
					sent[op] = nil -- a refusal isn't kept: the next press is a new request
					if not same(data, before) then
						wrong = `a refusal ({answer.Error}) changed the save`
					end
				end
				wrong = wrong or check()
				if wrong then
					broken += 1
					t.Check(`step {step} ({ask.Line} x{ask.Count}): every Credit spent once, every line within its limit`, false, wrong)
					break
				end
			end
			t.Equal("no step spent twice or passed a limit", broken, 0)
			local each = {}
			for _, reason in { Shop.Gone, Shop.Limit, Shop.Poor, Shop.Unknown } do
				table.insert(each, `{reason} {refused[reason] or 0}`)
			end
			t.Check(
				`bought, refused, repeated ({repeats}) and cut ({cuts}) often over {turns} turns: Shard {bought.Shard or 0}, Featured {bought.Featured or 0}; refused {table.concat(each, ", ")}`,
				(bought.Shard or 0) >= 20 and (bought.Featured or 0) >= 3 and (refused[Shop.Gone] or 0) >= 3 and (refused[Shop.Limit] or 0) >= 5 and (refused[Shop.Poor] or 0) >= 3 and (refused[Shop.Unknown] or 0) >= 3 and repeats >= 20 and cuts >= 20 and turns >= 15
			)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
}
