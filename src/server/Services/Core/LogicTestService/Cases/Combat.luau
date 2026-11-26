--!strict
-- Combat (TR49, the combat review built): research's cases from its integration pass (2026-11-19, 206 checks): F1, F7,
-- the level gap, Hit.Expected, Stats.Rate, the Kindle gate, the enemy's lift and stage, the seeds' time to kill through
-- the rate, the skull's cost. Then the builder's: Lifesteal's room (Rules.Fight.Steal), the foe card's blocks and its
-- never-grey floor (Rules.Hud), and the ten elements (decision 6).

local Shared = game:GetService("ReplicatedStorage").Shared
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Hud = require(Shared.Rules.Hud)
local Growth = require(Shared.Rules.Growth)
local StatsConfig = require(Shared.Config.Stats)
local EnemiesConfig = require(Shared.Config.Enemies)
local HudConfig = require(Shared.Config.Hud)
local Fight = require(Shared.Rules.Fight)
local Tower = require(Shared.Rules.Tower)
local Voidkin = require(Shared.Definitions.Voidkin)

local NONE: Hit.Rolls = { Dodge = 0.999999, Critical = 0.999999, Block = 0.999999 }

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

local function lead(def: string, level: number): Stats.Block
	return (Stats.Resolve({ Id = "k", Def = def, Level = level, Xp = 0, Stars = 0, Copies = 0, Nickname = "", Preset = "", Favourite = false, Locked = false, Born = 0 } :: any))
end

-- The mean of Hit.Resolve over its three rolls, each outcome weighted by its chance (the rolls are independent).
local function rolledMean(a: Stats.Block, d: Stats.Block, effects: Hit.Effects?): number
	local odds = Hit.Resolve(a, d, 1, NONE, effects)
	local mean = 0
	for _, critical in { true, false } do
		for _, blocked in { true, false } do
			local hit = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = if critical then 0 else 0.999999, Block = if blocked then 0 else 0.999999 }, effects)
			mean += (if critical then odds.ChanceCritical else 1 - odds.ChanceCritical) * (if blocked then odds.ChanceBlock else 1 - odds.ChanceBlock) * hit.Total
		end
	end
	return mean * (1 - odds.ChanceDodge)
end

return {
	{
		Name = "Hit: every rating's K x G reads its owner's level (F1)",
		Run = function(t: any)
			local caps = StatsConfig.Caps
			local a = fighter(5, { Attack = 100, Hit = 80, Critical = 90, Penetration = 70, Element = "Fire", ElementalAttack = 20 })
			local d = fighter(30, { Health = 1000, Defence = 60, Dodge = 50, Block = 40, CriticalResist = 30, ElementalResist = 50 })
			local dodge, critical, block, penetration, mitigation = Hit.Odds(a, d)
			t.Check("dodge: the defender's", near(dodge, Stats.Chance(caps.Dodge, 50, 80, 30)))
			t.Check("block: the defender's", near(block, Stats.Chance(caps.Block, 40, 80, 30)))
			t.Check("critical: the attacker's", near(critical, math.min(caps.Critical, caps.CriticalFloor + Stats.Chance(caps.CriticalSpan, 90, 30, 5))))
			t.Check("penetration: the attacker's", near(penetration, Stats.Chance(caps.Penetration, 70, 0, 5)))
			local left = 60 * (1 - penetration)
			t.Check("Defence: the defender's", near(mitigation, math.min(StatsConfig.Defence.Cap, left / (left + StatsConfig.Defence.K * Growth.G(30)))))
			local hit = Hit.Resolve(a, d, 1, NONE)
			local resist = Stats.Chance(caps.ElementalResist, 50, 0, 30)
			t.Check("Elemental Resist: the defender's", near(hit.Elemental, 20 * (1 - resist) * Hit.Gap(5, 30)), `{hit.Elemental}`)
		end,
	},
	{
		Name = "Hit: a block multiplies outside the reduction's ceiling (F7)",
		Run = function(t: any)
			local buckets = StatsConfig.Buckets
			local a = fighter(10, { Attack = 100, Type = "Burst" })
			local d = fighter(10, { Health = 1000, Block = 1e9, Type = "Force" })
			local open = Hit.Resolve(a, d, 1, NONE, { Reduction = 1 })
			local blocked = Hit.Resolve(a, d, 1, { Dodge = 0.999999, Critical = 0.999999, Block = 0 }, { Reduction = 1 })
			t.Check("the reduction alone stops at its ceiling", near(open.Physical, 100 * (1 - buckets.ReductionCap)), `{open.Physical}`)
			t.Check("blocked: the block's share off what the ceiling left", near(blocked.Physical, open.Physical * (1 - buckets.BlockShare)), `{blocked.Physical}`)
			t.Check("the reduction shown is past the ceiling", blocked.Reduction > buckets.ReductionCap, `{blocked.Reduction}`)
		end,
	},
	{
		Name = "Hit: the level gap, x 0.85 a level past 2 below, never under 0.05",
		Run = function(t: any)
			for _, row in { { 0, 1 }, { 2, 1 }, { 3, 0.85 }, { 4, 0.7225 }, { 10, 0.85 ^ 8 }, { 25, 0.05 }, { -10, 1 } } do
				t.Check(`{row[1]} levels under: x{row[2]}`, near(Hit.Gap(20, 20 + row[1]), row[2]), `{Hit.Gap(20, 20 + row[1])}`)
			end
			local a = fighter(10, { Attack = 100 })
			t.Check("a hit carries it", near(Hit.Resolve(a, fighter(14, { Health = 1 }), 1, NONE).Physical, Hit.Resolve(a, fighter(10, { Health = 1 }), 1, NONE).Physical * 0.7225))
		end,
	},
	{
		Name = "Hit: Hit.Expected is the rolled hit's mean, Kindle and Insulated included",
		Run = function(t: any)
			local pairs_ = {
				{ fighter(10, { Attack = 120, Hit = 60, Critical = 80, Penetration = 40, CriticalDamage = 0.9, Element = "Fire", ElementalAttack = 25, Type = "Burst" }), fighter(12, { Health = 900, Defence = 80, Dodge = 50, Block = 60, CriticalResist = 40, CriticalGuard = 0.2, ElementalResist = 70, Type = "Force" }) },
				{ fighter(30, { Attack = 300, Critical = 300, CriticalDamage = 1.5 }), fighter(25, { Health = 4000, Defence = 200, Block = 200, Type = "Burst" }) },
				{ lead("pip", 9), Stats.Enemy("brawler_elite", 9) },
				{ Stats.Enemy("lamplighter", 20, nil, "Hard", 4), lead("lyric", 18) },
			}
			for i, pair in pairs_ do
				for j, effects in { {}, { Extra = 0.35 }, { Extra = 0.35, Resist = 0.2, Reduction = 0.1, Bonus = 0.1 } } do
					local want = rolledMean(pair[1], pair[2], effects :: any)
					local got = Hit.Expected(pair[1], pair[2], effects :: any)
					t.Check(`pair {i}, effects {j}: {string.format("%.4f", got)} against {string.format("%.4f", want)}`, near(got, want, 1e-9))
				end
			end
		end,
	},
	{
		Name = "Stats: Stats.Rate is the kit's one-action-at-a-time rate, Kindle's share with it",
		Run = function(t: any)
			for _, row in { { "rook", 1.8692 }, { "kirra", 1.9394 }, { "pip", 1.6836 }, { "watt", 1.6071 }, { "lyric", 1.5880 }, { "brawler", 2.1778 }, { "lamplighter", 2.4306 } } do
				local rate = Stats.Rate(row[1] :: string)
				t.Check(`{row[1]}: {string.format("%.4f", rate)} a second`, near(rate, row[2] :: number, 5e-5))
			end
			local _, pip = Stats.Rate("pip")
			local _, rook = Stats.Rate("rook")
			t.Check("Pip's Kindle has a share, Rook none", pip > 0 and rook == 0, `{pip}, {rook}`)
			t.Equal("a Voidkin without a kit: the stand-in's (Actions.KitOf)", Stats.Rate("nobody"), Stats.Rate("rook"))
		end,
	},
	{
		Name = "Hit: Kindle's Extra rides the elemental path, and only with an element",
		Run = function(t: any)
			local d = fighter(10, { Health = 1000, ElementalResist = 40 })
			local bare = fighter(10, { Attack = 100 })
			local fire = fighter(10, { Attack = 100, Element = "Fire" })
			t.Equal("no element: no Extra", Hit.Resolve(bare, d, 1, NONE, { Extra = 0.5 }).Elemental, 0)
			local resist = Stats.Chance(StatsConfig.Caps.ElementalResist, 40, 0, 10)
			local hit = Hit.Resolve(fire, d, 1, NONE, { Extra = 0.5 })
			t.Check("an element: Share x Attack past Elemental Resist", near(hit.Elemental, 0.5 * 100 * (1 - resist)), `{hit.Elemental}`)
			t.Check("never critical", near(Hit.Resolve(fire, d, 1, { Dodge = 0.999999, Critical = 0, Block = 0.999999 }, { Extra = 0.5 }).Elemental, hit.Elemental))
		end,
	},
	{
		Name = "Stats: an enemy's lift by difficulty and Kind, and its stage's factor; Element and percents kept",
		Run = function(t: any)
			for _, def in { "brawler", "brawler_elite", "lamplighter" } do
				for _, level in { 1, 20 } do
					local plain = Stats.Enemy(def, level)
					local kind = assert(require(Shared.Definitions.Enemies).ById[def]).Kind
					local lift = EnemiesConfig.Lift.Hard[kind]
					for _, row in { { "Hard", 1 }, { "Hard", 2 }, { "Normal", 1 }, { "Normal", 3 }, { "Normal", 2 } } do
						local factor = (EnemiesConfig.Stage[row[1] :: string] :: any)[row[2]] or {}
						local l = if row[1] == "Hard" then lift else { Health = 1, Attack = 1 }
						local e = Stats.Enemy(def, level, nil, row[1] :: string, row[2] :: number)
						local tag = `{def} {level} {row[1]} {row[2]}`
						t.Check(`{tag}: Health`, near(e.Health, plain.Health * l.Health * (factor.Health or 1)))
						t.Check(`{tag}: Attack`, near(e.Attack, plain.Attack * l.Attack * (factor.Attack or 1)))
						t.Check(`{tag}: Elemental Attack with it`, near(e.ElementalAttack, plain.ElementalAttack * l.Attack * (factor.Attack or 1)))
						t.Check(`{tag}: Defence as it was`, near(e.Defence, plain.Defence))
					end
					t.Equal(`{def} {level}: its Element`, plain.Element, (EnemiesConfig :: any)[kind].Element)
					t.Equal(`{def} {level}: Critical Damage a percent`, plain.CriticalDamage, (EnemiesConfig :: any)[kind].CriticalDamage)
				end
			end
		end,
	},
	{
		Name = "Fight: the seeds' time to kill through the kit's rate, against a bare Common Warrior",
		Run = function(t: any)
			-- ttk and the share of the lead a kill costs, research's integration pass (2026-11-19), Normal, no stage factor,
			-- on a Rook with no element, as its copy had him: the merge gives research's model exactly. Then with his Fire
			-- (decision 6), the builder's figures through the same functions, 2026-11-19, for research to confirm or retune.
			-- The keeper's share isn't the bare lead's to meet: it's tuned to the on-budget lead (TR69 D, research's (a),
			-- 2026-11-26, 22:32; docs/balance.md, "Fights against the game"), and a bare lead can't beat it (the case below).
			local model = { { "brawler", 4.51, 0.018 }, { "brawler_elite", 12.69, 0.206 }, { "lamplighter", 44.11, nil } }
			local fire = { { "brawler", 3.789, 0.0155 }, { "brawler_elite", 10.666, 0.1733 }, { "lamplighter", 39.246, nil } }
			for _, level in { 1, 5, 9 } do
				for _, case in { { "no element", model, "" }, { "Fire", fire, nil } } :: { any } do
					local rook = lead("rook", level)
					if case[3] then
						rook.Element = case[3] :: string
					end
					for _, target in case[2] :: { any } do
						local enemy = Stats.Enemy(target[1] :: string, level)
						local ttk = enemy.Health / (Stats.Rate("rook") * Hit.Expected(rook, enemy))
						local share = Stats.Rate(target[1] :: string) * Hit.Expected(enemy, rook) * ttk / rook.Health
						t.Check(`level {level} {target[1]}, {case[1]}: {string.format("%.2f", ttk)} s`, near(ttk, target[2] :: number, 0.01))
						if target[3] ~= nil then
							t.Check(`level {level} {target[1]}, {case[1]}: {string.format("%.3f", share)} of the lead`, near(share, target[3] :: number, 0.03))
						end
					end
				end
				t.Equal(`level {level}: Rook's own element is Fire`, lead("rook", level).Element, "Fire")
			end
		end,
	},
	{
		-- TR69 D (research's (a), 2026-11-26, 22:32): the keeper is tuned to the on-budget Common Warrior, which ends a
		-- standing fight near 30% (keeperHpLoss 0.7, measured on the pad), so a bare own-level one can't beat it
		-- (docs/balance.md, "Fights against the game": "A bare Voidkin ... can't beat a keeper").
		Name = "Fight: a bare own-level Common Warrior can't beat the keeper, with or without its element (TR69 D)",
		Run = function(t: any)
			for _, level in { 1, 5, 9, 20, 40 } do
				for _, element in { "", "Fire" } do
					local rook = lead("rook", level)
					rook.Element = element
					local keeper = Stats.Enemy("lamplighter", level)
					local ttk = keeper.Health / (Stats.Rate("rook") * Hit.Expected(rook, keeper))
					local share = Stats.Rate("lamplighter") * Hit.Expected(keeper, rook) * ttk / rook.Health
					t.Check(`level {level}, {if element == "" then "no element" else element}: the keeper takes {string.format("%.2f", share)} of the lead`, share > 1)
				end
			end
		end,
	},
	{
		Name = "Hud: the skull reads one fight's cost against the cuts",
		Run = function(t: any)
			local cuts = HudConfig.Skulls.Cuts
			for _, level in { 5, 20, 40 } do
				local rook = lead("rook", level)
				for _, row in { { "brawler", 1 }, { "brawler_elite", 2 }, { "lamplighter", 4 } } do
					local cost = Hud.Cost(rook, Stats.Enemy(row[1] :: string, level))
					-- A bare own-level Rook: an Ordinary grey (its Regen outheals it), an Elite white, the keeper red: tuned to the
					-- on-budget lead, it beats a bare one (TR69 D). The skull reads the lead's own power (Stats.Resolve).
					t.Equal(`level {level} {row[1]}: cost {string.format("%.3f", cost)}`, Hud.Skull(cost, 1, cuts), row[2])
				end
				t.Check(`level {level}: a stronger foe costs more`, Hud.Cost(rook, Stats.Enemy("brawler", level + 6)) > Hud.Cost(rook, Stats.Enemy("brawler", level)))
				t.Equal(`level {level}: a foe that deals nothing costs 0`, Hud.Cost(rook, Stats.Enemy("dummy", level)), 0)
			end
		end,
	},
	{
		Name = "Fight: Lifesteal heals its share of what a hit removed, counted up to its cap of most health a second (TR49)",
		Run = function(t: any)
			local per = StatsConfig.Lifesteal.DamagePerSecondOfMaxHealth
			local most = 1000
			local room = per * most -- one second's count, full
			local heal, left = Fight.Steal(0.1, 30, most, per, nil, 0, 5)
			t.Check("a full room: the share of all it removed", near(heal, 3) and near(left, room - 30), `{heal}, {left}`)
			heal, left = Fight.Steal(0.1, 500, most, per, nil, 0, 5)
			t.Check("past the room: the share of the room alone", near(heal, 0.1 * room) and near(left, 0), `{heal}, {left}`)
			heal, left = Fight.Steal(0.1, 500, most, per, 0, 5, 5.5)
			t.Check("half a second later: half the room back", near(heal, 0.1 * room / 2) and near(left, 0), `{heal}, {left}`)
			heal, left = Fight.Steal(0.1, 10, most, per, 0, 5, 50)
			t.Check("never more than a second's", near(left, room - 10), `{left}`)
			heal, left = Fight.Steal(0, 100, most, per, nil, 0, 1)
			t.Check("no Lifesteal: no heal, the room full", heal == 0 and near(left, room))
			heal, left = Fight.Steal(0.1, 0, most, per, 40, 1, 1)
			t.Check("a hit that removed nothing: no heal, the room as it was", heal == 0 and near(left, 40))
			heal = Fight.Steal(0.1, math.huge, most, per, nil, 0, 1)
			t.Equal("a bad amount heals nothing", heal, 0)
			-- Over a long fight, never more than the share of the cap a second, however hard it hits.
			local total, r, since = 0, nil :: number?, 0
			for i = 1, 100 do
				local at = i * 0.25
				local h, rest = Fight.Steal(StatsConfig.Lifesteal.Cap, 1e6, most, per, r, since, at)
				total += h
				r, since = rest, at
			end
			t.Check("100 huge hits over 25 s: at most the cap, 8% a second", total <= StatsConfig.Lifesteal.Cap * per * most * 26 + 1e-6, `{total}`)
		end,
	},
	{
		Name = "Hud: the foe card's blocks are the server's, and a foe at the lead's level or above is never grey (TR49)",
		Run = function(t: any)
			local cuts = HudConfig.Skulls.Cuts
			for _, level in { 5, 20, 40 } do
				local rook = lead("rook", level)
				local brawler = Stats.Enemy("brawler", level)
				t.Equal(`level {level}: an own-level Ordinary costs a scratch`, Hud.Skull(Hud.Cost(rook, brawler), 1, cuts), 1)
				t.Equal(`level {level}: but reads white, never grey`, Hud.FoeTier(rook, brawler, cuts), 2)
				local low = Stats.Enemy("brawler", math.max(1, level - 3))
				t.Equal(`level {level}: one three levels under reads its cost`, Hud.FoeTier(rook, low, cuts), Hud.Skull(Hud.Cost(rook, low), 1, cuts))
				t.Equal(`level {level}: the keeper as the skull reads it, red to a bare lead (TR69 D)`, Hud.FoeTier(rook, Stats.Enemy("lamplighter", level), cuts), 4)
				local hard = Hud.FoeBlock("Ordinary", "brawler", level, nil, "Hard", 2, nil)
				local server = Stats.Enemy("brawler", level, nil, "Hard", 2)
				t.Check(`level {level}: a Hard Shade's block, the server's`, near(hard.Health, server.Health) and near(hard.Attack, server.Attack))
				local crowded = Hud.FoeBlock("Elite", "brawler_elite", level, "Red", nil, 1, 9999)
				t.Check(`level {level}: a crowd's health, as the model says`, crowded.Health == 9999 and crowded.Type == "Red", `{crowded.Health}`)
				local rival = Hud.FoeBlock("Rival", "kirra", level, "Blue", nil, nil, nil)
				local tower = Tower.Block({ Def = "kirra", Level = level })
				t.Check(`level {level}: a Tower rival's block, Rules.Tower's`, near(rival.Health, tower.Health) and near(rival.Attack, tower.Attack) and rival.Type == "Blue")
			end
		end,
	},
	{
		Name = "Definitions: every Voidkin has an element, the ten as research picked them (TR49, decision 6)",
		Run = function(t: any)
			local picks: { [string]: string } = { rook = "Fire", kirra = "Void", patch = "Frost", tumble = "Storm", brick = "Void", sable = "Void", gantry = "Fire", mallow = "Fire", wren = "Storm", crane = "Frost" }
			for id, element in picks do
				t.Equal(`{id}: {element}`, (Voidkin.ById[id] :: any).Element, element)
			end
			local counts: { [string]: number } = {}
			for _, row in Voidkin.List do
				counts[row.Element] = (counts[row.Element] or 0) + 1
			end
			t.Check("31 at Fire 9, Storm 9, Void 7, Frost 6, none without", counts.Fire == 9 and counts.Storm == 9 and counts.Void == 7 and counts.Frost == 6 and counts[""] == nil)
		end,
	},
}
