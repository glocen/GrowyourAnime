--!strict
-- Stages (shared Config): a ground's street in stages, each played on Normal or Hard (TR43; the director, 2026-11-18, D2;
-- docs/design.md, "The Festival of Battles"). A stage's stops are its street's (Config.World.Row.Stops, each with its
-- Stage), in the street's order from the Festival Door; here are the Shades it asks of a player before it clears, and
-- Hard's lift. Stages 1 to 3 are Lantern Row's stretches, each with its elite and then the player's own gate to the next;
-- stage 4 is the Lamplighter. Research's shape and seeds (TR43, 22:44: a quota of 10, about 3 minutes a stage, Hard +10 so
-- Lantern Row on Hard sits in Drum Court's band); tuned by playing.

local World = require(script.Parent.World)

-- With: a pack's others (AR52), Count of its Count Shades of that Def, spread through its ring (Rules.Fight.PackDefs).
export type Stop = { Kind: string, Def: string, Level: number, Count: number?, Stage: number, Square: boolean?, With: { Def: string, Count: number }? }
export type Stage = {
	Stops: { Stop }, -- Kind: Pack (Count Shades), Elite or Keeper; the last is the one whose fall it needs
	Quota: number, -- its packs' Shades that must fall to the player; 0 for a keeper's stage
}

-- A street's stops grouped by their Stage, each with its quota.
local function street(stops: { Stop }, quotas: { number }): { Stage }
	local stages: { Stage } = {}
	for _, stop in stops do
		local stage = stages[stop.Stage]
		if stage == nil then
			stage = { Stops = {}, Quota = quotas[stop.Stage] or 0 }
			stages[stop.Stage] = stage
		end
		table.insert(stage.Stops, stop)
	end
	return stages
end

return {
	-- Levels added to every foe of a stage on Hard: Lantern Row's 1 to 9 read 11 to 19.
	Offset = { Normal = 0, Hard = 10 } :: { [string]: number },
	-- A stage's results card: seconds from the fall that ends it to the card, so the fall plays and its drops are in.
	-- Clear: seconds the run's card waits past the keeper's fade back, so it never rises under the black (Stages.After).
	Results = { After = 1.2, Clear = 0.1 },
	-- A shut stage gate (StageService): a move under Walk studs in one look (a tenth of a second) is a walk across it, set
	-- back; a longer one is a set-down past it (the Door's, the keeper's exit, a test's) and stands.
	Gate = { Walk = 12, Every = 0.1 },
	-- A run ends when the player stands Off studs back past their ground's first stage's start, off the street.
	Off = 30,
	Grounds = {
		[World.Row.Ground] = street(World.Row.Stops, { 10, 10, 10, 0 }),
	} :: { [string]: { Stage } },
}
