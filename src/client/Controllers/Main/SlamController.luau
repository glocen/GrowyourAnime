--!strict
-- SlamController (client): a keeper's marked slam as this player sees it, in grey (docs/test-requests.md, TR44;
-- FightService's Mark attributes; SlamService). While a fighter's footprint is down, a flat white ring of
-- Config.Combat.Keeper.Mark's radius lies on the ground at its centre, and inside it a translucent disc grows from the
-- middle and meets the ring on the Slam, so the fill tells the time; both go on the Slam, and the column takes over.
-- Nothing else is marked: no screen text, no icon. In mode B (Config.Combat.Keeper.Out.Mode, read live), and only in a
-- keeper's try, the Recall: a round button by the right thumb, R and the gamepad's ButtonY, its cooldown on its face.
-- AR52's two tells, their looks the effects teammate's rows: the Dasher's line and the Guard's shield are their actions'
-- own (DasherLine, GuardShield), and a blow on a raised shield plays GuardGlance or GuardBreak here, where it meets the
-- paper, along the blow. Their grey stand-ins (Config.Combat.Guard.Look, Dasher.Line) draw only while an action's rows
-- aren't written, or beside them for the before and after (Config.Effects.Grey):
-- * a Dasher's line (MarkTo set): a lane outlined on the ground from its feet to the line's end, its fill growing from
--   the Dasher and reaching the end on the hit;
-- * a Guard's raised shield (GuardUntil): a grey pane before it, that brightens as a hit glances off and flashes white
--   and goes when one breaks it (GuardBroke).
-- AR58's Support, in grey until the effects teammate's (Config.Combat.Support.Look):
-- * a shield it gave (ShieldLook, Shield.Look): a grey ball round the one it shields while ShieldUntil holds, while its
--   Lasting row is switched off (Config.Effects);
-- * a heal it gave (a Heal whose healer is casting SupportCast): a light ball on the one it mends, growing and fading,
--   until a SupportHeal row is written.
--   SlamController.Veil(fighter) -> SphereHandleAdornment?   a Support's shield's ball, for tests
--   SlamController.Ring(fighter) -> (ring, disc)?   a fighter's footprint's two adornments, for tests
--   SlamController.Line(fighter) -> (edges, fill)?  a Dasher's line's outline and fill, for tests
--   SlamController.Pane(fighter) -> BoxHandleAdornment?   a Guard's raised pane, for tests
--   SlamController.Struck() -> { Name, Anchor, Rows }?     the last glance or break played on a shield, for tests
-- TR69 C, the press (Config.Combat.Hands, Off by default; Rules.Hands), in grey until Scintilla's look: on, the Recall
-- reads "Call" and shows in every fight but the Tower's, left of Roblox's jump button; an Open foe wears a cracked ring
-- at its feet, closing as its Open runs out and ticking each Look.Tick; the player's own lead flashes white on a slip
-- (its Slipped attribute); and the screen's edges flash white on its Finisher (a Hit's Finisher). No words.
--   SlamController.Recall() -> TextButton?          the Recall button while it shows, for tests
--   SlamController.Cracks(fighter) -> { BoxHandleAdornment }?   an Open foe's cracked ring, for tests
--   SlamController.Edge() -> Frame?                 the Finisher's flash at the screen's edges while it shows, for tests
--   SlamController.Press() -> { [string]: any }     a Recall as a press asks it, the server's answer
-- TR69 D, the keeper's hazards (Net "Hazard"; KeeperPhaseService), in grey on the footprint's own marks: a pool's or a
-- second slam's ring and disc where it lands, gone on its Slam; a sweep's sector outlined on the ground through its
-- tell, its line lying along the sector's first side and filling out to its end, then turning across the sector over
-- its Turn (Rules.Keeper.Sweep), gone at the end of it.
--   SlamController.Hazards() -> { Drawing }   the hazards drawn now (Kind, Holder, Ring, Disc, Line, At, Down, Slam), for tests

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Combat = require(Shared.Config.Combat)
local EffectsConfig = require(Shared.Config.Effects)
local MarkRule = require(Shared.Rules.Mark)
local Hands = require(Shared.Rules.Hands)
local Keeper = require(Shared.Rules.Keeper)
local Actions = require(Shared.Definitions.Actions)
local Effects = require(script.Parent.FighterController.Effects)
local Rows = require(script.Parent.FighterController.Rows)

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Layers)
local Text = require(UI.Kit.Text)
local Button = require(UI.Kit.Button)
local Skin = require(UI.Kit.Skin)
local HudController = require(script.Parent.HudController)

local SlamController = {}

local player = Players.LocalPlayer
local RING_UP = 0.06 -- studs over the ground: clear of it, so it never flickers into the paving
local RING_THICK = 0.04
local GROUND_RAY = 14 -- studs down from the fighter's root height that the ground is looked for
local RECALL_SIDE = 84 -- the button's side, authored: past the 52 a touch needs at the smallest scale
local RECALL_INSET = Vector2.new(28, 118) -- from the screen's bottom right corner: by the right thumb, over the dock's line
local ACTION = "NL_Recall"

-- A footprint drawn: the keeper's ring and disc, or a line's outline and fill (Length long).
type Drawn = {
	Holder: BasePart,
	Ring: CylinderHandleAdornment?,
	Disc: CylinderHandleAdornment?,
	Edges: { BoxHandleAdornment }?,
	Fill: BoxHandleAdornment?,
	Length: number,
	Slam: number,
	Down: number,
	Radius: number,
}
-- A Guard's pane: its adornment, and when a glance last brightened it (os.clock).
type Pane = { Box: BoxHandleAdornment, Glanced: number }

local drawn: { [Model]: Drawn } = {}
local panes: { [Model]: Pane } = {}
local struckLook: { Name: string, Anchor: CFrame, Rows: Rows.Player }? = nil -- the last glance or break, for tests

-- AR52: the grey stand-in for `action` draws while its own rows aren't written, or beside them when Config.Effects.Grey
-- says, read each time so a Tune shows at the next tell.
local function standsIn(action: string): boolean
	local def = Actions.ById[action]
	local effect = if def then def.Effect else nil
	return effect == nil or (EffectsConfig.Rows :: any)[effect] == nil or EffectsConfig.Grey[action] == true
end

-- The action `model` runs (FightService's "Action"), whose mark or shield this is (TR69 B: an elite's own move), or
-- `default`.
local function runs(model: Model, default: string): string
	local id = model:GetAttribute("Action")
	return if type(id) == "string" and Actions.ById[id] ~= nil then id else default
end

-- Whether `action` lays a disc of its own (TR69 B, the overhead's footprint): its rows draw it, the grey ring only stands in.
local function ownDisc(action: string): boolean
	local def = Actions.ById[action]
	for _, hit in (if def then def.Hits else {}) :: { [string]: Actions.Hit } do
		if hit.Mark and hit.Disc then
			return true
		end
	end
	return false
end
local veils: { [Model]: SphereHandleAdornment } = {}
local PANE_GREY = Color3.fromRGB(196, 199, 206)
local ROOT_UP = 3 -- a Shade's root over its feet at Scale 1 (FightService's LEAD_ROOT_HEIGHT, the rig's)
local SCREEN_MIDDLE = 1.875 -- the Guard elite's screen's middle over the street, in studs (Scintilla's S1: 0.15 to 3.6)
local PANE_THICK = 0.12
local recall: TextButton? = nil
local recallFace: Frame? = nil
local recallWord: TextLabel? = nil
local bound = false
-- TR69 C's grey stand-ins: each Open foe's cracked ring, and the Finisher's edge flash while it shows
type Crack = { Holder: BasePart, Bits: { BoxHandleAdornment } }
local cracks: { [Model]: Crack } = {}
local edge: Frame? = nil
local ownLead: Model? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

-- A keeper's hazard drawn (TR69 D): a ring and disc (a pool, a second slam), or a sweep's rim and turning line.
type Hazard = {
	Owner: Instance,
	Kind: string,
	Holder: BasePart,
	Ring: CylinderHandleAdornment?,
	Disc: CylinderHandleAdornment?,
	Rim: BasePart?,
	Line: BoxHandleAdornment?,
	Base: Vector3,
	Radius: number,
	Length: number,
	From: number,
	Arc: number,
	Turn: number,
	Back: boolean,
	Span: number, -- from its Slam to when it goes: a sweep's turn (twice, Back), a burn's Turn, 0 for a pool
	Down: number,
	Slam: number,
}
local hazardsDrawn: { Hazard } = {}
local SWEEP_DASH = 2 -- studs of the sector's rim each dash stands for

local function fighters(): Instance?
	return workspace:FindFirstChild("Fighters")
end

local function groundUnder(at: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {}
	for _, d in { fighters(), player.Character } do
		if d then
			table.insert(skip, d)
		end
	end
	params.FilterDescendantsInstances = skip
	local hit = workspace:Raycast(at + Vector3.new(0, 1, 0), Vector3.new(0, -GROUND_RAY, 0), params)
	return if hit then hit.Position.Y else at.Y - 3
end

local function erase(model: Model)
	local d = drawn[model]
	if d then
		drawn[model] = nil
		d.Holder:Destroy()
	end
end

local function holderAt(cframe: CFrame): BasePart
	local holder = Instance.new("Part")
	holder.Name = "NL_Mark"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.CFrame = cframe
	return holder
end

-- A Dasher's line (AR52): the holder at its start, looking down it, so a box's -Z runs along the line.
local function drawLine(model: Model, at: Vector3, to: Vector3, half: number, down: number, slam: number)
	local line = Combat.Dasher.Line
	local y = groundUnder(at)
	local from = Vector3.new(at.X, y + RING_UP, at.Z)
	local way = Vector3.new(to.X - at.X, 0, to.Z - at.Z)
	local length = way.Magnitude
	if length < 0.1 then
		return
	end
	local holder = holderAt(CFrame.lookAt(from, from + way))
	local function box(name: string, size: Vector3, offset: CFrame, transparency: number): BoxHandleAdornment
		local a = Instance.new("BoxHandleAdornment")
		a.Name = name
		a.Adornee = holder
		a.Size = size
		a.CFrame = offset
		a.Color3 = Color3.new(1, 1, 1)
		a.Transparency = transparency
		a.AlwaysOnTop = false
		a.ZIndex = 1
		a.Parent = holder
		return a
	end
	local edge = math.min(line.Edge, half)
	local edges = {
		box("Left", Vector3.new(edge, RING_THICK, length), CFrame.new(-half + edge / 2, 0, -length / 2), 0.05),
		box("Right", Vector3.new(edge, RING_THICK, length), CFrame.new(half - edge / 2, 0, -length / 2), 0.05),
		box("End", Vector3.new(half * 2, RING_THICK, edge), CFrame.new(0, 0, -length + edge / 2), 0.05),
	}
	local fill = box("Fill", Vector3.new(math.max(0.01, half * 2 - edge * 2), RING_THICK, 0.01), CFrame.new(0, 0, -0.005), line.Fill)
	holder.Parent = workspace
	drawn[model] = { Holder = holder, Edges = edges, Fill = fill, Length = length, Slam = slam, Down = down, Radius = half }
end

-- A ring and its growing disc flat on the ground under `at` (the keeper's footprint's look, Config.Combat.Keeper.Mark).
local function ringAt(at: Vector3, radius: number): (BasePart, CylinderHandleAdornment, CylinderHandleAdornment)
	local look = Combat.Keeper.Mark
	local y = groundUnder(at)
	-- a cylinder adornment's axis is its CFrame's look: turned to stand up, it lies flat on the ground
	local holder = holderAt(CFrame.new(at.X, y + RING_UP, at.Z) * CFrame.Angles(math.rad(90), 0, 0))
	local function adorn(name: string, transparency: number): CylinderHandleAdornment
		local a = Instance.new("CylinderHandleAdornment")
		a.Name = name
		a.Adornee = holder
		a.Height = RING_THICK
		a.Color3 = Color3.new(1, 1, 1)
		a.Transparency = transparency
		a.AlwaysOnTop = false
		a.ZIndex = 1
		a.Parent = holder
		return a
	end
	local ring = adorn("Ring", 0.05)
	ring.Radius = radius
	ring.InnerRadius = math.max(0, radius - look.Edge)
	local disc = adorn("Disc", look.Fill)
	disc.Radius = 0.01
	return holder, ring, disc
end

local function draw(model: Model)
	erase(model)
	local at, radius, down, slam = model:GetAttribute("MarkAt"), model:GetAttribute("MarkRadius"), model:GetAttribute("MarkDown"), model:GetAttribute("MarkSlam")
	if typeof(at) ~= "Vector3" or type(radius) ~= "number" or type(down) ~= "number" or type(slam) ~= "number" then
		return
	end
	local to = model:GetAttribute("MarkTo")
	if typeof(to) == "Vector3" then
		if standsIn(runs(model, "DasherLunge")) then
			drawLine(model, at :: Vector3, to :: Vector3, radius :: number, down :: number, slam :: number)
		end
		return
	end
	local own = runs(model, "")
	if ownDisc(own) and not standsIn(own) then
		return
	end
	local holder, ring, disc = ringAt(at :: Vector3, radius :: number)
	holder.Parent = workspace
	drawn[model] = { Holder = holder, Ring = ring, Disc = disc, Length = 0, Slam = slam :: number, Down = down :: number, Radius = radius :: number }
end

-- A keeper's hazard put down (TR69 D; FightService.Hazard's payload): a pool's or a second slam's ring, or a sweep's rim
-- and its line, drawn until its Slam (a sweep's, until its line has turned).
local function hazardOn(payload: any)
	if type(payload) ~= "table" or typeof(payload.A) ~= "Instance" or typeof(payload.At) ~= "Vector3" then
		return
	end
	local at: Vector3 = payload.At
	local radius, down, slam = tonumber(payload.Radius), tonumber(payload.Down), tonumber(payload.Slam)
	if radius == nil or down == nil or slam == nil then
		return
	end
	local kind = tostring(payload.Kind or "")
	local from, arc, length, turn = tonumber(payload.From), tonumber(payload.Arc), tonumber(payload.Length), tonumber(payload.Turn)
	if kind == "Sweep" and from and arc and length and turn then
		local base = Vector3.new(at.X, groundUnder(at) + RING_UP, at.Z)
		local edge = Combat.Keeper.Mark.Edge
		local rim = holderAt(CFrame.new(base))
		local function dash(name: string, middle: Vector3, along: Vector3, long: number)
			local a = Instance.new("BoxHandleAdornment")
			a.Name = name
			a.Adornee = rim
			a.Size = Vector3.new(edge, RING_THICK, long)
			a.CFrame = CFrame.lookAt(middle, middle + along)
			a.Color3 = Color3.new(1, 1, 1)
			a.Transparency = 0.05
			a.AlwaysOnTop = false
			a.ZIndex = 1
			a.Parent = rim
		end
		-- its two sides, and its far edge in dashes
		for index, a in { from, from + arc } do
			local way = Vector3.new(math.cos(a), 0, math.sin(a))
			dash(`Side{index}`, way * length / 2, way, length)
		end
		local count = math.max(2, math.ceil(length * arc / SWEEP_DASH))
		for index = 1, count do
			local a = from + arc * (index - 0.5) / count
			dash(`Rim{index}`, Vector3.new(math.cos(a), 0, math.sin(a)) * length, Vector3.new(-math.sin(a), 0, math.cos(a)), length * arc / count * 0.6)
		end
		local first = Vector3.new(math.cos(from), 0, math.sin(from))
		local holder = holderAt(CFrame.lookAt(base, base + first))
		local line = Instance.new("BoxHandleAdornment")
		line.Name = "Line"
		line.Adornee = holder
		line.Size = Vector3.new(radius * 2, RING_THICK, 0.01)
		line.CFrame = CFrame.new(0, 0, -0.005)
		line.Color3 = Color3.new(1, 1, 1)
		line.Transparency = Combat.Keeper.Mark.Fill
		line.AlwaysOnTop = false
		line.ZIndex = 1
		line.Parent = holder
		rim.Parent = workspace
		holder.Parent = workspace
		local back = payload.Back == true
		table.insert(hazardsDrawn, {
			Owner = payload.A, Kind = kind, Holder = holder, Rim = rim, Line = line, Base = base, Radius = radius,
			Length = length, From = from, Arc = arc, Turn = turn, Back = back, Span = if back then 2 * turn else turn,
			Down = down, Slam = slam,
		})
		return
	end
	local holder, ring, disc = ringAt(at, radius)
	holder.Parent = workspace
	table.insert(hazardsDrawn, {
		Owner = payload.A, Kind = kind, Holder = holder, Ring = ring, Disc = disc, Base = at, Radius = radius,
		Length = 0, From = 0, Arc = 0, Turn = 0, Back = false, Span = if tonumber(payload.Every) then turn or 0 else 0,
		Down = down, Slam = slam,
	})
end

local function hazardOff(index: number)
	local h = table.remove(hazardsDrawn, index)
	if h then
		h.Holder:Destroy()
		if h.Rim then
			h.Rim:Destroy()
		end
	end
end

local function stepHazards(t: number)
	for index = #hazardsDrawn, 1, -1 do
		local h = hazardsDrawn[index]
		if h.Owner.Parent == nil or t >= h.Slam + h.Span then
			hazardOff(index)
			continue
		end
		local share = MarkRule.Fill(t, h.Down, h.Slam)
		local disc, line = h.Disc, h.Line
		if disc then
			disc.Radius = math.max(0.01, h.Radius * share)
		elseif line then
			if t < h.Slam then
				local long = math.max(0.01, h.Length * share)
				line.Size = Vector3.new(h.Radius * 2, RING_THICK, long)
				line.CFrame = CFrame.new(0, 0, -long / 2)
			else
				local a = h.From + (Keeper.Sweep(t - h.Slam, h.Turn, h.Arc, h.Back) or (if h.Back then 0 else h.Arc))
				line.Size = Vector3.new(h.Radius * 2, RING_THICK, h.Length)
				line.CFrame = CFrame.new(0, 0, -h.Length / 2)
				line.Transparency = 0.05
				h.Holder.CFrame = CFrame.lookAt(h.Base, h.Base + Vector3.new(math.cos(a), 0, math.sin(a)))
			end
		end
	end
end

local function paneOff(model: Model)
	local pane = panes[model]
	if pane then
		panes[model] = nil
		pane.Box:Destroy()
	end
end

-- A Guard's shield raised (AR52): its grey pane before its root, while the server's GuardUntil holds.
local function paneOn(model: Model)
	local untilTime = model:GetAttribute("GuardUntil")
	local root = model:FindFirstChild("HumanoidRootPart")
	if type(untilTime) ~= "number" or now() >= untilTime or root == nil or not root:IsA("BasePart") then
		paneOff(model)
		return
	end
	if panes[model] or not standsIn(runs(model, "GuardRaise")) then
		return
	end
	local look = Combat.Guard.Look
	local k = model:GetScale() -- the elite's pane at its size (AR57)
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "NL_GuardPane"
	box.Adornee = root
	box.Size = Vector3.new(look.Wide * k, look.High * k, PANE_THICK)
	box.CFrame = CFrame.new(0, look.Up * k, -look.Ahead * k)
	box.Color3 = PANE_GREY
	box.Transparency = look.Transparency
	box.AlwaysOnTop = false
	box.ZIndex = 1
	box.Parent = root
	panes[model] = { Box = box, Glanced = -math.huge }
end

-- Broken open: a white flash where the pane stood, gone in Flash seconds.
local function paneBreak(model: Model)
	paneOff(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") or not standsIn("GuardRaise") then
		return
	end
	local look = Combat.Guard.Look
	local k = model:GetScale()
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "NL_GuardBreak"
	box.Adornee = root
	box.Size = Vector3.new(look.Wide * 1.15 * k, look.High * 1.15 * k, PANE_THICK)
	box.CFrame = CFrame.new(0, look.Up * k, -look.Ahead * k)
	box.Color3 = Color3.new(1, 1, 1)
	box.Transparency = 0.05
	box.AlwaysOnTop = false
	box.ZIndex = 1
	box.Parent = root
	task.delay(look.Flash, function()
		box:Destroy()
	end)
end

-- AR52: a blow on a Guard's raised shield, where it meets the paper (Config.Effects.Shield, at its scale), its Front
-- along the blow on the ground: GuardGlance on a glance, GuardBreak on the break, on the effects' clock. A break also
-- ends GuardRaise's action (its stagger), and FighterController ends the shield's rows at once.
-- With `behind` (TR69 B, a Guard elite's screen taking a blow meant for `behind`): where the blow crosses its wall.
local function shieldStruck(target: any, attacker: any, name: string, behind: any?)
	if typeof(target) ~= "Instance" or typeof(attacker) ~= "Instance" then
		return
	end
	local guard, by = target :: Instance, attacker :: Instance
	if not guard:IsA("Model") or not by:IsA("Model") then
		return
	end
	local root = guard:FindFirstChild("HumanoidRootPart")
	local from = by:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") or from == nil or not from:IsA("BasePart") then
		return
	end
	local meets = EffectsConfig.Shield
	local k = guard:GetScale()
	local point = (root.CFrame * CFrame.new(0, meets.Up * k, -meets.Ahead * k)).Position
	local blow = Vector3.new(root.Position.X - from.Position.X, 0, root.Position.Z - from.Position.Z)
	local facing = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local way = if blow.Magnitude > 0.01 then blow.Unit elseif facing.Magnitude > 0.01 then -facing.Unit else Vector3.new(0, 0, -1)
	local behindModel = if typeof(behind) == "Instance" then behind :: Instance else nil
	local back = if behindModel and behindModel:IsA("Model") then behindModel:FindFirstChild("HumanoidRootPart") else nil
	local wall = (Actions.ById.GuardScreen :: any).Guard.Screen
	if back and back:IsA("BasePart") and facing.Magnitude > 0.01 then
		local look = facing.Unit
		local line = Vector3.new(back.Position.X - from.Position.X, 0, back.Position.Z - from.Position.Z)
		local closing = line:Dot(look)
		if math.abs(closing) > 1e-3 then
			local start = Vector3.new(from.Position.X, root.Position.Y, from.Position.Z)
			local t = (wall.Ahead - (start - root.Position):Dot(look)) / closing
			-- on the wall, at its middle's height: it stands from 0.15 to 3.6 over the street (Scintilla's S1), the root
			-- LEAD_ROOT_HEIGHT x its scale over it
			point = start + line * math.clamp(t, 0, 1) + Vector3.new(0, SCREEN_MIDDLE - ROOT_UP * k, 0)
			way = line.Unit
		end
	end
	local anchor = CFrame.lookAt(point, point + way)
	if name == "GuardScreenBreak" and facing.Magnitude > 0.01 then
		-- the wall's break draws in the Guard's root frame, Front its look, as GuardScreen finds the wall (Scintilla, f06b40f3)
		anchor = CFrame.lookAt(root.Position, root.Position + facing.Unit)
	end
	local rows = Effects.At(name, anchor, k)
	if rows then
		struckLook = { Name = name, Anchor = anchor, Rows = rows }
	end
end

-- AR58: a shield from a Support holds on `model`, and no look of the effects teammate's draws it yet.
local function veiled(model: Model): boolean
	local untilTime = model:GetAttribute("ShieldUntil")
	local name = Combat.Support.Shield.Look
	return model.Parent ~= nil and model:GetAttribute("ShieldLook") == name and EffectsConfig.Lasting[name] ~= true
		and type(untilTime) == "number" and now() < untilTime and model:GetAttribute("State") ~= "Down"
end

local function veilOff(model: Model)
	local ball = veils[model]
	if ball then
		veils[model] = nil
		ball:Destroy()
	end
end

local function veilOn(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not veiled(model) or root == nil or not root:IsA("BasePart") then
		veilOff(model)
		return
	end
	if veils[model] then
		return
	end
	local look = Combat.Support.Look
	local ball = Instance.new("SphereHandleAdornment")
	ball.Name = "NL_SupportVeil"
	ball.Adornee = root
	ball.Radius = look.Radius * model:GetScale()
	ball.Color3 = PANE_GREY
	ball.Transparency = look.Transparency
	ball.AlwaysOnTop = false
	ball.ZIndex = 1
	ball.Parent = root
	veils[model] = ball
end

-- AR58: one a Support mends, a light ball growing from its body's size and fading out over Pop.Seconds.
local function mendPop(model: Model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") or (EffectsConfig.Rows :: any).SupportHeal ~= nil then
		return
	end
	local look = Combat.Support.Look
	local pop = look.Pop
	local size = look.Radius * model:GetScale()
	local ball = Instance.new("SphereHandleAdornment")
	ball.Name = "NL_SupportMend"
	ball.Adornee = root
	ball.Radius = size
	ball.Color3 = Color3.new(1, 1, 1)
	ball.Transparency = pop.Transparency
	ball.AlwaysOnTop = false
	ball.ZIndex = 1
	ball.Parent = root
	local began = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local share = (os.clock() - began) / math.max(pop.Seconds, 0.01)
		if share >= 1 or ball.Parent == nil then
			(connection :: RBXScriptConnection):Disconnect()
			ball:Destroy()
			return
		end
		ball.Radius = size * (1 + (pop.Grow - 1) * share)
		ball.Transparency = pop.Transparency + (1 - pop.Transparency) * share
	end)
end

-- The player's own lead, kept while it stands in the fighters' folder.
local function myLead(): Model?
	local kept = ownLead
	if kept and kept.Parent ~= nil then
		return kept
	end
	ownLead = nil
	local folder = fighters()
	for _, model in (if folder then folder:GetChildren() else {}) do
		if model:IsA("Model") and model:GetAttribute("Side") == "Lead" and model:GetAttribute("Owner") == player.UserId then
			ownLead = model
			return model
		end
	end
	return nil
end

local function crackOff(model: Model)
	local c = cracks[model]
	if c then
		cracks[model] = nil
		c.Holder:Destroy()
	end
end

-- An Open foe's cracked ring (TR69 C): Look.Cracks short arcs round its feet, a Gap of each left out.
local function crackOn(model: Model)
	local openUntil = model:GetAttribute("OpenUntil")
	if type(openUntil) ~= "number" or now() >= openUntil then
		crackOff(model)
		return
	end
	if cracks[model] then
		return
	end
	local look = Combat.Hands.Look
	local holder = holderAt(CFrame.new(model:GetPivot().Position))
	holder.Name = "NL_Open"
	local bits = {}
	for k = 1, look.Cracks do
		local a = Instance.new("BoxHandleAdornment")
		a.Name = `Crack{k}`
		a.Adornee = holder
		a.Color3 = Color3.new(1, 1, 1)
		a.Transparency = 0.2
		a.AlwaysOnTop = false
		a.ZIndex = 1
		a.Parent = holder
		table.insert(bits, a)
	end
	holder.Parent = workspace
	cracks[model] = { Holder = holder, Bits = bits }
end

-- Each frame: every cracked ring at its foe's feet, closing from Radius to Least of it as the Open runs out, brighter
-- for a moment each Tick (the clock by eye).
local function stepCracks(t: number)
	local look = Combat.Hands.Look
	for model, c in cracks do
		local openUntil = model:GetAttribute("OpenUntil")
		if model.Parent == nil or type(openUntil) ~= "number" or t >= openUntil or model:GetAttribute("State") == "Down" then
			crackOff(model)
			continue
		end
		local left = math.clamp((openUntil - t) / math.max(Combat.Hands.Open.Seconds, 0.01), 0, 1)
		local radius = look.Radius * (look.Least + (1 - look.Least) * left)
		local at = model:GetPivot().Position
		c.Holder.CFrame = CFrame.new(at.X, groundUnder(at) + RING_UP, at.Z)
		local arc = 2 * math.pi * radius / look.Cracks * (1 - look.Gap)
		local into = (openUntil - t) % look.Tick
		local lit = into > look.Tick - 0.1
		for k, bit in c.Bits do
			local angle = (k - 1) / look.Cracks * 2 * math.pi
			bit.Size = Vector3.new(arc, RING_THICK, look.Width)
			bit.CFrame = CFrame.Angles(0, -angle, 0) * CFrame.new(0, 0, -radius)
			bit.Transparency = if lit then 0 else 0.35
		end
	end
end

-- The player's own lead's slip (TR69 C): a white flash on it, Look.Slip seconds.
local function slipFlash(model: Model)
	if model ~= myLead() then
		return
	end
	local flash = Instance.new("Highlight")
	flash.Name = "NL_Slip"
	flash.FillColor = Color3.new(1, 1, 1)
	flash.FillTransparency = 0.15
	flash.OutlineTransparency = 1
	flash.DepthMode = Enum.HighlightDepthMode.Occluded
	flash.Adornee = model
	flash.Parent = model
	task.delay(Combat.Hands.Look.Slip, function()
		flash:Destroy()
	end)
end

-- The player's own lead's Finisher (TR69 C): the screen's edges flash white, Look.Edge seconds.
local function edgeFlash()
	local look = Combat.Hands.Look
	if edge then
		edge:Destroy()
	end
	local frame = Instance.new("Frame")
	frame.Name = "FinisherEdge"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = look.EdgeWidth
	stroke.Transparency = 0.1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	frame.Parent = Layers.Get("Overlay")
	edge = frame
	task.delay(look.Edge, function()
		frame:Destroy()
		if edge == frame then
			edge = nil
		end
	end)
end

local function watch(model: Instance)
	if not model:IsA("Model") then
		return
	end
	crackOn(model)
	model:GetAttributeChangedSignal("OpenUntil"):Connect(function()
		crackOn(model)
	end)
	model:GetAttributeChangedSignal("Slipped"):Connect(function()
		slipFlash(model)
	end)
	if model:GetAttribute("MarkSlam") ~= nil then
		draw(model)
	end
	model:GetAttributeChangedSignal("MarkSlam"):Connect(function()
		if model:GetAttribute("MarkSlam") ~= nil then
			draw(model)
		else
			erase(model)
		end
	end)
	paneOn(model)
	model:GetAttributeChangedSignal("GuardUntil"):Connect(function()
		paneOn(model)
	end)
	model:GetAttributeChangedSignal("GuardBroke"):Connect(function()
		paneBreak(model)
	end)
	veilOn(model)
	model:GetAttributeChangedSignal("ShieldUntil"):Connect(function()
		veilOn(model)
	end)
	model.Destroying:Connect(function()
		erase(model)
		paneOff(model)
		veilOff(model)
		crackOff(model)
	end)
end

local function stepMarks()
	local t = now()
	for model, d in drawn do
		if t >= d.Slam or model.Parent == nil then
			erase(model) -- gone on the Slam: the column takes over
			continue
		end
		-- the fill tells the time: it meets the ring on the Slam, or the line's end on its hit
		local share = MarkRule.Fill(t, d.Down, d.Slam)
		local disc, fill = d.Disc, d.Fill
		if disc then
			disc.Radius = math.max(0.01, d.Radius * share)
		elseif fill then
			local long = math.max(0.01, d.Length * share)
			fill.Size = Vector3.new(fill.Size.X, RING_THICK, long)
			fill.CFrame = CFrame.new(0, 0, -long / 2)
		end
	end
	local look = Combat.Guard.Look
	for model, pane in panes do
		local untilTime = model:GetAttribute("GuardUntil")
		if model.Parent == nil or type(untilTime) ~= "number" or t >= untilTime or model:GetAttribute("State") == "Down" then
			paneOff(model)
			continue
		end
		-- a glance brightens it, easing back over Flash
		local since = os.clock() - pane.Glanced
		local lift = math.clamp(1 - since / math.max(look.Flash, 0.01), 0, 1)
		pane.Box.Transparency = look.Transparency * (1 - 0.7 * lift)
	end
	for model in veils do
		if not veiled(model) then
			veilOff(model)
		end
	end
	stepCracks(t)
	stepHazards(t)
end

-- B's Recall: what a press asks the server.
function SlamController.Press(): { [string]: any }
	local ok, answer = pcall(Net.Client.Invoke, "Recall")
	return if ok and type(answer) == "table" then answer else { Ok = false, Error = "NoAnswer" }
end

-- B's Recall in a keeper's try; with hands on (TR69 C), Call in every fight but the Tower's: the lead has a target, or a
-- blow landed within Hands.Linger (the player's HitAt, server time).
local function shows(): boolean
	local hands = Combat.Hands
	local lead = myLead()
	local target = if lead then lead:GetAttribute("Target") else nil
	local blow = player:GetAttribute("HitAt")
	local fighting = (type(target) == "string" and target ~= "") or (type(blow) == "number" and now() - blow < hands.Linger)
	return Hands.Calls(hands.On, MarkRule.Mode(Combat.Keeper.Out.Mode), player:GetAttribute("Try") ~= nil, fighting, player:GetAttribute("Tower") ~= nil)
end

-- Its word: "Call" with hands on, "Recall" as TR44 built it.
local function callWord(): string
	return if Combat.Hands.On then "Call" else "Recall"
end

local function makeRecall(): TextButton
	local side = RECALL_SIDE
	local button = Button.new({
		Name = "Recall",
		Text = "",
		Bare = true,
		Size = UDim2.fromOffset(side, side),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -RECALL_INSET.X, 1, -RECALL_INSET.Y),
		Parent = Layers.Get("Hud"),
		OnPress = function(): boolean
			local answer = SlamController.Press()
			return answer.Ok == true
		end,
	})
	local skin = Skin.Of(button) -- in the face, so it squeezes with it
	local face = Instance.new("Frame")
	face.Name = "Round"
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundColor3 = Theme.Colour.PlateHigh
	face.BackgroundTransparency = Theme.Transparency.Plate
	face.ZIndex = 10
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = face
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colour.Text
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = face
	face.Parent = skin
	local word = Text.new({ Name = "Word", Size = Theme.Text.Body, Font = Theme.Font.Strong, Parent = face })
	word.Text = callWord()
	word.ZIndex = 11
	recallFace, recallWord = face, word
	return button
end

local function bind(on: boolean)
	if on == bound then
		return
	end
	bound = on
	if on then
		ContextActionService:BindAction(ACTION, function(_, state: Enum.UserInputState): Enum.ContextActionResult
			if state == Enum.UserInputState.Begin and recall then
				Button.Press(recall)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.R, Enum.KeyCode.ButtonY)
	else
		ContextActionService:UnbindAction(ACTION)
	end
end

local function stepRecall()
	local show = shows()
	if show and recall == nil then
		recall = makeRecall()
	end
	local button = recall
	if button then
		button.Visible = show
		-- with hands on, left of Roblox's jump button, its centre on the jump's, Gap from it (combat-agency.md, Input)
		if Combat.Hands.On then
			local at, size = HudController.JumpBox()
			local hud, scale = Layers.Get("Hud"), math.max(Layers.Scale(), 0.01)
			local origin = hud.AbsolutePosition
			button.AnchorPoint = Vector2.new(1, 0.5)
			button.Position = UDim2.fromOffset((at.X - origin.X) / scale - Combat.Hands.Look.CallGap, (at.Y + size.Y / 2 - origin.Y) / scale)
		else
			button.AnchorPoint = Vector2.new(1, 1)
			button.Position = UDim2.new(1, -RECALL_INSET.X, 1, -RECALL_INSET.Y)
		end
	end
	bind(show)
	local face, word = recallFace, recallWord
	if not show or face == nil or word == nil then
		return
	end
	-- the cooldown on its face: the seconds left, dimmed, until it's ready
	local ready = player:GetAttribute("RecallReady")
	local left = if type(ready) == "number" then ready - now() else 0
	if left > 0 then
		word.Text = tostring(math.ceil(left))
		face.BackgroundTransparency = 0.5
		word.TextTransparency = 0.3
	else
		word.Text = callWord()
		face.BackgroundTransparency = Theme.Transparency.Plate
		word.TextTransparency = 0
	end
end

function SlamController.Ring(model: Model): (CylinderHandleAdornment?, CylinderHandleAdornment?)
	local d = drawn[model]
	return if d then d.Ring else nil, if d then d.Disc else nil
end

function SlamController.Line(model: Model): ({ BoxHandleAdornment }?, BoxHandleAdornment?)
	local d = drawn[model]
	return if d then d.Edges else nil, if d then d.Fill else nil
end

function SlamController.Pane(model: Model): BoxHandleAdornment?
	local pane = panes[model]
	return if pane then pane.Box else nil
end

function SlamController.Struck(): { Name: string, Anchor: CFrame, Rows: Rows.Player }?
	return struckLook
end

function SlamController.Veil(model: Model): SphereHandleAdornment?
	return veils[model]
end

function SlamController.Recall(): TextButton?
	return if recall and recall.Visible then recall else nil
end

function SlamController.Cracks(model: Model): { BoxHandleAdornment }?
	local c = cracks[model]
	return if c then c.Bits else nil
end

function SlamController.Edge(): Frame?
	return edge
end

export type Drawing = {
	Kind: string,
	Holder: BasePart,
	Ring: CylinderHandleAdornment?,
	Disc: CylinderHandleAdornment?,
	Line: BoxHandleAdornment?,
	At: Vector3,
	Down: number,
	Slam: number,
}

function SlamController.Hazards(): { Drawing }
	local out: { Drawing } = {}
	for _, h in hazardsDrawn do
		table.insert(out, { Kind = h.Kind, Holder = h.Holder, Ring = h.Ring, Disc = h.Disc, Line = h.Line, At = h.Base, Down = h.Down, Slam = h.Slam })
	end
	return out
end

function SlamController.Start()
	local function hook(folder: Instance)
		for _, model in folder:GetChildren() do
			watch(model)
		end
		folder.ChildAdded:Connect(watch)
	end
	local folder = fighters()
	if folder then
		hook(folder)
	else
		task.spawn(function()
			hook(workspace:WaitForChild("Fighters"))
		end)
	end
	RunService.RenderStepped:Connect(stepMarks)
	RunService.Heartbeat:Connect(stepRecall)
	Net.Client.On("Hit", function(hit: any)
		-- a Guard elite's screen took it (TR69 B): the wall's Guard, not the one behind
		local screen = if type(hit) == "table" and typeof(hit.Screen) == "Instance" then hit.Screen else nil
		local guard = if screen then screen elseif type(hit) == "table" then hit.T else nil
		local pane = if type(hit) == "table" and hit.Guarded == "Glanced" and typeof(guard) == "Instance" then panes[guard :: any] else nil
		if pane then
			pane.Glanced = os.clock()
		end
		if type(hit) == "table" and (hit.Guarded == "Glanced" or hit.Guarded == "Broke") then
			local broke = if screen and (EffectsConfig.Rows :: any).GuardScreenBreak then "GuardScreenBreak" else "GuardBreak"
			shieldStruck(guard, hit.A, if hit.Guarded == "Glanced" then "GuardGlance" else broke, if screen then hit.T else nil)
		end
		if type(hit) == "table" and hit.Finisher == true and hit.A == myLead() then
			edgeFlash()
		end
	end)
	Net.Client.On("Hazard", hazardOn)
	Net.Client.On("Heal", function(heal: any)
		local healer, healed = if type(heal) == "table" then heal.A else nil, if type(heal) == "table" then heal.T else nil
		if typeof(healer) == "Instance" and healer:GetAttribute("Action") == "SupportCast" and typeof(healed) == "Instance" and healed:IsA("Model") then
			mendPop(healed)
		end
	end)
end

return SlamController
