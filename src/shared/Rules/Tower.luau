--!strict
-- The Tower's rules (shared, pure; TR29; docs/design.md, "The Tower"; docs/engineering-plan.md, "The Tower"): each
-- floor's foe and reward from the run's seed, the heal cap, and the run's ledger in the save (Progress.Tower). Every
-- write is one transaction the server runs inside DataService.Change: a floor won adds its reward to the run's ledger,
-- and the end grants the ledger once, raises the record, keeps the results and clears the run. A repeated or stale
-- request (another run's id, a floor not next) changes nothing. And the room's (AR56): where each copy stands, the
-- gate's door on the lot, the line a run is left at, the beat of its steps. No Roblox API beyond its data types: it
-- runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local TowerConfig = require(Shared.Config.Tower)
local RoomPlan = require(Shared.Config.Kits.TowerRoom.Plan) :: any
local DropsConfig = require(Shared.Config.Drops)
local ChestsConfig = require(Shared.Config.Chests)
local GrowthConfig = require(Shared.Config.Growth)
local Voidkin = require(Shared.Definitions.Voidkin)
local Grounds = require(Shared.Definitions.Grounds)
local ChestRows = require(Shared.Definitions.Chests)
local Growth = require(Shared.Rules.Growth)
local Stats = require(Shared.Rules.Stats)
local Chests = require(Shared.Rules.Chests)
local Drops = require(Shared.Rules.Drops)
local Goals = require(Shared.Rules.Goals)
local Boards = require(Shared.Rules.Boards)

local Tower = {}

export type Foe = { Def: string, Level: number }
-- Stone, the grade ("" for none); Case, the Emblem Case of a tenth floor's first clear (TR56)
export type Reward = { Credits: number, Chest: string?, Stone: string, Stones: number, Case: string? }

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
	local ranked, mineRanked = Boards.Rank(top, me, mine, shown, TowerConfig.Board.Page) -- the boards' one ranking (TR58)
	local rows: { Row } = {}
	for _, row in ranked do
		table.insert(rows, { Rank = row.Rank, Id = row.Id, Floor = Tower.ScoreFloor(row.Score) })
	end
	local own: Row? = if mineRanked then { Rank = mineRanked.Rank, Id = me, Floor = Tower.ScoreFloor(mineRanked.Score) } else nil
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
-- The gate stands there (AR56).
function Tower.RingSpot(across: number, deep: number, behind: number, tower: number, side: number): (number, number)
	return side * (across / 2 - tower / 2), deep / 2 + behind + tower / 2
end

-- The lot's frame from its ring marker's (whose look is toward its plot): the plan's lot frame, its +Z toward the base,
-- its look out from it.
function Tower.Lot(marker: CFrame): CFrame
	local look = marker.LookVector
	local out = Vector3.new(-look.X, 0, -look.Z)
	out = if out.Magnitude > 1e-3 then out.Unit else Vector3.zAxis
	return CFrame.lookAt(marker.Position, marker.Position + out)
end

-- The room (AR56): copy `slot`'s floor middle in the world, in rows of Config.Tower.Room's Across.
function Tower.RoomAt(slot: number): Vector3
	local room = TowerConfig.Room
	local index = math.max(1, math.floor(slot)) - 1
	local column, row = index % room.Across, index // room.Across
	return room.Origin + Vector3.new((column - (room.Across - 1) / 2) * room.Spacing, 0, -row * room.Spacing)
end

-- The lowest slot no copy holds.
function Tower.FreeSlot(taken: { [number]: any }): number
	local slot = 1
	while taken[slot] ~= nil do
		slot += 1
	end
	return slot
end

-- The door of light's place on the lot, from the plan: (across, along toward the base).
local function door(): (number, number)
	for _, placement in RoomPlan.lot.placements do
		if placement.piece == "GateVeil" then
			return placement.at[1], placement.at[3]
		end
	end
	return 0, 0
end
local DOOR_X, DOOR_Z = door()

-- Whether a point in the lot's frame (x across, y over its ground, z toward the base) stands in the gate's door: its box
-- (Config.Tower.Gate), grown by `grow` studs every way.
function Tower.InGate(x: number, y: number, z: number, grow: number?): boolean
	local gate, more = TowerConfig.Gate, grow or 0
	return math.abs(x - DOOR_X) <= gate.Half + more and math.abs(z - DOOR_Z) <= gate.Deep + more and y >= -1 - more and y <= gate.Up + more
end

-- The door's middle in the lot's frame: (across, along toward the base), on its ground.
function Tower.Door(): (number, number)
	return DOOR_X, DOOR_Z
end

-- Where a run sets the avatar down at its end, in the lot's frame: Back studs in front of the door, toward the base.
function Tower.Before(): (number, number)
	return DOOR_X, DOOR_Z + TowerConfig.Back
end

-- Whether an avatar's feet at (dx, dy, dz) from its room's floor middle have left the room: past its step ring's edge by
-- Out.Side, or Out.Below under the floor.
function Tower.Left(dx: number, dy: number, dz: number): boolean
	local edge = RoomPlan.floor.stepRing[2] + TowerConfig.Out.Side
	return dx * dx + dz * dz > edge * edge or dy < -TowerConfig.Out.Below
end

export type Step = { Tag: string, From: number, To: number, Rest: number }
export type Beat = { Steps: { Step }, Turn: { number }, Climb: { number }, Leap: { number }, Sink: { number } }

-- A floor's beat (the plan's, seconds from its start) for a rise of `rise` seconds: the foe's steps wait Rest studs under
-- their places and rise over [From, To], the farthest first, each Stagger after the last; the slab's turn keeps its own
-- seconds, the rest is scaled to the rise.
function Tower.Beat(rise: number): Beat
	local beat = RoomPlan.beat
	local scale = rise / TowerConfig.Rise
	local far: { { Tag: string, Off: number } } = {}
	for _, placement in RoomPlan.placements do
		if beat.stepRest[placement.tag] ~= nil then
			table.insert(far, { Tag = placement.tag, Off = math.abs(placement.at[3]) })
		end
	end
	table.sort(far, function(a: { Tag: string, Off: number }, b: { Tag: string, Off: number }): boolean
		return a.Off > b.Off
	end)
	local steps: { Step } = {}
	for index, step in far do
		local from = (beat.firstStep + (index - 1) * beat.stepStagger) * scale
		table.insert(steps, { Tag = step.Tag, From = from, To = from + beat.stepRise * scale, Rest = beat.stepRest[step.Tag] })
	end
	local function scaled(span: { number }): { number }
		return { span[1] * scale, span[2] * scale }
	end
	return {
		Steps = steps,
		Turn = { beat.slabTurn[1], math.min(beat.slabTurn[2], rise) },
		Climb = scaled(beat.climb),
		-- A fast floor keeps the leap's length (the plan's note), ending where the scaled one would.
		Leap = if scale < 1 then { math.max(0, beat.leap[2] * scale - (beat.leap[2] - beat.leap[1])), beat.leap[2] * scale } else scaled(beat.leap),
		Sink = scaled(beat.sink),
	}
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

-- The Emblem Case the account's first clear of floor `floor` gives, its record before it `best`, or nil: one sure at each
-- Every-th floor, its rarity rising with the floor (Config.Chests.Case.Tower; TR56). Floors are won in order, so a
-- floor over the record is its first clear, fast or hard.
function Tower.Case(floor: number, best: number): string?
	local tower = ChestsConfig.Case.Tower
	if floor <= best or floor % tower.Every ~= 0 then
		return nil
	end
	local step = floor // tower.Every
	local rarity = tower.By[step] or (if floor % tower.TopEvery == 0 then tower.Top else tower.Past)
	local row = ChestRows.TowerCase(rarity)
	return if row then row.Id else nil
end

-- What winning floor `floor` adds to the ledger of a run whose record before it was `best`: nothing when it fell `fast`
-- (Tower.Fast, as it was fought), since only hard floors pay. The one exception: floor Config.Tower.Chest.First's
-- chest is sure the first time the account wins it (`best` under it), fast or hard, so a lead that outgrew the opening
-- before its first climb still gets it. Once: the record never falls back under that floor.
function Tower.Reward(floor: number, best: number, seed: number, fast: boolean?): Reward
	local sure = floor == TowerConfig.Chest.First and best < floor
	local case = Tower.Case(floor, best)
	if fast then
		return { Credits = 0, Chest = if sure then chestOf(floor) else nil, Stone = "", Stones = 0, Case = case }
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
		Case = case,
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
	if reward.Case then
		run.Chests[reward.Case] = (run.Chests[reward.Case] or 0) + 1
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
