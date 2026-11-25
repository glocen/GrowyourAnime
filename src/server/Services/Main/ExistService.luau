--!strict
-- ExistService (server): how many of a Voidkin exist (docs/design.md, "Voidkin", "How many exist"; Rules.Exist; the
-- outside review's item 4). After every committed change, the player's owned Voidkin with no number join a queue; one
-- worker gives each the next number of its kind from this server's block, reserving a new block from the store when it's
-- spent, and writes it on the Voidkin as a change of its own. A grant never waits on it: the Voidkin is the player's the
-- moment its break commits, and its number follows. Only a number the save took is counted, so the count may run behind
-- and never ahead. The store is the save's own split, "Test" in Studio and "Live" on live servers, and every key carries
-- Config.Exist.Epoch. The count shown is ReplicatedStorage's Exist folder, one attribute per kind: the store's last read
-- plus what this server has granted since.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local Profile = require(Shared.Data.Profile)
local Exist = require(Shared.Rules.Exist)
local ExistConfig = require(Shared.Config.Exist)
local Voidkin = require(Shared.Definitions.Voidkin)

local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local ExistService = {
	Priority = 20, -- after DataService
}

local PREFIX = if RunService:IsStudio() then "Test" else "Live"

type Job = { Player: Player, Id: string, Def: string }

local store: any = nil
local folder: Folder = nil :: any
local queue: { Job } = {}
local queued: { [Player]: { [string]: boolean } } = {}
local blocks: { [string]: Exist.Block } = {}
local stored: { [string]: number } = {} -- each kind's count as last read or written
local pending: { [string]: number } = {} -- grants this server made since its last write
local waking: thread? = nil
local warned = false

local function key(def: string): string
	return `{ExistConfig.Epoch}:{def}`
end

-- The count each kind shows: the store's, plus this server's grants not yet written.
local function show(def: string)
	local count = (stored[def] or 0) + (pending[def] or 0)
	folder:SetAttribute(def, if count > 0 then count else nil)
end

local function failed(what: string, why: any)
	if not warned then
		warned = true
		Log.Warn("ExistService", `{what} failed; numbers wait and are tried again:`, why)
	end
end

-- One write for `def`: `take` numbers reserved and this server's grants counted. True when it held.
local function write(def: string, take: number): boolean
	local add = pending[def] or 0
	if take <= 0 and add <= 0 then
		return true
	end
	local block: Exist.Block? = nil
	local ok, result = pcall(function(): any
		return store:UpdateAsync(key(def), function(old: any): any
			local new, got = Exist.Reserve(old, take, add)
			block = got
			return new
		end)
	end)
	if not ok or type(result) ~= "table" then
		failed("a write", result)
		return false
	end
	warned = false
	pending[def] = math.max(0, (pending[def] or 0) - add)
	stored[def] = tonumber(result.Held) or stored[def]
	if take > 0 then
		blocks[def] = block :: Exist.Block
	end
	show(def)
	return true
end

-- The next number of `def`'s kind, reserving a block when this server's is spent; nil while the store won't answer.
local function number(def: string): number?
	local no = Exist.Take(blocks[def])
	if no then
		return no
	end
	if not write(def, ExistConfig.Block) then
		return nil
	end
	return Exist.Take(blocks[def])
end

local function wake()
	local thread = waking
	if thread and coroutine.status(thread) == "suspended" then
		task.spawn(thread)
	end
end

-- Queues every owned Voidkin of `player`'s with no number, once each.
local function scan(player: Player, data: Profile.Data)
	local mine = queued[player]
	if mine == nil then
		mine = {}
		queued[player] = mine
	end
	local added = false
	for _, each in Exist.Missing(data) do
		if not mine[each.Id] then
			mine[each.Id] = true
			table.insert(queue, { Player = player, Id = each.Id, Def = each.Def })
			added = true
		end
	end
	if added then
		wake()
	end
end

-- The worker: one number at a time, in the order queued. A store that won't answer keeps the job for later.
local function work()
	while true do
		local job = queue[1]
		if job == nil then
			waking = coroutine.running()
			coroutine.yield()
			waking = nil
			continue
		end
		local mine = queued[job.Player]
		if job.Player.Parent ~= Players or mine == nil then
			table.remove(queue, 1)
			continue
		end
		local no = number(job.Def)
		if no == nil then
			task.wait(ExistConfig.Retry)
			continue
		end
		table.remove(queue, 1)
		mine[job.Id] = nil
		local answer = DataService.Change(job.Player, "ExistNo", function(draft: Profile.Data): { [string]: any }
			return Exist.Grant(draft, job.Id, no, ExistConfig.Epoch)
		end)
		if answer.Ok == true then
			pending[job.Def] = (pending[job.Def] or 0) + 1
			show(job.Def)
		end
	end
end

-- Every kind's count from the store, a kind at a time.
local function read()
	for _, row in Voidkin.List do
		local ok, result = pcall(function(): any
			return store:GetAsync(key(row.Id))
		end)
		if ok then
			local held = if type(result) == "table" then tonumber(result.Held) else nil
			stored[row.Id] = math.max(stored[row.Id] or 0, held or 0) -- never falls
			show(row.Id)
		else
			failed("a read", result)
		end
		task.wait(ExistConfig.Read / math.max(1, #Voidkin.List) / 4)
	end
end

-- This server's grants written, kind by kind.
local function flush()
	for def, add in pending do
		if add > 0 then
			write(def, 0)
		end
	end
end

local function join(player: Player)
	local data = DataService.WaitFor(player)
	if data == nil then
		return
	end
	if data.ExistEpoch ~= ExistConfig.Epoch then
		DataService.Change(player, "ExistEpoch", function(draft: Profile.Data): { [string]: any }
			return { Ok = Exist.Fresh(draft, ExistConfig.Epoch) }
		end)
	end
	local now = DataService.Get(player)
	if now then
		scan(player, now)
	end
end

function ExistService.Init()
	folder = Instance.new("Folder")
	folder.Name = ExistConfig.Folder
	folder.Parent = ReplicatedStorage
end

function ExistService.Start()
	local opened, got = pcall(function(): any
		return DataStoreService:GetDataStore(`{PREFIX}Exist`)
	end)
	if not opened then
		Log.Warn("ExistService", "no store, so no numbers on this server:", got)
		return
	end
	store = got
	DataService.Changed:Connect(function(player: Player, data: Profile.Data, _answer: any, label: string)
		if label ~= "ExistNo" and data.ExistEpoch == ExistConfig.Epoch then
			scan(player, data)
		end
	end)
	Players.PlayerAdded:Connect(function(player: Player)
		join(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(join, player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		queued[player] = nil
	end)
	task.spawn(work)
	task.spawn(function()
		while true do
			read()
			task.wait(ExistConfig.Read)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(ExistConfig.Flush)
			flush()
		end
	end)
	game:BindToClose(flush)
	if RunService:IsStudio() then
		-- The counts shown and this server's state: what's queued, each kind's block and what's not yet written.
		DebugService.Register("Exist", function(): any
			local out = {}
			for def, block in blocks do
				out[def] = { From = block.From, To = block.To, Held = stored[def], Pending = pending[def] }
			end
			return { Ok = true, Epoch = ExistConfig.Epoch, Queued = #queue, Kinds = out, Warned = warned }
		end)
		DebugService.Register("ExistFlush", function(): any
			flush()
			return { Ok = true }
		end)
	end
end

return ExistService
