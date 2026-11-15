--!strict
-- VoidkinScreen (client): one Voidkin at a time, a character to show off, full screen (TR17, "The director's layout",
-- 2026-11-15; docs/research/voidkin-screen.md, "DESIGN"; docs/ui.md, "The screens of the first loop", 4 and 5). In grey:
--   in Roblox's top bar, right of its buttons (the Screen kit's band; research's call, 2026-11-15): Back, then
--     favourite, lock and rename as small marks, each a touch or more, and at its right the currencies;
--   a thin rail down the far left, every page a round button strung on a line: Overview, Bag, Kit and Stars, then
--     Forge, Jewels and War Emblems, greyed with "Soon" until they're built. The chosen one is larger and lit, the light
--     running along the line to it, and only its word shows; each opens its page in the panel on the right. A button
--     is a touch tall and no more, so the seven stand whole wherever the room is seven touches tall; on a shorter
--     phone the rail scrolls, the built pages in view;
--   its own model, live, on a stage lit by its rarity, the floor glowing its element (Figure): a drag turns it, a tap
--     plays the end of its Reveal, a flick goes to the next or the one before. Over the stage, its name on one line with
--     its rarity in the rarity's colour, and the figure under it (research's fix 2);
--   two columns of six gear slots either side of it, a space between each, the twelve every Voidkin shares
--     (Definitions.Gear), empty until gear is built: a tap anywhere on a column is the way to the gear page;
--   at its feet, Main Hand and Off Hand, its class's pair, one each side of Combat Power (Rules.Stats.Power; a tap
--     shows Overview, where its stats are);
--   over the panel, Lead, the screen's one filled button (lit as Leading on the lead), with Send to work (or Bring
--     home) beside it: off, each keeps its name and says why under it (the director on the mock, 2026-11-15: out of
--     the panel; research's fix 3);
--   the panel: the chosen page on the save's own numbers, the bag first (the player's whole inventory by kind; only
--     shards exist yet), Overview its facts and its whole stat sheet;
--   the portraits of every Voidkin owned along the foot of the stage, a tap on one to switch.
-- The dock's Voidkin opens it on the lead. Every change is asked of the server through the owner's Act, and the screen is
-- rebuilt from the server's copy, the figure kept as long as it's the same Voidkin. Another Voidkin whose body isn't in
-- memory yet is fetched first: the one shown stays, with its panel, and both change in one beat (research's fix 1).
-- TR15's stat board was taken out on the director's word (2026-11-14, night: "Remove now, tree later").
--   VoidkinScreen.Open(view, on)   builds it; again on each change of the save
--   VoidkinScreen.Tick()           each frame: a changed room, a healing clock, the currencies
--   For tests and takes: Choose(id), Chosen(), Show(page), Tap(piece), Figure(), Find(name), Measure()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Hud = require(Shared.Rules.Hud)
local Stats = require(Shared.Rules.Stats)
local Sheet = require(Shared.Rules.Sheet)
local Growth = require(Shared.Rules.Growth)
local Collection = require(Shared.Rules.Collection)
local HudConfig = require(Shared.Config.Hud)
local BaseConfig = require(Shared.Config.Base)
local VoidkinConfig = require(Shared.Config.Voidkin)
local Voidkin = require(Shared.Definitions.Voidkin)
local Shards = require(Shared.Definitions.Shards)
local Gear = require(Shared.Definitions.Gear)
local Actions = require(Shared.Definitions.Actions)
local Passives = require(Shared.Definitions.Passives)
local UI = script.Parent
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Button = require(UI.Kit.Button)
local Text = require(UI.Kit.Text)
local Panel = require(UI.Kit.Panel)
local Portrait = require(UI.Kit.Portrait)
local Hover = require(UI.Kit.Hover)
local Bar = require(UI.Kit.Bar)
local Skin = require(UI.Kit.Skin)
local Figure = require(script.Figure)

local VoidkinScreen = {}

export type On = { Act: (name: string, args: any) -> { [string]: any }, Healing: () -> { [string]: number } }

local NAME = "Voidkin"
local PAGES = { "Overview", "Bag", "Kit", "Stars", "Forge", "Jewels", "War Emblems" }
local SOON: { [string]: boolean } = { Forge = true, Jewels = true, ["War Emblems"] = true } -- not built yet: greyed
local KINDS = { "Shards", "Gear", "Emblems", "Jewels", "Stones" } -- the bag's tabs (docs/design.md, "The bag")
-- A page's word where it isn't its name: the Bag page reads "Items" (the director, 2026-11-15), so its gear tab is "Gear".
local SAID: { [string]: string } = { Bag = "Items" }
local HELD: { [string]: boolean } = { Shards = true } -- the kinds the save holds today
local ROW = Theme.Size.Tap -- a row of buttons, authored
local BAR = 28 -- a currency's chip, in the band, authored
local TITLE = 24 -- the name's line over the stage, authored
local TAB_GAP = 2 -- between the bag's tabs, authored: five stand whole in the smallest phone's panel, each a tap wide
local TAB_LETTERS = 6 -- a bag tab is as wide as a name of at least this many letters
local LABEL = 16 -- a rail button's label, under its circle, authored
local WORD = 64 -- Save and Cancel, in the band, each, authored
local WARM = 12 -- bodies drawn ahead at the open, the roster's first; one past them is drawn when it's asked for
local SHEET_HEAD = 22 -- a stat group's caption line, the space above it included, authored
-- A stat's cell (a tap, so the kit's touch size: 44 rendered at the smallest scale), its name's line from Top and its
-- total's under it, a source's line in its tap, the tap's inset, authored.
local SHEET = { Line = Theme.Size.Tap, Top = 5, Name = 18, Value = 24, Source = 18, Pad = 8 }
local WALLET = { Icon = 30, Digit = 0.62, Every = 0.5 } -- a chip's icon room, authored; a character's share of its text size; seconds between reads

local player = Players.LocalPlayer

-- What a refused change says (TR12, Rules.Carry; Rules.Base; Rules.Collection).
local REFUSED: { [string]: string } = {
	InCombat = "Not during a fight",
	Healing = "Still healing at home",
	Leading = "The lead fights, it can't work",
	Working = "At work: bring it home first",
	NotEnough = "Not enough copies",
	MaxStars = "All seven stars",
	Filtered = "That name can't be used",
	BadName = "That name can't be used",
	TooLong = `At most {VoidkinConfig.Nickname.Max} characters`,
	FilterFailed = "Names can't be checked right now",
}

local chosen: string? = nil
local page = "Bag"
local kind = "Shards" -- the bag's tab
local editing = false -- the name's row is a box to type a nickname in
local draft: string? = nil -- what's typed there, kept across a rebuild
local builtRoom = Vector2.zero -- the room it was built in
local builtBand = Vector2.zero -- and the band
local awaited: string? = nil -- the Voidkin to show once its body is in memory
local lastView: Profile.View? = nil
local lastOn: On? = nil
local slideFrom = 0 -- where the next figure comes in from
local figure: Figure.Figure? = nil
local stage: Frame? = nil -- the figure's stage, in the screen's frame beside its body: kept across rebuilds
local litTo: number? = nil -- how far down the rail's line the light reached, authored: it runs on from there
local measured = { Height = 0, Stage = 0, Slot = 0, Power = 0 }
local tickers: { () -> () } = {}
local taps: { [Instance]: () -> () } = {} -- for tests: what a tap does; emptied at each build
local shownPower: { [string]: number } = {} -- the Combat Power last shown for each Voidkin, so a rise counts up from it
local openStat: string? = nil -- the stat whose sources a tap opened on Overview: kept across rebuilds and Voidkin
local rebuild: () -> ()

local function refused(what: string, answer: { [string]: any }): boolean
	if answer.Ok ~= true then
		local said = REFUSED[tostring(answer.Error)]
		if said == nil then
			warn(`[VoidkinScreen] {what}: an unnamed refusal, {tostring(answer.Error)}`) -- the output names it; a player never reads a code
		end
		Toast.Show(`{what}: {said or "Not now"}`, Theme.Colour.TextDim)
		return false
	end
	return true
end

local function text(props: Text.Props, said: string): TextLabel
	local label = Text.new(props)
	label.Text = said
	return label
end

local function frameOf(name: string, parent: Instance, position: UDim2, size: UDim2): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BackgroundTransparency = 1
	made.Position = position
	made.Size = size
	made.Parent = parent
	return made
end

local function list(parent: Instance, horizontal: boolean)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, Theme.Size.Gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

local function scroller(name: string, parent: Instance, position: UDim2, size: UDim2, horizontal: boolean): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = position
	scroll.Size = size
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = if horizontal then Enum.AutomaticSize.X else Enum.AutomaticSize.Y
	scroll.ScrollingDirection = if horizontal then Enum.ScrollingDirection.X else Enum.ScrollingDirection.Y
	scroll.Parent = parent
	list(scroll, horizontal)
	return scroll
end

type Box = { X: number, Y: number, Wide: number, Tall: number }

-- Where each piece stands, authored, in the room the Screen kit gives a full screen.
type Place = {
	Room: Vector2,
	Rail: Box,
	Stage: Box,
	Panel: Box,
	Slot: number, -- a slot's side
	Hand: number, -- a hand's
	Column: number, -- a column's tap width
	Group: number, -- where the left column starts in the stage
	Span: number, -- from the left column's outer edge to the right one's
}

local function place(room: Vector2): Place
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local config = HudConfig.Voidkin
	local panelWide = math.clamp(config.Panel.Share * room.X, config.Panel.Least, config.Panel.Most)
	local stageX = pad + config.Rail.Width + pad
	local stageWide = math.max(room.X - pad - panelWide - gap - stageX, 1)
	local stageTall = math.max(room.Y - pad * 2 - config.Strip - gap, 1)
	local slots = config.Slots
	local slot = math.max(math.floor(math.min(slots.Size, (stageTall - 5 * slots.Gap) / 6)), 1)
	local span = math.min(stageWide, slots.Span * stageTall)
	return {
		Room = room,
		Rail = { X = pad, Y = 0, Wide = config.Rail.Width, Tall = math.max(room.Y, 1) }, -- the room's whole height: Back stands in the band
		Stage = { X = stageX, Y = pad, Wide = stageWide, Tall = stageTall },
		Panel = { X = room.X - pad - panelWide, Y = pad + ROW + gap, Wide = panelWide, Tall = math.max(room.Y - pad * 2 - ROW - gap, 1) },
		Slot = slot,
		Hand = math.min(slots.Hand, config.Power.Height),
		Column = math.max(slot, Theme.Size.Tap),
		Group = (stageWide - span) / 2,
		Span = span,
	}
end

-- A touch target's least side at the scale drawn now, authored: Theme.Size.Touch rendered, never more than a tap.
local function touch(): number
	return math.min(math.ceil(Theme.Size.Touch / Layers.Scale()), ROW)
end

local function role(view: Profile.View, owned: Profile.OwnedVoidkin, on: On, now: number): string
	local whole = on.Healing()[owned.Id]
	if whole and whole > now then
		return `Healing at home {Hud.Clock(whole - now)}`
	end
	if player:GetAttribute("Training") == owned.Id then
		return "Training"
	end
	local at = Read.Role(view, owned.Id)
	return if at == "Lead" then "Leading" elseif at ~= "" then `At work in {string.lower(at)}` else "Resting"
end

local function resolved(view: Profile.View, owned: Profile.OwnedVoidkin): (Stats.Block, { Stats.Line })
	local data = view :: any
	return Stats.Resolve(owned, Stats.PresetOf(data, owned), data)
end

local function show(name: string)
	if SOON[name] then -- never an empty page
		Toast.Show(`{name}: soon`, Theme.Colour.TextDim)
		return
	end
	page = name
	rebuild()
end

-- The figure's stage: its backing lit from below by its rarity, kept in the screen's frame across rebuilds.
local function stageIn(frame: Frame, position: UDim2, size: UDim2): Frame
	local made = stage
	if made == nil or made.Parent ~= frame then
		if figure then
			Figure.Destroy(figure)
			figure = nil
		end
		local fresh = Instance.new("Frame")
		fresh.Name = "Stage"
		fresh.BorderSizePixel = 0
		fresh.BackgroundColor3 = Color3.new(1, 1, 1)
		fresh.ZIndex = 0
		fresh.ClipsDescendants = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
		corner.Parent = fresh
		local light = Instance.new("UIGradient")
		light.Name = "Light"
		light.Rotation = 90
		light.Parent = fresh
		local halo = Instance.new("Frame")
		halo.Name = "Halo"
		halo.BorderSizePixel = 0
		halo.AnchorPoint = Vector2.new(0.5, 0.5)
		halo.Size = UDim2.fromScale(0.55, 0.55)
		halo.ZIndex = 1
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = halo
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.Parent = halo
		halo.Parent = fresh
		fresh.Position, fresh.Size = position, size
		fresh.Parent = frame
		made = fresh
		stage = fresh
	else
		made.Position, made.Size = position, size
	end
	return made :: Frame
end

-- The stage lit for `def`, and its figure, new when it's another Voidkin's.
local function dress(on: Frame, def: string, roster: { Profile.OwnedVoidkin }, at: Place)
	local row = Voidkin.ById[def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
	local light = on:FindFirstChild("Light") :: UIGradient
	light.Color = ColorSequence.new(Theme.Colour.Backing, Theme.Colour.Backing:Lerp(trim, 0.35))
	local halo = on:FindFirstChild("Halo") :: Frame
	halo.BackgroundColor3 = trim
	halo.BackgroundTransparency = 0.82
	-- It fills the stage: its crown Figure.Top under the stage's top, its soles over the feet's row.
	local config = HudConfig.Voidkin
	local stageHeight = at.Stage.Tall
	local feet = 1 - (config.Power.Height + 2) / stageHeight
	local height = math.max(0.2, feet - config.Figure.Top / stageHeight)
	halo.Position = UDim2.fromScale(0.5, feet - height * 0.55)
	measured.Height, measured.Stage, measured.Slot = height * stageHeight / at.Room.Y, stageHeight, at.Slot
	local current = figure
	if current and current.Def == def and current.Stage == on then
		Figure.Frame(current, height, feet)
		return
	end
	if current then
		Figure.Destroy(current)
	end
	figure = Figure.new(def, on, height, feet, function(step: number)
		local index = 1
		for at, owned in roster do
			if owned.Id == chosen then
				index = at
			end
		end
		local nextOne = roster[(index - 1 + step) % #roster + 1]
		if nextOne and nextOne.Id ~= chosen then
			VoidkinScreen.Choose(nextOne.Id, step)
		end
	end)
	if figure and slideFrom ~= 0 then
		Figure.Slide(figure, slideFrom)
	end
	slideFrom = 0
end

-- Its name over the stage, between the tops of the slot columns, on one line: its rarity after it, in the rarity's
-- colour (docs/ui.md, rule 3). The name gives way first, cut with "…". Renaming, the line is a box to type in, and what
-- it returns saves it: Save and Cancel stand in the band (marks).
local function nameLine(over: Frame, at: Place, owned: Profile.OwnedVoidkin, on: On): (() -> boolean)?
	local gap = Theme.Size.Gap
	local wide = math.max(at.Span - (at.Column + gap) * 2, 1)
	local row = frameOf("Name", over, UDim2.fromOffset(at.Group + at.Column + gap, 0), UDim2.fromOffset(wide, TITLE))
	local own = Voidkin.ById[owned.Def]
	if editing then
		local box = Instance.new("TextBox")
		box.Name = "NameBox"
		box.Text = draft or owned.Nickname
		box.PlaceholderText = if own then own.Name else owned.Def
		box.ClearTextOnFocus = false
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.FontFace = Theme.Font.Strong
		box.TextSize = Text.Legible(Theme.Text.Body, Layers.Scale())
		box.TextColor3 = Theme.Colour.Text
		box.PlaceholderColor3 = Theme.Colour.TextDim
		box.BackgroundColor3 = Theme.Colour.PlateHigh
		box.BorderSizePixel = 0
		box.Size = UDim2.fromScale(1, 1)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
		corner.Parent = box
		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, Theme.Size.Pad)
		inset.Parent = box
		box.Parent = row
		local max = VoidkinConfig.Nickname.Max
		box:GetPropertyChangedSignal("Text"):Connect(function() -- never past the most, as it's typed
			local length = utf8.len(box.Text)
			if length and length > max then
				box.Text = string.sub(box.Text, 1, (utf8.offset(box.Text, max + 1) :: number) - 1)
			end
			draft = box.Text
		end)
		local function save(): boolean
			if refused("Can't name it", on.Act("SetNickname", { Voidkin = owned.Id, Name = box.Text })) then
				editing, draft = false, nil
				rebuild()
				return true
			end
			return false
		end
		box.FocusLost:Connect(function(enter: boolean)
			if enter and editing then
				save()
			end
		end)
		task.defer(function()
			if box.Parent then
				box:CaptureFocus()
			end
		end)
		return save
	end
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	local titleLabel = text({ Name = "Title", Size = Theme.Text.Title, Font = Theme.Font.Strong, Box = UDim2.fromOffset(0, TITLE), Parent = row, Truncate = true }, Read.VoidkinName(owned))
	titleLabel.AutomaticSize = Enum.AutomaticSize.X
	titleLabel.LayoutOrder = 1
	local give = Instance.new("UIFlexItem")
	give.FlexMode = Enum.UIFlexMode.Shrink
	give.Parent = titleLabel
	local rarity = if own then own.Rarity else "Common"
	local rarityLabel = text({ Name = "Rarity", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = HudConfig.Card.Trim[rarity] or Theme.Colour.TextDim, Box = UDim2.fromOffset(0, TITLE), Parent = row }, rarity)
	rarityLabel.AutomaticSize = Enum.AutomaticSize.X
	rarityLabel.LayoutOrder = 2
	return nil
end

-- Lead and Send to work (or Bring home), side by side in `parent`, the line over the panel. On the lead, Lead is lit
-- and reads "Leading"; a button that's off keeps its name and says why under it (docs/ui.md, rule 4; research's fix 3).
local function actions(parent: Instance, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	local gap = Theme.Size.Gap
	local at = Read.Role(view, owned.Id)
	local leading = at == "Lead"
	local width = UDim2.new(0.5, -gap / 2, 0, ROW)
	local lead = Button.new({
		Name = "Lead",
		Text = if leading then "Leading" else "Lead",
		Size = width,
		Parent = parent,
		Primary = not leading,
		Under = true,
		OnPress = function(): boolean?
			if leading then
				return nil -- it leads already: nothing to ask
			end
			return refused("Can't lead", on.Act("SetLead", { Voidkin = owned.Id }))
		end,
	})
	local function leadState()
		local now = workspace:GetServerTimeNow()
		local why = if leading then nil else Hud.LeadReason(at, on.Healing()[owned.Id], now, player:GetAttribute("InCombat") == true)
		Button.Set(lead, { Selected = leading, Disabled = why or false })
	end
	leadState()
	table.insert(tickers, leadState)
	local working = string.match(at, "^Bay (%d+)$")
	local why, bay = Hud.WorkReason(at, view.Base.Bays)
	local work = Button.new({
		Name = "Work",
		Text = if working then "Bring home" else "Send to work",
		Size = width,
		Position = UDim2.new(0.5, gap / 2, 0, 0),
		Parent = parent,
		Under = true,
		OnPress = function(): boolean
			if working then
				return refused("Can't bring it home", on.Act("SetWorker", { Bay = tonumber(working), Voidkin = "" }))
			end
			return refused("Can't send it", on.Act("SetWorker", { Bay = bay, Voidkin = owned.Id }))
		end,
	})
	if not working then
		Button.Set(work, { Disabled = why or false })
	end
end

-- Combat Power at its feet, the screen's showpiece (the director, 2026-11-14, night): on a plate of its rarity's light
-- that fades out at both ends, its emblem, its caption and its digits. A rise since it was last shown counts the digits
-- up from the old number and floats the gain off the plate's end. Between the hands it's `wide`: a narrow plate drops its
-- emblem and sets its digits as large as they fit. In grey: the look is Modulo's after the pick. A tap shows where it
-- comes from.
local function power(parent: Instance, owned: Profile.OwnedVoidkin, block: Stats.Block, wide: number)
	local config = HudConfig.Voidkin.Power
	local row = Voidkin.ById[owned.Def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
	local value = Stats.Power(block)
	local from = shownPower[owned.Id]
	shownPower[owned.Id] = value
	local press = Instance.new("TextButton")
	press.Name = "Power"
	press.Text = ""
	press.AutoButtonColor = false
	press.BorderSizePixel = 0
	press.BackgroundColor3 = trim
	press.AnchorPoint = Vector2.new(0.5, 1)
	press.Position = UDim2.fromScale(0.5, 1)
	press.Size = UDim2.fromOffset(wide, config.Height)
	press.Parent = parent
	local whole = wide >= config.Emblem
	local fade = Instance.new("UIGradient")
	fade.Name = "Plate"
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.22, 0.62),
		NumberSequenceKeypoint.new(0.78, 0.62),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = press
	local emblem = Instance.new("Frame")
	emblem.Name = "Emblem"
	emblem.AnchorPoint = Vector2.new(0.5, 0.5)
	emblem.Position = UDim2.new(0, 34, 0.5, 0)
	emblem.Size = UDim2.fromOffset(26, 26)
	emblem.Rotation = 45
	emblem.BorderSizePixel = 0
	emblem.BackgroundColor3 = Theme.Colour.PlateHigh
	local edge = Instance.new("UIStroke")
	edge.Color = trim
	edge.Thickness = 2
	edge.Parent = emblem
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromScale(0.42, 0.42)
	core.BorderSizePixel = 0
	core.BackgroundColor3 = trim
	core.Parent = emblem
	emblem.Visible = whole
	emblem.Parent = press
	local left = if whole then 56 else 0
	local align = if whole then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
	if not whole then -- a narrow plate stands on the floor's glow: a shade under it keeps its caption and digits read
		local shade = Instance.new("Frame")
		shade.Name = "Shade"
		shade.BorderSizePixel = 0
		shade.BackgroundColor3 = Theme.Colour.Backing
		shade.BackgroundTransparency = 0.3
		shade.Size = UDim2.fromScale(1, 1)
		shade.ZIndex = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
		corner.Parent = shade
		shade.Parent = press
	end
	-- The caption may run past a narrow plate's ends, over the hands: they stand lower than its line.
	local finish = HudConfig.Voidkin.Finish
	local caption = text({ Name = "Caption", Size = Theme.Text.Caption, Colour = finish.Caption, Align = align, Box = UDim2.new(1, if whole then -left else 60, 0, 16), Position = UDim2.fromOffset(if whole then left else -30, 1), Parent = press }, "COMBAT POWER")
	caption.ZIndex = 2
	-- The digits as large as the plate holds: about 0.62 of their size each.
	local said = Hud.Digits(value)
	local fits = math.floor((wide - left - Theme.Size.Pad) / (0.62 * math.max(#said, 1)))
	local size = math.clamp(fits, config.Least, config.Number)
	-- In cobalt (Config.Hud.Voidkin.Finish): one soft glow behind them, their drop under them, the face over it, each
	-- stroked in ink. The drop and the face sit in one frame, so a rise swells both and says the same in each.
	local drawn = math.min(0.62 * size * #said, wide - left)
	Skin.Lay(Skin.Of(press), "ButtonBaseGlow", {
		Name = "Glow",
		X = if whole then left else (wide - drawn) / 2,
		Y = 16 + (config.Height - 16 - size) / 2,
		W = drawn,
		H = size,
		Tint = finish.Glow,
		Alpha = finish.GlowAlpha,
	})
	local digits = frameOf("Digits", press, UDim2.fromOffset(left, 16), UDim2.new(1, -left, 0, config.Height - 16))
	digits.ZIndex = 2
	-- `down` points lower, as Scale of the frame's height: a UDim's Offset is a whole number, and 1.2 drew as 1.
	local function stroked(name: string, colour: Color3?, down: number): TextLabel
		local label = text({ Name = name, Size = size, Font = Theme.Font.Number, Align = align, Colour = colour, Position = UDim2.fromScale(0, down / (config.Height - 16)), Parent = digits }, said)
		local line = Instance.new("UIStroke")
		line.Color = finish.Stroke
		line.Thickness = finish.Line
		line.Parent = label
		return label
	end
	local drop = stroked("Drop", finish.Stroke, finish.Drop)
	local number = stroked("Number", Color3.new(1, 1, 1), 0) -- white under its gradient, so the stops show true
	number.ZIndex = 2
	local stops: { ColorSequenceKeypoint } = {}
	for index, at in finish.Stops do
		table.insert(stops, ColorSequenceKeypoint.new(at, finish.Colours[index]))
	end
	local metal = Instance.new("UIGradient")
	metal.Rotation = 90
	metal.Color = ColorSequence.new(stops)
	metal.Parent = number
	if from and value > from then
		local started = os.clock()
		number.Text, drop.Text = Hud.Digits(from), Hud.Digits(from)
		local swell = Instance.new("UIScale")
		swell.Scale = finish.Swell
		swell.Parent = digits
		TweenService:Create(swell, TweenInfo.new(config.Roll, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		local rolled = false
		table.insert(tickers, function()
			if rolled then
				return
			end
			local t = math.clamp((os.clock() - started) / config.Roll, 0, 1)
			rolled = t >= 1
			local eased = 1 - (1 - t) ^ 4
			local now = Hud.Digits(math.floor(from + (value - from) * eased + 0.5))
			number.Text, drop.Text = now, now
			-- Lit toward white as it rises, back to its cobalt as the roll ends.
			local lift = finish.White * (1 - eased)
			local lit: { ColorSequenceKeypoint } = {}
			for index, at in finish.Stops do
				table.insert(lit, ColorSequenceKeypoint.new(at, finish.Colours[index]:Lerp(Color3.new(1, 1, 1), lift)))
			end
			metal.Color = ColorSequence.new(lit)
		end)
		local gain = text({ Name = "Gain", Font = Theme.Font.Number, Colour = Theme.Colour.Heal, Box = UDim2.fromOffset(96, 22), Position = UDim2.new(1, 4, 0, 20), Parent = press }, `+{Hud.Digits(value - from)}`)
		local rise = TweenService:Create(gain, TweenInfo.new(config.Hold, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, 4, 0, 20 - config.Gain),
			TextTransparency = 1,
		})
		rise.Completed:Connect(function()
			gain:Destroy()
		end)
		rise:Play()
	end
	local function onTap()
		show("Overview")
	end
	press.Activated:Connect(onTap)
	taps[press] = onTap
	measured.Power = wide
end

-- One line of a page: what it is on the left, its number on the right, and under them a quieter line.
local function line(parent: Instance, order: number, left: string, right: string?, under: string?): Frame
	local item = Instance.new("Frame")
	item.Name = left
	item.BackgroundTransparency = 1
	item.LayoutOrder = order
	item.Size = UDim2.new(1, -8, 0, 0)
	item.AutomaticSize = Enum.AutomaticSize.Y
	item.Parent = parent
	text({ Name = "Left", Font = Theme.Font.Strong, Box = UDim2.new(if right then 0.6 else 1, 0, 0, 22), Parent = item, Truncate = true }, left)
	if right then
		text({ Name = "Right", Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right, Box = UDim2.new(0.4, 0, 0, 22), Position = UDim2.fromScale(0.6, 0), Parent = item }, right)
	end
	if under then
		local quiet = text({ Name = "Under", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Box = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 22), Parent = item, Wrap = true }, under)
		quiet.AutomaticSize = Enum.AutomaticSize.Y
	end
	return item
end

-- One stat's cell (docs/ui.md, "Stats, shown honestly"), two a row: each a whole tap at the kit's touch size, and the
-- sheet as dense as one-line rows. Its name over its one total; under its row, opened by a tap, where each point comes
-- from, each source's number in a column that adds to the total, then its notes, a rating's chance last. One opens at a
-- time: a tap on another moves it there, a tap on the open one closes it.
local function statCell(cells: { Frame }, pair: Frame, side: number, row: Sheet.Row): Frame
	local open = openStat == row.Stat
	local item = Instance.new("Frame")
	item.Name = row.Name
	item.BackgroundTransparency = 1
	item.Position = UDim2.fromScale(side * 0.5, 0)
	item.Size = UDim2.new(0.5, 0, 0, SHEET.Line)
	item.AutomaticSize = Enum.AutomaticSize.Y
	item.Parent = pair
	text({ Name = "Left", Size = Theme.Text.Caption, Colour = if open then Theme.Colour.Primary else Theme.Colour.TextDim, Box = UDim2.new(1, -SHEET.Pad, 0, SHEET.Name), Position = UDim2.fromOffset(0, SHEET.Top), Parent = item }, row.Name)
	text({ Name = "Right", Font = Theme.Font.Number, Box = UDim2.new(1, -SHEET.Pad, 0, SHEET.Value), Position = UDim2.fromOffset(0, SHEET.Top + SHEET.Name), Parent = item }, row.Value)
	local press = Instance.new("TextButton")
	press.Name = "Press"
	press.Text = ""
	press.AutoButtonColor = false
	press.BackgroundTransparency = 1
	press.Size = UDim2.new(1, 0, 0, SHEET.Line)
	press.ZIndex = 2
	press.Parent = item
	local tap = Instance.new("Frame")
	tap.Name = "Sources"
	tap.BorderSizePixel = 0
	tap.BackgroundColor3 = Theme.Colour.PlateHigh
	tap.Position = UDim2.new(-side, 0, 0, SHEET.Line) -- under the whole row, whichever side it opened from
	tap.Size = UDim2.fromScale(2, 0)
	tap.AutomaticSize = Enum.AutomaticSize.Y
	tap.Visible = open
	tap.Parent = item
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
	corner.Parent = tap
	local inset = Instance.new("UIPadding")
	inset.PaddingLeft, inset.PaddingRight = UDim.new(0, SHEET.Pad), UDim.new(0, SHEET.Pad)
	inset.PaddingTop, inset.PaddingBottom = UDim.new(0, SHEET.Pad / 2), UDim.new(0, SHEET.Pad / 2)
	inset.Parent = tap
	local stack = Instance.new("UIListLayout")
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Padding = UDim.new(0, 2)
	stack.Parent = tap
	for index, source in row.Sources do
		local each = frameOf(`Source{index}`, tap, UDim2.new(), UDim2.new(1, 0, 0, SHEET.Source))
		each.LayoutOrder = index
		text({ Name = "Left", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Box = UDim2.new(0.7, 0, 1, 0), Parent = each, Truncate = true }, source.Name)
		text({ Name = "Right", Size = Theme.Text.Caption, Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right, Box = UDim2.new(0.3, 0, 1, 0), Position = UDim2.fromScale(0.7, 0), Parent = each }, source.Value)
	end
	for index, note in row.Notes do
		local said = text({ Name = `Note{index}`, Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Box = UDim2.fromScale(1, 0), Parent = tap, Wrap = true }, note)
		said.AutomaticSize = Enum.AutomaticSize.Y
		said.LayoutOrder = #row.Sources + index
	end
	local function onTap()
		openStat = if openStat == row.Stat then nil else row.Stat
		for _, other in cells do
			local sources = other:FindFirstChild("Sources")
			local name = other:FindFirstChild("Left")
			if sources and sources:IsA("Frame") and name and name:IsA("TextLabel") then
				local lit = other:GetAttribute("Stat") == openStat
				sources.Visible = lit
				name.TextColor3 = if lit then Theme.Colour.Primary else Theme.Colour.TextDim
			end
		end
	end
	press.Activated:Connect(onTap)
	taps[press] = onTap
	item:SetAttribute("Stat", row.Stat)
	table.insert(cells, item)
	return item
end

-- Its whole stat sheet, from `order` on (docs/ui.md, 5, "Overview's stat sheet"): every stat in its three groups, a zero
-- as 0, each stat one total from Rules.Sheet, two a row, its sources a tap away. A group's name is a quiet caption over
-- its cells; the first one's says a stat can be tapped.
local function statSheet(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, order: number)
	local block, lines = resolved(view, owned)
	local cells: { Frame } = {}
	for index, group in Sheet.Rows(block, lines, Passives.ById[owned.Def]) do
		order += 1
		local head = Instance.new("Frame")
		head.Name = `Group{group.Name}`
		head.BackgroundTransparency = 1
		head.LayoutOrder = order
		head.Size = UDim2.new(1, -8, 0, SHEET_HEAD)
		head.Parent = scroll
		local caption = UDim2.new(1, 0, 0, Theme.Text.Caption + 4)
		local foot = UDim2.new(0, 0, 1, -(Theme.Text.Caption + 4))
		text({ Name = "Left", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim, Box = caption, Position = foot, Parent = head }, group.Name)
		if index == 1 then
			text({ Name = "Hint", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Align = Enum.TextXAlignment.Right, Box = caption, Position = foot, Parent = head }, "Tap a stat for its sources")
		end
		for at = 1, #group.Rows, 2 do
			order += 1
			local pair = Instance.new("Frame")
			pair.Name = `Pair{group.Name}{(at + 1) // 2}`
			pair.BackgroundTransparency = 1
			pair.LayoutOrder = order
			pair.Size = UDim2.new(1, -8, 0, 0)
			pair.AutomaticSize = Enum.AutomaticSize.Y
			pair.Parent = scroll
			statCell(cells, pair, 0, group.Rows[at])
			local second = group.Rows[at + 1]
			if second then
				statCell(cells, pair, 1, second)
			end
		end
	end
end

local function overview(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	line(scroll, 1, Read.VoidkinLine(owned.Def, true))
	local need = Growth.XpToNext(owned.Level)
	local xp = line(scroll, 2, `Level {owned.Level}`, nil, if need then `{Hud.Digits(owned.Xp)} of {Hud.Digits(need)} experience to the next` else "The last level")
	if need then
		local bar = Bar.new({ Name = "Xp", Size = UDim2.new(1, 0, 0, Theme.Size.Bar), Position = UDim2.fromOffset(0, 44), Parent = xp, Colour = HudConfig.Card.Xp })
		Bar.Set(bar, math.clamp(owned.Xp / need, 0, 1))
		local spacer = Instance.new("UIPadding")
		spacer.PaddingBottom = UDim.new(0, Theme.Size.Bar + 4)
		spacer.Parent = xp
	end
	statSheet(scroll, view, owned, 2) -- straight under its level: the page's reason
	local now = line(scroll, 30, "Now", nil, role(view, owned, on, workspace:GetServerTimeNow()))
	local nowLabel = now:FindFirstChild("Under") :: TextLabel
	table.insert(tickers, function()
		nowLabel.Text = role(view, owned, on, workspace:GetServerTimeNow())
	end)
	local own = Voidkin.ById[owned.Def]
	if own then -- the stage has no room for a caption: which preset its slots show, and its class's pair of hands
		line(scroll, 31, `Gear · preset {owned.Preset}`, nil, `{Gear.Kind("Main Hand", own.Class)} and {Gear.Kind("Off Hand", own.Class)} in hand · nothing worn yet`)
	end
	if owned.Nickname ~= "" then
		line(scroll, 32, "Its own name", nil, if own then own.Name else owned.Def)
	end
end

local function kitTab(scroll: ScrollingFrame, owned: Profile.OwnedVoidkin)
	local row = Voidkin.ById[owned.Def]
	if row == nil then
		return
	end
	local function said(words: string): (string, string)
		local name, rest = string.match(words, "^([^:]+): (.+)$")
		return name or words, rest or ""
	end
	local signature, what = said(row.Words.Signature)
	line(scroll, 1, `Signature · {signature}`, nil, what)
	local combo = if row.Kit then Actions.ById[row.Kit.Combo] else nil
	local hits = 0
	for _ in (if combo then combo.Hits else {}) do
		hits += 1
	end
	line(scroll, 2, "Combo", nil, if hits > 0 then `{hits} hits in a string, again and again` else "Its moves come when it's built")
	local passive, how = said(row.Words.Passive)
	local own = Passives.ById[owned.Def]
	line(scroll, 3, `Passive · {if own then own.Name else passive}`, nil, how)
end

local function starsTab(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	local row = Voidkin.ById[owned.Def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
	local pips = Instance.new("Frame")
	pips.Name = "Pips"
	pips.BackgroundTransparency = 1
	pips.LayoutOrder = 1
	pips.Size = UDim2.new(1, 0, 0, 22)
	pips.Parent = scroll
	list(pips, true)
	for index = 1, VoidkinConfig.MaxStars do
		local pip = Instance.new("Frame")
		pip.Name = `Star{index}`
		pip.LayoutOrder = index
		pip.Size = UDim2.fromOffset(20, 20)
		pip.BorderSizePixel = 0
		pip.BackgroundColor3 = if index <= owned.Stars then trim else Theme.Colour.PlateHigh
		pip.Rotation = 45
		pip.Parent = pips
	end
	local cost = Collection.NextStarCost(owned)
	line(scroll, 2, `{owned.Stars} of {VoidkinConfig.MaxStars} stars`, nil, if cost then `{owned.Copies} of {cost} copies for the next` else "Every star: a copy sells for Credits")
	if cost then
		local before = Stats.Power((resolved(view, owned)))
		local next = table.clone(owned)
		next.Stars += 1
		local now, _ = resolved(view, owned)
		local after, _ = resolved(view, next)
		local gains = {}
		for _, name in { "Health", "Attack", "Defence" } do
			local gain = (after :: any)[name] - (now :: any)[name]
			if gain > 0 then
				table.insert(gains, `+{Hud.Digits(gain)} {name}`)
			end
		end
		line(scroll, 3, "The next star", `+{Hud.Digits(Stats.Power(after) - before)}`, `{table.concat(gains, " · ")}, Combat Power on the right`)
		local take = Button.new({
			Name = "TakeStar",
			Text = "Take the star",
			Size = UDim2.new(1, -8, 0, ROW),
			LayoutOrder = 4,
			Parent = scroll,
			Primary = owned.Copies >= cost,
			OnPress = function(): boolean
				return refused("Can't take it", on.Act("SpendCopies", { Voidkin = owned.Id }))
			end,
		})
		Button.Set(take, { Disabled = if owned.Copies < cost then `{cost - owned.Copies} more copies` else false })
	end
end

-- The bag's kinds as tabs along `parent`'s top: the held ones to pick, the rest greyed with "Soon" under their name
-- until they're built. Every tab stands whole in the row, each as wide as its name's share of it and never under a
-- tap's width on the smallest phone (TR17's retake, research's fix, 2026-11-15: a scrolling row cut a tab mid-word).
local function bagTabs(parent: Instance, top: number)
	local tabs = Instance.new("Frame")
	tabs.Name = "Kinds"
	tabs.BackgroundTransparency = 1
	tabs.Position = UDim2.fromOffset(0, top)
	tabs.Size = UDim2.new(1, 0, 0, ROW)
	tabs.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, TAB_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = tabs
	local letters = 0
	for _, name in KINDS do
		letters += math.max(#name, TAB_LETTERS)
	end
	local gaps = TAB_GAP * (#KINDS - 1)
	for index, name in KINDS do
		local share = math.max(#name, TAB_LETTERS) / letters
		local tab = Button.new({
			Name = name,
			Text = name,
			Under = true,
			Size = UDim2.new(share, -math.ceil(gaps * share), 0, ROW),
			LayoutOrder = index,
			Parent = tabs,
			TextSize = Theme.Text.Caption,
			OnPress = function()
				kind = name
				rebuild()
			end,
		})
		Button.Set(tab, { Selected = name == kind, Disabled = if HELD[name] then false else "Soon" })
	end
end

-- The bag: everything owned that isn't a Voidkin, one cell a thing with its count. Shards are what the save holds yet:
-- each one's mark wears the light of the Voidkin it holds, and a tap names it.
local function bagTab(scroll: ScrollingFrame, view: Profile.View)
	local ids = {}
	local total = 0
	for id, count in view.Bag.Shards do
		if count > 0 then
			table.insert(ids, id)
			total += count
		end
	end
	table.sort(ids)
	line(scroll, 1, if total == 1 then "1 shard" else `{Hud.Digits(total)} shards`, nil, if total == 0 then "None yet · the grounds drop them, the Breaker opens them" else nil)
	if total == 0 then
		return
	end
	local grid = Instance.new("Frame")
	grid.Name = "Cells"
	grid.BackgroundTransparency = 1
	grid.LayoutOrder = 2
	grid.Size = UDim2.new(1, -8, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Parent = scroll
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(ROW, ROW)
	layout.CellPadding = UDim2.fromOffset(Theme.Size.Gap, Theme.Size.Gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for index, id in ids do
		local count = view.Bag.Shards[id]
		local row = Shards.ById[id]
		local holds = if row and row.Holds ~= "" then Voidkin.ById[row.Holds] else nil
		local cell = Instance.new("TextButton")
		cell.Name = id
		cell.Text = ""
		cell.AutoButtonColor = false
		cell.BorderSizePixel = 0
		cell.BackgroundColor3 = Theme.Colour.PlateHigh
		cell.LayoutOrder = index
		cell:SetAttribute("Count", count)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
		corner.Parent = cell
		-- Its grade's picture (AR12); a shard that holds one Voidkin wears its light on the cell's edge, as its mark did.
		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = if holds then HudConfig.Card.Trim[holds.Rarity] or Theme.Colour.Line else Theme.Colour.Line
		edge.Parent = cell
		cell.Parent = grid
		local art = HudConfig.ShardArt
		local side = ROW * art.Cell
		local picture = Skin.Icon(cell, Hud.ShardPicture(if row then row.Grade else "Standard", side, art.Large), ROW / 2, side / 2 + 2, side)
		picture.Name = "Picture"
		text({ Name = "Count", Size = Theme.Text.Caption, Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -6, 0, 20), Position = UDim2.new(0, 0, 1, -21), Parent = cell }, `×{Hud.Digits(count)}`)
		local function onTap()
			Toast.Show(`{Read.ShardName(id)} ×{Hud.Digits(count)}`, Theme.Colour.Text)
		end
		cell.Activated:Connect(onTap)
		taps[cell] = onTap
	end
end

-- The chosen page, filling `parent` from `top` down.
local function pageBody(parent: Frame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On, top: number)
	if page == "Bag" then
		bagTabs(parent, top)
		top += ROW + Theme.Size.Gap
	end
	local scroll = scroller("Page", parent, UDim2.fromOffset(0, top), UDim2.new(1, 0, 1, -top), false)
	scroll:SetAttribute("Keep", if page == "Bag" then `Bag{kind}` else `{owned.Id}{page}`)
	scroll:SetAttribute("Page", page)
	if page == "Bag" then
		bagTab(scroll, view)
	elseif page == "Kit" then
		kitTab(scroll, owned)
	elseif page == "Stars" then
		starsTab(scroll, view, owned, on)
	else
		overview(scroll, view, owned, on)
	end
end

local function bit(parent: Instance, name: string, size: UDim2, colour: Color3, rotation: number?, position: UDim2?): Frame
	local made = Instance.new("Frame")
	made.Name = name
	made.BorderSizePixel = 0
	made.BackgroundColor3 = colour
	made.AnchorPoint = Vector2.new(0.5, 0.5)
	made.Position = position or UDim2.fromScale(0.5, 0.5)
	made.Size = size
	made.Rotation = rotation or 0
	made.Parent = parent
	return made
end

local function round(on: Instance)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = on
end

-- A page's mark in its circle, in grey: a head for Overview, a pouch for the bag, a blade for Kit, a star's cut for
-- Stars, an anvil for the Forge, a pair of stones for Jewels, a shield for War Emblems. The drawn icons are Modulo's.
local function glyph(dot: Frame, name: string, colour: Color3)
	if name == "Bag" then
		bit(dot, "Flap", UDim2.fromScale(0.24, 0.1), colour, 0, UDim2.fromScale(0.5, 0.34))
		bit(dot, "Pouch", UDim2.fromScale(0.44, 0.32), colour, 0, UDim2.fromScale(0.5, 0.58))
	elseif name == "Kit" then
		bit(dot, "Blade", UDim2.fromScale(0.56, 0.1), colour, -45)
		bit(dot, "Guard", UDim2.fromScale(0.26, 0.09), colour, 45, UDim2.fromScale(0.39, 0.61))
	elseif name == "Stars" then
		bit(dot, "Cut", UDim2.fromScale(0.34, 0.34), colour, 45)
	elseif name == "Forge" then
		bit(dot, "Face", UDim2.fromScale(0.5, 0.14), colour, 0, UDim2.fromScale(0.5, 0.4))
		bit(dot, "Foot", UDim2.fromScale(0.22, 0.24), colour, 0, UDim2.fromScale(0.5, 0.58))
	elseif name == "Jewels" then
		bit(dot, "Stone1", UDim2.fromScale(0.2, 0.2), colour, 45, UDim2.fromScale(0.37, 0.5))
		bit(dot, "Stone2", UDim2.fromScale(0.2, 0.2), colour, 45, UDim2.fromScale(0.63, 0.5))
	elseif name == "War Emblems" then
		bit(dot, "Field", UDim2.fromScale(0.36, 0.26), colour, 0, UDim2.fromScale(0.5, 0.42))
		bit(dot, "Point", UDim2.fromScale(0.255, 0.255), colour, 45, UDim2.fromScale(0.5, 0.55))
	else
		round(bit(dot, "Head", UDim2.fromScale(0.26, 0.26), colour, 0, UDim2.fromScale(0.5, 0.38)))
		bit(dot, "Shoulders", UDim2.fromScale(0.44, 0.12), colour, 0, UDim2.fromScale(0.5, 0.66))
	end
end

-- A mark's sign on its button in the band, in grey: a star for favourite, a padlock, a pencil. The drawn ones are Modulo's.
local function markGlyph(on: Instance, name: string, colour: Color3)
	local holder = Instance.new("Frame")
	holder.Name = "Glyph"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(20, 20)
	holder.ZIndex = 20
	holder.Parent = on
	if name == "Favourite" then
		bit(holder, "Square", UDim2.fromScale(0.6, 0.6), colour, 0)
		bit(holder, "Cut", UDim2.fromScale(0.6, 0.6), colour, 45)
	elseif name == "Lock" then
		local shackle = bit(holder, "Shackle", UDim2.fromScale(0.46, 0.5), colour, 0, UDim2.fromScale(0.5, 0.36))
		shackle.BackgroundTransparency = 1
		round(shackle)
		local loop = Instance.new("UIStroke")
		loop.Color = colour
		loop.Thickness = 2
		loop.Parent = shackle
		bit(holder, "Body", UDim2.fromScale(0.76, 0.46), colour, 0, UDim2.fromScale(0.5, 0.72)).ZIndex = 2
	else
		bit(holder, "Shaft", UDim2.fromScale(0.74, 0.2), colour, -45, UDim2.fromScale(0.56, 0.44))
		bit(holder, "Tip", UDim2.fromScale(0.2, 0.2), colour, 0, UDim2.fromScale(0.16, 0.84))
	end
end

-- Favourite, lock and rename in the band, right of Back: small marks, each on a touch or more (research's fix 2), lit
-- while they're on. Renaming, Save (`save`) and Cancel stand there. Returns where they end, authored from the band's left.
local function marks(band: Frame, owned: Profile.OwnedVoidkin, on: On, save: (() -> boolean)?): number
	local gap = Theme.Size.Gap
	local tall = Screen.Row()
	local x = Screen.BandLeft
	local function button(name: string, said: string, wide: number, press: () -> ...any): TextButton
		local made = Button.new({
			Name = name,
			Text = said,
			Size = UDim2.fromOffset(wide, tall),
			Position = UDim2.new(0, x, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = band,
			TextSize = Theme.Text.Caption,
			OnPress = press,
		})
		x += wide + gap
		return made
	end
	if save then
		button("Save", "Save", WORD, save)
		button("Cancel", "Cancel", WORD, function()
			editing, draft = false, nil
			rebuild()
		end)
		return x - gap
	end
	local function mark(name: string, lit: boolean, press: () -> ...any)
		local made = button(name, "", touch(), press)
		Button.Set(made, { Selected = lit })
		made:SetAttribute("On", lit)
		markGlyph(made, name, if lit then Theme.Colour.Text else Theme.Colour.TextDim)
	end
	mark("Favourite", owned.Favourite, function(): boolean
		return refused("Can't mark it", on.Act("SetMark", { Voidkin = owned.Id, Mark = "Favourite", On = not owned.Favourite }))
	end)
	mark("Lock", owned.Locked, function(): boolean
		return refused("Can't lock it", on.Act("SetMark", { Voidkin = owned.Id, Mark = "Locked", On = not owned.Locked }))
	end)
	mark("Rename", false, function()
		editing, draft = true, nil
		rebuild()
	end)
	return x - gap
end

-- The menu: a thin line down the far left with a round button strung on it for each page. The chosen one is larger, its
-- ring lit, a halo round it, its word under it, and the line is lit from the top down to it: the light runs there from
-- where it stood. The others show no word; one not built yet is greyed with "Soon" under it, and a tap says so. A
-- button's tap area is the rail's width and a touch tall, more only for its word, and the gaps give way before a tap
-- does: the seven stand whole in a room seven touches tall, and in a shorter one the rail scrolls. A pad wider than its
-- buttons each side for the chosen word (the room's edge on the left, the stage's gap on the right).
local function rail(body: Instance, at: Place)
	local config = HudConfig.Voidkin.Rail
	local lit = Theme.Colour.Primary
	local pad = Theme.Size.Pad
	local middle = pad + at.Rail.Wide / 2
	local least = touch()
	local resting, worded, picked = math.max(least, config.Dot + 2), math.max(least, config.Dot + LABEL + 2), math.max(least, config.Chosen + LABEL + 2)
	local function tallOf(name: string): number
		return if name == page then picked elseif SOON[name] then worded else resting
	end
	local sum = 0
	for _, name in PAGES do
		sum += tallOf(name)
	end
	local between = math.clamp((at.Rail.Tall - sum) / (#PAGES - 1), 0, config.Spread)
	local whole = sum + between * (#PAGES - 1)
	local top = math.clamp((at.Rail.Tall - whole) / 2, 0, pad)
	local holder = Instance.new("ScrollingFrame")
	holder.Name = "Rail"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Position = UDim2.fromOffset(at.Rail.X - pad, at.Rail.Y)
	holder.Size = UDim2.fromOffset(at.Rail.Wide + pad * 2, at.Rail.Tall)
	holder.CanvasSize = UDim2.fromOffset(0, top + whole)
	holder.ScrollBarThickness = 0
	holder.ScrollingDirection = Enum.ScrollingDirection.Y
	holder.ScrollingEnabled = whole > at.Rail.Tall + 0.5
	holder:SetAttribute("Whole", whole <= at.Rail.Tall + 0.5)
	holder.Parent = body
	local conduit = bit(holder, "Line", UDim2.fromOffset(config.Line, whole), Theme.Colour.Line, 0, UDim2.fromOffset(middle, top + whole / 2))
	conduit.ZIndex = 1
	local light = Instance.new("Frame")
	light.Name = "Lit"
	light.BorderSizePixel = 0
	light.BackgroundColor3 = lit
	light.AnchorPoint = Vector2.new(0.5, 0)
	light.Position = UDim2.fromOffset(middle, top)
	light.ZIndex = 2
	light.Parent = holder
	local y = top
	for index, name in PAGES do
		local on_ = name == page
		local soon = SOON[name] == true
		local tall = tallOf(name)
		local across = if on_ then config.Chosen else config.Dot
		local centred = if on_ or soon then 1 + across / 2 else tall / 2 -- a button with no word has its circle in its middle
		local press = Instance.new("TextButton")
		press.Name = name
		press.Text = ""
		press.AutoButtonColor = false
		press.BackgroundTransparency = 1
		press.Position = UDim2.fromOffset(pad, y)
		press.Size = UDim2.fromOffset(at.Rail.Wide, tall)
		press.ZIndex = 3
		press.LayoutOrder = index
		press:SetAttribute("Chosen", on_)
		press:SetAttribute("Soon", soon)
		press.Parent = holder
		local centre = at.Rail.Wide / 2
		if on_ then
			local halo = bit(press, "Halo", UDim2.fromOffset(across + 10, across + 10), lit, 0, UDim2.fromOffset(centre, centred))
			halo.BackgroundTransparency = 0.78
			round(halo)
		end
		local dot = bit(press, "Dot", UDim2.fromOffset(across, across), if on_ or soon then Theme.Colour.Plate else Theme.Colour.PlateHigh, 0, UDim2.fromOffset(centre, centred))
		dot.ZIndex = 2
		round(dot)
		local ring = Instance.new("UIStroke")
		ring.Name = "Ring"
		ring.Thickness = if on_ then 2.5 else 1.5
		ring.Color = if on_ then lit else Theme.Colour.Line
		ring.Transparency = if soon then 0.4 else 0
		ring.Parent = dot
		glyph(dot, name, if on_ then Theme.Colour.Text elseif soon then Theme.Colour.Line else Theme.Colour.TextDim)
		if on_ or soon then
			-- The line passes behind the word, never through its letters: a cut of the cover's colour under them.
			local cut = bit(press, "Cut", UDim2.fromOffset(config.Line + 10, LABEL), Theme.Colour.Backing, 0, UDim2.fromOffset(centre, 2 + across + LABEL / 2))
			cut.ZIndex = 0
			text({
				Name = "Label",
				Size = Theme.Text.Caption,
				Font = if on_ then Theme.Font.Strong else Theme.Font.Body,
				Colour = if on_ then Theme.Colour.Text else Theme.Colour.TextDim,
				Align = Enum.TextXAlignment.Center,
				Box = UDim2.new(1, pad * 2, 0, LABEL),
				Position = UDim2.fromOffset(-pad, 2 + across),
				Parent = press,
			}, if on_ then SAID[name] or name else "Soon")
		end
		local function onTap()
			show(name)
		end
		press.Activated:Connect(onTap)
		taps[press] = onTap
		if on_ then
			local to = y - top + centred
			local from = litTo or to
			litTo = to
			light.Size = UDim2.fromOffset(config.Line, from)
			if from ~= to then
				TweenService:Create(light, TweenInfo.new(config.Run, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(config.Line, to) }):Play()
			end
		end
		y += tall + between
	end
end

-- One gear slot, empty and grey until gear is built: a read target, named by its slot. A hand's edge is brighter, and
-- it says which of its class's weapons it takes (its Kind).
local function slotAt(parent: Instance, name: string, side: number, position: UDim2, kind: string?)
	local made = Instance.new("Frame")
	made.Name = name
	made.BorderSizePixel = 0
	made.BackgroundColor3 = Theme.Colour.PlateHigh
	made.BackgroundTransparency = 0.25
	made.Position = position
	made.Size = UDim2.fromOffset(side, side)
	made:SetAttribute("Slot", name)
	made:SetAttribute("Kind", kind or name)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
	corner.Parent = made
	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.Thickness = if kind then 1.5 else 1
	edge.Color = if kind then Theme.Colour.TextDim else Theme.Colour.Line
	edge.Parent = made
	local seat = bit(made, "Seat", UDim2.fromScale(0.3, 0.3), Theme.Colour.Line, 45)
	seat.BackgroundTransparency = 0.5
	made.Parent = parent
end

-- The gear round the figure: the twelve shared slots in two columns of six, each column one tap (the way to the gear
-- page, when gear is built), and at its feet its two hands either side of Combat Power.
local function gear(over: Frame, at: Place, owned: Profile.OwnedVoidkin, block: Stats.Block)
	local config = HudConfig.Voidkin
	local slot, apart = at.Slot, config.Slots.Gap
	local tall = slot * 6 + apart * 5
	local function column(name: string, x: number, inset: number, first: number)
		local press = Instance.new("TextButton")
		press.Name = name
		press.Text = ""
		press.AutoButtonColor = false
		press.BackgroundTransparency = 1
		press.Position = UDim2.fromOffset(x, 0)
		press.Size = UDim2.fromOffset(at.Column, tall)
		press.Parent = over
		for index = 1, 6 do
			slotAt(press, Gear.Shared[first + index], slot, UDim2.fromOffset(inset, (index - 1) * (slot + apart)))
		end
		local function onTap()
			Toast.Show("Gear isn't built yet", Theme.Colour.TextDim)
		end
		press.Activated:Connect(onTap)
		taps[press] = onTap
	end
	column("LeftSlots", at.Group, 0, 0)
	column("RightSlots", at.Group + at.Span - at.Column, at.Column - slot, 6)
	local row = Voidkin.ById[owned.Def]
	local class = if row then row.Class else ""
	local gap, hand = Theme.Size.Gap, at.Hand
	local wide = math.max(at.Span - (slot + gap) * 2, 1)
	local feet = frameOf("Feet", over, UDim2.new(0, at.Group + slot + gap, 1, -config.Power.Height), UDim2.fromOffset(wide, config.Power.Height))
	slotAt(feet, "Main Hand", hand, UDim2.new(0, 0, 1, -hand), Gear.Kind("Main Hand", class))
	slotAt(feet, "Off Hand", hand, UDim2.new(1, -hand, 1, -hand), Gear.Kind("Off Hand", class))
	power(feet, owned, block, math.clamp(wide - (hand + apart) * 2, Theme.Size.Tap, config.Power.Width))
end

-- The currencies at the band's right: Credits and the battery, read again every WALLET.Every seconds. A chip is as wide
-- as its number. In a band too narrow for both whole, right of `left` (authored, from the band's left), the battery
-- shows what it holds without its capacity.
local function wallet(band: Frame, left: number, view: Profile.View)
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local size = Text.Legible(Theme.Text.Body, Layers.Scale())
	local function wideOf(said: string): number
		return WALLET.Icon + math.ceil(#said * WALLET.Digit * size) + pad
	end
	local owns = Read.Number(view.Currency.Credits)
	-- The battery in kWh (TR18), measured at its widest: a full one.
	local capacity = Read.Number(BaseConfig.Battery.Capacity)
	local fullest = `{Read.Kwh(BaseConfig.Battery.Capacity)} kWh`
	local whole = `{Read.Kwh(BaseConfig.Battery.Capacity)} / {capacity} kWh`
	local room = Layers.Band().X - pad - left - gap
	local short = wideOf(owns) + gap + wideOf(whole) > room
	local battery = wideOf(if short then fullest else whole)
	local holder = frameOf("Wallet", band, UDim2.new(1, -pad, 0.5, 0), UDim2.fromOffset(wideOf(owns) + gap + battery, BAR))
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder:SetAttribute("Short", short)
	local function chip(name: string, icon: string, wide: number, right: number): TextLabel
		local made = Instance.new("Frame")
		made.Name = name
		made.BorderSizePixel = 0
		made.BackgroundColor3 = Theme.Colour.PlateHigh
		made.BackgroundTransparency = 0.2
		made.AnchorPoint = Vector2.new(1, 0)
		made.Position = UDim2.new(1, -right, 0, 0)
		made.Size = UDim2.fromOffset(wide, BAR)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
		corner.Parent = made
		made.Parent = holder
		Skin.Icon(made, icon, 16, BAR / 2, 20)
		return text({ Name = "Value", Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -(WALLET.Icon + pad), 1, 0), Position = UDim2.fromOffset(WALLET.Icon, 0), Parent = made }, "")
	end
	local electricity = chip("Electricity", "Bolt", battery, 0)
	local credits = chip("Credits", "Coin", wideOf(owns), battery + gap)
	credits.Text = owns
	local readAt = -math.huge
	local function read()
		if os.clock() - readAt < WALLET.Every then
			return
		end
		readAt = os.clock()
		local base = Read.Base(view, workspace:GetServerTimeNow())
		local stored = Read.Kwh(base.Data.Base.Charge)
		electricity.Text = if short then `{stored} kWh` else `{stored} / {capacity} kWh`
	end
	read()
	table.insert(tickers, read)
end

local function strip(body: Instance, at: Place, roster: { Profile.OwnedVoidkin }, on: On)
	local cell = HudConfig.Voidkin.Strip
	local scroll = scroller("Strip", body, UDim2.fromOffset(at.Stage.X, at.Room.Y - Theme.Size.Pad - cell), UDim2.fromOffset(at.Stage.Wide, cell), true)
	local now = workspace:GetServerTimeNow()
	local healing = on.Healing()
	for index, owned in roster do
		local press = Button.new({
			Name = owned.Id,
			Text = "",
			Size = UDim2.fromOffset(cell, cell),
			LayoutOrder = index,
			Parent = scroll,
			OnPress = function()
				VoidkinScreen.Choose(owned.Id)
			end,
		})
		Button.Set(press, { Selected = owned.Id == chosen })
		local face = Portrait.new({ Name = "Face", Small = true, Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = press, Voidkin = owned.Def })
		Portrait.Set(face, owned.Def, (healing[owned.Id] or 0) > now)
		local row = Voidkin.ById[owned.Def]
		local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
		if owned.Id == chosen then
			local ring = Instance.new("UIStroke")
			ring.Name = "Chosen"
			ring.Thickness = 2
			ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ring.Color = trim
			ring.Parent = press
		end
		-- Hover (TR20): a card under the pointer scales to Card in its own place and its rarity's rim lifts; a pad's
		-- selection wears that rim whole. Pressed beats hover, and the chosen card, open, keeps its ring: it gets no rim,
		-- as a frame draws one stroke of its own.
		local grow = Instance.new("UIScale")
		grow.Name = "Hover"
		grow.Parent = face
		local rim: UIStroke? = nil
		if owned.Id ~= chosen then
			local made = Instance.new("UIStroke")
			made.Name = "HoverRim"
			made.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			made.Color = trim
			made.Transparency = 1
			made.Parent = press
			rim = made
		end
		Hover.On(press, function(share: number, pad: boolean)
			local state = Button.State(press)
			local k = if state == "Pressed" or state == "Waiting" or state == "Selected" then 0 else share
			local scale = 1 + (HudConfig.Motion.Hover.Card - 1) * k
			grow.Scale = scale
			Button.Grow(press, scale)
			if rim then
				rim.Thickness = HudConfig.Motion.Hover.Rim
				rim.Color = trim:Lerp(Color3.new(1, 1, 1), HudConfig.Motion.Hover.RimLight) -- its rarity at full light
				rim.Transparency = if state == "Selected" then 1 else 1 - share
			end
		end)
	end
end

local function build(view: Profile.View, on: On)
	lastView, lastOn = view, on
	tickers = {}
	taps = {}
	builtRoom = Layers.Get("Menus").AbsoluteSize
	builtBand = Layers.Band()
	local roster = Read.Roster(view)
	if chosen == nil or view.Voidkin[chosen :: string] == nil then
		local lead = view.Roles.Lead
		chosen = if lead ~= "" and view.Voidkin[lead] then lead elseif roster[1] then roster[1].Id else nil
	end
	local body = Screen.Full(NAME, "Voidkin")
	local frame = Screen.Frame(NAME) :: Frame
	local band = Screen.Band(NAME) :: Frame
	local at = place(Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset))
	local owned = if chosen then view.Voidkin[chosen :: string] else nil
	if owned == nil then
		if stage then
			stage:Destroy()
			stage = nil
		end
		wallet(band, Screen.BandLeft, view)
		text({ Name = "Empty", Size = Theme.Text.Title, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, -at.Stage.X * 2, 0, 30), Position = UDim2.new(0, at.Stage.X, 0.5, -15), Parent = body }, "No Voidkin yet · break a shard at the Breaker")
		return
	end
	rail(body, at)
	local where, size = UDim2.fromOffset(at.Stage.X, at.Stage.Y), UDim2.fromOffset(at.Stage.Wide, at.Stage.Tall)
	local on_ = stageIn(frame, where, size)
	Figure.Wings(on_)
	dress(on_, owned.Def, roster, at)
	-- Over the stage, in the body: its name, its gear round it and what stands at its feet.
	local over = frameOf("Over", body, where, size)
	gear(over, at, owned, (resolved(view, owned)))
	-- The band: Back is the kit's; its marks beside it, the currencies at the right.
	wallet(band, marks(band, owned, on, nameLine(over, at, owned, on)), view)
	strip(body, at, roster, on)
	actions(frameOf("Actions", body, UDim2.fromOffset(at.Panel.X, Theme.Size.Pad), UDim2.fromOffset(at.Panel.Wide, ROW)), view, owned, on)
	local sheet = Panel.new({ Name = "Panel", Size = UDim2.fromOffset(at.Panel.Wide, at.Panel.Tall), Position = UDim2.fromOffset(at.Panel.X, at.Panel.Y), Parent = body })
	sheet.Active = true -- a tap on the panel stays on it
	local inside = frameOf("Inside", sheet, UDim2.fromOffset(Theme.Size.Pad, Theme.Size.Pad), UDim2.new(1, -Theme.Size.Pad * 2, 1, -Theme.Size.Pad * 2))
	pageBody(inside, view, owned, on, 0)
end

rebuild = function()
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn)
	end
end

function VoidkinScreen.Open(view: Profile.View, on: On)
	local fresh = Screen.Current() ~= NAME
	if fresh then -- a fresh open starts on the lead and the bag (research's call, 2026-11-15), never on a choice left from before
		chosen, page, kind, slideFrom, shownPower, litTo, openStat = nil, "Bag", "Shards", 0, {}, nil, nil
		editing, draft, awaited = false, nil, nil
	end
	build(view, on)
	if fresh then -- the bodies it may be asked to show next, drawn ahead in the stage's wings
		local warming = 0
		for _, owned in Read.Roster(view) do
			if warming < WARM and not Figure.Ready(owned.Def) then
				warming += 1
				Figure.Warm(owned.Def)
			end
		end
	end
end

function VoidkinScreen.Tick()
	if Screen.Current() ~= NAME then
		return
	end
	if Layers.Get("Menus").AbsoluteSize ~= builtRoom or Layers.Band() ~= builtBand then -- the room changed, or the band
		rebuild()
		return
	end
	for _, tick in tickers do
		tick()
	end
end

-- A strip cell lit or back at rest, in place: a tap's answer while its Voidkin is awaited.
local function lit(id: string, on: boolean)
	local cell = VoidkinScreen.Find(id)
	if cell and cell:IsA("TextButton") then
		Button.Set(cell, { Selected = on })
	end
end

-- Another Voidkin on the screen; `step` the way it was reached (1 the next, -1 the one before), for its entrance.
function VoidkinScreen.Choose(id: string, step: number?)
	if awaited and awaited ~= id then
		lit(awaited, false)
	end
	if id == chosen then
		awaited = nil
		return
	end
	local view = lastView
	local next = if view then view.Voidkin[id] else nil
	if next and figure and not Figure.Ready(next.Def) then
		-- Never an empty stage: the one shown stays, with its panel, until the next one's body can stand whole. Its cell
		-- on the strip lights at once, so the tap is answered.
		awaited = id
		lit(id, true)
		Figure.Warm(next.Def, function()
			if awaited == id and Screen.Current() == NAME then
				VoidkinScreen.Choose(id, step)
			end
		end)
		return
	end
	awaited = nil
	if step == nil and view then
		local roster, from, to = Read.Roster(view), 0, 0
		for index, owned in roster do
			from = if owned.Id == chosen then index else from
			to = if owned.Id == id then index else to
		end
		step = if to > from then 1 else -1
	end
	slideFrom = (step or 1) * HudConfig.Voidkin.Figure.Slide
	chosen = id
	editing, draft = false, nil
	rebuild()
end

function VoidkinScreen.Chosen(): string?
	return if Screen.Current() == NAME then chosen else nil
end

function VoidkinScreen.Show(name: string)
	show(name)
end

-- For tests: a tap on a rail button, a slot column, Combat Power or a cell of the bag, as a player's finger would;
-- false if it takes none.
function VoidkinScreen.Tap(piece: Instance?): boolean
	local onTap = if piece then taps[piece] else nil
	if onTap == nil then
		return false
	end
	onTap()
	return true
end

function VoidkinScreen.Figure(): Figure.Figure?
	return if Screen.Current() == NAME then figure else nil
end

-- A piece of the open screen by its name: one of the band's own pieces first (Back, a mark, the wallet), then in its
-- body, then its stage: for tests and takes.
function VoidkinScreen.Find(name: string): Instance?
	local frame = Screen.Frame(NAME)
	local body = if frame then frame:FindFirstChild("Body") else nil
	local band = Screen.Band(NAME)
	local barred = if band then band:FindFirstChild(name) or (band.Parent :: Instance):FindFirstChild(name) else nil
	if barred and barred ~= band then
		return barred
	end
	return if body and frame then body:FindFirstChild(name, true) or frame:FindFirstChild(name, true) else nil
end

-- The Voidkin it waits to show, its body still being fetched, or nil: for tests.
function VoidkinScreen.Awaited(): string?
	return if Screen.Current() == NAME then awaited else nil
end

-- As built, authored: the figure's share of the room's height, its stage's height, a slot's side and Combat Power's
-- width: for tests and takes.
function VoidkinScreen.Measure(): { Height: number, Stage: number, Slot: number, Power: number }
	return table.clone(measured)
end

VoidkinScreen.Name = NAME
VoidkinScreen.Refused = REFUSED
VoidkinScreen.Pages = PAGES
VoidkinScreen.Soon = SOON
VoidkinScreen.Said = SAID
VoidkinScreen.Kinds = KINDS
VoidkinScreen.Held = HELD

return VoidkinScreen
