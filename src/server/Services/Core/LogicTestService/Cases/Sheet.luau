--!strict
-- Logic cases (pure): Overview's stat sheet (docs/ui.md, 5, "Overview's stat sheet", and "Stats, shown honestly";
-- Rules.Sheet): every stat in its three groups, a zero as 0, one total a line and never "up to", a tap's sources in their
-- order and adding to the total as shown, a rating's chance last against a foe of its level with the same points (as
-- Rules.Hit sums it), the percents, Critical Damage without a ceiling, and a passive's Damage Reduction with its condition.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Sheet = require(Shared.Rules.Sheet)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local StatsConfig = require(Shared.Config.Stats)
local Passives = require(Shared.Definitions.Passives)
local Voidkin = require(Shared.Definitions.Voidkin)
local VoidkinConfig = require(Shared.Config.Voidkin)

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

-- A tap's sources as one string, "Name Value · Name Value".
local function listed(each: Sheet.Row?): string?
	if each == nil then
		return nil
	end
	local said = {}
	for _, source in each.Sources do
		table.insert(said, `{source.Name} {source.Value}`)
	end
	return table.concat(said, " · ")
end

local function last(each: Sheet.Row?): string?
	return if each then each.Notes[#each.Notes] else nil
end

-- A number as it's shown, read back: "1,234" 1234, "4.3 a second" 4.3, "+50%" 50.
local function readBack(said: string): number
	local digits = said:gsub(",", ""):match("%-?[%d%.]+")
	return tonumber(digits) or -1
end

return {
	{
		Name = "Sheet: Overview shows every stat in three groups, one total a line, a zero as 0, never 'up to'",
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
			local critical = row(groups, "Critical")
			t.Equal("Critical at no points: its points alone, 0", if critical then critical.Value else nil, "0")
			local guard = row(groups, "CriticalGuard")
			t.Equal("a percent at zero shows 0%", if guard then guard.Value else nil, "0%")
			local bonus = row(groups, "DamageBonus")
			t.Equal("Damage Bonus with nothing giving it: 0%, no source", if bonus then `{bonus.Value}|{listed(bonus)}` else nil, "0%|")
			local health = row(groups, "Health")
			t.Equal("points grouped", if health then health.Value else nil, "1,234")
			local regen = row(groups, "Regen")
			t.Equal("Regen to a tenth, a second", if regen then regen.Value else nil, "4.3 a second")
			local speed = row(groups, "Speed")
			t.Equal("Speed in studs a second", if speed then speed.Value else nil, "16 studs a second")
			t.Equal("the names players read", if row(groups, "CriticalDamage") then (row(groups, "CriticalDamage") :: Sheet.Row).Name else nil, "Critical Damage")
			local rated = Sheet.Rows(block({ Dodge = 80, Critical = 120, Block = 60, Penetration = 40, Hit = 50, CriticalResist = 30, ElementalResist = 20 }), {}, nil)
			for _, group in rated do
				for _, each in group.Rows do
					t.Check(`{each.Stat}: never "up to"`, not string.find(`{each.Value} {listed(each)} {table.concat(each.Notes, " ")}`, "up to", 1, true))
					t.Check(`{each.Stat}: a tap always says something`, #each.Sources + #each.Notes > 0)
				end
			end
			local dodge = row(rated, "Dodge")
			t.Equal("a rating's line: its points alone", if dodge then dodge.Value else nil, "80")
		end,
	},
	{
		Name = "Sheet: a rating's chance is last on its tap, against a foe of its level with the same points, as a hit sums it",
		Run = function(t: any)
			local near = function(a: number?, b: number): boolean
				return a ~= nil and math.abs(a - b) < 1e-9
			end
			local mine = block({ Dodge = 80, Critical = 120, Block = 60, Penetration = 40, ElementalResist = 50, Hit = 50, CriticalResist = 30 })
			local function foe(change: { [string]: number }): Stats.Block
				local b = Stats.Empty(LEVEL)
				for key, value in change do
					(b :: any)[key] = value
				end
				return b
			end
			local dodge = Hit.Odds(foe({ Hit = 80 }), mine)
			local _, critical = Hit.Odds(mine, foe({ CriticalResist = 120 }))
			local _, _, blocked = Hit.Odds(foe({ Hit = 60 }), mine)
			local _, _, _, penetration = Hit.Odds(mine, foe({}))
			t.Check("Dodge, as a foe's swing with the same Hit meets it", near(Sheet.Chance("Dodge", mine, 80), dodge))
			t.Check("Critical, its floor counted, against the same Critical Resist", near(Sheet.Chance("Critical", mine, 120), critical))
			t.Check("Block, against the same Hit", near(Sheet.Chance("Block", mine, 60), blocked))
			t.Check("Penetration meets nothing", near(Sheet.Chance("Penetration", mine, 40), penetration))
			t.Check("Elemental Resist meets nothing", near(Sheet.Chance("ElementalResist", mine, 50), Stats.Chance(StatsConfig.Caps.ElementalResist, 50, 0, LEVEL)))
			t.Equal("a stat with no chance of its own has none", Sheet.Chance("Hit", mine), nil)
			local groups = Sheet.Rows(mine, {}, nil)
			t.Equal("Dodge's last line", last(row(groups, "Dodge")), `Against a level {LEVEL} foe with 80 Hit: {Sheet.Percent(dodge)} of its hits dodged`)
			t.Equal("Block's last line", last(row(groups, "Block")), `Against a level {LEVEL} foe with 60 Hit: {Sheet.Percent(blocked)} of its hits blocked`)
			t.Equal("Critical's last line", last(row(groups, "Critical")), `Against a level {LEVEL} foe with 120 Critical Resist: {Sheet.Percent(critical)} of hits critical`)
			t.Equal("Penetration's last line", last(row(groups, "Penetration")), `Against a level {LEVEL} foe: {Sheet.Percent(penetration)} of its Defence ignored`)
			-- Hit and Critical Resist: what a foe with the same points is left with.
			local theirDodge = Hit.Odds(mine, foe({ Dodge = 50, Block = 50 }))
			local _, _, theirBlock = Hit.Odds(mine, foe({ Dodge = 50, Block = 50 }))
			t.Equal("Hit's last line", last(row(groups, "Hit")), `Against a level {LEVEL} foe with 50 Dodge and Block: it dodges {Sheet.Percent(theirDodge)}, blocks {Sheet.Percent(theirBlock)}`)
			local _, theirCritical = Hit.Odds(foe({ Critical = 30 }), mine)
			t.Equal("Critical Resist's last line", last(row(groups, "CriticalResist")), `Against a level {LEVEL} foe with 30 Critical: {Sheet.Percent(theirCritical)} of its hits critical`)
			local hit = row(groups, "Hit")
			t.Check("Hit says it lowers a foe's, before its chance", hit ~= nil and hit.Notes[1] == "Lowers a foe's Dodge and Block")
			local none = row(Sheet.Rows(block(), {}, nil), "Critical")
			t.Equal("Critical at no points: the floor shows on its tap", last(none), `Against a level {LEVEL} foe with 0 Critical Resist: {Sheet.Percent(StatsConfig.Caps.CriticalFloor)} of hits critical`)
			t.Equal("a stat that isn't a rating has no chance line", last(row(groups, "Attack")), "Nothing gives it yet")
		end,
	},
	{
		Name = "Sheet: percents, Critical Damage without a ceiling, an element, the lifesteal's cap and a passive's condition",
		Run = function(t: any)
			t.Equal("whole from 10%", Sheet.Percent(0.254), "25%")
			t.Equal("one place under it", Sheet.Percent(0.078), "7.8%")
			t.Equal("never a trailing .0", Sheet.Percent(0.05), "5%")
			t.Equal("grouped when it's large", Sheet.Percent(200), "20,000%")
			local base = StatsConfig.CriticalDamage
			local groups = Sheet.Rows(block({ CriticalDamage = base + 0.2, Lifesteal = StatsConfig.Lifesteal.Cap + 0.05 }), { { Source = "Item:Main Hand", Stat = "CriticalDamage", Value = 0.2 } }, nil)
			local cd = row(groups, "CriticalDamage")
			t.Equal("Critical Damage: one total, what a critical adds", if cd then cd.Value else nil, `+{Sheet.Percent(base + 0.2)}`)
			t.Equal("its base first on its tap, then the slot", listed(cd), `Base +{Sheet.Percent(base)} · Main Hand +20%`)
			t.Equal("and what it multiplies a critical by", if cd then cd.Notes[1] else nil, "A critical hit does x1.7, less a foe's Critical Guard, never under x1")
			local far = row(Sheet.Rows(block({ CriticalDamage = 200 }), { { Source = "Item:Main Hand", Stat = "CriticalDamage", Value = 200 - base } }, nil), "CriticalDamage")
			t.Equal("20,000%: no ceiling", if far then far.Value else nil, "+20,000%")
			t.Equal("x201", if far then far.Notes[1] else nil, "A critical hit does x201, less a foe's Critical Guard, never under x1")
			local steal = row(groups, "Lifesteal")
			t.Check("Lifesteal past its cap says what counts", steal ~= nil and table.find(steal.Notes, `At most {Sheet.Percent(StatsConfig.Lifesteal.Cap)} counts`) ~= nil)
			local none = row(groups, "ElementalAttack")
			t.Equal("no element: no second hit", last(none), "No element: no second hit")
			local fire = row(Sheet.Rows(block({ Element = "Fire", ElementalAttack = 30 }), {}, nil), "ElementalAttack")
			t.Equal("an element: its second hit", if fire then `{fire.Value}|{last(fire)}` else nil, "30|A second hit in Fire, past Defence")
			local wind = Passives.ById.rook
			local reduction = row(Sheet.Rows(block(), {}, wind), "DamageReduction")
			t.Equal("Second Wind's reduction: the total, and the passive as its source with its condition", if reduction then `{reduction.Value}|{listed(reduction)}` else nil, `{Sheet.Percent(wind.Share)}|Second Wind, below {Sheet.Percent(wind.Below :: number)} health {Sheet.Percent(wind.Share)}`)
			local tempo = row(Sheet.Rows(block(), {}, Passives.ById.lyric), "DamageReduction")
			t.Equal("a passive of another kind gives none", if tempo then `{tempo.Value}|{listed(tempo)}` else nil, "0%|")
		end,
	},
	{
		Name = "Sheet: a tap lists the sources in order, the base and the level apart, adding to the total as it's shown",
		Run = function(t: any)
			local lines: { Stats.Line } = {
				{ Source = "Item:Helmet", Stat = "Health", Value = 30 },
				{ Source = "Base", Stat = "Health", Value = 1000 },
				{ Source = "Forge", Stat = "Health", Value = 7 },
				{ Source = "Item:Ring I", Stat = "Health", Value = 4 },
				{ Source = "Level", Stat = "Health", Value = 150 },
				{ Source = "Item:Main Hand", Stat = "Health", Value = 13 },
				{ Source = "Stars", Stat = "Health", Value = 30 },
				{ Source = "Base", Stat = "Regen", Value = 2.04 },
				{ Source = "Level", Stat = "Regen", Value = 2.22 },
				{ Source = "Base", Stat = "Attack", Value = 400.4 },
				{ Source = "Level", Stat = "Attack", Value = 400.4 },
				{ Source = "Stars", Stat = "Attack", Value = 400.4 },
			}
			local groups = Sheet.Rows(block({ Attack = 1201.2 }), lines, nil)
			local health = row(groups, "Health")
			t.Equal(
				"the base, the level with its number, the stars, the slots as they stand, then a source to come",
				listed(health),
				`Base 1,000 · Level {LEVEL} 150 · Stars 30 · Main Hand 13 · Helmet 30 · Ring I 4 · Forge 7`
			)
			local regen = row(groups, "Regen")
			t.Equal("Regen's to a tenth, adding to its 4.3", listed(regen), `Base 2.1 · Level {LEVEL} 2.2`)
			local attack = row(groups, "Attack")
			t.Equal("three of 400.4 read 401, 400, 400: they add to the 1,201 shown", if attack then `{attack.Value}|{listed(attack)}` else nil, `1,201|Base 401 · Level {LEVEL} 400 · Stars 400`)
			local defence = row(groups, "Defence")
			t.Equal("a stat with no lines lists nothing and says so", if defence then `{listed(defence)}|{last(defence)}` else nil, "|Nothing gives it yet")
		end,
	},
	{
		Name = "Sheet: on every Voidkin, at its levels and stars, each line's sources add to its total as shown",
		Run = function(t: any)
			for _, def in Voidkin.List do
				for _, level in { 1, 12, 60 } do
					for _, stars in { 0, VoidkinConfig.MaxStars } do
						local owned = { Id = "k", Def = def.Id, Level = level, Xp = 0, Stars = stars, Copies = 0, Nickname = "", Preset = "", Favourite = false, Locked = false, Born = 0 }
						local made, lines = Stats.Resolve(owned :: any, nil, nil)
						for _, group in Sheet.Rows(made, lines, nil) do
							for _, each in group.Rows do
								if #each.Sources > 0 and each.Stat ~= "DamageReduction" then
									local sum = 0
									for _, source in each.Sources do
										sum += readBack(source.Value)
									end
									t.Check(`{def.Id} {level} {stars}: {each.Stat} {each.Value} = {listed(each)}`, math.abs(sum - readBack(each.Value)) < 1e-6)
								end
							end
						end
						local health = row(Sheet.Rows(made, lines, nil), "Health")
						local hasLevel = health ~= nil and string.find(listed(health) or "", `Level {level} `, 1, true) ~= nil
						t.Check(`{def.Id} {level}: the level's own line {if level == 1 then "absent at level 1" else "there"}`, hasLevel == (level > 1))
					end
				end
			end
		end,
	},
}
