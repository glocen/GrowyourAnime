--!strict
-- Jewels (shared, numbers): every gear piece holds five, one of each colour, and a jewel gives flat points of its colour's
-- Basic Attribute (the director, 2026-11-19, 03:10; docs/design.md, "Jewels"). Five levels at launch, three of one level
-- making one of the next (2026-11-17, 12:10). Finished for launch on the director's "ok" of 2026-11-24
-- (docs/research/cloud-2026-11-24/launch-design.md, sections 5 and 12). Read by Rules.Jewels.

return {
	-- The colours, in the page's order, and the attribute each gives.
	Colours = { "Red", "Green", "Blue", "Yellow", "Purple" } :: { string },
	Attribute = { Red = "Strength", Green = "Agility", Blue = "Intelligence", Yellow = "Endurance", Purple = "Spirit" } :: { [string]: string },
	-- Points of the colour's attribute by level (research's seeds, TR47 part B: each merge keeps two thirds, so the
	-- sockets are what make a merge worth it). Its length is the top level at launch.
	Points = { 1, 2, 4, 8, 16 } :: { number },
	Merge = 3, -- jewels of one colour and level that make one of the next
}
