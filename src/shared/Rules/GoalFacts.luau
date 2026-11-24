--!strict
-- GoalFacts (pure): the account facts goals read from a save (TR54): what a goal's Opens waits for before it's ever drawn,
-- and what each of Next's steps asks (Definitions.Goals). Apart from Rules.Goals, which the rules that note the game's
-- events require, so neither requires the other's neighbours. No Roblox API: its cases run with Studio closed.
--   GoalFacts.Of(data) -> { [string]: any }   Hard, Tower, Condenser, Forge (a goal's Opens); Keeper, KeeperHard,
--                                             BaseLevel, TowerBest (Next's facts)

local Shared = game:GetService("ReplicatedStorage").Shared
local Stages = require(Shared.Rules.Stages)
local Progress = require(Shared.Rules.Progress)
local Condenser = require(Shared.Rules.Condenser)

local GoalFacts = {}

local GROUND = "lanternrow" -- launch's one ground: its Hard, its keeper

function GoalFacts.Of(data: any): { [string]: any }
	local record = data.Progress.Grounds[GROUND]
	local rows = Stages.Of(GROUND)
	local best = data.Progress.Tower.Best
	return {
		-- Hard opens when every Normal stretch is cleared (Stages.Needs)
		Hard = rows ~= nil and Stages.Line(data, GROUND, "Normal").Cleared >= #rows,
		-- the Tower is drawn once a floor of it is won, so a goal never sends a player somewhere they haven't met
		Tower = best >= 1,
		Condenser = Condenser.Awake(data.Base.Level),
		-- the forge is drawn once there's gear to forge
		Forge = next(data.Items) ~= nil,
		Keeper = Progress.Wins(record, "Normal") >= 1,
		KeeperHard = Progress.Wins(record, "Hard") >= 1,
		BaseLevel = data.Base.Level,
		TowerBest = best,
	}
end

return GoalFacts
