--!strict
-- Board (shared, pure): the stat board, a Voidkin's skill points (docs/design.md, "Skill points"; TR15). One point a level
-- from Config.Stats.Board.From, each Voidkin's own, spent by hand on one of the board's stats: Health, Attack, Defence and
-- Regen. The board adds on top of the own base (research's call (c), 2026-11-14, night): spent evenly at full it adds a
-- fixed Share of each stat's own figure, rarity and class in it, at every level, and a stat's points, as a part of those
-- earned, place that part of the board's stat count times its Share. A point waiting adds nothing, so a Voidkin whose
-- points wait is today's Voidkin and a spent point is a gain. A point's gain is worth more early and less as points pile
-- up; the board shows it live before a tap. A reset gives every point back, unspent, for a little Credits. Each spend or
-- reset changes a draft inside one Transaction and returns its answer, so one asked twice with one op id happens once.
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

-- The points a Voidkin's shares are spread over: those earned, or those spent if more (a test's or a tune's), so the whole
-- board never adds more than its share.
function Board.Over(owned: Profile.OwnedVoidkin): number
	return math.max(Board.Earned(levelOf(owned)), Board.Spent(owned))
end

-- What `on` points of `over` add to `stat` whose own figure is `own` (Rules.Stats: rarity and class in it, times G):
-- each point places its part of the board's stat count times the stat's Share, so spent evenly at full each stat gains its
-- Share of its own, every point on one stat gains it that many times its Share, and a point waiting adds nothing.
function Board.Added(stat: string, own: number, on: number, over: number): number
	if not Board.Takes(stat) or on <= 0 or over <= 0 or not (own > 0) then
		return 0
	end
	return (StatsConfig.Board.Share[stat] or 0) * #StatsConfig.Board.Stats * own * math.min(on, over) / over
end

-- What one more point on `stat` adds, its own figure `own`, over `over` points: the gain the board shows before a tap.
-- A tap needs a point left, so `over` is the points earned and stays so after it: the shown gain is what the tap adds.
function Board.Gain(stat: string, own: number, over: number): number
	return Board.Added(stat, own, 1, over)
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
