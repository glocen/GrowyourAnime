--!strict
-- The Void Shop's numbers (AR38; docs/design.md, "The Strip", "The Void Shop"; Rules.Shop). TR76's rework (the director's
-- yes of 2026-11-28, 11:32, replacing D6's shelf): six slots, each with its own limit a player per stock, and the weekly
-- Exchange (Rules.Exchange, Config.Exchange). A Credits price is times G at the top level of the ground it names
-- (Ground, below), as salvage is (Rules.Chests), so it keeps its share of a ground's earnings; a kWh price is flat.
-- PLACEHOLDERS, the builder's of 2026-11-28 unless marked as the old seeds, until research sets them in
-- tools/balance/seeds.json with the simulation, so the shop takes about a quarter of a player's spending from the first
-- hour (docs/design.md, "The Credits it takes").

return {
	Period = 300, -- seconds a stock stands, on world time (Unix seconds): every server shows the same one
	Warn = 60, -- the last seconds before a stock, when the countdown chip shows under the pills (docs/ui.md)
	Ground = "lanternrow", -- the ground whose top level prices the Credits lines and whose chests the gear rolls as

	-- 1. Always: Standard shards (the old seeds: 299 Credits at Lantern Row's top, two a stock, bought by a new player by
	-- minute 10).
	Shard = {
		Pool = { "lanternrow_standard" }, -- the Standard shards a stock draws its one from (one at launch)
		Limit = 2,
		PricePerG = 135,
	},

	-- 2. Always: a forge stone bundle, or now and then (Manual.Chance) a Skill Manual, for Credits.
	Supply = {
		Limit = 1,
		Stones = { Grade = "Low", Each = 3, PricePerG = 60 }, -- Config.Reinforce.Grades
		Manual = { Chance = 0.15, Each = 1, PricePerG = 400 },
	},

	-- 3. Always: the Power Deal, for the battery's kWh: one of Pool, evenly. The design's Voltage cell joins when it's
	-- defined (TR76, research's to write).
	Power = {
		Limit = 1,
		Pool = {
			{ Chest = "pouch", Kwh = 20 }, -- a Jewel Pouch
			{ Chest = "towercase_rare", Kwh = 15 }, -- an Emblem Case (a Rare one, as the Tower's tenth floor gives)
		} :: { { Chest: string, Kwh: number } },
	},

	-- 4. Often: a gear piece, rolled as the ground's chests roll on Ladder's weights (Common to Legendary; the old seeds).
	Featured = {
		Chance = 0.6,
		Limit = 1,
		Ladder = { 0, 0, 70, 25, 5 },
		PricePerG = { Rare = 1000, Epic = 2000, Legendary = 4500 } :: { [string]: number }, -- the old seeds
	},

	-- 5. Sometimes: an emblem of Emblem's rarity (its set and stat drawn), or a jewel of Jewel's tier (its colour drawn),
	-- evenly. It lights the Shop's crown on the Strip. The design's Enriched shard joins when one exists (Definitions.Shards
	-- has none yet).
	Crown = {
		Chance = 0.25,
		Limit = 1,
		Emblem = { Rarity = "Rare", PricePerG = 600 },
		Jewel = { Tier = 2, PricePerG = 700 },
	},

	-- 6. Rarely, about once in four hours (48 stocks): a Legendary gear piece, or a Named shard of a launch Voidkin,
	-- evenly. It goes out on the Broadcast. The design's Dawn series joins when gear has one in code.
	Legend = {
		Chance = 1 / 48,
		Limit = 1,
		Gear = { Rarity = "Legendary", PricePerG = 4500 },
		-- Watt's alone: Lyric's Named shard is the welcome week's seventh, never sold or dropped (TR59), until research says
		Named = { Pool = { "named_watt" }, PricePerG = 3000 },
	},
}
