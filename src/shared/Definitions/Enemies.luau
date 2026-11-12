--!strict
-- Enemies (shared, content): the Shades and keepers, one row each (docs/roster.md, "Enemies: Shades"). A row is what the
-- enemy is; its numbers come from Config.Enemies by its Kind, times G at the level its spawn gives, through Rules.Stats.
-- A spawn gives the level and, for a Shade, the type: the outline's colour (ground 1's are Endurance, Strength, Technique).
-- TR2's bodies are grey boxes with a mask shape (Size, in studs); AR2's Shade rig replaces them.
-- No Roblox API: it runs with Studio closed.

export type Kind = "Ordinary" | "Elite" | "Keeper" | "Dummy"

export type Row = {
	Id: string,
	Name: string, -- on the target's card
	Kind: Kind,
	Action: string?, -- its one action (Definitions.Actions); nil: it never attacks
	Type: string, -- when the spawn gives none
	Size: { number }, -- the box: width, height, depth
	Mask: string, -- the mask's shape on the box (docs/roster.md): Round, Square, Long, Half
}

local rows: { Row } = {
	{ Id = "brawler", Name = "Brawler", Kind = "Ordinary", Action = "ShadeSwipe", Type = "Strength", Size = { 2.6, 4.6, 1.6 }, Mask = "Round" },
	{ Id = "brawler_elite", Name = "Brawler", Kind = "Elite", Action = "ShadeSwipe", Type = "Strength", Size = { 3.6, 6.2, 2.2 }, Mask = "Round" },
	{ Id = "lamplighter", Name = "the Lamplighter", Kind = "Keeper", Action = "KeeperSwing", Type = "Intelligence", Size = { 4.2, 7.4, 2.6 }, Mask = "Round" },
	-- The replay's and the self-test's target: takes every hit, never answers.
	{ Id = "dummy", Name = "Dummy", Kind = "Dummy", Action = nil, Type = "", Size = { 2.6, 4.6, 1.6 }, Mask = "Round" },
}

local Enemies = {}
Enemies.List = rows
Enemies.ById = {} :: { [string]: Row }
for _, row in rows do
	Enemies.ById[row.Id] = row
end

return Enemies
