--!strict
-- Sheet (shared, pure): what each line of Overview's stat sheet says (docs/research/rework-2026-11-16.md, part 4, "How
-- stats are written, and the Overview"; docs/ui.md, 5, "Overview's stat sheet"; the stats in docs/balance.md, "The
-- stats"). Two headings:
--   Basic Attributes   the two, each its total, its class's Main marked
--   Battle Attributes  Core; Offence and Defence paired on each row, so what counters what reads without a word; Sustain
-- A plain list [the director, 2026-11-15, night: "dont put any description for stats", then "Plain list, no taps"]: each
-- stat its name and its one total, a zero shown as 0, never hidden, and nothing opens. What each kind of number shows:
--   points             the number, grouped, no decimals (Regen to a tenth a second, Speed in studs a second)
--   a chance           Hit, Dodge, Critical, Block: its chance against an even foe, a percent and nothing else
--   a rating's effect  Penetration, Critical Resist, Elemental Resist: what it does to an even foe, a percent, no words
--   a percent          Critical Damage, Critical Immunity, Lifesteal, Damage Bonus, Damage Reduction, as it is
-- A rating's points are never shown: a chance or a share shows its percent only [the director, 2026-11-17, by 00:17;
-- docs/ui.md, "Stats, shown honestly"]. Every chance is the hit's own (Rules.Hit.Odds, Rules.Stats.Chance) against
-- Stats.EvenFoe at the block's level, so it can't drift from the combat, and none reads over its ceiling. Damage Bonus and
-- Damage Reduction show only what holds at all times, so a signature's, a passive's or an effect's share on a condition
-- isn't in them. The client draws the rows (UI.VoidkinScreen); nothing here decides anything.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local Attributes = require(Shared.Definitions.Attributes)
local Stats = require(Shared.Rules.Stats)
local Hit = require(Shared.Rules.Hit)
local Hud = require(Shared.Rules.Hud)

local Sheet = {}

-- A line: its stat, the name players read, its total as shown (a rating's: its chance or effect against an even foe),
-- and whether it's its class's Main.
export type Row = { Stat: string, Name: string, Value: string, Main: boolean? }
-- A block of lines under its caption. The first of a heading's blocks carries the heading, and its caption line under it.
export type Group = { Name: string, Rows: { Row }, Heading: string?, Caption: string? }

Sheet.Headings = { Basic = "Basic Attributes", Battle = "Battle Attributes" }
Sheet.EvenFoe = "chances against an even foe" -- the one caption, under Battle Attributes

-- The Battle Attributes' blocks, two a row: Offence and Defence paired, the attacker's stat on the left.
Sheet.Groups = {
	{ Name = "Core", Stats = { "Health", "Attack", "Defence", "Speed", "Poise" } },
	{
		Name = "Offence and Defence",
		Stats = {
			"Hit",
			"Dodge",
			"Critical",
			"CriticalResist",
			"CriticalDamage",
			"CriticalGuard",
			"ElementalAttack",
			"ElementalResist",
			"DamageBonus",
			"DamageReduction",
			"Penetration", -- not a counter pair: where both fit
			"Block",
		},
	},
	{ Name = "Sustain", Stats = { "Regen", "Lifesteal" } },
}

-- What players read for each stat.
Sheet.Said = {
	CriticalDamage = "Critical Damage",
	ElementalAttack = "Elemental Attack",
	DamageBonus = "Damage Bonus",
	CriticalResist = "Critical Resist",
	CriticalGuard = "Critical Immunity", -- the director's name (2026-11-17, by 00:17); the key stays the code's
	ElementalResist = "Elemental Resist",
	DamageReduction = "Damage Reduction",
} :: { [string]: string }

-- The ratings, each shown as its share against an even foe (Sheet.Odds), never as its points.
Sheet.Rated = {
	Hit = true,
	Dodge = true,
	Critical = true,
	Block = true,
	Penetration = true,
	CriticalResist = true,
	ElementalResist = true,
} :: { [string]: boolean }

local PERCENTS: { [string]: boolean } = {
	CriticalDamage = true,
	CriticalGuard = true,
	Lifesteal = true,
	DamageBonus = true,
	DamageReduction = true,
}

-- A share as a percent: whole from 10% and grouped ("20,000%"), one place under it, never a trailing ".0".
function Sheet.Percent(share: number): string
	local p = share * 100
	local said = if math.abs(p) >= 10 then Hud.Digits(p) else string.format("%.1f", p)
	return (said:gsub("%.0$", "")) .. "%"
end

-- One total as its stat is read: points, a share as a percent (Critical Damage with its +; a rating's `value` is its
-- share, Sheet.Odds), Regen to a tenth a second, Speed in studs a second.
local function amount(stat: string, value: number): string
	if stat == "CriticalDamage" then
		return `+{Sheet.Percent(value)}`
	elseif PERCENTS[stat] or Sheet.Rated[stat] then
		return Sheet.Percent(value)
	elseif stat == "Regen" then
		return `{string.format("%.1f", value)} a second`
	elseif stat == "Speed" then
		return `{if value == math.floor(value) then tostring(value) else string.format("%.1f", value)} studs a second`
	end
	return Hud.Digits(value)
end

-- A total as a card writes it beside another (Rules.Bag's cards): as the sheet reads it, a rating's from its share, but
-- Regen and Speed without their units, so a row fits a card's half.
function Sheet.Amount(stat: string, value: number): string
	if stat == "Regen" or stat == "Speed" then
		return if value == math.floor(value) then tostring(value) else string.format("%.1f", value)
	end
	return amount(stat, value)
end

-- What a change does to a total, signed: "+12", "−3", "+1.5%"; "–" when it's none. A share's change is in points of a
-- percent, never a percent of a percent (docs/ui.md, "Stats, shown honestly").
function Sheet.Change(stat: string, change: number): string
	if math.abs(change) < 1e-9 then
		return "–"
	end
	local size = math.abs(change)
	local said = if PERCENTS[stat] or Sheet.Rated[stat] or stat == "CriticalDamage" then Sheet.Percent(size) elseif stat == "Regen" or stat == "Speed" then string.format("%.1f", size) else Hud.Digits(size)
	-- A change finer than its usual digits gets a finer one, so a change never reads as none: points under a half to a
	-- tenth; a percent under a twentieth of one to a hundredth, "<0.01%" under that (a rating's gain against a high
	-- level's even foe: a +0% in the gain's green on TR24's phone run).
	if said == "0" then
		said = string.format("%.1f", size)
	elseif said == "0%" then
		said = if size * 100 >= 0.005 then string.format("%.2f%%", size * 100) else "<0.01%"
	end
	return (if change > 0 then "+" else "−") .. said
end

-- Each rating's chance or effect against an even foe of `block`'s level, as a share, by the hit's own functions:
--   Hit              the share of its hits that land: 1 - the foe's dodge
--   Dodge, Block     the share of the foe's hits it dodges, it blocks
--   Critical         its critical chance, the floor included
--   Penetration      the share of the foe's Defence it ignores
--   Critical Resist  how much it takes off the foe's critical chance, in points of chance
--   Elemental Resist the share of elemental damage it takes off
function Sheet.Odds(block: Stats.Block): { [string]: number }
	local foe = Stats.EvenFoe(block.Level)
	local foeDodge, critical, _, penetration = Hit.Odds(block, foe)
	local dodge, foeCritical, blocked = Hit.Odds(foe, block)
	local bare = table.clone(block)
	bare.CriticalResist = 0
	local _, foeBare = Hit.Odds(foe, bare)
	return {
		Hit = 1 - foeDodge,
		Dodge = dodge,
		Critical = critical,
		Block = blocked,
		Penetration = penetration,
		CriticalResist = foeBare - foeCritical,
		ElementalResist = Stats.Chance(StatsConfig.Caps.ElementalResist, block.ElementalResist, 0, foe.Level),
	}
end

-- What `points` more of a rating add to `block`'s share against an even foe (Sheet.Odds): a gear line's rating shown on
-- its own, as a percent (Rules.Bag).
function Sheet.Adds(stat: string, points: number, block: Stats.Block): number
	local more = table.clone(block)
	local had = (more :: any)[stat];
	(more :: any)[stat] = (if type(had) == "number" then had else 0) + points
	return Sheet.Odds(more)[stat] - Sheet.Odds(block)[stat]
end

-- One stat's line. A stat the block doesn't carry (Damage Bonus, Damage Reduction: nothing gives them at all times yet)
-- reads as its zero. A rating reads as its share (`odds`, Sheet.Odds, worked out when left out).
function Sheet.Row(stat: string, block: Stats.Block, odds: { [string]: number }?): Row
	local value = if Sheet.Rated[stat] then (odds or Sheet.Odds(block))[stat] else (block :: any)[stat]
	return {
		Stat = stat,
		Name = Sheet.Said[stat] or stat,
		Value = amount(stat, if type(value) == "number" then value else 0),
	}
end

-- The two attributes' lines, in Definitions.Attributes' order, each its total, the class's Main marked.
function Sheet.Basic(block: Stats.Block): { Row }
	local rows = {}
	for _, attribute in Attributes.List do
		table.insert(rows, {
			Stat = attribute.Id,
			Name = attribute.Name,
			Value = Hud.Digits(block.Attributes[attribute.Id] or 0),
			Main = if block.Main == attribute.Id then true else nil,
		})
	end
	return rows
end

-- The whole sheet, block by block: the Basic Attributes, then the Battle Attributes' three.
function Sheet.Rows(block: Stats.Block): { Group }
	local odds = Sheet.Odds(block)
	local groups: { Group } = { { Name = "", Heading = Sheet.Headings.Basic, Rows = Sheet.Basic(block) } }
	for index, group in Sheet.Groups do
		local rows = {}
		for _, stat in group.Stats do
			table.insert(rows, Sheet.Row(stat, block, odds))
		end
		table.insert(groups, {
			Name = group.Name,
			Rows = rows,
			Heading = if index == 1 then Sheet.Headings.Battle else nil,
			Caption = if index == 1 then Sheet.EvenFoe else nil,
		})
	end
	return groups
end

return Sheet
