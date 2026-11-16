--!strict
-- Base (shared): the numbers of a player's base, a power plant (docs/design.md, "The base", "Power"; TR18): the bays'
-- generation in kW, each machine's rating in kW, the battery in kWh. Seeds from tools/balance/seeds.json ("bays",
-- "power") unless marked as the builder's; once here, this is their home. Rules.Power and Rules.Breaker read them when
-- they run, so a tune reaches the next advance.

return {
	-- What a new profile starts with (Shared.Data.Profile.Template). Read when the store opens, so a tune reaches new
	-- profiles only after a restart.
	Start = {
		Chambers = 2, -- seeds "bays.chambersByGround", ground 1; the Breaker's level adds the rest (Machines.BreakerChambers)
		-- The battery's charge, kWh (seeds "power.startKwh"): Watt's shard breaks at full speed before any worker exists
		-- (docs/north-star.md, "The first session": nothing waits more than about half a minute).
		Charge = 2,
	},
	-- The machines, each drawing its rating while it works (seeds "power").
	Breaker = {
		Kw = 15, -- a chamber breaking, times its shard's ground factor (Config.Shards.RegionFactor)
		MostChambers = 4, -- docs/design.md: two chambers at the start and up to four; the screen shows the rest locked
	},
	Training = {
		Kw = 10, -- the Training machine with a Voidkin on it
	},
	Power = {
		-- Short of power a machine runs at its share over its rating, never below this share of full speed (docs/design.md:
		-- "never stopping dead"); the floor's share of the work costs nothing. Seeds "power.minSpeed".
		MinSpeed = 0.25,
	},
	Battery = {
		-- Its cap is the base level's: Levels.Battery (TR21).
		-- Away, the workers generate for this many hours, then the machines run on what the battery holds ("as far as the
		-- battery lasts"). Seeds "bays.batteryHoursByGround", ground 1, as the simulation reads it.
		AwayHours = 2,
		CreditsPerKwh = 0.5, -- what overflow past the cap sells for: "a poor rate" (seeds "power.creditsPerKwh")
	},
	Bays = {
		-- A worker generates Aptitude x KwPerAptitude x (1 + PerLevel x (Level - 1)) kW: Watt and Rook at level 1, 30 kW.
		KwPerAptitude = 6,
		PerLevel = 0.02,
	},
	-- The base's levels at launch, and its machines' under them (TR21; docs/design.md, "The base"; docs/balance.md,
	-- "Earning"). Research's seeds ("baseLevels"), priced by tools/balance/sim.py, section 15: a price is two significant
	-- figures of a share of the Credits earned over its window. Rules.BaseLevels reads them.
	Levels = {
		Cap = 3, -- the launch's: higher levels need items, designed when it rises (the director, 2026-11-15, night)
		Price = { [2] = 840, [3] = 18000 } :: { [number]: number }, -- Credits to reach each level: about 20 minutes, then 5 hours
		Bays = { 2, 4, 6 }, -- bays open at each base level
		Ceiling = { 2, 6, 30 }, -- the highest level any machine reaches at each base level
		Battery = { 60, 150, 400 }, -- kWh the battery holds at each base level (seeds "baseLevels.batteryKwh")
		Cells = { 2, 4, 8 }, -- cells its bank shows at each base level, lit one after another as it charges (Modulo's count, AR15, section 4)
	},
	Machines = {
		-- The first machine level of each stage: I, Primitive; II, Developed; III, Advanced (research's thresholds,
		-- docs/design.md, "Three stages for every machine"). The generator has no level: it takes a machine's stage at
		-- its base's ceiling (Rules.BaseLevels.GeneratorStage).
		Stages = { 1, 6, 15 },
		-- Credits to reach each machine level, the same for every machine with a level (the Training machine has none).
		Price = {
			[2] = 170, [3] = 660, [4] = 960, [5] = 1200, [6] = 1500, [7] = 2000, [8] = 2400, [9] = 2900, [10] = 3100,
			[11] = 3400, [12] = 3700, [13] = 4100, [14] = 4400, [15] = 4600, [16] = 4800, [17] = 5100, [18] = 5300,
			[19] = 5600, [20] = 5800, [21] = 6100, [22] = 6300, [23] = 6500, [24] = 6700, [25] = 6900, [26] = 7100,
			[27] = 7300, [28] = 7600, [29] = 7800, [30] = 8000,
		} :: { [number]: number },
		BayOutput = 0.04, -- a bay's output, a level past the first
		BreakerSpeed = 0.02, -- the Breaker's speed, and its rating with it, a level past the first
		BreakerChambers = { { From = 8, Chambers = 3 }, { From = 20, Chambers = 4 } }, -- its third and fourth chambers
	},
	-- When the server wakes an online player's base (BaseService): at its next event (a shard finishing, the battery
	-- emptying or filling), and at least this often, so overflow Credits and the battery's level reach the client.
	-- Technical, not balance: the builder's call, 2026-11-12.
	Clock = {
		MostSeconds = 60,
		LeastSeconds = 0.25, -- never sooner than this after the last advance, and this late past an event, so it has landed
	},
}
