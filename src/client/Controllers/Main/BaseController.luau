--!strict
-- BaseController (client): the player's own base, in grey (docs/test-requests.md, TR2, items 1, 2 and 7; docs/ui.md,
-- "The screens of the first loop", 2, 3 and 7, in stock frames). On the plot: a prompt at the Breaker (Open while a shard
-- is ready, else the Breaker's own screen, UI/BreakerScreen, TR9), one at each open bay, and the three starter shards waiting in front of the Breaker until
-- one is chosen. Over the world: the Breaker's chambers counting down, each bay's worker and output, the battery's name.
-- A plate speaks only near its machine, or while it's lit with something to do (TR2, research's read of the phone take,
-- fix 2): the Breaker with a shard to put in or to open, a bay that a free Voidkin could work. The Base
-- screen: the chambers, the line, what's ready, the bag, the bays and who works in them. Opening a shard shows the reveal:
-- the ceremony at its rarity (UI/Reveal, TR4), then one card with the name. Every change is asked of the server (ProfileController.Act) and shown only
-- once it answers; the prompts are this player's alone, so a visitor can look and never touch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local RevealConfig = require(Shared.Config.Reveal)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Power = require(Shared.Rules.Power)
local Markers = require(Shared.World.Markers)
local Kit = require(Shared.World.Kit)
local WorldConfig = require(Shared.Config.World)
local Parts = require(Shared.Util.Parts)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Read = require(UI.Read)
local World = require(UI.World)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Row = require(UI.Kit.Row)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local RevealStage = require(UI.Reveal)
local BreakerScreen = require(UI.BreakerScreen)
local PowerScreen = require(UI.PowerScreen)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)

local BaseController = {}

local player = Players.LocalPlayer

local FIND_EVERY = 1 -- seconds between looks for the plot's markers: they stream in, and a relaid world replaces them
local TICK = 0.25 -- seconds between countdown updates
local REACH = 140 -- studs from the camera a base's plates show: the plot and the Strip, never the street
local PROMPT_REACH = 10 -- studs from a prompt's spot it can be pressed
-- Studs, flat, from a machine's spot within which its plate speaks without news: the prompt's reach and a few steps. The
-- spawn stands 14 from the battery, so a player arriving home sees no plate that has nothing to say. A plate lets go
-- NEAR_SLACK farther out than it takes hold, so it never flickers at the edge.
local NEAR = PROMPT_REACH + 3
local NEAR_SLACK = 2
local BREAKER_UP = 7 -- studs over the Breaker's marker its prompt stands
local BREAKER_PLATE = 5.5 -- and its plate that much higher: over the gantry's lamp (11.5), clear of the chambers (AR15)
local BAY_UP = 4
local STARTER_OUT = 7 -- studs in front of the Breaker, toward the spawn, the starter shards wait
local STARTER_APART = 4
local STARTER_UP = 2.6
local STARTER_SIZE = Vector3.new(1.2, 2.2, 1.2)
local STARTER_SPIN = 0.6 -- radians a second each waiting shard turns
local CHOOSE_HOLD = 0.4 -- seconds a starter's prompt is held: a choice for good
local PLATE_LINE = 20 -- authored pixels a plate's line takes
-- Each plate as wide as its longest line at the smallest scale, where text draws at 17 authored (Text.Legible):
-- "Lantern Row shard · 1 min 59 s" is 222, "Bay 2 · nobody works here" 193 (measured 2026-11-12). The battery's plate
-- says only its name: the Electricity pill carries the count (TR2, research's read of the phone take, fix 3).
local BREAKER_WIDTH = 232
local BAY_WIDTH = 204
local BATTERY_WIDTH = 80
local MACHINE_WIDTH = 204 -- "Trains while you're away", as a bay's
local GENERATOR_UP = 9 -- studs over the generator's marker its plate and prompt stand: over its face
local GENERATOR_WIDTH = 180 -- "Generation 30 kW", "Demand 34 kW"
-- Wide enough that a row's name and its second line fit beside its button at the smallest scale: 191 authored pixels,
-- against "Intelligence · Mage · Fire" at 178 and "Chamber 2 · 1 min 59 s" at 164.
local SCREEN = Vector2.new(660, 320)

-- What a refusal says to the player, by its code (Rules.Base, Rules.Collection).
local REASON: { [string]: string } = {
	Chosen = "The first shard is already chosen",
	NoShard = "None of that shard in the bag",
	Empty = "Nothing there",
	Leading = "The lead can't work too",
	Working = "A worker can't lead too",
	Named = "That shard holds one Voidkin",
	Infused = "That shard already has its voltage",
	Short = "Not enough charge in the battery",
	Brief = "It would save under a minute",
	Closed = "The Power screen isn't open yet",
	Over = "The shares come to more than the whole",
	Moved = "That shard has moved on",
	BadArgs = "That can't be done",
	Unknown = "That can't be done",
}

-- Ground: the marker's spot on the floor. Near: the avatar stands within NEAR of it. News: it's lit with something to do.
type Spot = { Marker: Instance, Ground: Vector3, Anchor: Part, Prompt: ProximityPrompt?, Plate: Frame, Near: boolean, News: boolean }

local folder: Folder? = nil
local plot: number? = nil
local breaker: Spot? = nil
local battery: Spot? = nil
local machine: Spot? = nil -- the Training machine (TR12)
local generator: Spot? = nil -- the generator (TR18)
local bays: { [number]: Spot } = {}
local starters: { [string]: Part } = {}
local pickingBay: number? = nil
local countdowns: { { Label: TextLabel, Chamber: number, Prefix: string } } = {}
type Shown = { Frame: Instance, Stage: RevealStage.Handle, Card: Frame?, Carded: number, Name: string, Outcome: string }
local reveal: Shown? = nil

local function act(name: string, args: any?): { [string]: any }
	local answer = ProfileController.Act(name, args)
	if answer.Ok ~= true then
		Toast.Show(REASON[tostring(answer.Error)] or `Not now: {tostring(answer.Error)}`, Theme.Colour.TextDim)
	end
	return answer
end

local function base(): Folder
	if folder and folder.Parent then
		return folder
	end
	local made = Instance.new("Folder")
	made.Name = "NL_Base" -- this client's own: never replicated
	made.Parent = workspace
	folder = made
	return made
end

local function anchorAt(name: string, at: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Position = at
	part.Parent = base()
	return part
end

local function prompt(parent: Instance, name: string, object: string, actionText: string, hold: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ObjectText = object
	p.ActionText = actionText
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = PROMPT_REACH
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

-- Whether a spot's plate speaks now: it has news, or the avatar stands near it.
local function speaks(spot: Spot): boolean
	local root = Parts.Root(player.Character)
	if root == nil then
		spot.Near = false
	else
		local gap = root.Position - spot.Anchor.Position
		spot.Near = Vector2.new(gap.X, gap.Z).Magnitude <= (if spot.Near then NEAR + NEAR_SLACK else NEAR)
	end
	return spot.News or spot.Near
end

-- A plate over `anchor`, `lift` studs higher: a panel of `lines` text lines, filled by the caller, shown while `shown()`.
local function plate(name: string, anchor: Part, lines: number, width: number, shown: () -> boolean, lift: number?): Frame
	local over = Vector3.new(0, lift or 0, 0)
	local frame = World.Plate(name, Vector2.new(width, lines * PLATE_LINE + Theme.Size.Pad), function(): Vector3?
		return if anchor.Parent and shown() then anchor.Position + over else nil
	end, REACH)
	-- Kept under the top band: a machine high on screen put its news under the lead's card (the phone pack, 2026-11-13).
	World.Below(frame)
	local panel = Panel.new({ Name = "Panel", Size = UDim2.fromScale(1, 1), Parent = frame })
	panel.Visible = false -- until setLines gives it a line: at a join the save's copy comes a moment after the plot
	Panel.Pad(panel, 4, 10) -- clear of the panel's cut corner and its lit edge at the sides (TR3's take)
	Panel.List(panel, nil, 0)
	for index = 1, lines do
		local label = Text.new({ Name = `Line{index}`, Size = Theme.Text.Caption, Truncate = true, Box = UDim2.new(1, 0, 0, PLATE_LINE), Parent = panel })
		label.LayoutOrder = index
	end
	return frame
end

local function setLines(frame: Frame, lines: { string })
	local panel = frame:FindFirstChild("Panel") :: Frame?
	if panel == nil then
		return
	end
	local shown = 0
	for _, child in panel:GetChildren() do
		if child:IsA("TextLabel") then
			local index = tonumber(child.Name:match("^Line(%d+)$"))
			child.Text = if index then lines[index] or "" else ""
			child.Visible = child.Text ~= ""
			shown += if child.Visible then 1 else 0
		end
	end
	-- As tall as what it says, and gone when it says nothing.
	frame.Size = UDim2.fromOffset(frame.Size.X.Offset, shown * PLATE_LINE + Theme.Size.Pad)
	panel.Visible = shown > 0
end

local function clearSpot(spot: Spot?)
	if spot then
		World.Remove(spot.Plate)
		spot.Anchor:Destroy()
	end
end

local function clearAll()
	clearSpot(breaker)
	clearSpot(battery)
	clearSpot(machine)
	clearSpot(generator)
	for _, spot in bays do
		clearSpot(spot)
	end
	breaker, battery, machine, generator, bays = nil, nil, nil, nil, {}
	for _, part in starters do
		part:Destroy()
	end
	starters = {}
end

-- The Base screen ----------------------------------------------------------------------------------------------------

local build: () -> ()

local function column(body: Frame, name: string, heading: string, left: boolean): ScrollingFrame
	local half = UDim2.new(0.5, -Theme.Size.Gap / 2, 0, 22)
	local title = Text.new({ Name = `{name}Title`, Font = Theme.Font.Strong, Colour = Theme.Colour.TextDim, Box = half, Position = if left then UDim2.new() else UDim2.new(0.5, Theme.Size.Gap / 2, 0, 0), Parent = body })
	title.Text = heading
	return Row.List(body, name, UDim2.new(0.5, -Theme.Size.Gap / 2, 1, -26), if left then UDim2.fromOffset(0, 26) else UDim2.new(0.5, Theme.Size.Gap / 2, 0, 26))
end

local function openShard(index: number?)
	local answer = act("Open", if index then { Index = index } else nil)
	if answer.Ok == true then
		BaseController.Reveal(answer)
	end
end

-- A broken shard opened, the oldest unless `index`, as the Breaker's prompt and its screen open one: the reveal shows
-- only once the server says it opened (a refusal is a toast).
function BaseController.OpenShard(index: number?)
	openShard(index)
end

local function breakerRows(list: ScrollingFrame, view: Profile.View, now: Read.Base)
	local order = 0
	local function add(props: any): Frame
		order += 1
		props.Parent = list
		props.Order = order
		return Row.new(props)
	end
	if view.Progress.Starter == "" then
		for _, id in Shards.Starters do
			local holds = Shards.ById[id].Holds
			add({
				Name = id,
				Text = Voidkin.ById[holds].Name,
				Detail = Read.VoidkinLine(holds, false), -- the three are Common: the rarity tells nothing between them
				Action = "Choose",
				Primary = true,
				OnPress = function()
					act("ChooseStarter", { Shard = id })
				end,
			})
		end
		return
	end
	-- Identical shards ready to open share one row with their count; Open opens the first of them in the save's order.
	local kinds: { string } = {}
	local counts: { [string]: number } = {}
	for _, work in view.Base.Ready do
		if counts[work.Def] == nil then
			table.insert(kinds, work.Def)
		end
		counts[work.Def] = (counts[work.Def] or 0) + 1
	end
	for _, def in kinds do
		local count = counts[def]
		add({
			Name = `Ready_{def}`,
			Text = Read.ShardName(def),
			Detail = if count > 1 then `Ready to open · {count}` else "Ready to open",
			Colour = Theme.Colour.Ready,
			Action = "Open",
			Primary = true,
			OnPress = function()
				local current = ProfileController.Get()
				for index, work in (if current then current.Base.Ready else {}) do
					if work.Def == def then
						openShard(index)
						return
					end
				end
			end,
		})
	end
	for index, chamber in now.Data.Base.Chambers do
		local work = chamber.Work
		if work then
			local prefix = `Chamber {index}`
			local row = add({ Name = `Chamber{index}`, Text = Read.ShardName(work.Def), Detail = `{prefix} · {Read.Seconds(Read.Left(now, work))}`, Action = "Take out", OnPress = function()
				act("TakeOut", { Chamber = index })
			end })
			table.insert(countdowns, { Label = row:FindFirstChild("Detail") :: TextLabel, Chamber = index, Prefix = prefix })
		else
			add({ Name = `Chamber{index}`, Text = `Chamber {index} · empty`, Colour = Theme.Colour.TextDim })
		end
	end
	for index, work in now.Data.Base.Line do
		add({ Name = `Line{index}`, Text = Read.ShardName(work.Def), Detail = "Waiting in line", Colour = Theme.Colour.TextDim })
	end
end

local function bayRows(list: ScrollingFrame, view: Profile.View, now: Read.Base)
	local order = 0
	local function add(props: any)
		order += 1
		props.Parent = list
		props.Order = order
		Row.new(props)
	end
	local picking = pickingBay
	if picking and view.Base.Bays[picking] then
		local current = view.Base.Bays[picking].Worker
		for _, owned in Read.Roster(view) do
			local role = Read.Role(view, owned.Id)
			local here = current == owned.Id
			add({
				Name = owned.Id,
				Text = Read.VoidkinName(owned),
				Detail = `Lv {owned.Level} · {Read.Kw(Power.Output(owned))}`,
				Action = "Work",
				Primary = true,
				Disabled = if here then "Here" elseif role == "Lead" then "Leading" else nil,
				OnPress = function()
					if act("SetWorker", { Bay = picking, Voidkin = owned.Id }).Ok == true then
						pickingBay = nil
						build()
					end
				end,
			})
		end
		if current ~= "" then
			add({ Name = "Empty", Text = "Nobody works here", Action = "Empty", OnPress = function()
				if act("SetWorker", { Bay = picking, Voidkin = "" }).Ok == true then
					pickingBay = nil
					build()
				end
			end })
		end
		add({ Name = "Back", Text = `Bay {picking}: who works?`, Colour = Theme.Colour.TextDim, Action = "Back", OnPress = function()
			pickingBay = nil
			build()
		end })
		return
	end
	local shards = {}
	for id, count in view.Bag.Shards do
		if count > 0 then
			table.insert(shards, id)
		end
	end
	table.sort(shards)
	for _, id in shards do
		add({ Name = id, Text = Read.ShardName(id), Detail = `{view.Bag.Shards[id]} in the bag`, Action = "Add", Disabled = if view.Progress.Starter == "" then "First, choose" else nil, OnPress = function()
			act("AddShard", { Shard = id })
		end })
	end
	if #shards == 0 then
		add({ Name = "Bag", Text = "No shards yet", Detail = "They drop on Lantern Row", Colour = Theme.Colour.TextDim })
	end
	for index, bay in view.Base.Bays do
		local worker = if bay.Worker ~= "" then view.Voidkin[bay.Worker] else nil
		local detail = if worker then `{Read.VoidkinName(worker)} · {Read.Kw(Power.Output(worker))}` else "Nobody works here"
		add({ Name = `Bay{index}`, Text = `Bay {index}`, Detail = detail, Action = "Set", OnPress = function()
			pickingBay = index
			build()
		end })
	end
	for index in bays do
		if index > #view.Base.Bays then
			add({ Name = `Bay{index}`, Text = `Bay {index} · locked`, Colour = Theme.Colour.TextDim })
		end
	end
	local charge = now.Data.Base.Charge
	add({ Name = "Battery", Text = "Battery", Detail = `{Read.Kwh(charge)} / {Read.Number(BaseConfig.Battery.Capacity)} kWh · {Read.Kw(now.Rates.NetKw, true)}`, Colour = Theme.Colour.Electricity })
end

build = function()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	countdowns = {}
	local now = Read.Base(view, workspace:GetServerTimeNow())
	local body = Screen.Open("Base", "Base", SCREEN)
	breakerRows(column(body, "Breaker", if view.Progress.Starter == "" then "Choose your first shard" else "Void Breaker", true), view, now)
	bayRows(column(body, "Bays", if pickingBay then "Who works?" else "Bag and bays", false), view, now)
end

function BaseController.Open()
	pickingBay = nil
	build()
end

-- The Void Breaker's own screen (TR9, UI/BreakerScreen): the chambers, what's ready, waiting and in the bag, a shard's
-- odds and its infusion.
function BaseController.OpenBreaker()
	local view = ProfileController.Get()
	if view then
		BreakerScreen.Open(view, { Act = act, Open = openShard })
	end
end

-- The Power screen (TR18, UI/PowerScreen), from the generator's prompt: only once it's open to the player (the server
-- refuses a split before). For tests too.
function BaseController.OpenPower()
	local view = ProfileController.Get()
	if view and view.Base.Power.Open then
		PowerScreen.Open(view, { Act = act })
	end
end

-- The Breaker's prompt, pressed: the oldest shard ready opens, else the Breaker's own screen. For tests too.
function BaseController.PressBreaker()
	local view = ProfileController.Get()
	if view and #view.Base.Ready > 0 then
		openShard(nil)
	else
		BaseController.OpenBreaker()
	end
end

-- The reveal -----------------------------------------------------------------------------------------------------------

-- A tap: shut for the skip's first second; in the ceremony, to its held frame and the card; on the card, once it has
-- stood Config.Reveal.CardHold, closed.
local function tap()
	local shown = reveal
	if shown == nil then
		return
	end
	if shown.Card == nil then
		shown.Stage.Skip()
	elseif os.clock() - shown.Carded >= RevealConfig.CardHold then
		shown.Stage.Destroy()
		shown.Frame:Destroy()
		reveal = nil
	end
end

-- The card that's there today, over the ceremony's held frame: new, a copy, or sold for Credits.
local function card(shown: Shown, answer: { [string]: any }, row: Voidkin.Row?)
	local cover = shown.Frame :: TextButton
	cover.BackgroundTransparency = Theme.Transparency.Dim
	local def = tostring(answer.Def)
	local cardFrame = Panel.new({ Name = "Card", Size = UDim2.fromOffset(320, 176), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = cover })
	Panel.Pad(cardFrame, Theme.Size.Pad * 2)
	Panel.List(cardFrame, nil, 2)
	local outcome = shown.Outcome
	type Line = { Name: string, Text: string, Size: number, Colour: Color3, Font: Font }
	local note = if answer.Lead == true then "Your lead: it fights beside you"
		elseif outcome == "Copy" then "One more toward its next star"
		elseif outcome == "Sold" then `Sold for {Read.Number(tonumber(answer.Credits) or 0)} Credits`
		else "In your collection"
	local kind = if outcome == "New" then "A new Voidkin" elseif outcome == "Copy" then "A copy" else "Already at its last star"
	local lines: { Line } = {
		{ Name = "Kind", Text = kind, Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Font = Theme.Font.Body },
		{ Name = "Name", Text = shown.Name, Size = Theme.Text.Big, Colour = Theme.Colour.Text, Font = Theme.Font.Strong },
		{ Name = "Line", Text = Read.VoidkinLine(def), Size = Theme.Text.Body, Colour = Theme.Colour.TextDim, Font = Theme.Font.Body },
		{ Name = "Note", Text = note, Size = Theme.Text.Body, Colour = Theme.Colour.Ready, Font = Theme.Font.Body },
		{ Name = "Skip", Text = "", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Font = Theme.Font.Body },
	}
	for order, line in lines do
		local label = Text.new({ Name = line.Name, Size = line.Size, Colour = line.Colour, Font = line.Font, Box = UDim2.new(1, 0, 0, line.Size + 8), Parent = cardFrame })
		label.LayoutOrder = order
		label.Text = line.Text
	end
	shown.Card, shown.Carded = cardFrame, os.clock()
	task.delay(RevealConfig.CardHold, function()
		local skip = cardFrame:FindFirstChild("Skip") :: TextLabel?
		if skip and reveal == shown then
			skip.Text = "Tap to continue"
		end
	end)
end

-- What Open uncovered (Rules.Base.Open's answer): the ceremony at its rarity (UI/Reveal), then its card.
-- `show` sets the stage's own options (its rarity, name and body) in place of the definition's: the test bridge's Show.
function BaseController.Reveal(answer: { [string]: any }, show: RevealStage.Options?)
	if reveal then
		reveal.Stage.Destroy()
		reveal.Frame:Destroy()
		reveal = nil
	end
	local def = tostring(answer.Def)
	local row = Voidkin.ById[def]
	local name = if row then row.Name else def
	local shown: Shown
	local options: RevealStage.Options = show or { Rarity = if row then row.Rarity else "Common", Name = name, Model = if row then row.Model else nil }
	local stage = RevealStage.Play(options, function()
		if reveal == shown then
			card(shown, answer, row)
		end
	end)
	local cover = Instance.new("TextButton")
	cover.Name = "RevealTap"
	cover.Text = ""
	cover.AutoButtonColor = false
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Theme.Colour.Backing
	cover.BackgroundTransparency = 1
	cover.BorderSizePixel = 0
	cover.ZIndex = 10
	cover.Parent = stage.Root
	shown = { Frame = cover :: Instance, Stage = stage, Card = nil :: Frame?, Carded = 0, Name = name, Outcome = tostring(answer.Outcome) }
	reveal = shown
	cover.Activated:Connect(tap)
end

-- For tests: the reveal on screen (its ceremony's time, and whether its card shows), a tap as a player's, and closing it
-- outright.
function BaseController.Revealed(): { Name: string, Outcome: string, Time: number, Card: boolean }?
	local shown = reveal
	return if shown then { Name = shown.Name, Outcome = shown.Outcome, Time = shown.Stage.Time(), Card = shown.Card ~= nil } else nil
end

function BaseController.Tap()
	tap()
end

-- The reveal's clock pinned at `t` seconds from the tap, or let run on (nil): for tests and captures.
function BaseController.Seek(t: number?)
	local shown = reveal
	if shown then
		shown.Stage.Seek(t)
	end
end

function BaseController.Dismiss()
	local shown = reveal
	if shown then
		shown.Stage.Destroy()
		shown.Frame:Destroy()
		reveal = nil
	end
end

-- The plot -------------------------------------------------------------------------------------------------------------

local function spotFor(marker: Instance, name: string, up: number, lines: number, width: number, lift: number?): Spot
	local ground = Markers.At(marker).Position
	local anchor = anchorAt(name, ground + Vector3.new(0, up, 0))
	local spot: Spot = { Marker = marker, Ground = ground, Anchor = anchor, Prompt = nil, Plate = nil :: any, Near = false, News = false }
	spot.Plate = plate(name, anchor, lines, width, function(): boolean
		return speaks(spot)
	end, lift)
	return spot
end

local function stale(spot: Spot?, marker: Instance?): boolean
	return spot == nil or marker == nil or spot.Marker ~= marker or spot.Marker.Parent == nil
end

-- Finds the plot's markers, and lays the prompts and plates on them again when they changed.
local function find()
	local number = player:GetAttribute("Plot")
	if type(number) ~= "number" then
		if plot then
			clearAll()
			plot = nil
		end
		return
	end
	local breakerMarker = Markers.Find("Breaker", { Plot = number })
	local batteryMarker = Markers.Find("Battery", { Plot = number })
	local machineMarker = Markers.Find("Training", { Plot = number })
	local generatorMarker = Markers.Find("Generator", { Plot = number })
	local bayMarkers: { [number]: Instance } = {}
	for _, marker in Markers.All("Bay") do
		local index = marker:GetAttribute("Bay")
		if marker:GetAttribute("Plot") == number and type(index) == "number" then
			bayMarkers[index] = marker
		end
	end
	local changed = number ~= plot or stale(breaker, breakerMarker) or stale(battery, batteryMarker)
		or (machineMarker ~= nil and stale(machine, machineMarker))
		or (generatorMarker ~= nil and stale(generator, generatorMarker))
	for index, marker in bayMarkers do
		changed = changed or stale(bays[index], marker)
	end
	if not changed or breakerMarker == nil then
		return
	end
	clearAll()
	plot = number
	local b = spotFor(breakerMarker, "Breaker", BREAKER_UP, 4, BREAKER_WIDTH, BREAKER_PLATE)
	b.Prompt = prompt(b.Anchor, "NL_Breaker", "Void Breaker", "Breaker")
	;(b.Prompt :: ProximityPrompt).Triggered:Connect(function()
		BaseController.PressBreaker()
	end)
	breaker = b
	if batteryMarker then
		battery = spotFor(batteryMarker, "Battery", BAY_UP, 1, BATTERY_WIDTH)
	end
	if machineMarker then
		machine = spotFor(machineMarker, "Training", BAY_UP, 2, MACHINE_WIDTH)
	end
	if generatorMarker then
		generator = spotFor(generatorMarker, "Generator", GENERATOR_UP, 2, GENERATOR_WIDTH)
	end
	for index, marker in bayMarkers do
		local spot = spotFor(marker, `Bay{index}`, BAY_UP, 1, BAY_WIDTH)
		bays[index] = spot
	end
	BaseController.Refresh()
end

-- The starter shards wait in front of the Breaker until one is chosen.
local function layStarters(view: Profile.View)
	local want = view.Progress.Starter == "" and breaker ~= nil
	if not want then
		for _, part in starters do
			part:Destroy()
		end
		starters = {}
		return
	end
	if next(starters) ~= nil then
		return
	end
	local b = Markers.At((breaker :: Spot).Marker).Position
	local spawn = Markers.Find("Spawn", { Plot = plot })
	local toward = if spawn then Markers.At(spawn).Position - b else Vector3.new(0, 0, 1)
	toward = Vector3.new(toward.X, 0, toward.Z)
	toward = if toward.Magnitude > 1e-3 then toward.Unit else Vector3.new(0, 0, 1)
	local side = toward:Cross(Vector3.yAxis)
	for index, id in Shards.Starters do
		local part = Instance.new("Part")
		part.Name = id
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Material = Enum.Material.Neon
		part.Color = Theme.Colour.TextDim
		part.Size = STARTER_SIZE
		part.Position = b + toward * STARTER_OUT + side * (index - 2) * STARTER_APART + Vector3.new(0, STARTER_UP, 0)
		part.Parent = base()
		local holds = Shards.ById[id].Holds
		local p = prompt(part, "NL_Choose", Read.ShardName(id), "Choose", CHOOSE_HOLD)
		p.Triggered:Connect(function()
			act("ChooseStarter", { Shard = id })
		end)
		part:SetAttribute("Holds", holds)
		starters[id] = part
	end
end

-- The plates, the prompt's words and an open screen, from the server's copy and the base as it stands now.
function BaseController.Refresh()
	local view = ProfileController.Get()
	if view == nil then
		return
	end
	layStarters(view)
	local now = Read.Base(view, workspace:GetServerTimeNow())
	if breaker then
		-- Only what's happening: what breaks and when, what's ready, how many wait (docs/ui.md, rule 2).
		local lines = {}
		if #view.Base.Ready > 0 then
			table.insert(lines, `Ready to open: {#view.Base.Ready}`)
		end
		for _, chamber in now.Data.Base.Chambers do
			local work = chamber.Work
			if work then
				table.insert(lines, `{Read.ShardName(work.Def)} · {Read.Seconds(Read.Left(now, work))}`)
			end
		end
		if #now.Data.Base.Line > 0 then
			table.insert(lines, `Waiting: {#now.Data.Base.Line}`)
		end
		if #lines == 0 then
			table.insert(lines, "Void Breaker · idle")
		end
		setLines(breaker.Plate, lines)
		-- Lit, and seen from anywhere on the plot, while a shard waits in the bag, until it's in (research's read of TR2's
		-- fixes, 2026-11-12), or one waits to be opened.
		local bagged = false
		for _, count in view.Bag.Shards do
			bagged = bagged or count > 0
		end
		breaker.News = bagged or #view.Base.Ready > 0
		local panel = breaker.Plate:FindFirstChild("Panel")
		if panel and panel:IsA("GuiObject") then
			Panel.Lit(panel, breaker.News)
		end
		if breaker.Prompt then
			breaker.Prompt.ActionText = if #view.Base.Ready > 0 then "Open" else "Breaker"
		end
	end
	if battery then
		setLines(battery.Plate, { "Battery" })
	end
	if generator then
		-- Its face: the owner's generation and demand (TR18). Its prompt only once the Power screen is open to them: until
		-- a second machine draws, Auto runs the plant unseen.
		setLines(generator.Plate, { `Generation {Read.Kw(now.Rates.Generation)}`, `Demand {Read.Kw(now.Rates.Demand)}` })
		local open = view.Base.Power.Open
		if open and generator.Prompt == nil then
			local p = prompt(generator.Anchor, "NL_Generator", "Generator", "Power")
			p.Triggered:Connect(function()
				BaseController.OpenPower()
			end)
			generator.Prompt = p
		elseif not open and generator.Prompt then
			generator.Prompt:Destroy()
			generator.Prompt = nil
		end
	end
	if machine then
		-- Who's on it, at what level; nobody while the player is home, so it says what it's for (docs/design.md, "The
		-- Training machine").
		local on = player:GetAttribute("Training")
		local trainee = if type(on) == "string" and on ~= "" then view.Voidkin[on] else nil
		setLines(machine.Plate, { "Training machine", if trainee then `{Read.VoidkinName(trainee)} · Lv {trainee.Level}` else "Trains while you're away" })
	end
	-- Someone neither leading nor working, whom an empty bay could take.
	local free = false
	for id in view.Voidkin do
		free = free or Read.Role(view, id) == ""
	end
	for index, spot in bays do
		local bay = view.Base.Bays[index]
		local worker = if bay and bay.Worker ~= "" then view.Voidkin[bay.Worker] else nil
		setLines(spot.Plate, {
			if bay == nil then `Bay {index} · locked`
			elseif worker then `{Read.VoidkinName(worker)} · {Read.Kw(Power.Output(worker))}`
			else `Bay {index} · nobody works here`,
		})
		spot.News = bay ~= nil and worker == nil and free
		local panel = spot.Plate:FindFirstChild("Panel")
		if panel and panel:IsA("GuiObject") then
			Panel.Lit(panel, spot.News)
		end
		if bay and spot.Prompt == nil then
			local p = prompt(spot.Anchor, "NL_Bay", `Bay {index}`, "Set worker")
			p.Triggered:Connect(function()
				pickingBay = index
				build()
			end)
			spot.Prompt = p
		elseif bay == nil and spot.Prompt then
			spot.Prompt:Destroy()
			spot.Prompt = nil
		end
	end
	BreakerScreen.Tick(now)
	PowerScreen.Tick(now)
	for _, countdown in countdowns do
		local work = now.Data.Base.Chambers[countdown.Chamber] and now.Data.Base.Chambers[countdown.Chamber].Work
		if work and countdown.Label.Parent then
			countdown.Label.Text = `{countdown.Prefix} · {Read.Seconds(Read.Left(now, work))}`
		end
	end
end

-- For tests: the plot's prompts and plates.
function BaseController.Parts(): { [string]: Instance }
	local parts: { [string]: Instance } = {}
	if breaker then
		parts.BreakerPlate = breaker.Plate
		parts.BreakerPrompt = breaker.Prompt :: any
	end
	if battery then
		parts.BatteryPlate = battery.Plate
	end
	if machine then
		parts.TrainingPlate = machine.Plate
	end
	if generator then
		parts.GeneratorPlate = generator.Plate
		parts.GeneratorPrompt = generator.Prompt :: any
	end
	for index, spot in bays do
		parts[`Bay{index}Plate`] = spot.Plate
		if spot.Prompt then
			parts[`Bay{index}Prompt`] = spot.Prompt
		end
	end
	for id, part in starters do
		parts[id] = part
	end
	return parts
end

-- For tests: each plate's spot by its name ("Breaker", "Battery", "Bay1"), whether it's near and has news, its spot on
-- the floor, and how near speaks.
BaseController.Near = NEAR
BaseController.NearSlack = NEAR_SLACK
function BaseController.Says(): { [string]: { Near: boolean, News: boolean, Ground: Vector3 } }
	local says = {}
	local function add(name: string, spot: Spot?)
		if spot then
			says[name] = { Near = spot.Near, News = spot.News, Ground = spot.Ground }
		end
	end
	add("Breaker", breaker)
	add("Battery", battery)
	add("Training", machine)
	add("Generator", generator)
	for index, spot in bays do
		add(`Bay{index}`, spot)
	end
	return says
end

-- Studio only: the reveal driven from a snippet, which can't reach this client's modules (TR4's captures and tuning).
--   NL_RevealTest:Invoke("Play", "lyric")   the ceremony for a Voidkin, as a break would show it (display only: nothing owned)
--   NL_RevealTest:Invoke("Seek", 1.2)       its clock pinned there; ("Seek") lets it run on
--   NL_RevealTest:Invoke("Show", { Rarity = "Mythical", Name = "Umbriel", Model = "Rook" })   the stage's own options
--   NL_RevealTest:Invoke("State"), ("Tap"), ("Close")
local function revealBridge()
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "NL_RevealTest"
	bridge.OnInvoke = function(command: string, value: any): any
		if command == "Play" then
			BaseController.Reveal({ Def = value, Outcome = "New" })
		elseif command == "Show" then -- the stage at a rarity with a name and a body, e.g. Rook's at Mythical as the art sheet lays it
			BaseController.Reveal({ Def = value.Name, Outcome = "New" }, value)
		elseif command == "Seek" then
			BaseController.Seek(value)
		elseif command == "Tap" then
			tap()
		elseif command == "Close" then
			BaseController.Dismiss()
		end
		return BaseController.Revealed()
	end
	bridge.Parent = ReplicatedStorage
end

-- The generators' rotors on every plot (AR15), each turning about its own X by its owner's generation (BaseService).
local rotors: { [BasePart]: { Rest: CFrame, Angle: number } } = {}

local function watchRotor(item: Instance)
	if item:IsA("BasePart") and item:GetAttribute("Piece") == "GeneratorRotor" then
		rotors[item] = { Rest = item.CFrame, Angle = 0 }
	end
end

local function turnRotors(dt: number)
	local spin = WorldConfig.Grey.Generator.Rotor
	for part, turning in rotors do
		if part.Parent == nil then
			rotors[part] = nil
			continue
		end
		local kw = part:GetAttribute("Generation")
		local rate = if type(kw) == "number" then math.min(kw * spin.PerKw, spin.Most) else 0
		if rate > 0 then
			turning.Angle = (turning.Angle + rate * 2 * math.pi * dt) % (2 * math.pi)
			part.CFrame = turning.Rest * CFrame.Angles(turning.Angle, 0, 0)
		end
	end
end

function BaseController.Start()
	HudController.OpenBase = BaseController.Open
	CollectionService:GetInstanceAddedSignal(Kit.Tag):Connect(watchRotor)
	for _, item in CollectionService:GetTagged(Kit.Tag) do
		watchRotor(item)
	end
	if RunService:IsStudio() then
		revealBridge()
	end
	ProfileController.Changed:Connect(function()
		BaseController.Refresh()
		if Screen.Current() == "Base" then
			build()
		elseif Screen.Current() == BreakerScreen.Name then
			BaseController.OpenBreaker()
		elseif Screen.Current() == PowerScreen.Name then
			BaseController.OpenPower()
		end
	end)
	task.spawn(function()
		while true do
			local ok, problem = pcall(find)
			if not ok then
				warn(`BaseController: {problem}`)
			end
			task.wait(FIND_EVERY)
		end
	end)
	local last = 0
	RunService.RenderStepped:Connect(function(dt: number)
		for _, part in starters do
			part.CFrame = part.CFrame * CFrame.Angles(0, STARTER_SPIN * dt, 0)
		end
		turnRotors(dt)
		if os.clock() - last >= TICK then
			last = os.clock()
			BaseController.Refresh()
		end
	end)
end

return BaseController
