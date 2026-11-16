--!strict
-- TuneService (server): Config values at runtime, and the preset being played, Studio only. From the server side of a playtest:
--   game.ServerStorage.NL_Debug:Invoke("Tune", "Movement.Dodge.Duration", 0.5)   sets it on the server and every client
--   game.ServerStorage.NL_Debug:Invoke("Tune", "Movement.Dodge.Duration")        reads it
--   game.ServerStorage.NL_Debug:Invoke("TuneList")                               what's changed, to copy into Config by hand
-- Shared.Util.Tune says what a change reaches. Nothing is saved: the playtest's end drops every change.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Tune = require(Shared.Util.Tune)
local Preset = require(Shared.Util.Preset)
local Signal = require(Shared.Util.Signal)
local DebugService = require(script.Parent.DebugService)

local TuneService = {}
TuneService.Changed = Signal.new() -- (path, value) after a tune is applied on the server, for code that lays things from Config

type Change = { From: any, To: any }
local changes: { [string]: Change } = {}

-- A command run from a client has its player first; one run on the server may leave it out.
local function pathAndValue(first: any, second: any, third: any): (string, any)
	if type(first) == "string" then
		return first, second
	end
	return second, third
end

local function tune(first: any, second: any, third: any): any
	local path, value = pathAndValue(first, second, third)
	assert(type(path) == "string", "Tune needs a Config path")
	if value == nil then
		return Tune.Read(path)
	end
	local old = Tune.Apply(path, value)
	local change = changes[path]
	changes[path] = { From = if change then change.From else old, To = value }
	Net.Server.FireAll("Tune", path, value)
	TuneService.Changed:Fire(path, value)
	return value
end

-- A tune from server code, as the Tune command makes it (Studio only): every side takes it, and Changed fires.
function TuneService.Set(path: string, value: any): any
	return tune(path, value)
end

function TuneService.Init()
	if not RunService:IsStudio() then
		return
	end
	DebugService.Register("Tune", tune)
	DebugService.Register("TuneList", function(): { [string]: Change }
		return changes
	end)
	-- ("Preset") reads the current preset; ("Preset", name) switches every side to it. The self-test benches the one being
	-- played, runs on Baseline, and puts it back.
	DebugService.Register("Preset", function(first: any, second: any): string
		local name = if type(first) == "string" then first else second
		if name ~= nil then
			Preset.Pick(name)
		end
		return Preset.Current()
	end)
end

function TuneService.Start()
	if not RunService:IsStudio() then
		return
	end
	-- A client that joins later steps with the same numbers.
	Players.PlayerAdded:Connect(function(player: Player)
		for path, change in changes do
			Net.Server.Fire("Tune", player, path, change.To)
		end
	end)
end

return TuneService
