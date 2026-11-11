--!strict
-- Preset: a game's numbers as a named set (Config.Presets), switched while a server runs. The server picks one through a
-- Workspace attribute; it and every client take the same numbers from that, so prediction steps with the server's. Each switch
-- first puts back what the last one changed. The change reaches what Tune reaches, and lasts as long as the server.
-- Config.Presets needs: List = { [name] = { Set = { [tunePath] = value } } }, Order = { names }, Default = name.

local Config = require(script.Parent.Parent.Config.Presets)
local Tune = require(script.Parent.Tune)

local ATTRIBUTE = "NL_Preset"

local Preset = {}

local changed: { [string]: any } = {}

local function apply(name: string)
	for path, value in changed do
		Tune.Apply(path, value)
	end
	table.clear(changed)
	local preset = Config.List[name]
	for path, value in if preset then preset.Set else {} do
		changed[path] = Tune.Apply(path, value)
	end
end

function Preset.Current(): string
	local picked = workspace:GetAttribute(ATTRIBUTE)
	return if type(picked) == "string" then picked else Config.Default
end

-- Server only: every side changes when the attribute reaches it.
function Preset.Pick(name: string)
	assert(Config.List[name], `no preset "{name}"`)
	workspace:SetAttribute(ATTRIBUTE, name)
end

-- The preset after `name`, wrapping round.
function Preset.After(name: string): string
	local index = table.find(Config.Order, name) or 0
	return Config.Order[index % #Config.Order + 1]
end

-- Applies the current preset and follows every switch from here on.
function Preset.Follow()
	apply(Preset.Current())
	workspace:GetAttributeChangedSignal(ATTRIBUTE):Connect(function()
		apply(Preset.Current())
	end)
end

return Preset
