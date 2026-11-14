--!strict
-- Tags (shared): the world contract (handbook/engineering/architecture.md, "The world contract"; docs/engineering-plan.md,
-- "The world contract"). Every CollectionService tag a world stamps and code reads, with its attributes. Whoever builds a
-- world stamps these: WorldService's grey build from Config.World today, an authored Lantern Row later (AR5). Code reads
-- markers only through World.Markers, never a tag's name as a literal, and only those inside workspace.
-- Attribute types are typeof() names; a trailing "?" marks one a marker may leave out. Count: how many a whole world holds
-- (Per = "Plot": that many on each plot). Ground: the marker stands on the floor, so the world report looks for ground under it.
-- No Roblox API: it runs with Studio closed.

export type Spec = {
	Tag: string,
	Attributes: { [string]: string },
	Count: number?, -- nil: any number, one at least
	Per: string?, -- "Plot": Count on each plot
	Ground: boolean?,
}

local specs: { [string]: Spec } = {
	-- A player's plot: its floor, a box the plot fills. Plot is its number, 1 to Config.World.Plots.Count, each once.
	Plot = { Tag = "GA_Plot", Attributes = { Plot = "number" } },
	-- Where the plot's owner arrives, facing the Breaker and the shards (docs/design.md, "The world, in grey").
	Spawn = { Tag = "GA_Spawn", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	Breaker = { Tag = "GA_Breaker", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	-- A worker's bay. Bay is its number on the plot, in the order they open.
	Bay = { Tag = "GA_Bay", Attributes = { Plot = "number", Bay = "number" }, Per = "Plot", Ground = true },
	Battery = { Tag = "GA_Battery", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	-- The Training machine (TR12): one Voidkin at a time trains on it, and a fallen lead comes home before it.
	Training = { Tag = "GA_Training", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	Shop = { Tag = "GA_Shop", Attributes = {}, Count = 1, Ground = true },
	FestivalGate = { Tag = "GA_FestivalGate", Attributes = {}, Count = 1, Ground = true },
	-- A pack's spawn: Count Shades of Def at Level, spread round it. Pack is its number down the street. Type: the outline's
	-- colour, else the Def's own. Ground: the ground it stands in (Definitions.Grounds), whose Standard shard it drops.
	Pack = { Tag = "GA_Pack", Attributes = { Pack = "number", Def = "string", Level = "number", Count = "number", Type = "string?", Ground = "string" }, Ground = true },
	Elite = { Tag = "GA_Elite", Attributes = { Def = "string", Level = "number", Type = "string?", Ground = "string" }, Count = 1, Ground = true },
	KeeperGate = { Tag = "GA_KeeperGate", Attributes = {}, Count = 1, Ground = true },
	-- The keeper's ring: a model whose pivot is its centre, on the floor. A try is fought in a copy of it (KeeperService).
	-- Ground: the ground whose keeper it is (Definitions.Grounds), which a win counts on.
	Ring = { Tag = "GA_Ring", Attributes = { Def = "string", Level = "number", Ground = "string" }, Count = 1, Ground = true },
	-- Where a win sets the player down: beyond the ring, by the shortcut and the shut gate.
	RingExit = { Tag = "GA_RingExit", Attributes = {}, Count = 1, Ground = true },
	-- The shortcut home, opened by the first win: a pad that sets the player down at their own plot.
	Shortcut = { Tag = "GA_Shortcut", Attributes = {}, Count = 1, Ground = true },
	ShutGate = { Tag = "GA_ShutGate", Attributes = {}, Count = 1, Ground = true },
	-- The Festival Door (docs/design.md, "The world, in grey"): a frame on each plot whose way of light (a part named Way)
	-- takes the player to a ground's gate; its twin at each ground's gate (Ground: which) takes them home. DoorLanding: where
	-- the plot's door sets the player down at that ground, facing into it.
	FestivalDoor = { Tag = "GA_FestivalDoor", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	GroundDoor = { Tag = "GA_GroundDoor", Attributes = { Ground = "string" }, Count = 1, Ground = true },
	DoorLanding = { Tag = "GA_DoorLanding", Attributes = { Ground = "string" }, Count = 1, Ground = true },
}

return specs
