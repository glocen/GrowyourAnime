--!strict
-- HomeService (server): home in one tap, the dock's Base tile (docs/test-requests.md, TR19; it replaces TR16's chip and
-- trail). The tile asks (Net "Home") and the server decides (Rules.Home): refused, it answers why in plain words; else
-- the charge begins (the player's HomeCharge attribute: its start, server time) and runs Config.Home.Charge seconds. A
-- fight is FightService.InCombat, or a hit in the last few seconds while the lead stands (research's verdict on TR19). A
-- hit the player's side deals or takes in the charge (FightService's HitAt) cancels it, and nothing is spent. Then the
-- player and their lead are set down at their plot's spawn facing its Breaker (KeeperService.Place, no fade: the jump's
-- light is the client's), the cooldown starts (HomeReady: its end, server time) and the client is told (Net "HomeJump").
-- In Studio: HomeState reads it all, HomeHit stamps a hit now, HomeReady ends the cooldown.
-- In the Festival's place the same charge, and its jump is the trip back to the base (TravelService.Home, TR45).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local HomeConfig = require(Shared.Config.Home)
local Home = require(Shared.Rules.Home)
local Markers = require(Shared.World.Markers)
local Parts = require(Shared.Util.Parts)
local Net = require(Shared.Net)

local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local PlaceRole = require(Shared.Util.PlaceRole)
local KeeperService = require(script.Parent.KeeperService)
local TravelService = require(script.Parent.TravelService)
local FightService = require(script.Parent.FightService)
local WorldService = require(script.Parent.WorldService)

local HomeService = {
	Priority = 47, -- after the keeper, whose set-down it uses
}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function number(player: Player, name: string): number?
	local value = player:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

function HomeService.Situation(player: Player): Home.Situation
	local root = Parts.Root(player.Character)
	return {
		Now = now(),
		HitAt = number(player, "HitAt"),
		Engaged = FightService.InCombat(player),
		Standing = FightService.Standing(FightService.LeadOf(player)),
		Try = player:GetAttribute("Try") ~= nil,
		Event = false, -- no event exists yet: the rule keeps its place (TR19)
		ReadyAt = number(player, "HomeReady") or 0,
		OnPlot = Markers.OnPlot(WorldService.PlotOf(player), if root then root.Position else nil),
	}
end

-- The plot's spawn, turned to face its Breaker: where a jump sets the player down.
local function arrival(player: Player): CFrame?
	local spawn = WorldService.SpawnOf(player)
	local plot = WorldService.PlotOf(player)
	local breaker = if plot then Markers.Find("Breaker", { Plot = plot }) else nil
	if spawn == nil or breaker == nil then
		return spawn
	end
	local toward = Markers.At(breaker).Position - spawn.Position
	local flat = Vector3.new(toward.X, 0, toward.Z)
	return if flat.Magnitude > 1e-3 then CFrame.lookAt(spawn.Position, spawn.Position + flat) else spawn
end

local function jump(player: Player, began: number)
	if player.Parent == nil or player:GetAttribute("HomeCharge") ~= began then
		return -- left, or another charge took its place
	end
	player:SetAttribute("HomeCharge", nil)
	local s = HomeService.Situation(player)
	if Home.Broken(began, s.HitAt) then
		Net.Server.Fire("HomeJump", player, false, Home.Says("Fight", s))
		return
	end
	local refusal: Home.Refusal? = if s.Try then "Boss" elseif s.Event then "Event" else nil -- a try or an event begun in it
	if PlaceRole.Is("Festival") then
		local going = refusal == nil and TravelService.Home(player)
		Net.Server.Fire("HomeJump", player, going, if refusal then Home.Says(refusal, s) else nil)
		return
	end
	local at = arrival(player)
	if refusal or at == nil or not KeeperService.Place(player, at :: CFrame) then
		Net.Server.Fire("HomeJump", player, false, if refusal then Home.Says(refusal, s) else nil)
		return
	end
	player:SetAttribute("HomeReady", now() + HomeConfig.Cooldown)
	Net.Server.Fire("HomeJump", player, true)
end

-- Sets the player and their lead down at their plot's spawn now, free: no charge and no cooldown (the Tower's results'
-- Home, TR46: the Tower stands behind their own base). False when there's nowhere, or nothing moves.
function HomeService.SetDown(player: Player): boolean
	local at = arrival(player)
	return at ~= nil and KeeperService.Place(player, at :: CFrame)
end

-- A tap on the Base tile: the charge begins, or the answer says why not. A second tap in a charge changes nothing.
function HomeService.Ask(player: Player): { [string]: any }
	local s = HomeService.Situation(player)
	local refusal = Home.Refusal(s, HomeConfig)
	if refusal then
		return { Ok = false, Refusal = refusal, Says = Home.Says(refusal, s) }
	end
	if player:GetAttribute("HomeCharge") ~= nil then
		return { Ok = true, Charging = true }
	end
	if not PlaceRole.Is("Festival") and arrival(player) == nil then
		return { Ok = false, Refusal = "Nowhere" } -- no plot or no spawn: the world report says what
	end
	local began = s.Now
	player:SetAttribute("HomeCharge", began)
	task.delay(HomeConfig.Charge, jump, player, began)
	return { Ok = true, Charging = true }
end

function HomeService.Start()
	Net.Server.Handle("Home", function(player: Player): { [string]: any }
		return HomeService.Ask(player)
	end)
	if RunService:IsStudio() then
		DebugService.Register("HomeState", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player then
				return { Ok = false, Error = "BadArgs" }
			end
			local s = HomeService.Situation(player)
			local refusal = Home.Refusal(s, HomeConfig)
			return {
				Ok = true,
				Refusal = refusal or "",
				Says = Home.Says(refusal, s) or "",
				OnPlot = s.OnPlot,
				Charge = player:GetAttribute("HomeCharge") or 0,
				ReadyIn = math.max(s.ReadyAt - s.Now, 0),
			}
		end)
		DebugService.Register("HomeHit", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player then
				return { Ok = false, Error = "BadArgs" }
			end
			player:SetAttribute("HitAt", now())
			return { Ok = true }
		end)
		DebugService.Register("HomeReady", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player then
				return { Ok = false, Error = "BadArgs" }
			end
			player:SetAttribute("HomeReady", nil)
			player:SetAttribute("HitAt", nil)
			return { Ok = true }
		end)
	end
end

return HomeService
