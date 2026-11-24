--!strict
-- Goals cases (pure): today's three drawn once a UTC day and banked three days, a goal paid once, a repeated claim answered
-- by the op ledger, Next in its order, and a stretch's dare (docs/test-requests.md, TR54). Runs in Studio (LogicTests) and
-- with Studio closed (tools/checks/logic_offline.luau).

local Shared = game:GetService("ReplicatedStorage").Shared
local Goals = require(Shared.Rules.Goals)
local Defs = require(Shared.Definitions.Goals)
local GoalFacts = require(Shared.Rules.GoalFacts)
local GoalsConfig = require(Shared.Config.Goals)
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Transaction = require(Shared.Data.Transaction)
local Breaker = require(Shared.Rules.Breaker)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Drops = require(Shared.Rules.Drops)
local DataConfig = require(Shared.Config.Data)
local CondenserConfig = require(Shared.Config.Condenser)
local ChestsConfig = require(Shared.Config.Chests)

local T0 = 1_800_000_000

-- A whole save, as a new account's after its migrations.
local function save(): any
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

local ALL_OPEN = { Hard = true, Tower = true, Condenser = true, Forge = true }
local SEED = 573369515

local function fresh(): any
	return { Days = {}, Led = { Day = 0, Ids = {} } }
end

local function drawer(open: { [string]: boolean }, seed: number): (number) -> { string }
	return function(day: number): { string }
		return Goals.Draw(Defs.Rows, Defs.Lists, seed, day, open)
	end
end

return {
	{
		Name = "Goals: the day is UTC's, whatever the server's clock zone",
		Run = function(t: any)
			-- 2026-11-23 00:00:00 UTC is 1795392000
			local midnight = 1795392000
			t.Equal("the day at UTC midnight", Goals.DayOf(midnight), 20780)
			t.Equal("one second before it, the day before", Goals.DayOf(midnight - 1), 20779)
			t.Equal("23:59:59 the same day", Goals.DayOf(midnight + 86399), 20780)
		end,
	},
	{
		Name = "Goals: a day's three, one a list in order, the same for the same player and day",
		Run = function(t: any)
			local picks = Goals.Draw(Defs.Rows, Defs.Lists, SEED, 20780, ALL_OPEN)
			t.Equal("three", #picks, 3)
			for i, list in Defs.Lists do
				t.Equal(`pick {i} from {list}`, Defs.ById[picks[i]].List, list)
			end
			local again = Goals.Draw(Defs.Rows, Defs.Lists, SEED, 20780, ALL_OPEN)
			t.Equal("drawn again, the same", table.concat(again, ","), table.concat(picks, ","))
			-- across a month of days, each list draws more than one goal
			local seen = { Fight = {}, Base = {}, Roster = {} } :: any
			for day = 20780, 20809 do
				for i, id in Goals.Draw(Defs.Rows, Defs.Lists, SEED, day, ALL_OPEN) do
					seen[Defs.Lists[i]][id] = true
				end
			end
			for _, list in Defs.Lists do
				local n = 0
				for _ in seen[list] do
					n += 1
				end
				t.Check(`{list} varies over 30 days`, n >= 2, `{n} goals`)
			end
		end,
	},
	{
		Name = "Goals: a goal waits for what it needs before it's drawn",
		Run = function(t: any)
			for day = 20780, 20899 do
				for _, id in Goals.Draw(Defs.Rows, Defs.Lists, SEED, day, {}) do
					local row = Defs.ById[id]
					t.Check(`day {day}: {id} needs nothing`, row.Opens == nil, row.Opens)
				end
			end
			-- every list keeps a goal a new account can do
			t.Equal("a new account's three", #Goals.Draw(Defs.Rows, Defs.Lists, SEED, 20780, {}), 3)
		end,
	},
	{
		Name = "Goals: the bank holds three days, nine goals at most; a day past it leaves",
		Run = function(t: any)
			local state = fresh()
			local draw = drawer(ALL_OPEN, SEED)
			t.Check("the first day drawn", Goals.Roll(state, 20780, 3, draw))
			t.Equal("one day", #state.Days, 1)
			t.Check("a second roll the same day changes nothing", not Goals.Roll(state, 20780, 3, draw))
			-- away four days: the two days before today are drawn, the rest never
			Goals.Roll(state, 20784, 3, draw)
			t.Equal("three days", #state.Days, 3)
			t.Equal("the oldest is two days ago", state.Days[1].Day, 20782)
			t.Equal("today's is last", state.Days[3].Day, 20784)
			local n = 0
			for _, d in state.Days do
				n += #d.Picks
			end
			t.Equal("nine goals", n, 9)
			-- the next day, two days ago leaves, claimed or not
			Goals.Roll(state, 20785, 3, draw)
			t.Equal("still three", #state.Days, 3)
			t.Equal("its oldest moved on", state.Days[1].Day, 20783)
			-- a server clock behind the save draws nothing and keeps everything
			t.Check("a day behind changes nothing", not Goals.Roll(state, 20784, 3, draw))
			t.Equal("all three kept", #state.Days, 3)
			-- away a month: the bank's three days, never more
			Goals.Roll(state, 20815, 3, draw)
			t.Equal("back after a month: three days", #state.Days, 3)
			t.Equal("the oldest two days ago", state.Days[1].Day, 20813)
		end,
	},
	{
		Name = "Goals: an event moves every open goal on it, finishes it at its Need, and never past it",
		Run = function(t: any)
			local state = fresh()
			state.Days = {
				{ Day = 20779, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 0, 0, 0 }, Claimed = { false, false, false } },
				{ Day = 20780, Picks = { "TowerThree", "ThreeShards", "NewLead" }, Have = { 0, 0, 0 }, Claimed = { false, false, false } },
			}
			local done = Goals.Credit(state, Defs.ById, "ShardBroken", 2)
			t.Equal("two shards: none done", #done, 0)
			t.Equal("yesterday's moved on", state.Days[1].Have[2], 2)
			t.Equal("today's moved on", state.Days[2].Have[2], 2)
			done = Goals.Credit(state, Defs.ById, "ShardBroken", 5)
			t.Equal("the third: both done", #done, 2)
			t.Equal("held at its Need", state.Days[2].Have[2], 3)
			t.Equal("a done goal moves no more", #Goals.Credit(state, Defs.ById, "ShardBroken", 1), 0)
			t.Equal("another event moves nothing of it", state.Days[1].Have[1], 0)
			t.Equal("two wait to be claimed", Goals.Waits(state, Defs.ById), 2)
		end,
	},
	{
		Name = "Goals: a goal is claimed once, only when done",
		Run = function(t: any)
			local state = fresh()
			state.Days = { { Day = 20780, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 1, 2, 0 }, Claimed = { false, false, false } } }
			local ok, why = Goals.Claim(state, Defs.ById, 20780, 2)
			t.Check("not done: refused", not ok, why)
			t.Equal("its reason", why, "NotDone")
			ok = Goals.Claim(state, Defs.ById, 20780, 1)
			t.Check("done: claimed", ok)
			ok, why = Goals.Claim(state, Defs.ById, 20780, 1)
			t.Check("a second claim: refused", not ok)
			t.Equal("its reason", why, "Claimed")
			t.Equal("a day not held", select(2, Goals.Claim(state, Defs.ById, 20779, 1)), "NoDay")
			t.Equal("a slot not held", select(2, Goals.Claim(state, Defs.ById, 20780, 4)), "NoGoal")
			t.Equal("nothing waits", Goals.Waits(state, Defs.ById), 0)
		end,
	},
	{
		Name = "Goals: a claim pays its shard once, and a repeated or interrupted one nothing more (the op ledger)",
		Run = function(t: any)
			-- The "GoalClaim" action's own path: Transaction.Run with the client's op id, the rule inside
			local data = save()
			data.Goals.Days = { { Day = 20780, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 1, 0, 0 }, Claimed = { false, false, false } } }
			local reward = GoalsConfig.Reward
			local function claim(op: string, args: any): any
				return (Transaction.Run(data, op, function(draft: any): any
					return Goals.Take(draft, args, reward)
				end, DataConfig.OpsKept))
			end
			local function held(): number
				return data.Bag.Shards[reward.Shard] or 0
			end
			t.Check("the first claim pays", claim("op-a", { Day = 20780, Slot = 1 }).Ok == true)
			t.Equal("one shard of Lantern Row's", held(), reward.Count)
			t.Check("its repeat (the same op id) gets the first answer", claim("op-a", { Day = 20780, Slot = 1 }).Ok == true)
			t.Equal("and pays nothing more", held(), reward.Count)
			t.Equal("a new op on the same goal is refused as claimed", claim("op-b", { Day = 20780, Slot = 1 }).Error, "Claimed")
			t.Equal("an unfinished goal is refused", claim("op-c", { Day = 20780, Slot = 2 }).Error, "NotDone")
			t.Equal("a day not banked is refused", claim("op-d", { Day = 1, Slot = 1 }).Error, "NoDay")
			t.Equal("a request that isn't one is refused", claim("op-e", "nonsense").Error, "NoGoal")
			t.Equal("still one shard", held(), reward.Count)
			t.Check("its claim is saved", data.Goals.Days[1].Claimed[1] == true)
		end,
	},
	{
		Name = "Goals: a kept dare pays its stone into the bag and counts for today's dare goal",
		Run = function(t: any)
			local data = save()
			data.Goals.Days = { { Day = 20780, Picks = { "KeepDare", "ThreeShards", "LevelUp" }, Have = { 0, 0, 0 }, Claimed = { false, false, false } } }
			Goals.PayDare(data, GoalsConfig.Dare.Grade.lanternrow, GoalsConfig.Dare.Count)
			t.Equal("one Low stone", data.Bag.Stones.Low, 1)
			t.Equal("the dare goal is done", data.Goals.Days[1].Have[1], 1)
			t.Equal("Lantern Row's dares pay its grade", GoalsConfig.Dare.Grade.lanternrow, Drops.StoneGrade("lanternrow"))
		end,
	},
	{
		Name = "Goals: the base's events reach today's goals in the Breaker's own step, online and away",
		Run = function(t: any)
			local data = save()
			local today = Goals.DayOf(T0)
			data.Goals.Days = { { Day = today, Picks = { "BaysHour", "ThreeShards" }, Have = { 0, 0 }, Claimed = { false, false } } }
			for i, bay in data.Base.Bays do
				local id = `v{i}`
				data.Voidkin[id] = { Id = id, Def = "rook", Level = 1, Xp = 0 } :: any
				bay.Worker = id
			end
			Breaker.Advance(data, T0)
			Goals.Note(data, "ShardBroken", 0)
			t.Equal("nothing counted yet", data.Goals.Days[1].Have[2], 0)
			Goals.Note(data, "ShardBroken", 3)
			t.Equal("three shards noted finish it", data.Goals.Days[1].Have[2], 3)
			Goals.Note(data, "ShardBroken", 2)
			t.Equal("never past its need", data.Goals.Days[1].Have[2], 3)
			Breaker.Advance(data, T0 + 1800)
			t.Check("half an hour of every bay", math.abs(data.Goals.Days[1].Have[1] - 1800) < 1, `{data.Goals.Days[1].Have[1]}`)
			Breaker.Advance(data, T0 + 7200, true)
			t.Equal("a full hour, away too", data.Goals.Days[1].Have[1], 3600)
			-- one bay of two filled: the hour doesn't count
			local half = save()
			half.Goals.Days = { { Day = today, Picks = { "BaysHour" }, Have = { 0 }, Claimed = { false } } }
			half.Base.Bays[2] = half.Base.Bays[2] or { Worker = "", Level = 1 }
			half.Voidkin.v1 = { Id = "v1", Def = "rook", Level = 1, Xp = 0 } :: any
			half.Base.Bays[1].Worker = "v1"
			half.Base.Bays[2].Worker = ""
			Breaker.Advance(half, T0)
			Breaker.Advance(half, T0 + 600)
			t.Equal("a bay empty: nothing", half.Goals.Days[1].Have[1], 0)
			t.Check("a save without goals is left alone", (pcall(Goals.Note, { Base = {} }, "ShardBroken", 1)))
		end,
	},
	{
		Name = "Goals: what each goal waits for, and Next's facts, read from the save",
		Run = function(t: any)
			local data = save()
			local facts = GoalFacts.Of(data)
			t.Check("a new account: no Hard, Tower, Condenser or forge", not facts.Hard and not facts.Tower and not facts.Condenser and not facts.Forge)
			t.Equal("its Next is the Lamplighter", Goals.Next(Defs.Next, facts), 1)
			data.Progress.Grounds.lanternrow = { KeeperWins = { Normal = 1, Hard = 0 } } :: any
			data.Base.Level = 2
			facts = GoalFacts.Of(data)
			t.Check("level 2 wakes the Condenser", facts.Condenser == true)
			t.Equal("then Next is the Lamplighter on Hard", Goals.Next(Defs.Next, facts), 3)
			data.Progress.Tower.Best = 4
			t.Check("a floor won opens the Tower's goal", GoalFacts.Of(data).Tower == true)
		end,
	},
	{
		Name = "Goals: each Next line says what the config opens",
		Run = function(t: any)
			local next = Defs.Next
			t.Check("level 2 opens a third bay", BaseLevels.Bays(2) == 3 and BaseLevels.OpensAt(3) == 2 and string.find(next[2].Opens, "third bay") ~= nil)
			t.Equal("and the Condenser wakes at it", CondenserConfig.Wakes, next[2].AtLeast)
			t.Check("level 3 opens a fourth bay", BaseLevels.Bays(3) == 4 and string.find(next[4].Opens, "fourth bay") ~= nil)
			t.Check("and machines reach its ceiling at it", string.find(next[4].Opens, `level {BaseLevels.Ceiling(3)}.`, 1, true) ~= nil, next[4].Opens)
			t.Equal("the first Hard keeper's chest is a Rare or better", ChestsConfig.Keeper.FirstFloor.Hard, "Rare")
			t.Check("which its line says", string.find(next[3].Opens, "Rare or better") ~= nil)
		end,
	},
	{
		Name = "Goals: someone new leads a run once a day each",
		Run = function(t: any)
			local state = fresh()
			t.Check("Rook's first run today counts", Goals.Led(state, 20780, "v1"))
			t.Check("Rook again doesn't", not Goals.Led(state, 20780, "v1"))
			t.Check("Kirra does", Goals.Led(state, 20780, "v2"))
			t.Check("the next day, Rook counts again", Goals.Led(state, 20781, "v1"))
			t.Equal("the day's list starts again", #state.Led.Ids, 1)
		end,
	},
	{
		Name = "Goals: Next is the first step not done, in its order, and the last line past them",
		Run = function(t: any)
			local steps = Defs.Next
			t.Equal("a new account", Goals.Next(steps, { BaseLevel = 1, TowerBest = 0 }), 1)
			t.Equal("the Lamplighter down", Goals.Next(steps, { Keeper = true, BaseLevel = 1, TowerBest = 0 }), 2)
			t.Equal("base level 2", Goals.Next(steps, { Keeper = true, BaseLevel = 2, TowerBest = 0 }), 3)
			t.Equal("on Hard too", Goals.Next(steps, { Keeper = true, KeeperHard = true, BaseLevel = 2, TowerBest = 0 }), 4)
			t.Equal("level 3", Goals.Next(steps, { Keeper = true, KeeperHard = true, BaseLevel = 3, TowerBest = 24 }), 5)
			t.Equal("all done: the last line", Goals.Next(steps, { Keeper = true, KeeperHard = true, BaseLevel = 3, TowerBest = 25 }), 6)
			t.Equal("an early step undone comes first", Goals.Next(steps, { Keeper = true, BaseLevel = 1, KeeperHard = true, TowerBest = 30 }), 2)
			for i, step in steps do
				local letters = #(step.Opens or step.Text)
				t.Check(`line {i}'s second row is 45 letters or fewer`, letters <= 45, `{letters}`)
			end
		end,
	},
	{
		Name = "Goals: each stretch's dare once its piece is in, else the fallback",
		Run = function(t: any)
			local ready = { Guard = true, Dasher = true, Slam = true }
			for stage = 1, 4 do
				t.Equal(`stretch {stage}`, Goals.Dare(Defs.Dares, Defs.Fallback, stage, ready).Id, Defs.Dares[stage].Id)
			end
			t.Equal("stretch 3 without the Dasher", Goals.Dare(Defs.Dares, Defs.Fallback, 3, { Guard = true }).Id, "NoFall")
			t.Equal("stretch 1 needs nothing", Goals.Dare(Defs.Dares, Defs.Fallback, 1, {}).Id, "AboveHalf")
			t.Equal("a fifth stretch takes the fallback", Goals.Dare(Defs.Dares, Defs.Fallback, 5, ready).Id, "NoFall")
		end,
	},
	{
		Name = "Goals: a dare holds, breaks and is kept by its kind",
		Run = function(t: any)
			local above, shield, line = Defs.Dares[1], Defs.Dares[2], Defs.Dares[3]
			-- Above: its mark follows the lead's share, judged at the clear
			local s = { Broken = false, Done = false }
			t.Check("at three quarters it holds", not Goals.DareStep(above, s, "Health", 0.75))
			t.Check("at half it breaks", Goals.DareStep(above, s, "Health", 0.5))
			t.Equal("its look", Goals.DareLook(above, s), "Broken")
			t.Check("healed over half it holds again", Goals.DareStep(above, s, "Health", 0.6))
			t.Check("kept at the clear", Goals.DareKept(above, s))
			-- Do: kept only once done; its mark waits unlit, never dark, and turns kept the moment it's done (must-fix 1)
			s = { Broken = false, Done = false }
			t.Check("not yet done: not kept", not Goals.DareKept(shield, s))
			t.Equal("not yet done: its mark waits", Goals.DareLook(shield, s), "Waits")
			t.Check("another event: nothing", not Goals.DareStep(shield, s, "LineHit"))
			t.Check("a shield broken changes its look", Goals.DareStep(shield, s, "SignatureBreak"))
			t.Check("one shield broken: kept", Goals.DareKept(shield, s))
			t.Equal("its look is kept at once", Goals.DareLook(shield, s), "Kept")
			t.Check("a second break changes nothing", not Goals.DareStep(shield, s, "SignatureBreak"))
			-- a keep dare never waits, and a Do dare never shows broken while its stretch runs
			t.Equal("a keep dare holds from the start", Goals.DareLook(line, { Broken = false, Done = false }), "Holds")
			t.Equal("a Do dare isn't broken by a stray flag", Goals.DareLook(shield, { Broken = true, Done = false }), "Waits")
			-- Avoid: one touch breaks it for good
			s = { Broken = false, Done = false }
			t.Check("untouched: kept", Goals.DareKept(line, s))
			t.Check("a line's hit breaks it", Goals.DareStep(line, s, "LineHit"))
			t.Check("and it's not kept", not Goals.DareKept(line, s))
			t.Check("a second hit changes nothing", not Goals.DareStep(line, s, "LineHit"))
		end,
	},
}
