--!strict
-- Night (shared, pure): the world's day, dusk and night on one server clock (TR8; the director, 2026-11-12: "we should
-- add a night cycle for this festival area as well"; 2026-11-16: "we need a day time", yes to adding day to the cycle;
-- docs/decisions.md). The clock is the server's own time from an epoch the server can move (the workspace attribute
-- NightFrom, a jump to a phase for the takes), so every client sees the same hour. A turn holds each look of the
-- cycle's Order in turn for its Hold, then crosses into the next over Cross seconds, and round again
-- (Config.Lighting.Cycle). LightingController mixes the place's own look and the ground's by where the avatar stands,
-- and the turn's two looks by the clock. No Roblox API beyond its data types: it runs with Studio closed.
--   Night.Length(cycle)                 seconds in one turn
--   Night.Phases(cycle)                 the turn's phases in order: each look, then "To" and the next one's name
--   Night.Turn(seconds, cycle)          (from, to, w, phase, x): the two looks the turn stands between, w 0 at `from` to
--                                       1 at `to`, eased through a crossing (from == to, w 0, while a look holds); x the
--                                       crossing's own share, not eased (0 while a look holds)
--   Night.Warm(x, warm)                 0 to 1: how far a crossing's light has come at its share x, from its first second,
--                                       `warm` of the way by its middle, easing into its end (TR24's fix 9)
--   Night.Left(seconds, cycle)          seconds until the phase changes
--   Night.From(phase, now, cycle)       the epoch that puts `now` at the phase's start
--   Night.Veil(w, width)                0 to 1: the haze's peak over a blend's middle, where a sky is swapped (a sky can't
--                                       fade into another: handbook/visuals/lighting-and-mood.md, "Skies"), `width` the
--                                       share of the blend it covers
--   Night.Mix(a, b, w)                  a look between two, key by key: numbers, colours and vectors blend; anything else
--                                       is a's below the middle and b's from it (which sky)
--   Night.Clear(look, clear, w)         a table's keys with `clear`'s over them by w, 0 none to 1 all, a key it doesn't
--                                       hold left out: an Atmosphere's (no mist outside the Row, the director's 16:50), a
--                                       phase's (AR20's bright hours there)
--   Night.Ground(phase, sky, sun)       a phase of Config.Lighting as a look, its sun at `sun` (clock, latitude)
--   Night.Inside(z, gateZ, from)        whether a point `z` stands in the ground: north of its festival gate, or within
--                                       `from` studs south of it

local Night = {}

-- The workspace attribute holding the turn's epoch, the server's time a turn began (0 unless a jump moved it).
Night.Attribute = "NightFrom"

export type Cycle = { Order: { string }, Hold: { [string]: number }, Cross: number }
export type Sun = { Clock: number, Latitude: number }
type Span = { Phase: string, From: string, To: string, Start: number, Length: number }

local function ease(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Each phase of a turn: where it starts, how long it lasts, and the two looks it stands between.
local function spans(cycle: Cycle): { Span }
	local out: { Span } = {}
	local start = 0
	for index, name in cycle.Order do
		local hold = math.max(0, cycle.Hold[name] or 0)
		table.insert(out, { Phase = name, From = name, To = name, Start = start, Length = hold })
		start += hold
		local nextName = cycle.Order[index % #cycle.Order + 1]
		table.insert(out, { Phase = `To{nextName}`, From = name, To = nextName, Start = start, Length = cycle.Cross })
		start += cycle.Cross
	end
	return out
end

function Night.Length(cycle: Cycle): number
	local length = 0
	for _, span in spans(cycle) do
		length += span.Length
	end
	return length
end

function Night.Phases(cycle: Cycle): { string }
	local out: { string } = {}
	for _, span in spans(cycle) do
		table.insert(out, span.Phase)
	end
	return out
end

-- The span the turn stands in at `seconds`, and how far into it. A span of no length is passed over.
local function where(seconds: number, cycle: Cycle): (Span, number)
	local all = spans(cycle)
	local length = Night.Length(cycle)
	local t = if length > 0 and seconds == seconds then seconds % length else 0
	for _, span in all do
		if span.Length > 0 and t < span.Start + span.Length then
			return span, t - span.Start
		end
	end
	return all[1], 0
end

function Night.Turn(seconds: number, cycle: Cycle): (string, string, number, string, number)
	local span, into = where(seconds, cycle)
	if span.From == span.To then
		return span.From, span.To, 0, span.Phase, 0
	end
	local x = if span.Length > 0 then math.clamp(into / span.Length, 0, 1) else 1
	return span.From, span.To, ease(x), span.Phase, x
end

function Night.Warm(x: number, warm: number): number
	local t = math.clamp(if x == x then x else 0, 0, 1)
	local share = math.clamp(if warm == warm then warm else 0.5, 1e-3, 1 - 1e-3)
	-- 1 - (1 - t)^p, its p putting `share` at the middle: p 1 is a straight line (share 0.5), p 2 an ease-out (0.75)
	local p = math.log(1 - share) / math.log(0.5)
	return 1 - (1 - t) ^ p
end

function Night.Left(seconds: number, cycle: Cycle): number
	local span, into = where(seconds, cycle)
	return math.max(0, span.Length - into)
end

function Night.From(phase: string, now: number, cycle: Cycle): number
	for _, span in spans(cycle) do
		if span.Phase == phase then
			return now - span.Start
		end
	end
	error(`no phase "{phase}": {table.concat(Night.Phases(cycle), ", ")}`)
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
-- pseudo-night). Apart from Lighting: Floor, the floors' glow; Glow, the share of the kit's glow; Lights, the share of the
-- street's lights and the lead's (by day both dim, and light up at dusk), 1 when a phase doesn't say.
function Night.Clear(atmosphere: { [string]: any }, clear: { [string]: any }, w: number): { [string]: any }
	local out = table.clone(atmosphere)
	for key, value in clear do
		if out[key] ~= nil then
			out[key] = Night.Mix(out[key], value, math.clamp(w, 0, 1))
		end
	end
	return out
end

-- The sky worn for phase `name`: the base's own, `Clear<name>`, once `out` of the Row is past its middle and Clear gives
-- that phase faces (AR20's C); else the phase's own, by its name.
function Night.SkyOf(name: string, clear: { [string]: any }, out: number): string
	local over = clear[name]
	return if over and over.Sky and out > 0.5 then `Clear{name}` else name
end

function Night.Ground(phase: any, sky: string, sun: Sun): any
	return {
		Lighting = {
			Ambient = phase.Ambient,
			OutdoorAmbient = phase.Ambient,
			Brightness = phase.Brightness,
			ColorShift_Top = phase.Sun,
			EnvironmentDiffuseScale = phase.Diffuse,
			ExposureCompensation = phase.Exposure or 0,
			ClockTime = sun.Clock,
			GeographicLatitude = sun.Latitude,
		},
		Atmosphere = table.clone(phase.Atmosphere),
		Bloom = table.clone(phase.Bloom),
		Sky = sky,
		Floor = phase.Floor,
		Glow = phase.Glow or 1,
		Lights = phase.Lights or 1,
	}
end

function Night.Inside(z: number, gateZ: number, from: number): boolean
	return z < gateZ + from
end

return Night
