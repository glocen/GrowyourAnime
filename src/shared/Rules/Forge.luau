--!strict
-- Forge (shared, pure): the Forge's strike (TR37; AR28's Press; Config.World.Forge), the ram's height over its rest
-- through one Reinforce try. Four beats: anticipation, the ram lifting from rest to its tell, easing out; the strike, down
-- to the plate, easing in, fast; hitstop, held on the plate; recovery, settling back to rest. Its gears turn with its
-- travel, so they wind up as it lifts and run back as it falls. No Roblox API: it runs with Studio closed.

local Forge = {}

export type Ram = { Rest: number, Tell: number, Contact: number } -- its underside's heights over the Forge's floor
export type Timing = { Lift: number, Strike: number, Hold: number, Back: number } -- seconds of each beat

-- The beat at `t` seconds into a strike: "Lift", "Strike", "Hold", "Back", or "Done" once it's over.
function Forge.Beat(t: number, timing: Timing): string
	local edge = 0
	for _, beat in { "Lift", "Strike", "Hold", "Back" } do
		edge += math.max(0, (timing :: any)[beat])
		if t < edge then
			return beat
		end
	end
	return "Done"
end

-- The ram's height over its rest at `t` seconds into a strike, in studs (up positive); 0 before it and once it's done.
function Forge.Rise(t: number, ram: Ram, timing: Timing): number
	local up, down = ram.Tell - ram.Rest, ram.Contact - ram.Rest
	if t <= 0 then
		return 0
	end
	local lift, strike, hold, back = timing.Lift, timing.Strike, timing.Hold, timing.Back
	if t < lift then
		local x = t / lift
		return up * (1 - (1 - x) * (1 - x))
	end
	t -= lift
	if t < strike then
		local x = t / strike
		return up + (down - up) * x * x
	end
	t -= strike
	if t < hold then
		return down
	end
	t -= hold
	if t < back then
		local x = t / back
		return down * (1 - x * x * (3 - 2 * x))
	end
	return 0
end

-- Seconds a whole strike lasts.
function Forge.Length(timing: Timing): number
	return timing.Lift + timing.Strike + timing.Hold + timing.Back
end

return Forge
