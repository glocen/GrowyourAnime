--!strict
-- Lighting (shared Config): the world's day, dusk and night (TR8; the director, 2026-11-12: "we should add a night cycle
-- for this festival area as well cause the night looks absolutely gorgeous as well"; 2026-11-16: "i feel like the world it
-- a bit to dark and somber we need a day time", yes to adding day to the cycle, TR23), on one server clock (Rules.Night),
-- as LightingController turns them. The ground's look holds from its festival gate on, and over the base too (Everywhere).
-- The numbers start from the kit's frames (build/handoff/LanternRow/sky/lighting.json, AR5, section 2): a colour, a place
-- and a cone carry over as they are, the haze and the bloom are the handbook's starting values the frames used, and a
-- strength in the kit script's own unit becomes a Roblox one by the builder's seed, keeping the two phases' ratio. Tuned
-- by playing, live: NL_Debug:Invoke("Tune", "Lighting.Phases.Night.Brightness", 1.2); a jump to a phase for the takes:
-- NL_Debug:Invoke("Night", "Night") (or "Day", "Dusk", "ToDusk", "ToNight", "ToDay").

local function hex(text: string): Color3
	return Color3.fromHex(text)
end

local function faces(ids: { number }): { [string]: string }
	local out: { [string]: string } = {}
	for index, face in { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" } do
		out[face] = `rbxassetid://{ids[index]}`
	end
	return out
end

return {
	-- One turn, in seconds: each look of Order held for its Hold, then a crossing of Cross into the next, and round again.
	-- 30 minutes, day about 60% of it (the builder's seed at the director's yes, TR23; tuned by playing): 18 of day, a
	-- minute's crossing, 5 of dusk, a minute, 4 of night, a minute's dawn back to day. Dusk and night keep their looks.
	Cycle = { Order = { "Day", "Dusk", "Night" }, Hold = { Day = 1080, Dusk = 300, Night = 240 }, Cross = 60 },
	-- The ground's turn over the whole place, the base's plots and the Strip too (AR14's feel line: "under the same
	-- festival sky as Lantern Row"). Off, the place keeps its own Lighting outside the ground, as below.
	Everywhere = true,
	-- The ground's look begins From studs south of its festival gate, so a door's landing (Config.World.Grey.Door.Landing)
	-- is already in it, under the door's black, and a walk up the side street turns into it there, over Enter seconds.
	From = 24,
	Enter = 1.5,
	-- A sky is swapped at a blend's middle under a peak of haze (handbook/visuals/lighting-and-mood.md, "Skies"): Width,
	-- the share of the blend the peak covers; Density and Haze, added to the Atmosphere's at its top, in the Row.
	Veil = { Width = 0.3, Density = 0.12, Haze = 0.6 },
	-- No mist over the base and the map round it, the Strip and the crossing, in any phase (the director, 2026-11-16,
	-- 16:50: "imo we should remove all that in base and around it it way to much"; docs/decisions.md). South of the Row,
	-- from its From line, each phase's Atmosphere wears Clear's over its own; the Row keeps its haze, and a walk up the
	-- side street turns one into the other over Enter seconds. There a sky's swap hides under a peak of Haze alone, the
	-- coloured layer over the horizon, which veils the sky and leaves the yard clear (Density hides the ground, not the
	-- sky: the handbook's "Atmosphere"): Veil's Density and Haze over Clear's at its top (the builder's seeds, tuned by
	-- playing).
	-- And less somber there (the same words; AR20, research's pick of 17:23: C, bright hours, with round 2's fill, a
	-- rose-lilac dusk and a silver night): Phases' keys over each phase's own, the light, the fill and the exposure, and
	-- the kit's glow and the floors' Glow times theirs, the pools' and the lead's light Lights times theirs. A phase's Sky
	-- here is the base's own, worn south of the Row past its middle (the day keeps the game's day sky), its swap under the
	-- walk's veil. The Row keeps its own. Modulo's C (build/handoff/Base/lighting.json; AR20, "Modulo's paint and skies
	-- for C"; the faces uploaded under the group, docs/asset-log.md, 2026-11-16), tuned by playing.
	Clear = {
		Atmosphere = { Density = 0, Haze = 0, Glare = 0 },
		Veil = { Density = 0, Haze = 2.5 },
		Phases = {
			-- AR40's C by day (build/handoff/Colour/ar40/directions.json, C's Lighting): a warm afternoon, a step less exposed.
			Day = { Ambient = hex("BAAE9C"), Brightness = 2.7, Exposure = 0.08 },
			Dusk = {
				Sky = faces({ 75877956278554, 103984710637104, 74714220433765, 138164631575167, 125396877000879, 111017006396801 }),
				Ambient = hex("70618C"),
				Sun = hex("DDB8EC"),
				Brightness = 2.31,
				Exposure = 0.38,
			},
			Night = {
				Sky = faces({ 84005929943191, 108363997996410, 85851788746244, 96528787831781, 109109844282462, 117630142610865 }),
				Ambient = hex("50597E"),
				Sun = hex("BCCAF0"),
				Brightness = 1.53,
				Exposure = 0.54,
			},
		},
		Glow = 1.5,
		Lights = 1.3,
	},
	-- A crossing's light warms from its first second (TR24's fix 9, TR23's fix 1: "the light starts warming from the
	-- blend's first second, so the swap lands on a sky already near it"): Warm, the share of the way the light, the haze
	-- and the glow have come by the crossing's middle, where the sky swaps; easing into its end (the builder's seed).
	Warm = 0.75,
	-- The sun where the frames have it: the unit vector toward it, the street running to -Z (lighting.json, "sun"), the
	-- same in every phase so no shadow swings as the turn goes round. LightingController finds the clock and the latitude that
	-- stand Roblox's sun there, at a day clock: at a night clock Roblox darkens a painted sky (the handbook's pseudo-night).
	Toward = Vector3.new(-0.161, 0.883, 0.441),
	-- The sky's own discs and stars stay hidden: the moon and the stars are painted in the faces. A phase's Bodies, if any,
	-- stand over these.
	SkyBodies = { StarCount = 0, SunAngularSize = 0, MoonAngularSize = 0 },
	-- A phase: its Sky's six faces (none: Roblox's built-in sky), the sun's colour and Brightness, one flat fill, the sky's
	-- share of the fill (Diffuse), the exposure (ExposureCompensation), the haze, the bloom, the floors' glow (Floor), and
	-- the share of the kit's glow (Glow) and of the street's and the lead's lights (Lights), 1 when not given.
	Phases = {
		-- The day (TR23): a clear azure day under the same sun, warm on the faces turned to it, a lilac fill nearer grey so
		-- the shadows keep a violet and the paving loses its blue cast, the sky's share of the fill halved so the blue sky
		-- tints the ground less, a thin haze (the director to Modulo, 2026-11-16: "a bit to much atmosphere imo like that
		-- mist is a bit to much"), little bloom. The lanterns and the void machines' glow dim to a share, and light up again
		-- at dusk. Modulo's seeds (build/handoff/LanternRow/sky/lighting.json, "Day"; AR5, section 2b), tuned by playing.
		Day = {
			-- The six faces, uploaded under the group (docs/asset-log.md, 2026-11-16); the sun is painted in them.
			Sky = faces({ 98216580739980, 89383367394493, 123733923034090, 132698338964060, 116406582796462, 124209204001841 }),
			Sun = hex("FFDDA6"), -- AR40's C, a warmer sun (directions.json, C's Lighting)
			Brightness = 2.6,
			Ambient = hex("8A8496"),
			Diffuse = 0.5,
			Exposure = 0,
			Atmosphere = { Density = 0.16, Offset = 0.2, Haze = 0.2, Glare = 0.1, Color = hex("EFE3D6"), Decay = hex("A9BCE4") },
			Bloom = { Intensity = 0.3, Size = 24, Threshold = 2.2 },
			Floor = 0.35,
			Glow = 0.6, -- AR40's C: the kit's glow a step up by day, so a light in its dark bed still reads
			Lights = 0.2,
		},
		Dusk = {
			-- The six faces, uploaded under the group (docs/asset-log.md, 2026-11-14).
			Sky = faces({ 130610418024599, 133827456103265, 103210699518956, 102529233550104, 86758633678183, 95048421398658 }),
			Sun = hex("A9B4FF"), -- ColorShift_Top: the sun's colour on the faces turned to it
			Brightness = 1.65, -- the frames' 0.55, times 3 (the builder's seed)
			Ambient = hex("242852"), -- Ambient and OutdoorAmbient alike: the frames' colour times strength ("asOne")
			Diffuse = 0.6, -- EnvironmentDiffuseScale
			Exposure = 0, -- ExposureCompensation
			Atmosphere = { Density = 0.22, Offset = 0.12, Haze = 1, Glare = 0.2, Color = hex("CC7CA0"), Decay = hex("7868B4") },
			Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.3 },
			Floor = 0.85, -- the floors' glow (EmissiveStrength): their painted pools
		},
		Night = {
			Sky = faces({ 107453994329904, 95816790776110, 83803412310392, 72189203581233, 86856414650965, 100058057473740 }),
			Sun = hex("8FA8FF"),
			Brightness = 1.02, -- the frames' 0.34, times 3
			Ambient = hex("10183E"),
			Diffuse = 0.6,
			Exposure = 0,
			Atmosphere = { Density = 0.28, Offset = 0.1, Haze = 0.8, Glare = 0.1, Color = hex("3A3C80"), Decay = hex("22306A") },
			Bloom = { Intensity = 0.85, Size = 28, Threshold = 1.2 },
			Floor = 1.1, -- higher at night: the floor is darker, and a pool does more of the work
		},
	},
	-- The kit's glow, the same in both phases (EmissiveStrength): every piece's, and the houses' at about two thirds of it
	-- (TR8's first note, research's verdict on AR5: their windows burned as bright as the lanterns).
	-- A Breaker's chamber with no shard in it glows at Empty times the kit's (AR15: full while it breaks, low when empty).
	-- The Festival Door's core (AR15, section 7) glows as the kit does, never past CoreBloom times its phase's bloom
	-- Threshold (before its state's share), so its middle stays a warm light and never burns: from the way in at phone size
	-- (the builder's read, 2026-11-17), under the night's threshold of 1.2 its 3.6 and 1.8 clipped to white and 0.7 kept it
	-- gold; under the day's 2.2, 1.63 and 1.32 read as light, 0.82 as a gold disc and 0.27 as a flat one.
	-- A plot's own pieces glow at Base in place of Kit, and its floors at BaseFloor in place of the phase's Floor: the base
	-- made simpler, nothing on its floor lit and nothing leading by glow (AR65, research's pick of the cut pass, 2026-11-26;
	-- halved from the kit's, as the pass was taken).
	Glow = { Kit = 2.4, Houses = 1.6, Empty = 0.2, CoreBloom = 0.6, Base = 1.2, BaseFloor = 0 },
	Houses = { HouseLow = true, HouseTall = true } :: { [string]: boolean },
	Cores = { DoorWay = true } :: { [string]: boolean },
	-- A plot's piece at its own share of Base, by its piece: the Festival Door's frame and rings under the Void Mill (AR65
	-- must-fix 3, no piece outglows the Mill). Read in game at dusk, 2026-11-26, the saturated pixels' relative luminance
	-- at p99, the Mill's cyan 0.61 to 0.67: the Door's gold 0.88 at 1 with its lights, 0.63 at 0.5 and 0.61 at 0.4 without,
	-- 0.56 with no glow at all (its colour under the dusk light).
	BaseShare = { Door = 0.35, DoorRing1 = 0.35, DoorRing2 = 0.35, DoorRing3 = 0.35, DoorRing4 = 0.35 } :: { [string]: number },
	-- A piece whose glow is its own, times its phase's share and none of Clear's lift (AR17's great shard over the crossing:
	-- 2.5 times the kit's, so its light carries to the farthest gate; lifted with the base's glow it blooms into a halo at
	-- night, the manifest's surface note). The Shop's crown and minutes at their manifest's (AR38): the crown the Shop's
	-- brightest, so a lit one reads from far down the Strip; the minutes under the counter's light.
	Steady = { CrossingShard = 6, VoidShopCrown = 5.28, VoidShopMinute = 1.92 } :: { [string]: number },
	-- The street's static lights (the plan's), Shadows off: a pool's SpotLight straight down in its cone, and the keeper's
	-- lamp. Brightness and Range are the builder's seeds against the two targets (the lead at least 1.3 times what's round
	-- him, a Shade's edge at least 0.15), tuned in the engine.
	Pools = { Brightness = 2, Range = 22 },
	Lamp = { Brightness = 1.4, Range = 14 },
	-- A lamp at its own share of Lamp, by its name in the plan. The Door's two light its rings' inner faces, which clip:
	-- at 0.15 they still added 0.10 to the gold's read, past the Mill (BaseShare's read). Off; a light for the core would
	-- reach only the core.
	LampShare = { DoorInside = 0, DoorMouth = 0 } :: { [string]: number },
	-- The plan's tenth light: the player's lead carries one at its head, "under the hat" (AR5), on only in the ground and
	-- turned up with it, Shadows off. The stalls' lamp colour; Brightness and Range the builder's seeds against the lead's
	-- target (at least 1.3 times what's round him), tuned in the engine.
	Lead = { Brightness = 1, Range = 10, Colour = hex("FFD49A") },
	-- The drifting paper (AR5, "The paper's emitter"), after research's TR8 verdict (2026-11-14): a scrap the camera
	-- passed filled a corner as a big flat white quad. The plan's boxes, 4 to 14.5 studs over the paving, held the
	-- camera; a band over it keeps them clear. Roblox's starting zoom (12.5) behind the head (4.5 up) rides 6.65 up
	-- pitched 10 degrees down, as the takes do, and 10.75 at 30. Floor and Top over the paving; the rate follows the
	-- band's height, so the density holds (Kit.PaperBand). Colour: a warm paper's tint over the picture's white.
	Paper = { Floor = 12, Top = 18.5, Colour = hex("F2E3C6") },
	-- The Tower's room (AR56, the Crown): its own look, worn at once while the camera is within Reach of a room's middle
	-- (its way in and out is a fade), as a phase is (Night.Ground). Modulo's lighting.json (build/handoff/TowerRoom), taken
	-- as the base's frames were: the sun where the frames have it (Toward, solved to a day clock like the ground's), its
	-- colour, its Brightness the frames' 1.35 times 3; Ambient and OutdoorAmbient alike the frames' "asOne"; Exposure,
	-- log2 of the frames' 1.057; the bloom the frames' (Size their 20 px). The haze is the builder's seeds against the
	-- frames' "hazeAt" (5% at 150 studs, 15% at 400, 34% at 1000), tuned by playing. No glow or lights to dress: the
	-- room's pieces keep the kit's own (glow 1.3, the floor's 1.1).
	Room = {
		Reach = 600,
		Toward = Vector3.new(-0.821, 0.559, -0.115),
		-- The six faces, uploaded under the group (docs/asset-log.md, 2026-11-24); Ft toward the foe's way in.
		Sky = faces({ 134487859749660, 74431207345196, 111979866191066, 111163049260662, 83024702347687, 122714777710819 }),
		Sun = hex("FFF6E8"),
		Brightness = 4.05,
		Ambient = hex("B0BACF"),
		Diffuse = 0.5,
		Exposure = 0.08,
		Atmosphere = { Density = 0.2, Offset = 0, Haze = 0.3, Glare = 0, Color = hex("D2E2F8"), Decay = hex("D2E2F8") },
		Bloom = { Intensity = 0.4, Size = 20, Threshold = 1.4 },
		Floor = 1,
		Glow = 1,
		Lights = 0,
	},
}
