--!strict
-- The only client entry script. Everything else is a ModuleScript under Controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared:WaitForChild("Util"):WaitForChild("Loader"))
local PlaceRole = require(Shared:WaitForChild("Util"):WaitForChild("PlaceRole"))

-- When you add Preset, call Preset.Follow() here, before the Loader, or a preset silently does nothing.

local role = PlaceRole.Current
local controllers = script.Parent:WaitForChild("Controllers")
local _, bootErrors = Loader.Boot(`Client/{role}`, { controllers:FindFirstChild("Core"), controllers:FindFirstChild(role) })

-- When you add a Net module, tell the server the boot's error count here: Net.Client.Fire("ClientReady", bootErrors)
if bootErrors > 0 then
	warn(`Client boot finished with {bootErrors} errors`)
end
