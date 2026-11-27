--!strict
-- LeadPlate (client UI): the lead's plate, top left of the HUD: AR68 M's top left, A, the card and the blade (research's
-- pick of 2026-11-27, 14:29; Config.Hud.M.Lead; Config.UIKit's M*). Modulo's plate image holds the orange card, the dark
-- blade, their shadow and ink, and the health's and the experience's troughs. Over it: the lead's bust held by the card,
-- its hair free over the card's top (a lead with no bust drawn keeps its old face art, square, clipped inside the card);
-- the health as its image revealed by a clip, never stretched, with the last hit's lag under it and a thin light at its
-- end; the experience a gold line in the lower trough; the level on a dark tab at the card's foot; the name in capitals,
-- stepping its size down to fit its room, with the type's gem and the class's mark after it; the damage taken over the
-- blade's right end. Every word is Montserrat Heavy with the dark edge (UI.Kit.Edge, the word's own line). Fallen, the
-- bust dims, never a red wash.
-- The same calls as the card it replaces, so the HUD drives it unchanged:
--   LeadPlate.new(parent)                the plate, hidden until it has a lead
--   LeadPlate.Who(card, voidkinId?, down) the bust, or the face
--   LeadPlate.Kind(card, type, class)     the type's gem and the class's mark
--   LeadPlate.Name(card, text)            the name in capitals, its size stepped down to fit, never cut
--   LeadPlate.Fill(bar, share)            a bar's share, 0 to 1 (card.Health with its lag, card.Xp)
--   LeadPlate.Glow(card, share)           the level-up's pop on the level
--   LeadPlate.Pt(point) -> authored       a point of the 568 frame in the HUD's authored points

local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Layers = require(script.Parent.Layers)
local Skin = require(script.Parent.Kit.Skin)
local Edge = require(script.Parent.Kit.Edge)

export type Card = {
	Frame: Frame,
	Name: TextLabel,
	Level: TextLabel,
	Health: Frame,
	HealthText: TextLabel,
	Xp: Frame,
	Portrait: GuiObject,
	Gem: ImageLabel,
	Class: ImageLabel,
	Taken: TextLabel,
}

local LeadPlate = {}

local function a(): any
	return HudConfig.M.Lead
end

function LeadPlate.Pt(point: number): number
	return point * HudConfig.M.Per
end
local pt = LeadPlate.Pt

-- A box of the group { x, y, w, h } in the plate's authored points.
local function box(b: { number }): (number, number, number, number)
	return pt(b[1]), pt(b[2]), pt(b[3]), pt(b[4])
end

local function place(item: GuiObject, b: { number })
	local x, y, w, h = box(b)
	item.Position = UDim2.fromOffset(x, y)
	item.Size = UDim2.fromOffset(w, h)
end

-- One of Modulo's images, whole at its box.
local function image(parent: Instance, kit: string, name: string, z: number): ImageLabel
	local made = Instance.new("ImageLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.Image = UIKit.Images[kit].Id
	made.ZIndex = z
	made:SetAttribute("Kit", kit)
	made.Parent = parent
	return made
end

-- A word's drawn width in authored points: TextBounds as Roblox reports it, at the label's own scale.
local function drawn(label: TextLabel): number
	local k = if label.TextSize > 0 and label.TextBounds.Y > 0 then label.TextBounds.Y / label.TextSize else 1
	return label.TextBounds.X / math.max(k, 0.01)
end

-- The gem and the class's mark after the name as it draws.
local function placeMarks(card: Card)
	local c = a()
	local marks = c.Marks
	local right = pt(c.Texts.Name.X) + drawn(card.Name)
	local gem = right + pt(marks.GemAfter)
	local y = pt(marks.Y)
	local across = pt(marks.Gem / marks.GemFill)
	card.Gem.Position = UDim2.fromOffset(gem - across / 2, y - across / 2)
	card.Gem.Size = UDim2.fromOffset(across, across)
	local mark = card.Class.Parent :: Frame
	mark.Position = UDim2.fromOffset(gem + pt(marks.ClassAfter), y)
	local frame = card.Frame
	for _, pair in { { "GemSocket", gem }, { "ClassSocket", gem + pt(marks.ClassAfter) } } do
		local s = frame:FindFirstChild(pair[1] :: string) :: Frame?
		if s == nil then
			continue
		end
		local x = pair[2] :: number
		s.Position = UDim2.fromOffset(x, y)
		s.Size = UDim2.fromOffset(pt(marks.Socket), pt(marks.Socket))
		local rim = s:FindFirstChildOfClass("UIStroke") :: UIStroke
		rim.Thickness = pt(marks.Line)
	end
end

-- A mark's dark round socket with its light rim, under it (Config.Hud.M.Lead.Marks).
local function socket(parent: Instance, name: string): Frame
	local marks = a().Marks
	local made = Instance.new("Frame")
	made.Name = name
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.BackgroundColor3 = marks.SocketFill
	made.BorderSizePixel = 0
	made.ZIndex = 7
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = made
	local rim = Instance.new("UIStroke")
	rim.Color = marks.SocketRim
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = made
	made.Parent = parent
	return made
end

-- The old face art in the square Config.Hud.Slate.Lead.Face names, for a lead with no bust drawn.
local function art(portrait: GuiObject, name: string, kit: string, z: number, dim: Color3)
	local im = UIKit.Images[kit]
	local crop = HudConfig.Slate.Lead.Face
	local k = portrait.Size.X.Offset / crop.Size
	local at = im.At or Vector2.zero
	local made = image(portrait, kit, name, z)
	made.ImageColor3 = dim
	made.Position = UDim2.fromOffset((at.X - crop.X) * k, (at.Y - crop.Y) * k)
	made.Size = UDim2.fromOffset(im.Points.X * k, im.Points.Y * k)
end

local function paintWho(card: Card, want: string, down: boolean)
	local c = a()
	local portrait = card.Portrait
	portrait:SetAttribute("Voidkin", want)
	portrait:SetAttribute("Dim", down)
	local def = if want ~= "" then Voidkin.ById[want] else nil
	local rarity = if def then def.Rarity else "Common"
	local bust = if def and UIKit.Images[`MLeadBust{def.Name}`] then `MLeadBust{def.Name}` else nil
	portrait:ClearAllChildren()
	local d = if down then 1 - HudConfig.Fallen.Dim else 1
	local dim = Color3.new(d, d, d)
	local face: string
	if bust then
		-- the bust at its own box, unclipped: the hair over the card's top
		place(portrait, c.Bust)
		portrait.ClipsDescendants = false
		local made = image(portrait, bust, "Bust", 1)
		made.ImageColor3 = dim
		made.Size = UDim2.fromScale(1, 1)
		face = bust
	else
		place(portrait, c.Face)
		portrait.ClipsDescendants = true
		face = if def and UIKit.Images[`CardFace{def.Name}`] then `CardFace{def.Name}` else `CardFaceUnknown{rarity}`
		local head = if def and UIKit.Images[`CardHead{def.Name}`] then `CardHead{def.Name}` else nil
		if UIKit.Images[face] then
			art(portrait, "Face", face, 1, dim)
		end
		if head then
			art(portrait, "Head", head, 2, dim)
		end
	end
	portrait:SetAttribute("Face", face)
	portrait:SetAttribute("Rarity", rarity)
end

function LeadPlate.Who(card: Card, id: string?, down: boolean)
	local want = id or ""
	local portrait = card.Portrait
	if portrait:GetAttribute("Voidkin") == want and portrait:GetAttribute("Dim") == down then
		return
	end
	paintWho(card, want, down)
end

-- A word of the plate: Montserrat Heavy, its own colour, wearing the dark edge at its own line.
local function word(parent: Instance, name: string, row: any, align: Enum.TextXAlignment, colour: Color3, z: number): TextLabel
	local c = a()
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = ""
	label.TextColor3 = colour
	label.FontFace = Font.new(c.Font, Enum.FontWeight.Heavy)
	label.TextXAlignment = align
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.ZIndex = z
	label.Parent = parent
	return label
end

local function wear(label: TextLabel, row: any)
	local c = a()
	Edge.Wear(label, { Line = row.Line, Drop = c.Drop, Colour = c.Colours.Ink, Clear = 0 })
end

-- A word laid at its row's baseline: its size from the export's over Montserrat's Em (or `size`), its line box TextSize
-- tall with the baseline Rise of it down.
local function lay(label: TextLabel, row: any, anchor: number, size: number?)
	local c = a()
	local s = size or Edge.Size(pt(row.Size), c.Em)
	local top = pt(row.Baseline) - s * c.Rise
	label.TextSize = s
	label.AnchorPoint = Vector2.new(anchor, 0)
	label.Position = UDim2.fromOffset(pt(row.X), top)
	label:SetAttribute("Top", top) -- where a word that rises (the damage taken) starts
	label.Size = UDim2.fromOffset(math.max(drawn(label), s) + 4, s)
end

-- The name's size: the export's, stepped down so its drawn width fits Room, never under Least (never cut).
local function nameSize(card: Card): number
	local c = a()
	local row = c.Texts.Name
	local full = Edge.Size(pt(row.Size), c.Em)
	local least = Edge.Size(pt(row.Least), c.Em)
	local now = card.Name.TextSize
	local wide = drawn(card.Name)
	if now <= 0 or wide <= 0 then
		return full
	end
	local atFull = wide * full / now
	return math.clamp(full * math.min(1, pt(row.Room) / atFull), least, full)
end

local function layout(card: Card)
	if card.Frame:FindFirstChild("Plate") == nil then
		return -- being destroyed: its parts already gone
	end
	local c = a()
	local t = c.Texts
	local frame = card.Frame
	frame.Position = UDim2.fromOffset(pt(c.At[1]), pt(c.At[2]))
	frame.Size = UDim2.fromOffset(pt(c.Box[1] + c.Box[3]), pt(c.Box[2] + c.Box[4]))
	place(frame:FindFirstChild("Plate") :: GuiObject, c.Plate)
	place(frame:FindFirstChild("LevelTab") :: GuiObject, c.Tab)
	if card.Portrait:GetAttribute("Voidkin") ~= "-" then
		place(card.Portrait, if card.Portrait.ClipsDescendants then c.Face else c.Bust)
	end
	local health = card.Health
	place(health, c.Health)
	health:SetAttribute("Root", pt(c.Health.Root))
	health:SetAttribute("Span", pt(c.Health.Span))
	health:SetAttribute("Least", pt(c.Health.Least))
	for _, clip in { health:FindFirstChild("Light"), health:FindFirstChild("Lag") } do
		local shown = (clip :: Frame):FindFirstChildOfClass("ImageLabel") :: ImageLabel
		shown.Size = UDim2.fromOffset(pt(c.Health[3]), pt(c.Health[4]))
	end
	place(card.Xp, c.Xp)
	-- the bars' boxes are fixed authored points, so a layout never refills them (a late font's TextBounds would snap the
	-- lag mid-drain): only a bar never filled gets its first, empty
	for _, bar in { card.Health, card.Xp } do
		if bar:GetAttribute("Share") == -1 then
			LeadPlate.Fill(bar, 0)
		end
	end
	lay(card.Name, t.Name, 0, nameSize(card))
	lay(card.Taken, t.Taken, 1)
	lay(card.Level, t.Level, 0.5)
	-- The level swells about its middle (Pop.Centre): its box centred on its own middle.
	card.Level.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Level.Position = card.Level.Position + UDim2.fromOffset(0, card.Level.Size.Y.Offset / 2)
	-- The digits across the health's trough, centred on their own X.
	lay(card.HealthText, t.Health, 0.5)
	card.HealthText.Size = UDim2.fromOffset(pt(c.Health[3]), card.HealthText.Size.Y.Offset)
	local shown = card.HealthText:FindFirstChild("Shown") :: TextLabel
	shown.TextSize = card.HealthText.TextSize
	placeMarks(card)
	Edge.Refit(frame)
	Edge.Refit(card.HealthText)
end

-- The digits as the export draws them: '2,518  /  4,061', one weight; any other line (a fallen lead's) as it comes.
local function digits(card: Card)
	local label = card.HealthText
	local shown = label:FindFirstChild("Shown") :: TextLabel
	local now, most = string.match(label.Text, "^(.-)%s*/%s*(.+)$")
	shown.Text = if now and most then `{now}  /  {most}` else label.Text
end

-- A clip at a bar's box, holding its image whole.
local function clip(parent: Instance, kit: string, name: string, z: number): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.ClipsDescendants = true
	made.Size = UDim2.fromScale(0, 1)
	made.ZIndex = z
	made.Parent = parent
	local shown = image(made, kit, kit, z)
	shown.Position = UDim2.fromOffset(0, 0)
	return made
end

function LeadPlate.new(parent: Instance): Card
	local c = a()
	local t = c.Texts
	local colours = c.Colours
	local frame = Instance.new("Frame")
	frame.Name = "Lead"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame:SetAttribute("Look", "MA")
	image(frame, "MLeadPlate", "Plate", 1)
	-- The bust over the card (or the face inside it).
	local portrait = Instance.new("Frame")
	portrait.Name = "Portrait"
	portrait.BackgroundTransparency = 1
	portrait.BorderSizePixel = 0
	portrait.ZIndex = 2
	portrait:SetAttribute("Voidkin", "-")
	portrait:SetAttribute("Dim", false)
	portrait.Parent = frame
	-- The health: its lag under its light, each an image whole in a clip; the light's end a thin line.
	local health = Instance.new("Frame")
	health.Name = "Health"
	health.BackgroundTransparency = 1
	health.BorderSizePixel = 0
	health.ZIndex = 3
	health:SetAttribute("Share", -1)
	health.Parent = frame
	clip(health, "MHealthLag", "Lag", 3)
	clip(health, "MHealthFill", "Light", 4)
	local front = Instance.new("Frame")
	front.Name = "Front"
	front.BackgroundColor3 = c.Front.Colour
	front.BackgroundTransparency = c.Front.Clear
	front.BorderSizePixel = 0
	front.ZIndex = 5
	front.Visible = false
	front.Parent = health
	local digitsLabel = word(frame, "HealthText", t.Health, Enum.TextXAlignment.Center, colours.Bright, 6)
	digitsLabel.TextTransparency = 1 -- read by the HUD and the tests; Shown draws it
	local shown = word(digitsLabel, "Shown", t.Health, Enum.TextXAlignment.Center, colours.Bright, 6)
	shown.Size = UDim2.fromScale(1, 1)
	wear(shown, t.Health)
	-- Experience: a gold line in the lower trough, lit at its top.
	local xp = Instance.new("Frame")
	xp.Name = "Xp"
	xp.BackgroundTransparency = 1
	xp.BorderSizePixel = 0
	xp.ZIndex = 6
	xp:SetAttribute("Share", -1)
	xp.Parent = frame
	local thread = Instance.new("Frame")
	thread.Name = "Light"
	thread.BackgroundColor3 = Color3.new(1, 1, 1)
	thread.BorderSizePixel = 0
	thread.Size = UDim2.fromScale(0, 1)
	thread.ZIndex = 6
	thread.Parent = xp
	local lit = Instance.new("UIGradient")
	lit.Rotation = 90
	lit.Color = ColorSequence.new(colours.XpLit, colours.Xp)
	lit.Parent = thread
	-- The level's tab on the card's foot, the level on it.
	local tab = image(frame, "MLevelTab", "LevelTab", 7)
	tab.Active = false
	local level = word(frame, "Level", t.Level, Enum.TextXAlignment.Center, colours.Bright, 9)
	-- The name in capitals, the gem and the class's mark after it; the damage taken over the blade's end.
	local name = word(frame, "Name", t.Name, Enum.TextXAlignment.Left, colours.Text, 8)
	socket(frame, "GemSocket")
	socket(frame, "ClassSocket")
	local gem = Skin.Icon(frame, "GemRed", 0, 0, pt(c.Marks.Gem / c.Marks.GemFill), nil, 8)
	gem.Name = "Gem"
	local classAcross = pt(c.Marks.Class / c.Marks.Fill)
	local mark = Instance.new("Frame")
	mark.Name = "ClassMark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Size = UDim2.fromOffset(classAcross, classAcross)
	mark.ZIndex = 8
	mark.Parent = frame
	local class = Skin.Icon(mark, "ClassWarriorGlyph", classAcross / 2, classAcross / 2, classAcross, colours.Text, 8)
	class.Name = "Class"
	local taken = word(frame, "Taken", t.Taken, Enum.TextXAlignment.Right, colours.Taken, 9)
	taken.Visible = false
	wear(level, t.Level)
	wear(name, t.Name)
	wear(taken, t.Taken)
	frame.Parent = parent
	local made: Card = { Frame = frame, Name = name, Level = level, Health = health, HealthText = digitsLabel, Xp = xp, Portrait = portrait, Gem = gem, Class = class, Taken = taken }
	digitsLabel:GetPropertyChangedSignal("Text"):Connect(function()
		digits(made)
	end)
	for _, label in { name, level, taken } do
		label:GetPropertyChangedSignal("TextBounds"):Connect(function()
			layout(made)
		end)
	end
	LeadPlate.Who(made, nil, false)
	layout(made)
	-- held only while the card lives: a destroyed card (the cases' own) is never laid out again
	local changed = Layers.Changed:Connect(function()
		layout(made)
	end)
	frame.Destroying:Connect(function()
		changed:Disconnect()
	end)
	return made
end

-- The name in capitals; its size and the marks follow it as it draws (TextBounds).
function LeadPlate.Name(card: Card, text: string)
	local shown = string.upper(text)
	if card.Name.Text ~= shown then
		card.Name.Text = shown
	end
end

function LeadPlate.Kind(card: Card, kind: string, class: string)
	for shown, name in { [card.Gem] = `Gem{kind}`, [card.Class] = `Class{class}Glyph` } do
		local im = UIKit.Images[name]
		if im and shown:GetAttribute("Kit") ~= name then
			shown.Image = im.Id
			shown:SetAttribute("Kit", name)
		end
	end
end

-- A health clip's width at a share: Root + Span of it, Least at least while any is left.
local function reach(bar: Frame, share: number): number
	local root, span, least = bar:GetAttribute("Root") :: number, bar:GetAttribute("Span") :: number, bar:GetAttribute("Least") :: number
	return if share > 0 then math.max(root + span * share, least) else 0
end

local lagTweens: { [Frame]: Tween } = setmetatable({}, { __mode = "k" }) :: any

-- The lag at `share` now, its drain stopped.
local function lagAt(bar: Frame, lag: Frame, share: number)
	local running = lagTweens[bar]
	if running then
		running:Cancel()
		lagTweens[bar] = nil
	end
	lag.Size = UDim2.fromOffset(reach(bar, share), bar.Size.Y.Offset)
end

-- The share the lag shows now (mid-drain too), from its width.
local function lagShown(bar: Frame, lag: Frame): number
	local root, span = bar:GetAttribute("Root") :: number, bar:GetAttribute("Span") :: number
	local w = lag.Size.X.Offset
	return if w <= 0 or span <= 0 then 0 else math.clamp((w - root) / span, 0, 1)
end

-- A bar's share. The health: its light revealed Root + Span of it wide, its end lit, and its lag holding at the old share a
-- beat after a hit then draining (a heal carries it with the light). The experience: its share of the line wide.
function LeadPlate.Fill(bar: Frame, share: number)
	local clamped = math.clamp(if share == share then share else 0, 0, 1)
	local was = bar:GetAttribute("Share")
	if was == clamped then
		return
	end
	bar:SetAttribute("Share", clamped)
	local light = bar:FindFirstChild("Light") :: GuiObject
	local lag = bar:FindFirstChild("Lag") :: Frame?
	local h = bar.Size.Y.Offset
	if lag == nil then
		light.Visible = clamped > 0
		light.Size = UDim2.fromOffset(bar.Size.X.Offset * clamped, h)
		return
	end
	local c = a()
	local wide = reach(bar, clamped)
	light.Visible = clamped > 0
	light.Size = UDim2.fromOffset(wide, h)
	local front = bar:FindFirstChild("Front") :: Frame
	local line = pt(c.Front.Width)
	front.Visible = clamped > 0 and clamped < c.Front.Most
	-- in the bar's scale: an offset is whole authored points, and the line is under one
	local across = math.max(bar.Size.X.Offset, 1)
	front.Position = UDim2.fromScale((wide - line) / across, 0)
	front.Size = UDim2.fromScale(line / across, 1)
	local lagShare = lagShown(bar, lag)
	if type(was) ~= "number" or was < 0 or clamped >= lagShare then
		lagAt(bar, lag, clamped) -- the first fill, a heal, or a fill past the lag: with the light
		return
	end
	-- A hit: the lag where it stands (the old share at least), then down to the light a beat later.
	lagAt(bar, lag, math.max(lagShare, was))
	local info = TweenInfo.new(c.Health.Drain, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, c.Health.Hold)
	local drain = TweenService:Create(lag, info, { Size = UDim2.fromOffset(wide, h) })
	lagTweens[bar] = drain
	drain:Play()
end

-- The level-up's pop: the level lit toward the experience's pale gold, `share` of the way.
function LeadPlate.Glow(card: Card, share: number)
	local colours = a().Colours
	card.Level:SetAttribute("Lit", if share > 0 then share else nil)
	card.Level.TextColor3 = colours.Bright:Lerp(colours.XpLit, math.clamp(share, 0, 1))
end

return LeadPlate
