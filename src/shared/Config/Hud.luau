--!strict
-- Hud (shared config): the HUD's numbers that are tuned by playing (docs/ui.md, "The HUD, in the world"; TR3). Live by
-- NL_Debug:Invoke("Tune", "Hud.Numbers.Critical.Weight", 1.5), or a Color3 for a colour. The kit's own colours and images
-- are Config.UIKit (written from Modulo's handoff); how a number moves is Config.Combat.Numbers. Sizes are authored
-- pixels at the phone's size (UI.Theme.Author); a number's style Size is a share of Combat.Numbers.Size.

local UIKit = require(script.Parent.UIKit)

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

return {
	Numbers = {
		-- Roblox's own face, with a stroke (research's call, 2026-11-12): Builder Sans, which has a true italic at ExtraBold.
		Face = "rbxasset://fonts/families/BuilderSans.json",
		Digit = 0.56, -- a digit's width in its text size, Builder Sans ExtraBold: the unit of Gap
		-- The plain numbers, dealt, an element's, received and healing: AR44's take B, research's pick at 12:11 (the
		-- director, by 11:16: "The damages/healing text need a small rework"; the stroke "way to thick"): Oswald Medium,
		-- calm and tall, a thin outline of 0.8 and a gap of 0.45 of its own digit (Oswald's 0 is 0.36 of its size, measured
		-- in Studio), on the soft shadow. The critical and the grey word keep Builder Sans.
		Styles = {
			-- A hit dealt: pale ivory, upright.
			Dealt = { Colour = UIKit.Numbers.Plain, Size = 1, Gap = 0.45, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- An element's second number: the same, in its element's colour, a beat behind.
			Element = { Size = 1, Gap = 0.45, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- Damage the player's lead receives: the same face in muted red, a size larger (the builder's seed, 2026-11-12).
			Received = { Colour = Color3.fromHex("#E27A6A"), Size = 1.2, Gap = 0.45, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
			-- Healing: as damage received, in green.
			Heal = { Colour = UIKit.Numbers.Heal, Size = 1.2, Gap = 0.45, Outline = DARK, Weight = 0.8, Italic = false, Face = OSWALD, Font = "Medium", Digit = 0.36, Shadow = true },
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
			-- Gold drifting to an olive khaki head to foot, with a darker band two thirds down: the reference's critical
			-- measured row by row (AR44, "The critical's colours, measured", research, 12:48; the director, by 12:47: "make
			-- it as accurate as possible and allowed"). Top and Foot are its ends.
			Top = Color3.fromHex("#E7C66A"),
			Foot = Color3.fromHex("#CFC27A"),
			Ramp = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#E7C66A")),
				ColorSequenceKeypoint.new(0.12, Color3.fromHex("#EFCA61")),
				ColorSequenceKeypoint.new(0.3, Color3.fromHex("#ECD072")),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#EBD88C")),
				ColorSequenceKeypoint.new(0.57, Color3.fromHex("#EAD692")),
				ColorSequenceKeypoint.new(0.63, Color3.fromHex("#B49E60")),
				ColorSequenceKeypoint.new(0.7, Color3.fromHex("#C4B06F")),
				ColorSequenceKeypoint.new(0.82, Color3.fromHex("#CFC27C")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#CFC27A")),
			}),
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
			Sweep = {
				Tint = Color3.fromHex("#CC661F"),
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
	-- The type edge's arrow on the target's card (docs/ui.md): up when the lead's type beats the target's.
	Arrow = { Up = UIKit.Good, Down = Color3.fromHex("#A6ADBA") },
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
	Plates = { Gap = 6 },
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
	Guide = { Lift = 1.5, Bob = 0.35, Rate = 0.9, Size = 36, Margin = 56, Top = 84, Bottom = 120, Near = 12, Reach = 800,
		-- The edge's arrow (TR24's fix 2: it read as a small lilac stroke on the sky): an arrow, shaft and head, on a round
		-- dark backing Size points across, the backing in the chevrons' ink at Backing, rimmed in the guide's colour at Rim;
		-- Clear points between its foot and the next step's chip.
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
			L = { Rest = 1, Calling = 1.45, Pressed = 1.3, Open = 0.75, Quiet = 0.45, Dim = 0, Charge = 0 },
			DimFoot = 0.7,
			Glass = { Wing = Vector2.new(56.8, 48), Mid = Vector2.new(66.8, 58) },
			Cells = {
				{ Name = "Base", Kind = "Wing", Glass = Vector2.new(2, 12), Icon = Vector2.new(30.4, 33.5), Side = 39.4, Pip = Vector2.new(57.8, 13), Tap = { 0, 10, 60.8, 52 } },
				{ Name = "Inventory", Kind = "Mid", Glass = Vector2.new(62.8, 2), Icon = Vector2.new(96.2, 28.5), Side = 49.2, Pip = Vector2.new(128.6, 3), Tap = { 60.8, 0, 70.8, 62 } },
				-- Its word (a long press) is Word: the director, 2026-11-19, "the map button that should be renamed to play or
				-- something else and open FOB" (TR45). Its name stays the cell's, for its images and light.
				{ Name = "Map", Word = "Play", Kind = "Wing", Glass = Vector2.new(133.6, 12), Icon = Vector2.new(162, 33.5), Side = 39.4, Pip = Vector2.new(189.4, 13), Tap = { 131.6, 10, 60.8, 52 } },
			},
			Pip = { Glow = 54.2, GlowT = 0.2, Rings = { 24.6, 18.7, 10.8 } },
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
		-- The lead's card and the target's draw their lights in their colours (tools/blender/lead_card_art.py, the Ember pick
		-- of 2026-11-13); Xp stays experience's one colour for the level-up's ring and word. The target's rims and stud: a
		-- neutral grey, Common's metal light, since a Shade has no rarity (the builder's seed).
		TargetTrim = Color3.fromHex("#666C78"),
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
	-- glow, its line art Modulo's frames tinted Rim. Elite: C, the target card in Modulo's frames, its blade and light
	-- taller, a heavier frame tinted EliteFrame, a tab of its own with a crest notch and the word Elite; false the plain card. Switched live by Tune ("Hud.Boss.Keeper", "B"). The name stamps on as the Challenge's Stamp
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
		EliteFrame = Color3.fromHex("#C9D2E4"), -- the elite's heavier frame: Graphite's glint, as Modulo's sheet shows it
	},
	-- TR10's marker while the elite, or this player's keeper, is down (DownController; research's entry, 2026-11-14), in
	-- grey: its icon (a stand-in until Modulo's), the time left, and a small card of its loot with each drop's chance
	-- (Rules.Drops.Card). Layout: "Stack" (the icon over its name and the time, the card under), "Row" (the icon beside
	-- its name and the time, the card under) or "Badge" (the icon with the time on it, the card only within Near studs of
	-- it). Compare shows the three side by side over the elite's square, for one capture. Up: studs over its marker it
	-- stands. Reach: studs from the camera it shows, the street's length. Icon and Width, authored pixels. The builder's
	-- numbers, tuned live.
	Down = {
		Layout = "Stack",
		Compare = false,
		Near = 60,
		Reach = 320,
		Up = { Elite = 9, Keeper = 11 },
		Icon = 40,
		Width = 176,
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
	-- (2026-11-15, TR17, "The director's layout"): a thin rail of round buttons down the far left, its own model live
	-- between two columns of gear slots, its two hands and Combat Power at its feet, the chosen page on the right, the
	-- portraits along the foot.
	--   Rail     the menu: Width its column's, authored (each button's tap area is that wide and Theme.Size.Tap high or
	--            more); Dot and Chosen the drawn circles' widths, at rest and selected; Line the line's thickness;
	--            Spread the most authored pixels between two buttons; Run seconds the light takes to run along the
	--            line to a newly chosen one
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
		Rail = { Width = 68 }, -- the rail's width; its look is Chrome's (AR29, B)
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
			Rail = {
				-- A row, and the least it closes up to where every page must be in sight: 30.6 points on the smallest phone,
				-- whose room is 248, so its seven stand whole with War Emblems' two lines chosen (research's call, 2026-11-17,
				-- 20:06): Rules.Hud.RailRows.
				Row = 52,
				Least = 36,
				Icon = 35, -- an icon's image, square: its drawing is 28 across, 24 points on the smallest phone
				Drawn = 28,
				Aside = 3.4, -- an icon's middle, left of the rail's middle
				-- An idle icon's tint: research's seed, the seam's soft text (about 9:1), tuned in play so the chosen page is
				-- the brightest thing on the rail, never under 4.5:1 on the panel.
				Idle = UIKit.Palettes.Seam.Soft :: Color3,
				-- The line down the rail's right edge: its middle In from it, its strength Floor + (1 - Floor) e^-(dy/Spread)^2
				-- from the chosen row's middle, with a glow Glow wide each side at GlowAlpha of that.
				Line = { Wide = 1, In = 0.85, Floor = 0.16, Spread = 60, Glow = 2.6, GlowAlpha = 0.28 },
				Tick = { Long = 5, Tall = 1, Alpha = 0.5 }, -- at each idle row's middle, running left from the line
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
		Stage = { Glow = 0.35, Light = 0.45 },
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
		Rarity = { -- a rarity's word
			Common = Color3.fromHex("#9AA0AC"),
			Uncommon = Color3.fromHex("#7CF0A0"),
			Rare = Color3.fromHex("#6FB6FF"),
			Epic = Color3.fromHex("#D29CFF"),
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
}
