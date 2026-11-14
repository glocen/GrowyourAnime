--!strict
-- Shine (client kit): a light band sweeping once across a piece, only on what's rare (TR6; docs/research/vfx-reference.md,
-- "UI effects", DESIGN 3 and 5). A UIGradient in the piece's own colour with a white band in its middle, turned Angle
-- degrees, its Offset moved across over Seconds, eased in and out (handbook/visuals/ui.md, "UI effects: engine facts":
-- a gradient moves by Offset and Rotation only). The piece's own colour goes white and its gradient carries the colour,
-- so outside the band it looks as it did. Config.Hud.Motion.Shine, read live. With the player's reduced motion on, no
-- sweep (DESIGN 5).
--   Shine.Lay(object, colour)   a gradient on `object` (a TextLabel, an ImageLabel, a Frame or a UIStroke) in `colour`,
--                               its band off the piece; the object's own colour set to white. Returns the gradient.
--   Shine.Play(gradient, delay?) one sweep, Delay plus `delay` from now
--   Shine.Sweeping()            sweeps under way now, for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)

type Sweep = { Gradient: UIGradient, Start: number }

local Shine = {}

local WHITE = Color3.new(1, 1, 1)
local sweeping: { Sweep } = {}

function Shine.Lay(object: Instance, colour: Color3): UIGradient
	local look = HudConfig.Motion.Shine
	local half = look.Width / 2
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Shine"
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colour),
		ColorSequenceKeypoint.new(0.5 - half, colour),
		ColorSequenceKeypoint.new(0.5, WHITE),
		ColorSequenceKeypoint.new(0.5 + half, colour),
		ColorSequenceKeypoint.new(1, colour),
	})
	gradient.Rotation = look.Angle
	gradient.Offset = Vector2.new(-1, 0)
	if object:IsA("TextLabel") then
		object.TextColor3 = WHITE
	elseif object:IsA("ImageLabel") then
		object.ImageColor3 = WHITE
	elseif object:IsA("UIStroke") then
		object.Color = WHITE
	elseif object:IsA("GuiObject") then
		object.BackgroundColor3 = WHITE
	end
	gradient.Parent = object
	return gradient
end

function Shine.Play(gradient: UIGradient, delay: number?)
	if GuiService.ReducedMotionEnabled then
		return
	end
	table.insert(sweeping, { Gradient = gradient, Start = os.clock() + HudConfig.Motion.Shine.Delay + (delay or 0) })
end

function Shine.Sweeping(): number
	return #sweeping
end

RunService.RenderStepped:Connect(function()
	if #sweeping == 0 then
		return
	end
	local seconds = HudConfig.Motion.Shine.Seconds
	local now = os.clock()
	for i = #sweeping, 1, -1 do
		local s = sweeping[i]
		local t = if seconds > 0 then (now - s.Start) / seconds else 1
		if t >= 1 or s.Gradient.Parent == nil then
			s.Gradient.Offset = Vector2.new(1, 0)
			table.remove(sweeping, i)
		elseif t >= 0 then
			local u = t * t * (3 - 2 * t) -- eased in and out
			s.Gradient.Offset = Vector2.new(-1 + 2 * u, 0)
		end
	end
end)

return Shine
