--!strict
-- Waves cases (pure): the street in waves (TR69 B; Rules.Waves, each Pack stop's Waves in Config.World.Row.Stops). Each
-- stretch's waves fill its quota in one pass; a list run out starts again from its second wave only while someone near
-- owes; each new Shade is met alone first; the quota counts every Def a stop's waves stand; the spots stand where their
-- groups say.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Waves = require(Shared.Rules.Waves)
local World = require(Shared.Config.World)
local Stages = require(Shared.Config.Stages)

local ROW = World.Row

return {
	{
		Name = "Waves (TR69 B): each stretch's waves fill its quota in one pass; the next after the last is the second, only while someone near owes",
		Run = function(t: any)
			for stage, row in Stages.Grounds[ROW.Ground] do
				local pass, packs = 0, 0
				for _, stop in row.Stops do
					if stop.Kind == "Pack" then
						packs += 1
						pass += Waves.Pass(Waves.Of(stop))
					end
				end
				if packs > 0 then
					t.Check(`stretch {stage}: one pass fills its quota of {row.Quota}`, pass >= row.Quota, `{pass}`)
				end
			end
			local list = Waves.Of(ROW.Stops[1])
			t.Equal("the first stretch: three waves", #list, 3)
			t.Equal("owed: the next", Waves.After(list, 1, true), 2)
			t.Equal("owed, the list run out: its second", Waves.After(list, 3, true), 2)
			t.Equal("nobody near owes: it rests", Waves.After(list, 1, false), nil)
			t.Equal("a list of one starts again from it", Waves.After({ list[1] }, 1, true), 1)
		end,
	},
	{
		Name = "Waves (TR69 B): each new Shade is met alone first, and the quota counts every Def a stop's waves stand",
		Run = function(t: any)
			local seen: { [string]: boolean } = {}
			for index, stop in ROW.Stops do
				if stop.Kind == "Pack" and stop.Waves then
					for w, wave in Waves.Of(stop) do
						for _, group in wave do
							if not seen[group.Def] and group.Def ~= "support" then
								t.Check(`stop {index}, wave {w}: the first {group.Def} stands alone`, #wave == 1 or group.Def == "brawler", `{Waves.Size(wave)} in the wave`)
								seen[group.Def] = true
							end
						end
					end
				end
			end
			local defs = Waves.Defs(ROW.Stops[3])
			t.Check("a stop's waves' Defs all count", defs.guard == true and defs.brawler == true)
			local old = Waves.Of({ Def = "brawler", Count = 4, With = { Def = "guard", Count = 2 }, Rear = { Def = "support", Count = 1 } })
			t.Equal("a stop with no waves: one wave of its ring", #old, 1)
			t.Equal("as many as its ring and its rear", Waves.Size(old[1]), 5)
		end,
	},
	{
		Name = "Waves (TR69 B): the spots stand where their groups say: the sides at the stall fronts, far up the street, the rear behind, backs turned",
		Run = function(t: any)
			local w = ROW.Waves
			local spacing, behind = ROW.Spread, ROW.Behind
			local backs = Waves.Spots({ { Def = "brawler", Count = 3, Back = true } }, spacing, w.Side, w.Far, behind)
			t.Equal("three", #backs, 3)
			t.Check("their backs turned", backs[1].Turn == math.pi and backs[3].Turn == math.pi)
			local sides = Waves.Spots({ { Def = "brawler", Count = 4, From = "Sides" } }, spacing, w.Side, w.Far, behind)
			local left, right = 0, 0
			for _, spot in sides do
				left += if spot.X == -w.Side then 1 else 0
				right += if spot.X == w.Side then 1 else 0
			end
			t.Check("two from each stall front", left == 2 and right == 2, `{left} and {right}`)
			local far = Waves.Spots({ { Def = "dasher", Count = 1, From = "Far" } }, spacing, w.Side, w.Far, behind)
			t.Check("far up the street", far[1].Z == w.Far and far[1].X == 0)
			local mixed = Waves.Spots({ { Def = "guard", Count = 1, Row = "Front" }, { Def = "dasher", Count = 1 }, { Def = "brawler", Count = 2 }, { Def = "support", Count = 1, Rear = true } }, spacing, w.Side, w.Far, behind)
			t.Equal("every Shade of the wave", #mixed, 5)
			local front, rear
			for _, spot in mixed do
				if spot.Def == "guard" then
					front = spot
				elseif spot.Def == "support" then
					rear = spot
				end
			end
			t.Check("the Guard in front of the ring", front ~= nil and front.Z < 0)
			local deepest = -math.huge
			for _, spot in mixed do
				if spot.Def ~= "support" then
					deepest = math.max(deepest, spot.Z)
				end
			end
			t.Check("the Support behind everything", rear ~= nil and rear.Z >= deepest + behind - 1e-6)
			local typed = Waves.Spots({ { Def = "brawler", Count = 3, Type = "Blue" } }, spacing, w.Side, w.Far, behind)
			t.Equal("another type keeps its own", typed[1].Type, "Blue")
			local alleys = Waves.Spots({ { Def = "dasher", Count = 2, From = "Alleys" } }, spacing, w.Side, w.Far, behind)
			t.Check("the two alleys, one each side, ahead", alleys[1].X == -w.Side and alleys[2].X == w.Side and alleys[1].Z > 0 and alleys[1].Z ~= alleys[2].Z)
		end,
	},
}
