--!strict
-- TargetCard (client UI): the foe's card, top centre of the HUD, only in a fight (AR45; research's pick of 2026-11-19,
-- 13:35, "the lead card's own material, mirrored"). One plate in the lead card's indigo with its lavender rim, its top
-- left square and its ends leaning right, so it faces the lead's card: you against it (build/handoff/UI/foes/foes.json,
-- `card`; Config.UIKit.FoeCard). Its top row: the difficulty skull and "Lv N" in the tier's colour (Config.Hud.Skulls,
-- Rules.Hud.Skull), the name in the card's pale, then the type's gem and the type edge's arrow (Rules.Hud.Arrow), green
-- up or red down. Under it the health light in the plate's slot, leaning with it and filling from its left, its digits
-- straight on the light, ivory in a solid dark outline that holds over the light's front at any fill (LeadCard.Digits;
-- research's must-fix 2, 2026-11-19, 23:31: no band behind them). An elite's card wears the brass edge and two brass
-- shards on its top edge in place of the lavender rim (research's must-fix, 12:32). Every other word wears a hairline
-- dark outline. The plate is Modulo's (foe_cards.py), the light the builder's kit (lead_card_art.py, `foe`).
--   TargetCard.new(parent, position)      the card, hidden; its top centre at `position`
--   TargetCard.Name(card, name, level)    the name and the level, the name cut with "…" before the gem
--   TargetCard.Tier(card, tier)           the skull's tier, 1 grey and faint to 4 red, and the level's colour with it
--   TargetCard.Point(card, way)           the type edge's arrow: "Up", "Down" or "" for none
--   TargetCard.Elite(card, on)            an elite's brass edge and shards, or the plain rim


local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Theme)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)
local LeadCard = require(script.Parent.LeadCard)

export type Card = {
	Frame: Frame,
	Name: TextLabel,
	Level: TextLabel,
	Health: Frame,
	HealthText: TextLabel,
	Gem: ImageLabel,
	Skull: ImageLabel,
	Arrow: ImageLabel,
	Edge: ImageLabel,
	Elite: Frame,
}

local TargetCard = {}

local F = UIKit.FoeCard
local VOIDKIN = UIKit.Systems.Voidkin -- the lead card's colours: its rim, its pale words
local W, H = F.Size.X, F.Size.Y
local LEAN = F.Lean * H -- the plate's ends lean right this far across its height
local SLOT_TOP, SLOT_FOOT, SLOT_IN = F.Slot[1], F.Slot[2], F.Slot[3]
local SLOT_H = SLOT_FOOT - SLOT_TOP
local RUN = SLOT_H * F.Lean -- the light's ends lean this far across its height
local LIGHT_LEFT = SLOT_TOP * F.Lean + SLOT_IN -- the slot's top left, from the card's left
local LIGHT_RIGHT = W - LEAN + SLOT_FOOT * F.Lean - SLOT_IN - RUN -- its top right, the light's full front
local LIGHT_MID = (LIGHT_LEFT + LIGHT_RIGHT + RUN) / 2 -- its middle at half its height
local ROW = 11.04 -- the top row's middle: the skull's, the level's, the name's, the gem's and the arrow's
local INSET = 10 * F.Lean -- the top row starts this far in (the left end at its middle, leaning right)
local SKULL_AT, SKULL = 14 + INSET, 18 * 15 / 16 -- the skull's centre from the card's left, its box (drawn 15 high)
local LEVEL_X = 25 + INSET -- the level's left
local GAP = 7 -- between the level and the name
local GEM_AT, GEM = W - LEAN - 14, 15 -- the gem's centre, clear of the right end, which leans in at the top; its size
local ARROW_AT, ARROW = GEM_AT + 12, 10 -- the arrow's centre past the gem, its box
local NAME_END = GEM_AT - GEM / 2 - 4 -- the name stops short of the gem
local WORDS = 16 -- the words' box, high
local SHARD_ROOT = 14 -- an elite's shard's root on the top edge, in from where that edge starts and ends
local INK = Color3.fromHex("#0B0913") -- the words' hairline outline (foe_cards.py's `finish`)
local IVORY = Color3.fromHex("#F7F1E3") -- the health's digits

local function outline(label: TextLabel)
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Thickness = 1
	stroke.Transparency = 0.1
	stroke.Parent = label
end

local function plate(parent: Instance, name: string, kit: string, z: number): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = name
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.ZIndex = z
	Skin.Set(image, kit, { X = 0, Y = 0, W = W, H = H })
	image.Parent = parent
	return image
end

-- A shard's root on the top edge at x: the image placed by its anchor (foes.json's RankShardLeft/Right).
local function shard(parent: Instance, kit: string, x: number, anchor: Vector2): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = kit
	image.BackgroundTransparency = 1
	image.ZIndex = 1
	Skin.Set(image, kit, { X = x - anchor.X, Y = -anchor.Y })
	image.Parent = parent
	return image
end

function TargetCard.new(parent: Instance, position: UDim2): Card
	local card = Instance.new("Frame")
	card.Name = "Target"
	card.BackgroundTransparency = 1
	card.Size = UDim2.fromOffset(W, H)
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = position
	card.Visible = false
	card.Parent = parent
	plate(card, "Plate", "CardSlantFill", 1)
	local edge = plate(card, "Edge", "CardSlantEdge", 2)
	edge.ImageColor3 = VOIDKIN.Colour
	-- The light in the slot: its top edge from the slot's top left to the full front, leaning right (LeadCard.Fill's Lean).
	local health = LeadCard.Light(card, "Health", "CardFoeHealth", { LIGHT_LEFT, SLOT_TOP, LIGHT_RIGHT, SLOT_H }, LIGHT_LEFT, 3)
	health:SetAttribute("Lean", F.Lean)
	local digits = LeadCard.Digits(health)
	digits.TextColor3 = IVORY
	digits.Position = UDim2.fromOffset(LIGHT_MID - (LIGHT_LEFT + LIGHT_RIGHT) / 2, 0) -- centred on the light's middle
	local skull = Instance.new("ImageLabel")
	skull.Name = "Skull"
	skull.BackgroundTransparency = 1
	skull.ZIndex = 4
	Skin.Set(skull, "Skull", { X = SKULL_AT - SKULL / 2, Y = ROW - SKULL / 2, Size = SKULL })
	skull.Parent = card
	local level = Text.new({
		Name = "Level",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Box = UDim2.fromOffset(48, WORDS),
		Position = UDim2.fromOffset(LEVEL_X, ROW - WORDS / 2),
		Parent = card,
	})
	level.ZIndex = 4
	outline(level)
	local name = Text.new({
		Name = "Name",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Colour = VOIDKIN.Pale,
		Truncate = true,
		Box = UDim2.fromOffset(NAME_END - LEVEL_X, WORDS),
		Position = UDim2.fromOffset(LEVEL_X, ROW - WORDS / 2),
		Parent = card,
	})
	name.ZIndex = 4
	outline(name)
	local gem = Skin.Icon(card, "GemRed", GEM_AT, ROW, GEM, nil, 4)
	gem.Name = "Gem"
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.ZIndex = 4
	Skin.Set(arrow, "EdgeArrow", { X = ARROW_AT - ARROW / 2, Y = ROW - ARROW / 2, Size = ARROW })
	arrow:SetAttribute("Way", "")
	arrow.Visible = false
	arrow.Parent = card
	-- An elite's own: the two shards, over the plate's top edge (the brass edge is the Edge's image swapped).
	local elite = Instance.new("Frame")
	elite.Name = "Elite"
	elite.BackgroundTransparency = 1
	elite.Size = UDim2.fromScale(1, 1)
	elite.ZIndex = 5
	elite.Visible = false
	elite.Parent = card
	shard(elite, "RankShardLeft", SHARD_ROOT, Vector2.new(5.5, 8))
	shard(elite, "RankShardRight", W - LEAN - SHARD_ROOT, Vector2.new(4.5, 8))
	local made: Card = {
		Frame = card,
		Name = name,
		Level = level,
		Health = health,
		HealthText = digits,
		Gem = gem,
		Skull = skull,
		Arrow = arrow,
		Edge = edge,
		Elite = elite,
	}
	card:SetAttribute("Elite", false)
	TargetCard.Name(made, "", "")
	TargetCard.Tier(made, 2)
	LeadCard.Fill(health, 0)
	return made
end

-- The name after the level: measured at the sizes the labels draw (they grow on a small phone), the name holding what's
-- left before the gem. Nothing when unchanged.
function TargetCard.Name(card: Card, text: string, level: string)
	local key = `{text}\0{level}\0{card.Name.TextSize}\0{card.Name.FontFace.Family}\0{card.Name.FontFace.Weight.Value}\0{Text.Epoch()}`
	if card.Frame:GetAttribute("Fitted") == key then
		return
	end
	card.Frame:SetAttribute("Fitted", key)
	card.Level.Text = level
	card.Name.Text = text
	local x = LEVEL_X + (if level == "" then 0 else Text.Wide(card.Level, level) + GAP)
	card.Name.Position = UDim2.fromOffset(x, card.Name.Position.Y.Offset)
	card.Name.Size = UDim2.fromOffset(math.max(0, NAME_END - x), WORDS)
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
	Skin.Set(card.Edge, if on then "CardSlantRankEdge" else "CardSlantEdge", { X = 0, Y = 0, W = W, H = H })
	card.Edge.ImageColor3 = if on then Color3.new(1, 1, 1) else VOIDKIN.Colour -- the brass in its own colours
end

return TargetCard
