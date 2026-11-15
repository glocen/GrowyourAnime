--!strict
-- LeadCard (client UI): the lead's card, top left of the HUD, in take F (AR12, the director's pick of 2026-11-15: "let
-- try F i dont want segments tho just a bar"). The portrait is its biggest thing, the head standing over its rarity's
-- frame; beside it one plate on a slant: the name's row on top, one solid health bar in ruby (wine at its root, hot at
-- its front), its digits under it, and experience a lavender thread at its foot. The type's stud sits at the bar's root,
-- the level's mark under the frame's lowest point. No glow round the frame (the director, 2026-11-15: "let remove this
-- light aura"). Its art is the builder's kit (tools/blender/lead_card_art.py; Config.UIKit's Card* images and its
-- LeadPlate shape, in the card's own points, one authored pixel each), with Modulo's stud (AR12's colour) and level plate
-- (TR17's marks). Laid bottom to top: the plate and its rim, the two lights, the name and class mark, the health's
-- digits, the face, its rarity's frame, the head over the frame, the stud and its gem, the level's mark. The rims take the
-- lead's rarity's colour (Config.Hud.Card.Trim), the stud its type's (Config.Hud.Card.Types). Fallen, the face and head
-- dim; never a red wash.
--   LeadCard.new(parent, position)        the card, hidden until it has a lead
--   LeadCard.Who(card, voidkinId?, down)  the face, the frame and the trims
--   LeadCard.Kind(card, type, class)      the stud's colour and gem, and the class mark
--   LeadCard.Name(card, text)             the name, cut with "…" past its room
--   LeadCard.Fill(bar, share)             a light's share, 0 to 1 (card.Health, card.Xp, a target card's Health)
-- UI.TargetCard is built from take E's parts, which stay here: Lay, Image, Light, Relight, Stud and Digits below.


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
local LEVEL_H = 22 -- the level's plate (TR17's LevelPlate): its height, its lit cap with the chevrons, its end past the number
local LEVEL_CAP, LEVEL_AFTER, LEVEL_MIN = 24, 8, 54
local LEVEL_Y = P.FrameFoot + 1 -- its top: clear of every rarity's lowest point
local CHEVRONS = 14
-- The level plate's body in the plate's name row's violet, and the chevrons in its deep (lead_card_art.VIOLET).
local LEVEL_BODY = { Color3.fromHex("#5545A6"), Color3.fromHex("#211849") }
local CHEVRON_INK = Color3.fromHex("#150F30")
-- The box the card answers for (the HUD's overlap and band checks): the plate's end, and the level plate's foot. Its art
-- reaches a little past it (the shadow, the head, a high rarity's crest).
local BOX = Vector2.new(P.Plate[3], LEVEL_Y + LEVEL_H + 1)
local STUD = 6.5 -- take E's stud's radius (the target's card)
local INK = Color3.fromHex("#000000") -- take E's stud's well, Midnight's ink
local DIGITS_INK = Color3.fromHex("#0B0C10") -- the outline of the health digits on a light (the target's card)

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
-- empty point along that edge. Laid again at the next Fill (an elite's card swaps its light for the elite's, taller:
-- UI.TargetCard).
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
-- so its front shows where the share is; the target's keeps its root end in its slot, its front a little long.
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
	local w = math.max(front - left + h * SLANT + G.Glow, cut[1] + cut[3])
	-- In the bar's own place: its box ends at its glow ahead of the front, or starts at its foot's left.
	local x = if bar:GetAttribute("Front") == true then front + G.Glow - w - from else left - h * SLANT - from
	Skin.Set(lit, kit, { X = x, Y = 0, W = w, H = h })
end

-- Take E's stud (the target's card): a well in Midnight's ink, its rim (a UIStroke named Rim), the type's gem in it.
local function stud(parent: Instance, centre: Vector2, z: number): ImageLabel
	local well = Instance.new("Frame")
	well.Name = "Stud"
	well.AnchorPoint = Vector2.new(0.5, 0.5)
	well.Position = UDim2.fromOffset(centre.X, centre.Y)
	well.Size = UDim2.fromOffset(2 * STUD, 2 * STUD)
	well.BackgroundColor3 = INK
	well.BorderSizePixel = 0
	well.ZIndex = z
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = well
	local ring = Instance.new("UIStroke")
	ring.Name = "Rim"
	ring.Thickness = 1.5
	ring.Parent = well
	well.Parent = parent
	local gem = Skin.Icon(well, "GemStrength", STUD, STUD, 2 * STUD * 0.8 + 1, nil, 1)
	gem.Name = "Gem"
	return gem
end

-- The health digits on a light, centred on the share that shows, outlined so they read on the empty slot too (the
-- target's card).
local function digits(health: Frame): TextLabel
	local label = Text.new({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Align = Enum.TextXAlignment.Center, Parent = health })
	label.ZIndex = 3
	local outline = Instance.new("UIStroke")
	outline.Color = DIGITS_INK
	outline.Thickness = 1
	outline.Parent = label
	return label
end

LeadCard.Lay = at
LeadCard.Image = image
LeadCard.Light = light
LeadCard.Relight = relight
LeadCard.Stud = stud
LeadCard.Digits = digits

-- The level's plate cut to fit "Lv" and the number, centred under the portrait (never left of the frame), the number's
-- label anchored at its middle so the level-up's pop swells it in place (Pop.Centre).
local function fitLevel(card: Frame, level: TextLabel)
	local word = card:FindFirstChild("LevelWord") :: TextLabel
	local wordW, numberW = Text.Wide(word, word.Text), Text.Wide(level, level.Text)
	local w = math.max(LEVEL_CAP + 2 + wordW + 3 + numberW + LEVEL_AFTER, LEVEL_MIN)
	local x = math.max(FRAME[1], FRAME[1] + FRAME[3] / 2 - w / 2)
	for _, name in { "LevelPlate", "LevelPlateEdge" } do
		Skin.Set(card:FindFirstChild(name) :: ImageLabel, name, { X = x, Y = LEVEL_Y, W = w, H = LEVEL_H })
	end
	Skin.Set(card:FindFirstChild("LevelChevrons") :: ImageLabel, "LevelChevrons", { X = x + LEVEL_H / 2 - CHEVRONS / 2, Y = LEVEL_Y + LEVEL_H / 2 - CHEVRONS / 2, Scale = CHEVRONS / UIKit.Images.LevelChevrons.Points.X })
	word.Position = UDim2.fromOffset(x + LEVEL_CAP + 2, LEVEL_Y)
	word.Size = UDim2.fromOffset(wordW + 1, LEVEL_H)
	local left = x + LEVEL_CAP + 2 + wordW + 3
	level.Position = UDim2.fromOffset(left + (numberW + 2) / 2, LEVEL_Y + LEVEL_H / 2)
	level.Size = UDim2.fromOffset(numberW + 2, LEVEL_H)
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
	image(card, "PlateRim", "CardPlateRim", 2)
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
	-- The health's digits under its bar, between the two slots, in the ivory of the name.
	local below = P.Health[2] + P.Health[4]
	local healthText = Text.new({
		Name = "HealthText",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Box = UDim2.fromOffset(P.Health[3] - NAME_X, P.Xp[2] - below),
		Position = UDim2.fromOffset(NAME_X, below),
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
	local gem = Skin.Icon(card, "GemStrength", cx, cy, GEM, nil, 10)
	gem.Name = "Gem"
	-- The level's mark under the frame: its plate, its rim and lit cap, the chevrons on the cap, "Lv" and the number.
	for z, kit in { "LevelPlate", "LevelPlateEdge", "LevelChevrons" } do
		local made = Instance.new("ImageLabel")
		made.Name = kit
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.ZIndex = 10 + z
		made.Parent = card
		if kit == "LevelPlate" then
			Skin.Tint(made, LEVEL_BODY)
		elseif kit == "LevelChevrons" then
			made.ImageColor3 = CHEVRON_INK
		end
	end
	local word = Text.new({ Name = "LevelWord", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Parent = card })
	word.Text = "Lv"
	word.ZIndex = 14
	local level = Text.new({
		Name = "Level",
		Size = Theme.Text.Body,
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
	word:GetPropertyChangedSignal("TextSize"):Connect(refit)
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
	local trim = HudConfig.Card.Trim[rarity]
	local white = Color3.new(1, 1, 1);
	(card.Frame:FindFirstChild("PlateRim") :: ImageLabel).ImageColor3 = trim
	Skin.Tint(card.Frame:FindFirstChild("LevelPlateEdge") :: ImageLabel, { trim:Lerp(white, 0.6), trim });
	(card.Frame:FindFirstChild("LevelWord") :: TextLabel).TextColor3 = trim:Lerp(white, 0.55)
end

return LeadCard
