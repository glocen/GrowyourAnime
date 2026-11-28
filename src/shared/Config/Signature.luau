--!strict
-- Signature (shared): a Voidkin's signature levels, 1 to 5, each paid with Skill Manuals and Credits (docs/design.md,
-- "Voidkin", "Growing a Voidkin"; TR76, the director's yes of 2026-11-28, 11:32). Rules.Signature reads them when it runs.
-- PLACEHOLDERS, the builder's of 2026-11-28, until research sets the seeds with the simulation and writes each Voidkin's
-- five rows with its kit (docs/roster.md): every number below is one.

return {
	MaxLevel = 5,
	-- What reaching each level costs, by the level reached (level 1 is free: every Voidkin starts there). PLACEHOLDER.
	Cost = {
		[2] = { Manuals = 1, Credits = 2000 },
		[3] = { Manuals = 2, Credits = 5000 },
		[4] = { Manuals = 4, Credits = 12000 },
		[5] = { Manuals = 6, Credits = 30000 },
	} :: { [number]: { Manuals: number, Credits: number } },
	-- Each signature's rows: by action (Definitions.Actions), by beat, its hit's Coefficient at levels 1 to 5. Level 1 is
	-- the action's own, so a Voidkin at level 1 fights as before (a logic case holds it). A better row, never a
	-- multiplier (docs/balance.md, "The one rule"). A signature with no rows here stays at its own at every level.
	-- Levels 3 and 5's one more thing each (a wider wave, a second cut) comes with each kit's build. PLACEHOLDER.
	Rows = {
		RookHaymaker = { Strike = { 4.0, 4.4, 4.8, 5.2, 5.6 } },
		KirraScarfStep = { Cut = { 4.0, 4.4, 4.8, 5.2, 5.6 } },
		PipLanternBurst = { Burst = { 2.5, 2.75, 3.0, 3.25, 3.5 } },
		WattGroundWire = { Plant = { 2.5, 2.75, 3.0, 3.25, 3.5 } },
		LyricHeldNote = {
			Note = { 0.5, 0.55, 0.6, 0.65, 0.7 },
			Crest2 = { 0.5, 0.55, 0.6, 0.65, 0.7 },
			Crest3 = { 0.5, 0.55, 0.6, 0.65, 0.7 },
			Crest4 = { 0.5, 0.55, 0.6, 0.65, 0.7 },
			Release = { 0.5, 0.55, 0.6, 0.65, 0.7 },
		},
	} :: { [string]: { [string]: { number } } },
}
