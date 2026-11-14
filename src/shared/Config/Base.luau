--!strict
-- Base (shared): the numbers of a player's base: the Void Breaker, the bays, the battery. Seeds from tools/balance/seeds.json
-- ("bays") unless marked as the builder's; once here, this is their home (docs/design.md, "The base"). Rules.Breaker reads
-- them when it runs, so a tune reaches the next advance.

return {
	-- What a new profile starts with (Shared.Data.Profile.Template). Read when the store opens, so a tune reaches new
	-- profiles only after a restart.
	Start = {
		Chambers = 2, -- seeds "bays.chambersByGround", ground 1
		Bays = 1, -- TR2: one bay open and the second locked
		-- The battery starts holding one Named shard's work, so Watt's shard breaks at full speed before any worker
		-- exists (docs/north-star.md, "The first session": nothing waits more than about half a minute). The builder's
		-- seed, 2026-11-12.
		Battery = 20,
	},
	Breaker = {
		-- Short of power the Breaker slows in proportion to what it gets, but never below this share of full speed
		-- (docs/design.md: "it never stops dead"). The builder's seed, 2026-11-12.
		MinSpeed = 0.25,
		MostChambers = 4, -- docs/design.md: two chambers at the start and up to four; the screen shows the rest locked
	},
	Battery = {
		Capacity = 600, -- electricity held at most. The builder's seed, 2026-11-12: about two hours of ground 1's two workers
		-- Away, the workers make electricity for this many hours, then the Breaker runs on what the battery holds
		-- ("as far as the battery lasts"). Seeds "bays.batteryHoursByGround", ground 1, as the simulation reads it.
		AwayHours = 2,
		CreditsPerElectricity = 0.05, -- what overflow past the cap sells for: "a poor rate". The builder's seed, 2026-11-12
	},
	Bays = {
		-- A worker makes Aptitude x PerMinutePerAptitude x (1 + PerLevel x (Level - 1)) electricity a minute.
		PerMinutePerAptitude = 1.0,
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
