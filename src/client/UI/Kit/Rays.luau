--!strict
-- Rays (client kit): a sunburst behind a reward of rung 5 and up (TR6; docs/research/vfx-reference.md, "UI effects",
-- DESIGN 3). The effects kit's soft round light (Config.FxKit's fx_glow) cut into rays by a Conical gradient repeating
-- round it (handbook/visuals/ui.md, "UI effects: engine facts": TileMode Repeat, a Scale below 1), turning slowly by its
-- Rotation only. It comes in from 0.9 of its size (never from nothing) and grows to 1.1, at its fullest early and gone
-- by its end (Rules.Hud.Pop). Config.Hud.Motion.Rays, read live. With the player's reduced motion on, it fades without
-- turning or growing (DESIGN 5).
--   Rays.Play(holder, centre, across, colour, delay?)   behind the holder's other children (ZIndex 0): centred at `centre`
--                                                       in it, `across` authored pixels; it goes by itself
--   Rays.Showing()                                      sunbursts showing now, for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)
local FxKit = require(Shared.Config.FxKit)

type Burst = { Image: ImageLabel, Scale: UIScale, Gradient: UIGradient, Start: number }

local Rays = {}

local showing: { Burst } = {}

function Rays.Play(holder: GuiObject, centre: Vector2, across: number, colour: Color3, delay: number?)
	local look = HudConfig.Motion.Rays
	local image = Instance.new("ImageLabel")
	image.Name = "Rays"
	image.Image = FxKit.Images.fx_glow.Id
	image.ImageColor3 = colour
	image.ImageTransparency = 1
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromOffset(centre.X, centre.Y)
	image.Size = UDim2.fromOffset(across, across)
	image.ZIndex = 0
	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = image
	-- One ray a tile, bright in its middle and clear at its sides; Count tiles round.
	local cut = Instance.new("UIGradient")
	cut.Type = Enum.GradientType.Conical
	cut.TileMode = Enum.GradientTileMode.Repeat
	cut.Scale = 1 / math.max(look.Count, 1)
	cut.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	cut.Parent = image
	image.Parent = holder
	table.insert(showing, { Image = image, Scale = scale, Gradient = cut, Start = os.clock() + (delay or 0) })
end

function Rays.Showing(): number
	return #showing
end

RunService.RenderStepped:Connect(function(dt: number)
	if #showing == 0 then
		return
	end
	local look = HudConfig.Motion.Rays
	local still = GuiService.ReducedMotionEnabled
	local now = os.clock()
	for i = #showing, 1, -1 do
		local b = showing[i]
		local t = (now - b.Start) / look.Seconds
		if t >= 1 or b.Image.Parent == nil then
			b.Image:Destroy()
			table.remove(showing, i)
			continue
		end
		if t < 0 then
			continue
		end
		b.Image.ImageTransparency = 1 - look.Alpha * Hud.Pop(t, look.Peak)
		if not still then
			b.Scale.Scale = 0.9 + 0.2 * Hud.Ease(t)
			b.Gradient.Rotation = (b.Gradient.Rotation + look.Spin * dt) % 360
		end
	end
end)

return Rays
