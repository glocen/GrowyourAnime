--!strict
-- Logic cases (pure): Overview's stat sheet (docs/ui.md, 5, "Overview's stat sheet", and "Stats, shown honestly";
-- Rules.Sheet), a plain list [the director, 2026-11-15, night: "Plain list, no taps"]: every stat in its three groups, a
-- zero as 0, its name and one total a line, never "up to", nothing else on it; the percents, Critical Damage without a
-- ceiling; Damage Reduction only what holds at all times; and on every Voidkin each line its block's total as shown.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Sheet = require(Shared.Rules.Sheet)
local Stats = require(Shared.Rules.Stats)
local StatsConfig = require(Shared.Config.Stats)
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

-- A number as it's shown, read back: "1,234" 1234, "4.3 a second" 4.3, "+50%" 50.
local function readBack(said: string): number
	local digits = said:gsub(",", ""):match("%-?[%d%.]+")
	return tonumber(digits) or -1
end

-- What a line may say: its number, a percent's sign, and Regen's and Speed's units. Nothing else.
local function plain(said: string): boolean
	return string.match(said, "^%+?[%d,%.]+%%?$") ~= nil
		or string.match(said, "^[%d%.]+ a second$") ~= nil
		or string.match(said, "^[%d%.]+ studs a second$") ~= nil
end

return {
	{
		Name = "Sheet: Overview shows every stat in three groups, its name and one total a line, a zero as 0, nothing else",
		Run = function(t: any)
			local groups = Sheet.Rows(block())
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
			t.Equal("Damage Bonus with nothing giving it: 0%", if bonus then bonus.Value else nil, "0%")
			local health = row(groups, "Health")
			t.Equal("points grouped", if health then health.Value else nil, "1,234")
			local regen = row(groups, "Regen")
			t.Equal("Regen to a tenth, a second", if regen then regen.Value else nil, "4.3 a second")
			local speed = row(groups, "Speed")
			t.Equal("Speed in studs a second", if speed then speed.Value else nil, "16 studs a second")
			t.Equal("the names players read", if row(groups, "CriticalDamage") then (row(groups, "CriticalDamage") :: Sheet.Row).Name else nil, "Critical Damage")
			local rated = Sheet.Rows(block({ Dodge = 80, Critical = 120, Block = 60, Penetration = 40, Hit = 50, CriticalResist = 30, ElementalResist = 20, Element = "Fire", ElementalAttack = 30 }))
			for _, group in rated do
				for _, each in group.Rows do
					local keys = {}
					for key in each :: any do
						table.insert(keys, key)
					end
					table.sort(keys)
					t.Equal(`{each.Stat}: its name and its total, nothing to open`, table.concat(keys, ","), "Name,Stat,Value")
					t.Check(`{each.Stat}: only its number, never "up to" or a note`, plain(each.Value), each.Value)
				end
			end
			local dodge = row(rated, "Dodge")
			t.Equal("a rating's line: its points alone", if dodge then dodge.Value else nil, "80")
			local fire = row(rated, "ElementalAttack")
			t.Equal("Elemental Attack: its points, its element unsaid", if fire then fire.Value else nil, "30")
		end,
	},
	{
		Name = "Sheet: percents, Critical Damage without a ceiling, Lifesteal past its cap as it stands",
		Run = function(t: any)
			t.Equal("whole from 10%", Sheet.Percent(0.254), "25%")
			t.Equal("one place under it", Sheet.Percent(0.078), "7.8%")
			t.Equal("never a trailing .0", Sheet.Percent(0.05), "5%")
			t.Equal("grouped when it's large", Sheet.Percent(200), "20,000%")
			local base = StatsConfig.CriticalDamage
			local groups = Sheet.Rows(block({ CriticalDamage = base + 0.2, Lifesteal = StatsConfig.Lifesteal.Cap + 0.05 }))
			local cd = row(groups, "CriticalDamage")
			t.Equal("Critical Damage: one total, what a critical adds", if cd then cd.Value else nil, `+{Sheet.Percent(base + 0.2)}`)
			local far = row(Sheet.Rows(block({ CriticalDamage = 200 })), "CriticalDamage")
			t.Equal("20,000%: no ceiling", if far then far.Value else nil, "+20,000%")
			local steal = row(groups, "Lifesteal")
			t.Equal("Lifesteal past its cap: its total, nothing said of the cap", if steal then steal.Value else nil, Sheet.Percent(StatsConfig.Lifesteal.Cap + 0.05))
		end,
	},
	{
		Name = "Sheet: Damage Reduction shows only what holds at all times: Second Wind's, below 30% health, isn't in it",
		Run = function(t: any)
			local owned = { Id = "k", Def = "rook", Level = LEVEL, Xp = 0, Stars = 0, Copies = 0, Nickname = "", Preset = "", Favourite = false, Locked = false, Born = 0 }
			local made = Stats.Resolve(owned :: any, nil, nil)
			local reduction = row(Sheet.Rows(made), "DamageReduction")
			t.Equal("Rook, whose passive is Second Wind: 0%", if reduction then reduction.Value else nil, "0%")
		end,
	},
	{
		Name = "Sheet: on every Voidkin, at its levels and stars, each line is its total as its block has it",
		Run = function(t: any)
			for _, def in Voidkin.List do
				for _, level in { 1, 12, 60 } do
					for _, stars in { 0, VoidkinConfig.MaxStars } do
						local owned = { Id = "k", Def = def.Id, Level = level, Xp = 0, Stars = stars, Copies = 0, Nickname = "", Preset = "", Favourite = false, Locked = false, Born = 0 }
						local made = Stats.Resolve(owned :: any, nil, nil)
						for _, group in Sheet.Rows(made) do
							for _, each in group.Rows do
								local raw = (made :: any)[each.Stat]
								local value = if type(raw) == "number" then raw else 0
								local percent = string.sub(each.Value, -1) == "%"
								local want = if percent then value * 100 else value
								local slack = if percent then (if math.abs(want) >= 10 then 0.5 else 0.05) elseif string.find(each.Value, "second", 1, true) then 0.05 else 1
								t.Check(`{def.Id} {level} {stars}: {each.Stat} {each.Value}`, plain(each.Value) and math.abs(readBack(each.Value) - want) <= slack + 1e-9)
							end
						end
					end
				end
			end
		end,
	},
}
