--!strict
-- Logic cases (pure): Overview's stat sheet (docs/research/rework-2026-11-16.md, part 4; docs/ui.md, 5, "Overview's stat
-- sheet"; Rules.Sheet), a plain list [the director, 2026-11-15, night: "Plain list, no taps"]: the Basic Attributes with
-- the Main marked, then the Battle Attributes in Core, Offence and Defence paired, and Sustain; every stat a line, a zero
-- as 0, its name and one total, a rating its percent alone [the director, 2026-11-17, by 00:17], its chance or effect the
-- hit's own against the even foe, never over its ceiling; the percents, Critical Damage without a ceiling; Damage Reduction only what holds at
-- all times; and on every Voidkin each line its block's total as shown.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Sheet = require(Shared.Rules.Sheet)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Growth = require(Shared.Rules.Growth)
local StatsConfig = require(Shared.Config.Stats)
local Attributes = require(Shared.Definitions.Attributes)
local Voidkin = require(Shared.Definitions.Voidkin)
local VoidkinConfig = require(Shared.Config.Voidkin)

local LEVEL = 12

local RATED = { "Hit", "Dodge", "Critical", "Block", "Penetration", "CriticalResist", "ElementalResist" }

local function block(change: { [string]: any }?): Stats.Block
	local b = Stats.Empty(LEVEL)
	b.Def, b.Type, b.Class, b.Element, b.Main = "rook", "Blaze", "Warrior", "", "Strength"
	b.Health, b.Attack, b.Defence, b.Regen, b.Speed, b.Poise = 1234, 150, 60, 4.26, 16, 100
	b.Attributes = { Strength = 1234.4, Endurance = 0 }
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

-- A number as it's shown, read back: "1,234" 1234, "17 every 8 s" 17, "+50%" 50, "ignores 8.1% Defence" 8.1.
local function readBack(said: string): number
	local digits = said:gsub(",", ""):match("%-?[%d%.]+")
	return tonumber(digits) or -1
end

-- What a total may say: its number, a percent's sign, and Regen's and Speed's units. Nothing else.
local function plain(said: string): boolean
	return string.match(said, "^%+?[%d,%.]+%%?$") ~= nil
		or string.match(said, "^[%d,%.]+ every %d+ s$") ~= nil
		or string.match(said, "^[%d%.]+ studs a second$") ~= nil
end

local function keys(each: Sheet.Row): string
	local out = {}
	for key in each :: any do
		table.insert(out, key)
	end
	table.sort(out)
	return table.concat(out, ",")
end

return {
	{
		Name = "Sheet: Overview's two headings, Strength and Endurance with the Main marked, then Core, Offence and Defence paired, and Sustain",
		Run = function(t: any)
			local groups = Sheet.Rows(block())
			t.Equal("four blocks", #groups, 4)
			t.Equal("the Basic Attributes first", groups[1].Heading, "Basic Attributes")
			local two, shown = {}, {}
			for _, each in groups[1].Rows do
				table.insert(two, each.Stat)
				table.insert(shown, each.Name)
			end
			t.Equal("the two, in order", table.concat(two, ","), table.concat(Attributes.Ids, ","))
			t.Equal("Strength and Endurance only, by name (TR36)", table.concat(shown, ","), "Strength,Endurance")
			local strength = row(groups, "Strength")
			t.Equal("an attribute's total, grouped, no decimals", if strength then strength.Value else nil, "1,234")
			t.Equal("its Main marked", if strength then strength.Main else nil, true)
			local marked = 0
			for _, each in groups[1].Rows do
				marked += if each.Main then 1 else 0
				t.Check(`{each.Stat}: its name players read`, each.Name == Attributes.ById[each.Stat].Name)
				t.Equal(`{each.Stat}: its total and nothing else`, keys(each), if each.Main then "Main,Name,Stat,Value" else "Name,Stat,Value")
			end
			t.Equal("one Main", marked, 1)
			t.Equal("an attribute at zero shows 0", (row(groups, "Endurance") :: Sheet.Row).Value, "0")
			t.Equal("then the Battle Attributes", groups[2].Heading, "Battle Attributes")
			t.Equal("one caption under it", groups[2].Caption, "chances against an even foe")
			t.Check("and nowhere else", groups[3].Caption == nil and groups[4].Caption == nil and groups[1].Caption == nil)
			local names = {}
			local count = 0
			for index = 2, #groups do
				table.insert(names, groups[index].Name)
				count += #groups[index].Rows
			end
			t.Equal("Core, Offense and Defense, Sustain", table.concat(names, ", "), "Core, Offense and Defense, Sustain")
			t.Equal("Defense, in American spelling (the director, 2026-11-17, 13:15)", Sheet.Row("Defence", Stats.Empty(1), nil).Name, "Defense")
			t.Equal("nineteen lines: every stat a source adds to, Speed, Poise, and the two from effects", count, #Stats.Names + 4)
			for _, name in Stats.Names do
				t.Check(`{name} has a line`, row(groups, name) ~= nil)
			end
			local core = {}
			for _, each in groups[2].Rows do
				table.insert(core, each.Stat)
			end
			t.Equal("Core", table.concat(core, ","), "Health,Attack,Defence,Speed,Poise")
			local pairs = { { "Hit", "Dodge" }, { "Critical", "CriticalResist" }, { "CriticalDamage", "CriticalGuard" }, { "ElementalAttack", "ElementalResist" }, { "DamageBonus", "DamageReduction" }, { "Penetration", "Block" } }
			local paired = groups[3].Rows
			for index, pair in pairs do
				local left, right = paired[index * 2 - 1], paired[index * 2]
				t.Check(`row {index}: {pair[1]} | {pair[2]}`, left and right and left.Stat == pair[1] and right.Stat == pair[2])
			end
			local sustain = groups[4].Rows
			t.Check("Sustain: Regen | Lifesteal", #sustain == 2 and sustain[1].Stat == "Regen" and sustain[2].Stat == "Lifesteal")
		end,
	},
	{
		Name = "Sheet: each line its name and one total, a zero as 0, a rating as its percent alone, Critical Immunity by its name",
		Run = function(t: any)
			local bare = block()
			local groups = Sheet.Rows(bare)
			t.Equal("Hit at no points: its chance, every hit that lands", (row(groups, "Hit") :: Sheet.Row).Value, Sheet.Percent(Sheet.Odds(bare).Hit))
			local critical = row(groups, "Critical") :: Sheet.Row
			t.Equal("Critical at no points: the floor every hit has", critical.Value, Sheet.Percent(StatsConfig.Caps.CriticalFloor))
			t.Equal("Dodge at no points: 0%", (row(groups, "Dodge") :: Sheet.Row).Value, "0%")
			t.Equal("a percent at zero shows 0%", (row(groups, "CriticalGuard") :: Sheet.Row).Value, "0%")
			t.Equal("Critical Immunity, by the director's name", (row(groups, "CriticalGuard") :: Sheet.Row).Name, "Critical Immunity")
			for _, said in Sheet.Said do
				t.Check(`{said}: never Critical Guard`, string.find(said, "Guard", 1, true) == nil, said)
			end
			t.Equal("Damage Bonus with nothing giving it: 0%", (row(groups, "DamageBonus") :: Sheet.Row).Value, "0%")
			t.Equal("points grouped", (row(groups, "Health") :: Sheet.Row).Value, "1,234")
			t.Equal("Regen as one burst (TR40): 4.26 a second, 8 s, a half", (row(groups, "Regen") :: Sheet.Row).Value, "17")
			t.Equal("and \"every 8 s\" under it (4.6)", (row(groups, "Regen") :: Sheet.Row).Under, "every 8 s")
			t.Equal("its name: HP Regen (the director, 2026-11-18)", (row(groups, "Regen") :: Sheet.Row).Name, "HP Regen")
			t.Equal("a small burst to a tenth", Sheet.Burst(1.5), "6.0")
			t.Equal("a card's Regen: the burst alone", Sheet.Amount("Regen", 4.26), "17")
			t.Equal("a card's Regen change: the burst's", Sheet.Change("Regen", 0.5), "+2.0")
			t.Equal("Speed in studs a second", (row(groups, "Speed") :: Sheet.Row).Value, "16 studs a second")
			t.Equal("the names players read", (row(groups, "CriticalDamage") :: Sheet.Row).Name, "Critical Damage")
			local rated = Sheet.Rows(block({ Dodge = 80, Critical = 1240, Block = 60, Penetration = 40, Hit = 50, CriticalResist = 30, ElementalResist = 20, Element = "Fire", ElementalAttack = 30 }))
			for index = 2, #rated do
				for _, each in rated[index].Rows do
					local isRated = table.find(RATED, each.Stat) ~= nil
					t.Equal(`{each.Stat}: its name and its one total, nothing to open`, keys(each), if each.Stat == "Regen" then "Name,Stat,Under,Value" else "Name,Stat,Value")
					t.Check(`{each.Stat}: only its number, a rating its percent alone, never "up to"`, plain(each.Value) and (not isRated or string.match(each.Value, "^[%d%.]+%%$") ~= nil), each.Value)
				end
			end
			for _, stat in RATED do
				t.Check(`{stat}: a rating the sheet shows as its share`, Sheet.Rated[stat] == true)
			end
			local odds = Sheet.Odds(block({ Dodge = 80, Critical = 1240, Block = 60, Penetration = 40, Hit = 50, CriticalResist = 30, ElementalResist = 20, Element = "Fire", ElementalAttack = 30 }))
			local big = row(rated, "Critical") :: Sheet.Row
			t.Equal("Critical 1,240 points: its chance alone, no points", big.Value, Sheet.Percent(odds.Critical))
			t.Equal("Penetration: what it ignores, a percent, no words", (row(rated, "Penetration") :: Sheet.Row).Value, Sheet.Percent(odds.Penetration))
			t.Equal("Critical Resist: what it takes off, a percent, no words", (row(rated, "CriticalResist") :: Sheet.Row).Value, Sheet.Percent(odds.CriticalResist))
			t.Equal("Elemental Resist: what it takes off, a percent, no words", (row(rated, "ElementalResist") :: Sheet.Row).Value, Sheet.Percent(odds.ElementalResist))
			t.Equal("Elemental Attack: its points, its element unsaid", (row(rated, "ElementalAttack") :: Sheet.Row).Value, "30")
			-- by hand: 100 Dodge at level 1 against the even foe's Hit, 40% x 100 / (100 + Hit + K)
			local one = Stats.Empty(1)
			one.Dodge = 100
			local want = StatsConfig.Caps.Dodge * 100 / (100 + StatsConfig.EvenFoe.Hit * Growth.G(1) + StatsConfig.RatingK * Growth.G(1))
			t.Check("100 Dodge at level 1, by hand", math.abs(Sheet.Odds(one).Dodge - want) < 1e-12, `{Sheet.Odds(one).Dodge} against {want}`)
		end,
	},
	{
		Name = "Sheet: each shown chance is the hit's own against the even foe, and never over its ceiling",
		Run = function(t: any)
			local caps = StatsConfig.Caps
			local ceiling = {
				Hit = 1,
				Dodge = caps.Dodge,
				Critical = caps.Critical,
				Block = caps.Block,
				Penetration = caps.Penetration,
				CriticalResist = caps.CriticalSpan,
				ElementalResist = caps.ElementalResist,
			}
			local blocks: { Stats.Block } = {}
			for _, def in Voidkin.List do
				for _, level in { 1, 12, 60 } do
					for _, stars in { 0, VoidkinConfig.MaxStars } do
						local owned = { Id = "k", Def = def.Id, Level = level, Xp = 0, Stars = stars, Copies = 0, Nickname = "", Preset = "", Favourite = false, Locked = false, Born = 0 }
						table.insert(blocks, (Stats.Resolve(owned :: any, nil, nil)))
					end
				end
			end
			local huge = block()
			for _, stat in RATED do
				(huge :: any)[stat] = 1e12
			end
			table.insert(blocks, huge)
			for _, made in blocks do
				local foe = Stats.EvenFoe(made.Level)
				local foeDodge, critical, _, penetration = Hit.Odds(made, foe)
				local dodge, foeCritical, blocked = Hit.Odds(foe, made)
				local bare = table.clone(made)
				bare.CriticalResist = 0
				local _, foeBare = Hit.Odds(foe, bare)
				local want = {
					Hit = 1 - foeDodge,
					Dodge = dodge,
					Critical = critical,
					Block = blocked,
					Penetration = penetration,
					CriticalResist = foeBare - foeCritical,
					ElementalResist = Stats.Chance(caps.ElementalResist, made.ElementalResist, 0, foe.Level),
				}
				local odds = Sheet.Odds(made)
				local groups = Sheet.Rows(made)
				local label = `{made.Def} {made.Level}`
				for _, stat in RATED do
					t.Equal(`{label} {stat}: the hit's own`, odds[stat], want[stat])
					t.Check(`{label} {stat}: under its ceiling`, odds[stat] >= 0 and odds[stat] <= ceiling[stat], `{odds[stat]}`)
					local shown = row(groups, stat) :: Sheet.Row
					t.Equal(`{label} {stat}: shown as it is`, shown.Value, Sheet.Percent(odds[stat]))
					t.Check(`{label} {stat}: never over 100%`, readBack(shown.Value) <= 100 + 1e-9, shown.Value)
				end
			end
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
		Name = "Sheet: a change never reads as none: a percent too fine for a tenth to a hundredth, then <0.01%; none is a dash",
		Run = function(t: any)
			t.Equal("a tenth and over: its percent", Sheet.Change("Hit", 0.0012), "+0.1%")
			t.Equal("under a twentieth of a percent: a hundredth", Sheet.Change("Hit", 0.0004), "+0.04%")
			t.Equal("a loss the same", Sheet.Change("Critical", -0.0004), "−0.04%")
			t.Equal("under a two-hundredth: <0.01%", Sheet.Change("Dodge", 0.00002), "+<0.01%")
			t.Equal("Critical Damage, a percent too", Sheet.Change("CriticalDamage", 0.0003), "+0.03%")
			t.Equal("points under a half: a tenth", Sheet.Change("Strength", 0.3), "+0.3")
			t.Equal("no change: a dash", Sheet.Change("Hit", 0), "–")
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
						local odds = Sheet.Odds(made)
						for _, group in Sheet.Rows(made) do
							for _, each in group.Rows do
								local raw = if Attributes.ById[each.Stat] then made.Attributes[each.Stat] elseif Sheet.Rated[each.Stat] then odds[each.Stat] else (made :: any)[each.Stat]
								local value = if type(raw) == "number" then raw else 0
								local percent = string.sub(each.Value, -1) == "%"
								local want = if percent then value * 100 elseif each.Stat == "Regen" then Stats.Burst(value) else value -- Regen shows its burst (TR40)
								local tenth = string.find(each.Value, "second", 1, true) ~= nil or (each.Stat == "Regen" and math.abs(want) < 10)
								local slack = if percent then (if math.abs(want) >= 10 then 0.5 else 0.05) elseif tenth then 0.05 else 0.5
								t.Check(`{def.Id} {level} {stars}: {each.Stat} {each.Value}`, plain(each.Value) and math.abs(readBack(each.Value) - want) <= slack + 1e-9)
							end
						end
					end
				end
			end
		end,
	},
}
