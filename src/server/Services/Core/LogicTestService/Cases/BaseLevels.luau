--!strict
-- Logic cases (pure): the base's levels and its machines' (TR21; Rules.BaseLevels; Config.Base.Levels and .Machines,
-- research's seeds priced by tools/balance/sim.py, section 15). Runs in Studio (LogicTests) and with Studio closed
-- (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseLevels = require(Shared.Rules.BaseLevels)
local Breaker = require(Shared.Rules.Breaker)
local BaseConfig = require(Shared.Config.Base)
local BasePlan: any = require(Shared.Config.Kits.Base.Plan)
local BaseManifest: any = require(Shared.Config.Kits.Base.Manifest)
local Kit = require(Shared.World.Kit)

local function gainOf(offer: BaseLevels.Offer, what: string): BaseLevels.Gain?
	for _, each in offer.Gains do
		if each.What == what then
			return each
		end
	end
	return nil
end

return {
	{
		Name = "Base levels: 1 to the launch's cap of 3, each opening bays, the battery's cap and the machines' ceiling",
		Run = function(t: any)
			t.Equal("the launch's cap", BaseLevels.Top(), 3)
			t.Equal("level 1 has no price: every base starts there", BaseLevels.Price(1), nil)
			t.Equal("level 2: 840 Credits", BaseLevels.Price(2), 840)
			t.Equal("level 3: 18,000 Credits", BaseLevels.Price(3), 18000)
			t.Equal("nothing past the cap", BaseLevels.Price(4), nil)
			for level, want in { { 2, 60, 2 }, { 3, 150, 6 }, { 4, 400, 30 } } do
				t.Equal(`level {level}: {want[1]} bays`, BaseLevels.Bays(level), want[1])
				t.Equal(`level {level}: the battery holds {want[2]} kWh`, BaseLevels.Battery(level), want[2])
				t.Equal(`level {level}: a machine's ceiling {want[3]}`, BaseLevels.Ceiling(level), want[3])
			end
			t.Equal("four bays at most at launch (D5)", BaseLevels.Bays(BaseLevels.Top()), 4)
			t.Equal("six on every plot", BaseLevels.Plot(), 6)
			for index, want in { 1, 1, 2, 3 } do
				t.Equal(`bay {index} opens at base level {want}`, BaseLevels.OpensAt(index), want)
			end
			t.Check("bays 5 and 6 open with more Voidkin, at no level at launch", BaseLevels.OpensAt(5) == nil and BaseLevels.OpensAt(6) == nil)
			t.Equal("the plan lays every bay", 2 + #BasePlan.layout.laterBays, BaseLevels.Plot())
		end,
	},
	{
		Name = "Base levels: the next one's offer gives its price and its gains, short of Credits says so, and the cap ends it",
		Run = function(t: any)
			local first = BaseLevels.Next(1, 840)
			t.Equal("from 1: to level 2", first.Level, 2)
			t.Equal("its price", first.Price, 840)
			t.Equal("840 Credits buy it", first.Why, nil)
			local bays = gainOf(first, "Bays")
			t.Check("it shows its bays, 2 to 3", bays ~= nil and bays.From == 2 and bays.To == 3)
			local battery = gainOf(first, "Battery")
			t.Check("and the battery, 60 to 150 kWh", battery ~= nil and battery.From == 60 and battery.To == 150)
			local ceiling = gainOf(first, "Ceiling")
			t.Check("and the machines' ceiling, 2 to 6", ceiling ~= nil and ceiling.From == 2 and ceiling.To == 6)
			t.Equal("839 Credits are short", BaseLevels.Next(1, 839).Why, BaseLevels.Short)
			local last = BaseLevels.Next(3, 1e9)
			t.Equal("at the cap, nothing more", last.Why, BaseLevels.AtCap)
			t.Equal("and no price", last.Price, nil)
		end,
	},
	{
		Name = "Machine levels: the sim's prices, rising from 170 to 8,000, never past the base's ceiling",
		Run = function(t: any)
			t.Equal("level 1 has no price", BaseLevels.MachinePrice(1), nil)
			t.Equal("level 2: 170 Credits", BaseLevels.MachinePrice(2), 170)
			t.Equal("level 30: 8,000 Credits", BaseLevels.MachinePrice(30), 8000)
			t.Equal("nothing past 30 at launch", BaseLevels.MachinePrice(31), nil)
			local rising = true
			for level = 3, 30 do
				local price, before = BaseLevels.MachinePrice(level), BaseLevels.MachinePrice(level - 1)
				rising = rising and price ~= nil and before ~= nil and price > before
			end
			t.Check("each level dearer than the one before", rising)
			t.Equal("the launch's top ceiling is the table's end", BaseLevels.Ceiling(BaseLevels.Top()), 30)
			t.Equal("at base level 1, level 2 can be bought", BaseLevels.NextMachine("Bay", 1, 1, 170).Why, nil)
			t.Equal("level 3 waits for the base's level 2", BaseLevels.NextMachine("Bay", 2, 1, 1e9).Why, BaseLevels.AtCeiling)
			t.Equal("which lets it rise to 6", BaseLevels.NextMachine("Breaker", 5, 2, 1e9).Why, nil)
			t.Equal("and no further", BaseLevels.NextMachine("Breaker", 6, 2, 1e9).Why, BaseLevels.AtCeiling)
			t.Equal("short of Credits says so", BaseLevels.NextMachine("Bay", 1, 1, 169).Why, BaseLevels.Short)
			t.Equal("the ceiling before the purse", BaseLevels.NextMachine("Bay", 2, 1, 0).Why, BaseLevels.AtCeiling)
			t.Equal("30 is the last", BaseLevels.NextMachine("Bay", 30, 3, 1e9).Why, BaseLevels.AtCap)
		end,
	},
	{
		Name = "Machine levels: a bay +4% output a level, the Breaker +2% speed and its third and fourth chambers at 8 and 20",
		Run = function(t: any)
			t.Check("a bay at level 1: its output as it stands", math.abs(BaseLevels.BayOutput(1) - 1) < 1e-9, tostring(BaseLevels.BayOutput(1)))
			t.Check("a bay at level 26: twice it", math.abs(BaseLevels.BayOutput(26) - 2) < 1e-9, tostring(BaseLevels.BayOutput(26)))
			t.Check("the Breaker at level 11: 20% faster", math.abs(BaseLevels.BreakerSpeed(11) - 1.2) < 1e-9, tostring(BaseLevels.BreakerSpeed(11)))
			t.Equal("two chambers to level 7", BaseLevels.Chambers(7), BaseConfig.Start.Chambers)
			t.Equal("the third at 8", BaseLevels.Chambers(8), 3)
			t.Equal("still three at 19", BaseLevels.Chambers(19), 3)
			t.Equal("the fourth at 20", BaseLevels.Chambers(20), 4)
			t.Equal("never more than the Breaker holds", BaseLevels.Chambers(30), BaseConfig.Breaker.MostChambers)
			local bay = BaseLevels.NextMachine("Bay", 1, 1, 1e9)
			local output = gainOf(bay, "Output")
			t.Check("a bay's offer shows its output, 1 to 1.04", output ~= nil and math.abs(output.From - 1) < 1e-9 and math.abs(output.To - 1.04) < 1e-9)
			local breaker = BaseLevels.NextMachine("Breaker", 7, 3, 1e9)
			local chambers = gainOf(breaker, "Chambers")
			t.Check("the Breaker's offer at 7 shows its third chamber", chambers ~= nil and chambers.From == 2 and chambers.To == 3)
			t.Check("and its speed", gainOf(breaker, "Speed") ~= nil)
			t.Equal("a level with no new chamber shows none", gainOf(BaseLevels.NextMachine("Breaker", 2, 3, 1e9), "Chambers"), nil)
		end,
	},
	{
		Name = "Stages: a machine's I to level 5, II from 6, III from 15; the generator's the base's ceiling's, II at base level 2 and III at 3",
		Run = function(t: any)
			for level, want in { [1] = 1, [5] = 1, [6] = 2, [14] = 2, [15] = 3, [30] = 3 } do
				t.Equal(`machine level {level}: stage {want}`, BaseLevels.Stage(level), want)
			end
			t.Equal("below level 1 is still stage I", BaseLevels.Stage(0), 1)
			for level, want in { 1, 2, 3 } do
				t.Equal(`base level {level}: the generator's stage {want}`, BaseLevels.GeneratorStage(level), want)
				t.Equal(`base level {level}: as a machine at the ceiling`, BaseLevels.GeneratorStage(level), BaseLevels.Stage(BaseLevels.Ceiling(level)))
			end
			t.Equal("past the cap, the last stage", BaseLevels.GeneratorStage(BaseLevels.Top() + 1), 3)
			t.Equal("one stage a threshold", #BaseConfig.Machines.Stages, 3)
		end,
	},
	{
		Name = "Stages on a base (TR51): the Breaker and each bay by their own level, I at 5, II at 6 and 14, III at 15; the generator, the battery and the Training machine by the base's",
		Run = function(t: any)
			for level, want in { [5] = 1, [6] = 2, [14] = 2, [15] = 3 } do
				local stages = BaseLevels.Stages({ Level = 3, Machines = { Breaker = level }, Bays = { { Level = level }, { Level = 1 } } })
				t.Equal(`the Breaker at level {level}: stage {want}`, stages.Breaker, want)
				t.Equal(`a bay at level {level}: stage {want}`, stages.Bays[1], want)
				t.Equal("each bay its own", stages.Bays[2], 1)
			end
			for level, want in { 1, 2, 3 } do
				local stages = BaseLevels.Stages({ Level = level, Machines = {}, Bays = {} })
				t.Equal(`base level {level}: the battery's stage {want}`, stages.Battery, want)
				t.Equal(`base level {level}: the Training machine's stage {want}`, stages.Training, want)
				t.Equal(`base level {level}: the generator's stage {want}`, stages.Generator, BaseLevels.GeneratorStage(level))
				t.Equal("a Breaker with no level yet stands at stage I", stages.Breaker, 1)
			end
		end,
	},
	{
		Name = "Landing (TR51, AR37): a stage swap lands only on a rise from a stage already seen; a join, a respawn and a fall show it standing",
		Run = function(t: any)
			t.Check("a rise lands", BaseLevels.Lands(1, 2) and BaseLevels.Lands(2, 3) and BaseLevels.Lands(1, 3))
			t.Check("a join or a respawn (nothing seen yet) doesn't", not BaseLevels.Lands(nil, 1) and not BaseLevels.Lands(nil, 3))
			t.Check("the same stage again doesn't", not BaseLevels.Lands(2, 2))
			t.Check("a fall (a wiped save) doesn't", not BaseLevels.Lands(3, 1))
		end,
	},
	{
		Name = "Battery: its bank shows 2, 4 and 8 cells at the base's levels, lit one after another as it charges",
		Run = function(t: any)
			for level, want in { 2, 4, 8 } do
				t.Equal(`level {level}: {want} cells`, BaseLevels.Cells(level), want)
			end
			local function lit(level: number, charge: number): string
				return table.concat(Breaker.Cells({ Level = level, Charge = charge } :: any), " ")
			end
			t.Equal("empty: every cell dark", lit(1, 0), "0 0")
			t.Equal("a quarter of 60 kWh: the first cell half lit", lit(1, 15), "0.5 0")
			t.Equal("half: the first lit, the second dark", lit(1, 30), "1 0")
			t.Equal("full: both lit", lit(1, 60), "1 1")
			t.Equal("past the cap, as a stored charge can be: still both, never more", lit(1, 75), "1 1")
			t.Equal("level 3, 250 of 400 kWh: five of eight lit", lit(3, 250), "1 1 1 1 1 0 0 0")
		end,
	},
	{
		Name = "BaseLevels (AR50, AR54): levels 2 and 3 add their pieces beside the level's under them, the rings on one axle; bays 3 and 4 each their own wake; the sixteen floors glow as floors",
		Run = function(t: any)
			local levels = BasePlan.machines.baseLevels
			for _, key in { "2", "3" } do
				local rows = levels.levels[key].pieces
				t.Check(`level {key} has its pieces`, #rows == 4, `{#rows}`)
				for _, row in rows do
					t.Check(`level {key}: {row.piece} is in the kit`, BaseManifest.pieces[row.piece] ~= nil)
					t.Check(`level {key}: {row.piece} on the plot`, math.abs(row.across) <= 64 and row.along <= 0 and row.along >= -128, `{row.across}, {row.along}`)
					if row.moves == "turns" then
						-- Its axle as it stands: CFrame.Angles(0, 0, lean) * CFrame.Angles(tilt, 0, 0) applied to its own Y.
						local tilt, lean = math.rad(row.tilt), math.rad(row.lean)
						local axle = { -math.cos(tilt) * math.sin(lean), math.cos(tilt) * math.cos(lean), math.sin(tilt) }
						local off = 0
						for i = 1, 3 do
							off = math.max(off, math.abs(axle[i] - row.axle[i]))
						end
						t.Check(`level {key}: {row.piece}'s axle is the plan's`, off < 1e-3, string.format("%.4f %.4f %.4f", axle[1], axle[2], axle[3]))
						t.Check(`level {key}: {row.piece} turns slowly, a way of its own`, row.rate > 0 and row.rate < 0.05 and (row.sign == 1 or row.sign == -1))
						t.Check(`level {key}: {row.piece}'s middle is its origin, so it turns in place`, BaseManifest.pieces[row.piece].centre[1] == 0 and BaseManifest.pieces[row.piece].centre[3] == 0)
					end
				end
			end
			local inner, outer = levels.levels["2"].pieces[4], levels.levels["3"].pieces[4]
			t.Check("the two rings share one axle and cross opposite ways", inner.tilt == outer.tilt and inner.lean == outer.lean and inner.sign == -outer.sign)
			t.Equal("bay 3's wake", levels.bayWake.pieces["3"], "BayWake3")
			t.Equal("bay 4's wake", levels.bayWake.pieces["4"], "BayWake4")
			t.Check("no wake for the bays locked at launch", levels.bayWake.pieces["5"] == nil and levels.bayWake.pieces["6"] == nil)
			local floors = 0
			for _, placement in BasePlan.levels["1"].placements do
				if string.match(placement.piece, "^Floor%u%d$") then
					floors += 1
					t.Check(`{placement.piece} glows as a floor`, Kit.Floors[placement.piece] == true)
				end
			end
			t.Equal("the deck's sixteen floors", floors, 16)
			t.Equal("the gate's plate over the truss", BasePlan.levels["1"].levelMark.up, 21.6)
		end,
	},
}
