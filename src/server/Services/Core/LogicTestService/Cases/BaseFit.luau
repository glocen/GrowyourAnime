--!strict
-- BaseFit cases (pure): part 7's tests for the base's size (docs/research/rework-2026-11-16.md, part 7; Rules.BaseFit),
-- on boxes made for the test and on the grey trial's three layouts (Config.World.Fit), each of which must pass them all.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseFit = require(Shared.Rules.BaseFit)
local WorldConfig = require(Shared.Config.World)

local function box(name: string, x0: number, x1: number, z0: number, z1: number): BaseFit.Box
	return { Name = name, Kind = name, X0 = x0, X1 = x1, Z0 = z0, Z1 = z1, High = 1 }
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	{
		Name = "BaseFit: part 7's measures, the gap edge to edge, the view, the walk to the Breaker",
		Run = function(t: any)
			t.Check("side by side across", near(BaseFit.Gap(box("a", 0, 2, 0, 2), box("b", 5, 7, 0, 2)), 3))
			t.Check("one behind the other", near(BaseFit.Gap(box("a", 0, 2, 0, 2), box("b", 0, 2, 6, 8)), 4))
			t.Check("corner to corner", near(BaseFit.Gap(box("a", 0, 2, 0, 2), box("b", 5, 7, 6, 8)), 5))
			t.Check("overlapping: negative", BaseFit.Gap(box("a", 0, 4, 0, 4), box("b", 3, 7, 0, 4)) < 0)
			t.Check("a 16:9 screen at 70° sees about 51° each side", math.abs(BaseFit.HalfView(70, 16 / 9) - 51.2) < 0.1, tostring(BaseFit.HalfView(70, 16 / 9)))
			t.Equal("bays 3 to 6 are the later bays", BaseFit.Kind("bay3"), "later")
			t.Equal("bays 1 and 2 are bays", BaseFit.Kind("bay2"), "bay")
			t.Equal("the sleeping three are stones", BaseFit.Kind("lab"), "stone")
			local unit = { Across = 0, Inward = 0, Wide = 4, Deep = 4, High = 1 }
			local fit: BaseFit.Fit = {
				Breaker = 4,
				Clear = 12,
				Avenue = 20,
				Apron = 16,
				Margin = 4,
				Camera = { Back = 12.5, Fov = 70, Aspect = 16 / 9 },
				Prints = { generator = unit, breaker = unit, door = unit },
			}
			local layout: BaseFit.Layout = {
				spawn = { across = 0, inward = 8 },
				stations = { generator = { across = 0, inward = 60 }, breaker = { across = 20, inward = 30 }, door = { across = -20, inward = 30 } },
				laterBays = {},
				sleeping = {},
			}
			local plot = { Walk = 16, Between = 32, Kept = 24 }
			local report = BaseFit.Measure(layout, 128, fit, plot)
			t.Check("the walk to the Breaker's nearest corner", near(report.Breaker, math.sqrt(18 * 18 + 28 * 28) / 16), tostring(report.Breaker))
			t.Check("the least gap: the generator and a slant's corner to corner", near(report.Least, math.sqrt(16 * 16 + 26 * 26)), tostring(report.Least))
			t.Equal("a row of four end to end", report.Row, 4 * 128 + 3 * 32)
			t.Check("it passes", (BaseFit.Passes(report, fit)))
			layout.stations.breaker = { across = 4, inward = 30 }
			local inWay = BaseFit.Measure(layout, 128, fit, plot)
			t.Equal("a machine on the middle line before the generator is on the way in", inWay.Way[1], "breaker")
			layout.stations.breaker = { across = 20, inward = 10 }
			t.Equal("one nearer the gate than the apron is outside", BaseFit.Measure(layout, 128, fit, plot).Outside[1], "breaker")
			layout.stations.breaker = { across = 61, inward = 30 }
			t.Equal("one over the square's edge is outside", BaseFit.Measure(layout, 128, fit, plot).Outside[1], "breaker")
			layout.stations.breaker = { across = 20, inward = 30 }
			layout.stations.door = { across = 26, inward = 30 }
			local close = BaseFit.Measure(layout, 128, fit, plot)
			local ok, fails = BaseFit.Passes(close, fit)
			t.Check("two machines 2 apart fail, and say which", not ok and string.find(fails[1], "breaker", 1, true) ~= nil, fails[1])
		end,
	},
	{
		Name = "BaseFit: the grey trial's three sizes each pass part 7's tests, with every machine laid and the rows shorter",
		Run = function(t: any)
			local fit = WorldConfig.Fit :: any
			local walk = WorldConfig.Walk
			local kept = WorldConfig.Plots.Kept * walk
			-- the row of four as the plan was drawn (Drawn studs square, 48 between), before part 7's trial
			local drawn = 4 * WorldConfig.Plots.Drawn * walk + 3 * 48
			t.Equal("three sizes", #fit.Sizes, 3)
			for _, cells in fit.Sizes do
				local size = cells * walk
				local layout = fit.Layouts[tostring(size)]
				t.Check(`{size}: a layout`, layout ~= nil)
				if layout then
					local report = BaseFit.Measure(layout, size, fit, { Walk = walk, Between = fit.Between * walk, Kept = kept })
					local ok, fails = BaseFit.Passes(report, fit)
					t.Check(`{size}: passes`, ok, table.concat(fails, "; "))
					t.Equal(`{size}: every machine has its footprint`, #BaseFit.Boxes(layout, fit.Prints), 14)
					t.Check(`{size}: the row of four shorter than the plan's`, report.Row < drawn, `{report.Row} of {drawn}`)
					t.Check(`{size}: smaller than the plan's square`, size < WorldConfig.Plots.Drawn * walk)
				end
			end
			t.Check("the sizes are part 7's: 128, 144, 160", fit.Sizes[1] * walk == 128 and fit.Sizes[2] * walk == 144 and fit.Sizes[3] * walk == 160)
			t.Equal("neighbours 32 apart", fit.Between * walk, 32)
		end,
	},
}
