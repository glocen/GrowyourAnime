--!strict
-- Figure (client): one Voidkin's own model, live, on the Voidkin screen's small stage (TR17; docs/research/
-- voidkin-screen.md, "DESIGN"). Its body stands in a ViewportFrame's WorldModel playing its Idle, framed so it is
-- `height` of its stage's height tall with its soles `feet` of the way down (shares, so the framing holds at any size).
-- The stage's light takes its rarity's trim (Config.Hud.Card.Trim) and the floor's glow its element (Config.UIKit's
-- Elements): stand-in colours, the look is Modulo's after the pick. A drag turns it; a tap plays the end of its Reveal,
-- from the strike on; a flick across goes to the next or the one before (Config.Hud.Voidkin.Swipe). A Voidkin without
-- its own body stands as the grey stand-in, on the stand-in's clips.
-- A body never drawn yet isn't ready to draw: its first stage stood empty for 0.25 to 0.53 s, then grey before its
-- textures (TR17's takes, 2026-11-15; research's fix 1). Fetching it ahead (PreloadAsync) isn't enough: measured, the
-- engine makes a mesh ready only once something draws it, and says nothing when it has. So the stage has wings: a
-- viewport a few pixels wide in its corner where each body is drawn ahead, counted ready Config.Hud.Voidkin.Figure.Draw
-- seconds after it's fetched and standing there. Ready says so, and the screen keeps the one it shows until the next one
-- can stand whole. The wings and what they made ready last as long as their stage.
--   Figure.Wings(stage)               the wings in `stage`, new when it's another stage (nothing counted ready then)
--   Figure.Warm(def, done?)           its body fetched and drawn in the wings; `done` once it's ready (at once if so)
--   Figure.Ready(def) -> boolean      true once it is, or it has no body to draw
--   Figure.new(def, stage, height, feet, onSwipe) -> figure   built in `stage`, a frame its owner places and sizes
--   Figure.Frame(figure, height, feet)  framed again, for a stage of another size
--   Figure.Turn(figure, degrees)
--   Figure.Flourish(figure) -> true when its Reveal's end started
--   Figure.Slide(figure, from)        comes in from `from` authored pixels to its side, fading in
--   Figure.Gesture(figure, delta, took) -> "Tap" | "Swipe" | "Turn"   what a touch did, by its travel and its time
--   Figure.Destroy(figure)

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local AnimationsConfig = require(Shared.Config.Animations)
local RevealConfig = require(Shared.Config.Reveal)
local Voidkin = require(Shared.Definitions.Voidkin)
local Actions = require(Shared.Definitions.Actions)
local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Clips = require(UI.Parent.Controllers.Main.FighterController.Clips)

local Figure = {}

local HIP = 3 -- studs from the soles to the root, the Templates' R6 rig
local GREY_FLOOR = Color3.fromRGB(150, 156, 170) -- no element: a plain floor

export type Figure = {
	Def: string,
	Stage: Frame,
	View: ViewportFrame,
	Body: Model,
	Root: CFrame, -- where the body stands, unturned
	Yaw: number, -- degrees turned
	Idle: AnimationTrack?,
	Reveal: AnimationTrack?,
	Strike: number, -- the Reveal clip's strike, where its end begins
	Studs: number, -- its height, soles to crown
	Floor: BasePart, -- the disc it stands on
	Touch: TextButton,
	Connections: { RBXScriptConnection },
	OnSwipe: (step: number) -> (),
}

-- Its body and the clips it plays: its own, else the stand-in's.
local function pick(def: string): (Model?, string?, string?)
	local row = Voidkin.ById[def]
	local folder = ReplicatedStorage:FindFirstChild("NL_Reveal")
	local figures = folder and folder:FindFirstChild("Figures")
	if figures == nil then
		return nil, nil, nil
	end
	local own = if row and row.Model then figures:FindFirstChild(row.Model) else nil
	local reveal = if row and row.Model then `{row.Model}Reveal` else ""
	if own and own:IsA("Model") then
		local rig = AnimationsConfig.Rigs[if row and row.Rig then row.Rig else "R6"]
		local idle = Actions.IdleOf(def) or (if rig then rig.Idle else nil)
		return own, idle, if RevealConfig.Strikes[reveal] then reveal else RevealConfig.Fallback
	end
	local standIn = figures:FindFirstChild("StandIn")
	return if standIn and standIn:IsA("Model") then standIn else nil, AnimationsConfig.Rigs.R6.Idle, RevealConfig.Fallback
end

-- Each body's way to ready: true once it is, else those waiting on it.
local warmed: { [Model]: true | { () -> () } } = {}
local wings: WorldModel? = nil

local WINGS = 8 -- authored pixels a side: enough for the engine to draw it, too small and too faint to be seen

function Figure.Wings(stage: Frame)
	local world = wings
	if world and world:IsDescendantOf(stage) then
		return
	end
	if world and world.Parent then
		world.Parent:Destroy()
	end
	warmed = {} -- what another stage's wings drew may be out of memory by now
	local view = Instance.new("ViewportFrame")
	view.Name = "Wings"
	view.BackgroundTransparency = 1
	view.ImageTransparency = 0.98
	view.Size = UDim2.fromOffset(WINGS, WINGS)
	view.ZIndex = 0
	local made = Instance.new("WorldModel")
	made.Parent = view
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(0, HIP, -16), Vector3.new(0, HIP, 0))
	camera.Parent = view
	view.CurrentCamera = camera
	view.Parent = stage
	wings = made
end

-- For tests: a body's fetch held open (Hold), then let go (Release), as a slow network would.
function Figure.Hold(def: string)
	local source = pick(def)
	if source then
		warmed[source] = {}
	end
end

function Figure.Release(def: string)
	local source = pick(def)
	local state = if source then warmed[source] else nil
	if source and type(state) == "table" then
		warmed[source] = true
		for _, each in state do
			each()
		end
	end
end

function Figure.Ready(def: string): boolean
	local source = pick(def)
	return source == nil or warmed[source] == true
end

function Figure.Warm(def: string, done: (() -> ())?)
	local source = pick(def)
	local state = if source then warmed[source] else true
	if source == nil or state == true then
		if done then
			done()
		end
		return
	end
	if type(state) == "table" then
		if done then
			table.insert(state, done)
		end
		return
	end
	local waiting: { () -> () } = { done :: any }
	warmed[source] = waiting
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ source })
		end)
		local world = wings
		if world and world.Parent and warmed[source] == waiting then
			local body = source:Clone()
			local root = body:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				root.Anchored = true
			end
			body:PivotTo(CFrame.new(0, HIP, 0))
			body.Parent = world
			task.wait(HudConfig.Voidkin.Figure.Draw)
		end
		if warmed[source] ~= waiting then
			return -- another stage's wings since, or a test holds it
		end
		warmed[source] = true -- drawn, or it can't be: either way nothing more to wait for
		for _, each in waiting do
			each()
		end
	end)
end

local function load(body: Model, clip: string?, looped: boolean, priority: Enum.AnimationPriority): AnimationTrack?
	local animator = body:FindFirstChildWhichIsA("Animator", true)
	local animation = if clip then Clips.Animation(clip) else nil
	if animator == nil or animation == nil then
		return nil
	end
	local track = (animator :: Animator):LoadAnimation(animation)
	track.Looped = looped
	track.Priority = priority
	return track
end

local function place(figure: Figure)
	figure.Body:PivotTo(figure.Root * CFrame.Angles(0, math.rad(figure.Yaw), 0))
end

-- The stage camera, framed by shares of the stage's height: the visible height is the body's over `height`, and the
-- soles sit `feet` of the way down. Level, so the figure never leans.
local function frame(view: ViewportFrame, studs: number, height: number, feet: number)
	local camera = view.CurrentCamera :: Camera
	local fov = HudConfig.Voidkin.Figure.Fov
	local visible = studs / math.max(height, 0.05)
	local distance = visible / (2 * math.tan(math.rad(fov) / 2))
	local centre = (feet - 0.5) * visible
	camera.FieldOfView = fov
	camera.CFrame = CFrame.lookAt(Vector3.new(0, centre, -distance), Vector3.new(0, centre, 0))
end

function Figure.new(def: string, stage: Frame, height: number, feet: number, onSwipe: (step: number) -> ()): Figure?
	local source, idle, reveal = pick(def)
	if source == nil then
		return nil
	end
	local row = Voidkin.ById[def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
	local look = HudConfig.Voidkin.Stage
	local view = Instance.new("ViewportFrame")
	view.Name = "Figure"
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 2
	view.Ambient = Color3.fromRGB(70, 72, 80):Lerp(trim, look.Light)
	view.LightColor = Color3.new(1, 1, 1):Lerp(trim, look.Light * 0.5)
	view.LightDirection = Vector3.new(-0.4, -0.7, 1).Unit
	local world = Instance.new("WorldModel")
	world.Parent = view
	local body = source:Clone()
	local root = body:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		body.PrimaryPart = root
		root.Anchored = true
	end
	local standing = CFrame.new(0, HIP, 0)
	body:PivotTo(standing)
	local box, size = body:GetBoundingBox()
	local soles = box.Position.Y - size.Y / 2
	standing = CFrame.new(0, HIP - soles, 0) -- its soles on the floor, whatever its rig
	body:PivotTo(standing)
	body.Parent = world
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Shape = Enum.PartType.Cylinder
	floor.Anchored = true
	floor.Material = Enum.Material.Neon
	floor.Color = if row and row.Element ~= "" then UIKit.Elements[row.Element] or GREY_FLOOR else GREY_FLOOR
	floor.Transparency = look.Glow
	floor.Size = Vector3.new(0.1, size.X * 1.6 + 2, size.X * 1.6 + 2)
	floor.CFrame = CFrame.new(0, -0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
	floor.Parent = world
	local camera = Instance.new("Camera")
	camera.Parent = view
	view.CurrentCamera = camera
	frame(view, size.Y, height, feet)
	view.Parent = stage
	local touch = Instance.new("TextButton")
	touch.Name = "Touch"
	touch.Text = ""
	touch.BackgroundTransparency = 1
	touch.AutoButtonColor = false
	touch.Size = UDim2.fromScale(1, 1)
	touch.ZIndex = 3
	touch.Parent = stage
	local figure: Figure = {
		Def = def,
		Stage = stage,
		View = view,
		Body = body,
		Root = standing,
		Yaw = 0,
		Idle = load(body, idle, true, Enum.AnimationPriority.Idle),
		Reveal = load(body, reveal, false, Enum.AnimationPriority.Action4),
		Strike = if reveal and RevealConfig.Strikes[reveal] then RevealConfig.Strikes[reveal].Time else 0,
		Studs = size.Y,
		Floor = floor,
		Touch = touch,
		Connections = {},
		OnSwipe = onSwipe,
	}
	if figure.Idle then
		(figure.Idle :: AnimationTrack):Play(0)
	end
	-- One touch at a time: its travel turns the figure as it goes, and its end says whether it was a tap or a flick.
	local active: InputObject? = nil
	local began, last, startYaw, startTime = Vector2.zero, 0, 0, 0
	local function same(input: InputObject, kind: Enum.UserInputType): boolean
		local held = active
		if held == nil then
			return false
		end
		return input == held or (held.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == kind)
	end
	table.insert(figure.Connections, touch.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if active == nil and (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch) then
			active = input
			began = Vector2.new(input.Position.X, input.Position.Y)
			last, startYaw, startTime = input.Position.X, figure.Yaw, os.clock()
		end
	end))
	table.insert(figure.Connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if same(input, Enum.UserInputType.MouseMovement) then
			local dx = (input.Position.X - last) / Layers.Scale()
			last = input.Position.X
			Figure.Turn(figure, -dx * HudConfig.Voidkin.Figure.Turn)
		end
	end))
	table.insert(figure.Connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if same(input, Enum.UserInputType.MouseButton1) then
			active = nil
			local delta = (Vector2.new(input.Position.X, input.Position.Y) - began) / Layers.Scale()
			if Figure.Gesture(figure, delta, os.clock() - startTime) == "Swipe" then
				figure.Yaw = startYaw -- a flick goes to the next one; it doesn't leave this one turned
				place(figure)
			end
		end
	end))
	return figure
end

function Figure.Frame(figure: Figure, height: number, feet: number)
	frame(figure.View, figure.Studs, height, feet)
end

function Figure.Turn(figure: Figure, degrees: number)
	figure.Yaw = (figure.Yaw + degrees) % 360
	place(figure)
end

function Figure.Flourish(figure: Figure): boolean
	local track = figure.Reveal
	if track == nil then
		return false
	end
	track:Play(0.1)
	track.TimePosition = math.min(figure.Strike, math.max(0, track.Length - 0.1))
	return true
end

function Figure.Gesture(figure: Figure, delta: Vector2, took: number): string
	local swipe = HudConfig.Voidkin.Swipe
	if delta.Magnitude < swipe.Tap and took <= swipe.TapTime then
		Figure.Flourish(figure)
		return "Tap"
	end
	if math.abs(delta.X) >= swipe.Distance and math.abs(delta.X) > math.abs(delta.Y) and took <= swipe.Time then
		figure.OnSwipe(if delta.X < 0 then 1 else -1) -- a flick to the left brings the next one
		return "Swipe"
	end
	return "Turn"
end

function Figure.Slide(figure: Figure, from: number)
	local motion = HudConfig.Voidkin.Figure
	figure.View.Position = UDim2.fromOffset(from, 0)
	figure.View.ImageTransparency = 1
	TweenService:Create(figure.View, TweenInfo.new(motion.Back, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(0, 0),
		ImageTransparency = 0,
	}):Play()
end

function Figure.Destroy(figure: Figure)
	for _, connection in figure.Connections do
		connection:Disconnect()
	end
	figure.View:Destroy()
	figure.Touch:Destroy()
end

return Figure
