--!strict
-- Enemies (shared Config): an enemy's stats by its Kind, as one point of G (docs/balance.md, "Growth"): each stat is the
-- value here times G(level), so a deeper spawn changes what a player fights, not how fast the numbers run.
-- The builder's seeds (tier 2, for research), 2026-11-12: tools/balance/sim.py's own method (tune_enemies) run against a
-- bare Common Warrior at the enemy's level, since TR2 drops no gear. An ordinary Shade then falls in 5 s and costs the lead
-- 12% of its health, an elite 18 s and 35%, the Lamplighter 45 s and 70%, with the enemies' coefficient a second equal to
-- the lead's (Definitions.Actions). Defence is the seeds' 40 a G, and a keeper adds the seeds' ratings a G. When gear drops,
-- they're tuned again against the on-budget build, as the sim's own enemies are.
-- TR12, research's read of the sim, 2026-11-14 (tier 2, Faber's proposal): an Ordinary Shade's Attack halved from 11.47,
-- so a pack leaves its mark on a lead that heals only its Regen (tools/balance/sim.py, section 9).

return {
	Ordinary = { Health = 881.1, Attack = 5.735, Defence = 40 },
	Elite = { Health = 3172, Attack = 9.29, Defence = 40 },
	Keeper = { Health = 6975, Attack = 7.43, Defence = 40, Dodge = 20, CriticalResist = 30, Block = 30, ElementalResist = 30 },
	Dummy = { Health = 1e6, Attack = 0, Defence = 40 },
}
