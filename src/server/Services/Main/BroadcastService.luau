--!strict
-- BroadcastService (server): tells what's worth telling (TR57; docs/design.md, "Being seen"; Rules.Broadcast;
-- Config.Broadcast). A committed change's news (Broadcast.Read) goes to this server's players by the Broadcast remote,
-- and a line for every server also waits in this server's outbox, published to one MessagingService topic at most once
-- every Config.Broadcast.Bundle seconds, all its waiting lines in one message under 1 kB. Every server hears the topic
-- and passes on the lines of the others', its own skipped (it told them already). Delivery is best effort, as news may
-- be. A player whose ShareFinds is off, or who told every server inside Config.Broadcast.Every, is told on this server
-- only (Broadcast.Settle); one whose ShowFinds is off is sent only their own. A line carries ids and numbers and the
-- finder's display name as Roblox gives it, and each client builds the words from its own definitions; nothing a player
-- typed is ever carried (docs/roblox-rules.md, "Text players write").
-- Its sources: DataService.Changed's committed answers, a Tower run's end (this server's best floor today, Goals.DayOf's
-- day) and TowerBoardService.Led (the week's first place).
--   BroadcastService.News()   the last Config.Boards.News every-server lines, this server's and others', newest first: the
--                             news plate on the Strip (TR58, BoardsService)

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local BoardsConfig = require(Shared.Config.Boards)
local Log = require(Shared.Util.Log)
local Net = require(Shared.Net)
local Profile = require(Shared.Data.Profile)
local Broadcast = require(Shared.Rules.Broadcast)
local Goals = require(Shared.Rules.Goals)
local Settings = require(Shared.Rules.Settings)

local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local TowerBoardService = require(script.Parent.TowerBoardService)

local BroadcastService = {
	Priority = 52, -- after the Tower's board, whose first place it tells
}

-- A playtest never tells a live server, as DataService's saves and the Tower's board keep apart.
local TOPIC = (if RunService:IsStudio() then "Test" else "Live") .. Config.Topic
-- This server's name on the topic: its JobId, or in Studio, where every test server's is "", one of its own.
local JOB = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)
local SEND_EVERY = 1 -- seconds between looks at the outbox; Broadcast.Send keeps it to one message a Bundle

local outbox = Broadcast.Outbox()
local count = 0 -- this server's lines so far: each line's id is "{JOB}:{count}"
local last: { [number]: number } = {} -- by UserId: when the player's last every-server line went, os.time()
local best = { Day = 0, Floor = 0 } -- this server's best Tower floor today (Broadcast.Record)
local told: { Broadcast.News } = {} -- the last lines this server sent its players, newest last: for tests
local news: { Broadcast.News } = {} -- the last every-server lines, newest first (BroadcastService.News)

local function hold(item: Broadcast.News)
	table.insert(news, 1, item)
	while #news > BoardsConfig.News do
		table.remove(news)
	end
end

-- A line to this server's players: those who show others' finds, and the finder always.
local function show(item: Broadcast.News)
	local to: { Player } = {}
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if player.UserId == item.User or data == nil or Settings.On(data, "ShowFinds") then
			table.insert(to, player)
		end
	end
	if #to > 0 then
		Net.Server.FireList("Broadcast", to, item)
	end
	table.insert(told, item)
	if #told > 20 then
		table.remove(told, 1)
	end
end

-- `item` told of `player`: named, given its id, settled to every server or this one, and shown here.
function BroadcastService.Tell(player: Player, item: Broadcast.News)
	local data = DataService.Get(player)
	local now = os.time()
	count += 1
	item.Id = `{JOB}:{count}`
	item.User = player.UserId
	item.Name = player.DisplayName
	if Broadcast.Settle(item, data ~= nil and Settings.On(data, "ShareFinds"), last[player.UserId], now) then
		last[player.UserId] = now
		table.insert(outbox.Lines, item)
		hold(item)
	end
	show(item)
end

local function heard(message: any)
	local lines, job = Broadcast.Unpack(if type(message) == "table" then message.Data else nil)
	if job == nil or job == JOB then
		return
	end
	for _, item in lines do
		hold(item)
		show(item)
	end
end

local function send()
	local message = Broadcast.Send(outbox, JOB, os.time())
	if message == nil then
		return
	end
	local ok, problem = pcall(function()
		MessagingService:PublishAsync(TOPIC, message)
	end)
	if not ok then
		Log.Warn("BroadcastService", `a message wasn't sent to every server: {tostring(problem)}`)
	end
end

function BroadcastService.News(): { Broadcast.News }
	return table.clone(news)
end

function BroadcastService.Start()
	DataService.Changed:Connect(function(player: Player, data: Profile.Data, answer: any, label: string?)
		if label == "TowerEnd" then
			local floor = if type(answer) == "table" and answer.Ok == true then tonumber(answer.Floor) else nil
			if floor and Broadcast.Record(best, floor, Goals.DayOf(os.time())) then
				BroadcastService.Tell(player, Broadcast.Climb("Record", floor))
			end
			return
		end
		local item = Broadcast.Read(label or "", answer, data)
		if item then
			BroadcastService.Tell(player, item)
		end
	end)
	TowerBoardService.Led:Connect(function(player: Player, floor: number)
		if player.Parent == Players then
			BroadcastService.Tell(player, Broadcast.Climb("Board", floor))
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		last[player.UserId] = nil
	end)
	task.spawn(function()
		local ok, problem = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, heard)
		end)
		if not ok then
			Log.Warn("BroadcastService", `other servers' lines won't be heard: {tostring(problem)}`)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(SEND_EVERY)
			send()
		end
	end)
	if RunService:IsStudio() then
		-- The lines this server told its players lately, newest last, and what waits for every server.
		DebugService.Register("Broadcast", function(): any
			return { Ok = true, Told = told, Waiting = #outbox.Lines, Job = JOB, Topic = TOPIC }
		end)
		-- A line told of a player as if a change had made it: Tell's whole path (kind, def, rarity, level).
		DebugService.Register("BroadcastTell", function(who: any, kind: any, def: any, rarity: any, level: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player or type(kind) ~= "string" or table.find(Broadcast.Kinds, kind) == nil then
				return { Ok = false, Error = "BadArgs" }
			end
			local item: Broadcast.News = {
				Id = "",
				Kind = kind,
				Reach = "Server",
				Def = if type(def) == "string" then def else "",
				Rarity = if type(rarity) == "string" then rarity else "Rare",
				Level = if type(level) == "number" then level else 0,
				User = 0,
				Name = "",
			}
			BroadcastService.Tell(player, item)
			return { Ok = true, Id = item.Id }
		end)
	end
end

return BroadcastService
