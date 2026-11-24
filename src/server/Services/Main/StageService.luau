--!strict
-- StageService (server): a ground's one mission on Normal and Hard, a run of its stretches to its keeper (docs/test-
-- requests.md, TR43, TR50; Rules.Stages; Config.Stages). A run is one player's, held here while it lasts and never saved;
-- it begins at its difficulty's checkpoint (Rules.Stages.Checkpoint). A stretch's clear is written (the checkpoint moves
-- on), its line's check plays for Config.Stages.Results.After, and the run moves on to the next stretch; the keeper's
-- clear ends it with its one card. A stage below is a stretch.
-- * Normal plays the shared street: the stage's packs and its elite are everyone's (PackService), and a fall counts for
--   every hitter running that stage, the elite's for everyone who hit it.
-- * Hard stands the stage's own foes for the player alone, Config.Stages.Offset.Hard levels up, on the same markers
--   (FightService's For), and their lead fights alone (FightService.SetSolo): the street's Shades and it leave each other
--   be. A pack of them stands again Config.World.Row.Respawn after its last falls, while the run lasts. The keeper's stage
--   on Hard lifts the keeper's level (KeeperService.LevelOf).
-- * A stretch's gate (StageGate) is shut to a player in a run until the run's stretch there is done (Rules.Stages.Through),
--   and outside a run until they've cleared that stretch on Normal: a walk across it going up the street sets them back
--   Config.World.Row.GateSet before it. A set-down past it isn't a walk (the panel's, the keeper's exit, a test's:
--   Config.Stages.Gate), and walking back down is always free.
-- * The Festival Door: a fresh player (Rules.Stages.Fresh) starts the first stretch on Normal where it lands, with no
--   screen; anyone else is sent the Arc panel (Net StagePick), whose Normal and Hard begin a run (Net Stage) at that
--   difficulty's checkpoint, set down where that stretch starts.
-- * A keeper's try is its stretch's: a run on Normal begins at it when no run is on there and the stretch is open, and
--   the try's win (KeeperService.Won) is its stretch's last stop.
-- * A run ends when the keeper's stretch is done (its card: Net StageDone, Rules.Stages.After later, past the fade), when
--   another begins, when the player leaves the street (Config.Stages.Off: once they've stood on it in the run, so a
--   set-down still fading in from afar isn't a leave) or the game, or when their lead falls (its card says so, and where
--   the next run begins). The checkpoint stays through all but the keeper's fall.
-- The player's attributes carry the run to the client: StageRun ("Normal 2", its stretch), StageKills, StageQuota,
-- StageLast.
-- Studio:
--   NL_Debug:Invoke("Stage")                                 the run, the gates shut to the player, their record
--   NL_Debug:Invoke("StageBegin", nil, difficulty, stage?)   a run begins, at `stage` or the checkpoint as the panel
--   NL_Debug:Invoke("StageArrive", nil)                      as if the player had just come through the base's door: the
--                                                            menu there; in the Festival, an arrival with no ticket
--   NL_Debug:Invoke("StageArriveBy", nil, difficulty, stage)  in the Festival, an arrival with a ticket for that stage
--   NL_Debug:Invoke("StageFell", nil, group)                 fells a group's standing Shades ("Pack 1", "Elite 1", or a
--                                                            Hard run's own: "Elite 1 mine"), the player their hitter
--   NL_Debug:Invoke("StageLine", nil, difficulty, cleared, reached?)  the record on Lantern Row: its cleared count (0
--                                                            wipes it) and its checkpoint (nil or 1: the first)
--   NL_Debug:Invoke("StageLog", nil)                         the runs this server has logged, newest last
-- Each run's length is logged at its end (TR48: the pace model swings 2 to 2.5 times on it), from its beginning to its
-- clear or its end, the walk between stops and every wait included: a line in the server's output, and in a live game
-- Roblox's custom event "StageRunSeconds" (AnalyticsService), its fields the stage and how it ended. No personal data.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local Markers = require(Shared.World.Markers)
local Stages = require(Shared.Rules.Stages)
local Fight = require(Shared.Rules.Fight)
local Profile = require(Shared.Data.Profile)
local Parts = require(Shared.Util.Parts)
local Log = require(Shared.Util.Log)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)
local FightService = require(script.Parent.FightService)
local KeeperService = require(script.Parent.KeeperService)
local DoorService = require(script.Parent.DoorService)
local TravelService = require(script.Parent.TravelService)
local GoalService = require(script.Parent.GoalService)
local TravelConfig = require(Shared.Config.Travel)
local Travel = require(Shared.Rules.Travel)
local PlaceRole = require(Shared.Util.PlaceRole)

-- The Festival of Battles is its own place (TR45): its stages run there, and the base's picker sends the player there.
local FESTIVAL = PlaceRole.Is("Festival")

local StageService = {
	Priority = 48, -- after the packs, the keeper and the doors, whose signals it hears
}

type Run = {
	Rule: Stages.Run,
	Foes: { [FightService.Fighter]: string }, -- a Hard run's own Shades, by their group's marker name
	Groups: { [string]: Instance }, -- a Hard run's markers, by name: where each group stands again
	Before: Stages.Gave, -- the save's holdings as it began, for what it gave (Stages.Won)
	Ending: boolean,
	OnStreet: boolean, -- the player has stood on the street since it began: from then, off it ends the run
	Began: number, -- os.clock() it began, for its length (TR48)
	Logged: boolean, -- its length is logged
}

local runs: { [Player]: Run } = {}
local LOG_KEPT = 50 -- the runs the Studio log keeps
local logged: { { Stage: string, How: string, Seconds: number } } = {} -- this server's logged runs, oldest first (StageLog)

-- `run`'s length, logged once: "Cleared" at its clear, else how it ended (TR48).
local function logRun(player: Player, run: Run, how: string)
	if run.Logged then
		return
	end
	run.Logged = true
	local seconds = math.floor((os.clock() - run.Began) * 10 + 0.5) / 10
	local stage = Stages.Label(run.Rule)
	Log.Info("StageService", `stage run {stage}: {how} after {seconds} s`)
	table.insert(logged, { Stage = stage, How = how, Seconds = seconds })
	if #logged > LOG_KEPT then
		table.remove(logged, 1)
	end
	if not RunService:IsStudio() then
		local ok, err = pcall(function()
			AnalyticsService:LogCustomEvent(player, "StageRunSeconds", seconds, {
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = stage,
				[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = how,
			})
		end)
		if not ok then
			Log.Warn("StageService", `a run's length wasn't logged: {err}`)
		end
	end
end

-- The run, as the client reads it (Stages.Published).
local function publish(player: Player, run: Run?)
	local view = Stages.Published(if run then run.Rule else nil)
	player:SetAttribute("StageRun", view.StageRun)
	player:SetAttribute("StageKills", view.StageKills)
	player:SetAttribute("StageQuota", view.StageQuota)
	player:SetAttribute("StageLast", view.StageLast)
end

-- A run's markers of one kind ("Pack" or "Elite") in its stage.
local function markersOf(rule: Stages.Run, kind: string): { Instance }
	local found = {}
	for _, marker in Markers.All(kind) do
		if marker:GetAttribute("Stage") == rule.Stage and marker:GetAttribute("Ground") == rule.Ground then
			table.insert(found, marker)
		end
	end
	return found
end

-- A Hard run's group `name` standing at its marker, for `player` alone, its level lifted.
local function stand(player: Player, run: Run, name: string)
	local marker = run.Groups[name]
	if marker == nil then
		return -- its stretch is behind the run now
	end
	local def, level, count, type_ = marker:GetAttribute("Def"), marker:GetAttribute("Level"), marker:GetAttribute("Count"), marker:GetAttribute("Type")
	if type(def) ~= "string" or type(level) ~= "number" then
		return
	end
	local hard = marker:GetAttribute("Hard") -- its own on Hard (AR57: the square's elite)
	def = Stages.DefOn({ Def = def, Hard = if type(hard) == "string" then hard else nil }, run.Rule.Difficulty)
	local at = Markers.At(marker)
	local n = if type(count) == "number" then count else 1
	local with, withCount = marker:GetAttribute("With"), marker:GetAttribute("WithCount")
	local rear, rearCount = marker:GetAttribute("Rear"), marker:GetAttribute("RearCount")
	local spots = Fight.PackSpots(def, n, if type(with) == "string" then with else nil, if type(withCount) == "number" then withCount else nil, if type(rear) == "string" then rear else nil, if type(rearCount) == "number" then rearCount else nil, WorldConfig.Row.Spread, WorldConfig.Row.Behind)
	for _, place in spots do
		local f = FightService.SpawnEnemy(place.Def, Stages.Level(level, run.Rule.Difficulty), at * CFrame.new(place.X, 0, place.Z), {
			Type = if type(type_) == "string" then type_ else nil,
			Pack = `{name} for {player.UserId}`,
			Ground = run.Rule.Ground,
			Stage = run.Rule.Stage,
			Difficulty = run.Rule.Difficulty,
			For = player,
		})
		run.Foes[f] = name
		f.Model.Destroying:Connect(function()
			run.Foes[f] = nil -- gone without falling: a cleanup
		end)
	end
end

-- Ends `player`'s run, if any: its own foes go, its lead fights the street again. No card.
function StageService.End(player: Player)
	local run = runs[player]
	if run == nil then
		return
	end
	runs[player] = nil
	logRun(player, run, "Ended")
	run.Ending = true
	for f in run.Foes do
		run.Foes[f] = nil
		FightService.Remove(f)
	end
	FightService.SetSolo(player, false)
	GoalService.Stop(player)
	publish(player, nil)
end

-- A Hard run's own Shades of its stretch, standing for `player` alone: each group at its marker.
local function standStretch(player: Player, run: Run)
	for _, kind in { "Pack", "Elite" } do
		for _, marker in markersOf(run.Rule, kind) do
			local name = marker.Name
			run.Groups[name] = marker
			stand(player, run, name)
		end
	end
end

-- A run on `difficulty` begins for `player` at stretch `stage`, or at that difficulty's checkpoint (nil), set down at its
-- start unless `stay` (the Door's own landing). { Ok, Stage } or { Ok = false, Error, Needs?, Waits? }.
function StageService.Begin(player: Player, ground: string, difficulty: string, stage: number?, stay: boolean?): { [string]: any }
	local data = DataService.Get(player)
	local lead = FightService.LeadOf(player)
	if data == nil then
		return { Ok = false, Error = "NoData" }
	elseif player:GetAttribute("Try") ~= nil then
		return { Ok = false, Error = "InTry" }
	elseif lead == nil or not FightService.Standing(lead) then
		return { Ok = false, Error = "NoLead" }
	end
	local at = stage or Stages.Checkpoint(data, ground, difficulty)
	local rule, refusal = Stages.Start(data, ground, difficulty, at, os.time())
	if rule == nil then
		local needs, waits = Stages.Needs(data, ground, difficulty, at)
		return { Ok = false, Error = refusal, Needs = needs, Waits = waits }
	end
	local start = Markers.Find("StageStart", { Stage = at, Ground = ground })
	if start == nil then
		return { Ok = false, Error = "NoStart" }
	end
	StageService.End(player)
	local run: Run = { Rule = rule, Foes = {}, Groups = {}, Before = Stages.Holdings(data), Ending = false, OnStreet = false, Began = os.clock(), Logged = false }
	runs[player] = run
	if difficulty ~= "Normal" then
		FightService.SetSolo(player, true)
		standStretch(player, run)
	end
	publish(player, run)
	GoalService.Stretch(player, rule) -- the stretch's dare unfolds under the run's line (TR54)
	GoalService.Led(player)
	if not stay then
		KeeperService.SetDown(player, Markers.At(start))
	end
	return { Ok = true, Stage = at }
end

-- A stretch done: its clear written once (the checkpoint moves on with it), and its line's check plays. Then,
-- Config.Stages.Results.After later, the run moves on to the next stretch (a Hard run's own Shades of it standing), or at
-- the keeper's it ends with its card: the whole run's time and what it gave.
local function finish(player: Player, run: Run)
	local rule = run.Rule
	local count = #(Stages.Of(rule.Ground) :: { any })
	local judged = GoalService.Judge(player, rule) -- the stretch's dare, judged as it clears; its stone paid in the same step
	local answer = DataService.Change(player, "StageClear", function(draft)
		local cleared = Stages.Clear(draft, rule, os.time())
		if cleared.Ok == true then
			GoalService.Pay(draft, judged)
		end
		return cleared
	end)
	if answer.Ok == true then
		GoalService.Paid(player, judged)
	else
		Log.Error("StageService", `{player.Name}'s clear of {rule.Ground} {rule.Difficulty} {rule.Stage} wasn't saved: {tostring(answer.Error)}`)
		rule.Claimed = true -- the run still moves on; only the record missed it
	end
	local ends = rule.Stage >= count
	if ends then
		run.Ending = true
		logRun(player, run, "Cleared")
	end
	publish(player, run)
	task.delay(Stages.After(rule.Ground, rule.Stage), function()
		if runs[player] ~= run then
			return
		end
		if not ends then
			if run.Ending or not Stages.Advance(rule, os.time()) then
				return
			end
			if rule.Difficulty ~= "Normal" then
				for f in run.Foes do
					run.Foes[f] = nil
					FightService.Remove(f)
				end
				table.clear(run.Groups)
				standStretch(player, run)
			end
			publish(player, run)
			GoalService.Stretch(player, rule)
			return
		end
		local results = Stages.Won(rule, answer, run.Before, Stages.Holdings(DataService.Get(player)))
		results.Dares = GoalService.Card(player)
		Net.Server.Fire("StageDone", player, results)
		StageService.End(player)
	end)
end

-- The run's end on its lead's fall: its card says so, and where the next run on its difficulty begins.
local function lose(player: Player, run: Run)
	logRun(player, run, "Fell")
	local results = Stages.Lost(run.Rule, DataService.Get(player))
	results.Dares = GoalService.Card(player) -- a fall takes back no dare kept before it
	StageService.End(player)
	Net.Server.Fire("StageDone", player, results)
end

local function fell(f: FightService.Fighter, hitters: { Player })
	-- A Hard run's own foe: its pack stands again once the last of it is down.
	for player, run in runs do
		local name = run.Foes[f]
		if name == nil then
			continue
		end
		run.Foes[f] = nil
		local marker = run.Groups[name]
		if Stages.Regrows(run.Foes, name, marker ~= nil and marker:GetAttribute("Pack") ~= nil) then
			task.delay(WorldConfig.Row.Respawn, function()
				if runs[player] == run and not run.Ending then
					stand(player, run, name)
				end
			end)
		end
	end
	for _, player in hitters do
		local run = runs[player]
		if run and not run.Ending and Stages.Counts(run.Rule, f, player) then
			if Stages.Kill(run.Rule, f.Def) then
				finish(player, run)
			else
				publish(player, run)
			end
		end
	end
	if f.Side == "Lead" and f.Owner then
		local run = runs[f.Owner]
		if run and not run.Ending then
			lose(f.Owner, run)
		end
	end
end

-- Whether `gate` is shut to `player` (Stages.Shut): in a run there, its stretch not done in it yet; outside one, its
-- stretch not cleared on Normal.
local function shut(player: Player, gate: Instance): boolean
	local stage, ground = gate:GetAttribute("Stage"), gate:GetAttribute("Ground")
	if type(stage) ~= "number" or type(ground) ~= "string" then
		return false
	end
	local run = runs[player]
	return Stages.Shut(DataService.Get(player), if run and not run.Ending then run.Rule else nil, ground, stage)
end

-- The gates and the street's edge, every Config.Stages.Gate.Every seconds.
local seen: { [Player]: Vector3 } = {}
local function watch()
	local gates = Markers.All("StageGate")
	for _, player in Players:GetPlayers() do
		local root = Parts.Root(player.Character)
		if root == nil then
			seen[player] = nil
			continue
		end
		local now, before = root.Position, seen[player]
		seen[player] = now
		local run = runs[player]
		if run and run.Rule.Difficulty ~= "Normal" and not run.Ending then
			FightService.SetSolo(player, true) -- a lead summoned anew mid-run fights alone too
		end
		if run and not run.Ending and player:GetAttribute("Try") == nil then
			local first = Markers.Find("StageStart", { Stage = 1, Ground = run.Rule.Ground })
			local off = first ~= nil and now.Z > Markers.At(first).Position.Z + StagesConfig.Off
			if off and run.OnStreet then
				StageService.End(player) -- off the street, back toward the Strip
			elseif first and not off then
				run.OnStreet = true
			end
		end
		if before == nil or (now - before).Magnitude >= StagesConfig.Gate.Walk then
			continue
		end
		for _, gate in gates do
			if not gate:IsA("BasePart") then
				continue
			end
			local z = gate.Position.Z
			local across = before.Z > z and now.Z <= z -- up the street is -Z
			if across and math.abs(now.X - gate.Position.X) < gate.Size.X / 2 + 4 and shut(player, gate) then
				local back = Vector3.new(now.X, now.Y, z + WorldConfig.Row.GateSet)
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = CFrame.lookAt(back, back + Vector3.new(0, 0, -1))
				seen[player] = back
				Net.Server.Fire("StageGate", player, { Stage = gate:GetAttribute("Stage"), Ground = gate:GetAttribute("Ground") })
				break
			end
		end
	end
end

-- A pick in the base's place: the trip to the Festival, into that difficulty's run at its checkpoint, if the save opens
-- it and the lead stands. The Festival checks again on arrival (Travel.Arrival).
function StageService.Travel(player: Player, ground: string, difficulty: string): { [string]: any }
	local data = DataService.Get(player)
	if data == nil then
		return { Ok = false, Error = "NoData" }
	elseif player:GetAttribute("Try") ~= nil then
		return { Ok = false, Error = "InTry" }
	elseif not FightService.Standing(FightService.LeadOf(player)) then
		return { Ok = false, Error = "NoLead" }
	end
	local way = Stages.Way(data, ground, difficulty)
	if not way.Ok then
		return way
	end
	local ok, err = TravelService.ToStage(player, ground, difficulty, way.Stage)
	return { Ok = ok, Error = err, Travel = true }
end

-- Arriving in the Festival's place, or through its door in Studio's StageArrive: the ticket's stage begins if the save
-- opens it; else a fresh player's first stage, or the picker where they land (Travel.Arrival). The lead stands first,
-- Config.Travel.Hold seconds at most; then the trip's card lifts.
function StageService.Arrived(player: Player, ticket: Travel.Ticket?)
	local data = DataService.Get(player)
	if data == nil then
		return
	end
	local ground = WorldConfig.Row.Ground
	local decision = Travel.Arrival(ticket, data, ground)
	local waited = 0
	while player.Parent and not FightService.Standing(FightService.LeadOf(player)) and waited < TravelConfig.Hold do
		waited += task.wait(0.2)
	end
	if player.Parent == nil then
		return
	end
	local begun = false
	if decision.Begin then
		local answer = StageService.Begin(player, ground, decision.Difficulty :: string, decision.Stage :: number, ticket == nil)
		begun = answer.Ok == true
		if not begun then
			Log.Warn("StageService", `{player.Name}'s stage on arriving didn't begin: {tostring(answer.Error)}`)
		end
	end
	if not begun then
		StageService.End(player)
		Net.Server.Fire("StagePick", player, { Ground = ground, Refused = decision.Refused })
	end
	Net.Server.Fire("Travel", player, "Arrived", {})
end

local function state(who: any): any
	local player = DebugService.ResolvePlayer(who)
	if player == nil then
		return { Ok = false, Error = "NoPlayer" }
	end
	local data = DataService.Get(player)
	local run = runs[player]
	local shutTo = {}
	for _, gate in Markers.All("StageGate") do
		if shut(player, gate) then
			table.insert(shutTo, gate:GetAttribute("Stage"))
		end
	end
	table.sort(shutTo)
	local foes = 0
	for _ in if run then run.Foes else {} do
		foes += 1
	end
	local ground = WorldConfig.Row.Ground
	return {
		Ok = true,
		Run = if run then { Difficulty = run.Rule.Difficulty, Stage = run.Rule.Stage, From = run.Rule.From, Kills = run.Rule.Kills, Last = run.Rule.Last, Done = run.Rule.Done, Foes = foes } else nil,
		Shut = shutTo,
		Fresh = if data then Stages.Fresh(data) else nil,
		Normal = if data then Stages.Line(data, ground, "Normal") else nil,
		Hard = if data then Stages.Line(data, ground, "Hard") else nil,
		Checkpoint = if data then { Normal = Stages.Checkpoint(data, ground, "Normal"), Hard = Stages.Checkpoint(data, ground, "Hard") } else nil,
		Alone = (function()
			local lead = FightService.LeadOf(player)
			return lead ~= nil and lead.Solo == true
		end)(),
	}
end

function StageService.Start()
	Net.Server.Handle("Stage", function(player: Player, ground: any, difficulty: any): { [string]: any }
		if type(ground) ~= "string" or type(difficulty) ~= "string" then
			return { Ok = false, Error = Stages.Unknown }
		end
		if not FESTIVAL then
			return StageService.Travel(player, ground, difficulty)
		end
		return StageService.Begin(player, ground, difficulty)
	end)
	FightService.Fell:Connect(fell)
	-- The base's Festival Door opens the menu, for everyone (the director, 2026-11-19: "the teleport point of the base will
	-- simply open the menu ui of the game mode"); a pick from it is the trip.
	DoorService.Through:Connect(function(player: Player, kind: string)
		if kind == "FestivalDoor" and not FESTIVAL then
			Net.Server.Fire("StagePick", player, { Ground = WorldConfig.Row.Ground })
		elseif kind == "FestivalDoor" then
			task.spawn(StageService.Arrived, player, nil)
		else
			StageService.End(player)
		end
	end)
	if FESTIVAL then
		TravelService.Arrived:Connect(function(player: Player, ticket: Travel.Ticket?)
			task.spawn(StageService.Arrived, player, ticket) -- it waits for the lead: never inside the save's own signal
		end)
	end
	KeeperService.Trying:Connect(function(player: Player, ground: string)
		local run = runs[player]
		local at = Stages.TryAt(if run then run.Rule else nil, ground)
		if at then
			StageService.Begin(player, ground, "Normal", at, true) -- refused, quietly, when the stage isn't open
		end
	end)
	KeeperService.Won:Connect(function(player: Player, ground: string)
		local run = runs[player]
		if run and not run.Ending and Stages.KeeperFell(run.Rule, ground) then
			finish(player, run)
		end
	end)
	KeeperService.LevelOf = function(player: Player, level: number): number
		local run = runs[player]
		return if run then Stages.Level(level, run.Rule.Difficulty) else level
	end
	KeeperService.DifficultyOf = function(player: Player): string
		local run = runs[player]
		return if run then run.Rule.Difficulty else "Normal"
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		StageService.End(player)
		seen[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(StagesConfig.Gate.Every)
			local ok, err = pcall(watch)
			if not ok then
				Log.Error("StageService", `the gates' watch: {err}`)
			end
		end
	end)
	if RunService:IsStudio() then
		DebugService.Register("Stage", state)
		DebugService.Register("StageLog", function(): any
			return { Ok = true, Runs = table.clone(logged) }
		end)
		DebugService.Register("StageBegin", function(who: any, difficulty: any, stage: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil or type(difficulty) ~= "string" or (stage ~= nil and type(stage) ~= "number") then
				return { Ok = false, Error = "BadArgs" }
			end
			return StageService.Begin(player, WorldConfig.Row.Ground, difficulty, stage)
		end)
		DebugService.Register("StageFell", function(who: any, group: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil or type(group) ~= "string" then
				return { Ok = false, Error = "BadArgs" }
			end
			local pack = string.gsub(group, " mine$", ` for {player.UserId}`)
			local felled = 0
			for _, f in FightService.All() do
				if f.Pack == pack and FightService.Standing(f) then
					f.Hitters[player] = true
					FightService.Defeat(f)
					felled += 1
				end
			end
			return { Ok = felled > 0, Felled = felled, Error = if felled == 0 then "NoneStanding" else nil }
		end)
		DebugService.Register("StageArrive", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil then
				return { Ok = false, Error = "NoPlayer" }
			end
			if FESTIVAL then
				task.spawn(StageService.Arrived, player, nil)
			else
				Net.Server.Fire("StagePick", player, { Ground = WorldConfig.Row.Ground })
			end
			return { Ok = true }
		end)
		-- In the Festival's place, an arrival with a ticket for that stage, read as one from GetJoinData is (TR45).
		DebugService.Register("StageArriveBy", function(who: any, difficulty: any, stage: any): any
			local player = DebugService.ResolvePlayer(who)
			if player == nil or type(difficulty) ~= "string" or type(stage) ~= "number" then
				return { Ok = false, Error = "BadArgs" }
			elseif not FESTIVAL then
				return { Ok = false, Error = "NotFestival" }
			end
			local ticket = Travel.Read(Travel.Stage(WorldConfig.Row.Ground, difficulty, stage, nil, workspace:GetServerTimeNow()))
			if ticket == nil then
				return { Ok = false, Error = "BadTicket" }
			end
			task.spawn(StageService.Arrived, player, ticket)
			return { Ok = true }
		end)
		DebugService.Register("StageLine", function(who: any, difficulty: any, cleared: any, reached: any): any
			local player = DebugService.ResolvePlayer(who)
			local ground = WorldConfig.Row.Ground
			local count = #(Stages.Of(ground) :: { any })
			if player == nil or (difficulty ~= "Normal" and difficulty ~= "Hard") or type(cleared) ~= "number" or cleared < 0 or cleared > count or cleared % 1 ~= 0 then
				return { Ok = false, Error = "BadArgs" }
			elseif reached ~= nil and (type(reached) ~= "number" or reached < 1 or reached > count or reached % 1 ~= 0 or reached > cleared + 1) then
				return { Ok = false, Error = "BadArgs" }
			end
			return DataService.Change(player, "StageLine", function(draft)
				local record: Profile.StageProgress? = draft.Progress.Stages[ground]
				if record == nil then
					local made: Profile.StageProgress = { Normal = { Cleared = 0, Best = table.create(count, 0) }, Hard = { Cleared = 0, Best = table.create(count, 0) } }
					draft.Progress.Stages[ground] = made
					record = made
				end
				local whole = record :: Profile.StageProgress
				local line = (whole :: any)[difficulty] :: Profile.StageLine
				line.Cleared = cleared
				line.Reached = if reached and reached > 1 then reached else nil
				for stage = 1, count do
					line.Best[stage] = if stage <= cleared then line.Best[stage] else 0
				end
				if cleared < count then
					line.Run = nil
				end
				if whole.Normal.Cleared == 0 and whole.Hard.Cleared == 0 then
					draft.Progress.Stages[ground] = nil
				end
				return { Ok = true }
			end)
		end)
	end
end

return StageService
