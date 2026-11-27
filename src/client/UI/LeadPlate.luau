--!strict
-- LeadPlate (client UI): the lead's plate, top left of the HUD: AR68 M's first piece on (a) slate (research's pick of
-- 2026-11-27, 13:38; Config.Hud.M; Config.UIKit's M*). Modulo's plate image holds the portrait's mount, the name's card,
-- the health's card and both troughs. Over it: the lead's face in the mount, its health a nine-slice light whose slanted
-- ends keep their shape, its experience a thin gold line in the lower trough, the level on an orange tab over the
-- portrait's corner, the name in capitals with the type's gem and the class's mark after it, and the damage taken at the
-- name row's end. Every word is Oswald in warm off-white with a dark edge (UI.Kit.Edge). Fallen, the face dims, never a
-- red wash.
-- The same calls as the card it replaces, so the HUD drives it unchanged:
--   LeadPlate.new(parent)                the plate, hidden until it has a lead
--   LeadPlate.Who(card, voidkinId?, down) the face
--   LeadPlate.Kind(card, type, class)     the type's gem and the class's mark
--   LeadPlate.Name(card, text)            the name in capitals, cut with "…" past its room
--   LeadPlate.Fill(bar, share)            a bar's share, 0 to 1 (card.Health, card.Xp)
--   LeadPlate.Glow(card, share)           the level-up's pop on the level
--   LeadPlate.Pt(point) -> authored       a point of the 568 frame in the HUD's authored points

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

local function m(): any
	return HudConfig.M
end

function LeadPlate.Pt(point: number): number
	return point * m().Per
end
local pt = LeadPlate.Pt

-- A box of the frame { x, y, w, h } in the plate's own authored points (from its top left).
local function box(b: { number }): (number, number, number, number)
	local plate = m().Plate
	return pt(b[1] - plate[1]), pt(b[2] - plate[2]), pt(b[3]), pt(b[4])
end

-- The name's room: from its left to the damage taken's, less the marks after it and their gaps.
local function nameRoom(): number
	local c = m()
	local marks = c.Marks
	return pt(c.Texts.Taken.X - c.Texts.Name.X - 30 - marks.Gap - marks.Gem - marks.Step)
end

-- The gem and the class's mark after the name as it draws.
local function placeMarks(card: Card)
	local c = m()
	local marks = c.Marks
	local plate = c.Plate
	local wide = math.min(card.Name.TextBounds.X, nameRoom())
	local left = pt(c.Texts.Name.X - plate[1])
	local y = pt(marks.Y - plate[2])
	local gem = left + wide + pt(marks.Gap + marks.Gem / 2)
	card.Gem.Position = UDim2.fromOffset(gem - pt(marks.Gem) / 2, y - pt(marks.Gem) / 2)
	local mark = card.Class.Parent :: Frame
	mark.Position = UDim2.fromOffset(gem + pt(marks.Step), y)
end

-- The face in the mount: the old card's face and head art, the square of it Config.Hud.Slate.Lead.Face names.
local function art(portrait: GuiObject, name: string, kit: string, z: number, dim: Color3)
	local im = UIKit.Images[kit]
	local crop = HudConfig.Slate.Lead.Face
	local k = portrait.Size.X.Offset / crop.Size
	local at = im.At or Vector2.zero
	local made = Instance.new("ImageLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.Image = im.Id
	made.ImageColor3 = dim
	made.ZIndex = z
	made.Position = UDim2.fromOffset((at.X - crop.X) * k, (at.Y - crop.Y) * k)
	made.Size = UDim2.fromOffset(im.Points.X * k, im.Points.Y * k)
	made.Parent = portrait
end

local function paintWho(card: Card, want: string, down: boolean)
	local portrait = card.Portrait
	portrait:SetAttribute("Voidkin", want)
	portrait:SetAttribute("Dim", down)
	local def = if want ~= "" then Voidkin.ById[want] else nil
	local rarity = if def then def.Rarity else "Common"
	local face = if def and UIKit.Images[`CardFace{def.Name}`] then `CardFace{def.Name}` else `CardFaceUnknown{rarity}`
	local head = if def and UIKit.Images[`CardHead{def.Name}`] then `CardHead{def.Name}` else nil
	portrait:ClearAllChildren()
	local d = if down then 1 - HudConfig.Fallen.Dim else 1
	local dim = Color3.new(d, d, d)
	if UIKit.Images[face] then
		art(portrait, "Face", face, 1, dim)
	end
	if head then
		art(portrait, "Head", head, 2, dim)
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

-- A word of the plate: Oswald, its size held over the kit's floor at the layer's scale, its box over its baseline.
local function word(parent: Instance, name: string, row: any, x: number, align: Enum.TextXAlignment, colour: Color3, z: number): TextLabel
	local c = m()
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = ""
	label.TextColor3 = colour
	label.FontFace = Font.new(c.Font, if row.Bold then Enum.FontWeight.Bold else Enum.FontWeight.Regular)
	label.TextXAlignment = align
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = z
	label:SetAttribute("MX", x)
	label.Parent = parent
	return label
end

-- A word laid at its row's baseline: its size from the frame's, over the floor; its box Rise of it above the baseline.
local function lay(label: TextLabel, row: any, x: number, anchor: number)
	local c = m()
	local plate = c.Plate
	local size = Edge.Size(pt(row.Size))
	local top = pt(row.Baseline - plate[2]) - size * c.Rise
	label.TextSize = size
	label.AnchorPoint = Vector2.new(anchor, 0)
	label.Position = UDim2.fromOffset(pt(x - plate[1]), top)
	label:SetAttribute("Top", top) -- where a word that rises (the damage taken) starts
	label.Size = UDim2.fromOffset(if label.TextTruncate == Enum.TextTruncate.AtEnd then nameRoom() else math.max(label.TextBounds.X, size) + 4, size * 1.2)
end

local function layout(card: Card)
	local c = m()
	local t = c.Texts
	local frame = card.Frame
	local x, y, w, h = pt(c.Plate[1]), pt(c.Plate[2]), pt(c.Plate[3]), pt(c.Plate[4])
	frame.Position = UDim2.fromOffset(x, y)
	frame.Size = UDim2.fromOffset(w, h)
	local skin = Skin.Of(frame)
	Skin.Set(skin:FindFirstChild("Plate") :: ImageLabel, "MLeadPlate", { X = 0, Y = 0, Scale = c.Per })
	local tx, ty = box(c.Tab)
	Skin.Set(frame:FindFirstChild("LevelTab") :: ImageLabel, "MLevelTab", { X = tx, Y = ty, Scale = c.Per })
	local px, py, pw, ph = box(c.Portrait)
	card.Portrait.Position = UDim2.fromOffset(px, py)
	card.Portrait.Size = UDim2.fromOffset(pw, ph)
	local hx, hy, hw, hh = box(c.Health)
	card.Health.Position = UDim2.fromOffset(hx, hy)
	card.Health.Size = UDim2.fromOffset(hw, hh)
	card.Health:SetAttribute("Root", pt(c.Health.Root))
	card.Health:SetAttribute("Least", pt(c.Health.Least))
	local xx, xy, xw, xh = box(c.Xp)
	card.Xp.Position = UDim2.fromOffset(xx, xy)
	card.Xp.Size = UDim2.fromOffset(xw, xh)
	for _, bar in { card.Health, card.Xp } do
		local share = bar:GetAttribute("Share")
		bar:SetAttribute("Share", -1)
		LeadPlate.Fill(bar, if type(share) == "number" and share >= 0 then share else 0)
	end
	lay(card.Name, t.Name, t.Name.X, 0)
	lay(card.Taken, t.Taken, t.Taken.X, 1)
	lay(card.Level, t.Level, t.Level.X, 0.5)
	-- The level swells about its middle (Pop.Centre): its box centred on its own middle.
	card.Level.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Level.Position = card.Level.Position + UDim2.fromOffset(0, card.Level.Size.Y.Offset / 2)
	-- The digits across the health's card, centred.
	lay(card.HealthText, t.Health, t.Health.X, 0.5)
	card.HealthText.Size = UDim2.fromOffset(hw, card.HealthText.Size.Y.Offset)
	local runs = card.HealthText:FindFirstChild("Runs") :: TextLabel
	runs.TextSize = card.HealthText.TextSize
	placeMarks(card)
	Edge.Refit(frame)
end

-- The digits in two runs: the share bold, " / most" regular a shade warmer; any other line (a fallen lead's) in one.
local function runs(card: Card)
	local c = m()
	local label = card.HealthText
	local shown = label:FindFirstChild("Runs") :: TextLabel
	local now, most = string.match(label.Text, "^(.-)%s*/%s*(.+)$")
	if now and most then
		local tint = c.Colours.Most
		-- the slash spaced, as research's round on the frame put it back ('3,682 / 3,732')
		shown.Text = `<b>{now}</b><font weight="regular" color="#{tint:ToHex()}"> / {most}</font>`
	else
		shown.Text = `<b>{label.Text}</b>`
	end
end

function LeadPlate.new(parent: Instance): Card
	local c = m()
	local t = c.Texts
	local colours = c.Colours
	local frame = Instance.new("Frame")
	frame.Name = "Lead"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame:SetAttribute("Look", "M")
	local skin = Skin.Of(frame)
	Skin.Lay(skin, "MLeadPlate", { Name = "Plate", Scale = c.Per, Z = 1 })
	-- The face in the mount, clipped to it.
	local portrait = Instance.new("CanvasGroup")
	portrait.Name = "Portrait"
	portrait.BackgroundTransparency = 1
	portrait.BorderSizePixel = 0
	portrait.ZIndex = 2
	portrait:SetAttribute("Voidkin", "-")
	portrait:SetAttribute("Dim", false)
	portrait.Parent = frame
	-- The health: a track holding its light, the nine-slice.
	local health = Instance.new("Frame")
	health.Name = "Health"
	health.BackgroundTransparency = 1
	health.BorderSizePixel = 0
	health.ZIndex = 3
	health:SetAttribute("Share", -1)
	health.Parent = frame
	local light = Skin.Lay(health, "MHealthFill", { Name = "Light", Scale = c.Per, Z = 1 })
	light.Size = UDim2.fromScale(0, 1)
	local digits = word(frame, "HealthText", t.Health, t.Health.X, Enum.TextXAlignment.Center, colours.Text, 5)
	digits.TextTransparency = 1 -- read by the HUD and the tests; its runs draw it
	local shown = Instance.new("TextLabel")
	shown.Name = "Runs"
	shown.BackgroundTransparency = 1
	shown.Size = UDim2.fromScale(1, 1)
	shown.RichText = true
	shown.FontFace = Font.new(c.Font, Enum.FontWeight.Regular)
	shown.TextColor3 = colours.Text
	shown.ZIndex = 5
	shown.Text = ""
	shown.Parent = digits
	local shadow = Instance.new("UIStroke") -- a soft shadow under the digits, not the edge
	shadow.Name = "Shadow"
	shadow.Color = colours.Shadow
	shadow.Transparency = c.Shadow.Clear
	shadow.Thickness = 1
	shadow.Parent = shown
	-- Experience: a gold line in the lower trough.
	local xp = Instance.new("Frame")
	xp.Name = "Xp"
	xp.BackgroundTransparency = 1
	xp.BorderSizePixel = 0
	xp.ZIndex = 3
	xp:SetAttribute("Share", -1)
	xp.Parent = frame
	local thread = Instance.new("Frame")
	thread.Name = "Light"
	thread.BackgroundColor3 = colours.Xp
	thread.BorderSizePixel = 0
	thread.Size = UDim2.fromScale(0, 1)
	thread.Parent = xp
	-- The level's tab over the portrait's corner, the level on it.
	local tab = Skin.Lay(frame, "MLevelTab", { Name = "LevelTab", Scale = c.Per, Z = 6 })
	tab.Active = false
	local level = word(frame, "Level", t.Level, t.Level.X, Enum.TextXAlignment.Center, colours.Text, 8)
	-- The name in capitals, the gem and the class's mark after it; the damage taken at the row's end.
	local name = word(frame, "Name", t.Name, t.Name.X, Enum.TextXAlignment.Left, colours.Text, 5)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local gem = Skin.Icon(frame, "GemRed", 0, 0, pt(c.Marks.Gem), nil, 5)
	gem.Name = "Gem"
	local mark = Instance.new("Frame")
	mark.Name = "ClassMark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Size = UDim2.fromOffset(pt(c.Marks.Class), pt(c.Marks.Class))
	mark.ZIndex = 5
	mark.Parent = frame
	local class = Skin.Icon(mark, "ClassWarrior", pt(c.Marks.Class) / 2, pt(c.Marks.Class) / 2, pt(c.Marks.Class), colours.Text, 5)
	class.Name = "Class"
	local taken = word(frame, "Taken", t.Taken, t.Taken.X, Enum.TextXAlignment.Right, colours.Taken, 7)
	taken.Visible = false
	for _, label in { level, name, taken } do
		Edge.Wear(label)
	end
	frame.Parent = parent
	local made: Card = { Frame = frame, Name = name, Level = level, Health = health, HealthText = digits, Xp = xp, Portrait = portrait, Gem = gem, Class = class, Taken = taken }
	digits:GetPropertyChangedSignal("Text"):Connect(function()
		runs(made)
	end)
	for _, label in { name, level, taken } do
		label:GetPropertyChangedSignal("TextBounds"):Connect(function()
			layout(made)
		end)
	end
	LeadPlate.Who(made, nil, false)
	layout(made)
	Layers.Changed:Connect(function()
		layout(made)
	end)
	return made
end

-- The name in capitals; the marks follow it as it draws (TextBounds).
function LeadPlate.Name(card: Card, text: string)
	local shown = string.upper(text)
	if card.Name.Text ~= shown then
		card.Name.Text = shown
	end
end

function LeadPlate.Kind(card: Card, kind: string, class: string)
	for image, name in { [card.Gem] = `Gem{kind}`, [card.Class] = `Class{class}Glyph` } do
		local im = UIKit.Images[name]
		if im and image:GetAttribute("Kit") ~= name then
			image.Image = im.Id
			image:SetAttribute("Kit", name)
		end
	end
end

-- A bar's share: its light Root + (W − Root) of it wide, Least at least, hidden at none (the health); or its share of the
-- bar wide (the experience line).
function LeadPlate.Fill(bar: Frame, share: number)
	local clamped = math.clamp(if share == share then share else 0, 0, 1)
	if bar:GetAttribute("Share") == clamped then
		return
	end
	bar:SetAttribute("Share", clamped)
	local light = bar:FindFirstChild("Light") :: GuiObject
	local w, h = bar.Size.X.Offset, bar.Size.Y.Offset
	local root, least = bar:GetAttribute("Root"), bar:GetAttribute("Least")
	light.Visible = clamped > 0
	if type(root) == "number" and type(least) == "number" then
		light.Size = UDim2.fromOffset(math.max(root + (w - root) * clamped, least), h)
	else
		light.Size = UDim2.fromOffset(w * clamped, h)
	end
end

-- The level-up's pop: the level lit toward the experience's pale gold, `share` of the way.
function LeadPlate.Glow(card: Card, share: number)
	local colours = m().Colours
	card.Level:SetAttribute("Lit", if share > 0 then share else nil)
	card.Level.TextColor3 = colours.Text:Lerp(colours.XpLit, math.clamp(share, 0, 1))
end

return LeadPlate
