--!strict
-- Kit (shared, pure): a ground's dressing from the asset maker's kit (TR8; docs/asset-requests.md, AR5, section 2, "For the
-- builder"). The kit's two files are taken into Config.Kits.<Kit> as they are (tools/world/kit_take.py): Manifest, each
-- piece's mesh, centre, maps and glow; Plan, where each piece stands, in studs from the festival gate's middle at pavement
-- level, and the street's static lights. WorldService lays a piece wherever its plan says, over the grey street's markers,
-- which stay where TR2 put them (docs/engineering-plan.md, "The world contract"). No Roblox API beyond its data types: it
-- runs with Studio closed.
--   Kit.Place(placement, piece, gateZ, floorY)  a piece's MeshPart CFrame: its place times its centre
--   Kit.Room(frame, placed, piece)              a piece's MeshPart CFrame in a frame's plan (AR56's room and lot)
--   Kit.Light(light, gateZ, floorY)             a static light's CFrame, a SpotLight's shining straight down
--   Kit.Paper(box, gateZ, floorY, band?)        a box of the drifting paper's air: its centre, unturned (the plan's paper)
--   Kit.PaperBand(box, band?)                   the box in a band over the paving (Config.Lighting.Paper): its centre's
--                                              height, its own, and its rate's share, the density held; the plan's own
--                                              without one
--   Kit.Stops(plan)                             the plan's stops in street order, studs from the gate (packs, square, keeper)
--   Kit.Problems(manifest, plan, stops, ceiling) what keeps a kit off a street: a piece the manifest lacks, a stop away
--                                              from the street's marker (`stops`, studs from the gate, in street order), more
--                                              lights than the ceiling
--   Kit.Tag                                     the tag on every piece and light laid, for the client's look
--   Kit.Floors                                  the pieces that are a floor's look: their glow turns with the night

local Kit = {}

Kit.Tag = "GA_Dressing"
Kit.Floors = { StreetBay = true, SquareFloor = true } :: { [string]: boolean }
for _, row in { "A", "B", "C", "D" } do -- the base's sixteen floors, FloorA1 to FloorD4 (AR54), a quarter of the plot each
	for column = 1, 4 do
		Kit.Floors[`Floor{row}{column}`] = true
	end
end

export type Piece = { centre: { number }, size: { number }?, glowStrength: number?, glowTint: string? }
-- up: a machine's (AR15); toward: "crossing", a piece that stands on its plot's crossing side (AR16's Tower, Kit.Toward)
export type Placement = { piece: string, across: number, along: number, turn: number, up: number?, toward: string? }
export type Light = { name: string, across: number, along: number, up: number, colour: string, kind: string, cone: number? }
export type PaperBox = { across: number, along: number, up: number, size: { number } }
export type PaperBand = { Floor: number, Top: number }
export type Plan = {
	placements: { Placement },
	lights: { Light },
	stops: { packs: { number }, square: number, keeper: number },
	paper: { boxes: { PaperBox }, picture: string, emitter: { [string]: any } }?,
}

local NEAR = 0.01 -- studs: a stop on its marker

-- The plan's own formula (Plan.toRoblox): across is +X walking in, along runs up the street to -Z, turn is degrees
-- anticlockwise seen from above; the MeshPart goes at that place times the piece's centre.
function Kit.Place(placement: Placement, piece: Piece, gateZ: number, floorY: number): CFrame
	local c = piece.centre
	return CFrame.new(placement.across, floorY + (placement.up or 0), gateZ - placement.along)
		* CFrame.Angles(0, math.rad(placement.turn), 0)
		* CFrame.new(c[1], c[2], c[3])
end

-- A placement in a frame's own plan (AR56's room and its lot: `at` in the frame's studs on Roblox's axes, `turn`
-- degrees anticlockwise seen from above, `scale` the same on every axis): the frame, then its place, then the piece's
-- centre at its scale. The MeshPart's size is the piece's times `scale`.
export type Placed = { piece: string, tag: string, at: { number }, turn: number, scale: number }
function Kit.Room(frame: CFrame, placed: Placed, piece: Piece): CFrame
	local c, s = piece.centre, placed.scale
	return frame
		* CFrame.new(placed.at[1], placed.at[2], placed.at[3])
		* CFrame.Angles(0, math.rad(placed.turn), 0)
		* CFrame.new(c[1] * s, c[2] * s, c[3] * s)
end

-- A placement as it stands on a plot whose crossing is on its `side` of across (1 or -1): one marked "toward":
-- "crossing" is written as if the crossing were on its across's side, and mirrors, across and turn, on a plot whose
-- crossing is on the other (AR16's sleeping Tower, behind the back corner on the crossing's side, so the two inner
-- Towers flank the side street). Any other placement, and one on the middle line, as it is.
function Kit.Toward(placement: Placement, side: number): Placement
	if placement.toward ~= "crossing" or placement.across == 0 then
		return placement
	end
	local written = if placement.across > 0 then 1 else -1
	if side == written then
		return placement
	end
	local mirrored = table.clone(placement)
	mirrored.across = -placement.across
	mirrored.turn = -placement.turn
	return mirrored
end

-- A light's place; its frame looks straight down, so a SpotLight on a part's Front face shines onto the street.
function Kit.Light(light: Light, gateZ: number, floorY: number): CFrame
	return CFrame.lookAt(Vector3.new(light.across, floorY + light.up, gateZ - light.along), Vector3.new(light.across, floorY, gateZ - light.along), Vector3.zAxis)
end

-- A box of the paper's air (AR5, "The paper's emitter"): `up` is its centre over the paving, its size the box's own.
-- A band moves its floor and top, and its rate follows its height, so as many scraps drift in each stud of air.
function Kit.PaperBand(box: PaperBox, band: PaperBand?): (number, number, number)
	if band == nil then
		return box.up, box.size[2], 1
	end
	local tall = band.Top - band.Floor
	return band.Floor + tall / 2, tall, tall / box.size[2]
end

function Kit.Paper(box: PaperBox, gateZ: number, floorY: number, band: PaperBand?): CFrame
	local up = Kit.PaperBand(box, band)
	return CFrame.new(box.across, floorY + up, gateZ - box.along)
end

function Kit.Stops(plan: Plan): { number }
	local out: { number } = {}
	for _, along in plan.stops.packs do
		table.insert(out, along)
	end
	table.insert(out, plan.stops.square)
	table.insert(out, plan.stops.keeper)
	table.sort(out)
	return out
end

function Kit.Problems(manifest: { [string]: Piece }, plan: Plan, stops: { number }, ceiling: number): { string }
	local problems: { string } = {}
	for index, placement in plan.placements do
		if manifest[placement.piece] == nil then
			table.insert(problems, `placement {index}: "{tostring(placement.piece)}" isn't in the manifest`)
		end
	end
	local planned = Kit.Stops(plan)
	if #planned ~= #stops then
		table.insert(problems, `the plan has {#planned} stops, the street {#stops}`)
	else
		for index, along in planned do
			if math.abs(along - stops[index]) > NEAR then
				table.insert(problems, `stop {index}: the plan has it {along} studs up the street, its marker {stops[index]}`)
			end
		end
	end
	if #plan.lights > ceiling then
		table.insert(problems, `{#plan.lights} lights, over the ceiling of {ceiling}`)
	end
	return problems
end

return Kit
