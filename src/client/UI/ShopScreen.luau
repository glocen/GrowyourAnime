--!strict
-- ShopScreen (client): the Void Shop's screen (AR38; D6's shelf, docs/decisions.md, 2026-11-18; docs/design.md, "The
-- Void Shop"; Modulo's grey sheet, research's second look of 2026-11-19, 01:14). A full screen in the seam's skin (the
-- director's 14:56: the screens keep the old look). Its band: Back, its name, the stock's clock (a light a minute, the
-- running one's falling) and the player's Credits, since the HUD's pills are covered. Its body: the featured piece apart
-- on the left, how often one comes always on it; the Standard shard's line on the right with its Drop rates (the
-- Breaker's list, Rules.Odds); under them a line says how a stock works.
-- The shelf is the server's (Net "Shop"); a buy is too (Act "ShopBuy", its owner's `on.Buy`). What a player may still
-- buy is read from their copy (Rules.Shop.Left), so it's right the moment the copy lands. Off, Buy is dimmed and the
-- count's place says why; bought out, it reads "Bought". A piece for a class the player hasn't got says so in red, and is
-- bought on a second press (research's answer to Modulo, 2026-11-19: "No Tank yet. Buy anyway?").
--   ShopScreen.Open(view, shelf, on)   opens it, or refills it in place
--   ShopScreen.Tick(): boolean         its clock; true once the stock it shows has given way
--   ShopScreen.Shelf()                 the shelf it shows, while it's open
--   ShopScreen.Find(name)              a piece of it by name, the band's included, for tests
--   ShopScreen.Rates(on?)              whether the shard's Drop rates show; sets it, for tests

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Items = require(Shared.Definitions.Items)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local Voidkin = require(Shared.Definitions.Voidkin)
local Bag = require(Shared.Rules.Bag)
local Chests = require(Shared.Rules.Chests)
local Hud = require(Shared.Rules.Hud)
local Odds = require(Shared.Rules.Odds)
local Sheet = require(Shared.Rules.Sheet)
local Shop = require(Shared.Rules.Shop)
local ShopConfig = require(Shared.Config.Shop)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local UI = script.Parent
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Panel = require(UI.Kit.Panel)
local Screen = require(UI.Kit.Screen)
local Skin = require(UI.Kit.Skin)
local Toast = require(UI.Kit.Toast)
local Seam = require(UI.VoidkinScreen.Seam)

local ShopScreen = {}

export type On = {
	Buy: (line: string, stock: number) -> { [string]: any }, -- the server's answer
	Refresh: () -> (), -- the stock turned under a press: fetch the shelf again
}

local NAME = "Shop"
local SHOP = HudConfig.Shop
local RATE_GAP = 2 -- authored pixels between the Drop rates' rows
local KEY = "_shop" -- the featured piece's id in the copy its card is read from
local RATE_INDENT = 10 -- a Voidkin's row under its rarity's, in the Drop rates, as the Breaker's
local P = {
	Text = Seam.Colour.Text,
	Soft = Seam.Colour.TextDim,
	Faint = Seam.Colour.Disabled,
	Line = Seam.Colour.Line,
	Plate = Seam.Colour.PlateHigh,
	Light = Seam.Light,
	Bad = UIKit.Bad,
	Rarity = HudConfig.Bag.Rarity,
	Rim = HudConfig.Bag.Rim,
}
-- A refusal's words, by the server's code (Rules.Shop; ShopService's "Closed"; ProfileController's "NoAnswer").
local REFUSED: { [string]: string } = {
	[Shop.Gone] = "A new stock just came in",
	[Shop.Limit] = "None left for you this stock",
	[Shop.Poor] = "Not enough Credits",
	[Shop.BagFull] = "Your Inventory is full",
	[Shop.Unknown] = "That isn't on the shelf now",
	Closed = "The Shop is closed for a moment",
	NoAnswer = "No answer: try again",
}

local lastView: Profile.View? = nil
local lastShelf: Shop.Shelf? = nil
local lastOn: On? = nil
local rates = false -- the shard's Drop rates show in place of its picture
local armedAt = 0 -- when the featured Buy asked "Buy anyway?"
local tickers: { () -> () } = {}
local builtRoom = Vector2.zero -- the room it was laid out in, authored: laid out again when the room changes

local function label(props: Text.Props, said: string): TextLabel
	local made = Text.new(props)
	made.Text = said
	return made
end

local function box(name: string, parent: Instance, position: UDim2, size: UDim2): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BackgroundTransparency = 1
	made.BorderSizePixel = 0
	made.Position = position
	made.Size = size
	made.Parent = parent
	return made
end

local function round(on: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = on
end

-- A line's hero: its picture large on its light (the bag's slot light, as its cells wear it, a size larger), in a
-- square of `side` at x, y of its panel.
local function hero(panel: Frame, x: number, y: number, side: number, image: string?, words: string, light: Color3, strength: number): Frame
	local holder = box("Hero", panel, UDim2.fromOffset(x, y), UDim2.fromOffset(side, side))
	local glow = side * SHOP.Hero.Light
	Skin.Lay(holder, "GearLight", { Name = "Light", X = (side - glow) / 2, Y = (side - glow) / 2, Scale = glow / UIKit.Images.GearLight.Points.X, Tint = light, Alpha = strength, Z = 1 })
	if image then
		local picture = Skin.Icon(holder, image, side / 2, side / 2, side, nil, 2)
		picture.Name = "Picture"
	else
		label({ Name = "Kind", Size = Theme.Text.Caption, Colour = P.Soft, Align = Enum.TextXAlignment.Center, Wrap = true, Parent = holder }, words)
	end
	return holder
end

-- A line's words: its name, what it is, then its rarity in its colour when it has one (a shard's outcome is its odds',
-- never a word under it). Centred under its hero, or at the left beside it. Their height, authored.
local function titled(parent: Instance, x: number, y: number, wide: number, centred: boolean, name: string, what: string, rarity: string?): number
	local row = SHOP.Row
	local align = if centred then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
	label({ Name = "Name", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = P.Text, Align = align, Box = UDim2.fromOffset(wide, row + 4), Position = UDim2.fromOffset(x, y), Parent = parent, Truncate = true }, name)
	label({ Name = "What", Size = Theme.Text.Caption, Colour = P.Soft, Align = align, Box = UDim2.fromOffset(wide, row), Position = UDim2.fromOffset(x, y + row + 4), Parent = parent, Truncate = true }, what)
	if rarity == nil then
		return row * 2 + 4
	end
	label({ Name = "Rarity", Size = Theme.Text.Caption, Colour = P.Rarity[rarity] or P.Soft, Align = align, Box = UDim2.fromOffset(wide, row), Position = UDim2.fromOffset(x, y + row * 2 + 4), Parent = parent }, rarity)
	return row * 3 + 4
end

-- Where a line's hero stands between `top` and `bottom` of a panel `wide` across, `words` tall under it: over its words,
-- centred, as large as the room leaves up to Hero.Most. Where that falls under Hero.Least (the smallest phone), it
-- stands at the left, as tall as the room, its words at its right.
type Place = { Side: number, X: number, Y: number, Under: boolean }
local function place(wide: number, top: number, bottom: number, words: number): Place
	local H = SHOP.Hero
	local room = bottom - top
	local under = math.floor(math.min(room - words - H.Gap, H.Most, wide - Theme.Size.Pad * 2))
	if under >= H.Least then
		return { Side = under, X = math.floor((wide - under) / 2), Y = top + math.floor((room - under - H.Gap - words) / 2), Under = true }
	end
	return { Side = math.floor(math.min(room, H.Most, wide * H.Share)), X = Theme.Size.Pad, Y = top, Under = false }
end

-- How many rows `said` takes in a wrapped label `wide` across (a margin for where the words break).
local function rows(made: TextLabel, said: string, wide: number): number
	return math.max(1, math.ceil(Text.Wide(made, said) * SHOP.Hero.Break / math.max(wide, 1)))
end

-- A panel's head: its name at the left, its note at the right.
local function head(panel: Frame, name: string, note: string)
	local pad = Theme.Size.Pad
	label({ Name = "Heading", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = P.Text, Box = UDim2.new(0.4, -pad, 0, SHOP.Head), Position = UDim2.fromOffset(pad, pad), Parent = panel }, name)
	label({ Name = "Note", Size = Theme.Text.Caption, Colour = P.Soft, Align = Enum.TextXAlignment.Right, Box = UDim2.new(0.6, -pad, 0, SHOP.Head), Position = UDim2.new(0.4, 0, 0, pad), Parent = panel, Truncate = true }, note)
end

-- The featured piece's card, read as the bag reads one, on the lead (Rules.Bag.Card), from a copy that holds it.
local function pieceCard(view: Profile.View, item: Chests.Rolled): Bag.Card?
	local copy = table.clone(view) :: any
	copy.Items = table.clone(view.Items)
	copy.Items[KEY] = { Id = KEY, Def = item.Def, Tier = item.Tier, Rarity = item.Rarity, Design = item.Design, Lines = item.Lines, Sockets = item.Sockets, Jewel = item.Jewel }
	local lead = view.Voidkin[view.Roles.Lead]
	return Bag.Card(copy, lead, KEY)
end

-- Its stats on one line, as the bag's card writes each change: "Attack +86, Health +240".
local function statsOf(card: Bag.Card): string
	local said = {}
	for _, each in card.Lines do
		table.insert(said, `{Sheet.Said[each.Stat] or each.Stat} {Sheet.Change(each.Stat, each.Value)}`)
	end
	return table.concat(said, ", ")
end

local function hasClass(view: Profile.View, class: string): boolean
	for _, owned in view.Voidkin do
		local row = Voidkin.ById[owned.Def]
		if row and row.Class == class then
			return true
		end
	end
	return false
end

-- A line's foot: its count left, or why it's off, over its Buy with the price. `missing`: the class the piece is for,
-- when the player has none of it: the first press asks, the second buys.
local function buyLine(panel: Frame, view: Profile.View, shelf: Shop.Shelf, line: Shop.Line, on: On, named: string, missing: string?, listed: boolean?)
	local pad, gap, tap, row = Theme.Size.Pad, Theme.Size.Gap, Theme.Size.Tap, SHOP.Row
	local left = Shop.Left(view :: any, shelf, line.Name)
	local short = line.Price - view.Currency.Credits
	local price = Read.Number(line.Price)
	-- Off, the count's place says why (the grey sheet's B and C), so the dimmed Buy keeps its price, or reads "Bought":
	-- a disabled button's word is its reason (Rules.Hud.Says).
	local said, colour, off = `{left} left`, P.Soft, nil :: string?
	if left <= 0 then
		said, off = "None left", "Bought"
	elseif short > 0 then
		said, colour, off = `Need {Read.Number(short)} more`, P.Bad, price
	end
	local count = label({ Name = "Count", Size = Theme.Text.Caption, Colour = colour, Box = UDim2.new(1, -pad * 2, 0, row), Position = UDim2.new(0, pad, 1, -(pad + tap + gap + row)), Parent = panel }, said)
	count.Visible = not listed -- the Drop rates' list stands in its place till it's folded: the Buy keeps its price or Bought
	local buy: TextButton
	buy = Button.new({
		Name = "Buy",
		Text = price,
		Size = UDim2.new(1, -pad * 2, 0, tap),
		Position = UDim2.new(0, pad, 1, -(pad + tap)),
		Parent = panel,
		Palette = Seam.Palette,
		OnPress = function(): boolean?
			if missing and os.clock() - armedAt > SHOP.Armed then
				armedAt = os.clock()
				local at = armedAt
				Button.Set(buy, { Text = "Buy anyway?", Selected = true, Note = `No {missing} yet` })
				task.delay(SHOP.Armed, function()
					if armedAt == at and buy.Parent then
						armedAt = 0
						Button.Set(buy, { Text = price, Selected = false, Note = false })
					end
				end)
				return nil -- asked, not answered: no tick
			end
			armedAt = 0
			local answer = on.Buy(line.Name, shelf.Stock)
			if answer.Ok ~= true then
				local code = tostring(answer.Error)
				if REFUSED[code] == nil then
					warn(`[ShopScreen] an unnamed refusal: {code}`)
				end
				Toast.Show(REFUSED[code] or "Can't buy that now", Theme.Colour.TextDim)
				if code == Shop.Gone then
					on.Refresh()
				end
				return false
			end
			Toast.Show(`{named} bought: it's in your Inventory`, Theme.Colour.Text)
			return true
		end,
	})
	buy:SetAttribute("Line", line.Name)
	buy:SetAttribute("Left", left)
	buy:SetAttribute("Price", line.Price)
	if left > 0 then
		local coin = Skin.Icon(buy, "Coin", pad + 14, tap / 2, 22, nil, 12)
		coin.Name = "Coin"
		coin.ImageTransparency = if off then SHOP.CoinOff else 0 -- dimmed with its price
	end
	if off then
		Button.Set(buy, { Disabled = off })
	end
end

-- The featured piece apart: its picture, name, slot and whom it fits, rarity, stats, then its foot. None this stock:
-- where to look for one.
local function featured(panel: Frame, wide: number, tall: number, view: Profile.View, shelf: Shop.Shelf, on: On)
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	head(panel, "Featured", `about 1 stock in {math.round(1 / ShopConfig.Featured.Chance)}`)
	local line = shelf.Lines.Featured
	local item = if line then line.Item else nil
	local row = if item then Items.ById[item.Def] else nil
	local card = if item then pieceCard(view, item) else nil
	if line == nil or item == nil or row == nil or card == nil then
		label({
			Name = "None",
			Size = Theme.Text.Caption,
			Colour = P.Soft,
			Align = Enum.TextXAlignment.Center,
			Wrap = true,
			Box = UDim2.new(1, -pad * 4, 0.6, 0),
			Position = UDim2.new(0.5, 0, 0.55, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Parent = panel,
		}, "None this stock.\nWhen one is in,\nthe Shop's crown is lit.")
		return
	end
	local tap, line_ = Theme.Size.Tap, SHOP.Row
	local missing = if row.Class and not hasClass(view, row.Class) then row.Class else nil
	local top = pad + SHOP.Head + gap
	local bottom = tall - (pad + tap + gap + line_ + gap) - (if missing then line_ else 0)
	local what = `{row.Slot}, {if row.Class then `{row.Class} only` else "any class"}`
	local said = statsOf(card)
	local stats = label({ Name = "Stats", Size = Theme.Text.Caption, Colour = P.Text, Wrap = true, Parent = panel }, said)
	local full = wide - pad * 2
	local statsTall = rows(stats, said, full) * line_
	local at = place(wide, top, bottom, line_ * 3 + 4 + SHOP.Hero.Gap + statsTall)
	if not at.Under then
		-- Beside it its three words; the stats under both, across the panel.
		at = place(wide, top, bottom - statsTall - gap, 0)
	end
	local rim = P.Rim[item.Rarity] or P.Line
	hero(panel, at.X, at.Y, at.Side, card.Image, row.Kind, rim:Lerp(Color3.new(1, 1, 1), 0.2), if item.Rarity == "Common" then 0.8 else 1)
	local statsY: number
	if at.Under then
		local y = at.Y + at.Side + SHOP.Hero.Gap
		statsY = y + titled(panel, pad, y, full, true, card.Name, what, item.Rarity) + SHOP.Hero.Gap
		stats.TextXAlignment = Enum.TextXAlignment.Center
	else
		local x = at.X + at.Side + 10
		titled(panel, x, at.Y + math.max(0, math.floor((at.Side - (line_ * 3 + 4)) / 2)), wide - x - pad, false, card.Name, what, item.Rarity)
		statsY = at.Y + at.Side + gap
	end
	stats.Size = UDim2.fromOffset(full, statsTall)
	stats.Position = UDim2.fromOffset(pad, statsY)
	if missing then
		label({ Name = "Missing", Size = Theme.Text.Caption, Colour = P.Bad, Box = UDim2.new(1, -pad * 2, 0, line_), Position = UDim2.new(0, pad, 1, -(pad + tap + gap + line_ * 2)), Parent = panel }, `You have no {missing} yet`)
	end
	buyLine(panel, view, shelf, line, on, card.Name, missing)
end

-- The Drop rates' mark: three bars left of its word (the Breaker's, AR30).
local function rateMark(button: TextButton)
	local mark = Instance.new("Frame")
	mark.Name = "Mark"
	mark.BackgroundTransparency = 1
	mark.AnchorPoint = Vector2.new(0, 0.5)
	mark.Position = UDim2.new(0, Theme.Size.Pad + 6, 0.5, 0)
	mark.Size = UDim2.fromOffset(14, 12)
	mark.ZIndex = 12
	mark.Parent = button
	for index = 0, 2 do
		local bar = Instance.new("Frame")
		bar.Name = `Bar{index + 1}`
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = P.Soft
		bar.Size = UDim2.fromOffset(14 - index * 4, 2)
		bar.Position = UDim2.fromOffset(0, index * 5)
		bar.ZIndex = 12
		bar.Parent = mark
	end
end

-- Every Voidkin the shard can give under its rarity's total, as the server will roll them (Rules.Odds.Rates, at no
-- infusion: a bought shard is whole). The rows shown add to 100%.
local function rateList(parent: Instance, def: string, position: UDim2, size: UDim2)
	local list = Instance.new("ScrollingFrame")
	list.Name = "Chances"
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Position = position
	list.Size = size
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.Parent = parent
	Panel.List(list, nil, RATE_GAP)
	local order = 0
	local function rate(name: string, who: string, parts: number, indent: number, colour: Color3, font: Font)
		order += 1
		local line = box(name, list, UDim2.new(), UDim2.new(1, -8, 0, SHOP.Row))
		line.LayoutOrder = order
		label({ Name = "Who", Size = Theme.Text.Caption, Font = font, Colour = colour, Box = UDim2.new(1, -(64 + indent), 1, 0), Position = UDim2.fromOffset(indent, 0), Parent = line, Truncate = true }, who)
		label({ Name = "Chance", Size = Theme.Text.Caption, Font = font, Colour = colour, Align = Enum.TextXAlignment.Right, Box = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -60, 0, 0), Parent = line }, Odds.Percent(parts))
	end
	for _, group in Odds.Rates(def, 0) do
		rate(`Tier{group.Rarity}`, group.Rarity, group.Parts, 0, P.Rarity[group.Rarity] or P.Text, Theme.Font.Number)
		for _, each in group.Rates do
			local row = Voidkin.ById[each.Id]
			rate(each.Id, if row then row.Name else each.Id, each.Parts, RATE_INDENT, P.Text, Theme.Font.Body)
		end
	end
end

-- The Standard shard's line: its picture, name, whom it draws from, a Drop rates row of its own, then its foot.
local function shards(panel: Frame, wide: number, tall: number, view: Profile.View, shelf: Shop.Shelf, on: On)
	local pad, gap, tap = Theme.Size.Pad, Theme.Size.Gap, Theme.Size.Tap
	head(panel, "Shards", `{ShopConfig.Shard.Limit} each player, each stock`)
	local line = shelf.Lines.Shard
	local def = if line then line.Shard else nil
	local row = if def then Shards.ById[def] else nil
	if line == nil or def == nil or row == nil then
		return
	end
	local ground = Grounds.ById[row.Ground]
	local named = `{row.Grade} shard`
	local y = pad + SHOP.Head + gap
	if not rates then
		-- Its hero over its words, between the head and the Drop rates' row.
		local bottom = tall - (pad + tap + gap + SHOP.Row + gap) - (tap + gap)
		local words = SHOP.Row * 2 + 4
		local at = place(wide, y, bottom, words)
		local art = HudConfig.ShardArt
		local from = `a Voidkin of {if ground then ground.Name else row.Ground}`
		hero(panel, at.X, at.Y, at.Side, Hud.ShardPicture(row.Grade, at.Side, art.Large), named, Seam.Light, SHOP.Hero.Shard)
		if at.Under then
			titled(panel, pad, at.Y + at.Side + SHOP.Hero.Gap, wide - pad * 2, true, named, from, nil)
		else
			local x = at.X + at.Side + 10
			titled(panel, x, at.Y + math.max(0, math.floor((at.Side - words) / 2)), wide - x - pad, false, named, from, nil)
		end
		y = bottom + gap
	end
	local fold = Button.new({
		Name = "Rates",
		Text = "Drop rates",
		TextSize = Theme.Text.Caption,
		Quiet = true,
		Inset = 10,
		Size = UDim2.new(1, -pad * 2, 0, tap),
		Position = UDim2.fromOffset(pad, y),
		Parent = panel,
		Palette = Seam.Palette,
		OnPress = function()
			ShopScreen.Rates(not rates)
			return true
		end,
	})
	Button.Set(fold, { Selected = rates })
	rateMark(fold)
	if rates then
		-- Clear of the lit button's glow, down to the Buy (the count's place), and as tall as whole rows, so no row is
		-- cut through its words.
		local top = y + tap + HudConfig.Make.Glass.Reach
		local foot = pad + tap + gap
		local step = SHOP.Row + RATE_GAP
		local rows = math.max(1, math.floor((tall - top - foot + RATE_GAP) / step))
		rateList(panel, def, UDim2.fromOffset(pad, top), UDim2.new(1, -pad * 2, 0, rows * step - RATE_GAP))
	end
	buyLine(panel, view, shelf, line, on, named, nil, rates)
end

-- The band's clock: a light a minute of the stock, the spent ones dark at the left, the running one falling as its
-- seconds go (the building's clock, AR38), then "Next stock" over its time.
local function clock(band: Frame, x: number, shelf: Shop.Shelf): number
	local look = SHOP.Clock
	local count = math.max(1, math.ceil(ShopConfig.Period / 60))
	local lights = count * look.Wide + (count - 1) * look.Gap
	local holder = box("Clock", band, UDim2.new(0, x, 0.5, 0), UDim2.fromOffset(lights + Theme.Size.Pad + look.Words, look.Tall + 12))
	holder.AnchorPoint = Vector2.new(0, 0.5)
	local fills: { Frame } = {}
	for index = 1, count do
		local track = box(`Light{index}`, holder, UDim2.new(0, (index - 1) * (look.Wide + look.Gap), 0.5, 0), UDim2.fromOffset(look.Wide, look.Tall))
		track.AnchorPoint = Vector2.new(0, 0.5)
		track.BackgroundTransparency = look.Track
		track.BackgroundColor3 = P.Faint
		local fill = box("Fill", track, UDim2.fromScale(0, 1), UDim2.fromScale(1, 1))
		fill.AnchorPoint = Vector2.new(0, 1)
		fill.BackgroundTransparency = 0
		fill.BackgroundColor3 = P.Text
		fills[index] = fill
	end
	local words = lights + Theme.Size.Pad
	local half = (look.Tall + 12) / 2
	label({ Name = "Next", Size = Theme.Text.Caption, Colour = P.Soft, Box = UDim2.fromOffset(look.Words, half), Position = UDim2.fromOffset(words, 0), Parent = holder }, "Next stock")
	local time = label({ Name = "Time", Size = Theme.Text.Caption, Font = Theme.Font.Number, Colour = P.Text, Box = UDim2.fromOffset(look.Words, half), Position = UDim2.fromOffset(words, half), Parent = holder }, "")
	local function tick()
		local left = math.max(0, shelf.Ends - workspace:GetServerTimeNow())
		time.Text = Hud.Clock(left)
		for index, fill in fills do
			local minute = count - index -- 0 is the last minute's light, at the right
			local share = math.clamp((left - minute * 60) / 60, 0, 1)
			fill.Size = UDim2.fromScale(1, share)
			fill.Visible = share > 0
		end
		holder:SetAttribute("Left", left)
	end
	tick()
	table.insert(tickers, tick)
	return x + holder.Size.X.Offset
end

-- The player's Credits at the band's right, as wide as their number.
local function credits(band: Frame, view: Profile.View)
	local pad = Theme.Size.Pad
	local tall = Screen.Row()
	local said = Read.Number(view.Currency.Credits)
	local made = box("Credits", band, UDim2.new(1, -pad, 0.5, 0), UDim2.fromOffset(100, tall))
	made.AnchorPoint = Vector2.new(1, 0.5)
	made.BackgroundTransparency = 0.2
	made.BackgroundColor3 = P.Plate
	round(made, Theme.Size.Corner)
	Skin.Icon(made, "Coin", 16, tall / 2, 20)
	local value = label({ Name = "Value", Font = Theme.Font.Number, Colour = P.Text, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -(30 + pad), 1, 0), Position = UDim2.fromOffset(30, 0), Parent = made }, said)
	made.Size = UDim2.fromOffset(30 + math.ceil(Text.Wide(value, said)) + pad, tall)
end

local function build(view: Profile.View, shelf: Shop.Shelf, on: On)
	tickers = {}
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local body = Screen.Full(NAME, "Void Shop", Seam.Palette)
	local band = Screen.Band(NAME)
	if band then
		local title = label({ Name = "ShopName", Size = Theme.Text.Body, Font = Theme.Font.Strong, Colour = P.Text, Box = UDim2.fromOffset(1, Screen.Row()), Position = UDim2.new(0, Screen.BandLeft + pad, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = band }, "Void Shop")
		local wide = math.ceil(Text.Wide(title, "Void Shop"))
		title.Size = UDim2.fromOffset(wide, Screen.Row())
		clock(band, Screen.BandLeft + pad + wide + pad * 3, shelf)
		credits(band, view)
	end
	-- The shelf and its foot as one block, as large as the room allows up to SHOP.Most, in the room's middle: the grey
	-- sheet's phone fills it; a wide screen keeps the lines' words near their Buys.
	local frame = Screen.Frame(NAME) :: Frame
	local room = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
	builtRoom = room
	Seam.Case(body, "Room", pad, 0, room.X - pad * 2, room.Y - pad).ZIndex = 0 -- the bag's room, under the lines
	local wide = math.min(room.X - pad * 4, SHOP.Most.X)
	local tall = math.min(room.Y - pad * 3 - gap - SHOP.Row, SHOP.Most.Y)
	local top = math.max(pad, math.floor((room.Y - tall - gap - SHOP.Row) / 2))
	local shelfBox = box("Lines", body, UDim2.new(0.5, 0, 0, top), UDim2.fromOffset(wide, tall))
	shelfBox.AnchorPoint = Vector2.new(0.5, 0)
	local left = Panel.new({ Name = "Featured", Size = UDim2.new(0.5, -gap / 2, 1, 0), Parent = shelfBox, Palette = Seam.Palette })
	local right = Panel.new({ Name = "Shards", Size = UDim2.new(0.5, -gap / 2, 1, 0), Position = UDim2.new(0.5, gap / 2, 0, 0), Parent = shelfBox, Palette = Seam.Palette })
	local half = math.floor((wide - gap) / 2)
	featured(left, half, tall, view, shelf, on)
	shards(right, half, tall, view, shelf, on)
	local minutes = ShopConfig.Period / 60
	label({
		Name = "Foot",
		Size = Theme.Text.Caption,
		Colour = P.Soft,
		Box = UDim2.fromOffset(wide, SHOP.Row),
		Position = UDim2.new(0.5, 0, 0, top + tall + gap),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = body,
		Truncate = true,
	}, `A new stock every {if minutes == math.floor(minutes) then tostring(minutes) else string.format("%.1f", minutes)} minutes, in every server. Your counts are your own.`)
	body:SetAttribute("Stock", shelf.Stock)
	body:SetAttribute("Featured", shelf.Featured)
end

function ShopScreen.Open(view: Profile.View, shelf: Shop.Shelf, on: On)
	local again = Screen.Current() == NAME
	if not again or (lastShelf and lastShelf.Stock ~= shelf.Stock) then
		armedAt = 0
	end
	if not again then
		rates = false
	end
	lastView, lastShelf, lastOn = view, shelf, on
	build(view, shelf, on)
end

function ShopScreen.Tick(): boolean
	if Screen.Current() ~= NAME then
		return false
	end
	local frame = Screen.Frame(NAME)
	local view, shown, act = lastView, lastShelf, lastOn
	if frame and view and shown and act and Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset) ~= builtRoom then
		build(view, shown, act) -- the room changed (a turned phone, a resized window)
	end
	for _, tick in tickers do
		tick()
	end
	local shelf = lastShelf
	return shelf ~= nil and workspace:GetServerTimeNow() >= shelf.Ends
end

function ShopScreen.Shelf(): Shop.Shelf?
	return if Screen.Current() == NAME then lastShelf else nil
end

function ShopScreen.Rates(on: boolean?): boolean
	if on ~= nil and on ~= rates then
		rates = on
		local view, shelf, act = lastView, lastShelf, lastOn
		if Screen.Current() == NAME and view and shelf and act then
			build(view, shelf, act)
		end
	end
	return rates
end

function ShopScreen.Find(name: string): Instance?
	local frame, band = Screen.Frame(NAME), Screen.Band(NAME)
	local found = if frame then frame:FindFirstChild(name, true) else nil
	if found == nil and band then
		found = band:FindFirstChild(name, true)
	end
	return found
end

ShopScreen.Name = NAME
ShopScreen.Refused = REFUSED

return ShopScreen
