--!strict
-- Growth (shared): the one curve every size follows, and the experience a level takes (docs/balance.md, "Growth", "Pace").
-- Seeds from tools/balance/seeds.json ("growth", "pace", "grounds") unless marked as the builder's; once here, this is
-- their home. Rules.Growth reads them when it runs, so a tune reaches the next call.

return {
	-- G(level) = 1 + A x (level - 1) + B x (level - 1)^2: 1 at level 1, about 22 at level 60, about 77 at 125.
	A = 0.12,
	B = 0.004,
	-- The cap (TR14; the director, 2026-11-14, night: "the level cap is 125 but the launch is designed for level 60").
	-- Past 60 the same curve runs on, and a level takes the last ground's kills (Rules.Growth.GroundOf) until the grounds
	-- that reach those levels are designed.
	MaxLevel = 125,
	-- Experience. A kill at level L gives XpPerKillPerG x G(L); a level takes the kills its ground's pace allows:
	-- PaceHours x KillsPerHour spread over the ground's levels (Definitions.Grounds), so ground 1 is about 67 kills a level.
	-- The derivation is the builder's, 2026-11-12, from the seeds' pace table ("Everything else is derived from that table").
	XpPerKillPerG = 10,
	-- Measured (TR72 item 4, 2026-11-28): a player's hour, three Normal runs of Lantern Row back to back (the self-test's
	-- "Session (TR72 item 4)"), the lead on the level-9 on-budget sheet, the waves on and the keeper's phases off, at the
	-- keeper's 165 s rest (Config.World.Row.Back), so no run waits at the gate: 35, 36 and 36 kills in 217, 206 and
	-- 217 s, 601 an hour. At the 300 s rest it was 386, each run after the first waiting about 135 s. Seeds
	-- "pace.killsPerHour".
	KillsPerHour = 601,
	PaceHours = { 1, 3, 6, 10, 15, 22 }, -- by ground order; seeds "grounds[].paceHours"
	-- Catch-up (docs/balance.md, "Catch-up"; TR72, item 3): a lead more than Below levels under the account's highest
	-- Voidkin earns its fights' experience x (1 + Bonus), a fixed bonus in the experience bucket, whose sum stops at
	-- XpCeiling (docs/balance.md, "Earning": catch-up, an event, research; x2.5). The builder's seeds, 2026-11-27, for
	-- research to set (tier 2): halving a second lead's climb keeps it hours, and the gap leaves a lead a level or two
	-- behind on its own. Neither the Training machine nor a worker's kWh takes it: the design gives it to the lead.
	CatchUp = { Below = 5, Bonus = 1.0 },
	XpCeiling = 2.5,
	-- A new account's first fights (research's verdict on TR2, 2026-11-12): the first levels take these kills instead of the
	-- pace's, so the lead reaches level 2 during its first pack, at its second kill. The builder's seed.
	Early = { 2, 4, 6, 8, 10, 12, 14 },
	-- The Training machine (TR12; docs/design.md, "The Training machine"): the director's word, 2026-11-14, night, "Fixed
	-- rate, no cap". A Voidkin in it earns a fixed amount of experience a second at any level: Share of what fighting earns
	-- in Lantern Row (Rules.Training.Rate, from Config.World.Row's packs and elite), research's third. Each level costs
	-- more, so it slows as levels rise. Every: the most seconds between two credits while the player is in the game.
	Training = { Share = 0.33, Every = 30 },
}
