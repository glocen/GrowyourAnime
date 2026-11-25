--!strict
-- The Broadcast (shared Config; docs/design.md, "Being seen"; TR57; tools/balance/seeds.json, "broadcast", research,
-- 2026-11-24): what's told, to this server ("Server") or to every server ("All"), and how often. Rules.Broadcast reads
-- it. Least, Light and Bytes are the builder's, not the seeds'.

return {
	-- An item a chest gave and the bag kept, by its rarity. Dawn is a Legendary series (docs/design.md, "Gear"), so
	-- Legendary tells it too. One line an open, its rarest.
	Item = { Legendary = "All", Epic = "Server" } :: { [string]: string },
	-- A Reinforce that succeeded, to All's level or past it: every server; to Server's: this one.
	Reinforce = { All = 20, Server = 15 },
	Stars = "All", -- a Voidkin raised to Config.Voidkin.MaxStars
	-- The account's first Voidkin of a rarity, from Rare up (Lyric, at launch).
	First = { Rare = "Server", Epic = "Server", Legendary = "Server", Mythical = "Server" } :: { [string]: string },
	Keeper = { Hard = "Server" } :: { [string]: string }, -- a keeper's first fall on a difficulty
	-- This server's best Tower floor today (Goals.DayOf's day), and a new first place on the Tower's week, each from
	-- Least floors up, so a day's first short climb isn't news.
	Record = { Least = 10, Reach = "Server" },
	Board = { Least = 10, Reach = "All" },
	-- The light of a line with no rarity of its own.
	Light = { Keeper = "Epic", Record = "Rare", Board = "Legendary" } :: { [string]: string },

	Every = 600, -- seconds: one every-server line a player this often (seeds' 10 minutes); one inside it is told on this server
	Bundle = 5, -- seconds: a server publishes at most one message this often, every line waiting in it
	Bytes = 1000, -- a message's size at most, as JSON, counted high (Rules.Broadcast.Size): under MessagingService's 1 kB
	-- The plate at the top centre: shown Seconds, at most one every Gap seconds (start to start), and a line still
	-- waiting after Stale seconds goes to the chat only.
	Plate = { Seconds = 4, Gap = 20, Stale = 60 },
	ChatKeeps = true, -- each line stays in the chat as a system line
	NewsLines = 8, -- the news board's every-server lines (TR58)
	Topic = "Broadcast", -- the MessagingService topic, after "Test" or "Live": a playtest never tells a live server
}
