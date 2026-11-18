--!strict
-- Logic cases (pure): a ground's stages on Normal and Hard (TR43; Rules.Stages; Config.Stages). A stage needs the one
-- before it on the same difficulty, Hard opens when the keeper's stage falls on Normal, a run counts its quota of Shades
-- before its last stop, and its clear is written once, best time kept. Runs in Studio (LogicTests) and with Studio closed.

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
		Name = "Stages: a stage needs the one before it on its difficulty, and Hard opens when the keeper's stage falls on Normal",
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
			local first = play(data, "Normal", 1, 170)
			t.Check("Stage 1 clears, first, opening Stage 2", first.Ok and first.First and first.Opened == "Stage" and first.Next == 2, `{first.Error}`)
			t.Check("no longer fresh", not Stages.Fresh(data))
			t.Equal("Stage 2 open now", Stages.Needs(data, GROUND, "Normal", 2), nil)
			play(data, "Normal", 2, 180)
			play(data, "Normal", 3, 190)
			t.Equal("Hard still shut before the keeper", Stages.Needs(data, GROUND, "Hard", 1), Stages.Keeper)
			local keeper = play(data, "Normal", 4, 120)
			t.Check("the keeper's stage on Normal opens Hard", keeper.Ok and keeper.Opened == "Hard" and keeper.Next == nil, `{keeper.Opened}`)
			t.Equal("Hard Stage 1 open", Stages.Needs(data, GROUND, "Hard", 1), nil)
			local hardNeeds, hardStage = Stages.Needs(data, GROUND, "Hard", 2)
			t.Check("Hard Stage 2 waits for Hard Stage 1", hardNeeds == Stages.Before and hardStage == 1)
			local hard = play(data, "Hard", 4, 100)
			t.Check("Hard's keeper stage can't be skipped to", not hard.Ok)
			for stage = 1, 4 do
				play(data, "Hard", stage, 200)
			end
			local hardKeeper = play(data, "Hard", 4, 200)
			t.Check("the keeper's stage on Hard again: no first, opens nothing", hardKeeper.Ok and not hardKeeper.First and hardKeeper.Opened == "")
			t.Equal("all four on Hard", Stages.Line(data, GROUND, "Hard").Cleared, 4)
			local old = fresh()
			Progress.KeeperWon(old, GROUND, NOW)
			t.Check("an account that beat a keeper before the stages isn't fresh", not Stages.Fresh(old))
		end,
	},
	{
		Name = "Stages: a run counts its quota of Shades before its last stop, and its clear is written once with the best time",
		Run = function(t: any)
			local data = fresh()
			local run = Stages.Start(data, GROUND, "Normal", 1, NOW) :: Stages.Run
			local row = (Stages.Of(GROUND) :: any)[1]
			local last = (Stages.Last(GROUND, 1) :: any).Def
			t.Check("the elite before the quota: not done", not Stages.Kill(run, last))
			t.Equal("unfinished can't be cleared", Stages.Clear(data, run, NOW + 60).Error, Stages.Unfinished)
			t.Equal("a foe of no pack here counts nothing", (function()
				Stages.Kill(run, "lamplighter")
				return run.Kills
			end)(), 0)
			for _ = 1, row.Quota + 5 do
				Stages.Kill(run, "brawler")
			end
			t.Equal("the quota stops at its count", run.Kills, row.Quota)
			t.Check("the elite after the quota: done", Stages.Kill(run, last))
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
		Name = "Stages: each stage's recommended Combat Power is its last foe's, higher stage by stage, and higher again on Hard",
		Run = function(t: any)
			local before = 0
			for stage = 1, 4 do
				local normal = Stages.Recommended(GROUND, "Normal", stage)
				local hard = Stages.Recommended(GROUND, "Hard", stage)
				local last = Stages.Last(GROUND, stage) :: any
				t.Equal(`Stage {stage}: its last foe's own`, normal, Stats.Power(Stats.Enemy(last.Def, last.Level)))
				t.Check(`Stage {stage}: above the one before`, normal > before, `{normal} over {before}`)
				t.Check(`Stage {stage}: Hard above Normal`, hard > normal, `{hard} over {normal}`)
				before = normal
			end
			t.Equal("no such stage: none", Stages.Recommended(GROUND, "Normal", 9), 0)
		end,
	},
}
