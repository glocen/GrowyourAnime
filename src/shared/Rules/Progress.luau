--!strict
-- Progress (pure rules): what a keeper's fall changes in a player's save (docs/design.md, "The Festival of Battles":
-- beating the keeper opens the next ground for good), and the keeper's rest after it: each player's own, kept in their
-- save (TR10, Rules.Cooldown). A keeper's wins count by difficulty (TR48). The server decides the fall; this only
-- writes it. No Roblox API.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local Grounds = require(Shared.Definitions.Grounds)
local Cooldown = require(Shared.Rules.Cooldown)
local Chests = require(Shared.Rules.Chests)
local Drops = require(Shared.Rules.Drops)
local DropsConfig = require(Shared.Config.Drops)

local Progress = {}

Progress.Unknown = "Unknown" -- no ground by that id

-- A ground's record, made when it first counts as opened.
local function opened(data: Profile.Data, id: string, now: number): Profile.GroundProgress
	local record = data.Progress.Grounds[id]
	if record == nil then
		record = { Opened = now, KeeperWins = { Normal = 0, Hard = 0 }, Back = nil } :: Profile.GroundProgress
		data.Progress.Grounds[id] = record
	end
	return record
end

-- A ground's keeper's wins on `difficulty`, or on every difficulty when it's nil (TR48).
function Progress.Wins(record: { KeeperWins: { [string]: number } }?, difficulty: string?): number
	if record == nil then
		return 0
	elseif difficulty then
		return record.KeeperWins[difficulty] or 0
	end
	local all = 0
	for _, wins in record.KeeperWins do
		all += wins
	end
	return all
end

-- The keeper of ground `id` fell to this player's lead at `now` (os.time), in a run on `difficulty` (Normal when nil or
-- unknown): one more win there on that difficulty, the next ground opened if it wasn't, this player's keeper resting
-- Cooldown.Wait("Keeper") from now, and its chest, the better on that difficulty's first win (Rules.Chests.KeeperChest,
-- TR27; TR48). With `loot`'s rolls, its War Emblem too (Config.Drops.EmblemChance.Keeper, EmblemFirst on that first
-- win): a keeper's comes with its win, never its fall's drop. { Ok, Ground, Difficulty, Wins, Opened, Back, Chest,
-- Emblem } where Wins counts that difficulty's, Opened is the ground the win opened or "", Back when the keeper is back
-- (os.time), Chest the chest's id or "", and Emblem its key or "".
function Progress.KeeperWon(data: Profile.Data, id: any, now: number, difficulty: string?, loot: Drops.Loot?): { [string]: any }
	local row = if type(id) == "string" then Grounds.ById[id] else nil
	if row == nil then
		return { Ok = false, Error = Progress.Unknown }
	end
	local level = if difficulty == "Hard" then "Hard" else "Normal"
	local record = opened(data, row.Id, now)
	local wins = Progress.Wins(record, level) + 1
	record.KeeperWins[level] = wins
	record.Back = now + Cooldown.Wait("Keeper")
	local chest = Chests.KeeperChest(row.Id, wins, level)
	if chest then
		Chests.Grant(data, chest, 1)
	end
	local emblem = ""
	if loot then
		local first = if wins == 1 then DropsConfig.EmblemFirst[level] else nil
		emblem = Drops.Emblem("Keeper", row.Id, loot, level, first) or ""
		if emblem ~= "" then
			data.Bag.Emblems[emblem] = (data.Bag.Emblems[emblem] or 0) + 1
		end
	end
	local nextRow = Grounds.List[row.Order + 1]
	local newly = ""
	if nextRow and data.Progress.Grounds[nextRow.Id] == nil then
		opened(data, nextRow.Id, now)
		newly = nextRow.Id
	end
	return { Ok = true, Ground = row.Id, Difficulty = level, Wins = wins, Opened = newly, Back = record.Back, Chest = chest or "", Emblem = emblem }
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
