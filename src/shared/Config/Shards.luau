--!strict
-- Shards (shared): how long each grade of shard takes to break, what it holds, and what voltage does to it. Seeds from
-- tools/balance/seeds.json ("shards", "luck", "power.voltage") unless marked as the builder's; once here, this is their
-- home. A shard's energy is never set: its chamber's rating over its break time (Rules.Power.Cost, TR18).

return {
	-- Seconds of work at full power.
	Grades = {
		Standard = { BreakSeconds = 30 },
		Enriched = { BreakSeconds = 900 },
		Prismatic = { BreakSeconds = 10800 },
		Named = { BreakSeconds = 30 }, -- the builder's seed, 2026-11-12: a Standard's, as Watt's is the first
		Starter = { BreakSeconds = 6 }, -- docs/decisions.md, D01: fast. The builder's seed for "fast"
	} :: { [string]: { BreakSeconds: number } },
	-- Each grade's weight per rarity. A tier the ground's Voidkin don't reach is dropped and the rest keep their proportions.
	Pools = {
		Standard = { Common = 60, Uncommon = 30, Rare = 9, Epic = 1, Legendary = 0, Mythical = 0 },
		Enriched = { Common = 0, Uncommon = 45, Rare = 35, Epic = 16, Legendary = 4, Mythical = 0 },
		Prismatic = { Common = 0, Uncommon = 0, Rare = 40, Epic = 38, Legendary = 18, Mythical = 4 },
	} :: { [string]: { [string]: number } },
	-- A Voidkin of the shard's own ground or the one before weighs this much against an older one of its tier.
	FeaturedWeight = 3,
	-- The ground's multiplier on a chamber's rating while it breaks the ground's shard, by ground id.
	RegionFactor = {
		lanternrow = 1,
		drumcourt = 1.5,
		maskparade = 2,
		kiteheights = 4,
		emberstalls = 6,
		mirrorpavilion = 7,
	} :: { [string]: number },
	-- Luck from every source adds into one lift on the top two tiers a shard can give, up to this.
	LuckCap = 0.4,
	-- Infusion is voltage (the director, 2026-11-15, "Faster break"; docs/design.md, "Shards and the Void Breaker"): stored
	-- energy into one shard before it breaks, once, its odds never changed. Levels, in order, Low then High: the share of
	-- its time left that stays (Low halves it, High breaks it at once). The price: the energy its chamber would still draw
	-- over the time saved, times Premium, rounded up to a whole kWh; never offered when it saves under MinSavedSeconds.
	Voltage = {
		Levels = { { TimeLeft = 0.5 }, { TimeLeft = 0 } } :: { { TimeLeft: number } },
		Premium = 1.3333,
		MinSavedSeconds = 60,
	},
}
