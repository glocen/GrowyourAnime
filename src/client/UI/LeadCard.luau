--!strict
-- LeadCard (client UI): the lead's card, top left of the HUD, in take F (AR12, the director's pick of 2026-11-15: "let
-- try F i dont want segments tho just a bar"). The portrait is its biggest thing, the head standing over its rarity's
-- frame; beside it one plate on a slant: the name's row on top, one solid health bar in ruby (wine at its root, hot at
-- its front), its digits under it, and experience a lavender thread 3 thick at its foot. The type's stud sits at the
-- bar's root, the level on a badge on the frame's foot (TR24, the director's run, fix 6). Its colours are take A (AR12,
-- research's pick of 2026-11-17): the card wears the Voidkin's row as the HUD's pills wear theirs (Config.UIKit.Systems
-- .Voidkin): its Panel for the body with no band, a lavender edge, its pale for the words, the level in ink on its Block.
-- No glow round the frame (the director, 2026-11-15: "let remove this light aura"). Its art is the builder's kit
-- (tools/blender/lead_card_art.py; Config.UIKit's Card* images and its LeadPlate shape, in the card's own points, one
-- authored pixel each), with Modulo's stud (AR12's colour) and TR17's chevrons. Laid bottom to top: the plate and its
-- rim, the two lights, the name and class mark, the health's digits, the face, its rarity's frame, the head over the
-- frame, the stud and its gem, the level's badge. Only the frame says the rarity (Config.Hud.Card.Trim); the stud takes
-- the type's colour (Config.Hud.Card.Types). Fallen, the face and head dim; never a red wash.
--   LeadCard.new(parent, position)        the card, hidden until it has a lead
--   LeadCard.Who(card, voidkinId?, down)  the face, the frame and the trims
--   LeadCard.Kind(card, type, class)      the stud's colour and gem, and the class mark
--   LeadCard.Name(card, text)             the name, cut with "…" past its room
--   LeadCard.Fill(bar, share)             a light's share, 0 to 1 (card.Health, card.Xp, a target card's Health)
-- UI.TargetCard (the foe's card) shares its Light and its Digits below.


local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Theme = require(script.Parent.Theme)
local Skin = require(script.Parent.Kit.Skin)
local Text = require(script.Parent.Kit.Text)

export type Card = {
	Frame: Frame,
	Name: TextLabel,
	Level: TextLabel,
	Health: Frame,
	HealthText: TextLabel,
	Xp: Frame,
	Portrait: Frame,
	Gem: ImageLabel,
	Class: ImageLabel,
}

local LeadCard = {}

local G = UIKit.LeadCard -- take E's shape: the target's card is still built on it, and its Slant and Glow are shared
local P = UIKit.LeadPlate -- take F's plate
local FRAME = G.Frame -- x, y, w, h
local SLANT = G.Slant
local NAME_X = 69 -- the name's left on its row, and the health's digits' under the bar
local NAME_ROOM = 81 -- the longest name, authored pixels: past it, it's cut with "…" (the class mark fits after it)
local CLASS_AFTER = 10.5 -- the class mark's centre past the name
local CLASS = 12 -- the class mark's size
local GEM = 14.6 -- the type's gem on its stud
-- The level on a badge on the portrait's frame (docs/ui.md, the HUD, top left; TR24, the director's run, fix 6: never the
-- tab hanging under the card at another slant): a block on the card's slant over the frame's foot, its left at the
-- frame's, growing rightward with the number (UIKit.LeadPlate.Badge: its foot's left, its top, its least width, its
-- height; Modulo's mock, AR12's take A). The chevrons and the number in ink on the Voidkin's Block.
local BADGE = P.Badge
local CHEVRONS_AT, CHEVRONS = 11, 11.5 -- the chevrons' centre past the badge's foot's left, their size
local NUMBER_AT, NUMBER_AFTER = 18.5, 6.5 -- the number's left past the same, and the block past the number's end
local VOIDKIN = UIKit.Systems.Voidkin -- the card's colours, as each pill wears its system's (take A)
-- The box the card answers for (the HUD's corner, its overlap and band checks): the plate's end, and 89 tall, take E's
-- height kept (research's call, AR12), so the readout, the eye and notice B stay where they were. Its art reaches a little
-- past it: the shadow, the head, a high rarity's crest and points, and the level's badge to 91, clear of the readout's
-- corner (from 99) and the eye (from 102).
local BOX = Vector2.new(P.Plate[3], 89)
local DIGITS_INK = Color3.fromHex("#0B0C10") -- the outline of the health digits on a light (the target's card)
local DIGITS_LINE = 2 -- its width in points, solid: it holds over the light's front at any fill (research, 23:31)

-- Lays the kit image `name` at its place in the card, in a holder whose top left is at `origin` in the card's points
-- (`size`: a sliced image's box, past its pad).
local function at(image: ImageLabel, name: string, origin: Vector2, size: Vector2?)
	local im = UIKit.Images[name]
	local place = (im.At or Vector2.zero) - origin
	if size then
		Skin.Set(image, name, { X = place.X, Y = place.Y, W = size.X, H = size.Y })
	else
		Skin.Set(image, name, { X = place.X, Y = place.Y })
	end
end

local function image(parent: Instance, name: string, kit: string, z: number, origin: Vector2?): ImageLabel
	local made = Instance.new("ImageLabel")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.ZIndex = z
	at(made, kit, origin or Vector2.zero)
	made.Parent = parent
	return made
end

-- A light's slot and art: `row` is its top edge (its left end, its y, its right end when full) and its height; `from`, its
-- empty point along that edge. Laid again at the next Fill.
local function relight(bar: Frame, kit: string, row: { number }, from: number)
	local y, right, h = row[2], row[3], row[4]
	bar.Position = UDim2.fromOffset(from, y) -- the share that shows: the empty point to the light's full end
	bar.Size = UDim2.fromOffset(right - from, h)
	bar:SetAttribute("Kit", kit)
	bar:SetAttribute("Share", -1)
	bar:SetAttribute("Left", row[1])
	bar:SetAttribute("Right", right)
	bar:SetAttribute("From", from)
	bar:SetAttribute("Height", h)
end

-- A light in its slot (relight, above).
local function light(card: Frame, name: string, kit: string, row: { number }, from: number, z: number): Frame
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.BackgroundTransparency = 1
	bar.ZIndex = z
	relight(bar, kit, row, from)
	bar.Parent = card
	local lit = Instance.new("ImageLabel")
	lit.Name = "Light"
	lit.BackgroundTransparency = 1
	lit.BorderSizePixel = 0
	lit.ZIndex = 1
	lit.Parent = bar
	return bar
end

-- A light's share. Below the slices' least width (a share of a few percent) a light's image can't shrink: the lead's
-- (attribute Front) is anchored at its front, its root end sliding under the stud and frame that cover its empty point,
-- so its front shows where the share is; the target's keeps its root end in its slot, its front a little long. A light
-- with a Lean (the foe's card, AR45) leans the other way, right: its box runs from its top's left end to its foot's right,
-- that far past the front, with no glow.
function LeadCard.Fill(bar: Frame, share: number)
	local clamped = math.clamp(if share == share then share else 0, 0, 1)
	if bar:GetAttribute("Share") == clamped then
		return
	end
	bar:SetAttribute("Share", clamped)
	local lit = bar:FindFirstChild("Light") :: ImageLabel
	lit.Visible = clamped > 0
	if clamped <= 0 then
		return
	end
	local kit = bar:GetAttribute("Kit") :: string
	local left, right, from, h = bar:GetAttribute("Left") :: number, bar:GetAttribute("Right") :: number, bar:GetAttribute("From") :: number, bar:GetAttribute("Height") :: number
	local cut = UIKit.Images[kit].Cut :: { number }
	local front = from + (right - from) * clamped -- along the top edge
	local lean = bar:GetAttribute("Lean")
	if type(lean) == "number" then
		Skin.Set(lit, kit, { X = left - from, Y = 0, W = math.max(front - left + h * lean, cut[1] + cut[3]), H = h })
		return
	end
	local w = math.max(front - left + h * SLANT + G.Glow, cut[1] + cut[3])
	-- In the bar's own place: its box ends at its glow ahead of the front, or starts at its foot's left.
	local x = if bar:GetAttribute("Front") == true then front + G.Glow - w - from else left - h * SLANT - from
	Skin.Set(lit, kit, { X = x, Y = 0, W = w, H = h })
end

-- The health digits on a light, centred on the share that shows, outlined so they read on the empty slot too (the
-- target's card).
local function digits(health: Frame): TextLabel
	local label = Text.new({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Align = Enum.TextXAlignment.Center, Parent = health })
	label.ZIndex = 3
	local outline = Instance.new("UIStroke")
	outline.Color = DIGITS_INK
	outline.Transparency = 0
	outline.LineJoinMode = Enum.LineJoinMode.Round
	outline.Thickness = DIGITS_LINE -- authored: the layer's UIScale grows it (Digits, style)
	outline.Parent = label
	return label
end

LeadCard.Light = light
LeadCard.Digits = digits

-- The badge cut to fit the number, its left fixed so it grows rightward over the frame's foot; the number's label
-- anchored at its middle so the level-up's pop swells it in place (Pop.Centre).
local function fitLevel(card: Frame, level: TextLabel)
	local numberW = Text.Wide(level, level.Text)
	local x, y, h = BADGE[1], BADGE[2], BADGE[4]
	local w = math.max(NUMBER_AT + numberW + NUMBER_AFTER, BADGE[3])
	Skin.Set(card:FindFirstChild("LevelBadge") :: ImageLabel, "CardLevelBadge", { X = x, Y = y, W = w, H = h })
	level.Position = UDim2.fromOffset(x + NUMBER_AT + (numberW + 2) / 2, y + h / 2)
	level.Size = UDim2.fromOffset(numberW + 2, h)
end

function LeadCard.new(parent: Instance, position: UDim2): Card
	local card = Instance.new("Frame")
	card.Name = "Lead"
	card.BackgroundTransparency = 1
	card.Size = UDim2.fromOffset(BOX.X, BOX.Y)
	card.Position = position
	card.Visible = false
	card.Parent = parent
	image(card, "Plate", "CardPlate", 1)
	image(card, "PlateRim", "CardPlateRim", 2).ImageColor3 = VOIDKIN.Colour
	-- Each light's empty point is its row's left end: health's at the stud's right edge, experience's under the frame.
	local health = light(card, "Health", "CardLeadHealth", P.Health, P.Health[1], 3)
	local xp = light(card, "Xp", "CardLeadXp", P.Xp, P.Xp[1], 3)
	for _, bar in { health, xp } do
		bar:SetAttribute("Front", true) -- anchored at its front (Fill)
	end
	-- The name on its row, Builder Sans Bold; the class mark after it.
	local nameRow = P.Name - P.Plate[2]
	local name = Text.new({
		Name = "Name",
		Size = Theme.Text.Body,
		Font = Theme.Font.Strong,
		Truncate = true,
		Colour = VOIDKIN.Pale,
		Box = UDim2.fromOffset(NAME_ROOM, nameRow),
		Position = UDim2.fromOffset(NAME_X, P.Plate[2]),
		Parent = card,
	})
	name.ZIndex = 6
	local mark = Instance.new("Frame") -- moved along as the name changes
	mark.Name = "ClassMark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Size = UDim2.fromOffset(CLASS, CLASS)
	mark.Position = UDim2.fromOffset(NAME_X + CLASS_AFTER, P.Plate[2] + nameRow / 2)
	mark.ZIndex = 6
	mark.Parent = card
	local class = Skin.Icon(mark, "ClassWarrior", CLASS / 2, CLASS / 2, CLASS, nil, 1)
	class.Name = "Class"
	-- The health's digits under its bar, between the two slots, in the ivory of the name. Its box is centred on the gap
	-- and never shorter than the text's floor at the smallest scale (Theme.Text.Minimum over Theme.Scale.Floor): at 0.85
	-- the gap's 13 points drew 11 under a 14-point line.
	local below = P.Health[2] + P.Health[4]
	local gap = P.Xp[2] - below
	local tall = math.max(gap, math.ceil(Theme.Text.Minimum / Theme.Scale.Floor))
	local healthText = Text.new({
		Name = "HealthText",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Colour = VOIDKIN.Pale,
		Box = UDim2.fromOffset(P.Health[3] - NAME_X, tall),
		Position = UDim2.fromOffset(NAME_X, below - math.floor((tall - gap) / 2)),
		Parent = card,
	})
	healthText.ZIndex = 6
	-- The portrait: its face, its rarity's frame, its head over the frame's top.
	local portrait = Instance.new("Frame")
	portrait.Name = "Portrait"
	portrait.BackgroundTransparency = 1
	portrait.Position = UDim2.fromOffset(FRAME[1], FRAME[2])
	portrait.Size = UDim2.fromOffset(FRAME[3], FRAME[4])
	portrait.ZIndex = 7
	portrait:SetAttribute("Voidkin", "-")
	portrait:SetAttribute("Dim", false)
	portrait.Parent = card
	-- The type's stud at the health bar's root, over the frame's right side: its glow, its body, the type's gem on it.
	local cx, cy, radius = P.Stud[1], P.Stud[2], P.Stud[3]
	for z, kit in { "CardStudGlow", "CardStud" } do
		local made = Instance.new("ImageLabel")
		made.Name = if kit == "CardStud" then "Stud" else "StudGlow"
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.ZIndex = 7 + z
		Skin.Set(made, kit, { X = cx - radius, Y = cy - radius, Size = 2 * radius })
		made.Parent = card
	end
	local gem = Skin.Icon(card, "GemRed", cx, cy, GEM, nil, 10)
	gem.Name = "Gem"
	-- The level's badge on the frame's foot: the Voidkin's Block, TR17's chevrons and the number in ink on it.
	local badge = Instance.new("ImageLabel")
	badge.Name = "LevelBadge"
	badge.BackgroundTransparency = 1
	badge.BorderSizePixel = 0
	badge.ZIndex = 11
	Skin.Tint(badge, VOIDKIN.Block)
	badge.Parent = card
	local chevrons = Skin.Icon(card, "LevelChevrons", BADGE[1] + CHEVRONS_AT, BADGE[2] + BADGE[4] / 2, CHEVRONS, HudConfig.Card.LeadLevel, 12)
	chevrons.Name = "LevelChevrons"
	local level = Text.new({
		Name = "Level",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Number,
		Colour = HudConfig.Card.LeadLevel,
		Align = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = card,
	})
	level.ZIndex = 14
	local function refit()
		fitLevel(card, level)
	end
	level:GetPropertyChangedSignal("Text"):Connect(refit)
	level:GetPropertyChangedSignal("TextSize"):Connect(refit)
	refit()
	local made: Card = { Frame = card, Name = name, Level = level, Health = health, HealthText = healthText, Xp = xp, Portrait = portrait, Gem = gem, Class = class }
	LeadCard.Name(made, "")
	LeadCard.Fill(health, 0)
	LeadCard.Fill(xp, 0)
	LeadCard.Who(made, nil, false)
	return made
end

-- The name, and the class mark moved after it: in the label's own face at the size it draws (it grows on a small phone;
-- the HUD's face is Config.Hud.Face).
function LeadCard.Name(card: Card, text: string)
	local label = card.Name
	local key = `{text}\0{label.TextSize}\0{label.FontFace.Family}\0{label.FontFace.Weight.Value}\0{Text.Epoch()}`
	if label:GetAttribute("Fitted") == key then
		return
	end
	label:SetAttribute("Fitted", key)
	label.Text = text
	local wide = math.min(Text.Wide(label, text), NAME_ROOM)
	local mark = card.Class.Parent :: Frame
	mark.Position = UDim2.fromOffset(NAME_X + wide + CLASS_AFTER, mark.Position.Y.Offset)
	fitLevel(card.Frame, card.Level) -- a face that just arrived measures the level's text anew too
end

-- The type's gem and colour on the stud, and the class's mark, from the kit: nothing when unchanged.
function LeadCard.Kind(card: Card, kind: string, class: string)
	for image, name in { [card.Gem] = `Gem{kind}`, [card.Class] = `Class{class}` } do
		local im = UIKit.Images[name]
		if im and image:GetAttribute("Kit") ~= name then
			image.Image = im.Id
			image:SetAttribute("Kit", name)
		end
	end
	local colour = HudConfig.Card.Types[kind]
	if colour then
		for _, name in { "StudGlow", "Stud" } do
			(card.Frame:FindFirstChild(name) :: ImageLabel).ImageColor3 = colour
		end
	end
end

-- The face in its rarity's frame, the head over it, the rims in the rarity's colour; dimmed while it's fallen.
function LeadCard.Who(card: Card, id: string?, down: boolean)
	local portrait = card.Portrait
	local want = id or ""
	if portrait:GetAttribute("Voidkin") == want and portrait:GetAttribute("Dim") == down then
		return
	end
	portrait:SetAttribute("Voidkin", want)
	portrait:SetAttribute("Dim", down)
	local def = if want ~= "" then Voidkin.ById[want] else nil
	local rarity = if def then def.Rarity else "Common"
	local face = if def and UIKit.Images[`CardFace{def.Name}`] then `CardFace{def.Name}` else `CardFaceUnknown{rarity}`
	local head = if def and UIKit.Images[`CardHead{def.Name}`] then `CardHead{def.Name}` else nil
	portrait:ClearAllChildren()
	local origin = Vector2.new(FRAME[1], FRAME[2])
	local d = if down then 1 - HudConfig.Fallen.Dim else 1
	local dim = Color3.new(d, d, d)
	image(portrait, "Face", face, 1, origin).ImageColor3 = dim
	image(portrait, "Frame", `CardFrame{rarity}`, 2, origin)
	if head then
		image(portrait, "Head", head, 3, origin).ImageColor3 = dim
	end
	portrait:SetAttribute("Face", face)
	portrait:SetAttribute("Rarity", rarity)
end

-- The level-up's pop on the badge (HudController): its Block lifted `share` of the way to white under the ink number,
-- which keeps its ink so it reads through the flash.
function LeadCard.Glow(card: Card, share: number)
	local white = Color3.new(1, 1, 1)
	Skin.Tint(card.Frame:FindFirstChild("LevelBadge") :: ImageLabel, { VOIDKIN.Block[1]:Lerp(white, share), VOIDKIN.Block[2]:Lerp(white, share) })
end

return LeadCard
