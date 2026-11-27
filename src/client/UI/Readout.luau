--!strict
-- Readout (client): the signature's press: B's layout in F2's finish (AR62's piece 1, research's picks of 2026-11-26, 23:46
-- and 2026-11-27, 00:36; Config.Hud.Slate.Press, UI.Kit.Slate): the one big press on the HUD, a gold disc the tap's size
-- in the lead's corner, lit from below with a lit curve. The director rejected the fist and its cooldown (2026-11-27, by
-- 01:00), so its look waits on the next direction, in two slots that take it without a rebuild:
--   its art, one image on the disc (Press.Art): the signature's own, else today's mark, else its class's glyph;
--   its cooldown, one layer over the disc and its art (Press.Cooldown): today, the charge a ring round it on a dark gold
--   track, clockwise from the top, a veil of the Cool family over the disc while it charges and the seconds left on it.
-- As the move fires, the veil comes in over the flash and the piece swells; ready again, it swells once. The motion's
-- numbers: Config.Hud.Readout.
--   Readout.new(parent)              the piece, hidden
--   Readout.Step(piece, state)       draws a state: how full, the seconds left, the flash, the swell, how far it's faded
--                                    in, whose art
-- The ring: two halves, each clipping a whole ring whose stepped gradient turns with the share (the share's angle on
-- each side of the top's line).

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Skin = require(script.Parent.Kit.Skin)
local Slate = require(script.Parent.Kit.Slate)

export type State = {
	Share: number, -- 0 to 1 of the cooldown
	Full: boolean,
	Left: number?, -- the seconds left of it
	Flash: number, -- 1 as it fires, to 0
	Swell: number, -- 0 to 1 and back, once, as it's ready again
	Pulse: number?, -- 0 to 1 and back, once, a full ring left untapped (TR52)
	Press: number?, -- how far a tap has it in, of Config's Press: 1 on the tap's frame, back to 0 (TR52)
	Seen: number, -- 0 hidden to 1 shown
	Action: string, -- the signature's id
	Class: string, -- the lead's class, for a signature with no art yet
}

export type Piece = {
	Frame: Frame,
	Scale: UIScale,
	Disc: Frame, -- the gold disc (a Slate plate)
	Gold: Frame, -- its outer ring: its fade
	Curve: UIStroke, -- its lit curve from below
	Art: ImageLabel, -- the one art slot
	Cooldown: Frame, -- the cooldown's layer, over the disc and its art
	Veil: Frame, -- the Cool family's disc over them while it charges (a Slate plate)
	Glass: Frame, -- the veil's outer ring: its fade
	TrackInk: UIStroke, -- the ink under the ring's track
	Track: UIStroke, -- the ring's unlit track
	Halves: { UIGradient }, -- the lit ring's right and left halves
	Lit: { UIStroke },
	Count: TextLabel, -- the seconds left
}

local Readout = {}

local pt = Slate.Pt
local STEP = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
})
-- The lit curve: its stroke shown only along its foot (top to foot, 0 to 1).
local CURVE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.8, 1),
	NumberSequenceKeypoint.new(0.88, 0),
	NumberSequenceKeypoint.new(1, 0),
})

local function press(): any
	return HudConfig.Slate.Press
end

local function disc(parent: Instance, name: string, size: number, z: number): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BorderSizePixel = 0
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.fromScale(0.5, 0.5)
	made.Size = UDim2.fromOffset(size, size)
	made.ZIndex = z
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = made
	made.Parent = parent
	return made
end

-- A ring whose line, `width` wide, runs centred on the circle Cooldown.Ring past the disc's edge (a stroke draws outside
-- its box).
local function ring(parent: Instance, name: string, width: number, z: number): (Frame, UIStroke)
	local p = press()
	local made = disc(parent, name, pt(p.Size) + 2 * (pt(p.Cooldown.Ring) - width / 2), z)
	made.BackgroundTransparency = 1
	local line = Instance.new("UIStroke")
	line.Name = "Line"
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Thickness = width
	line.Parent = made
	return made, line
end

local function plate(frame: Frame, name: string, side: string, size: number, z: number): Frame
	local made = Slate.Plate(frame, name, Vector2.new(size, size), side, "Disc")
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = UDim2.fromScale(0.5, 0.5)
	made.ZIndex = z
	return made
end

type Layer = {
	Frame: Frame,
	Veil: Frame,
	TrackInk: UIStroke,
	Track: UIStroke,
	Halves: { UIGradient },
	Lit: { UIStroke },
	Count: TextLabel,
}

-- Today's cooldown, its layer's parts: the veil, the ring (the ink under its track, the track, its lit halves over
-- them) and the count.
local function cooldownLayer(frame: Frame, size: number): Layer
	local c = press().Cooldown
	local layer = Instance.new("Frame")
	layer.Name = "Cooldown"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.ZIndex = 8
	layer.Parent = frame
	local veil = plate(layer, "Veil", "Cool", size, 1)
	local _, trackInk = ring(layer, "TrackInk", pt(c.Ink), 2)
	local trackFrame, track = ring(layer, "Track", pt(c.Line), 3)
	local across = trackFrame.Size.X.Offset
	local halves: { UIGradient } = {}
	local lit: { UIStroke } = {}
	for index, side in { "Right", "Left" } do
		local half = Instance.new("Frame")
		half.Name = side
		half.BackgroundTransparency = 1
		half.ClipsDescendants = true
		half.AnchorPoint = Vector2.new(0.5, 0.5)
		-- a margin round the ring's box so its stroke, drawn outside the box, isn't clipped but at the middle line
		local room = across + 4 * pt(c.Line)
		half.Size = UDim2.fromOffset(room / 2, room)
		half.Position = UDim2.new(0.5, if side == "Right" then room / 4 else -room / 4, 0.5, 0)
		half.ZIndex = 4
		half.Parent = layer
		local whole, line = ring(half, "Ring", pt(c.Line), 1)
		whole.Position = UDim2.new(if side == "Right" then 0 else 1, 0, 0.5, 0)
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Share"
		gradient.Transparency = STEP
		gradient.Parent = line
		halves[index] = gradient
		lit[index] = line
	end
	local count = Slate.Gold(layer, "Count", pt(c.Count))
	count.AnchorPoint = Vector2.new(0.5, 0.5)
	count.Position = UDim2.fromScale(0.5, 0.5)
	count.Size = UDim2.fromScale(1, 1)
	count.ZIndex = 5
	count.Visible = false
	return { Frame = layer, Veil = veil, TrackInk = trackInk, Track = track, Halves = halves, Lit = lit, Count = count }
end

function Readout.new(parent: Instance): Piece
	local p = press()
	local size = pt(p.Size)
	local frame = Instance.new("Frame")
	frame.Name = "Signature"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(size, size)
	frame.AnchorPoint = Vector2.new(0.5, 0.5) -- it swells about its middle
	frame.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	-- The disc, its lit curve from below, its art over it.
	local gold = plate(frame, "Disc", "Gold", size, 4)
	local curveFrame = disc(gold, "Curve", size * p.Curve.Across, 3)
	curveFrame.BackgroundTransparency = 1
	local curve = Instance.new("UIStroke")
	curve.Name = "Line"
	curve.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	curve.Color = Color3.new(1, 1, 1)
	curve.Parent = curveFrame
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = CURVE
	fade.Parent = curve
	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.BorderSizePixel = 0
	art.ZIndex = 6
	art.Parent = frame
	local layer = cooldownLayer(frame, size)
	frame.Parent = parent
	return {
		Frame = frame,
		Scale = scale,
		Disc = gold,
		Gold = gold:FindFirstChild("Glass") :: Frame,
		Curve = curve,
		Art = art,
		Cooldown = layer.Frame,
		Veil = layer.Veil,
		Glass = layer.Veil:FindFirstChild("Glass") :: Frame,
		TrackInk = layer.TrackInk,
		Track = layer.Track,
		Halves = layer.Halves,
		Lit = layer.Lit,
		Count = layer.Count,
	}
end

-- The art slot: the signature's own image (Press.Art.Images), else today's mark (Config.Hud.Readout.Icons), else its
-- class's glyph, Art.Size page points across, centred on the disc, in white.
local function art(piece: Piece, action: string, class: string)
	local p = press()
	local own = p.Art.Images[action]
	local key = `{action}\0{class}\0{p.Art.Size}\0{p.Size}\0{own or ""}`
	if piece.Frame:GetAttribute("ArtKey") == key then
		return
	end
	local size, across = pt(p.Size), pt(p.Art.Size)
	local at = (size - across) / 2
	local slot = piece.Art
	if own then
		slot.Image = own
		slot.ScaleType = Enum.ScaleType.Fit
		slot.ImageRectOffset, slot.ImageRectSize = Vector2.zero, Vector2.zero
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
	slot.ImageColor3 = HudConfig.Slate.Ink
	piece.Frame:SetAttribute("ArtKey", key)
end

-- The ring's colours and widths from the tokens, laid again only when one changes (a Tune, the next finish). The discs
-- are Slate plates: the kit's repaint lays theirs.
local function paint(piece: Piece)
	local s = HudConfig.Slate
	local c = s.Press.Cooldown
	local key = `{c.Track:ToHex()}{s.Sides.Gold.Ink:ToHex()}{s.Accent[2]:ToHex()}{c.Line}{c.Ink}{c.Ring}{s.Press.Curve.Line}`
	if piece.Frame:GetAttribute("PaintKey") == key then
		return
	end
	piece.Frame:SetAttribute("PaintKey", key)
	piece.TrackInk.Color = s.Sides.Gold.Ink
	piece.TrackInk.Thickness = pt(c.Ink)
	piece.Track.Color = c.Track
	piece.Track.Thickness = pt(c.Line)
	for _, line in piece.Lit do
		line.Color = s.Accent[2]
		line.Thickness = pt(c.Line)
	end
	piece.Curve.Thickness = pt(s.Press.Curve.Line)
end

-- Today's cooldown: the veil over the disc while it charges (coming in over the flash as it fires), the seconds left on
-- it, the ring lit by the share.
local function cooldown(piece: Piece, state: State, seen: number, hot: number, share: number)
	local c = press().Cooldown
	Slate.Clear(piece.Veil, 1 - seen * (1 - hot) * (1 - c.Veil))
	local left = state.Left
	local counting = not state.Full and left ~= nil and left > 0 and seen > 0
	piece.Count.Visible = counting
	if counting then
		local text = string.format("%d", math.ceil(left :: number))
		if piece.Count.Text ~= text then
			piece.Count.Text = text
		end
		Slate.Fade(piece.Count, 1 - seen * (1 - hot))
	end
	piece.TrackInk.Transparency = 1 - seen * (1 - c.InkClear)
	piece.Track.Transparency = 1 - seen * (1 - c.TrackClear)
	piece.Halves[1].Rotation = math.min(share, 0.5) * 360
	piece.Halves[2].Rotation = math.max(share, 0.5) * 360
	for _, line in piece.Lit do
		line.Transparency = if share > 0 then 1 - seen else 1
	end
end

function Readout.Step(piece: Piece, state: State)
	local config = HudConfig.Readout
	local p = press()
	paint(piece)
	art(piece, state.Action, state.Class)
	local seen = math.clamp(state.Seen, 0, 1)
	-- Ready, the disc whole and lit; as it fires, the cooldown comes in over the flash.
	local hot = if state.Full then 1 else math.clamp(state.Flash, 0, 1)
	local share = if state.Full then 1 else math.clamp(state.Share, 0, 1)
	Slate.Clear(piece.Disc, 1 - seen)
	piece.Curve.Transparency = 1 - (1 - p.Curve.Clear) * seen * hot
	piece.Art.ImageTransparency = 1 - seen
	cooldown(piece, state, seen, hot, share)
	piece.Scale.Scale = 1 + config.Swell * state.Flash + config.ReadySwell * state.Swell + config.Pulse.Scale * (state.Pulse or 0)
		- config.Press * (state.Press or 0)
	piece.Frame:SetAttribute("Share", state.Share)
	piece.Frame:SetAttribute("Hot", hot)
end

return Readout
