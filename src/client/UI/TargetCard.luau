--!strict
-- TargetCard (client UI): the target's card, top centre of the HUD, only in a fight, built like the lead's (TR3, point 3;
-- research's pass on the lead card, 2026-11-13). The lead card's parts (UI.LeadCard): Midnight's blade with the health
-- slot only (Config.UIKit's CardTargetHousing, sliced to the card's length), the lead's name tab cut to fit, the Ember
-- light, the type's stud pinning the blade's left end. In the tab: the type edge's arrow (the HUD's), the name, the level
-- in Config.Hud.Card.Level's gold. Its rims take Config.Hud.Card.TargetTrim. Laid in its own points (Config.UIKit.TargetCard); the lead's
-- images it shares are moved by its Offset, so its tab and light sit on its blade as they sit on the lead's.
--   TargetCard.new(parent, position)      the card, hidden; its top centre at `position`
--   TargetCard.Name(card, name, level)    the name and the level, the tab cut to fit them
--   TargetCard.ArrowAt                    the type edge's arrow's centre, in the card's points
--   TargetCard.Elite(card, on)            an elite's card (TR5's variant C), in Modulo's frames (TR5, "Modulo's frames,
--                                         delivered"; Config.UIKit's CardTargetElite* images and EliteCard): its blade 6
--                                         taller with its light 23 high, the stud moved down with it, the heavier frame
--                                         round the blade in Config.Hud.Boss.EliteFrame, and at the blade's right end a tab
--                                         of its own with the crest notch and the word Elite in the card's ink (research's
--                                         verdict, 2026-11-14, fix 3). The name's tab ends before it. Off, the plain card.


local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.Config.UIKit)
local HudConfig = require(Shared.Config.Hud)
local Theme = require(script.Parent.Theme)
local Text = require(script.Parent.Kit.Text)
local LeadCard = require(script.Parent.LeadCard)

export type Card = {
	Frame: Frame,
	Name: TextLabel,
	Level: TextLabel,
	Health: Frame,
	HealthText: TextLabel,
	Gem: ImageLabel,
}

local TargetCard = {}

local T = UIKit.TargetCard
local E = UIKit.EliteCard -- an elite's, in the same points
local L = UIKit.LeadCard
local ORIGIN = -T.Offset -- where the shared images, placed in the lead's points, land in this card's
local TAB_TOP, TAB_FOOT, TAB_LEFT = L.Tab[1], L.Tab[2], L.Tab[4] -- the lead's points: its top, its foot, its top's left end
local TAB_MID = (TAB_TOP + L.Housing[2]) / 2 -- the middle of the tab's part above the blade
local NAME_X = 72 -- the name's left on the tab, in the lead's points: the arrow before it
local GAP = 5 -- between the name and the level
local TAB_AFTER = 10 -- the tab runs on past the level this far
local NAME_ROOM = 120 -- the longest name, authored pixels: past it, it's cut with "…"

-- The arrow just inside the tab's slanted left edge, at the middle of its height.
TargetCard.ArrowAt = Vector2.new(TAB_LEFT - (TAB_MID - TAB_TOP) * L.Slant + 6.5, TAB_MID) + T.Offset

function TargetCard.new(parent: Instance, position: UDim2): Card
	local card = Instance.new("Frame")
	card.Name = "Target"
	card.BackgroundTransparency = 1
	card.Size = UDim2.fromOffset(T.Size.X, T.Size.Y)
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = position
	card.Visible = false
	card.Parent = parent
	local length = Vector2.new(T.Housing[3] - T.Housing[1], T.Housing[4] - T.Housing[2])
	for z, kit in { "CardTargetHousing", "CardTargetHousingRim" } do
		local blade = LeadCard.Image(card, if z == 1 then "Housing" else "HousingRim", kit, z, ORIGIN)
		LeadCard.Lay(blade, kit, ORIGIN, length)
	end
	local health = LeadCard.Light(card, "Health", "CardLightHealth", T.Health, T.FillFrom, 3)
	LeadCard.Image(card, "Tab", "CardTab", 4, ORIGIN)
	LeadCard.Image(card, "TabRim", "CardTabRim", 5, ORIGIN)
	local box = TAB_FOOT - TAB_TOP - 2.4 -- the tab's height over the blade
	local name = Text.new({
		Name = "Name",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Truncate = true,
		Box = UDim2.fromOffset(NAME_ROOM, box),
		Position = UDim2.fromOffset(NAME_X + T.Offset.X, TAB_TOP + T.Offset.Y),
		Parent = card,
	})
	name.ZIndex = 6
	local level = Text.new({
		Name = "Level",
		Size = Theme.Text.Caption,
		Colour = HudConfig.Card.Level,
		Box = UDim2.fromOffset(48, box),
		Position = UDim2.fromOffset(NAME_X + T.Offset.X, TAB_TOP + T.Offset.Y),
		Parent = card,
	})
	level.ZIndex = 6
	local healthText = LeadCard.Digits(health)
	local gem = LeadCard.Stud(card, T.Stud, 8)
	local trim = HudConfig.Card.TargetTrim
	for _, rim in { "HousingRim", "TabRim" } do
		(card:FindFirstChild(rim) :: ImageLabel).ImageColor3 = trim
	end
	((gem.Parent :: Frame):FindFirstChild("Rim") :: UIStroke).Color = trim
	local made: Card = { Frame = card, Name = name, Level = level, Health = health, HealthText = healthText, Gem = gem }
	TargetCard.Name(made, "", "")
	LeadCard.Fill(health, 0)
	return made
end

-- The name and the level after it, and the tab cut to fit both: measured at the sizes the labels draw (they grow on a
-- small phone). On an elite's card the name's tab ends by the Elite tab (Config.UIKit.EliteCard.NameTabEnd), so its name
-- holds what's left. The tab's top edge's right end is the card's TabEnd attribute, in its points. Nothing when unchanged.
function TargetCard.Name(card: Card, text: string, level: string)
	local elite = card.Frame:GetAttribute("Elite") == true
	local key = `{text}\0{level}\0{card.Name.TextSize}\0{elite}\0{card.Name.FontFace.Family}\0{card.Name.FontFace.Weight.Value}\0{Text.Epoch()}`
	if card.Frame:GetAttribute("Fitted") == key then
		return
	end
	card.Frame:SetAttribute("Fitted", key)
	card.Name.Text = text
	card.Level.Text = level
	local after = Text.Wide(card.Level, level)
	local room = NAME_ROOM
	if elite then
		local most = E.NameTabEnd - T.Offset.X - TAB_LEFT -- the tab's top edge's longest, in the lead's points
		room = math.max(0, math.min(NAME_ROOM, most - (NAME_X - TAB_LEFT) - GAP - after - TAB_AFTER))
	end
	card.Name.Size = UDim2.fromOffset(room, card.Name.Size.Y.Offset)
	local wide = math.min(Text.Wide(card.Name, text), room)
	card.Level.Position = UDim2.fromOffset(NAME_X + wide + GAP + T.Offset.X, card.Level.Position.Y.Offset)
	local reach = NAME_X + wide + GAP + after + TAB_AFTER - TAB_LEFT -- the tab's top edge's width, in the lead's points
	local run = (TAB_FOOT - TAB_TOP) * L.Slant
	local size = Vector2.new(reach + run, TAB_FOOT - TAB_TOP)
	for _, name in { "Tab", "TabRim" } do
		LeadCard.Lay(card.Frame:FindFirstChild(name) :: ImageLabel, `Card{name}`, ORIGIN, size)
	end
	card.Frame:SetAttribute("TabEnd", TAB_LEFT + reach + T.Offset.X)
end

-- An elite's own parts, built hidden the first time they're asked for: the heavier frame under the name's tab, and the
-- Elite tab, its rim and its word over the rest (the holder named Elite).
local function eliteParts(card: Card): (ImageLabel, Frame)
	local found = card.Frame:FindFirstChild("Elite")
	if found and found:IsA("Frame") then
		return card.Frame:FindFirstChild("EliteFrame") :: ImageLabel, found
	end
	local frame = LeadCard.Image(card.Frame, "EliteFrame", "CardTargetEliteFrame", 3, ORIGIN)
	frame.Visible = false
	local holder = Instance.new("Frame")
	holder.Name = "Elite"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 7
	holder.Visible = false
	holder.Parent = card.Frame
	LeadCard.Image(holder, "EliteTab", "CardTargetEliteTab", 1, ORIGIN)
	local rim = LeadCard.Image(holder, "EliteTabRim", "CardTargetEliteTabRim", 2, ORIGIN)
	rim.ImageColor3 = HudConfig.Card.TargetTrim
	local tab = E.Tab -- its top's left and right, its foot's right and left
	local word = Text.new({
		Name = "Word",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Align = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Box = UDim2.fromOffset(tab[2].X - tab[1].X, TAB_FOOT - TAB_TOP - 2.4),
		Position = UDim2.fromOffset(E.Word.X, E.Word.Y),
		Parent = holder,
	})
	word.Text = "Elite"
	word.ZIndex = 3
	return frame, holder
end

function TargetCard.Elite(card: Card, on: boolean)
	local frame, holder = eliteParts(card)
	if card.Frame:GetAttribute("Elite") == on then
		return
	end
	card.Frame:SetAttribute("Elite", on)
	card.Frame:SetAttribute("Fitted", nil) -- the name's tab makes room for the Elite tab, or takes it back
	holder.Visible = on
	frame.Visible = on
	frame.ImageColor3 = HudConfig.Boss.EliteFrame
	-- The blade, its light and the stud: the elite's or the plain card's. The card's box follows its blade's foot.
	local shape = if on then E else T
	local box = shape.Housing
	local length = Vector2.new(box[3] - box[1], box[4] - box[2])
	for _, name in { "Housing", "HousingRim" } do
		LeadCard.Lay(card.Frame:FindFirstChild(name) :: ImageLabel, `CardTarget{if on then "Elite" else ""}{name}`, ORIGIN, length)
	end
	LeadCard.Relight(card.Health, if on then "CardLightHealthElite" else "CardLightHealth", shape.Health, shape.FillFrom)
	local stud = card.Gem.Parent :: Frame
	stud.Position = UDim2.fromOffset(shape.Stud.X, shape.Stud.Y)
	card.Frame.Size = UDim2.fromOffset(shape.Size.X, shape.Size.Y)
end

return TargetCard
