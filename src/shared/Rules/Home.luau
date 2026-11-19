--!strict
-- Home (pure rule): home in one tap, the dock's Base tile (docs/test-requests.md, TR19; the director, 2026-11-15, night:
-- "there should be a Ui to tp back to base with a small CD and only when out of combat/boss area event etc"). Whether a
-- tap takes the player home, and if not, why, in the order a player most needs to hear it: they're home already; they're
-- in a boss's ground (a keeper's try); an event is on; a fight; the cooldown. A fight is the game's one meaning of it
-- (FightService.InCombat, TR12: the lead has a target, or a Shade has the lead), or a hit the player's side dealt or took
-- in the last Fight seconds while the lead stands: a fall ends the fight at once, so the pip after a lone fall never
-- points at a dim tile (research's verdict on TR19, 2026-11-15). The server decides by it (HomeService); the dock shows
-- the same state from the same inputs (HudController).
--   Home.Refusal(situation, rules)   nil when a tap goes home, else "Here" | "Boss" | "Event" | "Fight" | "Cooldown"
--   Home.Says(refusal, situation)    the refusal in plain words; nil for "Here", where a tap does nothing
--   Home.Word(refusal, situation)    the tile's word on a hover or a long press: Says, and "You're home" for "Here"
--   Home.Broken(chargedAt, hitAt)    a hit since the charge began cancels it, and nothing is spent
--   Home.Share(from, seconds, now)   how far a charge or a cooldown has run, 0 to 1

export type Situation = {
	Now: number, -- server time
	HitAt: number?, -- the last hit the player's side dealt or took, server time
	Engaged: boolean, -- FightService.InCombat: the lead has a target, or a Shade has the lead
	Standing: boolean, -- the lead is out and stands: neither down nor gone home
	Try: boolean, -- a keeper's try under way
	Event: boolean,
	ReadyAt: number, -- the cooldown's end, server time; 0 when there's none
	OnPlot: boolean, -- standing on their own plot
}
export type Rules = { Fight: number }
export type Refusal = "Here" | "Boss" | "Event" | "Fight" | "Cooldown"

local Home = {}

function Home.Refusal(s: Situation, rules: Rules): Refusal?
	if s.OnPlot then
		return "Here"
	elseif s.Try then
		return "Boss"
	elseif s.Event then
		return "Event"
	elseif s.Engaged or (s.Standing and s.HitAt ~= nil and s.Now - s.HitAt < rules.Fight) then
		return "Fight"
	elseif s.Now < s.ReadyAt then
		return "Cooldown"
	end
	return nil
end

function Home.Says(refusal: Refusal?, s: Situation): string?
	if refusal == "Boss" then
		return "Not in a boss's arena" -- the keeper's street, never the Arc: players read a ground as an Arc
	elseif refusal == "Event" then
		return "Not during an event"
	elseif refusal == "Fight" then
		return "In a fight"
	elseif refusal == "Cooldown" then
		return `Ready in {math.max(math.ceil(s.ReadyAt - s.Now - 1e-6), 1)} s`
	end
	return nil
end

-- The Base tile's word, on a hover or a long press (TR20): why a tap does nothing or is refused. At home it's the reason a
-- tap stays silent (research's verdict on TR20, fix 2), where Says has nothing to say.
function Home.Word(refusal: Refusal?, s: Situation): string?
	if refusal == "Here" then
		return "You're home"
	end
	return Home.Says(refusal, s)
end

function Home.Broken(chargedAt: number, hitAt: number?): boolean
	return hitAt ~= nil and hitAt >= chargedAt
end

function Home.Share(from: number, seconds: number, now: number): number
	if seconds <= 0 then
		return 1
	end
	return math.clamp((now - from) / seconds, 0, 1)
end

return Home
