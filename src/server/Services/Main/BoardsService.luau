--!strict
-- BoardsService (server): the boards on the Strip (TR58; docs/design.md, "Being seen"; Rules.Boards; Config.Boards).
-- Two all-time boards, the strongest lead and the most stars, are each an OrderedDataStore of whole numbers keyed by
-- UserId alone, never a name: a name is looked up when shown (TowerBoardService.Names), so one Roblox resets shows its
-- new one. A player's numbers are read from their save every Config.Boards.Look seconds after a change, and posted at most
-- once every Post seconds a board and as they leave; a post only ever raises (UpdateAsync), so a repeat or a late one is
-- harmless. Each board's top page is read at most once every Read seconds on a server, shared by every reader. The
-- Tower's week is TowerBoardService's, and the news plate holds BroadcastService's last every-server lines.
--   Net "Boards" () -> { Ok, Boards = { [board] = { Rows = { { Rank, Name, Value, Mine } }, Mine = { Rank?, Value }? } },
--                       News = { Broadcast.News } }; the week's rows carry Floor in place of Value
-- Studio's playtests use their own stores, as the saves do (DataService's "Test").

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local Config = require(Shared.Config.Boards)
local Profile = require(Shared.Data.Profile)
local Boards = require(Shared.Rules.Boards)
local Net = require(Shared.Net)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local TowerBoardService = require(script.Parent.TowerBoardService)
local BroadcastService = require(script.Parent.BroadcastService)

local BoardsService = {
	Priority = 53, -- after the Tower's board and the Broadcast, whose rows and lines it shows
}

local PREFIX = if RunService:IsStudio() then "Test" else "Live" -- as DataService's saves: a playtest never touches a live board
local RETRY = 10 -- seconds before a failed page read is tried again
local TRIES = 3 -- a post's tries; one that fails waits Post seconds, as a post does

type Page = { At: number, Entries: { Boards.Entry }, Reading: boolean, Known: boolean, Warned: boolean }
type Made = { Entries: { Boards.Entry }, Names: { [number]: string } }

local pages: { [string]: Page } = {}
local values: { [Player]: { [string]: number } } = {} -- each player's numbers as last read from their save
local posts: { [Player]: { [string]: Boards.Post } } = {} -- the last number posted for each, and when (os.clock)
local posting: { [Player]: { [string]: boolean } } = {}
local dirty: { [Player]: boolean } = {} -- a change since the last read
local made: { [string]: Made } = {} -- Studio's made-up pages, in place of a store's (the "BoardsPage" command)

local function boardsOf(): { string }
	local out = {}
	for _, board in Config.Order do
		if Config.Stores[board] then
			table.insert(out, board)
		end
	end
	return out
end
local STORED = boardsOf() -- "Lead", "Stars": the boards this service keeps

local function storeOf(board: string): OrderedDataStore
	return DataStoreService:GetOrderedDataStore(`{PREFIX}{Config.Stores[board]}`)
end

-- `board`'s page of the best, read again once it's Read seconds old; a read under way is waited for, not repeated.
local function read(board: string): { Boards.Entry }
	local fake = made[board]
	if fake then
		return fake.Entries
	end
	local held = pages[board]
	if held == nil then
		held = { At = -math.huge, Entries = {}, Reading = false, Known = false, Warned = false }
		pages[board] = held
	end
	local page = held :: Page
	local began = os.clock()
	while page.Reading and os.clock() - began < 10 do
		task.wait(0.1)
	end
	if page.Reading or os.clock() - page.At < Config.Read then
		return page.Entries
	end
	page.Reading = true
	local ok, result = pcall(function(): { Boards.Entry }
		if DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync) <= 0 then
			error("no budget")
		end
		local sorted = storeOf(board):GetSortedAsync(false, Config.Page)
		return Boards.Entries(sorted:GetCurrentPage())
	end)
	page.Reading = false
	if ok then
		page.Entries = result
		page.At = os.clock()
		page.Known = true
		page.Warned = false
	else
		page.At = os.clock() - Config.Read + RETRY -- the old page kept, tried again soon
		if not page.Warned then
			page.Warned = true
			Log.Warn("BoardsService", `the {board} board wasn't read: {tostring(result)}`)
		end
	end
	return page.Entries
end

-- `player`'s number for `board` posted if it's due (Boards.Due): only raised, a few tries, then it waits as a post does.
local function post(player: Player, board: string, leaving: boolean)
	local mine = posts[player]
	local busy = posting[player]
	local value = if values[player] then values[player][board] or 0 else 0
	if mine == nil or busy == nil or busy[board] or not Boards.Due(mine[board], value, os.clock(), leaving) then
		return
	end
	busy[board] = true
	local before = mine[board]
	mine[board] = { Value = if before then before.Value else 0, At = os.clock() } -- the next try waits Post seconds
	task.spawn(function()
		local key = Boards.Key(player.UserId)
		local done = false
		for try = 1, TRIES do
			local ok, problem = pcall(function()
				-- Nil cancels the write: a number already as high stays (the engine's types say a number is due).
				local raise: any = function(old: number?): number?
					return Boards.Raise(old, value)
				end
				storeOf(board):UpdateAsync(key, raise)
			end)
			if ok then
				done = true
				break
			elseif try == TRIES then
				Log.Warn("BoardsService", `{player.Name}'s {board} number wasn't posted: {tostring(problem)}`)
			else
				task.wait(2 ^ try)
			end
		end
		busy[board] = nil
		if done then
			mine[board] = { Value = value, At = os.clock() }
			local page = pages[board]
			if page then -- this server's readers see it at once, before the page is read again
				local found = false
				for _, entry in page.Entries do
					if entry.Id == player.UserId then
						entry.Score = math.max(entry.Score, value)
						found = true
					end
				end
				if not found then
					table.insert(page.Entries, { Id = player.UserId, Score = value })
				end
			end
		end
	end)
end

-- Each player changed since the last look: their numbers read from their save, and posted where due.
local function look()
	for player in dirty do
		dirty[player] = nil
		local data = DataService.Get(player)
		local held = values[player]
		if data and held then
			for _, board in STORED do
				held[board] = Boards.Value(data, board)
			end
		end
	end
	for player in posts do
		for _, board in STORED do
			post(player, board, false)
		end
	end
end

-- The boards as `player` reads them: each one's first Shown rows with their names, their own row, and the news.
local function answer(player: Player): { [string]: any }
	local data = DataService.WaitFor(player)
	if data == nil then
		return { Ok = false, Error = "NoData" }
	end
	local out: { [string]: any } = {}
	local ranked: { [string]: { Rows: { Boards.Row }, Own: Boards.Row? } } = {}
	local ids: { number } = {}
	for _, board in STORED do
		local top = read(board)
		-- Their own number: the best of their save's, what this server posted and the page's, since a board keeps the best.
		local best = Boards.Value(data, board)
		local sent = if posts[player] then posts[player][board] else nil
		best = math.max(best, if sent then sent.Value else 0)
		for _, entry in top do
			if entry.Id == player.UserId then
				best = math.max(best, entry.Score)
			end
		end
		local rows, own = Boards.Rank(top, player.UserId, best, Config.Shown, Config.Page)
		ranked[board] = { Rows = rows, Own = own }
		for _, row in rows do
			table.insert(ids, row.Id)
		end
	end
	local named = TowerBoardService.Names(ids)
	for board, pair in ranked do
		local fake = made[board]
		local rows = {}
		for _, row in pair.Rows do
			local name = if fake and fake.Names[row.Id] then fake.Names[row.Id] else named[row.Id]
			table.insert(rows, { Rank = row.Rank, Name = name or "", Value = row.Score, Mine = row.Id == player.UserId })
		end
		local own = pair.Own
		out[board] = { Rows = rows, Mine = if own then { Rank = own.Rank, Value = own.Score } else nil }
	end
	out.Week = TowerBoardService.Board(player)
	return { Ok = true, Boards = out, News = BroadcastService.News() }
end

local function join(player: Player)
	values[player] = {}
	posts[player] = {}
	posting[player] = {}
	dirty[player] = true
end

function BoardsService.Init()
	if not RunService:IsStudio() then
		return
	end
	-- The boards as `who` reads them, with what this server posted and each page's age.
	DebugService.Register("Boards", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		if player == nil then
			return { Ok = false, Error = "NoPlayer" }
		end
		local got = answer(player)
		local ages = {}
		for board, page in pages do
			ages[board] = os.clock() - page.At
		end
		got.Posted = posts[player]
		got.Ages = ages
		got.Values = values[player]
		return got
	end)
	-- A made-up page for `board` in place of its store's: entries { { Id, Score, Name? } }, best first or not; nil puts
	-- the store's back. Names are the test's own, never stored. This server's readers all see it, so `who` is only the caller.
	DebugService.Register("BoardsPage", function(_who: any, board: any, entries: any): any
		if type(board) ~= "string" or Config.Stores[board] == nil then
			return { Ok = false, Error = "BadArgs" }
		end
		if entries == nil then
			made[board] = nil
			return { Ok = true }
		end
		if type(entries) ~= "table" then
			return { Ok = false, Error = "BadArgs" }
		end
		local fake: Made = { Entries = {}, Names = {} }
		for _, entry in entries do
			if type(entry) == "table" and type(entry.Id) == "number" and type(entry.Score) == "number" then
				table.insert(fake.Entries, { Id = entry.Id, Score = entry.Score })
				if type(entry.Name) == "string" then
					fake.Names[entry.Id] = entry.Name
				end
			end
		end
		made[board] = fake
		return { Ok = true, Count = #fake.Entries }
	end)
end

function BoardsService.Start()
	Net.Server.Handle("Boards", answer)
	DataService.Ready:Connect(function(player: Player, _data: Profile.Data)
		if values[player] == nil then
			join(player)
		end
	end)
	DataService.Changed:Connect(function(player: Player)
		if values[player] then
			dirty[player] = true
		end
	end)
	for _, player in Players:GetPlayers() do
		if DataService.Get(player) and values[player] == nil then
			join(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, board in STORED do
			post(player, board, true) -- the last numbers read, as the save has already let go
		end
		values[player], posts[player], posting[player], dirty[player] = nil, nil, nil, nil
	end)
	task.spawn(function()
		while true do
			task.wait(Config.Look)
			look()
		end
	end)
end

return BoardsService
