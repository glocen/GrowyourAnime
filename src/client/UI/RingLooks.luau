--!strict
-- The signature ring's looks in grey (TR13; docs/test-requests.md, TR13): three directions for the ring, judged at phone
-- size beside the current one and picked before Modulo's frames. Throwaway once one is picked. Each draws the same state
-- every frame (State): how full, whether it's ready, the flash since it fired, the swell since it became ready.
--   Rim:  the current ring given depth: a raised rim, a sunken well, and a bright head on the fill's leading edge. Ready, a
--         pulse rings out; fired, the well flashes.
--   Pool: the well itself fills from the bottom, a bright line at its level. Ready, a glint crosses it; fired, it drains
--         in a flash.
--   Pips: the ring in segments that light one by one, the next one filling and larger. Ready, a chase runs round them;
--         fired, they all flash and go dark.
--   RingLooks.new(name, size, weight, parent, caption) -> Look      RingLooks.Step(look, state)      RingLooks.Names
-- In the HUD's palette (Config.UIKit.Palettes.Graphite), with the builder's numbers (Config.Hud.Ring.Looks). Each look's
-- frame says what it drew (Share, and Head, Level or Lit), for the self-test.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Theme)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)

local GRAPHITE = UIKit.Palettes.Graphite
local WHITE = Color3.new(1, 1, 1)
local WELL = 0.2 -- the well's transparency shown

export type State = {
	Share: number, -- 0 to 1, how full
	Full: boolean,
	Flash: number, -- 1 as it fires, falling to 0 over Config.Hud.Ring.Flash
	Swell: number, -- 0 to 1 and back over Config.Hud.Ring.Ready, from the moment it's ready
	Since: number, -- seconds since it became ready (huge when long ago)
	Seen: number, -- 0 hidden to 1 shown
	Class: string, -- the lead's class, for the glyph
}

export type Look = {
	Name: string,
	Frame: Frame,
	Scale: UIScale,
	Glyph: ImageLabel,
	Size: number,
	Weight: number,
	Parts: { [string]: any },
}

local RingLooks = {}

RingLooks.Names = { "Rim", "Pool", "Pips" }

function RingLooks.Has(name: string): boolean
	return table.find(RingLooks.Names, name) ~= nil
end

local function round(name: string, diameter: number, z: number, parent: Instance): Frame
	local disc = Instance.new("Frame")
	disc.Name = name
	disc.BackgroundTransparency = 1
	disc.BorderSizePixel = 0
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Position = UDim2.fromScale(0.5, 0.5)
	disc.Size = UDim2.fromOffset(diameter, diameter)
	disc.ZIndex = z
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = disc
	disc.Parent = parent
	return disc
end

local function stroke(disc: Frame, colour: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = colour
	s.Thickness = thickness
	s.Parent = disc
	return s
end

local function gradient(parent: Instance, rotation: number): UIGradient
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Parent = parent
	return g
end

-- A raised rim: lit from the top, dark at the foot.
local function rim(holder: Frame, size: number, weight: number)
	local disc = round("Rim", size + 2 * weight, 1, holder)
	local s = stroke(disc, WHITE, 2)
	local g = gradient(s, 90)
	g.Color = ColorSequence.new(GRAPHITE.Glint, GRAPHITE.Edge)
end

-- A sunken well: darker under its top edge, as if lit from above.
local function well(holder: Frame, size: number): Frame
	local disc = round("Well", size, 1, holder)
	disc.BackgroundColor3 = WHITE
	disc.BackgroundTransparency = WELL
	local g = gradient(disc, 90)
	g.Color = ColorSequence.new(GRAPHITE.Channel, GRAPHITE.Ground)
	return disc
end

-- Sorted keypoints from (time, value) pairs: times clamped into 0 to 1 and kept strictly rising, the ends at 0 and 1.
local function sorted(points: { { any } }): { { any } }
	local out: { { any } } = {}
	local last = -1
	for _, p in points do
		local t = math.clamp(p[1], 0, 1)
		if t <= last then
			t = last + 1e-4
		end
		if t > 1 then
			break
		end
		table.insert(out, { t, p[2] })
		last = t
	end
	out[1][1] = 0
	if out[#out][1] < 1 then
		table.insert(out, { 1, out[#out][2] })
	else
		out[#out][1] = 1
	end
	return out
end

local function numbers(points: { { any } }): NumberSequence
	local keys = {}
	for _, p in sorted(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function colours(points: { { any } }): ColorSequence
	local keys = {}
	for _, p in sorted(points) do
		table.insert(keys, ColorSequenceKeypoint.new(p[1], p[2]))
	end
	return ColorSequence.new(keys)
end

-- The fill's two halves, as the current ring's: each clips a disc whose stroke's gradient turns its light in.
local function halves(holder: Frame, weight: number, colour: Color3): ({ UIGradient }, { UIStroke })
	local turns, strokes = {}, {}
	for side = 0, 1 do
		local clip = Instance.new("Frame")
		clip.Name = if side == 0 then "LeftHalf" else "RightHalf"
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Size = UDim2.fromScale(0.5, 1) -- the current ring's own geometry (HudController, signatureRing)
		clip.Position = UDim2.fromScale(side * 0.5, 0)
		clip.ZIndex = 2
		clip.Parent = holder
		local disc = Instance.new("Frame")
		disc.Name = "Light"
		disc.BackgroundTransparency = 1
		disc.Size = UDim2.fromScale(2, 1)
		disc.Position = UDim2.fromScale(-side, 0)
		disc.ZIndex = 2
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = disc
		local s = stroke(disc, colour, weight)
		local g = gradient(s, 0)
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.501, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		disc.Parent = clip
		table.insert(turns, g)
		table.insert(strokes, s)
	end
	return turns, strokes
end

local function fill(turns: { UIGradient }, share: number)
	local a = math.clamp(share * 360, 0, 180)
	local b = math.clamp(share * 360 - 180, 0, 180)
	turns[1].Rotation = 180 + b
	turns[2].Rotation = a
end

local BUILD: { [string]: (Look) -> () } = {}
local STEP: { [string]: (Look, State, (number) -> number) -> () } = {}

-- Rim ---------------------------------------------------------------------------------------------------------------

BUILD.Rim = function(look: Look)
	local s, w, holder = look.Size, look.Weight, look.Frame
	rim(holder, s, w)
	local channel = round("Channel", s, 1, holder)
	stroke(channel, GRAPHITE.Channel, w)
	look.Parts.Well = well(holder, s)
	look.Parts.Turns, look.Parts.Strokes = halves(holder, w, GRAPHITE.Accent)
	local config = HudConfig.Ring.Looks.Rim
	local glow = round("HeadGlow", config.Head * 2, 4, holder)
	glow.BackgroundColor3 = GRAPHITE.Accent
	local head = round("Head", config.Head, 5, holder)
	head.BackgroundColor3 = WHITE
	look.Parts.Glow, look.Parts.Head = glow, head
	local pulse = round("Pulse", s + 2 * w, 3, holder)
	look.Parts.Pulse = stroke(pulse, GRAPHITE.Accent, 2)
	look.Parts.PulseDisc = pulse
end

STEP.Rim = function(look: Look, state: State, faded: (number) -> number)
	local config, ring = HudConfig.Ring.Looks.Rim, HudConfig.Ring
	local s, w = look.Size, look.Weight
	fill(look.Parts.Turns, state.Share)
	for _, st in look.Parts.Strokes do
		st.Color = GRAPHITE.Accent:Lerp(WHITE, math.max(state.Flash, state.Swell))
		st.Transparency = faded(0)
	end
	-- The head rides the fill's leading edge, on the light's middle line, while it fills.
	local angle = state.Share * 2 * math.pi
	local r = s / 2 + w / 2
	local at = UDim2.new(0.5, r * math.sin(angle), 0.5, -r * math.cos(angle))
	local filling = state.Share > 0.01 and not state.Full
	look.Parts.Head.Position, look.Parts.Glow.Position = at, at
	look.Parts.Head.BackgroundTransparency = faded(if filling then 0 else 1)
	look.Parts.Glow.BackgroundTransparency = faded(if filling then 0.6 else 1)
	look.Frame:SetAttribute("Head", if filling then math.deg(angle) else -1)
	-- Fired, the well flashes white; ready, a pulse rings out from the rim.
	local wellDisc = look.Parts.Well :: Frame
	local g = wellDisc:FindFirstChildOfClass("UIGradient") :: UIGradient
	g.Color = ColorSequence.new(GRAPHITE.Channel:Lerp(WHITE, state.Flash), GRAPHITE.Ground:Lerp(WHITE, state.Flash))
	wellDisc.BackgroundTransparency = faded(WELL * (1 - state.Flash))
	local u = state.Since / math.max(ring.Ready, 0.01)
	local pulsing = u < 1
	local grow = (s + 2 * w) * (1 + (config.Pulse - 1) * (if pulsing then u else 0))
	look.Parts.PulseDisc.Size = UDim2.fromOffset(grow, grow)
	look.Parts.Pulse.Transparency = faded(if pulsing then u else 1)
	look.Scale.Scale = 1 + 0.15 * state.Flash + 0.08 * state.Swell
end

-- Pool --------------------------------------------------------------------------------------------------------------

BUILD.Pool = function(look: Look)
	local s, w, holder = look.Size, look.Weight, look.Frame
	rim(holder, s, w)
	local channel = round("Channel", s, 1, holder)
	look.Parts.Channel = stroke(channel, GRAPHITE.Channel, w)
	well(holder, s)
	local pool = round("Pool", s, 2, holder)
	pool.BackgroundColor3 = WHITE
	pool.BackgroundTransparency = 0
	look.Parts.Pool = pool
	look.Parts.Level = gradient(pool, 90) -- top to bottom
	local glint = round("Glint", s, 4, holder)
	glint.BackgroundColor3 = WHITE
	glint.BackgroundTransparency = 0
	look.Parts.Glint = gradient(glint, 45)
	look.Parts.GlintDisc = glint
	local flash = round("Flash", s, 4, holder)
	flash.BackgroundColor3 = WHITE
	look.Parts.Flash = flash
end

STEP.Pool = function(look: Look, state: State, faded: (number) -> number)
	local config, ring = HudConfig.Ring.Looks.Pool, HudConfig.Ring
	local level = 1 - math.clamp(state.Share, 0, 1) -- where the pool's top stands, from the top
	local shown = faded(0.1)
	local band = config.Band
	look.Parts.Level.Transparency = if state.Share <= 0.005 then NumberSequence.new(1)
		elseif state.Share >= 0.995 then NumberSequence.new(shown)
		else numbers({ { 0, 1 }, { level - 1e-3, 1 }, { level, shown }, { 1, shown } })
	look.Parts.Level.Color = colours({
		{ 0, GRAPHITE.Accent },
		{ level, if state.Full then GRAPHITE.Accent else WHITE },
		{ level + band, GRAPHITE.Accent },
		{ 1, GRAPHITE.Facet:Lerp(GRAPHITE.Accent, 0.5) },
	})
	look.Frame:SetAttribute("Level", state.Share)
	look.Parts.Channel.Transparency = faded(0)
	-- Ready, a glint crosses it once; fired, a white flash as it drains.
	local u = state.Since / math.max(ring.Ready, 0.01)
	if u < 1 then
		local c = -0.2 + 1.4 * u
		look.Parts.Glint.Transparency = numbers({ { 0, 1 }, { c - 0.12, 1 }, { c, faded(0.15) }, { c + 0.12, 1 }, { 1, 1 } })
		look.Parts.GlintDisc.Visible = true
	else
		look.Parts.GlintDisc.Visible = false
	end
	look.Parts.Flash.BackgroundTransparency = faded(1 - state.Flash)
	look.Glyph.ImageColor3 = if state.Full then GRAPHITE.Channel else GRAPHITE.Text
	look.Scale.Scale = 1 + 0.15 * state.Flash + 0.08 * state.Swell
end

-- Pips --------------------------------------------------------------------------------------------------------------

BUILD.Pips = function(look: Look)
	local s, w, holder = look.Size, look.Weight, look.Frame
	local config = HudConfig.Ring.Looks.Pips
	well(holder, s)
	local pips = {}
	local r = s / 2 + w / 2
	for i = 1, config.Count do
		local angle = (i - 0.5) / config.Count * 2 * math.pi
		local pip = Instance.new("Frame")
		pip.Name = `Pip{i}`
		pip.BorderSizePixel = 0
		pip.AnchorPoint = Vector2.new(0.5, 0.5)
		pip.Position = UDim2.new(0.5, r * math.sin(angle), 0.5, -r * math.cos(angle))
		pip.Size = UDim2.fromOffset(config.Long, config.Short)
		pip.Rotation = math.deg(angle)
		pip.ZIndex = 3
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = pip
		stroke(pip, GRAPHITE.Edge, 1)
		pip.Parent = holder
		table.insert(pips, pip)
	end
	look.Parts.Pips = pips
end

STEP.Pips = function(look: Look, state: State, faded: (number) -> number)
	local config, ring = HudConfig.Ring.Looks.Pips, HudConfig.Ring
	local n = config.Count
	local lit = math.clamp(state.Share, 0, 1) * n
	local whole = math.floor(lit + 1e-6)
	-- Ready, a chase runs round once: each pip flares white as it passes.
	local u = state.Since / math.max(ring.Ready, 0.01)
	for i, pip in look.Parts.Pips :: { Frame } do
		local on = if i <= whole then 1 elseif i == whole + 1 then lit - whole else 0
		local leading = i == whole + 1 and on > 0
		local chase = if u < 1 then math.max(0, 1 - math.abs(u * (n + 1) - i)) else 0
		local hot = math.max(state.Flash, chase)
		pip.BackgroundColor3 = GRAPHITE.Channel:Lerp(GRAPHITE.Accent, on):Lerp(WHITE, hot)
		pip.BackgroundTransparency = faded(0)
		local grow = 1 + (if leading then 0.25 else 0) + 0.3 * chase
		pip.Size = UDim2.fromOffset(config.Long * grow, config.Short * grow)
		local edge = pip:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Transparency = faded(0)
		end
	end
	look.Frame:SetAttribute("Lit", whole)
	look.Scale.Scale = 1 + 0.12 * state.Flash + 0.06 * state.Swell
end

-- The looks ---------------------------------------------------------------------------------------------------------

-- A look `name`, `size` authored pixels across with its light `weight` wide, under `parent`; with its name under it when
-- `caption` (beside the ring, for the comparison).
function RingLooks.new(name: string, size: number, weight: number, parent: Instance, caption: boolean): Look
	assert(BUILD[name], `no ring look "{name}"`)
	local frame = Instance.new("Frame")
	frame.Name = `Look{name}`
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(size, size)
	frame:SetAttribute("Look", name)
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local glyph = Skin.Icon(frame, "ClassWarriorGlyph", size / 2, size / 2, size * 0.5, GRAPHITE.Text, 6)
	glyph.Name = "Glyph"
	local look: Look = { Name = name, Frame = frame, Scale = scale, Glyph = glyph, Size = size, Weight = weight, Parts = {} }
	BUILD[name](look)
	if caption then
		local label = Text.new({
			Name = "Caption",
			Size = Theme.Text.Caption,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.new(1, 24, 0, 16),
			Position = UDim2.new(0.5, 0, 1, weight + 6),
			AnchorPoint = Vector2.new(0.5, 0),
			Parent = frame,
		})
		label.Text = name
	end
	frame.Parent = parent
	return look
end

function RingLooks.Step(look: Look, state: State)
	local seen = math.clamp(state.Seen, 0, 1)
	local function faded(transparency: number): number
		return 1 - (1 - transparency) * seen
	end
	local kit = `Class{state.Class}Glyph`
	local image = UIKit.Images[kit]
	if image and look.Glyph:GetAttribute("Kit") ~= kit then
		look.Glyph.Image = image.Id
		look.Glyph:SetAttribute("Kit", kit)
	end
	look.Glyph.ImageTransparency = faded(if state.Full then 0 else 0.55)
	local caption = look.Frame:FindFirstChild("Caption")
	if caption and caption:IsA("TextLabel") then
		caption.TextTransparency = faded(0)
	end
	look.Frame:SetAttribute("Share", state.Share)
	STEP[look.Name](look, state, faded)
end

return RingLooks
