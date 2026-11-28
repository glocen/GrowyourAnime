--!strict
-- Drops (pure rules): what an enemy's fall gives one player whose lead hit it, written into their save in one step
-- (docs/design.md, "The world, in grey"; docs/decisions.md, D01). Credits, the lead's experience, a chance at the ground's
-- Standard shard, and on the account's first kill, Watt's Named shard; a chest by Rules.Chests.Dropped (TR27); forge
-- stones of the ground's grade and, from an elite or a keeper, an Emblem Case (TR47; TR56: the case replaced the loose
-- emblem). The server decides the fall and the rolls; this only writes them. No Roblox API: it runs with Studio closed.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local DropsConfig = require(Shared.Config.Drops)
local GrowthConfig = require(Shared.Config.Growth)
local Grounds = require(Shared.Definitions.Grounds)
local Shards = require(Shared.Definitions.Shards)
local Growth = require(Shared.Rules.Growth)
local Mastery = require(Shared.Rules.Mastery)
local Chests = require(Shared.Rules.Chests)
local ChestsConfig = require(Shared.Config.Chests)
local ReinforceConfig = require(Shared.Config.Reinforce)
local ChestRows = require(Shared.Definitions.Chests)
local Goals = require(Shared.Rules.Goals)

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
-- whether an Emblem Case drops (its emblem is rolled when it's opened, TR56); Pouch and Crate, whether a Hard keeper's
-- win gives a Jewel Pouch and a Forge Crate (Rules.Progress; none: sure). Rarity, Set and Stat are no longer read: the
-- case rolls its own.
export type Loot = { Stone: number, Emblem: number, Rarity: number, Set: number, Stat: number, Pouch: number?, Crate: number? }

-- Where a fall stood (TR48): a stage on Normal or Hard (Stage 0 for none), which sets its stones' rate and its chest.
export type Place = { Difficulty: string, Stage: number }

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

-- How many stones a kind's fall on `difficulty` (Normal when nil) drops for `roll`: StoneChance x its share, the whole
-- part sure, the rest a chance.
function Drops.Stones(kind: string, roll: number, difficulty: string?): number
	local share = DropsConfig.Share[kind]
	local chance = DropsConfig.StoneChance[difficulty or "Normal"]
	if share == nil or chance == nil then
		return 0
	end
	local mean = chance * share
	local whole = math.floor(mean)
	return whole + (if roll < mean - whole then 1 else 0)
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

-- The fall written into one player's save: Credits, the lead's experience (levels as far as it goes, with Growth.CatchUp's
-- bonus when it's far behind), the shard the roll won, on the account's first kill, Config.Drops.First, and the chest
-- `chestRoll` drops (Rules.Chests.Dropped; the sure one needs no roll), and with `loot`'s rolls, its stones and an
-- elite's Emblem Case (TR47; TR56), at `place`'s difficulty and from its stage's chests (TR48; Normal when nil); the case
-- stands for the elite's own chest. A keeper's case comes with its win (Rules.Progress.KeeperWon), never here.
-- The lead also earns its kind's Mastery (Rules.Mastery; TR76), never multiplied.
-- { Ok, Credits, Xp, Levels, Mastery, Ranks, Shard, First, Chest, Stone, Stones, Case, Kills } where Shard, First, Chest, Stone and
-- Case are "" when nothing dropped. A player without a lead still gets the rest.
function Drops.Give(data: Profile.Data, kind: any, level: any, ground: any, roll: any, chestRoll: number?, loot: Loot?, place: Place?): { [string]: any }
	local drop, problem = Drops.Roll(kind, level, ground, roll)
	if drop == nil then
		return { Ok = false, Error = problem }
	end
	data.Currency.Credits += drop.Credits
	local lead = data.Voidkin[data.Roles.Lead]
	local xp = if lead then round(drop.Xp * Growth.CatchUp(data, lead)) else 0 -- a lead far behind earns faster (TR72, item 3)
	local levels = if lead then Growth.AddXp(lead, xp) else 0
	local mastery = if lead then Mastery.Earned(kind) else 0
	local ranks = if lead then Mastery.Add(lead, mastery) else 0
	Goals.Note(data, "LevelUp", levels) -- today's "raise a Voidkin a level" (TR54)
	local bag = data.Bag.Shards
	if drop.Shard ~= "" then
		bag[drop.Shard] = (bag[drop.Shard] or 0) + 1
	end
	local first = ""
	if data.Progress.Kills == 0 then
		first = DropsConfig.First
		bag[first] = (bag[first] or 0) + 1
	end
	local difficulty = if place then place.Difficulty else "Normal"
	local chest = Chests.Dropped(kind, ground, data.Progress.Kills, chestRoll, difficulty, if place then place.Stage else nil)
	if chest then
		Chests.Grant(data, chest, 1)
	end
	local stone, stones, case = "", 0, ""
	if loot then
		stones = Drops.Stones(kind, loot.Stone, difficulty)
		if stones > 0 then
			stone = Drops.StoneGrade(ground)
			data.Bag.Stones[stone] = (data.Bag.Stones[stone] or 0) + stones
		end
		local fall = ChestsConfig.Drop[kind]
		local own = if fall and kind ~= "Keeper" then ChestRows.Of(ground, fall.Tier, difficulty, if place then place.Stage else nil) or ChestRows.Of(ground, fall.Tier) else nil
		case = Chests.Case(if own then own.Id else nil, loot.Emblem, DropsConfig.EmblemChance[kind] or 0) or ""
		if case ~= "" then
			Chests.Grant(data, case, 1)
		end
	end
	data.Progress.Kills += 1
	return {
		Ok = true,
		Credits = drop.Credits,
		Xp = xp,
		Levels = levels,
		Mastery = mastery,
		Ranks = ranks,
		Shard = drop.Shard,
		First = first,
		Chest = chest or "",
		Stone = stone,
		Stones = stones,
		Case = case,
		Kills = data.Progress.Kills,
	}
end

return Drops
