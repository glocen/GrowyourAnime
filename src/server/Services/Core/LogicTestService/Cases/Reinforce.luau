--!strict
-- Gear's own levels, part A of TR47 (pure): Reinforce (Rules.Reinforce), the War Emblems (Rules.Emblems), the equip
-- transfer (Rules.Regalia.Transfer), what they add in the resolver (Rules.Stats), the level gap (Rules.Hit.Gap) and the
-- save's step 11. The numbers are TR47's seeds, written here as TR47 gives them, so a Config that drifts from the request
-- fails. Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Saveable = require(Shared.Data.Saveable)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Regalia = require(Shared.Rules.Regalia)
local Reinforce = require(Shared.Rules.Reinforce)
local Emblems = require(Shared.Rules.Emblems)
local Collection = require(Shared.Rules.Collection)
local Grounds = require(Shared.Definitions.Grounds)
local Sets = require(Shared.Definitions.Emblems)
local Voidkin = require(Shared.Definitions.Voidkin)
local ChestsConfig = require(Shared.Config.Chests)
local DropsConfig = require(Shared.Config.Drops)
local Drops = require(Shared.Rules.Drops)
local Tower = require(Shared.Rules.Tower)
local TowerConfig = require(Shared.Config.Tower)
local StatsConfig = require(Shared.Config.Stats)
local ReinforceConfig = require(Shared.Config.Reinforce)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- An owned item, its sockets by its rarity, its main line first.
local function item(data: Profile.Data, def: string, rarity: string, tier: number, main: number?): Profile.OwnedItem
	local id = Profile.NewId(data)
	local sockets = {}
	for _ = 1, ChestsConfig.Sockets[rarity] do
		table.insert(sockets, "")
	end
	local made: Profile.OwnedItem = {
		Id = id,
		Def = def,
		Tier = tier,
		Rarity = rarity,
		Design = 1,
		Lines = { { Stat = "Attack", Value = main or 300 }, { Stat = "Health", Value = 90 } },
		Sockets = sockets,
		Reinforce = 0,
		Jewels = {},
	}
	data.Items[id] = made
	return made
end

local function filled(sockets: { string }): string
	return table.concat(sockets, ",")
end

local TRIES = { 1, 1, 1, 1, 1, 0.8, 0.7, 0.6, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25 } -- TR47: then 20% from +15 to +30

return {
	{
		Name = "Reinforce: the chances, 100% to +5 then 80, 70, 60, 50 and down to 20% at +15 to +30; none past the cap",
		Run = function(t: any)
			t.Equal("the cap is +30", ReinforceConfig.Cap, 30)
			for level = 1, 30 do
				local want = TRIES[level] or 0.2
				t.Equal(`+{level}`, Reinforce.Chance(level), want)
			end
			t.Equal("+31: none", Reinforce.Chance(31), 0)
			t.Equal("+0: none", Reinforce.Chance(0), 0)
		end,
	},
	{
		Name = "Reinforce: a try's price, round(30 x G(the ground's last level) x (1 + L/15)) Credits and Low, Mid or High stones 1,1,1,2,2,2,3,3,3,4",
		Run = function(t: any)
			local counts = { 1, 1, 1, 2, 2, 2, 3, 3, 3, 4 }
			for tier, ground in Grounds.List do
				for _, level in { 1, 6, 10, 11, 15, 20, 21, 30 } do
					local cost = Reinforce.Cost({ Tier = tier }, level)
					local want = math.floor(30 * Growth.G(ground.LevelTo) * (1 + level / 15) + 0.5)
					t.Equal(`{ground.Id} +{level}: Credits`, cost.Credits, want)
					t.Equal(`{ground.Id} +{level}: the grade`, cost.Grade, if level <= 10 then "Low" elseif level <= 20 then "Mid" else "High")
					t.Equal(`{ground.Id} +{level}: the count`, cost.Stones, counts[(level - 1) % 10 + 1])
				end
			end
			t.Equal("a tier past the grounds prices at the last", Reinforce.Cost({ Tier = 99 }, 5).Credits, Reinforce.Cost({ Tier = #Grounds.List }, 5).Credits)
		end,
	},
	{
		Name = "Reinforce: a try spends then rolls; a failure spends and keeps the level; each refusal changes nothing; a retry never spends twice",
		Run = function(t: any)
			local data = fresh()
			local sword = item(data, "sword", "Rare", 1)
			sword.Reinforce = 5
			local cost = Reinforce.Cost(sword, 6)
			data.Currency.Credits = cost.Credits * 3
			data.Bag.Stones.Low = cost.Stones * 3
			local answer, changed = Transaction.Run(data, "op-fail", function(draft: Profile.Data): any
				return Reinforce.Try(draft, { Item = sword.Id }, 0.8) -- 80% at +6: 0.8 misses
			end, 8)
			t.Check("a failure commits", answer.Ok == true and changed and answer.Success == false)
			t.Equal("its level stays", data.Items[sword.Id].Reinforce, 5)
			t.Equal("it spent the Credits", data.Currency.Credits, cost.Credits * 2)
			t.Equal("and the stones", data.Bag.Stones.Low, cost.Stones * 2)
			local again, twice = Transaction.Run(data, "op-fail", function(draft: Profile.Data): any
				return Reinforce.Try(draft, { Item = sword.Id }, 0)
			end, 8)
			t.Check("the same op id: its first answer, nothing spent", again.Success == false and not twice and data.Currency.Credits == cost.Credits * 2)
			local won = Transaction.Run(data, "op-win", function(draft: Profile.Data): any
				return Reinforce.Try(draft, { Item = sword.Id }, 0.79)
			end, 8)
			t.Check("0.79 under 80%: +6", won.Success == true and won.Level == 6 and won.Tried == 6 and won.Chance == 0.8)
			t.Equal("the level", data.Items[sword.Id].Reinforce, 6)
			local poor = fresh()
			local axe = item(poor, "great_axe", "Common", 1)
			poor.Bag.Stones.Low = 5
			local before = Profile.DeepCopy(poor)
			t.Equal("no Credits: Poor", Reinforce.Try(poor, { Item = axe.Id }, 0).Error, Reinforce.Poor)
			poor.Currency.Credits = 10 ^ 6
			poor.Bag.Stones.Low = nil
			t.Equal("no stones: NoStones", Reinforce.Try(poor, { Item = axe.Id }, 0).Error, Reinforce.NoStones)
			t.Equal("an unknown item", Reinforce.Try(poor, { Item = "nowhere" }, 0).Error, Reinforce.Unknown)
			t.Equal("no request", Reinforce.Try(poor, nil, 0).Error, Reinforce.Unknown)
			axe.Reinforce = 30
			t.Equal("at +30: Capped", Reinforce.Try(poor, { Item = axe.Id }, 0).Error, Reinforce.Capped)
			t.Check("a refusal through the transaction changes nothing", (function(): boolean
				local _, moved = Transaction.Run(before, nil, function(draft: Profile.Data): any
					return Reinforce.Try(draft, { Item = axe.Id }, 0)
				end, 8)
				return not moved
			end)())
			local spent = fresh()
			local last = item(spent, "sword", "Rare", 1)
			local one = Reinforce.Cost(last, 1)
			spent.Currency.Credits, spent.Bag.Stones.Low = one.Credits, one.Stones
			Reinforce.Try(spent, { Item = last.Id }, 0)
			t.Check("the last stones spent leave no key", spent.Bag.Stones.Low == nil and spent.Currency.Credits == 0)
		end,
	},
	{
		Name = "Reinforce: +L adds L/30 of the main line's own value to its stat, +30 doubles it, its own source in the resolver",
		Run = function(t: any)
			local data = fresh()
			local def = Voidkin.List[1].Id
			local owned = data.Voidkin[Collection.Uncover(data, def, NOW).Id]
			local ring = item(data, "ring", "Rare", 1, 300)
			data.Presets[1].Slots["Ring I"] = ring.Id
			local stat, gain = Reinforce.Gain(ring, 30)
			t.Check("+30 doubles the main line", stat == "Attack" and math.abs(gain - 300) < 1e-9)
			t.Check("+0 adds nothing", Reinforce.Gain(ring) == nil)
			local plain = Stats.Resolve(owned, data.Presets[1], data)
			ring.Reinforce = 12
			local block, lines = Stats.Resolve(owned, data.Presets[1], data)
			local reinforced = 0
			for _, line in lines do
				if line.Source == "Reinforce:Ring I" then
					reinforced += line.Value
				end
			end
			t.Check("+12: 12/30 of 300 on Attack, as Reinforce:Ring I", math.abs(reinforced - 120) < 1e-9, tostring(reinforced))
			t.Check("the block's Attack rises by it", math.abs(block.Attack - plain.Attack - 120) < 1e-6)
		end,
	},
	{
		Name = "Emblems: twelve sets, three a rarity; points are the Legendary row times the rarity's worth; Critical Damage, Critical Immunity and Lifesteal from Epic only",
		Run = function(t: any)
			t.Equal("twelve sets", #Sets.List, 12)
			for _, rarity in { "Uncommon", "Rare", "Epic", "Legendary" } do
				t.Equal(`three {rarity}`, #Sets.ByRarity[rarity], 3)
			end
			local legendary: { [string]: number } = { Attack = 32, Health = 149, Defence = 73, Critical = 814, Hit = 530, Dodge = 294 }
			local worth: { [string]: number } = { Uncommon = 0.25, Rare = 0.45, Epic = 0.7, Legendary = 1.0 }
			for rarity, share in worth do
				local set = Sets.ByRarity[rarity][1].Id
				for stat, row in legendary do
					local got, points = Emblems.Points(Emblems.Key(set, stat))
					t.Check(`{rarity} {stat}: {math.floor(row * share + 0.5)}`, got == stat and points == math.floor(row * share + 0.5), tostring(points))
				end
			end
			local high: { [string]: { [string]: number } } = { Epic = { CriticalDamage = 0.04, CriticalGuard = 0.04, Lifesteal = 0.01 }, Legendary = { CriticalDamage = 0.06, CriticalGuard = 0.06, Lifesteal = 0.015 } }
			for rarity, rows in high do
				for stat, value in rows do
					t.Equal(`{rarity} {stat}`, select(2, Emblems.Points(Emblems.Key(Sets.ByRarity[rarity][2].Id, stat))), value)
				end
			end
			t.Check("Rare Lifesteal is no emblem", Emblems.Parse("warhorn:Lifesteal") == nil)
			t.Check("Uncommon Critical Damage is no emblem", Emblems.Parse("talon:CriticalDamage") == nil)
			t.Check("an unknown set or stat, or no key", Emblems.Parse("nowhere:Attack") == nil and Emblems.Parse("talon:Speed") == nil and Emblems.Parse(nil) == nil and Emblems.Parse("talon") == nil)
			t.Check("Epic Critical Immunity is one", Emblems.Parse("moonward:CriticalGuard") ~= nil)
		end,
	},
	{
		Name = "Emblems: in and out free, a filled socket's emblem back to the bag, identical ones stack, refusals change nothing, a retry never takes two; flat points in the resolver",
		Run = function(t: any)
			local data = fresh()
			local helm = item(data, "helmet", "Rare", 1)
			t.Equal("a Rare item: three sockets", #helm.Sockets, 3)
			data.Bag.Emblems["talon:Attack"] = 2
			data.Bag.Emblems["zenith:Critical"] = 1
			local answer, changed = Transaction.Run(data, "put-1", function(draft: Profile.Data): any
				return Emblems.Socket(draft, { Item = helm.Id, Socket = 2, Emblem = "talon:Attack" })
			end, 8)
			t.Check("in: Ok", answer.Ok == true and changed)
			t.Equal("in the second socket", filled(data.Items[helm.Id].Sockets), ",talon:Attack,")
			t.Equal("one left in the bag", data.Bag.Emblems["talon:Attack"], 1)
			local _, twice = Transaction.Run(data, "put-1", function(draft: Profile.Data): any
				return Emblems.Socket(draft, { Item = helm.Id, Socket = 3, Emblem = "talon:Attack" })
			end, 8)
			t.Check("the same op id takes none again", not twice and data.Bag.Emblems["talon:Attack"] == 1)
			helm = data.Items[helm.Id] -- a committed transaction puts in new tables
			Emblems.Socket(data, { Item = helm.Id, Socket = 3, Emblem = "talon:Attack" })
			t.Check("the last one in leaves no key; two identical in one item", data.Bag.Emblems["talon:Attack"] == nil and filled(helm.Sockets) == ",talon:Attack,talon:Attack")
			local swap = Emblems.Socket(data, { Item = helm.Id, Socket = 2, Emblem = "zenith:Critical" })
			t.Check("over a filled socket: the old one back to the bag", swap.Back == "talon:Attack" and data.Bag.Emblems["talon:Attack"] == 1 and data.Bag.Emblems["zenith:Critical"] == nil)
			local out = Emblems.Unsocket(data, { Item = helm.Id, Socket = 3 })
			t.Check("out: back to the bag, the socket empty", out.Ok == true and data.Bag.Emblems["talon:Attack"] == 2 and helm.Sockets[3] == "")
			local before = Profile.DeepCopy(data)
			t.Equal("an empty socket out: Empty", Emblems.Unsocket(data, { Item = helm.Id, Socket = 3 }).Error, Emblems.Empty)
			t.Equal("none in the bag: NoneLeft", Emblems.Socket(data, { Item = helm.Id, Socket = 1, Emblem = "radiance:Hit" }).Error, Emblems.NoneLeft)
			t.Equal("a fourth socket on a Rare: Unknown", Emblems.Socket(data, { Item = helm.Id, Socket = 4, Emblem = "talon:Attack" }).Error, Emblems.Unknown)
			t.Equal("socket 1.5: Unknown", Emblems.Socket(data, { Item = helm.Id, Socket = 1.5, Emblem = "talon:Attack" }).Error, Emblems.Unknown)
			t.Equal("a key that's no emblem: Unknown", Emblems.Socket(data, { Item = helm.Id, Socket = 1, Emblem = "talon:Lifesteal" }).Error, Emblems.Unknown)
			t.Check("the refusals changed nothing", filled(data.Items[helm.Id].Sockets) == filled(before.Items[helm.Id].Sockets) and data.Bag.Emblems["talon:Attack"] == 2)
			local owned = data.Voidkin[Collection.Uncover(data, Voidkin.List[1].Id, NOW).Id]
			data.Presets[1].Slots.Helmet = helm.Id
			local _, lines = Stats.Resolve(owned, data.Presets[1], data)
			local critical = 0
			for _, line in lines do
				if line.Source == "Emblem:Helmet" and line.Stat == "Critical" then
					critical += line.Value
				end
			end
			t.Equal("Zenith's Critical, 814 flat, as Emblem:Helmet", critical, 814)
			t.Check("the save with emblems is saveable", #Saveable.Problems(data, "profile") == 0)
		end,
	},
	{
		Name = "Transfer: Yes moves the level, the emblems and the jewels; the new item keeps its own; what it can't hold stays on the old; nothing is ever lost; No moves nothing",
		Run = function(t: any)
			local data = fresh()
			local old = item(data, "helmet", "Epic", 1)
			old.Reinforce = 14
			old.Sockets = { "talon:Attack", "", "zenith:Hit", "moonward:Lifesteal" }
			old.Jewels = { Red = 3 }
			local new = item(data, "helmet", "Uncommon", 2)
			data.Presets[1].Slots.Helmet = old.Id
			t.Check("the old item holds something; the new one nothing", Regalia.Holds(old) and not Regalia.Holds(new))
			local answer = Regalia.Equip(data, 1, "Helmet", nil, new.Id, true)
			t.Check("Yes: equipped and moved", answer.Ok == true and answer.Moved == true and answer.Was == old.Id and answer.Emblems == 2 and answer.Stayed == 1)
			t.Equal("the level moved", new.Reinforce, 14)
			t.Equal("the old item: +0", old.Reinforce, 0)
			t.Equal("the jewels moved", new.Jewels.Red, 3)
			t.Equal("the new item's two sockets, the first two in order", filled(new.Sockets), "talon:Attack,zenith:Hit")
			t.Equal("the third stays on the old", filled(old.Sockets), "moonward:Lifesteal,,,")
			local count = 0
			for _, list in { old.Sockets, new.Sockets } do
				for _, key in list do
					count += if key ~= "" then 1 else 0
				end
			end
			t.Equal("three emblems before, three after", count, 3)
			local back = Regalia.Equip(data, 1, "Helmet", nil, old.Id, true)
			t.Check("Yes again, back the other way: everything returns", back.Moved == true and old.Reinforce == 14 and new.Reinforce == 0 and old.Jewels.Red == 3)
			t.Equal("the emblems home again, after the one it kept", filled(old.Sockets), "moonward:Lifesteal,talon:Attack,zenith:Hit,")
			t.Equal("the other left bare", filled(new.Sockets), ",")
			local swap = fresh()
			local a = item(swap, "ring", "Rare", 1)
			local b = item(swap, "ring", "Rare", 1)
			a.Reinforce, b.Reinforce = 9, 4
			a.Sockets, b.Sockets = { "talon:Attack", "talon:Attack", "" }, { "warhorn:Hit", "", "" }
			swap.Presets[1].Slots["Ring I"] = a.Id
			Regalia.Equip(swap, 1, "Ring I", nil, b.Id, true)
			t.Check("both held some: the levels change places, the new one keeps its emblem and takes the rest", a.Reinforce == 4 and b.Reinforce == 9 and filled(b.Sockets) == "warhorn:Hit,talon:Attack,talon:Attack" and filled(a.Sockets) == ",,")
			local full = fresh()
			local c = item(full, "ring", "Common", 1)
			local d = item(full, "ring", "Common", 1)
			c.Sockets, d.Sockets = { "talon:Attack" }, { "warhorn:Hit" }
			c.Jewels, d.Jewels = { Red = 2, Blue = 1 }, { Red = 4 }
			full.Presets[1].Slots["Ring I"] = c.Id
			local crowded = Regalia.Equip(full, 1, "Ring I", nil, d.Id, true)
			t.Check("no room: the emblem stays on the old item", crowded.Emblems == 0 and crowded.Stayed == 1 and c.Sockets[1] == "talon:Attack" and d.Sockets[1] == "warhorn:Hit")
			t.Check("a jewel whose colour is taken stays; the other moves", c.Jewels.Red == 2 and c.Jewels.Blue == nil and d.Jewels.Red == 4 and d.Jewels.Blue == 1)
			local no = fresh()
			local kept = item(no, "gloves", "Rare", 1)
			kept.Reinforce = 7
			local plain = item(no, "gloves", "Rare", 1)
			no.Presets[1].Slots.Gloves = kept.Id
			local said = Regalia.Equip(no, 1, "Gloves", nil, plain.Id)
			t.Check("No: nothing moves", said.Moved == false and kept.Reinforce == 7 and plain.Reinforce == 0)
			local same = Regalia.Equip(no, 1, "Gloves", nil, plain.Id, true)
			t.Check("the same item again with Yes: nothing moves", same.Moved == false and plain.Reinforce == 0)
			local hands = fresh()
			local sword = item(hands, "sword", "Rare", 1)
			sword.Reinforce = 3
			local blade = item(hands, "sword", "Rare", 1)
			Regalia.Equip(hands, 1, "Main Hand", "Warrior", sword.Id)
			Regalia.Equip(hands, 1, "Main Hand", "Warrior", blade.Id, true)
			t.Check("a weapon's hand moves it too", blade.Reinforce == 3 and sword.Reinforce == 0)
		end,
	},
	{
		Name = "Gap: a lower attacker's hit by levels below, the combat review's table: 3 x0.85 ... 16 x0.10, 20+ x0.05; a higher one nothing",
		Run = function(t: any)
			local table1: { [number]: number } = { [0] = 1, [1] = 1, [2] = 1, [3] = 0.85, [4] = 0.72, [5] = 0.61, [6] = 0.52, [8] = 0.38, [10] = 0.27, [12] = 0.20, [16] = 0.10, [20] = 0.05, [30] = 0.05 }
			for gap, want in table1 do
				local got = Hit.Gap(20, 20 + gap)
				t.Check(`{gap} under: x{want}`, math.abs(math.floor(got * 100 + 0.5) / 100 - want) < 1e-9, tostring(got))
			end
			t.Equal("ten above: nothing", Hit.Gap(30, 20), 1)
			local attacker, defender = Stats.EvenFoe(10), Stats.EvenFoe(15)
			attacker.Attack = 1000 -- an even foe's block carries no Attack
			local rolls = { Dodge = 1, Critical = 1, Block = 1 }
			local even = Hit.Resolve(attacker, Stats.EvenFoe(10), 1, rolls)
			local under = Hit.Resolve(attacker, defender, 1, rolls)
			t.Check("five under: the hit carries x0.61 as its Gap", math.abs(under.Gap - 0.85 ^ 3) < 1e-12 and even.Gap == 1)
			local rule = StatsConfig.Gap
			local free = rule.Free
			rule.Free = math.huge -- the same hit with no gap, then the rule put back
			local without = Hit.Resolve(attacker, defender, 1, rolls)
			rule.Free = free
			t.Check("its total is the gap times the same hit without it", under.Total > 0 and math.abs(under.Total - without.Total * under.Gap) < 1e-9 and without.Gap == 1, `{under.Total} vs {without.Total}`)
		end,
	},
	{
		Name = "Loot: stones of the ground's grade from every fall, an emblem from an elite or a keeper at its chest row's rarity, written in the drop's one step",
		Run = function(t: any)
			local grades = {}
			for _, ground in Grounds.List do
				table.insert(grades, Drops.StoneGrade(ground.Id))
			end
			t.Equal("grades by ground, two a grade", table.concat(grades, ","), "Low,Low,Mid,Mid,High,High")
			local chance = DropsConfig.StoneChance
			t.Check("an ordinary Shade: one stone under its chance, none over", Drops.Stones("Ordinary", chance - 1e-6) == 1 and Drops.Stones("Ordinary", chance + 1e-6) == 0)
			local elite = chance * DropsConfig.Share.Elite
			t.Equal("an elite's mean, its whole part sure", Drops.Stones("Elite", 0.999), math.floor(elite))
			t.Equal("an unknown kind: none", Drops.Stones("Nowhere", 0), 0)
			t.Equal("an ordinary Shade drops no emblem", Drops.Emblem("Ordinary", "lanternrow", { Stone = 0, Emblem = 0, Rarity = 0, Set = 0, Stat = 0 }), nil)
			local weights = Drops.EmblemWeights("Elite", "lanternrow")
			local row = ChestsConfig.Ladder[1 + DropsConfig.EmblemTier.Elite - 1]
			t.Check("an elite in the first ground: its ladder row, Common as Uncommon", weights.Uncommon == row[1] + row[2] and weights.Rare == row[3])
			local key = Drops.Emblem("Keeper", "lanternrow", { Stone = 0, Emblem = 0.5, Rarity = 0, Set = 0, Stat = 0 })
			t.Check("a keeper's sure emblem: Uncommon, the first set, the first stat", key == "talon:Attack", tostring(key))
			t.Equal("over the elite's chance: none", Drops.Emblem("Elite", "lanternrow", { Stone = 0, Emblem = DropsConfig.EmblemChance.Elite, Rarity = 0, Set = 0, Stat = 0 }), nil)
			local last = Grounds.List[#Grounds.List].Id
			local top = Drops.Emblem("Keeper", last, { Stone = 0, Emblem = 0, Rarity = 0.99999, Set = 0.99, Stat = 0.99 })
			local parsed = Emblems.Parse(top)
			t.Check("the last ground's keeper, its rarest roll: an emblem that exists, at a rarity its row holds", parsed ~= nil and (Drops.EmblemWeights("Keeper", last) :: any)[parsed.Set.Rarity] > 0, tostring(top))
			local data = fresh()
			local loot = { Stone = 0, Emblem = 0, Rarity = 0, Set = 0, Stat = 0 }
			local answer = Drops.Give(data, "Keeper", 9, "lanternrow", 0.99, 0.99, loot)
			t.Check("a keeper's fall writes its stones and emblem", answer.Ok == true and answer.Stone == "Low" and answer.Stones >= 1 and data.Bag.Stones.Low == answer.Stones and answer.Emblem == "talon:Attack" and data.Bag.Emblems["talon:Attack"] == 1)
			local plain = Drops.Give(data, "Ordinary", 1, "lanternrow", 0.99, 0.99)
			t.Check("without the loot's rolls: none", plain.Stone == "" and plain.Stones == 0 and plain.Emblem == "")
			local climb = fresh()
			Tower.Start(climb, "run", 7, NOW)
			local hard = Tower.Won(climb, "run", 1, false)
			local fast = Tower.Won(climb, "run", 2, true)
			t.Check("a hard Tower floor: its stones; a fast one none", hard ~= nil and hard.Stones == TowerConfig.Stones and hard.Stone == "Low" and fast ~= nil and fast.Stones == 0)
			local results = Tower.End(climb, "run", NOW + 60)
			t.Check("granted at the run's end, and told in its results", climb.Bag.Stones.Low == TowerConfig.Stones and results ~= nil and (results.Stones :: any).Low == TowerConfig.Stones)
		end,
	},
	{
		Name = "Save step 11: each item gains +0 and no jewels and loses Jewel; SlotRanks goes; the bag gains stones, emblems and jewels",
		Run = function(t: any)
			local old: any = Profile.Template()
			Migrations.Run(old)
			old.Version = 10
			old.SlotRanks = { Ring = 2 }
			old.Bag = { Shards = {}, Chests = {} }
			old.Items.x = { Id = "x", Def = "sword", Tier = 1, Rarity = "Rare", Design = 1, Lines = {}, Sockets = { "", "", "" }, Jewel = "" }
			Migrations.Run(old)
			t.Check("the item: +0, no jewels, no Jewel", old.Items.x.Reinforce == 0 and next(old.Items.x.Jewels) == nil and old.Items.x.Jewel == nil)
			t.Check("SlotRanks gone", old.SlotRanks == nil)
			t.Check("the bag's three", type(old.Bag.Stones) == "table" and type(old.Bag.Emblems) == "table" and type(old.Bag.Jewels) == "table")
			t.Check("saveable after", #Saveable.Problems(old, "profile") == 0)
			t.Check("a new save has them too", type(fresh().Bag.Stones) == "table" and (fresh() :: any).SlotRanks == nil)
		end,
	},
}
