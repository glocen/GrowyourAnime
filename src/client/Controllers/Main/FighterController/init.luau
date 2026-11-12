--!strict
-- FighterController (client): draws every fighter the server runs (FightService). It plays each fighter's clips on the
-- server's action clock, holds both bodies on a hit (hitstop), and runs each action's effect on its beat names. It
-- presents only: health, hits and every choice are the server's.
-- A hit is shown on the frame its beat comes on screen, when the target stands in reach there: the hold, the spark and the
-- camera. The server's Hit event brings the number, and the hold and spark too if the screen didn't see it coming.
-- A late action starts from its first frame and catches up (handbook/feel/combat.md, "Hit confirmation").
-- Children: Clips (an Animation per clip name), Effects (the stand-ins).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Actions = require(Shared.Definitions.Actions)
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local Fight = require(Shared.Rules.Fight)
local Clips = require(script.Clips)
local Theme = require(script.Parent.Parent.Parent.UI.Theme)
local Effects = require(script.Effects)

local player = Players.LocalPlayer

-- The late start's catch-up (handbook/feel/combat.md, "Hit confirmation"): own pace first, then faster until in step.
local CATCH = { OwnPace = 0.08, Over = 0.12, Limit = 0.25 }
local BURST_MARKER = "Burst" -- AR2's Burst clip: the body hides here and the effect takes over
local WALK_SMOOTHING = 10 -- a second's share the walk's speed follows the body by: about a tenth of a second

-- The effects that hang on an action's beats, by its id. A landed hit's spark is every action's.
local EFFECTS: { [string]: (beats: { [string]: number }, attacker: Model, target: () -> BasePart?) -> Effects.Running } = {
	RookHaymaker = Effects.Haymaker,
}

type Running = { Effect: Effects.Running, Clock: number }

type View = {
	Model: Model,
	Id: string,
	Rig: string,
	Root: BasePart,
	Animator: Animator?,
	Tracks: { [string]: { AnimationTrack } }, -- two per clip, so a clip can cross into itself
	Flip: { [string]: number },
	Mirrored: { [string]: boolean }, -- which side a clip with a mirror played last
	Idle: AnimationTrack?,
	Walk: AnimationTrack?, -- a rig's walk, at the body's own speed
	Last: Vector3, -- the root's last position, for that speed
	Speed: number, -- studs a second over the ground, smoothed
	Chest: Attachment?, -- where a hit lands, on a rig that marks it
	Collar: Attachment?, -- where a Shade's burst starts
	Current: AnimationTrack?, -- the action's
	Reaction: AnimationTrack?, -- Hit, Down or Up
	Action: Actions.Action?,
	ActionAt: number,
	Clock: number,
	Begun: number, -- os.clock() when the action began on screen
	Late: number, -- how late it began, caught up after OwnPace
	Rate: number,
	FrozenUntil: number,
	Shown: { [string]: boolean }, -- the hits this screen has shown, by beat and press
	Running: { Running },
	Joint: Motor6D?, -- a box's lean
	Height: number,
	FlinchAt: number?,
	State: string,
	Connections: { RBXScriptConnection },
}

local views: { [Model]: View } = {}
local byId: { [string]: View } = {}

local FighterController = {}
FighterController.Views = views -- for the self-test

local function track(view: View, clip: string): AnimationTrack?
	local animator = view.Animator
	if animator == nil then
		return nil
	end
	local pair = view.Tracks[clip]
	if pair == nil then
		local animation = Clips.Animation(clip)
		if animation == nil then
			return nil
		end
		pair = { animator:LoadAnimation(animation), animator:LoadAnimation(animation) }
		view.Tracks[clip] = pair
		view.Flip[clip] = 1
	end
	local index = 3 - (view.Flip[clip] or 1)
	view.Flip[clip] = index
	return pair[index]
end

-- A clip and its mirror in turn (Config.Animations.Mirrors), each body starting on a side of its own, so a pack doesn't
-- move in step.
local function pick(view: View, clip: string): string
	local mirror = Animations.Mirrors[clip]
	if mirror == nil then
		return clip
	end
	local last = view.Mirrored[clip]
	local now = if last == nil then math.random() < 0.5 else not last
	view.Mirrored[clip] = now
	return if now then mirror else clip
end

local function setRate(view: View, rate: number)
	if view.Rate == rate then
		return
	end
	view.Rate = rate
	for _, t in { view.Current, view.Reaction, view.Idle } do
		if t and t.IsPlaying then
			t:AdjustSpeed(rate)
		end
	end
end

local function stopCurrent(view: View)
	local current = view.Current
	if current then
		local clip = (view.Action and view.Action.Clip) or ""
		local _, out = Clips.Fades(clip)
		current:Stop(out)
		view.Current = nil
	end
end

local function freeze(view: View?, hold: number)
	if view == nil or hold <= 0 then
		return
	end
	local untilTime = os.clock() + hold
	if untilTime > view.FrozenUntil then
		-- one hold at a time: a hit inside a hold doesn't stack on it
		if os.clock() >= view.FrozenUntil then
			view.FrozenUntil = untilTime
		end
	end
end

local function chest(view: View): Vector3
	if view.Chest then
		return view.Chest.WorldPosition
	end
	return view.Root.Position + Vector3.new(0, if view.Rig == "R6" then 0.6 else view.Height * 0.15, 0)
end

local function isMine(view: View?): boolean
	return view ~= nil and view.Model:GetAttribute("Owner") == player.UserId
end

-- The replay's freeze (Config.Combat.Replay.FreezeAt): the moment the player's own lead stops at in a replayed press, or nil.
local function freezeOf(view: View): number?
	local at = Combat.Replay.FreezeAt
	local replay = player:GetAttribute("Replay")
	if at > 0 and view.Action and type(replay) == "string" and replay ~= "" and isMine(view) then
		return at
	end
	return nil
end

-- A hit's moment on screen: both bodies held, a spark where it lands, the camera on the player's own heavy hit.
local function show(attacker: View, target: View?, heavy: boolean, key: string)
	if attacker.Shown[key] then
		return
	end
	attacker.Shown[key] = true
	local hold = if heavy then Combat.Hitstop.Heavy else Combat.Hitstop.Light
	freeze(attacker, hold)
	freeze(target, hold)
	if target then
		local at = chest(target)
		local from = attacker.Root.Position
		local toward = Vector3.new(from.X - at.X, 0, from.Z - at.Z)
		local surface = if toward.Magnitude > 0.01 then at + toward.Unit * (if target.Rig == "Box" then target.Root.Size.Z / 2 else 0.6) else at
		Effects.Spark(surface, from, heavy)
	end
	if heavy and isMine(attacker) then
		Effects.Shake(Combat.Shake.Heavy)
	end
end

local function targetOf(view: View): View?
	local id = view.Model:GetAttribute("Target")
	return if type(id) == "string" and id ~= "" then byId[id] else nil
end

local function beginAction(view: View, action: Actions.Action, at: number)
	stopCurrent(view)
	view.Action = action
	view.ActionAt = at
	view.Shown = {}
	view.Begun = os.clock()
	local late = math.max(0, workspace:GetServerTimeNow() - at)
	if late > CATCH.Limit then
		view.Clock, view.Late = late, 0 -- too late to catch up without cutting a short clip's end: in step
	else
		view.Clock, view.Late = 0, late
	end
	view.Rate = 1
	local clip = action.Clip
	if clip then
		local t = track(view, pick(view, clip))
		if t then
			local fadeIn = Clips.Fades(clip)
			t.Priority = Enum.AnimationPriority.Action
			t.Looped = false
			t:Play(fadeIn, 1, 1)
			t.TimePosition = view.Clock
			view.Current = t
		end
	end
	local make = EFFECTS[action.Id]
	if make then
		local effect = make(action.Beats, view.Model, function(): BasePart?
			local target = targetOf(view)
			return if target then target.Root else nil
		end)
		table.insert(view.Running, { Effect = effect, Clock = view.Clock })
	end
end

local function endAction(view: View)
	stopCurrent(view)
	view.Action = nil
end

local function playReaction(view: View, role: string): AnimationTrack?
	local rig = Animations.Rigs[view.Rig]
	local clip = if rig then rig[role] else nil
	if clip == nil then
		return nil
	end
	if view.Reaction then
		view.Reaction:Stop(0.05)
	end
	local chosen = pick(view, clip)
	local t = track(view, chosen)
	if t then
		local fadeIn = Clips.Fades(chosen)
		t.Priority = Enum.AnimationPriority.Action2
		t.Looped = false
		t:Play(fadeIn, 1, 1)
		view.Reaction = t
	end
	return t
end

-- A Shade bursts into light and paper on its Down clip's `Burst` marker (AR2: the whole body hides on that frame and the
-- effect starts from the collar), or at once when it has no clip.
local function burst(view: View, down: AnimationTrack?)
	local function go()
		Effects.Burst(view.Model, if view.Collar then view.Collar.WorldCFrame else nil)
	end
	if down == nil then
		go()
		return
	end
	local connection: RBXScriptConnection
	connection = down:GetMarkerReachedSignal(BURST_MARKER):Connect(function()
		connection:Disconnect()
		go()
	end)
	table.insert(view.Connections, connection)
end

local function onState(view: View)
	local state = view.Model:GetAttribute("State")
	if type(state) ~= "string" or state == view.State then
		return
	end
	local was = view.State
	view.State = state
	if state == "Flinch" then
		local wait = math.max(0, view.FrozenUntil - os.clock())
		if Animations.Rigs[view.Rig] then
			task.delay(wait, function()
				if view.State == "Flinch" then
					playReaction(view, "Hit")
				end
			end)
		else
			view.FlinchAt = os.clock() + wait
		end
	elseif state == "Down" then
		endAction(view)
		for _, running in view.Running do
			running.Effect.Destroy()
		end
		table.clear(view.Running)
		local down = playReaction(view, "Down")
		if view.Model:GetAttribute("Side") == "Shade" then
			burst(view, down)
		end
	elseif state == "Idle" and was == "Down" and view.Rig == "R6" then
		playReaction(view, "Up")
	end
end

local function onAction(view: View)
	local id = view.Model:GetAttribute("Action")
	local at = view.Model:GetAttribute("ActionAt")
	if type(id) ~= "string" or type(at) ~= "number" then
		return
	end
	local action = Actions.ById[id]
	if action then
		beginAction(view, action, at)
	elseif freezeOf(view) == nil then -- a frozen replay holds its frame past the server's end, until the next press
		endAction(view)
	end
end

local function add(model: Instance)
	if not model:IsA("Model") or views[model] then
		return
	end
	local root = model:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid", 10)
	if root == nil or humanoid == nil or model.Parent == nil then
		return
	end
	local rig = model:GetAttribute("Rig")
	local id = model:GetAttribute("Fighter")
	local body = model:FindFirstChild("Body") :: BasePart?
	local view: View = {
		Model = model,
		Id = if type(id) == "string" then id else "",
		Rig = if type(rig) == "string" then rig else "Box",
		Root = root,
		Animator = (humanoid :: Humanoid):FindFirstChildOfClass("Animator") or (humanoid :: Humanoid):WaitForChild("Animator", 5) :: Animator?,
		Tracks = {},
		Flip = {},
		Mirrored = {},
		Idle = nil,
		Walk = nil,
		Last = root.Position,
		Speed = 0,
		Chest = model:FindFirstChild("Chest", true) :: Attachment?,
		Collar = model:FindFirstChild("Collar", true) :: Attachment?,
		Current = nil,
		Reaction = nil,
		Action = nil,
		ActionAt = 0,
		Clock = 0,
		Begun = 0,
		Late = 0,
		Rate = 1,
		FrozenUntil = 0,
		Shown = {},
		Running = {},
		Joint = root:FindFirstChild("Body") :: Motor6D?,
		Height = if body then body.Size.Y else root.Size.Y,
		FlinchAt = nil,
		State = "Idle",
		Connections = {},
	}
	views[model] = view
	byId[view.Id] = view
	local reactions = Animations.Rigs[view.Rig]
	local idleClip = if reactions then reactions.Idle else nil
	if idleClip then
		local idle = track(view, idleClip)
		if idle then
			idle.Priority = Enum.AnimationPriority.Idle
			idle.Looped = true
			local fadeIn = Clips.Fades(idleClip)
			idle:Play(fadeIn, 1, 1)
			view.Idle = idle
		end
	end
	table.insert(view.Connections, model:GetAttributeChangedSignal("ActionAt"):Connect(function()
		onAction(view)
	end))
	table.insert(view.Connections, model:GetAttributeChangedSignal("State"):Connect(function()
		onState(view)
	end))
	local level = model:GetAttribute("Level")
	table.insert(view.Connections, model:GetAttributeChangedSignal("Level"):Connect(function()
		local now = model:GetAttribute("Level")
		if isMine(view) and type(now) == "number" and type(level) == "number" and now > level then
			Effects.LevelUp(view.Root, now)
		end
		level = now
	end))
	onState(view)
	onAction(view)
end

local function remove(model: Instance)
	local view = views[model :: Model]
	if view == nil then
		return
	end
	views[model :: Model] = nil
	if byId[view.Id] == view then
		byId[view.Id] = nil
	end
	for _, connection in view.Connections do
		connection:Disconnect()
	end
	for _, running in view.Running do
		running.Effect.Destroy()
	end
end

-- The rate the action's clock runs at this frame: 0 in a hold, faster while catching up a late start.
local function rateOf(view: View, now: number): number
	if now < view.FrozenUntil then
		return 0
	end
	local since = now - view.Begun
	if view.Late > 0 and since >= CATCH.OwnPace and since < CATCH.OwnPace + CATCH.Over then
		return 1 + view.Late / CATCH.Over
	end
	return 1
end

-- One frame of a fighter on screen. True while the replay's freeze holds it.
local function stepView(view: View, dt: number, now: number): boolean
	local rate = rateOf(view, now)
	local step = dt * rate
	local freezeAt = freezeOf(view)
	local frozen = freezeAt ~= nil and view.Clock + step >= freezeAt
	if frozen then
		step, rate = math.max(0, (freezeAt :: number) - view.Clock), 0
	end
	setRate(view, rate)
	local action = view.Action
	if action then
		local before = view.Clock
		view.Clock += step
		for _, beat in Fight.BeatsBetween(action, before, view.Clock) do
			local hit = action.Hits[beat]
			local target = targetOf(view)
			if hit and target and target.State ~= "Down" then
				local line = Vector3.new(target.Root.Position.X - view.Root.Position.X, 0, target.Root.Position.Z - view.Root.Position.Z)
				local look = view.Root.CFrame.LookVector
				local facing = Vector3.new(look.X, 0, look.Z)
				local cosine = if line.Magnitude > 0.01 and facing.Magnitude > 0.01 then facing.Unit:Dot(line.Unit) else 1
				if Fight.Reaches(line.Magnitude, cosine, hit.Reach, Combat.Arc) then
					show(view, target, hit.Heavy, `{beat}@{view.ActionAt}`)
				end
			end
		end
		-- Keep the clip on the clock the hits are timed by; a replay's freeze puts it exactly there, or the pose sits
		-- up to the drift's 0.05 s short of the effect it's captured with.
		if view.Current and (frozen or math.abs(view.Current.TimePosition - view.Clock) > 0.05) and view.Clock < action.Length then
			view.Current.TimePosition = view.Clock
		end
		if view.Clock >= action.Length then
			endAction(view)
		end
	end
	for index = #view.Running, 1, -1 do
		local running = view.Running[index]
		running.Clock += step
		if not running.Effect.Step(running.Clock) then
			table.remove(view.Running, index)
		end
	end
	-- A box's stand-in motion.
	local joint = view.Joint
	if joint then
		if view.Action then
			joint.C0 = Effects.BoxPose((view.Action :: Actions.Action).Beats, view.Clock, view.Height)
		elseif view.FlinchAt and now >= view.FlinchAt and now < view.FlinchAt + Combat.Flinch.Seconds then
			joint.C0 = Effects.BoxFlinch(now - view.FlinchAt, Combat.Flinch.Seconds, view.Height)
		else
			joint.C0 = CFrame.identity
		end
	end
	-- A rig's walk, at the body's own ground speed over the clip's (Config.Animations.Strides), so its feet keep to the
	-- ground; it stands while it acts or lies down.
	local rig = Animations.Rigs[view.Rig]
	local walkClip = if rig then rig.Walk else nil
	if walkClip and dt > 0 then
		local position = view.Root.Position
		local moved = Vector3.new(position.X - view.Last.X, 0, position.Z - view.Last.Z).Magnitude
		view.Last = position
		view.Speed += (moved / dt - view.Speed) * math.min(1, dt * WALK_SMOOTHING)
		local walking = view.Speed > Animations.Walk.MinSpeed and view.Action == nil and view.State ~= "Down" and rate > 0
		local walk = view.Walk
		if walking and walk == nil then
			walk = track(view, walkClip)
			if walk then
				walk.Priority = Enum.AnimationPriority.Movement
				walk.Looped = true
			end
			view.Walk = walk
		end
		if walk then
			if walking then
				local speed = math.min(view.Speed / (Animations.Strides[walkClip] or 1), Animations.Walk.MaxRate)
				if not walk.IsPlaying then
					walk:Play((Clips.Fades(walkClip)), 1, speed)
				elseif math.abs(walk.Speed - speed) > 0.02 then
					walk:AdjustSpeed(speed)
				end
			elseif walk.IsPlaying then
				local _, out = Clips.Fades(walkClip)
				walk:Stop(out)
			end
		end
	end
	-- Down holds its last frame until the fighter rises.
	local reaction = view.Reaction
	if view.State == "Down" and reaction and reaction.IsPlaying and reaction.Length > 0 and reaction.TimePosition >= reaction.Length - 0.04 then
		reaction:AdjustSpeed(0)
	end
	return frozen
end

local function onHit(hit: any)
	if type(hit) ~= "table" then
		return
	end
	local attacker = views[hit.A]
	local target = views[hit.T]
	if attacker and not hit.Dodged then
		local at = hit.A:GetAttribute("ActionAt")
		show(attacker, target, hit.Heavy == true, `{hit.Beat}@{at}`)
	end
	if target == nil then
		return
	end
	local mine, onMine = isMine(attacker), isMine(target)
	if not (mine or onMine) then
		return
	end
	local numbers = Combat.Numbers
	if hit.Dodged then
		Effects.Number(target.Root, "Miss", Theme.Colour.Dodge, false, numbers)
		return
	end
	local color = if onMine then Theme.Colour.Hurt elseif hit.Critical then Theme.Colour.Critical else Theme.Colour.Hit
	Effects.Number(target.Root, tostring(math.floor(hit.Total + 0.5)), color, hit.Critical == true or hit.Heavy == true, numbers)
	if onMine and type(hit.MaxHealth) == "number" and hit.Total >= hit.MaxHealth * Combat.Shake.HurtShare then
		Effects.Shake(Combat.Shake.Hurt)
	end
end

-- The replay (ReplayService) sets "Replay" on the player: the camera turns to look down the pad, pitched over the avatar
-- (Config.Combat.Replay.Pitch). The player's camera keeps its own distance and centres on the avatar as in play, so this
-- sets only its turn: what the replay shows is what a player sees.
local function onReplay()
	local action = player:GetAttribute("Replay")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if type(action) ~= "string" or action == "" or root == nil then
		return
	end
	local camera = workspace.CurrentCamera
	local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local pitch = math.rad(Combat.Replay.Pitch)
	local look = flatLook * math.cos(pitch) - Vector3.new(0, math.sin(pitch), 0)
	local focus = camera.Focus.Position
	local zoom = (camera.CFrame.Position - focus).Magnitude
	camera.CFrame = CFrame.lookAt(focus - look * zoom, focus)
end

function FighterController.Start()
	CollectionService:GetInstanceAddedSignal("Fighter"):Connect(function(model: Instance)
		task.spawn(add, model)
	end)
	CollectionService:GetInstanceRemovedSignal("Fighter"):Connect(remove)
	for _, model in CollectionService:GetTagged("Fighter") do
		task.spawn(add, model)
	end
	Net.Client.On("Hit", onHit)
	player:GetAttributeChangedSignal("Replay"):Connect(function()
		task.delay(0.15, onReplay) -- once the avatar's move has reached this client and the camera has followed it
	end)
	RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()
		local frozen = false
		for _, view in views do
			local ok, result = pcall(stepView, view, dt, now)
			if not ok then
				warn(`FighterController: {view.Model.Name}: {result}`)
			elseif result then
				frozen = true
			end
		end
		Effects.TimeScale = if frozen then 0 else 1 -- the replay's freeze holds the sparks and numbers with the lead
	end)
end

return FighterController
