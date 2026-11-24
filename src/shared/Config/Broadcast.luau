--!strict
-- The Broadcast (shared Config; docs/research/cloud-2026-11-24/launch-design.md, section 6, on the director's "ok" of
-- 2026-11-24; Rules.Broadcast): what's worth telling, to this server ("Server") or to every server ("All"), and how
-- often. The reach of each is the section's ladder; every number is the builder's seed, for research.

return {
	-- An item a chest gave, kept in the bag, by its rarity. One line an open, its rarest.
	Item = { Legendary = "All", Epic = "Server" } :: { [string]: string },
	-- A Reinforce success at All's level or past it reaches every server, at Server's this one.
	Reinforce = { All = 20, Server = 15 },
	-- A Voidkin raised to Config.Voidkin.MaxStars.
	Stars = "All",
	-- An account's first Voidkin of a rarity.
	First = { Rare = "Server" } :: { [string]: string },
	-- A keeper's first win on a difficulty.
	Keeper = { Hard = "Server" } :: { [string]: string },
	-- This server's record in the Tower: a run's last floor past every run's that ended here, from Least up.
	Record = { Least = 10, Reach = "Server" },
	-- A new first place on the Tower's weekly board, from Least floors up.
	Board = { Least = 10, Reach = "All" },
	-- The light of a line with no rarity of its own (UI: the rarity's colour).
	Light = { Keeper = "Epic", Record = "Rare", Board = "Legendary" } :: { [string]: string },

	Every = 600, -- seconds: one every-server line per player this often; another inside it is told on this server only
	Most = 12, -- lines a server shows in Window seconds at most; past it they wait, the oldest waiting dropped first
	Window = 60,
	Waiting = 12, -- lines held waiting at most
	Topic = "Broadcast", -- the MessagingService topic, after the place's prefix (a playtest never tells a live server)
	-- The client's line at the top centre: shown Seconds, held while a keeper's try, a reveal or a menu is up; at most
	-- Waiting held, and one held past Stale seconds is dropped (the chat keeps it).
	Banner = { Seconds = 4, Waiting = 3, Stale = 30 },
}
