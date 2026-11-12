--!strict
-- Fight (shared, pure): the decisions a fight makes that need no engine (docs/design.md, "Combat"). The server's
-- FightService measures distances and times, asks here, and does what it's told. Distances are studs, flat, root to root.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Actions = require(Shared.Definitions.Actions)

local Fight = {}

-- The beats of `action` after `from` and by `to` (seconds from its start), earliest first. A beat at 0 needs `from` < 0.
function Fight.BeatsBetween(action: Actions.Action, from: number, to: number): { string }
	local found = {}
	for name, at in action.Beats do
		if at > from and at <= to then
			table.insert(found, name)
		end
	end
	table.sort(found, function(a: string, b: string): boolean
		local ta, tb = action.Beats[a], action.Beats[b]
		return if ta == tb then a < b else ta < tb
	end)
	return found
end

-- The first action of `kit` (in its order) that's off its cooldown at `now`. `readyAt` holds when each may go again.
function Fight.Choose(kit: { Actions.Action }, readyAt: { [string]: number }, now: number): Actions.Action?
	for _, action in kit do
		if now >= (readyAt[action.Id] or -math.huge) then
			return action
		end
	end
	return nil
end

export type Candidate = {
	Id: string,
	Distance: number, -- to the fighter choosing
	Reach: number, -- to what bounds the choice: the lead's avatar, or the Shade itself
	Aggrieved: boolean?, -- a Shade's: this lead hit it or its pack
}

local function nearest(candidates: { Candidate }, allowed: (Candidate) -> boolean): string?
	local best: Candidate? = nil
	for _, candidate in candidates do
		if allowed(candidate) and (best == nil or candidate.Distance < best.Distance or (candidate.Distance == best.Distance and candidate.Id < best.Id)) then
			best = candidate
		end
	end
	return if best then best.Id else nil
end

-- A lead's target: of the enemies within `leash` of its avatar (Reach), the one it has while that stays in, else the
-- nearest to the lead. Nil when none is in: it comes back.
function Fight.LeadTarget(candidates: { Candidate }, current: string?, leash: number): string?
	for _, candidate in candidates do
		if candidate.Id == current and candidate.Reach <= leash then
			return current
		end
	end
	return nearest(candidates, function(candidate: Candidate): boolean
		return candidate.Reach <= leash
	end)
end

-- A Shade's target: the lead it has while that one stands; else the nearest lead that hit it or its pack, wherever it is;
-- else the nearest within `notice`. Nil: it stays home.
function Fight.ShadeTarget(candidates: { Candidate }, current: string?, notice: number): string?
	for _, candidate in candidates do
		if candidate.Id == current then
			return current
		end
	end
	local struck = nearest(candidates, function(candidate: Candidate): boolean
		return candidate.Aggrieved == true
	end)
	return struck or nearest(candidates, function(candidate: Candidate): boolean
		return candidate.Distance <= notice
	end)
end

-- A Shade gives up once it's further than `giveUp` from its spawn, and walks home untouchable.
function Fight.GivesUp(fromHome: number, giveUp: number): boolean
	return fromHome > giveUp
end

export type LeadMode = "Fight" | "Follow" | "Teleport"

-- What a lead does, given how far its avatar is and whether it has a target.
function Fight.LeadMode(toAvatar: number, hasTarget: boolean, lead: { TeleportFrom: number }): LeadMode
	if toAvatar > lead.TeleportFrom then
		return "Teleport"
	end
	return if hasTarget then "Fight" else "Follow"
end

-- How fast a lead walks after its avatar: its walk, or faster once it's far behind.
function Fight.FollowSpeed(toAvatar: number, lead: { WalkSpeed: number, CatchUpSpeed: number, CatchUpFrom: number }): number
	return if toAvatar >= lead.CatchUpFrom then lead.CatchUpSpeed else lead.WalkSpeed
end

-- Whether a hit reaches at its beat: the target within `reach`, and inside `arc` degrees either side of the facing.
-- `cosine` is the cosine between the attacker's facing and the line to the target (1 dead ahead).
function Fight.Reaches(distance: number, cosine: number, reach: number, arc: number): boolean
	if not (distance <= reach) then
		return false
	end
	return distance < 0.5 or cosine >= math.cos(math.rad(arc)) -- touching, any side counts
end

-- Health after `amount` of damage, and whether it fell. Never below 0; a bad amount does nothing.
function Fight.Damage(health: number, amount: number): (number, boolean)
	if not (amount > 0) or amount == math.huge then
		return health, health <= 0
	end
	local left = math.max(0, health - amount)
	return left, left <= 0
end

-- Health after `seconds` out of a fight. `since` is how long since it last hit or was hit; healing starts After that.
function Fight.Heal(health: number, maxHealth: number, since: number, seconds: number, heal: { After: number, PerSecond: number }): number
	if since < heal.After or health <= 0 or not (seconds > 0) then
		return health
	end
	return math.min(maxHealth, health + maxHealth * heal.PerSecond * seconds)
end

-- Health kept as a share of a new maximum (a level, a gear change out of a fight: docs/design.md, "Combat").
function Fight.Rescale(health: number, oldMax: number, newMax: number): number
	if not (oldMax > 0) then
		return newMax
	end
	return math.clamp(health / oldMax, 0, 1) * newMax
end

-- A bearing in degrees, brought into -180..180.
function Fight.Wrap(degrees: number): number
	return (degrees + 180) % 360 - 180
end

-- Where fighters closing on one target stand around it, so a pack never stacks on one spot (fighters don't collide).
-- `angles` are their bearings around the target, in degrees, in a fixed order (by fighter). The answer gives each a
-- bearing at least `spacing` from its neighbours, in the same order around the target and with the same middle: a lone
-- fighter, or ones already apart, stay where they are. Too many to fit share the circle evenly. Bearings in -180..180.
function Fight.Spread(angles: { number }, spacing: number): { number }
	local n = #angles
	local out = table.create(n, 0)
	if n == 0 then
		return out
	end
	local sx, sy = 0, 0
	for _, a in angles do
		sx += math.cos(math.rad(a))
		sy += math.sin(math.rad(a))
	end
	local middle = if sx * sx + sy * sy > 1e-9 then math.deg(math.atan2(sy, sx)) else angles[1]
	local gap = math.min(spacing, 360 / n)
	local order = table.create(n, 0)
	local relative = table.create(n, 0)
	for i, a in angles do
		order[i] = i
		relative[i] = Fight.Wrap(a - middle)
	end
	table.sort(order, function(a: number, b: number): boolean
		if relative[a] ~= relative[b] then
			return relative[a] < relative[b]
		end
		return a < b
	end)
	local placed = table.create(n, 0)
	for k, i in order do
		placed[k] = if k == 1 then relative[i] else math.max(relative[i], placed[k - 1] + gap)
	end
	if placed[n] - placed[1] > 360 - gap then
		for k = 2, n do
			placed[k] = placed[1] + (k - 1) * 360 / n -- a full circle: evenly
		end
	end
	local before, after = 0, 0
	for k, i in order do
		before += relative[i]
		after += placed[k]
	end
	local shift = (before - after) / n -- back to the same middle
	for k, i in order do
		out[i] = Fight.Wrap(middle + placed[k] + shift)
	end
	return out
end

return Fight
