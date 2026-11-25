--!strict
-- SelfTestService (server, Studio only): the server half of the self-test: a test pad far above the map, a dummy once the
-- game has one, and script errors on the server. The game's own Test* commands join here (scripted hits, enemies).
-- Clients call these through the Studio-only DebugCommand remote (the player goes first); the MCP bridge can too.
-- The dummy needs a Shared.Assets.TrainingDummy model and MakeEntity wired to the game's spawner; until then the pad has none.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")

local Shared = ReplicatedStorage.Shared
local Animations = require(Shared.Config.Animations)
local Parts = require(Shared.Util.Parts)
local Markers = require(Shared.World.Markers)
local DebugService = require(script.Parent.DebugService)

local PAD_NAME = "NL_TestPad"
local PAD_CENTER = CFrame.new(0, 3000, 0) -- far above any map
local PAD_SIZE = Vector3.new(300, 4, 300)
local STAND_HEIGHT = 3 -- root height above the floor
local DUMMY_DISTANCE = 8 -- studs in front of the player
local DUMMY_HEALTH = 1e6 -- never dies during a run; tests read the HP it loses

local SelfTestService = {}

-- Seam: spawn a body from `template`, named `name`, at `placed`, with `health`, under `parent`, and return it.
function SelfTestService.MakeEntity(_template: Model, _name: string, _placed: CFrame, _health: number, _parent: Instance): Model
	error("wire SelfTestService.MakeEntity to the game's spawner")
end

-- Seam: the per-case resets your game needs (stamina, cooldowns, meters, ammo, level). A carried-over value fails the next case.
function SelfTestService.ResetBody(_player: Player, _character: Model) end

local returnTo: { [Player]: CFrame } = {}

local function floorTop(): number
	return PAD_CENTER.Position.Y + PAD_SIZE.Y / 2
end

local function buildPad(): Folder
	local pad = Instance.new("Folder")
	pad.Name = PAD_NAME
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = PAD_SIZE
	floor.CFrame = PAD_CENTER
	floor.Material = Enum.Material.Slate
	floor.Parent = pad
	pad.Parent = workspace
	return pad
end

local function standAt(offset: Vector3): Vector3
	return Vector3.new(PAD_CENTER.X, floorTop() + STAND_HEIGHT, PAD_CENTER.Z) + offset
end

-- The pad's dummy, rebuilt at full health, `distance` studs in front of the player's spot, turned `turn` degrees from facing `facing`.
local function freshDummy(pad: Instance, facing: Vector3, distance: number?, turn: number?): Model?
	local assets = Shared:FindFirstChild("Assets")
	local template = if assets then assets:FindFirstChild("TrainingDummy") :: Model? else nil
	local old = pad:FindFirstChild("Dummy")
	if old then
		old:Destroy()
	end
	if not template then
		return nil
	end
	local position = standAt(Vector3.new(0, 0, -(distance or DUMMY_DISTANCE)))
	local placed = CFrame.lookAt(position, facing) * CFrame.Angles(0, math.rad(turn or 0), 0)
	return SelfTestService.MakeEntity(template, "Dummy", placed, DUMMY_HEALTH, pad)
end

local function characterOf(who: any): (Player, Model, BasePart)
	local player = assert(DebugService.ResolvePlayer(who), "no such player")
	local character = assert(player.Character, "player has no character")
	local root = assert(Parts.Root(character), "character has no root")
	return player, character, root
end

local function testPad(who: any): string?
	local player, character, root = characterOf(who)
	local pad = workspace:FindFirstChild(PAD_NAME) or buildPad()
	local spot = standAt(Vector3.zero)
	if not returnTo[player] then
		returnTo[player] = root.CFrame
	end
	player:RequestStreamAroundAsync(spot)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(spot, spot + Vector3.new(0, 0, -1))
	SelfTestService.ResetBody(player, character)
	local dummy = freshDummy(pad, spot)
	return dummy and dummy.Name
end

-- Removes the pad and puts the player back where they were.
local function testPadClear(who: any): boolean
	local player, _, root = characterOf(who)
	local pad = workspace:FindFirstChild(PAD_NAME)
	if pad then
		pad:Destroy()
	end
	local back = returnTo[player]
	returnTo[player] = nil
	if back then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = back
	end
	return true
end

-- A clip's shape, to compare a published clip with the one saved: its keyframes, its length, its markers, its poses.
local function clipShape(sequence: KeyframeSequence): (number, number, string, number)
	local last, marks, sum = 0, {}, 0
	local frames = sequence:GetKeyframes()
	for _, frame in frames do
		local keyframe = frame :: Keyframe
		last = math.max(last, keyframe.Time)
		for _, marker in keyframe:GetMarkers() do
			table.insert(marks, `{marker.Name}@{string.format("%.3f", keyframe.Time)}`)
		end
		for _, pose in keyframe:GetDescendants() do
			if pose:IsA("Pose") then
				local cf = pose.CFrame
				sum += cf.Position.X + cf.Position.Y + cf.Position.Z + cf.XVector.X + cf.YVector.Y + cf.ZVector.Z + pose.Weight
			end
		end
	end
	table.sort(marks)
	return #frames, last, table.concat(marks, ","), sum
end

-- A clip plays from its id in Studio too (FighterController/Clips), so one baked again after its publish shows nowhere
-- until it's published again. Each published clip (Config.Animations.Ids), read back, against the one saved in the place
-- (RBX_ANIMSAVES.R6, tools/studio/Animations/Author.luau). About 0.4 s a read, so all at once, up to CLIPS_WAIT.
local CLIPS_WAIT = 30
local function testClips(): { Count: number, Read: number, Stale: { string } }
	local saves = game:GetService("ServerStorage"):FindFirstChild("RBX_ANIMSAVES")
	local saved = if saves then saves:FindFirstChild("R6") else nil
	local provider = game:GetService("KeyframeSequenceProvider")
	local stale: { string } = {}
	local count, read = 0, 0
	local function compare(clip: string, id: number)
		local own = if saved then saved:FindFirstChild("NL_" .. clip) else nil
		local ok, published = pcall(function(): KeyframeSequence
			return provider:GetKeyframeSequenceAsync(`rbxassetid://{id}`) :: KeyframeSequence
		end)
		if own == nil or not own:IsA("KeyframeSequence") then
			table.insert(stale, `{clip}: not saved in the place`)
		elseif not ok then
			table.insert(stale, `{clip}: its id {id} didn't read back ({tostring(published)})`)
		else
			local frames, last, marks, sum = clipShape(own)
			local frames2, last2, marks2, sum2 = clipShape(published)
			if frames ~= frames2 or math.abs(last - last2) > 1e-3 or marks ~= marks2 or math.abs(sum - sum2) > 1e-2 then
				local markers = if marks ~= marks2 then ", its markers differ" else ""
				local poses = if math.abs(sum - sum2) > 1e-2 then ", its poses differ" else ""
				table.insert(stale, `{clip}: saved {frames} keys, {last} s; published {frames2} keys, {last2} s{markers}{poses}`)
			end
		end
		read += 1
	end
	for clip, id in Animations.Ids do
		count += 1
		task.spawn(compare, clip, id)
	end
	local started = os.clock()
	while read < count and os.clock() - started < CLIPS_WAIT do
		task.wait(0.1)
	end
	table.sort(stale)
	return { Count = count, Read = read, Stale = stale }
end

function SelfTestService.Init()
	if not RunService:IsStudio() then
		return
	end
	DebugService.Register("TestClips", testClips)
	DebugService.Register("TestPad", testPad)
	DebugService.Register("TestPadClear", testPadClear)
	DebugService.Register("TestDummyAt", function(_who: any, distance: any, turn: any)
		local pad = workspace:FindFirstChild(PAD_NAME)
		local dummy = pad and freshDummy(pad, standAt(Vector3.zero), tonumber(distance), tonumber(turn))
		return dummy and dummy.Name
	end)
	-- The avatar's root set down at `at` (a world position), looking toward `look` along the ground: a spot on the map
	-- for a case that needs one (the plot's plates, near and far).
	DebugService.Register("TestStandAt", function(who: any, at: any, look: any): boolean
		local player, _, root = characterOf(who)
		assert(typeof(at) == "Vector3", "at: a Vector3")
		player:RequestStreamAroundAsync(at)
		local toward = if typeof(look) == "Vector3" then Vector3.new(look.X, at.Y, look.Z) else at + Vector3.new(0, 0, -1)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(at, if (toward - at).Magnitude > 1e-3 then toward else at + Vector3.new(0, 0, -1))
		return true
	end)
	-- A far marker streamed in to the player while the avatar stays where it is: the live `name` marker whose attributes
	-- match `where`, found here (a client on the test pad may not have it), and the place streamed round it. Its
	-- position, or nil.
	DebugService.Register("TestStream", function(who: any, name: any, where: any): Vector3?
		local player = assert(DebugService.ResolvePlayer(who), "no such player")
		local marker = Markers.Find(tostring(name), if type(where) == "table" then where else nil)
		if marker == nil then
			return nil
		end
		local at = Markers.At(marker).Position
		player:RequestStreamAroundAsync(at)
		return at
	end)
end

function SelfTestService.Start()
	if not RunService:IsStudio() then
		return
	end
	-- Script errors on the server since the self-test began (TestErrorsClear / TestErrors): a run fails on any.
	local errors: { string } = {}
	ScriptContext.Error:Connect(function(message: string, _trace: string, origin: Instance?)
		if origin and origin:IsDescendantOf(game) then -- the game's own scripts, not Studio plugins
			table.insert(errors, `{message} ({origin:GetFullName()})`)
		end
	end)
	DebugService.Register("TestErrorsClear", function()
		table.clear(errors)
		return true
	end)
	DebugService.Register("TestErrors", function()
		return table.clone(errors)
	end)
end

return SelfTestService
