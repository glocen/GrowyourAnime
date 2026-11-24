--!strict
-- ModeScreen (client): the Play panel, in grey (the director, 2026-11-24: "i asked for the play button to open a panel
-- of gamemode"; Rules.Modes says which cards and what each press does; Config.Hud.Modes). A card a mode, side by side:
-- its name, what it is in one line, where this player stands in it, and its main press, the one lit thing on the card.
-- The Festival's card is the wider and holds a quiet second press to the Arc panel. A press that can't be pressed says
-- why in its own face. The cards rise in one after the other when the panel opens, and at once when it opens again
-- soon after. Mode art, a card's own light and the pad's focus row wait for the feel line's review.
--   ModeScreen.Open(cards, on)   builds it (on: Begin, Arc, Ring)
--   ModeScreen.Parts()           its pieces by name, for tests: `{Id}`, `{Id}Title`, `{Id}Line`, `{Id}Says`,
--                                `{Id}Press`, `{Id}Second`, and Body

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local HudConfig = require(Shared.Config.Hud)
local Modes = require(Shared.Rules.Modes)

local UI = script.Parent
local Theme = require(UI.Theme)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Panel = require(UI.Kit.Panel)
local Screen = require(UI.Kit.Screen)

local ModeScreen = {}
ModeScreen.Name = "Modes"

export type On = {
	Begin: (ground: string, difficulty: string) -> boolean, -- begins the run; true once it has (the panel has closed)
	Arc: () -> (), -- opens the Arc panel
	Ring: () -> boolean, -- points the way to the player's own Tower ring; false when there's none to point at
}

local LOOK = HudConfig.Modes
local TITLE = 24 -- a card's name, its line's height
local LINE = 36 -- what the mode is: two lines of Caption
local SAYS = 22 -- where the player stands
local SECOND = 0.38 -- the second press's share of a card's row

local parts: { [string]: Instance } = {}
local openedAt = -math.huge

local function label(card: Frame, name: string, words: string, y: number, tall: number, size: number, colour: Color3, font: Font, wrap: boolean): TextLabel
	local pad = Theme.Size.Pad
	local made = Text.new({
		Name = name,
		Size = size,
		Font = font,
		Colour = colour,
		Align = Enum.TextXAlignment.Left,
		Box = UDim2.new(1, -pad * 2, 0, tall),
		Position = UDim2.fromOffset(pad, y),
		Parent = card,
		Wrap = wrap,
		Truncate = not wrap,
	})
	made.Text = words
	made.ZIndex = 3
	return made
end

-- One card at `x`, `wide` by `tall`, in a holder that rises in.
local function build(body: Frame, card: Modes.Card, x: number, wide: number, tall: number, on: On): Frame
	local pad, gap, tap = Theme.Size.Pad, Theme.Size.Gap, Theme.Size.Tap
	local holder = Instance.new("Frame")
	holder.Name = card.Id
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(wide, tall)
	holder.Position = UDim2.fromOffset(x, 0)
	holder.Parent = body
	parts[card.Id] = holder
	local plate = Panel.new({ Name = "Plate", Size = UDim2.fromScale(1, 1), Parent = holder, Colour = Theme.Colour.PlateHigh, Edge = false })
	local y = pad + 4
	parts[`{card.Id}Title`] = label(plate, "Title", card.Title, y, TITLE, Theme.Text.Title, Theme.Colour.Text, Theme.Font.Strong, false)
	y += TITLE + 4
	parts[`{card.Id}Line`] = label(plate, "Line", card.Line, y, LINE, Theme.Text.Caption, Theme.Colour.TextDim, Theme.Font.Body, true)
	y += LINE + 6
	parts[`{card.Id}Says`] = label(plate, "Says", card.Says, y, SAYS, Theme.Text.Body, Theme.Colour.Text, Theme.Font.Strong, false)
	-- The presses along the card's foot: the main one, and the quiet second beside it where the card has one.
	local row = wide - pad * 2
	local second = if card.Second then math.floor(row * SECOND) else 0
	local main = row - second - (if card.Second then gap else 0)
	local at = tall - pad - tap
	local press = Button.new({
		Name = "Press",
		Text = card.Press,
		Size = UDim2.fromOffset(main, tap),
		Position = UDim2.fromOffset(pad, at),
		Parent = plate,
		Primary = true,
		OnPress = function(): boolean
			if card.Does == Modes.Begin and card.Ground and card.Difficulty then
				return on.Begin(card.Ground, card.Difficulty)
			elseif card.Does == Modes.Ring then
				return on.Ring()
			end
			return false
		end,
	})
	press.ZIndex = 4
	Button.Set(press, { Disabled = card.Off or false })
	press:SetAttribute("Does", card.Does)
	parts[`{card.Id}Press`] = press
	if card.Second then
		local other = Button.new({
			Name = "Second",
			Text = card.Second,
			Size = UDim2.fromOffset(second, tap),
			Position = UDim2.fromOffset(pad + main + gap, at),
			Parent = plate,
			Quiet = true,
			TextSize = Theme.Text.Caption,
			OnPress = function()
				on.Arc()
			end,
		})
		other.ZIndex = 4
		parts[`{card.Id}Second`] = other
	end
	return holder
end

function ModeScreen.Open(cards: { Modes.Card }, on: On)
	table.clear(parts)
	local pad = Theme.Size.Pad
	local across = 0
	local widths: { number } = {}
	for index, card in cards do
		widths[index] = if index == 1 then LOOK.Wide else LOOK.Narrow
		across += widths[index] + (if index > 1 then LOOK.Gap else 0)
	end
	local again = Screen.Current() == ModeScreen.Name
	local body = Screen.Open(ModeScreen.Name, "Play", Vector2.new(across + pad * 4, Screen.Head + LOOK.Tall + pad * 2))
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	parts.Body = body
	-- The body as the panel was fitted: a short phone's room is less than the cards' authored height (the Tower's card's
	-- way), and a narrow one's less than their width, each card then keeping its share.
	local panel = body.Parent :: Frame
	local wide = panel.Size.X.Offset - pad * 4
	local tall = math.min(LOOK.Tall, panel.Size.Y.Offset - Screen.Head - pad * 2)
	local share = math.min(1, wide / math.max(across, 1))
	local now = os.clock()
	local moves = not again and not GuiService.ReducedMotionEnabled and now - openedAt > LOOK.Again
	openedAt = now
	local x = 0
	for index, card in cards do
		local w = math.floor(widths[index] * share)
		local holder = build(body, card, x, w, tall, on)
		if moves then
			local rest = holder.Position
			holder.Position = rest + UDim2.fromOffset(0, LOOK.Rise)
			TweenService:Create(holder, TweenInfo.new(LOOK.Seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, (index - 1) * LOOK.Stagger), { Position = rest }):Play()
		end
		x += w + math.floor(LOOK.Gap * share)
	end
end

function ModeScreen.Parts(): { [string]: Instance }
	return parts
end

return ModeScreen
