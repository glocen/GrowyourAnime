--!strict
-- Passive (shared, pure): what a Voidkin's passive does to one hit or one cooldown, by its row's kind (Definitions.Passives).
-- Each returns what nothing changes when the row is nil or of another kind, so a fighter without a passive needs no branch.
-- No Roblox API: it runs with Studio closed.

local Passives = require(game:GetService("ReplicatedStorage").Shared.Definitions.Passives)

local Passive = {}

-- Whether a Reduction holds at `health` of `most`: standing, and under its share.
function Passive.Holds(row: Passives.Row?, health: number, most: number): boolean
	return row ~= nil and row.Kind == "Reduction" and health > 0 and most > 0 and health < most * (row.Below or 0)
end

-- The share less damage the defender takes (Rules.Hit's Reduction bucket), at its health before the hit.
function Passive.Reduction(row: Passives.Row?, health: number, most: number): number
	return if row and Passive.Holds(row, health, most) then row.Share else 0
end

-- The damage an Extra adds on `action`'s `beat`: Share of the hit's own damage (`dealt`), 0 elsewhere.
function Passive.Extra(row: Passives.Row?, action: string, beat: string, dealt: number): number
	if row == nil or row.Kind ~= "Extra" or row.Action ~= action or row.Beat ~= beat or not (dealt > 0) then
		return 0
	end
	return dealt * row.Share
end

-- The critical chance an Opener gives a hit (Rules.Hit's Critical floor): its Share on the first hit to land on a target
-- (`first`), nothing after or of another kind.
function Passive.Critical(row: Passives.Row?, first: boolean): number
	return if row and row.Kind == "Opener" and first then row.Share else 0
end

-- `action`'s cooldown under a Cooldown passive: Share shorter on its own action, unchanged on any other.
function Passive.Cooldown(row: Passives.Row?, action: string, cooldown: number): number
	if row == nil or row.Kind ~= "Cooldown" or row.Action ~= action then
		return cooldown
	end
	return cooldown * (1 - row.Share)
end

return Passive
