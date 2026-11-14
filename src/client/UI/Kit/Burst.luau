--!strict
-- Burst (client kit): a few sparks flung out from a point, slowing and shrinking as they go (TR6;
-- docs/research/vfx-reference.md, "UI effects", DESIGN 1; the handbook: no 2D particle emitter, so they're ImageLabels
-- moved by a script). The kit's Spark, Count of them evenly round with a little jitter, out Reach authored pixels over
-- Seconds, eased out, from full size to nothing. Drawn in Fly's Folder on the HUD layer, so the UI lint never counts one
-- as a piece. Config.Hud.Motion.Burst, read live. With the player's reduced motion on, none (DESIGN 5).
--   Burst.Play(at, colour)   at: a point on the HUD layer, authored pixels (Fly.Middle of a piece)
--   Burst.Sparks()           sparks out now, for tests

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Fly = require(script.Parent.Fly)

type Spark = { Image: ImageLabel, From: Vector2, Way: Vector2, Start: number }

local Burst = {}

local Z = 49 -- under the flying icons, over the HUD's pieces
local sparks: { Spark } = {}
local random = Random.new()

function Burst.Play(at: Vector2, colour: Color3)
	if GuiService.ReducedMotionEnabled then
		return
	end
	local look = HudConfig.Motion.Burst
	local holder = Fly.Holder()
	local turn = random:NextNumber(0, 2 * math.pi)
	local now = os.clock()
	for i = 1, look.Count do
		local angle = turn + 2 * math.pi * (i - 1) / look.Count + random:NextNumber(-0.25, 0.25)
		local image = Instance.new("ImageLabel")
		image.Name = "Spark"
		image.Image = UIKit.Images.Spark.Id
		image.ImageColor3 = colour
		image.BackgroundTransparency = 1
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromOffset(at.X, at.Y)
		image.Size = UDim2.fromOffset(look.Size, look.Size)
		image.Rotation = math.deg(angle)
		image.ZIndex = Z
		image.Parent = holder
		local reach = look.Reach * random:NextNumber(0.75, 1)
		table.insert(sparks, { Image = image, From = at, Way = Vector2.new(math.cos(angle), math.sin(angle)) * reach, Start = now })
	end
end

function Burst.Sparks(): number
	return #sparks
end

RunService.RenderStepped:Connect(function()
	if #sparks == 0 then
		return
	end
	local look = HudConfig.Motion.Burst
	local now = os.clock()
	for i = #sparks, 1, -1 do
		local s = sparks[i]
		local t = if look.Seconds > 0 then (now - s.Start) / look.Seconds else 1
		if t >= 1 or s.Image.Parent == nil then
			s.Image:Destroy()
			table.remove(sparks, i)
			continue
		end
		local at = s.From + s.Way * Hud.Ease(t)
		local size = look.Size * (1 - t)
		s.Image.Position = UDim2.fromOffset(at.X, at.Y)
		s.Image.Size = UDim2.fromOffset(size, size)
		s.Image.ImageTransparency = t * t
	end
end)

return Burst
