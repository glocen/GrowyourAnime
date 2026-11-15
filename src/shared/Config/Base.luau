--!strict
-- Base (shared): the numbers of a player's base, a power plant (docs/design.md, "The base", "Power"; TR18): the bays'
-- generation in kW, each machine's rating in kW, the battery in kWh. Seeds from tools/balance/seeds.json ("bays",
-- "power") unless marked as the builder's; once here, this is their home. Rules.Power and Rules.Breaker read them when
-- they run, so a tune reaches the next advance.

return {
	-- What a new profile starts with (Shared.Data.Profile.Template). Read when the store opens, so a tune reaches new
	-- profiles only after a restart.
	Start = {
		Chambers = 2, -- seeds "bays.chambersByGround", ground 1
		Bays = 1, -- TR2: one bay open and the second locked
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
		Capacity = 60, -- kWh held at most (seeds "power.batteryKwh"); it grows with the base before ground 3 (TR18)
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
	-- When the server wakes an online player's base (BaseService): at its next event (a shard finishing, the battery
	-- emptying or filling), and at least this often, so overflow Credits and the battery's level reach the client.
	-- Technical, not balance: the builder's call, 2026-11-12.
	Clock = {
		MostSeconds = 60,
		LeastSeconds = 0.25, -- never sooner than this after the last advance, and this late past an event, so it has landed
	},
}
