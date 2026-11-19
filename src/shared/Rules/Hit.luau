--!strict
-- Hit (shared, pure): one hit, the only place damage is computed (docs/balance.md, "One hit"; docs/engineering-plan.md,
-- "The resolver"). It multiplies in three places with a ceiling: the defender's mitigation, the attacker's bonus bucket,
-- the defender's reduction bucket. A critical multiplies on its own, outside the bucket, with no ceiling: x (1 + Critical
-- Damage - the target's Critical Immunity, CriticalGuard), never under x1 (the director, 2026-11-15). Everything else adds into one of the
-- two buckets. The server rolls the
-- three chances with its own Random and passes them in, so the same rolls always give the same hit.
-- Its expected value is Hit.Expected, in closed form; cases hold it to the rolled hits (TR49). tools/balance/sim.py's dps()
-- predates the combat review's F1 and F7.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local Stats = require(Shared.Rules.Stats)
local Growth = require(Shared.Rules.Growth)

local Hit = {}

export type Rolls = { Dodge: number, Critical: number, Block: number } -- each in [0, 1)
-- Damage Bonus and Damage Reduction from effects in the fight; Critical, a floor under the hit's critical chance, past its
-- cap (an Opener passive's: 1 always crits); Resist, Damage Reduction on the elemental part alone (a Resist passive's),
-- added to the hit's Reduction under the same ceiling; Extra, an Extra passive's share (Pip's Kindle): that share of the
-- hit's Attack x coefficient again, in the attacker's element, on the elemental path. No element, no Extra.
export type Effects = { Bonus: number?, Reduction: number?, Critical: number?, Resist: number?, Extra: number? }

export type Result = {
	Dodged: boolean,
	Critical: boolean,
	Blocked: boolean,
	Physical: number,
	Elemental: number, -- the second, coloured number; 0 without an element
	Total: number,
	LifestealShare: number, -- the attacker heals this share of the health the hit removes, capped per second by the fight
	-- The breakdown: every chance and factor the hit used, for the stat screen and the cases.
	TypeRelation: number, -- 1 with the advantage, -1 against it, 0 neutral
	ChanceDodge: number,
	ChanceCritical: number,
	ChanceBlock: number,
	Penetration: number,
	Mitigation: number,
	Bonus: number, -- the attacker's bucket as used, after its ceiling
	CriticalFactor: number, -- what a critical multiplied by, 1 without one; no ceiling
	Reduction: number, -- the defender's bucket as used, after its ceiling
	Gap: number, -- the level gap's factor (Hit.Gap), 1 unless the attacker is more than its Free levels under
}

-- 1 when `attacker` beats `defender`'s type, -1 the other way round, 0 otherwise.
function Hit.TypeRelation(attacker: string, defender: string): number
	local beats = StatsConfig.Beats
	if attacker ~= "" and beats[attacker] == defender then
		return 1
	end
	if defender ~= "" and beats[defender] == attacker then
		return -1
	end
	return 0
end

-- The chances and factors that don't depend on the rolls.
function Hit.Odds(attacker: Stats.Block, defender: Stats.Block): (number, number, number, number, number)
	-- F1 (the formula review, 2026-11-19; TR49): every K x G reads the level of the rating's owner.
	local caps = StatsConfig.Caps
	local dodge = Stats.Chance(caps.Dodge, defender.Dodge, attacker.Hit, defender.Level)
	local critical = math.min(
		caps.Critical,
		caps.CriticalFloor + Stats.Chance(caps.CriticalSpan, attacker.Critical, defender.CriticalResist, attacker.Level)
	)
	local block = Stats.Chance(caps.Block, defender.Block, attacker.Hit, defender.Level)
	local penetration = Stats.Chance(caps.Penetration, attacker.Penetration, 0, attacker.Level)
	local left = defender.Defence * (1 - penetration)
	local mitigation = if left > 0
		then math.min(StatsConfig.Defence.Cap, left / (left + StatsConfig.Defence.K * Growth.G(defender.Level)))
		else 0
	return dodge, critical, block, penetration, mitigation
end

-- The level gap (docs/balance.md, "One hit", 8; TR47): an attacker more than Free levels under its target deals
-- x max(Floor, Rate ^ (gap - Free)), physical and elemental: 61% at 5 levels, 27% at 10, 10% at 16. A higher one gets
-- nothing.
function Hit.Gap(attackerLevel: number, defenderLevel: number): number
	local gap, rule = defenderLevel - attackerLevel, StatsConfig.Gap
	if gap > rule.Free then
		return math.max(rule.Floor, rule.Rate ^ (gap - rule.Free))
	end
	return 1
end

function Hit.Resolve(attacker: Stats.Block, defender: Stats.Block, coefficient: number, rolls: Rolls, effects: Effects?): Result
	local buckets = StatsConfig.Buckets
	local dodge, critical, block, penetration, mitigation = Hit.Odds(attacker, defender)
	critical = math.max(critical, math.clamp(if effects then effects.Critical or 0 else 0, 0, 1))
	local relation = Hit.TypeRelation(attacker.Type, defender.Type)
	local result: Result = {
		Dodged = rolls.Dodge < dodge,
		Critical = false,
		Blocked = false,
		Physical = 0,
		Elemental = 0,
		Total = 0,
		LifestealShare = 0,
		TypeRelation = relation,
		ChanceDodge = dodge,
		ChanceCritical = critical,
		ChanceBlock = block,
		Penetration = penetration,
		Mitigation = mitigation,
		Bonus = 0,
		CriticalFactor = 1,
		Reduction = 0,
		Gap = Hit.Gap(attacker.Level, defender.Level),
	}
	if result.Dodged or not (coefficient > 0) then
		return result
	end
	result.Critical = rolls.Critical < critical
	result.Blocked = rolls.Block < block
	local fxBonus = if effects then effects.Bonus or 0 else 0
	local fxReduction = if effects then effects.Reduction or 0 else 0
	local bonus = math.min(buckets.BonusCap, fxBonus + (if relation > 0 then buckets.TypeAdvantage else 0))
	local factor = if result.Critical then 1 + math.max(0, attacker.CriticalDamage - defender.CriticalGuard) else 1
	local before = math.min(buckets.ReductionCap, fxReduction + (if relation < 0 then buckets.TypeDisadvantage else 0))
	-- F7: a block multiplies outside the reduction's ceiling.
	local blockKeep = if result.Blocked then 1 - buckets.BlockShare else 1
	local gap = result.Gap
	result.Bonus, result.CriticalFactor = bonus, factor
	result.Reduction = 1 - (1 - before) * blockKeep
	result.Physical = math.max(0, attacker.Attack) * coefficient * (1 - mitigation) * (1 + bonus) * factor * (1 - before) * blockKeep * gap
	local fxResist = if effects then effects.Resist or 0 else 0
	local elementalBefore = if fxResist > 0 then math.min(buckets.ReductionCap, before + fxResist) else before
	local resist = Stats.Chance(StatsConfig.Caps.ElementalResist, defender.ElementalResist, 0, defender.Level) -- F1
	local elementalKeep = (1 - resist) * (1 + bonus) * (1 - elementalBefore) * blockKeep * gap
	if attacker.Element ~= "" and attacker.ElementalAttack > 0 then
		-- Past Defence, never critical.
		result.Elemental = attacker.ElementalAttack * coefficient * elementalKeep
	end
	-- An Extra passive (Pip's Kindle): Share of the hit's Attack x coefficient, in the attacker's element, through the
	-- elemental path (Elemental Resist, the buckets, the block, the gap; past Defence, never critical).
	local extra = if effects then effects.Extra or 0 else 0
	if attacker.Element ~= "" and extra > 0 then
		result.Elemental += extra * math.max(0, attacker.Attack) * coefficient * elementalKeep
	end
	result.Total = result.Physical + result.Elemental
	result.LifestealShare = math.clamp(attacker.Lifesteal, 0, StatsConfig.Lifesteal.Cap)
	return result
end

-- The expected Total of Hit.Resolve(attacker, defender, 1, rolls, effects) over its three rolls, closed form: the rolls
-- are independent, so a critical's and a block's factors enter as their means. Combat Power (Rules.Stats.Sum) and the
-- skull's cost (Rules.Hud.Cost) read it; a case holds it to the mean of many rolled hits.
function Hit.Expected(attacker: Stats.Block, defender: Stats.Block, effects: Effects?): number
	local buckets = StatsConfig.Buckets
	local dodge, critical, block, _, mitigation = Hit.Odds(attacker, defender)
	critical = math.max(critical, math.clamp(if effects then effects.Critical or 0 else 0, 0, 1))
	local relation = Hit.TypeRelation(attacker.Type, defender.Type)
	local fxBonus = if effects then effects.Bonus or 0 else 0
	local fxReduction = if effects then effects.Reduction or 0 else 0
	local bonus = math.min(buckets.BonusCap, fxBonus + (if relation > 0 then buckets.TypeAdvantage else 0))
	local factor = 1 + critical * math.max(0, attacker.CriticalDamage - defender.CriticalGuard)
	local before = math.min(buckets.ReductionCap, fxReduction + (if relation < 0 then buckets.TypeDisadvantage else 0))
	local blockKeep = 1 - block * buckets.BlockShare
	local gap = Hit.Gap(attacker.Level, defender.Level)
	local physical = math.max(0, attacker.Attack) * (1 - mitigation) * (1 + bonus) * factor * (1 - before) * blockKeep * gap
	local elemental = 0
	if attacker.Element ~= "" then
		local fxResist = if effects then effects.Resist or 0 else 0
		local elementalBefore = if fxResist > 0 then math.min(buckets.ReductionCap, before + fxResist) else before
		local resist = Stats.Chance(StatsConfig.Caps.ElementalResist, defender.ElementalResist, 0, defender.Level)
		local elementalKeep = (1 - resist) * (1 + bonus) * (1 - elementalBefore) * blockKeep * gap
		local extra = if effects then effects.Extra or 0 else 0
		elemental = (math.max(0, attacker.ElementalAttack) + math.max(0, extra) * math.max(0, attacker.Attack)) * elementalKeep
	end
	return (1 - dodge) * (physical + elemental)
end

return Hit
