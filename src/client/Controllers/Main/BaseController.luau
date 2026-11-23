--!strict
-- BaseController (client): the player's own base, in grey (docs/test-requests.md, TR2, items 1, 2 and 7; docs/ui.md,
-- "The screens of the first loop", 2, 3 and 7, in stock frames). On the plot: a prompt at the Breaker (Open while a shard
-- is ready, else the Breaker's own screen, UI/BreakerScreen, TR9), one at each open bay, and the three starter shards waiting in front of the Breaker until
-- one is chosen. Over the world: the Breaker's chambers counting down, each bay's worker and output, the battery's name.
-- A plate speaks only near its machine, or while it's lit with something to do (TR2, research's read of the phone take,
-- fix 2): the Breaker with a shard to put in or to open, a bay that a free Voidkin could work. The Base
-- screen: the chambers, the line, what's ready, the bag, the bays and who works in them. Opening a shard shows the reveal:
-- the ceremony at its rarity (UI/Reveal, TR4), then the plate under its name (UI/Reveal/Plate, AR12). Every change is asked of the server (ProfileController.Act) and shown only
-- once it answers; the prompts are this player's alone, so a visitor can look and never touch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local RevealConfig = require(Shared.Config.Reveal)
local RevealArt = require(Shared.Config.RevealArt)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Power = require(Shared.Rules.Power)
local Breaker = require(Shared.Rules.Breaker)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Condenser = require(Shared.Rules.Condenser)
local Forge = require(Shared.Rules.Forge)
local CondenserConfig = require(Shared.Config.Condenser)
local ReinforceConfig = require(Shared.Config.Reinforce)
local Markers = require(Shared.World.Markers)
local Kit = require(Shared.World.Kit)
local BaseManifest: any = require(Shared.Config.Kits.Base.Manifest) -- each piece's centre, for the pieces that turn about their origin
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
local RevealPlate = require(UI.Reveal.Plate)
local BreakerScreen = require(UI.BreakerScreen)
local PowerScreen = require(UI.PowerScreen)
local BaseView = require(UI.BaseView)
local ProfileController = require(script.Parent.Parent.Core.ProfileController)
local HudController = require(script.Parent.HudController)
local Clips = require(script.Parent.FighterController.Clips)
local AnimationsConfig = require(Shared.Config.Animations)

local BaseController = {}

local player = Players.LocalPlayer

local FIND_EVERY = 1 -- seconds between looks for the plot's markers: they stream in, and a relaid world replaces them
local TICK = 0.25 -- seconds between countdown updates
local SELF_OPEN_EVERY = 0.5 -- seconds between looks for a shard that opens itself (TR24's fix 5)
local SELF_OPEN_AFTER_NO = 5 -- seconds before asking again once the server said no
local REACH = 140 -- studs from the camera a base's plates show: the plot and the Strip, never the street
local PROMPT_REACH = 10 -- studs from a prompt's spot it can be pressed
-- Studs, flat, from a machine's spot within which its plate speaks: the prompt's reach and a few steps. From farther, the
-- next step over the dock carries a machine's news, with its marker on the machine, and its plate is quiet (research's
-- must-fix on AR16, 2026-11-17: on arrival the plates stacked over the avatar and said the Breaker's count twice). A plate
-- lets go NEAR_SLACK farther out than it takes hold, so it never flickers at the edge.
local NEAR = PROMPT_REACH + 3
local NEAR_SLACK = 2
local BREAKER_UP = 7 -- studs over the Breaker's marker its prompt stands
local BREAKER_PLATE = 5.5 -- and its plate that much higher: over the gantry's lamp (11.5), clear of the chambers (AR15)
local BAY_UP = 4
local STARTER_OUT = 7 -- studs in front of the Breaker, toward the spawn, the starter shards wait
local STARTER_APART = 4
local STARTER_UP = 2.6
local STARTER_SIZE = Vector3.new(1.2, 2.2, 1.2) -- the anchor each one turns on, unseen: its prompt's host
-- TR24's fix 3: each one is the break card's crystal, the reveal's own shard (RevealArt.Shard, the Standard grade a
-- starter's picture shows, Rules.Hud.ShardPicture) whole and at this scale of its 4.5 studs (2.7 here, about half the
-- avatar), with a faint light of its own (Range studs, Brightness) in the break's first crack colour, so it reads as a
-- Void Shard and never a lit cube.
local STARTER_SCALE = 0.6
local STARTER_GLOW = { Colour = Color3.fromHex("#C9B8FF"), Range = 7, Brightness = 1.2 }
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
local CONDENSER_UP = 4 -- studs over the Stone Condenser's place its prompt stands, before its comb (TR37)
local CONDENSER_PLATE = 9 -- and its plate that much higher: over its core (9.5 up)
local CONDENSER_WIDTH = 204 -- "Tray 12 of 12 Low · 1 Mid"
local FORGE_UP = 4 -- the Forge's prompt, before its seat (TR37)
local FORGE_PLATE = 9.5 -- and its plate over its head (12.5 up)
local FORGE_WIDTH = 160
local CONVERT_LINES = { Title = 30, Line = 24 } -- the convert panel's lines, in its pixels (Config.World.Condenser.Panel)
-- Wide enough that a row's name and its second line fit beside its button at the smallest scale: 191 authored pixels,
-- against "Intelligence · Mage · Fire" at 178, the longest line before the types took their colours' names (TR36),
-- and "Chamber 2 · 1 min 59 s" at 164.
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
	Asleep = `The Stone Condenser wakes at base level {CondenserConfig.Wakes}`,
	Busy = "A convert is already under way",
	Stones = `A convert takes {CondenserConfig.Convert.Take} {CondenserConfig.Convert.From} stones`,
}

-- Ground: the marker's spot on the floor. Near: the avatar stands within NEAR of it. News: it's lit with something to do.
type Spot = { Marker: Instance, Ground: Vector3, Anchor: Part, Prompt: ProximityPrompt?, Plate: Frame, Near: boolean, News: boolean }

local folder: Folder? = nil
local plot: number? = nil
local breaker: Spot? = nil
local battery: Spot? = nil
local machine: Spot? = nil -- the Training machine (TR12)
local generator: Spot? = nil -- the generator (TR18)
local condenser: Spot? = nil -- the Stone Condenser (TR37): its plate, and its prompt while its tray holds a stone
local forge: Spot? = nil -- the Forge (TR37): its plate and its prompt, which opens Reinforce
-- The convert's grey panel on the Condenser (TR37): its words, drawn on the kit's block, and its prompt beside it.
type ConvertPanel = { Part: BasePart, Gui: SurfaceGui, Anchor: Part, Prompt: ProximityPrompt, Lines: { [string]: TextLabel } }
local convert: ConvertPanel? = nil
local bays: { [number]: Spot } = {}
local starters: { [string]: Part } = {}
local pickingBay: number? = nil
local countdowns: { { Label: TextLabel, Chamber: number, Prefix: string } } = {}
type Shown = { Frame: Instance, Stage: RevealStage.Handle, Card: Frame?, Carded: number, Name: string, Rarity: string, Outcome: string }
local reveal: Shown? = nil

-- A shut bay's line: the base level that opens it, or "more Voidkin" for the ones no level at launch does (D5).
local function shut(index: number): string
	local level = BaseLevels.OpensAt(index)
	return if level then `Bay {index} · opens at base level {level}` else `Bay {index} · opens with more Voidkin`
end

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

-- Whether a spot's plate speaks now: the avatar stands near it. Its news only lights it.
local function speaks(spot: Spot): boolean
	local root = Parts.Root(player.Character)
	if root == nil then
		spot.Near = false
	else
		local gap = root.Position - spot.Anchor.Position
		spot.Near = Vector2.new(gap.X, gap.Z).Magnitude <= (if spot.Near then NEAR + NEAR_SLACK else NEAR)
	end
	return spot.Near
end

-- A plate over `anchor`, `lift` studs higher: a panel of `lines` text lines, filled by the caller, shown while `shown()`.
local function plate(name: string, anchor: Part, lines: number, width: number, shown: () -> boolean, lift: number?): Frame
	local over = Vector3.new(0, lift or 0, 0)
	local frame = World.Plate(name, Vector2.new(width, lines * PLATE_LINE + Theme.Size.Pad), function(): Vector3?
		return if anchor.Parent and shown() and not BaseView.IsOpen() then anchor.Position + over else nil -- the command view's chips stand in
	end, REACH)
	-- Kept under the top band: a machine high on screen put its news under the lead's card (the phone pack, 2026-11-13).
	World.Below(frame)
	-- And never over another machine's: from the spawn, AR16's star stands bay 2 right behind the Breaker.
	World.Apart(frame, "Base")
	-- Nor over the player's own avatar: under the band on a phone, a plate over a machine ahead stood on its head.
	World.Off(frame)
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
	clearSpot(condenser)
	clearSpot(forge)
	for _, spot in bays do
		clearSpot(spot)
	end
	breaker, battery, machine, generator, condenser, forge, bays = nil, nil, nil, nil, nil, nil, {}
	if convert then
		convert.Gui:Destroy()
		convert.Anchor:Destroy()
		convert = nil
	end
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

-- A broken shard that opens itself (TR24's fix 5; Rules.Breaker.SelfOpening): the first session's starter and Watt's,
-- once the player stands on their plot, with no reveal on screen and no screen open but the Breaker's. One ask at a
-- time; after a no, a wait before the next. The server checks the ask as it checks a tap's.
local selfNext = 0
local selfOn = true
local function selfOpen()
	if not selfOn or os.clock() < selfNext or reveal ~= nil then
		return
	end
	local current = Screen.Current()
	if current ~= nil and current ~= BreakerScreen.Name then
		return
	end
	local view = ProfileController.Get()
	local plot = player:GetAttribute("Plot")
	local root = Parts.Root(player.Character)
	local onPlot = Markers.OnPlot(if type(plot) == "number" then plot else nil, if root then root.Position else nil)
	local index = if view then Breaker.SelfOpening(view.Base.Ready, onPlot) else nil
	if index == nil then
		return
	end
	selfNext = math.huge -- while the ask is out
	local answer = act("Open", { Index = index })
	selfNext = os.clock() + if answer.Ok == true then 0 else SELF_OPEN_AFTER_NO
	if answer.Ok == true then
		BaseController.Reveal(answer)
	end
end

-- For tests: whether a shard opens itself (on, as players have it), returning how it was. The self-test turns it off
-- for its run, its cases opening their shards by hand, and its own case turns it on.
function BaseController.SelfOpen(on: boolean): boolean
	local was = selfOn
	selfOn = on
	return was
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
				Action = "Station",
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
			add({ Name = `Bay{index}`, Text = shut(index), Colour = Theme.Colour.TextDim })
		end
	end
	local charge = now.Data.Base.Charge
	add({ Name = "Battery", Text = "Battery", Detail = `{Read.Kwh(charge)} / {Read.Number(now.Rates.Capacity)} kWh · {Read.Kw(now.Rates.NetKw, true)}`, Colour = Theme.Colour.Electricity })
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

-- The base screen's command view (TR21's blockout, UI/BaseView), from the Base tile at home: the camera over the
-- player's whole base, a chip on each machine and bay.
function BaseController.OpenView()
	local number = player:GetAttribute("Plot")
	local floor = if type(number) == "number" then Markers.Find("Plot", { Plot = number }) else nil
	if floor == nil or not floor:IsA("BasePart") then
		return
	end
	local spots: { [string]: Vector3 } = {}
	for name, spot in BaseController.Says() do
		spots[name] = spot.Ground
	end
	BaseView.Open({ Plot = floor, Spots = spots, View = ProfileController.Get })
end

-- The Power screen (TR18, UI/PowerScreen), from the generator's prompt: only once it's open to the player (the server
-- refuses a split before). For tests too.
function BaseController.OpenPower()
	local view = ProfileController.Get()
	if view and view.Base.Power.Open then
		PowerScreen.Open(view, { Act = act })
	end
end

-- What a collect brought in, in words: "7 Low stones", "12 Low and 1 Mid stones".
local function stonesWords(stones: { [string]: number }): string
	local said, count = {}, 0
	for _, grade in ReinforceConfig.Grades do
		local n = stones[grade]
		if type(n) == "number" and n > 0 then
			table.insert(said, `{n} {grade}`)
			count += n
		end
	end
	return `{table.concat(said, " and ")} {if count == 1 then "stone" else "stones"}`
end

-- The Condenser's prompt, pressed (TR37): its whole tray into the bag, said. For tests too.
function BaseController.CollectTray(): { [string]: any }
	local answer = act("CollectTray")
	if answer.Ok == true and type(answer.Stones) == "table" then
		Toast.Show(`Collected {stonesWords(answer.Stones :: any)}`)
	end
	return answer
end

-- The convert panel's prompt, pressed (TR37): a convert begins. For tests too.
function BaseController.Convert(): { [string]: any }
	local answer = act("Convert")
	if answer.Ok == true then
		local c = CondenserConfig.Convert
		Toast.Show(`Converting {c.Take} {c.From} into {c.Give} {c.To}`)
	end
	return answer
end

-- The Forge's prompt, pressed (TR37): Equipment's Reinforce page, where a try strikes the ram. For tests too.
function BaseController.PressForge()
	HudController.OpenEquipment("Reinforce")
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

-- The plate after the reveal (UI/Reveal/Plate; AR12), under the ceremony's name on its held frame, left undimmed: new,
-- a copy, or sold for Credits.
local function card(shown: Shown, answer: { [string]: any })
	local plate = RevealPlate.new(shown.Stage, {
		Def = tostring(answer.Def),
		Rarity = shown.Rarity,
		Outcome = shown.Outcome,
		Lead = answer.Lead == true,
		Credits = tonumber(answer.Credits) or 0,
	})
	shown.Card, shown.Carded = plate, os.clock()
	task.delay(RevealConfig.CardHold, function()
		if reveal == shown then
			RevealPlate.Continue(plate)
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
			card(shown, answer)
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
	shown = { Frame = cover :: Instance, Stage = stage, Card = nil :: Frame?, Carded = 0, Name = name, Rarity = options.Rarity, Outcome = tostring(answer.Outcome) }
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

-- The convert's panel (TR37): words on the Condenser's grey block, toward the gate (its title, what it turns into what,
-- how it stands), and its prompt before the block. This client's own: the block is the server's.
local function convertPanel(part: BasePart): ConvertPanel
	local look = WorldConfig.Condenser.Panel
	local gui = Instance.new("SurfaceGui")
	gui.Name = "NL_ConvertPanel"
	gui.Face = Enum.NormalId.Front
	gui.Adornee = part
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = look.PixelsPerStud
	gui.LightInfluence = 0
	gui.MaxDistance = REACH
	gui.ResetOnSpawn = false
	local lines: { [string]: TextLabel } = {}
	local wide = look.Size.X * look.PixelsPerStud
	local top = 8
	local rows: { { Name: string, Size: number, Font: Font } } = {
		{ Name = "Title", Size = CONVERT_LINES.Title, Font = Theme.Font.Strong },
		{ Name = "What", Size = CONVERT_LINES.Line, Font = Theme.Font.Body },
		{ Name = "State", Size = CONVERT_LINES.Line, Font = Theme.Font.Body },
	}
	for _, row in rows do
		local label = Instance.new("TextLabel")
		label.Name = row.Name
		label.BackgroundTransparency = 1
		label.FontFace = row.Font
		label.TextSize = row.Size
		label.TextColor3 = WorldConfig.Showcase.Shade
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Size = UDim2.fromOffset(wide - 12, row.Size)
		label.Position = UDim2.fromOffset(6, top)
		label.Text = ""
		label.Parent = gui
		lines[row.Name] = label
		top += row.Size + 4
	end
	lines.Title.Text = "Convert"
	local c = CondenserConfig.Convert
	lines.What.Text = `{c.Take} {c.From} into {c.Give} {c.To}`
	gui.Parent = player:FindFirstChildOfClass("PlayerGui") or base()
	local anchor = anchorAt("ConvertPanel", part.Position + part.CFrame.LookVector * 0.6)
	local p = prompt(anchor, "NL_Convert", "Stone Condenser", "Convert")
	p.Enabled = false
	p.Triggered:Connect(function()
		BaseController.Convert()
	end)
	return { Part = part, Gui = gui, Anchor = anchor, Prompt = p, Lines = lines }
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
	local condenserMarker = Markers.Find("Condenser", { Plot = number })
	local forgeMarker = Markers.Find("Forge", { Plot = number })
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
		or (condenserMarker ~= nil and stale(condenser, condenserMarker))
		or (forgeMarker ~= nil and stale(forge, forgeMarker))
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
	if condenserMarker then
		condenser = spotFor(condenserMarker, "Condenser", CONDENSER_UP, 2, CONDENSER_WIDTH, CONDENSER_PLATE)
		local block = condenserMarker:FindFirstChild("Panel")
		if block and block:IsA("BasePart") then
			convert = convertPanel(block)
		end
	end
	if forgeMarker then
		local f = spotFor(forgeMarker, "Forge", FORGE_UP, 2, FORGE_WIDTH, FORGE_PLATE)
		f.Prompt = prompt(f.Anchor, "NL_Forge", "Forge", "Reinforce")
		;(f.Prompt :: ProximityPrompt).Triggered:Connect(function()
			BaseController.PressForge()
		end)
		forge = f
	end
	BaseController.Refresh()
end

-- A waiting shard's crystal on its anchor: the reveal's pieces (RevealService loads them, NL_Reveal.Shard), each welded
-- where the shard whole has it, so the anchor's turn turns them. True once all are on; until then a later Refresh dresses
-- it, and the anchor's prompt already speaks.
local function dressStarter(anchor: BasePart): boolean
	if anchor:GetAttribute("Dressed") then
		return true
	end
	local reveal = ReplicatedStorage:FindFirstChild("NL_Reveal")
	local source = if reveal then reveal:FindFirstChild("Shard") else nil
	if source == nil then
		return false
	end
	local wanted: { [string]: MeshPart } = {}
	for name, piece in RevealArt.Shard.Pieces do
		if piece.Order ~= nil then -- the shell; a grade's buds and the core (seen only as it splits) stay out
			local made = source:FindFirstChild(name)
			if made == nil or not made:IsA("MeshPart") then
				return false
			end
			wanted[name] = made
		end
	end
	for name, made in wanted do
		local part = made:Clone()
		part.Anchored = false
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.Massless = true
		part.Material = Enum.Material.SmoothPlastic
		part.TextureID = RevealArt.Images.reveal_palette.Id
		part.Color = Color3.new(1, 1, 1)
		part.Size = made.Size * STARTER_SCALE
		part.CFrame = anchor.CFrame * CFrame.new(RevealArt.Shard.Pieces[name].Centre * STARTER_SCALE)
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = anchor, part
		weld.Parent = part
		part.Parent = anchor
	end
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = STARTER_GLOW.Colour, STARTER_GLOW.Range, STARTER_GLOW.Brightness, false
	light.Parent = anchor
	anchor:SetAttribute("Dressed", true)
	return true
end

-- One starter shard waiting at `at`: its unseen anchor with the prompt that chooses it, dressed as the crystal.
local function starterShard(id: string, at: Vector3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = id
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = STARTER_SIZE
	part.Position = at
	part:SetAttribute("Holds", Shards.ById[id].Holds)
	part.Parent = parent
	dressStarter(part)
	return part
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
		for _, part in starters do
			dressStarter(part)
		end
		return
	end
	local b = Markers.At((breaker :: Spot).Marker).Position
	local spawn = Markers.Find("Spawn", { Plot = plot })
	local toward = if spawn then Markers.At(spawn).Position - b else Vector3.new(0, 0, 1)
	toward = Vector3.new(toward.X, 0, toward.Z)
	toward = if toward.Magnitude > 1e-3 then toward.Unit else Vector3.new(0, 0, 1)
	local side = toward:Cross(Vector3.yAxis)
	for index, id in Shards.Starters do
		local part = starterShard(id, b + toward * STARTER_OUT + side * (index - 2) * STARTER_APART + Vector3.new(0, STARTER_UP, 0), base())
		local p = prompt(part, "NL_Choose", Read.ShardName(id), "Choose", CHOOSE_HOLD)
		p.Triggered:Connect(function()
			act("ChooseStarter", { Shard = id })
		end)
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
		-- Only what's happening: what breaks and when, what's ready, how many wait (docs/ui.md, rule 2). What's ready is
		-- the next step's line while it points here, so the plate leaves it out: one fact, said once.
		local step = HudController.Step()
		local lines = {}
		if #view.Base.Ready > 0 and not (step and step.Target == "Breaker") then
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
		if #lines == 0 and #view.Base.Ready == 0 then
			table.insert(lines, "Void Breaker · idle")
		end
		setLines(breaker.Plate, lines)
		-- Lit while a shard waits in the bag, until it's in (research's read of TR2's fixes, 2026-11-12), or one waits to
		-- be opened. Seen only near: from afar the next step says it (research's must-fix on AR16, 2026-11-17).
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
	local home = now.Data.Base
	local awake = Condenser.Awake(home.Level)
	local held = Condenser.Held(home)
	local mid = home.Condenser.Tray[CondenserConfig.Convert.To] or 0
	if condenser then
		-- What its tray holds against its cap, and what a convert left there; asleep, the level that wakes it. Lit while
		-- the tray is full (it has stopped) or a convert's stone waits. Its prompt while the tray holds a stone.
		local cap = Condenser.Cap(Condenser.Level(home))
		local tray = if held >= cap then `Tray full · {held} {CondenserConfig.Makes}` else `Tray {held} of {cap} {CondenserConfig.Makes}`
		setLines(condenser.Plate, { "Stone Condenser", if not awake then `Wakes at base level {CondenserConfig.Wakes}`
			elseif mid > 0 then `{tray} · {mid} {CondenserConfig.Convert.To}`
			else tray })
		condenser.News = awake and (held >= cap or mid > 0)
		local panel = condenser.Plate:FindFirstChild("Panel")
		if panel and panel:IsA("GuiObject") then
			Panel.Lit(panel, condenser.News)
		end
		local any = awake and held + mid > 0
		if any and condenser.Prompt == nil then
			local p = prompt(condenser.Anchor, "NL_Condenser", "Stone Condenser", "Collect")
			p.Triggered:Connect(function()
				BaseController.CollectTray()
			end)
			condenser.Prompt = p
		elseif not any and condenser.Prompt then
			condenser.Prompt:Destroy()
			condenser.Prompt = nil
		end
	end
	if convert then
		-- The job as it stands: its time left at the Condenser's speed now, or whether the bag holds its stones.
		local c = CondenserConfig.Convert
		local left = Condenser.ConvertLeft(home)
		local have = view.Bag.Stones[c.From] or 0
		convert.Lines.State.Text = if not awake then `Wakes at base level {CondenserConfig.Wakes}`
			elseif left then `{Read.Seconds(left / math.max(now.Rates.Condenser, 1e-3))} left`
			elseif have >= c.Take then `Ready · {have} {c.From} in the bag`
			else `{have} of {c.Take} {c.From} in the bag`
		convert.Prompt.Enabled = awake and left == nil and have >= c.Take
	end
	if forge then
		setLines(forge.Plate, { "Forge", "Reinforce your gear" })
	end
	-- Someone neither leading nor working, whom an empty bay could take.
	local free = false
	for id in view.Voidkin do
		free = free or Read.Role(view, id) == ""
	end
	local step = HudController.Step()
	for index, spot in bays do
		local bay = view.Base.Bays[index]
		local worker = if bay and bay.Worker ~= "" then view.Voidkin[bay.Worker] else nil
		-- An empty bay the next step sends a Voidkin to says nothing: the step's line says it, and the prompt is there.
		local sent = step ~= nil and step.Target == "Bay" and step.Bay == index
		local line: string? = if bay == nil then shut(index)
			elseif worker then `{Read.VoidkinName(worker)} · {Read.Kw(Power.Output(worker))}`
			elseif sent then nil
			else `Bay {index} · nobody works here`
		setLines(spot.Plate, if line then { line } else {})
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
	if condenser then
		parts.CondenserPlate = condenser.Plate
		parts.CondenserPrompt = condenser.Prompt :: any
	end
	if convert then
		parts.ConvertPanel = convert.Gui
		parts.ConvertPrompt = convert.Prompt
	end
	if forge then
		parts.ForgePlate = forge.Plate
		parts.ForgePrompt = forge.Prompt :: any
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
-- For tests: a starter shard as one waits, at `at` under `parent` (TR24's fix 3), and its scale of the reveal's shard.
BaseController.StarterShard = starterShard
BaseController.StarterScale = STARTER_SCALE
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
--   NL_RevealTest:Invoke("Breaker"), ("Power")   the Breaker's or the power's screen, as their prompts open them (AR40's captures)
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
		elseif command == "Breaker" then
			BaseController.OpenBreaker()
		elseif command == "Power" then
			BaseController.OpenPower()
		end
		return BaseController.Revealed()
	end
	bridge.Parent = ReplicatedStorage
end

-- The base's turning pieces on every plot, each from the attribute its server sets (BaseService), the generator's laid
-- once a stage by the swap's table (AR19; WorldService), marked by its row's `moves`:
-- * a stage's wheel ("turns", Rate 1) about its axle, the line to the gate, faster as its owner's plant generates more,
--   still at none (`Generator.Wheel`, in turns a second): anticlockwise from the gate, so the buckets rise on the gate's
--   right through the gauge's lit steps;
-- * a stage's pinions ("turns", Rate -2.4) about their own axles, driven from their stage's wheel's angle, never their
--   own clock, so the teeth stay meshed: CFrame.Angles(0, 0, -wheel * Rate). The wheel's angle comes round after five
--   turns (WRAP), where a pinion's 2.4 a turn does too (12 of its own);
-- * the demand's mark ("demand") about the same axle, to the demand's share of the gauge at its stage's degrees
--   (`Turn`, the row's; `Generator.Gauge.Turn` without one), gliding there over `Gauge.Glide` seconds
--   (Rules.Power.Gauge); the axle is its piece's origin, the manifest's centre away from the part;
-- * the Training machine's crown about its own upright while a Voidkin trains, still when none does (AR15, section 5;
--   each stage's crown alike, AR35);
-- * a stage's own turning pieces (TR51: the Breaker's hinges, AR32; a bay's rings, AR33) about their own axle ("Axis",
--   Z or X), "Speed" turns a second the way their "Sign" says while the server says they're "Spinning";
-- * the Festival Door's rings ("spins") about the tunnel's axis, each its own origin's Z, always and whatever the Door's
--   state, at their plan's `Spin` in degrees a second, anticlockwise seen from the mouth for a positive one: drawn as
--   CFrame.Angles(0, 0, -angle), so the angle runs against the spin (AR15, section 7).
-- A hidden stage's pieces keep their angle, and are moved once they're shown.
type Turning = { Rest: CFrame, Angle: number, Drawn: number, Axis: "Z" | "Y" | "X", Way: number, Pivot: CFrame, Rate: number, Follows: boolean }
local turning: { [BasePart]: Turning } = {}
local WRAP = 5 * 2 * math.pi

-- A bay's worker (BaseService, TR24's fix 1): its rig's Idle, looped, played here for this screen alone, as every fighter's
-- clips are. It streams in and out with its bay; a body replaced brings a new one.
local function watchWorker(item: Instance)
	if not item:IsA("Model") then
		return
	end
	task.spawn(function()
		local animator = item:FindFirstChildWhichIsA("Animator", true)
		local waited = 0
		while animator == nil and item.Parent and waited < 5 do
			waited += task.wait(0.2)
			animator = item:FindFirstChildWhichIsA("Animator", true)
		end
		local named = item:GetAttribute("Rig")
		local rig = AnimationsConfig.Rigs[if type(named) == "string" then named else "R6"] or AnimationsConfig.Rigs.R6
		local animation = Clips.Animation(rig.Idle)
		if animator == nil or animation == nil or item.Parent == nil then
			return
		end
		local track = (animator :: Animator):LoadAnimation(animation)
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Idle
		track:Play(0)
		item:SetAttribute("Playing", rig.Idle)
	end)
end

-- The showcase on the gate's plinth (BaseService, TR22): its rig's Idle, as a worker's, and turning slowly where it
-- stands (Config.World.Showcase.Turn, read each frame so a Tune shows at once), here for this screen alone.
local showcased: { [Model]: boolean } = {}
local function watchShowcase(item: Instance)
	if item:IsA("Model") and showcased[item] == nil then
		showcased[item] = true
		watchWorker(item)
	end
end

local function turnShowcases(dt: number)
	local turn = WorldConfig.Showcase.Turn * 2 * math.pi * dt
	for model in showcased do
		if model.Parent == nil then
			showcased[model] = nil
		elseif model.PrimaryPart then
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, turn, 0))
		end
	end
end

-- A Training machine's crown, at any stage (AR35: TrainingCrown, TrainingCrown2, TrainingCrown3 turn alike).
local function crowned(kind: any): boolean
	return type(kind) == "string" and string.match(kind, "^TrainingCrown%d*$") ~= nil
end

local function watchTurning(item: Instance)
	if not item:IsA("BasePart") then
		return
	end
	local kind = item:GetAttribute("Piece")
	local moves = item:GetAttribute("Moves")
	local own = item:GetAttribute("Axis")
	local axis: ("Z" | "Y" | "X")? = if crowned(kind) then "Y"
		elseif own == "X" then "X"
		elseif moves == "turns" or moves == "demand" or moves == "spins" then "Z"
		else nil
	if axis == nil then
		return
	end
	-- Drawn as CFrame.Angles(0, 0, -angle) about Z and (0, angle, 0) about Y, as ever; a stage's own turner as its row
	-- says, CFrame.Angles(0, 0, angle * sign) or (angle * sign, 0, 0) (AR32, AR33).
	local sign = item:GetAttribute("Sign")
	local way = if type(sign) == "number" then sign elseif axis == "Z" then -1 else 1
	-- The part stands at its piece's origin times the manifest's centre; it turns about the origin.
	local piece = if type(kind) == "string" then BaseManifest.pieces[kind] else nil
	local c = if piece then piece.centre else { 0, 0, 0 }
	local rate = item:GetAttribute("Rate")
	local r = if type(rate) == "number" then rate else 1
	turning[item] = {
		Rest = item.CFrame,
		Angle = 0,
		Drawn = 0,
		Axis = axis,
		Way = way,
		Pivot = CFrame.new(c[1], c[2], c[3]),
		Rate = r,
		Follows = moves == "turns" and r ~= 1,
	}
end

-- The Forge's strike (TR37; Rules.Forge, Config.World.Forge): every Forge's ram ("ForgeRam"), struck when the server
-- counts one more Reinforce try on it ("Strikes"), moves up its own upright by Rules.Forge.Rise from its rest, and its
-- gears turn about their axles by its travel at their "PerStud" degrees, each its "Spin" way. Every client plays every
-- plot's, so a passer-by sees it. A strike that comes mid-strike starts again from the ram's height, never a jump.
type Gear = { Part: BasePart, Rest: CFrame, Way: number, PerStud: number }
type Strike = { Ram: BasePart, Rest: CFrame, Heights: Forge.Ram, Began: number?, From: number, Gears: { [BasePart]: Gear }, Rise: number }
local strikes: { [BasePart]: Strike } = {}

local function gearsOf(strike: Strike)
	local holder = strike.Ram.Parent
	for _, item in (if holder then holder:GetChildren() else {}) do
		if item:IsA("BasePart") and item:GetAttribute("Piece") == "ForgeGear" and strike.Gears[item] == nil then
			local spin, per = item:GetAttribute("Spin"), item:GetAttribute("PerStud")
			strike.Gears[item] = { Part = item, Rest = item.CFrame, Way = if type(spin) == "number" then spin else 1, PerStud = if type(per) == "number" then per else 0 }
		end
	end
end

local function watchRam(item: Instance)
	if not item:IsA("BasePart") or item:GetAttribute("Piece") ~= "ForgeRam" or strikes[item] then
		return
	end
	local rest, tell, contact = item:GetAttribute("Rest"), item:GetAttribute("Tell"), item:GetAttribute("Contact")
	if type(rest) ~= "number" or type(tell) ~= "number" or type(contact) ~= "number" then
		return
	end
	local strike: Strike = { Ram = item, Rest = item.CFrame, Heights = { Rest = rest, Tell = tell, Contact = contact }, Began = nil, From = 0, Gears = {}, Rise = 0 }
	gearsOf(strike)
	strikes[item] = strike
	item:GetAttributeChangedSignal("Strikes"):Connect(function()
		gearsOf(strike)
		strike.From = strike.Rise -- from where it stands now
		strike.Began = os.clock()
	end)
end

local function strikePieces()
	local timing = WorldConfig.Forge
	for ram, strike in strikes do
		if ram.Parent == nil then
			strikes[ram] = nil
			continue
		end
		local began = strike.Began
		if began == nil then
			continue
		end
		local t = os.clock() - began
		local rise = Forge.Rise(t, strike.Heights, timing)
		if strike.From ~= 0 and Forge.Beat(t, timing) == "Lift" then
			rise = strike.From + (rise - strike.From) * math.clamp(t / math.max(timing.Lift, 1e-3), 0, 1) -- eased in from mid-strike
		end
		if Forge.Beat(t, timing) == "Done" then
			rise = 0
			strike.Began = nil
			strike.From = 0
		end
		strike.Rise = rise
		ram.CFrame = strike.Rest + strike.Rest.UpVector * rise
		for gear, turn in strike.Gears do
			if gear.Parent then
				gear.CFrame = turn.Rest * CFrame.Angles(0, 0, math.rad(rise * turn.PerStud * turn.Way))
			end
		end
	end
end

-- For the self-test: a Forge ram's height over its rest now, and whether it's mid-strike; nil for one not watched.
function BaseController.StrikeOf(ram: BasePart): (number?, boolean)
	local strike = strikes[ram]
	return if strike then strike.Rise else nil, strike ~= nil and strike.Began ~= nil
end

-- The angle a turning piece goes to this frame, in radians, growing the way it turns; a pinion's from its wheel's.
local function angleOf(part: BasePart, turn: Turning, dt: number): number
	local generator, training = WorldConfig.Grey.Generator, WorldConfig.Grey.Training
	if turn.Follows then
		local wheel = if part.Parent then part.Parent:FindFirstChild("Wheel") else nil
		local driver = if wheel and wheel:IsA("BasePart") then turning[wheel] else nil
		return if driver then driver.Angle * turn.Rate else turn.Angle
	end
	if part:GetAttribute("Moves") == "demand" then
		local share = part:GetAttribute("Share")
		local degrees = part:GetAttribute("Turn")
		local goal = math.rad(if type(degrees) == "number" then degrees else generator.Gauge.Turn) * math.clamp(if type(share) == "number" then share else 0, 0, 1)
		local glide = generator.Gauge.Glide
		return if glide <= 0 then goal else turn.Angle + (goal - turn.Angle) * (1 - math.exp(-dt * 4 / glide))
	end
	if part:GetAttribute("Moves") == "spins" then
		local spin = part:GetAttribute("Spin")
		return (turn.Angle - math.rad(if type(spin) == "number" then spin else 0) * dt) % WRAP
	end
	local speed = 0
	local own = part:GetAttribute("Speed")
	if type(own) == "number" then
		local pace = part:GetAttribute("Pace") -- its machine's power speed, where it has one (the Condenser's core, TR37)
		speed = if part:GetAttribute("Spinning") == true then own * (if type(pace) == "number" then pace else 1) else 0
	elseif crowned(part:GetAttribute("Piece")) then
		speed = if part:GetAttribute("Training") == true then training.Crown else 0
	else
		local kw = part:GetAttribute("Generation")
		local wheel = generator.Wheel
		speed = if type(kw) == "number" and kw > 0 then math.min(wheel.Least + kw * wheel.PerKw, wheel.Most) else 0
	end
	return (turn.Angle + speed * 2 * math.pi * dt) % WRAP
end

local function turnPieces(dt: number)
	-- The wheels and the marks first, then the pinions from their wheels' angles this frame.
	for pass = 1, 2 do
		for part, turn in turning do
			if turn.Follows ~= (pass == 2) then
				continue
			end
			if part.Parent == nil then
				turning[part] = nil
				continue
			end
			turn.Angle = angleOf(part, turn, dt)
			if turn.Angle ~= turn.Drawn and part.Transparency < 1 then
				turn.Drawn = turn.Angle
				local angle = turn.Angle * turn.Way
				part.CFrame = if turn.Axis == "Z"
					then turn.Rest * turn.Pivot:Inverse() * CFrame.Angles(0, 0, angle) * turn.Pivot
					elseif turn.Axis == "X" then turn.Rest * turn.Pivot:Inverse() * CFrame.Angles(angle, 0, 0) * turn.Pivot
					else turn.Rest * CFrame.Angles(0, angle, 0)
			end
		end
	end
end

-- The model of the stage a plot's machine stands at (BaseService's "Stage": the mill's, AR19; the Breaker's, a bay's,
-- the battery's and the Training machine's, TR51), nil before it's shown.
function BaseController.StageOf(holder: Instance): Instance?
	return holder:FindFirstChild(`Stage {holder:GetAttribute("Stage")}`)
end

-- For the self-test: a turning piece's angle so far, nil for one not watched.
function BaseController.TurnedOf(part: BasePart): number?
	local turn = turning[part]
	return if turn then turn.Angle else nil
end

function BaseController.Start()
	HudController.OpenBase = BaseController.Open
	HudController.OpenView = BaseController.OpenView
	CollectionService:GetInstanceAddedSignal(Kit.Tag):Connect(function(item: Instance)
		watchTurning(item)
		watchRam(item)
	end)
	for _, item in CollectionService:GetTagged(Kit.Tag) do
		watchTurning(item)
		watchRam(item)
	end
	CollectionService:GetInstanceAddedSignal("Worker"):Connect(watchWorker)
	for _, item in CollectionService:GetTagged("Worker") do
		watchWorker(item)
	end
	CollectionService:GetInstanceAddedSignal("Showcased"):Connect(watchShowcase)
	CollectionService:GetInstanceRemovedSignal("Showcased"):Connect(function(item: Instance)
		showcased[item :: Model] = nil
	end)
	for _, item in CollectionService:GetTagged("Showcased") do
		watchShowcase(item)
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
	task.spawn(function()
		while true do
			local ok, problem = pcall(selfOpen)
			if not ok then
				selfNext = os.clock() + SELF_OPEN_AFTER_NO
				warn(`BaseController: {problem}`)
			end
			task.wait(SELF_OPEN_EVERY)
		end
	end)
	local last = 0
	RunService.RenderStepped:Connect(function(dt: number)
		for _, part in starters do
			part.CFrame = part.CFrame * CFrame.Angles(0, STARTER_SPIN * dt, 0)
		end
		turnPieces(dt)
		turnShowcases(dt)
		strikePieces()
		if os.clock() - last >= TICK then
			last = os.clock()
			BaseController.Refresh()
		end
	end)
end

return BaseController
