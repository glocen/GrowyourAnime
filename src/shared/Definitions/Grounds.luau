--!strict
-- Grounds (shared, content): the Festival of Battles, one row per ground, in the order they open (docs/roster.md, "The
-- Festival of Battles"). A seventh ground is a new row. Its numbers (the region factor) are in Config.Shards.

export type Row = {
	Id: string,
	Name: string,
	Order: number, -- 1 for the first ground; a Voidkin's Zone is this number
	LevelFrom: number,
	LevelTo: number,
	Keeper: string?, -- its keeper's Enemies id (docs/roster.md): its title on the keeper's HUD names this ground (UI.BossBar)
}

local rows: { Row } = {
	{ Id = "lanternrow", Name = "Lantern Row", Order = 1, LevelFrom = 1, LevelTo = 9, Keeper = "lamplighter" },
	{ Id = "drumcourt", Name = "Drum Court", Order = 2, LevelFrom = 10, LevelTo = 19 },
	{ Id = "maskparade", Name = "Mask Parade", Order = 3, LevelFrom = 20, LevelTo = 29 },
	{ Id = "kiteheights", Name = "Kite Heights", Order = 4, LevelFrom = 30, LevelTo = 39 },
	{ Id = "emberstalls", Name = "Ember Stalls", Order = 5, LevelFrom = 40, LevelTo = 49 },
	{ Id = "mirrorpavilion", Name = "Mirror Pavilion", Order = 6, LevelFrom = 50, LevelTo = 60 },
}

local byId: { [string]: Row } = {}
for _, row in rows do
	byId[row.Id] = row
end

return {
	List = rows,
	ById = byId,
	First = "lanternrow", -- open from a player's first join
}
