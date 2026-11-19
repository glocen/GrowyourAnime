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
local Stages = require(Shared.Rules.Stages)
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
	Stages.Kill(run, (Stages.Last(GROUND, stage) :: any).Def)
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
	Stages.Kill(run, (Stages.Last(GROUND, run.Stage) :: any).Def)
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
			for _ = 1, 5 do
				Stages.Kill(run, "brawler")
			end
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
				t.Equal(`Stage {stage}: on Hard, its lifted own`, hard, Stats.Power(Stats.Enemy(last.Def, Stages.Level(last.Level, "Hard"), nil, "Hard", stage)))
				t.Check(`Stage {stage}: above the one before`, normal > before, `{normal} over {before}`)
				t.Check(`Stage {stage}: Hard above Normal`, hard > normal, `{hard} over {normal}`)
				before = normal
			end
			t.Equal("no such stage: none", Stages.Recommended(GROUND, "Normal", 9), 0)
		end,
	},
}
