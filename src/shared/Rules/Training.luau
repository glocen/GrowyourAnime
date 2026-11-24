--!strict
-- Training (shared, pure): the Training machine (docs/design.md, "The base", "The Training machine"; TR12). One Voidkin at
-- a time earns a fixed amount of experience a second, at any level, with no cap (the director, 2026-11-14: "Fixed rate,
-- no cap"): Config.Growth.Training.Share of what fighting earns in Lantern Row, KillsPerHour kills an hour as its stages
-- are played (Config.Stages, TR43: each stage's quota of its packs' Shades, then its elite), each kill as Rules.Drops pays
-- it. Each level costs more, so it slows as levels rise. It draws power like
-- every machine (TR18): the base's clock (Rules.Breaker) trains whoever's on it at the machine's speed, the seconds it gets
-- counted at full power, while the player is in the game and for the time away, when the lead trains.
--   Training.Rate()                      experience a second at full power, at any level
--   Training.Gain(owned, seconds)        trains `owned` for `seconds` at full power: the levels gained, and the seconds
--                                        left over
--   Training.Who(playerHome, lead, leadWaiting, healed)   who trains while the player is in the game, or nil
--   Training.WorkRate(kw)                a worker's experience a second at `kw` (TR55): Config.Base.Bays.Xp.PerKwh seconds
--                                        of the Training rate a kWh, never more a second than Xp.Cap times it
--   Training.Work(owned, seconds, kwAt)  a worker at work for `seconds`, `kwAt(level)` its kW at each level: the levels
--                                        gained, and the seconds left over

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local GrowthConfig = require(Shared.Config.Growth)
local BaseConfig = require(Shared.Config.Base)
local WorldConfig = require(Shared.Config.World)
local StagesConfig = require(Shared.Config.Stages)
local DropsConfig = require(Shared.Config.Drops)
local Growth = require(Shared.Rules.Growth)

local Training = {}

-- What a kill in Lantern Row pays on average as its stages are played: each stage of packs and an elite, its quota of
-- Shades at its packs' levels, then its elite, each kill as Rules.Drops pays it. The keeper's stage isn't counted.
local function rowXpPerKill(): number
	local kills, xp = 0, 0
	for _, stage in StagesConfig.Grounds[WorldConfig.Row.Ground] or {} do
		local last = stage.Stops[#stage.Stops]
		local packs, g = 0, 0
		for _, stop in stage.Stops do
			if stop.Kind == "Pack" then
				packs += 1
				g += Growth.G(stop.Level)
			end
		end
		if last and last.Kind == "Elite" and packs > 0 then
			kills += stage.Quota + 1
			xp += GrowthConfig.XpPerKillPerG
				* (stage.Quota * g / packs * DropsConfig.Share.Ordinary + Growth.G(last.Level) * DropsConfig.Share.Elite)
		end
	end
	return if kills > 0 then xp / kills else 0
end

function Training.Rate(): number
	return GrowthConfig.Training.Share * GrowthConfig.KillsPerHour / 3600 * rowXpPerKill()
end

function Training.WorkRate(kw: number): number
	local xp = BaseConfig.Bays.Xp
	return math.min(math.max(kw, 0) * xp.PerKwh / 3600, xp.Cap) * Training.Rate()
end

-- Raises `owned` by `seconds` at `rateAt(level)` experience a second, level by level, each at its own level's rate.
-- Returns the levels gained and the seconds not yet worth a whole point, so the caller keeps them. At the last level the
-- time is spent on nothing.
local function earn(owned: Profile.OwnedVoidkin, seconds: number, rateAt: (number) -> number): (number, number)
	if not (seconds > 0) or seconds == math.huge then
		return 0, 0
	end
	local gained, left = 0, seconds
	for _ = 1, GrowthConfig.MaxLevel do
		local need = Growth.XpToNext(owned.Level)
		local rate = rateAt(owned.Level)
		if need == nil or not (rate > 0) then
			owned.Xp = if need == nil then 0 else owned.Xp
			return gained, 0
		end
		local toNext = math.max(0, need - owned.Xp) / rate
		if toNext > left then
			local points = math.floor(left * rate)
			owned.Xp += points
			return gained, left - points / rate
		end
		left -= toNext
		owned.Level += 1
		owned.Xp = 0
		gained += 1
	end
	return gained, 0
end

-- Trains `owned` for `seconds` at full power at the Training rate, which is the same at every level.
function Training.Gain(owned: Profile.OwnedVoidkin, seconds: number): (number, number)
	local rate = Training.Rate()
	return earn(owned, seconds, function(): number
		return rate
	end)
end

-- A worker at work for `seconds`: each level at the rate its kW there pays (TR55).
function Training.Work(owned: Profile.OwnedVoidkin, seconds: number, kwAt: (number) -> number): (number, number)
	return earn(owned, seconds, function(level: number): number
		return Training.WorkRate(kwAt(level))
	end)
end

export type Healed = { Id: string, Fell: number }

-- Who trains while the player is in the game (docs/design.md, "The Training machine"): nobody while they're on their plot
-- (the lead leaves the machine and follows); else their lead, fallen, healed and waiting at home (`leadWaiting`); else
-- the one that fell last among those healed at home. Offline it's the lead (Training.Advance's caller).
function Training.Who(playerHome: boolean, lead: string, leadWaiting: boolean, healed: { Healed }): string?
	if playerHome then
		return nil
	end
	if leadWaiting and lead ~= "" then
		return lead
	end
	local best: Healed? = nil
	for _, one in healed do
		if best == nil or one.Fell > best.Fell then
			best = one
		end
	end
	return if best then best.Id else nil
end

return Training
