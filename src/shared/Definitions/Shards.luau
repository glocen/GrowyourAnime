--!strict
-- Shards (shared, content): every kind of Void Shard, keyed by an id that never changes (docs/design.md, "Shards and the Void
-- Breaker"). A shard belongs to a ground, which sets whose Voidkin it can hold. A Named or Starter shard holds one stated
-- Voidkin, never a roll. How long a grade takes and what it costs are in Config.Shards, by grade.
-- TR2 holds ground 1's: its Standard shard, Watt's Named shard, and the three starters (docs/decisions.md, D01).

export type Grade = "Standard" | "Enriched" | "Prismatic" | "Named" | "Starter"

export type Row = {
	Id: string,
	Grade: Grade,
	Ground: string, -- Definitions.Grounds
	Holds: string, -- the one Voidkin of a Named or Starter shard, or "" for a shard that rolls
}

local rows: { Row } = {
	{ Id = "lanternrow_standard", Grade = "Standard", Ground = "lanternrow", Holds = "" },
	{ Id = "named_watt", Grade = "Named", Ground = "lanternrow", Holds = "watt" },
	{ Id = "starter_rook", Grade = "Starter", Ground = "lanternrow", Holds = "rook" },
	{ Id = "starter_kirra", Grade = "Starter", Ground = "lanternrow", Holds = "kirra" },
	{ Id = "starter_pip", Grade = "Starter", Ground = "lanternrow", Holds = "pip" },
}

local byId: { [string]: Row } = {}
for _, row in rows do
	byId[row.Id] = row
end

return {
	List = rows,
	ById = byId,
	-- The three a new player picks one from, in the order they're shown.
	Starters = { "starter_rook", "starter_kirra", "starter_pip" },
}
