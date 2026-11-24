--!strict
-- Landing (shared config): AR37's landing, a machine's stage changing in the world (TR51). Modulo's recipe (AR37, "The
-- colour pass", "For Faber, the recipe"), research's pick A, the Climbing Ring, with the cover in the machine's own
-- shape. Frames are at 60 from the landing's start; r and h come from the larger of its two stages' boxes, from the box's
-- foot (Rules.Landing). Tuned by playing: NL_Debug:Invoke("Tune", "Landing.<path>", value).
-- The content check's conditions (AR37, 21:02; docs/asset-log.md, fx_rise_Void): one cover flash per landing, and on one
-- plot at least Gap between two swaps, so at most 3 in any second; a landing that comes while a swap waits swaps to the
-- newest stage under the same cover; no colour, glow or light toward red, orange or yellow (red's share under 0.8).

return {
	Frames = 60, -- its last frame: every part gone, the cover destroyed
	Rise = 33, -- the climb's top: u = (f / Rise)^2
	Swap = 35, -- the old stage gives way to the new at this frame, under the full cover
	Gap = 0.34, -- seconds at least between two swaps on one plot (the flash guard: at most 3 in any second)
	Size = { Across = 0.6, Up = 0.5 }, -- r: half the footprint's diagonal plus Across; h: the height plus Up
	Look = "fx_rise_Void", -- the hoop's and the shaft's (Config.FxKit), Neon in Throw's colour until the kit has it
	-- The hero: an upright band round the machine, the rise ramp turned over (its core at the top), climbing on the
	-- ease-in to h, stretching with speed, then pulled in to a third and gone.
	Hoop = { Least = 0.5, Stretch = 1.3, Pull = { 33, 36 }, Shrink = 0.7, Narrow = 2 / 3, Glow = { 1, 1.6, 1 } },
	-- Thrown out from the top as the hoop bursts: a short upright band (the kit's depth rule: a flat ring goes edge-on at
	-- the camera's height), fast then slow, fading. Reach: its widest, in studs from the machine's middle, the generator's
	-- own clear at Stage III (25.1, AR54; research, 2026-11-23): a wider machine's throw runs the same curve, scaled to end
	-- there, so it never slows against a wall.
	Throw = { From = 34, To = 60, Across = { 0.4, 1.3 }, Tall = { 0.3, 0.02 }, Reach = 25, Colour = Color3.fromRGB(181, 140, 255) },
	-- A short upright shaft rising from the top and thinning.
	Shaft = { From = 35, To = 50, Across = { 0.35, 0.25 }, Tall = { 0.6, 0.1 }, Glow = 1.5 },
	-- Rides the hoop's top to its end, then at half height following the cover. Brightness is the game's first guess
	-- (Blender's is in watts): judged on the in-game capture.
	Light = { Colour = Color3.fromRGB(181, 140, 255), Range = 1.5, Brightness = 2, Least = 0.3, Grow = 0.7, Fill = 0.8 },
	-- The cover: a Highlight on the machine, occluded, so the old shape glows, becomes the new one at Swap and cools.
	Cover = {
		In = { 12, 33 }, -- the fill: span(f, In)^2 to Hold, the swap under it
		Hold = 37,
		Out = 56, -- then (1 - span(f, Hold, Out))^2
		LineIn = { 6, 20 }, -- the outline: ease_out(span(f, LineIn)) * (1 - span(f, LineOut))^2
		LineOut = { 44, 60 },
		Fill = Color3.fromRGB(238, 228, 255),
		Outline = Color3.fromRGB(181, 140, 255),
	},
}
