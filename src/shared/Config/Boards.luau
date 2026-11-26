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
	-- A face shows the Top rows, then a fourth: the viewer's own, lit, when they stand outside them, else the next row, so
	-- a viewer among the top is lit where they stand (research's must-fix on TR58, 2026-11-26, in place of the top ten;
	-- the full list waits for a tap, with TR33). The server sends Top + 1 rows.
	Top = 3,
	Page = 100, -- the page read, best first; an own rank past it reads "100+"
	-- A face in authored pixels, Pixels a stud (a 14 by 9 stud plate draws 560 by 360), drawn from Reach studs: the title,
	-- then four rows of 54-point words, 2.7 times TR58's first 20 (research: about three times, read from the path's
	-- nearest point on the smallest phone). A rank's column is Rank wide, or its widest rank's; a name takes what its
	-- rank and number leave, Space round it, cut with an ellipsis past it. The viewer's row in the light at Lit.
	Face = {
		Pixels = 40,
		Reach = 120,
		Pad = 10,
		Title = { Size = 36, Tall = 42 },
		Gap = 4,
		Row = { Tall = 73, Size = 54 },
		Rank = 96,
		Space = 14,
		Lit = 0.4,
		News = { Size = 40, Tall = 98 }, -- a news line in the same type, wrapped to two lines at most
	},
	Read = 60, -- seconds a page read is kept on a server
	Post = 120, -- seconds between one player's posts to one board
	News = 3, -- every-server lines the news plate holds, newest first
	Look = 5, -- seconds between the server's looks at what waits to be posted (the builder's)
}
