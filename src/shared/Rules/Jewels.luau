--!strict
-- Jewels (shared, pure): jewels in an item's five slots, one a colour (TR47 part B; docs/design.md, "Jewels";
-- Config.Jewels). A jewel is a key, its colour and level, "Colour:level", never an owned row, so identical ones stack in
-- the bag (Bag.Jewels); in a slot it's the item's Jewels[colour] = level. Putting one in or taking it out is free, on
-- Equipment's Jewels page, and the slots move with the item's level on equip (Rules.Regalia.Transfer).
--   Jewels.Key(colour, level)       a jewel's key
--   Jewels.Parse(key)               its colour and level, or nil when the key names no jewel that can exist
--   Jewels.Points(colour, level)    the attribute it gives and how many points, or nil
--   Jewels.Set(data, args)          { Item, Jewel }: one from the bag into its colour's slot; one already there goes back
--   Jewels.Unset(data, args)        { Item, Colour }: the slot's jewel back to the bag
--   Jewels.Merge(data, args)        { Jewel, Count? }: Count (1 by default) times, three of the key into one of the next
--                                   level, in one step; never past the top level, never a fraction of a jewel
-- The server runs each in one transaction with its op id (Services.Main.RegaliaService).
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Jewels)
local Profile = require(Shared.Data.Profile)

local Jewels = {}

-- The refusals, which the screen says.
Jewels.Unknown = "Unknown" -- no such item, colour or jewel, or the request isn't one
Jewels.NoneLeft = "NoneLeft" -- the bag holds none of that jewel
Jewels.Empty = "Empty" -- nothing in that slot to take out
Jewels.Top = "Top" -- a jewel at the top level makes nothing higher
Jewels.TooFew = "TooFew" -- fewer than three of it for each one asked

export type Parsed = { Colour: string, Level: number }

function Jewels.Key(colour: string, level: number): string
	return `{colour}:{level}`
end

local function known(colour: any, level: any): boolean
	return type(colour) == "string" and Config.Attribute[colour] ~= nil and type(level) == "number"
		and level == math.floor(level) and level >= 1 and level <= #Config.Points
end

function Jewels.Parse(key: any): Parsed?
	if type(key) ~= "string" then
		return nil
	end
	local colour, digits = string.match(key, "^(%a+):(%d+)$")
	local level = if digits then tonumber(digits) else nil
	if not known(colour, level) then
		return nil
	end
	return { Colour = colour :: string, Level = level :: number }
end

function Jewels.Points(colour: string, level: number): (string?, number)
	if not known(colour, level) then
		return nil, 0
	end
	return Config.Attribute[colour], Config.Points[level]
end

local function bagAdd(data: Profile.Data, key: string, count: number)
	local left = (data.Bag.Jewels[key] or 0) + count
	data.Bag.Jewels[key] = if left > 0 then left else nil
end

local function itemOf(data: Profile.Data, args: any): Profile.OwnedItem?
	local id = if type(args) == "table" then args.Item else nil
	return if type(id) == "string" then data.Items[id] else nil
end

function Jewels.Set(data: Profile.Data, args: any): { [string]: any }
	local item = itemOf(data, args)
	local key = if type(args) == "table" then args.Jewel else nil
	local parsed = Jewels.Parse(key)
	if item == nil or parsed == nil then
		return { Ok = false, Error = Jewels.Unknown }
	end
	if (data.Bag.Jewels[key] or 0) < 1 then
		return { Ok = false, Error = Jewels.NoneLeft }
	end
	local held = item.Jewels[parsed.Colour]
	bagAdd(data, key, -1)
	local back = ""
	if known(parsed.Colour, held) then
		back = Jewels.Key(parsed.Colour, held :: number)
		bagAdd(data, back, 1)
	end
	item.Jewels[parsed.Colour] = parsed.Level
	return { Ok = true, Item = item.Id, Colour = parsed.Colour, Level = parsed.Level, Back = back }
end

function Jewels.Unset(data: Profile.Data, args: any): { [string]: any }
	local item = itemOf(data, args)
	local colour = if type(args) == "table" then args.Colour else nil
	if item == nil or type(colour) ~= "string" or Config.Attribute[colour] == nil then
		return { Ok = false, Error = Jewels.Unknown }
	end
	local held = item.Jewels[colour]
	if held == nil then
		return { Ok = false, Error = Jewels.Empty }
	end
	item.Jewels[colour] = nil
	-- A level the save holds that no jewel has (a hand-edited save) leaves the slot empty and gives nothing back.
	local back = if known(colour, held) then Jewels.Key(colour, held) else ""
	if back ~= "" then
		bagAdd(data, back, 1)
	end
	return { Ok = true, Item = item.Id, Colour = colour, Back = back }
end

function Jewels.Merge(data: Profile.Data, args: any): { [string]: any }
	local given = if type(args) == "table" then args else {}
	local parsed = Jewels.Parse(given.Jewel)
	local count = if given.Count == nil then 1 else given.Count
	if parsed == nil or type(count) ~= "number" or count ~= math.floor(count) or count < 1 or count == math.huge then
		return { Ok = false, Error = Jewels.Unknown }
	end
	if parsed.Level >= #Config.Points then
		return { Ok = false, Error = Jewels.Top }
	end
	local key = given.Jewel :: string
	local need = Config.Merge * count
	if (data.Bag.Jewels[key] or 0) < need then
		return { Ok = false, Error = Jewels.TooFew }
	end
	local made = Jewels.Key(parsed.Colour, parsed.Level + 1)
	bagAdd(data, key, -need)
	bagAdd(data, made, count)
	return { Ok = true, Jewel = key, Spent = need, Made = made, Count = count }
end

-- What a client may ask, by name, through the Act remote: all free, frozen in a fight like every gear change.
Jewels.Actions = {
	JewelSet = Jewels.Set,
	JewelUnset = Jewels.Unset,
	JewelMerge = Jewels.Merge,
} :: { [string]: (Profile.Data, any) -> { [string]: any } }

return Jewels
