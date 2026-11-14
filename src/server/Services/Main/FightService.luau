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
local Passives = require(Shared.Definitions.Passives)
local Voidkin = require(Shared.Definitions.Voidkin)
local Combat = require(Shared.Config.Combat)
local WorldConfig = require(Shared.Config.World)
local Shades = require(Shared.Config.Shades)
local EffectsConfig = require(Shared.Config.Effects)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Fight = require(Shared.Rules.Fight)
local Carry = require(Shared.Rules.Carry)
local Markers = require(Shared.World.Markers)
local Passive = require(Shared.Rules.Passive)

-- "Home": a fallen lead on its plot, healing and waiting for its player (TR12), never in a fight.
export type State = "Idle" | "Flinch" | "Down" | "Reset" | "Home"

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
	Hitters: { [Player]: boolean }, -- players whose lead hit it: a pack belongs to everyone (docs/design.md)
	Alone: number, -- its most health with one or two leads on it; a crowd adds to it (Fight.CrowdHealth)
	-- A lead watching a keeper it felled, standing and facing where it fell, until its Down's Gone (AR7, section 5, fix 2).
	Watch: Vector3?,
	WatchUntil: number,
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
FightService.Rose = Signal.new() -- (fighter) a lead up again: home with its player, or brought back by a test

local GROUP_FIGHTERS = "Fighters"
local GROUP_AVATARS = "Avatars"
local GREY = Color3.fromRGB(163, 162, 165)
local SHADE_BODY = Color3.fromRGB(46, 46, 52)
local SHADE_MASK = Color3.fromRGB(214, 214, 214)
local SHADE_ROOT_HEIGHT = 3 -- the Shade rig's root above its feet, at scale 1 (the recipe's frame)
local LEAD_ROOT_HEIGHT = 3 -- an R6 lead's root above its feet

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
		Home = nil,
		Pack = nil,
		Ground = nil,
		Hitters = {},
		Alone = block.Health,
		WatchUntil = 0,
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

-- Where a lead stands beside its avatar: a little to the right and behind, at the avatar's height; in a keeper's try, on
-- its left (Combat.Keeper.Side: clear of the Challenge and the fall's line).
local function besideAvatar(avatar: BasePart, owner: Player?): CFrame
	local side = if owner and owner:GetAttribute("Try") ~= nil then Combat.Keeper.Side else Combat.Lead.Side
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
		local watched = if avatar then flat(-avatar.CFrame.LookVector) else Vector3.zero -- the side the player watches from
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

local function push(f: Fighter, direction: Vector3, studs: number, hold: number)
	local weight = (Combat.Weight :: any)[f.Kind] or 1
	local amount = studs * weight
	if amount <= 0 or direction.Magnitude < 0.01 then
		return
	end
	task.delay(hold, function()
		if fighters[f.Id] ~= f then
			return
		end
		glide(f, direction.Unit, amount, Combat.Push.Seconds)
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

-- One target's share of a hit: rolled, dealt, pushed along `line` (from the attacker), and shown to every client. The
-- target's passive may take less (Rook's Second Wind); the attacker's may add to it in its element (Pip's Kindle), shown in
-- the element's number.
local function land(f: Fighter, action: Actions.Action, target: Fighter, beat: string, hit: Actions.Hit, at: number, line: Vector3)
	local rolls = { Dodge = rng:NextNumber(), Critical = rng:NextNumber(), Block = rng:NextNumber() }
	local effects: Hit.Effects = { Reduction = Passive.Reduction(passiveOf(target), target.Health, target.Block.Health) }
	local result = Hit.Resolve(f.Block, target.Block, hit.Coefficient, rolls, effects)
	local own = passiveOf(f)
	local extra = Passive.Extra(own, action.Id, beat, result.Physical)
	if extra > 0 then
		result.Elemental += extra
		result.Total += extra
	end
	local left, fell = Fight.Damage(target.Health, result.Total)
	setHealth(target, left)
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
		f.Root.CFrame = besideAvatar(avatar, f.Owner)
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

-- The fall's end (docs/design.md, "A fall sends it home"): it leaves as light (the client's), and is home on its plot,
-- healing from nothing to full in Home.Fallen seconds. StateUntil is when it's whole, for the card's time.
local function goHome(f: Fighter, at: number)
	local spot = homeSpot(f)
	if spot then
		f.Root.AssemblyLinearVelocity = Vector3.zero
		f.Root.CFrame = spot
	end
	f.ReadyAt = {}
	f.Model:SetAttribute("Ready", 0)
	setHealth(f, 0)
	setState(f, "Home", at + Combat.Lead.Home.Fallen)
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
	local share = Carry.Mend(if most > 0 then f.Health / most else 0, dt, Combat.Lead.Home.Fallen)
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
	-- Health carries (TR12): its Regen always, and on its owner's plot the heal at home besides.
	local plot = if f.Owner then f.Owner:GetAttribute("Plot") else nil
	local home = Markers.OnPlot(if type(plot) == "number" then plot else nil, f.Root.Position)
	setHealth(f, Fight.Regen(f.Health, f.Block.Health, Fight.RegenRate(f.Block.Regen, f.Block.Health, home, Combat.Lead.Home.Full), dt))
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
		f.Root.CFrame = besideAvatar(avatar, f.Owner)
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
		else
			endAction(f, at)
			local walk = if f.Block.Speed > 0 then f.Block.Speed else Combat.Lead.FollowWalk -- its Speed (TR14)
			moveTo(f, Vector3.new(slot.X, f.Root.Position.Y, slot.Z), Fight.LeadSpeed(toAvatar, walk, Combat.Lead))
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
	face(f, nil)
	if toAvatar > Combat.Lead.Follow then
		endAction(f, at)
		moveTo(f, besideAvatar(avatar, f.Owner).Position, Fight.LeadSpeed(toAvatar, Combat.Lead.FollowWalk, Combat.Lead))
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
		moveTo(f, Vector3.new(slot.X, f.Root.Position.Y, slot.Z), if keeper then Combat.Keeper.WalkSpeed else Combat.Shade.WalkSpeed)
	end
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
function FightService.SpawnEnemy(def: string, level: number, at: CFrame, options: { Type: string?, Pack: string?, Ground: string? }?): Fighter
	local row = assert(Enemies.ById[def], `no enemy {def}`)
	local block = Stats.Enemy(def, level, if options then options.Type else nil)
	local kit = if row.Action then { Actions.ById[row.Action] } else {}
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
	model:SetAttribute("Type", block.Type)
	if row.Enter then
		-- held to its end before it does anything else: busy() keeps it from walking or striking (the keeper's Challenge)
		start(f, Actions.ById[row.Enter], now())
	end
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

-- Studio's tests: a fallen lead back up at its avatar's side at once, whole, as the old quick return was (the way home
-- takes a walk to the plot, which a case on the test pad can't make).
function FightService.Recall(f: Fighter)
	if fighters[f.Id] == f and f.Side == "Lead" and (f.State == "Down" or f.State == "Home") then
		rise(f, now())
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
