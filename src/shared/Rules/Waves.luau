--!strict
-- Waves (pure): a pack stop's Shades, in waves (TR69 B; each Pack stop's Waves in Config.World.Row.Stops, the timing in
-- Config.World.Row.Waves). The next wave steps out of the stall fronts Gap seconds after its stop's last Shade falls, a
-- Tell before it; a list run out starts again from its second wave, only while someone near still owes the quota.
--   Waves.Of(stop)                 its list; a stop without one stands one wave of its ring, as before the waves
--   Waves.Size(wave)               the Shades in a wave
--   Waves.Pass(list)               the Shades in one pass of its list
--   Waves.After(list, index, owed) the next wave's index, or nil: nobody near owes, the stop rests
--   Waves.Defs(stop)               every Def its waves stand, each one the quota counts
--   Waves.Spots(wave, spacing, side, far, behind)  each Shade's Def and place on the marker (X across, Z along, its back
--                                  to the street's way on at Z > 0), its Turn (radians about Y: pi, its back turned)
--                                  and its Type, when its group has its own
-- The marker looks down the street toward the way in (-Z): Front rows stand nearer the player, Back and Rear farther.

local Shared = game:GetService("ReplicatedStorage").Shared
local Fight = require(Shared.Rules.Fight)

local Waves = {}

-- One group of a wave: Count Shades of Def, from where (nil: the ring round the marker; "Left" or "Right": that stall
-- front; "Sides": both, half each; "Far": up the street; "Alleys": out of both sides ahead, their lines crossing), in which
-- row (nil: the ring; "Front"; "Back"), turned (Back: its back to the way in), and of its own Type over the stop's.
export type Group = {
	Def: string,
	Count: number,
	From: string?,
	Row: string?,
	Back: boolean?,
	Type: string?,
	Rear: boolean?, -- a row at the back past everything, a Support's
}
export type Wave = { Group }
export type Spot = { Def: string, X: number, Z: number, Turn: number, Type: string? }

function Waves.Of(stop: any): { Wave }
	if type(stop.Waves) == "table" and #stop.Waves > 0 then
		return stop.Waves
	end
	local wave: Wave = { { Def = stop.Def, Count = stop.Count or 1 } }
	if stop.With then
		wave[1].Count -= stop.With.Count
		table.insert(wave, { Def = stop.With.Def, Count = stop.With.Count })
	end
	if stop.Rear then
		table.insert(wave, { Def = stop.Rear.Def, Count = stop.Rear.Count, Rear = true })
	end
	return { wave }
end

function Waves.Size(wave: Wave): number
	local n = 0
	for _, group in wave do
		n += math.max(0, math.floor(group.Count))
	end
	return n
end

function Waves.Pass(list: { Wave }): number
	local n = 0
	for _, wave in list do
		n += Waves.Size(wave)
	end
	return n
end

function Waves.After(list: { Wave }, index: number, owed: boolean): number?
	if not owed or #list == 0 then
		return nil
	elseif index < #list then
		return index + 1
	end
	return math.min(2, #list)
end

function Waves.Defs(stop: any): { [string]: boolean }
	local defs: { [string]: boolean } = {}
	for _, wave in Waves.Of(stop) do
		for _, group in wave do
			defs[group.Def] = true
		end
	end
	return defs
end

-- A line of n along X, centred, `spacing` apart.
local function across(n: number, spacing: number, k: number): number
	return (k - (n + 1) / 2) * spacing
end

function Waves.Spots(wave: Wave, spacing: number, side: number, far: number, behind: number): { Spot }
	local spots: { Spot } = {}
	local function add(group: Group, x: number, z: number)
		table.insert(spots, { Def = group.Def, X = x, Z = z, Turn = if group.Back then math.pi else 0, Type = group.Type })
	end
	-- the ring's groups share one ring, as a pack's did (Rules.Fight.PackRing)
	local ringed: { Group } = {}
	local ringCount = 0
	for _, group in wave do
		if group.From == nil and group.Row == nil and not group.Rear then
			table.insert(ringed, group)
			ringCount += math.max(0, math.floor(group.Count))
		end
	end
	local deepest = 0
	if ringCount > 0 then
		local ring = Fight.PackRing(ringCount, spacing)
		local k = 0
		for _, group in ringed do
			for _ = 1, math.max(0, math.floor(group.Count)) do
				k += 1
				add(group, ring[k][1], ring[k][2])
				deepest = math.max(deepest, ring[k][2])
			end
		end
	end
	for _, group in wave do
		local n = math.max(0, math.floor(group.Count))
		if group.From == "Left" or group.From == "Right" then
			local x = if group.From == "Left" then -side else side
			for k = 1, n do
				add(group, x, across(n, spacing, k))
			end
		elseif group.From == "Sides" then
			for k = 1, n do
				local left = k % 2 == 1
				add(group, if left then -side else side, across(math.ceil(n / 2), spacing, math.ceil(k / 2)))
			end
		elseif group.From == "Alleys" then
			for k = 1, n do
				local left = k % 2 == 1
				-- out of both sides ahead, staggered so their lines on the player cross
				add(group, if left then -side else side, far / 2 + (if left then 0 else spacing))
			end
		elseif group.From == "Far" then
			for k = 1, n do
				add(group, across(n, spacing, k), far)
			end
		elseif group.Row == "Front" then
			for k = 1, n do
				add(group, across(n, spacing, k), -spacing / 2)
			end
		elseif group.Row == "Back" then
			for k = 1, n do
				add(group, across(n, spacing, k), spacing)
				deepest = math.max(deepest, spacing)
			end
		end
	end
	for _, group in wave do
		if group.Rear then
			local n = math.max(0, math.floor(group.Count))
			for k = 1, n do
				add(group, across(n, spacing, k), deepest + behind)
			end
		end
	end
	return spots
end

return Waves
