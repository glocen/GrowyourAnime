--!strict
-- Shards (shared): how long each grade of shard takes to break, what it costs, and what it holds. Seeds from
-- tools/balance/seeds.json ("shards", "luck") unless marked as the builder's; once here, this is their home.

return {
	-- Seconds of work at full power, and the electricity that work costs before the ground's factor.
	Grades = {
		Standard = { BreakSeconds = 30, Energy = 20 },
		Enriched = { BreakSeconds = 900, Energy = 200 },
		Prismatic = { BreakSeconds = 10800, Energy = 1500 },
		Named = { BreakSeconds = 30, Energy = 20 }, -- the builder's seed, 2026-11-12: a Standard's, as Watt's is the first
		Starter = { BreakSeconds = 6, Energy = 0 }, -- docs/decisions.md, D01: free and fast. The builder's seed for "fast"
	} :: { [string]: { BreakSeconds: number, Energy: number } },
	-- Each grade's weight per rarity. A tier the ground's Voidkin don't reach is dropped and the rest keep their proportions.
	Pools = {
		Standard = { Common = 60, Uncommon = 30, Rare = 9, Epic = 1, Legendary = 0, Mythical = 0 },
		Enriched = { Common = 0, Uncommon = 45, Rare = 35, Epic = 16, Legendary = 4, Mythical = 0 },
		Prismatic = { Common = 0, Uncommon = 0, Rare = 40, Epic = 38, Legendary = 18, Mythical = 4 },
	} :: { [string]: { [string]: number } },
	-- A Voidkin of the shard's own ground or the one before weighs this much against an older one of its tier.
	FeaturedWeight = 3,
	-- The ground's multiplier on a shard's electricity, by ground id.
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
	-- Infusion (docs/design.md, "Shards and the Void Breaker"): electricity from the battery into one shard before it breaks,
	-- a little or a lot, lifting its top two tiers by Lift, the price the same whatever the shard (seeds.json, "luck").
	Infusion = {
		{ Lift = 0.10, Energy = 300 },
		{ Lift = 0.25, Energy = 900 },
	} :: { { Lift: number, Energy: number } },
}
