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
	-- its signature, tried before its Action whenever it's ready; the first ready First seconds after its Enter ends
	Signature: string?,
	First: number?, -- seconds; nil: Config.Combat.Keeper.First (TR44: the Lamplighter's slam)
	Idle: string?, -- its own stance's clip, over its rig's Idle (Config.Animations.Rigs; Actions.IdleOf)
	Marker: string?, -- its picture on the down marker's tile (TR10), a Config.UIKit image; nil: the name's letter
}

local rows: { Row } = {
	{ Id = "brawler", Name = "Brawler", Kind = "Ordinary", Action = "ShadeSwipe", Type = "Red", Rig = "Shade", Mask = "Brawler" },
	-- AR52: the Guard raises a paper shield, the Dasher lunges down a line; between, each swings as a Brawler. Each is
	-- ready First seconds after it's spawned; a stretch's pack stands long before its fight, so each opens with its own.
	{ Id = "guard", Name = "Guard", Kind = "Ordinary", Action = "ShadeSwipe", Signature = "GuardRaise", First = 0, Type = "Green", Rig = "Shade", Mask = "Guard" },
	{ Id = "dasher", Name = "Dasher", Kind = "Ordinary", Action = "ShadeSwipe", Signature = "DasherLunge", First = 1.5, Type = "Orange", Rig = "Shade", Mask = "Dasher" },
	-- An elite wears its mask twice, the second on its Left Arm (AR2, section 5): only the Brawler's is past the content check.
	{ Id = "brawler_elite", Name = "Brawler", Kind = "Elite", Action = "ShadeSwipe", Type = "Red", Rig = "Shade", Mask = "Brawler", Scale = 1.35, Marker = "MarkerElite" },
	-- AR7: 1.5 an ordinary Shade's size, the hat's top 10.3 studs up (research's pick: taller than the elite)
	{ Id = "lamplighter", Name = "the Lamplighter", Kind = "Keeper", Action = "KeeperSwing", Signature = "KeeperSignature", Type = "Purple", Rig = "Lamplighter", Scale = 1.5, Enter = "KeeperChallenge", Idle = "LamplighterReady", Marker = "MarkerLamplighter" },
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
