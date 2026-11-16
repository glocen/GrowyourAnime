--!strict
-- BaseService (server): a player's base keeps time. It registers the base's actions (Shared.Rules.Base) with the save's one
-- door, advances the base on a return as time away, and wakes it online at its next event, so a shard is Ready the moment it
-- finishes, and at least every Config.Base.Clock.MostSeconds, so the battery, overflow Credits and the Training machine's
-- levels reach the client. Nothing is advanced on leaving: the next load counts from the last stamp as time away, with the
-- lead on the Training machine. Within the away hours the workers generate the same either way, so the most a leave can
-- cost is that many seconds of a long absence's cap.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Breaker = require(Shared.Rules.Breaker)
local BaseLevels = require(Shared.Rules.BaseLevels)
local BaseRules = require(Shared.Rules.Base)
local BaseConfig = require(Shared.Config.Base)
local WorldConfig = require(Shared.Config.World)
local Shards = require(Shared.Definitions.Shards)
local Markers = require(Shared.World.Markers)
local Power = require(Shared.Rules.Power)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local WorldService = require(script.Parent.WorldService)

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
		return { Ok = true, Finished = summary.Finished, Made = summary.Made, Credits = summary.Credits, Trained = summary.Trained or "", Levels = summary.Levels }
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

-- A plot's machines as its owner's base stands (AR15; AR16), for every client, so a passer-by sees the plant work:
-- * a chamber that breaks a shard glows full with the shard between its points, an empty one low with none ("Working");
-- * the generator's wheel turns by the plant's generation ("Generation"), its gauge's steps light by it, and the demand's
--   mark stands at the demand's share ("Share"), on one scale (Rules.Power.Gauge; AR19);
-- * each bay the base has opened stands awake and the rest asleep, where a level will wake them;
-- * the battery's bank shows the cells its base's level holds, each lit by its share of the charge ("Lit",
--   Rules.Breaker.Cells);
-- * the Training machine's crown turns while a Voidkin trains ("Training").
-- `data` nil stills them all, with level 1's bays and cells.
local function showPlot(number: number, data: Profile.Data?)
	local plant = Markers.Find("Generator", { Plot = number })
	local rates = if data then Breaker.Rates(data) else nil
	local generation = if rates then rates.Generation else 0
	local gauge = Power.Gauge(generation, if rates then rates.Demand else 0, WorldConfig.Grey.Generator.Gauge)
	if plant then
		local wheel = plant:FindFirstChild("Wheel")
		if wheel then
			wheel:SetAttribute("Generation", generation)
		end
		local mark = plant:FindFirstChild("Demand")
		if mark then
			mark:SetAttribute("Share", gauge.Demand)
		end
		for _, step in plant:GetChildren() do
			local index = step:GetAttribute("Step")
			if type(index) == "number" and step:IsA("BasePart") then
				step.Transparency = if index <= gauge.Lit then 0 else 1
			end
		end
	end
	local open = if data then #data.Base.Bays else BaseLevels.Bays(1)
	for _, bay in Markers.All("Bay") do
		local index = bay:GetAttribute("Bay")
		local pad, sleeping = bay:FindFirstChild("Pad"), bay:FindFirstChild("Sleeping")
		if bay:GetAttribute("Plot") == number and type(index) == "number" and pad and sleeping and pad:IsA("BasePart") and sleeping:IsA("BasePart") then
			WorldService.Stand(pad, index <= open)
			WorldService.Stand(sleeping, index > open)
		end
	end
	local battery = Markers.Find("Battery", { Plot = number })
	if battery then
		local shown = BaseLevels.Cells(if data then data.Base.Level else 1)
		local lit = if data then Breaker.Cells(data.Base) else {}
		for _, cell in battery:GetChildren() do
			local seat = cell:GetAttribute("Cell")
			if type(seat) == "number" and cell:IsA("BasePart") then
				WorldService.Stand(cell, seat <= shown)
				cell:SetAttribute("Lit", lit[seat] or 0)
			end
		end
	end
	local trainer = Markers.Find("Training", { Plot = number })
	local crown = if trainer then trainer:FindFirstChild("Crown") else nil
	if crown then
		crown:SetAttribute("Training", data ~= nil and Breaker.Trainee(data) ~= nil)
	end
	local breaker = Markers.Find("Breaker", { Plot = number })
	if breaker == nil then
		return
	end
	local index = 1
	while true do
		local chamber = breaker:FindFirstChild(`Chamber {index}`)
		if chamber == nil then
			break
		end
		local held = if data then data.Base.Chambers[index] else nil
		local working = held ~= nil and held.Work ~= nil
		if chamber:GetAttribute("Working") ~= nil then
			chamber:SetAttribute("Working", working)
		end
		local shard = breaker:FindFirstChild(`Shard {index}`)
		if shard and shard:IsA("BasePart") then
			shard.Transparency = if working then 0 else 1
		end
		index += 1
	end
end

local shown: { [Player]: number } = {} -- the plot whose machines show each player's base

local function show(player: Player)
	local number = WorldService.PlotOf(player)
	local was = shown[player]
	if was and was ~= number then
		showPlot(was, nil)
	end
	shown[player] = number
	if number then
		showPlot(number, DataService.Get(player))
	end
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
		local rates = Breaker.Rates(data)
		return {
			Charge = `{string.format("%.3f", base.Charge)}/{Breaker.Capacity(base)} kWh`,
			Generation = rates.Generation,
			Demand = rates.Flow.Demand,
			Speed = rates.Flow.Speed,
			NetKw = rates.NetKw,
			Power = { Auto = base.Power.Auto, Shares = base.Power.Shares, Open = base.Power.Open },
			Trainee = data.Training.Trainee,
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
			return { Ok = true, Finished = summary.Finished, Made = summary.Made, Credits = summary.Credits, Trained = summary.Trained or "", Levels = summary.Levels }
		end)
	end)
	-- The battery's charge set to `amount` kWh, within its capacity: the Breaker screen's prices tried at each side (TR9).
	DebugService.Register("BaseBattery", function(who: any, amount: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(amount) ~= "number" or amount ~= amount then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseBattery", function(draft: Profile.Data): { [string]: any }
			Breaker.Advance(draft, now())
			local before = draft.Base.Charge
			draft.Base.Charge = math.clamp(amount, 0, Breaker.Capacity(draft.Base))
			return { Ok = true, Charge = draft.Base.Charge, Before = before }
		end)
	end)
	-- The Power screen opened or shut, as if a machine beside the Breaker had drawn power or never had; shut, Auto again
	-- (TR18's case: the screen and its refusal before it opens).
	DebugService.Register("PowerOpen", function(who: any, open: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(open) ~= "boolean" then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "PowerOpen", function(draft: Profile.Data): { [string]: any }
			Breaker.Advance(draft, now())
			draft.Base.Power.Open = open
			if not open then
				draft.Base.Power.Auto = true
			end
			return { Ok = true, Open = open }
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
		show(player)
	end)
	local function joined(player: Player)
		player:GetAttributeChangedSignal("Plot"):Connect(function()
			show(player)
		end)
		show(player)
	end
	Players.PlayerAdded:Connect(joined)
	WorldService.Laid:Connect(function() -- the plots were laid again: new chambers
		for _, player in Players:GetPlayers() do
			show(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local timer = timers[player]
		timers[player] = nil
		if timer then
			task.cancel(timer)
		end
		local was = shown[player]
		shown[player] = nil
		if was then
			showPlot(was, nil)
		end
	end)
	for _, player in Players:GetPlayers() do -- a save opened before this Start connected; a second advance is a no-op
		joined(player)
		if DataService.Get(player) then
			onReady(player)
		end
	end
end

return BaseService
