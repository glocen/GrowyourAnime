--!strict
-- Hit cases (pure): one hit worked by hand, each ceiling, the type ring, a critical, a block, the elemental number, and
-- the expected value of a hit against tools/balance/sim.py's dps() for the same two fighters.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local StatsConfig = require(Shared.Config.Stats)

local NONE: Hit.Rolls = { Dodge = 0.999999, Critical = 0.999999, Block = 0.999999 } -- nothing rolls in
local ALL: Hit.Rolls = { Dodge = 0, Critical = 0, Block = 0 }

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-9) * math.max(1, math.abs(b))
end

local function fighter(level: number, stats: { [string]: any }): Stats.Block
	local block = Stats.Empty(level)
	for k, v in stats do
		(block :: any)[k] = v
	end
	return block
end

return {
	{
		Name = "Hit: a plain hit, by hand",
		Run = function(t: any)
			local a = fighter(1, { Attack = 100 })
			local d = fighter(1, {})
			local hit = Hit.Resolve(a, d, 1, NONE)
			t.Check("nothing rolled in", not hit.Dodged and not hit.Critical and not hit.Blocked)
			t.Equal("all of it", hit.Total, 100)
			t.Equal("a coefficient scales it", Hit.Resolve(a, d, 1.4, NONE).Total, 140)
			local armoured = fighter(1, { Defence = StatsConfig.Defence.K }) -- d / (d + K) = one half at level 1
			t.Check("half mitigated", near(Hit.Resolve(a, armoured, 1, NONE).Total, 50))
			t.Equal("no coefficient, no hit", Hit.Resolve(a, d, 0, NONE).Total, 0)
		end,
	},
	{
		Name = "Hit: a dodged hit does nothing",
		Run = function(t: any)
			local a = fighter(5, { Attack = 500, ElementalAttack = 100, Element = "Fire" })
			local d = fighter(5, { Dodge = 300 })
			local hit = Hit.Resolve(a, d, 1, ALL)
			t.Check("dodged", hit.Dodged and hit.Total == 0 and hit.Elemental == 0)
		end,
	},
	{
		Name = "Hit: each ceiling holds",
		Run = function(t: any)
			local caps, buckets = StatsConfig.Caps, StatsConfig.Buckets
			local huge = 1e12
			local a = fighter(10, { Attack = 100, Hit = 0, Critical = huge, Penetration = huge, CriticalDamage = 50, Lifesteal = 5 })
			local d = fighter(10, { Defence = huge, Dodge = huge, Block = huge, CriticalResist = 0, ElementalResist = huge })
			local hit = Hit.Resolve(a, d, 1, NONE, { Bonus = 9, Reduction = 9 })
			t.Check("dodge under its cap", hit.ChanceDodge < caps.Dodge)
			t.Check("critical at most its cap", hit.ChanceCritical <= caps.Critical)
			t.Check("block under its cap", hit.ChanceBlock < caps.Block)
			t.Check("penetration under its cap", hit.Penetration < caps.Penetration)
			t.Equal("mitigation at its cap", hit.Mitigation, StatsConfig.Defence.Cap)
			t.Equal("the bonus bucket at its cap", hit.Bonus, buckets.BonusCap)
			t.Equal("the reduction bucket at its cap", hit.Reduction, buckets.ReductionCap)
			t.Equal("lifesteal at its cap", hit.LifestealShare, StatsConfig.Lifesteal.Cap)
			local crit = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = 0, Block = 0.999999 })
			t.Check("a critical stays in the bucket's cap", crit.Critical and crit.Bonus == buckets.BonusCap)
			local floor = Hit.Resolve(fighter(1, { Attack = 1 }), fighter(1, {}), 1, NONE)
			t.Equal("every hit has the critical floor", floor.ChanceCritical, caps.CriticalFloor)
		end,
	},
	{
		Name = "Hit: a critical adds its extra, less the guard, to the bonus",
		Run = function(t: any)
			local a = fighter(1, { Attack = 100 })
			local d = fighter(1, { CriticalGuard = 0.1 })
			local crit = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = 0, Block = 0.999999 })
			t.Check("critical", crit.Critical)
			t.Check("bonus is the extra less the guard", near(crit.Bonus, StatsConfig.CriticalDamage - 0.1))
			t.Check("by hand", near(crit.Total, 100 * (1 + StatsConfig.CriticalDamage - 0.1)))
			local guarded = Hit.Resolve(a, fighter(1, { CriticalGuard = 5 }), 1, { Dodge = 0.999999, Critical = 0, Block = 0.999999 })
			t.Equal("a guard past the extra takes it to nothing, not below", guarded.Total, 100)
		end,
	},
	{
		Name = "Hit: a block adds its share to the reduction",
		Run = function(t: any)
			local a = fighter(1, { Attack = 100 })
			local d = fighter(1, { Block = 1000 })
			local blocked = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = 0.999999, Block = 0 })
			t.Check("blocked", blocked.Blocked)
			t.Check("by hand", near(blocked.Total, 100 * (1 - StatsConfig.Buckets.BlockShare)))
		end,
	},
	{
		Name = "Hit: the type ring, once each way",
		Run = function(t: any)
			local seen = 0
			for attacker, beaten in StatsConfig.Beats do
				seen += 1
				t.Equal(`{attacker} beats {beaten}`, Hit.TypeRelation(attacker, beaten), 1)
				t.Equal(`{beaten} loses to {attacker}`, Hit.TypeRelation(beaten, attacker), -1)
				t.Equal(`{attacker} against itself`, Hit.TypeRelation(attacker, attacker), 0)
			end
			t.Equal("five in the ring", seen, 5)
			t.Equal("no type is neutral", Hit.TypeRelation("", "Agility"), 0)
			local a = fighter(1, { Attack = 100, Type = "Agility" })
			t.Check("the advantage", near(Hit.Resolve(a, fighter(1, { Type = "Strength" }), 1, NONE).Total, 100 * (1 + StatsConfig.Buckets.TypeAdvantage)))
			t.Check("the disadvantage", near(Hit.Resolve(a, fighter(1, { Type = "Technique" }), 1, NONE).Total, 100 * (1 - StatsConfig.Buckets.TypeDisadvantage)))
		end,
	},
	{
		Name = "Hit: the elemental number goes past Defence and is never critical",
		Run = function(t: any)
			local a = fighter(1, { Attack = 0, ElementalAttack = 80, Element = "Frost" })
			local d = fighter(1, { Defence = 1e9 })
			local plain = Hit.Resolve(a, d, 1, NONE)
			t.Equal("past Defence", plain.Elemental, 80)
			local crit = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = 0, Block = 0.999999 })
			t.Check("a critical doesn't touch it", crit.Critical and crit.Elemental == 80)
			local none = Hit.Resolve(fighter(1, { ElementalAttack = 80 }), d, 1, NONE)
			t.Equal("no element, no second number", none.Elemental, 0)
		end,
	},
	{
		Name = "Hit: on average, the balance simulation's damage",
		Run = function(t: any)
			-- tools/balance/sim.py dps(att, dfn, rel) / coef_per_second() for these two, printed 2026-11-12.
			local expected = { [1] = 297.6942693428971, [0] = 240.98900285488378, [-1] = 203.2984873059928 }
			local defenderType = { [1] = "Strength", [0] = "Endurance", [-1] = "Technique" }
			local a = fighter(5, { Attack = 300, Hit = 50, Critical = 80, Penetration = 40, ElementalAttack = 60, Element = "Fire", Type = "Agility" })
			for relation, want in expected do
				local d = fighter(7, {
					Defence = 120, Dodge = 60, CriticalResist = 30, Block = 40, ElementalResist = 20, CriticalGuard = 0.1,
					Type = defenderType[relation],
				})
				local odds = Hit.Resolve(a, d, 1, NONE)
				t.Equal(`relation {relation}`, odds.TypeRelation, relation)
				local mean = 0
				for _, critical in { true, false } do
					for _, blocked in { true, false } do
						local hit = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = if critical then 0 else 0.999999, Block = if blocked then 0 else 0.999999 })
						local p = (if critical then odds.ChanceCritical else 1 - odds.ChanceCritical) * (if blocked then odds.ChanceBlock else 1 - odds.ChanceBlock)
						mean += p * hit.Total
					end
				end
				mean *= 1 - odds.ChanceDodge
				t.Check(`relation {relation}: {string.format("%.4f", mean)} against {string.format("%.4f", want)}`, near(mean, want, 1e-9))
			end
		end,
	},
}
