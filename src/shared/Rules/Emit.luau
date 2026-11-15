--!strict
-- Emit (shared, pure): what an effect's Emitter row lets go, and how a sheet's passes are let go as one (Config.Effects,
-- "Emit" and "Sheet"; AR9's emitter row). Frames are the clip's, 60 a second.
-- A burst: the row's own Emit list of { frame, count }, and the vault's convention on the emitter itself, EmitCount
-- particles after EmitDelay seconds from the row's start. Those two are the kit's keys, not Roblox's, so they're never set
-- on the ParticleEmitter (Emit.Own).
-- A sheet's three passes (Config.FxKit.Sheets: its dark twin under, its fill, its line on top) are three emitters, and
-- Roblox draws each particle's chances on each emitter apart, so with any spread the line would leave its fill. So a
-- sheet row's particles are drawn here, once each, and every pass lets go the same one: one place, one way, one life,
-- one speed, one turn, one size (Rows, "sheet").
-- No Roblox API: it runs with Studio closed.

local Emit = {}

local FRAMES = 60 -- a second of the clip

-- The keys of a row's Emitter table that are the kit's own, never a ParticleEmitter's property.
Emit.Own = { EmitCount = true, EmitDelay = true } :: { [string]: boolean }

export type Source = { Emit: { { number } }?, Emitter: { [string]: any }? }
export type Point = { number } -- { time, value, envelope? }

-- Every burst the row lets go, as { frame, count }: its Emit list in order, then its emitter's EmitCount at EmitDelay
-- (none, or under 0: at the row's start). A count of none or under one lets nothing go.
function Emit.Bursts(row: Source): { { number } }
	local list: { { number } } = {}
	for _, burst in row.Emit or {} do
		if burst[2] >= 1 then
			table.insert(list, { burst[1], burst[2] })
		end
	end
	local emitter: { [string]: any } = row.Emitter or {}
	local count = emitter.EmitCount
	if type(count) == "number" and count >= 1 then
		local delay = emitter.EmitDelay
		table.insert(list, { (if type(delay) == "number" then math.max(delay, 0) else 0) * FRAMES, math.floor(count) })
	end
	return list
end

-- One value from a row's number or { low, high } range, `u` in [0, 1) from low to high.
function Emit.Pick(range: number | { number }, u: number): number
	if type(range) == "number" then
		return range
	end
	return range[1] + (range[2] - range[1]) * u
end

-- A sequence's points for one particle: each { time, value, envelope } at value plus `u` (in [-1, 1]) times its
-- envelope, the envelope gone. One chance for the whole sequence, so its shape holds.
function Emit.Fixed(points: { Point }, u: number): { Point }
	local fixed: { Point } = {}
	for _, point in points do
		table.insert(fixed, { point[1], point[2] + u * (point[3] or 0) })
	end
	return fixed
end

-- The dark twin's transparency over the bright passes' `points`: as clear again by `extra` (1 - (1 - t) (1 - extra)),
-- so it fades with them and never stands out alone. None: `extra` throughout.
function Emit.Twin(points: { Point }?, extra: number): { Point }
	if points == nil or #points == 0 then
		return { { 0, extra }, { 1, extra } }
	end
	local twin: { Point } = {}
	for _, point in points do
		table.insert(twin, { point[1], 1 - (1 - point[2]) * (1 - extra) })
	end
	return twin
end

-- How many particles a Rate lets go over `seconds`, with what's left over from the last step (`carry`, under one): the
-- count, and the new carry.
function Emit.Due(rate: number, carry: number, seconds: number): (number, number)
	local total = carry + math.max(rate, 0) * math.max(seconds, 0)
	local count = math.floor(total)
	return count, total - count
end

-- A place in a disc of `radius`, from two chances in [0, 1): spread evenly over it, or on its rim when `rim` is set (an
-- emitter's ShapeStyle Surface). Returns the two coordinates across it.
function Emit.InDisc(radius: number, u: number, v: number, rim: boolean): (number, number)
	local r = if rim then radius else radius * math.sqrt(u)
	local angle = 2 * math.pi * v
	return r * math.cos(angle), r * math.sin(angle)
end

-- The two turns off the emission's way, in radians, from SpreadAngle's { x, y } degrees and two chances in [0, 1).
function Emit.Spread(spread: { number }?, u: number, v: number): (number, number)
	if spread == nil then
		return 0, 0
	end
	return math.rad((2 * u - 1) * spread[1]), math.rad((2 * v - 1) * (spread[2] or spread[1]))
end

return Emit
