--!strict
-- The Void Shop's Exchange (TR76; docs/design.md, "The Strip", "The Exchange"; Rules.Exchange): a week's offers, the
-- same every week, nothing random, each with its own limit a player per week, paid in a bag token (Definitions.Tokens:
-- Arena Seals from the Colosseum, Tower Crests from the Tower). A week starts Monday 00:00 UTC.
-- PLACEHOLDERS, the builder's of 2026-11-28, until research sets them in tools/balance/seeds.json with the simulation.
-- Waiting: the trims for the base and the plinth (with the base's overhaul, the director's word of 2026-11-28, 11:32).

export type Offer = {
	Id: string,
	Kind: "Named" | "Emblem" | "Token", -- a copy of a picked Voidkin; an emblem of a picked set and stat; a bag token
	Token: string, -- what it's paid in (Definitions.Tokens)
	Price: number, -- tokens a buy
	Limit: number, -- buys a player each week
	Each: number?, -- Token: how many a buy lands
	Gives: string?, -- Token: the token it lands (Definitions.Tokens)
	Rarity: string?, -- Emblem: the sets' rarity a player picks from (Definitions.Emblems)
	Pool: { string }?, -- Named: the Voidkin a player picks from (Definitions.Voidkin)
}

local offers: { Offer } = {
	-- Lyric isn't in the pool: her Named shard is the welcome week's reward only (TR59), as in the Shop's sixth slot.
	{ Id = "named", Kind = "Named", Token = "Seal", Price = 40, Limit = 2, Pool = { "rook", "kirra", "pip", "watt" } },
	{ Id = "emblem", Kind = "Emblem", Token = "Crest", Price = 25, Limit = 2, Rarity = "Rare" },
	{ Id = "manual_seal", Kind = "Token", Token = "Seal", Price = 10, Limit = 3, Each = 1, Gives = "Manual" },
	{ Id = "manual_crest", Kind = "Token", Token = "Crest", Price = 10, Limit = 3, Each = 1, Gives = "Manual" },
}

local byId: { [string]: Offer } = {}
for _, offer in offers do
	byId[offer.Id] = offer
end

return {
	Week = 604800, -- seconds in a week
	Monday = 345600, -- the first Monday 00:00 UTC after Unix time 0 (Thursday, 1970-01-01), in seconds
	Offers = offers,
	ById = byId,
}
