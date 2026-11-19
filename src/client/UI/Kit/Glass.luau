--!strict
-- Glass (client kit): Seam's lit glass, the pieces its screens share (research's B, 2026-11-19, 15:04;
-- build/handoff/UI/seam/seam.json; first worn by AR42's stages, laid as tools/blender/stage_seam.py draws them). A cut
-- box is the lit press's sliced images (seam_cut.py: PressFill, PressEdge and PressGlow, drawn with a 5-point cut and a
-- 1-point hairline), laid at cut / 5, so every box keeps the cut corners and its hairline a fifth of them; a light inside
-- it is a white PressFill under a gradient. A disc is a round frame, a bloom the kit's ScreenBloom. One idle loop runs
-- every light that moves (Config.Hud.Equipment.Idle), none with the player's reduced motion on. Sizes are points.
--   Glass.Ground(parent, z, backing?) -> Frame             the screen's ground down it, and its top light; `backing`
--     its top and foot, Equipment's when nil
--   Glass.Panel(parent, name, x, y, w, h, palette, z) -> Frame   the kit's panel (seam.json, panel): PanelFill in the
--     palette's Panel, its sheen across the top, PanelEdge in its Facet lit from above, the light at its top-left corner
--   Glass.Fill(parent, name, x, y, w, h, cut, tint, z, alpha?) -> ImageLabel     a cut box's body
--   Glass.Edge(parent, name, x, y, w, h, cut, colour, top, foot?, z) -> ImageLabel   its hairline, `top` strong at its
--     top falling to `foot` by 0.85 of the way down (lit from above), or `top` all round
--   Glass.Wash(parent, name, x, y, w, h, cut, colour, strength, z) -> ImageLabel  a light inside it, strength(points down)
--   Glass.Glow(parent, name, x, y, w, h, reach, colour, alpha, z) -> ImageLabel   a glow round it, reaching `reach`
--   Glass.Lit(parent, name, x, y, w, h, fill, glow, z, cut?, glowAlpha?) -> Plate  the lit press's plate, its sheen
--     running once a loop
--   Glass.Quiet(parent, name, x, y, w, h, edge, z, cut?, palette?) -> Frame       a quiet plate: the palette's button
--     glass, SeamGlass's when nil
--   Glass.Dress(button, kind, words, why?, dress?)          a bare press's face (Equipment's, AR43): Lit (the one it can
--     do), Quiet, or Off (the well's, faint words), which says `why` on a tap. `dress`: its Palette (SeamGlass's when
--     nil), Under (`why` under its name: an Off press's reason, another's note, in the Soft, a lit one's in the Ink),
--     Mark (the diamond at the words' left, in the Ink: the main action set, Leading), Size (its words', 14 when nil)
--   Glass.Disc(parent, name, cx, cy, r, tint, z, alpha?) -> Frame
--   Glass.Circle(parent, name, cx, cy, r, colour, wide, top, foot?, z) -> Frame   a ring's line, lit from above
--   Glass.Bloom(parent, name, cx, cy, w, h, colour, alpha, z) -> ImageLabel
--   Glass.Mark(parent, name, record, cx, cy, side, colour, z, alpha?) -> ImageLabel  an icon of a Config's own
--   Glass.Label(parent, name, text, size, colour, x, y, w, h, align?, strong?, z) -> TextLabel
--   Glass.Band(width, sigma, peak) -> NumberSequence        a band of light `sigma` points round across `width`
--   Glass.Idle(holder, step)                               step(phase) each frame while holder stands
--   Glass.Ease(holder, seconds, step, style?)               step(0..1, eased) over seconds while holder stands

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Theme = require(script.Parent.Parent.Theme)
local Skin = require(script.Parent.Skin)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)

local Glass = {}

local CUT = 5 -- the press images' cut at scale 1
local REACH, PAD = 7, 21 -- PressGlow's glow and its pad at scale 1
local SEAM = UIKit.Palettes.SeamGlass
local EQUIPMENT = HudConfig.Equipment
local WHITE = Color3.new(1, 1, 1)

export type Tint = Color3 | { Color3 } | ColorSequence
export type Plate = { Glow: ImageLabel, Fill: ImageLabel, Foot: ImageLabel, Sheen: ImageLabel, Edge: ImageLabel }
export type Dress = { Palette: UIKit.Palette?, Under: boolean?, Mark: boolean?, Size: number? }

-- The lit press's plate, down the light's stops, and its glow (Config.Hud.Make.Lit).
local LIT = (function(): ColorSequence
	local points = {}
	for _, stop in HudConfig.Make.Lit.Fill do
		table.insert(points, ColorSequenceKeypoint.new(stop[1] :: number, Color3.fromHex(stop[2] :: string)))
	end
	return ColorSequence.new(points)
end)()
local LIT_GLOW = HudConfig.Make.Lit.Glow

-- A light's strength down a piece `tall` points, as a gradient's transparency: strength(points from the top).
local function down(tall: number, strength: (y: number) -> number): NumberSequence
	local points = {}
	for i = 0, 16 do
		local v = i / 16
		table.insert(points, NumberSequenceKeypoint.new(v, math.clamp(1 - strength(v * tall), 0, 1)))
	end
	return NumberSequence.new(points)
end

local function fade(image: GuiObject, sequence: NumberSequence, rotation: number?): UIGradient
	local gradient = image:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Rotation = rotation or 90
	gradient.Transparency = sequence
	gradient.Parent = image
	return gradient
end

local function box(parent: Instance, image: string, name: string, x: number, y: number, w: number, h: number, cut: number, tint: Tint?, z: number, alpha: number?): ImageLabel
	return Skin.Lay(parent :: GuiObject, image, { Name = name, X = x, Y = y, W = w, H = h, Scale = cut / CUT, Tint = tint, Z = z, Alpha = alpha })
end

function Glass.Band(width: number, sigma: number, peak: number): NumberSequence
	local half = sigma / math.max(width, 1)
	local spots = { 0, 1 }
	for k = -6, 6 do
		local v = 0.5 + k * 0.4 * half
		if v > 1e-3 and v < 1 - 1e-3 then
			table.insert(spots, v)
		end
	end
	table.sort(spots)
	local points = {}
	local last = -1
	for _, v in spots do
		if v - last > 1e-4 then
			local d = (v - 0.5) / half
			table.insert(points, NumberSequenceKeypoint.new(v, math.clamp(1 - peak * math.exp(-d * d), 0, 1)))
			last = v
		end
	end
	return NumberSequence.new(points)
end

function Glass.Ground(parent: Instance, z: number, backing: { Color3 }?): Frame
	local ground = Instance.new("Frame")
	ground.Name = "Ground"
	ground.BorderSizePixel = 0
	ground.BackgroundColor3 = WHITE
	ground.Size = UDim2.fromScale(1, 1)
	ground.ZIndex = z
	local tint = Instance.new("UIGradient")
	tint.Rotation = 90
	local ramp = backing or EQUIPMENT.Backing
	tint.Color = ColorSequence.new(ramp[1], ramp[2])
	tint.Parent = ground
	local T = EQUIPMENT.TopLight
	local top = Instance.new("Frame")
	top.Name = "TopLight"
	top.BorderSizePixel = 0
	top.BackgroundColor3 = SEAM.Glint
	top.Size = UDim2.new(1, 0, 0, T.Height)
	top.ZIndex = z
	fade(top, down(T.Height, function(y: number): number
		return T.Strength * math.exp(-y / T.Fall)
	end))
	top.Parent = ground
	ground.Parent = parent
	return ground
end

function Glass.Fill(parent: Instance, name: string, x: number, y: number, w: number, h: number, cut: number, tint: Tint, z: number, alpha: number?): ImageLabel
	return box(parent, "PressFill", name, x, y, w, h, cut, tint, z, alpha)
end

function Glass.Edge(parent: Instance, name: string, x: number, y: number, w: number, h: number, cut: number, colour: Color3, top: number, foot: number?, z: number): ImageLabel
	local edge = box(parent, "PressEdge", name, x, y, w, h, cut, colour, z)
	if foot and foot ~= top then
		fade(edge, down(h, function(at: number): number
			return foot + (top - foot) * math.clamp(1 - at / (h * 0.85), 0, 1)
		end))
	else
		edge.ImageTransparency = 1 - top
	end
	return edge
end

function Glass.Wash(parent: Instance, name: string, x: number, y: number, w: number, h: number, cut: number, colour: Color3, strength: (y: number) -> number, z: number): ImageLabel
	local wash = box(parent, "PressFill", name, x, y, w, h, cut, colour, z)
	fade(wash, down(h, strength))
	return wash
end

function Glass.Glow(parent: Instance, name: string, x: number, y: number, w: number, h: number, reach: number, colour: Color3, alpha: number, z: number): ImageLabel
	local s = reach / REACH
	local pad = PAD * s
	return Skin.Lay(parent :: GuiObject, "PressGlow", { Name = name, X = x - pad, Y = y - pad, W = w + 2 * pad, H = h + 2 * pad, Scale = s, Tint = colour, Z = z, Alpha = alpha })
end

-- A lit plate's sheen: a white band across it once a loop (seam.json, press.sheen), leaning half a point left a point
-- down; at rest, off the plate.
local function sheen(parent: Instance, name: string, x: number, y: number, w: number, h: number, cut: number, z: number): ImageLabel
	local band = box(parent, "PressFill", name, x, y, w, h, cut, WHITE, z)
	local gradient = fade(band, Glass.Band(w, 6, 0.75), 27)
	gradient.Offset = Vector2.new(-2, 0)
	Glass.Idle(band, function(phase: number)
		local at = -30 + (w + 60) * phase
		gradient.Offset = Vector2.new(at / math.max(w, 1) - 0.5, 0)
	end)
	return band
end

function Glass.Lit(parent: Instance, name: string, x: number, y: number, w: number, h: number, fill: Tint, glow: Color3, z: number, cut: number?, glowAlpha: number?): Plate
	local c = cut or 5
	local foot = if typeof(fill) == "table" then (fill :: { Color3 })[2] elseif typeof(fill) == "ColorSequence" then (fill :: ColorSequence).Keypoints[#(fill :: ColorSequence).Keypoints].Value else fill :: Color3
	return {
		Glow = Glass.Glow(parent, `{name}Glow`, x, y, w, h, 7, glow, glowAlpha or 0.45, z),
		Fill = Glass.Fill(parent, `{name}Fill`, x, y, w, h, c, fill, z + 1),
		Foot = Glass.Wash(parent, `{name}Foot`, x, y, w, h, c, foot, function(at: number): number
			return 0.35 * math.clamp(at / h - 0.4, 0, 1)
		end, z + 2),
		Sheen = sheen(parent, `{name}Sheen`, x, y, w, h, c, z + 3),
		Edge = Glass.Edge(parent, `{name}Edge`, x, y, w, h, c, WHITE, 0.9, nil, z + 4),
	}
end

function Glass.Quiet(parent: Instance, name: string, x: number, y: number, w: number, h: number, edge: Color3, z: number, cut: number?, palette: UIKit.Palette?): Frame
	local c = cut or 5
	local p = palette or SEAM
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = z
	Glass.Fill(holder, "Fill", x, y, w, h, c, p.Button, z)
	Glass.Wash(holder, "Sheen", x, y, w, h, c, p.Glint, function(at: number): number
		return 0.12 * math.exp(-at / 9)
	end, z + 1)
	Glass.Edge(holder, "Edge", x, y, w, h, c, edge, 0.9, 0.45, z + 2)
	holder.Parent = parent
	return holder
end

function Glass.Panel(parent: Instance, name: string, x: number, y: number, w: number, h: number, palette: UIKit.Palette, z: number): Frame
	local P = EQUIPMENT.Panel
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(w, h)
	frame.ZIndex = z
	frame.Parent = parent
	Skin.Lay(frame, "PanelFill", { Name = "Fill", Tint = palette.Panel, Z = z })
	Skin.Lay(frame, "PanelSheen", { Name = "Sheen", W = w, H = 96, Tint = palette.Glint, Alpha = 1 - P.Sheen, Z = z + 1 })
	local edge = Skin.Lay(frame, "PanelEdge", { Name = "Edge", Tint = palette.Facet, Z = z + 2 })
	local lit = Instance.new("UIGradient")
	lit.Rotation = 90
	lit.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, P.Edge[1]),
		NumberSequenceKeypoint.new(0.85, P.Edge[2]),
		NumberSequenceKeypoint.new(1, P.Edge[2]),
	})
	lit.Parent = edge
	Skin.Lay(frame, "PanelCornerGlint", { Name = "CornerGlint", Tint = palette.Glint, Alpha = 1 - P.Glint, Z = z + 3 })
	return frame
end

function Glass.Dress(button: TextButton, kind: string, words: string, why: string?, dress: Dress?)
	local p = (dress and dress.Palette) or SEAM
	local size = (dress and dress.Size) or 14
	local skin = Skin.Of(button)
	local old = skin:FindFirstChild("Face")
	if old then
		old:Destroy()
	end
	local face = Instance.new("Frame")
	face.Name = "Face"
	face.BackgroundTransparency = 1
	face.Size = UDim2.fromScale(1, 1)
	face.Parent = skin
	local w, h = button.Size.X.Offset, button.Size.Y.Offset
	if kind == "Lit" then
		Glass.Lit(face, "Plate", 0, 0, w, h, LIT, LIT_GLOW, 1)
	elseif kind == "Quiet" then
		Glass.Quiet(face, "Plate", 0, 0, w, h, p.Facet, 1, nil, p)
	else
		Glass.Fill(face, "Fill", 0, 0, w, h, 5, p.Well, 1)
		Glass.Edge(face, "Edge", 0, 0, w, h, 5, p.Edge, 0.9, nil, 2)
	end
	local ink = p.Ink or SEAM.Ink :: Color3
	local colour = if kind == "Lit" then ink elseif kind == "Quiet" then p.Text else p.Faint
	-- Under: `why` in a line under the words, an Off press's reason or another's note (Station's bay), the kit's own rule
	-- (docs/ui.md, rule 4).
	local under = why ~= nil and dress ~= nil and dress.Under == true
	local rise = if under then -8 else 0
	local label = Glass.Label(face, "Words", words, size, colour, 0, rise, w, h, nil, true, 7)
	if dress and dress.Mark then -- the diamond and the words centred together
		local mark = HudConfig.Make.Images.SeamMark
		local side, gap = HudConfig.Make.Mark.Side, HudConfig.Make.Mark.Shift
		local wide = Text.Wide(label, words)
		local left = (w - (side + gap + wide)) / 2
		label.Position = UDim2.fromOffset((side + gap) / 2, rise)
		Glass.Mark(face, "Mark", mark, left + side / 2, h / 2 + rise, side, colour, 8)
	end
	if under then
		Glass.Label(face, "Why", why :: string, Theme.Text.Caption, if kind == "Lit" then ink else p.Soft, 0, 9, w, h, nil, false, 7)
	end
	button:SetAttribute("Dress", kind)
	button:SetAttribute("Words", words)
	Button.Set(button, { Disabled = if kind == "Off" then why or "Not now" else false })
end

function Glass.Disc(parent: Instance, name: string, cx: number, cy: number, r: number, tint: Tint, z: number, alpha: number?): Frame
	local disc = Instance.new("Frame")
	disc.Name = name
	disc.BorderSizePixel = 0
	disc.Size = UDim2.fromOffset(2 * r, 2 * r)
	disc.Position = UDim2.fromOffset(cx - r, cy - r)
	disc.BackgroundTransparency = 1 - (alpha or 1)
	disc.ZIndex = z
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = disc
	if typeof(tint) == "Color3" then
		disc.BackgroundColor3 = tint
	else
		disc.BackgroundColor3 = WHITE
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Color = if typeof(tint) == "ColorSequence" then tint else ColorSequence.new((tint :: { Color3 })[1], (tint :: { Color3 })[2])
		gradient.Parent = disc
	end
	disc.Parent = parent
	return disc
end

function Glass.Circle(parent: Instance, name: string, cx: number, cy: number, r: number, colour: Color3, wide: number, top: number, foot: number?, z: number): Frame
	local ring = Glass.Disc(parent, name, cx, cy, r, colour, z, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = colour
	stroke.Thickness = wide
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if foot and foot ~= top then
		fade(stroke :: any, down(2 * r, function(at: number): number
			return foot + (top - foot) * (1 - at / (2 * r))
		end))
	else
		stroke.Transparency = 1 - top
	end
	stroke.Parent = ring
	return ring
end

function Glass.Bloom(parent: Instance, name: string, cx: number, cy: number, w: number, h: number, colour: Color3, alpha: number, z: number): ImageLabel
	local bloom = Skin.Lay(parent :: GuiObject, "ScreenBloom", { Name = name, Tint = colour, Alpha = alpha, Z = z })
	bloom.Size = UDim2.fromOffset(w, h)
	bloom.Position = UDim2.fromOffset(cx - w / 2, cy - h / 2)
	return bloom
end

function Glass.Mark(parent: Instance, name: string, record: UIKit.Image, cx: number, cy: number, side: number, colour: Color3, z: number, alpha: number?): ImageLabel
	local mark = Instance.new("ImageLabel")
	mark.Name = name
	mark.BackgroundTransparency = 1
	mark.Image = record.Id
	mark.ImageColor3 = colour
	mark.ImageTransparency = 1 - (alpha or 1)
	local tall = side * record.Points.Y / record.Points.X
	mark.Size = UDim2.fromOffset(side, tall)
	mark.Position = UDim2.fromOffset(cx - side / 2, cy - tall / 2)
	mark.ZIndex = z
	mark.Parent = parent
	return mark
end

function Glass.Label(parent: Instance, name: string, text: string, size: number, colour: Color3, x: number, y: number, w: number, h: number, align: Enum.TextXAlignment?, strong: boolean?, z: number): TextLabel
	local label = Text.new({
		Name = name,
		Size = size,
		Font = if strong then Theme.Font.Strong else Theme.Font.Body,
		Colour = colour,
		Align = align or Enum.TextXAlignment.Center,
		Box = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		Parent = parent,
	})
	label.Text = text
	label.ZIndex = z
	return label
end

-- The idle loop: one RenderStepped for every holder's step, while it stands.
local idlers: { [Instance]: (phase: number) -> () } = {}
local looping: RBXScriptConnection? = nil

function Glass.Idle(holder: Instance, step: (phase: number) -> ())
	if GuiService.ReducedMotionEnabled then
		return
	end
	idlers[holder] = step
	if looping then
		return
	end
	looping = RunService.RenderStepped:Connect(function()
		local loop = EQUIPMENT.Idle
		local phase = (os.clock() % loop) / loop
		for each, run in idlers do
			if each.Parent == nil then
				idlers[each] = nil
			else
				run(phase)
			end
		end
		if next(idlers) == nil and looping then
			looping:Disconnect()
			looping = nil
		end
	end)
end

-- A beat: step(u) each frame for `seconds`, u eased by `style` (Quart out unless named), then step(1).
function Glass.Ease(holder: Instance, seconds: number, step: (u: number) -> (), style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	if seconds <= 0 or GuiService.ReducedMotionEnabled then
		step(1)
		return
	end
	local began = os.clock()
	local easing, way = style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out
	local beat: RBXScriptConnection
	beat = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - began) / seconds, 0, 1)
		if holder.Parent == nil then
			beat:Disconnect()
			return
		end
		step(TweenService:GetValue(t, easing, way))
		if t >= 1 then
			beat:Disconnect()
		end
	end)
end

-- The kit's images Glass lays, with a screen's own, made ready ahead. Fetched isn't ready: measured, an image a
-- screen draws for the first time still stands empty for about 0.3 s, fetched or not (AR42's install, the picker's
-- first opening: its words alone until 0.4 s), as the Figure found for meshes. So each is drawn once, two points wide
-- and almost clear in the corner, until it says it's loaded, then taken away. An id given as a string fails to fetch
-- (AssetFetchStatus Failure), so each rides its label.
local warm: ScreenGui? = nil
function Glass.Preload(own: { UIKit.Image })
	local records: { UIKit.Image } = {}
	for _, name in { "PressFill", "PressEdge", "PressGlow", "ScreenBloom" } do
		local record = UIKit.Images[name]
		if record then
			table.insert(records, record)
		end
	end
	table.move(own, 1, #own, #records + 1, records)
	local player = Players.LocalPlayer
	if not warm or warm.Parent == nil then
		local gui = Instance.new("ScreenGui")
		gui.Name = "NL_Warm"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = -1
		gui.Parent = player:WaitForChild("PlayerGui")
		warm = gui
	end
	local labels: { ImageLabel } = {}
	for _, record in records do
		local label = Instance.new("ImageLabel")
		label.Name = "Warm"
		label.BackgroundTransparency = 1
		label.Image = record.Id
		label.ImageTransparency = 0.98
		label.Size = UDim2.fromOffset(2, 2)
		label.Parent = warm
		table.insert(labels, label)
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(labels :: { any })
		end)
		local stop = os.clock() + 10
		repeat
			local ready = true
			for _, label in labels do
				ready = ready and label.IsLoaded
			end
			task.wait(0.1)
		until ready or os.clock() > stop
		for _, label in labels do
			label:Destroy()
		end
		local gui = warm
		if gui and #gui:GetChildren() == 0 then
			gui:Destroy()
			warm = nil
		end
	end)
end

return Glass
