--!strict
-- Chest family cases (pure): TR56, "A chest for everything" (tools/balance/seeds.json "chestFamily" and "jewels"). Every
-- chest's Rare at its least and above its Epic; an Emblem Case's odds its gear chest's, Common read as Uncommon; the
-- Tower's case once a tenth floor; the pouch's and the crate's rolls and their opening into the bag, a repeat paying once;
-- a Hard keeper's pouch and crate; the combine's refusals and a repeated request paying once; Mid into High refused under
-- the Condenser's level 10; its jewels; presets at their base levels; a jewel's points, in the resolver too.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Saveable = require(Shared.Data.Saveable)
local ChestRows = require(Shared.Definitions.Chests)
local Sets = require(Shared.Definitions.Emblems)
local Voidkin = require(Shared.Definitions.Voidkin)
local Chests = require(Shared.Rules.Chests)
local Emblems = require(Shared.Rules.Emblems)
local Jewels = require(Shared.Rules.Jewels)
local Progress = require(Shared.Rules.Progress)
local Tower = require(Shared.Rules.Tower)
local Base = require(Shared.Rules.Base)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Breaker = require(Shared.Rules.Breaker)
local Condenser = require(Shared.Rules.Condenser)
local Regalia = require(Shared.Rules.Regalia)
local Stats = require(Shared.Rules.Stats)
local Collection = require(Shared.Rules.Collection)
local ChestsConfig = require(Shared.Config.Chests)
local EmblemsConfig = require(Shared.Config.Emblems)
local JewelsConfig = require(Shared.Config.Jewels)
local CondenserConfig = require(Shared.Config.Condenser)
local BaseConfig = require(Shared.Config.Base)
local DataConfig = require(Shared.Config.Data)

local NOW = 1_800_000_000
local GROUND = "lanternrow"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function saves(t: any, data: Profile.Data, label: string)
	local problems = Saveable.Problems(data, "profile")
	t.Check(`{label}: saves whole`, #problems == 0, table.concat(problems, "; "))
end

-- A fixed draw from `seed`: Park and Miller's minimal standard generator, its steps independent enough for rates.
local function sequence(seed: number): () -> number
	local state = seed % 2147483646 + 1
	return function(): number
		state = state * 16807 % 2147483647
		return (state - 1) / 2147483646
	end
end

local function constant(u: number): () -> number
	return function(): number
		return u
	end
end

local function sum(map: { [string]: number }): number
	local n = 0
	for _, each in map do
		n += each
	end
	return n
end

local function base(data: Profile.Data, name: string, args: any, now: number, opId: string?): any
	local answer = Transaction.Run(data, opId, function(draft: Profile.Data): any
		return Base.Actions[name](draft, args, now, 0.5)
	end, DataConfig.OpsKept)
	return answer
end

return {
	{
		Name = "Chest family: TR56, every chest gives a Rare at its least, above its Epic; the Hard keeper's at its own",
		Run = function(t: any)
			local gear, cases = 0, 0
			for _, row in ChestRows.List do
				if row.Tier > ChestRows.Case or row.Rarity ~= nil then
					continue -- a pouch and a crate give no rarity; a Tower case gives its one, sure
				end
				local odds = Chests.Odds(row)
				local least = Chests.Least(row)
				local total = 0
				for _, chance in odds do
					total += chance
				end
				t.Check(`{row.Id}: Rare at its least ({least.Rare}%)`, odds.Rare >= least.Rare / 100 - 1e-9, `{odds.Rare}`)
				t.Check(`{row.Id}: Rare above its Epic`, odds.Rare > odds.Epic, `{odds.Rare} {odds.Epic}`)
				t.Check(`{row.Id}: its odds sum to one`, math.abs(total - 1) < 1e-9, `{total}`)
				if row.Tier == ChestRows.Case then
					cases += 1
				else
					gear += 1
				end
			end
			t.Check("every gear chest checked, and a case for each elite's and keeper's", gear > 0 and cases > 0, `{gear} gear, {cases} cases`)
			t.Equal("the least Rare: 1%", ChestsConfig.Least.Rare, 1.0)
			t.Equal("a Hard keeper's: 3%", ChestsConfig.Hard.Least.Keeper.Rare, 3.0)
			local keeper = ChestRows.Of(GROUND, 3, "Hard", ChestRows.KeeperStage[GROUND]) :: ChestRows.Row
			t.Check("a Hard keeper's chest: Rare at 3%, over its 1.6% Epic", Chests.Odds(keeper).Rare >= 0.03 - 1e-9 and Chests.Odds(keeper).Rare > Chests.Odds(keeper).Epic)
		end,
	},
	{
		Name = "Chest family: TR56, an Emblem Case rolls its rarity as its gear chest does, Common read as Uncommon, and opens to emblems of that rarity",
		Run = function(t: any)
			local checked = 0
			for _, row in ChestRows.List do
				if row.Tier ~= ChestRows.Case or row.Of == nil then
					continue
				end
				local of = ChestRows.ById[row.Of :: string]
				local mine, theirs = Chests.Odds(row), Chests.Odds(of)
				local same = mine.Common == 0 and math.abs(mine.Uncommon - (theirs.Common + theirs.Uncommon)) < 1e-9
				for _, name in { "Rare", "Epic", "Legendary" } do
					same = same and math.abs(mine[name] - theirs[name]) < 1e-9
				end
				t.Check(`{row.Id}: {of.Id}'s rarities`, same, `{mine.Uncommon} {mine.Rare} {mine.Epic} {mine.Legendary}`)
				t.Equal(`{row.Id}: its gear chest names it`, (ChestRows.CaseOf(of.Id) :: ChestRows.Row).Id, row.Id)
				checked += 1
			end
			t.Check("every case checked", checked > 0, `{checked}`)
			-- Opened, each emblem at a rarity its odds hold, a stat that rarity holds.
			local case = ChestRows.CaseOf((ChestRows.Of(GROUND, 2) :: ChestRows.Row).Id) :: ChestRows.Row
			local odds = Chests.Odds(case)
			for i = 1, 300 do
				local key = Chests.RollCase(case, sequence(i))
				local parsed = Emblems.Parse(key)
				t.Check(`roll {i}: an emblem that exists, at a rarity the case gives`, parsed ~= nil and (odds :: any)[(parsed :: any).Set.Rarity] > 0, key)
			end
			-- The Tower's cases: one rarity each, sure.
			for _, rarity in { "Rare", "Epic", "Legendary" } do
				local row = ChestRows.TowerCase(rarity) :: ChestRows.Row
				t.Check(`the Tower's {rarity} case gives only {rarity}`, row ~= nil and math.abs(Chests.Odds(row)[rarity] - 1) < 1e-9)
				local parsed = Emblems.Parse(Chests.RollCase(row, sequence(3)))
				t.Check(`and opens to one`, parsed ~= nil and (parsed :: any).Set.Rarity == rarity)
			end
			t.Check("a case holds no gear", not Chests.IsGear(case) and Chests.IsGear(ChestRows.ById[case.Of :: string]))
		end,
	},
	{
		Name = "Chest family: TR56, the Tower gives one sure case at each tenth floor the account first clears, fast or hard, once a floor",
		Run = function(t: any)
			local by = ChestsConfig.Case.Tower.By
			for floor, rarity in { [10] = by[1], [20] = by[2], [30] = by[3], [40] = by[4], [50] = by[5], [60] = "Epic", [100] = "Legendary", [150] = "Legendary", [170] = "Epic" } do
				t.Equal(`floor {floor}: {rarity}`, Tower.Case(floor, 0), (ChestRows.TowerCase(rarity) :: ChestRows.Row).Id)
			end
			t.Check("the seeds' ladder: Rare, Rare, Epic, Epic, Legendary", table.concat(by, ",") == "Rare,Rare,Epic,Epic,Legendary")
			t.Equal("floor 11: none", Tower.Case(11, 0), nil)
			t.Equal("floor 10 again (best 10): none", Tower.Case(10, 10), nil)
			t.Equal("floor 20 past a best of 19: its case", Tower.Case(20, 19), (ChestRows.TowerCase("Rare") :: ChestRows.Row).Id)
			local data = fresh()
			Tower.Start(data, "c1", 7, NOW)
			for floor = 1, 10 do
				Tower.Won(data, "c1", floor, floor % 2 == 0)
			end
			t.Equal("floor 10 won again: a no-op", Tower.Won(data, "c1", 10, false), nil)
			local rare = (ChestRows.TowerCase("Rare") :: ChestRows.Row).Id
			t.Equal("the run's ledger: one Rare case", ((data.Progress.Tower.Run :: any).Chests :: any)[rare], 1)
			local results = Tower.End(data, "c1", NOW + 600) :: Profile.TowerResults
			t.Check("the end grants it into the bag", results ~= nil and data.Bag.Chests[rare] == 1)
			t.Equal("ended again: nothing more", Tower.End(data, "c1", NOW + 601), nil)
			t.Equal("still one", data.Bag.Chests[rare], 1)
			Tower.Start(data, "c2", 8, NOW + 700)
			for floor = 1, 10 do
				Tower.Won(data, "c2", floor, false)
			end
			t.Equal("a second climb past floor 10: no case, its first clear done", ((data.Progress.Tower.Run :: any).Chests :: any)[rare], nil)
			saves(t, data, "after the Tower")
		end,
	},
	{
		Name = "Chest family: TR56, a Jewel Pouch and a Forge Crate roll at the seeds' rates and open into the bag; a repeated open pays once",
		Run = function(t: any)
			t.Equal("a pouch at 0.79: tier 1", select(2, Jewels.Parse(Chests.RollPouch(constant(0.79)))), 1)
			t.Equal("at 0.8: tier 2", select(2, Jewels.Parse(Chests.RollPouch(constant(0.8)))), 2)
			local colours: { [string]: number } = {}
			local tiers = { 0, 0 }
			local draw = sequence(11)
			local N = 5000
			for _ = 1, N do
				local colour, tier = Jewels.Parse(Chests.RollPouch(draw))
				colours[colour :: string] = (colours[colour :: string] or 0) + 1
				tiers[tier :: number] += 1
			end
			t.Check("tier 1 about 80%", math.abs(tiers[1] / N - ChestsConfig.Pouch.Tiers[1]) < 0.03, `{tiers[1] / N}`)
			for _, colour in JewelsConfig.Colours do
				t.Check(`{colour} about a fifth`, math.abs((colours[colour] or 0) / N - 0.2) < 0.03, `{(colours[colour] or 0) / N}`)
			end
			local low = { Low = 0 }
			local mids, highs, lowMin, lowMax = 0, 0, math.huge, 0
			for _ = 1, N do
				local stones = Chests.RollCrate(draw)
				lowMin, lowMax = math.min(lowMin, stones.Low), math.max(lowMax, stones.Low)
				low.Low += stones.Low
				if stones.Mid then
					mids += 1
					t.Check("a crate's Mid: 1 to 2", stones.Mid >= 1 and stones.Mid <= 2)
				end
				highs += if stones.High then 1 else 0
			end
			t.Check("a crate's Low: 4 to 8, every one", lowMin == 4 and lowMax == 8, `{lowMin} to {lowMax}`)
			t.Check("Mid about 25% of crates", math.abs(mids / N - ChestsConfig.Crate.MidChance) < 0.03, `{mids / N}`)
			t.Check("High about 2%", math.abs(highs / N - ChestsConfig.Crate.HighChance) < 0.01, `{highs / N}`)
			-- Opened through the one path, op id and all.
			local data = fresh()
			Chests.Grant(data, ChestRows.PouchId, 3)
			Chests.Grant(data, ChestRows.CrateId, 1)
			local function open(id: string, count: number, opId: string): any
				return Transaction.Run(data, opId, function(draft: Profile.Data): any
					return Chests.Open(draft, id, count, sequence(5))
				end, DataConfig.OpsKept)
			end
			local pouch = open(ChestRows.PouchId, 3, "p1")
			t.Check("three pouches: three jewels in the bag", pouch.Ok == true and sum(pouch.Jewels) == 3 and sum(data.Bag.Jewels) == 3 and (data.Bag.Chests[ChestRows.PouchId] or 0) == 0)
			local again = open(ChestRows.PouchId, 3, "p1")
			t.Check("the same open again: its first answer, nothing more", again.Ok == true and sum(data.Bag.Jewels) == 3)
			local stonesWere = sum(data.Bag.Stones)
			local crate = open(ChestRows.CrateId, 1, "k1")
			t.Check("a crate: its stones in the bag, no item", crate.Ok == true and #crate.Items == 0 and sum(data.Bag.Stones) == stonesWere + sum(crate.Stones) and (crate.Stones.Low or 0) >= 4)
			t.Equal("none left: refused", open(ChestRows.CrateId, 1, "k2").Ok, false)
			local caseId = (ChestRows.CaseOf((ChestRows.Of(GROUND, 2) :: ChestRows.Row).Id) :: ChestRows.Row).Id
			Chests.Grant(data, caseId, 2)
			local cases = open(caseId, 2, "e1")
			t.Check("two cases: two emblems", cases.Ok == true and sum(cases.Emblems) == 2 and sum(data.Bag.Emblems) == 2)
			saves(t, data, "after opening")
		end,
	},
	{
		Name = "Chest family: TR56, a Hard keeper's win gives a Jewel Pouch for sure and a Forge Crate at half; Normal's neither",
		Run = function(t: any)
			local function loot(pouch: number, crate: number): any
				return { Stone = 0, Emblem = 0.99, Rarity = 0, Set = 0, Stat = 0, Pouch = pouch, Crate = crate }
			end
			local data = fresh()
			local normal = Progress.KeeperWon(data, GROUND, NOW, "Normal", loot(0, 0))
			t.Check("Normal: no pouch, no crate", normal.Ok == true and normal.Pouch == "" and normal.Crate == "")
			local hard = Progress.KeeperWon(data, GROUND, NOW + 400, "Hard", loot(0.99, 0.49))
			t.Check("Hard, rolls 0.99 and 0.49: a pouch and a crate", hard.Ok == true and hard.Pouch == ChestRows.PouchId and hard.Crate == ChestRows.CrateId, `{hard.Pouch} {hard.Crate}`)
			t.Check("both in the bag", data.Bag.Chests[ChestRows.PouchId] == 1 and data.Bag.Chests[ChestRows.CrateId] == 1)
			local half = Progress.KeeperWon(data, GROUND, NOW + 800, "Hard", loot(0.5, 0.5))
			t.Check("crate roll 0.5: the pouch alone", half.Pouch == ChestRows.PouchId and half.Crate == "")
			t.Check("without the rolls: neither", Progress.KeeperWon(data, GROUND, NOW + 1200, "Hard").Pouch == "")
			saves(t, data, "after the keepers")
		end,
	},
	{
		Name = "Chest family: TR56, three emblems of one stat and rarity combine into one of the next; refusals change nothing; a repeat pays once",
		Run = function(t: any)
			local uncommon = Sets.ByRarity.Uncommon
			local a, b = Emblems.Key(uncommon[1].Id, "Attack"), Emblems.Key(uncommon[2].Id, "Attack")
			local data = fresh()
			data.Bag.Emblems[a] = 2
			data.Bag.Emblems[b] = 2
			data.Bag.Emblems[Emblems.Key(uncommon[1].Id, "Health")] = 1
			local function combine(args: any, opId: string?, u: number?): any
				return Transaction.Run(data, opId, function(draft: Profile.Data): any
					return Emblems.Combine(draft, args, u or 0.5)
				end, DataConfig.OpsKept)
			end
			local function bag(): string
				local keys = {}
				for key, n in data.Bag.Emblems do
					table.insert(keys, `{key}={n}`)
				end
				table.sort(keys)
				return table.concat(keys, ",")
			end
			local before = bag()
			t.Equal("an unknown rarity: refused", combine({ Rarity = "Mythic", Stat = "Attack" }).Error, Emblems.Unknown)
			t.Equal("no args: refused", combine(nil).Error, Emblems.Unknown)
			t.Equal("one Health: not enough", combine({ Rarity = "Uncommon", Stat = "Health" }).Error, Emblems.NotEnough)
			data.Bag.Emblems[Emblems.Key(Sets.ByRarity.Legendary[1].Id, "Attack")] = 3
			t.Equal("three Legendary: the top", combine({ Rarity = "Legendary", Stat = "Attack" }).Error, Emblems.Top)
			data.Bag.Emblems[Emblems.Key(Sets.ByRarity.Legendary[1].Id, "Attack")] = nil
			t.Equal("the refusals changed nothing", bag(), before)
			t.Equal("held across sets: four Uncommon Attack", Emblems.Held(data, "Uncommon", "Attack"), 4)
			local made = combine({ Rarity = "Uncommon", Stat = "Attack" }, "m1", 0)
			local rare = Emblems.Key(Sets.ByRarity.Rare[1].Id, "Attack")
			t.Check("three Attack fold into one Rare Attack", made.Ok == true and made.Rarity == "Rare" and made.Emblem == rare and data.Bag.Emblems[rare] == 1, tostring(made.Emblem))
			t.Equal("three taken, one left", Emblems.Held(data, "Uncommon", "Attack"), 1)
			t.Equal("taken across both sets", sum(made.Took), EmblemsConfig.Combine.Take)
			local again = combine({ Rarity = "Uncommon", Stat = "Attack" }, "m1", 0)
			t.Check("the same request again: its first answer, nothing more", again.Ok == true and data.Bag.Emblems[rare] == 1 and Emblems.Held(data, "Uncommon", "Attack") == 1)
			t.Equal("a new request: not enough now", combine({ Rarity = "Uncommon", Stat = "Attack" }, "m2").Error, Emblems.NotEnough)
			data.Bag.Emblems[Emblems.Key(uncommon[1].Id, "Health")] = 3
			local last = combine({ Rarity = "Uncommon", Stat = "Health" }, "m3", 0.999)
			t.Equal("the made one's set: its roll, the last at 0.999", last.Emblem, Emblems.Key(Sets.ByRarity.Rare[#Sets.ByRarity.Rare].Id, "Health"))
			saves(t, data, "after combining")
		end,
	},
	{
		Name = "Chest family: TR56, the Condenser turns Mid into High from its level 10, refused under it; its jewels while it works",
		Run = function(t: any)
			local mid = CondenserConfig.Converts.Mid
			t.Check("the seeds: 5 Mid into 1 High, an hour, from level 10", mid.From == "Mid" and mid.Take == 5 and mid.To == "High" and mid.Give == 1 and mid.Seconds == 3600 and mid.FromLevel == 10)
			local data = fresh()
			data.Base.Level = 3
			data.Base.Machines.Condenser = 9
			data.Base.Charge = 0
			Breaker.Advance(data, NOW)
			data.Base.Charge = Breaker.Capacity(data.Base)
			data.Bag.Stones.Mid = 5
			t.Equal("level 9: refused", base(data, "Convert", { From = "Mid" }, NOW, "h1").Error, Base.Low)
			t.Equal("and nothing spent", data.Bag.Stones.Mid, 5)
			t.Equal("an unknown grade: refused", base(data, "Convert", { From = "High" }, NOW, "h0").Error, Base.BadArgs)
			data.Base.Machines.Condenser = 10
			local begun = base(data, "Convert", { From = "Mid" }, NOW, "h2")
			t.Check("level 10: begun, its five Mid taken", begun.Ok == true and begun.From == "Mid" and data.Bag.Stones.Mid == 0 and data.Base.Condenser.Converting == "Mid")
			t.Check("the same ask again: nothing more", base(data, "Convert", { From = "Mid" }, NOW, "h2").Ok == true and data.Bag.Stones.Mid == 0)
			t.Equal("a Low convert meanwhile: busy", base(data, "Convert", {}, NOW, "h3").Error, Base.Busy)
			Breaker.Advance(data, NOW + 8 * 3600)
			t.Check("its High lands in the tray", (data.Base.Condenser.Tray.High or 0) == 1 and data.Base.Condenser.Converting == nil and data.Base.Condenser.Convert == nil)
			-- Its jewels: one each EveryHours of work, colours in turn, tier by its level.
			local made = Condenser.JewelsHeld(data.Base)
			t.Check("eight hours' work: jewels in its tray", made >= 1, `{made}`)
			t.Equal("at level 10, tier 2", Condenser.JewelTier(10), 2)
			t.Check("tiers by level: 1 from 1, 2 from 8, 3 from 16", Condenser.JewelTier(7) == 1 and Condenser.JewelTier(8) == 2 and Condenser.JewelTier(16) == 3)
			for key in data.Base.Condenser.Jewels or {} do
				t.Equal(`{key}: tier 2`, select(2, Jewels.Parse(key)), 2)
			end
			local collected = base(data, "CollectTray", {}, NOW + 8 * 3600, "t1")
			t.Check("collected: its jewels into the bag", collected.Ok == true and sum(collected.Jewels) == made and sum(data.Bag.Jewels) == made and Condenser.JewelsHeld(data.Base) == 0)
			t.Check("and its High", (data.Bag.Stones.High or 0) == 1)
			local only = fresh()
			only.Base.Level = 3
			only.Base.Condenser.Jewels = { ["Red:1"] = 1 }
			t.Check("a tray of one jewel alone: collected", base(only, "CollectTray", {}, NOW, "j1").Ok == true and only.Bag.Jewels["Red:1"] == 1)
			-- Colours in turn, by the pure step.
			local plain = fresh()
			plain.Base.Level = 3
			plain.Base.Condenser.Convert = 0
			local every = Condenser.JewelSeconds()
			local _, _, five = Condenser.Work(plain.Base, 1, every * 5)
			t.Equal("five jewels' work: five", five, 5)
			for _, colour in JewelsConfig.Colours do
				t.Equal(`one {colour}`, (plain.Base.Condenser.Jewels :: any)[`{colour}:1`], 1)
			end
			saves(t, data, "after the High")
		end,
	},
	{
		Name = "Chest family: TR56, gear presets by base level, 1, 2 and 3; a migration gives an older save its level's; a Voidkin links to one held",
		Run = function(t: any)
			t.Check("the seeds: 1, 2, 3", table.concat(BaseConfig.Levels.Presets, ",") == "1,2,3")
			local data = fresh()
			t.Equal("a new account: one", #data.Presets, 1)
			for level = 2, 3 do
				local price = BaseLevels.Next(level - 1, math.huge).Price :: number
				data.Currency.Credits = price
				local answer = base(data, "UpgradeBase", { Level = level }, NOW + level, `u{level}`)
				t.Check(`base level {level}: {level} presets`, answer.Ok == true and #data.Presets == level, `{answer.Error} {#data.Presets}`)
			end
			local gains = BaseLevels.Next(1, 0).Gains
			local said = false
			for _, gain in gains do
				said = said or (gain.What == "Presets" and gain.To == 2)
			end
			t.Check("the next level's gains name the preset", said)
			-- An older save at base level 3.
			local old = fresh()
			old.Base.Level = 3
			old.Version = 12
			Migrations.Run(old)
			t.Equal("migration 13: a level 3 save holds three", #old.Presets, 3)
			Migrations.Run(old)
			t.Equal("run again: still three", #old.Presets, 3)
			-- A Voidkin links to a held preset.
			local owned = old.Voidkin[Collection.Uncover(old, Voidkin.List[1].Id, NOW).Id]
			t.Check("preset 3: linked", Regalia.UsePreset(old, owned.Id, 3).Ok == true and owned.Preset == 3)
			t.Equal("preset 4: refused", Regalia.UsePreset(old, owned.Id, 4).Ok, false)
			t.Equal("and it stays on 3", owned.Preset, 3)
			t.Equal("an unknown Voidkin: refused", Regalia.UsePreset(old, "nobody", 1).Ok, false)
			t.Check("through the Act remote's table", Regalia.Actions.UsePreset(old, { Voidkin = owned.Id, Preset = 2 }).Ok == true and owned.Preset == 2)
			local level1 = fresh()
			local one = level1.Voidkin[Collection.Uncover(level1, Voidkin.List[1].Id, NOW).Id]
			t.Equal("a level 1 base: preset 2 refused", Regalia.UsePreset(level1, one.Id, 2).Ok, false)
			saves(t, old, "after presets")
		end,
	},
	{
		Name = "Chest family: TR56, a jewel's points are its colour's attribute at the seeds' values, and the resolver counts them",
		Run = function(t: any)
			local want = {
				{ 2, 6, 4, 2, 3 },
				[5] = { 11, 38, 25, 11, 17 },
			}
			for tier, row in want do
				for i, colour in JewelsConfig.Colours do
					local attribute, points = Jewels.Points(colour, tier)
					t.Equal(`{colour} tier {tier}: {JewelsConfig.Attribute[colour]} +{row[i]}`, points, row[i])
					t.Equal(`{colour}'s attribute`, attribute, JewelsConfig.Attribute[colour])
				end
			end
			local colour, tier = Jewels.Parse(Jewels.Key("Blue", 3))
			t.Check("a key round trip", colour == "Blue" and tier == 3)
			t.Check("a bad key: nothing", Jewels.Parse("Black:1") == nil and Jewels.Parse("Red:9") == nil and Jewels.Parse("Red") == nil)
			local data = fresh()
			local owned = data.Voidkin[Collection.Uncover(data, Voidkin.List[1].Id, NOW).Id]
			local id = Profile.NewId(data)
			data.Items[id] = {
				Id = id,
				Def = "ring",
				Tier = 1,
				Rarity = "Rare",
				Design = 1,
				Lines = { { Stat = "Attack", Value = 100 } },
				Sockets = { "" },
				Reinforce = 0,
				Jewels = { Red = 1, Green = 5 },
			}
			data.Presets[1].Slots["Ring I"] = id
			local _, lines = Stats.Resolve(owned, data.Presets[1], data)
			local got: { [string]: number } = {}
			for _, line in lines do
				if line.Source == "Jewel:Ring I" then
					got[line.Stat] = (got[line.Stat] or 0) + line.Value
				end
			end
			t.Check("Red tier 1 and Green tier 5 in Ring I: Strength +2, Agility +38", got.Strength == 2 and got.Agility == 38, `{got.Strength} {got.Agility}`)
		end,
	},
}
