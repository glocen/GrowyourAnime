--!strict
-- Effects (shared Config): the look of the signature effects, from the asset maker's art sheets, played by the client's
-- FighterController/Effects. Frames are the clip's, 60 a second; distances in studs. Tuned live in a playtest:
-- NL_Debug:Invoke("Tune", "Effects.Haymaker.Stamp.Top", 6.4).

-- An effect as rows (AR8, "The method"), played by FighterController/Rows: no effect gets code of its own. A row is one
-- kit part or one engine object, what it rides, and its tracks (Rules.Track: keys { frame after the effect's marker, value,
-- ease on to the next as Roblox names it }). Before a row's first key it isn't there; past a track's last key it holds.
--   Kind     "Mesh": the kit's meshes (Config.FxKit) in Part, placed as one, each with the kit's texture Look as its own
--            emissive mask (it reads at night as by day), or Grey's in the block-in. "Card": the kit's Image facing the
--            camera. "Emitter": a ParticleEmitter with the kit's Image and Emitter's properties as Roblox names them (a pair
--            of numbers is a range; a list of { time, value } a sequence; a string an Enum item). "Light": a PointLight.
--   On       another row it rides: its place, spin and tilt, and its scale for At and Radius. None: the effect's foot.
--   Tracks   At (Vector3: on a row, in its unit space; else studs), Scale (Vector3, the mesh's unit size times it),
--            Spin (degrees round up, negative clockwise from above), Tilt (Vector3, degrees), Transparency, Glow (the
--            look's emissive strength), Color, Size (a card's studs), Brightness, Rate, Radius (an emitter's disc, in
--            its row's unit space).
--   Bands    a Mesh row's tracks for one of its parts, over the row's own.
--   Emit     { frame, count }: an emitter's particles let go at once.
-- Area: the hit's area the rows are written at; a hit of another area scales the places and sizes (not the particles).
-- Grey: the block-in, every look grey and every colour its own grey.
export type Key = { any }
export type Row = {
	Kind: string,
	On: string?,
	Part: { string }?,
	Look: string?,
	Grey: string?,
	Image: string?,
	Color: Color3?,
	Range: number?,
	Emitter: { [string]: any }?,
	Emit: { { number } }?,
	Tracks: { [string]: { Key } },
	Bands: { [string]: { [string]: { Key } } }?,
}
export type Rows = { Area: number, Grey: boolean, Rows: { [string]: Row } }

-- A coil band's burn (B1's exit): it holds whole until `from`, fades over Goes frames on Quad In, and flares from 2 to 4
-- as it goes (build/handoff/Pip/fx/pip_burst_rows.json).
local function burn(from: number): { [string]: { Key } }
	return {
		Transparency = { { 0, 0 }, { from, 0, "Quad In" }, { from + 3, 1 } },
		Glow = { { 0, 2 }, { from, 2, "Quad Out" }, { from + 1.5, 4, "Linear" }, { from + 3, 4 } },
	}
end

return {
	-- Rook's Haymaker (docs/asset-requests.md, AR1, section 5; tools/blender/rook_haymaker_art.py): one bar, drawn once, for
	-- the charge's square and the strike's square, eaten as it cools. Then B5's stamp (AR8, "B5"), a grey block until its art.
	Haymaker = {
		-- The bar's eight frames, one under another: the group's upload (docs/asset-log.md); "" plays the grey stand-in.
		Picture = "rbxassetid://82029716338204",
		FrameWidth = 512, -- pixels
		FrameHeight = 128,
		Body = 0.6, -- the share of a frame's height the stroke fills
		Span = 0.92, -- and of its width
		Eaten = { 0, 0.07, 0.16, 0.28, 0.42, 0.57, 0.72, 0.86 }, -- the share gone in each frame; the stand-in shows it as transparency
		-- The charge: the square forms out of its chips round the ram's face and is drawn tight through the hold.
		Charge = { From = 29, Forms = 8, Held = 5, Side = 2.9, Tight = 1.1, Last = 0.1, Bar = 0.3, Over = 0.5 }, -- frames before Strike; studs
		-- The punctuation: the same square thrown open round the ram, on the Strike frame and the Shock frame.
		Strike = { Side = 3.0, Bar = 0.8, Frame = 0 },
		Shock = { Side = 3.7, Bar = 0.7, Frame = 3 },
		Ahead = 0.3, -- studs down the line from the knuckles the squares stand
		-- B5, the stamp, a grey block (docs/asset-requests.md, AR8, "B5"; AR1, section 9; tools/blender/rook_haymaker_stamp.py,
		-- face() lifted). A square stood up facing the camera hangs over the target through the hold, drawn tight. It
		-- slams down onto it over Drop frames, stretched tall, and lands on Strike. It squashes flat on Shock while two bars
		-- run out along the floor from its feet, and is eaten where it lies, the target pinned under it (Actions: Haymaker's push is 0). Frames are counted from Strike; studs from the floor.
		Stamp = {
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
		Picture = "rbxassetid://102541566798055", -- twenty cells: the coil's sixteen, the heat's four (AR8 B1, the last redraw)
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
		-- The exit (AR8, B1): the rows in Rows that play from the Burst, in place of the burst's picture; "" plays the
		-- picture, the before. The heat and the trail stay.
		Exit = "LanternExit",
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
	-- A keeper's fall, by its rig (AR7, section 5; research signed the scope, 2026-11-13): the Shade's burst at its size on
	-- its Down clip's Burst, the body hidden there and the Kept parts left standing; the lantern's glow steady at Glow (the
	-- recipe's cold), flickering from Gutter, out on Out; on Gone the Kept parts go to a handful of the burst's own paper
	-- scraps, no flame: the art table's first Lantern scraps from the lantern, the next Pole from the pole's middle, each
	-- set Lift studs over it at a Shade's size. Frames are on the clip's clock, its markers' to Out; Gone may come after
	-- the clip's end, on its held last frame. The flicker: the glow jumps between Low and all of itself Rate times a
	-- second, under a top that falls to 0 by Out; the lantern's light follows the glow. From Gutter the lantern's Color
	-- goes down to Dark, a deep blue-grey at about a third of its value, eased in (progress to the power Ease), there by
	-- Out; Out to Gone about 0.35 s, so the dark paper is plainly unlit against the day sky (research's verdict on the
	-- install, fix 3). A grey block, the builder's numbers, tuned by playing.
	Falls = {
		Lamplighter = {
			Burst = 34,
			Gutter = 64,
			Out = 80,
			Gone = 101,
			Kept = { "Lamplighter_Pole", "Lamplighter_Lantern" },
			Lantern = "Lamplighter_Lantern", -- its glow and its light; its "Lantern" point the scraps' place
			Pole = "Lamplighter_Pole", -- its "PoleFoot" and "HookTip" points: the scraps' place between them
			Glow = 1.2,
			Flicker = { Rate = 14, Low = 0.15 },
			Dark = Color3.fromRGB(66, 74, 90),
			Ease = 2,
			Scraps = { Lantern = 4, Pole = 3, Lift = 2 },
		},
	} :: { [string]: { Burst: number, Gutter: number, Out: number, Gone: number, Kept: { string }, Lantern: string, Pole: string, Glow: number, Flicker: { Rate: number, Low: number }, Dark: Color3, Ease: number, Scraps: { Lantern: number, Pole: number, Lift: number } } },

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

	-- The effects as rows (the header). Tuned live: "Effects.Rows.LanternExit.Rows.Coil.Tracks.Spin.2.2".
	Rows = {
		-- Pip's Lantern Burst, its exit (AR8, B1; Modulo's rows, build/handoff/Pip/fx/pip_burst_rows.json), from the Burst
		-- (frame 66) on the ground under the lantern's stop, facing along the throw. The lantern's flame let out as the kit's
		-- two-strand coil round the Shades: a third grown and over the target's head on the hit, whole by 70, turning
		-- clockwise from above the way its strands climb and stretching up as it burns. From 74 its six bands go foot first,
		-- each flaring hot as it fades, the tip last, gone on 84; embers rise off the burning edge, two small flames stand at
		-- its feet as the burn starts, and the effect's one white flares at its tip on 70. A light in its middle lights the
		-- Shades and the floor, brightest on the flare.
		LanternExit = {
			Area = 5,
			Grey = true,
			Rows = {
				Coil = {
					Kind = "Mesh",
					Part = { "FxCoil2_Burn1", "FxCoil2_Burn2", "FxCoil2_Burn3", "FxCoil2_Burn4", "FxCoil2_Burn5", "FxCoil2_Burn6" },
					Look = "fx_across_Flame",
					Grey = "fx_across_Grey",
					Tracks = {
						Scale = {
							{ 0, Vector3.new(4.291, 3, 4.291), "Quart Out" },
							{ 4, Vector3.new(4.664, 5, 4.664), "Linear" },
							{ 18.5, Vector3.new(4.664, 5.6, 4.664) },
						},
						Spin = { { 0, 0, "Quart Out" }, { 18.5, -150 } },
					},
					Bands = {
						FxCoil2_Burn1 = burn(8),
						FxCoil2_Burn2 = burn(9.5),
						FxCoil2_Burn3 = burn(11),
						FxCoil2_Burn4 = burn(12.5),
						FxCoil2_Burn5 = burn(14),
						FxCoil2_Burn6 = burn(15.5),
					},
				},
				-- The effect's one white, its focal point, on 70 (rule 3): at the coil's tip, its unit coil's 2.2 up.
				Flare = {
					Kind = "Card",
					On = "Coil",
					Image = "fx_glow",
					Color = Color3.new(1, 0.97, 0.88),
					Tracks = {
						At = { { 3, Vector3.new(0, 2.2, 0) } },
						Size = { { 3, 3, "Quad Out" }, { 4, 5.5, "Quad In" }, { 5, 4, "Linear" }, { 6, 2, "Linear" }, { 7, 0 } },
					},
				},
				-- The burn reads as burning: a disc riding the burning edge, from the foot on 74 to the tip on 84, its radius
				-- the coil's there (the unit coil's 0.45 + 0.55 (1 - s)^1.6), embers rising off its rim. Never falling, never red.
				Embers = {
					Kind = "Emitter",
					On = "Coil",
					Image = "fx_ember",
					Emitter = {
						Shape = "Disc",
						ShapeStyle = "Surface",
						EmissionDirection = "Top",
						Lifetime = { 0.35, 0.6 },
						Speed = { 3, 6 },
						Acceleration = Vector3.new(0, 4, 0),
						Drag = 2,
						Size = { { 0, 0.5 }, { 1, 0 } },
						Color = { { 0, Color3.new(1, 0.84, 0.55) }, { 1, Color3.new(1, 0.54, 0.24) } },
						LightEmission = 1,
						FlipbookLayout = "Grid2x2",
						FlipbookMode = "Loop",
						FlipbookStartRandom = true,
						FlipbookFramerate = { 0, 0 },
					},
					Tracks = {
						At = { { 8, Vector3.new(0, 0, 0), "Linear" }, { 18.5, Vector3.new(0, 2.2, 0) } },
						Radius = { { 8, 1 }, { 10.625, 0.797 }, { 13.25, 0.632 }, { 15.875, 0.51 }, { 18.5, 0.45 } },
						Rate = { { 8, 90 }, { 18.5, 90 }, { 19, 0 } },
					},
				},
				-- The secondary, a breath after the peak, lower and softer, where the burn starts: one flame at each of the
				-- coil's two feet, where its strands leave the ground, turned with its spin. Lifted to stand on the ground.
				FootA = {
					Kind = "Emitter",
					On = "Coil",
					Image = "fx_flame",
					Emitter = {
						EmissionDirection = "Top",
						Lifetime = { 0.3, 0.45 },
						Speed = { 0.5, 1.5 },
						Size = { 1.4, 2 },
						Color = { { 0, Color3.new(1, 0.86, 0.5) }, { 1, Color3.new(1, 0.54, 0.24) } },
						LightEmission = 0.6,
						FlipbookLayout = "Grid2x2",
						FlipbookMode = "OneShot",
					},
					Emit = { { 8, 1 } },
					Tracks = { At = { { 8, Vector3.new(1, 0.17, 0) } } },
				},
				FootB = {
					Kind = "Emitter",
					On = "Coil",
					Image = "fx_flame",
					Emitter = {
						EmissionDirection = "Top",
						Lifetime = { 0.3, 0.45 },
						Speed = { 0.5, 1.5 },
						Size = { 1.4, 2 },
						Color = { { 0, Color3.new(1, 0.86, 0.5) }, { 1, Color3.new(1, 0.54, 0.24) } },
						LightEmission = 0.6,
						FlipbookLayout = "Grid2x2",
						FlipbookMode = "OneShot",
					},
					Emit = { { 8, 1 } },
					Tracks = { At = { { 8, Vector3.new(-1, 0.17, 0) } } },
				},
				-- The Shades and the floor lit by it, brightest on the flare: in the coil's middle.
				Light = {
					Kind = "Light",
					On = "Coil",
					Range = 16,
					Color = Color3.new(1, 0.69, 0.38),
					Tracks = {
						At = { { 0, Vector3.new(0, 1.1, 0) } },
						Brightness = { { 0, 1.5, "Quart Out" }, { 4, 4, "Cubic In" }, { 18.5, 0 } },
					},
				},
			},
		} :: Rows,
	} :: { [string]: Rows },
}
