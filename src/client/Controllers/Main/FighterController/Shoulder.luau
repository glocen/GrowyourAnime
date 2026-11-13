--!strict
-- The fight's shoulder camera (TR7, the framing; Config.Combat.Shoulder): while the player's lead has a target, the
-- camera eases right and up of the avatar through Humanoid.CameraOffset, in the avatar's own space, so the avatar sits
-- left of the frame and the fight right of centre. It holds a moment after the fight, then eases back. The camera's own
-- script applies the offset, so the player's drag still turns it freely. FighterController steps it before the camera.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage.Shared.Config.Combat)
local Fight = require(ReplicatedStorage.Shared.Rules.Fight)

local player = Players.LocalPlayer

local Shoulder = {}

local share = 0 -- of the offset, 0 to 1
local lastFight = -math.huge -- os.clock() when the lead last had a target

-- For tests: the share of the offset now.
function Shoulder.Share(): number
	return share
end

-- Each frame before the camera: `engaged` is whether the player's lead has a target now.
function Shoulder.Step(dt: number, engaged: boolean, now: number)
	if engaged then
		lastFight = now
	end
	local shoulder = Combat.Shoulder
	share = Fight.ShoulderShare(share, now - lastFight, dt, shoulder)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid.CameraOffset = Vector3.new(shoulder.Right, shoulder.Up, 0) * share
	end
end

return Shoulder
