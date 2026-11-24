--!strict
-- Reinforce (shared, pure): a gear's level, +1 a success, paid in forge stones and Credits (TR47; docs/design.md,
-- "Reinforce"; Config.Reinforce). The level belongs to the item, never the slot: equipping a new item offers to move it
-- across (Rules.Regalia.Transfer).
--   Reinforce.Chance(level)          the chance a try for `level` succeeds; its failure is 1 minus it, so the two shown
--                                    before every press add to 100% (docs/roblox-rules.md, "What we do", point 2)
--   Reinforce.Cost(item, level)      a try's price: Credits, and stones of one grade
--   Reinforce.Gain(item, level?)     what `level` (the item's own by default) adds: its main line's stat and the points
--   Reinforce.Try(data, args, roll)  one try, one step: it spends, then succeeds when `roll` (the server's Random, in
--                                    [0, 1)) falls under the chance. A failure spends and keeps the level, with no pity.
-- The server runs Try in one transaction with its op id (Services.Main.RegaliaService), so a retry never spends twice.
-- No Roblox API: it runs with Studio closed.

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config.Reinforce)
local Grounds = require(Shared.Definitions.Grounds)
local Growth = require(Shared.Rules.Growth)
local Profile = require(Shared.Data.Profile)
local Goals = require(Shared.Rules.Goals)

local Reinforce = {}

-- The refusals, which the screen says.
Reinforce.Unknown = "Unknown" -- no such item, or the request isn't one
Reinforce.Capped = "Capped" -- the item stands at the cap
Reinforce.Poor = "Poor" -- not enough Credits
Reinforce.NoStones = "NoStones" -- not enough stones of the grade

export type Cost = { Credits: number, Grade: string, Stones: number }

function Reinforce.Chance(level: number): number
	if level < 1 or level > Config.Cap or level ~= math.floor(level) then
		return 0
	end
	return Config.Chance[level] or Config.Floor
end

function Reinforce.Cost(item: { Tier: number }, level: number): Cost
	local ground = Grounds.List[math.clamp(item.Tier, 1, #Grounds.List)]
	local credits = Config.Credits.Base * Growth.G(if ground then ground.LevelTo else 1) * (1 + level / Config.Credits.Per)
	local ten = math.clamp(math.ceil(level / 10), 1, #Config.Grades)
	return {
		Credits = math.floor(credits + 0.5),
		Grade = Config.Grades[ten],
		Stones = Config.Stones[(level - 1) % #Config.Stones + 1],
	}
end

function Reinforce.Gain(item: Profile.OwnedItem, level: number?): (string?, number)
	local main = item.Lines[1]
	local at = if level then level else item.Reinforce
	if main == nil or not (at > 0) then
		return nil, 0
	end
	return main.Stat, main.Value * at * Config.Gain
end

function Reinforce.Try(data: Profile.Data, args: any, roll: number): { [string]: any }
	local id = if type(args) == "table" then args.Item else nil
	local item = if type(id) == "string" then data.Items[id] else nil
	if item == nil then
		return { Ok = false, Error = Reinforce.Unknown }
	end
	local level = item.Reinforce + 1
	if level > Config.Cap then
		return { Ok = false, Error = Reinforce.Capped }
	end
	local cost = Reinforce.Cost(item, level)
	local have = data.Bag.Stones[cost.Grade] or 0
	if data.Currency.Credits < cost.Credits then
		return { Ok = false, Error = Reinforce.Poor }
	end
	if have < cost.Stones then
		return { Ok = false, Error = Reinforce.NoStones }
	end
	data.Currency.Credits -= cost.Credits
	data.Bag.Stones[cost.Grade] = if have - cost.Stones > 0 then have - cost.Stones else nil
	local chance = Reinforce.Chance(level)
	local success = roll < chance
	if success then
		item.Reinforce = level
	end
	Goals.Note(data, "Forge") -- today's "forge once": a try made, kept or not (TR54)
	return {
		Ok = true, -- a failure is a try made: it spends, so it commits
		Item = id,
		Success = success,
		Level = item.Reinforce,
		Tried = level,
		Chance = chance,
		Credits = cost.Credits,
		Grade = cost.Grade,
		Stones = cost.Stones,
	}
end

return Reinforce
