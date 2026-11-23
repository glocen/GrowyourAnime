--!strict
-- Rail (client UI kit): the page rail, one rail in two screens. It is the Equipment screen's (AR43; seam.json, rail), and
-- the Voidkin screen's with its four pages (AR49, research's call of 2026-11-20, 00:12). A disc for each page down a
-- column, the open one grown and lit with its comet turning, each page's word under its disc, a line between them in
-- pieces and a light running down it once a loop. Its look is Config.Hud.Equipment.Rail's in SeamGlass. A screen gives
-- the places, laid in its own points, and its discs' radii where it has less room; everything else is the same.
--   Rail.new(parent, spec, open) -> rail   its holder ("Rail") in `parent`, a kit button for each page ("Rail<page>")
--   Rail.Paint(rail, open, last?)          the faces and words with `open` lit; `last` grows the switch from it
--   Rail.Idle(rail, phase)                 the comet's turn and the runner's run, 0 to 1 a loop
--   Rail.Pieces(spec, open)                the line's pieces with `open` lit: its own, or between each word and the next disc

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Button = require(script.Parent.Button)
local Glass = require(script.Parent.Glass)
local Skin = require(script.Parent.Skin)
local Fade = require(script.Parent.Fade)

local RAIL = HudConfig.Equipment.Rail
local MOTION = HudConfig.Equipment.Motion
local SEAM = UIKit.Palettes.SeamGlass
local LIGHT = SEAM.Light :: Color3
local CLEAR = 4 -- a computed piece starts this far under the word above it

export type Spec = {
	Pages: { string },
	At: { [string]: Vector2 }, -- each disc's middle, laid
	Marks: { [string]: string }, -- each page's mark (UIKit's, or the Voidkin screen's page icons)
	Words: { [string]: string }?, -- a page's word where it isn't its name
	Line: { number }, -- the line's x, its top and its foot, laid
	Pieces: { [string]: { { number } } }?, -- its own pieces with each page open, laid; else Rail.Pieces computes them
	Rest: number?, -- the discs' radii: RAIL's unless the screen has less room
	Chosen: number?,
	Tap: Vector2?, -- a page's button, about its disc's middle: wide, tall (92 x 79)
	TapTop: number?, -- how far over the disc's middle the button starts (31)
	Switch: (name: string) -> boolean,
}
export type Rail = { Holder: Frame, Line: Frame, Spec: Spec, Faces: { [string]: Frame }, Buttons: { [string]: TextButton }, Open: string }

local Rail = {}

local function radius(spec: Spec, chosen: boolean): number
	return if chosen then spec.Chosen or RAIL.Chosen else spec.Rest or RAIL.Rest
end

local function face(rail: Rail, name: string, chosen: boolean): Frame
	local spec = rail.Spec
	local at = spec.At[name]
	local r = radius(spec, chosen)
	local side = 2 * (radius(spec, true) + 24)
	local made = Instance.new("Frame")
	made.Name = `{name}Face`
	made.BackgroundTransparency = 1
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.fromOffset(at.X, at.Y)
	made.Size = UDim2.fromOffset(side, side)
	made.ZIndex = 3
	made.Parent = rail.Holder
	local scale = Instance.new("UIScale")
	scale.Name = "Grow"
	scale.Parent = made
	local function lay(image: string, laid: number, tint: Color3?, alpha: number, z: number): ImageLabel
		local laidOut = Skin.Lay(made, image, { Name = image, Tint = tint, Alpha = alpha, Z = z })
		laidOut.AnchorPoint = Vector2.new(0.5, 0.5)
		laidOut.Position = UDim2.fromScale(0.5, 0.5)
		laidOut.Size = UDim2.fromOffset(laid, laid)
		return laidOut
	end
	if chosen then
		lay("RailGlow", 2 * (r + 24), LIGHT, 1 - RAIL.Glow, 3)
	end
	local disc = lay("RailDisc", 2 * (r + 1), nil, 1, 4)
	local colours = (if chosen then SEAM.Card else SEAM.Button) :: { Color3 }
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colours[1]),
		ColorSequenceKeypoint.new(1 / 56, colours[1]),
		ColorSequenceKeypoint.new(55 / 56, colours[2]),
		ColorSequenceKeypoint.new(1, colours[2]),
	})
	gradient.Parent = disc
	lay("RailSheen", 2 * (r + 1), SEAM.Glint, 1 - (if chosen then RAIL.Sheen.Chosen else RAIL.Sheen.Rest), 5)
	if chosen then
		lay("RailLight", 2 * (r + 1), LIGHT, 1 - RAIL.Light, 6)
		lay("RailRingChosen", 2 * (r + 4.5), LIGHT, 1, 7)
		lay("RailEdgeChosen", 2 * (r + 1), SEAM.Facet, 1 - RAIL.Edge, 8)
		local comet = lay("RailComet", 2 * (r + 4.5), SEAM.Glint, 1 - RAIL.Comet, 10)
		comet.Name = "Comet"
	else
		lay("RailRing", 2 * (r + 4.5), SEAM.Facet, 1, 7)
		lay("RailEdge", 2 * (r + 1), SEAM.Edge, 1 - RAIL.Edge, 8)
	end
	local mark = spec.Marks[name]
	local record = UIKit.Images[mark] or HudConfig.Voidkin.Chrome.Images[mark]
	local tall = 1.05 * r
	local image = Glass.Mark(made, "Mark", record, side / 2, side / 2, tall * record.Points.X / record.Points.Y, if chosen then SEAM.Glint else SEAM.Soft, 9)
	image.Name = "Mark"
	made:SetAttribute("Chosen", chosen)
	return made
end

local function word(rail: Rail, name: string, chosen: boolean): TextLabel
	local spec = rail.Spec
	local at = spec.At[name]
	local r = radius(spec, chosen)
	local size = if chosen then RAIL.Word.Chosen else RAIL.Word.Rest
	local said = if spec.Words and spec.Words[name] then spec.Words[name] else name
	local y = at.Y + r + RAIL.Word.Gap
	return Glass.Label(rail.Holder, `{name}Word`, said, size, if chosen then LIGHT else SEAM.Soft, at.X - 46, y - 1, 92, size + 2, Enum.TextXAlignment.Center, chosen, 3)
end

-- The line's pieces with `open` lit: the screen's own, else from the line's top to the first disc, then from under each
-- page's word to the next disc; none where there's no room.
function Rail.Pieces(spec: Spec, open: string): { { number } }
	if spec.Pieces then
		return spec.Pieces[open]
	end
	local pieces: { { number } } = {}
	local from = spec.Line[2]
	for _, name in spec.Pages do
		local chosen = name == open
		local r = radius(spec, chosen)
		local y = spec.At[name].Y
		if y - r - from >= 1 then
			table.insert(pieces, { from, y - r })
		end
		from = y + r + RAIL.Word.Gap + (if chosen then RAIL.Word.Chosen else RAIL.Word.Rest) + CLEAR
	end
	return pieces
end

local function line(rail: Rail)
	local spec = rail.Spec
	rail.Line:ClearAllChildren()
	for k, piece in Rail.Pieces(spec, rail.Open) do
		local clip = Instance.new("Frame")
		clip.Name = `Piece{k}`
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Position = UDim2.fromOffset(spec.Line[1] - 2, piece[1])
		clip.Size = UDim2.fromOffset(4, piece[2] - piece[1])
		clip.ZIndex = 1
		clip.Parent = rail.Line
		local stroke = Instance.new("Frame")
		stroke.Name = "Stroke"
		stroke.BorderSizePixel = 0
		stroke.BackgroundColor3 = SEAM.Facet
		stroke.BackgroundTransparency = RAIL.Line.Alpha
		stroke.Position = UDim2.fromOffset(2 - RAIL.Line.Wide / 2, 0)
		stroke.Size = UDim2.new(0, RAIL.Line.Wide, 1, 0)
		stroke.ZIndex = 1
		stroke.Parent = clip
		local runner = Skin.Lay(clip, "RailRunner", { Name = "Runner", Tint = SEAM.Glint, Alpha = 1 - RAIL.Runner, Z = 2 })
		runner.Position = UDim2.fromOffset(0, -200)
		runner:SetAttribute("Top", piece[1])
	end
end

function Rail.Paint(rail: Rail, open: string, last: string?)
	rail.Open = open
	for _, name in rail.Spec.Pages do
		local chosen = name == open
		local old = rail.Faces[name]
		local was = if old then old:GetAttribute("Chosen") == true else nil
		local said = rail.Holder:FindFirstChild(`{name}Word`)
		if old and was == chosen then
			continue
		end
		if old then
			old:Destroy()
		end
		if said then
			said:Destroy()
		end
		local made = face(rail, name, chosen)
		rail.Faces[name] = made
		local label = word(rail, name, chosen)
		if last ~= nil and old ~= nil then
			local from = radius(rail.Spec, not chosen) / radius(rail.Spec, chosen)
			local grow = made:FindFirstChild("Grow") :: UIScale
			grow.Scale = from
			Glass.Ease(made, MOTION.Switch, function(u: number)
				local w = math.clamp(u, 0, 1) - 1 -- a Back ease out (Look.BackOut)
				local back = MOTION.Back
				grow.Scale = from + (1 - from) * (1 + (back + 1) * w * w * w + back * w * w)
			end, Enum.EasingStyle.Linear)
			Fade.Set(label, 0)
			Glass.Ease(label, MOTION.Cross, function(u: number)
				local v = math.clamp(u, 0, 1)
				Fade.Set(label, v * v * (3 - 2 * v))
			end, Enum.EasingStyle.Linear)
		end
	end
	line(rail)
end

function Rail.new(parent: Instance, spec: Spec, open: string): Rail
	local holder = Instance.new("Frame")
	holder.Name = "Rail"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 3
	holder.Parent = parent
	local stroke = Instance.new("Frame")
	stroke.Name = "Line"
	stroke.BackgroundTransparency = 1
	stroke.Size = UDim2.fromScale(1, 1)
	stroke.ZIndex = 1
	stroke.Parent = holder
	local rail: Rail = { Holder = holder, Line = stroke, Spec = spec, Faces = {}, Buttons = {}, Open = open }
	local tap = spec.Tap or Vector2.new(92, 79)
	local top = spec.TapTop or 31
	for _, name in spec.Pages do
		local at = spec.At[name]
		local button = Button.new({
			Name = `Rail{name}`,
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(tap.X, tap.Y),
			Position = UDim2.fromOffset(at.X - tap.X / 2, at.Y - top),
			Parent = holder,
			Still = true,
			OnPress = function(): boolean
				return spec.Switch(name)
			end,
		})
		button.ZIndex = 4
		rail.Buttons[name] = button
	end
	Rail.Paint(rail, open, nil)
	return rail
end

function Rail.Idle(rail: Rail, phase: number)
	local lit = rail.Faces[rail.Open]
	local comet = if lit then lit:FindFirstChild("Comet") :: ImageLabel? else nil
	if comet then
		comet.Rotation = 360 * phase
	end
	local spec = rail.Spec
	local y = spec.Line[2] + (spec.Line[3] - spec.Line[2]) * phase
	for _, clip in rail.Line:GetChildren() do
		local runner = clip:FindFirstChild("Runner") :: ImageLabel?
		local top = if runner then runner:GetAttribute("Top") else nil
		if runner and type(top) == "number" then
			runner.Position = UDim2.fromOffset(0, y - top - 48)
		end
	end
end

return Rail
