--!strict
-- Landing (pure rules): AR37's landing frame by frame, and when one may start (TR51; Config.Landing). Heights are studs
-- from the machine's foot, widths across in studs. The client plays At each frame (LandingController); the server
-- schedules each plot's landings by Start, so no two swaps on a plot come closer than Config's Gap (the flash guard).

local Landing = {}

export type Config = {
	Rise: number,
	Swap: number,
	Size: { Across: number, Up: number },
	Hoop: { Least: number, Stretch: number, Pull: { number }, Shrink: number, Narrow: number, Glow: { number } },
	Throw: { From: number, To: number, Across: { number }, Tall: { number } },
	Shaft: { From: number, To: number, Across: { number }, Tall: { number }, Glow: number },
	Light: { Least: number, Grow: number, Fill: number },
	Cover: { In: { number }, Hold: number, Out: number, LineIn: { number }, LineOut: { number } },
}

export type Frame = {
	Hoop: { Top: number, Foot: number, Across: number, Glow: number }?, -- nil once it's burst
	Throw: { Across: number, Tall: number, Up: number, Transparency: number }?, -- its middle at Up
	Shaft: { Across: number, Tall: number, Foot: number, Glow: number, Transparency: number }?,
	Light: { Up: number, Share: number }, -- Share of Config's Brightness
	Fill: number, -- the cover's fill, 0 clear to 1 full
	Line: number, -- its outline's
	Swapped: boolean, -- the new stage stands
}

-- f's share of the way from a to b, held to 0 and 1.
function Landing.Span(f: number, a: number, b: number): number
	return math.clamp((f - a) / (b - a), 0, 1)
end

function Landing.EaseOut(x: number): number
	return 1 - (1 - x) ^ 3
end

-- r and h from the larger of its stages' boxes (each { width, depth, height } in studs).
function Landing.Size(boxes: { { number } }, config: Config): (number, number)
	local r, h = 0, 0
	for _, box in boxes do
		r = math.max(r, math.sqrt(box[1] ^ 2 + box[2] ^ 2) / 2 + config.Size.Across)
		h = math.max(h, box[3] + config.Size.Up)
	end
	return r, h
end

-- Every part's numbers at frame f (at 60 from the start), for a machine of r and h.
function Landing.At(f: number, r: number, h: number, config: Config): Frame
	local span, ease = Landing.Span, Landing.EaseOut
	local u = (f / config.Rise) ^ 2
	local cover = config.Cover
	local fill = if f <= cover.Hold then span(f, cover.In[1], cover.In[2]) ^ 2 else (1 - span(f, cover.Hold, cover.Out)) ^ 2
	local frame: Frame = {
		Fill = fill,
		Line = ease(span(f, cover.LineIn[1], cover.LineIn[2])) * (1 - span(f, cover.LineOut[1], cover.LineOut[2])) ^ 2,
		Swapped = f >= config.Swap,
		Light = { Up = 0, Share = 0 },
	}
	local hoop = config.Hoop
	if f < hoop.Pull[2] then
		local pull = span(f, hoop.Pull[1], hoop.Pull[2])
		local tall = (hoop.Least + hoop.Stretch * u) * (1 - hoop.Shrink * pull)
		local top = h * u
		frame.Hoop = {
			Top = top,
			Foot = math.max(0, top - tall), -- never under the ground
			Across = 2 * r * (1 - hoop.Narrow * ease(pull)),
			Glow = hoop.Glow[1] + hoop.Glow[2] * u + hoop.Glow[3] * pull,
		}
		frame.Light = { Up = top, Share = config.Light.Least + config.Light.Grow * u }
	else
		frame.Light = { Up = h / 2, Share = config.Light.Fill * fill }
	end
	local throw = config.Throw
	if f >= throw.From and f < throw.To then
		local k = span(f, throw.From, throw.To)
		frame.Throw = {
			Across = 2 * r * (throw.Across[1] + throw.Across[2] * ease(k)),
			Tall = throw.Tall[1] + throw.Tall[2] * r,
			Up = h,
			Transparency = 1 - (1 - k) ^ 2,
		}
	end
	local shaft = config.Shaft
	if f >= shaft.From and f < shaft.To then
		local k = span(f, shaft.From, shaft.To)
		frame.Shaft = {
			Across = 2 * (shaft.Across[1] - shaft.Across[2] * k),
			Tall = shaft.Tall[1] * h * ease(k) + shaft.Tall[2],
			Foot = h,
			Glow = shaft.Glow * (1 - k) ^ 2,
			Transparency = 1 - (1 - k) ^ 2,
		}
	end
	return frame
end

-- When a landing asked for at `now` starts, given its plot's last swap (`last`, nil for none yet), so its swap (`swap`
-- seconds after its start) is the same instant as that one (a base level-up's machines, or one asked for while that
-- one is still to come), or at least `gap` after it. Seconds on one clock.
function Landing.Start(last: number?, now: number, swap: number, gap: number): number
	if last == nil then
		return now
	end
	local at = now + swap
	if at >= last + gap then
		return now -- clear of the last
	elseif at <= last then
		return last - swap -- the last is still to come: on its instant, one flash
	end
	return last + gap - swap -- inside the last one's window: the next it allows
end

return Landing
