--!strict
-- Stages (pure rules): a ground's street in stages, each played on Normal or Hard (TR43; the director, 2026-11-18, D2;
-- docs/design.md, "The Festival of Battles"; Config.Stages). A stage needs the one before it on the same difficulty, and
-- Hard opens for a ground when its keeper's stage falls on Normal. A stage played is a run, held by the server while it
-- lasts and never saved: its ordinary Shades count to its quota, its last stop's fall counts too, and once both are in it
-- ends, in either order, and its clear is written once. The server decides each fall; this only counts and writes. No
-- Roblox API.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local StagesConfig = require(Shared.Config.Stages)
local Progress = require(Shared.Rules.Progress)
local Stats = require(Shared.Rules.Stats)

local Stages = {}

Stages.Difficulties = { "Normal", "Hard" }

-- Refusals.
Stages.Unknown = "Unknown" -- no such ground, difficulty or stage
Stages.Locked = "Locked" -- the stage isn't open to this player yet (Stages.Needs says what it waits for)
Stages.Unfinished = "Unfinished" -- the run's last stop hasn't fallen
Stages.Claimed = "Claimed" -- the run's clear is already written

-- What a locked stage waits for (Stages.Needs).
Stages.Ground = "Ground" -- the ground isn't open to this player
Stages.Before = "Before" -- the stage before it, on the same difficulty
Stages.Keeper = "Keeper" -- for Hard: the keeper's stage, on Normal

export type Run = {
	Ground: string,
	Difficulty: string,
	Stage: number,
	Started: number, -- os.time() it began
	Kills: number, -- its ordinary Shades that fell to the player, up to the quota
	Last: boolean, -- its last stop's foe fell to the player
	Done: boolean, -- both: the quota met and its last stop fallen
	Claimed: boolean, -- its clear is written
}

-- A ground's stages, or nil for a ground with none.
function Stages.Of(ground: string): { StagesConfig.Stage }?
	return StagesConfig.Grounds[ground]
end

-- The stage's last stop: the foe whose fall ends it (an elite, or the keeper).
function Stages.Last(ground: string, stage: number): { Kind: string, Def: string, Level: number, Count: number? }?
	local rows = Stages.Of(ground)
	local row = if rows then rows[stage] else nil
	return if row then row.Stops[#row.Stops] else nil
end

local function valid(ground: string, difficulty: string, stage: number): boolean
	local rows = Stages.Of(ground)
	return rows ~= nil
		and StagesConfig.Offset[difficulty] ~= nil
		and type(stage) == "number"
		and stage % 1 == 0
		and stage >= 1
		and stage <= #rows
end

-- This player's record of a ground on one difficulty; a blank one when none is saved yet (not written).
function Stages.Line(data: Profile.Data, ground: string, difficulty: string): Profile.StageLine
	local record = data.Progress.Stages[ground]
	local line = if record then (record :: any)[difficulty] :: Profile.StageLine? else nil
	return line or { Cleared = 0, Best = {} }
end

-- The saved record, made on its first write: every stage's best present, 0 before one is timed, so it saves as a list.
local function written(data: Profile.Data, ground: string): Profile.StageProgress
	local record = data.Progress.Stages[ground]
	if record == nil then
		local count = #(Stages.Of(ground) :: { StagesConfig.Stage })
		local function blank(): Profile.StageLine
			return { Cleared = 0, Best = table.create(count, 0) }
		end
		record = { Normal = blank(), Hard = blank() }
		data.Progress.Stages[ground] = record
	end
	return record :: Profile.StageProgress
end

-- Nil when the stage is open to this player; else what it waits for, and for Stages.Before the stage it needs.
-- Stages.Unknown for no such ground, difficulty or stage.
function Stages.Needs(data: Profile.Data, ground: string, difficulty: string, stage: number): (string?, number?)
	if not valid(ground, difficulty, stage) then
		return Stages.Unknown, nil
	end
	if not Progress.IsOpen(data, ground) then
		return Stages.Ground, nil
	end
	local count = #(Stages.Of(ground) :: { StagesConfig.Stage })
	if difficulty == "Hard" and Stages.Line(data, ground, "Normal").Cleared < count then
		return Stages.Keeper, nil
	end
	if Stages.Line(data, ground, difficulty).Cleared < stage - 1 then
		return Stages.Before, stage - 1
	end
	return nil, nil
end

-- A new run of a stage at `now`, or nil and the refusal.
function Stages.Start(data: Profile.Data, ground: string, difficulty: string, stage: number, now: number): (Run?, string?)
	local needs = Stages.Needs(data, ground, difficulty, stage)
	if needs == Stages.Unknown then
		return nil, Stages.Unknown
	elseif needs then
		return nil, Stages.Locked
	end
	return { Ground = ground, Difficulty = difficulty, Stage = stage, Started = now, Kills = 0, Last = false, Done = false, Claimed = false }, nil
end

-- A foe of the run's stage fell with the player among its hitters: an ordinary Shade of one of its packs counts to the
-- quota, and its last stop's foe counts once. The run is done when both are in, in either order: on Normal the elite is
-- the street's, back only Config.World.Row.Back.Elite after its fall, so one felled before the quota still counts.
-- Whether the run is done.
function Stages.Kill(run: Run, def: string): boolean
	local rows = Stages.Of(run.Ground)
	local row = if rows then rows[run.Stage] else nil
	if row == nil or run.Done then
		return run.Done
	end
	local last = row.Stops[#row.Stops]
	if def == last.Def and last.Kind ~= "Pack" then
		run.Last = true
	else
		for _, stop in row.Stops do
			if stop.Kind == "Pack" and stop.Def == def then
				run.Kills = math.min(row.Quota, run.Kills + 1)
				break
			end
		end
	end
	run.Done = run.Last and run.Kills >= row.Quota
	return run.Done
end

-- Writes the run's clear at `now`, once: the stage counted cleared on its difficulty, its best time kept. { Ok, First,
-- Seconds, Best, Opened, Next } where First is the first clear of that stage on that difficulty, Opened what that first
-- clear opened ("Stage" for the next stage, "Hard" when the keeper's stage falls on Normal, "" for none), and Next and
-- NextDifficulty the stage its card offers next: the next on its difficulty, Hard's first after the keeper's stage on
-- Normal (AR42's card), nil after Hard's last.
function Stages.Clear(data: Profile.Data, run: Run, now: number): { [string]: any }
	local rows = Stages.Of(run.Ground)
	if rows == nil or not valid(run.Ground, run.Difficulty, run.Stage) then
		return { Ok = false, Error = Stages.Unknown }
	elseif run.Claimed then
		return { Ok = false, Error = Stages.Claimed }
	elseif not run.Done then
		return { Ok = false, Error = Stages.Unfinished }
	end
	run.Claimed = true
	local line = (written(data, run.Ground) :: any)[run.Difficulty] :: Profile.StageLine
	local seconds = math.max(0, now - run.Started)
	local first = line.Cleared < run.Stage
	line.Cleared = math.max(line.Cleared, run.Stage)
	local best = line.Best[run.Stage] or 0
	if best == 0 or seconds < best then
		line.Best[run.Stage] = seconds
	end
	local count = #rows
	local opened = ""
	if first and run.Stage < count then
		opened = "Stage"
	elseif first and run.Difficulty == "Normal" then
		opened = "Hard"
	end
	local nextStage: number?, nextDifficulty: string? = nil, nil
	if run.Stage < count then
		nextStage, nextDifficulty = run.Stage + 1, run.Difficulty
	elseif run.Difficulty == "Normal" then
		nextStage, nextDifficulty = 1, "Hard" -- clearing the keeper's stage on Normal opened Hard (Stages.Needs)
	end
	return {
		Ok = true,
		First = first,
		Seconds = seconds,
		Best = line.Best[run.Stage],
		Opened = opened,
		Next = nextStage,
		NextDifficulty = nextDifficulty,
	}
end

-- Whether this player has cleared nothing yet, a stage or a keeper anywhere: the Festival Door then sends them straight
-- into Stage 1 on Normal, with no picker (TR43).
function Stages.Fresh(data: Profile.Data): boolean
	for _, record in data.Progress.Stages do
		if record.Normal.Cleared > 0 or record.Hard.Cleared > 0 then
			return false
		end
	end
	for _, record in data.Progress.Grounds do
		if Progress.Wins(record) > 0 then
			return false
		end
	end
	return true
end

-- Whether stage `stage`'s gate on the street lets this player by, going up it: once they've cleared that stage on
-- Normal (TR43). Its gate shuts the way to the next stage, so a stage played before is a stage passed.
function Stages.Passes(data: Profile.Data, ground: string, stage: number): boolean
	return Stages.Line(data, ground, "Normal").Cleared >= stage
end

-- A foe's level in a stage on `difficulty`: its stop's, lifted on Hard.
function Stages.Level(level: number, difficulty: string): number
	return level + (StagesConfig.Offset[difficulty] or 0)
end

-- A stage's recommended Combat Power on `difficulty`: its last foe's own, at its level there. What a lead should stand at
-- to win it; the builder's seed (tier 2, for research), 0 for no such stage.
function Stages.Recommended(ground: string, difficulty: string, stage: number): number
	local last = Stages.Last(ground, stage)
	if last == nil or StagesConfig.Offset[difficulty] == nil then
		return 0
	end
	return Stats.Power(Stats.Enemy(last.Def, Stages.Level(last.Level, difficulty)))
end

return Stages
