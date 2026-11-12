--!strict
-- Drops (shared Config): what a fallen enemy gives each player whose lead hit it (docs/design.md, "The world, in grey": a
-- pack belongs to everyone, the drop in full to every hitter). Seeds from tools/balance/seeds.json unless marked as the
-- builder's; once here, this is their home. Rules.Drops reads them when it runs, so a tune reaches the next fall.

return {
	-- Credits a kill gives, times G at the enemy's level: seeds "pace.creditsPerKillPerG" (the sim's income line).
	CreditsPerKillPerG = 10,
	-- The chance an ordinary Shade drops its ground's Standard shard: seeds "shards.perHour.Standard" 18 over
	-- "pace.killsPerHour" 450.
	ShardChance = 0.04,
	-- What each kind is worth against an ordinary Shade, on Credits, experience and the shard's chance (a chance tops out
	-- at 1). The builder's seed (tier 2, for research), 2026-11-12: its time to fight over an ordinary's, seeds "enemy.ttk"
	-- (an elite 18 s, ground 1's keeper 45 s, an ordinary 5 s), so a second of fighting pays the same whatever is fought.
	Share = { Ordinary = 1, Elite = 3.6, Keeper = 9 } :: { [string]: number },
	-- The account's first kill also drops this shard (docs/decisions.md, D01: Watt, the first worker).
	First = "named_watt",
}
