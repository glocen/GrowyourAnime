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
	Health: number?, -- its health against its Kind's (Rules.Stats.Enemy): AR58's Support is fragile; nil is 1
	Size: { number }?, -- Box: width, height, depth
	Enter: string?, -- an action it holds as it's spawned, to its end, before it does anything else (Definitions.Actions)
	-- its signature, tried before its Action whenever it's ready; the first ready First seconds after its Enter ends
	Signature: string?,
	First: number?, -- seconds; nil: Config.Combat.Keeper.First (TR44: the Lamplighter's slam)
	Idle: string?, -- its own stance's clip, over its rig's Idle (Config.Animations.Rigs; Actions.IdleOf)
	Marker: string?, -- its picture on the down marker's tile (TR10), a Config.UIKit image; nil: the name's letter
	-- Hard's behaviour (TR69 E: one rule per role; FightService, Rules.Fight.MayStart and Again): InTurn, a Guard raises
	-- only while no other Guard on its lead is raising, so their shields go up in turn and never all drop at once;
	-- Lunges, a Dasher's lunges in a run, each from where the last left it, aimed afresh.
	Hard: { InTurn: boolean?, Lunges: number? }?,
	-- Its signature comes once Every - 1 of its Action have started since the last, never by a clock (TR69 B: the Brawler
	-- elite's every third swing is an overhead); First is then unused
	Every: number?,
}

local rows: { Row } = {
	{ Id = "brawler", Name = "Brawler", Kind = "Ordinary", Action = "ShadeSwipe", Type = "Red", Rig = "Shade", Mask = "Brawler" },
	-- AR52: the Guard raises a paper shield, the Dasher lunges down a line; between, each swings as a Brawler. Each is
	-- ready First seconds after it's spawned; a stretch's pack stands long before its fight, so each opens with its own.
	{ Id = "guard", Name = "Guard", Kind = "Ordinary", Action = "ShadeSwipe", Signature = "GuardRaise", First = 0, Type = "Green", Rig = "Shade", Mask = "Guard", Hard = { InTurn = true } },
	{ Id = "dasher", Name = "Dasher", Kind = "Ordinary", Action = "ShadeSwipe", Signature = "DasherLunge", First = 1.5, Type = "Orange", Rig = "Shade", Mask = "Dasher", Hard = { Lunges = 2 } },
	-- AR58: the Support keeps to its pack's back and lifts its sleeves, and a hurt one of its pack comes back up, or a whole
	-- one takes a shield (SupportCast; Rules.Support). Fragile: slighter, and less health than its kin. Alone, it swings
	-- as a Brawler. Seeds, tuned once the Guard and the Dasher are played (the director's pick, 2026-11-23).
	{ Id = "support", Name = "Support", Kind = "Ordinary", Action = "ShadeSwipe", Signature = "SupportCast", First = 1, Type = "Orange", Rig = "Shade", Mask = "Support", Scale = 0.9, Health = 0.6 },
	-- An elite wears its mask twice, the second on its Left Arm (AR2, section 5). AR57: the Guard's and the Dasher's elites
	-- ask their kin's question at the elite's size, and play their own clips of the same beats (Config.Animations.Kinds).
	-- TR69 B: each elite is its stage's role and one move of its own (research's feel line, 2026-11-26, 22:05): the
	-- Brawler's overhead every third swing, the Guard's screen, the Dasher's fan (Definitions.Actions).
	{ Id = "brawler_elite", Name = "Brawler", Kind = "Elite", Action = "ShadeSwipe", Signature = "ShadeOverhead", Every = 3, Type = "Red", Rig = "Shade", Mask = "Brawler", Scale = 1.35, Marker = "MarkerElite" },
	{ Id = "guard_elite", Name = "Guard", Kind = "Elite", Action = "ShadeSwipe", Signature = "GuardScreen", First = 0, Type = "Green", Rig = "Shade", Mask = "Guard", Scale = 1.35, Marker = "MarkerElite", Hard = { InTurn = true } },
	{ Id = "dasher_elite", Name = "Dasher", Kind = "Elite", Action = "ShadeSwipe", Signature = "DasherFan", First = 1.5, Type = "Orange", Rig = "Shade", Mask = "Dasher", Scale = 1.35, Marker = "MarkerElite", Hard = { Lunges = 2 } },
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
