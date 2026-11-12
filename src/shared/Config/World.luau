--!strict
-- World (shared Config): research's layout for TR2 in grey (docs/design.md, "The world, in grey"), as WorldService lays it
-- when the place holds no authored world. Times are the design and studs follow them: a length in seconds is walked at
-- Walk, so a change of walk moves the studs and keeps the times. Tuned live, and the grey world is laid again:
-- NL_Debug:Invoke("Tune", "World.Row.Spacing", 6).

-- One stop down Lantern Row. Kind: Pack (Count Shades), Elite or Keeper.
export type Stop = { Kind: string, Def: string, Level: number, Count: number? }

return {
	Walk = 16, -- studs a second the times are worked at: Roblox's default walk
	-- Seconds a new avatar opens from black on its plot's spawn, the camera turned behind it (WorldService, FadeController):
	-- joining, or a reset. The builder's, 2026-11-12.
	Arrive = 0.4,

	-- Eight plots, two rows of four, facing each other across the Strip; one per player (Max Players 8).
	Plots = {
		Count = 8,
		Across = 5, -- 80 studs, open onto the Strip
		Deep = 5, -- 80 studs: the Breaker at the front, the bays at its sides, the battery between them
		Kept = 1.5, -- 24 studs at the back, kept for the Forge, the Lab and the Condenser (phase 3)
		Between = 0.75, -- 12 studs of path between neighbours
		Behind = 1, -- 16 studs of path behind a plot, then its Tower
		Tower = 2, -- the Tower's footprint, 32 studs, left empty (phase 3)
		Bays = 2, -- one open, the second locked (TR2)
	},

	-- The Strip: plots on both sides, a crossing one plot wide at its middle, the Shop south of it, the side street north.
	Strip = {
		Wide = 3, -- 48 studs
		Ends = 5, -- past the last plots, kept for the Calamity and the Clash Grounds (phase 5)
	},

	-- The side street runs from the crossing between the Towers to the festival gate: a plot's depth, its path behind and
	-- its Tower, 8 s. Then Lantern Row.
	Row = {
		Ground = "lanternrow", -- the ground this street is (Definitions.Grounds): its keeper's win counts there
		Wide = 2, -- 32 studs between the stall fronts
		FirstPack = 2, -- from the gate to the first pack, in view of it
		Spacing = 5, -- 80 studs from stop to stop, past the lead's leash (Config.Combat.Lead.Leash)
		-- The street's rhythm, from the gate: three packs, the elite's square, three packs, the keeper's gate.
		-- Levels: the builder's seeds (tier 2, for research), 2026-11-12.
		Stops = {
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 1 },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 2 },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 3 },
			{ Kind = "Elite", Def = "brawler_elite", Level = 4 },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 5 },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 6 },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 7 },
			{ Kind = "Keeper", Def = "lamplighter", Level = 9 },
		} :: { Stop },
		Square = 4, -- the elite's square, 64 studs across, so anyone near can join
		Ring = 5, -- the Lamplighter's ring, 80 studs across, behind the keeper's gate
		Beyond = 1.5, -- from the ring's far edge to Drum Court's gate, shut, in view
		Spread = 7, -- studs between a pack's Shades at its spawn (inside Combat.Shade.Notice, so one notices for all)
		Respawn = 15, -- seconds after a pack's last Shade falls until it's back, the elite's too (the builder's seed, 2026-11-12)
	},

	-- How the grey build stands up: studs, not times.
	Grey = {
		Floor = 1, -- the ground slab's thickness
		Wall = 10, -- the stall fronts' and the gates' height
		Copies = 600, -- how far apart the keeper's ring copies stand, one per plot, out of sight
		CopiesAt = 3000, -- studs east of the crossing the first copy stands
	},
}
