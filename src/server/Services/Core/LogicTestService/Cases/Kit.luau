--!strict
-- Kit cases (pure): Lantern Row's dressing (TR8; docs/asset-requests.md, AR5, section 2, "For the builder"). The kit's
-- plan, taken as it is (Config.Kits.LanternRow), stands every stop on the grey street's markers, names only pieces its
-- manifest has, keeps its lights under round 2's ceiling; a piece stands at its place times its centre.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Kit = require(Shared.World.Kit)
local WorldConfig = require(Shared.Config.World)
local LightingConfig = require(Shared.Config.Lighting)
local Manifest = require(Shared.Config.Kits.LanternRow.Manifest) :: any
local Plan = require(Shared.Config.Kits.LanternRow.Plan) :: any

local CEILING = 14 -- round 2's lights, the ceiling to keep (AR5, section 2, "Delivers", 4)

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-4 * math.max(1, math.abs(b))
end

local function closeTo(a: Vector3, b: Vector3): boolean
	return (a - b).Magnitude <= 1e-4
end

-- The street's stops in studs up from the gate, as WorldService lays their markers (Config.World.Row).
local function streetStops(): { number }
	local row = WorldConfig.Row
	local out: { number } = {}
	for index in row.Stops do
		table.insert(out, WorldConfig.Walk * (row.FirstPack + (index - 1) * row.Spacing))
	end
	return out
end

return {
	{
		Name = "Kit: TR8, Lantern Row's plan stands every stop on the street's marker, names only its manifest's pieces, and keeps its lights under the ceiling",
		Run = function(t: any)
			local problems = Kit.Problems(Manifest.pieces, Plan, streetStops(), CEILING)
			t.Equal("no problems", table.concat(problems, "; "), "")
			t.Equal("the plan's 271 pieces, as its budget counts them", #Plan.placements, Plan.budget.whole_street.pieces)
			local counts: { [string]: number } = {}
			for _, placement in Plan.placements do
				counts[placement.piece] = (counts[placement.piece] or 0) + 1
			end
			for piece, want in Plan.budget.counts do
				t.Equal(`{piece}: laid as often as the budget counts it`, counts[piece], want)
			end
			t.Equal("nine static lights: the budget's ten less the lead's", #Plan.lights, Plan.budget.whole_street.lights - 1)
			local pieces = 0
			for name, piece in Manifest.pieces do
				pieces += 1
				t.Check(`{name}: a centre`, type(piece.centre) == "table" and #piece.centre == 3)
			end
			t.Equal("sixteen pieces", pieces, 16)
			t.Check("the floors are pieces", Manifest.pieces.StreetBay ~= nil and Manifest.pieces.SquareFloor ~= nil)
		end,
	},
	{
		Name = "Kit: TR8, a piece stands at its place times its centre, turned anticlockwise from above; a pool shines straight down",
		Run = function(t: any)
			local gateZ, floorY = -272, 0.6
			-- A stall down the west side, turned -90: its front looks across the street (+X), its centre behind it.
			local stall = Kit.Place({ piece = "StallA", across = -22, along = 35.67, turn = -90 }, Manifest.pieces.StallA, gateZ, floorY)
			local c = Manifest.pieces.StallA.centre
			t.Check("its centre is behind its front, to the west", closeTo(stall.Position, Vector3.new(-22 - c[3], floorY + c[2], gateZ - 35.67)), tostring(stall.Position))
			t.Check("its front looks across the street", closeTo(stall.LookVector, Vector3.xAxis), tostring(stall.LookVector))
			-- The east side's, turned 90, looks west.
			local east = Kit.Place({ piece = "StallA", across = 22, along = 35.67, turn = 90 }, Manifest.pieces.StallA, gateZ, floorY)
			t.Check("an east stall looks west", closeTo(east.LookVector, -Vector3.xAxis), tostring(east.LookVector))
			-- The gate itself, unturned, faces the player walking in (-Z is a piece's front).
			local gate = Kit.Place({ piece = "FestivalGate", across = 0, along = 0, turn = 0 }, Manifest.pieces.FestivalGate, gateZ, floorY)
			t.Check("the gate stands on the gate's line", near(gate.Position.Z, gateZ) and near(gate.Position.Y, floorY + Manifest.pieces.FestivalGate.centre[2]))
			-- The first pack's pool.
			local pool = Plan.lights[1]
			local at = Kit.Light(pool, gateZ, floorY)
			t.Check("the pool hangs over its pack", closeTo(at.Position, Vector3.new(pool.across, floorY + pool.up, gateZ - pool.along)), tostring(at.Position))
			t.Check("and looks straight down", closeTo(at.LookVector, -Vector3.yAxis), tostring(at.LookVector))
		end,
	},
	{
		Name = "Kit: TR8, the drifting paper's air: eight boxes from the festival gate up the street, end to end, over the paving",
		Run = function(t: any)
			-- AR5, "The paper's emitter": the plan's boxes as the look's numbers lay them.
			local paper = Plan.paper
			t.Check("the plan has its paper", paper ~= nil and type(paper.emitter) == "table")
			if paper == nil then
				return
			end
			local boxes = paper.boxes
			t.Equal("eight boxes", #boxes, 8)
			local gateZ, floorY = -272, 0.6
			local first = boxes[1]
			t.Check("the first starts at the gate", near(first.along - first.size[3] / 2, 0), tostring(first.along))
			local at = Kit.Paper(first, gateZ, floorY)
			t.Check("its centre at its place, unturned", closeTo(at.Position, Vector3.new(first.across, floorY + first.up, gateZ - first.along))
				and closeTo(at.LookVector, -Vector3.zAxis), tostring(at.Position))
			local over, joined = true, true
			for index, box in boxes do
				over = over and box.up - box.size[2] / 2 > 0
				local nextBox = boxes[index + 1]
				if nextBox then
					joined = joined and near(nextBox.along - nextBox.size[3] / 2, box.along + box.size[3] / 2)
				end
			end
			t.Check("each box's floor over the paving", over)
			t.Check("end to end up the street", joined)
			t.Equal("its picture the published one's", paper.emitter.Texture, string.match(paper.picture, "[^/]+$"))
		end,
	},
	{
		Name = "Kit: TR8, the paper's band: over the camera's height, the density held, the plan's own without one",
		Run = function(t: any)
			-- Research's TR8 verdict (2026-11-14): a scrap the camera passed filled a corner. Config.Lighting.Paper holds the
			-- boxes in a band over Roblox's starting zoom behind the head, pitched 30 degrees down.
			local paper = Plan.paper
			if paper == nil then
				t.Check("the plan has its paper", false)
				return
			end
			local HEAD, ZOOM, PITCH = 4.5, 12.5, 30 -- an R6 head over the paving, Roblox's starting zoom, a steep look down
			local camera = HEAD + ZOOM * math.sin(math.rad(PITCH))
			local band = LightingConfig.Paper
			t.Check("its floor over the camera's height", band.Floor > camera, `{band.Floor} over {camera}`)
			t.Check("a band, not a sheet", band.Top > band.Floor)
			local box = paper.boxes[1]
			local up, tall, share = Kit.PaperBand(box, band)
			t.Check("its floor and top the band's", near(up - tall / 2, band.Floor) and near(up + tall / 2, band.Top), `{up} {tall}`)
			t.Check("as many scraps in each stud of air", near(paper.emitter.Rate * share / tall, paper.emitter.Rate / box.size[2]))
			local gateZ, floorY = -272, 0.6
			t.Check("the box stands in the band", closeTo(Kit.Paper(box, gateZ, floorY, band).Position,
				Vector3.new(box.across, floorY + band.Floor + tall / 2, gateZ - box.along)))
			local planUp, planTall, planShare = Kit.PaperBand(box, nil)
			t.Check("without a band, the plan's own", planUp == box.up and planTall == box.size[2] and planShare == 1)
		end,
	},
	{
		Name = "Kit: TR8, a stop off its marker, a piece the manifest lacks, lights over the ceiling: each keeps the kit off the street",
		Run = function(t: any)
			local stops = streetStops()
			local moved = table.clone(stops)
			moved[2] += 16
			t.Equal("a stop moved off its marker (the street tuned)", #Kit.Problems(Manifest.pieces, Plan, moved, CEILING), 1)
			t.Equal("a stop missing", #Kit.Problems(Manifest.pieces, Plan, { table.unpack(stops, 1, #stops - 1) }, CEILING), 1)
			local plan = table.clone(Plan)
			plan.placements = table.clone(Plan.placements)
			table.insert(plan.placements, { piece = "Lighthouse", across = 0, along = 0, turn = 0 })
			t.Equal("a piece the manifest lacks", #Kit.Problems(Manifest.pieces, plan, stops, CEILING), 1)
			t.Equal("lights over the ceiling", #Kit.Problems(Manifest.pieces, Plan, stops, #Plan.lights - 1), 1)
		end,
	},
}
