--!strict
-- Attributes (shared, content): the five Basic Attributes (docs/design.md, "Voidkin"; the director, 2026-11-19, 03:10).
-- Each has a stable id, the working name, so a rename changes only `Name`. An item line whose Stat is one of these ids adds
-- attribute points (Rules.Stats).

export type Row = { Id: string, Name: string, Job: string }

local List: { Row } = {
	{ Id = "Strength", Name = "Strength", Job = "power" },
	{ Id = "Agility", Name = "Agility", Job = "precision" },
	{ Id = "Intelligence", Name = "Intelligence", Job = "element" },
	{ Id = "Endurance", Name = "Endurance", Job = "toughness" },
	{ Id = "Spirit", Name = "Spirit", Job = "resolve" },
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
