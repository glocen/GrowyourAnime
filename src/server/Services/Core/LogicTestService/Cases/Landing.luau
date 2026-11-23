--!strict
-- Logic cases (pure): AR37's landing (TR51; Rules.Landing; Config.Landing): its beats frame by frame, and the flash
-- guard's schedule. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Landing = require(Shared.Rules.Landing)
local LandingConfig = require(Shared.Config.Landing)

local config: Landing.Config = LandingConfig :: any

return {
	{
		Name = "Landing (AR37): the hoop climbs on the ease-in to the machine's top, pulls in to a third and bursts; the swap at 35 under the full cover, never seen",
		Run = function(t: any)
			local r, h = 7.7, 13.2 -- the Forge's, AR37's plan
			local top = -1
			local climbs = true
			for f = 0, 35 do
				local hoop = Landing.At(f, r, h, config).Hoop
				if hoop == nil or hoop.Top < top or hoop.Foot < 0 or hoop.Foot > hoop.Top then
					climbs = false
				end
				top = if hoop then hoop.Top else top
			end
			t.Check("frames 0 to 35: the hoop rises, its foot never under the ground nor over its top", climbs)
			t.Equal("frame 0: on the ground", (Landing.At(0, r, h, config).Hoop :: any).Top, 0)
			t.Check("frame 33, the climb's top: at h", math.abs((Landing.At(33, r, h, config).Hoop :: any).Top - h) < 1e-9)
			local early, late = (Landing.At(8, r, h, config).Hoop :: any).Top, (Landing.At(16, r, h, config).Hoop :: any).Top
			t.Check("accelerating: twice the time, four times the height", math.abs(late - 4 * early) < 1e-9, `{early}, {late}`)
			t.Check("round the machine while it climbs: 2r across", math.abs((Landing.At(20, r, h, config).Hoop :: any).Across - 2 * r) < 1e-9)
			t.Check("frame 36: pulled in to a third, then gone", Landing.At(36, r, h, config).Hoop == nil
				and math.abs((Landing.At(35.999, r, h, config).Hoop :: any).Across - 2 * r / 3) < 1e-2)
			-- The cover: full from the climb's top to Hold, the swap inside it; clear before In and after Out.
			for f = 0, 60 do
				local frame = Landing.At(f, r, h, config)
				local full = f >= 33 and f <= 37
				if full ~= (frame.Fill == 1) then
					t.Check(`frame {f}: the fill full only from 33 to 37`, false, tostring(frame.Fill))
				end
				if frame.Fill < 0 or frame.Fill > 1 or frame.Line < 0 or frame.Line > 1 then
					t.Check(`frame {f}: the cover's numbers between 0 and 1`, false, `{frame.Fill}, {frame.Line}`)
				end
				if frame.Swapped ~= (f >= 35) then
					t.Check(`frame {f}: the new stage from 35 only`, false)
				end
			end
			t.Check("the swap's frames, 34 to 36, all under the full cover", Landing.At(34, r, h, config).Fill == 1 and Landing.At(36, r, h, config).Fill == 1)
			t.Check("clear before 12 and from 56", Landing.At(11, r, h, config).Fill == 0 and Landing.At(56, r, h, config).Fill == 0)
			t.Check("the outline in from 6 and gone at 60", Landing.At(6, r, h, config).Line == 0 and Landing.At(60, r, h, config).Line == 0 and Landing.At(30, r, h, config).Line == 1)
			-- The throw and the shaft: from the top, fading to clear by their ends.
			local throw = Landing.At(34, r, h, config).Throw
			t.Check("frame 34: the throw at the top, 0.8 r across, lit", throw ~= nil and throw.Up == h and math.abs(throw.Across - 0.8 * r) < 1e-9 and throw.Transparency == 0)
			t.Check("a small machine's throw runs its whole curve: 1.7 r at its end", math.abs((Landing.At(59.999, r, h, config).Throw :: any).Across - 2 * 1.7 * r) < 1e-3)
			-- The generator at Stage III (r about 21.5): its throw held inside the Reach, on the same curve, scaled.
			local big = 21.5
			local widest, smooth, last = 0, true, -1
			for f = 34, 59.75, 0.25 do
				local across = (Landing.At(f, big, h, config).Throw :: any).Across
				widest = math.max(widest, across / 2)
				smooth = smooth and across > last
				last = across
			end
			t.Check(`the generator's throw never past the Reach ({config.Throw.Reach} studs)`, widest <= (config.Throw.Reach :: number) + 1e-9 and widest > (config.Throw.Reach :: number) - 0.2, string.format("%.2f", widest))
			t.Check("and still widening to its end, never held at a wall", smooth)
			t.Check("the throw fades out by 60", Landing.At(59.999, r, h, config).Throw ~= nil and (Landing.At(59.999, r, h, config).Throw :: any).Transparency > 0.999 and Landing.At(60, r, h, config).Throw == nil)
			local shaft = Landing.At(42, r, h, config).Shaft
			t.Check("the shaft rises from the top and thins", shaft ~= nil and shaft.Foot == h and shaft.Across < 0.7 and Landing.At(50, r, h, config).Shaft == nil)
			-- The light: up the frame with the hoop, then with the cover.
			local light = Landing.At(20, r, h, config).Light
			t.Check("the light rides the hoop's top", math.abs(light.Up - (Landing.At(20, r, h, config).Hoop :: any).Top) < 1e-9)
			t.Check("after the burst it follows the fill", math.abs(Landing.At(45, r, h, config).Light.Share - 0.8 * Landing.At(45, r, h, config).Fill) < 1e-9)
		end,
	},
	{
		Name = "Landing (AR37): r and h from the larger of the two stages' boxes, half the footprint's diagonal plus 0.6 and the height plus 0.5",
		Run = function(t: any)
			local r, h = Landing.Size({ { 6, 8, 10 } }, config)
			t.Check("one box: 5.6 and 10.5", math.abs(r - 5.6) < 1e-9 and math.abs(h - 10.5) < 1e-9, `{r}, {h}`)
			r, h = Landing.Size({ { 6, 8, 10 }, { 4, 3, 12 } }, config)
			t.Check("two: the wider's r, the taller's h", math.abs(r - 5.6) < 1e-9 and math.abs(h - 12.5) < 1e-9, `{r}, {h}`)
		end,
	},
	{
		Name = "Landing (AR37's flash guard): on a plot, a base level-up's machines swap on one instant; a landing inside another's window waits, or joins one still to come; at most 3 swaps in any second",
		Run = function(t: any)
			local swap, gap = LandingConfig.Swap / 60, LandingConfig.Gap
			t.Equal("Config's gap: 0.34 s (the content check)", gap, 0.34)
			t.Check("so at most 3 in any second", math.floor(1 / gap) + 1 <= 3)
			t.Equal("none before: now", Landing.Start(nil, 10, swap, gap), 10)
			local first = Landing.Start(nil, 10, swap, gap)
			t.Equal("a base level-up: the next machine on the same instant starts with it", Landing.Start(first + swap, 10, swap, gap), 10)
			t.Check("0.1 s later: waits for the window's end", math.abs(Landing.Start(10 + swap, 10.1, swap, gap) + swap - (10 + swap + gap)) < 1e-9)
			t.Equal("0.34 s later: clear", Landing.Start(10 + swap, 10.34, swap, gap), 10.34)
			t.Equal("one waiting at 10.34's swap, asked again at 10.2: joins it", Landing.Start(10.34 + swap, 10.2, swap, gap), 10.34)
			-- Back-to-back raises and level-ups, at random: every start at or after its ask, and the swaps one instant or
			-- at least the gap apart, so never more than 3 in a second.
			-- Its own seeded numbers (an LCG), so it runs with Studio closed as well (the engine's Random can't).
			local seed = 51
			local function number(): number
				seed = (seed * 1103515245 + 12345) % 2147483648
				return seed / 2147483648
			end
			local worst, early, close = 0, false, false
			for _ = 1, 400 do
				local now, last = 0, nil :: number?
				local swaps: { number } = {}
				for _ = 1, 2 + math.floor(number() * 11) do
					now += if number() < 0.3 then 0 else number() * 0.6
					local start = Landing.Start(last, now, swap, gap)
					early = early or start < now - 1e-9
					local at = start + swap
					if last == nil or at > last + 1e-9 then
						close = close or (last ~= nil and at < last + gap - 1e-9)
						table.insert(swaps, at)
						last = at
					end
				end
				for i, a in swaps do
					local count = 0
					for j = i, #swaps do
						if swaps[j] < a + 1 then
							count += 1
						end
					end
					worst = math.max(worst, count)
				end
			end
			t.Check("never before it's asked for", not early)
			t.Check("two flashes never closer than the gap", not close)
			t.Check(`at most 3 swaps in any second (worst {worst})`, worst <= 3)
		end,
	},
}
