--!strict
-- Track (shared rules): an effect row's tracks (AR8, "The method"; Config.Effects.Rows). A track is a list of keys, each
-- { frame, value, ease }: frames after the effect's marker at the clip's 60 a second, the value reached there, and the ease
-- on to the next key as Roblox names it ("Quart Out", "Sine InOut", "Linear"; nil is Linear). Before the first key the
-- track has no value (its row isn't shown); past the last it holds. Values: numbers, Vector3s and Color3s.
-- Pure: no engine, so the logic cases run it with Studio closed.

local Track = {}

export type Key = { any }

local POWERS: { [string]: number } = { Quad = 2, Cubic = 3, Quart = 4, Quint = 5 }
local BACK = 1.70158 -- Roblox's Back overshoot

-- The In half of a style, 0 to 1 over u 0 to 1.
local function eased(style: string, u: number): number?
	local power = POWERS[style]
	if power then
		return u ^ power
	elseif style == "Sine" then
		return 1 - math.cos(u * math.pi / 2)
	elseif style == "Exponential" then
		return if u <= 0 then 0 else 2 ^ (10 * (u - 1))
	elseif style == "Circular" then
		return 1 - math.sqrt(math.max(0, 1 - u * u))
	elseif style == "Back" then
		return u * u * ((BACK + 1) * u - BACK)
	end
	return nil
end

-- True when `name` is an ease this module knows: nil, "Linear", or a style and a direction.
function Track.Known(name: string?): boolean
	if name == nil or name == "Linear" then
		return true
	end
	local parts = string.split(name, " ")
	return #parts == 2
		and eased(parts[1], 0.5) ~= nil
		and (parts[2] == "In" or parts[2] == "Out" or parts[2] == "InOut")
end

-- u (0 to 1, clamped) through the ease `name`.
function Track.Ease(name: string?, u: number): number
	local x = math.clamp(u, 0, 1)
	if name == nil or name == "Linear" then
		return x
	end
	local parts = string.split(name, " ")
	local style, way = parts[1], parts[2]
	assert(Track.Known(name), `no ease "{name}"`)
	if way == "In" then
		return eased(style, x) :: number
	elseif way == "Out" then
		return 1 - (eased(style, 1 - x) :: number)
	end
	return if x < 0.5 then (eased(style, 2 * x) :: number) / 2 else 1 - (eased(style, 2 - 2 * x) :: number) / 2
end

local function mix(a: any, b: any, u: number): any
	if typeof(a) == "Color3" then
		return Color3.new(a.R + (b.R - a.R) * u, a.G + (b.G - a.G) * u, a.B + (b.B - a.B) * u)
	end
	return a + (b - a) * u
end

-- The track's value at frame t after its marker; nil before its first key (or with no track).
function Track.Value(keys: { Key }?, t: number): any?
	if keys == nil or #keys == 0 or t < keys[1][1] then
		return nil
	end
	for index = 2, #keys do
		local a, b = keys[index - 1], keys[index]
		if t <= b[1] then
			local span = b[1] - a[1]
			local u = if span > 0 then Track.Ease(a[3], (t - a[1]) / span) else 1
			return mix(a[2], b[2], u)
		end
	end
	return keys[#keys][2]
end

-- The frame a track's first and last keys stand on (0, 0 with no keys).
function Track.Span(keys: { Key }?): (number, number)
	if keys == nil or #keys == 0 then
		return 0, 0
	end
	return keys[1][1], keys[#keys][1]
end

-- A burst's particle count at the player's Effects level, a share 0 to 1: the count in that share, rounded, and never
-- below one above 0, so a one-particle hero shape (the mend's Core and Star) is never the first thing a low level loses
-- (Scintilla, AR58, 2026-11-25). At 0 nothing draws.
function Track.Burst(count: number, share: number): number
	if share <= 0 or count < 1 then
		return 0
	end
	return math.max(1, math.round(count * share))
end

return Track
