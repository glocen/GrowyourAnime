--!strict
-- Hands (pure): the press, slip then strike (TR69 C; docs/research/cloud-2026-11-24/combat-agency.md, section 4;
-- Config.Combat.Hands). Behind its switch, Off by default, built beside today's for the director's pick by playing.
-- * Call is TR44's B (the Recall) in every fight but the Tower's. A Call pressed inside a marked strike's tell, the
--   strike then missing the lead, is a slip: the attacker is Open (staggered) for a while, the lead's signature ring
--   fills a share of its cooldown, and the lead's hold ends so it goes straight back in.
-- * A lead's signature landing on an Open foe, or breaking a raised Guard open, is a Finisher: its own hitstop row, a
--   longer throw, and a share of its cooldown back. It adds no damage, and it uses the Open up.
-- * Auto, when on, waits a few seconds on a full ring for a thumb, then fires. Auto never Calls.
-- * One read-out per fight: its Calls, the strikes it missed on purpose and by accident, its taps, the seconds a full
--   ring waited, the damage the lead took, and its length. A fight ends Linger seconds after its last blow.
-- No Roblox API: its cases run with Studio closed.
--   Hands.Calls(on, mode, inTry, fighting, tower) -> boolean    whether Call shows and is taken now
--   Hands.Slip(hit, called) -> boolean                         a marked strike's miss is a slip
--   Hands.Open(openUntil, at) -> boolean                       a foe is Open at `at`
--   Hands.Finisher(signature, open, broke) -> boolean          a hit is a Finisher
--   Hands.Fill(readyAt, at, cooldown, share) -> number         the ring `share` of its cooldown fuller: its new ready time
--   Hands.Waits(readyAt, at, wait) -> boolean                  Auto, on, still waits for a thumb
--   Hands.Tally(at) -> Tally                                   a new fight's read-out, from `at`
--   Hands.Note(tally, what, amount, at)                        a count added: "Calls", "OnPurpose", "Accident", "Taps",
--                                                              "Waited" (seconds), "Taken" (health); "Blow" only keeps it up
--   Hands.Over(tally, at, linger) -> boolean                   its fight is over: Linger seconds since its last blow
--   Hands.Rate(tally) -> number?                               presses a second (Calls and taps over its length)

local Hands = {}

export type Tally = {
	From: number, -- its first blow
	To: number, -- its last
	Calls: number,
	OnPurpose: number, -- marked strikes missed on purpose (a move or a Call in the tell)
	Accident: number, -- and by accident
	Taps: number,
	Waited: number, -- seconds a full ring waited before its signature went
	Taken: number, -- health the lead lost
}

function Hands.Calls(on: boolean, mode: string, inTry: boolean, fighting: boolean, tower: boolean): boolean
	if on then
		return fighting and not tower
	end
	return mode == "B" and inTry
end

function Hands.Slip(hit: boolean, called: boolean): boolean
	return called and not hit
end

function Hands.Open(openUntil: number?, at: number): boolean
	return openUntil ~= nil and at < openUntil
end

function Hands.Finisher(signature: boolean, open: boolean, broke: boolean): boolean
	return signature and (open or broke)
end

function Hands.Fill(readyAt: number, at: number, cooldown: number, share: number): number
	if readyAt <= at or cooldown <= 0 or share <= 0 then
		return readyAt -- full already, or nothing to fill
	end
	return math.max(at, readyAt - cooldown * share)
end

function Hands.Waits(readyAt: number, at: number, wait: number): boolean
	return at < readyAt + math.max(0, wait)
end

function Hands.Tally(at: number): Tally
	return { From = at, To = at, Calls = 0, OnPurpose = 0, Accident = 0, Taps = 0, Waited = 0, Taken = 0 }
end

function Hands.Note(tally: Tally, what: string, amount: number, at: number)
	tally.To = math.max(tally.To, at)
	if what == "Blow" then
		return
	end
	local counts = tally :: any
	assert(type(counts[what]) == "number" and what ~= "From" and what ~= "To", `no count "{what}"`)
	counts[what] += amount
end

function Hands.Over(tally: Tally, at: number, linger: number): boolean
	return at - tally.To >= linger
end

function Hands.Rate(tally: Tally): number?
	local seconds = tally.To - tally.From
	if seconds <= 0 then
		return nil
	end
	return (tally.Calls + tally.Taps) / seconds
end

return Hands
