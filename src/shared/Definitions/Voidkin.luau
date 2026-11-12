--!strict
-- Voidkin (shared, content): the thirty-one fighters, one row each, keyed by an id that never changes and never shows to
-- players. Generated from docs/roster.md, "The thirty-one", on 2026-11-12: the roster is the design, these rows are what the
-- game reads. A row changes in both, the roster first. Kits (combo, signature, passive) join as each fighter is built.
-- Zone is the first ground (Definitions.Grounds, by Order) whose shards hold it. Aptitude is its work in a bay, 1 to 3.
-- Model is the build's, not the roster's: the fighter's own body, once it's installed.

export type Row = {
	Id: string,
	Name: string,
	Rarity: string, -- Definitions.Rarity
	Type: string, -- Agility, Strength, Endurance, Intelligence or Technique
	Class: string, -- Warrior, Tank, Assassin, Mage or Healer
	Element: string, -- Fire, Frost, Storm, Void, or "" for none
	Zone: number,
	Aptitude: number,
	-- Its body, ServerStorage.Templates.<Model> (tools/studio/Models/<Model>.luau): an R6 rig whose meshes ride its hidden
	-- parts, so it plays the R6 clips. Without one, a lead wears the grey R6 stand-in (FightService).
	Model: string?,
}

local rows: { Row } = {
	{ Id = "rook", Name = "Rook", Rarity = "Common", Type = "Strength", Class = "Warrior", Element = "", Zone = 1, Aptitude = 2, Model = "Rook" },
	{ Id = "kirra", Name = "Kirra", Rarity = "Common", Type = "Agility", Class = "Assassin", Element = "", Zone = 1, Aptitude = 1 },
	{ Id = "pip", Name = "Pip", Rarity = "Common", Type = "Intelligence", Class = "Mage", Element = "Fire", Zone = 1, Aptitude = 2 },
	{ Id = "watt", Name = "Watt", Rarity = "Common", Type = "Endurance", Class = "Tank", Element = "Storm", Zone = 1, Aptitude = 3 },
	{ Id = "patch", Name = "Patch", Rarity = "Common", Type = "Technique", Class = "Healer", Element = "", Zone = 1, Aptitude = 2 },
	{ Id = "tumble", Name = "Tumble", Rarity = "Common", Type = "Agility", Class = "Warrior", Element = "", Zone = 2, Aptitude = 1 },
	{ Id = "brick", Name = "Brick", Rarity = "Common", Type = "Strength", Class = "Tank", Element = "", Zone = 2, Aptitude = 3 },
	{ Id = "sable", Name = "Sable", Rarity = "Uncommon", Type = "Technique", Class = "Assassin", Element = "", Zone = 1, Aptitude = 1 },
	{ Id = "cinder", Name = "Cinder", Rarity = "Uncommon", Type = "Intelligence", Class = "Mage", Element = "Fire", Zone = 2, Aptitude = 2 },
	{ Id = "gantry", Name = "Gantry", Rarity = "Uncommon", Type = "Endurance", Class = "Warrior", Element = "", Zone = 2, Aptitude = 3 },
	{ Id = "mallow", Name = "Mallow", Rarity = "Uncommon", Type = "Strength", Class = "Healer", Element = "", Zone = 2, Aptitude = 2 },
	{ Id = "rill", Name = "Rill", Rarity = "Uncommon", Type = "Agility", Class = "Mage", Element = "Frost", Zone = 3, Aptitude = 1 },
	{ Id = "dirge", Name = "Dirge", Rarity = "Uncommon", Type = "Technique", Class = "Tank", Element = "Void", Zone = 3, Aptitude = 2 },
	{ Id = "juno", Name = "Juno", Rarity = "Uncommon", Type = "Intelligence", Class = "Warrior", Element = "Storm", Zone = 3, Aptitude = 2 },
	{ Id = "lyric", Name = "Lyric", Rarity = "Rare", Type = "Technique", Class = "Healer", Element = "Storm", Zone = 2, Aptitude = 2 },
	{ Id = "mirage", Name = "Mirage", Rarity = "Rare", Type = "Agility", Class = "Assassin", Element = "Fire", Zone = 3, Aptitude = 1 },
	{ Id = "bulwark", Name = "Bulwark", Rarity = "Rare", Type = "Endurance", Class = "Tank", Element = "Frost", Zone = 3, Aptitude = 3 },
	{ Id = "sliptail", Name = "Sliptail", Rarity = "Rare", Type = "Intelligence", Class = "Mage", Element = "Void", Zone = 3, Aptitude = 2 },
	{ Id = "gauge", Name = "Gauge", Rarity = "Rare", Type = "Strength", Class = "Warrior", Element = "Storm", Zone = 4, Aptitude = 2 },
	{ Id = "wren", Name = "Wren", Rarity = "Rare", Type = "Agility", Class = "Healer", Element = "", Zone = 4, Aptitude = 1 },
	{ Id = "halcyon", Name = "Halcyon", Rarity = "Epic", Type = "Intelligence", Class = "Healer", Element = "Frost", Zone = 3, Aptitude = 2 },
	{ Id = "ashen", Name = "Ashen", Rarity = "Epic", Type = "Strength", Class = "Assassin", Element = "Fire", Zone = 4, Aptitude = 1 },
	{ Id = "ironhymn", Name = "Ironhymn", Rarity = "Epic", Type = "Endurance", Class = "Mage", Element = "Storm", Zone = 4, Aptitude = 3 },
	{ Id = "noct", Name = "Noct", Rarity = "Epic", Type = "Technique", Class = "Assassin", Element = "Void", Zone = 5, Aptitude = 1 },
	{ Id = "marigold", Name = "Marigold", Rarity = "Epic", Type = "Endurance", Class = "Tank", Element = "Fire", Zone = 5, Aptitude = 2 },
	{ Id = "stellane", Name = "Stellane", Rarity = "Legendary", Type = "Intelligence", Class = "Mage", Element = "Storm", Zone = 4, Aptitude = 2 },
	{ Id = "crane", Name = "Crane", Rarity = "Legendary", Type = "Agility", Class = "Warrior", Element = "", Zone = 5, Aptitude = 1 },
	{ Id = "shiomaru", Name = "Shiomaru", Rarity = "Legendary", Type = "Endurance", Class = "Tank", Element = "Frost", Zone = 6, Aptitude = 3 },
	{ Id = "aegir", Name = "Aegir", Rarity = "Mythical", Type = "Agility", Class = "Assassin", Element = "Storm", Zone = 6, Aptitude = 3 },
	{ Id = "umbriel", Name = "Umbriel", Rarity = "Mythical", Type = "Technique", Class = "Mage", Element = "Void", Zone = 6, Aptitude = 2 },
	{ Id = "solkar", Name = "Solkar", Rarity = "Mythical", Type = "Strength", Class = "Warrior", Element = "Fire", Zone = 6, Aptitude = 2 },
}

local byId: { [string]: Row } = {}
for _, row in rows do
	byId[row.Id] = row
end

return {
	List = rows, -- in the roster's order
	ById = byId,
}
