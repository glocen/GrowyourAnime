--!strict
-- FighterController (client): draws every fighter the server runs (FightService). It plays each fighter's clips on the
-- server's action clock, holds both bodies on a hit (hitstop), and runs each action's effect on its beat names. It
-- presents only: health, hits and every choice are the server's.
-- A hit is shown on the frame its beat comes on screen, when the target stands in reach there: the hold, the spark and the
-- camera. The server's Hit event brings the number, and the hold and spark too if the screen didn't see it coming.
-- A late action starts from its first frame and catches up (handbook/feel/combat.md, "Hit confirmation").
-- A passive's cue (Definitions.Passives, Cue): the shell while the server's PassiveOn holds, the flare on a hit it marks.
-- Children: Clips (an Animation per clip name), Effects (the stand-ins).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Actions = require(Shared.Definitions.Actions)
local Passives = require(Shared.Definitions.Passives)
local Animations = require(Shared.Config.Animations)
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local HudConfig = require(Shared.Config.Hud)
local UIKit = require(Shared.Config.UIKit)
local Voidkin = require(Shared.Definitions.Voidkin)
local Fight = require(Shared.Rules.Fight)
local CameraTurn = require(Shared.Util.CameraTurn)
local Clips = require(script.Clips)
local Effects = require(script.Effects)
local Rows = require(script.Rows)
local Sounds = require(script.Sounds)

local player = Players.LocalPlayer

-- The late start's catch-up (handbook/feel/combat.md, "Hit confirmation"): own pace first, then faster until in step.
local CATCH = { OwnPace = 0.08, Over = 0.12, Limit = 0.25 }
local WALK_SMOOTHING = 10 -- a second's share the walk's speed follows the body by: about a tenth of a second

-- The effects that hang on an action's beats, by its id. A landed hit's spark is every action's.
local EFFECTS: { [string]: (beats: { [string]: number }, attacker: Model, target: () -> BasePart?, action: Actions.Action) -> Effects.Running } = {
	RookHaymaker = Effects.Haymaker,
	PipLanternBurst = Effects.LanternBurst,
	PipCombo = Effects.LanternShots,
	LyricHeldNote = Effects.HeldNote,
	LyricCombo = Effects.SpeakerShots,
	KeeperSignature = Effects.KeeperSignature,
}

-- The look of a heal (Actions.Hit.Heal) on the body it mends, by the healer's action.
local HEALS: { [string]: (root: BasePart) -> () } = {
	LyricHeldNote = Effects.HealRing,
}

-- Clock is the action's, which a hold pauses; Free runs through a hold (an effect that lives past the hit, unheld). At is
-- when its action began (ActionAt), which a hit names.
type Running = { Effect: Effects.Running, Clock: number, Free: number, At: number }

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

-- A hit shown on a body (Held), and the body's flash and tremble from it (Struck): Rules.Fight.Flash and .Tremble, by the
-- hit's rung (Config.Combat.Hitstop; AR8 A).
type Held = { Target: View, At: number?, Rung: number, Hold: number }
type Struck = { At: number, Flash: number, Glow: number, Hold: number, Tremble: number, Seed: number, Shown: Vector3?, Offset: Vector3 }

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
	FellAt: Vector3?, -- where a lead fell, for the light it leaves as (TR12)
	Action: Actions.Action?,
	ActionAt: number,
	Clock: number,
	Begun: number, -- os.clock() when the action began on screen
	Late: number, -- how late it began, caught up after OwnPace
	Rate: number,
	FrozenUntil: number,
	Shown: { [string]: boolean }, -- the hits this screen has shown, by beat and press
	Held: { [string]: Held }, -- each hit it has shown on a body, by beat, press and target: what a server's hit may raise
	Struck: Struck?, -- its flash and tremble as a hit's target, while they run
	Glow: Highlight?, -- its flash's fill, made on its first hit
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
FighterController.Show = nil :: any -- for the self-test: a hit's moment on screen (set to show, below)

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

-- The struck body's flash, and its tremble inside its hold when `trembles` (Config.Combat.Hitstop; AR8 A): from now, a
-- later hit starting it over. The flash is a white fill over the body (a Highlight, one a body, made on its first hit).
local function strike(view: View, lever: Fight.Lever, hold: number, trembles: boolean)
	local glow = view.Glow
	if glow == nil or glow.Parent == nil then
		local made = Instance.new("Highlight")
		made.Name = "NL_HitFlash"
		made.FillColor = Color3.new(1, 1, 1)
		made.FillTransparency = 1
		made.OutlineTransparency = 1
		made.DepthMode = Enum.HighlightDepthMode.Occluded
		made.Enabled = false
		made.Adornee = view.Model
		made.Parent = view.Model
		view.Glow = made
	end
	local was = view.Struck
	view.Struck = {
		At = os.clock(),
		Flash = lever.Flash,
		Glow = lever.Glow,
		Hold = hold,
		Tremble = if trembles then lever.Tremble else 0,
		Seed = math.random() * 100,
		Shown = if was then was.Shown else nil, -- the tremble's last place, so the next frame takes its offset back
		Offset = if was then was.Offset else Vector3.zero,
	}
end

-- A hit's moment on screen: both bodies held for the hit's rung (Rules.Fight.Hold), the struck body's flash and tremble,
-- a spark where it lands, the camera's trauma on the player's own lead's hit. `key` is the beat's press: an area's or a
-- cone's every target gets its own hold, flash and spark, the attacker one hold and one jolt for them all, and none on a
-- steady hit (Actions.Hit.Steady: a run of beats that keeps its count). `draw`: asks the action's effect to draw the hit
-- on the target itself (drawnBy); when it does, the spark stays off and the target's hold waits for the effect to reach
-- it. A beat shown from the clock is its own rung; the server's hit raises it for a critical or a kill (raise).
local function show(attacker: View, target: View?, rung: number, heavy: boolean, steady: boolean, key: string, draw: ((landed: () -> ()) -> boolean)?)
	local each = if target then `{key}#{target.Id}` else key
	if attacker.Shown[each] then
		return
	end
	local first = not attacker.Shown[key]
	attacker.Shown[each] = true
	attacker.Shown[key] = true
	local lever = Fight.Lever(rung, Combat.Hitstop)
	local hold = Fight.Hold(rung, false, Combat.Hitstop)
	if first and not steady then
		freeze(attacker, hold)
	end
	if target then
		local held: Held = { Target = target, At = nil, Rung = rung, Hold = hold }
		attacker.Held[each] = held
		-- A body struck in the middle of its own action shows the flash, the spark and the number, and its clip never holds:
		-- its own beats keep the stage, timed as the server times them, which holds nothing (AR4, section 8: research,
		-- 2026-11-12).
		local function land()
			local holds = target.Action == nil
			if holds then
				freeze(target, hold)
			end
			held.At = os.clock()
			strike(target, lever, hold, holds)
		end
		if not (draw and draw(land)) then
			land()
			local at = chest(target)
			local from = attacker.Root.Position
			local toward = Vector3.new(from.X - at.X, 0, from.Z - at.Z)
			local surface = if toward.Magnitude > 0.01 then at + toward.Unit * (if target.Rig == "Box" then target.Root.Size.Z / 2 else 0.6) else at
			Effects.Spark(surface, from, heavy)
		end
	end
	if first and isMine(attacker) then
		Effects.Jolt(lever.Trauma)
	end
end
FighterController.Show = show

-- The server's word on a hit this screen showed from the clock (onHit): a critical's higher rung and a killing hit's
-- longer hold are known only there, a replication's delay after the beat. A hold still running is held to the server's
-- length; a hold already over isn't started again, which would stutter. A higher rung flashes the body again at its own
-- strength, and the player's own lead's camera takes the rung's further trauma, with the critical's number.
local function raise(attacker: View, each: string, rung: number, hold: number)
	local held = attacker.Held[each]
	if held == nil or held.At == nil then
		return
	end
	local target = held.Target
	local now = os.clock()
	local at = held.At :: number
	if hold > held.Hold and now < at + held.Hold and now < target.FrozenUntil then
		target.FrozenUntil = math.max(target.FrozenUntil, at + hold)
		held.Hold = hold
		local struck = target.Struck
		if struck then
			struck.Hold = math.max(0, at + hold - struck.At) -- the tremble shrinks across the longer hold
		end
	end
	if rung > held.Rung then
		local lever = Fight.Lever(rung, Combat.Hitstop)
		local before = Fight.Lever(held.Rung, Combat.Hitstop)
		strike(target, lever, math.max(0, at + held.Hold - now), now < target.FrozenUntil)
		if isMine(attacker) then
			Effects.Jolt(lever.Trauma - before.Trauma)
		end
		held.Rung = rung
	end
end

-- True when one of the attacker's effects for the action begun `at` takes the hit of `beat` on `target` on itself (the
-- Held Note's, when its crest reaches the body): it calls `landed` then, and draws the hit's look there when `look`.
-- Asking twice for one body and beat draws it once, and calls each `landed`.
local function drawnBy(attacker: View, beat: string, at: any, target: View?, landed: () -> (), look: boolean): boolean
	if target == nil then
		return false
	end
	for _, running in attacker.Running do
		local struck = running.Effect.Struck
		if running.At == at and struck and struck(beat, target.Model, landed, look) then
			return true
		end
	end
	return false
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
	view.Held = {}
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
		table.insert(view.Running, { Effect = effect, Clock = view.Clock, Free = view.Clock, At = at })
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

-- A Shade bursts as it goes down (AR2, section 11): the effect runs from the Down clip's start, on its clock, and hides
-- the body on its `Burst` marker (Effects.ShadeBurst), or bursts at once when it has no clip. A keeper's rig has a fall of
-- its own (Config.Effects.Falls): the same burst on its clip's marker, and its lantern left to go out (AR7, section 5).
local function burst(view: View, down: AnimationTrack?)
	local fall = EffectsConfig.Falls[view.Rig]
	Effects.ShadeBurst(view.Model, down, view.Collar, fall)
	if fall then
		Effects.LanternOut(view.Model, down, fall)
	end
end

local letGo: (prop: Prop, out: boolean) -> ()

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
		view.FellAt = view.Root.Position
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
	elseif state == "Home" then
		-- A fallen lead leaves as light where it lay and stands home on its plot (TR12): no body left lying, its prop back
		-- in its hand.
		local reaction = view.Reaction
		if reaction then
			reaction:Stop(0)
			view.Reaction = nil
		end
		local prop = view.Prop
		if prop and prop.Phase ~= "Held" then
			letGo(prop, false)
			prop.Phase = "Held"
		end
		Effects.LeadLeaves(view.FellAt or view.Root.Position)
		view.FellAt = nil
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
function letGo(prop: Prop, out: boolean)
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
		FellAt = nil,
		Action = nil,
		ActionAt = 0,
		Clock = 0,
		Begun = 0,
		Late = 0,
		Rate = 1,
		FrozenUntil = 0,
		Shown = {},
		Held = {},
		Struck = nil,
		Glow = nil,
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
	-- A Reduction passive's shell (Rook's Second Wind), while the server says it holds; one at a time.
	local passive = if type(def) == "string" then Passives.ById[def] else nil
	if passive and passive.Cue == "Shell" then
		local shelled = false
		local function holds(): boolean
			return model:GetAttribute("PassiveOn") == true
		end
		local function shell()
			if not shelled and holds() then
				shelled = true
				Effects.Shell(root :: BasePart, holds, function()
					shelled = false
				end)
			end
		end
		table.insert(view.Connections, model:GetAttributeChangedSignal("PassiveOn"):Connect(shell))
		shell()
	end
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
	if view.Glow then
		view.Glow:Destroy()
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
					local at = view.ActionAt
					show(view, target, Fight.Rung(hit.Rung, false, Combat.Hitstop), hit.Heavy, hit.Steady == true, `{beat}@{at}`, function(landed: () -> ()): boolean
						return drawnBy(view, beat, at, target, landed, true)
					end)
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
	if view.State == "Down" and reaction and reaction.IsPlaying and reaction.Length > 0 and reaction.TimePosition >= reaction.Length - Effects.HeldEnd then
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

-- One frame of a struck body's flash and tremble (strike). The tremble moves the root as the drawn push does, and takes
-- its last frame's offset back first unless the replica has moved the body since, so it never walks it off.
local function stepStruck(view: View, now: number)
	local struck = view.Struck :: Struck
	local t = now - struck.At
	local glow = view.Glow
	local fill = Fight.Flash(t, struck.Flash, struck.Glow)
	if glow then
		glow.FillTransparency = 1 - fill
		glow.Enabled = fill > 0
	end
	local root = view.Root
	local at = root.Position
	local base = if struck.Shown and (at - (struck.Shown :: Vector3)).Magnitude < 1e-3 then at - struck.Offset else at
	local studs = Fight.Tremble(t, struck.Hold, struck.Tremble)
	local offset = Vector3.zero
	if studs > 0 then
		local rate = Combat.Hitstop.Tremble.Rate
		local turn = math.floor(t * rate) * 2.39996 + struck.Seed -- a new side each step, never back the way it came
		offset = Vector3.new(math.cos(turn), 0, math.sin(turn)) * studs
	end
	if base + offset ~= at then
		root.CFrame += base + offset - at
	end
	struck.Shown, struck.Offset = base + offset, offset
	if fill <= 0 and studs <= 0 and t > 0 then
		view.Struck = nil
	end
end

-- The server's hit on `beat` of the action begun `at`, reaching a screen whose clock of it is still short of the beat
-- (its own hold before it, kept here and not by the server): the clip and its effects move on to the beat, so the hit's
-- hold lands on its contact frame (Fight.CatchTo). Effects key on their markers with "at or past", so none is skipped.
local function catchUp(view: View, beat: any, at: any)
	local action = view.Action
	if action == nil or type(beat) ~= "string" or at ~= view.ActionAt then
		return
	end
	local to = Fight.CatchTo(action, beat, view.Clock)
	if to == nil then
		return
	end
	-- The effects' own clocks follow the action's; their free time ran through the hold already, so it stays.
	local ahead = to - view.Clock
	view.Clock = to
	for _, running in view.Running do
		running.Clock += ahead
	end
	if view.Current and to < action.Length then
		view.Current.TimePosition = to
	end
end

-- The key a body's numbers merge by: one press of one fighter's action is one flurry (Effects.Number).
local function pressOf(model: any): string
	local view = if typeof(model) == "Instance" then views[model :: Model] else nil
	local at = if view then view.Model:GetAttribute("ActionAt") else nil
	return if view and type(at) == "number" then `{view.Id}@{at}` else `alone@{os.clock()}`
end

local function onHit(hit: any)
	if type(hit) ~= "table" then
		return
	end
	local attacker = views[hit.A]
	local target = views[hit.T]
	local at = if attacker then attacker.Model:GetAttribute("ActionAt") else nil
	-- An effect that draws the hit on the target (the Held Note's crest) has the target's hold, push and number wait for it
	-- to reach the body: the number on the touch (AR4, section 10, fix 2).
	local function drawn(landed: () -> (), look: boolean): boolean
		return attacker ~= nil and type(hit.Beat) == "string" and drawnBy(attacker, hit.Beat, at, target, landed, look)
	end
	if attacker and not hit.Dodged then
		catchUp(attacker, hit.Beat, at)
		local rung = if type(hit.Rung) == "number" then hit.Rung else 2
		local key = `{hit.Beat}@{at}`
		show(attacker, target, rung, hit.Heavy == true, hit.Steady == true, key, function(landed: () -> ()): boolean
			return drawn(landed, true)
		end)
		if target and type(hit.Hold) == "number" then
			raise(attacker, `{key}#{target.Id}`, rung, hit.Hold)
		end
	end
	if target == nil then
		return
	end
	local struck: View = target
	local press = pressOf(hit.A)
	local function land()
		if attacker and not hit.Dodged then
			knockOf(attacker, struck, hit)
		end
		-- The attacker's passive on this hit (Pip's Kindle): its flare at the body's attachment the row names.
		local passive = if attacker and type(hit.Passive) == "string" then Passives.ById[hit.Passive] else nil
		if attacker and passive and passive.Cue == "Flare" and passive.At then
			for _, child in attacker.Model:GetDescendants() do
				if child:IsA("Attachment") and child.Name == passive.At then
					Effects.Flare(child)
					break
				end
			end
		end
		local mine, onMine = isMine(attacker), isMine(struck)
		if not (mine or onMine) then
			return
		end
		-- The five styles and the grey word (docs/ui.md; Config.Hud.Numbers): a dodge or a block says so on a pointer;
		-- damage on the player's own lead is received; the player's own hit is dealt, or a critical, and its element's share
		-- is its own number in the element's colour, a beat behind.
		local numbers = Combat.Numbers
		local rung = if type(hit.Rung) == "number" then hit.Rung else 2
		if rung >= HudConfig.Numbers.Yield.From then
			Effects.Yield(struck.Root, rung) -- the lower numbers on the body give way to it (research's pass on AR8 A)
		end
		if hit.Dodged then
			Effects.Number(struck.Root, `{press}:word`, nil, { Style = "Word", Word = "Dodge" }, numbers)
			return
		end
		if hit.Blocked then
			Effects.Number(struck.Root, `{press}:word`, nil, { Style = "Word", Word = "Block" }, numbers)
		end
		if onMine then
			Effects.Number(struck.Root, press, hit.Total, { Style = "Received", Rung = rung }, numbers)
		else
			local elemental = if type(hit.Elemental) == "number" then hit.Elemental else 0
			local physical = hit.Total - elemental
			if physical >= 0.5 or elemental < 0.5 then
				Effects.Number(struck.Root, press, physical, { Style = if hit.Critical then "Critical" else "Dealt", Rung = rung }, numbers)
			end
			local def = if attacker then Voidkin.ById[tostring(attacker.Model:GetAttribute("Def"))] else nil
			local colour = if def then UIKit.Elements[def.Element] else nil
			if elemental >= 0.5 and colour then
				local root = struck.Root
				task.delay(HudConfig.Numbers.Element.Delay, function()
					Effects.Number(root, `{press}:element`, elemental, { Style = "Element", Colour = colour, Rung = rung }, numbers)
				end)
			end
		end
		if onMine and type(hit.MaxHealth) == "number" and hit.Total >= hit.MaxHealth * Combat.Shake.HurtShare then
			Effects.Jolt(Combat.Shake.Hurt)
		end
	end
	if not drawn(land, false) then
		land()
	end
end

-- A hit's heal (Actions.Hit.Heal): its look round the healed body (HEALS), and its number over it on the screens of the
-- healer's player and the healed's, one counting number for the press.
local function onHeal(heal: any)
	if type(heal) ~= "table" or type(heal.Amount) ~= "number" then
		return
	end
	local healer, healed = views[heal.A], views[heal.T]
	if healed == nil then
		return
	end
	local look = if healer and healer.Action then HEALS[healer.Action.Id] else nil
	local press = `heal:{pressOf(heal.A)}`
	local function land()
		if look then
			look(healed.Root)
		end
		if (isMine(healer) or isMine(healed)) and heal.Amount >= 0.5 then
			Effects.Number(healed.Root, press, heal.Amount, { Style = "Heal" }, Combat.Numbers)
		end
	end
	-- An ally's heal shows when the beat's crest reaches it, as a hit does (TR3; AR4 section 10). The healer's own, at once.
	if healer and healer ~= healed and type(heal.Beat) == "string" then
		if drawnBy(healer, heal.Beat, healer.Model:GetAttribute("ActionAt"), healed, land, false) then
			return
		end
	end
	land()
end

-- The replay (ReplayService) sets "Replay" on the player: the camera turns to look down the pad, pitched over the avatar
-- (Config.Combat.Replay.Pitch). The player's camera keeps its own distance and centres on the avatar as in play, so this
-- sets only its turn (through CameraTurn, which a phone's camera keeps): what the replay shows is what a player sees.
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
	CameraTurn.To(CFrame.lookAt(focus - look * zoom, focus))
end

function FighterController.Start()
	Sounds.Preload()
	Rows.Warm() -- the effect kit drawn once, unseen, so the first effect never pops in late (AR8)
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
			if view.Struck then
				local stepped, problem = pcall(stepStruck, view, now)
				if not stepped then
					view.Struck = nil
					warn(`FighterController: {view.Model.Name}'s flash: {problem}`)
				end
			end
		end
		Effects.TimeScale = if frozen then 0 else 1 -- the replay's freeze holds the sparks and numbers with the lead
	end)
end

return FighterController
