--!strict
-- Progress (pure rules): what a keeper's fall changes in a player's save (docs/design.md, "The Festival of Battles":
-- beating the keeper opens the next ground for good). The server decides the fall; this only writes it. No Roblox API.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local Grounds = require(Shared.Definitions.Grounds)

local Progress = {}

Progress.Unknown = "Unknown" -- no ground by that id

-- A ground's record, made when it first counts as opened.
local function opened(data: Profile.Data, id: string, now: number): Profile.GroundProgress
	local record = data.Progress.Grounds[id]
	if record == nil then
		record = { Opened = now, KeeperWins = 0 }
		data.Progress.Grounds[id] = record
	end
	return record
end

-- The keeper of ground `id` fell to this player's lead at `now` (os.time): one more win there, and the next ground opened
-- if it wasn't. { Ok, Ground, Wins, Opened } where Opened is the ground the win opened, or "" when it opened none.
function Progress.KeeperWon(data: Profile.Data, id: any, now: number): { [string]: any }
	local row = if type(id) == "string" then Grounds.ById[id] else nil
	if row == nil then
		return { Ok = false, Error = Progress.Unknown }
	end
	local record = opened(data, row.Id, now)
	record.KeeperWins += 1
	local nextRow = Grounds.List[row.Order + 1]
	local newly = ""
	if nextRow and data.Progress.Grounds[nextRow.Id] == nil then
		opened(data, nextRow.Id, now)
		newly = nextRow.Id
	end
	return { Ok = true, Ground = row.Id, Wins = record.KeeperWins, Opened = newly }
end

-- Whether ground `id` is open to this player: the first always is.
function Progress.IsOpen(data: Profile.Data, id: string): boolean
	return id == Grounds.First or data.Progress.Grounds[id] ~= nil
end

return Progress
