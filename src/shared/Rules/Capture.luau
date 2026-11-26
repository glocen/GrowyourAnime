--!strict
-- Rules.Capture (shared, pure): the capture after a reveal (TR60; docs/design.md, "Being seen", the capture). Which
-- reveal's card offers the camera tile, and the launch data a share carries: the sharer's UserId alone, read back when a
-- friend joins through it, to be counted (FunnelService), never rewarded. No Roblox API: it runs with Studio closed.
--   Capture.Offered(kind, rarity)   a reveal's card offers the tile: every Voidkin's, an item's from Epic up
--   Capture.Launch(userId)          the share's launch data
--   Capture.Sharer(data, joiner)    the sharer's UserId from a join's launch data, or nil (not a share, malformed, or
--                                   the joiner's own)

local Shared = game:GetService("ReplicatedStorage").Shared
local Rarity = require(Shared.Definitions.Rarity)

local Capture = {}

local PREFIX = "share:" -- a share's launch data; a friend's invite (TR62) carries its own
local ITEM_FROM = "Epic" -- the lowest item rarity whose reveal offers the tile

function Capture.Offered(kind: string, rarity: string?): boolean
	if kind == "Voidkin" then
		return true
	end
	if kind == "Item" then
		local rank = if rarity then Rarity.Rank[rarity] else nil
		return rank ~= nil and rank >= Rarity.Rank[ITEM_FROM]
	end
	return false
end

function Capture.Launch(userId: number): string
	return `{PREFIX}{math.floor(userId)}`
end

function Capture.Sharer(data: any, joiner: number?): number?
	if type(data) ~= "string" or #data > 64 then
		return nil
	end
	local digits = string.match(data, `^{PREFIX}(%d+)$`)
	local id = if digits and #digits <= 19 then tonumber(digits) else nil
	if id == nil or id <= 0 or id == joiner then
		return nil
	end
	return id
end

return Capture
