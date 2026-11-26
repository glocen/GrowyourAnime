--!strict
-- Reveal (shared config): the reveal's numbers tuned by playing (docs/test-requests.md, TR4). Modulo's art, its places
-- and its timing are Config.RevealArt, written from reveal.json; the rules are Rules.Reveal; the stage is
-- src/client/UI/Reveal.

return {
	Skip = 1.0, -- seconds from the tap the skip opens, every rarity (reveal.json, "skip")
	CardHold = 0.3, -- seconds the card after it stands before a tap closes it, so the tap that skipped doesn't close it too
	-- The plate after the reveal (AR12, "The reveal's card, its images"; reveal_card_images.json, `plate`), in points from
	-- its top left. It hangs Gap under the name's rule, from the rule's left end, over the held frame left undimmed, so it
	-- holds wherever the name stands (research's verdict on the reveal's card in Eclipse, call 1). Its lines stand at the
	-- sheet's middles; their sizes are the floor's and a step over (Theme.Text.Minimum, docs/ui.md), where the sheet drew
	-- 11 and 13 (the builder's call, 2026-11-15). The plate widens past Size.X when a line needs it.
	Plate = {
		Size = Vector2.new(320, 84),
		Gap = 8,
		Inset = 16,
		Kind = { Middle = 18, Size = 14 },
		Rarity = { Middle = 40, Size = 16, Pip = 14, PipAt = 21, From = 30, Facet = 0.55 },
		Outcome = { Middle = 64, Size = 16, Mark = 16.25, MarkAt = 23.15, From = 33.55 },
		-- "Continue" on the outcome's line, at its right, while Room points stay between them; else under the
		-- plate's foot, centred, Under below it (Modulo's fallback).
		Tap = { Size = 14, Room = 12, Under = 4 },
		Kept = Color3.fromHex("#D9E1F0"), -- a Voidkin kept: its mark and its words (research's call 2)
		Star = Color3.fromHex("#FFF4D6"), -- a copy toward its star: the conduit's ivory
		-- Each rarity's word, its pip tinted the same; Mythical's no darker or redder than its content check's #FF8794.
		Words = {
			Common = Color3.fromHex("#AEB4C0"),
			Uncommon = Color3.fromHex("#7CF0A0"),
			Rare = Color3.fromHex("#6FB6FF"),
			Epic = Color3.fromHex("#D29CFF"),
			Legendary = Color3.fromHex("#FFD777"),
			Mythical = Color3.fromHex("#FF8794"),
		} :: { [string]: Color3 },
		-- The capture's tile (TR60, UI/Reveal/Capture): beside the card's top right corner, Gap points out, in the kit's
		-- neutral glass; a drawn camera stands in for its icon (Modulo's). Timeout: seconds the HUD stays off at most when
		-- the frame never comes back.
		Capture = { Size = 36, Gap = 8, Body = Vector2.new(18, 12), Lens = 7, Bump = Vector2.new(6, 3), Timeout = 3 },
	},
	-- Each Voidkin's Reveal clip: the marker his strike lands on, and its time in the clip. His clip is shifted so it falls
	-- on Rook's Knock, where the ceremony's colours run (RevealArt.Figure.Knock). The self-test reads the times back from
	-- the clips' own markers.
	Strikes = {
		RookReveal = { Marker = "Knock", Time = 0.85 },
		PipReveal = { Marker = "Flourish", Time = 0.9667 },
		LyricReveal = { Marker = "Strike", Time = 1.5 },
		KirraReveal = { Marker = "Land", Time = 0.2333 }, -- she drops in and lands as her colours run (the builder's call, AR10's install)
		WattReveal = { Marker = "Plant", Time = 0.9 }, -- the spear planted as his colours run (the builder's call, AR11's install)
	} :: { [string]: { Marker: string, Time: number } },
	Fallback = "RookReveal", -- the clip a Voidkin without his own Reveal plays (the grey stand-in)
	-- His silhouette's rim: the light from behind him, its colour the rarity's, so his edge takes it and his front stays
	-- dark. The direction is in the camera's frame (x right, y up, z toward the camera).
	Rim = { Direction = Vector3.new(0.35, -0.2, 1) },
	-- His colours' light once they run: from over the camera's left shoulder, the room's light low around it.
	Lit = { Ambient = Color3.fromRGB(178, 172, 186), Light = Color3.fromRGB(150, 146, 140), Direction = Vector3.new(0.4, -0.6, -0.7) },
	-- The game's face (Builder Sans ExtraBold) set this much over the art's size, so its capitals stand as tall as the
	-- art's: the art sets the name in Blender's stand-in face, whose capitals are taller at a size (40 against 33 points
	-- at Uncommon, 42 against 35 at Rare, measured on reveal_parts_compare.png, 2026-11-13).
	NameFace = 1.2,
	-- The name's stamp (research's TR4 verdict, fix 2): it shows From times its size and falls onto its place over Frames
	-- frames, gathering speed as a stamp does (Power 2: the most on the last frame), lands Under its size on its time, with
	-- the slam's sound, then rebounds still. reveal.json's slam came in over three frames and eased into the landing,
	-- which showed one picture large on the phone and read as a cut.
	Stamp = { Frames = 4, From = 1.7, Under = 0.93, Power = 2 },
	NameDescent = 0.21, -- the name's line below its baseline, against its size: its box's foot sits this far under 214
	-- The reveal's sounds, research's cues (docs/test-requests.md, TR4): each cue's level in dB against the Legendary
	-- split's, the loudest. The library slices they play are Config.Sounds.Cues; the schedule is Rules.Reveal.Cues.
	Sounds = {
		Crack = { Cue = "RevealCrack", Db = -14, Semitones = 1 }, -- each seam, a semitone over the last
		Rung = { Cue = "RevealRung", Db = { -12, -6 }, Semitones = 2 }, -- each rung after the first colour, a step up each, the first to the top (Mythical's)
		Breath = { Cue = "RevealBreath", Db = -10, Cut = 0.12 }, -- Epic up: its peak cut dead this long before the split
		SplitLow = { -- deeper and longer as it climbs: slower a rarity up
			Cue = "RevealSplitLow",
			Db = { Common = -12, Uncommon = -10, Rare = -8, Epic = -5 } :: { [string]: number },
			Speed = { Common = 1.12, Uncommon = 1.06, Rare = 1, Epic = 0.94 } :: { [string]: number },
		},
		SplitHigh = { Cue = "RevealSplitHigh", Db = 0, Speed = { Legendary = 1, Mythical = 0.9 } :: { [string]: number } },
		Strike = { Db = -6, Length = 0.4, Cues = { RookReveal = "HaymakerStrike" } :: { [string]: string } }, -- his own, on the Knock, shortened
		Name = { Cue = "RevealName", Db = { -4, -2 }, Late = 1 / 60 }, -- Common to Mythical, a frame after the slam
		Glint = { Cue = "RevealGlint", Db = -14 }, -- the light along the rule
		Bed = { Cue = "RevealBed", Db = -18, In = 0.3, Out = 0.4, From = 3 }, -- the third rarity (Rare) up: from the colours into the card
		Duck = -6, -- dB the world's sounds take while the reveal is up
	},
	-- The whole screen's flash, Legendary and Mythical: never pure white (research's TR4 verdict, fix 1;
	-- docs/research/vfx-reference.md, rule 3). It takes the rarity's own light, gold-white and red-white, and stops at Most,
	-- so the split's pieces show through it and a dark room isn't blinded. Modulo's eye on the colours.
	WholeFlash = {
		Most = 0.85,
		Colour = { Legendary = Color3.fromHex("#FFF0C8"), Mythical = Color3.fromHex("#FFDCE0") } :: { [string]: Color3 },
	},
	DisplayOrder = 35, -- over the overlay's cover, under the toasts (UI/Layers)
}
