--!strict
-- Rarity (shared, content): the tiers in order, lowest first. Limited and the tiers above Mythical come in updates, so
-- nothing past ObtainableTop can come from a roll at launch (docs/engineering-plan.md, "Transactions"): Rules.Odds refuses it.

local order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

local rank: { [string]: number } = {}
for index, name in order do
	rank[name] = index
end

return {
	Order = order,
	Rank = rank, -- 1 for Common up
	ObtainableTop = "Mythical",
}
