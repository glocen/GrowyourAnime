--!strict
-- Drops (pure rules): what an enemy's fall gives one player whose lead hit it, written into their save in one step
-- (docs/design.md, "The world, in grey"; docs/decisions.md, D01). Credits, the lead's experience, a chance at the ground's
-- Standard shard, and on the account's first kill, Watt's Named shard. The server decides the fall and the roll; this only
-- writes them. No Roblox API: it runs with Studio closed.

local Shared = script.Parent.Parent
local Profile = require(Shared.Data.Profile)
local DropsConfig = require(Shared.Config.Drops)
local GrowthConfig = require(Shared.Config.Growth)
local Grounds = require(Shared.Definitions.Grounds)
local Shards = require(Shared.Definitions.Shards)
local Growth = require(Shared.Rules.Growth)

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
-- won, and on the account's first kill, Config.Drops.First. { Ok, Credits, Xp, Levels, Shard, First, Kills } where Shard
-- and First are "" when nothing dropped. A player without a lead still gets the rest.
function Drops.Give(data: Profile.Data, kind: any, level: any, ground: any, roll: any): { [string]: any }
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
	data.Progress.Kills += 1
	return {
		Ok = true,
		Credits = drop.Credits,
		Xp = if lead then drop.Xp else 0,
		Levels = levels,
		Shard = drop.Shard,
		First = first,
		Kills = data.Progress.Kills,
	}
end

return Drops
