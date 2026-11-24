--!strict
-- Breaker (shared, pure): a base over time, a power plant (docs/design.md, "Shards and the Void Breaker", "The base",
-- "Power"; TR18): the Void Breaker's chambers and waiting line, the Training machine, the bays' generation and the
-- battery. The server keeps time as stamps, not loops: Advance moves a profile's base from its stamp to a time, online or
-- away, in one call (docs/engineering-plan.md, "The shape").
-- How it runs, between one event and the next (a shard finishing, the battery emptying or filling): Rules.Power splits
-- the generation among the machines working, by the base's setting (Auto or the player's shares), and says each one's
-- speed and what charges or drains the battery, past its cap into Credits at a poor rate; the Breaker's chambers work at
-- its speed and the one on the Training machine trains at its own; a finished shard moves to Ready, and an empty chamber
-- takes the line's first shard.
-- Who trains: while the player is in the game, Training.Trainee (the server's, LeadService); away, the lead. A worker
-- never trains. Away, the workers generate for Config.Base.Battery.AwayHours at most; then the machines run on the
-- battery, then at the floor. No Roblox API: it runs with Studio closed.
-- One query for the client: SelfOpening(ready, onPlot), the first broken shard that opens itself (a grade with Opens in
-- Config.Shards.Grades: the first session's starter and Watt's, TR24's fix 5) once its player stands on their plot.

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Profile = require(Shared.Data.Profile)
local Power = require(Shared.Rules.Power)
local Training = require(Shared.Rules.Training)
local Growth = require(Shared.Rules.Growth)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Condenser = require(Shared.Rules.Condenser)
local Goals = require(Shared.Rules.Goals)
local CondenserConfig = require(Shared.Config.Condenser)

export type Summary = {
	Finished: number, -- shards that moved to Ready
	Made: number, -- kWh the workers generated
	Overflow: number, -- kWh past the cap, sold
	Credits: number, -- whole Credits the overflow paid
	Trained: string?, -- who the Training machine trained, if anyone
	Levels: number, -- the levels it gained them
	Worked: number, -- the levels the bays' workers gained by the kWh they made (TR55)
	Stones: number, -- stones the Stone Condenser made into its tray (TR37)
	Converted: number, -- converts it finished
	Into: { [string]: number }, -- the stones those converts gave, by grade (TR56: Mid or High)
	Jewels: number, -- jewels it made into its tray (TR56)
	Steps: number, -- events stepped through, for tests
}

export type Rates = {
	Flow: Power.Flow, -- each machine's demand, draw and speed, and the battery's kW
	Generation: number, -- kW
	Demand: number, -- kW every working machine asks together
	NetKw: number, -- kW into the battery, negative while it covers demand
	Speed: number, -- the Breaker's: its share of full power times its level's speed (TR21), so 1 at full power at level 1
	Busy: boolean, -- a chamber is breaking
	Capacity: number, -- kWh the battery holds at most at the base's level (TR21)
	Trainee: string?, -- who's on the Training machine
	Condenser: number, -- the Stone Condenser's speed, 1 at full power or idle (TR37)
}

local EPSILON = 1e-6
local MAX_STEPS = 10000 -- a base has a handful of events an hour; this only stops a bug from hanging a server
local LEVEL_PAST = 1e-6 -- seconds a worker's level event lands past its level (nextLevel)

local Breaker = {}

-- A shard's seconds at full power and its kWh (Rules.Power.Cost). Nil for an unknown shard.
Breaker.Cost = Power.Cost

local function remaining(work: Profile.ShardWork): number
	local seconds = Power.Cost(work.Def)
	return math.max(0, (seconds or 0) - work.Done)
end

-- Seconds of work a shard has left at full power.
Breaker.Left = remaining

-- The Breaker's speed at full power, against level 1's (TR21): its chambers work this much faster.
local function pace(base: Profile.Base): number
	return BaseLevels.BreakerSpeed(base.Machines.Breaker or 1)
end

-- kWh the battery holds at most: its base's level's (TR21).
function Breaker.Capacity(base: Profile.Base): number
	return BaseLevels.Battery(base.Level)
end

-- How lit each cell of the battery's bank is, 0 to 1, in the order its seats fill (AR15, section 4): the charge's share
-- of the cap, one cell after another, so with two cells half a charge is the first lit and the second dark.
function Breaker.Cells(base: Profile.Base): { number }
	local count = BaseLevels.Cells(base.Level)
	local filled = math.clamp(base.Charge / Breaker.Capacity(base), 0, 1) * count
	local lit = table.create(count, 0)
	for index = 1, count do
		lit[index] = math.clamp(filled - (index - 1), 0, 1)
	end
	return lit
end

-- Who's on the Training machine over an advance: away, the lead; else Training.Trainee. Nil for nobody, a Voidkin that's
-- gone, or a worker (one role at a time).
function Breaker.Trainee(data: Profile.Data, away: boolean?): Profile.OwnedVoidkin?
	local id = if away then data.Roles.Lead else data.Training.Trainee
	local owned = if id ~= "" then data.Voidkin[id] else nil
	if owned == nil or Profile.RoleOf(data, owned.Id) == "Worker" then
		return nil
	end
	return owned
end

-- Empty chambers take the line's first shards, in order.
local function feed(base: Profile.Base)
	for _, chamber in base.Chambers do
		if chamber.Work == nil and #base.Line > 0 then
			chamber.Work = table.remove(base.Line, 1)
		end
	end
end

-- Moves every shard with no work left, in a chamber or in the line, to Ready, and feeds the chambers it frees.
-- Returns how many moved.
local function settle(base: Profile.Base): number
	local moved = 0
	for _, chamber in base.Chambers do
		local work = chamber.Work
		if work and remaining(work) <= EPSILON then
			work.Done = (Power.Cost(work.Def)) or work.Done
			table.insert(base.Ready, work)
			chamber.Work = nil
			moved += 1
		end
	end
	for index = #base.Line, 1, -1 do
		local work = base.Line[index]
		if remaining(work) <= EPSILON then
			work.Done = (Power.Cost(work.Def)) or work.Done
			table.remove(base.Line, index)
			table.insert(base.Ready, work)
			moved += 1
		end
	end
	feed(base)
	return moved
end

-- A shard broken at once (High voltage) moves to Ready now, and the chamber it frees takes the line's next.
function Breaker.Settle(data: Profile.Data): number
	local moved = settle(data.Base)
	Goals.Note(data, "ShardBroken", moved) -- today's goals count each shard the Breaker finishes (TR54)
	return moved
end

-- Every bay the base holds has a worker in it (today's "every bay a full hour", TR54).
local function allBays(base: Profile.Base): boolean
	for _, bay in base.Bays do
		if bay.Worker == "" then
			return false
		end
	end
	return #base.Bays > 0
end

local function flowNow(data: Profile.Data, generation: number, training: boolean): Power.Flow
	return Power.Flow(generation, Power.Demand(data, training), data.Base.Power, data.Base.Charge > EPSILON)
end

-- Seconds until the next event in this flow: a shard finishing, the battery emptying or filling, or the Stone
-- Condenser's next stone or convert.
local function nextEvent(base: Profile.Base, flow: Power.Flow): number
	local soonest = Condenser.Next(base, flow.Speed.Condenser or 1)
	local speed = (flow.Speed.Breaker or 1) * pace(base)
	if speed > 0 then
		for _, chamber in base.Chambers do
			local work = chamber.Work
			if work then
				soonest = math.min(soonest, remaining(work) / speed)
			end
		end
	end
	local perSecond = flow.Net / 3600
	local capacity = Breaker.Capacity(base)
	if perSecond < 0 and base.Charge > EPSILON then
		soonest = math.min(soonest, base.Charge / -perSecond)
	elseif perSecond > 0 and base.Charge < capacity - EPSILON then
		soonest = math.min(soonest, (capacity - base.Charge) / perSecond)
	end
	return soonest
end

-- The bays' workers at work for `dt`: each earns by the kWh it makes in its bay (TR55), its leftover seconds kept on the
-- bay. Returns the levels they gained.
local function work(data: Profile.Data, dt: number): number
	local levels = 0
	for _, bay in data.Base.Bays do
		local worker = if bay.Worker ~= "" then data.Voidkin[bay.Worker] else nil
		if worker then
			local share = BaseLevels.BayOutput(bay.Level or 1)
			local gained, banked = Training.Work(worker, dt + (bay.Banked or 0), function(level: number): number
				return Power.Output(worker, level) * share
			end)
			bay.Banked = if banked > 0 then banked else nil
			levels += gained
		end
	end
	if levels > 0 then
		Goals.Note(data, "LevelUp", levels)
	end
	return levels
end

-- Seconds until a worker's next level (TR55), where its kW and so the generation rise: an event, so many small advances
-- land where one large one does. A microsecond past the level, so rounding never leaves it a hair short.
local function nextLevel(data: Profile.Data): number
	local soonest = math.huge
	for _, bay in data.Base.Bays do
		local worker = if bay.Worker ~= "" then data.Voidkin[bay.Worker] else nil
		local need = if worker then Growth.XpToNext(worker.Level) else nil
		if worker and need then
			local rate = Training.WorkRate(Power.Output(worker) * BaseLevels.BayOutput(bay.Level or 1))
			if rate > 0 then
				soonest = math.min(soonest, math.max(0, (need - worker.Xp) / rate - (bay.Banked or 0)) + LEVEL_PAST)
			end
		end
	end
	return soonest
end

-- `making` while the bays generate: their workers' kW are read each event, since a worker's level raises them (TR55).
local function step(data: Profile.Data, seconds: number, making: boolean, trainee: Profile.OwnedVoidkin?, summary: Summary)
	local base = data.Base
	local left = seconds
	feed(base)
	while left > EPSILON and summary.Steps < MAX_STEPS do
		summary.Steps += 1
		local generation = if making then Power.Generation(data) else 0
		local flow = flowNow(data, generation, trainee ~= nil)
		local dt = math.min(left, nextEvent(base, flow), if generation > 0 then nextLevel(data) else math.huge)
		local speed = (flow.Speed.Breaker or 1) * pace(base)
		for _, chamber in base.Chambers do
			local work = chamber.Work
			if work then
				work.Done += speed * dt
			end
		end
		if trainee then
			local training = data.Training
			local gained, banked = Training.Gain(trainee, (flow.Speed.Training or 1) * dt + training.Banked)
			training.Banked = banked
			summary.Trained = trainee.Id
			summary.Levels += gained
			base.Power.Open = true -- a machine beside the Breaker has drawn power: the Power screen opens
			if (flow.Speed.Training or 1) > 0 then
				Goals.Note(data, "TrainSeconds", dt)
			end
			Goals.Note(data, "LevelUp", gained)
		end
		if generation > 0 then
			summary.Worked += work(data, dt)
			if allBays(base) then
				Goals.Note(data, "BaysSeconds", dt)
			end
		end
		if (flow.Demand.Condenser or 0) > 0 then
			local recipe = Condenser.Recipe(base) -- the convert under way, before the work can finish it
			local stones, converted, jewels = Condenser.Work(base, flow.Speed.Condenser or 1, dt)
			summary.Stones += stones
			summary.Converted += converted
			summary.Jewels += jewels
			if converted > 0 then
				summary.Into[recipe.To] = (summary.Into[recipe.To] or 0) + converted * recipe.Give
			end
			base.Power.Open = true
		end
		summary.Made += generation * dt / 3600
		local capacity = Breaker.Capacity(base)
		local charge = base.Charge + flow.Net * dt / 3600
		if charge > capacity then
			summary.Overflow += charge - capacity
			base.Spill += (charge - capacity) * BaseConfig.Battery.CreditsPerKwh
			charge = capacity
		end
		base.Charge = if charge < EPSILON then 0 else charge
		local moved = settle(base)
		summary.Finished += moved
		Goals.Note(data, "ShardBroken", moved)
		left -= dt
	end
	local whole = math.floor(base.Spill)
	if whole > 0 then
		base.Spill -= whole
		data.Currency.Credits += whole
		summary.Credits += whole
	end
end

-- The base's rates now, for a screen: what the bays generate, what each machine asks and gets, the Breaker's speed, the
-- battery's kW, whether a chamber is breaking and who trains. Nothing is written.
function Breaker.Rates(data: Profile.Data): Rates
	local generation = Power.Generation(data)
	local trainee = Breaker.Trainee(data)
	local flow = flowNow(data, generation, trainee ~= nil)
	local demand, busy = 0, false
	for _, name in Power.Machines do
		demand += flow.Demand[name] or 0
	end
	for _, chamber in data.Base.Chambers do
		busy = busy or chamber.Work ~= nil
	end
	return {
		Flow = flow,
		Generation = generation,
		Demand = demand,
		NetKw = flow.Net,
		Speed = (flow.Speed.Breaker or 1) * pace(data.Base),
		Busy = busy,
		Capacity = Breaker.Capacity(data.Base),
		Trainee = if trainee then trainee.Id else nil,
		Condenser = flow.Speed.Condenser or 1,
	}
end

-- An advance's work added to the record of the player's time away, when one is open (TR53; Rules.Return): `from` is
-- how many shards were ready before it, so the ones after broke in it.
local function remember(base: Profile.Base, summary: Summary, from: number)
	local away = base.Away
	if away == nil then
		return
	end
	away.Sold += summary.Overflow
	away.Credits += summary.Credits
	local function add(grade: string, count: number)
		if count > 0 then
			away.Stones[grade] = (away.Stones[grade] or 0) + count
		end
	end
	add(CondenserConfig.Makes, summary.Stones)
	for grade, count in summary.Into do
		add(grade, count)
	end
	if summary.Trained and summary.Levels > 0 then
		away.Trained[summary.Trained] = (away.Trained[summary.Trained] or 0) + summary.Levels
	end
	for index = from + 1, #base.Ready do
		table.insert(away.Shards, base.Ready[index].Def)
	end
end

-- Moves the base from its stamp to `now`. `away` is true when the player was offline for the whole gap (a rejoin): the
-- workers' generation stops after Config.Base.Battery.AwayHours and the lead trains. A base never advanced takes `now`
-- as its stamp. A `now` before the stamp (a clock step back) changes nothing.
function Breaker.Advance(data: Profile.Data, now: number, away: boolean?): Summary
	local summary: Summary = { Finished = 0, Made = 0, Overflow = 0, Credits = 0, Levels = 0, Worked = 0, Stones = 0, Converted = 0, Into = {}, Jewels = 0, Steps = 0 }
	local base = data.Base
	if base.Stamp == 0 then
		base.Stamp = now
		feed(base)
		return summary
	end
	local gap = now - base.Stamp
	if gap <= 0 then
		return summary
	end
	local trainee = Breaker.Trainee(data, away)
	local making = if away then math.min(gap, BaseConfig.Battery.AwayHours * 3600) else gap
	local ready = #base.Ready
	step(data, making, true, trainee, summary)
	if gap > making then
		step(data, gap - making, false, trainee, summary)
	end
	remember(base, summary, ready)
	base.Stamp = now
	return summary
end

-- Seconds from the stamp until the next shard finishes, the battery empties or fills, or the Stone Condenser makes a
-- stone or finishes a convert; nil when nothing is breaking and the Condenser rests. The server wakes a base then, so
-- Ready and the tray fill while the player watches.
function Breaker.NextEvent(data: Profile.Data): number?
	local base = data.Base
	local busy = Condenser.Working(base)
	for _, chamber in base.Chambers do
		busy = busy or chamber.Work ~= nil
	end
	if not busy and #base.Line == 0 then
		return nil
	end
	local soonest = nextEvent(base, flowNow(data, Power.Generation(data), Breaker.Trainee(data) ~= nil))
	return if soonest == math.huge then nil else soonest
end

-- Puts a shard into the waiting line, shortest work first, after any of equal length, then feeds an empty chamber.
function Breaker.AddToLine(data: Profile.Data, work: Profile.ShardWork)
	local base = data.Base
	local length = remaining(work)
	local at = #base.Line + 1
	for index, waiting in base.Line do
		if remaining(waiting) > length then
			at = index
			break
		end
	end
	table.insert(base.Line, at, work)
	feed(base)
end

-- Takes the shard out of a chamber, keeping its work, to the back of the line; the chamber takes the line's first.
-- False when the chamber is empty or doesn't exist.
function Breaker.TakeOut(data: Profile.Data, chamberIndex: number): boolean
	local base = data.Base
	local chamber = base.Chambers[chamberIndex]
	if not chamber or not chamber.Work then
		return false
	end
	local work = chamber.Work :: Profile.ShardWork
	chamber.Work = nil
	feed(base)
	table.insert(base.Line, work)
	feed(base) -- when the line was empty, the shard goes straight back in
	return true
end

-- The index in `ready` (Base.Ready, in the save's order) of the first broken shard that opens itself, while its player
-- stands on their plot, or nil: the client asks Open for it (the server checks the ask as any other).
function Breaker.SelfOpening(ready: { Profile.ShardWork }, onPlot: boolean): number?
	if not onPlot then
		return nil
	end
	for index, work in ready do
		local shard = Shards.ById[work.Def]
		local grade = shard and ShardConfig.Grades[shard.Grade]
		if grade and grade.Opens == true then
			return index
		end
	end
	return nil
end

return Breaker
