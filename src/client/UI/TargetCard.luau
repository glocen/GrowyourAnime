--!strict
-- TargetCard (client UI): the foe's card, top centre of the HUD, only in a fight: B's layout in F2's finish (AR62's piece
-- 1, research's picks of 2026-11-26, 23:46 and 2026-11-27, 00:36; Config.Hud.Slate.Foe; UI.Kit.Slate). The lead card's
-- construction in the coral family that says theirs, so the two read as you against it. Its top row: the difficulty skull
-- and "Lv N" flat in the meta face in the tier's colour (Config.Hud.Skulls, Rules.Hud.Skull), the name in capitals, the
-- type edge's arrow (Rules.Hud.Arrow), green up or red down, and the type's gem at the row's end. Under it the health bar,
-- its digits on it, white in the bar's line, notched every 1,000. An elite's card wears the gold family and a second rim
-- outside it. A word never draws under the 14 px floor (UI.Kit.Text): on a
-- small phone the bar and the card grow to hold theirs (Layers.Changed).
--   TargetCard.new(parent, position)      the card, hidden; its top centre at `position`
--   TargetCard.Name(card, name, level)    the name and the level, the name cut with "…" before the arrow
--   TargetCard.Tier(card, tier)           the skull's tier, 1 grey and faint to 4 red, and the level's colour with it
--   TargetCard.Point(card, way)           the type edge's arrow: "Up", "Down" or "" for none
--   TargetCard.Elite(card, on)            an elite's gold rims, or the coral

local Shared = game:GetService("ReplicatedStorage").Shared
local HudConfig = require(Shared.Config.Hud)
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
	Gem: ImageLabel,
	Skull: ImageLabel,
	Arrow: ImageLabel,
	Edge: Frame,
	Elite: Frame,
}

local TargetCard = {}

local pt = Slate.Pt
local LINE = 1.15 -- a word's box, its size times this

local function slate(): any
	return HudConfig.Slate
end

type Shape = { W: number, H: number, In: number, RowY: number, Row: number, BarTop: number, BarH: number, Level: number, Name: number }

local function shape(): Shape
	local f = slate().Foe
	local scale = Layers.Scale()
	local name = Text.Legible(pt(f.Name), scale, Slate.Floor())
	local level = Text.Legible(pt(f.Level), scale, Slate.Floor())
	local digits = Text.Legible(pt(f.Digits), scale, Slate.Floor())
	local row = math.max(name, level, pt(f.Skull)) * LINE
	local barTop = math.max(pt(f.BarTop), pt(f.RowTop) + row)
	local barH = math.max(pt(f.Bar), digits + 1)
	local foot = pt(f.Size.Y - f.BarTop - f.Bar) -- the target's room under the bar
	return {
		W = pt(f.Size.X),
		H = math.max(pt(f.Size.Y), barTop + barH + foot),
		In = pt(f.Inset),
		RowY = pt(f.RowTop) + row / 2,
		Row = row,
		BarTop = barTop,
		BarH = barH,
		Level = level,
		Name = name,
	}
end

-- The right of the name's room: short of the arrow, which stands before the gem.
local function nameEnd(s: Shape): number
	local f = slate().Foe
	return s.W - s.In - pt(f.Gem) - pt(4) - pt(12) - pt(4)
end

local function place(card: Card)
	local s = shape()
	local f = slate().Foe
	local frame = card.Frame
	local skull = pt(f.Skull)
	local levelX = s.In + skull + pt(5)
	local x = levelX + (if card.Level.Text == "" then 0 else Text.Wide(card.Level, card.Level.Text) + pt(f.Gap))
	-- Wide enough for its whole name where the floor lifts the words on a small phone, up to Wide of its own: centred,
	-- it widens both ways.
	local tail = s.W - nameEnd(s)
	s.W = math.clamp(math.ceil(x + Text.Wide(card.Name, card.Name.Text) + 2 + tail), s.W, math.max(s.W, math.floor(pt(f.Size.X * (f.Wide or 1)))))
	frame.Size = UDim2.fromOffset(s.W, s.H)
	card.Skull.Position = UDim2.fromOffset(s.In, s.RowY - skull / 2)
	card.Skull.Size = UDim2.fromOffset(skull, skull)
	card.Level.Position = UDim2.fromOffset(levelX, s.RowY - s.Row / 2)
	card.Level.Size = UDim2.fromOffset(Text.Wide(card.Level, card.Level.Text) + 2, s.Row)
	card.Name.Position = UDim2.fromOffset(x, s.RowY - s.Row / 2)
	card.Name.Size = UDim2.fromOffset(math.max(0, nameEnd(s) - x), s.Row)
	local gem = pt(f.Gem)
	card.Gem.Position = UDim2.fromOffset(s.W - s.In - gem, s.RowY - gem / 2)
	local arrow = pt(12)
	card.Arrow.Position = UDim2.fromOffset(s.W - s.In - gem - pt(4) - arrow, s.RowY - arrow / 2)
	card.Arrow.Size = UDim2.fromOffset(arrow, arrow)
	Slate.Shape(card.Health, Vector2.new(s.In, s.BarTop), Vector2.new(s.W - 2 * s.In, s.BarH))
end

function TargetCard.new(parent: Instance, position: UDim2): Card
	local c = slate()
	local f = c.Foe
	local s = shape()
	local card = Slate.Plate(parent, "Target", Vector2.new(s.W, s.H), "Theirs")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = position
	card.Visible = false
	local skull = Instance.new("ImageLabel")
	skull.Name = "Skull"
	skull.BackgroundTransparency = 1
	skull.ZIndex = 3
	Skin.Set(skull, "Skull", { X = 0, Y = 0, Size = pt(f.Skull) })
	skull.Parent = card
	local level = Slate.Meta(card, "Level", pt(f.Level))
	level.ZIndex = 3
	local name = Slate.Word(card, "Name", pt(f.Name))
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.ZIndex = 3
	local gem = Skin.Icon(card, "GemRed", 0, 0, pt(f.Gem), nil, 3)
	gem.Name = "Gem"
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.ZIndex = 3
	Skin.Set(arrow, "EdgeArrow", { X = 0, Y = 0, Size = pt(12) })
	arrow:SetAttribute("Way", "")
	arrow.Visible = false
	arrow.Parent = card
	local health = Slate.Bar(card, "Health", Vector2.new(s.In, s.BarTop), Vector2.new(s.W - 2 * s.In, s.BarH), "Health", pt(c.Bar.Radius))
	health.ZIndex = 3
	local digits = Slate.OnBar(health, pt(f.Digits))
	digits.Name = "HealthText"
	-- An elite's second rim, outside the plate.
	local elite = Instance.new("Frame")
	elite.Name = "Elite"
	elite.BackgroundTransparency = 1
	elite.AnchorPoint = Vector2.new(0.5, 0.5)
	elite.Position = UDim2.fromScale(0.5, 0.5)
	elite.Size = UDim2.new(1, 2 * pt(c.Elite.Out), 1, 2 * pt(c.Elite.Out))
	elite.ZIndex = 3
	elite.Visible = false
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, s.H * c.Kinds.Card.Round + pt(c.Elite.Out))
	round.Parent = elite
	local line = Instance.new("UIStroke")
	line.Name = "Line"
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Color = c.Sides.Elite.Band[2]
	line.Thickness = pt(c.Elite.Line)
	line.Transparency = c.Elite.Clear
	line.Parent = elite
	elite.Parent = card
	local made: Card = {
		Frame = card,
		Name = name,
		Level = level,
		Health = health,
		HealthText = digits,
		Gem = gem,
		Skull = skull,
		Arrow = arrow,
		Edge = card:FindFirstChild("Glass") :: Frame,
		Elite = elite,
	}
	card:SetAttribute("Elite", false)
	TargetCard.Name(made, "", "")
	TargetCard.Tier(made, 2)
	place(made)
	Layers.Changed:Connect(function()
		card:SetAttribute("Fitted", nil)
		place(made)
	end)
	return made
end

-- The name in capitals after the level: measured at the sizes the labels draw (they grow on a small phone), the name
-- holding what's left before the arrow. Nothing when unchanged.
function TargetCard.Name(card: Card, text: string, level: string)
	local shown = string.upper(text)
	local key = `{shown}\0{level}\0{card.Name.TextSize}\0{card.Name.FontFace.Family}\0{Text.Epoch()}`
	if card.Frame:GetAttribute("Fitted") == key then
		return
	end
	card.Frame:SetAttribute("Fitted", key)
	card.Level.Text = level
	card.Name.Text = shown
	place(card)
end

-- The skull's tier and the level's colour with it (Config.Hud.Skulls): the grey skull faint, its level whole (research's
-- must-fix 2: at least 4.5 to 1 over the card).
function TargetCard.Tier(card: Card, tier: number)
	local skulls = HudConfig.Skulls
	local colour = skulls.Colours[math.clamp(tier, 1, #skulls.Colours)]
	card.Skull.ImageColor3 = colour
	card.Skull.ImageTransparency = if tier == 1 then skulls.Faint else 0
	card.Level.TextColor3 = colour
	card.Frame:SetAttribute("Tier", tier)
end

-- The type edge's arrow: up as drawn, green, the lead hits this foe harder; down turned over, red (Config.Hud.Arrow).
function TargetCard.Point(card: Card, way: string)
	local arrow = card.Arrow
	if arrow:GetAttribute("Way") == way then
		return
	end
	arrow:SetAttribute("Way", way)
	arrow.Visible = way ~= ""
	arrow.ImageColor3 = if way == "Up" then HudConfig.Arrow.Up else HudConfig.Arrow.Down
	arrow.Rotation = if way == "Up" then 0 else 180
end

function TargetCard.Elite(card: Card, on: boolean)
	if card.Frame:GetAttribute("Elite") == on then
		return
	end
	card.Frame:SetAttribute("Elite", on)
	card.Elite.Visible = on
	Slate.Side(card.Frame, if on then "Elite" else "Theirs")
end

return TargetCard
