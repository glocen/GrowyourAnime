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
local Tower = require(Shared.Rules.Tower)
local Net = require(Shared.Net)
local Markers = require(Shared.World.Markers)
local Log = require(Shared.Util.Log)
local Signal = require(Shared.Util.Signal)
local PlaceRole = require(Shared.Util.PlaceRole)
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
local GROUND_PAST = 43 -- studs of the base's ground past a Tower lot's middle: as far as AR41's platforms reached, plus 16
local SPAWN_UP = 3 -- an R6 root stands 3 studs over its floor
local DRESS = "LanternRow" -- the kit Lantern Row wears: Config.Kits.LanternRow, ServerStorage.Templates.LanternRowKit
local DRESS_LIFT = 0.05 -- the kit's floors stand a hair over the paving they cover, so the two never fight at a distance
local LIGHT_CEILING = 14 -- round 2's lights, the ceiling the kit keeps (AR5, section 2)
-- Which world this place lays (TR45): Lantern Row's street in the Festival's place, the base's Strip and plots in the
-- main one. Read once: a place never changes role.
local FESTIVAL = PlaceRole.Is("Festival")
local FORECOURT = 24 -- the Festival's paving reaches this far before its gate, where a trip sets the player down
local BASE = "Base" -- the kit every plot wears: Config.Kits.Base, ServerStorage.Templates.BaseKit (AR14)
local STRIP = "Strip" -- the kit the Strip and the side street wear: Config.Kits.Strip, ServerStorage.Templates.StripKit (AR17)
local TOWER = "TowerRoom" -- the Tower's kit, its room and its gate: Config.Kits.TowerRoom, ServerStorage.Templates.TowerRoomKit (AR56)
local VEIL = 0.55 -- the gate's door of light, seen through (AR56's lot plan)
-- The Shop's building from the Strip's kit (AR38, installed with AR40's C), in its place's frame (the manifest's notes):
-- the marker stands before the counter, whose face is 9 behind the place; the five minutes hang at these across, the
-- first to run at 17, along -5.9 and up 12.2.
local SHOP_COUNTER = 8
local SHOP_MINUTES = { 17, 14, 11, 8, 5 }
local SHOP_MINUTE_ALONG, SHOP_MINUTE_UP = -5.9, 12.2
local BASE_LEVEL = "1" -- the plan's level laid on every plot, until the base has its levels (TR21)
local LEVEL_FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold) -- the HUD's numbers
local LEVEL_PIXELS = 40 -- the level's number, a SurfaceGui's pixels a stud
local PLATE_EDGE = 0.04 -- the plate's words clear of its edges, a share of its size
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
	Ring = Color3.fromRGB(150, 152, 160), -- the Tower's ring, lighter than its lot (TR29)
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

-- The Tower's gate on a lot (AR56; the plan's lot placements, in the lot's frame: Rules.Tower.Lot): the dais, its door of
-- light, its two blades and the record's slab, from the kit's template. Their glow is the kit's own, not the base's
-- dressing (no Kit.Tag). The slab is the client's to write (TowerRoomController; its Record kept by TowerService).
local function layGate(ring: Model, lot: CFrame, number: number)
	local template = kitTemplate(TOWER)
	if template == nil then
		Log.Warn("WorldService", `the Tower's template isn't built (ServerStorage.Templates.{TOWER}Kit): no gate on plot {number}`)
		return
	end
	local manifest, plan = kitFiles(TOWER)
	for _, placement in plan.lot.placements do
		local part = (template:FindFirstChild(placement.piece) :: BasePart):Clone()
		part.Anchored = true
		part.Size *= placement.scale
		part.CFrame = Kit.Room(lot, placement, manifest.pieces[placement.piece])
		part.Name = if placement.tag ~= "" then placement.tag else placement.piece
		part:SetAttribute("Piece", placement.piece)
		part:SetAttribute("Plot", number)
		if placement.piece == "GateVeil" then
			part.Transparency = VEIL
		elseif placement.piece == "CrownSlab" then
			CollectionService:AddTag(part, "GA_TowerSlab")
		end
		part.Parent = ring
	end
end

-- Why the base's kit can't be laid on the plots: none when it can.
local function baseProblems(): { string }
	local plots = WorldConfig.Plots
	if plots.Across ~= plots.Drawn or plots.Deep ~= plots.Drawn then
		return { `the plots are {plots.Across * WorldConfig.Walk} studs and the plan is drawn for {plots.Drawn * WorldConfig.Walk}` }
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

-- Why the Strip's kit can't be laid: none when it can.
local function stripProblems(): { string }
	local template = kitTemplate(STRIP)
	if template == nil then
		return { `the Strip's template isn't built (ServerStorage.Templates.{STRIP}Kit: tools/studio/KitAssembly)` }
	end
	local manifest, plan = kitFiles(STRIP)
	local problems: { string } = {}
	for index, placement in plan.placements do
		local piece = template:FindFirstChild(placement.piece)
		if manifest.pieces[placement.piece] == nil then
			table.insert(problems, `placement {index}: "{tostring(placement.piece)}" isn't in the Strip's manifest`)
		elseif piece == nil or not piece:IsA("BasePart") then
			table.insert(problems, `the Strip's template has no part {placement.piece}`)
		end
	end
	if template:FindFirstChild("Paving") == nil then
		table.insert(problems, "the Strip's template has no Paving")
	end
	return problems
end

-- The Strip's kit (AR17): the void's own, from the crossing to the sealed gates and up the side street to the festival's
-- gate, in Lantern Row's plan's frame (Kit.Place from the gate at `gateZ`), with the plan's seven lights, Shadows off.
-- Every piece and light is tagged for the client's look and carries its kit, so the street's count leaves them out.
local function dressStrip(parent: Instance, gateZ: number)
	local template = kitTemplate(STRIP) :: Instance
	local manifest, plan = kitFiles(STRIP)
	local folder = Instance.new("Folder")
	folder.Name = "Strip dressing"
	local floorY = PAVED_TOP + DRESS_LIFT
	for _, placement in plan.placements do
		local part = (template:FindFirstChild(placement.piece) :: BasePart):Clone()
		part.Anchored = true
		part.CFrame = Kit.Place(placement, manifest.pieces[placement.piece], gateZ, floorY)
		part:SetAttribute("Piece", placement.piece)
		part:SetAttribute("Kit", STRIP)
		CollectionService:AddTag(part, Kit.Tag)
		part.Parent = folder
	end
	for _, light in plan.lights do
		kitLight(light, Kit.Light(light, gateZ, floorY), folder):SetAttribute("Kit", STRIP)
	end
	folder.Parent = parent
end

-- The Shop's building from the Strip's kit (AR38; the manifest's VoidShop, VoidShopCrown and VoidShopMinute), into `shop`
-- at `place`: the building and its crown on the place, the five minutes on its turn, and the two pieces' own lights.
-- The crown and its light show only while the standing stock holds a piece (ShopService's ShopFeatured). Each minute
-- carries its number, its root under the slab, its full size and its centre, so the client runs the clock
-- (ShopController). Every piece carries Shop, so the Strip's count leaves them out.
local function dressShop(shop: Model, place: CFrame)
	local template = kitTemplate(STRIP) :: Instance
	local manifest = kitFiles(STRIP)
	local function mark(item: Instance)
		item:SetAttribute("Kit", STRIP)
		item:SetAttribute("Shop", true)
	end
	local function lay(piece: string, at: CFrame, name: string?): BasePart
		local part = (template:FindFirstChild(piece) :: BasePart):Clone()
		local c = manifest.pieces[piece].centre
		part.Name = name or piece
		part.Anchored = true
		part.CFrame = at * CFrame.new(c[1], c[2], c[3])
		part:SetAttribute("Piece", piece)
		mark(part)
		CollectionService:AddTag(part, Kit.Tag)
		part.Parent = shop
		return part
	end
	lay("VoidShop", place)
	local crown = lay("VoidShopCrown", place)
	for index, across in SHOP_MINUTES do
		local root = place * CFrame.new(across, SHOP_MINUTE_UP, -SHOP_MINUTE_ALONG)
		local minute = lay("VoidShopMinute", root, `VoidShopMinute{index}`)
		local c = manifest.pieces.VoidShopMinute.centre
		minute:SetAttribute("Minute", index)
		minute:SetAttribute("Root", root)
		minute:SetAttribute("Full", minute.Size)
		minute:SetAttribute("Centre", Vector3.new(c[1], c[2], c[3]))
	end
	local crownLight: Light? = nil
	for _, piece in { "VoidShop", "VoidShopCrown" } do
		for _, light in manifest.pieces[piece].lights or {} do
			local a = light.at
			local holder = kitLight({ name = light.name, colour = light.colour, kind = "point" } :: any, place * CFrame.new(a[1], a[2], a[3]), shop)
			mark(holder)
			if piece == "VoidShopCrown" then
				crownLight = holder:FindFirstChildWhichIsA("Light")
			end
		end
	end
	local function crowned()
		local on = workspace:GetAttribute("ShopFeatured") == true
		crown.Transparency = if on then 0 else 1
		if crownLight then
			crownLight.Enabled = on
		end
	end
	crowned()
	local watch = workspace:GetAttributeChangedSignal("ShopFeatured"):Connect(crowned)
	shop.Destroying:Connect(function()
		watch:Disconnect()
	end)
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
		if placement.piece == "Showcase" then
			-- Where its Voidkin stands (TR22; BaseService): the piece's foot at its middle, Up over it, facing the Strip.
			local c = manifest.pieces[placement.piece].centre
			part:SetAttribute("Stand", part.CFrame * CFrame.new(-c[1], WorldConfig.Showcase.Up - c[2], -c[3]))
		end
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
		-- The owner's name over the base's level (TR22), both lines written by BaseService as the save changes.
		local words = WorldConfig.Plate
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local gui = Instance.new("SurfaceGui")
			gui.Name = face.Name
			gui.Face = face
			gui.LightInfluence = 0
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = LEVEL_PIXELS
			for _, name in { "Owner", "Level" } do -- the name from the top edge, the level from the bottom
				local line = if name == "Owner" then words.Name else words.Level
				local said = Instance.new("TextLabel")
				said.Name = name
				said.BackgroundTransparency = 1
				said.AnchorPoint = Vector2.new(0.5, if name == "Owner" then 0 else 1)
				said.Position = UDim2.fromScale(0.5, if name == "Owner" then PLATE_EDGE else 1 - PLATE_EDGE)
				said.Size = UDim2.fromScale(1 - 2 * PLATE_EDGE, line.Share)
				said.FontFace = LEVEL_FACE
				said.TextScaled = true
				said.TextColor3 = line.Ink
				said.Text = ""
				said.Parent = gui
			end
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
	-- Stages II and III (the manifest's collision on Generator2 and Generator3): the sill's middle 5.1 toward the gate
	-- and the legs' heads with it; the footprint on the ground as Stage I's.
	Later = { SillAt = Vector3.new(0, 0.7, -5.1), LegTo = Vector3.new(1.5, 8.7, 4.1) },
}

local function millSolid(plant: Instance, body: BasePart, stage: number)
	local c = (kitFiles(BASE)).pieces[body:GetAttribute("Piece") :: string].centre
	local origin = body.CFrame * CFrame.new(-c[1], -c[2], -c[3])
	local later = if stage > 1 then MILL_SOLID.Later else nil
	local function solid(name: string, size: Vector3, frame: CFrame, shape: Enum.PartType?)
		local part = block(plant, name, size, origin * frame, GREY.Machine)
		part.Shape = shape or Enum.PartType.Block
		part.Transparency, part.CastShadow, part.CanTouch = 1, false, false
		part:SetAttribute("Solid", true)
		part:SetAttribute("Unseen", true) -- never seen: BaseService opens it while its stage is hidden, never shows it
	end
	local well = MILL_SOLID.Well
	solid("Well's solid", Vector3.new(well.High, well.Radius * 2, well.Radius * 2), CFrame.new(0, well.High / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	solid("Sill's solid", MILL_SOLID.Sill.Size, CFrame.new(if later then later.SillAt else MILL_SOLID.Sill.At))
	for _, side in { 1, -1 } do
		local flip = Vector3.new(side, 1, 1)
		solid("Foot's solid", MILL_SOLID.Feet.Size, CFrame.new(MILL_SOLID.Feet.At * flip))
		local from, to = MILL_SOLID.Leg.From * flip, (if later then later.LegTo else MILL_SOLID.Leg.To) * flip
		local thick = MILL_SOLID.Leg.Thick
		solid("Leg's solid", Vector3.new(thick, thick, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to))
	end
end

-- A machine with its model (AR15; the plan's machines) in place of its grey box: the plan's `nth` placement of `placed`,
-- laid as a placement is and raised by its `up`, wearing the piece `as` (`placed` itself unless given: a bay a level
-- wakes stands where its sleeping bay stood), named as the box it replaces. Nil while the base's kit isn't laid or the
-- plan has no such machine: then the box stands.
-- The plan's `nth` placement of `placed` as it stands on the plot at `at`; nil while the kit isn't laid or it has none.
local function placementOf(placed: string, nth: number, at: CFrame): any?
	if baseLook == nil then
		return nil
	end
	local _, plan = kitFiles(BASE)
	local seen = 0
	for _, placement in (if plan.machines then plan.machines.placements else {}) do
		if placement.piece == placed then
			seen += 1
			if seen == nth then
				return Kit.Toward(placement, crossingSide(at))
			end
		end
	end
	return nil
end

local function machine(parent: Instance, name: string, placed: string, nth: number, number: number, at: CFrame, front: number, as: string?): BasePart?
	local placement = placementOf(placed, nth, at)
	return if placement then piece(parent, name, as or placed, placement, number, at, front) else nil
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

-- A stage piece's placement (TR51): `offset` (across, toward the gate, up) in its machine's own frame, turned with its
-- machine's placement `home` (a swap's table: AR32 to AR35).
local function within(home: any, offset: { number }): any
	local turn = math.rad(home.turn or 0)
	return {
		across = home.across + offset[1] * math.cos(turn) - offset[2] * math.sin(turn),
		along = home.along + offset[1] * math.sin(turn) + offset[2] * math.cos(turn),
		up = (home.up or 0) + offset[3],
		turn = home.turn or 0,
	}
end

-- A machine's stage group (TR51): its own model "Stage n" in `holder`, which BaseService shows at its machine's stage.
local function stageGroup(holder: Instance, stage: number, at: CFrame): Model
	local group = model(holder, `Stage {stage}`, at)
	group:SetAttribute("Stage", stage)
	return group
end

-- A piece of a machine's stage, laid from its swap's row in the machine's frame. One past Stage I, or any while `later`
-- (a bay asleep), is a later level's: the dressing report counts level 1's, and it stands hidden until BaseService
-- shows its stage.
local function stagePiece(group: Instance, name: string, kind: string, home: any, offset: { number }, stage: number, later: boolean, number: number, at: CFrame, front: number): BasePart?
	local part = piece(group, name, kind, within(home, offset), number, at, front)
	if part then
		part:SetAttribute("Stage", stage)
		if later or stage > 1 then
			part:SetAttribute("Later", true)
			stand(part, false)
		end
	end
	return part
end

-- A stage's turning piece (TR51; AR32's hinges, AR33's rings): about its own axle `axis`, its row's `sign` the way,
-- `speed` turns a second while BaseService says it's "Spinning" (BaseController turns it).
local function spinner(part: BasePart?, axis: string, sign: number, speed: number)
	if part then
		part:SetAttribute("Moves", "turns")
		part:SetAttribute("Axis", axis)
		part:SetAttribute("Sign", sign)
		part:SetAttribute("Speed", speed)
		part:SetAttribute("Spinning", false)
	end
end

-- What the yard gains at base levels 2 and 3 (AR50; the plan's machines.baseLevels), in "Levels": each level's pieces
-- beside those of the level under it, never in their place, each a later level's ("BaseLevel" the first it stands at),
-- hidden until BaseService shows it by its owner's base. Rows are laid as placements are; a ring stands tilted on the
-- plan's axle (CFrame.Angles(0, 0, lean) * CFrame.Angles(tilt, 0, 0) in the plot's frame) and turns about its own Y,
-- always, its row's `rate` turns a second the way its `sign` says (BaseController). The fins are solid while shown.
local function layLevels(base: Instance, number: number, at: CFrame, front: number)
	local manifest, plan = kitFiles(BASE)
	local levels = if plan.machines then plan.machines.baseLevels else nil
	if levels == nil or baseLook == nil then
		return
	end
	local holder = model(base, "Levels", at)
	for key, level in levels.levels do
		for index, row in level.pieces do
			local part = piece(holder, `{row.piece} {index}`, row.piece, { across = row.across, along = row.along, up = row.up, turn = 0 }, number, at, front)
			if part == nil then
				continue
			end
			if row.moves == "turns" then
				local c = manifest.pieces[row.piece].centre
				part.CFrame = at
					* CFrame.new(row.across, DRESS_LIFT + row.up, front - row.along)
					* CFrame.Angles(0, 0, math.rad(row.lean or 0))
					* CFrame.Angles(math.rad(row.tilt or 0), 0, 0)
					* CFrame.new(c[1], c[2], c[3])
				spinner(part, "Y", row.sign or 1, row.rate)
				part:SetAttribute("Spinning", true)
			end
			part:SetAttribute("BaseLevel", tonumber(key))
			part:SetAttribute("Later", true)
			stand(part, false)
		end
	end
end

-- The back half's places (AR16; TR37), each in its sleeping place of the plan's layout:
-- * the Forge, AR28's Press at Stage I, from the first: its frame, its ram at rest over its plate ("Rest", "Tell" and
--   "Contact" its underside's heights over its floor, "Strikes" counting the Reinforce tries BaseService strikes on it),
--   and its gears on its head, the right one turned half a tooth so they mesh ("Spin" its way, "PerStud" degrees a stud
--   of the ram's travel). The client strikes it (BaseController). Stages II and III wait (AR36);
-- * the Stone Condenser, AR28's Comb at Stage I, over its sleeping stone ("Asleep"): its frame, its core (a turner) and
--   a stone in each of its comb's cups ("Cup", its filling order), all a later level's and hidden until BaseService shows
--   them once the base wakes it, the cups lit by its tray. The convert's prompt and card are its owner's client's, at the
--   cradle (Config.World.Condenser.Cradle; AR51);
-- * the Lab's sleeping stone, look only.
-- Without the base's kit none of them stands.
local function layBack(base: Instance, number: number, at: CFrame, front: number)
	local _, plan = kitFiles(BASE)
	local machines = plan.machines or {}
	local function homeAt(home: any): CFrame
		return at * Kit.Place(home, { centre = { 0, 0, 0 } }, front, DRESS_LIFT)
	end
	local forgeHome = placementOf("SleepingStone", 1, at)
	local forgePlan, forgeStages = machines.forge, machines.forgeStages
	if forgeHome and forgePlan then
		local forge = model(base, "Forge", homeAt(forgeHome))
		if piece(forge, "Frame", "Forge", forgeHome, number, at, front) then
			local ram = forgePlan.ram
			local struck = piece(forge, "Ram", "ForgeRam", within(forgeHome, { ram.across, ram.along, ram.rest }), number, at, front)
			if struck then
				struck:SetAttribute("Rest", ram.rest)
				struck:SetAttribute("Tell", ram.tell)
				struck:SetAttribute("Contact", ram.contact)
				struck:SetAttribute("Strikes", 0)
			end
			local gears = if forgeStages and forgeStages.stages["1"] then forgeStages.stages["1"].gears else forgePlan.gears
			for index, row in gears do
				local gear = piece(forge, `Gear {index}`, "ForgeGear", within(forgeHome, { row.across, row.along, row.up }), number, at, front)
				if gear then
					if row.turnedHalfTooth then
						gear.CFrame *= CFrame.Angles(0, 0, math.rad(forgePlan.halfTooth))
					end
					gear:SetAttribute("Spin", row.spin or (if row.turnedHalfTooth then -1 else 1))
					gear:SetAttribute("PerStud", forgePlan.degreesPerStud)
				end
			end
			Markers.Stamp(forge, "Forge", { Plot = number })
		else
			forge:Destroy()
		end
	end
	local condenserHome = placementOf("SleepingStone", 2, at)
	local condenserPlan = machines.condenser
	if condenserHome and condenserPlan then
		local origin = homeAt(condenserHome)
		local condenser = model(base, "Condenser", origin)
		machine(condenser, "Asleep", "SleepingStone", 2, number, at, front)
		local function later(part: BasePart?): BasePart?
			if part then
				part:SetAttribute("Later", true)
				stand(part, false)
			end
			return part
		end
		if later(piece(condenser, "Frame", "Condenser", condenserHome, number, at, front)) then
			local core = condenserPlan.core
			spinner(later(piece(condenser, "Core", "CondenserCore", within(condenserHome, { core.across, core.along, core.up }), number, at, front)), "Z", 1, WorldConfig.Condenser.Core)
			local stages = machines.condenserStages
			local cups = if stages and stages.stages["1"] then stages.stages["1"].cups else condenserPlan.cups
			for index, cup in cups do
				local stone = later(piece(condenser, `Cup {index}`, "CondenserStone", within(condenserHome, { cup.across, cup.along, cup.up }), number, at, front))
				if stone then
					stone:SetAttribute("Cup", index)
				end
			end
			condenser:SetAttribute("Cups", #cups)
			Markers.Stamp(condenser, "Condenser", { Plot = number })
		else
			condenser:Destroy()
			machine(base, "Condenser", "SleepingStone", 2, number, at, front) -- no kit's Comb: its stone stays
		end
	end
	local sleeping = model(base, "Sleeping", at)
	machine(sleeping, "Lab", "SleepingStone", 3, number, at, front)
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
		local layout = plan.layout
		-- A place of the layout in the plot's frame, on its floor: across, then studs in from the front edge.
		local function place(spot: BaseFit.Spot, turn: number?): CFrame
			return at * CFrame.new(spot.across, 0, front + spot.inward) * CFrame.Angles(0, math.rad(turn or 0), 0)
		end
		-- The Void Breaker on the slant toward the gate, so a passer-by sees the shards cracking: two chambers, and its
		-- waiting line beside it.
		local breakerAt = place(layout.stations.breaker)
		local breaker = model(base, "Breaker", breakerAt)
		local breakerSwap = if plan.machines then plan.machines.breakerStages else nil
		local breakerHome = placementOf("Breaker", 1, at)
		if breakerSwap and breakerHome then
			-- Its three stages (TR51; AR32, the Great Jaws), each a "Stage n" BaseService shows at the Breaker's own
			-- level: its body, its jaws' hinges and its waiting line, and where BreakerLamp stands ("Lamp"). Its
			-- chambers stand at the same places at every stage, so each is laid once at the Breaker's root from the
			-- first stage that has it ("From"), its shard with it, and its lid where the Breaker hasn't it yet.
			local chambers: { [number]: { Offset: { number }, From: number, Shut: string? } } = {}
			for stage = 1, 3 do
				local rows = breakerSwap.stages[tostring(stage)]
				if rows == nil then
					continue
				end
				local group = stageGroup(breaker, stage, breakerAt)
				if rows.lamp then
					local spot = within(breakerHome, rows.lamp)
					group:SetAttribute("Lamp", at * Kit.Light({ across = spot.across, along = spot.along, up = spot.up } :: any, front, DRESS_LIFT))
				end
				local hinges = 0
				for _, row in rows.pieces do
					if row.moves == "still" then
						stagePiece(group, "Body", row.piece, breakerHome, row.at, stage, false, number, at, front)
					elseif row.moves == "chamber" then
						if chambers[row.chamber] == nil then
							chambers[row.chamber] = { Offset = row.at, From = stage, Shut = row.shut }
						end
					elseif row.moves == "turns" then
						hinges += 1
						spinner(stagePiece(group, `Hinge {hinges}`, row.piece, breakerHome, row.at, stage, false, number, at, front), "Z", row.sign or 1, WorldConfig.Grey.Hinge)
					elseif row.moves == "waiting" then
						stagePiece(group, `Waiting {row.place}`, row.piece, breakerHome, row.at, stage, false, number, at, front)
					end
				end
			end
			for index, chamber in chambers do
				local offset = chamber.Offset
				local later = chamber.From > 1
				local made = piece(breaker, `Chamber {index}`, "BreakerChamber", within(breakerHome, offset), number, at, front)
				if made then
					-- Low until it breaks a shard; its shard stands between the points meanwhile (BaseService).
					made:SetAttribute("Working", false)
					made:SetAttribute("From", chamber.From)
					if later then
						made:SetAttribute("Later", true)
						stand(made, false)
					end
				end
				local shard = block(breaker, `Shard {index}`, SHARD.Size, breakerAt * CFrame.new(offset[1], SHARD.Up, -offset[2]) * CFrame.Angles(0, math.rad(SHARD.Turn), 0), tint("chamber", GREY.Chamber))
				shard.Material = Enum.Material.Neon
				shard.Transparency = 1
				shard.CanCollide, shard.CanQuery, shard.CanTouch, shard.CastShadow = false, false, false, false
				if chamber.Shut then
					local lid = piece(breaker, `Lid {index}`, chamber.Shut, within(breakerHome, offset), number, at, front)
					if lid then
						lid:SetAttribute("From", chamber.From)
						lid:SetAttribute("Later", true)
						stand(lid, false)
					end
				end
			end
		else
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
		end
		Markers.Stamp(breaker, "Breaker", { Plot = number })
		-- Every bay the base can open, on the layout's places: level 1's two at the bus's ends, and the rest asleep where
		-- each will stand until a base level wakes it. Each past level 1's carries its Pad and its Sleeping piece, and
		-- BaseService shows one of the two by its owner's open bays.
		local bayPlaces: { BaseFit.Spot } = { layout.stations.bay1, layout.stations.bay2 }
		for _, later in layout.laterBays do
			table.insert(bayPlaces, later)
		end
		for index, spot in bayPlaces do
			local bayAt = place(spot, spot.turn)
			local bay = model(base, `Bay {index}`, bayAt)
			local asleep = index > 2 -- level 1 opens two (Config.Base.Levels.Bays)
			local bayHome = if asleep then placementOf("BaySleeping", index - 2, at) else placementOf("Bay", index, at)
			local baySwap = if plan.machines then plan.machines.bayStages else nil
			local pad: BasePart? = nil
			if baySwap and bayHome then
				-- Its three stages (TR51; AR33, the Horned Crown), each a "Stage n" BaseService shows at the bay's own
				-- level while it's awake: its body ("Pad") and, from Stage II, its toothed rings, turning while a worker
				-- works there. A sleeping bay's are all a later level's.
				for stage = 1, 3 do
					local rows = baySwap.stages[tostring(stage)]
					if rows == nil then
						continue
					end
					local group = stageGroup(bay, stage, bayAt)
					for _, row in rows.pieces do
						if row.moves == "still" then
							local body = stagePiece(group, "Pad", row.piece, bayHome, row.at, stage, asleep, number, at, front)
							if stage == 1 then
								pad = body
							end
						elseif row.moves == "turns" then
							local name = if row.piece == "BayCogOuter" then "Cog Outer" else "Cog"
							local speed = if row.piece == "BayCogOuter" then WorldConfig.Grey.CogOuter else WorldConfig.Grey.Cog
							spinner(stagePiece(group, name, row.piece, bayHome, row.at, stage, asleep, number, at, front), "X", row.sign or 1, speed)
						end
					end
				end
			else
				pad = if asleep
					then machine(bay, "Pad", "BaySleeping", index - 2, number, at, front, "Bay")
					else machine(bay, "Pad", "Bay", index, number, at, front)
				if pad and asleep then
					pad:SetAttribute("Later", true)
				end
			end
			-- Its light, in the worker's rarity colour while one works there (TR22): out of sight until then, one colour.
			local halo = if asleep
				then machine(bay, "Halo", "BaySleeping", index - 2, number, at, front, "BayHalo")
				else machine(bay, "Halo", "BayHalo", index, number, at, front)
			if halo then
				halo:ClearAllChildren()
				halo.Material = Enum.Material.Neon
				halo.Transparency = 1
				-- A sleeping bay's light stands for a later level: the dressing report counts level 1's.
				if asleep then
					halo:SetAttribute("Later", true)
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
			-- Its light on the deck while it's awake, where the plan has one (AR54: bays 3 and 4, each its own line from
			-- the ring), at the bay's place and turn: a later level's, hidden until BaseService wakes the bay.
			local wakes = if plan.machines and plan.machines.baseLevels then plan.machines.baseLevels.bayWake else nil
			local wakePiece = if wakes and asleep then wakes.pieces[tostring(index)] else nil
			local wake = if wakePiece and bayHome then piece(bay, "Wake", wakePiece, bayHome, number, at, front) else nil
			if wake then
				wake:SetAttribute("Later", true)
				stand(wake, false)
			end
			Markers.Stamp(bay, "Bay", { Plot = number, Bay = index })
		end
		-- The battery on the slant toward the back: its rack, and its bank of cells on the plan's seats, in the order they
		-- fill (AR15, section 4). BaseService shows as many as the base's level holds and lights each by the charge.
		local batteryAt = place(layout.stations.battery)
		local battery = model(base, "Battery", batteryAt)
		local batterySwap = if plan.machines then plan.machines.batteryStages else nil
		local batteryHome = placementOf("BatteryRack", 1, at)
		if batterySwap and batteryHome then
			-- Its three stages (TR51; AR34, the Rising Stack), each a "Stage n" with its "Rack", shown at the base's
			-- level. Its cells sit on the same seats at every stage that has them, so each is laid once at the root, on
			-- the last stage's seats in the order they fill (they supersede machines.battery's), and BaseService shows
			-- the level's.
			local seats = {}
			for stage = 1, 3 do
				local rows = batterySwap.stages[tostring(stage)]
				if rows == nil then
					continue
				end
				local group = stageGroup(battery, stage, batteryAt)
				group:SetAttribute("Seats", if rows.seats then #rows.seats else 0) -- the cells its rack holds
				for _, row in rows.pieces do
					stagePiece(group, "Rack", row.piece, batteryHome, row.at, stage, false, number, at, front)
				end
				seats = rows.seats or seats
			end
			local first = plan.machines.battery.cellsAt["1"]
			for seat, offset in seats do
				local cell = piece(battery, `Cell {seat}`, "BatteryCell", within(batteryHome, offset), number, at, front)
				if cell then
					cell:SetAttribute("Cell", seat)
					cell:SetAttribute("Lit", 0)
					cell:SetAttribute("Later", seat > first)
					stand(cell, false)
				end
			end
		elseif machine(battery, "Rack", "BatteryRack", 1, number, at, front) then
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
		-- The generator at the plot's heart, at the end of the way in (TR18; AR19, the Void Mill), once a stage from the
		-- swap's table (the plan's machines.generatorStages), each stage its own model "Stage n": what stands still and
		-- its unseen solids; its wheel, which the client turns by its owner's generation; a stage's pinions, which the
		-- client drives from the wheel's angle; the gauge's eight steps up the rising side, which BaseService shows as
		-- the generation lights them; and the demand's mark, which the client turns about the axle to the demand's share
		-- at its stage's degrees (Rules.Power.Gauge). Stage I stands; BaseService stands its owner's stage and hides the
		-- others. A box while its kit isn't laid.
		local generator = WorldConfig.Grey.Generator
		local generatorAt = place(layout.stations.generator)
		local plant = model(base, "Generator", generatorAt)
		local _, kitPlan = kitFiles(BASE)
		local swap = if baseLook and kitPlan.machines then kitPlan.machines.generatorStages else nil
		local laid = false
		for stage = 1, 3 do
			local rows = if swap then swap.stages[tostring(stage)] else nil
			if rows == nil then
				continue
			end
			local group = model(plant, `Stage {stage}`, generatorAt)
			group:SetAttribute("Stage", stage)
			local pinions = 0
			for _, row in rows do
				local name = if row.moves == "still"
					then "Body"
					elseif row.moves == "gauge" then `Step {row.step}`
					elseif row.moves == "demand" then "Demand"
					elseif row.rate == 1 then "Wheel"
					else `Pinion {pinions + 1}`
				local part = piece(group, name, row.piece, { across = row.across, along = row.along, up = row.up, turn = 0 }, number, at, front)
				if part == nil then
					continue
				end
				laid = true
				part:SetAttribute("Stage", stage)
				part:SetAttribute("Moves", row.moves)
				if row.moves == "still" then
					millSolid(group, part, stage)
				elseif row.moves == "turns" then
					part:SetAttribute("Rate", row.rate) -- 1 for the wheel; a pinion's, against the wheel's angle
					if row.rate == 1 then
						part:SetAttribute("Generation", 0) -- its owner's kW (BaseService), by which the client turns it
					else
						pinions += 1
					end
				elseif row.moves == "gauge" then
					part:SetAttribute("Step", row.step)
					part.Transparency = 1 -- hidden until the generation lights it: shown or hidden, never dimmed
				elseif row.moves == "demand" then
					part:SetAttribute("Share", 0) -- the demand's share of the gauge (BaseService), to which the client turns it
					part:SetAttribute("Turn", row.degrees) -- its stage's degrees at a share of 1
				end
			end
			if stage > 1 then
				for _, part in group:GetChildren() do
					if part:IsA("BasePart") and part:GetAttribute("Step") == nil then
						if part:GetAttribute("Unseen") == true then
							part.CanCollide, part.CanQuery = false, false
						else
							stand(part, false)
						end
					end
				end
			end
		end
		if not laid then
			block(plant, "Body", generator.Size, generatorAt * CFrame.new(0, generator.Size.Y / 2, 0), tint("generator", GREY.Generator))
		end
		Markers.Stamp(plant, "Generator", { Plot = number })
		-- The Festival Door on the other slant toward the gate, turned to face down the way in: the ring tunnel (AR15,
		-- section 7). Its frame (the step, the front ring and the name's plate), the four rings behind it, which the
		-- client turns always, each at its plan's `spin` ("spins"), its core, whose glow is the Door's state (DoorService:
		-- "Working", full while a ground is open to go to, low while none is), the unseen Way a player walks into, inside
		-- the front ring's opening, and the unseen Name the client writes the Door's name on, on the plate's face. The
		-- grey frame while its kit isn't laid.
		local doorAt = place(layout.stations.door, turnOf("Door"))
		local festival = model(base, "Festival Door", doorAt)
		local frame = machine(festival, "Frame", "Door", 1, number, at, front)
		if frame then
			local d = WorldConfig.Grey.Door
			local _, doorPlan = kitFiles(BASE)
			for _, placement in (if doorPlan.machines then doorPlan.machines.placements else {}) do
				local ring = if type(placement.spin) == "number" then string.match(placement.piece, "^DoorRing(%d+)$") else nil
				local part = if ring then machine(festival, `Ring {ring}`, placement.piece, 1, number, at, front) else nil
				if part then
					part:SetAttribute("Moves", "spins")
					part:SetAttribute("Spin", placement.spin) -- degrees a second, anticlockwise seen from the mouth
				end
			end
			local core = machine(festival, "Core", "DoorWay", 1, number, at, front)
			if core then
				core.CastShadow = false
				core:SetAttribute("Working", false) -- DoorService opens it once the ground it goes to is laid
			end
			-- The Door's own frame: its origin, the step's middle on the floor, its mouth looking along +Z.
			local c = manifest.pieces.Door.centre
			local origin = frame.CFrame * CFrame.new(-c[1], -c[2], -c[3])
			local trigger = block(festival, "Way", d.Way.Size, origin * CFrame.new(d.Way.At), GREY.Pad)
			trigger.Transparency, trigger.CanCollide, trigger.CanQuery, trigger.CastShadow = 1, false, false, false
			local name = block(festival, "Name", Vector3.new(d.Name.Size.X, d.Name.Size.Y, 0.05), origin * CFrame.new(d.Name.At), GREY.Pad)
			name.Transparency, name.CanCollide, name.CanQuery, name.CanTouch, name.CastShadow = 1, false, false, false, false
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
		local trainingSwap = if plan.machines then plan.machines.trainingStages else nil
		local trainingHome = placementOf("Training", 1, at)
		if trainingSwap and trainingHome then
			-- Its three stages (TR51; AR35, the Weighted Crown), each a "Stage n" with its "Crown", shown at the base's
			-- level; the stone is the same at every stage, laid once above.
			for stage = 1, 3 do
				local rows = trainingSwap.stages[tostring(stage)]
				if rows == nil then
					continue
				end
				local group = stageGroup(trainer, stage, machineAt)
				for _, row in rows.pieces do
					if row.moves == "turns" then
						local crown = stagePiece(group, "Crown", row.piece, trainingHome, row.at, stage, false, number, at, front)
						if crown then
							crown:SetAttribute("Training", false)
						end
					end
				end
			end
		else
			local crown = machine(trainer, "Crown", "TrainingCrown", 1, number, at, front)
			if crown then
				crown:SetAttribute("Training", false)
			end
		end
		Markers.Stamp(trainer, "Training", { Plot = number })
		-- The back half's places (AR16), in the plan's order: the Forge's, the Condenser's and the Lab's.
		layBack(base, number, at, front)
		layLevels(base, number, at, front)
		-- The Tower's gate on its lot's crossing end, where the ring stood (AR56, replacing TR29's ring): its door of light
		-- starts a run, its slab shows the owner's record. It stands with its plot's base: a bare lot has none.
		local ringX, ringZ = Tower.RingSpot(across, deep, behind, tower, crossingSide(at))
		local ringAt = at * CFrame.new(ringX, 0, ringZ)
		local ring = model(base, "TowerRing", ringAt)
		local middle = block(ring, "Middle", Vector3.new(1, 0.1, 1), ringAt, GREY.Ring) -- the marker's own part, unseen
		middle.Transparency = 1
		middle.CanCollide, middle.CanQuery, middle.CanTouch = false, false, false
		ring.PrimaryPart = middle
		layGate(ring, Tower.Lot(ringAt), number)
		Markers.Stamp(ring, "TowerRing", { Plot = number })
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
		if look then
			dressPlot(base, number, at, front)
		end
		base.Parent = m
		return base
	end
end

-- Each plot's base builder, as the last lay left it (plot()).
local bases: { [number]: () -> Model } = {}

local layStreet: (folder: Folder, gateZ: number, stripEnd: number, groundColour: Color3) -> ()

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
	-- The festival gate, where the side street beside the base once ended: Lantern Row keeps that spot in its own place,
	-- and the Strip's kit and the lights still measure from it.
	local gateZ = -towers
	folder:SetAttribute("GateZ", gateZ)

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
	elseif not FESTIVAL then
		Log.Info("WorldService", `the plots stay grey: {table.concat(baseHeld, "; ")}`)
	end
	local groundColour = if baseLook then baseLook.ground else GREY.Ground
	if FESTIVAL then
		layStreet(folder, gateZ, stripEnd, groundColour)
		return
	end
	-- The base's ground, out past the Towers' far edges by as far as a platform reaches over them (Rules.Tower.Reach,
	-- AR41's 48 across), so an avatar that leaves its run off the far side comes down on ground. The Festival of
	-- Battles is its own place (TR45): the base's Festival Door opens its menu, and the crossing north of the Strip is ground.
	local ground = math.max(towers, stripHalf + deep + behind + tower / 2 + GROUND_PAST)
	slab(folder, "Ground", -stripEnd, stripEnd, ground, -ground, GROUND_TOP, groundColour)
	-- The Strip, wearing Lantern Row's paving with the base laid, as its street does: off the stones onto the plates is
	-- coming home (AR14). With the Strip's own kit, its own tile (Lantern Row's lifted) and its dressing (AR17).
	local strip = slab(folder, "Strip", -stripEnd, stripEnd, -stripHalf, stripHalf, PAVED_TOP, GREY.Paved)
	local stripHeld = stripProblems()
	local stones = if #stripHeld == 0 then kitTemplate(STRIP) else kitTemplate(DRESS)
	local stone = if baseLook and stones then stones:FindFirstChild("Paving") else nil
	if stone then
		stone:Clone().Parent = strip
	end
	if #stripHeld == 0 then
		dressStrip(folder, gateZ)
	else
		Log.Info("WorldService", `the Strip stays bare: {table.concat(stripHeld, "; ")}`)
	end

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

	-- The Shop, south of the crossing: every trip out and back passes its clock. With the Strip's kit, its own building
	-- (dressShop), its marker before the counter; without it, a grey block and a clock.
	local shopAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, stripHalf + 4), Vector3.new(0, PAVED_TOP, 0))
	local shop: Model
	if #stripHeld == 0 then
		shop = model(folder, "Shop", shopAt * CFrame.new(0, 0, SHOP_COUNTER))
		dressShop(shop, shopAt + Vector3.new(0, DRESS_LIFT, 0))
	else
		shop = model(folder, "Shop", shopAt)
		block(shop, "Building", Vector3.new(40, 14, 28), shopAt * CFrame.new(0, 7, 16), GREY.Machine)
		local clock = block(shop, "Clock", Vector3.new(1, 8, 8), shopAt * CFrame.new(0, 10, 1.5) * CFrame.Angles(0, math.pi / 2, 0), GREY.Pad)
		clock.Shape = Enum.PartType.Cylinder
	end
	Markers.Stamp(shop, "Shop")
	-- Its floor is the Strip's own paving, run on from the street with its joints in line (both on the tile's 8 studs):
	-- a grey lot under it read as a building site (research's must-fix 2 on AR40's C, 2026-11-19, 21:25).
	local shopFloor = slab(folder, "Shop's floor", -crossingHalf, crossingHalf, stripHalf, stripHalf + deep, PAVED_TOP, if stone then GREY.Paved else GREY.Plot)
	if stone then
		stone:Clone().Parent = shopFloor
	end
end

-- The Festival's place (TR45): Lantern Row from its forecourt, where a trip sets the player down before the gate, to
-- past the shut gate, on its own ground as wide as the base's, at the same spots it had beside the base, so every stop
-- keeps its numbers.
function layStreet(folder: Folder, gateZ: number, stripEnd: number, groundColour: Color3)
	local c = WorldConfig
	local function studs(seconds: number): number
		return seconds * c.Walk
	end
	local row = c.Row
	local rowHalf = studs(row.Wide) / 2
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
	local doors = c.Grey.Door
	-- The grey look the kit replaces: the street's stall fronts, the square, the two gates. Kept as unseen
	-- colliders when the kit is laid; the ring and beyond stay grey (their dressing waits).
	local looks: { Instance } = {}
	local function under(item: Instance?)
		if item then
			table.insert(looks, item)
		end
	end
	slab(folder, "Ground", -stripEnd, stripEnd, gateZ + FORECOURT * 2, shutZ - 24, GROUND_TOP, groundColour)
	local forecourt = slab(folder, "Forecourt", -rowHalf, rowHalf, gateZ, gateZ + FORECOURT, PAVED_TOP, GREY.Paved)
	-- The street's own floor carries the walking; dressed, it wears the kit's paving under the bays (AR5's manifest).
	local streetFloor = slab(folder, "Lantern Row", -rowHalf, rowHalf, keeperZ, gateZ, PAVED_TOP, GREY.Paved)

	-- The festival gate, open.
	local north = Vector3.new(0, 0, -1)
	local gateAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, gateZ), Vector3.new(0, PAVED_TOP, gateZ) + north)
	local festivalGate = gate(folder, "Festival gate", gateAt, studs(row.Wide), high, false)
	under(festivalGate)
	Markers.Stamp(festivalGate, "FestivalGate")
	-- Its twin, inside the gate against the east stall front, takes the player home; a trip here lands them before the
	-- gate in the street's middle, looking through it.
	local homeDoorAt = CFrame.lookAt(Vector3.new(rowHalf - 4, PAVED_TOP, gateZ - doors.AtGate), Vector3.new(0, PAVED_TOP, gateZ - doors.AtGate))
	Markers.Stamp(door(folder, "Home door", homeDoorAt, WorldConfig.Grey.Door.HomeWay), "GroundDoor", { Ground = row.Ground })
	-- Where the trail home goes (TR16), and the street it keeps to (its middle's X, its half width), on the folder that
	-- never streams out, as the door's own model may.
	folder:SetAttribute("HomeDoor", homeDoorAt.Position)
	folder:SetAttribute("Street", Vector2.new(0, rowHalf))
	local landingAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, gateZ + doors.Landing), Vector3.new(0, PAVED_TOP, gateZ + doors.Landing) + north)
	Markers.Stamp(spot(folder, "Door landing", landingAt), "DoorLanding", { Ground = row.Ground })
	-- Roblox's own spawn sets a player down there too, before setDown turns them to face the gate.
	local arrival = Instance.new("SpawnLocation")
	arrival.Name = "Arrival"
	arrival.Anchored = true
	arrival.Size = Vector3.new(6, 0.2, 6)
	arrival.CFrame = landingAt * CFrame.new(0, 0.1, 0)
	arrival.Transparency = 1
	arrival.CanCollide = false
	arrival.CanQuery = false
	arrival.CanTouch = false
	arrival.Duration = 0
	arrival.Neutral = true
	arrival.Parent = folder
	-- The first stage starts where the Door sets a player down (TR43).
	Markers.Stamp(spot(folder, `Stage {row.Stops[1].Stage}'s start`, landingAt), "StageStart", { Stage = row.Stops[1].Stage, Ground = row.Ground })

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
			local with, rear = stop.With, stop.Rear
			Markers.Stamp(spot(street, `Pack {pack}`, at), "Pack", {
				Pack = pack,
				Def = stop.Def,
				Level = stop.Level,
				Count = stop.Count or 1,
				With = if with then with.Def else nil,
				WithCount = if with then with.Count else nil,
				Rear = if rear then rear.Def else nil,
				RearCount = if rear then rear.Count else nil,
				Ground = row.Ground,
				Stage = stop.Stage,
			})
		elseif stop.Kind == "Elite" then
			if stop.Square then
				under(slab(street, "Square", -squareHalf, squareHalf, z - squareHalf, z + squareHalf, PAVED_TOP + OVERLAY, GREY.Plot))
				table.insert(openings, { z - squareHalf, z + squareHalf })
				for _, side in { -1, 1 } do
					under(wallZ(street, side * (squareHalf + 1), z - squareHalf, z + squareHalf, high))
					under(wallX(street, z - squareHalf - 1, side * (rowHalf + 1), side * (squareHalf + 2), high))
					under(wallX(street, z + squareHalf + 1, side * (rowHalf + 1), side * (squareHalf + 2), high))
				end
			end
			Markers.Stamp(spot(street, `Elite {stop.Stage}`, at), "Elite", { Def = stop.Def, Hard = stop.Hard, Level = stop.Level, Ground = row.Ground, Stage = stop.Stage })
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
			-- The keeper's stage starts before its gate, facing it.
			local startAt = Vector3.new(0, PAVED_TOP, z + row.GateSet)
			Markers.Stamp(spot(street, `Stage {stop.Stage}'s start`, CFrame.lookAt(startAt, startAt + north)), "StageStart", { Stage = stop.Stage, Ground = row.Ground })
		end
		-- A stage's gate (TR43), halfway from its last stop to the next stage's first, outside the square (Spacing's 80
		-- studs over the square's 32 to its edge); the next stage starts past it, the keeper's before its own gate.
		local after = stops[index + 1]
		if after and after.Stage ~= stop.Stage then
			local stageGateZ = (z + stopZ(index + 1)) / 2
			local shut = block(street, `Stage {stop.Stage}'s gate`, Vector3.new(studs(row.Wide), high, 1), CFrame.new(0, PAVED_TOP + high / 2, stageGateZ), GREY.Locked)
			shut.Transparency = 0.5
			shut.CanCollide = false -- per player: the server sets back whoever crosses it shut (StageService)
			shut.CanQuery = false
			shut.CanTouch = false
			Markers.Stamp(shut, "StageGate", { Stage = stop.Stage, Ground = row.Ground })
			if after.Kind ~= "Keeper" then
				local startAt = Vector3.new(0, PAVED_TOP, stageGateZ - row.GateSet)
				Markers.Stamp(spot(street, `Stage {after.Stage}'s start`, CFrame.lookAt(startAt, startAt + north)), "StageStart", { Stage = after.Stage, Ground = row.Ground })
			end
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
		paving:Clone().Parent = forecourt
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

-- A plot's dressing (its kit's pieces, the gate's plate, the plinth), or nil while no base stands there.
function WorldService.DressingOf(number: number): Instance?
	local lot = lotOf(number)
	local base = if lot then lot:FindFirstChild("Base") else nil
	return if base then base:FindFirstChild("Dressing") else nil
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

-- In the Festival's place, each player's number among those here, 1 to Config.World.Plots.Count as a plot's is in the
-- base's: what's kept per player is found by it (the keeper's ring copies, TR45). In the base's place, the plot's.
local slots: { [number]: Player } = {}

function WorldService.SlotOf(player: Player): number?
	if not FESTIVAL then
		return WorldService.PlotOf(player)
	end
	for number, who in slots do
		if who == player then
			return number
		end
	end
	return nil
end

local function slot(player: Player)
	for number = 1, WorldConfig.Plots.Count do
		if slots[number] == nil then
			slots[number] = player
			return
		end
	end
	Log.Warn("WorldService", `no free number for {player.Name} here: Max Players should be {WorldConfig.Plots.Count}`)
end

-- In the Festival's place, where everyone arrives: the Door's landing before the gate (TR45).
function WorldService.LandingOf(): CFrame?
	local landing = Markers.Find("DoorLanding")
	return if landing then Markers.At(landing) else nil
end

-- Roblox's own respawn lands on the plot's spawn too; in the Festival's place, on the landing's.
local function respawnOn(player: Player)
	if FESTIVAL then
		local world = workspace:FindFirstChild(WORLD)
		local arrival = if world then world:FindFirstChild("Arrival") else nil
		if arrival and arrival:IsA("SpawnLocation") then
			player.RespawnLocation = arrival
		end
		return
	end
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
	for number, who in slots do
		if who == player then
			slots[number] = nil
		end
	end
end

-- A new avatar on its plot's spawn, facing the Breaker, then the client opens from black with the camera behind it. The
-- event reaches the client after the pivot does, so the camera turns behind the final facing, never the spawn's first.
local function setDown(player: Player, character: Model)
	local at = if FESTIVAL then WorldService.LandingOf() else WorldService.SpawnOf(player)
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
		return Markers.Report(WorldConfig.Plots.Count, owned(), PlaceRole.Current)
	end)
	-- Part 7's tests on the base plan's layout at Stage III's footprints (Config.World.Fit; Rules.BaseFit): its line.
	DebugService.Register("BaseSize", function(): { string }
		local walk = WorldConfig.Walk
		local fit = WorldConfig.Fit
		local _, plan = kitFiles(BASE)
		local plots = WorldConfig.Plots
		return {
			BaseFit.Line(BaseFit.Measure(plan.layout, plots.Across * walk, fit :: any, { Walk = walk, Between = plots.Between * walk, Kept = plots.Kept * walk }), fit :: any),
		}
	end)
	-- The dressing against its plan: every piece laid as often as the plan has it, each with its look, the plan's lights,
	-- and the grey look under it hidden; then each plot against its base level's plan (AR14), its lights and its level's
	-- number; a plot no one owns, its bare lot. Empty when it's whole; one line when the street or the plots are grey, and
	-- why. ("DressReport", nil, "Street") leaves out the plots while their size isn't the plan's, for the street's case.
	DebugService.Register("DressReport", function(_who: any, only: any): { string }
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
		local stripGot: { [string]: number } = {}
		local stripLights = 0
		local shopGot: { [string]: number } = {}
		for _, item in CollectionService:GetTagged(Kit.Tag) do
			if not item:IsDescendantOf(world) or item:GetAttribute("Plot") ~= nil then
				continue
			end
			local piece = item:GetAttribute("Piece")
			if item:GetAttribute("Shop") then
				local name = if type(piece) == "string" then piece elseif item:FindFirstChildWhichIsA("Light") then "light" else "other"
				shopGot[name] = (shopGot[name] or 0) + 1
				continue
			end
			if item:GetAttribute("Kit") == STRIP then
				if type(piece) == "string" then
					stripGot[piece] = (stripGot[piece] or 0) + 1
					if item:FindFirstChildOfClass("SurfaceAppearance") == nil then
						table.insert(problems, `{item:GetFullName()}: no look`)
					end
				elseif item:FindFirstChildWhichIsA("Light") then
					stripLights += 1
				end
			elseif type(piece) == "string" then
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
			local trial = plots ~= nil and (WorldConfig.Plots.Across ~= WorldConfig.Plots.Drawn or WorldConfig.Plots.Deep ~= WorldConfig.Plots.Drawn)
			if not (only == "Street" and trial) then
				table.insert(problems, `plots grey: {table.concat(held, "; ")}`)
			end
		else
			local _, basePlan = kitFiles(BASE)
			local level = basePlan.levels[BASE_LEVEL]
			local each: { [string]: number } = {}
			for _, placement in level.placements do
				each[placement.piece] = (each[placement.piece] or 0) + 1
			end
			local standing: { [string]: number } = {}
			for _, placement in (if basePlan.machines then basePlan.machines.placements else {}) do
				-- The Tower's ring stands where the sleeping Tower was placed (TR29): it's checked below, not its piece.
				if placement.piece ~= "TowerSleeping" then
					standing[placement.piece] = (standing[placement.piece] or 0) + 1
				end
			end
			-- The Forge stands in the first sleeping place, its stone's (TR37): its frame, its ram and Stage I's gears.
			local forgePlan = if basePlan.machines then basePlan.machines.forge else nil
			local stones = standing.SleepingStone
			if forgePlan and stones then
				standing.SleepingStone = stones - 1
				standing.Forge, standing.ForgeRam, standing.ForgeGear = 1, 1, #forgePlan.gears
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
				for _, item in dressing:GetChildren() do
					if item:GetAttribute("Piece") == "Showcase" and typeof(item:GetAttribute("Stand")) ~= "CFrame" then
						table.insert(problems, `Plot {number}: the plinth has no stand for its Voidkin (TR22)`)
					end
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
				-- The Forge's ram knows its heights, and the Condenser has its comb's cups, its core and its panel (TR37).
				local forge = (m :: Instance):FindFirstChild("Forge")
				local ram = if forge then forge:FindFirstChild("Ram") else nil
				if ram == nil or type(ram:GetAttribute("Rest")) ~= "number" or type(ram:GetAttribute("Contact")) ~= "number" then
					table.insert(problems, `Plot {number}: the Forge has no ram with its heights`)
				end
				local condenser = (m :: Instance):FindFirstChild("Condenser")
				if condenser == nil or condenser:FindFirstChild("Frame") == nil then
					table.insert(problems, `Plot {number}: no Stone Condenser`)
				else
					local cups = 0
					for _, part in condenser:GetChildren() do
						cups += if type(part:GetAttribute("Cup")) == "number" then 1 else 0
					end
					if cups == 0 or cups ~= condenser:GetAttribute("Cups") then
						table.insert(problems, `Plot {number}: the Condenser has {cups} cups, its comb {condenser:GetAttribute("Cups")}`)
					end
					for _, name in { "Core", "Asleep" } do
						if condenser:FindFirstChild(name) == nil then
							table.insert(problems, `Plot {number}: the Condenser has no {name}`)
						end
					end
				end
				-- A piece placed toward the crossing stands on the plot's crossing side (AR16's Tower), and the Tower's ring
				-- with it (TR29).
				local pivot = (m :: Model).WorldPivot
				local side = crossingSide(pivot)
				local ring = (m :: Instance):FindFirstChild("TowerRing", true)
				local middle = if ring and ring:IsA("Model") then ring.PrimaryPart else nil
				if middle == nil then
					table.insert(problems, `Plot {number}: no Tower ring`)
				elseif pivot:PointToObjectSpace(middle.Position).X * side <= 0 then
					table.insert(problems, `Plot {number}: the Tower ring stands away from the crossing`)
				end
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
		-- The Strip's kit (AR17) against its plan, and its own tile on the Strip and the side street.
		local stripHeld = stripProblems()
		if #stripHeld > 0 then
			table.insert(problems, `the Strip bare: {table.concat(stripHeld, "; ")}`)
		else
			local _, stripPlan = kitFiles(STRIP)
			local stripWant: { [string]: number } = {}
			for _, placement in stripPlan.placements do
				stripWant[placement.piece] = (stripWant[placement.piece] or 0) + 1
			end
			for piece, count in stripWant do
				if stripGot[piece] ~= count then
					table.insert(problems, `the Strip's {piece}: {stripGot[piece] or 0} laid, the plan has {count}`)
				end
			end
			if stripLights ~= #stripPlan.lights then
				table.insert(problems, `the Strip's lights: {stripLights}, the plan has {#stripPlan.lights}`)
			end
			-- The Shop's building (dressShop): the building, its crown, its five minutes and its two lights.
			local shopWant: { [string]: number } = { VoidShop = 1, VoidShopCrown = 1, VoidShopMinute = #SHOP_MINUTES, light = 2 }
			for name, count in shopWant do
				if shopGot[name] ~= count then
					table.insert(problems, `the Shop's {name}: {shopGot[name] or 0}, its building has {count}`)
				end
			end
			local tile = (kitTemplate(STRIP) :: Instance):FindFirstChild("Paving") :: Texture?
			for _, name in { "Strip", "Side street" } do
				local street = world:FindFirstChild(name)
				local paving = if street then street:FindFirstChild("Paving") :: Texture? else nil
				if baseLook and tile and (paving == nil or paving.Texture ~= tile.Texture) then
					table.insert(problems, `the {name} wears another tile than the Strip's`)
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
	for _, problem in Markers.Report(WorldConfig.Plots.Count, owned(), PlaceRole.Current) do
		Log.Warn("WorldService", problem)
	end
	local function join(player: Player)
		if FESTIVAL then
			slot(player) -- no plot here: the save keeps the base, and the base keeps working from it (TR45)
			respawnOn(player)
		else
			arrive(player)
		end
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
