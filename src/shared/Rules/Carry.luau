--!strict
-- Carry (shared, pure): the health a Voidkin carries between fights (docs/design.md, "Combat", "Health carries" to "The
-- next lead"; TR12). The lead's own health lives on its fighter. One that isn't out keeps the share it had when it was
-- taken in and heals at home from then: Combat.Lead.Home.Full seconds from nothing to full, or Home.Fallen once it fell.
-- A fallen one can't be sent out again until it's whole, and the lead never changes in a fight.
--   Carry.Mend(share, seconds, full)            a share after `seconds` at home
--   Carry.Share(entry, now, home)               what a Voidkin carries now (whole when there's no entry)
--   Carry.WholeAt(entry, home)                  when it's whole again
--   Carry.Refusal(inCombat, entry, now, home)   why it can't be sent out now, or nil
--   Carry.Fallen(state, since, playerHome, leave, whole)   the fallen lead's next state

export type Entry = {
	Share: number, -- of its most health, when it was taken in
	At: number, -- server time it was taken in
	Fallen: boolean, -- it fell: it heals at the fallen rate, and can't be sent out until whole
}
export type Home = { Full: number, Fallen: number }

local Carry = {}

Carry.InCombat = "InCombat" -- the lead can't change in a fight
Carry.Healing = "Healing" -- a fallen Voidkin is still healing at home

-- `share` after `seconds` at home, from nothing to full in `full` seconds. Never past 1 or under 0; a bad time does
-- nothing.
function Carry.Mend(share: number, seconds: number, full: number): number
	local from = if share == share then math.clamp(share, 0, 1) else 0
	if not (seconds > 0) or seconds == math.huge then
		return from
	end
	if not (full > 0) then
		return 1
	end
	return math.min(1, from + seconds / full)
end

-- What a Voidkin carries at `now`: whole when it has no entry (it hasn't fought since it was last whole).
function Carry.Share(entry: Entry?, now: number, home: Home): number
	if entry == nil then
		return 1
	end
	return Carry.Mend(entry.Share, now - entry.At, if entry.Fallen then home.Fallen else home.Full)
end

-- The server time an entry is whole again.
function Carry.WholeAt(entry: Entry, home: Home): number
	local full = if entry.Fallen then home.Fallen else home.Full
	local share = if entry.Share == entry.Share then math.clamp(entry.Share, 0, 1) else 0
	return entry.At + (1 - share) * math.max(full, 0)
end

-- Why `entry`'s Voidkin can't be sent out as the lead now, or nil when it can: never in a fight (a keeper's try is one);
-- never a fallen one still healing. One that's hurt but never fell may go out as it is.
function Carry.Refusal(inCombat: boolean, entry: Entry?, now: number, home: Home): string?
	if inCombat then
		return Carry.InCombat
	end
	if entry and entry.Fallen and Carry.Share(entry, now, home) < 1 then
		return Carry.Healing
	end
	return nil
end

-- The fallen lead's next state (docs/design.md, "A fall sends it home"): "Down" for `leave` seconds from its fall, so the
-- fall is seen; then "Home", on its plot, healing to full and then waiting; once it's whole and its player stands on their
-- plot, "Idle": it follows again (never out half healed: a fallen one goes out only whole). Any other state is its own.
function Carry.Fallen(state: string, since: number, playerHome: boolean, leave: number, whole: boolean): string
	if state == "Down" then
		return if since >= leave then "Home" else "Down"
	elseif state == "Home" then
		return if playerHome and whole then "Idle" else "Home"
	end
	return state
end

return Carry
