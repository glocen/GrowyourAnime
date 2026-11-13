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
		-- A screen comes in from From of its size, see-through, eased out over Enter; it leaves to To, eased in, over Exit:
		-- about 0.8 of its entrance (rule 4).
		Screen = { Enter = 0.2, Exit = 0.16, From = 0.94, To = 0.97 },
		-- A toast slides in from the screen's right edge over Enter, eased out, and leaves that way over Exit, eased in.
		Toast = { Enter = 0.2, Exit = 0.16 },
	},
	-- A reward pops at its rung (rule 4): it swells to 1 + Swell × (rung − 1) of its size, at its peak at Peak of Seconds
	-- (eased out), and settles by Seconds (eased in and out). A Credits or Electricity win also sends a "+N" up off its pill,
	-- Rise authored pixels over the first half of Gain seconds, fading over the last third after its last win; wins within
	-- its life count up as one, over Count seconds. Electricity pops only on a jump of Jump of the battery's capacity or
	-- more in one read (a return from away), never the bays' flow. Experience: a glint over the thread's light, Glow opaque
	-- at its peak, brightest at its new end; a level: its number swells and goes Glow of the way to white.
	Pop = {
		Seconds = 0.35,
		Peak = 0.25,
		Swell = 0.06,
		Glow = 0.6,
		Rungs = { Xp = 2, Credits = 3, Electricity = 3, Level = 5 } :: { [string]: number },
		Gain = 0.9,
		Rise = 12,
		Jump = 0.05,
		Count = 0.15,
	},
	-- The type edge's arrow on the target's card (docs/ui.md): up when the lead's type beats the target's.
	Arrow = { Up = UIKit.Good, Down = Color3.fromHex("#A6ADBA") },
	-- The signature's ring (docs/ui.md: right edge, low; it fills over the cooldown and flashes when it fires). The builder's
	-- seed for its blockout, 2026-11-12.
	Ring = {
		Size = 46, -- across, authored
		Weight = 4, -- the ring's width
		Flash = 0.35, -- seconds of the flash when it fires
		Ready = 0.6, -- seconds the ring's glow swells when it's ready again
		-- Only in a fight (TR3's verdict, fix 5): seconds it takes to fade in as the lead takes a target, how long it stays
		-- after the lead has none, and seconds to fade out. The builder's seeds.
		FadeIn = 0.2,
		Linger = 1,
		FadeOut = 0.35,
	},
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
}
