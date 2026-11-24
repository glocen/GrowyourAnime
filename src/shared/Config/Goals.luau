--!strict
-- Goals (config): the numbers of today's three, the bank and the dares (docs/test-requests.md, TR54; the rows and words
-- are Definitions.Goals, the rules Rules.Goals). Seeds, tuned by playing (Tune "Goals.Held").
return {
	Bank = 3, -- days a day's goals stay to be done and claimed, today's included: nine goals at most
	-- What each goal pays when claimed: one shard of Lantern Row's, so each pays a reveal (design.md: shards and forge
	-- stones only, never anything sold).
	Reward = { Shard = "lanternrow_standard", Count = 1 },
	-- A kept dare pays one forge stone of its ground's grade as its stretch clears (TR54's seed).
	Dare = { Grade = { lanternrow = "Low" } :: { [string]: string }, Count = 1 },
	-- The pieces each stretch's own dare needs (Definitions.Goals.Dares' Needs): until one is in, its stretch takes the
	-- fallback. TR52's tap and AR52's Guard and Dasher are in; TR44's slam and its lead movement were already.
	Ready = { Guard = true, Dasher = true, Slam = true } :: { [string]: boolean },
	Held = 3, -- seconds a stretch's dare stays open under the run's line before it folds to its mark
}
