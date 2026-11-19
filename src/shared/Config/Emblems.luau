--!strict
-- Emblems (shared, numbers): what a War Emblem gives (TR47, research's seeds, from docs/balance.md's shares; tuned by
-- play and by the loot refit). Read by Rules.Emblems.
-- An emblem's points are its stat's row at Legendary times its rarity's worth, rounded: the worth is a share of 142
-- Combat Power weight units, the emblem share (11 of 27 against gear) over 56 sockets at a full launch build, priced by
-- Config.Stats's weights. When the combat review is accepted, the rows are re-priced with its weights; only numbers move.

return {
	Worth = { Uncommon = 0.25, Rare = 0.45, Epic = 0.7, Legendary = 1.0 } :: { [string]: number },
	Points = { Attack = 32, Health = 149, Defence = 73, Critical = 814, Hit = 530, Dodge = 294 } :: { [string]: number },
	-- Epic and Legendary only, set by the stats' caps rather than by price: a price measured at small values doesn't hold
	-- for a capped stat. Lifesteal is a share (0.01 is 1%).
	High = {
		Epic = { CriticalDamage = 0.04, CriticalGuard = 0.04, Lifesteal = 0.01 },
		Legendary = { CriticalDamage = 0.06, CriticalGuard = 0.06, Lifesteal = 0.015 },
	} :: { [string]: { [string]: number } },
}
