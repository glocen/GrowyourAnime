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
local BaseLevels = require(Shared.Rules.BaseLevels)

export type Summary = {
	Finished: number, -- shards that moved to Ready
	Made: number, -- kWh the workers generated
	Overflow: number, -- kWh past the cap, sold
	Credits: number, -- whole Credits the overflow paid
	Trained: string?, -- who the Training machine trained, if anyone
	Levels: number, -- the levels it gained them
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
}

local EPSILON = 1e-6
local MAX_STEPS = 10000 -- a base has a handful of events an hour; this only stops a bug from hanging a server

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
	return settle(data.Base)
end

local function flowNow(data: Profile.Data, generation: number, training: boolean): Power.Flow
	return Power.Flow(generation, Power.Demand(data, training), data.Base.Power, data.Base.Charge > EPSILON)
end

-- Seconds until the next event in this flow: a shard finishing, the battery emptying, or the battery filling.
local function nextEvent(base: Profile.Base, flow: Power.Flow): number
	local soonest = math.huge
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

local function step(data: Profile.Data, seconds: number, generation: number, trainee: Profile.OwnedVoidkin?, summary: Summary)
	local base = data.Base
	local left = seconds
	feed(base)
	while left > EPSILON and summary.Steps < MAX_STEPS do
		summary.Steps += 1
		local flow = flowNow(data, generation, trainee ~= nil)
		local dt = math.min(left, nextEvent(base, flow))
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
		summary.Finished += settle(base)
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
	}
end

-- Moves the base from its stamp to `now`. `away` is true when the player was offline for the whole gap (a rejoin): the
-- workers' generation stops after Config.Base.Battery.AwayHours and the lead trains. A base never advanced takes `now`
-- as its stamp. A `now` before the stamp (a clock step back) changes nothing.
function Breaker.Advance(data: Profile.Data, now: number, away: boolean?): Summary
	local summary: Summary = { Finished = 0, Made = 0, Overflow = 0, Credits = 0, Levels = 0, Steps = 0 }
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
	local generation = Power.Generation(data)
	local trainee = Breaker.Trainee(data, away)
	local making = if away then math.min(gap, BaseConfig.Battery.AwayHours * 3600) else gap
	step(data, making, generation, trainee, summary)
	if gap > making then
		step(data, gap - making, 0, trainee, summary)
	end
	base.Stamp = now
	return summary
end

-- Seconds from the stamp until the next shard finishes or the battery empties or fills, or nil when nothing is breaking.
-- The server wakes a base then, so Ready fills while the player watches.
function Breaker.NextEvent(data: Profile.Data): number?
	local base = data.Base
	local busy = false
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
