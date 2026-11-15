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
	-- Regen: the health a lead heals a second, always, in a fight too (docs/design.md, "Health carries"). A value, never a
	-- share: Base at level 1 times G(level), a Healer's class carrying Class more (every other class 1), and later its gear
	-- (Regalia's stats). Rarity and stars don't touch it. Research's read of the sim, 2026-11-14 (tier 2, TR12): 4, half
	-- a percent of a level-1 Warrior's health a second, 200 s from empty to full, so waiting out a heal loses to the door
	-- home; with Config.Enemies' Ordinary Attack halved, Pack 2 ends at about half (tools/balance/sim.py, section 9).
	Regen = { Base = 4, Class = { Healer = 1.5 } :: { [string]: number } },
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
	-- Speed (TR14; docs/design.md, "Speed"): a lead's walk speed in a fight, in studs a second, closing on its targets and
	-- moving between them. Its class's figure, moved by its own row's Speed (Definitions.Voidkin) up to Nudge either way.
	-- Never from gear: it isn't one of Rules.Stats' Names, so no source adds to it. Following the avatar,
	-- every lead walks at Config.Combat.Lead.FollowWalk whatever its Speed, and the catch-up stays. Research's seeds, tier 2,
	-- 2026-11-14, night.
	Speed = { Class = { Tank = 14, Warrior = 16, Mage = 16, Healer = 16, Assassin = 19 } :: { [string]: number }, Nudge = 1 },
	-- Combat Power (docs/design.md, "Combat Power"): one number for how strong a Voidkin is, a weighted sum of its resolved
	-- stats times Scale, rounded (Rules.Stats.Power); for reading, never for damage. Critical damage counts only above the
	-- base every fighter has. A weight is what a point adds to winning, Attack's held at 4; a percent's (Critical Damage,
	-- Critical Guard, Lifesteal) is its weight at level 1, multiplied by G at the block's level. With no type edge, the
	-- higher number wins 97% of same-level duels. Research's seeds (TR17 fix 10; tools/balance/seeds.json, "combatPower",
	-- fitted by tools/balance/sim.py, section 16), tier 2, 2026-11-15, night.
	Power = {
		Scale = 10,
		Weights = {
			Health = 0.53,
			Attack = 4,
			Defence = 3.1,
			Regen = 3.1,
			Hit = 0.53,
			Dodge = 2.1,
			Critical = 1.2,
			CriticalResist = 0.2,
			Block = 1.4,
			Penetration = 0.88,
			ElementalAttack = 5.2,
			ElementalResist = 0.34,
			CriticalDamage = 110,
			CriticalGuard = 110,
			Lifesteal = 770,
		} :: { [string]: number },
		-- The percents, whose weight multiplies by G at the block's level: a percent multiplies points, which grow with G.
		ByLevel = { CriticalDamage = true, CriticalGuard = true, Lifesteal = true } :: { [string]: boolean },
	},
}
