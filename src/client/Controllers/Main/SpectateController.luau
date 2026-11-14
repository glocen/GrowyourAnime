--!strict
-- SpectateController (client): the spectate toggle (TR11; the director, 2026-11-14, night: the player's camera is never
-- moved in a fight, and a small button follows the lead instead). On, Roblox's camera follows the player's lead instead
-- of their avatar. What it follows is a stand-in point, set before the camera each frame and eased from the avatar's
-- focus to the lead's (Config.Hud.Spectate, Rules.Hud.Approach), so the camera's heading and distance stay the player's
-- own and their drag and zoom work as ever. The avatar still walks, and the lead still follows it. Off, or when the lead
-- falls or leaves, it eases back onto the avatar; at a move's black fade it's back at once, in the black. Off at every
-- join and every spawn; never a setting.
--   SpectateController.Set(on)    on or off (the HUD's eye); never on with no lead standing
--   SpectateController.On()       whether it's on
--   SpectateController.Changed    fires (on) when it turns on or off
--   SpectateController.Share()    how far the camera's point has gone from the avatar to the lead, 0 to 1, for tests
--   SpectateController.Point()    the stand-in the camera follows while it's off the avatar, else nil, for tests

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Hud = require(Shared.Rules.Hud)
local Parts = require(Shared.Util.Parts)
local FadeController = require(script.Parent.FadeController)

local player = Players.LocalPlayer

local SpectateController = {}

-- Where Roblox's camera stands over an R6 avatar's root (its camera module's HEAD_OFFSET), so the way out starts exactly
-- where the camera already looks.
local AVATAR = Vector3.new(0, 1.5, 0)

local on = false
local share = 0
local leadFocus: Vector3? = nil -- the lead's focus when last seen standing, for the way back once it has gone
local point: Part? = nil
local changed = Instance.new("BindableEvent")
SpectateController.Changed = changed.Event

local function myLead(): Model?
	local folder = workspace:FindFirstChild("Fighters")
	for _, model in (if folder then folder:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			return model
		end
	end
	return nil
end

local function standing(lead: Model?): BasePart?
	local root = Parts.Root(lead)
	return if lead and root and lead:GetAttribute("State") ~= "Down" then root else nil
end

local function set(want: boolean)
	if on ~= want then
		on = want
		changed:Fire(on)
	end
end

-- The stand-in the camera follows: an anchored point under the camera, never in the world's queries.
local function makePoint(camera: Camera): Part
	local made = Instance.new("Part")
	made.Name = "NL_Spectate"
	made.Anchored = true
	made.CanCollide, made.CanQuery, made.CanTouch = false, false, false
	made.Transparency = 1
	made.Size = Vector3.one * 0.2
	made.Parent = camera
	point = made
	return made
end

-- Back on the avatar this frame (in a fade's black, or once the way back is done).
local function home()
	share = 0
	local camera = workspace.CurrentCamera
	local humanoid = Parts.Humanoid(player.Character)
	if camera and humanoid and point and camera.CameraSubject == point then
		camera.CameraSubject = humanoid
	end
end

function SpectateController.Set(want: boolean)
	set(want and standing(myLead()) ~= nil)
end

function SpectateController.On(): boolean
	return on
end

function SpectateController.Share(): number
	return share
end

function SpectateController.Point(): Part?
	return if share > 0 then point else nil
end

function SpectateController.Start()
	FadeController.OnFade(function(out: number)
		if on or share > 0 then
			set(false)
			task.delay(out, home)
		end
	end)
	player.CharacterAdded:Connect(function()
		set(false)
		share = 0 -- the new avatar's camera is Roblox's own
	end)
	RunService:BindToRenderStep("NL_Spectate", Enum.RenderPriority.Camera.Value - 1, function(dt: number)
		local camera = workspace.CurrentCamera
		local character = player.Character
		local humanoid = Parts.Humanoid(character)
		local root = Parts.Root(character)
		if camera == nil or humanoid == nil or root == nil then
			return
		end
		local look = HudConfig.Spectate
		local leadRoot = standing(myLead())
		if leadRoot then
			leadFocus = leadRoot.Position + Vector3.new(0, look.Height, 0)
		elseif on then
			set(false) -- it fell, or it's gone: back to the avatar
		end
		share = Hud.Approach(share, if on then 1 else 0, dt, look.Ease)
		if not on and share < 1e-3 then
			home()
			return
		end
		if camera.CameraType ~= Enum.CameraType.Custom then
			return -- a scripted camera (the reveal) has it
		end
		local from = root.Position + root.CFrame:VectorToWorldSpace(AVATAR + humanoid.CameraOffset)
		local made = if point and point.Parent == camera then point else makePoint(camera)
		made.CFrame = CFrame.new(from:Lerp(leadFocus or from, share))
		if camera.CameraSubject ~= made then
			camera.CameraSubject = made
		end
	end)
end

return SpectateController
