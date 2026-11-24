--!strict
-- TowerRoomController (client): the Tower's room as its owner sees it, and every gate's record (AR56, the Crown;
-- docs/asset-requests.md, AR56). The server lays each run's room (TowerService: a Model tagged GA_TowerRoom, its owner's
-- UserId in For) and each gate on its lot (WorldService); this writes and moves only what's seen, every frame from the
-- beat's start, so a frame late or a join mid-beat lands where it should. The server's parts stay where it laid them.
-- * The slab's number (the plan's `number`: a SurfaceGui on each face's well): the face toward the floor shows the floor
--   being fought, the back waits with the next. At each rise the slab turns over the beat's Turn, and once turned its
--   new back takes the floor after. A gate's slab shows its owner's record on both faces (its Record attribute, kept by
--   TowerService); none before the save's read.
-- * The floor's beat at each rise (Rules.Tower.Beat, from the player's TowerBeat, the server's clock, and TowerRise): the
--   foe's steps wait under their places, rise the farthest first with a small overshoot, and sink again once the foe
--   is in.
-- * The drifts: each cloud passes along +X at its plan's speed and comes round within Config.Tower.Drift's Wrap of the
--   room's middle, faded over its Fade at each end so it's never seen to jump.
--   TowerRoomController.Room() -> Model?                          the own player's room, for tests
--   TowerRoomController.Numbers(slab) -> { [string]: string }?    what a slab's faces read, Front and Back, for tests
--   TowerRoomController.Steps() -> { [string]: number }?           each foe step's height under its place, for tests
--   TowerRoomController.Turned() -> number?                        the room's slab's turn, in half turns, for tests

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local TowerConfig = require(Shared.Config.Tower)
local RoomPlan = require(Shared.Config.Kits.TowerRoom.Plan) :: any
local RoomManifest = require(Shared.Config.Kits.TowerRoom.Manifest) :: any
local Tower = require(Shared.Rules.Tower)

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)

local TowerRoomController = {}

local ROOM_TAG = "GA_TowerRoom"
local SLAB_TAG = "GA_TowerSlab"
local WELL_PIXELS = 110 -- the well's height in its SurfaceGui's pixels: TextScaled stops at 100 px, so the number fills it
local OVERSHOOT = 1.2 -- the steps' rise: a back-out ease's reach past its place, small
local INK = Color3.fromHex(RoomPlan.number.colour)

type Room = {
	Model: Model,
	Middle: Vector3,
	Slab: BasePart?,
	SlabAt: CFrame?, -- the slab as the server laid it
	Steps: { [string]: { Part: BasePart, At: CFrame } },
	Drifts: { { Part: BasePart, At: CFrame, From: number, Speed: number } },
	Since: number, -- os.clock the room was seen: the drifts' time
}

local room: Room? = nil
local numbers: { [BasePart]: { Front: TextLabel, Back: TextLabel } } = {}
local shownTurn: number? = nil
local shownSteps: { [string]: number } = {}

-- The slab's well (the plan's number), in studs at the slab's scale of 1: its middle is over the slab's place, which
-- is the piece's centre above the part's middle.
local WELL = { Wide = 16.8, Tall = 7.2, Over = 2.4 }

-- The well as a share of the slab's face: its size and its middle.
local function well(): (Vector2, Vector2)
	local piece = RoomManifest.pieces[RoomPlan.number.piece]
	local wide, tall = piece.size[1], piece.size[2]
	local fromTop = tall / 2 - (WELL.Over - piece.centre[2])
	return Vector2.new(WELL.Wide / wide, WELL.Tall / tall), Vector2.new(0.5, fromTop / tall)
end

-- A slab's two faces, each a SurfaceGui with its number in the well.
local function write(slab: BasePart): { Front: TextLabel, Back: TextLabel }
	local had = numbers[slab]
	if had then
		return had
	end
	local size, middle = well()
	-- The slab's scale (the room's 1, the gate's 0.66): the well's studs, and so the canvas's pixels a stud.
	local scale = slab.Size.Y / RoomManifest.pieces[RoomPlan.number.piece].size[2]
	local labels: { [string]: TextLabel } = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = `Number{face.Name}`
		gui.Face = face
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = WELL_PIXELS / (WELL.Tall * scale)
		local label = Instance.new("TextLabel")
		label.Name = "Number"
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(middle.X, middle.Y)
		label.Size = UDim2.fromScale(size.X, size.Y)
		label.FontFace = Theme.Font.Number
		label.TextScaled = true
		label.TextColor3 = INK
		label.Text = ""
		label.Parent = gui
		gui.Parent = slab
		labels[face.Name] = label
	end
	local made = { Front = labels.Front, Back = labels.Back }
	numbers[slab] = made
	slab.Destroying:Connect(function()
		numbers[slab] = nil
	end)
	return made
end

-- A gate's slab: its owner's record on both faces.
local function record(slab: BasePart)
	local labels = write(slab)
	local best = slab:GetAttribute("Record")
	local said = if type(best) == "number" then tostring(best) else ""
	labels.Front.Text, labels.Back.Text = said, said
end

local function mine(model: Instance): boolean
	return model:IsA("Model") and model:GetAttribute("For") == Players.LocalPlayer.UserId
end

local function seen(model: Model)
	local middle = model:GetPivot().Position
	local made: Room = { Model = model, Middle = middle, Steps = {}, Drifts = {}, Since = os.clock() }
	for _, placement in RoomPlan.placements do
		local part = model:FindFirstChild(if #placement.tag > 1 then placement.tag else `{placement.piece}{placement.tag}`)
		if part == nil or not part:IsA("BasePart") then
			continue
		end
		if RoomPlan.beat.stepRest[placement.tag] ~= nil then
			made.Steps[placement.tag] = { Part = part, At = part.CFrame }
		elseif RoomPlan.drift.speed[placement.tag] ~= nil then
			table.insert(made.Drifts, { Part = part, At = part.CFrame, From = part.Position.X - middle.X, Speed = RoomPlan.drift.speed[placement.tag] })
		elseif placement.piece == RoomPlan.number.piece then
			made.Slab = part
			made.SlabAt = part.CFrame
			write(part)
		end
	end
	room = made
end

-- 0 to 1 with a small overshoot past 1 on the way (a back-out ease).
local function rise(t: number): number
	local u = math.clamp(t, 0, 1) - 1
	return 1 + (OVERSHOOT + 1) * u * u * u + OVERSHOOT * u * u
end

local function smooth(t: number): number
	local u = math.clamp(t, 0, 1)
	return u * u * (3 - 2 * u)
end

-- The room's slab and steps where the beat has them at `elapsed` seconds into floor `floor`'s rise of `seconds`.
local function beatAt(r: Room, floor: number, elapsed: number, seconds: number)
	local beat = Tower.Beat(seconds)
	-- The slab: turned (floor - 1) half turns once the floor's turn is done, one fewer before it.
	local slab, at = r.Slab, r.SlabAt
	if slab and at then
		local turn = beat.Turn
		local into = if floor <= 1 then 1 else smooth((elapsed - turn[1]) / math.max(turn[2] - turn[1], 1e-3))
		local half = (floor - 2) + into
		local done = into >= 1
		if half ~= shownTurn then
			slab.CFrame = at * CFrame.Angles(0, math.pi * half, 0)
			shownTurn = half
		end
		-- The face toward the floor after `turns` half turns is the Back when they're even; it shows the floor turned to,
		-- the other the one after.
		local turns = if done then floor - 1 else floor - 2
		local shown = if done then floor else floor - 1
		local labels = write(slab)
		local toward, away = if turns % 2 == 0 then labels.Back else labels.Front, if turns % 2 == 0 then labels.Front else labels.Back
		toward.Text, away.Text = tostring(shown), tostring(shown + 1)
	end
	-- The steps: under their places, up over their span, down again over the sink.
	local sink = beat.Sink
	local down = smooth((elapsed - sink[1]) / math.max(sink[2] - sink[1], 1e-3))
	for _, step in beat.Steps do
		local held = r.Steps[step.Tag]
		if held == nil then
			continue
		end
		local up = rise((elapsed - step.From) / math.max(step.To - step.From, 1e-3))
		if elapsed < step.From then
			up = 0
		end
		local under = step.Rest * (1 - up * (1 - down))
		if shownSteps[step.Tag] ~= under then
			held.Part.CFrame = held.At + Vector3.new(0, under, 0)
			shownSteps[step.Tag] = under
		end
	end
end

local function drifts(r: Room)
	local drift = TowerConfig.Drift
	local t = os.clock() - r.Since
	for _, d in r.Drifts do
		local x = (d.From + d.Speed * t + drift.Wrap) % (2 * drift.Wrap) - drift.Wrap
		d.Part.CFrame = d.At + Vector3.new(x - d.From, 0, 0)
		local edge = drift.Wrap - math.abs(x)
		d.Part.Transparency = if edge < drift.Fade then 1 - math.max(edge, 0) / drift.Fade else 0
	end
end

local function step()
	local r = room
	if r == nil then
		return
	end
	if r.Model.Parent == nil then
		room, shownTurn = nil, nil
		table.clear(shownSteps)
		return
	end
	drifts(r)
	local me = Players.LocalPlayer
	local floor = me:GetAttribute("Tower")
	local started = me:GetAttribute("TowerBeat")
	local seconds = me:GetAttribute("TowerRise")
	if type(floor) ~= "number" then
		return
	end
	if type(started) ~= "number" or type(seconds) ~= "number" then
		beatAt(r, floor, -1, TowerConfig.Rise) -- in before the first beat: the steps down, the slab at the floor
		return
	end
	beatAt(r, floor, workspace:GetServerTimeNow() - started, seconds)
end

function TowerRoomController.Room(): Model?
	return if room then room.Model else nil
end

function TowerRoomController.Numbers(slab: BasePart): { [string]: string }?
	local labels = numbers[slab]
	return if labels then { Front = labels.Front.Text, Back = labels.Back.Text } else nil
end

function TowerRoomController.Steps(): { [string]: number }?
	return if room then table.clone(shownSteps) else nil
end

function TowerRoomController.Turned(): number?
	return shownTurn
end

function TowerRoomController.Start()
	local function added(item: Instance)
		if mine(item) then
			seen(item :: Model)
		end
	end
	CollectionService:GetInstanceAddedSignal(ROOM_TAG):Connect(added)
	for _, item in CollectionService:GetTagged(ROOM_TAG) do
		added(item)
	end
	-- Gates' slabs (on a lot, with a Plot): their record, now and as it changes. A room's is written by its beat.
	local function slab(item: Instance)
		if item:IsA("BasePart") and item:GetAttribute("Plot") ~= nil then
			record(item)
			item:GetAttributeChangedSignal("Record"):Connect(function()
				record(item)
			end)
		end
	end
	CollectionService:GetInstanceAddedSignal(SLAB_TAG):Connect(slab)
	for _, item in CollectionService:GetTagged(SLAB_TAG) do
		slab(item)
	end
	RunService:BindToRenderStep("GA_TowerRoom", Enum.RenderPriority.Last.Value, step)
end

return TowerRoomController
