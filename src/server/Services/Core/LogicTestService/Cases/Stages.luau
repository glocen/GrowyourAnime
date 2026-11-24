--!strict
-- Logic cases (pure): a ground's one run of stretches on Normal and Hard (TR43, TR50; Rules.Stages; Config.Stages). A
-- stretch needs the one before it on the same difficulty, Hard opens when the keeper falls on Normal, a stretch counts its
-- quota of Shades before its last stop, its clear is written once, best time kept, and the run moves on from it; a run
-- begins at its difficulty's checkpoint, which the keeper's fall clears. Runs in Studio (LogicTests) and with Studio
-- closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Migrations = require(Shared.Data.Migrations)
local Saveable = require(Shared.Data.Saveable)
local StagesConfig = require(Shared.Config.Stages)
local CombatConfig = require(Shared.Config.Combat)
local Stages = require(Shared.Rules.Stages)
local Collection = require(Shared.Rules.Collection)
local Progress = require(Shared.Rules.Progress)
local Stats = require(Shared.Rules.Stats)
local Grounds = require(Shared.Definitions.Grounds)
local Enemies = require(Shared.Definitions.Enemies)

local NOW = 1_800_000_000
local GROUND = "lanternrow"

local function fresh(): Profile.Data
	local data = Profile.Template()
	Migrations.Run(data)
	return data
end

-- Plays stage `stage` on `difficulty` to its end at `seconds`, every kill its own; the clear's answer.
local function play(data: Profile.Data, difficulty: string, stage: number, seconds: number): { [string]: any }
	local run = Stages.Start(data, GROUND, difficulty, stage, NOW)
	if run == nil then
		return { Ok = false, Error = "not started" }
	end
	local row = (Stages.Of(GROUND) :: any)[stage]
	local pack: string? = nil
	for _, stop in row.Stops do
		pack = if stop.Kind == "Pack" then stop.Def else pack
	end
	for _ = 1, row.Quota do
		Stages.Kill(run, pack :: string)
	end
	Stages.Kill(run, Stages.DefOn(Stages.Last(GROUND, stage) :: any, difficulty))
	return Stages.Clear(data, run, NOW + seconds)
end

-- Plays the run's stretch through: its quota of its packs' Shades, then its last stop.
local function through(run: Stages.Run)
	local row = (Stages.Of(GROUND) :: any)[run.Stage]
	local pack: string? = nil
	for _, stop in row.Stops do
		pack = if stop.Kind == "Pack" then stop.Def else pack
	end
	for _ = 1, row.Quota do
		Stages.Kill(run, pack :: string)
	end
	Stages.Kill(run, Stages.DefOn(Stages.Last(GROUND, run.Stage) :: any, run.Difficulty))
end

return {
	{
		Name = "Stages: every ground's stages are whole: packs of known Shades, a quota, and a last stop that ends it",
		Run = function(t: any)
			for ground, rows in StagesConfig.Grounds do
				t.Check(`{ground}: a ground`, Grounds.ById[ground] ~= nil)
				t.Check(`{ground}: at least one stage`, #rows >= 1)
				for index, row in rows do
					local last = row.Stops[#row.Stops]
					t.Check(`{ground} {index}: ends at an elite or the keeper`, last ~= nil and (last.Kind == "Elite" or last.Kind == "Keeper"))
					t.Check(`{ground} {index}: a quota, whole`, row.Quota >= 0 and row.Quota % 1 == 0)
					local packs = 0
					for _, stop in row.Stops do
						local enemy = Enemies.ById[stop.Def]
						t.Check(`{ground} {index}: {stop.Def} is a foe of its kind`, enemy ~= nil and (stop.Kind == "Pack" and enemy.Kind == "Ordinary" or enemy.Kind == stop.Kind))
						t.Check(`{ground} {index}: {stop.Def} at a level`, stop.Level >= 1)
						packs += if stop.Kind == "Pack" then 1 else 0
					end
					t.Check(`{ground} {index}: a quota has packs to fill it`, row.Quota == 0 or packs > 0)
				end
				t.Equal(`{ground}: the keeper's is the last`, rows[#rows].Stops[#rows[#rows].Stops].Def, Grounds.ById[ground].Keeper)
			end
			t.Equal("Lantern Row: four stages", #(Stages.Of(GROUND) :: any), 4)
			t.Equal("Hard: ten levels up", Stages.Level(9, "Hard"), 19)
			t.Equal("Normal: as it stands", Stages.Level(9, "Normal"), 9)
		end,
	},
	{
		Name = "Stages: a stage needs the one before it on its difficulty, Hard opens when the keeper's stage falls on Normal, and a stage's gate opens with its Normal clear",
		Run = function(t: any)
			local data = fresh()
			t.Check("a new account is fresh: the Door sends it straight in", Stages.Fresh(data))
			t.Equal("Stage 1 on Normal is open", Stages.Needs(data, GROUND, "Normal", 1), nil)
			local needs, waits = Stages.Needs(data, GROUND, "Normal", 2)
			t.Check("Stage 2 waits for Stage 1", needs == Stages.Before and waits == 1, `{needs} {waits}`)
			t.Equal("Hard waits for the keeper on Normal", Stages.Needs(data, GROUND, "Hard", 1), Stages.Keeper)
			t.Equal("no Stage 5", Stages.Needs(data, GROUND, "Normal", 5), Stages.Unknown)
			t.Equal("no Stage 1.5", Stages.Needs(data, GROUND, "Normal", 1.5), Stages.Unknown)
			t.Equal("no third difficulty", Stages.Needs(data, GROUND, "Nightmare", 1), Stages.Unknown)
			t.Equal("a ground not open yet", Stages.Needs(data, "drumcourt", "Normal", 1), if Stages.Of("drumcourt") then Stages.Ground else Stages.Unknown)
			local _, refused = Stages.Start(data, GROUND, "Normal", 3, NOW)
			t.Equal("a locked stage won't start", refused, Stages.Locked)
			t.Check("every gate shut to a new account", not Stages.Passes(data, GROUND, 1) and not Stages.Passes(data, GROUND, 3))
			local first = play(data, "Normal", 1, 170)
			t.Check("Stage 1 clears, first, opening Stage 2, the run moving on to it", first.Ok and first.First and first.Opened == "Stage" and first.Next == 2 and not first.Ends, `{first.Error}`)
			t.Check("Stage 1's gate lets it by, Stage 2's not yet", Stages.Passes(data, GROUND, 1) and not Stages.Passes(data, GROUND, 2))
			t.Check("no longer fresh", not Stages.Fresh(data))
			t.Equal("Stage 2 open now", Stages.Needs(data, GROUND, "Normal", 2), nil)
			play(data, "Normal", 2, 180)
			play(data, "Normal", 3, 190)
			t.Equal("Hard still shut before the keeper", Stages.Needs(data, GROUND, "Hard", 1), Stages.Keeper)
			local keeper = play(data, "Normal", 4, 120)
			t.Check("the keeper's stage on Normal opens Hard and ends the run, its card's next Hard", keeper.Ok and keeper.Opened == "Hard" and keeper.Ends and keeper.Next == nil and keeper.Then == "Hard", `{keeper.Opened}`)
			t.Equal("Hard Stage 1 open", Stages.Needs(data, GROUND, "Hard", 1), nil)
			t.Check("every gate open after the keeper's stage on Normal", Stages.Passes(data, GROUND, 1) and Stages.Passes(data, GROUND, 3))
			local hardNeeds, hardStage = Stages.Needs(data, GROUND, "Hard", 2)
			t.Check("Hard Stage 2 waits for Hard Stage 1", hardNeeds == Stages.Before and hardStage == 1)
			local hard = play(data, "Hard", 4, 100)
			t.Check("Hard's keeper stage can't be skipped to", not hard.Ok)
			for stage = 1, 4 do
				play(data, "Hard", stage, 200)
			end
			local hardKeeper = play(data, "Hard", 4, 200)
			t.Check("the keeper's stage on Hard again: no first, opens nothing, nothing after", hardKeeper.Ok and not hardKeeper.First and hardKeeper.Opened == "" and hardKeeper.Next == nil and hardKeeper.Then == nil)
			t.Equal("all four on Hard", Stages.Line(data, GROUND, "Hard").Cleared, 4)
			local old = fresh()
			Progress.KeeperWon(old, GROUND, NOW)
			t.Check("an account that beat a keeper before the stages isn't fresh", not Stages.Fresh(old))
		end,
	},
	{
		Name = "Stages: a run needs its quota of Shades and its last stop's fall, in either order, and its clear is written once with the best time",
		Run = function(t: any)
			local data = fresh()
			local run = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			local row = (Stages.Of(GROUND) :: any)[1]
			local last = (Stages.Last(GROUND, 1) :: any).Def
			t.Check("the elite before the quota: not done yet", not Stages.Kill(run, last) and run.Last)
			t.Equal("unfinished can't be cleared", Stages.Clear(data, run, NOW + 60).Error, Stages.Unfinished)
			t.Equal("a foe of no pack here counts nothing", (function()
				Stages.Kill(run, "lamplighter")
				return run.Kills
			end)(), 0)
			for _ = 1, row.Quota - 1 do
				Stages.Kill(run, "brawler")
			end
			t.Check("one Shade short: not done", not run.Done)
			t.Check("the quota's last Shade, the elite already down: done", Stages.Kill(run, "brawler"))
			local again = false
			for _ = 1, 5 do
				again = Stages.Kill(run, "brawler") or again
			end
			t.Check("a fall after it finishes nothing more, so the clear is asked for once", not again and not Stages.Kill(run, last) and run.Done)
			t.Equal("the quota stops at its count", run.Kills, row.Quota)
			local other = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			for _ = 1, row.Quota do
				Stages.Kill(other, "brawler")
			end
			t.Check("the quota first, the elite not yet: not done", not other.Done)
			t.Check("the elite after the quota: done", Stages.Kill(other, last))
			local clear = Stages.Clear(data, run, NOW + 175)
			t.Check("cleared in its time", clear.Ok and clear.Seconds == 175 and clear.Best == 175)
			t.Equal("the same run again: refused, nothing doubled", Stages.Clear(data, run, NOW + 180).Error, Stages.Claimed)
			t.Equal("one stage cleared", Stages.Line(data, GROUND, "Normal").Cleared, 1)
			local slower = play(data, "Normal", 1, 240)
			t.Check("a slower replay keeps the best", slower.Ok and not slower.First and slower.Opened == "" and slower.Best == 175)
			local faster = play(data, "Normal", 1, 150)
			t.Equal("a faster one takes it", faster.Best, 150)
			t.Equal("the Best list is whole, so it saves", #Stages.Line(data, GROUND, "Normal").Best, 4)
			local problems = Saveable.Problems(data.Progress.Stages, "Stages")
			t.Check("the record saves", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Stages (TR50): one run of four stretches, each clear moving it on and the checkpoint with it, the keeper's ending it with the whole run's time",
		Run = function(t: any)
			local data = fresh()
			t.Equal("a new account begins at the first stretch", Stages.Checkpoint(data, GROUND, "Normal"), 1)
			local run = Stages.Start(data, GROUND, "Normal", Stages.Checkpoint(data, GROUND, "Normal"), NOW) :: Stages.Run
			t.Check("the run begins there", run ~= nil and run.Stage == 1 and run.From == 1)
			t.Check("not before its clear: no moving on", not Stages.Advance(run, NOW))
			local at = NOW
			for stretch = 1, 3 do
				at += 180
				through(run)
				t.Check(`stretch {stretch}: done`, run.Done)
				t.Check(`stretch {stretch}: its gate lets the run by once done, the next not`, Stages.Through(stretch, run.Stage, run.Done) and not Stages.Through(stretch + 1, run.Stage, run.Done))
				local clear = Stages.Clear(data, run, at)
				t.Check(`stretch {stretch}: cleared in its own time, the run moving on`, clear.Ok and clear.Seconds == 180 and clear.Next == stretch + 1 and not clear.Ends, `{clear.Error} {clear.Seconds}`)
				t.Equal(`stretch {stretch}: the checkpoint moves on`, Stages.Checkpoint(data, GROUND, "Normal"), stretch + 1)
				t.Equal(`stretch {stretch}: the same clear again is refused`, Stages.Clear(data, run, at).Error, Stages.Claimed)
				t.Check(`stretch {stretch}: the run moves on`, Stages.Advance(run, at) and run.Stage == stretch + 1 and run.Kills == 0 and not run.Last and not run.Done and not run.Claimed)
				t.Check(`stretch {stretch}: its gate stays open behind the run`, Stages.Through(stretch, run.Stage, run.Done))
			end
			t.Equal("on Normal, Hard still shut before the keeper", Stages.Needs(data, GROUND, "Hard", 1), Stages.Keeper)
			at += 120
			through(run)
			local keeper = Stages.Clear(data, run, at)
			t.Check("the keeper's fall ends the run: no next stretch, Hard next on its card", keeper.Ok and keeper.Ends and keeper.Next == nil and keeper.Then == "Hard" and keeper.Opened == "Hard")
			t.Equal("the card's time is the whole run's", keeper.Run, 3 * 180 + 120)
			t.Equal("begun at the first stretch: the whole run's best", keeper.RunBest, 3 * 180 + 120)
			t.Check("past the keeper, nowhere to move on to", not Stages.Advance(run, at))
			t.Equal("the keeper's fall clears the checkpoint", Stages.Checkpoint(data, GROUND, "Normal"), 1)
			t.Equal("Hard opens", Stages.Needs(data, GROUND, "Hard", 1), nil)
			t.Equal("Hard's checkpoint is its own: its first", Stages.Checkpoint(data, GROUND, "Hard"), 1)
			local problems = Saveable.Problems(data.Progress.Stages, "Stages")
			t.Check("the record saves", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Stages (TR50): a fall at stretch 3 ends the run, and the next begins at 3, until the keeper falls; Hard keeps its own",
		Run = function(t: any)
			local data = fresh()
			local run = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			for _ = 1, 2 do
				through(run)
				Stages.Clear(data, run, NOW + 100)
				Stages.Advance(run, NOW + 100)
			end
			t.Equal("on stretch 3", run.Stage, 3)
			Stages.Kill(run, "brawler") -- a Shade, then the lead falls: the server drops the run, nothing written
			t.Equal("a fall at 3: the next run begins at 3", Stages.Checkpoint(data, GROUND, "Normal"), 3)
			local again = Stages.Start(data, GROUND, "Normal", Stages.Checkpoint(data, GROUND, "Normal"), NOW + 500) :: Stages.Run
			t.Check("it begins there, from there", again ~= nil and again.Stage == 3 and again.From == 3 and again.Kills == 0)
			local fell = Stages.Start(data, GROUND, "Normal", Stages.Checkpoint(data, GROUND, "Normal"), NOW + 900) :: Stages.Run
			t.Equal("another fall there: still 3", fell.Stage, 3)
			through(again)
			Stages.Clear(data, again, NOW + 700)
			Stages.Advance(again, NOW + 700)
			t.Equal("stretch 3 cleared: the checkpoint at the keeper", Stages.Checkpoint(data, GROUND, "Normal"), 4)
			through(again)
			local keeper = Stages.Clear(data, again, NOW + 800)
			t.Check("the keeper falls: the run ends", keeper.Ok and keeper.Ends)
			t.Equal("a run begun at 3: no whole run's best", keeper.RunBest, nil)
			t.Equal("the checkpoint cleared: the next run at the first", Stages.Checkpoint(data, GROUND, "Normal"), 1)
			local hard = Stages.Start(data, GROUND, "Hard", Stages.Checkpoint(data, GROUND, "Hard"), NOW) :: Stages.Run
			through(hard)
			Stages.Clear(data, hard, NOW + 200)
			t.Check("Hard's checkpoint moves on alone", Stages.Checkpoint(data, GROUND, "Hard") == 2 and Stages.Checkpoint(data, GROUND, "Normal") == 1)
			local broken = fresh()
			Stages.Start(broken, GROUND, "Normal", 1, NOW)
			;(Stages.Line(broken, GROUND, "Normal") :: any).Reached = 9
			t.Equal("a blank record's checkpoint is the first, whatever a blank holds", Stages.Checkpoint(broken, GROUND, "Normal"), 1)
			local problems = Saveable.Problems(data.Progress.Stages, "Stages")
			t.Check("the record saves, its checkpoints in", #problems == 0, table.concat(problems, "; "))
		end,
	},
	{
		Name = "Stages: each stage's recommended Combat Power is its last foe's as it stands there, higher stage by stage, and higher again on Hard",
		Run = function(t: any)
			local before = 0
			for stage = 1, 4 do
				local normal = Stages.Recommended(GROUND, "Normal", stage)
				local hard = Stages.Recommended(GROUND, "Hard", stage)
				local last = Stages.Last(GROUND, stage) :: any
				-- as it stands in the stage: its stage's factor on Normal, Hard's lift and level there (TR49; Config.Enemies)
				t.Equal(`Stage {stage}: its last foe's own`, normal, Stats.Power(Stats.Enemy(last.Def, last.Level, nil, "Normal", stage)))
				t.Equal(`Stage {stage}: on Hard, its lifted own`, hard, Stats.Power(Stats.Enemy(Stages.DefOn(last, "Hard"), Stages.Level(last.Level, "Hard"), nil, "Hard", stage)))
				t.Check(`Stage {stage}: above the one before`, normal > before, `{normal} over {before}`)
				t.Check(`Stage {stage}: Hard above Normal`, hard > normal, `{hard} over {normal}`)
				before = normal
			end
			t.Equal("no such stage: none", Stages.Recommended(GROUND, "Normal", 9), 0)
		end,
	},
	-- The engine-free parts of the Festival place's run case, "Stages (TR50)" (StageCases), as StageService plays them:
	-- which falls count, the gates, the card and the run's attributes. The players are stand-in tables.
	{
		Name = "Stages (TR50): a fall counts for a run when its foe is of the run's ground and stretch, the street's on Normal and the run's own on Hard, never on the keeper's stretch; a Hard pack stands again once its last is down, an elite never",
		Run = function(t: any)
			local me, other = {}, {}
			local data = fresh()
			local run = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			t.Check("Normal: a street Shade of its stretch", Stages.Counts(run, { Ground = GROUND, Stage = 1 }, me))
			t.Check("Normal: not another player's Hard foe", not Stages.Counts(run, { Ground = GROUND, Stage = 1, For = other }, me))
			t.Check("Normal: not its own Hard foe either", not Stages.Counts(run, { Ground = GROUND, Stage = 1, For = me }, me))
			t.Check("not a foe of the next stretch", not Stages.Counts(run, { Ground = GROUND, Stage = 2 }, me))
			t.Check("not a foe of another ground", not Stages.Counts(run, { Ground = "elsewhere", Stage = 1 }, me))
			t.Check("not a foe of no stretch (a base's, a try's)", not Stages.Counts(run, { Ground = GROUND }, me))
			local hard: Stages.Run = { Ground = GROUND, Difficulty = "Hard", Stage = 1, From = 1, Started = NOW, Since = NOW, Kills = 0, Last = false, Done = false, Claimed = false }
			t.Check("Hard: its own foe", Stages.Counts(hard, { Ground = GROUND, Stage = 1, For = me }, me))
			t.Check("Hard: not the street's", not Stages.Counts(hard, { Ground = GROUND, Stage = 1 }, me))
			t.Check("Hard: not another player's", not Stages.Counts(hard, { Ground = GROUND, Stage = 1, For = other }, me))
			t.Check("Hard: no player, nothing counts", not Stages.Counts(hard, { Ground = GROUND, Stage = 1 }, nil))
			local count = #(Stages.Of(GROUND) :: { any })
			local keeper: Stages.Run = { Ground = GROUND, Difficulty = "Normal", Stage = count, From = count, Started = NOW, Since = NOW, Kills = 0, Last = false, Done = false, Claimed = false }
			t.Equal("the last stretch is the keeper's", (Stages.Last(GROUND, count) :: any).Kind, "Keeper")
			t.Check("the keeper's stretch: no fall counts, its try's win does", not Stages.Counts(keeper, { Ground = GROUND, Stage = count }, me))
			-- A stretch played as the server hears its falls: each counts only through Counts, then Kill.
			local row = (Stages.Of(GROUND) :: any)[1]
			local pack: string? = nil
			for _, stop in row.Stops do
				pack = if stop.Kind == "Pack" then stop.Def else pack
			end
			local function fall(foe: { Ground: string?, Stage: number?, For: any }, def: string): boolean
				return Stages.Counts(run, foe, me) and Stages.Kill(run, def)
			end
			for _ = 1, row.Quota do
				fall({ Ground = GROUND, Stage = 2 }, pack :: string) -- the next stretch's: never counted
				fall({ Ground = GROUND, Stage = 1, For = other }, pack :: string) -- another's Hard foe: never counted
			end
			t.Equal("others' falls: none counted", run.Kills, 0)
			for _ = 1, row.Quota + 3 do
				fall({ Ground = GROUND, Stage = 1 }, pack :: string)
			end
			t.Equal("its own: counted up to the quota", run.Kills, row.Quota)
			t.Check("not done before its elite", not run.Done)
			t.Check("its elite: done", fall({ Ground = GROUND, Stage = 1 }, (Stages.Last(GROUND, 1) :: any).Def))
			-- A Hard run's own groups, standing by name.
			local standing: { [string]: string } = { a = "Pack 1", b = "Pack 1", c = "Elite 1", d = "Pack 2" }
			t.Check("a pack with one still up: not yet", not Stages.Regrows(standing, "Pack 1", true))
			standing.a = nil
			t.Check("its other one still up: not yet", not Stages.Regrows(standing, "Pack 1", true))
			standing.b = nil
			t.Check("its last down: it stands again", Stages.Regrows(standing, "Pack 1", true))
			standing.c = nil
			t.Check("an elite down: never in the run", not Stages.Regrows(standing, "Elite 1", false))
			t.Check("another pack's own still up", not Stages.Regrows(standing, "Pack 2", true))
		end,
	},
	{
		Name = "Stages (TR50): a stretch's gate is shut to a fresh save and with no save; in a run it opens behind the run and at its own stretch once done, whatever the record; outside a run, or in one elsewhere, by the Normal record",
		Run = function(t: any)
			local data = fresh()
			t.Check("a fresh save: stretch 1's gate shut", Stages.Shut(data, nil, GROUND, 1))
			t.Check("no save loaded: shut", Stages.Shut(nil, nil, GROUND, 1))
			local run = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			t.Check("in the run, its own stretch not done: shut", Stages.Shut(data, run, GROUND, 1))
			through(run)
			t.Check("its stretch done: open, before the clear is written", not Stages.Shut(data, run, GROUND, 1))
			t.Check("the next one's still shut", Stages.Shut(data, run, GROUND, 2))
			Stages.Clear(data, run, NOW + 60)
			Stages.Advance(run, NOW + 60)
			t.Check("moved on: the gate behind it open", not Stages.Shut(data, run, GROUND, 1))
			t.Check("its new stretch's gate shut", Stages.Shut(data, run, GROUND, 2))
			t.Check("the run over (nil): stretch 1 open by the record", not Stages.Shut(data, nil, GROUND, 1))
			t.Check("and stretch 2 shut by it", Stages.Shut(data, nil, GROUND, 2))
			local elsewhere: Stages.Run = { Ground = "elsewhere", Difficulty = "Normal", Stage = 3, From = 3, Started = NOW, Since = NOW, Kills = 0, Last = false, Done = false, Claimed = false }
			t.Check("a run on another ground: this one's gates by the record", not Stages.Shut(data, elsewhere, GROUND, 1) and Stages.Shut(data, elsewhere, GROUND, 2))
			local count = #(Stages.Of(GROUND) :: { any })
			;(Stages.Line(data, GROUND, "Normal") :: any).Cleared = count -- every stretch cleared on Normal
			local hard = Stages.Start(data, GROUND, "Hard", 1, NOW) :: Stages.Run
			t.Check("Hard opened by the keeper on Normal", hard ~= nil)
			t.Check("a Hard run at 1: its own gate shut though the record has passed it", Stages.Shut(data, hard, GROUND, 1))
			t.Check("outside it, the record lets them by", not Stages.Shut(data, nil, GROUND, 1))
		end,
	},
	{
		Name = "Stages (TR50): the keeper's card carries the whole run's time, its best, what it opened and what it gave, never below 0; a fall's card the save's checkpoint; the run's attributes read back as written, and its log name",
		Run = function(t: any)
			t.Check("no save: holds nothing", (function()
				local none = Stages.Holdings(nil)
				return none.Credits == 0 and none.Shards == 0 and none.Chests == 0
			end)())
			local data = fresh()
			data.Currency.Credits = 500
			data.Bag.Shards.a = 2
			data.Bag.Shards.b = 3
			data.Bag.Chests.c = 1
			local before = Stages.Holdings(data)
			t.Check("it sums every kind", before.Credits == 500 and before.Shards == 5 and before.Chests == 1, `{before.Credits} {before.Shards} {before.Chests}`)
			local run = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			local count = #(Stages.Of(GROUND) :: { any })
			local answer: { [string]: any } = {}
			for stretch = 1, count do
				through(run)
				answer = Stages.Clear(data, run, NOW + 100 * stretch)
				Stages.Advance(run, NOW + 100 * stretch)
			end
			-- what the run gave: Credits and a chest in, a shard spent
			data.Currency.Credits += 120
			data.Bag.Chests.c += 2
			data.Bag.Shards.a -= 1
			local card = Stages.Won(run, answer, before, Stages.Holdings(data))
			t.Check("won, at the keeper, begun at the first", card.Won == true and card.Stage == count and card.From == 1 and card.Count == count)
			t.Equal("its whole run's seconds", card.Seconds, 100 * count)
			t.Equal("its best whole run", card.Best, 100 * count)
			t.Check("first, it opened Hard, and offers it next", card.First == true and card.Opened == "Hard" and card.Then == "Hard")
			t.Equal("the Credits it gave", card.Credits, 120)
			t.Equal("the chests it gave", card.Chests, 2)
			t.Equal("a shard spent: 0 given, never less", card.Shards, 0)
			local spent = Stages.Holdings(data)
			spent.Credits = before.Credits - 300 -- more spent at the Forge than the run gave
			t.Equal("Credits spent past the gain: 0, never less", Stages.Won(run, answer, before, spent).Credits, 0)
			local missed = Stages.Won(run, { Ok = false, Error = "Saving" }, before, before)
			t.Check("a clear the save missed: the card still comes, with nothing opened", missed.Won == true and missed.Opened == "" and missed.Seconds == nil and missed.Credits == 0)
			-- a fall at stretch 3
			local again = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			for stretch = 1, 2 do
				through(again)
				Stages.Clear(data, again, NOW + 10 * stretch)
				Stages.Advance(again, NOW + 10 * stretch)
			end
			local lost = Stages.Lost(again, data)
			t.Check("the fall's card: lost at 3, begun at 1", lost.Won == false and lost.Stage == 3 and lost.From == 1 and lost.Count == count)
			t.Equal("the next run begins at the save's checkpoint", lost.Checkpoint, 3)
			t.Equal("no save loaded: at the run's stretch", Stages.Lost(again, nil).Checkpoint, 3)
			local lead = data.Voidkin[Collection.Uncover(data, "rook", NOW).Id]
			data.Roles.Lead = lead.Id
			lost = Stages.Lost(again, data)
			t.Check("it names its lead, as a list shows it (research's lines, TR54)", lead ~= nil and lost.Lead == Collection.Name(lead) and lost.Lead ~= "", tostring(lost.Lead))
			t.Equal("no save loaded: no name", Stages.Lost(again, nil).Lead, nil)
			t.Equal("a fall carries no gain", lost.Credits, nil)
			-- the attributes the client reads (StageController), and back
			local none = Stages.Published(nil)
			t.Check("no run: every attribute cleared", none.StageRun == nil and none.StageKills == nil and none.StageQuota == nil and none.StageLast == nil)
			again.Kills = 4
			local view = Stages.Published(again)
			t.Equal("its difficulty and stretch", view.StageRun, "Normal 3")
			t.Check("its count, its stretch's quota, its last stop", view.StageKills == 4 and view.StageQuota == (Stages.Of(GROUND) :: any)[3].Quota and view.StageLast == false)
			local difficulty, stretch = Stages.Parse(view.StageRun)
			t.Check("read back as written", difficulty == "Normal" and stretch == 3, `{difficulty} {stretch}`)
			local d2, s2 = Stages.Parse("Hard 12")
			t.Check("Hard and two digits", d2 == "Hard" and s2 == 12)
			for _, junk in { nil :: any, 5, "", "Normal", "Normal x", " Normal 2", "Normal 2 " } do
				local d, s = Stages.Parse(junk)
				t.Check(`{tostring(junk)}: nothing`, d == nil and s == nil)
			end
			t.Equal("a run begun earlier: its log name spans", Stages.Label(again), `{GROUND} Normal 1-3`)
			local one = Stages.Start(data, GROUND, "Normal", 3, NOW) :: Stages.Run
			t.Equal("begun where it is: one stretch", Stages.Label(one), `{GROUND} Normal 3`)
		end,
	},
	-- TR48's keeper in a run, as StageService hears KeeperService (Trying, Won, LevelOf, DifficultyOf): the engine-free part
	-- of the Festival place's Keeper case.
	{
		Name = "Stages (TR48): a keeper's try begins the keeper's stretch on Normal unless the run is there already; its win ends that stretch on the run's difficulty, the keeper ten levels up on Hard and its win counted there",
		Run = function(t: any)
			local count = #(Stages.Of(GROUND) :: { any })
			local keeper = Stages.Last(GROUND, count) :: any
			t.Equal("no run: the try begins the keeper's stretch", Stages.TryAt(nil, GROUND), count)
			t.Equal("a ground with no stretches: none", Stages.TryAt(nil, "nowhere"), nil)
			local data = fresh()
			local early = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			t.Equal("a run at stretch 1: the try begins the keeper's instead", Stages.TryAt(early, GROUND), count)
			t.Check("the keeper's win doesn't count for stretch 1", not Stages.KeeperFell(early, GROUND) and not early.Last)
			for stretch = 1, count - 1 do
				through(early)
				Stages.Clear(data, early, NOW + 10 * stretch)
				Stages.Advance(early, NOW + 10 * stretch)
			end
			t.Equal("the run reached the keeper: the try begins nothing new", Stages.TryAt(early, GROUND), nil)
			t.Equal("its keeper at its own level on Normal", Stages.Level(keeper.Level, early.Difficulty), keeper.Level)
			t.Check("a win on another ground: not this run's", not Stages.KeeperFell(early, "elsewhere"))
			t.Check("its keeper's win: the stretch done, no quota", Stages.KeeperFell(early, GROUND) and early.Done)
			local clear = Stages.Clear(data, early, NOW + 100)
			t.Check("the run ends, Hard opened and offered", clear.Ok and clear.Ends and clear.Opened == "Hard" and clear.Then == "Hard")
			local win = Progress.KeeperWon(data, GROUND, NOW + 100, early.Difficulty)
			t.Check("the try's win counts on Normal", win.Ok == true and win.Difficulty == "Normal" and data.Progress.Grounds[GROUND].KeeperWins.Normal == 1)
			;(Stages.Line(data, GROUND, "Hard") :: any).Cleared = count - 1 -- Hard played to its keeper
			local hard = Stages.Start(data, GROUND, "Hard", count, NOW + 500) :: Stages.Run
			t.Check("a Hard run at the keeper's stretch", hard ~= nil and hard.Difficulty == "Hard")
			t.Equal("its try begins nothing new: Hard's keeper is fought as Hard's", Stages.TryAt(hard, GROUND), nil)
			t.Equal("the keeper ten levels up", Stages.Level(keeper.Level, hard.Difficulty), keeper.Level + 10)
			t.Check("its win ends Hard's keeper stretch", Stages.KeeperFell(hard, GROUND))
			local hardClear = Stages.Clear(data, hard, NOW + 600)
			t.Check("Hard's card offers nothing after", hardClear.Ok and hardClear.Ends and hardClear.Then == nil)
			local hardWin = Progress.KeeperWon(data, GROUND, NOW + 600, hard.Difficulty)
			t.Check("the win counts on Hard, apart from Normal's", hardWin.Ok == true and data.Progress.Grounds[GROUND].KeeperWins.Hard == 1 and data.Progress.Grounds[GROUND].KeeperWins.Normal == 1)
			t.Equal("both checkpoints back at the first", Stages.Checkpoint(data, GROUND, "Hard") + Stages.Checkpoint(data, GROUND, "Normal"), 2)
		end,
	},
	{
		Name = "Stages: a stretch moves on after its check, and the run's card waits until the keeper's fade is back",
		Run = function(t: any)
			local rows = Stages.Of(GROUND) :: { any }
			local keeper = CombatConfig.Keeper
			local back = keeper.WinPause + keeper.Fade.Out + keeper.Fade.Hold + keeper.Fade.Back
			for stage = 1, #rows do
				local last = Stages.Last(GROUND, stage) :: any
				local after = Stages.After(GROUND, stage)
				if stage == #rows and last.Kind == "Keeper" then
					t.Check(`stretch {stage}: the card after the fade is back`, after > back, `{after} s against {back}`)
					t.Check(`stretch {stage}: and no longer than a breath after it`, after <= back + 0.5, `{after} s`)
				else
					t.Equal(`stretch {stage}: its check's time`, after, StagesConfig.Results.After)
				end
				t.Check(`stretch {stage}: never before the fall has played`, after >= StagesConfig.Results.After)
			end
			t.Equal("the last stretch ends on the keeper", (Stages.Last(GROUND, #rows) :: any).Kind, "Keeper")
			t.Equal("a ground with no stages: the plain wait", Stages.After("nowhere", 1), StagesConfig.Results.After)
		end,
	},
}
