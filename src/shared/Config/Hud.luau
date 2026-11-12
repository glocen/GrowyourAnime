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
		-- A critical (the director's word to stay close to the reference; research's table, AR3 section 3, round 2): gold,
		-- heavy, slanted, larger, widely spaced, on the swept stroke. Research tunes these live at TR3's blockout.
		Critical = {
			Size = 1.35,
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
	},
	Fallen = { Dim = 0.55 }, -- a fallen lead's portrait: how far it dims (never a red wash)
	-- The cards' colours, live for the blockout's fix round (the director's notes, 2026-11-13, in TR3; research asked for
	-- them live): health's light on the lead's card and the target's, the lead's experience thread, and the lead card's
	-- trim (its edge). Seeded as the take showed them: health in the kit's light (AR3's in-use rules), the trim the
	-- Graphite edge.
	Card = {
		Health = UIKit.Light,
		TargetHealth = UIKit.Light,
		Xp = Color3.fromRGB(176, 150, 246),
		Trim = UIKit.Palettes.Graphite.Edge,
	},
	-- A bar's glow reaches at most this far past its light, authored pixels: the kit's 14 points at a tall bar's scale ran
	-- past the cards (TR3's take). Read when a bar is set.
	Bar = { GlowReach = 8 },
}
