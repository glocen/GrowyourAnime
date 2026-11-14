--!strict
-- Stats (shared, pure): the one place a fighter's stats are added up (docs/engineering-plan.md, "The resolver";
-- docs/balance.md, "The one rule"). Every source gives flat points, and the breakdown says which source gave each one:
--   Base     the Voidkin's own Health, Attack and Defence: its rarity and its class times G(level)
--   Stars    a share of that own base per star, linear, never of the total
--   Level    Regen, from the level alone
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
	Speed: number, -- a lead's walk in a fight, studs a second (Stats.SpeedOf); 0 for an enemy, which walks at its kind's (Config.Combat)
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
		Speed = 0,
	}
end

-- A Voidkin row's walk speed in a fight (TR14; Config.Stats.Speed): its class's figure, moved by the row's own Speed up
-- to Nudge either way. Nothing else changes it: it isn't one of Names, so no source adds to it. 0 for an unknown class.
function Stats.SpeedOf(row: Voidkin.Row): number
	local speed = StatsConfig.Speed
	local class = speed.Class[row.Class]
	return if class then class + math.clamp(row.Speed or 0, -speed.Nudge, speed.Nudge) else 0
end

local OWN = { "Health", "Attack", "Defence" }

-- A Voidkin row's own figure of `stat` at `level`, before stars, the board and gear: for Health, Attack and Defence its
-- rarity and its class times G (the Base line); for Regen its class's Regen times G (the Level line); else 0.
function Stats.Own(row: Voidkin.Row, stat: string, level: number): number
	local g = Growth.G(math.clamp(level, 1, GrowthConfig.MaxLevel))
	if stat == "Regen" then
		local regen = StatsConfig.Regen
		return regen.Base * (regen.Class[row.Class] or 1) * g
	end
	local base = StatsConfig.Base[stat]
	if base == nil or not table.find(OWN, stat) then
		return 0
	end
	local shift = StatsConfig.Class[row.Class]
	return base * (StatsConfig.Rarity[row.Rarity] or 1) * (if shift then shift[stat] else 1) * g
end

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
	block.Speed = Stats.SpeedOf(row)
	local stars = math.clamp(owned.Stars, 0, VoidkinConfig.MaxStars)
	for _, stat in OWN do
		local own = Stats.Own(row, stat, level)
		add("Base", stat, own)
		add("Stars", stat, own * VoidkinConfig.StarShareOfBase * stars)
	end
	-- Regen comes from the level alone, its own source, so the own base's share (stars) never touches it.
	add("Level", "Regen", Stats.Own(row, "Regen", level))
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

-- A block's Combat Power (docs/design.md, "Combat Power"; Config.Stats.Power): its stats weighted, critical damage above
-- its base, times the scale, rounded to a whole. For reading only: nothing in a fight reads it.
function Stats.Power(block: Block): number
	local power = StatsConfig.Power
	local sum = 0
	for stat, weight in power.Weights do
		local value = (block :: any)[stat]
		if type(value) == "number" and value == value then
			sum += weight * (if stat == "CriticalDamage" then math.max(0, value - StatsConfig.CriticalDamage) else value)
		end
	end
	return math.floor(sum * power.Scale + 0.5)
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
