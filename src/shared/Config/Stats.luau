--!strict
-- Stats (shared): the numbers of a fighter's stat block and of one hit (docs/balance.md, "Where power comes from", "The
-- stats", "One hit", "Type"). Seeds from tools/balance/seeds.json unless marked as the builder's; once here, this is
-- their home. Rules.Stats and Rules.Hit read them when they run, so a tune reaches the next call.

return {
	-- Rarity multiplies the Voidkin's own attribute points only (seeds "rarityBase"), never gear.
	Rarity = { Common = 1.0, Uncommon = 1.08, Rare = 1.16, Epic = 1.26, Legendary = 1.38, Mythical = 1.5 } :: { [string]: number },
	-- Basic Attributes, five (the director, 2026-11-19, 03:10; the ids in Definitions.Attributes). A Voidkin's own points
	-- are its class's Shape x its rarity x G(level), and each star adds Config.Voidkin.StarShareOfBase of them; gear adds
	-- points flat. Every point converts once by its attribute's Convert row, every class alike, and its class's Main
	-- converts once more by its Main row: that's the whole class difference. Everything adds: nothing multiplies an
	-- attribute, and Combat Power reads the Battle Attributes only, so no point counts twice (Rules.Stats). Research's
	-- integration pass of the combat-math review (2026-11-19): rows fitted so each class stands against the rest as
	-- before, every attribute worth about half its Main's or more, and level-1 bodies kept near today's.
	Attributes = {
		-- Battle Attribute points per attribute point, every class.
		Convert = {
			Strength = { Health = 2.3, Attack = 1 },
			Agility = { Hit = 2.5, Dodge = 1.65, Critical = 2.5 },
			Intelligence = { Penetration = 2, ElementalAttack = 1.05 },
			Endurance = { Health = 5, Defence = 1, Block = 0.067 },
			Spirit = { Health = 3.2, CriticalResist = 5.1, ElementalResist = 3, Regen = 0.05 },
		} :: { [string]: { [string]: number } },
		-- Each class's Main, and what one point of it gives on top of its Convert row.
		Main = {
			Warrior = { Attribute = "Strength", Gives = { Health = 0.57, Attack = 0.78 } },
			Tank = { Attribute = "Endurance", Gives = { Health = 2.3, Attack = 0.3, Block = 0.23 } },
			Assassin = { Attribute = "Agility", Gives = { Health = 2, Attack = 1.05 } },
			Mage = { Attribute = "Intelligence", Gives = { Health = 1.55, Attack = 0.93, Penetration = 2, ElementalAttack = 0.135 } },
			Healer = { Attribute = "Spirit", Gives = { Attack = 0.85, Regen = 0.02 } },
		} :: { [string]: { Attribute: string, Gives: { [string]: number } } },
		-- A class's own points at level 1, Common, no stars, its Main the largest.
		Shape = {
			Warrior = { Strength = 64, Agility = 16, Intelligence = 16, Endurance = 45, Spirit = 16 },
			Tank = { Strength = 45, Agility = 17, Intelligence = 17, Endurance = 75, Spirit = 17 },
			Assassin = { Strength = 40, Agility = 47, Intelligence = 19, Endurance = 36, Spirit = 16 },
			Mage = { Strength = 34, Agility = 14, Intelligence = 43, Endurance = 37, Spirit = 14 },
			Healer = { Strength = 19, Agility = 16, Intelligence = 16, Endurance = 52, Spirit = 58 },
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
	-- Lifesteal (F9; TR49): heal = Lifesteal x the damage dealt, counted up to DamagePerSecondOfMaxHealth of most health a second.
	Lifesteal = { Cap = 0.1, PerSecondOfMaxHealth = 0.008, DamagePerSecondOfMaxHealth = 0.08 },
	-- The level gap (docs/balance.md, "One hit", 8; the director, 2026-11-19, 03:10; Rules.Hit.Gap): past Free levels under
	-- its target, an attacker's hit is x max(Floor, Rate ^ (gap - Free)). Seeds, through the simulation.
	Gap = { Free = 2, Rate = 0.85, Floor = 0.05 },
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
	-- Combat Power (docs/design.md, "Combat Power"; Rules.Stats.Sum): Scale x sqrt(EHP x DPS) against the reference body
	-- at the block's level, Reference times G (its three percents as they are): how long it lasts against that body and
	-- how fast it fells it, through the hit's own expected value. For reading, never for damage. Scale sets the look:
	-- the five kitted leads' Combat Power over G, levels 1 to 60, has today's geometric mean. Weights are the line
	-- prices (Rules.Chests.Price): what a point adds to the shown Combat Power at the reference body, Scale already in
	-- them, a percent's at level 1 and times G at the block's level (ByLevel). Combat Power itself never reads them.
	-- Research's integration pass of the combat-math review, 2026-11-19.
	Power = {
		Scale = 3.431,
		Reference = { Health = 736.2, Attack = 124.5, Defence = 83.84, Hit = 250.8, Dodge = 129.8, Critical = 270.6, CriticalResist = 443.4, Block = 102.8, Penetration = 227.1, ElementalAttack = 53.73, ElementalResist = 213.8, CriticalDamage = 1, CriticalGuard = 0.175, Lifesteal = 0.035, Regen = 3.42 } :: { [string]: number },
		Weights = {
			Health = 0.9556,
			Attack = 4.487,
			Defence = 1.947,
			Hit = 0.2681,
			Dodge = 0.4825,
			Critical = 0.1744,
			CriticalResist = 0.08822,
			Block = 0.3202,
			Penetration = 0.08318,
			ElementalAttack = 2.584,
			ElementalResist = 0.2196,
			CriticalDamage = 109.1,
			CriticalGuard = 110.8,
			Lifesteal = 172.3,
			Regen = 1.463,
		} :: { [string]: number },
		-- The percents, whose weight multiplies by G at the block's level: a percent multiplies points, which grow with G.
		ByLevel = { CriticalDamage = true, CriticalGuard = true, Lifesteal = true } :: { [string]: boolean },
	},
}
