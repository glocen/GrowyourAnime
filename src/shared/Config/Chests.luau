--!strict
-- Chests (shared, config): where chests come from and what an opened one rolls (docs/research/rework-2026-11-16.md, part
-- 11; docs/engineering-plan.md, "Chests"; Rules.Chests). Every number is the builder's seed (TR27), for research to fit
-- by simulation to part 11's targets: an Uncommon in the first hour, a Rare at 3 to 4 hours, an Epic at 10 to 15, a
-- Legendary at 35 to 45. An item's worth comes from tools/balance's gear share (27 of a full launch build), priced in
-- Combat Power as a line is (part 2, "A line's price").

return {
	-- What a fall drops, by enemy kind: the chance, and the chest's tier in the fall's ground. A keeper's is its win's.
	Drop = {
		Ordinary = { Chance = 0.05, Tier = 1 },
		Elite = { Chance = 1, Tier = 2 },
	} :: { [string]: { Chance: number, Tier: number } },
	Keeper = { First = 3, After = 2 }, -- the tier of a keeper's chest: its first win, then every win after
	Sure = 3, -- the account's third kill always drops a Shade's chest (the north star's "Build" beat)

	-- Rarity weights, Common to Legendary, one row a step. A chest of the ground in order g at tier t reads row g + t - 1,
	-- so an elite's chest is the next ground's Shade chest, and the last ground's elites and keeper read past it.
	-- Research's fit (TR27, 2026-11-16, 19:13; tools/balance/chests.py --fit): each rarity starts where its grounds read it
	-- (Rare at row 3, Epic at 5, Legendary at 7) and about doubles a row; alone, a first Rare at 3.5 h, Epic 12.5, Legendary
	-- 39.8 (medians).
	Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },
	Ladder = {
		{ 94, 6, 0, 0, 0 },
		{ 91.4, 8.6, 0, 0, 0 },
		{ 88, 10.9, 1.1, 0, 0 },
		{ 83.2, 14.6, 2.2, 0, 0 },
		{ 76.4, 19.2, 2.9, 1.5, 0 },
		{ 67, 24.2, 5.6, 3.2, 0 },
		{ 53.8, 28.7, 10.5, 6.2, 0.8 },
		{ 35.4, 29.6, 19.6, 13.5, 1.9 },
	},
	-- The Tower's chest reads this row in every ground, never the ladder (research's fit, TR29, 2026-11-16, 20:34): with
	-- half of play after the first hour in the Tower, a first Rare at 3.5 h, Epic 12.5, Legendary 39.9 (medians).
	Tower = { 60, 36.32, 2.86, 0.57, 0.24 },

	-- A weapon is for the lead's class this often; else for one of the other classes the player owns.
	ClassLean = 0.6,

	-- An item's worth, in Combat Power before its scale, a G at its ground's last level: a full set of fourteen at
	-- rarity 1 is the sim's gear share (Health 617, Attack 77, Defence 39, 20 of each rating, a G), 888, so 63.5 an item.
	-- Its rarity takes the sim's share of that (seeds.json, "gearRarity"). The main stat takes MainShare, the lines share
	-- the rest, and each roll lands within Spread of its worth.
	PowerPerG = 63.5,
	Rarity = { Common = 0.55, Uncommon = 0.65, Rare = 0.76, Epic = 0.88, Legendary = 1.0 } :: { [string]: number },
	MainShare = 0.5,
	Spread = 0.15,
	Lines = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 4 } :: { [string]: number },
	Sockets = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 4 } :: { [string]: number }, -- docs/design.md

	-- The main stat by the row's Slot: a weapon's Attack, armour's Battle Attribute; jewellery's (no entry) is a Basic
	-- Attribute rolled at the drop (part 2, "Gear and attributes").
	Main = {
		["Main Hand"] = "Attack",
		["Off Hand"] = "Attack",
		Helmet = "Health",
		Shoulders = "Defence",
		["Chest Armor"] = "Health",
		Gloves = "Critical",
		Bracers = "Hit",
		Boots = "Dodge",
		Cloak = "Block",
	} :: { [string]: string },
	-- What a line can be, by weight; never the main stat, never twice. A weapon's lines favour its class's Main. The two
	-- attributes keep the five's share of the pool, 10 of 21 (TR36, the builder's carry-over, for research to confirm).
	Pool = {
		Strength = 5,
		Endurance = 5,
		Health = 1,
		Attack = 1,
		Defence = 1,
		Hit = 1,
		Dodge = 1,
		Critical = 1,
		CriticalResist = 1,
		Block = 1,
		Penetration = 1,
		ElementalAttack = 1,
		ElementalResist = 1,
	} :: { [string]: number },
	MainLean = 3, -- a weapon's lines weigh its class's Main this many times

	-- Auto-salvage: Credits a G at the item's ground's last level, by rarity. Forge stones join when the Forge does.
	-- Research's fit (TR27): salvaging everything pays at most 10% of a kill's Credits on Lantern Row, 16% on Mirror
	-- Pavilion, so fighting stays the income.
	Salvage = { Common = 8, Uncommon = 14, Rare = 24, Epic = 40, Legendary = 64 } :: { [string]: number },

	Bag = 300, -- items held at most; an open that would pass it is refused before it rolls
	Step = 50, -- chests opened in one request at most
	Reach = 20, -- studs: a chest that falls within this of the avatar flies to it (its show, later)
}
