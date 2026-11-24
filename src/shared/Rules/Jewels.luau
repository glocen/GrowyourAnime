--!strict
-- Jewels (shared, pure): what a jewel is and gives (TR56; docs/design.md, "Jewels"; Config.Jewels). A jewel is a key,
-- "Colour:tier", never an owned row, so identical ones stack in the bag (Bag.Jewels); in an item, its colour's slot holds
-- its tier (OwnedItem.Jewels). A jewel's points are flat points of its colour's attribute, priced like a gear line, so
-- every colour of a tier is worth the same Combat Power (Rules.Price).
--   Jewels.Key(colour, tier)     a jewel's key
--   Jewels.Parse(key)            its colour and tier, or nil when the key names no jewel that can exist
--   Jewels.Points(colour, tier)  the attribute it gives and how many points, or nil
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Jewels)
local Price = require(Shared.Rules.Price)

local Jewels = {}

function Jewels.Key(colour: string, tier: number): string
	return `{colour}:{tier}`
end

function Jewels.Parse(key: any): (string?, number?)
	if type(key) ~= "string" then
		return nil, nil
	end
	local colour, tier = string.match(key, "^(%a+):(%d+)$")
	local level = tonumber(tier)
	if colour == nil or Config.Attribute[colour] == nil or level == nil or Config.Worth[level] == nil then
		return nil, nil
	end
	return colour, level
end

function Jewels.Points(colour: string, tier: number): (string?, number)
	local attribute = Config.Attribute[colour]
	local worth = Config.Worth[tier]
	if attribute == nil or worth == nil then
		return nil, 0
	end
	local price = Price.Of(attribute)
	return attribute, if price > 0 then math.max(1, math.floor(Config.TopUnits * worth / price + 0.5)) else 0
end

return Jewels
