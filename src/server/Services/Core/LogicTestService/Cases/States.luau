--!strict
-- The element states' cases (pure; docs/design.md, "States in a fight"; Rules.Fight's states; Config.Combat.States):
-- which hit leaves which state, a burn that adds nothing and pays out in time, a chill that fills, drains, slows and
-- freezes under the stun's lock, and a sap that cuts a heal while it holds.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Fight = require(Shared.Rules.Fight)
local Combat = require(Shared.Config.Combat)
local UIKit = require(Shared.Config.UIKit)

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-9) * math.max(1, math.abs(b))
end

local states = Combat.States

return {
	{
		Name = "States: an element's hit leaves its state",
		Run = function(t: any)
			for element in UIKit.Elements do
				t.Check(`{element} leaves a state`, states.By[element] ~= nil and (states :: any)[states.By[element]] ~= nil, tostring(states.By[element]))
			end
			t.Equal("Fire, a burn", Fight.StateOf(states, "Fire", 12, "Lead"), "Burn")
			t.Equal("Frost, a chill", Fight.StateOf(states, "Frost", 12, "Lead"), "Chill")
			t.Equal("Storm, a shock", Fight.StateOf(states, "Storm", 12, "Lead"), "Shock")
			t.Equal("Void, a sap", Fight.StateOf(states, "Void", 12, "Lead"), "Sap")
			t.Equal("no element: none", Fight.StateOf(states, "", 12, "Lead"), nil)
			t.Equal("no elemental part (a dodge, no Elemental Attack): none", Fight.StateOf(states, "Fire", 0, "Lead"), nil)
			-- At launch a Shade's Void saps nothing, an elite's included; the keeper's Fire burns (research, 2026-11-23).
			t.Equal("an ordinary Shade's Void: none", Fight.StateOf(states, "Void", 12, "Ordinary"), nil)
			t.Equal("an elite's Void: none", Fight.StateOf(states, "Void", 12, "Elite"), nil)
			t.Equal("the keeper's Fire: a burn", Fight.StateOf(states, "Fire", 12, "Keeper"), "Burn")
		end,
	},
	{
		Name = "States: a burn adds nothing and pays out over its time",
		Run = function(t: any)
			local rule = { Share = 0.5, Seconds = 3, Tick = 0.5 }
			local now, burn = Fight.Burn(rule, nil, 100, 10)
			t.Equal("half lands now", now, 50)
			t.Check("half held, paid by its time", burn ~= nil and burn.Left == 50 and burn.Until == 13 and near(burn.Rate, 50 / 3), if burn then `{burn.Left} by {burn.Until}` else "none")
			local paid, kept = Fight.BurnTick(rule, burn :: Fight.Burn, 10.3)
			t.Check("nothing before its tick", paid == 0 and kept == burn)
			local total = now
			local at = 10
			local left: Fight.Burn? = burn
			while left do
				at += 0.1
				local p, after = Fight.BurnTick(rule, left, at)
				total += p
				left = after
			end
			t.Check("the hit's whole, paid by the first step at or past its time", near(total, 100) and at - 0.1 < 13, `{total} by {at}`)
			-- Another Fire hit before the first is paid: its share joins what's left, over the time again.
			local _, first = Fight.Burn(rule, nil, 100, 0)
			local p1, mid = Fight.BurnTick(rule, first :: Fight.Burn, 1)
			local now2, both = Fight.Burn(rule, mid, 40, 1.2)
			t.Check("a second hit: its half now, its half added to what's left", now2 == 20 and both ~= nil and near(both.Left, 50 - p1 + 20) and both.Until == 4.2, if both then `{both.Left} by {both.Until}` else "none")
			local sum, run = p1, both
			local clock = 1.2
			while run do
				clock += 0.25
				local p, after = Fight.BurnTick(rule, run, clock)
				sum += p
				run = after
			end
			t.Check("both burns' shares paid, no more", near(sum, 70), `{sum}`)
			t.Equal("no share: all of it now", (Fight.Burn({ Share = 0, Seconds = 3 }, nil, 100, 0)), 100)
		end,
	},
	{
		Name = "States: a chill fills, drains, slows and freezes",
		Run = function(t: any)
			local rule = { Hits = 3, Delay = 1.5, Drain = 0.5, Slow = 0.3 }
			local c1, f1 = Fight.Chill(rule, nil, 0, 2, nil, 0)
			t.Check("one Frost hit: a third", c1 ~= nil and near(c1.Fill, 1 / 3) and f1 == 0)
			local c2, f2 = Fight.Chill(rule, c1, 0.5, 2, nil, 0)
			t.Check("two: two thirds", c2 ~= nil and near(c2.Fill, 2 / 3) and f2 == 0)
			t.Check("it slows in proportion", near(Fight.ChillRate(rule, (c2 :: Fight.Chill).Fill), 1 - 0.3 * 2 / 3))
			t.Equal("unchilled, full speed", Fight.ChillRate(rule, 0), 1)
			t.Check("full, Slow off", near(Fight.ChillRate(rule, 1), 0.7))
			local c3, f3 = Fight.Chill(rule, c2, 1, 2, nil, 0)
			t.Check("the third freezes it for its time and empties it", c3 == nil and f3 == 2, `{f3}`)
			local _, half = Fight.Chill(rule, c2, 1, 2, 0.5, 0)
			t.Equal("an elite or a keeper: half the freeze", half, 1)
			-- Locked after a freeze or a stun: no chill builds, so freezes never chain (research, 2026-11-23).
			local held, none = Fight.Chill(rule, nil, 3, 2, nil, 7)
			t.Check("locked: no chill builds, no freeze", held == nil and none == 0)
			local kept, _ = Fight.Chill(rule, c2, 1, 2, nil, 5)
			t.Check("locked: a chill already there stays as it was", kept == c2)
			local after1 = Fight.Chill(rule, nil, 7, 2, nil, 7)
			t.Check("the lock over: it builds again from a third", after1 ~= nil and near(after1.Fill, 1 / 3))
			-- Left alone it drains, from Delay after its last hit.
			t.Check("within its delay, as it was", near(Fight.ChillNow(rule, c2, 0.5 + 1.5), 2 / 3))
			t.Check("then Drain a second", near(Fight.ChillNow(rule, c2, 0.5 + 1.5 + 0.5), 2 / 3 - 0.25))
			t.Equal("and down to none", Fight.ChillNow(rule, c2, 30), 0)
			local after, _ = Fight.Chill(rule, c2, 0.5 + 1.5 + 1, 2, nil, 0)
			t.Check("a hit after a drain adds to what's left", after ~= nil and near(after.Fill, 2 / 3 - 0.5 + 1 / 3))
		end,
	},
	{
		Name = "States: a chill's look steps with its fill, a third each (AR48)",
		Run = function(t: any)
			t.Equal("none: no step", Fight.ChillStep(0, 3), 0)
			t.Equal("a sliver: the first", Fight.ChillStep(0.01, 3), 1)
			t.Equal("one hit's third: the first", Fight.ChillStep(1 / 3, 3), 1)
			t.Equal("just over it: the second", Fight.ChillStep(1 / 3 + 0.01, 3), 2)
			t.Equal("two hits' two thirds: the second", Fight.ChillStep(1 / 3 + 1 / 3, 3), 2)
			t.Equal("above two thirds: the third", Fight.ChillStep(0.8, 3), 3)
			t.Equal("full: the third", Fight.ChillStep(1, 3), 3)
			t.Equal("no steps: none", Fight.ChillStep(0.5, 0), 0)
			-- the game's own: each hit lands on its step's top, and a drain walks it back down
			local rule = Combat.States.Chill
			local steps = #rule.Looks
			local c1 = Fight.Chill(rule, nil, 0, 2, nil, 0)
			local c2 = Fight.Chill(rule, c1, 0.5, 2, nil, 0)
			t.Equal("the game's: a hit, its first look", Fight.ChillStep(Fight.ChillNow(rule, c1, 0), steps), 1)
			t.Equal("two, its second", Fight.ChillStep(Fight.ChillNow(rule, c2, 0.5), steps), 2)
			local back = 0.5 + rule.Delay + (1 / steps) / rule.Drain + 0.05
			t.Equal("drained a share, its first again", Fight.ChillStep(Fight.ChillNow(rule, c2, back), steps), 1)
		end,
	},
	{
		Name = "States: a sap cuts a heal while it holds",
		Run = function(t: any)
			local rule = { Cut = 0.3 }
			t.Check("sapped: Cut less", near(Fight.Sapped(rule, 100, 14, 10), 70))
			t.Equal("lapsed: whole", Fight.Sapped(rule, 100, 14, 14), 100)
			t.Equal("never sapped: whole", Fight.Sapped(rule, 100, nil, 10), 100)
		end,
	},
	{
		Name = "States: the game's numbers",
		Run = function(t: any)
			t.Check("a burn holds back a share, over a time, a tick at a time", states.Burn.Share > 0 and states.Burn.Share < 1 and states.Burn.Seconds > states.Burn.Tick and states.Burn.Tick > 0)
			t.Check("a chill fills in whole hits, drains, and never stops a body", states.Chill.Hits >= 1 and states.Chill.Drain > 0 and states.Chill.Slow > 0 and states.Chill.Slow < 1)
			t.Check("a freeze, a shock and a sap last a while", states.Freeze.Seconds > 0 and states.Shock.Seconds > 0 and states.Sap.Seconds > 0)
			t.Check("a sap cuts, never stops, a heal", states.Sap.Cut > 0 and states.Sap.Cut < 1)
		end,
	},
}
