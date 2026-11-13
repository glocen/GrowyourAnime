--!strict
-- Hud cases (pure): the flurry's one counting number, a number placed clear of its neighbours', the type edge's arrow for
-- every pair, the digits, and what a control says (docs/test-requests.md, TR3, "Checks").
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local Hit = require(Shared.Rules.Hit)
local StatsConfig = require(Shared.Config.Stats)

local COUNT = 0.12 -- seconds a number counts over
local SECONDS = 0.8 -- seconds a number shows after its last amount

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(b))
end

return {
	{
		Name = "Hud: a flurry is one number counting the real total",
		Run = function(t: any)
			local c = Hud.Count(37)
			t.Equal("the first hit shows whole", Hud.Shown(c, 0, COUNT), 37)
			t.Check("it shows", Hud.Live(c, 0.79, SECONDS))
			Hud.Add(c, 40, 0.2, COUNT)
			t.Equal("the total is both hits", c.Total, 77)
			t.Equal("it counts from what it showed", Hud.Shown(c, 0.2, COUNT), 37)
			local half = Hud.Shown(c, 0.2 + COUNT / 2, COUNT)
			t.Check("halfway it's past the middle (out fast)", half > 57 and half < 77)
			t.Equal("counted, it shows the total", Hud.Shown(c, 0.2 + COUNT, COUNT), 77)
			t.Equal("and stays there", Hud.Shown(c, 0.7, COUNT), 77)
			-- A hit landing mid-count starts from the number on screen, never from the old total.
			Hud.Add(c, 23, 0.3, COUNT)
			local from = 37 + 40 * Hud.Ease(0.1 / COUNT)
			t.Check("mid-count, it counts on from what it showed", near(c.From, from))
			t.Equal("the real total", c.Total, 100)
			t.Equal("counted", Hud.Shown(c, 0.3 + COUNT, COUNT), 100)
			t.Check("its fade starts over from the last hit", Hud.Live(c, 0.3 + SECONDS - 0.01, SECONDS))
			t.Check("and ends a life after it", not Hud.Live(c, 0.3 + SECONDS, SECONDS))
			t.Equal("swelling the moment a hit joins", Hud.Swell(c, 0.3, COUNT), 1)
			t.Equal("settled once counted", Hud.Swell(c, 0.3 + COUNT, COUNT), 0)
			t.Equal("a lone hit never swells", Hud.Swell(Hud.Count(5), 0, COUNT), 0)
			local word = Hud.Count(0)
			Hud.Add(word, 0, 0.5, COUNT)
			t.Equal("a word said again stays a word", word.Total, 0)
			t.Check("and its fade starts over", Hud.Live(word, 1.2, SECONDS))
			t.Equal("no count time: it shows the total at once", Hud.Shown(c, 0.3, 0), 100)
		end,
	},
	{
		Name = "Hud: a number is placed clear of its neighbours'",
		Run = function(t: any)
			local slots = { { 0, 0 }, { 0, -1 }, { -1, -0.5 }, { 1, -0.5 } }
			local want: Hud.Box = { X = 100, Y = 100, W = 60, H = 24 }
			local x, y = Hud.Place(want, {}, slots)
			t.Check("alone, it stays where it rose", x == 0 and y == 0)
			x, y = Hud.Place(want, { { X = 110, Y = 104, W = 60, H = 24 } }, slots)
			t.Check("over a neighbour, it goes up a height", x == 0 and y == -24)
			x, y = Hud.Place(want, { { X = 100, Y = 100, W = 60, H = 24 }, { X = 100, Y = 76, W = 60, H = 24 } }, slots)
			t.Check("both taken, it goes aside", x == -60 and y == -12)
			local full = {
				{ X = 100, Y = 100, W = 200, H = 200 },
			}
			x, y = Hud.Place(want, full, slots)
			t.Check("every slot covered: the first that covers least", x == 0 and y == 0)
			x, y = Hud.Place(want, { { X = 200, Y = 100, W = 60, H = 24 } }, slots)
			t.Check("a number far off doesn't move it", x == 0 and y == 0)
			x, y = Hud.Place(want, { { X = 160, Y = 100, W = 60, H = 24 } }, slots)
			t.Check("edges touching isn't overlapping", x == 0 and y == 0)
		end,
	},
	{
		Name = "Hud: a number's whole life stays under the top band",
		Run = function(t: any)
			-- TR3's verdict, fix 4: the band's lower edge at 50, and a number that climbs 20 after its birth.
			local slots = { { 0, 0 }, { 0, -1 }, { -1, -0.5 }, { 1, -0.5 } }
			local TOP, RISE = 50, 20
			local function peak(want: Hud.Box, dy: number): number
				return want.Y + dy - want.H / 2 - RISE
			end
			local far: Hud.Box = { X = 100, Y = 100, W = 60, H = 24 }
			local x, y = Hud.Place(far, {}, slots, TOP, RISE)
			t.Check("well under the band, it stays where it rose", x == 0 and y == 0)
			local near: Hud.Box = { X = 100, Y = 70, W = 60, H = 24 }
			x, y = Hud.Place(near, {}, slots, TOP, RISE)
			t.Equal("born near the band, it starts lower", y, 12)
			t.Equal("as far as its peak meets the band, no farther", peak(near, y), TOP)
			x, y = Hud.Place(near, { { X = 100, Y = 82, W = 60, H = 24 } }, slots, TOP, RISE)
			t.Check("a neighbour there: it goes aside, never up over the band", x == -60 and y == 12)
			t.Check("its peak still under the band", peak(near, y) >= TOP)
			local over: Hud.Box = { X = 100, Y = 30, W = 60, H = 24 }
			x, y = Hud.Place(over, { { X = 100, Y = 100, W = 600, H = 200 } }, slots, TOP, RISE)
			t.Check("every slot covered: still under the band", peak(over, y) >= TOP - 1e-9)
			x, y = Hud.Place(near, {}, slots)
			t.Check("no band: as before", x == 0 and y == 0)
			x, y = Hud.Place(near, {}, slots, TOP, -5)
			t.Equal("a rise below nothing counts as none: its top at 58, clear of the band", y, 0)
		end,
	},
	{
		Name = "Hud: the type edge's arrow for every pair",
		Run = function(t: any)
			local types: { string } = {}
			for attacker in StatsConfig.Beats do
				table.insert(types, attacker)
			end
			table.sort(types)
			t.Equal("five types", #types, 5)
			local ups, downs = 0, 0
			for _, mine in types do
				for _, theirs in types do
					local arrow = Hud.Arrow(mine, theirs)
					local want = if StatsConfig.Beats[mine] == theirs
						then "Up"
						elseif StatsConfig.Beats[theirs] == mine then "Down"
						else ""
					t.Equal(`{mine} on {theirs}`, arrow, want)
					t.Equal(`{mine} on {theirs} agrees with the hit's relation`, arrow, ({ [1] = "Up", [-1] = "Down", [0] = "" })[Hit.TypeRelation(mine, theirs)])
					ups += if arrow == "Up" then 1 else 0
					downs += if arrow == "Down" then 1 else 0
				end
			end
			t.Equal("each type beats one", ups, 5)
			t.Equal("and is beaten by one", downs, 5)
			t.Equal("a type against itself has no arrow", Hud.Arrow("Strength", "Strength"), "")
			t.Equal("an unknown type has no arrow", Hud.Arrow(nil, "Strength"), "")
			t.Equal("nor an empty one", Hud.Arrow("Agility", ""), "")
		end,
	},
	{
		Name = "Hud: digits with thousands separators",
		Run = function(t: any)
			t.Equal("small", Hud.Digits(7), "7")
			t.Equal("three digits", Hud.Digits(203), "203")
			t.Equal("four", Hud.Digits(2357), "2,357")
			t.Equal("seven", Hud.Digits(1234567), "1,234,567")
			t.Equal("rounded", Hud.Digits(999.6), "1,000")
			t.Equal("negative", Hud.Digits(-1200), "-1,200")
			t.Equal("nothing", Hud.Digits(0), "0")
			t.Equal("a sliver below nothing is nothing", Hud.Digits(-0.2), "0")
		end,
	},
	{
		Name = "Hud: a card's health in whole points, never past its most",
		Run = function(t: any)
			t.Equal("full, with a fractional most", Hud.Health(881.1, 881.1), "882 / 882")
			t.Equal("a heal a hair past the most", Hud.Health(881.4, 881.1), "882 / 882")
			t.Equal("hurt", Hud.Health(504.2, 881.1), "505 / 882")
			t.Equal("a sliver still standing shows 1", Hud.Health(0.3, 881.1), "1 / 882")
			t.Equal("down", Hud.Health(0, 881.1), "0 / 882")
			t.Equal("below nothing is nothing", Hud.Health(-4, 881.1), "0 / 882")
			t.Equal("thousands", Hud.Health(1165.5, 1166), "1,166 / 1,166")
			t.Equal("float noise on a whole most", Hud.Health(1166.0000001, 1166.0000001), "1,166 / 1,166")
		end,
	},
	{
		Name = "Hud: a number too wide for its bar takes its compact form",
		Run = function(t: any)
			-- TR3's verdict, fix 6: three figures and a unit, cut and never rounded up.
			t.Equal("under a thousand, whole", Hud.Short(999), "999")
			t.Equal("a thousand", Hud.Short(1000), "1K")
			t.Equal("three figures", Hud.Short(1250), "1.25K")
			t.Equal("cut, never rounded up", Hud.Short(1259), "1.25K")
			t.Equal("float noise doesn't cut a figure", Hud.Short(1150), "1.15K")
			t.Equal("a trailing nought dropped", Hud.Short(1200), "1.2K")
			t.Equal("tens", Hud.Short(12345), "12.3K")
			t.Equal("hundreds", Hud.Short(999999), "999K")
			t.Equal("millions", Hud.Short(1250000), "1.25M")
			t.Equal("billions", Hud.Short(125e9), "125B")
			t.Equal("trillions", Hud.Short(3.4e12), "3.4T")
			t.Equal("negative", Hud.Short(-12500), "-12.5K")
			t.Equal("nothing", Hud.Short(0), "0")
			t.Equal("room enough: the digits", Hud.Health(12345, 12345, 18), "12,345 / 12,345")
			t.Equal("too wide: compact", Hud.Health(1249999, 1250000, 18), "1.24M / 1.25M")
			t.Equal("cut: a hurt card never reads full", Hud.Health(1249000, 1250000, 18), "1.24M / 1.25M")
			t.Equal("full", Hud.Health(1250000, 1250000, 18), "1.25M / 1.25M")
			t.Equal("no room given: the digits", Hud.Health(1250000, 1250000), "1,250,000 / 1,250,000")
			t.Equal("just fits", #Hud.Health(123456, 123456, 17), 17)
			t.Equal("compact only when it's shorter", Hud.Health(1166, 1166, 5), "1,166 / 1,166")
			t.Equal("the dummy's, on the target's bar (TR3's capture)", Hud.Health(1254735, 1254735, 18), "1.25M / 1.25M")
			-- The lead's card sets its digits tight: no spaces round the slash, and its room counts that way too.
			t.Equal("tight", Hud.Health(504.2, 881.1, nil, true), "505/882")
			t.Equal("tight, thousands", Hud.Health(1165.5, 1166, 18, true), "1,166/1,166")
			t.Equal("tight just fits", #Hud.Health(1234567, 1234567, 19, true), 19)
			t.Equal("tight, too wide: compact", Hud.Health(1249999, 1250000, 18, true), "1.24M/1.25M")
		end,
	},
	{
		Name = "Hud: a disabled control says why",
		Run = function(t: any)
			t.Equal("at rest, its label", Hud.Says("Lead", nil, false), "Lead")
			t.Equal("disabled, its reason", Hud.Says("Lead", "Leading", false), "Leading")
			t.Equal("waiting, the server's pending mark", Hud.Says("Lead", nil, true), Hud.Pending)
			t.Equal("waiting outranks a reason", Hud.Says("Lead", "Leading", true), Hud.Pending)
			t.Equal("an empty reason is no reason", Hud.Says("Lead", "", false), "Lead")
			t.Equal("the lead can't lead again", Hud.LeadReason("Lead"), "Leading")
			t.Equal("a worker is at work", Hud.LeadReason("Worker"), "At work")
			t.Equal("an idle Voidkin can lead", Hud.LeadReason(""), nil)
			t.Equal("no Voidkin, no roster", Hud.VoidkinReason(0), "No Voidkin")
			t.Equal("one Voidkin opens it", Hud.VoidkinReason(1), nil)
		end,
	},
	{
		Name = "Hud: a fallen lead's seconds and the signature's ring",
		Run = function(t: any)
			t.Equal("rounded up", Hud.Back(10.2, 5), 6)
			t.Equal("never below one while down", Hud.Back(10, 10.5), 1)
			t.Equal("empty the moment it fires", Hud.Ready(20, 10, 10), 0)
			t.Equal("half way", Hud.Ready(20, 10, 15), 0.5)
			t.Equal("full once ready", Hud.Ready(20, 10, 20), 1)
			t.Equal("and stays full", Hud.Ready(20, 10, 99), 1)
			t.Equal("no cooldown, always full", Hud.Ready(20, 0, 10), 1)
		end,
	},
}
