--!strict
-- Takes (client, Studio only): the self-test's takes, a list of their own beside Cases, which joins them. A take is
-- a stretch of play at real speed from the player's camera, for research's verdict in motion or a piece's close: Manual,
-- never in a full run. Cases gives it the helpers they share (Takes(given)), so each is written once; a take's own
-- live here. Split out of Cases on 2026-11-14, when the one file grew past what the type check can follow.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Shared = ReplicatedStorage.Shared
local Combat = require(Shared.Config.Combat)
local HudConfig = require(Shared.Config.Hud)
local WorldConfig = require(Shared.Config.World)
local BaseConfig = require(Shared.Config.Base)
local Markers = require(Shared.World.Markers)
local Kit = require(Shared.World.Kit)
local LightingConfig = require(Shared.Config.Lighting)
local Parts = require(Shared.Util.Parts)
local Profile = require(Shared.Data.Profile)
local ShardConfig = require(Shared.Config.Shards)
local HudController = require(script.Parent.Parent.Parent.Main.HudController)
local WayHomeController = require(script.Parent.Parent.Parent.Main.WayHomeController)
local BaseController = require(script.Parent.Parent.Parent.Main.BaseController)
local ProfileController = require(script.Parent.Parent.ProfileController)
local UI = script.Parent.Parent.Parent.Parent.UI
local BreakerScreen = require(UI.BreakerScreen)
local VoidkinScreen = require(UI.VoidkinScreen)
local Figure = require(UI.VoidkinScreen.Figure)
local VoidkinCases = require(script.Parent.VoidkinCases)
local Hud = require(Shared.Rules.Hud)
local Read = require(UI.Read)
local Button = require(UI.Kit.Button)
local Screen = require(UI.Kit.Screen)

local TAKE_READ = 3 -- seconds the take leaves a screen or a card up, as a player reads it
local TAKE_WALK = 45 -- seconds a walk of the take may last
local TAKE_FIGHT = 75 -- seconds a pack may take to fall in the take
local TAKE_TURN = 2.5 -- how fast the take's camera swings in behind a walking avatar (a share of the gap a second)
local TAKE_REACH = 2.5 -- studs from a waypoint that count as there
local TAKE_ZOOM = 12.5 -- studs from the avatar the take's camera holds: where Roblox's camera starts a player
local TAKE_HEAL = 25 -- seconds a fallen lead heals at home in TR12's take, for Combat.Lead.Home.Fallen's 90
local TAKE_BEFORE_FALL = 1.5 -- seconds of the fight before a take holds its lead's health low
local TAKE_LOW = 0.002 -- the share of its health a take holds its lead at, at most: a sliver, a hit from falling
local TAKE_HIT = 8 -- seconds a take waits for a hit to down its held lead before it downs it outright
local TAKE_GATE_SHORT = 8 -- studs short of the gate's door TR8's take stops, back down the street
local TAKE_ALONE = { Pack = "Pack 2", Short = 40 } -- TR16's take: the pack its lead falls at, and how far short of it
-- toward the gate the avatar is set down (past its notice and the lead's leash, so the walk up shows)
local TAKE_KEEPER = 150 -- seconds the keeper's take watches its fight
local TAKE_KEEPER_LEVEL = 14 -- the lead's level in the keeper's take: it wins bare, where gear will carry it in play
local KEEPER_SHORT = 55 -- studs past Pack 6 the keeper's take starts: out of its notice and the lead's leash, 25 short of the gate
local KEEPER_ASK = 5 -- studs from the Challenge the avatar stops to hold it, inside Combat.Keeper.Reach
local KEEPER_SHOWS = 3 -- seconds after the walk by which the Challenge shows, the gate in view
local KEEPER_FRAME = { Low = 0.28, High = 0.4 } -- the keeper's height in the take, a share of the frame's: "about a third"
local HIDDEN = 1 / 3 -- of a fighter the camera can't see for a nearer one that still counts as clear of it
local CLEAR_SHARE = 0.7 -- the share of the fight's samples with a fighter clear: "most"
local REJOIN_SHARD = "lanternrow_standard" -- the shard the rejoin's takes leave breaking: Lantern Row's packs drop it
local TAKE_SPIN = { Degrees = 120, Seconds = 1.6 } -- TR17's take: a drag's turn, there and back

-- What Cases gives the takes: the helpers and numbers they share.
export type Given = {
	R6_ROOT_HEIGHT: number,
	LEAD_SETTLE: number,
	ARRIVE_TIMEOUT: number,
	MOVE_SLACK: number,
	SET_DOWN: number,
	REPLICATE: number,
	PACK_STAND: number,
	ANSWER: number,
	SKIP_ALL: number,
	waitFor: (t: any, seconds: number, ok: () -> boolean) -> boolean,
	streamed: (t: any, name: string, where: { [string]: any }?) -> Instance?,
	screenButton: (screen: string, list: string, row: string) -> TextButton?,
	leadButton: (id: string) -> TextButton?,
	readyCount: (def: string) -> number,
	openReadyDown: (t: any, def: string, keep: number) -> (),
	breakerPart: (name: string) -> Instance?,
	bagItem: (def: string) -> BreakerScreen.Selection?,
	chosenWork: (item: BreakerScreen.Selection?) -> Profile.ShardWork?,
	infuseButton: (level: number) -> (TextButton?, boolean),
	walkThrough: (t: any, door: Instance, close: boolean) -> boolean,
	fighterModel: (id: string) -> Model?,
	myLead: () -> Model?,
	DOOR_RUN: number,
}

return function(given: Given): { any }
	local R6_ROOT_HEIGHT = given.R6_ROOT_HEIGHT
	local LEAD_SETTLE = given.LEAD_SETTLE
	local ARRIVE_TIMEOUT = given.ARRIVE_TIMEOUT
	local MOVE_SLACK = given.MOVE_SLACK
	local SET_DOWN = given.SET_DOWN
	local REPLICATE = given.REPLICATE
	local PACK_STAND = given.PACK_STAND
	local ANSWER = given.ANSWER
	local SKIP_ALL = given.SKIP_ALL
	local waitFor = given.waitFor
	local streamed = given.streamed
	local screenButton = given.screenButton
	local leadButton = given.leadButton
	local readyCount = given.readyCount
	local openReadyDown = given.openReadyDown
	local breakerPart = given.breakerPart
	local bagItem = given.bagItem
	local chosenWork = given.chosenWork
	local infuseButton = given.infuseButton
	local walkThrough = given.walkThrough
	local fighterModel = given.fighterModel
	local myLead = given.myLead
	local DOOR_RUN = given.DOOR_RUN

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

	-- A take's fall (not played, and its rows say so): the player's lead's health held at most TAKE_LOW of its whole from now,
	-- so its regen (Config.Stats.Regen) can't outlast the pack, until a hit downs it; downed outright after TAKE_HIT seconds
	-- without one (a lead levels over the pack takes next to nothing a hit). True once it's down.
	local function fallHeld(t: any, moment: (string) -> ()): boolean
		local lead = myLead()
		if lead == nil then
			return false
		end
		local function down(): boolean
			return lead:GetAttribute("State") == "Down"
		end
		if waitFor(t, TAKE_HIT, function(): boolean
			if down() then
				return true
			end
			t.Server("FightHealth", TAKE_LOW, true)
			return false
		end) then
			moment("a hit downs it")
			return true
		end
		t.Server("FightHealth", 0)
		moment(`not played: downed, no hit having downed it in {TAKE_HIT} s`)
		return waitFor(t, REPLICATE, down)
	end

	-- TR17's evidence (docs/test-requests.md, TR17, "Done when"): the Voidkin screen in grey in one layout, at home, from
	-- the dock: the figure turned and tapped, three Voidkin switched by the strip and by a flick, each tab, one sent to lead
	-- and one to work. Not played, and their rows say so: the layout (a Tune before the take), a drag's turn (the figure's
	-- own Turn, frame by frame) and the flicks and the tap (its own gesture handler, given a flick's travel and time). After
	-- the take, out of it, the lead and the bay go back as they were.
	local function voidkinTake(layout: string): any
		return {
			Name = `Take: TR17, the Voidkin screen in {layout}, for research's verdict`,
			Manual = true,
			Stay = true,
			Run = function(t: any)
				local ids = VoidkinCases.Own(t, waitFor, ANSWER)
				t.Check("three Voidkin to switch between", #ids >= 3, `{#ids}`)
				if #ids < 3 then
					return
				end
				local was = HudConfig.Voidkin.Layout
				t.Server("Tune", "Hud.Voidkin.Layout", layout)
				t.Check("the layout tuned on this client", waitFor(t, REPLICATE, function(): boolean
					return HudConfig.Voidkin.Layout == layout
				end))
				Screen.Close()
				local view = ProfileController.Get() :: Profile.View
				local lead = view.Roles.Lead
				local free = {}
				for _, id in ids do
					if id ~= lead and Read.Role(view, id) == "" then
						table.insert(free, id)
					end
				end
				local _, bay = Hud.WorkReason("", view.Base.Bays)
				t.Check("two free, to lead and to send, and an empty bay", #free >= 2 and bay ~= nil)
				if #free < 2 or bay == nil then
					return
				end
				local function find(name: string): TextButton?
					local found = VoidkinScreen.Find(name)
					return if found and found:IsA("TextButton") then found else nil
				end
				local function press(name: string): boolean
					local found = find(name)
					return found ~= nil and Button.Press(found)
				end
				local function spin(degrees: number, seconds: number)
					local began, done = os.clock(), 0
					while done < 1 do
						RunService.RenderStepped:Wait()
						local now = math.min(1, (os.clock() - began) / seconds)
						local figure = VoidkinScreen.Figure()
						if figure then
							Figure.Turn(figure, degrees * (now - done))
						end
						done = now
					end
				end
				local function gesture(delta: Vector2, took: number): string
					local figure = VoidkinScreen.Figure()
					return if figure then Figure.Gesture(figure, delta, took) else "none"
				end
				local swipe = HudConfig.Voidkin.Swipe
				local hud = HudController.Parts()
				take(t, function(kit: Take)
					local moment = kit.Moment
					kit.Zero()
					moment(`zero: at home, the HUD; not played: {layout} tuned before the take`)
					t.Wait(1.5)
					moment("the dock's Voidkin tapped")
					t.Check("the dock opens it", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
						return Screen.Current() == VoidkinScreen.Name
					end))
					moment("the lead's screen: its figure on Idle, its power at its feet")
					t.Wait(TAKE_READ)
					moment(`not played: a drag, the figure turned {TAKE_SPIN.Degrees}° and back by its own Turn`)
					spin(TAKE_SPIN.Degrees, TAKE_SPIN.Seconds)
					t.Wait(0.6)
					spin(-TAKE_SPIN.Degrees, TAKE_SPIN.Seconds)
					moment("not played: a tap on the figure, the end of its Reveal")
					t.Check("a tap", gesture(Vector2.new(2, 1), swipe.TapTime / 2) == "Tap")
					t.Wait(2.2)
					for index = 2, 3 do
						moment(`the strip: Voidkin {index} tapped`)
						t.Check(`the strip's cell {index}`, press(ids[index]))
						t.Wait(TAKE_READ - 1)
					end
					moment("not played: a flick to the left, the next")
					t.Check("a flick left", gesture(Vector2.new(-(swipe.Distance + 60), 8), swipe.Time / 2) == "Swipe")
					t.Wait(2)
					moment("not played: a flick to the right, the one before")
					t.Check("a flick right", gesture(Vector2.new(swipe.Distance + 60, -6), swipe.Time / 2) == "Swipe")
					t.Wait(2)
					if layout == "Flank" then
						moment("Flank: the kit's Skill tapped, the panel slides in on Kit")
						t.Check("the kit's Skill", press("Skill"))
						t.Wait(TAKE_READ - 0.5)
					end
					for _, name in VoidkinScreen.Tabs do
						moment(`the {name} tab tapped`)
						local tabs = VoidkinScreen.Find("Tabs")
						local tab = tabs and tabs:FindFirstChild(name)
						t.Check(`the {name} tab`, tab ~= nil and tab:IsA("TextButton") and Button.Press(tab))
						t.Wait(TAKE_READ - 0.5)
					end
					if layout == "Flank" then
						moment("Flank: Hide, the panel slides out")
						t.Check("Hide", press("Hide"))
						t.Wait(1.5)
					end
					moment(`Lead: the strip's {free[1]}, then Lead`)
					press(free[1])
					t.Wait(1)
					t.Check("Lead", press("Lead") and waitFor(t, ANSWER, function(): boolean
						local now = ProfileController.Get()
						return now ~= nil and now.Roles.Lead == free[1]
					end))
					t.Wait(TAKE_READ)
					moment(`Send to work: the strip's {free[2]}, then Send to work`)
					press(free[2])
					t.Wait(1)
					t.Check("Send to work", press("Work") and waitFor(t, ANSWER, function(): boolean
						local now = ProfileController.Get()
						return now ~= nil and Read.Role(now, free[2]) == `Bay {bay}`
					end))
					t.Wait(TAKE_READ)
					moment("Close")
					Screen.Close()
					t.Wait(1.5)
					moment("end")
				end)
				t.Server("Act", "SetWorker", { Bay = bay, Voidkin = "" })
				t.Server("Act", "SetLead", { Voidkin = lead })
				t.Server("Tune", "Hud.Voidkin.Layout", was)
			end,
		}
	end

	return {
		voidkinTake("Stage"),
		voidkinTake("Flank"),
		voidkinTake("Rail"),
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
			Name = "Take: TR12, a fall, the next lead, Rook training at home and the walk home, for research's verdict",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- TR12's evidence (docs/test-requests.md, TR12): one circuit from the player's camera. Rook leads out of the
				-- Festival Door to Pack 1 and falls there; it leaves as light and heals at home, the card says so with its time,
				-- and "Send another" opens the Voidkin screen, where Ironhymn goes out. Rook, whole at home without the player,
				-- trains (its row says so), and the walk home through the door ends it. Two steps aren't played, and their rows
				-- say so: Rook's health held low from the fight's first moments (fallHeld), and Combat.Lead.Home.Fallen tuned to
				-- TAKE_HEAL for the take (90 s would hold it that long), put back after.
				local view = ProfileController.Get()
				local first, second = nil :: string?, nil :: string?
				for id, owned in (if view then view.Voidkin else {}) :: { [string]: any } do
					local role = Read.Role(view :: any, id)
					local free = role == "" or role == "Lead"
					if owned.Def == "rook" and free then
						first = first or id
					elseif owned.Def == "ironhymn" and free then
						second = second or id
					end
				end
				t.Check("Rook and Ironhymn owned", first ~= nil and second ~= nil)
				if first == nil or second == nil then
					return
				end
				local heal = Combat.Lead.Home.Fallen
				take(t, function(kit: Take)
					local player = Players.LocalPlayer
					local moment, walkTo = kit.Moment, kit.WalkTo
					local hud = HudController.Parts()
					local up = Vector3.new(0, R6_ROOT_HEIGHT, 0)
					local function standing(name: string): number
						for _, row in t.Server("Packs") do
							if row.Name == name then
								return row.Standing
							end
						end
						return 0
					end
					t.Server("LeadHeal")
					t.Check("Rook leads", t.Server("Act", "SetLead", { Voidkin = first }).Ok == true)
					t.Server("Tune", "Combat.Lead.Home.Fallen", TAKE_HEAL)
					local old = player.Character
					t.Server("Respawn")
					t.Check("the avatar arrives on its plot", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
						local character = player.Character
						local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
						return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
					end))
					t.Wait(WorldConfig.Arrive + 1)
					t.Check("Rook by the avatar", waitFor(t, 5, function(): boolean
						local lead = myLead()
						return lead ~= nil and lead:GetAttribute("Voidkin") == first
					end))
					kit.Zero()
					moment("zero: on the plot, Rook leading")
					t.Wait(2)
					local plot = player:GetAttribute("Plot")
					local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
					t.Check("the plot has its Festival Door", door ~= nil)
					if door == nil then
						return
					end
					moment("the walk to the Festival Door")
					walkTo(Markers.At(door).Position - Markers.At(door).LookVector * DOOR_RUN + up)
					t.Check("through it", walkThrough(t, door, false))
					moment("through the door: Lantern Row's gate")
					t.Wait(1)
					local pack: any = nil
					for _, row in t.Server("Packs") do
						if row.Name == "Pack 1" then
							pack = row
						end
					end
					t.Check("Pack 1 stands", pack ~= nil and pack.Standing > 0)
					if pack == nil then
						return
					end
					moment("the walk to Pack 1")
					t.Check("the avatar walks to Pack 1", walkTo(pack.At + up + Vector3.new(0, 0, PACK_STAND)))
					moment("at Pack 1: the fight")
					t.Wait(TAKE_BEFORE_FALL)
					moment(`not played: Rook's health held at {TAKE_LOW * 100}% or under from here`)
					local lead = myLead()
					t.Check("Rook falls", fallHeld(t, moment))
					moment("Rook is down: the card says so")
					t.Check("it leaves as light, home", waitFor(t, Combat.Lead.Leave + 1, function(): boolean
						return lead ~= nil and lead:GetAttribute("State") == "Home"
					end))
					moment(`Rook home, healing (not played: its heal tuned to {TAKE_HEAL} s)`)
					t.Wait(TAKE_READ)
					local nextButton = hud.Next :: TextButton
					t.Check("Send another shows", nextButton.Visible)
					t.Check("and opens the Voidkin screen", Button.Press(nextButton) and waitFor(t, 1, function(): boolean
						return Screen.Current() == VoidkinScreen.Name
					end))
					moment("the Voidkin screen: Rook healing")
					t.Wait(TAKE_READ)
					local out = leadButton(second :: string)
					t.Check("Ironhymn's Lead", out ~= nil and Button.Press(out))
					moment("Ironhymn goes out")
					t.Wait(1.5)
					Screen.Close()
					t.Check("Ironhymn by the avatar", waitFor(t, 5, function(): boolean
						local now = myLead()
						return now ~= nil and now:GetAttribute("Voidkin") == second and now:GetAttribute("State") ~= "Home"
					end))
					moment("Ironhymn fights on")
					t.Check("Pack 1 falls", waitFor(t, TAKE_FIGHT, function(): boolean
						return standing("Pack 1") == 0
					end))
					moment("Pack 1 down")
					t.Check("Rook, whole at home without the player, trains", waitFor(t, TAKE_HEAL + 10, function(): boolean
						return player:GetAttribute("Training") == first
					end), tostring(player:GetAttribute("Training")))
					moment("Rook trains at home")
					t.Check("the dock opens the Voidkin screen", Button.Press(hud.Voidkin :: TextButton) and waitFor(t, 1, function(): boolean
						return Screen.Current() == VoidkinScreen.Name
					end))
					moment("the Voidkin screen: Rook training")
					t.Wait(TAKE_READ)
					Screen.Close()
					local homeDoor = Markers.Find("GroundDoor", { Ground = WorldConfig.Row.Ground })
					t.Check("Lantern Row has its door home", homeDoor ~= nil)
					if homeDoor then
						moment("the walk back to the door home")
						walkTo(Markers.At(homeDoor).Position + Markers.At(homeDoor).LookVector * DOOR_RUN + up)
						t.Check("the avatar is home", walkThrough(t, homeDoor, false))
						moment("home through the door: the machine stops for the player")
					end
					t.Wait(6)
					moment("end")
				end)
				t.Server("Tune", "Combat.Lead.Home.Fallen", heal)
			end,
		},
		{
			Name = "Take: TR16, alone after a fall, the way home's chip and its trail walked to the door, for research's verdict",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- TR16's evidence (docs/test-requests.md, TR16), the extra take after TR12's, from the player's camera: on Lantern
				-- Row's street the lead walks up to a pack and falls there with no other Voidkin ready; the card says so, the
				-- "Go home" chip shows in the next lead's place, a tap draws the trail, the avatar walks it to the gate's door,
				-- where it's gone, and goes home through it. Three steps aren't played, and their rows say so: the set-down on the
				-- street, every other Voidkin fallen just before, and the lead's health set low.
				take(t, function(kit: Take)
					local moment, walkTo = kit.Moment, kit.WalkTo
					local home = HudController.Parts().Home :: TextButton
					local up = Vector3.new(0, R6_ROOT_HEIGHT, 0)
					t.Server("LeadHeal")
					local pack: any = nil
					for _, row in t.Server("Packs") do
						if row.Name == TAKE_ALONE.Pack then
							pack = row
						end
					end
					local marker = Markers.Find("GroundDoor", { Ground = WorldConfig.Row.Ground })
					t.Check(`{TAKE_ALONE.Pack} stands`, pack ~= nil and pack.Standing > 0)
					t.Check("Lantern Row has its door home", marker ~= nil)
					if pack == nil or marker == nil then
						return
					end
					local door = Markers.At(marker)
					local toward = Vector3.new(door.Position.X - pack.At.X, 0, door.Position.Z - pack.At.Z).Unit -- up the street to the gate
					local start = pack.At + toward * TAKE_ALONE.Short + up
					t.Root().CFrame = CFrame.lookAt(start, start - toward)
					RunService.RenderStepped:Wait()
					workspace.CurrentCamera.CFrame = CFrame.lookAt(start + toward * TAKE_ZOOM + Vector3.new(0, TAKE_ZOOM / 3, 0), start)
					t.Check("none other ready", t.Server("VoidkinFallen").Ok == true)
					t.Check("the lead by the avatar", waitFor(t, 5, function(): boolean
						local lead = myLead()
						local root = if lead then Parts.Root(lead) else nil
						return root ~= nil and (root.Position - start).Magnitude < 12
					end))
					t.Wait(LEAD_SETTLE)
					kit.Zero()
					moment("zero: the white frame")
					moment(`set down on the street short of {TAKE_ALONE.Pack}, every other Voidkin fallen (both set, not played)`)
					t.Wait(1)
					moment(`the walk up to {TAKE_ALONE.Pack}`)
					t.Check(`the avatar walks to {TAKE_ALONE.Pack}`, walkTo(pack.At + toward * PACK_STAND + up))
					moment("the fight")
					t.Wait(TAKE_BEFORE_FALL)
					moment(`not played: the lead's health held at {TAKE_LOW * 100}% or under from here`)
					local lead = myLead()
					t.Check("the lead falls", fallHeld(t, moment))
					moment("the lead is down: the card says so")
					t.Check("it leaves as light, home", waitFor(t, Combat.Lead.Leave + 1, function(): boolean
						return lead ~= nil and lead:GetAttribute("State") == "Home"
					end))
					t.Check("the Go home chip shows", waitFor(t, REPLICATE, function(): boolean
						return home.Visible
					end))
					moment("home, healing: the Go home chip")
					t.Wait(TAKE_READ)
					t.Check("a tap draws the trail", Button.Press(home) and waitFor(t, 1, WayHomeController.On))
					moment("a tap: the trail to the gate's door")
					t.Wait(TAKE_READ)
					-- Walked as drawn: its corners, then the door's step, where it's gone.
					local points = WayHomeController.Points()
					moment("the walk along the trail")
					for i = 2, #points - 1 do
						walkTo(points[i] + up)
					end
					walkTo(door.Position + door.LookVector * DOOR_RUN + up)
					t.Check("gone at the door", waitFor(t, 1, function(): boolean
						return not WayHomeController.On()
					end))
					moment("at the door: the trail gone")
					t.Wait(1)
					t.Check("the avatar is home", walkThrough(t, marker, false))
					moment("home through the door")
					t.Wait(6)
					moment("end")
				end)
				t.Server("LeadHeal")
			end,
		},
		{
			Name = "Take: TR8, Lantern Row dressed, up the street at dusk and back at night, for research's verdict",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- TR8's evidence (docs/test-requests.md, TR8): the dressed street from the player's camera, from the plot through
				-- the Festival Door, up the street to the elite's square at dusk, and back down to the gate at night, the lead at
				-- the avatar's side. Two steps aren't played, and their rows say so: the street's packs cleared before the walk
				-- (each fight would stop it), and the turn to night jumped (Config.Lighting.Cycle's own takes minutes).
				local cleared: { string } = {}
				take(t, function(kit: Take)
					local player = Players.LocalPlayer
					local moment, walkTo = kit.Moment, kit.WalkTo
					local up = Vector3.new(0, R6_ROOT_HEIGHT, 0)
					for _, row in t.Server("Packs") do
						if row.Standing > 0 and t.Server("PackDefeat", row.Name).Ok == true then
							table.insert(cleared, row.Name)
						end
					end
					t.Server("Night", "Dusk")
					local old = player.Character
					t.Server("Respawn")
					t.Check("the avatar arrives on its plot", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
						local character = player.Character
						local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
						return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
					end))
					t.Wait(WorldConfig.Arrive + 1)
					local plot = player:GetAttribute("Plot")
					local door = if type(plot) == "number" then Markers.Find("FestivalDoor", { Plot = plot }) else nil
					t.Check("the plot has its Festival Door", door ~= nil)
					if door == nil then
						return
					end
					kit.Zero()
					moment("zero: on the plot, at dusk")
					moment(`not played: the street's packs cleared ({#cleared}), so the walk never stops for a fight`)
					t.Wait(1)
					moment("the walk to the Festival Door")
					walkTo(Markers.At(door).Position - Markers.At(door).LookVector * DOOR_RUN + up)
					t.Check("through it", walkThrough(t, door, false))
					moment("through the door: Lantern Row's gate at dusk")
					-- The camera's highest over the paving from here on, against the paper's floor (research's verdict).
					local floorY: number? = nil
					for _, item in CollectionService:GetTagged(Kit.Tag) do
						local y = item:GetAttribute("FloorY")
						if type(y) == "number" then
							floorY = y
							break
						end
					end
					local highest = -math.huge
					local camera = RunService.RenderStepped:Connect(function()
						if floorY then
							highest = math.max(highest, workspace.CurrentCamera.CFrame.Position.Y - floorY)
						end
					end)
					t.Wait(2)
					local elite = streamed(t, "Elite")
					t.Check("the elite's square", elite ~= nil)
					if elite == nil then
						camera:Disconnect()
						return
					end
					local square = Markers.At(elite).Position
					moment("the walk up the street")
					t.Check("the avatar walks up to the elite's square", walkTo(square + up))
					moment("the elite's square at dusk")
					t.Wait(TAKE_READ)
					t.Server("Night", "Night")
					moment("not played: the turn to night jumped")
					t.Wait(TAKE_READ + 1)
					local marker = Markers.Find("GroundDoor", { Ground = WorldConfig.Row.Ground })
					t.Check("Lantern Row has its door home", marker ~= nil)
					if marker == nil then
						camera:Disconnect()
						return
					end
					local home = Markers.At(marker)
					moment("the walk back down the street at night")
					t.Check("the avatar walks back to the gate", walkTo(home.Position + home.LookVector * (DOOR_RUN + TAKE_GATE_SHORT) + up))
					moment("the gate at night")
					t.Wait(TAKE_READ + 1)
					moment("end")
					camera:Disconnect()
					t.Check("the camera rides under the paper's floor", floorY ~= nil and highest < LightingConfig.Paper.Floor,
						`highest {string.format("%.2f", highest)} over the paving, the paper from {LightingConfig.Paper.Floor}`)
				end)
				for _, name in cleared do
					t.Server("PackBack", name)
				end
			end,
		},
		{
			Name = "Take: TR9, the Breaker's three layouts at home with shards breaking, for research's verdict",
			Manual = true,
			Stay = true,
			Run = function(t: any)
				-- TR9's evidence (docs/test-requests.md, TR9): the Breaker's screen in grey from the player's camera, at home, its
				-- prompt tapped after a walk, its chambers cracking with their time left and a line waiting. In Machine a chamber
				-- tapped and a shard in the line infused a little; in List a row's odds; in Sheet a chamber's odds over the
				-- machine and Back. Not played, and their rows say so: the shards and the full battery given before the walk,
				-- the Breaker's ready shards opened first (its prompt would open them), and each switch of layout (a Tune on the
				-- open screen, as the blockout's verdict takes them side by side).
				local view = ProfileController.Get()
				t.Check("the first shard is chosen", view ~= nil and view.Progress.Starter ~= "")
				if view == nil or view.Progress.Starter == "" then
					return
				end
				local shard = "lanternrow_standard"
				local layout = HudConfig.Breaker.Layout
				local battery = view.Base.Battery
				local held = view.Bag.Shards[shard] or 0
				local before = readyCount(shard)
				-- Nothing ready, so the prompt opens the screen.
				local readyDefs: { [string]: boolean } = {}
				for _, work in view.Base.Ready do
					readyDefs[work.Def] = true
				end
				for def in readyDefs do
					openReadyDown(t, def, 0)
				end
				before = readyCount(shard)
				-- Every chamber filled, two in the line and one left in the bag.
				local open = #(ProfileController.Get() :: Profile.View).Base.Chambers
				local busy = 0
				for _, chamber in (ProfileController.Get() :: Profile.View).Base.Chambers do
					busy += if chamber.Work then 1 else 0
				end
				local feed = open - busy + 2
				t.Server("BaseGive", shard, feed + 1)
				t.Check("the server gives the take's shards", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and (now.Bag.Shards[shard] or 0) == held + feed + 1
				end))
				for _ = 1, feed do
					ProfileController.Act("AddShard", { Shard = shard })
				end
				t.Check("the chambers full and two in the line", waitFor(t, ANSWER, function(): boolean
					local now = ProfileController.Get()
					return now ~= nil and #now.Base.Line >= 2 and (now.Bag.Shards[shard] or 0) == held + 1
				end))
				t.Server("BaseSkip", ShardConfig.Grades.Standard.BreakSeconds * 0.4) -- cracked partway, each with its time left
				t.Server("BaseBattery", BaseConfig.Battery.Capacity)
				t.Server("Tune", "Hud.Breaker.Layout", "Machine")
				Screen.Close()
				local player = Players.LocalPlayer
				local old = player.Character
				t.Server("Respawn")
				t.Check("the avatar arrives on its plot, facing the Breaker", waitFor(t, ARRIVE_TIMEOUT, function(): boolean
					local character = player.Character
					local humanoid = if character and character ~= old then Parts.Humanoid(character) else nil
					return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
				end))
				t.Wait(WorldConfig.Arrive + 1)
				local prompt = BaseController.Parts().BreakerPrompt :: ProximityPrompt?
				local anchor = prompt and prompt.Parent
				t.Check("the Breaker has its prompt", anchor ~= nil and anchor:IsA("BasePart"))
				if prompt == nil or anchor == nil or not anchor:IsA("BasePart") then
					return
				end
				take(t, function(kit: Take)
					local moment = kit.Moment
					kit.Zero()
					moment("zero: at home, the Breaker ahead, its chambers cracking")
					moment("not played: the shards, the full battery and the opened ready shards given before the walk")
					local here = t.Root().Position
					local toward = Vector3.new(anchor.Position.X - here.X, 0, anchor.Position.Z - here.Z)
					local stand = anchor.Position - toward.Unit * 6
					moment("the walk to the Breaker")
					kit.WalkTo(Vector3.new(stand.X, here.Y, stand.Z))
					t.Wait(0.6)
					moment("the prompt tapped: the Breaker in Machine")
					prompt:InputHoldBegin()
					prompt:InputHoldEnd()
					t.Check("Machine opens on its prompt", waitFor(t, 2, function(): boolean
						return Screen.Current() == BreakerScreen.Name and breakerPart("Machine") ~= nil
					end))
					t.Wait(TAKE_READ)
					local now = ProfileController.Get() :: Profile.View
					if now.Base.Chambers[2] and now.Base.Chambers[2].Work then
						moment("Machine: chamber 2 tapped, its odds")
						BreakerScreen.Select({ Kind = "Chamber", Index = 2, Def = shard })
						t.Wait(2)
					end
					moment("Machine: the line's first shard tapped, its odds and infusion's two levels")
					BreakerScreen.Select({ Kind = "Line", Index = 1, Def = shard })
					t.Wait(2.5)
					-- The battery also feeds the breaking chambers, so the shard's own lift is what's read.
					local little, locked = infuseButton(1)
					moment("Machine: infused a little, its price spent and the rarest tier lifted")
					t.Check("a little can be pressed", little ~= nil and not locked)
					t.Check("a little infused", little ~= nil and Button.Press(little) and waitFor(t, ANSWER, function(): boolean
						local work = chosenWork(BreakerScreen.Selected())
						return work ~= nil and work.Luck > 0
					end), (function(): string
						local item = BreakerScreen.Selected()
						return if item then `{item.Kind} {item.Index}` else "nothing chosen"
					end)())
					t.Wait(TAKE_READ)
					moment("not played: the layout switched to List on the open screen")
					t.Server("Tune", "Hud.Breaker.Layout", "List")
					t.Check("List built", waitFor(t, 2, function(): boolean
						return breakerPart("Shards") ~= nil
					end))
					t.Wait(TAKE_READ)
					local bag = bagItem(shard)
					local odds = bag and screenButton(BreakerScreen.Name, "Shards", `Bag{bag.Index}`)
					moment("List: the bag's shard, its row's Odds tapped")
					t.Check("its odds chosen", odds ~= nil and Button.Press(odds) and waitFor(t, 1, function(): boolean
						local item = BreakerScreen.Selected()
						return item ~= nil and item.Kind == "Bag"
					end))
					t.Wait(TAKE_READ)
					moment("not played: the layout switched to Sheet, the choice cleared as a fresh screen")
					t.Server("Tune", "Hud.Breaker.Layout", "Sheet")
					t.Check("Sheet built", waitFor(t, 2, function(): boolean
						return breakerPart("Chambers") ~= nil and breakerPart("Machine") == nil
					end))
					BreakerScreen.Select(nil)
					t.Wait(TAKE_READ)
					moment("Sheet: chamber 1 tapped, its odds a sheet over the machine")
					BreakerScreen.Select({ Kind = "Chamber", Index = 1, Def = shard })
					t.Check("the sheet over the machine", waitFor(t, 1, function(): boolean
						return breakerPart("Odds") ~= nil
					end))
					t.Wait(TAKE_READ)
					local back = breakerPart("Back")
					moment("Sheet: Back, the machine again")
					t.Check("Back takes the sheet away", back ~= nil and back:IsA("TextButton") and Button.Press(back) and waitFor(t, 1, function(): boolean
						return breakerPart("Odds") == nil
					end))
					t.Wait(2)
					local frame = Screen.Frame(BreakerScreen.Name)
					local close = frame and frame:FindFirstChild("Close", true)
					moment("Close")
					t.Check("Close shuts it", close ~= nil and close:IsA("TextButton") and Button.Press(close) and waitFor(t, 1, function(): boolean
						return Screen.Current() == nil
					end))
					t.Wait(1.5)
					moment("end")
				end)
				-- As it found it: the layout, the battery, the bag's extra shard back, the rest broken and opened.
				t.Server("Tune", "Hud.Breaker.Layout", layout)
				Screen.Close()
				if ((ProfileController.Get() :: Profile.View).Bag.Shards[shard] or 0) > held then
					t.Server("BaseGive", shard, -1)
				end
				t.Server("BaseSkip", SKIP_ALL)
				waitFor(t, ANSWER, function(): boolean
					return readyCount(shard) > before
				end)
				openReadyDown(t, shard, before)
				t.Server("BaseBattery", battery)
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
					t.Server("KeeperRest", 0) -- TR10: a win earlier in the run hides the Challenge five minutes
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
	}
end
