--!strict
-- Hud cases (pure): the flurry's one counting number, a number placed clear of its neighbours', the type edge's arrow for
-- every pair, the digits, and what a control says (docs/test-requests.md, TR3, "Checks"); the interface's motion: a
-- press's squeeze, a reward's pop, a number's size by its rung and its giving way (AR8 C); the effects kit's count, its
-- flock and its arc (TR6); the spectate's ease (TR11).
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Hud = require(Shared.Rules.Hud)
local Hit = require(Shared.Rules.Hit)
local StatsConfig = require(Shared.Config.Stats)
local HudConfig = require(Shared.Config.Hud)

local COUNT = 0.12 -- seconds a number counts over
local SECONDS = 0.8 -- seconds a number shows after its last amount

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(b))
end

return {
	{
		Name = "Hud: the top band goes see-through over a keeper, never past research's floors",
		Run = function(t: any)
			local card: Hud.Rect = { Left = 260, Top = 17, Right = 490, Bottom = 80 }
			t.Check("a hat under the card is over it", Hud.Over(card, { Left = 380, Top = 60, Right = 420, Bottom = 110 }))
			t.Check("one beside it isn't", not Hud.Over(card, { Left = 495, Top = 30, Right = 540, Bottom = 90 }))
			t.Check("one below it isn't", not Hud.Over(card, { Left = 380, Top = 81, Right = 420, Bottom = 120 }))
			t.Check("touching edges aren't over", not Hud.Over(card, { Left = 490, Top = 17, Right = 520, Bottom = 80 }))
			t.Check("a box inside it is over", Hud.Over(card, { Left = 300, Top = 30, Right = 310, Bottom = 40 }))
			local see = HudConfig.SeeThrough
			t.Equal("research's term: the economy pills and the toast fade to a quarter", see.Economy, 0.25)
			t.Check("research's term: the Target card never lower than half", see.Target >= 0.5, tostring(see.Target))
			t.Check("its bar stays more solid than the card", see.Bar >= see.Target, tostring(see.Bar))
			t.Equal("whole, nothing faded", Hud.Through(0, see.Target), 1)
			t.Check("at its floor, the card at Target", near(Hud.Through(1, see.Target), see.Target))
			t.Check("never past it", near(Hud.Through(3, see.Target), see.Target))
			t.Check("halfway, halfway", near(Hud.Through(0.5, 0.5), 0.75))
			t.Check("an opaque part at half shows half", near(Hud.Faded(0, 0.5), 0.5))
			t.Check("a part already half see-through at half shows a quarter", near(Hud.Faded(0.5, 0.5), 0.75))
			t.Check("a hidden part stays hidden", near(Hud.Faded(1, 0.25), 1))
			t.Check("whole, a part keeps its own", near(Hud.Faded(0.3, 1), 0.3))
			t.Check("the keeper's hat and lantern are the parts watched", table.find(see.Parts.Lamplighter, "Lamplighter_Head") ~= nil and table.find(see.Parts.Lamplighter, "Lamplighter_Lantern") ~= nil)
			-- TR7, research's call on the hang (a): the effects' pieces it watches too, by a tag (your lead's hanging square)
			t.Check("an effect's watched pieces carry a tag", type(see.Tag) == "string" and #see.Tag > 0, tostring(see.Tag))
		end,
	},
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
	{
		Name = "Hud: a press squeezes at once, holds a quick tap, and comes back over its mark to exactly 1",
		Run = function(t: any)
			local press = HudConfig.Motion.Press
			t.Equal("untouched, full size", Hud.Squeeze(5, nil, nil, press), 1)
			t.Equal("the touch's own frame, full size", Hud.Squeeze(5, 5, nil, press), 1)
			local early = Hud.Squeeze(5 + press.In / 2, 5, nil, press)
			t.Check("half its In, past half the squeeze (eased out)", early < 1 - (1 - press.Squeeze) / 2 and early > press.Squeeze)
			t.Check("squeezed within 0.1 s (rule 4)", near(Hud.Squeeze(5 + math.min(press.In, 0.1), 5, nil, press), press.Squeeze))
			t.Check("held, it stays squeezed", near(Hud.Squeeze(9, 5, nil, press), press.Squeeze))
			t.Check("a squeeze a thumb feels: 5 to 12 per cent", press.Squeeze >= 0.88 and press.Squeeze <= 0.95)
			-- A tap shorter than Least stays down until Least.
			local up = 5 + press.Least / 4
			t.Check("a quick tap stays squeezed to Least", near(Hud.Squeeze(5 + press.Least, 5, up, press), press.Squeeze))
			local from = 5 + press.Least
			local most = 0
			for i = 1, 40 do
				most = math.max(most, Hud.Squeeze(from + press.Out * i / 40, 5, up, press))
			end
			t.Check("it comes back past full size for a moment", most > 1)
			t.Check("by a small mark, under 3 per cent", most < 1.03)
			t.Equal("and settles at exactly 1", Hud.Squeeze(from + press.Out, 5, up, press), 1)
			t.Equal("an old let-go is ignored", Hud.Squeeze(9, 5, 4, press), Hud.Squeeze(9, 5, nil, press))
			-- A long hold comes back from where it was, at once.
			t.Check("a long hold starts back the moment it's let go", near(Hud.Squeeze(8, 5, 8, press), press.Squeeze))
		end,
	},
	{
		Name = "Hud: a reward pops early and settles, larger by its rung",
		Run = function(t: any)
			local pop = HudConfig.Pop
			t.Equal("nothing before", Hud.Pop(0, pop.Peak), 0)
			t.Equal("full at its peak", Hud.Pop(pop.Peak, pop.Peak), 1)
			t.Equal("nothing after", Hud.Pop(1, pop.Peak), 0)
			t.Check("the peak early: in its first third", pop.Peak > 0 and pop.Peak <= 1 / 3)
			t.Check("quick up: past half by a quarter of the way", Hud.Pop(pop.Peak / 4, pop.Peak) > 0.4)
			t.Check("the settle eases in and out: slow off the peak", Hud.Pop(pop.Peak + 0.05 * (1 - pop.Peak), pop.Peak) > 0.98)
			t.Equal("rung 1 doesn't swell", Hud.PopScale(1, pop.Swell), 1)
			local last = 0
			for _, key in { "Xp", "Credits", "Level" } do
				local scale = Hud.PopScale(pop.Rungs[key], pop.Swell)
				t.Check(`{key} swells more than the rung below`, scale > last)
				last = scale
			end
			t.Check("a level, rung 5, swells under a third", last < 4 / 3)
			t.Check("an exit never outlasts its entrance (about 0.8)", HudConfig.Motion.Screen.Exit <= 0.85 * HudConfig.Motion.Screen.Enter)
			t.Check("and a toast's", HudConfig.Motion.Toast.Exit <= 0.85 * HudConfig.Motion.Toast.Enter)
		end,
	},
	{
		Name = "Hud: a number's size follows its hit's rung, and a lower one gives way, eased in",
		Run = function(t: any)
			local by = HudConfig.Numbers.Rung
			t.Equal("an ordinary hit, its style's size", Hud.NumberScale("Dealt", 2, by), 1)
			t.Equal("no rung, its style's size", Hud.NumberScale("Dealt", nil, by), 1)
			t.Equal("a critical at its own rung", Hud.NumberScale("Critical", 4, by), 1)
			t.Check("a signature's hit is larger", Hud.NumberScale("Dealt", 7, by) > Hud.NumberScale("Dealt", 3, by))
			t.Check("a combo's last is larger than a hit", Hud.NumberScale("Dealt", 3, by) > 1)
			t.Equal("never past Most", Hud.NumberScale("Dealt", 99, by), by.Most)
			t.Equal("a lower rung never shrinks it", Hud.NumberScale("Critical", 2, by), 1)
			local fade0, aside0 = Hud.Yield(0, 0.1)
			t.Equal("not faded the moment it lands", fade0, 0)
			t.Equal("not moved yet", aside0, 0)
			local fade, aside = Hud.Yield(0.05, 0.1)
			t.Check("half way: the fade eased in, slow first", fade < 0.5)
			t.Check("and the step aside eased out, quick first", aside > 0.5)
			local fade1, aside1 = Hud.Yield(1, 0.1)
			t.Equal("gone by its seconds", fade1, 1)
			t.Equal("all the way aside", aside1, 1)
			t.Check("it leaves within a tenth (research's fix 1)", HudConfig.Numbers.Yield.Seconds <= 0.1)
		end,
	},
	{
		Name = "Hud: TR6, a count is Expo out, a reward's flock grows with its size, and each icon's arc bows off the line",
		Run = function(t: any)
			t.Equal("a count starts at its old value", Hud.ExpoOut(0), 0)
			t.Equal("and ends exactly on its new", Hud.ExpoOut(1), 1)
			t.Equal("never before its start", Hud.ExpoOut(-1), 0)
			t.Equal("nor past its end", Hud.ExpoOut(2), 1)
			t.Check("most of it fast: past 95% by half its seconds", Hud.ExpoOut(0.5) > 0.95)
			local rising = true
			for i = 1, 100 do
				rising = rising and Hud.ExpoOut(i / 100) >= Hud.ExpoOut((i - 1) / 100)
			end
			t.Check("never back down", rising)
			local fly = HudConfig.Motion.Fly
			t.Equal("nothing won, nothing flies", Hud.Flock(0, fly.Least, fly.Most), 0)
			t.Equal("a spend, nothing", Hud.Flock(-5, fly.Least, fly.Most), 0)
			t.Equal("a small win flies its least", Hud.Flock(3, fly.Least, fly.Most), fly.Least)
			t.Equal("ten, one more", Hud.Flock(10, fly.Least, fly.Most), fly.Least + 1)
			t.Equal("a hundred, two more", Hud.Flock(100, fly.Least, fly.Most), fly.Least + 2)
			t.Equal("a thousand, exactly three more (no rounding below)", Hud.Flock(1000, fly.Least, fly.Most), fly.Least + 3)
			t.Equal("never past its most", Hud.Flock(1e12, fly.Least, fly.Most), fly.Most)
			t.Check("the study's 4 to 8 (DESIGN 3)", fly.Least >= 4 and fly.Most <= 8 and fly.Least <= fly.Most)
			local from, to = Vector2.new(0, 0), Vector2.new(100, 0)
			t.Check("an arc leaves from its start", (Hud.Arc(from, to, 0.35, 0) - from).Magnitude < 1e-9)
			t.Check("and lands on its end", (Hud.Arc(from, to, 0.35, 1) - to).Magnitude < 1e-9)
			local mid = Hud.Arc(from, to, 0.35, 0.5)
			t.Check("it bows off the straight line", math.abs(mid.Y) > 10)
			t.Check("the other way with the bend's other sign", (Hud.Arc(from, to, -0.35, 0.5).Y > 0) ~= (mid.Y > 0))
			t.Check("a bend of 0 is the straight line", Hud.Arc(from, to, 0, 0.5).Y == 0)
			t.Check("half way along at half its time", math.abs(mid.X - 50) < 1e-9)
		end,
	},
	{
		Name = "Hud: TR11, the spectate's ease: about 95% of the way by its seconds, never past, and smooth both ways",
		Run = function(t: any)
			local ease = HudConfig.Spectate.Ease
			local function run(share: number, want: number, seconds: number, dt: number): number
				local left = seconds
				while left > 1e-9 do
					local step = math.min(dt, left)
					share = Hud.Approach(share, want, step, ease)
					left -= step
				end
				return share
			end
			local frame = 1 / 60
			t.Check("the entry's about 0.3 s", ease >= 0.2 and ease <= 0.45, `{ease}`)
			local there = run(0, 1, ease, frame)
			t.Check("on the lead by its ease", there >= 0.94 and there < 1, `{there}`)
			local early = run(0, 1, ease / 4, frame)
			t.Check("eased, not snapped: part way at a quarter of it", early > 0.3 and early < 0.75, `{early}`)
			local back = run(1, 0, ease, frame)
			t.Check("back by its ease too", back <= 0.06 and back >= 0, `{back}`)
			local turned = run(run(0, 1, ease / 2, frame), 0, frame, frame)
			t.Check("a change of mind turns it on the next frame, never a jump", turned < run(0, 1, ease / 2, frame), `{turned}`)
			local long = Hud.Approach(0, 1, 5, ease)
			t.Check("a long frame never overshoots", long > 0.99 and long <= 1, `{long}`)
			t.Equal("nothing in no time", Hud.Approach(0.4, 1, 0, ease), 0.4)
			t.Check("the eye a whole tap target (Theme.Size.Tap, 52)", HudConfig.Spectate.Size >= 52)
		end,
	},
}
