--!strict
-- PaceCases (client, Studio only): the street's pace, measured (TR69 B, "Measure before and after"). One clean Normal run
-- from StageBegin at the first stretch: the avatar walks to the nearest standing Shade of its stretch (its elite once
-- the quota is met) and the lead is left to fight, never healed. Every tenth of a second counts as fighting (the lead
-- has a target), walking (the avatar moving, no target) or standing (neither), until the run reaches the keeper's
-- stage. The camera turns to the Shade the avatar walks to once it's TURN degrees off, as a player looks at the fight
-- (the lead takes a new target in the camera's view: Config.Combat.Lead.View). Manual: a measure, never in every check.
-- Its gate, under Gate seconds standing in the whole run, is the waves' (block B): before they land it reads a miss.
-- The record is put back after.
-- Beside it, a case in every check: a wave stood while you owe the quota steps out at your lead (PackService), in the
-- place that has the street, the switch on by a Tune for the case and put back after.
-- And a second measure, the Session (TR72 item 4: research asked for a player's hour, not a clean run): CYCLES Normal
-- runs back to back on the level-9 on-budget sheet, each walked as the Pace case walks it, then to the keeper's gate,
-- Challenge held, and while the keeper rests from the last win (Config.World.Row.Back.Keeper) the avatar fights what
-- stands near the gate and is back at it before the keeper is. Then the try, the run's card and PICK seconds at the menu
-- (in the Festival a pick begins the next run in place). Each phase's seconds and kills (the save's Progress.Kills),
-- the session's kills an hour, and the same with the kills made while the keeper rests left out. The keeper's rest is
-- taken off at its start and its end, the record put back after; the lead keeps the sheet till it's summoned again.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Helpers = require(script.Parent.Helpers)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Screen = require(UI.Kit.Screen)
local StageScreen = require(UI.StageScreen)
local Markers = require(ReplicatedStorage.Shared.World.Markers)
local WorldConfig = require(ReplicatedStorage.Shared.Config.World)
local StagesConfig = require(ReplicatedStorage.Shared.Config.Stages)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local KeeperConfig = Combat.Keeper

local PaceCases = {}

local TICK = 0.1
local NEAR = 18 -- studs from a Shade the avatar stops at: inside the lead's leash (Config.Combat.Lead.Leash)
local MOVING = 2 -- studs a second over which the avatar counts as walking
local STRETCH = 420 -- seconds a stretch may take before the measure gives up on it
local GATE = 20 -- seconds standing in the whole run (TR69 B's gate)
local KEEPER = 4 -- the keeper's stage: the measure ends as the run reaches it
local TURN = 30 -- degrees off the camera's look past which the measure turns it to the Shade it walks to
local LAID = 6 -- seconds the street takes to be laid again after the switch is tuned
local STEP_OUT = 3 -- seconds past the Gap the next wave may take to stand and go for the lead
local BACK = 35 -- studs back up the street from the stop the avatar waits at: inside Near, the wave outside the leash
local ARRIVE = 10 -- seconds the avatar may take to walk there
-- the Session's
local CYCLES = 3 -- keeper wins in the session: the first waits on no rest, the rest do
local PICK = 3 -- seconds a player takes at the menu to begin the next run (an assumption, not measured)
local GATE_NEAR = 8 -- studs from the keeper's gate counted as at it
local ARRIVE_GATE = 90 -- seconds the walk to the gate may take
local REST_REACH = 60 -- studs from the gate within which the avatar fights while the keeper rests
local BACK_AT = 8 -- seconds of the rest left when the avatar stops fighting and goes back to the gate
local REST_MAX = WorldConfig.Row.Back.Keeper + 30 -- seconds the wait may take
local TRY_MAX = 240 -- seconds the keeper's fight may take
-- fighter_attr(9, 0.7) (tools/balance/attributes.py, Common Warrior, balanced), with TR69 D's 3% lifesteal
local SHEET = {
	Level = 9, Health = 1852, Attack = 358, Defence = 152, Hit = 113, Dodge = 82, Critical = 113, CriticalResist = 206,
	Block = 29.7, Penetration = 94.8, ElementalAttack = 37.8, ElementalResist = 130.8, CriticalDamage = 0.5, Lifesteal = 0.03, Regen = 4,
}

local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

local function standing(model: Model): boolean
	local state = model:GetAttribute("State")
	return state ~= "Down" and state ~= "Reset" and state ~= "Home"
end

-- The nearest standing Shade of `stage` to `from`: its pack's while the quota is owed, its elite's after.
local function nearest(stage: number, elite: boolean, from: Vector3): Model?
	local best: Model?, gap = nil, math.huge
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		local def = model:GetAttribute("Def")
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("Stage") == stage and standing(model)
			and type(def) == "string" and (string.find(def, "_elite", 1, true) ~= nil) == elite then
			local d = (model:GetPivot().Position - from).Magnitude
			if d < gap then
				best, gap = model, d
			end
		end
	end
	return best
end

-- The camera turned about its focus to look at `at` (distance and height kept), once `at` is TURN degrees off its look.
local function look(root: BasePart, at: Vector3)
	local camera = workspace.CurrentCamera
	local to = Vector3.new(at.X - root.Position.X, 0, at.Z - root.Position.Z)
	local facing = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if to.Magnitude < 1e-3 or facing.Magnitude < 1e-3 or math.deg(math.acos(math.clamp(to.Unit:Dot(facing.Unit), -1, 1))) < TURN then
		return
	end
	local focus = camera.Focus.Position
	local offset = camera.CFrame.Position - focus
	local across = Vector3.new(offset.X, 0, offset.Z).Magnitude
	camera.CFrame = CFrame.lookAt(focus - to.Unit * across + Vector3.new(0, offset.Y, 0), focus)
end

-- The server's stop `name` (NL_Debug "Packs"), or nil.
local function stopOf(t: any, name: string): any
	local list = t.Server("Packs")
	for _, group in (if type(list) == "table" then list else {}) do
		if type(group) == "table" and group.Name == name then
			return group
		end
	end
	return nil
end

local function stageOf(run: any): number?
	return if type(run) == "string" then tonumber(string.match(run, "(%d+)$")) else nil
end

-- One tenth of a second of the avatar as a player plays it: toward `foe` till NEAR studs off (a new walk at most every
-- half second, `moved` the last), the camera turned to it. "Fight" (the lead has a target), "Walk" (the avatar moving)
-- or "Stand", and the time of the last walk.
local function step(t: any, foe: Model?, moved: number): (string, number)
	local root = t.Root() :: BasePart?
	local character = t.Character() :: Model?
	local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
	if root and humanoid then
		if foe and (foe:GetPivot().Position - root.Position).Magnitude > NEAR and os.clock() - moved > 0.5 then
			humanoid:MoveTo(foe:GetPivot().Position)
			moved = os.clock()
		elseif foe == nil or (foe:GetPivot().Position - root.Position).Magnitude <= NEAR then
			humanoid:MoveTo(root.Position)
		end
		if foe then
			look(root, foe:GetPivot().Position)
		end
	end
	local mine = myLead()
	local target = if mine then mine:GetAttribute("Target") else nil
	local speed = if root then (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude else 0
	return if type(target) == "string" and target ~= "" then "Fight" elseif speed > MOVING then "Walk" else "Stand", moved
end

local function still(t: any)
	local character = t.Character() :: Model?
	local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
	local root = t.Root() :: BasePart?
	if humanoid and root then
		humanoid:MoveTo(root.Position)
	end
end

-- The lead's kills in the save so far (Progress.Kills: a fall with the lead among its hitters).
local function kills(): number
	local view = ProfileController.Get() :: any
	local progress = if view then view.Progress else nil
	return if type(progress) == "table" and type(progress.Kills) == "number" then progress.Kills else 0
end

-- The standing Shade the try's keeper is (its Def is the player's Try), or nil.
local function keeperOf(def: any): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("Def") == def and standing(model) then
			return model
		end
	end
	return nil
end

-- The nearest standing ordinary Shade of any stretch within `reach` studs of `at`, or nil.
local function nearby(at: Vector3, reach: number, from: Vector3): Model?
	local best: Model?, gap = nil, math.huge
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("Kind") == "Ordinary" and standing(model)
			and (model:GetPivot().Position - at).Magnitude <= reach then
			local d = (model:GetPivot().Position - from).Magnitude
			if d < gap then
				best, gap = model, d
			end
		end
	end
	return best
end

function PaceCases.Cases(): { any }
	return {
		{
			Name = "Pace (TR69 B): one clean Normal run, each stretch's seconds fighting, walking and standing",
			Manual = true,
			Run = function(t: any)
				local player = Players.LocalPlayer
				local before = t.Server("Stage")
				local normal = if type(before) == "table" then before.Normal else nil
				local cleared = if type(normal) == "table" and type(normal.Cleared) == "number" then normal.Cleared else nil
				local checkpoint = if type(before) == "table" and type(before.Checkpoint) == "table" then before.Checkpoint.Normal else nil
				Helpers.endRun(t)
				t.Server("LeadHeal")
				local lead = myLead()
				local level = if lead then lead:GetAttribute("Level") else nil
				t.Row(`the lead's level`, nil, nil, if type(level) == "number" then level else nil, "")
				local began = t.Server("StageBegin", "Normal", 1)
				t.Check("the run begins at the first stretch", type(began) == "table" and began.Ok == true, if type(began) == "table" then tostring(began.Error) else "")
				local ok, problem = pcall(function()
					t.Check("the run is up", Helpers.waitFor(t, 3, function(): boolean
						return stageOf(player:GetAttribute("StageRun")) == 1
					end))
					local seconds: { [number]: { Fight: number, Walk: number, Stand: number } } = {}
					local total = { Fight = 0, Walk = 0, Stand = 0 }
					local stage = 1
					local since = os.clock()
					local moved = 0
					while true do
						local now = stageOf(player:GetAttribute("StageRun"))
						if now == nil then
							t.Check("the run lasts to the keeper's stage", false, `it ended in stretch {stage}`)
							break
						elseif now ~= stage then
							stage, since = now, os.clock()
						end
						if stage >= KEEPER then
							break
						elseif os.clock() - since > STRETCH then
							t.Check(`stretch {stage} within {STRETCH} s`, false, `{player:GetAttribute("StageKills")} of {player:GetAttribute("StageQuota")}`)
							break
						end
						local row = seconds[stage] or { Fight = 0, Walk = 0, Stand = 0 }
						seconds[stage] = row
						local root = t.Root() :: BasePart?
						local got, quota = player:GetAttribute("StageKills"), player:GetAttribute("StageQuota")
						local owed = type(got) == "number" and type(quota) == "number" and got < quota
						local kind
						kind, moved = step(t, if root then nearest(stage, not owed, root.Position) else nil, moved)
						if kind == "Fight" then
							row.Fight += TICK
							total.Fight += TICK
						elseif kind == "Walk" then
							row.Walk += TICK
							total.Walk += TICK
						else
							row.Stand += TICK
							total.Stand += TICK
						end
						t.Wait(TICK)
					end
					for n = 1, KEEPER - 1 do
						local row = seconds[n]
						if row then
							t.Row(`stretch {n}: fighting`, nil, nil, row.Fight, "s")
							t.Row(`stretch {n}: walking`, nil, nil, row.Walk, "s")
							t.Row(`stretch {n}: standing`, nil, nil, row.Stand, "s")
						end
					end
					t.Row("the run: fighting", nil, nil, total.Fight, "s")
					t.Row("the run: walking", nil, nil, total.Walk, "s")
					t.Row(`the run: standing (the waves' gate, under {GATE} s)`, 0, GATE, total.Stand, "s")
				end)
				still(t)
				Helpers.endRun(t)
				if cleared ~= nil then
					t.Server("StageLine", "Normal", cleared, checkpoint)
				end
				t.Server("LeadHeal")
				if not ok then
					t.Check("no error", false, tostring(problem))
				end
			end,
		},
		{
			Name = "Session (TR72 item 4): back-to-back Normal runs of Lantern Row, the keeper's rest included, kills an hour",
			Manual = true,
			Run = function(t: any)
				local player = Players.LocalPlayer
				local before = t.Server("Stage")
				local normal = if type(before) == "table" then before.Normal else nil
				local cleared = if type(normal) == "table" and type(normal.Cleared) == "number" then normal.Cleared else nil
				local checkpoint = if type(before) == "table" and type(before.Checkpoint) == "table" then before.Checkpoint.Normal else nil
				local gate = Markers.Find("KeeperGate")
				if gate == nil then
					t.Row("no keeper's gate in this place: the case runs in the Festival place", nil, nil, nil, "")
					return
				end
				local door = Markers.At(gate).Position
				Helpers.endRun(t)
				t.Server("KeeperRest", 0)
				local sheet = t.Server("FightSheet", SHEET)
				t.Check("the lead on the level-9 on-budget sheet", type(sheet) == "table" and sheet.Ok == true, if type(sheet) == "table" then tostring(sheet.Error) else "")
				t.Server("LeadHeal")
				-- each phase's seconds and kills, the session's and each cycle's
				local phases = { "Stretches", "To the gate", "The rest", "The keeper", "Between" }
				local spent: { [string]: { Seconds: number, Kills: number } } = {}
				for _, name in phases do
					spent[name] = { Seconds = 0, Kills = 0 }
				end
				local cycles: { { Seconds: number, Kills: number, Rest: number, RestKills: number } } = {}
				local last = kills()
				local clock = os.clock()
				local cycle = { Seconds = 0, Kills = 0, Rest = 0, RestKills = 0 }
				local function tick(phase: string)
					t.Wait(TICK)
					local now, k = os.clock(), kills()
					local row = spent[phase]
					row.Seconds += now - clock
					row.Kills += k - last
					cycle.Seconds += now - clock
					cycle.Kills += k - last
					if phase == "The rest" then
						cycle.Rest += now - clock
						cycle.RestKills += k - last
					end
					clock, last = now, k
				end
				local ok, problem = pcall(function()
					local moved = 0
					for n = 1, CYCLES do
						cycle = { Seconds = 0, Kills = 0, Rest = 0, RestKills = 0 }
						table.insert(cycles, cycle)
						clock, last = os.clock(), kills()
						local began = t.Server("StageBegin", "Normal", 1)
						if not t.Check(`run {n} begins at the first stretch`, type(began) == "table" and began.Ok == true, if type(began) == "table" then tostring(began.Error) else "") then
							return
						end
						local up = os.clock()
						while stageOf(player:GetAttribute("StageRun")) ~= 1 and os.clock() - up < 3 do
							tick("Between")
						end
						-- the stretches, as the Pace case walks them
						local stage, since = 1, os.clock()
						while true do
							local now = stageOf(player:GetAttribute("StageRun"))
							if now == nil then
								t.Check(`run {n} lasts to the keeper's stage`, false, `it ended in stretch {stage}`)
								return
							elseif now ~= stage then
								stage, since = now, os.clock()
							end
							if stage >= KEEPER then
								break
							elseif os.clock() - since > STRETCH then
								t.Check(`run {n}: stretch {stage} within {STRETCH} s`, false, `{player:GetAttribute("StageKills")} of {player:GetAttribute("StageQuota")}`)
								return
							end
							local root = t.Root() :: BasePart?
							local got, quota = player:GetAttribute("StageKills"), player:GetAttribute("StageQuota")
							local owed = type(got) == "number" and type(quota) == "number" and got < quota
							moved = select(2, step(t, if root then nearest(stage, not owed, root.Position) else nil, moved))
							tick("Stretches")
						end
						-- the walk to the keeper's gate
						local walk = os.clock()
						while true do
							local root = t.Root() :: BasePart?
							local at = if root then root.Position else door
							if Vector3.new(at.X - door.X, 0, at.Z - door.Z).Magnitude < GATE_NEAR then
								break
							elseif os.clock() - walk > ARRIVE_GATE then
								t.Check(`run {n}: the avatar reaches the keeper's gate`, false)
								return
							end
							local character = t.Character() :: Model?
							local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
							if humanoid and os.clock() - moved > 0.5 then
								humanoid:MoveTo(door)
								moved = os.clock()
							end
							tick("To the gate")
						end
						still(t)
						-- the gate: Challenge held, refused "Resting" while the keeper rests. Meanwhile the avatar fights
						-- what stands within REST_REACH of the gate, as a player waiting would, and is back by it
						-- BACK_AT seconds before the keeper is
						local held = os.clock()
						while os.clock() - held < KeeperConfig.Hold do
							tick("To the gate")
						end
						local asked, left = -math.huge, 0
						local rest = os.clock()
						while true do
							if os.clock() - rest > REST_MAX then
								t.Check(`run {n}: the keeper is back within {REST_MAX} s`, false)
								return
							end
							if os.clock() - asked >= 1 then
								asked = os.clock()
								local try = t.Server("KeeperTry")
								if type(try) == "table" and try.Ok == true then
									break
								elseif type(try) ~= "table" or try.Error ~= "Resting" then
									t.Check(`run {n}: the keeper's try`, false, if type(try) == "table" then tostring(try.Error) else "")
									return
								end
								left = if type(try.Left) == "number" then try.Left else 0
							end
							local root = t.Root() :: BasePart?
							local foe = if root and left > BACK_AT then nearby(door, REST_REACH, root.Position) else nil
							if foe then
								moved = select(2, step(t, foe, moved))
							else
								local character = t.Character() :: Model?
								local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
								if humanoid and root and Vector3.new(root.Position.X - door.X, 0, root.Position.Z - door.Z).Magnitude > GATE_NEAR then
									humanoid:MoveTo(door)
								end
							end
							tick("The rest")
						end
						-- the try: the avatar walks to the keeper as it does to a Shade, till the try ends
						local def = nil
						local into = os.clock()
						while os.clock() - into < 3 and def == nil do
							def = player:GetAttribute("Try")
							tick("The keeper")
						end
						while player:GetAttribute("Try") ~= nil do
							if os.clock() - into > TRY_MAX then
								t.Check(`run {n}: the keeper's fight within {TRY_MAX} s`, false)
								return
							end
							moved = select(2, step(t, keeperOf(def), moved))
							tick("The keeper")
						end
						local lead = myLead()
						if not t.Check(`run {n}: the keeper falls, not the lead`, lead ~= nil and standing(lead :: Model)) then
							return
						end
						-- the run's card, then the menu's pick of the next (in the Festival a pick begins it in place)
						local done = os.clock()
						while player:GetAttribute("StageRun") ~= nil and os.clock() - done < 10 do
							tick("Between")
						end
						local card = os.clock()
						while Screen.Current() ~= StageScreen.Name and os.clock() - card < StagesConfig.Results.After + 1 do
							tick("Between")
						end
						Screen.Close()
						local pick = os.clock()
						while os.clock() - pick < PICK do
							tick("Between")
						end
					end
				end)
				still(t)
				local total = { Seconds = 0, Kills = 0 }
				for n, row in cycles do
					t.Row(`cycle {n}: seconds`, nil, nil, row.Seconds, "s")
					t.Row(`cycle {n}: kills`, nil, nil, row.Kills, "")
					t.Row(`cycle {n}: waiting on the keeper's rest`, nil, nil, row.Rest, "s")
					t.Row(`cycle {n}: kills while it rests`, nil, nil, row.RestKills, "")
					total.Seconds += row.Seconds
					total.Kills += row.Kills
				end
				for _, name in phases do
					t.Row(`{name}: seconds`, nil, nil, spent[name].Seconds, "s")
					t.Row(`{name}: kills`, nil, nil, spent[name].Kills, "")
				end
				t.Row("the session: seconds", nil, nil, total.Seconds, "s")
				t.Row("the session: kills", nil, nil, total.Kills, "")
				if total.Seconds > 0 then
					t.Row("the session: kills an hour", nil, nil, math.floor(total.Kills / total.Seconds * 3600 + 0.5), "")
					t.Row("the session: kills an hour, none while the keeper rests", nil, nil,
						math.floor((total.Kills - spent["The rest"].Kills) / total.Seconds * 3600 + 0.5), "")
				end
				-- after the first win every cycle waits on a rest: the rate a player's hour settles at
				local steady = { Seconds = 0, Kills = 0, RestKills = 0 }
				for n = 2, #cycles do
					steady.Seconds += cycles[n].Seconds
					steady.Kills += cycles[n].Kills
					steady.RestKills += cycles[n].RestKills
				end
				if #cycles >= 2 and steady.Seconds > 0 then
					t.Row("from cycle 2: kills an hour", nil, nil, math.floor(steady.Kills / steady.Seconds * 3600 + 0.5), "")
					t.Row("from cycle 2: kills an hour, none while the keeper rests", nil, nil,
						math.floor((steady.Kills - steady.RestKills) / steady.Seconds * 3600 + 0.5), "")
				end
				Helpers.endRun(t)
				t.Server("KeeperRest", 0)
				if cleared ~= nil then
					t.Server("StageLine", "Normal", cleared, checkpoint)
				end
				t.Server("LeadHeal")
				if not ok then
					t.Check("no error", false, tostring(problem))
				end
			end,
		},
		{
			Name = "Waves (TR69 B): a wave stood while you owe the quota steps out at your lead, though it isn't fighting",
			Run = function(t: any)
				local first = stopOf(t, "Pack 1")
				if first == nil then
					t.Row("no street in this place: the case runs in the Festival place", nil, nil, nil, "")
					return
				end
				local player = Players.LocalPlayer
				local was = first.Waves ~= nil
				local before = t.Server("Stage")
				local normal = if type(before) == "table" then before.Normal else nil
				local cleared = if type(normal) == "table" and type(normal.Cleared) == "number" then normal.Cleared else nil
				local checkpoint = if type(before) == "table" and type(before.Checkpoint) == "table" then before.Checkpoint.Normal else nil
				Helpers.endRun(t)
				local ok, problem = pcall(function()
					if not was then
						t.Server("Tune", "World.Row.Waves.On", true)
					end
					t.Check("the street laid in waves", Helpers.waitFor(t, LAID, function(): boolean
						local stop = stopOf(t, "Pack 1")
						return stop ~= nil and stop.Waves ~= nil and stop.Standing > 0
					end))
					t.Server("LeadHeal")
					local began = t.Server("StageBegin", "Normal", 1)
					t.Check("the run begins at the first stretch", type(began) == "table" and began.Ok == true, if type(began) == "table" then tostring(began.Error) else "")
					t.Check("the run is up", Helpers.waitFor(t, 3, function(): boolean
						return stageOf(player:GetAttribute("StageRun")) == 1
					end))
					-- the avatar back up the street from the stop (away from the stretch's elite), the lead beside it
					local stop, elite = stopOf(t, "Pack 1"), stopOf(t, "Elite 1")
					local root = t.Root() :: BasePart?
					local character = t.Character() :: Model?
					local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
					if stop == nil or elite == nil or root == nil or humanoid == nil then
						t.Check("the stop, its elite and the avatar", false)
						return
					end
					local away = Vector3.new(stop.At.X - elite.At.X, 0, stop.At.Z - elite.At.Z).Unit
					local spot = stop.At + away * BACK
					humanoid:MoveTo(spot)
					t.Check("the avatar walks back up the street", Helpers.waitFor(t, ARRIVE, function(): boolean
						local at = (t.Root() :: BasePart).Position
						return Vector3.new(at.X - spot.X, 0, at.Z - spot.Z).Magnitude < 4
					end))
					local wave = stop.Wave
					t.Server("PackDefeat", "Pack 1")
					t.Server("LeadCalm")
					local lead = myLead()
					local id = if lead then lead:GetAttribute("Fighter") else nil
					t.Check("a lead, not fighting", lead ~= nil and Helpers.waitFor(t, 2, function(): boolean
						local target = (lead :: Model):GetAttribute("Target")
						return target == nil or target == ""
					end))
					local stood = Helpers.waitFor(t, WorldConfig.Row.Waves.Gap + STEP_OUT, function(): boolean
						local now = stopOf(t, "Pack 1")
						return now ~= nil and now.Wave ~= wave and now.Standing > 0
					end)
					t.Check("its next wave stands after the Gap", stood)
					local nearest = math.huge
					local avatar = (t.Root() :: BasePart).Position
					local fighters = workspace:FindFirstChild("Fighters")
					for _, model in (if fighters then fighters:GetChildren() else {}) do
						if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("Stage") == 1
							and model:GetAttribute("Kind") == "Ordinary" and standing(model) then
							nearest = math.min(nearest, (model:GetPivot().Position - avatar).Magnitude)
						end
					end
					t.Check("it stands outside the lead's leash, so only its step-out starts the fight", nearest > Combat.Lead.Leash, string.format("%.0f studs", nearest))
					local on, count = 0, 0
					t.Check("every Shade of it goes for the lead", stood and Helpers.waitFor(t, STEP_OUT, function(): boolean
						on, count = 0, 0
						local fighters = workspace:FindFirstChild("Fighters")
						for _, model in (if fighters then fighters:GetChildren() else {}) do
							if model:IsA("Model") and model:GetAttribute("Side") == "Shade" and model:GetAttribute("Stage") == 1
								and model:GetAttribute("Kind") == "Ordinary" and standing(model) then
								count += 1
								on += if id ~= nil and model:GetAttribute("Target") == id then 1 else 0
							end
						end
						return count > 0 and on == count
					end), `{on} of {count}`)
				end)
				local root = t.Root() :: BasePart?
				local character = t.Character() :: Model?
				local humanoid = if character then (character :: Model):FindFirstChildOfClass("Humanoid") else nil
				if humanoid and root then
					humanoid:MoveTo(root.Position)
				end
				Helpers.endRun(t)
				if not was then
					t.Server("Tune", "World.Row.Waves.On", false)
				end
				if cleared ~= nil then
					t.Server("StageLine", "Normal", cleared, checkpoint)
				end
				t.Server("LeadHeal")
				if not ok then
					t.Check("no error", false, tostring(problem))
				end
			end,
		},
	}
end

return PaceCases
