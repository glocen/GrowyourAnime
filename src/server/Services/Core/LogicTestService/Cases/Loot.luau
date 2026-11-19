--!strict
-- The loot refit, part 1 (TR48, pure): the keeper's wins counted by difficulty (Rules.Progress, the save's step 12),
-- Hard's own chests (Definitions.Chests, Rules.Chests), the first Hard keeper's sure Rare, the materials' rates by
-- difficulty (Rules.Drops) and the Tower's refit (Config.Tower, Config.Chests.Tower). The numbers are TR48's, written
-- here as research gives them, so a Config that drifts from the request fails. Runs in Studio (LogicTests) and with
-- Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Saveable = require(Shared.Data.Saveable)
local Progress = require(Shared.Rules.Progress)
local Chests = require(Shared.Rules.Chests)
local Drops = require(Shared.Rules.Drops)
local Tower = require(Shared.Rules.Tower)
local Stages = require(Shared.Rules.Stages)
local ChestRows = require(Shared.Definitions.Chests)
local ChestsConfig = require(Shared.Config.Chests)
local DropsConfig = require(Shared.Config.Drops)
local TowerConfig = require(Shared.Config.Tower)

local NOW = 1_800_000_000
local GROUND = "lanternrow"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local function loot(emblem: number): Drops.Loot
	return { Stone = 0, Emblem = emblem, Rarity = 0, Set = 0, Stat = 0 }
end

-- A draw that walks a fixed list of numbers in [0, 1), round and round.
local function sequence(seed: number): () -> number
	local i = 0
	return function(): number
		i += 1
		return ((seed * 7919 + i * 104729) % 10007) / 10007
	end
end

return {
	{
		Name = "Loot: TR48, a keeper's wins count by difficulty, so the first Hard win gives a first win's chest",
		Run = function(t: any)
			local data = fresh()
			local normal = Progress.KeeperWon(data, GROUND, NOW, "Normal")
			t.Check("the first Normal win: Normal's 1, a first win's chest", normal.Ok == true and normal.Wins == 1 and normal.Difficulty == "Normal" and normal.Chest == `{GROUND}_3`)
			local hard = Progress.KeeperWon(data, GROUND, NOW + 400, "Hard")
			t.Check("the first Hard win: Hard's 1, its own first win's chest", hard.Wins == 1 and hard.Difficulty == "Hard" and hard.Chest == `{GROUND}_3_hard{ChestRows.KeeperStage[GROUND]}`, hard.Chest)
			local again = Progress.KeeperWon(data, GROUND, NOW + 800, "Hard")
			t.Check("the second Hard win: a repeat's chest", again.Wins == 2 and again.Chest == `{GROUND}_2_hard{ChestRows.KeeperStage[GROUND]}`, again.Chest)
			local record = data.Progress.Grounds[GROUND]
			t.Check("the record: Normal 1, Hard 2", record.KeeperWins.Normal == 1 and record.KeeperWins.Hard == 2)
			t.Equal("every difficulty's", Progress.Wins(record), 3)
			local plain = Progress.KeeperWon(data, GROUND, NOW + 1200)
			t.Check("no difficulty, or an unknown one: Normal", plain.Difficulty == "Normal" and Progress.KeeperWon(data, GROUND, NOW + 1600, "Nightmare").Difficulty == "Normal" and record.KeeperWins.Normal == 3)
			t.Check("a beaten keeper anywhere: the account isn't fresh", not Stages.Fresh(data))
		end,
	},
	{
		Name = "Loot: TR48, the save's step 12 makes each ground's one count its Normal wins",
		Run = function(t: any)
			local old: any = Profile.Template()
			Migrations.Run(old)
			old.Version = 11
			old.Progress.Grounds[GROUND] = { Opened = NOW, KeeperWins = 4 }
			old.Progress.Grounds.drumcourt = { Opened = NOW, KeeperWins = 0, Back = NOW }
			Migrations.Run(old)
			t.Check("4 wins: Normal 4, Hard 0", old.Progress.Grounds[GROUND].KeeperWins.Normal == 4 and old.Progress.Grounds[GROUND].KeeperWins.Hard == 0)
			t.Check("none: none on both, its rest kept", old.Progress.Grounds.drumcourt.KeeperWins.Normal == 0 and old.Progress.Grounds.drumcourt.Back == NOW)
			t.Check("saveable after", #Saveable.Problems(old, "profile") == 0)
			t.Equal("the latest version", old.Version, Migrations.Latest)
		end,
	},
	{
		Name = "Loot: TR48, a Hard stage's chests are its own, read Drum Court's ladder rows and roll at the stage's last stop's level on Hard",
		Run = function(t: any)
			-- TR48's levels: G(12), G(15), G(18) and G(19) for stages 1 to 4; Normal keeps G(9).
			local levels = { 12, 15, 18, 19 }
			for stage, level in levels do
				local shade = ChestRows.Of(GROUND, 1, "Hard", stage)
				t.Check(`stage {stage}: its Shade chest, Hard, at level {level}`, shade ~= nil and shade.Difficulty == "Hard" and shade.Stage == stage and shade.Level == level)
				t.Check(`stage {stage}: Drum Court's Shade row`, shade ~= nil and Chests.Weights(shade) == ChestsConfig.Ladder[2])
			end
			local normal = ChestRows.Of(GROUND, 1) :: ChestRows.Row
			t.Check("Normal's: its ground's row, at its ground's level", normal.Difficulty == "Normal" and normal.Level == nil and Chests.Weights(normal) == ChestsConfig.Ladder[1])
			t.Check("a keeper's first win's chest only where a keeper ends the stage", ChestRows.Of(GROUND, 3, "Hard", 1) == nil and ChestRows.Of(GROUND, 3, "Hard", ChestRows.KeeperStage[GROUND]) ~= nil)
			t.Equal("an ordinary Shade on Hard, stage 2: that stage's", Chests.Dropped("Ordinary", GROUND, 10, 0, "Hard", 2), `{GROUND}_1_hard2`)
			t.Equal("an elite on Hard, stage 3", Chests.Dropped("Elite", GROUND, 10, 0, "Hard", 3), `{GROUND}_2_hard3`)
			t.Equal("on Normal: the ground's own", Chests.Dropped("Elite", GROUND, 10, 0, "Normal", 3), `{GROUND}_2`)
			t.Equal("on Hard with no stage: the ground's own", Chests.Dropped("Elite", GROUND, 10, 0, "Hard", 0), `{GROUND}_2`)
			local data = fresh()
			local answer = Drops.Give(data, "Elite", 15, GROUND, 0.99, 0, loot(0.99), { Difficulty = "Hard", Stage = 2 })
			t.Check("a Hard elite's fall: its stage's chest in the bag", answer.Chest == `{GROUND}_2_hard2` and data.Bag.Chests[`{GROUND}_2_hard2`] == 1, answer.Chest)
			local hard = ChestRows.Of(GROUND, 1, "Hard", 1) :: ChestRows.Row
			local classes = Chests.Classes(data)
			local higher = 0
			for seed = 1, 40 do
				local a = Chests.Roll(hard, classes, sequence(seed), { 100, 0, 0, 0, 0 })
				local b = Chests.Roll(normal, classes, sequence(seed), { 100, 0, 0, 0, 0 })
				if a.Lines[1].Value > b.Lines[1].Value then
					higher += 1
				end
			end
			t.Equal("the same draws: a Hard stage's main line over Normal's, every time", higher, 40)
		end,
	},
	{
		Name = "Loot: TR48, the first Hard keeper's win is a sure Rare, Normal's first stays its row, and a retried win grants once",
		Run = function(t: any)
			t.Equal("the floor", ChestsConfig.Keeper.FirstFloor.Hard, "Rare")
			local first = ChestRows.ById[`{GROUND}_3_hard{ChestRows.KeeperStage[GROUND]}`]
			local weights = Chests.Weights(first)
			t.Check("no Common, no Uncommon; Rare at least", weights[1] == 0 and weights[2] == 0 and weights[3] + weights[4] + weights[5] > 0)
			local classes = Chests.Classes(fresh())
			local below = 0
			for seed = 1, 200 do
				local rolled = Chests.Roll(first, classes, sequence(seed))
				if rolled.Rarity == "Common" or rolled.Rarity == "Uncommon" then
					below += 1
				end
			end
			t.Equal("200 rolls, none under Rare", below, 0)
			local normalFirst = ChestRows.Of(GROUND, 3) :: ChestRows.Row
			t.Check("Normal's first win: its ladder row, untouched", Chests.Weights(normalFirst) == ChestsConfig.Ladder[3])
			local after = ChestRows.Of(GROUND, 2, "Hard", ChestRows.KeeperStage[GROUND]) :: ChestRows.Row
			t.Check("a Hard repeat's chest: no floor", Chests.Weights(after) == ChestsConfig.Ladder[3])
			local data = fresh()
			local answer, changed = Transaction.Run(data, "keeper-1", function(draft: Profile.Data): any
				return Progress.KeeperWon(draft, GROUND, NOW, "Hard")
			end, 8)
			local _, twice = Transaction.Run(data, "keeper-1", function(draft: Profile.Data): any
				return Progress.KeeperWon(draft, GROUND, NOW, "Hard")
			end, 8)
			t.Check("the win, then its retry: one chest, one win", answer.Ok == true and changed and not twice and data.Bag.Chests[first.Id] == 1 and data.Progress.Grounds[GROUND].KeeperWins.Hard == 1)
			local cut = fresh()
			local _, interrupted = Transaction.Run(cut, nil, function(draft: Profile.Data): any
				Progress.KeeperWon(draft, GROUND, NOW, "Hard")
				error("the server stopped mid-win")
			end, 8)
			t.Check("a win cut off mid-way: nothing written", not interrupted and cut.Bag.Chests[first.Id] == nil and cut.Progress.Grounds[GROUND] == nil)
			Transaction.Run(cut, nil, function(draft: Profile.Data): any
				return Progress.KeeperWon(draft, GROUND, NOW, "Hard")
			end, 8)
			t.Check("its retry: one chest", cut.Bag.Chests[first.Id] == 1)
		end,
	},
	{
		Name = "Loot: TR48, the materials at research's rates: stones by difficulty, an elite's emblem at 30%, a keeper's with its win at 75%, the first Normal win sure",
		Run = function(t: any)
			t.Check("stones: Normal 22%, Hard 28%", DropsConfig.StoneChance.Normal == 0.22 and DropsConfig.StoneChance.Hard == 0.28)
			t.Check("a Shade, roll 0.25: none on Normal, one on Hard", Drops.Stones("Ordinary", 0.25, "Normal") == 0 and Drops.Stones("Ordinary", 0.25, "Hard") == 1)
			t.Check("a Normal elite: 0.8 (none sure)", Drops.Stones("Elite", 0.79, "Normal") == 1 and Drops.Stones("Elite", 0.8, "Normal") == 0)
			t.Check("a Hard elite: 1 sure", Drops.Stones("Elite", 0.99, "Hard") == 1)
			t.Check("a Normal keeper: 2 (1 sure)", Drops.Stones("Keeper", 0.97, "Normal") == 2 and Drops.Stones("Keeper", 0.99, "Normal") == 1)
			t.Check("a Hard keeper: 2.5 (2 sure)", Drops.Stones("Keeper", 0.5, "Hard") == 3 and Drops.Stones("Keeper", 0.55, "Hard") == 2)
			t.Check("emblems: an elite 30%, a keeper 75%", DropsConfig.EmblemChance.Elite == 0.3 and DropsConfig.EmblemChance.Keeper == 0.75)
			local hardRow = ChestsConfig.Ladder[1 + DropsConfig.EmblemTier.Elite - 1 + ChestsConfig.Hard.Rows]
			t.Check("a Hard elite's emblem: Drum Court's row", Drops.EmblemWeights("Elite", GROUND, "Hard").Rare == hardRow[3])
			local data = fresh()
			local first = Progress.KeeperWon(data, GROUND, NOW, "Normal", loot(0.9))
			t.Check("the first Normal win, roll 0.9: its emblem, sure", first.Emblem ~= "" and data.Bag.Emblems[first.Emblem] == 1, first.Emblem)
			local second = Progress.KeeperWon(data, GROUND, NOW + 400, "Normal", loot(0.9))
			t.Equal("the second, roll 0.9: none over 75%", second.Emblem, "")
			local hard = Progress.KeeperWon(data, GROUND, NOW + 800, "Hard", loot(0.9))
			t.Equal("the first Hard win, roll 0.9: 75% only", hard.Emblem, "")
			local hardAgain = Progress.KeeperWon(data, GROUND, NOW + 1200, "Hard", loot(0.5))
			t.Check("roll 0.5: under 75%, one", hardAgain.Emblem ~= "")
			t.Equal("without the rolls: none", Progress.KeeperWon(data, GROUND, NOW + 1600, "Hard").Emblem, "")
			local hardStones = Drops.Give(fresh(), "Ordinary", 12, GROUND, 0.99, 0.99, { Stone = 0.25, Emblem = 0.99, Rarity = 0, Set = 0, Stat = 0 }, { Difficulty = "Hard", Stage = 1 })
			t.Check("a Hard Shade's fall, roll 0.25: one Low stone", hardStones.Stones == 1 and hardStones.Stone == "Low")
		end,
	},
	{
		Name = "Loot: TR48, the Tower refit: its lifts, its chest's chance and row",
		Run = function(t: any)
			local want: { [string]: number } = {
				Health = 1.41, Attack = 1.23, Defence = 1.33, Hit = 1.25, Dodge = 1.91, Critical = 1.34, CriticalResist = 1.14,
				Block = 1.59, Penetration = 1.22, ElementalResist = 1.19, CriticalDamage = 1.03,
			}
			for stat, lift in want do
				t.Equal(`{stat}'s lift`, TowerConfig.Lift[stat], lift)
			end
			t.Check("the chest: 0.02 + 0.0004 a floor", TowerConfig.Chest.Base == 0.02 and TowerConfig.Chest.PerFloor == 0.0004)
			t.Check("floor 10: 2.4%", math.abs(Tower.ChestChance(10) - 0.024) < 1e-9)
			local row = ChestsConfig.Tower
			t.Check("its row: 59.49, 36.32, 2.86, 0.93, 0.40", row[1] == 59.49 and row[2] == 36.32 and row[3] == 2.86 and row[4] == 0.93 and row[5] == 0.40)
		end,
	},
}
