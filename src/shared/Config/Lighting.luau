--!strict
-- Lighting (shared Config): Lantern Row's dusk and night (TR8; the director, 2026-11-12: "we should add a night cycle for
-- this festival area as well cause the night looks absolutely gorgeous as well"), on one server clock (Rules.Night), as
-- LightingController turns them. The ground's look holds from its festival gate on; the base keeps the place's own Lighting.
-- The numbers start from the kit's frames (build/handoff/LanternRow/sky/lighting.json, AR5, section 2): a colour, a place
-- and a cone carry over as they are, the haze and the bloom are the handbook's starting values the frames used, and a
-- strength in the kit script's own unit becomes a Roblox one by the builder's seed, keeping the two phases' ratio. Tuned
-- by playing, live: NL_Debug:Invoke("Tune", "Lighting.Phases.Night.Brightness", 1.2); a jump to a phase for the takes:
-- NL_Debug:Invoke("Night", "Night") (or "Dusk", "ToNight", "ToDusk").

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
	-- One turn, from dusk, in seconds: research's seed (tier 2, TR8), tuned by playing. 20 minutes: 13 of dusk, a
	-- minute's crossing, 5 of night, a minute back.
	Cycle = { Dusk = 780, Night = 300, Cross = 60 },
	-- The ground's look begins From studs south of its festival gate, so a door's landing (Config.World.Grey.Door.Landing)
	-- is already in it, under the door's black, and a walk up the side street turns into it there, over Enter seconds.
	From = 24,
	Enter = 1.5,
	-- A sky is swapped at a blend's middle under a peak of haze (handbook/visuals/lighting-and-mood.md, "Skies"): Width,
	-- the share of the blend the peak covers; Density and Haze, added to the Atmosphere's at its top.
	Veil = { Width = 0.3, Density = 0.12, Haze = 0.6 },
	-- The sun where the frames have it: the unit vector toward it, the street running to -Z (lighting.json, "sun"), the
	-- same in both phases so no shadow swings as the night turns. LightingController finds the clock and the latitude that
	-- stand Roblox's sun there, at a day clock: at a night clock Roblox darkens a painted sky (the handbook's pseudo-night).
	Toward = Vector3.new(-0.161, 0.883, 0.441),
	-- The sky's own discs and stars stay hidden: the moon and the stars are painted in the faces.
	SkyBodies = { StarCount = 0, SunAngularSize = 0, MoonAngularSize = 0 },
	Phases = {
		Dusk = {
			-- The six faces, uploaded under the group (docs/asset-log.md, 2026-11-14).
			Sky = faces({ 130610418024599, 133827456103265, 103210699518956, 102529233550104, 86758633678183, 95048421398658 }),
			Sun = hex("A9B4FF"), -- ColorShift_Top: the sun's colour on the faces turned to it
			Brightness = 1.65, -- the frames' 0.55, times 3 (the builder's seed)
			Ambient = hex("242852"), -- Ambient and OutdoorAmbient alike: the frames' colour times strength ("asOne")
			Diffuse = 0.6, -- EnvironmentDiffuseScale
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
			Atmosphere = { Density = 0.28, Offset = 0.1, Haze = 0.8, Glare = 0.1, Color = hex("3A3C80"), Decay = hex("22306A") },
			Bloom = { Intensity = 0.85, Size = 28, Threshold = 1.2 },
			Floor = 1.1, -- higher at night: the floor is darker, and a pool does more of the work
		},
	},
	-- The kit's glow, the same in both phases (EmissiveStrength): every piece's, and the houses' at about two thirds of it
	-- (TR8's first note, research's verdict on AR5: their windows burned as bright as the lanterns).
	Glow = { Kit = 2.4, Houses = 1.6 },
	Houses = { HouseLow = true, HouseTall = true } :: { [string]: boolean },
	-- The street's static lights (the plan's), Shadows off: a pool's SpotLight straight down in its cone, and the keeper's
	-- lamp. Brightness and Range are the builder's seeds against the two targets (the lead at least 1.3 times what's round
	-- him, a Shade's edge at least 0.15), tuned in the engine.
	Pools = { Brightness = 2, Range = 22 },
	Lamp = { Brightness = 1.4, Range = 14 },
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
}
