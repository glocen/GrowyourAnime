--!strict
-- What's given, never sold (shared Config; docs/design.md, "The welcome week and codes"; TR59; tools/balance/seeds.json,
-- "welcomeWeek" and "codes", research, 2026-11-24): the welcome week and the codes. Rules.Welcome and Rules.Codes read it.

-- A gift: a chest by id (Definitions.Chests) or a shard by id (Definitions.Shards), Count of it. Never Credits, never
-- anything the store sells for Robux.
export type Gift = { Chest: string?, Shard: string?, Count: number }

-- A code: Id is what the save keeps, never changed or reused; Code what a player types, matched without case or spaces;
-- Until the os.time it ends, 0 for never.
export type Code = { Id: string, Code: string, Gives: { Gift }, Until: number }

return {
	-- One gift for each UTC day the account plays, in order: a missed day only waits, and the week ends with the seventh.
	-- Day 2's and 6's Emblem Case is Lantern Row's elite's (Normal), rolled as that chest's; day 7 is Lyric's Named shard
	-- for everyone, a copy toward Lyric's next star when Lyric is owned.
	Week = {
		{ Chest = "crate", Count = 1 },
		{ Chest = "lanternrow_2_case", Count = 1 },
		{ Shard = "lanternrow_standard", Count = 2 },
		{ Chest = "pouch", Count = 1 },
		{ Chest = "crate", Count = 1 },
		{ Chest = "lanternrow_2_case", Count = 1 },
		{ Shard = "named_lyric", Count = 1 },
	} :: { Gift },
	-- The row shows from the end of the first session's script: the keeper's gate reached (Rules.Funnel's "Want"), so
	-- the first ten minutes stay as written (docs/north-star.md). The builder's reading of the seeds' "firstRunEnd".
	ShowsAfter = "Want",
	Codes = {
		-- The codes themselves are the server's (ServerScriptService.Server.Config.Codes), so none reaches a client.
		-- What a code may give: a crate, an Emblem Case, a pouch or Standard shards (the seeds' "pays").
		Pays = { Chests = { "crate", "pouch", "lanternrow_2_case" }, Shards = { "lanternrow_standard" } },
		Tries = 5, -- wrong tries a minute,
		Wait = 60, -- then this many seconds' wait
		Most = 32, -- characters a typed code may take
	},
}
