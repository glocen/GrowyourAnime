--!strict
-- Cooldown (shared, pure): when Lantern Row's elite and its keeper are back after they fall (docs/test-requests.md, TR10;
-- the director, 2026-11-14). The elite's timer is the server's, one for everyone, since its fight is shared (PackService
-- keeps it, the Elite marker's BackAt shows it). The keeper's is each player's own, in their save, from their win
-- (Rules.Progress: KeeperWon starts it, Resting reads it), so a rejoin or a server hop never resets it. Packs keep
-- Config.World.Row.Respawn. No Roblox API: it runs with Studio closed.
--   Cooldown.Wait(kind)               seconds after a group's last fall, or a keeper's win, until it's back: "Elite",
--                                     "Keeper", or anything else for a pack (Config.World.Row.Back, Respawn)
--   Cooldown.Left(backAt, now, kind)  seconds left of a timer that ends at backAt (nil: none), from 0 up to its kind's
--                                     wait: a clock behind the one that set it (another server's) never lengthens it

local WorldConfig = require(script.Parent.Parent.Config.World)

local Cooldown = {}

function Cooldown.Wait(kind: string): number
	local back = (WorldConfig.Row.Back :: any)[kind]
	return if type(back) == "number" then back else WorldConfig.Row.Respawn
end

function Cooldown.Left(backAt: number?, now: number, kind: string): number
	if type(backAt) ~= "number" or backAt ~= backAt or now ~= now then
		return 0
	end
	return math.clamp(backAt - now, 0, Cooldown.Wait(kind))
end

return Cooldown
