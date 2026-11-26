--!strict
-- BaseService (server): a player's base keeps time. It registers the base's actions (Shared.Rules.Base) with the save's one
-- door, advances the base on a return as time away, and wakes it online at its next event, so a shard is Ready the moment it
-- finishes, and at least every Config.Base.Clock.MostSeconds, so the battery, overflow Credits and the Training machine's
-- levels reach the client. Nothing is advanced on leaving: the next load counts from the last stamp as time away, with the
-- lead on the Training machine. Within the away hours the workers generate the same either way, so the most a leave can
-- cost is that many seconds of a long absence's cap.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Data.Profile)
local Breaker = require(Shared.Rules.Breaker)
local BaseLevels = require(Shared.Rules.BaseLevels)
local BaseRules = require(Shared.Rules.Base)
local Return = require(Shared.Rules.Return)
local PlaceRole = require(Shared.Util.PlaceRole)
local BaseConfig = require(Shared.Config.Base)
local WorldConfig = require(Shared.Config.World)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local RevealConfig = require(Shared.Config.Reveal)
local Markers = require(Shared.World.Markers)
local Power = require(Shared.Rules.Power)
local Landing = require(Shared.Rules.Landing)
local LandingConfig = require(Shared.Config.Landing)
local Collection = require(Shared.Rules.Collection)
local Stats = require(Shared.Rules.Stats)
local Sheet = require(Shared.Rules.Sheet)
local Hud = require(Shared.Rules.Hud)
local Condenser = require(Shared.Rules.Condenser)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local WorldService = require(script.Parent.WorldService)
local FightService = require(script.Parent.FightService)

local BaseService = {
	Priority = 20, -- after DataService
}

local rng = Random.new()
local timers: { [Player]: thread } = {}

-- Server time in seconds, fractional, the clock clients can read too (workspace:GetServerTimeNow).
local function now(): number
	return workspace:GetServerTimeNow()
end

local function advance(player: Player, label: string, away: boolean): { [string]: any }
	return DataService.Change(player, label, function(draft: Profile.Data): { [string]: any }
		local summary = Breaker.Advance(draft, now(), away)
		return { Ok = true, Finished = summary.Finished, Made = summary.Made, Credits = summary.Credits, Trained = summary.Trained or "", Levels = summary.Levels }
	end)
end

local schedule: (player: Player) -> ()

local function wake(player: Player)
	timers[player] = nil -- this thread is running: nothing to cancel
	if DataService.Get(player) == nil then
		return
	end
	advance(player, "BaseClock", false) -- its Changed schedules the next wake
	if timers[player] == nil then
		schedule(player) -- the change failed: keep the clock going
	end
end

function schedule(player: Player)
	local old = timers[player]
	if old then
		task.cancel(old)
	end
	timers[player] = nil
	local data = DataService.Get(player)
	if data == nil then
		return
	end
	local clock = BaseConfig.Clock
	local soonest = Breaker.NextEvent(data) -- seconds from the stamp
	local due = if soonest then data.Base.Stamp + soonest - now() + clock.LeastSeconds else math.huge
	timers[player] = task.delay(math.clamp(due, clock.LeastSeconds, clock.MostSeconds), wake, player)
end

-- A join: the gap passes as away. Away from the base (TR53), in another place or offline, a record of what the base
-- does stays open from the base as it last stood, so a run's advances land in it; back in the base's place, it closes
-- onto the return card, the tray credited (Rules.Return).
local function onReady(player: Player)
	DataService.Change(player, "BaseReturn", function(draft: Profile.Data): { [string]: any }
		Return.Open(draft)
		local summary = Breaker.Advance(draft, now(), true)
		local card = if PlaceRole.Is("Main") then Return.Arrive(draft) else nil
		return { Ok = true, Finished = summary.Finished, Made = summary.Made, Card = card ~= nil }
	end)
	schedule(player)
end

-- A plot's machines as its owner's base stands (AR15; AR16), for every client, so a passer-by sees the plant work:
-- * a chamber that breaks a shard glows full with the shard between its points, an empty one low with none ("Working");
-- * the generator stands at its owner's stage (Rules.BaseLevels.GeneratorStage: a machine's at the base's ceiling; AR19),
--   the plant's "Stage", the other two stages hidden and their solids open; every stage's core turns by the plant's
--   generation ("Generation"), its column's steps light by it, and the collar rides at the demand's share ("Share"), on
--   one scale (Rules.Power.Gauge), so a stage shown is already where the plant is;
-- * each bay the base has opened stands awake and the rest asleep, where a level will wake them;
-- * the battery's bank shows the cells its base's level holds, each lit by its share of the charge ("Lit",
--   Rules.Breaker.Cells);
-- * the Training machine's crown turns while a Voidkin trains ("Training");
-- * a bay at work holds its worker's body in its ring, its halo lit in the worker's rarity colour (showWorker).
-- `data` nil stills them all, with level 1's bays and cells.

-- A bay's worker (TR24's fix 1): its body in the ring (FightService.Body: its own once installed, else the grey stand-in),
-- tagged "Worker" for the client to play its rig's Idle (BaseController), and the ring's halo lit in its rarity colour
-- with one light of it (Config.World.Bay; AR16). The same Voidkin kept stays as it stands; nobody there takes both away.
-- A Voidkin's body made to stand still where it's put: its root anchored, nothing solid, no scripts, no name over it.
local function still(made: Model)
	for _, item in made:GetDescendants() do
		if item:IsA("Script") or item:IsA("LocalScript") then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.Anchored = item.Name == "HumanoidRootPart"
			item.CanCollide, item.CanQuery, item.CanTouch = false, false, false
		elseif item:IsA("Humanoid") then
			item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			item.EvaluateStateMachine = false
		end
	end
end

local function showWorker(bay: Instance, number: number, index: number, id: string, def: string?)
	local body = bay:FindFirstChild("Worker")
	if body and (body:GetAttribute("Voidkin") ~= id or body:GetAttribute("Def") ~= def) then
		body:Destroy()
		body = nil
	end
	if body == nil and def then
		local made, rig = FightService.Body(def, "Worker")
		still(made)
		local at = Markers.At(bay)
		made:PivotTo(CFrame.lookAt(at.Position, at.Position + at.LookVector) + Vector3.new(0, WorldConfig.Bay.Hip, 0))
		made:SetAttribute("Voidkin", id)
		made:SetAttribute("Def", def)
		made:SetAttribute("Rig", rig)
		made:SetAttribute("Plot", number)
		made:SetAttribute("Bay", index)
		CollectionService:AddTag(made, "Worker")
		made.Parent = bay
	end
	local halo = bay:FindFirstChild("Halo")
	if halo and halo:IsA("BasePart") then
		local row = if def then Voidkin.ById[def] else nil
		local colour = if row then RevealConfig.Plate.Words[row.Rarity] else nil
		halo.Transparency = if colour then 0 else 1
		halo.Material = Enum.Material.Neon
		if colour then
			halo.Color = colour
		end
		local light = halo:FindFirstChild("Light") :: PointLight?
		if light == nil then
			local made = Instance.new("PointLight")
			made.Name = "Light"
			made.Range = WorldConfig.Bay.Light.Range
			made.Brightness = WorldConfig.Bay.Light.Brightness
			made.Shadows = false
			made.Parent = halo
			light = made
		end
		local lamp = light :: PointLight
		lamp.Enabled = colour ~= nil
		if colour then
			lamp.Color = colour
		end
	end
end

local SHOWCASE_FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold) -- the HUD's numbers

-- TR22's world parts (TR51 step 3). The gate's plate: the owner's display name over "Level n", on both faces. The
-- plinth: the owner's showcase Voidkin (Collection.Showcase: the one picked with "Show at the gate", else the strongest)
-- at its middle, facing the Strip, tagged "Showcased" for the client to play its Idle and turn it (BaseController), its
-- CR over it (Config.World.Showcase). Without its owner's save, a blank plate and a bare plinth.
local function showOwner(number: number, data: Profile.Data?, owner: Player?)
	local dressing = WorldService.DressingOf(number)
	if dressing == nil then
		return
	end
	local name = if owner and data then owner.DisplayName else ""
	local level = if owner and data then `Level {data.Base.Level}` else ""
	local plate = dressing:FindFirstChild("LevelMark")
	for _, gui in if plate then plate:GetChildren() else {} do
		for _, row in { { "Owner", name }, { "Level", level } } do
			local said = gui:FindFirstChild(row[1])
			if said and said:IsA("TextLabel") and said.Text ~= row[2] then
				said.Text = row[2]
			end
		end
	end
	local stand: CFrame? = nil
	for _, part in dressing:GetChildren() do
		local at = part:GetAttribute("Stand")
		if part:GetAttribute("Piece") == "Showcase" and typeof(at) == "CFrame" then
			stand = at
			break
		end
	end
	local owned = if data and owner then Collection.Showcase(data) else nil
	local figure = dressing:FindFirstChild("Showcased")
	if figure and (owned == nil or figure:GetAttribute("Voidkin") ~= owned.Id or figure:GetAttribute("Def") ~= owned.Def) then
		figure:Destroy()
		figure = nil
	end
	if owned == nil or stand == nil or data == nil then
		return
	end
	local look = WorldConfig.Showcase
	if figure == nil then
		local made, rig = FightService.Body(owned.Def, "Showcased")
		still(made)
		made:PivotTo((stand :: CFrame) * CFrame.new(0, look.Hip, 0))
		made:SetAttribute("Voidkin", owned.Id)
		made:SetAttribute("Def", owned.Def)
		made:SetAttribute("Rig", rig)
		made:SetAttribute("Plot", number)
		local root = made:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local board = Instance.new("BillboardGui")
			board.Name = "Power"
			board.Adornee = root
			board.Size = UDim2.fromScale(look.Size[1], look.Size[2]) -- studs: it reads as part of the world, nearer bigger
			board.StudsOffsetWorldSpace = Vector3.new(0, look.Above, 0)
			board.MaxDistance = look.Far
			board.LightInfluence = 0
			local said = Instance.new("TextLabel")
			said.Name = "Words"
			said.BackgroundTransparency = 1
			said.Size = UDim2.fromScale(1, 1)
			said.FontFace = SHOWCASE_FACE
			said.TextScaled = true
			said.TextColor3 = look.Ink
			said.Parent = board
			local stroke = Instance.new("UIStroke")
			stroke.Color = look.Shade
			stroke.Thickness = 2
			stroke.Parent = said
			board.Parent = root
		end
		CollectionService:AddTag(made, "Showcased")
		made.Parent = dressing
		figure = made
	end
	local power = Stats.Power((Stats.Resolve(owned, Stats.PresetOf(data, owned), data)))
	local shown = figure :: Instance
	shown:SetAttribute("Power", power)
	local root = shown:FindFirstChild("HumanoidRootPart")
	local board = if root then root:FindFirstChild("Power") else nil
	local said = if board then board:FindFirstChild("Words") else nil
	if said and said:IsA("TextLabel") then
		said.Text = `{Sheet.Said.Power} {Hud.Digits(power)}`
	end
end

-- AR37's landing (TR51). A machine's stage that rose while its owner's plot was shown (`seen`: not a join, a respawn or
-- a plot changing hands) lands: at the next start its plot's flash guard allows (Rules.Landing.Start), "Rose" counts
-- one more, with the stage it rose from ("RoseFrom"), which the client plays (LandingController); the old stage stands,
-- "Swapping", until the swap, Config.Landing.Swap frames on, when its newest stage stands. A rise or a fall asked for
-- while a swap waits goes to the newest under the same cover, and never counts again.
type Held = { From: number, Plot: number }
local held: { [Instance]: Held } = {} -- a machine whose swap waits, and the stage it stands at until then
local lastSwap: { [number]: number } = {} -- each plot's last swap, on os.clock
local redraw: (number: number) -> () -- its plot shown again, at a swap

-- Its stage set ("Stage", the save's), a landing begun if it rose, and the stage it stands at now.
local function stageNow(holder: Instance, stage: number, seen: boolean, awake: boolean?, number: number, clock: number): number
	local was = holder:GetAttribute("Stage")
	holder:SetAttribute("Stage", stage)
	local waiting = held[holder]
	if waiting then
		return waiting.From
	end
	if awake == false or not seen or not BaseLevels.Lands(if type(was) == "number" then was else nil, stage) then
		return stage
	end
	local swap = LandingConfig.Swap / 60
	local start = Landing.Start(lastSwap[number], clock, swap, LandingConfig.Gap)
	lastSwap[number] = start + swap
	local entry: Held = { From = if type(was) == "number" then was else stage, Plot = number }
	held[holder] = entry
	holder:SetAttribute("Swapping", true)
	task.delay(start - clock, function()
		if held[holder] == entry then
			local count = holder:GetAttribute("Rose")
			holder:SetAttribute("RoseFrom", entry.From)
			holder:SetAttribute("Rose", (if type(count) == "number" then count else 0) + 1)
		end
	end)
	task.delay(start - clock + swap, function()
		if held[holder] == entry then
			held[holder] = nil
			holder:SetAttribute("Swapping", false)
			redraw(number)
		end
	end)
	return entry.From
end

-- A machine's stage shown (TR51; AR32 to AR35): the pieces of the stage it stands at standing and the others' hidden,
-- none of them while it's asleep (`awake` false: a bay not yet opened). Says that stage.
local function showStage(holder: Instance, stage: number, seen: boolean, awake: boolean?, number: number, clock: number): number
	local drawn = stageNow(holder, stage, seen, awake, number, clock)
	for _, group in holder:GetChildren() do
		local at = group:GetAttribute("Stage")
		if group:IsA("Model") and type(at) == "number" then
			for _, part in group:GetChildren() do
				if part:IsA("BasePart") then
					WorldService.Stand(part, awake ~= false and at == drawn)
				end
			end
		end
	end
	return drawn
end

-- Every turning stage piece in `holder` (a Breaker's hinges, a bay's rings) on or off.
local function spin(holder: Instance, on: boolean)
	for _, part in holder:GetDescendants() do
		if part:GetAttribute("Spinning") ~= nil then
			part:SetAttribute("Spinning", on)
		end
	end
end

local NO_BASE: BaseLevels.StagedBase = { Level = 1, Machines = {}, Bays = {} }

-- What the stages read of a save's base (Rules.BaseLevels.Stages).
local function staged(base: Profile.Base): BaseLevels.StagedBase
	local bays = {}
	for index, bay in base.Bays do
		bays[index] = { Level = bay.Level }
	end
	return { Level = base.Level, Machines = base.Machines, Bays = bays }
end

local function showPlot(number: number, data: Profile.Data?, seen: boolean?, owner: Player?)
	local plant = Markers.Find("Generator", { Plot = number })
	local rates = if data then Breaker.Rates(data) else nil
	local generation = if rates then rates.Generation else 0
	local gauge = Power.Gauge(generation, if rates then rates.Demand else 0, WorldConfig.Grey.Generator.Gauge)
	local stages = BaseLevels.Stages(if data then staged(data.Base) else NO_BASE)
	local landing = seen == true and data ~= nil
	local clock = os.clock() -- one instant for every machine, so a base level-up's land together
	if not landing then
		for holder, entry in held do -- a plot changing hands, or its owner gone: shown as it is at once
			if entry.Plot == number then
				held[holder] = nil
				holder:SetAttribute("Swapping", false)
			end
		end
	end
	showOwner(number, data, owner)
	if plant then
		local stage = stageNow(plant, stages.Generator, landing, true, number, clock)
		for _, group in plant:GetChildren() do
			local at = group:GetAttribute("Stage")
			if not group:IsA("Model") or type(at) ~= "number" then
				continue
			end
			local shown = at == stage
			for _, part in group:GetChildren() do
				if not part:IsA("BasePart") then
					continue
				end
				local index = part:GetAttribute("Step")
				if type(index) == "number" then
					part.Transparency = if shown and index <= gauge.Lit then 0 else 1 -- shown or hidden, never dimmed
				elseif part:GetAttribute("Unseen") == true then
					part.CanCollide, part.CanQuery = shown, shown -- the generator's well: never seen, solid while shown
				else
					WorldService.Stand(part, shown)
				end
				if part.Name == "Core" then
					part:SetAttribute("Generation", generation)
				elseif part.Name == "Demand" then
					part:SetAttribute("Share", gauge.Demand)
				end
			end
		end
	end
	local open = if data then #data.Base.Bays else BaseLevels.Bays(1)
	for _, bay in Markers.All("Bay") do
		local index = bay:GetAttribute("Bay")
		if bay:GetAttribute("Plot") ~= number or type(index) ~= "number" then
			continue
		end
		local awake = index <= open
		local pad, sleeping = bay:FindFirstChild("Pad"), bay:FindFirstChild("Sleeping")
		if sleeping and sleeping:IsA("BasePart") then
			WorldService.Stand(sleeping, not awake)
			if pad and pad:IsA("BasePart") then -- the grey stand-in's pad, or the kit's before its stages
				WorldService.Stand(pad, awake)
			end
		end
		local wake = bay:FindFirstChild("Wake") -- its light on the deck while it's awake (AR54)
		if wake and wake:IsA("BasePart") then
			WorldService.Stand(wake, awake)
		end
		-- Its stage at its own level while it's awake (TR51; AR33), its rings turning while a worker works there.
		showStage(bay, stages.Bays[index] or 1, landing, awake, number, clock)
		local seat = if data and awake then data.Base.Bays[index] else nil
		local id = if seat then seat.Worker else ""
		local owned = if id ~= "" and data then data.Voidkin[id] else nil
		showWorker(bay, number, index, id, if owned then owned.Def else nil)
		spin(bay, owned ~= nil)
	end
	-- AR50's pieces of each base level past the first (WorldService's "Levels"), beside the level's under them: a
	-- level-up's stand at its generator's swap, under the landing's cover, so they never show before it.
	local base = if plant then plant.Parent else nil
	local levels = if base then base:FindFirstChild("Levels") else nil
	if levels then
		local drawn = levels:GetAttribute("Level")
		if type(drawn) ~= "number" or held[plant :: Instance] == nil then
			drawn = if data then data.Base.Level else 1
			levels:SetAttribute("Level", drawn)
		end
		for _, part in levels:GetChildren() do
			local from = part:GetAttribute("BaseLevel")
			if part:IsA("BasePart") and type(from) == "number" then
				WorldService.Stand(part, (drawn :: number) >= from)
			end
		end
	end
	local battery = Markers.Find("Battery", { Plot = number })
	if battery then
		-- Its rack at the base's level (TR51; AR34), and its cells as many as the level holds and that rack seats.
		local stage = showStage(battery, stages.Battery, landing, nil, number, clock)
		local rack = battery:FindFirstChild(`Stage {stage}`)
		local seats = if rack then rack:GetAttribute("Seats") else nil
		local shown = math.min(BaseLevels.Cells(if data then data.Base.Level else 1), if type(seats) == "number" then seats else math.huge)
		local lit = if data then Breaker.Cells(data.Base) else {}
		for _, cell in battery:GetChildren() do
			local seat = cell:GetAttribute("Cell")
			if type(seat) == "number" and cell:IsA("BasePart") then
				WorldService.Stand(cell, seat <= shown)
				cell:SetAttribute("Lit", lit[seat] or 0)
			end
		end
	end
	local trainer = Markers.Find("Training", { Plot = number })
	if trainer then
		showStage(trainer, stages.Training, landing, nil, number, clock) -- its crown at the base's level (TR51; AR35)
		local training = data ~= nil and Breaker.Trainee(data) ~= nil
		for _, crown in trainer:GetDescendants() do
			if crown.Name == "Crown" and crown:GetAttribute("Training") ~= nil then
				crown:SetAttribute("Training", training)
			end
		end
	end
	local condenser = Markers.Find("Condenser", { Plot = number })
	if condenser then
		-- The Stone Condenser (TR37): its sleeping stone until the base wakes it, then its Comb at Stage I, the comb's cups
		-- lit by the tray's fill of its cap (Rules.Condenser.Lit) and its core turning while it works, at its power's speed
		-- ("Pace"). "Held" and "Cap" say the tray, for the client and the tests.
		local awake = data ~= nil and Condenser.Awake(data.Base.Level)
		local cups = condenser:GetAttribute("Cups")
		local lit = if data and awake then Condenser.Lit(data.Base, if type(cups) == "number" then cups else 0) else 0
		for _, part in condenser:GetChildren() do
			if not part:IsA("BasePart") then
				continue
			end
			local cup = part:GetAttribute("Cup")
			if part.Name == "Asleep" then
				WorldService.Stand(part, not awake)
			elseif type(cup) == "number" then
				part.Transparency = if awake and cup <= lit then 0 else 1 -- shown or hidden, never solid
			else
				WorldService.Stand(part, awake)
			end
		end
		local core = condenser:FindFirstChild("Core")
		if core then
			core:SetAttribute("Spinning", data ~= nil and awake and Condenser.Working(data.Base))
			core:SetAttribute("Pace", if rates then rates.Condenser else 1)
		end
		condenser:SetAttribute("Held", if data then Condenser.Held(data.Base) else 0)
		condenser:SetAttribute("Cap", if data then Condenser.Cap(Condenser.Level(data.Base)) else 0)
		condenser:SetAttribute("Awake", awake)
	end
	local breaker = Markers.Find("Breaker", { Plot = number })
	if breaker == nil then
		return
	end
	-- Its stage at its own level (TR51; AR32), BreakerLamp at that stage's crystal, its chambers that stage has, each
	-- shown while the Breaker has it and its lid until it does, and its hinges turning while any chamber breaks.
	local stage = showStage(breaker, stages.Breaker, landing, nil, number, clock)
	local group = breaker:FindFirstChild(`Stage {stage}`)
	local lampAt = if group then group:GetAttribute("Lamp") else nil
	local dressing = (breaker.Parent :: Instance):FindFirstChild("Dressing")
	local lamp = if dressing then dressing:FindFirstChild("BreakerLamp") else nil
	if typeof(lampAt) == "CFrame" and lamp and lamp:IsA("BasePart") and lamp.CFrame ~= lampAt then
		lamp.CFrame = lampAt
	end
	local has = if data then #data.Base.Chambers else BaseConfig.Start.Chambers
	local breaking = false
	local index = 1
	while true do
		local chamber = breaker:FindFirstChild(`Chamber {index}`)
		if chamber == nil then
			break
		end
		local from = chamber:GetAttribute("From")
		local there = type(from) ~= "number" or from <= stage
		if type(from) == "number" and chamber:IsA("BasePart") then
			WorldService.Stand(chamber, there and index <= has)
		end
		local lid = breaker:FindFirstChild(`Lid {index}`)
		if lid and lid:IsA("BasePart") then
			WorldService.Stand(lid, there and index > has)
		end
		local held = if data then data.Base.Chambers[index] else nil
		local working = held ~= nil and held.Work ~= nil
		breaking = breaking or working
		if chamber:GetAttribute("Working") ~= nil then
			chamber:SetAttribute("Working", working)
		end
		local shard = breaker:FindFirstChild(`Shard {index}`)
		if shard and shard:IsA("BasePart") then
			shard.Transparency = if working then 0 else 1
		end
		index += 1
	end
	spin(breaker, breaking)
end

local shown: { [Player]: number } = {} -- the plot whose machines show each player's base

-- A Reinforce try made (TR37; design.md, "Upgrading gear needs no walk"): its owner's Forge's ram strikes, on every
-- client ("Strikes" counts one more; BaseController plays it), wherever the try was made.
local function strike(player: Player)
	local number = shown[player]
	local forge = if number then Markers.Find("Forge", { Plot = number }) else nil
	local ram = if forge then forge:FindFirstChild("Ram") else nil
	if ram then
		local count = ram:GetAttribute("Strikes")
		ram:SetAttribute("Strikes", (if type(count) == "number" then count else 0) + 1)
	end
end

function redraw(number: number)
	for player, plot in shown do
		if plot == number then
			showPlot(number, DataService.Get(player), true, player)
			return
		end
	end
	showPlot(number, nil)
end

local function show(player: Player)
	local number = WorldService.PlotOf(player)
	local was = shown[player]
	if was and was ~= number then
		showPlot(was, nil)
	end
	shown[player] = number
	if number then
		showPlot(number, DataService.Get(player), was == number, player) -- a rise lands only on the plot it was seen on
	end
end

local function registerDebug()
	-- Studio only. Each bay's worker as the save holds it, "" for none, so the self-test puts back what a case left
	-- (a lead swapped in and back takes its worker out of its bay: Collection.SetLead).
	DebugService.Register("Bays", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		local data = player and DataService.Get(player)
		if not data then
			return nil
		end
		local workers: { string } = {}
		for index, bay in data.Base.Bays do
			workers[index] = bay.Worker
		end
		return workers
	end)
	-- Studio only. A readout of the base, time passing without waiting for it, and shards in the bag.
	DebugService.Register("Base", function(who: any): any
		local player = DebugService.ResolvePlayer(who)
		local data = player and DataService.Get(player)
		if not data then
			return nil
		end
		local base = data.Base
		local chambers = {}
		for index, chamber in base.Chambers do
			local work = chamber.Work
			local seconds = work and Breaker.Cost(work.Def)
			chambers[index] = if work then `{work.Def} {string.format("%.1f", work.Done)}/{seconds}` else "empty"
		end
		local line = {}
		for _, work in base.Line do
			table.insert(line, work.Def)
		end
		local ready = {}
		for _, work in base.Ready do
			table.insert(ready, work.Def)
		end
		local workers = {}
		for index, bay in base.Bays do
			workers[index] = if bay.Worker == "" then "empty" else `{bay.Worker} ({data.Voidkin[bay.Worker].Def})`
		end
		local rates = Breaker.Rates(data)
		return {
			Charge = `{string.format("%.3f", base.Charge)}/{Breaker.Capacity(base)} kWh`,
			Generation = rates.Generation,
			Demand = rates.Flow.Demand,
			Speed = rates.Flow.Speed,
			NetKw = rates.NetKw,
			Power = { Auto = base.Power.Auto, Shares = base.Power.Shares, Open = base.Power.Open },
			Trainee = data.Training.Trainee,
			Chambers = chambers,
			Line = line,
			Ready = ready,
			Bays = workers,
			Bag = data.Bag.Shards,
			Lead = data.Roles.Lead,
			Credits = data.Currency.Credits,
			NextEvent = Breaker.NextEvent(data),
			StampAge = now() - base.Stamp,
		}
	end)
	-- As if `seconds` passed, online or away: the stamp moves back, then the base advances to now.
	DebugService.Register("BaseSkip", function(who: any, seconds: any, away: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(seconds) ~= "number" or seconds <= 0 or seconds ~= seconds then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseSkip", function(draft: Profile.Data): { [string]: any }
			if draft.Base.Stamp == 0 then
				return { Ok = false, Error = "NoStamp" }
			end
			draft.Base.Stamp -= seconds
			local summary = Breaker.Advance(draft, now(), away == true)
			return { Ok = true, Finished = summary.Finished, Made = summary.Made, Credits = summary.Credits, Trained = summary.Trained or "", Levels = summary.Levels }
		end)
	end)
	-- The battery's charge set to `amount` kWh, within its capacity: the Breaker screen's prices tried at each side (TR9).
	DebugService.Register("BaseBattery", function(who: any, amount: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(amount) ~= "number" or amount ~= amount then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseBattery", function(draft: Profile.Data): { [string]: any }
			Breaker.Advance(draft, now())
			local before = draft.Base.Charge
			draft.Base.Charge = math.clamp(amount, 0, Breaker.Capacity(draft.Base))
			return { Ok = true, Charge = draft.Base.Charge, Before = before }
		end)
	end)
	-- The Power screen opened or shut, as if a machine beside the Breaker had drawn power or never had; shut, Auto again
	-- (TR18's case: the screen and its refusal before it opens).
	DebugService.Register("PowerOpen", function(who: any, open: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(open) ~= "boolean" then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "PowerOpen", function(draft: Profile.Data): { [string]: any }
			Breaker.Advance(draft, now())
			draft.Base.Power.Open = open
			if not open then
				draft.Base.Power.Auto = true
			end
			return { Ok = true, Open = open }
		end)
	end)
	-- Studio only. The base's level set as it is, nothing else touched, so a case shows a stage and puts the level back
	-- (the generator's stages, AR19). Bought levels go through Act("UpgradeBase").
	DebugService.Register("BaseLevel", function(who: any, level: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or type(level) ~= "number" or level ~= math.floor(level) or level < 1 or level > BaseLevels.Top() then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseLevel", function(draft: Profile.Data): { [string]: any }
			local was = draft.Base.Level
			draft.Base.Level = level
			return { Ok = true, Was = was, Level = level }
		end)
	end)
	-- Studio only. A machine's level set as it is (the Breaker's, the Condenser's, or bay `bay`'s), nothing else touched,
	-- not even its chambers, so a case shows each stage, a lid where the Breaker hasn't its chamber yet, and puts the
	-- level back (TR51; the Condenser's for TR56's Mid into High). Bought levels go through Act("UpgradeMachine").
	DebugService.Register("MachineLevel", function(who: any, machine: any, level: any, bay: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or (machine ~= "Breaker" and machine ~= "Condenser" and machine ~= "Bay") or type(level) ~= "number" or level ~= math.floor(level) or level < 1 then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "MachineLevel", function(draft: Profile.Data): { [string]: any }
			if machine == "Breaker" or machine == "Condenser" then
				local was = draft.Base.Machines[machine] or 1
				draft.Base.Machines[machine] = level
				return { Ok = true, Was = was, Level = level }
			end
			local seat = if type(bay) == "number" then draft.Base.Bays[bay] else nil
			if seat == nil then
				return { Ok = false, Error = "NoBay" }
			end
			local was = seat.Level
			seat.Level = level
			return { Ok = true, Was = was, Level = level }
		end)
	end)
	DebugService.Register("BaseGive", function(who: any, shard: any, count: any): any
		local player = DebugService.ResolvePlayer(who)
		local amount = if count == nil then 1 else count
		if not player or type(shard) ~= "string" or Shards.ById[shard] == nil or type(amount) ~= "number" or amount == 0 or amount ~= math.floor(amount) then
			return { Ok = false, Error = "BadArgs" }
		end
		return DataService.Change(player, "BaseGive", function(draft: Profile.Data): { [string]: any }
			local held = math.max(0, (draft.Bag.Shards[shard] or 0) + amount) -- a negative count takes them out, never below none
			draft.Bag.Shards[shard] = if held > 0 then held else nil
			return { Ok = true, Held = held }
		end)
	end)
	-- Studio only. The return card set as `card` says (TR53's cases lay each line and put the card back), nil for none.
	-- What it shows is never credited: the arrival credits, and this stands in for one. `card`'s parts left out are none.
	DebugService.Register("ReturnCardSet", function(who: any, card: any): any
		local player = DebugService.ResolvePlayer(who)
		if not player or (card ~= nil and type(card) ~= "table") then
			return { Ok = false, Error = "BadArgs" }
		end
		local function counts(from: any): { [string]: number }
			local out = {}
			for key, n in (if type(from) == "table" then from else {}) do
				if type(key) == "string" and type(n) == "number" and n > 0 then
					out[key] = n
				end
			end
			return out
		end
		return DataService.Change(player, "ReturnCardSet", function(draft: Profile.Data): { [string]: any }
			local was = draft.Base.Card
			if card == nil then
				draft.Base.Card = nil
			else
				local shards = {}
				for _, def in (if type(card.Shards) == "table" then card.Shards else {}) do
					if type(def) == "string" and Shards.ById[def] then
						table.insert(shards, def)
					end
				end
				draft.Base.Card = {
					Kwh = if type(card.Kwh) == "number" then card.Kwh else 0,
					Full = card.Full == true,
					Credits = if type(card.Credits) == "number" then card.Credits else 0,
					Stones = counts(card.Stones),
					Trained = counts(card.Trained),
					Worked = counts(card.Worked),
					Shards = shards,
				}
			end
			return { Ok = true, Was = was, Lines = #Return.Lines(draft.Base.Card) }
		end)
	end)
end

function BaseService.Init()
	for name, action in BaseRules.Actions do
		DataService.Action(name, function(draft: Profile.Data, args: any): { [string]: any }
			return action(draft, args, now(), rng:NextNumber())
		end)
	end
	if RunService:IsStudio() then
		registerDebug()
	end
end

function BaseService.Start()
	DataService.Ready:Connect(onReady)
	DataService.Changed:Connect(function(player: Player, _data: any, _answer: any, label: string?)
		schedule(player)
		show(player)
		if label == "Reinforce" then
			strike(player)
		end
	end)
	local function joined(player: Player)
		player:GetAttributeChangedSignal("Plot"):Connect(function()
			show(player)
		end)
		show(player)
	end
	Players.PlayerAdded:Connect(joined)
	WorldService.Laid:Connect(function() -- the plots were laid again: new chambers
		for _, player in Players:GetPlayers() do
			show(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local timer = timers[player]
		timers[player] = nil
		if timer then
			task.cancel(timer)
		end
		local was = shown[player]
		shown[player] = nil
		if was then
			showPlot(was, nil)
		end
	end)
	for _, player in Players:GetPlayers() do -- a save opened before this Start connected; a second advance is a no-op
		joined(player)
		if DataService.Get(player) then
			onReady(player)
		end
	end
end

return BaseService
