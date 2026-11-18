--!strict
-- TuneController (client): takes a Config change from TuneService, so this client's prediction steps with the server's numbers.
-- Studio only. A snippet can't see this client's modules, so the NL_ClientTune bindable reads a path as the client has it,
-- and NL_ClientTheme sets the screens' colours on this client, for a look tried live (AR40's directions):
--   NL_ClientTheme:Invoke("Set", { Colour = { Text = "#1B1E3A" }, Palette = "Graphite", Values = { Panel = { "#F7F2E8", "#E7E0D2" }, Border = 1.6 } })
--   NL_ClientTheme:Invoke("Reset")   every colour and value back as it loaded
-- A screen takes them when it's next built.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Tune = require(Shared.Util.Tune)
local UIKit = require(Shared.Config.UIKit)
local Theme = require(script.Parent.Parent.Parent.UI.Theme)

local TuneController = {}

-- A colour from its hex, a pair from two, a number as it is.
local function valueOf(v: any): any
	if type(v) == "string" then
		return Color3.fromHex(v)
	elseif type(v) == "table" then
		local pair = {}
		for i, each in v do
			pair[i] = valueOf(each)
		end
		return pair
	end
	return v
end

local function themeBridge()
	local colours = Theme.Colour :: { [string]: any }
	local palettes = UIKit.Palettes :: { [string]: { [string]: any } }
	local NONE = {} -- a key the table didn't have
	local was: { [any]: { [string]: any } } = {} -- each table's first values, by key
	local function set(into: { [string]: any }, key: string, value: any)
		local first = was[into] or {}
		was[into] = first
		if first[key] == nil then
			first[key] = if into[key] == nil then NONE else into[key]
		end
		into[key] = value
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "NL_ClientTheme"
	bridge.OnInvoke = function(command: string, look: any): any
		if command == "Set" and type(look) == "table" then
			for key, v in look.Colour or {} do
				set(colours, key, valueOf(v))
			end
			local palette = palettes[look.Palette or "Graphite"]
			for key, v in (if palette then look.Values else nil) or {} do
				set(palette, key, valueOf(v))
			end
			return true
		elseif command == "Reset" then
			for into, first in was do
				for key, v in first do
					into[key] = if v == NONE then nil else v
				end
			end
			table.clear(was)
			return true
		end
		return false
	end
	bridge.Parent = Players.LocalPlayer:WaitForChild("PlayerScripts")
end

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
	themeBridge()
end

return TuneController
