--!strict
-- Rules.Welcome (shared, pure): the welcome week (TR59; docs/design.md, "The welcome week and codes"; Config.Welcome).
-- One gift for each UTC day the account plays, in order: a missed day only waits, so no gift is lost and there's no
-- streak; the week ends with the seventh. Each claim is one transaction, and a second on the same day changes nothing.
-- No Roblox API: it runs with Studio closed.
--   Welcome.Shown(data)          the row shows: the first session's script is over (Config.Welcome.ShowsAfter)
--   Welcome.Row(data, day)       the seven tiles on UTC day `day`: "Taken", "Today" (lit, one tap) or "Later"
--   Welcome.Claim(data, day)     today's gift into the bag: { Ok, Day, Gift } or refused Early, Done or Today
--   Welcome.Give(data, gift)     a gift into the bag: a chest by Chests.Grant, or shards
--   Welcome.Said(gift)           a gift's words: "Forge Crate", "2 Standard shards", "Lyric's Named shard"

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Welcome)
local Profile = require(Shared.Data.Profile)
local ChestRows = require(Shared.Definitions.Chests)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Chests = require(Shared.Rules.Chests)

local Welcome = {}

Welcome.Early = "Early" -- the row isn't shown yet: the first session's script comes first
Welcome.Done = "Done" -- the seven are taken
Welcome.Today = "Today" -- today's is taken; the next waits for the next day played

function Welcome.Shown(data: Profile.Data): boolean
	return data.Funnel[Config.ShowsAfter] == true
end

local function taken(data: Profile.Data): number
	local held = data.Welcome
	return if held then held.Taken else 0
end

-- The gift takeable on `day`, its number in the week, or nil.
local function due(data: Profile.Data, day: number): number?
	local held = data.Welcome
	if taken(data) >= #Config.Week or (held ~= nil and held.Last == day) then
		return nil
	end
	return taken(data) + 1
end

function Welcome.Row(data: Profile.Data, day: number): { string }
	local done = taken(data)
	local now = if Welcome.Shown(data) then due(data, day) else nil
	local out: { string } = {}
	for index = 1, #Config.Week do
		table.insert(out, if index <= done then "Taken" elseif index == now then "Today" else "Later")
	end
	return out
end

function Welcome.Give(data: Profile.Data, gift: Config.Gift)
	if gift.Chest then
		Chests.Grant(data, gift.Chest, gift.Count)
	elseif gift.Shard then
		data.Bag.Shards[gift.Shard] = (data.Bag.Shards[gift.Shard] or 0) + gift.Count
	end
end

function Welcome.Claim(data: Profile.Data, day: number): { [string]: any }
	if not Welcome.Shown(data) then
		return { Ok = false, Error = Welcome.Early }
	end
	if taken(data) >= #Config.Week then
		return { Ok = false, Error = Welcome.Done }
	end
	local index = due(data, day)
	if index == nil then
		return { Ok = false, Error = Welcome.Today }
	end
	local gift = Config.Week[index]
	Welcome.Give(data, gift)
	data.Welcome = { Taken = index, Last = day }
	return { Ok = true, Day = index, Gift = table.clone(gift) }
end

function Welcome.Said(gift: Config.Gift): string
	if gift.Chest then
		local row = ChestRows.ById[gift.Chest]
		local name = if row then row.Name else gift.Chest
		return if gift.Count > 1 then `{name} ×{gift.Count}` else name
	end
	local row = if gift.Shard then Shards.ById[gift.Shard] else nil
	if row == nil then
		return ""
	end
	local holds = Voidkin.ById[row.Holds]
	local name = if holds then `{holds.Name}'s {row.Grade} shard` else `{row.Grade} shard`
	return if gift.Count > 1 then `{gift.Count} {name}s` else name
end

return Welcome
