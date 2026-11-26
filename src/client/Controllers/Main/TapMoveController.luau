--!strict
-- TapMoveController (client): tap to move, TR69's trial block (tier 1; Config.Combat.TapMove, Rules.TapMove; research's
-- feel line, 2026-11-26: "the player taps the ground beside the lead, and it snaps there in a blink, clear of the slam,
-- swinging again as the ground cracks"). In a fight, a tap or a click that lands on the floor, and isn't the UI's
-- (gameProcessed) or the camera's drag (Rules.TapMove.IsTap), asks the server to send the lead there (Net "TapMove";
-- FightService.TapMove clamps it, checks the way and the recovery). A grey block ring marks where it goes. The ray sees
-- the floor only: it passes through bodies, effects and anything that isn't solid underfoot.
--   TapMoveController.Ask(spot) -> answer        the server asked for `spot`, as a tap does: its answer (the self-test's)
--   TapMoveController.Press(screen, seconds, pixels) -> Vector3?   a press at screen point `screen` that lasted
--                                                `seconds` and moved `pixels`, as the input hears one: the floor it hit
--                                                if it counts, else nil (nothing asked) (the self-test's)
--   TapMoveController.Ring() -> BasePart?       the spot's ring while it shows (the self-test's)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local TapMove = require(Shared.Rules.TapMove)

local TapMoveController = {}

local player = Players.LocalPlayer
local FLOOR_UP = 0.6 -- a floor faces up at least this much: a wall or a stall's side never counts
local TRIES = 6 -- parts the ray passes through before it gives up
local RING_GREY = Color3.fromRGB(214, 216, 222)

local ring: BasePart? = nil
local ringToken = 0

local function myLead(): Model?
	local folder = workspace:FindFirstChild("Fighters")
	for _, model in (if folder then folder:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

-- In a fight: the lead has a target (FightService's "Target").
local function fighting(): boolean
	local lead = myLead()
	local target = if lead then lead:GetAttribute("Target") else nil
	return type(target) == "string" and target ~= ""
end

-- The floor under screen point `screen`: the first solid, upward-facing surface that isn't a body.
local function floorAt(screen: Vector2): Vector3?
	local camera = workspace.CurrentCamera
	if camera == nil then
		return nil
	end
	local ray = camera:ScreenPointToRay(screen.X, screen.Y)
	local skipped: { Instance } = {}
	local fighters = workspace:FindFirstChild("Fighters")
	if fighters then
		table.insert(skipped, fighters)
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(skipped, other.Character)
		end
	end
	for _ = 1, TRIES do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = skipped
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
		if hit == nil then
			return nil
		end
		local part = hit.Instance
		local body = part:FindFirstAncestorOfClass("Model")
		local isBody = body ~= nil and body:FindFirstChildOfClass("Humanoid") ~= nil
		local solid = part:IsA("Terrain") or (part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.95)
		if solid and not isBody and hit.Normal.Y >= FLOOR_UP then
			return hit.Position
		end
		table.insert(skipped, if isBody and body then body else part)
	end
	return nil
end

local function showRing(at: Vector3)
	ringToken += 1
	local token = ringToken
	if ring then
		ring:Destroy()
	end
	local look = Combat.TapMove.Ring
	local part = Instance.new("Part")
	part.Name = "NL_TapMoveRing"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame = CFrame.new(at + Vector3.new(0, 0.06, 0))
	local band = Instance.new("CylinderHandleAdornment")
	band.Name = "Band"
	band.Adornee = part
	band.CFrame = CFrame.Angles(math.rad(90), 0, 0) -- the cylinder's axis up
	band.Height = 0.04
	band.Radius = look.Radius
	band.InnerRadius = look.Radius * 0.78
	band.Color3 = RING_GREY
	band.Transparency = 0.15
	band.AlwaysOnTop = false
	band.ZIndex = 1
	band.Parent = part
	part.Parent = workspace
	ring = part
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local u = (os.clock() - started) / math.max(look.Seconds, 0.05)
		if token ~= ringToken or u >= 1 then
			connection:Disconnect()
			if token == ringToken then
				part:Destroy()
				ring = nil
			end
			return
		end
		band.Transparency = 0.15 + 0.85 * u * u -- holds, then goes
	end)
end

function TapMoveController.Ask(spot: Vector3): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "TapMove", spot)
	local result: { [string]: any } = if ok and type(answer) == "table" then answer else { Ok = false, Error = "NoAnswer" }
	if result.Ok and typeof(result.At) == "Vector3" then
		showRing(result.At)
	end
	return result
end

function TapMoveController.Press(screen: Vector2, seconds: number, pixels: number): Vector3?
	if not Combat.TapMove.On or not TapMove.IsTap(seconds, pixels, Combat.TapMove.Drag) or not fighting() then
		return nil
	end
	local spot = floorAt(screen)
	if spot then
		task.spawn(TapMoveController.Ask, spot)
	end
	return spot
end

function TapMoveController.Ring(): BasePart?
	return ring
end

type Press = { Began: number, From: Vector2, Most: number }

function TapMoveController.Start()
	local presses: { [InputObject]: Press } = {}
	local function counts(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not counts(input) then
			return -- the UI's: a button, a panel, the thumbstick
		end
		local at = Vector2.new(input.Position.X, input.Position.Y)
		presses[input] = { Began = os.clock(), From = at, Most = 0 }
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		local press = presses[input]
		if press then
			local now = Vector2.new(input.Position.X, input.Position.Y)
			press.Most = math.max(press.Most, (now - press.From).Magnitude)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		local press = presses[input]
		presses[input] = nil
		if press == nil then
			return
		end
		local now = Vector2.new(input.Position.X, input.Position.Y)
		local moved = math.max(press.Most, (now - press.From).Magnitude)
		TapMoveController.Press(press.From, os.clock() - press.Began, moved)
	end)
end

return TapMoveController
