--!strict
-- Readout (client): the signature's readout (AR12, V2 Block; docs/asset-requests.md, "The readout and the eye, redrawn
-- as one family"; hud_colour.json's pieces.readout): a plate cut like the dock's buttons, in the lead's corner, holding
-- the lead's signature's own icon. Charging, its well fills from the foot like a conduit, its front leaning as the bars
-- do: the well's own shape under one gradient that carries the light's colour and how solid it is, moved to move the
-- level (Rules.Hud.FrontTurn, FrontAt, FrontOffset). A box clip isn't used: it would let the light out past the plate's
-- two cut corners. Ready, the whole plate is white-hot with its glow and the icon dark on the light: the loudest piece
-- on the HUD. As the move fires, the ready plate empties in a flash and the piece swells; ready again, it swells once.
-- A signature with no icon yet shows its class's glyph. The numbers: Config.Hud.Readout, tuned live.
--   Readout.new(parent)              the piece, hidden
--   Readout.Step(piece, state)       draws a state: how full, the flash, the swell, how far it's faded in, whose icon

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Hud = require(Shared.Rules.Hud)
local Skin = require(script.Parent.Kit.Skin)

export type State = {
	Share: number, -- 0 to 1 of the cooldown
	Full: boolean,
	Flash: number, -- 1 as it fires, to 0
	Swell: number, -- 0 to 1 and back, once, as it's ready again
	Seen: number, -- 0 hidden to 1 shown
	Action: string, -- the signature's id
	Class: string, -- the lead's class, for a signature with no icon yet
}

export type Piece = {
	Frame: Frame,
	Scale: UIScale,
	Charging: { ImageLabel }, -- the plate, the light, the face
	Light: ImageLabel,
	Front: UIGradient,
	Icon: ImageLabel,
	Ready: ImageLabel,
	ReadyIcon: ImageLabel,
	Key: string, -- the gradient's numbers it was last built from
}

local Readout = {}

-- The gradient from Config.Hud.Readout's stops: built again only when a number changes (they're tuned live).
local function front(piece: Piece)
	local config = HudConfig.Readout
	local well = config.Well
	local side = well[4] - well[2]
	local parts = { tostring(config.Lean), tostring(side) }
	for _, stop in config.Front do
		table.insert(parts, `{stop.Below},{stop.Solid},{stop.Colour:ToHex()}`)
	end
	local key = table.concat(parts, ";")
	if piece.Key == key then
		return
	end
	piece.Key = key
	local turn, length = Hud.FrontTurn(side, config.Lean)
	local colours: { ColorSequenceKeypoint } = {}
	local solid: { NumberSequenceKeypoint } = {}
	local last = -1
	local stops = config.Front
	local function add(at: number, colour: Color3, how: number)
		local t = math.clamp(math.max(at, last + 1e-3), 0, 1) -- keypoints stand in order, never two at one time
		if t <= last then
			return
		end
		last = t
		table.insert(colours, ColorSequenceKeypoint.new(t, colour))
		table.insert(solid, NumberSequenceKeypoint.new(t, 1 - how))
	end
	-- Nothing shows above the front; the last stop holds down to the foot.
	add(0, stops[1].Colour, stops[1].Solid)
	for _, stop in stops do
		local at = Hud.FrontAt(stop.Below, length)
		if at > 0 and at < 1 then
			add(at, stop.Colour, stop.Solid)
		end
	end
	local final = stops[#stops]
	if last < 1 then
		-- hold the last stop to the end
		table.insert(colours, ColorSequenceKeypoint.new(1, final.Colour))
		table.insert(solid, NumberSequenceKeypoint.new(1, 1 - final.Solid))
	end
	piece.Front.Rotation = turn
	piece.Front.Color = ColorSequence.new(colours)
	piece.Front.Transparency = NumberSequence.new(solid)
end

function Readout.new(parent: Instance): Piece
	local config = HudConfig.Readout
	local frame = Instance.new("Frame")
	frame.Name = "Signature"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(config.Size, config.Size)
	frame.AnchorPoint = Vector2.new(0.5, 0.5) -- it swells about its middle
	frame.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local plate = Skin.Lay(frame, "ReadoutPlate", { Name = "Plate", X = 0, Y = 0, Z = 1 })
	local light = Skin.Lay(frame, "ReadoutLight", { Name = "Light", X = config.Well[1], Y = config.Well[2], Z = 2 })
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Front"
	gradient.Parent = light
	local face = Skin.Lay(frame, "ReadoutFace", { Name = "Face", X = 0, Y = 0, Z = 3 })
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.ZIndex = 4
	icon.Parent = frame
	local ready = Skin.Lay(frame, "ReadoutReady", { Name = "Ready", X = 0, Y = 0, Z = 5 })
	local readyIcon = Instance.new("ImageLabel")
	readyIcon.Name = "ReadyIcon"
	readyIcon.BackgroundTransparency = 1
	readyIcon.BorderSizePixel = 0
	readyIcon.ZIndex = 6
	readyIcon.Parent = frame
	frame.Parent = parent
	local piece: Piece = {
		Frame = frame,
		Scale = scale,
		Charging = { plate, light, face },
		Light = light,
		Front = gradient,
		Icon = icon,
		Ready = ready,
		ReadyIcon = readyIcon,
		Key = "",
	}
	front(piece)
	return piece
end

-- The signature's own icon, charging and ready; or, with none drawn yet, its class's glyph in light and in ink.
local function icons(piece: Piece, action: string, class: string)
	local config = HudConfig.Readout
	local key = `{action}\0{class}\0{config.Glyph}`
	if piece.Frame:GetAttribute("IconKey") == key then
		return
	end
	local own = config.Icons[action]
	local glyph = `Class{class}Glyph`
	if own and UIKit.Images[own] and UIKit.Images[own .. "Ready"] then
		Skin.Set(piece.Icon, own, { X = 0, Y = 0 })
		Skin.Set(piece.ReadyIcon, own .. "Ready", { X = 0, Y = 0 })
		piece.Icon.ImageColor3 = Color3.new(1, 1, 1)
		piece.ReadyIcon.ImageColor3 = Color3.new(1, 1, 1)
		piece.Frame:SetAttribute("Icon", own)
	elseif UIKit.Images[glyph] then
		local across = config.Size * config.Glyph
		local s = across / UIKit.Images[glyph].Points.X
		local at = (config.Size - across) / 2
		for image, tint in { [piece.Icon] = UIKit.Light, [piece.ReadyIcon] = config.Ink } do
			Skin.Set(image, glyph, { X = at, Y = at, Scale = s })
			image.ImageColor3 = tint
		end
		piece.Frame:SetAttribute("Icon", glyph)
	else
		return -- the lead's class isn't known yet: asked again next frame
	end
	piece.Frame:SetAttribute("IconKey", key)
end

function Readout.Step(piece: Piece, state: State)
	local config = HudConfig.Readout
	front(piece)
	icons(piece, state.Action, state.Class)
	local seen = math.clamp(state.Seen, 0, 1)
	-- The white-hot plate: whole while it's ready, and gone over the flash as it fires.
	local hot = if state.Full then 1 else math.clamp(state.Flash, 0, 1)
	for _, image in piece.Charging do
		image.ImageTransparency = 1 - seen
	end
	piece.Icon.ImageTransparency = 1 - seen * (1 - hot)
	piece.Ready.ImageTransparency = 1 - seen * hot
	piece.ReadyIcon.ImageTransparency = 1 - seen * hot
	piece.Front.Offset = Vector2.new(Hud.FrontOffset(state.Share, config.Travel), 0)
	piece.Scale.Scale = 1 + config.Swell * state.Flash + config.ReadySwell * state.Swell
	piece.Frame:SetAttribute("Share", state.Share)
	piece.Frame:SetAttribute("Hot", hot)
end

return Readout
