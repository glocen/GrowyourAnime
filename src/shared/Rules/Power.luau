--!strict
-- Power (shared, pure): the base as a power plant at one moment (docs/design.md, "Power"; TR18). What the bays generate,
-- what each machine asks, and how the generation is split among them: the speed each runs at and what charges or drains
-- the battery. Rules.Breaker steps it through time. Power is in kW, energy in kWh. No Roblox API: it runs with Studio
-- closed.
--   Power.Staff(data, bay) is a bay's picker: every owned Voidkin with what the base gains by stationing it there.
--   Under Auto each machine's routed demand is its full rating: the generation serves them all, the battery covers what
--   it can't while it holds charge, and with the battery empty they share the generation by demand.
--   Under a split each machine has its share of the generation, never more than it, so the battery is never drawn: what
--   a machine's share doesn't use, and what isn't routed, charges the battery.
--   A machine short of power runs at what it takes over its rating, never below Config.Base.Power.MinSpeed; the floor's
--   share of the work costs nothing.

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local Shards = require(Shared.Definitions.Shards)
local Voidkin = require(Shared.Definitions.Voidkin)
local BaseConfig = require(Shared.Config.Base)
local ShardConfig = require(Shared.Config.Shards)
local BaseLevels = require(Shared.Rules.BaseLevels)
local Condenser = require(Shared.Rules.Condenser)

local Power = {}

-- The machines that draw power, in the order the Power screen and its bar show them. The bar splits the first two; the
-- Stone Condenser (TR37) shares under Auto and takes a share asked of SetPower, its own handle to come.
Power.Machines = { "Breaker", "Training", "Condenser" }

export type Flow = {
	Generation: number, -- kW the bays generate
	Demand: { [string]: number }, -- kW each machine asks at full speed now; 0 for one that isn't working
	Draw: { [string]: number }, -- kW each machine takes
	Speed: { [string]: number }, -- each machine's speed, 1 at full power, never under the floor; 1 for one that's idle
	Net: number, -- kW into the battery; negative while it covers demand
}

local EPSILON = 1e-9

-- The kW one Voidkin generates at work, at its level or at `level`: 0 for a definition that's gone.
function Power.Output(worker: Profile.OwnedVoidkin, level: number?): number
	local bays = BaseConfig.Bays
	local row = Voidkin.ById[worker.Def]
	if row == nil then
		return 0
	end
	return row.Aptitude * bays.KwPerAptitude * (1 + bays.PerLevel * ((level or worker.Level) - 1))
end

-- Who a bay's picker offers, the best for the base first, so nobody does sums to staff a bay.
export type Hand = {
	Id: string,
	Kw: number, -- what it would make in this bay, at the bay's level
	Gain: number, -- what the base's generation changes by once it's stationed here: it leaves the bay it works, and the
	-- worker here steps out. 0 for the one here and for the lead
	Where: string, -- "Here", "Lead", "Bay" (it works another bay) or ""
	Bay: number?, -- that other bay
}

-- Every owned Voidkin for bay `bay`'s picker: the ones that can be stationed by what the base gains, the most first
-- (then the higher output, then the id, so two reads agree), then the worker here, then the lead, who can't work. Empty
-- for a bay that isn't open.
function Power.Staff(data: Profile.Data, bay: number): { Hand }
	local here = data.Base.Bays[bay]
	if here == nil then
		return {}
	end
	local share = BaseLevels.BayOutput(here.Level or 1)
	local current = if here.Worker ~= "" then data.Voidkin[here.Worker] else nil
	local leaves = if current then Power.Output(current) * share else 0
	local works: { [string]: number } = {}
	for index, other in data.Base.Bays do
		if other.Worker ~= "" then
			works[other.Worker] = index
		end
	end
	local hands: { Hand } = {}
	for id, owned in data.Voidkin do
		local kw = Power.Output(owned) * share
		local at = works[id]
		if id == data.Roles.Lead then
			table.insert(hands, { Id = id, Kw = kw, Gain = 0, Where = "Lead" })
		elseif at == bay then
			table.insert(hands, { Id = id, Kw = kw, Gain = 0, Where = "Here" })
		elseif at ~= nil then
			local there = Power.Output(owned) * BaseLevels.BayOutput(data.Base.Bays[at].Level or 1)
			table.insert(hands, { Id = id, Kw = kw, Gain = kw - leaves - there, Where = "Bay", Bay = at })
		else
			table.insert(hands, { Id = id, Kw = kw, Gain = kw - leaves, Where = "" })
		end
	end
	local rank: { [string]: number } = { [""] = 1, Bay = 1, Here = 2, Lead = 3 }
	table.sort(hands, function(a: Hand, b: Hand): boolean
		if rank[a.Where] ~= rank[b.Where] then
			return rank[a.Where] < rank[b.Where]
		end
		if math.abs(a.Gain - b.Gain) > EPSILON then
			return a.Gain > b.Gain
		end
		if math.abs(a.Kw - b.Kw) > EPSILON then
			return a.Kw > b.Kw
		end
		return a.Id < b.Id
	end)
	return hands
end

-- The kW `worker` makes in bay `bay`, at the bay's level (TR21): what Lead, Station and Recall say they cost (docs/ui.md,
-- item 5). 0 for a bay that isn't open.
function Power.BayKw(data: Profile.Data, bay: number, worker: Profile.OwnedVoidkin): number
	local here = data.Base.Bays[bay]
	return if here then Power.Output(worker) * BaseLevels.BayOutput(here.Level or 1) else 0
end

-- The kW the bays' workers generate, each times its bay's level's output (TR21).
function Power.Generation(data: Profile.Data): number
	local kw = 0
	for _, bay in data.Base.Bays do
		local worker = if bay.Worker ~= "" then data.Voidkin[bay.Worker] else nil
		if worker then
			kw += Power.Output(worker) * BaseLevels.BayOutput(bay.Level or 1)
		end
	end
	return kw
end

-- The kW a chamber draws breaking a shard at the Breaker's level 1: its rating, times the shard's ground factor. Nil for
-- an unknown shard. A level past the first raises the draw and the speed together (Power.Demand), so a shard's kWh stay.
function Power.Rating(shardId: string): number?
	local shard = Shards.ById[shardId]
	if shard == nil then
		return nil
	end
	return BaseConfig.Breaker.Kw * (ShardConfig.RegionFactor[shard.Ground] or 1)
end

-- A shard's work: its seconds at full power and the kWh it costs, never set but derived: its chamber's rating over its
-- break time (TR18). Nil for an unknown shard.
function Power.Cost(shardId: string): (number?, number?)
	local shard = Shards.ById[shardId]
	local grade = shard and ShardConfig.Grades[shard.Grade]
	local rating = Power.Rating(shardId)
	if grade == nil or rating == nil then
		return nil, nil
	end
	return grade.BreakSeconds, rating * grade.BreakSeconds / 3600
end

-- What each machine asks now, kW: the Breaker its chambers' ratings at its level (TR21), the Training machine its own
-- while someone's on it, the Stone Condenser its rating at its level while it works (TR37).
function Power.Demand(data: Profile.Data, training: boolean): { [string]: number }
	local breaker = 0
	for _, chamber in data.Base.Chambers do
		local work = chamber.Work
		if work then
			breaker += Power.Rating(work.Def) or 0
		end
	end
	breaker *= BaseLevels.BreakerSpeed(data.Base.Machines.Breaker or 1)
	return { Breaker = breaker, Training = if training then BaseConfig.Training.Kw else 0, Condenser = Condenser.Demand(data.Base) }
end

-- How `generation` kW serves `demand` under `setting`, with the battery holding charge (`charged`) or empty.
function Power.Flow(generation: number, demand: { [string]: number }, setting: Profile.Power, charged: boolean): Flow
	local floor = BaseConfig.Power.MinSpeed
	local draw: { [string]: number } = {}
	local speed: { [string]: number } = {}
	local total = 0
	for _, name in Power.Machines do
		total += demand[name] or 0
	end
	local net: number
	if setting.Auto then
		local share = if generation >= total or charged or total <= 0 then 1 else generation / total
		for _, name in Power.Machines do
			local asks = demand[name] or 0
			draw[name] = asks * share
			speed[name] = if asks > 0 then math.max(floor, share) else 1
		end
		net = if share < 1 then 0 else generation - total
	else
		-- Shares over the whole (a save from a longer machine list) are scaled back to it, so the battery is never drawn.
		local routed = 0
		for _, name in Power.Machines do
			routed += math.max(0, setting.Shares[name] or 0)
		end
		local scale = if routed > 1 then 1 / routed else 1
		local used = 0
		for _, name in Power.Machines do
			local asks = demand[name] or 0
			local offered = math.max(0, setting.Shares[name] or 0) * scale * generation
			local taken = math.min(offered, asks)
			draw[name] = taken
			speed[name] = if asks > 0 then math.max(floor, taken / asks) else 1
			used += taken
		end
		net = math.max(0, generation - used)
	end
	return { Generation = generation, Demand = demand, Draw = draw, Speed = speed, Net = net }
end

-- Voltage into a shard at `level` (Config.Shards.Voltage.Levels): its price in whole kWh and the seconds of work it saves,
-- from what the shard has left. The price is nil when it saves under MinSavedSeconds, so it isn't offered, and for an
-- unknown shard or level.
function Power.Voltage(work: Profile.ShardWork, level: number): (number?, number)
	local voltage = ShardConfig.Voltage
	local row = voltage.Levels[level]
	local seconds = Power.Cost(work.Def)
	local rating = Power.Rating(work.Def)
	if row == nil or seconds == nil or rating == nil then
		return nil, 0
	end
	local saved = math.max(0, seconds - work.Done) * (1 - row.TimeLeft)
	if saved < voltage.MinSavedSeconds then
		return nil, saved
	end
	return math.ceil(rating * saved / 3600 * voltage.Premium - EPSILON), saved
end

-- Whether voltage is ever offered on a shard of this kind: some level saves at least MinSavedSeconds of a whole shard's
-- work. Where it can't be, the Breaker shows no voltage at all (research, TR18: a pane that can only say "not offered"
-- is noise, as on Lantern Row's 30-second shards). False for an unknown shard.
function Power.Offered(shardId: string): boolean
	for level in ShardConfig.Voltage.Levels do
		if (Power.Voltage({ Def = shardId, Luck = 0, Done = 0 }, level)) ~= nil then
			return true
		end
	end
	return false
end

-- A split a client asked for, checked: each share a machine's, 0 or more, the whole never over 1. Returns the shares,
-- or nil and a refusal code (Rules.Base's): "BadArgs" for the wrong shape, "Over" for a whole over 1.
-- The generator's gauge (AR19, the Void Mill): the generation and the demand as shares of one scale, 0 at the well to 1
-- at the collector's shoe, and the steps the generation lights. The scale's top is the larger of the two over
-- `gauge.Fill`, never under `gauge.Floor` kW, so the larger never quite reaches the top, the lit steps meet the mark
-- when generation meets demand, and a small plant reads small. Steps light from the first: none at no generation, all
-- at the top, the share times Steps rounded otherwise, and at least one while any power is made.
export type Gauge = { Steps: number, Floor: number, Fill: number }
export type GaugeRead = { Generation: number, Demand: number, Lit: number }
function Power.Gauge(generation: number, demand: number, gauge: Gauge): GaugeRead
	local made = math.max(0, if generation == generation then generation else 0)
	local asked = math.max(0, if demand == demand then demand else 0)
	local top = math.max(gauge.Floor, math.max(made, asked) / math.max(gauge.Fill, EPSILON), EPSILON)
	local share = math.clamp(made / top, 0, 1)
	local lit = math.clamp(math.floor(share * gauge.Steps + 0.5), 0, gauge.Steps)
	if made > EPSILON and lit == 0 then
		lit = 1
	end
	return { Generation = share, Demand = math.clamp(asked / top, 0, 1), Lit = lit }
end

function Power.Shares(asked: any): ({ [string]: number }?, string?)
	if type(asked) ~= "table" then
		return nil, "BadArgs"
	end
	local shares: { [string]: number } = {}
	local whole = 0
	for name, share in asked do
		if type(name) ~= "string" or table.find(Power.Machines, name) == nil then
			return nil, "BadArgs"
		end
		if type(share) ~= "number" or share ~= share or share < 0 or share == math.huge then
			return nil, "BadArgs"
		end
		shares[name] = share
		whole += share
	end
	if whole > 1 + 1e-6 then
		return nil, "Over"
	end
	return shares, nil
end

return Power
