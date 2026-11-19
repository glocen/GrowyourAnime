--!strict
-- The only client entry script. Everything else is a ModuleScript under Controllers, booted by the Loader.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util = Shared:WaitForChild("Util")
local Loader = require(Util:WaitForChild("Loader"))
local Net = require(Shared:WaitForChild("Net"))
local PlaceRole = require(Util:WaitForChild("PlaceRole"))
local Preset = require(Util:WaitForChild("Preset"))

Preset.Follow() -- before the Loader, or a preset silently does nothing

local role = PlaceRole.Current
local controllers = script.Parent:WaitForChild("Controllers")
local folders: { Instance? } = { controllers:FindFirstChild("Core"), controllers:FindFirstChild("Main") } -- the game's, in every place
if role ~= "Main" then
	folders[3] = controllers:FindFirstChild(role)
end
local _, bootErrors = Loader.Boot(`Client/{role}`, folders)

Net.Client.Fire("ClientReady", bootErrors) -- the server keeps it on the player, for the self-test
if bootErrors > 0 then
	warn(`Client boot finished with {bootErrors} errors`)
end
