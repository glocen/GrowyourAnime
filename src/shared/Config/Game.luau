--!strict
-- Game-wide settings (shared).

return {
	Version = "0.1.0",
	-- A place sets the Workspace attribute "PlaceRole" to one of these. Every place boots Core and the game's systems in
	-- Main, then Services/<role> and Controllers/<role> if the role has its own; a system whose world stands in one place
	-- idles in the other, read through Util.PlaceRole (TR45; docs/engineering-plan.md, "Places").
	-- Main: the base, the Strip, the Shop and the Towers. Festival: the Festival of Battles, Lantern Row's stages.
	PlaceRoles = {
		Main = "Main",
		Festival = "Festival",
	} :: { [string]: string },
	DefaultPlaceRole = "Main", -- the fallback when a place doesn't set the attribute
	-- Each role's place in universe 9093907961: where a trip goes (Rules.Travel).
	Places = {
		Main = 78052287756826,
		Festival = 110443456684004,
	} :: { [string]: number },
}
