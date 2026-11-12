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

	-- A level gained, on the player's own lead (research's verdict on TR2, 2026-11-12: a first level-up as a moment). A grey
	-- block, the builder's: a ring of light spreads from its feet and fades, and "Level N" rises over it, slower and larger
	-- than a hit's number. Seconds; studs; Size in pixels at the phone's size.
	LevelUp = { Ring = { Seconds = 0.6, From = 2, To = 10, Thick = 0.3 }, Rise = 3, Seconds = 1.6, Size = 34 },
	-- A shard won, leaping from where its Shade fell to the avatar (research's verdict on TR2, 2026-11-12: the hook that
	-- sends you home, seen). A grey block, the builder's: it hops up, arcs over Seconds as high as Height, spinning, and lands
	-- in a small flash. Searched for its Shade within From studs of the avatar; none, and it only lands.
	ShardLeap = { Seconds = 0.8, Height = 7, Size = 1.4, Spin = 9, From = 60, Flash = { Seconds = 0.3, To = 4 } },
}
