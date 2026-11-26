--!strict
-- Slate (client kit): AR62's piece 1, the fight's HUD in B, Slate glass (research's pick, 2026-11-26, 23:46; Config.Hud
-- .Slate; build/handoff/UI/hud_overhaul/piece1_fight/B_*.png). Its pieces from the engine's own shapes, no image: a plate
-- of blue-grey glass (a gradient top to foot, nearly solid, rounded, a fine rim by side, a lit hairline inside its top,
-- a soft lift and a depth lip under it), a bar in its dark well, a number on a bar in its dark stroke, a word in its face,
-- a gold piece. The target's numbers are page points, Slate.Pt's authored points times Config.Hud.Slate.Page (the style
-- frames' 1.28: the page is the small phone at 1.5, which the layer draws at 0.85). Every surface value is a token in
-- Config.Hud.Slate, read when a piece is painted: each piece is tagged, and Repaint lays the tokens again, so a Tune, or
-- the finish's new surface, shows without a rebuild (research, 2026-11-27, 00:04).
--   Slate.Pt(page) -> authored                         a target's page points in the HUD's authored points
--   Slate.Plate(parent, name, size, side, radius?)     a plate, a holder its content joins at ZIndex 3 and up: side
--                                                      "Yours", "Theirs", "Elite" or "Plain" picks its rim
--   Slate.Side(plate, side)                             its rim by side
--   Slate.Bar(parent, name, position, size, colours, radius?)   a bar's well and its light (Slate.Fill)
--   Slate.Fill(bar, share)                              the light's share, 0 to 1 (its "Share" attribute)
--   Slate.Shape(bar, position, size)                    a bar laid again: its share kept
--   Slate.OnBar(bar, size)                              a number on a bar: white in the dark stroke, centred
--   Slate.Word(parent, name, size, colour?)             a word in the Slate's face, its soft shade round it, left aligned
--   Slate.Taken(parent, name)                           the lead's damage taken: coral in its dark stroke, its foot centre
--   Slate.Fade(label, transparency)                     a word and its stroke faded together
--   Slate.Gold(frame)                                   the accent's gold on a frame, its fine rim round it
--   Slate.Repaint(root)                                 every piece under `root` in the tokens now

local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local Text = require(script.Parent.Text)

local Slate = {}

local PLATE, BAR, WORD, GOLD = "NL_SlatePlate", "NL_SlateBar", "NL_SlateWord", "NL_SlateGold"

local function config(): any
	return HudConfig.Slate
end

local function corner(parent: Instance, radius: number)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = parent
end

local function sequence(colours: { Color3 } | Color3): ColorSequence
	if typeof(colours) == "Color3" then
		return ColorSequence.new(colours)
	end
	local pair = colours :: { Color3 }
	local top: Color3, foot: Color3 = pair[1], pair[2] or pair[1]
	return ColorSequence.new(top, foot)
end

function Slate.Pt(page: number): number
	return page / config().Page
end

local function face(): Font
	return Font.new(config().Face, Enum.FontWeight.Bold)
end

local function paintPlate(plate: Frame)
	local c = config().Plate
	local glass = plate:FindFirstChild("Glass") :: Frame?
	if glass == nil then
		return
	end
	glass.BackgroundColor3 = Color3.new(1, 1, 1)
	glass.BackgroundTransparency = c.Clear
	local tone = glass:FindFirstChild("Tone") :: UIGradient?
	if tone then
		local want = ColorSequence.new(c.Top, c.Foot)
		if tone.Color ~= want then
			tone.Color = want
		end
	end
	local rim = glass:FindFirstChild("Rim") :: UIStroke?
	if rim then
		local side = plate:GetAttribute("Side")
		rim.Color = config().Rim[if type(side) == "string" then side else "Plain"] or config().Rim.Plain
		rim.Thickness = c.Rim
		rim.Transparency = c.RimClear
	end
	local hair = glass:FindFirstChild("Hairline") :: Frame?
	if hair then
		hair.BackgroundColor3 = c.Hairline
		hair.BackgroundTransparency = c.HairlineClear
		hair.Position = UDim2.new(0.5, 0, 0, c.Rim)
	end
	local lift = plate:FindFirstChild("Lift") :: Frame?
	if lift then
		lift.BackgroundTransparency = c.Lift
		lift.Position = UDim2.fromOffset(0, c.LiftDown)
	end
	local lip = plate:FindFirstChild("Lip") :: Frame?
	if lip then
		lip.BackgroundColor3 = c.Lip
		lip.BackgroundTransparency = c.LipClear
		lip.Position = UDim2.fromOffset(0, c.LipDown)
	end
end

-- The plate's holder: the lift and the lip (ZIndex 1) and the glass (2) inside it, its content over them.
function Slate.Plate(parent: Instance, name: string, size: Vector2, side: string, radius: number?): Frame
	local r = radius or config().Plate.Radius
	local plate = Instance.new("Frame")
	plate.Name = name
	plate.BackgroundTransparency = 1
	plate.BorderSizePixel = 0
	plate.Size = UDim2.fromOffset(size.X, size.Y)
	plate:SetAttribute("Side", side)
	for _, under in { "Lift", "Lip" } do
		local made = Instance.new("Frame")
		made.Name = under
		made.BorderSizePixel = 0
		made.BackgroundColor3 = Color3.new(0, 0, 0)
		made.Size = UDim2.fromScale(1, 1)
		made.ZIndex = 1
		corner(made, r)
		made.Parent = plate
	end
	local glass = Instance.new("Frame")
	glass.Name = "Glass"
	glass.BorderSizePixel = 0
	glass.Size = UDim2.fromScale(1, 1)
	glass.ZIndex = 2
	corner(glass, r)
	local tone = Instance.new("UIGradient")
	tone.Name = "Tone"
	tone.Rotation = 90 -- top to foot
	tone.Parent = glass
	local rim = Instance.new("UIStroke")
	rim.Name = "Rim"
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.LineJoinMode = Enum.LineJoinMode.Round
	rim.Parent = glass
	-- The lit hairline inside the top, between the corners.
	local hair = Instance.new("Frame")
	hair.Name = "Hairline"
	hair.BorderSizePixel = 0
	hair.AnchorPoint = Vector2.new(0.5, 0)
	hair.Size = UDim2.new(1, -2 * r, 0, 1)
	hair.Parent = glass
	glass.Parent = plate
	CollectionService:AddTag(plate, PLATE)
	paintPlate(plate)
	plate.Parent = parent
	return plate
end

function Slate.Side(plate: Frame, side: string)
	if plate:GetAttribute("Side") ~= side then
		plate:SetAttribute("Side", side)
		paintPlate(plate)
	end
end

local function paintBar(bar: Frame)
	local c = config()
	bar.BackgroundColor3 = c.Well.Colour
	bar.BackgroundTransparency = c.Well.Clear
	local light = bar:FindFirstChild("Light")
	local sheen = if light then light:FindFirstChild("Sheen") :: Frame? else nil
	if sheen then
		sheen.Visible = bar.Size.Y.Offset >= Slate.Pt(c.Bar.SheenFrom)
		sheen.BackgroundTransparency = c.Bar.Sheen
		sheen.Size = UDim2.new(1, -3, c.Bar.SheenTall, 0)
	end
end

function Slate.Bar(parent: Instance, name: string, position: Vector2, size: Vector2, colours: { Color3 } | Color3, radius: number?): Frame
	local r = radius or size.Y / 2
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.BorderSizePixel = 0
	bar.Position = UDim2.fromOffset(position.X, position.Y)
	bar.Size = UDim2.fromOffset(size.X, size.Y)
	corner(bar, r)
	local light = Instance.new("Frame")
	light.Name = "Light"
	light.BorderSizePixel = 0
	light.BackgroundColor3 = Color3.new(1, 1, 1)
	light.Size = UDim2.fromScale(1, 1)
	corner(light, r)
	local shade = Instance.new("UIGradient")
	shade.Name = "Shade"
	shade.Rotation = 90
	shade.Color = sequence(colours)
	shade.Parent = light
	light.Parent = bar
	-- A sheen along the light's top, on a bar tall enough to show one.
	local sheen = Instance.new("Frame")
	sheen.Name = "Sheen"
	sheen.BorderSizePixel = 0
	sheen.BackgroundColor3 = Color3.new(1, 1, 1)
	sheen.Position = UDim2.fromOffset(1.5, 1)
	corner(sheen, math.max(1, size.Y * 0.16))
	sheen.Parent = light
	bar:SetAttribute("Share", -1)
	CollectionService:AddTag(bar, BAR)
	paintBar(bar)
	bar.Parent = parent
	Slate.Fill(bar, 0)
	return bar
end

-- The light's share: its width, never under its own round ends while it shows.
function Slate.Fill(bar: Frame, share: number)
	local clamped = math.clamp(if share == share then share else 0, 0, 1)
	if bar:GetAttribute("Share") == clamped then
		return
	end
	bar:SetAttribute("Share", clamped)
	local light = bar:FindFirstChild("Light") :: Frame
	light.Visible = clamped > 0
	local w, h = bar.Size.X.Offset, bar.Size.Y.Offset
	light.Size = UDim2.fromOffset(math.max(w * clamped, h), h)
end

function Slate.Shape(bar: Frame, position: Vector2, size: Vector2)
	bar.Position = UDim2.fromOffset(position.X, position.Y)
	if bar.Size.X.Offset ~= size.X or bar.Size.Y.Offset ~= size.Y then
		bar.Size = UDim2.fromOffset(size.X, size.Y)
		local share = bar:GetAttribute("Share")
		bar:SetAttribute("Share", -1)
		Slate.Fill(bar, if type(share) == "number" and share >= 0 then share else 0)
		paintBar(bar)
	end
end

local function paintWord(label: TextLabel)
	local c = config()
	local want = face()
	if label.FontFace ~= want then
		label.FontFace = want
	end
	local stroke = label:FindFirstChild("Stroke") :: UIStroke?
	if stroke == nil then
		return
	end
	stroke.Color = c.Shade
	local role = label:GetAttribute("Role")
	if role == "Taken" then
		label.TextColor3 = c.Taken.Colour
		stroke.Color = c.Taken.Stroke
		stroke.Transparency = label.TextTransparency
		stroke.Thickness = Slate.Pt(c.Taken.Line)
	elseif role == "OnBar" then
		stroke.Transparency = 0
		stroke.Thickness = math.max(1, (Text.Authored(label) or label.TextSize) * c.Text.OnBar)
	else
		stroke.Transparency = c.Text.Shade
		stroke.Thickness = c.Text.ShadeLine
	end
end

local function word(parent: Instance, name: string, size: number, colour: Color3, role: string): TextLabel
	local label = Text.new({
		Name = name,
		Size = size,
		Font = face(),
		Colour = colour,
		Parent = parent,
	})
	label:SetAttribute("Role", role)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	CollectionService:AddTag(label, WORD)
	paintWord(label)
	return label
end

function Slate.OnBar(bar: Frame, size: number): TextLabel
	local label = word(bar, "Value", size, config().Ink, "OnBar")
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.ZIndex = bar.ZIndex + 2
	return label
end

function Slate.Word(parent: Instance, name: string, size: number, colour: Color3?): TextLabel
	return word(parent, name, size, colour or config().Ink, "Word")
end

-- The lead's damage taken (Config.Hud.Slate.Taken): coral in its dark stroke, centred on its place.
function Slate.Taken(parent: Instance, name: string): TextLabel
	local c = config().Taken
	local label = word(parent, name, Slate.Pt(c.Size), c.Colour, "Taken")
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.AnchorPoint = Vector2.new(0.5, 1)
	return label
end

-- A Taken word's stroke fades with its text (the kit's repaint keeps them together).
function Slate.Fade(label: TextLabel, transparency: number)
	label.TextTransparency = transparency
	local stroke = label:FindFirstChild("Stroke") :: UIStroke?
	if stroke then
		stroke.Transparency = transparency
	end
end

local function paintGold(frame: Frame)
	local c = config()
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	local gold = frame:FindFirstChild("Gold") :: UIGradient?
	if gold and frame:GetAttribute("Lit") == nil then -- a pop lifting it toward white paints it itself (LeadCard.Glow)
		gold.Color = sequence(c.Accent)
	end
	local line = frame:FindFirstChild("GoldRim") :: UIStroke?
	if line then
		line.Color = c.Rim.Plain
		line.Transparency = c.Plate.RimClear
		line.Thickness = Slate.Pt(c.Badge.Line)
	end
end

function Slate.Gold(frame: Frame)
	local gold = Instance.new("UIGradient")
	gold.Name = "Gold"
	gold.Rotation = 90
	gold.Parent = frame
	local line = Instance.new("UIStroke")
	line.Name = "GoldRim"
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = frame
	CollectionService:AddTag(frame, GOLD)
	paintGold(frame)
end

function Slate.Repaint(root: Instance)
	for tag, paint in { [PLATE] = paintPlate, [BAR] = paintBar, [GOLD] = paintGold } :: { [string]: (Frame) -> () } do
		for _, piece in CollectionService:GetTagged(tag) do
			if piece:IsA("Frame") and piece:IsDescendantOf(root) then
				paint(piece)
			end
		end
	end
	for _, label in CollectionService:GetTagged(WORD) do
		if label:IsA("TextLabel") and label:IsDescendantOf(root) then
			paintWord(label)
		end
	end
end

return Slate
