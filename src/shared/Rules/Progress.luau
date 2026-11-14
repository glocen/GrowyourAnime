--!strict
-- Progress (pure rules): what a keeper's fall changes in a player's save (docs/design.md, "The Festival of Battles":
-- beating the keeper opens the next ground for good), and the keeper's rest after it: each player's own, kept in their
-- save (TR10, Rules.Cooldown). The server decides the fall; this only writes it. No Roblox API.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local Grounds = require(Shared.Definitions.Grounds)
local Cooldown = require(Shared.Rules.Cooldown)

local Progress = {}

Progress.Unknown = "Unknown" -- no ground by that id

-- A ground's record, made when it first counts as opened.
local function opened(data: Profile.Data, id: string, now: number): Profile.GroundProgress
	local record = data.Progress.Grounds[id]
	if record == nil then
		record = { Opened = now, KeeperWins = 0, Back = nil } :: Profile.GroundProgress
		data.Progress.Grounds[id] = record
	end
	return record
end

-- The keeper of ground `id` fell to this player's lead at `now` (os.time): one more win there, the next ground opened if
-- it wasn't, and this player's keeper resting Cooldown.Wait("Keeper") from now. { Ok, Ground, Wins, Opened, Back } where
-- Opened is the ground the win opened, or "" when it opened none, and Back when the keeper is back (os.time).
function Progress.KeeperWon(data: Profile.Data, id: any, now: number): { [string]: any }
	local row = if type(id) == "string" then Grounds.ById[id] else nil
	if row == nil then
		return { Ok = false, Error = Progress.Unknown }
	end
	local record = opened(data, row.Id, now)
	record.KeeperWins += 1
	record.Back = now + Cooldown.Wait("Keeper")
	local nextRow = Grounds.List[row.Order + 1]
	local newly = ""
	if nextRow and data.Progress.Grounds[nextRow.Id] == nil then
		opened(data, nextRow.Id, now)
		newly = nextRow.Id
	end
	return { Ok = true, Ground = row.Id, Wins = record.KeeperWins, Opened = newly, Back = record.Back }
end

-- Seconds before this player's keeper of ground `id` is back at `now` (os.time, or the server's time on a client), 0 when
-- it's up: only a win rests it, so a lost try may try again at once.
function Progress.Resting(data: Profile.Data, id: string, now: number): number
	local record = data.Progress.Grounds[id]
	return if record then Cooldown.Left(record.Back, now, "Keeper") else 0
end

-- Whether ground `id` is open to this player: the first always is.
function Progress.IsOpen(data: Profile.Data, id: string): boolean
	return id == Grounds.First or data.Progress.Grounds[id] ~= nil
end

return Progress
