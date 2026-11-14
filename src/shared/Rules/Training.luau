--!strict
-- Training (shared, pure): the Training machine (docs/design.md, "The base", "The Training machine"; TR12). One Voidkin at
-- a time earns experience at Config.Growth.Training.Share of what fighting earns a second at its own level (KillsPerHour
-- kills an hour), with no cap: each level's own cost slows it, so it's fast only at the start. Its time is worked out from
-- a stamp (Profile's Training.Stamp), as the Breaker's is: on the server's clock while the player is in the game, and at a
-- join for the time away, when the lead trained. It draws nothing.
--   Training.Rate(level)                 experience a second at `level`
--   Training.Gain(owned, seconds)        trains `owned` for `seconds`: the levels gained, and the seconds left over
--   Training.Who(playerHome, lead, leadWaiting, healed)   who trains while the player is in the game, or nil
--   Training.Advance(data, now, trainee) trains `trainee` from the stamp to `now`, and moves the stamp

local Shared = game:GetService("ReplicatedStorage").Shared
local Profile = require(Shared.Data.Profile)
local GrowthConfig = require(Shared.Config.Growth)
local Growth = require(Shared.Rules.Growth)

local Training = {}

function Training.Rate(level: number): number
	return GrowthConfig.Training.Share * GrowthConfig.KillsPerHour / 3600 * Growth.XpPerKill(level)
end

-- Trains `owned` for `seconds`, level by level, each at its own level's rate. Returns the levels gained and the seconds
-- not yet worth a whole point of experience, so the stamp keeps them. At the last level the time is spent on nothing.
function Training.Gain(owned: Profile.OwnedVoidkin, seconds: number): (number, number)
	if not (seconds > 0) or seconds == math.huge then
		return 0, 0
	end
	local gained, left = 0, seconds
	for _ = 1, GrowthConfig.MaxLevel do
		local need = Growth.XpToNext(owned.Level)
		local rate = Training.Rate(owned.Level)
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

-- Trains `trainee` (an owned Voidkin's Id, or nil for nobody) from the stamp to `now`, and moves the stamp. The first call
-- only sets it, and a clock that went back sets it again. A worker never trains. Returns who trained and the levels gained.
function Training.Advance(data: Profile.Data, now: number, trainee: string?): (string?, number)
	local training = data.Training
	if training.Stamp == 0 or now < training.Stamp then
		training.Stamp = now
		return nil, 0
	end
	local owned = if trainee then data.Voidkin[trainee] else nil
	if owned == nil or Profile.RoleOf(data, owned.Id) == "Worker" then
		training.Stamp = now
		return nil, 0
	end
	local gained, left = Training.Gain(owned, now - training.Stamp)
	training.Stamp = now - left
	return owned.Id, gained
end

return Training
