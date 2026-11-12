--!strict
-- Breaker (shared, pure): a base over time: the Void Breaker's chambers and waiting line, the bays' electricity and the
-- battery (docs/design.md, "Shards and the Void Breaker", "The base"). The server keeps time as stamps, not loops: Advance
-- moves a profile's base from its stamp to a time, online or away, in one call (docs/engineering-plan.md, "The shape").
-- How it runs, between one event and the next (a shard finishing, the battery emptying or filling):
--   each shard in a chamber draws its electricity evenly over its work; the workers' electricity goes first to the
--   chambers, the rest to the battery, past its cap into Credits at a poor rate;
--   while the battery holds charge the Breaker runs at full speed; empty, it runs at what the workers make against what
--   it asks, never below Config.Base.Breaker.MinSpeed, and never loses a shard;
--   a finished shard moves to Ready, and an empty chamber takes the line's first shard.
-- Away, the workers make electricity for Config.Base.Battery.AwayHours at most; then the Breaker runs on the battery.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local Profile = require(Shared.Data.Profile)

export type Summary = {
	Finished: number, -- shards that moved to Ready
	Made: number, -- electricity the workers made
	Overflow: number, -- electricity past the cap, sold
	Credits: number, -- whole Credits the overflow paid
	Steps: number, -- events stepped through, for tests
}

local EPSILON = 1e-6
local MAX_STEPS = 10000 -- a base has a handful of events an hour; this only stops a bug from hanging a server

local Breaker = {}

-- A shard's work: its seconds at full power and its electricity, the ground's factor applied. Nil for an unknown shard.
function Breaker.Cost(shardId: string): (number?, number?)
	local shard = Shards.ById[shardId]
	local grade = shard and ShardConfig.Grades[shard.Grade]
	if not shard or not grade then
		return nil, nil
	end
	return grade.BreakSeconds, grade.Energy * (ShardConfig.RegionFactor[shard.Ground] or 1)
end

-- The electricity one Voidkin makes at work, per second: 0 for a definition that's gone.
function Breaker.Output(worker: Profile.OwnedVoidkin): number
	local bays = BaseConfig.Bays
	local row = Voidkin.ById[worker.Def]
	if row == nil then
		return 0
	end
	return row.Aptitude * bays.PerMinutePerAptitude * (1 + bays.PerLevel * (worker.Level - 1)) / 60
end

-- The electricity the bays' workers make, per second.
function Breaker.Production(data: Profile.Data): number
	local perSecond = 0
	for _, bay in data.Base.Bays do
		local worker = if bay.Worker ~= "" then data.Voidkin[bay.Worker] else nil
		if worker then
			perSecond += Breaker.Output(worker)
		end
	end
	return perSecond
end

local function remaining(work: Profile.ShardWork): number
	local seconds = Breaker.Cost(work.Def)
	return math.max(0, (seconds or 0) - work.Done)
end

-- Seconds of work a shard has left at full power.
Breaker.Left = remaining

-- Empty chambers take the line's first shards, in order.
local function feed(base: Profile.Base)
	for _, chamber in base.Chambers do
		if chamber.Work == nil and #base.Line > 0 then
			chamber.Work = table.remove(base.Line, 1)
		end
	end
end

-- The Breaker's speed and the battery's rate of change, now.
local function regime(base: Profile.Base, production: number): (number, number, boolean)
	local demand = 0
	local busy = false
	for _, chamber in base.Chambers do
		local work = chamber.Work
		if work then
			busy = true
			local seconds, energy = Breaker.Cost(work.Def)
			if seconds and energy and seconds > 0 then
				demand += energy / seconds
			end
		end
	end
	if base.Battery > EPSILON or production >= demand then
		return 1, production - demand, busy
	end
	-- Empty and short: everything made is used at once, and the floor's share of the work costs nothing.
	return math.max(BaseConfig.Breaker.MinSpeed, production / demand), 0, busy
end

-- Seconds until the next event at this speed and rate: a shard finishing, the battery emptying, or the battery filling.
local function nextEvent(base: Profile.Base, speed: number, net: number): number
	local soonest = math.huge
	for _, chamber in base.Chambers do
		local work = chamber.Work
		if work then
			soonest = math.min(soonest, remaining(work) / speed)
		end
	end
	local capacity = BaseConfig.Battery.Capacity
	if net < 0 and base.Battery > EPSILON then
		soonest = math.min(soonest, base.Battery / -net)
	elseif net > 0 and base.Battery < capacity - EPSILON then
		soonest = math.min(soonest, (capacity - base.Battery) / net)
	end
	return soonest
end

local function step(data: Profile.Data, seconds: number, production: number, summary: Summary)
	local base = data.Base
	local left = seconds
	feed(base)
	while left > EPSILON and summary.Steps < MAX_STEPS do
		summary.Steps += 1
		local speed, net = regime(base, production)
		local dt = math.min(left, nextEvent(base, speed, net))
		for _, chamber in base.Chambers do
			local work = chamber.Work
			if work then
				work.Done += speed * dt
			end
		end
		summary.Made += production * dt
		local capacity = BaseConfig.Battery.Capacity
		local battery = base.Battery + net * dt
		if battery > capacity then
			summary.Overflow += battery - capacity
			base.Spill += (battery - capacity) * BaseConfig.Battery.CreditsPerElectricity
			battery = capacity
		end
		base.Battery = if battery < EPSILON then 0 else battery
		for _, chamber in base.Chambers do
			local work = chamber.Work
			if work and remaining(work) <= EPSILON then
				work.Done = (Breaker.Cost(work.Def)) or work.Done
				table.insert(base.Ready, work)
				chamber.Work = nil
				summary.Finished += 1
			end
		end
		feed(base)
		left -= dt
	end
	local whole = math.floor(base.Spill)
	if whole > 0 then
		base.Spill -= whole
		data.Currency.Credits += whole
		summary.Credits += whole
	end
end

-- The base's rates now, for a screen: the Breaker's speed (1 at full power), what the workers make and the battery's change,
-- per second, and whether a chamber is breaking. Nothing is written.
function Breaker.Rates(data: Profile.Data): { Speed: number, Production: number, Net: number, Busy: boolean }
	local production = Breaker.Production(data)
	local speed, net, busy = regime(data.Base, production)
	return { Speed = speed, Production = production, Net = net, Busy = busy }
end

-- Moves the base from its stamp to `now`. `away` is true when the player was offline for the whole gap (a rejoin), so
-- the workers' electricity stops after Config.Base.Battery.AwayHours. A base never advanced takes `now` as its stamp.
-- A `now` before the stamp (a clock step back) changes nothing.
function Breaker.Advance(data: Profile.Data, now: number, away: boolean?): Summary
	local summary: Summary = { Finished = 0, Made = 0, Overflow = 0, Credits = 0, Steps = 0 }
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
	local production = Breaker.Production(data)
	local making = if away then math.min(gap, BaseConfig.Battery.AwayHours * 3600) else gap
	step(data, making, production, summary)
	if gap > making then
		step(data, gap - making, 0, summary)
	end
	base.Stamp = now
	return summary
end

-- Seconds from the stamp until the next shard finishes or the battery empties, or nil when nothing is breaking.
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
	local speed, net = regime(base, Breaker.Production(data))
	local soonest = nextEvent(base, speed, net)
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

return Breaker
