--!strict
-- Animations (shared Config): how the game plays its clips.
-- Fades are seconds, by the game's name for a clip; Author.SaveBaked checks a clip's own fades against them.
-- Ids are published clips, by clip name. A clip with no id plays in Studio from its saved KeyframeSequence
-- (ServerStorage.RBX_ANIMSAVES.R6.NL_<Clip>, which the server hands each client to register), and not at all live:
-- every clip is published before a public build (handbook/art/animation.md, "Importing and publishing").
-- Rigs: each rig's shared reactions, one clip set per rig, not per Voidkin (docs/design.md, "States in a fight"). TR2's
-- R6 stand-in uses Rook's.

return {
	Fades = {
		Idle = { In = 0.2, Out = 0.2 },
		Combo = { In = 0.06, Out = 0.12 },
		Haymaker = { In = 0.06, Out = 0.15 },
		Hit = { In = 0.03, Out = 0.1 },
		Down = { In = 0.05, Out = 0.05 },
		Up = { In = 0.05, Out = 0.2 },
	},
	Ids = {} :: { [string]: number },
	Rigs = {
		R6 = { Idle = "RookIdle", Hit = "RookHit", Down = "RookDown", Up = "RookUp" },
	} :: { [string]: { [string]: string } },
	-- The game's name for each clip, for its fades.
	Roles = {
		RookIdle = "Idle",
		RookCombo = "Combo",
		RookHaymaker = "Haymaker",
		RookHit = "Hit",
		RookDown = "Down",
		RookUp = "Up",
	} :: { [string]: string },
}
