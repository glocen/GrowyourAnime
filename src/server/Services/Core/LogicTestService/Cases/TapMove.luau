--!strict
-- Logic cases (pure): tap to move (TR69's trial block; Rules.TapMove, Config.Combat.TapMove). A tap past reach clamps
-- along its line, a drag is never a tap, a tap during recovery doesn't go, and the hold lasts until the tell it left
-- resolves, never past Hold. Runs in Studio (LogicTests) and with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Combat = require(Shared.Config.Combat)
local TapMove = require(Shared.Rules.TapMove)

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	{
		Name = "TapMove: a tap past reach clamps along its line, and one inside it goes where it's tapped",
		Run = function(t: any)
			local reach = 10
			local x, z, clamped = TapMove.Clamp(0, 0, 30, 40, reach) -- 50 away, along (0.6, 0.8)
			t.Check("past reach: at reach", near(math.sqrt(x * x + z * z), reach), `{x}, {z}`)
			t.Check("along the tap's line", near(x, 6) and near(z, 8), `{x}, {z}`)
			t.Check("and says so", clamped)
			local ix, iz, inside = TapMove.Clamp(2, 3, 5, 7, reach)
			t.Check("inside reach: the tap itself", near(ix, 5) and near(iz, 7) and not inside)
			local ex, ez = TapMove.Clamp(1, 1, 1 + reach, 1, reach)
			t.Check("on the edge: the tap itself", near(ex, 1 + reach) and near(ez, 1))
			local ox, oz = TapMove.Clamp(4, 4, 4, 4, reach)
			t.Check("on the lead: where it stands", near(ox, 4) and near(oz, 4))
			t.Equal("the config's reach: the director's narrowed seed", Combat.TapMove.Reach, 10)
		end,
	},
	{
		Name = "TapMove: a drag never counts as a tap, by time or by distance",
		Run = function(t: any)
			local drag = Combat.TapMove.Drag
			t.Check("a quick, still press: a tap", TapMove.IsTap(0.1, 2, drag))
			t.Check("held as long as a drag: not", not TapMove.IsTap(drag.Seconds, 0, drag))
			t.Check("held past it: not", not TapMove.IsTap(0.6, 0, drag))
			t.Check("moved as far as a drag: not", not TapMove.IsTap(0.05, drag.Pixels, drag))
			t.Check("a camera swipe: not", not TapMove.IsTap(0.2, 80, drag))
			t.Check("research's numbers: 0.25 s and 12 px", drag.Seconds == 0.25 and drag.Pixels == 12)
		end,
	},
	{
		Name = "TapMove: a tap during recovery doesn't go, and the first and one after recovery do",
		Run = function(t: any)
			local recover = Combat.TapMove.Recover
			t.Check("the first tap", TapMove.Ready(nil, 100, recover))
			t.Check("during recovery: no", not TapMove.Ready(100, 100 + recover - 0.01, recover))
			t.Check("once it's over", TapMove.Ready(100, 100 + recover, recover))
			t.Equal("3 s: a tap answers about one tell in two (the director's narrowing)", recover, 3)
			local state = { On = true, Lead = true, Stunned = false, Fighting = true, Ready = true }
			t.Equal("all there: it goes", TapMove.Refusal(state), nil)
			state.Ready = false
			t.Equal("recovering", TapMove.Refusal(state), "Recovering")
			state.Fighting = false
			t.Equal("out of a fight", TapMove.Refusal(state), "NoFight")
			state.Stunned = true
			t.Equal("stunned", TapMove.Refusal(state), "Stunned")
			state.Lead = false
			t.Equal("no lead", TapMove.Refusal(state), "NoLead")
			state.On = false
			t.Equal("switched off", TapMove.Refusal(state), "Off")
		end,
	},
	{
		Name = "TapMove: landed, the lead holds until the tell it left resolves, never past Hold, and not at all with none",
		Run = function(t: any)
			local hold = Combat.TapMove.Hold
			t.Equal("no tell: it moves as it lands", TapMove.HoldUntil(10, {}, hold), 10)
			t.Equal("a slam 0.4 s after it lands: to the slam", TapMove.HoldUntil(10, { 10.4 }, hold), 10.4)
			t.Equal("a slam far off: Hold at most", TapMove.HoldUntil(10, { 15 }, hold), 10 + hold)
			t.Equal("a tell already resolved: as it lands", TapMove.HoldUntil(10, { 9 }, hold), 10)
			t.Equal("two tells: the later", TapMove.HoldUntil(10, { 10.2, 10.5 }, hold), 10.5)
			t.Equal("research's 0.6 s", hold, 0.6)
		end,
	},
}
