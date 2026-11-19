--!strict
-- TravelService (server): the trip between the base and the Festival of Battles, each its own place in this experience
-- (TR45; the director, 2026-11-19: "festival of battle is a game mode it need a new places"; docs/engineering-plan.md,
-- "Places"; docs/research/game-mode-places.md). A trip is one TeleportAsync with its ticket (Rules.Travel) as the
-- teleport data, tried as Roblox's own pattern says (Config.Travel): the call Calls times, then on a failure after it a
-- wait by kind, at most Most failures, and a server asked for but full or gone gives way to any server once. A player
-- still here Watchdog seconds after the call gets their screen back: trips have stalled with no error.
--
-- The far side reads the ticket from GetJoinData once the save is open and fires Arrived; the ticket is a request, never
-- a grant, so whatever acts on it checks the save (StageService, Travel.Arrival). The save itself is released as the
-- player leaves, and the far server's ProfileStore waits for it. Home goes back to the base server they came from, else
-- any. In Studio the transport can be stubbed ("TravelStub"), so a self-test sees each trip asked for without leaving.
--   TravelService.ToStage(player, ground, difficulty, stage) -> (ok, error?)   from the base: to the Festival, that stage
--   TravelService.Home(player) -> (ok, error?)                                 from the Festival: back to the base
--   TravelService.Going(player) -> boolean                                     a trip is under way
--   TravelService.Arrived (player, ticket?, data)                              a player's save opened in this place

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.Game)
local TravelConfig = require(Shared.Config.Travel)
local Travel = require(Shared.Rules.Travel)
local Profile = require(Shared.Data.Profile)
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local PlaceRole = require(Shared.Util.PlaceRole)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local TravelService = {
	Priority = 44, -- after DataService; before the stages and the way home, which send through it
}

TravelService.Arrived = Signal.new() -- (player, ticket?, data) a player's save opened here, with the ticket they came by

TravelService.Unknown = "Unknown" -- no place for that role in Config.Game.Places
TravelService.Busy = "Busy" -- a trip is already under way
TravelService.Here = "Here" -- the player is already in that place

type Trip = {
	Place: number,
	Role: string,
	Ticket: Travel.Ticket,
	Server: string?, -- the one server asked for, if any
	Failed: number,
}

type Sent = { Player: string, Role: string, Ticket: Travel.Ticket, Server: string? }

local LANDED = 0.5 -- seconds after the avatar stands before a trip home's card lifts

local going: { [Player]: Trip } = {}
local from: { [Player]: string } = {} -- the base server each player came from, for the way home
local started = os.clock()
local stubbed = false
local sent: { Sent } = {} -- the stub's record, newest last

local function transport(trip: Trip, player: Player)
	if stubbed then
		table.insert(sent, { Player = player.Name, Role = trip.Role, Ticket = trip.Ticket, Server = trip.Server })
		return
	end
	local options = Instance.new("TeleportOptions")
	if trip.Server then
		options.ServerInstanceId = trip.Server
	end
	options:SetTeleportData(trip.Ticket :: any)
	TeleportService:TeleportAsync(trip.Place, { player }, options)
end

local function failed(player: Player, trip: Trip, why: string)
	if going[player] == trip then
		going[player] = nil
	end
	Log.Warn("TravelService", `{player.Name}'s trip to {trip.Role} failed: {why}`)
	Net.Server.Fire("Travel", player, "Failed", { Result = why })
end

-- The call, tried Calls times Gap seconds apart; then the watchdog.
local function call(player: Player, trip: Trip)
	local wait = TravelConfig.Settle - (os.clock() - started)
	if wait > 0 then
		task.wait(wait) -- a server just started sends no one out yet
	end
	local err: any = nil
	for attempt = 1, TravelConfig.Calls do
		if going[player] ~= trip or player.Parent == nil then
			return
		end
		local ok, problem = pcall(transport, trip, player)
		if ok then
			err = nil
			break
		end
		err = problem
		if attempt < TravelConfig.Calls then
			task.wait(TravelConfig.Gap)
		end
	end
	if err ~= nil then
		failed(player, trip, tostring(err))
		return
	end
	if stubbed then
		return -- recorded, and under way until a TravelFail or the stub's reset ends it
	end
	task.delay(TravelConfig.Watchdog, function()
		if going[player] == trip and player.Parent ~= nil then
			failed(player, trip, "Stalled")
		end
	end)
end

-- Roblox said the trip failed after the call: again after a wait by kind, or the screen back.
local function initFailed(player: Player, result: string, message: string)
	local trip = going[player]
	if trip == nil then
		return
	end
	trip.Failed += 1
	local step = Travel.Next(result, trip.Failed, trip.Server ~= nil)
	if step == nil then
		failed(player, trip, `{result}: {message}`)
		return
	end
	if step.Open then
		trip.Server = nil
	end
	Log.Info("TravelService", `{player.Name}'s trip: {result}, again in {step.Wait} s{if step.Open then ", to any server" else ""}`)
	task.delay(step.Wait, call, player, trip)
end

local function send(player: Player, role: string, ticket: Travel.Ticket, server: string?): (boolean, string?)
	local place = GameConfig.Places[role]
	if place == nil then
		return false, TravelService.Unknown
	elseif PlaceRole.Is(role) then
		return false, TravelService.Here
	elseif going[player] then
		return false, TravelService.Busy
	end
	local trip: Trip = { Place = place, Role = role, Ticket = ticket, Server = server, Failed = 0 }
	going[player] = trip
	Net.Server.Fire("Travel", player, "Leaving", { To = role })
	task.spawn(call, player, trip)
	return true, nil
end

function TravelService.Going(player: Player): boolean
	return going[player] ~= nil
end

-- From the base to the Festival, into that stage. The caller has checked the save opens it; the far side checks again.
function TravelService.ToStage(player: Player, ground: string, difficulty: string, stage: number): (boolean, string?)
	local here = if game.JobId ~= "" then game.JobId else nil
	return send(player, "Festival", Travel.Stage(ground, difficulty, stage, here, workspace:GetServerTimeNow()), nil)
end

-- From the Festival back to the base: the server they came from if it still stands, else any.
function TravelService.Home(player: Player): (boolean, string?)
	return send(player, "Main", Travel.Home(workspace:GetServerTimeNow()), from[player])
end

local function arrived(player: Player, data: Profile.Data)
	local join = player:GetJoinData()
	local source = join.SourcePlaceId
	local ours = false
	for _, id in GameConfig.Places do
		ours = ours or id == source
	end
	local ticket = if ours then Travel.Read(join.TeleportData) else nil
	if ticket then
		if ticket.From then
			from[player] = ticket.From
		end
		local took = Travel.Took(ticket, workspace:GetServerTimeNow())
		Log.Info("TravelService", `{player.Name} arrived by {ticket.Go}{if took then string.format(" in %.1f s", took) else ""}`)
	end
	TravelService.Arrived:Fire(player, ticket, data)
	if not PlaceRole.Is("Festival") then
		-- Home: the card lifts once the avatar stands on its plot (WorldService sets it down); the Festival's
		-- StageService lifts it once the stage stands.
		task.spawn(function()
			local waited = 0
			while player.Parent and player.Character == nil and waited < TravelConfig.Hold do
				waited += task.wait(0.2)
			end
			task.wait(LANDED)
			if player.Parent then
				Net.Server.Fire("Travel", player, "Arrived", {})
			end
		end)
	end
end

function TravelService.Init()
	-- Studio: ("TravelStub", nil, true) records each trip instead of making it, ("TravelStub", nil, false) makes them;
	-- either way every trip under way ends, its screen back. ("TravelSent") reads the record, newest last, with whether
	-- a trip is under way; ("TravelFail", who, result) fails the trip under way as Roblox would (a TeleportResult's name).
	DebugService.Register("TravelStub", function(_who: any, on: any): boolean
		stubbed = on == true
		for player in going do
			Net.Server.Fire("Travel", player, "Back", {})
		end
		table.clear(going)
		table.clear(sent)
		return stubbed
	end)
	DebugService.Register("TravelSent", function(who: any): { [string]: any }
		local player = DebugService.ResolvePlayer(who)
		local trip = if player then going[player] else nil
		return { Sent = sent, Going = trip ~= nil, Failed = if trip then trip.Failed else 0, Server = if trip then trip.Server else nil }
	end)
	DebugService.Register("TravelFail", function(who: any, result: any): boolean
		local player = DebugService.ResolvePlayer(who)
		if player == nil or going[player] == nil then
			return false
		end
		initFailed(player, tostring(result), "debug")
		return true
	end)
end

function TravelService.Start()
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		initFailed(player, result.Name, message)
	end)
	DataService.Ready:Connect(arrived)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			task.spawn(arrived, player, data)
		end
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		going[player] = nil
		from[player] = nil
	end)
end

return TravelService
