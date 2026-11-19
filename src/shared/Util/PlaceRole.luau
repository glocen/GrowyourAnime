--!strict
-- PlaceRole (shared): which kind of place this server or client runs in. Each place sets the Workspace attribute
-- "PlaceRole" to one of Config.Game.PlaceRoles. Boot loads Core and Main in every place, then Services/<role> and
-- Controllers/<role> if they exist; a system whose world stands in one place asks Is and idles in the other (TR45).
-- Read once: a place never changes role. An unknown role falls back to the default, with a warning.
--   PlaceRole.Current        the role's name
--   PlaceRole.Is(role)       whether this place plays that role

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

local current = read()

return {
	Current = current,
	Is = function(role: string): boolean
		return current == role
	end,
}
