--!strict
-- Board (shared, pure): the stat board, a Voidkin's skill points (docs/design.md, "Skill points"; TR15). One point a level
-- from Config.Stats.Board.From, each Voidkin's own, spent by hand on one of the board's stats: Health, Attack, Defence and
-- Regen. A point adds its stat's Point times G at the Voidkin's level, whatever its class or rarity, so an early point
-- keeps its worth. No free power: the board takes each stat's even part, a quarter of the points earned, out of the own
-- base (Rules.Stats), so an even spread is the Voidkin without the board and a chosen spread leans it. A point left
-- unspent adds nothing. A reset gives every point back for a little Credits. Each function changes a draft inside one
-- Transaction and returns its answer, so a spend or a reset asked twice with one op id happens once.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local StatsConfig = require(Shared.Config.Stats)
local GrowthConfig = require(Shared.Config.Growth)
local Profile = require(Shared.Data.Profile)
local Growth = require(Shared.Rules.Growth)

local Board = {}

-- Refusal codes.
Board.Unknown = "Unknown" -- no such owned Voidkin
Board.Stat = "Stat" -- not a stat the board takes
Board.NoPoints = "NoPoints" -- every point earned is spent
Board.Nothing = "Nothing" -- a reset with no point spent
Board.Short = "Short" -- not enough Credits for the reset

-- Whether `stat` is on the board (read when called, so a tune reaches the next one).
function Board.Takes(stat: any): boolean
	return type(stat) == "string" and table.find(StatsConfig.Board.Stats, stat) ~= nil
end

local function levelOf(owned: Profile.OwnedVoidkin): number
	return math.clamp(math.floor(owned.Level), 1, GrowthConfig.MaxLevel)
end

-- The points a Voidkin at `level` has earned: one a level from From.
function Board.Earned(level: number): number
	return math.max(0, math.floor(level) - StatsConfig.Board.From + 1)
end

-- The points spent on `stat`, and on the whole board.
function Board.On(owned: Profile.OwnedVoidkin, stat: string): number
	return owned.Points[stat] or 0
end

function Board.Spent(owned: Profile.OwnedVoidkin): number
	local spent = 0
	for _, stat in StatsConfig.Board.Stats do
		spent += Board.On(owned, stat)
	end
	return spent
end

-- The points still to spend.
function Board.Left(owned: Profile.OwnedVoidkin): number
	return math.max(0, Board.Earned(levelOf(owned)) - Board.Spent(owned))
end

-- What one point on `stat` adds at `level`: the gain the board shows before a tap.
function Board.Gain(stat: string, level: number): number
	return (StatsConfig.Board.Point[stat] or 0) * Growth.G(math.clamp(level, 1, GrowthConfig.MaxLevel))
end

-- What the board takes out of `stat`'s own base at `level`: the even part of the points earned, a quarter each.
function Board.Taken(stat: string, level: number): number
	if not Board.Takes(stat) then
		return 0
	end
	return Board.Earned(level) / #StatsConfig.Board.Stats * Board.Gain(stat, level)
end

-- What the points spent on `stat` add.
function Board.Added(owned: Profile.OwnedVoidkin, stat: string): number
	return Board.On(owned, stat) * Board.Gain(stat, levelOf(owned))
end

-- The Credits a reset costs: whole, sized by G at the Voidkin's level.
function Board.ResetCost(owned: Profile.OwnedVoidkin): number
	return math.ceil(StatsConfig.Board.ResetPerG * Growth.G(levelOf(owned)) - 1e-9)
end

local function ownedOf(data: Profile.Data, id: any): Profile.OwnedVoidkin?
	return if type(id) == "string" then data.Voidkin[id] else nil
end

-- One point on `stat`: { Ok, Id, Stat, On (the points on it now), Left }.
function Board.Spend(data: Profile.Data, id: any, stat: any): { [string]: any }
	local owned = ownedOf(data, id)
	if owned == nil then
		return { Ok = false, Error = Board.Unknown }
	end
	if not Board.Takes(stat) then
		return { Ok = false, Error = Board.Stat }
	end
	if Board.Left(owned) < 1 then
		return { Ok = false, Error = Board.NoPoints }
	end
	owned.Points[stat] = Board.On(owned, stat) + 1
	return { Ok = true, Id = owned.Id, Stat = stat, On = owned.Points[stat], Left = Board.Left(owned) }
end

-- Every point back, for Credits: { Ok, Id, Credits (what it cost), Left }.
function Board.Reset(data: Profile.Data, id: any): { [string]: any }
	local owned = ownedOf(data, id)
	if owned == nil then
		return { Ok = false, Error = Board.Unknown }
	end
	if next(owned.Points) == nil then
		return { Ok = false, Error = Board.Nothing }
	end
	local cost = Board.ResetCost(owned)
	if data.Currency.Credits < cost then
		return { Ok = false, Error = Board.Short, Credits = cost }
	end
	data.Currency.Credits -= cost
	table.clear(owned.Points)
	return { Ok = true, Id = owned.Id, Credits = cost, Left = Board.Left(owned) }
end

return Board
