--!strict
-- How many exist (docs/design.md, "Voidkin", "How many exist"; the outside review's item 4, research, 2026-11-25): each
-- new Voidkin's number, handed out in blocks per kind, and the count of accounts that hold its kind. The builder's
-- numbers, not the seeds'.

return {
	-- The count's era. Every number and every count belong to one; a save numbered in another is numbered again. The
	-- live store's count starts at the first public build (the design's "From when"): change this word on that build,
	-- once, and never back. Studio's saves count apart in the Test store whatever it says.
	Epoch = "Before",
	Block = 5, -- numbers a server reserves for a kind at a time: the fewer, the closer the order to the breaks'
	Flush = 60, -- seconds between this server's writes of the grants it has made
	Read = 300, -- seconds between reads of every kind's count
	Retry = 30, -- seconds before a failed read or write is tried again
	Folder = "Exist", -- ReplicatedStorage's folder: one attribute per kind, the count shown
}
