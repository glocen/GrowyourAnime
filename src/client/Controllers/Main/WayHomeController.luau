--!strict
-- WayHomeController (client): the trail home after a lone fall (docs/test-requests.md, TR16). When the player's only
-- Voidkin falls and none other could lead, the fallen card's "Go home" chip (HudController) turns this on: a thin grey
-- line on the floor from the avatar to the ground's home door, the Festival Door's twin at the gate, redrawn as the avatar
-- walks (Rules.WayHome, Config.Hud.WayHome). It never moves the player. It's gone at the door, out of the ground, at a
-- respawn, on a second tap, and when the card no longer offers it (the lead's return, or another ready).
--   WayHomeController.Set(on)    on or off; never on with nowhere to go
--   WayHomeController.Toggle()   the chip's tap
--   WayHomeController.On()       whether it's drawn
--   WayHomeController.Away()     whether the avatar is out in a ground, where the way home is offered
--   WayHomeController.Door()     the home door's floor point, from the world's folder, or nil
--   WayHomeController.Points()   the trail's points as drawn, empty while it's off, for tests

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local LightingConfig = require(Shared.Config.Lighting)
local Night = require(Shared.Rules.Night)
local WayHome = require(Shared.Rules.WayHome)
local Parts = require(Shared.Util.Parts)

local player = Players.LocalPlayer

local WORLD = "World"

local WayHomeController = {}

local on = false
local drawn: { Vector3 } = {}
local folder: Folder? = nil
local segments: { Part } = {}

local function world(): Instance?
	return workspace:FindFirstChild(WORLD)
end

function WayHomeController.Door(): Vector3?
	local folderOf = world()
	local at = if folderOf then folderOf:GetAttribute("HomeDoor") else nil
	return if typeof(at) == "Vector3" then at else nil
end

-- The street's middle X and half width (WorldService), or nil.
local function street(): Vector2?
	local folderOf = world()
	local at = if folderOf then folderOf:GetAttribute("Street") else nil
	return if typeof(at) == "Vector2" then at else nil
end

function WayHomeController.Away(): boolean
	local root = Parts.Root(player.Character)
	local folderOf = world()
	local gateZ = if folderOf then folderOf:GetAttribute("GateZ") else nil
	if root == nil or type(gateZ) ~= "number" or player:GetAttribute("Try") ~= nil then
		return false -- a keeper's try sets the player down itself
	end
	return Night.Inside(root.Position.Z, gateZ, LightingConfig.From) -- one line for "in the ground": the night's
end

-- Where the trail goes from here, or nil when it can't be drawn: no avatar, no door, out of the ground, or arrived.
local function route(): { Vector3 }?
	local root = Parts.Root(player.Character)
	local door = WayHomeController.Door()
	local lane = street()
	if root == nil or door == nil or lane == nil or not WayHomeController.Away() then
		return nil
	end
	local look = HudConfig.WayHome
	if WayHome.Arrived(root.Position, door, look.Reach) then
		return nil
	end
	return WayHome.Route(root.Position, door, lane.X, lane.Y - look.Lane)
end

local function clear()
	drawn = {}
	for _, part in segments do
		part:Destroy()
	end
	segments = {}
	if folder then
		folder:Destroy()
		folder = nil
	end
end

-- A segment of the line: anchored, out of every query, touch and shadow, so nothing in the world feels it.
local function segment(parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = "Leg"
	part.Anchored = true
	part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function draw(points: { Vector3 })
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	if folder == nil or folder.Parent ~= camera then
		clear()
		local made = Instance.new("Folder")
		made.Name = "NL_WayHome"
		made.Parent = camera
		folder = made
	end
	local look = HudConfig.WayHome
	local lift = Vector3.new(0, look.Lift + look.Thick / 2, 0)
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local part = segments[index] or segment(folder :: Folder)
		segments[index] = part
		local along = b - a
		local length = along.Magnitude
		part.Color = look.Colour
		part.Transparency = look.Transparency
		part.Size = Vector3.new(look.Width, look.Thick, math.max(length + look.Width, look.Width)) -- the joints close
		local mid = (a + b) / 2 + lift
		part.CFrame = if length > 1e-3 then CFrame.lookAt(mid, mid + along) else CFrame.new(mid)
	end
	for index = #segments, math.max(#points, 1), -1 do
		segments[index]:Destroy()
		segments[index] = nil
	end
	drawn = points
end

function WayHomeController.Set(want: boolean)
	local points = if want then route() else nil
	on = points ~= nil
	if points then
		draw(points) -- drawn on the tap's own frame
	else
		clear()
	end
end

function WayHomeController.Toggle()
	WayHomeController.Set(not on)
end

function WayHomeController.On(): boolean
	return on
end

function WayHomeController.Points(): { Vector3 }
	return table.clone(drawn)
end

function WayHomeController.Start()
	player.CharacterAdded:Connect(function()
		WayHomeController.Set(false)
	end)
	RunService.RenderStepped:Connect(function()
		if not on then
			return
		end
		local points = route()
		if points == nil then
			WayHomeController.Set(false) -- at the door, out of the ground, or the avatar gone
			return
		end
		draw(points)
	end)
end

return WayHomeController
