--!strict
-- TowerBoardService (server): the Tower's week's board (TR46; Rules.Tower's Score, Climb and Board; Config.Tower.Board).
-- An account's best climb of a week lives in its save (Progress.Tower.Week, raised by Rules.Tower.End). It's posted to
-- that week's own OrderedDataStore under its UserId alone, never a name: a name is looked up when the board is shown, so
-- one Roblox resets shows its new one (the content check, 2026-11-19). A post only ever raises (UpdateAsync), so a repeat
-- or a late one is harmless, and one that fails is tried again at the account's next change or join. The page of the
-- best is read at most once per Fresh seconds on a server, shared by every reader; each reader's own row is their save's,
-- set in its place by Rules.Tower.Board, so a climb shows at once on its own card.
--   Net "TowerBoard" () -> { Ok, Rows = { { Rank, Name, Floor, Mine } }, Mine = { Rank?, Floor }? }
-- Studio's playtests use their own stores, as the saves do (DataService's "Test").

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local TowerConfig = require(Shared.Config.Tower)
local Profile = require(Shared.Data.Profile)
local Tower = require(Shared.Rules.Tower)
local Net = require(Shared.Net)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local TowerBoardService = {
	Priority = 51, -- after the Tower's runs
}

local PREFIX = if RunService:IsStudio() then "Test" else "Live" -- as DataService's saves: a playtest never touches the live board
local NAMES_KEPT = 600 -- seconds a looked-up name is kept
local RETRY = 10 -- seconds before a failed page read is tried again
local TRIES = 3 -- a post's tries before it waits for the account's next change

type Page = { Week: number, At: number, Entries: { Tower.Entry }, Reading: boolean }

local page: Page? = nil
local names: { [number]: { Name: string, At: number } } = {}
local posted: { [Player]: number } = {} -- the score last posted for each player, by its week's store
local posting: { [Player]: boolean } = {}

local function storeOf(week: number): OrderedDataStore
	return DataStoreService:GetOrderedDataStore(`{PREFIX}TowerWeek{week}`)
end

-- The week's page of the best, read again once it's Fresh seconds old; a read under way is waited for, not repeated.
local function read(week: number): { Tower.Entry }
	local now = os.clock()
	local held = page
	if held and held.Week == week then
		local began = now
		while held.Reading and os.clock() - began < 10 do
			task.wait(0.1)
		end
		if os.clock() - held.At < TowerConfig.Board.Fresh or held.Reading then
			return held.Entries
		end
	end
	local current: Page = if held and held.Week == week then held else { Week = week, At = 0, Entries = {}, Reading = false }
	page = current
	current.Reading = true
	local ok, result = pcall(function(): { Tower.Entry }
		if DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync) <= 0 then
			error("no budget")
		end
		local pages = storeOf(week):GetSortedAsync(false, TowerConfig.Board.Page)
		local out: { Tower.Entry } = {}
		for _, item in pages:GetCurrentPage() do
			local id = tonumber(item.key)
			if id and type(item.value) == "number" then
				table.insert(out, { Id = id, Score = item.value })
			end
		end
		return out
	end)
	current.Reading = false
	if ok then
		current.Entries = result
		current.At = os.clock()
	else
		current.At = os.clock() - TowerConfig.Board.Fresh + RETRY -- the old page kept, tried again soon
		Log.Warn("TowerBoardService", `week {week}'s board wasn't read: {tostring(result)}`)
	end
	return current.Entries
end

-- Display names for `ids`: a player here gives theirs, else one looked up lately, else Roblox's own. "" when unknown.
local function nameAll(ids: { number }): { [number]: string }
	local out: { [number]: string } = {}
	local missing: { number } = {}
	local now = os.clock()
	for _, id in ids do
		local here = Players:GetPlayerByUserId(id)
		local kept = names[id]
		if here then
			out[id] = here.DisplayName
		elseif kept and now - kept.At < NAMES_KEPT then
			out[id] = kept.Name
		elseif id > 0 then
			table.insert(missing, id)
		end
	end
	if #missing > 0 then
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(missing)
		end)
		if ok and type(infos) == "table" then
			for _, info in infos do
				names[info.Id] = { Name = info.DisplayName, At = now }
				out[info.Id] = info.DisplayName
			end
		end
	end
	for _, id in ids do
		out[id] = out[id] or ""
	end
	return out
end

-- Player `player`'s climb posted to its week's store if it's newer than the last one posted from here.
local function post(player: Player)
	if posting[player] then
		return
	end
	local data = DataService.Get(player)
	local climb = if data then data.Progress.Tower.Week else nil
	if climb == nil or climb.Floor <= 0 or posted[player] == climb.Score or climb.Week < Tower.Week(os.time()) - 1 then
		return
	end
	posting[player] = true
	task.spawn(function()
		local key = tostring(player.UserId)
		local score = climb.Score
		local done = false
		for try = 1, TRIES do
			local ok, problem = pcall(function()
				-- Nil cancels the write: a score already as high stays (the engine's types say a number is due).
				local raise: any = function(old: number?): number?
					return if type(old) == "number" and old >= score then nil else score
				end
				storeOf(climb.Week):UpdateAsync(key, raise)
			end)
			if ok then
				done = true
				break
			elseif try == TRIES then
				Log.Warn("TowerBoardService", `{player.Name}'s climb wasn't posted: {tostring(problem)}`)
			else
				task.wait(2 ^ try)
			end
		end
		posting[player] = nil
		if done then
			posted[player] = score
			local held = page
			if held and held.Week == climb.Week then
				-- This server's readers see it at once, before the page is read again.
				local found = false
				for _, entry in held.Entries do
					if entry.Id == player.UserId then
						entry.Score = math.max(entry.Score, score)
						found = true
					end
				end
				if not found then
					table.insert(held.Entries, { Id = player.UserId, Score = score })
				end
			end
			if player.Parent == Players then
				post(player) -- a newer climb written while this one was posting
			end
		end
	end)
end

-- The board as `player` reads it: the first Shown rows with their names, and their own row.
local function board(player: Player): { [string]: any }
	local data = DataService.WaitFor(player)
	if data == nil then
		return { Ok = false, Error = "NoData" }
	end
	local now = os.time()
	local week = Tower.Week(now)
	local climb = Tower.Climb(data, now)
	local rows, own = Tower.Board(read(week), player.UserId, if climb then climb.Score else nil, TowerConfig.Board.Shown)
	local ids = {}
	for _, row in rows do
		table.insert(ids, row.Id)
	end
	local named = nameAll(ids)
	local out = {}
	for _, row in rows do
		table.insert(out, { Rank = row.Rank, Name = named[row.Id], Floor = row.Floor, Mine = row.Id == player.UserId })
	end
	return { Ok = true, Week = week, Rows = out, Mine = if own then { Rank = own.Rank, Floor = own.Floor } else nil }
end

function TowerBoardService.Init()
	DebugService.Register("TowerBoard", function(who: any)
		local player = DebugService.ResolvePlayer(who)
		if player == nil then
			return { Ok = false, Error = "NoPlayer" }
		end
		local answer = board(player)
		answer.Posted = posted[player]
		answer.Age = if page then os.clock() - page.At else nil
		return answer
	end)
	-- The account's climb this week set to `floor` (nil clears it), as a run's end would set it, then posted.
	DebugService.Register("TowerWeek", function(who: any, floor: any)
		local player = DebugService.ResolvePlayer(who)
		if player == nil or (floor ~= nil and type(floor) ~= "number") then
			return { Ok = false, Error = "BadArgs" }
		end
		local now = os.time()
		return DataService.Change(player, "TowerWeek", function(draft: Profile.Data)
			local week = Tower.Week(now)
			draft.Progress.Tower.Week = if floor then { Week = week, Floor = math.floor(floor), Score = Tower.Score(floor, week, now) } else nil
			return { Ok = true }
		end)
	end)
end

function TowerBoardService.Start()
	Net.Server.Handle("TowerBoard", board)
	DataService.Ready:Connect(post)
	DataService.Changed:Connect(post)
	Players.PlayerRemoving:Connect(function(player: Player)
		posted[player] = nil
	end)
end

return TowerBoardService
