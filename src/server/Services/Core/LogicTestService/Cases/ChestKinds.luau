--!strict
-- Chest kinds cases (pure): the Emblem Case, the Jewel Pouch and the Forge Crate (the director's "ok" of 2026-11-24 to
-- docs/research/cloud-2026-11-24/launch-design.md, section 5; Definitions.Chests, Rules.Chests, Config.Chests). The rows
-- and their names, what each opens into by its odds over many seeded opens, no bag room needed, a repeat taking nothing
-- twice, where they come from (an elite's fall, a keeper's win, a Hard keeper's win, the Tower's tenth floors) and the
-- toast's words. The seeds' numbers are written here as Config gives them, so a Config that drifts fails. Runs in
-- Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Saveable = require(Shared.Data.Saveable)
local Chests = require(Shared.Rules.Chests)
local Bag = require(Shared.Rules.Bag)
local Emblems = require(Shared.Rules.Emblems)
local Jewels = require(Shared.Rules.Jewels)
local Progress = require(Shared.Rules.Progress)
local Tower = require(Shared.Rules.Tower)
local Growth = require(Shared.Rules.Growth)
local ChestRows = require(Shared.Definitions.Chests)
local Grounds = require(Shared.Definitions.Grounds)
local ChestsConfig = require(Shared.Config.Chests)
local DropsConfig = require(Shared.Config.Drops)
local JewelsConfig = require(Shared.Config.Jewels)
local TowerConfig = require(Shared.Config.Tower)
local ReinforceConfig = require(Shared.Config.Reinforce)
local UIKit = require(Shared.Config.UIKit)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- A seeded sequence in [0, 1) (Lehmer): the offline runner has no Random.
local function sequence(seed: number): Chests.Draw
	local state = seed
	return function(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
end

local function sum(map: { [string]: number }): number
	local total = 0
	for _, n in map do
		total += n
	end
	return total
end

-- Whether `seen` of `n` is within `sigmas` of a chance `p`'s mean.
local function near(seen: number, n: number, p: number, sigmas: number): boolean
	return math.abs(seen - n * p) <= sigmas * math.sqrt(n * p * (1 - p)) + 1
end

-- Opens `total` of chest `id` in steps of Config's Step, every draw from `draw`, and answers what came out by key.
local function openAll(data: Profile.Data, id: string, total: number, draw: Chests.Draw): { [string]: number }
	Chests.Grant(data, id, total)
	local gave: { [string]: number } = {}
	local left = total
	while left > 0 do
		local step = math.min(left, ChestsConfig.Step)
		local answer = Chests.Open(data, id, step, draw)
		assert(answer.Ok == true, tostring(answer.Error))
		for key, n in answer.Gave do
			gave[key] = (gave[key] or 0) + n
		end
		left -= step
	end
	return gave
end

return {
	{
		Name = "Chest kinds: an elite's and a keeper's Emblem Case for every ground on Normal and Hard, a Jewel Pouch and a Forge Crate; named for ground and kind, no rarity's word, a picture in the kit; the gear list stays gear",
		Run = function(t: any)
			for _, ground in Grounds.List do
				for _, kind in { "Elite", "Keeper" } do
					for _, difficulty in { "Normal", "Hard" } do
						local row = ChestRows.CaseOf(ground.Id, kind, difficulty)
						t.Check(`{ground.Id} {kind} {difficulty}: a case`, row ~= nil)
						if row == nil then
							continue
						end
						t.Check(`{row.Id}: an Emblem Case of its source's tier`, row.Kind == "Emblem" and row.Word == "Emblem Case" and row.Tier == DropsConfig.EmblemTier[kind] and row.Difficulty == difficulty)
						t.Check(`{row.Id}: named for its ground and its kind`, string.find(row.Name, ground.Name, 1, true) ~= nil and string.find(row.Name, "Emblem Case", 1, true) ~= nil, row.Name)
						for _, word in ChestsConfig.Rarities do
							t.Check(`{row.Id}: no {word} in its name`, string.find(row.Name, word, 1, true) == nil, row.Name)
						end
						t.Check(`{row.Id}: its picture is in the kit`, UIKit.Images[row.Image] ~= nil, row.Image)
						local odds = Chests.Odds(row)
						t.Check(`{row.Id}: odds sum to one, never a Common`, math.abs(sum(odds) - 1) < 1e-9 and odds.Common == 0, tostring(sum(odds)))
					end
				end
			end
			t.Check("a Hard case is not its Normal one", ChestRows.CaseOf("lanternrow", "Elite", "Hard") ~= ChestRows.CaseOf("lanternrow", "Elite"))
			local pouch, crate = ChestRows.ById[ChestRows.Pouch], ChestRows.ById[ChestRows.Crate]
			t.Check("one Jewel Pouch", pouch ~= nil and pouch.Kind == "Jewel" and pouch.Name == "Jewel Pouch" and UIKit.Images[pouch.Image] ~= nil)
			t.Check("one Forge Crate", crate ~= nil and crate.Kind == "Stone" and crate.Name == "Forge Crate" and UIKit.Images[crate.Image] ~= nil)
			local all = 0
			for _ in ChestRows.ById do
				all += 1
			end
			local gear = true
			for _, row in ChestRows.List do
				gear = gear and row.Kind == "Gear" and row.Word ~= ""
			end
			local others = true
			for _, row in ChestRows.Others do
				others = others and row.Kind ~= "Gear"
			end
			t.Check("the gear list holds gear, the others none", gear and others)
			t.Equal("every row by id", all, #ChestRows.List + #ChestRows.Others)
			t.Equal("the others: four cases a ground, the pouch and the crate", #ChestRows.Others, #Grounds.List * 4 + 2)
			t.Check("a gear chest's word is its tier's", ChestRows.ById.lanternrow_1.Word == "Shade Chest" and ChestRows.ById.lanternrow_3.Word == "Keeper's Chest")
		end,
	},
	{
		Name = "Chest kinds: an Emblem Case opens into one War Emblem a case at its odds, 20,000 opens; no room needed in a full bag; the card's lines; a repeat opens nothing twice; refusals change nothing",
		Run = function(t: any)
			local data = fresh()
			local last = Grounds.List[#Grounds.List].Id
			local case = ChestRows.CaseOf(last, "Keeper", "Hard") :: ChestRows.Row
			local odds = Chests.Odds(case)
			local n = 20000
			local gave = openAll(data, case.Id, n, sequence(4242))
			local byRarity: { [string]: number } = {}
			local valid = true
			for key, count in gave do
				local parsed = Emblems.Parse(key)
				valid = valid and parsed ~= nil
				if parsed then
					byRarity[parsed.Set.Rarity] = (byRarity[parsed.Set.Rarity] or 0) + count
				end
			end
			t.Check("every key an emblem that exists", valid)
			t.Equal("one emblem a case, all in the bag", sum(data.Bag.Emblems), n)
			t.Check("the cases gone", data.Bag.Chests[case.Id] == nil)
			for _, rarity in { "Uncommon", "Rare", "Epic", "Legendary" } do
				t.Check(`{rarity}: at its odds`, near(byRarity[rarity] or 0, n, odds[rarity] or 0, 4.5), `{byRarity[rarity] or 0} of {n} against {odds[rarity]}`)
			end
			-- a full bag: gear chests refused, a case opens
			local full = fresh()
			for i = 1, ChestsConfig.Bag do
				local id = Profile.NewId(full)
				full.Items[id] = { Id = id, Def = "ring", Tier = 1, Rarity = "Common", Design = 1, Lines = { { Stat = "Attack", Value = 1 } }, Sockets = { "" }, Reinforce = 0, Jewels = {} }
			end
			Chests.Grant(full, "lanternrow_1", 1)
			Chests.Grant(full, case.Id, 2)
			t.Equal("a gear chest in a full bag: refused", Chests.Open(full, "lanternrow_1", 1, sequence(1)).Error, Chests.BagFull)
			local card = Bag.Chest(full, case.Id) :: { [string]: any }
			t.Check("its card: no room needed, both open at once", card.Fills == false and card.Step == 2 and card.Word == "Emblem Case")
			local lines = 0
			for _, line in card.Odds do
				lines += 1
				t.Check(`{line.Name}: a rarity's line`, line.Rarity == line.Name and line.Chance > 0)
			end
			t.Check("a line for each rarity it gives", lines >= 2)
			local first, changed = Transaction.Run(full, "op-case", function(draft: Profile.Data): any
				return Chests.Open(draft, case.Id, 2, sequence(9))
			end, 8)
			t.Check("in a full bag: opened, its emblems in", first.Ok == true and changed and first.Kind == "Emblem" and sum(first.Gave) == 2 and sum(full.Bag.Emblems) == 2)
			Chests.Grant(full, case.Id, 1)
			local again, twice = Transaction.Run(full, "op-case", function(draft: Profile.Data): any
				return Chests.Open(draft, case.Id, 2, sequence(9))
			end, 8)
			t.Check("the same op id: its first answer, nothing opened twice", again.Ok == true and not twice and full.Bag.Chests[case.Id] == 1 and sum(full.Bag.Emblems) == 2)
			local before = Profile.DeepCopy(full)
			t.Equal("more than held", Chests.Open(full, case.Id, 2, sequence(3)).Error, Chests.NotEnough)
			t.Equal("past the step", Chests.Open(full, case.Id, ChestsConfig.Step + 1, sequence(3)).Error, Chests.Unknown)
			t.Equal("no such chest", Chests.Open(full, "lanternrow_case_nowhere", 1, sequence(3)).Error, Chests.Unknown)
			t.Check("and nothing changed", sum(full.Bag.Emblems) == sum(before.Bag.Emblems) and full.Bag.Chests[case.Id] == before.Bag.Chests[case.Id])
			t.Check("the save is saveable", #Saveable.Problems(data, "profile") == 0 and #Saveable.Problems(full, "profile") == 0)
		end,
	},
	{
		Name = "Chest kinds: a Jewel Pouch gives one jewel, level 2 at 15%, each colour alike; a Forge Crate 3 to 5 Low stones evenly, a Mid at 20%, a High at 3%; 20,000 opens each, the cards' lines",
		Run = function(t: any)
			t.Check("the seeds as Config gives them", ChestsConfig.Pouch.Up == 0.15 and ChestsConfig.Crate.Low[1] == 3 and ChestsConfig.Crate.Low[2] == 5 and ChestsConfig.Crate.Mid == 0.2 and ChestsConfig.Crate.High == 0.03)
			local n = 20000
			local data = fresh()
			local jewels = openAll(data, ChestRows.Pouch, n, sequence(777))
			local level2, byColour = 0, {} :: { [string]: number }
			local valid = true
			for key, count in jewels do
				local parsed = Jewels.Parse(key)
				valid = valid and parsed ~= nil and parsed.Level <= 2
				if parsed then
					level2 += if parsed.Level == 2 then count else 0
					byColour[parsed.Colour] = (byColour[parsed.Colour] or 0) + count
				end
			end
			t.Check("every key a jewel of level 1 or 2", valid)
			t.Equal("one jewel a pouch, all in the bag", sum(data.Bag.Jewels), n)
			t.Check("level 2 at 15%", near(level2, n, 0.15, 4.5), `{level2} of {n}`)
			for _, colour in JewelsConfig.Colours do
				t.Check(`{colour}: a fifth`, near(byColour[colour] or 0, n, 1 / #JewelsConfig.Colours, 4.5), `{byColour[colour] or 0}`)
			end
			Chests.Grant(data, ChestRows.Pouch, 1)
			local pouchCard = Bag.Chest(data, ChestRows.Pouch) :: { [string]: any }
			t.Check("the pouch's card: two lines, summing to one", #pouchCard.Odds == 2 and math.abs(pouchCard.Odds[1].Chance + pouchCard.Odds[2].Chance - 1) < 1e-12 and pouchCard.Fills == false)
			local stones = fresh()
			local counts: { [number]: number } = {}
			Chests.Grant(stones, ChestRows.Crate, n)
			local draw = sequence(31337)
			local mid, high = 0, 0
			for _ = 1, n do
				local answer = Chests.Open(stones, ChestRows.Crate, 1, draw)
				local low = answer.Gave.Low or 0
				counts[low] = (counts[low] or 0) + 1
				mid += answer.Gave.Mid or 0
				high += answer.Gave.High or 0
			end
			t.Check("Low: 3, 4 or 5, each a third", (counts[3] or 0) + (counts[4] or 0) + (counts[5] or 0) == n and near(counts[3] or 0, n, 1 / 3, 4.5) and near(counts[5] or 0, n, 1 / 3, 4.5), `{counts[3]} {counts[4]} {counts[5]}`)
			t.Check("a Mid at 20%", near(mid, n, 0.2, 4.5), `{mid}`)
			t.Check("a High at 3%", near(high, n, 0.03, 4.5), `{high}`)
			t.Equal("all in the bag", (stones.Bag.Stones.Low or 0) + (stones.Bag.Stones.Mid or 0) + (stones.Bag.Stones.High or 0), (counts[3] or 0) * 3 + (counts[4] or 0) * 4 + (counts[5] or 0) * 5 + mid + high)
			Chests.Grant(stones, ChestRows.Crate, 1)
			local crateCard = Bag.Chest(stones, ChestRows.Crate) :: { [string]: any }
			t.Check("the crate's card: Low sure, Mid and High at their chances", #crateCard.Odds == 3 and crateCard.Odds[1].Name == "3 to 5 Low stones" and crateCard.Odds[1].Chance == 1 and crateCard.Odds[2].Chance == 0.2 and crateCard.Odds[3].Chance == 0.03)
			t.Check("the saves are saveable", #Saveable.Problems(data, "profile") == 0 and #Saveable.Problems(stones, "profile") == 0)
		end,
	},
	{
		Name = "Chest kinds: a keeper's win on Hard adds a Jewel Pouch and a Forge Crate every win, on Normal none; the Tower's tenth floors won hard past the record give their ground's keeper's case, once, a fast one none",
		Run = function(t: any)
			local ground = Grounds.List[1].Id
			local data = fresh()
			local normal = Progress.KeeperWon(data, ground, NOW, "Normal")
			t.Check("Normal: no pouch, no crate", normal.Ok == true and next(normal.Extra) == nil and data.Bag.Chests[ChestRows.Pouch] == nil and data.Bag.Chests[ChestRows.Crate] == nil)
			local hard = Progress.KeeperWon(data, ground, NOW + 10_000, "Hard")
			t.Check("Hard: one of each", hard.Ok == true and hard.Extra[ChestRows.Pouch] == 1 and hard.Extra[ChestRows.Crate] == 1 and data.Bag.Chests[ChestRows.Pouch] == 1 and data.Bag.Chests[ChestRows.Crate] == 1)
			t.Check("while it rests: refused, nothing twice", Progress.KeeperWon(data, ground, NOW + 10_000, "Hard").Ok == false and data.Bag.Chests[ChestRows.Pouch] == 1)
			local again = Progress.KeeperWon(data, ground, NOW + 20_000, "Hard")
			t.Check("the next Hard win: one more each", again.Ok == true and data.Bag.Chests[ChestRows.Pouch] == 2 and data.Bag.Chests[ChestRows.Crate] == 2)
			local every = TowerConfig.Case.Every
			t.Equal("every tenth floor", every, 10)
			local function caseOf(floor: number): string
				local at = Grounds.List[Growth.GroundOf(Tower.Level(floor))]
				local row = ChestRows.CaseOf(at.Id, "Keeper")
				return if row then row.Id else "none"
			end
			t.Equal("floor 10, a first climb: its ground's keeper's case", Tower.Reward(10, 0, 7, false).Case, caseOf(10))
			t.Equal("floor 10 again, the record at 10: none", Tower.Reward(10, 10, 7, false).Case, nil)
			t.Equal("floor 10 fast: none", Tower.Reward(10, 0, 7, true).Case, nil)
			t.Equal("floor 9: none", Tower.Reward(9, 0, 7, false).Case, nil)
			t.Equal("floor 20 past a record of 15", Tower.Reward(20, 15, 7, false).Case, caseOf(20))
			local climb = fresh()
			Tower.Start(climb, "run", 7, NOW)
			for floor = 1, 20 do
				Tower.Won(climb, "run", floor, false)
			end
			Tower.End(climb, "run", NOW + 600)
			local cases = 0
			for id, count in climb.Bag.Chests do
				local row = ChestRows.ById[id]
				cases += if row and row.Kind == "Emblem" then count else 0
			end
			t.Equal("a climb to 20: two cases, granted at its end", cases, 2)
			Tower.Start(climb, "run2", 8, NOW + 700)
			for floor = 1, 20 do
				Tower.Won(climb, "run2", floor, false)
			end
			Tower.End(climb, "run2", NOW + 1300)
			local after = 0
			for id, count in climb.Bag.Chests do
				local row = ChestRows.ById[id]
				after += if row and row.Kind == "Emblem" then count else 0
			end
			t.Equal("the same climb again: none more", after, 2)
		end,
	},
	{
		Name = "Chest kinds: the toast says what came out, gear kept and salvaged, each emblem and jewel by name, the stones by grade",
		Run = function(t: any)
			t.Equal("gear", Bag.Opened({ Ok = true, Kind = "Gear", Opened = 3, Items = { "a", "b" }, Salvaged = 1, Credits = 1200 }), "Opened 3: 2 kept, 1 salvaged for 1,200 Credits")
			t.Equal("gear, none salvaged", Bag.Opened({ Ok = true, Kind = "Gear", Opened = 1, Items = { "a" }, Salvaged = 0, Credits = 0 }), "Opened 1: 1 kept")
			t.Equal("emblems", Bag.Opened({ Ok = true, Kind = "Emblem", Opened = 3, Gave = { ["talon:Attack"] = 2, ["warhorn:Hit"] = 1 } }), "Opened 3: 2 Talon (Attack), Warhorn (Hit)")
			t.Equal("a jewel", Bag.Opened({ Ok = true, Kind = "Jewel", Opened = 1, Gave = { ["Red:2"] = 1 } }), "Opened 1: Red jewel, level 2")
			t.Equal("stones", Bag.Opened({ Ok = true, Kind = "Stone", Opened = 1, Gave = { Low = 4, Mid = 1 } }), "Opened 1: 4 Low stones, 1 Mid stone")
			t.Equal("the crate's grades are the forge's", table.concat(ReinforceConfig.Grades, ","), "Low,Mid,High")
		end,
	},
}
