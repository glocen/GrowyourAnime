--!strict
-- The seam's skin on the Voidkin screen (TR28; the director's word of 2026-11-17, 02:40: "the inventory ... with that color
-- style not the old yellow brown"; Modulo's sheet and its notes, AR18): violet-black grounds, edges of pale light, and
-- what's chosen drawn in that light. Its colours are UIKit.Palettes.Seam; its numbers are Config.Hud.Seam. It draws the
-- three things the kit doesn't: a lit edge, the chosen ring, and a plate of light with its glow.

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local Skin = require(script.Parent.Parent.Kit.Skin)

local Seam = {}

local K = UIKit.Palettes.Seam
local S = HudConfig.Seam
local LIGHT = K.Light :: Color3

Seam.Palette = "Seam" -- the kit palette's name: the screen's cover and Back, its panels and buttons
Seam.Lit = "SeamLit" -- a plate of light's palette: the one action (Equip)

-- The screen's colours, under the theme's names where the Overview used the theme's graphite, so each word keeps its role.
Seam.Colour = {
	Text = K.Text,
	TextDim = K.Soft,
	Disabled = K.Faint,
	Line = K.Edge,
	Plate = K.Button[2],
	PlateHigh = K.Well,
	Backing = K.Backing :: Color3,
	Channel = K.Channel,
	Primary = LIGHT,
	Heal = Theme.Colour.Heal,
}

Seam.Light = LIGHT
Seam.Ink = K.Ink :: Color3
Seam.Glint = K.Glint
Seam.Facet = K.Facet
Seam.Panel = K.Panel
Seam.Card = K.Card :: { Color3 }
Seam.Alpha = K.Alpha
Seam.Well = { K.Well, S.WellFoot }
Seam.Button = K.Button
Seam.Ground = K.Ground

-- What a colour of the panel's top reads as over the backing: a veil that fades into the room must match it.
Seam.Room = K.Panel[1]:Lerp(K.Backing :: Color3, 1 - K.Alpha)

function Seam.Ramp(on: Instance, colours: { Color3 }, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colours[1], colours[2])
	gradient.Rotation = rotation or 90
	gradient.Parent = on
	return gradient
end

-- How strong an edge is along it, as a UIGradient's transparency: full at `mid`, falling to `floor` at its ends,
-- times `alpha`. Fifteen samples hold the curve (a sequence takes twenty at most); a narrow peak (the page rail's line,
-- AR29) takes its samples round the peak, and the ends.
local function along(mid: number, spread: number, floor: number, alpha: number): NumberSequence
	local function at(v: number): NumberSequenceKeypoint
		local strength = floor + (1 - floor) * math.exp(-((v - mid) / math.max(spread, 1e-3)) ^ 2)
		return NumberSequenceKeypoint.new(v, math.clamp(1 - alpha * strength, 0, 1))
	end
	local points = {}
	if spread >= 0.25 then
		for i = 0, 14 do
			table.insert(points, at(i / 14))
		end
		return NumberSequence.new(points)
	end
	local spots = { 0, 1 }
	for k = -8, 8 do
		local v = mid + k * spread * 0.3
		if v > 1e-3 and v < 1 - 1e-3 then
			table.insert(spots, v)
		end
	end
	table.sort(spots)
	for _, v in spots do
		table.insert(points, at(v))
	end
	return NumberSequence.new(points)
end

export type EdgeLook = { Spread: number, Floor: number, Strength: number }
export type Bands = { Line: number, Glow: { { Wide: number, Alpha: number } } }

-- A line `line` wide with a glow reaching `reach` each side at `alpha`, Modulo's falloff (alpha * e^-(d/reach)^1.4, d
-- from the line's side, in tools/blender/voidkin_chrome.py), out to three reaches where it's spent (AR29, B). Drawn as
-- nested bands of Light, a unit apart or more and sixteen at most, each band's alpha such that where they overlap they
-- make the falloff at the middle of each ring: steps too fine to see, where two bands showed as grey slabs.
function Seam.Bands(line: number, reach: number, alpha: number): Bands
	local far = 3 * reach
	local rings = math.clamp(math.round(far), 2, 16)
	local step = far / rings
	local want: { number } = {}
	for ring = 1, rings do
		want[ring] = alpha * math.exp(-(((ring - 0.5) * step / reach) ^ 1.4))
	end
	local glow: { { Wide: number, Alpha: number } } = {}
	for ring = rings, 1, -1 do -- outermost first, under the rest
		local beyond = want[ring + 1] or 0
		table.insert(glow, { Wide = line + 2 * ring * step, Alpha = 1 - (1 - want[ring]) / (1 - beyond) })
	end
	return { Line = line, Glow = glow }
end

-- Roblox keeps a UDim's offset whole, cutting toward nought (0.85 becomes 0, 2.7 becomes 2), so B's points are made
-- whole before they become one: a place to the nearest unit (`Whole`), a line's width or a size the same but never under
-- one (`Thin`), so a hairline of 0.85 still draws.
function Seam.Whole(n: number): number
	return math.round(n)
end

function Seam.Thin(n: number): number
	return if n > 0 then math.max(1, math.round(n)) else 0
end

-- A lit edge `length` long from (x, y) along its axis, down when `vertical`: its glow's bands, then its line on top,
-- each a frame of Light whose gradient carries the strength along it. `mid`: where it's strongest, a share of its
-- length (its middle when nil). `bands`: its line's width and its glow's (Config.Hud.Seam.Edge's when nil). The frame
-- holds no taps.
function Seam.Edge(parent: Instance, name: string, x: number, y: number, length: number, vertical: boolean, look: EdgeLook, mid: number?, bands: Bands?): Frame
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.Active = false
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Position = UDim2.fromOffset(Seam.Whole(x), Seam.Whole(y))
	holder.Size = if vertical then UDim2.fromOffset(0, Seam.Whole(length)) else UDim2.fromOffset(Seam.Whole(length), 0)
	holder:SetAttribute("Seam", true)
	holder.Parent = parent
	local centre = mid or 0.5
	local long = math.max(Seam.Whole(length), 1)
	-- A band `beyond` past each end too, its ends round, when it's a ring of glow: every point of it as far from the
	-- line as the sheet's falloff measures (the distance to the line, so a short line glows as a halo, not a slab). Its
	-- strength along it is the line's, moved for its longer length.
	local function band(bandName: string, wide: number, beyond: number, alpha: number, z: number)
		local made = Instance.new("Frame")
		made.Name = bandName
		made.Active = false
		made.BorderSizePixel = 0
		made.BackgroundColor3 = LIGHT
		made.AnchorPoint = if vertical then Vector2.new(0.5, 0) else Vector2.new(0, 0.5)
		made.Position = if vertical then UDim2.fromOffset(0, -beyond) else UDim2.fromOffset(-beyond, 0)
		made.Size = if vertical then UDim2.new(0, Seam.Thin(wide), 1, 2 * beyond) else UDim2.new(1, 2 * beyond, 0, Seam.Thin(wide))
		made.ZIndex = z
		made.Parent = holder
		if beyond > 0 then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = made
		end
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = if vertical then 90 else 0
		local whole = long + 2 * beyond
		gradient.Transparency = along((centre * long + beyond) / whole, look.Spread * long / whole, look.Floor, alpha * look.Strength)
		gradient.Parent = made
	end
	local widths: Bands = bands or S.Edge
	for index, glow in widths.Glow do
		band(`Glow{index}`, glow.Wide, if bands then Seam.Whole((glow.Wide - widths.Line) / 2) else 0, glow.Alpha, 1)
	end
	band("Line", widths.Line, 0, 1, 2)
	return holder
end

local function outline(parent: Instance, name: string, out: number, radius: number, colour: Color3, thickness: number, transparency: number, z: number): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.Active = false
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.fromScale(0.5, 0.5)
	made.Size = UDim2.new(1, 2 * out, 1, 2 * out)
	made.ZIndex = z
	made.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = made
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = colour
	stroke.Thickness = thickness
	stroke.Transparency = transparency
	stroke.Parent = made
	return made
end

-- The chosen ring round a cell `side` across (research's fix of 08:01, Modulo's sheet of 08:13): a dark moat, then a
-- ring of Light with its glow outward, at the sheet's sizes for a 48-point cell scaled to this one. It lies in `on`,
-- over its layers; the caller raises `on` over its neighbours while the ring shows (Seam.Raise).
function Seam.Ring(on: GuiObject, name: string, side: number, shown: boolean): Frame
	local r = S.Ring
	local z = side / r.Cell
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.Active = false
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 20
	holder.Visible = shown
	holder:SetAttribute("Seam", true)
	holder.Parent = on
	local corner = r.Corner * z
	outline(holder, "Moat", r.Moat.From * z, corner + r.Moat.From * z, K.Channel, (r.Moat.To - r.Moat.From) * z, 1 - r.Moat.Alpha, 1)
	local rim = r.Out + r.Wide
	for index, glow in r.Glow do
		outline(holder, `Glow{index}`, rim * z, corner + rim * z, LIGHT, glow.Wide * z, 1 - glow.Alpha, 2)
	end
	outline(holder, "Light", r.Out * z, corner + r.Out * z, LIGHT, r.Wide * z, 0, 3)
	return holder
end

-- How far a ring reaches past its cell, in pixels: its light, and its glow.
function Seam.Reach(side: number): (number, number)
	local r = S.Ring
	local z = side / r.Cell
	local glow = 0
	for _, band in r.Glow do
		glow = math.max(glow, band.Wide)
	end
	return (r.Out + r.Wide) * z, (r.Out + r.Wide + glow) * z
end

-- A ring's cell drawn over its neighbours while its ring shows, and back among them after.
function Seam.Raise(on: GuiObject, up: boolean)
	on.ZIndex = if up then 2 else 1
end

-- A plate of light (the lit chip; Equip's plate is the kit's button in Seam.Lit): white falling to the seam's Light,
-- its glow round it, `radius` its corners'.
function Seam.Plate(on: GuiObject, radius: number)
	if on:IsA("Frame") then
		on.BackgroundColor3 = Color3.new(1, 1, 1)
		on.BackgroundTransparency = 0
		Seam.Ramp(on, { Color3.new(1, 1, 1), LIGHT })
	end
	Seam.Glow(on, radius)
end

-- A kit button's plate of light (Seam.Lit) gets its glow: the kit's ring glow, which follows its cut corners, in the
-- seam's Light, under its fill.
function Seam.ButtonGlow(button: GuiObject): ImageLabel
	return Skin.Lay(Skin.Of(button), "ButtonRingGlow", { Name = "Glow", Tint = LIGHT, Alpha = S.Lit.Button, Z = 2 })
end

-- A plate of light's glow: stepped bands of Light round `on`, outside it.
function Seam.Glow(on: GuiObject, radius: number): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Glow"
	holder.Active = false
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 0
	holder:SetAttribute("Seam", true)
	holder.Parent = on
	for index, glow in S.Lit.Glow do
		outline(holder, `Glow{index}`, 0, radius, LIGHT, glow.Wide, 1 - glow.Alpha, index)
	end
	return holder
end

return Seam
