--!strict
-- The conductor (TR71 A; docs/research/cloud-2026-11-24/orchestration.md, 5a and 5c): every notice goes through one door,
-- Rules.Conductor orders it and the HUD shows it. A kind's Band is its place on the importance ladder (0 Still to
-- 6 Event); its Lane is where it shows: Lead (under the lead's card: its own news), Rewards (under the pills: rewards
-- and refusals, by the counters they feed) or Centre (bands 4 and up only); Fight, whether it's about the fight (in a
-- fight, a band 3 notice that isn't shows as an icon chip, and its line waits for the fight's end); Merge, whether the
-- same kind about the same thing counts up in one line. Research's seeds (5c), tuned by playing.
return {
	Merge = 1.0, -- seconds: the same kind about the same thing inside this counts up in one line
	Gap = 0.25, -- seconds between two notices in one lane
	Drop = 4, -- seconds a band 1 or 2 notice may wait before it's dropped: its counter already shows it
	Chip = 0.8, -- seconds a band 3 notice not about the fight shows as a chip in a fight
	-- How many notices a lane shows at once, in a fight (within Theme.Time.Fight of the last hit) and out of one.
	Caps = {
		Fight = { Lead = 1, Rewards = 1, Centre = 1 },
		Calm = { Lead = 1, Rewards = 2, Centre = 1 },
	} :: { [string]: { [string]: number } },
	Kinds = {
		-- band 1, Tick: a count, no words beyond a reason
		Credits = { Band = 1, Lane = "Rewards", Merge = true, Fight = true },
		Refusal = { Band = 1, Lane = "Rewards", Merge = true, Fight = false },
		-- band 2, Beat: a fly to the counter, an icon chip, never a sentence
		Shard = { Band = 2, Lane = "Rewards", Merge = true, Fight = true },
		-- band 3, Line: one line with an icon
		LevelUp = { Band = 3, Lane = "Lead", Merge = false, Fight = false },
		Drop = { Band = 3, Lane = "Rewards", Merge = false, Fight = true }, -- Rare and up
		GoalDone = { Band = 3, Lane = "Rewards", Merge = false, Fight = false },
		ShardReady = { Band = 3, Lane = "Rewards", Merge = true, Fight = false },
		BatteryFull = { Band = 3, Lane = "Rewards", Merge = true, Fight = false },
		Purchase = { Band = 3, Lane = "Rewards", Merge = false, Fight = false },
		-- band 5, Payoff: the centre
		KeeperFall = { Band = 5, Lane = "Centre", Merge = false, Fight = true },
		LeadDown = { Band = 5, Lane = "Centre", Merge = false, Fight = true },
		Record = { Band = 5, Lane = "Centre", Merge = false, Fight = false },
	} :: { [string]: { Band: number, Lane: string, Merge: boolean, Fight: boolean } },
}
