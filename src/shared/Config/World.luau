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
		Deep = 12.5, -- 200 studs. Where each machine stands is the base plan's layout (Config.Kits.Base, AR16)
		Kept = 1.5, -- 24 studs at the back, kept for the Forge, the Lab and the Condenser (phase 3)
		Between = 3, -- 48 studs between neighbours
		Behind = 1, -- 16 studs of path behind a plot, then its Tower
		Tower = 2, -- the Tower's footprint, 32 studs, left empty (phase 3)
		-- The size the base plan's layout and its floor pictures are drawn for (AR16). A plot of another size stands grey,
		-- on Fit's layout for its size: part 7's trial.
		Drawn = 12.5,
	},

	-- The base's three sizes in grey (docs/research/rework-2026-11-16.md, part 7): 128, 144 and 160 studs square, 32
	-- between neighbours, tried from the player's camera before anything is drawn. NL_Debug:Invoke("BaseSize", nil, 144)
	-- lays the plots at one (Rules.BaseFit's report with it); ("BaseSize") puts today's back.
	-- The tests (Rules.BaseFit): Breaker, seconds from the gate at most; Clear, studs between any two footprints at least
	-- (part 7: "no machine within 12 studs of another's front"; the grey boxes have no front, so every side); Avenue, the
	-- way in clear down the middle (AR16's 20); Apron, studs from the gate to the nearest machine; Margin, from the
	-- square's edge; Camera, the player's, Back studs behind the gate looking in, its vertical Fov at a 16:9 screen's
	-- Aspect, the narrower landscape.
	Fit = {
		Sizes = { 8, 9, 10 },
		Between = 2,
		Breaker = 4,
		Clear = 12,
		Avenue = 20,
		Apron = 16,
		Margin = 4,
		Camera = { Back = 12.5, Fov = 70, Aspect = 16 / 9 },
		-- Each machine's real footprint (Rules.BaseFit.Kind), measured from the laid kit at 200 studs, 2026-11-16: its
		-- middle's offset from its spot, its size across and inward, its height. The machines keep their size at every
		-- size of plot ("recomposed, never scaled").
		Prints = {
			generator = { Across = -0.75, Inward = 3.75, Wide = 24.9, Deep = 28.9, High = 24.2 },
			breaker = { Across = 4, Inward = 0, Wide = 24.8, Deep = 6.8, High = 12.9 },
			door = { Across = 0, Inward = 0, Wide = 3, Deep = 12.4, High = 14.7 },
			bay = { Across = 0, Inward = 0, Wide = 10.3, Deep = 11.4, High = 10.3 },
			later = { Across = 0, Inward = 0, Wide = 10.3, Deep = 10.2, High = 1.6 },
			battery = { Across = 0, Inward = 0, Wide = 6.6, Deep = 4.6, High = 3 },
			training = { Across = 0, Inward = -2.5, Wide = 6.2, Deep = 11.2, High = 9.1 },
			stone = { Across = 0, Inward = 0, Wide = 9.2, Deep = 9.2, High = 1.6 },
		},
		-- AR16's star at each size, the plan's shape: the generator at the heart, the Breaker and the Door on the slants
		-- toward the gate, level 1's bays at the bus's ends and the later ones past them, the battery and the Training
		-- machine on the back slants, the Forge, the Condenser and the Lab asleep behind. The builder's grey re-lay: the
		-- nearest to AR16 scaled to the size that passes every test (a search, 2026-11-16). Modulo re-lays the
		-- chosen one for real (part 7).
		Layouts = {
			["128"] = {
				spawn = { across = 0, inward = 8 },
				stations = {
					generator = { across = 0, inward = 47 },
					breaker = { across = 19, inward = 20 },
					door = { across = -25, inward = 23 },
					battery = { across = 29, inward = 73 },
					training = { across = -29, inward = 73 },
					bay1 = { across = -31, inward = 47 },
					bay2 = { across = 31, inward = 47 },
				},
				laterBays = { { across = -54, inward = 47 }, { across = 54, inward = 47 }, { across = -54, inward = 70 }, { across = 54, inward = 70 } },
				sleeping = { forge = { across = -23, inward = 94 }, condenser = { across = 23, inward = 94 }, lab = { across = 0, inward = 88 } },
			},
			["144"] = {
				spawn = { across = 0, inward = 8 },
				stations = {
					generator = { across = 0, inward = 52 },
					breaker = { across = 19, inward = 25 },
					door = { across = -25, inward = 27 },
					battery = { across = 29, inward = 78 },
					training = { across = -29, inward = 78 },
					bay1 = { across = -36, inward = 52 },
					bay2 = { across = 36, inward = 52 },
				},
				laterBays = { { across = -59, inward = 52 }, { across = 59, inward = 52 }, { across = -59, inward = 78 }, { across = 59, inward = 78 } },
				sleeping = { forge = { across = -26, inward = 99 }, condenser = { across = 26, inward = 99 }, lab = { across = 0, inward = 98 } },
			},
			["160"] = {
				spawn = { across = 0, inward = 8 },
				stations = {
					generator = { across = 0, inward = 58 },
					breaker = { across = 21, inward = 31 },
					door = { across = -25, inward = 34 },
					battery = { across = 29, inward = 83 },
					training = { across = -29, inward = 83 },
					bay1 = { across = -42, inward = 58 },
					bay2 = { across = 42, inward = 58 },
				},
				laterBays = { { across = -66, inward = 58 }, { across = 66, inward = 58 }, { across = -66, inward = 87 }, { across = 66, inward = 87 } },
				sleeping = { forge = { across = -29, inward = 106 }, condenser = { across = 29, inward = 106 }, lab = { across = 0, inward = 109 } },
			},
		},
	},

	-- The Strip: plots on both sides, a crossing one plot wide at its middle, the Shop south of it, the side street north.
	Strip = {
		Wide = 3, -- 48 studs
		Ends = 5, -- past the last plots, kept for the Calamity and the Clash Grounds (phase 5)
	},

	-- The side street runs from the crossing between the Towers to the festival gate: a plot's depth, its path behind and
	-- its Tower: 15.5 s at a 200-stud plot, so the Festival Door is the way in. Then Lantern Row.
	-- The names a place says of itself (TR24's fix 10; SignsController): the player's Festival Door, its name and its
	-- ground under it (docs/design.md, "The Festival Door"), and the festival gate, its ground's name to the side street.
	-- Width and Line in authored pixels; Reach studs from the camera (the gate's, past the 35 studs TR24's still saw it
	-- from). A sign never covers the landmark it names (research's must-fix on AR15, 2026-11-17): it stands beside it, Gap
	-- authored pixels off its side, level with its middle on the screen. Over the arch, under the top band, it was pushed
	-- down onto the Door from every distance in its reach (the builder's measure, 2026-11-17: 32 to 100% of the sign over
	-- the Door). The builder's seeds.
	-- The Door's name is also written on its own plate, on the front ring's crown (AR15, section 7: research's fix 3,
	-- the name's plate belongs to the ring): Plate, in the Door's warm light, unlit by the world (LightInfluence 0),
	-- PixelsPerStud on the plate's 5 by 1.3, Pad studs in from each edge, seen within Reach studs (the builder's seeds).
	-- While it reads, the Door's sign steps away, so the name isn't said twice: the camera within Reads studs of the
	-- plate, in front of its face past Facing (the cosine), the plate on screen. The game's camera rides about 12 studs
	-- behind the avatar, so the way in at 18 studs is about 29 from the plate, where its name reads small but clear on a
	-- phone (the builder's seeds, measured in AR15).
	Signs = {
		Door = {
			Name = "Festival of Battles",
			Width = 200,
			Line = 22,
			Gap = 16,
			Reach = 90,
			Plate = { Colour = "#FFD49A", Brightness = 1.2, PixelsPerStud = 80, Pad = 0.12, Reach = 60, Reads = 36, Facing = 0.35 },
		},
		Gate = { Width = 160, Line = 24, Gap = 16, Reach = 120 },
	},
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
		-- The Festival Door: its way of light, Wide by High, in a grey frame. On a plot it stands where the base plan's
		-- layout says, and wears its kit's Door, the ring tunnel (AR15, section 7). In the Door's own frame (its origin the
		-- step's middle on the floor, +Z out of its mouth): the Way a player walks into fills the front ring's opening, a
		-- square round 5.6 up and through its depth, from -0.6 to 1.0, so it never touches a player walking past the stone.
		-- The mesh's opening is a circle of radius 5, and the Door's collision (Default: the precise one shuts the opening)
		-- comes within 4.8 of its middle, so the square's corner stays at 4.53. The Name is the plate's face toward the way
		-- in, where the client writes the name (Config.World.Signs.Door.Plate), just proud of the face at 1.4. At a ground's
		-- gate it stands AtGate studs
		-- inside it, against the east stall front. A plot's door sets the player down Landing studs before the gate, facing
		-- through it: out of the lead's leash of the first pack (Combat.Lead.Leash), so the arrival is a look up the street
		-- before the first fight.
		-- HomeWay: the door home's way, in the ground's look, is lit by the street, no brighter than its lanterns (research's
		-- read of TR8's round 1, 2026-11-14: a Neon block outshone them at the gate); its dressing waits for the door pass.
		Door = {
			Wide = 6,
			High = 9,
			AtGate = 10,
			Landing = 4,
			HomeWay = "SmoothPlastic",
			Way = { Size = Vector3.new(6.4, 6.4, 1.6), At = Vector3.new(0, 5.6, 0.2) },
			Name = { Size = Vector2.new(5, 1.3), At = Vector3.new(0, 12.3, 1.43) },
		},
		-- The Training machine (TR12), where the layout says: a box Size while its kit isn't laid, and its pad Spot studs
		-- before it toward the gate (the kit's pad, AR15, section 5), where a fallen lead comes home, facing the machine.
		-- Its crown turns Crown turns a second about its upright while a Voidkin trains (the builder's seed).
		Training = { Size = Vector3.new(6, 4, 5), Spot = -6, Crown = 0.12 },
		-- The generator (TR18) at the plot's heart, where the layout says: a box Size while its kit isn't laid. Its spot
		-- stands more than BaseController's near (13 studs) from every other: a player at one hears only that one.
		-- The Void Mill (AR19, Stage I): its wheel turns Least turns a second and PerKw more for each kW its owner's plant
		-- generates, at most Most, still at none; heavy, never a spin (the builder's seed, tuned by playing).
		-- Its gauge (Rules.Power.Gauge): Steps lit steps up the rising side are the generation, and the demand's mark rides
		-- the rail on the same scale, Turn degrees about the axle from its foot to its top (the rail's arc, Modulo's). The
		-- scale's top is the larger of the two over Fill, never under Floor kW, so the mark and the lit steps meet when
		-- generation meets demand and a small plant reads small (the builder's seed). The mark glides to its place over
		-- Glide seconds.
		Generator = {
			Size = Vector3.new(6, 8, 5),
			Wheel = { Least = 0.03, PerKw = 0.002, Most = 0.18 },
			Gauge = { Steps = 8, Floor = 60, Fill = 0.85, Turn = 117.9, Glide = 0.6 },
		},
	},
	-- A bay at work (TR24's fix 1; AR16's rarity light): its worker stands in the ring, Hip studs over the bay's floor (an R6
	-- body's root), facing the bay's front, playing its rig's Idle; the ring's BayHalo stands lit in the worker's rarity colour
	-- (Config.Reveal's Words) in Neon, with one PointLight of that colour. An empty bay shows its frame and ring, unlit.
	Bay = { Hip = 3, Light = { Range = 12, Brightness = 1.5 } },
}
