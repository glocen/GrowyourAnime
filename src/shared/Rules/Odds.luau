--!strict
-- Odds (shared, pure): who a shard can hold, the chance of each, and one roll against them (docs/design.md, "Shards and the
-- Void Breaker"). The same table is shown to the player before the break (docs/roblox-rules.md) and rolled by the server.
-- It follows tools/balance/sim.py's pool() exactly, so the game and the simulation read one rule:
--   a shard holds the Voidkin whose Zone is at most its ground's; a grade weighs each rarity (Config.Shards.Pools), a tier
--   nobody there reaches is dropped; a Voidkin of the ground or the one before weighs Config.Shards.FeaturedWeight against
--   older ones of its tier; luck lifts the top two tiers that can drop (only the top one when two can, none when one can).
-- Nothing above Definitions.Rarity.ObtainableTop is ever in a table. No Roblox API: it runs with Studio closed.
-- Odds.Rates is the same table as the player reads it, "Drop rates" (the director, 2026-11-15; docs/ui.md, screen 3).

local Shared = game:GetService("ReplicatedStorage").Shared
local ShardConfig = require(Shared.Config.Shards)
local Shards = require(Shared.Definitions.Shards)
local Grounds = require(Shared.Definitions.Grounds)
local Voidkin = require(Shared.Definitions.Voidkin)
local Rarity = require(Shared.Definitions.Rarity)

export type Entry = { Id: string, Chance: number }
export type Rate = { Id: string, Chance: number, Parts: number }
export type Group = { Rarity: string, Chance: number, Parts: number, Rates: { Rate } }

local Odds = {}

-- What 100% is in parts: a part is a hundredth of a percent.
Odds.Parts = 10000

-- Every Voidkin the shard can give with its chance, rarest tier last, roster order inside a tier. Chances sum to 1.
-- `luck` is clamped to 0..Config.Shards.LuckCap. An unknown shard gives an empty table.
function Odds.Table(shardId: string, luck: number?): { Entry }
	local shard = Shards.ById[shardId]
	if not shard then
		return {}
	end
	if shard.Holds ~= "" then
		return { { Id = shard.Holds, Chance = 1 } }
	end
	local ground = Grounds.ById[shard.Ground]
	local weights = ShardConfig.Pools[shard.Grade]
	if not ground or not weights then
		return {}
	end
	local top = Rarity.Rank[Rarity.ObtainableTop]
	local byTier: { [string]: { Voidkin.Row } } = {}
	for _, row in Voidkin.List do
		local rank = Rarity.Rank[row.Rarity]
		if row.Zone <= ground.Order and rank and rank <= top then
			local tier = byTier[row.Rarity] or {}
			table.insert(tier, row)
			byTier[row.Rarity] = tier
		end
	end
	local live: { string } = {}
	local tierWeight: { [string]: number } = {}
	local total = 0
	for _, name in Rarity.Order do
		local weight = weights[name] or 0
		if byTier[name] and weight > 0 then
			table.insert(live, name)
			tierWeight[name] = weight
		end
	end
	local lift = math.clamp(luck or 0, 0, ShardConfig.LuckCap)
	local lifted = if #live > 2 then 2 elseif #live == 2 then 1 else 0
	for index = #live - lifted + 1, #live do
		tierWeight[live[index]] *= 1 + lift
	end
	for _, name in live do
		total += tierWeight[name]
	end
	local entries: { Entry } = {}
	for _, name in live do
		local tier = byTier[name]
		local featured: { number } = {}
		local tierTotal = 0
		for index, row in tier do
			featured[index] = if row.Zone >= ground.Order - 1 then ShardConfig.FeaturedWeight else 1
			tierTotal += featured[index]
		end
		for index, row in tier do
			table.insert(entries, { Id = row.Id, Chance = tierWeight[name] / total * featured[index] / tierTotal })
		end
	end
	return entries
end

-- How many of a shard's tiers luck lifts: its top two, its top one when it has two, none when it has one (a Named shard,
-- or a ground whose Voidkin all share a tier). Infusion is offered only where this is above 0.
function Odds.Lifted(shardId: string): number
	local tiers: { [string]: boolean } = {}
	local count = 0
	for _, entry in Odds.Table(shardId, 0) do
		local rarity = Voidkin.ById[entry.Id].Rarity
		if not tiers[rarity] then
			tiers[rarity] = true
			count += 1
		end
	end
	return if count > 2 then 2 elseif count == 2 then 1 else 0
end

-- A shard's drop rates as the player reads them: Odds.Table grouped by rarity, the commonest first, roster order inside. Each
-- chance is also whole Parts, rounded by largest remainder, so the rows shown add to exactly 100% and a rarity's total
-- is the sum of its rows. A Voidkin that can drop never shows as none.
function Odds.Rates(shardId: string, luck: number?): { Group }
	local entries = Odds.Table(shardId, luck)
	local parts: { number } = {}
	local rest: { number } = {}
	local given = 0
	for index, entry in entries do
		local scaled = entry.Chance * Odds.Parts
		local whole = math.floor(scaled + 1e-6)
		rest[index] = scaled - whole
		if whole == 0 and entry.Chance > 0 then
			whole, rest[index] = 1, -1
		end
		parts[index] = whole
		given += whole
	end
	while #entries > 0 and given < Odds.Parts do -- one part each to the largest remainders
		local best = 1
		for index = 2, #entries do
			if rest[index] > rest[best] then
				best = index
			end
		end
		parts[best] += 1
		rest[best] -= 1
		given += 1
	end
	while given > Odds.Parts do -- only after a row was raised to its one part: off the largest row
		local best = 1
		for index = 2, #entries do
			if parts[index] > parts[best] then
				best = index
			end
		end
		parts[best] -= 1
		given -= 1
	end
	local groups: { Group } = {}
	for index, entry in entries do
		local rarity = Voidkin.ById[entry.Id].Rarity
		local group = groups[#groups]
		if group == nil or group.Rarity ~= rarity then
			group = { Rarity = rarity, Chance = 0, Parts = 0, Rates = {} }
			table.insert(groups, group)
		end
		group.Chance += entry.Chance
		group.Parts += parts[index]
		table.insert(group.Rates, { Id = entry.Id, Chance = entry.Chance, Parts = parts[index] })
	end
	return groups
end

-- Parts as a percentage, to the hundredth they hold and no further: 6000 is "60%", 675 is "6.75%".
function Odds.Percent(parts: number): string
	local text = string.gsub(string.format("%.2f", parts / 100), "%.?0+$", "")
	return `{text}%`
end

-- The Voidkin one roll gives, for `u` in [0, 1) from the server's random source. Nil for a shard with nothing in it.
function Odds.Roll(shardId: string, luck: number?, u: number): string?
	local entries = Odds.Table(shardId, luck)
	local reached = 0
	for _, entry in entries do
		reached += entry.Chance
		if u < reached then
			return entry.Id
		end
	end
	local last = entries[#entries] -- the sum can fall a hair short of 1 in floating point
	return if last then last.Id else nil
end

return Odds
