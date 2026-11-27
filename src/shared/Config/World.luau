--!strict
-- World (shared Config): research's layout for TR2 in grey (docs/design.md, "The world, in grey"), as WorldService lays it
-- when the place holds no authored world. Times are the design and studs follow them: a length in seconds is walked at
-- Walk, so a change of walk moves the studs and keeps the times. Tuned live, and the grey world is laid again:
-- NL_Debug:Invoke("Tune", "World.Row.Spacing", 6).

-- One stop down Lantern Row. Kind: Pack (Count Shades), Elite or Keeper.
-- Stage: the stage it belongs to (Config.Stages, TR43). Square: the elite stands in the square (one stop at most).
-- With: a pack's others (AR52), Count of its Count Shades of that Def, spread through its ring (Rules.Fight.PackDefs).
-- Hard: the Def that stands there on Hard in its place (AR57; Rules.Stages.DefOn).
export type Stop = { Kind: string, Def: string, Level: number, Count: number?, Stage: number, Square: boolean?, With: { Def: string, Count: number }?, Rear: { Def: string, Count: number }?, Hard: string?, Waves: { { { [string]: any } } }? }

return {
	Walk = 16, -- studs a second the times are worked at: Roblox's default walk
	-- Seconds a new avatar opens from black on its plot's spawn, the camera turned behind it (WorldService, FadeController):
	-- joining, or a reset. The builder's, 2026-11-12.
	Arrive = 0.4,

	-- What the world doesn't lay of the kits' plans (AR65, the base made simpler: research's pick of the cut pass, 2026-11-26),
	-- by a placement's or a light's name: the base's grid (its pylons, spans and transformers), its two flood masts and their
	-- pools, the Strip's far shards on the skyline, the yard's lit floor and rings at levels 2 and 3, the bays' wakes, and
	-- "Lab", the Lab's sleeping place. Then the battery, folded into the Mill (its charge stays on the HUD and the Power
	-- screen), and the Forge, out of the yard at launch: Reinforce lives in Equipment, and the Forge comes back with its
	-- own use after launch, or at once if the director says it stays (take its three out of here). Modulo's rebuilt kit
	-- (AR65, step 3) drops the rest from its plans; then this holds only what waits to come back.
	Cut = {
		Pylon = true, PowerSpan = true, Transformer = true, FloodMast = true, FloodLeft = true, FloodRight = true,
		FarShardLow = true, FarShardMid = true, FarShardTall = true,
		LevelFloor = true, LevelRays = true, LevelRing = true, LevelRingOuter = true, BayWake3 = true, BayWake4 = true,
		Lab = true,
		BatteryRack = true, BatteryRack2 = true, BatteryRack3 = true, BatteryCell = true,
		Forge = true, ForgeRam = true, ForgeGear = true,
	} :: { [string]: boolean },

	-- Eight plots, two rows of four, facing each other across the Strip; one per player (Max Players 8). A plot is 200 studs
	-- square and neighbours stand 48 apart (the director, 2026-11-12: "base should be 200"; research's verdict on TR2): the
	-- Festival Door, not the walk, takes a player to the grounds.
	Plots = {
		Count = 8,
		-- 128 studs square (research's verdict of 2026-11-17, 12:01, on part 7's trial; AR16; the plan laid for Stage III by
		-- AR54). 144 is the written fallback (docs/design.md).
		Across = 8, -- 128 studs, open onto the Strip
		Deep = 8, -- 128 studs. Where each machine stands is the base plan's layout (Config.Kits.Base, AR16)
		Kept = 1.5, -- 24 studs at the back, kept for the Forge, the Lab and the Condenser (phase 3)
		Between = 2, -- 32 studs between neighbours
		Behind = 1, -- 16 studs of path behind a plot, then its Tower
		Tower = 2, -- the Tower's footprint, 32 studs, left empty (phase 3)
		-- The size the base plan's layout and its floor pictures are drawn for (AR16; AR54 at Stage III).
		Drawn = 8,
	},

	-- Part 7's tests for the base's plan (docs/research/rework-2026-11-16.md, part 7; Rules.BaseFit), on the plan's own
	-- layout (Config.Kits.Base, `layout`; AR54's lay for Stage III, 2026-11-23). The trial of three sizes chose 128
	-- (research, 2026-11-17) and is over. NL_Debug:Invoke("BaseSize") answers the plan's line.
	-- The tests: Breaker, seconds from the gate at most; Clear, studs between any two footprints at least (part 7: "no
	-- machine within 12 studs of another's front"; a box has no front, so every side); Avenue, the way in clear down the
	-- middle (AR16's 20); Apron, studs from the gate to the nearest machine; Margin, from the square's edge; Camera, the
	-- player's, Back studs behind the gate looking in, its vertical Fov at a 16:9 screen's Aspect, the narrower landscape.
	Fit = {
		Breaker = 4,
		Clear = 12,
		Avenue = 20,
		Apron = 16,
		Margin = 4,
		Camera = { Back = 12.5, Fov = 70, Aspect = 16 / 9 },
		-- Each machine's footprint at Stage III, its widest (Rules.BaseFit.Kind): its middle's offset from its spot, its size
		-- across and inward, its height, measured on the handoff's meshes as the plan stands and turns them
		-- (`py tools/blender/base_fit.py prints`, 2026-11-23). The Door's is its only stage, turned as it stands; the Lab's is
		-- its sleeping stone. A sleeping bay is held to a bay's, since it wakes into one.
		Prints = {
			generator = { Across = -0.72, Inward = 3.72, Wide = 30.24, Deep = 28.86, High = 27.12 },
			breaker = { Across = 7.0, Inward = -1.52, Wide = 34.58, Deep = 9.87, High = 20.17 },
			door = { Across = -1.59, Inward = 0, Wide = 8.61, Deep = 14.22, High = 13.06 },
			bay = { Across = -0.07, Inward = 0, Wide = 10.36, Deep = 11.74, High = 15.74 },
			battery = { Across = 0, Inward = 0, Wide = 6.52, Deep = 4.52, High = 13.43 },
			training = { Across = 0, Inward = -1.62, Wide = 9.75, Deep = 12.98, High = 10.37 },
			forge = { Across = 0, Inward = 0, Wide = 11.08, Deep = 8.82, High = 14.51 },
			condenser = { Across = 0, Inward = 0.25, Wide = 11.61, Deep = 9.31, High = 11.79 },
			lab = { Across = 0, Inward = 0, Wide = 9.22, Deep = 9.22, High = 1.44 },
		},
	},

	-- The Strip: plots on both sides, a crossing one plot wide at its middle, the Shop south of it, the side street north.
	Strip = {
		Wide = 3, -- 48 studs
		Ends = 5, -- past the last plots, kept for the Calamity and the Clash Grounds (phase 5)
	},
	-- The boards on the Strip (TR58; Config.Boards): four plates on the Shop's side of the crossing, at the Shop's flanks,
	-- facing the Strip, read by a player coming back from the side street. At: each plate's middle across the crossing,
	-- in Config.Boards.Order, from the viewer's left (+x) to right; Out: studs from the Strip's edge onto the Shop's floor;
	-- each Wide by High studs, its foot Lift over the paving on a stand. A grey block, the builder's seeds, set from the
	-- player's camera; the boards' art waits for research's verdict (Modulo, an AR).
	Boards = { At = { 52, 36, -36, -52 }, Out = 8, Wide = 14, High = 9, Lift = 2.5, Deep = 0.8 },

	-- The side street runs from the crossing between the Towers to the festival gate: a plot's depth, its path behind and
	-- its Tower: 15.5 s at a 200-stud plot, so the Festival Door is the way in. Then Lantern Row.
	-- The names a place says of itself (TR24's fix 10; SignsController): the festival gate, its ground's name to the side
	-- street. Width and Line in authored pixels; Reach studs from the camera (the gate's, past the 35 studs TR24's still
	-- saw it from). A sign never covers the landmark it names (research's must-fix on AR15, 2026-11-17): it stands beside
	-- it, Gap authored pixels off its side, level with its middle on the screen. The builder's seeds.
	-- The player's Festival Door has its Name written on its own plate, on the front ring's crown (AR15, section 7:
	-- research's fix 3, the name's plate belongs to the ring): Plate, in the Door's warm light, unlit by the world
	-- (LightInfluence 0), PixelsPerStud on the plate's 5 by 1.3, Pad studs in from each edge, seen within Reach studs (the
	-- builder's seeds). Where it goes, its ground's name, stands over it in the machines' plate (BaseController; AR65's
	-- verdict, must-fix 2: a screen sign beside it stood over the lead and said the ring's name again).
	Signs = {
		Door = {
			Name = "Festival of Battles",
			Plate = { Colour = "#FFD49A", Brightness = 1.2, PixelsPerStud = 80, Pad = 0.12, Reach = 60 },
		},
		Gate = { Width = 160, Line = 24, Gap = 16, Reach = 120 },
	},
	Row = {
		Ground = "lanternrow", -- the ground this street is (Definitions.Grounds): its keeper's win counts there
		Wide = 2.75, -- 44 studs between the stall fronts (research's verdict on TR2, 2026-11-12)
		FirstPack = 2, -- from the gate to the first pack, in view of it
		Spacing = 5, -- 80 studs from stop to stop, past the lead's leash (Config.Combat.Lead.Leash)
		-- The street's rhythm, from the gate, in TR43's four stages (Config.Stages reads its stages from here): Stage 1, a
		-- pack and its elite in the street; Stage 2, a pack and the elite's square; Stage 3, two packs and its elite in the
		-- street; Stage 4, the keeper's gate. Eight stops at the kit's eight places (Config.Kits.LanternRow's plan), so its
		-- dressing still fits; each stage's gate stands between its last stop and the next stage's first. Levels: the
		-- builder's seeds (tier 2, for research), 2026-11-18; the first pack at level 1 keeps research's lever for a new
		-- account's first fight (its verdict on TR2, 2026-11-12), four to a pack where a stage has one. Each stretch asks
		-- its own question (AR52, research's seeds; how many of each, the builder's, tuned in play): Brawlers alone, Red; with
		-- Guards, Green; with Dashers, Orange; then the Lamplighter, Purple. The square holds the Guard's elite on Normal and
		-- the Dasher's on Hard (AR57, research's seed, tuned in play). A pack's Rear stand in a row at its back, past its ring
		-- (Rules.Fight.PackSpots): AR58's Support behind stage 3's second pack, the builder's seed (tier 2, for research).
		Stops = {
			{ Kind = "Pack", Def = "brawler", Count = 4, Level = 1, Stage = 1, Waves = {
				{ { Def = "brawler", Count = 3, Back = true } }, -- their backs turned
				{ { Def = "brawler", Count = 4, From = "Sides" } }, -- two from each side
				{ { Def = "brawler", Count = 3, Type = "Blue" } }, -- of another type
			} },
			{ Kind = "Elite", Def = "brawler_elite", Level = 2, Stage = 1 },
			{ Kind = "Pack", Def = "brawler", Count = 4, Level = 3, Stage = 2, With = { Def = "guard", Count = 2 }, Waves = {
				{ { Def = "guard", Count = 1 } }, -- alone, facing the player
				{ { Def = "guard", Count = 2, Row = "Front" }, { Def = "brawler", Count = 2, Row = "Back" } },
				{ { Def = "guard", Count = 3, Row = "Front" }, { Def = "brawler", Count = 2, Row = "Back" } }, -- raising in turn
			} },
			{ Kind = "Elite", Def = "guard_elite", Level = 5, Stage = 2, Square = true, Hard = "dasher_elite" },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 6, Stage = 3, With = { Def = "dasher", Count = 1 }, Waves = {
				{ { Def = "dasher", Count = 1, From = "Far" } }, -- alone, far up the street
				{ { Def = "brawler", Count = 2, Row = "Front" }, { Def = "dasher", Count = 1, Row = "Back" } },
			} },
			{ Kind = "Pack", Def = "brawler", Count = 3, Level = 7, Stage = 3, With = { Def = "dasher", Count = 1 }, Rear = { Def = "support", Count = 1 }, Waves = {
				{ { Def = "dasher", Count = 2, From = "Alleys" } }, -- from the two alleys, their lines crossing
				{ { Def = "guard", Count = 1, Row = "Front" }, { Def = "dasher", Count = 1 }, { Def = "brawler", Count = 2 }, { Def = "support", Count = 1, Rear = true } },
			} },
			{ Kind = "Elite", Def = "brawler_elite", Level = 8, Stage = 3 },
			{ Kind = "Keeper", Def = "lamplighter", Level = 9, Stage = 4 },
		} :: { Stop },
		GateSet = 6, -- studs before a shut stage gate a player who crossed it is set down, facing back into its stage
		Square = 4, -- the elite's square, 64 studs across, so anyone near can join
		Ring = 5, -- the Lamplighter's ring, 80 studs across, behind the keeper's gate
		Beyond = 1.5, -- from the ring's far edge to Drum Court's gate, shut, in view
		Spread = 7, -- studs between a pack's Shades at its spawn (inside Combat.Shade.Notice, so one notices for all)
		-- studs to the side of the Door landing (its Arrival pad, 6 wide) a fallen lead heals at in the Festival, which has no
		-- plot (docs/design.md, "A fall in the Festival"; FightService's homeSpot). The builder's.
		LeadAside = 5,
		-- studs a pack's Rear row stands past its ring's back (AR58's Support; the builder's seed): a Spread, so none of its
		-- Shades stands nearer another than its ring's do
		Behind = 7,
		Respawn = 15, -- seconds after a pack's last Shade falls until it's back (the builder's seed, 2026-11-12)
		-- The street in waves (TR69 B, research's seeds, tuned by playing): each Pack stop's Waves, in order. The next steps
		-- out Gap seconds after its stop's last Shade falls, its stall fronts marked in grey for the Tell before it; a list
		-- run out starts again from its second wave while a player within Near studs of the stop still owes the stretch's
		-- quota, and nobody near waits past the Gap. With nobody near owing, the stop rests and stands its first wave again
		-- after Respawn, or at once, after a Tell, when someone who owes comes near. A wave stood while someone near owes
		-- steps out at their leads (PackService; FightService.Rouse). Off, a pack stands its ring as before. On since the
		-- pace was measured in the Festival place (PaceCases, 2026-11-26): standing 66.1 s in the run Off, 14.5 s On,
		-- under the gate's 20.
		Waves = { On = true, Gap = 2.5, Tell = 1, Near = 90, Far = 26, Side = 20 },
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
		-- The stages' moving parts (TR51; AR32, AR33), turns a second about their own axles (the builder's seeds): the
		-- Breaker's jaw hinges while any chamber breaks, a bay's toothed rings while a worker works there, the outer
		-- one at its teeth's ratio to the inner's (16 to 22), each the way its row's sign says.
		Hinge = 0.2,
		Cog = 0.12,
		CogOuter = 0.12 * 16 / 22,
		-- The generator (TR18) at the plot's heart, where the layout says: a box Size while its kit isn't laid. Its spot
		-- stands more than BaseController's near (13 studs) from every other: a player at one hears only that one.
		-- Its model (AR67): its core turns about its upright Least turns a second and PerKw more for each kW its owner's
		-- plant generates, at most Most, still at none (the old wheel's numbers, Modulo's contract; tuned by playing).
		-- Its gauge (Rules.Power.Gauge): Steps lit steps up the column are the generation, and the collar rides the column
		-- on the same scale, its row's studs from its foot to its top. The scale's top is the larger of the two over Fill,
		-- never under Floor kW, so the collar and the lit steps meet when generation meets demand and a small plant reads
		-- small (the builder's seed). The collar glides to its place over Glide seconds.
		Generator = {
			Size = Vector3.new(6, 8, 5),
			Core = { Least = 0.03, PerKw = 0.002, Most = 0.18 },
			Gauge = { Steps = 8, Floor = 60, Fill = 0.85, Glide = 0.6 },
		},
	},
	-- A bay at work (TR24's fix 1; AR16's rarity light): its worker stands in the ring, Hip studs over the bay's floor (an R6
	-- body's root), facing the bay's front, playing its rig's Idle; the ring's BayHalo stands lit in the worker's rarity colour
	-- (Config.Reveal's Words) in Neon, with one PointLight of that colour. An empty bay shows its frame and ring, unlit.
	Bay = { Hip = 3, Light = { Range = 12, Brightness = 1.5 } },
	-- The Forge (TR37; AR28's Press, Stage I, in its sleeping place): a Reinforce try struck on its ram, seconds, every
	-- client's. Anticipation: the ram lifts from rest to its tell over Lift, easing out; the strike: down to the plate over
	-- Strike, easing in; hitstop: it holds on the plate for Hold; then it settles back to rest over Back. Its gears turn with
	-- its travel (the plan's degreesPerStud). Seeds, tuned by playing.
	Forge = { Lift = 0.16, Strike = 0.06, Hold = 0.07, Back = 0.34 },
	-- The Stone Condenser (TR37; AR28's Comb, Stage I): its core turns Core turns a second at full power while it works,
	-- slower with less power and still when it rests. Its tray's cups light by the tray's fill of its cap, so a full tray
	-- lights the whole comb (37 cups at Stage I over a cap of 12 at level 1: the builder's, TR37). Cradle: the top of
	-- AR28's cradle on the Comb's front corner (tools/blender/base_forge.py, `cradle(m, -3.0, 3.2)`), across, toward the
	-- gate and up in the Condenser's own frame: the convert's prompt stands there, and its card beside it (AR51's B,
	-- Config.Hud.Convert), in place of TR37's grey block-in.
	Condenser = {
		Core = 0.2,
		Cradle = { -3.0, 3.2, 1.2 },
	},
	-- TR22's showcase (TR51 step 3): the owner's Voidkin (Collection.Showcase: the one picked, else the strongest) stands at
	-- the plinth's middle, Up over the piece's foot, its root Hip over that, facing the Strip and turning Turn turns a
	-- second (the client's; the plinth doesn't turn), playing its rig's Idle. Its CR rides Above its root, a BillboardGui
	-- Size studs across, read to Far studs, in Ink with a Shade stroke. Seeds, judged from the Strip.
	Showcase = {
		Up = 1.2,
		Hip = 3,
		Turn = 0.08,
		Above = 4.4,
		Size = { 6, 1.5 },
		Far = 160,
		Ink = Color3.fromHex("#F6FCFF"),
		Shade = Color3.fromHex("#14101E"),
		-- its power label fades out over Fade seconds while its box on the screen crosses the lead's plate, from any
		-- camera, and back once clear (research's must-fix 1 on AR68 A, 2026-11-27: it stood half over the blade's top)
		Under = { Fade = 0.15 },
	},
	-- The gate's plate (TR22): the owner's display name over the base's level ("Level n", in Power's yellow, as the plan's
	-- level mark asks), on both faces, each line Share of the plate's height. Seeds, judged from the Strip.
	Plate = {
		Name = { Share = 0.5, Ink = Color3.fromHex("#F6FCFF") },
		Level = { Share = 0.36, Ink = Color3.fromHex("#FFD23E") },
	},
}
