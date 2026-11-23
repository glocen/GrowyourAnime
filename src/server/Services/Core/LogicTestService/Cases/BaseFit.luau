--!strict
-- BaseFit cases (pure): part 7's tests for the base's plan (docs/research/rework-2026-11-16.md, part 7; Rules.BaseFit),
-- on boxes made for the test and on the plan's own layout (Config.Kits.Base, AR54's lay) at Stage III's footprints
-- (Config.World.Fit.Prints), which must pass them all.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseFit = require(Shared.Rules.BaseFit)
local WorldConfig = require(Shared.Config.World)
local BasePlan: any = require(Shared.Config.Kits.Base.Plan)

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
			t.Equal("bays 1 and 2 are bays", BaseFit.Kind("bay2"), "bay")
			t.Equal("bays 3 to 6 are bays too: a sleeping bay wakes into one", BaseFit.Kind("bay6"), "bay")
			t.Equal("the Forge, the Condenser and the Lab are their own", BaseFit.Kind("lab"), "lab")
			local offset = { Across = 1, Inward = 2, Wide = 4, Deep = 6, High = 3 }
			local half = BaseFit.Turned(offset, 180)
			t.Check("a half turn mirrors the print's offset and keeps its size", half.Across == -1 and half.Inward == -2 and half.Wide == 4 and half.Deep == 6, `{half.Across}, {half.Inward}, {half.Wide} by {half.Deep}`)
			local quarter = BaseFit.Turned(offset, 90)
			t.Check("a quarter turn swaps its size across and inward", quarter.Across == 2 and quarter.Inward == -1 and quarter.Wide == 6 and quarter.Deep == 4, `{quarter.Across}, {quarter.Inward}, {quarter.Wide} by {quarter.Deep}`)
			t.Equal("no turn: as it is", BaseFit.Turned(offset, nil).Across, 1)
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
		Name = "BaseFit: the plan's layout (AR54) passes part 7's tests at Stage III's footprints, every machine laid, the ring kept",
		Run = function(t: any)
			local fit = WorldConfig.Fit :: any
			local walk = WorldConfig.Walk
			local size = WorldConfig.Plots.Drawn * walk
			local layout = BasePlan.layout
			t.Equal("the plan is drawn for the plots' size", WorldConfig.Plots.Across * walk, size)
			local report = BaseFit.Measure(layout, size, fit, { Walk = walk, Between = WorldConfig.Plots.Between * walk, Kept = WorldConfig.Plots.Kept * walk })
			local ok, fails = BaseFit.Passes(report, fit)
			t.Check(BaseFit.Line(report, fit), ok, table.concat(fails, "; "))
			local boxes = BaseFit.Boxes(layout, fit.Prints)
			t.Equal("every machine has its footprint: the seven stations, four more bays, three sleeping", #boxes, 14)
			for _, box in boxes do
				t.Check(`{box.Name}: a print of its own kind`, fit.Prints[box.Kind] ~= nil, box.Kind)
			end
			-- The generator's own clear: the widest ring round its spot that touches no other footprint (AR54, 25.1 at
			-- Stage III); the landing's ring is held inside it (Config.Landing.Throw.Reach).
			local gx, gz = layout.stations.generator.across, layout.stations.generator.inward
			local ring = math.huge
			for _, box in boxes do
				if box.Name ~= "generator" then
					local dx = math.max(box.X0 - gx, gx - box.X1, 0)
					local dz = math.max(box.Z0 - gz, gz - box.Z1, 0)
					ring = math.min(ring, math.sqrt(dx * dx + dz * dz))
				end
			end
			t.Check("the generator's clear is 25 studs or more", ring >= 25, string.format("%.2f", ring))
		end,
	},
}
