--!strict
-- Flight (pure rules): a won thing's way from where its enemy fell to the player (TR24's fix 8: "a drop falls in the world
-- with its name and flies to the player", the same flight as the package's chests, the director's "Automatic nearby chest
-- collection", 2026-11-16). Four beats:
--   Pop     it springs up out of the fall and comes down on the floor, a step toward the player: up fast, down by gravity
--   Bounce  one small hop where it lands, so it reads as having weight
--   Rest    it sits on the floor a beat, for its name to be read
--   Pull    it's pulled to the player, slow off the floor and fast into them (an ease-in: the acceleration is the snap)
-- The player's place is read again each frame, so it follows a walking player. No Roblox API but Vector3: it runs with
-- Studio closed. Numbers: Config.Effects.Drop.

local Flight = {}

export type Look = {
	Pop: { Seconds: number, Height: number, Out: number },
	Bounce: { Seconds: number, Height: number },
	Rest: number,
	Pull: { Seconds: number, Lift: number },
	Hover: number, -- studs from the floor to the thing's middle, at rest
}

export type Beat = "Pop" | "Bounce" | "Rest" | "Pull" | "Done"

-- Its whole time, in seconds.
function Flight.Length(look: Look): number
	return look.Pop.Seconds + look.Bounce.Seconds + look.Rest + look.Pull.Seconds
end

-- Where it lands: `out` studs from the fall toward the player across the floor (straight up if they're on it), at
-- `floor` plus its hover.
function Flight.Landing(from: Vector3, floor: number, to: Vector3, look: Look): Vector3
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local step = if flat.Magnitude > 1e-3 then flat.Unit * math.min(look.Pop.Out, flat.Magnitude) else Vector3.zero
	return Vector3.new(from.X + step.X, floor + look.Hover, from.Z + step.Z)
end

-- At `age` seconds: where it is, its beat, and how far through that beat (0 to 1). `from` is where its enemy fell, `floor`
-- the floor's height there, `to` the player's place now.
function Flight.At(age: number, from: Vector3, floor: number, to: Vector3, look: Look): (Vector3, Beat, number)
	local land = Flight.Landing(from, floor, to, look)
	local pop, bounce, pull = look.Pop, look.Bounce, look.Pull
	local t = math.max(age, 0)
	if t < pop.Seconds then
		-- up and over, as thrown: its height a parabola from the fall's height to the landing's, peaking Height over the
		-- higher of the two
		local u = t / pop.Seconds
		local flat = from:Lerp(land, u)
		local top = math.max(from.Y, land.Y) + pop.Height
		-- the parabola through (0, from.Y), (1, land.Y) whose highest point is `top`
		local a, b = from.Y - top, land.Y - top
		local root = math.sqrt(math.max(a * b, 0)) -- the peak's place along u: 1 / (1 + sqrt(b / a))
		local peak = if a < 0 then -a / (-a + root) else 0.5
		local y = if u <= peak
			then top + (from.Y - top) * ((peak - u) / peak) ^ 2
			else top + (land.Y - top) * ((u - peak) / (1 - peak)) ^ 2
		return Vector3.new(flat.X, y, flat.Z), "Pop", u
	end
	t -= pop.Seconds
	if t < bounce.Seconds then
		local u = t / bounce.Seconds
		return land + Vector3.new(0, bounce.Height * 4 * u * (1 - u), 0), "Bounce", u
	end
	t -= bounce.Seconds
	if t < look.Rest then
		return land, "Rest", t / math.max(look.Rest, 1e-3)
	end
	t -= look.Rest
	if t < pull.Seconds then
		local u = t / pull.Seconds
		local eased = u * u * u -- slow off the floor, fast into the player
		return land:Lerp(to, eased) + Vector3.new(0, pull.Lift * 4 * u * (1 - u), 0), "Pull", u
	end
	return to, "Done", 1
end

return Flight
