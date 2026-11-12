--!strict
-- Base (shared): the numbers of a player's base: the Void Breaker, the bays, the battery. Seeds from tools/balance/seeds.json
-- ("bays", "shards") until play tunes them; once here, this is their home (docs/design.md, "The base").

return {
	-- What a new profile starts with (Shared.Data.Profile.Template). Read when the store opens, so a tune reaches new
	-- profiles only after a restart.
	Start = {
		Chambers = 2, -- seeds "bays.chambersByGround", ground 1
		Bays = 1, -- TR2: one bay open and the second locked
		-- The battery starts holding one Standard shard's work, so Watt's shard breaks at full speed before any worker
		-- exists (docs/north-star.md, "The first session": nothing waits more than about half a minute). The builder's
		-- seed, 2026-11-12, to be confirmed at the Breaker's build.
		Battery = 20,
	},
}
