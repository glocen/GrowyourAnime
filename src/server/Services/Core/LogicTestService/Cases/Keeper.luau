--!strict
-- Logic cases (pure): the Lamplighter in three phases (TR69 D; Rules.Keeper, Rules.Mark.Swept;
-- Config.Combat.Keeper.Phases). Its share decides its phase, a hit holds at a phase's line, its posts stand evenly round
-- the ring with the first along its look, its sweep turns its arc in its seconds (and back on Hard), its slam's tell is
-- run to its seed, its second slam lands After the first, and a sweep's line strikes what it passed over and nothing
-- else. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local Actions = require(Shared.Definitions.Actions)
local Keeper = require(Shared.Rules.Keeper)
local Mark = require(Shared.Rules.Mark)

local EPS = 1e-6

local function near(a: number?, b: number): boolean
	return a ~= nil and math.abs(a - b) < EPS
end

return {
	{
		Name = "Keeper: its health share decides its phase, a line's own share already the next phase's",
		Run = function(t: any)
			local from = { 0.7, 0.35 }
			t.Equal("full health: phase 1", Keeper.Phase(1, from), 1)
			t.Equal("just over the first line: still 1", Keeper.Phase(0.7001, from), 1)
			t.Equal("on the first line: 2", Keeper.Phase(0.7, from), 2)
			t.Equal("just over the second: 2", Keeper.Phase(0.3501, from), 2)
			t.Equal("on the second: 3", Keeper.Phase(0.35, from), 3)
			t.Equal("nothing left: 3", Keeper.Phase(0, from), 3)
			t.Equal("no lines: one phase", Keeper.Phase(0.5, {}), 1)
		end,
	},
	{
		Name = "Keeper: a hit holds at its phase's line until the turn has played, and the last phase has none",
		Run = function(t: any)
			local from = { 0.7, 0.35 }
			t.Check("phase 1's line: 70% of its most", near(Keeper.Floor(1, 1000, from), 700), `{Keeper.Floor(1, 1000, from)}`)
			t.Check("phase 2's: 35%", near(Keeper.Floor(2, 1000, from), 350), `{Keeper.Floor(2, 1000, from)}`)
			t.Equal("phase 3's: none", Keeper.Floor(3, 1000, from), 0)
			local left, held = Keeper.Clamp(650, 700)
			t.Check("a hit past the line stops on it", left == 700 and held, `{left} {held}`)
			left, held = Keeper.Clamp(750, 700)
			t.Check("one short of it lands whole", left == 750 and not held, `{left} {held}`)
			left, held = Keeper.Clamp(700, 700)
			t.Check("one onto it lands whole", left == 700 and not held, `{left} {held}`)
			left, held = Keeper.Clamp(-20, 0)
			t.Check("a floor of 0 holds nothing: it can fall", left == -20 and not held, `{left} {held}`)
			left, held = Keeper.Clamp(-20, nil)
			t.Check("no floor: it can fall", left == -20 and not held, `{left} {held}`)
		end,
	},
	{
		Name = "Keeper: its posts stand evenly round the ring at its radius, the first along its look, never a nan",
		Run = function(t: any)
			local posts = Keeper.Posts(10, -4, 0, -1, 12, 6)
			t.Equal("six posts", #posts, 6)
			t.Check("the first along the look (-Z)", near(posts[1].X, 10) and near(posts[1].Z, -16), `({posts[1].X}, {posts[1].Z})`)
			local worst = 0
			for index, post in posts do
				local r = math.sqrt((post.X - 10) ^ 2 + (post.Z + 4) ^ 2)
				local nextPost = posts[index % #posts + 1]
				local gap = math.sqrt((post.X - nextPost.X) ^ 2 + (post.Z - nextPost.Z) ^ 2)
				-- six round a ring: each next one a radius away
				worst = math.max(worst, math.abs(r - 12), math.abs(gap - 12))
			end
			t.Check("all on the ring, evenly spaced", worst < 1e-4, `{worst}`)
			local still = Keeper.Posts(0, 0, 0, 0, 5, 3)
			t.Check("no look: still round the ring", still[1].X == still[1].X and near(math.sqrt(still[1].X ^ 2 + still[1].Z ^ 2), 5), `({still[1].X}, {still[1].Z})`)
		end,
	},
	{
		Name = "Keeper: its posts light one at a time, or two at a time across the ring (Hard), each once",
		Run = function(t: any)
			local one = Keeper.Rounds(6, 1)
			t.Equal("one at a time: six steps", #one, 6)
			t.Check("in order", one[1][1] == 1 and one[6][1] == 6, `{one[1][1]} {one[6][1]}`)
			local two = Keeper.Rounds(6, 2)
			t.Equal("two at a time: three steps", #two, 3)
			t.Check("each step's pair across the ring", two[1][1] == 1 and two[1][2] == 4 and two[3][1] == 3 and two[3][2] == 6, `{two[1][1]},{two[1][2]} {two[3][1]},{two[3][2]}`)
			for _, per in { 1, 2, 3, 4, 6, 9 } do
				local seen: { [number]: number } = {}
				local count = 0
				for _, step in Keeper.Rounds(6, per) do
					for _, index in step do
						count += 1
						seen[index] = (seen[index] or 0) + 1
					end
				end
				local once = count == 6
				for index = 1, 6 do
					once = once and seen[index] == 1
				end
				t.Check(`{per} at a time: every post once`, once, `{count}`)
			end
		end,
	},
	{
		Name = "Keeper: its sweep turns its arc in its seconds, and back on Hard; nothing outside it",
		Run = function(t: any)
			local arc = math.rad(120)
			t.Check("at its start: 0", near(Keeper.Sweep(0, 1.6, arc, false), 0), `{Keeper.Sweep(0, 1.6, arc, false)}`)
			t.Check("halfway: half the arc", near(Keeper.Sweep(0.8, 1.6, arc, false), arc / 2), `{Keeper.Sweep(0.8, 1.6, arc, false)}`)
			t.Check("at its end: the arc", near(Keeper.Sweep(1.6, 1.6, arc, false), arc), `{Keeper.Sweep(1.6, 1.6, arc, false)}`)
			t.Equal("past its end: done", Keeper.Sweep(1.7, 1.6, arc, false), nil)
			t.Equal("before its start: nil", Keeper.Sweep(-0.1, 1.6, arc, false), nil)
			t.Check("Hard: halfway back", near(Keeper.Sweep(2.4, 1.6, arc, true), arc / 2), `{Keeper.Sweep(2.4, 1.6, arc, true)}`)
			t.Check("Hard: home again", near(Keeper.Sweep(3.2, 1.6, arc, true), 0), `{Keeper.Sweep(3.2, 1.6, arc, true)}`)
			t.Equal("Hard: done after", Keeper.Sweep(3.3, 1.6, arc, true), nil)
		end,
	},
	{
		Name = "Keeper: phase 3's slam runs its tell to the seed, the second slam lands After the first's",
		Run = function(t: any)
			local beats = Actions.ById.KeeperSignature.Beats
			local span = beats.Slam - beats.Plant
			local tell = Combat.Keeper.Phases.Slam.Tell
			local rate = Keeper.Rate(span, tell)
			t.Check("its tell at that rate lasts the seed", near(span / rate, math.min(span, tell)), `{span / rate} against {tell}`)
			t.Equal("a tell already short enough: rate 1", Keeper.Rate(1, 1.2), 1)
			t.Equal("no tell: rate 1", Keeper.Rate(1.5, 0), 1)
			local down, slam = Keeper.Second(10, 0.9, 1.2)
			t.Check("the second lands After the first", near(slam, 10.9), `{slam}`)
			t.Check("its tell runs Tell", near(slam - down, 1.2), `{slam - down}`)
		end,
	},
	{
		Name = "Mark: a sweep's line strikes what it turned over, its width either side, and nothing behind or past it",
		Run = function(t: any)
			-- from +X round to +Z, 10 studs long, 1 either side
			local a0, a1, length, half = 0, math.pi / 2, 10, 1
			local function swept(x: number, z: number): boolean
				return Mark.Swept(0, 0, a0, a1, length, half, x, z)
			end
			t.Check("on its first side", swept(5, 0))
			t.Check("on its last side", swept(0, 5))
			t.Check("between them", swept(5, 5))
			t.Check("at its foot", swept(0.5, -0.2))
			t.Check("its width beyond the first side", swept(5, -0.9))
			t.Check("not past its width", not swept(5, -1.5))
			t.Check("not behind it", not swept(-5, 0))
			t.Check("its width past its end", swept(10.5, 0))
			t.Check("not past that", not swept(11.5, 0))
			-- across the angle's wrap: from -Z round through +X to +Z
			t.Check("across the wrap: +X inside", Mark.Swept(0, 0, 3 * math.pi / 2, 5 * math.pi / 2, length, half, 5, 0))
			t.Check("across the wrap: -X outside", not Mark.Swept(0, 0, 3 * math.pi / 2, 5 * math.pi / 2, length, half, -5, 0))
			local shape = { X = 0, Z = 0, Radius = half, Length = length, From = a0, Arc = a1 - a0 }
			t.Check("Covers reads a sweep's shape as its arc", Mark.Covers(shape :: any, 5, 5) and not Mark.Covers(shape :: any, -5, 0))
		end,
	},
	{
		Name = "Keeper: the phases' seeds hang together (off by default, lines falling, pools inside the ring, the sweep's tell its beat)",
		Run = function(t: any)
			local p = Combat.Keeper.Phases
			t.Equal("Off until it's judged in play", p.On, false)
			t.Check("its lines fall, inside (0, 1)", p.From[1] < 1 and p.From[2] < p.From[1] and p.From[2] > 0, `{p.From[1]}, {p.From[2]}`)
			t.Check("a pool fits inside the ring", p.Pools.Radius < p.Mid.Radius, `{p.Pools.Radius} in {p.Mid.Radius}`)
			t.Check("a round's pools are down before the next round", (p.Mid.Posts - 1) * p.Pools.Gap + p.Pools.Tell < p.Pools.Every, `{(p.Mid.Posts - 1) * p.Pools.Gap + p.Pools.Tell} in {p.Pools.Every}`)
			local sweep = Actions.ById.KeeperSweep
			t.Check("the sweep's line turns on its action's Sweep beat", near(sweep.Beats.Sweep, p.Sweep.Tell), `{sweep.Beats.Sweep} against {p.Sweep.Tell}`)
			local light = Actions.ById.KeeperLight
			t.Check("the pools' and the sweep's hits are written", light.Hits.Pool ~= nil and light.Hits.Sweep ~= nil)
			t.Check("the second slam has its hit", Actions.ById.KeeperSignature.Hits.Slam ~= nil)
			t.Check("a sweep's window is open before the next", p.Sweep.Tell + p.Sweep.Seconds + p.Sweep.Window < p.Sweep.Every, `{p.Sweep.Tell + p.Sweep.Seconds + p.Sweep.Window} in {p.Sweep.Every}`)
		end,
	},
}
