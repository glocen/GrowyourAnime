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
	-- Forge stones and War Emblems (TR47), at research's rates (TR48, the loot refit of 2026-11-19, 16:53, at the
	-- "available" ramp). A fall drops StoneChance (by its difficulty) x its kind's Share stones of its ground's grade, the
	-- whole part sure and the rest a chance: on Normal a Shade 22% of one, an elite 0.8, a keeper 2; on Hard 28%, 1, 2.5.
	-- Low in the first GroundsAGrade grounds, Mid in the next, High after, as Reinforce spends them by tens.
	StoneChance = { Normal = 0.22, Hard = 0.28 } :: { [string]: number },
	GroundsAGrade = 2,
	-- An elite's fall drops an Emblem Case this often, and a keeper's win (Rules.Progress.KeeperWon); on a keeper's first
	-- win on a difficulty, EmblemFirst's chance instead (the director's "ok" of 2026-11-24: the drop became a case). Its
	-- emblem's rarity is the case's chest ladder row's (Config.Chests.Ladder, the ground's order plus EmblemTier minus 1,
	-- plus Config.Chests.Hard.Rows on Hard), Common counting as Uncommon, since no emblem is Common; its set and its stat,
	-- one of the rarity's, evenly. EmblemTier is the case's tier in Definitions.Chests.
	EmblemChance = { Elite = 0.3, Keeper = 0.75 } :: { [string]: number },
	EmblemFirst = { Normal = 1 } :: { [string]: number },
	EmblemTier = { Elite = 2, Keeper = 3 } :: { [string]: number },
}
