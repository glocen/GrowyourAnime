--!strict
-- Kit (shared, pure): a ground's dressing from the asset maker's kit (TR8; docs/asset-requests.md, AR5, section 2, "For the
-- builder"). The kit's two files are taken into Config.Kits.<Kit> as they are (tools/world/kit_take.py): Manifest, each
-- piece's mesh, centre, maps and glow; Plan, where each piece stands, in studs from the festival gate's middle at pavement
-- level, and the street's static lights. WorldService lays a piece wherever its plan says, over the grey street's markers,
-- which stay where TR2 put them (docs/engineering-plan.md, "The world contract"). No Roblox API beyond its data types: it
-- runs with Studio closed.
--   Kit.Place(placement, piece, gateZ, floorY)  a piece's MeshPart CFrame: its place times its centre
--   Kit.Light(light, gateZ, floorY)             a static light's CFrame, a SpotLight's shining straight down
--   Kit.Stops(plan)                             the plan's stops in street order, studs from the gate (packs, square, keeper)
--   Kit.Problems(manifest, plan, stops, ceiling) what keeps a kit off a street: a piece the manifest lacks, a stop away
--                                              from the street's marker (`stops`, studs from the gate, in street order), more
--                                              lights than the ceiling
--   Kit.Tag                                     the tag on every piece and light laid, for the client's look
--   Kit.Floors                                  the pieces that are a floor's look: their glow turns with the night

local Kit = {}

Kit.Tag = "GA_Dressing"
Kit.Floors = { StreetBay = true, SquareFloor = true } :: { [string]: boolean }

export type Piece = { centre: { number }, size: { number }?, glowStrength: number?, glowTint: string? }
export type Placement = { piece: string, across: number, along: number, turn: number }
export type Light = { name: string, across: number, along: number, up: number, colour: string, kind: string, cone: number? }
export type Plan = {
	placements: { Placement },
	lights: { Light },
	stops: { packs: { number }, square: number, keeper: number },
}

local NEAR = 0.01 -- studs: a stop on its marker

-- The plan's own formula (Plan.toRoblox): across is +X walking in, along runs up the street to -Z, turn is degrees
-- anticlockwise seen from above; the MeshPart goes at that place times the piece's centre.
function Kit.Place(placement: Placement, piece: Piece, gateZ: number, floorY: number): CFrame
	local c = piece.centre
	return CFrame.new(placement.across, floorY, gateZ - placement.along)
		* CFrame.Angles(0, math.rad(placement.turn), 0)
		* CFrame.new(c[1], c[2], c[3])
end

-- A light's place; its frame looks straight down, so a SpotLight on a part's Front face shines onto the street.
function Kit.Light(light: Light, gateZ: number, floorY: number): CFrame
	return CFrame.lookAt(Vector3.new(light.across, floorY + light.up, gateZ - light.along), Vector3.new(light.across, floorY, gateZ - light.along), Vector3.zAxis)
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
