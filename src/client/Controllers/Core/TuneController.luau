--!strict
-- TuneController (client): takes a Config change from TuneService, so this client's prediction steps with the server's numbers.
-- Studio only. A snippet can't see this client's modules, so the NL_ClientTune bindable reads a path as the client has it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Tune = require(Shared.Util.Tune)

local TuneController = {}

function TuneController.Start()
	if not RunService:IsStudio() then
		return
	end
	Net.Client.On("Tune", function(path: string, value: any)
		Tune.Apply(path, value)
	end)
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "NL_ClientTune"
	bridge.OnInvoke = Tune.Read
	bridge.Parent = Players.LocalPlayer:WaitForChild("PlayerScripts")
end

return TuneController
