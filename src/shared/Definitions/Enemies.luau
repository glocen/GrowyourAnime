--!strict
-- Enemies (shared, content): the Shades and keepers, one row each (docs/roster.md, "Enemies: Shades"). A row is what the
-- enemy is; its numbers come from Config.Enemies by its Kind, times G at the level its spawn gives, through Rules.Stats.
-- A spawn gives the level and, for a Shade, the type: the outline's colour (ground 1's are Endurance, Strength, Technique).
-- A Shade wears AR2's rig (Rig "Shade": ServerStorage.Templates.Shade, one mask kept by its role, scaled by Scale). The
-- keeper waits for its own sheet and the dummy stays a target, so both are TR2's grey boxes with a mask shape (Size, in
-- studs). No Roblox API: it runs with Studio closed.

export type Kind = "Ordinary" | "Elite" | "Keeper" | "Dummy"

export type Row = {
	Id: string,
	Name: string, -- on the target's card
	Kind: Kind,
	Action: string?, -- its one action (Definitions.Actions); nil: it never attacks
	Type: string, -- when the spawn gives none
	Rig: "Shade" | "Box",
	Mask: string, -- Shade: the mask's role (Brawler, Guard, Dasher, Support); Box: its shape (docs/roster.md)
	Scale: number?, -- Shade: the rig's size against an ordinary Shade's (the elite's is its box's height over the ordinary's)
	Size: { number }?, -- Box: width, height, depth
}

local rows: { Row } = {
	{ Id = "brawler", Name = "Brawler", Kind = "Ordinary", Action = "ShadeSwipe", Type = "Strength", Rig = "Shade", Mask = "Brawler" },
	-- The elite's second mask on its shoulder waits on AR2 (docs/asset-requests.md).
	{ Id = "brawler_elite", Name = "Brawler", Kind = "Elite", Action = "ShadeSwipe", Type = "Strength", Rig = "Shade", Mask = "Brawler", Scale = 1.35 },
	{ Id = "lamplighter", Name = "the Lamplighter", Kind = "Keeper", Action = "KeeperSwing", Type = "Intelligence", Rig = "Box", Mask = "Round", Size = { 4.2, 7.4, 2.6 } },
	-- The replay's and the self-test's target: takes every hit, never answers.
	{ Id = "dummy", Name = "Dummy", Kind = "Dummy", Action = nil, Type = "", Rig = "Box", Mask = "Round", Size = { 2.6, 4.6, 1.6 } },
}

local Enemies = {}
Enemies.List = rows
Enemies.ById = {} :: { [string]: Row }
for _, row in rows do
	Enemies.ById[row.Id] = row
end

return Enemies
