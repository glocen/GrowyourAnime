--!strict
-- Slate (client kit): the surface of AR62's piece 1, the fight's HUD, in F2's finish (research's pick of 2026-11-27, 00:36;
-- Config.Hud.Slate; build/handoff/UI/hud_overhaul/piece1_finish/F2_*.png, the construction from
-- docs/research/anime-crusaders-ui-surface.md). Its pieces from the engine's own shapes:
--   a plate, a ring stack in its family: rings outside in, each a frame inside the last, then its fill (a card's lit from
--   the top with a highlight under its top edge, a press's lit from below), a soft lift under it;
--   a bar, a black line outside a dark track of its own hue, its light lit top to foot with a darker lip and a sheen line,
--   notched every so many of its whole;
--   a word in Fredoka One in a near-black stroke of its family's hue, its size its em (Config.Hud.Slate.Text.Em);
--   a mark, Modulo's painted picture where one is made (Config.Hud.Slate.Icons), else the kit's.
-- The target's numbers are page points, Slate.Pt's authored points times Config.Hud.Slate.Page (the style frames' 1.28).
-- The target is one page scaled whole by the screen's height: the slate's pieces stand in Slate.Root(), a page over the
-- HUD layer drawn Grow() times larger, what the layers' cap holds back on a big screen up to Config.Hud.Slate.Cap (1 on a
-- phone and under a test's forced scale). Its points are the HUD layer's over Grow().
-- Every surface value is a token, read when a piece is painted: each piece is tagged, and Repaint lays the tokens again,
-- so a Tune, the take (F1 or F2) or the next finish shows without a rebuild (research, 2026-11-27, 00:04).
--   Slate.Pt(page) -> authored                       a target's page points in the page's authored points
--   Slate.Root() -> Frame                            the page the slate's pieces stand in, made on first use
--   Slate.Em(page) -> authored                       the em a word of `page` points draws at, the kit's floor in
--   Slate.Grow() -> number                           how much larger the page draws than the HUD layer now
--   Slate.Mark(image, name, size?)                   a mark's picture, its drawing `size` across about the image's
--                                                    middle (AnchorPoint 0.5); its Kit stays `name`
--   Slate.Take() -> take                             the take now: its cards' fill, its presses' fill, its steel
--   Slate.Family(side, hue?) -> family               a side's family; "Plain" the take's steel; "Hue" one from a colour
--   Slate.Plate(parent, name, size, side, kind?, radius?)   a plate (Config.Hud.Slate.Kinds: "Card" unless named), a
--                                                    holder its content joins at ZIndex 3 and up
--   Slate.Side(plate, side, hue?)                    its family
--   Slate.Resize(plate, size)                        its size, its corners with it
--   Slate.Clear(plate, transparency)                 the whole plate faded (a press's states)
--   Slate.FillOf(plate) -> Frame?                    the innermost frame, its fill (its "Paint" gradient)
--   Slate.Inside(plate) -> number                    its rings' width, authored: where the fill starts
--   Slate.Bar(parent, name, position, size, family, radius?)   a bar of Config.Hud.Slate.Bars[family] (Slate.Fill)
--   Slate.Fill(bar, share)                           the light's share, 0 to 1 (its "Share" attribute)
--   Slate.Notch(bar, most)                           a notch every Bar.Notch of `most` (coarser for a huge whole)
--   Slate.Shape(bar, position, size)                 a bar laid again: its share kept
--   Slate.OnBar(bar, size)                           a number on a bar: white in the bar's line, centred
--   Slate.Word(parent, name, size, colour?)          a display word, in its plate family's stroke, left aligned
--   Slate.Gold(parent, name, size)                   a number on the gold, white in the gold's stroke, centred
--   Slate.Taken(parent, name)                        the lead's damage taken: lit pale to coral in its stroke, centred
--   Slate.Fade(label, transparency)                  a word and its stroke faded together
--   Slate.Reach() -> number                          the signature press's ring past its disc's edge, authored
--   Slate.Repaint(root)                              every piece under `root` in the tokens now

local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Layers = require(script.Parent.Parent.Layers)
local Text = require(script.Parent.Text)
local Theme = require(script.Parent.Parent.Theme)

local Slate = {}

local PLATE, BAR, WORD = "NL_SlatePlate", "NL_SlateBar", "NL_SlateWord"
local RINGS = { "Glass", "Dark", "Band", "Rim", "Fill" } -- a plate's frames, outside in, each inside the last
local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)

export type Family = { Ink: Color3, Dark: Color3, Band: { Color3 }, Line: Color3, Fill: { Color3 }? }

local function config(): any
	return HudConfig.Slate
end

local function corner(parent: Instance, radius: number): UICorner
	local round = parent:FindFirstChildOfClass("UICorner")
	if round == nil then
		round = Instance.new("UICorner")
		round.Parent = parent
	end
	local made = round :: UICorner
	local want = UDim.new(0, math.max(radius, 0))
	if made.CornerRadius ~= want then
		made.CornerRadius = want
	end
	return made
end

-- One colour, or two or three stops spread evenly.
local function sequence(colours: { Color3 } | Color3): ColorSequence
	if typeof(colours) == "Color3" then
		return ColorSequence.new(colours)
	end
	local list = colours :: { Color3 }
	if #list >= 3 then
		local points = {}
		for index, colour in list do
			table.insert(points, ColorSequenceKeypoint.new((index - 1) / (#list - 1), colour))
		end
		return ColorSequence.new(points)
	end
	return ColorSequence.new(list[1], list[2] or list[1])
end

local function paint(frame: Instance, colours: { Color3 } | Color3, rotation: number)
	local gradient = frame:FindFirstChild("Paint") :: UIGradient?
	if gradient == nil then
		local made = Instance.new("UIGradient")
		made.Name = "Paint"
		made.Parent = frame
		gradient = made
	end
	local g = gradient :: UIGradient
	local want = sequence(colours)
	if g.Color ~= want then
		g.Color = want
	end
	if g.Rotation ~= rotation then
		g.Rotation = rotation
	end
end

function Slate.Pt(page: number): number
	return page / config().Page
end

-- A word's floor on its TextSize, rendered: its em, not its line, holds the kit's minimum (docs/ui.md rule 1, 14 px, as
-- research and Modulo measure a word: its font size).
local function floor(): number
	return Theme.Text.Minimum / (config().Text.Em or 1)
end

-- The em a word of `page` points draws at, authored: its size, or more where the floor lifts it on a small screen. A card
-- lays its rows by it.
function Slate.Em(page: number): number
	local em = config().Text.Em or 1
	return Text.Legible(Slate.Pt(page) / em, Layers.Scale(), floor() / Slate.Grow()) * em -- the cards stand in the page
end

function Slate.Grow(): number
	return math.max(Layers.Fit(config().Cap) / math.max(Layers.Scale(), 0.01), 1)
end

local root: Frame? = nil
local grown: UIScale? = nil

-- A word's floor on its TextSize at the layers' scale: in the page, the grow already lifts it (Text.Floor).
local function floorIn(label: TextLabel): number
	return floor() / (if root and label:IsDescendantOf(root) then Slate.Grow() else 1)
end

local function regrow()
	local page, scale = root, grown
	if page == nil or scale == nil then
		return
	end
	local grow = Slate.Grow()
	if scale.Scale ~= grow then
		scale.Scale = grow
		page.Size = UDim2.fromScale(1 / grow, 1 / grow)
	end
	for _, label in CollectionService:GetTagged(WORD) do
		if label:IsA("TextLabel") and label:GetAttribute("NL_TextFloor") ~= floorIn(label) then
			Text.Floor(label, floorIn(label))
		end
	end
end

function Slate.Root(): Frame
	if root then
		return root
	end
	local page = Instance.new("Frame")
	page.Name = "NL_Page"
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.Size = UDim2.fromScale(1, 1)
	local scale = Instance.new("UIScale")
	scale.Name = "Grow"
	scale.Parent = page
	page.Parent = Layers.Get("Hud")
	root, grown = page, scale
	regrow()
	Layers.Changed:Connect(regrow)
	return page
end

function Slate.Mark(image: ImageLabel, name: string, size: number?)
	local across = size or image:GetAttribute("Across")
	local painted = config().Icons[name]
	local kit = if painted and UIKit.Images[painted] then painted else name
	local im = UIKit.Images[kit]
	if im == nil or type(across) ~= "number" then
		return
	end
	if image:GetAttribute("Kit") == name and image:GetAttribute("Across") == across then
		return
	end
	local box = across * im.Points.X / math.max(im.Points.X - 2 * im.Pad, 1e-3)
	image.Image = im.Id
	image.ScaleType = Enum.ScaleType.Stretch
	image.ImageRectOffset, image.ImageRectSize = Vector2.zero, Vector2.zero
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Size = UDim2.fromOffset(box, box)
	image:SetAttribute("Kit", name)
	image:SetAttribute("Across", across)
	image:SetAttribute("Painted", kit ~= name)
end

function Slate.Take(): any
	local c = config()
	return c.Takes[c.Take] or c.Takes.F2
end

-- A family from one colour (a rarity's): its ink and dark line near black in its hue, the hue at about 40%, its band lit
-- from three quarters toward white down to the colour itself.
local function fromHue(hue: Color3): Family
	local function times(k: number): Color3
		return Color3.new(hue.R * k, hue.G * k, hue.B * k)
	end
	return { Ink = times(0.08), Dark = times(0.4), Band = { hue:Lerp(WHITE, 0.75), hue }, Line = times(0.1) }
end

function Slate.Family(side: string, hue: Color3?): Family
	if side == "Hue" and hue then
		return fromHue(hue)
	end
	if side == "Plain" then
		local steel = Slate.Take().Steel
		return { Ink = steel.Ink, Dark = steel.Dark, Band = steel.Band, Line = BLACK }
	end
	return config().Sides[side] or config().Sides.Yours
end

local function familyOf(plate: Instance): Family
	local side = plate:GetAttribute("Side")
	local hue = plate:GetAttribute("Hue")
	return Slate.Family(if type(side) == "string" then side else "Plain", if typeof(hue) == "Color3" then hue else nil)
end

local function kindOf(plate: Instance): any
	local kinds = config().Kinds
	local kind = plate:GetAttribute("Kind")
	return kinds[if type(kind) == "string" then kind else "Card"] or kinds.Card
end

-- Its corner: its own, a share of its height, or its kind's page points.
local function radiusOf(plate: Frame, kind: any): number
	local own = plate:GetAttribute("Radius")
	if type(own) == "number" then
		return own
	end
	if kind.Corner then
		return Slate.Pt(kind.Corner)
	end
	return math.min(plate.Size.X.Offset, plate.Size.Y.Offset) * (kind.Round or 0.1)
end

function Slate.Inside(plate: Instance): number
	local total = 0
	for _, width in kindOf(plate).Rings do
		total += Slate.Pt(width)
	end
	return total
end

-- The fade alone: every frame of the plate at `clear` of its own (all solid), the lift and the highlight with it.
local function clearPlate(plate: Frame)
	local c = config().Plate
	local clear = plate:GetAttribute("Clear")
	local t = if type(clear) == "number" then clear else 0
	local frame: Instance? = plate:FindFirstChild("Glass")
	for index = 1, #RINGS do
		if frame == nil then
			break
		end
		local ring = frame :: Frame
		if ring.BackgroundTransparency ~= t then
			ring.BackgroundTransparency = t
		end
		local light = ring:FindFirstChild("TopLight") :: Frame?
		if light then
			light.BackgroundTransparency = 1 - (1 - c.Light) * (1 - t)
		end
		frame = if index < #RINGS then ring:FindFirstChild(RINGS[index + 1]) else nil
	end
	local lift = plate:FindFirstChild("Lift") :: Frame?
	if lift then
		lift.BackgroundTransparency = 1 - (1 - c.Lift) * (1 - t)
	end
	local surface = plate:FindFirstChild("Surface") :: ImageLabel?
	if surface then
		surface.ImageTransparency = t
	end
end

-- Its painted surface, if one's named for its kind and side (Config.Hud.Slate.Surfaces): the 9-slice in place of the ring
-- stack and the lift, sliced at its density so its corners hold their page points at any size. True while it shows.
local function surfaceOf(plate: Frame): boolean
	local c = config()
	local kind, side = plate:GetAttribute("Kind"), plate:GetAttribute("Side")
	local surfaces = c.Surfaces or {}
	local named = surfaces[`{kind}.{side}`] or surfaces[tostring(kind)]
	local im = if named then UIKit.Images[named.Image] else nil
	local image = plate:FindFirstChild("Surface") :: ImageLabel?
	if im == nil then
		if image then
			image.Visible = false
		end
		return false
	end
	if image == nil then
		local made = Instance.new("ImageLabel")
		made.Name = "Surface"
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.ScaleType = Enum.ScaleType.Slice
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Position = UDim2.fromScale(0.5, 0.5)
		made.ZIndex = 2
		made.Parent = plate
		image = made
	end
	local surface = image :: ImageLabel
	local out = 2 * Slate.Pt(named.Out or 0)
	surface.Image = im.Id
	surface.SliceCenter = named.Slice
	surface.SliceScale = 1 / math.max(named.Density * c.Page, 1e-3) -- its pixels to the page's points
	surface.Size = UDim2.new(1, out, 1, out)
	surface.Visible = true
	return true
end

local function paintPlate(plate: Frame)
	local c = config()
	local painted = surfaceOf(plate)
	for _, name in { RINGS[1], "Lift" } do
		local frame = plate:FindFirstChild(name) :: GuiObject?
		if frame and frame.Visible == painted then
			frame.Visible = not painted
		end
	end
	local kind = kindOf(plate)
	local fam = familyOf(plate)
	local take = Slate.Take()
	local r = radiusOf(plate, kind)
	-- A card: Ink, Dark, its Band lit corner to corner, its Line. A press: Ink, Dark, a black hairline, its Band as its
	-- rim, lit top to foot.
	local paints: { any } = if kind.Rim then { fam.Ink, fam.Dark, BLACK, fam.Band } else { fam.Ink, fam.Dark, fam.Band, fam.Line }
	local rotations = if kind.Rim then { 90, 90, 90, 90 } else { 90, 90, 45, 90 }
	local own = plate:GetAttribute("Fill")
	local fill: any = if typeof(own) == "Color3" then own elseif fam.Fill then fam.Fill elseif kind.Rim then take.Press else take.Fill
	local frame = plate:FindFirstChild("Glass") :: Frame?
	local inset = 0
	for index, name in RINGS do
		if frame == nil then
			break
		end
		local ring = frame :: Frame
		local width = if index == 1 then 0 else Slate.Pt(kind.Rings[index - 1])
		inset += width
		ring.Position = UDim2.fromOffset(width, width)
		ring.Size = if index == 1 then UDim2.fromScale(1, 1) else UDim2.new(1, -2 * width, 1, -2 * width)
		ring.BackgroundColor3 = WHITE
		corner(ring, r - inset)
		if name == "Fill" then
			if plate:GetAttribute("Lit") == nil then -- a pop lifting it toward white paints it itself (LeadCard.Glow)
				paint(ring, fill, 90)
			end
			local light = ring:FindFirstChild("TopLight") :: Frame?
			if light then
				light.Visible = kind.Lit == true
				light.Size = UDim2.new(1, 0, 0, Slate.Pt(c.Plate.LightTall))
				corner(light, math.max(r - inset, 0))
			end
		else
			paint(ring, paints[index], rotations[index])
		end
		local nextName = RINGS[index + 1]
		frame = if nextName then ring:FindFirstChild(nextName) :: Frame? else nil
	end
	local lift = plate:FindFirstChild("Lift") :: Frame?
	if lift then
		lift.BackgroundColor3 = c.Plate.Shadow
		lift.Position = UDim2.fromOffset(0, Slate.Pt(c.Plate.LiftDown))
		corner(lift, r)
	end
	clearPlate(plate)
end

-- The plate's holder: the lift (ZIndex 1) and the ring stack (2) inside it, its content over them.
function Slate.Plate(parent: Instance, name: string, size: Vector2, side: string, kind: string?, radius: number?): Frame
	local plate = Instance.new("Frame")
	plate.Name = name
	plate.BackgroundTransparency = 1
	plate.BorderSizePixel = 0
	plate.Size = UDim2.fromOffset(size.X, size.Y)
	plate:SetAttribute("Side", side)
	plate:SetAttribute("Kind", kind or "Card")
	if radius then
		plate:SetAttribute("Radius", radius)
	end
	local lift = Instance.new("Frame")
	lift.Name = "Lift"
	lift.BorderSizePixel = 0
	lift.Size = UDim2.fromScale(1, 1)
	lift.ZIndex = 1
	lift.Parent = plate
	local outer: Instance = plate
	for index, ringName in RINGS do
		local ring = Instance.new("Frame")
		ring.Name = ringName
		ring.BorderSizePixel = 0
		ring.ZIndex = if index == 1 then 2 else 1
		ring.Parent = outer
		outer = ring
	end
	local light = Instance.new("Frame") -- a card's highlight under its top edge
	light.Name = "TopLight"
	light.BorderSizePixel = 0
	light.BackgroundColor3 = WHITE
	light.Parent = outer
	CollectionService:AddTag(plate, PLATE)
	paintPlate(plate)
	plate.Parent = parent
	return plate
end

function Slate.Side(plate: Frame, side: string, hue: Color3?)
	if plate:GetAttribute("Side") ~= side or plate:GetAttribute("Hue") ~= hue then
		plate:SetAttribute("Side", side)
		plate:SetAttribute("Hue", hue)
		paintPlate(plate)
	end
end

function Slate.Resize(plate: Frame, size: Vector2)
	if plate.Size.X.Offset ~= size.X or plate.Size.Y.Offset ~= size.Y then
		plate.Size = UDim2.fromOffset(size.X, size.Y)
		paintPlate(plate)
	end
end

function Slate.Clear(plate: Frame, transparency: number)
	if plate:GetAttribute("Clear") ~= transparency then
		plate:SetAttribute("Clear", transparency)
		clearPlate(plate)
	end
end

function Slate.FillOf(plate: Instance): Frame?
	local frame: Instance? = plate:FindFirstChild("Glass")
	for index = 2, #RINGS do
		frame = if frame then frame:FindFirstChild(RINGS[index]) else nil
	end
	return frame :: Frame?
end

local function paintBar(bar: Frame)
	local c = config()
	local b = c.Bar
	local family = bar:GetAttribute("Family")
	local fam = c.Bars[if type(family) == "string" then family else "Health"] or c.Bars.Health
	bar.BackgroundColor3 = WHITE
	paint(bar, fam.Track, 90)
	local outline = bar:FindFirstChild("Outline") :: UIStroke?
	if outline then
		outline.Color = fam.Outline
		outline.Thickness = Slate.Pt(b.Outline)
	end
	local tall = bar.Size.Y.Offset >= Slate.Pt(b.From)
	local light = bar:FindFirstChild("Light") :: Frame?
	if light then
		light.BackgroundColor3 = WHITE
		paint(light, fam.Fill, 90)
		local lip = light:FindFirstChild("Lip") :: Frame?
		local r = Slate.Pt(b.Radius)
		if lip then
			lip.Visible = tall
			lip.BackgroundColor3 = fam.Lip
			lip.Size = UDim2.new(1, -r, 0, Slate.Pt(b.Lip))
			lip.Position = UDim2.new(0, r / 2, 1, -Slate.Pt(b.Lip))
		end
		local sheen = light:FindFirstChild("Sheen") :: Frame?
		if sheen then
			sheen.Visible = tall
			sheen.BackgroundTransparency = b.Sheen
			sheen.Size = UDim2.new(1, -r, 0, Slate.Pt(b.SheenTall))
			sheen.Position = UDim2.new(0, r / 2, 0, Slate.Pt(b.SheenAt))
		end
	end
	local notches = bar:FindFirstChild("Notches")
	if notches then
		for _, notch in notches:GetChildren() do
			if notch:IsA("Frame") then
				notch.BackgroundColor3 = fam.Outline
				notch.BackgroundTransparency = b.NotchClear
			end
		end
	end
end

function Slate.Bar(parent: Instance, name: string, position: Vector2, size: Vector2, family: string, radius: number?): Frame
	local r = radius or size.Y / 2
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.BorderSizePixel = 0
	bar.Position = UDim2.fromOffset(position.X, position.Y)
	bar.Size = UDim2.fromOffset(size.X, size.Y)
	bar:SetAttribute("Family", family)
	corner(bar, r)
	local outline = Instance.new("UIStroke")
	outline.Name = "Outline"
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.LineJoinMode = Enum.LineJoinMode.Round
	outline.Parent = bar
	local light = Instance.new("Frame")
	light.Name = "Light"
	light.BorderSizePixel = 0
	light.Size = UDim2.fromScale(1, 1)
	light.ZIndex = 1
	corner(light, r)
	light.Parent = bar
	for _, part in { "Lip", "Sheen" } do
		local made = Instance.new("Frame")
		made.Name = part
		made.BorderSizePixel = 0
		made.BackgroundColor3 = WHITE
		made.Parent = light
	end
	local notches = Instance.new("Frame")
	notches.Name = "Notches"
	notches.BackgroundTransparency = 1
	notches.Size = UDim2.fromScale(1, 1)
	notches.ZIndex = 2
	notches.Parent = bar
	bar:SetAttribute("Share", -1)
	bar:SetAttribute("Most", 0)
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

-- A notch every Bar.Notch of the whole, ten times coarser while more than twenty would stand.
local function layNotches(bar: Frame)
	local b = config().Bar
	local most = bar:GetAttribute("Most")
	local whole = if type(most) == "number" then most else 0
	local step = b.Notch
	while whole / step > 20 do
		step *= 10
	end
	local notches = bar:FindFirstChild("Notches") :: Frame?
	if notches == nil then
		return
	end
	local count = if whole > 0 and bar.Size.Y.Offset >= Slate.Pt(b.From) then math.max(0, math.ceil(whole / step) - 1) else 0
	local made = notches:GetChildren()
	for index = count + 1, #made do
		made[index]:Destroy()
	end
	local wide = math.max(Slate.Pt(b.NotchWide), 1) -- a whole point at least, or a phone draws none
	local inset = Slate.Pt(0.6)
	for index = 1, count do
		local notch = (notches:GetChildren()[index] :: Frame?) or Instance.new("Frame")
		notch.Name = "Notch"
		notch.BorderSizePixel = 0
		notch.AnchorPoint = Vector2.new(0.5, 0)
		notch.Position = UDim2.new(index * step / whole, 0, 0, inset)
		notch.Size = UDim2.new(0, wide, 1, -2 * inset)
		notch.Parent = notches
	end
	paintBar(bar)
end

function Slate.Notch(bar: Frame, most: number)
	if bar:GetAttribute("Most") == most then
		return
	end
	bar:SetAttribute("Most", most)
	layNotches(bar)
end

function Slate.Shape(bar: Frame, position: Vector2, size: Vector2)
	bar.Position = UDim2.fromOffset(position.X, position.Y)
	if bar.Size.X.Offset ~= size.X or bar.Size.Y.Offset ~= size.Y then
		bar.Size = UDim2.fromOffset(size.X, size.Y)
		local share = bar:GetAttribute("Share")
		bar:SetAttribute("Share", -1)
		Slate.Fill(bar, if type(share) == "number" and share >= 0 then share else 0)
		layNotches(bar)
	end
end

-- The plate a word sits on, for its family's ink.
local function plateAbove(label: Instance): Instance?
	local at = label.Parent
	while at do
		if CollectionService:HasTag(at, PLATE) then
			return at
		end
		at = at.Parent
	end
	return nil
end

local function displayFace(): Font
	local c = config()
	return Font.new(c.Face, (Enum.FontWeight :: any)[c.Weight or "Regular"] or Enum.FontWeight.Regular)
end

local function paintWord(label: TextLabel)
	local c = config()
	local role = label:GetAttribute("Role")
	local want = displayFace()
	if label.FontFace ~= want then
		label.FontFace = want
	end
	local stroke = label:FindFirstChild("Stroke") :: UIStroke?
	if stroke == nil then
		return
	end
	local size = label.TextSize * (c.Text.Em or 1) -- its em: the strokes are shares of it
	stroke.Enabled = true
	if role == "Taken" then
		local k = c.Taken
		label.TextColor3 = WHITE
		paint(label, k.Fill, 90)
		stroke.Color = k.Stroke
		stroke.Thickness = math.max(1, size * k.Line)
		stroke.Transparency = label.TextTransparency
	elseif role == "OnBar" then
		local bar = label.Parent
		local family = if bar then bar:GetAttribute("Family") else nil
		local fam = c.Bars[if type(family) == "string" then family else "Health"] or c.Bars.Health
		stroke.Color = fam.Outline
		stroke.Thickness = math.max(1, size * c.Text.OnBar)
		stroke.Transparency = 0
	elseif role == "Gold" then
		label.TextColor3 = c.Ink
		stroke.Color = c.Sides.Gold.Line
		stroke.Thickness = math.max(1, size * c.Text.Gold)
		stroke.Transparency = 0
	else
		local plate = plateAbove(label)
		stroke.Color = if plate then familyOf(plate).Ink else c.Shade
		stroke.Thickness = math.max(1, size * c.Text.Stroke)
		stroke.Transparency = 0
	end
end

local function word(parent: Instance, name: string, size: number, colour: Color3, role: string): TextLabel
	local label = Text.new({
		Name = name,
		Size = size / (config().Text.Em or 1), -- a TextSize is the line: the em `size` over the face's Em
		Font = displayFace(),
		Colour = colour,
		Parent = parent,
	})
	label:SetAttribute("Role", role)
	Text.Floor(label, floorIn(label))
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

function Slate.Gold(parent: Instance, name: string, size: number): TextLabel
	local label = word(parent, name, size, config().Ink, "Gold")
	label.TextXAlignment = Enum.TextXAlignment.Center
	return label
end

-- The lead's damage taken (Config.Hud.Slate.Taken): lit pale to coral in its dark stroke, centred on its place.
function Slate.Taken(parent: Instance, name: string): TextLabel
	local c = config().Taken
	local label = word(parent, name, Slate.Pt(c.Size), WHITE, "Taken")
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.AnchorPoint = Vector2.new(0.5, 0.5)
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

function Slate.Reach(): number
	local c = config().Press.Cooldown
	return Slate.Pt(c.Ring + math.max(c.Line, c.Ink) / 2)
end

function Slate.Repaint(root: Instance)
	for tag, painter in { [PLATE] = paintPlate, [BAR] = paintBar } :: { [string]: (Frame) -> () } do
		for _, piece in CollectionService:GetTagged(tag) do
			if piece:IsA("Frame") and piece:IsDescendantOf(root) then
				painter(piece)
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
