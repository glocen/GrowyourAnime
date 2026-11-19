--!strict
-- The Items page (client; TR28): AR18's A, "the ledger" (the director's pick, about 20:52, 2026-11-16; TR28, "The rebuild
-- in A"; docs/ui.md, the bag), in the Overview's colours, so a switch of tabs never changes one (TR24, the director's
-- run, fix 4): the screen's backing, the Overview's stage, its slots' graphite cells, its panel for the card. Right of
-- the rail:
--   the strip over the grid: the bag's five kinds, All first and holding everything (the director, by 21:32), scrolling
--     with the chosen one kept in view, and at its end the sort (the salvage's control, in Chests);
--   the grid, five across or more, cells of about 64, each A's cell on AR6's assembly (build/handoff/UI/gear/
--     gear_icons.json): its well, its rarity's tint, light and rim (Legendary's a gilt frame), its design's picture, a
--     weapon's class mark, its rarity's bar along its foot; an up arrow when wearing it would raise the shown Voidkin's
--     Combat Power, a tick when it's worn, another class's weapon drained. Chests stand after the items, each its
--     picture (AR21) and count in a plain cell, the shards after them. The count stands under the grid, outside its
--     scroll;
--   the doll at the room's left, as A's sheet has it (the director, 2026-11-16), a hairline between it and the grid:
--     the Voidkin between its two columns of slots, the six armor pieces on the left,
--     the cloak and the jewellery on the right, its name and level over it, its Combat Power and its two hands at its
--     feet. All fourteen slots always show, each a touch, an empty one its piece's mark (AR22); the one the chosen
--     item would go in wears an ivory ring;
--   a chosen item's card slides in at the room's right edge, the doll's width, in 0.16 s, so Equip stands under the right
--     thumb and the doll stays in view: its design's picture and
--     name, its rarity and kind, Combat Power's change, what it replaces, each Basic and Battle Attribute's change, and
--     Equip, or Take off when it's worn. Another class's weapon lists its lines, says whose it is, and Equip is off. A
--     chest's card holds its odds, and Open and Open all (in steps of 50).
-- Every number comes from Rules.Bag, so what a cell says is what the logic cases check; every change is asked of the
-- server through Act, and the screen is rebuilt from the server's copy. A tap on a cell changes the card and the rings in
-- place, never the grid.
--   Bag.Build(context) -> the rename's save, from the name line over the figure
--   Bag.Reset()        a fresh open: All, by rarity, nothing chosen
--   Bag.State()        for tests: the kind, the sort, the chosen thing
--   Bag.Choose(id)     for tests: a cell's tap

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Gear = require(Shared.Definitions.Gear)
local Shards = require(Shared.Definitions.Shards)
local ChestRows = require(Shared.Definitions.Chests)
local Voidkin = require(Shared.Definitions.Voidkin)
local Rules = require(Shared.Rules.Bag)
local Chests = require(Shared.Rules.Chests)
local Sheet = require(Shared.Rules.Sheet)
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local Skin = require(UI.Kit.Skin)
local ShardTag = require(UI.ShardTag)
local Seam = require(script.Parent.Seam)

local Bag = {}

type Box = { X: number, Y: number, Wide: number, Tall: number }

export type Context = {
	Body: Frame,
	Behind: Frame, -- under the figure's stage, cleared with the body: the room's panel
	Room: Vector2,
	Left: number, -- where the page starts, authored, right of the rail
	View: Profile.View,
	Owned: Profile.OwnedVoidkin,
	Act: (name: string, args: any) -> { [string]: any },
	Taps: { [Instance]: () -> () },
	Rebuild: () -> (),
	-- The figure's stage in `box`, dressed for the shown Voidkin; its name's line over it (the rename's save, when
	-- renaming); its Combat Power at its feet, `wide` across.
	Stage: (box: Box) -> (),
	Name: (over: Frame, wide: number) -> (() -> boolean)?,
	Power: (parent: Frame, wide: number) -> (),
}

local C = HudConfig.Bag
-- The seam's palette, the Overview's too (TR28, UI.VoidkinScreen.Seam): its words, its edges, its wells, its room and
-- card; a rarity keeps its own colours (Config.Hud.Bag).
local SEAM = HudConfig.Seam
local P = {
	Text = Seam.Colour.Text,
	Soft = Seam.Colour.TextDim,
	Faint = Seam.Colour.Disabled,
	Line = Seam.Colour.Line, -- a hairline, a well's rim, a chip's edge
	Ink = Seam.Ink, -- a word on a plate of light
	Backing = Seam.Room, -- what a veil fades into: the room's panel at its top
	Cell = Seam.Well, -- every cell's and slot's well, a rarity's and a Legendary's too
	Field = Seam.Card, -- the card, a step up from the room
	Edge = Seam.Colour.Line,
	Seat = Seam.Colour.Channel, -- under a corner's mark, and the card's Combat Power
	Up = UIKit.Good,
	Down = UIKit.Bad,
	Rarity = C.Rarity,
	Rim = C.Rim,
}
local GROUP_KIND = { "Gear", "Gear", "Jewelry" } -- each slot group's kind on the strip
local TIER_WORD = { "Shade", "Elite", "Keeper's", "Tower" } -- a chest's kind on its cell, never a rarity's word
local NUMBER_ROW = 22 -- the card's Combat Power line
-- The full bag's way out (the follow-up's item 6): what frees a slot, said wherever a full bag stops an open.
local FREE_A_SLOT = "salvage an item from its card to free a slot"
local CHEST_SAID: { [string]: string } = { NotEnough = "Not that many held", BagFull = `The bag is full: {FREE_A_SLOT}`, Unknown = "Not now" }
local SALVAGE_SAID: { [string]: string } = {
	NotOwned = "It isn't in the bag",
	Worn = "Take it off first",
	Unknown = "Not now",
}
local ARMED = 3 -- s the salvage's second tap is waited for
local EQUIP_SAID: { [string]: string } = {
	NotOwned = "It isn't in the bag",
	WrongSlot = "It doesn't go there",
	WrongClass = "Another class's weapon",
	Unknown = "Not now",
	InCombat = "Not during a fight",
}

local kind = "All"
local sort = "Rarity"
local chosen: string? = nil -- the item or chest whose card shows
local carded: string? = nil -- the card drawn last, so only a new one slides in
local last: Context? = nil
local cells: { [string]: GuiObject } = {}
local slots: Frame? = nil -- the doll's fourteen slots, drawn again on each choice
local room: Frame? = nil -- the card's room, over the doll, clipping its slide
local card: Frame? = nil

local function said(map: { [string]: string }, what: string, answer: { [string]: any }): boolean
	if answer.Ok == true then
		return true
	end
	local word = map[tostring(answer.Error)]
	if word == nil then
		warn(`[VoidkinScreen.Bag] {what}: an unnamed refusal, {tostring(answer.Error)}`)
	end
	Toast.Show(`{what}: {word or "Not now"}`, Theme.Colour.TextDim)
	return false
end

local function label(props: Text.Props, words: string): TextLabel
	props.Colour = props.Colour or P.Text
	local made = Text.new(props)
	made.Text = words
	return made
end

local function plain(name: string, parent: Instance, x: number, y: number, wide: number, tall: number): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.Position = UDim2.fromOffset(x, y)
	made.Size = UDim2.fromOffset(wide, tall)
	made.Parent = parent
	return made
end

local function round(on: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = on
end

local function ramp(on: Instance, colours: { Color3 }, rotation: number?)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colours[1], colours[2])
	gradient.Rotation = rotation or 90
	gradient.Parent = on
end

local function press(name: string, parent: Instance, x: number, y: number, wide: number, tall: number, onTap: () -> (), taps: { [Instance]: () -> () }): TextButton
	local made = Instance.new("TextButton")
	made.Name = name
	made.Text = ""
	made.AutoButtonColor = false
	made.BorderSizePixel = 0
	made.BackgroundTransparency = 1
	made.Position = UDim2.fromOffset(x, y)
	made.Size = UDim2.fromOffset(wide, tall)
	made.Parent = parent
	made.Activated:Connect(function()
		onTap()
	end)
	taps[made] = onTap
	return made
end

-- A touch target's least side at the scale drawn now, authored: 44 rendered, never more than a tap.
local function touch(): number
	return math.min(math.ceil(Theme.Size.Touch / Layers.Scale()), Theme.Size.Tap)
end

-- An up arrow in `colour`, `side` across, centred in `parent`: a stem and two arms.
local function arrow(parent: Instance, colour: Color3, side: number)
	local thick = math.max(2, math.floor(side / 7))
	local function bar(name: string, wide: number, tall: number, x: number, y: number, rotation: number)
		local made = Instance.new("Frame")
		made.Name = name
		made.BorderSizePixel = 0
		made.BackgroundColor3 = colour
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Size = UDim2.fromOffset(wide, tall)
		made.Position = UDim2.fromScale(x, y)
		made.Rotation = rotation
		made.Parent = parent
	end
	bar("Stem", thick, side * 0.6, 0.5, 0.6, 0)
	bar("ArmLeft", side * 0.48, thick, 0.36, 0.42, -45)
	bar("ArmRight", side * 0.48, thick, 0.64, 0.42, 45)
end

-- A cross in `colour`, `side` across, centred in `parent`: the card's close.
local function cross(parent: Instance, colour: Color3, side: number)
	for _, turn in { 45, -45 } do
		local made = Instance.new("Frame")
		made.Name = "Bar"
		made.BorderSizePixel = 0
		made.BackgroundColor3 = colour
		made.AnchorPoint = Vector2.new(0.5, 0.5)
		made.Size = UDim2.fromOffset(side * 1.3, 2)
		made.Position = UDim2.fromScale(0.5, 0.5)
		made.Rotation = turn
		made.Parent = parent
	end
end

-- Where each piece stands, authored, in the room right of the rail: the doll at the left, as A's sheet has it (the
-- director, 2026-11-16), its slots a touch each and taking the room's height (C.Doll), then a hairline, the grid
-- in what's left, five across or more. The card opens at the room's right edge, the doll's width, over the grid's end:
-- Equip under the right thumb (docs/ui.md), and the doll in view beside it.
type Layout = {
	Case: Box,
	Strip: Box,
	Grid: Box,
	Count: Box,
	Doll: Box, -- the two columns of slots and the figure between them
	Half: Box, -- the card's room: the doll's width at the room's right edge, the room's height
	Hit: number, -- a slot's tap
	Pitch: number, -- from one slot to the next down its column
	Well: number, -- a slot's drawn well, inside its tap
	Figure: number, -- the figure's room between the columns
	Cell: number,
	Columns: number,
}

local function layout(size: Vector2, left: number): Layout
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local d = C.Doll
	local tall = math.max(size.Y, 1)
	local case = { X = left, Y = 0, Wide = math.max(size.X - pad - left, 1), Tall = tall }
	local hit = math.clamp((tall - 5 * d.Gap) / 6, math.max(touch(), d.Slot), d.Most)
	local pitch = hit + d.Gap
	if 5 * pitch + hit > tall then
		-- Six a touch tall don't stand (the smallest phone: 262 rendered px for 264): each slot keeps its whole touch and
		-- the six are pitched to the room, a tap's edge over its neighbour's by under a rendered pixel, the wells apart.
		pitch = (tall - hit) / 5
	end
	local figure = math.max(d.Figure, math.floor(hit * d.Grow))
	local dollWide = hit * 2 + figure
	local column = 5 * pitch + hit
	local doll = { X = case.X + C.Inset, Y = math.floor((tall - column) / 2), Wide = dollWide, Tall = column }
	local x0, y0 = doll.X + dollWide + gap * 2, C.Inset
	local gridWide = math.max(case.X + case.Wide - C.Inset - x0, 1)
	local inner = gridWide - C.Ring -- the cells' holder: room for a chosen cell's ring at the grid's edges
	local columns = math.max(C.Columns, math.floor((inner + C.CellGap) / (C.Cell + C.CellGap)))
	local cell = math.max(math.floor(math.min(C.Cell, (inner - (columns - 1) * C.CellGap) / columns)), touch())
	local gridY = y0 + Theme.Size.Tap + C.Under
	local countY = tall - C.Inset - C.Row -- the count pinned under the grid, never in its scroll (research, TR28's call 3)
	return {
		Case = case,
		Strip = { X = x0, Y = y0, Wide = gridWide, Tall = Theme.Size.Tap },
		Grid = { X = x0, Y = gridY, Wide = gridWide, Tall = math.max(countY - C.Under - gridY, 1) },
		Count = { X = x0, Y = countY, Wide = gridWide, Tall = C.Row },
		Doll = doll,
		Half = { X = case.X + case.Wide - dollWide - C.Ring / 2, Y = 0, Wide = dollWide + C.Ring / 2, Tall = tall }, -- C.Ring / 2 more: a cell's ring stays under it
		Hit = hit,
		Pitch = pitch,
		Well = math.min(hit, pitch - d.Seam),
		Figure = figure,
		Cell = cell,
		Columns = columns,
	}
end

-- A's cell on AR6's assembly (gear_icons.json's layers, its sizes for a slot of C.Gear), `side` across in `holder`: the
-- well (a Legendary's umber); the rarity's tint and light; its rim (a Legendary's gilt frame); its rarity's bar along its
-- foot; its picture, 0.94 of it; a weapon's class mark at its foot's right. `drained`: another class's weapon, its light,
-- rim and picture dimmed. `rarity` "" (a chest) takes the plain edge, and `words` stand for a missing picture.
local function art(holder: GuiObject, side: number, rarity: string, image: string?, words: string, class: string?, drained: boolean)
	local s = side / C.Gear
	local skin = Skin.Of(holder)
	local legendary = rarity == "Legendary"
	local rim = P.Rim[rarity]
	Skin.Lay(skin, "ButtonFill", { Name = "Well", Tint = P.Cell, Z = 1 })
	if rim then
		if not legendary then
			Skin.Lay(skin, "ButtonFill", { Name = "Tint", Tint = rim, Alpha = if rarity == "Common" then 0.112 else 0.14, Z = 2 })
		end
		local light = rim:Lerp(Color3.new(1, 1, 1), 0.2)
		local strength = (if rarity == "Common" then 0.8 else 1) * (if drained then 0.35 else 1)
		if legendary then
			Skin.Lay(skin, "GearLight", { Name = "Light", X = side * 0.14, Y = side * 0.129, Scale = s * 0.72, Tint = light, Alpha = strength, Z = 3 })
			Skin.Lay(skin, "GearFrameLegendary", { Name = "Rim", Scale = s, Alpha = if drained then 0.5 else 1, Z = 5 })
		else
			Skin.Lay(skin, "GearLight", { Name = "Light", Scale = s, Tint = light, Alpha = strength, Z = 3 })
			Skin.Lay(skin, "ButtonEdgeBold", { Name = "Rim", Tint = rim, Alpha = if drained then 0.35 else 1, Z = 5 })
		end
		local band = Instance.new("Frame")
		band.Name = "Band"
		band.BorderSizePixel = 0
		band.BackgroundColor3 = rim
		band.BackgroundTransparency = if drained then 0.65 else 0.05
		band.Position = UDim2.fromOffset(4, side - C.Bar - 2)
		band.Size = UDim2.fromOffset(side - 8, C.Bar)
		band.ZIndex = 4
		round(band, 1)
		band.Parent = skin
	else
		Skin.Lay(skin, "ButtonEdge", { Name = "Rim", Tint = P.Line, Z = 5 })
	end
	if image then
		local picture = Skin.Icon(holder, image, side / 2, side / 2, side * 0.94, nil, 2)
		picture.Name = "Picture"
		if drained then
			picture.ImageColor3 = Color3.fromRGB(122, 118, 140) -- dimmed toward the seam's Soft
			picture.ImageTransparency = 0.35
		end
	elseif words ~= "" then
		local word = label({
			Name = "Art",
			Size = Theme.Text.Caption,
			Font = Theme.Font.Strong,
			Colour = P.Soft,
			Align = Enum.TextXAlignment.Center,
			Box = UDim2.fromOffset(side - 6, side - 14),
			Position = UDim2.fromOffset(3, 6),
			Parent = holder,
			Wrap = true,
			Truncate = true,
		}, words)
		word.TextTransparency = if drained then 0.55 else 0
		word.ZIndex = 2
	end
	if class then
		local mark = Skin.Icon(holder, `Class{class}`, side - 4.6 * s, side - 4.6 * s, 10.8 * s, nil, 4)
		mark.Name = "Class"
	end
end

-- A dark seat in a cell's top corner, `left` or right, holding `fill`'s mark.
local function corner(holder: GuiObject, name: string, left: boolean, side: number, fill: (Frame) -> ())
	local chip = Instance.new("Frame")
	chip.Name = name
	chip.BorderSizePixel = 0
	chip.BackgroundColor3 = P.Seat
	chip.BackgroundTransparency = 0.15
	chip.Size = UDim2.fromOffset(C.Mark, C.Mark)
	chip.Position = UDim2.fromOffset(if left then 3 else side - C.Mark - 3, 3)
	chip.ZIndex = 5
	round(chip, 3)
	chip.Parent = holder
	fill(chip)
end

-- The kit's name of an empty slot's mark (AR22; build/handoff/UI/slots/slot_marks.json): SlotEmpty<Kind>, either ring
-- Ring and either earring Earring; a hand's SlotEmpty<Hand><Class>.
local function emptyMark(slot: string, class: string): string
	local kind = string.gsub(Gear.Family(slot), " ", "")
	return if Gear.IsHand(slot) then `SlotEmpty{kind}{class}` else `SlotEmpty{kind}`
end

local function slotWord(entry: Rules.Entry): string
	if entry.Kind == "Chest" then
		local row = ChestRows.ById[entry.Def]
		return `{TIER_WORD[if row then row.Tier else 1] or ""} Chest`
	end
	local row = Items.ById[entry.Def]
	return if row then row.Kind else entry.Def
end

local refresh: () -> ()

-- A cell's tap: its card, or for a shard its name.
local function choose(id: string?)
	chosen = id
	refresh()
end

local function cellFor(entry: Rules.Entry, side: number, order: number, parent: Instance, taps: { [Instance]: () -> () }): GuiObject
	local made = Instance.new("TextButton")
	made.Name = entry.Id
	made.Text = ""
	made.AutoButtonColor = false
	made.BorderSizePixel = 0
	made.BackgroundTransparency = 1
	made.LayoutOrder = order
	made:SetAttribute("Kind", entry.Kind)
	made:SetAttribute("Rarity", entry.Rarity)
	made:SetAttribute("Up", entry.Up)
	made:SetAttribute("Worn", entry.Worn or "")
	made:SetAttribute("Fits", entry.Fits)
	made:SetAttribute("Count", entry.Count)
	made:SetAttribute("Image", entry.Image or "")
	if entry.Kind == "Shard" then
		local row = Shards.ById[entry.Def]
		art(made, side, entry.Rarity, nil, "", nil, false)
		local shardArt = HudConfig.ShardArt
		local picture = Skin.Icon(made, Hud.ShardPicture(if row then row.Grade else "Standard", side * shardArt.Cell, shardArt.Large), side / 2, side / 2 + 2, side * shardArt.Cell, nil, 2)
		picture.Name = "Picture"
		ShardTag.Lay(picture, entry.Def, side * shardArt.Cell, true) -- where it came from, left of the count (TR41 (d))
	elseif entry.Kind == "Chest" then
		art(made, side, "", entry.Image, slotWord(entry), nil, false) -- AR21's picture in the plain cell
	else
		art(made, side, entry.Rarity, entry.Image, slotWord(entry), entry.Class, not entry.Fits)
	end
	if entry.Count > 1 or entry.Kind ~= "Item" then
		local count = label({ Name = "Count", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Text, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(side - 7, 16), Position = UDim2.fromOffset(0, side - 19), Parent = made }, `×{Hud.Digits(entry.Count)}`)
		count.ZIndex = 5
	end
	if entry.Up then
		corner(made, "Up", false, side, function(chip: Frame)
			arrow(chip, P.Up, C.Mark - 4)
		end)
	end
	if entry.Worn then
		corner(made, "WornMark", true, side, function(chip: Frame)
			Skin.Icon(chip, "Tick", C.Mark / 2, C.Mark / 2, C.Mark - 4, P.Text)
		end)
	end
	Seam.Ring(made, "Chosen", side, entry.Id == chosen)
	Seam.Raise(made, entry.Id == chosen)
	local function onTap()
		if entry.Kind == "Shard" then
			Toast.Show(`{Read.ShardName(entry.Id)} ×{Hud.Digits(entry.Count)}`, Theme.Colour.Text)
			return
		end
		choose(if chosen == entry.Id then nil else entry.Id)
	end
	made.Activated:Connect(onTap)
	taps[made] = onTap
	made.Parent = parent
	return made
end

-- The doll's fourteen slots, each a touch: the six armor pieces down the left, the cloak and the jewellery down the
-- right, the two hands at the figure's feet. Each holds what the shown Voidkin wears there, or its empty mark (AR22);
-- the slot the chosen item would go in is ringed in ivory.
local function drawSlots(context: Context, at: Layout, target: string?)
	local holder = slots
	if holder == nil then
		return
	end
	holder:ClearAllChildren()
	local data = context.View :: any
	local worn = Rules.Worn(data, context.Owned)
	local hit, well = at.Hit, at.Well
	local own = Voidkin.ById[context.Owned.Def]
	local class = if own then own.Class else "Warrior"
	local function place(name: string, group: number, x: number, y: number)
		local id = worn[name]
		local item = if id then context.View.Items[id] else nil
		local row = if item then Items.ById[item.Def] else nil
		local function onTap()
			if id then
				choose(if chosen == id then nil else id)
			else
				Toast.Show(`{name}: empty`, Theme.Colour.TextDim)
				kind = GROUP_KIND[group]
				chosen = nil
				context.Rebuild()
			end
		end
		local made = press(name, holder, x, y, hit, hit, onTap, context.Taps)
		made:SetAttribute("Slot", name)
		made:SetAttribute("Item", id or "")
		local inside = plain("Well", made, (hit - well) / 2, (hit - well) / 2, well, well)
		if item and row then
			local design = Items.Design(item)
			art(inside, well, item.Rarity, if design then design.Image else nil, row.Kind, row.Class, false)
		else
			local skin = Skin.Of(inside)
			Skin.Lay(skin, "ButtonFill", { Name = "Well", Tint = P.Cell, Z = 1 })
			Skin.Lay(skin, "ButtonEdge", { Name = "Rim", Tint = P.Line, Z = 2 })
			-- AR22's mark for what goes there, from the slot's Epic piece; a hand's by the shown Voidkin's class.
			local mark = Skin.Icon(inside, emptyMark(name, class), well / 2, well / 2, well * C.Empty.Share, C.Empty.Tint, 3)
			mark.Name = "Empty"
			mark.ImageTransparency = C.Empty.Alpha
		end
		Seam.Ring(inside, "Target", well, name == target)
		Seam.Raise(made, name == target)
	end
	local pitch, gap = at.Pitch, C.Doll.Gap
	for index, name in Rules.Groups[2] do
		place(name, 2, 0, (index - 1) * pitch)
	end
	for index, name in Rules.Groups[3] do
		place(name, 3, hit + at.Figure, (index - 1) * pitch)
	end
	local pair = hit * 2 + gap
	for index, name in Rules.Groups[1] do
		place(name, 1, hit + (at.Figure - pair) / 2 + (index - 1) * (hit + gap), at.Doll.Tall - hit)
	end
end

-- The card's places in its room: open, its shadow in the room's left lip over the grid; shut, wholly off its right.
local OPEN, SHUT = UDim2.fromOffset(SEAM.Shade.Wide, 0), UDim2.new(1, SEAM.Shade.Wide, 0, 0)

local function slide(frame: Frame, open: boolean, done: (() -> ())?)
	local tween = TweenService:Create(frame, TweenInfo.new(C.Slide, if open then Enum.EasingStyle.Quart else Enum.EasingStyle.Quad, if open then Enum.EasingDirection.Out else Enum.EasingDirection.In), { Position = if open then OPEN else SHUT })
	if done then
		tween.Completed:Connect(function()
			done()
		end)
	end
	tween:Play()
end

-- Closes the card: it slides back off the doll.
local function close()
	local was = card
	chosen, carded, card = nil, nil, nil
	if was then
		slide(was, false, function()
			was:Destroy()
		end)
	end
	refresh()
end

-- One line of the card's comparison: the stat's name, its total, its change in the kit's green or red.
local function compared(parent: Instance, order: number, wide: number, stat: string, name: string, value: string, change: number)
	local line = Instance.new("Frame")
	line.Name = stat
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, 0, 0, C.Row) -- the list's canvas: inside the scrollbar once the lines scroll
	line.LayoutOrder = order
	line.Parent = parent
	local changeWide = 44
	label({ Name = "Name", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(math.max(wide - changeWide - 56, 10), C.Row), Parent = line, Truncate = true }, name)
	label({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Text, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -changeWide - 4, 0, C.Row), Parent = line }, value)
	local delta = label({ Name = "Change", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = if change > 0 then P.Up elseif change < 0 then P.Down else P.Faint, Align = Enum.TextXAlignment.Right, Parent = line }, Sheet.Change(stat, change))
	delta:SetAttribute("Change", change)
end

local function caption(parent: Instance, order: number, wide: number, words: string)
	local made = label({ Name = words, Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = Seam.Glint, Box = UDim2.fromOffset(wide, C.Row + 4), Parent = parent }, words)
	made.TextYAlignment = Enum.TextYAlignment.Bottom
	made.LayoutOrder = order
end

local function rule(parent: Instance, x: number, y: number, wide: number)
	local made = Instance.new("Frame")
	made.Name = "Divider"
	made.BorderSizePixel = 0
	made.BackgroundColor3 = P.Line
	made.Position = UDim2.fromOffset(x, y)
	made.Size = UDim2.fromOffset(wide, 1)
	made.Parent = parent
end

-- The card's scrolling lines between `top` and `bottom`, listed down one column.
local function lines(made: Frame, id: string, x: number, top: number, wide: number, bottom: number): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.Name = "Lines"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(x, top)
	list.Size = UDim2.fromOffset(wide, math.max(bottom - top, C.Row))
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = P.Line
	-- Scrolling, the window narrows by the bar and clips there: the canvas narrows with it, so a right-aligned change
	-- ends beside the bar, never under it (TR36's card at phone size, a ring's eight lines).
	list.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list:SetAttribute("Keep", id)
	list.Parent = made
	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Parent = list
	return list
end

-- A card's frame over the grid's right: the seam's card a step up from the room, its sliding edge lit, its shadow on
-- the grid, its close, and the side of a touch.
local function cardFrame(at: Layout, id: string, taps: { [Instance]: () -> () }): (Frame, number)
	local holder = room :: Frame
	local made = Instance.new("Frame")
	made.Name = "Card"
	made.BorderSizePixel = 0
	made.BackgroundColor3 = Color3.new(1, 1, 1)
	made.Size = UDim2.new(1, -SEAM.Shade.Wide, 1, 0)
	made.Position = if carded == id then OPEN else SHUT
	made:SetAttribute("For", id)
	ramp(made, P.Field)
	round(made, C.Card.Corner)
	local shade = plain("Shade", made, -SEAM.Shade.Wide, 0, SEAM.Shade.Wide, at.Half.Tall)
	shade.BackgroundTransparency = 0
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	local fall = Instance.new("UIGradient")
	fall.Transparency = NumberSequence.new(1, 1 - SEAM.Shade.Alpha)
	fall.Parent = shade
	Seam.Edge(made, "SlideEdge", 0, 0, at.Half.Tall, true, SEAM.Edges.Card)
	made.Parent = holder
	local side = touch()
	local shut = press("Close", made, at.Half.Wide - side, 0, side, side, close, taps)
	cross(shut, P.Text, C.Card.Close)
	return made, side
end

local function foot(at: Layout): number
	return at.Half.Tall - C.Card.Pad - touch()
end

-- A card's head: the cell, its rarity and its kind beside it, and its title under them, two lines at most. Returns
-- where the head ends.
local function head(made: Frame, at: Layout, side: number, rarity: string, image: string?, words: string, class: string?, drained: boolean, kindWord: string, title: string): number
	local pad = C.Card.Pad
	local cellSide = C.Card.Cell
	local holder = plain("Head", made, pad, pad, cellSide, cellSide)
	art(holder, cellSide, rarity, image, words, class, drained)
	local nx = pad + cellSide + 10
	local beside = math.max(at.Half.Wide - nx - side, 10)
	label({ Name = "Rarity", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Rarity[rarity] or P.Soft, Box = UDim2.fromOffset(beside, 18), Position = UDim2.fromOffset(nx, pad + 8), Parent = made, Truncate = true }, if rarity == "" then "Chest" else rarity)
	label({ Name = "Kind", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(beside, 18), Position = UDim2.fromOffset(nx, pad + 27), Parent = made, Truncate = true }, kindWord)
	local y = pad + cellSide + 6
	local name = label({ Name = "ItemName", Size = C.Card.Title, Font = Theme.Font.Strong, Colour = P.Text, Box = UDim2.fromOffset(at.Half.Wide - pad * 2, 42), Position = UDim2.fromOffset(pad, y), Parent = made, Wrap = true, Truncate = true }, title)
	name.TextYAlignment = Enum.TextYAlignment.Top
	return y + 44
end

-- The chosen item's card: against what it replaces, or for a worn one, what taking it off does.
local function itemCard(context: Context, at: Layout, id: string)
	local data = context.View :: any
	local info = Rules.Card(data, context.Owned, id)
	if info == nil then
		chosen = nil
		return
	end
	local made, side = cardFrame(at, id, context.Taps)
	local pad = C.Card.Pad
	local wide = at.Half.Wide - pad * 2
	local y = head(made, at, side, info.Rarity, info.Image, info.Kind, info.Class, not info.Fits, info.Kind, info.Name)
	local why: string? = nil
	if info.Fits then
		-- Combat Power's change on its dark plate, an up arrow beside a gain.
		local up = info.Power > 0
		local colour = if up then P.Up elseif info.Power < 0 then P.Down else P.Faint
		local plate = plain("PowerChange", made, pad, y, wide, NUMBER_ROW + 8)
		plate.BackgroundTransparency = 0.15
		plate.BackgroundColor3 = P.Seat
		round(plate, 3)
		-- the doll's own word (research's fix 3 to the rebuild); the number, right-aligned, keeps the plate's other side
		label({ Name = "Word", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(wide * 0.6, NUMBER_ROW + 8), Position = UDim2.fromOffset(8, 0), Parent = plate, Truncate = true }, Sheet.Said.Power)
		local number = label({ Name = "Power", Size = Theme.Text.Title, Font = Theme.Font.Number, Colour = colour, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(wide - 8 - 20, NUMBER_ROW + 8), Parent = plate }, Sheet.Change("Power", info.Power))
		number:SetAttribute("Power", info.Power)
		if up then
			arrow(plain("Mark", plate, wide - 18, (NUMBER_ROW + 8 - 14) / 2, 14, 14), colour, 14)
		end
		y += NUMBER_ROW + 12
		-- What it goes in place of: the worn slot, the item it replaces in that item's rarity, or the empty slot.
		local words = plain("Replaces", made, pad, y, wide, C.Row)
		if info.Worn then
			label({ Name = "Worn", Size = Theme.Text.Caption, Colour = P.Soft, Parent = words, Truncate = true }, `Worn in {info.Worn}`)
		else
			local replaced = if info.Replaces then context.View.Items[info.Replaces] else nil
			local design = if replaced then Items.Design(replaced) else nil
			local row = if replaced then Items.ById[replaced.Def] else nil
			local name = if design then design.Name elseif row then row.Name else nil
			if replaced and name then
				label({ Name = "For", Size = Theme.Text.Caption, Colour = P.Faint, Box = UDim2.fromOffset(24, C.Row), Parent = words }, "for")
				label({ Name = "Name", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Rarity[replaced.Rarity] or P.Text, Box = UDim2.fromOffset(wide - 24, C.Row), Position = UDim2.fromOffset(24, 0), Parent = words, Truncate = true }, name)
			else
				label({ Name = "Into", Size = Theme.Text.Caption, Colour = P.Soft, Parent = words, Truncate = true }, `Into the empty {info.Slot}`)
			end
		end
		y += C.Row + 4
	else
		-- Whose it is: its class's mark and its name, and Equip off for the same reason.
		why = `{info.Class or "Another class"} only`
		if info.Class then
			Skin.Icon(made, `Class{info.Class}Glyph`, pad + 7, y + C.Row / 2, 14, P.Soft).Name = "ClassMark"
		end
		label({ Name = "Whose", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Text, Box = UDim2.fromOffset(wide - 20, C.Row), Position = UDim2.fromOffset(pad + 20, y), Parent = made, Truncate = true }, why)
		y += C.Row + 4
	end
	rule(made, pad, y, wide)
	local bottom = foot(at)
	local list = lines(made, id, pad, y + 2, wide, bottom - 6)
	if info.Fits then
		-- Only what it changes, Basic then Battle: on a phone an unchanged line would push the change under the fold.
		local basic = 0
		for index, each in info.Basic do
			if each.Change ~= 0 then
				basic += 1
				compared(list, index, wide, each.Stat, Sheet.Said[each.Stat] or each.Stat, Hud.Digits(each.Value + each.Change), each.Change)
			end
		end
		if basic > 0 then
			caption(list, 0, wide, "Basic")
		end
		if #info.Battle > 0 then
			caption(list, 100, wide, "Battle")
		end
		for index, each in info.Battle do
			compared(list, 100 + index, wide, each.Stat, Sheet.Said[each.Stat] or each.Stat, Sheet.Amount(each.Stat, each.Value + each.Change), each.Change)
		end
		if basic == 0 and #info.Battle == 0 then
			label({ Name = "None", Size = Theme.Text.Caption, Colour = P.Faint, Box = UDim2.fromOffset(wide, C.Row), Parent = list }, "No change").LayoutOrder = 101
		end
	else
		caption(list, 0, wide, "Its lines")
		for index, each in info.Lines do
			local line = Instance.new("Frame")
			line.Name = each.Stat
			line.BackgroundTransparency = 1
			line.Size = UDim2.new(1, 0, 0, C.Row)
			line.LayoutOrder = index
			line.Parent = list
			label({ Name = "Name", Size = Theme.Text.Caption, Colour = P.Soft, Parent = line }, Sheet.Said[each.Stat] or each.Stat)
			label({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Text, Align = Enum.TextXAlignment.Right, Parent = line }, Sheet.Amount(each.Stat, each.Value))
		end
	end
	-- The foot: Equip, the card's main action, under the right thumb, and Salvage at its left (the follow-up's item 6).
	local owned = context.Owned
	local class = (Voidkin.ById[owned.Def] :: Voidkin.Row?) and (Voidkin.ById[owned.Def] :: Voidkin.Row).Class
	local half = math.floor((wide - 6) / 2)
	local equip = Button.new({
		Name = if info.Worn then "TakeOff" else "Equip",
		Text = if info.Worn then "Take off" else "Equip",
		Size = UDim2.fromOffset(half, touch()),
		Position = UDim2.fromOffset(pad + half + 6, bottom),
		Parent = made,
		Primary = not info.Worn, -- the glass; one that doesn't fit, the main action unavailable (AR30)
		Quiet = info.Worn ~= nil,
		Palette = Seam.Palette,
		OnPress = function(): boolean
			local args = { Preset = owned.Preset, Slot = info.Worn or info.Slot, Class = if Gear.IsHand(info.Worn or info.Slot) then class else nil, Item = if info.Worn then "" else id }
			local ok = said(EQUIP_SAID, if info.Worn then "Can't take it off" else "Can't equip it", context.Act("Equip", args))
			if ok then
				close() -- the doll shows again, its Combat Power counting to its new number
			end
			return ok
		end,
	})
	if why then
		Button.Set(equip, { Disabled = why })
	end
	-- Salvage: a first tap says what it gives, a second within ARMED seconds salvages, so one slip never loses an item.
	-- An item a preset wears is refused on the server; here it's off with the reason.
	local item = context.View.Items[id]
	local credits = if item then Chests.Salvage(item) else 0
	local armedAt = 0
	local salvage: TextButton
	salvage = Button.new({
		Name = "SalvageItem", -- Chests' picker is "Salvage"
		Text = "Salvage",
		Size = UDim2.fromOffset(half, touch()),
		Position = UDim2.fromOffset(pad, bottom),
		Parent = made,
		Quiet = true,
		Under = true,
		Palette = Seam.Palette,
		OnPress = function(): boolean?
			if os.clock() - armedAt > ARMED then
				armedAt = os.clock()
				local at = armedAt
				Button.Set(salvage, { Text = "Confirm", Selected = true, Note = `+{Hud.Digits(credits)} Credits` })
				task.delay(ARMED, function()
					if armedAt == at and salvage.Parent then
						armedAt = 0
						Button.Set(salvage, { Text = "Salvage", Selected = false, Note = false })
					end
				end)
				return nil -- asked, not answered: no tick
			end
			armedAt = 0
			local answer = context.Act("SalvageItem", { Item = id })
			if not said(SALVAGE_SAID, "Can't salvage it", answer) then
				Button.Set(salvage, { Text = "Salvage", Selected = false, Note = false })
				return false
			end
			Toast.Show(`Salvaged for {Hud.Digits(tonumber(answer.Credits) or credits)} Credits`, Theme.Colour.Text)
			close()
			return true
		end,
	})
	if info.Worn or Chests.IsWorn(data, id) then
		Button.Set(salvage, { Disabled = if info.Worn then "Take it off first" else "Another Voidkin wears it" })
	end
	card = made
	if carded ~= id then
		slide(made, true)
	end
	carded = id
end

-- The chosen chest's card: its odds, how many are held, and Open and Open all.
local function chestCard(context: Context, at: Layout, id: string)
	local data = context.View :: any
	local info = Rules.Chest(data, id)
	if info == nil then
		chosen = nil
		return
	end
	local made, side = cardFrame(at, id, context.Taps)
	local pad = C.Card.Pad
	local wide = at.Half.Wide - pad * 2
	local entry: Rules.Entry? = nil
	for _, each in Rules.List(data, nil, "Chests", "New") do
		entry = if each.Id == id then each else entry
	end
	local shown = entry :: Rules.Entry
	local y = head(made, at, side, "", shown.Image, slotWord(shown), nil, false, `×{Hud.Digits(info.Held)} held`, info.Name)
	rule(made, pad, y, wide)
	local bottom = foot(at)
	local list = lines(made, id, pad, y + 2, wide, bottom - 6)
	list:SetAttribute("Keep", nil)
	local odds = Instance.new("Frame")
	odds.Name = "Odds"
	odds.BackgroundTransparency = 1
	odds.Size = UDim2.fromOffset(wide, 0)
	odds.AutomaticSize = Enum.AutomaticSize.Y
	odds.Parent = list
	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Parent = odds
	caption(odds, 0, wide, "What it gives")
	for index, each in info.Odds do
		local line = Instance.new("Frame")
		line.Name = each.Rarity
		line.BackgroundTransparency = 1
		line.Size = UDim2.fromOffset(wide, C.Row)
		line.LayoutOrder = index
		line.Parent = odds
		label({ Name = "Name", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Rarity[each.Rarity] or P.Text, Parent = line }, each.Rarity)
		label({ Name = "Chance", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Text, Align = Enum.TextXAlignment.Right, Parent = line }, Sheet.Percent(each.Chance))
	end
	if info.Room > 0 then
		label({ Name = "Room", Size = Theme.Text.Caption, Colour = P.Faint, Box = UDim2.fromOffset(wide, C.Row), Parent = odds }, `Room for {Hud.Digits(info.Room)} in the bag`).LayoutOrder = #info.Odds + 1
	else
		-- a full bag says how to free a slot (the follow-up's item 6), two lines where the room's one stood
		label({ Name = "Room", Size = Theme.Text.Caption, Colour = P.Down, Box = UDim2.fromOffset(wide, C.Row * 2), Parent = odds, Wrap = true }, `The bag is full: {FREE_A_SLOT}`).LayoutOrder = #info.Odds + 1
	end
	local action = touch()
	local function open(count: number): boolean
		local answer = context.Act("OpenChests", { Chest = id, Count = count })
		if not said(CHEST_SAID, "Can't open it", answer) then
			return false
		end
		local kept = if type(answer.Items) == "table" then #answer.Items else 0
		local gone = tonumber(answer.Salvaged) or 0
		local words = `Opened {Hud.Digits(tonumber(answer.Opened) or count)}: {Hud.Digits(kept)} kept`
		if gone > 0 then
			words ..= `, {Hud.Digits(gone)} salvaged for {Hud.Digits(tonumber(answer.Credits) or 0)} Credits`
		end
		Toast.Show(words, Theme.Colour.Text)
		return true
	end
	local many = info.Step > 1
	local buttonWide = if many then math.floor((wide - 6) / 2) else wide
	local one = Button.new({
		Name = "OpenOne",
		Text = "Open",
		Size = UDim2.fromOffset(buttonWide, action),
		Position = UDim2.fromOffset(pad, bottom),
		Parent = made,
		Primary = not many,
		Quiet = many,
		Palette = Seam.Palette,
		OnPress = function(): boolean
			return open(1)
		end,
	})
	if info.Step < 1 then
		Button.Set(one, { Disabled = "The bag is full" })
	end
	if many then
		Button.new({
			Name = "OpenAll",
			Text = `Open {info.Step}`,
			Size = UDim2.fromOffset(buttonWide, action),
			Position = UDim2.fromOffset(pad + buttonWide + 6, bottom),
			Parent = made,
			Primary = true,
			Palette = Seam.Palette,
			OnPress = function(): boolean
				return open(info.Step)
			end,
		})
	end
	card = made
	if carded ~= id then
		slide(made, true)
	end
	carded = id
end

local lastLayout: Layout? = nil

refresh = function()
	local context, at = last, lastLayout
	if context == nil or at == nil then
		return
	end
	for id, cell in cells do
		local ring = cell:FindFirstChild("Chosen")
		if ring and ring:IsA("GuiObject") then
			ring.Visible = id == chosen
			Seam.Raise(cell, id == chosen)
		end
	end
	local data = context.View :: any
	local target: string? = nil
	local isItem = chosen ~= nil and context.View.Items[chosen :: string] ~= nil
	if isItem then
		local info = Rules.Card(data, context.Owned, chosen :: string)
		target = if info and info.Fits then info.Slot else nil
	end
	drawSlots(context, at, target)
	if card and card:GetAttribute("For") ~= chosen then
		local was = card
		card = nil
		if chosen == nil then
			carded = nil
			slide(was, false, function()
				was:Destroy()
			end)
		else
			was:Destroy()
		end
	end
	if room == nil or chosen == nil or card ~= nil then
		return
	end
	if isItem then
		itemCard(context, at, chosen :: string)
	elseif context.View.Bag.Chests[chosen :: string] then
		chestCard(context, at, chosen :: string)
	else
		chosen = nil
	end
end

-- A chip on the kinds' row, in AR30's make (UI.Kit.Button's Chip; Config.Hud.Make.Chip): no plate of its own, the row is
-- its channel; the glass when chosen; its word in Soft, and in Text under a finger over a short line.
local function chip(parent: Instance, name: string, order: number, lit: boolean, taps: { [Instance]: () -> () }, onTap: () -> ()): TextButton
	local made = Button.new({ Name = name, Text = name, Size = UDim2.fromOffset(Theme.Size.Tap, Theme.Size.Tap), Chip = true, LayoutOrder = order, Palette = Seam.Palette, OnPress = onTap })
	Button.Fit(made)
	Button.Set(made, { Selected = lit })
	made:SetAttribute("Chosen", lit)
	made.Parent = parent
	taps[made] = onTap
	return made
end

-- The strip's right: the sort, or in Chests the salvage's steps, a picker in AR30's make (Button's Pick): its name, its
-- value, a chevron; its value in the light while it isn't the first step.
local function picker(parent: Instance, name: string, words: string, value: string, on: boolean, taps: { [Instance]: () -> () }, onTap: () -> ()): TextButton
	local made = Button.new({ Name = name, Text = value, Pick = words, Size = UDim2.fromOffset(Theme.Size.Tap, Theme.Size.Tap), Palette = Seam.Palette, OnPress = onTap })
	Button.Fit(made)
	Button.Set(made, { Selected = on })
	made.Parent = parent
	taps[made] = onTap
	return made
end

-- The kinds' row: one channel (AR30's make), its shadow and fill under the chips, its edge over them and their veils.
local CHANNEL = UIKit.Palettes.Seam
local function channel(holder: Frame, over: Frame)
	local under = Skin.Of(holder)
	Skin.Lay(under, "ButtonShadow", { Name = "Shadow", Z = 1 })
	local fill = Skin.Lay(under, "ButtonFill", { Name = "Fill", Z = 2 })
	Skin.Tint(fill, CHANNEL.Channel)
	fill.ImageTransparency = HudConfig.Make.Channel.Rest
	local line = Skin.Lay(Skin.Of(over), "ButtonEdge", { Name = "Edge", Z = 1 })
	line.ImageColor3 = CHANNEL.Edge
end

local EMPTY: { [string]: { string } } = {
	All = { "Nothing in the bag yet", "Shades and keepers drop gear" },
	Gear = { "No gear yet", "Shades and keepers drop it" },
	Jewelry = { "No jewelry yet", "Shades and keepers drop it" },
	Chests = { "No chests yet", "Shades drop them, and keepers" },
	Materials = { "No shards yet", "The Arcs drop them" },
}

function Bag.Build(context: Context): (() -> boolean)?
	last = context
	cells = {}
	card = nil
	local at = layout(context.Room, context.Left)
	lastLayout = at
	local body = context.Body
	local taps = context.Taps
	-- The page's room: the seam's panel over the screen's backing, its top a lit edge, laid under the stage so the
	-- figure stands on it.
	Seam.Case(context.Behind, "Case", at.Case.X, at.Case.Y, at.Case.Wide, at.Case.Tall)
	-- The strip: the five kinds' row, scrolling, then the sort or, in Chests, the salvage's steps (AR30's make).
	local data = context.View :: any
	local right: TextButton
	local strip = plain("Strip", body, at.Strip.X, at.Strip.Y, at.Strip.Wide, at.Strip.Tall)
	if kind == "Chests" then
		local below = context.View.Settings.Salvage
		right = picker(strip, "Salvage", "Salvage:", if below == "" then "Off" else below, below ~= "", taps, function()
			local steps = C.Salvage
			local at_ = table.find(steps, below) or 1
			local nextOne = steps[at_ % #steps + 1]
			local answer = context.Act("SetSalvage", { Below = nextOne })
			if said(CHEST_SAID, "Can't set it", answer) then
				Toast.Show(if nextOne == "" then "Salvage off: every item kept" else `{nextOne} and under turn into Credits, unless they'd raise {Sheet.Said.Power}`, Theme.Colour.Text)
			end
		end)
	else
		right = picker(strip, "Sort", "Sort:", Sheet.Said[sort] or sort, sort ~= Rules.Sorts[1], taps, function()
			local at_ = table.find(Rules.Sorts, sort) or 1
			sort = Rules.Sorts[at_ % #Rules.Sorts + 1]
			context.Rebuild()
		end)
	end
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.fromScale(1, 0)
	-- The row: its channel under the kinds' window, its edge over the chips and their veils.
	local rowWide = UDim2.new(1, -(right.Size.X.Offset + Theme.Size.Gap), 1, 0)
	local row = plain("Row", strip, 0, 0, 0, 0)
	row.Size = rowWide
	local rowEdge = plain("RowEdge", strip, 0, 0, 0, 0)
	rowEdge.Size = rowWide
	rowEdge.ZIndex = 4
	channel(row, rowEdge)
	local kinds = Instance.new("ScrollingFrame")
	kinds.Name = "Kinds"
	kinds.BackgroundTransparency = 1
	kinds.BorderSizePixel = 0
	kinds.Size = rowWide
	kinds.ZIndex = 2
	kinds.ScrollBarThickness = 0
	kinds.ScrollBarImageTransparency = 1 -- a touch device draws its thumb even at nought: a grey line under the chips
	kinds.CanvasSize = UDim2.new()
	kinds.AutomaticCanvasSize = Enum.AutomaticSize.X
	kinds.ScrollingDirection = Enum.ScrollingDirection.X
	kinds:SetAttribute("Keep", kind) -- the screen's refill puts its scroll back only while the same kind is chosen
	kinds.Parent = strip
	local line = Instance.new("UIListLayout")
	line.FillDirection = Enum.FillDirection.Horizontal
	line.Padding = UDim.new(0, 0)
	line.SortOrder = Enum.SortOrder.LayoutOrder
	line.Parent = kinds
	local lit: TextButton? = nil
	local made: { TextButton } = {}
	for index, name in Rules.Kinds do
		local one = chip(kinds, name, index, name == kind, taps, function()
			if kind ~= name then
				kind, chosen = name, nil
				context.Rebuild()
			end
		end)
		lit = if name == kind then one else lit
		table.insert(made, one)
	end
	-- A split between two unchosen chips, a hairline in Edge at the left of the second (Make.Chip: Split of a point wide,
	-- drawn a point wide at that cover).
	local K = HudConfig.Make.Chip
	for index = 2, #made do
		if made[index] ~= lit and made[index - 1] ~= lit then
			local split = Instance.new("Frame")
			split.Name = "Split"
			split.Active = false
			split.BorderSizePixel = 0
			split.BackgroundColor3 = CHANNEL.Edge
			split.BackgroundTransparency = 1 - K.Split
			split.AnchorPoint = Vector2.new(0.5, 0.5)
			split.Position = UDim2.fromScale(0, 0.5)
			split.Size = UDim2.fromOffset(1, K.SplitTall)
			split.ZIndex = 2
			split.Parent = made[index]
		end
	end
	-- A chip cut by the row's edge reads as more this way, never a stray sliver: each edge hiding a chip fades into the
	-- channel under it.
	local function veil(name: string, onLeft: boolean): Frame
		local made_ = Instance.new("Frame")
		made_.Name = name
		made_.Active = false
		made_.BorderSizePixel = 0
		made_.BackgroundColor3 = CHANNEL.Channel
		made_.AnchorPoint = Vector2.new(if onLeft then 0 else 1, 0)
		made_.Position = if onLeft then UDim2.new() else UDim2.new(1, kinds.Size.X.Offset, 0, 0)
		made_.Size = UDim2.new(0, C.Veil, 1, 0)
		made_.ZIndex = 3
		made_.Visible = false
		local gradient = Instance.new("UIGradient")
		gradient.Transparency = NumberSequence.new(if onLeft then 0 else 1, if onLeft then 1 else 0)
		gradient.Parent = made_
		made_.Parent = strip
		return made_
	end
	local before, after = veil("VeilLeft", true), veil("VeilRight", false)
	local function veils()
		local from = kinds.CanvasPosition.X
		before.Visible = from > 1
		after.Visible = from + kinds.AbsoluteWindowSize.X < kinds.AbsoluteCanvasSize.X - 1
	end
	-- The chosen kind kept in view: scrolled so its chip stands whole with Peek of its neighbour beside it, cut by the
	-- edge, so the row shows that it scrolls. Once the strip has its size and again whenever its window changes size.
	-- Its place comes from the chips' own widths in order, never from absolute positions, which a strip just built can
	-- still hold from before its layout. A player's own scroll changes no size, so it's never pulled back.
	local function keep()
		local window = kinds.AbsoluteWindowSize.X
		if lit and lit.Parent and kinds.Parent and window > 0 then
			local scale = Layers.Scale()
			local left = 0
			local prior: GuiObject?, after: GuiObject? = nil, nil
			local passed = false
			for _, name in Rules.Kinds do
				local one = kinds:FindFirstChild(name) :: GuiObject?
				if one == nil then
					continue
				elseif one == lit then
					passed = true
				elseif passed then
					after = one
					break
				else
					prior = one
					left += (one.Size.X.Offset + line.Padding.Offset) * scale
				end
			end
			local wide = lit.Size.X.Offset * scale
			if left < kinds.CanvasPosition.X then
				local peek = if prior then prior.Size.X.Offset * scale * C.Peek else 0
				kinds.CanvasPosition = Vector2.new(math.max(0, left - peek), 0)
			elseif left + wide > kinds.CanvasPosition.X + window then
				local peek = if after then after.Size.X.Offset * scale * C.Peek else 0
				kinds.CanvasPosition = Vector2.new(math.max(0, left + wide - window + peek), 0)
			end
		end
		veils()
	end
	kinds:GetPropertyChangedSignal("CanvasPosition"):Connect(veils)
	kinds:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(keep)
	kinds:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(keep)
	task.defer(keep)
	-- The grid.
	local list = Rules.List(data, context.Owned, kind, sort)
	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Page"
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.Position = UDim2.fromOffset(at.Grid.X, at.Grid.Y)
	grid.Size = UDim2.fromOffset(at.Grid.Wide, at.Grid.Tall)
	grid.ScrollBarThickness = 3
	grid.ScrollBarImageColor3 = P.Line
	grid.CanvasSize = UDim2.new()
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid:SetAttribute("Page", "Bag")
	grid:SetAttribute("Kind", kind)
	grid:SetAttribute("Keep", `Bag{kind}{sort}`)
	grid.Parent = body
	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Padding = UDim.new(0, Theme.Size.Gap)
	stack.Parent = grid
	if #list == 0 then
		local words = EMPTY[kind] or EMPTY.All
		local empty = plain("Empty", grid, 0, 0, at.Grid.Wide, math.max(at.Grid.Tall - 8, 60))
		label({ Name = "Line", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = P.Text, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0.5, -24), Parent = empty }, words[1])
		label({ Name = "Under", Size = Theme.Text.Caption, Colour = P.Soft, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0.5, 0), Parent = empty }, words[2])
	else
		local holder = Instance.new("Frame")
		holder.Name = "Cells"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, -C.Ring / 2, 0, 0)
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.LayoutOrder = 1
		holder.Parent = grid
		local inset = Instance.new("UIPadding") -- room for a chosen cell's ring at the grid's edges
		inset.PaddingTop = UDim.new(0, C.Ring / 2)
		inset.PaddingLeft = UDim.new(0, C.Ring / 2)
		inset.PaddingBottom = UDim.new(0, C.Ring / 2)
		inset.Parent = holder
		local cellsLayout = Instance.new("UIGridLayout")
		cellsLayout.CellSize = UDim2.fromOffset(at.Cell, at.Cell)
		cellsLayout.CellPadding = UDim2.fromOffset(C.CellGap, C.CellGap)
		cellsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cellsLayout.Parent = holder
		for index, entry in list do
			cells[entry.Id] = cellFor(entry, at.Cell, index, holder, taps)
		end
	end
	-- The count, under the grid and outside its scroll, so a nearly full bag says so wherever it's scrolled.
	local held = Rules.Held(data)
	local count = label({ Name = "BagCount", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = if held >= Rules.Cap then P.Down else P.Faint, Box = UDim2.fromOffset(at.Count.Wide - 4, at.Count.Tall), Position = UDim2.fromOffset(at.Count.X, at.Count.Y), Parent = body }, `{Hud.Digits(held)} / {Hud.Digits(Rules.Cap)} in the bag`)
	count:SetAttribute("Held", held)
	-- The seam between the doll and the grid: a lit edge, strongest at its middle.
	Seam.Edge(body, "Rule", at.Doll.X + at.Doll.Wide + Theme.Size.Gap + 0.5, C.Inset * 2, at.Case.Tall - C.Inset * 4, true, SEAM.Edges.Rule)
	-- The doll: its name and level over the figure, the figure on its stage, its Combat Power at its feet, then the slots.
	local doll = at.Doll
	local owned = context.Owned
	local x = doll.X + at.Hit
	local over = plain("Over", body, x, doll.Y, at.Figure, doll.Tall - at.Hit - C.Doll.Gap)
	local save = context.Name(over, at.Figure)
	local nameRow = over:FindFirstChild("Name")
	local nameTall = if nameRow and nameRow:IsA("GuiObject") then nameRow.Size.Y.Offset else 24
	local own = Voidkin.ById[owned.Def]
	label({ Name = "Level", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(at.Figure - Theme.Size.Pad * 2, C.Doll.Level), Position = UDim2.fromOffset(Theme.Size.Pad, nameTall), Parent = over, Truncate = true }, `Lv {owned.Level}  {if own then own.Class else ""}`)
	local top = nameTall + C.Doll.Level
	local power = HudConfig.Voidkin.Power.Height
	context.Stage({ X = x, Y = doll.Y + top, Wide = at.Figure, Tall = math.max(over.Size.Y.Offset - top, 1) })
	local feet = plain("Feet", over, 0, over.Size.Y.Offset - power, at.Figure, power)
	context.Power(feet, at.Figure)
	slots = plain("Doll", body, doll.X, doll.Y, doll.Wide, doll.Tall)
	-- The card's room over the doll, clipping its slide.
	local shelf = plain("CardRoom", body, at.Half.X - SEAM.Shade.Wide, at.Half.Y, at.Half.Wide + SEAM.Shade.Wide, at.Half.Tall)
	shelf.ClipsDescendants = true
	shelf.ZIndex = 5
	room = shelf
	if chosen and context.View.Items[chosen :: string] == nil and (context.View.Bag.Chests[chosen :: string] or 0) <= 0 then
		chosen, carded = nil, nil -- opened, salvaged or gone: no card
	end
	refresh()
	return save
end

function Bag.Reset()
	kind, sort, chosen, carded = "All", "Rarity", nil, nil
end

function Bag.State(): { Kind: string, Sort: string, Chosen: string? }
	return { Kind = kind, Sort = sort, Chosen = chosen }
end

function Bag.Choose(id: string?)
	choose(id)
end

-- A's cell, for another screen's item (Equipment's rows and its gear in the ring): art(holder, side, rarity, image,
-- words, class, drained).
Bag.Art = art

return Bag
