--!strict
-- Night (shared, pure): Lantern Row's dusk and night on one server clock (TR8; the director, 2026-11-12: "we should add a
-- night cycle for this festival area as well"; docs/decisions.md). The clock is the server's own time from an epoch the
-- server can move (the workspace attribute NightFrom, a jump to a phase for the takes), so every client sees the same
-- hour. A turn is dusk, a crossing to night, night, and a crossing back (Config.Lighting.Cycle). LightingController mixes
-- the place's own look and the ground's by where the avatar stands, and the ground's dusk and night by the clock. No
-- Roblox API beyond its data types: it runs with Studio closed.
--   Night.Length(cycle)                 seconds in one turn
--   Night.At(seconds, cycle)            (night, phase): night 0 at dusk to 1 at night, eased through a crossing; phase
--                                       "Dusk", "ToNight", "Night" or "ToDusk"
--   Night.Left(seconds, cycle)          seconds until the phase changes
--   Night.From(phase, now, cycle)       the epoch that puts `now` at the phase's start
--   Night.Veil(w, width)                0 to 1: the haze's peak over a blend's middle, where a sky is swapped (a sky can't
--                                       fade into another: handbook/visuals/lighting-and-mood.md, "Skies"), `width` the
--                                       share of the blend it covers
--   Night.Mix(a, b, w)                  a look between two, key by key: numbers, colours and vectors blend; anything else
--                                       is a's below the middle and b's from it (which sky)
--   Night.Ground(phase, sky, sun)       a phase of Config.Lighting as a look, its sun at `sun` (clock, latitude)
--   Night.Inside(z, gateZ, from)        whether a point `z` stands in the ground: north of its festival gate, or within
--                                       `from` studs south of it

local Night = {}

-- The workspace attribute holding the turn's epoch, the server's time a dusk began (0 unless a jump moved it).
Night.Attribute = "NightFrom"

export type Cycle = { Dusk: number, Night: number, Cross: number }
export type Sun = { Clock: number, Latitude: number }

local PHASES = { "Dusk", "ToNight", "Night", "ToDusk" }

local function ease(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Where each phase starts in a turn, and how long it lasts.
local function spans(cycle: Cycle): { { number } }
	local a = cycle.Dusk
	local b = a + cycle.Cross
	local c = b + cycle.Night
	return { { 0, a }, { a, cycle.Cross }, { b, cycle.Night }, { c, cycle.Cross } }
end

function Night.Length(cycle: Cycle): number
	return cycle.Dusk + cycle.Night + 2 * cycle.Cross
end

local function where(seconds: number, cycle: Cycle): (number, number)
	local length = Night.Length(cycle)
	local t = if length > 0 and seconds == seconds then seconds % length else 0
	for index, span in spans(cycle) do
		if t < span[1] + span[2] or index == #PHASES then
			return index, t - span[1]
		end
	end
	return 1, t
end

function Night.At(seconds: number, cycle: Cycle): (number, string)
	local index, into = where(seconds, cycle)
	local phase = PHASES[index]
	if phase == "Dusk" then
		return 0, phase
	elseif phase == "Night" then
		return 1, phase
	end
	local w = if cycle.Cross > 0 then ease(into / cycle.Cross) else 1
	return if phase == "ToNight" then w else 1 - w, phase
end

function Night.Left(seconds: number, cycle: Cycle): number
	local index, into = where(seconds, cycle)
	return math.max(0, spans(cycle)[index][2] - into)
end

function Night.From(phase: string, now: number, cycle: Cycle): number
	local index = table.find(PHASES, phase)
	assert(index, `no phase "{phase}": Dusk, ToNight, Night or ToDusk`)
	return now - spans(cycle)[index][1]
end

function Night.Veil(w: number, width: number): number
	if width <= 0 then
		return 0
	end
	local d = math.abs(w - 0.5) / (width / 2)
	return if d >= 1 then 0 else ease(1 - d)
end

function Night.Mix(a: any, b: any, w: number): any
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return if w < 0.5 then a else b
	elseif kind == "number" then
		return a + (b - a) * w
	elseif kind == "Color3" or kind == "Vector3" then
		return a:Lerp(b, w)
	elseif kind == "table" then
		local out = {}
		for key, value in a do
			out[key] = if b[key] == nil then value else Night.Mix(value, b[key], w)
		end
		for key, value in b do
			if out[key] == nil then
				out[key] = value
			end
		end
		return out
	end
	return if w < 0.5 then a else b
end

-- A phase as Lighting holds it: the sun's colour on the faces turned to it (ColorShift_Top) and its brightness, one flat
-- fill for Ambient and OutdoorAmbient alike (the kit's frames: lighting.json, "ambient", asOne), the sky's share of the
-- fill, the haze and the bloom; the sky by its name; the sun where the frames have it, at a day clock (the handbook's
-- pseudo-night). Floor is the floors' glow, apart from Lighting.
function Night.Ground(phase: any, sky: string, sun: Sun): any
	return {
		Lighting = {
			Ambient = phase.Ambient,
			OutdoorAmbient = phase.Ambient,
			Brightness = phase.Brightness,
			ColorShift_Top = phase.Sun,
			EnvironmentDiffuseScale = phase.Diffuse,
			ClockTime = sun.Clock,
			GeographicLatitude = sun.Latitude,
		},
		Atmosphere = table.clone(phase.Atmosphere),
		Bloom = table.clone(phase.Bloom),
		Sky = sky,
		Floor = phase.Floor,
	}
end

function Night.Inside(z: number, gateZ: number, from: number): boolean
	return z < gateZ + from
end

return Night
