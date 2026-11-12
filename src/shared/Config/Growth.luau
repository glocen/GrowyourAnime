--!strict
-- Growth (shared): the one curve every size follows, and the experience a level takes (docs/balance.md, "Growth", "Pace").
-- Seeds from tools/balance/seeds.json ("growth", "pace", "grounds") unless marked as the builder's; once here, this is
-- their home. Rules.Growth reads them when it runs, so a tune reaches the next call.

return {
	-- G(level) = 1 + A x (level - 1) + B x (level - 1)^2: 1 at level 1, about 22 at level 60.
	A = 0.12,
	B = 0.004,
	MaxLevel = 60,
	-- Experience. A kill at level L gives XpPerKillPerG x G(L); a level takes the kills its ground's pace allows:
	-- PaceHours x KillsPerHour spread over the ground's levels (Definitions.Grounds), so ground 1 is 50 kills a level.
	-- The derivation is the builder's, 2026-11-12, from the seeds' pace table ("Everything else is derived from that table").
	XpPerKillPerG = 10,
	KillsPerHour = 450, -- seeds "pace.killsPerHour"
	PaceHours = { 1, 3, 6, 10, 15, 22 }, -- by ground order; seeds "grounds[].paceHours"
}
