--!strict
-- Drops (pure rules): what an enemy's fall gives one player whose lead hit it, written into their save in one step
-- (docs/design.md, "The world, in grey"; docs/decisions.md, D01). Credits, the lead's experience, a chance at the ground's
-- Standard shard, and on the account's first kill, Watt's Named shard; a chest by Rules.Chests.Dropped (TR27); forge
-- stones of the ground's grade and, from an elite or a keeper, a War Emblem (TR47). The server decides the fall and the
-- rolls; this only writes them. No Roblox API: it runs with Studio closed.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local DropsConfig = require(Shared.Config.Drops)
local GrowthConfig = require(Shared.Config.Growth)
local Grounds = require(Shared.Definitions.Grounds)
local Shards = require(Shared.Definitions.Shards)
local Growth = require(Shared.Rules.Growth)
local Chests = require(Shared.Rules.Chests)
local Emblems = require(Shared.Rules.Emblems)
local ChestsConfig = require(Shared.Config.Chests)
local ReinforceConfig = require(Shared.Config.Reinforce)
local EmblemSets = require(Shared.Definitions.Emblems)

local Drops = {}

Drops.Unknown = "Unknown" -- an enemy kind that drops nothing, a level out of range, a ground with no Standard shard, or a bad roll

-- Each ground's Standard shard, by ground id.
local standard: { [string]: string } = {}
for _, row in Shards.List do
	if row.Grade == "Standard" then
		standard[row.Ground] = row.Id
	end
end

local function round(x: number): number
	return math.floor(x + 0.5)
end

export type Drop = {
	Credits: number,
	Xp: number,
	Shard: string, -- the shard the roll won, or ""
}

-- The server's rolls for a fall's stones and emblem, each in [0, 1) (TR47): Stone, the stone count's fraction; Emblem,
-- whether one drops; Rarity, Set and Stat, which.
export type Loot = { Stone: number, Emblem: number, Rarity: number, Set: number, Stat: number }

-- One line of a kind's loot card (TR10): Kind "Credits", "Xp" or "Shard"; Shard, the shard's id on its line, else "".
export type Line = { Kind: string, Amount: number, Chance: number, Shard: string }

-- The chance a kind of enemy drops its ground's Standard shard, as Roll draws it: ShardChance times its share, at most 1.
function Drops.Chance(kind: string): number
	local share = DropsConfig.Share[kind]
	return if share then math.min(1, DropsConfig.ShardChance * share) else 0
end

-- What a kind of enemy at `level` in ground `ground` drops for a `roll` in [0, 1), or nil and why not. Pure: nothing is
-- written. The first kill's shard is added by Give, which knows the save.
function Drops.Roll(kind: any, level: any, ground: any, roll: any): (Drop?, string?)
	local share = if type(kind) == "string" then DropsConfig.Share[kind] else nil
	local valid = type(level) == "number" and level == math.floor(level) and level >= 1 and level <= GrowthConfig.MaxLevel
	local shard = if type(ground) == "string" and Grounds.ById[ground] then standard[ground] else nil
	if share == nil or not valid or shard == nil or type(roll) ~= "number" or not (roll >= 0 and roll < 1) then
		return nil, Drops.Unknown
	end
	local g = Growth.G(level)
	local drop: Drop = {
		Credits = round(DropsConfig.CreditsPerKillPerG * g * share),
		Xp = round(GrowthConfig.XpPerKillPerG * g * share),
		Shard = if roll < Drops.Chance(kind) then shard else "",
	}
	return drop, nil
end

-- The grade of forge stone a ground's falls drop (Config.Drops.GroundsAGrade).
function Drops.StoneGrade(ground: string): string
	local row = Grounds.ById[ground]
	local order = if row then row.Order else 1
	local grades = ReinforceConfig.Grades
	return grades[math.clamp(math.ceil(order / DropsConfig.GroundsAGrade), 1, #grades)]
end

-- How many stones a kind's fall drops for `roll`: StoneChance x its share, the whole part sure, the rest a chance.
function Drops.Stones(kind: string, roll: number): number
	local share = DropsConfig.Share[kind]
	if share == nil then
		return 0
	end
	local mean = DropsConfig.StoneChance * share
	local whole = math.floor(mean)
	return whole + (if roll < mean - whole then 1 else 0)
end

-- The emblem rarities' weights for a kind's fall in a ground, Uncommon to Legendary: its chest ladder row, Common counted
-- as Uncommon. Empty for a kind that drops none.
function Drops.EmblemWeights(kind: string, ground: string): { [string]: number }
	local tier = DropsConfig.EmblemTier[kind]
	if tier == nil then
		return {}
	end
	local row = Grounds.ById[ground]
	local step = math.clamp((if row then row.Order else 1) + tier - 1, 1, #ChestsConfig.Ladder)
	local weights = ChestsConfig.Ladder[step]
	return { Uncommon = weights[1] + weights[2], Rare = weights[3], Epic = weights[4], Legendary = weights[5] }
end

-- The emblem a kind's fall drops for `loot`'s rolls, or nil.
function Drops.Emblem(kind: string, ground: string, loot: Loot): string?
	if not (loot.Emblem < (DropsConfig.EmblemChance[kind] or 0)) then
		return nil
	end
	local weights = Drops.EmblemWeights(kind, ground)
	local total = 0
	for _, rarity in { "Uncommon", "Rare", "Epic", "Legendary" } do
		total += weights[rarity] or 0
	end
	local at, rarity = loot.Rarity * total, "Uncommon"
	for _, name in { "Uncommon", "Rare", "Epic", "Legendary" } do
		local weight = weights[name] or 0
		if weight > 0 then
			rarity = name
			if at < weight then
				break
			end
			at -= weight
		end
	end
	local sets = EmblemSets.ByRarity[rarity]
	local stats = table.clone(EmblemSets.Stats)
	if rarity == "Epic" or rarity == "Legendary" then
		table.move(EmblemSets.HighStats, 1, #EmblemSets.HighStats, #stats + 1, stats)
	end
	local set = sets[math.clamp(math.floor(loot.Set * #sets) + 1, 1, #sets)]
	local stat = stats[math.clamp(math.floor(loot.Stat * #stats) + 1, 1, #stats)]
	local key = Emblems.Key(set.Id, stat)
	return if Emblems.Parse(key) then key else nil
end

-- What a kind of enemy at `level` in ground `ground` drops, each line with its chance, for the card shown while it's down
-- (TR10): Roll's own numbers, never copied into the UI. Credits go to every player whose lead hit it, the experience to
-- their lead. Empty when Roll would give nothing.
function Drops.Card(kind: any, level: any, ground: any): { Line }
	local drop = Drops.Roll(kind, level, ground, 0)
	if drop == nil then
		return {}
	end
	return {
		{ Kind = "Credits", Amount = drop.Credits, Chance = 1, Shard = "" },
		{ Kind = "Xp", Amount = drop.Xp, Chance = 1, Shard = "" },
		{ Kind = "Shard", Amount = 1, Chance = Drops.Chance(kind), Shard = drop.Shard },
	}
end

-- The fall written into one player's save: Credits, the lead's experience (levels as far as it goes), the shard the roll
-- won, on the account's first kill, Config.Drops.First, and the chest `chestRoll` drops (Rules.Chests.Dropped; the sure one
-- needs no roll), and with `loot`'s rolls, its stones and emblem (TR47). { Ok, Credits, Xp, Levels, Shard, First, Chest,
-- Stone, Stones, Emblem, Kills } where Shard, First, Chest, Stone and Emblem are "" when nothing dropped. A player without
-- a lead still gets the rest.
function Drops.Give(data: Profile.Data, kind: any, level: any, ground: any, roll: any, chestRoll: number?, loot: Loot?): { [string]: any }
	local drop, problem = Drops.Roll(kind, level, ground, roll)
	if drop == nil then
		return { Ok = false, Error = problem }
	end
	data.Currency.Credits += drop.Credits
	local lead = data.Voidkin[data.Roles.Lead]
	local levels = if lead then Growth.AddXp(lead, drop.Xp) else 0
	local bag = data.Bag.Shards
	if drop.Shard ~= "" then
		bag[drop.Shard] = (bag[drop.Shard] or 0) + 1
	end
	local first = ""
	if data.Progress.Kills == 0 then
		first = DropsConfig.First
		bag[first] = (bag[first] or 0) + 1
	end
	local chest = Chests.Dropped(kind, ground, data.Progress.Kills, chestRoll)
	if chest then
		Chests.Grant(data, chest, 1)
	end
	local stone, stones, emblem = "", 0, ""
	if loot then
		stones = Drops.Stones(kind, loot.Stone)
		if stones > 0 then
			stone = Drops.StoneGrade(ground)
			data.Bag.Stones[stone] = (data.Bag.Stones[stone] or 0) + stones
		end
		emblem = Drops.Emblem(kind, ground, loot) or ""
		if emblem ~= "" then
			data.Bag.Emblems[emblem] = (data.Bag.Emblems[emblem] or 0) + 1
		end
	end
	data.Progress.Kills += 1
	return {
		Ok = true,
		Credits = drop.Credits,
		Xp = if lead then drop.Xp else 0,
		Levels = levels,
		Shard = drop.Shard,
		First = first,
		Chest = chest or "",
		Stone = stone,
		Stones = stones,
		Emblem = emblem,
		Kills = data.Progress.Kills,
	}
end

return Drops
