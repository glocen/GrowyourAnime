--!strict
-- Press (client UI): the signature's press, under the lead's plate: AR68 M's first piece on (a) slate (research's pick of
-- 2026-11-27, 13:38; Config.Hud.M; Config.UIKit's M*). A dark disc with the skill's art on it, an orange ring round it that
-- fills clockwise from the top over the cooldown and is whole when the skill is ready; awake, a soft glow behind the disc.
-- Its label card to the right says how full it is while it fills ("62%") and the skill's name once it's awake. Under the
-- label, Auto's chip and the eye's. The motion is today's (Config.Hud.Readout): the swell as it fires and as it's ready,
-- the pulse of a full ring left untapped, the squeeze of a tap.
--   Press.new(parent)                 the piece, hidden; its label in `parent` beside it
--   Press.Step(piece, state)          draws a state (Readout's)
--   Press.Place(piece, centre)        the disc's centre, authored; the label follows it
--   Press.AutoChip(button)            Auto's chip on its button; Press.AutoShows(button, on)
--   Press.EyeChip(button)             the eye's chip on its button; Press.EyeShows(button, on, whole)
--   Press.Box(name) -> (x, y, w, h)   a box of the frame (Config.Hud.M), authored, from the disc's centre

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Skin = require(script.Parent.Kit.Skin)
local Edge = require(script.Parent.Kit.Edge)

export type State = {
	Share: number,
	Full: boolean,
	Left: number?,
	Flash: number,
	Swell: number,
	Pulse: number?,
	Press: number?,
	Seen: number,
	Action: string,
	Class: string,
	Name: string?, -- the skill's name, for the label awake
}

export type Piece = {
	Frame: Frame,
	Scale: UIScale,
	Glow: ImageLabel,
	Disc: ImageLabel,
	Art: ImageLabel,
	Halves: { UIGradient },
	Rings: { ImageLabel },
	Label: Frame, -- the label's holder, beside the piece
	Card: ImageLabel,
	Says: TextLabel,
}

local Press = {}

local STEP = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local function m(): any
	return HudConfig.M
end

local function pt(point: number): number
	return point * m().Per
end

-- A box of the frame from the disc's centre, authored.
function Press.Box(name: string): (number, number, number, number)
	local c = m()
	local b = c[name]
	local centre = c.Art.Centre
	return pt(b[1] - centre.X), pt(b[2] - centre.Y), pt(b[3]), pt(b[4])
end

local function image(parent: Instance, kit: string, name: string, across: number, z: number): ImageLabel
	local im = UIKit.Images[kit]
	local made = Instance.new("ImageLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.Image = im.Id
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.fromScale(0.5, 0.5)
	-- its box across, and its pad round it
	local size = across * im.Points.X / (im.Points.X - 2 * im.Pad)
	made.Size = UDim2.fromOffset(size, size)
	made.ZIndex = z
	made:SetAttribute("Kit", kit)
	made.Parent = parent
	return made
end

local function word(parent: Instance, name: string, row: any, z: number): TextLabel
	local c = m()
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = ""
	label.TextColor3 = c.Colours.Text
	label.FontFace = Font.new(c.Font, if row.Bold then Enum.FontWeight.Bold else Enum.FontWeight.Regular)
	label.TextSize = Edge.Size(pt(row.Size))
	label.ZIndex = z
	label.Parent = parent
	Edge.Wear(label)
	return label
end

function Press.new(parent: Instance): Piece
	local c = m()
	local across = pt(c.Disc[3])
	local frame = Instance.new("Frame")
	frame.Name = "Signature"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(across, across)
	frame.AnchorPoint = Vector2.new(0.5, 0.5) -- it swells about its middle
	frame.Visible = false
	frame:SetAttribute("Look", "M")
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.BackgroundTransparency = 1
	glow.Image = UIKit.Images.MPressGlow.Id
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromOffset(pt(c.Glow[3]), pt(c.Glow[4]))
	glow.ZIndex = 1
	glow.Parent = frame
	local disc = image(frame, "MPressDisc", "Disc", across, 2)
	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.BorderSizePixel = 0
	art.ZIndex = 3
	art.Parent = frame
	-- The ring in two halves, each clipping a whole ring whose stepped gradient turns with the share.
	local ringSize = across * UIKit.Images.MPressRing.Points.X / (UIKit.Images.MPressRing.Points.X - 2 * UIKit.Images.MPressRing.Pad)
	local halves: { UIGradient } = {}
	local rings: { ImageLabel } = {}
	for index, side in { "Right", "Left" } do
		local half = Instance.new("Frame")
		half.Name = side
		half.BackgroundTransparency = 1
		half.ClipsDescendants = true
		half.AnchorPoint = Vector2.new(if side == "Right" then 0 else 1, 0.5)
		half.Position = UDim2.fromScale(0.5, 0.5)
		half.Size = UDim2.fromOffset(ringSize / 2, ringSize)
		half.ZIndex = 4
		half.Parent = frame
		local ring = Instance.new("ImageLabel")
		ring.Name = "Ring"
		ring.BackgroundTransparency = 1
		ring.Image = UIKit.Images.MPressRing.Id
		ring.ImageColor3 = c.Colours.Hue
		ring.Size = UDim2.fromOffset(ringSize, ringSize)
		ring.Position = UDim2.fromOffset(if side == "Right" then -ringSize / 2 else 0, 0)
		ring.ZIndex = 4
		ring.Parent = half
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Share"
		gradient.Transparency = STEP
		gradient.Parent = ring
		halves[index] = gradient
		rings[index] = ring
	end
	-- The label's card beside it, in the layer: it never swells with the disc.
	local holder = Instance.new("Frame")
	holder.Name = "PressLabel"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Visible = false
	holder.Parent = parent
	local card = Skin.Lay(holder, "MLabelCard", { Name = "Card", Scale = c.Per, Z = 1 })
	local says = word(holder, "Says", c.Texts.Label, 3)
	says.AnchorPoint = Vector2.new(0.5, 0)
	frame.Parent = parent
	return { Frame = frame, Scale = scale, Glow = glow, Disc = disc, Art = art, Halves = halves, Rings = rings, Label = holder, Card = card, Says = says }
end

-- The disc's centre, authored; the label beside it.
function Press.Place(piece: Piece, centre: Vector2)
	piece.Frame.Position = UDim2.fromOffset(centre.X, centre.Y)
	local x, y, _, h = Press.Box("Label")
	piece.Label.Position = UDim2.fromOffset(centre.X + x, centre.Y + y)
	piece.Label.Size = UDim2.fromOffset(piece.Label.Size.X.Offset, h)
end

-- The art: the skill's own pair (Config.Hud.M.Art.Own: awake, and greyed while it fills) at its box; else a token's
-- image (Slate.Press.Art.Images), else today's mark (Readout.Icons), else its class's glyph.
local function art(piece: Piece, action: string, class: string, full: boolean)
	local c = m()
	local pair = c.Art.Own[action]
	local own = HudConfig.Slate.Press.Art.Images[action]
	local key = `{action}\0{class}\0{c.Art.Radius}\0{c.Art.Glyph}\0{c.Per}\0{own or ""}\0{if pair then tostring(full) else ""}`
	if piece.Frame:GetAttribute("ArtKey") == key then
		return
	end
	if pair then
		local name = if full then pair.Awake else pair.Cold
		local box = c.Art.Box
		piece.Art.ImageColor3 = Color3.new(1, 1, 1)
		Skin.Set(piece.Art, name, { X = pt(box[1] - c.Disc[1]), Y = pt(box[2] - c.Disc[2]), Scale = c.Per })
		piece.Frame:SetAttribute("Art", name)
		piece.Frame:SetAttribute("ArtKey", key)
		return
	end
	local across = pt(2 * c.Art.Radius) * (if own then 1 else c.Art.Glyph)
	local at = (pt(c.Disc[3]) - across) / 2
	local slot = piece.Art
	if own then
		slot.Image = own
		slot.ScaleType = Enum.ScaleType.Fit
		slot.Size = UDim2.fromOffset(across, across)
		slot.Position = UDim2.fromOffset(at, at)
		slot:SetAttribute("Kit", nil)
		piece.Frame:SetAttribute("Art", own)
	else
		local mark = HudConfig.Readout.Icons[action]
		local name = if mark and UIKit.Images[mark] then mark else `Class{class}Glyph`
		if UIKit.Images[name] == nil then
			return -- the lead's class isn't known yet: asked again next frame
		end
		Skin.Set(slot, name, { X = at, Y = at, Scale = across / UIKit.Images[name].Points.X })
		piece.Frame:SetAttribute("Art", name)
	end
	slot.ImageColor3 = c.Colours.Text
	piece.Frame:SetAttribute("ArtKey", key)
end

-- The label: its share while it fills, the skill's name awake; its card wide enough for either.
local function label(piece: Piece, state: State, seen: number)
	local c = m()
	local _, _, w, h = Press.Box("Label")
	local awake = state.Full
	local text = if awake then string.upper(state.Name or "") else `{math.floor(math.clamp(state.Share, 0, 1) * 100)}%`
	if piece.Says.Text ~= text then
		piece.Says.Text = text
	end
	local wide = if awake then math.max(w, piece.Says.TextBounds.X + pt(16)) else pt(c.Label.Filling)
	local holder = piece.Label
	if holder.Size.X.Offset ~= wide or holder.Size.Y.Offset ~= h then
		holder.Size = UDim2.fromOffset(wide, h)
		Skin.Set(piece.Card, "MLabelCard", { X = 0, Y = 0, W = wide, H = h, Scale = c.Per })
	end
	local row = c.Texts.Label
	local size = Edge.Size(pt(row.Size))
	local top = pt(row.Baseline - c.Label[2]) - size * c.Rise
	piece.Says.TextSize = size
	piece.Says.Position = UDim2.fromOffset(wide / 2, top)
	piece.Says.Size = UDim2.fromOffset(wide, size * 1.2)
	holder.Visible = seen > 0 and text ~= ""
	piece.Card.ImageTransparency = 1 - seen
	Edge.Fade(piece.Says, 1 - seen)
	holder:SetAttribute("Awake", awake)
end

function Press.Step(piece: Piece, state: State)
	local config = HudConfig.Readout
	local c = m()
	art(piece, state.Action, state.Class, state.Full)
	local whole = state.Full or c.Art.Own[state.Action] ~= nil -- its own cold art is drawn whole
	local seen = math.clamp(state.Seen, 0, 1)
	local hot = if state.Full then 1 else math.clamp(state.Flash, 0, 1)
	local share = if state.Full then 1 else math.clamp(state.Share, 0, 1)
	piece.Disc.ImageTransparency = 1 - seen
	piece.Glow.Visible = state.Full
	piece.Glow.ImageTransparency = 1 - seen * hot
	piece.Art.ImageTransparency = 1 - seen * (if whole then 1 else c.Art.Filling)
	piece.Halves[1].Rotation = math.min(share, 0.5) * 360
	piece.Halves[2].Rotation = math.max(share, 0.5) * 360
	for _, ring in piece.Rings do
		ring.ImageTransparency = if share > 0 then 1 - seen else 1
	end
	label(piece, state, seen)
	piece.Scale.Scale = 1 + config.Swell * state.Flash + config.ReadySwell * state.Swell + config.Pulse.Scale * (state.Pulse or 0)
		- config.Press * (state.Press or 0)
	piece.Frame:SetAttribute("Share", state.Share)
	piece.Frame:SetAttribute("Hot", hot)
end

-- A chip on a control's button: its card at the button's left, centred on its height; the button at least a tap wide.
local function chip(button: GuiObject, name: string): (Frame, number, number)
	local c = m()
	local _, _, w, h = Press.Box(name)
	local skin = Skin.Of(button)
	local holder = skin:FindFirstChild("Chip") :: Frame?
	if holder == nil then
		local made = Instance.new("Frame")
		made.Name = "Chip"
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.Parent = skin
		Skin.Lay(made, "MChip", { Name = "Card", X = 0, Y = 0, W = w, H = h, Scale = c.Per, Z = 1 })
		holder = made
	end
	local found = holder :: Frame
	found.AnchorPoint = Vector2.new(0, 0)
	found.Position = UDim2.fromOffset(0, 0) -- its touch box hangs below it, clear of the label above
	found.Size = UDim2.fromOffset(w, h)
	return found, w, h
end

function Press.AutoChip(button: TextButton)
	local c = m()
	local card = chip(button, "Auto")
	local mark = Instance.new("Frame")
	mark.Name = "Mark"
	mark.BorderSizePixel = 0
	mark.BackgroundColor3 = c.Colours.Text
	mark.Position = UDim2.fromOffset(pt(c.AutoMark[1] - c.Auto[1]), pt(c.AutoMark[2] - c.Auto[2]))
	mark.Size = UDim2.fromOffset(pt(c.AutoMark[3]), pt(c.AutoMark[4]))
	mark.ZIndex = 3
	local line = Instance.new("UIStroke")
	line.Name = "Line"
	line.Color = c.Colours.Text
	line.Thickness = pt(1)
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = mark
	mark.Parent = card
	local row = c.Texts.Auto
	local says = word(card, "Word", row, 3)
	says.Text = "AUTO"
	says.TextXAlignment = Enum.TextXAlignment.Left
	local size = says.TextSize
	says.Position = UDim2.fromOffset(pt(row.X - c.Auto[1]), pt(row.Baseline - c.Auto[2]) - size * c.Rise)
	says.Size = UDim2.fromOffset(pt(c.Auto[3]) - pt(row.X - c.Auto[1]), size * 1.2)
end

-- On, the mark a filled square; off, its outline.
function Press.AutoShows(button: TextButton, on: boolean)
	local card = Skin.Of(button):FindFirstChild("Chip")
	local mark = if card then card:FindFirstChild("Mark") :: Frame? else nil
	if mark then
		mark.BackgroundTransparency = if on then 0 else 1
	end
	button:SetAttribute("On", on)
end

function Press.EyeChip(button: TextButton)
	local c = m()
	local card = chip(button, "Eye")
	local eye = Instance.new("ImageLabel")
	eye.Name = "Eye"
	eye.BackgroundTransparency = 1
	eye.BorderSizePixel = 0
	eye.ZIndex = 3
	eye.Parent = card
	Skin.Set(eye, "MEye", { X = pt(c.EyeMark[1] - c.Eye[1]), Y = pt(c.EyeMark[2] - c.Eye[2]), Scale = c.Per })
end

-- On (watching the lead), the eye lit in the hue; off, off-white; `whole` its opacity (fainter while it can't be used).
function Press.EyeShows(button: TextButton, on: boolean, whole: number)
	local c = m()
	local card = Skin.Of(button):FindFirstChild("Chip")
	local eye = if card then card:FindFirstChild("Eye") :: ImageLabel? else nil
	if eye then
		eye.ImageColor3 = if on then c.Colours.Hue else c.Colours.Text
		eye.ImageTransparency = 1 - whole
	end
	local face = if card then card:FindFirstChild("Card") :: ImageLabel? else nil
	if face then
		face.ImageTransparency = 1 - whole
	end
	button:SetAttribute("On", on)
end

return Press
