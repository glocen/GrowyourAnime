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
--   TargetCard.Elite(card, on, share)     an elite's heavier frame, in grey (TR5's variant C; Config.Hud.Boss): a thicker
--                                         line round the blade, a crest notch on its top, the word Elite in the tab after
--                                         the level, in the card's ink (research's verdict, 2026-11-14, fix 3), and the
--                                         health thickened by a strip under the light at its share

local TextService = game:GetService("TextService")

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
local L = UIKit.LeadCard
local ORIGIN = -T.Offset -- where the shared images, placed in the lead's points, land in this card's
local TAB_TOP, TAB_FOOT, TAB_LEFT = L.Tab[1], L.Tab[2], L.Tab[4] -- the lead's points: its top, its foot, its top's left end
local TAB_MID = (TAB_TOP + L.Housing[2]) / 2 -- the middle of the tab's part above the blade
local NAME_X = 72 -- the name's left on the tab, in the lead's points: the arrow before it
local GAP = 5 -- between the name and the level
local TAB_AFTER = 10 -- the tab runs on past the level this far
local NAME_ROOM = 120 -- the longest name, authored pixels: past it, it's cut with "…"
local NAME_FONT = Enum.Font.BuilderSansBold -- Theme.Font.Strong, for measuring
local LEVEL_FONT = Enum.Font.BuilderSansMedium -- Theme.Font.Body

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
-- small phone). Nothing when unchanged.
function TargetCard.Name(card: Card, text: string, level: string)
	local holder = card.Frame:FindFirstChild("Elite")
	local word = if holder and (holder :: Frame).Visible then holder:FindFirstChild("Word") :: TextLabel? else nil
	local key = `{text}\0{level}\0{card.Name.TextSize}\0{word ~= nil}`
	if card.Frame:GetAttribute("Fitted") == key then
		return
	end
	card.Frame:SetAttribute("Fitted", key)
	card.Name.Text = text
	card.Level.Text = level
	local wide = math.min(TextService:GetTextSize(text, card.Name.TextSize, NAME_FONT, Vector2.new(1000, 100)).X, NAME_ROOM)
	local after = TextService:GetTextSize(level, card.Level.TextSize, LEVEL_FONT, Vector2.new(1000, 100)).X
	card.Level.Position = UDim2.fromOffset(NAME_X + wide + GAP + T.Offset.X, card.Level.Position.Y.Offset)
	local reach = NAME_X + wide + GAP + after + TAB_AFTER - TAB_LEFT -- the tab's top edge's width, in the lead's points
	if word then -- an elite's word after the level
		local wordWide = TextService:GetTextSize(word.Text, word.TextSize, NAME_FONT, Vector2.new(1000, 100)).X + 2
		word.Size = UDim2.fromOffset(wordWide, word.Size.Y.Offset)
		word.Position = UDim2.fromOffset(NAME_X + wide + GAP + after + GAP + T.Offset.X, word.Position.Y.Offset)
		reach += GAP + wordWide
	end
	local run = (TAB_FOOT - TAB_TOP) * L.Slant
	local size = Vector2.new(reach + run, TAB_FOOT - TAB_TOP)
	for _, name in { "Tab", "TabRim" } do
		LeadCard.Lay(card.Frame:FindFirstChild(name) :: ImageLabel, `Card{name}`, ORIGIN, size)
	end
end

-- C's grey block over the card: built the first time it's asked for, then shown or hidden.
local function eliteFrame(card: Card): Frame
	local found = card.Frame:FindFirstChild("Elite")
	if found and found:IsA("Frame") then
		return found
	end
	local look = HudConfig.Boss.Frame
	local grey = HudConfig.Boss.Grey
	local left, top, right, foot = T.Housing[1], T.Housing[2], T.Housing[3], T.Housing[4] + look.Under
	local holder = Instance.new("Frame")
	holder.Name = "Elite"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 7
	holder.Visible = false
	holder.Parent = card.Frame
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.BackgroundTransparency = 1
	line.Position = UDim2.fromOffset(left - 2, top - 2)
	line.Size = UDim2.fromOffset(right - left + 4, foot - top + 4)
	line.ZIndex = 7
	line.Parent = holder
	local stroke = Instance.new("UIStroke")
	stroke.Color = grey
	stroke.Thickness = look.Stroke
	stroke.Parent = line
	local notch = Instance.new("Frame")
	notch.Name = "Notch"
	notch.BackgroundColor3 = grey
	notch.BorderSizePixel = 0
	notch.AnchorPoint = Vector2.new(0.5, 0.5)
	notch.Position = UDim2.fromOffset((left + right) / 2, top - 2)
	notch.Size = UDim2.fromOffset(look.Notch, look.Notch)
	notch.Rotation = 45
	notch.ZIndex = 8
	notch.Parent = holder
	local word = Text.new({ -- in the tab after the level, laid by TargetCard.Name
		Name = "Word",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Box = UDim2.fromOffset(40, TAB_FOOT - TAB_TOP - 2.4),
		Position = UDim2.fromOffset(0, TAB_TOP + T.Offset.Y),
		Parent = holder,
	})
	word.Text = "Elite"
	word.ZIndex = 8
	local h = T.Health
	local under = Instance.new("Frame")
	under.Name = "Under"
	under.BackgroundColor3 = Theme.Colour.Channel
	under.BorderSizePixel = 0
	under.Position = UDim2.fromOffset(h[1], h[2] + h[4])
	under.Size = UDim2.fromOffset(h[3] - h[1], look.Under)
	under.ZIndex = 7
	under.Parent = holder
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = HudConfig.Boss.EliteHealth
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.ZIndex = 7
	fill.Parent = under
	return holder
end

function TargetCard.Elite(card: Card, on: boolean, share: number)
	local holder = eliteFrame(card)
	if holder.Visible ~= on then
		holder.Visible = on
		card.Frame:SetAttribute("Fitted", nil) -- the tab fits the word, or lets it go
	end
	local fill = (holder:FindFirstChild("Under") :: Frame):FindFirstChild("Fill") :: Frame
	fill.Size = UDim2.fromScale(math.clamp(if share == share then share else 0, 0, 1), 1)
end

return TargetCard
