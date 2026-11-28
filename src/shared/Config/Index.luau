--!strict
-- The Index, the collection book (TR76; docs/design.md, "The Index"; Rules.Index, Rules.IndexBook): its stamps, what a
-- find pays, and the milestones its points reach.
-- PLACEHOLDERS, the builder's of 2026-11-28, until research sets them in tools/balance/seeds.json with the simulation.
-- Waiting: the Lamplighter's Enriched shard (no Enriched shard is defined yet), and a tab done whole's title and plinth
-- frame (screen and world work).

export type Pay = {
	Credits: number?,
	Chests: { [string]: number }?, -- by chest id (Definitions.Chests)
	Stones: { [string]: number }?, -- by grade (Config.Reinforce.Grades)
	Tokens: { [string]: number }?, -- by token id (Definitions.Tokens)
	Attributes: number?, -- flat points to each of the five Basic Attributes, for good (a milestone's)
}

return {
	Point = 1, -- Index points a stamp gives, any stamp

	-- A Voidkin's stamps beyond its find.
	Stars = { 3, 7 }, -- a stamp at each of these stars
	MasteryRank = 5, -- a stamp at this Mastery rank

	-- A Shade's kill stamps beyond its find (its first kill).
	Kills = { 10, 100, 500 },

	-- What each find pays, once, at its claim. A Shade of Kind "Keeper" pays Keeper's.
	Find = {
		Voidkin = { Credits = 500, Chests = { crate = 1 } } :: Pay,
		Shade = { Credits = 150, Stones = { Low = 2 } } :: Pay,
		Keeper = { Credits = 1000 } :: Pay, -- its Enriched shard waits for the shard
		Regalia = { Credits = 50 } :: Pay,
		Emblem = { Credits = 100 } :: Pay,
		Jewel = { Credits = 100 } :: Pay,
	},

	-- The milestones, in order. Their Attributes add to 50 to each Basic Attribute in all: about 2.5% of a level-60 build
	-- (docs/design.md, "The Index"; a level-60 build is about 10,000 points, by Mastery's rank-5 measure in TR76).
	Milestones = {
		{ At = 25, Pay = { Chests = { pouch = 1 } } :: Pay },
		{ At = 50, Pay = { Chests = { towercase_rare = 1 }, Attributes = 5 } :: Pay },
		{ At = 100, Pay = { Tokens = { Manual = 2 }, Attributes = 5 } :: Pay },
		{ At = 175, Pay = { Chests = { pouch = 2 }, Attributes = 10 } :: Pay },
		{ At = 250, Pay = { Chests = { towercase_epic = 1 }, Tokens = { Manual = 3 }, Attributes = 10 } :: Pay },
		{ At = 400, Pay = { Chests = { towercase_legendary = 1 }, Tokens = { Manual = 5 }, Attributes = 20 } :: Pay },
	},
}
