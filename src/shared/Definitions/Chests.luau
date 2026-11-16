--!strict
-- Chests (shared, content): each ground's chests, one row a tier (docs/engineering-plan.md, "Chests"; the rework's part
-- 11). A chest is named for its ground and tier, and its table rolls the item when it's opened (Rules.Chests). The bag
-- holds them as counts by Id (Profile.Bag.Chests), so identical chests stack.
--   Tier 1  a Shade's
--   Tier 2  an elite's, and a keeper's after its first win
--   Tier 3  a keeper's first win
--   Tier 4  the Tower's, a hard floor's: its own rarity row (Config.Chests.Tower), not the ladder's
-- The tier names are the builder's, for research (TR27). No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Grounds = require(Shared.Definitions.Grounds)

export type Row = { Id: string, Ground: string, Tier: number, Name: string }

-- Named for what drops it, never a rarity's word (docs/design.md, "Chests"): a chest isn't a rarity.
local TIERS = { "Shade Chest", "Elite Chest", "Keeper's Chest", "Tower Chest" }

local List: { Row } = {}
local ById: { [string]: Row } = {}
for _, ground in Grounds.List do
	for tier, said in TIERS do
		local row = { Id = `{ground.Id}_{tier}`, Ground = ground.Id, Tier = tier, Name = `{said} of {ground.Name}` }
		table.insert(List, row)
		ById[row.Id] = row
	end
end

-- The chest of `ground` at `tier`, or nil.
local function Of(ground: string, tier: number): Row?
	return ById[`{ground}_{tier}`]
end

return {
	List = List,
	ById = ById,
	Of = Of,
	Tiers = #TIERS,
	Tower = 4, -- the Tower's tier
}
