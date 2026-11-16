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

local Tower = {}

export type Foe = { Def: string, Level: number }
export type Reward = { Credits: number, Chest: string? }

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

-- The Voidkin a foe can be: those with a body of their own, in Id order.
function Tower.Pool(): { string }
	local pool = {}
	for _, row in Voidkin.List do
		if row.Model then
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

-- Floor `floor`'s foe in the run of `seed`.
function Tower.Foe(floor: number, seed: number): Foe
	local pool = Tower.Pool()
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

-- The chest a floor won may give: the elite's of the ground its foe's level stands in.
local function chestOf(floor: number): string?
	local ground = Grounds.List[Growth.GroundOf(Tower.Level(floor))]
	local row = if ground then ChestRows.Of(ground.Id, TowerConfig.Chest.Tier) else nil
	return if row then row.Id else nil
end

-- The chance a floor won gives a chest.
function Tower.ChestChance(floor: number): number
	local chest = TowerConfig.Chest
	return math.clamp(chest.Base + chest.PerFloor * floor, 0, chest.Most)
end

-- What winning floor `floor` adds to the ledger of a run whose record before it was `best`.
function Tower.Reward(floor: number, best: number, seed: number): Reward
	local credits = DropsConfig.CreditsPerKillPerG * Growth.G(Tower.Level(floor)) * TowerConfig.Credits.Share
	if floor > best then
		credits *= TowerConfig.Credits.Record
	end
	local chest = if draw(seed, floor, 2) < Tower.ChestChance(floor) then chestOf(floor) else nil
	return { Credits = math.floor(credits + 0.5), Chest = chest }
end

-- A new run in `data`, with `id` (Profile.NewId) and `seed`, started at `now`. Nil if a run is under way. Results not
-- yet seen are dropped: the player has seen them by stepping into the ring again.
function Tower.Start(data: Profile.Data, id: string, seed: number, now: number): Profile.TowerRun?
	local tower = data.Progress.Tower
	if tower.Run then
		return nil
	end
	local run: Profile.TowerRun = { Id = id, Started = now, Floor = 0, Best = tower.Best, Seed = seed, Credits = 0, Chests = {} }
	tower.Run = run
	tower.Results = nil
	return run
end

-- Floor `floor` won in run `id`: its reward into the ledger, the run's floor moved on. Nil (nothing changed) for another
-- run, or for a floor that isn't the next one, so a repeated claim is a no-op.
function Tower.Won(data: Profile.Data, id: string, floor: number): Reward?
	local run = data.Progress.Tower.Run
	if run == nil or run.Id ~= id or floor ~= run.Floor + 1 then
		return nil
	end
	local reward = Tower.Reward(floor, run.Best, run.Seed)
	run.Floor = floor
	run.Credits += reward.Credits
	if reward.Chest then
		run.Chests[reward.Chest] = (run.Chests[reward.Chest] or 0) + 1
	end
	return reward
end

-- Run `id` ended at its last floor won: the ledger granted once, the record raised, the results kept to be shown, the run
-- cleared. Nil (nothing changed) when no run of that id is under way.
function Tower.End(data: Profile.Data, id: string): Profile.TowerResults?
	local tower = data.Progress.Tower
	local run = tower.Run
	if run == nil or run.Id ~= id then
		return nil
	end
	data.Currency.Credits += run.Credits
	for chest, count in run.Chests do
		Chests.Grant(data, chest, count)
	end
	local results: Profile.TowerResults = {
		Id = run.Id,
		Floor = run.Floor,
		Best = tower.Best,
		Record = run.Floor > tower.Best,
		Credits = run.Credits,
		Chests = table.clone(run.Chests),
	}
	tower.Best = math.max(tower.Best, run.Floor)
	tower.Results = results
	tower.Run = nil
	return results
end

-- A run the save still holds at a join (a crash, a shutdown): ended at its last floor won. Nil when there's none.
function Tower.Recover(data: Profile.Data): Profile.TowerResults?
	local run = data.Progress.Tower.Run
	return if run then Tower.End(data, run.Id) else nil
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
