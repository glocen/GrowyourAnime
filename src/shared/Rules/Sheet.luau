--!strict
-- Sheet (shared, pure): what each line of Overview's stat sheet says, and what a tap on it says (docs/ui.md, 5,
-- "Overview's stat sheet", and "Stats, shown honestly"; the stats in docs/balance.md, "The stats"). Every stat in three
-- groups, Core, Attack and Defence, a zero shown as 0, never hidden.
--   The line      one total, the sum of its sources, never "up to": a rating as its points, a percent as its percent.
--   Its sources   on a tap, each with what it gave, in this order: the Voidkin's base, its level, its stars, each slot;
--                 forge, jewels, War Emblems and research after them as they join the resolver. A source shows once it
--                 gives something. Rounded so the list adds to the total as it's shown.
--   Its notes     after them: what the stat does where its number doesn't say it, then, for a rating, the chance it
--                 gives against a foe of its level with the same points, always last.
-- Damage Bonus and Damage Reduction come from a signature, a passive or an effect only: each giver is a source, named with
-- its condition ("Second Wind, below 30% health").
-- The client draws the rows (UI.VoidkinScreen); nothing here decides anything.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)
local Gear = require(Shared.Definitions.Gear)
local Passives = require(Shared.Definitions.Passives)

local Sheet = {}

export type Source = { Name: string, Value: string }
export type Row = { Stat: string, Name: string, Value: string, Sources: { Source }, Notes: { string } }
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

local PERCENTS: { [string]: boolean } = { CriticalDamage = true, CriticalGuard = true, Lifesteal = true }

-- The resolver's sources in the order a tap lists them: the Voidkin's own two, its stars, then the slots as the character
-- screen stands them. A source not here (forge, jewels, ...) follows, in the order the resolver gave it.
local ORDER: { string } = { "Base", "Level", "Stars" }
for _, slot in Gear.Hands do
	table.insert(ORDER, `Item:{slot}`)
end
for _, slot in Gear.Shared do
	table.insert(ORDER, `Item:{slot}`)
end
local RANK: { [string]: number } = {}
for index, source in ORDER do
	RANK[source] = index
end

-- A share as a percent: whole from 10% and grouped ("20,000%"), one place under it, never a trailing ".0".
function Sheet.Percent(share: number): string
	local p = share * 100
	local said = if math.abs(p) >= 10 then Hud.Digits(p) else string.format("%.1f", p)
	return (said:gsub("%.0$", "")) .. "%"
end

-- What a rating gives at the Voidkin's level against a foe of its level with `theirs` points meeting it (none if nil),
-- the way Rules.Hit sums it: Dodge and Block meet Hit, Critical meets Critical Resist, Penetration and Elemental Resist
-- meet nothing. Critical counts its floor. nil for a stat that isn't a rating with a chance of its own.
function Sheet.Chance(stat: string, block: Stats.Block, theirs: number?): number?
	local caps = StatsConfig.Caps
	local level, against = block.Level, theirs or 0
	if stat == "Critical" then
		return math.min(caps.Critical, caps.CriticalFloor + Stats.Chance(caps.CriticalSpan, block.Critical, against, level))
	elseif stat == "Dodge" or stat == "Block" then
		return Stats.Chance((caps :: any)[stat], (block :: any)[stat], against, level)
	elseif stat == "Penetration" or stat == "ElementalResist" then
		return Stats.Chance((caps :: any)[stat], (block :: any)[stat], 0, level)
	end
	return nil
end

-- A rating's last line on a tap: what it gives against a foe of its level with the same points (docs/ui.md, "Stats,
-- shown honestly"). Hit and Critical Resist give no chance of their own, so theirs is what the foe is left with.
local function chanceLine(stat: string, block: Stats.Block, points: number): string?
	local caps, level, said = StatsConfig.Caps, block.Level, Hud.Digits(points)
	local foe = `Against a level {level} foe`
	if stat == "Dodge" or stat == "Block" then
		local chance = Sheet.Chance(stat, block, points) :: number
		return `{foe} with {said} Hit: {Sheet.Percent(chance)} of its hits {if stat == "Dodge" then "dodged" else "blocked"}`
	elseif stat == "Critical" then
		return `{foe} with {said} Critical Resist: {Sheet.Percent(Sheet.Chance(stat, block, points) :: number)} of hits critical`
	elseif stat == "Penetration" then
		return `{foe}: {Sheet.Percent(Sheet.Chance(stat, block) :: number)} of its Defence ignored`
	elseif stat == "ElementalResist" then
		return `{foe}: {Sheet.Percent(Sheet.Chance(stat, block) :: number)} off its elemental hits`
	elseif stat == "Hit" then
		local dodge = Stats.Chance(caps.Dodge, points, points, level)
		local blocked = Stats.Chance(caps.Block, points, points, level)
		return `{foe} with {said} Dodge and Block: it dodges {Sheet.Percent(dodge)}, blocks {Sheet.Percent(blocked)}`
	elseif stat == "CriticalResist" then
		local critical = math.min(caps.Critical, caps.CriticalFloor + Stats.Chance(caps.CriticalSpan, points, points, level))
		return `{foe} with {said} Critical: {Sheet.Percent(critical)} of its hits critical`
	end
	return nil
end

-- `values` in whole units of 1/`per` (1 for points, 10 for tenths, 1000 for a percent's tenths), so that they add to
-- their rounded total: the largest remainders take the spare units, the earlier source on a tie.
local function rounded(values: { number }, per: number): { number }
	local total, got, out, rest = 0, 0, {}, {}
	for index, value in values do
		total += value * per
		out[index] = math.floor(value * per)
		got += out[index]
		table.insert(rest, index)
	end
	table.sort(rest, function(a: number, b: number): boolean
		local ra, rb = values[a] * per - out[a], values[b] * per - out[b]
		return if ra ~= rb then ra > rb else a < b
	end)
	local want = math.floor(total + 0.5)
	for k = 1, math.min(#rest, want - got) do
		out[rest[k]] += 1
	end
	for index in out do
		out[index] /= per
	end
	return out
end

-- One number as its stat is read: points, a share as a percent (Critical Damage with its +), Regen to a tenth.
local function amount(stat: string, value: number): string
	if stat == "CriticalDamage" then
		return `+{Sheet.Percent(value)}`
	elseif PERCENTS[stat] then
		return Sheet.Percent(value)
	elseif stat == "Regen" then
		return string.format("%.1f", value)
	end
	return Hud.Digits(value)
end

local function nameOf(source: string, block: Stats.Block): string
	if source == "Level" then
		return `Level {block.Level}`
	end
	return (source:gsub("^Item:", ""))
end

-- Each source that gave `stat` something, in ORDER, rounded to add to the total as it's shown.
local function sources(stat: string, block: Stats.Block, lines: { Stats.Line }): { Source }
	local by: { [string]: number } = {}
	local seen: { string } = {}
	if stat == "CriticalDamage" then -- every Voidkin's own, on no line: Stats.Empty starts from it
		by.Base = StatsConfig.CriticalDamage
		table.insert(seen, "Base")
	end
	for _, line in lines do
		if line.Stat == stat then
			if by[line.Source] == nil then
				table.insert(seen, line.Source)
			end
			by[line.Source] = (by[line.Source] or 0) + line.Value
		end
	end
	local first: { [string]: number } = {}
	for index, source in seen do
		first[source] = index
	end
	table.sort(seen, function(a: string, b: string): boolean
		return (RANK[a] or #ORDER + first[a]) < (RANK[b] or #ORDER + first[b])
	end)
	local values = {}
	for index, source in seen do
		values[index] = by[source]
	end
	local shown = rounded(values, if PERCENTS[stat] then 1000 elseif stat == "Regen" then 10 else 1)
	local said: { Source } = {}
	for index, source in seen do
		table.insert(said, { Name = nameOf(source, block), Value = amount(stat, shown[index]) })
	end
	return said
end

-- What a passive gives to Damage Bonus or Damage Reduction, named with its condition; nil if nothing does.
local function fromPassive(stat: string, passive: Passives.Row?): (number?, string?)
	if passive and stat == "DamageReduction" and passive.Kind == "Reduction" then
		local below = if passive.Below then `, below {Sheet.Percent(passive.Below)} health` else ""
		return passive.Share, `{passive.Name}{below}`
	end
	return nil, nil
end

-- A multiplier as it's read: "x1.5", "x201", never a trailing 0.
local function times(n: number): string
	local said = string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", "")
	return `x{said}`
end

-- One stat's line, and what a tap on it says.
function Sheet.Row(stat: string, block: Stats.Block, lines: { Stats.Line }, passive: Passives.Row?): Row
	local value = (block :: any)[stat]
	local points = if type(value) == "number" then value else 0
	local said = amount(stat, points)
	local list = sources(stat, block, lines)
	local notes: { string } = {}
	if stat == "Regen" then
		said = `{said} a second`
	elseif stat == "Speed" then
		said = `{if points == math.floor(points) then tostring(points) else string.format("%.1f", points)} studs a second`
		table.insert(notes, "From its class and its own build, never from gear")
	elseif stat == "Poise" then
		table.insert(notes, "From its class, never from gear")
	elseif stat == "DamageBonus" or stat == "DamageReduction" then
		local share, condition = fromPassive(stat, passive)
		said = Sheet.Percent(share or 0)
		list = if share and condition then { { Name = condition, Value = Sheet.Percent(share) } } else {}
		table.insert(notes, "Only from a signature, a passive or an effect in a fight, never from gear")
	elseif stat == "CriticalDamage" then
		table.insert(notes, `A critical hit does {times(1 + points)}, less a foe's Critical Guard, never under x1`)
	elseif stat == "CriticalGuard" then
		table.insert(notes, "Taken off a foe's Critical Damage")
	elseif stat == "Hit" then
		table.insert(notes, "Lowers a foe's Dodge and Block")
	elseif stat == "CriticalResist" then
		table.insert(notes, "Lowers a foe's Critical")
	elseif stat == "ElementalAttack" then
		table.insert(notes, if block.Element ~= "" then `A second hit in {block.Element}, past Defence` else "No element: no second hit")
	elseif stat == "Lifesteal" and points > StatsConfig.Lifesteal.Cap then
		table.insert(notes, `At most {Sheet.Percent(StatsConfig.Lifesteal.Cap)} counts`)
	end
	if #list == 0 and #notes == 0 then
		table.insert(notes, "Nothing gives it yet")
	end
	local chance = chanceLine(stat, block, points)
	if chance then
		table.insert(notes, chance) -- always last
	end
	return { Stat = stat, Name = Sheet.Said[stat] or stat, Value = said, Sources = list, Notes = notes }
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
