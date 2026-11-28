--!strict
-- Stats cases (pure): the curve, experience, and the resolver. Every source adds flat points and none multiplies another
-- (docs/balance.md, "The one rule"); rarity, class and level shape the own attribute points only; stars are a share of
-- them, linear; an item's lines add as they are; each attribute converts once by its row and its class's Main once more;
-- Combat Power reads the Battle Attributes only (docs/engineering-plan.md, "Attributes in the resolver"). Runs in Studio
-- (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Chests = require(Shared.Rules.Chests)
local Collection = require(Shared.Rules.Collection)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local Items = require(Shared.Definitions.Items)
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

-- An item of the row that fits shared `slot`, worn there in the first preset (hands: the Regalia cases).
local function give(data: Profile.Data, slot: string, lines: { { Stat: string, Value: number } }): string
	local def = nil
	for _, row in Items.List do
		if Items.Fits(row, slot, nil) then
			def = row.Id
			break
		end
	end
	assert(def, `no row fits {slot}`)
	local id = Profile.NewId(data)
	data.Items[id] = { Id = id, Def = def, Tier = 1, Rarity = "Common", Design = 1, Lines = lines :: any, Sockets = {}, Reinforce = 0, Jewels = {} }
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
			t.Equal("ground 1 is about 67 kills a level, past the first fights (601 an hour, TR72's session)", math.floor(Growth.KillsPerLevel(early + 1) + 0.5), 67)
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
			give(data, "Cloak", { { Stat = "Speed", Value = 50 } })
			t.Equal("an item's Speed line adds nothing", Stats.Resolve(rook, data.Presets[1], data).Speed, speed.Class.Warrior)
			t.Equal("an enemy walks its kind's, not a Speed", Stats.Enemy("brawler", 5).Speed, 0)
			t.Equal("an unknown class walks nothing of its own", Stats.SpeedOf({ Id = "x", Name = "X", Rarity = "Common", Type = "Red", Class = "Nobody", Element = "", Zone = 1, Aptitude = 1, Speed = 1, Words = { Signature = "", Passive = "" } }), 0)
		end,
	},
	{
		Name = "Stats: a Common Warrior at level 1 is its class's shape, converted by the five attributes' rows (TR49)",
		Run = function(t: any)
			local def = first("Common", "Warrior")
			t.Check("the roster has one", def ~= nil)
			local data = fresh()
			local block = Stats.Resolve(own(data, def :: string, 1, 0), nil, nil)
			local shape = StatsConfig.Attributes.Shape.Warrior
			for _, id in Attributes.Ids do
				t.Check(`its {id} is its shape's`, near(block.Attributes[id], shape[id]), `{block.Attributes[id]}`)
			end
			t.Equal("its Main is Strength", block.Main, "Strength")
			-- By hand from the rows (research's integration pass of the combat review, 2026-11-19): Strength 64, Agility
			-- 16, Intelligence 16, Endurance 45, Spirit 16; a Warrior's Main gives 0.57 Health and 0.78 Attack a Strength.
			t.Check("health: 2.3 a Strength and its Main's 0.57, 5 an Endurance, 3.2 a Spirit", near(block.Health, 2.3 * 64 + 0.57 * 64 + 5 * 45 + 3.2 * 16), `{block.Health}`)
			t.Check("attack: Strength's 1 and its Main's 0.78 more", near(block.Attack, 64 + 0.78 * 64), `{block.Attack}`)
			t.Check("defence: 1 an Endurance", near(block.Defence, 45), `{block.Defence}`)
			t.Check("regen: the level's Base, and 0.05 a Spirit", near(block.Regen, StatsConfig.Regen.Base + 0.05 * 16), `{block.Regen}`)
			t.Check("Agility's Hit, Dodge and Critical", near(block.Hit, 2.5 * 16) and near(block.Dodge, 1.65 * 16) and near(block.Critical, 2.5 * 16), `{block.Hit}, {block.Dodge}, {block.Critical}`)
			t.Check("Intelligence's Penetration and Elemental Attack", near(block.Penetration, 2 * 16) and near(block.ElementalAttack, 1.05 * 16), `{block.Penetration}, {block.ElementalAttack}`)
			t.Check("Endurance's Block, Spirit's resists", near(block.Block, 0.067 * 45) and near(block.CriticalResist, 5.1 * 16) and near(block.ElementalResist, 3 * 16), `{block.Block}, {block.CriticalResist}, {block.ElementalResist}`)
			t.Equal("the critical's base extra", block.CriticalDamage, StatsConfig.CriticalDamage)
			t.Equal("a Warrior's poise", block.Poise, StatsConfig.Poise.Warrior)
		end,
	},
	{
		Name = "Stats: every conversion and every Main, a point at a time, on every class",
		Run = function(t: any)
			local attributes = StatsConfig.Attributes
			local data = fresh()
			for class, main in attributes.Main do
				local def: string? = nil
				for _, row in Voidkin.List do
					if row.Class == class then
						def = row.Id
						break
					end
				end
				if def == nil then
					t.Check(`{class}: no Voidkin of the class to test on yet`, true)
					continue
				end
				local owned = own(data, def, 14, 2)
				t.Equal(`{class}: its Main`, (Stats.Resolve(owned, nil, nil)).Main, main.Attribute)
				local shape = attributes.Shape[class]
				local largest = 0
				for _, id in Attributes.Ids do
					largest = math.max(largest, shape[id])
				end
				t.Equal(`{class}: its Main is its shape's largest`, shape[main.Attribute], largest)
				for _, id in Attributes.Ids do
					data.Presets[1].Slots = {}
					local before = Stats.Resolve(owned, data.Presets[1], data)
					give(data, "Amulet", { { Stat = id, Value = 100 } })
					local after, lines = Stats.Resolve(owned, data.Presets[1], data)
					t.Check(`{class} {id}: the total takes the 100`, near(after.Attributes[id] - before.Attributes[id], 100))
					local row: { [string]: number } = attributes.Convert[id] or {}
					for _, stat in Stats.Names do
						local want: number = 100 * (row[stat] or 0)
						if id == main.Attribute then
							want += 100 * (main.Gives[stat] or 0)
						end
						local moved = (after :: any)[stat] - (before :: any)[stat]
						t.Check(`{class} {id} to {stat}: its row's {want}`, near(moved, want, 1e-9), `{moved}`)
					end
					-- the lines: Attr:<id> is the total times its row, once; Main:<id> only for the Main
					for stat, rate in attributes.Convert[id] or {} do
						t.Check(`{class} {id}: its Attr line for {stat}`, near(from(lines, `Attr:{id}`)[stat] or 0, after.Attributes[id] * rate))
					end
					local mainLines = from(lines, `Main:{id}`)
					t.Equal(`{class} {id}: a Main line only on the Main`, next(mainLines) ~= nil, id == main.Attribute)
				end
			end
		end,
	},
	{
		Name = "Stats: linear and nothing multiplies: twice an item's points, twice exactly what it gives, on any level or stars",
		Run = function(t: any)
			local data = fresh()
			local owned = own(data, "kirra", 20, 0)
			local function gain(points: number): { [string]: number }
				data.Presets[1].Slots = {}
				local bare = Stats.Resolve(owned, data.Presets[1], data)
				give(data, "Ring I", { { Stat = "Strength", Value = points }, { Stat = "Endurance", Value = points / 2 }, { Stat = "Attack", Value = points / 4 } })
				local worn = Stats.Resolve(owned, data.Presets[1], data)
				local out = {}
				for _, stat in Stats.Names do
					out[stat] = (worn :: any)[stat] - (bare :: any)[stat]
				end
				return out
			end
			local once, twice = gain(40), gain(80)
			for _, stat in Stats.Names do
				t.Check(`{stat}: twice the points, twice the gain`, near(twice[stat], 2 * once[stat], 1e-9), `{once[stat]} then {twice[stat]}`)
			end
			owned.Stars, owned.Level = VoidkinConfig.MaxStars, 55
			local later = gain(40)
			for _, stat in Stats.Names do
				t.Check(`{stat}: the same item gives the same at any level and stars`, near(later[stat], once[stat], 1e-9), `{once[stat]} then {later[stat]}`)
			end
		end,
	},
	{
		Name = "Stats: Combat Power reads the Battle Attributes only: the attribute totals and the Main count for nothing",
		Run = function(t: any)
			local data = fresh()
			local block = Stats.Resolve(own(data, "rook", 30, 3), nil, nil)
			local power = Stats.Power(block)
			local doubled = table.clone(block)
			doubled.Attributes = table.clone(block.Attributes)
			for id, value in doubled.Attributes do
				doubled.Attributes[id] = value * 2 + 1000
			end
			doubled.Main = "Endurance"
			t.Equal("the totals moved, the power didn't", Stats.Power(doubled), power)
			local more = table.clone(block)
			more.Attack += 10
			t.Check("a Battle Attribute still moves it", Stats.Power(more) > power)
		end,
	},
	{
		-- TR12: Regen is a value a second from the level (G), never a share; rarity and stars leave the level's own
		-- alone (docs/design.md, "Health carries"). A Healer's more comes from its Main now (rework part 1).
		Name = "Stats: TR12, the level's Regen grows with G for every class, Spirit adds to it (TR49), and a Healer's Main the most",
		Run = function(t: any)
			local data = fresh()
			local regen = StatsConfig.Regen
			t.Equal("no class carries more of the level's own", next(regen.Class), nil)
			for _, row in Voidkin.List do
				for _, level in { 1, 9, 30 } do
					local owned = own(data, row.Id, level, 0)
					local block, lines = Stats.Resolve(owned, nil, nil)
					local levelled = regen.Base * Growth.G(level)
					local first = regen.Base * Growth.G(1)
					t.Check(`{row.Id} at {level}: its base, the level-1 figure`, near(from(lines, "Base").Regen or 0, first))
					t.Check(`{row.Id} at {level}: the level adds the rest`, near((from(lines, "Level").Regen or 0) + first, levelled))
					-- The five attributes' rows (TR49): Spirit converts to Regen, Endurance no longer does.
					local spirit = from(lines, "Attr:Spirit").Regen or 0
					local main = from(lines, `Main:{block.Main}`).Regen or 0
					t.Check(`{row.Id} at {level}: the level's, Spirit's and its Main's`, near(block.Regen, levelled + spirit + main), `{block.Regen}`)
					t.Check(`{row.Id} at {level}: Spirit adds`, spirit > 0)
					t.Equal(`{row.Id} at {level}: Endurance adds none`, from(lines, "Attr:Endurance").Regen, nil)
					owned.Stars = VoidkinConfig.MaxStars
					local _, starred = Stats.Resolve(owned, nil, nil)
					t.Check(`{row.Id} at {level}: stars leave the level's own alone`, near((from(starred, "Base").Regen or 0) + (from(starred, "Level").Regen or 0), levelled))
				end
			end
			local healer, warrior = first("Common", "Healer"), first("Common", "Warrior")
			if healer and warrior then
				local h = Stats.Resolve(own(data, healer, 20, 0), nil, nil)
				local w = Stats.Resolve(own(data, warrior, 20, 0), nil, nil)
				t.Check("a Healer heals more than a Warrior of its level", h.Regen > w.Regen, `{h.Regen} against {w.Regen}`)
			end
			t.Equal("an enemy has none", Stats.Enemy("brawler", 5).Regen, 0)
		end,
	},
	{
		Name = "Stats: rarity, class and level shape the own points only",
		Run = function(t: any)
			local data = fresh()
			give(data, "Gloves", { { Stat = "Attack", Value = 40 }, { Stat = "Critical", Value = 12 }, { Stat = "Endurance", Value = 9 } })
			for _, row in Voidkin.List do
				local owned = own(data, row.Id, 9, 0)
				local _, lines = Stats.Resolve(owned, data.Presets[1], data)
				local shape = StatsConfig.Attributes.Shape[row.Class]
				for _, id in Attributes.Ids do
					local expected = shape[id] * StatsConfig.Rarity[row.Rarity] * Growth.G(9)
					local firstLevel = shape[id] * StatsConfig.Rarity[row.Rarity] * Growth.G(1)
					t.Check(`{row.Id} {id} base, at level 1`, near(from(lines, "Base")[id], firstLevel))
					t.Check(`{row.Id} {id}: base and level make the own figure`, near(from(lines, "Base")[id] + from(lines, "Level")[id], expected))
					t.Check(`{row.Id} {id}: the same as Stats.Own`, near(Stats.Own(row, id, 9), expected))
				end
				t.Check(`{row.Id}: the item is the same on everyone`, same(from(lines, "Item:Gloves"), { Attack = 40, Critical = 12, Endurance = 9 }))
			end
		end,
	},
	{
		Name = "Stats: stars are a share of the own points, linear",
		Run = function(t: any)
			local data = fresh()
			local owned = own(data, "rook", 12, 0)
			give(data, "Chest Armor", { { Stat = "Health", Value = 500 }, { Stat = "Strength", Value = 20 } })
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
				t.Equal(`{stars} stars: only on the attributes`, got.Health, nil)
				t.Check(`{stars} stars leave the item alone`, same(from(lines, "Item:Chest Armor"), { Health = 500, Strength = 20 }))
			end
			owned.Stars = 99
			local _, over = Stats.Resolve(owned, nil, nil)
			t.Check("no star past the last", near(from(over, "Stars").Strength, base.Strength * VoidkinConfig.StarShareOfBase * VoidkinConfig.MaxStars))
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
			for _, id in Attributes.Ids do
				local sum = 0
				for _, line in afterLines do
					sum += if line.Stat == id then line.Value else 0
				end
				t.Check(`{id}'s total is the sum of its points' lines`, near(after.Attributes[id], sum))
			end
		end,
	},
	{
		Name = "Stats: what isn't there adds nothing",
		Run = function(t: any)
			local data = fresh()
			local owned = own(data, "rook", 1, 0)
			local clean = Stats.Resolve(owned, data.Presets[1], data)
			-- Might is one of the five retired attributes (TR36): a line of it that a save still held would add nothing
			give(data, "Boots", { { Stat = "Charisma", Value = 50 }, { Stat = "Might", Value = 50 }, { Stat = "Attack", Value = 0 / 0 }, { Stat = "Strength", Value = 0 / 0 } })
			data.Presets[1].Slots.Helmet = "k404"
			local block = Stats.Resolve(owned, data.Presets[1], data)
			t.Check("an unknown stat, a retired attribute, NaN and a missing item add nothing", block.Attack == clean.Attack and block.Health == clean.Health
				and block.Attributes.Strength == clean.Attributes.Strength and block.Attributes.Might == nil)
			owned.Level = 1000
			t.Equal("the level holds at the last", Stats.Resolve(owned, nil, nil).Level, GrowthConfig.MaxLevel)
			owned.Def = "nobody"
			local empty = Stats.Resolve(owned, nil, nil)
			t.Equal("no row, no stats", empty.Health, 0)
			t.Equal("no row, no Main", empty.Main, "")
			t.Equal("an enemy has no attributes", Stats.Enemy("brawler", 5).Attributes.Strength, 0)
		end,
	},
	{
		Name = "Stats: the even foe is the on-budget ratings times G at its level, and nothing else",
		Run = function(t: any)
			for _, level in { 1, 20, 60 } do
				local foe = Stats.EvenFoe(level)
				local g = Growth.G(level)
				t.Equal(`level {level}`, foe.Level, level)
				for stat, value in StatsConfig.EvenFoe do
					t.Check(`level {level}: its {stat}`, near((foe :: any)[stat], value * g))
				end
				t.Equal(`level {level}: no type, no element`, foe.Type .. foe.Element, "")
			end
			t.Equal("past the last level, the last", Stats.EvenFoe(9999).Level, GrowthConfig.MaxLevel)
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
		Name = "Stats: Combat Power is its sum rounded to a whole, and the sum rises with every stat, a level and a star, and a critical's base adds none",
		Run = function(t: any)
			-- docs/design.md, "Combat Power". TR17 shows it at the feet. At a tenth's scale (D3, 2026-11-18) one point of a
			-- stat can stay under half a shown point, so a gain is judged on the unrounded sum (Stats.Sum).
			local data = fresh()
			local id = Collection.Uncover(data, "rook", NOW).Id
			local owned = data.Voidkin[id]
			local base = Stats.Resolve(owned, nil, data)
			local power = Stats.Power(base)
			local sum = Stats.Sum(base)
			t.Check("a whole number above zero", power > 0 and power == math.floor(power), tostring(power))
			t.Equal("the sum rounded", power, math.floor(sum + 0.5))
			t.Equal("an empty block has only its critical's base, which adds none", Stats.Sum(Stats.Empty(1)), 0)
			for stat in StatsConfig.Power.Weights do
				local more = table.clone(base) :: any
				more[stat] += if stat == "CriticalDamage" or stat == "Lifesteal" then 0.01 else 1
				if stat == "ElementalAttack" then
					-- Rook's Fire (TR49, decision 6) carries it: more power. A block with no element has no elemental part
					-- (Rules.Hit), so there the points add nothing, and an element with no points adds none either.
					t.Check("more Elemental Attack with an element, more power", Stats.Sum(more) > sum, `{Stats.Sum(more)} over {sum}`)
					local bare, bareMore = table.clone(base) :: any, table.clone(more)
					bare.Element, bareMore.Element = "", ""
					t.Equal("more Elemental Attack with no element: the same power", Stats.Sum(bareMore), Stats.Sum(bare))
					local spent, kept = table.clone(base) :: any, table.clone(base) :: any
					spent.ElementalAttack, kept.ElementalAttack, kept.Element = 0, 0, ""
					t.Equal("an element alone adds none", Stats.Sum(spent), Stats.Sum(kept))
				else
					t.Check(`more {stat}, more power`, Stats.Sum(more) > sum, `{Stats.Sum(more)} over {sum}`)
				end
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
	{
		Name = "Stats: a percent's line price grows with G at its level, a point's doesn't (TR17 fix 10, on the prices since TR49)",
		Run = function(t: any)
			-- Research's seeds: a percent multiplies points, which grow with G, so its price is its level-1 weight times G.
			-- Since the combat review (TR49) Combat Power never reads the weights: they are the line prices alone (Rules.Chests,
			-- Config.Stats.Power), and Combat Power is the body's against the reference (Stats.Sum), so a block of one stat
			-- alone, with no health, has none.
			local power = StatsConfig.Power
			local weights = power.Weights
			for _, level in { 1, 20, 60 } do
				local lone = Stats.Empty(level) :: any
				lone.Attack += 100
				t.Equal(`100 Attack alone at level {level}: no body, no Combat Power`, Stats.Power(lone), 0)
			end
			for stat in power.ByLevel do
				t.Check(`{stat}: a percent, priced at its level-1 weight (ByLevel times G wherever one is read)`, weights[stat] > 0 and Chests.Price(stat) == weights[stat])
			end
			t.Check("a percent's price is only on the three percents", power.ByLevel.Attack == nil and power.ByLevel.Health == nil)
			for stat, row in StatsConfig.Attributes.Convert do
				local price = 0
				for into, rate in row do
					price += rate * (weights[into] or 0)
				end
				t.Check(`{stat}: its price is what it converts into, priced`, math.abs(Chests.Price(stat) - price) <= 1e-9)
			end
		end,
	},
}
