--!strict
-- Mastery (shared, pure): a Voidkin's Mastery, ranks 0 to 5, earned by leading it (docs/design.md, "Voidkin", "Growing a
-- Voidkin"; TR76). The save keeps its experience in all (OwnedVoidkin.Mastery, nil for none), so a rank is read from it
-- and never stored apart: the two can't disagree.
--   Mastery.Xp(owned) -> number                       its experience in all
--   Mastery.Rank(xp) -> number                        the rank that experience holds, 0 to the last
--   Mastery.Next(xp) -> (number?, number?)            the experience the next rank takes in all, and still to go; nil at the last
--   Mastery.Points(rank, level) -> number             the points a rank adds to its class's Main at `level` (Rules.Stats)
--   Mastery.Earned(kind) -> number                    what one fall of `kind` or one win (Warden, Bout) gives the lead
--   Mastery.Add(owned, amount) -> number              adds experience; the ranks it gained
-- Experience past the last rank isn't kept. Only the lead earns it, and nothing multiplies it: no catch-up, no bucket.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local MasteryConfig = require(Shared.Config.Mastery)
local GrowthConfig = require(Shared.Config.Growth)
local Profile = require(Shared.Data.Profile)
local Growth = require(Shared.Rules.Growth)

local Mastery = {}

local function whole(x: any): number
	return if type(x) == "number" and x == x and x > 0 and x ~= math.huge then math.floor(x) else 0
end

function Mastery.Xp(owned: Profile.OwnedVoidkin): number
	return whole(owned.Mastery)
end

function Mastery.Rank(xp: number): number
	local rank = 0
	for index, need in MasteryConfig.Ranks do
		if xp >= need then
			rank = index
		end
	end
	return rank
end

function Mastery.Next(xp: number): (number?, number?)
	local need = MasteryConfig.Ranks[Mastery.Rank(xp) + 1]
	if need == nil then
		return nil, nil
	end
	return need, need - xp
end

function Mastery.Points(rank: number, level: number): number
	local points = MasteryConfig.Points[math.min(rank, #MasteryConfig.Points)]
	if points == nil or not (rank >= 1) then
		return 0
	end
	return points * Growth.G(math.clamp(level, 1, GrowthConfig.MaxLevel))
end

function Mastery.Earned(kind: any): number
	return if type(kind) == "string" then MasteryConfig.Gain[kind] or 0 else 0
end

function Mastery.Add(owned: Profile.OwnedVoidkin, amount: number): number
	local before = Mastery.Xp(owned)
	local last = MasteryConfig.Ranks[#MasteryConfig.Ranks]
	local add = whole(amount)
	if add == 0 or before >= last then
		return 0
	end
	local after = math.min(before + add, last)
	owned.Mastery = after
	return Mastery.Rank(after) - Mastery.Rank(before)
end

return Mastery
