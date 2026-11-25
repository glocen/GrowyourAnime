--!strict
-- The boards on the Strip (shared Config; docs/design.md, "Being seen"; TR58; tools/balance/seeds.json, "boards",
-- research, 2026-11-24). Rules.Boards reads it. Two all-time boards live here, each an OrderedDataStore of whole numbers
-- by UserId, posted by the server only and only ever raised; the Tower's week keeps Config.Tower.Board. Each server reads
-- each board's top page at most once every Read seconds, and posts a player's number at most once every Post seconds a
-- board, and as they leave. Budgets (SOURCED, creator-docs, data stores' limits): GetSortedAsync 5 + 2 x players a server
-- a minute, writes 30 + 5 x players; at 8 players, 3 reads against 21 and at most 8 posts against 70 (COMPUTED).

return {
	-- The boards in the order they stand, read left to right by a player coming back from the side street; "News" is the
	-- fourth plate, the last News every-server lines, between them.
	Order = { "Lead", "Week", "News", "Stars" },
	-- The two all-time boards, each its store's name: the lead's Combat Power, and total stars across the collection.
	Stores = { Lead = "BoardLead", Stars = "BoardStars" } :: { [string]: string },
	-- The words over each plate (the content check before they ship).
	Titles = { Lead = "Strongest lead", Week = "The Tower this week", News = "News", Stars = "Most stars" } :: { [string]: string },
	Shown = 10, -- rows a board shows; the viewer's own rank under them when they're outside
	Page = 100, -- the page read, best first; an own rank past it reads "Past the top 100"
	Read = 60, -- seconds a page read is kept on a server
	Post = 120, -- seconds between one player's posts to one board
	News = 8, -- every-server lines the news plate holds
	Look = 5, -- seconds between the server's looks at what waits to be posted (the builder's)
}
