--!strict
-- Tokens (shared, content): the bag's plain counted items that are neither shards, chests, stones, emblems nor jewels,
-- keyed by an id that never changes, counted in the save's Bag.Tokens (docs/design.md, TR76, the director's yes of
-- 2026-11-28, 11:32):
--   Manual  a Skill Manual: raises a signature's level with Credits (Rules.Signature); from Wardens, the Void Shop's
--           rotating slot and the weekly Exchange ("Growing a Voidkin")
--   Seal    an Arena Seal: the Colosseum's, spent at the weekly Exchange ("The Strip")
--   Crest   a Tower Crest: the Tower's, spent at the weekly Exchange ("The Tower", "The Strip")
-- No Roblox API: it runs with Studio closed.

export type Row = {
	Id: string,
	Name: string, -- what players read, one and many
	Plural: string,
}

local rows: { Row } = {
	{ Id = "Manual", Name = "Skill Manual", Plural = "Skill Manuals" },
	{ Id = "Seal", Name = "Arena Seal", Plural = "Arena Seals" },
	{ Id = "Crest", Name = "Tower Crest", Plural = "Tower Crests" },
}

local Tokens = {}

Tokens.List = rows
Tokens.ById = {} :: { [string]: Row }
for _, row in rows do
	Tokens.ById[row.Id] = row
end

return Tokens
