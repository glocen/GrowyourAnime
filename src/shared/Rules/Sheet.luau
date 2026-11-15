--!strict
-- Sheet (shared, pure): what each line of Overview's stat sheet says (docs/ui.md, 5, "Overview's stat sheet"; the stats in
-- docs/balance.md, "The stats"). Every stat in three groups, Core, Attack and Defence, a zero shown as 0, never hidden.
--   A rating      its points, then what it gives at the Voidkin's level against a foe with none: "up to N%", since a
--                 foe's own rating only lowers it (Rules.Hit's own sums). Critical counts its floor. Hit and Critical
--                 Resist give no chance of their own: they lower a foe's, and say so.
--   A percent     its percent. Damage Bonus and Damage Reduction come from a signature, a passive or an effect only,
--                 each said with its condition ("below 30% health").
--   Its sources   under it, as the resolver's lines give them: Own, Level, Stars, Gear.
-- The client draws the rows (UI.VoidkinScreen); nothing here decides anything.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)
local Passives = require(Shared.Definitions.Passives)

local Sheet = {}

export type Row = { Stat: string, Name: string, Value: string, Under: string? }
export type Group = { Name: string, Rows: { Row } }

Sheet.Groups = {
	{ Name = "Core", Stats = { "Health", "Attack", "Defence", "Regen", "Speed", "Poise" } },
	{ Name = "Attack", Stats = { "Hit", "Critical", "CriticalDamage", "Penetration", "ElementalAttack", "Lifesteal", "DamageBonus" } },
	{ Name = "Defence", Stats = { "Dodge", "Block", "CriticalResist", "CriticalGuard", "ElementalResist", "DamageReduction" } },
}

-- What players read for each stat.
Sheet.Said = {
	CriticalDamage = "Critical Damage",
	ElementalAttack = "Elemental Attack",
	DamageBonus = "Damage Bonus",
	CriticalResist = "Critical Resist",
	CriticalGuard = "Critical Guard",
	ElementalResist = "Elemental Resist",
	DamageReduction = "Damage Reduction",
} :: { [string]: string }

-- The resolver's sources as players read them, in the order they're listed; any other source is a slot's item.
local SOURCES: { [string]: string } = { Base = "Own", Level = "Level", Stars = "Stars" }
local ORDER = { "Own", "Level", "Stars", "Gear" }
local PERCENTS: { [string]: boolean } = { CriticalDamage = true, CriticalGuard = true, Lifesteal = true }

-- A share as a percent: whole from 10%, one place under it, never a trailing ".0".
function Sheet.Percent(share: number): string
	local p = share * 100
	local said = if math.abs(p) >= 10 then tostring(math.floor(p + 0.5)) else string.format("%.1f", p)
	return (said:gsub("%.0$", "")) .. "%"
end

-- What a rating gives at the Voidkin's level against a foe with none, the way Rules.Hit sums it; nil for a stat that
-- isn't a rating with a chance of its own.
function Sheet.Chance(stat: string, block: Stats.Block): number?
	local caps = StatsConfig.Caps
	local level = block.Level
	if stat == "Critical" then
		return math.min(caps.Critical, caps.CriticalFloor + Stats.Chance(caps.CriticalSpan, block.Critical, 0, level))
	elseif stat == "Dodge" or stat == "Block" or stat == "Penetration" or stat == "ElementalResist" then
		return Stats.Chance((caps :: any)[stat], (block :: any)[stat], 0, level)
	end
	return nil
end

-- One number as its stat is read: points, a share as a percent, Regen to a tenth.
local function amount(stat: string, value: number): string
	if PERCENTS[stat] then
		return Sheet.Percent(value)
	elseif stat == "Regen" then
		return string.format("%.1f", value)
	end
	return Hud.Digits(value)
end

local function sources(stat: string, lines: { Stats.Line }): { string }
	local by: { [string]: number } = {}
	for _, line in lines do
		if line.Stat == stat then
			local source = SOURCES[line.Source] or "Gear"
			by[source] = (by[source] or 0) + line.Value
		end
	end
	local said = {}
	for _, source in ORDER do
		if by[source] then
			table.insert(said, `{source} {amount(stat, by[source])}`)
		end
	end
	return said
end

-- What a passive gives to Damage Bonus or Damage Reduction, with its condition; nil if nothing does.
local function fromPassive(stat: string, passive: Passives.Row?): (number?, string?)
	if passive and stat == "DamageReduction" and passive.Kind == "Reduction" then
		local below = if passive.Below then `, below {Sheet.Percent(passive.Below)} health` else ""
		return passive.Share, `{passive.Name}{below}`
	end
	return nil, nil
end

-- One stat's line.
function Sheet.Row(stat: string, block: Stats.Block, lines: { Stats.Line }, passive: Passives.Row?): Row
	local value = (block :: any)[stat]
	local points = if type(value) == "number" then value else 0
	local under = sources(stat, lines)
	local said: string
	if stat == "Regen" then
		said = `{amount(stat, points)} a second`
	elseif stat == "Speed" then
		said = `{if points == math.floor(points) then tostring(points) else string.format("%.1f", points)} studs a second`
	elseif stat == "DamageBonus" or stat == "DamageReduction" then
		local share, condition = fromPassive(stat, passive)
		said = Sheet.Percent(share or 0)
		under = if condition then { condition } else {}
	elseif stat == "CriticalDamage" then
		said = `+{Sheet.Percent(points)}`
		table.insert(under, 1, `Base {Sheet.Percent(StatsConfig.CriticalDamage)}`)
	else
		local chance = Sheet.Chance(stat, block)
		-- A rating at zero gives nothing, so it reads 0 alone; Critical's floor still gives its 5%.
		said = if chance and chance > 0 then `{Hud.Digits(points)} · up to {Sheet.Percent(chance)}` else amount(stat, points)
	end
	if stat == "Hit" then
		table.insert(under, 1, "Lowers a foe's Dodge and Block")
	elseif stat == "CriticalResist" then
		table.insert(under, 1, "Lowers a foe's Critical")
	elseif stat == "ElementalAttack" then
		table.insert(under, 1, if block.Element ~= "" then `A second hit in {block.Element}, past Defence` else "No element: no second hit")
	elseif stat == "Lifesteal" and points > StatsConfig.Lifesteal.Cap then
		table.insert(under, `at most {Sheet.Percent(StatsConfig.Lifesteal.Cap)} counts`)
	end
	return { Stat = stat, Name = Sheet.Said[stat] or stat, Value = said, Under = if #under > 0 then table.concat(under, " · ") else nil }
end

-- The whole sheet, group by group.
function Sheet.Rows(block: Stats.Block, lines: { Stats.Line }, passive: Passives.Row?): { Group }
	local groups = {}
	for _, group in Sheet.Groups do
		local rows = {}
		for _, stat in group.Stats do
			table.insert(rows, Sheet.Row(stat, block, lines, passive))
		end
		table.insert(groups, { Name = group.Name, Rows = rows })
	end
	return groups
end

return Sheet
