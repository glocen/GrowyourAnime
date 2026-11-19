--!strict
-- FightService (server): every fighter in the world, the lead, the Shades and the keeper, run by one module
-- (docs/engineering-plan.md, "Reusable modules"). The server decides every hit (Shared.Rules.Hit, rolled with its own
-- Random) and every choice (Shared.Rules.Fight); clients only present it.
-- What clients read, as attributes on each fighter's model: Fighter (its id), Side, Def, Kind, Rig, Title, Level, Owner
-- (a lead's UserId), Health, MaxHealth, State, StateUntil (server time it ends, 0 for open-ended: a fallen lead's return),
-- Target (a fighter id or ""), Action and ActionAt. ActionAt is written last,
-- so a client reads the action on its change. Each hit, landed or dodged, goes to every client as the Hit event.
-- A marked strike's footprint (TR44; Rules.Mark) while it's down: MarkAt (its centre, at the fighter's root height),
-- MarkRadius, MarkDown and MarkSlam (server times), MarkSlam written last. A lead broken off for its avatar: Away.
-- Beats are checked every frame against the server's clock; decisions every Config.Combat.Think.

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)
local Parts = require(Shared.Util.Parts)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Passives = require(Shared.Definitions.Passives)
local Voidkin = require(Shared.Definitions.Voidkin)
local Combat = require(Shared.Config.Combat)
local WorldConfig = require(Shared.Config.World)
local Shades = require(Shared.Config.Shades)
local EffectsConfig = require(Shared.Config.Effects)
local Stats = require(Shared.Rules.Stats)
local StatsConfig = require(Shared.Config.Stats)
local Hit = require(Shared.Rules.Hit)
local Fight = require(Shared.Rules.Fight)
local Tower = require(Shared.Rules.Tower)
local Carry = require(Shared.Rules.Carry)
local Markers = require(Shared.World.Markers)
local Passive = require(Shared.Rules.Passive)
local MarkRule = require(Shared.Rules.Mark)
local DataService = require(script.Parent.Parent.Core.DataService)

-- "Home": a fallen lead on its plot, healing and waiting for its player (TR12), never in a fight.
export type State = "Idle" | "Flinch" | "Stun" | "Down" | "Reset" | "Home"

-- A marked strike's footprint (TR44): its flat centre and its root's height when put down, its radius, when it went down
-- and when its hit lands (server time), and the fighter it was aimed at.
export type Mark = { X: number, Z: number, Y: number, Radius: number, Down: number, Slam: number, Target: Fighter? }
-- A lead broken off for its place by its avatar (FightService.Away): at Speed, held until Until, or else Hold seconds
-- once it arrives (at most Most seconds on the way); Since, when it broke off.
export type Away = { Speed: number, Until: number?, Hold: number, Most: number, Since: number, Arrived: number? }

export type Fighter = {
	Id: string,
	Model: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Align: AlignOrientation,
	Push: LinearVelocity,
	Side: "Lead" | "Shade",
	Kind: string, -- "Lead", or an enemy's Kind
	Owner: Player?,
	Def: string,
	Block: Stats.Block,
	Kit: { Actions.Action },
	Health: number,
	State: State,
	StateUntil: number,
	Target: Fighter?,
	Action: Actions.Action?,
	ActionAt: number,
	Checked: number, -- the action's clock at the last beat check
	ReadyAt: { [string]: number },
	ResetClosest: number, -- walking home: the nearest it has come, and when (Rules.Fight.ResetStuck)
	ResetSince: number,
	SkippedAt: number, -- a ranged lead's last skip back (Combat.Skip)
	NextThink: number,
	Home: CFrame?, -- a Shade's spawn
	Pack: string?,
	Ground: string?, -- the ground an enemy stands in, whose drops it gives (Rules.Drops); nil drops nothing
	Stage: number?, -- the street's stage it stands in (Config.Stages, TR43): its fall counts for a run of that stage
	-- A foe fought by this player's lead alone (a Tower floor's, TR29): no other lead sees it or strikes it, and it sees
	-- and strikes no other.
	For: Player?,
	-- A lead on a Hard stage (TR43): it fights its player's own foes alone, and no other foe fights it.
	Solo: boolean?,
	-- Its marked strike's footprint while it's down (TR44): put down on its action's Aim beat, taken up on its Mark hit or
	-- when the action ends. Its aim is fixed meanwhile.
	Mark: Mark?,
	Away: Away?, -- a lead broken off for its place by its avatar (TR44's A and B)
	HealRoom: number?, -- what it may still heal this floor (the Tower's heal cap, Rules.Tower.Capped); nil, no cap
	RegenAt: number, -- a lead's next Regen burst (TR40; Rules.Fight.BurstDue), from its summon
	Frail: boolean?, -- it falls to the first hit that lands (a Tower's fast floor, Rules.Tower.Fast)
	Hitters: { [Player]: boolean }, -- players whose lead hit it: a pack belongs to everyone (docs/design.md)
	Struck: { [string]: boolean }, -- the fighters (by Id) whose hit has landed on it since it last stood home: an Opener's first
	Shield: { Share: number, Until: number }?, -- the share less damage it takes until then (Actions.Hit.Shield)
	StunLock: number, -- no stun stops it again before this (Rules.Fight.Stun)
	Alone: number, -- its most health with one or two leads on it; a crowd adds to it (Fight.CrowdHealth)
	-- A lead watching a keeper it felled, standing and facing where it fell, until its Down's Gone (AR7, section 5, fix 2).
	Watch: Vector3?,
	WatchUntil: number,
	-- The replay's (Studio): one action on a timer, against one target, standing still.
	Forced: string?,
	ForcedEvery: number,
	ForcedNext: number,
	ForcedTarget: Fighter?,
	ForcedHome: CFrame?, -- where it stood when held: an action that carries it (Actions.Moves) starts each press from there
	-- The replay's foe (FightService.Follow): it presses ForcedLag seconds after each press of the fighter whose
	-- ForcedFollower it is, never on its own clock.
	ForcedLag: number?,
	ForcedFollower: Fighter?,
}

local FightService = {
	Priority = 30, -- after DataService and BaseService
}

FightService.Fell = Signal.new() -- (fighter, hitters: { Player }) once a fighter falls; a Shade is gone FadeSeconds later
FightService.Rose = Signal.new() -- (fighter) a lead up again: home with its player, or brought back by a test
FightService.Marked = Signal.new() -- (fighter, mark) a marked strike's footprint is down (TR44)
-- (fighter, mark, struck: { Fighter }?) taken up: on its hit, with the leads it took; nil when its action ended first
FightService.Unmarked = Signal.new()
FightService.Capped = Signal.new() -- (fighter) a heal stopped short by its HealRoom: the Tower's cap bound (TR46)

local GROUP_FIGHTERS = "Fighters"
local GROUP_AVATARS = "Avatars"
local GREY = Color3.fromRGB(163, 162, 165)
local SHADE_BODY = Color3.fromRGB(46, 46, 52)
local SHADE_MASK = Color3.fromRGB(214, 214, 214)
local SHADE_ROOT_HEIGHT = 3 -- the Shade rig's root above its feet, at scale 1 (the recipe's frame)
local LEAD_ROOT_HEIGHT = 3 -- an R6 lead's root above its feet
local AWAY_THERE = 1.5 -- studs from its place by the avatar a broken-off lead counts as there (TR44)

local rng = Random.new()
local fighters: { [string]: Fighter } = {}
local byModel: { [Model]: Fighter } = {}
local leads: { [Player]: Fighter } = {}
local packHit: { [string]: { [Fighter]: boolean } } = {} -- the leads that hit a pack, until it resets
-- Where each player's camera looks, flat, as their client last said (Net "View"; TR24's fixes 2 and 3), by os.clock().
local views: { [Player]: { Look: Vector3, At: number } } = {}
-- A lead waiting in view for an enemy coming to it from out of view (TR24's fix 2): which, and since when.
local waits: { [Fighter]: { Target: Fighter, Since: number } } = setmetatable({}, { __mode = "k" }) :: any
local overs: { [Fighter]: number } = setmetatable({}, { __mode = "k" }) :: any -- halfOver's, once each
local nextId = 0
local folder: Folder

local function now(): number
	return workspace:GetServerTimeNow()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function distance(a: BasePart, b: BasePart): number
	return flat(b.Position - a.Position).Magnitude
end

local function standing(f: Fighter?): boolean
	return f ~= nil and fighters[f.Id] == f and f.State ~= "Down" and f.State ~= "Reset" and f.State ~= "Home"
end

local function setState(f: Fighter, state: State, untilTime: number?)
	if state == "Reset" and f.State ~= "Reset" then
		f.ResetClosest, f.ResetSince = math.huge, now()
	end
	f.State = state
	f.StateUntil = untilTime or 0
	f.Model:SetAttribute("StateUntil", f.StateUntil) -- before State: a client reads both on State's change
	f.Model:SetAttribute("State", state)
end

-- A lead's passive (Definitions.Passives), while Combat.Passives is on; a Shade has none.
local function passiveOf(f: Fighter): Passives.Row?
	return if f.Side == "Lead" and Combat.Passives.On then Passives.ById[f.Def] else nil
end

local function setHealth(f: Fighter, health: number)
	f.Health = health
	f.Model:SetAttribute("Health", health)
	-- A Reduction passive's cue holds while its condition does (FighterController/Passives): Rook's shell under 30%.
	local row = passiveOf(f)
	if row and row.Kind == "Reduction" then
		f.Model:SetAttribute("PassiveOn", f.State ~= "Home" and Passive.Holds(row, health, f.Block.Health))
	end
end

-- An action's cooldown for this fighter: its passive may shorten its own (Lyric's Tempo).
-- A heal toward `wanted`, inside what the fighter may still heal (HealRoom, the Tower's cap; Rules.Tower.Capped): every
-- heal in a fight passes here, its Regen, an action's mend and Lifesteal once it's wired. Returns the health it reached.
local function heal(f: Fighter, wanted: number): number
	local room = f.HealRoom
	if room == nil then
		setHealth(f, wanted)
		return f.Health
	end
	local reached, left = Tower.Capped(f.Health, wanted, room)
	f.HealRoom = left
	setHealth(f, reached)
	if reached < wanted then
		FightService.Capped:Fire(f)
	end
	return f.Health
end

-- Whether `f` may strike `other`: another side, and a foe fought alone and its player's lead only each other (TR29).
local function against(f: Fighter, other: Fighter): boolean
	if other.Side == f.Side then
		return false
	end
	if f.For and other.Owner ~= f.For then
		return false
	end
	if (f.Solo and other.For ~= f.Owner) or (other.Solo and f.For ~= other.Owner) then
		return false
	end
	return other.For == nil or other.For == f.Owner
end

local function cooldownOf(f: Fighter, action: Actions.Action): number
	return Passive.Cooldown(passiveOf(f), action.Id, action.Cooldown)
end

-- Who the client sees a fighter aimed at (an effect's line through it): the replay's held target first, then its own.
local function showTarget(f: Fighter)
	local shown = f.ForcedTarget or f.Target
	f.Model:SetAttribute("Target", if shown then shown.Id else "")
end

local function setTarget(f: Fighter, target: Fighter?)
	if f.Target ~= target then
		f.Target = target
		showTarget(f)
	end
end

local function face(f: Fighter, toward: Vector3?)
	if toward then
		local look = flat(toward - f.Root.Position)
		if look.Magnitude > 0.05 then
			f.Humanoid.AutoRotate = false
			f.Align.CFrame = CFrame.lookAt(Vector3.zero, look.Unit)
			f.Align.Enabled = true
			return
		end
	end
	f.Align.Enabled = false
	f.Humanoid.AutoRotate = true
end

local function moveTo(f: Fighter, position: Vector3, speed: number)
	f.Humanoid.WalkSpeed = speed
	f.Humanoid:MoveTo(position)
end

local function stop(f: Fighter)
	f.Humanoid:MoveTo(f.Root.Position)
end

-- A footprint taken up (TR44): its attributes cleared, and its hearers told what it took (nil: its action ended first).
local function takeUp(f: Fighter, struck: { Fighter }?)
	local mark = f.Mark
	if mark == nil then
		return
	end
	f.Mark = nil
	f.Model:SetAttribute("MarkSlam", nil)
	f.Model:SetAttribute("MarkAt", nil)
	f.Model:SetAttribute("MarkRadius", nil)
	f.Model:SetAttribute("MarkDown", nil)
	FightService.Unmarked:Fire(f, mark, struck)
end

local function endAction(f: Fighter, at: number)
	takeUp(f, nil)
	if f.Action then
		f.Action = nil
		f.Model:SetAttribute("Action", "")
		f.Model:SetAttribute("ActionAt", at)
	end
end

local function start(f: Fighter, action: Actions.Action, at: number)
	f.Action = action
	f.ActionAt = at
	f.Checked = -1
	local cooldown = cooldownOf(f, action)
	if cooldown > 0 then
		f.ReadyAt[action.Id] = at + cooldown
		-- The signature's ring on the HUD fills from here (docs/ui.md; TR3): when it's ready again, in server time.
		f.Model:SetAttribute("Ready", at + cooldown)
	end
	stop(f)
	f.Model:SetAttribute("Action", action.Id)
	f.Model:SetAttribute("ActionAt", at) -- last: a client reads the action on its change
end

-- Busy: inside an action, before the next may start.
local function busy(f: Fighter, at: number): boolean
	return f.Action ~= nil and at - f.ActionAt < (f.Action :: Actions.Action).CancelFrom
end

local function setCollision(model: Model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = GROUP_FIGHTERS
		end
	end
end

-- The joints every fighter's root carries: one to turn it to its target, one to push it.
local function addMovers(root: BasePart): (AlignOrientation, LinearVelocity)
	local attachment = Instance.new("Attachment")
	attachment.Name = "FightAttachment"
	attachment.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.Responsiveness = 40
	align.MaxTorque = 1e7
	align.Enabled = false
	align.Parent = root
	local push = Instance.new("LinearVelocity")
	push.Attachment0 = attachment
	push.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	push.MaxAxesForce = Vector3.new(1e6, 0, 1e6)
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.Enabled = false
	push.Parent = root
	return align, push
end

-- The lead's R6 stand-in: Roblox's plain R6 body, greyed, with nothing of the avatar's (no face, clothes or scripts).
local function buildR6(name: string): Model
	local model = Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	model.Name = name
	for _, item in model:GetDescendants() do
		if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("Decal") or item:IsA("Clothing") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("Accessory") then
			item:Destroy()
		end
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Color = GREY
			part.Material = Enum.Material.SmoothPlastic
		end
	end
	return model
end

-- The grey stand-in, for a Voidkin not yet made: the reveal shows it too (RevealService).
FightService.StandIn = buildR6

-- A lead's body: its Voidkin's own (Definitions.Voidkin's Model, ServerStorage.Templates.<Model>) once it's installed,
-- else the grey R6 stand-in. Both are R6 rigs, so both play the R6 clips; with its body comes its row's reaction set
-- (Config.Animations.Rigs), the stand-in's is open legs'.
local function buildLead(def: string, name: string): (Model, string)
	local row = Voidkin.ById[def]
	local template = if row and row.Model then ServerStorage:WaitForChild("Templates"):FindFirstChild(row.Model) else nil
	if template == nil then
		return buildR6(name), "R6"
	end
	local model = (template :: Model):Clone()
	model.Name = name
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart -- set in code: a synced .rbxm can drop it
	return model, (row :: Voidkin.Row).Rig or "R6"
end

-- A Voidkin's body and its rig's name, as a lead's: a worker at its bay stands in it too (BaseService).
FightService.Body = buildLead

-- A Shade in grey: a dark box on an unseen root, joined by a Motor6D the client leans for its stand-in motion, and a
-- mask on its face. An elite carries a second mask on its shoulder; a keeper, a hat.
local function buildBox(row: Enemies.Row, name: string): Model
	local size = assert(row.Size, `{row.Id}: a box needs a Size`)
	local width, height, depth = size[1], size[2], size[3]
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(width, height, depth)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = root.Size
	body.Color = SHADE_BODY
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.Massless = true
	body.Parent = model
	local joint = Instance.new("Motor6D")
	joint.Name = "Body"
	joint.Part0 = root
	joint.Part1 = body
	joint.Parent = root
	local function mask(size: number, at: CFrame)
		local part = Instance.new("Part")
		part.Name = "Mask"
		part.Shape = if row.Mask == "Round" then Enum.PartType.Cylinder else Enum.PartType.Block
		part.Size = Vector3.new(0.3, size, size)
		part.Color = SHADE_MASK
		part.Material = Enum.Material.SmoothPlastic
		part.CanCollide = false
		part.Massless = true
		part.CFrame = body.CFrame * at * CFrame.Angles(0, math.rad(90), 0) -- a cylinder's axis is X: turn it to face forward
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
	end
	mask(width * 0.62, CFrame.new(0, height * 0.28, -depth / 2 - 0.16))
	if row.Kind == "Elite" then
		mask(width * 0.36, CFrame.new(width * 0.32, height / 2 + 0.1, -depth / 2 + 0.2))
	elseif row.Kind == "Keeper" then
		local hat = Instance.new("Part")
		hat.Name = "Hat"
		hat.Size = Vector3.new(width * 1.4, 0.4, depth * 1.6)
		hat.Color = SHADE_BODY
		hat.Material = Enum.Material.SmoothPlastic
		hat.CanCollide = false
		hat.Massless = true
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.2, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = hat
		weld.Parent = hat
		hat.Parent = model
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 0.1
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

-- A Shade in AR2's rig (ServerStorage.Templates.Shade, tools/studio/Models/Shade.luau): the row's mask kept and the
-- others dropped, an elite's second mask on its Left Arm too, the body's lit edges in its type's colour and the masks in
-- their own (Config.Shades), at the row's scale.
local function buildShade(row: Enemies.Row, name: string, type: string): Model
	local templates = ServerStorage:WaitForChild("Templates")
	local model = (templates:WaitForChild("Shade") :: Model):Clone()
	model.Name = name
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart -- set in code: a synced .rbxm can drop it
	local keep = `Mask_{row.Mask}`
	local second = if row.Kind == "Elite" then `EliteMask_{row.Mask}` else nil
	assert(model:FindFirstChild(keep), `{row.Id}: the rig has no {keep}`)
	-- Only the Brawler's second mask is past its content check (AR2, section 5): another elite waits for its own.
	assert(second == nil or model:FindFirstChild(second), `{row.Id}: the rig has no {second}`)
	for _, part in model:GetChildren() do
		local mask = string.sub(part.Name, 1, 5) == "Mask_" or string.sub(part.Name, 1, 10) == "EliteMask_"
		if part:IsA("BasePart") and mask and part.Name ~= keep and part.Name ~= second then
			part:Destroy()
		end
	end
	local tint = Shades.Tint[type] or Shades.Tint[row.Type] or Shades.MaskTint
	for _, look in model:GetDescendants() do
		if look:IsA("SurfaceAppearance") then
			local on = (look.Parent :: Instance).Name
			local onMask = on == keep or on == second
			look.EmissiveTint = if onMask then Shades.MaskTint else tint
			look.EmissiveStrength = if onMask then Shades.MaskEmissive else Shades.Emissive
		end
	end
	if row.Scale and row.Scale ~= 1 then
		model:ScaleTo(row.Scale)
	end
	return model
end

-- An enemy in a rig of its own (ServerStorage.Templates.<Rig>: the Lamplighter's, built by ModelRecipe),
-- built on the Shade's frame: each surface's glow says what it is (its attribute Glow), so the body's lit seams take its
-- type's colour and the mask a mask's, as a Shade's (Config.Shades); any other glow is its own. At the row's scale.
local function buildRig(row: Enemies.Row, name: string, type: string): Model
	local templates = ServerStorage:WaitForChild("Templates")
	local model = (templates:WaitForChild(row.Rig) :: Model):Clone()
	model.Name = name
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart -- set in code: a synced .rbxm can drop it
	local tint = Shades.Tint[type] or Shades.Tint[row.Type] or Shades.MaskTint
	for _, look in model:GetDescendants() do
		if look:IsA("SurfaceAppearance") then
			local glow = look:GetAttribute("Glow")
			if glow == "Body" then
				look.EmissiveTint, look.EmissiveStrength = tint, Shades.Emissive
			elseif glow == "Mask" then
				look.EmissiveTint, look.EmissiveStrength = Shades.MaskTint, Shades.MaskEmissive
			end
		end
	end
	if row.Scale and row.Scale ~= 1 then
		model:ScaleTo(row.Scale)
	end
	return model
end

local function register(model: Model, side: "Lead" | "Shade", kind: string, def: string, block: Stats.Block, kit: { Actions.Action }, title: string, owner: Player?, rig: string?): Fighter
	nextId += 1
	local id = `f{nextId}`
	local root = assert(Parts.Root(model), "a fighter needs a root")
	local humanoid = assert(Parts.Humanoid(model), "a fighter needs a humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) -- health is ours (Fighter.Health); the engine's never falls
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid
	end
	local align, push = addMovers(root)
	setCollision(model)
	local at = now()
	local f: Fighter = {
		Id = id,
		Model = model,
		Root = root,
		Humanoid = humanoid,
		Align = align,
		Push = push,
		Side = side,
		Kind = kind,
		Owner = owner,
		Def = def,
		Block = block,
		Kit = kit,
		Health = block.Health,
		State = "Idle",
		StateUntil = 0,
		Target = nil,
		Action = nil,
		ActionAt = 0,
		Checked = -1,
		ReadyAt = {},
		ResetClosest = math.huge,
		ResetSince = 0,
		SkippedAt = -math.huge,
		NextThink = at + rng:NextNumber() * Combat.Think, -- spread over the tick
		RegenAt = at + StatsConfig.Regen.Every,
		Home = nil,
		Pack = nil,
		Ground = nil,
		Hitters = {},
		Struck = {},
		Shield = nil,
		StunLock = 0,
		Alone = block.Health,
		WatchUntil = 0,
		Forced = nil,
		ForcedEvery = 0,
		ForcedNext = 0,
		ForcedTarget = nil,
		ForcedHome = nil,
		ForcedLag = nil,
		ForcedFollower = nil,
	}
	model:SetAttribute("Fighter", id)
	model:SetAttribute("Side", side)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Def", def)
	model:SetAttribute("Rig", rig or (if side == "Lead" then "R6" else "Box"))
	model:SetAttribute("Title", title)
	model:SetAttribute("Level", block.Level)
	-- The signature: the kit's action with a cooldown, for the HUD's ring (TR3), after its passive. 0 without one.
	local cooldown = 0
	for _, action in kit do
		cooldown = math.max(cooldown, cooldownOf(f, action))
	end
	model:SetAttribute("Cooldown", cooldown)
	model:SetAttribute("PassiveOn", false)
	model:SetAttribute("Ready", 0)
	model:SetAttribute("Owner", if owner then owner.UserId else 0)
	model:SetAttribute("MaxHealth", block.Health)
	model:SetAttribute("Health", block.Health)
	model:SetAttribute("State", "Idle")
	model:SetAttribute("Target", "")
	model:SetAttribute("Action", "")
	model:SetAttribute("ActionAt", 0)
	fighters[id] = f
	byModel[model] = f
	CollectionService:AddTag(model, "Fighter")
	-- A body streams whole. A lead is always on its owner's client: left out of range when the avatar teleports, its
	-- copy there would stand stale where it was (seen in the self-test, 2026-11-12).
	if owner then
		model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
		model:AddPersistentPlayer(owner)
	else
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
	model.Parent = folder
	root:SetNetworkOwner(nil) -- the server moves every fighter
	return f
end

local function remove(f: Fighter)
	if fighters[f.Id] ~= f then
		return
	end
	fighters[f.Id] = nil
	byModel[f.Model] = nil
	if f.Owner and leads[f.Owner] == f then
		leads[f.Owner] = nil
	end
	for _, other in fighters do
		if other.Target == f then
			setTarget(other, nil)
		end
		if other.ForcedTarget == f then
			other.ForcedTarget = nil
			showTarget(other)
		end
	end
	for _, hit in packHit do
		hit[f] = nil
	end
	f.Model:Destroy()
end

local function bearingOf(offset: Vector3): number
	return math.deg(math.atan2(offset.Z, offset.X))
end

-- Where the player watches from (TR24's fixes 2 and 3): their camera's flat look while their client's report is fresh,
-- else the avatar's facing.
local function lookOf(owner: Player?, avatar: BasePart): Vector3
	local view = if owner then views[owner] else nil
	if view and os.clock() - view.At <= Combat.Lead.View.Fresh then
		return view.Look
	end
	local facing = flat(avatar.CFrame.LookVector)
	return if facing.Magnitude > 1e-3 then facing.Unit else Vector3.new(0, 0, -1)
end

-- Half of how much wider than an R6 body with its arms (4 studs) a lead stands, at most 3: it stands that much further
-- aside, so a broad Voidkin never brushes the avatar.
local function halfOver(f: Fighter): number
	local known = overs[f]
	if known == nil then
		local size = f.Model:GetExtentsSize()
		known = math.clamp(math.max(size.X, size.Z) / 2 - 2, 0, 3)
		overs[f] = known
	end
	return known :: number
end

-- Where a lead stands beside its avatar: Combat.Lead.Side to the right and Ahead in front along the player's camera, at
-- the avatar's height, facing where the camera looks, so it stands out of the camera's line (TR24's fix 3); `f` adds its
-- breadth. In a keeper's try, on the avatar's left along its facing (Combat.Keeper.Side: clear of the Challenge and the
-- fall's line).
local function besideAvatar(avatar: BasePart, owner: Player?, f: Fighter?): CFrame
	if owner and owner:GetAttribute("Try") ~= nil then
		return avatar.CFrame * CFrame.new(Combat.Keeper.Side, 0, 1)
	end
	local look = lookOf(owner, avatar)
	local right = look:Cross(Vector3.yAxis)
	local at = avatar.Position + right * (Combat.Lead.Side + (if f then halfOver(f) else 0)) + look * Combat.Lead.Ahead
	return CFrame.lookAt(at, at + look)
end

local function avatarRoot(f: Fighter): BasePart?
	local owner = f.Owner
	local root = if owner then Parts.Root(owner.Character) else nil
	if root and root:IsDescendantOf(workspace) then
		return root
	end
	return nil
end

-- Where `f` heads to fight `target`, `radius` studs from it: its place among the fighters of its side closing on that
-- target (Rules/Fight.Spread), each wanting to stay where it is, but a lead wanting the target's far side along its
-- avatar's facing, the way the player's camera looks (Fight.Beyond: a Shade comes to the lead at the avatar's side, so the
-- avatar's place would put the fight off the frame's edge; the take of 2026-11-12), and the way there round the target
-- (Fight.Toward). Also how far, in degrees, `f` stands from its place, its place's bearing, and its own.
local function slotFor(f: Fighter, target: Fighter, radius: number): (Vector3, number, number, number)
	local center = target.Root.Position
	local mates: { Fighter } = {}
	for _, other in fighters do
		if other == f or (other.Side == f.Side and other.Target == target and standing(other)) then
			table.insert(mates, other)
		end
	end
	table.sort(mates, function(a: Fighter, b: Fighter): boolean
		return a.Id < b.Id
	end)
	local wants: { number } = {}
	local mine, here = 1, 0
	local beside = (Combat.Lead.Beside :: { [string]: number })[target.Kind]
	local frame = beside or Combat.Lead.Frame
	local near = (Combat.Lead.Near :: { [string]: boolean })[target.Kind] == true
	for index, other in mates do
		local bearing = bearingOf(flat(other.Root.Position - center))
		local avatar = if other.Side == "Lead" then avatarRoot(other) else nil
		local watched = if avatar then -lookOf(other.Owner, avatar) else Vector3.zero -- the side the player watches from
		if avatar and watched.Magnitude > 0.5 and beside then
			local lean = Fight.Wrap(bearingOf(flat(center - avatar.Position)) - bearingOf(watched) - 180)
			wants[index] = Fight.Aside(bearingOf(watched), lean, bearing, frame, Combat.Lead.Straight, near)
		elseif watched.Magnitude > 0.5 then
			wants[index] = Fight.Beyond(bearingOf(watched), bearing, frame)
		else
			wants[index] = bearing
		end
		if other == f then
			mine, here = index, bearing
		end
	end
	local place = Fight.Spread(wants, Combat.Slots.Spacing)[mine]
	local heading = math.rad(Fight.Toward(here, place, Combat.Slots.Step))
	return center + Vector3.new(math.cos(heading), 0, math.sin(heading)) * radius, math.abs(Fight.Wrap(place - here)), place, here
end

-- The hit's push, once the hold is over: the body jumps on the frame it lets go (handbook/feel/combat.md). It goes its
-- distance at a steady pace over Combat.Push.Seconds and stops there, with no slide: each frame's speed is what's left
-- over that frame, so a late timer never carries it on. Each screen draws that same push from its own hold's end
-- (FighterController, Combat.Push.Shown). A newer push takes over from one still running; a wall ends it after
-- Seconds × PUSH_GIVE_UP.
local PUSH_GIVE_UP = 3
local PUSH_SKIN = 0.5 -- studs past the body's side a push looks ahead for the world, so it ends at a wall, never through one

-- Rays that see only the world: never a fighter or an avatar.
local function worldRays(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skipped: { Instance } = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(skipped, player.Character)
		end
	end
	params.FilterDescendantsInstances = skipped
	params.RespectCanCollide = true
	return params
end
local pushing: { [Fighter]: number } = {}
-- The body carried `amount` studs along `unit`, flat, at a steady pace over `seconds`: a hit's push, or a skip's travel.
-- A skip passes `facing`, re-aimed at each frame and held rigid: the think's tick and the Align's responsiveness both
-- trail a bearing that swings this fast up close (about 30 degrees, the skip's self-test).
local function glide(f: Fighter, unit: Vector3, amount: number, seconds: number, facing: Fighter?)
	local token = (pushing[f] or 0) + 1
	pushing[f] = token
	f.Align.RigidityEnabled = facing ~= nil
	local from = f.Root.Position
	local speed = amount / seconds
	local started = os.clock()
	local world = worldRays()
	local side = math.max(f.Root.Size.X, f.Root.Size.Z) / 2 + PUSH_SKIN
	f.Push.VectorVelocity = unit * speed
	f.Push.Enabled = true
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if pushing[f] ~= token then
			connection:Disconnect() -- a newer push has it
			return
		end
		if fighters[f.Id] ~= f then
			connection:Disconnect()
			pushing[f] = nil
			return
		end
		local left = amount - (f.Root.Position - from):Dot(unit)
		local step = math.min(speed, left / math.max(dt, 1 / 240)) * math.max(dt, 1 / 240)
		local wall = left > 0.02 and workspace:Raycast(f.Root.Position, unit * (side + step), world) ~= nil
		if left <= 0.02 or wall or os.clock() - started > seconds * PUSH_GIVE_UP then
			connection:Disconnect()
			pushing[f] = nil
			f.Push.Enabled = false
			f.Align.RigidityEnabled = false
			local v = f.Root.AssemblyLinearVelocity
			f.Root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
			return
		end
		f.Push.VectorVelocity = unit * math.min(speed, left / math.max(dt, 1 / 240))
		if facing and facing.Root.Parent then
			face(f, facing.Root.Position)
		end
	end)
end

-- A glide in progress stopped where it is (a lead broken off mid-carry: TR44).
local function unpush(f: Fighter)
	if pushing[f] then
		pushing[f] = nil -- its Heartbeat sees the token gone and lets go
		f.Push.Enabled = false
		f.Align.RigidityEnabled = false
	end
end

local function push(f: Fighter, direction: Vector3, studs: number, hold: number, seconds: number)
	local weight = (Combat.Weight :: any)[f.Kind] or 1
	local amount = studs * weight
	if amount <= 0 or direction.Magnitude < 0.01 then
		return
	end
	task.delay(hold, function()
		if fighters[f.Id] ~= f then
			return
		end
		if f.State == "Down" then
			f.Humanoid:MoveTo(f.Root.Position + direction.Unit * amount) -- a thrown body doesn't walk back to where it fell
		end
		glide(f, direction.Unit, amount, seconds)
	end)
end

-- A move's carry from its beat (Definitions.Actions, Move; Rules.Fight.MoveEnd), its clip moving in place: a glide over
-- its Seconds, facing its target (a dash in), or set down at once, facing back along its path (a blink). A blink stops
-- short of the first wall on its way and never leaves the ground: over an edge, it stays where it stands.
local function carry(f: Fighter, move: Actions.Move)
	local target = f.ForcedTarget or f.Target -- as its strike's (the replay's is forced)
	if target == nil or not standing(target) then
		return
	end
	local avatar = avatarRoot(f)
	local from = f.Root.Position
	local spot, way = Fight.MoveEnd(from, target.Root.Position, if avatar then avatar.Position else from, move)
	local travel = flat(spot - from)
	if travel.Magnitude < 0.05 then
		return
	end
	if move.Seconds > 0 then
		f.Humanoid:MoveTo(spot) -- so it doesn't walk back to where it started
		glide(f, travel.Unit, travel.Magnitude, move.Seconds, target)
		return
	end
	local world = worldRays()
	local side = math.max(f.Root.Size.X, f.Root.Size.Z) / 2 + PUSH_SKIN
	local wall = workspace:Raycast(from, travel.Unit * (travel.Magnitude + side), world)
	if wall then
		spot = from + travel.Unit * math.max(0, (wall.Position - from):Dot(travel.Unit) - side)
	end
	if workspace:Raycast(spot + Vector3.new(0, 1, 0), Vector3.new(0, -(LEAD_ROOT_HEIGHT + 1 + Combat.Skip.Ground), 0), world) == nil then
		return
	end
	local back = spot - way
	pushing[f] = nil -- a push still running is over
	f.Push.Enabled = false
	f.Align.RigidityEnabled = false
	f.Root.AssemblyLinearVelocity = Vector3.zero
	f.Root.CFrame = CFrame.lookAt(spot, Vector3.new(back.X, spot.Y, back.Z))
	f.Humanoid:MoveTo(spot)
	face(f, back) -- the Align held its old facing, the way it went
end

local fall: (f: Fighter, at: number) -> ()

-- Its most health for the leads that have hit it, and as much added to what it has left (Fight.CrowdHealth): a crowd's
-- further leads each add a share of its health, and a duo fights it as one would (research's verdict on TR2, 2026-11-12).
local function crowd(f: Fighter)
	local leads = 0
	for _ in f.Hitters do
		leads += 1
	end
	local most = Fight.CrowdHealth(f.Alone, leads, Combat.Crowd)
	if most ~= f.Block.Health then
		local added = most - f.Block.Health
		local block = table.clone(f.Block)
		block.Health = most
		f.Block = block
		f.Model:SetAttribute("MaxHealth", most)
		setHealth(f, math.max(0, f.Health + added))
	end
end

-- One target's share of a hit: rolled, dealt, pushed along `line` (from the attacker), and shown to every client. The
-- target's passive may take less (Rook's Second Wind); the attacker's may add to it in its element (Pip's Kindle), shown in
-- the element's number, or crit its first hit to land on the target (Kirra's First Strike).
local function land(f: Fighter, action: Actions.Action, target: Fighter, beat: string, hit: Actions.Hit, at: number, line: Vector3)
	local rolls = { Dodge = rng:NextNumber(), Critical = rng:NextNumber(), Block = rng:NextNumber() }
	local own = passiveOf(f)
	local guard = passiveOf(target)
	local effects: Hit.Effects = {
		Reduction = Passive.Reduction(guard, target.Health, target.Block.Health) + Fight.Shield(target.Shield, at),
		Critical = Passive.Critical(own, not target.Struck[f.Id]),
		Resist = Passive.Resist(guard),
	}
	local result = Hit.Resolve(f.Block, target.Block, hit.Coefficient, rolls, effects)
	if target.Frail then
		-- A fast floor's foe (Rules.Tower.Fast): the first hit that reaches it fells it.
		result.Dodged = false
		result.Total = math.max(result.Total, target.Health)
	end
	if not result.Dodged then
		target.Struck[f.Id] = true
	end
	local extra = Passive.Extra(own, action.Id, beat, result.Physical)
	if extra > 0 then
		result.Elemental += extra
		result.Total += extra
	end
	local left, fell = Fight.Damage(target.Health, result.Total)
	setHealth(target, left)
	-- A hit dealt or taken, dodged or not, keeps its player "in a fight" a while (Rules.Home, TR19: HomeService reads it).
	for _, side in { f, target } do
		if side.Side == "Lead" and side.Owner then
			side.Owner:SetAttribute("HitAt", at)
		end
	end
	if target.Side == "Shade" and f.Side == "Lead" then
		if f.Owner and not target.Hitters[f.Owner] then
			target.Hitters[f.Owner] = true
			crowd(target)
		end
		if target.Pack then
			local hitBy = packHit[target.Pack] or {}
			hitBy[f] = true
			packHit[target.Pack] = hitBy
		end
	end
	-- The hold by the hit's rung, a critical's raised and a killing hit's at least its own (Rules.Fight.Hold; AR8 A)
	local rung = Fight.Rung(hit.Rung, result.Critical, Combat.Hitstop, fell)
	local hold = if result.Dodged then 0 else Fight.Hold(rung, fell, Combat.Hitstop)
	if not result.Dodged then
		if not fell and target.Action == nil and target.State ~= "Stun" and (Combat.Flinch.Kinds :: any)[target.Kind] then
			setState(target, "Flinch", at + hold + Combat.Flinch.Seconds)
			stop(target)
		end
		local stunned = if fell then 0 else Fight.Stun(hit.Stun, Combat.Stun.Share[target.Kind], at, target.StunLock)
		if stunned > 0 then
			-- stopped where it stands: the state first, so a client holds the pose its action was stopped in
			target.StunLock = at + stunned + Combat.Stun.Lock
			target.Model:SetAttribute("StunLook", if hit.Looks then hit.Looks.Stun else nil) -- before State: its look's name
			setState(target, "Stun", at + stunned)
			endAction(target, at)
			stop(target)
		end
		local studs, seconds = Fight.Throw(hit.Push, fell, Combat.Push :: any)
		push(target, line, studs, hold, seconds)
	end
	Net.Server.FireAll("Hit", {
		A = f.Model,
		T = target.Model,
		Action = action.Id,
		Beat = beat,
		Total = result.Total,
		Elemental = result.Elemental,
		Critical = result.Critical,
		Blocked = result.Blocked,
		Dodged = result.Dodged,
		Heavy = hit.Heavy,
		Rung = rung,
		Hold = hold,
		Steady = hit.Steady == true, -- the attacker doesn't hold on it, only the target
		Health = left,
		MaxHealth = target.Block.Health,
		Passive = if extra > 0 and own then own.Id else nil, -- its cue on the attacker (FighterController/Passives)
	})
	if fell then
		fall(target, at)
	end
end

-- Whether `other` stands inside `f`'s cone along `axis`, a flat unit line (Actions.Hit.Cone; Rules.Fight.InCone).
local function inCone(f: Fighter, other: Fighter, axis: Vector3, hit: Actions.Hit): boolean
	local offset = flat(other.Root.Position - f.Root.Position)
	local along = offset:Dot(axis)
	return Fight.InCone(along, (offset - axis * along).Magnitude, hit.Reach, hit.Cone :: number, hit.Apex or 0)
end

-- A beat's heal (Actions.Hit.Heal): the fighter itself, and with a Cone every ally lead standing inside it along `axis`,
-- each mended a share of its own most, and shown to every client.
local function mend(f: Fighter, hit: Actions.Hit, axis: Vector3?, beat: string)
	local healed = { f }
	if hit.Cone and axis then
		for _, other in fighters do
			if other ~= f and other.Side == "Lead" and f.Side == "Lead" and standing(other) and inCone(f, other, axis, hit) then
				table.insert(healed, other)
			end
		end
	end
	for _, other in healed do
		local before = other.Health
		local after = Fight.Mend(before, other.Block.Health, hit.Heal :: number)
		if standing(other) and after > before then
			after = heal(other, after)
			if after > before then
				-- Beat: a client shows an ally's heal when the beat's crest reaches it, as a hit's (TR3; AR4 section 10).
				Net.Server.FireAll("Heal", { A = f.Model, T = other.Model, Beat = beat, Amount = after - before, Health = after, MaxHealth = other.Block.Health })
			end
		end
	end
end

-- A beat's hit on its fighter's target, if it reaches; with an Area, on every enemy standing that near the target too;
-- with a Cone, on every enemy inside it; with a Round, on every enemy round the fighter instead, reaching or not. A heal
-- and a shield come first, and with no target the fighter still heals and shields itself.
local function strike(f: Fighter, beat: string, hit: Actions.Hit, at: number)
	local action = f.Action :: Actions.Action
	local mark = f.Mark
	if hit.Mark and mark then
		-- on its footprint (TR44): every enemy whose centre is inside it, where it stands now, and nothing else
		local struck: { Fighter } = {}
		for _, other in fighters do
			local p = other.Root.Position
			if against(f, other) and standing(other) and MarkRule.Inside(mark.X, mark.Z, mark.Radius, p.X, p.Z) then
				table.insert(struck, other)
			end
		end
		for _, other in struck do
			land(f, action, other, beat, hit, at, flat(other.Root.Position - f.Root.Position))
		end
		takeUp(f, struck)
		return
	end
	local target = f.ForcedTarget or f.Target
	if target ~= nil and not standing(target) then
		target = nil
	end
	local line = if target then flat(target.Root.Position - f.Root.Position) else Vector3.zero
	local gap = line.Magnitude
	if hit.Heal then
		mend(f, hit, if gap > 0.01 then line.Unit else nil, beat)
	end
	local shield = hit.Shield
	if shield then
		f.Shield = { Share = shield.Share, Until = at + shield.Seconds }
		f.Model:SetAttribute("ShieldLook", if hit.Looks then hit.Looks.Shield else nil) -- before its time: its look's name
		f.Model:SetAttribute("ShieldUntil", at + shield.Seconds) -- for its look (Ground Wire's, AR11)
	end
	if hit.Round then
		-- a pulse round the fighter itself: every enemy standing within, its target too, whichever way it faces
		local near = {}
		for _, other in fighters do
			if against(f, other) and standing(other) and Fight.Within(flat(other.Root.Position - f.Root.Position).Magnitude, hit.Round) then
				table.insert(near, other)
			end
		end
		for _, other in near do
			land(f, action, other, beat, hit, at, flat(other.Root.Position - f.Root.Position))
		end
		return
	end
	if target == nil then
		return
	end
	local facing = flat(f.Root.CFrame.LookVector)
	local cosine = if gap > 0.01 and facing.Magnitude > 0.01 then facing.Unit:Dot(line.Unit) else 1
	if not Fight.Reaches(gap, cosine, hit.Reach, Combat.Arc) then
		return -- a whiff: its effect still plays on the beat, with no spark and no number
	end
	local centre = target.Root.Position
	land(f, action, target, beat, hit, at, line)
	if hit.Area then
		local near = {}
		for _, other in fighters do
			if other ~= target and against(f, other) and standing(other) and Fight.Within(flat(other.Root.Position - centre).Magnitude, hit.Area) then
				table.insert(near, other)
			end
		end
		for _, other in near do
			land(f, action, other, beat, hit, at, flat(other.Root.Position - f.Root.Position))
		end
	end
	if hit.Cone and gap > 0.01 then
		local inside = {}
		for _, other in fighters do
			if other ~= target and against(f, other) and standing(other) and inCone(f, other, line.Unit, hit) then
				table.insert(inside, other)
			end
		end
		for _, other in inside do
			land(f, action, other, beat, hit, at, flat(other.Root.Position - f.Root.Position))
		end
	end
end

function fall(f: Fighter, at: number)
	endAction(f, at)
	f.Away = nil
	f.Model:SetAttribute("Away", nil)
	setTarget(f, nil)
	stop(f)
	face(f, nil)
	local hitters = {}
	for player in f.Hitters do
		if player.Parent == Players then
			table.insert(hitters, player)
		end
	end
	if f.Side == "Lead" then
		setState(f, "Down", at + Combat.Lead.Leave) -- then home on its plot (goHome)
	else
		setState(f, "Down")
		task.delay(if f.Kind == "Keeper" then Combat.Keeper.FadeSeconds else Combat.Shade.FadeSeconds, remove, f)
		-- A keeper's fall is the try's ending: the leads on it watch it, facing it, until its Down's Gone, the longest hold
		-- past it, and then turn (AR7, section 5, fix 2).
		local def = Enemies.ById[f.Def]
		local falls = if def and def.Rig then (EffectsConfig.Falls :: any)[def.Rig] else nil
		if f.Kind == "Keeper" and falls then
			for _, other in fighters do
				if other.Side == "Lead" and other.Target == f then
					other.Watch = f.Root.Position
					other.WatchUntil = at + falls.Gone / 60 + Fight.LongestHold(Combat.Hitstop)
				end
			end
		end
	end
	FightService.Fell:Fire(f, hitters)
end

local function rise(f: Fighter, at: number)
	local avatar = avatarRoot(f)
	if avatar then
		f.Root.AssemblyLinearVelocity = Vector3.zero
		f.Root.CFrame = besideAvatar(avatar, f.Owner, f)
	end
	setHealth(f, f.Block.Health)
	f.ReadyAt = {}
	f.Model:SetAttribute("Ready", 0)
	setState(f, "Idle")
	FightService.Rose:Fire(f)
end

-- Where a fallen lead waits on its plot (TR12): on the Training machine's pad (Config.World.Grey.Training), facing it;
-- else on the plot's spawn; nil when its player has no plot (it then waits where it fell).
local function homeSpot(f: Fighter): CFrame?
	local plot = if f.Owner then f.Owner:GetAttribute("Plot") else nil
	if type(plot) ~= "number" then
		return nil
	end
	local machine = Markers.Find("Training", { Plot = plot })
	if machine then
		local at = Markers.At(machine)
		local spot = (at * CFrame.new(0, 0, WorldConfig.Grey.Training.Spot)).Position + Vector3.new(0, LEAD_ROOT_HEIGHT, 0)
		return CFrame.lookAt(spot, Vector3.new(at.Position.X, spot.Y, at.Position.Z))
	end
	local spawn = Markers.Find("Spawn", { Plot = plot })
	return if spawn then Markers.At(spawn) + Vector3.new(0, LEAD_ROOT_HEIGHT, 0) else nil
end

-- The home's times for `player` (Rules.Carry.HomeFor): a fallen lead's wait is short until their first keeper falls
-- (TR24's fix 5). LeadService reads the same.
function FightService.HomeOf(player: Player?): Carry.Home
	local data = if player then DataService.Get(player) else nil
	return Carry.HomeFor(Combat.Lead.Home, if data then data.Progress.Grounds :: any else nil)
end

-- The fall's end (docs/design.md, "A fall sends it home"): it leaves as light (the client's), and is home on its plot,
-- healing from nothing to full in its player's Home.Fallen seconds. StateUntil is when it's whole, for the card's time.
local function goHome(f: Fighter, at: number)
	local spot = homeSpot(f)
	if spot then
		f.Root.AssemblyLinearVelocity = Vector3.zero
		f.Root.CFrame = spot
	end
	f.ReadyAt = {}
	f.Model:SetAttribute("Ready", 0)
	setHealth(f, 0)
	setState(f, "Home", at + FightService.HomeOf(f.Owner).Fallen)
end

-- Whether a player stands on their own plot (Markers.OnPlot).
local function playerHome(player: Player?): boolean
	local plot = if player then player:GetAttribute("Plot") else nil
	local root = if player then Parts.Root(player.Character) else nil
	return Markers.OnPlot(if type(plot) == "number" then plot else nil, if root then root.Position else nil)
end

-- A lead at home: it heals to full at the fallen rate, then waits; once it's whole and its player is on their plot, it's
-- up and follows them.
local function thinkHome(f: Fighter, at: number, dt: number)
	local most = f.Block.Health
	local share = Carry.Mend(if most > 0 then f.Health / most else 0, dt, FightService.HomeOf(f.Owner).Fallen)
	setHealth(f, share * most)
	if Carry.Fallen(f.State, 0, playerHome(f.Owner), Combat.Lead.Leave, share >= 1) == "Idle" then
		setState(f, "Idle")
		FightService.Rose:Fire(f)
	end
end

-- The replay's hold (FightService.Force): true while `f` is held, facing its target and pressing its action on time. A
-- lead or a Shade alike; an action that isn't one ("") holds it still, facing, pressing nothing.
local function forced(f: Fighter, at: number): boolean
	if f.Forced == nil then
		return false
	end
	local target = f.ForcedTarget
	if f.Mark == nil then -- a footprint down: its aim is fixed (TR44)
		face(f, if target then target.Root.Position else nil)
	end
	if target and at >= f.ForcedNext and not busy(f, at) then
		local action = Actions.ById[f.Forced]
		if action then
			if target.Home then -- every press from the same spacing and health: the last one's push and damage undone
				target.Root.AssemblyLinearVelocity = Vector3.zero
				target.Root.CFrame = target.Home
				if target.Health < target.Block.Health then
					setHealth(target, target.Block.Health)
				end
			end
			if action.Moves and f.ForcedHome then -- and the last one's carry (start's stop holds it there)
				f.Root.AssemblyLinearVelocity = Vector3.zero
				f.Root.CFrame = f.ForcedHome
			end
			start(f, action, at)
			local follower = f.ForcedFollower
			if follower and follower.ForcedLag then
				follower.ForcedNext = at + follower.ForcedLag
			end
		end
		f.ForcedNext = if f.ForcedLag then math.huge else at + f.ForcedEvery
	end
	return true
end

-- The skip back's clear spot (Combat.Skip): on the ground, no wall on the way or where it lands, within the leash, no
-- enemy within Close, and the way never nearer an enemy than Body (Rules.Fight.SkipKeepsClear).
local function skipClear(f: Fighter, spot: Vector3, avatar: BasePart, enemies: { Fighter }): boolean
	local skip = Combat.Skip
	if flat(spot - avatar.Position).Magnitude > Combat.Lead.Leash then
		return false
	end
	for _, enemy in enemies do
		local at = enemy.Root.Position
		if flat(spot - at).Magnitude < skip.Close or not Fight.SkipKeepsClear(f.Root.Position, spot, at, skip.Body) then
			return false
		end
	end
	local ignore = worldRays()
	local from = f.Root.Position
	local way = flat(spot - from)
	if way.Magnitude > 1e-3 and workspace:Spherecast(from, skip.Body / 2, way, ignore) then
		return false -- a wall or a stall on the way
	end
	local ground = workspace:Raycast(spot + Vector3.new(0, 1, 0), Vector3.new(0, -(LEAD_ROOT_HEIGHT + 1 + skip.Ground), 0), ignore)
	return ground ~= nil
end

-- A ranged lead's skip back (docs/design.md, "Combat"; Rules.Fight.ShouldSkip): back to its place in the frame at its
-- next action's range from `target`, or the nearest clear spot at that range, travelling from its start to Land. True if
-- it skipped.
local function trySkip(f: Fighter, target: Fighter, avatar: BasePart, at: number): boolean
	local skip = Actions.SkipOf(f.Def)
	if skip == nil or not Combat.Skip.On then
		return false
	end
	local enemies: { Fighter } = {}
	local nearest, windingUp = math.huge, false
	for _, other in fighters do
		if other.Side ~= f.Side and other.Kind ~= "Dummy" and standing(other) then
			table.insert(enemies, other)
			nearest = math.min(nearest, distance(f.Root, other.Root))
			local swing = other.Action
			if other.Target == f and swing then
				for beat in swing.Hits do
					windingUp = windingUp or at - other.ActionAt < swing.Beats[beat]
				end
			end
		end
	end
	if not Fight.ShouldSkip(nearest, at - f.SkippedAt, windingUp, Combat.Skip) then
		return false
	end
	local next = Fight.Choose(f.Kit, f.ReadyAt, at)
	local radius = math.max(0, (if next then next.Range else 4) - Combat.Approach)
	local _, _, place, here = slotFor(f, target, radius)
	local center = target.Root.Position
	for _, bearing in Fight.SkipBearings(place, Combat.Skip.Step, here) do
		local heading = math.rad(bearing)
		local spot = Vector3.new(center.X + math.cos(heading) * radius, f.Root.Position.Y, center.Z + math.sin(heading) * radius)
		if skipClear(f, spot, avatar, enemies) then
			start(f, skip, at)
			f.SkippedAt = at
			f.Humanoid:MoveTo(spot) -- so it doesn't walk back to where it stood once it lands
			local way = flat(spot - f.Root.Position)
			if way.Magnitude > 0.05 then
				glide(f, way.Unit, way.Magnitude, skip.Beats.Land, target)
			end
			return true
		end
	end
	return false -- cornered or surrounded: it fights where it stands
end

-- A lead's turn to decide.
local function thinkLead(f: Fighter, at: number, dt: number)
	local avatar = avatarRoot(f)
	if forced(f, at) then
		return
	end
	if avatar == nil then
		stop(f)
		return
	end
	-- Health carries (TR12): on its owner's plot the heal at home, and its Regen always, in bursts (TR40): one every
	-- Config.Stats.Regen.Every seconds from its summon, in a fight too, a hit never resetting it. A burst at full heals
	-- nothing and shows nothing; one that heals shows its number and its pop to everyone near (FighterController).
	local plot = if f.Owner then f.Owner:GetAttribute("Plot") else nil
	local home = Markers.OnPlot(if type(plot) == "number" then plot else nil, f.Root.Position)
	heal(f, Fight.Regen(f.Health, f.Block.Health, Fight.HomeRate(f.Block.Health, home, Combat.Lead.Home.Full), dt))
	local due, nextDue = Fight.BurstDue(f.RegenAt, at, StatsConfig.Regen.Every)
	f.RegenAt = nextDue
	if due then
		local before = f.Health
		local after = heal(f, Fight.Burst(before, f.Block.Health, Stats.Burst(f.Block.Regen)))
		if after > before then
			Net.Server.FireAll("Heal", { A = f.Model, T = f.Model, Amount = after - before, Health = after, MaxHealth = f.Block.Health, Regen = true })
		end
	end
	local toAvatar = (avatar.Position - f.Root.Position).Magnitude -- in three dimensions: an avatar teleported straight up still pulls its lead
	-- The fight in the camera's view (TR24's fix 2): each enemy's degrees off the camera's look, from the avatar.
	local looking = bearingOf(lookOf(f.Owner, avatar))
	local function offView(other: Fighter): number
		local offset = flat(other.Root.Position - avatar.Position)
		return if offset.Magnitude > 1e-3 then Fight.Off(bearingOf(offset), looking) else 0
	end
	local candidates: { Fight.Candidate } = {}
	for _, other in fighters do
		if other.Side == "Shade" and other.Kind ~= "Dummy" and standing(other) and against(f, other) then
			table.insert(candidates, {
				Id = other.Id,
				Distance = distance(f.Root, other.Root),
				Reach = distance(avatar, other.Root),
				Off = offView(other),
				Engaged = other.Target == f,
			})
		end
	end
	local targetId = Fight.LeadTarget(candidates, if f.Target then f.Target.Id else nil, Combat.Lead.Leash, Combat.Lead.View)
	setTarget(f, if targetId then fighters[targetId] else nil)
	local mode = Fight.LeadMode(toAvatar, f.Target ~= nil, Combat.Lead)
	if mode == "Teleport" then
		endAction(f, at)
		f.Root.AssemblyLinearVelocity = Vector3.zero
		f.Root.CFrame = besideAvatar(avatar, f.Owner, f)
		return
	end
	if f.State == "Flinch" then
		return
	end
	-- Broken off for its place by the avatar (TR44's A and B; FightService.Away): it goes there, and holds, then fights.
	local away = f.Away
	if away then
		local place = besideAvatar(avatar, f.Owner, f).Position
		local gap = flat(place - f.Root.Position).Magnitude
		if away.Arrived == nil and (gap < AWAY_THERE or at - away.Since >= away.Most) then
			away.Arrived = at
		end
		local over = if away.Until then at >= away.Until else (away.Arrived ~= nil and at >= away.Arrived + away.Hold)
		if over then
			f.Away = nil
			f.Model:SetAttribute("Away", nil)
		else
			if gap >= AWAY_THERE and (away.Until ~= nil or away.Arrived == nil) then
				face(f, nil)
				moveTo(f, Vector3.new(place.X, f.Root.Position.Y, place.Z), away.Speed)
			else
				stop(f)
				face(f, if f.Target then f.Target.Root.Position else nil)
			end
			return
		end
	end
	local target = f.Target
	if mode == "Fight" and target then
		face(f, target.Root.Position)
		if busy(f, at) then
			return
		end
		if trySkip(f, target, avatar, at) then
			return
		end
		local action = Fight.Choose(f.Kit, f.ReadyAt, at)
		local range = if action then action.Range else 4
		local gap = distance(f.Root, target.Root)
		local slot, off = slotFor(f, target, math.max(0, range - Combat.Approach))
		-- after a skip it fires from where it lands while its target is in range, and never walks in again (Combat.Skip)
		local landed = at - f.SkippedAt < Combat.Skip.Every
		if action and gap <= action.Range and (off <= Combat.Slots.Arc or landed) then
			start(f, action, at)
		elseif landed and action == nil then
			-- landed with nothing ready yet: it holds where it landed, as a walk to its slot would take it back in (the
			-- skip's case saw it drift 0.8 studs on Land, sometimes, 2026-11-15)
			endAction(f, at)
			stop(f)
		else
			endAction(f, at)
			local walk = if f.Block.Speed > 0 then f.Block.Speed else Combat.Lead.FollowWalk -- its Speed (TR14)
			-- An enemy on it from out of the camera's view: it waits for it in view, at its place by the avatar, rather
			-- than walking off the frame to meet it, View.Wait seconds at most (TR24's fix 2).
			local waiting = waits[f]
			if target.Target == f and offView(target) > Combat.Lead.View.Arc then
				if waiting == nil or waiting.Target ~= target then
					waiting = { Target = target, Since = at }
					waits[f] = waiting
				end
			else
				waiting = nil
				waits[f] = nil
			end
			if waiting and at - waiting.Since < Combat.Lead.View.Wait then
				local place = besideAvatar(avatar, f.Owner, f).Position
				moveTo(f, Vector3.new(place.X, f.Root.Position.Y, place.Z), Fight.LeadSpeed(toAvatar, walk, Combat.Lead))
			else
				moveTo(f, Vector3.new(slot.X, f.Root.Position.Y, slot.Z), Fight.LeadSpeed(toAvatar, walk, Combat.Lead))
			end
		end
		return
	end
	-- Follow: nothing to fight near the avatar; first, a keeper it felled watched to its end.
	if busy(f, at) then
		return
	end
	local watch = f.Watch
	if watch and at < f.WatchUntil and toAvatar <= Combat.Lead.Leash then
		endAction(f, at)
		stop(f)
		face(f, watch)
		return
	end
	f.Watch = nil
	waits[f] = nil
	-- Its place beside the avatar, along the camera (TR24's fix 3): it walks there once the avatar is Follow away or the
	-- place has moved Settle from it (the camera turned), and there faces where the camera looks. The watch over, it
	-- turns from the fall and goes back to its place however near it stands: a lead within Follow would otherwise keep
	-- facing where the keeper fell.
	local place = besideAvatar(avatar, f.Owner, f)
	local fromPlace = flat(place.Position - f.Root.Position).Magnitude
	if toAvatar > Combat.Lead.Follow or fromPlace > Combat.Lead.Settle or watch then
		face(f, nil)
		endAction(f, at)
		moveTo(f, place.Position, Fight.LeadSpeed(toAvatar, Combat.Lead.FollowWalk, Combat.Lead))
	elseif fromPlace < 1 then
		face(f, f.Root.Position + place.LookVector)
	end
end

-- A Shade's turn to decide.
local function thinkShade(f: Fighter, at: number)
	local home = f.Home
	if f.Kit[1] == nil or home == nil then
		return -- a dummy stands and takes it
	end
	if f.State ~= "Flinch" and forced(f, at) then
		return
	end
	local fromHome = flat(f.Root.Position - home.Position).Magnitude
	if f.State == "Reset" then
		if fromHome < 2 then
			f.Hitters = {}
			f.Struck = {} -- fought anew: an Opener's first hit again
			crowd(f) -- back to its health alone
			setHealth(f, f.Block.Health)
			if f.Pack then
				packHit[f.Pack] = nil
			end
			setState(f, "Idle")
			face(f, home.Position + home.LookVector)
		else
			local stuck
			f.ResetClosest, f.ResetSince, stuck = Fight.ResetStuck(f.ResetClosest, f.ResetSince, fromHome, at, Combat.Shade.ResetStuck.Gain, Combat.Shade.ResetStuck.Seconds)
			if stuck then
				-- a wall between it and home that a straight walk can't pass: it's set down there, out of the fight
				stop(f)
				f.Model:PivotTo(home)
				f.ResetClosest, f.ResetSince = 0, at
			else
				moveTo(f, home.Position, Combat.Shade.ResetSpeed)
			end
		end
		return
	end
	if f.State == "Flinch" then
		return
	end
	-- A keeper is fought alone in its own copy of the ring (KeeperService): it comes for its challenger at once, and nothing
	-- in the copy is far enough to make it give up. Copies stand 600 studs apart, so it never sees another player's lead.
	local keeper = f.Kind == "Keeper"
	-- A Tower floor's foe is fought the same way, alone on its platform: at once, and never given up (TR29).
	local alone = keeper or f.For ~= nil
	if f.Target and not alone and Fight.GivesUp(fromHome, Combat.Shade.GiveUp) then
		endAction(f, at)
		setTarget(f, nil)
		face(f, nil)
		setState(f, "Reset")
		moveTo(f, home.Position, Combat.Shade.ResetSpeed)
		return
	end
	local struck = if f.Pack then packHit[f.Pack] else nil
	local candidates: { Fight.Candidate } = {}
	for _, lead in leads do
		if standing(lead) and against(f, lead) then
			table.insert(candidates, {
				Id = lead.Id,
				Distance = distance(f.Root, lead.Root),
				Reach = 0,
				Aggrieved = struck ~= nil and struck[lead] == true,
				Fighting = standing(lead.Target),
			})
		end
	end
	local notice = if alone then Combat.Keeper.Notice else Combat.Shade.Notice
	local targetId = Fight.ShadeTarget(candidates, if f.Target then f.Target.Id else nil, notice, if alone then nil else Combat.Shade.Lose, alone or Combat.Shade.NoticeIdle)
	setTarget(f, if targetId then fighters[targetId] else nil)
	local target = f.Target
	if target == nil then
		if busy(f, at) then
			return
		end
		face(f, nil)
		if f.For == nil and (fromHome > 2 or f.Health < f.Block.Health) then
			setState(f, "Reset") -- left alone: it goes home and heals (a Tower's foe stands its ground)
		end
		return
	end
	if f.Mark == nil then -- a footprint down: its aim is fixed from its Aim beat (TR44)
		face(f, target.Root.Position)
	end
	if busy(f, at) then
		return
	end
	local action = Fight.Choose(f.Kit, f.ReadyAt, at)
	local range = if action then action.Range else 4
	local gap = distance(f.Root, target.Root)
	local slot, off = slotFor(f, target, math.max(0, range - Combat.Approach))
	if action and gap <= action.Range and off <= Combat.Slots.Arc then
		start(f, action, at)
	else
		endAction(f, at)
		local walk = if f.For and f.Block.Speed > 0 then f.Block.Speed elseif keeper then Combat.Keeper.WalkSpeed else Combat.Shade.WalkSpeed
		moveTo(f, Vector3.new(slot.X, f.Root.Position.Y, slot.Z), walk)
	end
end

-- A marked strike's footprint put down on its action's Aim beat (TR44; Config.Combat.Keeper.Mark): where its Mark hit
-- will land, from where the fighter faces now. Its aim is held there: the turn it was still making is stopped.
local function putDown(f: Fighter, action: Actions.Action)
	local slam: number? = nil
	for beat, hit in action.Hits do
		if hit.Mark then
			slam = action.Beats[beat]
		end
	end
	local aim = action.Aim
	if slam == nil or aim == nil then
		return
	end
	local mark = Combat.Keeper.Mark
	local look = flat(f.Root.CFrame.LookVector)
	if look.Magnitude > 0.05 then
		f.Humanoid.AutoRotate = false
		f.Align.CFrame = CFrame.lookAt(Vector3.zero, look.Unit)
		f.Align.Enabled = true
	end
	local p = f.Root.Position
	local x, z = MarkRule.Centre(p.X, p.Z, look.X, look.Z, mark.Ahead, mark.Left)
	local m: Mark = { X = x, Z = z, Y = p.Y, Radius = mark.Radius, Down = f.ActionAt + action.Beats[aim], Slam = f.ActionAt + slam, Target = f.Target }
	f.Mark = m
	f.Model:SetAttribute("MarkAt", Vector3.new(x, p.Y, z))
	f.Model:SetAttribute("MarkRadius", m.Radius)
	f.Model:SetAttribute("MarkDown", m.Down)
	f.Model:SetAttribute("MarkSlam", m.Slam) -- last: a client draws it on this one's change
	FightService.Marked:Fire(f, m)
end

local function step()
	local at = now()
	for _, f in fighters do
		if f.State == "Down" then
			if f.Side == "Lead" and Carry.Fallen("Down", at - (f.StateUntil - Combat.Lead.Leave), false, Combat.Lead.Leave, false) == "Home" then
				goHome(f, at)
			end
			continue
		end
		if f.State == "Home" then
			if at >= f.NextThink then
				local dt = Combat.Think + (at - f.NextThink)
				f.NextThink = at + Combat.Think
				thinkHome(f, at, dt)
			end
			continue
		end
		if f.State == "Stun" then
			if at < f.StateUntil then
				continue -- stopped: no beat, no step, no thought (Actions.Hit.Stun)
			end
			setState(f, "Idle")
		end
		if f.State == "Flinch" and at >= f.StateUntil then
			setState(f, "Idle")
		end
		local action = f.Action
		if action then
			local clock = at - f.ActionAt
			for _, beat in Fight.BeatsBetween(action, f.Checked, clock) do
				local move = if action.Moves then action.Moves[beat] else nil
				if move and f.Action == action then
					carry(f, move)
				end
				local hit = action.Hits[beat]
				if hit and f.Action == action then
					strike(f, beat, hit, at)
				end
				if beat == action.Aim and f.Action == action then
					putDown(f, action)
				end
			end
			if f.Action == action then
				f.Checked = clock
				if clock >= action.Length then
					endAction(f, at)
				end
			end
		end
		if at >= f.NextThink then
			local dt = Combat.Think + (at - f.NextThink)
			f.NextThink = at + Combat.Think
			if fighters[f.Id] == f and f.State ~= "Down" then
				if f.Side == "Lead" then
					thinkLead(f, at, dt)
				else
					thinkShade(f, at)
				end
			end
		end
	end
end

-- A lead for `player`, from its stat block, beside the avatar, at `share` of its most health (what it carried in: TR12;
-- whole when nil). Replaces any lead the player had.
function FightService.SpawnLead(player: Player, block: Stats.Block, title: string, share: number?): Fighter
	local old = leads[player]
	if old then
		remove(old)
	end
	local model, rig = buildLead(block.Def, `Lead_{player.UserId}`)
	local avatar = Parts.Root(player.Character)
	model:PivotTo(if avatar then besideAvatar(avatar, player) else CFrame.new(0, 10, 0))
	local f = register(model, "Lead", "Lead", block.Def, block, Actions.KitOf(block.Def), title, player, rig)
	if share and share < 1 then
		setHealth(f, block.Health * math.clamp(share, 0, 1))
	end
	leads[player] = f
	return f
end

-- A new stat block for a fighter, its health kept as a share (a level gained, or later a gear change out of a fight).
function FightService.SetBlock(f: Fighter, block: Stats.Block)
	local share = Fight.Rescale(f.Health, f.Block.Health, block.Health)
	f.Block = block
	f.Model:SetAttribute("Level", block.Level)
	f.Model:SetAttribute("MaxHealth", block.Health)
	setHealth(f, if f.State == "Down" then 0 else share)
end

-- An enemy of row `def` at `level`, standing at `at`, which is also its home. `options` gives its type and its pack.
-- options.For: fought by that player's lead alone (a Hard stage's foe, TR43), as a Tower floor's.
function FightService.SpawnEnemy(def: string, level: number, at: CFrame, options: { Type: string?, Pack: string?, Ground: string?, Stage: number?, For: Player? }?): Fighter
	local row = assert(Enemies.ById[def], `no enemy {def}`)
	local block = Stats.Enemy(def, level, if options then options.Type else nil)
	local kit = if row.Action then { Actions.ById[row.Action] } else {}
	if row.Signature then
		table.insert(kit, 1, Actions.ById[row.Signature]) -- tried first, whenever it's ready (TR44)
	end
	local name = `{row.Id}_{level}`
	local model, up
	if row.Rig == "Box" then
		model = buildBox(row, name)
		up = (row.Size :: { number })[2] / 2 + 0.1
	else
		model = if row.Rig == "Shade" then buildShade(row, name, block.Type) else buildRig(row, name, block.Type)
		up = SHADE_ROOT_HEIGHT * (row.Scale or 1) + 0.05 -- the rig's feet on the floor
	end
	model:PivotTo(at + Vector3.new(0, up, 0))
	local f = register(model, "Shade", row.Kind, def, block, kit, row.Name, nil, row.Rig)
	f.Home = model:GetPivot()
	f.Pack = if options then options.Pack else nil
	f.Ground = if options then options.Ground else nil
	f.Stage = if options then options.Stage else nil
	model:SetAttribute("Type", block.Type)
	model:SetAttribute("Stage", f.Stage)
	if options and options.For then
		f.For = options.For
		model:SetAttribute("For", options.For.UserId)
	end
	if row.Enter then
		-- held to its end before it does anything else: busy() keeps it from walking or striking (the keeper's Challenge)
		start(f, Actions.ById[row.Enter], now())
	end
	if row.Signature then
		-- its first, First seconds after its Enter ends (TR44)
		local enter = if row.Enter then Actions.ById[row.Enter].Length else 0
		f.ReadyAt[row.Signature] = now() + enter + Combat.Keeper.First
	end
	return f
end

-- A Tower floor's foe for `player` (TR29): Voidkin `block.Def`'s own body in an enemy look, on its block, standing at
-- `at`, which is also its home. Only `player`'s lead fights it, and it fights no other; it drops nothing (no Ground).
function FightService.SpawnRival(player: Player, block: Stats.Block, at: CFrame, title: string): Fighter
	local model, rig = buildLead(block.Def, `Rival_{player.UserId}`)
	-- The enemy look in grey: darkened with a void tint over the body. A Highlight, so the client's own glows (its
	-- signature's EmissiveStrength) and its hit flash keep working. The finish gives it its void light.
	local look = Instance.new("Highlight")
	look.Name = "RivalLook"
	look.FillColor = Color3.fromRGB(18, 10, 32)
	look.FillTransparency = 0.4
	look.OutlineColor = Color3.fromRGB(140, 96, 255)
	look.OutlineTransparency = 0.35
	look.DepthMode = Enum.HighlightDepthMode.Occluded
	look.Adornee = model
	look.Parent = model
	model:PivotTo(at)
	local f = register(model, "Shade", "Rival", block.Def, block, Actions.KitOf(block.Def), title, nil, rig)
	f.Home = model:GetPivot()
	f.For = player
	model:SetAttribute("For", player.UserId)
	model:SetAttribute("Type", block.Type)
	return f
end

-- A lead fought alone, or not (TR43, a Hard stage's): it takes only its player's own foes (For), and no other foe takes
-- it. Its target dropped when it changes.
function FightService.SetSolo(player: Player, alone: boolean)
	local f = leads[player]
	if f and (f.Solo == true) ~= alone then
		f.Solo = if alone then true else nil
		setTarget(f, nil)
	end
end

-- Sets what `f` may still heal (the Tower's cap for its floor), or nil for no cap.
function FightService.SetHealRoom(f: Fighter, room: number?)
	f.HealRoom = room
end

-- Makes `f` fall to the first hit that lands on it (a Tower's fast floor).
function FightService.SetFrail(f: Fighter, frail: boolean)
	f.Frail = frail
end

-- Whether `player`'s lead and its Regalia are frozen (D10): through a keeper's try, and a Tower run from its first floor
-- to its end.
function FightService.Frozen(player: Player): boolean
	return player:GetAttribute("Try") ~= nil or player:GetAttribute("Tower") ~= nil
end

function FightService.Remove(f: Fighter)
	remove(f)
end

-- Studio's tests: `f` falls at once, as if hit to nothing. Its hitters are whoever hit it before.
function FightService.Defeat(f: Fighter)
	if fighters[f.Id] == f and f.State ~= "Down" then
		setHealth(f, 0)
		fall(f, now())
	end
end

-- Whether `f` is up and in the world: not down, not at home, not walking home after giving up.
function FightService.Standing(f: Fighter?): boolean
	return standing(f)
end

-- Whether `player` is in combat (TR12: the lead never changes in one): in a keeper's try, or their lead standing with a
-- target, or a Shade's target.
function FightService.InCombat(player: Player): boolean
	if player:GetAttribute("Try") ~= nil then
		return true
	end
	local lead = leads[player]
	if lead == nil or not standing(lead) then
		return false
	end
	if standing(lead.Target) then
		return true
	end
	for _, other in fighters do
		if other.Side == "Shade" and other.Target == lead and standing(other) then
			return true
		end
	end
	return false
end

-- InCombat for the client's Base tile (TR19, research's verdict: "In a fight" is InCombat or a hit's tail), as the
-- player's Engaged attribute, written only when it changes.
local function publishEngaged()
	for _, player in Players:GetPlayers() do
		local engaged = FightService.InCombat(player)
		if (player:GetAttribute("Engaged") == true) ~= engaged then
			player:SetAttribute("Engaged", if engaged then true else nil)
		end
	end
end

-- Studio's tests: a fallen lead back up at its avatar's side at once, whole, as the old quick return was (the way home
-- takes a walk to the plot, which a case on the test pad can't make).
function FightService.Recall(f: Fighter)
	if fighters[f.Id] == f and f.Side == "Lead" and (f.State == "Down" or f.State == "Home") then
		rise(f, now())
	end
end

-- Studio's tests: `player`'s lead out of any fight at once: its target dropped, every Shade on it sent back to its post,
-- and the lead set down beside its avatar (a case that starts after a fight: TR19's after its take, since a lead with a
-- target is "In a fight").
function FightService.Calm(player: Player)
	local lead = leads[player]
	if lead == nil or fighters[lead.Id] ~= lead then
		return
	end
	setTarget(lead, nil)
	for _, other in fighters do
		if other.Side == "Shade" and other.Target == lead then
			setTarget(other, nil)
			if standing(other) then
				setState(other, "Reset")
			end
		end
	end
	local avatar = Parts.Root(player.Character)
	if avatar and standing(lead) then
		lead.Model:PivotTo(besideAvatar(avatar, player, lead))
	end
end

-- Studio's tests: `f` at `share` of its most health, standing (a heal's case needs a lead that's hurt).
-- A heal of `amount` through the fighter's HealRoom, as every heal in a fight goes (the debug bridge's, TR46).
function FightService.Heal(f: Fighter, amount: number)
	if fighters[f.Id] == f and f.State ~= "Down" and amount > 0 then
		heal(f, math.min(f.Health + amount, f.Block.Health))
	end
end

function FightService.SetHealthShare(f: Fighter, share: number)
	if fighters[f.Id] == f and f.State ~= "Down" and share > 0 and share <= 1 then
		setHealth(f, f.Block.Health * share)
	end
end

function FightService.LeadOf(player: Player): Fighter?
	return leads[player]
end

function FightService.Get(id: string): Fighter?
	return fighters[id]
end

function FightService.All(): { [string]: Fighter }
	return fighters
end

-- TR44's ways out of a mark (SlamService): `f`, a standing lead, breaks off what it was doing (its combo lost, a carry
-- stopped) and goes to its place by its avatar at `speed`, then holds there until `untilAt` (A: the Slam), or else `hold`
-- seconds once it arrives, at most `most` seconds on the way (B: the Recall's dash). False when it can't.
function FightService.Away(f: Fighter, speed: number, untilAt: number?, hold: number?, most: number?): boolean
	if fighters[f.Id] ~= f or f.Side ~= "Lead" or not standing(f) or f.State == "Home" then
		return false
	end
	local at = now()
	endAction(f, at)
	unpush(f)
	f.Away = { Speed = speed, Until = untilAt, Hold = hold or 0, Most = most or math.huge, Since = at, Arrived = nil }
	f.Model:SetAttribute("Away", true)
	return true
end

-- The replay's hold on a lead (Studio): `action` every `every` seconds against `target`, standing still; nil lets it go.
function FightService.Force(f: Fighter, action: string?, every: number?, target: Fighter?)
	endAction(f, now()) -- a clean start: what it was doing lands nothing on the new target
	f.Forced = action
	f.ForcedEvery = every or 0
	f.ForcedNext = now()
	f.ForcedTarget = target
	f.ForcedHome = if action then f.Root.CFrame else nil
	f.ForcedLag = nil
	f.ForcedFollower = nil
	showTarget(f)
	if action == nil then
		face(f, nil)
	end
end

-- The replay's foe (ReplayService: a Shade in place of the dummy). `f`, held by Force already, presses its action `lag`
-- seconds after each press of `leader`, within a think, never on its own clock. So its swing meets the leader's beat at the
-- same moment every press, without drifting: AR11's retake, a brawler stopped mid-swing.
function FightService.Follow(f: Fighter, leader: Fighter, lag: number)
	leader.ForcedFollower = f
	f.ForcedLag = math.max(0, lag)
	f.ForcedNext = math.huge
end

function FightService.Init()
	PhysicsService:RegisterCollisionGroup(GROUP_FIGHTERS)
	PhysicsService:RegisterCollisionGroup(GROUP_AVATARS)
	PhysicsService:CollisionGroupSetCollidable(GROUP_FIGHTERS, GROUP_FIGHTERS, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_FIGHTERS, GROUP_AVATARS, false)
	folder = Instance.new("Folder")
	folder.Name = "Fighters"
	folder.Parent = workspace
	if RunService:IsStudio() then
		-- Studio only: the baked clips (RBX_ANIMSAVES.R6.NL_*, tools/studio/Animations/Author.luau) handed to every client,
		-- which registers the unpublished ones (FighterController/Clips.luau). Live, clips play from their ids.
		local saves = game:GetService("ServerStorage"):FindFirstChild("RBX_ANIMSAVES")
		local r6 = if saves then saves:FindFirstChild("R6") else nil
		local clips = Instance.new("Folder")
		clips.Name = "NL_Clips"
		if r6 then
			for _, sequence in r6:GetChildren() do
				if sequence:IsA("KeyframeSequence") and string.sub(sequence.Name, 1, 3) == "NL_" then
					sequence:Clone().Parent = clips
				end
			end
		end
		clips.Parent = ReplicatedStorage
	end
end

function FightService.Start()
	local function onCharacter(character: Model)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = GROUP_AVATARS
			end
		end
		character.DescendantAdded:Connect(function(part: Instance)
			if part:IsA("BasePart") then
				part.CollisionGroup = GROUP_AVATARS
			end
		end)
	end
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			onCharacter(player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	-- Where each player's camera looks (TR24's fixes 2 and 3): a flat bearing in degrees, atan2(Z, X).
	Net.Server.On("View", function(player: Player, bearing: any)
		if type(bearing) ~= "number" or bearing ~= bearing or math.abs(bearing) > 360 then
			return
		end
		local r = math.rad(bearing)
		views[player] = { Look = Vector3.new(math.cos(r), 0, math.sin(r)), At = os.clock() }
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		views[player] = nil
		local lead = leads[player]
		if lead then
			remove(lead)
		end
		for _, f in fighters do
			f.Hitters[player] = nil
		end
	end)
	RunService.Heartbeat:Connect(step)
	RunService.Heartbeat:Connect(publishEngaged)
end

return FightService
