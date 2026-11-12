--!strict
-- Hit (shared, pure): one hit, the only place damage is computed (docs/balance.md, "One hit"; docs/engineering-plan.md,
-- "The resolver"). It multiplies in three places only, each with a ceiling: the defender's mitigation, the attacker's
-- bonus bucket, the defender's reduction bucket. Everything else adds into one of the two buckets. The server rolls the
-- three chances with its own Random and passes them in, so the same rolls always give the same hit.
-- Its expected value is tools/balance/sim.py's dps() for one coefficient; a case holds the two together.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local Stats = require(Shared.Rules.Stats)
local Growth = require(Shared.Rules.Growth)

local Hit = {}

export type Rolls = { Dodge: number, Critical: number, Block: number } -- each in [0, 1)
export type Effects = { Bonus: number?, Reduction: number? } -- Damage Bonus and Damage Reduction from effects in the fight

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
	Reduction: number, -- the defender's bucket as used, after its ceiling
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
	local caps = StatsConfig.Caps
	local dodge = Stats.Chance(caps.Dodge, defender.Dodge, attacker.Hit, defender.Level)
	local critical = math.min(
		caps.Critical,
		caps.CriticalFloor + Stats.Chance(caps.CriticalSpan, attacker.Critical, defender.CriticalResist, defender.Level)
	)
	local block = Stats.Chance(caps.Block, defender.Block, attacker.Hit, attacker.Level)
	local penetration = Stats.Chance(caps.Penetration, attacker.Penetration, 0, defender.Level)
	local left = defender.Defence * (1 - penetration)
	local mitigation = if left > 0
		then math.min(StatsConfig.Defence.Cap, left / (left + StatsConfig.Defence.K * Growth.G(attacker.Level)))
		else 0
	return dodge, critical, block, penetration, mitigation
end

function Hit.Resolve(attacker: Stats.Block, defender: Stats.Block, coefficient: number, rolls: Rolls, effects: Effects?): Result
	local buckets = StatsConfig.Buckets
	local dodge, critical, block, penetration, mitigation = Hit.Odds(attacker, defender)
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
		Reduction = 0,
	}
	if result.Dodged or not (coefficient > 0) then
		return result
	end
	result.Critical = rolls.Critical < critical
	result.Blocked = rolls.Block < block
	local fxBonus = if effects then effects.Bonus or 0 else 0
	local fxReduction = if effects then effects.Reduction or 0 else 0
	local base = math.min(buckets.BonusCap, fxBonus + (if relation > 0 then buckets.TypeAdvantage else 0))
	local bonus = base
	if result.Critical then
		bonus = math.min(buckets.BonusCap, base + math.max(0, attacker.CriticalDamage - defender.CriticalGuard))
	end
	local before = math.min(buckets.ReductionCap, fxReduction + (if relation < 0 then buckets.TypeDisadvantage else 0))
	local reduction = before
	if result.Blocked then
		reduction = math.min(buckets.ReductionCap, before + buckets.BlockShare)
	end
	result.Bonus, result.Reduction = bonus, reduction
	result.Physical = math.max(0, attacker.Attack) * coefficient * (1 - mitigation) * (1 + bonus) * (1 - reduction)
	if attacker.Element ~= "" and attacker.ElementalAttack > 0 then
		local resist = Stats.Chance(StatsConfig.Caps.ElementalResist, defender.ElementalResist, 0, attacker.Level)
		-- Past Defence, never critical: the bonus without the critical's extra.
		result.Elemental = attacker.ElementalAttack * coefficient * (1 - resist) * (1 + base) * (1 - reduction)
	end
	result.Total = result.Physical + result.Elemental
	result.LifestealShare = math.clamp(attacker.Lifesteal, 0, StatsConfig.Lifesteal.Cap)
	return result
end

return Hit
