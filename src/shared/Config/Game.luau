--!strict
-- Game-wide settings (shared).

return {
	Version = "0.1.0",
	-- A place sets the Workspace attribute "PlaceRole" to one of these, which chooses the role's services and controllers
	-- (Services/<role>, Controllers/<role>) beside Core. Read it through Util.PlaceRole. The game is one place today.
	PlaceRoles = {
		Main = "Main",
	} :: { [string]: string },
	DefaultPlaceRole = "Main", -- the fallback when a place doesn't set the attribute
}
