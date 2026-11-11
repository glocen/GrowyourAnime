--!strict
-- DebugService (server): a Studio-only bridge that lets tools (the Studio MCP, the command bar) run checks inside
-- the game's own script context. Plugin and command-bar code get separate module instances, so they
-- can't see live game state any other way.
-- While playtesting, from the server side:  game.ServerStorage.NL_Debug:Invoke("Commands")
-- The bridge never exists on live servers.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)

local DebugService = {}

local commands: { [string]: (...any) -> ...any } = {}

-- Any service may register commands at any time (Init included); this only writes to a table.
function DebugService.Register(name: string, command: (...any) -> ...any)
	assert(commands[name] == nil, `debug command "{name}" registered twice`)
	commands[name] = command
end

-- Runs a command: (true, results...) or (false, error).
function DebugService.Run(name: any, ...: any): (boolean, ...any)
	local command = commands[name]
	if not command then
		return false, `unknown debug command "{tostring(name)}"`
	end
	return pcall(command, ...)
end

-- The player a command means: a Player, a player's name, or nil for the first player (solo playtests).
function DebugService.ResolvePlayer(who: any): Player?
	if typeof(who) == "Instance" and (who :: Instance):IsA("Player") then
		return who :: Player
	elseif who == nil then
		return Players:GetPlayers()[1]
	end
	return Players:FindFirstChild(tostring(who)) :: Player?
end

function DebugService.Init()
	-- Kept on the player, so it needs no cleanup. It's the client's own word: for reading a test, never for a rule.
	Net.Server.On("ClientReady", function(player: Player, bootErrors: any)
		if type(bootErrors) ~= "number" then
			return
		end
		player:SetAttribute("ClientBootErrors", bootErrors)
		if bootErrors > 0 then
			Log.Warn("Boot", `{player.Name}'s client booted with {bootErrors} errors`)
		end
	end)

	DebugService.Register("Ping", function()
		return "pong"
	end)
	DebugService.Register("Commands", function()
		local names = {}
		for name in commands do
			table.insert(names, name)
		end
		table.sort(names)
		return names
	end)
	DebugService.Register("NetDropped", function()
		return Net.Server.DroppedCounts()
	end)
	-- The server boot's error count in require and Init, which Boot keeps on its own script.
	DebugService.Register("BootErrors", function()
		local boot = ServerScriptService:FindFirstChild("Server") and ServerScriptService.Server:FindFirstChild("Boot")
		return if boot then boot:GetAttribute("BootErrors") else nil
	end)

	if not RunService:IsStudio() then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "NL_Debug"
	bridge.OnInvoke = DebugService.Run
	bridge.Parent = ServerStorage
	-- Clients (the self-test) reach the same commands; the calling player goes first.
	Net.Server.Handle("DebugCommand", function(player: Player, name: any, ...: any)
		return DebugService.Run(name, player, ...)
	end)
	Log.Info("DebugService", "Studio debug bridge ready (ServerStorage.NL_Debug)")
end

return DebugService
