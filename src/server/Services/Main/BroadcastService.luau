--!strict
-- BroadcastService (server): tells what's worth telling (Rules.Broadcast; docs/research/cloud-2026-11-24/
-- launch-design.md, section 6, on the director's "ok" of 2026-11-24). A committed change's news goes to this server's
-- players by the "Broadcast" remote, and the rarest to every server too, by one MessagingService topic that every server
-- hears and passes on, its own messages skipped. Delivery is best effort, as news may be. What this server shows passes
-- one gate: at most Config.Broadcast.Most lines a Window, the oldest waiting dropped. A player whose ShowFinds is off
-- hears only their own; one whose ShareFinds is off is told on their own server only (Rules.Settings).
-- Its sources: DataService.Changed's committed answers (Broadcast.Read), a run's end for this server's Tower record, and
-- TowerBoardService.Led for the week's first place.
--   BroadcastService.Tell(player, news)   for a source of news with no label of its own

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Broadcast)
local Log = require(Shared.Util.Log)
local Net = require(Shared.Net)
local Broadcast = require(Shared.Rules.Broadcast)
local Settings = require(Shared.Rules.Settings)

local DataService = require(script.Parent.Parent.Core.DataService)
local TowerBoardService = require(script.Parent.TowerBoardService)

local BroadcastService = {
	Priority = 52, -- after the Tower's board, whose first place it tells
}

-- A playtest never tells a live server, as DataService's saves and the Tower's board keep apart.
local TOPIC = (if RunService:IsStudio() then "Test" else "Live") .. Config.Topic
local RELEASE_EVERY = 1 -- seconds between looks at the gate while lines wait

local gate = Broadcast.Gate()
local last: { [number]: number } = {} -- by UserId: when the player's last every-server line went, os.time()
local record = 0 -- the best floor a Tower run ended at on this server since it opened

local function release()
	for _, news in Broadcast.Release(gate, os.clock()) do
		local to: { Player } = {}
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			if player.UserId == news.User or data == nil or Settings.On(data, "ShowFinds") then
				table.insert(to, player)
			end
		end
		Net.Server.FireList("Broadcast", to, news)
	end
end

local function show(news: Broadcast.News)
	Broadcast.Wait(gate, news)
	release()
end

local function publish(news: Broadcast.News)
	task.spawn(function()
		local ok, problem = pcall(function()
			MessagingService:PublishAsync(TOPIC, Broadcast.Pack(news, game.JobId))
		end)
		if not ok then
			Log.Warn("BroadcastService", `a line wasn't sent to every server: {tostring(problem)}`)
		end
	end)
end

function BroadcastService.Tell(player: Player, news: Broadcast.News)
	news.User = player.UserId
	news.Name = player.DisplayName
	local data = DataService.Get(player)
	local now = os.time()
	if Broadcast.Settle(news, data == nil or Settings.On(data, "ShareFinds"), last[player.UserId], now) then
		last[player.UserId] = now
		publish(news)
	end
	show(news)
end

local function heard(message: any)
	local news, job = Broadcast.Unpack(if type(message) == "table" then message.Data else nil)
	if news and job ~= game.JobId then
		show(news)
	end
end

function BroadcastService.Start()
	DataService.Changed:Connect(function(player: Player, data: any, answer: any, label: string?)
		if label == "TowerEnd" and type(answer) == "table" and answer.Ok == true and type(answer.Floor) == "number" then
			local floor = answer.Floor
			local beaten = Broadcast.Record(record, floor)
			record = math.max(record, floor)
			if beaten then
				BroadcastService.Tell(player, Broadcast.Climb("Record", floor))
			end
			return
		end
		local news = Broadcast.Read(label or "", answer, data)
		if news then
			BroadcastService.Tell(player, news)
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
			task.wait(RELEASE_EVERY)
			if #gate.Waiting > 0 then
				release()
			end
		end
	end)
end

return BroadcastService
