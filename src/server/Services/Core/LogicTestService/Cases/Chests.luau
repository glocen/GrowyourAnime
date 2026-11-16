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
			t.Equal("three tiers", ChestRows.Tiers, 3)
			for _, ground in Grounds.List do
				for tier = 1, ChestRows.Tiers do
					local row = ChestRows.Of(ground.Id, tier)
					t.Check(`{ground.Id} tier {tier}: a row`, row ~= nil and row.Ground == ground.Id and row.Tier == tier)
					if row then
						t.Check(`{row.Id}: named for its ground`, string.find(row.Name, ground.Name, 1, true) ~= nil, row.Name)
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
				data.Items[`fill{n}`] = { Id = `fill{n}`, Def = "ring", Tier = 1, Rarity = "Common", Lines = {}, Sockets = {}, Jewel = "" }
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
				data.Items[id] = { Id = id, Def = Items.ById[string.lower((string.gsub(Gear.Family(slot), " ", "_")))].Id, Tier = 6, Rarity = "Legendary", Lines = { { Stat = "Attack", Value = 1e6 }, { Stat = "Health", Value = 1e6 }, { Stat = "Might", Value = 1e5 }, { Stat = "Finesse", Value = 1e5 }, { Stat = "Vigor", Value = 1e5 }, { Stat = "Spirit", Value = 1e5 }, { Stat = "Insight", Value = 1e5 }, { Stat = "Defence", Value = 1e6 } }, Sockets = {}, Jewel = "" }
				Regalia.Put(data.Presets[1], slot, nil, id)
			end
			for _, hand in Gear.Hands do
				local id = Profile.NewId(data)
				local def = if hand == "Main Hand" then "sword" else "short_sword"
				data.Items[id] = { Id = id, Def = def, Tier = 6, Rarity = "Legendary", Lines = { { Stat = "Attack", Value = 1e6 }, { Stat = "Might", Value = 1e5 }, { Stat = "Hit", Value = 1e5 }, { Stat = "Critical", Value = 1e5 } }, Sockets = {}, Jewel = "" }
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
}
