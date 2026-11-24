--!strict
-- Progress cases (pure): a keeper's fall counts a win on its ground and opens the next one for good, once; the last ground
-- opens nothing; an unknown ground changes nothing. Its save stays saveable.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local Grounds = require(Shared.Definitions.Grounds)
local Progress = require(Shared.Rules.Progress)
local Transaction = require(Shared.Data.Transaction)

local NOW = 1_800_000_000

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

return {
	{
		Name = "Progress: a keeper's fall opens the next ground, once",
		Run = function(t: any)
			local data = fresh()
			local first, second = Grounds.List[1], Grounds.List[2]
			t.Check("the first ground is open from the start", Progress.IsOpen(data, first.Id))
			t.Check("the second isn't", not Progress.IsOpen(data, second.Id))
			local won = Progress.KeeperWon(data, first.Id, NOW)
			t.Check("the win is counted", won.Ok == true and won.Ground == first.Id and won.Wins == 1)
			t.Equal("it opens the next ground", won.Opened, second.Id)
			t.Check("which stays open", Progress.IsOpen(data, second.Id) and data.Progress.Grounds[second.Id].Opened == NOW)
			t.Equal("with no wins of its own", data.Progress.Grounds[second.Id].KeeperWins.Normal, 0)
			local again = Progress.KeeperWon(data, first.Id, NOW + 400) -- after its rest: no try begins before (TR10)
			t.Check("a second win counts", again.Ok == true and again.Wins == 2)
			t.Equal("and opens nothing new", again.Opened, "")
			t.Equal("the next ground keeps its first opening", data.Progress.Grounds[second.Id].Opened, NOW)
			local problems = Saveable.Problems(data)
			t.Check("the save stays saveable", #problems == 0, problems[1])
		end,
	},
	{
		Name = "Progress: the last ground opens nothing; an unknown one changes nothing",
		Run = function(t: any)
			local data = fresh()
			local last = Grounds.List[#Grounds.List]
			local won = Progress.KeeperWon(data, last.Id, NOW)
			t.Check("the last keeper's win counts", won.Ok == true and won.Wins == 1)
			t.Equal("and opens nothing", won.Opened, "")
			local before = 0
			for _ in data.Progress.Grounds do
				before += 1
			end
			for _, bad in { "nowhere", 5, nil :: any, "" } do
				local answer = Progress.KeeperWon(data, bad, NOW)
				t.Check(`{tostring(bad)} is refused`, answer.Ok == false and answer.Error == Progress.Unknown)
			end
			local after = 0
			for _ in data.Progress.Grounds do
				after += 1
			end
			t.Equal("nothing changed", after, before)
		end,
	},
	{
		Name = "Progress (section 9): a keeper's win repeated while the keeper rests from it grants nothing twice, with no op id; the refusal changes nothing; after the rest a win counts again",
		Run = function(t: any)
			local first = Grounds.List[1]
			local data = fresh()
			local roll: any = { Stone = 0, Emblem = 0, Rarity = 0, Set = 0, Stat = 0, Pouch = 0, Crate = 0 } -- every roll lands
			local won = Progress.KeeperWon(data, first.Id, NOW, "Normal", roll)
			t.Check("the win: a chest and an Emblem Case", won.Ok == true and won.Chest ~= "" and won.Case ~= "", `{won.Chest} {won.Case}`)
			local function held(): string
				local chests, emblems = 0, 0
				for _, n in data.Bag.Chests do
					chests += n
				end
				for _, n in data.Bag.Emblems do
					emblems += n
				end
				local record = data.Progress.Grounds[first.Id]
				return `{chests} chests, {emblems} emblems, {record.KeeperWins.Normal}+{record.KeeperWins.Hard} wins, back at {record.Back}`
			end
			local once = held()
			local again = Progress.KeeperWon(data, first.Id, NOW, "Normal", roll)
			t.Check("the same win again: refused, the keeper resting", again.Ok == false and again.Error == Progress.Rest, tostring(again.Error))
			t.Equal("nothing twice", held(), once)
			t.Check("on Hard during the rest: refused too", Progress.KeeperWon(data, first.Id, NOW + 299, "Hard", roll).Ok == false)
			t.Equal("still nothing twice", held(), once)
			local _, changed = Transaction.Run(data, nil, function(draft: Profile.Data): any
				return Progress.KeeperWon(draft, first.Id, NOW + 1, "Normal", roll)
			end, 8)
			t.Check("a server change with no op id, repeated: not applied", not changed)
			t.Equal("and still nothing twice", held(), once)
			local back = Progress.KeeperWon(data, first.Id, NOW + 300, "Normal", roll)
			t.Check("its rest over: a new win counts", back.Ok == true and back.Wins == 2)
			t.Equal("an unknown ground still answers unknown", Progress.KeeperWon(data, "nowhere", NOW).Error, Progress.Unknown)
			t.Equal("the save stays saveable", #Saveable.Problems(data), 0)
		end,
	},
}
