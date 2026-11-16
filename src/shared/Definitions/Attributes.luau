--!strict
-- Attributes (shared, content): the five Basic Attributes (docs/research/rework-2026-11-16.md, part 1; the director's
-- yes of 2026-11-16, 16:50, with research's names). Each has a stable id, the working name, so a rename changes only
-- `Name`. An item line whose Stat is one of these ids adds attribute points (Rules.Stats). What each point converts to,
-- each class's Main and its shape: Config.Stats.Attributes.

export type Row = { Id: string, Name: string, Job: string }

local List: { Row } = {
	{ Id = "Might", Name = "Might", Job = "raw power" },
	{ Id = "Finesse", Name = "Finesse", Job = "precision and evasion" },
	{ Id = "Vigor", Name = "Vigor", Job = "toughness" },
	{ Id = "Spirit", Name = "Spirit", Job = "resolve and recovery" },
	{ Id = "Insight", Name = "Insight", Job = "seeing through armour" },
}

local ById: { [string]: Row } = {}
local Ids: { string } = {}
for _, row in List do
	ById[row.Id] = row
	table.insert(Ids, row.Id)
end

return {
	List = List, -- in the sheet's order
	ById = ById,
	Ids = Ids,
}
