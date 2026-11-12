--!strict
-- Data (shared): the save layer's numbers (Services/Core/DataService).

return {
	-- Operation ids a profile remembers, with their first answers. A client retries within seconds, so a few dozen covers
	-- every retry with room to spare; each costs a GUID and a small answer in the save. The builder's seed, 2026-11-12.
	OpsKept = 32,
	-- A client's request waits this long for its profile to load before it's refused.
	LoadWaitSeconds = 30,
}
