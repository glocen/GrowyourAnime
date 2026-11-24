--!strict
-- Support (pure): AR58's Support Shade, who its cast is for and where it stands between casts (docs/asset-requests.md,
-- AR58; Config.Combat.Support, the builder's seeds, tuned once the Guard and the Dasher are played). FightService casts
-- it and walks it; its pack's spawn puts it at the back (Rules.Fight.PackSpots). No Roblox API: its cases run with
-- Studio closed. Flat positions are (x, z) pairs.
--   Support.Pick(allies, reach, below) -> (id?, Does?)   its cast's one: the most hurt of its pack within `reach`, at or
--                                       under `below` of its health, is mended ("Heal"); with none, the nearest engaged
--                                       with a lead and unshielded is shielded ("Shield"); else nobody, and it doesn't cast
--   Support.Back(cx, cz, lx, lz, back) -> (x, z)   its place: `back` studs past its pack's middle (cx, cz), away from the
--                                       lead it fights (lx, lz); with the two on one spot, `back` along +z

local Support = {}

export type Does = "Heal" | "Shield"

-- One of its pack, as the Support reads it at the moment it casts.
export type Ally = {
	Id: string,
	Share: number, -- its health over its most: 0 is down, 1 whole
	Distance: number, -- studs from the Support, flat
	Shielded: boolean, -- a shield holds on it now
	Engaged: boolean, -- it has a standing lead for its target
}

function Support.Pick(allies: { Ally }, reach: number, below: number): (string?, Does?)
	local hurt: Ally? = nil
	local guard: Ally? = nil
	for _, ally in allies do
		if not (ally.Distance <= reach) or not (ally.Share > 0) then
			continue -- out of its reach, or down
		end
		if ally.Share <= below then
			local best = hurt
			if best == nil or ally.Share < best.Share or (ally.Share == best.Share and ally.Distance < best.Distance) then
				hurt = ally
			end
		end
		if ally.Engaged and not ally.Shielded then
			local best = guard
			if best == nil or ally.Distance < best.Distance then
				guard = ally
			end
		end
	end
	if hurt then
		return hurt.Id, "Heal"
	elseif guard then
		return guard.Id, "Shield"
	end
	return nil, nil
end

function Support.Back(cx: number, cz: number, lx: number, lz: number, back: number): (number, number)
	local dx, dz = cx - lx, cz - lz
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 1e-3 then
		return cx, cz + back
	end
	return cx + dx / length * back, cz + dz / length * back
end

return Support
