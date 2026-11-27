--!strict
-- LeadCard (client UI): the lead's card, top left of the HUD: B's layout in F2's finish (AR62's piece 1, research's picks
-- of 2026-11-26, 23:46 and 2026-11-27, 00:36; Config.Hud.Slate.Lead; UI.Kit.Slate). One card in the azure family that says
-- yours: the portrait a rounded square crossing its top and left edges (the face and head of the old card's art, in its
-- rarity's family, Config.Hud.Card.Trim), the level white on a gold badge astride the portrait's foot, across the card's
-- left edge; beside it the name in capitals, the type's gem and the class's mark after it, the health bar with its digits
-- on it (white in the bar's line), notched every 1,000, and experience a thin lit thread under it. Fallen, the face dims;
-- never a red wash. A word never draws under the 14 px floor (UI.Kit.Text), so on a small phone the bars and the card grow
-- to hold theirs (Layers.Changed).
--   LeadCard.new(parent, position)        the card, hidden until it has a lead
--   LeadCard.Who(card, voidkinId?, down)  the face and its rarity's rim
--   LeadCard.Kind(card, type, class)      the type's gem and the class's mark
--   LeadCard.Name(card, text)             the name in capitals, cut with "…" past its room
--   LeadCard.Fill(bar, share)             a bar's share, 0 to 1 (card.Health, card.Xp, a target card's Health)
--   LeadCard.Glow(card, share)            the level-up's pop on the badge

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Layers = require(script.Parent.Layers)
local Skin = require(script.Parent.Kit.Skin)
local Slate = require(script.Parent.Kit.Slate)
local Text = require(script.Parent.Kit.Text)

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
}

local LeadCard = {}

local pt = Slate.Pt
local LINE = 1.15 -- a word's box, its size times this

local function slate(): any
	return HudConfig.Slate
end

-- Every place on the card, from the scale the layer draws at: the target's where its words fit, grown where the floor
-- makes a word taller than the target's bar.
type Shape = {
	W: number,
	H: number,
	Inset: number,
	Portrait: number,
	NameX: number,
	NameTop: number,
	NameSize: number,
	BarTop: number,
	BarH: number,
	BarW: number,
	ThreadTop: number,
	ThreadH: number,
	Digits: number,
	Level: number,
}

local function shape(): Shape
	local c = slate().Lead
	local scale = Layers.Scale()
	local inset = pt(c.Inset)
	local nameSize = Text.Legible(pt(c.Name), scale, Slate.Floor())
	local digits = Text.Legible(pt(c.Digits), scale, Slate.Floor())
	local barH = math.max(pt(c.Bar), digits + 1)
	local barTop = math.max(pt(c.BarTop), pt(c.NameTop) + nameSize * LINE)
	local threadTop = barTop + barH + pt(c.ThreadGap)
	local threadH = pt(c.Thread)
	local foot = pt(c.Size.Y - c.BarTop - c.Bar - c.ThreadGap - c.Thread) -- the target's room under the thread
	local h = math.max(pt(c.Size.Y), threadTop + threadH + foot)
	local w = pt(c.Size.X)
	local portrait = pt(c.Portrait.Size)
	local nameX = pt(c.NameX)
	return {
		W = w,
		H = h,
		Inset = inset,
		Portrait = portrait,
		NameX = nameX,
		NameTop = pt(c.NameTop),
		NameSize = nameSize,
		BarTop = barTop,
		BarH = barH,
		BarW = w - nameX - pt(c.Right),
		ThreadTop = threadTop,
		ThreadH = threadH,
		Digits = digits,
		Level = Text.Legible(pt(slate().Badge.Text), scale, Slate.Floor()),
	}
end

-- The name's room: the bar's width, less the gem and the class's mark after it, and the damage taken at the row's end.
local function nameRoom(s: Shape): number
	return s.BarW - pt(slate().Lead.Marks + 12 + 15 + 6) - pt(34)
end

-- The badge cut to fit the number, its left fixed so it grows rightward; the number anchored at its middle so the
-- level-up's pop swells it in place (Pop.Centre).
local function fitLevel(card: Frame, level: TextLabel)
	local badge = card:FindFirstChild("LevelBadge") :: Frame?
	if badge == nil then
		return
	end
	local b = slate().Badge
	local wide = Text.Wide(level, level.Text)
	local w = math.max(pt(b.Size.X), wide + pt(10))
	local h = math.max(pt(b.Size.Y), level.TextSize + 1)
	Slate.Resize(badge, Vector2.new(w, h))
	local at = badge.Position
	level.Position = UDim2.fromOffset(at.X.Offset + w / 2, at.Y.Offset + h / 2)
	level.Size = UDim2.fromOffset(wide + 2, h)
end

-- The gem and the class's mark after the name as it draws.
local function placeMarks(card: Card)
	local s = shape()
	local m = slate().Lead.Marks
	local wide = math.min(Text.Wide(card.Name, card.Name.Text), nameRoom(s))
	local y = s.NameTop + s.NameSize * LINE / 2
	local gemAt = s.NameX + wide + pt(m + 6)
	card.Gem.Position = UDim2.fromOffset(gemAt - pt(12) / 2, y - pt(12) / 2) -- as Skin.Icon lays it
	local mark = card.Class.Parent :: Frame
	mark.Position = UDim2.fromOffset(gemAt + pt(15), y)
end

-- An image of the old card's art laid in the portrait's square: the art's own points, `crop` of them across it.
local function art(portrait: GuiObject, name: string, kit: string, z: number, dim: Color3)
	local im = UIKit.Images[kit]
	local crop = slate().Lead.Face
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
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, pt(slate().Lead.Portrait.Art))
	round.Parent = portrait
	local d = if down then 1 - HudConfig.Fallen.Dim else 1
	local dim = Color3.new(d, d, d)
	art(portrait, "Face", face, 1, dim)
	if head then
		art(portrait, "Head", head, 2, dim)
	end
	local rim = card.Frame:FindFirstChild("PortraitRim") :: Frame?
	if rim then
		Slate.Side(rim, "Hue", HudConfig.Card.Trim[rarity] or HudConfig.Card.Trim.Common)
	end
	portrait:SetAttribute("Face", face)
	portrait:SetAttribute("Rarity", rarity)
end

-- The face and head in their square, the rim in the rarity's colour; dimmed while it's fallen.
function LeadCard.Who(card: Card, id: string?, down: boolean)
	local portrait = card.Portrait
	local want = id or ""
	if portrait:GetAttribute("Voidkin") == want and portrait:GetAttribute("Dim") == down then
		return
	end
	paintWho(card, want, down)
end

local function layout(card: Card)
	local s = shape()
	local frame = card.Frame
	frame.Size = UDim2.fromOffset(s.W, s.H)
	-- The portrait in its rings, crossing the card's top and left edges; its art inside the rings.
	local c = slate()
	local rim = frame:FindFirstChild("PortraitRim") :: Frame
	local at = Vector2.new(pt(c.Lead.Portrait.At.X), pt(c.Lead.Portrait.At.Y))
	rim.Position = UDim2.fromOffset(at.X, at.Y)
	Slate.Resize(rim, Vector2.new(s.Portrait, s.Portrait))
	local inside = Slate.Inside(rim)
	local portrait = card.Portrait
	portrait.Position = UDim2.fromOffset(at.X + inside, at.Y + inside)
	portrait.Size = UDim2.fromOffset(s.Portrait - 2 * inside, s.Portrait - 2 * inside)
	card.Name.Position = UDim2.fromOffset(s.NameX, s.NameTop)
	card.Name.Size = UDim2.fromOffset(nameRoom(s), s.NameSize * LINE)
	Slate.Shape(card.Health, Vector2.new(s.NameX, s.BarTop), Vector2.new(s.BarW, s.BarH))
	Slate.Shape(card.Xp, Vector2.new(s.NameX, s.ThreadTop), Vector2.new(s.BarW, s.ThreadH))
	local badge = frame:FindFirstChild("LevelBadge") :: Frame
	badge.Position = UDim2.fromOffset(pt(c.Badge.At.X), pt(c.Badge.At.Y))
	placeMarks(card)
	fitLevel(frame, card.Level)
	-- The face's art laid in its square again.
	local who = portrait:GetAttribute("Voidkin")
	paintWho(card, if type(who) == "string" and who ~= "-" then who else "", portrait:GetAttribute("Dim") == true)
end

function LeadCard.new(parent: Instance, position: UDim2): Card
	local c = slate()
	local s = shape()
	local card = Slate.Plate(parent, "Lead", Vector2.new(s.W, s.H), "Yours")
	card.Position = position
	card.Visible = false
	-- The portrait: its rings in its rarity's family over the backdrop, its face and head clipped to a rounded square in them.
	local rim = Slate.Plate(card, "PortraitRim", Vector2.new(s.Portrait, s.Portrait), "Hue", "Portrait")
	rim:SetAttribute("Fill", c.Lead.Backdrop)
	Slate.Side(rim, "Hue", HudConfig.Card.Trim.Common)
	rim.ZIndex = 3
	local portrait = Instance.new("CanvasGroup")
	portrait.Name = "Portrait"
	portrait.BackgroundColor3 = c.Lead.Backdrop
	portrait.BorderSizePixel = 0
	portrait.ZIndex = 4
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, pt(c.Lead.Portrait.Art))
	round.Parent = portrait
	portrait:SetAttribute("Voidkin", "-")
	portrait:SetAttribute("Dim", false)
	portrait.Parent = card
	-- The level, white on its gold badge astride the portrait's foot.
	local badge = Slate.Plate(card, "LevelBadge", Vector2.new(pt(c.Badge.Size.X), pt(c.Badge.Size.Y)), "Gold", "Badge")
	badge.ZIndex = 5
	local level = Slate.Gold(card, "Level", pt(c.Badge.Text))
	level.AnchorPoint = Vector2.new(0.5, 0.5)
	level.ZIndex = 6
	local function refit()
		fitLevel(card, level)
	end
	level:GetPropertyChangedSignal("Text"):Connect(refit)
	level:GetPropertyChangedSignal("TextSize"):Connect(refit)
	-- The name in capitals, the gem and the class's mark after it.
	local name = Slate.Word(card, "Name", pt(c.Lead.Name))
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.ZIndex = 3
	local gem = Skin.Icon(card, "GemRed", 0, 0, pt(12), nil, 3)
	gem.Name = "Gem"
	local mark = Instance.new("Frame")
	mark.Name = "ClassMark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Size = UDim2.fromOffset(pt(11), pt(11))
	mark.ZIndex = 3
	mark.Parent = card
	local class = Skin.Icon(mark, "ClassWarrior", pt(11) / 2, pt(11) / 2, pt(11), c.Ink2, 3)
	class.Name = "Class"
	-- The health bar with its digits on it, and the experience thread under it.
	local health = Slate.Bar(card, "Health", Vector2.new(s.NameX, s.BarTop), Vector2.new(s.BarW, s.BarH), "Health", pt(c.Bar.Radius))
	health.ZIndex = 3
	local digits = Slate.OnBar(health, pt(c.Lead.Digits))
	digits.Name = "HealthText"
	local xp = Slate.Bar(card, "Xp", Vector2.new(s.NameX, s.ThreadTop), Vector2.new(s.BarW, s.ThreadH), "Xp")
	xp.ZIndex = 3
	local made: Card = { Frame = card, Name = name, Level = level, Health = health, HealthText = digits, Xp = xp, Portrait = portrait, Gem = gem, Class = class }
	LeadCard.Name(made, "")
	LeadCard.Who(made, nil, false)
	layout(made)
	Layers.Changed:Connect(function()
		layout(made)
	end)
	return made
end

-- The name in capitals, and the marks moved after it: in the label's own face at the size it draws.
function LeadCard.Name(card: Card, text: string)
	local label = card.Name
	local shown = string.upper(text)
	local key = `{shown}\0{label.TextSize}\0{label.FontFace.Family}\0{Text.Epoch()}`
	if label:GetAttribute("Fitted") == key then
		return
	end
	label:SetAttribute("Fitted", key)
	label.Text = shown
	placeMarks(card)
	fitLevel(card.Frame, card.Level) -- a face that just arrived measures the level's text anew too
end

-- The type's gem and the class's mark, from the kit: nothing when unchanged.
function LeadCard.Kind(card: Card, kind: string, class: string)
	for image, name in { [card.Gem] = `Gem{kind}`, [card.Class] = `Class{class}` } do
		local im = UIKit.Images[name]
		if im and image:GetAttribute("Kit") ~= name then
			image.Image = im.Id
			image:SetAttribute("Kit", name)
		end
	end
end

-- A bar's share (UI.Kit.Slate).
LeadCard.Fill = Slate.Fill

-- The level-up's pop (HudController): the badge's gold fill lifted `share` of the way to white under the number (the
-- kit's repaint leaves it alone while it's lit).
function LeadCard.Glow(card: Card, share: number)
	local badge = card.Frame:FindFirstChild("LevelBadge")
	local fill = if badge then Slate.FillOf(badge) else nil
	local gold = if fill then fill:FindFirstChild("Paint") :: UIGradient? else nil
	if badge and gold then
		badge:SetAttribute("Lit", if share > 0 then share else nil)
		local white = Color3.new(1, 1, 1)
		local lit = slate().Sides.Gold.Fill :: { Color3 }
		gold.Color = ColorSequence.new(lit[1]:Lerp(white, share), lit[2]:Lerp(white, share))
	end
end

return LeadCard
