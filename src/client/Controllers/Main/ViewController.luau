--!strict
-- ViewController (client): the lead and the player's camera (TR24's fixes 2 and 3). The camera is never moved for it
-- (the director, 2026-11-14, night: the player's camera is never moved in a fight).
-- - It tells the server where the camera looks, a flat bearing (Net "View"), whenever that turns Turn degrees or every
--   Every seconds: FightService picks the lead's fights in view, sets it where the camera frames the fight, and stands it
--   beside the avatar out of the camera's line (Config.Combat.Lead.View, Side, Ahead).
-- - On this screen, a lead standing in the camera's line to the avatar, or too near the camera, fades to
--   Combat.Lead.Fade.Transparency over its Seconds, and back once it's clear (Rules.Fight.InLine), through each part's
--   LocalTransparencyModifier. Not the lead the spectate camera follows, nor a lead that's down or home: its fall and its
--   leaving as light are FighterController's, and a fade lets go of it first.
--   ViewController.Faded(model)   how far a lead is faded now, 0 to 1 of Transparency, for tests

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local Fight = require(Shared.Rules.Fight)
local SpectateController = require(script.Parent.SpectateController)

local player = Players.LocalPlayer

local ViewController = {}

local TURN = 4 -- degrees the camera turns before it's said again
local EVERY = 1 -- seconds, at most, between two reports, so the server's never goes stale (Combat.Lead.View.Fresh)

type Faded = { Share: number, Radius: number, Parts: { Instance }, Added: RBXScriptConnection? }
local faded: { [Model]: Faded } = {}
local said: number? = nil
local saidAt = -math.huge

local function bearingOf(look: Vector3): number?
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return nil -- straight down or up: the last bearing stands
	end
	return math.deg(math.atan2(flat.Z, flat.X))
end

local function report(camera: Camera)
	local bearing = bearingOf(camera.CFrame.LookVector)
	if bearing == nil then
		return
	end
	local now = os.clock()
	if said ~= nil and Fight.Off(bearing, said) < TURN and now - saidAt < EVERY then
		return
	end
	said, saidAt = bearing, now
	Net.Client.Fire("View", math.floor(bearing * 10 + 0.5) / 10)
end

-- Each part and decal a fade reaches, and the body's half-width on the ground, read once per model.
local function entry(model: Model): Faded
	local known = faded[model]
	if known then
		return known
	end
	local list: { Instance } = {}
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") or item:IsA("Decal") then
			table.insert(list, item)
		end
	end
	local size = model:GetExtentsSize()
	local made: Faded = { Share = 0, Radius = math.max(size.X, size.Z) / 2, Parts = list }
	made.Added = model.DescendantAdded:Connect(function(item: Instance)
		if item:IsA("BasePart") or item:IsA("Decal") then
			table.insert(list, item)
			;(item :: any).LocalTransparencyModifier = made.Share * Combat.Lead.Fade.Transparency
		end
	end)
	faded[model] = made
	return made
end

local function paint(f: Faded, share: number)
	local amount = share * Combat.Lead.Fade.Transparency
	for _, item in f.Parts do
		if item.Parent ~= nil then
			(item :: any).LocalTransparencyModifier = amount
		end
	end
end

-- Lets go of a model: whole again at once, unless it's gone.
local function drop(model: Model, f: Faded)
	if f.Added then
		f.Added:Disconnect()
	end
	if model.Parent ~= nil and f.Share > 0 then
		paint(f, 0)
	end
	faded[model] = nil
end

-- Whether `model`, a lead, stands in the camera's line to `subject` or too near the camera.
local function inLine(camera: Camera, subject: Vector3, model: Model, radius: number): boolean
	local from = camera.CFrame.Position
	local line = subject - from
	local length = line.Magnitude
	if length < 1e-3 then
		return false -- first person: Roblox hides the avatar, and a lead in front is what's seen
	end
	local unit = line / length
	local middle = model:GetPivot().Position
	local offset = middle - from
	local along = offset:Dot(unit)
	local across = (offset - unit * along).Magnitude
	local fade = Combat.Lead.Fade
	return Fight.InLine(along, across, length, radius, fade.Margin, fade.Near)
end

local function step(dt: number)
	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end
	report(camera)
	local character = player.Character
	local head = if character then character:FindFirstChild("Head") :: BasePart? else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local subject = if head then head.Position elseif root then root.Position else nil
	local folder = workspace:FindFirstChild("Fighters")
	local seen: { [Model]: boolean } = {}
	local rate = dt / math.max(Combat.Lead.Fade.Seconds, 1e-3)
	if folder and subject then
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("Side") == "Lead" then
				local state = model:GetAttribute("State")
				local followed = SpectateController.On() and model:GetAttribute("Owner") == player.UserId
				local f = faded[model]
				if state == "Down" or state == "Home" or followed then
					-- its fall and its leaving are FighterController's: let go of it, whole, at once
					if f then
						drop(model, f)
					end
				else
					f = entry(model)
					local want = if inLine(camera, subject, model, (f :: Faded).Radius) then 1 else 0
					local share = (f :: Faded).Share
					local next = if want > share then math.min(want, share + rate) else math.max(want, share - rate)
					if next ~= share then
						(f :: Faded).Share = next
						paint(f :: Faded, next)
					end
					seen[model] = true
				end
			end
		end
	end
	for model, f in faded do
		if not seen[model] then
			drop(model, f)
		end
	end
end

function ViewController.Faded(model: Model): number
	local f = faded[model]
	return if f then f.Share else 0
end

function ViewController.Start()
	-- after the camera has moved this frame, so the line is the one drawn
	RunService:BindToRenderStep("GA_View", Enum.RenderPriority.Camera.Value + 2, step)
end

return ViewController
