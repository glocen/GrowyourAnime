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
local ChestsConfig = require(Shared.Config.Chests)
local ChestRows = require(Shared.Definitions.Chests)
local Goals = require(Shared.Rules.Goals)

local Progress = {}

Progress.Unknown = "Unknown" -- no ground by that id
Progress.Rest = "Resting" -- the keeper rests from this player's last win: a win now can only be that win again

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

-- Whether a keeper is beaten in any ground: the end of the first session, the tutorial (TR65: the guide's arrows stop
-- there; the same line as Carry.HomeFor's short wait, TR24's fix 5).
function Progress.Beaten(grounds: { [string]: Profile.GroundProgress }?): boolean
	for _, record in grounds or {} do
		if Progress.Wins(record) > 0 then
			return true
		end
	end
	return false
end

-- The keeper of ground `id` fell to this player's lead at `now` (os.time), in a run on `difficulty` (Normal when nil or
-- unknown): one more win there on that difficulty, the next ground opened if it wasn't, this player's keeper resting
-- Cooldown.Wait("Keeper") from now, and its chest, the better on that difficulty's first win (Rules.Chests.KeeperChest,
-- TR27; TR48). With `loot`'s rolls, its Emblem Case too (Config.Drops.EmblemChance.Keeper, EmblemFirst on that first
-- win), standing for the win's chest (TR56): a keeper's comes with its win, never its fall's drop. A Hard win also gives
-- a Jewel Pouch and, at its chance, a Forge Crate (Config.Chests.Pouch and Crate, HardKeeper). { Ok, Ground, Difficulty,
-- Wins, Opened, Back, Chest, Case, Pouch, Crate } where Wins counts that difficulty's, Opened is the ground the win
-- opened or "", Back when the keeper is back (os.time), and Chest, Case, Pouch and Crate each a chest's id or "".
function Progress.KeeperWon(data: Profile.Data, id: any, now: number, difficulty: string?, loot: Drops.Loot?): { [string]: any }
	local row = if type(id) == "string" then Grounds.ById[id] else nil
	if row == nil then
		return { Ok = false, Error = Progress.Unknown }
	end
	if Progress.Resting(data, row.Id, now) > 0 then
		-- No try begins while it rests (KeeperService.Try), so this is a repeat of the win that rested it: nothing twice
		-- (section 9), whether the server's flag or an op id caught it first or not.
		return { Ok = false, Error = Progress.Rest }
	end
	local level = if difficulty == "Hard" then "Hard" else "Normal"
	local record = opened(data, row.Id, now)
	local wins = Progress.Wins(record, level) + 1
	record.KeeperWins[level] = wins
	Goals.Note(data, "Keeper") -- today's "bring down the Lamplighter", on either difficulty (TR54)
	record.Back = now + Cooldown.Wait("Keeper")
	local chest = Chests.KeeperChest(row.Id, wins, level)
	if chest then
		Chests.Grant(data, chest, 1)
	end
	local case, pouch, crate = "", "", ""
	if loot then
		local first = if wins == 1 then DropsConfig.EmblemFirst[level] else nil
		case = Chests.Case(chest, loot.Emblem, first or DropsConfig.EmblemChance.Keeper or 0) or ""
		if case ~= "" then
			Chests.Grant(data, case, 1)
		end
		if level == "Hard" then
			if (loot.Pouch or 0) < ChestsConfig.Pouch.HardKeeper then
				pouch = ChestRows.PouchId
				Chests.Grant(data, pouch, 1)
			end
			if (loot.Crate or 0) < ChestsConfig.Crate.HardKeeper then
				crate = ChestRows.CrateId
				Chests.Grant(data, crate, 1)
			end
		end
	end
	local nextRow = Grounds.List[row.Order + 1]
	local newly = ""
	if nextRow and data.Progress.Grounds[nextRow.Id] == nil then
		opened(data, nextRow.Id, now)
		newly = nextRow.Id
	end
	return { Ok = true, Ground = row.Id, Difficulty = level, Wins = wins, Opened = newly, Back = record.Back, Chest = chest or "", Case = case, Pouch = pouch, Crate = crate }
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
