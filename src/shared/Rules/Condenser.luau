--!strict
-- Condenser (shared, pure): the Stone Condenser over time (TR37; docs/design.md, "The base"; Config.Condenser). From the
-- base's level Wakes, it makes stones of its grade into its tray at its level's rate and its power's speed (Rules.Power,
-- through Rules.Breaker's steps, online and away), its whole stones only; a tray at its cap stops it. Its second job, one
-- at a time, turns stones taken from the bag into a higher grade over its seconds of work, at the same speed, landing in
-- the tray beside the cap. It works while awake and making or converting, and asks its rating only then. Rules.Base's
-- CollectTray and Convert are what a player asks of it. No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local CondenserConfig = require(Shared.Config.Condenser)

local Condenser = {}

-- What it reads of a base (Profile.Base, which requires BaseLevels, which requires this: so its own shape here).
type Base = {
	Level: number,
	Machines: { [string]: number },
	Condenser: { Made: number, Tray: { [string]: number }, Convert: number? },
}

local EPSILON = 1e-9

-- Its level (Base.Machines; 1 in a save from before it).
function Condenser.Level(base: Base): number
	return base.Machines.Condenser or 1
end

-- Stones an hour at full power at `level`.
function Condenser.Rate(level: number): number
	local rate = CondenserConfig.Rate
	return rate.First + rate.PerLevel * (math.max(1, level) - 1)
end

-- Its full speed against level 1's: its rating rises with it, as the Breaker's with its speed.
function Condenser.Pace(level: number): number
	return Condenser.Rate(level) / Condenser.Rate(1)
end

-- Whole stones of its grade its tray holds at `level`: TrayHours of its making.
function Condenser.Cap(level: number): number
	return math.floor(CondenserConfig.TrayHours * Condenser.Rate(level) + EPSILON)
end

-- Its rating at `level`, kW.
function Condenser.Rating(level: number): number
	return CondenserConfig.Kw * Condenser.Pace(level)
end

-- Whether a base of `baseLevel` has it awake.
function Condenser.Awake(baseLevel: number): boolean
	return baseLevel >= CondenserConfig.Wakes
end

-- Stones of its grade in the tray.
function Condenser.Held(base: Base): number
	return base.Condenser.Tray[CondenserConfig.Makes] or 0
end

-- Whether it's making: awake, its tray under its cap.
function Condenser.Making(base: Base): boolean
	return Condenser.Awake(base.Level) and Condenser.Held(base) < Condenser.Cap(Condenser.Level(base))
end

-- Whether it works now: making, or converting while awake.
function Condenser.Working(base: Base): boolean
	return Condenser.Making(base) or (Condenser.Awake(base.Level) and base.Condenser.Convert ~= nil)
end

-- kW it asks now: its rating while it works, else 0.
function Condenser.Demand(base: Base): number
	return if Condenser.Working(base) then Condenser.Rating(Condenser.Level(base)) else 0
end

-- Seconds at `speed` (1 at full power) until its next event: its next whole stone while it makes, the convert's end.
-- math.huge when neither comes.
function Condenser.Next(base: Base, speed: number): number
	if speed <= 0 or not Condenser.Awake(base.Level) then
		return math.huge
	end
	local soonest = math.huge
	if Condenser.Making(base) then
		local perSecond = Condenser.Rate(Condenser.Level(base)) * speed / 3600
		soonest = math.max(0, 1 - base.Condenser.Made) / perSecond
	end
	local convert = base.Condenser.Convert
	if convert then
		soonest = math.min(soonest, math.max(0, CondenserConfig.Convert.Seconds - convert) / speed)
	end
	return soonest
end

-- Works `seconds` at `speed`: its making into the tray to its cap, and the convert under way. Returns the stones made
-- and the converts finished. Asleep, nothing.
function Condenser.Work(base: Base, speed: number, seconds: number): (number, number)
	if seconds <= 0 or not Condenser.Awake(base.Level) then
		return 0, 0
	end
	local state = base.Condenser
	local made = 0
	if Condenser.Making(base) then
		local level = Condenser.Level(base)
		local cap, held = Condenser.Cap(level), Condenser.Held(base)
		local share = state.Made + Condenser.Rate(level) * speed * seconds / 3600
		local whole = math.floor(share + EPSILON)
		made = math.min(whole, cap - held)
		state.Tray[CondenserConfig.Makes] = held + made
		state.Made = if held + made >= cap then 0 else math.clamp(share - whole, 0, 1) -- full: it stops
	end
	local finished = 0
	local convert = CondenserConfig.Convert
	if state.Convert then
		local done = (state.Convert :: number) + speed * seconds
		if done >= convert.Seconds - EPSILON then
			state.Tray[convert.To] = (state.Tray[convert.To] or 0) + convert.Give
			state.Convert = nil
			finished = 1
		else
			state.Convert = done
		end
	end
	return made, finished
end

-- How many of a comb's `cups` its tray lights (TR37): the tray's fill of its cap over the comb, so a full tray lights it
-- whole and a single stone lights one; none while it's asleep or empty. The convert's grade is collected beside it.
function Condenser.Lit(base: Base, cups: number): number
	local held = Condenser.Held(base)
	if held <= 0 or cups <= 0 or not Condenser.Awake(base.Level) then
		return 0
	end
	local cap = math.max(1, Condenser.Cap(Condenser.Level(base)))
	return math.clamp(math.ceil(held / cap * cups - EPSILON), 1, cups)
end

-- Seconds of work the convert under way has left at full power, or nil with none.
function Condenser.ConvertLeft(base: Base): number?
	local convert = base.Condenser.Convert
	return if convert then math.max(0, CondenserConfig.Convert.Seconds - convert) else nil
end

return Condenser
