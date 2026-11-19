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
-- TR25, 2026-11-16: solved again by the same method for the bare Common Warrior's attribute figure (Health 516, Attack
-- 116, its own ratings), so every target above holds exactly: Health from 881.1, 3172 and 6975, Attack from 5.735, 9.29
-- and 7.43 ("the build re-authors them and the targets hold exactly", docs/research/rework-2026-11-16.md, part 2).

-- The integration pass of the combat-math review (research, 2026-11-19): solved against the median Rook build on
-- each stage's first play, one action at a time. Element is a string; Critical Damage a percent, never times G.
return {
	Ordinary = { Health = 660, Attack = 0.9, Defence = 70, Hit = 57, Dodge = 31, Critical = 47, Block = 31, ElementalAttack = 0.225, CriticalDamage = 0.5, Element = "Void" },
	Elite = { Health = 1800, Attack = 3.4, Defence = 70, Hit = 76, Dodge = 41, Critical = 63, Block = 41, ElementalAttack = 0.85, CriticalDamage = 0.75, Element = "Void" },
	Keeper = { Health = 6050, Attack = 3.15, Defence = 70, Hit = 76, Dodge = 41, Critical = 63, CriticalResist = 120, Block = 41, Penetration = 83, ElementalAttack = 1.1025, ElementalResist = 97, CriticalDamage = 1, Element = "Fire" },
	Dummy = { Health = 1e6, Attack = 0, Defence = 40 },
	-- A difficulty's lift by Kind, times the row (Rules.Stats.Enemy). Normal has none.
	Lift = { Hard = { Ordinary = { Health = 1.6, Attack = 1.6 }, Elite = { Health = 2.05, Attack = 1.5 }, Keeper = { Health = 1.7, Attack = 1.2 } } } :: { [string]: { [string]: { Health: number, Attack: number } } },
	-- A stage's factor on every foe in it, by difficulty and stage (Rules.Stats.Enemy). A stage not here has none.
	Stage = { Normal = { [1] = { Attack = 0.8 }, [3] = { Attack = 1.2 } }, Hard = { [1] = { Attack = 0.8 } } } :: { [string]: { [number]: { Health: number?, Attack: number? } } },
}
