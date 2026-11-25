--!strict
-- Cases (client, Studio only): the self-test's list, a child of SelfTestController. Name is what a filter matches. Run gets
-- the `t` API (SelfTestController, type Test). Manual = true keeps a case out of a full run; Stay = true skips the reset to
-- the pad. Expected values come from Config or the instances themselves, never typed twice. One case, one behaviour.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Stats = require(Shared.Rules.Stats)
local StatsConfig = require(Shared.Config.Stats)
local Tune = require(Shared.Util.Tune)
local TestInput = require(Shared.Util.TestInput)
local Actions = require(Shared.Definitions.Actions)
local Passives = require(Shared.Definitions.Passives)
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Shades = require(Shared.Config.Shades)
local EffectsConfig = require(Shared.Config.Effects)
local ShadeBurstArt = require(Shared.Config.ShadeBurstArt)
local WorldConfig = require(Shared.Config.World)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Markers = require(Shared.World.Markers)
local Kit = require(Shared.World.Kit)
local LightingConfig = require(Shared.Config.Lighting)
local Parts = require(Shared.Util.Parts)
local CameraTurn = require(Shared.Util.CameraTurn)
local Drops = require(Shared.Rules.Drops)
local Odds = require(Shared.Rules.Odds)
local Breaker = require(Shared.Rules.Breaker)
local Power = require(Shared.Rules.Power)
local Profile = require(Shared.Data.Profile)
local ShardConfig = require(Shared.Config.Shards)
local ShardDefs = require(Shared.Definitions.Shards)
local Hud = require(Shared.Rules.Hud)
local Voidkin = require(Shared.Definitions.Voidkin)
local Rarity = require(Shared.Definitions.Rarity)
local RevealConfig = require(Shared.Config.Reveal)
local RevealArt = require(Shared.Config.RevealArt)
local RevealRule = require(Shared.Rules.Reveal)
local FightRule = require(Shared.Rules.Fight)
local Enemies = require(Shared.Definitions.Enemies)
local Clips = require(script.Parent.Parent.Parent.Main.FighterController.Clips)
local Effects = require(script.Parent.Parent.Parent.Main.FighterController.Effects)
local Sounds = require(script.Parent.Parent.Parent.Main.FighterController.Sounds)
local Rows = require(script.Parent.Parent.Parent.Main.FighterController.Rows)
local FxKit = require(Shared.Config.FxKit)
local Track = require(Shared.Rules.Track)
local FighterController = require(script.Parent.Parent.Parent.Main.FighterController)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local FadeController = require(script.Parent.Parent.Parent.Main.FadeController)
local SpectateController = require(script.Parent.Parent.Parent.Main.SpectateController)
local LightingController = require(script.Parent.Parent.Parent.Main.LightingController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local DownController = require(script.Parent.Parent.Parent.Main.DownController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Digits = require(UI.Kit.Digits)
local Fade = require(UI.Kit.Fade)
local BreakerScreen = require(UI.BreakerScreen)
local VoidkinScreen = require(UI.VoidkinScreen)
local World = require(UI.World)
local Read = require(UI.Read)
local Readout = require(UI.Readout)
local Button = require(UI.Kit.Button)
local Row = require(UI.Kit.Row)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Text = require(UI.Kit.Text)
local Pop = require(UI.Kit.Pop)
local Fly = require(UI.Kit.Fly)
local Count = require(UI.Kit.Count)
local Burst = require(UI.Kit.Burst)
local UiLint = require(script.Parent.UiLint)
local Takes = require(script.Parent.Takes)
local VoidkinCases = require(script.Parent.VoidkinCases)
local BagCases = require(script.Parent.BagCases)
local HudCases = require(script.Parent.HudCases)
local DockCases = require(script.Parent.DockCases)
local PowerCases = require(script.Parent.PowerCases)
local ViewCases = require(script.Parent.ViewCases)
local NumberCases = require(script.Parent.NumberCases)
local BaseCases = require(script.Parent.BaseCases)
local Helpers = require(script.Parent.Helpers)
local TravelCases = require(script.Parent.TravelCases)
local HomePanel = require(UI.HomePanel)

local R6_ROOT_HEIGHT = 3 -- an R6 body's root stands 3 studs above the floor (legs 2, half the torso 1): an engine fact
local TUNE_PATH = "Game.Version" -- a string any build has; the case puts it back
local BEAT_TOLERANCE = 1 / 120 -- half a frame at 60 fps
local LEAD_SETTLE = 1.5 -- seconds for the lead to catch up after the reset's teleport (Config.Combat.Lead)
local TAPE_WATCH = 2.4 -- one loop of Rook's idle
local TAPE_SWING = 5 -- degrees: his idle swings the tape about 9
local REPLAY_PAUSE = 5 -- seconds past the action before a second press, longer than the case waits
local SHADE_AHEAD = 12 -- studs ahead of the avatar a test Shade spawns: inside its notice and the lead's leash
local SHADE_TIMEOUT = 20 -- seconds a level-matched ordinary may take to fall (the seed is 5 s of fighting, Config.Enemies)
local SHADE_TOUGHER = 10 -- levels over the lead's a Shade spawns at to swing and flinch several times before it falls
local SHADE_WATCH = 12 -- seconds the alternation case watches for three swings and three flinches
-- The skip back as this screen draws it (Config.Combat.Skip): a body replicates about a tenth of a second behind its
-- action's attribute, so the landing is read that much after Land, and the Shade may have stepped in meanwhile.
local SKIP_LAG = 0.15 -- seconds
local SKIP_LAG_STUDS = 1.5 -- studs the Shade can close in that lag
local SKIP_SETTLE = 0.15 -- seconds after the landing it must stay put
local SKIP_SLIDE = 0.5 -- studs it may drift in them
local SKIP_MIN_TRAVEL = 2 -- studs farther from the Shade's spot it must land
local SKIP_FACING = 30 -- degrees off the Shade at worst through the travel, once turned onto it
local SKIP_TURN = 0.1 -- seconds into the skip it has turned onto the Shade: it may start off it, from a Shade that ran in
local SKIP_NEXT = 0.3 -- seconds after Land its next action may wait for the next think
-- A move's landing (Actions.Moves, FightService's carry), read SKIP_LAG after its glide or blink as this screen draws it:
-- this near Rules.Fight.MoveEnd's point, a glide's last frame at a dash's speed (about 27 studs a second) and the lag.
local MOVE_NEAR = 1 -- studs
local PASSIVE_LOW = 0.2 -- the health share a test sets to bring a Reduction on (Rook's Second Wind holds under 0.3)
local PASSIVE_CUE = 1 -- seconds a passive's cue may take to show or go, the server's attribute and a fade included
local PASSIVE_NEAR = 1 -- studs from the body a shell's middle stands
local FRAME = 1 / 60 -- the clip's frame, which the art sheets count in
local SQUARE = 4 -- bars in a square
local GONE_BY = 19 * FRAME -- the art sheet: Haymaker's look is over by frame 76, Strike (57) + 19

-- An effect's GUI shows by its image, enabled from its making and cleared a step after its last frame (AR8 A).
local function pictured(gui: Instance?): boolean
	if gui == nil or not (gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) or not (gui :: any).Enabled then
		return false
	end
	for _, label in gui:GetChildren() do
		if label:IsA("ImageLabel") and label.ImageTransparency < 1 then
			return true
		end
	end
	return false
end

-- A part an effect lays: seen in grey, or by a face's picture.
local function laid(p: BasePart): boolean
	if p.Transparency < 1 then
		return true
	end
	for _, gui in p:GetChildren() do
		if pictured(gui) then
			return true
		end
	end
	return false
end
local ARRIVE_TIMEOUT = 8 -- seconds for a respawned avatar to stand on its spawn
local FACING_TOLERANCE = 10 -- degrees off straight at the Breaker that still count as facing it
local CAMERA_TOLERANCE = 25 -- the camera swings in behind the avatar a moment late
local RESPAWN_PATH = "World.Row.Respawn"
local PACK_BACK = 1 -- seconds a felled pack takes to come back while the case runs; the case puts the seed back
local MOVE_SLACK = 0.5 -- seconds past a fade's move before the case reads where the avatar stands
local SET_DOWN = 2 -- studs from its spot a set-down avatar may stand once physics settles it
local KEEPER_MEETS = 3 -- seconds after arriving by which the lead fights the keeper (it arrives inside Lead.Leash of it)
local KEEPER_BESIDE = 4 -- seconds after they trade hits by which the lead stands at the keeper's side
local BESIDE_TOLERANCE = 25 -- degrees off square to the avatar's facing that still read as side by side
local LANDED = 0.3 -- seconds after a keeper's fall by which a lead's step under way has landed: a think and the replication
local CAMERA_BACK = 12.5 -- studs behind the avatar the player's camera stands at Roblox's default zoom (the takes' camera)
local KEEPER_TRADES = 6 -- seconds after that by which each has hit the other
local REPLICATE = 1 -- seconds a server-set attribute may take to reach this client
local BOSS_STAMP = 0.1 -- seconds a keeper's name may stamp on off its Challenge's Stamp: a frame and the clocks' sync (TR5)
local BOSS_GONE = 0.25 -- seconds its bar may leave off its fall's Gone: the State's replication and a frame
local PACK_STAND = 10 -- studs short of a pack's marker the avatar stands: inside its notice and the lead's leash
local CARD_SLACK = 0.1 -- seconds past reveal.json's Card the reveal's card may come: its frame, and the spawn that builds it
local FPS_FLOOR = 50 -- frames a second the Mythical's reveal holds: the self-test's own warning line
local DROP_BACK = 3 -- seconds a felled pack takes to come back in the drops case: time to leave the street first
local PACK_SETTLE = 10 -- seconds Shades drawn out by an earlier case's walk may take to stand home again
local ANSWER = Helpers.ANSWER
local STREAM_IN = 3 -- seconds a far place may take to stream in to this client once the server asks
-- Where TR10's case watches the elite's square from: Past studs beyond the badge's Near, toward the gate, by the square of
-- Pack, felled for the case (Lantern Row: Pack 3 stands 80 studs short of the elite).
local SQUARE_ELITE = Helpers.SQUARE
local ELITE_STAND = { Past = 10, Pack = SQUARE_ELITE.Before }
local PLATE_TICK = 0.4 -- seconds for the plates and pills to show a change (BaseController and HudController read at 4 Hz)
local SKIP_ALL = Helpers.SKIP_ALL
local DOOR_RUN = 4 -- studs before a Festival Door the avatar starts its walk in
local DOOR_THROUGH = 4 -- seconds from the walk's start to the fade's move: a step in, then the fade's middle
local DOOR_GONE = 40 -- studs from a door that count as set down on its other side

-- The angle in degrees between two directions, flat on the ground.
local function flatAngle(a: Vector3, b: Vector3): number
	local fa, fb = Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, 0, b.Z)
	if fa.Magnitude < 1e-3 or fb.Magnitude < 1e-3 then
		return 180
	end
	return math.deg(math.acos(math.clamp(fa.Unit:Dot(fb.Unit), -1, 1)))
end

local waitFor = Helpers.waitFor -- the shared waits and reads, one home (Helpers)

-- Before a test Shade spawns SHADE_AHEAD studs ahead of the avatar: the camera turned to look the avatar's way, as a
-- player's does. The lead takes on only what's in the camera's view (TR24's fix 2, Combat.Lead.View), and a fresh
-- playtest's camera can face anywhere (a first "Fight:" run's looked 58 degrees off, and the lead stood idle by its Shade
-- for 20 s).
local function lookAhead(t: any)
	local camera = workspace.CurrentCamera
	local root = t.Root()
	local ahead = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if camera and ahead.Magnitude > 1e-3 then
		local back = math.max(8, (camera.CFrame.Position - root.Position).Magnitude)
		camera.CFrame = CFrame.lookAt(root.Position - ahead.Unit * back + Vector3.new(0, 4, 0), root.Position + ahead.Unit * SHADE_AHEAD)
		t.Wait(0.5) -- the view's report reaches the server (ViewController, Net "View")
	end
end

-- A marker this client may not have: the avatar on the test pad is far from the map, so the server streams the place in
-- round it (TestStream) and the case waits for it. The marker, or nil.
local function streamed(t: any, name: string, where: { [string]: any }?): Instance?
	local found = Markers.Find(name, where)
	if found then
		return found
	end
	t.Server("TestStream", name, where)
	waitFor(t, STREAM_IN, function(): boolean
		found = Markers.Find(name, where)
		return found ~= nil
	end)
	return found
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

-- The Lead button for Voidkin `id` on the open Voidkin screen: it's chosen, and its Lead is the one in view (TR17).
local function leadButton(id: string): TextButton?
	if Screen.Current() ~= VoidkinScreen.Name then
		return nil
	end
	VoidkinScreen.Choose(id)
	local limit = os.clock() + 3 -- a body not drawn yet holds the switch until it can stand whole (TR17, fix 1)
	while VoidkinScreen.Chosen() ~= id and os.clock() < limit do
		task.wait()
	end
	local found = VoidkinScreen.Find("Lead")
	return if found and found:IsA("TextButton") then found else nil
end

local readyCount = Helpers.readyCount
local openReadyDown = Helpers.openReadyDown
local breakerPart = Helpers.breakerPart

-- A label's text on the open Breaker screen: the label `label` under the piece `name`, or "".
local function breakerText(name: string, label: string): string
	local piece = breakerPart(name)
	local found = piece and piece:FindFirstChild(label, true)
	return if found and found:IsA("TextLabel") then found.Text else ""
end

-- A shard kind in the bag as the Breaker's screen names it: its place among the bag's kinds, by id.
local function bagItem(def: string): BreakerScreen.Selection?
	local view = ProfileController.Get()
	local ids: { string } = {}
	for id, count in (if view then view.Bag.Shards else {}) do
		if count > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	local index = table.find(ids, def)
	return if index then { Kind = "Bag", Index = index, Def = def } else nil
end

-- The work of a shard the Breaker's screen has chosen, in the save's copy, or nil.
local function chosenWork(item: BreakerScreen.Selection?): Profile.ShardWork?
	local view = ProfileController.Get()
	if view == nil or item == nil then
		return nil
	elseif item.Kind == "Chamber" then
		local chamber = view.Base.Chambers[item.Index]
		return if chamber then chamber.Work else nil
	elseif item.Kind == "Line" then
		return view.Base.Line[item.Index]
	elseif item.Kind == "Ready" then
		return view.Base.Ready[item.Index]
	end
	return nil
end

-- The Breaker screen's infusion button at `level`, and whether it's locked (its reason is the line beside it).
local function infuseButton(level: number): (TextButton?, boolean)
	local found = breakerPart(`Infuse{level}`)
	local button = if found and found:IsA("TextButton") then found else nil
	return button, button ~= nil and tostring(button:GetAttribute("Disabled") or "") ~= ""
end

-- The Standard's break time, tuned by the voltage case (Config.Shards): voltage is never offered on its own 30 seconds.
local BREAK_PATH = "Shards.Grades.Standard.BreakSeconds"
local NAMED_PATH = "Shards.Grades.Named.BreakSeconds" -- and a Named shard's, a Standard's 30 too

-- Rook's reveal at `rarity`, on his body, as the NL_RevealTest bridge's Show plays it: display only, nothing owned.
local function showReveal(rarity: string)
	local rook = Voidkin.ById.rook
	BaseController.Reveal({ Def = rook.Id, Outcome = "New" }, { Rarity = rarity, Name = rook.Name, Model = rook.Model })
end

-- Waits a frame at a time until the reveal's clock reaches `at`: false if it's gone or `seconds` pass first.
local function revealAt(at: number, seconds: number): boolean
	local began = os.clock()
	while os.clock() - began < seconds do
		local shown = BaseController.Revealed()
		if shown == nil then
			return false
		elseif shown.Time >= at then
			return true
		end
		RunService.RenderStepped:Wait()
	end
	return false
end

local lintClean = Helpers.lintClean

-- Walks the avatar into a Festival Door's way from the side it stands on (DOOR_RUN studs out when `close`, else wherever it
-- is), and waits for the fade to move it: true once it's been set down away from the door. With `done`, it waits for that
-- instead (TR45: the base's door opens a menu, the Festival's asks for the trip home).
local function walkThrough(t: any, door: Instance, close: boolean, done: (() -> boolean)?): boolean
	local way = door:FindFirstChild("Way")
	local character = Players.LocalPlayer.Character
	local humanoid = if character then Parts.Humanoid(character) else nil
	if way == nil or not way:IsA("BasePart") or humanoid == nil then
		return false
	end
	local look = Vector3.new(way.CFrame.LookVector.X, 0, way.CFrame.LookVector.Z).Unit
	local floor = way.Position - Vector3.new(0, way.Size.Y / 2 - R6_ROOT_HEIGHT, 0)
	local side = if (t.Root().Position - floor):Dot(look) >= 0 then 1 else -1
	if close then
		t.Root().CFrame = CFrame.lookAt(floor + look * side * DOOR_RUN, floor)
		t.Wait(0.3)
	end
	humanoid:MoveTo(floor - look * side * 2)
	local moved = waitFor(t, DOOR_THROUGH, done or function(): boolean
		local here = t.Root().Position
		return Vector3.new(here.X - floor.X, 0, here.Z - floor.Z).Magnitude > DOOR_GONE
	end)
	humanoid:MoveTo(t.Root().Position)
	return moved
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

-- The highest pixel row any of `parts` reaches on screen (the smallest viewport Y over their boxes' eight corners).
local function topOnScreen(parts: { BasePart }): number
	local camera = workspace.CurrentCamera
	local highest = math.huge
	for _, part in parts do
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					highest = math.min(highest, camera:WorldToViewportPoint(part.CFrame * (part.Size / 2 * Vector3.new(x, y, z))).Y)
				end
			end
		end
	end
	return highest
end

-- A Shade of `def` spawned SHADE_TOUGHER levels over the lead, watched for up to SHADE_WATCH seconds or three swings and
-- three flinches: the clip each swing and each flinch started, in order. Nil when it can't be watched; the Shade is cleared.
local function swingsOf(t: any, def: string): ({ string }?, { string }?)
	local lead = myLead()
	local level = if lead then lead:GetAttribute("Level") else nil
	if type(level) ~= "number" then
		t.Check("the lead is in the world", false)
		return nil, nil
	end
	lookAhead(t)
	local spawned = t.Server("FightSpawn", def, level + SHADE_TOUGHER, SHADE_AHEAD)
	t.Check(`the {def} spawns`, type(spawned) == "table" and spawned.Ok == true)
	if type(spawned) ~= "table" or spawned.Ok ~= true then
		return nil, nil
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
		return nil, nil
	end
	-- A start is a track that wasn't playing a frame ago, or went back.
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
	return swings, flinches
end

local cases = {
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
		Name = "Effects: the player plays B1's exit from its rows, each part on its frame, and leaves nothing",
		Stay = true,
		Run = function(t: any)
			-- AR8, "The method": Config.Effects.Rows.LanternExit through FighterController/Rows, stepped by hand.
			local effect = EffectsConfig.Rows.LanternExit
			local rows = effect.Rows
			local root = t.Character():FindFirstChild("HumanoidRootPart") :: BasePart
			local foot = root.Position + root.CFrame.LookVector * 20 - Vector3.new(0, 3, 0)
			local anchor = CFrame.lookAt(foot, foot + root.CFrame.LookVector)
			t.Wait(2.5)
			local over, drawn = Rows.Warmed()
			local images = 0
			for _ in FxKit.Images do
				images += 1
			end
			t.Check("the warm pass ran and is over", over)
			t.Check("and drew every kit image as a particle, so a picture's first burst in a session draws (AR58)", drawn == images and images > 0, `{drawn} of {images}`)
			local player = Rows.Play("LanternExit", anchor, 1)
			local coil = player.Parts("Coil") :: { any }
			t.Check("one part for each of the coil's bands", #coil == #(rows.Coil.Part :: { string }), tostring(#coil))
			local look = if effect.Grey then rows.Coil.Grey else rows.Coil.Look
			local first = coil[1] :: MeshPart
			local surface = first:FindFirstChildOfClass("SurfaceAppearance")
			t.Check("each band wears the kit's look, its texture its own emissive mask", surface ~= nil
				and surface.ColorMapContent.Uri == FxKit.Images[look :: string].Id
				and surface.EmissiveMaskContent.Uri == FxKit.Images[look :: string].Id, tostring(surface and surface.ColorMapContent.Uri))
			player.Step(-1)
			t.Check("nothing shown before its first key", first.Transparency == 1)
			player.Step(4)
			local scale = Track.Value(rows.Coil.Tracks.Scale, 4) :: Vector3
			local worst = 0
			for _, part in coil do
				local unit = FxKit.Meshes[part.Name]
				worst = math.max(worst, (part.Size - unit.Size * scale).Magnitude)
				local should = (anchor * CFrame.new(unit.Centre * scale)).Position
				worst = math.max(worst, (part.Position - should).Magnitude)
			end
			t.Check("whole on 70: every band at its size and place on the coil", worst < 1e-3, string.format("%.4f", worst))
			t.Check("whole and glowing at its Glow", first.Transparency == 0
				and math.abs((surface :: SurfaceAppearance).EmissiveStrength - Track.Value((rows.Coil.Bands :: any).FxCoil2_Burn1.Glow, 4)) < 1e-6,
				tostring((surface :: SurfaceAppearance).EmissiveStrength))
			local card = player.Parts("Flare")[1]:FindFirstChildWhichIsA("BillboardGui", true) :: BillboardGui
			local label = card:FindFirstChildOfClass("ImageLabel") :: ImageLabel
			t.Check("the flare, white at the tip on 70", label.ImageTransparency == 0 and math.abs(card.Size.X.Scale - 5.5) < 1e-6, tostring(card.Size))
			local tip = (anchor * CFrame.new(Vector3.new(0, 2.2, 0) * scale)).Position
			t.Check("on the coil's tip", (player.Parts("Flare")[1] :: BasePart).Position:FuzzyEq(tip, 1e-3))
			local light = player.Parts("Light")[1]:FindFirstChildOfClass("PointLight") :: PointLight
			t.Check("the light at its brightest on the flare", math.abs(light.Brightness - 4) < 1e-6, tostring(light.Brightness))
			local fronts = player.Parts("Front") :: { any }
			t.Check("five burning fronts", #fronts == 5, tostring(#fronts))
			local frontLook = if effect.Grey then rows.Front.Grey else rows.Front.Look
			local frontSurface = (fronts[1] :: MeshPart):FindFirstChildOfClass("SurfaceAppearance")
			t.Check("in the kit's flame", frontSurface ~= nil and frontSurface.ColorMapContent.Uri == FxKit.Images[frontLook :: string].Id)
			t.Check("none while the coil's whole", fronts[1].Transparency == 1 and fronts[5].Transparency == 1)
			player.Step(9.5)
			t.Check("from 74 the foot burns first, whole while it flares", coil[1].Transparency == 0 and coil[2].Transparency == 0, `{coil[1].Transparency} {coil[2].Transparency}`)
			local unitBand = FxKit.Meshes[coil[1].Name]
			local coilFrame = (coil[1] :: BasePart).CFrame * CFrame.new(-unitBand.Centre * (coil[1].Size / unitBand.Size))
			local unitFront = FxKit.Meshes[fronts[1].Name]
			local frontScale = fronts[1].Size / unitFront.Size
			t.Check("the first front burning, the next unseen", fronts[1].Transparency == 0 and fronts[2].Transparency == 1, `{fronts[1].Transparency} {fronts[2].Transparency}`)
			t.Check("on the coil, turned with it, where its first band meets the second",
				(fronts[1].Position - (coilFrame * CFrame.new(unitFront.Centre * frontScale)).Position).Magnitude < 1e-3
				and (frontScale - coil[1].Size / unitBand.Size).Magnitude < 1e-4)
			t.Check("glowing at its Glow", math.abs((frontSurface :: SurfaceAppearance).EmissiveStrength
				- Track.Value((rows.Front.Bands :: any).FxCoil2_Front1.Glow, 9.5)) < 1e-6)
			local band = (rows.Coil.Bands :: any).FxCoil2_Burn1
			t.Check("flaring hot as it goes", math.abs((surface :: SurfaceAppearance).EmissiveStrength - Track.Value(band.Glow, 9.5)) < 1e-6)
			player.Step(10.5)
			t.Check("cut, never faded: past 76 the foot's gone, the next band whole under its front",
				coil[1].Transparency == 1 and coil[2].Transparency == 0 and fronts[2].Transparency == 0,
				`{coil[1].Transparency} {coil[2].Transparency} {fronts[2].Transparency}`)
			player.Step(9.5)
			local embers = player.Parts("Embers")[1] :: BasePart
			local emitter = embers:FindFirstChildOfClass("ParticleEmitter") :: ParticleEmitter
			t.Check("embers rise off the burning edge", emitter.Rate == 90 and emitter.Texture == FxKit.Images.fx_ember.Id, tostring(emitter.Rate))
			local low = embers.Position.Y
			player.Step(15)
			t.Check("the edge climbs", embers.Position.Y > low + 1, string.format("%.2f to %.2f", low, embers.Position.Y))
			t.Check("the flare cleared a step after its last frame", label.ImageTransparency == 1)
			player.Step(19)
			local gone = true
			for _, part in coil do
				gone = gone and part.Transparency == 1
			end
			for _, part in fronts do
				gone = gone and part.Transparency == 1
			end
			t.Check("gone on 84, the tip last, its fronts with it", gone)
			t.Check("the embers stop", emitter.Rate == 0)
			t.Check("it lives on while its embers do", player.Step(player.End - 1))
			t.Check("and ends", not player.Step(player.End + 1))
			t.Check("leaving nothing", coil[1].Parent == nil and embers.Parent == nil)
		end,
	},
	{
		Name = "Effects: every effect's rows play on a body to their last frame, and leave nothing",
		Stay = true,
		Run = function(t: any)
			-- docs/engineering-plan.md, "Content at scale", item 5: one case for every effect in Config.Effects.Rows, written
			-- in Luau or a rows file, so a new effect is checked the day it lands. Each plays through Rows on a stand-in body
			-- with the points and the looks its rows name, on its action's beats, stepped by hand every half frame, its
			-- streaks and relights on a clock of the case's own: nothing shows before its first frame, each row that makes a
			-- part shows on some frame, it lives to its End and ends a frame past it, and leaves nothing (the rows' folder as it
			-- was, the body's looks put back, a relit one at its Glow). Then once more, ended halfway, as a fight ends one.
			local root = t.Character():FindFirstChild("HumanoidRootPart") :: BasePart
			local foot = root.Position + root.CFrame.LookVector * 20 - Vector3.new(0, 3, 0)
			local anchor = CFrame.lookAt(foot, foot + root.CFrame.LookVector)
			t.Wait(2.5)
			t.Check("the warm pass ran and is over", Rows.Warmed())
			local COLD = 1.2 -- a stand-in look's glow before the effect
			local function rowsLeft(): number
				local folder = workspace:FindFirstChild("NL_Rows")
				return if folder then #folder:GetChildren() else 0
			end
			local function stand(at: CFrame, name: string): MeshPart
				local part = Instance.new("MeshPart") -- a look sits only on a MeshPart
				part.Name = name
				part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
				part.Size = Vector3.one
				part.Transparency = 1
				part.CFrame = at
				return part
			end
			-- What a made part shows, by its row's kind, as Rows shows it: a mesh by its transparency, a card by its image, a
			-- beam by Enabled, a light by its brightness, an emitter by its rate.
			local function showing(kind: string, made: Instance): boolean
				if kind == "Mesh" then
					return (made :: BasePart).Transparency < 1
				elseif kind == "Card" then
					local label = made:FindFirstChildWhichIsA("ImageLabel", true)
					return label ~= nil and label.ImageTransparency < 1
				elseif kind == "Beam" then
					local beam = made:FindFirstChildOfClass("Beam")
					return beam ~= nil and beam.Enabled
				elseif kind == "Light" then
					local light = made:FindFirstChildOfClass("PointLight")
					return light ~= nil and light.Brightness > 0
				elseif kind == "Emitter" then
					local emitter = made:FindFirstChildOfClass("ParticleEmitter")
					return emitter ~= nil and emitter.Rate > 0
				end
				return false
			end
			-- Whether a row shows on a still stand-in: a beam blank in grey never does, nor a trail whose point never moves,
			-- and an emitter of bursts alone has no rate to read.
			local function shows(effect: EffectsConfig.Rows, row: EffectsConfig.Row): boolean
				if row.Kind == "Beam" then
					return not (effect.Grey and row.Grey == "") and row.Trail == nil
				elseif row.Kind == "Emitter" then
					return row.Tracks.Rate ~= nil
				end
				return row.Kind == "Mesh" or row.Kind == "Card" or row.Kind == "Light"
			end
			local names: { string } = {}
			for name in EffectsConfig.Rows do
				table.insert(names, name)
			end
			table.sort(names)
			t.Check("every effect, one by one", #names >= 4, `{#names}`)
			for _, name in names do
				local effect = EffectsConfig.Rows[name]
				local action = if effect.Action then Actions.ById[effect.Action] else nil
				local marks: { [string]: number } = {}
				for beat, at in (if action then action.Beats else {}) :: { [string]: number } do
					marks[beat] = math.floor(at / FRAME + 0.5)
				end
				-- The stand-in: a part with a look for each its rows light, an attachment for each place they ride.
				local body = Instance.new("Model")
				body.Name = "NL_TestBody"
				local trunk = stand(anchor * CFrame.new(0, 3, -2), "NL_TestTrunk")
				trunk.Parent = body
				local looks: { [SurfaceAppearance]: number } = {} -- each look, and where it's left
				for _, row in effect.Rows do
					local lit = if row.Part and (row.Kind == "Glow" or row.Kind == "Relight") then row.Part[1] else nil
					local part = if lit then body:FindFirstChild(lit) else nil
					if lit and part == nil then
						local made = stand(anchor * CFrame.new(1.5, 5, -2), lit)
						local look = Instance.new("SurfaceAppearance")
						look.EmissiveStrength = COLD
						look.Parent = made
						made.Parent = body
						looks[look] = COLD
						part = made
					end
					local relit = row.Relight
					if row.Kind == "Relight" and relit and part then
						looks[part:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance] = relit.Glow
					end
				end
				for _, row in effect.Rows do
					local point = row.Body
					if point and body:FindFirstChild(point, true) == nil then
						local attachment = Instance.new("Attachment")
						attachment.Name = point
						attachment.Position = Vector3.new(0.5, 1, -0.5)
						attachment.Parent = trunk
					end
				end
				local aim = stand(anchor * CFrame.new(0, 3, -12), "NL_TestTarget")
				aim.Parent = workspace
				body.Parent = workspace
				local runs: { { Step: (number) -> boolean, Done: () -> () } } = {}
				local options: Rows.Options = {
					Body = body,
					Marks = marks,
					Target = function(): BasePart?
						return aim
					end,
					Hits = if action then action.Hits else nil,
					Cooldown = if action then action.Cooldown else nil,
					Run = function(step: (number) -> boolean, done: () -> ())
						table.insert(runs, { Step = step, Done = done })
					end,
				}
				-- A streak's or a relight's own clock, run out at once: each to its end, then let go.
				local function runOut(): boolean
					local whole = true
					for _, run in runs do
						local age, alive = 0, true
						while alive and age < 120 do
							age += FRAME
							local ok, more = pcall(run.Step, age)
							alive = ok and more
						end
						whole = whole and not alive
						run.Done()
					end
					table.clear(runs)
					return whole
				end
				local function stayed(player: any): string
					local left: { string } = {}
					for rowName in effect.Rows do
						for _, made in player.Parts(rowName) do
							if made.Parent ~= nil then
								table.insert(left, rowName)
								break
							end
						end
					end
					return table.concat(left, ", ")
				end
				local function looksOff(): string
					local off: { string } = {}
					for look, want in looks do
						if math.abs(look.EmissiveStrength - want) > 1e-6 then
							table.insert(off, string.format("%s at %.2f, not %.2f", (look.Parent :: Instance).Name, look.EmissiveStrength, want))
						end
					end
					return table.concat(off, ", ")
				end
				local before = rowsLeft()
				local ok, played = pcall(Rows.Play, name, anchor, 1, options)
				t.Check(`{name}: plays on its body and its beats`, ok, if ok then nil else tostring(played))
				if ok then
					local player = played :: any
					player.Step(-1)
					local early: { string } = {}
					for rowName, row in effect.Rows do
						for _, made in player.Parts(rowName) do
							if showing(row.Kind, made) then
								table.insert(early, rowName)
								break
							end
						end
					end
					t.Check(`{name}: nothing shown before its first frame`, #early == 0, table.concat(early, ", "))
					local seen: { [string]: boolean } = {}
					local alive, frames = true, 0
					while alive and frames <= player.End do
						alive = player.Step(frames)
						for rowName, row in effect.Rows do
							if not seen[rowName] then
								for _, made in player.Parts(rowName) do
									if showing(row.Kind, made) then
										seen[rowName] = true
										break
									end
								end
							end
						end
						frames += 0.5
					end
					t.Check(`{name}: lives to its End`, alive, string.format("ended on %.1f of %.1f", frames - 0.5, player.End))
					local never: { string } = {}
					for rowName, row in effect.Rows do
						if shows(effect, row) and not seen[rowName] then
							table.insert(never, rowName)
						end
					end
					table.sort(never)
					t.Check(`{name}: each row that makes a part shows on a frame of it`, #never == 0, table.concat(never, ", "))
					t.Check(`{name}: and ends a frame past it`, not player.Step(player.End + 1))
					t.Check(`{name}: its streaks and relights run out`, runOut())
					local left = stayed(player)
					t.Check(`{name}: leaving nothing`, left == "" and rowsLeft() == before, `{left} ({rowsLeft()} parts, {before} before)`)
					t.Check(`{name}: the body's looks as they were, a relit one at its Glow`, looksOff() == "", looksOff())
					-- ended halfway: all of it at once
					local again = Rows.Play(name, anchor, 1, options)
					local half = math.floor(again.End / 2)
					for frame = 0, half do
						again.Step(frame)
					end
					again.Destroy()
					runOut()
					local leftHalf = stayed(again)
					t.Check(`{name}: ended halfway, nothing left`, leftHalf == "" and rowsLeft() == before, `{leftHalf} ({rowsLeft()} parts, {before} before)`)
					t.Check(`{name}: and its looks put back`, looksOff() == "", looksOff())
				end
				body:Destroy()
				aim:Destroy()
			end
		end,
	},
	{
		Name = "Effects: the keeper's signature plays its rows on its beats, on a body, and leaves the body as it was",
		Stay = true,
		Run = function(t: any)
			-- AR8, "The keeper's signature in the engine": Config.Effects.Rows.KeeperSignature through Rows, stepped by hand
			-- on a stand-in body: its lantern part, its look and its "Lantern" point, as the keeper's rig has them.
			local action = Actions.ById.KeeperSignature
			local marks: { [string]: number } = {}
			for beat, at in action.Beats do
				marks[beat] = math.floor(at * 60 + 0.5)
			end
			local root = t.Character():FindFirstChild("HumanoidRootPart") :: BasePart
			local foot = root.Position + root.CFrame.LookVector * 20 - Vector3.new(0, 3, 0)
			local anchor = CFrame.lookAt(foot, foot + root.CFrame.LookVector)
			local body = Instance.new("Model")
			body.Name = "NL_TestKeeper"
			local lantern = Instance.new("MeshPart") -- a look sits only on a MeshPart
			lantern.Name = "Lamplighter_Lantern"
			lantern.Anchored, lantern.CanCollide, lantern.CanQuery = true, false, false
			lantern.Size = Vector3.new(3, 3.45, 3)
			lantern.Transparency = 1
			local held = anchor * CFrame.new(1.5, 11, -3) -- leant out over the fighter through the hold
			lantern.CFrame = held
			local look = Instance.new("SurfaceAppearance")
			look.EmissiveStrength = 1.2
			look.Parent = lantern
			local point = Instance.new("Attachment")
			point.Name = "Lantern"
			point.Parent = lantern
			lantern.Parent = body
			body.Parent = workspace
			local player = Rows.Play("KeeperSignature", anchor, 1, { Body = body, Marks = marks })
			local function beam(row: string): Beam
				return player.Parts(row)[1]:FindFirstChildOfClass("Beam") :: Beam
			end
			local function light(row: string): PointLight
				return player.Parts(row)[1]:FindFirstChildOfClass("PointLight") :: PointLight
			end
			local shell = player.Parts("Shell")[1] :: MeshPart

			player.Step(40)
			t.Near("before the Light: the paper as it was", look.EmissiveStrength, 1.2, 1e-6)
			t.Check("no shell, no light", shell.Transparency == 1 and light("HoldLight").Brightness == 0)
			player.Step(96)
			t.Near("the light gathered in the paper at the look, 96", look.EmissiveStrength, 2.2, 1e-6)
			t.Check("the shell round the drum's middle", shell.Position:FuzzyEq(point.WorldPosition, 1e-3), tostring(shell.Position - point.WorldPosition))
			t.Check("at its size there", (shell.Size - FxKit.Meshes.FxShell.Size * Vector3.new(1.9, 2.25, 1.9)).Magnitude < 1e-3, tostring(shell.Size))
			t.Near("see-through", shell.Transparency, 0.45, 1e-6)
			t.Check("the hold's light at the lantern", (player.Parts("HoldLight")[1] :: BasePart).Position:FuzzyEq(point.WorldPosition, 1e-3))
			t.Near("building", light("HoldLight").Brightness, 2.4, 1e-6)
			lantern.CFrame = held * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, 0.3)
			player.Step(97)
			t.Check("the shell rides the lantern as it moves", shell.Position:FuzzyEq(point.WorldPosition, 1e-3))
			player.Step(104)
			t.Check("the shell and the light gone by 104 (condition a)", shell.Transparency == 1 and light("HoldLight").Brightness == 0)
			player.Step(106)
			t.Near("the paper at its top on the Wrench", look.EmissiveStrength, 3, 1e-6)
			-- The fall: the lantern driven down to the street beside the fighter.
			local landing = anchor * CFrame.new(-1.92, 1.9, -6.33)
			local fallFrom = lantern.Position
			for frame = 107, 118 do
				local u = (frame - 106) / 12
				lantern.CFrame = CFrame.new(fallFrom:Lerp(landing.Position, u * u))
				player.Step(frame)
				if frame == 113 then
					local streak = beam("Streak")
					local ends = player.Parts("Streak")[1]:GetChildren()
					t.Check("the streak trails the fall on 113", streak.Enabled and math.abs(streak.Width0 - 3.3) < 1e-6)
					local low = (streak.Attachment0 :: Attachment).WorldPosition
					local high = (streak.Attachment1 :: Attachment).WorldPosition
					t.Check("from the drum's trailing edge, behind it", (low - point.WorldPosition).Magnitude > 1.49 and high.Y > low.Y, `{#ends} {low} {high}`)
				end
				if frame == 117 then
					t.Check("the streak gone before 117 (condition b)", not beam("Streak").Enabled)
				end
			end
			local spot = Vector3.new(point.WorldPosition.X, anchor.Y, point.WorldPosition.Z)
			local shaft = beam("Shaft")
			t.Check("the column on the Slam", shaft.Enabled and math.abs(shaft.Width0 - 6.9) < 1e-6, tostring(shaft.Width0))
			t.Check("its foot on the street under the drum", (shaft.Attachment0 :: Attachment).WorldPosition:FuzzyEq(spot, 1e-3), tostring((shaft.Attachment0 :: Attachment).WorldPosition - spot))
			-- research's verdict on the grey (2026-11-13): it leaps from the street, widest at the foot
			t.Check("its top 2 up as it leaps", (shaft.Attachment1 :: Attachment).WorldPosition:FuzzyEq(spot + Vector3.new(0, 2, 0), 1e-3))
			t.Check("the tip over it", (beam("Tip").Attachment0 :: Attachment).WorldPosition:FuzzyEq(spot + Vector3.new(0, 2, 0), 1e-3) and beam("Tip").Enabled)
			t.Check("half as wide at its top", math.abs(shaft.Width1 - 6.9 * 0.5) < 1e-6, tostring(shaft.Width1))
			t.Check("the tip as wide as the shaft's top", math.abs(beam("Tip").Width0 - shaft.Width1) < 1e-6, tostring(beam("Tip").Width0))
			t.Check("the halo only out of grey", beam("Halo").Enabled == not EffectsConfig.Rows.KeeperSignature.Grey)
			t.Check("the street lit 4 up, at its brightest", (player.Parts("SlamLight")[1] :: BasePart).Position:FuzzyEq(spot + Vector3.new(0, 4, 0), 1e-3) and light("SlamLight").Brightness == 5)
			player.Step(123)
			t.Check("at its full height by 123", (shaft.Attachment1 :: Attachment).WorldPosition:FuzzyEq(spot + Vector3.new(0, 13.5, 0), 1e-3))
			lantern.CFrame = held -- lifted again: the column stays where it fell
			player.Step(124)
			local stood = (shaft.Attachment0 :: Attachment).WorldPosition
			t.Check("the column stays where the lantern fell", Vector3.new(stood.X, 0, stood.Z):FuzzyEq(Vector3.new(spot.X, 0, spot.Z), 1e-3))
			t.Check("the paper dim after the Slam", look.EmissiveStrength < 1.2, string.format("%.2f", look.EmissiveStrength))
			t.Check("its foot letting go on 124", (shaft.Attachment0 :: Attachment).WorldPosition.Y > anchor.Y)
			local shown, chips = 0, 0
			for index = 1, 9 do
				local chip = player.Parts(`Chip{index}`)[1] :: MeshPart
				chips += 1
				if chip.Transparency == 0 and chip.Material == Enum.Material.Neon then
					shown += 1
				end
			end
			t.Check("nine chips flung off its edge, Neon", shown == 9 and chips == 9, tostring(shown))
			player.Step(141)
			t.Check("the street clear by 141 (condition 4)", not shaft.Enabled and light("SlamLight").Brightness == 0 and (player.Parts("Chip1")[1] :: MeshPart).Size.Magnitude < 0.01)
			t.Check("it lives on while the paper relights", player.Step(player.End - 1))
			t.Check("and ends", not player.Step(player.End + 1))
			t.Near("the paper as it was", look.EmissiveStrength, 1.2, 1e-6)
			t.Check("leaving nothing", shell.Parent == nil and player.Parts("Shaft")[1].Parent == nil)
			-- Let go after the Slam (its keeper fell): the body's glow back at once, the column plays on.
			local again = Rows.Play("KeeperSignature", anchor, 1, { Body = body, Marks = marks })
			lantern.CFrame = landing
			again.Step(110)
			again.Step(120)
			again.Let()
			t.Near("let go: the paper back at once", look.EmissiveStrength, 1.2, 1e-6)
			again.Step(121)
			local column = again.Parts("Shaft")[1]:FindFirstChildOfClass("Beam") :: Beam
			t.Check("the column plays on", column.Enabled)
			again.Destroy()
			t.Check("and ends with nothing left", column.Parent == nil)
			-- As a fight plays it (Action.Effect, through Effects.Play): the camera never moves (the director, 2026-11-14:
			-- only the hit's shake does), even aimed at the player's own lead; ended in the hold it all goes at once, the paper
			-- put back; ended after the Slam, the column plays out, then nothing is left.
			t.Check("its effect is its rows", action.Effect == "KeeperSignature", tostring(action.Effect))
			local lead = Instance.new("Model")
			lead:SetAttribute("Owner", Players.LocalPlayer.UserId)
			local chest = Instance.new("Part")
			chest.Anchored, chest.CanCollide, chest.CanQuery, chest.Transparency = true, false, false, 1
			chest.CFrame = anchor * CFrame.new(0, 3, -7.5)
			chest.Parent = lead
			lead.Parent = workspace
			local camera = workspace.CurrentCamera
			local function rowsLeft(): number
				local folder = workspace:FindFirstChild("NL_Rows")
				return if folder then #folder:GetChildren() else 0
			end
			local left = rowsLeft()
			lantern.CFrame = held
			local looked = camera.CFrame.LookVector
			local inHold = Effects.Play(action.Beats, body, function(): BasePart?
				return chest
			end, action)
			inHold.Step(action.Beats.Light + 0.6)
			RunService.RenderStepped:Wait()
			RunService.RenderStepped:Wait()
			t.Check("the camera never turned in the hold", camera.CFrame.LookVector:FuzzyEq(looked, 1e-3))
			t.Check("the paper lit in the hold", look.EmissiveStrength > 1.2 + 1e-3, string.format("%.2f", look.EmissiveStrength))
			inHold.Destroy()
			t.Near("ended in the hold: the paper put back at once", look.EmissiveStrength, 1.2, 1e-6)
			t.Check("and nothing left", rowsLeft() == left, `{rowsLeft()} {left}`)
			lantern.CFrame = landing
			local afterSlam = Effects.Play(action.Beats, body, function(): BasePart?
				return chest
			end, action)
			afterSlam.Step(action.Beats.Slam + 0.05)
			afterSlam.Destroy()
			t.Near("ended after the Slam: the paper back at once", look.EmissiveStrength, 1.2, 1e-6)
			t.Check("the column plays on", rowsLeft() > left, `{rowsLeft()} {left}`)
			t.Wait(4)
			t.Check("then nothing is left", rowsLeft() == left, `{rowsLeft()} {left}`)
			body:Destroy()
			lead:Destroy()
		end,
	},
	{
		Name = "Camera: a turn put on the player's camera stays, on a phone's following camera too",
		Stay = true,
		Run = function(t: any)
			-- CameraTurn: a phone's camera follows, and undoes on the next frame a turn it didn't make itself (measured
			-- 2026-11-13); the fade's swing behind the avatar and the replay's turn go through CameraTurn so it stays. A
			-- mouse's camera keeps it either way. Run on the phone emulation to test the following camera.
			local camera = workspace.CurrentCamera
			local focus = camera.Focus.Position
			local turned = CFrame.new(focus) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(-focus) * camera.CFrame
			CameraTurn.To(turned)
			for _ = 1, 10 do
				RunService.RenderStepped:Wait()
			end
			t.Near("turned a quarter round, ten frames on (degrees off)", flatAngle(camera.CFrame.LookVector, turned.LookVector), 0, 2)
			t.Check("and the camera the player's again", camera.CameraType == Enum.CameraType.Custom)
			local back = CFrame.new(camera.Focus.Position) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(-camera.Focus.Position)
			CameraTurn.To(back * camera.CFrame)
			for _ = 1, 3 do
				RunService.RenderStepped:Wait()
			end
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
		Name = "World: a plot no one owns is a bare lot, and each player's base stands on theirs (the director, 2026-11-15)",
		Place = "Main", -- TR45: its world stands in that place only
		Stay = true,
		Run = function(t: any)
			local owned: { [number]: boolean } = {}
			for _, other in Players:GetPlayers() do
				local number = other:GetAttribute("Plot")
				if type(number) == "number" then
					owned[number] = true
				end
			end
			local mine = Players.LocalPlayer:GetAttribute("Plot")
			t.Check("this player owns a plot", type(mine) == "number" and owned[mine] == true, tostring(mine))
			local wrong: { string } = {}
			for number = 1, WorldConfig.Plots.Count do
				local floor = Markers.Find("Plot", { Plot = number })
				local lot = if floor then floor.Parent else nil
				if lot == nil then
					continue -- not streamed in here
				end
				local base = lot:FindFirstChild("Base")
				if owned[number] and (base == nil or base:FindFirstChild("Breaker") == nil or base:FindFirstChild("Spawn") == nil) then
					table.insert(wrong, `plot {number} is owned and has no base`)
				elseif not owned[number] and base ~= nil then
					table.insert(wrong, `plot {number} is no one's and its base stands`)
				end
			end
			t.Check("every plot as its owner has it", #wrong == 0, table.concat(wrong, "; "))
		end,
	},
	{
		Name = "World: TR8, Lantern Row wears its kit whole, the plan's lights with it, the grey look under it hidden",
		Place = "Festival", -- TR45: its world stands in that place only
		Stay = true,
		Run = function(t: any)
			-- "Street": the plots left out while their size isn't the base plan's (the base's own cases read them)
			local problems = t.Server("DressReport", "Street")
			local first = if type(problems) == "table" then problems[1] else nil
			t.Check("the dressing report is empty", type(problems) == "table" and #problems == 0, if first then `{first} (and {#problems - 1} more)` else nil)
			-- The paper as this client shows it (research's TR8 verdict): each box streamed in stands in Config.Lighting.Paper's
			-- band over the paving, in its tint (its rate is the logic case's).
			streamed(t, "Elite", { Stage = SQUARE_ELITE.Stage })
			local band = LightingConfig.Paper
			local seen, off = 0, {}
			for _, item in CollectionService:GetTagged(Kit.Tag) do
				local floorY = item:GetAttribute("FloorY")
				if type(item:GetAttribute("Paper")) ~= "number" or type(floorY) ~= "number" or not item:IsA("BasePart") then
					continue
				end
				seen += 1
				local emitter = item:FindFirstChildOfClass("ParticleEmitter")
				local bottom, top = item.Position.Y - item.Size.Y / 2 - floorY, item.Position.Y + item.Size.Y / 2 - floorY
				if math.abs(bottom - band.Floor) > 0.01 or math.abs(top - band.Top) > 0.01 then
					table.insert(off, `{item.Name} from {string.format("%.2f", bottom)} to {string.format("%.2f", top)}`)
				elseif emitter == nil or emitter.Color.Keypoints[1].Value ~= band.Colour then
					table.insert(off, `{item.Name}: not the paper's tint`)
				end
			end
			t.Check("the paper's boxes in the band over the camera, in the paper's tint", seen > 0 and #off == 0, off[1] or `{seen} boxes streamed in`)
			local home = streamed(t, "GroundDoor", { Ground = WorldConfig.Row.Ground })
			local way = home and home:FindFirstChild("Way")
			t.Check("the door home's way lit by the street, not Neon", way ~= nil and way:IsA("BasePart")
				and way.Material == (Enum.Material :: any)[WorldConfig.Grey.Door.HomeWay], if way and way:IsA("BasePart") then tostring(way.Material) else "none")
		end,
	},
	{
		Name = "Lighting: TR8, the ground's sun stands where the kit's frames have it, at a day clock",
		Stay = true,
		Run = function(t: any)
			local sun = LightingController.Sun()
			t.Check("within 2 degrees of the frames' sun", sun.Off <= 2, string.format("%.2f degrees off", sun.Off))
			t.Check("at a day clock (the handbook's pseudo-night)", sun.Clock >= 6 and sun.Clock <= 18, tostring(sun.Clock))
		end,
	},
	{
		Name = "Lighting: TR8, TR23, north of the festival gate the ground's day, dusk or night holds, outside it the place's own unless the base is under it too (AR14), in the clear with no mist (the director's 16:50); by day the glow and the lights dim; a walk eases in, a jump lands",
		Place = "Festival", -- TR45: its world stands in that place only
		Run = function(t: any)
			local world = workspace:FindFirstChild("World")
			local gateZ = if world then world:GetAttribute("GateZ") else nil
			t.Check("the world says where its gate stands", type(gateZ) == "number")
			if type(gateZ) ~= "number" then
				return
			end
			local from = LightingConfig.From
			local up = Vector3.new(0, 3.6, 0) -- an R6 root over the paving
			local function stand(z: number)
				t.Server("TestStandAt", Vector3.new(0, 0, z) + up, Vector3.new(0, 0, z - 10) + up)
			end
			local function near(a: Color3, b: Color3): boolean
				return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 3e-3
			end
			local Atmosphere = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
			local Bloom = game:GetService("Lighting"):FindFirstChildOfClass("BloomEffect")
			local function holds(name: string)
				local phase = (LightingConfig.Phases :: any)[name]
				local look = LightingController.Look()
				local lighting = game:GetService("Lighting")
				t.Check(`{name}: all the way in`, look.Area == 1, tostring(look.Area))
				t.Equal(`{name}: the turn's phase`, look.Phase, name)
				t.Check(`{name}: its sky`, lighting:FindFirstChild(`LanternRow{name}`) ~= nil)
				local skies = 0
				for _, child in lighting:GetChildren() do
					skies += if child:IsA("Sky") then 1 else 0
				end
				t.Equal(`{name}: one sky`, skies, 1)
				t.Check(`{name}: its fill`, near(lighting.Ambient, phase.Ambient) and near(lighting.OutdoorAmbient, phase.Ambient), tostring(lighting.Ambient))
				t.Near(`{name}: its brightness`, lighting.Brightness, phase.Brightness, 1e-3)
				t.Check(`{name}: its sun's colour`, near(lighting.ColorShift_Top, phase.Sun))
				t.Near(`{name}: its haze, no veil`, Atmosphere and Atmosphere.Density or -1, phase.Atmosphere.Density, 1e-3)
				t.Near(`{name}: its bloom`, Bloom and Bloom.Intensity or -1, phase.Bloom.Intensity, 1e-3)
			end
			-- The base under the ground's sky (AR14): out on the plots it holds as inside. Then the switch off, for the split.
			t.Server("Night", "Night")
			stand(gateZ + from + 40)
			t.Wait(0.3)
			local everywhere = LightingConfig.Everywhere
			if everywhere then
				t.Check("the base: under the ground's look", LightingController.Look().Area == 1, tostring(LightingController.Look().Area))
				-- and in the clear: no mist over the base in any phase (the director's 16:50), its veil's haze only at a swap
				local clear = LightingConfig.Clear.Atmosphere
				t.Check("the base: out of the Row's haze", LightingController.Look().Row == 0, tostring(LightingController.Look().Row))
				t.Near("the base: no mist, its density", Atmosphere and Atmosphere.Density or -1, clear.Density, 1e-3)
				t.Near("the base: no haze", Atmosphere and Atmosphere.Haze or -1, clear.Haze, 1e-3)
				-- and in bright hours (AR20's C): the night's fill, light and exposure there, not the Row's
				local bright = LightingConfig.Clear.Phases.Night
				local lighting = game:GetService("Lighting")
				t.Check("the base: C's night fill", near(lighting.Ambient, bright.Ambient) and near(lighting.OutdoorAmbient, bright.Ambient), tostring(lighting.Ambient))
				t.Near("the base: C's night light", lighting.Brightness, bright.Brightness, 1e-3)
				t.Near("the base: C's night exposure", lighting.ExposureCompensation, bright.Exposure, 1e-3)
				t.Near("the base: the glow lifted", LightingController.Look().Glow, ((LightingConfig.Phases :: any).Night.Glow or 1) * LightingConfig.Clear.Glow, 0.02)
				t.Server("Tune", "Lighting.Everywhere", false)
				stand(gateZ + from + 120) -- a jump, so it lands
				t.Wait(0.3)
			end
			-- Outside: the place's own.
			t.Check("outside: none of the ground's look", LightingController.Look().Area == 0)
			t.Check("outside: the place's own sky", game:GetService("Lighting"):FindFirstChild("LanternRowNight") == nil
				and game:GetService("Lighting"):FindFirstChild("LanternRowDusk") == nil)
			local function leadLit(): boolean?
				local light = LightingController.LeadLight()
				return if light then light.Enabled and light.Brightness > 0 else nil
			end
			t.Check("outside: the lead's light off", leadLit() ~= true)
			-- A jump in lands in the night at once: halfway between the first two packs, past the lead's Leash of either, so
			-- no fight starts (one drew Pack 1's Shades out, and the packs case read them walking home).
			local packZ: { number } = {}
			for _, row in t.Server("Packs") do
				if row.Name == "Pack 1" or row.Name == "Pack 2" then
					table.insert(packZ, row.At.Z)
				end
			end
			stand(if #packZ == 2 then (packZ[1] + packZ[2]) / 2 else gateZ - 60)
			t.Wait(0.3)
			holds("Night")
			t.Check("inside: the lead carries its light", leadLit() == true)
			-- The turn jumped to dusk.
			t.Server("Night", "Dusk")
			t.Wait(0.3)
			holds("Dusk")
			-- The pieces round the avatar glow by Config, at the phase's share, and a tune shows at once.
			local function glows(name: string): (number, { string })
				local count, off = 0, {}
				local share = LightingController.Look().Glow
				for _, item in CollectionService:GetTagged(Kit.Tag) do
					local piece = item:GetAttribute("Piece")
					local surface = item:FindFirstChildOfClass("SurfaceAppearance")
					if type(piece) ~= "string" or surface == nil then
						continue
					end
					count += 1
					local want = if Kit.Floors[piece] then (LightingConfig.Phases :: any)[name].Floor
						elseif LightingConfig.Cores[piece] then math.min(LightingConfig.Glow.Kit * share, LightingController.Look().CoreMost) / share
						elseif LightingConfig.Houses[piece] then LightingConfig.Glow.Houses
						else LightingConfig.Glow.Kit
					local lit = item:GetAttribute("Lit")
					if item:GetAttribute("Working") == false then -- an empty chamber, low (AR15)
						want *= LightingConfig.Glow.Empty
					elseif type(lit) == "number" then -- a battery cell, by its share of the charge (AR15, section 4)
						want *= LightingConfig.Glow.Empty + (1 - LightingConfig.Glow.Empty) * math.clamp(lit, 0, 1)
					end
					-- A steady piece (Config.Lighting.Steady; AR17's crossing shard) keeps its own glow at the phase's share alone.
					local steady = LightingConfig.Steady[piece]
					want = if steady then steady * LightingController.Look().Steady else want * share
					if math.abs(surface.EmissiveStrength - want) > 1e-3 then
						table.insert(off, string.format("%s at %.2f, not %.2f", piece, surface.EmissiveStrength, want))
					end
				end
				return count, off
			end
			t.Equal("dusk: the glow whole", LightingController.Look().Glow, 1)
			local count, off = glows("Dusk")
			t.Check("pieces streamed in round the avatar", count > 0, tostring(count))
			t.Check("each at its glow", #off == 0, off[1])
			local before = LightingConfig.Glow.Kit
			t.Server("Tune", "Lighting.Glow.Kit", before + 1)
			t.Wait(0.3)
			count, off = glows("Dusk")
			t.Check("a tuned glow shows at once", count > 0 and #off == 0, off[1])
			t.Server("Tune", "Lighting.Glow.Kit", before)
			t.Wait(0.3)
			-- The turn jumped to day (TR23): its own look and sky, the glow and the lights at their shares.
			t.Server("Night", "Day")
			t.Wait(0.3)
			holds("Day")
			local day = (LightingConfig.Phases :: any).Day
			local now = LightingController.Look()
			t.Near("day: the glow at its share", now.Glow, day.Glow or 1, 0.011)
			t.Near("day: the lights at their share", now.Lights, day.Lights or 1, 0.011)
			count, off = glows("Day")
			t.Check("day: each piece at its share of its glow", count > 0 and #off == 0, off[1])
			local light = LightingController.LeadLight()
			t.Near("day: the lead's light at its share", if light then light.Brightness else -1, LightingConfig.Lead.Brightness * now.Lights, 1e-3)
			-- A walk out eases: half way through Enter, between the two looks; after it, out.
			stand(gateZ + from - 8)
			t.Wait(0.3)
			stand(gateZ + from + 8) -- 16 studs: a walk, not a jump
			t.Wait(LightingConfig.Enter / 2)
			local mid = LightingController.Look().Area
			t.Check("half way out, between the looks", mid > 0 and mid < 1, tostring(mid))
			t.Wait(LightingConfig.Enter / 2 + 0.3)
			t.Check("and out", LightingController.Look().Area == 0, tostring(LightingController.Look().Area))
			if everywhere then
				t.Server("Tune", "Lighting.Everywhere", everywhere)
				t.Wait(0.3)
			end
		end,
	},
	{
		Name = "World: the player arrives on their own plot, facing the Breaker",
		Place = "Main", -- TR45: its world stands in that place only
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
		Place = "Festival", -- TR45: its world stands in that place only
		Stay = true,
		Run = function(t: any)
			-- Shades an earlier case's walk drew out walk home first.
			local rows: { any } = {}
			waitFor(t, PACK_SETTLE, function(): boolean
				rows = t.Server("Packs")
				for _, row in rows do
					if row.Standing ~= row.Count or (row.Count > 1 and math.abs(row.Gap - WorldConfig.Row.Spread) > 0.5) then
						return false
					end
				end
				return true
			end)
			local byName: { [string]: any } = {}
			for _, row in rows do
				byName[row.Name] = row
			end
			local packs, elites = 0, 0
			for _, stop in WorldConfig.Row.Stops do
				packs += if stop.Kind == "Pack" then 1 else 0
				elites += if stop.Kind == "Elite" then 1 else 0
			end
			local found, foundElites = 0, 0
			for name, row in byName do
				found += if string.sub(name, 1, 5) == "Pack " then 1 else 0
				foundElites += if string.sub(name, 1, 6) == "Elite " and row.Stage ~= nil then 1 else 0
			end
			t.Check("a pack at each pack stop", found == packs, `{found} packs for {packs} stops`)
			t.Check("an elite at each elite stop, each its stage's (TR43)", foundElites == elites, `{foundElites} elites for {elites} stops`)
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
		Place = "Festival", -- TR45: its world stands in that place only
		Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
		Run = function(t: any)
			local keeper = Combat.Keeper
			local moved = keeper.Fade.Out + keeper.Fade.Hold / 2 + MOVE_SLACK
			local def = nil
			for _, stop in WorldConfig.Row.Stops do
				def = if stop.Kind == "Keeper" then stop.Def else def
			end
			t.Server("KeeperRest", 0) -- TR10: a win earlier in the run rests the keeper five minutes; this case tries it now.
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
			t.Near("the avatar faces past the ring's middle, so its own body hides none of the keeper (degrees)", inside.OffCentre, Combat.Keeper.Turn, 2)
			-- research's verdict on AR7's install, fix 1: the lead on its left, clear of the Challenge and the fall's line
			t.Near("its lead set down on its left (studs right of it)", inside.LeadSide, Combat.Keeper.Side, 0.3)
			-- The fight is joined with nobody pressing anything: the keeper comes for the lead from the middle of the ring, and the
			-- lead meets it once it's inside Lead.Leash of the avatar.
			t.Check("the keeper comes for the lead at once", inside.KeeperTarget ~= "" and inside.KeeperTarget == inside.Lead, `target {inside.KeeperTarget}, lead {inside.Lead}`)
			-- Research's call on fix 4, option A: on screen the lead stays on its own side of the keeper from its walk-in to its
			-- place beside it, never crossing the camera's line to it (Combat.Lead.Near). Pixels past the keeper's middle, worst.
			local keeperAt = fighterModel(inside.Keeper) -- where it stood as the try began: the ring's middle
			local keeperSide = if keeperAt then (keeperAt:GetPivot().Position - t.Root().Position):Dot(t.Root().CFrame.RightVector) else 0
			local sideOf = if keeperSide > 0 then -1 else 1 -- the lead's side of the line: away from where the Turn puts the keeper
			local crossed, frames = -math.huge, 0
			-- The line from the player's camera at Roblox's default zoom behind the avatar (the takes' camera) to the keeper, in
			-- the ground's plane: the self-test's own camera isn't the game's, so the line is drawn from where it would stand.
			local watchCross = RunService.Heartbeat:Connect(function()
				local them, ours, root = fighterModel(inside.Keeper), myLead(), t.Root()
				if them and ours and root then
					local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
					local eye = root.Position - look * CAMERA_BACK
					local toKeeper = them:GetPivot().Position - eye
					local along = Vector3.new(toKeeper.X, 0, toKeeper.Z).Unit
					local toLead = ours:GetPivot().Position - eye
					frames += 1
					crossed = math.max(crossed, Vector3.new(toLead.X, 0, toLead.Z):Dot(along:Cross(Vector3.yAxis)) * -sideOf)
				end
			end)
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
			-- Against a keeper the lead takes its side, so both read side by side from the avatar's place (Combat.Lead.Beside).
			local beside = (Combat.Lead.Beside :: { [string]: number }).Keeper
			local off = 180
			t.Check("the lead stands at the keeper's side", waitFor(t, KEEPER_BESIDE, function(): boolean
				local them, ours = fighterModel(joined.Keeper), myLead()
				if them and ours then
					off = flatAngle(ours:GetPivot().Position - them:GetPivot().Position, t.Root().CFrame.LookVector)
				end
				return math.abs(off - beside) <= BESIDE_TOLERANCE
			end), `{math.floor(off + 0.5)} degrees off the avatar's facing, want {beside} ±{BESIDE_TOLERANCE}`)
			watchCross:Disconnect()
			t.Check("the lead never crosses the camera's line to the keeper", frames > 30 and crossed < 0, string.format("%.1f studs past it at worst, in %d frames", crossed, frames))
			do
				-- the side toward the avatar's line of sight, as the keeper stood when the try began
				local them, ours = fighterModel(joined.Keeper), myLead()
				local leadSide = if them and ours then (ours:GetPivot().Position - them:GetPivot().Position):Dot(t.Root().CFrame.RightVector) else 0
				t.Check("it stands on the keeper's near side", keeperSide * leadSide < 0, string.format("the keeper began %.1f studs right of the avatar; the lead stands %.1f right of it", keeperSide, leadSide))
			end
			-- Research's call on fix 4, option B (Config.Hud.SeeThrough): the camera held so the keeper's hat stands under a piece
			-- of the top band, then turned to the sky. Under it, the piece fades to its floor and no lower, the Target card's bar
			-- held readable; out of view, all of it whole again, each part exactly as it was. The keeper's own bar (Config.Hud.Boss,
			-- A and B) stands in the Target card's stead, so the card is put back for it ("Off") while this looks, as before TR5.
			do
				local wasBoss = HudConfig.Boss.Keeper
				t.Server("Tune", "Hud.Boss.Keeper", "Off")
				t.Wait(0.1)
				local see = HudConfig.SeeThrough
				local hud = HudController.Parts()
				local camera = workspace.CurrentCamera
				local housing = hud.Target:FindFirstChild("Plate") :: ImageLabel? -- the foe card's plate (AR45)
				local light = hud.TargetHealth:FindFirstChild("Light") :: ImageLabel?
				local housingWhole, lightWhole = -1, -1 -- read once the sky has held: the test's own camera may start on the keeper
				local aim: GuiObject? = nil -- the piece the hat is held under; nil, the sky
				local lowest: { [string]: number } = {}
				local wasType, was = camera.CameraType, camera.CFrame -- given back as it was: the player's camera keeps its aim
				camera.CameraType = Enum.CameraType.Scriptable
				RunService:BindToRenderStep("NL_SeeThroughCamera", Enum.RenderPriority.Camera.Value + 1, function()
					local root, them = t.Root(), fighterModel(joined.Keeper)
					local hat = if them then them:FindFirstChild("Lamplighter_Head") else nil
					if not (root and hat and hat:IsA("BasePart")) then
						return
					end
					local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
					local eye = root.Position - look * CAMERA_BACK + Vector3.new(0, 3, 0)
					if aim == nil then
						camera.CFrame = CFrame.lookAt(eye, eye + Vector3.new(0, 1, 0) + look * 0.01) -- the sky: no keeper in view
						return
					end
					-- Turned so the piece's middle looks along the line to the hat (as the Base's band case aims).
					local middle = aim.AbsolutePosition + aim.AbsoluteSize / 2 + GuiService:GetGuiInset()
					camera.CFrame = CFrame.lookAt(eye, hat.Position)
					local aside = camera.CFrame:VectorToObjectSpace(camera:ViewportPointToRay(middle.X, middle.Y).Direction)
					camera.CFrame *= CFrame.fromRotationBetweenVectors(aside, Vector3.new(0, 0, -1))
				end)
				local function hold(piece: GuiObject?, seconds: number)
					aim = piece
					local untilAt = os.clock() + seconds
					while os.clock() < untilAt do
						for name, opacity in HudController.SeeThrough() do
							lowest[name] = math.min(lowest[name] or 1, opacity)
						end
						RunService.RenderStepped:Wait()
					end
				end
				local ok, problem = pcall(function()
					hold(nil, see.Hold + 0.7)
					housingWhole, lightWhole = if housing then housing.ImageTransparency else -1, if light then light.ImageTransparency else -1
					hold(hud.Target, 0.7)
					local now = HudController.SeeThrough()
					t.Check("the hat under the Target card: it fades to its floor", hud.Target.Visible and math.abs((now.Target or 1) - see.Target) < 0.02, string.format("at %.2f, its floor %.2f", now.Target or 1, see.Target))
					t.Check("its bar held readable", math.abs((now.TargetBar or 1) - see.Bar) < 0.02, string.format("at %.2f", now.TargetBar or 1))
					t.Check("drawn so: its housing see-through, its light nearly whole", housing ~= nil and light ~= nil and math.abs(housing.ImageTransparency - Hud.Faded(housingWhole, see.Target)) < 0.02 and math.abs(light.ImageTransparency - Hud.Faded(lightWhole, see.Bar)) < 0.02, string.format("housing %.2f, light %.2f", if housing then housing.ImageTransparency else -1, if light then light.ImageTransparency else -1))
					hold(hud.Credits.Parent :: GuiObject, 0.7)
					now = HudController.SeeThrough()
					t.Check("under the Credits pill: it fades to a quarter", math.abs((now.Credits or 1) - see.Economy) < 0.02, string.format("at %.2f", now.Credits or 1))
					hold(nil, see.Hold + 0.7)
					now = HudController.SeeThrough()
					t.Check("out of view, every piece whole again", now.Target == 1 and now.TargetBar == 1 and now.Credits == 1 and now.Electricity == 1, string.format("target %.2f, bar %.2f, credits %.2f, electricity %.2f", now.Target or -1, now.TargetBar or -1, now.Credits or -1, now.Electricity or -1))
					t.Check("each part exactly as it was", housing ~= nil and light ~= nil and housing.ImageTransparency == housingWhole and light.ImageTransparency == lightWhole and hud.Target:GetAttribute("Opacity") == nil)
				end)
				RunService:UnbindFromRenderStep("NL_SeeThroughCamera")
				camera.CFrame = was
				camera.CameraType = wasType
				t.Server("Tune", "Hud.Boss.Keeper", wasBoss)
				t.Check("never past research's floors", (lowest.Target or 1) >= see.Target - 1e-3 and (lowest.TargetBar or 1) >= see.Bar - 1e-3 and (lowest.Credits or 1) >= see.Economy - 1e-3 and (lowest.Electricity or 1) >= see.Economy - 1e-3, string.format("target %.2f, bar %.2f", lowest.Target or 1, lowest.TargetBar or 1))
				if not ok then
					error(problem, 0)
				end
			end
			-- Fix 2: after the keeper falls the lead holds, facing it, until its Down's Gone (the longest hold past it), then turns.
			local ours, them = myLead(), fighterModel(joined.Keeper)
			local fellAt = if them then them:GetPivot().Position else Vector3.zero
			local leadFrom: Vector3? = nil -- where it stands once a step under way at the fall has landed (a think and the replication)
			t.Check("the keeper falls", t.Server("KeeperEnd", "Win").Ok == true)
			local fellClock = os.clock()
			local fall = EffectsConfig.Falls[Enemies.ById[def :: string].Rig]
			local watched = fall.Gone / 60 + FightRule.LongestHold(Combat.Hitstop)
			local drift, offKeeper, saved = 0, 0, nil
			while os.clock() - fellClock < watched - 0.15 do
				-- held from where a swing under way at the fall ends: its clip's own lunge and recovery are its, not a step
				local acting = ours ~= nil and (ours:GetAttribute("Action") or "") ~= ""
				if ours and ours.Parent and os.clock() - fellClock > LANDED and (leadFrom or not acting) then
					local pivot = ours:GetPivot()
					local from = leadFrom or pivot.Position
					leadFrom = from
					drift = math.max(drift, Vector3.new(pivot.Position.X - from.X, 0, pivot.Position.Z - from.Z).Magnitude)
					-- from its last action's end: a swing under way ends first
					if os.clock() - fellClock > 0.6 then
						offKeeper = math.max(offKeeper, flatAngle(pivot.LookVector, fellAt - pivot.Position))
					end
				end
				if saved == nil and os.clock() - fellClock > 0.3 then
					saved = t.Server("Keeper").Wins
				end
				task.wait()
			end
			t.Check("the win is saved before any fade", saved == before.Wins + 1, `{saved} wins, was {before.Wins}`)
			t.Check("the lead holds where it stood until Gone", drift < 1, string.format("%.2f studs", drift))
			t.Check("facing the keeper", offKeeper < 25, string.format("%.0f degrees off", offKeeper))
			local turned = waitFor(t, keeper.WinPause - watched - 0.05, function(): boolean
				local pivot = if ours and ours.Parent then ours:GetPivot() else nil
				return pivot ~= nil and (flatAngle(pivot.LookVector, fellAt - pivot.Position) > 45 or (pivot.Position - (leadFrom or pivot.Position)).Magnitude > drift + 1)
			end)
			t.Check("then it turns from it, before the fade", turned)
			t.Wait(math.max(0, keeper.WinPause + moved - (os.clock() - fellClock)))
			local won = t.Server("Keeper")
			t.Check("the try is over", won.InTry == false and Players.LocalPlayer:GetAttribute("Try") == nil)
			t.Near("the avatar stands at the ring's exit (studs off)", won.FromExit, 0, SET_DOWN)
			-- The shortcut home, a step away: the trip to the base (TR45), recorded by the run's stub.
			local pad = Markers.Find("Shortcut")
			t.Check("the shortcut is in view of the exit", pad ~= nil and pad:IsA("BasePart"))
			if pad and pad:IsA("BasePart") then
				local stood = t.Root().CFrame
				t.Server("TravelStub", true)
				t.Root().CFrame = pad.CFrame + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				t.Check("the shortcut asks for the trip home", waitFor(t, Helpers.TRIP_ASKED, function(): boolean
					return Helpers.lastTrip(t, "Main") ~= nil
				end))
				t.Root().CFrame = stood -- off the pad, before the trip's reset
				t.Wait(0.3)
				t.Server("TravelStub", true) -- the trip's card down again, nothing under way
			end
			-- A loss: the lead falls. The win rested the keeper (TR10): a try meanwhile is refused, then it's back.
			t.Equal("the win rests the keeper: a try now is refused", t.Server("KeeperTry").Error, "Resting")
			t.Server("KeeperRest", 0)
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
			-- The fallen lead goes home to its plot (TR12); Studio's heal brings it back before the next case needs it.
			t.Check("the fallen lead goes home", waitFor(t, Combat.Lead.Leave + 2, function(): boolean
				local fallen = myLead()
				return fallen ~= nil and fallen:GetAttribute("State") == "Home"
			end))
			t.Server("LeadHeal")
			local state: any = nil
			waitFor(t, REPLICATE, function(): boolean -- its state reaches this client a moment after the server's answer
				local lead = myLead()
				state = if lead then lead:GetAttribute("State") else nil
				return state ~= nil and state ~= "Down" and state ~= "Home"
			end)
			t.Check("the lead is back up after its fall", state ~= nil and state ~= "Down" and state ~= "Home", tostring(state))
		end,
	},
	{
		-- Not Stay: the reset before it records where the run will put the avatar back (TestPadClear), never the street.
		Name = "Drops: the Shades a player's lead hit pay them as they fall, into the save; a pack it never hit pays nothing",
		Place = "Festival", -- TR45: its world stands in that place only
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
			-- Health carries (TR12): out of the fight it heals its Regen, a burst every 8 s (TR40); then whole for the next case.
			local lead = myLead()
			local was = if lead then lead:GetAttribute("Health") :: number else 0
			local most = if lead then lead:GetAttribute("MaxHealth") :: number else 0
			if lead and was < most then
				t.Check("its Regen heals it out of the fight", waitFor(t, StatsConfig.Regen.Every + 0.5, function(): boolean
					local now = myLead()
					return now ~= nil and (now:GetAttribute("Health") :: number) > was
				end))
			end
			t.Check("whole again for the next case", t.Server("FightHealth", 1).Ok == true)
			t.Check("the lead at full", waitFor(t, 1, function(): boolean
				local now = myLead()
				return now ~= nil and now:GetAttribute("Health") == now:GetAttribute("MaxHealth")
			end))
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
			-- Its own idle: its Voidkin's stance, else its rig's (Definitions.Actions, IdleOf; Config.Animations.Rigs).
			local rig = Animations.Rigs[tostring(lead:GetAttribute("Rig"))] or Animations.Rigs.R6
			local want = Actions.IdleOf(tostring(lead:GetAttribute("Def"))) or rig.Idle
			local idle: AnimationTrack? = nil
			for _, playing in (if animator then animator:GetPlayingAnimationTracks() else {}) do
				if playing.Animation and playing.Animation.Name == want then
					idle = playing
				end
			end
			t.Check("its idle plays", idle ~= nil, want)
			if idle then
				t.Near("at full weight", idle.WeightTarget, 1, 0.01)
			end
		end,
	},
	{
		Name = "Fight: Rook's lead wears his model",
		Run = function(t: any)
			t.Wait(LEAD_SETTLE)
			local found = myLead()
			t.Check("the lead is in the world", found ~= nil)
			if found == nil then
				return
			end
			local lead = found :: Model
			local row = Voidkin.ById[tostring(lead:GetAttribute("Def"))]
			if row == nil or row.Model ~= "Rook" then
				t.Row(`the lead is {tostring(lead:GetAttribute("Def"))}, not Rook: his checks wait for a Rook lead`, nil, nil, nil, "")
				return
			end
			-- AR1 (his recipe, built by ModelRecipe): R6's seven parts hidden, his eight pieces riding them
			local hidden, shown = 0, 0
			for _, part in lead:GetChildren() do
				if part:IsA("BasePart") then
					if string.sub(part.Name, 1, 5) == "Rook_" then
						shown += if part.Transparency == 0 then 1 else 0
					else
						hidden += if part.Transparency >= 1 then 1 else 0
					end
				end
			end
			t.Check("R6's seven parts are hidden", hidden == 7, `{hidden} of 7`)
			t.Check("his eight pieces show", shown == 8, `{shown} of 8`)
			local function joint(arm: string, name: string, piece: string): Motor6D?
				local on = lead:FindFirstChild(arm)
				local motor = if on then on:FindFirstChild(name) else nil
				local part1 = if motor and motor:IsA("Motor6D") then motor.Part1 else nil
				local ok = part1 ~= nil and part1.Name == piece
				t.Check(`the {name} joint turns {piece} on the {arm}`, ok)
				return if ok then motor :: Motor6D else nil
			end
			local piston = joint("Right Arm", "Piston", "Rook_Piston")
			local tape = joint("Left Arm", "Tape", "Rook_Tape")
			-- his clips key the two, under their arms (tools/studio/Animations/Author's HELD): Haymaker's wind-up slides the
			-- piston 0.85 studs toward the shoulder at its most cocked (AR8 B5's polish, build/handoff/Rook/clips/Rook_Haymaker.json)
			local slide = -1
			local haymaker = Clips.Sequence(Actions.ById.RookHaymaker.Clip or "")
			for _, keyframe in if haymaker then haymaker:GetKeyframes() else {} do
				for _, pose in (keyframe :: Keyframe):GetDescendants() do
					if pose:IsA("Pose") and pose.Name == "Rook_Piston" and (pose.Parent :: Instance).Name == "Right Arm" then
						slide = math.max(slide, pose.CFrame.Position.Magnitude)
					end
				end
			end
			t.Near("Haymaker slides the piston", slide, 0.85, 0.01)
			-- and a clip always plays: idle, the piston rests home and the tape swings (at R6's rest pose the ram meets the hip)
			if piston and tape then
				local first = tape.Transform
				local swing, out = 0, 0
				local began = os.clock()
				while os.clock() - began < TAPE_WATCH do
					RunService.Heartbeat:Wait()
					local _, angle = (first:Inverse() * tape.Transform):ToAxisAngle()
					swing = math.max(swing, math.deg(angle))
					out = math.max(out, piston.Transform.Position.Magnitude)
				end
				t.Check("the tape swings through the idle", swing > TAPE_SWING, string.format("%.1f degrees", swing))
				t.Near("the piston rests home", out, 0, 0.01)
			end
		end,
	},
	{
		Name = "Fight: every Voidkin with a model wears it as the lead, with the points and the looks its effects use",
		Run = function(t: any)
			-- docs/engineering-plan.md, "Content at scale", item 5: each row of Definitions.Voidkin that names a Model
			-- (ServerStorage.Templates.<Model>) leads in turn, one owned or given, and its body is read as the lead wears it:
			-- R6's seven parts hidden; every <Model>_ piece shown, held by a weld or a joint with both its ends set (a synced
			-- .rbxm can drop a new part's Part0) and riding the body; every point a Body row of its kit's effects rides, and
			-- every look a Glow or a Relight row lights, on it. Rook's own case keeps his piston, his tape and his Haymaker.
			local view = ProfileController.Get()
			local was = if view then view.Roles.Lead else nil
			local count = 0
			local benched: { { Bay: number, Voidkin: string } } = {} -- workers taken out of their bay to lead, put back after
			for _, row in Voidkin.List do
				local modelName = row.Model
				if modelName == nil then
					continue
				end
				count += 1
				local def = row.Id
				local function leading(): Model?
					local found = myLead()
					return if found and found:GetAttribute("Def") == def then found else nil
				end
				if leading() == nil then
					local now = ProfileController.Get()
					local id: string? = nil
					for owned, voidkin in (if now then now.Voidkin else {}) :: { [string]: any } do
						if voidkin.Def == def and Read.Role(now :: any, owned) == "" then
							id = owned
							break
						end
					end
					if id == nil then -- the only one works in a bay (a copy given would join it): out of the bay for its turn
						for owned, voidkin in (if now then now.Voidkin else {}) :: { [string]: any } do
							local bay = if voidkin.Def == def then tonumber(string.match(Read.Role(now :: any, owned), "^Bay (%d+)$")) else nil
							if bay and t.Server("Act", "SetWorker", { Bay = bay, Voidkin = "" }).Ok == true then
								table.insert(benched, { Bay = bay, Voidkin = owned })
								id = owned
								break
							end
						end
					end
					if id == nil then
						local given = t.Server("VoidkinGive", def)
						local newId = if type(given) == "table" and given.Ok == true then given.Id else nil
						local arrived = type(newId) == "string" and waitFor(t, 2, function(): boolean
							local latest = ProfileController.Get()
							return latest ~= nil and latest.Voidkin[newId] ~= nil
						end)
						if arrived then
							id = newId
						end
					end
					t.Check(`{def}: one free to lead`, id ~= nil)
					if id == nil then
						continue
					end
					local answer = t.Server("Act", "SetLead", { Voidkin = id })
					t.Check(`{def}: made the lead`, type(answer) == "table" and answer.Ok == true, if type(answer) == "table" then tostring(answer.Error) else tostring(answer))
				end
				local stood = waitFor(t, LEAD_SETTLE * 2, function(): boolean
					return leading() ~= nil
				end)
				local lead = leading()
				t.Check(`{def} leads in the world`, stood and lead ~= nil)
				if lead == nil then
					continue
				end
				local prefix = `{modelName}_`
				local rigParts, hidden, pieces, shown = 0, 0, 0, 0
				local loose: { string } = {}
				-- Held and riding: each piece's joint holds it to something and it sits where that joint puts it, and its
				-- chain of joints ends on the body, so a piece riding a loose piece is loose too. Kirra's scarf reaches 9.5
				-- studs at rest, so a reach from the root can't tell a long piece from a dropped one.
				local joints: { [BasePart]: Instance } = {}
				for _, joint in lead:GetDescendants() do
					if (joint:IsA("JointInstance") or joint:IsA("WeldConstraint")) and joint.Part1 ~= nil and joint.Part0 ~= nil then
						joints[joint.Part1 :: BasePart] = joint
					end
				end
				local function placed(part: BasePart): boolean
					local joint = joints[part]
					if joint == nil then
						return false
					elseif joint:IsA("JointInstance") then
						local motor = if joint:IsA("Motor6D") then joint.Transform else CFrame.identity
						local at = (joint.Part0 :: BasePart).CFrame * joint.C0 * motor * joint.C1:Inverse()
						return (at.Position - part.Position).Magnitude < 1
					end
					return true -- a WeldConstraint holds its offset as it was made
				end
				local function riding(part: BasePart): boolean
					local at: BasePart? = part
					for _ = 1, 32 do
						if at == nil or string.sub(at.Name, 1, #prefix) ~= prefix then
							return at ~= nil -- the chain reached the body
						elseif not placed(at) then
							return false
						end
						local joint = joints[at] :: any
						at = joint.Part0
					end
					return false
				end
				for _, part in lead:GetChildren() do
					if not part:IsA("BasePart") then
						continue
					end
					if string.sub(part.Name, 1, #prefix) ~= prefix then
						rigParts += 1
						hidden += if part.Transparency >= 1 then 1 else 0
						continue
					end
					pieces += 1
					shown += if part.Transparency == 0 then 1 else 0
					if not riding(part) then
						table.insert(loose, part.Name)
					end
				end
				t.Check(`{def}: R6's seven parts hidden`, rigParts == 7 and hidden == 7, `{hidden} of {rigParts}`)
				t.Check(`{def}: its pieces show`, pieces > 0 and shown == pieces, `{shown} of {pieces}`)
				table.sort(loose)
				t.Check(`{def}: each piece held to the body and riding it`, #loose == 0, table.concat(loose, ", "))
				local kit = Actions.KitOf(def)
				local skip = Actions.SkipOf(def)
				if skip then
					table.insert(kit, skip)
				end
				local missing: { string } = {}
				for _, action in kit do
					local effect = if action.Effect then EffectsConfig.Rows[action.Effect] else nil
					for rowName, effectRow in (if effect then effect.Rows else {}) :: { [string]: EffectsConfig.Row } do
						local point = effectRow.Body
						if point and lead:FindFirstChild(point, true) == nil then
							table.insert(missing, `{action.Effect}.{rowName}: {point}`)
						end
						local lit = if effectRow.Part and (effectRow.Kind == "Glow" or effectRow.Kind == "Relight") then effectRow.Part[1] else nil
						local part = if lit then lead:FindFirstChild(lit, true) else nil
						if lit and (part == nil or part:FindFirstChildOfClass("SurfaceAppearance") == nil) then
							table.insert(missing, `{action.Effect}.{rowName}: {lit}'s look`)
						end
					end
				end
				table.sort(missing)
				t.Check(`{def}: every point and look its effects use is on it`, #missing == 0, table.concat(missing, ", "))
			end
			t.Check("every Voidkin with a model, in turn", count >= 3, `{count}`)
			if was then
				t.Server("Act", "SetLead", { Voidkin = was })
			end
			for _, worker in benched do
				t.Server("Act", "SetWorker", worker)
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
			lookAhead(t)
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
		Name = "Fight: a ranged lead skips back when a Shade closes: away from it by Land, facing it, into its next action (TR7)",
		Run = function(t: any)
			-- Each Voidkin with a skip leads in turn (its Kit's Skip, Actions.Skips: Pip, Lyric); the save's own lead is put back after.
			local view = t.Server("Data")
			local owned = if type(view) == "table" and type(view.Voidkin) == "table" then view.Voidkin else {}
			local was = if type(view) == "table" and type(view.Roles) == "table" then view.Roles.Lead else nil
			local ids: { string } = {}
			for id, row in owned do
				if type(row) == "table" and Actions.Skips[row.Def] then
					table.insert(ids, id)
				end
			end
			table.sort(ids)
			local function flat(v: Vector3): Vector3
				return Vector3.new(v.X, 0, v.Z)
			end
			-- One lead's first skip against a level-matched Shade, watched each frame as this screen draws it.
			local function trial(def: string)
				local skip = Actions.SkipOf(def) :: Actions.Action
				local lead: Model? = nil
				local began = os.clock()
				while lead == nil and os.clock() - began < LEAD_SETTLE * 2 do
					t.Wait(0.1)
					local found = myLead()
					lead = if found and found:GetAttribute("Def") == def then found else nil
				end
				local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				t.Check(`{def} leads`, lead ~= nil and root ~= nil)
				if lead == nil or root == nil then
					return
				end
				local body = lead :: Model
				lookAhead(t)
				local spawned = t.Server("FightSpawn", "brawler", body:GetAttribute("Level"), SHADE_AHEAD)
				t.Check(`{def}: the Shade spawns`, type(spawned) == "table" and spawned.Ok == true)
				local function shade(): BasePart?
					for _, model in (workspace:FindFirstChild("Fighters") :: Instance):GetChildren() do
						if model:GetAttribute("Fighter") == body:GetAttribute("Target") then
							return model:FindFirstChild("HumanoidRootPart") :: BasePart?
						end
					end
					return nil
				end
				local skippedAt: number? = nil
				local from, foe = Vector3.zero, Vector3.zero
				local startGap, landGap, worst, worstAt, startOff = 0, 0, 0, 0, 0
				local landedAt: Vector3? = nil
				local settled: Vector3? = nil
				local nextIn: number? = nil
				began = os.clock()
				while os.clock() - began < SHADE_TIMEOUT and (settled == nil or nextIn == nil) do
					RunService.Heartbeat:Wait()
					local target = shade()
					local action = body:GetAttribute("Action")
					if skippedAt == nil then
						if action == skip.Id and target then
							skippedAt = os.clock()
							from, foe = root.Position, target.Position
							startGap = flat(from - foe).Magnitude
						end
						continue
					end
					local since = os.clock() - (skippedAt :: number)
					if target and since <= skip.Beats.Land then
						local look = flat(root.CFrame.LookVector)
						local toward = flat(target.Position - root.Position)
						local off = if look.Magnitude > 1e-3 and toward.Magnitude > 1e-3
							then math.deg(math.acos(math.clamp(look.Unit:Dot(toward.Unit), -1, 1)))
							else 0
						if since < SKIP_TURN then
							startOff = math.max(startOff, off)
						elseif off > worst then
							worst, worstAt = off, since
						end
					end
					if landedAt == nil and since >= skip.Beats.Land + SKIP_LAG then
						landedAt = root.Position
						landGap = flat(root.Position - foe).Magnitude
					end
					if landedAt and settled == nil and since >= skip.Beats.Land + SKIP_LAG + SKIP_SETTLE then
						settled = root.Position
					end
					if nextIn == nil and action ~= skip.Id and action ~= "" then
						nextIn = since
					end
				end
				t.Server("FightSpawn") -- clears what is left
				t.Check(`{def} skips when the Shade closes`, skippedAt ~= nil, `within {SHADE_TIMEOUT} s`)
				if skippedAt == nil then
					return
				end
				t.Check(`{def}: it skipped with the Shade inside Close`, startGap < Combat.Skip.Close + SKIP_LAG_STUDS, string.format("%.1f studs", startGap))
				t.Check(`{def}: it lands farther from where the Shade stood`, landGap > startGap + SKIP_MIN_TRAVEL, string.format("%.1f to %.1f studs", startGap, landGap))
				t.Check(`{def}: outside Close`, landGap >= Combat.Skip.Close, string.format("%.1f studs", landGap))
				t.Check(`{def}: facing the Shade all the way`, worst <= SKIP_FACING, string.format("%.0f degrees at worst, %.2f s in", worst, worstAt))
				t.Row(`{def}: degrees off the Shade as it started, before it turned`, nil, nil, startOff, "degrees")
				if landedAt and settled then
					local drift = flat(settled - landedAt).Magnitude
					t.Check(`{def}: and stops on Land, no slide after`, drift <= SKIP_SLIDE, string.format("%.2f studs", drift))
				end
				t.Check(`{def}: it lands into its next action`, nextIn ~= nil and nextIn <= skip.Beats.Land + SKIP_NEXT, if nextIn then string.format("%.2f s after it skipped", nextIn) else "none")
				t.Row(`{def}: studs it skipped`, nil, nil, flat((landedAt or from) - from).Magnitude, "studs")
			end
			local tried: { [string]: boolean } = {}
			for _, id in ids do
				local def = owned[id].Def
				if tried[def] then
					continue
				end
				local answer = t.Server("Act", "SetLead", { Voidkin = id })
				if type(answer) == "table" and answer.Ok == true then -- a worker can't lead: another of its kind may
					tried[def] = true
					trial(def)
				end
			end
			t.Server("Act", "SetLead", { Voidkin = was })
			if next(tried) == nil then
				t.Row("no Pip or Lyric free to lead: the skip's checks wait for one", nil, nil, nil, "")
			end
		end,
	},
	{
		Name = "Fight: a move carries its lead on its beat to Rules.Fight.MoveEnd's point, facing its target, into its next hit's reach (AR10)",
		Run = function(t: any)
			-- Each action with Moves in a Voidkin's kit (Kirra's dash and Scarf Step's blink), pressed once by the replay:
			-- the lead held at the action's spacing from a dummy (ReplayService), each move watched as this screen draws
			-- it. No hit comes before a move, so the lead and the dummy stand on the replay's spots until it.
			local function flat(v: Vector3): Vector3
				return Vector3.new(v.X, 0, v.Z)
			end
			local view = ProfileController.Get()
			local was = if view then view.Roles.Lead else nil
			local tried = 0
			for _, row in Voidkin.List do
				local carried: { Actions.Action } = {}
				for _, action in Actions.KitOf(row.Id) do
					if action.Moves then
						table.insert(carried, action)
					end
				end
				if #carried == 0 then
					continue
				end
				local def = row.Id
				local function leading(): Model?
					local found = myLead()
					return if found and found:GetAttribute("Def") == def then found else nil
				end
				if leading() == nil then -- one free to lead, owned or given
					local now = ProfileController.Get()
					local id: string? = nil
					for owned, voidkin in (if now then now.Voidkin else {}) :: { [string]: any } do
						if voidkin.Def == def and Read.Role(now :: any, owned) == "" then
							id = owned
							break
						end
					end
					if id == nil then
						local given = t.Server("VoidkinGive", def)
						local newId = if type(given) == "table" and given.Ok == true then given.Id else nil
						local arrived = type(newId) == "string" and waitFor(t, 2, function(): boolean
							local latest = ProfileController.Get()
							return latest ~= nil and latest.Voidkin[newId] ~= nil
						end)
						local latest = ProfileController.Get()
						if arrived and latest and Read.Role(latest :: any, newId) == "" then
							id = newId
						end
					end
					if id == nil then -- her only copy works in a bay, and a copy given joins it
						t.Row(`no {def} free to lead: its moves wait for one`, nil, nil, nil, "")
						continue
					end
					t.Server("Act", "SetLead", { Voidkin = id })
				end
				waitFor(t, LEAD_SETTLE * 2, function(): boolean
					return leading() ~= nil
				end)
				local lead = leading()
				local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				t.Check(`{def} leads`, lead ~= nil and root ~= nil)
				if lead == nil or root == nil then
					continue
				end
				tried += 1
				for _, action in carried do
					local moves = action.Moves :: { [string]: Actions.Move }
					local beats: { string } = {}
					for beat in moves do
						table.insert(beats, beat)
					end
					table.sort(beats, function(a: string, b: string): boolean
						return action.Beats[a] < action.Beats[b]
					end)
					local pressedAt: number? = nil
					local onPress = lead:GetAttributeChangedSignal("ActionAt"):Connect(function()
						if pressedAt == nil and lead:GetAttribute("Action") == action.Id then
							pressedAt = os.clock()
						end
					end)
					local struck: { [string]: boolean } = {} -- a whiff sends no Hit: one sent is a hit that reached
					local onHit = Net.Client.On("Hit", function(hit: any)
						if type(hit) == "table" and hit.A == lead and hit.Action == action.Id and type(hit.Beat) == "string" then
							struck[hit.Beat] = true
						end
					end)
					local started = t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE)
					local ok = type(started) == "table" and started.Ok == true and typeof(started.Spot) == "Vector3" and typeof(started.Target) == "Vector3"
					t.Check(`{action.Id}: the replay presses it`, ok, if type(started) == "table" then tostring(started.Error) else tostring(started))
					local foe = if ok then started.Target :: Vector3 else Vector3.zero
					local from = if ok then started.Spot :: Vector3 else Vector3.zero
					type Seen = { From: Vector3, Avatar: Vector3, Landed: Vector3?, Look: Vector3?, Settled: Vector3? }
					local seen: { [string]: Seen } = {}
					local began = os.clock()
					while ok and os.clock() - began < action.Length + LEAD_SETTLE do
						RunService.Heartbeat:Wait()
						if pressedAt == nil then
							continue
						end
						local since = os.clock() - (pressedAt :: number)
						for _, beat in beats do
							local move, at, s = moves[beat], action.Beats[beat], seen[beat]
							if s == nil and since >= at then
								local avatar = Parts.Root(Players.LocalPlayer.Character)
								seen[beat] = { From = from, Avatar = if avatar then avatar.Position else from }
							elseif s and s.Landed == nil and since >= at + move.Seconds + SKIP_LAG then
								s.Landed, s.Look = root.Position, root.CFrame.LookVector
								from = root.Position -- a later move starts where this one left it
							elseif s and s.Landed and s.Settled == nil and since >= at + move.Seconds + SKIP_LAG + SKIP_SETTLE then
								s.Settled = root.Position
							end
						end
						local last = seen[beats[#beats]]
						if last and last.Settled then
							break
						end
					end
					t.Wait(math.max(0, action.Length - (if pressedAt then os.clock() - pressedAt else 0))) -- its hits all in
					onPress:Disconnect()
					onHit:Disconnect()
					t.Server("Replay")
					t.Check(`{action.Id}: pressed`, pressedAt ~= nil)
					for _, beat in beats do
						local move, s = moves[beat], seen[beat]
						t.Check(`{action.Id}.{beat}: watched to its landing`, s ~= nil and s.Settled ~= nil)
						if s == nil or s.Landed == nil or s.Settled == nil then
							continue
						end
						local landed = s.Landed :: Vector3
						local expected = FightRule.MoveEnd(s.From, foe, s.Avatar, move)
						local off = flat(landed - expected).Magnitude
						t.Check(`{action.Id}.{beat}: lands on MoveEnd's point`, off <= MOVE_NEAR, string.format("%.2f studs off", off))
						t.Row(`{action.Id}.{beat}: studs it carried the lead`, nil, nil, flat(landed - s.From).Magnitude, "studs")
						if move.Gap < 0 then
							local past = flat(landed - foe):Dot(flat(foe - s.From).Unit)
							t.Check(`{action.Id}.{beat}: past its target`, past > 0, string.format("%.1f studs past", past))
						end
						local facing = flatAngle(s.Look :: Vector3, foe - landed)
						t.Check(`{action.Id}.{beat}: facing its target as it lands`, facing <= SKIP_FACING, string.format("%.0f degrees", facing))
						local drift = flat((s.Settled :: Vector3) - landed).Magnitude
						t.Check(`{action.Id}.{beat}: and stays there`, drift <= SKIP_SLIDE, string.format("%.2f studs", drift))
						local hitBeat: string? = nil
						for name in action.Hits do -- the first hit on or after the move: the one it carries the lead in for
							local at = action.Beats[name]
							if at >= action.Beats[beat] and (hitBeat == nil or at < action.Beats[hitBeat :: string]) then
								hitBeat = name
							end
						end
						if hitBeat then
							local hit = action.Hits[hitBeat :: string]
							local gap = flat(landed - foe).Magnitude
							t.Check(`{action.Id}.{hitBeat}: its target inside its reach from there`, gap <= hit.Reach, string.format("%.1f of %.1f studs", gap, hit.Reach))
							t.Check(`{action.Id}.{hitBeat}: and it lands`, struck[hitBeat :: string] == true)
						end
					end
				end
			end
			if was then
				t.Server("Act", "SetLead", { Voidkin = was })
			end
			if tried == 0 then
				t.Row("no Voidkin with a move free to lead: the moves' checks wait for one", nil, nil, nil, "")
			end
		end,
	},
	{
		Name = "Fight: each lead's passive in play, with its cue: Second Wind's shell, Kindle's Fire and flare, Tempo's cooldown, First Strike's critical (TR7)",
		Run = function(t: any)
			-- Each Voidkin with a passive that this save can lead, in turn (Definitions.Passives: Rook, Pip, Lyric, Kirra); the
			-- save's own lead is put back after.
			local view = t.Server("Data")
			local owned = if type(view) == "table" and type(view.Voidkin) == "table" then view.Voidkin else {}
			local was = if type(view) == "table" and type(view.Roles) == "table" then view.Roles.Lead else nil
			local ids: { string } = {}
			for id, row in owned do
				if type(row) == "table" and Passives.ById[row.Def] then
					table.insert(ids, id)
				end
			end
			table.sort(ids)
			local function effects(name: string): { BasePart }
				local found = {}
				local folder = workspace:FindFirstChild("NL_Effects")
				for _, child in if folder then folder:GetChildren() else {} do
					if child:IsA("BasePart") and child.Name == name then
						table.insert(found, child)
					end
				end
				return found
			end
			local function shellRound(root: BasePart): boolean
				for _, shell in effects("NL_PassiveShell") do
					if (shell.Position - root.Position).Magnitude <= PASSIVE_NEAR and shell.Transparency < 1 then
						return true
					end
				end
				return false
			end
			local trials: { [string]: (body: Model, root: BasePart) -> () } = {}
			trials.rook = function(body: Model, root: BasePart)
				t.Check("rook: Second Wind off at full health", body:GetAttribute("PassiveOn") == false)
				t.Server("FightHealth", PASSIVE_LOW)
				t.Check("rook: under 30%, it holds", waitFor(t, PASSIVE_CUE, function(): boolean
					return body:GetAttribute("PassiveOn") == true
				end))
				t.Check("rook: its shell round him", waitFor(t, PASSIVE_CUE, function(): boolean
					return shellRound(root)
				end))
				t.Server("FightHealth", 1)
				t.Check("rook: back over it, it's off", waitFor(t, PASSIVE_CUE, function(): boolean
					return body:GetAttribute("PassiveOn") == false
				end))
				t.Check("rook: and the shell fades away", waitFor(t, PASSIVE_CUE, function(): boolean
					return not shellRound(root)
				end))
			end
			trials.pip = function(body: Model, _root: BasePart)
				local row = Passives.ById.pip
				local seen: { [string]: { Passive: any, Physical: number, Elemental: number } } = {}
				local flared = false
				local connection = Net.Client.On("Hit", function(hit: any)
					if type(hit) ~= "table" or hit.A ~= body or hit.Action ~= row.Action or hit.Dodged then
						return
					end
					local elemental = if type(hit.Elemental) == "number" then hit.Elemental else 0
					seen[hit.Beat] = { Passive = hit.Passive, Physical = hit.Total - elemental, Elemental = elemental }
					if hit.Beat == row.Beat then
						task.spawn(function()
							local began = os.clock()
							while not flared and os.clock() - began < PASSIVE_CUE do
								flared = #effects("NL_PassiveFlare") > 0
								RunService.Heartbeat:Wait()
							end
						end)
					end
				end)
				lookAhead(t)
				-- SHADE_TOUGHER over him, so it stands for the third shot: a geared Pip fells a level-matched brawler in two
				-- (this save's, 2026-11-18: 172 a shot).
				local spawned = t.Server("FightSpawn", "brawler", ((body:GetAttribute("Level") :: number?) or 1) + SHADE_TOUGHER, SHADE_AHEAD)
				t.Check("pip: the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
				waitFor(t, SHADE_TIMEOUT, function(): boolean
					return seen[row.Beat :: string] ~= nil and seen.Shot1 ~= nil
				end)
				t.Wait(PASSIVE_CUE)
				connection:Disconnect()
				t.Server("FightSpawn")
				local third = seen[row.Beat :: string]
				t.Check("pip: his third shot lands", third ~= nil)
				if third then
					t.Check("pip: it carries Kindle", third.Passive == "pip", tostring(third.Passive))
					-- its Fire is 40% of the shot, past whatever Fire his gear adds
					t.Check("pip: Fire worth 40% of the shot, as its own number", third.Elemental >= row.Share * third.Physical - 1e-6, string.format("%.1f of %.1f", third.Elemental, third.Physical))
				end
				if seen.Shot1 then
					t.Check("pip: his first shot carries none", seen.Shot1.Passive == nil)
				end
				t.Check("pip: the lantern flares on it", flared)
			end
			trials.lyric = function(body: Model, _root: BasePart)
				local row = Passives.ById.lyric
				local held = Actions.ById[row.Action :: string]
				local expected = held.Cooldown * (1 - row.Share)
				local ring = body:GetAttribute("Cooldown")
				t.Check("lyric: the ring's cooldown is Tempo's", type(ring) == "number" and math.abs(ring - expected) < 1e-6, `{ring} of {expected}`)
				local readyIn: number? = nil
				local connection = body:GetAttributeChangedSignal("ActionAt"):Connect(function()
					if body:GetAttribute("Action") == held.Id then
						local ready, at = body:GetAttribute("Ready"), body:GetAttribute("ActionAt")
						if type(ready) == "number" and type(at) == "number" then
							readyIn = ready - at
						end
					end
				end)
				lookAhead(t)
				local spawned = t.Server("FightSpawn", "brawler", body:GetAttribute("Level"), SHADE_AHEAD)
				t.Check("lyric: the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
				waitFor(t, SHADE_TIMEOUT, function(): boolean
					return readyIn ~= nil
				end)
				connection:Disconnect()
				t.Server("FightSpawn")
				t.Check("lyric: Held Note comes back 20% sooner", readyIn ~= nil and math.abs((readyIn :: number) - expected) < 1e-3, if readyIn then string.format("%.2f s", readyIn) else "not seen")
			end
			trials.kirra = function(body: Model, _root: BasePart)
				-- First Strike: her first hit to land on a new Shade crits, whatever her own chance; the ones after roll as
				-- any hit's (Rules.Passive.Critical; the logic cases keep "nothing after"). A dodged swing hasn't landed.
				local landed: { any } = {}
				local connection = Net.Client.On("Hit", function(hit: any)
					if type(hit) == "table" and hit.A == body and not hit.Dodged and typeof(hit.T) == "Instance" then
						table.insert(landed, hit)
					end
				end)
				lookAhead(t)
				local spawned = t.Server("FightSpawn", "brawler", body:GetAttribute("Level"), SHADE_AHEAD)
				t.Check("kirra: the Shade spawns", type(spawned) == "table" and spawned.Ok == true)
				local shadeId = if type(spawned) == "table" then spawned.Id else nil
				local function onIt(): { any }
					local list = {}
					for _, hit in landed do
						if (hit.T :: Instance):GetAttribute("Fighter") == shadeId then
							table.insert(list, hit)
						end
					end
					return list
				end
				waitFor(t, SHADE_TIMEOUT, function(): boolean
					return #onIt() >= 3
				end)
				connection:Disconnect()
				t.Server("FightSpawn")
				local hits = onIt()
				t.Check("kirra: her first hit on it lands", hits[1] ~= nil)
				if hits[1] then
					t.Check("kirra: and crits (First Strike)", hits[1].Critical == true, `{hits[1].Action}.{hits[1].Beat}`)
				end
				local crits = 0
				for i = 2, #hits do
					crits += if hits[i].Critical then 1 else 0
				end
				t.Row("kirra: criticals among the hits after it, at her own chance", nil, nil, crits, `of {math.max(0, #hits - 1)}`)
			end
			local tried: { [string]: boolean } = {}
			for _, id in ids do
				local def = owned[id].Def
				if tried[def] or trials[def] == nil then
					continue
				end
				local answer = t.Server("Act", "SetLead", { Voidkin = id })
				if type(answer) ~= "table" or answer.Ok ~= true then -- a worker can't lead: another of its kind may
					continue
				end
				tried[def] = true
				local lead: Model? = nil
				waitFor(t, LEAD_SETTLE * 2, function(): boolean
					local found = myLead()
					lead = if found and found:GetAttribute("Def") == def then found else nil
					return lead ~= nil
				end)
				local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				t.Check(`{def} leads`, lead ~= nil and root ~= nil)
				if lead and root then
					trials[def](lead :: Model, root)
				end
			end
			t.Server("Act", "SetLead", { Voidkin = was })
			if next(tried) == nil then
				t.Row("no Rook, Pip, Lyric or Kirra free to lead: the passives' checks wait for one", nil, nil, nil, "")
			end
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
			lookAhead(t)
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
				if string.sub(part.Name, 1, 5) == "Mask_" or string.sub(part.Name, 1, 10) == "EliteMask_" then
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
			t.Check("each at its own strength, Config.Shades' (AR2, section 6)", bodyLook ~= nil and maskLook ~= nil and bodyLook.EmissiveStrength == Shades.Emissive and maskLook.EmissiveStrength == Shades.MaskEmissive, if bodyLook and maskLook then `{bodyLook.EmissiveStrength} and {maskLook.EmissiveStrength}` else "")
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
				-- the burst's pictures (AR2, section 11), the art sheet's on billboards round its anchor
				local function pictures(): { BillboardGui }
					local found = {}
					local home = workspace:FindFirstChild("NL_Effects")
					for _, anchor in (if home then home:GetChildren() else {}) do
						if anchor.Name == "NL_ShadeBurst" then
							for _, gui in anchor:GetChildren() do
								if gui:IsA("BillboardGui") then
									table.insert(found, gui)
								end
							end
						end
					end
					return found
				end
				-- every billboard is made at the start; a picture shows by its image (Effects.ShadeBurst)
				local function lit(): { BillboardGui }
					local on = {}
					for _, gui in pictures() do
						local image = gui:FindFirstChildOfClass("ImageLabel")
						if gui.Enabled and image and image.ImageTransparency < 1 then
							table.insert(on, gui)
						end
					end
					return on
				end
				local hideAt: number? = nil
				local hideClip: number? = nil
				local shownBefore = not hidden()
				local charged = false
				local atHide: { BillboardGui } = {}
				local before: { BillboardGui } = {}
				local beforeClip: number? = nil
				-- the longest of the last steps: the flare is set on the first step at or past the marker and read a poll
				-- later, so a long frame there moves the clip's time by that step, not by a nominal frame
				local polledAt, step = os.clock(), FRAME
				while os.clock() - (downAt :: number) < 1 do
					step = math.max(step, os.clock() - polledAt)
					polledAt = os.clock()
					-- the effect steps on RenderStepped, before this poll's Heartbeat. A part is drawn the frame it's set; a
					-- billboard shown is drawn a frame later, one cleared is gone at once. So the hide's picture shows what
					-- was lit a step before it and is still lit on it.
					if hidden() then
						hideAt, hideClip = os.clock(), beforeClip
						local still = {}
						for _, gui in lit() do
							still[gui] = true
						end
						for _, gui in before do
							if still[gui] then
								table.insert(atHide, gui)
							end
						end
						break
					end
					before, beforeClip = lit(), clipTime()
					charged = charged or #before > 0
					if beforeClip == nil or (beforeClip :: number) < ShadeBurstArt.Burst * FRAME - 2 * FRAME then
						step = FRAME -- only the steps round the marker count
					end
					task.wait()
				end
				t.Check("its burst plays", playing(shade)[Animations.Rigs.Shade.Down] == true or hideAt ~= nil)
				t.Check("whole until the marker", shownBefore)
				t.Check("then the whole body, mask too, hides at once", hideAt ~= nil)
				if hideAt then
					local marker = ShadeBurstArt.Burst * FRAME
					t.Check(
						"its flare set on the marker, frame 27 of the clip: never before it, within two of the steps that ran",
						hideClip ~= nil and (hideClip :: number) >= marker - 1e-3 and (hideClip :: number) <= marker + 2 * step + 1e-3,
						string.format("at %.3f s, the marker %.3f, a step %.1f ms", hideClip or -1, marker, step * 1000)
					)
					t.Row("seconds from the fall to the burst, the hold included", nil, nil, (hideAt :: number) - (downAt :: number), "s")
					t.Check("the charge shows in its collar before it", charged)
					local flare = (ShadeBurstArt.Frames[ShadeBurstArt.Burst] or {})[1]
					local label = if #atHide == 1 then atHide[1]:FindFirstChildOfClass("ImageLabel") else nil
					t.Check(
						"the flare, the art sheet's, drawn in the hide's own picture",
						flare ~= nil and flare.Kind == "flare" and label ~= nil and label.ImageRectOffset == flare.Offset and label.ImageRectSize == flare.Rect,
						`{#atHide} lit`
					)
					-- the table's At is right, forward and up: the flare's centre straight under the collar, its top over it
					local offset = if #atHide == 1 then atHide[1].StudsOffsetWorldSpace else Vector3.zero
					t.Near("the flare's centre under the collar by the table's 1.8", if flare then offset.Y else 0, if flare then flare.At.Z else 1, 0.05)
					t.Near("and on its line, not out to a side", Vector3.new(offset.X, 0, offset.Z).Magnitude, 0, 0.05)
					local plain = #pictures() > 0
					for _, gui in pictures() do
						local image = gui:FindFirstChildOfClass("ImageLabel")
						if gui.LightInfluence ~= 0 or image == nil or image.ImageColor3 ~= Color3.new(1, 1, 1) or image.Image ~= EffectsConfig.ShadeBurst.Picture then
							plain = false
						end
					end
					t.Check("untinted and unlit, the group's picture (the content check's condition 1)", plain)
					local gone = waitFor(t, (ShadeBurstArt.Last - ShadeBurstArt.Burst) * FRAME + 1, function(): boolean
						local home = workspace:FindFirstChild("NL_Effects")
						return home == nil or home:FindFirstChild("NL_ShadeBurst") == nil
					end)
					t.Check("nothing of it left after its last frame", gone)
				end
			end
			t.Server("FightSpawn") -- clears it
		end,
	},
	{
		Name = "Fight: a Shade's burst never waits for good on a clip held still",
		Run = function(t: any)
			-- AR2, section 13: the charge runs on the Down clip's clock. A clip held still bursts anyway after
			-- Config.Effects.ShadeBurst.Wait, before the server takes the body; a body cleared while its clip is held takes the
			-- charge with it. Before, a body that left with its clip short of the marker left the burst in the world for good.
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if type(level) ~= "number" then
				return
			end
			local function anchors(): number
				local count = 0
				local home = workspace:FindFirstChild("NL_Effects")
				for _, child in (if home then home:GetChildren() else {}) do
					count += if child.Name == "NL_ShadeBurst" then 1 else 0
				end
				return count
			end
			-- the Down clip held still on this client, every frame, as a hold that never lets go would
			local function hold(model: Model)
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
				for _, track in (if animator then animator:GetPlayingAnimationTracks() else {}) do
					if track.Animation and track.Animation.Name == Animations.Rigs.Shade.Down then
						track:AdjustSpeed(0)
					end
				end
			end
			-- one Shade beaten by the lead: its model and the moment this client sees it fall
			local function fallen(): (Model?, number)
				lookAhead(t)
				local spawned = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
				if type(spawned) ~= "table" or spawned.Ok ~= true then
					return nil, 0
				end
				local model: Model? = nil
				waitFor(t, 5, function(): boolean
					model = fighterModel(spawned.Id)
					return model ~= nil
				end)
				local shade = model
				if shade == nil then
					return nil, 0
				end
				local until_ = os.clock() + SHADE_TIMEOUT
				while os.clock() < until_ and shade.Parent ~= nil and shade:GetAttribute("State") ~= "Down" do
					task.wait()
				end
				return if shade:GetAttribute("State") == "Down" then shade else nil, os.clock()
			end
			t.Check("no burst in the world before", anchors() == 0, `{anchors()}`)
			local forced = ShadeBurstArt.Burst * FRAME + EffectsConfig.ShadeBurst.Wait
			local held, downAt = fallen()
			t.Check("a Shade falls", held ~= nil)
			if held then
				local torso = held:FindFirstChild("Shade_Torso") :: BasePart?
				local hidAt: number? = nil
				while os.clock() - downAt < forced + 0.5 do
					hold(held)
					if torso and torso.LocalTransparencyModifier >= 1 then
						hidAt = os.clock() - downAt
						break
					end
					task.wait()
				end
				t.Near("its clip held still, it bursts anyway, Config.Effects.ShadeBurst.Wait past the marker", hidAt or -1, forced, 0.15)
				t.Check("and the burst ends", waitFor(t, (ShadeBurstArt.Last - ShadeBurstArt.Burst) * FRAME + 1, function(): boolean
					return anchors() == 0
				end), `{anchors()} left`)
			end
			t.Server("FightSpawn")
			local cleared, clearedAt = fallen()
			t.Check("a second Shade falls", cleared ~= nil)
			if cleared then
				hold(cleared)
				t.Server("FightSpawn") -- cleared while its clip is held short of the marker
				local left = waitFor(t, 1, function(): boolean
					if cleared.Parent ~= nil then
						hold(cleared)
					end
					return cleared.Parent == nil and anchors() == 0
				end)
				t.Check("cleared with its clip held, it takes its burst with it", left, string.format("%d left, %.2f s after its fall", anchors(), os.clock() - clearedAt))
			end
			t.Server("FightSpawn")
		end,
	},
	{
		Name = "Fight: an elite wears its mask twice, the second on its Left Arm",
		Run = function(t: any)
			-- docs/asset-requests.md, AR2, section 5: the same mask at 0.6 of it, welded to the Left Arm, in the mask's own
			-- light only; an ordinary Shade has none.
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if type(level) ~= "number" then
				return
			end
			lookAhead(t)
			local spawned = t.Server("FightSpawn", "brawler_elite", level, SHADE_AHEAD)
			t.Check("the elite spawns", type(spawned) == "table" and spawned.Ok == true, tostring(type(spawned) == "table" and spawned.Error))
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local model: Model? = nil
			waitFor(t, 5, function(): boolean
				model = fighterModel(spawned.Id)
				return model ~= nil and model:FindFirstChild("EliteMask_Brawler") ~= nil
			end)
			local elite = model :: Model
			t.Check("its model reaches this client", elite ~= nil)
			if elite == nil then
				t.Server("FightSpawn")
				return
			end
			local masks = {}
			for _, part in elite:GetChildren() do
				if string.sub(part.Name, 1, 5) == "Mask_" or string.sub(part.Name, 1, 10) == "EliteMask_" then
					table.insert(masks, part.Name)
				end
			end
			table.sort(masks)
			t.Check("it wears its mask twice and no other", #masks == 2 and masks[1] == "EliteMask_Brawler" and masks[2] == "Mask_Brawler", table.concat(masks, ", "))
			local first = elite:FindFirstChild("Mask_Brawler") :: BasePart?
			local second = elite:FindFirstChild("EliteMask_Brawler") :: BasePart?
			local weld = if second then second:FindFirstChildOfClass("Weld") else nil
			t.Check("the second rides the Left Arm", weld ~= nil and weld.Part0 ~= nil and weld.Part0.Name == "Left Arm", if weld and weld.Part0 then weld.Part0.Name else "no weld")
			if first and second then
				t.Near("at 0.6 of the first's size", second.Size.X / first.Size.X, 0.6, 0.01)
				-- AR2, section 7: the copy without the ties, which a sleeve can't hide, is as deep as the face alone. The whole
				-- mask at 0.6 would be 0.6 of the first's depth.
				local depth = second.Size.Z / first.Size.Z
				t.Check("without its ties: as deep as the face alone", depth < 0.15, string.format("%.3f of the first's depth", depth))
			end
			local look = if second then second:FindFirstChildOfClass("SurfaceAppearance") else nil
			t.Check("in the mask's own light only", look ~= nil and look.EmissiveTint == Shades.MaskTint and look.EmissiveStrength == Shades.MaskEmissive, if look then `{look.EmissiveTint:ToHex()} at {look.EmissiveStrength}` else "no surface")
			t.Server("FightSpawn") -- clears it
		end,
	},
	{
		Name = "Fight: a Shade swings and flinches on alternate sides",
		Run = function(t: any)
			-- research's ask for the Shade (docs/team-notes.md, Now, 2026-11-12): Attack and AttackLeft in turn, Hit and
			-- HitLeft too (Config.Animations.Mirrors).
			local swings, flinches = swingsOf(t, "brawler")
			if swings == nil or flinches == nil then
				return
			end
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
	-- "the elite swings Attack every time" is ShadeCases' now, for every elite (AR57)
	{
		Name = "Fight: the elite is the Shade rig, larger",
		Run = function(t: any)
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			if type(level) ~= "number" then
				t.Check("the lead is in the world", false)
				return
			end
			lookAhead(t)
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
		-- AR7: the keeper on its own rig (sections 2 and 4) and its fall's block (section 5, signed 2026-11-13): it holds its
		-- Challenge before anything, fights in its Ready, walks at its own pace, and falls into the Shade's burst on its clip's
		-- Burst with its pole and lantern left standing, the lantern lit, guttering and out, then gone to paper; the server
		-- keeps the body until Gone.
		Name = "Keeper: the Lamplighter wears its rig, holds its Challenge, walks at its pace, and its lantern goes out last",
		Run = function(t: any)
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if type(level) ~= "number" then
				return
			end
			local row = Enemies.ById.lamplighter
			local fall = EffectsConfig.Falls[row.Rig]
			local challenge = Actions.ById[row.Enter :: string]
			-- outside the lead's leash, so the keeper walks to it alone for a while
			local spawned = t.Server("FightSpawn", "lamplighter", level, Combat.Lead.Leash + 10)
			t.Check("the keeper spawns", type(spawned) == "table" and spawned.Ok == true, tostring(type(spawned) == "table" and spawned.Error))
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			local spawnedAt = os.clock()
			local model: Model? = nil
			waitFor(t, 5, function(): boolean
				model = fighterModel(spawned.Id)
				return model ~= nil and model:FindFirstChild("Lamplighter_Lantern") ~= nil
			end)
			local keeper = model :: Model
			local root = if keeper then keeper:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			t.Check("its model reaches this client", keeper ~= nil and root ~= nil)
			if keeper == nil or root == nil then
				t.Server("FightSpawn")
				return
			end
			t.Check("it's its own rig", keeper:GetAttribute("Rig") == "Lamplighter", tostring(keeper:GetAttribute("Rig")))
			t.Near("at its scale", keeper:GetScale(), row.Scale or 1, 0.01)
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { workspace:FindFirstChild("Fighters") :: Instance, Players.LocalPlayer.Character :: Instance }
			params.FilterType = Enum.RaycastFilterType.Exclude
			local floor = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), params)
			t.Near("its feet on the floor, at its scale", if floor then root.Position.Y - floor.Position.Y else -1, 3 * (row.Scale or 1), 0.45)
			local function look(name: string): SurfaceAppearance?
				local piece = keeper:FindFirstChild(name)
				return if piece then piece:FindFirstChildOfClass("SurfaceAppearance") else nil
			end
			local body, mask, lantern = look("Lamplighter_Torso"), look("Lamplighter_Head"), look("Lamplighter_Lantern")
			local kind = tostring(keeper:GetAttribute("Type"))
			t.Check("its seams lit in its type's colour at a Shade's strength", body ~= nil and body.EmissiveTint == Shades.Tint[kind] and body.EmissiveStrength == Shades.Emissive, kind)
			t.Check("its mask in a mask's", mask ~= nil and mask.EmissiveTint == Shades.MaskTint and mask.EmissiveStrength == Shades.MaskEmissive)
			t.Near("its lantern burning cold", if lantern then lantern.EmissiveStrength else -1, fall.Glow, 1e-3)
			-- the Challenge first, held still to its end
			t.Check("it holds its Challenge as it's spawned", keeper:GetAttribute("Action") == challenge.Id and waitFor(t, 1, function(): boolean
				return playing(keeper)[challenge.Clip :: string] == true
			end), tostring(keeper:GetAttribute("Action")))
			local from = root.Position
			local drift = 0
			while os.clock() - spawnedAt < challenge.Length - 0.15 do
				drift = math.max(drift, (root.Position - from).Magnitude)
				task.wait()
			end
			t.Check("and stands where it was through it", drift < 0.3, string.format("%.2f studs", drift))
			t.Check("its stance under everything is its Ready", waitFor(t, 1, function(): boolean
				return playing(keeper)[Actions.IdleOf("lamplighter") :: string] == true
			end))
			-- its walk: its own speed, the clip near rate 1 (research's tier 2, AR7, section 4)
			local walked = waitFor(t, 2, function(): boolean
				return playing(keeper)[Animations.Rigs.Lamplighter.Walk] == true
			end)
			t.Check("it walks its own walk", walked)
			local speeds: { number } = {}
			local last, lastAt = root.Position, os.clock()
			local walkUntil = os.clock() + 1.2
			while os.clock() < walkUntil and keeper:GetAttribute("Action") == "" do
				task.wait(0.2)
				local now = os.clock()
				local step = root.Position - last
				table.insert(speeds, Vector3.new(step.X, 0, step.Z).Magnitude / (now - lastAt))
				last, lastAt = root.Position, now
			end
			table.sort(speeds)
			local median = if #speeds > 0 then speeds[math.floor(#speeds / 2) + 1] else -1
			t.Near("at its own pace (studs a second)", median, Combat.Keeper.WalkSpeed, 0.8)
			-- the fall, on the Down clip's clock (the killing hit's hold pauses it, so not the wall's)
			t.Check("it falls", t.Server("FightDefeat", spawned.Id).Ok == true)
			-- the clip's clock, run on past its held last frame (Gone may come after the clip's end)
			local held: number? = nil
			local function clipTime(): number?
				if held then
					return held + os.clock()
				end
				local humanoid = keeper:FindFirstChildOfClass("Humanoid")
				local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
				for _, track in (if animator then animator:GetPlayingAnimationTracks() else {}) do
					if track.Animation and track.Animation.Name == Animations.Rigs.Lamplighter.Down then
						if track.Length > 0 and track.TimePosition >= track.Length - Effects.HeldEnd then
							held = track.TimePosition - os.clock()
						end
						return track.TimePosition
					end
				end
				return nil
			end
			local paper = if lantern then lantern.Color else Color3.new()
			local function shows(name: string): boolean
				local piece = keeper:FindFirstChild(name)
				return piece ~= nil and piece:IsA("BasePart") and piece.LocalTransparencyModifier < 1
			end
			local function scraps(): number
				local count = 0
				local home = workspace:FindFirstChild("NL_Effects")
				for _, anchor in (if home then home:GetChildren() else {}) do
					if anchor.Name == "NL_LanternOut" then
						for _, gui in anchor:GetChildren() do
							local image = if gui:IsA("BillboardGui") then gui:FindFirstChildOfClass("ImageLabel") else nil
							count += if image and image.ImageTransparency < 1 then 1 else 0
						end
					end
				end
				return count
			end
			local seen = { BodyAfterBurst = false, KeptAfterBurst = true, KeptBurst = false, SteadyBefore = true, Dimmed = false, LitAfterOut = false, Gone = false, Scraps = 0, KeptAfterGone = false, PaperBefore = true, Darkening = false, DarkAfterOut = true, DarkSeen = false }
			local function near(a: Color3, b: Color3): boolean
				return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.03
			end
			local deadline = os.clock() + 4
			local clock: number? = nil
			local scrapsAt: number? = nil
			while os.clock() < deadline and keeper.Parent ~= nil do
				local at = clipTime()
				clock = at or clock
				local frame = if at then at / FRAME else nil
				local glow = if lantern then lantern.EmissiveStrength else -1
				if frame and frame >= fall.Burst + 2 and frame < fall.Gone - 1 then
					seen.BodyAfterBurst = seen.BodyAfterBurst or shows("Lamplighter_Torso")
					seen.KeptAfterBurst = seen.KeptAfterBurst and shows("Lamplighter_Pole") and shows("Lamplighter_Lantern")
					seen.KeptBurst = true
				end
				local colour = if lantern then lantern.Color else paper
				if frame and frame < fall.Gutter - 1 then
					seen.SteadyBefore = seen.SteadyBefore and math.abs(glow - fall.Glow) < 1e-3
					seen.PaperBefore = seen.PaperBefore and near(colour, paper)
				elseif frame and frame > fall.Gutter + 1 and frame < fall.Out - 1 then
					seen.Dimmed = seen.Dimmed or glow < fall.Glow - 1e-3
					seen.Darkening = seen.Darkening or (not near(colour, paper) and not near(colour, fall.Dark))
				elseif frame and frame > fall.Out + 1 and frame < fall.Gone - 1 then
					seen.LitAfterOut = seen.LitAfterOut or glow > 0
					seen.DarkAfterOut = seen.DarkAfterOut and near(colour, fall.Dark)
					seen.DarkSeen = true
				end
				if frame and frame >= fall.Gone - 1 then
					seen.Gone = true -- the body is still here at Gone
				end
				local count = scraps()
				seen.Scraps = math.max(seen.Scraps, count)
				scrapsAt = scrapsAt or (if count > 0 then os.clock() else nil)
				if scrapsAt and os.clock() - scrapsAt > 3 * FRAME then
					-- a step after Gone the pole and lantern are gone: only paper
					seen.KeptAfterGone = seen.KeptAfterGone or shows("Lamplighter_Pole") or shows("Lamplighter_Lantern")
				end
				task.wait()
			end
			t.Check("its body hidden on the clip's Burst", seen.KeptBurst and not seen.BodyAfterBurst)
			t.Check("its pole and lantern left standing", seen.KeptBurst and seen.KeptAfterBurst)
			t.Check("the lantern steady until Gutter", seen.SteadyBefore)
			t.Check("guttering from Gutter", seen.Dimmed)
			t.Check("and out on Out", not seen.LitAfterOut)
			t.Check("its paper its own until Gutter", seen.PaperBefore)
			t.Check("going down from Gutter", seen.Darkening)
			t.Check("and dark from Out to Gone", seen.DarkSeen and seen.DarkAfterOut)
			t.Check("the server keeps the body to Gone", seen.Gone, string.format("the clip at %.2f s when it went", clock or -1))
			t.Check("then the pole and lantern go to paper scraps", seen.Scraps > 0 and seen.Scraps <= fall.Scraps.Lantern + fall.Scraps.Pole and not seen.KeptAfterGone, `{seen.Scraps} scraps at once`)
			t.Server("FightSpawn")
		end,
	},
	{
		Name = "Fight: Haymaker's look keeps its frames, and leaves nothing",
		Stay = true,
		Run = function(t: any)
			-- docs/asset-requests.md, AR1, section 5: the charge to the strike, the strike's square held through the hitstop,
			-- the shock's square the frame after; all gone by Strike + 19. Then B5's stamp (AR8, "B5"), checked in its own case.
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
					if theirs[p] or not p:IsA("BasePart") or p.Name:sub(1, 8) == "NL_Stamp" then
						continue -- B5's stamp has its own case
					end
					all += 1
					if laid(p) then
						count += 1
					end
				end
				return count, all
			end
			-- The strike's cue (Config.Sounds): one point sound, on the strike's frame, not again through the hitstop.
			local cue = EffectsConfig.Haymaker.Sound
			local theirSounds: { [Instance]: boolean } = {}
			for _, point in workspace.Terrain:GetChildren() do
				theirSounds[point] = true
			end
			local function cues(): number
				local count = 0
				for _, point in workspace.Terrain:GetChildren() do
					if not theirSounds[point] and point.Name == "NL_Sound" and point:FindFirstChild(cue) then
						count += 1
					end
				end
				return count
			end
			local running = Effects.Haymaker(action.Beats, lead, function(): BasePart?
				return nil
			end)
			local function at(clock: number): number
				running.Step(clock)
				running.Step(clock) -- a bar the step before laid and this doesn't is kept a step (AR8 A): settled
				return (shown())
			end
			t.Check("the charge's square before the strike", at(strike - 10 * FRAME) == SQUARE, `{shown()} bars`)
			t.Check("no strike sound before the strike", cues() == 0, `{cues()} plays`)
			-- Which square shows: its four bars, the longest as long as the square's side and bar (a picture's part is the
			-- stroke's length over the picture's span).
			local look = EffectsConfig.Haymaker
			local function isSquare(clock: number, square: { Side: number, Bar: number }): (boolean, string)
				local count = at(clock)
				local longest = 0
				local home = workspace:FindFirstChild("NL_Effects")
				for _, p in (if home then home:GetChildren() else {}) do
					if not theirs[p] and p:IsA("BasePart") and laid(p) and p.Name:sub(1, 8) ~= "NL_Stamp" then
						longest = math.max(longest, p.Size.X)
					end
				end
				local want = (square.Side + square.Bar) / (if look.Picture == "" then 1 else look.Span)
				return count == SQUARE and math.abs(longest - want) < 0.01, string.format("%d bars, %.2f long, want %.2f", count, longest, want)
			end
			-- a slow frame that lands past Shock still gives the strike its square, and the hitstop holds the clock there
			t.Check("the strike's square on the first frame past Strike", isSquare(shock + 0.25 * FRAME, look.Strike))
			t.Check("held there through the hitstop", isSquare(shock + 0.25 * FRAME, look.Strike))
			t.Check("the strike's sound plays once, on the strike", cues() == 1, `{cues()} plays`)
			t.Check("the shock's square on the next frame", isSquare(shock + 0.75 * FRAME, look.Shock))
			local after = at(shock + 4 * FRAME)
			t.Check("no bar after the shock's square: B5's stamp has its place", after == 0, `{after} bars`)
			local over = running.Step(strike + GONE_BY)
			local _, left = shown()
			t.Check("over by Strike + 19 frames", over == false)
			t.Check("and nothing left", left == 0, `{left} parts`)
			running.Destroy()
			-- AR1, sections 5 to 7: the ram's heat on the clip's markers, on both lit pieces alike (Config.Effects.Haymaker.Glow).
			local glow = look.Glow
			local surfaces: { SurfaceAppearance } = {}
			for _, name in glow.Pieces do
				local piece = lead:FindFirstChild(name)
				local surface = if piece then piece:FindFirstChildOfClass("SurfaceAppearance") else nil
				if surface then
					table.insert(surfaces, surface)
				end
			end
			if #surfaces < #glow.Pieces then
				t.Row(`the lead has {#surfaces} of the ram's {#glow.Pieces} lit pieces: the glow's checks wait for a Rook lead`, nil, nil, nil, "")
				return
			end
			local function strength(): (number, number)
				local low: number, high: number = math.huge, 0
				for _, surface in surfaces do
					low = math.min(low, surface.EmissiveStrength)
					high = math.max(high, surface.EmissiveStrength)
				end
				return low, high
			end
			local heat = Effects.Haymaker(action.Beats, lead, function(): BasePart?
				return nil
			end)
			local function lit(clock: number): (number, number)
				heat.Step(clock)
				return strength()
			end
			-- Section 7: the content check holds it lit between 3 and 5, so it steps 0 to Step at Charge and back at Vent.
			local peak = math.clamp(glow.Peak, 3, 5)
			local step = math.clamp(glow.Step, 3, peak)
			local charge, vent = action.Beats.Charge, action.Beats.Vent
			local _, cold = strength()
			t.Check("the ram cold once the look's over", cold == 0, string.format("%.2f", cold))
			local _, before = lit(charge - FRAME)
			t.Check("cold before Charge", before == 0, string.format("%.2f", before))
			local low, high = lit(charge)
			t.Near("on Charge it steps straight to Step", low, step, 0.01)
			low, high = lit((charge + strike) / 2)
			t.Near("warming through the wind-up, halfway", high, step + (peak - step) * 0.5 ^ glow.Rise, 0.01)
			t.Check("both pieces alike", low == high, string.format("%.2f and %.2f", low, high))
			low, high = lit(strike)
			t.Check("at its peak on the strike", low == peak and high == peak, string.format("%.2f, want %.2f", high, peak))
			_, high = lit((shock + vent) / 2)
			t.Near("cooling after the shock, halfway", high, step + (peak - step) * 0.5 ^ glow.Fall, 0.01)
			low, high = lit(vent - FRAME)
			t.Check("still at Step or above a frame before Vent", low >= step - 0.01, string.format("%.2f", low))
			_, high = lit(vent)
			t.Check("out by Vent", high == 0, string.format("%.2f", high))
			heat.Destroy()
		end,
	},
	{
		-- docs/asset-requests.md, AR8, "B5" (Config.Effects.Haymaker.Stamp): through the hold the square hangs over the
		-- target, facing the camera, drawn tight as it rises; it slams down over Drop frames, stretched tall; on Strike it
		-- lands at the target's feet, wide, and stays there when the target moves; it squashes on Shock as the floor's two
		-- bars run out, and is gone by the look's end. The pin itself, Haymaker's push of 0, is a logic case.
		Name = "Fight: Haymaker's stamp hangs over the target, slams onto it on Strike, and lies where it landed",
		Stay = true,
		Run = function(t: any)
			local look = EffectsConfig.Haymaker
			local s = look.Stamp
			local action = Actions.ById.RookHaymaker
			local lead = myLead()
			local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			local camera = workspace.CurrentCamera
			t.Check("the lead is in the world", root ~= nil and camera ~= nil)
			if lead == nil or root == nil or camera == nil then
				return
			end
			local r = root :: BasePart
			local strike = action.Beats.Strike
			local floorY = r.Position.Y - 3 -- an R6 root's height over the floor
			local ahead = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
			local right = Vector3.new(r.CFrame.RightVector.X, 0, r.CFrame.RightVector.Z).Unit
			local mark = Instance.new("Part")
			mark.Name = "NL_SelfTestTarget"
			mark.Anchored = true
			mark.CanCollide = false
			mark.CanQuery = false
			mark.Transparency = 1
			mark.Size = Vector3.one
			mark.Position = r.Position + ahead * 6 + right * 1.5
			mark.Parent = workspace
			local spot = Vector3.new(mark.Position.X, floorY, mark.Position.Z)
			local function shown(name: string): { BasePart }
				local found = {}
				local home = workspace:FindFirstChild("NL_Effects")
				for _, p in (if home then home:GetChildren() else {}) do
					if p:IsA("BasePart") and p.Name == name and p.Transparency < 1 then
						table.insert(found, p)
					end
				end
				return found
			end
			-- Only its own stamp is read: in a full run the lead's real Haymaker from an earlier case's fight still lay on the
			-- floor (4 bars before this one formed). The lead out of any fight, and the floor cleared first.
			t.Server("LeadCalm")
			waitFor(t, 5, function(): boolean
				return #shown("NL_StampPost") + #shown("NL_StampRail") == 0
			end)
			local running = Effects.Haymaker(action.Beats, lead, function(): BasePart?
				return mark
			end)
			-- The square `at` frames from Strike: its count, its foot over the floor (the lower bar's centre), its width
			-- (post to post), its height (bar to bar), its centre on the floor, and whether it faces the camera.
			type Square = { Count: number, Foot: number, Wide: number, Tall: number, Centre: Vector3, Faces: boolean }
			local function square(at: number): Square
				running.Step(strike + at * FRAME)
				local posts, across = shown("NL_StampPost"), shown("NL_StampRail")
				local got: Square = { Count = #posts + #across, Foot = -1, Wide = 0, Tall = 0, Centre = Vector3.zero, Faces = false }
				if #posts == 2 and #across == 2 then
					table.sort(across, function(a: BasePart, b: BasePart): boolean
						return a.Position.Y < b.Position.Y
					end)
					got.Foot = across[1].Position.Y - floorY
					got.Tall = across[2].Position.Y - across[1].Position.Y
					got.Wide = (posts[1].Position - posts[2].Position).Magnitude
					local mid = (posts[1].Position + posts[2].Position) / 2
					got.Centre = Vector3.new(mid.X, floorY, mid.Z)
					local toward = camera.CFrame.Position - got.Centre
					toward = Vector3.new(toward.X, 0, toward.Z).Unit
					got.Faces = across[1].CFrame.LookVector:Dot(toward) > 0.999
				end
				return got
			end
			local function on(got: Square, where: Vector3): number
				return (got.Centre - where).Magnitude
			end
			-- TR7 (c): it never stands over the top bar's foot plus Under. Where that cap bites in this framing, its height
			-- is lower than the Config's and its top edge sits on that line on screen, within 3 px.
			local function atLine(): (boolean, string)
				local edge = World.Ceiling()
				if edge == nil then
					return false, "no top bar"
				end
				local line = edge + s.Under * Layers.Scale()
				local frame = shown("NL_StampPost")
				for _, rail in shown("NL_StampRail") do
					table.insert(frame, rail)
				end
				local highest = topOnScreen(frame)
				return math.abs(highest - line) <= 1.5, string.format("capped: its top at %.1f px, the line at %.1f", highest, line)
			end
			-- ...but never held lower than Over, Clear above the head (Haymaker's content check, condition 1): there the
			-- head's margin wins.
			local function heightOk(got: number, want: number, within: number): (boolean, string)
				if math.abs(got - want) < within then
					return true, ""
				end
				if got < s.Over - 0.01 then
					return false, "under its floor over the head"
				end
				if got < want then
					if math.abs(got - s.Over) < 0.01 then
						return true, "held at its floor over the head"
					end
					return atLine()
				end
				return false, ""
			end
			local before = square(-s.Rise - 1)
			t.Check("nothing before it forms", before.Count == 0, `{before.Count} bars`)
			local forms = square(-s.Rise + 0.5)
			local formsHigh, formsNote = heightOk(forms.Foot, s.Over, 0.3)
			t.Check("it forms loose over the target's head", forms.Count == 4 and math.abs(forms.Wide - s.Side * s.Forms) < 0.1 * s.Side and formsHigh, string.format("%d bars, %.2f wide, foot at %.2f %s", forms.Count, forms.Wide, forms.Foot, formsNote))
			-- its art (Stamp.Art): the kit's bar and plate in their looks, posts upright, glowing and charging on its keys
			local art = s.Art
			local function lookOf(p: BasePart?): string?
				local surface = if p then p:FindFirstChildOfClass("SurfaceAppearance") else nil
				return if surface then surface.ColorMapContent.Uri else nil
			end
			local post = shown("NL_StampPost")[1]
			local plate = shown("NL_StampPlate")[1]
			t.Check("in the kit's look: the frame's ember, the plate's", lookOf(post) == FxKit.Images[if art.Grey then art.Frame.Grey else art.Frame.Look].Id
				and lookOf(plate) == FxKit.Images[if art.Grey then art.Plate.Grey else art.Plate.Look].Id, tostring(lookOf(post)))
			t.Check("its posts stand upright", post ~= nil and math.abs(post.CFrame.RightVector.Y) > 0.999)
			local hung = square(-s.Drop - 1)
			plate = shown("NL_StampPlate")[1]
			t.Check("the plate charging inside the frame", plate ~= nil and math.abs(plate.Transparency - Track.Value(art.Charge, -s.Drop - 1)) < 1e-6
				and plate.Size.X < hung.Wide, string.format("%.3f", if plate then plate.Transparency else -1))
			local surface = if plate then plate:FindFirstChildOfClass("SurfaceAppearance") else nil
			t.Check("glowing at its hang's Glow", surface ~= nil and math.abs(surface.EmissiveStrength - Track.Value(art.Glow, -s.Drop - 1)) < 1e-6)
			t.Near("hung: drawn tight to its side", hung.Wide, s.Side, 0.01)
			local hungHigh, hungNote = heightOk(hung.Foot, s.Top, 0.01)
			t.Check("at the top of its drop, or capped under the top bar", hungHigh, string.format("got %.2f, want %.2f %s", hung.Foot, s.Top, hungNote))
			t.Check("over the target", on(hung, spot) < 0.05, string.format("%.3f studs off", on(hung, spot)))
			t.Check("facing the camera", hung.Faces)
			local held = square(-s.Drop - 2)
			t.Check("held there a frame before it drops", math.abs(held.Foot - hung.Foot) < 0.01 and math.abs(held.Wide - hung.Wide) < 0.01)
			local falling = square(-1.5)
			t.Check("falling: lower, and stretched taller than wide", falling.Foot > 0.05 and falling.Foot < hung.Foot - 1 and falling.Tall > falling.Wide, string.format("foot at %.2f, %.2f tall, %.2f wide", falling.Foot, falling.Tall, falling.Wide))
			local landed = square(0.25)
			local postSurface = shown("NL_StampPost")[1]:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance
			t.Check("brighter on Strike", postSurface.EmissiveStrength > Track.Value(art.Glow, -s.Drop - 1)
				and math.abs(postSurface.EmissiveStrength - Track.Value(art.Glow, 0.25)) < 1e-6, string.format("%.3f", postSurface.EmissiveStrength))
			t.Near("on Strike: on the floor", landed.Foot, 0.04, 0.01)
			t.Near("wide", landed.Wide, s.Side * s.Spread, 0.01)
			t.Check("at the target's feet", on(landed, spot) < 0.05, string.format("%.3f studs off", on(landed, spot)))
			mark.Position += right * 3 -- the target moves on: the stamp stays where it landed
			local shock = square(1.25)
			t.Check("on Shock: where it landed, though the target moved", on(shock, spot) < 0.05, string.format("%.3f studs off", on(shock, spot)))
			t.Near("squashed flat", shock.Tall, s.Side * s.Squash[2], 0.01)
			local runParts = shown("NL_StampRun")
			t.Check("the floor's two bars run out from its feet, face up", #runParts == 2 and math.abs(runParts[1].CFrame.LookVector.Y) > 0.999, `{#runParts} bars`)
			square(3.25)
			t.Check("the plate gone before it lies flat, never left on the floor", #shown("NL_StampPlate") == 0)
			local lights = 0
			for _, p in (if workspace:FindFirstChild("NL_Effects") then (workspace :: any).NL_Effects:GetChildren() else {}) do
				if p.Name:sub(1, 8) == "NL_Stamp" and p:FindFirstChildWhichIsA("Light", true) then
					lights += 1
				end
			end
			t.Check("no light at the landing", lights == 0)
			local eaten = square(s.Eat + s.Eaten + 0.25)
			t.Check("eaten where it lies", eaten.Count == 0 and #shown("NL_StampRun") == 0, `{eaten.Count} bars`)
			local over = running.Step(strike + (s.Eat + s.Eaten + 1) * FRAME)
			t.Check("over once eaten", over == false)
			local left = 0
			local home = workspace:FindFirstChild("NL_Effects")
			for _, p in (if home then home:GetChildren() else {}) do
				if p.Name:sub(1, 8) == "NL_Stamp" then
					left += 1
				end
			end
			t.Check("and nothing left", left == 0, `{left} parts`)
			running.Destroy()
			mark:Destroy()
		end,
	},
	{
		Name = "Fight: Lantern Burst's look keeps the art sheet's table, and relights over the cooldown",
		Stay = true,
		Run = function(t: any)
			-- docs/asset-requests.md, AR4, section 8 (build/handoff/Pip/fx/pip_burst_art.json): the glow up from Heat to Send,
			-- held, out at the Burst; the heat on the lantern from Heat to the Burst; the trail from the frame after Send to
			-- Close frames past the Burst; the burst's cells from the Burst, on the clock that runs through the hit's hold;
			-- all white (the content check's condition 1); nothing left; then the lantern relit over the cooldown.
			local action = Actions.ById.PipLanternBurst
			local lead = myLead()
			local lamp = if lead then lead:FindFirstChild("Pip_Lamp") else nil
			local lantern = if lamp then lamp:FindFirstChild("Lantern") :: Attachment? else nil
			local surface = if lamp then lamp:FindFirstChildOfClass("SurfaceAppearance") else nil
			local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if lead == nil or lantern == nil or surface == nil or root == nil then
				t.Row("the lead isn't Pip: Lantern Burst's look waits for a Pip lead", nil, nil, nil, "")
				return
			end
			local look = EffectsConfig.LanternBurst
			local beats = action.Beats
			local heat, send, burst = beats.Heat, beats.Send, beats.Burst
			local area = (action.Hits.Burst.Area :: number)
			local folder = workspace:FindFirstChild("NL_Effects")
			local theirs: { [Instance]: boolean } = {}
			for _, p in (if folder then folder:GetDescendants() else {}) do
				theirs[p] = true
			end
			local function mine(class: string): Instance?
				local home = workspace:FindFirstChild("NL_Effects")
				for _, p in (if home then home:GetDescendants() else {}) do
					if not theirs[p] and p:IsA(class) then
						return p
					end
				end
				return nil
			end
			local running = Effects.LanternBurst(beats, lead, function(): BasePart?
				return nil
			end, action)
			local function at(clock: number, free: number?)
				running.Step(clock, free or clock)
			end
			-- The glow (Config.Effects.LanternBurst.Glow).
			local glow = look.Glow
			at(heat - FRAME)
			t.Near("cold before Heat", surface.EmissiveStrength, glow.Cold, 0.001)
			at((heat + send) / 2)
			t.Near("heating, halfway to Send", surface.EmissiveStrength, glow.Cold + (glow.Hot - glow.Cold) * 0.5 ^ glow.Curve, 0.01)
			at(burst - FRAME)
			t.Near("hot through the flight", surface.EmissiveStrength, glow.Hot, 0.001)
			-- The heat: its first cell on Heat, its size at Send, on the lantern.
			at(heat)
			local heatGui = lantern:FindFirstChildOfClass("BillboardGui")
			local heatLabel = if heatGui then heatGui:FindFirstChildOfClass("ImageLabel") else nil
			t.Check("the heat on the lantern, from Heat", pictured(heatGui) and heatLabel ~= nil)
			if heatGui and heatLabel then
				t.Check("its first cell", heatLabel.ImageRectOffset == Vector2.new(512, 768) and heatLabel.ImageRectSize == Vector2.new(128, 128), tostring(heatLabel.ImageRectOffset))
				t.Check("white and unlit", heatLabel.ImageColor3 == Color3.new(1, 1, 1) and heatGui.LightInfluence == 0 and heatLabel.Image == look.Picture)
				at(send)
				t.Near("3.2 studs at Send", heatGui.Size.X.Scale, 3.2, 0.01)
				t.Near("its belly on the lantern", heatGui.StudsOffsetWorldSpace.Y, (0.5 - look.Heat.Belly) * 3.2, 0.01)
			end
			-- The trail: off on Send, on the frame after.
			local beam = mine("Beam") :: Beam?
			t.Check("no trail on Send", beam ~= nil and not beam.Enabled)
			at(send + 2 * FRAME)
			t.Check("the trail the frame after", beam ~= nil and beam.Enabled)
			if beam then
				t.Check("white and unlit, the trail's picture", beam.Color.Keypoints[1].Value == Color3.new(1, 1, 1) and beam.LightInfluence == 0 and beam.Texture == look.TrailPicture)
				-- A Beam runs its picture's height along it: the turned picture, stretched once and still.
				t.Check("stretched once and still, so its head stays at the lantern", beam.TextureMode == Enum.TextureMode.Stretch and beam.TextureLength == 1 and beam.TextureSpeed == 0, `speed {beam.TextureSpeed}`)
			end
			-- The burst, held by the hit: the clock stays on the Burst, the free clock runs on.
			at(burst)
			t.Check("out at the Burst", surface.EmissiveStrength == 0, string.format("%.2f", surface.EmissiveStrength))
			t.Check("the heat kept a step past its last frame, drawn a picture late (AR8 A)", pictured(heatGui))
			at(burst)
			t.Check("the heat gone the step after", heatGui ~= nil and not pictured(heatGui))
			local burstGui = mine("BillboardGui") :: BillboardGui?
			local burstLabel = if burstGui then burstGui:FindFirstChildOfClass("ImageLabel") else nil
			if look.Exit ~= "" then
				-- The exit's rows in place of the picture (AR8, B1; the player's own case checks each row): the coil on the
				-- Burst, its foot on the ground under the lantern's stop, run on the free clock through the hold, gone after
				-- its burn; the picture never shown.
				t.Check("no burst picture: the exit's rows play instead", not pictured(burstGui))
				local home = workspace:FindFirstChild("NL_Rows")
				local bands: { MeshPart } = {}
				for _, p in (if home then home:GetChildren() else {}) do
					if p:IsA("MeshPart") and string.find(p.Name, "^FxCoil2_Burn") and p.Transparency < 1 then
						table.insert(bands, p)
					end
				end
				t.Check("the coil on the Burst, all six bands", #bands == 6, tostring(#bands))
				local band1 = nil :: MeshPart?
				for _, p in bands do
					band1 = if p.Name == "FxCoil2_Burn1" then p else band1
				end
				if band1 then
					local unit = FxKit.Meshes.FxCoil2_Burn1
					local scale = band1.Size.Y / unit.Size.Y
					t.Near("its foot on the ground", band1.Position.Y - unit.Centre.Y * scale, root.Position.Y - 3, 0.01)
					at(burst, burst + 30 * FRAME)
					t.Check("burnt off after its burn, on the free clock through the hold", band1.Transparency == 1)
				end
				at(burst, burst + 2 * FRAME)
				t.Check("the trail closing onto it", beam ~= nil and beam.Enabled)
				at(burst, burst + look.Trail.Close * FRAME)
				t.Check("and closed", beam ~= nil and not beam.Enabled)
			end
			if look.Exit == "" then
				t.Check("the burst on the Burst", pictured(burstGui) and burstLabel ~= nil)
			end
			if look.Exit == "" and burstGui and burstLabel then
				local size = look.Burst.PerArea * area
				t.Near("three times the area's studs", burstGui.Size.X.Scale, size, 0.001)
				local stand = burstGui.Parent :: BasePart
				t.Near("its foot on the ground", stand.Position.Y - size / 2, root.Position.Y - 3, 0.01)
				t.Check("white and unlit", burstLabel.ImageColor3 == Color3.new(1, 1, 1) and burstGui.LightInfluence == 0 and burstLabel.Image == look.Picture)
				local function cellAt(frames: number): (Vector2?, Vector2?)
					at(burst, burst + frames * FRAME)
					at(burst, burst + frames * FRAME) -- settled: a cell gone is kept a step (AR8 A)
					if not pictured(burstGui) then
						return nil, nil
					end
					return burstLabel.ImageRectOffset, burstLabel.ImageRectSize
				end
				local b = look.Burst
				local boil, ending = 4 * b.Leap, 4 * b.Leap + 4 * b.Boil * b.BoilPlays
				local cells = {
					{ 0, Vector2.new(0, 0), 256, "the leap's first cell" },
					{ boil, Vector2.new(0, 256), 256, "the boil's, through the hold" },
					{ ending, Vector2.new(0, 512), 256, "the end's" },
					{ ending + 8 * b.End - 1, Vector2.new(384, 768), 128, "the wisp's, the last" },
				}
				for _, row in cells do
					local offset, extent = cellAt(row[1] :: number)
					t.Check(row[4] :: string, offset == row[2] and extent == Vector2.new(row[3] :: number, row[3] :: number), `{offset} {extent}`)
				end
				local gone = cellAt(ending + 8 * b.End)
				t.Check("gone after the wisp", gone == nil)
				at(burst, burst + 2 * FRAME)
				t.Check("the trail closing onto it", beam ~= nil and beam.Enabled)
				at(burst, burst + look.Trail.Close * FRAME)
				t.Check("and closed", beam ~= nil and not beam.Enabled)
			end
			-- Nothing left, and the readout: dark at the clip's end, relit by the cooldown.
			at(action.Length)
			t.Check("nothing left", mine("BasePart") == nil and mine("Beam") == nil and lantern:FindFirstChildOfClass("BillboardGui") == nil)
			t.Check("dark at the clip's end", surface.EmissiveStrength == 0, string.format("%.2f", surface.EmissiveStrength))
			local seconds = action.Cooldown - action.Length
			local began = os.clock()
			task.wait(1)
			local u = (os.clock() - began) / seconds
			t.Near("relighting over the cooldown's rest", surface.EmissiveStrength, glow.Cold * u ^ glow.Relight, 0.03)
			local again = Effects.LanternBurst(beats, lead, function(): BasePart?
				return nil
			end, action)
			again.Step(0, 0)
			t.Near("a new burst takes the lantern back from the readout", surface.EmissiveStrength, glow.Cold, 0.001)
			again.Destroy()
			Effects.Relight(surface, 0) -- the lantern ready, as the replay and the next case find it
		end,
	},
	{
		Name = "Fight: the Held Note's look keeps the art sheet's table: the flash, two Beams on an arc, a touch as it reaches, the heal's ring",
		Stay = true,
		Run = function(t: any)
			-- docs/asset-requests.md, AR4, section 10 (build/handoff/Lyric/fx/lyric_note_art.json), on a stand-in of hers (a
			-- root and the two rings), so it runs with any lead: the flash swelling in the rings and its sizes on the beats; on
			-- each beat a crest of two Beams, the ribbon over the veil, white and unlit, upright, on an arc round the cone's
			-- point with the table's CurveSize; its height, place and width by its age, the width times Config's Width; the veil
			-- gone after its hold and fade; a struck Shade's touch on the frame the crest comes within Short of it, once; the
			-- heal's ring rising flat round a body; nothing left after.
			local action = Actions.ById.LyricHeldNote
			local look = EffectsConfig.HeldNote
			local beats = action.Beats
			local note = action.Hits.Note
			local cone, apex = math.rad(note.Cone or 0), note.Apex or 0
			local origin = Vector3.new(0, 600, 0) -- far over the map: these parts are this client's own
			local function body(name: string, at: Vector3): (Model, BasePart)
				local model = Instance.new("Model")
				model.Name = name
				local root = Instance.new("Part")
				root.Name = "HumanoidRootPart"
				root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
				root.Size = Vector3.new(2, 2, 1)
				root.CFrame = CFrame.lookAt(at, at + Vector3.new(0, 0, -1))
				root.Parent = model
				model.PrimaryPart = root
				model.Parent = workspace
				return model, root
			end
			local stand, root = body("SelfTest_Lyric", origin)
			for _, name in { "RingR", "RingL" } do
				local ring = Instance.new("Attachment")
				ring.Name = name
				ring.Position = Vector3.new(if name == "RingR" then 2.5 else -2.5, 1.9, 0)
				ring.Parent = root
			end
			local away = 9 -- studs ahead of her, inside the cone
			local shade, shadeRoot = body("SelfTest_Shade", origin + Vector3.new(0, 0, -away))
			local folder = workspace:FindFirstChild("NL_Effects")
			local theirs: { [Instance]: boolean } = {}
			for _, p in (if folder then folder:GetDescendants() else {}) do
				theirs[p] = true
			end
			local function mine(class: string): { Instance }
				local found = {}
				local home = workspace:FindFirstChild("NL_Effects")
				for _, p in (if home then home:GetDescendants() else {}) do
					if not theirs[p] and p:IsA(class) then
						table.insert(found, p)
					end
				end
				return found
			end
			local function smooth(u: number): number
				local c = math.clamp(u, 0, 1)
				return c * c * (3 - 2 * c)
			end
			local running = Effects.HeldNote(beats, stand, function(): BasePart?
				return shadeRoot
			end, action)
			local function at(clock: number)
				running.Step(clock, clock)
			end
			local flashes: { BillboardGui } = {}
			for _, ring in root:GetChildren() do
				local gui = ring:FindFirstChildOfClass("BillboardGui")
				if gui then
					table.insert(flashes, gui)
				end
			end
			t.Check("a flash on each ring", #flashes == 2, `{#flashes}`)
			local first = beats.Note
			local charge = look.Charge * FRAME
			local flash = look.Flash
			local function flashSize(): number?
				local gui = flashes[1]
				return if pictured(gui) then gui.Size.X.Scale else nil
			end
			at(first - charge - FRAME)
			t.Check("no flash before the charge", flashSize() == nil)
			at(first - FRAME)
			local swell = flash.Swell[1] + (flash.Swell[2] - flash.Swell[1]) * smooth((charge - FRAME) / charge)
			t.Near("swelling in the charge", flashSize() or -1, swell, 0.001)
			local label = if flashes[1] then flashes[1]:FindFirstChildOfClass("ImageLabel") else nil
			t.Check("the flash's cell, white and unlit", label ~= nil and label.Image == look.Touch and label.ImageRectOffset == Vector2.new(look.Cell, look.Cell) and label.ImageColor3 == Color3.new(1, 1, 1) and flashes[1].LightInfluence == 0)
			-- The server strikes the Shade on the Note: the effect takes it, once, and nothing it doesn't hit. Asked twice (the
			-- screen's own beat, then the server's hit with its number), both land on the touch's frame (fix 2).
			local struck = running.Struck
			t.Check("the effect draws its own hits", struck ~= nil)
			if struck == nil then
				running.Destroy()
				stand:Destroy()
				shade:Destroy()
				return
			end
			local clockNow = first
			local landedAt: { number } = {}
			local function landing(): () -> ()
				local index = #landedAt + 1
				landedAt[index] = -1
				return function()
					landedAt[index] = clockNow
				end
			end
			t.Check("a beat it doesn't hit on isn't its", struck("SelfTest", shade, function() end, true) == false)
			local once = struck("Note", shade, landing(), true)
			t.Check("the Note's is, asked twice", once and struck("Note", shade, landing(), false))
			t.Check("nothing lands before the crest is thrown", landedAt[1] == -1 and landedAt[2] == -1)
			at(first)
			t.Near("the Note's flash", flashSize() or -1, flash.Note[1], 0.001)
			at(first + 1.5 * FRAME)
			t.Near("and the frame after", flashSize() or -1, flash.Note[2], 0.001)
			at(first + 2.5 * FRAME)
			t.Check("kept a step past its last frame, drawn a picture late (AR8 A)", flashSize() ~= nil)
			at(first + 2.5 * FRAME)
			t.Check("then out", flashSize() == nil)
			local beams = mine("Beam")
			t.Check("one crest: two Beams", #beams == 2, `{#beams}`)
			local foundRibbon: Beam?, foundVeil: Beam? = nil, nil
			for _, each in beams do
				if each:IsA("Beam") and each.Texture == look.Ribbon then
					foundRibbon = each
				elseif each:IsA("Beam") and each.Texture == look.Veil then
					foundVeil = each
				end
			end
			t.Check("the ribbon and the veil", foundRibbon ~= nil and foundVeil ~= nil)
			if foundRibbon == nil or foundVeil == nil then
				running.Destroy()
				stand:Destroy()
				shade:Destroy()
				return
			end
			local ribbon, veil = foundRibbon :: Beam, foundVeil :: Beam
			t.Check("the ribbon over the veil", ribbon.ZOffset > veil.ZOffset)
			for _, beam in { ribbon, veil } do
				t.Check(`{beam.Texture == look.Ribbon and "ribbon" or "veil"}: upright, stretched, still, white, unlit, on the same ends`, not beam.FaceCamera and beam.TextureMode == Enum.TextureMode.Stretch and beam.TextureSpeed == 0 and beam.LightInfluence == 0 and beam.Color.Keypoints[1].Value == Color3.new(1, 1, 1) and beam.Segments == look.Segments and beam.Attachment0 == ribbon.Attachment0 and beam.Attachment1 == ribbon.Attachment1)
			end
			-- Frame by frame from the Note: the crest's place by its age, and the touch on the frame it comes within Short.
			local life = (beats.Crest2 - first) * 2 ^ (1 / look.Ease)
			local function outAt(frames: number): number
				local u = frames * FRAME / life
				return look.From + (note.Reach - look.From) * (1 - (1 - u) ^ look.Ease)
			end
			local touchedAt: number? = nil
			local point = Vector3.new(origin.X, 0, origin.Z) - Vector3.new(0, 0, -1) * apex
			for frames = 1, 30 do
				clockNow = first + frames * FRAME
				at(clockNow)
				if touchedAt == nil and shadeRoot:FindFirstChildOfClass("BillboardGui") then
					touchedAt = frames
				end
				if frames == 6 then
					local out = outAt(frames)
					local radius = out + apex
					local a0, a1 = ribbon.Attachment0 :: Attachment, ribbon.Attachment1 :: Attachment
					local p0, p1 = a0.WorldPosition, a1.WorldPosition
					local flat0, flat1 = Vector3.new(p0.X, 0, p0.Z) - point, Vector3.new(p1.X, 0, p1.Z) - point
					t.Near("at 6 frames, the first end on the radius", flat0.Magnitude, radius, 0.01)
					t.Near("and the second", flat1.Magnitude, radius, 0.01)
					t.Near("across twice the cone", math.deg(math.acos(math.clamp(flat0.Unit:Dot(flat1.Unit), -1, 1))), 2 * math.deg(cone), 0.05)
					t.Check("the first end on her left", p0.X < p1.X, string.format("%.2f, %.2f", p0.X, p1.X))
					t.Near("at the height by its age", p0.Y, origin.Y - 3 + look.Up - look.Fall * (out - look.From), 0.01)
					local curve = 4 / 3 * math.tan(cone / 2) * radius
					t.Near("CurveSize as the table: 0.2834 x radius at 24 degrees", ribbon.CurveSize0, curve, 0.001)
					t.Near("at both ends", ribbon.CurveSize1, curve, 0.001)
					local c0 = p0 + a0.WorldCFrame.RightVector * ribbon.CurveSize0
					local c1 = p1 - a1.WorldCFrame.RightVector * ribbon.CurveSize1
					local middle = p0 * 0.125 + c0 * 0.375 + c1 * 0.375 + p1 * 0.125
					t.Near("an arc: its middle on the radius too", (Vector3.new(middle.X, 0, middle.Z) - point).Magnitude, radius, 0.01 * radius)
					t.Near("its width by its age", ribbon.Width0, (look.Tall + look.Grow * (out - look.From)) * look.Width, 0.001)
					local was = look.Width
					look.Width = was * 2
					at(first + frames * FRAME)
					local wide = ribbon.Width0
					look.Width = was
					at(first + frames * FRAME)
					t.Near("times Config's Width, live", wide, (look.Tall + look.Grow * (out - look.From)) * was * 2, 0.001)
				end
				if frames == look.VeilHold + look.VeilFade then
					t.Near("the veil gone after its hold and fade", veil.Transparency.Keypoints[1].Value, 1, 0.001)
					t.Check("the ribbon still on", ribbon.Transparency.Keypoints[1].Value < 1)
				end
			end
			t.Check("the Shade touched", touchedAt ~= nil)
			if touchedAt then
				local due = away - look.Hit.Short
				t.Check("on the frame the crest comes within Short of it", outAt(touchedAt) >= due and outAt(touchedAt - 1) < due, `frame {touchedAt}`)
				local guis = 0
				for _, each in shadeRoot:GetChildren() do
					if each:IsA("BillboardGui") then
						guis += 1
					end
				end
				t.Check("once, though struck twice", guis == 1, `{guis}`)
				local touchClock = first + touchedAt * FRAME
				t.Check("both askings landed on the touch's frame, not the beat's", landedAt[1] == touchClock and landedAt[2] == touchClock, `{landedAt[1]}, {landedAt[2]} against {touchClock}`)
				local late = false
				struck("Note", shade, function()
					late = true
				end, false)
				t.Check("asked after the touch, it lands at once", late)
				local gui = shadeRoot:FindFirstChildOfClass("BillboardGui") :: BillboardGui
				local cellLabel = gui:FindFirstChildOfClass("ImageLabel")
				t.Near("its size", gui.Size.X.Scale, look.Hit.Size, 0.001)
				t.Near("toward the camera", gui.StudsOffset.Z, look.Hit.Toward, 0.001)
				t.Check("its cells' picture, white and unlit", cellLabel ~= nil and cellLabel.Image == look.Touch and cellLabel.ImageColor3 == Color3.new(1, 1, 1) and gui.LightInfluence == 0)
			end
			-- Cut short with a hit still on its way (she's knocked down): it lands then, so its number isn't lost.
			local cut = Effects.HeldNote(beats, stand, function(): BasePart?
				return shadeRoot
			end, action)
			local cutLanded = false
			if cut.Struck then
				cut.Struck("Note", shade, function()
					cutLanded = true
				end, true)
			end
			cut.Step(first, first)
			t.Check("cut short before its crest reaches the body", not cutLanded)
			cut.Destroy()
			t.Check("what waited lands as it's cut short", cutLanded)
			-- Done: the last crest out, nothing left on the stand-in or in the effects.
			local done = not running.Step(action.Length + 2, action.Length + 2)
			t.Check("done after the last crest", done)
			t.Check("nothing left", #mine("Beam") == 0 and #mine("BasePart") == 0 and #mine("BillboardGui") == 0)
			local onRings = 0
			for _, ring in root:GetChildren() do
				onRings += #ring:GetChildren()
			end
			t.Check("the rings bare", onRings == 0, `{onRings}`)
			t.Wait(4 * look.Hit.Frames * FRAME + 0.1)
			t.Check("the touch over after its four cells", shadeRoot:FindFirstChildOfClass("BillboardGui") == nil)
			-- The heal's ring round a body: flat, its cell, as wide as the table says, from its floor up; then gone.
			Effects.HealRing(shadeRoot)
			local plate = mine("BasePart")[1] :: BasePart?
			local surface = if plate then plate:FindFirstChildOfClass("SurfaceGui") else nil
			local healLabel = if surface then surface:FindFirstChildOfClass("ImageLabel") else nil
			t.Check("a ring", plate ~= nil and surface ~= nil and healLabel ~= nil)
			if plate and surface and healLabel then
				local heal = look.Heal
				t.Check("flat, its cell, white and unlit", surface.Face == Enum.NormalId.Top and healLabel.ImageRectOffset == Vector2.new(0, look.Cell) and healLabel.ImageColor3 == Color3.new(1, 1, 1) and surface.LightInfluence == 0)
				t.Near("radius x 2 / Drawn across", plate.Size.X, heal.Radius * 2 / heal.Drawn, 0.001)
				t.Near("its floor's From up", plate.Position.Y, shadeRoot.Position.Y - 3 + heal.From, 0.001)
			end
			t.Wait(look.Heal.Frames * FRAME + 0.1)
			t.Check("and gone", #mine("BasePart") == 0)
			stand:Destroy()
			shade:Destroy()
		end,
	},
	{
		Name = "Fight: a flurry is one counting number on each body; it counts up, pops, and fades from its last hit",
		Run = function(t: any)
			-- docs/ui.md, "Damage numbers"; TR3: a flurry merges into one counting number (AR4, section 10, fix 1). On a stand-in
			-- body: one press's three hits make one number that counts to their whole, swells on each and settles, and fades from
			-- the last; another press's is its own; a critical after makes it the critical (larger, cream to gold, in the face's
			-- italic, its stroke behind it); a dodge is one grey word on its pointer; a heal says its plus; an element's number
			-- is in the element's colour, a received one in its own; every outline grows with the layer.
			local numbers = Combat.Numbers
			local styles = HudConfig.Numbers.Styles
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
			root.CFrame = CFrame.new(0, 600, 0)
			root.Parent = workspace
			local counting = Effects.Counting
			local function keys(): number
				local n = 0
				for _ in counting[root] or {} do
					n += 1
				end
				return n
			end
			local function of(key: string)
				return if counting[root] then counting[root][key] else nil
			end
			local function first(key: string): TextLabel?
				local c = of(key)
				return if c then c.Row:FindFirstChild("C1") :: TextLabel? else nil
			end
			Effects.Number(root, "SelfTest@1", 37, { Style = "Dealt" }, numbers)
			local one = of("SelfTest@1")
			t.Check("the first hit's number", one ~= nil and one.Text == "37" and one.Row:GetAttribute("Text") == "37", if one then one.Text else "none")
			if one == nil then
				root:Destroy()
				return
			end
			local c1 = first("SelfTest@1")
			local stroke = if c1 then c1:FindFirstChildOfClass("UIStroke") else nil
			t.Check("in the plain hit's colour", c1 ~= nil and c1.TextColor3 == styles.Dealt.Colour, if c1 then tostring(c1.TextColor3) else "no digit")
			-- AR44: the plain numbers in their own face (take B, research's pick), outline, gap and soft shadow.
			local plain = styles.Dealt
			local function wears(label: TextLabel?, family: string?, weight: string?): boolean
				return label ~= nil and label.FontFace.Family == (family or HudConfig.Numbers.Face) and label.FontFace.Weight == (Enum.FontWeight :: any)[weight or "ExtraBold"]
			end
			t.Near("its outline authored, grown by the layer's UIScale alone", if stroke then stroke.Thickness else 0, plain.Weight, 0.01)
			t.Check("in the plain numbers' face and weight", wears(c1, plain.Face, plain.Font), if c1 then `{c1.FontFace.Family} {c1.FontFace.Weight.Name}` else "no digit")
			local pad = if c1 then c1:FindFirstChildOfClass("UIPadding") else nil
			t.Near("spaced by its gap, in its own digit (a whole pixel)", if pad then pad.PaddingRight.Offset else 0, plain.Gap * (plain.Digit or HudConfig.Numbers.Digit) * (one.Row:GetAttribute("Size") :: number), 0.5)
			local shadow = Digits.Shadows[one.Row]
			local under = if shadow then shadow:FindFirstChild("C1") :: TextLabel? else nil
			local soft = HudConfig.Numbers.Shadow
			if plain.Shadow then
				t.Check("its soft shadow under it: the same digits, offset, in the shadow's colour", shadow ~= nil and shadow.Parent == one.Row.Parent and shadow.ZIndex < one.Row.ZIndex
					and shadow:GetAttribute("Text") == nil and under ~= nil and under.Text == "3" and under.TextColor3 == soft.Colour
					and shadow.Position.X.Offset == soft.Offset.X and shadow.Position.Y.Offset == soft.Offset.Y, if shadow then shadow.Name else "no shadow")
				t.Near("and see-through as Config says", if under then under.TextTransparency else 0, soft.Transparency, 0.01)
			else
				t.Check("no shadow", shadow == nil)
			end
			t.Near("unswollen", one.Scale.Scale, 1, 0.001)
			t.Wait(numbers.Seconds * 0.5)
			-- The swell lasts the count, so it's read off every frame drawn over it: one sample could land past it after a
			-- long frame in the full suite.
			local swell = 1
			local watch = RunService.RenderStepped:Connect(function()
				swell = math.max(swell, one.Scale.Scale)
			end)
			Effects.Number(root, "SelfTest@1", 37, { Style = "Dealt" }, numbers)
			Effects.Number(root, "SelfTest@1", 40, { Style = "Dealt" }, numbers)
			t.Check("the press's next hits join it", keys() == 1 and one.Count.Total == 114, `{keys()} numbers, {one.Count.Total}`)
			t.Wait(numbers.Count + 0.05)
			watch:Disconnect()
			t.Check("it swells as it counts", swell > 1.02, string.format("%.3f at most", swell))
			t.Check("counted up to the whole", one.Text == "114" and one.Row:GetAttribute("Text") == "114", one.Text)
			t.Near("and settled", one.Scale.Scale, 1, 0.001)
			t.Check("its fade starts over from the last hit", one.Fade < 0.05, string.format("%.2f", one.Fade))
			Effects.Number(root, "SelfTest@2", 9, { Style = "Dealt" }, numbers)
			t.Check("another press is its own number", keys() == 2)
			Effects.Number(root, "SelfTest@1", 50, { Style = "Critical" }, numbers)
			local critical = HudConfig.Numbers.Critical
			c1 = first("SelfTest@1")
			local gradient = if c1 then c1:FindFirstChildOfClass("UIGradient") else nil
			t.Check("a critical after makes it the critical, its stroke behind", one.Style == "Critical" and one.Big and one.Sweep ~= nil, `{one.Style}, sweep {one.Sweep ~= nil}`)
			t.Near("larger by the critical's size", one.Row:GetAttribute("Size") :: number, numbers.Size * critical.Size, 0.01)
			t.Check("its run of hues, head to foot (AR44's yellow)", gradient ~= nil and gradient.Color.Keypoints[1].Value == critical.Top and gradient.Color.Keypoints[#gradient.Color.Keypoints].Value == critical.Foot
				and (critical.Ramp == nil or #gradient.Color.Keypoints == #critical.Ramp.Keypoints), if gradient then `{#gradient.Color.Keypoints} stops` else "no gradient")
			t.Check("in the face's italic, or upright as Config says", c1 ~= nil and (c1.FontFace.Style == Enum.FontStyle.Italic) == critical.Italic)
			-- Its own face; and its hard cast onto the splash, not the plain numbers' soft shadow (the director, 2026-11-19).
			local cast = Digits.Shadows[one.Row]
			local castDigit = if cast then cast:FindFirstChild("C1") :: TextLabel? else nil
			t.Check("the critical keeps its own face", c1 ~= nil and c1.FontFace.Family == HudConfig.Numbers.Face, if c1 then c1.FontFace.Family else "no digit")
			if critical.Cast.On then
				t.Check("its digits cast hard and dark onto the splash, down and right", cast ~= nil and castDigit ~= nil and castDigit.TextColor3 == critical.Cast.Colour
					and cast.Position.X.Offset == critical.Cast.Offset.X and cast.Position.Y.Offset == critical.Cast.Offset.Y and castDigit.TextTransparency < 0.05
					and one.Sweep ~= nil and cast.ZIndex > one.Sweep.ZIndex, if cast then `{cast.Position}` else "no cast")
			else
				t.Check("no cast", cast == nil)
			end
			t.Wait(numbers.Count + 0.05)
			t.Near("settled", one.Scale.Scale, 1, 0.001)
			local sweep = one.Sweep
			t.Near("its stroke as clear as Config says", if sweep then sweep.ImageTransparency else 1, critical.Sweep.Transparency, 0.02)
			t.Check("in Config's tint", sweep ~= nil and sweep.ImageColor3 == critical.Sweep.Tint)
			do -- laid on the row's real width, so its head sits behind the first digit as drawn (AR44)
				local across = one.Plate.AbsoluteSize.X / one.Plate.Size.X.Offset -- absolute pixels to the plate's own
				local before = if sweep then (one.Row.AbsolutePosition.X - sweep.AbsolutePosition.X) / across else 0
				local want = critical.Sweep.Left * HudConfig.Numbers.Digit * (one.Row:GetAttribute("Size") :: number)
				t.Near("its splash starts Left digits before the row's real first digit", before, want, 1.5)
			end
			Effects.Number(root, "SelfTest:word", nil, { Style = "Word", Word = "Dodge" }, numbers)
			Effects.Number(root, "SelfTest:word", nil, { Style = "Word", Word = "Dodge" }, numbers)
			local word = of("SelfTest:word")
			t.Check("a dodge is one grey word on its pointer", keys() == 3 and word ~= nil and word.Text == "Dodge" and word.Pointer ~= nil, if word then word.Text else "none")
			local said = if word then word.Row:FindFirstChild("C1") :: TextLabel? else nil
			t.Check("the word keeps its own face, with no shadow (AR44)", said ~= nil and said.FontFace.Family == HudConfig.Numbers.Face and word ~= nil and Digits.Shadows[word.Row] == nil)
			Effects.Number(root, "SelfTest:heal", 12, { Style = "Heal" }, numbers)
			local heal = of("SelfTest:heal")
			t.Check("a heal says its plus", heal ~= nil and heal.Text == "+12", if heal then heal.Text else "none")
			local element, colour = "Fire", UIKit.Elements.Fire
			Effects.Number(root, "SelfTest@1:element", 8, { Style = "Element", Colour = colour }, numbers)
			local tinted = first("SelfTest@1:element")
			t.Check(`an element's number in its colour ({element})`, tinted ~= nil and tinted.TextColor3 == colour)
			Effects.Number(root, "SelfTest:mine", 20, { Style = "Received" }, numbers)
			local mine = first("SelfTest:mine")
			t.Check("a received number in its own colour", mine ~= nil and mine.TextColor3 == styles.Received.Colour)
			t.Check("received and healing wear the plain face, and an element's number", wears(mine, styles.Received.Face, styles.Received.Font)
				and wears(first("SelfTest:heal"), styles.Heal.Face, styles.Heal.Font) and wears(tinted, styles.Element.Face, styles.Element.Font))
			-- A comma or a "1" keeps no whole digit's gap about it (AR44's verdict, fix 2): 1,204's spaces.
			Effects.Number(root, "SelfTest:comma", 1204, { Style = "Dealt" }, numbers)
			local comma = of("SelfTest:comma")
			local function padOf(i: number): number
				local label = if comma then comma.Row:FindFirstChild(`C{i}`) else nil
				local after = if label then label:FindFirstChildOfClass("UIPadding") else nil
				return if after then after.PaddingRight.Offset else -1
			end
			t.Check("1,204: about its comma a comma's share of the gap, between digits a whole one, none after the last", comma ~= nil and comma.Text == "1,204"
				and padOf(1) >= 0 and padOf(1) < padOf(3) * 0.5 and padOf(2) >= 0 and padOf(2) < padOf(3) * 0.5 and padOf(3) > 0 and padOf(5) == 0,
				`{padOf(1)}, {padOf(2)}, {padOf(3)}, {padOf(4)}, {padOf(5)}`)
			t.Check("seven numbers up at once", keys() == 7, `{keys()}`)
			t.Wait(numbers.Seconds + 0.1)
			t.Check("all gone a fade after their last", counting[root] == nil, `{keys()} left`)
			-- A lone critical lands swollen to the pop, its splash with it, and settles over the count (AR44, research's
			-- second look); a plain number lands whole ("unswollen", above).
			Effects.Number(root, "SelfTest@9", 1204, { Style = "Critical" }, numbers)
			local lone = of("SelfTest@9")
			t.Near("a lone critical lands swollen to the pop", if lone then lone.Scale.Scale else 0, if critical.Land then numbers.Pop else 1, 0.001)
			t.Check("its splash inside what swells", lone ~= nil and lone.Sweep ~= nil and lone.Sweep.Parent == lone.Scale.Parent)
			t.Wait(numbers.Count + 0.05)
			t.Near("and settles over the count", if lone then lone.Scale.Scale else 0, 1, 0.001)
			t.Wait(numbers.Seconds)
			root:Destroy()
		end,
	},
	{
		Name = "HUD: experience has one colour: the level-up's sleeve is the thread's blue, the column fades to it",
		Run = function(t: any)
			-- Research on TR3's three calls (2026-11-13): the light takes the card's thread's blue as it is (a beam, unlit by
			-- the scene: AR8 C). The words are the HUD's notice now (TR41 (c)). On a stand-in body.
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
			root.CFrame = CFrame.new(0, 600, 0)
			root.Parent = workspace
			local look = EffectsConfig.LevelUp
			local xp = HudConfig.Card.Xp
			local column, sleeve = Effects.LevelUp(root)
			local k = sleeve.Color.Keypoints
			t.Check("the sleeve is the thread's blue, all along it", k[1].Value:ToHex() == xp:ToHex() and k[#k].Value:ToHex() == xp:ToHex(), k[1].Value:ToHex())
			t.Check("both unlit by the scene", column.LightInfluence == 0 and sleeve.LightInfluence == 0)
			-- Research's pass on Modulo's column picture (AR8 C, fix 2): the column wears it, white at its peak, and its
			-- colour goes to the thread's blue as it fades, so the fade never reads grey. Watched every frame it shows.
			t.Check("the column wears its picture, stretched once along it", column.Texture == look.Column.Picture and column.TextureMode == Enum.TextureMode.Stretch and column.TextureLength == 1)
			local function near(a: Color3, b: Color3): number
				return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B)
			end
			local white = Color3.new(1, 1, 1)
			local brightest, atBrightest, peaked, lastFaint = 0, white, false, nil :: Color3?
			local watch = RunService.RenderStepped:Connect(function()
				local o = column:GetAttribute("Opaque")
				if column:IsDescendantOf(game) and column.Enabled and type(o) == "number" and o > 0 then
					local colour = column.Color.Keypoints[1].Value
					if o >= brightest then
						brightest, atBrightest = o, colour
					elseif o < brightest * 0.3 then
						peaked, lastFaint = true, colour
					end
				end
			end)
			t.Wait(look.Column.Seconds + 0.1)
			watch:Disconnect()
			t.Check("white at its brightest", near(atBrightest, white) < 0.15, atBrightest:ToHex())
			t.Check("the thread's blue as it fades", peaked and lastFaint ~= nil and near(lastFaint, xp) < near(lastFaint, white), if lastFaint then lastFaint:ToHex() else "never faint")
			t.Wait(0.2)
			t.Check("all gone after the effect", not column:IsDescendantOf(game) and not sleeve:IsDescendantOf(game))
			root:Destroy()
		end,
	},
	{
		Name = "Effects: the level-up is light that rises: a column out of the feet past the head, its foot after, gone by its seconds",
		Run = function(t: any)
			-- AR8 C, part 4 (rule 3): the main shape stands up out of the feet past the head, brightest in the first quarter
			-- of its life; its foot then leaves the ground and climbs after its top; the sleeve comes a breath later, wider and
			-- fainter, over the body. Solid light: one part each, nothing falls (the
			-- content check's condition 2). Sized by the lead: a stand-in body whose hat stands as tall as Pip's, sampled
			-- every frame.
			local body = Instance.new("Model")
			body.Name = "SelfTestLead"
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
			root.CFrame = CFrame.new(0, 600, 0)
			root.Parent = body
			local feet = 600 - 3 + 0.1 -- R6: the root stands 3 studs over the feet
			local tall = 7.5 -- Pip, hat and all
			local hat = Instance.new("Part")
			hat.Name = "Hat"
			hat.Anchored, hat.CanCollide, hat.CanQuery, hat.Transparency = true, false, false, 1
			hat.Size = Vector3.one
			hat.CFrame = CFrame.new(0, feet + tall - 0.5, 0)
			hat.Parent = body
			body.PrimaryPart = root
			body.Parent = workspace
			local look = EffectsConfig.LevelUp
			local c = look.Column
			local born = os.clock()
			local column, sleeve = Effects.LevelUp(root)
			local brightest, brightestAt, highest, footAt, lowestFoot = 1, -1, -math.huge, -1, math.huge
			local sleeveFirst, sleeveWidest, columnWidest, sleeveOpaque = -1, 0, 0, 0
			local footLast = -math.huge
			local fell = false
			local function opaque(beam: Beam): number
				local o = beam:GetAttribute("Opaque")
				return if beam:IsDescendantOf(game) and beam.Enabled and type(o) == "number" then o else 0
			end
			local soft, faded = true, true
			local watch = RunService.RenderStepped:Connect(function()
				local age = os.clock() - born
				local o = opaque(column)
				if o > 0 then
					local foot = (column.Attachment0 :: Attachment).WorldPosition.Y - feet
					local top = (column.Attachment1 :: Attachment).WorldPosition.Y - feet
					highest = math.max(highest, top)
					lowestFoot = math.min(lowestFoot, foot)
					if foot < footLast - 0.01 then
						fell = true
					end
					footLast = foot
					if foot > 0.3 and footAt < 0 then
						footAt = age
					end
					if 1 - o < brightest then
						brightest, brightestAt = 1 - o, age
					end
					columnWidest = math.max(columnWidest, column.Width0)
					local k = column.Transparency.Keypoints
					if o > 0.2 then
						soft = soft and k[1].Value > 1 - o + 0.05 -- its foot softer than its body
					end
					faded = faded and k[#k].Value >= 0.999 -- and nothing at its top
				end
				local so = opaque(sleeve)
				if so > 0 then
					if sleeveFirst < 0 then
						sleeveFirst = age
					end
					sleeveWidest = math.max(sleeveWidest, sleeve.Width0)
					sleeveOpaque = math.max(sleeveOpaque, so)
				end
			end)
			t.Wait(c.Seconds + 0.1)
			t.Check("the column is gone by its seconds", opaque(column) == 0, `{opaque(column)}`)
			t.Wait(0.1)
			watch:Disconnect()
			body:Destroy()
			t.Check("it stands out of the feet", lowestFoot < 0.3, string.format("its foot at %.2f studs", lowestFoot))
			t.Check("past the head: its Over past the lead's top, hat and all", highest >= tall + c.Over - 0.05, string.format("its top at %.2f studs, the lead %.1f", highest, tall))
			t.Near("as wide as its share of the lead's height", columnWidest, tall * c.Wide, 0.05)
			t.Check("drawn in segments enough to show its soft foot and its fade", column.Segments >= 10 and sleeve.Segments >= 10, `{column.Segments}, {sleeve.Segments}`)
			t.Check("the sleeve lies over the body", sleeve.ZOffset == look.Sleeve.Front and look.Sleeve.Front > 0, `{sleeve.ZOffset}`)
			t.Check("brightest in the first quarter of its life, or near it", brightestAt >= 0 and brightestAt <= c.Seconds * 0.3, string.format("at %.3f s", brightestAt))
			t.Check("at its Opaque at its brightest, never a solid", math.abs((1 - brightest) - c.Opaque) < 0.05 and c.Opaque < 1, string.format("%.2f", 1 - brightest))
			t.Check("soft at its foot and gone at its top: light, not a shape", soft and faded)
			t.Check("its foot leaves the ground after the peak", footAt > brightestAt, string.format("foot off at %.3f s, peak %.3f s", footAt, brightestAt))
			t.Check("nothing falls: the foot only climbs", not fell)
			t.Check("the sleeve a breath later", sleeveFirst >= look.Sleeve.Delay - 0.02, string.format("at %.3f s", sleeveFirst))
			t.Check("wider", sleeveWidest > columnWidest, string.format("%.2f against %.2f", sleeveWidest, columnWidest))
			t.Check("and fainter", sleeveOpaque <= look.Sleeve.Alpha + 0.01, string.format("%.2f", sleeveOpaque))
			t.Check("all gone after", not column:IsDescendantOf(game) and not sleeve:IsDescendantOf(game))
		end,
	},
	{
		Name = "World: an open plate stands in the sky between the top band's pieces, and under any piece it crosses",
		Run = function(t: any)
			-- Research's pass on AR8 C, fix 1: the level-up's word over the lead's head, free in the sky between the lead's
			-- card and the pills, never over one. A stand-in plate whose top is above the band, set in the gap and then
			-- under the Electricity pill, out of a fight (the target's card hidden).
			t.Wait(LEAD_SETTLE)
			local world = Layers.Get("World")
			local band = world:GetAttribute("Band")
			local camera = workspace.CurrentCamera
			local parts = HudController.Parts()
			t.Check("the HUD sets the band", type(band) == "number", tostring(band))
			t.Check("out of a fight: the target's card hidden", not parts.Target.Visible)
			if type(band) ~= "number" or camera == nil or parts.Target.Visible then
				return
			end
			-- Points are set in the viewport, a GUI pixel plus the top bar's inset; the band is in the World layer's authored
			-- pixels from its corner.
			local origin, scale = world.AbsolutePosition, Layers.Scale()
			local inset = GuiService:GetGuiInset()
			local function authored(gui: Vector2): Vector2
				return (gui - origin) / scale
			end
			local lead, pill = parts.Lead, (parts.Electricity :: GuiObject).Parent :: GuiObject
			local size = Vector2.new(60, 30)
			local leadRight = lead.AbsolutePosition.X + lead.AbsoluteSize.X
			t.Check("room in the gap for it", pill.AbsolutePosition.X - leadRight > (size.X + 2 * HudConfig.Numbers.Band) * scale)
			local x = (leadRight + pill.AbsolutePosition.X) / 2 + inset.X
			local foot = (band - size.Y / 2) * scale + origin.Y + inset.Y -- its foot half a plate over the band
			local plate = World.Plate("SelfTestOpen", size, function(): Vector3?
				local ray = camera:ViewportPointToRay(x, foot)
				return ray.Origin + ray.Direction * 20
			end)
			World.Below(plate, true)
			t.Wait(0.1)
			local stands = Vector2.new(plate.AbsolutePosition.X + plate.AbsoluteSize.X / 2, plate.AbsolutePosition.Y + plate.AbsoluteSize.Y)
			local point = Vector2.new(x, foot) - inset
			t.Check("it stands on its point: a viewport pixel less the top bar's inset", (stands - point).Magnitude < 1, `{stands} against {point}`)
			local top = authored(plate.AbsolutePosition).Y
			t.Check("in the gap it keeps its place, over the band", top < band - size.Y / 4, string.format("its top at %.1f, the band %.1f", top, band))
			t.Check("and under the top bar", plate.AbsolutePosition.Y >= Layers.Get("Hud").AbsolutePosition.Y - 0.5)
			x = pill.AbsolutePosition.X + pill.AbsoluteSize.X / 2 + inset.X
			t.Wait(0.1)
			local pillFoot = authored(pill.AbsolutePosition + pill.AbsoluteSize).Y
			top = authored(plate.AbsolutePosition).Y
			t.Check("under the pill when it can't slide clear within its room", top >= pillFoot + HudConfig.Numbers.Band - 0.5, string.format("its top at %.1f, the pill's foot %.1f", top, pillFoot))
			-- One that crosses a piece's side by a little slides aside, eased, held under it until it's clear, and then rises
			-- back, eased, to its own height: two eases, each about 4 / Rate to its last pixel.
			local margin, settle = HudConfig.Numbers.Band, 8 / HudConfig.Numbers.Slide.Rate + 0.1
			local function beside(piece: GuiObject, label: string)
				local side = authored(piece.AbsolutePosition).X - margin -- its span's left
				local edge = authored(piece.AbsolutePosition + piece.AbsoluteSize).Y + margin -- its span's edge
				x = (side - size.X / 2 + 10) * scale + origin.X + inset.X -- crossing it by 10
				local over, overlapped = math.huge, false
				local watch = RunService.RenderStepped:Connect(function()
					if plate.Visible and authored(plate.AbsolutePosition + plate.AbsoluteSize).X > side + 0.5 then
						overlapped = true
						over = math.min(over, authored(plate.AbsolutePosition).Y - edge)
					end
				end)
				t.Wait(settle)
				watch:Disconnect()
				t.Check(`held under {label} while it still crosses it, mid-slide too`, not overlapped or over >= -0.5, if overlapped then string.format("%.1f px under its edge at its closest", over) else "clear from its first frame")
				local right = authored(plate.AbsolutePosition + plate.AbsoluteSize).X
				local stood = authored(plate.AbsolutePosition).Y
				local was = authored(Vector2.new(0, foot) - inset).Y - size.Y
				t.Check(`it slides aside, clear of {label}, to a pixel's rounding`, right <= side + 1.5, string.format("its right at %.1f, the side %.1f", right, side))
				t.Check(`and keeps its height beside {label}`, math.abs(stood - was) < 1, string.format("its top at %.1f, its own %.1f", stood, was))
			end
			beside(pill, "the pill")
			Toast.Show("Self-test: a plate stands aside")
			t.Wait(HudConfig.Motion.Toast.Enter)
			local stack = Toast.Stack()
			t.Check("a toast's stack shows", stack ~= nil)
			if stack then
				foot = stack.AbsolutePosition.Y + stack.AbsoluteSize.Y / 2 + inset.Y -- its foot at the stack's middle
				beside(stack, "a toast")
			end
			World.Remove(plate)
			t.Wait(Theme.Time.Toast + HudConfig.Motion.Toast.Exit) -- the toast leaves
		end,
	},
	{
		Name = "HUD: a number born at the top band stays under it its whole life",
		Run = function(t: any)
			-- TR3's verdict, fix 4: under the cards' and the pills' lower edge plus a margin, its rise and swell included; one
			-- born near it starts lower or rises less. A critical (the largest) on a stand-in body whose point is just under
			-- the band, on the lead card's side, watched every frame it shows.
			t.Wait(LEAD_SETTLE)
			local world = Layers.Get("World")
			local band = world:GetAttribute("Band")
			t.Check("the HUD sets the band", type(band) == "number", tostring(band))
			local camera = workspace.CurrentCamera
			if type(band) ~= "number" or camera == nil then
				return
			end
			local numbers = Combat.Numbers
			local ray = camera:ViewportPointToRay(camera.ViewportSize.X * 0.2, band * Layers.Scale() + 4)
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
			root.Position = ray.Origin + ray.Direction * 24 - Vector3.new(0, 3, 0)
			root.Parent = workspace
			local key = "SelfTest@band"
			local closest, frames = math.huge, 0
			local watch = RunService.RenderStepped:Connect(function()
				local c = Effects.Counting[root] and Effects.Counting[root][key]
				local edge = world:GetAttribute("Band")
				if c and c.Plate.Visible and type(edge) == "number" then
					frames += 1
					closest = math.min(closest, (c.Plate.AbsolutePosition.Y - world.AbsolutePosition.Y) / Layers.Scale() - edge)
				end
			end)
			Effects.Number(root, key, 12345, { Style = "Critical" }, numbers)
			t.Wait(numbers.Seconds * 0.5)
			Effects.Number(root, key, 678, { Style = "Critical" }, numbers) -- a second hit: it swells as it counts
			t.Wait(numbers.Seconds + 0.1)
			watch:Disconnect()
			root:Destroy()
			t.Check("it showed", frames > 10, `{frames} frames`)
			t.Check("never over the band, its rise and swell included", closest >= -1, string.format("%.1f px under it at its closest", closest))
		end,
	},
	{
		-- TR40, Regen in bursts (the director, 2026-11-17): a lead under full heals one burst every Config.Stats.Regen.Every
		-- seconds, its size Rules.Stats.Burst of its Regen, and a small pop at its chest (Effects.RegenPop). Its number reads on
		-- its owner's HUD, on the lead's own bar: the band in the heal's green and "+N" after the digits (research's must-fix),
		-- never in the world among the hits. At full, none, and nothing shows.
		Name = "Fight: TR40, a lead's Regen in bursts: one every 8 s at its size, on the lead's bar with its +N and a small pop, and none at full",
		Run = function(t: any)
			local lead = myLead()
			local view = ProfileController.Get()
			t.Check("the lead is out", lead ~= nil and view ~= nil)
			if lead == nil or view == nil then
				return
			end
			local owned = view.Voidkin[view.Roles.Lead]
			local block = Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any)
			local size = Stats.Burst(block.Regen)
			local every = StatsConfig.Regen.Every
			local root = lead:FindFirstChild("HumanoidRootPart") :: BasePart
			local bursts: { { At: number, Amount: number } } = {}
			local onHeal = Net.Client.On("Heal", function(heal: any)
				if type(heal) == "table" and heal.T == lead and heal.Regen == true and type(heal.Amount) == "number" then
					table.insert(bursts, { At = os.clock(), Amount = heal.Amount })
				end
			end)
			local parts = HudController.Parts()
			local band, gain = parts.LeadHealBand, parts.LeadHealGain :: TextLabel
			local popped, banded, plus, inWorld = false, false, "", false
			local watch = RunService.RenderStepped:Connect(function()
				local home = workspace:FindFirstChild("NL_Effects")
				local pop = if home then home:FindFirstChild("RegenPop") else nil
				if pop and pop:IsA("BasePart") and (pop.Position - root.Position).Magnitude < 2 then
					popped = true
				end
				if band.Visible and band.BackgroundTransparency < 0.9 then
					banded = true
				end
				if gain.Visible then
					plus = gain.Text
				end
				local keyed = Effects.Counting[root]
				if keyed and keyed.regen then
					inWorld = true
				end
			end)
			t.Server("FightHealth", 0.5)
			-- Two bursts, 8 s apart, each its size: the timer runs from the summon, so the first may come at any moment.
			local two = waitFor(t, every * 2 + 1, function(): boolean
				return #bursts >= 2
			end)
			t.Check("two bursts while under full", two, `{#bursts}`)
			if #bursts >= 2 then
				t.Near("8 s apart", bursts[2].At - bursts[1].At, every, 0.35)
				t.Near("each its Regen's burst: the rate times 8 times a half", bursts[1].Amount, size, 0.05)
			end
			t.Check("a pop at its chest", popped)
			t.Check("the band runs on the lead's health light", banded)
			local said = if #bursts > 0 then `+{Hud.Digits(math.floor(bursts[#bursts].Amount + 0.5))}` else "?"
			t.Check("its +N after the health's digits, the burst's own", plus == said, `{plus} for {said}`)
			t.Check("in the heal's green", gain.TextColor3 == HudConfig.Card.Heal.Colour)
			t.Check("and no number in the world among the hits", not inWorld)
			-- At full: nothing for a whole beat.
			t.Server("FightHealth", 1)
			t.Wait(0.3)
			local count = #bursts
			popped = false
			t.Wait(every + 0.5)
			t.Check("at full, no burst and no pop", #bursts == count and not popped, `{#bursts - count} bursts`)
			onHeal:Disconnect()
			watch:Disconnect()
		end,
	},
	{
		Name = "Fight: the Held Note lands on each Shade in its cone, heals her, and never holds her",
		Run = function(t: any)
			-- docs/asset-requests.md, AR4, section 9: five touches, one a crest, each on every Shade inside the cone and a heal
			-- on her; her hold keeps its count (Steady), the Shades still hold; the avatar stands past the cone's 14.
			local action = Actions.ById.LyricHeldNote
			local lead = myLead()
			if lead == nil or lead:GetAttribute("Def") ~= "lyric" then
				t.Row("the lead isn't Lyric: the Held Note waits for a Lyric lead", nil, nil, nil, "")
				return
			end
			local view = FighterController.Views[lead]
			local hits: { [string]: { [string]: number } } = {}
			local steady, heals, gained = true, 0, 0
			local avatarAway: number? = nil
			local character = Players.LocalPlayer.Character
			local avatar = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			local onHit = Net.Client.On("Hit", function(hit: any)
				local struckId = if type(hit) == "table" and typeof(hit.T) == "Instance" then (hit.T :: Instance):GetAttribute("Fighter") else nil
				if type(struckId) == "string" and hit.A == lead and hit.Action == action.Id then
					local by = hits[struckId] or {}
					by[hit.Beat] = (by[hit.Beat] or 0) + 1
					hits[struckId] = by
					steady = steady and hit.Steady == true
					if avatar and avatarAway == nil then
						local root = lead:FindFirstChild("HumanoidRootPart") :: BasePart
						avatarAway = Vector3.new(avatar.Position.X - root.Position.X, 0, avatar.Position.Z - root.Position.Z).Magnitude
					end
				end
			end)
			local onHeal = Net.Client.On("Heal", function(heal: any)
				if type(heal) == "table" and heal.T == lead and heal.Regen ~= true and type(heal.Amount) == "number" then -- her heals, not her Regen's bursts (TR40)
					heals += 1
					gained += heal.Amount
				end
			end)
			-- Each frame, the numbers on screen (AR4, section 10, fixes 1 and 2): one counting number for the press on each
			-- body, the most it counted to, and whether a body's touch stood on it the frame its number came.
			local dealt: { [BasePart]: number } = {}
			local onDealt = Net.Client.On("Hit", function(hit: any)
				local root = if type(hit) == "table" and hit.A == lead and typeof(hit.T) == "Instance" then (hit.T :: Instance):FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if root and not hit.Dodged and type(hit.Total) == "number" then
					dealt[root] = (dealt[root] or 0) + hit.Total
				end
			end)
			local prefix, healPrefix = `{if view then view.Id else "?"}@`, `heal:{if view then view.Id else "?"}@`
			local mostAtOnce, mostHealsAtOnce = 0, 0
			local counted: { [BasePart]: number } = {}
			local came: { [BasePart]: boolean } = {}
			local healed = 0
			local watch = RunService.RenderStepped:Connect(function()
				for root, keyed in Effects.Counting do
					local here, healsHere, whole = 0, 0, 0
					for key, number in keyed do
						if string.sub(key, 1, #prefix) == prefix then
							-- the press's number, and its element's a beat behind it: together the hits' whole (TR3)
							here += if string.find(key, ":", #prefix, true) then 0 else 1
							whole += number.Count.Total
							if came[root] == nil then
								came[root] = root:FindFirstChild("NL_Effect") ~= nil
							end
						elseif string.sub(key, 1, #healPrefix) == healPrefix then
							healsHere += 1
							healed = math.max(healed, number.Count.Total)
						end
					end
					counted[root] = math.max(counted[root] or 0, whole)
					mostAtOnce = math.max(mostAtOnce, here)
					mostHealsAtOnce = math.max(mostHealsAtOnce, healsHere)
				end
			end)
			local began = os.clock()
			local frozenBefore = if view then view.FrozenUntil else 0
			local ok, result = pcall(function()
				local started = t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE)
				t.Server("FightSpawn", "dummy", lead:GetAttribute("Level"), 11) -- deeper in her cone than the replay's dummy
				t.Server("FightHealth", 0.5)
				return started
			end)
			t.Check("the replay starts, a second Shade in the cone, her health at half", ok and type(result) == "table" and result.Ok == true, tostring(if ok then result and result.Error else result))
			t.Wait(action.Length + 0.3)
			onHit:Disconnect()
			onHeal:Disconnect()
			onDealt:Disconnect()
			watch:Disconnect()
			local bodies, whole, withTouch = 0, true, true
			for root, total in dealt do
				bodies += 1
				whole = whole and math.abs((counted[root] or 0) - total) < 0.5
				withTouch = withTouch and came[root] == true
			end
			t.Check("one counting number a body for the press", bodies >= 2 and mostAtOnce == 1, `{bodies} bodies, at most {mostAtOnce} at once`)
			t.Check("each counted to its hits' whole", whole)
			t.Check("each came with its touch, not on the server's beat", withTouch)
			t.Check("her heals one counting number, to their whole", mostHealsAtOnce == 1 and math.abs(healed - gained) < 0.5, `{mostHealsAtOnce} at once, {healed} of {gained}`)
			local struck = 0
			for _, by in hits do
				struck += 1
				for beat in action.Hits do
					t.Check(`{beat} landed once on each`, by[beat] == 1, `{by[beat] or 0} times`)
				end
			end
			t.Check("both Shades in the cone took the crests", struck == 2, `{struck}`)
			t.Check("every touch is steady", steady)
			local most = lead:GetAttribute("MaxHealth") :: number
			t.Check("a heal on her with every crest", heals == 5, `{heals}`)
			t.Near("each a share of her most", gained, 5 * (action.Hits.Note.Heal :: number) * most, 0.5)
			t.Check("her clip never held", view ~= nil and view.FrozenUntil <= math.max(frozenBefore, began), if view then string.format("%.2f after", view.FrozenUntil - began) else "no view")
			t.Check("the avatar stands past the cone", avatarAway ~= nil and avatarAway > action.Hits.Note.Reach, tostring(avatarAway))
			t.Server("FightSpawn")
			t.Server("Replay")
			t.Wait(0.3)
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
			-- the client sees the lead aimed at the dummy, so an effect's line runs through it as in play
			local aimed = lead:GetAttribute("Target")
			local dummyId = if dummy then dummy:GetAttribute("Fighter") else nil
			t.Check("the lead is aimed at the dummy", type(aimed) == "string" and aimed ~= "" and aimed == dummyId, `{tostring(aimed)} against {tostring(dummyId)}`)
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
		-- The director, 2026-11-14, night: "simply do not touch player camera" (TR7's shoulder ease scrapped; the hit shake
		-- and the fade's turn aren't named, and stay). A fight never offsets the player's camera, in it or after it.
		Name = "Camera: a fight never offsets the player's camera, in it or after it",
		Run = function(t: any)
			local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			t.Check("the avatar is in the world", humanoid ~= nil, "no humanoid")
			if humanoid == nil then
				return
			end
			local most, fought = 0, false
			local watch = RunService.RenderStepped:Connect(function()
				most = math.max(most, humanoid.CameraOffset.Magnitude)
				local lead = myLead()
				local aimed = if lead then lead:GetAttribute("Target") else nil
				fought = fought or (type(aimed) == "string" and aimed ~= "")
			end)
			t.Server("Replay", Actions.ById.RookCombo.Id, 1.2)
			t.Wait(1.2)
			t.Server("Replay")
			t.Wait(2) -- past where the old ease would have held and come back
			watch:Disconnect()
			t.Check("the lead had a target", fought)
			t.Check("no offset, in the fight or after it", most < 1e-3, string.format("%.3f studs at most", most))
		end,
	},
	{
		-- TR11 (the director, 2026-11-14, night): the player's camera is never moved in a fight; a small eye follows the lead
		-- instead. On, the camera's point eases onto the lead with the player's own heading and distance; off, or on the
		-- lead's fall, it eases back onto the avatar; in a fade's black it's back at once.
		Name = "Camera: TR11, the eye follows the lead and comes back: off, on a fall, and in a fade's black",
		Run = function(t: any)
			local look = HudConfig.Spectate
			local eye = HudController.Parts().Spectate :: TextButton
			local camera = workspace.CurrentCamera
			local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			local lead = myLead()
			local leadRoot = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			t.Check("the eye is on the HUD", eye ~= nil and eye.Visible and eye.Parent ~= nil)
			t.Check("a whole tap target", eye.Size.X.Offset >= Theme.Size.Tap and eye.Size.Y.Offset >= Theme.Size.Tap, tostring(eye.Size))
			-- AR12: one family with the readout, its plate Right of it and Lower than its top (authored points).
			local plate = HudConfig.Readout
			local signature = HudController.Parts().Signature :: GuiObject
			local dx = (eye.Position.X.Offset - look.Plate / 2) - (signature.Position.X.Offset + plate.Size / 2)
			local dy = (eye.Position.Y.Offset - look.Plate / 2) - (signature.Position.Y.Offset - plate.Size / 2)
			t.Check("beside the signature's readout", math.abs(dx - look.Right) < 0.01 and math.abs(dy - look.Lower) < 0.01, string.format("%.1f right, %.1f lower", dx, dy))
			local shut, open = eye:FindFirstChild("Off", true), eye:FindFirstChild("On", true)
			t.Check("shut on its own plate while off", shut ~= nil and shut:IsA("ImageLabel") and shut.Visible and shut:GetAttribute("Kit") == "EyeOff"
				and open ~= nil and open:IsA("ImageLabel") and not open.Visible and open:GetAttribute("Kit") == "EyeOn")
			t.Check("off at the start", not SpectateController.On() and eye:GetAttribute("On") == false)
			if humanoid == nil or leadRoot == nil or lead == nil then
				t.Check("the avatar and its lead are out", false)
				return
			end
			local function distance(): number
				return (camera.CFrame.Position - camera.Focus.Position).Magnitude
			end
			local before, heading = distance(), camera.CFrame.LookVector
			t.Check("a tap turns it on", Button.Press(eye))
			t.Wait(0.1)
			t.Check("lit while on", SpectateController.On() and eye:GetAttribute("On") == true and Button.State(eye) == "Selected", Button.State(eye))
			t.Check("open on its plate", open ~= nil and open:IsA("ImageLabel") and open.Visible and shut ~= nil and shut:IsA("ImageLabel") and not shut.Visible)
			local point = SpectateController.Point()
			t.Check("the camera follows its stand-in", point ~= nil and camera.CameraSubject == point)
			local early = SpectateController.Share()
			t.Check("eased, not snapped: part way at a tenth of a second", early > 0.2 and early < 0.9, string.format("%.2f", early))
			t.Wait(look.Ease + 0.2)
			t.Check("on the lead by its ease", SpectateController.Share() >= 0.95, string.format("%.3f", SpectateController.Share()))
			local want = leadRoot.Position + Vector3.new(0, look.Height, 0)
			local at = SpectateController.Point()
			t.Check("its point at the lead's focus", at ~= nil and (at.Position - want).Magnitude < 1, if at then string.format("%.2f studs off", (at.Position - want).Magnitude) else "none")
			t.Check("the zoom is the player's", math.abs(distance() - before) < 1, string.format("%.2f, was %.2f", distance(), before))
			local kept = camera.CFrame.LookVector:Dot(heading)
			if game:GetService("UserInputService").TouchEnabled then
				-- A touch screen's camera follows (Util.CameraTurn): it turns with its subject's travel to the lead, by
				-- Roblox's own rule, and the player's camera is left as it is (the director, TR11). Measured for research's
				-- verdict, not held to the mouse's bar.
				t.Row("the heading on a touch screen, turned by the follow camera on the way to the lead", nil, nil, math.deg(math.acos(math.clamp(kept, -1, 1))), "degrees")
			else
				t.Check("and so is the heading", kept > 0.99, string.format("%.3f", kept))
			end
			t.Check("a second tap turns it off", Button.Press(eye))
			t.Check("back on the avatar by its ease", waitFor(t, look.Ease + 0.5, function(): boolean
				return camera.CameraSubject == humanoid and SpectateController.Share() == 0
			end), string.format("%.3f", SpectateController.Share()))
			t.Check("unlit", eye:GetAttribute("On") == false and Button.State(eye) ~= "Selected", Button.State(eye))
			t.Check("at the distance it had", math.abs(distance() - before) < 1, string.format("%.2f, was %.2f", distance(), before))
			-- The lead's fall: off, the eye says why, and it can't be turned on while the lead is down.
			SpectateController.Set(true)
			t.Wait(look.Ease + 0.1)
			t.Check("the lead falls", t.Server("FightHealth", 0).Ok == true)
			t.Check("a fall turns it off", waitFor(t, 1, function(): boolean
				return not SpectateController.On()
			end))
			t.Check("the eye says why", waitFor(t, 1, function(): boolean
				return Button.State(eye) == "Disabled"
			end), Button.State(eye))
			t.Check("fainter while it can't be used", shut ~= nil and shut:IsA("ImageLabel") and math.abs(shut.ImageTransparency - (1 - look.Off)) < 0.01)
			local face = eye:FindFirstChild("Label", true) :: TextLabel?
			local why = tostring(eye:GetAttribute("Disabled"))
			t.Check("in a toast on a tap, its face only the eye", not Button.Press(eye) and table.find(Toast.Shown(), why) ~= nil
				and face ~= nil and face.Text == "", why)
			SpectateController.Set(true)
			t.Check("never on while the lead is down", not SpectateController.On())
			t.Check("and the camera's back on the avatar", waitFor(t, look.Ease + 0.5, function(): boolean
				return camera.CameraSubject == humanoid
			end))
			t.Check("it goes home, and the eye stays off", waitFor(t, Combat.Lead.Leave + 2, function(): boolean
				local fallen = myLead()
				return fallen ~= nil and fallen:GetAttribute("State") == "Home"
			end) and Button.State(eye) == "Disabled", Button.State(eye))
			SpectateController.Set(true)
			t.Check("never on while it's home", not SpectateController.On())
			t.Server("LeadHeal") -- Studio's: the way home takes a walk to the plot
			t.Check("the lead is back", waitFor(t, 1, function(): boolean
				local back = myLead()
				local state = if back then back:GetAttribute("State") else nil
				return state ~= nil and state ~= "Down" and state ~= "Home"
			end))
			t.Check("and the eye takes a tap again", waitFor(t, 1, function(): boolean
				return Button.State(eye) ~= "Disabled"
			end), Button.State(eye))
			-- A move's fade: back on the avatar at once, in the black.
			SpectateController.Set(true)
			t.Wait(look.Ease + 0.1)
			FadeController.Play(0.2, 0.3, 0.2)
			t.Wait(0.3)
			t.Check("a fade's black takes it back at once", not SpectateController.On() and SpectateController.Share() == 0 and camera.CameraSubject == humanoid, string.format("%.3f", SpectateController.Share()))
			t.Wait(0.6)
		end,
	},
	{
		-- TR7, research's call on the hang (2026-11-13): (a) the top band watches your own lead's hanging square
		-- (Config.Hud.SeeThrough.Tag); (c) the square never stands over the top bar's foot (Stamp.Under, UI.World.Ceiling),
		-- but never hangs lower than Clear over the target's head (Haymaker's content check, condition 1), and against
		-- Stamp.Uncapped kinds it isn't capped at all (the content check's block of the keeper's still: (d) stands).
		-- Its top tuned far too high, so the cap must hold it.
		Name = "Haymaker: your lead's hanging square stays under the top bar, never down to the head, and the card goes see-through behind it",
		Run = function(t: any)
			local TOP_PATH = "Effects.Haymaker.Stamp.Top"
			local TALL = 30
			local action = Actions.ById.RookHaymaker
			local s = EffectsConfig.Haymaker.Stamp
			local tag = HudConfig.SeeThrough.Tag
			local before = t.Server("Tune", TOP_PATH)
			t.Server("Tune", TOP_PATH, TALL)
			local ok, problem = pcall(function()
				t.Server("Replay", action.Id, action.Length + 3)
				local started = os.clock()
				local hangFrames, tagged, untaggedRun, lowestCard = 0, true, true, 1
				local over, lowestHang, overLine, atLine, atFloor = math.huge, math.huge, 0, 0, 0
				local worst = ""
				while os.clock() - started < action.Beats.Strike + 0.4 do
					local lead = myLead()
					local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
					local folder = workspace:FindFirstChild("NL_Effects")
					local posts: { BasePart }, rails: { BasePart } = {}, {}
					for _, part in (if folder then folder:GetChildren() else {}) do
						if part:IsA("BasePart") and part.Transparency < 1 then
							if part.Name == "NL_StampRun" then
								untaggedRun = untaggedRun and not CollectionService:HasTag(part, tag)
							elseif part.Name == "NL_StampPost" or part.Name == "NL_StampRail" or part.Name == "NL_StampPlate" then
								tagged = tagged and CollectionService:HasTag(part, tag)
								table.insert(if part.Name == "NL_StampPost" then posts elseif part.Name == "NL_StampRail" then rails else {}, part)
							end
						end
					end
					local floorY = if root then root.Position.Y - 3 else 0
					local foot = if #rails == 2 then math.min(rails[1].Position.Y, rails[2].Position.Y) - floorY else 0
					local edge = World.Ceiling()
					if #posts == 2 and #rails == 2 and foot > 0.5 and edge then -- hung or falling, not lying on the floor
						-- the hang is square (its post's length less its bar is its rail's), the drop stretched tall
						local square = math.abs(posts[1].Size.X - posts[1].Size.Y - rails[1].Size.X) < 1e-4
						if over == math.huge then
							-- the replay's dummy, measured as the effect does: its top over the lead's floor, and Clear
							for _, model in (workspace:FindFirstChild("Fighters") or workspace):GetChildren() do
								if model:IsA("Model") and model:GetAttribute("Kind") == "Dummy" then
									local box, extent = model:GetBoundingBox()
									over = math.max(s.Over, box.Position.Y + extent.Y / 2 - floorY + s.Clear)
								end
							end
						end
						local line = edge + s.Under * Layers.Scale()
						local frame = { posts[1], posts[2], rails[1], rails[2] }
						local top = topOnScreen(frame)
						local floored = square and math.abs(foot - over) < 0.01
						if square then
							hangFrames += 1
							lowestHang = math.min(lowestHang, foot)
							atLine += if math.abs(top - line) <= 1.5 then 1 else 0
							atFloor += if floored then 1 else 0
						end
						-- on or under the margin's line, every corner of its boxes within a pixel and a half; over it only
						-- while held at its floor over the head
						if top < line - 1.5 and not floored then
							overLine += 1
							worst = string.format("its top at %.1f px, the line at %.1f, its foot at %.2f", top, line, foot)
						end
						lowestCard = math.min(lowestCard, HudController.SeeThrough().Target or 1)
					end
					RunService.RenderStepped:Wait()
				end
				t.Check("the square hung", hangFrames > 5, `{hangFrames} frames`)
				t.Check("its posts, rails and plate are watched by the top band", tagged)
				t.Check("its floor's runs aren't", untaggedRun)
				t.Check("held by the cap, at the line or at its floor", atLine + atFloor > 0, `{atLine} frames at the line, {atFloor} at its floor`)
				t.Check("its top never over the top bar's foot plus the margin, but at its floor over the head", overLine == 0, `{overLine} frames over: {worst}`)
				t.Check("never hung lower than Clear over the target's head", lowestHang >= over - 0.01, string.format("lowest foot %.2f, its floor %.2f", lowestHang, over))
				t.Check("the Target card went see-through behind it, no lower than its floor", lowestCard < 1 and lowestCard >= HudConfig.SeeThrough.Target - 1e-3, string.format("lowest %.2f", lowestCard))
			end)
			t.Server("Replay")
			-- Uncapped: the same square stepped over a tall body, a Keeper and then an Ordinary, at the top of its hang.
			local made: Instance? = nil
			local ok2, problem2 = pcall(function()
				local lead = myLead()
				local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if lead == nil or root == nil then
					t.Check("the lead is in the world", false)
					return
				end
				local r = root :: BasePart
				local floorY = r.Position.Y - 3
				local ahead = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z).Unit
				local body = Instance.new("Model")
				body.Name = "NL_SelfTestTall"
				made = body
				local part = Instance.new("Part")
				part.Anchored, part.CanCollide, part.CanQuery, part.Transparency = true, false, false, 1
				part.Size = Vector3.new(4, 9, 4)
				part.Position = Vector3.new(r.Position.X, floorY + 4.5, r.Position.Z) + ahead * 8
				part.Parent = body
				body.Parent = workspace
				local function hungAt(kind: string): number
					body:SetAttribute("Kind", kind)
					local folder = workspace:FindFirstChild("NL_Effects")
					local theirs: { [Instance]: boolean } = {}
					for _, p in (if folder then folder:GetChildren() else {}) do
						theirs[p] = true
					end
					local running = Effects.Haymaker(action.Beats, lead :: Model, function(): BasePart?
						return part
					end)
					running.Step(action.Beats.Strike + (-s.Drop - 1) * FRAME)
					local low = math.huge
					folder = workspace:FindFirstChild("NL_Effects")
					for _, p in (if folder then folder:GetChildren() else {}) do
						if not theirs[p] and p:IsA("BasePart") and p.Name == "NL_StampRail" then
							low = math.min(low, p.Position.Y - floorY)
						end
					end
					running.Destroy()
					return low
				end
				local tallOver = math.max(s.Over, 9 + s.Clear)
				local free = tallOver + (TALL - s.Over)
				local keeper = hungAt("Keeper")
				t.Check("over a Keeper, uncapped: at the top of its drop", s.Uncapped.Keeper == true and math.abs(keeper - free) < 0.01, string.format("foot at %.2f, want %.2f", keeper, free))
				local ordinary = hungAt("Ordinary")
				t.Check("over an Ordinary as tall, capped, never under its floor", ordinary < free - 0.01 and ordinary >= tallOver - 0.01, string.format("foot at %.2f, its floor %.2f", ordinary, tallOver))
			end)
			if made then
				(made :: Instance):Destroy()
			end
			t.Server("Tune", TOP_PATH, before)
			if not ok then
				error(problem, 0)
			end
			if not ok2 then
				error(problem2, 0)
			end
		end,
	},
	{
		Name = "Fight: a hit ahead of its beat moves the clip to it, and a body struck mid-action never holds",
		Run = function(t: any)
			-- AR4, section 8 (research, 2026-11-12). The lead's combo in the replay, its screen held 0.4 s on the first hit
			-- as a Shade's hit on it used to hold it: each later hit from the server finds its clip and its effects on the
			-- hit's beat, never short of it. Then a hit's moment on a body mid-action: a spark, no hold.
			local lead = myLead()
			t.Check("the lead is in the world", lead ~= nil)
			if lead == nil then
				return
			end
			local combo: Actions.Action? = nil
			for _, action in Actions.KitOf(lead:GetAttribute("Def") :: string) do
				local count = 0
				for _ in action.Hits do
					count += 1
				end
				if action.Cooldown == 0 and count >= 2 then
					combo = action
				end
			end
			local view = FighterController.Views[lead]
			t.Check("the lead has a combo of two hits or more, and a view", combo ~= nil and view ~= nil)
			if combo == nil or view == nil then
				return
			end
			local action = combo :: Actions.Action
			local held = false
			local seen: { { Beat: string, Clock: number, Clip: number?, Effects: boolean } } = {}
			local connection = Net.Client.On("Hit", function(hit: any)
				if type(hit) ~= "table" or hit.A ~= lead or hit.Action ~= action.Id then
					return
				end
				if not held then
					held = true
					view.FrozenUntil = os.clock() + 0.4
					return
				end
				local beat = hit.Beat
				task.defer(function() -- after the screen's own handler of the same hit
					local inStep = true
					for _, running in view.Running do
						inStep = inStep and math.abs(running.Clock - view.Clock) < 1e-6
					end
					table.insert(seen, {
						Beat = beat,
						Clock = view.Clock,
						Clip = if view.Current then view.Current.TimePosition else nil,
						Effects = inStep,
					})
				end)
			end)
			local ok, result = pcall(function()
				return t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE)
			end)
			t.Check("the replay starts", ok and type(result) == "table" and result.Ok == true, tostring(if ok then result and result.Error else result))
			t.Wait(action.Length + 0.3)
			connection:Disconnect()
			t.Check("the later hits came", #seen >= 1, `{#seen}`)
			for _, row in seen do
				local at = action.Beats[row.Beat]
				t.Check(`{row.Beat}: the clock on its beat or past it`, row.Clock >= at - 1e-3, string.format("%.3f against %.3f", row.Clock, at))
				t.Check(`{row.Beat}: the clip on the clock`, row.Clip == nil or math.abs(row.Clip - row.Clock) < 0.02, string.format("%.3f", row.Clip or -1))
				t.Check(`{row.Beat}: the effects on the clock`, row.Effects)
			end
			-- A body mid-action takes the spark and no hold; the same body idle holds.
			local struck: any = nil
			for model, each in FighterController.Views do
				if model:GetAttribute("Kind") == "Dummy" then
					struck = each
				end
			end
			t.Check("the replay's dummy is on screen", struck ~= nil)
			if struck then
				local was = struck.Action
				local before = struck.FrozenUntil
				struck.Action = Actions.ById.ShadeSwipe -- no yield until it's put back: no frame steps it
				FighterController.Show(view, struck, 2, false, false, "SelfTest@1")
				local mid = struck.FrozenUntil
				struck.Action = was
				t.Check("mid-action: no hold", mid == before, string.format("%.3f later", mid - before))
				t.Wait(Combat.Hitstop.Kill + 0.1)
				FighterController.Show(view, struck, 2, false, false, "SelfTest@2")
				t.Check("idle: the hold", struck.FrozenUntil > os.clock(), string.format("%.3f", struck.FrozenUntil - os.clock()))
				-- AR8 A: the struck body's flash by the hit's rung, its tremble inside a signature's hold, the camera's trauma.
				local hitstop = Combat.Hitstop
				t.Check("idle: the flash", struck.Glow ~= nil and struck.Struck ~= nil)
				t.Wait(1 / 60)
				local glow = struck.Glow :: Highlight?
				t.Check("the flash is drawn, under the top value", glow ~= nil and glow.Enabled and glow.FillTransparency > 1 - FightRule.Lever(2, hitstop).Glow - 1e-3, if glow then string.format("%.2f", glow.FillTransparency) else "none")
				t.Wait(FightRule.Lever(2, hitstop).Flash + 0.1)
				t.Check("and over", glow ~= nil and not glow.Enabled and struck.Struck == nil)
				local home = struck.Root.Position
				local traumaBefore = Effects.Trauma()
				FighterController.Show(view, struck, 7, true, false, "SelfTest@3")
				t.Check("the player's own lead's signature: trauma", Effects.Trauma() >= math.min(1, traumaBefore + FightRule.Lever(7, hitstop).Trauma) - 1e-6, string.format("%.2f", Effects.Trauma()))
				local hold = FightRule.Hold(7, false, hitstop)
				local moved, ends = 0, os.clock() + hold
				while os.clock() < ends do
					t.Wait(1 / 60)
					moved = math.max(moved, (struck.Root.Position - home).Magnitude)
				end
				local most = FightRule.Lever(7, hitstop).Tremble
				t.Check("a signature's tremble shakes the body inside its hold", moved > most * 0.25 and moved <= most + 0.02, string.format("%.3f of %.2f studs", moved, most))
				t.Wait(0.1)
				t.Check("and puts it back where it stood", (struck.Root.Position - home).Magnitude < 0.02, string.format("%.3f studs off", (struck.Root.Position - home).Magnitude))
				t.Wait(hitstop.Rungs[#hitstop.Rungs].Flash + Combat.Shake.Decay)
				t.Check("the trauma falls to nothing", Effects.Trauma() == 0, string.format("%.3f", Effects.Trauma()))
			end
			t.Server("Replay")
			t.Wait(0.3)
		end,
	},
	{
		Name = "Kit: a button shows its states, says why it's disabled, and refuses a second press while it waits",
		Run = function(t: any)
			-- docs/ui.md, "Components"; TR3, part 1: rest, selected, disabled with its reason (never a bare grey), waiting on the
			-- server (its light running round, three dots, a second press refused), succeeded with its tick or failed on the
			-- answer, then back; a press that answers nothing goes back to rest. Pressed is a held touch: the capture shows it.
			local answer: boolean? = nil
			local release = Instance.new("BindableEvent")
			local presses = 0
			local button = Button.new({
				Name = "SelfTestButton",
				Text = "Lead",
				Size = UDim2.fromOffset(120, Theme.Size.Tap),
				Parent = Layers.Get("Hud"),
				OnPress = function()
					presses += 1
					release.Event:Wait()
					return answer
				end,
			})
			local label = button:FindFirstChild("Label", true) :: TextLabel?
			local tick = button:FindFirstChild("Tick", true) :: GuiObject?
			local function now(want: string): boolean
				return waitFor(t, 0.5, function(): boolean
					return Button.State(button) == want
				end)
			end
			t.Check("at rest", Button.State(button) == "Rest", Button.State(button))
			Button.Set(button, { Selected = true })
			t.Check("selected", Button.State(button) == "Selected", Button.State(button))
			Button.Set(button, { Selected = false, Disabled = "Leading" })
			t.Check("disabled", Button.State(button) == "Disabled", Button.State(button))
			t.Check("saying why", label ~= nil and label.Text == Hud.Says("Lead", "Leading", false), if label then label.Text else "no label")
			t.Check("and a press is refused", not Button.Press(button) and presses == 0)
			Button.Set(button, { Disabled = false })
			t.Check("enabled again, its label back", Button.State(button) == "Rest" and label ~= nil and label.Text == "Lead")
			answer = true
			t.Check("a press is taken", Button.Press(button))
			t.Check("waiting on the answer, its dots for its label", now("Waiting") and label ~= nil and not label.Visible)
			t.Check("a second press is refused while it waits", not Button.Press(button) and presses == 1, `{presses} presses`)
			release:Fire()
			t.Check("succeeded on a yes, with its tick", now("Succeeded") and tick ~= nil and tick.Visible)
			t.Check("then back at rest", waitFor(t, Button.FlashSeconds + 0.3, function(): boolean
				return Button.State(button) == "Rest"
			end))
			answer = false
			Button.Press(button)
			t.Wait(0.05)
			release:Fire()
			t.Check("failed on a no", now("Failed"), Button.State(button))
			t.Wait(Button.FlashSeconds + 0.1)
			answer = nil
			Button.Press(button)
			t.Wait(0.05)
			release:Fire()
			t.Wait(0.05)
			t.Check("a press that answers nothing goes back to rest, no flash", Button.State(button) == "Rest", Button.State(button))
			button:Destroy()
			release:Destroy()
		end,
	},
	{
		Name = "Kit: a press squeezes within 0.05 s about its middle, holds a quick tap, and comes back past full size to 1",
		Run = function(t: any)
			-- AR8 C, part 1 (rule 4): the face and the label squeeze about the button's middle; the button's own box, and so
			-- the layout, never moves. A press with no touch (a pad, a key) squeezes as a tap.
			local press = HudConfig.Motion.Press
			local button = Button.new({
				Name = "SelfTestSqueeze",
				Text = "Lead",
				Size = UDim2.fromOffset(120, Theme.Size.Tap),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Parent = Layers.Get("Hud"),
				OnPress = function() end,
			})
			local label = button:FindFirstChild("Label", true) :: TextLabel
			t.Wait(0.05)
			local middle = label.AbsolutePosition + label.AbsoluteSize / 2
			local box = button.AbsoluteSize
			t.Check("at rest, full size", Button.Squeeze(button) == 1)
			Button.Touch(button, true)
			t.Wait(press.In + 0.04)
			local squeezed = Button.Squeeze(button)
			t.Check("squeezed within its In", math.abs(squeezed - press.Squeeze) < 0.005, string.format("%.3f", squeezed))
			local now = label.AbsolutePosition + label.AbsoluteSize / 2
			-- About its middle, sunk by the make's Sink (AR30): the press goes down as it squeezes.
			local sunk = math.round(HudConfig.Make.Sink) * box.Y / Theme.Size.Tap
			local off = (now - middle) - Vector2.new(0, sunk)
			t.Check("about its middle, sunk by the make's press", off.Magnitude <= 1, string.format("%.1f px off", off.Magnitude))
			t.Check("its box, and so the layout, unmoved", button.AbsoluteSize == box)
			t.Check("held, the pressed look", Button.State(button) == "Pressed", Button.State(button))
			local most = 0
			local watch = RunService.RenderStepped:Connect(function()
				most = math.max(most, Button.Squeeze(button))
			end)
			Button.Touch(button, false)
			t.Wait(press.Out + 0.1)
			watch:Disconnect()
			t.Check("back past full size for a moment", most > 1, string.format("at most %.4f", most))
			t.Check("by a small mark", most < 1.03, string.format("at most %.4f", most))
			t.Check("and settled at exactly 1", Button.Squeeze(button) == 1, string.format("%.4f", Button.Squeeze(button)))
			-- A quick tap: down and up in one frame still shows.
			Button.Touch(button, true)
			Button.Touch(button, false)
			t.Wait(press.Least * 0.75)
			t.Check("a quick tap stays squeezed to its Least", Button.Squeeze(button) < 1 - (1 - press.Squeeze) / 2, string.format("%.3f", Button.Squeeze(button)))
			t.Wait(press.Least + press.Out + 0.1)
			Button.Press(button)
			t.Wait(press.In)
			t.Check("a press with no touch squeezes as a tap", Button.Squeeze(button) < 1, string.format("%.3f", Button.Squeeze(button)))
			t.Wait(press.Least + press.Out + 0.1)
			t.Check("and comes back", Button.Squeeze(button) == 1)
			button:Destroy()
		end,
	},
	{
		Name = "Kit: a screen comes in eased out and leaves eased in, quicker, closed the moment it's asked",
		Run = function(t: any)
			-- AR8 C, part 2 (rule 4): in from a little smaller, see-through, eased out; out to a little smaller, eased in, in
			-- about 0.8 of the entrance. Closed at once: nothing in it takes a tap while it leaves.
			local motion = HudConfig.Motion.Screen
			t.Check("its exit about 0.8 of its entrance", motion.Exit <= motion.Enter * 0.85 and motion.Exit >= motion.Enter * 0.7)
			Screen.Close()
			t.Wait(motion.Exit + 0.05)
			Screen.Open("SelfTestScreen", "Self-test", Vector2.new(300, 200))
			local stage = Screen.Stage("SelfTestScreen")
			t.Check("it stands in its group", stage ~= nil)
			if stage == nil then
				Screen.Close()
				return
			end
			local scale = stage:FindFirstChildOfClass("UIScale") :: UIScale
			t.Check("it starts see-through and smaller", stage.GroupTransparency > 0.9 and scale.Scale < 1, string.format("%.2f, %.3f", stage.GroupTransparency, scale.Scale))
			local born = os.clock()
			local quarter: number? = nil
			local watch = RunService.RenderStepped:Connect(function()
				if quarter == nil and os.clock() - born >= motion.Enter * 0.25 then
					quarter = stage.GroupTransparency
				end
			end)
			t.Wait(motion.Enter + 0.1)
			watch:Disconnect()
			t.Check("eased out: more than half in by a quarter of its time", quarter ~= nil and quarter < 0.5, if quarter then string.format("%.2f see-through", quarter) else "no frame")
			t.Check("in by its Enter", stage.GroupTransparency == 0 and scale.Scale == 1, string.format("%.2f, %.3f", stage.GroupTransparency, scale.Scale))
			Screen.Close()
			t.Check("closed at once", Screen.Current() == nil and Screen.Frame("SelfTestScreen") == nil)
			t.Check("nothing in it takes a tap while it leaves", stage.Interactable == false)
			local left = os.clock()
			local half: number? = nil
			watch = RunService.RenderStepped:Connect(function()
				if half == nil and os.clock() - left >= motion.Exit * 0.5 then
					half = stage.GroupTransparency
				end
			end)
			t.Wait(motion.Exit + 0.1)
			watch:Disconnect()
			t.Check("eased in: under half gone at half its time", half ~= nil and half < 0.5, if half then string.format("%.2f see-through", half) else "no frame")
			t.Check("gone by its Exit", stage.Parent == nil)
		end,
	},
	{
		Name = "Kit: a screen opened again, as its owner rebuilds it, keeps its panel and refills in place, with no second entrance",
		Run = function(t: any)
			-- TR9: the Breaker's screen rebuilds on every tap and every change of the save, so a rebuild mustn't flash.
			local motion = HudConfig.Motion.Screen
			Screen.Close()
			t.Wait(motion.Exit + 0.05)
			local body = Screen.Open("SelfTestScreen", "Self-test", Vector2.new(300, 200))
			local old = Instance.new("Frame")
			old.Name = "Old"
			old.Parent = body
			t.Wait(motion.Enter + 0.1)
			local frame = Screen.Frame("SelfTestScreen")
			local closed = 0
			local watch = Screen.Closed:Connect(function()
				closed += 1
			end)
			local again = Screen.Open("SelfTestScreen", "Self-test, again", Vector2.new(320, 200))
			watch:Disconnect()
			local stage = Screen.Stage("SelfTestScreen")
			local title = frame and frame:FindFirstChild("Title") :: TextLabel?
			t.Check("the same panel and body", frame ~= nil and Screen.Frame("SelfTestScreen") == frame and again == body)
			t.Check("its body emptied for its owner", body:FindFirstChild("Old") == nil and #body:GetChildren() == 0, `{#body:GetChildren()} left`)
			t.Check("its title the new one", title ~= nil and title.Text == "Self-test, again", if title then title.Text else "none")
			t.Check("its size the new one", frame ~= nil and frame.Size.X.Offset == 320, if frame then tostring(frame.Size) else "none")
			t.Check("no second entrance", stage ~= nil and stage.GroupTransparency == 0, if stage then string.format("%.2f see-through", stage.GroupTransparency) else "no stage")
			t.Check("nothing closed", closed == 0 and Screen.Current() == "SelfTestScreen")
			Screen.Open("SelfTestScreenOther", "Self-test, other", Vector2.new(300, 200))
			t.Check("another screen still takes its place", Screen.Current() == "SelfTestScreenOther" and Screen.Frame("SelfTestScreen") == nil)
			Screen.Close()
		end,
	},
	{
		Name = "Kit: a toast slides in from the right edge, eased out, and leaves that way, eased in",
		Run = function(t: any)
			-- AR8 C, part 2 (rule 4). Shown past the stack's room, so the oldest is pushed out and leaves at once.
			local motion = HudConfig.Motion.Toast
			local function plateOf(message: string): Frame?
				for _, label in Layers.Get("Toasts"):GetDescendants() do
					if label:IsA("TextLabel") and label.Name == "Message" and label.Text == message then
						return label.Parent :: Frame
					end
				end
				return nil
			end
			Toast.Show("Self-test toast 1")
			local plate = plateOf("Self-test toast 1")
			t.Check("it shows", plate ~= nil)
			if plate == nil then
				return
			end
			local away = plate.Position.X.Offset
			t.Check("it starts off the right edge", away >= Toast.Width + Theme.Size.Pad, `{away} px over`)
			local born = os.clock()
			local quarter: number? = nil
			local watch = RunService.RenderStepped:Connect(function()
				if quarter == nil and os.clock() - born >= motion.Enter * 0.25 then
					quarter = plate.Position.X.Offset
				end
			end)
			t.Wait(motion.Enter + 0.1)
			watch:Disconnect()
			t.Check("eased out: past half way in by a quarter of its time", quarter ~= nil and quarter < away / 2, if quarter then `{quarter} px over` else "no frame")
			t.Check("in by its Enter", plate.Position.X.Offset == 0, `{plate.Position.X.Offset} px over`)
			-- Research's pass on AR8 C, fix 2: a full stack sits inside the safe area, under the pills, over nothing it
			-- would hide (the pills, the signature's ring), in this window and on the smallest phone.
			local stack = (plate.Parent :: Frame).Parent :: Frame
			local parts = HudController.Parts()
			local hud = Layers.Get("Hud")
			local top = GuiService.TopbarInset.Height
			local function clear(piece: GuiObject): boolean
				local a, b = stack.AbsolutePosition, stack.AbsolutePosition + stack.AbsoluteSize
				local c, d = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
				return a.X >= d.X or c.X >= b.X or a.Y >= d.Y or c.Y >= b.Y
			end
			for _, at in { { Name = "this window", Scale = nil :: number?, Box = nil :: Vector2? }, { Name = "the smallest phone", Scale = Theme.Scale.Floor, Box = Theme.Smallest - Vector2.new(0, top) } } do
				Layers.Force(at.Scale)
				Layers.Box(at.Box)
				t.Wait(0.1) -- laid out again
				local edge = hud.AbsolutePosition.X + hud.AbsoluteSize.X
				local right = stack.AbsolutePosition.X + stack.AbsoluteSize.X
				t.Check(`inside the safe area's right edge, in {at.Name}`, right <= edge + 0.5, `{right} against {edge}`)
				t.Check(`under the top of the safe area, in {at.Name}`, stack.AbsolutePosition.Y >= hud.AbsolutePosition.Y)
				for _, name in { "Credits", "Electricity" } do
					t.Check(`clear of the {name} pill, in {at.Name}`, clear((parts[name] :: GuiObject).Parent :: GuiObject))
				end
				t.Check(`clear of the signature's readout, in {at.Name}`, clear(parts.Signature :: GuiObject))
			end
			Layers.Box(nil)
			Layers.Force(nil)
			for i = 2, Theme.Time.Toasts + 1 do
				Toast.Show(`Self-test toast {i}`)
			end
			t.Check("pushed out, it's no longer shown", table.find(Toast.Shown(), "Self-test toast 1") == nil)
			local left = os.clock()
			local half: number? = nil
			watch = RunService.RenderStepped:Connect(function()
				if half == nil and os.clock() - left >= motion.Exit * 0.5 then
					half = plate.Position.X.Offset
				end
			end)
			t.Wait(motion.Exit + 0.1)
			watch:Disconnect()
			t.Check("eased in: under half way out at half its time", half ~= nil and half < away / 2 and half > 0, if half then `{half} px over` else "no frame")
			t.Check("and gone by its Exit", plate.Parent == nil or plate.Parent.Parent == nil)
			t.Wait(Theme.Time.Toast + motion.Exit + 0.1) -- the rest leave
		end,
	},
	{
		Name = "HUD: a reward pops at its rung: Credits swell in place, a +N rises and counts, a level swells and its thread glints",
		Run = function(t: any)
			-- AR8 C, part 3 (rule 4). Credits and a level from the server (DataCredits, LeadLevel), put back after.
			local cfg = HudConfig.Pop
			local parts = HudController.Parts()
			local pill = (parts.Credits :: GuiObject).Parent :: GuiObject
			local level = parts.LeadLevel :: TextLabel
			local glint = parts.XpGlint :: Frame
			t.Wait(cfg.Seconds + 0.1) -- anything popping settles
			local middle = pill.AbsolutePosition + pill.AbsoluteSize / 2
			local most, moved, levelMost, glinted, whitest = 1, 0, 1, 0, 0
			local rest = UIKit.Systems.Voidkin.Block[1] -- the level's badge in take A: the Voidkin's Block, lifted toward white
			local watch = RunService.RenderStepped:Connect(function()
				most = math.max(most, Pop.Active(pill))
				moved = math.max(moved, (pill.AbsolutePosition + pill.AbsoluteSize / 2 - middle).Magnitude)
				levelMost = math.max(levelMost, Pop.Active(level))
				if glint.Visible then
					glinted = math.max(glinted, 1 - glint.BackgroundTransparency)
				end
				local c = HudCases.BadgeTop(parts)
				whitest = math.max(whitest, (c.R + c.G + c.B) - (rest.R + rest.G + rest.B))
			end)
			t.Check("credits given", t.Server("DataCredits", 25).Ok == true)
			t.Check("a +N rises off the pill", waitFor(t, 2, function(): boolean
				return Pop.Gained(pill) == "+25"
			end), Pop.Gained(pill))
			t.Check("credits again, close after", t.Server("DataCredits", 15).Ok == true)
			t.Check("the two count up as one", waitFor(t, 1, function(): boolean
				return Pop.Gained(pill) == "+40"
			end), Pop.Gained(pill))
			t.Check("the +N leaves after its life", waitFor(t, cfg.Gain + 0.5, function(): boolean
				return Pop.Gained(pill) == ""
			end))
			t.Server("DataCredits", -40) -- a spend: no pop
			local view = ProfileController.Get()
			local owned = if view then view.Voidkin[view.Roles.Lead] else nil
			local was = if owned then owned.Level else nil
			if was then
				t.Check("a level gained", t.Server("LeadLevel", was + 1).Ok == true)
				t.Wait(1)
				t.Server("LeadLevel", was)
			end
			t.Wait(cfg.Seconds + 0.1)
			watch:Disconnect()
			local want = Hud.PopScale(cfg.Rungs.Credits, cfg.Swell)
			t.Check("Credits swelled to its rung's size", math.abs(most - want) < 0.02, string.format("%.3f, its rung's %.3f", most, want))
			t.Check("in place: the pill's middle never moved", moved <= 1, string.format("%.1f px", moved))
			t.Check("and settled", Pop.Active(pill) == 1)
			if was then
				local high = Hud.PopScale(cfg.Rungs.Level, cfg.Swell)
				t.Check("the level swelled larger, at its rung", math.abs(levelMost - high) < 0.03 and levelMost > most, string.format("%.3f, its rung's %.3f", levelMost, high))
				-- At its peak the badge goes Glow of the way to white: from lavender, little is left to go, so the check is
				-- against that; the number keeps its ink through it.
				local reach = (3 - (rest.R + rest.G + rest.B)) * cfg.Glow
				t.Check("and its badge brightened toward white", whitest >= reach * 0.8, string.format("%.3f of its %.3f", whitest, reach))
				t.Check("its colour back after", HudCases.BadgeTop(parts):ToHex() == rest:ToHex() and level.TextColor3 == HudConfig.Card.LeadLevel, HudCases.BadgeTop(parts):ToHex())
				t.Check("the thread glinted", glinted >= cfg.Glow - 0.05, string.format("%.2f opaque", glinted))
				t.Check("and the glint's gone after", not glint.Visible)
			end
		end,
	},
	{
		Name = "HUD: TR6, a reward's icons fly into its pill and its number counts up; the level's badge bursts; a touch ticks",
		Run = function(t: any)
			-- TR6 (docs/research/vfx-reference.md, "UI effects", DESIGN 2 to 5): the kit's pieces alone, then in the HUD. The
			-- level's rays and shine are the level-up's case. With the player's reduced motion on, nothing flies or counts.
			local motion = HudConfig.Motion
			local still = GuiService.ReducedMotionEnabled
			local parts = HudController.Parts()
			local value = parts.Credits :: TextLabel
			local pill = value.Parent :: GuiObject
			local mark = pill:FindFirstChild("Mark")
			local coin = UIKit.Systems.Credits.Icon
			t.Check("the Credits pill wears its icon", mark ~= nil and mark:IsA("ImageLabel"))
			if mark == nil or not mark:IsA("ImageLabel") then
				return
			end
			-- The fly, from the screen's middle into the pill's icon.
			local look = motion.Fly
			local landings: { number } = {}
			local began = os.clock()
			local into = Fly.Middle(mark)
			local nearest, aloft = math.huge, 0
			local watch = RunService.RenderStepped:Connect(function()
				local holder = Layers.Get("Hud"):FindFirstChild("NL_Fly")
				local shown = 0
				for _, icon in if holder then holder:GetChildren() else {} do
					if icon:IsA("ImageLabel") and icon.Name == coin and icon.Visible then
						shown += 1
						nearest = math.min(nearest, (Vector2.new(icon.Position.X.Offset, icon.Position.Y.Offset) - into).Magnitude)
					end
				end
				aloft = math.max(aloft, shown)
			end)
			local n = Fly.Send(Fly.Centre(), mark, coin, 250, function(k: number)
				landings[k] = os.clock() - began
			end)
			t.Check("a flock by the reward's size", n == Hud.Flock(250, look.Least, look.Most), `{n}`)
			if still then
				t.Check("reduced motion: each lands at once, none flies", #landings == n and Fly.Flying() == 0)
			else
				t.Check("they're on their way", Fly.Flying() == n, `{Fly.Flying()}`)
				local by = look.Seconds * 1.1 + look.Stagger * (n - 1) + 0.3
				t.Check("all land", waitFor(t, by, function(): boolean
					return #landings == n
				end), `{#landings} of {n}`)
				local first, last = landings[1] or 0, landings[n] or 0
				t.Check("the first lands in about its flight's seconds", first >= look.Seconds * 0.85 and first <= look.Seconds * 1.15 + 0.05, string.format("%.2f s", first))
				t.Check("staggered: the last lands after", last - first >= look.Stagger * 0.5, string.format("%.2f s after", last - first))
				t.Check("several in the air at once", aloft >= 2, `{aloft}`)
				local reach = math.max(16, 0.12 * (into - Fly.Centre()).Magnitude)
				t.Check("into the icon", nearest <= reach, string.format("%.1f px, within %.1f", nearest, reach))
				t.Check("and gone after", Fly.Flying() == 0)
			end
			watch:Disconnect()
			-- The count, on a stand-in label: from the old to the new, Expo out, never back down.
			local label = Instance.new("TextLabel")
			label.Name = "CountProbe"
			label.Visible = false
			label.Parent = Layers.Get("Hud")
			local function whole(x: number): string
				return tostring(math.floor(x + 0.5))
			end
			local seen: { number } = {}
			local probe = RunService.RenderStepped:Connect(function()
				table.insert(seen, tonumber(label.Text) or -1)
			end)
			Count.Run(label, 0, 1000, whole)
			if still then
				t.Check("reduced motion: the new value at once", label.Text == "1000", label.Text)
			else
				t.Check("it starts from the old value", label.Text == "0", label.Text)
				t.Wait(motion.Count.Seconds * 0.5)
				local half = tonumber(label.Text) or 0
				t.Check("most of the way by half its seconds, its end eased", half >= 900 and half < 1000, label.Text)
				t.Check("and lands on the new", waitFor(t, motion.Count.Seconds, function(): boolean
					return label.Text == "1000" and not Count.Counting(label)
				end), label.Text)
				local rising = true
				for i = 2, #seen do
					rising = rising and seen[i] >= seen[i - 1]
				end
				t.Check("never down on its way up", rising)
				Count.Run(label, 1000, 1200, whole, true)
				t.Wait(0.3)
				t.Check("a count waiting for its landing holds the old value", label.Text == "1000" and Count.Counting(label), label.Text)
				Count.Start(label)
				t.Check("and counts once it lands", waitFor(t, motion.Count.Seconds + 0.3, function(): boolean
					return label.Text == "1200"
				end), label.Text)
				Count.Run(label, 1200, 1300, whole, true)
				t.Check("one that never lands starts by its latest", waitFor(t, motion.Count.Latest + motion.Count.Seconds + 0.3, function(): boolean
					return label.Text == "1300"
				end), label.Text)
			end
			probe:Disconnect()
			label:Destroy()
			-- In the HUD: Credits from nowhere on screen (the server's DataCredits) count up in the pill.
			local view = ProfileController.Get()
			local had = if view then view.Currency.Credits else 0
			local shownValues: { [string]: boolean } = {}
			local reading = RunService.RenderStepped:Connect(function()
				shownValues[value.Text] = true
			end)
			t.Check("credits given", t.Server("DataCredits", 500).Ok == true)
			t.Check("the pill counts up to the save's", waitFor(t, look.Seconds + motion.Count.Latest + motion.Count.Seconds + 0.5, function(): boolean
				return value.Text == Read.Number(had + 500)
			end), value.Text)
			reading:Disconnect()
			local steps = 0
			for _ in shownValues do
				steps += 1
			end
			t.Check("through numbers between, not one jump", still or steps >= 4, `{steps} numbers shown`)
			t.Server("DataCredits", -500)
			t.Check("a spend shows at once", waitFor(t, 1, function(): boolean
				return value.Text == Read.Number(had)
			end), value.Text)
			-- A level: sparks off the badge, round it, gone by their seconds.
			local owned = if view then view.Voidkin[view.Roles.Lead] else nil
			if owned and not still then
				local badge = Fly.Middle(parts.LeadLevel :: GuiObject)
				local sparks, farthest = 0, 0
				local burst = RunService.RenderStepped:Connect(function()
					sparks = math.max(sparks, Burst.Sparks())
					local holder = Layers.Get("Hud"):FindFirstChild("NL_Fly")
					for _, spark in if holder then holder:GetChildren() else {} do
						if spark:IsA("ImageLabel") and spark.Name == "Spark" then
							farthest = math.max(farthest, (Vector2.new(spark.Position.X.Offset, spark.Position.Y.Offset) - badge).Magnitude)
						end
					end
				end)
				t.Check("a level gained", t.Server("LeadLevel", owned.Level + 1).Ok == true)
				t.Check("the badge bursts", waitFor(t, 2, function(): boolean
					return sparks >= motion.Burst.Count
				end), `{sparks} sparks`)
				t.Check("its sparks stay round the badge", farthest <= motion.Burst.Reach + 1, string.format("%.1f px out", farthest))
				t.Check("and go by their seconds", waitFor(t, motion.Burst.Seconds + 0.3, function(): boolean
					return Burst.Sparks() == 0
				end), `{Burst.Sparks()}`)
				burst:Disconnect()
				t.Server("LeadLevel", owned.Level)
			end
			-- A touch's tick (Roblox's UIClick haptic): on a button that takes the press, never on a disabled one. The
			-- thumb's feel itself is the device's, by hand.
			local button = Button.new({ Name = "SelfTestHaptic", Text = "Lead", Size = UDim2.fromOffset(120, Theme.Size.Tap), Parent = Layers.Get("Hud"), OnPress = function() end })
			t.Check("a touch ticks on a button that takes it", motion.Haptic and Button.Haptic(button))
			Button.Set(button, { Disabled = "for the test" })
			t.Check("never on a disabled one", not Button.Haptic(button))
			button:Destroy()
		end,
	},
	{
		Name = "Effects: a number's size follows its hit's rung, and a heavy hit sends the lower numbers aside, up, fading",
		Run = function(t: any)
			-- AR8 C, part 5 (research's pass on A, fix 1): larger by rung; while a rung-7 hit lands on a body, its lower
			-- numbers leave its middle, out and up (never down the body: the content check's condition 1), fading over
			-- Yield.Seconds, eased in; the heavy hit's own number stays. On stand-in bodies in front of the camera.
			local camera = workspace.CurrentCamera
			local function body(x: number): Part
				local root = Instance.new("Part")
				root.Name = "HumanoidRootPart"
				root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
				root.CFrame = camera.CFrame * CFrame.new(x, -2, -24)
				root.Parent = workspace
				return root
			end
			local numbers = Combat.Numbers
			local a, b = body(-6), body(6)
			Effects.Number(a, "light", 100, { Style = "Dealt", Rung = 2 }, numbers)
			Effects.Number(b, "heavy", 100, { Style = "Dealt", Rung = 7 }, numbers)
			local light, heavy = Effects.Counting[a].light, Effects.Counting[b].heavy
			local by = HudConfig.Numbers.Rung
			local ratio = heavy.H / light.H
			t.Check("a signature's hit is larger by its rung", math.abs(ratio - Hud.NumberScale("Dealt", 7, by)) < 0.01, string.format("%.3f times", ratio))
			Effects.Number(a, "light", 50, { Style = "Dealt", Rung = 4 }, numbers)
			t.Check("a heavier hit joining a number makes it larger", light.H > heavy.H / Hud.NumberScale("Dealt", 7, by) + 0.5, string.format("%.1f px", light.H))
			-- The yield: a rung-2 number and a word, then a rung-7 hit on the same body.
			local c = body(0)
			Effects.Number(c, "low", 100, { Style = "Dealt", Rung = 2 }, numbers)
			Effects.Number(c, "word", nil, { Style = "Word", Word = "Block" }, numbers)
			t.Wait(0.05)
			local low, word = Effects.Counting[c].low, Effects.Counting[c].word
			local yield = HudConfig.Numbers.Yield
			local born = os.clock()
			local half: number? = nil
			local watch = RunService.RenderStepped:Connect(function()
				if half == nil and os.clock() - born >= yield.Seconds * 0.5 then
					half = low.Fade
				end
			end)
			Effects.Yield(c, 7)
			Effects.Number(c, "sig", 900, { Style = "Dealt", Rung = 7 }, numbers)
			t.Check("the lower numbers give way", low.YieldAt ~= nil and word.YieldAt ~= nil)
			t.Check("out of the middle and up, never down", low.Aside.Y < 0 and word.Aside.Y < 0 and math.abs(low.Aside.X) > 0)
			t.Check("the heavy hit's own number stays", Effects.Counting[c].sig ~= nil and Effects.Counting[c].sig.YieldAt == nil)
			t.Check("a hit after on a yielded key is a new number", Effects.Counting[c].low == nil)
			t.Wait(yield.Seconds + 0.05)
			watch:Disconnect()
			t.Check("eased in: under half faded at half its time", half ~= nil and half < 0.5, if half then string.format("%.2f", half) else "no frame")
			t.Check("gone by its Seconds", low.Fade >= 1 and word.Fade >= 1, string.format("%.2f, %.2f", low.Fade, word.Fade))
			t.Wait(numbers.Seconds + 0.1)
			for _, root in { a, b, c } do
				root:Destroy()
			end
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
			t.Check("and its level, on its mark", level == tostring(lead:GetAttribute("Level")), level)
			local health, most = lead:GetAttribute("Health") :: number, lead:GetAttribute("MaxHealth") :: number
			t.Near("its health bar is its share of health", parts.LeadHealth:GetAttribute("Share") :: number, health / most, 0.01)
			local under = (parts.LeadHealthText :: TextLabel).Text
			-- whole, or in its compact form where the most over the most is wider than its bar holds (TR3's fix 6; AR45)
			t.Check("with its health and its most under it, set tight", under == Hud.Health(health, most, nil, true) or under == Hud.Health(health, most, 0, true), under)
			local def = Voidkin.ById[lead:GetAttribute("Def") :: string]
			t.Check("its portrait in its rarity's frame", def ~= nil and parts.LeadPortrait:GetAttribute("Voidkin") == def.Id and parts.LeadPortrait:GetAttribute("Rarity") == def.Rarity, `{parts.LeadPortrait:GetAttribute("Face")}`)
			t.Check("and its type's gem", def ~= nil and parts.LeadGem:GetAttribute("Kit") == `Gem{def.Type}`, `{parts.LeadGem:GetAttribute("Kit")}`)
			-- Take F (AR12): the stud in the type's colour, the digits between the two bars; the level on a badge on the
			-- frame (TR24, the director's run, fix 6): over the frame's foot and inside its width, in the
			-- card's own colours (the plate's body, the rarity's rim), the number on it, above the eye under the card.
			local stud = parts.Lead:FindFirstChild("Stud") :: ImageLabel?
			local hue = if def then HudConfig.Card.Types[def.Type] else nil
			t.Check("its stud in its type's colour", stud ~= nil and hue ~= nil and stud.ImageColor3 == hue, if stud then stud.ImageColor3:ToHex() else "no stud")
			local text, bar, xpBar = parts.LeadHealthText :: GuiObject, parts.LeadHealth :: GuiObject, parts.Lead:FindFirstChild("Xp") :: GuiObject
			-- The digits' line, not its box: the box is centred on the gap and held at the text's floor (UI.LeadCard).
			local middle = text.AbsolutePosition.Y + text.AbsoluteSize.Y / 2
			local lineHalf = (text :: TextLabel).TextBounds.Y / 2
			t.Check("its digits between the health bar and the experience", middle - lineHalf >= bar.AbsolutePosition.Y + bar.AbsoluteSize.Y - 1
				and middle + lineHalf <= xpBar.AbsolutePosition.Y + 1, string.format("%.0f to %.0f", middle - lineHalf, middle + lineHalf))
			local scale = parts.Lead.AbsoluteSize.X / parts.Lead.Size.X.Offset
			HudCases.LevelBadge(t, parts, scale)
			local credits = (parts.Credits :: TextLabel).Text
			t.Check("the Credits pill shows the save's", credits == Read.Number(view.Currency.Credits), credits)
			t.Wait(PLATE_TICK)
			-- TR18: the Power pill says generation against demand in kW, the battery's kWh after it.
			local shown = (parts.Electricity :: TextLabel).Text
			local now = Read.Base(view, workspace:GetServerTimeNow())
			t.Equal("the Power pill: generation against demand", shown, Read.Against(now.Rates.Generation, now.Rates.Demand))
			local over = now.Rates.Flow.Net < -1e-9
			t.Check("its warning only while the battery covers a shortfall", ((parts.Electricity :: TextLabel).Parent :: GuiObject):GetAttribute("Over") == over, `{now.Rates.Flow.Net} kW into the battery`)
			local after = (parts.PowerStored :: TextLabel).Text
			local kwh = tonumber(((after:match("^([%d%.,]+) kWh$") or ""):gsub(",", "")))
			t.Check("the battery's kWh after it", after == "full" or kwh ~= nil, after)
			if kwh then
				-- To the readout's own step (Read.Kwh): a hundredth under 100, whole from 100, so a battery of any save
				-- reads, beside the tick's drift.
				local step = if math.abs(now.Data.Base.Charge) < 100 then 0 else 0.5
				t.Near("the battery as it stands now", kwh, now.Data.Base.Charge, step + 0.05)
			end
			HudCases.PillBattery(t, parts, now.Data.Base.Charge, now.Rates.Capacity)
			t.Check("a battery under 100 shows its hundredth, so it visibly counts up", Read.Kwh(0.354) == "0.35" and Read.Kwh(47.8) == "47.80" and Read.Kwh(2357) == "2,357", `{Read.Kwh(0.354)}, {Read.Kwh(47.8)}, {Read.Kwh(2357)}`)
			t.Check("power in kW: a tenth under 10, whole above", Read.Kw(7.5) == "7.5 kW" and Read.Kw(7) == "7 kW" and Read.Kw(18) == "18 kW" and Read.Kw(3, true) == "+3 kW" and Read.Against(30, 34) == "30 / 34 kW", `{Read.Kw(7.5)}, {Read.Kw(7)}, {Read.Against(30, 34)}`)
			t.Check("nothing drawing, only what's made (TR24's fix 4)", Read.Against(18, 0) == "18 kW" and Read.Against(0, 0) == "0 kW", `{Read.Against(18, 0)}, {Read.Against(0, 0)}`)
			t.Check("the target's card hides out of a fight", not parts.Target.Visible)
			-- Nothing stands empty: at a join the save's copy comes a moment after the HUD and the plot, and pills and plates
			-- stood as blank boxes for a second (TR2's rejoin take).
			local pill = parts.Credits :: TextLabel
			local said = pill.Text
			pill.Text = ""
			RunService.Heartbeat:Wait() -- the change's signal runs deferred
			t.Check("a pill with nothing to say hides", pill.Parent ~= nil and not (pill.Parent :: GuiObject).Visible)
			pill.Text = said
			RunService.Heartbeat:Wait()
			t.Check("and shows again once it has", pill.Parent ~= nil and (pill.Parent :: GuiObject).Visible)
			-- A panel shows only while it and everything over it shows; its words stand in it or beside it in its plate (the
			-- down badge's card lies beside its panel, TR10).
			local world = Layers.Get("World")
			local function standing(item: Instance): boolean
				local at: Instance? = item
				while at and at ~= world do
					if (at:IsA("GuiObject") and not at.Visible) or (at:IsA("CanvasGroup") and at.GroupTransparency >= 1) then
						return false
					end
					at = at.Parent
				end
				return at == world
			end
			local blank: { string } = {}
			for _, panel in world:GetDescendants() do
				if panel.Name == "Panel" and panel:IsA("GuiObject") and standing(panel) then
					local says = false
					for _, line in (panel.Parent :: Instance):GetDescendants() do
						says = says or (line:IsA("TextLabel") and line.Text ~= "" and standing(line))
					end
					if not says and panel.Parent then
						table.insert(blank, panel.Parent.Name)
					end
				end
			end
			t.Check("no plate shows empty", #blank == 0, table.concat(blank, ", "))
			-- Whole or not at all: the join's black lifted once the HUD was whole, not by running out of time.
			local opened = FadeController.Opened()
			t.Check("the join's black lifted on a whole screen", opened ~= nil and opened.Whole, if opened then `{math.floor(opened.At * 100 + 0.5) / 100} s after the client started` else "not lifted")
			lintClean(t, "the HUD")
		end,
	},
	{
		-- TR12 (docs/design.md, "A fall sends it home", "The next lead"): the card through a fall, and another Voidkin sent
		-- out at once from the button under it; the fallen one stays home until it's whole.
		Name = "HUD: TR12, a fallen lead's card says it's down, then healing at home with its time, and sends out the next",
		Place = "Main", -- TR45: its world stands in that place only
		Run = function(t: any)
			t.Wait(LEAD_SETTLE)
			local parts = HudController.Parts()
			local lead = myLead()
			local view = ProfileController.Get()
			t.Check("the lead is in the world and the save's copy is here", lead ~= nil and view ~= nil)
			if lead == nil or view == nil then
				return
			end
			local was = lead:GetAttribute("Voidkin") :: string
			local def = lead:GetAttribute("Def")
			-- A second Voidkin free to lead: one owned, or one given.
			local other: string? = nil
			for id in view.Voidkin do
				if id ~= was and Read.Role(view, id) == "" then
					other = id
					break
				end
			end
			for _, give in { "pip", "kirra", "rook" } do
				if other ~= nil or give == def then
					continue
				end
				local given = t.Server("VoidkinGive", give)
				local id = if type(given) == "table" and given.Ok == true then given.Id else nil
				local arrived = type(id) == "string" and waitFor(t, 2, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and now.Voidkin[id] ~= nil
				end)
				local now = ProfileController.Get()
				if arrived and now and Read.Role(now, id) == "" then
					other = id
				end
			end
			t.Check("a second Voidkin, free to lead", other ~= nil)
			if other == nil then
				return
			end
			t.Check("no button for the next while the lead stands", not parts.Next.Visible)
			-- The fall: down, then home on its plot, healing, with its time.
			t.Check("the lead falls", t.Server("FightHealth", 0).Ok == true)
			t.Check("the card says it's down", waitFor(t, 1, function(): boolean
				return parts.Lead:GetAttribute("Status") == "Down"
			end), tostring(parts.Lead:GetAttribute("Status")))
			t.Check("then it's home", waitFor(t, Combat.Lead.Leave + 1, function(): boolean
				local fallen = myLead()
				return fallen ~= nil and fallen:GetAttribute("State") == "Home"
			end))
			local plot = Players.LocalPlayer:GetAttribute("Plot")
			local fallen = myLead()
			streamed(t, "Plot", { Plot = plot })
			t.Check("on its plot", fallen ~= nil and Markers.OnPlot(if type(plot) == "number" then plot else nil, fallen:GetPivot().Position))
			t.Check("the card says it's healing, with its time", waitFor(t, 1, function(): boolean
				local status = parts.Lead:GetAttribute("Status")
				return type(status) == "string" and status:match("^Healing %d+:%d%d$") ~= nil
			end), tostring(parts.Lead:GetAttribute("Status")))
			local line = (parts.LeadHealthText :: TextLabel).Text
			t.Check("in its health line", line == parts.Lead:GetAttribute("Status"), line)
			local first = parts.LeadHealth:GetAttribute("Share") :: number
			t.Wait(1.2)
			local later = parts.LeadHealth:GetAttribute("Share") :: number
			t.Check("its bar fills as it heals", later > first, string.format("%.3f to %.3f", first, later))
			local foot = parts.Lead.AbsolutePosition.Y + parts.Lead.AbsoluteSize.Y
			t.Check("the button for the next shows under the card", parts.Next.Visible and parts.Next.AbsolutePosition.Y >= foot - 1, string.format("%.0f, the card's foot %.0f", parts.Next.AbsolutePosition.Y, foot))
			local eyeEnd = parts.Spectate.AbsolutePosition.X + parts.Spectate.AbsoluteSize.X
			t.Check("after the eye", parts.Next.AbsolutePosition.X >= eyeEnd - 1, string.format("%.0f, the eye's end %.0f", parts.Next.AbsolutePosition.X, eyeEnd))
			t.Check("and the readout stands down with the lead", not parts.Signature.Visible)
			lintClean(t, "a fallen lead's card")
			-- The next lead: the button opens the Voidkin screen, where another goes out at once.
			t.Check("the button opens the Voidkin screen", Button.Press(parts.Next :: TextButton) and waitFor(t, 1, function(): boolean
				return Screen.Current() == "Voidkin"
			end), tostring(Screen.Current()))
			local opened = VoidkinScreen.Find("Page")
			t.Check("on Overview, where Lead is (TR28: the dock's opens on the Items page)", opened ~= nil and opened:GetAttribute("Page") == "Overview", tostring(opened and opened:GetAttribute("Page")))
			local fallenRow = leadButton(was)
			t.Check("the fallen one, the lead still, reads Leading, lit: nothing to press", fallenRow ~= nil and Button.State(fallenRow) == "Selected" and VoidkinScreen.Chosen() == was, if fallenRow then Button.State(fallenRow) else "no button")
			local free = leadButton(other)
			t.Check("another's can be pressed", free ~= nil and Button.State(free) == "Rest" and VoidkinScreen.Chosen() == other, if free then Button.State(free) else "no button")
			if free then
				Button.Press(free)
			end
			t.Check("the next lead goes out at once", waitFor(t, 2, function(): boolean
				local now = myLead()
				return now ~= nil and now:GetAttribute("Voidkin") == other and now:GetAttribute("State") ~= "Home"
			end))
			Screen.Close()
			t.Check("the card is the new lead's, standing", waitFor(t, 1, function(): boolean
				return parts.Lead:GetAttribute("Status") == "" and parts.Lead:GetAttribute("Down") == false
			end), tostring(parts.Lead:GetAttribute("Status")))
			t.Check("and the button's gone", not parts.Next.Visible)
			local back = t.Server("Act", "SetLead", { Voidkin = was })
			t.Check("the fallen one can't go out until it's whole", type(back) == "table" and back.Ok == false and back.Error == "Healing", if type(back) == "table" then tostring(back.Error) else "")
			-- The first lead back for the next case.
			t.Server("LeadHeal")
			local put = t.Server("Act", "SetLead", { Voidkin = was })
			t.Check("whole, it leads again", type(put) == "table" and put.Ok == true, if type(put) == "table" then tostring(put.Error) else "")
			t.Check("back by the avatar", waitFor(t, 2, function(): boolean
				local now = myLead()
				return now ~= nil and now:GetAttribute("Voidkin") == was
			end))
		end,
	},
	{
		Name = "UI kit: a screen rebuilt in place keeps where its lists were scrolled, and a list keyed to another thing starts at its top",
		Run = function(t: any)
			-- TR15's take (2026-11-14): a tap low on a list rebuilt its screen and threw the row out of view (UI/Kit/Screen).
			Screen.Close()
			local function fill(key: string): ScrollingFrame
				local body = Screen.Open("NL_TestScroll", "Scroll test", Vector2.new(440, 300))
				local list = Row.List(body, "List")
				list:SetAttribute("Keep", key)
				for index = 1, 30 do
					Row.new({ Name = `Row{index}`, Parent = list, Order = index, Text = `Row {index}` })
				end
				return list
			end
			local first = fill("a")
			t.Wait(0.2) -- laid out
			local low = math.max(0, first.AbsoluteCanvasSize.Y - first.AbsoluteWindowSize.Y)
			t.Check("the list scrolls", low > 0, tostring(low))
			first.CanvasPosition = Vector2.new(0, low)
			t.Wait(0.1)
			local at = first.CanvasPosition.Y
			local again = fill("a")
			t.Check("rebuilt, it's where it was", at > 0 and waitFor(t, 1, function(): boolean
				return math.abs(again.CanvasPosition.Y - at) < 1
			end), `{at} kept as {again.CanvasPosition.Y}`)
			local other = fill("b")
			t.Wait(0.2)
			t.Equal("keyed to another thing, at its top", other.CanvasPosition.Y, 0)
			Screen.Close()
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
			lookAhead(t)
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
			-- TR3, part 3: its type's gem, and the type edge's arrow up or down before the first hit (Rules.Hud.Arrow).
			local theirs = Enemies.ById.brawler.Type
			local mine = Voidkin.ById[lead:GetAttribute("Def") :: string]
			local way = Hud.Arrow(if mine then mine.Type else "", theirs)
			local arrow = parts.TargetArrow
			t.Check("its type's gem", parts.TargetGem:GetAttribute("Kit") == `Gem{theirs}`, `{parts.TargetGem:GetAttribute("Kit")}`)
			t.Check(`the type edge's arrow ({if way == "" then "even: none" else way})`, arrow:GetAttribute("Way") == way and arrow.Visible == (way ~= ""), `{arrow:GetAttribute("Way")}, shown {arrow.Visible}`)
			t.Server("FightSpawn") -- clears it
			t.Check("and hides once it's gone", waitFor(t, 2, function(): boolean
				return not parts.Target.Visible
			end))
		end,
	},
	{
		Name = "HUD: the foe card's skull and level take the tier of the foe's CR over the lead's, and turn with it mid-fight (AR45)",
		Run = function(t: any)
			local parts = HudController.Parts()
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if lead == nil or type(level) ~= "number" then
				return
			end
			-- An elite of the lead's level: it stands long enough for the cuts to move under it.
			lookAhead(t)
			local spawned = t.Server("FightSpawn", "brawler_elite", level, SHADE_AHEAD)
			t.Check("the elite spawns", type(spawned) == "table" and spawned.Ok == true)
			if type(spawned) ~= "table" or spawned.Ok ~= true then
				return
			end
			t.Check("its card shows", waitFor(t, SHADE_TIMEOUT, function(): boolean
				return lead:GetAttribute("Target") == spawned.Id and parts.Target.Visible
			end))
			local skulls = HudConfig.Skulls
			local wasCuts = table.clone(skulls.Cuts)
			local function shown(): number
				local tier = parts.Target:GetAttribute("Tier")
				return if type(tier) == "number" then tier else 0
			end
			-- TR49: the tier is the fight's cost, the lead's block against the foe's (Rules.Hud.FoeTier), never grey at the
			-- lead's level or above.
			local foe = fighterModel(spawned.Id)
			local view = ProfileController.Get()
			local owned = if view then view.Voidkin[view.Roles.Lead] else nil
			local mine = if view and owned then Stats.Resolve(owned, Stats.PresetOf(view :: any, owned), view :: any) else nil
			local function theirs(model: Model?): Stats.Block?
				local def, at = if model then model:GetAttribute("Def") else nil, if model then model:GetAttribute("Level") else nil
				if model == nil or type(def) ~= "string" or type(at) ~= "number" then
					return nil
				end
				local kind, kin, most = model:GetAttribute("Kind"), model:GetAttribute("Type"), model:GetAttribute("MaxHealth")
				return Hud.FoeBlock(if type(kind) == "string" then kind else "", def, at, if type(kin) == "string" then kin else nil, nil, nil, if type(most) == "number" then most else nil)
			end
			local block = theirs(foe)
			t.Check("both sides' blocks to read", mine ~= nil and block ~= nil)
			local want = if mine and block then Hud.FoeTier(mine, block, skulls.Cuts) else 0
			t.Check("its tier by the fight's cost (Rules.Hud.FoeTier)", shown() == want, `shown {shown()}, wanted {want}`)
			local skull = parts.TargetSkull :: ImageLabel
			local words = parts.TargetLevel :: TextLabel
			-- Its own transparencies, under the card's see-through (a fighter behind it fades the whole card, Kit.Fade).
			local function worn(tier: number): boolean
				local colour = skulls.Colours[tier]
				local faint = if tier == 1 then skulls.Faint else 0
				local shows = Fade.Of(parts.Target :: GuiObject)
				return skull.ImageColor3 == colour
					and words.TextColor3 == colour
					and math.abs(words.TextTransparency - Hud.Faded(0, shows)) < 1e-3
					and math.abs(skull.ImageTransparency - Hud.Faded(faint, shows)) < 1e-3
			end
			t.Check("the skull and the level in its colour", worn(want))
			-- Mid-fight, the cuts moved under its cost and then over it: the skull turns red, then white, never grey at the
			-- lead's level (TR49); a foe under the lead's level over them, grey and faint with its level whole (research's
			-- must-fix 2).
			local ok, problem = pcall(function()
				t.Server("Tune", "Hud.Skulls.Cuts", { 1e-6, 2e-6, 3e-6 })
				local red = waitFor(t, REPLICATE, function(): boolean
					return shown() == 4
				end)
				t.Check("the cuts under its cost: red, at once", red and worn(4))
				t.Server("Tune", "Hud.Skulls.Cuts", { 1e6, 2e6, 3e6 })
				local white = waitFor(t, REPLICATE, function(): boolean
					return shown() == 2
				end)
				t.Check("over it at the lead's level: white, never grey (TR49)", white and worn(2), `shown {shown()}`)
				if level > 1 then
					t.Server("FightSpawn") -- clears it
					lookAhead(t)
					local low = t.Server("FightSpawn", "brawler", level - 1, SHADE_AHEAD)
					local met = type(low) == "table" and low.Ok == true and waitFor(t, SHADE_TIMEOUT, function(): boolean
						return lead:GetAttribute("Target") == low.Id and parts.Target.Visible
					end)
					local grey = met and waitFor(t, REPLICATE, function(): boolean
						return shown() == 1
					end)
					t.Check("a Shade a level under, over the cuts: grey and faint, its level whole", grey and worn(1), `shown {shown()}; skull {skull.ImageColor3:ToHex()} at {string.format("%.3f", skull.ImageTransparency)}, level {words.TextColor3:ToHex()} at {string.format("%.3f", words.TextTransparency)}, the card at {string.format("%.2f", Fade.Of(parts.Target :: GuiObject))}`)
				end
			end)
			t.Server("Tune", "Hud.Skulls.Cuts", wasCuts)
			t.Server("FightSpawn") -- clears it
			if not ok then
				error(problem, 0)
			end
		end,
	},
	{
		Name = "HUD: a keeper's try and an elite take their own HUD: the keeper's title card at the foot or the top, an elite's heavier frame (TR5)",
		Place = "Festival", -- TR45: its world stands in that place only
		Stay = true, -- it moves the avatar itself (a try); the next case's reset takes it back to the pad
		Run = function(t: any)
			local boss = HudConfig.Boss
			local keeper = Combat.Keeper
			local moved = keeper.Fade.Out + keeper.Fade.Hold / 2 + MOVE_SLACK
			local wasKeeper, wasElite = boss.Keeper, boss.Elite
			local parts = HudController.Parts()
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if lead == nil or type(level) ~= "number" then
				return
			end
			-- An elite's card wears the brass edge and its two shards (AR45); switched off, the plain card. A Shade's, none.
			t.Server("Tune", "Hud.Boss.Elite", true)
			lookAhead(t)
			local elite = t.Server("FightSpawn", "brawler_elite", level, SHADE_AHEAD)
			t.Check("the elite spawns", type(elite) == "table" and elite.Ok == true)
			if type(elite) == "table" and elite.Ok == true then
				t.Check("the elite's card wears its brass", waitFor(t, SHADE_TIMEOUT, function(): boolean
					return lead:GetAttribute("Target") == elite.Id and parts.Target.Visible and parts.TargetElite.Visible
				end))
				local edge = parts.Target:FindFirstChild("Edge") :: ImageLabel?
				t.Check("its edge the brass, in its own colours", edge ~= nil and edge:GetAttribute("Kit") == "CardSlantRankEdge" and edge.ImageColor3 == Color3.new(1, 1, 1))
				-- Each shard's root on the plate's top edge (foes.json's RankShardLeft and Right): standing above the card, the
				-- left one near its square corner, the right one short of where its leaning end starts.
				local plate = parts.Target
				local edgeEnd = plate.AbsolutePosition.X + plate.AbsoluteSize.X * (1 - UIKit.FoeCard.Lean * UIKit.FoeCard.Size.Y / UIKit.FoeCard.Size.X)
				local stands = 0
				for _, shard in parts.TargetElite:GetChildren() do
					if shard:IsA("ImageLabel") and shard.AbsolutePosition.Y < plate.AbsolutePosition.Y and shard.AbsolutePosition.X > plate.AbsolutePosition.X
						and shard.AbsolutePosition.X + shard.AbsoluteSize.X < edgeEnd then
						stands += 1
					end
				end
				t.Check("its two shards on its top edge, short of where it ends", stands == 2, `{stands} of 2`)
				t.Server("Tune", "Hud.Boss.Elite", false)
				t.Check("switched off, the plain card", waitFor(t, REPLICATE, function(): boolean
					return parts.Target.Visible and not parts.TargetElite.Visible
				end))
				t.Check("with the lead card's lavender rim", edge ~= nil and edge:GetAttribute("Kit") == "CardSlantEdge" and edge.ImageColor3 == UIKit.Systems.Voidkin.Colour)
				t.Server("Tune", "Hud.Boss.Elite", wasElite)
				t.Server("FightSpawn") -- clears it
			end
			lookAhead(t)
			local plain = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
			if type(plain) == "table" and plain.Ok == true then
				local met = waitFor(t, SHADE_TIMEOUT, function(): boolean
					return lead:GetAttribute("Target") == plain.Id and parts.Target.Visible
				end)
				t.Check("a Shade's card wears none", met and not parts.TargetElite.Visible)
				t.Server("FightSpawn")
			end
			-- A: the keeper's title card at the foot, its name stamped on as the Challenge's Stamp lands; the dock steps out and
			-- the target card stands aside for it.
			t.Server("Tune", "Hud.Boss.Keeper", "A")
			local def = nil
			for _, stop in WorldConfig.Row.Stops do
				def = if stop.Kind == "Keeper" then stop.Def else def
			end
			local stampedAt: number? = nil
			local watch = RunService.Heartbeat:Connect(function()
				local _, phase = HudController.Keeper()
				if phase == "Stamp" and stampedAt == nil then
					stampedAt = workspace:GetServerTimeNow()
				end
			end)
			local function restore()
				watch:Disconnect()
				t.Server("Tune", "Hud.Boss.Keeper", wasKeeper)
			end
			t.Server("KeeperRest", 0) -- TR10: a win earlier in the run rests the keeper five minutes; this case tries it now.
			local start = t.Server("KeeperTry")
			t.Check("a try starts", start.Ok == true, tostring(start.Error))
			if start.Ok ~= true then
				restore()
				return
			end
			t.Wait(moved)
			local inside = t.Server("Keeper")
			local them: Model? = nil
			waitFor(t, REPLICATE, function(): boolean
				them = fighterModel(inside.Keeper)
				return them ~= nil
			end)
			local challenge = Actions.ById[Enemies.ById[def :: string].Enter :: string]
			local at = if them then them:GetAttribute("ActionAt") else nil
			local holding = them ~= nil and them:GetAttribute("Action") == challenge.Id and type(at) == "number"
			t.Check("the keeper holds its Challenge as the avatar arrives", holding)
			t.Check("A: its name stamps on", waitFor(t, challenge.Length, function(): boolean
				return stampedAt ~= nil
			end))
			if holding and stampedAt then
				t.Near("as the Challenge's Stamp lands (seconds off)", (stampedAt :: number) - ((at :: number) + challenge.Beats.Stamp), 0, BOSS_STAMP)
			end
			t.Check("the title card comes in whole", waitFor(t, boss.Stamp.Seconds + boss.Stamp.Fill + 0.3, function(): boolean
				local shown, phase = HudController.Keeper()
				return shown == 1 and phase == "Whole"
			end))
			local name = (parts.KeeperName :: TextLabel).Text
			local row = Enemies.ById[def :: string]
			t.Check("its name, capitalised", name == string.upper(string.sub(row.Name, 1, 1)) .. string.sub(row.Name, 2), name)
			local title = (parts.KeeperTitle :: TextLabel).Text
			t.Check("its title names its ground", title == "Keeper of Lantern Row", title)
			local screen = parts.Keeper.Parent :: GuiObject
			local foot = parts.Keeper.AbsolutePosition.Y + parts.Keeper.AbsoluteSize.Y
			t.Check("A: at the foot of the screen", foot > screen.AbsolutePosition.Y + screen.AbsoluteSize.Y * 0.85, string.format("its foot at %d of %d", foot, screen.AbsoluteSize.Y))
			t.Check("the dock steps out for the try", not parts.Dock.Visible)
			t.Check("the target card stands aside for it", waitFor(t, KEEPER_MEETS, function(): boolean
				return lead:GetAttribute("Target") == inside.Keeper
			end) and not parts.Target.Visible)
			-- Each variant at the smallest phone's size, by the UI lint: on screen, apart, clear of the thumbs.
			local function lintPhone(where: string)
				Layers.Force(Theme.Scale.Floor)
				Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
				t.Wait(0.1) -- laid out again
				lintClean(t, where)
				Layers.Box(nil)
				Layers.Force(nil)
			end
			lintPhone("A, the keeper at the foot, on the smallest phone")
			-- B, the top middle (the director's pick, 2026-11-14): the same keeper's title card in the band, between the
			-- lead's card and the pills, never lower than the lead card's foot; the dock back.
			t.Server("Tune", "Hud.Boss.Keeper", "B")
			local band = parts.Lead.AbsolutePosition.Y + parts.Lead.AbsoluteSize.Y -- the lead card's foot
			local head = parts.KeeperHead
			local function inBand(): boolean
				local bar = parts.Keeper
				local leadRight = parts.Lead.AbsolutePosition.X + parts.Lead.AbsoluteSize.X
				local pills = math.min((parts.Credits.Parent :: GuiObject).AbsolutePosition.X, (parts.Electricity.Parent :: GuiObject).AbsolutePosition.X)
				return bar.AbsolutePosition.Y + bar.AbsoluteSize.Y <= band + 1
					and head.AbsolutePosition.Y >= parts.Lead.AbsolutePosition.Y - 1
					and math.min(bar.AbsolutePosition.X, head.AbsolutePosition.X) >= leadRight
					and math.max(bar.AbsolutePosition.X + bar.AbsoluteSize.X, head.AbsolutePosition.X + head.AbsoluteSize.X) <= pills
			end
			t.Check("B: the top middle, in the band between the lead's card and the pills", waitFor(t, REPLICATE, inBand),
				string.format("its foot at %d, the band's foot at %d", parts.Keeper.AbsolutePosition.Y + parts.Keeper.AbsoluteSize.Y, band))
			t.Check("the dock stays in B", parts.Dock.Visible)
			-- Its number on the bar, nothing of it below (research's verdict, 2026-11-14, fix 1).
			local number = parts.Keeper:FindFirstChild("Number") :: GuiObject
			local channel = parts.Keeper:FindFirstChild("Channel") :: GuiObject
			local numberMiddle = number.AbsolutePosition.Y + number.AbsoluteSize.Y / 2
			t.Check("its number on the bar", numberMiddle >= channel.AbsolutePosition.Y and numberMiddle <= channel.AbsolutePosition.Y + channel.AbsoluteSize.Y
				and number.AbsolutePosition.X + number.AbsoluteSize.X <= channel.AbsolutePosition.X + channel.AbsoluteSize.X)
			-- In the bar's middle, and no mark across it (the director, 2026-11-14).
			local numberCentre = number.AbsolutePosition.X + number.AbsoluteSize.X / 2
			local channelCentre = channel.AbsolutePosition.X + channel.AbsoluteSize.X / 2
			t.Check("its number in the bar's middle", math.abs(numberCentre - channelCentre) <= 1 and (number :: TextLabel).TextXAlignment == Enum.TextXAlignment.Center,
				string.format("the number's centre %.1f, the bar's %.1f", numberCentre, channelCentre))
			t.Check("no mark across the bar", parts.Keeper:FindFirstChild("Phase1") == nil)
			-- Its line art Modulo's frames (TR5, "Modulo's frames, delivered"): the rim round the channel, a cap on each end,
			-- the two rules either side of the title and the crest over its middle.
			local function framed(holder: Instance, name: string, kit: string): boolean
				local image = holder:FindFirstChild(name)
				return image ~= nil and image:IsA("ImageLabel") and image:GetAttribute("Kit") == kit and image.Image == UIKit.Images[kit].Id
			end
			local rimmed = framed(parts.Keeper, "Rim", "BossBarRim") and framed(parts.Keeper, "CapLeft", "BossBarCap") and framed(parts.Keeper, "CapRight", "BossBarCap")
			local rim = parts.Keeper:FindFirstChild("Rim") :: GuiObject?
			t.Check("its rim and caps Modulo's, the rim round the channel", rimmed and rim ~= nil and rim.AbsolutePosition.X < channel.AbsolutePosition.X
				and rim.AbsolutePosition.X + rim.AbsoluteSize.X > channel.AbsolutePosition.X + channel.AbsoluteSize.X)
			local crest = parts.KeeperHead:FindFirstChild("Crest") :: GuiObject?
			local titleLabel = parts.KeeperTitle :: GuiObject
			t.Check("its title's rules and crest Modulo's, the crest over the title's middle", framed(parts.KeeperHead, "Rule1", "BossTitleRuleLeft") and framed(parts.KeeperHead, "Rule2", "BossTitleRuleRight")
				and framed(parts.KeeperHead, "Crest", "BossTitleCrest") and crest ~= nil
				and math.abs(crest.AbsolutePosition.X + crest.AbsoluteSize.X / 2 - (titleLabel.AbsolutePosition.X + titleLabel.AbsoluteSize.X / 2)) <= 1
				and crest.AbsolutePosition.Y < titleLabel.AbsolutePosition.Y)
			-- Its name in the keeper's purple, never white (the director, 2026-11-14).
			local nameLabel = parts.KeeperHead:FindFirstChild("Name", true) :: TextLabel?
			local lit = if nameLabel then nameLabel:FindFirstChildOfClass("UIGradient") else nil
			t.Check("its name in the keeper's purple", lit ~= nil and lit.Color.Keypoints[1].Value == boss.Name[1] and lit.Color.Keypoints[#lit.Color.Keypoints].Value == boss.Name[2])
			-- Its health purple (the director's word, 2026-11-14), and a pale trail behind the fill that holds after a hit.
			t.Check("its health in the keeper's purple", (parts.KeeperFill:FindFirstChildOfClass("UIGradient") :: UIGradient).Color.Keypoints[2].Value == boss.Health)
			local under = false
			t.Check("a hit leaves the trail behind the fill", waitFor(t, KEEPER_MEETS + 3, function(): boolean
				local trail, share = HudController.KeeperTrail()
				under = under or trail < share - 1e-4
				return trail > share + 1e-3
			end))
			t.Check("and never under it", not under)
			t.Check("and the target card stands aside", not parts.Target.Visible)
			lintPhone("B, the keeper at the top, on the smallest phone")
			-- The keeper falls: the bar leaves from its fall's Gone.
			t.Check("the keeper falls", t.Server("KeeperEnd", "Win").Ok == true)
			local fellClock = os.clock()
			local fall = EffectsConfig.Falls[row.Rig :: string]
			local leftAt: number? = nil
			t.Check("the bar leaves", waitFor(t, fall.Gone / 60 + REPLICATE, function(): boolean
				local _, phase = HudController.Keeper()
				leftAt = if phase == "Leave" then os.clock() else nil
				return leftAt ~= nil
			end))
			if leftAt then
				t.Near("from the fall's Gone (seconds after the fall)", (leftAt :: number) - fellClock, fall.Gone / 60, BOSS_GONE)
			end
			t.Check("and is gone", waitFor(t, boss.Leave + 0.3, function(): boolean
				return not parts.Keeper.Visible
			end))
			restore()
			t.Wait(math.max(0, keeper.WinPause + moved - (os.clock() - fellClock)))
			t.Check("the try is over", Players.LocalPlayer:GetAttribute("Try") == nil)
		end,
	},
	{
		Name = "HUD: in a fight with a shard in the bag, on the smallest phone, every piece fits, apart and in the safe area",
		Run = function(t: any)
			-- TR3's check: the UI lint at the smallest phone's scale (docs/ui.md, rule 1). The lead's card, the target's, both
			-- pills, the readout, the eye and the dock all showing at once, laid out in this window's safe area and then in the
			-- smallest phone's (Theme.Smallest under Roblox's top bar, at the scale's floor). The shards' hint stays home (the
			-- director, 2026-11-15): its own fit is checked at the base, in the Breaker's case.
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if lead == nil or type(level) ~= "number" then
				return
			end
			local parts = HudController.Parts()
			lookAhead(t)
			local spawned = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
			local gave = t.Server("BaseGive", "named_watt", 1)
			local shown = waitFor(t, SHADE_TIMEOUT, function(): boolean
				return parts.Target.Visible and parts.Signature.Visible
			end)
			t.Check("a fight, and a shard in the bag", type(spawned) == "table" and spawned.Ok == true and shown)
			t.Check("no hint in the grounds", not parts.Chip.Visible)
			local top = GuiService.TopbarInset.Height
			local sizes = {
				{ Name = "this window", Scale = nil :: number?, Box = nil :: Vector2? },
				{ Name = "the smallest phone", Scale = Theme.Scale.Floor, Box = Theme.Smallest - Vector2.new(0, top) },
			}
			for _, at in sizes do
				Layers.Force(at.Scale)
				Layers.Box(at.Box)
				t.Wait(0.1) -- laid out again
				lintClean(t, `the HUD in a fight, in {at.Name}`)
			end
			Layers.Box(nil)
			Layers.Force(nil)
			t.Server("FightSpawn") -- clears it
			if type(gave) == "table" and gave.Ok == true then
				t.Server("BaseGive", "named_watt", -1)
			end
		end,
	},
	{
		Name = "HUD: the signature's readout shows only in a fight, empties and flashes when it fires, and fills over its cooldown",
		Run = function(t: any)
			-- TR3, part 5, in AR12's look: in the lead's corner, under its card. The server says when the signature is ready
			-- again (FightService, Ready); the readout flashes the moment it fires, then fills with the cooldown, the
			-- signature's own icon on its plate (its class's glyph while none is drawn).
			t.Wait(LEAD_SETTLE)
			local lead = myLead()
			local def = if lead then lead:GetAttribute("Def") else nil
			local signature: Actions.Action? = nil
			for _, action in Actions.KitOf(if type(def) == "string" then def else "") do
				if action.Cooldown > 0 then
					signature = action
				end
			end
			local ring = HudController.Parts().Signature
			if lead == nil or signature == nil then
				t.Check("a lead without a signature has no readout", lead ~= nil and not ring.Visible)
				return
			end
			local action = signature :: Actions.Action
			-- Only in a fight (TR3's verdict, fix 5): hidden out of one, in as the lead takes a target, out a moment after.
			local config = HudConfig.Readout
			local card = HudController.Parts().Lead :: GuiObject
			local dx = (ring.Position.X.Offset - config.Size / 2) - card.Position.X.Offset
			local dy = (ring.Position.Y.Offset - config.Size / 2) - (card.Position.Y.Offset + card.Size.Y.Offset)
			t.Check("under the lead's card, at its left", math.abs(dx - config.Right) < 0.01 and math.abs(dy - config.Under) < 0.01, string.format("%.1f right, %.1f under", dx, dy))
			local function target(): boolean
				local id = lead:GetAttribute("Target")
				return type(id) == "string" and id ~= ""
			end
			waitFor(t, config.Linger + config.FadeOut + 2, function(): boolean
				return not target() and not ring.Visible
			end)
			t.Check("out of a fight, the readout is hidden", not ring.Visible, `target {tostring(lead:GetAttribute("Target"))}`)
			local level = lead:GetAttribute("Level")
			local spawned = t.Server("FightSpawn", "brawler", (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD)
			t.Check("a Shade to fight spawns", type(spawned) == "table" and spawned.Ok == true)
			t.Check("the lead takes it on", waitFor(t, SHADE_TIMEOUT, target))
			t.Wait(config.FadeIn + 0.1)
			t.Check("in a fight, the readout fades in", ring.Visible and ring:GetAttribute("Seen") == 1, `{tostring(ring:GetAttribute("Seen"))} in`)
			t.Server("FightSpawn") -- clears it
			t.Check("the fight ends", waitFor(t, 2, function(): boolean
				return not target()
			end))
			t.Wait(config.Linger / 2)
			t.Check("it stays a moment after", ring.Visible and ring:GetAttribute("Seen") == 1, `{tostring(ring:GetAttribute("Seen"))} in`)
			t.Wait(config.Linger / 2 + config.FadeOut + 0.15)
			t.Check("then fades out", not ring.Visible, `{tostring(ring:GetAttribute("Seen"))} in`)
			local row = Voidkin.ById[def :: string]
			local own = config.Icons[action.Id]
			local want = if own and UIKit.Images[own] then own elseif row then `Class{row.Class}Glyph` else ""
			local icon = ring:FindFirstChild("Icon")
			t.Check("with its signature's icon, or its class's glyph while none is drawn", icon ~= nil and icon:GetAttribute("Kit") == want and ring:GetAttribute("Icon") == want, `{ring:GetAttribute("Icon")}, wanted {want}`)
			t.Check("ready, the plate is white-hot", waitFor(t, action.Cooldown + 1, function(): boolean
				return ring:GetAttribute("Share") == 1 and ring:GetAttribute("Hot") == 1
			end), `{tostring(ring:GetAttribute("Share"))} full, {tostring(ring:GetAttribute("Hot"))} hot`)
			local flash = 0
			local watch = RunService.RenderStepped:Connect(function()
				flash = math.max(flash, (ring:GetAttribute("Flash") :: number?) or 0)
			end)
			local ready = (lead:GetAttribute("Ready") :: number?) or 0
			local started = t.Server("Replay", action.Id, action.Length + REPLAY_PAUSE)
			t.Check("the replay starts", type(started) == "table" and started.Ok == true)
			local fired = waitFor(t, 3, function(): boolean
				local now = lead:GetAttribute("Ready")
				return type(now) == "number" and now > ready + 1e-3
			end)
			t.Check("the server says when it's ready again", fired)
			t.Wait(2 / 60)
			local first = (ring:GetAttribute("Share") :: number?) or 1
			local at = os.clock()
			t.Check("it empties as it fires", first < 0.1, string.format("%.3f", first))
			t.Wait(2)
			local second = (ring:GetAttribute("Share") :: number?) or 0
			watch:Disconnect()
			t.Check("charging, the white-hot plate is gone", second >= 1 or ring:GetAttribute("Hot") == 0, tostring(ring:GetAttribute("Hot")))
			t.Check("it flashed when it fired", flash > 0.5, string.format("%.2f", flash))
			t.Near("it fills with the cooldown", second - first, (os.clock() - at) / action.Cooldown, 0.03)
			t.Server("Replay")
			t.Wait(0.3)
		end,
	},
	{
		-- AR12 (V2, Block): the readout alone, through the states it must show.
		Name = "HUD: AR12, the readout draws its states: the level, white-hot when ready, the flash, a glyph for a signature not drawn yet",
		Run = function(t: any)
			local config = HudConfig.Readout
			local holder = Instance.new("Frame")
			holder.Name = "SelfTestReadout"
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.fromOffset(config.Size, config.Size)
			holder.Position = UDim2.fromOffset(-500, -500) -- off the screen
			holder.Parent = Layers.Get("Hud")
			local piece = Readout.new(holder)
			local drawn = next(config.Icons)
			local function state(share: number, flash: number?, seen: number?, action: string?): Readout.State
				return { Share = share, Full = share >= 1, Flash = flash or 0, Swell = 0, Seen = seen or 1, Action = action or drawn or "", Class = "Warrior" }
			end
			local turn, length = Hud.FrontTurn(config.Well[4] - config.Well[2], config.Lean)
			Readout.Step(piece, state(0.5))
			t.Near("the front leans as the bars do (degrees)", piece.Front.Rotation, turn, 1e-3)
			t.Check("the light is the well's own shape, under one gradient", piece.Light:GetAttribute("Kit") == "ReadoutLight" and piece.Front.Parent == piece.Light)
			t.Check("its gradient as long as the well's reach along it", length > config.Well[4] - config.Well[2])
			for _, share in { 0, 0.25, 0.5, 0.99 } do
				Readout.Step(piece, state(share))
				t.Near(`at {share}: it says how full`, piece.Frame:GetAttribute("Share") :: number, share, 1e-6)
				-- Its carry turned with the gradient (Rules.Hud.FrontShift): Roblox moves a gradient along its element's axes.
				local x, y = Hud.FrontShift(Hud.FrontOffset(share, config.Travel), piece.Front.Rotation)
				t.Near(`at {share}: the front stands at its level, across`, piece.Front.Offset.X, x, 1e-6)
				t.Near(`at {share}: the front stands at its level, down`, piece.Front.Offset.Y, y, 1e-6)
				t.Check(`at {share}: charging, the icon in light and no white-hot plate`, piece.Icon.ImageTransparency < 0.01 and piece.Ready.ImageTransparency > 0.99 and piece.ReadyIcon.ImageTransparency > 0.99)
			end
			Readout.Step(piece, state(1))
			t.Check("ready: the white-hot plate, its icon dark on the light", piece.Ready.ImageTransparency < 0.01 and piece.ReadyIcon.ImageTransparency < 0.01 and piece.Icon.ImageTransparency > 0.99)
			if drawn then
				t.Check("the signature's own icon, charging and ready", piece.Icon:GetAttribute("Kit") == config.Icons[drawn] and piece.ReadyIcon:GetAttribute("Kit") == config.Icons[drawn] .. "Ready", tostring(piece.Icon:GetAttribute("Kit")))
			end
			Readout.Step(piece, state(0, 1))
			t.Check("as it fires it swells", piece.Scale.Scale > 1.1, string.format("%.2f", piece.Scale.Scale))
			t.Check("and the white-hot plate is still whole", piece.Ready.ImageTransparency < 0.01)
			Readout.Step(piece, state(0.05, 0.5))
			t.Near("half through the flash, the plate is half gone", piece.Ready.ImageTransparency, 0.5, 0.01)
			Readout.Step(piece, state(0.5, 0, 0))
			local hidden = piece.Icon.ImageTransparency > 0.99 and piece.Ready.ImageTransparency > 0.99
			for _, image in piece.Charging do
				hidden = hidden and image.ImageTransparency > 0.99
			end
			t.Check("faded out, every layer is", hidden)
			Readout.Step(piece, state(0.5, 0, 1, "SelfTestNoIcon"))
			t.Check("a signature not drawn yet shows its class's glyph in light", piece.Icon:GetAttribute("Kit") == "ClassWarriorGlyph" and piece.Icon.ImageColor3 == UIKit.Light, tostring(piece.Icon:GetAttribute("Kit")))
			t.Check("and in ink on the white-hot plate", piece.ReadyIcon:GetAttribute("Kit") == "ClassWarriorGlyph" and piece.ReadyIcon.ImageColor3 == config.Ink)
			holder:Destroy()
		end,
	},
	{
		-- AR12 (V2, Block; docs/ui.md, rule 3): each pill in its system's colour, and the HUD's face one value.
		Name = "HUD: AR12, the pills wear their systems' colours, and the HUD's text takes the face named, at once",
		Run = function(t: any)
			t.Wait(LEAD_SETTLE)
			local parts = HudController.Parts()
			for name, system in { Credits = "Credits", Electricity = "Power", ChipText = "Voidkin" } :: { [string]: string } do
				local value = parts[name] :: TextLabel
				local pill = value.Parent :: GuiObject
				local row = UIKit.Systems[system]
				local mark = pill:FindFirstChild("Mark")
				local block = pill:FindFirstChild("Block", true)
				t.Check(`{name}: {system}'s pill`, pill:GetAttribute("System") == system, tostring(pill:GetAttribute("System")))
				t.Check(`{name}: its mark in ink on its block of colour`, mark ~= nil and mark:GetAttribute("Kit") == row.Mark and block ~= nil and block:GetAttribute("Kit") == "BlockPill", if mark then tostring(mark:GetAttribute("Kit")) else "no mark")
				-- Power's words turn its warning while the battery covers a shortfall (HudController; the battery's own
				-- case checks when), so a save with its bays empty reads too.
				local warned = system == "Power" and pill:GetAttribute("Over") == true
				t.Check(`{name}: its words in its pale ink{if warned then ", here Power's warning: the battery covers a shortfall" else ""}`,
					value.TextColor3 == (if warned then Theme.Colour.Over else row.Text), value.TextColor3:ToHex())
			end
			local wasFace, wasSmall = HudConfig.Face, HudConfig.FaceSmall
			local value, name = parts.Credits :: TextLabel, parts.LeadName :: TextLabel
			local menu = Text.new({ Name = "SelfTestFace", Font = Theme.Font.Strong, Parent = Layers.Get("Menus") })
			for face, row in HudConfig.Faces do
				HudConfig.Face = face
				t.Wait(0.1)
				t.Check(`{face}: the pill's value wears it`, value.FontFace.Family == row.Family and value.FontFace.Weight.Name == row.Strong, `{value.FontFace.Family} {value.FontFace.Weight.Name}`)
				t.Check(`{face}: and the lead's name`, name.FontFace.Family == row.Family, name.FontFace.Family)
				local joined = Text.new({ Name = "SelfTestFace", Font = Theme.Font.Number, Parent = Layers.Get("Hud") })
				t.Check(`{face}: a label that joins the HUD wears it too`, joined.FontFace.Family == row.Family and joined.FontFace.Weight.Name == row.Number, `{joined.FontFace.Family} {joined.FontFace.Weight.Name}`)
				joined:Destroy()
				t.Check(`{face}: a menu's label keeps the kit's face`, menu.FontFace == Theme.Font.Strong)
				-- How each candidate fits, for research's pick: a measure, not a bar (only the face in use is held to the lint).
				t.Wait(0.4) -- its widths arrive (Text.Wide)
				local report = UiLint.Run()
				t.Row(`{face}: labels that don't fit their box`, nil, nil, #report.Fit, "labels")
				t.Row(`{face}: pieces of the HUD that overlap`, nil, nil, #report.Overlap, "pairs")
			end
			-- A plainer face for small text, when one's named.
			local big, small = "Sarpanch", "BuilderSans"
			HudConfig.Face, HudConfig.FaceSmall = big, small
			t.Wait(0.1)
			local under = (Text.Authored(value) or math.huge) < HudConfig.FaceSmallUnder
			t.Check("a small face named: a label authored under its line wears it", under and value.FontFace.Family == HudConfig.Faces[small].Family, `{Text.Authored(value)} pt, {value.FontFace.Family}`)
			local tall = Text.new({ Name = "SelfTestFace", Size = HudConfig.FaceSmallUnder + 2, Font = Theme.Font.Strong, Parent = Layers.Get("Hud") })
			t.Check("and a larger one keeps the HUD's", tall.FontFace.Family == HudConfig.Faces[big].Family, tall.FontFace.Family)
			tall:Destroy()
			menu:Destroy()
			HudConfig.Face, HudConfig.FaceSmall = wasFace, wasSmall
			t.Wait(0.5)
			local back = HudConfig.Faces[wasFace] or HudConfig.Faces.BuilderSans
			t.Check("put back, the HUD wears its own face again", value.FontFace.Family == back.Family, value.FontFace.Family)
			lintClean(t, "the HUD in its own face")
		end,
	},
	{
		-- TR10 (research's entry, 2026-11-14): the elite down shows its marker over its square, with the server's time left
		-- and its loot's chances from Rules.Drops, its card folded far and unfolding near (Badge); this player's keeper resting
		-- shows at its gate, its Challenge hidden for them, and a try asked meanwhile is refused.
		Name = "World: TR10, the elite's and the keeper's markers while they're down, and a resting keeper refuses a try",
		Place = "Festival", -- TR45: its world stands in that place only
		Run = function(t: any)
			t.Wait(LEAD_SETTLE)
			local config = HudConfig.Down
			local was = { Near = config.Near }
			local function restore()
				config.Near = was.Near
				t.Server("PackBack", SQUARE_ELITE.Name)
				t.Server("PackBack", ELITE_STAND.Pack)
				t.Server("KeeperRest", 0)
			end
			-- Down the street from the square, past the badge's Near, so the place stays streamed in (the test pad is too
			-- far to keep it) and its card waits: the pack there felled first, so nothing notices the avatar.
			local served = t.Server("TestStream", "Elite", { Stage = SQUARE_ELITE.Stage })
			if typeof(served) == "Vector3" then
				t.Server("PackDefeat", ELITE_STAND.Pack)
				local at = served + Vector3.new(0, R6_ROOT_HEIGHT + 0.6, config.Near + ELITE_STAND.Past)
				t.Server("TestStandAt", at, served)
			end
			local elite = streamed(t, "Elite", { Stage = SQUARE_ELITE.Stage })
			t.Check("the elite's square", elite ~= nil)
			t.Check("the keeper's gate and its ring", streamed(t, "KeeperGate") ~= nil and streamed(t, "Ring") ~= nil)
			if elite == nil then
				restore()
				return
			end
			local felled = t.Server("PackDefeat", SQUARE_ELITE.Name)
			t.Check("the elite falls", felled.Ok == true, tostring(felled.Error))
			local function plateOf(kind: string): Frame?
				return DownController.Plate(kind)
			end
			local function shows(kind: string): boolean
				local plate = plateOf(kind)
				return plate ~= nil and World.Where(plate) ~= nil and ((plate:GetAttribute("Left") or 0) :: number) > 0
			end
			t.Check("its marker shows over its square", waitFor(t, REPLICATE, function(): boolean
				return shows("Elite")
			end))
			local plate = plateOf("Elite")
			if plate == nil then
				restore()
				return
			end
			local back = WorldConfig.Row.Back.Elite
			local left = plate:GetAttribute("Left") :: number
			t.Check("the time left is the server's, from its fall", left > back - 5 and left <= back, `{left} of {back}`)
			local where = World.Where(plate) :: Vector3
			local square = Markers.At(elite).Position
			t.Near("over the square (studs off, flat)", Vector3.new(where.X - square.X, 0, where.Z - square.Z).Magnitude, 0, 0.01)
			t.Check("above it", where.Y > square.Y + 4)
			local level = elite:GetAttribute("Level")
			local ground = elite:GetAttribute("Ground")
			local chances = {}
			for _, line in Drops.Card("Elite", level, if type(ground) == "string" then ground else WorldConfig.Row.Ground) do
				table.insert(chances, tostring(line.Chance))
			end
			t.Equal("its card's chances are Rules.Drops'", plate:GetAttribute("Chances"), table.concat(chances, ","))
			t.Equal("Credits, experience and the shard", plate:GetAttribute("Lines"), 3)
			t.Wait(1.2)
			t.Check("it counts down", (plate:GetAttribute("Left") :: number) < left)
			-- Badge (research's pick, 2026-11-23): past Near its card stays folded, only the tile and its time; near, it unfolds.
			t.Check("far: its card folded", plate:GetAttribute("Unfold") == 0 and plate:GetAttribute("Card") == false)
			config.Near = 1e6
			t.Check("near: its card unfolds whole", waitFor(t, config.Unfold + 0.5, function(): boolean
				return plate:GetAttribute("Card") == true
			end))
			t.Check("as tall as it holds", plate.Size.Y.Offset > config.Icon and plate.Size.Y.Offset < 260, `{plate.Size.Y.Offset}`)
			config.Near = was.Near
			t.Check("far again: it folds away", waitFor(t, config.Unfold + 0.5, function(): boolean
				return plate:GetAttribute("Unfold") == 0
			end))
			-- Back: its marker goes.
			t.Check("the elite is back at once for the test", t.Server("PackBack", SQUARE_ELITE.Name).Ok == true)
			t.Check("its marker goes", waitFor(t, REPLICATE, function(): boolean
				return not shows("Elite")
			end))
			-- This player's keeper, resting.
			local rest = t.Server("KeeperRest", WorldConfig.Row.Back.Keeper)
			t.Check("the keeper rests", rest.Ok == true and (rest.Resting or 0) > 0, tostring(rest.Error))
			t.Check("its marker shows at the gate", waitFor(t, REPLICATE, function(): boolean
				local plate = plateOf("Keeper")
				-- this rest's, not one an earlier case's win left
				return shows("Keeper") and plate ~= nil and (plate:GetAttribute("Left") :: number) > WorldConfig.Row.Back.Keeper - 5
			end))
			local keeper = plateOf("Keeper")
			local gate = Markers.Find("KeeperGate")
			if keeper and gate then
				local at = World.Where(keeper) :: Vector3
				local foot = Markers.At(gate).Position
				t.Near("over the gate (studs off, flat)", Vector3.new(at.X - foot.X, 0, at.Z - foot.Z).Magnitude, 0, 0.01)
				t.Check("five minutes left", (keeper:GetAttribute("Left") :: number) > WorldConfig.Row.Back.Keeper - 5)
				t.Equal("its card", keeper:GetAttribute("Lines"), 3)
			end
			local prompt = DownController.Challenge()
			t.Check("its Challenge hidden for this player", prompt ~= nil and prompt.Enabled == false)
			t.Equal("a try meanwhile is refused", t.Server("KeeperTry").Error, "Resting")
			t.Check("the keeper's state says so", (t.Server("Keeper").Resting or 0) > 0)
			t.Server("KeeperRest", 0)
			t.Check("back: its marker goes and its Challenge shows", waitFor(t, REPLICATE, function(): boolean
				local p = DownController.Challenge()
				return not shows("Keeper") and p ~= nil and p.Enabled
			end))
			restore()
		end,
	},
	{
		Name = "HUD: a shard in the bag: the chip names the next step, and the Breaker's plate is lit until it's in",
		Place = "Main", -- TR45: its world stands in that place only
		Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
		Run = function(t: any)
			-- Home is the server's respawn and the field is the test pad: a far marker isn't streamed in to this client.
			local hud = HudController.Parts()
			-- The plates are laid again with the world, so the Breaker's may be on its way back.
			local plate, panel = nil :: Instance?, nil :: Instance?
			waitFor(t, ANSWER, function(): boolean
				plate = BaseController.Parts().BreakerPlate
				panel = if plate then plate:FindFirstChild("Panel") else nil
				return panel ~= nil
			end)
			t.Check("the Breaker's plate", panel ~= nil, `plate {plate ~= nil}, panel {panel ~= nil}`)
			if not panel then
				return
			end
			local function held(): number
				local view = ProfileController.Get()
				local total = 0
				for _, count in (if view then view.Bag.Shards else {}) do
					total += count
				end
				return total
			end
			local before = held()
			local shard = "named_watt"
			t.Check("a shard goes in the bag", t.Server("BaseGive", shard, 1).Ok == true)
			t.Check("and the save's copy has it", waitFor(t, ANSWER, function(): boolean
				return held() == before + 1
			end))
			local text = hud.ChipText :: TextLabel
			local old = Players.LocalPlayer.Character
			t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, ARRIVE_TIMEOUT, function(): boolean
				local character = Players.LocalPlayer.Character
				local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
				return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
			end))
			t.Wait(PLATE_TICK * 2)
			-- into the Breaker, or, where breaks already wait in it, those first (Rules.Hud.NextStep, TR24's fix 1)
			local readyFirst = string.find(text.Text, "at the Breaker", 1, true) ~= nil
			t.Check("at home, the hint says into the Breaker", hud.Chip.Visible and (string.find(text.Text, "into the Breaker", 1, true) ~= nil or readyFirst), text.Text)
			t.Check("in the Voidkin's colour", hud.Chip:GetAttribute("System") == "Voidkin")
			Layers.Force(Theme.Scale.Floor)
			Layers.Box(Theme.Smallest - Vector2.new(0, GuiService.TopbarInset.Height))
			t.Wait(0.1) -- laid out again
			lintClean(t, "the HUD at home with the hint, on the smallest phone")
			Layers.Box(nil)
			Layers.Force(nil)
			t.Wait(0.1)
			t.Check("and the Breaker's plate is lit", panel:GetAttribute("Lit") == true) -- its edge bold in the accent (Panel.Lit)
			t.Reset() -- the test pad, off the plot
			t.Wait(PLATE_TICK * 2)
			t.Check("in the field, no hint (the director, 2026-11-15: only at the base)", not hud.Chip.Visible, text.Text)
			t.Check("the shard comes back out of the bag", t.Server("BaseGive", shard, -1).Ok == true)
			t.Check("as it was", waitFor(t, ANSWER, function(): boolean
				return held() == before
			end))
			t.Wait(PLATE_TICK * 2)
			if before == 0 then
				t.Check("an empty bag: no chip", not hud.Chip.Visible, text.Text)
				local view = ProfileController.Get()
				if view and #view.Base.Ready == 0 then -- a shard waiting to open lights it too
					t.Check("and the plate unlit", panel:GetAttribute("Lit") ~= true)
				end
			end
		end,
	},
	{
		Name = "HUD: a machine's plate with news never hides under the top band",
		Place = "Main", -- TR45: its world stands in that place only
		Run = function(t: any)
			-- The phone pack, part two (2026-11-13): at the plot on a phone, the Breaker's plate ("Ready to open") stood under
			-- the lead's card. The camera is turned so the Breaker's point is halfway up the band on the lead card's side; its
			-- plate must show whole under the band.
			local world = Layers.Get("World")
			local plate: Frame? = nil
			waitFor(t, ANSWER, function(): boolean
				plate = BaseController.Parts().BreakerPlate :: Frame?
				return plate ~= nil and plate:FindFirstChild("Panel") ~= nil
			end)
			t.Check("the Breaker's plate", plate ~= nil)
			if plate == nil then
				return
			end
			-- A shard breaking: a line of the plate's own (what's ready is the next step's line, left off the plate).
			local shard = "lanternrow_standard"
			local before = readyCount(shard)
			local gave = t.Server("BaseGive", shard, 1)
			local added = type(gave) == "table" and gave.Ok == true and ProfileController.Act("AddShard", { Shard = shard }).Ok == true
			t.Check("a shard breaking: the plate has a line", added)
			local old = Players.LocalPlayer.Character
			t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, ARRIVE_TIMEOUT, function(): boolean
				local character = Players.LocalPlayer.Character
				local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
				return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
			end))
			local prompt = BaseController.Parts().BreakerPrompt
			local anchor = if prompt then prompt.Parent :: BasePart? else nil
			-- A plate speaks only near its machine and hides over the avatar (research's must-fixes, 2026-11-17): the avatar
			-- stands 7 studs short of the Breaker, and the camera between them, the avatar behind it.
			local root = t.Root()
			local back = Vector3.zAxis
			if anchor and root then
				local ground = Vector3.new(anchor.Position.X, root.Position.Y, anchor.Position.Z)
				local away = Vector3.new(root.Position.X - ground.X, 0, root.Position.Z - ground.Z)
				back = if away.Magnitude > 1e-3 then away.Unit else back
				t.Server("TestStandAt", ground + back * 7, ground)
			end
			t.Wait(PLATE_TICK * 2)
			local camera = workspace.CurrentCamera
			local band = world:GetAttribute("Band")
			-- The plate's own point, over the gantry's lamp: from 7 studs, its lift over the anchor is a third of the screen.
			local over = World.Where(plate)
			t.Check("its point, and the band", over ~= nil and camera ~= nil and type(band) == "number", tostring(band))
			if anchor and over and camera and type(band) == "number" then
				local scale = Layers.Scale()
				local at = Vector2.new(camera.ViewportSize.X * 0.15, band * scale * 0.5)
				camera.CameraType = Enum.CameraType.Scriptable
				-- Turned so the pixel `at` looks along the line to the point: its direction in the camera's frame is turned
				-- onto the camera's forward.
				camera.CFrame = CFrame.lookAt(anchor.Position + back * 4 + Vector3.new(0, 3, 0), over)
				local aside = camera.CFrame:VectorToObjectSpace(camera:ViewportPointToRay(at.X, at.Y).Direction)
				camera.CFrame *= CFrame.fromRotationBetweenVectors(aside, Vector3.new(0, 0, -1))
				for _ = 1, 3 do
					RunService.RenderStepped:Wait()
				end
				local point = camera:WorldToViewportPoint(over)
				t.Check("the Breaker's point is over the band", point.Y / scale < band, string.format("%.1f against %.1f", point.Y / scale, band))
				t.Check("its plate shows", plate.Visible and plate.Parent ~= nil)
				local top = (plate.AbsolutePosition.Y - world.AbsolutePosition.Y) / scale - band
				t.Check("whole under the band", top >= -1, string.format("its top %.1f px under the band", top))
				t.Check("and right under it, not lost lower", top <= 2, string.format("its top %.1f px under the band", top))
				camera.CameraType = Enum.CameraType.Custom
			end
			if added then
				t.Server("BaseSkip", SKIP_ALL)
				waitFor(t, ANSWER, function(): boolean
					return readyCount(shard) > before
				end)
				openReadyDown(t, shard, before)
			end
		end,
	},
	{
		Name = "Base: the plot's Breaker, bays and battery carry their prompt and plate; the dock opens each screen",
		Place = "Main", -- TR45: its world stands in that place only
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
			-- Every open bay has its spot on the plot. A spot beyond the open ones shows locked (the loop above): base level 1
			-- opens two (TR21), today's plot has two, and AR16's plot brings the later bays' spots.
			t.Check("the plot has a spot for every open bay", index - 1 >= #view.Base.Bays, `{index - 1} bays, {#view.Base.Bays} open`)
			local hud = HudController.Parts()
			for _, name in { "Base", "Voidkin" } do
				Screen.Close()
				if name == "Base" then
					BaseController.Open() -- as a bay's prompt opens it: the dock's Base tile is the way home (TR19)
				else
					t.Check(`the dock's {name} can be pressed`, Button.Press(hud[name] :: TextButton))
				end
				t.Check(`and opens the {name} screen`, waitFor(t, 1, function(): boolean
					return Screen.Current() == name
				end))
				t.Wait(HudConfig.Motion.Screen.Enter + 0.1) -- laid out, and in
				lintClean(t, `the {name} screen`)
			end
			Screen.Close()
		end,
	},
	{
		Name = "UI: a screen stands below Roblox's top bar, and shrinks to the room it has",
		Run = function(t: any)
			local root = Layers.Get("Menus")
			local gui = root.Parent :: ScreenGui
			t.Check("the screens' layer keeps clear of the top bar and the notch", not gui.IgnoreGuiInset and gui.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets)
			local bar = GuiService:GetGuiInset().Y
			local top = Layers.Get("World").AbsolutePosition.Y -- the full-bleed layer starts at the screen's top
			t.Check("its room starts below the top bar", root.AbsolutePosition.Y - top >= bar - 0.5, `{root.AbsolutePosition.Y - top} px down, the bar {bar}`)
			local function inside(frame: GuiObject): boolean
				local a, b = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
				local c, d = root.AbsolutePosition, root.AbsolutePosition + root.AbsoluteSize
				return a.X >= c.X - 0.5 and a.Y >= c.Y - 0.5 and b.X <= d.X + 0.5 and b.Y <= d.Y + 0.5
			end
			BaseController.Open()
			local frame = Screen.Frame("Base")
			t.Check("the Base screen opens", frame ~= nil)
			if frame == nil then
				return
			end
			local authored = frame.Size.Y.Offset
			t.Wait(HudConfig.Motion.Screen.Enter + 0.1) -- laid out, and in
			t.Check("it stands within the room", inside(frame), `{frame.AbsolutePosition} {frame.AbsoluteSize}`)
			-- A screen too short for it: the scale that leaves 250 authored pixels of room.
			Layers.Force(root.AbsoluteSize.Y / 250)
			t.Wait(0.1)
			t.Check("on a short screen, it shrinks to the room", frame.Size.Y.Offset < authored and inside(frame), `{frame.Size.Y.Offset} of {authored} authored`)
			Layers.Force(nil)
			t.Wait(0.1)
			t.Check("and grows back with the room", frame.Size.Y.Offset == authored and inside(frame), `{frame.Size.Y.Offset} of {authored} authored`)
			lintClean(t, "the Base screen, fitted")
			Screen.Close()
		end,
	},
	{
		-- Research's must-fix on AR16 (2026-11-17): a world plate never stands over the player's own avatar, and one fact
		-- shows once on the screen. From afar, a machine's news is the next step's line over the dock; its plate only lights.
		Name = "Base: the plot's plates speak only near their machine, never over the avatar nor saying the next step's fact, and the battery's says only its name",
		Place = "Main", -- TR45: its world stands in that place only
		Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
		Run = function(t: any)
			local view = ProfileController.Get()
			local says = BaseController.Says()
			local breaker, battery = says.Breaker, says.Battery
			t.Check("the plot's spots are here", view ~= nil and breaker ~= nil and battery ~= nil)
			if view == nil or breaker == nil or battery == nil then
				return
			end
			local parts = BaseController.Parts()
			local flat = battery.Ground - breaker.Ground
			local back = Vector3.new(flat.X, 0, flat.Z).Unit -- from the Breaker toward the spawn
			local function stand(at: Vector3, look: Vector3)
				t.Server("TestStandAt", at + Vector3.new(0, 3, 0), look)
				t.Wait(0.1) -- the camera's focus follows the avatar
				-- The camera keeps its own look (FadeController): turned to the avatar's, a little down, as a player would,
				-- at the distance it had. Through CameraTurn: a phone's camera undoes a turn written straight to it, and
				-- the plates then stood behind it (the full pass in the phone emulation, 2026-11-15).
				local camera = workspace.CurrentCamera
				local along = Vector3.new(look.X - at.X, 0, look.Z - at.Z)
				if camera and along.Magnitude > 1e-3 then
					local focus = camera.Focus.Position
					local far = (camera.CFrame.Position - focus).Magnitude
					local down = math.rad(15)
					local toward = along.Unit * math.cos(down) - Vector3.new(0, math.sin(down), 0)
					CameraTurn.To(CFrame.lookAt(focus - toward * far, focus))
				end
				t.Wait(PLATE_TICK + 0.3) -- the plates read at 4 Hz
			end
			local function plateOf(name: string): Frame
				return parts[`{name}Plate`] :: Frame
			end
			local function lit(name: string): boolean
				local panel = plateOf(name):FindFirstChild("Panel")
				return panel ~= nil and panel:GetAttribute("Lit") == true -- its edge bold in the accent (Panel.Lit)
			end
			-- What the save says each spot has to do: a shard to put in or open, a bay a free Voidkin could take.
			local function news(): { [string]: boolean }
				local now = ProfileController.Get() :: any
				local bagged, free = false, false
				for _, count in now.Bag.Shards do
					bagged = bagged or count > 0
				end
				for id in now.Voidkin do
					free = free or Read.Role(now, id) == ""
				end
				-- the battery, the Training machine (TR12) and the generator (TR18) only say what they are
				local out: { [string]: boolean } = { Breaker = bagged or #now.Base.Ready > 0, Battery = false, Training = false, Generator = false }
				for name in BaseController.Says() do
					local index = tonumber(name:match("^Bay(%d+)$"))
					if index then
						local bay: any = now.Base.Bays[index]
						out[name] = bay ~= nil and bay.Worker == "" and free
					end
				end
				return out
			end
			-- Every plate whose spot isn't near is hidden, news or not, and none that shows stands over the avatar; each spot's
			-- news is the save's, and lights its plate.
			local function quiet(where: string)
				local want = news()
				local wrong, loud, over = {}, {}, {}
				for name, spot in BaseController.Says() do
					if spot.News ~= want[name] or lit(name) ~= want[name] then
						table.insert(wrong, `{name} {spot.News}/{lit(name)}, the save {want[name]}`)
					end
					if not spot.Near and plateOf(name).Visible then
						table.insert(loud, name)
					end
					if plateOf(name).Visible and World.OnAvatar(plateOf(name)) then
						table.insert(over, name)
					end
				end
				t.Check(`{where}: each plate's news and its light are the save's`, #wrong == 0, table.concat(wrong, "; "))
				t.Check(`{where}: a plate not near hides, news or not`, #loud == 0, table.concat(loud, ", "))
				t.Check(`{where}: no plate stands over the avatar`, #over == 0, table.concat(over, ", "))
			end
			local function nearOnes(): string
				local list = {}
				for name, spot in BaseController.Says() do
					if spot.Near then
						table.insert(list, name)
					end
				end
				table.sort(list)
				return table.concat(list, ", ")
			end

			stand(battery.Ground + back * 24, breaker.Ground)
			t.Check("far from every machine, none is near", nearOnes() == "", nearOnes())
			quiet("far off")

			stand(battery.Ground + back * 6, battery.Ground)
			t.Check("beside the battery, only it is near", nearOnes() == "Battery", nearOnes())
			t.Check("and its plate shows, unless it would stand over the avatar", waitFor(t, 1, function(): boolean
				return plateOf("Battery").Visible or World.OnAvatar(plateOf("Battery"))
			end), if plateOf("Battery").Visible then "shown" else "hidden over the avatar")
			local line = plateOf("Battery"):FindFirstChild("Line1", true) :: TextLabel?
			t.Check("saying only its name: the Electricity pill has the count", line ~= nil and line.Text == "Battery", if line then line.Text else "no line")
			quiet("beside the battery")
			local spawnAt = BaseController.Near + 1 -- the spawn's distance from the battery, about
			stand(battery.Ground + back * spawnAt, battery.Ground)
			t.Check(`stepping back to {spawnAt} studs, it holds on`, BaseController.Says().Battery.Near)
			stand(battery.Ground + back * (BaseController.Near + BaseController.NearSlack + 3), battery.Ground)
			t.Check("past its slack it lets go, and the plate hides", not BaseController.Says().Battery.Near and not plateOf("Battery").Visible)
			stand(battery.Ground + back * spawnAt, battery.Ground)
			t.Check(`coming in to {spawnAt} studs, it stays quiet: it takes hold only within {BaseController.Near}`, not BaseController.Says().Battery.Near and not plateOf("Battery").Visible)

			stand(breaker.Ground + back * 8, breaker.Ground)
			t.Check("beside the Breaker, it's near", BaseController.Says().Breaker.Near)
			t.Check("and its plate shows, unless it would stand over the avatar", waitFor(t, 1, function(): boolean
				return plateOf("Breaker").Visible or World.OnAvatar(plateOf("Breaker"))
			end), if plateOf("Breaker").Visible then "shown" else "hidden over the avatar")
			quiet("beside the Breaker")
			-- One fact once: what's ready is the next step's line while it points at the Breaker, so the plate leaves it out.
			local ready = #(ProfileController.Get() :: any).Base.Ready
			local step = HudController.Step()
			if ready > 0 and step and step.Target == "Breaker" then
				local first = plateOf("Breaker"):FindFirstChild("Line1", true) :: TextLabel?
				t.Check(`{ready} ready, said by the next step: the Breaker's plate leaves the count out`, first ~= nil and string.find(first.Text, "Ready", 1, true) == nil, if first then first.Text else "no line")
			end

			-- From afar, news lights a plate and leaves it quiet: the next step says it.
			stand(battery.Ground + back * 24, breaker.Ground)
			local shard = "named_watt"
			local had = news().Breaker
			t.Check("a shard goes in the bag", t.Server("BaseGive", shard, 1).Ok == true)
			t.Check("far off, the Breaker's plate lights and stays quiet", waitFor(t, ANSWER, function(): boolean
				return BaseController.Says().Breaker.News and lit("Breaker") and not plateOf("Breaker").Visible
			end))
			quiet("with a shard in the bag")
			t.Check("the shard comes back out", t.Server("BaseGive", shard, -1).Ok == true)
			t.Check("and the Breaker's news is the save's again", waitFor(t, ANSWER, function(): boolean
				return BaseController.Says().Breaker.News == had and (had or not plateOf("Breaker").Visible)
			end))
			local worker = view.Base.Bays[1] and view.Base.Bays[1].Worker or ""
			if worker ~= "" and says.Bay1 then
				t.Check("bay 1's worker steps out", ProfileController.Act("SetWorker", { Bay = 1, Voidkin = "" }).Ok == true)
				t.Check("far off, bay 1 lights and stays quiet: a free Voidkin could work it", waitFor(t, ANSWER, function(): boolean
					return BaseController.Says().Bay1.News and lit("Bay1") and not plateOf("Bay1").Visible
				end))
				t.Check("the worker goes back", ProfileController.Act("SetWorker", { Bay = 1, Voidkin = worker }).Ok == true)
				t.Check("and bay 1 is quiet again", waitFor(t, ANSWER, function(): boolean
					return not BaseController.Says().Bay1.News and not lit("Bay1") and not plateOf("Bay1").Visible
				end))
			end
			quiet("at the end")
		end,
	},
	{
		Name = "Base: the Breaker's chambers glow and hold their shard while they break, low and empty after; the mill's wheel turns by its generation (AR15, AR19)",
		Place = "Main", -- TR45: its world stands in that place only
		Run = function(t: any)
			local view = ProfileController.Get()
			local plot = Players.LocalPlayer:GetAttribute("Plot")
			local breaker = if type(plot) == "number" then Markers.Find("Breaker", { Plot = plot }) else nil
			local plant = if type(plot) == "number" then Markers.Find("Generator", { Plot = plot }) else nil
			local first = if breaker then breaker:FindFirstChild("Chamber 1") else nil
			if view == nil or view.Progress.Starter == "" or breaker == nil or first == nil or first:GetAttribute("Working") == nil then
				t.Check("the first shard is chosen and the Breaker stands as its model", false, "a grey box, or no starter yet")
				return
			end
			-- Each chamber as the save has it: its state, its shard, its glow.
			local function wrong(): string?
				local now = ProfileController.Get()
				for index = 1, #(now :: any).Base.Chambers do
					local chamber = breaker:FindFirstChild(`Chamber {index}`)
					local shard = breaker:FindFirstChild(`Shard {index}`)
					local held = (now :: any).Base.Chambers[index]
					local working = held ~= nil and held.Work ~= nil
					local look = if chamber then chamber:FindFirstChildOfClass("SurfaceAppearance") else nil
					local glow = LightingConfig.Glow.Kit * (if working then 1 else LightingConfig.Glow.Empty) * LightingController.Look().Glow -- the phase's share (TR23)
					if chamber == nil or chamber:GetAttribute("Working") ~= working then
						return `chamber {index}: Working {tostring(chamber and chamber:GetAttribute("Working"))}, the save {tostring(working)}`
					elseif shard == nil or not shard:IsA("BasePart") or shard.Transparency ~= (if working then 0 else 1) then
						return `chamber {index}: its shard {if shard and shard:IsA("BasePart") then shard.Transparency else "missing"}`
					elseif look == nil or math.abs(look.EmissiveStrength - glow) > 1e-3 then
						return `chamber {index}: glow {if look then string.format("%.2f", look.EmissiveStrength) else "none"}, not {string.format("%.2f", glow)}`
					end
				end
				return nil
			end
			t.Server("BaseSkip", SKIP_ALL)
			t.Check("all broken: every chamber low, no shard", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now :: any).Base.Chambers[1].Work == nil and wrong() == nil
			end), wrong())
			local shard = "named_watt"
			t.Server("BaseGive", shard, 1)
			local added = t.Server("Act", "AddShard", { Shard = shard })
			local wentIn = type(added) == "table" and added.Ok == true
			t.Check("the shard goes in", wentIn, if wentIn then nil else tostring(type(added) == "table" and added.Reason))
			t.Check("one in: its chamber full with its shard between the points", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now :: any).Base.Chambers[1].Work ~= nil and wrong() == nil
			end), wrong())
			t.Server("BaseSkip", SKIP_ALL)
			t.Check("broken: low again, the shard gone", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now :: any).Base.Chambers[1].Work == nil and wrong() == nil
			end), wrong())
			-- The mill's wheel (AR19): its owner's generation, and turning about its axle while there is some.
			local wheel = if plant then (BaseController.StageOf(plant) or plant):FindFirstChild("Wheel") else nil
			local kw = if wheel then wheel:GetAttribute("Generation") else nil
			t.Check("the generator's wheel carries the plant's generation", type(kw) == "number" and math.abs(kw - Power.Generation(ProfileController.Get() :: any)) < 1e-6, tostring(kw))
			if wheel and wheel:IsA("BasePart") and type(kw) == "number" then
				local before = wheel.CFrame
				t.Wait(0.5)
				local turned = before.Position:FuzzyEq(wheel.CFrame.Position, 1e-3) and not before:FuzzyEq(wheel.CFrame, 1e-4)
				t.Check(if kw > 0 then "it turns about its axle" else "it stands still at none", if kw > 0 then turned else before:FuzzyEq(wheel.CFrame, 1e-4))
			end
		end,
	},
	{
		Name = "Base: a shard added through the screen breaks, and opening it shows a card that names it",
		Place = "Main", -- TR45: its world stands in that place only
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
		Name = "Reveal: a break at each rarity plays through to its card, every cue sounding",
		Run = function(t: any)
			-- TR4's check, each rarity on Rook's body: the card comes on reveal.json's Card, and every cue Rules.Reveal.Cues
			-- schedules starts a Sound. The Mythical's frame rate too (TR4: run on the desktop and on the phone simulator).
			local rook = Voidkin.ById.rook
			local clip = if rook.Model and RevealConfig.Strikes[`{rook.Model}Reveal`] then `{rook.Model}Reveal` else RevealConfig.Fallback
			local strike = RevealConfig.Sounds.Strike.Cues[clip]
			local function length(cue: string): number
				return Sounds.Length(cue) or 0
			end
			for index, rarity in Rarity.Order do
				local r = RevealArt.Rarities[rarity]
				local expected = #RevealRule.Cues(r, rarity, index, strike, length)
				local began = os.clock()
				showReveal(rarity)
				local group = SoundService:FindFirstChild("NL_RevealSounds")
				local heard = 0
				local counting = if group
					then group.ChildAdded:Connect(function(child: Instance)
						heard += if child:IsA("Sound") then 1 else 0
					end)
					else nil
				local frames, worst = 0, 0
				local carded: number? = nil
				while os.clock() - began < r.Times.Card + CARD_SLACK * 2 do
					local step = RunService.RenderStepped:Wait()
					frames += 1
					worst = math.max(worst, step)
					local shown = BaseController.Revealed()
					if shown and shown.Card then
						carded = os.clock() - began
						break
					end
				end
				if counting then
					counting:Disconnect()
				end
				t.Check(`{rarity}: the card comes`, carded ~= nil)
				if carded then
					t.Near(`{rarity}: on reveal.json's Card, {r.Times.Card} s`, carded, r.Times.Card + CARD_SLACK / 2, CARD_SLACK / 2)
				end
				t.Check(`{rarity}: every cue starts a Sound`, heard == expected, `{heard} of {expected}`)
				if rarity == Rarity.Order[#Rarity.Order] and carded then
					local fps = frames / carded
					t.Check(`{rarity}: holds {FPS_FLOOR} fps or more`, fps >= FPS_FLOOR, string.format("%.0f fps, the worst frame %.0f ms", fps, worst * 1000))
				end
				BaseController.Dismiss()
			end
			t.Check("it closes", BaseController.Revealed() == nil)
		end,
	},
	{
		Name = "Reveal: a tap before the skip opens does nothing; one after lands on the held frame with only the stamp; one past the card's hold closes it",
		Run = function(t: any)
			local rarity = Rarity.Order[#Rarity.Order - 1]
			local r = RevealArt.Rarities[rarity]
			showReveal(rarity)
			t.Check("the reveal runs", revealAt(RevealConfig.Skip / 2, RevealConfig.Skip))
			BaseController.Tap()
			RunService.RenderStepped:Wait()
			local shown = BaseController.Revealed()
			t.Check("a tap before the skip opens does nothing", shown ~= nil and not shown.Card and shown.Time < RevealConfig.Skip, if shown then string.format("%.2f s", shown.Time) else "gone")
			t.Check("the skip opens", revealAt(RevealConfig.Skip + 0.1, RevealConfig.Skip))
			BaseController.Tap()
			RunService.RenderStepped:Wait()
			shown = BaseController.Revealed()
			t.Check("a tap after it lands on the held frame", shown ~= nil and math.abs(shown.Time - r.Times.Card) < 1e-3, if shown then string.format("%.2f s", shown.Time) else "gone")
			t.Check("the card comes with it", waitFor(t, CARD_SLACK * 2, function(): boolean
				local now = BaseController.Revealed()
				return now ~= nil and now.Card
			end))
			local group = SoundService:FindFirstChild("NL_RevealSounds")
			local left: { string } = {}
			for _, sound in if group then group:GetChildren() else {} do
				if sound:IsA("Sound") then
					table.insert(left, sound.Name)
				end
			end
			t.Check("every cue stops but the name's stamp", #left == 1 and left[1] == RevealConfig.Sounds.Name.Cue, table.concat(left, ", "))
			BaseController.Tap()
			t.Check("a tap inside the card's hold keeps it", BaseController.Revealed() ~= nil)
			t.Wait(RevealConfig.CardHold + 0.05)
			BaseController.Tap()
			t.Check("a tap past it closes it", BaseController.Revealed() == nil)
		end,
	},
	{
		Name = "Reveal: a refused break shows no ceremony",
		Run = function(t: any)
			local view = ProfileController.Get()
			local ready = if view then #view.Base.Ready else 0
			BaseController.OpenShard(ready + 1) -- past the end: the server refuses it (nothing ready, or no such shard)
			t.Wait(0.1)
			t.Check("no reveal", BaseController.Revealed() == nil)
			t.Check("nothing on the overlay", Layers.Get("Overlay"):FindFirstChild("Reveal") == nil)
			local now = ProfileController.Get()
			local after = if now then #now.Base.Ready else 0
			t.Check("nothing spent", after == ready, `{after} ready, {ready} before`)
		end,
	},
	{
		Name = "Reveal: on the held frame, the frame, the window, the name and its rule sit inside this screen's safe area",
		Run = function(t: any)
			-- TR4's check, run on the desktop and on the phone simulator's smallest phone: the reveal fills the whole screen,
			-- and what must read keeps inside the safe area (the frame's right wing stands nearest the edge).
			local probe = Instance.new("ScreenGui")
			probe.Name = "NL_SelfTestSafe"
			probe.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
			local safe = Instance.new("Frame")
			safe.Size = UDim2.fromScale(1, 1)
			safe.BackgroundTransparency = 1
			safe.Parent = probe
			probe.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
			for _, rarity in Rarity.Order do
				showReveal(rarity)
				BaseController.Seek(RevealArt.Rarities[rarity].Times.Card)
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				local holder = Layers.Get("Overlay"):FindFirstChild("Reveal")
				local stage = holder and holder:FindFirstChild("Stage", true)
				t.Check(`{rarity}: the stage shows`, stage ~= nil)
				local low, high = safe.AbsolutePosition, safe.AbsolutePosition + safe.AbsoluteSize
				for _, name in { "Frame", "Window", "Name", "Rule" } do
					local piece = stage and stage:FindFirstChild(name)
					if piece and piece:IsA("GuiObject") and piece.Visible then
						local a, b = piece.AbsolutePosition, piece.AbsolutePosition + piece.AbsoluteSize
						local inside = a.X >= low.X - 0.5 and a.Y >= low.Y - 0.5 and b.X <= high.X + 0.5 and b.Y <= high.Y + 0.5
						t.Check(`{rarity}: the {name} inside the safe area`, inside, string.format("%.0f,%.0f to %.0f,%.0f in %.0f,%.0f to %.0f,%.0f", a.X, a.Y, b.X, b.Y, low.X, low.Y, high.X, high.Y))
					else
						t.Check(`{rarity}: the {name} shows`, false)
					end
				end
				BaseController.Dismiss()
			end
			probe:Destroy()
		end,
	},
	{
		Name = "Reveal: the plate after it hangs under the name's rule, the frame undimmed, each line one colour, for each outcome",
		Run = function(t: any)
			-- AR12, research's verdict on the reveal's card in Eclipse, and the plate's images: the plate under the name's
			-- line, from its rule's left end, over the held frame left undimmed; the pip tinted its rarity's word colour; the
			-- outcome's mark and words in one colour; "Tap to continue" once the card has stood Config.Reveal.CardHold, clear
			-- of the outcome's words or under the plate; every label legible, whole and on screen (the UI lint).
			local plate = RevealConfig.Plate
			local looks = {
				{ Def = "rook", Rarity = "Common", Outcome = "New", Lead = false, Kind = "A new Voidkin", Mark = "ShardSilver", Words = "In your collection", Colour = plate.Kept },
				{ Def = "rook", Rarity = "Rare", Outcome = "New", Lead = true, Kind = "A new Voidkin", Mark = "ShardSilver", Words = "Your lead: it fights beside you", Colour = plate.Kept },
				{ Def = "rook", Rarity = "Mythical", Outcome = "Copy", Lead = false, Kind = "A copy", Mark = "Star", Words = "One more toward its next star", Colour = plate.Star },
				{ Def = "stellane", Rarity = "Legendary", Outcome = "Sold", Lead = false, Kind = "Already at its last star", Mark = "CoinMint", Words = "Sold for 120 Credits", Colour = UIKit.Systems.Credits.Colour },
			}
			for _, look in looks do
				local row = Voidkin.ById[look.Def]
				local where = `{look.Rarity}, {look.Outcome}{if look.Lead then ", the lead" else ""}`
				BaseController.Reveal({ Def = look.Def, Outcome = look.Outcome, Lead = look.Lead, Credits = 120 }, { Rarity = look.Rarity, Name = row.Name, Model = row.Model })
				BaseController.Seek(RevealArt.Rarities[look.Rarity].Times.Card)
				t.Check(`{where}: the plate comes`, waitFor(t, 1, function(): boolean
					local shown = BaseController.Revealed()
					return shown ~= nil and shown.Card
				end))
				local holder = Layers.Get("Overlay"):FindFirstChild("Reveal")
				local stage = holder and holder:FindFirstChild("Stage", true)
				local card = stage and stage:FindFirstChild("Card")
				local rule = stage and stage:FindFirstChild("Rule")
				local cover = holder and holder:FindFirstChild("RevealTap")
				if not (card and card:IsA("GuiObject") and rule and rule:IsA("GuiObject") and stage and stage:IsA("GuiObject")) then
					t.Check(`{where}: the plate on the stage, beside the name's rule`, false)
					BaseController.Dismiss()
					continue
				end
				t.Check(`{where}: the held frame stays undimmed`, cover ~= nil and cover:IsA("GuiObject") and cover.BackgroundTransparency == 1)
				local scale = stage.AbsoluteSize.X / RevealArt.Screen.X
				local foot = rule.AbsolutePosition.Y + rule.AbsoluteSize.Y
				t.Near(`{where}: from the rule's left end`, card.AbsolutePosition.X, rule.AbsolutePosition.X, 1)
				t.Near(`{where}: {plate.Gap} points under the rule`, card.AbsolutePosition.Y - foot, plate.Gap * scale, 1)
				local function says(name: string): TextLabel?
					local found = card:FindFirstChild(name)
					return if found and found:IsA("TextLabel") then found else nil
				end
				local kind, rarity, outcome, skip = says("Kind"), says("Rarity"), says("Outcome"), says("Skip")
				t.Equal(`{where}: what the break gave`, if kind then kind.Text else nil, look.Kind)
				t.Equal(`{where}: its rarity, type and class`, if rarity then rarity.ContentText else nil, `{look.Rarity} · {row.Type} · {row.Class}`)
				local pip = card:FindFirstChild("Pip")
				t.Check(`{where}: the pip in its rarity's word colour`, pip ~= nil and pip:IsA("ImageLabel") and pip.ImageColor3:ToHex() == plate.Words[look.Rarity]:ToHex())
				local mark = card:FindFirstChild("Mark")
				t.Check(`{where}: the outcome's mark, {look.Mark}`, mark ~= nil and mark:IsA("ImageLabel") and mark.Image == UIKit.Images[look.Mark].Id)
				t.Equal(`{where}: the outcome's words`, if outcome then outcome.Text else nil, look.Words)
				t.Check(`{where}: in the mark's colour`, outcome ~= nil and outcome.TextColor3:ToHex() == look.Colour:ToHex())
				t.Check(`{where}: no "Tap to continue" before the card has stood`, skip ~= nil and not skip.Visible)
				t.Wait(RevealConfig.CardHold + 0.1)
				t.Check(`{where}: then "Tap to continue"`, skip ~= nil and skip.Visible and skip.Text == "Tap to continue")
				if skip and outcome then
					local beside = math.abs((skip.AbsolutePosition.Y + skip.AbsoluteSize.Y / 2) - (outcome.AbsolutePosition.Y + outcome.AbsoluteSize.Y / 2)) < 1
					local gap = skip.AbsolutePosition.X + skip.AbsoluteSize.X - skip.TextBounds.X - (outcome.AbsolutePosition.X + outcome.TextBounds.X)
					local under = skip.AbsolutePosition.Y >= card.AbsolutePosition.Y + card.AbsoluteSize.Y - 0.5
					t.Check(`{where}: "Tap to continue" clear of the words, or under the plate`, (beside and gap >= plate.Tap.Room * scale - 1) or under, string.format("%s, %.0f px", if beside then "beside" else "under", gap))
				end
				lintClean(t, `the plate after the reveal, {where}`)
				BaseController.Dismiss()
			end
			t.Check("it closes", BaseController.Revealed() == nil)
		end,
	},
	{
		Name = "Reveal: each Voidkin's Reveal clip marks its strike where Config.Reveal.Strikes says",
		Stay = true,
		Run = function(t: any)
			for clip, strike in RevealConfig.Strikes do
				local sequence = Clips.Sequence(clip)
				t.Check(`{clip} is baked`, sequence ~= nil)
				local at: number? = nil
				for _, keyframe in if sequence then sequence:GetKeyframes() else {} do
					for _, marker in (keyframe :: Keyframe):GetMarkers() do
						if marker.Name == strike.Marker then
							at = (keyframe :: Keyframe).Time
						end
					end
				end
				t.Check(`{clip} marks {strike.Marker}`, at ~= nil)
				if at then
					t.Near(`{clip}: {strike.Marker} at {strike.Time} s`, at, strike.Time, BEAT_TOLERANCE)
				end
			end
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
			t.Wait(HudConfig.Motion.Screen.Enter + 0.1) -- laid out, and in
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
		Name = "Breaker: with nothing ready its prompt opens its own screen, Machine: the chambers, what waits and the chosen shard's odds, rarest first, and what opens a locked chamber",
		Run = function(t: any)
			-- TR9's screen in Machine, the director's pick (2026-11-14, night), at this screen's scale and the smallest
			-- phone's: the chambers as they stand, what's ready, waiting and in the bag, and one tap to a shard's odds.
			local view = ProfileController.Get()
			t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
			if view == nil or view.Progress.Starter == "" then
				return
			end
			local shard = "lanternrow_standard"
			local held = view.Bag.Shards[shard] or 0
			t.Server("BaseGive", shard, 2)
			t.Check("the server gives two", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 2
			end))
			t.Check("one goes into the Breaker, one stays in the bag", ProfileController.Act("AddShard", { Shard = shard }).Ok == true)
			t.Check("the save shows it", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
			end))
			Screen.Close()
			local ready = #(ProfileController.Get() :: Profile.View).Base.Ready
			BaseController.PressBreaker()
			if ready == 0 then
				t.Check("its prompt, with nothing ready, opens the Breaker's screen", Screen.Current() == BreakerScreen.Name, tostring(Screen.Current()))
			else
				t.Check(`its prompt, with {ready} ready, opens the oldest`, waitFor(t, ANSWER, function(): boolean
					return BaseController.Revealed() ~= nil
				end))
				BaseController.Dismiss()
				BaseController.OpenBreaker()
			end
			local before = readyCount(shard) -- the one put in is still breaking
			local first = BreakerScreen.Selected()
			t.Check("it opens on a chamber's shard", first ~= nil and first.Kind == "Chamber", if first then `{first.Kind} {first.Index}` else "none")
			-- The chosen shard's pane: its name, and its drop rates one tap away: every Voidkin under its rarity's total, the
			-- commonest first, in place of its voltage until a second tap.
			local function oddsShown(where: string)
				local item = BreakerScreen.Selected()
				local title = breakerText("Odds", "Title")
				t.Check(`{where}: the pane names the chosen shard`, item ~= nil and string.find(title, Read.ShardName(item.Def), 1, true) ~= nil, title)
				local fold = breakerPart("Rates")
				-- Its voltage, where the kind is ever offered it (Rules.Power.Offered; research, TR18): none on Lantern Row's
				-- 30-second shards.
				local offered = item ~= nil and Power.Offered(item.Def)
				local function voltageBack(): boolean
					return (breakerPart("Level1") ~= nil) == offered
				end
				t.Check(`{where}: Drop rates is one tap away, its voltage shown until then`, fold ~= nil and fold:IsA("TextButton") and Button.State(fold) == "Rest" and breakerPart("Chances") == nil and voltageBack(), if offered then "voltage offered" else "no voltage on this kind")
				local beside = fold and fold.Parent
				local base = fold and fold:FindFirstChild("Foot", true) -- the glass's foot of light (AR30)
				t.Check(`{where}: a secondary press: half its row at most, a list's mark, never the action's light`, fold ~= nil and fold:IsA("GuiObject") and beside ~= nil and beside:IsA("GuiObject")
					and fold.AbsoluteSize.X <= beside.AbsoluteSize.X / 2 + 0.5 and fold:FindFirstChild("Mark") ~= nil and base ~= nil and base:IsA("GuiObject") and not base.Visible)
				t.Check(`{where}: a tap opens them, in place of its voltage`, fold ~= nil and fold:IsA("TextButton") and Button.Press(fold) and waitFor(t, 1, function(): boolean
					local lit = breakerPart("Rates")
					return lit ~= nil and lit:IsA("TextButton") and Button.State(lit) == "Selected" and breakerPart("Chances") ~= nil and breakerPart("Level1") == nil
				end))
				local list = breakerPart("Chances")
				local work = chosenWork(item)
				local groups = if item then Odds.Rates(item.Def, if work then work.Luck else 0) else {}
				local off: { string } = {}
				local order = 0
				local function row(name: string, parts: number)
					order += 1
					local line = list and list:FindFirstChild(name)
					local chance = line and line:FindFirstChild("Chance") :: TextLabel?
					if line == nil or chance == nil or not line:IsA("GuiObject") then
						table.insert(off, `{name} missing`)
					elseif chance.Text ~= Odds.Percent(parts) or line.LayoutOrder ~= order then
						table.insert(off, `{name}: {chance.Text} at {line.LayoutOrder}`)
					end
				end
				for _, group in groups do
					row(`Tier{group.Rarity}`, group.Parts)
					for _, each in group.Rates do
						row(each.Id, each.Parts)
					end
				end
				local shown = if list then #list:GetChildren() - 1 else 0 -- its layout aside
				t.Check(`{where}: every Voidkin under its rarity's total, the commonest first, as the server rolls them`, #groups > 0 and #off == 0 and shown == order, off[1] or `{shown} rows for {order}`)
				lintClean(t, `{where}, its drop rates open`)
				local lit = breakerPart("Rates")
				t.Check(`{where}: a second tap closes them, its voltage back`, lit ~= nil and lit:IsA("TextButton") and Button.Press(lit) and waitFor(t, 1, function(): boolean
					return breakerPart("Chances") == nil and voltageBack()
				end))
			end
			-- The chambers as they stand, those open and the locked ones a ceiling reaches, and the bag's shard on the strip.
			local function machineShown(where: string)
				local now = ProfileController.Get() :: Profile.View
				local row = breakerPart("Chambers")
				local most = BaseLevels.ChambersShown(#now.Base.Chambers)
				local wrong: { string } = {}
				for index = 1, most do
					local cell = row and row:FindFirstChild(`Chamber{index}`)
					local label = cell and cell:FindFirstChild("Name") :: TextLabel?
					local left = cell and cell:FindFirstChild("Left") :: TextLabel?
					local chamber = now.Base.Chambers[index]
					local want = if chamber == nil then "Locked" elseif chamber.Work == nil then "Empty" else nil
					local opens = breakerPart("Opens") :: TextLabel? -- said once over the row (TR41)
					if cell == nil or label == nil then
						table.insert(wrong, `chamber {index} missing`)
					elseif want and label.Text ~= want then
						table.insert(wrong, `chamber {index} says {label.Text}, not {want}`)
					elseif chamber == nil and (opens == nil or opens.Text ~= BreakerScreen.Opens(#now.Base.Chambers)) then
						table.insert(wrong, `the row doesn't say what opens locked chamber {index}: {if opens then opens.Text else "nothing"}`)
					elseif want == nil and (cell:FindFirstChild("Crack") == nil or left == nil or string.find(left.Text, " left$") == nil) then
						table.insert(wrong, `chamber {index} lacks its crack or its time`)
					elseif want == nil then
						-- AR12, research's call: its grade's picture at the top, Least to Chamber points, its words under it.
						local picture = cell:FindFirstChild("Picture") :: ImageLabel?
						local work = (chamber :: Profile.Chamber).Work :: Profile.ShardWork
						local art = HudConfig.ShardArt
						local side = if picture then picture.Size.X.Offset else 0
						local grade = if ShardDefs.ById[work.Def] then ShardDefs.ById[work.Def].Grade else "Standard"
						if picture == nil or picture:GetAttribute("Kit") ~= Hud.ShardPicture(grade, side, art.Large) or side < art.Least - 1e-3 or side > art.Chamber + 1e-3 then
							table.insert(wrong, `chamber {index}'s picture: {if picture then tostring(picture:GetAttribute("Kit")) else "none"} at {side}`)
						elseif picture.AbsolutePosition.Y + picture.AbsoluteSize.Y > (label :: TextLabel).AbsolutePosition.Y + 0.5 then
							table.insert(wrong, `chamber {index}'s name crosses its picture`)
						end
					end
				end
				t.Check(`{where}: each chamber as it stands, up to {most}, the rest locked, saying what opens them`, #wrong == 0, wrong[1])
				local bag = bagItem(shard)
				local detail = if bag then breakerText(`Bag{bag.Index}`, "Detail") else ""
				t.Check(`{where}: the bag's shard on the strip, with its count`, string.find(detail, "^In the bag · ") ~= nil, detail)
				-- AR12: its grade's small picture at a chip's size.
				local picture = if bag then breakerPart(`Bag{bag.Index}`) else nil
				picture = if picture then picture:FindFirstChild("Picture") else nil
				local art = HudConfig.ShardArt
				local want = Hud.ShardPicture(if ShardDefs.ById[shard] then ShardDefs.ById[shard].Grade else "Standard", art.Chip, art.Large)
				t.Check(`{where}: the chip wears its grade's picture`, picture ~= nil and picture:GetAttribute("Kit") == want, if picture then tostring(picture:GetAttribute("Kit")) else "none")
			end
			t.Check("Machine: built", waitFor(t, 2, function(): boolean
				return breakerPart("Machine") ~= nil
			end))
			t.Wait(HudConfig.Motion.Screen.Enter + 0.1) -- laid out, and in
			machineShown("Machine")
			oddsShown("Machine")
			local bag = bagItem(shard)
			local chip = if bag then breakerPart(`Bag{bag.Index}`) else nil
			t.Check("a tap on the bag's chip chooses its shard", chip ~= nil and BreakerScreen.Tap(chip:FindFirstChild("Tap")) and waitFor(t, 1, function(): boolean
				local item = BreakerScreen.Selected()
				return item ~= nil and item.Kind == "Bag" and item.Def == shard
			end))
			oddsShown("Machine, the bag's shard")
			for _, at in { { Name = "this screen", Scale = nil }, { Name = "the smallest phone", Scale = Theme.Scale.Floor } } do
				Layers.Force(at.Scale)
				t.Wait(0.1) -- laid out again
				lintClean(t, `Machine, at {at.Name}'s scale`)
			end
			Layers.Force(nil)
			Screen.Close()
			-- Leaves the Breaker as it found it: the bag's shard taken back, the one put in broken and opened.
			t.Server("BaseGive", shard, -1)
			t.Server("BaseSkip", SKIP_ALL)
			waitFor(t, ANSWER, function(): boolean
				return readyCount(shard) > before
			end)
			openReadyDown(t, shard, before)
		end,
	},
	{
		Name = "Breaker: a shard finishing flashes its chamber gold \"Ready\" as it goes to the strip, where its chip glows gold and opens on one tap",
		Run = function(t: any)
			-- TR9's fixes (a) and (b), research's verdict as corrected on the builder's facts (2026-11-14, night): a chamber
			-- never holds a ready shard, so the payoff shows in the machine as the chamber hands it over, and the strip's
			-- ready chip is the loudest thing on the screen (Config.Hud.Breaker.Flash, .Glow).
			local view = ProfileController.Get()
			t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
			if view == nil or view.Progress.Starter == "" then
				return
			end
			local shard = "lanternrow_standard"
			local held = view.Bag.Shards[shard] or 0
			local before = readyCount(shard)
			t.Server("BaseGive", shard, 1)
			t.Check("the server gives one", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1
			end))
			t.Check("it goes into the Breaker", ProfileController.Act("AddShard", { Shard = shard }).Ok == true)
			t.Check("the save shows it", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and (now.Bag.Shards[shard] or 0) == held
			end))
			Screen.Close()
			BaseController.OpenBreaker()
			t.Check("the Breaker's screen is open", waitFor(t, 2, function(): boolean
				return Screen.Current() == BreakerScreen.Name and breakerPart("Machine") ~= nil
			end))
			-- The chamber nearest done, brought to a second short of it, so its end is watched on the open screen.
			local base = Read.Base(ProfileController.Get() :: Profile.View, workspace:GetServerTimeNow())
			local nearest, left = 0, math.huge
			for index, chamber in base.Data.Base.Chambers do
				local work = chamber.Work
				if work and Read.Left(base, work) < left then
					nearest, left = index, Read.Left(base, work)
				end
			end
			t.Check("a chamber is breaking", nearest > 0)
			if nearest == 0 then
				return
			end
			local readyBefore = #base.Data.Base.Ready
			local SHORT = 1
			if left > SHORT then
				t.Server("BaseSkip", left - SHORT)
			end
			local flash = HudConfig.Breaker.Flash
			t.Check(`chamber {nearest} flashes as its shard finishes`, waitFor(t, SHORT + ANSWER + 1, function(): boolean
				return BreakerScreen.Flashing()[nearest] == true
			end))
			local began = os.clock()
			local cell = breakerPart(`Chamber{nearest}`)
			local over = cell and cell:FindFirstChild("Flash")
			local word = over and over:FindFirstChild("Ready") :: TextLabel?
			local fill = over and over:FindFirstChild("Fill", true) :: ImageLabel?
			t.Check("gold, \"Ready\" across the box", word ~= nil and word.Text == "Ready" and fill ~= nil and fill.ImageColor3 == Theme.Ink(BreakerScreen.Palette).Ready,
				if word then word.Text else "no flash over the chamber")
			local under = cell and cell:FindFirstChild("Name")
			t.Check("what the chamber holds next waits under the gold, its words not shown", under ~= nil and under:IsA("TextLabel") and not under.Visible)
			t.Check("the shard reaches the strip", waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				return now ~= nil and #now.Base.Ready > readyBefore
			end))
			local index = #(ProfileController.Get() :: Profile.View).Base.Ready
			local chip: Instance? = nil
			t.Check("its chip is on the strip", waitFor(t, 1, function(): boolean
				chip = breakerPart(`Ready{index}`)
				return chip ~= nil
			end))
			local glow = chip and chip:FindFirstChild("Glow", true) :: ImageLabel?
			t.Check("the chip glows gold, \"Ready\" its first word", chip ~= nil and glow ~= nil and glow.ImageColor3 == Theme.Ink(BreakerScreen.Palette).Ready
				and chip:GetAttribute("Trim") == Theme.Ink(BreakerScreen.Palette).Ready and breakerText(`Ready{index}`, "Name") == "Ready", breakerText(`Ready{index}`, "Name"))
			lintClean(t, "the Breaker with a chamber flashing")
			t.Check("the flash ends in about its time", waitFor(t, flash.Seconds + 0.5, function(): boolean
				return BreakerScreen.Flashing()[nearest] == nil
			end))
			t.Row("the flash, from its first look to its end (looks 0.25 s apart at most)", nil, nil, os.clock() - began, "s")
			t.Wait(0.1)
			local shown = breakerPart(`Chamber{nearest}`)
			local after = shown and shown:FindFirstChild("Flash")
			local faded = after and after:FindFirstChild("Fill", true) :: ImageLabel?
			t.Check("and its gold is gone", after == nil or (faded ~= nil and faded.ImageTransparency > 0.95))
			local words = shown and shown:FindFirstChild("Name")
			t.Check("then the chamber's words show", words ~= nil and words:IsA("TextLabel") and words.Visible)
			chip = breakerPart(`Ready{index}`)
			t.Check("one tap on the chip opens it", chip ~= nil and BreakerScreen.Tap((chip :: Instance):FindFirstChild("Tap")) and waitFor(t, ANSWER, function(): boolean
				return BaseController.Revealed() ~= nil
			end))
			BaseController.Dismiss()
			-- Leaves the Breaker as it found it: the one put in broken and opened.
			Screen.Close()
			t.Server("BaseSkip", SKIP_ALL)
			waitFor(t, ANSWER, function(): boolean
				local now = ProfileController.Get()
				if now == nil then
					return false
				end
				for _, chamber in now.Base.Chambers do
					if chamber.Work then
						return false
					end
				end
				return #now.Base.Line == 0
			end)
			openReadyDown(t, shard, before)
		end,
	},
	{
		Name = "Breaker: voltage shows its price in kWh and the time it saves, says why when it can't, and spends once",
		Run = function(t: any)
			-- TR18 (docs/design.md, "Power"; Rules.Power.Voltage, Rules.Base.Infuse): Low or High voltage, each with its price
			-- in kWh, and the time it saves beside it. Why a whole shard takes none stands over the levels; a level's own
			-- reason beside its button (BreakerScreen.Reasons). Voltage is never offered on Lantern Row's 30-second shards, so
			-- none shows there (research, TR18); the case then tunes the Standard and the Named an Enriched's 900 seconds, and
			-- puts them back however the case ends.
			local reasons = BreakerScreen.Reasons
			local view = ProfileController.Get()
			t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
			if view == nil or view.Progress.Starter == "" then
				return
			end
			local shard = "lanternrow_standard"
			local seconds = BREAK_PATH
			local plain = Tune.Read(seconds) :: number
			local plainNamed = Tune.Read(NAMED_PATH) :: number
			local charge = view.Base.Charge
			local held = view.Bag.Shards[shard] or 0
			local heldWatt = view.Bag.Shards.named_watt or 0
			local before = readyCount(shard)
			local capacity = Breaker.Capacity(view.Base)
			local function tuned(value: number, named: number): boolean
				t.Server("Tune", seconds, value)
				t.Server("Tune", NAMED_PATH, named)
				return waitFor(t, ANSWER, function(): boolean
					return Tune.Read(seconds) == value and Tune.Read(NAMED_PATH) == named
				end)
			end
			local ok, err = pcall(function()
				t.Server("BaseGive", shard, 1)
				t.Server("BaseGive", "named_watt", 1)
				t.Check("the server gives a shard and Watt's", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and (now.Bag.Shards[shard] or 0) == held + 1 and (now.Bag.Shards.named_watt or 0) == heldWatt + 1
				end))
				Screen.Close()
				BaseController.OpenBreaker()
				-- Lantern Row's 30 seconds: voltage is never offered on its shards, so none shows.
				for _, def in { shard, "named_watt" } do
					BreakerScreen.Select(bagItem(def))
					local button = infuseButton(1)
					t.Check(`{def} at Lantern Row's 30 seconds: no voltage shown`, button == nil and breakerText("Odds", "Why") == "", breakerText("Odds", "Why"))
				end
				-- An Enriched's 900 seconds from here: voltage is offered, and each reason stands.
				t.Check("tuned to 900 seconds", tuned(900, 900))
				-- Watt's shard holds him alone: no voltage.
				BreakerScreen.Select(bagItem("named_watt"))
				local _, locked = infuseButton(1)
				t.Check("a Named shard takes no voltage", locked)
				t.Check("and says why over the levels", breakerText("Odds", "Why") == reasons.Holds, breakerText("Odds", "Why"))
				-- A shard in the bag: in first, and the screen keeps it chosen where it lands.
				BreakerScreen.Select(bagItem(shard))
				_, locked = infuseButton(1)
				t.Check("a shard in the bag: put it in first", locked and breakerText("Odds", "Why") == reasons.Bag, breakerText("Odds", "Why"))
				local action = breakerPart("Action")
				local label = action and action:FindFirstChild("Label") :: TextLabel?
				t.Check("its one thing to do: Put it in", label ~= nil and label.Text == "Put it in", if label then label.Text else "none")
				t.Check("which takes a press", action ~= nil and action:IsA("TextButton") and Button.Press(action))
				t.Check("it goes in, still chosen where it stands", waitFor(t, ANSWER, function(): boolean
					local item = BreakerScreen.Selected()
					local work = chosenWork(item)
					return item ~= nil and (item.Kind == "Chamber" or item.Kind == "Line") and work ~= nil and work.Def == shard and work.Volt == nil
				end))
				local chosen = BreakerScreen.Selected() :: BreakerScreen.Selection
				t.Check("in, nothing stands over the levels", breakerText("Odds", "Why") == "", breakerText("Odds", "Why"))
				-- The battery empty: each level says beside it what it needs, its price on it.
				t.Server("BaseBattery", 0)
				t.Check("the battery emptied", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and now.Base.Charge < 1
				end))
				BreakerScreen.Select(chosen) -- rebuilt with the tuned time
				t.Wait(0.1)
				local function priceOn(index: number): number?
					local said = breakerText(`Infuse{index}`, "Label")
					return tonumber(said:match("\n(%d+) kWh$") or "")
				end
				for index in ShardConfig.Voltage.Levels do
					local _, off = infuseButton(index)
					local work = chosenWork(chosen) :: Profile.ShardWork
					local price = Power.Voltage(work, index)
					local shown = priceOn(index)
					t.Check(`level {index}: its price in kWh on it, the server's rule`, price ~= nil and shown ~= nil and math.abs(shown - price) <= 1, `{shown} against {price}`)
					local beside = breakerText("Odds", `Effect{index}`)
					t.Check(`level {index}, the battery empty: locked, its need beside it`, off and shown ~= nil and beside == string.format(reasons.Short, Read.Number(shown)), beside)
				end
				lintClean(t, "the Breaker with voltage locked")
				-- A full battery: Low says the time it saves, High that it breaks it now; Low takes a press, spent once.
				t.Server("BaseBattery", capacity)
				t.Check("Low voltage can be pressed with the battery full", waitFor(t, ANSWER, function(): boolean
					local _, off = infuseButton(1)
					return not off
				end))
				local saves = breakerText("Odds", "Effect1")
				t.Check("Low: the time it saves beside it", string.find(saves, "^Saves %d") ~= nil, saves)
				t.Check("High: it breaks it now", breakerText("Odds", "Effect2") == "Breaks it now", breakerText("Odds", "Effect2"))
				lintClean(t, "the Breaker with voltage open")
				local button = infuseButton(1)
				t.Check("named Low voltage and High voltage, each over its price", button ~= nil and string.find(breakerText("Infuse1", "Label"), "^Low voltage\n%d+ kWh$") ~= nil and string.find(breakerText("Infuse2", "Label"), "^High voltage\n%d+ kWh$") ~= nil, breakerText("Infuse1", "Label"))
				local price = priceOn(1) or 0
				local left = Breaker.Left(chosenWork(chosen) :: Profile.ShardWork)
				t.Check("Low voltage is pressed", button ~= nil and Button.Press(button))
				local generation = Read.Base(ProfileController.Get() :: Profile.View, workspace:GetServerTimeNow()).Rates.Generation
				local slack = generation / 3600 * (ANSWER + 1) + 1e-3
				t.Check("the server takes its price and halves the time left", waitFor(t, ANSWER, function(): boolean
					local work = chosenWork(chosen)
					local now = ProfileController.Get()
					return work ~= nil and work.Volt == 1 and Breaker.Left(work) <= left / 2 + 1 and now ~= nil and now.Base.Charge <= capacity - price + slack
				end))
				local infused = string.format(reasons.Infused, "Infused · Low voltage")
				t.Check("the screen says it's infused, once a shard", waitFor(t, 1, function(): boolean
					local _, off = infuseButton(1)
					return off and breakerText("Odds", "Why") == infused and string.find(breakerText("Odds", "Place"), "infused, low voltage", 1, true) ~= nil
				end), `{breakerText("Odds", "Why")}; {breakerText("Odds", "Place")}`)
				local again, off = infuseButton(#ShardConfig.Voltage.Levels)
				t.Check("and takes no second voltage", off and again ~= nil and not Button.Press(again))
				local unlifted = Odds.Rates(shard, 0)
				local top = unlifted[#unlifted]
				local fold = breakerPart("Rates")
				t.Check("its drop rates open", fold ~= nil and fold:IsA("TextButton") and Button.Press(fold) and waitFor(t, 1, function(): boolean
					return breakerPart("Chances") ~= nil
				end))
				local total = if top then breakerText(`Tier{top.Rarity}`, "Chance") else ""
				t.Check("and its odds never change", top ~= nil and total == Odds.Percent(top.Parts), total)
				fold = breakerPart("Rates")
				t.Check("then close", fold ~= nil and fold:IsA("TextButton") and Button.Press(fold) and waitFor(t, 1, function(): boolean
					return breakerPart("Chances") == nil
				end))
				if chosen.Kind == "Chamber" then
					-- One line in the chamber; the level is the pane's, checked above (AR12, the chamber's picture over its words).
					t.Check("its chamber says so", breakerText(`Chamber{chosen.Index}`, "Infused") == "Infused", breakerText(`Chamber{chosen.Index}`, "Infused"))
				end
				lintClean(t, "the Breaker with an infused shard chosen")
				-- Broken: nothing more goes in, and the one thing to do is open it.
				t.Server("BaseSkip", SKIP_ALL)
				t.Check("it breaks", waitFor(t, ANSWER, function(): boolean
					return readyCount(shard) > before
				end))
				local now = ProfileController.Get() :: Profile.View
				local at = 0
				for index, work in now.Base.Ready do
					if work.Def == shard and work.Volt == 1 then
						at = index
					end
				end
				BreakerScreen.Select({ Kind = "Ready", Index = at, Def = shard })
				t.Check("a shard broken: already broken", at > 0 and breakerText("Odds", "Why") == reasons.Ready, breakerText("Odds", "Why"))
				action = breakerPart("Action")
				label = action and action:FindFirstChild("Label") :: TextLabel?
				t.Check("its one thing to do: Open", label ~= nil and label.Text == "Open", if label then label.Text else "none")
				t.Check("which opens it", action ~= nil and action:IsA("TextButton") and Button.Press(action) and waitFor(t, ANSWER, function(): boolean
					return BaseController.Revealed() ~= nil
				end))
				BaseController.Dismiss()
			end)
			-- Leaves the base as it found it: the break time put back, Watt's shard taken back, the rest opened, the
			-- battery as it was.
			Screen.Close()
			t.Check("the break times put back", tuned(plain, plainNamed))
			t.Server("BaseGive", "named_watt", -1)
			openReadyDown(t, shard, before)
			t.Server("BaseBattery", charge)
			if not ok then
				error(err, 0)
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
			-- The Base screen opens from a bay's prompt (the dock's Base tile is the way home, TR19); the Voidkin screen from
			-- Home's Voidkin card (AR49), the dock's Home cell selected while it holds it.
			for _, name in { "Base", "Voidkin" } do
				local hud = HudController.Parts()
				if name == "Base" then
					BaseController.Open()
				end
				-- The Voidkin screen as a player opens it: Home's panel first, then its Voidkin card, which steps into it.
				local home = HudConfig.Home
				if name == "Voidkin" and not HomePanel.Shown(HudController.Home()) then
					Button.Press(hud.Home :: TextButton)
					t.Wait(home.Open.Grow + 0.1)
				end
				local opened = name == "Base" or Button.Press(hud[name] :: TextButton)
				t.Check(`{name} opens`, opened and waitFor(t, 1 + home.Step.Lit + home.Step.RiseAt, function(): boolean
					return Screen.Current() == name
				end))
				t.Check(`the world's layer hides while {name} is open`, waitFor(t, 0.5, function(): boolean
					return not layer.Visible
				end))
				if name == "Voidkin" then -- from Home's Voidkin card since AR49: the dock's Home cell holds its screen
					t.Check(`the dock's Home is selected while {name} is open from its panel`, waitFor(t, 0.5, function(): boolean
						return Button.State(hud.Home :: TextButton) == "Selected"
					end), Button.State(hud.Home :: TextButton))
				end
				Screen.Close()
				t.Check(`and shows again once {name} closes`, waitFor(t, 0.5, function(): boolean
					return layer.Visible
				end))
				if name == "Voidkin" then
					t.Check("and the dock's Home is back at rest", waitFor(t, 0.5, function(): boolean
						return Button.State(hud.Home :: TextButton) == "Rest"
					end), Button.State(hud.Home :: TextButton))
				end
			end
		end,
	},
	{
		Name = "Base: a worker set through the screen works its bay, and its plate says so",
		Place = "Main", -- TR45: its world stands in that place only
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
			t.Check("bay 1's plate names it, with its output in kW", text == `{Read.VoidkinName(pick)} · {Read.Kw(Power.Output(pick))}`, text)
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
		Name = "Capture: the plot's plates, no screen open",
		Place = "Main", -- TR45: its world stands in that place only
		Manual = true,
		Stay = true,
		Run = function(t: any)
			Screen.Close()
			BaseController.Dismiss()
			t.Check("no screen is open", Screen.Current() == nil)
		end,
	},
	{
		Name = "Capture: the level-up's light beside a Frost hit",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			-- Research on TR3's three calls (2026-11-13): the ring told from Frost's cyan, judged beside a Frost hit's
			-- number. On the player's own lead, at once, held for a capture. For a still, slow the column first:
			-- NL_Debug:Invoke("Tune", "Effects.LevelUp.Column.Seconds", 6), and put it back (0.7) after.
			local lead = myLead()
			local root = if lead then lead:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			t.Check("the player's lead stands", root ~= nil)
			if lead == nil or root == nil then
				return
			end
			Effects.LevelUp(root)
			Effects.Number(root, "Capture@Frost", 1234, { Style = "Element", Colour = UIKit.Elements.Frost }, Combat.Numbers)
			t.Wait(3)
		end,
	},
	{
		Name = "Capture: the interface in motion",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			-- AR8 C, each part beside its "before" (docs/asset-requests.md, AR8): a level gained, Credits won (a big win, then
			-- a small one), then a thumb on the dock opens a screen and its Close shuts it, twice. A tap is a thumb's: down,
			-- held, up, then the tap (Button.Touch, Button.Press). Start the recording, then the case; about 12 s.
			local parts = HudController.Parts()
			local function tap(button: TextButton?)
				if button == nil then
					return
				end
				Button.Touch(button, true)
				t.Wait(0.12)
				Button.Touch(button, false)
				Button.Press(button)
			end
			local function closeOf(name: string): TextButton?
				local frame = Screen.Frame(name)
				return if frame then frame:FindFirstChild("Close", true) :: TextButton? else nil
			end
			local view = ProfileController.Get()
			local owned = if view then view.Voidkin[view.Roles.Lead] else nil
			t.Check("the save names a lead", owned ~= nil)
			if owned == nil then
				return
			end
			local level = owned.Level
			t.Wait(1)
			t.Server("LeadLevel", level + 1)
			t.Wait(2)
			t.Server("DataCredits", 250)
			t.Wait(1)
			t.Server("DataCredits", 40)
			t.Wait(1.5)
			VoidkinScreen.Last("Bag") -- the card opens the page last shown (AR49)
			tap(parts.Voidkin :: TextButton)
			t.Wait(1.5)
			tap(closeOf("Voidkin"))
			t.Wait(1)
			BaseController.Open() -- as a bay's prompt opens it (TR19)
			t.Wait(1.5)
			tap(closeOf("Base"))
			t.Wait(1)
			t.Server("LeadLevel", level)
			t.Server("DataCredits", -290)
			t.Check("no screen is left open", Screen.Current() == nil)
		end,
	},
}

-- The takes, a list of their own (Takes), given the helpers they share with these cases.
local given: Takes.Given = {
	R6_ROOT_HEIGHT = R6_ROOT_HEIGHT,
	LEAD_SETTLE = LEAD_SETTLE,
	ARRIVE_TIMEOUT = ARRIVE_TIMEOUT,
	MOVE_SLACK = MOVE_SLACK,
	SET_DOWN = SET_DOWN,
	REPLICATE = REPLICATE,
	PACK_STAND = PACK_STAND,
	ANSWER = ANSWER,
	SKIP_ALL = SKIP_ALL,
	waitFor = waitFor,
	streamed = streamed,
	screenButton = screenButton,
	leadButton = leadButton,
	readyCount = readyCount,
	openReadyDown = openReadyDown,
	breakerPart = breakerPart,
	bagItem = bagItem,
	chosenWork = chosenWork,
	infuseButton = infuseButton,
	walkThrough = walkThrough,
	fighterModel = fighterModel,
	myLead = myLead,
	DOOR_RUN = DOOR_RUN,
}
for _, case in Takes(given) do
	table.insert(cases, case)
end
-- The places' and the trip between them, given theirs (TR45).
for _, case in TravelCases.Cases({
	REPLICATE = REPLICATE,
	SET_DOWN = SET_DOWN,
	R6_ROOT_HEIGHT = R6_ROOT_HEIGHT,
	streamed = streamed,
	walkThrough = walkThrough,
	lintClean = lintClean,
}) do
	table.insert(cases, case)
end
-- The HUD's and the kit's newer ones, given theirs (TR19, TR20).
for _, case in HudCases.Cases({
	REPLICATE = REPLICATE,
	LEAD_SETTLE = LEAD_SETTLE,
	ANSWER = ANSWER,
	ARRIVE_TIMEOUT = ARRIVE_TIMEOUT,
	PLATE_TICK = PLATE_TICK,
	SET_DOWN = SET_DOWN,
	R6_ROOT_HEIGHT = R6_ROOT_HEIGHT,
	waitFor = waitFor,
	streamed = streamed,
	lintClean = lintClean,
	myLead = myLead,
}) do
	table.insert(cases, case)
end
-- TR24's fixes 1 to 3, given theirs: the next step's marker, the lead's fights in view, its place beside the avatar, its fade.
for _, case in ViewCases.Cases({ LEAD_SETTLE = LEAD_SETTLE, SHADE_AHEAD = SHADE_AHEAD, waitFor = waitFor, myLead = myLead }) do
	table.insert(cases, case)
end
-- TR52's block, the signature on a tap, given theirs. Its module cast: typed, its require alone tipped this file past what
-- the type solver checks (32 internal errors, 2026-11-23); the module checks itself.
for _, case in (require(script.Parent.SignatureCases) :: any).Cases({
	LEAD_SETTLE = LEAD_SETTLE,
	SHADE_AHEAD = SHADE_AHEAD,
	SHADE_TOUGHER = SHADE_TOUGHER,
	SHADE_TIMEOUT = SHADE_TIMEOUT,
	waitFor = waitFor,
	myLead = myLead,
}) do
	table.insert(cases, case)
end
-- AR52's Guard and Dasher in a fight, given theirs, cast as SignatureCases is.
for _, case in (require(script.Parent.ShadeCases) :: any).Cases({
	LEAD_SETTLE = LEAD_SETTLE,
	SHADE_AHEAD = SHADE_AHEAD,
	SHADE_TOUGHER = SHADE_TOUGHER,
	SHADE_TIMEOUT = SHADE_TIMEOUT,
	waitFor = waitFor,
	myLead = myLead,
}) do
	table.insert(cases, case)
end
-- AR44's numbers in a fight, given theirs: clear of each other along their rise, and the clip for research.
for _, case in NumberCases.Cases({ myLead = myLead }) do
	table.insert(cases, case)
end
-- The dock's, given theirs (AR30's make).
for _, case in DockCases.Cases({ waitFor = waitFor }) do
	table.insert(cases, case)
end
-- The Power screen's, given theirs (TR18; AR12's battery plate).
for _, case in PowerCases.Cases({ ANSWER = ANSWER, PLATE_TICK = PLATE_TICK, waitFor = waitFor, lintClean = lintClean }) do
	table.insert(cases, case)
end
-- The base's on its plot, given theirs (AR16).
for _, case in BaseCases.Cases({ ANSWER = ANSWER, waitFor = waitFor }) do
	table.insert(cases, case)
end
-- The Voidkin screen's, given theirs (TR17).
for _, case in VoidkinCases.Cases({ ANSWER = ANSWER, REPLICATE = REPLICATE, waitFor = waitFor, lintClean = lintClean }) do
	table.insert(cases, case)
end
-- The Items page's, given theirs (TR28; AR18's A).
for _, case in BagCases.Cases({ ANSWER = ANSWER, waitFor = waitFor, lintClean = lintClean }) do
	table.insert(cases, case)
end
return cases
