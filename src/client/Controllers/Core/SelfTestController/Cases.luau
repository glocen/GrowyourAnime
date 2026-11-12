--!strict
-- Cases (client, Studio only): the self-test's list, a child of SelfTestController. Name is what a filter matches. Run gets
-- the `t` API (SelfTestController, type Test). Manual = true keeps a case out of a full run; Stay = true skips the reset to
-- the pad. Expected values come from Config or the instances themselves, never typed twice. One case, one behaviour.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Tune = require(Shared.Util.Tune)
local TestInput = require(Shared.Util.TestInput)
local Actions = require(Shared.Definitions.Actions)
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local Shades = require(Shared.Config.Shades)
local EffectsConfig = require(Shared.Config.Effects)
local WorldConfig = require(Shared.Config.World)
local Markers = require(Shared.World.Markers)
local Parts = require(Shared.Util.Parts)
local Drops = require(Shared.Rules.Drops)
local Voidkin = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local Clips = require(script.Parent.Parent.Parent.Main.FighterController.Clips)
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Read = require(UI.Read)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local UiLint = require(script.Parent.UiLint)

local R6_ROOT_HEIGHT = 3 -- an R6 body's root stands 3 studs above the floor (legs 2, half the torso 1): an engine fact
local TUNE_PATH = "Game.Version" -- a string any build has; the case puts it back
local BEAT_TOLERANCE = 1 / 120 -- half a frame at 60 fps
local LEAD_SETTLE = 1.5 -- seconds for the lead to catch up after the reset's teleport (Config.Combat.Lead)
local REPLAY_PAUSE = 5 -- seconds past the action before a second press, longer than the case waits
local SHADE_AHEAD = 12 -- studs ahead of the avatar a test Shade spawns: inside its notice and the lead's leash
local SHADE_TIMEOUT = 20 -- seconds a level-matched ordinary may take to fall (the seed is 5 s of fighting, Config.Enemies)
local SHADE_TOUGHER = 10 -- levels over the lead's a Shade spawns at to swing and flinch several times before it falls
local SHADE_WATCH = 12 -- seconds the alternation case watches for three swings and three flinches
local FRAME = 1 / 60 -- the clip's frame, which the art sheets count in
local SQUARE = 4 -- bars in a square
local BRACKET = 3 -- bars in a bracket: two posts and a lintel
local GONE_BY = 19 * FRAME -- the art sheet: Haymaker's look is over by frame 76, Strike (57) + 19
local ARRIVE_TIMEOUT = 8 -- seconds for a respawned avatar to stand on its spawn
local FACING_TOLERANCE = 10 -- degrees off straight at the Breaker that still count as facing it
local CAMERA_TOLERANCE = 25 -- the camera swings in behind the avatar a moment late
local RESPAWN_PATH = "World.Row.Respawn"
local PACK_BACK = 1 -- seconds a felled pack takes to come back while the case runs; the case puts the seed back
local MOVE_SLACK = 0.5 -- seconds past a fade's move before the case reads where the avatar stands
local SET_DOWN = 2 -- studs from its spot a set-down avatar may stand once physics settles it
local KEEPER_MEETS = 3 -- seconds after arriving by which the lead fights the keeper (it walks 4 studs into Lead.Leash)
local KEEPER_TRADES = 6 -- seconds after that by which each has hit the other
local REPLICATE = 1 -- seconds a server-set attribute may take to reach this client
local PACK_STAND = 10 -- studs short of a pack's marker the avatar stands: inside its notice and the lead's leash
local DROP_BACK = 3 -- seconds a felled pack takes to come back in the drops case: time to leave the street first
local ANSWER = 3 -- seconds a request through a screen may take to come back in the save's copy
local PLATE_TICK = 0.4 -- seconds for the plates and pills to show a change (BaseController and HudController read at 4 Hz)
local SKIP_ALL = 3600 -- seconds of base time a case skips, past any shard's work even at the floor's speed
local TAKE_READ = 3 -- seconds the take leaves a screen or a card up, as a player reads it
local TAKE_WALK = 45 -- seconds a walk of the take may last
local TAKE_FIGHT = 75 -- seconds a pack may take to fall in the take
local TAKE_TURN = 2.5 -- how fast the take's camera swings in behind a walking avatar (a share of the gap a second)
local TAKE_REACH = 2.5 -- studs from a waypoint that count as there
local TAKE_ZOOM = 12.5 -- studs from the avatar the take's camera holds: where Roblox's camera starts a player

-- The angle in degrees between two directions, flat on the ground.
local function flatAngle(a: Vector3, b: Vector3): number
	local fa, fb = Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, 0, b.Z)
	if fa.Magnitude < 1e-3 or fb.Magnitude < 1e-3 then
		return 180
	end
	return math.deg(math.acos(math.clamp(fa.Unit:Dot(fb.Unit), -1, 1)))
end

-- Waits up to `seconds` for `ok`, and says whether it came.
local function waitFor(t: any, seconds: number, ok: () -> boolean): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		if ok() then
			return true
		end
		t.Wait(0.1)
	end
	return ok()
end

-- The button of row `row` in list `list` of the open screen `screen`, or nil.
local function screenButton(screen: string, list: string, row: string): TextButton?
	local frame = Screen.Frame(screen)
	local body = frame and frame:FindFirstChild("Body")
	local scroll = body and body:FindFirstChild(list)
	local found = scroll and scroll:FindFirstChild(row)
	local button = found and found:FindFirstChild("Action")
	return if button and button:IsA("TextButton") then button else nil
end

-- How many shards of `def` wait ready to open, in the save's copy.
local function readyCount(def: string): number
	local view = ProfileController.Get()
	local count = 0
	for _, work in (if view then view.Base.Ready else {}) do
		count += if work.Def == def then 1 else 0
	end
	return count
end

-- The UI lint on whatever shows now.
local function lintClean(t: any, where: string)
	local report = UiLint.Run()
	t.Check(`{where}: every label fits its box`, #report.Fit == 0, UiLint.Detail(report.Fit, report.Checked))
	t.Check(`{where}: every label reads at {Theme.Text.Minimum} px or more`, #report.Size == 0, UiLint.Detail(report.Size, report.Checked))
	t.Check(`{where}: every label is on screen`, #report.Screen == 0, UiLint.Detail(report.Screen, report.Checked))
	t.Check(`{where}: no label shows Roblox's default`, #report.Placeholder == 0, UiLint.Detail(report.Placeholder, report.Checked))
end

-- The fighter model with id `id`, or nil.
local function fighterModel(id: string): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Fighter") == id then
			return model
		end
	end
	return nil
end

-- The name of every clip `model` plays now.
local function playing(model: Model): { [string]: boolean }
	local names = {}
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	for _, track in (if animator then animator:GetPlayingAnimationTracks() else {}) do
		if track.Animation then
			names[track.Animation.Name] = true
		end
	end
	return names
end

-- The player's own lead's model, or nil.
local function myLead(): Model?
	local fighters = workspace:FindFirstChild("Fighters")
	for _, model in (if fighters then fighters:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == Players.LocalPlayer.UserId then
			return model
		end
	end
	return nil
end

return {
	{
		Name = "Boot: the server booted clean",
		Stay = true,
		Run = function(t: any)
			local errors = t.Server("BootErrors")
			t.Check("no errors in require or Init", errors == 0, `got {tostring(errors)}`)
		end,
	},
	{
		Name = "Boot: this client booted clean",
		Stay = true,
		Run = function(t: any)
			local errors = Players.LocalPlayer:GetAttribute("ClientBootErrors")
			t.Check("the server heard a clean boot", errors == 0, `got {tostring(errors)}`)
		end,
	},
	{
		Name = "Debug bridge: answers a client",
		Stay = true,
		Run = function(t: any)
			t.Check("Ping", t.Server("Ping") == "pong")
		end,
	},
	{
		Name = "Live numbers: a tune reaches this client",
		Stay = true,
		Run = function(t: any)
			local before = Tune.Read(TUNE_PATH)
			local probe = `{before}-tune-check`
			t.Server("Tune", TUNE_PATH, probe)
			t.Wait(0.3)
			t.Check("the client has the new value", Tune.Read(TUNE_PATH) == probe, `got {tostring(Tune.Read(TUNE_PATH))}`)
			t.Server("Tune", TUNE_PATH, before)
			t.Wait(0.3)
			t.Check("and the old one back", Tune.Read(TUNE_PATH) == before)
		end,
	},
	{
		Name = "Avatar: R6",
		Stay = true,
		Run = function(t: any)
			-- The director, 2026-11-12: the player's avatar is R6 only. This catches the place's avatar setting drifting.
			local humanoid = t.Character():FindFirstChildOfClass("Humanoid")
			local rig = if humanoid then humanoid.RigType else nil
			t.Check("the rig is R6", rig == Enum.HumanoidRigType.R6, `got {tostring(rig)}`)
		end,
	},
	{
		Name = "World: the place's markers keep the world contract",
		Stay = true,
		Run = function(t: any)
			local problems = t.Server("WorldReport")
			local first = if type(problems) == "table" then problems[1] else nil
			t.Check("the world report is empty", type(problems) == "table" and #problems == 0, if first then `{first} (and {#problems - 1} more)` else nil)
		end,
	},
	{
		Name = "World: the player arrives on their own plot, facing the Breaker",
		Stay = true, -- it makes its own arrival; the next case's reset takes the avatar back to the pad
		Run = function(t: any)
			local player = Players.LocalPlayer
			local plot = player:GetAttribute("Plot")
			t.Check("the player owns a plot", type(plot) == "number", `got {tostring(plot)}`)
			local spawn = if type(plot) == "number" then Markers.Find("Spawn", { Plot = plot }) else nil
			local breaker = if type(plot) == "number" then Markers.Find("Breaker", { Plot = plot }) else nil
			t.Check("its spawn and its Breaker are marked", spawn ~= nil and breaker ~= nil)
			if not (spawn and breaker) then
				return
			end
			-- Looking away from the Breaker first, as a player back from the street does: the arrival must turn the camera.
			local camera = workspace.CurrentCamera
			local away = Markers.At(spawn).Position - Markers.At(breaker).Position
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + Vector3.new(away.X, 0, away.Z))
			local old = player.Character
			t.Check("the server respawns the avatar", t.Server("Respawn") == true)
			local deadline = os.clock() + ARRIVE_TIMEOUT
			local root: BasePart? = nil
			repeat
				t.Wait(0.1)
				local character = player.Character
				local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
				root = if character and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then Parts.Root(character) else nil
			until root or os.clock() > deadline
			t.Check("a new avatar stands on the ground", root ~= nil)
			if not root then
				return
			end
			t.Wait(WorldConfig.Arrive) -- the arrival opens from black, the camera behind it
			local at = Markers.At(spawn)
			local offset = at:PointToObjectSpace(root.Position)
			local size = if spawn:IsA("BasePart") then spawn.Size else Vector3.new(2, 0, 2)
			t.Check("on its plot's spawn", math.abs(offset.X) <= size.X / 2 and math.abs(offset.Z) <= size.Z / 2, `{string.format("%.1f, %.1f", offset.X, offset.Z)} from its centre`)
			local toBreaker = Markers.At(breaker).Position - root.Position
			t.Near("the avatar faces the Breaker (degrees off)", flatAngle(root.CFrame.LookVector, toBreaker), 0, FACING_TOLERANCE)
			t.Near("so does the camera (degrees off)", flatAngle(camera.CFrame.LookVector, toBreaker), 0, CAMERA_TOLERANCE)
		end,
	},
	{
		Name = "Packs: each stop stands its Shades, and a fallen pack comes back",
		Stay = true,
		Run = function(t: any)
			local rows = t.Server("Packs")
			local byName: { [string]: any } = {}
			for _, row in rows do
				byName[row.Name] = row
			end
			local packs = 0
			for _, stop in WorldConfig.Row.Stops do
				packs += if stop.Kind == "Pack" then 1 else 0
			end
			local found = 0
			for name in byName do
				found += if string.sub(name, 1, 5) == "Pack " then 1 else 0
			end
			t.Check("a pack at each pack stop, and the elite", found == packs and byName.Elite ~= nil, `{found} packs for {packs} stops`)
			for name, row in byName do
				t.Check(`{name} stands {row.Count}`, row.Standing == row.Count, `{row.Standing} standing`)
				if row.Count > 1 then
					t.Near(`{name}'s Shades stand Row.Spread apart`, row.Gap, WorldConfig.Row.Spread, 0.5)
				end
			end
			local first = byName["Pack 1"]
			if first == nil then
				return
			end
			local wait = t.Server("Tune", RESPAWN_PATH)
			t.Server("Tune", RESPAWN_PATH, PACK_BACK)
			local felled = t.Server("PackDefeat", "Pack 1")
			t.Check("Pack 1 falls", felled.Ok == true and felled.Felled == first.Count, `{tostring(felled.Felled)} felled`)
			local down = t.Server("Packs")
			for _, row in down do
				if row.Name == "Pack 1" then
					t.Check("none of it stands, and it's coming back", row.Standing == 0 and row.BackIn > 0, `{row.Standing} standing, back in {row.BackIn}`)
				end
			end
			t.Wait(PACK_BACK + 0.5)
			for _, row in t.Server("Packs") do
				if row.Name == "Pack 1" then
					t.Check("it's back, whole, after Row.Respawn", row.Standing == first.Count, `{row.Standing} standing`)
				end
			end
			t.Server("Tune", RESPAWN_PATH, wait)
		end,
	},
	{
		Name = "Keeper: a try in the plot's own ring; a win is saved and sets down beyond it, a loss before the gate",
		Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
		Run = function(t: any)
			local keeper = Combat.Keeper
			local moved = keeper.Fade.Out + keeper.Fade.Hold / 2 + MOVE_SLACK
			local def = nil
			for _, stop in WorldConfig.Row.Stops do
				def = if stop.Kind == "Keeper" then stop.Def else def
			end
			local before = t.Server("Keeper")
			t.Check("no try yet", before.Ok == true and before.InTry == false)
			local start = t.Server("KeeperTry")
			t.Check("a try starts", start.Ok == true, tostring(start.Error))
			if start.Ok ~= true then
				return
			end
			-- The attribute replicates after the server's answer: wait for it, briefly.
			local named = os.clock() + REPLICATE
			while Players.LocalPlayer:GetAttribute("Try") ~= def and os.clock() < named do
				t.Wait(0.05)
			end
			t.Check("the player's Try names the keeper", Players.LocalPlayer:GetAttribute("Try") == def, tostring(Players.LocalPlayer:GetAttribute("Try")))
			t.Check("one try at a time", t.Server("KeeperTry").Error == "InTry")
			t.Wait(moved)
			local inside = t.Server("Keeper")
			t.Near("the avatar stands at its copy's entrance (studs off)", inside.FromEntry, 0, SET_DOWN)
			t.Check("the copy is its plot's, out of sight of the street", inside.FromCopy > 0 and inside.FromCopy < inside.Radius)
			t.Check("a fresh keeper stands in it", inside.Keeper ~= "" and inside.KeeperHealth > 0)
			-- The fight is joined with nobody pressing anything: the keeper comes for the lead from the middle of the ring, and the
			-- lead meets it once it's inside Lead.Leash of the avatar.
			t.Check("the keeper comes for the lead at once", inside.KeeperTarget ~= "" and inside.KeeperTarget == inside.Lead, `target {inside.KeeperTarget}, lead {inside.Lead}`)
			local joined = inside
			local meetBy = os.clock() + KEEPER_MEETS
			while joined.LeadTarget ~= joined.Keeper and os.clock() < meetBy do
				t.Wait(0.2)
				joined = t.Server("Keeper")
			end
			t.Check("and the lead meets it", joined.LeadTarget == joined.Keeper, `lead's target {joined.LeadTarget}`)
			-- And they trade hits, never a stand-off just outside each other's reach (Combat.Approach).
			local traded = joined
			local tradeBy = os.clock() + KEEPER_TRADES
			while (traded.KeeperHealth >= joined.KeeperHealth or traded.LeadHealth >= joined.LeadHealth) and os.clock() < tradeBy do
				t.Wait(0.25)
				traded = t.Server("Keeper")
			end
			t.Check("the lead lands hits on the keeper", traded.KeeperHealth < joined.KeeperHealth, `{traded.KeeperHealth} of {joined.KeeperHealth}`)
			t.Check("and the keeper on the lead", traded.LeadHealth < joined.LeadHealth, `{traded.LeadHealth} of {joined.LeadHealth}`)
			t.Check("the keeper falls", t.Server("KeeperEnd", "Win").Ok == true)
			t.Wait(0.3)
			local saved = t.Server("Keeper").Wins
			t.Check("the win is saved before any fade", saved == before.Wins + 1, `{saved} wins, was {before.Wins}`)
			t.Wait(keeper.WinPause + moved)
			local won = t.Server("Keeper")
			t.Check("the try is over", won.InTry == false and Players.LocalPlayer:GetAttribute("Try") == nil)
			t.Near("the avatar stands at the ring's exit (studs off)", won.FromExit, 0, SET_DOWN)
			-- The shortcut home, a step away.
			local pad = Markers.Find("Shortcut")
			t.Check("the shortcut is in view of the exit", pad ~= nil and pad:IsA("BasePart"))
			if pad and pad:IsA("BasePart") then
				t.Root().CFrame = pad.CFrame + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				t.Wait(moved + 0.3)
				t.Near("the shortcut sets the avatar down on its plot (studs off)", t.Server("Keeper").FromHome, 0, SET_DOWN)
			end
			-- A loss: the lead falls.
			local again = t.Server("KeeperTry")
			t.Check("a second try starts", again.Ok == true, tostring(again.Error))
			if again.Ok ~= true then
				return
			end
			t.Wait(moved)
			t.Check("the lead falls", t.Server("KeeperEnd", "Loss").Ok == true)
			t.Wait(keeper.LossPause + moved)
			local lost = t.Server("Keeper")
			t.Check("the try is over", lost.InTry == false)
			t.Near("the avatar stands before the keeper's gate (studs off)", lost.FromBefore, 0, SET_DOWN)
			t.Check("a loss saves nothing", lost.Wins == before.Wins + 1, `{lost.Wins} wins`)
			-- The lead back up before the next case needs it.
			local deadline = os.clock() + Combat.Lead.DownSeconds + 2
			repeat
				t.Wait(0.2)
				local lead = myLead()
			until (lead and lead:GetAttribute("State") ~= "Down") or os.clock() > deadline
			local lead = myLead()
			t.Check("the lead is back up after its fall", lead ~= nil and lead:GetAttribute("State") ~= "Down")
		end,
	},
	{
		-- Not Stay: the reset before it records where the run will put the avatar back (TestPadClear), never the street.
		Name = "Drops: the Shades a player's lead hit pay them as they fall, into the save; a pack it never hit pays nothing",
		Run = function(t: any)
			local before = t.Server("Drops")
			t.Check("the save is open", before.Ok == true, tostring(before.Error))
			if before.Ok ~= true then
				return
			end
			-- From the server: on the pad, this client has the street streamed out.
			local first, second = nil, nil
			for _, r in t.Server("Packs") do
				first = if r.Name == "Pack 1" then r else first
				second = if r.Name == "Pack 2" then r else second
			end
			t.Check("Pack 1 and Pack 2 stand", first ~= nil and second ~= nil and first.Standing == first.Count and second.Standing == second.Count)
			if first == nil or second == nil then
				return
			end
			local wait = t.Server("Tune", RESPAWN_PATH)
			t.Server("Tune", RESPAWN_PATH, DROP_BACK)
			-- A pack nobody's lead touched: its fall pays nothing.
			t.Server("PackDefeat", "Pack 2")
			t.Wait(0.3)
			local untouched = t.Server("Drops").Kills
			t.Check("Pack 2's fall paid nothing", untouched == before.Kills, `{untouched - before.Kills} kills paid`)
			-- Stand before Pack 1, facing it, and let the lead land a hit.
			local at: Vector3 = first.At
			local stand = at + Vector3.new(0, R6_ROOT_HEIGHT, PACK_STAND)
			t.Root().CFrame = CFrame.lookAt(stand, Vector3.new(at.X, stand.Y, at.Z))
			local row: any = nil
			local hitBy = os.clock() + SHADE_TIMEOUT
			repeat
				t.Wait(0.2)
				for _, r in t.Server("Packs") do
					row = if r.Name == "Pack 1" then r else row
				end
			until (row and row.HitBy > 0) or os.clock() > hitBy
			t.Check("the lead hits Pack 1", row ~= nil and row.HitBy > 0)
			if row == nil or row.HitBy == 0 then
				t.Reset()
				t.Server("Tune", RESPAWN_PATH, wait)
				return
			end
			local mid = t.Server("Drops")
			local felled = t.Server("PackDefeat", "Pack 1")
			t.Wait(0.3)
			local after = t.Server("Drops")
			local kills = after.Kills - mid.Kills
			t.Check("each Shade it hit pays once", felled.Ok == true and kills >= row.HitBy and kills <= row.Count, `{kills} paid, {row.HitBy} hit, {row.Count} in the pack`)
			local each = Drops.Roll("Ordinary", row.Level, row.Ground, 0.999) :: Drops.Drop
			local credits = after.Credits - mid.Credits
			t.Check("its Credits, per Config.Drops", credits == kills * each.Credits, `{credits} for {kills} x {each.Credits}`)
			local gained = after.Standard - mid.Standard
			t.Check("Standard shards, at most one a Shade", gained >= 0 and gained <= kills, `{gained} for {kills}`)
			t.Check("the lead's experience rose", after.Level > mid.Level or after.Xp == mid.Xp + kills * each.Xp, `level {mid.Level} to {after.Level}, xp {mid.Xp} to {after.Xp}`)
			local wantNamed = before.Named + (if before.Kills == 0 then 1 else 0)
			t.Check("Watt's shard only on the account's first kill", after.Named == wantNamed, `{after.Named} held, {wantNamed} wanted`)
			-- Leave as found: off the street before Pack 1 is back, the seed back, the lead healed out of the fight.
			t.Reset()
			t.Wait(DROP_BACK)
			t.Server("Tune", RESPAWN_PATH, wait)
			local heal = Combat.Lead.Heal
			local healBy = os.clock() + heal.After + 1 / heal.PerSecond + 1
			local lead = myLead()
			while lead and lead:GetAttribute("Health") ~= lead:GetAttribute("MaxHealth") and os.clock() < healBy do
				t.Wait(0.25)
				lead = myLead()
			end
			t.Check("the lead heals to full out of the fight", lead ~= nil and lead:GetAttribute("Health") == lead:GetAttribute("MaxHealth"))
		end,
	},
	{
		Name = "Test pad: the player stands on it",
		Run = function(t: any)
			local pad = workspace:FindFirstChild(TestInput.PadName)
			local floor = pad and pad:FindFirstChild("Floor") :: BasePart?
			t.Check("the pad is built", floor ~= nil)
			if not floor then
				return
			end
			local offset = floor.CFrame:PointToObjectSpace(t.Root().Position)
			local inside = math.abs(offset.X) < floor.Size.X / 2 and math.abs(offset.Z) < floor.Size.Z / 2
			t.Check("over the floor", inside, `{string.format("%.1f, %.1f", offset.X, offset.Z)} from its centre`)
			t.Near("root height above the floor", offset.Y - floor.Size.Y / 2, R6_ROOT_HEIGHT, 0.5)
		end,
	},
	{
		Name = "Fight: each clip's markers are its action's beats",
		Stay = true,
		Run = function(t: any)
			-- The ga-action skill: the effect, the hit and the camera hang on the beat names, so the clip must carry them.
			for _, action in Actions.List do
				local base = action.Clip
				if base == nil then
					continue
				end
				-- a mirror plays in its clip's place (Config.Animations.Mirrors), so it carries the same beats
				for _, clip in { base, Animations.Mirrors[base] } do
					local sequence = Clips.Sequence(clip)
					t.Check(`{action.Id}: the clip {clip} is baked`, sequence ~= nil)
					if sequence == nil then
						continue
					end
					local markers: { [string]: number } = {}
					local length = 0
					for _, keyframe in sequence:GetKeyframes() do
						local frame = keyframe :: Keyframe
						length = math.max(length, frame.Time)
						for _, marker in frame:GetMarkers() do
							markers[marker.Name] = frame.Time
						end
					end
					t.Near(`{clip}: the clip's length is {action.Id}'s`, length, action.Length, BEAT_TOLERANCE)
					for beat, at in action.Beats do
						local marked = markers[beat]
						t.Check(`{clip}: the clip marks {beat}`, marked ~= nil)
						if marked then
							t.Near(`{clip}: {beat} on its beat`, marked, at, BEAT_TOLERANCE)
						end
					end
					for name in markers do
						t.Check(`{clip}: the marker {name} is a beat`, action.Beats[name] ~= nil)
					end
				end
			end
			for rig, clips in Animations.Rigs do
				for role, clip in clips do
					t.Check(`the {rig} rig's {role} clip {clip} is baked`, Clips.Sequence(clip) ~= nil)
					local mirror = Animations.Mirrors[clip]
					if mirror then
						t.Check(`and its mirror {mirror}`, Clips.Sequence(mirror) ~= nil)
					end
				end
			end
			-- the Shade's Down hides the body on its Burst marker (AR2, the content check: frame 27)
			local down = Clips.Sequence(Animations.Rigs.Shade.Down)
			local burstAt: number? = nil
			for _, keyframe in if down then down:GetKeyframes() else {} do
				for _, marker in (keyframe :: Keyframe):GetMarkers() do
					if marker.Name == "Burst" then
						burstAt = (keyframe :: Keyframe).Time
					end
				end
			end
			t.Near("the Shade's Down bursts on frame 27", burstAt or -1, 27 / 60, BEAT_TOLERANCE)
		end,
	},
	{
		Name = "Fight: the lead stands by the avatar",
		Run = function(t: any)
			t.Wait(LEAD_SETTLE)
			local lead = myLead()
			t.Check("the lead is in the world", lead ~= nil)
			if lead == nil then
				return
			end
			local root = lead:FindFirstChild("HumanoidRootPart") :: BasePart? -- an R6 model's PrimaryPart is its head
			local away = if root then (root.Position - t.Root().Position).Magnitude else math.huge
			t.Check("it stands by the avatar", away < Combat.Lead.CatchUpFrom, string.format("%.1f studs away", away))
			t.Check("it stands", lead:GetAttribute("State") == "Idle", `state {tostring(lead:GetAttribute("State"))}`)
			t.Check("at full health", lead:GetAttribute("Health") == lead:GetAttribute("MaxHealth"))
			local humanoid = lead:FindFirstChildOfClass("Humanoid")
			local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
			local idle: AnimationTrack? = nil
			for _, playing in (if animator then animator:GetPlayingAnimationTracks() else {}) do
				if playing.Animation and playing.Animation.Name == Animations.Rigs.R6.Idle then
					idle = playing
				end
			end
			t.Check("its idle plays", idle ~= nil)
			if idle then
				t.Near("at full weight", idle.WeightTarget, 1, 0.01)
			end
		end,
	},
	{
		Name = "Fight: the lead beats an ordinary Shade, which hits back",
		Run = function(t: any)
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if type(level) ~= "number" then
				return
			end
			local spawned = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
			t.Check("the Shade spawns", type(spawned) == "table" and spawned.Ok == true, tostring(type(spawned) == "table" and spawned.Error))
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local began = os.clock()
			local hurt, fought, fell = false, false, false
			while os.clock() - began < SHADE_TIMEOUT do
				t.Wait(0.25)
				local shade, mine = nil, nil
				for _, row in t.Server("Fighters") do
					if row.Id == spawned.Id then
						shade = row
					elseif row.Kind == "Lead" and lead and row.Id == lead:GetAttribute("Fighter") then
						mine = row
					end
				end
				if mine and mine.Health < mine.MaxHealth then
					hurt = true
				end
				if mine and mine.Target == spawned.Id then
					fought = true
				end
				if shade == nil or shade.State == "Down" then
					fell = true
					break
				end
			end
			local seconds = os.clock() - began
			t.Server("FightSpawn") -- clears what is left
			t.Check("the lead takes the Shade on", fought)
			t.Check("the Shade hits the lead", hurt)
			t.Check("the Shade falls", fell, string.format("after %.1f s", seconds))
			t.Row("seconds from its spawn to its fall, walk-in included", nil, nil, seconds, "s")
		end,
	},
	{
		Name = "Fight: a Shade wears AR2's rig, swings its clip and bursts on its marker",
		Run = function(t: any)
			-- docs/asset-requests.md, AR2, "For the builder": the mask's own light, the type's on the body, the mirrored
			-- swing, and the whole body hidden on the Burst marker (frame 27), where the effect starts.
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if type(level) ~= "number" then
				return
			end
			local spawned = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
			t.Check("the Shade spawns", type(spawned) == "table" and spawned.Ok == true, tostring(type(spawned) == "table" and spawned.Error))
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local model: Model? = nil
			waitFor(t, 5, function(): boolean
				model = fighterModel(spawned.Id)
				return model ~= nil and model:FindFirstChild("Shade_Torso") ~= nil
			end)
			local shade = model :: Model
			t.Check("its model reaches this client", shade ~= nil)
			if shade == nil then
				t.Server("FightSpawn")
				return
			end
			t.Check("it's the Shade rig", shade:GetAttribute("Rig") == "Shade", tostring(shade:GetAttribute("Rig")))
			local masks = {}
			for _, part in shade:GetChildren() do
				if string.sub(part.Name, 1, 5) == "Mask_" then
					table.insert(masks, part.Name)
				end
			end
			t.Check("it wears its row's mask and no other", #masks == 1 and masks[1] == "Mask_Brawler", table.concat(masks, ", "))
			local torso = shade:FindFirstChild("Shade_Torso")
			local mask = shade:FindFirstChild("Mask_Brawler")
			local bodyLook = if torso then torso:FindFirstChildOfClass("SurfaceAppearance") else nil
			local maskLook = if mask then mask:FindFirstChildOfClass("SurfaceAppearance") else nil
			local kind = tostring(shade:GetAttribute("Type"))
			t.Check("its body is lit in its type's colour", bodyLook ~= nil and bodyLook.EmissiveTint == Shades.Tint[kind], kind)
			t.Check("its mask in the mask's own", maskLook ~= nil and maskLook.EmissiveTint == Shades.MaskTint)
			local root = shade:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { shade, workspace:FindFirstChild("Fighters") :: Instance, Players.LocalPlayer.Character :: Instance }
				params.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), params)
				t.Near("its feet on the floor (the root 3 studs up)", if hit then root.Position.Y - hit.Position.Y else -1, 3, 0.35)
			end
			t.Check("its idle plays", waitFor(t, 2, function(): boolean
				return playing(shade)[Animations.Rigs.Shade.Idle] == true
			end))
			local swung = waitFor(t, SHADE_TIMEOUT, function(): boolean
				local now = playing(shade)
				return now.ShadeAttack == true or now.ShadeAttackLeft == true or shade:GetAttribute("State") == "Down"
			end)
			t.Check("it swings its Attack or the mirror", swung and shade:GetAttribute("State") ~= "Down")
			-- frame by frame from here: the hide is timed against the marker, so a poll's tenth would hide a late frame
			local downAt: number? = nil
			local until_ = os.clock() + SHADE_TIMEOUT
			while os.clock() < until_ and shade.Parent ~= nil do
				if shade:GetAttribute("State") == "Down" then
					downAt = os.clock()
					break
				end
				task.wait()
			end
			t.Check("the lead beats it", downAt ~= nil)
			if downAt then
				local function hidden(): boolean
					for _, part in shade:GetDescendants() do
						if part:IsA("BasePart") and part.Transparency < 1 and part.LocalTransparencyModifier < 1 then
							return false
						end
					end
					return true
				end
				-- the Burst clip's own clock: the killing hit's hold (Config.Combat.Hitstop) stops it a beat, so the
				-- wall clock runs ahead of the clip by that hold
				local function clipTime(): number?
					local humanoid = shade:FindFirstChildOfClass("Humanoid")
					local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
					for _, track in (if animator then animator:GetPlayingAnimationTracks() else {}) do
						if track.Animation and track.Animation.Name == Animations.Rigs.Shade.Down then
							return track.TimePosition
						end
					end
					return nil
				end
				local hideAt: number? = nil
				local hideClip: number? = nil
				local shownBefore = not hidden()
				while os.clock() - (downAt :: number) < 1 do
					if hidden() then
						hideAt, hideClip = os.clock(), clipTime()
						break
					end
					task.wait()
				end
				t.Check("its burst plays", playing(shade)[Animations.Rigs.Shade.Down] == true or hideAt ~= nil)
				t.Check("whole until the marker", shownBefore)
				t.Check("then the whole body, mask too, hides at once", hideAt ~= nil)
				if hideAt then
					t.Near("on the marker, frame 27 of the clip", hideClip or -1, 27 / 60, 2 * FRAME)
					t.Row("seconds from the fall to the burst, the hold included", nil, nil, (hideAt :: number) - (downAt :: number), "s")
				end
			end
			t.Server("FightSpawn") -- clears it
		end,
	},
	{
		Name = "Fight: a Shade swings and flinches on alternate sides",
		Run = function(t: any)
			-- research's ask for the Shade (docs/team-notes.md, Now, 2026-11-12): Attack and AttackLeft in turn, Hit and
			-- HitLeft too (Config.Animations.Mirrors). A start is a track that wasn't playing a frame ago, or went back.
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			if type(level) ~= "number" then
				t.Check("the lead is in the world", false)
				return
			end
			local spawned = t.Server("FightSpawn", "brawler", level + SHADE_TOUGHER, SHADE_AHEAD)
			t.Check("the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local model: Model? = nil
			waitFor(t, 5, function(): boolean
				model = fighterModel(spawned.Id)
				return model ~= nil and model:FindFirstChild("Shade_Torso") ~= nil
			end)
			local humanoid = if model then model:FindFirstChildOfClass("Humanoid") else nil
			local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
			t.Check("its model reaches this client", animator ~= nil)
			if model == nil or animator == nil then
				t.Server("FightSpawn")
				return
			end
			local swings: { string }, flinches: { string } = {}, {}
			local seen: { [AnimationTrack]: number } = {}
			local until_ = os.clock() + SHADE_WATCH
			while os.clock() < until_ and model.Parent ~= nil and (#swings < 3 or #flinches < 3) do
				local now: { [AnimationTrack]: number } = {}
				for _, track in animator:GetPlayingAnimationTracks() do
					local before = seen[track]
					local name = if track.Animation then track.Animation.Name else ""
					if before == nil or track.TimePosition < before then
						if name == "ShadeAttack" or name == "ShadeAttackLeft" then
							table.insert(swings, name)
						elseif name == "ShadeHit" or name == "ShadeHitLeft" then
							table.insert(flinches, name)
						end
					end
					now[track] = track.TimePosition
				end
				seen = now
				task.wait()
			end
			t.Server("FightSpawn") -- clears it
			local function alternates(list: { string }): boolean
				for i = 2, #list do
					if list[i] == list[i - 1] then
						return false
					end
				end
				return #list >= 2
			end
			t.Check("its swings alternate", alternates(swings), table.concat(swings, ", "))
			-- an ordinary flinches only between actions (FightService), and a Shade in reach swings back to back, so its
			-- flinches come on the walk-in or not at all; the swing proved the turn they share
			if #flinches >= 2 then
				t.Check("its flinches alternate", alternates(flinches), table.concat(flinches, ", "))
			end
			t.Row("flinches seen", nil, nil, #flinches, "")
		end,
	},
	{
		Name = "Fight: the elite is the Shade rig, larger",
		Run = function(t: any)
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			if type(level) ~= "number" then
				t.Check("the lead is in the world", false)
				return
			end
			local spawned = t.Server("FightSpawn", "brawler_elite", level, SHADE_AHEAD)
			t.Check("the elite spawns", type(spawned) == "table" and spawned.Ok == true)
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local model: Model? = nil
			waitFor(t, 5, function(): boolean
				model = fighterModel(spawned.Id)
				return model ~= nil and model:FindFirstChild("Shade_Torso") ~= nil
			end)
			local elite = model
			local root = if elite then elite:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			t.Check("its model reaches this client", root ~= nil)
			if elite and root then
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = { workspace:FindFirstChild("Fighters") :: Instance, Players.LocalPlayer.Character :: Instance }
				params.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), params)
				local scale = Enemies.ById.brawler_elite.Scale or 1
				t.Near("its feet on the floor, at its scale", if hit then root.Position.Y - hit.Position.Y else -1, 3 * scale, 0.45)
				t.Near("its scale", elite:GetScale(), scale, 0.01)
			end
			t.Server("FightSpawn")
		end,
	},
	{
		Name = "Fight: Haymaker's look keeps its frames, and leaves nothing",
		Stay = true,
		Run = function(t: any)
			-- docs/asset-requests.md, AR1, section 5: the charge to the strike, the strike's square held through the hitstop,
			-- the shock's square the frame after, then the hero and the floor's lines; all gone by frame 76, Strike + 19.
			local action = Actions.ById.RookHaymaker
			local lead = myLead()
			t.Check("the lead is in the world", lead ~= nil)
			if lead == nil then
				return
			end
			local strike, shock = action.Beats.Strike, action.Beats.Shock
			-- One synchronous run, no yields: nothing else can add an effect part between its steps.
			local folder = workspace:FindFirstChild("NL_Effects")
			local theirs: { [Instance]: boolean } = {}
			for _, p in (if folder then folder:GetChildren() else {}) do
				theirs[p] = true
			end
			local function shown(): (number, number)
				local count, all = 0, 0
				local home = workspace:FindFirstChild("NL_Effects")
				for _, p in (if home then home:GetChildren() else {}) do
					if theirs[p] or not p:IsA("BasePart") then
						continue
					end
					all += 1
					local gui = p:FindFirstChildOfClass("SurfaceGui")
					if p.Transparency < 1 or (gui and gui.Enabled) then
						count += 1
					end
				end
				return count, all
			end
			local running = Effects.Haymaker(action.Beats, lead, function(): BasePart?
				return nil
			end)
			local function at(clock: number): number
				running.Step(clock)
				return (shown())
			end
			t.Check("the charge's square before the strike", at(strike - 10 * FRAME) == SQUARE, `{shown()} bars`)
			-- Which square shows: its four bars, the longest as long as the square's side and bar (a picture's part is the
			-- stroke's length over the picture's span).
			local look = EffectsConfig.Haymaker
			local function isSquare(clock: number, square: { Side: number, Bar: number }): (boolean, string)
				local count = at(clock)
				local longest = 0
				local home = workspace:FindFirstChild("NL_Effects")
				for _, p in (if home then home:GetChildren() else {}) do
					if not theirs[p] and p:IsA("BasePart") then
						local gui = p:FindFirstChildOfClass("SurfaceGui")
						if p.Transparency < 1 or (gui and gui.Enabled) then
							longest = math.max(longest, p.Size.X)
						end
					end
				end
				local want = (square.Side + square.Bar) / (if look.Picture == "" then 1 else look.Span)
				return count == SQUARE and math.abs(longest - want) < 0.01, string.format("%d bars, %.2f long, want %.2f", count, longest, want)
			end
			-- a slow frame that lands past Shock still gives the strike its square, and the hitstop holds the clock there
			t.Check("the strike's square on the first frame past Strike", isSquare(shock + 0.25 * FRAME, look.Strike))
			t.Check("held there through the hitstop", isSquare(shock + 0.25 * FRAME, look.Strike))
			t.Check("the shock's square on the next frame", isSquare(shock + 0.75 * FRAME, look.Shock))
			local flying = at(shock + 4 * FRAME)
			t.Check("the hero and the floor's lines while it flies", flying > BRACKET, `{flying} bars`)
			local last = shock + (look.Hero.Fly + look.Hero.Leaves - 0.5) * FRAME
			t.Check("the hero still there on its last frame", at(last) >= BRACKET, `{shown()} bars`)
			local over = running.Step(strike + GONE_BY)
			local _, left = shown()
			t.Check("over by Strike + 19 frames", over == false)
			t.Check("and nothing left", left == 0, `{left} parts`)
			running.Destroy()
		end,
	},
	{
		Name = "Fight: the replay lands each hit of the combo once",
		Run = function(t: any)
			local action = Actions.ById.RookCombo
			local lead = myLead()
			t.Check("the lead is in the world", lead ~= nil)
			if lead == nil then
				return
			end
			local beats: { [string]: number } = {}
			local connection = Net.Client.On("Hit", function(hit: any)
				if type(hit) == "table" and hit.A == lead and hit.Action == action.Id then
					beats[hit.Beat] = (beats[hit.Beat] or 0) + 1
				end
			end)
			local ok, result = pcall(function()
				-- one press: the next would come after the run's end
				return t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE) -- the bridge passes this player first
			end)
			t.Check("the replay starts", ok and type(result) == "table" and result.Ok == true, tostring(if ok then result and result.Error else result))
			t.Wait(action.Length + 0.3)
			connection:Disconnect()
			local dummy: Model? = nil
			for _, model in (workspace:FindFirstChild("Fighters") or workspace):GetChildren() do
				if model:IsA("Model") and model:GetAttribute("Kind") == "Dummy" then
					dummy = model
				end
			end
			local health = if dummy then dummy:GetAttribute("Health") else nil
			local max = if dummy then dummy:GetAttribute("MaxHealth") else nil
			t.Check("the dummy took damage", type(health) == "number" and type(max) == "number" and health < max)
			for beat in action.Hits do
				t.Check(`{beat} landed once`, beats[beat] == 1, `{beats[beat] or 0} times`)
			end
			local mode = Players.LocalPlayer:GetAttribute("Replay")
			t.Check("the replay's camera is on", type(mode) == "string" and mode ~= "", `got {tostring(mode)}`)
			t.Server("Replay")
			t.Wait(0.3)
			t.Check("the dummy is gone after the stop", dummy == nil or dummy.Parent == nil)
			local after = Players.LocalPlayer:GetAttribute("Replay")
			t.Check("the replay's camera is off", after == nil or after == "", `got {tostring(after)}`)
		end,
	},
	{
		Name = "HUD: the lead's card reads the lead in the fight, the pills read the save",
		Run = function(t: any)
			t.Wait(LEAD_SETTLE)
			local parts = HudController.Parts()
			local lead = myLead()
			local view = ProfileController.Get()
			t.Check("the lead is in the world and the save's copy is here", lead ~= nil and view ~= nil)
			if lead == nil or view == nil then
				return
			end
			t.Check("the lead's card shows", parts.Lead.Visible)
			local name, level = (parts.LeadName :: TextLabel).Text, (parts.LeadLevel :: TextLabel).Text
			t.Check("with the lead's name", name == lead:GetAttribute("Title"), name)
			t.Check("and its level", level == `Lv {lead:GetAttribute("Level")}`, level)
			local health, most = lead:GetAttribute("Health") :: number, lead:GetAttribute("MaxHealth") :: number
			t.Near("its health bar is its share of health", parts.LeadHealth:GetAttribute("Share") :: number, health / most, 0.01)
			local credits = (parts.Credits :: TextLabel).Text
			t.Check("the Credits pill shows the save's", credits == `Credits {Read.Number(view.Currency.Credits)}`, credits)
			t.Wait(PLATE_TICK)
			local shown = (parts.Electricity :: TextLabel).Text
			local digits = string.gsub(shown:match("^([%d,]+) /") or "", ",", "")
			local stored = tonumber(digits)
			local now = Read.Base(view, workspace:GetServerTimeNow())
			t.Check("the Electricity pill shows a number", stored ~= nil, shown)
			if stored then
				t.Near("the battery as it stands now", stored, now.Data.Base.Battery, 1)
			end
			t.Check("the target's card hides out of a fight", not parts.Target.Visible)
			lintClean(t, "the HUD")
		end,
	},
	{
		Name = "HUD: the target's card shows the lead's foe in a fight, and leaves with it",
		Run = function(t: any)
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if lead == nil or type(level) ~= "number" then
				return
			end
			local spawned = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
			t.Check("the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local parts = HudController.Parts()
			local met = waitFor(t, SHADE_TIMEOUT, function(): boolean
				return lead:GetAttribute("Target") == spawned.Id and parts.Target.Visible
			end)
			t.Check("the target's card shows when the lead takes the Shade on", met)
			local foe = (parts.TargetName :: TextLabel).Text
			t.Check("with the Shade's name", foe == Enemies.ById.brawler.Name, foe)
			t.Server("FightSpawn") -- clears it
			t.Check("and hides once it's gone", waitFor(t, 2, function(): boolean
				return not parts.Target.Visible
			end))
		end,
	},
	{
		Name = "Base: the plot's Breaker, bays and battery carry their prompt and plate; the dock opens each screen",
		Run = function(t: any)
			local parts = BaseController.Parts()
			local view = ProfileController.Get()
			t.Check("the save's copy is here", view ~= nil)
			if view == nil then
				return
			end
			t.Check("the Breaker has its prompt", parts.BreakerPrompt ~= nil and parts.BreakerPrompt:IsA("ProximityPrompt"))
			t.Check("and its plate", parts.BreakerPlate ~= nil)
			t.Check("the battery has its plate", parts.BatteryPlate ~= nil)
			local index = 1
			while parts[`Bay{index}Plate`] do
				local open = index <= #view.Base.Bays
				t.Check(`bay {index} has its plate, and a prompt only when open`, (parts[`Bay{index}Prompt`] ~= nil) == open)
				index += 1
			end
			t.Check("the plot has a bay beyond the open ones, shown locked", index - 1 > #view.Base.Bays, `{index - 1} bays, {#view.Base.Bays} open`)
			local hud = HudController.Parts()
			for _, name in { "Base", "Voidkin" } do
				Screen.Close()
				t.Check(`the dock's {name} can be pressed`, Button.Press(hud[name] :: TextButton))
				t.Check(`and opens the {name} screen`, waitFor(t, 1, function(): boolean
					return Screen.Current() == name
				end))
				t.Wait(0.1) -- laid out
				lintClean(t, `the {name} screen`)
			end
			Screen.Close()
		end,
	},
	{
		Name = "Base: a shard added through the screen breaks, and opening it shows a card that names it",
		Run = function(t: any)
			local view = ProfileController.Get()
			t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
			if view == nil or view.Progress.Starter == "" then
				return
			end
			local shard = "named_watt"
			local held = view.Bag.Shards[shard] or 0
			t.Server("BaseGive", shard, 1)
			t.Check("the server gives one", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
			end))
			BaseController.Open()
			local add = screenButton("Base", "Bays", shard)
			t.Check("the bag's row offers Add", add ~= nil)
			if add == nil then
				Screen.Close()
				return
			end
			t.Check("and can be pressed", Button.Press(add))
			t.Check("the shard leaves the bag", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held
			end))
			t.Server("BaseSkip", SKIP_ALL)
			t.Check("it breaks", waitFor(t, ANSWER, function(): boolean
				return readyCount(shard) > 0
			end))
			t.Check("the Breaker's prompt says Open", waitFor(t, 1, function(): boolean
				local prompt = BaseController.Parts().BreakerPrompt :: ProximityPrompt?
				return prompt ~= nil and prompt.ActionText == "Open"
			end))
			local open = screenButton("Base", "Breaker", `Ready_{shard}`)
			t.Check("the screen offers Open on it", open ~= nil)
			if open == nil then
				Screen.Close()
				return
			end
			Button.Press(open)
			t.Check("the reveal shows", waitFor(t, ANSWER, function(): boolean
				return BaseController.Revealed() ~= nil
			end))
			local shown = BaseController.Revealed()
			t.Check("and names Watt", shown ~= nil and shown.Name == Voidkin.ById.watt.Name, if shown then shown.Name else "nothing")
			lintClean(t, "the reveal")
			BaseController.Dismiss()
			t.Check("it closes", BaseController.Revealed() == nil)
			Screen.Close()
		end,
	},
	{
		Name = "Base: identical shards ready to open share one row with their count, and every row's name shows whole",
		Run = function(t: any)
			local view = ProfileController.Get()
			t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
			if view == nil or view.Progress.Starter == "" then
				return
			end
			local shard = "lanternrow_standard" -- the longest shard name the game has: "Lantern Row shard"
			local before = readyCount(shard)
			local held = view.Bag.Shards[shard] or 0
			t.Server("BaseGive", shard, 2)
			t.Check("the server gives two", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 2
			end))
			for _ = 1, 2 do
				t.Check("each goes into the Breaker", ProfileController.Act("AddShard", { Shard = shard }).Ok == true)
			end
			t.Server("BaseSkip", SKIP_ALL)
			t.Check("both break", waitFor(t, ANSWER, function(): boolean
				return readyCount(shard) == before + 2
			end))
			local count = readyCount(shard)
			BaseController.Open()
			t.Wait(0.1) -- laid out
			local frame = Screen.Frame("Base")
			local list = frame and frame:FindFirstChild("Breaker", true)
			local rows = 0
			for _, row in (if list then list:GetChildren() else {}) do
				local label = row:FindFirstChild("Label") :: TextLabel?
				rows += if string.find(row.Name, "^Ready") and label and label.Text == Read.ShardName(shard) then 1 else 0
			end
			t.Check("they share one row", rows == 1, `{rows} rows for {count} ready`)
			local row = list and list:FindFirstChild(`Ready_{shard}`)
			local detail = row and row:FindFirstChild("Detail") :: TextLabel?
			t.Check("its second line gives the count", detail ~= nil and detail.Text == `Ready to open · {count}`, if detail then detail.Text else "no second line")
			-- A name truncates rather than overrun, so the lint passes it either way: here it must not be cut at all, at
			-- this screen's scale and at the smallest phone's, where text draws largest against its box (Text.Legible).
			for _, at in { { Name = "this screen", Scale = nil }, { Name = "the smallest phone", Scale = Theme.Scale.Floor } } do
				Layers.Force(at.Scale)
				t.Wait(0.1) -- laid out again
				local cut = {}
				for _, label in (if frame then frame:GetDescendants() else {}) do
					if label:IsA("TextLabel") and label.Name == "Label" and label.Visible and not label.TextFits then
						table.insert(cut, label.Text)
					end
				end
				t.Check(`no row's name is cut, at {at.Name}'s scale`, #cut == 0, table.concat(cut, ", "))
				lintClean(t, `the Base screen with shards ready, at {at.Name}'s scale`)
			end
			Layers.Force(nil)
			local open = screenButton("Base", "Breaker", `Ready_{shard}`)
			t.Check("Open can be pressed", open ~= nil and Button.Press(open))
			t.Check("it opens one of them", waitFor(t, ANSWER, function(): boolean
				return BaseController.Revealed() ~= nil and readyCount(shard) == count - 1
			end))
			BaseController.Dismiss()
			t.Check("and the row counts one fewer", waitFor(t, 1, function(): boolean
				local again = screenButton("Base", "Breaker", `Ready_{shard}`)
				local line = again and (again.Parent :: Instance):FindFirstChild("Detail") :: TextLabel?
				return line ~= nil and line.Text == (if count - 1 > 1 then `Ready to open · {count - 1}` else "Ready to open")
			end))
			Screen.Close()
			-- Leaves the Breaker as it found it: the rest of what this case broke, opened.
			while readyCount(shard) > before do
				local current = ProfileController.Get()
				local at = 0
				for index, work in (if current then current.Base.Ready else {}) do
					if at == 0 and work.Def == shard then
						at = index
					end
				end
				if ProfileController.Act("Open", { Index = at }).Ok ~= true then
					break
				end
			end
		end,
	},
	{
		Name = "Base: the world's plates step back while a screen is open, and come back when it closes",
		Run = function(t: any)
			local layer = Layers.Get("World")
			Screen.Close()
			t.Wait(0.1) -- a frame of the plates' step
			t.Check("the world's layer shows with no screen open", layer.Visible)
			for _, name in { "Base", "Voidkin" } do
				local hud = HudController.Parts()
				t.Check(`the dock opens {name}`, Button.Press(hud[name] :: TextButton) and waitFor(t, 1, function(): boolean
					return Screen.Current() == name
				end))
				t.Check(`the world's layer hides while {name} is open`, waitFor(t, 0.5, function(): boolean
					return not layer.Visible
				end))
				Screen.Close()
				t.Check(`and shows again once {name} closes`, waitFor(t, 0.5, function(): boolean
					return layer.Visible
				end))
			end
		end,
	},
	{
		Name = "Base: a worker set through the screen works its bay, and its plate says so",
		Run = function(t: any)
			local view = ProfileController.Get()
			t.Check("a bay is open", view ~= nil and #view.Base.Bays >= 1)
			if view == nil or #view.Base.Bays < 1 then
				return
			end
			local previous = view.Base.Bays[1].Worker
			local pick: any = nil
			for _, owned in Read.Roster(view) do
				if owned.Id ~= view.Roles.Lead and pick == nil then
					pick = owned
				end
			end
			t.Check("someone besides the lead can work", pick ~= nil)
			if pick == nil then
				return
			end
			local function worker(): string
				local now = ProfileController.Get()
				return if now and now.Base.Bays[1] then now.Base.Bays[1].Worker else "?"
			end
			BaseController.Open()
			local set = screenButton("Base", "Bays", "Bay1")
			t.Check("bay 1's row offers Set", set ~= nil and Button.Press(set))
			if previous == pick.Id then
				local empty = screenButton("Base", "Bays", "Empty")
				t.Check("a bay with a worker can be emptied", empty ~= nil and Button.Press(empty))
				t.Check("and is", waitFor(t, ANSWER, function(): boolean
					return worker() == ""
				end))
				set = screenButton("Base", "Bays", "Bay1")
				t.Check("bay 1's row offers Set again", set ~= nil and Button.Press(set))
			end
			local work = screenButton("Base", "Bays", pick.Id)
			t.Check(`{Read.VoidkinName(pick)} can be put to work`, work ~= nil and Button.Press(work))
			t.Check("and works bay 1", waitFor(t, ANSWER, function(): boolean
				return worker() == pick.Id
			end))
			t.Wait(PLATE_TICK)
			local plate = BaseController.Parts().Bay1Plate
			local line = if plate then plate:FindFirstChild("Line1", true) :: TextLabel? else nil
			local text = if line then line.Text else ""
			t.Check("bay 1's plate names it, with its output", string.find(text, Read.VoidkinName(pick), 1, true) == 1 and string.find(text, "/min", 1, true) ~= nil, text)
			Screen.Close()
			if previous ~= pick.Id then
				ProfileController.Act("SetWorker", { Bay = 1, Voidkin = previous })
			end
		end,
	},
	-- For a capture from the player's camera: run "arrives on their own plot" first, then these, then screen_capture.
	{
		Name = "Capture: the Base screen open with every kind of row",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			local view = ProfileController.Get()
			if view == nil or view.Progress.Starter == "" then
				t.Check("the first shard is chosen", false)
				return
			end
			local standard, named = "lanternrow_standard", "named_watt"
			local function add(shard: string, n: number)
				t.Server("BaseGive", shard, n)
				waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and (now.Bag.Shards[shard] or 0) >= n
				end)
				for _ = 1, n do
					ProfileController.Act("AddShard", { Shard = shard })
				end
			end
			if readyCount(standard) < 2 then
				add(standard, 2 - readyCount(standard))
			end
			if readyCount(named) < 1 then
				add(named, 1)
			end
			t.Server("BaseSkip", SKIP_ALL)
			add(standard, 3) -- two counting down, one in line
			t.Server("BaseSkip", 10)
			t.Server("BaseGive", standard, 2) -- and two in the bag
			t.Wait(0.5)
			BaseController.Open()
			t.Check("the Base screen is open", Screen.Current() == "Base")
		end,
	},
	{
		Name = "Take: the loop on a new account, for research's verdict",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			-- TR2's evidence (docs/test-requests.md, TR2): the loop at real speed from the player's camera, on a new account
			-- in the Test store, the screens pressed through their own buttons. A white frame opens the take so a recording
			-- finds its zero, and each moment is a row in seconds from it. Two steps aren't played, and their rows say so:
			-- the walk home (a respawn) and Watt's 30 s in the Breaker (BaseSkip).
			local player = Players.LocalPlayer
			local zero = os.clock()
			local function moment(name: string)
				t.Row(`moment: {name}`, nil, nil, math.floor((os.clock() - zero) * 100 + 0.5) / 100, "s")
			end
			local function standing(name: string): number
				for _, row in t.Server("Packs") do
					if row.Name == name then
						return row.Standing
					end
				end
				return 0
			end
			local function arrive(): boolean
				local old = player.Character
				t.Server("Respawn")
				return waitFor(t, ARRIVE_TIMEOUT, function(): boolean
					local character = player.Character
					local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
					return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
				end)
			end
			-- The camera a player steers: while the avatar walks, it swings in behind it.
			RunService:BindToRenderStep("NL_TakeCamera", Enum.RenderPriority.Camera.Value - 1, function(dt: number)
				local root = player.Character and Parts.Root(player.Character)
				local camera = workspace.CurrentCamera
				if root == nil or Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude < 2 then
					return
				end
				local look = camera.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				local want = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				if flat.Magnitude < 0.01 or want.Magnitude < 0.01 then
					return
				end
				local turned = flat.Unit:Lerp(want.Unit, math.min(1, dt * TAKE_TURN))
				if turned.Magnitude < 0.01 then
					return
				end
				local across = math.sqrt(math.max(0, 1 - look.Y * look.Y))
				local direction = Vector3.new(turned.Unit.X * across, look.Y, turned.Unit.Z * across)
				camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + direction)
			end)
			local function walkTo(goal: Vector3): boolean
				local character = player.Character
				local humanoid = if character then Parts.Humanoid(character) else nil
				if humanoid == nil then
					return false
				end
				local points = { goal }
				local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false })
				if pcall(function()
					path:ComputeAsync(t.Root().Position, goal)
				end) and path.Status == Enum.PathStatus.Success then
					points = {}
					for _, point in path:GetWaypoints() do
						table.insert(points, point.Position)
					end
				end
				local deadline = os.clock() + TAKE_WALK
				for _, at in points do
					humanoid:MoveTo(at)
					while os.clock() < deadline do
						local here = t.Root().Position
						if Vector3.new(here.X - at.X, 0, here.Z - at.Z).Magnitude <= TAKE_REACH then
							break
						end
						t.Wait(0.05)
					end
				end
				local here = t.Root().Position
				return Vector3.new(here.X - goal.X, 0, here.Z - goal.Z).Magnitude <= TAKE_REACH * 2
			end
			local function fight(name: string): boolean
				local before = t.Server("Drops")
				local first = before.Kills == 0
				return waitFor(t, TAKE_FIGHT, function(): boolean
					if first and t.Server("Drops").Kills > 0 then
						first = false
						moment("the account's first kill: Watt's shard drops")
					end
					return standing(name) == 0
				end)
			end

			-- The zoom is held at Roblox's starting distance for the take: a key or a wheel that reaches Studio while the hold
			-- keeps it in front can't pull the camera out (the take of 2026-11-12 lost its last 30 s to one).
			local zoomMin, zoomMax = player.CameraMinZoomDistance, player.CameraMaxZoomDistance
			player.CameraMinZoomDistance = TAKE_ZOOM
			player.CameraMaxZoomDistance = TAKE_ZOOM
			local ok, problem = pcall(function()
				t.Server("DataWipe")
				t.Check("a new account", waitFor(t, ANSWER, function(): boolean
					local view = ProfileController.Get()
					return view ~= nil and view.Progress.Starter == ""
				end))
				local flash = Instance.new("ScreenGui")
				flash.Name = "NL_TakeZero"
				flash.IgnoreGuiInset = true
				flash.DisplayOrder = 1000
				local white = Instance.new("Frame")
				white.Size = UDim2.fromScale(1, 1)
				white.BackgroundColor3 = Color3.new(1, 1, 1)
				white.BorderSizePixel = 0
				white.Parent = flash
				flash.Parent = player:WaitForChild("PlayerGui")
				RunService.RenderStepped:Wait()
				zero = os.clock()
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				flash:Destroy()
				moment("zero: the white frame")

				t.Check("the avatar arrives on its plot", arrive())
				moment("arrival on the plot")
				t.Wait(WorldConfig.Arrive + 1)
				BaseController.Open()
				moment("the Base screen: choose your first shard")
				t.Wait(TAKE_READ)
				local choose = screenButton("Base", "Breaker", "starter_rook")
				t.Check("Rook's shard is chosen through the screen", choose ~= nil and Button.Press(choose))
				moment("Rook's shard chosen: it breaks")
				t.Check("it breaks", waitFor(t, 15, function(): boolean
					return readyCount("starter_rook") > 0
				end))
				moment("ready to open")
				t.Wait(1)
				local open = screenButton("Base", "Breaker", "Ready_starter_rook")
				t.Check("and opens through the screen", open ~= nil and Button.Press(open))
				t.Check("the reveal shows", waitFor(t, ANSWER, function(): boolean
					return BaseController.Revealed() ~= nil
				end))
				moment("the reveal: Rook")
				t.Wait(TAKE_READ + 0.5)
				BaseController.Dismiss()
				Screen.Close()
				moment("the card and the screen closed")
				t.Check("the lead stands by the avatar", waitFor(t, 5, function(): boolean
					return myLead() ~= nil
				end))
				moment("Rook stands by the avatar")
				t.Wait(2)

				local packs: { [string]: any } = {}
				for _, row in t.Server("Packs") do
					packs[row.Name] = row
				end
				for _, name in { "Pack 1", "Pack 2" } do
					local row = packs[name]
					if row == nil then
						t.Check(`{name} stands`, false)
						break
					end
					local at: Vector3 = row.At
					moment(`the walk to {name}`)
					t.Check(`the avatar walks to {name}`, walkTo(at + Vector3.new(0, R6_ROOT_HEIGHT, PACK_STAND)))
					moment(`at {name}`)
					t.Check(`{name} falls`, fight(name))
					moment(`{name} down`)
					t.Wait(2)
				end

				moment("home: a respawn stands in for the walk back")
				t.Check("the avatar is home", arrive())
				t.Wait(WorldConfig.Arrive + 1)
				BaseController.Open()
				moment("the Base screen, Watt's shard in the bag")
				t.Wait(TAKE_READ)
				local add = screenButton("Base", "Bays", "named_watt")
				t.Check("Watt's shard goes in through the screen", add ~= nil and Button.Press(add))
				moment("Watt's shard in the Breaker")
				t.Wait(TAKE_READ)
				t.Server("BaseSkip", 30)
				moment("skipped: Watt's 30 s in the Breaker")
				t.Check("it breaks", waitFor(t, ANSWER, function(): boolean
					return readyCount("named_watt") > 0
				end))
				t.Wait(1)
				local openWatt = screenButton("Base", "Breaker", "Ready_named_watt")
				t.Check("and opens through the screen", openWatt ~= nil and Button.Press(openWatt))
				t.Check("the reveal shows", waitFor(t, ANSWER, function(): boolean
					return BaseController.Revealed() ~= nil
				end))
				moment("the reveal: Watt")
				t.Wait(TAKE_READ + 0.5)
				BaseController.Dismiss()
				local view = ProfileController.Get()
				local watt: any = nil
				for _, owned in (if view then Read.Roster(view) else {}) do
					if view and owned.Id ~= view.Roles.Lead then
						watt = owned
					end
				end
				local set = screenButton("Base", "Bays", "Bay1")
				t.Check("bay 1 offers Set", set ~= nil and Button.Press(set))
				t.Wait(1)
				local work = if watt then screenButton("Base", "Bays", watt.Id) else nil
				t.Check("Watt goes to work through the screen", work ~= nil and Button.Press(work))
				moment("Watt to work in bay 1")
				t.Wait(TAKE_READ)
				Screen.Close()
				moment("the plot: Watt's plate and the battery")
				t.Wait(6)
				moment("end")
			end)
			RunService:UnbindFromRenderStep("NL_TakeCamera")
			player.CameraMinZoomDistance = zoomMin
			player.CameraMaxZoomDistance = zoomMax
			if not ok then
				error(problem, 0)
			end
		end,
	},
	{
		Name = "Capture: the plot's plates, no screen open",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			Screen.Close()
			BaseController.Dismiss()
			t.Check("no screen is open", Screen.Current() == nil)
		end,
	},
}
