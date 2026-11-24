--!strict
-- Jewels (shared config): what a jewel gives and where it comes from (TR56; docs/design.md, "Jewels"; seeds.json,
-- "jewels"). Every gear piece holds five, one of each colour; a jewel gives flat points of its colour's Basic Attribute
-- (the director, 2026-11-19, 03:10), and every colour's are priced to the same Combat Power, as a gear line's are
-- (Rules.Jewels.Points). Five tiers at launch. Read by Rules.Jewels; the screen's colours are Config.Hud's.
-- Tuned by playing: NL_Debug:Invoke("Tune", "Jewels.<path>", value).

return {
	Colours = { "Red", "Green", "Blue", "Yellow", "Purple" }, -- in the order every list shows them
	Attribute = { Red = "Strength", Green = "Agility", Blue = "Intelligence", Yellow = "Endurance", Purple = "Spirit" } :: { [string]: string },
	-- A jewel's points: round(TopUnits x Worth[tier] / the attribute's price (Rules.Price)), at least 1. TopUnits is the
	-- jewels' share against the emblems' of a Legendary emblem's weight units (seeds "jewels").
	TopUnits = 102,
	Worth = { 0.15, 0.3, 0.5, 0.75, 1.0 },
	-- The Stone Condenser makes one jewel each EveryHours of its work into its tray, the colours in turn (Order's), its
	-- tier the highest whose level From has reached (Rules.Condenser).
	Condenser = { EveryHours = 4, From = { 1, 8, 16 } },
}
