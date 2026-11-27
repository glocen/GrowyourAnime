--!strict
-- Readout (client): the signature's press: B's layout in F2's finish (AR62's piece 1, research's picks of 2026-11-26, 23:46
-- and 2026-11-27, 00:36; Config.Hud.Slate.Press, UI.Kit.Slate; F2_states.png): the one big press on the HUD, a gold disc
-- the tap's size in the lead's corner, with the lead's signature's own icon. Its charge runs round it on a dark gold
-- track, clockwise from the top. Charging, it cools: the disc in the Cool family, its icon faint and the seconds left on
-- it. Ready, the disc is the bright gold, lit from below with a lit curve, its icon whole and the ring whole and lit: the
-- loudest piece on the HUD. As the move fires, the gold empties in a flash and the piece swells; ready again, it swells
-- once. A signature with no icon yet shows its class's glyph. The motion's numbers: Config.Hud.Readout.
--   Readout.new(parent)              the piece, hidden
--   Readout.Step(piece, state)       draws a state: how full, the flash, the swell, how far it's faded in, whose icon
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
	Class: string, -- the lead's class, for a signature with no icon yet
}

export type Piece = {
	Frame: Frame,
	Scale: UIScale,
	Cool: Frame, -- the disc while it charges (a Slate plate)
	Ready: Frame, -- and ready
	Glass: Frame, -- the cooling disc's outer ring: its fade
	Gold: Frame, -- the ready disc's
	Curve: UIStroke, -- the ready disc's lit curve from below
	TrackInk: UIStroke, -- the ink under the ring's track
	Track: UIStroke, -- the ring's unlit track
	Halves: { UIGradient }, -- the lit ring's right and left halves
	Lit: { UIStroke },
	Icon: ImageLabel,
	ReadyIcon: ImageLabel,
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

-- A ring whose line, `width` wide, runs centred on the circle Press.Ring past the disc's edge (a stroke draws outside
-- its box).
local function ring(parent: Instance, name: string, width: number, z: number): (Frame, UIStroke)
	local p = press()
	local made = disc(parent, name, pt(p.Size) + 2 * (pt(p.Ring) - width / 2), z)
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
	-- The ring: the ink under its track, the track, then its lit halves over them.
	local _, trackInk = ring(frame, "TrackInk", pt(p.TrackInk), 1)
	local trackFrame, track = ring(frame, "Track", pt(p.Line), 2)
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
		local room = across + 4 * pt(p.Line)
		half.Size = UDim2.fromOffset(room / 2, room)
		half.Position = UDim2.new(0.5, if side == "Right" then room / 4 else -room / 4, 0.5, 0)
		half.ZIndex = 3
		half.Parent = frame
		local whole, line = ring(half, "Ring", pt(p.Line), 3)
		whole.Position = UDim2.new(if side == "Right" then 0 else 1, 0, 0.5, 0)
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Share"
		gradient.Transparency = STEP
		gradient.Parent = line
		halves[index] = gradient
		lit[index] = line
	end
	-- The disc: cooling while it charges, the bright gold over it while it's ready, its lit curve from below.
	local cool = plate(frame, "Cool", "Cool", size, 4)
	local ready = plate(frame, "Ready", "Gold", size, 5)
	local curveFrame = disc(ready, "Curve", size * p.Curve.Across, 3)
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
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.ZIndex = 6
	icon.Parent = frame
	local readyIcon = Instance.new("ImageLabel")
	readyIcon.Name = "ReadyIcon"
	readyIcon.BackgroundTransparency = 1
	readyIcon.BorderSizePixel = 0
	readyIcon.ZIndex = 7
	readyIcon.Parent = frame
	local count = Slate.Gold(frame, "Count", pt(p.Count))
	count.AnchorPoint = Vector2.new(0.5, 0.5)
	count.Position = UDim2.fromScale(0.5, 0.5)
	count.Size = UDim2.fromScale(1, 1)
	count.ZIndex = 8
	count.Visible = false
	frame.Parent = parent
	return {
		Frame = frame,
		Scale = scale,
		Cool = cool,
		Ready = ready,
		Glass = cool:FindFirstChild("Glass") :: Frame,
		Gold = ready:FindFirstChild("Glass") :: Frame,
		Curve = curve,
		TrackInk = trackInk,
		Track = track,
		Halves = halves,
		Lit = lit,
		Icon = icon,
		ReadyIcon = readyIcon,
		Count = count,
	}
end

-- The signature's own icon, charging and ready; or, with none drawn yet, its class's glyph in white and in ink. Both
-- `p.Icon` page points across, centred on the disc.
local function icons(piece: Piece, action: string, class: string)
	local config = HudConfig.Readout
	local p = press()
	local key = `{action}\0{class}\0{p.Icon}\0{p.Size}`
	if piece.Frame:GetAttribute("IconKey") == key then
		return
	end
	local own = config.Icons[action]
	local glyph = `Class{class}Glyph`
	local size, across = pt(p.Size), pt(p.Icon)
	local at = (size - across) / 2
	local ink = HudConfig.Slate.AccentInk
	if own and UIKit.Images[own] and UIKit.Images[own .. "Ready"] then
		local s = across / UIKit.Images[own].Points.X
		Skin.Set(piece.Icon, own, { X = at, Y = at, Scale = s })
		Skin.Set(piece.ReadyIcon, own .. "Ready", { X = at, Y = at, Scale = s })
		piece.Icon.ImageColor3 = Color3.new(1, 1, 1)
		piece.ReadyIcon.ImageColor3 = Color3.new(1, 1, 1)
		piece.Frame:SetAttribute("Icon", own)
	elseif UIKit.Images[glyph] then
		local s = across / UIKit.Images[glyph].Points.X
		for image, tint in { [piece.Icon] = HudConfig.Slate.Ink, [piece.ReadyIcon] = ink } do
			Skin.Set(image, glyph, { X = at, Y = at, Scale = s })
			image.ImageColor3 = tint
		end
		piece.Frame:SetAttribute("Icon", glyph)
	else
		return -- the lead's class isn't known yet: asked again next frame
	end
	piece.Frame:SetAttribute("IconKey", key)
end

-- The ring's colours and widths from the tokens, laid again only when one changes (a Tune, the next finish). The discs
-- are Slate plates: the kit's repaint lays theirs.
local function paint(piece: Piece)
	local c = HudConfig.Slate
	local p = c.Press
	local key = `{p.Track:ToHex()}{c.Sides.Gold.Ink:ToHex()}{c.Accent[2]:ToHex()}{p.Line}{p.TrackInk}{p.Ring}{p.Curve.Line}`
	if piece.Frame:GetAttribute("PaintKey") == key then
		return
	end
	piece.Frame:SetAttribute("PaintKey", key)
	piece.TrackInk.Color = c.Sides.Gold.Ink
	piece.TrackInk.Thickness = pt(p.TrackInk)
	piece.Track.Color = p.Track
	piece.Track.Thickness = pt(p.Line)
	for _, line in piece.Lit do
		line.Color = c.Accent[2]
		line.Thickness = pt(p.Line)
	end
	piece.Curve.Thickness = pt(p.Curve.Line)
end

function Readout.Step(piece: Piece, state: State)
	local config = HudConfig.Readout
	local p = press()
	paint(piece)
	icons(piece, state.Action, state.Class)
	local seen = math.clamp(state.Seen, 0, 1)
	-- The gold disc: whole while it's ready, and gone over the flash as it fires.
	local hot = if state.Full then 1 else math.clamp(state.Flash, 0, 1)
	local share = if state.Full then 1 else math.clamp(state.Share, 0, 1)
	Slate.Clear(piece.Cool, 1 - seen)
	Slate.Clear(piece.Ready, 1 - seen * hot)
	piece.Curve.Transparency = 1 - (1 - p.Curve.Clear) * seen * hot
	piece.Icon.ImageTransparency = 1 - seen * (1 - hot) * (1 - p.CoolIcon)
	piece.ReadyIcon.ImageTransparency = 1 - seen * hot
	-- The seconds left, whole, while it charges.
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
	-- The ring: its track dark, the share lit clockwise from the top (right half to 0.5, left half after).
	piece.TrackInk.Transparency = 1 - seen * (1 - p.TrackInkClear)
	piece.Track.Transparency = 1 - seen * (1 - p.RingClear)
	piece.Halves[1].Rotation = math.min(share, 0.5) * 360
	piece.Halves[2].Rotation = math.max(share, 0.5) * 360
	for _, line in piece.Lit do
		line.Transparency = if share > 0 then 1 - seen else 1
	end
	piece.Scale.Scale = 1 + config.Swell * state.Flash + config.ReadySwell * state.Swell + config.Pulse.Scale * (state.Pulse or 0)
		- config.Press * (state.Press or 0)
	piece.Frame:SetAttribute("Share", state.Share)
	piece.Frame:SetAttribute("Hot", hot)
end

return Readout
