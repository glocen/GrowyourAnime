--!strict
-- The Void Shop (shared, pure; AR38; docs/design.md, "The Strip", "The Void Shop"; TR76's rework, the director's yes of
-- 2026-11-28, 11:32; docs/engineering-plan.md, the profile's Shop).
--   The clock   a stock every Config.Shop.Period seconds of world time: its number is the Unix time over the period,
--               floored, so every server is on the same one with no messaging.
--   The shelf   a seeded draw on the stock's number and the server's salt, which never reaches a client, so nobody sees
--               a stock before it lands. Six slots (Config.Shop), each its own line with its own limit a player:
--                 1 Shard     always: a Standard shard, for Credits
--                 2 Supply    always: a forge stone bundle, or now and then a Skill Manual, for Credits
--                 3 Power     always: the Power Deal, a Jewel Pouch or an Emblem Case, for the battery's kWh
--                 4 Featured  often: a gear piece, rolled as the ground's chests roll on the Shop's weights
--                 5 Crown     sometimes: an emblem or a jewel of a stated grade; it lights the Shop's crown
--                 6 Legend    rarely: a Legendary piece or a Named shard; it goes out on the Broadcast
--               Each slot reads its own draws (slot x 1000 on), so a change to one slot's roll never moves another's.
--   A buy       one transaction (DataService.Change, with its op id, so a repeat answers its first answer): the price
--               leaves (Credits, or kWh from the battery as it stands at `now`) and the goods land in the same step, and a
--               refusal changes nothing. Each line has its own count a player, saved against the stock's number (Profile's
--               Shop), so one player's buy never empties another's and a server hop never refills a line. A buy names the
--               stock it was pressed on: one pressed as the stock turned is refused, never charged for a shelf the player
--               didn't see.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local ShopConfig = require(Shared.Config.Shop)
local ChestsConfig = require(Shared.Config.Chests)
local EmblemsConfig = require(Shared.Config.Emblems)
local JewelsConfig = require(Shared.Config.Jewels)
local ChestRows = require(Shared.Definitions.Chests)
local EmblemSets = require(Shared.Definitions.Emblems)
local Gear = require(Shared.Definitions.Gear)
local Grounds = require(Shared.Definitions.Grounds)
local Growth = require(Shared.Rules.Growth)
local Chests = require(Shared.Rules.Chests)
local Emblems = require(Shared.Rules.Emblems)
local Jewels = require(Shared.Rules.Jewels)
local Breaker = require(Shared.Rules.Breaker)
local IndexBook = require(Shared.Rules.IndexBook)

local Shop = {}

Shop.Unknown = "Unknown" -- no such line on this stock, or a count that isn't one
Shop.Gone = "Gone" -- the stock turned since the press: nothing bought
Shop.Limit = "Limit" -- that line's count for this stock is bought
Shop.Poor = "Poor" -- not enough Credits
Shop.BagFull = "BagFull" -- the piece would pass the bag's cap
Shop.Short = "Short" -- not enough kWh in the battery

export type Currency = "Credits" | "Kwh"

-- One slot's line. Its goods are one of Shard, Grade (forge stones), Token, Chest, Item, Emblem or Jewel; Each of them
-- lands per buy (a piece is always one).
export type Line = {
	Name: string, -- "Shard", "Supply", "Power", "Featured", "Crown" or "Legend"
	Slot: number, -- 1 to 6, the shelf's order
	Price: number, -- a buy's, in Currency
	Currency: Currency,
	Limit: number, -- buys a player each stock
	Each: number,
	Shard: string?, -- a shard's definition
	Grade: string?, -- forge stones of this grade (Config.Reinforce.Grades)
	Token: string?, -- a bag token (Definitions.Tokens)
	Chest: string?, -- a chest's definition: a pouch, a case
	Item: Chests.Rolled?, -- the piece
	Emblem: string?, -- an emblem's key, "set:stat"
	Jewel: string?, -- a jewel's key, "Colour:tier"
}

export type Shelf = {
	Stock: number,
	Ends: number, -- the Unix second the next stock lands
	Featured: boolean, -- slot 4 holds a piece
	Crown: boolean, -- slot 5 holds its line: the Shop's crown is lit
	Legend: boolean, -- slot 6 holds its line: the Broadcast says so
	Lines: { [string]: Line },
}

-- The stock standing at Unix second `now`.
function Shop.Stock(now: number): number
	return math.floor(now / ShopConfig.Period)
end

-- The Unix second stock `stock` gives way to the next.
function Shop.Ends(stock: number): number
	return (stock + 1) * ShopConfig.Period
end

-- The share still to run of the building's minute `index` of `count` (AR38's clock: the first runs first), with `left`
-- seconds of the stock to go: 1 while it waits, 0 once it's spent, and the running one in between.
function Shop.Minute(left: number, index: number, count: number): number
	return math.clamp(left * count / ShopConfig.Period - (count - index), 0, 1)
end

local TWO32 = 4294967296

-- a * b modulo 2^32, exact in a double: the low half's product stays under 2^49.
local function mul32(a: number, b: number): number
	local low, high = a % 65536, a // 65536
	return (low * b + ((high * b) % 65536) * 65536) % TWO32
end

-- MurmurHash3's finisher: every bit of the result hangs on every bit of `h`.
local function mix(h: number): number
	h = bit32.bxor(h, bit32.rshift(h, 16))
	h = mul32(h, 0x85ebca6b)
	h = bit32.bxor(h, bit32.rshift(h, 13))
	h = mul32(h, 0xc2b2ae35)
	return bit32.bxor(h, bit32.rshift(h, 16))
end

-- The salt's store transform (ShopService): the stored salt when there is one, written back as it is, so every server
-- draws with the first; else `fresh`. Never nil: UpdateAsync answers nil to a transform that cancels (measured in
-- Studio, 2026-11-27), and a server that read nil would keep the Shop closed.
function Shop.Salt(old: any, fresh: number): number
	if type(old) == "number" and old == math.floor(old) and old >= 1 then
		return old
	end
	return fresh
end

-- The `n`th draw of stock `stock` under `salt`, in [0, 1): the same three, the same draw.
function Shop.Draw(salt: number, stock: number, n: number): number
	local h = mix(bit32.bxor(salt % TWO32, mix(stock % TWO32)))
	return mix(bit32.bxor(h, n % TWO32)) / TWO32
end

local function index(count: number, u: number): number
	return math.clamp(math.floor(u * count) + 1, 1, count)
end

local function priced(perG: number): number
	local row = Grounds.ById[ShopConfig.Ground]
	return math.floor(perG * Growth.G(if row then row.LevelTo else 1) + 0.5)
end

-- A piece's roll stands as a chest of the Shop's ground (its tier and worth), on the slot's weights.
local PIECE_ROW: ChestRows.Row = { Id = "shop_featured", Ground = ShopConfig.Ground, Tier = 0, Name = "", Image = "", Difficulty = "Normal", Stage = 0 }

-- Every weapon class alike: the shelf is everyone's, so it leans to nobody's lead.
local CLASSES: { [string]: number } = {}
for class in Gear.Weapons do
	CLASSES[class] = 1
end

-- Each emblem rarity's sets, and the stats an emblem may have, in a fixed order so a draw lands the same everywhere.
local SETS: { [string]: { string } } = {}
for _, set in EmblemSets.List do
	SETS[set.Rarity] = SETS[set.Rarity] or {}
	table.insert(SETS[set.Rarity], set.Id)
end
local STATS: { string } = {}
for stat in EmblemsConfig.Points do
	table.insert(STATS, stat)
end
table.sort(STATS)

-- Slot `slot`'s draws: its `n`th, from slot x 1000 on.
local function draws(salt: number, stock: number, slot: number): (n: number) -> number
	return function(n: number): number
		return Shop.Draw(salt, stock, slot * 1000 + n)
	end
end

-- A piece rolled from a slot's draws 100 on, on `ladder`'s weights.
local function piece(at: (n: number) -> number, ladder: { number }): Chests.Rolled
	local n = 99
	return Chests.Roll(PIECE_ROW, CLASSES, function(): number
		n += 1
		return at(n)
	end, ladder)
end

-- The weights that roll only `rarity` (Config.Chests.Rarities' order).
local function only(rarity: string): { number }
	local out = {}
	for i, name in ChestsConfig.Rarities do
		out[i] = if name == rarity then 1 else 0
	end
	return out
end

local function line(name: string, slot: number, price: number, currency: Currency, limit: number, each: number): Line
	return { Name = name, Slot = slot, Price = price, Currency = currency, Limit = limit, Each = each }
end

-- The shelf of stock `stock` under `salt`. Within each slot, draw 1 says whether a sometimes slot holds its line, or
-- which kind an always slot holds; draws 2 on pick; a piece's roll reads draws 100 on.
function Shop.Shelf(stock: number, salt: number): Shelf
	local lines: { [string]: Line } = {}
	-- 1. the shard
	local shard = line("Shard", 1, priced(ShopConfig.Shard.PricePerG), "Credits", ShopConfig.Shard.Limit, 1)
	shard.Shard = ShopConfig.Shard.Pool[index(#ShopConfig.Shard.Pool, draws(salt, stock, 1)(2))]
	lines.Shard = shard
	-- 2. the supply: stones, or now and then a Skill Manual
	local supply = ShopConfig.Supply
	if draws(salt, stock, 2)(1) < supply.Manual.Chance then
		local manual = line("Supply", 2, priced(supply.Manual.PricePerG), "Credits", supply.Limit, supply.Manual.Each)
		manual.Token = "Manual"
		lines.Supply = manual
	else
		local stones = line("Supply", 2, priced(supply.Stones.PricePerG), "Credits", supply.Limit, supply.Stones.Each)
		stones.Grade = supply.Stones.Grade
		lines.Supply = stones
	end
	-- 3. the Power Deal
	local power = ShopConfig.Power
	local deal = power.Pool[index(#power.Pool, draws(salt, stock, 3)(2))]
	local powerLine = line("Power", 3, deal.Kwh, "Kwh", power.Limit, 1)
	powerLine.Chest = deal.Chest
	lines.Power = powerLine
	-- 4. a gear piece, often
	local featured = ShopConfig.Featured
	local d4 = draws(salt, stock, 4)
	if d4(1) < featured.Chance then
		local item = piece(d4, featured.Ladder)
		local gear = line("Featured", 4, priced(featured.PricePerG[item.Rarity] or 0), "Credits", featured.Limit, 1)
		gear.Item = item
		lines.Featured = gear
	end
	-- 5. the crown's, sometimes: an emblem or a jewel of its stated grade
	local crown = ShopConfig.Crown
	local d5 = draws(salt, stock, 5)
	if d5(1) < crown.Chance then
		local sets = SETS[crown.Emblem.Rarity] or {}
		if d5(2) < 0.5 and #sets > 0 and #STATS > 0 then
			local held = line("Crown", 5, priced(crown.Emblem.PricePerG), "Credits", crown.Limit, 1)
			held.Emblem = Emblems.Key(sets[index(#sets, d5(3))], STATS[index(#STATS, d5(4))])
			lines.Crown = held
		else
			local colours = JewelsConfig.Colours
			local held = line("Crown", 5, priced(crown.Jewel.PricePerG), "Credits", crown.Limit, 1)
			held.Jewel = Jewels.Key(colours[index(#colours, d5(3))], crown.Jewel.Tier)
			lines.Crown = held
		end
	end
	-- 6. the legend's, rarely: a Legendary piece or a Named shard
	local legend = ShopConfig.Legend
	local d6 = draws(salt, stock, 6)
	if d6(1) < legend.Chance then
		if d6(2) < 0.5 then
			local held = line("Legend", 6, priced(legend.Gear.PricePerG), "Credits", legend.Limit, 1)
			held.Item = piece(d6, only(legend.Gear.Rarity))
			lines.Legend = held
		else
			local pool = legend.Named.Pool
			local held = line("Legend", 6, priced(legend.Named.PricePerG), "Credits", legend.Limit, 1)
			held.Shard = pool[index(#pool, d6(3))]
			lines.Legend = held
		end
	end
	return {
		Stock = stock,
		Ends = Shop.Ends(stock),
		Featured = lines.Featured ~= nil,
		Crown = lines.Crown ~= nil,
		Legend = lines.Legend ~= nil,
		Lines = lines,
	}
end

-- How many of line `name` this account has bought on stock `stock`.
function Shop.Bought(data: Profile.Data, stock: number, name: string): number
	local held = data.Shop
	if held.Stock ~= stock then
		return 0
	end
	return held.Bought[name] or 0
end

-- How many of line `name` this account may still buy on `shelf`; 0 for a line the shelf hasn't.
function Shop.Left(data: Profile.Data, shelf: Shelf, name: string): number
	local held = shelf.Lines[name]
	if held == nil then
		return 0
	end
	return math.max(0, held.Limit - Shop.Bought(data, shelf.Stock, name))
end

-- Each featured rarity's chance on a stock that holds a piece, as its roll draws it.
function Shop.FeaturedOdds(): { [string]: number }
	local total = 0
	for _, weight in ShopConfig.Featured.Ladder do
		total += weight
	end
	local out = {}
	for i, name in ChestsConfig.Rarities do
		out[name] = if total > 0 then (ShopConfig.Featured.Ladder[i] or 0) / total else 0
	end
	return out
end

-- Buys `args.Count` of line `args.Line` from `shelf`, pressed on stock `args.Stock`, at Unix second `now` (the battery is
-- read as it stands then). { Ok, Line, Count, Credits (spent), Kwh (spent), Shard?, Items? (the pieces' new ids) }, or a
-- refusal that changed nothing, with Need on Poor and Short.
function Shop.Buy(data: Profile.Data, shelf: Shelf, args: any, now: number): { [string]: any }
	if type(args) ~= "table" then
		return { Ok = false, Error = Shop.Unknown }
	end
	local name, count, stock = args.Line, args.Count, args.Stock
	if type(stock) ~= "number" or stock ~= shelf.Stock then
		return { Ok = false, Error = Shop.Gone }
	end
	local held = if type(name) == "string" then shelf.Lines[name] else nil
	local valid = type(count) == "number" and count == math.floor(count) and count >= 1 and count <= (if held then held.Limit else 0)
	if held == nil or not valid then
		return { Ok = false, Error = Shop.Unknown }
	end
	local bought = Shop.Bought(data, shelf.Stock, held.Name)
	if bought + count > held.Limit then
		return { Ok = false, Error = Shop.Limit }
	end
	local cost = held.Price * count
	if held.Currency == "Kwh" then
		Breaker.Advance(data, now) -- the battery as it stands now
		if data.Base.Charge < cost then
			return { Ok = false, Error = Shop.Short, Need = math.ceil(cost - data.Base.Charge) }
		end
	elseif data.Currency.Credits < cost then
		return { Ok = false, Error = Shop.Poor, Need = cost - data.Currency.Credits }
	end
	local units = held.Each * count
	local kept: { string } = {}
	if held.Item then
		local items = 0
		for _ in data.Items do
			items += 1
		end
		if items + count > ChestsConfig.Bag then
			return { Ok = false, Error = Shop.BagFull }
		end
		for _ = 1, count do
			local rolled = Profile.DeepCopy(held.Item) :: Chests.Rolled
			IndexBook.Saw(data, rolled.Def, rolled.Rarity, rolled.Design) -- found for the Index (TR76)
			local id = Profile.NewId(data)
			data.Items[id] = {
				Id = id,
				Def = rolled.Def,
				Tier = rolled.Tier,
				Rarity = rolled.Rarity,
				Design = rolled.Design,
				Lines = rolled.Lines,
				Sockets = rolled.Sockets,
				Reinforce = 0,
				Jewels = {},
			}
			table.insert(kept, id)
		end
		Chests.Firsts(data, kept) -- a bought item's rarity is seen too, so a chest's later one is no first (TR57)
	elseif held.Shard then
		data.Bag.Shards[held.Shard] = (data.Bag.Shards[held.Shard] or 0) + units
	elseif held.Grade then
		data.Bag.Stones[held.Grade] = (data.Bag.Stones[held.Grade] or 0) + units
	elseif held.Token then
		data.Bag.Tokens[held.Token] = (data.Bag.Tokens[held.Token] or 0) + units
	elseif held.Chest then
		Chests.Grant(data, held.Chest, units)
	elseif held.Emblem then
		data.Bag.Emblems[held.Emblem] = (data.Bag.Emblems[held.Emblem] or 0) + units
	elseif held.Jewel then
		data.Bag.Jewels[held.Jewel] = (data.Bag.Jewels[held.Jewel] or 0) + units
	end
	if data.Shop.Stock ~= shelf.Stock then
		data.Shop = { Stock = shelf.Stock, Bought = {} }
	end
	data.Shop.Bought[held.Name] = bought + count
	if held.Currency == "Kwh" then
		data.Base.Charge -= cost
	else
		data.Currency.Credits -= cost
	end
	return {
		Ok = true,
		Line = held.Name,
		Count = count,
		Credits = if held.Currency == "Credits" then cost else 0,
		Kwh = if held.Currency == "Kwh" then cost else 0,
		Shard = held.Shard,
		Items = if held.Item then kept else nil,
	}
end

return Shop
