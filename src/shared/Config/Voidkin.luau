--!strict
-- Voidkin (shared): the numbers of a fighter's own progress. Seeds from tools/balance/seeds.json unless marked as the
-- builder's; once here, this is their home (docs/design.md, "Voidkin", "Stars").

return {
	MaxStars = 7, -- seeds "maxStars", the director's word of 2026-11-12
	-- Copies each star costs, the first star first: each twice the one before (seeds "shards.starCopies", the same for
	-- every rarity, so one list).
	StarCopies = { 1, 2, 4, 8, 16, 32, 64 },
	StarShareOfBase = 0.0143, -- each star adds this share of the Voidkin's base stats (seeds "starPctOfBase")
	-- Credits one copy sells for past the last star, by rarity. The builder's seed, 2026-11-12: ten times the seeds'
	-- "shards.value", so a Common copy pays one ground-1 kill ("pace.creditsPerKillPerG").
	SellCredits = { Common = 10, Uncommon = 30, Rare = 100, Epic = 400, Legendary = 2000, Mythical = 10000 } :: { [string]: number },
}
