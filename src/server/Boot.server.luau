--!strict
-- The only server entry script. Everything else is a ModuleScript under Services, booted by the Loader.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Loader = require(Shared.Util.Loader)
local Net = require(Shared.Net)
local PlaceRole = require(Shared.Util.PlaceRole)
local Preset = require(Shared.Util.Preset)

Net.Server.Setup() -- every remote exists before any service uses one
Preset.Follow() -- before the Loader, or a preset silently does nothing

local role = PlaceRole.Current
local services = script.Parent:WaitForChild("Services")
local folders: { Instance? } = { services:FindFirstChild("Core"), services:FindFirstChild("Main") } -- the game's systems, in every place
if role ~= "Main" then
	folders[3] = services:FindFirstChild(role)
end
local _, bootErrors = Loader.Boot(`Server/{role}`, folders)
script:SetAttribute("BootErrors", bootErrors) -- the debug bridge's BootErrors reads it
