--!strict
-- Hud (shared config): the HUD's numbers that are tuned by playing (docs/ui.md, "The HUD, in the world"; TR3). Live by
-- NL_Debug:Invoke("Tune", "Hud.Numbers.Critical.Weight", 1.5), or a Color3 for a colour. The kit's own colours and images
-- are Config.UIKit (written from Modulo's handoff); how a number moves is Config.Combat.Numbers. Sizes are authored
-- pixels at the phone's size (UI.Theme.Author); a number's style Size is a share of Combat.Numbers.Size.

local UIKit = require(script.Parent.UIKit)
local JewelsConfig = require(script.Parent.Jewels)

export type Style = {
	Colour: Color3?, -- nil: the element's (UIKit.Elements), or the critical's gradient
	Size: number,
	Gap: number, -- between characters, in a digit's width ("widely spaced")
	Outline: Color3,
	Weight: number, -- the outline, authored pixels
	Italic: boolean, -- Builder Sans' true italic, about 10 degrees forward
	Face: string?, -- its own face; nil: Numbers.Face
	Font: string?, -- the face's weight, an Enum.FontWeight name; nil: ExtraBold
	Digit: number?, -- its face's digit width in its text size, the unit of Gap; nil: Numbers.Digit
	Shadow: boolean?, -- the soft shadow under it (Numbers.Shadow)
}

local OSWALD = "rbxasset://fonts/families/Oswald.json" -- the plain numbers' face (AR44)
local DARK = Color3.fromHex("#15120E") -- a warm near-black: an outline that reads over the dusk street's pink end and its dark side

-- The stages' three screens in Seam's lit glass (AR42; build/handoff/UI/stages/stages.json, laid as
-- tools/blender/stage_seam.py draws them): the picker, the results card and the run's line. Places are the cut's, in
-- points on the smallest phone (568 x 320); the picker and the card lay their Block from the band's foot (Top), scaled
-- to the room under it, at most Grow. Kept apart and joined below: the table under it is past the type checker's reach.
local stages = {
	-- The tiles' pictures, open and shut (uploaded under the group, 2026-11-19; docs/asset-log.md), Stage 1 to 4's.
	Images = {
		StageShade = { Id = "rbxassetid://101131336057213", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageShadeShut = { Id = "rbxassetid://118891517960594", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageElite = { Id = "rbxassetid://115142114348580", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageEliteShut = { Id = "rbxassetid://92031257350308", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageEliteBig = { Id = "rbxassetid://91179208057157", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageEliteBigShut = { Id = "rbxassetid://78262016594651", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageLantern = { Id = "rbxassetid://128569720153333", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
		StageLanternShut = { Id = "rbxassetid://91569063445168", Pixels = Vector2.new(400, 344), Points = Vector2.new(100, 86), Pad = 0 },
	},
	Pictures = { "StageShade", "StageElite", "StageEliteBig", "StageLantern" },
	Block = { Top = 58, Wide = 568, Tall = 262, Grow = 1.6 },
	-- Each mode's one accent: Normal's is Seam's light, Hard's an ember (research's pass, 16:34). Edge: the edges, the
	-- chevrons; Lit: a lit plate's fill, top to foot; Road: the walked road's, start to end; Bloom: the ground's light
	-- behind the next tile (at BloomAlpha) and each picture's (Pictures: the next's, any open one's); Glow: round a lit
	-- plate. Hard keeps Normal's value: one ground, one tile, one shut tile for both.
	Accent = {
		Normal = { Edge = Color3.fromHex("#EDE4FF"), Lit = { Color3.fromHex("#FFFFFF"), Color3.fromHex("#D4C6FF") }, Road = { Color3.fromHex("#A89CD8"), Color3.fromHex("#EDE4FF") }, Bloom = Color3.fromHex("#5C48AC"), Glow = Color3.fromHex("#D4C6FF"), BloomAlpha = 0.3, Pictures = { Next = 0.75, Open = 0.42 } },
		Hard = { Edge = Color3.fromHex("#FF9A80"), Lit = { Color3.fromHex("#FFF4EE"), Color3.fromHex("#FFB4A0") }, Road = { Color3.fromHex("#C2503F"), Color3.fromHex("#FFC2B2") }, Bloom = Color3.fromHex("#E85A44"), Glow = Color3.fromHex("#FF9A80"), BloomAlpha = 0.24, Pictures = { Next = 0.55, Open = 0.32 } },
	},
	HardBox = { Color3.fromHex("#2A1626"), Color3.fromHex("#170C16") }, -- the box Hard's chevrons sit in, by a mark
	Ready = Color3.fromHex("#FFD880"), -- a new best (Theme.Colour.Ready)
	Socket = { Color3.fromHex("#1B1728"), Color3.fromHex("#0E0B18") }, -- a dark socket: a new best's chip
	Text = { Small = 14, Title = 17, Big = 22 },
	-- The picker: four tiles side by side over one road (A's One road, research's pick).
	Tile = {
		Top = 71, Foot = 266, Pad = 7, Gap = 5, Corner = 6, Lift = 6, -- the next one stands Lift higher
		Fill = { Color3.fromHex("#2F2758"), Color3.fromHex("#16122C") },
		Shut = { Color3.fromHex("#1C1834"), Color3.fromHex("#110E20") },
		Sheen = { Alpha = 0.11, Fall = 24 }, -- the glint down an open tile's top: Alpha x exp(-y / Fall)
		Next = { Glow = 8, GlowAlpha = 0.38, Wash = 0.12, Edge = 2, Glint = 0.14 }, -- its glint runs down it once a loop
		Edge = { Top = 0.9, Foot = 0.3 }, -- an open tile's hairline, lit from above (the next's: 1 and 0.55)
		ShutEdge = 0.8,
		CornerGlint = 0.7, -- the light at an open tile's top left
		Rise = 18, Start = 0.04, Step = 0.05, Seconds = 0.22, -- each tile rises in from Rise points under, Step apart
	},
	-- The Arc panel's bed in the festival's dusk (TR50's older line: Modulo's B with Seam's lights, research's pick of
	-- 2026-11-23, 00:29; build/handoff/UI/stages/arc_dusk.json): dark wine over the keeper, rosewood at its foot, its light
	-- pooled low in amber (Bloom: its Size is the laid image's, five times where the drawn light falls to a third, times
	-- Arc.Picture), its hairline in rosewood (Edge, at EdgeAlpha).
	Bed = {
		Inset = 6, Tall = 86, Corner = 4, EdgeAlpha = 0.8, Edge = Color3.fromHex("#7A5048"),
		Fill = { Color3.fromHex("#1E0F16"), Color3.fromHex("#4A2324") },
		Bloom = { Middle = Vector2.new(0.5, 0.88), Size = Vector2.new(305.4, 142.1), Colour = Color3.fromHex("#FF9A50"), Alpha = 0.62 },
		Picture = Vector2.new(100, 86),
		Lock = { Side = 26, Down = 53 },
	},
	Badge = { Side = 26, Corner = 5, In = 4, Glow = 4, GlowAlpha = 0.3, Box = 18, Space = 3, Mark = 18 }, -- Mark: the line's chevrons' side
	Road = { Y = 280, Half = 5, Fill = 3, Glow = 4, GlowAlpha = 0.22, Light = 0.55 },
	Foot = { Down = 15, Power = 84 },
	-- The Arc panel (TR50, the director's word of 2026-11-19, 23:19): one tile for the ground, the keeper's picture on its
	-- bed (Picture times the cut's size) and its name under it, and beside it Normal and Hard, one press each, Gap apart.
	-- A choice: its name at In and Top, what it recommends at its top right, the run's marks along Road from In, their
	-- middle Marks down, and where the next run starts past them.
	-- In the festival's dusk (arc_dusk.json, B with Seam's lights): the screen behind the glass in the street's rose
	-- (Backing, top to foot), the light pooled behind the bed (Bloom, at the bed's middle, under the tile; Size as the
	-- bed's), the light round the panel in lantern light (Glow, at Tile.Next.GlowAlpha) and its rim and Back's underline
	-- in ivory (Rim). Normal's own lights stay Seam's.
	Arc = {
		Title = "Festival of Battles",
		Bed = Vector2.new(150, 153), Picture = 1.4, Gap = 8,
		Backing = { Color3.fromHex("#5E2A3A"), Color3.fromHex("#1E0E12") },
		Bloom = { Colour = Color3.fromHex("#FF8246"), Alpha = 0.38, Size = Vector2.new(750, 600) },
		Glow = Color3.fromHex("#FFCF98"),
		Rim = Color3.fromHex("#FFEBD2"),
		-- Says: where the run starts, its top this far from the marks' middle; Press: the lit plate's height under it.
		Choice = { In = 12, Top = 6, Head = 24, Marks = 60, Road = 214, Words = 12, Says = -26, Press = 28 },
	},
	-- The card at a run's end, over the street dimmed (Dim, the cover's transparency; Cover, its colour: the dusk's dark
	-- wine, so the street under the card stays the street's, arc_dusk.json).
	Card = {
		Left = 124, Wide = 320, Corner = 8, Edge = 1.4, Space = 8, In = 12, Foot = 10, Before = 14,
		Inset = 16, -- a row's content stays this far inside the card's sides (the marks' road runs from it)
		GaveGap = 6, -- between the rewards' cells, each as wide as its words
		Fit = 0.85, -- the least the rewards' row shrinks to keep its longest inside the inset (a run's Credits grow)
		TitleFit = 0.6, -- the least the title shrinks to: a fall names its lead, whose nickname runs to 20 letters
		NewBest = 98, -- the "New best" tag's width, beside the clock at the title's size
		Rows = { Marks = 30, Title = 28, Time = 22, Gave = 28 },
		-- the press into Hard on the card whose clear opened it: shut under Hard's lock (Lock points, Gap before its word),
		-- then After seconds past the card's beats the lock lifts Rise points and fades over Seconds as the press lights
		Unlock = { After = 0.3, Seconds = 0.3, Rise = 8, Lock = 18, Gap = 6 },
		Presses = { Quiet = 82, One = 124, Retry = 170, Home = 124, Gap = 6 },
		-- A fall's three (docs/design.md, "A fall in the Festival"; research's widths, 2026-11-24): Retry lit at One, or dim
		-- with the time its lead heals in; Send another and Home quiet at Quiet, or, when "Send another" doesn't fit Quiet
		-- with Pad either side, Tight's (its width taken from Home's). Lit: how long Retry takes to light, once someone
		-- leads.
		Fall = { Pad = 6, Tight = { Another = 100, Home = 64 }, Lit = 0.2 },
		Shadow = 0.4,
		Dim = 0.5,
		Cover = Color3.fromHex("#2A1219"),
		Margin = 4, -- kept above and below the card when the screen's room is the card's (the cut: 4 at the smallest phone)
	},
	-- The run's line under Roblox's top bar, in the Hud layer.
	-- It stands clear of the HUD's pieces named in Clear, Gap from them; between them it narrows, to Least at most: Hard's
	-- longest head ("Hard Stage 3  10 / 10 Shades") still clears its words there.
	Line = { Wide = 368, Least = 330, Down = 4, Tall = 44, Corner = 6, Edge = 1.2, Gap = 8, Clear = { "Lead", "Credits", "Electricity" } },
	-- A stretch's dare under the line (AR53, build/handoff/UI/goals/goals.json, "dare"; TR54), from the line's glass's top
	-- left. Open: its box from Left, Top to its foot by its rows (Foot, Corner), its words from the stretch's name's left at
	-- Words.Y by its rows (capitals' top), the box Pad past the widest row and never past Limit short of the Electricity
	-- pill; one row when the words end Inside of that limit, else two. Folded: Tab, the mark's middle at Mark, always.
	-- Motion: the tab opens over Open seconds as the stretch begins, holds Config.Goals.Held, closes over Close; a kept
	-- dare's mark flares once to Flare.Scale over Flare.Seconds.
	Dare = {
		Left = 8, Top = 30, Foot = { 70, 88 }, Corner = { 4, 6 }, Pad = 10, Limit = 6, Inside = 8,
		Words = { Size = 14, Colour = Color3.fromHex("#F1ECFF"), Y = { { 51 }, { 48, 66 } } },
		Tab = { 8, 30, 26, 40 },
		Mark = Vector2.new(21, 57),
		-- a "Do" dare's mark until it's done (TR54's must-fix 1): the held mark multiplied by Colour at Transparency, whole
		-- and unlit, apart from the broken mark's dark split
		Waits = { Colour = Color3.fromRGB(150, 144, 168), Transparency = 0.35 },
		Motion = { Open = 0.2, Close = 0.18, Flare = { Seconds = 0.4, Scale = 1.4 } },
	},
	-- The dares kept on a run's card (AR53, goals.json, "dare.card"): a mark Mark.Gap right of each kept stretch's node at
	-- Mark.Scale, and the chip last on the time's row (Chip.Gap before it) when the row's longest fits inside the card's
	-- Card.Inset, else a row of its own, Fall tall, the chip Down from its top, as always on the fall's card (TR54's
	-- must-fix 3). Chip: its glass (Fill top to foot, Edge, Glow), the mark at Mark (scale Mark.Scale), the words, Pad at
	-- its right. The stones the dares paid stand in the rewards' row (must-fix 2): the stone's picture Stone.Side across,
	-- over its Light (a bloom Spread times the picture across, Tall times it high, Colour at Alpha), so the dark rock reads
	-- on the well: the picture fills the row, so the light is larger than it, a little past the cell.
	DareCard = {
		Mark = { Gap = 10, Scale = 0.9375 },
		Chip = {
			Tall = 22, Corner = 4, Gap = 8, Pad = 7, Fall = 26, Down = 2,
			Fill = { Color3.fromHex("#0E0B1A"), Color3.fromHex("#08070F") },
			Edge = { Colour = Color3.fromHex("#C9BA9C"), Width = 1.2 },
			Glow = { Colour = Color3.fromHex("#FFF6E2"), Alpha = 0.22, Reach = 5 },
			Mark = { At = Vector2.new(10, 11), Scale = 0.8125 },
			Words = { X = 19, Y = 4, Size = 14, Colour = Color3.fromHex("#EFE6D2") },
		},
		Stone = { Side = 28, Light = { Colour = Color3.fromHex("#FFB869"), Alpha = 0.9, Spread = 2.4, Tall = 1.8 } },
	},
	-- Its beats (stage_seam.py's strips): the picker's opening, the switch, the card's two beats, the line's.
	Motion = {
		Rise = 12, Open = 0.22, -- the screen rises Rise points as it fades in
		RoadAt = 0.3, RoadSeconds = 0.36, -- the road fills
		RingAt = 0.6, RingSeconds = 0.26, RingFrom = 0.4, -- the ring pops, backing out
		Switch = 0.22, Drain = 0.18, -- a switch crossfades; its road drains and fills again
		Idle = 2.4, -- one loop for every idling light
		CheckAt = 0.22, CheckSeconds = 0.12, CheckOver = 1.3, -- the card's check pops in a little over
		RunAt = 0.34, RunSeconds = 0.36, -- then the light runs on to the next mark
		Notch = 0.18, Pop = 1.35, Settle = 0.2, -- a Shade's fall eases the light onto its notch; the last foe's ring pops
	},
}

return {
	Numbers = {
		-- Roblox's own face, with a stroke (research's call, 2026-11-12): Builder Sans, which has a true italic at ExtraBold.
		Face = "rbxasset://fonts/families/BuilderSans.json",
		Digit = 0.56, -- a digit's width in its text size, Builder Sans ExtraBold: the unit of Gap
		-- The plain numbers, dealt, an element's, received and healing: AR44's take B, research's pick at 12:11 (the
		-- director, by 11:16: "The damages/healing text need a small rework"; the stroke "way to thick"): Oswald Medium,
		-- calm and tall, a thin outline of 0.8 and a gap of 0.12 of its own digit (Oswald's 0 is 0.36 of its size, measured
		-- in Studio; 0.45 read as three separate digits, research's pass at competent, AR44), on the soft shadow. The
		-- critical and the grey word keep Builder Sans.
		Styles = {
			-- A hit dealt: pale ivory, upright.
			Dealt = { Colour = UIKit.Numbers.Plain, Size = 1, Gap = 0.12, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- An element's second number: the same, in its element's colour, a beat behind.
			Element = { Size = 1, Gap = 0.12, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- Damage the player's lead receives: the same face in muted red, a size larger (the builder's seed, 2026-11-12).
			Received = { Colour = Color3.fromHex("#E27A6A"), Size = 1.2, Gap = 0.12, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- Healing: as damage received, in green.
			Heal = { Colour = UIKit.Numbers.Heal, Size = 1.2, Gap = 0.12, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- A dodge, a block, an absorb: a short grey word on a pointer.
			Word = { Colour = UIKit.Numbers.Miss, Size = 0.72, Gap = 0.12, Outline = DARK, Weight = 1.4, Italic = false },
		} :: { [string]: Style },
		-- The soft shadow under the plain digits: a dark copy of them Offset authored pixels right and down, Transparency
		-- see-through, its edge softened by an outline Spread authored pixels wide at Soft see-through. The builder's seed.
		Shadow = { Colour = DARK, Offset = Vector2.new(1, 2), Transparency = 0.45, Spread = 2.5, Soft = 0.82 },
		Element = { Delay = 0.1 }, -- seconds behind the hit's own number: "a beat behind"
		-- Where a new number tries to go, in its own widths and heights, first to last, clear of the numbers already up
		-- (Rules.Hud.Place): where it rose, then above, then up to either side, then a ring farther up and out, then wide
		-- aside, and last below, where it trails the ones above. A short word among a flurry, a critical aside and the next
		-- body's numbers found the first five all taken, and under the top band every slot above folds down to one (AR44's
		-- fix 3).
		Slots = {
			{ 0, 0 }, { 0, -1 }, { -0.75, -0.5 }, { 0.75, -0.5 }, { 0, -2 },
			{ -0.75, -1.5 }, { 0.75, -1.5 }, { -1.25, -1 }, { 1.25, -1 }, { 0, -3 },
			{ -0.75, -2.5 }, { 0.75, -2.5 }, { 0, -4 },
			{ -1.5, -0.5 }, { 1.5, -0.5 }, { -1.5, 0.5 }, { 1.5, 0.5 },
			{ 0, 1 }, { -0.75, 1 }, { 0.75, 1 }, { 0, 2 },
		},
		-- Clear along their whole rise, seen at these seconds ahead (each rises on its own eased curve, so one born a beat
		-- later climbs into the one above it: AR44's verdict, fix 3), and Clear authored pixels apart, so none touches.
		-- The builder's seeds.
		Ahead = { 0, 0.1, 0.25, 0.5, 0.8 },
		Clear = 3,
		Pointer = 5, -- the word's pointer, authored pixels across
		-- Authored pixels a number keeps under the top band (the lowest of the cards and the pills that show), its whole life,
		-- rise and swell included (TR3's verdict, fix 4). The builder's seed.
		Band = 10,
		-- An open plate (the level-up's word) that would cross a piece of the band slides aside into the open sky, at most
		-- Room of its own width, and eases there at this rate a second; with no room it's pushed under instead (research's
		-- pass on AR8 C, fix 1). The builder's seed.
		Slide = { Room = 1, Rate = 14 },
		-- A critical (the director's word to stay close to the reference; research's table, AR3 section 3, round 2): gold,
		-- heavy, slanted, larger, widely spaced, on the swept stroke. Research tunes these live at TR3's blockout.
		Critical = {
			Size = 1.6, -- tops the ladder by a clear step: received and heal are 1.2 (research on TR3's three calls, 2026-11-13)
			-- It lands swollen to Combat.Numbers.Pop, its splash with it, and settles over Count (AR44, research's second
			-- look: the critical only; the plain numbers land whole).
			Land = true,
			Gap = 0.25, -- a quarter of a digit between digits: at 0.4, "1 , 2 0 4" read as separate glyphs (AR44's verdict, fix 2)
			-- Polished gold chrome, head to foot: near-white at the top, rich gold down to a hard dark horizon at the middle,
			-- hot amber below it, then a light lip (AR44, "The critical's shine": take C, research's pick, 2026-11-19, 23:36,
			-- on the director's "the crit text isnt chromatic shiny right now it look sad and meh"; Modulo's cut,
			-- build/handoff/UI/hud/critical_shine.json). The stops at 0.49 and 0.5 make the horizon: keep them that close.
			-- Top and Foot are its ends.
			Top = Color3.fromHex("#FFFDF0"),
			Foot = Color3.fromHex("#FFF0B8"),
			Ramp = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#FFFDF0")),
				ColorSequenceKeypoint.new(0.15, Color3.fromHex("#FFF2B0")),
				ColorSequenceKeypoint.new(0.35, Color3.fromHex("#FFD84A")),
				ColorSequenceKeypoint.new(0.49, Color3.fromHex("#FFB300")),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#7A3A00")),
				ColorSequenceKeypoint.new(0.58, Color3.fromHex("#B85E00")),
				ColorSequenceKeypoint.new(0.75, Color3.fromHex("#FF9A1A")),
				ColorSequenceKeypoint.new(0.92, Color3.fromHex("#FFD36B")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#FFF0B8")),
			}),
			-- Its shine on the land (take C): three levers, each a copy of the digits with no outline, laid in the plate so
			-- they pop and rise with it. Read at the number's birth, so a Tune shows on the next critical.
			Shine = {
				On = true,
				-- The chromatic split, an impact's aberration that settles: a cyan copy left and up, a red one right and down,
				-- behind the digits and over their cast. Each is Points along (authored pixels at the critical's own size,
				-- grown with a heavier hit's number) and a quarter of that across, from Land to Rest over Seconds, eased
				-- out; its transparency from LandClear to RestClear with it. At rest a hairline each side by day (4.6:
				-- 3.4 vanished, 5.8 doubled the 1). The content check's condition: the two always together and symmetric.
				Split = {
					Cyan = Color3.fromHex("#3DEBFF"),
					Red = Color3.fromHex("#FF3D5E"),
					Land = 7,
					Rest = 4.6,
					Across = 0.25,
					Seconds = 0.2,
					LandClear = 0.15,
					RestClear = 0.05,
				},
				-- The hit flash: a white copy over the digits, clear from opaque over Seconds, straight.
				Flash = { Colour = Color3.fromHex("#FFFFFF"), Seconds = 0.0667 },
				-- The specular glint, once: a white band over the digits, leaning Lean degrees with the italic (its top to
				-- the right), carried from Reach of the number's width before it to Reach past it, from Start after the land
				-- over Seconds. Its middle Strength opaque, half that at Half of the width, nothing by twice Half; a thinner
				-- band Trail behind it, TrailStrength opaque, TrailHalf wide.
				Glint = { Start = 0.08, Seconds = 0.25, Reach = 0.15, Lean = 20, Strength = 0.95, Half = 0.1, Trail = 0.13, TrailStrength = 0.6, TrailHalf = 0.035 },
			},
			Outline = Color3.fromHex("#211306"), -- near-black brown, measured
			Weight = 2.4, -- the reference's thick dark edge (1.2 read thin and pasted on: the director, 2026-11-19, "that art isnt composited")
			Italic = true, -- the slant is the face's italic, on or off: about 10 degrees, never another angle
			-- A hard dark copy of its digits cast down and right onto the splash, binding the two into one picture as the
			-- reference's critical is (the director, 2026-11-19: "that art isnt composited"; the builder's take, tried live).
			-- Authored pixels; its edge Spread wide, as wide as the digits' own outline.
			Cast = { On = true, Colour = Color3.fromHex("#211306"), Offset = Vector2.new(2, 3), Transparency = 0, Spread = 2.4, Soft = 0 },
			-- The splash (CritSweep, AR44 round 4, Modulo's): behind the number and under its outline, its height 1.5 of the
			-- digits', centred on them, its left edge half a digit before the first digit, its width 0.67 of the number's and
			-- never under 2.2 heights; it stretches along, never up. Tint: the content check's limit itself (AR44, "Modulo's
			-- splash", condition 1), the nearest allowed to the reference's burnt orange, which rule 4 blocks (research's
			-- measure, 12:48, replacing the #F08A2C of 12:11): yellower or lighter free, never redder or darker.
			-- Round 5 (AR44, "The splash, painted"): the colour is in the picture, #CC661F at its lower edge to #E8873A in its
			-- core, so the tint is white; a tint multiplies, and #CC661F over the core would pass rule 4's limit (the content
			-- check's condition 1).
			Sweep = {
				Tint = Color3.fromHex("#FFFFFF"),
				Transparency = 0,
				Height = 1.25, -- tucked behind the digits, peeking out at the head and the tail as the reference's (1.5 and 0.67 till 2026-11-19)
				Left = 0.5,
				Width = 0.55,
				Least = 2.2,
			},
		},
		-- By the hit's rung (AR8 C; research's pass on A): a number grows Grow of its style's size for each rung over its
		-- style's own (Rungs; a critical's style is rung 4's), at most Most times. While a hit of rung Yield.From or more
		-- lands on a body, the lower numbers on it leave its middle: out and up by Aside authored pixels, fading over
		-- Seconds, eased in, never down the body (the content check's condition 1).
		Rung = { Grow = 0.08, Most = 1.5, Rungs = { Critical = 4 } :: { [string]: number }, Default = 2 },
		Yield = { From = 7, Seconds = 0.1, Aside = 14 },
	},
	-- The foe card's difficulty skull (AR45), by the share of the lead's health one fight with the foe takes (Rules.Hud.Cost,
	-- read by Rules.Hud.Skull against 1): grey under Cuts[1], white up to Cuts[2], yellow under Cuts[3], red from it, where
	-- the lead falls first. Research's integration pass, 2026-11-19: on 1890 pairs the cost's tier is the duels' for 1863.
	-- The skull and the level wear the tier's colour; the grey skull is faint (Faint, its ImageTransparency).
	Skulls = {
		Cuts = { 0.15, 0.5, 1 },
		Colours = { Color3.fromHex("#D3D1DC"), Color3.fromHex("#F6F2E8"), Color3.fromHex("#FFC83A"), Color3.fromHex("#FF4F42") },
		Faint = 0.45,
	},
	-- The interface's motion (AR8 C; docs/research/vfx-reference.md, rule 4). Seconds; scales are of full size.
	Motion = {
		-- A press: the face squeezes to Squeeze within In of the touch, held at least Least, and comes back over Out with a
		-- small overshoot (Back: the ease's strength; 0 is none). It replaces the pixel's sink.
		Press = { Squeeze = 0.92, In = 0.05, Least = 0.08, Out = 0.14, Back = 2.4 },
		-- Hover (TR20; UI.Kit.Hover), seeds, UNVERIFIED: a pointer over a pressable thing, or a pad's selection, eases it
		-- in over In seconds and out over Out. A tile or a panel lifts Lift points, its colours White of the way toward
		-- white, its halo (or its edge, toward its accent) at Halo; a card scales to Card and its rarity rim lifts, Rim
		-- points, RimLight of the way from its rarity's trim toward white (research's verdict on TR20, fix 3: 1.03 and the
		-- trim alone couldn't be seen); a pad's selection wears that rim whole. Over a dock tile Word seconds, its word (or
		-- why it's refused) shows.
		Hover = { In = 0.08, Out = 0.12, Lift = 2, White = 0.12, Halo = 0.4, Card = 1.06, Rim = 2, RimLight = 0.5, Word = 0.35 },
		-- A screen comes in from From of its size, see-through, eased out over Enter; it leaves to To, eased in, over Exit:
		-- about 0.8 of its entrance (rule 4).
		Screen = { Enter = 0.2, Exit = 0.16, From = 0.94, To = 0.97 },
		-- A toast slides in from the screen's right edge over Enter, eased out, and leaves that way over Exit, eased in.
		Toast = { Enter = 0.2, Exit = 0.16 },
		-- The UI effects kit (TR6; docs/research/vfx-reference.md, "UI effects", DESIGN, its starting numbers, tuned by
		-- playing). The tokens live here, beside the press's, so Tune reaches them live (UI/Theme.Motion keeps the tweens).
		-- Haptic: a press's click under the thumb on a phone (ClickHaptic's UIClick).
		Haptic = true,
		-- Fly: a reward's icons (Rules.Hud.Flock: Least for under 10, one more each power of ten, Most at most), Size
		-- authored pixels, each from within Spread of where it was won, on an arc bowed Bend of its way to either side
		-- (Rules.Hud.Arc), over Seconds, gathering speed into its counter; Stagger apart. From 0.9 of their size, never
		-- from nothing; Land, their size as they reach the counter.
		Fly = { Least = 4, Most = 8, Size = 22, Spread = 16, Bend = 0.35, Seconds = 0.5, Stagger = 0.04, Land = 0.75 },
		-- Count: a counter counts from its old value to its new over Seconds, Expo out (Rules.Hud.ExpoOut), from the first
		-- icon's landing; it starts by Latest seconds whatever lands.
		Count = { Seconds = 0.6, Latest = 1.2 },
		-- Rays: a sunburst behind a reward of rung 5 and up, Size times its word's height across, Count rays, coming in
		-- Delay after the word from 0.9 of its size to 1.1 over Seconds, at its fullest Alpha at Peak of its life
		-- (Rules.Hud.Pop), turning Spin degrees a second.
		Rays = { Size = 3.6, Count = 12, Delay = 0.08, Seconds = 0.9, Peak = 0.2, Alpha = 0.55, Spin = 40 },
		-- Shine: a light band Width of its piece across, turned Angle degrees, sweeping once over Seconds, Delay after its
		-- piece comes in (only on what's rare).
		Shine = { Width = 0.12, Angle = 20, Seconds = 0.4, Delay = 0.15 },
		-- Burst: Count sparks flung out from a point, Reach authored pixels, slowing over Seconds and shrinking, Size each.
		Burst = { Count = 6, Reach = 30, Size = 14, Seconds = 0.45 },
	},
	-- A reward pops at its rung (rule 4): it swells to 1 + Swell × (rung − 1) of its size, at its peak at Peak of Seconds
	-- (eased out), and settles by Seconds (eased in and out). A Credits or Electricity win also sends a "+N" up off its pill,
	-- Rise authored pixels over the first half of Gain seconds, fading over the last third after its last win; wins within
	-- its life count up as one, over Count seconds. Electricity pops only on a jump of Jump of the battery's capacity or
	-- more in one read (a return from away), never the bays' flow. Experience: a glint over the thread's light, Glow opaque
	-- at its peak, brightest at its new end; a level: its number swells and goes Glow of the way to white. A reward that
	-- flies to its pill (TR6: a kill's Credits, the battery's jump) pops at Fly's rung as its first icon lands: about 1.25
	-- (the study's DESIGN 3, rung 4 to 5); the level's badge bursts as it pops.
	Pop = {
		Seconds = 0.35,
		Peak = 0.25,
		Swell = 0.06,
		Glow = 0.6,
		Rungs = { Xp = 2, Credits = 3, Electricity = 3, Level = 5, Fly = 5 } :: { [string]: number },
		Gain = 0.9,
		Rise = 12,
		Jump = 0.05,
		Count = 0.15,
	},
	-- The type edge's arrow on the target's card (docs/ui.md): up, green, when the lead's type beats the target's; down,
	-- red, when the target's beats the lead's (AR45's EdgeArrow, its content check: these two tints only).
	Arrow = { Up = UIKit.Good, Down = Color3.fromHex("#FF786E") },
	-- The signature's readout (AR12, V2 Block; hud_colour.json's pieces.readout): a plate Size across in the lead's corner,
	-- Under the lead card's foot and Right of its left, holding the lead's signature's own icon (Icons, by the action's
	-- id; one not drawn yet shows its class's glyph, Glyph of the plate across). Its well (x0, y0, x1, y1 in the plate's
	-- points) fills from the foot like a conduit: the well's shape under one gradient, whose line rises Lean of a point
	-- for each point to the right; Front, the gradient's stops Below that line in points, how Solid and in what Colour
	-- (Modulo's, DESIGN); Travel, the carry that takes the line from the well's middle to its foot, in the well's sides,
	-- found in Studio (2026-11-15, stills at 0 to 0.995: nothing lit when empty, the line in by about 3%, at the top just
	-- short of ready; 0.5 left a glow at the foot when empty, 0.66 stood still for the first and last tenth). Ready, the
	-- plate is white-hot with its icon dark on the light. It empties over Flash seconds as the move
	-- fires, swelling Swell of its size, and swells ReadySwell once over Ready seconds when it's ready again. Only in a
	-- fight (TR3's verdict, fix 5): FadeIn as the lead takes a target, Linger after it has none, FadeOut; Always shows it
	-- out of a fight too, to judge its corner whole. The builder's seeds, tuned live.
	Readout = {
		Size = 58,
		Under = 10,
		Right = 2,
		Well = { 4, 4, 54, 54 },
		Lean = 0.12,
		Front = {
			{ Below = -5.8, Solid = 0, Colour = Color3.fromHex("#FFF4D6") },
			{ Below = -1.35, Solid = 0.55, Colour = Color3.fromHex("#FFF4D6") },
			{ Below = -1.25, Solid = 1, Colour = Color3.fromHex("#FFFFFF") },
			{ Below = 1.25, Solid = 1, Colour = Color3.fromHex("#FFFFFF") },
			{ Below = 1.35, Solid = 0.78, Colour = Color3.fromHex("#FFF4D6") },
			{ Below = 5.8, Solid = 0.36, Colour = Color3.fromHex("#FFF4D6") },
			{ Below = 8, Solid = 0.28, Colour = Color3.fromHex("#FFF4D6") },
		},
		Travel = 0.58,
		Icons = { RookHaymaker = "SignatureHaymaker", LyricHeldNote = "SignatureHeldNote" } :: { [string]: string },
		Glyph = 0.5,
		Ink = Color3.fromHex("#14161B"), -- a glyph on the ready plate
		Flash = 0.35,
		Swell = 0.25,
		Ready = 0.6,
		ReadySwell = 0.12,
		FadeIn = 0.2,
		Linger = 1,
		FadeOut = 0.35,
		Always = false,
		-- TR52's block, the signature on a tap: the readout is the button. A tap squeezes it by Press, gone over PressTime,
		-- on the frame it lands; armed and waiting for its target's range, it stays in by Armed. A full ring left untapped
		-- pulses once by Pulse.Scale over Pulse.Length, Pulse.Hold seconds after its ready swell or its fade in, so the two
		-- never merge (the seed's 0.5 s). The Auto toggle after the eye, Auto.Width points wide.
		Press = 0.12,
		PressTime = 0.14,
		Armed = 0.06,
		Pulse = { Hold = 0.5, Length = 0.4, Scale = 0.16 },
		Auto = { Width = 100 },
		-- Where the ring stands (TR52, research's add for the director's run): "Card", under the lead's card, the left
		-- thumb's, the one that walks; "Jump", over Roblox's jump button, the right thumb's, its centre over the button's
		-- and Jump.Above points clear of its top. The eye and Auto stay in the corner either way.
		At = "Card",
		Jump = { Above = 12 },
	},
	-- The spectate toggle (TR11; the director, 2026-11-14, night: the player's camera is never moved in a fight, and a small
	-- button follows the lead instead). The eye (AR12: one family with the readout): its plate Plate across, open and lit
	-- while on, shut and dim while off, in a tap box Size square (Theme.Size.Tap: a whole 44 px target at the layer's
	-- smallest scale); Right of the readout and Lower than its top. Off while it can't be used, it draws at Off of itself.
	-- On, the camera's point eases from the avatar's focus to the lead's, Height studs over the lead's root, about 95% of
	-- the way in Ease seconds (Rules.Hud.Approach); the player's drag and zoom are theirs throughout.
	Spectate = { Size = 52, Plate = 44, Right = 10, Lower = 7, Off = 0.45, Ease = 0.3, Height = 1.5 },
	-- Plates kept apart in a group (UI.World.Apart: the base's machine plates): Gap authored pixels between two, over and
	-- under, as the command view's chips (Config.BaseView.Chip.Gap). The builder's seed.
	Plates = {
		Gap = 6,
		-- A base machine's plate (AR65 must-fix 2: Modulo's kit on research's pick of target A, 2026-11-26; BaseController):
		-- AR62's cut plate (Theme.Frame: the panel's graphite top to foot in Fill, its rim in Edge, a hairline of light
		-- along its top), a tick Bar.W by Bar.H of the machine's Accent at its left and Bar.Gap before its name, in the
		-- display face's capitals in that accent, Row authored pixels tall, Pad at each side. Near, its lines under the
		-- name, Line each, in the body face's small size and the second words, Foot under the last; a stem Stem.W by
		-- Stem.H from its foot down to the machine. It stands Over studs above the top of its machine's laid pieces
		-- within Reach studs of its spot, whatever stage stands there, and draws at Ref over its distance of its size,
		-- never under Theme.Text.Minimum for its name nor over Most, near or far: target A's Mill and Breaker stand about
		-- 1.25 of it, its bays and Training about 0.85, from the spawn. The Stone Condenser's stands Aside studs out
		-- from the Mill, over its far horn, and sits on that side of its point on the screen, clear of the Mill's rim.
		-- The accents are the kit's (Modulo's base_kit.WEARS). The builder's seed, tuned by playing.
		Machine = {
			Fill = { Id = "rbxassetid://86497582966819", Pixels = Vector2.new(80, 80), Points = Vector2.new(20, 20), Cut = { 9, 9, 9, 9 }, Pad = 0 },
			Edge = { Id = "rbxassetid://101281545115611", Pixels = Vector2.new(80, 80), Points = Vector2.new(20, 20), Cut = { 9, 9, 9, 9 }, Pad = 0 },
			Accent = {
				Mill = Color3.fromHex("#33D6E6"),
				Breaker = Color3.fromHex("#B784FF"),
				Bay = Color3.fromHex("#FF7A59"),
				Training = Color3.fromHex("#5EDB72"),
				Condenser = Color3.fromHex("#5C86FF"),
			} :: { [string]: Color3 },
			Row = 26,
			Pad = 9,
			Line = 18,
			Foot = 5,
			Bar = { W = 3, H = 12, Gap = 6 },
			Stem = { W = 2, H = 9 },
			Over = 0.8,
			Reach = 18,
			Ref = 75,
			Most = 1.25,
			Aside = 3,
		},
	},
	-- The Stone Condenser's convert card (AR51's B, research's pick and pass of 2026-11-23; Modulo's condenser_card.json;
	-- BaseController): a plate's kin on the system slab, beside the cradle, shown as the Comb's plate is. Its left edge
	-- Place.X right of the cradle's point on the screen and its top Place.Y under it (negative: above), in points, and
	-- never nearer than Plates.Gap to the right of the convert prompt's card (UI.World.Beside: Roblox draws that card
	-- under every layer, so the card over it hid its words, the build's finding at AR51's capture). Size
	-- while awake, Asleep high while the base is under Config.Condenser.Wakes (the cost line alone, dimmed; the Comb's
	-- plate says what wakes it). Wider when its word needs it: Word.At plus the word plus Word.End.
	--   Cost: each number at Digit points in the number face, its stone Stone points across, Gap after the number; the
	--         Arrow box Before and After it; the whole line Top down, Left in. Dim, its transparency when it can't start.
	--   Bar:  At and Size, its Bed's colour, its fill Inset inside, Ready's and Running's colours (the stones' own seam).
	Convert = {
		Size = Vector2.new(172, 70),
		Asleep = 44,
		Place = Vector2.new(22, -50),
		Cost = { Left = 12, Top = 4, Digit = 20, Stone = 36, Gap = 3, Arrow = Vector2.new(8, 12), Before = 7, After = 8, Dim = 0.45 },
		Bar = { At = Vector2.new(12, 50), Size = Vector2.new(64, 10), Bed = Color3.fromHex("#070A0C"), Inset = 1, Ready = Color3.fromHex("#F6FCFF"), Running = Color3.fromHex("#FFB878") },
		Word = { At = 84, End = 12 },
	},
	-- A quiet note under the lead's corner, where the level-up's notice shows (docs/ui.md, rule 2; TR46: the heal cap told
	-- once): it fades in over In seconds, sliding Slide points out of the left unless Reduced Motion, holds Hold, fades out
	-- over Out. Its backing at Back's transparency, Pad points around its words.
	Note = { In = 0.25, Hold = 4.5, Out = 0.4, Slide = 10, Back = 0.3, Pad = 8 },
	-- The level-up's notice (AR12, take B, the director's pick of 2026-11-15; Modulo's levelup_notice.json; UI.LevelNotice;
	-- TR41 (c)). A plate Tall points high, in the lead card's violet, Below the lead's corner (its readout's foot) at the
	-- card's left edge, Base + the wider of its name and its line across. Its block is Block wide and leans Lean across per
	-- down, as do its ends. Above the HUD's parts at Z. The words in the game's face: Modulo's sizes are Blender's, whose
	-- capitals stand 1.2 times the game's at the same size (measured on its sheet: "Rook" 34.9 points drawn, 29.3 at 16 in
	-- Builder Sans; the digits 18.8 tall), so each size here is the json's times 1.2. A word stands by its capitals' top:
	-- Capitals is where they stand in the face's line (its top and height, shares of the size; Digits the bold figures),
	-- measured in Studio at 100. "LEVEL UP" is spaced by hair spaces (0.67 points each at 11), Blender's 1.14.
	-- Its sheen's band crosses the foot Sheen.Middle points from its image's left. The motion is Rules.Hud.Notice.
	-- The plate is cut across only, as the json cuts it: its ends keep their size and its middle stretches. It's laid as
	-- three plain pieces of its image, not Roblox's slice: under the layer's scale a slice drew this plate wrong (measured in
	-- Studio, 2026-11-17: cut across only, nothing at all; with rows above and under, its rows far too short).
	LevelNotice = {
		Images = {
			Plate = { Id = "rbxassetid://86056784616806", Pixels = Vector2.new(656, 304), Points = Vector2.new(164, 76), Cut = { 80, 0, 74, 0 }, Pad = 16 },
			Flash = { Id = "rbxassetid://101874891515818", Pixels = Vector2.new(247, 176), Points = Vector2.new(61.8, 44), Pad = 0, At = Vector2.new(-1, 0) },
			Sheen = { Id = "rbxassetid://138783457538831", Pixels = Vector2.new(295, 176), Points = Vector2.new(73.8, 44), Pad = 0 },
		} :: { [string]: UIKit.Image },
		Tall = 44,
		Block = 40,
		Lean = 0.45,
		Base = 83.8,
		Below = 8,
		Z = 6,
		Capitals = { Top = 0.224, Tall = 0.552 },
		Digits = { Top = 0.216, Tall = 0.56 },
		Words = {
			-- Centred on the block, as the json's note says: the block's lavender centres at 30.75 points across at the
			-- digits' middle height in Modulo's plate image (measured 2026-11-17), where the json's middle says 28.9.
			Number = { Middle = Vector2.new(30.75, 22), Sizes = { 32, 30, 23 }, Colour = Color3.fromHex("#1D1245") },
			Name = { At = Vector2.new(63.95, 8), Size = 19, Colour = Color3.fromHex("#FFFFFF") },
			Line = { Text = "L\u{200A}E\u{200A}V\u{200A}E\u{200A}L\u{200A} \u{200A}U\u{200A}P", At = Vector2.new(55.4, 28), Size = 13, Colour = Color3.fromHex("#D8C8FF") },
		},
		Sheen = { Middle = 27 },
		Motion = {
			In = 0.2,
			Fall = 0.12,
			From = 1.9,
			Squash = 0.88,
			Settle = 0.1,
			Flash = { Strength = 0.75, Seconds = 0.14 },
			Knock = { Points = 1.5, Seconds = 0.12 },
			Sheen = { After = 0.1, Seconds = 0.5, Reach = 30, Fade = 26 },
			Hold = 2.5,
			Out = 0.2,
			Fade = 0.2,
		},
	},
	-- The next step's marker (TR24's fix 1; UI.Guide): a chevron Lift studs over each target, bobbing Bob studs Rate times a
	-- second, Size authored points wide; off the frame, one arrow at its edge, Margin authored points in from the sides,
	-- Top from the top and Bottom from the foot (clear of the cards and the dock). Within Near studs of the avatar it steps
	-- back for the target's own prompt. The keeper's gate is pointed at within Reach studs of it. The builder's seeds.
	-- The Play panel (the director, 2026-11-24: "i asked for the play button to open a panel of gamemode"; Rules.Modes;
	-- UI.ModeScreen), in grey until its feel line's review: a card a mode, the Festival's Wide and the Tower's Narrow, Tall
	-- at the most, Gap apart; the cards rise in Rise points over Seconds, Stagger apart, and at once when the panel opens
	-- again within Again seconds. On = false gives the dock's Play the Arc panel again, as before (TR50).
	Modes = { On = true, Wide = 300, Narrow = 220, Tall = 196, Gap = 10, Rise = 14, Seconds = 0.2, Stagger = 0.04, Again = 60 },
	Guide = { Lift = 1.5, Bob = 0.35, Rate = 0.9, Size = 36, Margin = 56, Top = 84, Bottom = 120, Near = 12, Reach = 800,
		-- The edge's arrow (TR24's fix 2: it read as a small lilac stroke on the sky): an arrow, shaft and head, on a round
		-- dark backing Size points across, the backing in the chevrons' ink at Backing, rimmed in the guide's colour at Rim;
		-- Clear points between its foot and the next step's chip, or off the chip's end where it rides the chip (its own spot
		-- over the avatar, a prompt or a plate: research's call on AR51, 2026-11-23).
		Edge = { Size = 60, Backing = 0.15, Rim = 0.3, Clear = 6 } },
	-- AR30, every button in the seam's make (Modulo's numbers, 2026-11-17, 15:00; asset-requests, AR30, "The cut, the images
	-- and the numbers for Faber"): a pressable thing is dark glass lit from its foot at L in its light colour, or the plain
	-- channel. Sizes are authored points, T a layer's ImageTransparency. Colours are the Seam palette's (Config.UIKit), and
	-- Light below a kind's own. Seeds, tuned in play: Tune("Hud.Make.Sink", 2).
	Make = {
		Images = {
			DockSeamBase = { Id = "rbxassetid://101111358271877", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			DockSeamBody = { Id = "rbxassetid://120288857758554", Pixels = Vector2.new(770, 248), Points = Vector2.new(192.5, 62), Pad = 0 },
			DockSeamCallMid = { Id = "rbxassetid://96997959999931", Pixels = Vector2.new(411, 376), Points = Vector2.new(102.75, 94), Pad = 0 },
			DockSeamCallWing = { Id = "rbxassetid://117349466656055", Pixels = Vector2.new(371, 336), Points = Vector2.new(92.75, 84), Pad = 0 },
			DockSeamEdge = { Id = "rbxassetid://116879340527241", Pixels = Vector2.new(770, 248), Points = Vector2.new(192.5, 62), Pad = 0 },
			DockSeamFootMid = { Id = "rbxassetid://114305255121830", Pixels = Vector2.new(267, 232), Points = Vector2.new(66.75, 58), Pad = 0 },
			DockSeamFootWing = { Id = "rbxassetid://106010594765096", Pixels = Vector2.new(227, 192), Points = Vector2.new(56.75, 48), Pad = 0 },
			DockSeamGlassMid = { Id = "rbxassetid://133510593265528", Pixels = Vector2.new(267, 232), Points = Vector2.new(66.75, 58), Pad = 0 },
			-- Home's mark (AR43): Modulo's DockMarkHomeMask, a white mask in the Items page's place and square.
			DockSeamHome = { Id = "rbxassetid://108425291864907", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			DockSeamGlassWing = { Id = "rbxassetid://110774430206065", Pixels = Vector2.new(227, 192), Points = Vector2.new(56.75, 48), Pad = 0 },
			DockSeamLightMid = { Id = "rbxassetid://71451440044467", Pixels = Vector2.new(411, 376), Points = Vector2.new(102.75, 94), Pad = 0 },
			DockSeamLightWing = { Id = "rbxassetid://124228959542597", Pixels = Vector2.new(371, 336), Points = Vector2.new(92.75, 84), Pad = 0 },
			DockSeamMap = { Id = "rbxassetid://76450894205228", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			DockSeamShadow = { Id = "rbxassetid://126174280533213", Pixels = Vector2.new(962, 440), Points = Vector2.new(240.5, 110), Pad = 0 },
			SeamChevron = { Id = "rbxassetid://87298639484008", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamClose = { Id = "rbxassetid://132295505672780", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamFoot = { Id = "rbxassetid://124112477894928", Pixels = Vector2.new(112, 16), Points = Vector2.new(28, 4), Cut = { 10, 0, 10, 0 }, Pad = 0 },
			SeamFootGlow = { Id = "rbxassetid://78206033974809", Pixels = Vector2.new(256, 144), Points = Vector2.new(64, 36), Cut = { 28, 0, 28, 0 }, Pad = 0 },
			SeamHalo = { Id = "rbxassetid://123474220477559", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamMark = { Id = "rbxassetid://81214305959157", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamMinus = { Id = "rbxassetid://75848718889044", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamPipGlow = { Id = "rbxassetid://83810068457044", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamPlus = { Id = "rbxassetid://107263844901515", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamRates = { Id = "rbxassetid://78602826016043", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
			SeamUnderline = { Id = "rbxassetid://110759843540232", Pixels = Vector2.new(304, 64), Points = Vector2.new(76, 16), Pad = 0 },
			SeamUnderlineGlow = { Id = "rbxassetid://133063172941339", Pixels = Vector2.new(304, 64), Points = Vector2.new(76, 16), Pad = 0 },
		} :: { [string]: UIKit.Image },
		-- The glass: the Panel gradient at Fill; the ring's glow at 1 - RingGlow·L; the wash in the light at 1 - L/Wash,
		-- falling from the foot up (WashFall: where, T); the edge at 1 - Edge·L; the foot's glow at 1 - FootGlow·L, Reach
		-- past each side and the foot, and the foot itself Foot tall at T 0.
		Glass = {
			Fill = 0.03,
			RingGlow = 0.44,
			Wash = 1.45,
			WashFall = { { 0, 0.913 }, { 0.4, 0.867 }, { 0.6, 0.756 }, { 0.75, 0.607 }, { 0.9, 0.384 }, { 1, 0.188 } },
			Edge = 0.6,
			FootGlow = 0.5,
			Reach = 18,
			Foot = 4,
		},
		-- The channel: Channel at T Rest; Main for an unavailable main action, Off for an unavailable second one; edged in
		-- Edge, or Pressed's edge with a wash of the light falling as PressedFall while a finger holds it.
		Channel = {
			Rest = 0.22,
			Main = 0.3,
			Off = 0.38,
			PressedEdge = Color3.fromHex("#8B83A3"),
			PressedFall = { { 0, 0.95 }, { 0.4, 0.915 }, { 0.6, 0.871 }, { 0.75, 0.826 }, { 0.9, 0.772 }, { 1, 0.73 } },
		},
		-- The lit press (AR43's B, Modulo's cut: build/handoff/UI/seam/seam.json, "press"): the plate down Fill's stops, its
		-- hairline white at T Edge, the glow round it in Glow at T GlowAlpha (GlowSet while it's set), its words in the
		-- seam's Ink. Pressed, the plate at T Down; off, the plate at T Off, its hairline at OffEdge, its words at OffWords,
		-- and no glow (research's 16:19, on the Shop's Buy). The cut's sheen comes with its idle phase.
		Lit = {
			Fill = { { 0, "#FFFFFF" }, { 0.4, "#EEE8FF" }, { 0.55, "#E6DEFF" }, { 0.7, "#E0D5FF" }, { 0.85, "#D9CDFF" }, { 1, "#D4C6FF" } },
			Edge = 0.1,
			Glow = Color3.fromHex("#D4C6FF"),
			GlowAlpha = 0.55,
			GlowSet = 0.3,
			Down = 0.15,
			Off = 0.62,
			OffEdge = 0.6,
			OffWords = 0.3,
		},
		-- L: a main action at rest and pressed; set (Leading); a second action on (Auto); a chosen chip.
		L = { Main = 1, Pressed = 1.45, Set = 0.6, On = 0.75, Chosen = 0.9 },
		-- A press sinks Sink points; the light rises over Down seconds and falls back over Up (the release flash). Research's
		-- seed: a sink of 1 to 2 and a release flash.
		Sink = 1,
		Down = 0.05,
		Up = 0.25,
		-- The word: a second action's Over the middle; on or chosen, OnOver; an unavailable one's name Rise over it and its
		-- reason Fall under it.
		Word = { Over = 1.2, OnOver = 1, Rise = 8, Fall = 9 },
		-- A second action's underline: half Rest × min(Share × its width, Most) at rest, the whole at a press, its middle
		-- Over the foot. Its image spans Span of its drawn width, Tall high. Line and Glow: T at rest and pressed.
		Underline = { Share = 0.3, Most = 26, Rest = 0.8, Over = 5, Span = 76 / 64, Tall = 16, Line = { 0.45, 0 }, Glow = { 0.835, 0.4 } },
		-- A main action set (Leading): its mark Side across in the light, its middle Left of the word's left edge, and the
		-- pair Shift to the right.
		Mark = { Side = 11.3, Left = 7, Shift = 5 },
		-- An icon's button (the X): no plate, the icon Side across in Text; pressed, in the light over its halo (Halo across
		-- at HaloT) with an underline of Half whose middle is Below the icon's (the line at Line, its glow at Glow); unavailable,
		-- in Faint. The X's touch is Box square at a panel's top right, In from its corner.
		Icon = { Halo = 56.6, HaloT = 0.7, Half = 9, Below = 20, Line = 0, Glow = 0.55 },
		Close = { Side = 20.7, Box = 52, In = 4 },
		PlusMinus = 17.2, -- Power's ±: the channel with SeamPlus or SeamMinus this many across, in Text
		-- A chip on a tabs' row (the bag's kinds): the row is one channel and a chip has no plate of its own. At least Least
		-- wide, its word plus Pad; its word in Soft, off in Faint. Chosen, the glass at L.Chosen Inset inside its box, its word
		-- in Text; pressed, its word in Text over an underline of half Under × its width (the line at Line, its glow at Glow),
		-- no sink. The row's splits: Split of a point wide in Edge, SplitTall high and centred, only between two unchosen chips.
		Chip = { Least = 52, Pad = 30, Inset = 1.5, Under = 0.32, Line = 0.2, Glow = 0.6, Split = 0.85, SplitTall = 26 },
		-- A picker (Sort; the salvage's steps): the channel, its words plus Pad wide. Its name in Soft from In, then Gap, then
		-- its value in Text, bold; the chevron Chevron across in Text, its middle In from the right and Drop under the middle.
		-- On (anything but the default): the value and the chevron in the light over an underline of half Under × its width;
		-- pressed, that underline whether on or not (Line and Glow: T on, pressed), no wash, no sink. Unavailable, all Faint.
		-- Gap is measured from the make's sheet (AR30, buttons_kit.png: 65 px at its 2.64 to a point), the spec giving none.
		Pick = { Pad = 44, In = 15, Gap = 24, Chevron = 12.3, Drop = 1, Under = 0.3, Line = { 0.2, 0 }, Glow = { 0.52, 0.4 } },
		-- The kinds' own lights: a claim and a ready shard, the base's, the map's.
		Light = { Ready = Color3.fromHex("#F6DE80"), Power = Color3.fromHex("#F2C53D"), Map = Color3.fromHex("#E0566E") },
		-- The dock (AR30, "The dock"; UI.Dock), in points from its frame's top left. Its frame is Frame across, its foot on
		-- today's tiles' foot and centred where today's dock stands: At inside today's Box, which the HUD places and the
		-- chip stands over. The channel: the shadow Shadow round it in Channel at ShadowT, the body in Channel at BodyT,
		-- its edge in Edge. Each cell: its glass (Glass Wing or Mid) at its place with the Panel gradient at GlassT, its
		-- light Out bigger each side in its hue at 1 - L/Top, its foot in its hue; its icon in Text, Side across on its
		-- middle; its touch its column, Tap. Calling (something new): L Calling, its call ring Out bigger in its hue, and the
		-- pip on Pip: the glow Glow across in its hue at GlowT, then SeamMark Rings across in Ink, its hue and Light. L at
		-- rest, pressed (no sink), its screen open. Quiet (TR19, nothing to do here) and Dim (refused) are the builder's,
		-- for research's read: less light, the icon in Soft or Faint, a dim foot at DimFoot. A pointer lifts it
		-- Motion.Hover.Lift and raises L toward Pressed by Motion.Hover.Halo of its share; a pad's selection wears its rim,
		-- the call ring in Light.
		Dock = {
			Box = Vector2.new(196, 68),
			Frame = Vector2.new(192.4, 62),
			At = Vector2.new(1.8, -3),
			Out = 18,
			Shadow = 24,
			ShadowT = 0.55,
			BodyT = 0.1,
			GlassT = 0.03,
			Top = 1.45,
			-- At rest a cell's colour lives in its foot bar, inside its glass: a halo past it means "this one" (AR30, "The
			-- dock's shine, reopened": the director, 2026-11-23, "a bit to shiny"). Dim < Quiet < Rest < Open < Pressed < Calling.
			L = { Rest = 0.4, Calling = 1.45, Pressed = 1.3, Open = 0.6, Quiet = 0.2, Dim = 0, Charge = 0 },
			DimFoot = 0.7,
			Glass = { Wing = Vector2.new(56.8, 48), Mid = Vector2.new(66.8, 58) },
			Cells = {
				{ Name = "Base", Kind = "Wing", Glass = Vector2.new(2, 12), Icon = Vector2.new(30.4, 33.5), Side = 39.4, Pip = Vector2.new(57.8, 13), Tap = { 0, 10, 60.8, 52 } },
				-- Home (AR49): Home's panel (UI.HomePanel).
				{ Name = "Home", Kind = "Mid", Glass = Vector2.new(62.8, 2), Icon = Vector2.new(96.2, 28.5), Side = 49.2, Pip = Vector2.new(128.6, 3), Tap = { 60.8, 0, 70.8, 62 } },
				-- Its word (a long press) is Word: the director, 2026-11-19, "the map button that should be renamed to play or
				-- something else and open FOB" (TR45). Its name stays the cell's, for its images and light.
				{ Name = "Map", Word = "Play", Kind = "Wing", Glass = Vector2.new(133.6, 12), Icon = Vector2.new(162, 33.5), Side = 39.4, Pip = Vector2.new(189.4, 13), Tap = { 131.6, 10, 60.8, 52 } },
			},
			Pip = { Glow = 54.2, GlowT = 0.2, Rings = { 24.6, 18.7, 10.8 } },
		},
	},
	-- Home's panel (AR49 in C: research's pick of 2026-11-19, 23:54, its second look of 2026-11-20, 00:07; UI.HomePanel;
	-- build/handoff/UI/home_cards/home_cards.json). The dock's middle cell opens it over the world dimmed, the dock lit: three
	-- cards, Equipment, Voidkin (the lead, live) and Settings, each opening its whole screen on the page last shown. Every
	-- place is in points from the glass's top left, at the same size on every phone. Its left is the lead's card's right
	-- plus Gap, or the phone's middle less half its width if that's further right, never past the phone's right less Edge;
	-- its foot Above over the dock's top; the pointer's middle on the Home cell's. Each image lies whole in its box
	-- (Images: kit name, left, top, wide, tall), in its card, bottom to top; a card's press image shows while it's held or
	-- lit, laid under the live view on Voidkin (research's condition 1). Tap: each card's column, split at the seams'
	-- middles (measured on the images' alpha). Words: TextLabels in the face's bold italic, their capitals' top left at
	-- x, y (Settings' its middle), a dark copy Shadow under. Open: the glass grows from From about the pointer with a Back
	-- ease over Grow and fades in over Fade, the cards landing Stagger apart, each rising Rise points and fading in over
	-- Land; it leaves quicker, over Leave, all at once. Seeds from Modulo's cut, tuned live.
	Home = {
		Size = Vector2.new(371, 184),
		Gap = 8,
		Edge = 6,
		Above = 9,
		Glass = { "HomeGlass", -16, -16, 403, 216 },
		Pointer = { "HomePointer", -12, 181, 24, 13 }, -- its left and wide about the Home cell's middle
		Cards = {
			{
				Name = "Equipment",
				Screen = "Equipment",
				Tap = { 0, 0, 124.7, 184 },
				Z = 3,
				Images = { { "HomeEquipment", -2, -2, 149.6, 188 } },
				Press = { "HomeEquipmentPress", -2, -2, 149.6, 188, Color3.fromHex("#FF8A3D") },
				Words = { { "Word", "Equipment", 20, 153.1, 17.9, "Left" }, { "Level", "+7", 45.5, 33.8, 16.5, "Left", Color3.fromHex("#FFD36B") } },
			},
			{
				Name = "Voidkin",
				Screen = "Voidkin",
				Tap = { 124.7, 0, 141.9, 184 },
				Z = 2,
				-- under the live view (Lit: tinted the lead's light), then over it
				Images = { { "HomeVoidkinBack", 102, -2, 187.6, 188 }, { "HomeVoidkinGlow", 102, -2, 187.6, 188, "Lit" }, { "HomeVoidkinRimTop", 102, -2, 187.6, 188, "Lit" } },
				Over = { { "HomeVoidkinFrame", 102, -2, 187.6, 188 }, { "HomeVoidkinRim", 102, -2, 187.6, 188, "Lit" } },
				Press = { "HomeVoidkinPress", 102, -2, 187.6, 188, "Lit" }, -- over the Back, under the Glow and the view
				Words = { { "Word", "Voidkin", 124, 150.2, 22, "Left" } },
			},
			-- Settings' column (AR53 in B, build/handoff/UI/goals/goals.json, "today"; TR54): Settings is a cog tile at its
			-- top, today's three a card under it.
			{
				Name = "Settings",
				Screen = "Settings",
				Tap = { 278, 8, 85, 44 },
				Z = 3,
				Images = { { "HomeCog", 268, -2, 105, 64 } },
				Press = { "HomeCogPress", 268, -2, 105, 64, Color3.fromHex("#AEB7C2") },
				Words = {},
				Mark = { "HomeMarkSettings", 320.7, 30, 24, Color3.fromHex("#C9D0D9") },
			},
			{
				Name = "Today",
				Stay = true, -- its press opens the list in the glass, not a screen
				Tap = { 254, 58, 99, 118 },
				Z = 3,
				Images = { { "HomeToday", 242, 46, 123, 142 } },
				Press = { "HomeTodayPress", 242, 46, 123, 142 },
				Words = { { "Word", "Today", 293.3, 156.92, 14, "Centre" } },
			},
		},
		-- Today's three (TR54; AR53, goals.json "today"), in points from the glass's top left. The card: Waits over its
		-- art while any goal waits to be claimed, the shard's picture in Shard, today's three as pips at Pips (open, done,
		-- claimed), in the lists' order. The list, in the glass alone: Next pinned at its head (its plate laid from Left, Top
		-- by its image's origin; the back press Back.Tap, its chevron Back.Chevron; its lines from the plate's left at
		-- Lines.X + Lines.Lean x (Lines.Base - y), at Lines.Y or Lines.Alone, "Next" in Label, the step Label.Step right of
		-- it); under it the rows scroll from Rows.From to the glass's foot, padded Rows.Pad. A row: from Rows.Left, Tall,
		-- Gap between, its image by its origin, its words, shard, right-hand text and check from the row's left; a banked
		-- day under its heading (Day). The thumb at Thumb.X when the rows pass the room.
		Today = {
			Waits = { "HomeTodayWaits", 242, 46, 123, 142 },
			Shard = { "ShardStandardSmall", 287.5, 72, 40, 40 },
			Pips = { Images = { Open = "GoalPipOpen", Done = "GoalPipDone", Claimed = "GoalPipClaimed" }, Y = 130, X = { 287.7, 300.7, 313.7 }, Side = 28 },
			Next = {
				Image = "GoalNext", Left = 10, Top = 3, Tall = 40, Origin = Vector2.new(12, 12), Size = Vector2.new(374, 64),
				Back = { Chevron = { Vector2.new(39, 17), Vector2.new(33, 23), Vector2.new(39, 29) }, Width = 1.8, Tap = { 8, 1, 46, 44 } },
				Lines = { X = 50, Lean = 0.2, Base = 35, Y = { 6, 23 }, Alone = 15, Size = 14, Colours = { Color3.fromHex("#F5EFE2"), Color3.fromHex("#AEB7C2") } },
				Label = { Colour = Color3.fromHex("#AFC6F0"), Step = 38 },
			},
			Rows = {
				From = 43, Pad = { 2, 3 }, Left = 10, Tall = 44, Gap = 2, Wide = 351,
				Images = { Open = "GoalRow", Done = "GoalRowDone", Claimed = "GoalRowClaimed", Press = "GoalRowPress" },
				Origin = Vector2.new(12, 12), Size = Vector2.new(375, 68),
				Words = { X = 18.4, Y = 15, Size = 14, Colour = Color3.fromHex("#F5EFE2"), Claimed = Color3.fromHex("#7E879A") },
				Shard = { 306.4, 6, 32, 32, Open = 0.5 }, -- its box from the row's left; dim while open
				Right = { X = 298.4, Y = 15, Size = 14, Count = Color3.fromHex("#AEB7C2"), Claim = Color3.fromHex("#FFD880") },
				Check = { Image = "GoalCheck", At = Vector2.new(322.4, 22), Side = 24 },
			},
			Day = { Tall = 22, X = 24, Y = 4, Size = 14, Colour = Color3.fromHex("#8F99A6") },
			Thumb = { X = 366, Wide = 2, Colour = Color3.fromHex("#55607A") },
			Switch = 0.14, -- seconds the cards and the list cross
			-- The welcome week's row (TR59; docs/design.md, "The welcome week and codes"), a grey block for research's
			-- verdict: under its heading at the list's head, seven tiles across the rows' width, each its day, its gift's
			-- picture (day 7 Lyric's face from day 1) and, once taken, the check. Today's lit and taken with one tap; later
			-- ones dim. While today's waits the card's gold rim shows, as for a goal to claim.
			Week = {
				Heading = "Welcome week",
				Day = "Day",
				Tall = 62, Gap = 4, Corner = 6,
				-- Fade: a picture's stand-in words (Home's Word), clear by state and still 4.5:1 on its fill. A taken day shows
				-- its check alone (research's must-fix, 2026-11-26), so no picture or words of its gift.
				Words = { Y = 5, Size = 12, Colour = Color3.fromHex("#AEB7C2"), Fade = { Today = 0, Later = 0.25 } },
				Picture = { Y = 20, Side = 34, Face = "CardFaceLyric", Shard = "ShardStandardSmall" },
				Fill = { Later = Color3.fromHex("#2B313C"), Today = Color3.fromHex("#3A4150"), Taken = Color3.fromHex("#20252D") },
				Dim = { Later = 0.55, Today = 0 }, -- the picture's transparency
				Lit = Color3.fromHex("#FFD880"), Stroke = 1.5,
				Check = 22,
			},
		},
		Word = Color3.fromHex("#F5EFE2"),
		Shadow = { Offset = Vector2.new(0.8, 1.2), Colour = Color3.fromHex("#000000"), T = 0.45 },
		CapTop = 0.24, -- the face's capitals' top, a share of its size under the label's top
		Lift = 0.4, -- the lead's light: its rarity's Card.Trim lifted this share toward white
		-- The live view (research's condition 2): the lead's own model in its idle, head and chest. Its head's top at Crown and
		-- the share Chest down its torso at Foot (panel points), its head's middle at the card's middle across (Across), turned
		-- Yaw degrees, its head brought back Head; Fov the camera's. Each Voidkin's own offsets in Each (any of Yaw, Head,
		-- Chest, X and Y in points) keep a held weapon whole or out of frame. Lit from behind and above in the lead's light,
		-- the face by Ambient.
		Live = {
			Box = { 112, -16, 167.6, 192 },
			Crown = -6,
			Foot = 176,
			Chest = 0.55,
			Across = 195.8,
			Yaw = -34,
			Head = 22,
			Fov = 20,
			Ambient = Color3.fromHex("#B4B8C2"),
			Light = Vector3.new(0.3, -0.7, -1),
			Each = {
				-- Framed a little closer (the chest's line at 0.45, about 10% larger, the crown unmoved): in her idle the top of
				-- her pale glove rose to the window's foot, a white sliver under "Voidkin" (research's must-fix 1 on AR49,
				-- 2026-11-23). 6 points lower (Y) still left it there; at 0.45 it sits about 12 points under the foot.
				Kirra = { Chest = 0.45 },
			} :: { [string]: { Yaw: number?, Head: number?, Chest: number?, X: number?, Y: number? } },
		},
		Dim = { Colour = Color3.fromHex("#05090B"), Amount = 0.6, Seconds = 0.15, Side = 100 },
		Open = { Grow = 0.22, From = 0.9, Back = 1.2, Fade = 0.12, Stagger = 0.045, Order = { "Voidkin", "Equipment", "Settings", "Today" }, Land = 0.16, Rise = 8, Leave = 0.12, LeaveTo = 0.96 },
		Step = { Lit = 0.06, Leave = 0.12, LeaveTo = 0.96, RiseAt = 0.08, Rise = 0.22, RiseFrom = 24, Cover = 0.08, Sink = 0.14, Uncover = 0.1, BackAt = 0.06 },
	},
	Stages = stages,
	-- Equipment's three screens from Home (TR47; AR43, "The cut in B, for Faber": build/handoff/UI/equipment/equipment.json
	-- and ../seam/seam.json), in Seam's lit glass (UIKit.Palettes.SeamGlass). Every place is the cut's, in points on the
	-- smallest phone (568 x 320) from the screen's top left; the game lays the Block (the rail, the list and the work)
	-- from its own top left, scaled to the room it has, at most Grow. Colours are the palette's unless named here.
	Equipment = {
		Pages = { "Reinforce", "Jewels", "War Emblems" },
		Block = { Left = 0, Top = 56, Wide = 568, Tall = 260, Grow = 1.6 },
		Backing = { Color3.fromHex("#1F1942"), Color3.fromHex("#0D0B1A") }, -- the ground, top to foot
		Bloom = { At = Vector2.new(433, 150), Size = Vector2.new(750, 600), Tint = Color3.fromHex("#5C48AC"), Alpha = 0.7 },
		TopLight = { Height = 160, Fall = 40, Strength = 0.06 }, -- the glint down the screen's top: 1 - Strength x exp(-y / Fall)
		Good = Color3.fromHex("#7CF0A4"), -- a rise's
		Hurt = Color3.fromHex("#FF786E"), -- a fail's, and too few stones
		Panel = { Sheen = 0.89, Glint = 0.15, Edge = { 0.1, 0.7 } }, -- the lift's, the corner's and the edge's transparencies
		Rail = {
			X = 48,
			Buttons = { Reinforce = { 48, 104, "PageForge" }, Jewels = { 48, 186, "PageJewels" }, ["War Emblems"] = { 48, 262, "PageWarEmblems" } }, -- the marks: the Voidkin screen's page icons (Voidkin.Chrome.Images)
			Rest = 20,
			Chosen = 27,
			Line = { Wide = 1.2, Alpha = 0.55 },
			Pieces = {
				Reinforce = { { 66, 77 }, { 157, 166 }, { 231, 242 } },
				Jewels = { { 66, 84 }, { 149, 159 }, { 239, 242 } },
				["War Emblems"] = { { 66, 84 }, { 149, 166 }, { 231, 235 } },
			},
			Word = { Gap = 7, Chosen = 15, Rest = 14 },
			Sheen = { Chosen = 0.78, Rest = 0.88 },
			Light = 0.82,
			Glow = 0.78,
			Edge = 0.2,
			Comet = 0.1,
			Runner = 0.15,
		},
		List = {
			Panel = { 98, 60, 300, 312 },
			First = 64,
			Pitch = 50,
			Tall = 46,
			Box = { 101, 297 },
			Cell = { 3, 3, 40 },
			Name = { 51, 5 },
			Holds = 24,
			Glint = 0.8,
			Wash = 0.7,
			Glow = 0.9,
			EdgeChosen = 0.1,
		},
		Work = { 306, 60, 560, 312 },
		Reinforce = {
			Name = Vector2.new(433, 66),
			Ring = Vector2.new(433, 110),
			Radius = 27,
			Cell = 40,
			Now = { X = 316, Word = 88, Level = 104, Stat = 126 },
			After = { X = 550, Word = 88, Level = 104, Stat = 126, Gain = 142 },
			Stone = { At = Vector2.new(420, 142), Side = 26 },
			Odds = { Y = 173, Success = 427, Dot = 433, Fail = 439 },
			Said = { At = Vector2.new(316, 192), Pitch = 17 },
			-- Forge heat (TR55's grey block, under the said lines): its word at Word, the track from From to To at Y, Tall
			-- high, filled in Colour by the item's heat; full, the track lit whole in the good and Full's words under its end.
			Heat = { Word = 316, From = 352, To = 550, Y = 240, Tall = 6, Colour = Color3.fromHex("#FF9A57"), Full = "Next try is sure" },
			Stones = { 318, 272, 382, 304, Picture = Vector2.new(322, 277), Side = 22, Count = 376 },
			Credits = { 388, 272, 462, 304, Picture = Vector2.new(392, 279), Side = 18, Count = 456 },
			Press = { 468, 266, 548, 310 },
			Bloom = 0.66,
			-- upgrade_motion.SEEDS (equipment.json, reinforce.motion), in seconds and points: the answer waits on the server,
			-- and shows no sooner than Least, so the stones land and the ring breathes (the cut's stand-in answer).
			Motion = {
				Least = 0.4,
				-- reinforce.motion's shapes: the breath from Breath.From, its ring Breath.Line wide at Breath.Light[1] + [2] u of
				-- light, its glow to Breath.Glow, the fill inside it to Breath.Fill, Breath.Inner round; the wave's line Waves.Line[1]
				-- + [2] (1 - v) wide, white turned green by Waves.Green v, its glow Waves.Glow; the sparks from Edge round; a fail's dull
				-- light Dull.Alpha of Dull.Tint, Dull.Round round; the gear dims over DimIn, back from DimFrom to DimBack, sinks over
				-- SinkIn, rises again from SinkFrom over SinkFor; the press's light back over Return.
				Breath = { From = 0.06, Line = 1.6, Light = { 0.25, 0.6 }, Glow = 0.35, Fill = 0.14, Inner = 25 },
				Waves = { Line = { 0.4, 2.2 }, Green = 2.5, Glow = 0.5 },
				Edge = 23,
				Dull = { Tint = Color3.fromHex("#FFD2CC"), Alpha = 0.3, Round = 26 },
				DimIn = 0.08, DimFrom = 0.2, DimBack = 0.45, SinkIn = 0.1, SinkFrom = 0.15, SinkFor = 0.25,
				Return = 0.1,
				Pending = 0.6, Fly = 0.22, Apart = 0.035, Stones = 3, Inhale = 16, Lift = 0.05, Flash = 0.14, Wave = 26, WaveFor = 0.32,
				Kick = 0.1, Texts = 0.3, Crack = 0.06, CrackFade = 0.4, Dim = 0.55, Sink = 0.04, Shake = 2, ShakeFor = 0.24, Settle = 0.8, Turn = 0.08,
			},
		},
		Emblems = {
			Name = Vector2.new(433, 66),
			Sockets = { Top = 84, Pitch = 60, Side = 46, Middle = 433, Value = 50, Stat = 66, StatPitch = 15 },
			Rule = { Y = 188, Ends = { 316, 550 }, Alpha = 0.55 },
			Heading = Vector2.new(318, 193),
			Sort = { 482, 191, 548, 211 },
			Combine = { 408, 191, 474, 211 }, -- the combine's pill, left of the sort's (TR56's block: the heading row's free end)
			Bag = { Top = 218, First = 319, Pitch = 46, Side = 40, Clip = { 307, 552 } },
			Said = { At = Vector2.new(318, 266), Pitch = 18 },
			Press = { Right = 550, Top = 262, Foot = 306, Put = 84, Out = 92 },
		},
		Jewels = {
			Order = JewelsConfig.Colours,
			-- Each colour's words and ring (build/handoff/UI/jewels/jewels.json), and the attribute it gives (Config.Jewels).
			Colours = {
				Red = Color3.fromHex("#FF6B7A"),
				Green = Color3.fromHex("#5FE39A"),
				Blue = Color3.fromHex("#6FA8FF"),
				Yellow = Color3.fromHex("#FFCF4D"),
				Purple = Color3.fromHex("#B98AFF"),
			} :: { [string]: Color3 },
			Attributes = JewelsConfig.Attribute,
			Sockets = { First = Vector2.new(313, 84), Pitch = 49, Side = 44, Value = Vector2.new(22, 48) },
			Rule = { Y = 156, Ends = { 316, 550 }, Alpha = 0.55 },
			Said = { At = Vector2.new(318, 166), Pitch = 18 },
		},
		-- The sockets' looks (equipment.json, images): the rest rim's and the glow's transparencies, the empty marks'.
		-- Transparencies (equipment.json's images): a rim, an empty one's, the chosen one's glow, the empty marks in a socket
		-- and in a list row.
		Socket = { Edge = 0.15, EmptyEdge = 0.5, Glow = 0.45, EmptyEmblem = 0.3, EmptyJewel = 0.45, RowEmblem = 0.2, RowJewel = 0.3 },
		-- Seam's idle and motion (seam.json): one loop for every idling piece; the opening and a rail switch.
		Idle = 2.4,
		-- Opening: row k slides in RowFrom points from the left from RowStart + k RowGap over RowTime; the work fades in from
		-- WorkStart over WorkTime; Reinforce's ring draws round from Ring.Start over Ring.Time; the gear grows from Pop.From.
		-- A rail tap: the buttons grow or shrink over Switch (a Back ease), the work dips over Cross, the rows' words cross.
		-- A row tapped: the glass glides over Glide; the old work leaves over Leave sliding Slide left, the new comes in over
		-- Enter from Slide right (reinforce.motion, rowTapped).
		Motion = {
			RowStart = 0.06, RowGap = 0.035, RowTime = 0.2, RowFrom = 24, WorkStart = 0.1, WorkTime = 0.22, Switch = 0.18, Back = 1.2,
			Glide = 0.2, Cross = 0.18, Slide = 8, Leave = 0.1, Enter = 0.16,
			Ring = { Start = 0.14, Time = 0.3, Swap = 0.1 }, -- drawn, the copies cross to the ring lit from above over Swap
			Pop = { Start = 0.14, Time = 0.24, From = 0.8, Back = 1.2 },
		},
	},
	-- Settings in B (AR43, "The cut in B, for Faber": build/handoff/UI/seam/seam.json, "settings"): one card of three
	-- sliders, Music, Sound and Effects (Rules.Settings), on Equipment's block, in the cut's points like Equipment's.
	-- Transparencies are ImageTransparency, at rest and held.
	Settings = {
		Card = { 88, 68, 480, 304 },
		-- each row's middle: the three sliders, then the Broadcast's two switches (TR57; the builder's re-pitch from the
		-- cut's 122, 186, 250 at 64, so five fit the card; research's pass to judge). A slider's whole row, the card wide and
		-- Pitch tall, drags it; a switch's whole row flips it.
		Rows = { 91, 137, 183, 229, 275 },
		Pitch = 46,
		Switch = { Wide = 64, Tall = 30 }, -- the On or Off press at the row's right, its right edge at Value.Right
		Name = { X = 110, Size = 15 }, -- bold, in the palette's Text, the light held
		Value = { Right = 458, Size = 14 }, -- "Off" or "N%", in Soft, the light and bold held
		Slider = { Start = 208, End = 402 },
		Track = 8, -- the channel's height, on the row's middle
		Fill = { Tall = 6, Light = { 0.75, 0.55 }, Glow = { 0.86, 0.7 }, Pad = 12 }, -- from 1 past the start to the knob
		Knob = { Rest = 10, Held = 12.5, Grow = 0.08, Sheen = 0.4, Edge = 0.1, Glow = { 0.65, 0.35 }, GlowPad = 18, Ring = 36, RingAlpha = 0.15, Foot = Color3.fromHex("#D4C6FF") },
		Divider = { Left = 106, Right = 462, Alpha = 0.4 }, -- between the rows, in the palette's Edge
		Glow = Color3.fromHex("#D4C6FF"), -- the knob's glow, lavender
		-- The codes (TR59; docs/design.md, "The welcome week and codes"), a grey block for research's verdict: the band's
		-- Codes press, at its right Right points in, turns the card to the codes and back. On it, the field and its Take
		-- press on the first row, the answer's line and the note on their middles, in the card's points; the card shrinks
		-- to Foot while they show, no empty middle, and the field wears the kit's neutral glass (Palette's Panel, its Edge
		-- round it, its Text and Soft), not violet (research's must-fixes, 2026-11-26). AR62's style frame restyles it.
		Codes = {
			Press = { Wide = 84, Tall = 30, Right = 12 },
			Field = { Right = 380, Tall = 34, Size = 15, Palette = "Graphite", Stroke = 1 },
			Line = { Y = 128, Size = 15 },
			Note = { Y = 153, Size = 13 },
			Foot = 176,
		},
	},
	-- The dock of three icons (AR12, in AR30's make: its look is Make.Dock): a touch held LongPress seconds shows the
	-- cell's word Rise points over its glass, and lifting it then doesn't press.
	Dock = {
		LongPress = 0.4,
		Rise = 6,
		-- TR19's seeds, UNVERIFIED: a cooldown's veil in ink at Veil; a refused tap's shake, Shake points either way over
		-- Shook seconds, three times, dying away.
		Veil = 0.5,
		-- A charge (research's verdict on TR19, corrected 2026-11-15): the glass goes to Ink at the tap, and the fill rises
		-- over it in Colour at Alpha, its rising edge a band Edge of the glass's height in Bright at full. White is a stand-in
		-- until the palette is picked (the director, 2026-11-15: nothing new goes violet). Seeds, tuned live.
		Charge = { Ink = Color3.fromHex("#0B0B12"), Colour = Color3.new(1, 1, 1), Bright = Color3.new(1, 1, 1), Edge = 0.1, Alpha = 0.85 },
		Shake = 4,
		Shook = 0.25,
	},
	-- The HUD's face (docs/ui.md, rule 3; the director, 2026-11-15: "the whole main hud of the player need a refont"): Face
	-- names one of Faces, from Roblox's own font library, for every label on FaceLayers; a label authored under
	-- FaceSmallUnder takes FaceSmall's when it names one (a face that fails at 14 pt keeps a plainer one for small text).
	-- A face: its family, the weight each of the kit's three roles draws in, and a digit's width in its text size at
	-- Strong (a health bar's number takes its compact form by it). Tuned live: Tune("Hud.Face", "Oswald").
	Face = "BuilderSans",
	FaceSmall = "",
	FaceSmallUnder = 16,
	FaceLayers = { "Hud", "Toasts" },
	Faces = {
		BuilderSans = { Family = "rbxasset://fonts/families/BuilderSans.json", Body = "Medium", Strong = "Bold", Number = "ExtraBold", Digit = 0.56 },
		Sarpanch = { Family = "rbxasset://fonts/families/Sarpanch.json", Body = "Medium", Strong = "Bold", Number = "ExtraBold", Digit = 0.6 },
		Oswald = { Family = "rbxasset://fonts/families/Oswald.json", Body = "Regular", Strong = "Medium", Number = "SemiBold", Digit = 0.5 },
		TitilliumWeb = { Family = "rbxasset://fonts/families/TitilliumWeb.json", Body = "SemiBold", Strong = "Bold", Number = "Bold", Digit = 0.52 },
	} :: { [string]: { Family: string, Body: string, Strong: string, Number: string, Digit: number } },
	-- The top right's pills (AR12, V2 Block): each wears its system's row (Config.UIKit.Systems). Widths, authored.
	Pills = { Credits = 124, Power = 200 },
	Fallen = { Dim = 0.55 }, -- a fallen lead's portrait: how far it dims (never a red wash)
	-- The cards' colours (TR3's verdict, 2026-11-13, fixes 1 to 3, with the director's notes). Health is the Ember light on
	-- both cards, and no other bar takes red; the content check's conditions are in TR3's verdict, fix 2. The lead's
	-- experience light is a cool colour of its own against the red. The trim round the lead card's bars and its level's badge is
	-- the lead's rarity's colour, never a fixed gold (AR3's in-use rule 4): the director's three rarity colours (AR3,
	-- section 4, settled), and for the rest Modulo's frames (tools/blender/ui_sheet.py, RARITIES): the glow, else the
	-- metal's light. Experience has this one colour: the thread, the level-up's word and ring, its toast. Room: the share
	-- of a health bar its number may take before it takes its compact form (fix 6).
	Card = {
		-- The lead's card and the foe's draw their lights in their colours (tools/blender/lead_card_art.py, the Ember pick
		-- of 2026-11-13); Xp stays experience's one colour for the level-up's ring and word.
		-- A level on both cards: the target's beside its name, "a tiny bit brighter and in yellow style" (the director,
		-- 2026-11-13), a soft gold a step brighter than the soft grey it replaced; the lead's on its badge the same, the
		-- director leaving it to the builder ("whatever best", 2026-11-13). Experience keeps its blue, the level this gold.
		Level = Color3.fromHex("#F2CB62"),
		-- The lead's level in take A (AR12, research's pick of 2026-11-17): the number and the chevrons in the HUD's ink on
		-- the Voidkin's Block; the level-up's pop lifts the block toward white (UI.LeadCard.Glow), its sparks stay this gold.
		LeadLevel = Color3.fromHex("#14161B"),
		-- The lead's stud takes its type's colour, as Modulo's mocks tint it (tools/blender/shade_sheet.py, TYPES).
		Types = {
			Red = Color3.fromHex("#EA4B4F"),
			Orange = Color3.fromHex("#F4902A"),
			Blue = Color3.fromHex("#3F9DF2"),
			Purple = Color3.fromHex("#A470F2"),
			Green = Color3.fromHex("#42CC7E"),
		} :: { [string]: Color3 },
		Xp = Color3.fromHex("#4E9BFF"),
		Trim = {
			Common = Color3.fromHex("#666C78"),
			Uncommon = Color3.fromHex("#7CF0A0"),
			Rare = Color3.fromHex("#6FB6FF"),
			Epic = Color3.fromHex("#D29CFF"),
			Legendary = Color3.fromHex("#FFD777"),
			Mythical = Color3.fromHex("#FF8794"), -- its metal's light, not its #FF2848 glow: kept apart from health's red
		} :: { [string]: Color3 },
		Room = 0.75,
		-- A heal of the lead's own shows on its bar (TR40, research's must-fix: a number about the lead's own state reads
		-- on the lead's own bar, never in the crowd of hits). A burst is a sliver of the bar, so a soft band in the heal's
		-- green, Band points wide and at most Peak opaque, runs from the bar's root to its front in Sweep seconds, holds
		-- there Hold seconds and fades over Fade. Its "+N", in the same green, stands Gap points after the health's digits
		-- and rises Rise points over Life seconds, fading in its last third. The builder's seeds.
		Heal = { Colour = UIKit.Numbers.Heal, Band = 26, Peak = 0.75, Sweep = 0.3, Hold = 0.15, Fade = 0.45, Gap = 4, Rise = 8, Life = 1.2 },
	},
	-- A bar's glow reaches at most this far past its light, authored pixels: the kit's 14 points at a tall bar's scale ran
	-- past the cards (TR3's take). Read when a bar is set.
	Bar = { GlowReach = 8 },
	-- The top band goes see-through over a keeper (research's call on AR7's fix 4, option B, 2026-11-13). While one of the
	-- rig's parts below stands under a piece on screen, the piece fades, eased at Rate a second: the economy pills and the
	-- shard toast to Economy, the Target card to Target and never lower, its bar and its health to Bar, so the fight's own
	-- read holds. It comes back once none has been under it for Hold seconds, so a hat grazing an edge doesn't flutter it.
	-- Opacities: 1 is whole. The builder's seeds for Rate, Hold and Bar.
	-- Tag: an effect's piece the band watches the same way, carrying this CollectionService tag: the player's own lead's
	-- hanging square, Haymaker's stamp, its posts, rails and plate (TR7, research's call on the hang, 2026-11-13, (a)). It
	-- fades the card only while the square stands behind it, with no timed fade.
	SeeThrough = {
		Tag = "NL_SeeThrough",
		Economy = 0.25,
		Target = 0.5,
		Bar = 0.85,
		Rate = 10,
		Hold = 0.25,
		Parts = { Lamplighter = { "Lamplighter_Head", "Lamplighter_Lantern" } } :: { [string]: { string } }, -- the hat, the lantern
	},
	-- The elite's and the keeper's HUD (TR5, the director's word of 2026-11-13: "mini boss and boss should have a different
	-- HUD"): judged in motion at phone size before Modulo's frames (UI.BossBar; UI.TargetCard.Elite).
	-- Keeper: "B" at the top middle, the director's pick of 2026-11-14 ("it should be at the top middle"): its title, its
	-- name and its bar in the band's middle, the target card's place, as wide as the room between the lead's card and the
	-- pills (Top.Most at most); "A" its bar wide at the foot, the dock stepped out for the try; "Off" the target card as
	-- before. Its look, the director's words of 2026-11-14: richer and composed, its health purple, and light over the
	-- fight ("it does need to looks very light too else we see nothing"): no plate behind it, a thin framed bar on a faint
	-- glow, its line art Modulo's frames tinted Rim. Elite: the foe card's brass edge and shards (AR45); false the plain
	-- card. Switched live by Tune ("Hud.Boss.Keeper", "B"). The name stamps on as the Challenge's Stamp
	-- lands, From times its size down to its own over Seconds; the rest comes in over Fill with a shine across the bar
	-- (Shine); the whole leaves over Leave from the fall's Gone. Drain: after a hit the pale trail holds Hold seconds, then
	-- drains Rate of the bar a second. Look: transparencies, 0 solid. Sizes in authored pixels. The builder's seeds,
	-- 2026-11-13 and 14.
	Boss = {
		Keeper = "B",
		Elite = true,
		-- Bar: the bar's height, its number inside it: at least the number's line on the smallest phone (Caption at the
		-- scale's floor, 17), and about twice the grey block's 8 (research's verdict, 2026-11-14, fix 2).
		Foot = { Width = 400, Bar = 18, Above = 14 }, -- Above: the bar's foot over the screen's; Width clears the jump button on the smallest phone
		Top = { Most = 400, Bar = 18, Y = 17 }, -- Y: the title's top, the band's top line; the bar's foot at 86 (the lead card's at 113)
		Stamp = { From = 1.6, Seconds = 0.14, Fill = 0.25 }, -- Fill: seconds the title and the bar take to come in after it
		Shine = { Seconds = 0.6 },
		Leave = 0.3,
		Drain = { Hold = 0.45, Rate = 0.5 },
		Health = Color3.fromHex("#9150FF"), -- the keeper's purple, the fill's middle and its glow
		Light = Color3.fromHex("#CDA6FF"), -- the fill's top edge, lit
		Deep = Color3.fromHex("#5A27C9"), -- its foot
		Trail = Color3.fromHex("#F3E9FF"), -- the health just lost, draining
		Rim = Color3.fromHex("#DCCBFF"), -- the tint of the bar's rim, its caps, the title's rules and its crest
		Title = Color3.fromHex("#D9CFEA"), -- "Keeper of ...", a lilac grey over the name
		-- The keeper's name, lit from above like its bar, never white (the director, 2026-11-14: "not white"): its top, its foot.
		Name = { Color3.fromHex("#D7B5FF"), Color3.fromHex("#A066FF") },
		-- Channel: the bar's empty part, the world through it; Rim: the bar's rim and caps; Rule: the title's rules and crest.
		Look = { Channel = 0.45, Rim = 0.15, Glow = 0.82, Rule = 0.3 },
	},
	-- TR10's marker while the elite, or this player's keeper, is down (DownController; research's entry, 2026-11-14), as
	-- Badge (research's pick, 2026-11-23, 16:41). Far, its icon with the time on its foot, nothing round them. Within Near
	-- studs of the avatar, a card of its loot with each drop's chance (Rules.Drops.Card) unfolds from the tile over Unfold
	-- seconds.
	-- It takes its size from the world (research's must-fix 1), as a thing there does: today's size within Full studs of
	-- the camera, Full / distance of it past them. It never shrinks under Least, the icon's side in rendered pixels on the
	-- smallest phone (Modulo's read: both icons still part at 28, TR10), and its words stay at Theme.Text.Minimum there.
	-- Full is the camera's distance when the avatar walks within Near, so the card always unfolds at today's size.
	-- Up: studs over its marker it stands. Reach: studs from the camera it shows, the street's length. Icon (its tile's
	-- side) and Width (the card's), authored pixels. The builder's numbers, tuned live.
	Down = {
		Near = 60,
		Reach = 320,
		Up = { Elite = 9, Keeper = 11 },
		Icon = 48,
		Width = 176,
		Full = 75,
		Least = 28,
		Unfold = 0.18,
	},
	-- TR9's Breaker screen in grey (UI/BreakerScreen), Machine by the director's pick (2026-11-14, night): the chambers
	-- side by side over a strip of what's ready, waiting and in the bag, the chosen shard's odds beside them. Cell: a
	-- chamber's authored height: its shard's picture over its name, its crack, its time and, infused, one line saying so
	-- (Config.Hud.ShardArt, AR12). Flash: a chamber whose shard finishes flashes gold "Ready" this long, seconds ("about 1.5 s",
	-- research's fix (b)), held at full for Hold of them, then fading; Pop, the scale it lands from. Glow: a ready chip's
	-- gold fill breathing between Low and High (its alpha) every Period seconds, there and back (fix (a)).
	Breaker = {
		-- A chamber's height: its name strip, its window on the sky and its plate (TR41, the galaxy's glass), so the whole
		-- body's height with the strip under it.
		Cell = 142,
		Strip = 20, -- a chamber's name strip, solid, "Chamber N" on it
		Fade = 0.3, -- the share of the ready row's width, at its end by the detail panel, over which it fades out (TR41 (a); research, 2026-11-17: 0.1 left the third card reading "Rea")
		-- The galaxy Breaker's sky (TR41; AR12, "The galaxy Breaker's images for the build"; Modulo's breaker_sky.json,
		-- whose places are in the mock's points on a panel of 684 by 306, laid here as shares of ours). From the back: the
		-- night in the panel's shape, one band of mist along the chambers' row tinted as one river (research's read), the
		-- six stars, the falling star in chamber 4's window, then a chamber's glass, its light, its shard, and the plates.
		-- With reduced motion on, it holds still and no star falls.
		Sky = {
			Images = {
				Left = "rbxassetid://85968639200976",
				Right = "rbxassetid://104002526402503",
				Mist = "rbxassetid://119524756969687",
				Star = "rbxassetid://91107060875888",
				Falling = "rbxassetid://121639543913318",
				Light = "rbxassetid://136697115054832",
			},
			Panel = Vector2.new(684, 306), -- the mock's panel: the night's halves and the stars are shares of it
			Left = { At = 0, Wide = 428.651 }, -- the night's two halves, lapping 7.5 points
			Right = { At = 421.116, Wide = 262.884 },
			-- The windows' band down a chamber, shares of its height (the json's glass.nameStrip and glass.plate): the mist's
			-- image lies so that its Top and Foot (shares of the image's own height) meet the band's.
			Band = { Top = 0.1458, Foot = 0.6944 },
			Mist = {
				Image = Vector2.new(684, 142.945), -- one turn of it, in the mock's points
				Top = 0.1367,
				Foot = 0.6894,
				Drift = 2.5, -- points a second, leftward
				Tint = { -- the river, left to right along the row
					{ 0, "#D44FB4" }, { 0.125, "#D14FB7" }, { 0.25, "#B54FD0" }, { 0.375, "#9850E9" }, { 0.5, "#7768F4" },
					{ 0.625, "#5580FF" }, { 0.75, "#41A1EE" }, { 0.875, "#2DC2DD" }, { 1, "#2FCCD4" },
				} :: { { any } },
				Down = { -- the cover down the image, share of its height: cover
					{ 0, 0 }, { 0.1367, 0.347 }, { 0.2058, 0.647 }, { 0.2749, 0.827 }, { 0.344, 0.859 }, { 0.4131, 0.886 },
					{ 0.4822, 0.89 }, { 0.5512, 0.858 }, { 0.6203, 0.792 }, { 0.6894, 0.704 }, { 1, 0 },
				} :: { { number } },
			},
			-- Six stars: the image is Side times a star's size across; its light 0.775 + 0.225 * sin(2 pi (t / Seconds + Start)).
			Stars = {
				Side = 16,
				Each = {
					{ At = Vector2.new(528, 21), Size = 1.5, Tint = "#DCE6FF", Seconds = 4.6, Start = 0 },
					{ At = Vector2.new(398, 90), Size = 1.1, Tint = "#FFE9D0", Seconds = 3.4, Start = 0.3 },
					{ At = Vector2.new(38, 142), Size = 1.0, Tint = "#BFD0FF", Seconds = 5.2, Start = 0.6 },
					{ At = Vector2.new(94, 84), Size = 0.9, Tint = "#F1D9FF", Seconds = 3.9, Start = 0.8 },
					{ At = Vector2.new(250, 46), Size = 0.9, Tint = "#DCE6FF", Seconds = 4.2, Start = 0.45 },
					{ At = Vector2.new(300, 294), Size = 0.9, Tint = "#BFD0FF", Seconds = 5.0, Start = 0.15 },
				},
			},
			-- The falling star, pale, never tinted, in chamber 4's window under its glass: its Head runs From To (shares of the
			-- window's band) in Seconds; its light sin(pi s) ^ 0.6. The first First seconds after the screen opens, then one
			-- every Every, each drawn at random between the two (research, 2026-11-15: seeds, tuned in play). Made to be caught
			-- at the smallest phone (TR41 (a)'s must-fix; AR12, "The falling star, made to be caught"): a bright head in a soft
			-- glow, the tail twice as long, corner to corner of the window in the old speed on the longer path.
			Falling = {
				Chamber = 4, -- its window's chamber
				Points = Vector2.new(56, 48),
				Head = Vector2.new(9, 39),
				From = Vector2.new(1, 0),
				To = Vector2.new(0, 1),
				Seconds = 0.9,
				First = { 3, 6 },
				Every = { 15, 30 },
			},
			-- The soft light behind a working shard: Side times Radius across, on the shard's middle, breathing Swell round
			-- its Cover once in Breath seconds.
			Light = { Tint = "#DCCBFF", Radius = 27, Side = 4, Cover = 0.36, Breath = 2.6, Swell = 0.07 },
			-- A chamber's glass: solid over its strip and plate, covering Window of the sky between them (Locked when it's
			-- locked), going over Under of its height below the strip and Over above the plate.
			Glass = { Colour = "#0A0824", Window = 0.1, Locked = 0.13, Under = 0.04, Over = 0.06 },
		},
		Flash = { Seconds = 1.5, Hold = 0.35, Pop = 1.08 },
		Glow = { Low = 0.18, High = 0.4, Period = 0.9 },
		-- A rarity's heading in the drop rates where its trim is too dim to head a list: Common's metal grey, lifted
		-- (research's fix, 2026-11-15). The others head theirs in their trim's colour.
		Tier = { Common = Color3.fromHex("#C9CED8") } :: { [string]: Color3 },
	},
	-- The Power screen (TR18): Step, the share a +/- press moves, of the whole generation; shares snap to Snap. Its bar is
	-- Modulo's, cut in Eclipse (AR12, "Power's cut images, in Eclipse"; build/handoff/UI/hud/colour/power_images.json;
	-- TR41 (b)), stacked as the json's `bar.stack` says, ember to handle. Its images are its own, not the kit's: a white
	-- one takes its tint, Cut in points at 4 pixels a point, Pad past its piece's box (the Ember drawn at a pixel a point).
	Power = {
		Step = 0.05,
		Snap = 0.01,
		Images = {
			Channel = { Id = "rbxassetid://112778052596196", Pixels = Vector2.new(224, 224), Points = Vector2.new(56, 56), Cut = { 24, 24, 24, 24 }, Pad = 16 },
			Glow = { Id = "rbxassetid://135869228981854", Pixels = Vector2.new(352, 336), Points = Vector2.new(88, 84), Cut = { 40, 40, 40, 40 }, Pad = 32 },
			Light = { Id = "rbxassetid://95479211429609", Pixels = Vector2.new(96, 96), Points = Vector2.new(24, 24), Cut = { 8, 8, 8, 8 }, Pad = 0 },
			Edge = { Id = "rbxassetid://122469296270915", Pixels = Vector2.new(96, 96), Points = Vector2.new(24, 24), Cut = { 8, 8, 8, 8 }, Pad = 0 },
			Handle = { Id = "rbxassetid://90514113048264", Pixels = Vector2.new(100, 224), Points = Vector2.new(25, 56), Pad = 8 },
			ChipBreaker = { Id = "rbxassetid://130456525982318", Pixels = Vector2.new(88, 88), Points = Vector2.new(22, 22), Pad = 5 },
			ChipTraining = { Id = "rbxassetid://114149720582348", Pixels = Vector2.new(88, 88), Points = Vector2.new(22, 22), Pad = 5 },
			-- The Stone Condenser's, six-sided, in its Rose (AR51's finish; images/PowerChipCondenser.png).
			ChipCondenser = { Id = "rbxassetid://109967765766548", Pixels = Vector2.new(88, 88), Points = Vector2.new(22, 22), Pad = 5 },
			Ember = { Id = "rbxassetid://90007328405959", Pixels = Vector2.new(580, 168), Points = Vector2.new(580, 168), Pad = 0 },
			-- The battery's mark on its plate in the head, one of AR12's V2 images (build/handoff/UI/hud/colour/images/Battery.png;
			-- TR41 (e)): drawn in its own gold and dark rim, never tinted. Its drawing spans 0.88 of its side across, centred.
			Battery = { Id = "rbxassetid://124264049509782", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
		} :: { [string]: UIKit.Image },
		-- The battery mark's three cells, in its image's pixels (TR41 (e), research's must-fix: lit by the charge, by
		-- Rules.Hud.BatteryCells). The image draws two lit and an empty slot behind the third, so each cell is laid as a
		-- crop of the image itself. A lit cell: its second cell (Lit), at At plus Every for each cell before it. An empty
		-- one: a tile of the slot's dark over the battery's inside (Inside, left to right, top to foot), from the middle of
		-- one gap between cells to the next, stretched from a small flat patch deep in the slot (Dark), since an image drawn
		-- small blends each pixel with its neighbours, and a crop near the gold brought a seam of it in (TR41 (e)'s stills).
		Cells = {
			At = Vector2.new(25, 46), Every = 25, Size = Vector2.new(19, 36), Lit = Vector2.new(50, 46),
			Inside = { Left = 23, Right = 93, Top = 44, Foot = 85 },
			Dark = { From = Vector2.new(78, 58), Size = Vector2.new(6, 12) },
		},
		-- The mark in the Power pill, before the battery's reading, always (research, TR41 (e); docs/ui.md, the top right):
		-- its side and its gap to the words, in points.
		PillMark = { Side = 17, Gap = 4 },
		Colours = {
			Breaker = Color3.fromHex("#E6ECF7"),
			Training = Color3.fromHex("#4FD1FF"),
			Condenser = Color3.fromHex("#FF8FAE"), -- Rose (AR51, research's pick of 14:29): no other light or word here is near it
			Battery = Color3.fromHex("#FFE266"),
			Ember = Color3.fromHex("#F2A63B"),
			Caution = Color3.fromHex("#FF9A4D"),
			Channel = Color3.fromHex("#080705"),
			Edge = Color3.fromHex("#9A7A22"),
			Faint = Color3.fromHex("#8F7F52"),
			Well = Color3.fromHex("#0E0C09"),
		} :: { [string]: Color3 },
		-- A light's colour across the bar, top to foot: dark at the rims, paled at the middle, the sheen's band. An idle
		-- machine's light wears the Battery's.
		Lights = {
			Breaker = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#989CA3")), ColorSequenceKeypoint.new(0.0625, Color3.fromHex("#9FA3AA")), ColorSequenceKeypoint.new(0.125, Color3.fromHex("#A8ACB4")), ColorSequenceKeypoint.new(0.1875, Color3.fromHex("#B6BAC1")), ColorSequenceKeypoint.new(0.25, Color3.fromHex("#C7CBD1")), ColorSequenceKeypoint.new(0.3125, Color3.fromHex("#D3D6DD")), ColorSequenceKeypoint.new(0.375, Color3.fromHex("#D7DCE3")), ColorSequenceKeypoint.new(0.4375, Color3.fromHex("#DFE3EC")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#EAEFF8")), ColorSequenceKeypoint.new(0.5625, Color3.fromHex("#DDE2EC")), ColorSequenceKeypoint.new(0.625, Color3.fromHex("#D2D6DF")), ColorSequenceKeypoint.new(0.6875, Color3.fromHex("#C6CBD3")), ColorSequenceKeypoint.new(0.75, Color3.fromHex("#BBC0C8")), ColorSequenceKeypoint.new(0.8125, Color3.fromHex("#B1B5BD")), ColorSequenceKeypoint.new(0.875, Color3.fromHex("#A7ABB3")), ColorSequenceKeypoint.new(0.9375, Color3.fromHex("#9FA3AA")), ColorSequenceKeypoint.new(1, Color3.fromHex("#989CA3")) }),
			Training = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#348AA8")), ColorSequenceKeypoint.new(0.0625, Color3.fromHex("#3990B0")), ColorSequenceKeypoint.new(0.125, Color3.fromHex("#409AB9")), ColorSequenceKeypoint.new(0.1875, Color3.fromHex("#50A8C7")), ColorSequenceKeypoint.new(0.25, Color3.fromHex("#69BAD6")), ColorSequenceKeypoint.new(0.3125, Color3.fromHex("#77C6E2")), ColorSequenceKeypoint.new(0.375, Color3.fromHex("#6DC9E9")), ColorSequenceKeypoint.new(0.4375, Color3.fromHex("#65CEF3")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#68D8FF")), ColorSequenceKeypoint.new(0.5625, Color3.fromHex("#60CCF2")), ColorSequenceKeypoint.new(0.625, Color3.fromHex("#59C1E6")), ColorSequenceKeypoint.new(0.6875, Color3.fromHex("#51B6DA")), ColorSequenceKeypoint.new(0.75, Color3.fromHex("#4BACCE")), ColorSequenceKeypoint.new(0.8125, Color3.fromHex("#44A2C3")), ColorSequenceKeypoint.new(0.875, Color3.fromHex("#3E99B9")), ColorSequenceKeypoint.new(0.9375, Color3.fromHex("#3890AF")), ColorSequenceKeypoint.new(1, Color3.fromHex("#348AA8")) }),
			Condenser = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#A85E73")), ColorSequenceKeypoint.new(0.0625, Color3.fromHex("#B06479")), ColorSequenceKeypoint.new(0.125, Color3.fromHex("#B96C82")), ColorSequenceKeypoint.new(0.1875, Color3.fromHex("#C77B90")), ColorSequenceKeypoint.new(0.25, Color3.fromHex("#D691A4")), ColorSequenceKeypoint.new(0.3125, Color3.fromHex("#E29EB1")), ColorSequenceKeypoint.new(0.375, Color3.fromHex("#E99AB0")), ColorSequenceKeypoint.new(0.4375, Color3.fromHex("#F399B2")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FF9FBA")), ColorSequenceKeypoint.new(0.5625, Color3.fromHex("#F295AF")), ColorSequenceKeypoint.new(0.625, Color3.fromHex("#E68CA5")), ColorSequenceKeypoint.new(0.6875, Color3.fromHex("#DA839B")), ColorSequenceKeypoint.new(0.75, Color3.fromHex("#CE7A92")), ColorSequenceKeypoint.new(0.8125, Color3.fromHex("#C37289")), ColorSequenceKeypoint.new(0.875, Color3.fromHex("#B96B80")), ColorSequenceKeypoint.new(0.9375, Color3.fromHex("#AF6479")), ColorSequenceKeypoint.new(1, Color3.fromHex("#A85E73")) }),
			Battery = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#A89543")), ColorSequenceKeypoint.new(0.0625, Color3.fromHex("#B09C48")), ColorSequenceKeypoint.new(0.125, Color3.fromHex("#B9A550")), ColorSequenceKeypoint.new(0.1875, Color3.fromHex("#C7B35F")), ColorSequenceKeypoint.new(0.25, Color3.fromHex("#D6C478")), ColorSequenceKeypoint.new(0.3125, Color3.fromHex("#E2D085")), ColorSequenceKeypoint.new(0.375, Color3.fromHex("#E9D57E")), ColorSequenceKeypoint.new(0.4375, Color3.fromHex("#F3DB78")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFE67C")), ColorSequenceKeypoint.new(0.5625, Color3.fromHex("#F2DA73")), ColorSequenceKeypoint.new(0.625, Color3.fromHex("#E6CE6B")), ColorSequenceKeypoint.new(0.6875, Color3.fromHex("#DAC363")), ColorSequenceKeypoint.new(0.75, Color3.fromHex("#CEB85C")), ColorSequenceKeypoint.new(0.8125, Color3.fromHex("#C3AE55")), ColorSequenceKeypoint.new(0.875, Color3.fromHex("#B9A44E")), ColorSequenceKeypoint.new(0.9375, Color3.fromHex("#AF9C48")), ColorSequenceKeypoint.new(1, Color3.fromHex("#A89543")) }),
		} :: { [string]: ColorSequence },
		Bar = {
			Height = 24,
			Rim = 2, -- the lights run from Rim inside the bar's left to Rim inside its right; a cut at share s at Rim + (width - 2 Rim) s
			Gap = 1, -- left each side of a cut between two lights
			Glow = 0.42,
			Edge = 0.95,
			Ember = 0.16,
			Arrive = { Points = 38.4, From = 1, To = 0.7 }, -- the light's white end, its Transparency over its last Points
			Ticks = { At = { 0.25, 0.5, 0.75 }, Size = Vector2.new(1, 4), Under = 3.5, Alpha = 0.8 },
			Handle = Vector2.new(9, 40),
			Chip = 12,
			-- The well: the kit's ButtonFill tinted Well at Fill and its ButtonEdge tinted Edge at Line, past the bar by Above,
			-- Under and Ends.
			Well = { Above = 13, Under = 15, Ends = 26, Fill = 0.6, Line = 0.4 },
		},
	},
	-- The shard grades' pictures (AR12; Config.UIKit's Shard images): each grade's own from Large authored points up, its
	-- small one under that (a step paler, its rim wider, a dark line round it, so the outline holds at a chip's size).
	-- Modulo drew the large for 50 and up and the small for 40 and under; between them the small one holds the outline.
	--   Chip: the picture's side on a Breaker chip; Cell: its share of a Voidkin bag cell's side
	--   Chamber: its most in a Breaker chamber's window, its words on the plate under it, never over its foot, where
	--            Enriched's and Prismatic's spires grow (research's call, AR12, 2026-11-15, night); Least: the side it gives
	--            way to, in a row where a chamber's infusion takes a line of the plate, before anything overlaps (still the
	--            large picture, at Large)
	ShardArt = { Large = 50, Chip = 26, Cell = 0.78, Chamber = 72, Least = 50 },
	-- Where a shard came from: its festival tag (AR12, "Where a shard came from", research's design and verdict of
	-- 2026-11-15; Modulo's build/handoff/UI/shards/tag/shard_tag.json; Rules.Hud.ShardTag; UI.ShardTag; TR41 (d)). Laid
	-- over a shard's picture, which keeps its place and size, by the side it's shown at (ShardArt):
	--   Tag      from ShardArt.Large up: the ground's tag hung by its thread from the crystal's right shoulder. Its plaque
	--            is Third.Of of the side up to a side of Third.Upto, Quarter.Of from Quarter.From, a straight line between
	--            (a third of the crystal at 50, a quarter at 96); its image is shown plaque / Plaque times its points, its
	--            Tie (in the image's points) on At (in sides from the picture's middle, right and up)
	--   Mark     a smaller picture: the ground's mark on its disc, Side of the side and never under Least points, its
	--            middle at Middle (in sides from the picture's middle: the crystal's foot, on the right)
	--   Band     a Breaker chip (its picture at ShardArt.Chip): no image, a band of the ground's colour Band points high
	--            along the chip's foot, inside its edge
	--   Grounds  each ground's colours and images, by Definitions.Grounds id. The other four grounds' are drawn when their
	--            grounds are built: a shard of a ground with none shows no tag.
	ShardTag = {
		Tag = { Plaque = 24, Tie = Vector2.new(15, 2), At = Vector2.new(0.1366, -0.2084), Third = { Upto = 69.6, Of = 0.2396 }, Quarter = { From = 133.6, Of = 0.1797 } },
		Mark = { Side = 0.2831, Least = 14, Middle = Vector2.new(0.2156, 0.2587) },
		Band = 3.6,
		Grounds = {
			lanternrow = {
				Colour = Color3.fromHex("#35CFEA"),
				Second = Color3.fromHex("#FFF1D8"),
				Tag = { Id = "rbxassetid://132220202941634", Pixels = Vector2.new(192, 288), Points = Vector2.new(24, 36), Pad = 0 },
				Mark = { Id = "rbxassetid://103859402666115", Pixels = Vector2.new(128, 128), Points = Vector2.new(16, 16), Pad = 0 },
			},
			drumcourt = {
				Colour = Color3.fromHex("#DD3A32"),
				Second = Color3.fromHex("#FFE7C6"),
				Tag = { Id = "rbxassetid://111610217960625", Pixels = Vector2.new(192, 288), Points = Vector2.new(24, 36), Pad = 0 },
				Mark = { Id = "rbxassetid://134664108788002", Pixels = Vector2.new(128, 128), Points = Vector2.new(16, 16), Pad = 0 },
			},
		} :: { [string]: { Colour: Color3, Second: Color3, Tag: UIKit.Image, Mark: UIKit.Image } },
	},
	-- TR17's Voidkin screen in grey (UI/VoidkinScreen): one Voidkin at a time, full screen, in the director's layout
	-- (2026-11-15, TR17, "The director's layout"): its own model live
	-- between two columns of gear slots, its two hands and Combat Power at its feet, the chosen page on the right, the
	-- portraits along the foot.
	--   Span     how wide the name's line and the feet's row stand over the stage, at most this share of its height
	--            (no gear slots on the Overview: the director, 2026-11-17)
	--   Figure   Top: authored pixels kept clear over its crown (it stands from there down to the feet's row); Fov: the
	--            stage camera's; Turn: degrees a dragged authored pixel turns it; Back: seconds the next one takes to
	--            slide in, from Slide authored pixels to its side; Draw: seconds a body stands in the stage's wings,
	--            fetched, before it counts as ready to show (its first draw measured 0.25 to 0.53 s on the dev PC,
	--            2026-11-15; no phone measured yet)
	--   Swipe    a flick on the figure that goes to the next or the one before: at least Distance authored pixels across
	--            in at most Time seconds; a touch that moves less than Tap pixels in at most TapTime is a tap
	--   Stage    the stand-in stage: Glow the floor's transparency, Light how far the rarity tints the light
	--   Power    Combat Power's plate under the soles, the MMORPG's showpiece (the director, 2026-11-14, night: "combat
	--            power need to really look like taichi panda dragon hunter in design but like us visually"): Width at
	--            most (between the hands it takes what's left) and Height, authored; Number its digits' authored size
	--            at most and Least at least, as many as fit the plate; Emblem the least width that shows its emblem;
	--            when it rises, the digits Roll up from the old number over that many seconds and the gain rises Gain
	--            authored pixels over Hold seconds as it fades
	--   Finish   its digits in cobalt blue-steel (AR12: the director's "let go platnium but i want it to have color not
	--            be blend", research's read A2 with its foot lifted to 3 to 1 at 20 points; Modulo's combat_power.json,
	--            DESIGN, untried in Studio): the Colours at the Stops top to foot; a Line-point Stroke round them and the
	--            same again Drop points lower; a Glow behind them at GlowAlpha; the caption in Caption. Rising, they go
	--            White of the way toward white and Swell times their size, easing back over the roll
	--   Strip    a portrait's cell, authored
	--   Panel    the page's panel: Share of the room's width, between Least and Most authored
	Voidkin = {
		-- AR29, B, the seam (the director's pick, 2026-11-17, 14:04; Modulo's numbers, 14:15; research's call on seven rows,
		-- 14:17): the rail and the bar, in authored points. Images: Modulo's 13 icons, white on alpha for the game to tint
		-- (build/handoff/UI/voidkin/chrome/images/; their drawing 104 of 128 pixels, centred), and the two cut plates the
		-- kit hasn't (tools/ui/cut_plates.py): the chosen tab, cut top left and foot left, and the bar's channel.
		Chrome = {
			Images = {
				PageOverview = { Id = "rbxassetid://107109302537459", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				PageItems = { Id = "rbxassetid://136552132337644", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				PageKit = { Id = "rbxassetid://82892541132082", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				PageStars = { Id = "rbxassetid://88757612539188", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				PageForge = { Id = "rbxassetid://86087795979068", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				PageJewels = { Id = "rbxassetid://84949390395894", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				PageWarEmblems = { Id = "rbxassetid://104137646367677", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				Back = { Id = "rbxassetid://82378479826308", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				Favourite = { Id = "rbxassetid://130526251247322", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				FavouriteOn = { Id = "rbxassetid://96273820029643", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				Lock = { Id = "rbxassetid://118645338371807", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				LockOn = { Id = "rbxassetid://81840010809176", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				Rename = { Id = "rbxassetid://111948848313920", Pixels = Vector2.new(128, 128), Points = Vector2.new(32, 32), Pad = 0 },
				TabFill = { Id = "rbxassetid://121634951696924", Pixels = Vector2.new(64, 64), Points = Vector2.new(16, 16), Cut = { 9, 9, 2, 4 }, Pad = 0 },
				TabEdge = { Id = "rbxassetid://77599492881527", Pixels = Vector2.new(64, 64), Points = Vector2.new(16, 16), Cut = { 9, 9, 2, 4 }, Pad = 0 },
				TabGlow = { Id = "rbxassetid://95861086972945", Pixels = Vector2.new(104, 104), Points = Vector2.new(26, 26), Cut = { 14, 14, 7, 9 }, Pad = 5 },
				ChannelFill = { Id = "rbxassetid://77652759335656", Pixels = Vector2.new(64, 64), Points = Vector2.new(16, 16), Cut = { 8, 8, 8, 8 }, Pad = 0 },
				ChannelEdge = { Id = "rbxassetid://110614215738990", Pixels = Vector2.new(64, 64), Points = Vector2.new(16, 16), Cut = { 8, 8, 8, 8 }, Pad = 0 },
			} :: { [string]: UIKit.Image },
			-- AR29's page rail sizes, its rail replaced by the Equipment screen's (AR49; Voidkin.Rail): Icon and Drawn size the
			-- band's icons, and Tab is the kit's tab (Kit.Button).
			Rail = {
				Icon = 35, -- an icon's image, square: its drawing is 28 across, 24 points on the smallest phone
				Drawn = 28,
				-- The chosen tab: its row less Inset at top and foot, from the rail's left + Inset to the line. Its fill the
				-- panel's at Fill, washed with Light at Base + Rise t^Power from its left (t 0) to the line (t 1); its edge
				-- Light at Edge, its glow at Glow; where it meets the line, the line Meet.Wide in full Light with its glow.
				-- Its contents, centred: Top, the icon's drawing, Under, then its word at Word, bold, Lines tall a line.
				Tab = {
					Inset = 0.85,
					Fill = 0.97,
					Wash = { Base = 0.08, Rise = 0.52, Power = 3.4 },
					Edge = 0.6,
					Glow = 0.22,
					Meet = { Wide = 2.7, Glow = 7.7, GlowAlpha = 0.6 },
					Top = 3.4,
					Under = 2.6,
					Word = 15,
					Lines = 1.05,
				},
			},
			Bar = {
				-- Back: no plate. Its chevron (the Back icon, half its drawing Chevron) ChevronAt in, its word from WordAt, and
				-- under them a line Tall high, Inset in at each end, Over above the row's foot, its strength Floor +
				-- (1 - Floor) e^-(dx/Spread)^2 from its middle, with a glow.
				Back = { Chevron = 7.3, ChevronAt = 9.4, Word = 17, WordAt = 19.7, Line = { Tall = 0.85, Inset = 3.4, Over = 2.6, Floor = 0.15, Spread = 18.8, Glow = 2.1, GlowAlpha = 0.3 } },
				-- Favourite, lock and rename in one channel: Cell wide each (46 points on the smallest phone), from the band
				-- row's top less Over to its foot plus Under; filled with Channel at Fill, edged (0.85, the plate's own) and split
				-- in the seam's Edge, the splits Inset from the row's top and foot.
				Channel = { Cell = 54, Over = 0.85, Under = 1.7, Fill = 0.72, Split = { Wide = 0.85, Inset = 10.3 } },
				-- A mark: its icon the rail's size, Lift over the channel's middle; on, in Light, with a line Long by Tall,
				-- Over above the channel's foot, and its glow.
				Mark = { Lift = 0.85, On = { Long = 15.4, Tall = 1, Over = 3.1, Glow = 2.6, GlowAlpha = 0.45 } },
			},
		},
		Span = 1.2,
		Figure = { Top = 24, Fov = 30, Turn = 0.6, Back = 0.2, Slide = 48, Draw = 0.8 },
		Swipe = { Distance = 80, Time = 0.35, Tap = 10, TapTime = 0.3 },
		-- Floor: the stage's stone under the fighter, its element only a ring of light round its edge, Rim of the floor across
		-- (Modulo's B, research's pick of 2026-11-23, 02:05; TR50's sweep). The stone shows the sheet's Shows under every
		-- rarity's light: the stage shows a plastic floor at its colour x (Ambient + LightColor x Lit), Lit measured on this
		-- stage (2026-11-23), so the floor wears Shows over that and the rarity's light keeps the fighter alone (research's
		-- must-fix 1: Epic's light turned the stone lavender). The ring is opaque Neon, which a viewport shows at about Gain x
		-- colour^Power in linear light (measured with grey probes): the ring takes the colour that shows its element's, or
		-- Fire's orange shows yellow.
		Stage = {
			Light = 0.45,
			Floor = { Shows = Color3.fromHex("#A9A59B"), Lit = 0.46, Rim = 0.03, Neon = { Gain = 11.3, Power = 1.84 } },
		},
		Power = { Width = 236, Height = 56, Number = 36, Least = 20, Emblem = 170, Roll = 0.6, Gain = 26, Hold = 1.2 },
		Finish = {
			Stops = { 0, 0.2, 0.5, 0.56, 1 },
			Colours = { Color3.fromHex("#FFFFFF"), Color3.fromHex("#C9DBFF"), Color3.fromHex("#5F90EA"), Color3.fromHex("#3566C9"), Color3.fromHex("#315FBE") },
			Stroke = Color3.fromHex("#07080D"),
			Line = 1.2,
			Drop = 1.2,
			Glow = Color3.fromHex("#4A7BF5"),
			GlowAlpha = 0.55,
			Caption = Color3.fromHex("#BCD0F7"),
			White = 0.4,
			Swell = 1.1,
		},
		Strip = 52,
		Panel = { Share = 0.44, Least = 300, Most = 420 },
		-- The page rail (AR49, research's call of 2026-11-20, 00:12): the Equipment screen's (UI.Kit.Rail), its four pages
		-- down a column Width wide at the room's left, Margin in from its top and foot. Its words are the rail's; its discs
		-- take a share of the rail's radii, the most that lets four stand whole in the room (the smallest phone's 248 points
		-- hold them at about 0.65), and its pitch grows with the room up to Pitch.
		Rail = { Pages = { "Overview", "Kit", "Bag", "Stars" }, Width = 68, Margin = 4, Pitch = 82, Least = 0.5 },
		-- The Stars page's pips (AR43's take 2, voidkin_b.json, stars.pips): a Side-point square turned 45 degrees, Half
		-- its height's half, Pitch apart; a won one its trim lit by Lit towards white, its Glint hairline at WonHair, its
		-- glow Glow points out at GlowAlpha; one to win, the Facet's hairline at EmptyHair.
		Pips = { Side = 14, Half = 10, Pitch = 24, Lit = 0.35, WonHair = 0.2, EmptyHair = 0.45, Glow = 6, GlowAlpha = 0.5 },
	},
	-- The Items page, AR18's C, "the case" (TR28; research's pick at 14:27, its fixes at 15:12, fix 4 at 16:52): a belt of
	-- the fourteen slots across the top, the bag's six kinds under it, the grid five across, and the Voidkin's half beside
	-- it, where a chosen item's card slides in. Authored points, as Modulo's sheet draws them; a slot is a touch at the
	-- scale drawn, never under (fix 4), so a narrow screen's belt shows the chosen item's group.
	Bag = {
		-- The Items page in A, "the ledger" (the director's pick of AR18, about 20:52, 2026-11-16; TR28, "The rebuild in A"):
		-- the grid beside the Voidkin between its two columns of slots, the card sliding over the Voidkin (docs/ui.md, the bag).
		Cell = 64, -- a grid cell's side at most (docs/ui.md: about 64); five across or more, never under a touch
		CellGap = 6,
		Veil = 32, -- the kinds strip's fade where it hides a chip: past a chip's half pad, so a whole chip at the edge fades too
		Divider = { Left = 4, Alpha = 0.65 }, -- the doll's side and the bag's split: Left points left of the strip, the Facet at Alpha (AR43's take 2)
		Peek = 0.5, -- a row scrolled to show the chosen chip keeps this share of its neighbour in view: it ends on a cut chip (AR30, research's must-fix)
		Ring = 16, -- the cells' holder's margins, 8 each side and over and under: a chosen cell's ring's light (UI.VoidkinScreen.Seam.Reach at 64), the scroll bar inside the right's
		Empty = { Share = 32 / 44, Tint = Color3.fromHex("#6F6790"), Alpha = 0.45 }, -- an empty slot's mark (AR22's json): its share of the well, its tint (the seam's Faint) at 0.55
		Columns = 5, -- at least; a wider room adds a column a cell wide
		Inset = 4, -- the room's edge round the grid
		Under = 4, -- between the strip, the grid and the count
		-- The doll: A's slots 44 at a pitch of 49, its figure's room 140 between its two columns. On a taller room the slots
		-- grow to Most and the figure's room with them (Grow slots wide); where six a touch tall don't stand (the smallest phone),
		-- each slot keeps its whole touch and the six are pitched to the room, a tap over its neighbour's by under a pixel.
		Doll = { Slot = 44, Gap = 5, Most = 64, Seam = 4, Figure = 140, Grow = 2.6, Level = 16 },
		Gear = 48, -- the slot AR6's sizes are given for (build/handoff/UI/gear/gear_icons.json): a cell's layers scale from it
		Bar = 3, -- a cell's rarity bar along its foot
		Row = 18, -- a line of the card
		Slide = 0.16, -- seconds: the card over the Voidkin, and back
		Mark = 14, -- a cell's corner seat: the up arrow, the worn tick
		Card = { Corner = 4, Pad = 10, Cell = 56, Close = 14, Title = 16 }, -- the close's X drawn this size in a touch
		Salvage = { "", "Common", "Uncommon", "Rare", "Epic" }, -- the salvage control's steps, in order: "" is off
		-- The page's colours are the seam's, as the Overview's (UI.VoidkinScreen.Seam); a rarity keeps its own.
		-- A rarity's word. 2026-11-25, the builder: Common, Rare and Epic lifted toward white (from #9AA0AC, #6FB6FF and
		-- #D29CFF), so each reads 4.6:1 on the card's top (UIKit's SeamDeep, #4C3E92), where the Epic weapon's read 4.35.
		Rarity = {
			Common = Color3.fromHex("#B9BDC6"),
			Uncommon = Color3.fromHex("#7CF0A0"),
			Rare = Color3.fromHex("#86C2FF"),
			Epic = Color3.fromHex("#D8AAFF"),
			Legendary = Color3.fromHex("#FFD777"),
		} :: { [string]: Color3 },
		Rim = { -- a rarity's rim, tint and light on a cell (AR6's `rim`)
			Common = Color3.fromHex("#8A909C"),
			Uncommon = Color3.fromHex("#7CF0A0"),
			Rare = Color3.fromHex("#6FB6FF"),
			Epic = Color3.fromHex("#D29CFF"),
			Legendary = Color3.fromHex("#FFD777"),
		} :: { [string]: Color3 },
	},
	-- The Voidkin screen in the seam's skin (TR28; the director's word of 2026-11-17, 02:40; Modulo's sheet notes, AR18):
	-- violet-black grounds, edges of pale light, and what's chosen drawn in it. Authored points; every number a seed.
	Seam = {
		WellFoot = Color3.fromHex("#0C0A13"), -- a well falls to this from the palette's Well
		Stage = { Color3.fromHex("#140F25"), Color3.fromHex("#0A0812") }, -- the stage's dark, top to foot, under its rarity's light
		Shaft = { Half = 26, Alpha = 0.13 }, -- the light behind the figure, cut at the stage: its half width (to 1/e), its strength
		-- A lit edge: a line of Light over its glow's bands (each Wide across, centred on the line), strongest at its middle
		-- and Floor of that at its ends; Spread is how far the strength holds, a share of the edge's length (to 1/e).
		Edge = { Line = 1, Glow = { { Wide = 3, Alpha = 0.25 }, { Wide = 9, Alpha = 0.1 } } },
		Edges = {
			Room = { Spread = 0.4, Floor = 0.12, Strength = 1 }, -- the room's top
			Rule = { Spread = 0.36, Floor = 0.12, Strength = 1 }, -- the hairline between the doll and the grid
			Card = { Spread = 0.32, Floor = 0.15, Strength = 1 }, -- the card's sliding edge
			Power = { Spread = 0.33, Floor = 0, Strength = 1 }, -- Combat Power's plate, along its top
		},
		-- The chosen ring (research's fix, 08:01; Modulo's 08:13): a dark moat From to To out, then Wide of Light from Out, its
		-- glow's bands outward; at a 48-point cell, scaled with the cell.
		-- Corner: its rounding round a cell's cut corner.
		Ring = { Moat = { From = 0.8, To = 3.4, Alpha = 0.94 }, Out = 3, Wide = 2.6, Glow = { { Wide = 3, Alpha = 0.3 }, { Wide = 7, Alpha = 0.12 } }, Cell = 48, Corner = 4 },
		Room = { Corner = 6 }, -- the Items room's panel
		Shade = { Wide = 8, Alpha = 0.45 }, -- the card's shadow on the grid, left of its sliding edge
	},
	-- The Void Shop's screen (AR38, UI.ShopScreen; Modulo's grey sheet on D6, research's second look of 2026-11-19), authored:
	-- a line's head and each text row; a picture's well, its rim and the picture's share of it; the band's clock, a light a
	-- minute; the seconds the Buy of a piece for a class the player hasn't got waits for its second press; the countdown
	-- chip under the HUD's pills in a stock's last Config.Shop.Warn seconds. Most: the two lines' block at the most, so a
	-- wide screen keeps each line's words near its Buy.
	Shop = {
		Most = Vector2.new(860, 376),
		Head = 24,
		Row = 20,
		-- A line's hero (research's 15:56): its picture at Most at the most, over its words; under Least, at the left of
		-- them, Share of its panel's width at the most. Its light: Light times its side (the bag's slot light); a shard's at
		-- Shard. Break: a margin on a wrapped line's measure, for where its words break.
		Hero = { Most = 150, Least = 96, Gap = 6, Share = 0.4, Light = 1.5, Shard = 0.9, Break = 1.05 },
		Clock = { Wide = 7, Gap = 3, Tall = 24, Track = 0.72, Words = 82 },
		Armed = 3,
		CoinOff = 0.5, -- an off Buy's coin, dimmed with its price
		Chip = { Wide = 196, Tall = 30 }, -- as wide as its words once shown
	},
	-- The return card (TR53; AR55's look, build/handoff/UI/return/return.json, in its points): what the base did while
	-- the player was away, on the System slab at the HUD's right, Right in from its side and Foot over its bottom, grown
	-- up from its foot: Head, then a line a change at Pitch (Five's with five lines), then the press. A line: its rule,
	-- its well Seat from the line's top at (Seat.X, Seat.Y) and pitch - Seat.In across, lit in its machine's Colours, its
	-- picture inside at (pitch - Picture.In) x its Grow (a Voidkin's face pitch - Face, the well inset 2), the gain at
	-- Gain, the word Word in from the slab's right.
	-- The block's motion: Wait after the join's black lifts, Rise points up and in over Seconds, each line's count After
	-- apart.
	Return = {
		Wide = 188, Right = 8, Foot = 6, Base = 86,
		Pitch = 26, Five = 21,
		Head = { X = 10, Y = 7, Size = 14 },
		Top = 26,
		Rule = { Inset = 8, Alpha = 0.78 },
		Seat = { X = 9, Y = 2, In = 4, Of = 22 }, -- the well's images drawn at (pitch - In) / Of
		Picture = { In = 9, Face = 8, Grow = { Battery = 1, Full = 1, Stones = 1.15, Jewels = 1.15, Training = 1, Worker = 1, Workers = 1, Shards = 1.2 } },
		Colours = {
			Battery = Color3.fromHex("#FFE266"),
			Full = Color3.fromHex("#FFE266"),
			Stones = Color3.fromHex("#FF8FAE"),
			Training = Color3.fromHex("#4FD1FF"),
			-- a bay's worker: the electricity's yellow it makes, the battery's (the builder's call, 2026-11-25)
			Worker = Color3.fromHex("#FFE266"),
			Workers = Color3.fromHex("#FFE266"),
			Shards = Color3.fromHex("#E6ECF7"),
		},
		Gain = { Gap = 7, Size = 17 },
		Word = { Right = 11, Size = 14 },
		Press = { Inset = 8, Over = 58, Tall = 52, Size = 17 }, -- Tall: Theme.Size.Tap, 44 px at the smallest phone's scale
		Wait = 0.6, Rise = 16, Seconds = 0.3, After = 0.08,
		-- AR55's cut (build/handoff/UI/return/images/), under the group (2026-11-24): a line's well and its light, white
		-- for its machine's colour, laid at (Seat.X, Seat.Y), Pad its origin; the Ready tab's glow, centred, its Pad the
		-- middle. The lights take only Colours' tints (the content check's condition).
		Images = {
			ReturnSeat = { Id = "rbxassetid://131404796096136", Pixels = Vector2.new(120, 120), Points = Vector2.new(30, 30), Pad = 4 },
			ReturnSeatLight = { Id = "rbxassetid://130816354357927", Pixels = Vector2.new(120, 120), Points = Vector2.new(30, 30), Pad = 4 },
			ReturnGlow = { Id = "rbxassetid://106910986651502", Pixels = Vector2.new(144, 144), Points = Vector2.new(36, 36), Pad = 18 },
		} :: { [string]: UIKit.Image },
		-- The base's shard during a run (AR55, return.json "run"; TR53's Festival half), in the run's line's points from its
		-- glass's top left: a tab of the line's glass, Tab's box, the dare's tab's twin 6 to its right, as wide as
		-- Room's pads and its words, never under Least; the shard's small picture at Picture (its middle and height), the
		-- time left Words.Right in from its right, its capitals' top at Words.Y. It rides the open dare's foot, Line under
		-- the dare's Foot. Broken: Ready in bold over ReturnGlow, until the player is home. The notice opens right from
		-- the tab once (Notice's box, its picture and two rows), held Held seconds, after the dare's close.
		Run = {
			Tab = { 40, 30, 72, 40 }, Least = 72, Room = 44, Corner = { 4, 6 }, Line = 44,
			Picture = { X = 54, Y = 57, Tall = 19.2 },
			Words = { Right = 8, Y = 51.12, Size = 14, Colour = Color3.fromHex("#C6BDE4"), Ready = Color3.fromHex("#F1ECFF") },
			Glow = Color3.fromHex("#E6ECF7"),
			Notice = {
				Box = { 40, 30, 183, 58 },
				Picture = { X = 51, Y = 64, Tall = 24 },
				Rows = { { X = 62, Y = 48 }, { X = 62, Y = 66 } },
				Held = 4, Open = 0.2, Close = 0.18,
				Words = { "Your shard broke.", "Its Voidkin is at your base." },
			},
			Ride = 0.18, Every = 0.25,
		},
	},
}
