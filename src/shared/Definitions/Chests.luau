--!strict
-- Chests (shared, content): each ground's chests, one row a tier (docs/engineering-plan.md, "Chests"; the rework's part
-- 11). A chest is named for its ground and tier, and its table rolls the item when it's opened (Rules.Chests). The bag
-- holds them as counts by Id (Profile.Bag.Chests), so identical chests stack.
--   Tier 1  a Shade's
--   Tier 2  an elite's, and a keeper's after its first win
--   Tier 3  a keeper's first win
--   Tier 4  the Tower's, a hard floor's: its own rarity row (Config.Chests.Tower), not the ladder's
-- A stage on Hard rolls on its own budget (TR48; D7): its tiers 1 to 3 are its own chests, one a stage, read
-- Config.Chests.Hard.Rows ladder rows past their ground's, and roll their items at the stage's last stop's level on Hard
-- (Config.Stages.Offset), so each stage pays as hard as it fights. Tier 3 only where a keeper ends the stage.
-- The tier names are the builder's, for research (TR27). No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Grounds = require(Shared.Definitions.Grounds)
local StagesConfig = require(Shared.Config.Stages)

-- Difficulty is "Normal" for a ground's own chests and the Tower's, Stage 0; a Hard stage's has its stage and Level.
export type Row = { Id: string, Ground: string, Tier: number, Name: string, Image: string, Difficulty: string, Stage: number, Level: number? }

-- Named for what drops it, never a rarity's word (docs/design.md, "Chests"): a chest isn't a rarity.
local TIERS = { "Shade Chest", "Elite Chest", "Keeper's Chest", "Tower Chest" }
-- Each tier's picture in Config.UIKit.Images (AR21; build/handoff/UI/chests/chest_icons.json), the same in every ground.
local PICTURES = { "ChestShade", "ChestElite", "ChestKeeper", "ChestTower" }

local List: { Row } = {}
local ById: { [string]: Row } = {}
local KeeperStage: { [string]: number } = {} -- the stage a keeper ends, by ground
local function add(row: Row)
	table.insert(List, row)
	ById[row.Id] = row
end
for _, ground in Grounds.List do
	for tier, said in TIERS do
		add({ Id = `{ground.Id}_{tier}`, Ground = ground.Id, Tier = tier, Name = `{said} of {ground.Name}`, Image = PICTURES[tier], Difficulty = "Normal", Stage = 0 })
	end
	for stage, row in StagesConfig.Grounds[ground.Id] or {} do
		local last = row.Stops[#row.Stops]
		if last.Kind == "Keeper" then
			KeeperStage[ground.Id] = stage
		end
		for tier = 1, if last.Kind == "Keeper" then 3 else 2 do
			add({
				Id = `{ground.Id}_{tier}_hard{stage}`,
				Ground = ground.Id,
				Tier = tier,
				Name = `{TIERS[tier]} of {ground.Name}, Hard Stage {stage}`,
				Image = PICTURES[tier],
				Difficulty = "Hard",
				Stage = stage,
				Level = last.Level + (StagesConfig.Offset.Hard or 0),
			})
		end
	end
end

-- The chest of `ground` at `tier`, or nil: on Hard, its `stage`'s own (TR48).
local function Of(ground: string, tier: number, difficulty: string?, stage: number?): Row?
	if difficulty == "Hard" then
		return ById[`{ground}_{tier}_hard{stage or 0}`]
	end
	return ById[`{ground}_{tier}`]
end

return {
	List = List,
	ById = ById,
	Of = Of,
	KeeperStage = KeeperStage,
	Tiers = #TIERS,
	Tower = 4, -- the Tower's tier
}
