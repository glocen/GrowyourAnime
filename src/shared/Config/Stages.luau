--!strict
-- Stages (shared Config): a ground's street in stages, each played on Normal or Hard (TR43; the director, 2026-11-18, D2;
-- docs/design.md, "The Festival of Battles"). The one home of what a stage holds: its stops, in the street's order from
-- the Festival Door, the Shades it asks of a player before its last stop counts, and Hard's lift. Stages 1 to 3 are
-- Lantern Row's stretches, each ending at its elite and then the player's own gate to the next; stage 4 is the
-- Lamplighter. Research's shape and seeds (TR43, 22:44: a quota of 10, about 3 minutes a stage, Hard +10 so Lantern Row
-- on Hard sits in Drum Court's band); the stretches' levels are the builder's seeds, tier 2 for research, tuned by
-- playing.

export type Stage = {
	Stops: { { Kind: string, Def: string, Level: number, Count: number? } }, -- Kind: Pack (Count Shades), Elite or Keeper
	Quota: number, -- Shades that must fall to the player before the last stop counts; 0 for a keeper's stage
}

return {
	-- Levels added to every foe of a stage on Hard: Lantern Row's 1 to 9 read 11 to 19.
	Offset = { Normal = 0, Hard = 10 } :: { [string]: number },
	Grounds = {
		lanternrow = {
			{
				Stops = {
					{ Kind = "Pack", Def = "brawler", Count = 3, Level = 1 },
					{ Kind = "Pack", Def = "brawler", Count = 3, Level = 1 },
					{ Kind = "Elite", Def = "brawler_elite", Level = 2 },
				},
				Quota = 10,
			},
			{
				Stops = {
					{ Kind = "Pack", Def = "brawler", Count = 3, Level = 3 },
					{ Kind = "Pack", Def = "brawler", Count = 3, Level = 4 },
					{ Kind = "Elite", Def = "brawler_elite", Level = 5 },
				},
				Quota = 10,
			},
			{
				Stops = {
					{ Kind = "Pack", Def = "brawler", Count = 3, Level = 6 },
					{ Kind = "Pack", Def = "brawler", Count = 3, Level = 7 },
					{ Kind = "Elite", Def = "brawler_elite", Level = 8 },
				},
				Quota = 10,
			},
			{
				Stops = { { Kind = "Keeper", Def = "lamplighter", Level = 9 } },
				Quota = 0,
			},
		},
	} :: { [string]: { Stage } },
}
