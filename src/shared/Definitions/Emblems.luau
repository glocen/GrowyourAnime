--!strict
-- Emblems (shared, content): the War Emblems' twelve sets, three a rarity (TR47; docs/design.md, "War Emblems"; the
-- director's word of 2026-11-19, 03:13: Uncommon, Rare, Epic and Legendary at launch). A set is a name and a symbol only,
-- never a stat: an emblem is a key, its set and its one stat (Rules.Emblems), so identical emblems stack in the bag. Its
-- image is Modulo's star B with the set's symbol (AR43, `build/handoff/UI/emblems/`); what each stat gives:
-- Config.Emblems.

export type Row = { Id: string, Name: string, Rarity: string, Image: string }

local List: { Row } = {
	{ Id = "talon", Name = "Talon", Rarity = "Uncommon", Image = "EmblemTalon" },
	{ Id = "spearhead", Name = "Spearhead", Rarity = "Uncommon", Image = "EmblemSpearhead" },
	{ Id = "palisade", Name = "Palisade", Rarity = "Uncommon", Image = "EmblemPalisade" },
	{ Id = "tidebreak", Name = "Tidebreak", Rarity = "Rare", Image = "EmblemTidebreak" },
	{ Id = "warhorn", Name = "Warhorn", Rarity = "Rare", Image = "EmblemWarhorn" },
	{ Id = "compass", Name = "Compass", Rarity = "Rare", Image = "EmblemCompass" },
	{ Id = "serpent_coil", Name = "Serpent Coil", Rarity = "Epic", Image = "EmblemSerpentCoil" },
	{ Id = "sworn_rings", Name = "Sworn Rings", Rarity = "Epic", Image = "EmblemSwornRings" },
	{ Id = "moonward", Name = "Moonward", Rarity = "Epic", Image = "EmblemMoonward" },
	{ Id = "zenith", Name = "Zenith", Rarity = "Legendary", Image = "EmblemZenith" },
	{ Id = "highcrown", Name = "Highcrown", Rarity = "Legendary", Image = "EmblemHighcrown" },
	{ Id = "radiance", Name = "Radiance", Rarity = "Legendary", Image = "EmblemRadiance" },
}

local ById: { [string]: Row } = {}
local ByRarity: { [string]: { Row } } = {}
for _, row in List do
	ById[row.Id] = row
	local sets = ByRarity[row.Rarity] or {}
	table.insert(sets, row)
	ByRarity[row.Rarity] = sets
end

return {
	List = List, -- by rarity, then the sets' order
	ById = ById,
	ByRarity = ByRarity,
	-- The stats an emblem can carry, in the card's order: the six at every rarity, then the three from Epic.
	Stats = { "Attack", "Defence", "Health", "Critical", "Hit", "Dodge" },
	HighStats = { "CriticalDamage", "CriticalGuard", "Lifesteal" },
}
