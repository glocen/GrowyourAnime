--!strict
-- Stats (shared): the numbers of a fighter's stat block and of one hit (docs/balance.md, "Where power comes from", "The
-- stats", "One hit", "Type"). Seeds from tools/balance/seeds.json unless marked as the builder's; once here, this is
-- their home. Rules.Stats and Rules.Hit read them when they run, so a tune reaches the next call.

return {
	-- Rarity multiplies the Voidkin's own attribute points only (seeds "rarityBase"), never gear.
	Rarity = { Common = 1.0, Uncommon = 1.08, Rare = 1.16, Epic = 1.26, Legendary = 1.38, Mythical = 1.5 } :: { [string]: number },
	-- Basic Attributes (docs/research/rework-2026-11-16.md, parts 1 and 2; the director's yes of 2026-11-16, 16:50; the
	-- ids in Definitions.Attributes). A Voidkin's own points are its class's Shape x its rarity x G(level), and each star
	-- adds Config.Voidkin.StarShareOfBase of them; gear adds points flat. Every point converts once by its attribute's
	-- Convert row, every class alike, and its class's Main converts once more by its Main row: that's the whole class
	-- difference. Everything adds: nothing multiplies an attribute, and Combat Power reads the Battle Attributes only, so
	-- no point counts twice (Rules.Stats). Research's seeds: tools/balance/attributes.py, ATTR, the shapes its fitted
	-- level-1 points (report A1), each class as strong against the rest as before.
	Attributes = {
		-- Battle Attribute points per attribute point, every class.
		Convert = {
			Might = { Attack = 1, Health = 4 },
			Finesse = { Attack = 0.4, Hit = 1.2, Critical = 1.6, Dodge = 0.6 },
			Vigor = { Health = 5, Defence = 1, Block = 0.3 },
			Spirit = { Regen = 0.06, Health = 6, CriticalResist = 4, ElementalResist = 3 },
			Insight = { Attack = 0.4, Penetration = 2.5, Hit = 1, Health = 2 },
		} :: { [string]: { [string]: number } },
		-- Each class's Main, and what one point of it gives on top of its Convert row.
		Main = {
			Warrior = { Attribute = "Might", Gives = { Attack = 1 } },
			Tank = { Attribute = "Vigor", Gives = { Attack = 0.5, Health = 3 } },
			Assassin = { Attribute = "Finesse", Gives = { Attack = 1 } },
			Mage = { Attribute = "Insight", Gives = { Attack = 0.8, ElementalAttack = 0.25 } },
			Healer = { Attribute = "Spirit", Gives = { Attack = 0.7, Regen = 0.04 } },
		} :: { [string]: { Attribute: string, Gives: { [string]: number } } },
		-- A class's own points at level 1, Common, no stars, its Main the largest.
		Shape = {
			Warrior = { Might = 53, Finesse = 13, Vigor = 40, Spirit = 13, Insight = 13 },
			Tank = { Might = 32, Finesse = 15, Vigor = 62, Spirit = 21, Insight = 18 },
			Assassin = { Might = 38, Finesse = 53, Vigor = 32, Spirit = 12, Insight = 12 },
			Mage = { Might = 35, Finesse = 12, Vigor = 32, Spirit = 14, Insight = 52 },
			Healer = { Might = 31, Finesse = 11, Vigor = 37, Spirit = 51, Insight = 11 },
		} :: { [string]: { [string]: number } },
	},
	-- The even foe (docs/research/rework-2026-11-16.md, part 4): the fixed reference the stat sheet's chances are read
	-- against, a Voidkin of the viewer's level on the on-budget build (seeds "onBudget"). Its ratings per G: the mean of
	-- the five classes' on-budget builds with attributes (tools/balance/attributes.py's fighter_attr, balanced spec) at
	-- each ground's first and last levels. They run from 0.8 to 1.2 of these across the grounds, which moves a shown
	-- chance under 2 points. The builder's seeds, 2026-11-16, for research to confirm.
	EvenFoe = { Hit = 76, Dodge = 41, Critical = 63, CriticalResist = 120, Block = 41, Penetration = 83, ElementalResist = 97 } :: { [string]: number },
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
	-- share: the level's own, Base at level 1 times G(level) for every class (a class in Class would carry that many
	-- times more; none does), plus what Spirit gives and a Healer's Main (Attributes), and later its gear (Regalia's
	-- stats). Rarity and stars don't touch the level's own. Research's read of the sim, 2026-11-14 (tier 2, TR12): 4, half
	-- a percent of a level-1 Warrior's health a second, 200 s from empty to full, so waiting out a heal loses to the door
	-- home; with Config.Enemies' Ordinary Attack halved, Pack 2 ends at about half (tools/balance/sim.py, section 9). The
	-- Healer's 1.5 moved into its Main (rework part 1).
	Regen = { Base = 4, Class = {} :: { [string]: number } },
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
	-- Critical Immunity, Lifesteal) is its weight at level 1, multiplied by G at the block's level. With no type edge, the
	-- higher number wins 97% of same-level duels. Research's seeds (TR17 fix 10; tools/balance/seeds.json, "combatPower",
	-- fitted by tools/balance/sim.py, section 16), tier 2, 2026-11-15, night; refitted on the attribute builds (TR25,
	-- "Research's answers", 2026-11-16, 19:13; attributes.py, report A8): 97% again, 99.7% where one wins 10% faster.
	Power = {
		Scale = 10,
		Weights = {
			Health = 0.62,
			Attack = 4,
			Defence = 2.9,
			Regen = 2.9,
			Hit = 0.45,
			Dodge = 1.4,
			Critical = 0.57,
			CriticalResist = 0.17,
			Block = 0.91,
			Penetration = 0.44,
			ElementalAttack = 3.6,
			ElementalResist = 0.18,
			CriticalDamage = 130,
			CriticalGuard = 130,
			Lifesteal = 630,
		} :: { [string]: number },
		-- The percents, whose weight multiplies by G at the block's level: a percent multiplies points, which grow with G.
		ByLevel = { CriticalDamage = true, CriticalGuard = true, Lifesteal = true } :: { [string]: boolean },
	},
}
