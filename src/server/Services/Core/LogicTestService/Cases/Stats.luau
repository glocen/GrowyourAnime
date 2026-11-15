--!strict
-- Stats cases (pure): the curve, experience, and the resolver. Every source adds flat points and none multiplies another
-- (docs/balance.md, "The one rule"); rarity and class touch the own base only; stars are a share of the own base, linear;
-- an item's lines add as they are. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Collection = require(Shared.Rules.Collection)
local Voidkin = require(Shared.Definitions.Voidkin)
local StatsConfig = require(Shared.Config.Stats)
local GrowthConfig = require(Shared.Config.Growth)
local VoidkinConfig = require(Shared.Config.Voidkin)

local NOW = 1_800_000_000

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-9) * math.max(1, math.abs(b))
end

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function first(rarity: string, class: string): string?
	for _, row in Voidkin.List do
		if row.Rarity == rarity and row.Class == class then
			return row.Id
		end
	end
	return nil
end

-- A voidkin owned by `data`, at a level and stars.
local function own(data: Profile.Data, def: string, level: number, stars: number): Profile.OwnedVoidkin
	local id = Collection.Uncover(data, def, NOW).Id
	local owned = data.Voidkin[id]
	owned.Level, owned.Stars = level, stars
	return owned
end

local function give(data: Profile.Data, slot: string, lines: { { Stat: string, Value: number } }): string
	local id = Profile.NewId(data)
	data.Items[id] = { Id = id, Def = "case_item", Tier = 1, Rarity = "Common", Lines = lines :: any, Sockets = {}, Jewel = "" }
	data.Presets[1].Slots[slot] = id
	return id
end

-- The lines of one source, by stat.
local function from(lines: { Stats.Line }, source: string): { [string]: number }
	local out = {}
	for _, line in lines do
		if line.Source == source then
			out[line.Stat] = (out[line.Stat] or 0) + line.Value
		end
	end
	return out
end

local function same(a: { [string]: number }, b: { [string]: number }): boolean
	for k, v in a do
		if b[k] ~= v then
			return false
		end
	end
	for k, v in b do
		if a[k] ~= v then
			return false
		end
	end
	return true
end

return {
	{
		Name = "Stats: the curve runs from 1 to about 22",
		Run = function(t: any)
			t.Equal("G(1)", Growth.G(1), 1)
			t.Check("G(60) as the seeds' simulation", near(Growth.G(60), 22.004), `{Growth.G(60)}`)
			t.Check("G(7) as the simulation", near(Growth.G(7), 1.864), `{Growth.G(7)}`)
			for level = 2, GrowthConfig.MaxLevel do
				t.Check(`rises at {level}`, Growth.G(level) > Growth.G(level - 1))
			end
		end,
	},
	{
		Name = "Stats: experience follows the pace table",
		Run = function(t: any)
			local early = #GrowthConfig.Early
			t.Equal("ground 1 is fifty kills a level, past the first fights", Growth.KillsPerLevel(early + 1), 50)
			for level, kills in GrowthConfig.Early do
				t.Equal(`a new account's level {level} takes its early kills`, Growth.KillsPerLevel(level), kills)
			end
			t.Check("the lead reaches level 2 inside its first pack of three", Growth.KillsPerLevel(1) < 3, `{Growth.KillsPerLevel(1)} kills`)
			t.Equal("a level-1 kill", Growth.XpPerKill(1), GrowthConfig.XpPerKillPerG)
			t.Equal("level 1 to 2", Growth.XpToNext(1), Growth.KillsPerLevel(1) * GrowthConfig.XpPerKillPerG)
			t.Equal("no level past the last", Growth.XpToNext(GrowthConfig.MaxLevel), nil)
			local data = fresh()
			local owned = own(data, "rook", 1, 0)
			local need = Growth.XpToNext(1) :: number
			t.Equal("short of a level", Growth.AddXp(owned, need - 1), 0)
			t.Equal("one more", Growth.AddXp(owned, 1), 1)
			t.Check("level 2, nothing carried", owned.Level == 2 and owned.Xp == 0)
			local big = 0
			for level = 2, 4 do
				big += Growth.XpToNext(level) :: number
			end
			t.Equal("three levels at once", Growth.AddXp(owned, big + 7), 3)
			t.Check("the rest carried", owned.Level == 5 and owned.Xp == 7)
			for _, bad in { 0, -5, 0 / 0, math.huge } do
				t.Equal(`nothing from {bad}`, Growth.AddXp(owned, bad), 0)
			end
			t.Check("unchanged", owned.Level == 5 and owned.Xp == 7)
			owned.Level = GrowthConfig.MaxLevel - 1
			Growth.AddXp(owned, 10 ^ 12)
			t.Check("the last level holds nothing", owned.Level == GrowthConfig.MaxLevel and owned.Xp == 0)
		end,
	},
	{
		-- TR14 (the director, 2026-11-14, night: "the level cap is 125 but the launch is designed for level 60").
		Name = "Stats: the cap is 125, the same curve on past 60, a level there at the last ground's pace",
		Run = function(t: any)
			t.Equal("the last level", GrowthConfig.MaxLevel, 125)
			t.Check("G(125), the curve run on", near(Growth.G(125), 77.384), `{Growth.G(125)}`)
			for _, level in { 60, 61, 90, 124 } do
				t.Check(`a level past {level}`, type(Growth.XpToNext(level)) == "number" and (Growth.XpToNext(level) :: number) > (Growth.XpToNext(level - 1) :: number))
				t.Equal(`level {level} at the last ground's kills`, Growth.KillsPerLevel(level), Growth.KillsPerLevel(55))
			end
			local data = fresh()
			local owned = own(data, "rook", 60, 0)
			t.Equal("60 goes on to 61", Growth.AddXp(owned, Growth.XpToNext(60) :: number), 1)
			t.Check("at 61, nothing carried", owned.Level == 61 and owned.Xp == 0)
			owned.Level = GrowthConfig.MaxLevel
			t.Equal("a Voidkin at the cap resolves there", Stats.Resolve(owned, nil, nil).Level, 125)
		end,
	},
	{
		-- TR14 (docs/design.md, "Speed"): a lead's walk in a fight, by class with a nudge of its own, from nothing else.
		Name = "Stats: Speed is the class's walk with the Voidkin's own nudge, at any level, and nothing else adds to it",
		Run = function(t: any)
			local speed = StatsConfig.Speed
			local data = fresh()
			for _, row in Voidkin.List do
				local class = speed.Class[row.Class]
				local nudge = row.Speed or 0
				t.Check(`{row.Id}: its class has a walk`, class ~= nil, row.Class)
				t.Check(`{row.Id}: its nudge is whole and at most {speed.Nudge} either way`, nudge == math.floor(nudge) and math.abs(nudge) <= speed.Nudge, `{nudge}`)
				local owned = own(data, row.Id, 1, 0)
				local at1 = Stats.Resolve(owned, nil, nil).Speed
				t.Equal(`{row.Id}: its Speed`, at1, (class or 0) + nudge)
				owned.Level, owned.Stars = GrowthConfig.MaxLevel, VoidkinConfig.MaxStars
				t.Equal(`{row.Id}: the same at the cap, with every star`, Stats.Resolve(owned, nil, nil).Speed, at1)
			end
			t.Equal("Kirra: the Assassin's and one", Stats.Resolve(own(data, "kirra", 5, 0), nil, nil).Speed, speed.Class.Assassin + 1)
			t.Equal("a Tank plods", Stats.Resolve(own(data, first("Common", "Tank") :: string, 5, 0), nil, nil).Speed, speed.Class.Tank)
			t.Equal("Rook walks a Warrior's", Stats.Resolve(own(data, "rook", 5, 0), nil, nil).Speed, speed.Class.Warrior)
			t.Check("the Assassin closes fastest, the Tank slowest", speed.Class.Assassin > speed.Class.Warrior and speed.Class.Warrior > speed.Class.Tank)
			-- Nothing else: no source names it, and gear's line is dropped.
			t.Check("not a stat any source adds to", table.find(Stats.Names, "Speed") == nil)
			local rook = own(data, "rook", 5, 0)
			give(data, "Weapon", { { Stat = "Speed", Value = 50 } })
			t.Equal("an item's Speed line adds nothing", Stats.Resolve(rook, data.Presets[1], data).Speed, speed.Class.Warrior)
			t.Equal("an enemy walks its kind's, not a Speed", Stats.Enemy("brawler", 5).Speed, 0)
			t.Equal("an unknown class walks nothing of its own", Stats.SpeedOf({ Id = "x", Name = "X", Rarity = "Common", Type = "Strength", Class = "Nobody", Element = "", Zone = 1, Aptitude = 1, Speed = 1, Words = { Signature = "", Passive = "" } }), 0)
		end,
	},
	{
		Name = "Stats: a Common Warrior at level 1 is the seeds' base",
		Run = function(t: any)
			local def = first("Common", "Warrior")
			t.Check("the roster has one", def ~= nil)
			local data = fresh()
			local block = Stats.Resolve(own(data, def :: string, 1, 0), nil, nil)
			t.Equal("health", block.Health, StatsConfig.Base.Health)
			t.Equal("attack", block.Attack, StatsConfig.Base.Attack)
			t.Equal("defence", block.Defence, StatsConfig.Base.Defence)
			t.Equal("no rating from nowhere", block.Critical + block.Dodge + block.Hit, 0)
			t.Equal("the critical's base extra", block.CriticalDamage, StatsConfig.CriticalDamage)
			t.Equal("a Warrior's poise", block.Poise, StatsConfig.Poise.Warrior)
			t.Equal("its Regen, the seed's at level 1", block.Regen, StatsConfig.Regen.Base)
		end,
	},
	{
		-- TR12: Regen is a value a second from the level (G), never a share; a Healer's class carries more; rarity and
		-- stars leave it alone (docs/design.md, "Health carries").
		Name = "Stats: TR12, Regen grows with the level, a Healer carries more, and rarity and stars leave it alone",
		Run = function(t: any)
			local data = fresh()
			local regen = StatsConfig.Regen
			t.Check("a Healer's class carries more", (regen.Class.Healer or 1) > 1)
			for _, row in Voidkin.List do
				for _, level in { 1, 9, 30 } do
					local owned = own(data, row.Id, level, 0)
					local block, lines = Stats.Resolve(owned, nil, nil)
					local want = regen.Base * (regen.Class[row.Class] or 1) * Growth.G(level)
					t.Check(`{row.Id} at {level}`, near(block.Regen, want), `{block.Regen}, wanted {want}`)
					local first = regen.Base * (regen.Class[row.Class] or 1) * Growth.G(1)
				t.Check(`{row.Id} at {level}: its base, the level-1 figure`, near(from(lines, "Base").Regen or 0, first))
				t.Check(`{row.Id} at {level}: the level adds the rest`, near((from(lines, "Level").Regen or 0) + first, want))
					owned.Stars = VoidkinConfig.MaxStars
					t.Check(`{row.Id} at {level}: stars leave it alone`, near(Stats.Resolve(owned, nil, nil).Regen, want))
				end
			end
			local rook = Stats.Resolve(own(data, "rook", 15, 0), nil, nil)
			t.Check("a value, not a share: the same Regen whatever the health", rook.Regen > 0 and near(rook.Regen, regen.Base * Growth.G(15)))
			t.Equal("an enemy has none", Stats.Enemy("brawler", 5).Regen, 0)
		end,
	},
	{
		Name = "Stats: rarity, class and level shape the own base only",
		Run = function(t: any)
			local data = fresh()
			give(data, "Main Hand", { { Stat = "Attack", Value = 40 }, { Stat = "Critical", Value = 12 } })
			for _, row in Voidkin.List do
				local owned = own(data, row.Id, 9, 0)
				local block, lines = Stats.Resolve(owned, data.Presets[1], data)
				local g = Growth.G(9)
				for _, stat in { "Health", "Attack", "Defence" } do
					local expected = StatsConfig.Base[stat] * StatsConfig.Rarity[row.Rarity] * StatsConfig.Class[row.Class][stat] * g
					local first = StatsConfig.Base[stat] * StatsConfig.Rarity[row.Rarity] * StatsConfig.Class[row.Class][stat] * Growth.G(1)
					t.Check(`{row.Id} {stat} base, at level 1`, near(from(lines, "Base")[stat], first))
					t.Check(`{row.Id} {stat}: base and level make the own figure`, near(from(lines, "Base")[stat] + from(lines, "Level")[stat], expected))
					t.Check(`{row.Id} {stat}: the same as Stats.Own`, near(Stats.Own(row, stat, 9), expected))
				end
				t.Check(`{row.Id}: the item is the same on everyone`, same(from(lines, "Item:Main Hand"), { Attack = 40, Critical = 12 }))
				t.Equal(`{row.Id} critical is the item's`, block.Critical, 12)
			end
		end,
	},
	{
		Name = "Stats: stars are a share of the own base, linear",
		Run = function(t: any)
			local data = fresh()
			local owned = own(data, "rook", 12, 0)
			give(data, "Chest Armor", { { Stat = "Health", Value = 500 } })
			local _, none = Stats.Resolve(owned, data.Presets[1], data)
			local base = from(none, "Base") -- the own figure: the base and the level's lines
			for stat, value in from(none, "Level") do
				base[stat] = (base[stat] or 0) + value
			end
			base.Regen = nil -- no star share
			for stars = 1, VoidkinConfig.MaxStars do
				owned.Stars = stars
				local _, lines = Stats.Resolve(owned, data.Presets[1], data)
				local got = from(lines, "Stars")
				for stat, value in base do
					t.Check(`{stars} stars on {stat}`, near(got[stat], value * VoidkinConfig.StarShareOfBase * stars))
				end
				t.Check(`{stars} stars leave the item alone`, same(from(lines, "Item:Chest Armor"), { Health = 500 }))
			end
			owned.Stars = 99
			local _, over = Stats.Resolve(owned, nil, nil)
			t.Check("no star past the last", near(from(over, "Stars").Attack, base.Attack * VoidkinConfig.StarShareOfBase * VoidkinConfig.MaxStars))
		end,
	},
	{
		Name = "Stats: nothing multiplies: each source moves the total by its own lines",
		Run = function(t: any)
			local data = fresh()
			local owned = own(data, "kirra", 20, 3)
			local function total(): (Stats.Block, { Stats.Line })
				return Stats.Resolve(owned, data.Presets[1], data)
			end
			local before, beforeLines = total()
			give(data, "Ring I", { { Stat = "Attack", Value = 33 }, { Stat = "Defence", Value = 21 } })
			local after, afterLines = total()
			t.Check("Attack moved by the ring's", near(after.Attack - before.Attack, 33))
			t.Check("Defence moved by the ring's", near(after.Defence - before.Defence, 21))
			t.Check("Health didn't move", after.Health == before.Health)
			t.Check("the own base kept", same(from(afterLines, "Base"), from(beforeLines, "Base")))
			t.Check("the level's kept", same(from(afterLines, "Level"), from(beforeLines, "Level")))
			t.Check("the stars kept", same(from(afterLines, "Stars"), from(beforeLines, "Stars")))
			for _, stat in Stats.Names do
				local sum = if stat == "CriticalDamage" then StatsConfig.CriticalDamage else 0
				for _, line in afterLines do
					sum += if line.Stat == stat then line.Value else 0
				end
				t.Check(`{stat} is the sum of its lines`, near((after :: any)[stat], sum))
			end
		end,
	},
	{
		Name = "Stats: what isn't there adds nothing",
		Run = function(t: any)
			local data = fresh()
			local owned = own(data, "rook", 1, 0)
			local clean = Stats.Resolve(owned, data.Presets[1], data)
			give(data, "Boots", { { Stat = "Charisma", Value = 50 }, { Stat = "Attack", Value = 0 / 0 } })
			data.Presets[1].Slots.Helmet = "k404"
			local block = Stats.Resolve(owned, data.Presets[1], data)
			t.Check("an unknown stat, NaN and a missing item add nothing", block.Attack == clean.Attack and block.Health == clean.Health)
			owned.Level = 1000
			t.Equal("the level holds at the last", Stats.Resolve(owned, nil, nil).Level, GrowthConfig.MaxLevel)
			owned.Def = "nobody"
			local empty = Stats.Resolve(owned, nil, nil)
			t.Equal("no row, no stats", empty.Health, 0)
		end,
	},
	{
		Name = "Stats: a rating never reaches its cap",
		Run = function(t: any)
			t.Equal("no points, no chance", Stats.Chance(0.4, 0, 100, 5), 0)
			t.Equal("negative points, no chance", Stats.Chance(0.4, -50, 0, 5), 0)
			t.Check("huge points stay under", Stats.Chance(0.4, 1e12, 0, 5) < 0.4)
			t.Check("an opposing rating pulls it down", Stats.Chance(0.4, 100, 100, 5) < Stats.Chance(0.4, 100, 0, 5))
			t.Check("higher levels need more", Stats.Chance(0.4, 100, 0, 30) < Stats.Chance(0.4, 100, 0, 5))
			t.Check("by hand", near(Stats.Chance(0.4, 100, 0, 1), 0.4 * 100 / (100 + StatsConfig.RatingK)))
		end,
	},
	{
		Name = "Stats: Combat Power is a whole number that rises with every stat, a level and a star, and a critical's base adds none",
		Run = function(t: any)
			-- docs/design.md, "Combat Power": every real gain moves it by a whole, visible number. TR17 shows it at the feet.
			local data = fresh()
			local id = Collection.Uncover(data, "rook", NOW).Id
			local owned = data.Voidkin[id]
			local base = Stats.Resolve(owned, nil, data)
			local power = Stats.Power(base)
			t.Check("a whole number above zero", power > 0 and power == math.floor(power), tostring(power))
			t.Equal("an empty block has only its critical's base, which adds none", Stats.Power(Stats.Empty(1)), 0)
			for stat in StatsConfig.Power.Weights do
				local more = table.clone(base) :: any
				more[stat] += if stat == "CriticalDamage" or stat == "Lifesteal" then 0.01 else 1
				t.Check(`more {stat}, more power`, Stats.Power(more) > power, `{Stats.Power(more)} over {power}`)
			end
			owned.Level = 10
			local levelled = Stats.Power((Stats.Resolve(owned, nil, data)))
			t.Check("a level raises it", levelled > power, `{levelled} over {power}`)
			owned.Stars = 1
			local starred = Stats.Power((Stats.Resolve(owned, nil, data)))
			t.Check("a star raises it", starred > levelled, `{starred} over {levelled}`)
			local mythic = first("Mythical", "Warrior")
			if mythic then
				local mid = Collection.Uncover(data, mythic, NOW).Id
				t.Check("a Mythical stands over a Common at the same level", Stats.Power((Stats.Resolve(data.Voidkin[mid], nil, data))) > power)
			end
		end,
	},
}
