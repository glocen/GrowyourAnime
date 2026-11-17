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
local UIKit = require(Shared.Config.UIKit)
local Shards = require(Shared.Definitions.Shards)

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
			t.Equal("a type against itself has no arrow", Hud.Arrow("Red", "Red"), "")
			t.Equal("an unknown type has no arrow", Hud.Arrow(nil, "Red"), "")
			t.Equal("nor an empty one", Hud.Arrow("Blue", ""), "")
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
		Name = "Hud: the signature's ring",
		Run = function(t: any)
			t.Equal("empty the moment it fires", Hud.Ready(20, 10, 10), 0)
			t.Equal("half way", Hud.Ready(20, 10, 15), 0.5)
			t.Equal("full once ready", Hud.Ready(20, 10, 20), 1)
			t.Equal("and stays full", Hud.Ready(20, 10, 99), 1)
			t.Equal("no cooldown, always full", Hud.Ready(20, 0, 10), 1)
		end,
	},
	{
		Name = "Hud: the shards' hint shows only at the base, and names the one shard or counts them",
		Run = function(t: any)
			-- The director, 2026-11-15: "should only show when we are at the base".
			t.Equal("home, one shard alone: its name", Hud.ShardHint(1, 1, "Named Watt", true), "Named Watt: into the Breaker")
			t.Equal("home, two of one kind: counted", Hud.ShardHint(1, 2, "Named Watt", true), "2 shards: into the Breaker")
			t.Equal("home, several kinds: counted", Hud.ShardHint(3, 65, nil, true), "65 shards: into the Breaker")
			t.Equal("home, one with no name known: counted", Hud.ShardHint(1, 1, nil, true), "1 shards: into the Breaker")
			t.Equal("home, an empty bag: no hint", Hud.ShardHint(0, 0, nil, true), nil)
			t.Equal("in the grounds, never", Hud.ShardHint(3, 65, nil, false), nil)
			t.Equal("in the grounds, one shard: never", Hud.ShardHint(1, 1, "Named Watt", false), nil)
		end,
	},
	{
		Name = "Hud: the next step names one target at every step of the first session (TR24's fix 1)",
		Run = function(t: any)
			local function state(over: { [string]: any }): Hud.StepState
				local s: { [string]: any } = {
					Home = true, Chosen = true, Ready = 0, Breaking = 0, Shards = 0, Kinds = 0, First = nil,
					Idle = nil, Bay = nil, Worked = false, Won = false, Keeper = nil, Ground = "Lantern Row",
				}
				for key, value in over do
					s[key] = value
				end
				return s :: any
			end
			local function step(over: { [string]: any }): (string?, string?, number?)
				local found = Hud.NextStep(state(over))
				if found == nil then
					return nil, nil, nil
				end
				return found.Line, found.Target, found.Bay
			end
			local line, target = step({ Chosen = false })
			t.Check("arrival: the starter shards", line == "Choose your first shard" and target == "Starters", `{line} {target}`)
			line, target = step({ Breaking = 1 })
			t.Check("the starter breaking: the Breaker", line == "Breaking: it opens at the Breaker" and target == "Breaker", `{line} {target}`)
			line, target = step({ Ready = 1, Breaking = 1 })
			t.Check("one ready: open it at the Breaker", line == "Ready: open it at the Breaker" and target == "Breaker", `{line} {target}`)
			line = step({ Ready = 3 })
			t.Equal("three ready: counted", line, "3 ready: open them at the Breaker")
			line, target = step({})
			t.Check("after the reveal: the Door to the first ground", line == "Through the Door: Lantern Row" and target == "Door", `{line} {target}`)
			line, target = step({ Shards = 1, Kinds = 1, First = "Watt's shard" })
			t.Check("home with a shard: the shards' hint, at the Breaker", line == "Watt's shard: into the Breaker" and target == "Breaker", `{line} {target}`)
			local bay
			line, target, bay = step({ Idle = "Watt", Bay = 2 })
			t.Check("a Voidkin idle and a bay empty: that bay", line == "Watt: to work in Bay 2" and target == "Bay" and bay == 2, `{line} {target} {bay}`)
			t.Equal("an idle Voidkin with no empty bay: on to the Door", (step({ Idle = "Watt" })), "Through the Door: Lantern Row")
			t.Equal("the order: the choice first", (step({ Chosen = false, Ready = 1, Shards = 2, Kinds = 1 })), "Choose your first shard")
			t.Equal("then what's ready", (step({ Ready = 1, Shards = 2, Kinds = 1, Idle = "Watt", Bay = 2 })), "Ready: open it at the Breaker")
			t.Equal("then the bag", (step({ Shards = 2, Kinds = 1, Idle = "Watt", Bay = 2 })), "2 shards: into the Breaker")
			t.Equal("then the bay", (step({ Idle = "Watt", Bay = 2, Breaking = 1 })), "Watt: to work in Bay 2")
			-- Out in a ground: nothing but the keeper's gate, once a bay works and until a keeper falls.
			t.Equal("in the ground before a bay works: nothing", (step({ Home = false, Keeper = "the Lamplighter" })), nil)
			line, target = step({ Home = false, Worked = true, Keeper = "the Lamplighter" })
			t.Check("in the ground once a bay works: the keeper's gate", line == "The Lamplighter waits at the gate" and target == "Gate", `{line} {target}`)
			t.Equal("in the ground with shards: never the shards' hint", (step({ Home = false, Shards = 4, Kinds = 1 })), nil)
			t.Equal("in a ground with no keeper: nothing", (step({ Home = false, Worked = true })), nil)
			-- After the first keeper falls the guide is quiet, but what's ready, the bag and an empty bay still speak at home.
			t.Equal("won, out in a ground: nothing", (step({ Home = false, Worked = true, Won = true, Keeper = "the Lamplighter" })), nil)
			t.Equal("won, home, nothing to do: nothing", (step({ Won = true })), nil)
			t.Equal("won, home, a shard breaking: nothing", (step({ Won = true, Breaking = 2 })), nil)
			t.Equal("won, home, one ready: still said", (step({ Won = true, Ready = 1 })), "Ready: open it at the Breaker")
			t.Equal("won, home, the bag: still said", (step({ Won = true, Shards = 5, Kinds = 2 })), "5 shards: into the Breaker")
			t.Equal("won, home, an empty bay: still said", (step({ Won = true, Idle = "Watt", Bay = 1 })), "Watt: to work in Bay 1")
		end,
	},
	{
		Name = "Hud: the readout's front: its turn, a stop's place along it, and the carry for each share",
		Run = function(t: any)
			-- AR12 (Config.Hud.Readout): one gradient over the well's square, its line rising `lean` for each point right.
			local flat, long = Hud.FrontTurn(50, 0)
			t.Check("no lean: top to foot, as long as the well is high", near(flat, 90) and math.abs(long - 50) < 1e-9, `{flat} {long}`)
			local config = HudConfig.Readout
			local side = config.Well[4] - config.Well[2]
			local turn, length = Hud.FrontTurn(side, config.Lean)
			t.Check("leaning, it turns short of 90 degrees", turn < 90 and turn > 80, tostring(turn))
			t.Check("and the gradient is longer than the well", length > side and length < side * 1.2, tostring(length))
			t.Check("the lean is the turn's own", near(math.tan(math.rad(90 - turn)), config.Lean))
			t.Equal("the line itself is the gradient's middle", Hud.FrontAt(0, length), 0.5)
			t.Check("a point below it, further along", near(Hud.FrontAt(5, 50), 0.6))
			t.Check("a point above it, before", near(Hud.FrontAt(-5, 50), 0.4))
			t.Equal("past the foot, it holds the end", Hud.FrontAt(1000, length), 1)
			t.Equal("past the top, the start", Hud.FrontAt(-1000, length), 0)
			local last = -math.huge
			for _, stop in config.Front do
				t.Check(`the stop {stop.Below} below stands after the one before`, stop.Below > last)
				last = stop.Below
			end
			t.Equal("half full: no carry", Hud.FrontOffset(0.5, config.Travel), 0)
			t.Check("empty: carried to the foot", near(Hud.FrontOffset(0, config.Travel), config.Travel))
			t.Check("full: to the top", near(Hud.FrontOffset(1, config.Travel), -config.Travel))
			t.Check("a quarter: half way to the foot", near(Hud.FrontOffset(0.25, 0.8), 0.4))
			t.Check("past full holds full", near(Hud.FrontOffset(7, 0.8), -0.8))
			t.Check("not a number reads empty", near(Hud.FrontOffset(0 / 0, 0.8), 0.8))
			-- the carry turned with the gradient, since Roblox moves it along its element's own axes
			local x, y = Hud.FrontShift(0.5, 90)
			t.Check("top to foot: the carry goes straight down", near(x, 0) and near(y, 0.5), `{x} {y}`)
			x, y = Hud.FrontShift(0.5, 0)
			t.Check("left to right: straight across", near(x, 0.5) and near(y, 0), `{x} {y}`)
			x, y = Hud.FrontShift(Hud.FrontOffset(0, config.Travel), turn)
			t.Check("empty, leaning: down and a little right, by the whole travel", y > 0 and x > 0 and x < y and near(math.sqrt(x * x + y * y), config.Travel), `{x} {y}`)
			x, y = Hud.FrontShift(Hud.FrontOffset(1, config.Travel), turn)
			t.Check("full: up and a little left", y < 0 and x < 0, `{x} {y}`)
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
	{
		Name = "HUD: TR10, a drop's chance as the loot card writes it, never rounded up",
		Run = function(t: any)
			t.Equal("certain", Hud.Chance(1), "100%")
			t.Equal("the keeper's shard", Hud.Chance(0.36), "36%")
			t.Equal("the elite's shard, cut", Hud.Chance(0.144), "14%")
			t.Equal("short of certain never reads 100%", Hud.Chance(0.999), "99%")
			t.Equal("under 10, a tenth", Hud.Chance(0.036), "3.6%")
			t.Equal("a whole one under 10", Hud.Chance(0.04), "4%")
			t.Equal("a chance there is never reads 0%", Hud.Chance(0.0001), "<0.1%")
			t.Equal("none", Hud.Chance(0), "0%")
			t.Equal("not a number", Hud.Chance(0 / 0), "0%")
		end,
	},
	{
		Name = "Hud: AR12, a shard wears its grade's picture, the small one under the large's least size, Standard's for a grade with none",
		Run = function(t: any)
			local large = HudConfig.ShardArt.Large
			t.Equal("a chamber's window", Hud.ShardPicture("Prismatic", 96, large), "ShardPrismatic")
			t.Equal("at the large's least", Hud.ShardPicture("Enriched", large, large), "ShardEnriched")
			t.Equal("a hair under it", Hud.ShardPicture("Enriched", large - 0.5, large), "ShardEnrichedSmall")
			t.Equal("a chip", Hud.ShardPicture("Standard", HudConfig.ShardArt.Chip, large), "ShardStandardSmall")
			t.Equal("a Named shard wears Standard's", Hud.ShardPicture("Named", 96, large), "ShardStandard")
			t.Equal("a Starter's small", Hud.ShardPicture("Starter", 26, large), "ShardStandardSmall")
			for _, row in Shards.List do
				for _, points in { 96, HudConfig.ShardArt.Chip } do
					local name = Hud.ShardPicture(row.Grade, points, large)
					t.Check(`{row.Id} at {points} points has its picture in the kit`, UIKit.Images[name] ~= nil, name)
				end
			end
		end,
	},
	{
		Name = "Hud: TR41 (d), a shard's festival tag hangs where Modulo's json works it out at five sides, a third of the crystal at 50 and a quarter at 96; a smaller picture takes its mark on a disc, never under its least",
		Run = function(t: any)
			local look = HudConfig.ShardTag
			local large = HudConfig.ShardArt.Large
			local image = look.Grounds.lanternrow.Tag.Points
			-- build/handoff/UI/shards/tag/shard_tag.json, "boxes": the image's left and top from the picture's middle, its
			-- width and its height, worked out by Modulo for five sides (two decimals).
			local boxes: { [number]: { number } } = {
				[50] = { -0.66, -11.42, 11.98, 17.97 },
				[60] = { -0.79, -13.7, 14.38, 21.56 },
				[72] = { -0.85, -16.43, 17.09, 25.63 },
				[96] = { 0.22, -21.73, 20.62, 30.94 },
				[134] = { 3.25, -29.94, 24.08, 36.12 },
			}
			for side, want in boxes do
				local box = Hud.ShardTag(side, look, large, image)
				local off = math.max(math.abs(box.X - want[1]), math.abs(box.Y - want[2]), math.abs(box.W - want[3]), math.abs(box.H - want[4]))
				t.Check(`at {side}, the tag where the json hangs it`, box.Kind == "Tag" and off < 0.011, string.format("%s %.2f %.2f %.2f %.2f", box.Kind, box.X, box.Y, box.W, box.H))
			end
			local function plaque(side: number): number
				return Hud.ShardTag(side, look, large, image).H / image.Y * look.Tag.Plaque
			end
			t.Check("a third of the side up to the third's end", near(plaque(60) / 60, look.Tag.Third.Of))
			t.Check("a quarter's share from the quarter's start", near(plaque(200) / 200, look.Tag.Quarter.Of))
			t.Check("growing with the side between, never stepping", plaque(look.Tag.Third.Upto + 1) > plaque(look.Tag.Third.Upto) and plaque(look.Tag.Quarter.From) > plaque(look.Tag.Quarter.From - 1))
			-- Under the large picture's least, its mark on a disc at the crystal's foot, on the right.
			local small = Hud.ShardTag(large - 0.5, look, large, image)
			t.Check("a hair under the large's least, the mark", small.Kind == "Mark" and small.W == small.H)
			local cell = 64 * HudConfig.ShardArt.Cell
			local disc = Hud.ShardTag(cell, look, large, image)
			t.Check("a bag cell's picture: the disc its share of the side", disc.Kind == "Mark" and near(disc.W, math.max(cell * look.Mark.Side, look.Mark.Least)), string.format("%.2f", disc.W))
			t.Check("its middle at the crystal's foot, on the right", near(disc.X + disc.W / 2, look.Mark.Middle.X * cell) and near(disc.Y + disc.H / 2, look.Mark.Middle.Y * cell) and look.Mark.Middle.X > 0 and look.Mark.Middle.Y > 0)
			t.Equal("never under its least", Hud.ShardTag(30, look, large, image).W, look.Mark.Least)
			local mirrored = Hud.ShardTag(cell, look, large, image, true)
			t.Check("in a bag cell, at the crystal's left foot, mirrored, its size and height kept", near(mirrored.X + mirrored.W / 2, -(disc.X + disc.W / 2)) and near(mirrored.Y, disc.Y) and near(mirrored.W, disc.W))
			local big = Hud.ShardTag(96, look, large, image, true)
			t.Check("a tag is never mirrored", big.Kind == "Tag" and near(big.X, Hud.ShardTag(96, look, large, image).X))
			-- Every ground's shard that's in the game has its tag and mark (a ground with none shows no tag, as yet).
			for _, row in Shards.List do
				local ground = look.Grounds[row.Ground]
				t.Check(`{row.Id}'s ground has its tag and its mark`, ground ~= nil and ground.Tag.Points == image and ground.Mark.Points.X == ground.Mark.Points.Y, row.Ground)
			end
		end,
	},
	{
		Name = "Hud: a Voidkin goes to work in the first empty bay, never the lead, never a worker twice, and says why not",
		Run = function(t: any)
			-- TR17: Send to work on one Voidkin's screen.
			local bays = { { Worker = "k1", Level = 1 }, { Worker = "", Level = 1 }, { Worker = "", Level = 1 } }
			local why, bay = Hud.WorkReason("", bays)
			t.Check("the first empty bay", why == nil and bay == 2, `{why} {bay}`)
			t.Equal("the lead fights", (Hud.WorkReason("Lead", bays)), "Not while leading")
			t.Equal("a worker is at work", (Hud.WorkReason("Bay 1", bays)), "At work")
			t.Equal("every bay busy", (Hud.WorkReason("", { { Worker = "k1", Level = 1 } })), "Every bay is busy")
			t.Equal("no bay yet", (Hud.WorkReason("", {})), "No bay open yet")
		end,
	},
	{
		Name = "Hud: the level-up's notice slides in, its number falls onto its block and lands with a flash and a knock, one sheen crosses, it holds and leaves (TR41 (c))",
		Run = function(t: any)
			-- AR12's take B as Modulo's json gives its motion (Config.Hud.LevelNotice.Motion): the levers, in order.
			local m = HudConfig.LevelNotice.Motion
			local wide, foot = 160, 140
			local land = m.In + m.Fall
			local function at(age: number): Hud.Notice
				return Hud.Notice(age, m, wide, foot)
			end
			t.Equal("it starts wholly off the screen's left", at(0).Away, 1)
			t.Check("eased out: most of the way in by half its slide", at(m.In / 2).Away < 0.2, tostring(at(m.In / 2).Away))
			t.Equal("at its place when the slide ends", at(m.In).Away, 0)
			t.Check("its block empty while it slides", at(m.In * 0.9).Number == 0 and at(m.In * 0.9).Size == 0)
			t.Check("the number starts large", near(at(m.In).Size, m.From))
			t.Check("and solid within the fall's first third", at(m.In + m.Fall / 3 + 1e-6).Number >= 1 and at(m.In + m.Fall / 6).Number < 1)
			t.Check("it lands squashed", near(at(land).Size, m.Squash) and m.Squash < 1)
			t.Check("and settles to its own size", near(at(land + m.Settle).Size, 1) and near(at(land + 5).Size, 1))
			t.Check("the flash at its strongest as it lands", near(at(land).Flash, m.Flash.Strength))
			t.Check("and gone after its time", at(land + m.Flash.Seconds).Flash == 0)
			t.Check("the knock as it lands, back after its time", near(at(land).Knock, m.Knock.Points) and at(land + m.Knock.Seconds).Knock == 0)
			t.Check("no flash or knock before it lands", at(land - 0.01).Flash == 0 and at(land - 0.01).Knock == 0)
			local start = land + m.Sheen.After
			t.Check("no sheen before its moment", at(start - 0.01).Sheen == nil)
			t.Check("the sheen starts left of the plate, unseen", near(at(start).Sheen :: number, -m.Sheen.Reach) and at(start).Shine == 0)
			t.Check("it ends past the far end", near(at(start + m.Sheen.Seconds).Sheen :: number, wide + m.Sheen.Reach))
			local middle = at(start + m.Sheen.Seconds / 2)
			t.Check("whole across the plate's middle", near(middle.Sheen :: number, wide / 2) and middle.Shine == 1)
			t.Check("never seen past the leaning end's foot", at(start + m.Sheen.Seconds * 0.95).Shine == 0)
			t.Check("held at its place", at(m.In + m.Hold).Away == 0 and not at(m.In + m.Hold).Done)
			t.Check("eased in as it leaves: still near at half its exit", at(m.In + m.Hold + m.Out / 2).Away < 0.2)
			t.Check("gone the way it came", at(m.In + m.Hold + m.Out).Away == 1 and at(m.In + m.Hold + m.Out).Done)
			t.Check("whole all along without reduced motion", at(0).Solid == 1 and at(m.In + m.Hold).Solid == 1)
			-- Reduced motion: it fades in at its place, the number set, and out; no fall, flash, knock or sheen.
			local still = Hud.Notice(land, m, wide, foot, true)
			t.Check("reduced motion: at its place, the number set", still.Away == 0 and still.Size == 1 and still.Number == 1)
			t.Check("no flash, knock or sheen", still.Flash == 0 and still.Knock == 0 and still.Sheen == nil)
			t.Check("it fades in", Hud.Notice(0, m, wide, foot, true).Solid == 0 and Hud.Notice(m.Fade, m, wide, foot, true).Solid == 1)
			t.Check("and out", Hud.Notice(m.In + m.Hold + m.Fade, m, wide, foot, true).Done and Hud.Notice(m.In + m.Hold + m.Fade, m, wide, foot, true).Solid == 0)
		end,
	},
	{
		Name = "Hud: TR41 (e), the battery mark's cells follow its charge by thirds: full only when full, empty only when empty, never disagreeing with the reading beside it",
		Run = function(t: any)
			t.Check("empty: no cell", Hud.BatteryCells(0, 60) == 0)
			t.Check("a sliver: one cell", Hud.BatteryCells(0.01, 60) == 1)
			t.Check("a third: one cell", Hud.BatteryCells(20, 60) == 1)
			t.Check("past a third: two", Hud.BatteryCells(20.5, 60) == 2)
			t.Check("all but full: two, never full before it is", Hud.BatteryCells(59.99, 60) == 2)
			t.Check("full: all three", Hud.BatteryCells(60, 60) == 3 and Hud.BatteryCells(400, 400) == 3)
			t.Check("no battery: no cell", Hud.BatteryCells(5, 0) == 0)
			local cells = HudConfig.Power.Cells
			local pixels = HudConfig.Power.Images.Battery.Pixels
			local third = cells.At.X + cells.Every * 2
			t.Check("the three cells inside the image", third + cells.Size.X <= pixels.X and cells.At.Y + cells.Size.Y <= pixels.Y, `{third}`)
			-- The image's inside is dark from x 23 to 92, y 44 to 84, and its empty slot from x 69 (measured on Battery.png).
			local inside, dark = cells.Inside, cells.Dark
			t.Check("the cells inside the battery's inside", cells.At.X >= inside.Left and cells.At.Y >= inside.Top and cells.At.Y + cells.Size.Y <= inside.Foot)
			-- The third is cut at the inside's right (UI.BatteryMark): a pixel at most, so it still reads as a cell.
			t.Check("the third cell cut by a pixel at most", inside.Right - third >= cells.Size.X - 1, `{inside.Right - third} of {cells.Size.X}`)
			-- Drawn small, an image blends a pixel with its neighbours up to about 8 away (a 128 px image at 16 points):
			-- the dark patch keeps that far from the slot's edges, the second cell's gold at 68 and the rim at 93.
			local far = 8
			t.Check("the dark patch keeps clear of any gold, as far as an image drawn small blends", dark.From.X - far >= 69 and dark.From.X + dark.Size.X + far <= 93 and dark.From.Y - far >= inside.Top and dark.From.Y + dark.Size.Y + far <= inside.Foot, `{dark.From}`)
		end,
	},
	{
		Name = "Hud: AR29, B, the page rail's rows: a row each where they fit, closing up evenly to the least where they don't, every page in sight, and the pitch the same whichever page is chosen",
		Run = function(t: any)
			local rail = HudConfig.Voidkin.Chrome.Rail
			local one, two = Hud.RailNeed(1, rail.Tab.Word, rail.Drawn, rail.Tab), Hud.RailNeed(2, rail.Tab.Word, rail.Drawn, rail.Tab)
			t.Check("a one-line word's tab fits a row at its authored size", one <= rail.Row, string.format("%.2f of %d", one, rail.Row))
			t.Check("two lines need more", two > rail.Row)
			-- The least a row closes to is 30.6 points at the scale's floor (research's call of 20:06; Theme.Scale.Floor 0.85).
			t.Check("the least row is 30.6 points at the floor", math.abs(rail.Least * 0.85 - 30.6) < 0.01)
			-- The smallest phone: a room of 292 authored (248 points), the word at the legible floor (14 pixels at 0.85: 17),
			-- seven pages, War Emblems' two lines chosen: every page whole, no scroll.
			local word = math.max(rail.Tab.Word, math.ceil(14 / 0.85))
			local phoneOne, phoneTwo = Hud.RailNeed(1, word, rail.Drawn, rail.Tab), Hud.RailNeed(2, word, rail.Drawn, rail.Tab)
			local phonePitch, phoneWhole = Hud.RailRows(292, 7, rail.Row, rail.Least, phoneTwo, phoneTwo)
			t.Check("the smallest phone: seven whole with War Emblems chosen", phoneWhole, string.format("%.2f", phonePitch))
			t.Check("and with a one-line page chosen", select(2, Hud.RailRows(292, 7, rail.Row, rail.Least, phoneTwo, phoneOne)))
			local pitch, whole = Hud.RailRows(300, 4, rail.Row, rail.Least, one, one)
			t.Check("four pages in a tall room: a row each, whole", pitch == rail.Row and whole, `{pitch}`)
			pitch, whole = Hud.RailRows(4 * rail.Row + (two - rail.Row), 4, rail.Row, rail.Least, two, two)
			t.Check("room for the rows and the long tab's extra: still a row each", pitch == rail.Row and whole, `{pitch}`)
			local room = 7 * 44 + 20
			local closed, alsoWhole = Hud.RailRows(room, 7, rail.Row, rail.Least, two, one)
			t.Check("seven in a short room close up evenly, keeping room for the long tab", math.abs(closed - (room - two) / 6) < 1e-6 and alsoWhole, `{closed}`)
			local withLong, longWhole = Hud.RailRows(room, 7, rail.Row, rail.Least, two, two)
			t.Check("the pitch is the same whichever page is chosen, and whole with the long one chosen", withLong == closed and longWhole)
			local floor, notWhole = Hud.RailRows(200, 7, rail.Row, rail.Least, two, two)
			t.Check("never under the least: a room too short scrolls", floor == rail.Least and not notWhole, `{floor}`)
			local alone, aloneWhole = Hud.RailRows(30, 1, rail.Row, rail.Least, one, one)
			t.Check("one page: its row, scrolling only where its tab is taller than the room", alone == rail.Row and not aloneWhole)
			-- Research's seed for the idle icons: the seam's soft text, never under 4.5:1 on the rail's ground (the cover) or
			-- the panel, and dimmer than the chosen page's, so the chosen page is the brightest thing on the rail.
			local seam = UIKit.Palettes.Seam
			local ground, panel = seam.Backing :: Color3, (seam.Panel :: { Color3 })[1]
			local idle = Hud.Contrast(rail.Idle, ground)
			t.Check("an idle icon 4.5:1 or more on the rail's ground", idle >= 4.5, string.format("%.1f", idle))
			t.Check("and on the panel", Hud.Contrast(rail.Idle, panel) >= 4.5, string.format("%.1f", Hud.Contrast(rail.Idle, panel)))
			t.Check("dimmer than the chosen page's text", Hud.Contrast(seam.Text :: Color3, ground) > idle)
			t.Check("contrast: white on black is 21:1", math.abs(Hud.Contrast(Color3.new(1, 1, 1), Color3.new(0, 0, 0)) - 21) < 1e-6)
		end,
	},
	{
		Name = "Hud: the Stars page's copies, never a count past its total read as N of M",
		Run = function(t: any)
			t.Equal("short of the next star", Hud.Copies(3, 5), "3 of 5 copies for the next")
			t.Equal("exactly enough", Hud.Copies(5, 5), "5 of 5 copies for the next")
			t.Equal("past it: the count and the need apart", Hud.Copies(48, 1), "48 copies, 1 needed for the next star")
			t.Equal("in thousands", Hud.Copies(1200, 40), "1,200 copies, 40 needed for the next star")
		end,
	},
}
