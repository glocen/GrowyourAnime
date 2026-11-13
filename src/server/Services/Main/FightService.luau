--!strict
-- FightService (server): every fighter in the world, the lead, the Shades and the keeper, run by one module
-- (docs/engineering-plan.md, "Reusable modules"). The server decides every hit (Shared.Rules.Hit, rolled with its own
-- Random) and every choice (Shared.Rules.Fight); clients only present it.
-- What clients read, as attributes on each fighter's model: Fighter (its id), Side, Def, Kind, Rig, Title, Level, Owner
-- (a lead's UserId), Health, MaxHealth, State, StateUntil (server time it ends, 0 for open-ended: a fallen lead's return),
-- Target (a fighter id or ""), Action and ActionAt. ActionAt is written last,
-- so a client reads the action on its change. Each hit, landed or dodged, goes to every client as the Hit event.
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
local Voidkin = require(Shared.Definitions.Voidkin)
local Combat = require(Shared.Config.Combat)
local Shades = require(Shared.Config.Shades)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Fight = require(Shared.Rules.Fight)

export type State = "Idle" | "Flinch" | "Down" | "Reset"

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
	LastHurt: number, -- it last took a hit (Combat.Lead.Heal)
	NextThink: number,
	Home: CFrame?, -- a Shade's spawn
	Pack: string?,
	Ground: string?, -- the ground an enemy stands in, whose drops it gives (Rules.Drops); nil drops nothing
	Hitters: { [Player]: boolean }, -- players whose lead hit it: a pack belongs to everyone (docs/design.md)
	Alone: number, -- its most health with one or two leads on it; a crowd adds to it (Fight.CrowdHealth)
	-- The replay's (Studio): one action on a timer, against one target, standing still.
	Forced: string?,
	ForcedEvery: number,
	ForcedNext: number,
	ForcedTarget: Fighter?,
}

local FightService = {
	Priority = 30, -- after DataService and BaseService
}

FightService.Fell = Signal.new() -- (fighter, hitters: { Player }) once a fighter falls; a Shade is gone FadeSeconds later
FightService.Rose = Signal.new() -- (fighter) a lead back up at its avatar's side

local GROUP_FIGHTERS = "Fighters"
local GROUP_AVATARS = "Avatars"
local GREY = Color3.fromRGB(163, 162, 165)
local SHADE_BODY = Color3.fromRGB(46, 46, 52)
local SHADE_MASK = Color3.fromRGB(214, 214, 214)
local SHADE_ROOT_HEIGHT = 3 -- the Shade rig's root above its feet, at scale 1 (the recipe's frame)

local rng = Random.new()
local fighters: { [string]: Fighter } = {}
local byModel: { [Model]: Fighter } = {}
local leads: { [Player]: Fighter } = {}
local packHit: { [string]: { [Fighter]: boolean } } = {} -- the leads that hit a pack, until it resets
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
	return f ~= nil and fighters[f.Id] == f and f.State ~= "Down" and f.State ~= "Reset"
end

local function setState(f: Fighter, state: State, untilTime: number?)
	f.State = state
	f.StateUntil = untilTime or 0
	f.Model:SetAttribute("StateUntil", f.StateUntil) -- before State: a client reads both on State's change
	f.Model:SetAttribute("State", state)
end

local function setHealth(f: Fighter, health: number)
	f.Health = health
	f.Model:SetAttribute("Health", health)
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

local function endAction(f: Fighter, at: number)
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
	if action.Cooldown > 0 then
		f.ReadyAt[action.Id] = at + action.Cooldown
		-- The signature's ring on the HUD fills from here (docs/ui.md; TR3): when it's ready again, in server time.
		f.Model:SetAttribute("Ready", at + action.Cooldown)
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
		LastHurt = -math.huge,
		NextThink = at + rng:NextNumber() * Combat.Think, -- spread over the tick
		Home = nil,
		Pack = nil,
		Ground = nil,
		Hitters = {},
		Alone = block.Health,
		Forced = nil,
		ForcedEvery = 0,
		ForcedNext = 0,
		ForcedTarget = nil,
	}
	model:SetAttribute("Fighter", id)
	model:SetAttribute("Side", side)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Def", def)
	model:SetAttribute("Rig", rig or (if side == "Lead" then "R6" else "Box"))
	model:SetAttribute("Title", title)
	model:SetAttribute("Level", block.Level)
	-- The signature: the kit's action with a cooldown, for the HUD's ring (TR3). 0 without one.
	local cooldown = 0
	for _, action in kit do
		cooldown = math.max(cooldown, action.Cooldown)
	end
	model:SetAttribute("Cooldown", cooldown)
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

-- Where a lead stands beside its avatar: a little to the right and behind, at the avatar's height.
local function besideAvatar(avatar: BasePart): CFrame
	local side = Combat.Lead.Side
	return avatar.CFrame * CFrame.new(side, 0, 1)
end

local function avatarRoot(f: Fighter): BasePart?
	local owner = f.Owner
	local root = if owner then Parts.Root(owner.Character) else nil
	if root and root:IsDescendantOf(workspace) then
		return root
	end
	return nil
end

local function bearingOf(offset: Vector3): number
	return math.deg(math.atan2(offset.Z, offset.X))
end

-- Where `f` heads to fight `target`, `radius` studs from it: its place among the fighters of its side closing on that
-- target (Rules/Fight.Spread), each wanting to stay where it is, but a lead wanting the target's far side along its
-- avatar's facing, the way the player's camera looks (Fight.Beyond: a Shade comes to the lead at the avatar's side, so the
-- avatar's place would put the fight off the frame's edge; the take of 2026-11-12), and the way there round the target
-- (Fight.Toward). Also how far, in degrees, `f` stands from its place.
local function slotFor(f: Fighter, target: Fighter, radius: number): (Vector3, number)
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
	for index, other in mates do
		local bearing = bearingOf(flat(other.Root.Position - center))
		local avatar = if other.Side == "Lead" then avatarRoot(other) else nil
		local watched = if avatar then flat(-avatar.CFrame.LookVector) else Vector3.zero -- the side the player watches from
		if avatar and watched.Magnitude > 0.5 and beside then
			local lean = Fight.Wrap(bearingOf(flat(center - avatar.Position)) - bearingOf(watched) - 180)
			wants[index] = Fight.Aside(bearingOf(watched), lean, bearing, frame, Combat.Lead.Straight)
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
	return center + Vector3.new(math.cos(heading), 0, math.sin(heading)) * radius, math.abs(Fight.Wrap(place - here))
end

-- The hit's push, once the hold is over: the body jumps on the frame it lets go (handbook/feel/combat.md). It goes its
-- distance at a steady pace over Combat.Push.Seconds and stops there, with no slide: each frame's speed is what's left
-- over that frame, so a late timer never carries it on. Each screen draws that same push from its own hold's end
-- (FighterController, Combat.Push.Shown). A newer push takes over from one still running; a wall ends it after
-- Seconds × PUSH_GIVE_UP.
local PUSH_GIVE_UP = 3
local pushing: { [Fighter]: number } = {}
local function push(f: Fighter, direction: Vector3, studs: number, hold: number)
	local weight = (Combat.Weight :: any)[f.Kind] or 1
	local amount = studs * weight
	if amount <= 0 or direction.Magnitude < 0.01 then
		return
	end
	local seconds = Combat.Push.Seconds
	task.delay(hold, function()
		if fighters[f.Id] ~= f then
			return
		end
		local token = (pushing[f] or 0) + 1
		pushing[f] = token
		local unit = direction.Unit
		local from = f.Root.Position
		local speed = amount / seconds
		local started = os.clock()
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
			if left <= 0.02 or os.clock() - started > seconds * PUSH_GIVE_UP then
				connection:Disconnect()
				pushing[f] = nil
				f.Push.Enabled = false
				local v = f.Root.AssemblyLinearVelocity
				f.Root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
				return
			end
			f.Push.VectorVelocity = unit * math.min(speed, left / math.max(dt, 1 / 240))
		end)
	end)
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

-- One target's share of a hit: rolled, dealt, pushed along `line` (from the attacker), and shown to every client.
local function land(f: Fighter, action: Actions.Action, target: Fighter, beat: string, hit: Actions.Hit, at: number, line: Vector3)
	local rolls = { Dodge = rng:NextNumber(), Critical = rng:NextNumber(), Block = rng:NextNumber() }
	local result = Hit.Resolve(f.Block, target.Block, hit.Coefficient, rolls)
	local left, fell = Fight.Damage(target.Health, result.Total)
	setHealth(target, left)
	target.LastHurt = at
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
	local rung = Fight.Rung(hit.Rung, result.Critical, Combat.Hitstop)
	local hold = if result.Dodged then 0 else Fight.Hold(rung, fell, Combat.Hitstop)
	if not result.Dodged then
		if not fell and target.Action == nil and (Combat.Flinch.Kinds :: any)[target.Kind] then
			setState(target, "Flinch", at + hold + Combat.Flinch.Seconds)
			stop(target)
		end
		push(target, line, hit.Push, hold)
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
			setHealth(other, after)
			-- Beat: a client shows an ally's heal when the beat's crest reaches it, as a hit's (TR3; AR4 section 10).
			Net.Server.FireAll("Heal", { A = f.Model, T = other.Model, Beat = beat, Amount = after - before, Health = after, MaxHealth = other.Block.Health })
		end
	end
end

-- A beat's hit on its fighter's target, if it reaches; with an Area, on every enemy standing that near the target too;
-- with a Cone, on every enemy inside it. A heal comes first, and with no target the fighter still heals itself.
local function strike(f: Fighter, beat: string, hit: Actions.Hit, at: number)
	local action = f.Action :: Actions.Action
	local target = f.ForcedTarget or f.Target
	if target ~= nil and not standing(target) then
		target = nil
	end
	local line = if target then flat(target.Root.Position - f.Root.Position) else Vector3.zero
	local gap = line.Magnitude
	if hit.Heal then
		mend(f, hit, if gap > 0.01 then line.Unit else nil, beat)
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
			if other ~= target and other.Side ~= f.Side and standing(other) and Fight.Within(flat(other.Root.Position - centre).Magnitude, hit.Area) then
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
			if other ~= target and other.Side ~= f.Side and standing(other) and inCone(f, other, line.Unit, hit) then
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
		setState(f, "Down", at + Combat.Lead.DownSeconds)
	else
		setState(f, "Down")
		task.delay(Combat.Shade.FadeSeconds, remove, f)
	end
	FightService.Fell:Fire(f, hitters)
end

local function rise(f: Fighter, at: number)
	local avatar = avatarRoot(f)
	if avatar then
		f.Root.AssemblyLinearVelocity = Vector3.zero
		f.Root.CFrame = besideAvatar(avatar)
	end
	setHealth(f, f.Block.Health)
	f.ReadyAt = {}
	f.Model:SetAttribute("Ready", 0)
	f.LastHurt = -math.huge
	setState(f, "Idle")
	FightService.Rose:Fire(f)
end

-- A lead's turn to decide.
local function thinkLead(f: Fighter, at: number, dt: number)
	local avatar = avatarRoot(f)
	if f.Forced then
		local target = f.ForcedTarget
		face(f, if target then target.Root.Position else nil)
		if target and at >= f.ForcedNext and not busy(f, at) then
			local action = Actions.ById[f.Forced]
			if action then
				if target.Home then -- every press from the same spacing: the last one's push undone
					target.Root.AssemblyLinearVelocity = Vector3.zero
					target.Root.CFrame = target.Home
				end
				start(f, action, at)
			end
			f.ForcedNext = at + f.ForcedEvery
		end
		return
	end
	if avatar == nil then
		stop(f)
		return
	end
	local engaged = false -- a Shade has it for its target
	for _, other in fighters do
		engaged = engaged or (other.Side == "Shade" and other.Target == f and standing(other))
	end
	setHealth(f, Fight.Heal(f.Health, f.Block.Health, at - f.LastHurt, dt, Combat.Lead.Heal, engaged))
	local toAvatar = (avatar.Position - f.Root.Position).Magnitude -- in three dimensions: an avatar teleported straight up still pulls its lead
	local candidates: { Fight.Candidate } = {}
	for _, other in fighters do
		if other.Side == "Shade" and other.Kind ~= "Dummy" and standing(other) then
			table.insert(candidates, { Id = other.Id, Distance = distance(f.Root, other.Root), Reach = distance(avatar, other.Root) })
		end
	end
	local targetId = Fight.LeadTarget(candidates, if f.Target then f.Target.Id else nil, Combat.Lead.Leash)
	setTarget(f, if targetId then fighters[targetId] else nil)
	local mode = Fight.LeadMode(toAvatar, f.Target ~= nil, Combat.Lead)
	if mode == "Teleport" then
		endAction(f, at)
		f.Root.AssemblyLinearVelocity = Vector3.zero
		f.Root.CFrame = besideAvatar(avatar)
		return
	end
	if f.State == "Flinch" then
		return
	end
	local target = f.Target
	if mode == "Fight" and target then
		face(f, target.Root.Position)
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
			moveTo(f, Vector3.new(slot.X, f.Root.Position.Y, slot.Z), Fight.FollowSpeed(toAvatar, Combat.Lead))
		end
		return
	end
	-- Follow: nothing to fight near the avatar.
	if busy(f, at) then
		return
	end
	face(f, nil)
	if toAvatar > Combat.Lead.Follow then
		endAction(f, at)
		moveTo(f, besideAvatar(avatar).Position, Fight.FollowSpeed(toAvatar, Combat.Lead))
	end
end

-- A Shade's turn to decide.
local function thinkShade(f: Fighter, at: number)
	local home = f.Home
	if f.Kit[1] == nil or home == nil then
		return -- a dummy stands and takes it
	end
	local fromHome = flat(f.Root.Position - home.Position).Magnitude
	if f.State == "Reset" then
		if fromHome < 2 then
			f.Hitters = {}
			crowd(f) -- back to its health alone
			setHealth(f, f.Block.Health)
			if f.Pack then
				packHit[f.Pack] = nil
			end
			setState(f, "Idle")
			face(f, home.Position + home.LookVector)
		else
			moveTo(f, home.Position, Combat.Shade.ResetSpeed)
		end
		return
	end
	if f.State == "Flinch" then
		return
	end
	-- A keeper is fought alone in its own copy of the ring (KeeperService): it comes for its challenger at once, and nothing
	-- in the copy is far enough to make it give up. Copies stand 600 studs apart, so it never sees another player's lead.
	local keeper = f.Kind == "Keeper"
	if f.Target and not keeper and Fight.GivesUp(fromHome, Combat.Shade.GiveUp) then
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
		if standing(lead) then
			table.insert(candidates, {
				Id = lead.Id,
				Distance = distance(f.Root, lead.Root),
				Reach = 0,
				Aggrieved = struck ~= nil and struck[lead] == true,
			})
		end
	end
	local notice = if keeper then Combat.Keeper.Notice else Combat.Shade.Notice
	local targetId = Fight.ShadeTarget(candidates, if f.Target then f.Target.Id else nil, notice)
	setTarget(f, if targetId then fighters[targetId] else nil)
	local target = f.Target
	if target == nil then
		if busy(f, at) then
			return
		end
		face(f, nil)
		if fromHome > 2 or f.Health < f.Block.Health then
			setState(f, "Reset") -- left alone: it goes home and heals
		end
		return
	end
	face(f, target.Root.Position)
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
		moveTo(f, Vector3.new(slot.X, f.Root.Position.Y, slot.Z), Combat.Shade.WalkSpeed)
	end
end

local function step()
	local at = now()
	for _, f in fighters do
		if f.State == "Down" then
			if f.Side == "Lead" and at >= f.StateUntil then
				rise(f, at)
			end
			continue
		end
		if f.State == "Flinch" and at >= f.StateUntil then
			setState(f, "Idle")
		end
		local action = f.Action
		if action then
			local clock = at - f.ActionAt
			for _, beat in Fight.BeatsBetween(action, f.Checked, clock) do
				local hit = action.Hits[beat]
				if hit and f.Action == action then
					strike(f, beat, hit, at)
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

-- A lead for `player`, from its stat block, beside the avatar. Replaces any lead the player had.
function FightService.SpawnLead(player: Player, block: Stats.Block, title: string): Fighter
	local old = leads[player]
	if old then
		remove(old)
	end
	local model, rig = buildLead(block.Def, `Lead_{player.UserId}`)
	local avatar = Parts.Root(player.Character)
	model:PivotTo(if avatar then besideAvatar(avatar) else CFrame.new(0, 10, 0))
	local f = register(model, "Lead", "Lead", block.Def, block, Actions.KitOf(block.Def), title, player, rig)
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
function FightService.SpawnEnemy(def: string, level: number, at: CFrame, options: { Type: string?, Pack: string?, Ground: string? }?): Fighter
	local row = assert(Enemies.ById[def], `no enemy {def}`)
	local block = Stats.Enemy(def, level, if options then options.Type else nil)
	local kit = if row.Action then { Actions.ById[row.Action] } else {}
	local name = `{row.Id}_{level}`
	local model, up
	if row.Rig == "Shade" then
		model = buildShade(row, name, block.Type)
		up = SHADE_ROOT_HEIGHT * (row.Scale or 1) + 0.05 -- the rig's feet on the floor
	else
		model = buildBox(row, name)
		up = (row.Size :: { number })[2] / 2 + 0.1
	end
	model:PivotTo(at + Vector3.new(0, up, 0))
	local f = register(model, "Shade", row.Kind, def, block, kit, row.Name, nil, row.Rig)
	f.Home = model:GetPivot()
	f.Pack = if options then options.Pack else nil
	f.Ground = if options then options.Ground else nil
	model:SetAttribute("Type", block.Type)
	return f
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

-- Studio's tests: `f` at `share` of its most health, standing (a heal's case needs a lead that's hurt).
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

-- The replay's hold on a lead (Studio): `action` every `every` seconds against `target`, standing still; nil lets it go.
function FightService.Force(f: Fighter, action: string?, every: number?, target: Fighter?)
	endAction(f, now()) -- a clean start: what it was doing lands nothing on the new target
	f.Forced = action
	f.ForcedEvery = every or 0
	f.ForcedNext = now()
	f.ForcedTarget = target
	showTarget(f)
	if action == nil then
		face(f, nil)
	end
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
	Players.PlayerRemoving:Connect(function(player: Player)
		local lead = leads[player]
		if lead then
			remove(lead)
		end
		for _, f in fighters do
			f.Hitters[player] = nil
		end
	end)
	RunService.Heartbeat:Connect(step)
end

return FightService
