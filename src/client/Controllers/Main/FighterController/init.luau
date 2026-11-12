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
local Sounds = require(script.Sounds)

local player = Players.LocalPlayer

-- The late start's catch-up (handbook/feel/combat.md, "Hit confirmation"): own pace first, then faster until in step.
local CATCH = { OwnPace = 0.08, Over = 0.12, Limit = 0.25 }
local BURST_MARKER = "Burst" -- AR2's Burst clip: the body hides here and the effect takes over
local WALK_SMOOTHING = 10 -- a second's share the walk's speed follows the body by: about a tenth of a second

-- The effects that hang on an action's beats, by its id. A landed hit's spark is every action's.
local EFFECTS: { [string]: (beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action) -> Effects.Running } = {
	RookHaymaker = Effects.Haymaker,
	PipLanternBurst = Effects.LanternBurst,
	PipCombo = Effects.LanternShots,
	LyricHeldNote = Effects.HeldNote,
	LyricCombo = Effects.SpeakerShots,
}

-- Clock is the action's, which a hold pauses; Free runs through a hold (an effect that lives past the hit, unheld).
type Running = { Effect: Effects.Running, Clock: number, Free: number }

-- A hit's push as this screen draws it (Config.Combat.Push.Shown): from the hold's end, along the hit's line, at the
-- server's pace.
type Knock = { Home: Vector3, Direction: Vector3, Studs: number, From: number }

-- A prop let go of on Down and taken back on Up (Config.Animations.Props). At is when its move began.
type Prop = {
	Motor: Motor6D,
	Home: CFrame, -- its C0 in the hand
	Def: string,
	Phase: "Held" | "Down" | "Falling" | "Lying" | "Rise" | "Rising",
	From: CFrame, -- falling: the world place it left the hand; rising: where it lay, in the root's frame
	To: CFrame, -- where it lies, in the root's frame
	At: number,
}

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
	Knock: Knock?,
	Prop: Prop?,
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
-- move in step. A kind can keep a clip unmirrored (Config.Animations.Unmirrored).
local function pick(view: View, clip: string): string
	local mirror = Animations.Mirrors[clip]
	local kind = view.Model:GetAttribute("Kind")
	local kept = if type(kind) == "string" then Animations.Unmirrored[kind] else nil
	if mirror == nil or (kept and kept[clip]) then
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

-- A hit's moment on screen: both bodies held, a spark where it lands, the camera on the player's own heavy hit. `key` is
-- the beat's press: an area's or a cone's every target gets its own hold and spark, the attacker one hold and one shake for
-- them all, and none on a steady hit (Actions.Hit.Steady: a run of beats that keeps its count).
local function show(attacker: View, target: View?, heavy: boolean, steady: boolean, key: string)
	local each = if target then `{key}#{target.Id}` else key
	if attacker.Shown[each] then
		return
	end
	local first = not attacker.Shown[key]
	attacker.Shown[each] = true
	attacker.Shown[key] = true
	local hold = if heavy then Combat.Hitstop.Heavy else Combat.Hitstop.Light
	if first and not steady then
		freeze(attacker, hold)
	end
	freeze(target, hold)
	if target then
		local at = chest(target)
		local from = attacker.Root.Position
		local toward = Vector3.new(from.X - at.X, 0, from.Z - at.Z)
		local surface = if toward.Magnitude > 0.01 then at + toward.Unit * (if target.Rig == "Box" then target.Root.Size.Z / 2 else 0.6) else at
		Effects.Spark(surface, from, heavy)
	end
	if first and heavy and isMine(attacker) then
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
		end, action)
		table.insert(view.Running, { Effect = effect, Clock = view.Clock, Free = view.Clock })
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
		local prop = view.Prop
		if prop then
			prop.Phase, prop.At = "Down", os.clock()
		end
	elseif state == "Idle" and was == "Down" then
		playReaction(view, "Up") -- a rig with no Up (a Shade's, a box) plays none
		local prop = view.Prop
		if prop and prop.Phase == "Down" then
			prop.Phase = "Held" -- never let go
		elseif prop and prop.Phase ~= "Held" then
			prop.Phase = "Rise"
		end
	end
end

-- Where a prop's piece is in the hand, under the clip's Transform.
local function inHand(prop: Prop): CFrame
	local motor = prop.Motor
	return (motor.Part0 :: BasePart).CFrame * prop.Home * motor.Transform * motor.C1:Inverse()
end

-- Out of the hand, the piece leaves its joint on this screen only (the motor off, the piece anchored), so the clip's arm
-- can't carry it: the server's copy never changes.
local function letGo(prop: Prop, out: boolean)
	local piece = prop.Motor.Part1 :: BasePart
	if out then
		prop.Motor.Enabled = false
		piece.Anchored = true
	else
		prop.Motor.C0 = prop.Home
		piece.Anchored = false
		prop.Motor.Enabled = true
	end
end

-- One frame of a prop (Config.Animations.Props): let go at its Drop into the Down clip, falling flat beside the body,
-- lying there, and carried back to the hand on Up. Where it lies, and where it rises from, are kept in the root's frame,
-- so it stays beside the body if the body is moved (a lead rises at the avatar's side).
local function stepProp(view: View, now: number)
	local prop = view.Prop
	if prop == nil or prop.Phase == "Held" or prop.Motor.Part0 == nil or prop.Motor.Part1 == nil then
		return
	end
	local spec = Animations.Props[prop.Def]
	if spec == nil then
		return
	end
	local piece = prop.Motor.Part1 :: BasePart
	local root = view.Root.CFrame
	if prop.Phase == "Down" then
		local down = view.Reaction
		local into = if down and down.IsPlaying then down.TimePosition else now - prop.At
		if into < spec.Drop then
			return
		end
		local floor = -3 -- an R6 root stands 3 studs over the floor
		-- its length along the body, lying on its back: its own up along the root's look, its face to the sky
		prop.To = CFrame.fromMatrix(Vector3.new(spec.Aside, floor + piece.Size.Z / 2, -spec.Along), Vector3.xAxis, -Vector3.zAxis)
		prop.From = piece.CFrame
		letGo(prop, true)
		prop.Phase, prop.At = "Falling", now
	end
	if prop.Phase == "Rise" then
		prop.From = root:ToObjectSpace(piece.CFrame) -- from wherever it is, fallen or still falling
		prop.Phase, prop.At = "Rising", now
	end
	if prop.Phase == "Falling" then
		local u = math.clamp((now - prop.At) / math.max(spec.Fall, 0.01), 0, 1)
		local rest = root * prop.To
		local fall = prop.From:Lerp(rest, u * u) -- it drops, faster as it goes
		local half = piece.Size / 2
		local low = math.huge
		for _, corner in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1) } do
			local reach = math.abs(fall:VectorToWorldSpace(half * corner).Y)
			low = math.min(low, fall.Position.Y - reach)
		end
		local floor = root.Position.Y - 3
		if low < floor then
			fall += Vector3.new(0, floor - low, 0) -- tipping over, never through the floor
		end
		piece.CFrame = fall
		if u >= 1 then
			prop.Phase = "Lying"
		end
	elseif prop.Phase == "Lying" then
		piece.CFrame = root * prop.To
	elseif prop.Phase == "Rising" then
		local u = math.clamp((now - prop.At) / math.max(spec.Back, 0.01), 0, 1)
		if u >= 1 then
			letGo(prop, false)
			prop.Phase = "Held"
		else
			piece.CFrame = (root * prop.From):Lerp(inHand(prop), u * u * (3 - 2 * u))
		end
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
	local def = model:GetAttribute("Def")
	local propSpec = if type(def) == "string" then Animations.Props[def] else nil
	local propMotor = if propSpec then model:FindFirstChild(propSpec.Motor, true) else nil
	if propSpec and propMotor and propMotor:IsA("Motor6D") then
		view.Prop = { Motor = propMotor, Home = propMotor.C0, Def = def :: string, Phase = "Held", From = CFrame.identity, To = CFrame.identity, At = 0 }
	end
	local idleClip = (if type(def) == "string" then Animations.Idles[def] else nil) or (if reactions then reactions.Idle else nil)
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
					show(view, target, hit.Heavy, hit.Steady == true, `{beat}@{view.ActionAt}`)
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
		running.Free += if frozen or now >= view.FrozenUntil then step else dt
		if not running.Effect.Step(running.Clock, running.Free) then
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
	stepProp(view, now)
	return frozen
end

-- The server pushes a hit's target as the hold ends, and a body the server moves reaches this screen a replication delay
-- later: about 0.2 s in Studio, more with ping, so the knock landed after Haymaker's bracket had gone (AR1, section 8).
-- So this screen draws the push itself, from its own hold's end at the server's pace (Combat.Push.Seconds), ahead of the
-- body's replicated place by what the replication hasn't brought yet, and hands it back once that has caught up.
local function knockOf(attacker: View, target: View, hit: any)
	local action = Actions.ById[hit.Action]
	local beat = if action and action.Hits then (action.Hits :: any)[hit.Beat] else nil
	local weight = (Combat.Weight :: any)[target.Model:GetAttribute("Kind")] or 1
	local studs = (if beat and type(beat.Push) == "number" then beat.Push else 0) * weight
	local line = target.Root.Position - attacker.Root.Position
	line = Vector3.new(line.X, 0, line.Z)
	if not Combat.Push.Shown or studs <= 0 or line.Magnitude < 0.01 then
		return
	end
	target.Knock = {
		Home = target.Root.Position,
		Direction = line.Unit,
		Studs = studs,
		From = os.clock() + (if type(hit.Hold) == "number" then hit.Hold else 0),
	}
end

-- One frame of a drawn push: the body moved on by what the server's push has done by now and its replica hasn't shown.
local function stepKnock(view: View, now: number)
	local knock = view.Knock
	if knock == nil then
		return
	end
	local shown = (view.Root.Position - knock.Home):Dot(knock.Direction)
	local ahead = Fight.KnockAhead(knock.Studs, now - knock.From, shown, Combat.Push)
	if ahead == nil or view.Root.Parent == nil then
		view.Knock = nil
	elseif ahead > 0 then
		view.Root.CFrame += knock.Direction * ahead
	end
end

local function onHit(hit: any)
	if type(hit) ~= "table" then
		return
	end
	local attacker = views[hit.A]
	local target = views[hit.T]
	if attacker and not hit.Dodged then
		local at = hit.A:GetAttribute("ActionAt")
		show(attacker, target, hit.Heavy == true, hit.Steady == true, `{hit.Beat}@{at}`)
		if target then
			knockOf(attacker, target, hit)
		end
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

-- A hit's heal (Actions.Hit.Heal): its number over the healed body, on the screens of the healer's player and the healed's.
local function onHeal(heal: any)
	if type(heal) ~= "table" or type(heal.Amount) ~= "number" then
		return
	end
	local healer, healed = views[heal.A], views[heal.T]
	if healed == nil or not (isMine(healer) or isMine(healed)) then
		return
	end
	local amount = math.floor(heal.Amount + 0.5)
	if amount >= 1 then
		Effects.Number(healed.Root, `+{amount}`, Theme.Colour.Heal, false, Combat.Numbers)
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
	Sounds.Preload()
	CollectionService:GetInstanceAddedSignal("Fighter"):Connect(function(model: Instance)
		task.spawn(add, model)
	end)
	CollectionService:GetInstanceRemovedSignal("Fighter"):Connect(remove)
	for _, model in CollectionService:GetTagged("Fighter") do
		task.spawn(add, model)
	end
	Net.Client.On("Hit", onHit)
	Net.Client.On("Heal", onHeal)
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
			if view.Knock then
				local knocked, problem = pcall(stepKnock, view, now)
				if not knocked then
					view.Knock = nil
					warn(`FighterController: {view.Model.Name}'s knock: {problem}`)
				end
			end
		end
		Effects.TimeScale = if frozen then 0 else 1 -- the replay's freeze holds the sparks and numbers with the lead
	end)
end

return FighterController
