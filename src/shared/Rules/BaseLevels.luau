--!strict
-- BaseLevels (shared, pure): the base's levels and its machines' (TR21; docs/design.md, "The base"; docs/balance.md,
-- "Earning"). The base's level, 1 to Config.Base.Levels.Cap, opens bays, holds the battery's cap and sets the ceiling
-- every machine can reach; a machine's level raises its own work, a bay its output, the Breaker its speed, then its
-- third and fourth chambers, and the Stone Condenser its rate and its tray (TR37). Each level costs Credits, and its gain is shown before it's bought, so an offer gives the
-- price, the gain, and why it can't be bought when it can't. No Roblox API: it runs with Studio closed.
--   BaseLevels.Next(baseLevel, credits)                     the base's next level, as an offer
--   BaseLevels.NextMachine(machine, level, baseLevel, credits)  a machine's next level ("Breaker", "Bay" or "Condenser"), as an offer
--   BaseLevels.Ask(base, spot, credits)                     what a spot of the base's view can buy: the action, its
--                                                           arguments and its offer, as Rules.Base takes them
--   BaseLevels.ChambersShown(open), ChamberOpens(open)      the Breaker screen's chambers over those open, and the
--                                                           Breaker level that opens the next one shown (nil: none waits)
--   BaseLevels.Stage(level)                                 a machine's stage at its level: 1, 2 or 3
--   BaseLevels.GeneratorStage(baseLevel)                    the generator's: a machine's at the base's ceiling
--   BaseLevels.Stages(base)                                 every machine's stage on a base, as the world stands it (TR51)
--   BaseLevels.Lands(was, now)                              whether a stage swap plays AR37's landing: only a rise seen

local Shared = game:GetService("ReplicatedStorage").Shared
local BaseConfig = require(Shared.Config.Base)
local Condenser = require(Shared.Rules.Condenser)

local BaseLevels = {}

export type Machine = "Breaker" | "Bay" | "Condenser"
-- Every machine's stage on a base (TR51): the Breaker's and each bay's by its own level (AR32, AR33), the generator's,
-- the battery's and the Training machine's, which have none, at the base's (AR19, AR34, AR35).
export type Stages = { Generator: number, Breaker: number, Battery: number, Training: number, Bays: { number } }
-- What Stages reads of a base (Data.Profile's Base), so the rule needs no profile.
export type StagedBase = { Level: number, Machines: { [string]: number }, Bays: { { Level: number } } }
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
BaseLevels.Asleep = "Asleep" -- the Stone Condenser before the base's level wakes it

-- What a press on a spot of the base's view asks the server for (docs/ui.md, 7: "its price, and Upgrade").
export type Ask = {
	Act: string, -- Rules.Base's action: "UpgradeBase" or "UpgradeMachine"
	Args: { [string]: any }, -- as that action takes them
	Machine: Machine?, -- nil for the base itself
	Bay: number?,
	Now: number, -- the level it stands at
	Offer: Offer,
}

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

-- The gear presets a base of `level` holds (TR56).
function BaseLevels.Presets(level: number): number
	return at(BaseConfig.Levels.Presets, level)
end

-- Adds empty presets to a save's `presets` up to its base `level`'s count: never takes one away.
function BaseLevels.GrowPresets(presets: any, level: number)
	for _ = #presets + 1, BaseLevels.Presets(level) do
		table.insert(presets, { Slots = {}, Hands = {} })
	end
end

-- The bays every plot lays (Config.Base.Levels.Plot), the ones no level at launch opens among them (D5).
function BaseLevels.Plot(): number
	return BaseConfig.Levels.Plot
end

-- The base level that opens bay `index`, or nil when none at launch does: it opens with more Voidkin (D5).
function BaseLevels.OpensAt(index: number): number?
	for level = 1, BaseLevels.Top() do
		if BaseLevels.Bays(level) >= index then
			return level
		end
	end
	return nil
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

-- Every machine's stage on `base`: the Breaker and each bay at their own machine level's (Stages: I to 5, II from 6, III
-- from 15), the generator, the battery and the Training machine at the base's (I at level 1, II at 2, III at 3).
function BaseLevels.Stages(base: StagedBase): Stages
	local byBase = BaseLevels.GeneratorStage(base.Level)
	local bays = {}
	for index, bay in base.Bays do
		bays[index] = BaseLevels.Stage(bay.Level)
	end
	return {
		Generator = byBase,
		Breaker = BaseLevels.Stage(base.Machines.Breaker or 1),
		Battery = byBase,
		Training = byBase,
		Bays = bays,
	}
end

-- Whether a machine going from stage `was` to `now` plays AR37's landing: only a rise from a stage already seen, so a
-- join, a respawn or a plot streaming in (`was` nil) shows its stage standing, and nothing plays on a fall.
function BaseLevels.Lands(was: number?, now: number): boolean
	return was ~= nil and now > was
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

-- The chambers the Breaker's screen shows over `open` (research, 2026-11-25, tier 1): those open, and each locked one a
-- machine can reach under the launch's top ceiling (Ceiling at Levels.Cap). A chamber no ceiling reaches isn't shown, so
-- the screen never promises what an upgrade can't give; it appears when a ceiling reaches its level. The world's lidded
-- seats stay to MostChambers (a prop, no words).
function BaseLevels.ChambersShown(open: number): number
	local top = BaseLevels.Ceiling(BaseConfig.Levels.Cap)
	local shown = math.max(open, BaseConfig.Start.Chambers)
	for _, step in BaseConfig.Machines.BreakerChambers do
		if step.From <= top then
			shown = math.max(shown, math.min(step.Chambers, BaseConfig.Breaker.MostChambers))
		end
	end
	return shown
end

-- The Breaker level that opens the next chamber the screen shows over `open`, or nil when every shown one is open.
function BaseLevels.ChamberOpens(open: number): number?
	local shown = BaseLevels.ChambersShown(open)
	for _, step in BaseConfig.Machines.BreakerChambers do
		if step.Chambers > open and step.Chambers <= shown then
			return step.From
		end
	end
	return nil
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
	gain(gains, "Presets", BaseLevels.Presets(baseLevel), BaseLevels.Presets(level))
	gain(gains, "Battery", BaseLevels.Battery(baseLevel), BaseLevels.Battery(level))
	gain(gains, "Ceiling", BaseLevels.Ceiling(baseLevel), BaseLevels.Ceiling(level))
	gain(gains, "Condenser", if Condenser.Awake(baseLevel) then 1 else 0, if Condenser.Awake(level) then 1 else 0) -- it wakes (TR37)
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
	elseif machine == "Condenser" then
		gain(gains, "Rate", Condenser.Rate(level), Condenser.Rate(next)) -- stones an hour at full power
		gain(gains, "Tray", Condenser.Cap(level), Condenser.Cap(next))
	else
		gain(gains, "Output", BaseLevels.BayOutput(level), BaseLevels.BayOutput(next))
	end
	if next > BaseLevels.Ceiling(baseLevel) and baseLevel >= BaseLevels.Top() then
		-- the top base level's ceiling is the machine's top: no base level to wait for (the ceiling 15 sits below the
		-- price table's end)
		return { Level = next, Price = nil, Why = BaseLevels.AtCap, Gains = {} }
	end
	local why = if next > BaseLevels.Ceiling(baseLevel) then BaseLevels.AtCeiling elseif credits < price then BaseLevels.Short else nil
	return { Level = next, Price = price, Why = why, Gains = gains }
end

-- What a spot of the base's view can buy: "Base", "Breaker", "Condenser" or a bay ("Bay3"). The action, its arguments
-- and its offer, so the press sends exactly what Rules.Base accepts, and says why when it can't. Nil for a spot with no
-- level of its own (the battery, the generator and the Training machine follow the base's) and for a bay not open yet.
function BaseLevels.Ask(base: StagedBase, spot: string, credits: number): Ask?
	if spot == "Base" then
		local offer = BaseLevels.Next(base.Level, credits)
		return { Act = "UpgradeBase", Args = { Level = offer.Level }, Now = base.Level, Offer = offer }
	end
	local bay = tonumber(string.match(spot, "^Bay(%d+)$"))
	if bay ~= nil then
		local open = base.Bays[bay]
		if open == nil then
			return nil
		end
		local level = open.Level or 1
		local offer = BaseLevels.NextMachine("Bay", level, base.Level, credits)
		return { Act = "UpgradeMachine", Args = { Machine = "Bay", Bay = bay, Level = offer.Level }, Machine = "Bay", Bay = bay, Now = level, Offer = offer }
	elseif spot == "Breaker" or spot == "Condenser" then
		local level = base.Machines[spot] or 1
		local offer = BaseLevels.NextMachine(spot, level, base.Level, credits)
		if spot == "Condenser" and not Condenser.Awake(base.Level) then
			offer.Why = BaseLevels.Asleep
		end
		return { Act = "UpgradeMachine", Args = { Machine = spot, Level = offer.Level }, Machine = spot, Now = level, Offer = offer }
	end
	return nil
end

return BaseLevels
