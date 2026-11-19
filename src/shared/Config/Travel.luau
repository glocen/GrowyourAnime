--!strict
-- The trip between the base and the Festival of Battles (TR45; docs/engineering-plan.md, "Places";
-- docs/research/game-mode-places.md). Roblox's own retry: the call tried Calls times, Gap seconds apart; a failure
-- after the call, Flooded seconds later for a flood and Failure seconds for a plain failure, at most Most times a trip.
-- Watchdog: a player still here this long after the call gets their screen back. Settle: a server just started waits
-- this long before sending anyone out (Roblox staff, 2026).

return {
	Calls = 5,
	Gap = 1,
	Flooded = 15,
	Failure = 1,
	Most = 4,
	Watchdog = 40,
	Settle = 2,
	-- The arrival card on the far side: shown until the server says the stage stands, never longer than Hold seconds.
	Hold = 20,
}
