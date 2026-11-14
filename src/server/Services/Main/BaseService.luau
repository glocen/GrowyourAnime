--!strict
-- BaseService (server): a player's base keeps time. It registers the base's actions (Shared.Rules.Base) with the save's one
-- door, advances the base on a return as time away, and wakes it online at its next event, so a shard is Ready the moment it
-- finishes, and at least every Config.Base.Clock.MostSeconds, so the battery and overflow Credits reach the client.
-- Nothing is advanced on leaving: the next load counts from the last stamp as time away. Within the away hours the workers
-- make the same either way, so the most a leave can cost is that many seconds of a long absence's cap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Breaker = require(Shared.Rules.Breaker)
local BaseRules = require(Shared.Rules.Base)
local BaseConfig = require(Shared.Config.Base)
local Shards = require(Shared.Definitions.Shards)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local BaseService = {
	Priority = 20, -- after DataService
}

local rng = Random.new()
local timers: { [Player]: thread } = {}

-- Server time in seconds, fractional, the clock clients can read too (workspace:GetServerTimeNow).
local function now(): number
	return workspace:GetServerTimeNow()
end

local function advance(player: Player, label: string, away: boolean): { [string]: any }
	return DataService.Change(player, label, function(draft: Profile.Data): { [string]: any }
		local summary = Breaker.Advance(draft, now(), away)
		return { Ok = true, Finished = summary.Finished, Made = summary.Made, Credits = summary.Credits }
	end)
end

local schedule: (player: Player) -> ()

local function wake(player: Player)
	timers[player] = nil -- this thread is running: nothing to cancel
	if DataService.Get(player) == nil then
		return
	end
	advance(player, "BaseClock", false) -- its Changed schedules the next wake
	if timers[player] == nil then
		schedule(player) -- the change failed: keep the clock going
	end
end

function schedule(player: Player)
	local old = timers[player]
	if old then
		task.cancel(old)
	end
	timers[player] = nil
	local data = DataService.Get(player)
	if data == nil then
		return
	end
	local clock = BaseConfig.Clock
	local soonest = Breaker.NextEvent(data) -- seconds from the stamp
	local due = if soonest then data.Base.Stamp + soonest - now() + clock.LeastSeconds else math.huge
	timers[player] = task.delay(math.clamp(due, clock.LeastSeconds, clock.MostSeconds), wake, player)
end

local function onReady(player: Player)
	advance(player, "BaseReturn", true)
	schedule(player)
end

local function registerDebug()
	-- Studio only. A readout of the base, time passing without waiting for it, and shards in the bag.
	DebugService.Register("Base", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		local data = player and DataService.Get(player)
		if not data then
			return nil
		end
		local base = data.Base
		local chambers = {}
		for index, chamber in base.Chambers do
			local work = chamber.Work
			local seconds = work and Breaker.Cost(work.Def)
			chambers[index] = if work then `{work.Def} {string.format("%.1f", work.Done)}/{seconds}` else "empty"
		end
		local line = {}
		for _, work in base.Line do
			table.insert(line, work.Def)
		end
		local ready = {}
		for _, work in base.Ready do
			table.insert(ready, work.Def)
		end
		local workers = {}
		for index, bay in base.Bays do
			workers[index] = if bay.Worker == "" then "empty" else `{bay.Worker} ({data.Voidkin[bay.Worker].Def})`
		end
		return {
			Battery = `{string.format("%.2f", base.Battery)}/{BaseConfig.Battery.Capacity}`,
			PerSecond = Breaker.Production(data),
			Chambers = chambers,
			Line = line,
			Ready = ready,
			Bays = workers,
			Bag = data.Bag.Shards,
			Lead = data.Roles.Lead,
			Credits = data.Currency.Credits,
			NextEvent = Breaker.NextEvent(data),
			StampAge = now() - base.Stamp,
		}
	end)
	-- As if `seconds` passed, online or away: the stamp moves back, then the base advances to now.
	DebugService.Register("BaseSkip", function(who: any, seconds: any, away: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(seconds) ~= "number" or seconds <= 0 or seconds ~= seconds then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseSkip", function(draft: Profile.Data): { [string]: any }
			if draft.Base.Stamp == 0 then
				return { Ok = false, Error = "NoStamp" }
			end
			draft.Base.Stamp -= seconds
			local summary = Breaker.Advance(draft, now(), away == true)
			return { Ok = true, Finished = summary.Finished, Made = summary.Made, Credits = summary.Credits }
		end)
	end)
	-- The battery set to `amount`, within its capacity: the Breaker screen's prices tried at each side (TR9).
	DebugService.Register("BaseBattery", function(who: any, amount: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(amount) ~= "number" or amount ~= amount then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseBattery", function(draft: Profile.Data): { [string]: any }
			Breaker.Advance(draft, now())
			local before = draft.Base.Battery
			draft.Base.Battery = math.clamp(amount, 0, BaseConfig.Battery.Capacity)
			return { Ok = true, Battery = draft.Base.Battery, Before = before }
		end)
	end)
	DebugService.Register("BaseGive", function(who: any, shard: any, count: any): any
		local player = DebugService.ResolvePlayer(who)
		local amount = if count == nil then 1 else count
		if not player or type(shard) ~= "string" or Shards.ById[shard] == nil or type(amount) ~= "number" or amount == 0 or amount ~= math.floor(amount) then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseGive", function(draft: Profile.Data): { [string]: any }
			local held = math.max(0, (draft.Bag.Shards[shard] or 0) + amount) -- a negative count takes them out, never below none
			draft.Bag.Shards[shard] = if held > 0 then held else nil
			return { Ok = true, Held = held }
		end)
	end)
end

function BaseService.Init()
	for name, action in BaseRules.Actions do
		DataService.Action(name, function(draft: Profile.Data, args: any): { [string]: any }
			return action(draft, args, now(), rng:NextNumber())
		end)
	end
	if RunService:IsStudio() then
		registerDebug()
	end
end

function BaseService.Start()
	DataService.Ready:Connect(onReady)
	DataService.Changed:Connect(function(player: Player)
		schedule(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local timer = timers[player]
		timers[player] = nil
		if timer then
			task.cancel(timer)
		end
	end)
	for _, player in Players:GetPlayers() do -- a save opened before this Start connected; a second advance is a no-op
		if DataService.Get(player) then
			onReady(player)
		end
	end
end

return BaseService
