--!strict
-- TargetRing (client): a thin ring at the feet of the player's own lead's target, in the target's type's colour
-- (TR69 A; Config.Combat.Ring, the colours Config.Hud.Card.Types). A grey block: one flat CylinderHandleAdornment with
-- a hole, on an unseen anchored part this client moves each frame. Scintilla gives it its look later. Hidden with no
-- target, or once the target is down or walking home.
--   TargetRing.Step(target)   each frame: the player's own lead's target's model, or nil
--   TargetRing.Read()         for the self-test: { Shown, Target, Colour, Radius, At }

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)

local TargetRing = {}

local GREY = Color3.fromRGB(150, 150, 150) -- a type with no colour (the dummy's)
local FLAT = CFrame.Angles(math.rad(90), 0, 0) -- a handle cylinder's height runs along Z: this lays it on the floor
local REACH = 12 -- studs down from the target's root the floor is looked for

local anchor: Part? = nil
local band: CylinderHandleAdornment? = nil
local shownFor: Model? = nil
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function make(): (Part, CylinderHandleAdornment)
	local part = Instance.new("Part")
	part.Name = "TargetRing"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.2
	local ring = Instance.new("CylinderHandleAdornment")
	ring.Name = "Band"
	ring.Adornee = part
	ring.CFrame = FLAT
	ring.Height = 0.03
	ring.AlwaysOnTop = false
	ring.Parent = part
	part.Parent = workspace.CurrentCamera -- this client's own, never the server's
	return part, ring
end

local function hide()
	if band then
		band.Visible = false
	end
	shownFor = nil
end

function TargetRing.Step(target: Model?)
	local look = Combat.Ring
	local root = if target then target:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	local state = if target then target:GetAttribute("State") else nil
	if not look.On or target == nil or root == nil or state == "Down" or state == "Reset" or state == "Home" then
		hide()
		return
	end
	if anchor == nil or anchor.Parent == nil or band == nil then
		anchor, band = make()
	end
	local part, ring = anchor :: Part, band :: CylinderHandleAdornment
	-- the floor under it, every fighter and this client's own effects left out
	local fighters = workspace:FindFirstChild("Fighters")
	params.FilterDescendantsInstances = { fighters or target, workspace.CurrentCamera }
	local found = workspace:Raycast(root.Position, Vector3.new(0, -REACH, 0), params)
	local floor = if found then found.Position.Y else root.Position.Y - 3
	local radius = look.Radius * target:GetScale()
	local kind = target:GetAttribute("Type")
	ring.Radius = radius
	ring.InnerRadius = math.max(0, radius - look.Width)
	ring.Color3 = if type(kind) == "string" then HudConfig.Card.Types[kind] or GREY else GREY
	ring.Transparency = look.Transparency
	part.CFrame = CFrame.new(root.Position.X, floor + look.Lift, root.Position.Z)
	ring.Visible = true
	shownFor = target
end

function TargetRing.Read(): { [string]: any }
	return {
		Shown = band ~= nil and band.Visible,
		Target = shownFor,
		Colour = if band then band.Color3 else nil,
		Radius = if band then band.Radius else 0,
		At = if anchor then anchor.Position else nil,
	}
end

return TargetRing
