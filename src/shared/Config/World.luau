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

	-- Eight plots, two rows of four, facing each other across the Strip; one per player (Max Players 8). A plot is 200 studs
	-- square and neighbours stand 48 apart (the director, 2026-11-12: "base should be 200"; research's verdict on TR2): the
	-- Festival Door, not the walk, takes a player to the grounds.
	Plots = {
		Count = 8,
		Across = 12.5, -- 200 studs, open onto the Strip
		Deep = 12.5, -- 200 studs: the Breaker at the front, the bays at its sides, the battery between them
		Kept = 1.5, -- 24 studs at the back, kept for the Forge, the Lab and the Condenser (phase 3)
		Between = 3, -- 48 studs between neighbours
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
	-- its Tower: 15.5 s at a 200-stud plot, so the Festival Door is the way in. Then Lantern Row.
	Row = {
		Ground = "lanternrow", -- the ground this street is (Definitions.Grounds): its keeper's win counts there
		Wide = 2.75, -- 44 studs between the stall fronts (research's verdict on TR2, 2026-11-12)
		FirstPack = 2, -- from the gate to the first pack, in view of it
		Spacing = 5, -- 80 studs from stop to stop, past the lead's leash (Config.Combat.Lead.Leash)
		-- The street's rhythm, from the gate: three packs, the elite's square, three packs, the keeper's gate.
		-- Levels: the builder's seeds (tier 2, for research), 2026-11-12. Pack 2 at level 1 is research's second lever for a
		-- new account's first fights (its verdict on TR2, 2026-11-12: no down before the elite, an early pack in 15 to 20 s).
		Stops = {
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 1 },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 1 },
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
		Respawn = 15, -- seconds after a pack's last Shade falls until it's back (the builder's seed, 2026-11-12)
		-- TR10 (the director, 2026-11-14: "mini boss/boss need a server cooldown", the keeper's "Per player"): seconds before
		-- the elite and the keeper are back (Rules.Cooldown). The elite's is the server's, from its fall, since its fight is
		-- shared; the keeper's is each player's own, from their win, kept with their save (a lost try may try again at
		-- once). Research's seeds (tier 2), tuned by playing.
		Back = { Elite = 120, Keeper = 300 },
	},

	-- How the grey build stands up: studs, not times.
	Grey = {
		Floor = 1, -- the ground slab's thickness
		Wall = 10, -- the stall fronts' and the gates' height
		Copies = 600, -- how far apart the keeper's ring copies stand, one per plot, out of sight
		CopiesAt = 3000, -- studs east of the crossing the first copy stands
		-- The Festival Door: its way of light, Wide by High, in a frame. On a plot it stands DoorAt studs right of the
		-- Breaker's line and level with it; at a ground's gate, AtGate studs inside it, against the east stall front. A plot's
		-- door sets the player down Landing studs before the gate, facing through it: out of the lead's leash of the first
		-- pack (Combat.Lead.Leash), so the arrival is a look up the street before the first fight.
		-- HomeWay: the door home's way, in the ground's look, is lit by the street, no brighter than its lanterns (research's
		-- read of TR8's round 1, 2026-11-14: a Neon block outshone them at the gate); its dressing waits for the door pass.
		Door = { Wide = 6, High = 9, DoorAt = 34, AtGate = 10, Landing = 4, HomeWay = "SmoothPlastic" },
		-- The Training machine (TR12): left of the Breaker, as the door is right of it (DoorAt), a box Size, and its pad
		-- Spot studs behind it on the spawn's side, where a fallen lead comes home, facing the machine.
		Training = { Size = Vector3.new(6, 4, 5), Spot = 6 },
		-- The generator (TR18): between the Breaker and the Training machine it feeds, At studs left of the Breaker's
		-- line and level with it, a box Size, taller than both, so the plant's heart reads from the spawn. Its spot
		-- stands more than BaseController's near (13 studs) from every other: a player at one hears only that one.
		-- Its rotor (AR15) turns PerKw turns a second for each kW its owner's plant generates, at most Most, still at none.
		Generator = { Size = Vector3.new(6, 8, 5), At = -17, Rotor = { PerKw = 0.02, Most = 2 } },
	},
}
