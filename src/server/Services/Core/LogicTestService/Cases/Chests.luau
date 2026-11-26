--!strict
-- Chests cases (pure): part 11's chests (docs/engineering-plan.md, "Chests"; Rules.Chests). The rows and their odds; a
-- roll fixed by its draws and priced at its item's worth; the shares over many rolls; 1,000 opened in steps, each chest
-- removed once and each item granted once; a repeat answering its first answer and a refusal changing nothing; the
-- salvage, which never takes what would raise Combat Power; the drops at a fall and a keeper's win; the save at a full
-- bag; and gear's whole way, seeded, repeated and cut short, never making or losing a chest, an item, a Credit, a stone
-- or an emblem (section 9). Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Transaction = require(Shared.Data.Transaction)
local ChestsConfig = require(Shared.Config.Chests)
local ChestRows = require(Shared.Definitions.Chests)
local Items = require(Shared.Definitions.Items)
local Gear = require(Shared.Definitions.Gear)
local Grounds = require(Shared.Definitions.Grounds)
local Voidkin = require(Shared.Definitions.Voidkin)
local Attributes = require(Shared.Definitions.Attributes)
local Chests = require(Shared.Rules.Chests)
local Drops = require(Shared.Rules.Drops)
local Progress = require(Shared.Rules.Progress)
local Regalia = require(Shared.Rules.Regalia)
local Reinforce = require(Shared.Rules.Reinforce)
local Emblems = require(Shared.Rules.Emblems)
local EmblemSets = require(Shared.Definitions.Emblems)
local ReinforceConfig = require(Shared.Config.Reinforce)
local Growth = require(Shared.Rules.Growth)
local Collection = require(Shared.Rules.Collection)
local Stats = require(Shared.Rules.Stats)
local ItemDesigns = require(Shared.Definitions.ItemDesigns)
local UIKit = require(Shared.Config.UIKit)
local Bag = require(Shared.Rules.Bag)
local Sheet = require(Shared.Rules.Sheet)

local NOW = 1_800_000_000
local OP = "9b2c7d1e-5f3a-4c8b-a6e0-1d2f3a4b5c6d"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function same(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not same(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

-- A fixed sequence in (0, 1): Park and Miller's, exact in doubles.
local function sequence(seed: number): Chests.Draw
	local state = seed
	return function(): number
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
end

local function lead(data: Profile.Data, class: string): Profile.OwnedVoidkin
	for _, row in Voidkin.List do
		if row.Class == class then
			local owned = data.Voidkin[Collection.Uncover(data, row.Id, NOW).Id]
			owned.Level = 9
			data.Roles.Lead = owned.Id
			return owned
		end
	end
	error(`no {class}`)
end

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

-- A save's size as JSON, the way the store writes it, near enough: keys and strings quoted, numbers as Luau prints them.
local function size(value: any): number
	if type(value) == "string" then
		return #value + 2
	elseif type(value) == "number" or type(value) == "boolean" then
		return #tostring(value)
	elseif type(value) == "table" then
		local n, total = 0, 2
		if #value > 0 then
			for _, item in ipairs(value) do
				total += size(item) + 1
				n += 1
			end
		else
			for key, item in value do
				total += #tostring(key) + 3 + size(item) + 1
				n += 1
			end
		end
		return total - (if n > 0 then 1 else 0)
	end
	return 4
end

local function chest(ground: string, tier: number): string
	return (ChestRows.Of(ground, tier) :: ChestRows.Row).Id
end

return {
	{
		Name = "Chests: one row a tier in every ground, its odds summing to one, nothing above Legendary",
		Run = function(t: any)
			t.Equal("four tiers, the Tower's the fourth", ChestRows.Tiers, 4)
			t.Equal("the Tower's tier", ChestRows.Tower, 4)
			for _, ground in Grounds.List do
				for tier = 1, ChestRows.Tiers do
					local row = ChestRows.Of(ground.Id, tier)
					t.Check(`{ground.Id} tier {tier}: a row`, row ~= nil and row.Ground == ground.Id and row.Tier == tier)
					if row then
						t.Check(`{row.Id}: named for its ground`, string.find(row.Name, ground.Name, 1, true) ~= nil, row.Name)
						for _, word in ChestsConfig.Rarities do
							if string.find(row.Name, word, 1, true) then
								t.Check(`{row.Id}: no rarity's word in its name`, false, row.Name)
							end
						end
						local sum = 0
						for _, chance in Chests.Odds(row) do
							sum += chance
						end
						t.Check(`{row.Id}: odds sum to one`, math.abs(sum - 1) < 1e-9, tostring(sum))
					end
				end
				if ground.Order < #Grounds.List then
					local nextGround = Grounds.List[ground.Order + 1]
					t.Equal(`{ground.Id}: an elite's chest is the next ground's Shade chest`, Chests.Step(ChestRows.Of(ground.Id, 2) :: any), Chests.Step(ChestRows.Of(nextGround.Id, 1) :: any))
				end
			end
			t.Equal("the rarities stop at Legendary", ChestsConfig.Rarities[#ChestsConfig.Rarities], "Legendary")
			t.Equal("one ladder row a rarity each", #ChestsConfig.Ladder[1], #ChestsConfig.Rarities)
			local shade = Chests.Odds(ChestRows.Of("lanternrow", 1) :: any)
			t.Check("TR56: Lantern Row's Shade chest gives a Rare at its least, 1%, above its Epic", math.abs(shade.Rare - ChestsConfig.Least.Rare / 100) < 1e-9 and shade.Rare > shade.Epic, `{shade.Rare} {shade.Epic}`)
		end,
	},
	{
		Name = "Chests: the Tower's chest reads its own row in every ground, never the ladder, and rolls by it",
		Run = function(t: any)
			local own = ChestsConfig.Tower
			t.Equal("the Tower's row, a rarity each", #own, #ChestsConfig.Rarities)
			local total = 0
			for _, weight in own do
				total += weight
			end
			for _, ground in Grounds.List do
				local row = ChestRows.Of(ground.Id, ChestRows.Tower)
				t.Check(`{ground.Id}: a Tower chest, named for its ground`, row ~= nil and string.find(row.Name, "Tower Chest", 1, true) == 1 and string.find(row.Name, ground.Name, 1, true) ~= nil, if row then row.Name else "none")
				if row then
					local odds = Chests.Odds(row)
					for i, name in ChestsConfig.Rarities do
						if math.abs((odds[name] or 0) - own[i] / total) > 1e-12 then
							t.Check(`{row.Id}: {name} at the Tower's row`, false, `{odds[name]}`)
						end
					end
				end
			end
			-- Lantern Row's Tower chest gives what its ladder rows give at their least, and more: rolled, each rarity near its share.
			local row = ChestRows.Of("lanternrow", ChestRows.Tower) :: ChestRows.Row
			local draw = sequence(77)
			local counts: { [string]: number } = {}
			local rolls = 20_000
			for _ = 1, rolls do
				local rarity = Chests.Roll(row, { Warrior = 1 }, draw).Rarity
				counts[rarity] = (counts[rarity] or 0) + 1
			end
			for i, name in ChestsConfig.Rarities do
				local want = rolls * own[i] / total
				local got = counts[name] or 0
				t.Check(`Lantern Row's Tower chest: {name} near its share`, math.abs(got - want) <= 4 * math.sqrt(want) + 1, `{got} against {want}`)
			end
			t.Check("it can give a Legendary, more often than Lantern Row's ladder chests at their least (TR48 part 2)", (counts.Legendary or 0) > 0 and Chests.Odds(ChestRows.Of("lanternrow", 2) :: any).Legendary < own[5] / total)
		end,
	},
	{
		Name = "Chests: a roll is fixed by its draws, fits its slot, and each line is priced at its share of the item's worth",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Tank")
			lead(data, "Mage")
			local classes = Chests.Classes(data)
			local draw = sequence(7)
			local gear = {} -- the chests that hold gear (TR56: a case, a pouch and a crate hold none)
			for _, row in ChestRows.List do
				if Chests.IsGear(row) then
					table.insert(gear, row)
				end
			end
			for i = 1, 400 do
				local row = gear[(i - 1) % #gear + 1]
				local seed = 1000 + i
				local rolled = Chests.Roll(row, classes, sequence(seed))
				t.Check(`{i}: the same draws, the same item`, same(rolled, Chests.Roll(row, classes, sequence(seed))))
				local itemRow = Items.ById[rolled.Def]
				t.Check(`{i}: a row`, itemRow ~= nil, rolled.Def)
				if itemRow == nil then
					continue
				end
				local ground = Grounds.ById[row.Ground]
				t.Equal(`{i}: its tier is its ground's`, rolled.Tier, ground.Order)
				local main = rolled.Lines[1].Stat
				local wanted = ChestsConfig.Main[itemRow.Slot]
				if wanted then
					t.Equal(`{i}: {itemRow.Id}'s main stat is its slot's`, main, wanted)
				else
					t.Check(`{i}: jewellery's main is a Basic Attribute`, Attributes.ById[main] ~= nil, main)
				end
				t.Equal(`{i}: {rolled.Rarity} has its lines`, #rolled.Lines - 1, ChestsConfig.Lines[rolled.Rarity])
				t.Equal(`{i}: and its sockets, empty`, #rolled.Sockets, ChestsConfig.Sockets[rolled.Rarity])
				local seen: { [string]: boolean } = {}
				local worth = ChestsConfig.PowerPerG * ChestsConfig.Rarity[rolled.Rarity] * Growth.G(row.Level or ground.LevelTo) -- a Hard stage's chest: its own level (TR48)
				for index, itemLine in rolled.Lines do
					t.Check(`{i}: {itemLine.Stat} once`, not seen[itemLine.Stat])
					seen[itemLine.Stat] = true
					local share = if index == 1 then ChestsConfig.MainShare else (1 - ChestsConfig.MainShare) / (#rolled.Lines - 1)
					local price = Chests.Price(itemLine.Stat)
					local aim = worth * share
					local off = math.abs(itemLine.Value * price - aim)
					t.Check(`{i}: {itemLine.Stat} within its spread`, off <= aim * ChestsConfig.Spread + price * 0.5 + 1e-9 or itemLine.Value == 1, `{itemLine.Value} x {price} against {aim}`)
				end
				if itemRow.Class then
					t.Check(`{i}: a weapon for a class the player owns`, itemRow.Class == "Tank" or itemRow.Class == "Mage", itemRow.Class)
				end
			end
			t.Check("a draw is in (0, 1)", (function()
				for _ = 1, 1000 do
					local u = draw()
					if not (u > 0 and u < 1) then
						return false
					end
				end
				return true
			end)())
			-- docs/balance.md, "The stats": a point of either is worth about the same at the generic row (TR36); since the
			-- prices became the gains (TR49's must-fix), 9 to 10 a point, where the normalised prices read 6 to 7
			t.Check("an attribute's price is its row weighed: 9 to 10 a point", Chests.Price("Strength") > 9 and Chests.Price("Strength") < 10 and Chests.Price("Endurance") > 9
				and Chests.Price("Endurance") < 10, `{Chests.Price("Strength")}, {Chests.Price("Endurance")}`)
		end,
	},
	{
		Name = "Chests: over 20,000 rolls, each rarity, slot and weapon class lands on its odds",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Assassin")
			lead(data, "Healer")
			local assassin = lead(data, "Assassin")
			data.Roles.Lead = assassin.Id
			local classes = Chests.Classes(data)
			t.Check("the lead's class leans", math.abs(classes.Assassin - ChestsConfig.ClassLean) < 1e-9 and math.abs(classes.Healer - (1 - ChestsConfig.ClassLean)) < 1e-9)
			local row = ChestRows.Of("kiteheights", 1) :: ChestRows.Row
			local odds = Chests.Odds(row)
			local rarities: { [string]: number }, kinds: { [string]: number } = {}, {}
			local weapons, assassins = 0, 0
			local draw = sequence(99)
			local n = 20000
			for _ = 1, n do
				local rolled = Chests.Roll(row, classes, draw)
				rarities[rolled.Rarity] = (rarities[rolled.Rarity] or 0) + 1
				local itemRow = Items.ById[rolled.Def]
				kinds[itemRow.Slot] = (kinds[itemRow.Slot] or 0) + 1
				if itemRow.Class then
					weapons += 1
					assassins += if itemRow.Class == "Assassin" then 1 else 0
				end
			end
			for name, chance in odds do
				t.Check(`{name}: {chance}`, math.abs((rarities[name] or 0) / n - chance) < 0.012, tostring((rarities[name] or 0) / n))
			end
			local slots = #Gear.Shared + #Gear.Hands
			t.Check("a ring is two slots' worth", math.abs((kinds.Ring or 0) / n - 2 / slots) < 0.01, tostring((kinds.Ring or 0) / n))
			t.Check("a helmet one", math.abs((kinds.Helmet or 0) / n - 1 / slots) < 0.008, tostring((kinds.Helmet or 0) / n))
			t.Check("a weapon two", math.abs(weapons / n - 2 / slots) < 0.01, tostring(weapons / n))
			t.Check("most weapons for the lead's class", math.abs(assassins / weapons - ChestsConfig.ClassLean) < 0.03, tostring(assassins / weapons))
			local alone = fresh()
			lead(alone, "Warrior")
			t.Equal("one class owned: all its", Chests.Classes(alone).Warrior, 1)
			t.Equal("no lead: every class alike", count(Chests.Classes(fresh())), count(Gear.Weapons))
		end,
	},
	{
		Name = "Chests: 1,000 opened in steps of 50, every chest removed once and every item granted once",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Warrior")
			local id = chest("drumcourt", 1)
			Chests.Grant(data, id, 1000)
			local seen: { [string]: boolean } = {}
			local granted, steps = 0, 0
			local draw = sequence(4242)
			while (data.Bag.Chests[id] or 0) > 0 do
				local before = data.Bag.Chests[id]
				local answer = Chests.Open(data, id, math.min(ChestsConfig.Step, before), draw)
				steps += 1
				t.Check(`step {steps}: ok`, answer.Ok == true, tostring(answer.Error))
				if answer.Ok ~= true then
					break
				end
				t.Equal(`step {steps}: its chests left the bag`, (data.Bag.Chests[id] or 0), before - answer.Opened)
				t.Equal(`step {steps}: one item a chest`, #answer.Items, answer.Opened)
				for _, itemId in answer.Items do
					t.Check(`{itemId}: granted once`, not seen[itemId] and data.Items[itemId] ~= nil)
					seen[itemId] = true
					granted += 1
					data.Items[itemId] = nil -- the player clears the bag between steps, so the cap never stops the test
				end
			end
			t.Equal("twenty steps", steps, 20)
			t.Equal("a thousand items", granted, 1000)
			t.Check("no chest left, no empty count kept", data.Bag.Chests[id] == nil)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Chests: a repeated open answers its first answer, and a refused one changes nothing",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Mage")
			local id = chest("lanternrow", 1)
			Chests.Grant(data, id, 10)
			local change = function(n: any, which: any): Transaction.Change
				return function(draft: Profile.Data): Transaction.Answer
					return Chests.Open(draft, which or id, n, sequence(5))
				end
			end
			local first = Transaction.Run(data, OP, change(3), 8)
			t.Check("opened", first.Ok == true and #first.Items == 3 and data.Bag.Chests[id] == 7)
			local before = Profile.DeepCopy(data)
			local again, changed = Transaction.Run(data, OP, change(3), 8)
			t.Check("the repeat changes nothing", not changed and same(data, before))
			t.Check("and answers the first answer", same(again.Items, first.Items))
			local refusals = {
				{ "more than held", 8, nil, Chests.NotEnough },
				{ "none", 0, nil, Chests.Unknown },
				{ "past a step", ChestsConfig.Step + 1, nil, Chests.Unknown },
				{ "a part", 1.5, nil, Chests.Unknown },
				{ "no such chest", 1, "nowhere_1", Chests.Unknown },
				{ "a chest not held", 1, chest("lanternrow", 3), Chests.NotEnough },
			}
			for _, case in refusals do
				local answer = Chests.Open(data, case[3] or id, case[2], sequence(1))
				t.Equal(`{case[1]}: refused`, answer.Error, case[4])
				t.Check(`{case[1]}: nothing changed`, same(data, before))
			end
			for n = 1, ChestsConfig.Bag - count(data.Items) - 2 do
				data.Items[`fill{n}`] = { Id = `fill{n}`, Def = "ring", Tier = 1, Rarity = "Common", Design = 1, Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} }
			end
			local full = Profile.DeepCopy(data)
			local answer = Chests.Open(data, id, 3, sequence(1))
			t.Equal("past the bag's cap: refused before rolling", answer.Error, Chests.BagFull)
			t.Check("the chests kept, nothing rolled", same(data, full))
			t.Check("up to the cap still opens", Chests.Open(data, id, 2, sequence(1)).Ok == true)
		end,
	},
	{
		Name = "Chests: a server stopped mid-open applies nothing, and the request sent again opens once",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Healer")
			local id = chest("maskparade", 1)
			Chests.Grant(data, id, 50)
			local before = Profile.DeepCopy(data)
			local calls = 0
			local stopped = Transaction.Run(data, OP, function(draft: Profile.Data): Transaction.Answer
				local draw = sequence(11)
				return Chests.Open(draft, id, 50, function(): number
					calls += 1
					if calls == 200 then
						error("the server stopped")
					end
					return draw()
				end)
			end, 8)
			t.Check("the stop is refused", stopped.Ok == false and stopped.Error == Transaction.Failed and calls == 200)
			t.Check("and changed nothing: the chests held, no item, no id spent", same(data, before))
			local change = function(draft: Profile.Data): Transaction.Answer
				return Chests.Open(draft, id, 50, sequence(11))
			end
			local sent = Transaction.Run(data, OP, change, 8)
			t.Check("sent again, it opens", sent.Ok == true and #sent.Items == 50 and data.Bag.Chests[id] == nil)
			local after = Profile.DeepCopy(data)
			local again, changed = Transaction.Run(data, OP, change, 8)
			t.Check("and once: the third send changes nothing", not changed and same(data, after) and same(again.Items, sent.Items))
			t.Equal("fifty items in all", count(data.Items), 50)
		end,
	},
	{
		Name = "Chests: the salvage turns its rarity and under into Credits, never what would raise Combat Power",
		Run = function(t: any)
			local data = fresh()
			local owned = lead(data, "Warrior")
			t.Equal("an unknown rarity refused", Chests.SetSalvage(data, "Shiny").Error, Chests.Unknown)
			t.Check("Legendary and under", Chests.SetSalvage(data, "Legendary").Ok == true and data.Settings.Salvage == "Legendary")
			-- Worn: an item in every slot too strong for any Lantern Row roll to beat: every stat a roll can carry (its main
			-- stat or a line, Config.Chests.Main and Pool) far past any roll's. Under the combat review's Combat Power (TR49)
			-- a stat the worn set lacked, a resist, is a real gain, so the set carries them all.
			local function strong(): { Profile.ItemLine }
				local lines: { Profile.ItemLine } = {}
				for stat in ChestsConfig.Pool do
					table.insert(lines, { Stat = stat, Value = if Attributes.ById[stat] then 1e5 else 1e6 })
				end
				table.sort(lines, function(a: Profile.ItemLine, b: Profile.ItemLine): boolean
					return a.Stat < b.Stat
				end)
				return lines
			end
			for _, slot in Gear.Shared do
				local id = Profile.NewId(data)
				data.Items[id] = { Id = id, Def = Items.ById[string.lower((string.gsub(Gear.Family(slot), " ", "_")))].Id, Tier = 6, Rarity = "Legendary", Design = 1, Lines = strong(), Sockets = {}, Reinforce = 0, Jewels = {} }
				Regalia.Put(data.Presets[1], slot, nil, id)
			end
			for _, hand in Gear.Hands do
				local id = Profile.NewId(data)
				local def = if hand == "Main Hand" then "sword" else "short_sword"
				data.Items[id] = { Id = id, Def = def, Tier = 6, Rarity = "Legendary", Design = 1, Lines = strong(), Sockets = {}, Reinforce = 0, Jewels = {} }
				Regalia.Put(data.Presets[1], hand, "Warrior", id)
			end
			local worn = count(data.Items)
			local id = chest("lanternrow", 1)
			Chests.Grant(data, id, 40)
			local credits = data.Currency.Credits
			local answer = Chests.Open(data, id, 40, sequence(31))
			local expected = 0
			local replay = sequence(31)
			local classes = Chests.Classes(data)
			local weaponsElsewhere = 0
			for _ = 1, 40 do
				local rolled = Chests.Roll(ChestRows.ById[id], classes, replay)
				expected += Chests.Salvage(rolled)
				weaponsElsewhere += if Items.ById[rolled.Def].Class and Items.ById[rolled.Def].Class ~= "Warrior" then 1 else 0
			end
			t.Check("all forty salvaged: none beats what's worn", answer.Ok == true and answer.Salvaged == 40 and #answer.Items == 0, `{answer.Salvaged}`)
			t.Equal("their Credits, the same rolls replayed", answer.Credits, expected)
			t.Equal("paid", data.Currency.Credits - credits, expected)
			t.Equal("no item added", count(data.Items), worn)
			Chests.SetSalvage(data, "Common")
			Chests.Grant(data, id, 40)
			local commons = Chests.Open(data, id, 40, sequence(32))
			local replayed, common = sequence(32), 0
			for _ = 1, 40 do
				common += if Chests.Roll(ChestRows.ById[id], classes, replayed).Rarity == "Common" then 1 else 0
			end
			t.Check("Common: the Commons salvaged, the Uncommons kept", common > 0 and common < 40 and commons.Salvaged == common and #commons.Items == 40 - common, `{commons.Salvaged} of {common}`)
			for _, itemId in commons.Items do
				data.Items[itemId] = nil
			end
			Chests.SetSalvage(data, "Legendary")
			local full = data.Presets[1]
			data.Presets[1] = { Slots = {}, Hands = {} }
			Chests.Grant(data, id, 40)
			local open = Chests.Open(data, id, 40, sequence(31))
			local weapons = 0
			for _, itemId in open.Items do
				weapons += if Items.ById[data.Items[itemId].Def].Class then 1 else 0
			end
			t.Equal("nothing worn: every armour and Warrior weapon kept, as each would raise it", #open.Items, 40 - weaponsElsewhere)
			t.Equal("only another class's weapon, with none of that class owned, salvaged", open.Salvaged, weaponsElsewhere)
			t.Check("Lantern Row gave the Warrior's weapons only", weapons >= 0 and weaponsElsewhere == 0, `{weaponsElsewhere}`)
			-- A second class's best, wearing nothing: armour now raises its figure, so the salvage keeps it.
			data.Presets[1] = full
			local healer = lead(data, "Healer")
			healer.Preset = 2
			data.Presets[2] = { Slots = {}, Hands = {} }
			data.Roles.Lead = owned.Id
			Chests.Grant(data, id, 40)
			local shared = Chests.Open(data, id, 40, sequence(31))
			local armour, healers = 0, 0
			for _, itemId in shared.Items do
				local itemRow = Items.ById[data.Items[itemId].Def]
				armour += if itemRow.Class == nil then 1 else 0
				healers += if itemRow.Class == "Healer" then 1 else 0
			end
			t.Check("a shared piece kept for any class's best: every armour, every Healer weapon", armour > 0 and healers + armour == #shared.Items and shared.Salvaged == 40 - #shared.Items, `{armour} armour, {healers} Healer, {shared.Salvaged} salvaged`)
			Chests.SetSalvage(data, "")
			t.Equal("off", data.Settings.Salvage, "")
			t.Check(`the worn Voidkin stood: {owned.Id}`, data.Voidkin[owned.Id] ~= nil)
		end,
	},
	{
		-- D3 (the director, 2026-11-18): Combat Power shows a tenth, so a small gain can stay under half a shown point.
		-- It is judged on the unrounded sum: the salvage keeps it, the bag marks it, and its card words it finer than none.
		Name = "Chests: a gain too small to move the shown Combat Power is still a gain: kept by the salvage, marked in the bag, worded on its card",
		Run = function(t: any)
			local data = fresh()
			local owned = lead(data, "Warrior")
			local slot = Gear.Shared[1]
			local def = Items.ById[string.lower((string.gsub(Gear.Family(slot), " ", "_")))].Id
			local function item(health: number): string
				local id = Profile.NewId(data)
				data.Items[id] = { Id = id, Def = def, Tier = 1, Rarity = "Common", Design = 1, Lines = { { Stat = "Health", Value = health } }, Sockets = {}, Reinforce = 0, Jewels = {} }
				return id
			end
			Regalia.Put(data.Presets[1], slot, nil, item(10))
			local better = item(10.1)
			local preset = Stats.PresetOf(data, owned)
			local change = Stats.Compare(data, preset, owned, better)
			t.Check("it compares", change ~= nil and change.Slot == slot, if change then change.Slot else "none")
			if change == nil then
				return
			end
			local before = Stats.Resolve(owned, preset, data)
			t.Equal("the shown figure doesn't move", Stats.Power(change.After), Stats.Power(before))
			t.Check("the unrounded sum does, by under half a point", change.Power > 0 and change.Power < 0.5, tostring(change.Power))
			local best = Chests.For(data)
			local warrior = best.Warrior
			t.Equal("its class's best is the one wearing it", if warrior then warrior.Id else "", owned.Id)
			t.Check("the salvage keeps it", Chests.Keep(data, better, best))
			local entry: Bag.Entry? = nil
			for _, each in Bag.List(data, owned, "All", "Rarity") do
				if each.Id == better then
					entry = each
				end
			end
			t.Check("the bag gives it the up arrow", entry ~= nil and entry.Up == true and entry.Gain == change.Power)
			local card = Bag.Card(data, owned, better)
			t.Check("its card's change is the sum's", card ~= nil and math.abs(card.Power - change.Power) < 1e-9, if card then tostring(card.Power) else "none")
			t.Equal("worded finer than none", Sheet.Change("Power", change.Power), "+0.1")
			local worse = item(9.9)
			local loss = Stats.Compare(data, preset, owned, worse)
			t.Check("a loss as small is a loss, never kept", loss ~= nil and loss.Power < 0 and not Chests.Keep(data, worse, best))
		end,
	},
	{
		Name = "Chests: one owned item salvaged by hand pays its Credits once, never a worn one, and frees a full bag for a chest",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Warrior")
			local function item(def: string, rarity: string): string
				local id = Profile.NewId(data)
				data.Items[id] = { Id = id, Def = def, Tier = 1, Rarity = rarity, Design = 1, Lines = { { Stat = "Attack", Value = 3 } }, Sockets = {}, Reinforce = 0, Jewels = {} }
				return id
			end
			local spare, sword, armour = item("sword", "Uncommon"), item("sword", "Common"), item(Items.List[1].Id, "Common")
			local shared: string? = nil
			for _, row in Items.List do
				if row.Class == nil and not Gear.IsHand(row.Slot) then
					data.Items[armour].Def = row.Id
					shared = Gear.SlotsOf(row.Slot)[1]
					break
				end
			end
			t.Check("a shared piece to wear", shared ~= nil)
			Regalia.Put(data.Presets[1], "Main Hand", "Warrior", sword)
			Regalia.Put(data.Presets[1], shared :: string, nil, armour)
			t.Check("worn: the hand's and the shared slot's", Chests.IsWorn(data, sword) and Chests.IsWorn(data, armour) and not Chests.IsWorn(data, spare))
			local before, held = table.clone(data.Currency), count(data.Items)
			for _, bad in { nil, 7, "", "no-such-item", {} } :: { any } do
				local answer = Chests.SalvageItem(data, bad)
				t.Check(`{tostring(bad)}: not owned, nothing changed`, answer.Ok == false and answer.Error == Chests.NotOwned and count(data.Items) == held and data.Currency.Credits == before.Credits)
			end
			for _, id in { sword, armour } do
				local answer = Chests.SalvageItem(data, id)
				t.Check("a worn item: refused, kept, unpaid", answer.Ok == false and answer.Error == Chests.Worn and data.Items[id] ~= nil and data.Currency.Credits == before.Credits)
			end
			local worth = Chests.Salvage(data.Items[spare])
			local answer = Chests.SalvageItem(data, spare)
			t.Check("its Credits, the opened chest's own salvage price", worth > 0 and answer.Ok == true and answer.Item == spare and answer.Credits == worth)
			t.Check("gone and paid", data.Items[spare] == nil and count(data.Items) == held - 1 and data.Currency.Credits == before.Credits + worth)
			t.Check("asked again: not owned, never paid twice", Chests.SalvageItem(data, spare).Error == Chests.NotOwned and data.Currency.Credits == before.Credits + worth)
			t.Check("the worn ones still worn", Chests.IsWorn(data, sword) and Chests.IsWorn(data, armour))
			-- Taken off, it can go, and what was put in it is kept (TR72, item 2): its emblems and jewels to the bag, its
			-- Reinforce level lost and said.
			Regalia.Put(data.Presets[1], "Main Hand", "Warrior", nil)
			local kept = data.Items[sword]
			local emblem = Emblems.Key(EmblemSets.List[1].Id, "Attack")
			local slotted = #kept.Sockets > 0
			if slotted then
				kept.Sockets[1] = emblem
			end
			kept.Jewels = { Red = 2, Blue = 1 }
			kept.Reinforce = 7
			local emblemsHad, redHad, blueHad = data.Bag.Emblems[emblem] or 0, data.Bag.Jewels["Red:2"] or 0, data.Bag.Jewels["Blue:1"] or 0
			local gone = Chests.SalvageItem(data, sword)
			t.Check("taken off: salvaged", gone.Ok == true and data.Items[sword] == nil)
			if slotted then
				t.Check("its emblem to the bag", (data.Bag.Emblems[emblem] or 0) == emblemsHad + 1 and #gone.Emblems == 1 and gone.Emblems[1] == emblem)
			end
			t.Check("its jewels to the bag", (data.Bag.Jewels["Red:2"] or 0) == redHad + 1 and (data.Bag.Jewels["Blue:1"] or 0) == blueHad + 1)
			t.Equal("and said, each once", table.concat(gone.Jewels, ","), "Blue:1,Red:2")
			t.Equal("its +7 lost, and said", gone.Lost, 7)
			-- The full bag: a chest refused at the cap opens once one item is salvaged.
			while count(data.Items) < ChestsConfig.Bag do
				item("sword", "Common")
			end
			local id = chest("lanternrow", 1)
			Chests.Grant(data, id, 1)
			t.Equal("at the cap: the chest refused", Chests.Open(data, id, 1, sequence(5)).Error, Chests.BagFull)
			local one: string? = nil
			for itemId in data.Items do
				if not Chests.IsWorn(data, itemId) then
					one = itemId
					break
				end
			end
			t.Check("one salvaged by hand", one ~= nil and Chests.SalvageItem(data, one).Ok == true)
			t.Check("and the chest opens", Chests.Open(data, id, 1, sequence(5)).Ok == true)
		end,
	},
	{
		Name = "Chests: an elite's chest always, a Shade's at its chance, one sure on the third kill, a keeper's better first",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Tank")
			local shade, elite = chest("lanternrow", 1), chest("lanternrow", 2)
			local first = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, 0.5)
			t.Equal("the first kill, over its chance: none", first.Chest, "")
			local second = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, 0.01)
			t.Equal("the second, under its chance: a Shade's chest", second.Chest, shade)
			local third = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, 0.99)
			t.Equal("the third, whatever the roll", third.Chest, shade)
			local fourth = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, nil)
			t.Equal("no roll, no chest after", fourth.Chest, "")
			t.Equal("two in the bag, stacked", data.Bag.Chests[shade], 2)
			t.Equal("an elite's, every time", Drops.Give(data, "Elite", 3, "lanternrow", 0.99, 0.999).Chest, elite)
			t.Equal("a keeper's fall drops none of its own", Drops.Give(data, "Keeper", 9, "lanternrow", 0.99, 0.0).Chest, "")
			local won = Progress.KeeperWon(data, "lanternrow", NOW)
			t.Equal("the keeper's first win: the best", won.Chest, chest("lanternrow", 3))
			local again = Progress.KeeperWon(data, "lanternrow", NOW + 1000)
			t.Equal("after: an elite's", again.Chest, elite)
			t.Equal("Drum Court's keeper first: its own best", Progress.KeeperWon(data, "drumcourt", NOW).Chest, chest("drumcourt", 3))
			t.Equal("Drum Court's Shade chest from Drum Court", Chests.Dropped("Ordinary", "drumcourt", 40, 0.0), chest("drumcourt", 1))
			t.Equal("an unknown kind drops none", Chests.Dropped("Nobody", "lanternrow", 2, 0.0), nil)
		end,
	},
	{
		Name = "Chests: the save at a full bag of the richest chest's items stays small",
		Run = function(t: any)
			local data = fresh()
			lead(data, "Warrior")
			local id = chest("mirrorpavilion", 3)
			Chests.Grant(data, id, ChestsConfig.Bag)
			local draw = sequence(77)
			while (data.Bag.Chests[id] or 0) > 0 do
				local answer = Chests.Open(data, id, math.min(ChestsConfig.Step, data.Bag.Chests[id]), draw)
				if answer.Ok ~= true then
					break
				end
			end
			t.Equal("a full bag", count(data.Items), ChestsConfig.Bag)
			local whole = size(data)
			local each = size(data.Items) / ChestsConfig.Bag
			t.Check(`about {math.floor(each)} bytes an item, {math.floor(whole / 1024)} KB in all, under 100 KB`, whole < 100 * 1024 and each < 400, `{whole}`)
			local problems = Saveable.Problems(data, "profile")
			t.Check("still saves whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Chests: an item's design, fixed at its drop, never moved by a design added later, never a stat",
		Run = function(t: any)
			-- every kind has its three designs at every rarity, each named, each with its picture in the kit
			for _, row in Items.List do
				for _, rarity in ChestsConfig.Rarities do
					local by = ItemDesigns.ByKind[row.Kind]
					local list: { ItemDesigns.Design } = if by and by[rarity] then by[rarity] else {}
					t.Equal(`{row.Id} {rarity}: three designs`, #list, 3)
					t.Equal(`{row.Id} {rarity}: Items.Designs counts them`, Items.Designs(row.Id, rarity), #list)
					for i, design in list do
						t.Check(`{row.Id} {rarity} {i}: a name`, #design.Name > 0)
						t.Check(`{row.Id} {rarity} {i}: its picture is in the kit`, UIKit.Images[design.Image] ~= nil, design.Image)
					end
				end
			end
			-- a drop draws its design last, from its kind's at its rarity
			local data = fresh()
			lead(data, "Warrior")
			local classes = Chests.Classes(data)
			local row = ChestRows.ById[chest("lanternrow", 1)]
			local seen: { [number]: number } = {}
			local rolls = 3000
			local last = true
			for seed = 1, rolls do
				local inner = sequence(5000 + seed)
				local final = 0
				local rolled = Chests.Roll(row, classes, function(): number
					final = inner()
					return final
				end)
				local n = Items.Designs(rolled.Def, rolled.Rarity)
				last = last and rolled.Design == math.clamp(math.floor(final * n) + 1, 1, n)
				seen[rolled.Design] = (seen[rolled.Design] or 0) + 1
			end
			t.Check("the design is the roll's last draw", last)
			for design = 1, 3 do
				local share = (seen[design] or 0) / rolls
				t.Check(`design {design} drops about a third of the time`, share > 0.29 and share < 0.38, string.format("%.3f", share))
			end
			-- opened, the item keeps the design its roll drew
			data.Bag.Chests[row.Id] = 20
			local opened = Chests.Open(data, row.Id, 20, function()
				return 0.999
			end)
			t.Check("opened", opened.Ok == true, tostring(opened.Error))
			for _, id in opened.Items or {} do
				t.Equal(`{id}: the last draw's design`, data.Items[id].Design, Items.Designs(data.Items[id].Def, data.Items[id].Rarity))
			end
			-- a design added later moves no item: the item keeps its index, and the launch's fill never reads the list
			local item = data.Items[(opened.Items or {})[1]]
			if item then
				item.Design = 2
				local kind = Items.ById[item.Def].Kind
				local list = ItemDesigns.ByKind[kind][item.Rarity]
				local before, launch = (Items.Design(item) :: ItemDesigns.Design).Name, Items.LaunchDesign(item.Id)
				table.insert(list, { Name = "Case's fourth", Image = "GearLight" })
				t.Equal("with a fourth design, the same design", (Items.Design(item) :: ItemDesigns.Design).Name, before)
				t.Equal("with a fourth design, the same launch design", Items.LaunchDesign(item.Id), launch)
				t.Equal("a drop now picks from four", Items.Designs(item.Def, item.Rarity), 4)
				table.remove(list)
			end
			-- the launch's fill: the same id the same design, always one of three, spread across them
			local spread: { [number]: number } = {}
			for n = 1, 3000 do
				local design = Items.LaunchDesign(`i{n}`)
				spread[design] = (spread[design] or 0) + 1
			end
			t.Equal("the launch's fill: one id, one design", Items.LaunchDesign("i42"), Items.LaunchDesign("i42"))
			t.Check("the launch's fill: only the three", (spread[1] or 0) + (spread[2] or 0) + (spread[3] or 0) == 3000)
			t.Check("the launch's fill: each about a third", (spread[1] or 0) > 800 and (spread[2] or 0) > 800 and (spread[3] or 0) > 800, `{spread[1]}, {spread[2]}, {spread[3]}`)
			-- migration 7: an item saved before designs takes its launch design, once
			local old = Profile.Template()
			Migrations.Run(old)
			old.Version = 6
			old.Items.x = { Id = "x", Def = "sword", Tier = 1, Rarity = "Rare", Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} } :: any
			old.Items.kept = { Id = "kept", Def = "sword", Tier = 1, Rarity = "Rare", Design = 3, Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} }
			Migrations.Run(old)
			t.Equal("an old item takes its launch design", old.Items.x.Design, Items.LaunchDesign("x"))
			t.Equal("an item with a design keeps it", old.Items.kept.Design, 3)
			t.Equal("at the latest", old.Version, Migrations.Latest)
			-- a design is never a stat: the same item in every design, the same Combat Power
			local held = fresh()
			local owned = lead(held, "Warrior")
			local id = Profile.NewId(held)
			held.Items[id] = { Id = id, Def = "sword", Tier = 3, Rarity = "Epic", Design = 1, Lines = { { Stat = "Attack", Value = 400 }, { Stat = "Strength", Value = 30 } }, Sockets = {}, Reinforce = 0, Jewels = {} }
			Regalia.Put(held.Presets[1], "Main Hand", "Warrior", id)
			local powers = {}
			for design = 1, 3 do
				held.Items[id].Design = design
				powers[design] = Stats.Power((Stats.Resolve(owned, Stats.PresetOf(held, owned), held)))
			end
			t.Check("worn, the sword raises Combat Power", powers[1] > Stats.Power((Stats.Resolve(owned, nil, held))))
			t.Check("every design, the same Combat Power", powers[1] == powers[2] and powers[2] == powers[3], `{powers[1]}, {powers[2]}, {powers[3]}`)
		end,
	},
	{
		Name = "Chests (section 9): gear's whole way, seeded, repeated and cut short in any order, never makes or loses a chest, an item, a Credit, a stone or an emblem",
		Run = function(t: any)
			local seed = 20261121
			local function roll(n: number): number -- Park-Miller, exact in doubles: the same steps every run
				seed = (seed * 16807) % 2147483647
				return seed % n + 1
			end
			local function unit(): number
				return (roll(9999) - 0.5) / 9999
			end
			local KEEP = 8 -- short, so ids leave the ledger and come back as new requests
			local data = fresh()
			lead(data, "Warrior")
			local CHESTS = { ChestRows.List[1].Id, ChestRows.List[2].Id }
			local KEYS = { "talon:Attack", "talon:Hit", "warhorn:Defence" }
			for _, chest in CHESTS do
				data.Bag.Chests[chest] = 12
			end
			for _, key in KEYS do
				data.Bag.Emblems[key] = 3
			end
			for _, grade in ReinforceConfig.Grades do
				data.Bag.Stones[grade] = 30
			end
			data.Currency.Credits = 40_000
			local function sum(map: { [string]: number }): number
				local n = 0
				for _, count in map do
					n += count
				end
				return n
			end
			local function socketed(of: Profile.Data): number
				local n = 0
				for _, item in of.Items do
					for _, key in item.Sockets do
						n += if key ~= "" then 1 else 0
					end
				end
				return n
			end
			local function items(): { string }
				local ids = {}
				for id in data.Items do
					table.insert(ids, id)
				end
				table.sort(ids)
				return ids
			end
			local function any(): string
				local ids = items()
				return if #ids == 0 then "none" else ids[roll(#ids)]
			end
			-- Each action as its service runs it, by the name a request carries.
			local DO: { [string]: (Profile.Data, any, number, Chests.Draw) -> { [string]: any } } = {
				Open = function(draft: Profile.Data, args: any, _: number, draws: Chests.Draw): { [string]: any }
					return Chests.Open(draft, args.Chest, args.Count, draws)
				end,
				Try = function(draft: Profile.Data, args: any, u: number): { [string]: any }
					return Reinforce.Try(draft, args, u)
				end,
				Socket = function(draft: Profile.Data, args: any): { [string]: any }
					return Emblems.Socket(draft, args)
				end,
				Unsocket = function(draft: Profile.Data, args: any): { [string]: any }
					return Emblems.Unsocket(draft, args)
				end,
				Equip = function(draft: Profile.Data, args: any): { [string]: any }
					return Regalia.Actions.Equip(draft, args)
				end,
				SalvageItem = function(draft: Profile.Data, args: any): { [string]: any }
					return Chests.SalvageItem(draft, args.Item)
				end,
				SetSalvage = function(draft: Profile.Data, args: any): { [string]: any }
					return Chests.SetSalvage(draft, args.Below)
				end,
			}
			local chests0, credits0, stones0, emblems0 = sum(data.Bag.Chests), data.Currency.Credits, sum(data.Bag.Stones), sum(data.Bag.Emblems)
			local opened, made, salvaged, creditsIn, creditsOut, stonesOut = 0, 0, 0, 0, 0, 0
			local autoSalvaged, carried = 0, 0 -- items salvaged as they came out, and emblems a Move carried over
			local held: { string } = {}
			local sent: { [string]: { Name: string, Args: any, U: number } } = {}
			local applied, repeats, cuts, broken = {} :: { [string]: number }, 0, 0, 0
			local function check(step: number, name: string): string?
				if sum(data.Bag.Chests) + opened ~= chests0 then
					return `chests: {sum(data.Bag.Chests)} held and {opened} opened of {chests0}`
				elseif #items() ~= made - salvaged then
					return `items: {#items()} held, {made} made, {salvaged} salvaged`
				elseif data.Currency.Credits ~= credits0 + creditsIn - creditsOut or data.Currency.Credits < 0 then
					return `Credits: {data.Currency.Credits} against {credits0 + creditsIn - creditsOut}`
				elseif sum(data.Bag.Stones) ~= stones0 - stonesOut then
					return `stones: {sum(data.Bag.Stones)} against {stones0 - stonesOut}`
				elseif sum(data.Bag.Emblems) + socketed(data) ~= emblems0 then -- a salvage puts its emblems back (TR72, item 2)
					return `emblems: {sum(data.Bag.Emblems)} + {socketed(data)} against {emblems0}`
				end
				for _, preset in data.Presets do
					for slot, id in preset.Slots do
						if data.Items[id] == nil then
							return `{slot} wears {id}, which is gone`
						end
					end
				end
				for id, item in data.Items do
					if item.Reinforce < 0 or item.Reinforce > ReinforceConfig.Cap then
						return `{id} at Reinforce {item.Reinforce}`
					end
				end
				return nil
			end
			for step = 1, 400 do
				local op = string.format("%08x-0000-4000-8000-%012x", roll(24), 2)
				local ask = sent[op]
				if ask == nil then
					local pick = roll(12)
					if pick <= 3 then
						ask = { Name = "Open", Args = { Chest = CHESTS[roll(#CHESTS)], Count = roll(3) }, U = 0 }
					elseif pick <= 5 then
						ask = { Name = "Try", Args = { Item = any() }, U = unit() }
					elseif pick <= 7 then
						local id = any()
						local sockets = if data.Items[id] then #data.Items[id].Sockets else 0
						ask = { Name = "Socket", Args = { Item = id, Socket = if sockets > 0 then roll(sockets) else 1, Emblem = KEYS[roll(#KEYS)] }, U = 0 }
					elseif pick == 8 then
						-- a filled socket when there is one, so the emblem comes out
						local filled: { { Item: string, Socket: number } } = {}
						for _, id in items() do
							for index, key in data.Items[id].Sockets do
								if key ~= "" then
									table.insert(filled, { Item = id, Socket = index })
								end
							end
						end
						ask = { Name = "Unsocket", Args = if #filled > 0 then filled[roll(#filled)] else { Item = any(), Socket = 1 }, U = 0 }
					elseif pick <= 10 then
						-- half the time, a Move onto a worn piece that holds emblems, so they follow the new one
						local moves: { { Slot: string, Item: string } } = {}
						if roll(2) == 1 then
							for slot, wornId in data.Presets[1].Slots do
								local worn = data.Items[wornId]
								if worn and socketed({ Items = { worn } } :: any) > 0 then
									for _, id in items() do
										local row = Items.ById[data.Items[id].Def]
										if id ~= wornId and row and row.Slot == (string.gsub(slot, " I+$", "")) then
											table.insert(moves, { Slot = slot, Item = id })
										end
									end
								end
							end
						end
						if #moves > 0 then
							local move = moves[roll(#moves)]
							ask = { Name = "Equip", Args = { Preset = 1, Slot = move.Slot, Item = move.Item, Move = true }, U = 0 }
						else
							local id = any()
							local row = if data.Items[id] then Items.ById[data.Items[id].Def] else nil
							local slot = if row == nil then "Helmet" elseif row.Slot == "Ring" or row.Slot == "Earring" then `{row.Slot} {if roll(2) == 1 then "I" else "II"}` else row.Slot
							ask = { Name = "Equip", Args = { Preset = 1, Slot = slot, Item = id, Move = roll(2) == 1 }, U = 0 }
						end
					elseif pick == 11 then
						ask = { Name = "SalvageItem", Args = { Item = any() }, U = 0 }
					else
						ask = { Name = "SetSalvage", Args = { Below = ({ "", "Common", "Uncommon" })[roll(3)] }, U = 0 }
					end
					sent[op] = ask
				end
				local cut = roll(6) == 1 -- the server falls over after the action, before its change finishes
				local before = Profile.DeepCopy(data)
				local draws = sequence(roll(2147483646))
				local answer, changed = Transaction.Run(data, op, function(draft: Profile.Data): Transaction.Answer
					local done = DO[ask.Name](draft, ask.Args, ask.U, draws)
					if cut then
						error("interrupted")
					end
					return done
				end, KEEP)
				local again = table.find(held, op) ~= nil
				if again or cut then
					if again then
						repeats += 1
					else
						cuts += 1
					end
					if changed or not same(data, before) then
						broken += 1
						t.Check(`step {step}: a {if again then "repeat" else "cut"} of {ask.Name} changes nothing`, false)
					end
				elseif changed then
					local name: any = ask.Name
					applied[name] = (applied[name] or 0) + 1
					if name == "Open" then
						opened += answer.Opened
						made += answer.Opened - answer.Salvaged
						creditsIn += answer.Credits
						autoSalvaged += answer.Salvaged
					elseif name == "SalvageItem" then
						salvaged += 1
						creditsIn += answer.Credits
					elseif name == "Try" then
						creditsOut += answer.Credits
						stonesOut += answer.Stones
					elseif name == "Equip" and answer.Moved then
						local was = before.Items[before.Presets[1].Slots[ask.Args.Slot]]
						carried += if was and socketed({ Items = { was } } :: any) > 0 then 1 else 0
					end
					table.insert(held, op)
					if #held > KEEP then
						sent[table.remove(held, 1) :: string] = nil -- its next use is a new request
					end
				end
				local wrong = check(step, ask.Name)
				if wrong then
					broken += 1
					t.Check(`step {step} ({ask.Name}): everything is held or accounted for, once`, false, wrong)
					break
				end
			end
			t.Equal("no step made or lost anything", broken, 0)
			local each = {}
			for _, name in { "Open", "Try", "Socket", "Unsocket", "Equip", "SalvageItem" } do
				table.insert(each, `{name} {applied[name] or 0}`)
			end
			t.Check(`every action applied, repeated ({repeats}) and cut ({cuts}) often: {table.concat(each, ", ")}, {autoSalvaged} salvaged on opening, {carried} Moves carrying emblems`, (applied.Open or 0) >= 5 and (applied.Try or 0) >= 5 and (applied.Socket or 0) >= 5 and (applied.Unsocket or 0) >= 3 and (applied.Equip or 0) >= 5 and (applied.SalvageItem or 0) >= 3 and autoSalvaged >= 3 and carried >= 3 and repeats >= 20 and cuts >= 20)
			local problems = Saveable.Problems(data, "profile")
			t.Check("the save stays whole", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Chests: the account's first item of each rarity from Rare up, once (TR57's firsts); a save from before reads what it held; a bought one is seen too",
		Run = function(t: any)
			local data = fresh()
			local function give(rarity: string): string
				local id = Profile.NewId(data)
				data.Items[id] = { Id = id, Def = Items.List[1].Id, Tier = 1, Rarity = rarity, Design = 1, Lines = {}, Sockets = {}, Reinforce = 0, Jewels = {} }
				return id
			end
			-- a save from before the mark: an Epic held already, so only Rare and Legendary are firsts
			give("Epic")
			t.Check("no mark yet", data.Bag.Seen == nil)
			local common, rare, rare2, epic, legendary = give("Common"), give("Rare"), give("Rare"), give("Epic"), give("Legendary")
			local firsts = Chests.Firsts(data, { common, rare, rare2, epic, legendary })
			t.Check("the first Rare and the first Legendary, in the order opened; a Common never, a second Rare never, an Epic held before never",
				#firsts == 2 and firsts[1] == rare and firsts[2] == legendary, table.concat(firsts, ","))
			t.Check("the rarities marked seen", data.Bag.Seen ~= nil and (data.Bag.Seen :: any).Rare and (data.Bag.Seen :: any).Epic and (data.Bag.Seen :: any).Legendary and not (data.Bag.Seen :: any).Common)
			t.Equal("once: the next Rare is no first", #Chests.Firsts(data, { give("Rare") }), 0)
			-- a new account: its first Rare from a chest's open is a first, and the answer says what it is
			local new = fresh()
			local top: ChestRows.Row? = nil -- the highest gear chest, so Rares and better come
			for _, row in ChestRows.List do
				if Chests.IsGear(row) and (top == nil or row.Tier > (top :: ChestRows.Row).Tier) then
					top = row
				end
			end
			local chest = (top :: ChestRows.Row).Id
			new.Bag.Chests[chest] = 40
			local seenFirst: { [string]: number } = {}
			for round = 1, 8 do
				local answer = Chests.Open(new, chest, 5, sequence(7 + round))
				for _, first in (answer.Firsts or {}) :: { any } do
					seenFirst[first.Rarity] = (seenFirst[first.Rarity] or 0) + 1
					t.Check(`a first's answer names it: {first.Rarity}`, type(first.Id) == "string" and new.Items[first.Id] ~= nil and first.Def == new.Items[first.Id].Def and first.Design == new.Items[first.Id].Design)
				end
			end
			local twice = false
			for _, n in seenFirst do
				twice = twice or n > 1
			end
			t.Check("over many opens, each rarity's first comes once at most, and some came", not twice and next(seenFirst) ~= nil, `{seenFirst.Rare or 0} Rare, {seenFirst.Epic or 0} Epic`)
		end,
	},
}
