--!strict
-- Plate (client): the plate after the reveal (AR12, "The reveal's card, its images"; research's verdict on the reveal's
-- card in Eclipse). It hangs under the ceremony's name, from its rule, over the held frame left undimmed, so the name is
-- said once, on the ceremony, and the plate says what was won: what the break gave, the rarity's pip with its rarity,
-- type and class, then the outcome's mark with its words, each line one colour, mark and words together. "Tap to
-- continue" joins once the card has stood Config.Reveal.CardHold. Laid once, in the stage's points, its numbers
-- Config.Reveal.Plate's; the stage keeps it at its size where it shrinks to fit a small phone (stage.Hold).
--   local plate = Plate.new(stage, { Def = "rook", Rarity = "Common", Outcome = "New", Lead = false, Credits = 0 })
--   Plate.Continue(plate)    "Continue" shows
--   Plate.Number(plate, 1284) a new Voidkin's number once the server holds it: "A new Voidkin · No. 1,284"

local TextService = game:GetService("TextService")

local Shared = game:GetService("ReplicatedStorage").Shared
local RevealConfig = require(Shared.Config.Reveal)
local UIKit = require(Shared.Config.UIKit)
local Voidkin = require(Shared.Definitions.Voidkin)
local Exist = require(Shared.Rules.Exist)
local Theme = require(script.Parent.Parent.Theme)
local Read = require(script.Parent.Parent.Read)
local Panel = require(script.Parent.Parent.Kit.Panel)
local Skin = require(script.Parent.Parent.Kit.Skin)

export type Answer = { Def: string, Rarity: string, Outcome: string, Lead: boolean, Credits: number } -- Rarity: the ceremony's
type Stage = { Stage: Frame, Under: Vector2, Hold: (scale: UIScale) -> () }

local Plate = {}

local PALETTE = "Eclipse"
local Z = 20 -- over every layer of the stage (UI/Reveal's Z)
local MEASURE = Enum.Font.BuilderSansMedium -- Theme.Font.Body's face, for a width measured at once

-- How wide `text` draws at `size` in the plate's face, in points: synchronous, so the plate comes on its frame.
local function wide(text: string, size: number): number
	local ok, got = pcall(function(): Vector2
		return TextService:GetTextSize(text, size, MEASURE, Vector2.new(100000, 1000))
	end)
	return if ok then got.X else #text * size * 0.55
end

local function label(name: string, parent: Instance, size: number, colour: Color3, x: number, middle: number, width: number): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.FontFace = Theme.Font.Body
	text.TextSize = size
	text.TextColor3 = colour
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Position = UDim2.fromOffset(x, middle - (size + 6) / 2)
	text.Size = UDim2.fromOffset(width, size + 6)
	text.ZIndex = 2
	text.Parent = parent
	return text
end

-- What a break's outcome says: the first line, the outcome's mark, its words, and their colour.
local function said(answer: Answer): (string, string, string, Color3)
	local plate = RevealConfig.Plate
	if answer.Outcome == "Copy" then
		return "A copy", "Star", "One more toward its next star", plate.Star
	elseif answer.Outcome == "Sold" then
		return "Already at its last star", "CoinMint", `Sold for {Read.Number(answer.Credits)} Credits`, UIKit.Systems.Credits.Colour
	elseif answer.Lead then
		return "A new Voidkin", "ShardSilver", "Your lead fights beside you", plate.Kept
	end
	return "A new Voidkin", "ShardSilver", "In your collection", plate.Kept
end

function Plate.new(stage: Stage, answer: Answer): Frame
	local c = RevealConfig.Plate
	local p = UIKit.Palettes[PALETTE]
	local row = Voidkin.ById[answer.Def]
	local rarity = answer.Rarity
	local word = c.Words[rarity] or c.Words.Common
	local kind, mark, words, colour = said(answer)
	local runs = if row then { rarity, row.Type, row.Class } else { rarity }
	local plain = table.concat(runs, " · ")
	local tap = "Continue"

	local width = math.max(
		c.Size.X,
		math.ceil(c.Rarity.From + wide(plain, c.Rarity.Size) + c.Inset),
		math.ceil(c.Outcome.From + wide(words, c.Outcome.Size) + c.Inset)
	)
	local tapWide = wide(tap, c.Tap.Size)
	local inline = (width - c.Inset - tapWide) - (c.Outcome.From + wide(words, c.Outcome.Size)) >= c.Tap.Room

	local plate = Panel.new({ Name = "Card", Palette = PALETTE, Transparency = 1 - p.Alpha, Size = UDim2.fromOffset(width, c.Size.Y) })
	plate.Position = UDim2.fromOffset(stage.Under.X, stage.Under.Y + c.Gap)
	plate.ZIndex = Z
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	stage.Hold(scale)

	label("Kind", plate, c.Kind.Size, p.Soft, c.Inset, c.Kind.Middle, width - 2 * c.Inset).Text = kind

	local pip = c.Rarity.Pip
	Skin.Icon(plate, "RarityPip", c.Rarity.PipAt, c.Rarity.Middle, pip, word, 2).Name = "Pip"
	local facet = Skin.Icon(plate, "RarityPipFacet", c.Rarity.PipAt, c.Rarity.Middle, pip, nil, 3)
	facet.Name = "PipFacet"
	facet.ImageTransparency = 1 - c.Rarity.Facet
	local line = label("Rarity", plate, c.Rarity.Size, p.Soft, c.Rarity.From, c.Rarity.Middle, width - c.Rarity.From - c.Inset)
	local parts = { `<font color="#{word:ToHex()}">{runs[1]}</font>` }
	for i = 2, #runs do
		table.insert(parts, `<font color="#{p.Faint:ToHex()}"> · </font>{runs[i]}`)
	end
	line.RichText = true
	line.Text = table.concat(parts)

	Skin.Icon(plate, mark, c.Outcome.MarkAt, c.Outcome.Middle, c.Outcome.Mark, nil, 2).Name = "Mark"
	label("Outcome", plate, c.Outcome.Size, colour, c.Outcome.From, c.Outcome.Middle, width - c.Outcome.From - c.Inset).Text = words

	local skip = if inline
		then label("Skip", plate, c.Tap.Size, p.Soft, width - c.Inset - tapWide - 2, c.Outcome.Middle, tapWide + 2)
		else label("Skip", plate, c.Tap.Size, p.Soft, 0, c.Size.Y + c.Tap.Under + (c.Tap.Size + 6) / 2, width)
	skip.TextXAlignment = if inline then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center
	skip.Text = tap
	skip.Visible = false

	plate.Parent = stage.Stage
	return plate
end

-- A new Voidkin's number on its first line, once the server holds it (docs/design.md, "How many exist": "On the reveal
-- of a new Voidkin, its number once the server holds it"). A copy's or a sale's plate keeps its line.
function Plate.Number(plate: Frame, no: number)
	local kind = plate:FindFirstChild("Kind")
	if kind and kind:IsA("TextLabel") and kind.Text == "A new Voidkin" then
		kind.Text = `A new Voidkin · {Exist.Words(no)}`
	end
end

-- "Continue" shows: the card has stood long enough for a tap to close it.
function Plate.Continue(plate: Frame)
	local skip = plate:FindFirstChild("Skip")
	if skip and skip:IsA("TextLabel") then
		skip.Visible = true
	end
end

return Plate
