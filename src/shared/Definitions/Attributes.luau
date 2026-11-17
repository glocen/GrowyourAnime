--!strict
-- Attributes (shared, content): the two Basic Attributes, Strength and Endurance (docs/design.md, "Voidkin"; the
-- director's word of 2026-11-17, "just strenght and endurance", which replaced the five of 2026-11-16; TR36). Each has a
-- stable id, the working name, so a rename changes only `Name`. An item line whose Stat is one of these ids adds
-- attribute points (Rules.Stats). What each point converts to, each class's Main and its shape: Config.Stats.Attributes.

export type Row = { Id: string, Name: string, Job: string }

local List: { Row } = {
	{ Id = "Strength", Name = "Strength", Job = "power" },
	{ Id = "Endurance", Name = "Endurance", Job = "toughness" },
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
