--!strict
-- CameraTurn: turns the player's own camera to a new view that the default camera then keeps. Client only.
--
-- On a touch screen the default camera follows (TouchCameraMovementMode Default plays as Follow): each frame it undoes any
-- turn it didn't make itself and keeps only a change of pitch, so a view written straight to the camera loses its yaw on the
-- next frame (measured in Studio's phone emulation, 2026-11-13). One rendered frame in Scriptable clears what it remembers,
-- and the view written then stays once the camera is Custom again. A mouse's camera (Classic) keeps it either way.

local RunService = game:GetService("RunService")

local CameraTurn = {}

local turns = 0
local pending = false

-- Puts the camera at `view` from the next frame on; a second turn before then wins. Left alone when something else
-- scripts the camera. The camera keeps its own zoom, so `view` should sit at the distance it had from its focus.
function CameraTurn.To(view: CFrame)
	local camera = workspace.CurrentCamera
	if camera == nil or (camera.CameraType ~= Enum.CameraType.Custom and not pending) then
		return
	end
	turns += 1
	local mine = turns
	pending = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = view
	RunService.RenderStepped:Once(function()
		if turns ~= mine then
			return
		end
		pending = false
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CFrame = view
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

return CameraTurn
