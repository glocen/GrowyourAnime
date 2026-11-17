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
}

local DARK = Color3.fromHex("#15120E") -- a warm near-black: an outline that reads over the dusk street's pink end and its dark side

return {
	Numbers = {
		-- Roblox's own face, with a stroke (research's call, 2026-11-12): Builder Sans, which has a true italic at ExtraBold.
		Face = "rbxasset://fonts/families/BuilderSans.json",
		Digit = 0.56, -- a digit's width in its text size, Builder Sans ExtraBold: the unit of Gap
		Styles = {
			-- A hit dealt: pale ivory, upright.
			Dealt = { Colour = UIKit.Numbers.Plain, Size = 1, Gap = 0.3, Outline = DARK, Weight = 1.6, Italic = false },
			-- An element's second number: the same, in its element's colour, a beat behind.
			Element = { Size = 1, Gap = 0.3, Outline = DARK, Weight = 1.6, Italic = false },
			-- Damage the player's lead receives: the same face in muted red, a size larger (the builder's seed, 2026-11-12).
			Received = { Colour = Color3.fromHex("#E27A6A"), Size = 1.2, Gap = 0.3, Outline = DARK, Weight = 1.6, Italic = false },
			-- Healing: as damage received, in green.
			Heal = { Colour = UIKit.Numbers.Heal, Size = 1.2, Gap = 0.3, Outline = DARK, Weight = 1.6, Italic = false },
			-- A dodge, a block, an absorb: a short grey word on a pointer.
			Word = { Colour = UIKit.Numbers.Miss, Size = 0.72, Gap = 0.12, Outline = DARK, Weight = 1.4, Italic = false },
		} :: { [string]: Style },
		Element = { Delay = 0.1 }, -- seconds behind the hit's own number: "a beat behind"
		-- Where a new number tries to go, in its own widths and heights, first to last, clear of the numbers already up
		-- (Rules.Hud.Place): where it rose, then above, then up to either side.
		Slots = { { 0, 0 }, { 0, -1 }, { -0.75, -0.5 }, { 0.75, -0.5 }, { 0, -2 } },
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
			Gap = 0.4, -- about 0.4 of a digit between digits
			Top = Color3.fromHex("#FFF4D6"), -- cream at the head
			Foot = Color3.fromHex("#F2B43C"), -- to gold at the foot
			Outline = Color3.fromHex("#4E2C16"), -- a medium warm brown
			Weight = 1.2, -- one point at a 28 point number, at this size
			Italic = true, -- the slant is the face's italic, on or off: about 10 degrees, never another angle
			-- The stroke (CritSweep, round 2): behind the number and under its outline, its height the digits' own, its left
			-- edge a third of a digit before the first digit, its width 0.6 of the number's and never under three heights.
			-- Tint and opacity: the content check's limits (AR3 section 3, round 2, conditions 1 and 2): #CC661F is the red
			-- and dark limit, yellower or lighter is free, green at least half of red; Transparency 0.4 or more solid.
			Sweep = {
				Tint = Color3.fromHex("#CC661F"),
				Transparency = 0.3,
				Height = 1,
				Left = 1 / 3,
				Width = 0.6,
				Least = 3,
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
	-- The next step's marker (TR24's fix 1; UI.Guide): a chevron Lift studs over each target, bobbing Bob studs Rate times a
	-- second, Size authored points wide; off the frame, one arrow at its edge, Margin authored points in from the sides,
	-- Top from the top and Bottom from the foot (clear of the cards and the dock). Within Near studs of the avatar it steps
	-- back for the target's own prompt. The keeper's gate is pointed at within Reach studs of it. The builder's seeds.
	Guide = { Lift = 1.5, Bob = 0.35, Rate = 0.9, Size = 36, Margin = 56, Top = 84, Bottom = 120, Near = 12, Reach = 800,
		-- The edge's arrow (TR24's fix 2: it read as a small lilac stroke on the sky): an arrow, shaft and head, on a round
		-- dark backing Size points across, the backing in the chevrons' ink at Backing, rimmed in the guide's colour at Rim;
		-- Clear points between its foot and the next step's chip.
		Edge = { Size = 60, Backing = 0.15, Rim = 0.3, Clear = 6 } },
	-- The dock of three icons (AR12; UI.Dock; its shape is UIKit.Dock, Modulo's): pressed, a tile's mark sinks Sink points
	-- along the tile's lean (Modulo's 1.6); a tile that can't be used draws its tile and mark at Dim of themselves; a touch
	-- held LongPress seconds shows the tile's word Rise points over its tap, and lifting it then doesn't press.
	Dock = {
		Sink = 1.6,
		Dim = 0.45,
		LongPress = 0.4,
		Rise = 6,
		-- TR19's seeds, UNVERIFIED: a quiet tile at Quiet of itself; a cooldown's veil in ink at Veil; a refused tap's
		-- shake, Shake points either way over Shook seconds, three times, dying away.
		Quiet = 0.8,
		Veil = 0.5,
		-- A charge (research's verdict on TR19, corrected 2026-11-15): the tile goes to Ink at the tap, and the fill rises
		-- over it in Colour at Alpha, its rising edge a band Edge of the tile's height in Bright at full. White is a stand-in
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
		Cell = 138,
		Flash = { Seconds = 1.5, Hold = 0.35, Pop = 1.08 },
		Glow = { Low = 0.18, High = 0.4, Period = 0.9 },
		-- A rarity's heading in the drop rates where its trim is too dim to head a list: Common's metal grey, lifted
		-- (research's fix, 2026-11-15). The others head theirs in their trim's colour.
		Tier = { Common = Color3.fromHex("#C9CED8") } :: { [string]: Color3 },
	},
	-- The Power screen (TR18, grey): Step, the share a +/- press moves, of the whole generation; shares snap to Snap.
	Power = { Step = 0.05, Snap = 0.01 },
	-- The shard grades' pictures (AR12; Config.UIKit's Shard images): each grade's own from Large authored points up, its
	-- small one under that (a step paler, its rim wider, a dark line round it, so the outline holds at a chip's size).
	-- Modulo drew the large for 50 and up and the small for 40 and under; between them the small one holds the outline.
	--   Chip: the picture's side on a Breaker chip; Cell: its share of a Voidkin bag cell's side
	--   Chamber: its side at the top of a Breaker chamber, its words under it, never over its foot, where Enriched's and
	--            Prismatic's spires grow (research's call, AR12, 2026-11-15, night); Least: the side it gives way to
	--            first, in a row where a chamber's infusion takes a line, before anything overlaps
	ShardArt = { Large = 50, Chip = 26, Cell = 0.78, Chamber = 72, Least = 60 },
	-- TR17's Voidkin screen in grey (UI/VoidkinScreen): one Voidkin at a time, full screen, in the director's layout
	-- (2026-11-15, TR17, "The director's layout"): a thin rail of round buttons down the far left, its own model live
	-- between two columns of gear slots, its two hands and Combat Power at its feet, the chosen page on the right, the
	-- portraits along the foot.
	--   Rail     the menu: Width its column's, authored (each button's tap area is that wide and Theme.Size.Tap high or
	--            more); Dot and Chosen the drawn circles' widths, at rest and selected; Line the line's thickness;
	--            Spread the most authored pixels between two buttons; Run seconds the light takes to run along the
	--            line to a newly chosen one
	--   Slots    the twelve shared, six a column: Size a slot's side, authored, or as large as six fit Gap apart; the
	--            two columns stand at most Span of the stage's height apart; Hand the side of the two hands at the
	--            feet, either side of Combat Power (Modulo's mock of the layout, AR12: 40 and 46)
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
		Rail = { Width = 68, Dot = 26, Chosen = 42, Line = 2, Spread = 20, Run = 0.25 },
		Slots = { Size = 40, Gap = 6, Span = 1.2, Hand = 46 },
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
		Veil = 24, -- the kinds strip's fade where it hides a chip
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
		Pill = 34, -- a chip's pill, drawn in the middle of its tap's height
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
		Lit = { Glow = { { Wide = 2, Alpha = 0.22 }, { Wide = 5, Alpha = 0.1 } }, Button = 0.5 }, -- a plate of light's glow round it (the lit chip), and a button's (Equip's) in the kit's ring glow
		Room = { Corner = 6 }, -- the Items room's panel
		Shade = { Wide = 8, Alpha = 0.45 }, -- the card's shadow on the grid, left of its sliding edge
	},
}
