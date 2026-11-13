--!strict
-- BaseController (client): the player's own base, in grey (docs/test-requests.md, TR2, items 1, 2 and 7; docs/ui.md,
-- "The screens of the first loop", 2, 3 and 7, in stock frames). On the plot: a prompt at the Breaker (Open while a shard
-- is ready, else the Base screen), one at each open bay, and the three starter shards waiting in front of the Breaker until
-- one is chosen. Over the world: the Breaker's chambers counting down, each bay's worker and output, the battery's name.
-- A plate speaks only near its machine, or while it's lit with something to do (TR2, research's read of the phone take,
-- fix 2): the Breaker with a shard to put in or to open, a bay that a free Voidkin could work. The Base
-- screen: the chambers, the line, what's ready, the bag, the bays and who works in them. Opening a shard shows the reveal:
-- one card with the name, no ceremony yet. Every change is asked of the server (ProfileController.Act) and shown only
-- once it answers; the prompts are this player's alone, so a visitor can look and never touch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local BaseConfig = require(Shared.Config.Base)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Breaker = require(Shared.Rules.Breaker)
local Markers = require(Shared.World.Markers)
local Parts = require(Shared.Util.Parts)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local World = require(UI.World)
local Panel = require(UI.Kit.Panel)
local Text = require(UI.Kit.Text)
local Row = require(UI.Kit.Row)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
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
local BREAKER_UP = 7 -- studs over the Breaker's marker its plate and prompt stand
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
	BadArgs = "That can't be done",
	Unknown = "That can't be done",
}

-- Ground: the marker's spot on the floor. Near: the avatar stands within NEAR of it. News: it's lit with something to do.
type Spot = { Marker: Instance, Ground: Vector3, Anchor: Part, Prompt: ProximityPrompt?, Plate: Frame, Near: boolean, News: boolean }

local folder: Folder? = nil
local plot: number? = nil
local breaker: Spot? = nil
local battery: Spot? = nil
local bays: { [number]: Spot } = {}
local starters: { [string]: Part } = {}
local pickingBay: number? = nil
local countdowns: { { Label: TextLabel, Chamber: number, Prefix: string } } = {}
local reveal: { Frame: Instance, Shown: number, Name: string, Outcome: string }? = nil

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

-- A plate over `anchor`: a panel of `lines` text lines, filled by the caller, shown while `shown()`.
local function plate(name: string, anchor: Part, lines: number, width: number, shown: () -> boolean): Frame
	local frame = World.Plate(name, Vector2.new(width, lines * PLATE_LINE + Theme.Size.Pad), function(): Vector3?
		return if anchor.Parent and shown() then anchor.Position else nil
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
	for _, spot in bays do
		clearSpot(spot)
	end
	breaker, battery, bays = nil, nil, {}
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
				Detail = `Lv {owned.Level} · {Read.Rate(Breaker.Output(owned))}`,
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
		local detail = if worker then `{Read.VoidkinName(worker)} · {Read.Rate(Breaker.Output(worker))}` else "Nobody works here"
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
	local stored = now.Data.Base.Battery
	add({ Name = "Battery", Text = "Battery", Detail = `{Read.Stored(stored)} / {Read.Number(BaseConfig.Battery.Capacity)} · {Read.Rate(now.Rates.Net)}`, Colour = Theme.Colour.Electricity })
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

-- The reveal -----------------------------------------------------------------------------------------------------------

local function dismiss()
	if reveal and os.clock() - reveal.Shown >= Theme.Time.Skip then
		reveal.Frame:Destroy()
		reveal = nil
	end
end

-- One card for what Open uncovered (Rules.Base.Open's answer): new, a copy, or sold for Credits.
function BaseController.Reveal(answer: { [string]: any })
	if reveal then
		reveal.Frame:Destroy()
	end
	local def = tostring(answer.Def)
	local row = Voidkin.ById[def]
	local name = if row then row.Name else def
	local cover = Instance.new("TextButton")
	cover.Name = "Reveal"
	cover.Text = ""
	cover.AutoButtonColor = false
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Theme.Colour.Backing
	cover.BackgroundTransparency = Theme.Transparency.Dim
	cover.BorderSizePixel = 0
	cover.Parent = Layers.Get("Overlay")
	local cardFrame = Panel.new({ Name = "Card", Size = UDim2.fromOffset(320, 176), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = cover })
	Panel.Pad(cardFrame, Theme.Size.Pad * 2)
	Panel.List(cardFrame, nil, 2)
	local outcome = tostring(answer.Outcome)
	type Line = { Name: string, Text: string, Size: number, Colour: Color3, Font: Font }
	local note = if answer.Lead == true then "Your lead: it fights beside you"
		elseif outcome == "Copy" then "One more toward its next star"
		elseif outcome == "Sold" then `Sold for {Read.Number(tonumber(answer.Credits) or 0)} Credits`
		else "In your collection"
	local kind = if outcome == "New" then "A new Voidkin" elseif outcome == "Copy" then "A copy" else "Already at its last star"
	local lines: { Line } = {
		{ Name = "Kind", Text = kind, Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Font = Theme.Font.Body },
		{ Name = "Name", Text = name, Size = Theme.Text.Big, Colour = Theme.Colour.Text, Font = Theme.Font.Strong },
		{ Name = "Line", Text = Read.VoidkinLine(def), Size = Theme.Text.Body, Colour = Theme.Colour.TextDim, Font = Theme.Font.Body },
		{ Name = "Note", Text = note, Size = Theme.Text.Body, Colour = Theme.Colour.Ready, Font = Theme.Font.Body },
		{ Name = "Skip", Text = "", Size = Theme.Text.Caption, Colour = Theme.Colour.TextDim, Font = Theme.Font.Body },
	}
	for order, line in lines do
		local label = Text.new({ Name = line.Name, Size = line.Size, Colour = line.Colour, Font = line.Font, Box = UDim2.new(1, 0, 0, line.Size + 8), Parent = cardFrame })
		label.LayoutOrder = order
		label.Text = line.Text
	end
	local shown = os.clock()
	reveal = { Frame = cover, Shown = shown, Name = name, Outcome = outcome }
	task.delay(Theme.Time.Skip, function()
		local skip = cardFrame:FindFirstChild("Skip") :: TextLabel?
		if skip and reveal and reveal.Shown == shown then
			skip.Text = "Tap to continue"
		end
	end)
	cover.Activated:Connect(dismiss)
end

-- For tests: the reveal on screen, and closing it as a tap after the skip time would.
function BaseController.Revealed(): { Name: string, Outcome: string }?
	return if reveal then { Name = reveal.Name, Outcome = reveal.Outcome } else nil
end

function BaseController.Dismiss()
	if reveal then
		reveal.Shown = -math.huge
		dismiss()
	end
end

-- The plot -------------------------------------------------------------------------------------------------------------

local function spotFor(marker: Instance, name: string, up: number, lines: number, width: number): Spot
	local ground = Markers.At(marker).Position
	local anchor = anchorAt(name, ground + Vector3.new(0, up, 0))
	local spot: Spot = { Marker = marker, Ground = ground, Anchor = anchor, Prompt = nil, Plate = nil :: any, Near = false, News = false }
	spot.Plate = plate(name, anchor, lines, width, function(): boolean
		return speaks(spot)
	end)
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
	local bayMarkers: { [number]: Instance } = {}
	for _, marker in Markers.All("Bay") do
		local index = marker:GetAttribute("Bay")
		if marker:GetAttribute("Plot") == number and type(index) == "number" then
			bayMarkers[index] = marker
		end
	end
	local changed = number ~= plot or stale(breaker, breakerMarker) or stale(battery, batteryMarker)
	for index, marker in bayMarkers do
		changed = changed or stale(bays[index], marker)
	end
	if not changed or breakerMarker == nil then
		return
	end
	clearAll()
	plot = number
	local b = spotFor(breakerMarker, "Breaker", BREAKER_UP, 4, BREAKER_WIDTH)
	b.Prompt = prompt(b.Anchor, "NL_Breaker", "Void Breaker", "Breaker")
	;(b.Prompt :: ProximityPrompt).Triggered:Connect(function()
		local view = ProfileController.Get()
		if view and #view.Base.Ready > 0 then
			openShard(nil)
		else
			BaseController.Open()
		end
	end)
	breaker = b
	if batteryMarker then
		battery = spotFor(batteryMarker, "Battery", BAY_UP, 1, BATTERY_WIDTH)
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
			elseif worker then `{Read.VoidkinName(worker)} · {Read.Rate(Breaker.Output(worker))}`
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
	for index, spot in bays do
		add(`Bay{index}`, spot)
	end
	return says
end

function BaseController.Start()
	HudController.OpenBase = BaseController.Open
	ProfileController.Changed:Connect(function()
		BaseController.Refresh()
		if Screen.Current() == "Base" then
			build()
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
		if os.clock() - last >= TICK then
			last = os.clock()
			BaseController.Refresh()
		end
	end)
end

return BaseController
