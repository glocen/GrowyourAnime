--!strict
-- VoidkinScreen (client): one Voidkin at a time, a character to show off (TR17, research's entry and feel line;
-- docs/research/voidkin-screen.md, "DESIGN"; docs/ui.md, "The screens of the first loop", 4 and 5). In grey, three
-- layouts for the blockout's verdict, tuned live (Config.Hud.Voidkin.Layout): Stage, Flank and Rail. In each:
--   its own model, live, on a stage lit by its rarity, the floor glowing its element (Figure): a drag turns it, a tap
--     plays the end of its Reveal, a flick goes to the next or the one before;
--   Combat Power at its feet (Rules.Stats.Power; a tap shows the Stats tab);
--   the panel's tabs, Overview, Stats, Kit and Stars, on the save's own numbers;
--   Lead (or Leading) and Send to work (or Bring home), always in view; favourite, lock and rename beside its name;
--   the portraits of every Voidkin owned, a tap on one to switch.
-- The dock's Voidkin opens it on the lead. Every change is asked of the server through the owner's Act, and the screen is
-- rebuilt from the server's copy, the figure kept as long as it's the same Voidkin. TR15's stat board was taken out on
-- the director's word (2026-11-14, night: "Remove now, tree later").
--   VoidkinScreen.Open(view, on)   builds it; again on each change of the save
--   VoidkinScreen.Tick()           each frame: a tuned layout, a healing clock
--   For tests and takes: Choose(id), Chosen(), Show(tab), Slide(open), Figure(), Find(name), Measure()

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
local VoidkinConfig = require(Shared.Config.Voidkin)
local Voidkin = require(Shared.Definitions.Voidkin)
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
local Figure = require(script.Figure)

local VoidkinScreen = {}

export type On = { Act: (name: string, args: any) -> { [string]: any }, Healing: () -> { [string]: number } }

local NAME = "Voidkin"
local TABS = { "Overview", "Stats", "Kit", "Stars" }
local ROW = Theme.Size.Tap -- a row of buttons, authored
local CLOSE = 72 -- the screen's close button's width, authored (UI/Kit/Screen)
local SIDE = 72 -- Flank's columns, authored
local MARK = 64 -- favourite, lock and rename, each, authored
local SHOWN = { "Health", "Attack", "Defence", "Regen" } -- always on the Stats tab; a rating shows once it's above 0
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
local tab = "Overview"
local panelOpen = false -- Flank's panel
local editing = false -- the name's row is a box to type a nickname in
local draft: string? = nil -- what's typed there, kept across a rebuild
local built: string? = nil -- the layout built
local builtRoom = Vector2.zero -- and the room it was built in
local lastView: Profile.View? = nil
local lastOn: On? = nil
local slideFrom = 0 -- where the next figure comes in from
local figure: Figure.Figure? = nil
local stage: Frame? = nil -- the figure's stage, in the screen's panel beside its body: kept across rebuilds
local measured = { Height = 0, Stage = 0 }
local tickers: { () -> () } = {}
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

-- Where each piece stands in a layout, in the panel's own frame (a bare screen: the body is the whole panel).
type Rects = {
	Stage: { UDim2 },
	Strip: { UDim2 },
	Panel: { UDim2 }?,
	Name: { UDim2 }?, -- the name's row outside the panel (Flank)
	Kit: { UDim2 }?, -- Flank's columns
	Stars: { UDim2 }?,
	Horizontal: boolean, -- the strip's way
	Top: number, -- authored pixels over the stage kept clear of the figure's crown
	StageHeight: number, -- authored
}

local function rects(layout: string, size: Vector2, open: boolean): Rects
	local pad, gap = Theme.Size.Pad, Theme.Size.Gap
	local config = HudConfig.Voidkin
	local strip, share = config.Strip, config.Panel
	local fullPanel = { UDim2.new(1 - share, gap / 2, 0, pad), UDim2.new(share, -(pad + gap / 2), 1, -pad * 2) }
	if layout == "Rail" then
		return {
			Strip = { UDim2.fromOffset(pad, pad), UDim2.new(0, strip, 1, -pad * 2) },
			Stage = { UDim2.fromOffset(pad + strip + gap, pad), UDim2.new(1 - share, -(pad + strip + gap * 1.5), 1, -pad * 2) },
			Panel = fullPanel,
			Horizontal = false,
			Top = pad,
			StageHeight = size.Y - pad * 2,
		}
	elseif layout == "Flank" then
		local left = pad + SIDE + gap
		local tall = -(strip + pad * 2 + gap)
		return {
			Strip = { UDim2.new(0, pad, 1, -(strip + pad)), UDim2.new(1, -pad * 2, 0, strip) },
			Stage = if open
				then { UDim2.fromOffset(left, pad), UDim2.new(1 - share, -(left + gap / 2), 1, tall) }
				else { UDim2.fromOffset(left, pad), UDim2.new(1, -left * 2, 1, tall) },
			Panel = if open
				then { UDim2.new(1 - share, gap / 2, 0, pad), UDim2.new(share, -(pad + gap / 2), 1, tall) }
				else { UDim2.new(1, pad, 0, pad), UDim2.new(share, -(pad + gap / 2), 1, tall) },
			Name = { UDim2.fromOffset(pad, pad), UDim2.fromOffset(SIDE + gap + MARK * 3 + gap * 3 + 120, ROW) },
			Kit = { UDim2.fromOffset(pad, pad + ROW + gap), UDim2.new(0, SIDE, 1, tall - ROW - gap) },
			Stars = { UDim2.new(1, -(pad + SIDE), 0, pad + ROW + gap), UDim2.new(0, SIDE, 1, tall - ROW - gap) },
			Horizontal = true,
			Top = ROW + gap,
			StageHeight = size.Y + tall,
		}
	end
	local tall = -(strip + pad * 2 + gap)
	return { -- Stage
		Strip = { UDim2.new(0, pad, 1, -(strip + pad)), UDim2.new(1 - share, -(pad + gap / 2), 0, strip) },
		Stage = { UDim2.fromOffset(pad, pad), UDim2.new(1 - share, -(pad + gap / 2), 1, tall) },
		Panel = fullPanel,
		Horizontal = true,
		Top = pad,
		StageHeight = size.Y + tall,
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
	tab = name
	panelOpen = true
	rebuild()
end

-- The figure's stage: its backing lit from below by its rarity, kept in the panel across rebuilds.
local function stageIn(frame: Frame, position: UDim2, size: UDim2, animate: boolean): Frame
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
	elseif animate then
		TweenService:Create(made, TweenInfo.new(HudConfig.Voidkin.Ease, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = position,
			Size = size,
		}):Play()
	else
		made.Position, made.Size = position, size
	end
	return made :: Frame
end

-- The stage lit for `def`, and its figure, new when it's another Voidkin's.
local function dress(on: Frame, def: string, roster: { Profile.OwnedVoidkin }, r: Rects)
	local row = Voidkin.ById[def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
	local light = on:FindFirstChild("Light") :: UIGradient
	light.Color = ColorSequence.new(Theme.Colour.Backing, Theme.Colour.Backing:Lerp(trim, 0.35))
	local halo = on:FindFirstChild("Halo") :: Frame
	halo.BackgroundColor3 = trim
	halo.BackgroundTransparency = 0.82
	local config = HudConfig.Voidkin
	local room = Layers.Get("Menus").AbsoluteSize.Y / Layers.Scale() -- the screens' room, as the Screen kit fits them
	local stageHeight = math.max(r.StageHeight, 1)
	local feet = 1 - (config.Power.Height + 2) / stageHeight
	local top = r.Top / stageHeight
	local height = math.clamp(config.Figure.Height * room / stageHeight, 0.2, math.max(0.2, feet - top))
	halo.Position = UDim2.fromScale(0.5, feet - height * 0.55)
	measured = { Height = height * stageHeight / room, Stage = stageHeight }
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

-- Lead (or Leading) and Send to work (or Bring home) along the foot of `parent`: in its two corners when `apart`,
-- else side by side across `share` of its width.
local function actions(parent: Instance, view: Profile.View, owned: Profile.OwnedVoidkin, on: On, apart: boolean, share: number?)
	local gap = Theme.Size.Gap
	local at = Read.Role(view, owned.Id)
	local half = (share or 1) / 2
	local width = if apart then UDim2.fromOffset(112, ROW) else UDim2.new(half, -gap / 2, 0, ROW)
	local lead = Button.new({
		Name = "Lead",
		Text = if at == "Lead" then "Leading" else "Lead",
		Size = width,
		Position = UDim2.new(0, 0, 1, -ROW),
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
		Position = if apart then UDim2.new(1, -112, 1, -ROW) else UDim2.new(half, gap / 2, 1, -ROW),
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
-- up from the old number and floats the gain off the plate's end. In grey: the look is Modulo's after the pick. A tap
-- shows where it comes from.
local function power(parent: Instance, owned: Profile.OwnedVoidkin, block: Stats.Block)
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
	press.Size = UDim2.fromOffset(config.Width, config.Height)
	press.Parent = parent
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
	emblem.Parent = press
	local left = 56
	text({ Name = "Caption", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Box = UDim2.new(1, -left, 0, 16), Position = UDim2.fromOffset(left, 2), Parent = press }, "Combat Power")
	local number = text({ Name = "Number", Size = config.Number, Font = Theme.Font.Number, Box = UDim2.new(1, -left, 0, config.Number + 2), Position = UDim2.fromOffset(left, 16), Parent = press }, Hud.Digits(value))
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
	press.Activated:Connect(function()
		show("Stats")
	end)
end

-- One line of a tab: what it is on the left, its number on the right, and under them a quieter line.
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
	local now = line(scroll, 3, "Now", nil, role(view, owned, on, workspace:GetServerTimeNow()))
	local nowLabel = now:FindFirstChild("Under") :: TextLabel
	table.insert(tickers, function()
		nowLabel.Text = role(view, owned, on, workspace:GetServerTimeNow())
	end)
	if owned.Nickname ~= "" then
		local own = Voidkin.ById[owned.Def]
		line(scroll, 4, "Its own name", nil, if own then own.Name else owned.Def)
	end
end

local function statsTab(scroll: ScrollingFrame, view: Profile.View, owned: Profile.OwnedVoidkin)
	local block, lines = resolved(view, owned)
	local from: { [string]: { [string]: number } } = {}
	for _, each in lines do
		local source = SOURCES[each.Source] or "Gear"
		local by = from[each.Stat] or {}
		by[source] = (by[source] or 0) + each.Value
		from[each.Stat] = by
	end
	local order = 0
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

-- The tabs and the chosen one's content, filling `parent` over a footer row.
local function panelBody(parent: Frame, view: Profile.View, owned: Profile.OwnedVoidkin, on: On, top: number, right: number, footer: boolean)
	local gap = Theme.Size.Gap
	local tabs = frameOf("Tabs", parent, UDim2.fromOffset(0, top), UDim2.new(1, -right, 0, ROW))
	list(tabs, true)
	for index, name in TABS do
		local button = Button.new({
			Name = name,
			Text = name,
			Size = UDim2.new(1 / #TABS, -gap * (#TABS - 1) / #TABS, 0, ROW),
			LayoutOrder = index,
			Parent = tabs,
			TextSize = Theme.Text.Caption,
			OnPress = function()
				show(name)
			end,
		})
		Button.Set(button, { Selected = name == tab })
	end
	local under = top + ROW + gap
	local scroll = scroller("Tab", parent, UDim2.fromOffset(0, under), UDim2.new(1, 0, 1, -(under + (if footer then ROW + gap else 0))), false)
	scroll:SetAttribute("Keep", `{owned.Id}{tab}`)
	if tab == "Stats" then
		statsTab(scroll, view, owned)
	elseif tab == "Kit" then
		kitTab(scroll, owned)
	elseif tab == "Stars" then
		starsTab(scroll, view, owned, on)
	else
		overview(scroll, view, owned, on)
	end
end

local function strip(body: Instance, r: Rects, roster: { Profile.OwnedVoidkin }, on: On)
	local cell = HudConfig.Voidkin.Strip
	local scroll = scroller("Strip", body, r.Strip[1], r.Strip[2], r.Horizontal)
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

-- Flank's columns: the kit's three, then its stars, each a tap from the panel.
local function columns(body: Instance, r: Rects, owned: Profile.OwnedVoidkin)
	local kit = frameOf("KitColumn", body, (r.Kit :: { UDim2 })[1], (r.Kit :: { UDim2 })[2])
	list(kit, false)
	for index, name in { "Skill", "Combo", "Passive" } do
		Button.new({ Name = name, Text = name, Size = UDim2.fromOffset(SIDE, ROW), LayoutOrder = index, Parent = kit, TextSize = Theme.Text.Caption, OnPress = function()
			show("Kit")
		end })
	end
	local stars = Instance.new("TextButton")
	stars.Name = "StarsColumn"
	stars.Text = ""
	stars.AutoButtonColor = false
	stars.BackgroundTransparency = 1
	stars.Position, stars.Size = (r.Stars :: { UDim2 })[1], (r.Stars :: { UDim2 })[2]
	stars.Parent = body
	list(stars, false)
	local row = Voidkin.ById[owned.Def]
	local trim = HudConfig.Card.Trim[if row then row.Rarity else "Common"] or Theme.Colour.Line
	for index = 1, VoidkinConfig.MaxStars do
		local pip = Instance.new("Frame")
		pip.Name = `Star{index}`
		pip.LayoutOrder = VoidkinConfig.MaxStars - index
		pip.Size = UDim2.fromOffset(18, 18)
		pip.BorderSizePixel = 0
		pip.Rotation = 45
		pip.BackgroundColor3 = if index <= owned.Stars then trim else Theme.Colour.PlateHigh
		pip.Parent = stars
	end
	local layout = stars:FindFirstChildOfClass("UIListLayout") :: UIListLayout
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stars.Activated:Connect(function()
		show("Stars")
	end)
end

local function build(view: Profile.View, on: On, animate: boolean?)
	lastView, lastOn = view, on
	tickers = {}
	local config = HudConfig.Voidkin
	local layout = config.Layout
	if built ~= layout then
		panelOpen = false
	end
	built = layout
	builtRoom = Layers.Get("Menus").AbsoluteSize
	local roster = Read.Roster(view)
	if chosen == nil or view.Voidkin[chosen :: string] == nil then
		local lead = view.Roles.Lead
		chosen = if lead ~= "" and view.Voidkin[lead] then lead elseif roster[1] then roster[1].Id else nil
	end
	local body = Screen.Open(NAME, "Voidkin", config.Size, true)
	local frame = Screen.Frame(NAME) :: Frame
	local owned = if chosen then view.Voidkin[chosen :: string] else nil
	if owned == nil then
		if stage then
			stage:Destroy()
			stage = nil
		end
		text({ Name = "Empty", Size = Theme.Text.Title, Align = Enum.TextXAlignment.Center, Box = UDim2.new(1, -CLOSE * 2, 0, 30), Position = UDim2.new(0, CLOSE, 0.5, -15), Parent = body }, "No Voidkin yet · break a shard at the Breaker")
		return
	end
	local size = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
	local r = rects(layout, size, panelOpen)
	local on_ = stageIn(frame, r.Stage[1], r.Stage[2], animate == true)
	dress(on_, owned.Def, roster, r)
	local block = resolved(view, owned)
	-- Over the stage, in the body: what stands at the figure's feet.
	local over = frameOf("Over", body, r.Stage[1], r.Stage[2])
	if animate then
		over.Position, over.Size = on_.Position, on_.Size
		TweenService:Create(over, TweenInfo.new(config.Ease, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = r.Stage[1], Size = r.Stage[2] }):Play()
	end
	power(over, owned, block)
	strip(body, r, roster, on)
	local gap = Theme.Size.Gap
	if layout == "Flank" and not panelOpen then -- with the panel in, they stand on its foot
		actions(over, view, owned, on, true)
	end
	if layout == "Flank" then
		nameRow(body, (r.Name :: { UDim2 })[1], (r.Name :: { UDim2 })[2], owned, on)
		columns(body, r, owned)
	end
	local place = r.Panel :: { UDim2 }
	local sheet = Panel.new({ Name = "Panel", Size = place[2], Position = place[1], Parent = body })
	sheet.Active = true -- a tap on the panel stays on it
	if animate and layout == "Flank" then
		sheet.Position = (rects(layout, size, not panelOpen).Panel :: { UDim2 })[1]
		TweenService:Create(sheet, TweenInfo.new(config.Ease, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = place[1] }):Play()
	end
	local inside = frameOf("Inside", sheet, UDim2.fromOffset(Theme.Size.Pad, Theme.Size.Pad), UDim2.new(1, -Theme.Size.Pad * 2, 1, -Theme.Size.Pad * 2))
	if layout == "Flank" then
		-- Hide beside the screen's close, the tabs the panel's width under them, Lead and Send to work on its foot.
		Button.new({ Name = "Hide", Text = "Hide", Size = UDim2.fromOffset(96, ROW), Parent = inside, OnPress = function()
			VoidkinScreen.Slide(false)
		end })
		panelBody(inside, view, owned, on, ROW + gap, 0, true)
		if panelOpen then
			actions(inside, view, owned, on, false)
		end
		sheet.Visible = panelOpen or animate == true
		if animate and not panelOpen then
			task.delay(config.Ease, function()
				if sheet.Parent and not panelOpen then
					sheet.Visible = false
				end
			end)
		end
	else
		nameRow(inside, UDim2.new(), UDim2.new(1, -(CLOSE + gap), 0, ROW), owned, on)
		panelBody(inside, view, owned, on, ROW + gap, 0, true)
		actions(inside, view, owned, on, false)
	end
end

rebuild = function()
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn)
	end
end

function VoidkinScreen.Open(view: Profile.View, on: On)
	if Screen.Current() ~= NAME then -- a fresh open starts on the lead's Overview, never on a choice left from before
		chosen, tab, panelOpen, slideFrom, shownPower = nil, "Overview", false, 0, {}
		editing, draft = false, nil
	end
	build(view, on)
end

function VoidkinScreen.Tick()
	if Screen.Current() ~= NAME then
		return
	end
	if built ~= HudConfig.Voidkin.Layout or Layers.Get("Menus").AbsoluteSize ~= builtRoom then -- tuned, or the room changed
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

-- Flank's panel in or out, sliding, the figure easing to make room.
function VoidkinScreen.Slide(open: boolean)
	if open == panelOpen then
		return
	end
	panelOpen = open
	if lastView and lastOn and Screen.Current() == NAME then
		build(lastView, lastOn, true)
	end
end

function VoidkinScreen.Figure(): Figure.Figure?
	return if Screen.Current() == NAME then figure else nil
end

-- A piece of the open screen by its name, anywhere in it: for tests and takes.
function VoidkinScreen.Find(name: string): Instance?
	local frame = Screen.Frame(NAME)
	return if frame then frame:FindFirstChild(name, true) else nil
end

-- The figure's share of the screen's height as framed, and its stage's authored height: for tests and takes.
function VoidkinScreen.Measure(): { Height: number, Stage: number }
	return table.clone(measured)
end

VoidkinScreen.Name = NAME
VoidkinScreen.Refused = REFUSED
VoidkinScreen.Tabs = TABS

return VoidkinScreen
