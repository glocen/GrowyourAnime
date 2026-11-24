--!strict
-- Price (shared, pure): what one point of a stat is worth in Combat Power before its scale, at the generic row (no
-- Main): a Battle Attribute's weight, an attribute's conversion row weighed (the rework's part 2, "A line's price").
-- A gear line and a jewel are priced by it, so every colour and every line of one budget are worth the same (TR56).
-- Its own module so the resolver's sources can read it without a cycle (Rules.Chests requires Rules.Stats).
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)

local Price = {}

function Price.Of(stat: string): number
	local weights = StatsConfig.Power.Weights
	local row = StatsConfig.Attributes.Convert[stat]
	if row then
		local price = 0
		for into, rate in row do
			price += rate * (weights[into] or 0)
		end
		return price
	end
	return weights[stat] or 0
end

return Price
