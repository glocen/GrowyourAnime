--!strict
-- VoidkinScreen (client): one Voidkin at a time, a character to show off, full screen (TR17, "The director's layout",
-- 2026-11-15; docs/research/voidkin-screen.md, "DESIGN"; docs/ui.md, "The screens of the first loop", 4 and 5). In grey:
--   a thin rail down the far left under Back, every page a round button strung on a line: Overview, Bag, Kit and
--     Stars, then Forge, Jewels and War Emblems, greyed with "Soon" until they're built. The chosen one is larger and
--     lit, the light running along the line to it, and only its word shows; each opens its page in the panel on the
--     right. Seven taps are taller than the rail: it scrolls, the built pages in view;
--   its own model, live, on a stage lit by its rarity, the floor glowing its element (Figure): a drag turns it, a tap
--     plays the end of its Reveal, a flick goes to the next or the one before;
--   two columns of six gear slots either side of it, a space between each, the twelve every Voidkin shares
--     (Definitions.Gear), empty until gear is built: a tap anywhere on a column is the way to the gear page;
--   at its feet, Main Hand and Off Hand, its class's pair, one each side of Combat Power (Rules.Stats.Power; a tap
--     shows Overview, where its stats are);
--   along the top, the screen's name by the left column; over the panel the currencies, and under them Lead (or
--     Leading), the screen's one filled button, with Send to work (or Bring home) beside it (the director on the mock,
--     2026-11-15: out of the panel);
--   the panel: its name with favourite, lock and rename, and the chosen page on the save's own numbers: Overview its
--     facts and its whole stat sheet, Bag the player's whole inventory by kind (only shards exist yet);
--   the portraits of every Voidkin owned along the foot of the stage, a tap on one to switch.
-- The dock's Voidkin opens it on the lead. Every change is asked of the server through the owner's Act, and the screen is
-- rebuilt from the server's copy, the figure kept as long as it's the same Voidkin. TR15's stat board was taken out on
-- the director's word (2026-11-14, night: "Remove now, tree later").
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
local Bar = require(UI.Kit.Bar)
local Skin = require(UI.Kit.Skin)
local Figure = require(script.Figure)

local VoidkinScreen = {}

export type On = { Act: (name: string, args: any) -> { [string]: any }, Healing: () -> { [string]: number } }

local NAME = "Voidkin"
local PAGES = { "Overview", "Bag", "Kit", "Stars", "Forge", "Jewels", "War Emblems" }
local SOON: { [string]: boolean } = { Forge = true, Jewels = true, ["War Emblems"] = true } -- not built yet: greyed
local KINDS = { "Shards", "Items", "Emblems", "Jewels", "Stones" } -- the bag's tabs (docs/design.md, "The bag")
local HELD: { [string]: boolean } = { Shards = true } -- the kinds the save holds today
local ROW = Theme.Size.Tap -- a row of buttons, authored
local BAR = 28 -- the top bar's line: the screen's name, the currencies, authored
local LABEL = 20 -- a rail button's label, under its circle, authored
local MARK = 64 -- favourite, lock and rename, each, authored
local WALLET = { Credits = 116, Electricity = 152, Every = 0.5 } -- the chips' authored widths; seconds between reads
local SHOWN = { "Health", "Attack", "Defence", "Regen" } -- always in the stat sheet; a rating shows once it's above 0
local SOURCES: { [string]: string } = { Base = "Own", Stars = "Stars", Level = "Level" }

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
local page = "Overview"
local kind = "Shards" -- the bag's tab
local editing = false -- the name's row is a box to type a nickname in
local draft: string? = nil -- what's typed there, kept across a rebuild
local builtRoom = Vector2.zero -- the room it was built in
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
	local under = pad + Screen.Back.Y + gap
	local panelWide = math.clamp(config.Panel.Share * room.X, config.Panel.Least, config.Panel.Most)
	local stageX = pad + config.Rail.Width + pad
	local stageWide = math.max(room.X - pad - panelWide - gap - stageX, 1)
	local stageTall = math.max(room.Y - pad * 2 - config.Strip - gap, 1)
	local slots = config.Slots
	local slot = math.max(math.floor(math.min(slots.Size, (stageTall - 5 * slots.Gap) / 6)), 1)
	local span = math.min(stageWide, slots.Span * stageTall)
	return {
		Room = room,
		Rail = { X = pad, Y = under, Wide = config.Rail.Width, Tall = math.max(room.Y - pad - under, 1) },
		Stage = { X = stageX, Y = pad, Wide = stageWide, Tall = stageTall },
		Panel = { X = room.X - pad - panelWide, Y = pad + BAR + gap + ROW + gap, Wide = panelWide, Tall = math.max(room.Y - pad * 2 - BAR - ROW - gap * 2, 1) },
		Slot = slot,
		Hand = math.min(slots.Hand, config.Power.Height),
		Column = math.max(slot, Theme.Size.Tap),
		Group = (stageWide - span) / 2,
		Span = span,
	}
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

-- Its name and, nicknamed, its own under it; favourite, lock and rename beside them.
local function nameRow(parent: Instance, position: UDim2, size: UDim2, owned: Profile.OwnedVoidkin, on: On)
	local row = frameOf("Name", parent, position, size)
	local gap = Theme.Size.Gap
	local marks = MARK * 3 + gap * 3
	local own = Voidkin.ById[owned.Def]
	local titleLabel = text({ Name = "Title", Size = Theme.Text.Title, Font = Theme.Font.Strong, Box = UDim2.new(1, -marks, 0, 26), Parent = row, Truncate = true }, Read.VoidkinName(owned))
	local under = if owned.Nickname ~= "" and own then own.Name else Read.VoidkinLine(owned.Def, true)
	local underLabel = text({ Name = "Under", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Box = UDim2.new(1, -marks, 0, 20), Position = UDim2.fromOffset(0, 28), Parent = row, Truncate = true }, under)
	local function mark(name: string, said: string, index: number, on_: boolean, press: () -> ...any, disabled: string?)
		local button = Button.new({
			Name = name,
			Text = said,
			Size = UDim2.fromOffset(MARK, ROW),
			Position = UDim2.new(1, -(MARK + gap) * (4 - index) + gap, 0, 0),
			Parent = row,
			TextSize = Theme.Text.Caption,
			OnPress = press,
		})
		Button.Set(button, { Selected = on_, Disabled = disabled or false })
	end
	mark("Favourite", "Favourite", 1, owned.Favourite, function(): boolean
		return refused("Can't mark it", on.Act("SetMark", { Voidkin = owned.Id, Mark = "Favourite", On = not owned.Favourite }))
	end)
	mark("Lock", if owned.Locked then "Locked" else "Lock", 2, owned.Locked, function(): boolean
		return refused("Can't lock it", on.Act("SetMark", { Voidkin = owned.Id, Mark = "Locked", On = not owned.Locked }))
	end)
	if editing then
		titleLabel.Visible, underLabel.Visible = false, false
		for _, name in { "Favourite", "Lock" } do
			(row:FindFirstChild(name) :: GuiObject).Visible = false
		end
		local box = Instance.new("TextBox")
		box.Name = "NameBox"
		box.Text = draft or owned.Nickname
		box.PlaceholderText = if own then own.Name else owned.Def
		box.ClearTextOnFocus = false
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.FontFace = Theme.Font.Strong
		box.TextSize = Theme.Text.Body
		box.TextColor3 = Theme.Colour.Text
		box.PlaceholderColor3 = Theme.Colour.TextDim
		box.BackgroundColor3 = Theme.Colour.PlateHigh
		box.BorderSizePixel = 0
		box.Size = UDim2.new(1, -(MARK + gap) * 2, 0, ROW)
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
		mark("Save", "Save", 2, false, save)
		mark("Cancel", "Cancel", 3, false, function()
			editing, draft = false, nil
			rebuild()
		end)
		task.defer(function()
			if box.Parent then
				box:CaptureFocus()
			end
		end)
		return
	end
	mark("Rename", "Rename", 3, false, function()
		editing, draft = true, nil
		rebuild()
	end)
end

-- Lead (or Leading) and Send to work (or Bring home), side by side in `parent`, the top bar's line over the panel.
local function actions(parent: Instance, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	local gap = Theme.Size.Gap
	local at = Read.Role(view, owned.Id)
	local width = UDim2.new(0.5, -gap / 2, 0, ROW)
	local lead = Button.new({
		Name = "Lead",
		Text = if at == "Lead" then "Leading" else "Lead",
		Size = width,
		Parent = parent,
		Primary = at ~= "Lead",
		OnPress = function(): boolean
			return refused("Can't lead", on.Act("SetLead", { Voidkin = owned.Id }))
		end,
	})
	local function leadState()
		local now = workspace:GetServerTimeNow()
		local why = Hud.LeadReason(at, on.Healing()[owned.Id], now, player:GetAttribute("InCombat") == true)
		Button.Set(lead, { Selected = at == "Lead", Disabled = if at == "Lead" then "Leading" else why or false })
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
	local caption = text({ Name = "Caption", Size = Theme.Text.Caption, Colour = if whole then Theme.Colour.TextDim else Theme.Colour.Text, Align = align, Box = UDim2.new(1, if whole then -left else 60, 0, 16), Position = UDim2.fromOffset(if whole then left else -30, 1), Parent = press }, "Combat Power")
	caption.ZIndex = 2
	-- The digits as large as the plate holds: about 0.62 of their size each.
	local fits = math.floor((wide - left - Theme.Size.Pad) / (0.62 * math.max(#Hud.Digits(value), 1)))
	local size = math.clamp(fits, config.Least, config.Number)
	local number = text({ Name = "Number", Size = size, Font = Theme.Font.Number, Align = align, Box = UDim2.new(1, -left, 0, config.Height - 16), Position = UDim2.fromOffset(left, 16), Parent = press }, Hud.Digits(value))
	local metal = Instance.new("UIGradient")
	metal.Rotation = 90
	metal.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(176, 182, 196))
	metal.Parent = number
	if from and value > from then
		local started = os.clock()
		number.Text = Hud.Digits(from)
		local swell = Instance.new("UIScale")
		swell.Scale = 1.12
		swell.Parent = number
		TweenService:Create(swell, TweenInfo.new(config.Roll, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		table.insert(tickers, function()
			local t = math.clamp((os.clock() - started) / config.Roll, 0, 1)
			number.Text = Hud.Digits(math.floor(from + (value - from) * (1 - (1 - t) ^ 4) + 0.5))
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

-- Its whole stat sheet, each number with where it comes from, from `order` on.
local function statSheet(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, order: number)
	local block, lines = resolved(view, owned)
	local from: { [string]: { [string]: number } } = {}
	for _, each in lines do
		local source = SOURCES[each.Source] or "Gear"
		local by = from[each.Stat] or {}
		by[source] = (by[source] or 0) + each.Value
		from[each.Stat] = by
	end
	local function stat(name: string, value: number, said: string)
		order += 1
		local parts = {}
		for _, source in { "Own", "Level", "Stars", "Gear" } do
			local amount = (from[name] or {})[source]
			if amount then
				table.insert(parts, `{source} {if name == "Regen" then string.format("%.1f", amount) else Hud.Digits(amount)}`)
			end
		end
		line(scroll, order, name, said, if #parts > 0 then table.concat(parts, " · ") else nil)
	end
	for _, name in SHOWN do
		local value = (block :: any)[name] :: number
		stat(name, value, if name == "Regen" then `{string.format("%.1f", value)} a second` else Hud.Digits(value))
	end
	order += 1
	line(scroll, order, "Speed", `{block.Speed} studs a second`)
	for _, name in Stats.Names do
		local value = (block :: any)[name] :: number
		if not table.find(SHOWN, name) and name ~= "CriticalDamage" and value > 0 then
			stat(name, value, Hud.Digits(value))
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

-- The bag's kinds as tabs along `parent`'s top: the held ones to pick, the rest greyed until they're built.
local function bagTabs(parent: Instance, top: number)
	local tabs = scroller("Kinds", parent, UDim2.fromOffset(0, top), UDim2.new(1, 0, 0, ROW), true)
	tabs.ScrollBarThickness = 0
	for index, name in KINDS do
		local said = if HELD[name] then name else `{name} soon`
		local tab = Button.new({
			Name = name,
			Text = name,
			Size = UDim2.fromOffset(#said * 10 + 24, ROW),
			LayoutOrder = index,
			Parent = tabs,
			TextSize = Theme.Text.Caption,
			OnPress = function()
				kind = name
				rebuild()
			end,
		})
		Button.Set(tab, { Selected = name == kind, Disabled = if HELD[name] then false else said })
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
		local edge = Instance.new("UIStroke")
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Color = Theme.Colour.Line
		edge.Parent = cell
		cell.Parent = grid
		local mark = Instance.new("Frame")
		mark.Name = "Mark"
		mark.BorderSizePixel = 0
		mark.BackgroundColor3 = if holds then HudConfig.Card.Trim[holds.Rarity] or Theme.Colour.TextDim else Theme.Colour.TextDim
		mark.AnchorPoint = Vector2.new(0.5, 0.5)
		mark.Position = UDim2.fromScale(0.5, 0.4)
		mark.Size = UDim2.fromScale(0.34, 0.34)
		mark.Rotation = 45
		mark.Parent = cell
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

-- The menu: a thin line down the far left with a round button strung on it for each page. The chosen one is larger, its
-- ring lit, a halo round it, its word under it, and the line is lit from the top down to it: the light runs there from
-- where it stood. The others show no word; one not built yet is greyed with "Soon" under it, and a tap says so. A
-- button's tap area is the rail's width and a tap high or more, so every page is taller than the rail: it scrolls, a pad
-- wider than its buttons each side for the chosen word (the room's edge on the left, the stage's gap on the right).
local function rail(body: Instance, at: Place)
	local config = HudConfig.Voidkin.Rail
	local lit = Theme.Colour.Primary
	local pad = Theme.Size.Pad
	local middle = pad + at.Rail.Wide / 2
	local resting, picked = math.max(ROW, config.Dot + LABEL + 2), math.max(ROW, config.Chosen + LABEL + 2)
	local between = math.clamp((at.Rail.Tall - resting * (#PAGES - 1) - picked) / (#PAGES - 1), 0, config.Spread)
	local whole = resting * (#PAGES - 1) + picked + between * (#PAGES - 1)
	local holder = Instance.new("ScrollingFrame")
	holder.Name = "Rail"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Position = UDim2.fromOffset(at.Rail.X - pad, at.Rail.Y)
	holder.Size = UDim2.fromOffset(at.Rail.Wide + pad * 2, at.Rail.Tall)
	holder.CanvasSize = UDim2.fromOffset(0, whole)
	holder.ScrollBarThickness = 0
	holder.ScrollingDirection = Enum.ScrollingDirection.Y
	holder.Parent = body
	local conduit = bit(holder, "Line", UDim2.fromOffset(config.Line, whole), Theme.Colour.Line, 0, UDim2.fromOffset(middle, whole / 2))
	conduit.ZIndex = 1
	local light = Instance.new("Frame")
	light.Name = "Lit"
	light.BorderSizePixel = 0
	light.BackgroundColor3 = lit
	light.AnchorPoint = Vector2.new(0.5, 0)
	light.Position = UDim2.fromOffset(middle, 0)
	light.ZIndex = 2
	light.Parent = holder
	local y = 0
	for index, name in PAGES do
		local on_ = name == page
		local soon = SOON[name] == true
		local tall = if on_ then picked else resting
		local across = if on_ then config.Chosen else config.Dot
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
			local halo = bit(press, "Halo", UDim2.fromOffset(across + 10, across + 10), lit, 0, UDim2.fromOffset(centre, 1 + across / 2))
			halo.BackgroundTransparency = 0.78
			round(halo)
		end
		local dot = bit(press, "Dot", UDim2.fromOffset(across, across), if on_ or soon then Theme.Colour.Plate else Theme.Colour.PlateHigh, 0, UDim2.fromOffset(centre, 1 + across / 2))
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
			}, if on_ then name else "Soon")
		end
		local function onTap()
			show(name)
		end
		press.Activated:Connect(onTap)
		taps[press] = onTap
		if on_ then
			local to = y + 1 + across / 2
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

-- The currencies at the top bar's right, over the panel: Credits and the battery, read again every WALLET.Every seconds.
local function wallet(body: Instance, at: Place, view: Profile.View)
	local holder = frameOf("Wallet", body, UDim2.fromOffset(at.Panel.X, Theme.Size.Pad), UDim2.fromOffset(at.Panel.Wide, BAR))
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
		return text({ Name = "Value", Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -(30 + Theme.Size.Pad), 1, 0), Position = UDim2.fromOffset(30, 0), Parent = made }, "")
	end
	local electricity = chip("Electricity", "Bolt", WALLET.Electricity, 0)
	local credits = chip("Credits", "Coin", WALLET.Credits, WALLET.Electricity + Theme.Size.Gap)
	credits.Text = Read.Number(view.Currency.Credits)
	local readAt = -math.huge
	local function read()
		if os.clock() - readAt < WALLET.Every then
			return
		end
		readAt = os.clock()
		local base = Read.Base(view, workspace:GetServerTimeNow())
		electricity.Text = `{Read.Stored(base.Data.Base.Battery)} / {Read.Number(BaseConfig.Battery.Capacity)}`
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
		if owned.Id == chosen then
			local row = Voidkin.ById[owned.Def]
			local ring = Instance.new("UIStroke")
			ring.Name = "Chosen"
			ring.Thickness = 2
			ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ring.Color = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
			ring.Parent = press
		end
	end
end

local function build(view: Profile.View, on: On)
	lastView, lastOn = view, on
	tickers = {}
	taps = {}
	builtRoom = Layers.Get("Menus").AbsoluteSize
	local roster = Read.Roster(view)
	if chosen == nil or view.Voidkin[chosen :: string] == nil then
		local lead = view.Roles.Lead
		chosen = if lead ~= "" and view.Voidkin[lead] then lead elseif roster[1] then roster[1].Id else nil
	end
	local body = Screen.Full(NAME, "Voidkin")
	local frame = Screen.Frame(NAME) :: Frame
	local at = place(Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset))
	local owned = if chosen then view.Voidkin[chosen :: string] else nil
	-- The top bar: Back is the kit's; the screen's name by the left column, the currencies over the panel.
	text({ Name = "Screen", Size = Theme.Text.Title, Font = Theme.Font.Strong, Box = UDim2.fromOffset(96, BAR), Position = UDim2.fromOffset(at.Stage.X + at.Group + at.Slot + Theme.Size.Pad, Theme.Size.Pad), Parent = body }, "Voidkin")
	wallet(body, at, view)
	if owned == nil then
		if stage then
			stage:Destroy()
			stage = nil
		end
		text({ Name = "Empty", Size = Theme.Text.Title, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, -at.Stage.X * 2, 0, 30), Position = UDim2.new(0, at.Stage.X, 0.5, -15), Parent = body }, "No Voidkin yet · break a shard at the Breaker")
		return
	end
	rail(body, at)
	local where, size = UDim2.fromOffset(at.Stage.X, at.Stage.Y), UDim2.fromOffset(at.Stage.Wide, at.Stage.Tall)
	local on_ = stageIn(frame, where, size)
	dress(on_, owned.Def, roster, at)
	-- Over the stage, in the body: its gear round it and what stands at its feet.
	local over = frameOf("Over", body, where, size)
	gear(over, at, owned, (resolved(view, owned)))
	strip(body, at, roster, on)
	local sheet = Panel.new({ Name = "Panel", Size = UDim2.fromOffset(at.Panel.Wide, at.Panel.Tall), Position = UDim2.fromOffset(at.Panel.X, at.Panel.Y), Parent = body })
	sheet.Active = true -- a tap on the panel stays on it
	local inside = frameOf("Inside", sheet, UDim2.fromOffset(Theme.Size.Pad, Theme.Size.Pad), UDim2.new(1, -Theme.Size.Pad * 2, 1, -Theme.Size.Pad * 2))
	nameRow(inside, UDim2.new(), UDim2.new(1, 0, 0, ROW), owned, on)
	pageBody(inside, view, owned, on, ROW + Theme.Size.Gap)
	-- The top bar's second line, over the panel: a 44 pt tap is taller than the currencies' line.
	actions(frameOf("Actions", body, UDim2.fromOffset(at.Panel.X, Theme.Size.Pad + BAR + Theme.Size.Gap), UDim2.fromOffset(at.Panel.Wide, ROW)), view, owned, on)
end

rebuild = function()
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn)
	end
end

function VoidkinScreen.Open(view: Profile.View, on: On)
	if Screen.Current() ~= NAME then -- a fresh open starts on the lead's Overview, never on a choice left from before
		chosen, page, kind, slideFrom, shownPower, litTo = nil, "Overview", "Shards", 0, {}, nil
		editing, draft = false, nil
	end
	build(view, on)
end

function VoidkinScreen.Tick()
	if Screen.Current() ~= NAME then
		return
	end
	if Layers.Get("Menus").AbsoluteSize ~= builtRoom then -- the room changed
		rebuild()
		return
	end
	for _, tick in tickers do
		tick()
	end
end

-- Another Voidkin on the screen; `step` the way it was reached (1 the next, -1 the one before), for its entrance.
function VoidkinScreen.Choose(id: string, step: number?)
	if id == chosen then
		return
	end
	local view = lastView
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

-- A piece of the open screen by its name, in its body first, then its stage: for tests and takes.
function VoidkinScreen.Find(name: string): Instance?
	local frame = Screen.Frame(NAME)
	local body = if frame then frame:FindFirstChild("Body") else nil
	return if body and frame then body:FindFirstChild(name, true) or frame:FindFirstChild(name, true) else nil
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
VoidkinScreen.Kinds = KINDS
VoidkinScreen.Held = HELD

return VoidkinScreen
