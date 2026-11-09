--!strict
-- The only server entry script. Everything else is a ModuleScript under Services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared.Util.Loader)
local PlaceRole = require(Shared.Util.PlaceRole)

-- When you add a Net module, create its remotes here, before anything boots: Net.Server.Setup()
-- When you add Preset, call Preset.Follow() here too, before the Loader, or a preset silently does nothing.

local role = PlaceRole.Current
local services = script.Parent:WaitForChild("Services")
Loader.Boot(`Server/{role}`, { services:FindFirstChild("Core"), services:FindFirstChild(role) })
