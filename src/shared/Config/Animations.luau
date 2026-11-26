--!strict
-- Animations (shared Config): how the game plays its clips.
-- Fades are seconds, by the game's name for a clip; Author.SaveBaked checks a clip's own fades against them.
-- Ids are published clips, by clip name. A clip with no id plays in Studio from its saved KeyframeSequence
-- (ServerStorage.RBX_ANIMSAVES.R6.NL_<Clip>, which the server hands each client to register), and not at all live:
-- every clip is published before a public build (handbook/art/animation.md, "Importing and publishing").
-- Rigs: each rig's shared reactions, one clip set per rig, not per Voidkin (docs/design.md, "States in a fight"). R6
-- with open legs uses Rook's, as does TR2's stand-in; R6 in a robe uses Pip's (AR4), named by a Voidkin row's Rig; Watt,
-- Kirra and Lyric have their own (AR11, AR66), their props and tails keyed in them. The
-- Shade's (AR2) is every Shade's: its Down bursts on the clip's `Burst` marker. The Lamplighter's (AR7) is its own: the
-- Shade's clips lay its pole through its coat. A fighter's own stance, over its rig's Idle, is on its row (a Voidkin's
-- Kit, an enemy's Idle; Definitions.Actions, IdleOf).

return {
	Fades = {
		Idle = { In = 0.2, Out = 0.2 },
		Combo = { In = 0.06, Out = 0.12 },
		Hit = { In = 0.03, Out = 0.1 },
		Down = { In = 0.05, Out = 0.05 },
		Up = { In = 0.05, Out = 0.2 },
		Walk = { In = 0.15, Out = 0.15 },
		Swipe = { In = 0.06, Out = 0.15 },
		Burst = { In = 0.03, Out = 0.05 },
		Signature = { In = 0.06, Out = 0.15 },
		Challenge = { In = 0.06, Out = 0.15 }, -- the keeper's, as a try starts: it ends in Ready's pose
		Skip = { In = 0.04, Out = 0.1 }, -- a ranged lead's skip back (TR7): quick in, and the next action cuts it at Land
		Guard = { In = 0.08, Out = 0.15 }, -- AR52's raise (Shade.clips.json)
		Lunge = { In = 0.06, Out = 0.15 }, -- AR52's lunge
		Cast = { In = 0.1, Out = 0.15 }, -- AR58's cast, the Support's (Shade_Support.clips.json)
	},
	-- The attack clips' snap, a live test beside today's fades (TR69 A, from TR66 row 12): On, every role here fades in
	-- over In in place of its own (0.06 today). Off by default; NL_Debug:Invoke("Tune", "Animations.Snap.On", true).
	Snap = { On = false, In = 0.02, Roles = { Combo = true, Swipe = true, Signature = true, Lunge = true } :: { [string]: boolean } },
	-- A clip played in place of another, a live test beside today's (TR66 row 13: Rook's jab retimed, the same poses and
	-- markers). Off by default; NL_Debug:Invoke("Tune", "Animations.Swap.On", true), read as each fighter next plays it.
	Swap = { On = false, Clips = { RookCombo = "RookComboSnap" } :: { [string]: string } },
	Ids = {
		-- published under the group, 2026-11-23 (docs/asset-log.md): AR52's two, the first clips up
		ShadeGuard = 110693664240912,
		ShadeLunge = 102847424758672,
		-- 2026-11-24: AR57's, the elites' own
		ShadeGuardElite = 137199476410376,
		ShadeLungeElite = 104663452343076,
		-- 2026-11-24: AR58's, the Support's
		ShadeCast = 134130801801922,
		-- 2026-11-25: every other clip a shipped fighter plays, published under the group (docs/asset-log.md), so they move outside Studio (Cases/Clips)
		RookCombo = 109507884509265, -- 2026-11-26: rebaked from Modulo's run beside the snap (TR66 row 13)
		RookComboSnap = 135404826126237, -- 2026-11-26: the jab retimed, played by Swap (TR66 row 13)
		RookDown = 76098815267317,
		RookHaymaker = 138665901194052,
		RookHit = 75740448301863,
		RookIdle = 138750665580513,
		RookReveal = 124560683635693,
		RookUp = 80323823693572,
		KirraCombo = 140239433081509,
		KirraIdle = 108318089099016,
		KirraReveal = 111050593111477,
		KirraScarfStep = 105107044044384,
		-- 2026-11-26: AR66's, Kirra's own reactions in place of her tail's layers over Rook's
		KirraHit = 100347512530324,
		KirraDown = 104340648024258,
		KirraUp = 89020276273109,
		PipCombo = 103542498101838,
		PipDown = 103301007001277,
		PipHit = 73299738552534,
		PipIdle = 70901275448837,
		PipLanternBurst = 116945277984913,
		PipReveal = 108006097011335,
		PipSkip = 105476882266259,
		PipUp = 137781811293957,
		WattCombo = 74985171400109,
		WattDown = 140558073244324,
		WattGroundWire = 128337394503043,
		WattHit = 72996074110267,
		WattIdle = 136459622633366,
		WattReveal = 87835885076667,
		WattUp = 132922134441811,
		LyricCombo = 84081020273026,
		LyricHeldNote = 84568089666118,
		LyricIdle = 136586189975169,
		LyricReveal = 101522079487373,
		LyricSkip = 94294294123885,
		-- 2026-11-26: AR66's, Lyric's own reactions in place of Pip's, her stand and speakers keyed in them
		LyricHit = 86395559014665,
		LyricDown = 102460695668151,
		LyricUp = 138529485516868,
		ShadeAttack = 119217500758699,
		ShadeAttackLeft = 132742315983424,
		ShadeBurst = 120794324997203,
		ShadeHit = 97079708302692,
		ShadeHitLeft = 135520146794730,
		ShadeIdle = 116551302510908,
		ShadeWalk = 76012623208461,
		LamplighterChallenge = 127880386701212,
		LamplighterDown = 129777049911479,
		LamplighterHit = 94565990734001,
		LamplighterIdle = 73759405794554,
		LamplighterReady = 113898895062416,
		LamplighterSignature = 131424199571891,
		LamplighterSwing = 136349914534422,
		LamplighterWalk = 95046868303280,
	} :: { [string]: number },
	Rigs = {
		R6 = { Idle = "RookIdle", Hit = "RookHit", Down = "RookDown", Up = "RookUp" },
		Robe = { Idle = "PipIdle", Hit = "PipHit", Down = "PipDown", Up = "PipUp" },
		-- Watt's own (AR11): the spear slung on his back is keyed in each (its joint on the Torso), so the shared sets would
		-- leave it still through a fall
		Watt = { Idle = "WattIdle", Hit = "WattHit", Down = "WattDown", Up = "WattUp" },
		-- Kirra's and Lyric's own (AR66): her tail keyed with the body; her stand and speakers keyed in each, the stand left
		-- standing while she lies
		Kirra = { Idle = "KirraIdle", Hit = "KirraHit", Down = "KirraDown", Up = "KirraUp" },
		Lyric = { Idle = "LyricIdle", Hit = "LyricHit", Down = "LyricDown", Up = "LyricUp" },
		Shade = { Idle = "ShadeIdle", Walk = "ShadeWalk", Hit = "ShadeHit", Down = "ShadeBurst" },
		Lamplighter = { Idle = "LamplighterIdle", Walk = "LamplighterWalk", Hit = "LamplighterHit", Down = "LamplighterDown" },
	} :: { [string]: { [string]: string } },
	-- A Voidkin's own layer over its rig's shared reaction, by its def and the reaction's role: it starts with the
	-- reaction, one priority above it, and keys only what the shared set doesn't. None now: Kirra's tail layers (AR10)
	-- went into her own set (AR66).
	Layers = {} :: { [string]: { [string]: string } },
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
	-- A kind of fighter's own clip in place of an action's (AR57): the elite's raise and lunge, in the same lengths,
	-- markers and fades (Shade_Elite.clips.json, EliteOf), so one action drives both; the weight is in the spacing.
	Kinds = {
		Elite = { ShadeGuard = "ShadeGuardElite", ShadeLunge = "ShadeLungeElite" },
	} :: { [string]: { [string]: string } },
	-- A walk's ground speed at rate 1, in studs a second (its stride over its loop: Shade.clips.json). The clip plays at the
	-- body's own speed over this, so its feet keep to the ground, up to MaxRate (AR2: "walk speed comes from the stride").
	Strides = {
		ShadeWalk = 4.11,
		LamplighterWalk = 4.94, -- at its Scale, 1.5 (Lamplighter.clips.json)
	} :: { [string]: number },
	Walk = { MinSpeed = 0.6, MaxRate = 3 }, -- studs a second below which it stands; the fastest it plays
	-- A prop a Voidkin lets go of when it goes down, by its def: its motor's piece leaves the hand Drop seconds into the
	-- Down clip, falls over Fall seconds to lie flat Aside studs to the body's right and Along ahead, and goes back to the
	-- hand over Back once Up begins. None now: Lyric's stand (AR4, section 6) is keyed in her own Down and Up (AR66).
	Props = {} :: { [string]: { Motor: string, Drop: number, Fall: number, Aside: number, Along: number, Back: number } },
	-- The game's name for each shared clip, for its fades: the rigs' reactions and the enemies' moves. A Voidkin's own
	-- clips take theirs from their place in its kit (Definitions.Voidkin, Kit; Definitions.Actions, RoleOf).
	Roles = {
		RookIdle = "Idle",
		RookHit = "Hit",
		RookDown = "Down",
		RookUp = "Up",
		PipIdle = "Idle",
		PipHit = "Hit",
		PipDown = "Down",
		PipUp = "Up",
		WattIdle = "Idle",
		WattHit = "Hit",
		WattDown = "Down",
		WattUp = "Up",
		KirraIdle = "Idle",
		KirraHit = "Hit",
		KirraDown = "Down",
		KirraUp = "Up",
		LyricIdle = "Idle",
		LyricHit = "Hit",
		LyricDown = "Down",
		LyricUp = "Up",
		ShadeIdle = "Idle",
		ShadeWalk = "Walk",
		ShadeAttack = "Swipe",
		ShadeAttackLeft = "Swipe",
		ShadeHit = "Hit",
		ShadeHitLeft = "Hit",
		ShadeBurst = "Burst",
		ShadeGuard = "Guard",
		ShadeLunge = "Lunge",
		ShadeGuardElite = "Guard",
		ShadeLungeElite = "Lunge",
		ShadeCast = "Cast",
		LamplighterIdle = "Idle",
		LamplighterChallenge = "Challenge",
		LamplighterWalk = "Walk",
		LamplighterSwing = "Swipe",
		LamplighterHit = "Hit",
		LamplighterSignature = "Signature",
		LamplighterDown = "Burst",
	} :: { [string]: string },
}
