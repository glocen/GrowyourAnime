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

-- Where a screen's clock of `action` moves to when the server's hit on `beat` reaches it at `clock`: the beat's time when
-- the clock hasn't reached it yet (a hold the server doesn't keep left the clip behind), so the hit's hold lands on its
-- contact frame; nil when it's there or past it, or `beat` isn't one of the action's (AR4, section 8: research, 2026-11-12).
function Fight.CatchTo(action: Actions.Action, beat: string, clock: number): number?
	local at = action.Beats[beat]
	if at == nil or at <= clock or at > action.Length then
		return nil
	end
	return at
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
	Off: number?, -- a lead's: degrees between the camera's look and the enemy, seen from the avatar (0 to 180)
	Engaged: boolean?, -- a lead's: this enemy is on the lead
	Fighting: boolean?, -- a Shade's: this lead has a target of its own (TR24's fix 6)
}

export type View = { Arc: number, Guard: number }

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
-- With a `view` (TR24's fix 2: the fight in the camera's view), a new target is, in turn, the nearest already on the
-- lead (Engaged), the nearest in view (Off within view.Arc), or the nearest within view.Guard of the avatar; one out of
-- view and not on the lead is left for the player to look at. A candidate with no Off counts as in view.
function Fight.LeadTarget(candidates: { Candidate }, current: string?, leash: number, view: View?): string?
	for _, candidate in candidates do
		if candidate.Id == current and candidate.Reach <= leash then
			return current
		end
	end
	if view == nil then
		return nearest(candidates, function(candidate: Candidate): boolean
			return candidate.Reach <= leash
		end)
	end
	return nearest(candidates, function(candidate: Candidate): boolean
		return candidate.Reach <= leash and candidate.Engaged == true
	end) or nearest(candidates, function(candidate: Candidate): boolean
		return candidate.Reach <= leash and (candidate.Off or 0) <= view.Arc
	end) or nearest(candidates, function(candidate: Candidate): boolean
		return candidate.Reach <= math.min(leash, view.Guard)
	end)
end

-- Degrees between two flat bearings, 0 to 180.
function Fight.Off(a: number, b: number): number
	return math.abs(Fight.Wrap(a - b))
end

-- Whether a lead `radius` studs wide stands in the camera's line to the avatar, or too near the camera (TR24's fix 3):
-- `along` studs from the camera along the line to the avatar, `across` studs off it, the avatar `length` along. In the
-- line: between the camera and the avatar, within radius + margin of it. Too near: its middle within `near` + radius of
-- the camera, wherever.
function Fight.InLine(along: number, across: number, length: number, radius: number, margin: number, near: number): boolean
	if along * along + across * across <= (near + radius) ^ 2 then
		return true
	end
	return along > 0 and along < length and across <= radius + margin
end

-- A Shade's target: the lead it has while that one stands; else the nearest lead that hit it or its pack, wherever it is;
-- else the nearest within `notice`, and with `idle` false only one that's fighting already (TR24's fix 6: a player who
-- stands isn't pulled into a new pack; their lead's own choice starts a fight). Nil: it stays home. A lead further than
-- `lose` is let go and never picked, even one that hit its pack: one gone home through a door, while the Shade stands
-- pinned at a wall short of its give-up (nil: never let go, as a keeper's).
function Fight.ShadeTarget(candidates: { Candidate }, current: string?, notice: number, lose: number?, idle: boolean?): string?
	local near = candidates
	if lose then
		near = {}
		for _, candidate in candidates do
			if candidate.Distance <= lose then
				table.insert(near, candidate)
			end
		end
	end
	for _, candidate in near do
		if candidate.Id == current then
			return current
		end
	end
	local struck = nearest(near, function(candidate: Candidate): boolean
		return candidate.Aggrieved == true
	end)
	return struck or nearest(near, function(candidate: Candidate): boolean
		return candidate.Distance <= notice and (idle ~= false or candidate.Fighting == true)
	end)
end

-- A Shade gives up once it's further than `giveUp` from its spawn, and walks home untouchable.
function Fight.GivesUp(fromHome: number, giveUp: number): boolean
	return fromHome > giveUp
end

-- A Shade walking home: whether it's stuck. `closest` is the nearest it has come and `since` when it got there; it's
-- stuck once it has come no `gain` nearer for `seconds`. Returns them updated, and whether it's stuck.
function Fight.ResetStuck(closest: number, since: number, fromHome: number, now: number, gain: number, seconds: number): (number, number, boolean)
	if fromHome < closest - gain then
		return fromHome, now, false
	end
	return closest, since, now - since > seconds
end

export type LeadMode = "Fight" | "Follow" | "Teleport"

-- What a lead does, given how far its avatar is and whether it has a target.
function Fight.LeadMode(toAvatar: number, hasTarget: boolean, lead: { TeleportFrom: number }): LeadMode
	if toAvatar > lead.TeleportFrom then
		return "Teleport"
	end
	return if hasTarget then "Fight" else "Follow"
end

-- How fast a lead walks: `walk` (its Speed in a fight; Config.Combat.Lead.FollowWalk after its avatar), or the catch-up
-- once it's far behind its avatar, never slower than its walk, so every lead keeps up with a running avatar (TR14).
function Fight.LeadSpeed(toAvatar: number, walk: number, lead: { CatchUpSpeed: number, CatchUpFrom: number }): number
	return if toAvatar >= lead.CatchUpFrom then math.max(walk, lead.CatchUpSpeed) else walk
end

-- Whether a hit reaches at its beat: the target within `reach`, and inside `arc` degrees either side of the facing.
-- `cosine` is the cosine between the attacker's facing and the line to the target (1 dead ahead).
function Fight.Reaches(distance: number, cosine: number, reach: number, arc: number): boolean
	if not (distance <= reach) then
		return false
	end
	return distance < 0.5 or cosine >= math.cos(math.rad(arc)) -- touching, any side counts
end

-- Whether a body `along` studs down a cone's line from the fighter and `across` studs off it stands in the cone
-- (Actions.Hit.Cone): within `reach` of the fighter, and within `cone` degrees of the line seen from the cone's point,
-- `apex` studs behind the fighter (Lyric's: where her speakers' lines meet, AR4, section 9). Never behind the fighter.
function Fight.InCone(along: number, across: number, reach: number, cone: number, apex: number): boolean
	if not (along >= 0) or not (math.sqrt(along * along + across * across) <= reach) then
		return false
	end
	local ahead = along + apex
	return ahead > 0 and math.deg(math.atan2(math.abs(across), ahead)) <= cone
end

-- Health after `amount` of damage, and whether it fell. Never below 0; a bad amount does nothing.
function Fight.Damage(health: number, amount: number): (number, boolean)
	if not (amount > 0) or amount == math.huge then
		return health, health <= 0
	end
	local left = math.max(0, health - amount)
	return left, left <= 0
end

-- Health after `seconds` of healing at `perSecond`: its Regen, always, in a fight too, and on its own plot what heals it
-- to full in Combat.Lead.Home.Full seconds (docs/design.md, "Health carries"). Never past the most; a body that's down
-- stays down; a bad rate or time does nothing.
function Fight.Regen(health: number, maxHealth: number, perSecond: number, seconds: number): number
	if health <= 0 or not (perSecond > 0) or perSecond == math.huge or not (seconds > 0) or seconds == math.huge then
		return health
	end
	return math.min(maxHealth, health + perSecond * seconds)
end

-- What a lead heals a second: its Regen, and on its own plot (`home`) what takes it from nothing to full in `full`
-- seconds besides.
function Fight.RegenRate(regen: number, maxHealth: number, home: boolean, full: number): number
	return math.max(0, regen) + (if home and full > 0 then maxHealth / full else 0)
end

-- Health after a hit's heal of `share` of the most (Actions.Hit.Heal): never past the most, and a body that's down
-- stays down. A bad share does nothing.
function Fight.Mend(health: number, maxHealth: number, share: number): number
	if health <= 0 or not (share > 0) or share == math.huge then
		return health
	end
	return math.min(maxHealth, health + maxHealth * share)
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

-- Where a lead wants to stand around its target, as a bearing around it: on the target's far side from where the player
-- watches, so the player's camera frames the fight, never with the lead between the two (research's verdict on TR2,
-- 2026-11-12). Turned `frame` degrees toward the side the lead already stands on, so the target doesn't hide it.
-- `avatar` is the bearing the player watches from (FightService: the avatar's back), `current` the lead's.
function Fight.Beyond(avatar: number, current: number, frame: number): number
	local beyond = Fight.Wrap(avatar + 180)
	local side = if Fight.Wrap(current - beyond) < 0 then -1 else 1
	return Fight.Wrap(beyond + side * frame)
end

-- Where a fighter stands round a target wider than itself, which the player sees `lean` degrees off the avatar's facing:
-- `frame` degrees round from beyond it, on the side away from the avatar's line of sight, so neither the avatar's own body
-- nor the target hides it; `near`, on the side toward it instead, so a lead coming from that side never crosses the line.
-- Seen within `straight` degrees of straight ahead, it keeps the side it's nearer, as Beyond does.
function Fight.Aside(avatar: number, lean: number, current: number, frame: number, straight: number, near: boolean?): number
	if math.abs(lean) < straight then
		return Fight.Beyond(avatar, current, frame)
	end
	local away = if lean < 0 then -1 else 1
	return Fight.Wrap(avatar + 180 + (if near then -away else away) * frame)
end

-- A Shade's most health with `leads` leads on it: from crowd.From on, each further lead adds crowd.Share of its health
-- `alone`, so a duo fights it as one would and eight don't sweep at three times the pace (research's verdict on TR2,
-- 2026-11-12).
function Fight.CrowdHealth(alone: number, leads: number, crowd: { From: number, Share: number }): number
	return alone * (1 + crowd.Share * math.max(0, leads - crowd.From + 1))
end

-- The bearing a fighter heads for next on its way round a target to `want`: at most `step` degrees from where it stands,
-- so it walks round the target rather than through it (fighters don't collide).
function Fight.Toward(current: number, want: number, step: number): number
	return Fight.Wrap(current + math.clamp(Fight.Wrap(want - current), -step, step))
end

-- Where a pack's `count` Shades stand round its spawn: on one circle, each `spacing` from its neighbours, the first straight
-- ahead (-Z, the spawn's look). Offsets { X, Z } in studs, in the spawn's own frame. One Shade stands on the spawn.
function Fight.PackRing(count: number, spacing: number): { { number } }
	local n = math.max(1, math.floor(count))
	if n == 1 then
		return { { 0, 0 } }
	end
	local radius = spacing / (2 * math.sin(math.pi / n))
	local out: { { number } } = {}
	for k = 1, n do
		local angle = (k - 1) * 2 * math.pi / n
		table.insert(out, { radius * math.sin(angle), -radius * math.cos(angle) })
	end
	return out
end

-- How long a hit's Stun (`seconds`) stops a fighter of a kind stopped `share` of it, at `at`: none while it's still locked
-- from its last (`locked`, the time its lock ends), else the share of it. The lock starts where this one ends.
function Fight.Stun(seconds: number?, share: number?, at: number, locked: number): number
	if seconds == nil or not (seconds > 0) or at < locked then
		return 0
	end
	return seconds * math.clamp(share or 1, 0, 1)
end

-- The share less damage a fighter's shield takes off a hit at `at` (Actions.Hit.Shield): its Share until it lapses.
function Fight.Shield(shield: { Share: number, Until: number }?, at: number): number
	if shield == nil or at >= shield.Until or not (shield.Share > 0) then
		return 0
	end
	return math.min(shield.Share, 1)
end

-- Whether a fighter `distance` studs (flat) from a hit's target stands in the hit's Area, the target's own studs round it.
function Fight.Within(distance: number, area: number): boolean
	return area > 0 and distance <= area
end

-- The push a client draws ahead of the server's (FighterController; AR1, section 8): `t` seconds after the hold ended,
-- a body pushed `studs` whose replica has brought `shown` of it is drawn this much further on, never back. The server's
-- push runs over push.Seconds; what the replica still hasn't brought by push.Wait after it is let go over push.HandBack.
-- nil once it's over: handed back, or let go.
function Fight.KnockAhead(studs: number, t: number, shown: number, push: { Seconds: number, Wait: number, HandBack: number }): number?
	if t < 0 then
		return 0 -- the hold
	end
	if t > push.Seconds + push.Wait + push.HandBack then
		return nil
	end
	local done = math.max(studs, 0) * (if push.Seconds > 0 then math.clamp(t / push.Seconds, 0, 1) else 1)
	local ahead = math.clamp(done - shown, 0, done)
	local late = t - push.Seconds - push.Wait -- a wall, a lighter push: the replica never brings it all
	if late > 0 then
		ahead *= 1 - (if push.HandBack > 0 then math.clamp(late / push.HandBack, 0, 1) else 1)
	end
	if t >= push.Seconds and ahead < 0.01 then
		return nil
	end
	return ahead
end

export type Lever = { From: number, Hold: number, Flash: number, Glow: number, Tremble: number, Trauma: number }
export type Hitstop = { Rungs: { Lever }, Critical: number, Kill: number, KillRung: number }

-- A hit's rung on the importance ladder (Actions.Hit.Rung; docs/research/vfx-reference.md, rule 1): its own, 2 when it
-- names none, and at least the critical's when it's critical.
function Fight.Rung(rung: number?, critical: boolean, hitstop: Hitstop, killing: boolean?): number
	local own = rung or 2
	own = if critical then math.max(own, hitstop.Critical) else own
	-- a killing hit lands at least at KillRung's levers, its flash and its camera (TR24's fix 11)
	return if killing then math.max(own, hitstop.KillRung) else own
end

export type Throw = { Studs: number, Seconds: number }

-- A hit's push, in studs before its body's weight, and the seconds it takes: its beat's over the push's Seconds; a killing
-- hit's at least Kill's studs over Kill's own seconds, so the blow throws the body back as it falls and its burst lands
-- where the body does (TR24's fix 11; handbook/feel/combat.md: "let the blow's push carry the fall").
function Fight.Throw(studs: number, killing: boolean, push: { Seconds: number, Kill: Throw? }): (number, number)
	local kill = push.Kill
	if killing and kill then
		return math.max(studs, kill.Studs), kill.Seconds
	end
	return studs, push.Seconds
end

-- The hit's levers for a rung (Config.Combat.Hitstop.Rungs): the highest row at or under it, or the lowest row.
function Fight.Lever(rung: number, hitstop: Hitstop): Lever
	local chosen = hitstop.Rungs[1]
	for _, row in hitstop.Rungs do
		if row.From <= rung and row.From >= chosen.From then
			chosen = row
		end
	end
	return chosen
end

-- Seconds both bodies hold on a hit of `rung`: its row's, and at least the killing hit's own when it fells.
function Fight.Hold(rung: number, killing: boolean, hitstop: Hitstop): number
	local hold = Fight.Lever(rung, hitstop).Hold
	return if killing then math.max(hold, hitstop.Kill) else hold
end

-- The longest hold any hit can have: what waits on a hold (the Shade's burst on a held clip) waits this out.
function Fight.LongestHold(hitstop: Hitstop): number
	local most = hitstop.Kill
	for _, row in hitstop.Rungs do
		most = math.max(most, row.Hold)
	end
	return most
end

-- The struck body's flash `t` seconds in, as the fill's opacity: `glow` at once, eased out (quadratic) to 0 at `seconds`,
-- so its top value lasts a picture or two and it never fades linearly (docs/research/vfx-reference.md, rule 3).
function Fight.Flash(t: number, seconds: number, glow: number): number
	if t < 0 or t >= seconds or seconds <= 0 then
		return 0
	end
	local left = 1 - t / seconds
	return glow * left * left
end

-- How far the struck body trembles `t` seconds into a hold of `hold` seconds: `studs`, shrinking linearly to nothing at
-- the hold's end (docs/research/vfx-reference.md, item 10). The side it goes is the caller's noise.
function Fight.Tremble(t: number, hold: number, studs: number): number
	if t < 0 or t >= hold or hold <= 0 then
		return 0
	end
	return studs * (1 - t / hold)
end

-- The camera's trauma (Config.Combat.Shake): `add` on `trauma`, capped at 1; after `dt` seconds it falls by dt / decay.
-- The shake is its square, so a big jolt lands and a small one barely ticks (Eiserloh, GDC 2016).
function Fight.Trauma(trauma: number, add: number): number
	return math.clamp(trauma + math.max(add, 0), 0, 1)
end

function Fight.TraumaAfter(trauma: number, dt: number, decay: number): number
	return if decay > 0 then math.max(0, trauma - dt / decay) else 0
end

function Fight.ShakeOf(trauma: number): number
	return trauma * trauma
end

-- The skip back (docs/design.md, "Combat"; Config.Combat.Skip). A ranged lead between actions skips when the nearest enemy
-- is inside Close studs and its last skip was at least Every seconds ago (`since`), never while an enemy's swing at it is
-- winding up: a skip never dodges a hit already coming.
function Fight.ShouldSkip(nearest: number, since: number, windingUp: boolean, skip: { Close: number, Every: number }): boolean
	return nearest < skip.Close and since >= skip.Every and not windingUp
end

-- The bearings round its target a skip tries, in order: its place in the frame first, then Step degrees either side at a
-- time, the side it already stands on first at each step, to straight across. Degrees, wrapped as Fight.Wrap.
function Fight.SkipBearings(place: number, step: number, here: number): { number }
	local out = { Fight.Wrap(place) }
	local first = if Fight.Wrap(here - place) >= 0 then 1 else -1
	local k = 1
	while k * step < 180 - 1e-6 do
		table.insert(out, Fight.Wrap(place + first * k * step))
		table.insert(out, Fight.Wrap(place - first * k * step))
		k += 1
	end
	if math.abs(k * step - 180) < 1e-6 then
		table.insert(out, Fight.Wrap(place + 180))
	end
	return out
end

-- Whether a skip's way, flat, from `from` to `to`, keeps clear of an enemy at `enemy`: never nearer it than `body`, or,
-- when it starts nearer than that, never nearer than where it starts (straight away from it).
function Fight.SkipKeepsClear(from: Vector3, to: Vector3, enemy: Vector3, body: number): boolean
	local a = Vector3.new(from.X, 0, from.Z)
	local b = Vector3.new(to.X, 0, to.Z)
	local e = Vector3.new(enemy.X, 0, enemy.Z)
	local line = b - a
	local length = line.Magnitude
	local closest = if length < 1e-6 then (e - a).Magnitude else (e - (a + line * math.clamp((e - a):Dot(line) / (length * length), 0, 1))).Magnitude
	return closest >= math.min(body, (e - a).Magnitude) - 1e-6
end

-- Where a move carries its fighter (Definitions.Actions, Move: an Assassin's dash in, Kirra's blink), flat, at `from`'s
-- height: along its line to `target`, turned Turn degrees at its spot toward the side of that line `avatar` stands on, to
-- Gap studs short of the target's point on that path (past it when Gap is negative), never back, and at most Most studs.
-- Returns where it ends and the path's way (a flat unit; zero with its target where it stands). An avatar on the line
-- turns it to the right of the fighter's line.
function Fight.MoveEnd(from: Vector3, target: Vector3, avatar: Vector3, move: { Gap: number, Most: number?, Turn: number? }): (Vector3, Vector3)
	local line = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
	local gap = line.Magnitude
	if gap < 1e-3 then
		return from, Vector3.zero
	end
	local unit = line / gap
	local toAvatar = Vector3.new(avatar.X - from.X, 0, avatar.Z - from.Z)
	-- which side of the line the avatar stands: + is a positive turn below, the way from `unit` toward (-z, x)
	local side = if unit.X * toAvatar.Z - unit.Z * toAvatar.X < 0 then -1 else 1
	local turn = math.rad((move.Turn or 0) * side)
	local c, s = math.cos(turn), math.sin(turn)
	local way = Vector3.new(unit.X * c - unit.Z * s, 0, unit.X * s + unit.Z * c)
	local studs = math.max(0, gap * c - move.Gap) -- the target's point on the path is gap * cos(turn) along it
	if move.Most then
		studs = math.min(studs, move.Most)
	end
	return from + way * studs, way
end

return Fight
