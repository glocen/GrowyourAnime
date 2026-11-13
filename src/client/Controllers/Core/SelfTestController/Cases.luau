--!strict
-- Cases (client, Studio only): the self-test's list, a child of SelfTestController. Name is what a filter matches. Run gets
-- the `t` API (SelfTestController, type Test). Manual = true keeps a case out of a full run; Stay = true skips the reset to
-- the pad. Expected values come from Config or the instances themselves, never typed twice. One case, one behaviour.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local PathfindingService = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Tune = require(Shared.Util.Tune)
local TestInput = require(Shared.Util.TestInput)
local Actions = require(Shared.Definitions.Actions)
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Shades = require(Shared.Config.Shades)
local EffectsConfig = require(Shared.Config.Effects)
local ShadeBurstArt = require(Shared.Config.ShadeBurstArt)
local WorldConfig = require(Shared.Config.World)
local BaseConfig = require(Shared.Config.Base)
local Markers = require(Shared.World.Markers)
local Parts = require(Shared.Util.Parts)
local CameraTurn = require(Shared.Util.CameraTurn)
local Drops = require(Shared.Rules.Drops)
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
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local World = require(UI.World)
local Read = require(UI.Read)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)
local Toast = require(UI.Kit.Toast)
local Pop = require(UI.Kit.Pop)
local UiLint = require(script.Parent.UiLint)

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
local PACK_STAND = 10 -- studs short of a pack's marker the avatar stands: inside its notice and the lead's leash
local CARD_SLACK = 0.1 -- seconds past reveal.json's Card the reveal's card may come: its frame, and the spawn that builds it
local FPS_FLOOR = 50 -- frames a second the Mythical's reveal holds: the self-test's own warning line
local DROP_BACK = 3 -- seconds a felled pack takes to come back in the drops case: time to leave the street first
local ANSWER = 3 -- seconds a request through a screen may take to come back in the save's copy
local PLATE_TICK = 0.4 -- seconds for the plates and pills to show a change (BaseController and HudController read at 4 Hz)
local SKIP_ALL = 3600 -- seconds of base time a case skips, past any shard's work even at the floor's speed
local TAKE_READ = 3 -- seconds the take leaves a screen or a card up, as a player reads it
local TAKE_WALK = 45 -- seconds a walk of the take may last
local TAKE_FIGHT = 75 -- seconds a pack may take to fall in the take
local TAKE_TURN = 2.5 -- how fast the take's camera swings in behind a walking avatar (a share of the gap a second)
local TAKE_REACH = 2.5 -- studs from a waypoint that count as there
local DOOR_RUN = 4 -- studs before a Festival Door the avatar starts its walk in
local DOOR_THROUGH = 4 -- seconds from the walk's start to the fade's move: a step in, then the fade's middle
local DOOR_GONE = 40 -- studs from a door that count as set down on its other side
local TAKE_ZOOM = 12.5 -- studs from the avatar the take's camera holds: where Roblox's camera starts a player
local TAKE_KEEPER = 150 -- seconds the keeper's take watches its fight
local TAKE_KEEPER_LEVEL = 14 -- the lead's level in the keeper's take: it wins bare, where gear will carry it in play
local KEEPER_SHORT = 55 -- studs past Pack 6 the keeper's take starts: out of its notice and the lead's leash, 25 short of the gate
local KEEPER_ASK = 5 -- studs from the Challenge the avatar stops to hold it, inside Combat.Keeper.Reach
local KEEPER_SHOWS = 3 -- seconds after the walk by which the Challenge shows, the gate in view
local KEEPER_FRAME = { Low = 0.28, High = 0.4 } -- the keeper's height in the take, a share of the frame's: "about a third"
local HIDDEN = 1 / 3 -- of a fighter the camera can't see for a nearer one that still counts as clear of it
local CLEAR_SHARE = 0.7 -- the share of the fight's samples with a fighter clear: "most"
local REJOIN_SHARD = "lanternrow_standard" -- the shard the rejoin's takes leave breaking: Lantern Row's packs drop it

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

-- The UI lint on whatever shows now.
local function lintClean(t: any, where: string)
	local report = UiLint.Run()
	t.Check(`{where}: every label fits its box`, #report.Fit == 0, UiLint.Detail(report.Fit, report.Checked))
	t.Check(`{where}: every label reads at {Theme.Text.Minimum} px or more`, #report.Size == 0, UiLint.Detail(report.Size, report.Checked))
	t.Check(`{where}: every label is on screen`, #report.Screen == 0, UiLint.Detail(report.Screen, report.Checked))
	t.Check(`{where}: no label shows Roblox's default`, #report.Placeholder == 0, UiLint.Detail(report.Placeholder, report.Checked))
	t.Check(`{where}: every tap is {Theme.Size.Touch} px or more`, #report.Touch == 0, UiLint.Detail(report.Touch, report.Checked))
	t.Check(`{where}: every piece sits in the safe area`, #report.Safe == 0, UiLint.Detail(report.Safe, report.Checked))
	t.Check(`{where}: no two pieces of the HUD overlap`, #report.Overlap == 0, UiLint.Detail(report.Overlap, report.Checked))
	t.Check(`{where}: nothing sits under the thumbs' controls`, #report.Thumbs == 0, UiLint.Detail(report.Thumbs, report.Checked))
end

-- Walks the avatar into a Festival Door's way from the side it stands on (DOOR_RUN studs out when `close`, else wherever it
-- is), and waits for the fade to move it: true once it's been set down away from the door.
local function walkThrough(t: any, door: Instance, close: boolean): boolean
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
	local moved = waitFor(t, DOOR_THROUGH, function(): boolean
		local here = t.Root().Position
		return Vector3.new(here.X - floor.X, 0, here.Z - floor.Z).Magnitude > DOOR_GONE
	end)
	humanoid:MoveTo(t.Root().Position)
	return moved
end

-- Where `model` stands on screen: its box's corners in viewport pixels, low and high, and its distance from the camera; nil
-- when any of it is behind the camera.
local function screenBox(model: Model): (Vector2?, Vector2?, number?)
	local camera = workspace.CurrentCamera
	local at, size = model:GetBoundingBox()
	local low, high = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
	for _, x in { -0.5, 0.5 } do
		for _, y in { -0.5, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				local point = camera:WorldToViewportPoint((at * CFrame.new(size.X * x, size.Y * y, size.Z * z)).Position)
				if point.Z <= 0 then
					return nil, nil, nil
				end
				low = Vector2.new(math.min(low.X, point.X), math.min(low.Y, point.Y))
				high = Vector2.new(math.max(high.X, point.X), math.max(high.Y, point.Y))
			end
		end
	end
	return low, high, (camera.CFrame.Position - at.Position).Magnitude
end

-- How much of `back` the camera can't see for `front`: rays from the camera to five points on each of its parts (the
-- middle and four toward its corners), a share of them that `front` stops first. Silhouettes, not boxes: a leaning
-- keeper's box covers empty corners. Nil when `back` has no parts.
local function covered(front: Model, back: Model): number?
	local camera = workspace.CurrentCamera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { front }
	local hidden, rays = 0, 0
	for _, part in back:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= 1 then
			continue
		end
		for _, at in { Vector2.zero, Vector2.new(-0.35, -0.35), Vector2.new(0.35, -0.35), Vector2.new(-0.35, 0.35), Vector2.new(0.35, 0.35) } do
			local point = (part.CFrame * CFrame.new(part.Size.X * at.X, part.Size.Y * at.Y, 0)).Position
			rays += 1
			hidden += if workspace:Raycast(camera, point - camera, params) then 1 else 0
		end
	end
	return if rays > 0 then hidden / rays else nil
end

-- A take (TR2's evidence and its close): a stretch of play at real speed from the player's camera. `body` gets the take's
-- kit: Zero() flashes a white frame so a recording finds its zero; Moment(name) writes a row in seconds from it;
-- WalkTo(goal) walks the avatar there on a path, as a player steers. While it runs, the camera swings in behind a walking
-- avatar, and the zoom is held at Roblox's starting distance: a key or a wheel that reaches Studio while the hold keeps it
-- in front can't pull the camera out (the take of 2026-11-12 lost its last 30 s to one).
type Take = { Zero: () -> (), Moment: (name: string) -> (), WalkTo: (goal: Vector3) -> boolean }
local function take(t: any, body: (Take) -> ())
	local player = Players.LocalPlayer
	local zero = os.clock()
	local kit = {} :: Take
	function kit.Moment(name: string)
		t.Row(`moment: {name}`, nil, nil, math.floor((os.clock() - zero) * 100 + 0.5) / 100, "s")
	end
	function kit.Zero()
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
	end
	function kit.WalkTo(goal: Vector3): boolean
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
		-- By angle, the short way round, so a camera facing the avatar exactly turns too (a lerp of opposites never does).
		local from, to = math.atan2(flat.X, flat.Z), math.atan2(want.X, want.Z)
		local yaw = from + ((to - from + math.pi) % (2 * math.pi) - math.pi) * math.min(1, dt * TAKE_TURN)
		local across = math.sqrt(math.max(0, 1 - look.Y * look.Y))
		local direction = Vector3.new(math.sin(yaw) * across, look.Y, math.cos(yaw) * across)
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + direction)
	end)
	local zoomMin, zoomMax = player.CameraMinZoomDistance, player.CameraMaxZoomDistance
	player.CameraMinZoomDistance = TAKE_ZOOM
	player.CameraMaxZoomDistance = TAKE_ZOOM
	local ok, problem = pcall(body, kit)
	RunService:UnbindFromRenderStep("NL_TakeCamera")
	player.CameraMinZoomDistance = zoomMin
	player.CameraMaxZoomDistance = zoomMax
	if not ok then
		error(problem, 0)
	end
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

-- A Shade of `def` spawned SHADE_TOUGHER levels over the lead, watched for up to SHADE_WATCH seconds or three swings and
-- three flinches: the clip each swing and each flinch started, in order. Nil when it can't be watched; the Shade is cleared.
local function swingsOf(t: any, def: string): ({ string }?, { string }?)
	local lead = myLead()
	local level = if lead then lead:GetAttribute("Level") else nil
	if type(level) ~= "number" then
		t.Check("the lead is in the world", false)
		return nil, nil
	end
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
			t.Check("the warm pass ran and is over", Rows.Warmed())
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
			-- The camera's lift through the hold, when the lead it's aimed at is the player's own.
			local lead = Instance.new("Model")
			lead:SetAttribute("Owner", Players.LocalPlayer.UserId)
			local chest = Instance.new("Part")
			chest.Anchored, chest.CanCollide, chest.CanQuery, chest.Transparency = true, false, false, 1
			chest.CFrame = anchor * CFrame.new(0, 3, -7.5)
			chest.Parent = lead
			lead.Parent = workspace
			local lift = EffectsConfig.KeeperSignature.Lift
			local base = Effects.Lift()
			local running = Effects.KeeperSignature(action.Beats, body, function(): BasePart?
				return chest
			end, action)
			running.Step(action.Beats.Light + lift.Rise)
			t.Near("lifted through the hold", Effects.Lift() - base, lift.Degrees, 1e-6)
			running.Step(action.Beats.Slam + lift.Fall)
			t.Near("and down again after the Slam", Effects.Lift() - base, 0, 1e-6)
			local early = Effects.KeeperSignature(action.Beats, body, function(): BasePart?
				return chest
			end, action)
			early.Step(action.Beats.Light + lift.Rise)
			early.Destroy()
			t.Near("ended mid-hold: still lifted on that frame", Effects.Lift() - base, lift.Degrees, 1e-6)
			t.Wait(lift.Fall + 0.2)
			t.Near("then eased back down over Fall", Effects.Lift() - base, 0, 1e-6)
			running.Destroy()
			t.Near("and the paper as it was, both put back", look.EmissiveStrength, 1.2, 1e-6)
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
			-- held readable; out of view, all of it whole again, each part exactly as it was.
			do
				local see = HudConfig.SeeThrough
				local hud = HudController.Parts()
				local camera = workspace.CurrentCamera
				local housing = hud.Target:FindFirstChild("Housing") :: ImageLabel?
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
				if ours and ours.Parent and os.clock() - fellClock > LANDED then
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
		Name = "World: the Festival Door takes the player to Lantern Row's gate, and its twin takes them home",
		Stay = true, -- it moves the avatar itself; the next case's reset takes it back to the pad
		Run = function(t: any)
			local fade = Combat.Keeper.Fade
			local moved = fade.Out + fade.Hold / 2 + MOVE_SLACK
			local plot = Players.LocalPlayer:GetAttribute("Plot")
			local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
			local landing = Markers.Find("DoorLanding", { Ground = WorldConfig.Row.Ground })
			local home = Markers.Find("GroundDoor", { Ground = WorldConfig.Row.Ground })
			local spawn = if type(plot) == "number" then Markers.Find("Spawn", { Plot = plot }) else nil
			t.Check("the plot has its door, Lantern Row its twin and its landing", door ~= nil and landing ~= nil and home ~= nil and spawn ~= nil)
			if not (door and landing and home and spawn) then
				return
			end
			local function flat(a: Vector3, b: Vector3): number
				return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
			end
			-- From the spawn, as a player arrives.
			t.Root().CFrame = Markers.At(spawn) + Vector3.new(0, R6_ROOT_HEIGHT, 0)
			t.Wait(0.5)
			local fromSpawn = flat(Markers.At(door).Position, Markers.At(spawn).Position)
			t.Check("the door stands near the spawn, in view", fromSpawn < 60, `{math.floor(fromSpawn)} studs`)
			t.Check("the avatar walks into the plot's door", walkThrough(t, door, true))
			t.Wait(moved)
			local at = Markers.At(landing)
			t.Near("the plot's door sets the avatar down at Lantern Row's gate (studs off)", flat(t.Root().Position, at.Position), 0, SET_DOWN)
			t.Near("facing through it (degrees off)", flatAngle(t.Root().CFrame.LookVector, at.LookVector), 0, FACING_TOLERANCE)
			-- Out of the lead's leash of every pack: the arrival is a look up the street, never a fight already joined.
			local nearest = math.huge
			for _, pack in Markers.All("Pack") do
				nearest = math.min(nearest, flat(Markers.At(pack).Position, at.Position))
			end
			t.Check("no pack within the lead's leash of the landing", nearest > Combat.Lead.Leash, `{math.floor(nearest)} studs to the nearest`)
			local lead = myLead()
			local leadRoot = if lead then Parts.Root(lead) else nil
			t.Check("the lead comes through beside it", leadRoot ~= nil and flat(leadRoot.Position, t.Root().Position) <= Combat.Lead.Follow, if leadRoot then `{math.floor(flat(leadRoot.Position, t.Root().Position))} studs` else "no lead")
			t.Wait(1) -- past the door's gap, once a second at most a player
			t.Check("and into its twin", walkThrough(t, home, true))
			t.Wait(moved)
			t.Near("its twin sets the avatar down on its plot (studs off)", flat(t.Root().Position, Markers.At(spawn).Position), 0, SET_DOWN)
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
			-- Its own idle: its Voidkin's stance, else its rig's (Config.Animations.Idles, Rigs).
			local rig = Animations.Rigs[tostring(lead:GetAttribute("Rig"))] or Animations.Rigs.R6
			local want = Animations.Idles[tostring(lead:GetAttribute("Def"))] or rig.Idle
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
			-- AR1 (tools/studio/Models/Rook.luau): R6's seven parts hidden, his eight pieces riding them
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
			-- piston 0.65 studs toward the shoulder
			local slide = -1
			local haymaker = Clips.Sequence(Actions.ById.RookHaymaker.Clip or "")
			for _, keyframe in if haymaker then haymaker:GetKeyframes() else {} do
				for _, pose in (keyframe :: Keyframe):GetDescendants() do
					if pose:IsA("Pose") and pose.Name == "Rook_Piston" and (pose.Parent :: Instance).Name == "Right Arm" then
						slide = math.max(slide, pose.CFrame.Position.Magnitude)
					end
				end
			end
			t.Near("Haymaker slides the piston", slide, 0.65, 0.01)
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
	{
		Name = "Fight: the elite swings Attack every time",
		Run = function(t: any)
			-- AR2, section 10 (research picked (a)): in AttackLeft the elite's second mask cuts into its first, so the elite
			-- never plays it (Config.Animations.Unmirrored). Its other clips keep their mirrors.
			local swings = swingsOf(t, "brawler_elite")
			if swings == nil then
				return
			end
			local right = #swings >= 2
			for _, name in swings do
				right = right and name == "ShadeAttack"
			end
			t.Check("every swing is Attack", right, table.concat(swings, ", "))
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
				return playing(keeper)[Animations.Idles.lamplighter] == true
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
			local running = Effects.Haymaker(action.Beats, lead, function(): BasePart?
				return mark
			end)
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
			local before = square(-s.Rise - 1)
			t.Check("nothing before it forms", before.Count == 0, `{before.Count} bars`)
			local forms = square(-s.Rise + 0.5)
			t.Check("it forms loose over the target's head", forms.Count == 4 and math.abs(forms.Wide - s.Side * s.Forms) < 0.1 * s.Side and math.abs(forms.Foot - s.Over) < 0.3, string.format("%d bars, %.2f wide, foot at %.2f", forms.Count, forms.Wide, forms.Foot))
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
			t.Near("at the top of its drop", hung.Foot, s.Top, 0.01)
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
			t.Near("its outline grows with the layer", if stroke then stroke.Thickness else 0, styles.Dealt.Weight * Layers.Scale(), 0.01)
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
			t.Check("cream to gold, head to foot", gradient ~= nil and gradient.Color.Keypoints[1].Value == critical.Top and gradient.Color.Keypoints[#gradient.Color.Keypoints].Value == critical.Foot)
			t.Check("in the face's italic, or upright as Config says", c1 ~= nil and (c1.FontFace.Style == Enum.FontStyle.Italic) == critical.Italic)
			t.Wait(numbers.Count + 0.05)
			t.Near("settled", one.Scale.Scale, 1, 0.001)
			local sweep = one.Sweep
			t.Near("its stroke as clear as Config says", if sweep then sweep.ImageTransparency else 1, critical.Sweep.Transparency, 0.02)
			t.Check("in Config's tint", sweep ~= nil and sweep.ImageColor3 == critical.Sweep.Tint)
			Effects.Number(root, "SelfTest:word", nil, { Style = "Word", Word = "Dodge" }, numbers)
			Effects.Number(root, "SelfTest:word", nil, { Style = "Word", Word = "Dodge" }, numbers)
			local word = of("SelfTest:word")
			t.Check("a dodge is one grey word on its pointer", keys() == 3 and word ~= nil and word.Text == "Dodge" and word.Pointer ~= nil, if word then word.Text else "none")
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
			t.Check("six numbers up at once", keys() == 6, `{keys()}`)
			t.Wait(numbers.Seconds + 0.1)
			t.Check("all gone a fade after their last", counting[root] == nil, `{keys()} left`)
			root:Destroy()
		end,
	},
	{
		Name = "HUD: experience has one colour: the level-up's word is edged in the thread's blue, the sleeve is that blue, the column fades to it",
		Run = function(t: any)
			-- Research on TR3's three calls (2026-11-13): the word takes the card's thread's blue, and so does the light, as it
			-- is (a beam, unlit by the scene: AR8 C). Research's pass on AR8 C, fix 1: the word's fill is bright and the blue
			-- is its edge, so it reads over a blue hat. On a stand-in body.
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored, root.CanCollide, root.CanQuery, root.Transparency = true, false, false, 1
			root.CFrame = CFrame.new(0, 600, 0)
			root.Parent = workspace
			local look = EffectsConfig.LevelUp
			local xp = HudConfig.Card.Xp
			local column, word, sleeve = Effects.LevelUp(root, 7)
			local edge = word:FindFirstChildOfClass("UIStroke")
			local fill = word.TextColor3
			t.Check("the word is edged in the thread's blue", edge ~= nil and edge.Color:ToHex() == xp:ToHex(), if edge then edge.Color:ToHex() else "no edge")
			t.Check("its edge drawn at its authored width", edge ~= nil and math.abs(edge.Thickness - look.Word.Edge * Layers.Scale()) < 0.01)
			t.Check("its fill is bright, near white", math.min(fill.R, fill.G, fill.B) >= 0.8, fill:ToHex())
			t.Check("and of the same blue's hue", (fill.B - fill.R) * (xp.B - xp.R) > 0, `{fill:ToHex()} against {xp:ToHex()}`)
			t.Check("one edge only, no legacy stroke", word.TextStrokeTransparency >= 1)
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
			t.Wait(look.Seconds + look.Column.Peak * look.Column.Seconds - look.Column.Seconds)
			t.Check("all gone after the effect", not column:IsDescendantOf(game) and not sleeve:IsDescendantOf(game) and not word:IsDescendantOf(game))
			root:Destroy()
		end,
	},
	{
		Name = "Effects: the level-up is light that rises: a column out of the feet past the head, its foot after, gone by its seconds",
		Run = function(t: any)
			-- AR8 C, part 4 (rule 3): the main shape stands up out of the feet past the head, brightest in the first quarter
			-- of its life; its foot then leaves the ground and climbs after its top; the sleeve comes a breath later, wider and
			-- fainter, over the body; the word pops in as the column peaks. Solid light: one part each, nothing falls (the
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
			local column, word, sleeve = Effects.LevelUp(root, 7)
			local scale = word:FindFirstChildOfClass("UIScale")
			local brightest, brightestAt, highest, footAt, lowestFoot = 1, -1, -math.huge, -1, math.huge
			local sleeveFirst, sleeveWidest, columnWidest, sleeveOpaque = -1, 0, 0, 0
			local wordFirst, wordBiggest, wordLowest = -1, 0, math.huge
			local plate = word.Parent :: Frame
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
				if word.Parent and word.TextTransparency < 1 then
					if wordFirst < 0 then
						wordFirst = age
					end
					wordBiggest = math.max(wordBiggest, if scale then scale.Scale else 1)
					local over = World.Where(plate)
					if over then
						wordLowest = math.min(wordLowest, over.Y - feet)
					end
				end
			end)
			t.Wait(c.Seconds + 0.1)
			t.Check("the column is gone by its seconds", opaque(column) == 0, `{opaque(column)}`)
			t.Wait(look.Seconds + c.Peak * c.Seconds - c.Seconds + 0.1)
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
			t.Check("the word pops in as the column peaks", wordFirst >= c.Peak * c.Seconds - 0.03 and wordFirst <= c.Peak * c.Seconds + 0.1, string.format("at %.3f s", wordFirst))
			t.Check("past its size for a moment", wordBiggest > 1, string.format("%.3f", wordBiggest))
			t.Check("the word stands clear over the lead's top, hat and all, its whole life", wordLowest >= tall + look.Word.Clear - 0.05 and look.Word.Clear > 0, string.format("its foot at %.2f studs, the lead %.1f", wordLowest, tall))
			t.Check("all gone after", not column:IsDescendantOf(game) and not sleeve:IsDescendantOf(game) and not word:IsDescendantOf(game))
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
			-- The level-up's word is an open plate (research's pass on AR8 C, fix 1): born at the band, it may stand in the sky
			-- between the band's pieces, but never over one it crosses, nor over the top bar's foot (the phone pack,
			-- 2026-11-13: it drew over the Electricity pill). Each piece's span is its frame, the band's margin all round.
			local feet = Instance.new("Part")
			feet.Name = "HumanoidRootPart"
			feet.Anchored, feet.CanCollide, feet.CanQuery, feet.Transparency = true, false, false, 1
			feet.Position = ray.Origin + ray.Direction * 24 - Vector3.new(0, 3, 0)
			feet.Parent = workspace
			local _, word = Effects.LevelUp(feet, 7)
			local plate = word.Parent :: Frame
			local up = EffectsConfig.LevelUp
			local parts = HudController.Parts()
			local pieces = { parts.Lead, parts.Target, (parts.Credits :: GuiObject).Parent :: GuiObject, (parts.Electricity :: GuiObject).Parent :: GuiObject }
			local margin = HudConfig.Numbers.Band
			local overPiece, overBar, seen, crossed = math.huge, math.huge, 0, 0
			local look = RunService.RenderStepped:Connect(function()
				if not (plate.Parent and plate.Visible) then
					return
				end
				seen += 1
				local origin, scale = world.AbsolutePosition, Layers.Scale()
				local left = (plate.AbsolutePosition.X - origin.X) / scale
				local right = left + plate.AbsoluteSize.X / scale
				local top = (plate.AbsolutePosition.Y - origin.Y) / scale
				overBar = math.min(overBar, top - (Layers.Get("Hud").AbsolutePosition.Y - origin.Y) / scale)
				for _, piece in pieces do
					if piece.Visible then
						local at = (piece.AbsolutePosition - origin) / scale
						local size = piece.AbsoluteSize / scale
						if at.X - margin < right - 0.5 and at.X + size.X + margin > left + 0.5 then -- flush beside it isn't over it
							crossed += 1
							overPiece = math.min(overPiece, top - (at.Y + size.Y + margin))
						end
					end
				end
			end)
			t.Wait(up.Seconds + up.Column.Peak * up.Column.Seconds + 0.1)
			look:Disconnect()
			feet:Destroy()
			t.Check("the level-up's word showed", seen > 10, `{seen} frames`)
			t.Check("and never over the top bar's foot, its rise included", overBar >= -1, string.format("%.1f px under it at its closest", overBar))
			t.Check("nor over a piece of the band it crosses", crossed == 0 or overPiece >= -1, if crossed == 0 then "it crossed none" else string.format("%.1f px under one at its closest", overPiece))
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
				if type(heal) == "table" and heal.T == lead and type(heal.Amount) == "number" then
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
			t.Check("about its middle", (now - middle).Magnitude <= 1, string.format("%.1f px off", (now - middle).Magnitude))
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
				t.Check(`clear of the signature's ring, in {at.Name}`, clear(parts.Signature :: GuiObject))
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
			local gold = HudConfig.Card.Level
			local watch = RunService.RenderStepped:Connect(function()
				most = math.max(most, Pop.Active(pill))
				moved = math.max(moved, (pill.AbsolutePosition + pill.AbsoluteSize / 2 - middle).Magnitude)
				levelMost = math.max(levelMost, Pop.Active(level))
				if glint.Visible then
					glinted = math.max(glinted, 1 - glint.BackgroundTransparency)
				end
				local c = level.TextColor3
				whitest = math.max(whitest, (c.R + c.G + c.B) - (gold.R + gold.G + gold.B))
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
				t.Check("and brightened toward white", whitest > 0.2, string.format("%.2f", whitest))
				t.Check("its colour back after", level.TextColor3:ToHex() == gold:ToHex(), level.TextColor3:ToHex())
				t.Check("the thread glinted", glinted >= cfg.Glow - 0.05, string.format("%.2f opaque", glinted))
				t.Check("and the glint's gone after", not glint.Visible)
			end
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
			t.Check("and its level, on the badge", level == tostring(lead:GetAttribute("Level")), level)
			local health, most = lead:GetAttribute("Health") :: number, lead:GetAttribute("MaxHealth") :: number
			t.Near("its health bar is its share of health", parts.LeadHealth:GetAttribute("Share") :: number, health / most, 0.01)
			local inside = (parts.LeadHealthText :: TextLabel).Text
			t.Check("with its health and its most inside, set tight", inside == Hud.Health(health, most, nil, true), inside)
			local def = Voidkin.ById[lead:GetAttribute("Def") :: string]
			t.Check("its portrait in its rarity's frame", def ~= nil and parts.LeadPortrait:GetAttribute("Voidkin") == def.Id and parts.LeadPortrait:GetAttribute("Rarity") == def.Rarity, `{parts.LeadPortrait:GetAttribute("Face")}`)
			t.Check("and its type's gem", def ~= nil and parts.LeadGem:GetAttribute("Kit") == `Gem{def.Type}`, `{parts.LeadGem:GetAttribute("Kit")}`)
			local credits = (parts.Credits :: TextLabel).Text
			t.Check("the Credits pill shows the save's", credits == Read.Number(view.Currency.Credits), credits)
			t.Wait(PLATE_TICK)
			local shown = (parts.Electricity :: TextLabel).Text
			local digits = string.gsub(shown:match("^([%d,%.]+) /") or "", ",", "")
			local stored = tonumber(digits)
			local now = Read.Base(view, workspace:GetServerTimeNow())
			t.Check("the Electricity pill shows a number", stored ~= nil, shown)
			if stored then
				t.Near("the battery as it stands now", stored, now.Data.Base.Battery, 1)
			end
			t.Check("a battery under 100 shows its tenth, so it visibly counts up", Read.Stored(0.35) == "0.4" and Read.Stored(86.24) == "86.2" and Read.Stored(2357) == "2,357", `{Read.Stored(0.35)}, {Read.Stored(86.24)}, {Read.Stored(2357)}`)
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
			local blank: { string } = {}
			for _, panel in Layers.Get("World"):GetDescendants() do
				if panel.Name == "Panel" and panel:IsA("GuiObject") and panel.Visible then
					local says = false
					for _, line in panel:GetChildren() do
						says = says or (line:IsA("TextLabel") and line.Text ~= "")
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
		Name = "HUD: in a fight with a shard in the bag, on the smallest phone, every piece fits, apart and in the safe area",
		Run = function(t: any)
			-- TR3's check: the UI lint at the smallest phone's scale (docs/ui.md, rule 1). The lead's card, the target's, both
			-- pills, the ring, the chip and the dock all showing at once, laid out in this window's safe area and then in the
			-- smallest phone's (Theme.Smallest under Roblox's top bar, at the scale's floor).
			local lead = myLead()
			local level = if lead then lead:GetAttribute("Level") else nil
			t.Check("the lead is in the world", type(level) == "number")
			if lead == nil or type(level) ~= "number" then
				return
			end
			local parts = HudController.Parts()
			local spawned = t.Server("FightSpawn", "brawler", level, SHADE_AHEAD)
			local gave = t.Server("BaseGive", "named_watt", 1)
			local shown = waitFor(t, SHADE_TIMEOUT, function(): boolean
				return parts.Target.Visible and parts.Chip.Visible
			end)
			t.Check("a fight, and a shard in the bag", type(spawned) == "table" and spawned.Ok == true and shown)
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
		Name = "HUD: the signature's ring shows only in a fight, empties and flashes when it fires, and fills over its cooldown",
		Run = function(t: any)
			-- TR3, part 5: at the right edge, low. The server says when the signature is ready again (FightService, Ready);
			-- the ring flashes the moment it fires, then fills with the cooldown, the class's glyph in its middle.
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
				t.Check("a lead without a signature has no ring", lead ~= nil and not ring.Visible)
				return
			end
			local action = signature :: Actions.Action
			-- Only in a fight (TR3's verdict, fix 5): hidden out of one, in as the lead takes a target, out a moment after.
			local config = HudConfig.Ring
			local function target(): boolean
				local id = lead:GetAttribute("Target")
				return type(id) == "string" and id ~= ""
			end
			waitFor(t, config.Linger + config.FadeOut + 2, function(): boolean
				return not target() and not ring.Visible
			end)
			t.Check("out of a fight, the ring is hidden", not ring.Visible, `target {tostring(lead:GetAttribute("Target"))}`)
			local level = lead:GetAttribute("Level")
			local spawned = t.Server("FightSpawn", "brawler", (if type(level) == "number" then level else 1) + SHADE_TOUGHER, SHADE_AHEAD)
			t.Check("a Shade to fight spawns", type(spawned) == "table" and spawned.Ok == true)
			t.Check("the lead takes it on", waitFor(t, SHADE_TIMEOUT, target))
			t.Wait(config.FadeIn + 0.1)
			t.Check("in a fight, the ring fades in", ring.Visible and ring:GetAttribute("Seen") == 1, `{tostring(ring:GetAttribute("Seen"))} in`)
			t.Server("FightSpawn") -- clears it
			t.Check("the fight ends", waitFor(t, 2, function(): boolean
				return not target()
			end))
			t.Wait(config.Linger / 2)
			t.Check("it stays a moment after", ring.Visible and ring:GetAttribute("Seen") == 1, `{tostring(ring:GetAttribute("Seen"))} in`)
			t.Wait(config.Linger / 2 + config.FadeOut + 0.15)
			t.Check("then fades out", not ring.Visible, `{tostring(ring:GetAttribute("Seen"))} in`)
			local row = Voidkin.ById[def :: string]
			local glyph = ring:FindFirstChild("Glyph")
			t.Check("with its class's glyph", row ~= nil and glyph ~= nil and glyph:GetAttribute("Kit") == `Class{row.Class}Glyph`, if glyph then `{glyph:GetAttribute("Kit")}` else "no glyph")
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
			t.Check("it flashed when it fired", flash > 0.5, string.format("%.2f", flash))
			t.Near("it fills with the cooldown", second - first, (os.clock() - at) / action.Cooldown, 0.03)
			t.Server("Replay")
			t.Wait(0.3)
		end,
	},
	{
		Name = "HUD: a shard in the bag: the chip names the next step, and the Breaker's plate is lit until it's in",
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
			t.Check("at home, the chip says into the Breaker", hud.Chip.Visible and string.find(text.Text, "into the Breaker", 1, true) ~= nil, text.Text)
			t.Check("and the Breaker's plate is lit", panel:GetAttribute("Lit") == true) -- its edge bold in the accent (Panel.Lit)
			t.Reset() -- the test pad, off the plot
			t.Wait(PLATE_TICK * 2)
			t.Check("in the field, break it at home", hud.Chip.Visible and string.find(text.Text, "at home", 1, true) ~= nil and string.find(text.Text, "Breaker", 1, true) == nil, text.Text)
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
			local shard = "named_watt"
			local gave = t.Server("BaseGive", shard, 1)
			t.Check("a shard in the bag: the plate has news", type(gave) == "table" and gave.Ok == true)
			local old = Players.LocalPlayer.Character
			t.Check("the avatar goes home", t.Server("Respawn") == true and waitFor(t, ARRIVE_TIMEOUT, function(): boolean
				local character = Players.LocalPlayer.Character
				local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
				return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
			end))
			t.Wait(PLATE_TICK * 2)
			local prompt = BaseController.Parts().BreakerPrompt
			local anchor = if prompt then prompt.Parent :: BasePart? else nil
			local camera = workspace.CurrentCamera
			local band = world:GetAttribute("Band")
			t.Check("its point, and the band", anchor ~= nil and camera ~= nil and type(band) == "number", tostring(band))
			if anchor and camera and type(band) == "number" then
				local scale = Layers.Scale()
				local at = Vector2.new(camera.ViewportSize.X * 0.15, band * scale * 0.5)
				camera.CameraType = Enum.CameraType.Scriptable
				-- Turned so the pixel `at` looks along the line to the point: its direction in the camera's frame is turned
				-- onto the camera's forward.
				camera.CFrame = CFrame.lookAt(camera.CFrame.Position, anchor.Position)
				local aside = camera.CFrame:VectorToObjectSpace(camera:ViewportPointToRay(at.X, at.Y).Direction)
				camera.CFrame *= CFrame.fromRotationBetweenVectors(aside, Vector3.new(0, 0, -1))
				for _ = 1, 3 do
					RunService.RenderStepped:Wait()
				end
				local point = camera:WorldToViewportPoint(anchor.Position)
				t.Check("the Breaker's point is over the band", point.Y / scale < band, string.format("%.1f against %.1f", point.Y / scale, band))
				t.Check("its plate shows", plate.Visible and plate.Parent ~= nil)
				local top = (plate.AbsolutePosition.Y - world.AbsolutePosition.Y) / scale - band
				t.Check("whole under the band", top >= -1, string.format("its top %.1f px under the band", top))
				t.Check("and right under it, not lost lower", top <= 2, string.format("its top %.1f px under the band", top))
				camera.CameraType = Enum.CameraType.Custom
			end
			if type(gave) == "table" and gave.Ok == true then
				t.Server("BaseGive", shard, -1)
			end
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
		Name = "Base: the plot's plates speak only near their machine or lit with news, and the battery's says only its name",
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
				-- The camera keeps its own look (FadeController): turned to the avatar's, a little down, as a player would.
				local camera = workspace.CurrentCamera
				local along = Vector3.new(look.X - at.X, 0, look.Z - at.Z)
				if camera and along.Magnitude > 1e-3 then
					local from = camera.CFrame.Position
					local down = math.rad(15)
					camera.CFrame = CFrame.lookAt(from, from + along.Unit * math.cos(down) - Vector3.new(0, math.sin(down), 0))
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
				local out: { [string]: boolean } = { Breaker = bagged or #now.Base.Ready > 0, Battery = false }
				for name in BaseController.Says() do
					local index = tonumber(name:match("^Bay(%d+)$"))
					if index then
						local bay: any = now.Base.Bays[index]
						out[name] = bay ~= nil and bay.Worker == "" and free
					end
				end
				return out
			end
			-- Every plate whose spot is neither near nor lit is hidden; each spot's news is the save's.
			local function quiet(where: string)
				local want = news()
				local wrong, loud = {}, {}
				for name, spot in BaseController.Says() do
					if spot.News ~= want[name] or lit(name) ~= want[name] then
						table.insert(wrong, `{name} {spot.News}/{lit(name)}, the save {want[name]}`)
					end
					if not spot.News and not spot.Near and plateOf(name).Visible then
						table.insert(loud, name)
					end
				end
				t.Check(`{where}: each plate's news and its light are the save's`, #wrong == 0, table.concat(wrong, "; "))
				t.Check(`{where}: a plate neither near nor with news hides`, #loud == 0, table.concat(loud, ", "))
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
			t.Check("and its plate shows", waitFor(t, 1, function(): boolean
				return plateOf("Battery").Visible
			end))
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
			t.Check("and its plate shows", waitFor(t, 1, function(): boolean
				return plateOf("Breaker").Visible
			end))

			-- News reaches the far side of the plot.
			stand(battery.Ground + back * 24, breaker.Ground)
			local shard = "named_watt"
			local had = news().Breaker
			t.Check("a shard goes in the bag", t.Server("BaseGive", shard, 1).Ok == true)
			t.Check("far off, the Breaker's plate lights and shows", waitFor(t, ANSWER, function(): boolean
				return BaseController.Says().Breaker.News and lit("Breaker") and plateOf("Breaker").Visible
			end))
			quiet("with a shard in the bag")
			t.Check("the shard comes back out", t.Server("BaseGive", shard, -1).Ok == true)
			t.Check("and the Breaker's news is the save's again", waitFor(t, ANSWER, function(): boolean
				return BaseController.Says().Breaker.News == had and (had or not plateOf("Breaker").Visible)
			end))
			local worker = view.Base.Bays[1] and view.Base.Bays[1].Worker or ""
			if worker ~= "" and says.Bay1 then
				t.Check("bay 1's worker steps out", ProfileController.Act("SetWorker", { Bay = 1, Voidkin = "" }).Ok == true)
				t.Check("far off, bay 1 lights and shows: a free Voidkin could work it", waitFor(t, ANSWER, function(): boolean
					return BaseController.Says().Bay1.News and lit("Bay1") and plateOf("Bay1").Visible
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
				t.Check(`the dock's {name} is selected while it's open`, waitFor(t, 0.5, function(): boolean
					return Button.State(hud[name] :: TextButton) == "Selected"
				end), Button.State(hud[name] :: TextButton))
				Screen.Close()
				t.Check(`and shows again once {name} closes`, waitFor(t, 0.5, function(): boolean
					return layer.Visible
				end))
				t.Check(`and the dock's {name} is back at rest`, waitFor(t, 0.5, function(): boolean
					return Button.State(hud[name] :: TextButton) == "Rest"
				end), Button.State(hud[name] :: TextButton))
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
			-- finds its zero, and each moment is a row in seconds from it. The way out and home is the Festival Door. One step
			-- isn't played, and its row says so: Watt's 30 s in the Breaker (BaseSkip).
			take(t, function(kit: Take)
				local player = Players.LocalPlayer
				local moment, walkTo = kit.Moment, kit.WalkTo
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

				t.Server("DataWipe")
				t.Check("a new account", waitFor(t, ANSWER, function(): boolean
					local view = ProfileController.Get()
					return view ~= nil and view.Progress.Starter == ""
				end))
				kit.Zero()
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
				-- Rook's level-ups and downs, as they happen.
				local lead = myLead()
				local watching: { RBXScriptConnection } = {}
				if lead then
					table.insert(watching, lead:GetAttributeChangedSignal("Level"):Connect(function()
						moment(`Rook reaches level {lead:GetAttribute("Level")}`)
					end))
					table.insert(watching, lead:GetAttributeChangedSignal("State"):Connect(function()
						if lead:GetAttribute("State") == "Down" then
							moment("Rook is down")
						end
					end))
				end
				t.Wait(2)
				local plot = player:GetAttribute("Plot")
				local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
				t.Check("the plot has its Festival Door", door ~= nil)
				if door then
					moment("the walk to the Festival Door")
					local look = Markers.At(door).LookVector
					walkTo(Markers.At(door).Position - look * DOOR_RUN + Vector3.new(0, R6_ROOT_HEIGHT, 0))
					t.Check("through it", walkThrough(t, door, false))
					moment("through the door: Lantern Row's gate")
					t.Wait(1)
				end

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

				for _, connection in watching do
					connection:Disconnect()
				end
				local homeDoor = Markers.Find("GroundDoor", { Ground = WorldConfig.Row.Ground })
				t.Check("Lantern Row has its door home", homeDoor ~= nil)
				if homeDoor then
					moment("the walk back to the door home")
					local look = Markers.At(homeDoor).LookVector
					walkTo(Markers.At(homeDoor).Position + look * DOOR_RUN + Vector3.new(0, R6_ROOT_HEIGHT, 0))
					t.Check("the avatar is home", walkThrough(t, homeDoor, false))
					moment("home through the door")
				end
				t.Wait(1.5)
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
		end,
	},
	{
		Name = "Take: the Lamplighter's fall, for TR2's close",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			-- TR2's close (docs/test-requests.md, TR2, research's read of the fixes): the keeper's fight at real speed from the
			-- player's camera, its fall, the set-down beyond the ring and the shortcut home. Two steps aren't played, and their rows
			-- say so: the lead's level is set (gear isn't in, and a bare Voidkin can't beat a keeper, docs/balance.md), and the
			-- avatar is set down short of the keeper's gate (the street is the loop take's). The gate's Challenge is held as a
			-- player holds it.
			take(t, function(kit: Take)
				local player = Players.LocalPlayer
				local moment, walkTo = kit.Moment, kit.WalkTo
				local keeper = Combat.Keeper
				local moved = keeper.Fade.Out + keeper.Fade.Hold / 2 + MOVE_SLACK
				local before = myLead()
				local level = if before then before:GetAttribute("Level") else nil
				t.Check("a lead to fight with", type(level) == "number")
				if type(level) ~= "number" then
					return
				end
				t.Check("the lead is set to the take's level", t.Server("LeadLevel", TAKE_KEEPER_LEVEL).Ok == true)
				local old = player.Character
				t.Server("Respawn")
				t.Check("the lead stands at it", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
					local lead = myLead()
					return player.Character ~= old and lead ~= nil and lead:GetAttribute("Level") == TAKE_KEEPER_LEVEL
				end))
				-- Short of the gate, past Pack 6's notice and the lead's leash: along the street from Pack 5 to Pack 6.
				local at: { [string]: Vector3 } = {}
				for _, row in t.Server("Packs") do
					at[row.Name] = row.At
				end
				local last, prior = at["Pack 6"], at["Pack 5"]
				t.Check("the street's last packs stand", last ~= nil and prior ~= nil)
				if last == nil or prior == nil then
					return
				end
				local along = Vector3.new(last.X - prior.X, 0, last.Z - prior.Z).Unit
				local start = last + along * KEEPER_SHORT + Vector3.new(0, R6_ROOT_HEIGHT, 0)
				t.Root().CFrame = CFrame.lookAt(start, start + along)
				-- The camera behind the avatar, where a player who walked up the street has it.
				RunService.RenderStepped:Wait()
				local camera = workspace.CurrentCamera
				camera.CFrame = CFrame.lookAt(start - along * TAKE_ZOOM + Vector3.new(0, TAKE_ZOOM / 3, 0), start)
				local prompt: ProximityPrompt? = nil
				t.Check("the keeper's gate streams in", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
					for _, item in workspace:GetDescendants() do
						if item:IsA("ProximityPrompt") and item.ActionText == "Challenge" then
							prompt = item
						end
					end
					return prompt ~= nil
				end))
				t.Wait(LEAD_SETTLE + 1)
				kit.Zero()
				moment("zero: the white frame")
				moment(`set down short of the keeper's gate, Rook at level {TAKE_KEEPER_LEVEL} (both set, not played)`)
				local holder = if prompt then prompt.Parent else nil
				if prompt == nil or holder == nil or not holder:IsA("BasePart") then
					return
				end
				local here = t.Root().Position
				local flat = Vector3.new(holder.Position.X, here.Y, holder.Position.Z)
				-- A prompt shows only while it's on screen (Roblox's own rule, seen 2026-11-12): held as a player holds it, once
				-- the walk up to the gate has brought it into view.
				local shown = false
				local showing = ProximityPromptService.PromptShown:Connect(function(which: ProximityPrompt)
					shown = shown or which == prompt
				end)
				moment("the walk to the keeper's gate")
				walkTo(flat + (here - flat).Unit * KEEPER_ASK)
				t.Check("the Challenge shows as the avatar comes up to the gate", waitFor(t, KEEPER_SHOWS, function(): boolean
					return shown
				end))
				showing:Disconnect()
				t.Wait(1)
				moment("the Challenge held")
				prompt:InputHoldBegin()
				t.Wait(keeper.Hold + 0.2)
				prompt:InputHoldEnd()
				local asked = waitFor(t, REPLICATE, function(): boolean
					return player:GetAttribute("Try") ~= nil
				end)
				if not asked then
					t.Check("the Challenge didn't start a try: KeeperTry stands in", t.Server("KeeperTry").Ok == true)
					moment("KeeperTry stands in for the Challenge")
				end
				moment("the try: the fade into the ring")
				local seen: any = nil
				t.Check("the Lamplighter stands in the ring", waitFor(t, moved + 2, function(): boolean
					seen = t.Server("Keeper")
					return seen.Keeper ~= "" and seen.KeeperHealth > 0
				end))
				if seen == nil or seen.Keeper == "" then
					return
				end
				moment("in the ring, the Lamplighter at its middle")
				local full, leadFull = seen.KeeperHealth, seen.LeadHealth
				local struck, hurt, half, outcome = false, false, false, nil
				-- The framing, measured as the camera sees it (research's read of the closing takes): the Lamplighter's height
				-- as a share of the frame's, and whether Rook stands clear of it, once a second.
				local heights: { number } = {}
				local clear, samples = 0, 0
				local seenWhole, looks = 0, 0
				local sampleAt = os.clock() + 1
				local deadline = os.clock() + TAKE_KEEPER
				while os.clock() < deadline do
					local now = t.Server("Keeper")
					if os.clock() >= sampleAt then
						sampleAt += 1
						local them, ours, avatar = fighterModel(seen.Keeper), myLead(), Players.LocalPlayer.Character
						local low, high = nil, nil
						if them then
							low, high = screenBox(them) -- an if-expression would keep only the first of its values
						end
						if low and high then
							table.insert(heights, (high.Y - low.Y) / workspace.CurrentCamera.ViewportSize.Y)
						end
						local rook = if them and ours then covered(them, ours) else nil
						if rook then
							samples += 1
							clear += if rook <= HIDDEN then 1 else 0
						end
						local keeperHidden = if them and avatar then covered(avatar, them) else nil
						if keeperHidden then
							seenWhole += if keeperHidden <= HIDDEN then 1 else 0
							looks += 1
						end
					end
					if not struck and now.KeeperHealth < full then
						struck = true
						moment("Rook's first hit on the Lamplighter")
					end
					if not hurt and now.LeadHealth < leadFull then
						hurt = true
						moment("the Lamplighter's first hit on Rook")
					end
					if not half and now.KeeperHealth <= full / 2 then
						half = true
						moment(`the Lamplighter at half, Rook at {math.floor(now.LeadHealth / leadFull * 100 + 0.5)}%`)
					end
					local lead = myLead()
					if now.KeeperHealth <= 0 then
						outcome = "Win"
						moment(`the Lamplighter falls, Rook at {math.floor(now.LeadHealth / leadFull * 100 + 0.5)}%`)
						break
					elseif (lead and lead:GetAttribute("State") == "Down") or not now.InTry then
						outcome = "Loss"
						moment("Rook is down: the try is lost")
						break
					end
					t.Wait(0.1)
				end
				t.Check("the Lamplighter falls", outcome == "Win", tostring(outcome))
				table.sort(heights)
				local median = if #heights > 0 then heights[math.ceil(#heights / 2)] else nil
				t.Row("the Lamplighter's height, a share of the frame's (the fight's median)", KEEPER_FRAME.Low, KEEPER_FRAME.High, median, "")
				t.Row("of the fight's samples, the share with Rook clear of the Lamplighter", CLEAR_SHARE, 1, if samples > 0 then clear / samples else nil, `of {samples}`)
				t.Row("and with the Lamplighter clear of the avatar", CLEAR_SHARE, 1, if looks > 0 then seenWhole / looks else nil, `of {looks}`)
				if outcome == "Win" then
					t.Check("the try ends", waitFor(t, keeper.WinPause + moved + 2, function(): boolean
						return t.Server("Keeper").InTry == false
					end))
					moment("set down beyond the ring")
					t.Wait(MOVE_SLACK)
					t.Near("at the ring's exit (studs off)", t.Server("Keeper").FromExit, 0, SET_DOWN)
					t.Wait(TAKE_READ)
					local pad = nil
					t.Check("the shortcut is in view", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
						pad = Markers.Find("Shortcut")
						return pad ~= nil and pad:IsA("BasePart")
					end))
					if pad and pad:IsA("BasePart") then
						moment("the walk to the shortcut")
						walkTo(pad.Position + Vector3.new(0, R6_ROOT_HEIGHT, 0))
						t.Check("the shortcut sets the avatar down at home", waitFor(t, moved + 2, function(): boolean
							return t.Server("Keeper").FromHome <= SET_DOWN
						end))
						moment("home by the shortcut")
					end
				end
				t.Wait(4)
				moment("end")
				t.Server("LeadLevel", level) -- the lead's own level back
				t.Server("Respawn")
			end)
		end,
	},
	{
		Name = "Take: a rejoin, part 1: the leave, for TR2's close",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			-- TR2's close: a rejoin to the saved base, in two takes either side of a real leave (the playtest stopped, then
			-- started: a new server loads the save from the Test store, and the time between is time away). Here the player puts
			-- the bag's Lantern Row shards in the Breaker through the screen, as a player does before leaving.
			take(t, function(kit: Take)
				local player = Players.LocalPlayer
				local moment = kit.Moment
				local held = t.Server("Base").Bag[REJOIN_SHARD] or 0
				t.Check("shards in the bag to leave breaking", held >= 1, `{held} held`)
				local old = player.Character
				t.Server("Respawn")
				t.Check("the avatar stands on its plot", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
					local character = player.Character
					local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
					return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
				end))
				t.Wait(WorldConfig.Arrive + 1)
				kit.Zero()
				moment("zero: the white frame")
				BaseController.Open()
				moment(`the Base screen: {held} Lantern Row shards in the bag`)
				t.Wait(TAKE_READ)
				for index = 1, held do
					local add = screenButton("Base", "Bays", REJOIN_SHARD)
					t.Check(`shard {index} goes in through the screen`, add ~= nil and Button.Press(add))
					moment(`shard {index} into the Breaker`)
					t.Wait(1.5)
				end
				t.Wait(TAKE_READ)
				Screen.Close()
				moment("the plot: the Breaker at work, Watt at work")
				t.Wait(8)
				local base = t.Server("Base")
				t.Check("the base as it's left", #base.Ready == 0 and base.Bag[REJOIN_SHARD] == nil, `battery {base.Battery}, chambers {table.concat(base.Chambers, ", ")}, {#base.Line} in line, bays {table.concat(base.Bays, ", ")}, credits {base.Credits}, at {os.date("!%H:%M:%S")} UTC`)
				moment("end: the player leaves (the playtest stops)")
			end)
		end,
	},
	{
		Name = "Take: a rejoin, part 2: the return, for TR2's close",
		Manual = true,
		Stay = true,
		Run = function(t: any)
			-- The return (part 1 says how): the save as it was left, advanced by the time away. The recording starts before the
			-- playtest does, so it holds the load and the arrival; the white frame comes once the self-test can run.
			take(t, function(kit: Take)
				local moment = kit.Moment
				kit.Zero()
				moment("zero: the white frame, after the join")
				local base = t.Server("Base")
				local battery = tonumber(string.match(base.Battery, "^[%d%.]+")) or -1
				local watt = false
				for _, worker in base.Bays do
					watt = watt or string.find(worker, "(watt)", 1, true) ~= nil
				end
				local detail = `battery {base.Battery}, chambers {table.concat(base.Chambers, ", ")}, {#base.Line} in line, ready {#base.Ready}, bays {table.concat(base.Bays, ", ")}, credits {base.Credits}, at {os.date("!%H:%M:%S")} UTC`
				t.Check("Watt is still at work", watt, detail)
				t.Check("the shards left breaking are ready to open", #base.Ready >= 1 and #base.Line == 0, detail)
				t.Check("the battery paid for them and holds the rest", battery > 0 and battery < BaseConfig.Battery.Capacity, detail)
				t.Wait(1)
				moment("the plot as the player finds it")
				t.Wait(6)
				BaseController.Open()
				moment(`the Base screen: {#base.Ready} ready to open`)
				t.Wait(TAKE_READ)
				local open = screenButton("Base", "Breaker", `Ready_{REJOIN_SHARD}`)
				t.Check("one opens through the screen", open ~= nil and Button.Press(open))
				t.Check("the reveal shows", waitFor(t, ANSWER, function(): boolean
					return BaseController.Revealed() ~= nil
				end))
				moment("the reveal")
				t.Wait(TAKE_READ + 0.5)
				BaseController.Dismiss()
				Screen.Close()
				moment("the screen closed")
				t.Wait(3)
				moment("end")
			end)
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
			local level = tonumber(lead:GetAttribute("Level")) or 1
			Effects.LevelUp(root, level + 1)
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
			tap(parts.Voidkin :: TextButton)
			t.Wait(1.5)
			tap(closeOf("Voidkin"))
			t.Wait(1)
			tap(parts.Base :: TextButton)
			t.Wait(1.5)
			tap(closeOf("Base"))
			t.Wait(1)
			t.Server("LeadLevel", level)
			t.Server("DataCredits", -290)
			t.Check("no screen is left open", Screen.Current() == nil)
		end,
	},
}
