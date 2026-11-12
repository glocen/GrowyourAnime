--!strict
-- DoorService (server): the Festival Door (docs/design.md, "The world, in grey"; the director, 2026-11-12: "let just make
-- a door or something at the base to teleport to zones easily"). Walking into a plot's door (its part named Way) sets the
-- player down at the gate of the ground it goes to, today Lantern Row's DoorLanding, facing up the street; walking into
-- that ground's own door sets them down on their plot's spawn. Each move is the keeper's fade with the lead at the side
-- (KeeperService.SetDown), never during a try, and once a second at most a player. The doors are found again whenever the
-- grey world is laid.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)

local KeeperService = require(script.Parent.KeeperService)
local WorldService = require(script.Parent.WorldService)

local DoorService = {
	Priority = 46, -- after the keeper, whose set-down it uses
}

local GAP = 1 -- seconds before a player's next way through

local last: { [Player]: number } = {}

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
	if way == nil or not way:IsA("BasePart") then
		return
	end
	way.Touched:Connect(function(part: BasePart)
		local player = if part.Parent and part.Parent:IsA("Model") then Players:GetPlayerFromCharacter(part.Parent) else nil
		local now = os.clock()
		if player == nil or (last[player] and now - last[player] < GAP) then
			return
		end
		local at = goal(player, kind)
		if at and KeeperService.SetDown(player, at) then
			last[player] = now
		end
	end)
end

local function hookAll()
	for _, kind in { "FestivalDoor", "GroundDoor" } do
		for _, door in Markers.All(kind) do
			hook(door, kind)
		end
	end
end

function DoorService.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		last[player] = nil
	end)
	WorldService.Laid:Connect(hookAll)
	hookAll()
end

return DoorService
