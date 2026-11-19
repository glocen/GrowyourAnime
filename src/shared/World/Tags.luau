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
	Place: string, -- "Main" or "Festival": the other place holds none
}

local specs: { [string]: Spec } = {
	-- A player's plot: its floor, a box the plot fills. Plot is its number, 1 to Config.World.Plots.Count, each once.
	Plot = { Tag = "GA_Plot", Place = "Main", Attributes = { Plot = "number" } },
	-- Where the plot's owner arrives, facing the Breaker and the shards (docs/design.md, "The world, in grey").
	Spawn = { Tag = "GA_Spawn", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	Breaker = { Tag = "GA_Breaker", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	-- A worker's bay. Bay is its number on the plot, in the order they open.
	Bay = { Tag = "GA_Bay", Place = "Main", Attributes = { Plot = "number", Bay = "number" }, Per = "Plot", Ground = true },
	Battery = { Tag = "GA_Battery", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	-- The generator (TR18): the plant's heart, with generation and demand on its face; its prompt opens the Power screen.
	Generator = { Tag = "GA_Generator", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	-- The Training machine (TR12): one Voidkin at a time trains on it, and a fallen lead comes home before it.
	Training = { Tag = "GA_Training", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	-- The ring a Tower run starts from, on the plot's Tower lot (TR29; Rules.Tower.RingSpot).
	TowerRing = { Tag = "GA_TowerRing", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	Shop = { Tag = "GA_Shop", Place = "Main", Attributes = {}, Count = 1, Ground = true },
	FestivalGate = { Tag = "GA_FestivalGate", Place = "Festival", Attributes = {}, Count = 1, Ground = true },
	-- A pack's spawn: Count Shades of Def at Level, spread round it. Pack is its number down the street. Type: the outline's
	-- colour, else the Def's own. Ground: the ground it stands in (Definitions.Grounds), whose Standard shard it drops.
	-- Stage: the stage of the street it belongs to (Config.Stages, TR43), its elite's too: one elite to a stage of packs.
	Pack = { Tag = "GA_Pack", Place = "Festival", Attributes = { Pack = "number", Def = "string", Level = "number", Count = "number", Type = "string?", Ground = "string", Stage = "number" }, Ground = true },
	Elite = { Tag = "GA_Elite", Place = "Festival", Attributes = { Def = "string", Level = "number", Type = "string?", Ground = "string", Stage = "number" }, Ground = true },
	-- A stage's gate (TR43): across the street after stage Stage's last stop, shut to a player until they've cleared that
	-- stage on Normal. A part whose pivot is its middle; the server sets back whoever crosses it shut, the client shows it.
	StageGate = { Tag = "GA_StageGate", Place = "Festival", Attributes = { Stage = "number", Ground = "string" } },
	-- Where a stage's run sets the player down, facing into it: the first by the Door's landing, the next past each gate,
	-- the keeper's before its gate.
	StageStart = { Tag = "GA_StageStart", Place = "Festival", Attributes = { Stage = "number", Ground = "string" }, Ground = true },
	KeeperGate = { Tag = "GA_KeeperGate", Place = "Festival", Attributes = {}, Count = 1, Ground = true },
	-- The keeper's ring: a model whose pivot is its centre, on the floor. A try is fought in a copy of it (KeeperService).
	-- Ground: the ground whose keeper it is (Definitions.Grounds), which a win counts on.
	Ring = { Tag = "GA_Ring", Place = "Festival", Attributes = { Def = "string", Level = "number", Ground = "string" }, Count = 1, Ground = true },
	-- Where a win sets the player down: beyond the ring, by the shortcut and the shut gate.
	RingExit = { Tag = "GA_RingExit", Place = "Festival", Attributes = {}, Count = 1, Ground = true },
	-- The shortcut home, opened by the first win: a pad that sets the player down at their own plot.
	Shortcut = { Tag = "GA_Shortcut", Place = "Festival", Attributes = {}, Count = 1, Ground = true },
	ShutGate = { Tag = "GA_ShutGate", Place = "Festival", Attributes = {}, Count = 1, Ground = true },
	-- The Festival Door (docs/design.md, "The world, in grey"): a frame on each plot whose way of light (a part named Way)
	-- takes the player to a ground's gate; its twin at each ground's gate (Ground: which) takes them home. DoorLanding: where
	-- the plot's door sets the player down at that ground, facing into it.
	FestivalDoor = { Tag = "GA_FestivalDoor", Place = "Main", Attributes = { Plot = "number" }, Count = 1, Per = "Plot", Ground = true },
	GroundDoor = { Tag = "GA_GroundDoor", Place = "Festival", Attributes = { Ground = "string" }, Count = 1, Ground = true },
	DoorLanding = { Tag = "GA_DoorLanding", Place = "Festival", Attributes = { Ground = "string" }, Count = 1, Ground = true },
}

return specs
