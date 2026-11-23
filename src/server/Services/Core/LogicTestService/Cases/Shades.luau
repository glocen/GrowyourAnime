--!strict
-- Logic cases (pure): AR52's two Shades, so each stretch of Lantern Row asks its own question (docs/asset-requests.md,
-- AR52). The Guard's raised shield lets Keep of a hit through until a heavy hit or a signature breaks it (Rules.Fight.
-- Guarded, Breaks); the Dasher's line takes a centre on it and none off it, and its lunge stops short of one standing on
-- it (Rules.Mark.OnLine, Covers, Short); a pack mixes its others evenly through its ring (Rules.Fight.PackDefs); the
-- stretches' packs are research's, and a Guard's or a Dasher's fall counts to its stretch's quota. Runs in Studio
-- (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local World = require(Shared.Config.World)
local Animations = require(Shared.Config.Animations)
local Actions = require(Shared.Definitions.Actions)
local Enemies = require(Shared.Definitions.Enemies)
local Fight = require(Shared.Rules.Fight)
local Mark = require(Shared.Rules.Mark)
local Hit = require(Shared.Rules.Hit)
local Stats = require(Shared.Rules.Stats)
local Stages = require(Shared.Rules.Stages)

local EPS = 1e-6

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or EPS)
end

return {
	{
		Name = "Shades: AR52's Guard and Dasher are Ordinary Shades on the Shade's rig, each in its own mask and type, its signature tried before its swing",
		Run = function(t: any)
			local wants: { [string]: { Mask: string, Type: string, Signature: string } } = {
				guard = { Mask = "Guard", Type = "Green", Signature = "GuardRaise" },
				dasher = { Mask = "Dasher", Type = "Orange", Signature = "DasherLunge" },
			}
			for id, want in wants do
				local row = Enemies.ById[id]
				t.Check(`{id}: a row`, row ~= nil)
				if row == nil then
					continue
				end
				t.Check(`{id}: an Ordinary Shade on the Shade's rig`, row.Kind == "Ordinary" and row.Rig == "Shade")
				t.Equal(`{id}: its mask`, row.Mask, want.Mask)
				t.Equal(`{id}: its type`, row.Type, want.Type)
				t.Equal(`{id}: its signature`, row.Signature, want.Signature)
				t.Check(`{id}: its swing between, the Brawler's`, row.Action == Enemies.ById.brawler.Action)
				t.Check(`{id}: its own first, sooner than a keeper's`, row.First ~= nil and row.First < Combat.Keeper.First)
				local action = Actions.ById[want.Signature]
				t.Check(`{id}: its signature is an action with a clip whose fades are known`, action ~= nil and action.Clip ~= nil
					and (Animations.Fades :: any)[(Animations.Roles :: any)[action.Clip]] ~= nil)
				local block = Stats.Enemy(id, 3)
				local brawler = Stats.Enemy("brawler", 3)
				t.Check(`{id}: a Brawler's numbers at its level (its Kind's)`, block.Health == brawler.Health and block.Attack == brawler.Attack)
			end
		end,
	},
	{
		Name = "Shades: the Guard's raise holds its shield 2.0 s from Raise to Drop and opens 2.5 s before the next, research's seeds",
		Run = function(t: any)
			local raise = Actions.ById.GuardRaise
			local guard = raise.Guard
			t.Check("its Raise beat raises the shield to its Drop beat", guard ~= nil and guard.From == "Raise" and guard.To == "Drop" and raise.Beats.Drop ~= nil)
			t.Check("held 2.0 s", near(raise.Beats.Drop - raise.Beats.Raise, 2.0), `{raise.Beats.Drop - raise.Beats.Raise}`)
			t.Check("up in 0.3 s", near(raise.Beats.Raise, 0.3))
			t.Check("open 2.5 s from Drop to the next raise", near(raise.Cooldown - raise.Beats.Drop, 2.5), `{raise.Cooldown - raise.Beats.Drop}`)
			t.Check("it lands on nobody", next(raise.Hits) == nil)
			t.Check("its stagger is research's 1.0 s, its keep 20%", near(Combat.Guard.Stagger, 1.0) and near(Combat.Guard.Keep, 0.2))
		end,
	},
	{
		Name = "Shades: a raised shield lets Keep of a hit through and its fall lets all of it; a heavy hit or a signature breaks it",
		Run = function(t: any)
			local guard = { Keep = 0.2, Until = 10 }
			t.Equal("raised: its keep", Fight.Guarded(guard, 9.9), 0.2)
			t.Equal("on its Drop: all of it", Fight.Guarded(guard, 10), 1)
			t.Equal("none raised: all of it", Fight.Guarded(nil, 1), 1)
			t.Equal("a keep past 1 is all of it", Fight.Guarded({ Keep = 3, Until = 10 }, 1), 1)
			t.Check("a heavy hit breaks it", Fight.Breaks(true, false))
			t.Check("a signature's hit breaks it", Fight.Breaks(false, true))
			t.Check("an ordinary hit glances off", not Fight.Breaks(false, false))
			-- its cut stands apart from the Reduction bucket: a shielded body behind it still takes a fifth of what it would
			local a = Stats.Empty(1)
			a.Attack = 100
			local d = Stats.Empty(1)
			local NONE: Hit.Rolls = { Dodge = 0.999999, Critical = 0.999999, Block = 0.999999 }
			local capped = Hit.Resolve(a, d, 1, NONE, { Reduction = 0.95 })
			local keep = Fight.Guarded(guard, 5)
			t.Check("past the Reduction ceiling, the shield still cuts", near(capped.Total * keep, capped.Total * 0.2), `{capped.Total}`)
		end,
	},
	{
		Name = "Shades: the Dasher's line takes a centre on it and none off it, past its end or behind its start",
		Run = function(t: any)
			-- from (0, 0) along +X, 10 long, 2 either side
			t.Check("on its middle", Mark.OnLine(0, 0, 1, 0, 10, 2, 5, 0))
			t.Check("on its edge", Mark.OnLine(0, 0, 1, 0, 10, 2, 5, 2))
			t.Check("just off its edge", not Mark.OnLine(0, 0, 1, 0, 10, 2, 5, 2.01))
			t.Check("round its far end, within its half", Mark.OnLine(0, 0, 1, 0, 10, 2, 11.5, 0))
			t.Check("past its far end", not Mark.OnLine(0, 0, 1, 0, 10, 2, 12.01, 0))
			t.Check("behind its start, past its half", not Mark.OnLine(0, 0, 1, 0, 10, 2, -2.01, 0))
			local diagonal = math.sqrt(0.5)
			t.Check("any way it runs", Mark.OnLine(1, 1, diagonal, diagonal, 10, 2, 6, 6) and not Mark.OnLine(1, 1, diagonal, diagonal, 10, 2, 6, 1))
			-- Covers: a line when it has a Length, the keeper's ring when not
			local line: Mark.Shape = { X = 0, Z = 0, Radius = 2, Length = 10, DirX = 1, DirZ = 0 }
			local ring: Mark.Shape = { X = 0, Z = 0, Radius = 2 }
			t.Check("a line's cover is its line", Mark.Covers(line, 8, 1) and not Mark.Covers(line, 0, 3))
			t.Check("a ring's is its ring", Mark.Covers(ring, 1, 1) and not Mark.Covers(ring, 8, 1))
		end,
	},
	{
		Name = "Shades: the Dasher's lunge runs its whole Most through whoever stands on its line, and its first waits for the lead to stand in its fight",
		Run = function(t: any)
			local lunge = Actions.ById.DasherLunge
			local move = if lunge.Moves then lunge.Moves.Lunge else nil
			-- Along: its Most in full, never short of a fighter (they pass through each other), so it ends with its back to them
			t.Check("down its line, not at its target", move ~= nil and move.Along == true and move.Gap == 0)
			t.Check("its line reaches past where it ends", Combat.Dasher.Line.Past > 0)
			-- First: a lead walking in circles to its place and would step off a line put down at once (the trace, 2026-11-23)
			local dasher, guard = Enemies.ById.dasher, Enemies.ById.guard
			t.Check("the Dasher's first lunge waits a second or more", dasher.First ~= nil and dasher.First >= 1, tostring(dasher.First))
			t.Equal("the Guard raises at once", guard.First, 0)
		end,
	},
	{
		Name = "Shades: the Dasher's lunge is research's seeds: a 1.0 s tell from its start, 0.25 s down 12 studs, 0.8 s with its back open",
		Run = function(t: any)
			local lunge = Actions.ById.DasherLunge
			local beats = lunge.Beats
			local move = if lunge.Moves then lunge.Moves.Lunge else nil
			t.Check("its line opens on its Aim, before the lunge", lunge.Aim == "Line" and beats.Line < beats.Lunge)
			t.Check("it goes 1.0 s in", near(beats.Lunge, 1.0))
			t.Check("down its line, 12 studs in 0.25 s", move ~= nil and move.Along == true and move.Most == 12 and near(move.Seconds, 0.25) and near(beats.Land - beats.Lunge, 0.25))
			t.Check("its back open 0.8 s", near(beats.Close - beats.Land, 0.8))
			local hit = lunge.Hits.Land
			t.Check("it lands on its line at Land", hit ~= nil and hit.Mark == true and hit.Line == true)
			-- a hit worth its length at the swing's rate: a Dasher that lands every lunge deals what a Brawler does
			local swipe = Actions.ById.ShadeSwipe
			t.Check("its length's worth of the swing's rate", near(hit.Coefficient / lunge.Length, swipe.Hits.Hit.Coefficient / swipe.Length, 1e-4), `{hit.Coefficient / lunge.Length} against {swipe.Hits.Hit.Coefficient / swipe.Length}`)
			t.Check("it starts where its line reaches past its target", lunge.Range < (move :: any).Most + Combat.Dasher.Line.Past)
		end,
	},
	{
		Name = "Shades: a pack mixes its others evenly through its ring, never side by side, and a Count past the pack's is the whole pack",
		Run = function(t: any)
			local four = Fight.PackDefs("brawler", 4, "guard", 2)
			t.Equal("4 with 2: four of them", #four, 4)
			local guards = 0
			for _, def in four do
				guards += if def == "guard" then 1 else 0
			end
			t.Equal("two of them Guards", guards, 2)
			-- on a ring of four, places 1 and 3 face across it, 2 and 4 beside each
			t.Check("the two stand across the ring from each other", (four[1] == "guard" and four[3] == "guard") or (four[2] == "guard" and four[4] == "guard"), table.concat(four, ","))
			local three = Fight.PackDefs("brawler", 3, "dasher", 1)
			t.Check("3 with 1: one Dasher", #three == 3 and table.find(three, "dasher") ~= nil and #string.split(table.concat(three, ","), "dasher") == 2)
			local none = Fight.PackDefs("brawler", 3, nil, nil)
			t.Check("no others: all its own", none[1] == "brawler" and none[2] == "brawler" and none[3] == "brawler")
			local all = Fight.PackDefs("brawler", 3, "guard", 9)
			t.Check("more others than places: every place", all[1] == "guard" and all[2] == "guard" and all[3] == "guard")
			t.Equal("a count of none: all its own", Fight.PackDefs("brawler", 2, "guard", 0)[1], "brawler")
		end,
	},
	{
		Name = "Shades: Lantern Row's stretches ask their own questions: Brawlers alone, then with Guards, then with Dashers, then the Lamplighter",
		Run = function(t: any)
			local withs: { [number]: { [string]: boolean } } = {}
			for _, stop in World.Row.Stops do
				if stop.Kind == "Pack" then
					t.Equal(`stage {stop.Stage}'s pack: Brawlers at its heart`, stop.Def, "brawler")
					local with = stop.With
					local mix = withs[stop.Stage] or {}
					if with then
						mix[with.Def] = true
						t.Check(`stage {stop.Stage}: its others are an enemy, fewer than the pack`, Enemies.ById[with.Def] ~= nil and with.Count >= 1 and with.Count < (stop.Count or 1))
					end
					withs[stop.Stage] = mix
				end
			end
			t.Check("stage 1: Brawlers alone", withs[1] ~= nil and next(withs[1]) == nil)
			t.Check("stage 2: with Guards", withs[2] ~= nil and withs[2].guard == true and withs[2].dasher == nil)
			t.Check("stage 3: with Dashers", withs[3] ~= nil and withs[3].dasher == true and withs[3].guard == nil)
			local last = World.Row.Stops[#World.Row.Stops]
			t.Check("stage 4: the Lamplighter, Purple", last.Kind == "Keeper" and Enemies.ById[last.Def].Type == "Purple")
			-- a Guard's fall counts to stage 2's quota, a Dasher's to stage 3's, and neither to another's
			local run = { Ground = World.Row.Ground, Difficulty = "Normal", Stage = 2, Kills = 0, Last = false, Done = false } :: any
			Stages.Kill(run, "guard")
			t.Equal("a Guard's fall counts in stage 2", run.Kills, 1)
			Stages.Kill(run, "dasher")
			t.Equal("a Dasher's doesn't", run.Kills, 1)
			run = { Ground = World.Row.Ground, Difficulty = "Normal", Stage = 3, Kills = 0, Last = false, Done = false } :: any
			Stages.Kill(run, "dasher")
			Stages.Kill(run, "brawler")
			t.Equal("a Dasher's and a Brawler's count in stage 3", run.Kills, 2)
		end,
	},
}
