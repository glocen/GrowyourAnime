--!strict
-- Game-wide settings.

return {
	Version = "0.1.0",
	-- Each place sets the Workspace attribute "PlaceRole" to one of these, which chooses the role-specific services
	-- and controllers that boot (Services/<role>, Controllers/<role>). Read it through Util.PlaceRole.
	PlaceRoles = {
		Hub = "Hub",
		Match = "Match",
	},
	DefaultPlaceRole = "Hub", -- the fallback when a place doesn't set the attribute
}
