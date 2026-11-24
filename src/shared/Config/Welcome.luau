--!strict
-- What's given, never sold (shared Config; docs/research/cloud-2026-11-24/launch-design.md, section 8, on the
-- director's "ok" of 2026-11-24; Rules.Welcome): the welcome week and the codes. The gifts are the builder's seeds, for
-- research.

export type Code = {
	Id: string, -- what the save keeps; never changes, never reused
	Code: string, -- what a player types, matched without case or spaces
	Chests: { [string]: number }, -- by chest id: no-gear chests only (a crate, a case, a pouch)
	From: number, -- os.time it opens, 0 for always
	Until: number, -- os.time it ends, 0 for never
}

return {
	-- The welcome week: one gift for each day played, in order, never lost, so a missed day only waits. Each is a chest id,
	-- or one of two words:
	--   Case   the elite's Emblem Case of the account's furthest ground, Normal
	--   Named  a Named shard of a launch Voidkin the account doesn't own, the first in the roster's order, chosen and
	--          never rolled. An account that owns all five gets Fallback.
	Week = { "forge_crate", "Case", "jewel_pouch", "Case", "jewel_pouch", "Case", "Named" } :: { string },
	Fallback = "forge_crate",
	-- The codes, one an update, each typed once an account. The director decides where they're posted. None yet.
	Codes = {} :: { Code },
	CodeMost = 32, -- characters a typed code may take
}
