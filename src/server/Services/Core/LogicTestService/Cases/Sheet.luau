--!strict
-- Logic cases (pure): Overview's stat sheet (docs/ui.md, 5, "Overview's stat sheet"; Rules.Sheet): every stat in its
-- three groups, a zero as 0, a rating's "up to" as Rules.Hit sums it against a foe with none, Critical with its floor, the
-- percents, a passive's Damage Reduction with its condition, and each line's sources.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Sheet = require(Shared.Rules.Sheet)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local StatsConfig = require(Shared.Config.Stats)
local Passives = require(Shared.Definitions.Passives)

local LEVEL = 12

local function block(change: { [string]: any }?): Stats.Block
	local b = Stats.Empty(LEVEL)
	b.Def, b.Type, b.Class, b.Element = "rook", "Blaze", "Warrior", ""
	b.Health, b.Attack, b.Defence, b.Regen, b.Speed, b.Poise = 1234, 150, 60, 4.26, 16, 100
	for key, value in change or {} do
		(b :: any)[key] = value
	end
	return b
end

local function row(groups: { Sheet.Group }, stat: string): Sheet.Row?
	for _, group in groups do
		for _, each in group.Rows do
			if each.Stat == stat then
				return each
			end
		end
	end
	return nil
end

return {
	{
		Name = "Sheet: Overview shows every stat in three groups, a zero as 0, never hidden",
		Run = function(t: any)
			local groups = Sheet.Rows(block(), {}, nil)
			local names, count = {}, 0
			for _, group in groups do
				table.insert(names, group.Name)
				count += #group.Rows
			end
			t.Equal("Core, Attack and Defence, in that order", table.concat(names, ", "), "Core, Attack, Defence")
			t.Equal("nineteen lines: every stat a source adds to, Speed, Poise, and the two from effects", count, #Stats.Names + 4)
			for _, name in Stats.Names do
				t.Check(`{name} has a line`, row(groups, name) ~= nil)
			end
			local hit = row(groups, "Hit")
			t.Equal("a rating at zero shows 0", if hit then hit.Value else nil, "0")
			local dodge = row(groups, "Dodge")
			t.Equal("a rating at zero gives nothing: 0 alone, never 'up to 0%'", if dodge then dodge.Value else nil, "0")
			local guard = row(groups, "CriticalGuard")
			t.Equal("a percent at zero shows 0%", if guard then guard.Value else nil, "0%")
			local bonus = row(groups, "DamageBonus")
			t.Equal("Damage Bonus with nothing giving it: 0%, nothing under it", if bonus then `{bonus.Value}|{bonus.Under or ""}` else nil, "0%|")
			local health = row(groups, "Health")
			t.Equal("points grouped", if health then health.Value else nil, "1,234")
			local regen = row(groups, "Regen")
			t.Equal("Regen to a tenth, a second", if regen then regen.Value else nil, "4.3 a second")
			local speed = row(groups, "Speed")
			t.Equal("Speed in studs a second", if speed then speed.Value else nil, "16 studs a second")
			t.Equal("the names players read", if row(groups, "CriticalDamage") then (row(groups, "CriticalDamage") :: Sheet.Row).Name else nil, "Critical Damage")
		end,
	},
	{
		Name = "Sheet: a rating's 'up to' is what it gives at its level against a foe with none, as a hit sums it",
		Run = function(t: any)
			local foe = Stats.Empty(LEVEL) -- a foe with none, at the Voidkin's level
			local mine = block({ Dodge = 80, Critical = 120, Block = 60, Penetration = 40, ElementalResist = 50 })
			local dodge = Hit.Odds(foe, mine)
			local _, critical, _, penetration = Hit.Odds(mine, foe)
			local _, _, block2 = Hit.Odds(foe, mine)
			local near = function(a: number?, b: number): boolean
				return a ~= nil and math.abs(a - b) < 1e-9
			end
			t.Check("Dodge, as the foe's swing meets it", near(Sheet.Chance("Dodge", mine), dodge))
			t.Check("Critical, its floor counted, as its own swing rolls it", near(Sheet.Chance("Critical", mine), critical))
			t.Check("Block", near(Sheet.Chance("Block", mine), block2))
			t.Check("Penetration", near(Sheet.Chance("Penetration", mine), penetration))
			t.Check("Elemental Resist", near(Sheet.Chance("ElementalResist", mine), Stats.Chance(StatsConfig.Caps.ElementalResist, 50, 0, LEVEL)))
			t.Equal("a stat with no chance of its own has none", Sheet.Chance("Hit", mine), nil)
			local groups = Sheet.Rows(mine, {}, nil)
			local dodgeRow = row(groups, "Dodge")
			t.Equal("its points, then up to its chance", if dodgeRow then dodgeRow.Value else nil, `80 · up to {Sheet.Percent(dodge)}`)
			local none = row(Sheet.Rows(block(), {}, nil), "Critical")
			t.Equal("Critical at no points still has its floor", if none then none.Value else nil, `0 · up to {Sheet.Percent(StatsConfig.Caps.CriticalFloor)}`)
			local hit = row(groups, "Hit")
			t.Check("Hit says it lowers a foe's", hit ~= nil and string.find(hit.Under or "", "Lowers a foe's Dodge and Block", 1, true) ~= nil)
		end,
	},
	{
		Name = "Sheet: percents, the critical's base, an element, the lifesteal's cap and a passive's condition",
		Run = function(t: any)
			t.Equal("whole from 10%", Sheet.Percent(0.254), "25%")
			t.Equal("one place under it", Sheet.Percent(0.078), "7.8%")
			t.Equal("never a trailing .0", Sheet.Percent(0.05), "5%")
			local base = StatsConfig.CriticalDamage
			local groups = Sheet.Rows(block({ CriticalDamage = base + 0.2, Lifesteal = StatsConfig.Lifesteal.Cap + 0.05 }), { { Source = "MainHand", Stat = "CriticalDamage", Value = 0.2 } }, nil)
			local cd = row(groups, "CriticalDamage")
			t.Equal("Critical Damage: what a critical adds, its base first, then its sources", if cd then `{cd.Value}|{cd.Under or ""}` else nil, `+{Sheet.Percent(base + 0.2)}|Base {Sheet.Percent(base)} · Gear 20%`)
			local steal = row(groups, "Lifesteal")
			t.Check("Lifesteal past its cap says what counts", steal ~= nil and string.find(steal.Under or "", `at most {Sheet.Percent(StatsConfig.Lifesteal.Cap)} counts`, 1, true) ~= nil, if steal then steal.Under else "none")
			local none = row(groups, "ElementalAttack")
			t.Equal("no element: no second hit", if none then none.Under else nil, "No element: no second hit")
			local fire = row(Sheet.Rows(block({ Element = "Fire", ElementalAttack = 30 }), {}, nil), "ElementalAttack")
			t.Equal("an element: its second hit", if fire then `{fire.Value}|{fire.Under or ""}` else nil, "30|A second hit in Fire, past Defence")
			local wind = Passives.ById.rook
			local reduction = row(Sheet.Rows(block(), {}, wind), "DamageReduction")
			t.Equal("Second Wind's reduction, with its condition", if reduction then `{reduction.Value}|{reduction.Under or ""}` else nil, `{Sheet.Percent(wind.Share)}|Second Wind, below {Sheet.Percent(wind.Below :: number)} health`)
			local tempo = row(Sheet.Rows(block(), {}, Passives.ById.lyric), "DamageReduction")
			t.Equal("a passive of another kind gives none", if tempo then tempo.Value else nil, "0%")
		end,
	},
	{
		Name = "Sheet: each line keeps its sources, Own, Level, Stars and Gear, adding to its number",
		Run = function(t: any)
			local lines: { Stats.Line } = {
				{ Source = "Base", Stat = "Health", Value = 1000 },
				{ Source = "Stars", Stat = "Health", Value = 200 },
				{ Source = "Helmet", Stat = "Health", Value = 30 },
				{ Source = "Ring1", Stat = "Health", Value = 4 },
				{ Source = "Level", Stat = "Regen", Value = 4.26 },
			}
			local groups = Sheet.Rows(block(), lines, nil)
			local health = row(groups, "Health")
			t.Equal("Own, Stars and both slots as Gear", if health then health.Under else nil, "Own 1,000 · Stars 200 · Gear 34")
			local regen = row(groups, "Regen")
			t.Equal("Regen's source to a tenth", if regen then regen.Under else nil, "Level 4.3")
			local attack = row(groups, "Attack")
			t.Equal("a stat with no lines has nothing under it", if attack then attack.Under else "missing", nil)
		end,
	},
}
