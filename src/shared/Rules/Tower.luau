--!strict
-- The Tower's rules (shared, pure; TR29; docs/design.md, "The Tower"; docs/engineering-plan.md, "The Tower"): each
-- floor's foe and reward from the run's seed, the heal cap, and the run's ledger in the save (Progress.Tower). Every
-- write is one transaction the server runs inside DataService.Change: a floor won adds its reward to the run's ledger,
-- and the end grants the ledger once, raises the record, keeps the results and clears the run. A repeated or stale
-- request (another run's id, a floor not next) changes nothing. No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local TowerConfig = require(Shared.Config.Tower)
local DropsConfig = require(Shared.Config.Drops)
local GrowthConfig = require(Shared.Config.Growth)
local Voidkin = require(Shared.Definitions.Voidkin)
local Grounds = require(Shared.Definitions.Grounds)
local ChestRows = require(Shared.Definitions.Chests)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Chests = require(Shared.Rules.Chests)
local Drops = require(Shared.Rules.Drops)
local Goals = require(Shared.Rules.Goals)

local Tower = {}

export type Foe = { Def: string, Level: number }
export type Reward = { Credits: number, Chest: string?, Stone: string, Stones: number } -- Stone, the grade ("" for none)

-- A draw in [0, 1) from the run's seed, the floor and what it's for: the same three, the same draw.
local function draw(seed: number, floor: number, salt: number): number
	local x = bit32.bxor(bit32.band(seed, 0x7fffffff), floor * 40503 + salt * 2654435) + 0x6d2b79f5
	for _ = 1, 3 do
		x = bit32.bxor(x, bit32.lshift(x, 13))
		x = bit32.bxor(x, bit32.rshift(x, 17))
		x = bit32.bxor(x, bit32.lshift(x, 5))
	end
	return bit32.band(x, 0xffffffff) / 4294967296
end
Tower.Draw = draw

-- The Voidkin a foe can be: those with a body and moves of their own, in Id order. A body installed ahead of its clips
-- (Definitions.Voidkin's ClipsDue) waits for them: it would fight on the stand-in's kit.
function Tower.Pool(): { string }
	local pool = {}
	for _, row in Voidkin.List do
		if row.Model and row.Kit then
			table.insert(pool, row.Id)
		end
	end
	table.sort(pool)
	return pool
end

-- Floor `floor`'s foe's level: 1 + (floor - 1) x LevelPerFloor, rounded, within Growth's levels.
function Tower.Level(floor: number): number
	return math.clamp(math.floor(1 + (math.max(floor, 1) - 1) * TowerConfig.LevelPerFloor + 0.5), 1, GrowthConfig.MaxLevel)
end

-- The week the moment `now` (Unix seconds) falls in: weeks begin Monday 00:00 UTC (Config.Tower.Week; TR46).
function Tower.Week(now: number): number
	return math.floor((now - TowerConfig.Week.Start) / TowerConfig.Week.Length)
end

-- The foes' seed for week `week`, the same on every server: a run draws its foes from the week it started in, and its
-- chests from its own seed (Tower.Reward). A foe is harmless to know ahead, so it's unsalted.
function Tower.WeekSeed(week: number): number
	return bit32.band((week * 0x9E3779B1) % 4294967296 + 0x2545F491, 0x7fffffff)
end

-- The week's board (TR46). A climb's score orders a week's climbs by floor, then the earlier first: floor x the week's
-- Length, plus the seconds still to come in its week at `at` (a run ended past its week's end counts as at its last
-- second). Whole, and under 2^53 to floor 10^9, so an OrderedDataStore holds it exactly.
function Tower.Score(floor: number, week: number, at: number): number
	local length = TowerConfig.Week.Length
	local into = math.clamp(math.floor(at) - (TowerConfig.Week.Start + week * length), 0, length - 1)
	return math.max(math.floor(floor), 0) * length + (length - 1 - into)
end

-- The floor a score stands for.
function Tower.ScoreFloor(score: number): number
	return math.floor(score / TowerConfig.Week.Length)
end

-- The account's climb this week, at `now`: nil before its first floor won in a run started this week.
function Tower.Climb(data: Profile.Data, now: number): Profile.TowerWeek?
	local held = data.Progress.Tower.Week
	return if held and held.Week == Tower.Week(now) and held.Floor > 0 then held else nil
end

export type Entry = { Id: number, Score: number } -- one board row as stored: a UserId and its score
export type Row = { Rank: number?, Id: number, Floor: number } -- as shown; a rank nil past a full page

-- The board as player `me` reads it: `top`, the stored page best first (Config.Tower.Board.Page long when full), with
-- their own `mine` score (their save's, which may be newer than the page) set in its place. Its first `shown` rows, and
-- their own row: nil without a climb, its rank nil when it falls under a full page. Equal scores go by UserId.
function Tower.Board(top: { Entry }, me: number, mine: number?, shown: number): ({ Row }, Row?)
	local page = TowerConfig.Board.Page
	local list: { Entry } = {}
	for _, entry in top do
		if entry.Id ~= me then
			table.insert(list, entry)
		end
	end
	if mine then
		table.insert(list, { Id = me, Score = mine })
	end
	table.sort(list, function(a: Entry, b: Entry): boolean
		if a.Score ~= b.Score then
			return a.Score > b.Score
		end
		return a.Id < b.Id
	end)
	local rows: { Row } = {}
	local own: Row? = nil
	for index, entry in list do
		if index > page then
			break
		end
		local row: Row = { Rank = index, Id = entry.Id, Floor = Tower.ScoreFloor(entry.Score) }
		if index <= shown then
			table.insert(rows, row)
		end
		if entry.Id == me then
			own = row
		end
	end
	if mine and own == nil then
		-- Only under a full page: where it stands past the page isn't read.
		local under: Row = { Rank = nil, Id = me, Floor = Tower.ScoreFloor(mine) }
		own = under
	end
	return rows, own
end

-- The card's line for the player's own row (research's words, TR46).
function Tower.WeekLine(own: Row?): string
	if own == nil then
		return "This week: no climb yet"
	end
	local rank = if own.Rank then `#{own.Rank}` else `#{TowerConfig.Board.Page}+`
	return `This week: {rank} · floor {own.Floor}`
end

-- Floor `floor`'s foe for the foes' seed `seed` (a run's week's, Tower.WeekSeed): the opening's (Config.Tower.Opening)
-- on its floors, the same for every run, while that Voidkin is in the pool; from the seed past it.
function Tower.Foe(floor: number, seed: number): Foe
	local pool = Tower.Pool()
	local opening = TowerConfig.Opening[floor]
	if opening and table.find(pool, opening) then
		return { Def = opening, Level = Tower.Level(floor) }
	end
	local index = math.min(#pool, 1 + math.floor(draw(seed, floor, 1) * #pool))
	return { Def = pool[index], Level = Tower.Level(floor) }
end

-- The foe's stat block: its own figure at its level with no Regalia, lifted to the seeds' build, its health then cut to
-- Config's share.
function Tower.Block(foe: Foe): Stats.Block
	local owned: Profile.OwnedVoidkin = {
		Id = "tower",
		Def = foe.Def,
		Level = foe.Level,
		Xp = 0,
		Stars = 0,
		Copies = 0,
		Nickname = "",
		Preset = 0,
		Favourite = false,
		Locked = false,
		Born = 0,
	}
	local block = Stats.Resolve(owned, nil, nil)
	for stat, lift in TowerConfig.Lift do
		local value = (block :: any)[stat]
		if type(value) == "number" then
			(block :: any)[stat] = value * lift
		end
	end
	block.Health *= TowerConfig.Health
	return block
end

-- The ring's middle in its plot's frame, (across, inward from the plot's middle), on a plot `across` x `deep` with
-- `behind` of path and a lot `tower` deep, its crossing on `side` (1 or -1): the lot's crossing end, a square of it.
function Tower.RingSpot(across: number, deep: number, behind: number, tower: number, side: number): (number, number)
	return side * (across / 2 - tower / 2), deep / 2 + behind + tower / 2
end

-- Where a platform over that ring reaches, out to the line a run is left at (its edge, then Out.Side), in the same
-- frame and the same studs: Side, across from the plot's middle on the ring's side; Near, the least inward (toward the
-- plot); Far, the most. A platform wider than its lot overhangs it in the air, never the plot's own yard or a
-- neighbour's half of the gap between them (the logic cases), and the base's ground is laid on past Far.
function Tower.Reach(across: number, deep: number, behind: number, tower: number): { Side: number, Near: number, Far: number }
	local x, z = Tower.RingSpot(across, deep, behind, tower, 1)
	local out = TowerConfig.Platform.Radius + TowerConfig.Out.Side
	return { Side = x + out, Near = z - out, Far = z + out }
end

-- Whether a foe of `foeLevel` falls to the lead's first hit (Config.Tower.Fast).
function Tower.Fast(leadLevel: number, foeLevel: number): boolean
	return leadLevel - foeLevel >= TowerConfig.Fast.Gap
end

-- The seconds from floor won to the next foe, a fast one's quicker.
function Tower.Rise(fast: boolean): number
	return if fast then TowerConfig.Fast.Rise else TowerConfig.Rise
end

-- The most a lead of `maxHealth` heals in one floor.
function Tower.HealCap(maxHealth: number): number
	return TowerConfig.HealCap * maxHealth
end

-- A heal from `before` to `wanted` with `room` left under the cap: the health it reaches and the room left. A fall in
-- health (a hit, a rescale) is never cut.
function Tower.Capped(before: number, wanted: number, room: number): (number, number)
	local gain = wanted - before
	if gain <= 0 then
		return wanted, room
	end
	local taken = math.clamp(gain, 0, math.max(room, 0))
	return before + taken, room - taken
end

-- The chest a hard floor won may give: the Tower's own, of the ground its foe's level stands in.
local function chestOf(floor: number): string?
	local ground = Grounds.List[Growth.GroundOf(Tower.Level(floor))]
	local row = if ground then ChestRows.Of(ground.Id, ChestRows.Tower) else nil
	return if row then row.Id else nil
end

-- The chance a floor won gives a chest.
function Tower.ChestChance(floor: number): number
	local chest = TowerConfig.Chest
	return math.clamp(chest.Base + chest.PerFloor * floor, 0, chest.Most)
end

-- What winning floor `floor` adds to the ledger of a run whose record before it was `best`: nothing when it fell `fast`
-- (Tower.Fast, as it was fought), since only hard floors pay. The one exception: floor Config.Tower.Chest.First's
-- chest is sure the first time the account wins it (`best` under it), fast or hard, so a lead that outgrew the opening
-- before its first climb still gets it. Once: the record never falls back under that floor.
function Tower.Reward(floor: number, best: number, seed: number, fast: boolean?): Reward
	local sure = floor == TowerConfig.Chest.First and best < floor
	if fast then
		return { Credits = 0, Chest = if sure then chestOf(floor) else nil, Stone = "", Stones = 0 }
	end
	local credits = DropsConfig.CreditsPerKillPerG * Growth.G(Tower.Level(floor)) * TowerConfig.Credits.Share
	if floor > best then
		credits *= TowerConfig.Credits.Record
	end
	local chest = if sure or draw(seed, floor, 2) < Tower.ChestChance(floor) then chestOf(floor) else nil
	local ground = Grounds.List[Growth.GroundOf(Tower.Level(floor))]
	local stones = if ground then Drops.Stones("Ordinary", draw(seed, floor, 3), TowerConfig.Stones) else 0
	return {
		Credits = math.floor(credits + 0.5),
		Chest = chest,
		Stone = if stones > 0 and ground then Drops.StoneGrade(ground.Id) else "",
		Stones = stones,
	}
end

-- A new run in `data`, with `id` (Profile.NewId) and `seed`, started at `now`. Nil if a run is under way. Results not
-- yet seen are dropped: the player has seen them by stepping into the ring again.
function Tower.Start(data: Profile.Data, id: string, seed: number, now: number): Profile.TowerRun?
	local tower = data.Progress.Tower
	if tower.Run then
		return nil
	end
	local run: Profile.TowerRun = { Id = id, Started = now, Floor = 0, Best = tower.Best, Seed = seed, Credits = 0, Chests = {}, Stones = {} }
	tower.Run = run
	tower.Results = nil
	return run
end

-- Floor `floor` won in run `id`, `fast` or hard as it was fought: its reward into the ledger, the run's floor moved on.
-- Nil (nothing changed) for another run, or for a floor that isn't the next one, so a repeated claim is a no-op.
function Tower.Won(data: Profile.Data, id: string, floor: number, fast: boolean?): Reward?
	local run = data.Progress.Tower.Run
	if run == nil or run.Id ~= id or floor ~= run.Floor + 1 then
		return nil
	end
	local reward = Tower.Reward(floor, run.Best, run.Seed, fast)
	run.Floor = floor
	Goals.Note(data, "TowerFloor") -- today's "win three Tower floors" (TR54)
	run.Credits += reward.Credits
	if reward.Chest then
		run.Chests[reward.Chest] = (run.Chests[reward.Chest] or 0) + 1
	end
	if reward.Stones > 0 then
		local stones = run.Stones or {}
		stones[reward.Stone] = (stones[reward.Stone] or 0) + reward.Stones
		run.Stones = stones
	end
	return reward
end

-- Run `id` ended at its last floor won, at `now`: the ledger granted once, the record raised, the week's climb raised for
-- the week the run started in (a later week's replaces an earlier's), the results kept to be shown, the run cleared. Nil
-- (nothing changed) when no run of that id is under way.
function Tower.End(data: Profile.Data, id: string, now: number): Profile.TowerResults?
	local tower = data.Progress.Tower
	local run = tower.Run
	if run == nil or run.Id ~= id then
		return nil
	end
	data.Currency.Credits += run.Credits
	for chest, count in run.Chests do
		Chests.Grant(data, chest, count)
	end
	for grade, count in run.Stones or {} do
		data.Bag.Stones[grade] = (data.Bag.Stones[grade] or 0) + count
	end
	local results: Profile.TowerResults = {
		Id = run.Id,
		Floor = run.Floor,
		Best = tower.Best,
		Record = run.Floor > tower.Best,
		Credits = run.Credits,
		Chests = table.clone(run.Chests),
		Stones = table.clone(run.Stones or {}),
	}
	tower.Best = math.max(tower.Best, run.Floor)
	local week = Tower.Week(run.Started)
	local held = tower.Week
	if run.Floor > 0 and (held == nil or held.Week < week or (held.Week == week and run.Floor > held.Floor)) then
		tower.Week = { Week = week, Floor = run.Floor, Score = Tower.Score(run.Floor, week, now) }
	end
	tower.Results = results
	tower.Run = nil
	return results
end

-- A run the save still holds at a join (a crash, a shutdown): ended at its last floor won, at `now`. Nil when there's none.
function Tower.Recover(data: Profile.Data, now: number): Profile.TowerResults?
	local run = data.Progress.Tower.Run
	return if run then Tower.End(data, run.Id, now) else nil
end

-- The results of run `id` shown: cleared. False when they aren't the ones held.
function Tower.Seen(data: Profile.Data, id: string): boolean
	local tower = data.Progress.Tower
	if tower.Results == nil or tower.Results.Id ~= id then
		return false
	end
	tower.Results = nil
	return true
end

return Tower
