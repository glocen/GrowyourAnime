--!strict
-- The Void Shop's numbers (AR38; docs/design.md, "The Void Shop"; Rules.Shop). The shelf at launch is D6's
-- (docs/decisions.md, 2026-11-18): each stock, a Standard shard a player may buy Limit of, and on a featured stock one
-- gear piece. Every price is in Credits, times G at the top level of the ground it names, as salvage is (Rules.Chests),
-- so a price keeps its share of a ground's earnings wherever it's bought.
-- The prices, the chance and the ladder are SEEDS by the builder (2026-11-19), from the sim's income line (about
-- 4,500 x G Credits an hour): research sets them in tools/balance/seeds.json from the simulation, so the shop takes about
-- a quarter of income after five hours (docs/balance.md, "Earning").

return {
	Period = 300, -- seconds a stock stands, on world time (Unix seconds): every server shows the same one
	Warn = 60, -- the last seconds before a stock, when the countdown chip shows under the pills (docs/ui.md)

	Shard = {
		Pool = { "lanternrow_standard" }, -- the Standard shards a stock draws its one from (one at launch)
		Limit = 2, -- a player each stock
		PricePerG = 135, -- seed: 299 at Lantern Row's top
	},

	Featured = {
		Chance = 1 / 6, -- seed: how often a stock holds a piece (the screen says so on it)
		Ground = "lanternrow", -- the piece's tier and worth: a roll as this ground's chests roll (Rules.Chests.Roll)
		Ladder = { 0, 0, 70, 25, 5 }, -- seed: its rarity's weights, Common to Legendary
		Limit = 1, -- a player each stock
		PricePerG = { Rare = 1000, Epic = 2000, Legendary = 4500 } :: { [string]: number }, -- seed
	},
}
