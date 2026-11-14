--!strict
-- WorldService (server): the world the circuit is played in (docs/design.md, "The world, in grey").
-- * With no authored world in the place (no workspace.World), it lays research's layout in grey from Config.World,
--   stamping the contract's markers (Shared.World.Tags) as it goes. A World number tuned in a playtest lays it again, and
--   Laid tells whatever stands on a marker to find it again.
-- * It gives each player a plot at join, the lowest free one, as the player attribute "Plot" (docs/engineering-plan.md,
--   "Who owns what": the server, at join), and sets them down on its spawn, facing the Breaker.
-- Studio's WorldReport checks the place's markers against the contract.
-- North is -Z. The crossing's centre is the origin; the Strip runs east-west; Lantern Row runs north from the gate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local WorldConfig = require(Shared.Config.World)
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

local WORLD = "World"
local GROUND_TOP = 0.5 -- the ground's top, over a template Baseplate's (0), so the two never fight for a pixel
local PAVED_TOP = 0.6 -- the Strip, the streets and the plots stand a tenth higher, for the same reason
local OVERLAY = 0.1 -- a mark on a paved floor: the kept back of a plot, a Tower's footprint
local SPAWN_UP = 3 -- an R6 root stands 3 studs over its floor
local READ_LIVE = { ["World.Row.Respawn"] = true, ["World.Arrive"] = true } -- World numbers read when used, not laid

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
-- look. Walking into the way takes the player through (DoorService).
local function door(parent: Instance, name: string, at: CFrame): Model
	local d = WorldConfig.Grey.Door
	local m = model(parent, name, at)
	for _, side in { -1, 1 } do
		block(m, "Post", Vector3.new(1.5, d.High, 1.5), at * CFrame.new(side * (d.Wide / 2 + 0.75), d.High / 2, 0), GREY.Gate)
	end
	block(m, "Lintel", Vector3.new(d.Wide + 3, 1.5, 1.5), at * CFrame.new(0, d.High + 0.75, 0), GREY.Gate)
	local way = block(m, "Way", Vector3.new(d.Wide, d.High, 0.4), at * CFrame.new(0, d.High / 2, 0), GREY.Pad)
	way.Material = Enum.Material.Neon
	way.Transparency = 0.35
	way.CanCollide = false
	return m
end

-- A wall along z from z0 to z1 at x, `high` tall.
local function wallZ(parent: Instance, x: number, z0: number, z1: number, high: number)
	if math.abs(z1 - z0) < 0.5 then
		return
	end
	block(parent, "Wall", Vector3.new(2, high, math.abs(z1 - z0)), CFrame.new(x, PAVED_TOP + high / 2, (z0 + z1) / 2), GREY.Wall)
end

-- A wall along x from x0 to x1 at z.
local function wallX(parent: Instance, z: number, x0: number, x1: number, high: number)
	if math.abs(x1 - x0) < 0.5 then
		return
	end
	block(parent, "Wall", Vector3.new(math.abs(x1 - x0), high, 2), CFrame.new((x0 + x1) / 2, PAVED_TOP + high / 2, z), GREY.Wall)
end

-- One plot, `at` its centre on its floor, looking out of its front onto the Strip.
local function plot(parent: Instance, number: number, at: CFrame, across: number, deep: number, kept: number, behind: number, tower: number, bays: number)
	local m = model(parent, `Plot {number}`, at)
	local floor = block(m, "Floor", Vector3.new(across, 1, deep), at * CFrame.new(0, -0.5, 0), GREY.Plot)
	Markers.Stamp(floor, "Plot", { Plot = number })
	block(m, "Kept", Vector3.new(across, OVERLAY, kept), at * CFrame.new(0, OVERLAY / 2, deep / 2 - kept / 2), GREY.Kept)
	block(m, "Tower", Vector3.new(across, OVERLAY, tower), at * CFrame.new(0, OVERLAY / 2 - 0.05, deep / 2 + behind + tower / 2), GREY.Tower)
	local front = -deep / 2 -- local z of its front edge
	-- The Breaker at the front, so a passer-by sees the shards cracking: two chambers, and its waiting line beside it.
	local breakerAt = at * CFrame.new(0, 0, front + 12)
	local breaker = model(m, "Breaker", breakerAt)
	block(breaker, "Body", Vector3.new(14, 5, 6), breakerAt * CFrame.new(0, 2.5, 0), GREY.Machine)
	for index, x in { -3.5, 3.5 } do
		block(breaker, `Chamber {index}`, Vector3.new(4, 4, 4), breakerAt * CFrame.new(x, 7, 0), GREY.Chamber)
	end
	for index = 1, 3 do
		block(breaker, `Waiting {index}`, Vector3.new(2.5, 1, 2.5), breakerAt * CFrame.new(9 + (index - 1) * 3, 0.5, 0), GREY.Chamber)
	end
	Markers.Stamp(breaker, "Breaker", { Plot = number })
	-- The bays line its sides, in the order they open; the battery sits between them.
	for index = 1, bays do
		local side = if index % 2 == 1 then -1 else 1
		local row = (index - 1) // 2
		local bayAt = at * CFrame.new(side * 22, 0, front + 26 + row * 14)
		local bay = model(m, `Bay {index}`, bayAt)
		block(bay, "Pad", Vector3.new(10, 0.4, 10), bayAt * CFrame.new(0, 0.2, 0), GREY.Bay)
		if index > 1 then
			block(bay, "Locked", Vector3.new(10, 3, 0.6), bayAt * CFrame.new(0, 1.5, -5), GREY.Locked)
		end
		Markers.Stamp(bay, "Bay", { Plot = number, Bay = index })
	end
	local batteryAt = at * CFrame.new(0, 0, front + 26)
	local battery = model(m, "Battery", batteryAt)
	-- Low, so the owner sees the Breaker over it from the spawn.
	block(battery, "Cell", Vector3.new(6, 3, 4), batteryAt * CFrame.new(0, 1.5, 0), GREY.Battery)
	Markers.Stamp(battery, "Battery", { Plot = number })
	-- The Festival Door, right of the Breaker and level with it, in view from the spawn.
	Markers.Stamp(door(m, "Festival Door", at * CFrame.new(WorldConfig.Grey.Door.DoorAt, 0, front + 12)), "FestivalDoor", { Plot = number })
	-- The Training machine (TR12), left of the Breaker as the door is right of it: a box, and its pad on the spawn's side,
	-- where a fallen lead comes home and trains (FightService).
	local training = WorldConfig.Grey.Training
	local machineAt = at * CFrame.new(-WorldConfig.Grey.Door.DoorAt, 0, front + 12)
	local machine = model(m, "Training machine", machineAt)
	block(machine, "Body", training.Size, machineAt * CFrame.new(0, training.Size.Y / 2, 0), GREY.Machine)
	block(machine, "Pad", Vector3.new(4, 0.4, 4), machineAt * CFrame.new(0, 0.2, training.Spot), GREY.Bay)
	Markers.Stamp(machine, "Training", { Plot = number })
	-- The owner arrives behind it all, facing the Breaker.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.CFrame = at * CFrame.new(0, 0.1, front + 40)
	spawn.Color = GREY.Pad
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0 -- no shield
	spawn.Neutral = true
	spawn.Parent = m
	Markers.Stamp(spawn, "Spawn", { Plot = number })
end

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

	-- The ground, under all of it.
	slab(folder, "Ground", -stripEnd, stripEnd, towers, shutZ - 24, GROUND_TOP, GREY.Ground)
	-- The Strip, the side street to the gate, and Lantern Row to the keeper's gate.
	slab(folder, "Strip", -stripEnd, stripEnd, -stripHalf, stripHalf, PAVED_TOP, GREY.Paved)
	slab(folder, "Side street", -rowHalf, rowHalf, gateZ, -stripHalf, PAVED_TOP, GREY.Paved)
	slab(folder, "Lantern Row", -rowHalf, rowHalf, keeperZ, gateZ, PAVED_TOP, GREY.Paved)

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
		plot(plotFolder, number, at, across, deep, studs(plots.Kept), behind, tower, plots.Bays)
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
	Markers.Stamp(gate(folder, "Festival gate", gateAt, studs(row.Wide), high, false), "FestivalGate")
	-- Its twin, inside the gate against the east stall front, takes the player home; the plots' doors land them before
	-- the gate in the street's middle, looking through it.
	local doors = c.Grey.Door
	local homeDoorAt = CFrame.lookAt(Vector3.new(rowHalf - 4, PAVED_TOP, gateZ - doors.AtGate), Vector3.new(0, PAVED_TOP, gateZ - doors.AtGate))
	Markers.Stamp(door(folder, "Home door", homeDoorAt), "GroundDoor", { Ground = row.Ground })
	local landingAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, gateZ + doors.Landing), Vector3.new(0, PAVED_TOP, gateZ + doors.Landing) + north)
	Markers.Stamp(spot(folder, "Door landing", landingAt), "DoorLanding", { Ground = row.Ground })

	-- Lantern Row's stops, and its stall fronts with the elite's square opened out of them.
	local street = Instance.new("Folder")
	street.Name = "Lantern Row"
	street.Parent = folder
	local squareHalf = studs(row.Square) / 2
	local openings: { { number } } = {} -- z ranges the stall fronts leave open
	local pack = 0
	for index, stop in stops do
		local z = stopZ(index)
		local at = CFrame.lookAt(Vector3.new(0, PAVED_TOP, z), Vector3.new(0, PAVED_TOP, z) + Vector3.new(0, 0, 1)) -- facing the way the player comes
		if stop.Kind == "Pack" then
			pack += 1
			Markers.Stamp(spot(street, `Pack {pack}`, at), "Pack", { Pack = pack, Def = stop.Def, Level = stop.Level, Count = stop.Count or 1, Ground = row.Ground })
		elseif stop.Kind == "Elite" then
			slab(street, "Square", -squareHalf, squareHalf, z - squareHalf, z + squareHalf, PAVED_TOP + OVERLAY, GREY.Plot)
			table.insert(openings, { z - squareHalf, z + squareHalf })
			for _, side in { -1, 1 } do
				wallZ(street, side * (squareHalf + 1), z - squareHalf, z + squareHalf, high)
				wallX(street, z - squareHalf - 1, side * (rowHalf + 1), side * (squareHalf + 2), high)
				wallX(street, z + squareHalf + 1, side * (rowHalf + 1), side * (squareHalf + 2), high)
			end
			Markers.Stamp(spot(street, "Elite", at), "Elite", { Def = stop.Def, Level = stop.Level, Ground = row.Ground })
		elseif stop.Kind == "Keeper" then
			local keeperAt = CFrame.lookAt(Vector3.new(0, PAVED_TOP, z), Vector3.new(0, PAVED_TOP, z) + north)
			Markers.Stamp(gate(street, "Keeper's gate", keeperAt, studs(row.Wide), high, true), "KeeperGate")
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
			wallZ(street, side * (rowHalf + 1), from, opening[2] + 2, high)
			from = opening[1] - 2
		end
		wallZ(street, side * (rowHalf + 1), from, keeperZ, high)
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
		return Markers.Report(WorldConfig.Plots.Count)
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
	for _, problem in Markers.Report(WorldConfig.Plots.Count) do
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
			for _, player in Players:GetPlayers() do
				respawnOn(player)
			end
			WorldService.Laid:Fire()
		end)
	end)
end

return WorldService
