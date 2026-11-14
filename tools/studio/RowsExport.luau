--!strict
-- RowsExport (Studio tool, and offline): an effect in Config.Effects.Rows as its rows file would hold it
-- (Config.EffectRows, Encode; docs/engineering-plan.md, "The rows contract"), so an effect first written in Luau can move to
-- a file, or the asset maker can take one back as the base of its rows script. Offline:
--   py tools/fx/rows_export.py KeeperSignature build/scratch/<teammate>/KeeperSignature.json

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectsConfig = require(ReplicatedStorage.Shared.Config.Effects)
local EffectRows = require(ReplicatedStorage.Shared.Config.EffectRows)

return function(name: string): any
	local effect = (EffectsConfig.Rows :: any)[name]
	assert(effect, `no effect "{tostring(name)}" in Config.Effects.Rows`)
	return EffectRows.Encode(effect, name)
end
