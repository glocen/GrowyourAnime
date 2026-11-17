--!strict
-- Enemies (shared, content): the Shades and keepers, one row each (docs/roster.md, "Enemies: Shades"). A row is what the
-- enemy is; its numbers come from Config.Enemies by its Kind, times G at the level its spawn gives, through Rules.Stats.
-- A spawn gives the level and, for a Shade, the type: the outline's colour (ground 1's are Orange, Red, Green).
-- A Shade wears AR2's rig (Rig "Shade": ServerStorage.Templates.Shade, one mask kept by its role, scaled by Scale). The
-- Lamplighter wears its own (Rig "Lamplighter": ServerStorage.Templates.Lamplighter, AR7), scaled by Scale, and holds its
-- Challenge as a try starts (Enter), and fights in its Ready (Idle) over the doze it's built in. The dummy stays a target, TR2's grey box with a mask shape (Size, in studs). No
-- Roblox API: it runs with Studio closed.

export type Kind = "Ordinary" | "Elite" | "Keeper" | "Dummy"

export type Row = {
	Id: string,
	Name: string, -- on the target's card
	Kind: Kind,
	Action: string?, -- its one action (Definitions.Actions); nil: it never attacks
	Type: string, -- when the spawn gives none
	-- "Shade": AR2's rig, its masks by role; "Box": TR2's grey box; any other: the template of that name, its own rig and
	-- clip set (Config.Animations.Rigs)
	Rig: string,
	Mask: string?, -- Shade: the mask's role (Brawler, Guard, Dasher, Support); Box: its shape (docs/roster.md)
	Scale: number?, -- a rig's size against an ordinary Shade's (the elite's is its box's height over the ordinary's)
	Size: { number }?, -- Box: width, height, depth
	Enter: string?, -- an action it holds as it's spawned, to its end, before it does anything else (Definitions.Actions)
	Idle: string?, -- its own stance's clip, over its rig's Idle (Config.Animations.Rigs; Actions.IdleOf)
}

local rows: { Row } = {
	{ Id = "brawler", Name = "Brawler", Kind = "Ordinary", Action = "ShadeSwipe", Type = "Red", Rig = "Shade", Mask = "Brawler" },
	-- An elite wears its mask twice, the second on its Left Arm (AR2, section 5): only the Brawler's is past the content check.
	{ Id = "brawler_elite", Name = "Brawler", Kind = "Elite", Action = "ShadeSwipe", Type = "Red", Rig = "Shade", Mask = "Brawler", Scale = 1.35 },
	-- AR7: 1.5 an ordinary Shade's size, the hat's top 10.3 studs up (research's pick: taller than the elite)
	{ Id = "lamplighter", Name = "the Lamplighter", Kind = "Keeper", Action = "KeeperSwing", Type = "Purple", Rig = "Lamplighter", Scale = 1.5, Enter = "KeeperChallenge", Idle = "LamplighterReady" },
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
