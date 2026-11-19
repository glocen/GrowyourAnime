--!strict
-- Mark (pure): a marked strike's footprint, and the lead's ways out of it (docs/test-requests.md, TR44;
-- Config.Combat.Keeper.Mark and Out). FightService puts the footprint down and resolves its hit; SlamService moves the
-- lead out and counts the slams. No Roblox API: its cases run with Studio closed. Flat positions are (x, z) pairs.
--   Mark.Centre(x, z, lookX, lookZ, ahead, left) -> (x, z)   where it lands: `ahead` along the look, `left` to its left
--   Mark.Inside(cx, cz, radius, x, z) -> boolean             a centre within the radius: the hit takes it
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
