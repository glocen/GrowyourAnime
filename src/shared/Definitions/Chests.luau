--!strict
-- Chests (shared, content): every chest, one row each (docs/engineering-plan.md, "Chests"; the rework's part 11; TR56).
-- A chest is named for its kind and, where it has one, its ground, and its table rolls what it holds when it's opened
-- (Rules.Chests). The bag holds them as counts by Id (Profile.Bag.Chests), so identical chests stack. Seven kinds, by
-- tier (docs/design.md, "The family at launch"):
--   Tier 1  a Shade's
--   Tier 2  an elite's, and a keeper's after its first win
--   Tier 3  a keeper's first win
--   Tier 4  the Tower's, a hard floor's: its own rarity row (Config.Chests.Tower), not the ladder's
--   Tier 5  an Emblem Case: one War Emblem, its rarity as the gear chest it stands for (Of) rolls; the Tower's cases one
--           rarity each (Rarity)
--   Tier 6  a Jewel Pouch: one jewel
--   Tier 7  a Forge Crate: forge stones
-- A stage on Hard rolls on its own budget (TR48; D7): its tiers 1 to 3 are its own chests, one a stage, read
-- Config.Chests.Hard.Rows ladder rows past their ground's, and roll their items at the stage's last stop's level on Hard
-- (Config.Stages.Offset), so each stage pays as hard as it fights. Tier 3 only where a keeper ends the stage. Every
-- elite's and keeper's chest has its Emblem Case beside it (CaseOf). The pouch and the crate are the same in every ground.
-- The tier names are the builder's, for research (TR27). No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Grounds = require(Shared.Definitions.Grounds)
local StagesConfig = require(Shared.Config.Stages)
local ChestsConfig = require(Shared.Config.Chests)

-- Difficulty is "Normal" for a ground's own chests and the Tower's, Stage 0; a Hard stage's has its stage and Level.
-- Ground is "" for a chest of no ground (the pouch, the crate, the Tower's cases). Of: a case's gear chest; Rarity: a
-- Tower case's one rarity.
export type Row = {
	Id: string,
	Ground: string,
	Tier: number,
	Name: string,
	Image: string,
	Difficulty: string,
	Stage: number,
	Level: number?,
	Of: string?,
	Rarity: string?,
}

-- Named for what drops it or what it holds, never a rarity's word (docs/design.md, "Chests"): a chest isn't a rarity.
local KINDS = { "Shade Chest", "Elite Chest", "Keeper's Chest", "Tower Chest", "Emblem Case", "Jewel Pouch", "Forge Crate" }
-- Each kind's picture in Config.UIKit.Images (AR21; build/handoff/UI/chests/chest_icons.json), the same in every ground.
local PICTURES = { "ChestShade", "ChestElite", "ChestKeeper", "ChestTower", "ChestCase", "ChestPouch", "ChestCrate" }
local CASE, POUCH, CRATE = 5, 6, 7

local List: { Row } = {}
local ById: { [string]: Row } = {}
local KeeperStage: { [string]: number } = {} -- the stage a keeper ends, by ground
local function add(row: Row)
	table.insert(List, row)
	ById[row.Id] = row
end
-- A gear chest, and for an elite's or a keeper's its Emblem Case, named as it is.
local function gear(row: Row, where: string)
	add(row)
	if row.Tier == 2 or row.Tier == 3 then
		add({
			Id = `{row.Id}_case`,
			Ground = row.Ground,
			Tier = CASE,
			Name = `{KINDS[CASE]} of {where}`,
			Image = PICTURES[CASE],
			Difficulty = row.Difficulty,
			Stage = row.Stage,
			Level = row.Level,
			Of = row.Id,
		})
	end
end
for _, ground in Grounds.List do
	for tier = 1, 4 do
		local said = KINDS[tier]
		gear({ Id = `{ground.Id}_{tier}`, Ground = ground.Id, Tier = tier, Name = `{said} of {ground.Name}`, Image = PICTURES[tier], Difficulty = "Normal", Stage = 0 }, ground.Name)
	end
	for stage, row in StagesConfig.Grounds[ground.Id] or {} do
		local last = row.Stops[#row.Stops]
		if last.Kind == "Keeper" then
			KeeperStage[ground.Id] = stage
		end
		local where = `{ground.Name}, Hard Stage {stage}`
		for tier = 1, if last.Kind == "Keeper" then 3 else 2 do
			gear({
				Id = `{ground.Id}_{tier}_hard{stage}`,
				Ground = ground.Id,
				Tier = tier,
				Name = `{KINDS[tier]} of {where}`,
				Image = PICTURES[tier],
				Difficulty = "Hard",
				Stage = stage,
				Level = last.Level + (StagesConfig.Offset.Hard or 0),
			}, where)
		end
	end
end
-- The Tower's cases, one a rarity it gives (Config.Chests.Case.Tower).
local towerRarities: { string } = {}
local tower = ChestsConfig.Case.Tower
for _, rarity in tower.By do
	if table.find(towerRarities, rarity) == nil then
		table.insert(towerRarities, rarity)
	end
end
for _, rarity in { tower.Past, tower.Top } do
	if table.find(towerRarities, rarity) == nil then
		table.insert(towerRarities, rarity)
	end
end
for _, rarity in towerRarities do
	add({ Id = `towercase_{string.lower(rarity)}`, Ground = "", Tier = CASE, Name = `{KINDS[CASE]} of the Tower`, Image = PICTURES[CASE], Difficulty = "Normal", Stage = 0, Rarity = rarity })
end
add({ Id = "pouch", Ground = "", Tier = POUCH, Name = KINDS[POUCH], Image = PICTURES[POUCH], Difficulty = "Normal", Stage = 0 })
add({ Id = "crate", Ground = "", Tier = CRATE, Name = KINDS[CRATE], Image = PICTURES[CRATE], Difficulty = "Normal", Stage = 0 })

-- The gear chest of `ground` at `tier`, or nil: on Hard, its `stage`'s own (TR48).
local function Of(ground: string, tier: number, difficulty: string?, stage: number?): Row?
	if difficulty == "Hard" then
		return ById[`{ground}_{tier}_hard{stage or 0}`]
	end
	return ById[`{ground}_{tier}`]
end

-- The Emblem Case that rolls as gear chest `id`, or nil.
local function CaseOf(id: string?): Row?
	return if id then ById[`{id}_case`] else nil
end

-- The Tower's case of `rarity`, or nil.
local function TowerCase(rarity: string): Row?
	return ById[`towercase_{string.lower(rarity)}`]
end

return {
	List = List,
	ById = ById,
	Of = Of,
	CaseOf = CaseOf,
	TowerCase = TowerCase,
	KeeperStage = KeeperStage,
	Kinds = KINDS, -- each tier's kind, as its cell and card say it
	Tiers = 4, -- the gear chests' tiers
	Tower = 4, -- the Tower's tier
	Case = CASE, -- the kinds past gear's, by tier
	Pouch = POUCH,
	Crate = CRATE,
	PouchId = "pouch", -- the one pouch and the one crate
	CrateId = "crate",
}
