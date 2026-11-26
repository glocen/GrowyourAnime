--!strict
-- VoidkinScreen (client): one Voidkin at a time, a character to show off, full screen (TR17, "The director's layout",
-- 2026-11-15; docs/research/voidkin-screen.md, "DESIGN"; docs/ui.md, "The screens of the first loop", 4 and 5). In grey:
--   in Roblox's top bar, right of its buttons (the Screen kit's band; research's call, 2026-11-15), AR29's B, the
--     seam (the director's pick, 2026-11-17): Back with no plate, its chevron and word over a line of light; then
--     favourite, lock and rename in one cut channel of three cells, each a touch or more; at its right the currencies;
--   after the channel, the page's name; down the room's left, the rail of its four pages, the Equipment screen's
--     (AR49, research's call, 2026-11-20; UI.Kit.Rail), the page shown lit; Home's Voidkin card opens the page last shown;
--   its own model, live, on a stage lit by its rarity, the floor glowing its element (Figure): a drag turns it, a tap
--     plays the end of its Reveal, a flick goes to the next or the one before. Over the stage, its name on one line with
--     its rarity in the rarity's colour, and the figure under it (research's fix 2);
--   no gear slots round it (the director, 2026-11-17: "overview ui shouldn't show any gears slot"; gear is the Items
--     page's);
--   at its feet, Combat Power (Rules.Stats.Power; a tap shows Overview, where its stats are);
--   over the panel, Lead, the screen's one filled button (lit as Leading on the lead), with Send to work (or Bring
--     home) beside it: off, each keeps its name and says why under it (the director on the mock, 2026-11-15: out of
--     the panel; research's fix 3);
--   the panel: the chosen page on the save's own numbers, the bag first (the player's whole inventory by kind; only
--     shards exist yet), Overview its facts and its whole stat sheet, a plain list where nothing opens;
--   the portraits of every Voidkin owned along the foot of the stage, a tap on one to switch.
-- Home's tiles open it on the lead. Every change is asked of the server through the owner's Act, and the screen is
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
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Exist = require(Shared.Rules.Exist)
local ExistConfig = require(Shared.Config.Exist)
local UIKit = require(Shared.Config.UIKit)
local VoidkinConfig = require(Shared.Config.Voidkin)
-- The stars at the top, as a word ("All seven stars"), for the line a copy sells on (TR61).
local ALL_STARS = ({ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" })[VoidkinConfig.MaxStars] or tostring(VoidkinConfig.MaxStars)
local Voidkin = require(Shared.Definitions.Voidkin)
local Gear = require(Shared.Definitions.Gear)
local Actions = require(Shared.Definitions.Actions)
local Passives = require(Shared.Definitions.Passives)
local UI = script.Parent
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Refuse = require(UI.Kit.Refuse)
local Button = require(UI.Kit.Button)
local Text = require(UI.Kit.Text)
local Glass = require(UI.Kit.Glass)
local Portrait = require(UI.Kit.Portrait)
local Hover = require(UI.Kit.Hover)
local Bar = require(UI.Kit.Bar)
local Skin = require(UI.Kit.Skin)
local Figure = require(script.Figure)
local Seam = require(script.Seam)
local Look = Seam.Colour -- the seam's colours under the theme's names (TR28): one palette across the tabs
local BagPage = require(script.Bag)
local Rail = require(script.Parent.Kit.Rail)
local BagRules = require(Shared.Rules.Bag)

local VoidkinScreen = {}

-- `Page`: the page a fresh open shows, the Items page when none is named ("Send another" asks for Overview, where Lead is).
-- `Said`: its name in the band where it isn't the page's own word (SAID).
export type On = { Act: (name: string, args: any) -> { [string]: any }, Healing: () -> { [string]: number }, Page: string?, Said: string? }

local NAME = "Voidkin"
local PAGES = { "Overview", "Bag", "Kit", "Stars", "Forge", "Jewels", "War Emblems" }
local SOON: { [string]: boolean } = { Forge = true, Jewels = true, ["War Emblems"] = true } -- not built yet: greyed
-- A page's word where it isn't its name: the Bag page reads "Inventory", as Home's tile does (the director's 03:37,
-- "inventory with the gears slot", in place of 2026-11-15's "Items"; research's call, AR43, 2026-11-19). Its kinds are
-- Rules.Bag's (TR28, AR18's A).
local SAID: { [string]: string } = { Bag = "Inventory" }
local ROW = Theme.Size.Tap -- a row of buttons, authored
local BAR = 28 -- a currency's chip, in the band, authored
local TITLE = 24 -- the name's line over the stage, authored
local WORD = 64 -- Save and Cancel, in the band, each, authored
local WARM = 12 -- bodies drawn ahead at the open, the roster's first; one past them is drawn when it's asked for
local SHEET_HEAD = 22 -- a stat group's caption line, the space above it included, authored
-- A heading over the sheet's blocks (Basic Attributes, Battle Attributes), the space above it included, and its caption's
-- line under it, authored.
local SHEET_HEADING = { Line = 34, Caption = 18 }
-- A stat's cell (a tap, so the kit's touch size: 44 rendered at the smallest scale), its name's line from Top and its
-- total's under it, the tap's inset, authored.
-- A total's quiet line under it (HP Regen's "every 8 s", 4.6) adds its own height to its pair.
local SHEET = { Line = Theme.Size.Tap, Top = 5, Name = 18, Value = 24, Pad = 8, Under = 16 }
local sheetWide = 0 -- the Overview's row, authored: the panel's inside less the list's inset, set at each build
local WALLET = { Icon = 30, Digit = 0.62, Every = 0.5 } -- a chip's icon room, authored; a character's share of its text size; seconds between reads

local player = Players.LocalPlayer

local chosen: string? = nil
local page = "Bag"
local railShown: string? = nil -- the page the rail lit at the last build, so a switch grows from it
local named: string? = nil -- the page's name in the band
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
local measured = { Height = 0, Stage = 0, Power = 0 }
local tickers: { () -> () } = {}
local taps: { [Instance]: () -> () } = {} -- for tests: what a tap does; emptied at each build
local shownPower: { [string]: number } = {} -- the Combat Power last shown for each Voidkin, so a rise counts up from it
local rebuild: () -> ()

-- A change's answer: true when it went through; a refusal says its fix in grey (Config.Refusals' Voidkin; TR71 B), and
-- `what` names the press in the output only.
local function refused(what: string, answer: { [string]: any }): boolean
	if answer.Ok ~= true then
		Refuse.Show("Voidkin", answer, nil, `VoidkinScreen {what}`)
		return false
	end
	return true
end

local function text(props: Text.Props, said: string): TextLabel
	props.Colour = props.Colour or Look.Text
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
	Rail: Box, -- the page rail's column (AR49)
	Stage: Box,
	Panel: Box,
	Group: number, -- where the name's line and the feet's row start in the stage
	Span: number, -- how wide they stand
}

local function place(room: Vector2): Place
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local config = HudConfig.Voidkin
	local panelWide = math.clamp(config.Panel.Share * room.X, config.Panel.Least, config.Panel.Most)
	local stageX = pad + config.Rail.Width + pad
	local stageWide = math.max(room.X - pad - panelWide - gap - stageX, 1)
	local stageTall = math.max(room.Y - pad * 2 - config.Strip - gap, 1)
	local span = math.min(stageWide, config.Span * stageTall)
	return {
		Room = room,
		Rail = { X = pad, Y = 0, Wide = config.Rail.Width, Tall = math.max(room.Y, 1) },
		Stage = { X = stageX, Y = pad, Wide = stageWide, Tall = stageTall },
		Panel = { X = room.X - pad - panelWide, Y = pad + ROW + gap, Wide = panelWide, Tall = math.max(room.Y - pad * 2 - ROW - gap, 1) },
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
		return `Healing at base {Hud.Clock(whole - now)}`
	end
	if player:GetAttribute("Training") == owned.Id then
		return "Training"
	end
	local at = Read.Role(view, owned.Id)
	return if at == "Lead" then "Leading" elseif at ~= "" then `Working in {at}` else "Resting"
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
	named = SAID[name] or name
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
		-- The seam's shaft: a soft column of its light behind the figure, cut at the stage (Modulo's sheet, AR18).
		local shaft = HudConfig.Seam.Shaft
		local column = Instance.new("Frame")
		column.Name = "Shaft"
		column.Active = false
		column.BorderSizePixel = 0
		column.BackgroundColor3 = Seam.Light
		column.AnchorPoint = Vector2.new(0.5, 0)
		column.Position = UDim2.fromScale(0.5, 0)
		column.Size = UDim2.new(0, shaft.Half * 6, 1, 0)
		column.ZIndex = 1
		local points = {}
		for i = 0, 12 do
			local v = i / 12
			table.insert(points, NumberSequenceKeypoint.new(v, 1 - shaft.Alpha * math.exp(-((v - 0.5) * 6) ^ 2)))
		end
		local falloff = Instance.new("UIGradient")
		falloff.Transparency = NumberSequence.new(points)
		falloff.Parent = column
		column.Parent = fresh
		fresh.Position, fresh.Size = position, size
		fresh.Parent = frame
		made = fresh
		stage = fresh
	else
		made.Position, made.Size = position, size
	end
	return made :: Frame
end

-- The stage lit for `def`, and its figure, new when it's another Voidkin's: the same on every page, so a switch of tabs
-- never changes a colour (TR24, the director's run, fix 4).
local function dress(on: Frame, def: string, roster: { Profile.OwnedVoidkin }, at: Place)
	local row = Voidkin.ById[def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Look.Line
	local light = on:FindFirstChild("Light") :: UIGradient
	local dark = HudConfig.Seam.Stage
	light.Color = ColorSequence.new(dark[1], dark[2]:Lerp(trim, 0.35)) -- the seam's dark, lit from below by its rarity
	local halo = on:FindFirstChild("Halo") :: Frame
	halo.BackgroundColor3 = trim
	halo.BackgroundTransparency = 0.82
	-- It fills the stage: its crown Figure.Top under the stage's top, its soles over the feet's row.
	local config = HudConfig.Voidkin
	local stageHeight = at.Stage.Tall
	local feet = 1 - (config.Power.Height + 2) / stageHeight
	local height = math.max(0.2, feet - config.Figure.Top / stageHeight)
	halo.Position = UDim2.fromScale(0.5, feet - height * 0.55)
	measured.Height, measured.Stage = height * stageHeight / at.Room.Y, stageHeight
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
local function nameLine(over: Frame, x: number, wide: number, owned: Profile.OwnedVoidkin, on: On): (() -> boolean)?
	local gap = Theme.Size.Gap
	local row = frameOf("Name", over, UDim2.fromOffset(x, 0), UDim2.fromOffset(math.max(wide, 1), TITLE))
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
		box.TextColor3 = Look.Text
		box.PlaceholderColor3 = Look.TextDim
		box.BackgroundColor3 = Look.PlateHigh
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
			if refused("Name", on.Act("SetNickname", { Voidkin = owned.Id, Name = box.Text })) then
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
	local rarityLabel = text({ Name = "Rarity", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = HudConfig.Card.Trim[rarity] or Look.TextDim, Box = UDim2.fromOffset(0, TITLE), Parent = row }, rarity)
	rarityLabel.AutomaticSize = Enum.AutomaticSize.X
	rarityLabel.LayoutOrder = 2
	return nil
end

-- The line under a press that moves a Voidkin into or out of a bay, with what it costs (docs/ui.md, item 5, "Lead and
-- Station say what they cost"; the outside review's item 6, research's words): `words`, then its kW change in the gains'
-- green or the losses' red. The base after the press is the HUD's power pill's to show.
local function cost(words: string, kw: number): string
	local light = if kw < 0 then UIKit.Bad else UIKit.Good
	return `{words} · <font color="#{light:ToHex()}">{Hud.KwChange(kw)}</font>`
end

-- The line under a press, Glass.Dress's, read as rich text so its cost wears its colour.
local function richUnder(button: TextButton)
	local why = button:FindFirstChild("Why", true)
	if why and why:IsA("TextLabel") then
		why.RichText = true
	end
end

-- Lead and Station (or Recall), side by side in `parent`, the line over the panel, in the Glass kit's faces (AR43's take
-- 2, voidkin_b.json, actions). On the lead, "Leading" with its mark stands alone across the line, lit, the diamond and the
-- word in the Ink centred together: an action the page's own state rules out isn't shown (research's ruling on the
-- director's remark, 2026-11-17, 20:31). Another's Lead is lit, Station (or Recall) quiet in the Text. A passing block is
-- the Off press, its name kept and why under it ("No bay free"); Station and Recall say their bay under their name
-- (docs/ui.md, rule 4).
local function actions(parent: Frame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	local gap = Theme.Size.Gap
	local at = Read.Role(view, owned.Id)
	local leading = at == "Lead"
	local wide = parent.Size.X.Offset
	local each = if leading then wide else math.floor((wide - gap) / 2)
	local dress: Glass.Dress = { Palette = Seam.Kit, Under = true, Mark = leading }
	local function press(name: string, x: number, act: () -> boolean?): TextButton
		return Button.new({ Name = name, Text = "", Bare = true, Size = UDim2.fromOffset(each, ROW), Position = UDim2.fromOffset(x, 0), Parent = parent, OnPress = act })
	end
	local lead = press("Lead", 0, function(): boolean?
		if leading then
			return nil -- it leads already: nothing to ask
		end
		return refused("Lead", on.Act("SetLead", { Voidkin = owned.Id }))
	end)
	local worn = "" -- the face it wears: laid again only when its state moves
	local function leadState()
		local now = workspace:GetServerTimeNow()
		local why = if leading then nil else Hud.LeadReason(at, on.Healing()[owned.Id], now, player:GetAttribute("InCombat") == true)
		local blocked: string? = if type(why) == "string" then why else nil
		local kind = if blocked then "Off" else "Lit"
		-- on a worker: the lead it swaps with takes its bay unless that one's healing (Collection.SetLead; TR72, item 1)
		local oldId = view.Roles.Lead
		local old = if oldId ~= "" and oldId ~= owned.Id then view.Voidkin[oldId] else nil
		local oldWhole = if old then on.Healing()[old.Id] else nil
		local swap = if old and not (oldWhole and oldWhole > now) then old else nil
		local note = Hud.LeadNote(at, if swap then Read.VoidkinName(swap) else nil)
		local from = tonumber(string.match(at, "^Bay (%d+)$"))
		-- and what its bay's making changes by ("Rook takes Bay 2 · −6 kW", "Leaves Bay 2 · −18 kW")
		local kw = if from then -Power.BayKw(view :: any, from, owned :: any) + (if swap then Power.BayKw(view :: any, from, swap :: any) else 0) else 0
		local under = blocked or (if note and from then cost(note, kw) else note)
		local key = `{kind}|{tostring(under)}`
		if key ~= worn then
			worn = key
			Glass.Dress(lead, kind, if leading then "Leading" else "Lead", under, dress)
			richUnder(lead)
			Button.Set(lead, { Selected = leading })
		end
	end
	leadState()
	table.insert(tickers, leadState)
	if leading then
		return
	end
	local working = string.match(at, "^Bay (%d+)$")
	local why, bay = Hud.WorkReason(at, view.Base.Bays)
	local work = press("Work", each + gap, function(): boolean
		if working then
			return refused("Recall", on.Act("SetWorker", { Bay = tonumber(working), Voidkin = "" }))
		end
		return refused("Station", on.Act("SetWorker", { Bay = bay, Voidkin = owned.Id }))
	end)
	local words = if working then "Recall" else "Station"
	if working then
		-- Recall: what its bay stops making ("Bay 2 · −18 kW")
		Glass.Dress(work, "Quiet", words, cost(`Bay {working}`, -Power.BayKw(view :: any, tonumber(working) :: number, owned :: any)), dress)
	elseif why then
		Glass.Dress(work, "Off", words, why, dress)
	else
		-- Station: what it would make there ("Bay 3 · +12 kW")
		Glass.Dress(work, "Quiet", words, if bay then cost(`Bay {bay}`, Power.BayKw(view :: any, bay, owned :: any)) else nil, dress)
	end
	richUnder(work)
end

-- Combat Power at its feet, the screen's showpiece (the director, 2026-11-14, night): on a plate of its rarity's light
-- that fades out at both ends, its emblem, its caption and its digits. A rise since it was last shown counts the digits
-- up from the old number and floats the gain off the plate's end. Between the hands it's `wide`: a narrow plate drops its
-- emblem and sets its digits as large as they fit. In grey: the look is Modulo's after the pick. A tap shows where it
-- comes from.
local function power(parent: Instance, owned: Profile.OwnedVoidkin, block: Stats.Block, wide: number)
	local config = HudConfig.Voidkin.Power
	local row = Voidkin.ById[owned.Def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Look.Line
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
	Seam.Edge(press, "Seam", 0, 0, wide, false, HudConfig.Seam.Edges.Power) -- a line of the seam's light along its top
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
	emblem.BackgroundColor3 = Look.PlateHigh
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
		shade.BackgroundColor3 = Look.Backing
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
	local caption = text({ Name = "Caption", Size = Theme.Text.Caption, Colour = finish.Caption, Align = align, Box = UDim2.new(1, if whole then -left else 60, 0, 16), Position = UDim2.fromOffset(if whole then left else -30, 1), Parent = press }, string.upper(Sheet.Said.Power))
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
		local gain = text({ Name = "Gain", Font = Theme.Font.Number, Colour = Look.Heal, Box = UDim2.fromOffset(96, 22), Position = UDim2.new(1, 4, 0, 20), Parent = press }, `+{Hud.Digits(value - from)}`)
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
		local quiet = text({ Name = "Under", Size = Theme.Text.Caption, Colour = Look.TextDim, Box = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 22), Parent = item, Wrap = true }, under)
		quiet.AutomaticSize = Enum.AutomaticSize.Y
	end
	return item
end

-- One stat's cell (docs/ui.md, "Stats, shown honestly"; rework part 4), `across` a row: its name over its one total (a
-- rating's percent against an even foe, and nothing else), and an attribute's Main tag right after its own total, never
-- at the cell's far edge where it read as the next cell's (TR24, the director's run); nothing opens [the director,
-- 2026-11-15, night: "Plain list, no taps"].
local function statCell(pair: Frame, side: number, row: Sheet.Row, tall: number, across: number): Frame
	local item = Instance.new("Frame")
	item.Name = row.Name
	item.BackgroundTransparency = 1
	item.Position = UDim2.fromScale(side / across, 0)
	item.Size = UDim2.new(1 / across, 0, 0, tall)
	item.Parent = pair
	text({ Name = "Left", Size = Theme.Text.Caption, Colour = Look.TextDim, Box = UDim2.new(1, -SHEET.Pad, 0, SHEET.Name), Position = UDim2.fromOffset(0, SHEET.Top), Parent = item }, row.Name)
	-- The total and its tag in one row, each as wide as its words, so the tag sits against its own number.
	local total = frameOf("Total", item, UDim2.fromOffset(0, SHEET.Top + SHEET.Name), UDim2.new(1, -SHEET.Pad, 0, SHEET.Value))
	list(total, true)
	local layout = total:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local value = text({ Name = "Right", Font = Theme.Font.Number, Box = UDim2.new(0, 0, 1, 0), Parent = total }, row.Value)
	value.AutomaticSize = Enum.AutomaticSize.X
	if row.Main then
		local tag = text({ Name = "Main", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = Look.Primary, Box = UDim2.new(0, 0, 1, 0), Parent = total }, "Main")
		tag.AutomaticSize = Enum.AutomaticSize.X
		tag.LayoutOrder = 1
	end
	if row.Under then
		text({ Name = "Under", Size = Theme.Text.Caption, Colour = Look.TextDim, Box = UDim2.new(1, -SHEET.Pad, 0, SHEET.Under), Position = UDim2.fromOffset(0, SHEET.Top + SHEET.Name + SHEET.Value), Parent = item }, row.Under)
	end
	item:SetAttribute("Stat", row.Stat)
	return item
end

-- How many of a block's cells stand in a row: the Battle Attributes two; the Basic Attributes three (AR43's take 2,
-- Modulo's cut, 2026-11-19) when every name and total fits a third of the row whole at the size it draws, else two:
-- research's condition (21:28), no attribute's name or number cut or shrunk on the smallest phone, the cells wider.
local function across(group: Sheet.Group): number
	if group.Heading ~= Sheet.Headings.Basic then
		return 2
	end
	local room = sheetWide / 3 - SHEET.Pad
	local name = text({ Name = "Probe", Size = Theme.Text.Caption }, "")
	local total = text({ Name = "Probe", Font = Theme.Font.Number }, "")
	local tag = text({ Name = "Probe", Size = Theme.Text.Caption, Font = Theme.Font.Strong }, "")
	local fits = room > 0
	for _, row in group.Rows do
		local need = Text.Wide(total, row.Value) + (if row.Main then Theme.Size.Gap + Text.Wide(tag, "Main") else 0)
		if Text.Wide(name, row.Name) > room or need > room then
			fits = false
		end
	end
	name:Destroy()
	total:Destroy()
	tag:Destroy()
	return if fits then 3 else 2
end

-- Its whole stat sheet, from `order` on (docs/ui.md, 5, "Overview's stat sheet"; rework part 4): the Basic Attributes,
-- then the Battle Attributes' three blocks, every stat a line, a zero as 0, each one total from Rules.Sheet, Offence and
-- Defence paired. A heading is a line of its own with its caption under it; a block's name is a quiet caption over its
-- cells. The Battle Attributes two a row, each at least as tall as a touch, so the sheet keeps its rhythm; the five Basic
-- Attributes three a row, then two, each its words' height, and the first heading with no space above its words, so all
-- five show on the smallest phone with nothing scrolled (AR43's take 2).
local function statSheet(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, order: number)
	local block = resolved(view, owned)
	for index, group in Sheet.Rows(block) do
		if group.Heading then
			order += 1
			local line = if index == 1 then Theme.Text.Body + 6 else SHEET_HEADING.Line
			local heading = Instance.new("Frame")
			heading.Name = `Heading{group.Heading}`
			heading.BackgroundTransparency = 1
			heading.LayoutOrder = order
			heading.Size = UDim2.new(1, -8, 0, line + (if group.Caption then SHEET_HEADING.Caption else 0))
			heading.Parent = scroll
			text({ Name = "Left", Font = Theme.Font.Strong, Box = UDim2.new(1, 0, 0, Theme.Text.Body + 6), Position = UDim2.new(0, 0, 0, line - Theme.Text.Body - 6), Parent = heading }, string.upper(group.Heading))
			if group.Caption then
				text({ Name = "Caption", Size = Theme.Text.Caption, Colour = Look.TextDim, Box = UDim2.new(1, 0, 0, SHEET_HEADING.Caption), Position = UDim2.fromOffset(0, line), Parent = heading }, group.Caption)
			end
		end
		if group.Name ~= "" then
			order += 1
			local head = Instance.new("Frame")
			head.Name = `Group{group.Name}`
			head.BackgroundTransparency = 1
			head.LayoutOrder = order
			head.Size = UDim2.new(1, -8, 0, SHEET_HEAD)
			head.Parent = scroll
			local caption = UDim2.new(1, 0, 0, Theme.Text.Caption + 4)
			local foot = UDim2.new(0, 0, 1, -(Theme.Text.Caption + 4))
			text({ Name = "Left", Size = Theme.Text.Caption, Font = Theme.Font.Strong, Colour = Look.TextDim, Box = caption, Position = foot, Parent = head }, group.Name)
		end
		local many = across(group)
		local least = if many == 3 then SHEET.Top + SHEET.Name + SHEET.Value else SHEET.Line
		for at = 1, #group.Rows, many do
			order += 1
			local under = false
			for side = 0, many - 1 do
				local row = group.Rows[at + side]
				under = under or (row ~= nil and row.Under ~= nil)
			end
			local tall = if under then math.max(least, SHEET.Top + SHEET.Name + SHEET.Value + SHEET.Under) else least
			local pair = Instance.new("Frame")
			pair.Name = `Pair{group.Name}{(at + many - 1) // many}`
			pair.BackgroundTransparency = 1
			pair.LayoutOrder = order
			pair.Size = UDim2.new(1, -8, 0, tall)
			pair:SetAttribute("Across", many)
			pair.Parent = scroll
			for side = 0, many - 1 do
				local row = group.Rows[at + side]
				if row then
					statCell(pair, side, row, tall, many)
				end
			end
		end
	end
end

local function overview(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	-- How many exist, in the header once the server holds its number: "No. 1,284 · 3,912 exist" (docs/design.md,
	-- "How many exist"; Rules.Exist; the count is ReplicatedStorage's Exist folder, ExistService's)
	local counts = ReplicatedStorage:FindFirstChild(ExistConfig.Folder)
	local held = if counts then counts:GetAttribute(owned.Def) else nil
	local exists = Exist.Words(owned.No, if type(held) == "number" then held else nil)
	line(scroll, 1, Read.VoidkinLine(owned.Def, true))
	local need = Growth.XpToNext(owned.Level)
	-- Its experience on one line, its bar right under the words and the line ending at the bar's foot (AR43's take 2,
	-- voidkin_b.json, overview.heading: the Basic Attributes' heading pulled up, so all five show on the smallest phone).
	local xp = line(scroll, 2, `Level {owned.Level}`, nil, if need then `{Hud.Digits(owned.Xp)} of {Hud.Digits(need)} to Level {owned.Level + 1}` else "The last level")
	if need then
		local stack = Instance.new("UIListLayout")
		stack.SortOrder = Enum.SortOrder.LayoutOrder
		stack.Parent = xp
		for index, name in { "Left", "Under" } do
			local piece = xp:FindFirstChild(name) :: GuiObject?
			if piece then
				piece.LayoutOrder = index
			end
		end
		local bar = Bar.new({ Name = "Xp", Size = UDim2.new(1, 0, 0, Theme.Size.Bar), Parent = xp, Colour = HudConfig.Card.Xp, Palette = Seam.Palette })
		bar.LayoutOrder = 3
		Bar.Set(bar, math.clamp(owned.Xp / need, 0, 1))
	end
	if exists ~= "" then -- at the right of the level's row, so it costs the list no height (all five Basic Attributes
		-- stay on the smallest phone, AR43's take 2), with room for six figures where the header's line has none
		local count = text({ Name = "Exist", Size = Theme.Text.Caption, Colour = Look.TextDim, Align = Enum.TextXAlignment.Right, Box = UDim2.new(0, 0, 1, 0), Parent = xp:FindFirstChild("Left") :: Instance }, exists)
		count.AutomaticSize = Enum.AutomaticSize.X
		count.AnchorPoint = Vector2.new(1, 0)
		count.Position = UDim2.fromScale(1, 0)
	end
	statSheet(scroll, view, owned, 2) -- straight under its level: the page's reason
	local now = line(scroll, 30, "Now", nil, role(view, owned, on, workspace:GetServerTimeNow()))
	local nowLabel = now:FindFirstChild("Under") :: TextLabel
	table.insert(tickers, function()
		nowLabel.Text = role(view, owned, on, workspace:GetServerTimeNow())
	end)
	local own = Voidkin.ById[owned.Def]
	if own then -- the stage has no room for a caption: which preset its slots show, its class's pair of hands, and what
		-- the preset has it wear, read from the preset (the follow-up's 4.10)
		local worn = 0
		for _ in BagRules.Worn(view, owned) do
			worn += 1
		end
		local wears = if worn == 0 then "nothing worn yet" elseif worn == 1 then "1 piece worn" else `{worn} pieces worn`
		line(scroll, 31, `Gear · preset {owned.Preset}`, nil, `{Gear.Kind("Main Hand", own.Class)} and {Gear.Kind("Off Hand", own.Class)} in hand · {wears}`)
		-- The presets its base's level holds (TR56), one press each: the one it wears lit, a tap on another links it there.
		local count = #(view :: any).Presets
		if count > 1 then
			local row = Instance.new("Frame")
			row.Name = "Presets"
			row.BackgroundTransparency = 1
			row.LayoutOrder = 32
			row.Size = UDim2.fromOffset(sheetWide, ROW)
			row.Parent = scroll
			local gap = 6
			local each = math.floor((sheetWide - gap * (count - 1)) / count)
			for index = 1, count do
				local press = Button.new({
					Name = `Preset{index}`,
					Text = "",
					Bare = true,
					Size = UDim2.fromOffset(each, ROW),
					Position = UDim2.fromOffset((index - 1) * (each + gap), 0),
					Parent = row,
					OnPress = function(): boolean
						if owned.Preset == index then
							return false
						end
						return refused("Preset", on.Act("UsePreset", { Voidkin = owned.Id, Preset = index }))
					end,
				})
				Glass.Dress(press, if owned.Preset == index then "Lit" else "Quiet", `Preset {index}`, nil, { Palette = Seam.Kit })
			end
		end
	end
	if owned.Nickname ~= "" then
		line(scroll, 33, "Nickname", nil, if own then own.Name else owned.Def)
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
	line(scroll, 2, "Combo", nil, if hits > 0 then `{hits}-hit combo, repeating` else "Moves coming soon")
	local passive, how = said(row.Words.Passive)
	local own = Passives.ById[owned.Def]
	line(scroll, 3, `Passive · {if own then own.Name else passive}`, nil, how)
end

local function starsTab(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On)
	local row = Voidkin.ById[owned.Def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Look.Line
	-- The pips (AR43's take 2, voidkin_b.json, stars.pips): a 14-point square turned 45 degrees, 20 tall, 24 apart. A won
	-- star is its rarity's trim lit from above, a Glint hairline and the trim's glow; one to win, the Well with a Facet
	-- hairline: seven to win, each seen.
	local P = HudConfig.Voidkin.Pips
	local pips = Instance.new("Frame")
	pips.Name = "Pips"
	pips.BackgroundTransparency = 1
	pips.LayoutOrder = 1
	pips.Size = UDim2.new(1, 0, 0, P.Half * 2 + P.Glow * 2)
	pips.Parent = scroll
	for index = 1, VoidkinConfig.MaxStars do
		local won = index <= owned.Stars
		local cx, cy = P.Glow + P.Half + (index - 1) * P.Pitch, P.Glow + P.Half
		if won then
			Glass.Glow(pips, `Glow{index}`, cx - P.Half, cy - P.Half, P.Half * 2, P.Half * 2, P.Glow, trim, P.GlowAlpha, 1)
		end
		local pip = Instance.new("Frame")
		pip.Name = `Star{index}`
		pip.AnchorPoint = Vector2.new(0.5, 0.5)
		pip.Position = UDim2.fromOffset(cx, cy)
		pip.Size = UDim2.fromOffset(P.Side, P.Side)
		pip.Rotation = 45
		pip.BorderSizePixel = 0
		pip.BackgroundColor3 = Color3.new(1, 1, 1)
		pip.ZIndex = 2
		pip:SetAttribute("Won", won)
		local ramp = Instance.new("UIGradient")
		ramp.Rotation = 45 -- the screen's top to foot, the square turned under it
		ramp.Color = if won then ColorSequence.new(trim:Lerp(Color3.new(1, 1, 1), P.Lit), trim) else ColorSequence.new(Seam.Kit.Well, HudConfig.Seam.WellFoot)
		ramp.Parent = pip
		local hair = Instance.new("UIStroke")
		hair.Name = "Hairline"
		hair.Thickness = 1
		hair.Color = if won then Seam.Kit.Glint else Seam.Kit.Facet
		hair.Transparency = if won then P.WonHair else P.EmptyHair
		hair.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hair.Parent = pip
		pip.Parent = pips
	end
	local cost = Collection.NextStarCost(owned)
	line(scroll, 2, `{owned.Stars} of {VoidkinConfig.MaxStars} stars`, nil, if cost then Hud.Copies(owned.Copies, cost) else `All {ALL_STARS} stars. Extra copies sell for Credits.`)
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
				table.insert(gains, `+{Hud.Digits(gain)} {Sheet.Said[name] or name}`)
			end
		end
		line(scroll, 3, "The next star", `+{Hud.Digits(Stats.Power(after) - before)}`, `{table.concat(gains, " · ")}, {Sheet.Said.Power} on the right`)
		-- Take the star (stars.press): lit, its words in the Ink; short of copies, the Off press saying how many under it.
		local take = Button.new({
			Name = "TakeStar",
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(sheetWide, ROW),
			LayoutOrder = 4,
			Parent = scroll,
			OnPress = function(): boolean
				return refused("Stars", on.Act("SpendCopies", { Voidkin = owned.Id }))
			end,
		})
		local short = cost - owned.Copies
		if short > 0 then
			Glass.Dress(take, "Off", "Take the star", if short == 1 then "1 more copy" else `{short} more copies`, { Palette = Seam.Kit, Under = true })
		else
			Glass.Dress(take, "Lit", "Take the star", nil, { Palette = Seam.Kit })
		end
	end
end

-- The chosen page, filling `parent` from `top` down.
local function pageBody(parent: Frame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On, top: number)
	local scroll = scroller("Page", parent, UDim2.fromOffset(0, top), UDim2.new(1, 0, 1, -top), false)
	scroll.ScrollBarImageColor3 = Look.TextDim -- AR43's take 2: the bar in the Soft at 0.4, 2.4 wide
	scroll.ScrollBarImageTransparency = 0.4
	scroll.ScrollBarThickness = 2.4
	scroll:SetAttribute("Keep", `{owned.Id}{page}`)
	scroll:SetAttribute("Page", page)
	if page == "Kit" then
		kitTab(scroll, owned)
	elseif page == "Stars" then
		starsTab(scroll, view, owned, on)
	else
		overview(scroll, view, owned, on)
	end
end

-- AR29's B, the seam (the director's pick, 2026-11-17, 14:04; Modulo's numbers, 14:15; Config.Hud.Voidkin.Chrome): the
-- bar's icons are Modulo's, white on alpha, tinted here.
-- One of the chrome's icons, `side` across, its middle at `at`, named "Icon" (its image's name as its "Kit").
local Whole, Thin = Seam.Whole, Seam.Thin -- B's points made whole before a UDim cuts them (Seam.Whole)

local function chromeIcon(parent: Instance, key: string, side: number, at: UDim2, tint: Color3, z: number): ImageLabel
	local record = HudConfig.Voidkin.Chrome.Images[key]
	local image = Instance.new("ImageLabel")
	image.Name = "Icon"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Image = record.Id
	image.ImageColor3 = tint
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = at
	image.Size = UDim2.fromOffset(side, side)
	image.ZIndex = z
	image:SetAttribute("Kit", key)
	image.Parent = parent
	return image
end

-- Back, B's: no plate (Screen.Full's `dress`). Its chevron and its word on the band, over a line of Light strongest under
-- its middle, all in its face, so a press squeezes them as one.
local function dressBack(exit: TextButton)
	local look = HudConfig.Voidkin.Chrome.Bar.Back
	local rail = HudConfig.Voidkin.Chrome.Rail
	local face = Skin.Of(exit)
	local side = Whole(2 * look.Chevron * rail.Icon / rail.Drawn)
	chromeIcon(face, "Back", side, UDim2.new(0, Whole(look.ChevronAt), 0.5, 0), Look.Text, 20)
	local word = text({
		Name = "Word",
		Size = look.Word,
		Font = Theme.Font.Strong,
		Colour = Look.Text,
		Align = Enum.TextXAlignment.Left,
		Box = UDim2.new(1, -Whole(look.WordAt), 1, 0),
		Position = UDim2.fromOffset(Whole(look.WordAt), 0),
		Parent = face,
	}, "BACK")
	word.ZIndex = 20
	local line = look.Line
	local long = Screen.Back.X - line.Inset * 2
	local edge = Seam.Edge(face, "Line", line.Inset, 0, long, false, { Spread = line.Spread / long, Floor = line.Floor, Strength = 1 }, 0.5, Seam.Bands(line.Tall, line.Glow, line.GlowAlpha))
	edge.Position = UDim2.new(0, Whole(line.Inset), 1, -Whole(line.Over))
	edge.ZIndex = 19
end

-- Favourite, lock and rename in the band, right of Back: B's channel, one cut plate of the dark split by hairlines into
-- three equal cells, each a touch or more, an icon in each: the seam's text when off; on, Light with a short line of it
-- under, favourite and lock drawn solid and shut. Renaming, Save (`save`) and Cancel stand there as kit buttons. Returns
-- where they end, authored from the band's left.
local function marks(band: Frame, owned: Profile.OwnedVoidkin, on: On, save: (() -> boolean)?): number
	local gap = Theme.Size.Gap
	local tall = Screen.Row()
	local x = Screen.BandLeft
	if save then
		local function button(name: string, said: string, press: () -> ...any)
			Button.new({
				Palette = Seam.Palette,
				Name = name,
				Text = said,
				Size = UDim2.fromOffset(WORD, tall),
				Position = UDim2.new(0, x, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Parent = band,
				TextSize = Theme.Text.Caption,
				OnPress = press,
			})
			x += WORD + gap
		end
		button("Save", "Save", save)
		button("Cancel", "Cancel", function()
			editing, draft = false, nil
			rebuild()
		end)
		return x - gap
	end
	local chrome = HudConfig.Voidkin.Chrome
	local look, rail = chrome.Bar, chrome.Rail
	local channel = look.Channel
	local cell = math.ceil(math.max(channel.Cell, touch()))
	-- The channel's top and foot from the band's middle, each whole, so the lit line hangs a whole Over above that foot.
	local top, foot = -Whole(tall / 2 + channel.Over), Whole(tall / 2 + channel.Under)
	local plate = frameOf("Channel", band, UDim2.new(0, x, 0.5, top), UDim2.fromOffset(cell * 3, foot - top))
	plate.AnchorPoint = Vector2.new(0, 0)
	plate.Active = false
	Skin.LayOwn(plate, chrome.Images.ChannelFill, "Fill", { Tint = Look.Channel, Alpha = channel.Fill, Z = 1 })
	Skin.LayOwn(plate, chrome.Images.ChannelEdge, "Edge", { Tint = Look.Line, Z = 2 })
	for at = 1, 2 do
		local split = Instance.new("Frame")
		split.Name = `Split{at}`
		split.BorderSizePixel = 0
		split.BackgroundColor3 = Look.Line
		split.AnchorPoint = Vector2.new(0.5, 0)
		split.Position = UDim2.fromOffset(cell * at, Whole(channel.Over + channel.Split.Inset))
		split.Size = UDim2.fromOffset(Thin(channel.Split.Wide), Thin(tall - channel.Split.Inset * 2))
		split.ZIndex = 3
		split.Parent = plate
	end
	local middle = (top + foot) / 2 -- the channel's middle, from a cell's
	local function mark(name: string, lit: boolean, press: () -> ...any)
		local made = Button.new({
			Palette = Seam.Palette,
			Name = name,
			Text = "",
			Bare = true,
			Size = UDim2.fromOffset(cell, tall),
			Position = UDim2.new(0, x, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = band,
			OnPress = press,
		})
		made.ZIndex = 2
		x += cell
		Button.Set(made, { Selected = lit })
		made:SetAttribute("On", lit)
		local face = Skin.Of(made)
		chromeIcon(face, if lit then `{name}On` else name, rail.Icon, UDim2.new(0.5, 0, 0.5, Whole(middle - look.Mark.Lift)), if lit then Seam.Light else Look.Text, 20)
		if lit then
			local under = look.Mark.On
			local edge = Seam.Edge(face, "Lit", 0, 0, under.Long, false, { Spread = 1e3, Floor = 1, Strength = 1 }, nil, Seam.Bands(under.Tall, under.Glow, under.GlowAlpha))
			edge.Position = UDim2.new(0.5, -Whole(under.Long / 2), 0.5, Whole(foot - under.Over))
			edge.ZIndex = 19
		end
	end
	mark("Favourite", owned.Favourite, function(): boolean
		return refused("Favourite", on.Act("SetMark", { Voidkin = owned.Id, Mark = "Favourite", On = not owned.Favourite }))
	end)
	mark("Lock", owned.Locked, function(): boolean
		return refused("Lock", on.Act("SetMark", { Voidkin = owned.Id, Mark = "Locked", On = not owned.Locked }))
	end)
	mark("Rename", false, function()
		editing, draft = true, nil
		rebuild()
	end)
	return x
end

-- At its feet, Combat Power alone, under the figure's middle: the Overview shows no gear slots (the director,
-- 2026-11-17: "overview ui shouldn't show any gears slot"; gear is the Items page's).
local function feet(over: Frame, at: Place, owned: Profile.OwnedVoidkin, block: Stats.Block)
	local config = HudConfig.Voidkin
	local row = frameOf("Feet", over, UDim2.new(0, at.Group, 1, -config.Power.Height), UDim2.fromOffset(at.Span, config.Power.Height))
	power(row, owned, block, math.clamp(at.Span - Theme.Size.Gap * 2, Theme.Size.Tap, config.Power.Width))
end

-- The currencies at the band's right: Credits and the battery, read again every WALLET.Every seconds. A chip is as wide
-- as its number. They never cross what stands right of `left` (authored, from the band's left; research's must-fix on
-- TR28, 2026-11-17): in a band too narrow, they step down until they fit: the battery without its capacity, then what
-- it holds alone (its bolt says what it is), then Credits short (Hud.Short), then the battery alone.
-- The page's name in the band from `left` (authored), in the seam's text; returns where it ends.
local function pageName(band: Frame, left: number): number
	local said = named or page
	local label = text({ Name = "PageName", Size = Theme.Text.Body, Font = Theme.Font.Strong, Box = UDim2.fromOffset(1, BAR), Position = UDim2.new(0, left + Theme.Size.Pad, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = band }, said)
	local wide = math.ceil(Text.Wide(label, said))
	label.Size = UDim2.fromOffset(wide, BAR)
	return left + Theme.Size.Pad + wide
end

local function wallet(band: Frame, left: number, view: Profile.View)
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local size = Text.Legible(Theme.Text.Body, Layers.Scale())
	local function wideOf(said: string): number
		return WALLET.Icon + math.ceil(#said * WALLET.Digit * size) + pad
	end
	-- The battery in kWh (TR18), measured at its widest: a full one, at the cap its base's level holds (TR21).
	local cap = Breaker.Capacity(view.Base)
	local capacity = Read.Number(cap)
	local room = Layers.Band().X - pad - left - gap
	local steps = {
		{ Form = "Whole", Credits = Read.Number(view.Currency.Credits), Battery = `{Read.Kwh(cap)} / {capacity} kWh` },
		{ Form = "Short", Credits = Read.Number(view.Currency.Credits), Battery = `{Read.Kwh(cap)} kWh` },
		{ Form = "Bare", Credits = Read.Number(view.Currency.Credits), Battery = Read.Kwh(cap) },
		{ Form = "Bare", Credits = Hud.Short(view.Currency.Credits), Battery = Read.Kwh(cap) },
		{ Form = "Bare", Credits = nil, Battery = Read.Kwh(cap) },
	}
	local step = steps[#steps]
	for _, each in steps do
		if (if each.Credits then wideOf(each.Credits) + gap else 0) + wideOf(each.Battery) <= room then
			step = each
			break
		end
	end
	local owns = step.Credits
	local battery = wideOf(step.Battery)
	local holder = frameOf("Wallet", band, UDim2.new(1, -pad, 0.5, 0), UDim2.fromOffset((if owns then wideOf(owns) + gap else 0) + battery, BAR))
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder:SetAttribute("Short", step.Form ~= "Whole")
	holder:SetAttribute("Form", step.Form)
	local function chip(name: string, icon: string, wide: number, right: number): TextLabel
		local made = Instance.new("Frame")
		made.Name = name
		made.BorderSizePixel = 0
		made.BackgroundColor3 = Look.Channel -- AR43's take 2: the chip in the Channel with the Edge
		made.BackgroundTransparency = 0
		made.AnchorPoint = Vector2.new(1, 0)
		made.Position = UDim2.new(1, -right, 0, 0)
		made.Size = UDim2.fromOffset(wide, BAR)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Size.Corner)
		corner.Parent = made
		local edge = Instance.new("UIStroke")
		edge.Name = "Edge"
		edge.Color = Look.Line
		edge.Thickness = 1
		edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		edge.Parent = made
		made.Parent = holder
		Skin.Icon(made, icon, 16, BAR / 2, 20)
		return text({ Name = "Value", Font = Theme.Font.Number, Align = Enum.TextXAlignment.Right, Box = UDim2.new(1, -(WALLET.Icon + pad), 1, 0), Position = UDim2.fromOffset(WALLET.Icon, 0), Parent = made }, "")
	end
	local electricity = chip("Electricity", "Bolt", battery, 0)
	if owns then
		local credits = chip("Credits", "Coin", wideOf(owns), battery + gap)
		credits.Text = owns
	end
	local readAt = -math.huge
	local function read()
		if os.clock() - readAt < WALLET.Every then
			return
		end
		readAt = os.clock()
		local base = Read.Base(view, workspace:GetServerTimeNow())
		local stored = Read.Kwh(base.Data.Base.Charge)
		electricity.Text = if step.Form == "Whole" then `{stored} / {capacity} kWh` elseif step.Form == "Short" then `{stored} kWh` else stored
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
			Palette = Seam.Own.Palette, -- the portraits bring no more violet (AR43's take 2, palette.keep)
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
		local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Look.Line
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

-- The page rail (AR49; UI.Kit.Rail): the Equipment screen's rail, its four pages down the room's left. Its words are the
-- rail's sizes; its discs the largest share of the rail's radii that stands four whole in the room's height: the first lit
-- at the top, a lit one over a rested one at each step, the last lit at the foot (Config.Hud.Voidkin.Rail).
local function railSpec(at: Place): Rail.Spec
	local R, mine = HudConfig.Equipment.Rail, HudConfig.Voidkin.Rail
	local word = R.Word
	local ring = 4.5 -- a disc's ring stands this far out of it
	local under = word.Gap + word.Chosen + 2 -- a lit word's box under its disc
	local tall = at.Room.Y - mine.Margin * 2
	local fixed = ring + 3 * (under + ring) + under
	local share = math.clamp((tall - fixed) / (R.Chosen + 3 * (R.Chosen + R.Rest) + R.Chosen), mine.Least, 1)
	local chosen, rest = R.Chosen * share, R.Rest * share
	local least = chosen + under + rest + ring
	local pitch = math.clamp((tall - (chosen + ring) - (chosen + under)) / 3, least, math.max(least, mine.Pitch))
	local x = at.Rail.X + at.Rail.Wide / 2
	local first = mine.Margin + chosen + ring
	local places: { [string]: Vector2 } = {}
	local marks: { [string]: string } = {}
	local MARKS = { Overview = "PageOverview", Kit = "PageKit", Bag = "PageItems", Stars = "PageStars" }
	for k, name in mine.Pages do
		places[name] = Vector2.new(x, first + (k - 1) * pitch)
		marks[name] = MARKS[name]
	end
	local foot = first + (#mine.Pages - 1) * pitch + chosen + under
	local tap = math.min(pitch - 1, 79)
	return {
		Pages = mine.Pages,
		At = places,
		Marks = marks,
		Words = SAID,
		Line = { x, mine.Margin, foot },
		Rest = rest,
		Chosen = chosen,
		Tap = Vector2.new(math.min(at.Rail.Wide + Theme.Size.Pad, 92), tap),
		TapTop = math.min(chosen + 4, tap / 2),
		Switch = function(name: string): boolean
			if name ~= page then
				show(name)
			end
			return true
		end,
	}
end

local function rail(body: Frame, at: Place)
	local made = Rail.new(body, railSpec(at), railShown or page)
	if railShown and railShown ~= page then
		Rail.Paint(made, page, railShown)
	end
	railShown = page
	Glass.Idle(made.Holder, function(phase: number)
		Rail.Idle(made, phase)
	end)
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
	local body = Screen.Full(NAME, "Voidkin", Seam.Palette, dressBack)
	local frame = Screen.Frame(NAME) :: Frame
	local band = Screen.Band(NAME) :: Frame
	-- Under the stage: what a page lays behind its figure (the Items page's room), cleared with the body.
	local behind = frame:FindFirstChild("Behind") :: Frame?
	if behind == nil then
		local made = Instance.new("Frame")
		made.Name = "Behind"
		made.BackgroundTransparency = 1
		made.BorderSizePixel = 0
		made.Size = UDim2.fromScale(1, 1)
		made.ZIndex = -1
		made.Parent = frame
		behind = made
	end
	(behind :: Frame):ClearAllChildren()
	Glass.Ground(behind :: Frame, 1, { Seam.Colour.Backing, Seam.Colour.Backing }) -- AR43's take 2: Seam's Backing, the kit's top light
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
	if page == "Bag" then
		-- The Items page is AR18's A (TR28): right of the rail, the doll with the figure between its slots, then the grid.
		local block = resolved(view, owned)
		local save = BagPage.Build({
			Body = body,
			Behind = behind :: Frame,
			Room = at.Room,
			Left = at.Stage.X,
			View = view,
			Owned = owned,
			Act = on.Act,
			Taps = taps,
			Rebuild = rebuild,
			Stage = function(box: Box)
				local on_ = stageIn(frame, UDim2.fromOffset(box.X, box.Y), UDim2.fromOffset(box.Wide, box.Tall))
				Figure.Wings(on_)
				local there = table.clone(at)
				there.Stage = box
				dress(on_, owned.Def, roster, there)
			end,
			Name = function(over: Frame, wide: number): (() -> boolean)?
				return nameLine(over, Theme.Size.Pad, wide - Theme.Size.Pad * 2, owned, on)
			end,
			Power = function(feet: Frame, wide: number)
				power(feet, owned, block, wide)
			end,
		})
		wallet(band, pageName(band, marks(band, owned, on, save)), view)
		return
	end
	local where, size = UDim2.fromOffset(at.Stage.X, at.Stage.Y), UDim2.fromOffset(at.Stage.Wide, at.Stage.Tall)
	local on_ = stageIn(frame, where, size)
	Figure.Wings(on_)
	dress(on_, owned.Def, roster, at)
	-- Over the stage, in the body: its name, and Combat Power at its feet.
	local over = frameOf("Over", body, where, size)
	feet(over, at, owned, (resolved(view, owned)))
	-- The band: Back is the kit's; its marks beside it, the currencies at the right.
	wallet(band, pageName(band, marks(band, owned, on, nameLine(over, at.Group, at.Span, owned, on))), view)
	strip(body, at, roster, on)
	actions(frameOf("Actions", body, UDim2.fromOffset(at.Panel.X, Theme.Size.Pad), UDim2.fromOffset(at.Panel.Wide, ROW)), view, owned, on)
	sheetWide = at.Panel.Wide - Theme.Size.Pad * 2 - 8
	-- The kit's panel (AR43's take 2, voidkin_b.json, panel): PanelFill in the screen's Panel, its sheen, its edge lit from
	-- above, its corner's glint.
	local sheet = Glass.Panel(body, "Panel", at.Panel.X, at.Panel.Y, at.Panel.Wide, at.Panel.Tall, Seam.Kit, 2)
	sheet.Active = true -- a tap on the panel stays on it
	local inside = frameOf("Inside", sheet, UDim2.fromOffset(Theme.Size.Pad, Theme.Size.Pad), UDim2.new(1, -Theme.Size.Pad * 2, 1, -Theme.Size.Pad * 2))
	inside.ZIndex = 10 -- over the panel's layers, its siblings
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
		chosen, page, slideFrom, shownPower = nil, if on.Page and table.find(PAGES, on.Page) and not SOON[on.Page] then on.Page else "Bag", 0, {}
		named = on.Said or SAID[page] or page
		editing, draft, awaited = false, nil, nil
		railShown = nil
		BagPage.Reset()
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

-- The page last shown, where Home's Voidkin card opens it (AR49); `set` puts one there (a test's start).
function VoidkinScreen.Last(set: string?): string
	if set and Screen.Current() ~= NAME and table.find(PAGES, set) and not SOON[set] then
		page = set
	end
	return page
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
function VoidkinScreen.Measure(): { Height: number, Stage: number, Power: number }
	return table.clone(measured)
end

VoidkinScreen.Name = NAME
VoidkinScreen.Pages = PAGES
VoidkinScreen.Soon = SOON
VoidkinScreen.Said = SAID
VoidkinScreen.Kinds = BagRules.Kinds
VoidkinScreen.Bag = BagPage

return VoidkinScreen
