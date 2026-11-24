--!strict
-- Emblems (shared, pure): War Emblems in an item's sockets (TR47; docs/design.md, "War Emblems"). An emblem is a key, its
-- set and its one stat, "set:stat", never an owned row: its value is fixed by its rarity and stat, with no roll, so
-- identical ones stack in the bag (Bag.Emblems). An item's sockets come with its rarity (Config.Chests.Sockets): one on a
-- Common item up to four from Epic. Putting one in or taking it out is free, on Equipment's War Emblems page.
--   Emblems.Key(set, stat)             an emblem's key
--   Emblems.Parse(key)                 its set's row and its stat, or nil when the key names no emblem that can exist
--   Emblems.Points(key)                the stat it gives and how much (Config.Emblems), or nil
--   Emblems.Socket(data, args)         { Item, Socket, Emblem }: one from the bag into the socket; one already there goes
--                                      back to the bag
--   Emblems.Unsocket(data, args)       { Item, Socket }: the socket's emblem back to the bag
--   Emblems.Held(data, rarity, stat)   how many of that stat and rarity the bag holds, every set together
--   Emblems.Combine(data, args, u)     { Rarity, Stat }: Config.Emblems.Combine.Take of them from the bag into one of the
--                                      next rarity, the same stat, its set drawn by `u` (TR56); Legendary the top
-- The server runs each in one transaction with its op id (Services.Main.RegaliaService), so a repeat pays once.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Emblems)
local Sets = require(Shared.Definitions.Emblems)
local Profile = require(Shared.Data.Profile)

local Emblems = {}

-- The refusals, which the screen says.
Emblems.Unknown = "Unknown" -- no such item, socket or emblem, or the request isn't one
Emblems.NoneLeft = "NoneLeft" -- the bag holds none of that emblem
Emblems.Empty = "Empty" -- nothing in that socket to take out
Emblems.NotEnough = "NotEnough" -- fewer of that stat and rarity in the bag than a combine takes
Emblems.Top = "Top" -- Legendary: nothing above it to combine into

export type Parsed = { Set: Sets.Row, Stat: string }

function Emblems.Key(set: string, stat: string): string
	return `{set}:{stat}`
end

function Emblems.Parse(key: any): Parsed?
	if type(key) ~= "string" then
		return nil
	end
	local set, stat = string.match(key, "^([%w_]+):(%w+)$")
	local row = if set then Sets.ById[set] else nil
	if row == nil or stat == nil then
		return nil
	end
	local high = Config.High[row.Rarity]
	if table.find(Sets.Stats, stat) == nil and not (high and high[stat] and table.find(Sets.HighStats, stat)) then
		return nil
	end
	return { Set = row, Stat = stat }
end

function Emblems.Points(key: string): (string?, number)
	local parsed = Emblems.Parse(key)
	if parsed == nil then
		return nil, 0
	end
	local rarity, stat = parsed.Set.Rarity, parsed.Stat
	local row = Config.Points[stat]
	if row then
		return stat, math.floor(row * (Config.Worth[rarity] or 0) + 0.5)
	end
	return stat, (Config.High[rarity] :: { [string]: number })[stat]
end

local function socketOf(data: Profile.Data, args: any): (Profile.OwnedItem?, number?)
	local given = if type(args) == "table" then args else {}
	local item = if type(given.Item) == "string" then data.Items[given.Item] else nil
	local index = given.Socket
	if item == nil or type(index) ~= "number" or index ~= math.floor(index) or item.Sockets[index] == nil then
		return nil, nil
	end
	return item, index
end

local function bagAdd(data: Profile.Data, key: string, count: number)
	local left = (data.Bag.Emblems[key] or 0) + count
	data.Bag.Emblems[key] = if left > 0 then left else nil
end

function Emblems.Socket(data: Profile.Data, args: any): { [string]: any }
	local item, index = socketOf(data, args)
	local key = if type(args) == "table" then args.Emblem else nil
	if item == nil or index == nil or Emblems.Parse(key) == nil then
		return { Ok = false, Error = Emblems.Unknown }
	end
	if (data.Bag.Emblems[key] or 0) < 1 then
		return { Ok = false, Error = Emblems.NoneLeft }
	end
	local back = item.Sockets[index]
	bagAdd(data, key, -1)
	if back ~= "" then
		bagAdd(data, back, 1)
	end
	item.Sockets[index] = key
	return { Ok = true, Item = item.Id, Socket = index, Emblem = key, Back = back }
end

function Emblems.Unsocket(data: Profile.Data, args: any): { [string]: any }
	local item, index = socketOf(data, args)
	if item == nil or index == nil then
		return { Ok = false, Error = Emblems.Unknown }
	end
	local key = item.Sockets[index]
	if key == "" then
		return { Ok = false, Error = Emblems.Empty }
	end
	item.Sockets[index] = ""
	bagAdd(data, key, 1)
	return { Ok = true, Item = item.Id, Socket = index, Back = key }
end

-- The emblems in the bag of `stat` at `rarity`, every set, as { Key, Count }, the most held first, then by key: the
-- order a combine takes them in, so the sets a player holds most of go first.
type Held = { Key: string, Count: number }
local function held(data: Profile.Data, rarity: string, stat: string): { Held }
	local out: { Held } = {}
	for key, count in data.Bag.Emblems do
		local parsed = Emblems.Parse(key)
		if parsed and count > 0 and parsed.Set.Rarity == rarity and parsed.Stat == stat then
			table.insert(out, { Key = key, Count = count })
		end
	end
	table.sort(out, function(a: Held, b: Held): boolean
		if a.Count ~= b.Count then
			return a.Count > b.Count
		end
		return a.Key < b.Key
	end)
	return out
end

function Emblems.Held(data: Profile.Data, rarity: string, stat: string): number
	local total = 0
	for _, each in held(data, rarity, stat) do
		total += each.Count
	end
	return total
end

-- The rarity one above `rarity`, or nil at the top or for none.
function Emblems.Above(rarity: string): string?
	local at = table.find(Config.Order, rarity)
	return if at then Config.Order[at + 1] else nil
end

function Emblems.Combine(data: Profile.Data, args: any, u: number): { [string]: any }
	local given = if type(args) == "table" then args else {}
	local rarity, stat = given.Rarity, given.Stat
	if type(rarity) ~= "string" or type(stat) ~= "string" or table.find(Config.Order, rarity) == nil then
		return { Ok = false, Error = Emblems.Unknown }
	end
	local above = Emblems.Above(rarity)
	if above == nil then
		return { Ok = false, Error = Emblems.Top }
	end
	local sets = Sets.ByRarity[above] or {}
	local made = if #sets > 0 then Emblems.Key(sets[math.clamp(math.floor(u * #sets) + 1, 1, #sets)].Id, stat) else ""
	if Emblems.Parse(made) == nil then
		return { Ok = false, Error = Emblems.Unknown } -- a stat that rarity can't hold
	end
	local take = Config.Combine.Take
	local from = held(data, rarity, stat)
	if Emblems.Held(data, rarity, stat) < take then
		return { Ok = false, Error = Emblems.NotEnough }
	end
	local took: { [string]: number } = {}
	for _, each in from do
		local n = math.min(each.Count, take)
		if n > 0 then
			bagAdd(data, each.Key, -n)
			took[each.Key] = n
			take -= n
		end
	end
	bagAdd(data, made, 1)
	return { Ok = true, Rarity = above, Stat = stat, Emblem = made, Took = took }
end

-- What a client may ask, by name, through the Act remote: both free, frozen in a fight like every gear change.
Emblems.Actions = {
	Socket = Emblems.Socket,
	Unsocket = Emblems.Unsocket,
} :: { [string]: (Profile.Data, any) -> { [string]: any } }

return Emblems
