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
local DropsConfig = require(Shared.Config.Drops)

-- Difficulty is "Normal" for a ground's own chests and the Tower's, Stage 0; a Hard stage's has its stage and Level.
-- Kind: "Gear", "Emblem", "Jewel" or "Stone", what it holds. Word: what its cell calls it. Ground "" and Tier 0 for the
-- Jewel Pouch and the Forge Crate, which hold the same in every ground.
export type Row = {
	Id: string,
	Ground: string,
	Tier: number,
	Name: string,
	Image: string,
	Difficulty: string,
	Stage: number,
	Level: number?,
	Kind: string,
	Word: string,
}

-- Named for what drops it, never a rarity's word (docs/design.md, "Chests"): a chest isn't a rarity.
local TIERS = { "Shade Chest", "Elite Chest", "Keeper's Chest", "Tower Chest" }
-- Each tier's picture in Config.UIKit.Images (AR21; build/handoff/UI/chests/chest_icons.json), the same in every ground.
local PICTURES = { "ChestShade", "ChestElite", "ChestKeeper", "ChestTower" }

local List: { Row } = {} -- the gear chests
local Others: { Row } = {} -- the chests that hold no gear
local ById: { [string]: Row } = {}
local KeeperStage: { [string]: number } = {} -- the stage a keeper ends, by ground
local function add(row: Row)
	table.insert(if row.Kind == "Gear" then List else Others, row)
	ById[row.Id] = row
end
local POUCH, CRATE = "jewel_pouch", "forge_crate"
-- Stand-in pictures from the gear chests' until Modulo's three (launch-design.md, section 5): a case its source's.
add({ Id = POUCH, Ground = "", Tier = 0, Name = "Jewel Pouch", Image = PICTURES[1], Difficulty = "Normal", Stage = 0, Kind = "Jewel", Word = "Jewel Pouch" })
add({ Id = CRATE, Ground = "", Tier = 0, Name = "Forge Crate", Image = PICTURES[1], Difficulty = "Normal", Stage = 0, Kind = "Stone", Word = "Forge Crate" })
local SOURCES = { Elite = "Elite's", Keeper = "Keeper's" }
local function caseId(ground: string, kind: string, difficulty: string?): string
	return `{ground}_case_{string.lower(kind)}{if difficulty == "Hard" then "_hard" else ""}`
end
for _, ground in Grounds.List do
	for tier, said in TIERS do
		add({ Id = `{ground.Id}_{tier}`, Ground = ground.Id, Tier = tier, Name = `{said} of {ground.Name}`, Image = PICTURES[tier], Difficulty = "Normal", Stage = 0, Kind = "Gear", Word = said })
	end
	for _, kind in { "Elite", "Keeper" } do
		local tier = DropsConfig.EmblemTier[kind]
		for _, difficulty in { "Normal", "Hard" } do
			add({
				Id = caseId(ground.Id, kind, difficulty),
				Ground = ground.Id,
				Tier = tier,
				Name = `{SOURCES[kind]} Emblem Case of {ground.Name}{if difficulty == "Hard" then ", Hard" else ""}`,
				Image = PICTURES[tier],
				Difficulty = difficulty,
				Stage = 0,
				Kind = "Emblem",
				Word = "Emblem Case",
			})
		end
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
				Kind = "Gear",
				Word = TIERS[tier],
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

-- The Emblem Case a fall of `kind` ("Elite" or "Keeper") drops in `ground` on `difficulty`, or nil.
local function CaseOf(ground: string, kind: string, difficulty: string?): Row?
	return ById[caseId(ground, kind, difficulty)]
end

return {
	List = List,
	Others = Others,
	ById = ById,
	Of = Of,
	CaseOf = CaseOf,
	Pouch = POUCH,
	Crate = CRATE,
	KeeperStage = KeeperStage,
	Tiers = #TIERS,
	Tower = 4, -- the Tower's tier
}
