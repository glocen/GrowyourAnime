--!strict
-- Sheet (shared, pure): what each line of Overview's stat sheet says (docs/ui.md, 5, "Overview's stat sheet", and
-- "Stats, shown honestly"; the stats in docs/balance.md, "The stats"). Every stat in three groups, Core, Attack and
-- Defence, a zero shown as 0, never hidden. A plain list [the director, 2026-11-15, night: "dont put any description for
-- stats", then "Plain list, no taps"]: each stat its name and its one total, never "up to", a rating as its points, a
-- percent as its percent, and nothing opens: no notes, no chance, no sources. Damage Bonus and Damage Reduction show only
-- what holds at all times, so a signature's, a passive's or an effect's share on a condition isn't in them.
-- The client draws the rows (UI.VoidkinScreen); nothing here decides anything.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Stats = require(Shared.Rules.Stats)
local Hud = require(Shared.Rules.Hud)

local Sheet = {}

export type Row = { Stat: string, Name: string, Value: string }
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

-- One total as its stat is read: points, a share as a percent (Critical Damage with its +), Regen to a tenth a second,
-- Speed in studs a second.
local function amount(stat: string, value: number): string
	if stat == "CriticalDamage" then
		return `+{Sheet.Percent(value)}`
	elseif PERCENTS[stat] then
		return Sheet.Percent(value)
	elseif stat == "Regen" then
		return `{string.format("%.1f", value)} a second`
	elseif stat == "Speed" then
		return `{if value == math.floor(value) then tostring(value) else string.format("%.1f", value)} studs a second`
	end
	return Hud.Digits(value)
end

-- One stat's line. A stat the block doesn't carry (Damage Bonus, Damage Reduction: nothing gives them at all times yet)
-- reads as its zero.
function Sheet.Row(stat: string, block: Stats.Block): Row
	local value = (block :: any)[stat]
	return { Stat = stat, Name = Sheet.Said[stat] or stat, Value = amount(stat, if type(value) == "number" then value else 0) }
end

-- The whole sheet, group by group.
function Sheet.Rows(block: Stats.Block): { Group }
	local groups = {}
	for _, group in Sheet.Groups do
		local rows = {}
		for _, stat in group.Stats do
			table.insert(rows, Sheet.Row(stat, block))
		end
		table.insert(groups, { Name = group.Name, Rows = rows })
	end
	return groups
end

return Sheet
