--!strict
-- Stages (pure rules): a ground's one mission, a run of its stretches to its keeper, on Normal or Hard (TR50; the
-- director, 2026-11-19, 23:19, replacing D2's four stages; docs/design.md, "The Festival of Battles"; Config.Stages).
-- A run begins at its difficulty's checkpoint, the last stretch reached there, or the first once that difficulty's keeper
-- has fallen; Hard opens for a ground when its keeper falls on Normal. A run is held by the server while it lasts and
-- never saved. In each stretch its ordinary Shades count to its quota and its last stop's fall counts too; once both are
-- in, in either order, that stretch's clear is written once (the checkpoint moves on with it) and the run moves on to the
-- next stretch, until the keeper's ends it. A stretch's gate on the street lets the run's player by once that stretch is
-- done. The server decides each fall; this only counts and writes. No Roblox API.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local StagesConfig = require(Shared.Config.Stages)
local CombatConfig = require(Shared.Config.Combat)
local Progress = require(Shared.Rules.Progress)
local Stats = require(Shared.Rules.Stats)
local Goals = require(Shared.Rules.Goals)
local Collection = require(Shared.Rules.Collection)

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
	Stage: number, -- the stretch it's on
	From: number, -- the stretch it began at
	Started: number, -- os.time() it began
	Since: number, -- os.time() its stretch began
	Kills: number, -- its stretch's ordinary Shades that fell to the player, up to the quota
	Last: boolean, -- its stretch's last stop's foe fell to the player
	Done: boolean, -- both: the quota met and its stretch's last stop fallen
	Claimed: boolean, -- its stretch's clear is written
}

-- A ground's stages, or nil for a ground with none.
function Stages.Of(ground: string): { StagesConfig.Stage }?
	return StagesConfig.Grounds[ground]
end

-- The stage's last stop: the foe whose fall ends it (an elite, or the keeper).
function Stages.Last(ground: string, stage: number): { Kind: string, Def: string, Level: number, Count: number?, Hard: string? }?
	local rows = Stages.Of(ground)
	local row = if rows then rows[stage] else nil
	return if row then row.Stops[#row.Stops] else nil
end

-- The def that stands at a stop on `difficulty`: its Hard one there, else its own (AR57: the square's elite).
function Stages.DefOn(stop: { Def: string, Hard: string? }, difficulty: string?): string
	return if difficulty == "Hard" and stop.Hard then stop.Hard else stop.Def
end

-- Seconds from the fall that ends `stage` to what follows it: the next stretch, or the run's card. A keeper's fall is
-- followed by its try's fade out and back (Config.Combat.Keeper), which covers every screen, so the card of a run that
-- ends on a keeper waits until the fade is back: the fall is seen whole, and the card is never drawn under the black.
function Stages.After(ground: string, stage: number): number
	local rows = Stages.Of(ground)
	local last = Stages.Last(ground, stage)
	if rows and last and last.Kind == "Keeper" and stage >= #rows then
		local keeper = CombatConfig.Keeper
		return math.max(StagesConfig.Results.After, keeper.WinPause + keeper.Fade.Out + keeper.Fade.Hold + keeper.Fade.Back + StagesConfig.Results.Clear)
	end
	return StagesConfig.Results.After
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

-- The stretch a run on `difficulty` begins at: the last reached there, or the first (none reached, or its keeper fallen
-- since, TR50). 1 for a ground with no stretches.
function Stages.Checkpoint(data: Profile.Data, ground: string, difficulty: string): number
	local count = #((Stages.Of(ground) or {}) :: { StagesConfig.Stage })
	local reached = Stages.Line(data, ground, difficulty).Reached
	return if type(reached) == "number" and reached % 1 == 0 then math.clamp(reached, 1, math.max(count, 1)) else 1
end

-- Where a run on `difficulty` begins for this player and whether it may (the base's pick, StageService.Travel): { Ok,
-- Stage } at its checkpoint, or { Ok = false, Error (Unknown or Locked), Needs?, Waits? } as Stages.Needs says.
function Stages.Way(data: Profile.Data, ground: string, difficulty: string): { [string]: any }
	local stage = Stages.Checkpoint(data, ground, difficulty)
	local needs, waits = Stages.Needs(data, ground, difficulty, stage)
	if needs == Stages.Unknown then
		return { Ok = false, Error = Stages.Unknown }
	elseif needs then
		return { Ok = false, Error = Stages.Locked, Needs = needs, Waits = waits }
	end
	return { Ok = true, Stage = stage }
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
	return { Ground = ground, Difficulty = difficulty, Stage = stage, From = stage, Started = now, Since = now, Kills = 0, Last = false, Done = false, Claimed = false }, nil
end

-- A foe of the run's stage fell with the player among its hitters: an ordinary Shade of one of its packs counts to the
-- quota, and its last stop's foe counts once. The run is done when both are in, in either order: on Normal the elite is
-- the street's, back only Config.World.Row.Back.Elite after its fall, so one felled before the quota still counts.
-- Whether this fall finished the stretch: true once, so its clear is written once. A fall after it (a pack felled whole
-- past the quota, a Hard pack standing again before the run moves on) finishes nothing (run.Done says it's done).
function Stages.Kill(run: Run, def: string): boolean
	local rows = Stages.Of(run.Ground)
	local row = if rows then rows[run.Stage] else nil
	if row == nil or run.Done then
		return false
	end
	local last = row.Stops[#row.Stops]
	if def == Stages.DefOn(last, run.Difficulty) and last.Kind ~= "Pack" then
		run.Last = true
	else
		for _, stop in row.Stops do
			if stop.Kind == "Pack" and (stop.Def == def or (stop.With ~= nil and stop.With.Def == def) or (stop.Rear ~= nil and stop.Rear.Def == def)) then
				run.Kills = math.min(row.Quota, run.Kills + 1)
				break
			end
		end
	end
	run.Done = run.Last and run.Kills >= row.Quota
	return run.Done
end

-- Whether a foe's fall counts for `who`'s run (StageService, before Stages.Kill): a foe of the run's ground and stretch, on
-- Normal one of the street's (no `For`), on Hard one of the run's own (`For` is `who`). Never on a keeper's stretch: the
-- try's own win counts it (KeeperService.Won).
function Stages.Counts(run: Run, foe: { Ground: string?, Stage: number?, For: any }, who: any): boolean
	local last = Stages.Last(run.Ground, run.Stage)
	if last and last.Kind == "Keeper" then
		return false
	elseif foe.Stage ~= run.Stage or foe.Ground ~= run.Ground then
		return false
	end
	return if run.Difficulty == "Normal" then foe.For == nil else who ~= nil and foe.For == who
end

-- The stretch a keeper's try on `ground` begins a run at (StageService, on KeeperService.Trying): the keeper's, on Normal,
-- so its win is that stretch's last stop; nil when the player's run is already there (on either difficulty: a Hard run's
-- keeper is fought as Hard's), or the ground has no stretches.
function Stages.TryAt(run: Run?, ground: string): number?
	local count = #((Stages.Of(ground) or {}) :: { StagesConfig.Stage })
	if count == 0 or (run and run.Ground == ground and run.Stage == count) then
		return nil
	end
	return count
end

-- A keeper's try on `ground` won (KeeperService.Won): counted as the run's last stop when the run is on that ground's
-- keeper's stretch. Whether the run is done.
function Stages.KeeperFell(run: Run, ground: string): boolean
	local last = Stages.Last(run.Ground, run.Stage)
	if run.Ground ~= ground or last == nil or last.Kind ~= "Keeper" then
		return false
	end
	return Stages.Kill(run, last.Def)
end

-- Whether a Hard run's group `name` stands again for its player: a pack, once the last of its foes is down (`standing`:
-- the run's own foes still up, each by its group's name). An elite never does while the run lasts.
function Stages.Regrows(standing: { [any]: string }, name: string, isPack: boolean): boolean
	if not isPack then
		return false
	end
	for _, group in standing do
		if group == name then
			return false
		end
	end
	return true
end

-- Writes the clear of the run's stretch at `now`, once: the stretch counted cleared on its difficulty, its best time kept,
-- and the checkpoint moved on to the next stretch, or cleared with the keeper's. { Ok, First, Seconds, Best, Opened,
-- Next, Ends, Run, RunBest, Then } where First is the first clear of that stretch on that difficulty; Opened what it
-- opened ("Stage" for the next stretch, "Hard" when the keeper falls on Normal, "" for none); Next the stretch the run
-- moves on to (Stages.Advance), nil when the keeper's clear Ends it. At the end: Run its seconds from its beginning,
-- RunBest the best whole run's (begun at the first stretch), and Then the difficulty its card offers next: Hard after
-- Normal's, nil after Hard's.
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
	if run.Difficulty == "Hard" then
		Goals.Note(data, "HardStretch") -- today's "clear a stretch on Hard" (TR54)
	end
	local line = (written(data, run.Ground) :: any)[run.Difficulty] :: Profile.StageLine
	local seconds = math.max(0, now - run.Since)
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
	local ends = run.Stage >= count
	local whole = math.max(0, now - run.Started)
	if ends then
		line.Reached = nil -- the keeper fell: the next run begins at the first stretch
		if run.From == 1 and (line.Run == nil or line.Run == 0 or whole < line.Run) then
			line.Run = whole
		end
	else
		line.Reached = run.Stage + 1
	end
	return {
		Ok = true,
		First = first,
		Seconds = seconds,
		Best = line.Best[run.Stage],
		Opened = opened,
		Next = if ends then nil else run.Stage + 1,
		Ends = ends,
		Run = if ends then whole else nil,
		RunBest = if ends then line.Run else nil,
		Then = if ends and run.Difficulty == "Normal" then "Hard" else nil, -- the keeper on Normal opened Hard (Stages.Needs)
	}
end

-- Moves a run whose stretch's clear is written on to the next stretch at `now`, its count begun again. Whether it moved:
-- not past the last stretch, nor before the clear.
function Stages.Advance(run: Run, now: number): boolean
	local count = #((Stages.Of(run.Ground) or {}) :: { StagesConfig.Stage })
	if not run.Claimed or run.Stage >= count then
		return false
	end
	run.Stage += 1
	run.Since = now
	run.Kills = 0
	run.Last = false
	run.Done = false
	run.Claimed = false
	return true
end

-- Whether stretch `gate`'s gate lets a run's player by, the run on stretch `stage` (`done`: that stretch's quota and last
-- stop in): a stretch behind it, or its own once done (TR50). The run's own order, whatever the record says.
function Stages.Through(gate: number, stage: number, done: boolean): boolean
	return gate < stage or (gate == stage and done)
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

-- Whether stage `stage`'s gate on the street lets this player by, going up it, outside a run: once they've cleared that
-- stage on Normal (TR43). In a run, the run's own order (Stages.Through).
function Stages.Passes(data: Profile.Data, ground: string, stage: number): boolean
	return Stages.Line(data, ground, "Normal").Cleared >= stage
end

-- Whether stretch `gate`'s gate on `ground` is shut to a player (StageService's watch): in a run on that ground, by the
-- run's own order (Stages.Through); outside one, or in a run on another ground, until they've cleared that stretch on
-- Normal (Stages.Passes); with no save loaded, shut. `run` is nil when there's none or it is ending.
function Stages.Shut(data: Profile.Data?, run: Run?, ground: string, gate: number): boolean
	if run and run.Ground == ground then
		return not Stages.Through(gate, run.Stage, run.Done)
	end
	return data == nil or not Stages.Passes(data, ground, gate)
end

-- The run's contract with the client and its card (StageService; StageController, StageScreen).

export type Gave = { Credits: number, Shards: number, Chests: number }

-- What a save holds of what a run gives: its Credits, and its shards and chests of every kind, summed. A run's card says
-- what it gave as the change from its beginning to its end (Stages.Won). No save: nothing.
function Stages.Holdings(data: Profile.Data?): Gave
	local gave = { Credits = 0, Shards = 0, Chests = 0 }
	if data then
		gave.Credits = data.Currency.Credits
		for _, n in data.Bag.Shards do
			gave.Shards += n
		end
		for _, n in data.Bag.Chests do
			gave.Chests += n
		end
	end
	return gave
end

-- The run's card at its keeper's clear (Net StageDone, Won): `answer` is that clear's (Stages.Clear, whose Run, RunBest,
-- First, Opened and Then it carries), `before` and `after` the save's holdings as the run began and now. What it gave is
-- never below 0, so a spend during the run never reads as a loss.
function Stages.Won(run: Run, answer: { [string]: any }, before: Gave, after: Gave): { [string]: any }
	return {
		Won = true,
		Ground = run.Ground,
		Difficulty = run.Difficulty,
		Stage = run.Stage,
		From = run.From,
		Count = #((Stages.Of(run.Ground) or {}) :: { StagesConfig.Stage }),
		Seconds = answer.Run,
		Best = answer.RunBest,
		First = answer.First,
		Opened = answer.Opened or "",
		Then = answer.Then,
		Credits = math.max(0, after.Credits - before.Credits),
		Shards = math.max(0, after.Shards - before.Shards),
		Chests = math.max(0, after.Chests - before.Chests),
	}
end

-- The lead's name as a list shows it (its nickname, else its own), or nil with no save or no lead.
local function leadName(data: Profile.Data?): string?
	local owned = if data then data.Voidkin[data.Roles.Lead] else nil
	return if owned then Collection.Name(owned) else nil
end

-- The run's card on its lead's fall (Net StageDone, lost): where it fell, its lead's name, and the checkpoint the next
-- run on its difficulty begins at, the save's (the run's stretch when no save is loaded).
function Stages.Lost(run: Run, data: Profile.Data?): { [string]: any }
	return {
		Won = false,
		Ground = run.Ground,
		Difficulty = run.Difficulty,
		Stage = run.Stage,
		From = run.From,
		Count = #((Stages.Of(run.Ground) or {}) :: { StagesConfig.Stage }),
		Checkpoint = if data then Stages.Checkpoint(data, run.Ground, run.Difficulty) else run.Stage,
		Lead = leadName(data), -- the card names it: "Kirra fell" (research's lines, TR54)
	}
end

export type Published = { StageRun: string?, StageKills: number?, StageQuota: number?, StageLast: boolean? }

-- The run as the client reads it, the player's attributes: StageRun, its difficulty and stretch ("Normal 2", read back by
-- Stages.Parse), StageKills, StageQuota (its stretch's), StageLast. All nil with no run.
function Stages.Published(run: Run?): Published
	if run == nil then
		return {}
	end
	local rows = Stages.Of(run.Ground)
	local row = if rows then rows[run.Stage] else nil
	return {
		StageRun = `{run.Difficulty} {run.Stage}`,
		StageKills = run.Kills,
		StageQuota = if row then row.Quota else nil,
		StageLast = run.Last,
	}
end

-- A StageRun attribute read back: its difficulty and stretch, or nil for none or anything else.
function Stages.Parse(text: any): (string?, number?)
	if type(text) ~= "string" then
		return nil, nil
	end
	local difficulty, stage = string.match(text, "^(%a+) (%d+)$")
	if difficulty == nil then
		return nil, nil
	end
	return difficulty, tonumber(stage)
end

-- A run's name in the server's log and its analytics field (TR48): "Lantern Row Normal 2", or "Lantern Row Normal 1-4" for
-- one that began at an earlier stretch.
function Stages.Label(run: Run): string
	local stretch = if run.From == run.Stage then `{run.Stage}` else `{run.From}-{run.Stage}`
	return `{run.Ground} {run.Difficulty} {stretch}`
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
	return Stats.Power(Stats.Enemy(Stages.DefOn(last, difficulty), Stages.Level(last.Level, difficulty), nil, difficulty, stage)) -- lifted (TR49)
end

return Stages
