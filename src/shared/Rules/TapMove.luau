--!strict
-- TapMove (pure rules): tap to move, TR69's trial block (tier 1; research's seeds, 2026-11-26, narrowed by the director's
-- word by 23:23: "a nice bonus", never a winning answer to every tell; Config.Combat.TapMove). In a fight a tap or a
-- click on the floor sends the lead there in a blink, and it holds that spot until the tell it left resolves.
--   TapMove.IsTap(seconds, pixels, drag) -> boolean           a press shorter than drag.Seconds that never moved
--                                                              drag.Pixels: a tap, not the camera's drag
--   TapMove.Clamp(fromX, fromZ, toX, toZ, reach) -> (x, z, boolean)  the spot at most `reach` from the lead, along the
--                                                              line to the tap; true when it was clamped
--   TapMove.Ready(last, at, recover) -> boolean                a tap-move `recover` seconds after the last counts
--   TapMove.HoldUntil(landAt, ends, hold) -> number            when the lead may move again: the last of the tells it
--                                                              left resolving (`ends`, server times), at most `hold` after
--                                                              it lands; with none, as it lands
--   TapMove.Refusal(state) -> string?                         why a tap-move doesn't go: Off, NoLead, Stunned, NoFight,
--                                                              Recovering; nil when it goes
-- No Roblox API: it runs with Studio closed.

local TapMove = {}

export type Drag = { Seconds: number, Pixels: number }

function TapMove.IsTap(seconds: number, pixels: number, drag: Drag): boolean
	return seconds >= 0 and seconds < drag.Seconds and pixels < drag.Pixels
end

function TapMove.Clamp(fromX: number, fromZ: number, toX: number, toZ: number, reach: number): (number, number, boolean)
	local dx, dz = toX - fromX, toZ - fromZ
	local d = math.sqrt(dx * dx + dz * dz)
	if d <= reach then
		return toX, toZ, false
	end
	local k = math.max(reach, 0) / d
	return fromX + dx * k, fromZ + dz * k, true
end

function TapMove.Ready(last: number?, at: number, recover: number): boolean
	return last == nil or at - last >= recover
end

function TapMove.HoldUntil(landAt: number, ends: { number }, hold: number): number
	local last = landAt
	for _, e in ends do
		last = math.max(last, e)
	end
	return math.min(last, landAt + math.max(hold, 0))
end

export type State = { On: boolean, Lead: boolean, Stunned: boolean, Fighting: boolean, Ready: boolean }

function TapMove.Refusal(state: State): string?
	if not state.On then
		return "Off"
	elseif not state.Lead then
		return "NoLead"
	elseif state.Stunned then
		return "Stunned"
	elseif not state.Fighting then
		return "NoFight"
	elseif not state.Ready then
		return "Recovering"
	end
	return nil
end

return TapMove
