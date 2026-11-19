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
-- The server runs each in one transaction with its op id (Services.Main.RegaliaService).
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

-- What a client may ask, by name, through the Act remote: both free, frozen in a fight like every gear change.
Emblems.Actions = {
	Socket = Emblems.Socket,
	Unsocket = Emblems.Unsocket,
} :: { [string]: (Profile.Data, any) -> { [string]: any } }

return Emblems
