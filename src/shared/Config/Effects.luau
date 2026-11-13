--!strict
-- Effects (shared Config): the look of the signature effects, from the asset maker's art sheets, played by the client's
-- FighterController/Effects. Frames are the clip's, 60 a second; distances in studs. Tuned live in a playtest:
-- NL_Debug:Invoke("Tune", "Effects.Haymaker.Hero.Reach", 9).

return {
	-- Rook's Haymaker (docs/asset-requests.md, AR1, section 5; tools/blender/rook_haymaker_art.py): one bar, drawn once, for
	-- the charge's square, the strike's square, the thrown bracket and the floor's two lines, eaten as it cools. While
	-- Stamp.On, B5's grey stamp takes the bracket's and the lines' place.
	Haymaker = {
		-- The bar's eight frames, one under another: the group's upload (docs/asset-log.md); "" plays the grey stand-in.
		Picture = "rbxassetid://82029716338204",
		FrameWidth = 512, -- pixels
		FrameHeight = 128,
		Body = 0.6, -- the share of a frame's height the stroke fills
		Span = 0.92, -- and of its width
		Eaten = { 0, 0.07, 0.16, 0.28, 0.42, 0.57, 0.72, 0.86 }, -- the share gone in each frame; the stand-in shows it as transparency
		Scorch = Color3.new(0.34, 0.26, 0.3), -- a floor line's tint once it cools (the content check: no redder)
		-- The charge: the square forms out of its chips round the ram's face and is drawn tight through the hold.
		Charge = { From = 29, Forms = 8, Held = 5, Side = 2.9, Tight = 1.1, Last = 0.1, Bar = 0.3, Over = 0.5 }, -- frames before Strike; studs
		-- The punctuation: the same square thrown open round the ram, on the Strike frame and the Shock frame.
		Strike = { Side = 3.0, Bar = 0.8, Frame = 0 },
		Shock = { Side = 3.7, Bar = 0.7, Frame = 3 },
		Ahead = 0.3, -- studs down the line from the knuckles the squares stand
		-- The hero: one bracket thrown down the line from the frame after Shock. It snaps out over Fly frames and drifts on
		-- (it never quite stops), then is eaten over Leaves frames as it opens and its feet lift.
		-- The line ends Past the target, so the bracket is eaten round what it hit, at the fight's depth (section 8).
		Hero = {
			Past = 2.5, -- studs past the target's centre the line ends: the frame seen out its near side as the knock carries it
			Reach = 8, -- studs down the line it flies when there's no target
			Fly = 10,
			Drift = 0.004, -- the line's share a frame it drifts once it has flown
			Leaves = 6,
			Opens = 0.06, -- it opens this share as it's eaten
			Lift = 0.3, -- its feet lift this share of its height, by the square of how far it's eaten
			-- Degrees it leans the way it goes, seen side-on; times how side-on the line is to the camera, so a line coming at
			-- the camera stands upright (0 face-on, 1 side-on, by the angle; section 8)
			Lean = 16,
			Width = 2.2, WidthGain = 2.8, -- studs at the knuckles, and gained by the line's end: the target's outline and a margin there
			Height = 2.0, HeightGain = 3.4,
			Bar = 0.85, BarGain = 0.5,
		},
		-- The floor's two lines, scored under the hero's feet in pieces as it passes: hot, then a scorch, eaten from the near end.
		Floor = { Pieces = 6, Hot = 3, Eat = 4, Life = 11, Bar = 0.5, Over = 0.03, Overlap = 0.3 }, -- frames; studs
		-- B5, the stamp, a grey block (docs/asset-requests.md, AR8, "B5"; AR1, section 9; tools/blender/rook_haymaker_stamp.py,
		-- face() lifted). In place of the hero and the floor's lines, a square stood up facing the camera hangs over the
		-- target through the hold, drawn tight. It slams down onto it over Drop frames, stretched tall, and lands on Strike.
		-- It squashes flat on Shock while two bars run out along the floor from its feet, and is eaten where it lies, the
		-- target pinned under it (Actions: Haymaker's push is 0). Frames are counted from Strike; studs from the floor.
		Stamp = {
			On = true, -- false plays A's bracket thrown through the target: a look beside it while B5 is a blockout
			Side = 4.6, -- the square's side: the target's footprint and a margin
			Bar = 0.85,
			Rise = 21, -- frames before Strike it forms over the target's head (the sheet's frame 36)
			Over = 5.6, -- its foot as it forms; and at least Clear over the target's own top, well above the head (the content check)
			Clear = 1,
			-- Its foot at the top of the hang, where it falls from. On a phone at the replay's framing, the sheet's 10 and Modulo's
			-- 8 cut its top off the frame (by 13 px at 8); at 6.4 it stands 28 px inside, under the top bar's buttons.
			Top = 6.4,
			Forms = 0.65, -- its side's share as it forms, and its bar then: drawn tight to Side and Bar
			FormBar = 0.3,
			Drop = 4, -- frames it falls, faster and faster, to land on Strike
			Stretch = 0.35, -- it grows this share taller, and Narrow narrower, as it falls fast
			Narrow = 0.15,
			Squash = { 0.55, 0.3, 0.26, 0.24 }, -- its height, a share of Side, on Strike and each frame after: flat into the floor
			Spread = 1.3, -- its width, a share of Side, on Strike; then Spreads, gaining SpreadGain over 10 frames
			Spreads = 1.55,
			SpreadGain = 0.05,
			Eat = 3, -- frames after Strike it starts to be eaten, and the frames it takes to go
			Eaten = 12,
			Run = { Reach = 4.5, Frames = 8, Life = 9, Width = 0.5 }, -- the floor's two bars: out Reach studs over Frames, gone after Life
			Alone = 6, -- studs ahead of the lead it lands with no target: Haymaker's range
		},
		Sound = "HaymakerStrike", -- the cue on the strike's frame, at the knuckles (Config.Sounds)
		-- The ram's heat (AR1, sections 5 to 7): the glow mask on these pieces, on the clip's markers. Up from Charge to
		-- Strike, held through the hitstop to Shock, out by Vent. The content check's engine looks (section 7) hold the
		-- strength at 5 at most (above it, bloom haloes the ram) and never between 0 and 3 (there the cream band reads
		-- deeper than cold): the effect keeps Peak at 5 and steps 0 to Step at Charge, Step to 0 at Vent.
		Glow = {
			Pieces = { "Rook_RightArm", "Rook_Piston" },
			Peak = 5, -- EmissiveStrength at the strike: research tunes it on the replay, up to the check's 5
			Step = 3, -- where the heat starts at Charge and ends at Vent: the check's floor, held at 3 or above
			Rise = 2, -- the wind-up's curve: it warms slowly, then fast into the strike
			Fall = 2, -- the cooling's, from Shock to Vent: the heat goes out with the bracket, the last of it lingers
		},
	},

	-- Pip's Lantern Burst (docs/asset-requests.md, AR4, sections 7 and 8; tools/blender/pip_burst_art.py): the lantern heats,
	-- is thrown, and lets its flame out over the target. Two pictures, the group's uploads (docs/asset-log.md); the table
	-- the art sheet plays them by is build/handoff/Pip/fx/pip_burst_art.json. Frames are the clip's, from its start.
	LanternBurst = {
		Picture = "rbxassetid://100913199674615", -- twenty cells: the coil's sixteen, the heat's four (AR8 B1)
		-- The flame blown back, uploaded turned a quarter (its tongues the top row, its head the bottom): a Beam runs its
		-- picture's height along it (handbook/visuals/vfx-engine-facts.md, "Beam"). 93148687324383 was the same picture sideways.
		TrailPicture = "rbxassetid://105763467007985",
		-- The sheet: cells 0 to 11 are Big pixels square, Across to a row from the top; the rest are Small, in one row at
		-- SmallTop, from the left.
		Sheet = { Big = 256, Across = 4, Bigs = 12, Small = 128, SmallTop = 768 },
		-- The burst, from the Burst beat: one picture Size studs square for each stud of the hit's Area, its foot on the
		-- ground under where the lantern stops. Frames each cell holds: the leap (cells 0 to 3), the boil (4 to 7, played
		-- BoilPlays times), the end (8 to 15). Research's lever if the boil reads as one card held still: Boil 1, BoilPlays 2.
		Burst = { PerArea = 3, Leap = 1, Boil = 2, BoilPlays = 1, End = 2, Back = 0, Brightness = 1 }, -- Back: studs away from the camera
		-- The heat, on the lantern from Heat to the Burst: cells 16 to 19, PerCell frames each; its size eased between the
		-- keys (frame, studs), its belly (that share of its height up from its foot) on the lantern's middle.
		Heat = {
			First = 16,
			PerCell = 2,
			Keys = { { 8, 1.0 }, { 30, 1.9 }, { 45, 2.8 }, { 51, 3.2 }, { 65, 2.6 } },
			Belly = 0.1933,
			Brightness = 1,
		},
		-- The trail, from the frame after Send to Close frames after the Burst: a beam from where the lantern was Lag frames
		-- back (never before Send) to the lantern; from the Burst its tail closes onto it.
		Trail = { Lag = 15, Close = 5, Width0 = 0.6, Width1 = 2.4, Brightness = 1 },
		-- The lantern's glow mask (Pip_Lamp): Cold at rest, up to Hot from Heat to Send on the curve u^Curve, held through
		-- the flight, dark from the Burst. Then the readout (research's tier 2, AR4, section 7): dark until the clip ends,
		-- it relights to Cold over the rest of the cooldown, full when the signature is ready, on the curve u^Relight. Research's
		-- verdict (AR4, section 8): 0.5, so it's lit again by mid-cooldown, not dim for most of a fight.
		Glow = { Cold = 1.2, Hot = 3.0, Curve = 1.6, Relight = 0.5 },
		-- The throw's length follows the target: the clip throws the lantern from where it is at Send to Flight studs ahead
		-- of him, which stops Short of a target Short + Flight away. Nearer or further, its flight from Send (handed back
		-- between Return and the clip's end) is scaled to stop Short of the target, between Min and Max of the clip's.
		Throw = { Flight = 12, Short = 1.5, Min = 0, Max = 1.25 },
	},
	-- Pip's shots (PipCombo) and Lyric's (LyricCombo): a grey block, the builder's. A streak from the lantern, or from a
	-- speaker's ring, to the target on each shot's beat, Life seconds; a heavy shot's is wider. Speakers: the rings each of
	-- Lyric's shots fires from (AR4, section 6: she stamps the base and the right one fires, cuts her free hand at you and
	-- the left one fires, then drives the stand down and both fire).
	Shot = {
		Width = 0.2,
		Heavy = 0.45,
		Life = 0.12,
		Speakers = { Shot1 = { "RingR" }, Shot2 = { "RingL" }, Shot3 = { "RingR", "RingL" } } :: { [string]: { string } },
	},

	-- Lyric's Held Note (LyricHeldNote): AR4's art sheet (section 10; build/handoff/Lyric/fx/lyric_note_art.json) on the
	-- block's motion (section 9; research, 2026-11-12: Ease 2 stays, the table's punch and drift isn't used).
	-- The motion: on each beat that hits, a crest is thrown from her rings across the hit's whole cone (its Cone degrees
	-- either side of the line to her target, round its Apex behind her), fast then slowing on the curve 1 - (1 - u)^Ease,
	-- out to the hit's Reach from her. It lives until the next is halfway out (the gap to the next beat, times 2^(1/Ease)).
	-- Its band's middle stands Up studs over the floor at From studs out, Tall high; a stud further out it falls Fall and
	-- grows Grow.
	-- The look by the crest's age (the table's): each crest is two Beams on its arc's two ends, bent into the arc by their
	-- CurveSize, the ribbon over the veil. It's born unseen over its first Birth studs, out of the rings' flash; over its
	-- last Thin it fades to nothing and loses Narrow of its height. The veil holds VeilHold frames after the throw, then
	-- falls away over VeilFade. Width scales the band's height: research's live lever on the crest's size (section 10).
	-- The flash, on each ring: it swells from Swell[1] to Swell[2] studs over Charge frames before the first crest, is
	-- Note[1] then Note[2] on it, and Crest[1] then Crest[2] on each crest after.
	-- The hit: the touch sheet's four cells, Frames each, Size studs across, on a struck body's root, Toward the camera, from
	-- the frame its crest reaches it (Short of its radius from the cone's point). It stands in for the spark.
	-- The heal: a ring flat round the healed body, rising From to To studs over its Frames (fast first), its Radius
	-- shrinking to Shrink of itself, gone over its last Fade frames; drawn at Drawn of its cell's half.
	-- Every picture untinted and unlit (the content check).
	HeldNote = {
		-- the group's uploads (docs/asset-log.md). The ribbon and the veil are uploaded turned a quarter: a Beam runs its
		-- picture's height along it (handbook/visuals/vfx-engine-facts.md, "Beam"; tested here, 2026-11-12)
		Ribbon = "rbxassetid://99574922833055", -- AR8 B2, bold
		Veil = "rbxassetid://112733560800824", -- AR8 B2, bold
		Touch = "rbxassetid://132431936099861", -- 256 px cells: the hit's four on row 0; the heal, then the flash, on row 1
		Cell = 256,
		From = 4.7,
		Up = 4.5,
		Tall = 0.9,
		Fall = 0.208,
		Grow = 0.301,
		Ease = 2, -- research's verdict (AR4, section 9): at 4 each crest had thinned to a sliver by the time it landed
		Thin = 4,
		Width = 2, -- research's pick from the ladder of 1.5, 2 and 2.5 (AR4, section 10, 2026-11-12)
		Birth = 2.5,
		Narrow = 0.6,
		VeilHold = 3,
		VeilFade = 8,
		Segments = 24,
		Charge = 8,
		Flash = { Swell = { 0.25, 0.55 }, Note = { 0.9, 0.6 }, Crest = { 0.6, 0.4 } },
		Hit = { Frames = 2, Size = 3, Toward = 1.2, Short = 0.7 },
		Heal = { Frames = 14, From = 0.4, To = 5, Radius = 1.6, Shrink = 0.7, Fade = 5, Drawn = 0.8 },
	},

	-- A Shade's burst (docs/asset-requests.md, AR2, section 11; tools/blender/shade_burst_art.py): the sky lantern. A small
	-- flame swells in its collar from the Down clip's frame 18, flares the coat's size on its Burst marker (27), where the body
	-- hides, and is let go: it climbs and burns down to an ember by 41, its paper rising after it, all gone after 49. Every
	-- picture on every frame is the art sheet's (Config.ShadeBurstArt). Untinted and unlit, by the content check: a tint, a
	-- colour or added glow goes back to it. Brightness 1 is the picture's own; the game's bloom does the rest (the capture,
	-- AR2, sections 10 and 11).
	ShadeBurst = {
		Picture = "rbxassetid://91970461037109", -- the group's upload (docs/asset-log.md)
		Brightness = 1,
		-- Seconds past the marker's time the charge waits on a clip that never reaches it (a clip held still), then bursts
		-- anyway. Longer than the killing hit's hold (Combat.Hitstop), which pauses the clip on purpose, and over, with room
		-- for the replication's delay, before the server takes the body away (Combat.Shade.FadeSeconds); a logic case holds
		-- both. A body that leaves first takes the charge with it (AR2, section 13).
		Wait = 0.4,
	},

	-- A level gained, on the player's own lead (research's verdict on TR2, 2026-11-12: a first level-up as a moment), rung 5:
	-- light that rises (AR8 C; docs/research/vfx-reference.md, rule 3). A grey block, the builder's. Seconds; studs; Size
	-- in pixels at the phone's size.
	-- Both are sized by the lead, measured once from its feet to its model's top, hat and all (Tall for a body with no
	-- model): each stands Over studs past that top and is Wide of that height wide. The lead stands in front of the
	-- column, so its solid part must clear the head before its Fade begins (Pip, 7.4 studs, hid a fixed 7-stud one).
	-- The main shape, a column of light, stands up out of the lead's feet: its top climbs to its height over Climb of its
	-- life, eased out, and drifts on up; it is brightest at Peak of its life, Opaque at most; then its foot leaves the ground
	-- and climbs after its top, eased in, as it narrows by Narrow and fades, eased, gone by Seconds. Along it, it's Foot of
	-- its opacity at its foot and fades to nothing over its top's Fade, so it reads as light, never as a solid. The
	-- secondary, a breath (Delay) later, is a sleeve of the same light, wider and fainter (Alpha opaque at most), on the
	-- same curve, drawn Front studs toward the camera so it lies over the body as light around it. Continuous light:
	-- nothing falls or scatters (the content check's condition 2). Both are beams facing the camera, Emission their light's
	-- emission (at noon, 0.3 already goes pale and toward Frost's cyan against the sky), in experience's one colour as it
	-- is (Config.Hud.Card.Xp; the ring before them was Neon, seeded at 0.58 of it to render as the thread's blue: research
	-- on TR3's three calls). The column wears Modulo's picture (its foot the top row), stretched along it, its colour white
	-- at its peak and the thread's blue as it fades, so its fade never reads grey at night (research's pass on Modulo's
	-- sheet, AR8 C, fix 2); the sleeve stays the flat blue. The word pops in from From of its size over Pop as the column
	-- peaks, and rises Rise over Seconds, slower and larger than a hit's number. Its foot stands Clear studs over the
	-- lead's top, hat and all; it's filled bright (white with Fill of experience's blue) and edged in that blue, Edge
	-- authored pixels, so it reads over a blue hat and over the sky (research's pass on AR8 C, fix 1: blue on Pip's blue
	-- hat, it sank).
	LevelUp = {
		Column = { Seconds = 0.7, Over = 5, Wide = 0.6, Climb = 0.3, Peak = 0.25, Narrow = 0.5, Opaque = 0.85, Foot = 0.4, Fade = 0.25, Emission = 0, Picture = "rbxassetid://104727013188370" },
		Sleeve = { Delay = 0.08, Seconds = 0.6, Over = 1, Wide = 0.75, Alpha = 0.3, Front = 2 },
		Word = { From = 0.6, Pop = 0.18, Clear = 0.8, Fill = 0.15, Edge = 2.5 },
		Tall = 5,
		Rise = 3,
		Seconds = 1.6,
		Size = 34,
	},
	-- A shard won, leaping from where its Shade fell to the avatar (research's verdict on TR2, 2026-11-12: the hook that
	-- sends you home, seen). A grey block, the builder's: it hops up, arcs over Seconds as high as Height, spinning, and lands
	-- in a small flash. Searched for its Shade within From studs of the avatar; none, and it only lands.
	ShardLeap = { Seconds = 0.8, Height = 7, Size = 1.4, Spin = 9, From = 60, Flash = { Seconds = 0.3, To = 4 } },
}
