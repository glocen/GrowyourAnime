--!strict
-- The Void Shop (shared, pure; AR38; docs/design.md, "The Void Shop"; docs/engineering-plan.md, the profile's Shop).
--   The clock   a stock every Config.Shop.Period seconds of world time: its number is the Unix time over the period,
--               floored, so every server is on the same one with no messaging.
--   The shelf   a seeded draw on the stock's number and the server's salt, which never reaches a client, so nobody sees
--               a stock before it lands: the stock's Standard shard, and on a featured stock one gear piece, rolled as
--               the featured ground's chests roll on the Shop's own rarity weights (Rules.Chests.Roll).
--   A buy       one transaction (DataService.Change, with its op id, so a repeat answers its first answer): the Credits
--               leave and the shards or the piece land in the same step, and a refusal changes nothing. Each line has its
--               own count a player, saved against the stock's number (Profile's Shop), so one player's buy never empties
--               another's and a server hop never refills a line. A buy names the stock it was pressed on: one pressed as
--               the stock turned is refused, never charged for a shelf the player didn't see.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local ShopConfig = require(Shared.Config.Shop)
local ChestsConfig = require(Shared.Config.Chests)
local ChestRows = require(Shared.Definitions.Chests)
local Gear = require(Shared.Definitions.Gear)
local Grounds = require(Shared.Definitions.Grounds)
local Growth = require(Shared.Rules.Growth)
local Chests = require(Shared.Rules.Chests)

local Shop = {}

Shop.Unknown = "Unknown" -- no such line on this stock, or a count that isn't one
Shop.Gone = "Gone" -- the stock turned since the press: nothing bought
Shop.Limit = "Limit" -- that line's count for this stock is bought
Shop.Poor = "Poor" -- not enough Credits
Shop.BagFull = "BagFull" -- the piece would pass the bag's cap

export type Line = {
	Name: string, -- "Shard" or "Featured"
	Price: number, -- Credits each
	Limit: number, -- a player each stock
	Shard: string?, -- the shard's definition, on the shard's line
	Item: Chests.Rolled?, -- the piece, on the featured line
}

export type Shelf = {
	Stock: number,
	Ends: number, -- the Unix second the next stock lands
	Featured: boolean,
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

-- The `n`th draw of stock `stock` under `salt`, in [0, 1): the same three, the same draw.
function Shop.Draw(salt: number, stock: number, n: number): number
	local h = mix(bit32.bxor(salt % TWO32, mix(stock % TWO32)))
	return mix(bit32.bxor(h, n % TWO32)) / TWO32
end

local function index(count: number, u: number): number
	return math.clamp(math.floor(u * count) + 1, 1, count)
end

local function priced(perG: number, ground: string): number
	local row = Grounds.ById[ground]
	return math.floor(perG * Growth.G(if row then row.LevelTo else 1) + 0.5)
end

-- The featured piece's roll stands as a chest of its ground (its tier and worth), on the Shop's weights.
local FEATURED_ROW: ChestRows.Row = { Id = "shop_featured", Ground = ShopConfig.Featured.Ground, Tier = 0, Name = "", Image = "", Difficulty = "Normal", Stage = 0 }

-- Every weapon class alike: the shelf is everyone's, so it leans to nobody's lead.
local CLASSES: { [string]: number } = {}
for class in Gear.Weapons do
	CLASSES[class] = 1
end

-- The shelf of stock `stock` under `salt`. Draw 1 picks the shard, draw 2 says whether a piece is featured, and the
-- piece's roll reads draws from 101 on, so a change to the piece's roll never moves the shard or the chance.
function Shop.Shelf(stock: number, salt: number): Shelf
	local pool = ShopConfig.Shard.Pool
	local lines: { [string]: Line } = {
		Shard = {
			Name = "Shard",
			Price = priced(ShopConfig.Shard.PricePerG, ShopConfig.Featured.Ground),
			Limit = ShopConfig.Shard.Limit,
			Shard = pool[index(#pool, Shop.Draw(salt, stock, 1))],
		},
	}
	local featured = Shop.Draw(salt, stock, 2) < ShopConfig.Featured.Chance
	if featured then
		local n = 100
		local item = Chests.Roll(FEATURED_ROW, CLASSES, function(): number
			n += 1
			return Shop.Draw(salt, stock, n)
		end, ShopConfig.Featured.Ladder)
		lines.Featured = {
			Name = "Featured",
			Price = priced(ShopConfig.Featured.PricePerG[item.Rarity] or 0, ShopConfig.Featured.Ground),
			Limit = ShopConfig.Featured.Limit,
			Item = item,
		}
	end
	return { Stock = stock, Ends = Shop.Ends(stock), Featured = featured, Lines = lines }
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
	local line = shelf.Lines[name]
	if line == nil then
		return 0
	end
	return math.max(0, line.Limit - Shop.Bought(data, shelf.Stock, name))
end

-- Each featured rarity's chance on a featured stock, as its roll draws it.
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

-- Buys `args.Count` of line `args.Line` from `shelf`, pressed on stock `args.Stock`. { Ok, Line, Count, Credits (spent),
-- Shard?, Items? (the piece's new id) }, or a refusal that changed nothing.
function Shop.Buy(data: Profile.Data, shelf: Shelf, args: any): { [string]: any }
	if type(args) ~= "table" then
		return { Ok = false, Error = Shop.Unknown }
	end
	local name, count, stock = args.Line, args.Count, args.Stock
	if type(stock) ~= "number" or stock ~= shelf.Stock then
		return { Ok = false, Error = Shop.Gone }
	end
	local line = if type(name) == "string" then shelf.Lines[name] else nil
	local valid = type(count) == "number" and count == math.floor(count) and count >= 1 and count <= (if line then line.Limit else 0)
	if line == nil or not valid then
		return { Ok = false, Error = Shop.Unknown }
	end
	local bought = Shop.Bought(data, shelf.Stock, line.Name)
	if bought + count > line.Limit then
		return { Ok = false, Error = Shop.Limit }
	end
	local cost = line.Price * count
	if data.Currency.Credits < cost then
		return { Ok = false, Error = Shop.Poor }
	end
	local kept: { string } = {}
	if line.Item then
		local items = 0
		for _ in data.Items do
			items += 1
		end
		if items + count > ChestsConfig.Bag then
			return { Ok = false, Error = Shop.BagFull }
		end
		for _ = 1, count do
			local piece = Profile.DeepCopy(line.Item) :: Chests.Rolled
			local id = Profile.NewId(data)
			data.Items[id] = {
				Id = id,
				Def = piece.Def,
				Tier = piece.Tier,
				Rarity = piece.Rarity,
				Design = piece.Design,
				Lines = piece.Lines,
				Sockets = piece.Sockets,
				Reinforce = 0,
				Jewels = {},
			}
			table.insert(kept, id)
		end
	elseif line.Shard then
		data.Bag.Shards[line.Shard] = (data.Bag.Shards[line.Shard] or 0) + count
	end
	if data.Shop.Stock ~= shelf.Stock then
		data.Shop = { Stock = shelf.Stock, Bought = {} }
	end
	data.Shop.Bought[line.Name] = bought + count
	data.Currency.Credits -= cost
	return { Ok = true, Line = line.Name, Count = count, Credits = cost, Shard = line.Shard, Items = if line.Item then kept else nil }
end

return Shop
