--!strict
-- Keeper (pure): the Lamplighter in three phases (TR69 D; docs/research/cloud-2026-11-24/grounds-and-encounters.md,
-- section C; the seeds in Config.Combat.Keeper.Phases). Its health share decides its phase; a hit never carries it past a
-- phase's line before that phase's turn has played; its posts stand round the ring's middle; its sweep turns a line
-- (what the line passed over is Rules.Mark.Swept's).
--   Keeper.Phase(share, from)           1 above from[1], 2 above from[2], ... the last below them all
--   Keeper.Floor(phase, most, from)     the least health `phase` may be taken to: its line's share of `most` (0 in the last)
--   Keeper.Clamp(left, floor)           health after a hit, held at the floor: (left, held)
--   Keeper.Posts(cx, cz, lookX, lookZ, radius, count)  each post's { X, Z }, the first along the look, round the ring
--   Keeper.Rounds(count, per)           the posts lit at each step of a round, `per` at a time, spread evenly round it
--   Keeper.Sweep(t, seconds, arc, back) the line's turn (radians) t seconds into its sweep; nil outside it
--   Keeper.Rate(span, tell)             the rate its signature runs at for its tell (Plant to Slam, `span` at rate 1) to
--                                       last `tell`: 1 when the tell is already that short or shorter
--   Keeper.Second(slam, after, tell)    the double slam's second footprint: (down, slam), Tell long, After the first's Slam

local Keeper = {}

local TAU = 2 * math.pi

function Keeper.Phase(share: number, from: { number }): number
	for index, line in from do
		if share > line then
			return index
		end
	end
	return #from + 1
end

function Keeper.Floor(phase: number, most: number, from: { number }): number
	local line = from[phase]
	return if line then line * most else 0
end

function Keeper.Clamp(left: number, floor: number?): (number, boolean)
	if floor and floor > 0 and left < floor then
		return floor, true
	end
	return left, false
end

function Keeper.Posts(cx: number, cz: number, lookX: number, lookZ: number, radius: number, count: number): { { X: number, Z: number } }
	local base = if lookX * lookX + lookZ * lookZ > 1e-9 then math.atan2(lookZ, lookX) else 0
	local posts = {}
	for index = 0, count - 1 do
		local a = base + index * TAU / count
		table.insert(posts, { X = cx + math.cos(a) * radius, Z = cz + math.sin(a) * radius })
	end
	return posts
end

function Keeper.Rounds(count: number, per: number): { { number } }
	per = math.clamp(math.floor(per), 1, math.max(1, count))
	local steps = math.ceil(count / per)
	local rounds = {}
	for step = 1, steps do
		local lit = {}
		for j = 0, per - 1 do
			local index = step + j * steps
			if index <= count then
				table.insert(lit, index)
			end
		end
		table.insert(rounds, lit)
	end
	return rounds
end

function Keeper.Sweep(t: number, seconds: number, arc: number, back: boolean): number?
	if t < 0 or seconds <= 0 then
		return nil
	end
	if t <= seconds then
		return arc * t / seconds
	end
	if back and t <= 2 * seconds then
		return arc * (2 - t / seconds)
	end
	return nil
end

function Keeper.Rate(span: number, tell: number): number
	if tell <= 0 or span <= tell then
		return 1
	end
	return span / tell
end

function Keeper.Second(slam: number, after: number, tell: number): (number, number)
	local second = slam + after
	return second - tell, second
end

return Keeper
