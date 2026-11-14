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
		-- TR13's looks in grey (UI.RingLooks; research's entry, 2026-11-14): Look puts "Rim", "Pool" or "Pips" in the
		-- ring's place ("Current" keeps today's ring); Beside shows the three in a row left of the ring, Gap apart, on the
		-- same cooldown, for one capture at phone size. Both tuned live. The looks' numbers are the builder's: Rim's head
		-- Head pixels across and its pulse out to Pulse of the rim; Pool's bright line Band of the well tall; Pips' Count
		-- segments, Long by Short pixels.
		Look = "Current",
		Beside = false,
		Gap = 22,
		Looks = {
			Rim = { Head = 7, Pulse = 1.5 },
			Pool = { Band = 0.08 },
			Pips = { Count = 8, Long = 10, Short = 5 },
		},
	},
	-- The spectate toggle (TR11; the director, 2026-11-14, night: the player's camera is never moved in a fight, and a small
	-- button follows the lead instead). The eye: Size authored pixels square (Theme.Size.Tap: a whole 44 px target at the
	-- layer's smallest scale), Gap from the signature's ring, at Place: "Above", "Left" or "Below" the ring, the three
	-- judged at phone size. On, the camera's point eases from the avatar's focus to the lead's, Height studs over the lead's root, about 95% of the way in Ease seconds
	-- (Rules.Hud.Approach); the player's drag and zoom are theirs throughout.
	Spectate = { Size = 52, Gap = 8, Place = "Above", Ease = 0.3, Height = 1.5 },
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
}
