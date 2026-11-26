--!strict
-- Logic cases (pure): a marked strike's footprint and the lead's ways out of it (TR44; Rules.Mark;
-- Config.Combat.Keeper.Mark and Out). The footprint lands Ahead and Left of its fighter's look, takes a centre on its
-- edge and nothing past it, fills to its ring on the Slam; A follows only a move of Moved studs that ends outside; a miss
-- is on purpose or an accident; B's Recall waits its cooldown. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Mark = require(Shared.Rules.Mark)

local EPS = 1e-6

local function near(a: number, b: number): boolean
	return math.abs(a - b) < EPS
end

return {
	{
		Name = "Mark: the footprint lands Ahead along the look and Left of it, whichever way its fighter faces",
		Run = function(t: any)
			local x, z = Mark.Centre(0, 0, 0, -1, 6, 2)
			-- facing -Z, its left is -X
			t.Check("facing -Z: 6 ahead, 2 to its left", near(x, -2) and near(z, -6), `({x}, {z})`)
			x, z = Mark.Centre(10, 5, 1, 0, 6, 2)
			t.Check("facing +X: its left is -Z", near(x, 16) and near(z, 3), `({x}, {z})`)
			x, z = Mark.Centre(0, 0, 3, 4, 5, 0)
			t.Check("a look of any length is its direction", near(x, 3) and near(z, 4), `({x}, {z})`)
			x, z = Mark.Centre(7, 8, 0, 0, 6, 2)
			t.Check("no look: on the fighter, never a nan", x == 7 and z == 8, `({x}, {z})`)
			local look = Combat.Keeper.Mark
			x, z = Mark.Centre(0, 0, 0, -1, look.Ahead, look.Left)
			local gap = math.sqrt(x * x + z * z)
			t.Check("the keeper's own: past its reach of the swing, inside the slam's old reach", gap > 4 and gap < 10, `{gap}`)
		end,
	},
	{
		Name = "Mark: a centre on the footprint's edge is taken, one past it is not, and the disc fills to its ring on the Slam",
		Run = function(t: any)
			t.Check("the middle", Mark.Inside(0, 0, 5, 0, 0))
			t.Check("on the edge", Mark.Inside(0, 0, 5, 3, 4))
			t.Check("just past it", not Mark.Inside(0, 0, 5, 3, 4.01))
			t.Check("far off", not Mark.Inside(0, 0, 5, 0, 12))
			t.Equal("on going down: empty", Mark.Fill(10, 10, 12), 0)
			t.Equal("halfway", Mark.Fill(11, 10, 12), 0.5)
			t.Equal("on the Slam: full", Mark.Fill(12, 10, 12), 1)
			t.Equal("before it went down: empty", Mark.Fill(9, 10, 12), 0)
			t.Equal("past the Slam: still full", Mark.Fill(13, 10, 12), 1)
			t.Equal("a tell of no length: full", Mark.Fill(10, 10, 10), 1)
		end,
	},
	{
		Name = "Mark: A's lead follows only a move of Moved studs that ends outside the ring",
		Run = function(t: any)
			local least = Combat.Keeper.Out.Moved
			t.Check("moved enough, outside: it follows", Mark.Follows(least, true, least))
			t.Check("moved far, still inside: it fights on", not Mark.Follows(least * 4, false, least))
			t.Check("outside, barely moved (stood outside all along): it fights on", not Mark.Follows(least - 0.1, true, least))
			t.Check("neither: it fights on", not Mark.Follows(0, false, least))
		end,
	},
	{
		Name = "Mark: a miss is on purpose after a move or a Recall in the tell, an accident otherwise, and each counts under its mode",
		Run = function(t: any)
			local least = Combat.Keeper.Out.Moved
			t.Equal("moved", Mark.Purpose(least, false, least), "OnPurpose")
			t.Equal("recalled, unmoved", Mark.Purpose(0, true, least), "OnPurpose")
			t.Equal("neither", Mark.Purpose(least - 0.5, false, least), "Accident")
			local counts: Mark.Counts = {}
			Mark.Count(counts, "A", true)
			Mark.Count(counts, "A", false, "OnPurpose")
			Mark.Count(counts, "A", false, "Accident")
			Mark.Count(counts, "B", false, "OnPurpose")
			local a, b = counts.A, counts.B
			t.Check("A: 3 slams, 1 hit, 2 missed", a.Slams == 3 and a.Hit == 1 and a.Missed == 2)
			t.Check("A: 1 on purpose, 1 by accident", a.OnPurpose == 1 and a.Accident == 1)
			t.Check("B, apart: 1 slam, missed on purpose", b.Slams == 1 and b.Missed == 1 and b.OnPurpose == 1 and b.Hit == 0)
			t.Equal("Off untouched", counts.Off, nil)
		end,
	},
	{
		Name = "Mark: B's Recall is ready at first, waits its cooldown after a press, and the switch reads safely",
		Run = function(t: any)
			local cooldown = Combat.Keeper.Out.Recall.Cooldown
			local ready = Mark.Ready(nil, 100, cooldown)
			t.Check("never pressed: ready", ready)
			local again, from = Mark.Ready(100, 100 + cooldown / 2, cooldown)
			t.Check("halfway through: not yet", not again)
			t.Equal("ready from the press plus its cooldown", from, 100 + cooldown)
			t.Check("on the cooldown's end: ready", (Mark.Ready(100, 100 + cooldown, cooldown)))
			t.Equal("A", Mark.Mode("A"), "A")
			t.Equal("B", Mark.Mode("B"), "B")
			t.Equal("Off", Mark.Mode("Off"), "Off")
			t.Equal("nil: Off", Mark.Mode(nil), "Off")
			t.Equal("a typo: Off", Mark.Mode("b"), "Off")
			t.Check("the config's own is one of them", Mark.Mode(Combat.Keeper.Out.Mode) == Combat.Keeper.Out.Mode)
		end,
	},
	{
		Name = "Mark: the Lamplighter's slam is its signature, its footprint is put down on Plant, before the Slam, and only its Slam lands on it",
		Run = function(t: any)
			local row = Enemies.ById.lamplighter
			t.Equal("the keeper's signature", row.Signature, "KeeperSignature")
			local action = Actions.ById.KeeperSignature
			t.Equal("aimed until Plant", action.Aim, "Plant")
			local aim = action.Beats[action.Aim :: string]
			local marked = 0
			for beat, hit in action.Hits do
				if hit.Mark then
					marked += 1
					t.Check(`{beat} lands after its Aim`, action.Beats[beat] > (aim :: number), `{action.Beats[beat]} after {aim}`)
					t.Check(`{beat}'s tell is 1.5 s or more`, action.Beats[beat] - (aim :: number) >= 1.5)
				end
			end
			t.Equal("one marked hit", marked, 1)
			t.Check("its first after the Challenge, a cooldown from then on", Combat.Keeper.First > 0 and (action.Cooldown or 0) > 0)
			local look = Combat.Keeper.Mark
			t.Check("the ring's edge inside its radius", look.Edge > 0 and look.Edge < look.Radius)
			t.Check("the disc can be seen through", look.Fill > 0 and look.Fill < 1)
		end,
	},
	{
		Name = "Mark: the Dasher elite's fan takes a centre on any of its three lanes, and nothing in its notches (TR69 B)",
		Run = function(t: any)
			local spread = math.rad(25)
			local length, half = 14, 2
			-- along +x from the origin: the middle lane, and the two turned 25 degrees either way
			t.Check("on the middle lane", Mark.Fanned(0, 0, 1, 0, length, half, spread, 10, 0))
			for _, sign in { 1, -1 } do
				local a = sign * spread
				t.Check(`on the lane at {sign * 25} degrees`, Mark.Fanned(0, 0, 1, 0, length, half, spread, 12 * math.cos(a), 12 * math.sin(a)))
			end
			-- in a notch: 12.5 degrees off, 12 out, 2.6 from either lane's line
			local n = math.rad(12.5)
			t.Check("in a notch, far out: nothing", not Mark.Fanned(0, 0, 1, 0, length, half, spread, 12 * math.cos(n), 12 * math.sin(n)))
			t.Check("past the lanes' end: nothing", not Mark.Fanned(0, 0, 1, 0, length, half, spread, length + half + 0.5, 0))
			t.Check("behind the feet: nothing", not Mark.Fanned(0, 0, 1, 0, length, half, spread, -half - 0.5, 0))
			-- Covers reads a fan's shape, and a line without one stays one lane
			local fan: Mark.Shape = { X = 0, Z = 0, Radius = half, Length = length, DirX = 1, DirZ = 0, Fan = spread }
			local side = { 12 * math.cos(spread), 12 * math.sin(spread) }
			t.Check("Covers: the fan takes a side lane", Mark.Covers(fan, side[1], side[2]))
			fan.Fan = nil
			t.Check("Covers: a line alone doesn't", not Mark.Covers(fan, side[1], side[2]))
		end,
	},
	{
		Name = "Mark: a blow crosses the Guard elite's screen only through the wall (TR69 B)",
		Run = function(t: any)
			-- a guard at the origin facing +z, its wall 8 across, 2.6 ahead: from x = -4 to 4 at z = 2.6
			local function screens(ax: number, az: number, tx: number, tz: number): boolean
				return Mark.Screens(0, 0, 0, 1, 8, 2.6, ax, az, tx, tz)
			end
			t.Check("a blow from the street at one behind the wall", screens(0, 8, 0, 0))
			t.Check("and slanting through its end", screens(5, 8, 0, 0))
			t.Check("from beside it, round the end: not", not screens(8, 3, 6, 1))
			t.Check("from behind it to behind it: not", not screens(-2, 0, 2, 0))
			t.Check("two in front of it: not", not screens(-2, 6, 2, 5))
			t.Check("along the wall's own line: not", not screens(-10, 2.6, 10, 2.6))
			t.Check("the wall turns with the guard's look", Mark.Screens(0, 0, 1, 0, 8, 2.6, 8, 0, 0, 0) and not Mark.Screens(0, 0, 1, 0, 8, 2.6, 0, 8, 0, 0))
			t.Check("no look: no wall", not Mark.Screens(0, 0, 0, 0, 8, 2.6, 0, 8, 0, 0))
		end,
	},
}
