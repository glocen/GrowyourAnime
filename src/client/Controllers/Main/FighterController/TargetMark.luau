--!strict
-- TargetMark (client): a small cut chevron over the head of the player's own lead's target, in the target's type's
-- colour (TR69 A, R4, research's pick; Config.Effects.Mark its pictures and numbers, Config.Combat.TargetMark its switch,
-- the colours Config.Hud.Card.Types), in place of the ring at its feet that the bodies hid from the player's camera. One
-- BillboardGui of three ImageLabels in ZIndex order (the ink, the light in the type's colour, the white core), unlit and
-- always on top, on an unseen anchored part this client moves each frame: the chevron's apex Lift over the target's top
-- (a Shade's highest mask's top, else its head's), the picture's middle Centre over the apex, all at the target's scale.
-- A new target's mark drops in on a Back Out and fades in, then bobs. Hidden with no target, or once the target is down
-- or walking home.
--   TargetMark.Step(target)   each frame: the player's own lead's target's model, or nil
--   TargetMark.Read()         for the self-test: { Shown, Target, Colour, Side, At, Apex }

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local HudConfig = require(Shared.Config.Hud)

local TargetMark = {}

local GREY = Color3.fromRGB(150, 150, 150) -- a type with no colour (the dummy's)
local WHITE = Color3.new(1, 1, 1)
local FPS = 60 -- Config.Effects.Mark's frames

local anchor: Part? = nil
local gui: BillboardGui? = nil
local layers: { ImageLabel } = {}
local shownFor: Model? = nil
local since = 0 -- os.clock() when the shown target became the target
local apexAt: Vector3? = nil

local function make(): (Part, BillboardGui)
	local part = Instance.new("Part")
	part.Name = "TargetMark"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.2
	local board = Instance.new("BillboardGui")
	board.Name = "Mark"
	board.Adornee = part
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.ClipsDescendants = false
	board.Enabled = false
	layers = {}
	for index, name in { "Ink", "Light", "Core" } do
		local layer = Instance.new("ImageLabel")
		layer.Name = name
		layer.BackgroundTransparency = 1
		layer.Size = UDim2.fromScale(1, 1)
		layer.ZIndex = index
		layer.ImageTransparency = 1
		layer.Parent = board
		layers[index] = layer
	end
	board.Parent = part
	part.Parent = workspace.CurrentCamera -- this client's own, never the server's
	return part, board
end

-- Half a part's height along the world's up, however it's turned.
local function halfHeight(part: BasePart): number
	local cf, half = part.CFrame, part.Size / 2
	return math.abs(cf.RightVector.Y) * half.X + math.abs(cf.UpVector.Y) * half.Y + math.abs(cf.LookVector.Y) * half.Z
end

-- The target's top: a Shade's highest mask's, else its head's, else its box's.
local function topOf(target: Model): number
	local best = -math.huge
	for _, part in target:GetChildren() do
		if part:IsA("BasePart") and (string.sub(part.Name, 1, 5) == "Mask_" or string.sub(part.Name, 1, 10) == "EliteMask_") then
			best = math.max(best, part.Position.Y + halfHeight(part))
		end
	end
	if best > -math.huge then
		return best
	end
	local head = target:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position.Y + halfHeight(head)
	end
	local box, size = target:GetBoundingBox()
	return box.Position.Y + size.Y / 2
end

local function hide()
	if gui then
		gui.Enabled = false
	end
	shownFor = nil
	apexAt = nil
end

function TargetMark.Step(target: Model?)
	local root = if target then target:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local state = if target then target:GetAttribute("State") else nil
	if not Combat.TargetMark.On or target == nil or root == nil or state == "Down" or state == "Reset" or state == "Home" then
		hide()
		return
	end
	if anchor == nil or anchor.Parent == nil or gui == nil then
		anchor, gui = make()
	end
	local part, board = anchor :: Part, gui :: BillboardGui
	local look = EffectsConfig.Mark
	local pictures = EffectsConfig.Pictures :: { [string]: string }
	local now = os.clock()
	if shownFor ~= target then
		since = now
	end
	local scale = target:GetScale()
	local frames = (now - since) * FPS
	-- the drop: from Drop.From higher, a Back Out over Drop.Frames (dipping past its rest by the overshoot, then home)
	local u = math.clamp(frames / math.max(look.Drop.Frames, 1e-3), 0, 1) - 1
	local back = 1 + (look.Drop.Over + 1) * u * u * u + look.Drop.Over * u * u
	local lift = look.Drop.From * scale * (1 - back)
	if frames >= look.Bob.After then
		local age = (frames - look.Bob.After) / FPS
		lift += look.Bob.Studs * scale * math.sin(2 * math.pi * age / math.max(look.Bob.Seconds, 1e-3))
	end
	local shown = math.clamp(frames / math.max(look.Fade, 1e-3), 0, 1)
	local kind = target:GetAttribute("Type")
	local colour = if type(kind) == "string" then HudConfig.Card.Types[kind] or GREY else GREY
	local ink, light, core = layers[1], layers[2], layers[3]
	ink.Image, light.Image, core.Image = pictures[look.Ink] or "", pictures[look.Light] or "", pictures[look.Core] or ""
	ink.ImageColor3, light.ImageColor3, core.ImageColor3 = look.InkColor, colour, WHITE
	ink.ImageTransparency = 1 - shown * (1 - look.InkTransparency)
	light.ImageTransparency = 1 - shown
	core.ImageTransparency = 1 - shown
	local side = look.Side * scale
	board.Size = UDim2.fromScale(side, side)
	local apex = Vector3.new(root.Position.X, topOf(target) + look.Lift * scale, root.Position.Z)
	part.CFrame = CFrame.new(apex + Vector3.new(0, look.Centre * scale + lift, 0))
	board.Enabled = true
	shownFor = target
	apexAt = apex
end

function TargetMark.Read(): { [string]: any }
	return {
		Shown = gui ~= nil and gui.Enabled,
		Target = shownFor,
		Colour = if layers[2] then layers[2].ImageColor3 else nil,
		Side = if gui then gui.Size.X.Scale else 0,
		At = if anchor then anchor.Position else nil,
		Apex = apexAt,
	}
end

return TargetMark
