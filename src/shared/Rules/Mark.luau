--!strict
-- Mark (pure): a marked strike's footprint, and the lead's ways out of it (docs/test-requests.md, TR44;
-- Config.Combat.Keeper.Mark and Out). FightService puts the footprint down and resolves its hit; SlamService moves the
-- lead out and counts the slams. No Roblox API: its cases run with Studio closed. Flat positions are (x, z) pairs.
--   Mark.Centre(x, z, lookX, lookZ, ahead, left) -> (x, z)   where it lands: `ahead` along the look, `left` to its left
--   Mark.Inside(cx, cz, radius, x, z) -> boolean             a centre within the radius: the hit takes it
--   Mark.OnLine(x0, z0, dx, dz, length, half, x, z) -> boolean  AR52, the Dasher's line: a centre within `half` of the
--                                                            segment from (x0, z0), `length` along the unit (dx, dz)
--   Mark.Swept(cx, cz, a0, a1, length, half, x, z) -> boolean  TR69 D, the keeper's sweep: a centre the line passed
--                                                            over, turned about (cx, cz) from a0 to a1 (radians, as
--                                                            atan2(z, x)), `length` long and `half` either side
--   Mark.Fanned(x0, z0, dx, dz, length, half, spread, x, z) -> boolean  TR69 B, the Dasher elite's fan: OnLine on any of
--                                                            three lanes, the line and the line turned `spread` (radians)
--                                                            either way about (x0, z0)
--   Mark.Covers(shape, x, z) -> boolean                      a ring's Inside, a line's OnLine when it has a Length (its
--                                                            Fanned with a Fan), or a sweep's Swept over its whole Arc
--   Mark.Screens(gx, gz, lookX, lookZ, wide, ahead, ax, az, tx, tz) -> boolean  TR69 B, the Guard elite's screen: the
--                                                            blow from (ax, az) to (tx, tz) crosses the wall `wide`
--                                                            across, its middle `ahead` along the guard's look
--   Mark.Fill(now, down, slam) -> number                     the disc's share of the ring: 0 when it's put down, 1 on the Slam
--   Mark.Follows(moved, outside, least) -> boolean           A: the avatar stands `least` or more from where it stood at
--                                                            the Plant, outside the ring: its lead breaks off
--   Mark.Purpose(moved, recalled, least) -> Kind             a miss's kind: on purpose (a move of `least`, or a Recall, in
--                                                            the tell) or by accident (neither)
--   Mark.Count(counts, mode, hit, kind?)                     one slam counted under its mode, in place
--   Mark.Ready(last, now, cooldown) -> (boolean, number)     B's Recall: ready now, and the time it's ready from
--   Mark.Mode(value) -> Mode                                 the switch read safely: anything but "A" or "B" is "Off"

local Mark = {}

export type Mode = "Off" | "A" | "B"
export type Kind = "OnPurpose" | "Accident"
export type Tally = { Slams: number, Hit: number, Missed: number, OnPurpose: number, Accident: number }
export type Counts = { [string]: Tally }
-- A footprint's shape: a ring of Radius round (X, Z); with Length, a line from (X, Z) along the unit (DirX, DirZ), Radius
-- either side of it; with Length and Arc, a sweep (TR69 D): that line turned about (X, Z) from From over Arc (radians);
-- with Length and Fan, three such lines, the line and it turned Fan (radians) either way (TR69 B, the Dasher elite).
export type Shape = { X: number, Z: number, Radius: number, Length: number?, DirX: number?, DirZ: number?, From: number?, Arc: number?, Fan: number? }

function Mark.Centre(x: number, z: number, lookX: number, lookZ: number, ahead: number, left: number): (number, number)
	local length = math.sqrt(lookX * lookX + lookZ * lookZ)
	if length < 1e-6 then
		return x, z
	end
	local lx, lz = lookX / length, lookZ / length
	-- its left, flat: the look turned a quarter anticlockwise seen from above, (lz, -lx)
	return x + lx * ahead + lz * left, z + lz * ahead - lx * left
end

function Mark.Inside(cx: number, cz: number, radius: number, x: number, z: number): boolean
	local dx, dz = x - cx, z - cz
	return dx * dx + dz * dz <= radius * radius
end

function Mark.OnLine(x0: number, z0: number, dx: number, dz: number, length: number, half: number, x: number, z: number): boolean
	local px, pz = x - x0, z - z0
	local along = math.clamp(px * dx + pz * dz, 0, length)
	local ex, ez = px - dx * along, pz - dz * along
	return ex * ex + ez * ez <= half * half
end

function Mark.Fanned(x0: number, z0: number, dx: number, dz: number, length: number, half: number, spread: number, x: number, z: number): boolean
	if Mark.OnLine(x0, z0, dx, dz, length, half, x, z) then
		return true
	end
	local c, s = math.cos(spread), math.sin(spread)
	-- the line turned either way: (dx, dz) by +spread and by -spread
	return Mark.OnLine(x0, z0, dx * c - dz * s, dx * s + dz * c, length, half, x, z)
		or Mark.OnLine(x0, z0, dx * c + dz * s, -dx * s + dz * c, length, half, x, z)
end

function Mark.Swept(cx: number, cz: number, a0: number, a1: number, length: number, half: number, x: number, z: number): boolean
	local dx, dz = x - cx, z - cz
	local d = math.sqrt(dx * dx + dz * dz)
	if d > length + half then
		return false
	end
	if d <= half then
		return true -- at its foot
	end
	local widen = math.asin(math.min(1, half / d))
	local lo, hi = math.min(a0, a1) - widen, math.max(a0, a1) + widen
	local rel = (math.atan2(dz, dx) - lo) % (2 * math.pi)
	return rel <= hi - lo
end

function Mark.Covers(shape: Shape, x: number, z: number): boolean
	local length = shape.Length
	if length and shape.Arc and shape.From then
		return Mark.Swept(shape.X, shape.Z, shape.From, shape.From + shape.Arc, length, shape.Radius, x, z)
	end
	if length and shape.DirX and shape.DirZ then
		if shape.Fan then
			return Mark.Fanned(shape.X, shape.Z, shape.DirX, shape.DirZ, length, shape.Radius, shape.Fan, x, z)
		end
		return Mark.OnLine(shape.X, shape.Z, shape.DirX, shape.DirZ, length, shape.Radius, x, z)
	end
	return Mark.Inside(shape.X, shape.Z, shape.Radius, x, z)
end

local function cross(ax: number, az: number, bx: number, bz: number): number
	return ax * bz - az * bx
end

function Mark.Screens(gx: number, gz: number, lookX: number, lookZ: number, wide: number, ahead: number, ax: number, az: number, tx: number, tz: number): boolean
	local size = math.sqrt(lookX * lookX + lookZ * lookZ)
	if size < 1e-6 then
		return false
	end
	local lx, lz = lookX / size, lookZ / size
	local cx, cz = gx + lx * ahead, gz + lz * ahead
	-- the wall runs across the look, along its left (lz, -lx), half its width each way
	local sx, sz = lz * wide / 2, -lx * wide / 2
	local px, pz = cx - sx, cz - sz
	local qx, qz = 2 * sx, 2 * sz
	local rx, rz = tx - ax, tz - az
	local denom = cross(rx, rz, qx, qz)
	if math.abs(denom) < 1e-9 then
		return false -- the blow runs along the wall: it never crosses it
	end
	local wx, wz = px - ax, pz - az
	local t = cross(wx, wz, qx, qz) / denom -- how far along the blow it meets the wall's line
	local u = cross(wx, wz, rx, rz) / denom -- and how far along the wall
	return t >= 0 and t <= 1 and u >= 0 and u <= 1
end

function Mark.Fill(now: number, down: number, slam: number): number
	if slam <= down then
		return 1
	end
	return math.clamp((now - down) / (slam - down), 0, 1)
end

function Mark.Follows(moved: number, outside: boolean, least: number): boolean
	return outside and moved >= least
end

function Mark.Purpose(moved: number, recalled: boolean, least: number): Kind
	return if recalled or moved >= least then "OnPurpose" else "Accident"
end

function Mark.Count(counts: Counts, mode: string, hit: boolean, kind: Kind?)
	local tally = counts[mode]
	if tally == nil then
		tally = { Slams = 0, Hit = 0, Missed = 0, OnPurpose = 0, Accident = 0 }
		counts[mode] = tally
	end
	tally.Slams += 1
	if hit then
		tally.Hit += 1
	else
		tally.Missed += 1
		if kind == "OnPurpose" then
			tally.OnPurpose += 1
		elseif kind == "Accident" then
			tally.Accident += 1
		end
	end
end

function Mark.Ready(last: number?, now: number, cooldown: number): (boolean, number)
	local from = if last then last + cooldown else -math.huge
	return now >= from, from
end

function Mark.Mode(value: any): Mode
	return if value == "A" then "A" elseif value == "B" then "B" else "Off"
end

return Mark
