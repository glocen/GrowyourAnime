--!strict
-- BaseLevels (shared, pure): the base's levels and its machines' (TR21; docs/design.md, "The base"; docs/balance.md,
-- "Earning"). The base's level, 1 to Config.Base.Levels.Cap, opens bays, holds the battery's cap and sets the ceiling
-- every machine can reach; a machine's level raises its own work, a bay its output and the Breaker its speed, then its
-- third and fourth chambers. Each level costs Credits, and its gain is shown before it's bought, so an offer gives the
-- price, the gain, and why it can't be bought when it can't. No Roblox API: it runs with Studio closed.
--   BaseLevels.Next(baseLevel, credits)                     the base's next level, as an offer
--   BaseLevels.NextMachine(machine, level, baseLevel, credits)  a machine's next level ("Breaker" or "Bay"), as an offer
--   BaseLevels.Stage(level)                                 a machine's stage at its level: 1, 2 or 3
--   BaseLevels.GeneratorStage(baseLevel)                    the generator's: a machine's at the base's ceiling

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseConfig = require(Shared.Config.Base)

local BaseLevels = {}

export type Machine = "Breaker" | "Bay"
export type Gain = { What: string, From: number, To: number }
export type Offer = {
	Level: number, -- the level it would reach
	Price: number?, -- Credits; nil when there's no such level
	Why: string?, -- nil when it can be bought now: Cap, Ceiling or Short
	Gains: { Gain },
}

-- Why an offer can't be bought.
BaseLevels.AtCap = "Cap" -- past the last level there is
BaseLevels.AtCeiling = "Ceiling" -- a machine at its base's ceiling: the base's level comes first
BaseLevels.Short = "Short" -- fewer Credits than the price

local function at(list: { number }, level: number): number
	return list[math.clamp(level, 1, #list)]
end

function BaseLevels.Top(): number
	return BaseConfig.Levels.Cap
end

-- Credits to reach the base's `level`; nil at 1 and past the cap.
function BaseLevels.Price(level: number): number?
	return if level <= BaseConfig.Levels.Cap then BaseConfig.Levels.Price[level] else nil
end

function BaseLevels.Bays(level: number): number
	return at(BaseConfig.Levels.Bays, level)
end

function BaseLevels.Ceiling(level: number): number
	return at(BaseConfig.Levels.Ceiling, level)
end

function BaseLevels.Battery(level: number): number
	return at(BaseConfig.Levels.Battery, level)
end

-- A machine's stage at its `level` (Config.Base.Machines.Stages): 1, Primitive; 2, Developed; 3, Advanced.
function BaseLevels.Stage(level: number): number
	local stage = 1
	for index, from in BaseConfig.Machines.Stages do
		if level >= from then
			stage = index
		end
	end
	return stage
end

-- The generator's stage at the base's `level`: it has no level of its own, so it stands as a machine at the base's
-- ceiling would, and the plant's heart changes when the base levels up (docs/design.md; AR19).
function BaseLevels.GeneratorStage(baseLevel: number): number
	return BaseLevels.Stage(BaseLevels.Ceiling(baseLevel))
end

-- Cells the battery's bank shows at the base's `level` (AR15, section 4).
function BaseLevels.Cells(level: number): number
	return at(BaseConfig.Levels.Cells, level)
end

-- Credits to reach a machine's `level`; nil at 1 and past the table.
function BaseLevels.MachinePrice(level: number): number?
	return BaseConfig.Machines.Price[level]
end

-- The Breaker's chambers at its `level`: two, then each step's from its level on.
function BaseLevels.Chambers(level: number): number
	local chambers = BaseConfig.Start.Chambers
	for _, step in BaseConfig.Machines.BreakerChambers do
		if level >= step.From then
			chambers = math.max(chambers, step.Chambers)
		end
	end
	return chambers
end

-- The Breaker's speed and its rating, against level 1's.
function BaseLevels.BreakerSpeed(level: number): number
	return 1 + BaseConfig.Machines.BreakerSpeed * (math.max(level, 1) - 1)
end

-- A bay's output, against level 1's.
function BaseLevels.BayOutput(level: number): number
	return 1 + BaseConfig.Machines.BayOutput * (math.max(level, 1) - 1)
end

local function gain(gains: { Gain }, what: string, from: number, to: number)
	if from ~= to then
		table.insert(gains, { What = what, From = from, To = to })
	end
end

function BaseLevels.Next(baseLevel: number, credits: number): Offer
	local level = baseLevel + 1
	local price = BaseLevels.Price(level)
	local gains: { Gain } = {}
	if price == nil then
		return { Level = level, Price = nil, Why = BaseLevels.AtCap, Gains = gains }
	end
	gain(gains, "Bays", BaseLevels.Bays(baseLevel), BaseLevels.Bays(level))
	gain(gains, "Battery", BaseLevels.Battery(baseLevel), BaseLevels.Battery(level))
	gain(gains, "Ceiling", BaseLevels.Ceiling(baseLevel), BaseLevels.Ceiling(level))
	return { Level = level, Price = price, Why = if credits < price then BaseLevels.Short else nil, Gains = gains }
end

function BaseLevels.NextMachine(machine: Machine, level: number, baseLevel: number, credits: number): Offer
	local next = level + 1
	local price = BaseLevels.MachinePrice(next)
	local gains: { Gain } = {}
	if price == nil then
		return { Level = next, Price = nil, Why = BaseLevels.AtCap, Gains = gains }
	end
	if machine == "Breaker" then
		gain(gains, "Speed", BaseLevels.BreakerSpeed(level), BaseLevels.BreakerSpeed(next))
		gain(gains, "Chambers", BaseLevels.Chambers(level), BaseLevels.Chambers(next))
	else
		gain(gains, "Output", BaseLevels.BayOutput(level), BaseLevels.BayOutput(next))
	end
	local why = if next > BaseLevels.Ceiling(baseLevel) then BaseLevels.AtCeiling elseif credits < price then BaseLevels.Short else nil
	return { Level = next, Price = price, Why = why, Gains = gains }
end

return BaseLevels
