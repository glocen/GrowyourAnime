--!strict
-- Growth (shared, pure): the curve G(level) every size follows, and experience: what a kill gives and what a level takes
-- (docs/balance.md, "Growth", "Pace"). Experience is whole numbers. No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local GrowthConfig = require(Shared.Config.Growth)
local Grounds = require(Shared.Definitions.Grounds)
local Profile = require(Shared.Data.Profile)

local Growth = {}

local function round(x: number): number
	return math.floor(x + 0.5)
end

function Growth.G(level: number): number
	local n = level - 1
	return 1 + GrowthConfig.A * n + GrowthConfig.B * n * n
end

-- The ground whose levels hold `level` (its order), the last one past the end.
function Growth.GroundOf(level: number): number
	for index, row in Grounds.List do
		if level <= row.LevelTo then
			return index
		end
	end
	return #Grounds.List
end

function Growth.KillsPerLevel(level: number): number
	local index = Growth.GroundOf(level)
	local row = Grounds.List[index]
	return GrowthConfig.PaceHours[index] * GrowthConfig.KillsPerHour / (row.LevelTo - row.LevelFrom + 1)
end

-- Experience one kill gives, for an enemy of `level`.
function Growth.XpPerKill(level: number): number
	return round(GrowthConfig.XpPerKillPerG * Growth.G(level))
end

-- Experience from `level` to the next, or nil at the last level.
function Growth.XpToNext(level: number): number?
	if level >= GrowthConfig.MaxLevel then
		return nil
	end
	return round(Growth.KillsPerLevel(level) * Growth.XpPerKill(level))
end

-- Adds experience to an owned Voidkin and raises its level as far as it goes. Returns the levels gained. At the last
-- level, experience isn't kept.
function Growth.AddXp(owned: Profile.OwnedVoidkin, amount: number): number
	if not (amount > 0) or amount == math.huge then
		return 0
	end
	owned.Xp += round(amount)
	local gained = 0
	while true do
		local need = Growth.XpToNext(owned.Level)
		if need == nil then
			owned.Xp = 0
			break
		end
		if owned.Xp < need then
			break
		end
		owned.Xp -= need
		owned.Level += 1
		gained += 1
	end
	return gained
end

return Growth
