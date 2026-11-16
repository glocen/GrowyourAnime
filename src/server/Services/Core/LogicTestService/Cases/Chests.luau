--!strict
-- Chests cases (pure): part 11's chests (docs/engineering-plan.md, "Chests"; Rules.Chests). The rows and their odds; a
-- roll fixed by its draws and priced at its item's worth; the shares over many rolls; 1,000 opened in steps, each chest
-- removed once and each item granted once; a repeat answering its first answer and a refusal changing nothing; the
-- salvage, which never takes what would raise Combat Power; the drops at a fall and a keeper's win; the save at a full
-- bag. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

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
local Growth = require(Shared.Rules.Growth)
local Collection = require(Shared.Rules.Collection)
local Stats = require(Shared.Rules.Stats)
local ItemDesigns = require(Shared.Definitions.ItemDesigns)
local UIKit = require(Shared.Config.UIKit)

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
			t.Equal("Lantern Row's Shade chest never gives a Rare", Chests.Odds(ChestRows.Of("lanternrow", 1) :: any).Rare, 0)
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
			-- Lantern Row's Tower chest can give what its ladder row can't: rolled, each rarity near its share.
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
			t.Check("it can give a Legendary, as no ladder row of Lantern Row's can", (counts.Legendary or 0) > 0 and Chests.Odds(ChestRows.Of("lanternrow", 2) :: any).Legendary == 0)
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
			for i = 1, 400 do
				local row = ChestRows.List[(i - 1) % #ChestRows.List + 1]
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
				local worth = ChestsConfig.PowerPerG * ChestsConfig.Rarity[rolled.Rarity] * Growth.G(ground.LevelTo)
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
			t.Check("an attribute's price is its row weighed: 5 to 6.5 a point", Chests.Price("Might") > 5 and Chests.Price("Might") < 6.5 and Chests.Price("Spirit") > 5, `{Chests.Price("Might")}, {Chests.Price("Spirit")}`)
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
				data.Items[`fill{n}`] = { Id = `fill{n}`, Def = "ring", Tier = 1, Rarity = "Common", Design = 1, Lines = {}, Sockets = {}, Jewel = "" }
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
			-- Worn: an item in every slot too strong for any Lantern Row roll to beat.
			for _, slot in Gear.Shared do
				local id = Profile.NewId(data)
				data.Items[id] = { Id = id, Def = Items.ById[string.lower((string.gsub(Gear.Family(slot), " ", "_")))].Id, Tier = 6, Rarity = "Legendary", Design = 1, Lines = { { Stat = "Attack", Value = 1e6 }, { Stat = "Health", Value = 1e6 }, { Stat = "Might", Value = 1e5 }, { Stat = "Finesse", Value = 1e5 }, { Stat = "Vigor", Value = 1e5 }, { Stat = "Spirit", Value = 1e5 }, { Stat = "Insight", Value = 1e5 }, { Stat = "Defence", Value = 1e6 } }, Sockets = {}, Jewel = "" }
				Regalia.Put(data.Presets[1], slot, nil, id)
			end
			for _, hand in Gear.Hands do
				local id = Profile.NewId(data)
				local def = if hand == "Main Hand" then "sword" else "short_sword"
				data.Items[id] = { Id = id, Def = def, Tier = 6, Rarity = "Legendary", Design = 1, Lines = { { Stat = "Attack", Value = 1e6 }, { Stat = "Might", Value = 1e5 }, { Stat = "Hit", Value = 1e5 }, { Stat = "Critical", Value = 1e5 } }, Sockets = {}, Jewel = "" }
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
			old.Items.x = { Id = "x", Def = "sword", Tier = 1, Rarity = "Rare", Lines = {}, Sockets = {}, Jewel = "" } :: any
			old.Items.kept = { Id = "kept", Def = "sword", Tier = 1, Rarity = "Rare", Design = 3, Lines = {}, Sockets = {}, Jewel = "" }
			Migrations.Run(old)
			t.Equal("an old item takes its launch design", old.Items.x.Design, Items.LaunchDesign("x"))
			t.Equal("an item with a design keeps it", old.Items.kept.Design, 3)
			t.Equal("at the latest", old.Version, Migrations.Latest)
			-- a design is never a stat: the same item in every design, the same Combat Power
			local held = fresh()
			local owned = lead(held, "Warrior")
			local id = Profile.NewId(held)
			held.Items[id] = { Id = id, Def = "sword", Tier = 3, Rarity = "Epic", Design = 1, Lines = { { Stat = "Attack", Value = 400 }, { Stat = "Might", Value = 30 } }, Sockets = {}, Jewel = "" }
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
}
