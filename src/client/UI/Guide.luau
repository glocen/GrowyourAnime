--!strict
-- Guide (client): the next step's marker in the world (TR24's fix 1; Rules.Hud.NextStep says where). A chevron over each
-- target, pointing down at it and bobbing, on the World layer (UI.World: drawn in captures, steps back while a screen is
-- open); while the target is off the frame or behind the camera, one arrow at the frame's edge points the way to it.
-- Within Config.Hud.Guide.Near studs of the avatar both step back, and the target's own prompt speaks.
--   Guide.Point(targets, colour?)   the targets, parts or models (nil or empty: none); the same list again changes nothing
--   Guide.Errand(targets?, seconds?) an errand the player asked for (the Play panel's "Go to the Tower"): these targets
--                                   over Point's until the avatar comes Near them, `seconds` pass, or Errand(nil)
--   Guide.Read()                    for tests: how many targets, how many chevrons show, whether the edge's arrow shows
--   Guide.Test(targets?)            for tests: these targets until Test(nil), whatever Point says meanwhile; then Point's

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)

local Layers = require(script.Parent.Layers)
local World = require(script.Parent.World)
local Screen = require(script.Parent.Kit.Screen)

local Guide = {}

local CONFIG = HudConfig.Guide
local INK = Color3.fromHex("#120E22") -- the chevron's outline, so it reads on a pale sky and on the void alike
local THICK = 7 -- a bar's thickness, authored points
local NUDGE = 4 -- authored points the edge's arrow nudges either way along its way

local player = Players.LocalPlayer
local targets: { Instance } = {}
local tops: { Vector3 } = {} -- each target's top, read when pointed at
local chevrons: { Frame } = {}
local edge: Frame? = nil
local colour = UIKit.Systems.Voidkin.Colour
local hidden = true -- near the target, or none
local rides = false -- the edge's arrow on the next step's chip, its own spot taken
local held: { Instance }? = nil -- a test's targets, over Point's
local wanted: { Instance } = {} -- Point's last
local errand: { Instance }? = nil -- an errand's targets, over Point's and under a test's
local errandUntil = 0 -- os.clock() the errand gives the marker back at

-- A chevron of two bars pointing down, its point at the frame's foot.
local function chevron(parent: GuiObject)
	local long = CONFIG.Size * 0.62
	for index, turn in { 45, -45 } do
		local bar = Instance.new("Frame")
		bar.Name = if index == 1 then "Left" else "Right"
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Size = UDim2.fromOffset(long, THICK)
		bar.Position = UDim2.new(0.5, (if index == 1 then -1 else 1) * long * 0.33, 0.5, 0)
		bar.Rotation = turn
		bar.BackgroundColor3 = colour
		bar.BorderSizePixel = 0
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Thickness = 1.5
		stroke.Parent = bar
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = bar
		bar.Parent = parent
	end
end

local function topOf(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position + Vector3.new(0, target.Size.Y / 2, 0)
	elseif target:IsA("Model") then
		local frame, size = target:GetBoundingBox()
		return frame.Position + Vector3.new(0, size.Y / 2, 0)
	end
	return nil
end

local function avatarAt(): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	return if root and root.Parent then root.Position else nil
end

local function bob(): number
	return CONFIG.Bob * math.sin(os.clock() * CONFIG.Rate * 2 * math.pi)
end

local function clear()
	for _, frame in chevrons do
		World.Remove(frame)
	end
	chevrons, targets, tops = {}, {}, {}
	if edge then
		edge.Visible = false
	end
end

local function apply(list: { Instance }?, tint: Color3?)
	list = list or {}
	local same = #(list :: { Instance }) == #targets
	if same then
		for index, target in list :: { Instance } do
			same = same and targets[index] == target
		end
	end
	if same and (tint == nil or tint == colour) then
		return
	end
	clear()
	colour = tint or UIKit.Systems.Voidkin.Colour
	for index, target in list :: { Instance } do
		local top = topOf(target)
		if top == nil then
			continue
		end
		table.insert(targets, target)
		table.insert(tops, top)
		local n = #tops
		local frame = World.Plate(`NL_Guide{index}`, Vector2.new(CONFIG.Size, CONFIG.Size * 0.6), function(): Vector3?
			local at = tops[n]
			if hidden or at == nil or targets[n] == nil or targets[n].Parent == nil then
				return nil
			end
			return at + Vector3.new(0, CONFIG.Lift + bob(), 0)
		end)
		chevron(frame)
		table.insert(chevrons, frame)
	end
	if edge then
		for _, bar in edge:GetChildren() do
			if bar.Name == "Backing" then
				local rim = bar:FindFirstChildOfClass("UIStroke")
				if rim then
					rim.Color = colour -- the backing stays the ink; only its rim takes the colour
				end
			elseif bar:IsA("Frame") then
				bar.BackgroundColor3 = colour
			end
		end
	end
end

function Guide.Point(list: { Instance }?, tint: Color3?)
	wanted = list or {}
	if held == nil and errand == nil then
		apply(wanted, tint)
	end
end

function Guide.Test(list: { Instance }?)
	held = list
	apply(if list then list else errand or wanted)
end

function Guide.Errand(list: { Instance }?, seconds: number?)
	errand = if list and #list > 0 then list else nil
	errandUntil = os.clock() + (seconds or 60)
	if held == nil then
		apply(errand or wanted)
	end
end

function Guide.Read(): { Count: number, Shown: number, Edge: boolean, Arrow: Frame?, Rides: boolean, Errand: boolean }
	local shown = 0
	for _, frame in chevrons do
		if frame.Visible then
			shown += 1
		end
	end
	return { Count = #targets, Shown = shown, Edge = edge ~= nil and edge.Visible, Arrow = edge, Rides = rides, Errand = errand ~= nil }
end

-- The edge's arrow drawn pointing down, its turn set each frame: a round dark backing rimmed in the guide's colour, and an
-- arrow on it, a shaft and a head of two bars, each bar in the guide's colour with the chevrons' ink round it.
local function edgeArrow(parent: Frame)
	local look = CONFIG.Edge
	local size = look.Size
	local backing = Instance.new("Frame")
	backing.Name = "Backing"
	backing.AnchorPoint = Vector2.new(0.5, 0.5)
	backing.Position = UDim2.fromScale(0.5, 0.5)
	backing.Size = UDim2.fromScale(1, 1)
	backing.BackgroundColor3 = INK
	backing.BackgroundTransparency = look.Backing
	backing.BorderSizePixel = 0
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = backing
	local rim = Instance.new("UIStroke")
	rim.Color = colour
	rim.Transparency = look.Rim
	rim.Thickness = 2
	rim.Parent = backing
	backing.Parent = parent
	local length = size * 0.6
	local tip = Vector2.new(size / 2, size / 2 + length / 2)
	local head = size * 0.34
	local function bar(name: string, centre: Vector2, long: number, turn: number)
		local made = Instance.new("Frame")
		made.Name = name
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Size = UDim2.fromOffset(long, THICK)
		made.Position = UDim2.fromOffset(centre.X, centre.Y)
		made.Rotation = turn
		made.BackgroundColor3 = colour
		made.BorderSizePixel = 0
		made.ZIndex = 2
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Thickness = 1.5
		stroke.Parent = made
		local ends = Instance.new("UICorner")
		ends.CornerRadius = UDim.new(0.5, 0)
		ends.Parent = made
		made.Parent = parent
	end
	bar("Shaft", Vector2.new(size / 2, size / 2 - THICK * 0.3), length - THICK * 0.6, 90)
	local reach = head * 0.5 * math.sqrt(0.5)
	bar("Left", tip + Vector2.new(-reach, -reach) + Vector2.new(0.5, -0.5) * THICK * 0.35, head, 45)
	bar("Right", tip + Vector2.new(reach, -reach) + Vector2.new(-0.5, -0.5) * THICK * 0.35, head, -45)
end

-- The edge's arrow: where the targets' middle is off the frame, at the frame's inset edge on the way to it, turned to it.
local function stepEdge()
	local arrow = edge
	if arrow == nil then
		local layer = Layers.Get("World")
		local made = Instance.new("Frame")
		made.Name = "NL_GuideEdge"
		made.BackgroundTransparency = 1
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Size = UDim2.fromOffset(CONFIG.Edge.Size, CONFIG.Edge.Size)
		made.Visible = false
		edgeArrow(made)
		made.Parent = layer
		edge = made
		arrow = made
	end
	local a = arrow :: Frame
	if errand and os.clock() > errandUntil then -- an errand nobody walked: the marker is the next step's again
		Guide.Errand(nil)
	end
	local camera = workspace.CurrentCamera
	local at = avatarAt()
	if #tops == 0 or camera == nil or at == nil then
		hidden = true
		a.Visible = false
		return
	end
	-- Over each target where it is now, a moving one too (the plates read the same tops after this step).
	for index, target in targets do
		tops[index] = (if target.Parent then topOf(target) else nil) or tops[index]
	end
	local middle, nearest = Vector3.zero, math.huge
	for _, top in tops do
		middle += top / #tops
		nearest = math.min(nearest, (Vector3.new(top.X, at.Y, top.Z) - at).Magnitude)
	end
	hidden = nearest <= CONFIG.Near
	if hidden then
		a.Visible = false
		if errand and held == nil then -- arrived: the errand is done, and the next step's marker stands again
			Guide.Errand(nil)
		end
		return
	end
	local screen = camera:WorldToViewportPoint(middle + Vector3.new(0, CONFIG.Lift, 0))
	-- The frame is the World layer's, from its top left in the viewport's pixels: the window in play, a take's phone where
	-- the take frames one (UI.Layers.Box with a corner, AR51), so the arrow stands at that phone's edge as on the phone.
	local layer = a.Parent :: GuiObject
	local origin = layer.AbsolutePosition + GuiService:GetGuiInset()
	local view = layer.AbsoluteSize
	if view.X <= 0 or view.Y <= 0 then
		a.Visible = false
		return
	end
	local seen = Vector2.new(screen.X, screen.Y) - origin
	local scale = Layers.Scale()
	local margin, top, bottom = CONFIG.Margin * scale, CONFIG.Top * scale, CONFIG.Bottom * scale
	-- Never under the HUD's top band (the cards and the pills, UI.World.Band): the arrow drawn under the wallet was unseen
	-- (TR24's fix 1, read on an unlocked screen, 2026-11-16).
	-- In view is judged on the frame's own inset: a chevron in the sky over the band still shows, and no arrow with it.
	local inside = screen.Z > 0 and seen.X >= margin and seen.X <= view.X - margin and seen.Y >= top and seen.Y <= view.Y - bottom
	if inside then
		a.Visible = false
		return
	end
	local band = World.Edge()
	-- The arrow's middle keeps half its size inside the inset, and its nudge along the way (below), so the whole of it
	-- stays clear of the HUD's edges (the next step's chip under it).
	local pad = (CONFIG.Edge.Size * 0.5 + NUDGE) * scale
	margin += pad
	top += pad
	bottom += pad
	-- and over the next step's chip where it stands higher than the inset (research's must-fix, 2026-11-17)
	local chipTop = World.FootTop()
	if chipTop then
		bottom = math.max(bottom, view.Y - (chipTop - origin.Y) + pad + CONFIG.Edge.Clear * scale)
	end
	if band then
		top = math.max(top, band * scale + pad)
	end
	-- The way to it from the frame's middle (behind the camera, the way is turned round), cut at the inset edge.
	local centre = Vector2.new(view.X / 2, (top + view.Y - bottom) / 2)
	local way = seen - centre
	if screen.Z <= 0 then
		way = -way
	end
	if way.Magnitude < 1e-3 then
		way = Vector2.new(0, 1)
	end
	local halfX, halfY = view.X / 2 - margin, (view.Y - bottom - top) / 2
	local reach = math.min(if math.abs(way.X) > 1e-6 then halfX / math.abs(way.X) else math.huge, if math.abs(way.Y) > 1e-6 then halfY / math.abs(way.Y) else math.huge)
	local point = centre + way * reach
	local unit = way.Unit
	-- Never over the avatar, a prompt's card or a plate (research's call on AR51, 2026-11-23: on the smallest phone the
	-- band and the chip leave it no height, and it stood mid-screen over the avatar and the convert's prompt). Where its
	-- spot is taken it rides the next step's chip, Clear points off its end toward the target, else the other end, still
	-- turned to the target; with neither free, it waits. Judged on its box and its nudge both ways, so it never flickers.
	local reachOf = CONFIG.Edge.Size * scale / 2 + NUDGE * scale
	local taken = World.Taken()
	local function free(spotAt: Vector2): boolean
		local low, high = spotAt + origin - Vector2.one * reachOf, spotAt + origin + Vector2.one * reachOf
		if spotAt.X - reachOf < 0 or spotAt.X + reachOf > view.X then
			return false
		end
		for _, box in taken do
			if low.X < box.High.X and high.X > box.Low.X and low.Y < box.High.Y and high.Y > box.Low.Y then
				return false
			end
		end
		return true
	end
	rides = false
	if not free(point) then
		local low, high = World.FootBox()
		local spot: Vector2? = nil
		if low and high then
			local off = CONFIG.Edge.Clear * scale + reachOf
			local level = (low.Y + high.Y) / 2 - origin.Y
			for _, side in if unit.X < 0 then { -1, 1 } else { 1, -1 } do
				local beside = Vector2.new((if side > 0 then high.X + off else low.X - off) - origin.X, level)
				if free(beside) then
					spot = beside
					break
				end
			end
		end
		if spot == nil then
			a.Visible = false
			return
		end
		point = spot :: Vector2
		rides = true
	end
	point += unit * (bob() / CONFIG.Bob) * NUDGE * scale -- it nudges along its way, as the chevrons bob
	-- On the layer already (as UI.World places its plates). By scale, so the layer's UIScale sizes the arrow and never
	-- moves it.
	a.Position = UDim2.fromScale(point.X / view.X, point.Y / view.Y)
	a.Rotation = math.deg(math.atan2(unit.Y, unit.X)) - 90
	a.Visible = Screen.Current() == nil
end

RunService:BindToRenderStep("NL_Guide", Enum.RenderPriority.Camera.Value + 1, stepEdge) -- before the plates place theirs

return Guide
