--!strict
-- Logic cases (pure): TR16, "Alone after a fall: the way home" (docs/test-requests.md): what a fallen lead's card offers
-- under it, the next lead or the way home, and the trail's route from the avatar to the gate's home door on Lantern Row's
-- own geometry (Config.World, as WorldService lays it).
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local WayHome = require(Shared.Rules.WayHome)
local Night = require(Shared.Rules.Night)
local HudConfig = require(Shared.Config.Hud)
local WorldConfig = require(Shared.Config.World)
local LightingConfig = require(Shared.Config.Lighting)

local NOW = 1_800_000_000

-- Lantern Row as WorldService lays it: studs are the config's seconds at the walk.
local function studs(seconds: number): number
	return seconds * WorldConfig.Walk
end
local GATE_Z = -300 -- any gate: the route is the same about it
local PAVED_TOP = 0.6
local ROW_HALF = studs(WorldConfig.Row.Wide) / 2
local SQUARE_HALF = studs(WorldConfig.Row.Square) / 2
local DOOR = Vector3.new(ROW_HALF - 4, PAVED_TOP, GATE_Z - WorldConfig.Grey.Door.AtGate)

local function eliteZ(): number
	for index, stop in WorldConfig.Row.Stops do
		if stop.Kind == "Elite" then
			return GATE_Z - studs(WorldConfig.Row.FirstPack + (index - 1) * WorldConfig.Row.Spacing)
		end
	end
	error("Lantern Row has no elite's square")
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function route(from: Vector3): { Vector3 }
	return WayHome.Route(from, DOOR, 0, ROW_HALF - HudConfig.WayHome.Lane)
end

return {
	{
		Name = "WayHome: TR16, a fallen card offers the next lead while another is ready, else the way home out in a ground, and nothing once the lead is back",
		Run = function(t: any)
			local ready: Hud.Other = { Role = "" }
			local healingOne: Hud.Other = { Role = "", Healing = NOW + 30 }
			local healed: Hud.Other = { Role = "", Healing = NOW - 1 }
			local worker: Hud.Other = { Role = "Bay 1" }
			t.Equal("the lead standing: nothing", Hud.AfterFall(false, {}, NOW, true), nil)
			t.Equal("one Voidkin fallen, out on the street: the way home", Hud.AfterFall(true, {}, NOW, true), "Home")
			t.Equal("one fallen, the player already home: nothing", Hud.AfterFall(true, {}, NOW, false), nil)
			t.Equal("a second one ready: the next lead, and no way home", Hud.AfterFall(true, { ready }, NOW, true), "Send")
			t.Equal("a second one ready, at the base too", Hud.AfterFall(true, { ready }, NOW, false), "Send")
			t.Equal("a second still healing from its own fall: the way home", Hud.AfterFall(true, { healingOne }, NOW, true), "Home")
			t.Equal("that second once whole: the next lead", Hud.AfterFall(true, { healed }, NOW, true), "Send")
			t.Equal("a second at work in a bay can't lead: the way home", Hud.AfterFall(true, { worker }, NOW, true), "Home")
			t.Equal("among several, one ready is enough", Hud.AfterFall(true, { worker, healingOne, ready }, NOW, true), "Send")
			t.Equal("the lead itself, were it listed, never sends", Hud.AfterFall(true, { { Role = "Lead" } }, NOW, true), "Home")
			t.Equal("the lead's return: gone, whoever else is ready", Hud.AfterFall(false, { worker, ready }, NOW, true), nil)
			t.Equal("the lead's return alone: gone", Hud.AfterFall(false, {}, NOW, true), nil)
		end,
	},
	{
		Name = "WayHome: TR16, the trail runs on the floor from the avatar to the gate's door, inside the street, square into it from the elite's square",
		Run = function(t: any)
			local lane = ROW_HALF - HudConfig.WayHome.Lane
			t.Check("the lane keeps clear of the stall fronts", lane > 0 and lane < ROW_HALF, `{lane} of {ROW_HALF}`)
			local function inStreet(points: { Vector3 }, from: number): boolean
				for index = from, #points do
					if math.abs(points[index].X) > ROW_HALF - 1 then
						return false
					end
				end
				return true
			end
			local function onFloor(points: { Vector3 }): boolean
				for _, point in points do
					if not near(point.Y, DOOR.Y) then
						return false
					end
				end
				return true
			end
			-- From the elite's square's middle, where its fight ends: one leg, straight down the street to the door.
			local z = eliteZ()
			local middle = route(Vector3.new(0, PAVED_TOP + 3, z))
			t.Equal("from the square's middle: one leg", #middle, 2)
			t.Check("it starts under the avatar", near(middle[1].X, 0) and near(middle[1].Z, z))
			t.Check("it ends at the door", (middle[#middle] - DOOR).Magnitude < 1e-6)
			t.Check("on the floor, at the door's height", onFloor(middle))
			t.Check("inside the street", inStreet(middle, 1))
			t.Check("the square stands inside the ground", Night.Inside(z, GATE_Z, LightingConfig.From))
			-- From the square's wide edge, out past the street's own walls: a step square into the lane, then the leg.
			local edge = route(Vector3.new(SQUARE_HALF - 2, PAVED_TOP + 3, z))
			t.Equal("from the square's edge: a step, then the leg", #edge, 3)
			t.Check("the step goes square across, into the lane", near(edge[2].Z, z) and near(edge[2].X, lane), `{edge[2]}`)
			t.Check("past the step, inside the street", inStreet(edge, 2))
			t.Check("it ends at the door", (edge[#edge] - DOOR).Magnitude < 1e-6)
			local west = route(Vector3.new(-(SQUARE_HALF - 2), PAVED_TOP + 3, z))
			t.Check("the west edge steps in to the lane's west side", #west == 3 and near(west[2].X, -lane))
			-- From the door's landing, south of the gate: one leg, as long as the walk on the floor.
			local landing = Vector3.new(0, PAVED_TOP + 3, GATE_Z + WorldConfig.Grey.Door.Landing)
			local short = route(landing)
			t.Equal("from the landing: one leg", #short, 2)
			t.Check("its length is the walk on the floor", near(WayHome.Length(short), WayHome.Left(landing, DOOR)))
			t.Check("the landing stands inside the ground", Night.Inside(landing.Z, GATE_Z, LightingConfig.From))
			t.Check("the length adds its legs", near(WayHome.Length(edge), (edge[2] - edge[1]).Magnitude + (edge[3] - edge[2]).Magnitude))
			t.Equal("one point has no length", WayHome.Length({ DOOR }), 0)
			-- At the door it's gone.
			local reach = HudConfig.WayHome.Reach
			t.Check("within its reach of the door: arrived", WayHome.Arrived(DOOR + Vector3.new(-reach, 3, 0), DOOR, reach))
			t.Check("a stud past it: not yet", not WayHome.Arrived(DOOR + Vector3.new(-(reach + 1), 3, 0), DOOR, reach))
			t.Check("the square is far from arrived", not WayHome.Arrived(Vector3.new(0, 0, z), DOOR, reach))
		end,
	},
}
