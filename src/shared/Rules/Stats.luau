--!strict
-- Stats (shared, pure): the one place a fighter's stats are added up (docs/engineering-plan.md, "The resolver" and
-- "Attributes in the resolver"; docs/balance.md, "The one rule"). Every source gives flat points, in three steps, and the
-- breakdown says which source gave each one:
--   1. Points, to the Basic Attributes (Definitions.Attributes) and to Regen:
--      Base     the Voidkin's own points at level 1: its class's shape times its rarity times G(1); the level's own Regen
--      Level    what its level adds to the same, times G(level) - G(1): the two make the own figure
--      Stars    a share of the own attribute points (base and level) per star, linear, never of Regen
--      Item     each line of each item worn, as it is: to an attribute or to a Battle Attribute. Worn means the preset's
--               twelve shared slots and its pair for the Voidkin's own class, in Gear's order, and only an item whose row
--               fits there (Definitions.Items.Fits), so a save edited by hand applies no wrong weapon (TR26)
--   2. Attr:<id>  each attribute's total converts once by its row (Config.Stats.Attributes.Convert)
--   3. Main:<id>  the class's Main converts once more by its class's row (Attributes.Main)
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
local Attributes = require(Shared.Definitions.Attributes)
local Gear = require(Shared.Definitions.Gear)
local Items = require(Shared.Definitions.Items)
local Growth = require(Shared.Rules.Growth)
local Regalia = require(Shared.Rules.Regalia)

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
	Regen: number, -- health a second, healed in bursts (Config.Stats.Regen; Stats.Burst)
	Speed: number, -- a lead's walk in a fight, studs a second (Stats.SpeedOf); 0 for an enemy, which walks at its kind's (Config.Combat)
	Attributes: { [string]: number }, -- each Basic Attribute's total, by its id; read by the sheet, never by a fight or Power
	Main: string, -- its class's Main attribute's id, or "" (an enemy, an unknown class)
}

export type Line = { Source: string, Stat: string, Value: number }

-- Every attribute at 0, by its id.
function Stats.NoPoints(): { [string]: number }
	local out = {}
	for _, id in Attributes.Ids do
		out[id] = 0
	end
	return out
end

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
		Attributes = Stats.NoPoints(),
		Main = "",
	}
end

-- A Voidkin row's walk speed in a fight (TR14; Config.Stats.Speed): its class's figure, moved by the row's own Speed up
-- to Nudge either way. Nothing else changes it: it isn't one of Names, so no source adds to it. 0 for an unknown class.
function Stats.SpeedOf(row: Voidkin.Row): number
	local speed = StatsConfig.Speed
	local class = speed.Class[row.Class]
	return if class then class + math.clamp(row.Speed or 0, -speed.Nudge, speed.Nudge) else 0
end

-- A Voidkin row's own figure of `stat` at `level`, before stars and gear: for an attribute, its class's shape times its
-- rarity times G; for Regen, the level's own, Base times G (times its class's, if Config names one); else 0.
function Stats.Own(row: Voidkin.Row, stat: string, level: number): number
	local g = Growth.G(math.clamp(level, 1, GrowthConfig.MaxLevel))
	if stat == "Regen" then
		local regen = StatsConfig.Regen
		return regen.Base * (regen.Class[row.Class] or 1) * g
	end
	local shape = StatsConfig.Attributes.Shape[row.Class]
	local points = if shape then shape[stat] else nil
	if points == nil or Attributes.ById[stat] == nil then
		return 0
	end
	return points * (StatsConfig.Rarity[row.Rarity] or 1) * g
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
	local attributes = StatsConfig.Attributes
	-- 1. Points. An attribute's go to its total, a Battle Attribute's straight on.
	local function point(source: string, id: string, value: number)
		if value == value and value ~= 0 then
			block.Attributes[id] += value
			table.insert(lines, { Source = source, Stat = id, Value = value })
		end
	end
	-- The own figure in two lines, so the stat sheet can say what the level gave (docs/ui.md, "Stats, shown honestly").
	for _, id in Attributes.Ids do
		local whole, first = Stats.Own(row, id, level), Stats.Own(row, id, 1)
		point("Base", id, first)
		point("Level", id, whole - first)
		point("Stars", id, whole * VoidkinConfig.StarShareOfBase * stars)
	end
	local regen, firstRegen = Stats.Own(row, "Regen", level), Stats.Own(row, "Regen", 1)
	add("Base", "Regen", firstRegen) -- no star share: the level's Regen is a value a second, never a share
	add("Level", "Regen", regen - firstRegen)
	if preset and data then
		local function wear(slot: string, itemId: string?)
			local item = if itemId then data.Items[itemId] else nil
			local itemRow = if item then Items.ById[item.Def] else nil
			if item == nil or itemRow == nil or not Items.Fits(itemRow, slot, row.Class) then
				return
			end
			for _, itemLine in item.Lines do
				if Attributes.ById[itemLine.Stat] then
					point(`Item:{slot}`, itemLine.Stat, itemLine.Value)
				else
					add(`Item:{slot}`, itemLine.Stat, itemLine.Value)
				end
			end
		end
		for _, slot in Gear.Shared do
			wear(slot, preset.Slots[slot])
		end
		local pair = if preset.Hands then preset.Hands[row.Class] else nil
		for _, slot in Gear.Hands do
			wear(slot, if pair then pair[slot] else nil)
		end
	end
	-- 2. Each total converts once by its row, in Names' order so the lines read the same every time.
	local function convert(source: string, total: number, rates: { [string]: number })
		for _, stat in Stats.Names do
			local rate = rates[stat]
			if rate then
				add(source, stat, total * rate)
			end
		end
	end
	for _, id in Attributes.Ids do
		convert(`Attr:{id}`, block.Attributes[id], attributes.Convert[id] or {})
	end
	-- 3. The Main converts once more.
	local main = attributes.Main[row.Class]
	if main and Attributes.ById[main.Attribute] then
		block.Main = main.Attribute
		convert(`Main:{main.Attribute}`, block.Attributes[main.Attribute], main.Gives)
	end
	return block, lines
end

-- A block's Combat Power unrounded (docs/design.md, "Combat Power"; Config.Stats.Power): its stats weighted, critical
-- damage above its base, a percent's weight times G at the block's level, times the scale. For reading only: nothing in
-- a fight reads it. Elemental Attack counts only for a block with an element: without one a hit has no elemental part
-- (Rules.Hit), so the points add nothing to winning (the director's design review, 2026-11-18). A gain is judged on this
-- sum, never on the rounded figure, so one under half a shown point still counts (D3, 2026-11-18).
function Stats.Sum(block: Block): number
	local power = StatsConfig.Power
	local g = Growth.G(math.clamp(block.Level, 1, GrowthConfig.MaxLevel))
	local sum = 0
	for stat, weight in power.Weights do
		local value = (block :: any)[stat]
		local used = stat ~= "ElementalAttack" or block.Element ~= ""
		if used and type(value) == "number" and value == value then
			local each = if power.ByLevel[stat] then weight * g else weight
			sum += each * (if stat == "CriticalDamage" then math.max(0, value - StatsConfig.CriticalDamage) else value)
		end
	end
	return sum * power.Scale
end

-- A block's Combat Power as it shows: the sum rounded to a whole.
function Stats.Power(block: Block): number
	return math.floor(Stats.Sum(block) + 0.5)
end

-- One Regen burst's size (TR40; Config.Stats.Regen): Share of what Every seconds at `regen` a second would heal. A value,
-- never a share of health; linear, so a change in Regen is a change in the burst by the same rule.
function Stats.Burst(regen: number): number
	local config = StatsConfig.Regen
	return regen * config.Every * config.Share
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

-- The even foe at `level` (docs/research/rework-2026-11-16.md, part 4): a Voidkin of that level on the on-budget build,
-- its ratings Config.Stats.EvenFoe times G, nothing else. The stat sheet reads its chances against it, through the
-- hit's own functions (Rules.Sheet), so what it shows can't drift from the combat.
function Stats.EvenFoe(level: number): Block
	local clamped = math.clamp(level, 1, GrowthConfig.MaxLevel)
	local block = Stats.Empty(clamped)
	local g = Growth.G(clamped)
	for stat, value in StatsConfig.EvenFoe do
		if KNOWN[stat] then
			(block :: any)[stat] = value * g
		end
	end
	return block
end

-- The preset an owned Voidkin is linked to, or nil.
function Stats.PresetOf(data: Profile.Data, owned: Profile.OwnedVoidkin): Profile.Preset?
	return data.Presets[owned.Preset]
end

-- What wearing one item would change: the slot it would go in, each Basic Attribute's change, each Battle Attribute's,
-- Combat Power's, and the two blocks.
export type Change = {
	Slot: string,
	Attributes: { [string]: number },
	Battle: { [string]: number },
	Power: number, -- the unrounded sum's change (Stats.Sum), so a gain under half a shown point is still a gain
	Before: Block,
	After: Block,
}

local function copyPreset(preset: Profile.Preset?): Profile.Preset
	local hands = {}
	for class, pair in (if preset and preset.Hands then preset.Hands else {}) :: { [string]: { [string]: string } } do
		hands[class] = table.clone(pair)
	end
	return { Slots = if preset then table.clone(preset.Slots) else {}, Hands = hands }
end

-- What `owned` would gain from wearing item `id` in `preset` (docs/engineering-plan.md, "Class rules"; the rework's
-- part 10, "The comparison"): the resolver run twice, on the preset as it is and with the item put in, so it can't drift
-- from the fight, and the client's copy answers it as the server's would. `slot` picks one of a pair; without it, a ring
-- or an earring goes where Combat Power ends highest, an empty one before a worn one, Ring I before Ring II on a tie. A
-- weapon is compared for its own class only. Nil and the refusal when the item can't go there. `before`, when given, is
-- `owned` resolved in `preset` already, so a list of items resolves it once (Rules.Bag).
function Stats.Compare(
	data: Profile.Data,
	preset: Profile.Preset?,
	owned: Profile.OwnedVoidkin,
	id: string,
	slot: string?,
	before: Block?
): (Change?, string?)
	local item = data.Items[id]
	local itemRow = if item then Items.ById[item.Def] else nil
	local row = Voidkin.ById[owned.Def]
	if item == nil or itemRow == nil then
		return nil, if item == nil then Regalia.NotOwned else Regalia.WrongSlot
	end
	local class = if row then row.Class else nil
	local slots = if slot then { slot } else Gear.SlotsOf(itemRow.Slot)
	local now = before or Stats.Resolve(owned, preset, data)
	local best: Change? = nil
	local refusal: string? = Regalia.WrongSlot
	for _, candidate in slots do
		refusal = Regalia.Refusal(data, candidate, class, id)
		if refusal then
			continue
		end
		local trial = copyPreset(preset)
		Regalia.Put(trial, candidate, class, id)
		local after = Stats.Resolve(owned, trial, data)
		local power = Stats.Sum(after) - Stats.Sum(now)
		if best == nil or power > best.Power then
			local attributes, battle = {}, {}
			for _, attribute in Attributes.Ids do
				attributes[attribute] = after.Attributes[attribute] - now.Attributes[attribute]
			end
			for _, stat in Stats.Names do
				battle[stat] = (after :: any)[stat] - (now :: any)[stat]
			end
			best = { Slot = candidate, Attributes = attributes, Battle = battle, Power = power, Before = now, After = after }
		end
	end
	if best then
		return best, nil
	end
	return nil, refusal
end

-- A rating as a chance: cap x mine / (mine + theirs + K x G(level)). Never reaches its cap; nothing below one point.
function Stats.Chance(cap: number, mine: number, theirs: number, level: number): number
	if not (mine > 0) then
		return 0
	end
	return cap * mine / (mine + math.max(0, theirs) + StatsConfig.RatingK * Growth.G(level))
end

return Stats
