--!strict
-- Stats (shared): the numbers of a fighter's stat block and of one hit (docs/balance.md, "Where power comes from", "The
-- stats", "One hit", "Type"). Seeds from tools/balance/seeds.json unless marked as the builder's; once here, this is
-- their home. Rules.Stats and Rules.Hit read them when they run, so a tune reaches the next call.

return {
	-- A Common Warrior's own base at level 1 (seeds "base"); G(level) scales it.
	Base = { Health = 800, Attack = 100, Defence = 50 } :: { [string]: number },
	-- Rarity multiplies the Voidkin's own base only (seeds "rarityBase").
	Rarity = { Common = 1.0, Uncommon = 1.08, Rare = 1.16, Epic = 1.26, Legendary = 1.38, Mythical = 1.5 } :: { [string]: number },
	-- Class shifts the own base between the three (seeds "classMult"). It never touches gear.
	Class = {
		Warrior = { Health = 1.0, Attack = 1.0, Defence = 1.0 },
		Tank = { Health = 1.3, Attack = 0.8, Defence = 1.25 },
		Assassin = { Health = 0.85, Attack = 1.2, Defence = 0.85 },
		Mage = { Health = 0.9, Attack = 1.15, Defence = 0.85 },
		Healer = { Health = 1.0, Attack = 0.8, Defence = 0.95 },
	} :: { [string]: { [string]: number } },
	-- Ratings: chance = cap x mine / (mine + theirs + K x G(level)) (seeds "ratings").
	RatingK = 100,
	Caps = {
		Dodge = 0.4,
		CriticalFloor = 0.05, -- every hit has this chance to be critical
		CriticalSpan = 0.55, -- what the Critical rating adds above the floor
		Critical = 0.6, -- the floor and the span together, at most
		Block = 0.5,
		Penetration = 0.4,
		ElementalResist = 0.75,
	},
	-- Mitigation = d / (d + K x G(attacker's level)), d the Defence left after Penetration, at most Cap (seeds "defense").
	Defence = { K = 150, Cap = 0.75 },
	CriticalDamage = 0.5, -- the extra a critical adds before items (seeds "crit.baseDamage")
	-- The two buckets a hit multiplies by, each a sum with one ceiling (seeds "buckets").
	Buckets = {
		BonusCap = 2.0,
		ReductionCap = 0.7,
		TypeAdvantage = 0.25, -- into the attacker's bonus
		TypeDisadvantage = 0.15, -- into the defender's reduction
		BlockShare = 0.5, -- a blocked hit adds this to the reduction
	},
	Lifesteal = { Cap = 0.1, PerSecondOfMaxHealth = 0.008 }, -- seeds "lifesteal"
	-- Type: each beats the next, in a ring (docs/design.md, "Voidkin").
	Beats = {
		Agility = "Strength",
		Strength = "Endurance",
		Endurance = "Intelligence",
		Intelligence = "Technique",
		Technique = "Agility",
	} :: { [string]: string },
	-- Poise: the bar a fighter's hits fill (docs/design.md, "States in a fight"). Class sets its size. Read by nothing in
	-- TR2: the states join with the Lamplighter as a real fight. The builder's seed, 2026-11-12, to be tuned by playing.
	Poise = { Warrior = 100, Tank = 150, Assassin = 70, Mage = 80, Healer = 90 } :: { [string]: number },
}
