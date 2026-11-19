--!strict
-- DoorService (server): the Festival Door (docs/design.md, "The world, in grey"; the director, 2026-11-12: "let just make
-- a door or something at the base to teleport to zones easily"). Walking into a plot's door (its part named Way) sets the
-- player down at the gate of the ground it goes to, today Lantern Row's DoorLanding, facing up the street; walking into
-- that ground's own door sets them down on their plot's spawn. Each move is the keeper's fade with the lead at the side
-- (KeeperService.SetDown), never during a try, and once a second at most a player. The doors are found again whenever the
-- grey world is laid. DoorService.Through (player, kind) once a door has taken a player: StageService starts a fresh
-- player's first stage, or sends the picker (TR43).
-- Since the Festival of Battles is its own place (TR45; the director, 2026-11-19: "the teleport point of the base will
-- simply open the menu ui of the game mode"), the plot's door moves no one: walking into it opens the Festival's menu
-- (Through, "FestivalDoor"), once each time in. The Festival's own door is the trip home (TravelService.Home).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Signal = require(Shared.Util.Signal)

local GameConfig = require(Shared.Config.Game)
local PlaceRole = require(Shared.Util.PlaceRole)

local KeeperService = require(script.Parent.KeeperService)
local WorldService = require(script.Parent.WorldService)
local TravelService = require(script.Parent.TravelService)

local DoorService = {
	Priority = 46, -- after the keeper, whose set-down it uses
}

DoorService.Through = Signal.new() -- (player, kind) a door took them: "FestivalDoor" or "GroundDoor"

local GAP = 1 -- seconds before a player's next way through

local last: { [Player]: number } = {}
local hooked: { [Instance]: true } = setmetatable({}, { __mode = "k" }) :: any -- each door's way, once

-- Where a door sets `player` down, or nil when it goes nowhere for them.
local function goal(player: Player, kind: string): CFrame?
	if kind == "FestivalDoor" then
		local landing = Markers.Find("DoorLanding", { Ground = WorldConfig.Row.Ground })
		return if landing then Markers.At(landing) else nil
	end
	return WorldService.SpawnOf(player)
end

local function hook(door: Instance, kind: string)
	local way = door:FindFirstChild("Way")
	if way == nil or not way:IsA("BasePart") or hooked[way] then
		return
	end
	hooked[way] = true
	way.Touched:Connect(function(part: BasePart)
		local player = if part.Parent and part.Parent:IsA("Model") then Players:GetPlayerFromCharacter(part.Parent) else nil
		local now = os.clock()
		if player == nil or (last[player] and now - last[player] < GAP) then
			if player then
				last[player] = now -- still in the way: once each time in
			end
			return
		end
		if kind == "FestivalDoor" and not PlaceRole.Is("Festival") then
			last[player] = now
			if player:GetAttribute("Try") == nil then
				DoorService.Through:Fire(player, kind) -- the menu (StageService)
			end
			return
		elseif kind == "GroundDoor" and PlaceRole.Is("Festival") then
			last[player] = now
			if player:GetAttribute("Try") == nil then
				TravelService.Home(player)
			end
			return
		end
		local at = goal(player, kind)
		if at and KeeperService.SetDown(player, at) then
			last[player] = now
			DoorService.Through:Fire(player, kind)
		end
	end)
end

-- A plot's door shows whether it goes anywhere: its core's glow full while the ground it goes to is laid, low while
-- none is (AR15, section 7; LightingController lights a kit piece by "Working").
local function show(door: Instance)
	local core = door:FindFirstChild("Core")
	if core then
		core:SetAttribute("Working", GameConfig.Places.Festival ~= nil or Markers.Find("DoorLanding", { Ground = WorldConfig.Row.Ground }) ~= nil)
	end
end

local function hookAll()
	for _, kind in { "FestivalDoor", "GroundDoor" } do
		for _, door in Markers.All(kind) do
			hook(door, kind)
			if kind == "FestivalDoor" then
				show(door)
			end
		end
	end
end

function DoorService.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		last[player] = nil
	end)
	WorldService.Laid:Connect(hookAll)
	WorldService.Built:Connect(hookAll) -- a plot's base stood for its owner: its door is new
	hookAll()
end

return DoorService
