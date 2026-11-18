--!strict
-- Stats (shared): the numbers of a fighter's stat block and of one hit (docs/balance.md, "Where power comes from", "The
-- stats", "One hit", "Type"). Seeds from tools/balance/seeds.json unless marked as the builder's; once here, this is
-- their home. Rules.Stats and Rules.Hit read them when they run, so a tune reaches the next call.

return {
	-- Rarity multiplies the Voidkin's own attribute points only (seeds "rarityBase"), never gear.
	Rarity = { Common = 1.0, Uncommon = 1.08, Rare = 1.16, Epic = 1.26, Legendary = 1.38, Mythical = 1.5 } :: { [string]: number },
	-- Basic Attributes, two (docs/balance.md, "The stats"; the director's word of 2026-11-17, TR36, which replaced the five
	-- of 2026-11-16; the ids in Definitions.Attributes). A Voidkin's own points are its class's Shape x its rarity x G(level), and each star
	-- adds Config.Voidkin.StarShareOfBase of them; gear adds points flat. Every point converts once by its attribute's
	-- Convert row, every class alike, and its class's Main converts once more by its Main row: that's the whole class
	-- difference. Everything adds: nothing multiplies an attribute, and Combat Power reads the Battle Attributes only, so
	-- no point counts twice (Rules.Stats). Research's rows and fitted shapes (docs/balance.md's table, 2026-11-17; read
	-- back by tools/balance/attributes.py), each class as strong against the rest as before.
	Attributes = {
		-- Battle Attribute points per attribute point, every class.
		Convert = {
			Strength = { Attack = 1, Health = 3, Hit = 0.4, Penetration = 0.4 },
			Endurance = { Health = 5, Defence = 1, Block = 0.3, Regen = 0.02, CriticalResist = 1.5, ElementalResist = 1 },
		} :: { [string]: { [string]: number } },
		-- Each class's Main, and what one point of it gives on top of its Convert row.
		Main = {
			Warrior = { Attribute = "Strength", Gives = { Attack = 1 } },
			Tank = { Attribute = "Endurance", Gives = { Attack = 0.5, Health = 3, Block = 0.3 } },
			Assassin = { Attribute = "Strength", Gives = { Attack = 0.6, Critical = 1.6, Dodge = 0.6 } },
			Mage = { Attribute = "Strength", Gives = { Attack = 0.6, ElementalAttack = 0.25, Penetration = 1.5 } },
			Healer = { Attribute = "Endurance", Gives = { Attack = 0.7, Regen = 0.06, CriticalResist = 2 } },
		} :: { [string]: { Attribute: string, Gives: { [string]: number } } },
		-- A class's own points at level 1, Common, no stars, its Main the largest.
		Shape = {
			Warrior = { Strength = 67, Endurance = 48 },
			Tank = { Strength = 40, Endurance = 77 },
			Assassin = { Strength = 67, Endurance = 41 },
			Mage = { Strength = 67, Endurance = 45 },
			Healer = { Strength = 38, Endurance = 68 },
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
	-- times more; none does), plus what Endurance gives and a Healer's Main (Attributes), and later its gear (Regalia's
	-- stats). Rarity and stars don't touch the level's own. Research's read of the sim, 2026-11-14 (tier 2, TR12): 4, half
	-- a percent of a level-1 Warrior's health a second, 200 s from empty to full, so waiting out a heal loses to the door
	-- home; with Config.Enemies' Ordinary Attack halved, Pack 2 ends at about half (tools/balance/sim.py, section 9). The
	-- Healer's 1.5 moved into its Main (rework part 1).
	-- In bursts (TR40; the director, 2026-11-17, by 12:54 and 12:56; docs/decisions.md): a lead heals one burst every
	-- Every seconds from its summon, always, in a fight too, Share of what Every seconds at its Regen would heal, so the
	-- block's Regen stays a rate a second and a burst is Rules.Stats.Burst of it. Base from 4 to 1, so it starts very slow,
	-- and what a build adds keeps its size. Home's own heal on the player's plot is unchanged (Combat.Lead.Home).
	Regen = { Base = 1, Class = {} :: { [string]: number }, Every = 8, Share = 0.5 },
	-- Type: each beats the next, in a ring (docs/design.md, "Voidkin"). The types are named by the colours they wear (the
	-- director's word of 2026-11-17, TR36): Red, Orange, Blue, Purple, Green, the ids and the names alike.
	Beats = {
		Blue = "Red",
		Red = "Orange",
		Orange = "Purple",
		Purple = "Green",
		Green = "Blue",
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
	-- Refitted again on the two attributes' builds (docs/balance.md, "The stats", 2026-11-17; TR36): 96.3%, and 99.7%.
	-- Scale is a tenth of the seeds' 10 (the director, 2026-11-18, D3: 60,382 reads about 6,038), a look that moves no
	-- balance: the weights and every price made from them (Config.Chests.PowerPerG) stand before it.
	Power = {
		Scale = 1,
		Weights = {
			Health = 0.67,
			Attack = 4,
			Defence = 2.9,
			Regen = 1.6, -- TR40: half of 3.2, as a burst heals half what the rate did, so a point's worth halves
			Hit = 0.57,
			Dodge = 1.7,
			Critical = 0.65,
			CriticalResist = 0.11,
			Block = 0.96,
			Penetration = 0.59,
			ElementalAttack = 4.0,
			ElementalResist = 0.21,
			CriticalDamage = 110,
			CriticalGuard = 110,
			Lifesteal = 650,
		} :: { [string]: number },
		-- The percents, whose weight multiplies by G at the block's level: a percent multiplies points, which grow with G.
		ByLevel = { CriticalDamage = true, CriticalGuard = true, Lifesteal = true } :: { [string]: boolean },
	},
}
