--!strict
-- Effects (shared Config): the look of the signature effects, from the asset maker's art sheets, played by the client's
-- FighterController/Effects. Frames are the clip's, 60 a second; distances in studs. Tuned live in a playtest:
-- NL_Debug:Invoke("Tune", "Effects.Haymaker.Hero.Reach", 9).

return {
	-- Rook's Haymaker (docs/asset-requests.md, AR1, section 5; tools/blender/rook_haymaker_art.py): one bar, drawn once, for
	-- the charge's square, the strike's square, the thrown bracket and the floor's two lines, eaten as it cools.
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
		Picture = "rbxassetid://139257020366755", -- the flame's twenty cells (round 2: the boil stands up)
		TrailPicture = "rbxassetid://93148687324383", -- the flame blown back
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

	-- Lyric's Held Note (LyricHeldNote): a grey block, the builder's, until the art sheet (AR4, section 9, variant A, and
	-- research's verdict). On each beat that hits, a crest is thrown from her rings across the hit's whole cone (its Cone
	-- degrees either side of the line to her target, from its Apex behind her), fast then slowing on the curve
	-- 1 - (1 - u)^Ease, out to the hit's Reach from her; it thins to nothing over its last Thin studs, and lives until the
	-- next is halfway out (the gap to the next beat, times 2^(1/Ease)). Its veil stands Up studs over the floor at From
	-- studs out, Tall high; a stud further out it falls Fall and grows Grow (the block-in's 1.8 to 4.6 up at the target).
	-- The charge: a light swells in each ring over Charge frames before the first crest, to Flash studs, and flashes there
	-- on it over Out frames, ring-sized (the content check: clear of her face).
	HeldNote = {
		From = 4.7,
		Up = 4.5,
		Tall = 0.9,
		Fall = 0.208,
		Grow = 0.301,
		Ease = 2, -- research's verdict (AR4, section 9): at 4 each crest had thinned to a sliver by the time it landed
		Thin = 4,
		Segments = 12,
		Transparency = 0.45,
		Charge = 8,
		Flash = 0.9,
		Out = 6,
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

	-- A level gained, on the player's own lead (research's verdict on TR2, 2026-11-12: a first level-up as a moment). A grey
	-- block, the builder's: a ring of light spreads from its feet and fades, and "Level N" rises over it, slower and larger
	-- than a hit's number. Seconds; studs; Size in pixels at the phone's size.
	LevelUp = { Ring = { Seconds = 0.6, From = 2, To = 10, Thick = 0.3 }, Rise = 3, Seconds = 1.6, Size = 34 },
	-- A shard won, leaping from where its Shade fell to the avatar (research's verdict on TR2, 2026-11-12: the hook that
	-- sends you home, seen). A grey block, the builder's: it hops up, arcs over Seconds as high as Height, spinning, and lands
	-- in a small flash. Searched for its Shade within From studs of the avatar; none, and it only lands.
	ShardLeap = { Seconds = 0.8, Height = 7, Size = 1.4, Spin = 9, From = 60, Flash = { Seconds = 0.3, To = 4 } },
}
