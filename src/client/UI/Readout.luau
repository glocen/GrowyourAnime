--!strict
-- Readout (client): the signature's press, in B, Slate glass (AR62's piece 1, research's pick of 2026-11-26, 23:46;
-- Config.Hud.Slate.Press, UI.Kit.Slate): the one big press on the HUD, a disc the tap's size in the lead's corner, with
-- the lead's signature's own icon. Charging, the disc is the HUD's glass with the icon in white, and its charge runs
-- round it as a gold ring, clockwise from the top. Ready, the disc is gold with the icon in ink and the ring whole and
-- lit: the loudest piece on the HUD. As the move fires, the gold empties in a flash and the piece swells; ready again,
-- it swells once. A signature with no icon yet shows its class's glyph. The motion's numbers: Config.Hud.Readout.
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
	Glass: Frame, -- the disc while it charges
	Gold: Frame, -- and ready
	Track: UIStroke, -- the ring's unlit track
	Halves: { UIGradient }, -- the lit ring's right and left halves
	Lit: { UIStroke },
	Icon: ImageLabel,
	ReadyIcon: ImageLabel,
}

local Readout = {}

local pt = Slate.Pt
local STEP = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1),
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

local function ring(parent: Instance, name: string, size: number, z: number): (Frame, UIStroke)
	local made = disc(parent, name, size, z)
	made.BackgroundTransparency = 1
	local line = Instance.new("UIStroke")
	line.Name = "Line"
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Thickness = pt(press().Line)
	line.Parent = made
	return made, line
end

function Readout.new(parent: Instance): Piece
	local c = HudConfig.Slate
	local p = c.Press
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
	local across = size + 2 * pt(p.Ring)
	-- The ring's track, then its lit halves over it.
	local _, track = ring(frame, "Track", across, 1)
	track.Color = Color3.new(1, 1, 1)
	local halves: { UIGradient } = {}
	local lit: { UIStroke } = {}
	for index, side in { "Right", "Left" } do
		local half = Instance.new("Frame")
		half.Name = side
		half.BackgroundTransparency = 1
		half.ClipsDescendants = true
		half.AnchorPoint = Vector2.new(0.5, 0.5)
		half.Position = UDim2.fromScale(0.5, 0.5)
		-- a margin round the ring's box so its stroke, drawn outside the box, isn't clipped but at the middle line
		local room = across + 4 * pt(p.Line)
		half.Size = UDim2.fromOffset(room / 2, room)
		half.Position = UDim2.new(0.5, if side == "Right" then room / 4 else -room / 4, 0.5, 0)
		half.ZIndex = 2
		half.Parent = frame
		local whole, line = ring(half, "Ring", across, 2)
		whole.Position = UDim2.new(if side == "Right" then 0 else 1, 0, 0.5, 0)
		line.Color = c.Accent[1]
		local gradient = Instance.new("UIGradient")
		gradient.Name = "Share"
		gradient.Transparency = STEP
		gradient.Parent = line
		halves[index] = gradient
		lit[index] = line
	end
	-- The disc: the glass while it charges, gold over it while it's ready.
	local glass = disc(frame, "Plate", size, 3)
	glass.BackgroundColor3 = Color3.new(1, 1, 1)
	local tone = Instance.new("UIGradient")
	tone.Rotation = 90
	tone.Color = ColorSequence.new(c.Plate.Top, c.Plate.Foot)
	tone.Parent = glass
	local glassRim = Instance.new("UIStroke")
	glassRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glassRim.Color = c.Rim.Plain
	glassRim.Thickness = pt(1.2)
	glassRim.Parent = glass
	local gold = disc(frame, "Ready", size, 4)
	gold.BackgroundColor3 = Color3.new(1, 1, 1)
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new(c.Accent[1], c.Accent[2])
	shine.Parent = gold
	local goldRim = Instance.new("UIStroke")
	goldRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	goldRim.Color = Color3.new(1, 1, 1)
	goldRim.Thickness = pt(1.2)
	goldRim.Parent = gold
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.ZIndex = 5
	icon.Parent = frame
	local readyIcon = Instance.new("ImageLabel")
	readyIcon.Name = "ReadyIcon"
	readyIcon.BackgroundTransparency = 1
	readyIcon.BorderSizePixel = 0
	readyIcon.ZIndex = 6
	readyIcon.Parent = frame
	frame.Parent = parent
	return {
		Frame = frame,
		Scale = scale,
		Glass = glass,
		Gold = gold,
		Track = track,
		Halves = halves,
		Lit = lit,
		Icon = icon,
		ReadyIcon = readyIcon,
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

-- The press's colours and rims from the tokens, laid again only when one changes (a Tune, the finish's surface).
local function paint(piece: Piece)
	local c = HudConfig.Slate
	local p = c.Press
	local key = `{c.Plate.Top:ToHex()}{c.Plate.Foot:ToHex()}{c.Accent[1]:ToHex()}{c.Accent[2]:ToHex()}{c.Rim.Plain:ToHex()}{p.Rim}{p.Line}`
	if piece.Frame:GetAttribute("PaintKey") == key then
		return
	end
	piece.Frame:SetAttribute("PaintKey", key)
	local tone = piece.Glass:FindFirstChildOfClass("UIGradient")
	if tone then
		tone.Color = ColorSequence.new(c.Plate.Top, c.Plate.Foot)
	end
	local shine = piece.Gold:FindFirstChildOfClass("UIGradient")
	if shine then
		shine.Color = ColorSequence.new(c.Accent[1], c.Accent[2])
	end
	for _, disc in { piece.Glass, piece.Gold } do
		local rim = disc:FindFirstChildOfClass("UIStroke")
		if rim then
			rim.Thickness = pt(p.Rim)
			rim.Color = if disc == piece.Gold then Color3.new(1, 1, 1) else c.Rim.Plain
		end
	end
	piece.Track.Thickness = pt(p.Line)
	for _, line in piece.Lit do
		line.Color = c.Accent[1]
		line.Thickness = pt(p.Line)
	end
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
	local plate = HudConfig.Slate.Plate
	piece.Glass.BackgroundTransparency = 1 - seen * (1 - plate.Clear)
	piece.Gold.BackgroundTransparency = 1 - seen * hot
	for _, rim in { piece.Glass:FindFirstChildOfClass("UIStroke"), piece.Gold:FindFirstChildOfClass("UIStroke") } do
		if rim then
			rim.Transparency = 1 - seen * (if rim.Parent == piece.Gold then (1 - p.GoldRimClear) * hot else 1 - plate.RimClear)
		end
	end
	piece.Icon.ImageTransparency = 1 - seen * (1 - hot)
	piece.ReadyIcon.ImageTransparency = 1 - seen * hot
	-- The ring: its track faint, the share lit clockwise from the top (right half to 0.5, left half after).
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
