--!strict
-- WorldService (server): the world the circuit is played in (docs/design.md, "The world, in grey").
-- * With no authored world in the place (no workspace.World), it lays research's layout in grey from Config.World,
--   stamping the contract's markers (Shared.World.Tags) as it goes. A World number tuned in a playtest lays it again, and
--   Laid tells whatever stands on a marker to find it again.
-- * It gives each player a plot at join, the lowest free one, as the player attribute "Plot" (docs/engineering-plan.md,
--   "Who owns what": the server, at join), and sets them down on its spawn, facing the Breaker. A plot is a bare lot
--   until a player owns it: its base (the machines, the door, the spawn, the dressing) stands when they arrive and goes
--   when they leave (the director, 2026-11-15), and Built tells whatever stands on its markers.
-- * Lantern Row wears its kit (TR8; AR5, section 2) once the kit's template is built (ServerStorage.Templates.
--   LanternRowKit, tools/studio/KitAssembly): each piece where its plan says (Config.Kits.LanternRow, Shared.World.Kit)
--   and the plan's lights, over the grey street, whose markers stay where they are and whose walls, gates and square
--   stay as unseen colliders under the look; the street's floor carries the walking and wears the kit's paving under
--   the bays. With no template, or a plan off the street's markers (a tuned street),
--   the street stays grey and says why. The world's folder carries GateZ, the festival gate's line, for the ground's
--   look (LightingController).
-- * Every plot wears the base's kit (AR14) once its template is built (ServerStorage.Templates.BaseKit): its plan's level
--   (Config.Kits.Base) laid in the plot's own frame, the plan's lights and the level's number on the gate's plate. The
--   lot outside the yard, the Tower's footprint, the ground and the Strip take the plan's colours and tiles, and the grey
--   machines its stand-ins' colours; the kept back's overlay goes under the yard. With no template, the plots stay grey.
-- Studio's WorldReport checks the place's markers against the contract, DressReport the dressing against its plan, and
-- Night jumps the server's turn of dusk and night to a phase (Rules.Night), for the takes.
-- North is -Z. The crossing's centre is the origin; the Strip runs east-west; Lantern Row runs north from the gate.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
local LightingConfig = require(Shared.Config.Lighting)
local Kit = require(Shared.World.Kit)
local Night = require(Shared.Rules.Night)
local BaseFit = require(Shared.Rules.BaseFit)
local Net = require(Shared.Net)
local Markers = require(Shared.World.Markers)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local Core = script.Parent.Parent.Core
local DebugService = require(Core.DebugService)
local TuneService = require(Core.TuneService)

local WorldService = {
	Priority = 15, -- before anything that stands on a marker
}
WorldService.Laid = Signal.new() -- () the grey world was laid again: markers moved
WorldService.Built = Signal.new() -- (number) a plot's base stood for its new owner: its markers are new

local WORLD = "World"
local GROUND_TOP = 0.5 -- the ground's top, over a template Baseplate's (0), so the two never fight for a pixel
local PAVED_TOP = 0.6 -- the Strip, the streets and the plots stand a tenth higher, for the same reason
local OVERLAY = 0.1 -- a mark on a paved floor: the kept back of a plot, a Tower's footprint
local SPAWN_UP = 3 -- an R6 root stands 3 studs over its floor
local DRESS = "LanternRow" -- the kit Lantern Row wears: Config.Kits.LanternRow, ServerStorage.Templates.LanternRowKit
local DRESS_LIFT = 0.05 -- the kit's floors stand a hair over the paving they cover, so the two never fight at a distance
local LIGHT_CEILING = 14 -- round 2's lights, the ceiling the kit keeps (AR5, section 2)
local BASE = "Base" -- the kit every plot wears: Config.Kits.Base, ServerStorage.Templates.BaseKit (AR14)
local BASE_LEVEL = "1" -- the plan's level laid on every plot, until the base has its levels (TR21)
local LEVEL_FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold) -- the HUD's numbers
local LEVEL_INK = Color3.fromHex("#FFD23E") -- Power's yellow, as the plan's level mark asks
local LEVEL_PIXELS = 40 -- the level's number, a SurfaceGui's pixels a stud
-- The shard a Breaker's chamber breaks, between its two points (AR15: 5.85 to 8.35 up, the middle 7.1), turned an eighth
-- so it reads as a crystal; seen only while the chamber breaks one (BaseService).
local SHARD = { Size = Vector3.new(1.1, 2.2, 1.1), Up = 7.1, Turn = 45 }
-- World numbers read when used, not laid
local READ_LIVE = {
	["World.Row.Respawn"] = true,
	["World.Row.Back.Elite"] = true,
	["World.Row.Back.Keeper"] = true,
	["World.Arrive"] = true,
}

local GREY = {
	Ground = Color3.fromRGB(78, 80, 86),
	Paved = Color3.fromRGB(118, 120, 126),
	Plot = Color3.fromRGB(104, 106, 112),
	Kept = Color3.fromRGB(92, 94, 100),
	Tower = Color3.fromRGB(66, 68, 74),
	Wall = Color3.fromRGB(70, 72, 78),
	Gate = Color3.fromRGB(56, 58, 64),
	Machine = Color3.fromRGB(150, 151, 156),
	Chamber = Color3.fromRGB(178, 178, 184),
	Bay = Color3.fromRGB(132, 133, 138),
	Locked = Color3.fromRGB(60, 61, 66),
	Battery = Color3.fromRGB(164, 165, 150),
	Generator = Color3.fromRGB(140, 141, 132),
	Pad = Color3.fromRGB(196, 196, 200),
}

local function block(parent: Instance, name: string, size: Vector3, at: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = at
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A floor from x0 to x1 and z0 to z1, its top at `top`.
local function slab(parent: Instance, name: string, x0: number, x1: number, z0: number, z1: number, top: number, color: Color3): Part
	local thick = 1
	local size = Vector3.new(math.abs(x1 - x0), thick, math.abs(z1 - z0))
	return block(parent, name, size, CFrame.new((x0 + x1) / 2, top - thick / 2, (z0 + z1) / 2), color)
end

-- A marker that's only a place: unseen, untouchable, its centre on the floor at `at`, so where it stands is the floor.
local function spot(parent: Instance, name: string, at: CFrame): Part
	local p = block(parent, name, Vector3.new(2, 0.2, 2), at, GREY.Pad)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- A model whose pivot stands on the floor at `at`.
local function model(parent: Instance, name: string, at: CFrame): Model
	local m = Instance.new("Model")
	m.Name = name
	m.WorldPivot = at
	m.Parent = parent
	return m
end

-- A gate across a street: two posts and a lintel, `wide` apart, facing along `at`'s look.
local function gate(parent: Instance, name: string, at: CFrame, wide: number, high: number, shut: boolean): Model
	local m = model(parent, name, at)
	for _, side in { -1, 1 } do
		block(m, "Post", Vector3.new(2, high, 2), at * CFrame.new(side * (wide / 2 + 1), high / 2, 0), GREY.Gate)
	end
	block(m, "Lintel", Vector3.new(wide + 4, 2, 2), at * CFrame.new(0, high + 1, 0), GREY.Gate)
	if shut then
		block(m, "Door", Vector3.new(wide, high, 1), at * CFrame.new(0, high / 2, 0), GREY.Locked)
	end
	return m
end

-- The Festival Door: a frame with a way of light through it, its pivot on the floor at `at`, the way's face along `at`'s
-- look. Walking into the way takes the player through (DoorService). `material`: the way's, Neon unless given.
local function door(parent: Instance, name: string, at: CFrame, material: string?): Model
	local d = WorldConfig.Grey.Door
	local m = model(parent, name, at)
	for _, side in { -1, 1 } do
		block(m, "Post", Vector3.new(1.5, d.High, 1.5), at * CFrame.new(side * (d.Wide / 2 + 0.75), d.High / 2, 0), GREY.Gate)
	end
	block(m, "Lintel", Vector3.new(d.Wide + 3, 1.5, 1.5), at * CFrame.new(0, d.High + 0.75, 0), GREY.Gate)
	local way = block(m, "Way", Vector3.new(d.Wide, d.High, 0.4), at * CFrame.new(0, d.High / 2, 0), GREY.Pad)
	way.Material = (Enum.Material :: any)[material or "Neon"]
	way.Transparency = 0.35
	way.CanCollide = false
	return m
end

-- A wall along z from z0 to z1 at x, `high` tall.
local function wallZ(parent: Instance, x: number, z0: number, z1: number, high: number): Part?
	if math.abs(z1 - z0) < 0.5 then
		return nil
	end
	return block(parent, "Wall", Vector3.new(2, high, math.abs(z1 - z0)), CFrame.new(x, PAVED_TOP + high / 2, (z0 + z1) / 2), GREY.Wall)
end

-- A wall along x from x0 to x1 at z.
local function wallX(parent: Instance, z: number, x0: number, x1: number, high: number): Part?
	if math.abs(x1 - x0) < 0.5 then
		return nil
	end
	return block(parent, "Wall", Vector3.new(math.abs(x1 - x0), high, 2), CFrame.new((x0 + x1) / 2, PAVED_TOP + high / 2, z), GREY.Wall)
end

-- A kit's pieces as a template (src/storage/<Kit>Kit.rbxm, built by tools/studio/KitAssembly), or nil until then;
-- Lantern Row's when no kit is named.
local function kitTemplate(kit: string?): Instance?
	local templates = ServerStorage:FindFirstChild("Templates")
	return if templates then templates:FindFirstChild(`{kit or DRESS}Kit`) else nil
end

local function kitFiles(kit: string?): (any, any)
	local home = (Shared.Config :: any).Kits[kit or DRESS]
	return require(home.Manifest) :: any, require(home.Plan) :: any
end

-- Why the base's kit can't be laid on the plots: none when it can.
local function baseProblems(): { string }
	local plots = WorldConfig.Plots
	if plots.Across ~= plots.Drawn or plots.Deep ~= plots.Drawn then
		return { `the plots are {plots.Across * WorldConfig.Walk} studs and the plan is drawn for {plots.Drawn * WorldConfig.Walk}: part 7's grey trial` }
	end
	local template = kitTemplate(BASE)
	if template == nil then
		return { `the base's template isn't built (ServerStorage.Templates.{BASE}Kit: tools/studio/KitAssembly)` }
	end
	local manifest, plan = kitFiles(BASE)
	local level = plan.levels[BASE_LEVEL]
	if level == nil then
		return { `the base's plan has no level {BASE_LEVEL}` }
	end
	local problems: { string } = {}
	for index, placement in level.placements do
		local piece = template:FindFirstChild(placement.piece)
		if manifest.pieces[placement.piece] == nil then
			table.insert(problems, `placement {index}: "{tostring(placement.piece)}" isn't in the base's manifest`)
		elseif piece == nil or not piece:IsA("BasePart") then
			table.insert(problems, `the base's template has no part {placement.piece}`)
		end
	end
	if template:FindFirstChild("Paving") == nil then
		table.insert(problems, "the base's template has no Paving")
	end
	return problems
end

-- One of a kit's static lights at `at`, Shadows off, tagged for the client's look: a SpotLight straight down is a pool.
local function kitLight(light: Kit.Light, at: CFrame, parent: Instance): Part
	local holder = Instance.new("Part")
	holder.Name = light.name
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch, holder.CastShadow = true, false, false, false, false
	holder.CFrame = at
	local spot = light.kind == "spot"
	local made: Light
	if spot then
		local cone = Instance.new("SpotLight")
		cone.Face = Enum.NormalId.Front -- the holder looks straight down
		cone.Angle = light.cone or 90
		made = cone
	else
		made = Instance.new("PointLight")
	end
	local numbers = if spot then LightingConfig.Pools else LightingConfig.Lamp
	made.Color = Color3.fromHex(light.colour)
	made.Brightness = numbers.Brightness;
	(made :: any).Range = numbers.Range
	made.Shadows = false
	made.Parent = holder
	holder:SetAttribute("Light", if spot then "Pool" else "Lamp")
	CollectionService:AddTag(holder, Kit.Tag)
	holder.Parent = parent
	return holder
end

-- Why the kit can't be laid on a street whose stops stand `stops` studs up from its gate: none when it can.
local function dressProblems(stops: { number }): { string }
	local template = kitTemplate()
	if template == nil then
		return { `the kit's template isn't built (ServerStorage.Templates.{DRESS}Kit: tools/studio/KitAssembly)` }
	end
	local manifest, plan = kitFiles()
	local problems = Kit.Problems(manifest.pieces, plan, stops, LIGHT_CEILING)
	for name in manifest.pieces do
		local piece = template:FindFirstChild(name)
		if piece == nil or not piece:IsA("BasePart") then
			table.insert(problems, `the template has no part {name}`)
		end
	end
	return problems
end

-- The street's kit (TR8): each piece at its plan's place, and the plan's lights, Shadows off. Every piece and light is
-- tagged (Kit.Tag) for the client, which keeps their glow and brightness with Config.Lighting and the night.
local function dress(street: Instance, gateZ: number)
	local template = kitTemplate() :: Instance
	local manifest, plan = kitFiles()
	local folder = Instance.new("Folder")
	folder.Name = "Dressing"
	local floorY = PAVED_TOP + DRESS_LIFT
	for _, placement in plan.placements do
		local part = (template:FindFirstChild(placement.piece) :: BasePart):Clone()
		part.Anchored = true
		part.CFrame = Kit.Place(placement, manifest.pieces[placement.piece], gateZ, floorY)
		part:SetAttribute("Piece", placement.piece)
		CollectionService:AddTag(part, Kit.Tag)
		part.Parent = folder
	end
	for _, light in plan.lights do
		kitLight(light, Kit.Light(light, gateZ, floorY), folder)
	end
	-- The drifting paper (AR5, "The paper's emitter"): a box of air each, seen by nothing but its emitter, in the band
	-- over the camera (Config.Lighting.Paper), its rate and tint from it. The client keeps it to a tuned band live.
	local paper = template:FindFirstChild("Paper") :: ParticleEmitter?
	if plan.paper and paper then
		local band = LightingConfig.Paper
		for index, box in plan.paper.boxes do
			local _, tall, share = Kit.PaperBand(box, band)
			local air = Instance.new("Part")
			air.Name = `Paper{index}`
			air.Size = Vector3.new(box.size[1], tall, box.size[3])
			air.Transparency = 1
			air.Anchored, air.CanCollide, air.CanQuery, air.CanTouch, air.CastShadow = true, false, false, false, false
			air.CFrame = Kit.Paper(box, gateZ, floorY, band)
			local emitter = paper:Clone()
			emitter.Rate = plan.paper.emitter.Rate * share
			emitter.Color = ColorSequence.new(band.Colour)
			emitter.Parent = air
			air:SetAttribute("Paper", index) -- its box in the plan
			air:SetAttribute("FloorY", floorY)
			CollectionService:AddTag(air, Kit.Tag)
			air.Parent = folder
		end
	end
	folder.Parent = street
end

-- The plan's colours while the base's kit is laid (its stand-ins', the lot's and the ground's), or nil: the plots grey.
local baseLook: { [string]: Color3 }? = nil

-- The base's kit on one plot (AR14): its plan's level in the plot's own frame (the plan's toRoblox: Kit.Place with the
-- plot's front edge for the gate's line), the level's lights, and the level's number on the gate's plate, on both faces.
-- Every piece and light is tagged for the client's look and carries its plot. The court's and the yard's floors are
-- look only: the plot's own floor carries the walking.
local function dressPlot(m: Model, number: number, at: CFrame, front: number)
	local template = kitTemplate(BASE) :: Instance
	local manifest, plan = kitFiles(BASE)
	local level = plan.levels[BASE_LEVEL]
	local folder = Instance.new("Folder")
	folder.Name = "Dressing"
	for _, placement in level.placements do
		local part = (template:FindFirstChild(placement.piece) :: BasePart):Clone()
		part.Anchored = true
		part.CFrame = at * Kit.Place(placement, manifest.pieces[placement.piece], front, DRESS_LIFT)
		part:SetAttribute("Piece", placement.piece)
		part:SetAttribute("Plot", number)
		CollectionService:AddTag(part, Kit.Tag)
		part.Parent = folder
	end
	for _, light in level.lights do
		kitLight(light, at * Kit.Light(light, front, DRESS_LIFT), folder):SetAttribute("Plot", number)
	end
	local mark = level.levelMark
	if mark then
		local plate = Instance.new("Part")
		plate.Name = "LevelMark"
		plate.Size = Vector3.new(mark.size[1], mark.size[2], mark.depth + 0.04) -- a hair proud of the plate's two faces
		plate.Transparency = 1
		plate.Anchored, plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.CastShadow = true, false, false, false, false
		plate.CFrame = at * CFrame.new(mark.across, DRESS_LIFT + mark.up, front - mark.along)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Name = face.Name
			gui.Face = face
			gui.LightInfluence = 0
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = LEVEL_PIXELS
			local said = Instance.new("TextLabel")
			said.Name = "Level"
			said.BackgroundTransparency = 1
			said.AnchorPoint = Vector2.new(0.5, 0.5)
			said.Position = UDim2.fromScale(0.5, 0.5)
			said.Size = UDim2.fromScale(1, 0.84)
			said.FontFace = LEVEL_FACE
			said.TextScaled = true
			said.TextColor3 = LEVEL_INK
			said.Text = BASE_LEVEL
			said.Parent = gui
			gui.Parent = plate
		end
		plate:SetAttribute("Plot", number)
		plate.Parent = folder
	end
	folder.Parent = m
end

-- The base's deck tile on a plot's floor or overlay, in the lot's colour (the plan's ground).
local function pave(part: BasePart)
	local paving = (kitTemplate(BASE) :: Instance):FindFirstChild("Paving")
	if paving and baseLook then
		local tile = paving:Clone() :: Texture
		tile.Color3 = baseLook.lot
		tile.Parent = part
	end
end

-- The crossing's side of a plot `at`, in its own across: 1 or -1. The plots stand either side of the crossing, which
-- is the world's x = 0 (lay()).
local function crossingSide(at: CFrame): number
	return if at:PointToObjectSpace(Vector3.new(0, at.Position.Y, at.Position.Z)).X >= 0 then 1 else -1
end

-- One of the base kit's pieces on a plot at `placement` (Kit.Place in the plot's frame), named `name`, tagged for the
-- client's look and carrying its plot, and "Solid" when its piece collides, for whatever shows and hides it
-- (BaseService). Nil while the base's kit isn't laid or the template has no such piece.
local function piece(parent: Instance, name: string, kind: string, placement: any, number: number, at: CFrame, front: number): BasePart?
	if baseLook == nil then
		return nil
	end
	local made = (kitTemplate(BASE) :: Instance):FindFirstChild(kind)
	if made == nil or not made:IsA("BasePart") then
		return nil
	end
	local manifest = kitFiles(BASE)
	local part = made:Clone()
	part.Name = name
	part.CFrame = at * Kit.Place(placement, manifest.pieces[kind], front, DRESS_LIFT)
	part:SetAttribute("Piece", kind)
	part:SetAttribute("Plot", number)
	part:SetAttribute("Solid", part.CanCollide)
	CollectionService:AddTag(part, Kit.Tag)
	part.Parent = parent
	return part
end

-- The Void Mill's body is look only; what a player bumps is these unseen shapes, the manifest's `collision` on Generator
-- (AR19), in the piece's own frame (x across, y up, -z toward the gate): the well shut to walking, so nobody stands in
-- its wheel, the sill across it, and the raked legs' feet and legs. The trestle and the arm stand on them, look only.
local MILL_SOLID = {
	Well = { Radius = 10.6, High = 3 },
	Sill = { Size = Vector3.new(22.4, 1.4, 1.8), At = Vector3.new(0, 0.7, -4.6) },
	Feet = { Size = Vector3.new(2.8, 1, 2.8), At = Vector3.new(7.6, 0.5, 14) },
	Leg = { Thick = 1.3, From = Vector3.new(7.6, 0.3, 14), To = Vector3.new(1.5, 8.7, 3.6) },
}

local function millSolid(plant: Instance, body: BasePart)
	local c = (kitFiles(BASE)).pieces.Generator.centre
	local origin = body.CFrame * CFrame.new(-c[1], -c[2], -c[3])
	local function solid(name: string, size: Vector3, frame: CFrame, shape: Enum.PartType?)
		local part = block(plant, name, size, origin * frame, GREY.Machine)
		part.Shape = shape or Enum.PartType.Block
		part.Transparency, part.CastShadow, part.CanTouch = 1, false, false
		part:SetAttribute("Solid", true)
	end
	local well = MILL_SOLID.Well
	solid("Well's solid", Vector3.new(well.High, well.Radius * 2, well.Radius * 2), CFrame.new(0, well.High / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	solid("Sill's solid", MILL_SOLID.Sill.Size, CFrame.new(MILL_SOLID.Sill.At))
	for _, side in { 1, -1 } do
		local flip = Vector3.new(side, 1, 1)
		solid("Foot's solid", MILL_SOLID.Feet.Size, CFrame.new(MILL_SOLID.Feet.At * flip))
		local from, to = MILL_SOLID.Leg.From * flip, MILL_SOLID.Leg.To * flip
		local thick = MILL_SOLID.Leg.Thick
		solid("Leg's solid", Vector3.new(thick, thick, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to))
	end
end

-- A machine with its model (AR15; the plan's machines) in place of its grey box: the plan's `nth` placement of `placed`,
-- laid as a placement is and raised by its `up`, wearing the piece `as` (`placed` itself unless given: a bay a level
-- wakes stands where its sleeping bay stood), named as the box it replaces. Nil while the base's kit isn't laid or the
-- plan has no such machine: then the box stands.
local function machine(parent: Instance, name: string, placed: string, nth: number, number: number, at: CFrame, front: number, as: string?): BasePart?
	if baseLook == nil then
		return nil
	end
	local _, plan = kitFiles(BASE)
	local seen = 0
	for _, placement in (if plan.machines then plan.machines.placements else {}) do
		if placement.piece == placed then
			seen += 1
			if seen == nth then
				return piece(parent, name, as or placed, Kit.Toward(placement, crossingSide(at)), number, at, front)
			end
		end
	end
	return nil
end

-- The turn of the plan's first placement of `placed`, in degrees anticlockwise from above; 0 when it has none.
local function turnOf(placed: string): number
	local _, plan = kitFiles(BASE)
	for _, placement in (if plan.machines then plan.machines.placements else {}) do
		if placement.piece == placed then
			return placement.turn or 0
		end
	end
	return 0
end

-- A part shown or hidden in its place (a bay asleep or awake, a battery cell), solid only while shown and its piece is.
-- BaseService shows each plot's by its owner's base.
local function stand(part: BasePart, shown: boolean)
	part.Transparency = if shown then 0 else 1
	part.CanCollide = shown and part:GetAttribute("Solid") == true
	part.CanQuery = part.CanCollide
end
WorldService.Stand = stand

-- Part 7's trial (Config.World.Fit): a square plot of another size than the plan's stands on Fit's layout for its size;
-- nil at the plan's own, or a size Fit has no layout for (the plan's then stands as it is).
local function trialLayout(across: number, deep: number): BaseFit.Layout?
	if deep ~= across or across == WorldConfig.Plots.Drawn * WorldConfig.Walk then
		return nil
	end
	return (WorldConfig.Fit.Layouts :: any)[tostring(across)]
end

-- One plot, `at` its centre on its floor, looking out of its front onto the Strip: its lot, laid with the world, and the
-- builder of its base, raised when a player owns the plot and cleared when they leave, so a server stands only its
-- players' bases (the director, 2026-11-15). The base is built whole before it's parented: it reaches clients at once.
-- Where each machine stands is the base plan's layout (AR16: a star round the generator, open toward the gate), whether
-- its kit is laid or the plot is grey.
local function plot(parent: Instance, number: number, at: CFrame, across: number, deep: number, kept: number, behind: number, tower: number): () -> Model
	local m = model(parent, `Plot {number}`, at)
	local look = baseLook
	-- Each grey box in the base's stand-in colour while its kit is laid (the plan's standIns: one steel body, an accent each).
	local function tint(name: string, grey: Color3): Color3
		return if look then look[name] or grey else grey
	end
	local floor = block(m, "Floor", Vector3.new(across, 1, deep), at * CFrame.new(0, -0.5, 0), tint("lot", GREY.Plot))
	Markers.Stamp(floor, "Plot", { Plot = number })
	local keptBack = block(m, "Kept", Vector3.new(across, OVERLAY, kept), at * CFrame.new(0, OVERLAY / 2, deep / 2 - kept / 2), GREY.Kept)
	local towerFloor = block(m, "Tower", Vector3.new(across, OVERLAY, tower), at * CFrame.new(0, OVERLAY / 2 - 0.05, deep / 2 + behind + tower / 2), tint("lot", GREY.Tower))
	if look then
		-- The lot wears the deck. The kept back takes it unmarked, so its overlay steps aside: the yard's floor runs over
		-- its middle, lower than the overlay's top.
		pave(floor)
		pave(towerFloor)
		keptBack.Transparency, keptBack.CanCollide, keptBack.CanQuery = 1, false, false
	end
	local front = -deep / 2 -- local z of its front edge
	return function(): Model
		local base = Instance.new("Model")
		base.Name = "Base"
		base.WorldPivot = at
		local manifest, plan = kitFiles(BASE)
		local trial = trialLayout(across, deep)
		local layout = trial or plan.layout
		-- A place of the layout in the plot's frame, on its floor: across, then studs in from the front edge.
		local function place(spot: { across: number, inward: number }, turn: number?): CFrame
			return at * CFrame.new(spot.across, 0, front + spot.inward) * CFrame.Angles(0, math.rad(turn or 0), 0)
		end
		-- The Void Breaker on the slant toward the gate, so a passer-by sees the shards cracking: two chambers, and its
		-- waiting line beside it.
		local breakerAt = place(layout.stations.breaker)
		local breaker = model(base, "Breaker", breakerAt)
		if machine(breaker, "Body", "Breaker", 1, number, at, front) == nil then
			block(breaker, "Body", Vector3.new(14, 5, 6), breakerAt * CFrame.new(0, 2.5, 0), tint("machine", GREY.Machine))
		end
		for index, x in { -3.5, 3.5 } do
			local chamber = machine(breaker, `Chamber {index}`, "BreakerChamber", index, number, at, front)
			if chamber then
				-- Low until it breaks a shard; its shard stands between the points meanwhile (BaseService).
				chamber:SetAttribute("Working", false)
				local shard = block(breaker, `Shard {index}`, SHARD.Size, breakerAt * CFrame.new(x, SHARD.Up, 0) * CFrame.Angles(0, math.rad(SHARD.Turn), 0), tint("chamber", GREY.Chamber))
				shard.Material = Enum.Material.Neon
				shard.Transparency = 1
				shard.CanCollide, shard.CanQuery, shard.CanTouch, shard.CastShadow = false, false, false, false
			else
				local box = block(breaker, `Chamber {index}`, Vector3.new(4, 4, 4), breakerAt * CFrame.new(x, 7, 0), tint("chamber", GREY.Chamber))
				if look then
					box.Material = Enum.Material.Neon
				end
			end
		end
		for index = 1, 3 do
			if machine(breaker, `Waiting {index}`, "BreakerWaiting", index, number, at, front) == nil then
				block(breaker, `Waiting {index}`, Vector3.new(2.5, 1, 2.5), breakerAt * CFrame.new(9 + (index - 1) * 3, 0.5, 0), tint("waiting", GREY.Chamber))
			end
		end
		Markers.Stamp(breaker, "Breaker", { Plot = number })
		-- Every bay the base can open, on the layout's places: level 1's two at the bus's ends, and the rest asleep where
		-- each will stand until a base level wakes it. Each past level 1's carries its Pad and its Sleeping piece, and
		-- BaseService shows one of the two by its owner's open bays.
		local bayPlaces = { layout.stations.bay1, layout.stations.bay2 }
		for _, later in layout.laterBays do
			table.insert(bayPlaces, later)
		end
		for index, spot in bayPlaces do
			local bayAt = place(spot)
			local bay = model(base, `Bay {index}`, bayAt)
			local asleep = index > 2 -- level 1 opens two (Config.Base.Levels.Bays)
			local pad = if asleep
				then machine(bay, "Pad", "BaySleeping", index - 2, number, at, front, "Bay")
				else machine(bay, "Pad", "Bay", index, number, at, front)
			-- Its light, in the worker's rarity colour while one works there (TR22): out of sight until then, one colour.
			local halo = if asleep
				then machine(bay, "Halo", "BaySleeping", index - 2, number, at, front, "BayHalo")
				else machine(bay, "Halo", "BayHalo", index, number, at, front)
			if halo then
				halo:ClearAllChildren()
				halo.Material = Enum.Material.Neon
				halo.Transparency = 1
			end
			-- A sleeping bay's pad and light stand for a later level: the dressing report counts level 1's.
			for _, part in { pad, halo } do
				if part and asleep then
					part:SetAttribute("Later", true)
				end
			end
			local sleeping = if asleep then machine(bay, "Sleeping", "BaySleeping", index - 2, number, at, front) else nil
			if pad == nil then
				pad = block(bay, "Pad", Vector3.new(10, 0.4, 10), bayAt * CFrame.new(0, 0.2, 0), tint("bay", GREY.Bay))
				pad:SetAttribute("Solid", true)
				if asleep then
					sleeping = block(bay, "Sleeping", Vector3.new(10, 0.6, 10), bayAt * CFrame.new(0, 0.3, 0), tint("locked", GREY.Locked))
					sleeping:SetAttribute("Solid", true)
				end
			end
			if pad and sleeping then
				stand(pad, false)
			end
			Markers.Stamp(bay, "Bay", { Plot = number, Bay = index })
		end
		-- The battery on the slant toward the back: its rack, and its bank of cells on the plan's seats, in the order they
		-- fill (AR15, section 4). BaseService shows as many as the base's level holds and lights each by the charge.
		local batteryAt = place(layout.stations.battery)
		local battery = model(base, "Battery", batteryAt)
		if machine(battery, "Rack", "BatteryRack", 1, number, at, front) then
			local bank = plan.machines.battery
			for seat, spot in bank.seats do
				local cell = piece(battery, `Cell {seat}`, "BatteryCell", { across = spot.across, along = spot.along, up = bank.up, turn = 0 }, number, at, front)
				if cell then
					cell:SetAttribute("Cell", seat)
					cell:SetAttribute("Lit", 0)
					cell:SetAttribute("Later", seat > bank.cellsAt["1"])
					stand(cell, false)
				end
			end
		else
			block(battery, "Body", Vector3.new(6, 3, 4), batteryAt * CFrame.new(0, 1.5, 0), tint("battery", GREY.Battery))
		end
		Markers.Stamp(battery, "Battery", { Plot = number })
		-- The generator at the plot's heart, at the end of the way in (TR18; AR19, the Void Mill): what stands still, its
		-- wheel, which the client turns by its owner's generation, the gauge's eight steps up the rising side, which
		-- BaseService shows as the generation lights them, and the demand's mark, which the client turns about the axle
		-- to the demand's share (Rules.Power.Gauge); a box while its kit isn't laid.
		local generator = WorldConfig.Grey.Generator
		local generatorAt = place(layout.stations.generator)
		local plant = model(base, "Generator", generatorAt)
		local body = machine(plant, "Body", "Generator", 1, number, at, front)
		if body == nil then
			block(plant, "Body", generator.Size, generatorAt * CFrame.new(0, generator.Size.Y / 2, 0), tint("generator", GREY.Generator))
		else
			millSolid(plant, body)
		end
		local wheel = machine(plant, "Wheel", "GeneratorWheel", 1, number, at, front)
		if wheel then
			wheel:SetAttribute("Generation", 0) -- its owner's kW (BaseService), by which the client turns it
		end
		for step = 1, generator.Gauge.Steps do
			local lit = machine(plant, `Step {step}`, `GeneratorArc{step}`, 1, number, at, front)
			if lit then
				lit:SetAttribute("Step", step)
				lit.Transparency = 1 -- hidden until the generation lights it: shown or hidden, never dimmed
			end
		end
		local mark = machine(plant, "Demand", "GeneratorDemand", 1, number, at, front)
		if mark then
			mark:SetAttribute("Share", 0) -- the demand's share of the gauge (BaseService), to which the client turns it
		end
		Markers.Stamp(plant, "Generator", { Plot = number })
		-- The Festival Door on the other slant toward the gate, turned to face down the way in (AR15, section 5): its
		-- frame, its way of light, and the unseen Way a player walks into (DoorService); the grey frame while its kit
		-- isn't laid.
		local doorAt = place(layout.stations.door, turnOf("Door"))
		local festival = model(base, "Festival Door", doorAt)
		if machine(festival, "Frame", "Door", 1, number, at, front) then
			local d = WorldConfig.Grey.Door
			-- Its way wears the festival seen through it, a print on the kit's atlas (AR15, section 6), tinted Light.
			local light = machine(festival, "Light", "DoorWay", 1, number, at, front)
			if light then
				light.Color = Color3.fromHex(d.Light)
				light.Transparency = d.LightFade
				light.CastShadow = false
			end
			local way = manifest.pieces.DoorWay.size
			local trigger = block(festival, "Way", Vector3.new(way[1], way[2], 1), if light then light.CFrame else doorAt * CFrame.new(0, way[2] / 2 + 0.5, 0), GREY.Pad)
			trigger.Transparency, trigger.CanCollide, trigger.CanQuery, trigger.CastShadow = 1, false, false, false
		else
			festival:Destroy()
			festival = door(base, "Festival Door", doorAt)
		end
		Markers.Stamp(festival, "FestivalDoor", { Plot = number })
		-- The Training machine (TR12) on the slant toward the back, as the battery is: its stone, its pad in front of it
		-- toward the gate, where a fallen lead comes home and trains (FightService), and its crown, which the client turns
		-- while a Voidkin trains (BaseService).
		local training = WorldConfig.Grey.Training
		local machineAt = place(layout.stations.training)
		local trainer = model(base, "Training machine", machineAt)
		if machine(trainer, "Body", "Training", 1, number, at, front) == nil then
			block(trainer, "Body", training.Size, machineAt * CFrame.new(0, training.Size.Y / 2, 0), tint("training", GREY.Machine))
			block(trainer, "Pad", Vector3.new(4, 0.4, 4), machineAt * CFrame.new(0, 0.2, training.Spot), tint("bay", GREY.Bay))
		end
		local crown = machine(trainer, "Crown", "TrainingCrown", 1, number, at, front)
		if crown then
			crown:SetAttribute("Training", false)
		end
		Markers.Stamp(trainer, "Training", { Plot = number })
		-- What the base will wake in its back half, asleep where each will stand (AR16): the Forge, the Condenser and the
		-- Lab, in the plan's order. Look only: nothing works there yet.
		local sleeping = model(base, "Sleeping", at)
		for index, name in { "Forge", "Condenser", "Lab" } do
			machine(sleeping, name, "SleepingStone", index, number, at, front)
		end
		-- And the Tower, asleep behind the back corner on the crossing's side until phase 3 (AR16): one silhouette on its
		-- lot's crossing end, look only. It stands with its plot's base: a bare lot has none.
		machine(sleeping, "Tower", "TowerSleeping", 1, number, at, front)
		-- The owner arrives at the gate, facing into the plot down the way in to the generator.
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Anchored = true
		spawn.Size = Vector3.new(6, 0.2, 6)
		-- Facing the Breaker and the three shards before it (docs/design.md, "The base", arrival), the way in and the
		-- generator in the same view.
		local spawnAt = place(layout.spawn).Position
		spawn.CFrame = CFrame.lookAt(spawnAt, Vector3.new(breakerAt.X, spawnAt.Y, breakerAt.Z)) * CFrame.new(0, 0.1, 0)
		spawn.Color = tint("spawn", GREY.Pad)
		spawn.Material = Enum.Material.SmoothPlastic
		spawn.Duration = 0 -- no shield
		spawn.Neutral = true
		spawn.Parent = base
		Markers.Stamp(spawn, "Spawn", { Plot = number })
		-- In part 7's trial, each machine's real footprint stands as a pale volume round its grey box, so the space
		-- between them reads as it will with the kit: walked through, never solid.
		if trial then
			local fit = model(base, "Fit", at)
			for _, box in BaseFit.Boxes(trial, WorldConfig.Fit.Prints :: any) do
				local size = Vector3.new(box.X1 - box.X0, box.High, box.Z1 - box.Z0)
				local middle = CFrame.new((box.X0 + box.X1) / 2, box.High / 2, front + (box.Z0 + box.Z1) / 2)
				local part = block(fit, box.Name, size, at * middle, GREY.Chamber)
				part.Transparency = 0.6
				part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = false, false, false, false
			end
		end
		if look then
			dressPlot(base, number, at, front)
		end
		base.Parent = m
		return base
	end
end

-- Each plot's base builder, as the last lay left it (plot()).
local bases: { [number]: () -> Model } = {}

local function lay(folder: Folder)
	local c = WorldConfig
	local function studs(seconds: number): number
		return seconds * c.Walk
	end
	local plots = c.Plots
	local across, deep = studs(plots.Across), studs(plots.Deep)
	local between, behind, tower = studs(plots.Between), studs(plots.Behind), studs(plots.Tower)
	local stripHalf = studs(c.Strip.Wide) / 2
	local perRow = plots.Count // 2
	local perSide = perRow // 2
	local crossingHalf = across / 2 -- the crossing is one plot wide
	local rowEnd = crossingHalf + perSide * across + math.max(0, perSide - 1) * between
	local stripEnd = rowEnd + studs(c.Strip.Ends)
	local towers = stripHalf + deep + behind + tower -- from the Strip's middle to the Towers' far edge
	local row = c.Row
	local rowHalf = studs(row.Wide) / 2
	local gateZ = -towers -- the festival gate, at the side street's end
	local function stopZ(index: number): number
		return gateZ - studs(row.FirstPack + (index - 1) * row.Spacing)
	end
	local stops = row.Stops
	local keeperZ = stopZ(#stops)
	local ringRadius = studs(row.Ring) / 2
	local ringZ = keeperZ - ringRadius
	local farZ = ringZ - ringRadius
	local shutZ = farZ - studs(row.Beyond)
	local high = c.Grey.Wall
	folder:SetAttribute("GateZ", gateZ)
	-- The grey look the kit replaces: the street's stall fronts, the square, the two gates. Kept as unseen
	-- colliders when the kit is laid; the ring and beyond stay grey (their dressing waits).
	local looks: { Instance } = {}
	local function under(item: Instance?)
		if item then
			table.insert(looks, item)
		end
	end

	-- The base's kit, if its template is built: its colours for every plot (AR14).
	local baseHeld = baseProblems()
	baseLook = nil
	if #baseHeld == 0 then
		local _, basePlan = kitFiles(BASE)
		local colours: { [string]: Color3 } = {}
		for name, hex in basePlan.standIns do
			if type(hex) == "string" and string.sub(hex, 1, 1) == "#" then
				colours[name] = Color3.fromHex(hex)
			end
		end
		colours.lot, colours.ground = Color3.fromHex(basePlan.ground.lot), Color3.fromHex(basePlan.ground.ground)
		baseLook = colours
	else
		Log.Info("WorldService", `the plots stay grey: {table.concat(baseHeld, "; ")}`)
	end
	-- The ground, under all of it.
	slab(folder, "Ground", -stripEnd, stripEnd, towers, shutZ - 24, GROUND_TOP, if baseLook then baseLook.ground else GREY.Ground)
	-- The Strip, the side street to the gate, and Lantern Row to the keeper's gate. With the base laid, the Strip and the
	-- side street wear Lantern Row's paving, as its street does: off the stones onto the plates is coming home (AR14).
	local strip = slab(folder, "Strip", -stripEnd, stripEnd, -stripHalf, stripHalf, PAVED_TOP, GREY.Paved)
	local sideStreet = slab(folder, "Side street", -rowHalf, rowHalf, gateZ, -stripHalf, PAVED_TOP, GREY.Paved)
	local stones = kitTemplate(DRESS)
	local stone = if baseLook and stones then stones:FindFirstChild("Paving") else nil
	if stone then
		stone:Clone().Parent = strip
		stone:Clone().Parent = sideStreet
	end
	-- The street's own floor carries the walking; dressed, it wears the kit's paving under the bays (AR5's manifest).
	local streetFloor = slab(folder, "Lantern Row", -rowHalf, rowHalf, keeperZ, gateZ, PAVED_TOP, GREY.Paved)

	-- The plots: two rows, numbered west to east, the north row first; each opens onto the Strip.
	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plots"
	plotFolder.Parent = folder
	for number = 1, plots.Count do
		local south = number > perRow
		local k = (number - 1) % perRow -- west to east
		local east = k >= perSide
		local fromCrossing = if east then k - perSide else perSide - 1 - k -- 0 is next to the crossing
		local x = (if east then 1 else -1) * (crossingHalf + fromCrossing * (across + between) + across / 2)
		local z = (if south then 1 else -1) * (stripHalf + deep / 2)
		local centre = Vector3.new(x, PAVED_TOP, z)
		local at = CFrame.lookAt(centre, centre + Vector3.new(0, 0, if south then -1 else 1))
		bases[number] = plot(plotFolder, number, at, across, deep, studs(plots.Kept), behind, tower)
	end

	-- The Shop, south of the crossing: every trip out and back passes its clock.
	local shopAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, stripHalf + 4), Vector3.new(0, PAVED_TOP, 0))
	local shop = model(folder, "Shop", shopAt)
	block(shop, "Building", Vector3.new(40, 14, 28), shopAt * CFrame.new(0, 7, 16), GREY.Machine)
	local clock = block(shop, "Clock", Vector3.new(1, 8, 8), shopAt * CFrame.new(0, 10, 1.5) * CFrame.Angles(0, math.pi / 2, 0), GREY.Pad)
	clock.Shape = Enum.PartType.Cylinder
	Markers.Stamp(shop, "Shop")
	slab(folder, "Shop's floor", -crossingHalf, crossingHalf, stripHalf, stripHalf + deep, PAVED_TOP, GREY.Plot)

	-- The festival gate, open.
	local north = Vector3.new(0, 0, -1)
	local gateAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, gateZ), Vector3.new(0, PAVED_TOP, gateZ) + north)
	local festivalGate = gate(folder, "Festival gate", gateAt, studs(row.Wide), high, false)
	under(festivalGate)
	Markers.Stamp(festivalGate, "FestivalGate")
	-- Its twin, inside the gate against the east stall front, takes the player home; the plots' doors land them before
	-- the gate in the street's middle, looking through it.
	local doors = c.Grey.Door
	local homeDoorAt = CFrame.lookAt(Vector3.new(rowHalf - 4, PAVED_TOP, gateZ - doors.AtGate), Vector3.new(0, PAVED_TOP, gateZ - doors.AtGate))
	Markers.Stamp(door(folder, "Home door", homeDoorAt, WorldConfig.Grey.Door.HomeWay), "GroundDoor", { Ground = row.Ground })
	-- Where the trail home goes (TR16), and the street it keeps to (its middle's X, its half width), on the folder that
	-- never streams out, as the door's own model may.
	folder:SetAttribute("HomeDoor", homeDoorAt.Position)
	folder:SetAttribute("Street", Vector2.new(0, rowHalf))
	local landingAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, gateZ + doors.Landing), Vector3.new(0, PAVED_TOP, gateZ + doors.Landing) + north)
	Markers.Stamp(spot(folder, "Door landing", landingAt), "DoorLanding", { Ground = row.Ground })

	-- Lantern Row's stops, and its stall fronts with the elite's square opened out of them.
	local street = Instance.new("Folder")
	street.Name = "Lantern Row"
	street.Parent = folder
	local squareHalf = studs(row.Square) / 2
	local openings: { { number } } = {} -- z ranges the stall fronts leave open
	local pack = 0
	local stopsAlong: { number } = {} -- each stop in studs up from the gate, for the kit's plan
	for index, stop in stops do
		local z = stopZ(index)
		table.insert(stopsAlong, gateZ - z)
		local at = CFrame.lookAt(Vector3.new(0, PAVED_TOP, z), Vector3.new(0, PAVED_TOP, z) + Vector3.new(0, 0, 1)) -- facing the way the player comes
		if stop.Kind == "Pack" then
			pack += 1
			Markers.Stamp(spot(street, `Pack {pack}`, at), "Pack", { Pack = pack, Def = stop.Def, Level = stop.Level, Count = stop.Count or 1, Ground = row.Ground })
		elseif stop.Kind == "Elite" then
			under(slab(street, "Square", -squareHalf, squareHalf, z - squareHalf, z + squareHalf, PAVED_TOP + OVERLAY, GREY.Plot))
			table.insert(openings, { z - squareHalf, z + squareHalf })
			for _, side in { -1, 1 } do
				under(wallZ(street, side * (squareHalf + 1), z - squareHalf, z + squareHalf, high))
				under(wallX(street, z - squareHalf - 1, side * (rowHalf + 1), side * (squareHalf + 2), high))
				under(wallX(street, z + squareHalf + 1, side * (rowHalf + 1), side * (squareHalf + 2), high))
			end
			Markers.Stamp(spot(street, "Elite", at), "Elite", { Def = stop.Def, Level = stop.Level, Ground = row.Ground })
		elseif stop.Kind == "Keeper" then
			local keeperAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, z), Vector3.new(0, PAVED_TOP, z) + north)
			local keeperGate = gate(street, "Keeper's gate", keeperAt, studs(row.Wide), high, true)
			under(keeperGate)
			Markers.Stamp(keeperGate, "KeeperGate")
			-- The ring behind it: a floor and a low wall round it.
			local ringAt = CFrame.new(0, PAVED_TOP, ringZ)
			local ring = model(street, "Ring", ringAt)
			local floor = block(ring, "Floor", Vector3.new(0.2, ringRadius * 2, ringRadius * 2), ringAt * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2), GREY.Plot)
			floor.Shape = Enum.PartType.Cylinder
			local segments = 24
			for s = 1, segments do
				local angle = (s - 0.5) * 2 * math.pi / segments
				local length = 2 * ringRadius * math.sin(math.pi / segments) + 0.5
				local facing = CFrame.Angles(0, -angle, 0)
				local spotAt = ringAt * facing * CFrame.new(0, 1.5, -ringRadius)
				if math.abs(spotAt.Position.X) < rowHalf and spotAt.Position.Z > ringZ then
					continue -- open where the keeper's gate lets in
				end
				block(ring, "Rail", Vector3.new(length, 3, 1), spotAt, GREY.Wall)
			end
			Markers.Stamp(ring, "Ring", { Def = stop.Def, Level = stop.Level, Ground = row.Ground })
		end
	end
	-- The stall fronts, from the gate to the keeper's gate, open at the square; then round the ring to the shut gate.
	table.sort(openings, function(a: { number }, b: { number }): boolean
		return a[2] > b[2]
	end)
	for _, side in { -1, 1 } do
		local from = gateZ
		for _, opening in openings do
			under(wallZ(street, side * (rowHalf + 1), from, opening[2] + 2, high))
			from = opening[1] - 2
		end
		under(wallZ(street, side * (rowHalf + 1), from, keeperZ, high))
		wallX(street, keeperZ, side * (rowHalf + 1), side * (ringRadius + 2), high)
		wallZ(street, side * (ringRadius + 2), keeperZ, shutZ, high)
	end
	slab(street, "Ring's ground", -ringRadius - 2, ringRadius + 2, shutZ, keeperZ, PAVED_TOP, GREY.Paved)

	-- Beyond the ring: Drum Court's gate, shut, in view; the shortcut home; where a win sets the player down.
	local shutAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, shutZ), Vector3.new(0, PAVED_TOP, shutZ) + north)
	local shut = gate(street, "Drum Court's gate", shutAt, studs(row.Wide), high, true)
	wallX(street, shutZ, -(ringRadius + 2), -(rowHalf + 2), high)
	wallX(street, shutZ, rowHalf + 2, ringRadius + 2, high)
	Markers.Stamp(shut, "ShutGate")
	local beyondZ = (farZ + shutZ) / 2
	local shortcutAt = CFrame.new(rowHalf - 4, PAVED_TOP, beyondZ)
	local shortcut = block(street, "Shortcut", Vector3.new(6, 0.3, 6), shortcutAt * CFrame.new(0, 0.15, 0), GREY.Pad)
	shortcut.Material = Enum.Material.Neon
	Markers.Stamp(shortcut, "Shortcut")
	local exitAt = CFrame.lookAt(Vector3.new(-(rowHalf - 4), PAVED_TOP, beyondZ), Vector3.new(-(rowHalf - 4), PAVED_TOP, beyondZ) + north)
	Markers.Stamp(spot(street, "Ring exit", exitAt), "RingExit")

	-- The kit, over the grey street: its look hidden, its colliders kept.
	folder:SetAttribute("Stops", table.concat(stopsAlong, ","))
	local problems = dressProblems(stopsAlong)
	if #problems > 0 then
		Log.Info("WorldService", `Lantern Row stays grey: {table.concat(problems, "; ")}`)
		return
	end
	dress(street, gateZ)
	local paving = (kitTemplate() :: Instance):FindFirstChild("Paving")
	if paving then
		paving:Clone().Parent = streetFloor
	end
	for _, item in looks do
		local parts = if item:IsA("BasePart") then { item } else item:GetDescendants()
		for _, part in parts do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end
	folder:SetAttribute("Dressed", DRESS)
end

local function build(): Folder
	local folder = Instance.new("Folder")
	folder.Name = WORLD
	folder:SetAttribute("Grey", true)
	lay(folder)
	folder.Parent = workspace
	return folder
end

-- The plots' owners, and each player's.
local owners: { [number]: Player } = {}

-- A plot's lot in the world, or nil.
local function lotOf(number: number): Instance?
	local world = workspace:FindFirstChild(WORLD)
	local plots = if world then world:FindFirstChild("Plots") else nil
	return if plots then plots:FindFirstChild(`Plot {number}`) else nil
end

-- A plot's base stood for its owner, once; Built tells whatever stands on its markers.
local function raise(number: number)
	local lot = lotOf(number)
	if lot == nil or lot:FindFirstChild("Base") or bases[number] == nil then
		return
	end
	bases[number]()
	WorldService.Built:Fire(number)
end

-- A plot no one owns any more back to its bare lot.
local function clear(number: number)
	local lot = lotOf(number)
	local base = if lot then lot:FindFirstChild("Base") else nil
	if base then
		base:Destroy()
	end
end

-- The owned plots, for the reports.
local function owned(): { [number]: boolean }
	local set: { [number]: boolean } = {}
	for number in owners do
		set[number] = true
	end
	return set
end

function WorldService.PlotOf(player: Player): number?
	local plot = player:GetAttribute("Plot")
	return if type(plot) == "number" then plot else nil
end

-- Where a player's plot sets them down: its spawn, or nil when they have no plot.
function WorldService.SpawnOf(player: Player): CFrame?
	local plot = WorldService.PlotOf(player)
	local spawn = if plot then Markers.Find("Spawn", { Plot = plot }) else nil
	return if spawn then Markers.At(spawn) else nil
end

-- Roblox's own respawn lands on the plot's spawn too.
local function respawnOn(player: Player)
	local plot = WorldService.PlotOf(player)
	local spawn = if plot then Markers.Find("Spawn", { Plot = plot }) else nil
	if spawn and spawn:IsA("SpawnLocation") then
		player.RespawnLocation = spawn
	end
end

local function arrive(player: Player)
	for number = 1, WorldConfig.Plots.Count do
		if owners[number] == nil then
			owners[number] = player
			raise(number) -- before the attribute, so whatever reads the plot finds its base standing
			player:SetAttribute("Plot", number)
			respawnOn(player)
			return
		end
	end
	Log.Warn("WorldService", `no free plot for {player.Name}: Max Players should be {WorldConfig.Plots.Count}`)
end

local function leave(player: Player)
	for number, owner in owners do
		if owner == player then
			owners[number] = nil
			clear(number)
		end
	end
end

-- A new avatar on its plot's spawn, facing the Breaker, then the client opens from black with the camera behind it. The
-- event reaches the client after the pivot does, so the camera turns behind the final facing, never the spawn's first.
local function setDown(player: Player, character: Model)
	local at = WorldService.SpawnOf(player)
	if at then
		character:PivotTo(at * CFrame.new(0, SPAWN_UP, 0))
		Net.Server.Fire("Fade", player, 0, 0, WorldConfig.Arrive)
	end
end

function WorldService.Init()
	local authored = workspace:FindFirstChild(WORLD)
	if authored == nil then
		build()
	elseif authored:GetAttribute("Grey") == true then
		authored:Destroy() -- a grey world saved into the place by mistake: lay it fresh from Config
		build()
	end
	DebugService.Register("WorldReport", function(): { string }
		return Markers.Report(WorldConfig.Plots.Count, owned())
	end)
	-- Part 7's trial (Config.World.Fit): ("BaseSize", nil, 144) lays the plots grey at that size, Fit.Between apart, on
	-- Fit's layout; ("BaseSize") puts today's back. Either way it answers Rules.BaseFit's line for today's and each size.
	local today = { Across = WorldConfig.Plots.Across, Deep = WorldConfig.Plots.Deep, Between = WorldConfig.Plots.Between }
	DebugService.Register("BaseSize", function(_who: any, size: any): { string }
		local walk = WorldConfig.Walk
		local fit = WorldConfig.Fit
		local cells = if type(size) == "number" then size / walk else nil
		TuneService.Set("World.Plots.Across", cells or today.Across)
		TuneService.Set("World.Plots.Deep", cells or today.Deep)
		TuneService.Set("World.Plots.Between", if cells then fit.Between else today.Between)
		local _, plan = kitFiles(BASE)
		local kept = WorldConfig.Plots.Kept * walk
		local lines = {
			BaseFit.Line(BaseFit.Measure(plan.layout, today.Across * walk, fit :: any, { Walk = walk, Between = today.Between * walk, Kept = kept }), fit :: any) .. " (today's, AR16)",
		}
		for _, each in fit.Sizes do
			local studs = each * walk
			local layout = (fit.Layouts :: any)[tostring(studs)]
			if layout then
				table.insert(lines, BaseFit.Line(BaseFit.Measure(layout, studs, fit :: any, { Walk = walk, Between = fit.Between * walk, Kept = kept }), fit :: any))
			end
		end
		return lines
	end)
	-- The dressing against its plan: every piece laid as often as the plan has it, each with its look, the plan's lights,
	-- and the grey look under it hidden; then each plot against its base level's plan (AR14), its lights and its level's
	-- number; a plot no one owns, its bare lot. Empty when it's whole; one line when the street or the plots are grey, and
	-- why.
	DebugService.Register("DressReport", function(): { string }
		local world = workspace:FindFirstChild(WORLD)
		if world == nil then
			return { "no world" }
		end
		if world:GetAttribute("Dressed") ~= DRESS then
			local stops: { number } = {}
			for _, along in string.split(tostring(world:GetAttribute("Stops") or ""), ",") do
				table.insert(stops, tonumber(along) or 0)
			end
			return { `grey: {table.concat(dressProblems(stops), "; ")}` }
		end
		local _, plan = kitFiles()
		local want: { [string]: number } = {}
		for _, placement in plan.placements do
			want[placement.piece] = (want[placement.piece] or 0) + 1
		end
		local got: { [string]: number } = {}
		local lights, paper, problems = 0, 0, {}
		for _, item in CollectionService:GetTagged(Kit.Tag) do
			if not item:IsDescendantOf(world) or item:GetAttribute("Plot") ~= nil then
				continue
			end
			local piece = item:GetAttribute("Piece")
			if type(piece) == "string" then
				got[piece] = (got[piece] or 0) + 1
				if item:FindFirstChildOfClass("SurfaceAppearance") == nil then
					table.insert(problems, `{item:GetFullName()}: no look`)
				end
			elseif item:GetAttribute("Paper") then
				paper += if item:FindFirstChildOfClass("ParticleEmitter") then 1 else 0
			elseif item:FindFirstChildWhichIsA("Light") then
				lights += 1
			end
		end
		for piece, count in want do
			if got[piece] ~= count then
				table.insert(problems, `{piece}: {got[piece] or 0} laid, the plan has {count}`)
			end
		end
		if lights ~= #plan.lights then
			table.insert(problems, `{lights} lights, the plan has {#plan.lights}`)
		end
		local boxes = if plan.paper then #plan.paper.boxes else 0
		if paper ~= boxes then
			table.insert(problems, `{paper} boxes of drifting paper, the plan has {boxes}`)
		end
		local row = world:FindFirstChild("Lantern Row")
		if row == nil or row:FindFirstChild("Paving") == nil then
			table.insert(problems, "the street's floor wears no paving")
		end
		-- The plots: each one's Dressing against its level, and the lot, the Strip and the side street paved.
		local held = baseProblems()
		local plots = world:FindFirstChild("Plots")
		if #held > 0 or plots == nil then
			table.insert(problems, `plots grey: {table.concat(held, "; ")}`)
		else
			local _, basePlan = kitFiles(BASE)
			local level = basePlan.levels[BASE_LEVEL]
			local each: { [string]: number } = {}
			for _, placement in level.placements do
				each[placement.piece] = (each[placement.piece] or 0) + 1
			end
			local standing: { [string]: number } = {}
			for _, placement in (if basePlan.machines then basePlan.machines.placements else {}) do
				standing[placement.piece] = (standing[placement.piece] or 0) + 1
			end
			for number = 1, WorldConfig.Plots.Count do
				local lot = plots:FindFirstChild(`Plot {number}`)
				local floor = if lot then lot:FindFirstChild("Floor") else nil
				if floor == nil or floor:FindFirstChild("Paving") == nil then
					table.insert(problems, `Plot {number}: the lot wears no deck`)
				end
				local m = if lot then lot:FindFirstChild("Base") else nil
				if owners[number] == nil then
					if m then
						table.insert(problems, `Plot {number}: no one's, but its base stands`)
					end
					continue
				end
				local dressing = if m then m:FindFirstChild("Dressing") else nil
				if dressing == nil then
					table.insert(problems, `Plot {number}: not dressed`)
					continue
				end
				local count: { [string]: number } = {}
				local plotLights = 0
				for _, item in dressing:GetChildren() do
					local piece = item:GetAttribute("Piece")
					if type(piece) == "string" then
						count[piece] = (count[piece] or 0) + 1
						if item:FindFirstChildOfClass("SurfaceAppearance") == nil then
							table.insert(problems, `Plot {number} {piece}: no look`)
						end
					elseif item:FindFirstChildWhichIsA("Light") then
						plotLights += 1
					end
				end
				for piece, needed in each do
					if count[piece] ~= needed then
						table.insert(problems, `Plot {number} {piece}: {count[piece] or 0} laid, level {BASE_LEVEL} has {needed}`)
					end
				end
				if plotLights ~= #level.lights then
					table.insert(problems, `Plot {number}: {plotLights} lights, level {BASE_LEVEL} has {#level.lights}`)
				end
				if level.levelMark and dressing:FindFirstChild("LevelMark") == nil then
					table.insert(problems, `Plot {number}: no level mark`)
				end
				-- The machines with their model, each in place of its box (AR15), as level 1 stands them: a sleeping bay's
				-- pad and light, and the cells past level 1's, are a later level's (AR16).
				local machines: { [string]: number } = {}
				for _, item in (m :: Instance):GetDescendants() do
					local piece = item:GetAttribute("Piece")
					if type(piece) == "string" and item.Parent ~= dressing and item:GetAttribute("Later") ~= true then
						machines[piece] = (machines[piece] or 0) + 1
					end
				end
				for piece, needed in standing do
					if machines[piece] ~= needed then
						table.insert(problems, `Plot {number} {piece}: {machines[piece] or 0} stand, the plan's machines have {needed}`)
					end
				end
				-- A piece placed toward the crossing stands on the plot's crossing side (AR16's Tower).
				local pivot = (m :: Model).WorldPivot
				local side = crossingSide(pivot)
				for _, placement in (if basePlan.machines then basePlan.machines.placements else {}) do
					if placement.toward == "crossing" then
						for _, item in (m :: Instance):GetDescendants() do
							if item:IsA("BasePart") and item:GetAttribute("Piece") == placement.piece then
								local across = pivot:PointToObjectSpace(item.Position).X
								if across * side <= 0 then
									table.insert(problems, `Plot {number} {placement.piece}: stands away from the crossing`)
								end
							end
						end
					end
				end
			end
			for _, name in { "Strip", "Side street" } do
				local street = world:FindFirstChild(name)
				if street == nil or street:FindFirstChild("Paving") == nil then
					table.insert(problems, `the {name} wears no paving`)
				end
			end
		end
		table.sort(problems)
		return problems
	end)
	-- A jump of the server's turn of dusk and night to a phase's start (Rules.Night), every client with it.
	DebugService.Register("Night", function(_who: any, phase: any): string
		local name = tostring(phase)
		workspace:SetAttribute(Night.Attribute, Night.From(name, workspace:GetServerTimeNow(), LightingConfig.Cycle :: any))
		return name
	end)
	-- A fresh arrival, as after a fall or a reset: Respawn (the bridge passes the caller first).
	DebugService.Register("Respawn", function(who: any): boolean
		local player = if typeof(who) == "Instance" then who :: Instance else nil
		if player and player:IsA("Player") then
			player:LoadCharacterAsync()
			return true
		end
		return false
	end)
end

function WorldService.Start()
	for _, problem in Markers.Report(WorldConfig.Plots.Count, owned()) do
		Log.Warn("WorldService", problem)
	end
	local function join(player: Player)
		arrive(player)
		player.CharacterAdded:Connect(function(character: Model)
			setDown(player, character)
		end)
		if player.Character then
			setDown(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		join(player)
	end
	Players.PlayerRemoving:Connect(leave)
	-- A World number tuned in a playtest: lay the grey world again, once for a burst of tunes. A number read live, that
	-- moves nothing laid, leaves it be.
	local pending = false
	TuneService.Changed:Connect(function(path: string)
		local current = workspace:FindFirstChild(WORLD)
		local laid = string.sub(path, 1, 6) == "World." and not READ_LIVE[path]
		if not laid or current == nil or current:GetAttribute("Grey") ~= true or pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			local old = workspace:FindFirstChild(WORLD)
			if old then
				old:Destroy()
			end
			build()
			for number in owners do
				raise(number)
			end
			for _, player in Players:GetPlayers() do
				respawnOn(player)
			end
			WorldService.Laid:Fire()
		end)
	end)
end

return WorldService
