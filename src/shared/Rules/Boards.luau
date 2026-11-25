--!strict
-- Rules.Boards (shared, pure): the boards on the Strip (TR58; docs/design.md, "Being seen"; Config.Boards). What an
-- account posts to each all-time board, the store's write that only raises, when a post is due, and a board as one player
-- reads it: its first rows and their own rank. A board holds UserIds and numbers, never a name (names are looked up when
-- shown). No Roblox API: it runs with Studio closed.
--   Boards.Value(data, board)                    the account's number for "Lead" or "Stars"
--   Boards.Raise(old, value)                      the store's transform: the value, or nil (no write) when old is as high
--   Boards.Due(last, value, now, leaving)         a post is due: higher than the last posted, and Post seconds on or leaving
--   Boards.Entries(items)                         a page as the store gives it, as entries; keys that aren't a UserId dropped
--   Boards.Rank(top, me, mine, shown, page)       the first `shown` rows, and the reader's own row
--   Boards.Key(userId)                            a store's key: the UserId alone

local Shared = script.Parent.Parent
local Config = require(Shared.Config.Boards)
local Profile = require(Shared.Data.Profile)
local Stats = require(Shared.Rules.Stats)

local Boards = {}

export type Entry = { Id: number, Score: number } -- one row as stored: a UserId and its number
export type Row = { Rank: number?, Id: number, Score: number } -- as shown; a rank nil past a full page
export type Post = { Value: number, At: number } -- the last number posted for a player to a board, and when

-- The account's number for `board`: its lead's Combat Power as it shows ("Lead"), or every star its Voidkin hold
-- ("Stars"); 0 without one.
function Boards.Value(data: Profile.Data, board: string): number
	if board == "Lead" then
		local owned = data.Voidkin[data.Roles.Lead]
		if owned == nil then
			return 0
		end
		return math.max(0, Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data))))
	elseif board == "Stars" then
		local total = 0
		for _, owned in data.Voidkin do
			total += math.max(0, math.floor(owned.Stars))
		end
		return total
	end
	return 0
end

-- The store's write: `value` when it's higher than what's stored, else nil, which cancels the write.
function Boards.Raise(old: any, value: number): number?
	if type(old) == "number" and old >= value then
		return nil
	end
	return value
end

-- A post is due when `value` is higher than the last one posted from here, and Post seconds have passed since it, or the
-- player is leaving. A number that only fell is never posted: the board keeps the best.
function Boards.Due(last: Post?, value: number, now: number, leaving: boolean): boolean
	if value <= 0 or (last ~= nil and value <= last.Value) then
		return false
	end
	return last == nil or leaving or now - last.At >= Config.Post
end

-- The page as GetSortedAsync gives it ({ key, value }), as entries; a key that isn't a whole UserId, or a value that
-- isn't a number, is dropped.
function Boards.Entries(items: { any }): { Entry }
	local out: { Entry } = {}
	for _, item in items do
		local id = if type(item) == "table" then tonumber(item.key) else nil
		if id and id > 0 and id == math.floor(id) and type(item.value) == "number" then
			table.insert(out, { Id = id, Score = item.value })
		end
	end
	return out
end

-- The board as player `me` reads it: `top`, the stored page best first (`page` long when full), with their own `mine`
-- (their save's, which may be newer than the page) set in its place. Its first `shown` rows, and their own row: nil
-- without a number, its rank nil when it falls under a full page. Equal numbers go by UserId.
function Boards.Rank(top: { Entry }, me: number, mine: number?, shown: number, page: number): ({ Row }, Row?)
	local list: { Entry } = {}
	for _, entry in top do
		if entry.Id ~= me then
			table.insert(list, entry)
		end
	end
	if mine and mine > 0 then
		table.insert(list, { Id = me, Score = mine })
	end
	table.sort(list, function(a: Entry, b: Entry): boolean
		if a.Score ~= b.Score then
			return a.Score > b.Score
		end
		return a.Id < b.Id
	end)
	local rows: { Row } = {}
	local own: Row? = nil
	for index, entry in list do
		if index > page then
			break
		end
		local row: Row = { Rank = index, Id = entry.Id, Score = entry.Score }
		if index <= shown then
			table.insert(rows, row)
		end
		if entry.Id == me then
			own = row
		end
	end
	if mine and mine > 0 and own == nil then
		local under: Row = { Rank = nil, Id = me, Score = mine } -- only under a full page: past it isn't read
		own = under
	end
	return rows, own
end

function Boards.Key(userId: number): string
	return tostring(userId)
end

return Boards
