--!strict
-- PlaceRole (shared): which kind of place this server or client runs in. Each place sets the Workspace attribute
-- "PlaceRole" to one of Config.Game.PlaceRoles, and boot loads Services/<role> and Controllers/<role> beside Core.
-- Read once: a place never changes role. An unknown role falls back to the default, with a warning.

local GameConfig = require(script.Parent.Parent.Config.Game)
local Log = require(script.Parent.Log)

local ATTRIBUTE = "PlaceRole"

local function read(): string
	local set = workspace:GetAttribute(ATTRIBUTE)
	if set == nil then
		return GameConfig.DefaultPlaceRole
	end
	for _, role in GameConfig.PlaceRoles do
		if set == role then
			return role
		end
	end
	Log.Warn("PlaceRole", `unknown role "{tostring(set)}", booting as {GameConfig.DefaultPlaceRole}`)
	return GameConfig.DefaultPlaceRole
end

return {
	Current = read(),
}
