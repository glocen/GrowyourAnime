--!strict
-- The Items page (client; TR28): AR18's C, "the case", in BONE (research's pick, 2026-11-16, 14:27; its fixes 1 to 3 at
-- 15:12; fix 4 at 16:52; docs/research/rework-2026-11-16.md, part 5; docs/ui.md, the bag). The whole room right of the
-- rail is one case of warmed porcelain:
--   the belt across its top: the fourteen slots in their three groups, what the shown Voidkin wears in each. Where all
--     fourteen don't stand at a touch, only the chosen item's group shows (the hands' with nothing chosen), the other
--     two a chip each (fix 4, way 1). The slot the chosen item would go in wears an ink ring;
--   under it, the bag's six kinds on a strip that scrolls, the chosen one kept in view, and at its end the sort (the
--     salvage's control, in Chests);
--   the grid, five across or more: each cell a dark inlay with its rarity's enamel across its head, a lit up arrow when
--     wearing it would raise the shown Voidkin's Combat Power, a tick when it's worn, another class's weapon dimmed with
--     its class's mark. Chests stand after the items with their counts, the shards after them;
--   beside it, the Voidkin's half: its figure on its stage, its Combat Power at its feet, its totals beside it. A chosen
--     item's card slides over it in 0.16 s: the item against what it replaces, each Basic and Battle Attribute's change,
--     and Equip, or Take off when it's worn. Another class's weapon lists its lines, says whose it is, and Equip is off.
--     A chest's card holds its odds, and Open and Open all (in steps of 50).
-- Every number comes from Rules.Bag, so what a cell says is what the logic cases check; every change is asked of the
-- server through Act, and the screen is rebuilt from the server's copy. A tap on a cell changes the card and the rings in
-- place, never the grid.
--   Bag.Build(context) -> the rename's save, from the name line over the stage
--   Bag.Reset()        a fresh open: All, by rarity, nothing chosen
--   Bag.State()        for tests: the kind, the sort, the chosen thing, the belt's group, whether all fourteen show
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
local Stats = require(Shared.Rules.Stats)
local Sheet = require(Shared.Rules.Sheet)
local Hud = require(Shared.Rules.Hud)
local HudConfig = require(Shared.Config.Hud)
local UI = script.Parent.Parent
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Toast = require(UI.Kit.Toast)
local Skin = require(UI.Kit.Skin)

local Bag = {}

type Box = { X: number, Y: number, Wide: number, Tall: number }

export type Context = {
	Body: Frame,
	Room: Vector2,
	Left: number, -- where the case starts, authored, right of the rail
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
local P = C.Palette
local GROUP_KIND = { "Weapons", "Armour", "Jewellery" } -- each belt group's kind on the strip, and its chip's word
local TIER_WORD = { "Common", "Elite", "Keeper's" } -- a chest's tier on its cell
local NUMBER_ROW = 20 -- the card's Combat Power line
local CHEST_SAID: { [string]: string } = { NotEnough = "Not that many held", BagFull = "The bag is full", Unknown = "Not now" }
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
local group: number? = nil -- the belt's group a chip asked for, on a narrow belt, until the next choice
local carded: string? = nil -- the card drawn last, so only a new one slides in
local last: Context? = nil
local cells: { [string]: GuiObject } = {}
local belt: Frame? = nil
local room: Frame? = nil -- the card's room, over the Voidkin's half, clipping its slide
local card: Frame? = nil
local whole = true -- all fourteen slots on the belt

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

local function edge(on: Instance, colour: Color3, thickness: number?, name: string?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Name = name or "Edge"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = colour
	stroke.Thickness = thickness or 1
	stroke.Parent = on
	return stroke
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

-- Where each piece stands, authored, in the room right of the rail (fix 4: the half narrows before the grid does).
type Layout = { Case: Box, Belt: Box, Strip: Box, Grid: Box, Count: Box, Half: Box, Cell: number, Columns: number, Slot: number, Whole: boolean }

local function layout(size: Vector2, left: number): Layout
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local case = { X = left, Y = 0, Wide = math.max(size.X - pad - left, 1), Tall = math.max(size.Y - pad, 1) }
	local x0, y0 = case.X + C.Inset, C.Inset
	local wide = case.Wide - C.Inset * 2
	local foot = case.Tall - C.Inset
	local slot = touch()
	local fourteen = 14 * slot + 11 * C.BeltGap + 2 * C.GroupGap + 2 * C.BeltInset
	local beltTall = slot + C.BeltInset * 2
	local least = C.Columns * C.Cell + (C.Columns - 1) * C.CellGap
	local half = math.clamp(wide - gap - least, 0, C.Half)
	local gridWide = wide - gap - half
	local columns = math.max(C.Columns, math.floor((gridWide + C.CellGap) / (C.Cell + C.CellGap)))
	local cell = math.max(math.floor(math.min(C.Cell, (gridWide - (columns - 1) * C.CellGap) / columns)), slot)
	local stripY = y0 + beltTall + C.Under
	local gridY = stripY + Theme.Size.Tap + C.Under
	local countY = foot - C.Row -- the count pinned under the grid, never in its scroll (research, TR28's call 3)
	return {
		Case = case,
		Belt = { X = x0, Y = y0, Wide = wide, Tall = beltTall },
		Strip = { X = x0, Y = stripY, Wide = gridWide, Tall = Theme.Size.Tap },
		Grid = { X = x0, Y = gridY, Wide = gridWide, Tall = math.max(countY - C.Under - gridY, 1) },
		Count = { X = x0, Y = countY, Wide = gridWide, Tall = C.Row },
		Half = { X = x0 + gridWide + gap, Y = stripY, Wide = half, Tall = math.max(foot - stripY, 1) },
		Cell = cell,
		Columns = columns,
		Slot = slot,
		Whole = fourteen <= wide,
	}
end

-- A thing's dark inlay, `side` across: its rarity's enamel across its head, its stand-in art (its kind's word, until
-- AR6's icons), dimmed for another class with that class's mark at its foot.
local function inlay(holder: GuiObject, rarity: string, words: string, side: number, dim: boolean, class: string?)
	holder.BackgroundColor3 = Color3.new(1, 1, 1)
	holder.BackgroundTransparency = 0
	ramp(holder, if rarity == "Legendary" then P.Umber else P.Well)
	round(holder, C.Corner)
	edge(holder, P.Line)
	local band = Instance.new("Frame")
	band.Name = "Band"
	band.BorderSizePixel = 0
	band.BackgroundColor3 = P.Band[rarity] or P.Band.Common
	band.BackgroundTransparency = if dim then 0.65 else 0
	band.Position = UDim2.fromOffset(C.Corner - 1, 3)
	band.Size = UDim2.fromOffset(side - (C.Corner - 1) * 2, C.Band)
	round(band, 2)
	band.Parent = holder
	local art = label({
		Name = "Art",
		Size = Theme.Text.Caption,
		Font = Theme.Font.Strong,
		Colour = P.OnWell,
		Align = Enum.TextXAlignment.Center,
		Box = UDim2.fromOffset(side - 6, side - 14),
		Position = UDim2.fromOffset(3, 8),
		Parent = holder,
		Wrap = true,
		Truncate = true,
	}, words)
	art.TextTransparency = if dim then 0.55 else 0
	if dim and class then
		local mark = Skin.Icon(holder, `Class{class}Glyph`, side - C.Mark / 2 - 3, side - C.Mark / 2 - 3, C.Mark, P.OnWell)
		mark.Name = "Class"
	end
end

-- A lit square in a cell's corner, `left` or right, holding `fill`'s mark.
local function corner(holder: GuiObject, name: string, left: boolean, side: number, fill: (Frame) -> ())
	local chip = Instance.new("Frame")
	chip.Name = name
	chip.BorderSizePixel = 0
	chip.BackgroundColor3 = P.Lit
	chip.Size = UDim2.fromOffset(C.Mark, C.Mark)
	chip.Position = UDim2.fromOffset(if left then 3 else side - C.Mark - 3, C.Band + 6)
	round(chip, 3)
	chip.Parent = holder
	fill(chip)
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
	group = nil
	refresh()
end

local function cellFor(entry: Rules.Entry, side: number, order: number, parent: Instance, taps: { [Instance]: () -> () }): GuiObject
	local made = Instance.new("TextButton")
	made.Name = entry.Id
	made.Text = ""
	made.AutoButtonColor = false
	made.BorderSizePixel = 0
	made.LayoutOrder = order
	made:SetAttribute("Kind", entry.Kind)
	made:SetAttribute("Rarity", entry.Rarity)
	made:SetAttribute("Up", entry.Up)
	made:SetAttribute("Worn", entry.Worn or "")
	made:SetAttribute("Fits", entry.Fits)
	made:SetAttribute("Count", entry.Count)
	if entry.Kind == "Shard" then
		local row = Shards.ById[entry.Def]
		inlay(made, entry.Rarity, "", side, false, nil)
		local art = HudConfig.ShardArt
		local picture = Skin.Icon(made, Hud.ShardPicture(if row then row.Grade else "Standard", side * art.Cell, art.Large), side / 2, side / 2 + 2, side * art.Cell)
		picture.Name = "Picture"
	else
		inlay(made, entry.Rarity, slotWord(entry), side, not entry.Fits, entry.Class)
	end
	if entry.Count > 1 or entry.Kind ~= "Item" then
		label({ Name = "Count", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Lit, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(side - 6, 16), Position = UDim2.fromOffset(0, side - 17), Parent = made }, `×{Hud.Digits(entry.Count)}`)
	end
	if entry.Up then
		corner(made, "Up", false, side, function(chip: Frame)
			arrow(chip, P.Up, C.Mark - 4)
		end)
	end
	if entry.Worn then
		corner(made, "WornMark", true, side, function(chip: Frame)
			Skin.Icon(chip, "Tick", C.Mark / 2, C.Mark / 2, C.Mark - 4, P.Ink)
		end)
	end
	local ring = edge(made, P.Ink, 2, "Chosen")
	ring.Enabled = entry.Id == chosen
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

-- The belt: what the shown Voidkin wears, slot by slot; on a narrow one, one group and a chip for each of the others.
local function drawBelt(context: Context, at: Layout, target: string?)
	local holder = belt
	if holder == nil then
		return
	end
	holder:ClearAllChildren()
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BorderSizePixel = 0
	plate.BackgroundColor3 = P.Belt
	plate.Size = UDim2.fromScale(1, 1)
	round(plate, 10)
	edge(plate, P.Line, 0.8)
	plate.Parent = holder
	local data = context.View :: any
	local worn = Rules.Worn(data, context.Owned)
	local slot = at.Slot
	local x = C.BeltInset
	local showing = if whole then nil else (group or (if target then Rules.GroupOf(target) else 1))
	holder:SetAttribute("Group", showing or 0)
	for index, slots in Rules.Groups do
		if showing and index ~= showing then
			local word = GROUP_KIND[index]
			local probe = label({ Name = "Probe", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Parent = holder }, word)
			local wide = math.max(math.ceil(Text.Wide(probe, word)) + Theme.Size.Pad * 2, slot)
			probe:Destroy()
			local chip = press(`Group{index}`, holder, x, C.BeltInset, wide, slot, function()
				group = index
				refresh()
			end, context.Taps)
			chip.BackgroundTransparency = 0
			chip.BackgroundColor3 = Color3.new(1, 1, 1)
			ramp(chip, P.Slot)
			round(chip, 6)
			label({ Name = "Word", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Soft, Align = Enum.TextXAlignment.Center, Parent = chip }, word)
			x += wide + C.GroupGap
			continue
		end
		for at_, name in slots do
			local id = worn[name]
			local item = if id then context.View.Items[id] else nil
			local row = if item then Items.ById[item.Def] else nil
			local function onTap()
				if id then
					choose(if chosen == id then nil else id)
				else
					Toast.Show(`{name}: empty`, Theme.Colour.TextDim)
					kind = GROUP_KIND[index]
					chosen, group = nil, nil
					context.Rebuild()
				end
			end
			local made = press(name, holder, x, C.BeltInset, slot, slot, onTap, context.Taps)
			made:SetAttribute("Slot", name)
			made:SetAttribute("Item", id or "")
			if item and row then
				inlay(made, item.Rarity, row.Kind, slot, false, nil)
			else
				made.BackgroundTransparency = 0
				made.BackgroundColor3 = Color3.new(1, 1, 1)
				ramp(made, P.Slot)
				round(made, 6)
				local seat = Instance.new("Frame")
				seat.Name = "Seat"
				seat.BorderSizePixel = 0
				seat.BackgroundColor3 = P.SlotMark
				seat.BackgroundTransparency = 0.35
				seat.AnchorPoint = Vector2.new(0.5, 0.5)
				seat.Position = UDim2.fromScale(0.5, 0.5)
				seat.Size = UDim2.fromScale(0.26, 0.26)
				seat.Rotation = 45
				seat.Parent = made
			end
			local ring = edge(made, P.Ink, 2, "Target")
			ring.Enabled = name == target
			x += slot + (if at_ < #slots then C.BeltGap else C.GroupGap)
		end
	end
end

-- The Voidkin's totals beside its figure: its Basic Attributes, then as many Battle Attributes as stand.
local function totals(parent: Frame, block: Stats.Block, wide: number, tall: number)
	local y = 0
	local function heading(words: string)
		label({ Name = words, Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Faint, Box = UDim2.fromOffset(wide, C.Row), Position = UDim2.fromOffset(0, y), Parent = parent }, words)
		y += C.Row
	end
	local function row(stat: string, name: string, value: string)
		if y + C.Row > tall then
			return
		end
		local line = plain(stat, parent, 0, y, wide, C.Row)
		label({ Name = "Name", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(wide - 44, C.Row), Parent = line, Truncate = true }, name)
		label({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Ink, Align = Enum.TextXAlignment.Right, Parent = line }, value)
		y += C.Row
	end
	heading("Basic")
	for _, each in Sheet.Basic(block) do
		row(each.Stat, each.Name, each.Value)
	end
	y += 4
	if y + C.Row * 2 <= tall then
		heading("Battle")
		for _, stat in Stats.Names do
			local each = Sheet.Row(stat, block)
			row(stat, each.Name, each.Value)
		end
	end
end

local function slide(frame: Frame, open: boolean, done: (() -> ())?)
	local tween = TweenService:Create(frame, TweenInfo.new(C.Slide, if open then Enum.EasingStyle.Quart else Enum.EasingStyle.Quad, if open then Enum.EasingDirection.Out else Enum.EasingDirection.In), { Position = UDim2.fromScale(if open then 0 else 1, 0) })
	if done then
		tween.Completed:Connect(function()
			done()
		end)
	end
	tween:Play()
end

-- Closes the card: it slides back off the Voidkin's half.
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

-- One line of the card's comparison: the stat's name, its total, its change in green or red.
local function compared(parent: Instance, order: number, wide: number, stat: string, name: string, value: string, change: number)
	local line = Instance.new("Frame")
	line.Name = stat
	line.BackgroundTransparency = 1
	line.Size = UDim2.fromOffset(wide, C.Row)
	line.LayoutOrder = order
	line.Parent = parent
	local change_ = Sheet.Change(stat, change)
	local changeWide = 40
	label({ Name = "Name", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(math.max(wide - changeWide - 44, 10), C.Row), Parent = line, Truncate = true }, name)
	label({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Ink, Align = Enum.TextXAlignment.Right, Box = UDim2.fromOffset(wide - changeWide - 2, C.Row), Parent = line }, value)
	local delta = label({ Name = "Change", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = if change > 0 then P.Up elseif change < 0 then P.Down else P.Faint, Align = Enum.TextXAlignment.Right, Parent = line }, change_)
	delta:SetAttribute("Change", change)
end

local function column(parent: Instance, name: string, x: number, wide: number): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BackgroundTransparency = 1
	made.Position = UDim2.fromOffset(x, 0)
	made.Size = UDim2.fromOffset(wide, 0)
	made.AutomaticSize = Enum.AutomaticSize.Y
	made.Parent = parent
	local layout_ = Instance.new("UIListLayout")
	layout_.SortOrder = Enum.SortOrder.LayoutOrder
	layout_.Parent = made
	return made
end

local function caption(parent: Instance, order: number, wide: number, words: string)
	local made = label({ Name = words, Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Faint, Box = UDim2.fromOffset(wide, C.Row), Parent = parent }, words)
	made.LayoutOrder = order
end

-- A card's frame over the Voidkin's half: its porcelain, its close, and its body's box under the head.
local function cardFrame(at: Layout, id: string, taps: { [Instance]: () -> () }): (Frame, number)
	local holder = room :: Frame
	local made = Instance.new("Frame")
	made.Name = "Card"
	made.BorderSizePixel = 0
	made.BackgroundColor3 = Color3.new(1, 1, 1)
	made.Size = UDim2.fromScale(1, 1)
	made.Position = UDim2.fromScale(if carded == id then 0 else 1, 0)
	made:SetAttribute("For", id)
	ramp(made, P.Card)
	round(made, C.Card.Corner)
	edge(made, P.Line)
	made.Parent = holder
	local side = touch()
	local shut = press("Close", made, at.Half.Wide - side, 0, side, side, close, taps)
	cross(shut, P.Ink, C.Card.Close)
	return made, side
end

local function foot(made: Frame, at: Layout): number
	return at.Half.Tall - C.Card.Pad - touch()
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
	local cellSide = C.Card.Cell
	local head = plain("Head", made, pad, pad, cellSide, cellSide)
	inlay(head, info.Rarity, info.Kind, cellSide, not info.Fits, info.Class)
	local nx = pad + cellSide + 8
	local nameWide = at.Half.Wide - nx - side + 6
	local name = label({ Name = "ItemName", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = P.Ink, Box = UDim2.fromOffset(nameWide, 38), Position = UDim2.fromOffset(nx, pad - 2), Parent = made, Wrap = true, Truncate = true }, info.Name)
	name.TextYAlignment = Enum.TextYAlignment.Top
	local y = pad + 38
	if info.Fits then
		local up = info.Power > 0
		local line = plain("PowerChange", made, nx, y, at.Half.Wide - nx - pad, NUMBER_ROW)
		local colour = if up then P.Up elseif info.Power < 0 then P.Down else P.Faint
		local mark = plain("Mark", line, 0, 3, 14, 14)
		if up then
			arrow(mark, colour, 14)
		end
		local number = label({ Name = "Power", Size = Theme.Text.Title, Font = Theme.Font.Number, Colour = colour, Box = UDim2.new(1, -18, 1, 0), Position = UDim2.fromOffset(if up then 18 else 0, 0), Parent = line }, Sheet.Change("Power", info.Power))
		number:SetAttribute("Power", info.Power)
		y += NUMBER_ROW + 2
	end
	label({ Name = "Rarity", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Rarity[info.Rarity] or P.Ink, Box = UDim2.fromOffset(at.Half.Wide - nx - pad, 16), Position = UDim2.fromOffset(nx, y), Parent = made, Truncate = true }, `{info.Rarity} · {info.Kind}`)
	local divider = math.max(pad + cellSide, y + 16) + 6
	local rule = Instance.new("Frame")
	rule.Name = "Divider"
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = P.Line
	rule.Position = UDim2.fromOffset(pad, divider)
	rule.Size = UDim2.fromOffset(wide, 1)
	rule.Parent = made
	local bottom = foot(made, at)
	local list = Instance.new("ScrollingFrame")
	list.Name = "Lines"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(pad, divider + 4)
	list.Size = UDim2.fromOffset(wide, math.max(bottom - divider - 8, C.Row))
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = P.Line
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list:SetAttribute("Keep", id)
	list.Parent = made
	local half = math.floor((wide - 8) / 2)
	if info.Fits then
		local basic = column(list, "Basic", 0, half)
		caption(basic, 0, half, "Basic")
		for index, each in info.Basic do
			compared(basic, index, half, each.Stat, Sheet.Said[each.Stat] or each.Stat, Hud.Digits(each.Value + each.Change), each.Change)
		end
		local battle = column(list, "Battle", half + 8, half)
		caption(battle, 0, half, "Battle")
		for index, each in info.Battle do
			compared(battle, index, half, each.Stat, Sheet.Said[each.Stat] or each.Stat, Sheet.Amount(each.Stat, each.Value + each.Change), each.Change)
		end
		if #info.Battle == 0 then
			label({ Name = "None", Size = Theme.Text.Caption, Colour = P.Faint, Box = UDim2.fromOffset(half, C.Row), Parent = battle }, "No change").LayoutOrder = 1
		end
	else
		local lines = column(list, "Own", 0, wide)
		caption(lines, 0, wide, "Its lines")
		for index, each in info.Lines do
			local line = Instance.new("Frame")
			line.Name = each.Stat
			line.BackgroundTransparency = 1
			line.Size = UDim2.fromOffset(wide, C.Row)
			line.LayoutOrder = index
			line.Parent = lines
			label({ Name = "Name", Size = Theme.Text.Caption, Colour = P.Soft, Parent = line }, Sheet.Said[each.Stat] or each.Stat)
			label({ Name = "Value", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Ink, Align = Enum.TextXAlignment.Right, Parent = line }, Sheet.Amount(each.Stat, each.Value))
		end
	end
	-- The foot: what it replaces (or whose it is), and the card's one action.
	local action = touch()
	local buttonWide = if info.Fits then 96 else 120
	local leftWide = math.max(wide - buttonWide - 6, 10)
	local why: string? = nil
	if not info.Fits then
		why = `{info.Class or "Another class"} only`
		if info.Class then
			Skin.Icon(made, `Class{info.Class}Glyph`, pad + 8, bottom + action / 2, 16, P.Ink).Name = "ClassMark"
		end
		label({ Name = "Whose", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Ink, Box = UDim2.fromOffset(leftWide - 22, action), Position = UDim2.fromOffset(pad + 22, bottom), Parent = made, Truncate = true }, why)
	elseif info.Worn then
		label({ Name = "Worn", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(leftWide, action), Position = UDim2.fromOffset(pad, bottom), Parent = made, Truncate = true }, `Worn in {info.Worn}`)
	else
		local replaced = if info.Replaces then context.View.Items[info.Replaces] else nil
		local row = if replaced then Items.ById[replaced.Def] else nil
		local words = plain("Replaces", made, pad, bottom, leftWide, action)
		label({ Name = "Caption", Size = Theme.Text.Caption, Colour = P.Faint, Box = UDim2.fromOffset(leftWide, 16), Position = UDim2.fromOffset(0, action / 2 - 16), Parent = words }, if replaced then "Replaces" else `Into {info.Slot}`)
		label({ Name = "Name", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = if replaced then P.Rarity[replaced.Rarity] or P.Ink else P.Soft, Box = UDim2.fromOffset(leftWide, 16), Position = UDim2.fromOffset(0, action / 2), Parent = words, Truncate = true }, if row then row.Name else "an empty slot")
	end
	local owned = context.Owned
	local class = (Voidkin.ById[owned.Def] :: Voidkin.Row?) and (Voidkin.ById[owned.Def] :: Voidkin.Row).Class
	local equip = Button.new({
		Name = if info.Worn then "TakeOff" else "Equip",
		Text = if info.Worn then "Take off" else "Equip",
		Size = UDim2.fromOffset(buttonWide, action),
		Position = UDim2.fromOffset(at.Half.Wide - pad - buttonWide, bottom),
		Parent = made,
		Primary = info.Fits and not info.Worn,
		Quiet = info.Worn ~= nil,
		OnPress = function(): boolean
			local args = { Preset = owned.Preset, Slot = info.Worn or info.Slot, Class = if Gear.IsHand(info.Worn or info.Slot) then class else nil, Item = if info.Worn then "" else id }
			local ok = said(EQUIP_SAID, if info.Worn then "Can't take it off" else "Can't equip it", context.Act("Equip", args))
			if ok then
				close() -- the half shows again, its Combat Power counting to its new number
			end
			return ok
		end,
	})
	if why then
		Button.Set(equip, { Disabled = why })
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
	local cellSide = C.Card.Cell
	local head = plain("Head", made, pad, pad, cellSide, cellSide)
	local entry: Rules.Entry? = nil
	for _, each in Rules.List(data, nil, "Chests", "New") do
		entry = if each.Id == id then each else entry
	end
	local shown = entry :: Rules.Entry
	inlay(head, shown.Rarity, slotWord(shown), cellSide, false, nil)
	local nx = pad + cellSide + 8
	local name = label({ Name = "ItemName", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = P.Ink, Box = UDim2.fromOffset(at.Half.Wide - nx - side + 6, 38), Position = UDim2.fromOffset(nx, pad - 2), Parent = made, Wrap = true, Truncate = true }, info.Name)
	name.TextYAlignment = Enum.TextYAlignment.Top
	label({ Name = "Held", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Soft, Box = UDim2.fromOffset(at.Half.Wide - nx - pad, 16), Position = UDim2.fromOffset(nx, pad + 40), Parent = made }, `×{Hud.Digits(info.Held)} held`)
	local divider = pad + cellSide + 6
	local rule = Instance.new("Frame")
	rule.Name = "Divider"
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = P.Line
	rule.Position = UDim2.fromOffset(pad, divider)
	rule.Size = UDim2.fromOffset(wide, 1)
	rule.Parent = made
	local bottom = foot(made, at)
	local list = Instance.new("ScrollingFrame")
	list.Name = "Lines"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(pad, divider + 4)
	list.Size = UDim2.fromOffset(wide, math.max(bottom - divider - 8, C.Row))
	list.ScrollBarThickness = 3
	list.ScrollBarImageColor3 = P.Line
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.Parent = made
	local odds = column(list, "Odds", 0, wide)
	caption(odds, 0, wide, "What it gives")
	for index, each in info.Odds do
		local line = Instance.new("Frame")
		line.Name = each.Rarity
		line.BackgroundTransparency = 1
		line.Size = UDim2.fromOffset(wide, C.Row)
		line.LayoutOrder = index
		line.Parent = odds
		label({ Name = "Name", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Rarity[each.Rarity] or P.Ink, Parent = line }, each.Rarity)
		label({ Name = "Chance", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Ink, Align = Enum.TextXAlignment.Right, Parent = line }, Sheet.Percent(each.Chance))
	end
	label({ Name = "Room", Size = Theme.Text.Caption, Colour = P.Faint, Box = UDim2.fromOffset(wide, C.Row), Parent = odds }, `Room for {Hud.Digits(info.Room)} in the bag`).LayoutOrder = #info.Odds + 1
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
		if ring and ring:IsA("UIStroke") then
			ring.Enabled = id == chosen
		end
	end
	local data = context.View :: any
	local target: string? = nil
	local isItem = chosen ~= nil and context.View.Items[chosen :: string] ~= nil
	if isItem then
		local info = Rules.Card(data, context.Owned, chosen :: string)
		target = if info and info.Fits then info.Slot else nil
	end
	drawBelt(context, at, target)
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

-- A chip on the strip: a pill `C.Pill` tall in a tap's height, inked when chosen.
local function chip(parent: Instance, name: string, words: string, order: number, lit: boolean, taps: { [Instance]: () -> () }, onTap: () -> ()): TextButton
	local probe = label({ Name = "Probe", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Parent = parent }, words)
	local wide = math.max(math.ceil(Text.Wide(probe, words)) + Theme.Size.Pad * 2, Theme.Size.Tap)
	probe:Destroy()
	local made = Instance.new("TextButton")
	made.Name = name
	made.Text = ""
	made.AutoButtonColor = false
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.LayoutOrder = order
	made.Size = UDim2.fromOffset(wide, Theme.Size.Tap)
	made:SetAttribute("Chosen", lit)
	made.Parent = parent
	local pill = Instance.new("Frame")
	pill.Name = "Pill"
	pill.BorderSizePixel = 0
	pill.BackgroundColor3 = if lit then P.Ink else P.Top
	pill.BackgroundTransparency = if lit then 0 else 1
	pill.AnchorPoint = Vector2.new(0, 0.5)
	pill.Position = UDim2.fromScale(0, 0.5)
	pill.Size = UDim2.new(1, 0, 0, C.Pill)
	round(pill, C.Pill / 2)
	if not lit then
		edge(pill, P.Line)
	end
	pill.Parent = made
	label({ Name = "Word", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = if lit then P.Lit else P.Soft, Align = Enum.TextXAlignment.Center, Parent = pill }, words)
	made.Activated:Connect(function()
		onTap()
	end)
	taps[made] = onTap
	return made
end

local EMPTY: { [string]: { string } } = {
	All = { "No gear yet", "Shades and keepers drop it" },
	Weapons = { "No weapons yet", "Shades and keepers drop them" },
	Armour = { "No armour yet", "Shades and keepers drop it" },
	Jewellery = { "No jewellery yet", "Shades and keepers drop it" },
	Chests = { "No chests yet", "Shades drop them, and keepers" },
	Materials = { "No shards yet", "The grounds drop them" },
}

function Bag.Build(context: Context): (() -> boolean)?
	last = context
	cells = {}
	card = nil
	local at = layout(context.Room, context.Left)
	lastLayout = at
	whole = at.Whole
	local body = context.Body
	local taps = context.Taps
	-- The case: one plate of warmed porcelain behind everything the page holds.
	local case = plain("Case", body, at.Case.X, at.Case.Y, at.Case.Wide, at.Case.Tall)
	case.BackgroundTransparency = 0
	case.BackgroundColor3 = Color3.new(1, 1, 1)
	ramp(case, { P.Top, P.Foot })
	round(case, 10)
	-- The belt.
	belt = plain("Belt", body, at.Belt.X, at.Belt.Y, if whole then 14 * at.Slot + 11 * C.BeltGap + 2 * C.GroupGap + 2 * C.BeltInset else at.Belt.Wide, at.Belt.Tall)
	;(belt :: Frame):SetAttribute("Whole", whole)
	-- The strip: the six kinds, scrolling, then the sort or, in Chests, the salvage.
	local data = context.View :: any
	local rightWords: string
	local onRight: () -> ()
	if kind == "Chests" then
		local below = context.View.Settings.Salvage
		rightWords = if below == "" then "Salvage: off" else `Salvage: {below}`
		onRight = function()
			local steps = C.Salvage
			local at_ = table.find(steps, below) or 1
			local nextOne = steps[at_ % #steps + 1]
			local answer = context.Act("SetSalvage", { Below = nextOne })
			if said(CHEST_SAID, "Can't set it", answer) then
				Toast.Show(if nextOne == "" then "Salvage off: every item kept" else `{nextOne} and under turn into Credits, unless they'd raise Combat Power`, Theme.Colour.Text)
			end
		end
	else
		rightWords = `Sort: {sort}`
		onRight = function()
			local at_ = table.find(Rules.Sorts, sort) or 1
			sort = Rules.Sorts[at_ % #Rules.Sorts + 1]
			context.Rebuild()
		end
	end
	local strip = plain("Strip", body, at.Strip.X, at.Strip.Y, at.Strip.Wide, at.Strip.Tall)
	local right = chip(strip, if kind == "Chests" then "Salvage" else "Sort", rightWords, 0, false, taps, onRight)
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.fromScale(1, 0)
	local kinds = Instance.new("ScrollingFrame")
	kinds.Name = "Kinds"
	kinds.BackgroundTransparency = 1
	kinds.BorderSizePixel = 0
	kinds.Size = UDim2.new(1, -(right.Size.X.Offset + Theme.Size.Gap), 1, 0)
	kinds.ScrollBarThickness = 0
	kinds.CanvasSize = UDim2.new()
	kinds.AutomaticCanvasSize = Enum.AutomaticSize.X
	kinds.ScrollingDirection = Enum.ScrollingDirection.X
	kinds.Parent = strip
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.Padding = UDim.new(0, 4)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = kinds
	local lit: TextButton? = nil
	for index, name in Rules.Kinds do
		local made = chip(kinds, name, name, index, name == kind, taps, function()
			if kind ~= name then
				kind, chosen, group = name, nil, nil
				context.Rebuild()
			end
		end)
		lit = if name == kind then made else lit
	end
	-- The chosen kind kept in view: once the strip has its size, scrolled so its chip stands whole.
	task.defer(function()
		if lit and lit.Parent and kinds.Parent then
			local left = lit.AbsolutePosition.X - kinds.AbsolutePosition.X + kinds.CanvasPosition.X
			local scale = Layers.Scale()
			local window = kinds.AbsoluteWindowSize.X
			local wide = lit.AbsoluteSize.X
			if left + wide > kinds.CanvasPosition.X + window or left < kinds.CanvasPosition.X then
				kinds.CanvasPosition = Vector2.new(math.max(0, left + wide - window + 12 * scale), 0)
			end
		end
	end)
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
		label({ Name = "Line", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = P.Ink, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0.5, -24), Parent = empty }, words[1])
		label({ Name = "Under", Size = Theme.Text.Caption, Colour = P.Soft, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 0.5, 0), Parent = empty }, words[2])
	else
		local holder = Instance.new("Frame")
		holder.Name = "Cells"
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, -4, 0, 0)
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.LayoutOrder = 1
		holder.Parent = grid
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
	-- The Voidkin's half: its stage and figure, its name over it, its Combat Power at its feet, its totals beside it.
	local half = at.Half
	local totalsWide = math.min(C.Totals, math.floor(half.Wide * 0.42))
	local stageWide = math.max(half.Wide - totalsWide - Theme.Size.Gap, 1)
	local stageBox = { X = half.X, Y = half.Y, Wide = stageWide, Tall = half.Tall }
	context.Stage(stageBox)
	local over = plain("Over", body, stageBox.X, stageBox.Y, stageBox.Wide, stageBox.Tall)
	local save = context.Name(over, stageWide)
	local feet = plain("Feet", over, 0, stageBox.Tall - HudConfig.Voidkin.Power.Height, stageWide, HudConfig.Voidkin.Power.Height)
	context.Power(feet, stageWide)
	local block = Stats.Resolve(context.Owned, Stats.PresetOf(data, context.Owned), data)
	local sums = plain("Totals", body, half.X + stageWide + Theme.Size.Gap, half.Y + 4, totalsWide, half.Tall - 4)
	totals(sums, block, totalsWide, half.Tall - 4)
	-- The card's room over the half, clipping its slide.
	local shelf = plain("CardRoom", body, half.X, half.Y, half.Wide, half.Tall)
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
	kind, sort, chosen, group, carded = "All", "Rarity", nil, nil, nil
end

function Bag.State(): { Kind: string, Sort: string, Chosen: string?, Group: number?, Whole: boolean }
	local holder = belt
	local shown = if holder then holder:GetAttribute("Group") else nil
	return { Kind = kind, Sort = sort, Chosen = chosen, Group = if type(shown) == "number" and shown > 0 then shown else nil, Whole = whole }
end

function Bag.Choose(id: string?)
	choose(id)
end

return Bag
