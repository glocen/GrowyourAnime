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
--            "Glow": the body's own look on its Part, its strength from the Glow track, put back at the end. "Point": a
--            place only, for the rows that hang on it. "Beam": a Beam in Image (or Grey's in the block-in; "" none there),
--            with Beam's properties as Roblox names them, between its two ends (below). "Streak": on its frame, a
--            streak from where it stands (a Body point) to the action's target as it stands then, its look Shot's (a
--            heavy hit on its From beat the wider), living Shot.Life on its own time, so a hold or the action's end
--            never cuts it. "Sound": its Cue (Config.Sounds) played once on its frame, from where it stands.
--            "Relight": its body's Part goes dark on its frame and its glow comes back over the action's cooldown
--            from there, to Relight's Glow along u^Power, the move's readout; a newer relight on that part takes over.
--   On       another row it rides: its place, spin and tilt, and its scale for At and Radius. None: the effect's foot.
--   Body     a point of the action's body it rides instead (an attachment by that name, else a part).
--   From     the beat of the effect's action its keys count from; none: the effect's marker.
--   Ground   set down to the effect's foot, upright, facing as the effect does. Hold: its place kept from its first frame.
--   Tint     its colour is the one its player is given (FighterController/Rows' Options.Tint: a foe's type's), in place
--            of its Color; none given, its Color (TR69 A's G1, ShadeGlint).
--   Turn     Vector3, degrees: turned about up, then about its own X, then its own Z.
--   Tracks   At (Vector3: on a row, in its unit space; else studs), Scale (Vector3, the mesh's unit size times it; a
--            number for all three), Spin (degrees round up, negative clockwise from above), Tilt (Vector3, degrees),
--            Transparency, Glow (a look's emissive strength), Color, Size (a card's studs), Brightness, Rate, Radius (an
--            emitter's disc, in its row's unit space); a Beam's Width, Foot, Top, Spike, Lag and Reach.
--   Beam ends: Low is Foot studs up its place, or another Beam's end ("Shaft.High"); High is Top studs up its place, or
--            Spike studs over Low, or another's end, or "Target": where the effect's target stands each frame (no target, no
--            beam). Reach: the share of the way from Low to High it's drawn out to (none: all of it). Trail { Back, Beyond }: from its point Back studs behind it along its
--            motion, to where it was Lag frames before and Beyond studs further. Like: another Beam whose Width and
--            Transparency it takes when it has none (footed on its top, the width there). FootFade: studs from Low over
--            which it fades in. Taper: the width at High as a share of the width at Low.
--   Bands    a Mesh row's tracks for one of its parts, over the row's own.
-- Free (an effect's): the beat from which its rows run on the free clock, so a hold on its hit never stills them, and an
-- early end lets what it left play out (FighterController/Effects, Play); none: the action's clock, and an early end
-- takes it all at once.
--   Emit     { frame, count }: an emitter's particles let go at once.
-- Area: the hit's area the rows are written at, or for an action's own effect the body's scale; another scales the places
-- and sizes (not the particles). Grey: the block-in, every look grey and every colour its own grey. Action: the action
-- whose beats its rows' From name.
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
	Tell: boolean?, -- its bursts keep one particle at any Effects level: a tell a player must read (Track.Burst)
	Tracks: { [string]: { Key } },
	Bands: { [string]: { [string]: { Key } } }?,
	From: string?,
	Body: string?,
	Ground: boolean?,
	Hold: boolean?,
	Tint: boolean?,
	Turn: Vector3?,
	Beam: { [string]: any }?,
	Trail: { Back: number, Beyond: number }?,
	Low: string?,
	High: string?,
	Like: string?,
	FootFade: number?,
	Taper: number?,
	Cue: string?,
	Relight: { Glow: number, Power: number }?,
}
-- World: drawn at its authored size whatever its body's scale (an elite's), as a tell on the ground that must match its
-- hit's own size (DasherLine; the hit's line never scales); left out, an action's rows grow with its body (Effects.Play).
export type Rows = { Area: number, Grey: boolean, Action: string?, Free: string?, World: boolean?, Rows: { [string]: Row } }

-- A coil band's burn (B1's exit): it holds whole, flaring from 1.5 to 4 from `from`, and is cut two frames in, its front
-- covering the cut (build/handoff/Pip/fx/pip_burst_rows.json). Never a fade: half-gone fire over a dark Shade or a dusk sky
-- reads rose, redder than the kit's orange (B1's finish, content check conditions 1 and 4). Its base Glow is 1.5, from 2,
-- so at noon it reads as flame, not gold ribbon (research's final, 2026-11-13).
local function burn(from: number): { [string]: { Key } }
	return {
		Transparency = { { 0, 0 }, { from + 2, 0 }, { from + 2, 1 } },
		Glow = { { 0, 1.5 }, { from, 1.5, "Quad Out" }, { from + 1.5, 4, "Linear" }, { from + 3, 4 } },
	}
end

-- B1's burning front n (AR8, "B1's finish"): shown as band n starts to burn, held 1.5 frames, gone over one as the next
-- takes over.
local function front(from: number): { [string]: { Key } }
	return {
		Transparency = { { 0, 1 }, { from, 1, "Linear" }, { from + 0.5, 0 }, { from + 2, 0, "Quad In" }, { from + 3, 1 } },
		Glow = { { 0, 3 } },
	}
end

-- B1's coil and its fronts grow as one: (width, height, width), 0.7 of Modulo's width, its height kept (research's fix 1).
local COIL_SCALE: { Key } = {
	{ 0, Vector3.new(3.004, 3, 3.004), "Quart Out" },
	{ 4, Vector3.new(3.265, 5, 3.265), "Linear" },
	{ 18.5, Vector3.new(3.265, 5.6, 3.265) },
}

local EffectRows = require(script.Parent.EffectRows)

local Effects = {
	-- Rook's Haymaker (docs/asset-requests.md, AR1, section 5; tools/blender/rook_haymaker_art.py): one bar, drawn once, for
	-- the charge's square and the strike's square, eaten as it cools. Then B5's stamp (AR8, "B5"), in its art (Stamp.Art).
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
		-- B5, the stamp (docs/asset-requests.md, AR8, "B5"; AR1, section 9; tools/blender/rook_haymaker_stamp.py,
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
			-- Never over the top bar: its top edge stands at least Under authored pixels below the top bar's foot, measured
			-- from the camera each frame (UI.World.Ceiling), while the Target card goes see-through behind it
			-- (Config.Hud.SeeThrough.Tag; TR7, research's call on the hang, 2026-11-13, (a) and (c)). But the hang is never
			-- held lower than Over, Clear above the target's head: there the head's margin wins over the top bar (Haymaker's
			-- content check, condition 1). Against Uncapped kinds the cap is off, since capped it hung at the keeper's hat:
			-- the content check blocked it, 2026-11-13, so research's (d) stands.
			Under = 10,
			Uncapped = { Keeper = true },
			-- Its side's share as it forms, and its bar then: drawn tight to Side and Bar with the ram, on Tighten, slowly then
			-- fast into the drop. Loose and over 1 its top edge stays level as it tightens and rises (fix 1, the hold builds;
			-- Modulo's offer, AR8, "B5's polish and the square's art"; it was 0.65 on Quad Out).
			Forms = 1.2,
			FormBar = 0.3,
			Tighten = "Quad In",
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
			-- Its art (AR8, "B5's polish and the square's art"; build/handoff/Rook/fx/rook_haymaker_rows.json): a framed plate
			-- standing up. Two posts the full height and two rails between them, of the kit's FxBar in fx_across_Ember (a dark
			-- rim, orange, a cream core), round FxPlate in fx_rise_Ember set back inside; the floor's two runs, FxBar laid face
			-- up, hard strokes, never a pool. No light at the landing, and the plate never left on the floor. Grey plays the
			-- block-in looks on the same meshes. Keys are frames from Strike (Rules.Track).
			Art = {
				Grey = false,
				Frame = { Mesh = "FxBar", Look = "fx_across_Ember", Grey = "fx_across_Grey" }, -- the posts, the rails, the runs
				Plate = { Mesh = "FxPlate", Look = "fx_rise_Ember", Grey = "fx_rise_Grey" },
				Depth = 0.5, -- studs through a post; a rail is Rails of it, so no rail's face lies in a post's
				Rails = 0.9,
				Pane = 0.06, -- studs: the plate's thickness
				-- The frame's and the plate's EmissiveStrength: 1 through the hang, 2 on Strike, 1 again two frames after.
				Glow = { { -21, 1, "Linear" }, { -1, 1, "Linear" }, { 0, 2, "Quad Out" }, { 2, 1 } },
				-- The plate's Transparency: it charges through the hang, flashes on Strike, and is gone before the stamp lies flat.
				Charge = { { -21, 0.85, "Quad In" }, { -6, 0.35, "Linear" }, { -1, 0.35, "Linear" }, { 0, 0.15, "Linear" }, { 3, 1 } },
			},
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
	-- A Streak row's look (Rows: Pip's shots and Lyric's, a grey block, the builder's): Width studs across, Heavy on a
	-- heavy hit, thinning and fading over Life seconds.
	Shot = {
		Width = 0.2,
		Heavy = 0.45,
		Life = 0.12,
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

	-- A Regen burst's pop (TR40, the block; the builder's numbers, its look waits for the finish): a ball of the heal
	-- number's green at the chest, Height studs over the root, swelling From to To studs across over its Frames (fast
	-- first) while it fades from Alpha to nothing. No picture: Neon, unlit. Small: the burst reads on the HUD's bar
	-- (Config.Hud.Card.Heal), and the pop only ties it to the body (research's must-fix; 3.4 hid behind the sparks).
	RegenPop = { Frames = 10, From = 0.8, To = 2.2, Alpha = 0.45, Height = 0.6 },

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
	-- sheet, AR8 C, fix 2); the sleeve stays the flat blue. Tall is the lead's height when its model can't say. The words
	-- are the HUD's notice (Config.Hud.LevelNotice; AR12, take B: research's ruling of 2026-11-15, the word over the lead
	-- goes and the column stays).
	LevelUp = {
		Column = { Seconds = 0.7, Over = 5, Wide = 0.6, Climb = 0.3, Peak = 0.25, Narrow = 0.5, Opaque = 0.85, Foot = 0.4, Fade = 0.25, Emission = 0, Picture = "rbxassetid://104727013188370" },
		Sleeve = { Delay = 0.08, Seconds = 0.6, Over = 1, Wide = 0.75, Alpha = 0.3, Front = 2 },
		Tall = 5,
	},
	-- A shard won, in the world (TR24's fix 8: "a drop falls in the world with its name and flies to the player", the
	-- package's chests' flight; Rules.Flight). It pops out of the fallen Shade a step toward the player, bounces once, rests
	-- Rest seconds with its name over it, then is pulled into the player, eased in, and lands in a flash as the toast says
	-- it. Size studs tall, a hero shape that reads at a fight's 40 studs (the 1.4 before it read as a speck, TR24's `10`);
	-- spinning Spin radians a second; its name Plate's foot Lift studs over its top. Its Shade is searched for within From
	-- studs of the avatar; none, and it only lands. The builder's grey block, 2026-11-16, until research's pass.
	Drop = {
		Pop = { Seconds = 0.45, Height = 5, Out = 3 },
		Bounce = { Seconds = 0.22, Height = 0.8 },
		Rest = 0.8,
		Pull = { Seconds = 0.45, Lift = 2 },
		Hover = 1.6,
		Size = 2.4,
		Spin = 3,
		From = 60,
		Plate = { Lift = 0.8, Width = 170, Line = 22 },
		Flash = { Seconds = 0.3, To = 4 },
	},
	-- A fallen lead leaving as light for home (TR12; docs/design.md, "A fall sends it home": never a body left lying). The
	-- builder's grey stand-in, 2026-11-14, until its look is designed: a column of light where it lay, High studs tall and
	-- Width across, narrowing and fading as it rises Rise studs over Seconds.
	LeadLeaves = { Seconds = 0.5, Rise = 5, Width = 3, High = 7 },

	-- The three older signatures, still functions in FighterController/Effects, by the name an action's Effect gives: they
	-- move to rows at the finish pass (docs/engineering-plan.md, "Content at scale", item 1). Every other effect is rows.
	Older = { Haymaker = true, LanternBurst = true, HeldNote = true } :: { [string]: boolean },

	-- A landed hit's spark (AR61, the star: research's pick of 2026-11-25, 23:18): the rows of the highest From at or under
	-- the hit's rung, at the struck side, its Front the way the blow travels, on the effects' free clock. A critical's gold
	-- star only on a critical: a killing hit lifted to rung 4 keeps its beat's own spark. Below: from this rung a hit is a
	-- signature's, with its own look to come, and keeps the old spark until then. Old: the old spark beside the new, for
	-- the before and after ("Effects.HitSparks.Old", true). On false: the old spark alone.
	HitSparks = {
		On = true,
		Old = false,
		Below = 7,
		Rungs = { { From = 2, Name = "HitSpark2" }, { From = 3, Name = "HitSpark3" }, { From = 4, Name = "HitSpark4" } },
	} :: { On: boolean, Old: boolean, Below: number, Rungs: { { From: number, Name: string } } },

	-- AR52's grey stand-ins (SlamController: the Guard's pane and its flash, the Dasher's line), by the action they stand
	-- in for: drawn whenever its own rows aren't written, and beside them only when true here, for the verdict's before
	-- and after ("Effects.Grey.GuardRaise", true).
	Grey = { GuardRaise = false, DasherLunge = false } :: { [string]: boolean },
	-- Where a blow meets the Guard's raised shield, in studs from its root at its scale (GuardShield's Shield row stands
	-- there): GuardGlance and GuardBreak play at it, their Front along the blow (SlamController).
	Shield = { Up = 0.4, Ahead = 1.5 },

	-- The looks a hit's Looks name (Definitions.Actions), a shield's and the element states' (Config.Combat: Support's
	-- Shield, States), worn by FighterController on a body for as long as what they show holds, and ended with it at once: rows (their rows hold to a far frame), or an outline (Outlines, below). False takes
	-- one off at once and leaves it out, to judge a block without it: "Effects.Lasting.WattGroundWireShield", false.
	Lasting = { WattGroundWireStop = true, WattGroundWireShield = true, SupportShield = true,
		StateBurn = true, StateChill = true, StateChill2 = true, StateChill3 = true, StateFreeze = true, StateShock = true, StateSap = true } :: { [string]: boolean },
	-- The looks worn as an outline on the body, not rows: its one Highlight's outline, the fill left clear for the hit
	-- flash, Occluded so it never shows through a wall. Read each frame, so a Tune shows at once. Ground Wire's shield, for
	-- his 5 s: a thin outline that sharpens his silhouette, in place of the shell's haze that blurred it (research's
	-- must-fix on AR11's blockout, 2026-11-17, 01:56: a blockout's trial, beside none). Grey until Storm's colour pass.
	Outlines = {
		WattGroundWireShield = { Color = Color3.fromRGB(236, 238, 245), Transparency = 0.15 },
	} :: { [string]: { Color: Color3, Transparency: number } },

	-- The passives' grey cues (Definitions.Passives, Cue; TR7, part 3), the builder's numbers, 2026-11-13, to tune by playing.
	-- Shell: a faint ball round the body while a Reduction holds (Rook's Second Wind), Size studs across, faded in and out
	-- over Fade seconds. Flare: a hot ball swelling at the body's attachment as an Extra lands (Pip's Kindle, at his
	-- lantern), from a fifth of Size to Size over Grow, then fading over Fade, lighting Range studs round it.
	Passives = {
		Shell = { Size = 7.5, Colour = Color3.fromRGB(255, 226, 168), Transparency = 0.6, Fade = 0.2 },
		Flare = { Size = 2.4, Colour = Color3.fromRGB(255, 160, 60), Grow = 0.06, Fade = 0.3, Brightness = 6, Range = 10 },
	},

	-- TR69 A's mark, R4 (research's pick, 2026-11-26, 19:06: docs/test-requests.md, TR69, "Research's pick"), in place of
	-- the ring at its feet, which the bodies hide from the player's camera: a small cut chevron over the head of the
	-- player's lead's target, in the target's type's colour (Config.Hud.Card.Types), quieter than every hit. Three
	-- passes of one drawing (Pictures, below; tools/fx/fight_read_targets.py --pictures), each a card facing the camera,
	-- Side studs a side, its middle Centre studs over the chevron's apex: the ink laid under in InkColor at
	-- InkTransparency, a hairline never alone; the light in the type's colour; the core white, never tinted; each a hair
	-- nearer the camera than the one under it (Nearer studs). The apex hangs Lift studs over the target's top (its mask's
	-- top on a Shade). A new target's mark drops in from Drop.From studs higher over Drop.Frames on a Back Out of
	-- overshoot Drop.Over (back_out(t) = 1 + (Over + 1)(t - 1)^3 + Over (t - 1)^2: the lock-on's snap), fading in over
	-- Fade frames; from Bob.After frames it bobs Bob.Studs up and down once each Bob.Seconds (alive, never busy). The
	-- target's scale sizes it all. Gone at once when the target is down or walking home, as the ring was. It stays clear
	-- of any plate over the foe (research's condition). Frames at 60 a second.
	Mark = {
		Ink = "fight_mark_ink",
		Light = "fight_mark_light",
		Core = "fight_mark_core",
		Side = 1.4,
		Centre = 0.23,
		Lift = 0.55,
		Nearer = 0.02,
		InkColor = Color3.fromRGB(26, 16, 32),
		InkTransparency = 0.4,
		Drop = { From = 1, Frames = 6, Over = 1.4 },
		Fade = 4,
		Bob = { Studs = 0.08, Seconds = 1, After = 8 },
	},

	-- The effects' own pictures, by name, for rows that use one outside the kit: the group's uploads (docs/asset-log.md),
	-- "" until uploaded, which a block-in in grey doesn't need.
	Pictures = {
		lamplighter_column = "rbxassetid://136476355133145",
		lamplighter_column_tip = "rbxassetid://94760089297087",
		lamplighter_column_halo = "rbxassetid://71122841157536",
		-- AR52's ward, W2's lantern frame in three passes and its running light, a Grid4x4 flipbook (tools/fx/ward_targets.py
		-- --pictures), white, tinted only in the blues and white (the content checks of 2026-11-26): ink #163C8C laid
		-- under, the light azure, the core white, the run azure to white. The light and the run carry no glow past the
		-- stroke (research's must-fix at the half checkpoint, 2026-11-26).
		guard_ward_ink = "rbxassetid://136219260367274",
		guard_ward_light = "rbxassetid://70439356326114",
		guard_ward_core = "rbxassetid://88139294901119",
		guard_ward_run = "rbxassetid://106871276509214",
		-- AR7's C4, the keeper's challenge ring, two Grid4x4 flipbooks played once flat on the street
		-- (tools/fx/keeper_targets.py --pictures; the content check of 2026-11-26): the field laid deep warm #7A4A12 under
		-- and added warm over, never the deep alone or past its light, and the line added warm white.
		keeper_ring_field = "rbxassetid://72314583030396",
		keeper_ring_line = "rbxassetid://129310421154504",
		-- TR69 A's mark (Mark, above) and the glint's star (ShadeGlint), white, tinted in the game: the mark's ink #1A1020,
		-- its light and the star's in the foe's type's colour, the cores white (tools/fx/fight_read_targets.py --pictures;
		-- the content check of 2026-11-26).
		fight_mark_ink = "rbxassetid://79519858190353",
		fight_mark_light = "rbxassetid://114476480961865",
		fight_mark_core = "rbxassetid://112380963852248",
		fight_glint_light = "rbxassetid://103104123211223",
		fight_glint_core = "rbxassetid://135371519314738",
	} :: { [string]: string },

	-- The effects as rows (the header), and those in a rows file (Config.EffectRows), merged below. Tuned live:
	-- "Effects.Rows.LanternExit.Rows.Coil.Tracks.Spin.2.2".
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
			Grey = false,
			Rows = {
				-- On fire (B1's finish): a dark saturated rim, the flame's orange, gold and a white core licking up each strand,
				-- drawn for a Glow of 2 and played at 1.5 (burn()); its strength is the Glow, never the texture.
				Coil = {
					Kind = "Mesh",
					Part = { "FxCoil2_Burn1", "FxCoil2_Burn2", "FxCoil2_Burn3", "FxCoil2_Burn4", "FxCoil2_Burn5", "FxCoil2_Burn6" },
					Look = "fx_fire_Flame",
					Grey = "fx_across_Grey",
					Tracks = {
						Scale = COIL_SCALE, -- it hugs the Shade, it doesn't balloon
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
				-- The burning edge: where band n meets n + 1, a bright line across each strand with ragged tongues licking up
				-- it, brighter than the bands, climbing a band every 1.5 frames from 74 (B1's finish).
				Front = {
					Kind = "Mesh",
					On = "Coil",
					Part = { "FxCoil2_Front1", "FxCoil2_Front2", "FxCoil2_Front3", "FxCoil2_Front4", "FxCoil2_Front5" },
					Look = "fx_rise_Flame",
					Grey = "fx_rise_Grey",
					Tracks = { Scale = COIL_SCALE },
					Bands = {
						FxCoil2_Front1 = front(8),
						FxCoil2_Front2 = front(9.5),
						FxCoil2_Front3 = front(11),
						FxCoil2_Front4 = front(12.5),
						FxCoil2_Front5 = front(14),
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
				-- The Shades lit by it, the floor only under the coil (research's fix 2), in the flame's amber: in the coil's
				-- middle, brightest on the flare, falling with the burn.
				Light = {
					Kind = "Light",
					On = "Coil",
					Range = 8,
					Color = Color3.new(1, 0.66, 0.22),
					Tracks = {
						At = { { 0, Vector3.new(0, 1.1, 0) } },
						Brightness = { { 0, 1.5, "Quart Out" }, { 4, 4, "Sine InOut" }, { 8, 3.2, "Linear" }, { 18.5, 0 } },
					},
				},
			},
		} :: Rows,
		-- The keeper's signature (AR7, section 7; Modulo's rows, build/handoff/Lamplighter/fx/lamplighter_signature_rows.json),
		-- written at the keeper's scale (Definitions.Enemies), each from its beat. Through the hold the light gathers in the
		-- lantern's paper, a shell of warm light round its belly and a light on the street; one streak trails the fall; on
		-- the Slam the light leaps back up out of the street beside your fighter as a column, its foot letting go and
		-- climbing away, chips flung off its edge.
		KeeperSignature = {
			Area = 1.5,
			Grey = false,
			Action = "KeeperSignature",
			Free = "Slam", -- the column runs through the hold on the hit, and plays out if the keeper falls
			Rows = {
			-- The light gathers in the paper through the hold, flares on the Wrench, dims on the Slam: the lantern's own glow.
			Paper = {
				Kind = "Glow",
				From = "Light",
				Part = { "Lamplighter_Lantern" },
				Tracks = {
					Glow = {
						{ 0, 1.2, "Sine InOut" },
						{ 52, 2.2, "Quad In" },
						{ 60, 2.6, "Linear" },
						{ 62, 3, "Linear" },
						{ 63, 3, "Quad Out" },
						{ 68, 2.4, "Linear" },
						{ 74, 2.4, "Quart Out" },
						{ 75, 0.4, "Sine InOut" },
						{ 116, 1.2 },
					},
				},
			},
			-- Lamplight on your fighter and the street under the lantern, building to the look, out by 104 (condition a).
			HoldLight = {
				Kind = "Light",
				From = "Light",
				Body = "Lantern",
				Range = 14,
				Color = Color3.new(0.82, 0.958, 0.918),
				Tracks = {
					Brightness = {
						{ 0, 0, "Quad Out" },
						{ 6, 1.2, "Sine InOut" },
						{ 52, 2.4, "Quad In" },
						{ 56, 3.2, "Quad In" },
						{ 60, 0 },
					},
				},
			},
			-- The hold's glow made a shape round the paper's belly, the drum's rims standing out of it; gone by 104.
			Shell = {
				Kind = "Mesh",
				From = "Light",
				Body = "Lantern",
				Part = { "FxShell" },
				Look = "fx_rise_Warm",
				Grey = "fx_rise_Grey",
				Tracks = {
					Scale = {
						{ 0, Vector3.new(1.6, 1.9, 1.6), "Quad Out" },
						{ 8, Vector3.new(1.75, 2.1, 1.75), "Sine InOut" },
						{ 52, Vector3.new(1.9, 2.25, 1.9), "Linear" },
						{ 56, Vector3.new(1.9, 2.25, 1.9), "Quad In" },
						{ 60, Vector3.new(1.5, 1.75, 1.5) },
					},
					Transparency = {
						{ 0, 1, "Quad Out" },
						{ 8, 0.6, "Sine InOut" },
						{ 52, 0.45, "Linear" },
						{ 56, 0.4, "Quad In" },
						{ 60, 1 },
					},
					Glow = { { 0, 1.5, "Sine InOut" }, { 52, 3, "Linear" }, { 60, 3 } },
				},
			},
			-- One straight streak behind the falling lantern, in the column's light, gone before 117 (condition b).
			Streak = {
				Kind = "Beam",
				From = "Wrench",
				Body = "Lantern",
				Image = "lamplighter_column_tip",
				Grey = "fx_beam",
				Color = Color3.new(1, 1, 1),
				Beam = { FaceCamera = true, TextureMode = "Stretch", TextureLength = 1, TextureSpeed = 0, LightEmission = 1, LightInfluence = 0, Segments = 10 },
				Trail = { Back = 1.5, Beyond = 0.9 }, -- from the drum's trailing edge back to where it was Lag frames before
				Tracks = {
					Width = { { 5, 3.3 } },
					Lag = { { 5, 5 } },
					Transparency = { { 5, 0.15, "Linear" }, { 10, 0.15 }, { 11, 1 } },
				},
			},
			-- The ground under the drum's middle on the Slam: the column's foot.
			Spot = {
				Kind = "Point",
				From = "Slam",
				Body = "Lantern",
				Ground = true,
				Hold = true,
				Tracks = { At = { { 0, Vector3.zero } } },
			},
			-- Section 7's column: straight sides, the paper lantern's ribs climbing it, its foot letting go after the peak.
			Shaft = {
				Kind = "Beam",
				From = "Slam",
				On = "Spot",
				Image = "lamplighter_column",
				Grey = "fx_beam",
				Color = Color3.new(1, 1, 1),
				Beam = { FaceCamera = true, TextureMode = "Wrap", TextureLength = 2.625, TextureSpeed = 7, LightEmission = 0.7, LightInfluence = 0, Segments = 20 },
				FootFade = 2.1,
				Taper = 0.5, -- widest at the foot
				Tracks = {
					Foot = {
						{ 0, 0, "Linear" },
						{ 1, 0, "Linear" },
						{ 2, 0, "Linear" },
						{ 3, 0, "Linear" },
						{ 4, 0, "Linear" },
						{ 5, 0, "Linear" },
						{ 6, 0.067, "Linear" },
						{ 7, 0.309, "Linear" },
						{ 8, 0.755, "Linear" },
						{ 9, 1.421, "Linear" },
						{ 10, 2.322, "Linear" },
						{ 11, 3.467, "Linear" },
						{ 12, 4.867, "Linear" },
						{ 13, 6.529, "Linear" },
						{ 14, 8.46, "Linear" },
						{ 15, 10.667, "Linear" },
						{ 16, 13.156, "Linear" },
						{ 17, 15.931, "Linear" },
						{ 18, 18.999, "Linear" },
						{ 19, 22.363, "Linear" },
						{ 20, 26.029, "Linear" },
						{ 21, 30, "Linear" },
					},
					Top = {
						{ 0, 2, "Linear" },
						{ 1, 7.5, "Linear" },
						{ 2, 11, "Linear" },
						{ 3, 12.6, "Linear" },
						{ 4, 13.3, "Linear" },
						{ 5, 13.5, "Linear" },
						{ 6, 13.567, "Linear" },
						{ 7, 13.809, "Linear" },
						{ 8, 14.255, "Linear" },
						{ 9, 14.921, "Linear" },
						{ 10, 15.822, "Linear" },
						{ 11, 16.967, "Linear" },
						{ 12, 18.367, "Linear" },
						{ 13, 20.029, "Linear" },
						{ 14, 21.96, "Linear" },
						{ 15, 24.167, "Linear" },
						{ 16, 26.656, "Linear" },
						{ 17, 29.431, "Linear" },
						{ 18, 32.499, "Linear" },
						{ 19, 35.863, "Linear" },
						{ 20, 39.529, "Linear" },
						{ 21, 43.5, "Linear" },
					},
					Width = {
						{ 0, 6.9, "Linear" },
						{ 1, 6.36, "Linear" },
						{ 2, 6.12, "Linear" },
						{ 3, 6, "Linear" },
						{ 4, 6, "Linear" },
						{ 5, 6, "Linear" },
						{ 6, 5.841, "Linear" },
						{ 7, 5.682, "Linear" },
						{ 8, 5.524, "Linear" },
						{ 9, 5.365, "Linear" },
						{ 10, 5.206, "Linear" },
						{ 11, 5.047, "Linear" },
						{ 12, 4.888, "Linear" },
						{ 13, 4.729, "Linear" },
						{ 14, 4.571, "Linear" },
						{ 15, 4.412, "Linear" },
						{ 16, 4.253, "Linear" },
						{ 17, 4.094, "Linear" },
						{ 18, 3.935, "Linear" },
						{ 19, 3.776, "Linear" },
						{ 20, 3.618, "Linear" },
						{ 21, 3.459 },
					},
					Transparency = {
						{ 0, 0, "Linear" },
						{ 1, 0, "Linear" },
						{ 2, 0, "Linear" },
						{ 3, 0, "Linear" },
						{ 4, 0, "Linear" },
						{ 5, 0, "Linear" },
						{ 6, 0, "Linear" },
						{ 7, 0, "Linear" },
						{ 8, 0, "Linear" },
						{ 9, 0, "Linear" },
						{ 10, 0, "Linear" },
						{ 11, 0, "Linear" },
						{ 12, 0, "Linear" },
						{ 13, 0, "Linear" },
						{ 14, 0, "Linear" },
						{ 15, 0.08, "Linear" },
						{ 16, 0.18, "Linear" },
						{ 17, 0.32, "Linear" },
						{ 18, 0.48, "Linear" },
						{ 19, 0.64, "Linear" },
						{ 20, 0.8, "Linear" },
						{ 21, 0.93, "Linear" },
						{ 22, 1, "Linear" },
					},
				},
			},
			-- The needle over the shaft, with the shaft's width at its top and its fade.
			Tip = {
				Kind = "Beam",
				From = "Slam",
				On = "Spot",
				Low = "Shaft.High",
				Like = "Shaft",
				Image = "lamplighter_column_tip",
				Grey = "fx_beam",
				Color = Color3.new(1, 1, 1),
				Beam = { FaceCamera = true, TextureMode = "Stretch", TextureLength = 1, TextureSpeed = 0, LightEmission = 0.7, LightInfluence = 0, Segments = 10 },
				Tracks = {
					Spike = {
						{ 0, 5.7, "Linear" },
						{ 1, 5.7, "Linear" },
						{ 2, 5.7, "Linear" },
						{ 3, 5.7, "Linear" },
						{ 4, 5.7, "Linear" },
						{ 5, 5.7, "Linear" },
						{ 6, 5.549, "Linear" },
						{ 7, 5.398, "Linear" },
						{ 8, 5.247, "Linear" },
						{ 9, 5.096, "Linear" },
						{ 10, 4.946, "Linear" },
						{ 11, 4.795, "Linear" },
						{ 12, 4.644, "Linear" },
						{ 13, 4.493, "Linear" },
						{ 14, 4.342, "Linear" },
						{ 15, 4.191, "Linear" },
						{ 16, 4.04, "Linear" },
						{ 17, 3.889, "Linear" },
						{ 18, 3.739, "Linear" },
						{ 19, 3.588, "Linear" },
						{ 20, 3.437, "Linear" },
						{ 21, 3.286 },
					},
				},
			},
			-- The column's glow behind it, 1.9 times its width, wider on the slam and the frame after.
			Halo = {
				Kind = "Beam",
				From = "Slam",
				On = "Spot",
				Low = "Shaft.Low",
				High = "Tip.High",
				Like = "Shaft",
				Taper = 0.5, -- hugging the shaft
				-- 1.4 times the shaft's width, from 1.9, so the shaft reads crisp (research's final, 2026-11-13)
				Image = "lamplighter_column_halo",
				Grey = "", -- none in the block-in
				Color = Color3.new(1, 1, 1),
				Beam = { FaceCamera = true, TextureMode = "Stretch", TextureLength = 1, TextureSpeed = 0, LightEmission = 1, LightInfluence = 0, Segments = 10, ZOffset = -0.5 },
				Tracks = {
					Width = {
						{ 0, 15.456, "Linear" },
						{ 1, 11.13, "Linear" },
						{ 2, 8.568, "Linear" },
						{ 3, 8.4, "Linear" },
						{ 4, 8.4, "Linear" },
						{ 5, 8.4, "Linear" },
						{ 6, 8.177, "Linear" },
						{ 7, 7.955, "Linear" },
						{ 8, 7.733, "Linear" },
						{ 9, 7.511, "Linear" },
						{ 10, 7.288, "Linear" },
						{ 11, 7.066, "Linear" },
						{ 12, 6.844, "Linear" },
						{ 13, 6.621, "Linear" },
						{ 14, 6.399, "Linear" },
						{ 15, 6.176, "Linear" },
						{ 16, 5.954, "Linear" },
						{ 17, 5.732, "Linear" },
						{ 18, 5.509, "Linear" },
						{ 19, 5.287, "Linear" },
						{ 20, 5.065, "Linear" },
						{ 21, 4.843 },
					},
				},
			},
			-- The secondary, a breath after the peak: angular bits of light flung up and out off the column's edge, shrinking as they rise.
			Chip1 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip1" },
				Color = Color3.new(0.549, 0.965, 1), -- cyan
				Turn = Vector3.new(45, 16.1, -34.4),
				Tracks = {
					At = {
						{ 4, Vector3.new(2.59, 1.2, -0.75), "Linear" },
						{ 6, Vector3.new(5.74, 4.2, -1.65), "Linear" },
						{ 8, Vector3.new(7.64, 6.35, -2.2), "Linear" },
						{ 10, Vector3.new(8.62, 7.8, -2.48), "Linear" },
						{ 13, Vector3.new(9.03, 8.94, -2.6), "Linear" },
						{ 16, Vector3.new(9.04, 9.28, -2.6), "Linear" },
						{ 19, Vector3.new(9.04, 9.31, -2.6), "Linear" },
						{ 22, Vector3.new(9.04, 9.31, -2.6) },
					},
					Scale = {
						{ 4, 1.26, "Linear" },
						{ 6, 1.147, "Linear" },
						{ 8, 1.031, "Linear" },
						{ 10, 0.911, "Linear" },
						{ 13, 0.724, "Linear" },
						{ 16, 0.523, "Linear" },
						{ 19, 0.301, "Linear" },
						{ 22, 0 },
					},
				},
			},
			Chip2 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip2" },
				Color = Color3.new(1, 0.922, 0.761), -- warm
				Turn = Vector3.new(45, 45.9, -34.4),
				Tracks = {
					At = {
						{ 5, Vector3.new(1.88, 1.2, -1.94), "Linear" },
						{ 7, Vector3.new(3.42, 3.88, -3.53), "Linear" },
						{ 9, Vector3.new(4.36, 5.8, -4.5), "Linear" },
						{ 11, Vector3.new(4.84, 7.09, -4.99), "Linear" },
						{ 14, Vector3.new(5.04, 8.11, -5.2), "Linear" },
						{ 17, Vector3.new(5.04, 8.42, -5.2), "Linear" },
						{ 20, Vector3.new(5.04, 8.44, -5.2), "Linear" },
						{ 23, Vector3.new(5.04, 8.44, -5.2) },
					},
					Scale = {
						{ 5, 1.26, "Linear" },
						{ 7, 1.147, "Linear" },
						{ 9, 1.031, "Linear" },
						{ 11, 0.911, "Linear" },
						{ 14, 0.724, "Linear" },
						{ 17, 0.523, "Linear" },
						{ 20, 0.301, "Linear" },
						{ 23, 0 },
					},
				},
			},
			Chip3 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip3" },
				Color = Color3.new(0.549, 0.965, 1), -- cyan
				Turn = Vector3.new(45, 94.6, -34.4),
				Tracks = {
					At = {
						{ 4, Vector3.new(-0.22, 1.2, -2.69), "Linear" },
						{ 6, Vector3.new(-0.5, 2.93, -6.21), "Linear" },
						{ 8, Vector3.new(-0.67, 4.18, -8.34), "Linear" },
						{ 10, Vector3.new(-0.75, 5.01, -9.44), "Linear" },
						{ 13, Vector3.new(-0.79, 5.67, -9.89), "Linear" },
						{ 16, Vector3.new(-0.79, 5.87, -9.9), "Linear" },
						{ 19, Vector3.new(-0.79, 5.89, -9.9), "Linear" },
						{ 22, Vector3.new(-0.79, 5.89, -9.9) },
					},
					Scale = {
						{ 4, 1.26, "Linear" },
						{ 6, 1.147, "Linear" },
						{ 8, 1.031, "Linear" },
						{ 10, 0.911, "Linear" },
						{ 13, 0.724, "Linear" },
						{ 16, 0.523, "Linear" },
						{ 19, 0.301, "Linear" },
						{ 22, 0 },
					},
				},
			},
			Chip4 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip1" },
				Color = Color3.new(1, 0.922, 0.761), -- warm
				Turn = Vector3.new(45, 112.8, -34.4),
				Tracks = {
					At = {
						{ 4, Vector3.new(-1.05, 1.2, -2.49), "Linear" },
						{ 6, Vector3.new(-1.9, 4.06, -4.53), "Linear" },
						{ 8, Vector3.new(-2.42, 6.11, -5.76), "Linear" },
						{ 10, Vector3.new(-2.69, 7.48, -6.4), "Linear" },
						{ 13, Vector3.new(-2.8, 8.57, -6.66), "Linear" },
						{ 16, Vector3.new(-2.8, 8.9, -6.66), "Linear" },
						{ 19, Vector3.new(-2.8, 8.92, -6.66), "Linear" },
						{ 22, Vector3.new(-2.8, 8.92, -6.66) },
					},
					Scale = {
						{ 4, 1.26, "Linear" },
						{ 6, 1.147, "Linear" },
						{ 8, 1.031, "Linear" },
						{ 10, 0.911, "Linear" },
						{ 13, 0.724, "Linear" },
						{ 16, 0.523, "Linear" },
						{ 19, 0.301, "Linear" },
						{ 22, 0 },
					},
				},
			},
			Chip5 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip2" },
				Color = Color3.new(0.549, 0.965, 1), -- cyan
				Turn = Vector3.new(45, 167.7, -34.4),
				Tracks = {
					At = {
						{ 4, Vector3.new(-2.64, 1.2, -0.57), "Linear" },
						{ 6, Vector3.new(-5.87, 3.2, -1.28), "Linear" },
						{ 8, Vector3.new(-7.83, 4.63, -1.7), "Linear" },
						{ 10, Vector3.new(-8.84, 5.59, -1.92), "Linear" },
						{ 13, Vector3.new(-9.26, 6.35, -2.02), "Linear" },
						{ 16, Vector3.new(-9.26, 6.58, -2.02), "Linear" },
						{ 19, Vector3.new(-9.26, 6.59, -2.02), "Linear" },
						{ 22, Vector3.new(-9.26, 6.59, -2.02) },
					},
					Scale = {
						{ 4, 1.26, "Linear" },
						{ 6, 1.147, "Linear" },
						{ 8, 1.031, "Linear" },
						{ 10, 0.911, "Linear" },
						{ 13, 0.724, "Linear" },
						{ 16, 0.523, "Linear" },
						{ 19, 0.301, "Linear" },
						{ 22, 0 },
					},
				},
			},
			Chip6 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip3" },
				Color = Color3.new(1, 0.922, 0.761), -- warm
				Turn = Vector3.new(45, 215.2, -34.4),
				Tracks = {
					At = {
						{ 4, Vector3.new(-2.21, 1.2, 1.55), "Linear" },
						{ 6, Vector3.new(-4.62, 2.82, 3.26), "Linear" },
						{ 8, Vector3.new(-6.09, 3.98, 4.29), "Linear" },
						{ 10, Vector3.new(-6.84, 4.75, 4.82), "Linear" },
						{ 13, Vector3.new(-7.15, 5.37, 5.04), "Linear" },
						{ 16, Vector3.new(-7.16, 5.55, 5.04), "Linear" },
						{ 19, Vector3.new(-7.16, 5.57, 5.04), "Linear" },
						{ 22, Vector3.new(-7.16, 5.57, 5.04) },
					},
					Scale = {
						{ 4, 1.26, "Linear" },
						{ 6, 1.147, "Linear" },
						{ 8, 1.031, "Linear" },
						{ 10, 0.911, "Linear" },
						{ 13, 0.724, "Linear" },
						{ 16, 0.523, "Linear" },
						{ 19, 0.301, "Linear" },
						{ 22, 0 },
					},
				},
			},
			Chip7 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip1" },
				Color = Color3.new(0.549, 0.965, 1), -- cyan
				Turn = Vector3.new(45, 240.5, -34.4),
				Tracks = {
					At = {
						{ 5, Vector3.new(-1.33, 1.2, 2.35), "Linear" },
						{ 7, Vector3.new(-2.42, 2.99, 4.27), "Linear" },
						{ 9, Vector3.new(-3.08, 4.28, 5.44), "Linear" },
						{ 11, Vector3.new(-3.41, 5.14, 6.04), "Linear" },
						{ 14, Vector3.new(-3.55, 5.82, 6.29), "Linear" },
						{ 17, Vector3.new(-3.56, 6.03, 6.29), "Linear" },
						{ 20, Vector3.new(-3.56, 6.04, 6.29), "Linear" },
						{ 23, Vector3.new(-3.56, 6.04, 6.29) },
					},
					Scale = {
						{ 5, 1.26, "Linear" },
						{ 7, 1.147, "Linear" },
						{ 9, 1.031, "Linear" },
						{ 11, 0.911, "Linear" },
						{ 14, 0.724, "Linear" },
						{ 17, 0.523, "Linear" },
						{ 20, 0.301, "Linear" },
						{ 23, 0 },
					},
				},
			},
			Chip8 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip2" },
				Color = Color3.new(1, 0.922, 0.761), -- warm
				Turn = Vector3.new(45, 275.5, -34.4),
				Tracks = {
					At = {
						{ 5, Vector3.new(0.26, 1.2, 2.69), "Linear" },
						{ 7, Vector3.new(0.48, 3.84, 4.97), "Linear" },
						{ 9, Vector3.new(0.61, 5.74, 6.35), "Linear" },
						{ 11, Vector3.new(0.68, 7.01, 7.06), "Linear" },
						{ 14, Vector3.new(0.71, 8.01, 7.36), "Linear" },
						{ 17, Vector3.new(0.71, 8.32, 7.36), "Linear" },
						{ 20, Vector3.new(0.71, 8.34, 7.36), "Linear" },
						{ 23, Vector3.new(0.71, 8.34, 7.36) },
					},
					Scale = {
						{ 5, 1.26, "Linear" },
						{ 7, 1.147, "Linear" },
						{ 9, 1.031, "Linear" },
						{ 11, 0.911, "Linear" },
						{ 14, 0.724, "Linear" },
						{ 17, 0.523, "Linear" },
						{ 20, 0.301, "Linear" },
						{ 23, 0 },
					},
				},
			},
			Chip9 = {
				Kind = "Mesh",
				From = "Slam",
				On = "Spot",
				Part = { "FxChip3" },
				Color = Color3.new(0.549, 0.965, 1), -- cyan
				Turn = Vector3.new(45, 320, -34.4),
				Tracks = {
					At = {
						{ 4, Vector3.new(2.07, 1.2, 1.74), "Linear" },
						{ 6, Vector3.new(3.89, 2.9, 3.27), "Linear" },
						{ 8, Vector3.new(5, 4.12, 4.2), "Linear" },
						{ 10, Vector3.new(5.57, 4.93, 4.67), "Linear" },
						{ 13, Vector3.new(5.8, 5.58, 4.87), "Linear" },
						{ 16, Vector3.new(5.81, 5.78, 4.87), "Linear" },
						{ 19, Vector3.new(5.81, 5.79, 4.87), "Linear" },
						{ 22, Vector3.new(5.81, 5.79, 4.87) },
					},
					Scale = {
						{ 4, 1.26, "Linear" },
						{ 6, 1.147, "Linear" },
						{ 8, 1.031, "Linear" },
						{ 10, 0.911, "Linear" },
						{ 13, 0.724, "Linear" },
						{ 16, 0.523, "Linear" },
						{ 19, 0.301, "Linear" },
						{ 22, 0 },
					},
				},
			},
			-- The street, your fighter and the keeper lit by the column, brightest on the slam: 4 studs over its foot.
			SlamLight = {
				Kind = "Light",
				From = "Slam",
				On = "Spot",
				Range = 20,
				Color = Color3.new(0.729, 0.96, 0.945),
				Tracks = {
					At = { { 0, Vector3.new(0, 4, 0) } },
					Brightness = { { 0, 5, "Quart Out" }, { 3, 3, "Sine InOut" }, { 22, 0 } },
				},
			},
			},
		} :: Rows,
	} :: { [string]: Rows },
}

-- The effects whose rows are a JSON file (Config.EffectRows; docs/engineering-plan.md, "The rows contract"), beside
-- the ones written here, as one map: the player, a Tune and the checks never tell them apart.
for name, rows in EffectRows.Effects do
	assert(Effects.Rows[name] == nil, `effect "{name}" is written both here and in a rows file`)
	Effects.Rows[name] = rows :: Rows
end

return Effects
