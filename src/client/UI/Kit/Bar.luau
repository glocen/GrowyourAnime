--!strict
-- Bar (client kit): a conduit that fills with light, left to right (docs/ui.md, rule 3; AR3, section 2). Its layers, in
-- Modulo's order and numbers (tools/blender/ui_kit.py, `bar`; kit.json's "bar"): the channel and its edge, a thread
-- under 7 points high; then the light, kept a dark rim inside the channel, its front cut on the slant: the glow, the
-- light, its white core, and the bright head at its front. Bars are told apart by place and label as well as colour
-- (handbook/visuals/ui.md, "Don't"), and red is never a bar's colour (AR3's in-use rules). Size is authored pixels.

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Skin = require(script.Parent.Skin)
local Panel = require(script.Parent.Panel)

export type Props = {
	Name: string,
	Size: UDim2, -- in pixels (offsets)
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Parent: Instance?,
	Colour: Color3, -- the light
	Palette: string?,
	LayoutOrder: number?,
}

local Bar = {}

local LIGHT = { "Glow", "Light", "Core", "Head" }

local function light(bar: Frame)
	local share = bar:GetAttribute("Share")
	local fill = if type(share) == "number" then share else 0
	local colour = bar:GetAttribute("Colour") :: Color3
	local p = Panel.Palette(bar)
	local skin = Skin.Of(bar)
	local w, h = bar.Size.X.Offset, bar.Size.Y.Offset
	local rim = math.min(p.Rim or 1, h * 0.2)
	local s = 0.6 * h
	local lx, ly, lh = 1.77 * rim, rim, h - 2 * rim
	local lw = math.min(s + (w - s) * fill - 2.37 * rim, w - 3.53 * rim)
	local k = lh / 8
	local warm = p.Warm ~= nil and colour.B < colour.R -- a warm light on a pale panel: gold at its edges
	local images: { [string]: ImageLabel } = {}
	for _, name in LIGHT do
		local image = skin:FindFirstChild(name) :: ImageLabel?
		if image == nil then
			local made = Instance.new("ImageLabel")
			made.Name = name
			made.BackgroundTransparency = 1
			made.BorderSizePixel = 0
			made.Parent = skin
			image = made
		end
		images[name] = image :: ImageLabel
		;(image :: ImageLabel).Visible = fill > 0
	end
	if fill <= 0 then
		return
	end
	local box: Skin.Options = { X = lx, Y = ly, W = math.max(lw, 1), H = lh, Scale = k }
	local glow = UIKit.Images.BarGlow
	Skin.Set(images.Glow, "BarGlow", { X = lx, Y = ly, W = box.W, H = lh, Scale = math.min(k, HudConfig.Bar.GlowReach / glow.Pad) })
	Skin.Tint(images.Glow, colour)
	images.Glow.ZIndex = 3
	Skin.Set(images.Light, "BarLight", box)
	local warmth = p.Warm
	Skin.Tint(images.Light, if warm and warmth then Color3.new(colour.R * warmth[1], colour.G * warmth[2], colour.B * warmth[3]) else colour)
	images.Light.ZIndex = 4
	Skin.Set(images.Core, "BarCore", box)
	Skin.Tint(images.Core, nil)
	images.Core.ImageTransparency = 1 - (if warm then p.Core else 0.5)
	images.Core.ZIndex = 5
	Skin.Set(images.Head, "BarHead", { X = lx + lw - 20 * k, Y = ly, Scale = k })
	Skin.Tint(images.Head, nil)
	images.Head.ZIndex = 6
end

function Bar.new(props: Props): Frame
	local bar = Instance.new("Frame")
	bar.Name = props.Name
	bar.Size = props.Size
	bar.Position = props.Position or UDim2.new()
	bar.AnchorPoint = props.AnchorPoint or Vector2.zero
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.LayoutOrder = props.LayoutOrder or 0
	bar:SetAttribute("Palette", props.Palette or "Graphite")
	bar:SetAttribute("Colour", props.Colour)
	bar:SetAttribute("Share", 0)
	local p = Panel.Palette(bar)
	local h = props.Size.Y.Offset
	local kind, base = if h < 7 then "Thread" else "Bar", if h < 7 then 4 else 10
	local skin = Skin.Of(bar)
	Skin.Lay(skin, kind .. "Channel", { Name = "Channel", Tint = p.Channel, Scale = h / base, Z = 1 })
	Skin.Lay(skin, kind .. "Edge", { Name = "Edge", Tint = p.Edge, Alpha = 0.9, Scale = h / base, Z = 2 })
	light(bar)
	bar.Parent = props.Parent
	return bar
end

-- Fills `bar` to `share` of its length (0 to 1).
function Bar.Set(bar: Frame, share: number)
	local clamped = math.clamp(if share == share then share else 0, 0, 1)
	if bar:GetAttribute("Share") == clamped and bar:FindFirstChild("NL_Skin") then
		return
	end
	bar:SetAttribute("Share", clamped)
	light(bar)
end

-- Recolours the light.
function Bar.Colour(bar: Frame, colour: Color3)
	if bar:GetAttribute("Colour") == colour then
		return
	end
	bar:SetAttribute("Colour", colour)
	light(bar)
end

return Bar
