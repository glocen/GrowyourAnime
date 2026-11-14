--!strict
-- Stats (shared, pure): the one place a fighter's stats are added up (docs/engineering-plan.md, "The resolver";
-- docs/balance.md, "The one rule"). Every source gives flat points, and the breakdown says which source gave each one:
--   Base     the Voidkin's own Health, Attack and Defence: its rarity and its class times G(level), less the board's part
--   Stars    a share of that own base per star, linear, never of the total; the board's part counted, so it never moves them
--   Level    Regen, from the level alone, less the board's part
--   Board    the skill points spent on each board stat (Rules.Board): the board takes each stat's even part out of Base and
--            Level, so an even spread adds up to the Voidkin without the board
--   Item     each line of the item in each of the preset's slots, as it is
-- Forge ranks, emblems, jewels and research join here as sources when they're built, each a flat line.
-- An enemy's block is its Kind's numbers times G (Stats.Enemy): no sources, nothing worn.
-- Both the server (for truth) and the client (for previews) call it; nothing else adds stats.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local VoidkinConfig = require(Shared.Config.Voidkin)
local GrowthConfig = require(Shared.Config.Growth)
local Voidkin = require(Shared.Definitions.Voidkin)
local Enemies = require(Shared.Definitions.Enemies)
local EnemiesConfig = require(Shared.Config.Enemies)
local Profile = require(Shared.Data.Profile)
local Growth = require(Shared.Rules.Growth)
local Board = require(Shared.Rules.Board)

local Stats = {}

-- Every stat a source may add to. Damage Bonus and Damage Reduction aren't here: they come from effects in a fight only.
Stats.Names = {
	"Health",
	"Attack",
	"Defence",
	"Hit",
	"Dodge",
	"Critical",
	"CriticalResist",
	"Block",
	"Penetration",
	"ElementalAttack",
	"ElementalResist",
	"CriticalDamage",
	"CriticalGuard",
	"Lifesteal",
	"Regen",
}
local KNOWN: { [string]: boolean } = {}
for _, name in Stats.Names do
	KNOWN[name] = true
end

export type Block = {
	Def: string,
	Level: number,
	Type: string,
	Class: string,
	Element: string, -- "" for none: no elemental hit
	Poise: number,
	Health: number,
	Attack: number,
	Defence: number,
	Hit: number,
	Dodge: number,
	Critical: number,
	CriticalResist: number,
	Block: number,
	Penetration: number,
	ElementalAttack: number,
	ElementalResist: number,
	CriticalDamage: number,
	CriticalGuard: number,
	Lifesteal: number,
	Regen: number, -- health a second, always (Config.Stats.Regen)
}

export type Line = { Source: string, Stat: string, Value: number }

-- A block of zeros, with the critical's base extra. Enemies and tests start from it too.
function Stats.Empty(level: number): Block
	return {
		Def = "",
		Level = level,
		Type = "",
		Class = "",
		Element = "",
		Poise = 0,
		Health = 0,
		Attack = 0,
		Defence = 0,
		Hit = 0,
		Dodge = 0,
		Critical = 0,
		CriticalResist = 0,
		Block = 0,
		Penetration = 0,
		ElementalAttack = 0,
		ElementalResist = 0,
		CriticalDamage = StatsConfig.CriticalDamage,
		CriticalGuard = 0,
		Lifesteal = 0,
		Regen = 0,
	}
end

local OWN = { "Health", "Attack", "Defence" }

-- The full stat block of an owned Voidkin wearing `preset` (nil: nothing worn), and where each point came from.
-- `data` holds the items the preset names; an item that isn't there, or a line naming no stat, adds nothing.
function Stats.Resolve(owned: Profile.OwnedVoidkin, preset: Profile.Preset?, data: Profile.Data?): (Block, { Line })
	local row = Voidkin.ById[owned.Def]
	local level = math.clamp(owned.Level, 1, GrowthConfig.MaxLevel)
	local block = Stats.Empty(level)
	local lines: { Line } = {}
	local function add(source: string, stat: string, value: number)
		if KNOWN[stat] and value == value and value ~= 0 then
			(block :: any)[stat] += value
			table.insert(lines, { Source = source, Stat = stat, Value = value })
		end
	end
	if row == nil then
		return block, lines
	end
	block.Def, block.Type, block.Class, block.Element = row.Id, row.Type, row.Class, row.Element
	block.Poise = StatsConfig.Poise[row.Class] or 0
	local g = Growth.G(level)
	local rarity = StatsConfig.Rarity[row.Rarity] or 1
	local shift = StatsConfig.Class[row.Class]
	local stars = math.clamp(owned.Stars, 0, VoidkinConfig.MaxStars)
	for _, stat in OWN do
		local own = StatsConfig.Base[stat] * rarity * (if shift then shift[stat] else 1) * g
		add("Base", stat, math.max(0, own - Board.Taken(stat, level)))
		add("Stars", stat, own * VoidkinConfig.StarShareOfBase * stars)
	end
	-- Regen comes from the level alone, its own source, so the own base's share (stars) never touches it.
	local regen = StatsConfig.Regen
	add("Level", "Regen", math.max(0, regen.Base * (regen.Class[row.Class] or 1) * g - Board.Taken("Regen", level)))
	for _, stat in StatsConfig.Board.Stats do
		add("Board", stat, Board.On(owned, stat) * Board.Gain(stat, level))
	end
	if preset and data then
		for slot, itemId in preset.Slots do
			local item = data.Items[itemId]
			if item then
				for _, itemLine in item.Lines do
					add(`Item:{slot}`, itemLine.Stat, itemLine.Value)
				end
			end
		end
	end
	return block, lines
end

-- An enemy's stat block at `level`: its Kind's numbers in Config.Enemies times G, nothing else. `type` is the spawn's,
-- else the row's. An unknown id gives an empty block at that level.
function Stats.Enemy(def: string, level: number, type: string?): Block
	local row = Enemies.ById[def]
	local clamped = math.clamp(level, 1, GrowthConfig.MaxLevel)
	local block = Stats.Empty(clamped)
	if row == nil then
		return block
	end
	local g = Growth.G(clamped)
	for stat, value in (EnemiesConfig :: any)[row.Kind] :: { [string]: number } do
		if KNOWN[stat] then
			(block :: any)[stat] = value * g
		end
	end
	block.Def, block.Type = row.Id, type or row.Type
	return block
end

-- The preset an owned Voidkin is linked to, or nil.
function Stats.PresetOf(data: Profile.Data, owned: Profile.OwnedVoidkin): Profile.Preset?
	return data.Presets[owned.Preset]
end

-- A rating as a chance: cap x mine / (mine + theirs + K x G(level)). Never reaches its cap; nothing below one point.
function Stats.Chance(cap: number, mine: number, theirs: number, level: number): number
	if not (mine > 0) then
		return 0
	end
	return cap * mine / (mine + math.max(0, theirs) + StatsConfig.RatingK * Growth.G(level))
end

return Stats
