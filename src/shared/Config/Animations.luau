--!strict
-- Animations (shared Config): how the game plays its clips.
-- Fades are seconds, by the game's name for a clip; Author.SaveBaked checks a clip's own fades against them.
-- Ids are published clips, by clip name. A clip with no id plays in Studio from its saved KeyframeSequence
-- (ServerStorage.RBX_ANIMSAVES.R6.NL_<Clip>, which the server hands each client to register), and not at all live:
-- every clip is published before a public build (handbook/art/animation.md, "Importing and publishing").
-- Rigs: each rig's shared reactions, one clip set per rig, not per Voidkin (docs/design.md, "States in a fight"). R6
-- with open legs uses Rook's, as does TR2's stand-in; R6 in a robe uses Pip's (AR4: Pip and Lyric), named by a Voidkin row's Rig. The
-- Shade's (AR2) is every Shade's: its Down bursts on the clip's `Burst` marker. Idles: a Voidkin's own stance, by its
-- def, over its rig's.

return {
	Fades = {
		Idle = { In = 0.2, Out = 0.2 },
		Combo = { In = 0.06, Out = 0.12 },
		Haymaker = { In = 0.06, Out = 0.15 },
		Hit = { In = 0.03, Out = 0.1 },
		Down = { In = 0.05, Out = 0.05 },
		Up = { In = 0.05, Out = 0.2 },
		Walk = { In = 0.15, Out = 0.15 },
		Swipe = { In = 0.06, Out = 0.15 },
		Burst = { In = 0.03, Out = 0.05 },
		Signature = { In = 0.06, Out = 0.15 },
	},
	Ids = {} :: { [string]: number },
	Rigs = {
		R6 = { Idle = "RookIdle", Hit = "RookHit", Down = "RookDown", Up = "RookUp" },
		Robe = { Idle = "PipIdle", Hit = "PipHit", Down = "PipDown", Up = "PipUp" },
		Shade = { Idle = "ShadeIdle", Walk = "ShadeWalk", Hit = "ShadeHit", Down = "ShadeBurst" },
	} :: { [string]: { [string]: string } },
	Idles = {
		pip = "PipIdle",
		lyric = "LyricIdle",
	} :: { [string]: string },
	-- A clip's mirror, picked at random each time it plays, so a pack doesn't swing or reel in step (AR2).
	Mirrors = {
		ShadeAttack = "ShadeAttackLeft",
		ShadeHit = "ShadeHitLeft",
	} :: { [string]: string },
	-- A clip a kind of fighter never trades for its mirror. AR2, section 10: in AttackLeft the elite's second mask cuts
	-- into its first, so the elite plays Attack every time; the ordinary Shade keeps alternating.
	Unmirrored = {
		Elite = { ShadeAttack = true },
	} :: { [string]: { [string]: boolean } },
	-- A walk's ground speed at rate 1, in studs a second (its stride over its loop: Shade.clips.json). The clip plays at the
	-- body's own speed over this, so its feet keep to the ground, up to MaxRate (AR2: "walk speed comes from the stride").
	Strides = {
		ShadeWalk = 4.11,
	} :: { [string]: number },
	Walk = { MinSpeed = 0.6, MaxRate = 3 }, -- studs a second below which it stands; the fastest it plays
	-- A prop a Voidkin lets go of when it goes down, by its def (research's prop state for Lyric's stand, AR4, section 6):
	-- its motor's piece leaves the hand Drop seconds into the Down clip (before its frame 12, at the blow), falls over Fall
	-- seconds to lie flat Aside studs to the body's right and Along ahead (Lyric falls back, so hers lies by her body, clear
	-- of her arm), and goes back to the hand over Back once Up begins.
	Props = {
		lyric = { Motor = "Staff", Drop = 0.1, Fall = 0.25, Aside = 2.9, Along = -1.5, Back = 0.3 },
	} :: { [string]: { Motor: string, Drop: number, Fall: number, Aside: number, Along: number, Back: number } },
	-- The game's name for each clip, for its fades.
	Roles = {
		RookIdle = "Idle",
		RookCombo = "Combo",
		RookHaymaker = "Haymaker",
		RookHit = "Hit",
		RookDown = "Down",
		RookUp = "Up",
		PipIdle = "Idle",
		PipCombo = "Combo",
		PipLanternBurst = "Signature",
		PipHit = "Hit",
		PipDown = "Down",
		PipUp = "Up",
		LyricIdle = "Idle",
		LyricCombo = "Combo",
		LyricHeldNote = "Signature",
		ShadeIdle = "Idle",
		ShadeWalk = "Walk",
		ShadeAttack = "Swipe",
		ShadeAttackLeft = "Swipe",
		ShadeHit = "Hit",
		ShadeHitLeft = "Hit",
		ShadeBurst = "Burst",
	} :: { [string]: string },
}
