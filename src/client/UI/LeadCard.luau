--!strict
-- LeadCard (client UI): the lead's card, top left of the HUD, in the director's picks of 2026-11-13 from the mocks (TR3,
-- the director's eye): Midnight's lacquered black, the Ember lights, the portrait its biggest thing with the head
-- standing over the frame's top rim. Its art is the builder's kit (tools/blender/lead_card_art.py; Config.UIKit's Card*
-- images and LeadCard shape, in the card's own points, one authored pixel each). Laid bottom to top: the housing and its
-- rim, the two lights, the name's tab and its rim, the name and class mark, the face, its rarity's frame, the head over
-- the frame, the type's stud where the bars meet the frame, the level's badge. The rims take the lead's rarity's colour
-- (TR3's verdict, fix 3: Config.Hud.Card.Trim). Fallen, the face and head dim; never a red wash.
--   LeadCard.new(parent, position)        the card, hidden until it has a lead
--   LeadCard.Who(card, voidkinId?, down)  the face, the frame and the trims
--   LeadCard.Kind(card, type, class)      the stud's gem and the class mark
--   LeadCard.Name(card, text)             the name, its tab cut to fit it
--   LeadCard.Fill(bar, share)             a light's share, 0 to 1 (card.Health, card.Xp, a target card's Health)
-- UI.TargetCard is built from the same parts: Lay, Image, Light, Relight, Stud and Digits below.

local TextService = game:GetService("TextService")

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

local G = UIKit.LeadCard
local FRAME = G.Frame -- x, y, w, h
local SLANT = G.Slant
-- The box the card answers for (the HUD's overlap and band checks): the housing's end, and the badge's foot. Its art
-- reaches a little past it (the shadow, the head, a high rarity's crest and glow).
local BOX = Vector2.new(212, G.Badge[2] + G.Badge[4] / 2 + 1)
local NAME_X = 66 -- the name's left, on the tab
local NAME_ROOM = 104 -- the longest name, authored pixels: past it, it's cut with "…"
local TAB_AFTER = 26 -- the tab runs on past the name this far, the class mark in it
local CLASS_AFTER = 10.5 -- the class mark's centre past the name
local CLASS = 12 -- the class mark's size
local STUD = 6.5 -- the type's stud's radius, where the bars meet the frame
local INK = Color3.fromHex("#000000") -- the stud's well, Midnight's ink
local DIGITS_INK = Color3.fromHex("#0B0C10") -- the outline of the health digits on the light
local NAME_FONT = Enum.Font.BuilderSansBold -- the name's face, for measuring (Theme.Font.Strong)

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
-- empty point along that edge (the lead's: the frame's right side, its left end under the frame). Laid again at the next
-- Fill (an elite's card swaps its light for the elite's, taller: UI.TargetCard).
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
	-- From the light's foot's left, in the bar's own place.
	Skin.Set(lit, kit, { X = left - h * SLANT - from, Y = 0, W = w, H = h })
end

-- The type's stud: a well in Midnight's ink, its rim (a UIStroke named Rim, in the trim's colour), the type's gem in it.
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

-- The health digits on a light, centred on the share that shows, outlined so they read on the empty slot too.
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

function LeadCard.new(parent: Instance, position: UDim2): Card
	local card = Instance.new("Frame")
	card.Name = "Lead"
	card.BackgroundTransparency = 1
	card.Size = UDim2.fromOffset(BOX.X, BOX.Y)
	card.Position = position
	card.Visible = false
	card.Parent = parent
	image(card, "Housing", "CardHousing", 1)
	image(card, "HousingRim", "CardHousingRim", 2)
	local health = light(card, "Health", "CardLightHealth", G.Health, G.FillFrom, 3)
	local xp = light(card, "Xp", "CardLightXp", G.Xp, G.FillFrom, 3)
	image(card, "Tab", "CardTab", 4)
	image(card, "TabRim", "CardTabRim", 5)
	-- The name on its tab, Builder Sans Bold; the class mark after it.
	local name = Text.new({
		Name = "Name",
		Size = Theme.Text.Body,
		Font = Theme.Font.Strong,
		Truncate = true,
		Box = UDim2.fromOffset(NAME_ROOM, G.Tab[2] - G.Tab[1] - 2.4),
		Position = UDim2.fromOffset(NAME_X, G.Tab[1]),
		Parent = card,
	})
	name.ZIndex = 6
	local mark = Instance.new("Frame") -- moved along as the name changes
	mark.Name = "ClassMark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Size = UDim2.fromOffset(CLASS, CLASS)
	mark.Position = UDim2.fromOffset(NAME_X + CLASS_AFTER, (G.Tab[1] + G.Housing[2]) / 2)
	mark.ZIndex = 6
	mark.Parent = card
	local class = Skin.Icon(mark, "ClassWarrior", CLASS / 2, CLASS / 2, CLASS, nil, 1)
	class.Name = "Class"
	local healthText = digits(health)
	-- The portrait: its face, its rarity's frame, its head over the frame's top rim.
	local portrait = Instance.new("Frame")
	portrait.Name = "Portrait"
	portrait.BackgroundTransparency = 1
	portrait.Position = UDim2.fromOffset(FRAME[1], FRAME[2])
	portrait.Size = UDim2.fromOffset(FRAME[3], FRAME[4])
	portrait.ZIndex = 7
	portrait:SetAttribute("Voidkin", "-")
	portrait:SetAttribute("Dim", false)
	portrait.Parent = card
	-- The type's stud where the bars meet the frame.
	local gem = stud(card, Vector2.new(FRAME[1] + FRAME[3] + 0.5, G.Mid), 8)
	-- The level on its badge, biting the frame's lower left corner.
	local bx, by, bw, bh = G.Badge[1], G.Badge[2], G.Badge[3], G.Badge[4]
	image(card, "Badge", "CardBadge", 9)
	image(card, "BadgeRim", "CardBadgeRim", 10)
	local level = Text.new({
		Name = "Level",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Number,
		Colour = HudConfig.Card.Level,
		Align = Enum.TextXAlignment.Center,
		Box = UDim2.fromOffset(bw, bh),
		Position = UDim2.fromOffset(bx - bw / 2, by - bh / 2),
		Parent = card,
	})
	level.ZIndex = 11
	local made: Card = { Frame = card, Name = name, Level = level, Health = health, HealthText = healthText, Xp = xp, Portrait = portrait, Gem = gem, Class = class }
	LeadCard.Name(made, "")
	LeadCard.Fill(health, 0)
	LeadCard.Fill(xp, 0)
	LeadCard.Who(made, nil, false)
	return made
end

-- The name, and the tab cut to fit it: Builder Sans Bold at the size the label draws (it grows on a small phone).
function LeadCard.Name(card: Card, text: string)
	local label = card.Name
	local key = `{text}\0{label.TextSize}`
	if label:GetAttribute("Fitted") == key then
		return
	end
	label:SetAttribute("Fitted", key)
	label.Text = text
	local wide = math.min(TextService:GetTextSize(text, label.TextSize, NAME_FONT, Vector2.new(1000, 100)).X, NAME_ROOM)
	local top = G.Tab[4] -- the tab's top edge's left end
	local reach = NAME_X + wide + TAB_AFTER - top -- its top edge's width
	local run = (G.Tab[2] - G.Tab[1]) * SLANT
	local size = Vector2.new(reach + run, G.Tab[2] - G.Tab[1])
	for _, name in { "Tab", "TabRim" } do
		local tab = card.Frame:FindFirstChild(name) :: ImageLabel
		at(tab, `Card{name}`, Vector2.zero, size)
	end
	local mark = card.Class.Parent :: Frame
	mark.Position = UDim2.fromOffset(NAME_X + wide + CLASS_AFTER, mark.Position.Y.Offset)
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
	for _, name in { "HousingRim", "TabRim", "BadgeRim" } do
		(card.Frame:FindFirstChild(name) :: ImageLabel).ImageColor3 = trim
	end
	((card.Gem.Parent :: Frame):FindFirstChild("Rim") :: UIStroke).Color = trim
end

return LeadCard
