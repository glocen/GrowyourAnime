--!strict
-- Cues (shared Config): the fight's layered cues (docs/asset-requests.md, AR13, the sound test). A cue is a few layers
-- started together, each one of its takes picked at random, played on the audio graph by the client's
-- FighterController/Cues; Rules.Sound says which cue a beat or a contact plays. Our layers are Modulo's takes, made by
-- tools/audio/test6.py and uploaded under the group (docs/asset-log.md); the library's layers join them by the director's
-- ear. Unheard: every level and spread is a seed (DESIGN) until the director's ear in a fight sets it. Tuned live:
-- NL_Debug:Invoke("Tune", "Cues.Cues.HeavyHit.Layers.3.Volume", 0.5) (a list's row by its number).
-- AR39: a take may be a slice of a library sound (Take), and a pilot's cue has arrangements beside it (Use, Arrangements).

-- A take: its asset; its length as played and the time to its top from its start, s. One of ours plays whole. A library
-- sound plays a slice of its file (AR39), never downloaded or edited: From and To in its file, s (Seconds = To - From),
-- faded in over In and out over Out, s, so its edges never click. Gain is its own level inside its list (linear, 1
-- when left out), times its layer's Volume: a library sound can't be levelled offline, as ours are.
export type Take = { Id: number, Seconds: number, Peak: number, From: number?, To: number?, In: number?, Out: number?, Gain: number? }
export type Layer = {
	Takes: string, -- the Takes it plays one of, never the same one twice running
	At: number, -- seconds from the cue's moment it starts at; negative is before it
	Lead: string?, -- "Peak" or "Length": and earlier by its take's time to its top, or its whole length, landing on the moment
	Volume: number,
	Strength: boolean?, -- its volume times the hit's strength (Strength, below): none at the lightest hit, full at the heaviest
}
export type Cue = {
	Layers: { Layer },
	Bus: string, -- "Lead" or "Shade": the Shades' bus ducks under the player's own lead's hits (Duck)
	Pitch: { number }, -- the playback speed one play picks, the same for its layers so they stay in tune together
	Volume: { number }, -- the volume one play picks
	Voices: number, -- plays at once: one past it stops the oldest
	Near: number, -- studs from the listener it plays at full volume within
	Range: number, -- and is silent by
}

local Config = {
	Volume = 1, -- every cue's fader
	-- Roblox doubled an AudioPlayer's volume in 2025 (docs/research/sound.md, "The engine, for Faber", the level trap): this
	-- takes it back, so a cue's Volume means what a Sound's does, beside Config.Sounds' cues. Measured 2026-11-17: a
	-- player at Volume 1 plays its file as it is through its bus, so a cue at Volume 1 is 6 dB under its file.
	Trim = 0.5,
	-- On the player's own lead's hit, the Shades' bus goes down by Db at once, holds, and comes back over Release (AR13: "the
	-- Shade's sounds and the ambience drop 3 to 4 dB for 150 ms").
	Duck = { Db = -3.5, Hold = 0.15, Release = 0.05 },
	-- A layer's start is handed to the mixer's clock this long before it, s (AR39). A start the mixer holds can't be
	-- taken back (FighterController/Cues), so this is also the longest a stopped voice waits before it plays again.
	Lookahead = 0.05,
	-- Each bus ends in a limiter (AR39, research on round 1): the cues' levels are set by their relation, and the rare
	-- exact coincidence of tops is caught here, never by turning the cues down. MaxLevel in dB, Release in s. Seeds.
	Limiter = { MaxLevel = -1, Release = 0.05 },
	Strength = { 2, 8 }, -- the rungs (Config.Combat.Hitstop) a hit's strength runs over, from none to full

	-- Modulo's takes (build/handoff/Audio/test6/test6.json): each layer's, matched in loudness, so a play's Volume spread is
	-- the only one inside a layer. Those of the hits and the swipe left with the director's keeps (TR42, 2026-11-19).
	Takes = {
		ShadeHurtSpark = {
			{ Id = 97910398854788, Seconds = 0.07, Peak = 0.0015 }, -- ShadeHurtSpark_1
			{ Id = 111484288931351, Seconds = 0.06, Peak = 0.0015 }, -- ShadeHurtSpark_2
			{ Id = 124507240514033, Seconds = 0.075, Peak = 0.0015 }, -- ShadeHurtSpark_3
		},
		ShadeBurstShimmer = {
			{ Id = 126445682256961, Seconds = 0.7, Peak = 0.0210 }, -- ShadeBurstShimmer_1
			{ Id = 78525311361600, Seconds = 0.6, Peak = 0.0480 }, -- ShadeBurstShimmer_2
		},
		ShadeBurstTicks = {
			{ Id = 121773721624039, Seconds = 0.31, Peak = 0.0016 }, -- ShadeBurstTicks_1
			{ Id = 88194747580265, Seconds = 0.31, Peak = 0.0013 }, -- ShadeBurstTicks_2
		},
		HeavyRiser = {
			{ Id = 97515716318295, Seconds = 0.18, Peak = 0.1720 }, -- HeavyRiser_1
			{ Id = 114077736762662, Seconds = 0.15, Peak = 0.1415 }, -- HeavyRiser_2
			{ Id = 132895683656890, Seconds = 0.2, Peak = 0.1902 }, -- HeavyRiser_3
		},
		CritShing = {
			{ Id = 91060945362019, Seconds = 0.26, Peak = 0.0202 }, -- CritShing_1
			{ Id = 126467383466299, Seconds = 0.28, Peak = 0.0153 }, -- CritShing_2
			{ Id = 79304245121355, Seconds = 0.24, Peak = 0.0025 }, -- CritShing_3
		},
		-- AR39's library lists: begin (build/scratch/faber/ar39/round.py writes between these lines)
		LibContact = {
			{ Id = 9120003720, Seconds = 0.078, Peak = 0.008, From = 0.004, To = 0.082, In = 0.003, Out = 0.03, Gain = 0.473 }, -- Thigh Slap 2 (SFX), ProSoundEffects
			{ Id = 9114773313, Seconds = 0.076, Peak = 0.0057, From = 0.0, To = 0.076, In = 0.003, Out = 0.03, Gain = 1.161 }, -- Hand Slap Single Hits 16 (SFX), ProSoundEffects
			{ Id = 9113532901, Seconds = 0.049, Peak = 0.0058, From = 0.008, To = 0.057, In = 0.003, Out = 0.02, Gain = 0.861 }, -- Body Pats Cloth Hits 3 (SFX), ProSoundEffects
			{ Id = 9113316991, Seconds = 0.032, Peak = 0.0028, From = 0.008, To = 0.04, In = 0.003, Out = 0.015, Gain = 1.84 }, -- Baseball Slap Ball Into Glove Singles 4 (SFX), ProSoundEffects
		},
		LibSnap = {
			{ Id = 9114763106, Seconds = 0.032, Peak = 0.004, From = 0.0, To = 0.032, In = 0.003, Out = 0.015, Gain = 0.768 }, -- Hand Clap Single Hits 14 (SFX), ProSoundEffects
			{ Id = 9114762131, Seconds = 0.022, Peak = 0.0032, From = 0.788, To = 0.81, In = 0.003, Out = 0.01, Gain = 1.876 }, -- Hand Claps 1 (SFX), ProSoundEffects
			{ Id = 9114771788, Seconds = 0.054, Peak = 0.0046, From = 0.0, To = 0.054, In = 0.003, Out = 0.025, Gain = 1.0 }, -- Hand Slap Claps 2 (SFX), ProSoundEffects
		},
		LibLow = {
			{ Id = 9113568059, Seconds = 0.11, Peak = 0.0081, From = 0.004, To = 0.114, In = 0.003, Out = 0.04, Gain = 0.786 }, -- Boxing Hits 5 (SFX), ProSoundEffects
			{ Id = 9113514100, Seconds = 0.096, Peak = 0.0065, From = 0.024, To = 0.12, In = 0.003, Out = 0.04, Gain = 1.273 }, -- Body Hits Leather Baseball Glove 13 (SFX), ProSoundEffects
		},
		LibLowLong = {
			{ Id = 9113568059, Seconds = 0.14, Peak = 0.0081, From = 0.004, To = 0.144, In = 0.003, Out = 0.05, Gain = 0.789 }, -- Boxing Hits 5 (SFX), ProSoundEffects
			{ Id = 9113514100, Seconds = 0.186, Peak = 0.0065, From = 0.024, To = 0.21, In = 0.003, Out = 0.06, Gain = 1.268 }, -- Body Hits Leather Baseball Glove 13 (SFX), ProSoundEffects
		},
		LibHeavyBody = {
			{ Id = 9113574140, Seconds = 0.138, Peak = 0.0028, From = 0.0, To = 0.138, In = 0.003, Out = 0.05, Gain = 0.461 }, -- Boxing Hits 17 (SFX), ProSoundEffects
			{ Id = 9113531442, Seconds = 0.144, Peak = 0.005, From = 0.634, To = 0.778, In = 0.003, Out = 0.05, Gain = 1.0 }, -- Body Kick With Leather Boots 9 (SFX), ProSoundEffects
			{ Id = 9113470397, Seconds = 0.118, Peak = 0.0087, From = 0.03, To = 0.148, In = 0.003, Out = 0.05, Gain = 7.27 }, -- Body Fall Heavy 5 (SFX), ProSoundEffects
		},
		LibHeavySnap = {
			{ Id = 9113316991, Seconds = 0.032, Peak = 0.0028, From = 0.008, To = 0.04, In = 0.003, Out = 0.015, Gain = 1.121 }, -- Baseball Slap Ball Into Glove Singles 4 (SFX), ProSoundEffects
			{ Id = 9114763106, Seconds = 0.032, Peak = 0.004, From = 0.0, To = 0.032, In = 0.003, Out = 0.015, Gain = 0.41 }, -- Hand Clap Single Hits 14 (SFX), ProSoundEffects
			{ Id = 9114762131, Seconds = 0.022, Peak = 0.0032, From = 0.788, To = 0.81, In = 0.003, Out = 0.01, Gain = 1.0 }, -- Hand Claps 1 (SFX), ProSoundEffects
		},
		LibAir = {
			{ Id = 9120704978, Seconds = 0.264, Peak = 0.1058, From = 0.036, To = 0.3, In = 0.003, Out = 0.06, Gain = 1.0 }, -- Whooshes Fast Wipes Quick Airy Slices 3 (SFX), ProSoundEffects
			{ Id = 9120972444, Seconds = 0.162, Peak = 0.0338, From = 0.022, To = 0.184, In = 0.003, Out = 0.06, Gain = 2.325 }, -- Wood Whoosh Slicing Air Quick Swings 1 (SFX), ProSoundEffects
			{ Id = 9120709477, Seconds = 0.136, Peak = 0.047, From = 0.2, To = 0.336, In = 0.003, Out = 0.04, Gain = 0.912 }, -- Whoosh Fast Short Dull Several Versions 2 (SFX), ProSoundEffects
		},
		LibFlick = {
			{ Id = 9125654187, Seconds = 0.036, Peak = 0.0064, From = 0.322, To = 0.358, In = 0.003, Out = 0.015, Gain = 0.737 }, -- Map Movement Opening Closing Rustling Paper  (SFX), ProSoundEffects
			{ Id = 9114348719, Seconds = 0.09, Peak = 0.0303, From = 0.58, To = 0.67, In = 0.003, Out = 0.03, Gain = 1.0 }, -- Envelope Slam Down 12 (SFX), ProSoundEffects
			{ Id = 9118106802, Seconds = 0.12, Peak = 0.0604, From = 0.138, To = 0.258, In = 0.003, Out = 0.03, Gain = 2.568 }, -- Record Sleeve Pulled Out Back In 9 (SFX), ProSoundEffects
		},
		LibRustle = {
			{ Id = 9125654187, Seconds = 0.17, Peak = 0.1504, From = 0.178, To = 0.348, In = 0.003, Out = 0.012, Gain = 0.619 }, -- Map Movement Opening Closing Rustling Paper  (SFX), ProSoundEffects
			{ Id = 9126143504, Seconds = 0.2, Peak = 0.111, From = 0.298, To = 0.498, In = 0.003, Out = 0.04, Gain = 1.0 }, -- Typing Paper Flutter Single Sheet Passing By (SFX), ProSoundEffects
			{ Id = 9118106802, Seconds = 0.25, Peak = 0.1904, From = 0.008, To = 0.258, In = 0.003, Out = 0.03, Gain = 2.414 }, -- Record Sleeve Pulled Out Back In 9 (SFX), ProSoundEffects
		},
		-- AR39's library lists: end
		-- TR42's keeps: begin (the director's 63 on the audition panel, 2026-11-19; build/scratch/faber/tr42/kept.py writes
		-- between these lines). Each the finder's cut of its library file, its first event whole; Gain sets it at its cue's
		-- matched loudness, today's LightHit then (-42.5 LUFS short-term) plus Config.Audition.Levels, as the panel played it.
		KeptLight = {
			{ Id = 101093315205711, Seconds = 0.64213, Peak = 0.00769, From = 0.05287, To = 0.69500, In = 0, Out = 0.020, Gain = 0.236 }, -- Audio_Axe_kick_hit_1, djtaothuatday1
			{ Id = 78108149531620, Seconds = 0.32694, Peak = 0.00588, From = 0.04306, To = 0.37000, In = 0, Out = 0.020, Gain = 0.191 }, -- punch kick beefy hit sfx 3, Axellatic
			{ Id = 76673854191773, Seconds = 0.35900, Peak = 0.00719, From = 0.04600, To = 0.40500, In = 0, Out = 0.020, Gain = 0.125 }, -- punch kick beefy hit sfx 4, Axellatic
			{ Id = 126976659766267, Seconds = 0.49066, Peak = 0.00791, From = 0.05434, To = 0.54500, In = 0, Out = 0.020, Gain = 0.252 }, -- Hit - Impact - Punch - Blunt, lorenzosaudiostash
			{ Id = 137163256711828, Seconds = 0.51340, Peak = 0.00688, From = 0.07100, To = 0.58440, In = 0, Out = 0.010, Gain = 0.179 }, -- Punch, guesttown82
			{ Id = 74041775202019, Seconds = 0.46303, Peak = 0.00669, From = 0.08697, To = 0.55000, In = 0, Out = 0.020, Gain = 0.490 }, -- Impact - Punch - Hit - Blunt, lorenzosaudiostash
			{ Id = 139697578472716, Seconds = 0.27759, Peak = 0.00797, From = 0.04241, To = 0.32000, In = 0, Out = 0.020, Gain = 0.320 }, -- punch, frankprogamer_Y
			{ Id = 114637695466966, Seconds = 0.28731, Peak = 0.00422, From = 0.01269, To = 0.30000, In = 0, Out = 0.020, Gain = 0.119 }, -- Kick Hit 1, Generic_Username3510
			{ Id = 80766153538417, Seconds = 0.49519, Peak = 0.00800, From = 0.28481, To = 0.78000, In = 0, Out = 0.020, Gain = 0.259 }, -- combat-sword-swing-hit, 0Estetic_girl0
			{ Id = 139897497838184, Seconds = 0.63606, Peak = 0.00794, From = 0.05394, To = 0.69000, In = 0, Out = 0.020, Gain = 0.118 }, -- punch6, ProKartallar165456
			{ Id = 131741758254583, Seconds = 0.49966, Peak = 0.00766, From = 0.13034, To = 0.63000, In = 0, Out = 0.020, Gain = 0.359 }, -- punch sound, SVPJSP
			{ Id = 137972233621112, Seconds = 0.34500, Peak = 0.00556, From = 0.00000, To = 0.34500, In = 0, Out = 0.020, Gain = 0.181 }, -- LiTDoom | Combat Knife Generic Hit, xxxnewmakcxxx
			{ Id = 124216736896680, Seconds = 0.64219, Peak = 0.00462, From = 0.09781, To = 0.74000, In = 0, Out = 0.020, Gain = 0.338 }, -- melee knife hit 1, Alika0946
			{ Id = 8595975878, Seconds = 0.64841, Peak = 0.00728, From = 0.06659, To = 0.71500, In = 0, Out = 0.020, Gain = 0.230 }, -- hit_kick_m, h3artevil
			{ Id = 94197481990296, Seconds = 0.53497, Peak = 0.00666, From = 0.04503, To = 0.58000, In = 0, Out = 0.020, Gain = 0.103 }, -- Punch Hit 4 ALT, Generic_Username3510
			{ Id = 8595975458, Seconds = 0.24975, Peak = 0.00250, From = 0.13106, To = 0.38081, In = 0, Out = 0.010, Gain = 0.504 }, -- hit_kick_l, h3artevil
			{ Id = 8595980577, Seconds = 0.38559, Peak = 0.00800, From = 0.01166, To = 0.39725, In = 0, Out = 0.010, Gain = 0.340 }, -- hit_punch_l, h3artevil
			{ Id = 119801699610817, Seconds = 0.39250, Peak = 0.00591, From = 0.02866, To = 0.42116, In = 0, Out = 0.010, Gain = 0.149 }, -- hit_kick2, mostimayuri
			{ Id = 119316959874813, Seconds = 0.59552, Peak = 0.00637, From = 0.05666, To = 0.65218, In = 0, Out = 0.010, Gain = 0.144 }, -- LiTDoom | Combat Knife Fresh hit, xxxnewmakcxxx
			{ Id = 110562992588060, Seconds = 0.50206, Peak = 0.00575, From = 0.03794, To = 0.54000, In = 0, Out = 0.020, Gain = 0.325 }, -- combat_melee_hit2, BWMixezz
			{ Id = 86860520324860, Seconds = 0.66225, Peak = 0.00753, From = 0.10275, To = 0.76500, In = 0, Out = 0.020, Gain = 0.163 }, -- combat_sword_hit2, BWMixezz
			{ Id = 139795256698131, Seconds = 0.32053, Peak = 0.00728, From = 0.08447, To = 0.40500, In = 0, Out = 0.020, Gain = 0.826 }, -- punchhit2, 0btain_TheGrain
			{ Id = 140626490819228, Seconds = 0.35109, Peak = 0.00191, From = 0.00891, To = 0.36000, In = 0, Out = 0.010, Gain = 0.113 }, -- punch7, ProKartallar165456
			{ Id = 9117969687, Seconds = 0.35488, Peak = 0.00753, From = 0.03012, To = 0.38500, In = 0, Out = 0.020, Gain = 0.204 }, -- Punch Kit Beefy Hit 2 (SFX), ProSoundEffects
			{ Id = 109496822316417, Seconds = 0.50756, Peak = 0.00694, From = 0.05244, To = 0.56000, In = 0, Out = 0.020, Gain = 0.307 }, -- melee knife hit 2, Alika0946
			{ Id = 9117969717, Seconds = 0.28663, Peak = 0.00800, From = 0.05337, To = 0.34000, In = 0, Out = 0.020, Gain = 0.179 }, -- Punch Kit Beefy Hit 3 (SFX), ProSoundEffects
			{ Id = 79476956608476, Seconds = 0.51950, Peak = 0.00797, From = 0.12550, To = 0.64500, In = 0, Out = 0.020, Gain = 0.436 }, -- Hit - Punch - Impact - Blunt - Debris - Downslam, lorenzosaudiostash
			{ Id = 139890294541073, Seconds = 0.57853, Peak = 0.00706, From = 0.06147, To = 0.64000, In = 0, Out = 0.020, Gain = 0.294 }, -- combat_melee_hit1, BWMixezz
			{ Id = 106617636342358, Seconds = 0.43719, Peak = 0.00616, From = 0.04781, To = 0.48500, In = 0, Out = 0.020, Gain = 0.297 }, -- combat_melee_hit3, BWMixezz
			{ Id = 132851203831922, Seconds = 0.49519, Peak = 0.00800, From = 0.28481, To = 0.78000, In = 0, Out = 0.020, Gain = 0.259 }, -- combat-sword-swing-hit, tammmmmkung
			{ Id = 130907980308479, Seconds = 0.41952, Peak = 0.00744, From = 0.02506, To = 0.44458, In = 0, Out = 0.010, Gain = 0.111 }, -- Kick Hit 2, Generic_Username3510
			{ Id = 129240409121774, Seconds = 0.52250, Peak = 0.00737, From = 0.15250, To = 0.67500, In = 0, Out = 0.020, Gain = 0.338 }, -- melee knife hit 4, Alika0946
		},
		KeptHeavy = {
			{ Id = 82235785832022, Seconds = 0.66428, Peak = 0.00203, From = 0.00072, To = 0.66500, In = 0, Out = 0.020, Gain = 0.214 }, -- Heavy_punch_impact_#3-1770242809040, MegaBloxxy
			{ Id = 79157071156981, Seconds = 1.08425, Peak = 0.00706, From = 0.05575, To = 1.14000, In = 0, Out = 0.020, Gain = 0.300 }, -- bee strong impact, HuskerTheWulf2
			{ Id = 136097290040379, Seconds = 0.94141, Peak = 0.00759, From = 0.14359, To = 1.08500, In = 0, Out = 0.020, Gain = 0.183 }, -- Power hit 10, MobbyTheSlayer
			{ Id = 97949571394241, Seconds = 1.23588, Peak = 0.00703, From = 0.04412, To = 1.28000, In = 0, Out = 0.020, Gain = 0.321 }, -- Heavy Rifle Bullet Hit, NNTTWW7
			{ Id = 97522871949213, Seconds = 1.12256, Peak = 0.00737, From = 0.12244, To = 1.24500, In = 0, Out = 0.020, Gain = 0.380 }, -- Audio_ground_slam, Tofah_89
			{ Id = 84636875169658, Seconds = 1.39431, Peak = 0.00797, From = 0.11069, To = 1.50500, In = 0, Out = 0.020, Gain = 0.296 }, -- Heavy Sword Hit 1, prescr_ption
			{ Id = 135370885522783, Seconds = 0.72356, Peak = 0.00400, From = 0.17644, To = 0.90000, In = 0, Out = 0.020, Gain = 0.323 }, -- Heavy Hit 1, GleonoffG
			{ Id = 97005077227469, Seconds = 1.37159, Peak = 0.00578, From = 0.50341, To = 1.87500, In = 0, Out = 0.020, Gain = 0.065 }, -- Strong Impact, GleonoffG
			{ Id = 102109874814687, Seconds = 1.37294, Peak = 0.00759, From = 0.14706, To = 1.52000, In = 0, Out = 0.020, Gain = 0.296 }, -- blastaway throw punch heavy sfx hit, Axellatic
			{ Id = 138379788001813, Seconds = 0.34356, Peak = 0.00637, From = 0.07144, To = 0.41500, In = 0, Out = 0.020, Gain = 0.461 }, -- Heavy Punch, projay2951
			{ Id = 3908308607, Seconds = 1.04906, Peak = 0.00644, From = 0.11094, To = 1.16000, In = 0, Out = 0.020, Gain = 0.405 }, -- Metal Door Slam, S1xty
			{ Id = 105223250998958, Seconds = 1.33813, Peak = 0.00553, From = 0.27187, To = 1.61000, In = 0, Out = 0.020, Gain = 0.449 }, -- Really strong impact, lucsanti31
			{ Id = 93704409008888, Seconds = 1.33891, Peak = 0.00306, From = 0.03609, To = 1.37500, In = 0, Out = 0.020, Gain = 0.219 }, -- Echoing Smash/Impact SFX, DragonndineWhite2
			{ Id = 76385508400544, Seconds = 1.12509, Peak = 0.00709, From = 0.09066, To = 1.21575, In = 0, Out = 0.010, Gain = 0.183 }, -- Heavy Punch, Vxsion_Fear
			{ Id = 99021683276237, Seconds = 0.49797, Peak = 0.00759, From = 0.02703, To = 0.52500, In = 0, Out = 0.020, Gain = 0.289 }, -- Heavy_Punch_1, aarondeminecraft1
			{ Id = 9113964478, Seconds = 1.09163, Peak = 0.00562, From = 0.26837, To = 1.36000, In = 0, Out = 0.020, Gain = 1.288 }, -- Cracky Punch 6 (SFX), ProSoundEffects
			{ Id = 5951832571, Seconds = 0.75428, Peak = 0.00100, From = 0.15572, To = 0.91000, In = 0, Out = 0.020, Gain = 0.411 }, -- Sword Hit heavy 4 beyond x OTH, tushai
			{ Id = 87860406137843, Seconds = 0.86987, Peak = 0.00159, From = 0.00013, To = 0.87000, In = 0, Out = 0.020, Gain = 0.233 }, -- hit_blunt_heavy_00_0, Sanya790228
			{ Id = 88385100345706, Seconds = 1.38472, Peak = 0.00622, From = 0.21528, To = 1.60000, In = 0, Out = 0.020, Gain = 0.356 }, -- Heavy Sword Hit 3, prescr_ption
			{ Id = 127429272097426, Seconds = 1.28366, Peak = 0.00709, From = 0.19634, To = 1.48000, In = 0, Out = 0.020, Gain = 0.112 }, -- heavy Punch, SillyShippo
			{ Id = 127605012393667, Seconds = 1.09419, Peak = 0.00384, From = 0.41581, To = 1.51000, In = 0, Out = 0.020, Gain = 0.937 }, -- Dreamer Power Slam Hit, tarvoski
			{ Id = 131871609905735, Seconds = 0.46950, Peak = 0.00769, From = 0.10519, To = 0.57469, In = 0, Out = 0.010, Gain = 0.326 }, -- hit 1 power heavy sfx, Axellatic
		},
		KeptSwipe = {
			{ Id = 130845581077634, Seconds = 0.84000, Peak = 0.25956, From = 0.00000, To = 0.84000, In = 0, Out = 0.020, Gain = 0.128 }, -- teleport, SLASH43415
			{ Id = 101359410446176, Seconds = 0.91500, Peak = 0.17181, From = 0.00000, To = 0.91500, In = 0, Out = 0.020, Gain = 0.078 }, -- Coyote Claw Swipe, StickBugDistraction
			{ Id = 136949335117661, Seconds = 0.51500, Peak = 0.01959, From = 0.00000, To = 0.51500, In = 0, Out = 0.020, Gain = 0.314 }, -- Slash_hit, Bobismad689
			{ Id = 137431264282253, Seconds = 0.39000, Peak = 0.14409, From = 0.04000, To = 0.43000, In = 0, Out = 0.020, Gain = 0.231 }, -- Audio_swoosh, thy_doggeth
			{ Id = 93311226362113, Seconds = 0.57500, Peak = 0.14772, From = 0.02500, To = 0.60000, In = 0, Out = 0.020, Gain = 0.161 }, -- m1 whoosh swing sfx miss, Axellatic
			{ Id = 136833367092810, Seconds = 0.67765, Peak = 0.23081, From = 0.00000, To = 0.67765, In = 0, Out = 0.010, Gain = 0.083 }, -- hit_slash_m, h3artevil
			{ Id = 123240796092086, Seconds = 0.76500, Peak = 0.02706, From = 0.07500, To = 0.84000, In = 0, Out = 0.020, Gain = 0.197 }, -- sword hit or swing, tarvoski
			{ Id = 92188315735827, Seconds = 0.91500, Peak = 0.01256, From = 0.00000, To = 0.91500, In = 0, Out = 0.020, Gain = 0.187 }, -- Slash Hit Impact, Divinicalll
			{ Id = 140228522212884, Seconds = 0.52665, Peak = 0.14097, From = 0.00000, To = 0.52665, In = 0, Out = 0.010, Gain = 0.648 }, -- Slash 4, Sunny_CIover
		},
		-- TR42's keeps: end
	} :: { [string]: { Take } },

	Cues = {
		-- 1. A Shade's swipe, on its clock, landed or not: one of the director's nine keeps (TR42, 2026-11-19), its rise
		-- whole and its top on the hit. Quieter than the lead's hits.
		ShadeSwipe = {
			Layers = { { Takes = "KeptSwipe", At = 0, Lead = "Peak", Volume = 1 } },
			Bus = "Shade",
			Pitch = { 0.97, 1.03 }, -- seeds: the panel played each at 1, so a play stays close to what was kept
			Volume = { 0.9, 1 },
			Voices = 4,
			Near = 20,
			Range = 120,
		} :: Cue,
		-- 2. A Shade's hurt, on the touch: the spark tick. Its library paper crumple waits on the shortlist.
		ShadeHurt = {
			Layers = { { Takes = "ShadeHurtSpark", At = 0, Volume = 0.8 } },
			Bus = "Shade",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
			Voices = 4,
			Near = 20,
			Range = 120,
		} :: Cue,
		-- 3. A Shade bursts, on its burst's frame: the shimmer on A and the ticks. Its library rip and thump wait on the
		-- shortlist. Three at once at most (AR13).
		ShadeBurst = {
			Layers = {
				{ Takes = "ShadeBurstShimmer", At = 0, Volume = 0.8 },
				{ Takes = "ShadeBurstTicks", At = 0, Volume = 0.7 },
			},
			Bus = "Shade",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
			Voices = 3,
			Near = 30,
			Range = 160,
		} :: Cue,
		-- 4. A light hit, on the touch: one of the director's 32 keeps (TR42, 2026-11-19), never the same twice running.
		LightHit = {
			Layers = { { Takes = "KeptLight", At = 0, Volume = 1 } },
			Bus = "Lead",
			Pitch = { 0.97, 1.03 },
			Volume = { 0.9, 1 },
			Voices = 4,
			Near = 30,
			Range = 160,
		} :: Cue,
		-- 5a. A heavy hit's wind-up, on the attacker's clock, landed or not: the riser, cut off on the hit.
		HeavyWind = {
			Layers = { { Takes = "HeavyRiser", At = 0, Lead = "Length", Volume = 0.6 } },
			Bus = "Lead",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
			Voices = 2,
			Near = 30,
			Range = 160,
		} :: Cue,
		-- 5b. A heavy hit, on the touch: one of the director's 22 keeps (TR42, 2026-11-19), never the same twice running.
		HeavyHit = {
			Layers = { { Takes = "KeptHeavy", At = 0, Volume = 1 } },
			Bus = "Lead",
			Pitch = { 0.97, 1.03 },
			Volume = { 0.9, 1 },
			Voices = 2,
			Near = 30,
			Range = 160,
		} :: Cue,
		-- 6. A critical, on the server's word: the shing over the hit's own cue, under its layers (Modulo's seed).
		Critical = {
			Layers = { { Takes = "CritShing", At = 0, Volume = 0.7 } },
			Bus = "Lead",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
			Voices = 2,
			Near = 30,
			Range = 160,
		} :: Cue,
	} :: { [string]: Cue },

	-- AR39, the sound rescue's A/B: a pilot's cue played as it was ("Old") or as one of its arrangements, by name, switched
	-- while playing: NL_Debug:Invoke("Tune", "Cues.Use.LightHit", "A"). An arrangement is a whole cue of its own, so
	-- the old one stays as it is beside it. A name with no arrangement plays the old cue.
	Use = {
		LightHit = "Old",
		HeavyHit = "Old",
		ShadeSwipe = "Old",
		Haymaker = "Old",
		ScarfStep = "Old",
		LanternBurst = "Old",
		GroundWire = "Old",
		HeldNote = "Old",
		MageShot = "Old",
		MageHit = "Old",
		HealerShot = "Old",
		HealerHit = "Old",
		RookHit = "Old",
		KirraHit = "Old",
		WattHit = "Old",
	},
	-- TR42's second round (the director, 2026-11-19: "we need more audition sfx for the skills of our current voidskin
	-- rooster + the m1 of ranged class like mage etc"): an action's own cues, in place of the ones every hit plays. Beat
	-- plays on its attacker's clock in place of the heavy wind-up (Rules.Sound.Beat), on each of its hits' beats, or on
	-- At's alone; Contact on the struck body in place of the light or heavy hit (Rules.Sound.Contact). Each own cue
	-- starts as what played in its place before (below), so nothing changes until the audition's pick. The ranged M1s
	-- are named by class: the Mage's are a Fire Mage's (a Mage of another element gets its own), a later Healer's combo
	-- joins Lyric's. The melee fighters' combo hits split the light hit's keeps between them (research, 2026-11-19).
	Own = {
		RookHaymaker = { Beat = "Haymaker" },
		KirraScarfStep = { Beat = "ScarfStep" },
		PipLanternBurst = { Beat = "LanternBurst" },
		WattGroundWire = { Beat = "GroundWire" },
		LyricHeldNote = { Beat = "HeldNote", At = "Note" }, -- once, as the note begins: its crests come a quarter second apart
		PipCombo = { Beat = "MageShot", Contact = "MageHit" },
		LyricCombo = { Beat = "HealerShot", Contact = "HealerHit" },
		RookCombo = { Contact = "RookHit" },
		KirraCombo = { Contact = "KirraHit" },
		WattCombo = { Contact = "WattHit" },
	} :: { [string]: { Beat: string?, At: string?, Contact: string? } },
	Arrangements = {} :: { [string]: { [string]: Cue } },
	-- AR39, the A/B at matched level (research, 2026-11-17): while On, an arrangement plays Db louder, so it meets its old
	-- cue's short-term loudness. Db is CueCheck's Match, measured on the mix with this off, and is measured again after
	-- every round. For the listen only: the level that ships is gate 4's. NL_Debug:Invoke("Tune", "Cues.Match.On", false).
	Match = { On = true, Db = {} :: { [string]: { [string]: number } } },
	-- TR64's big moments: cues the game plays by name at their moment (Cues.Moment), never by a hit's rules, each silent
	-- until the director's ear picks its sound. Written below with the others.
	Moments = { "LevelUp", "ShardDrop", "KeeperFall", "LeadDown", "GoalDone", "Record", "Reinforced", "ReinforceFailed", "MachineStage", "LeadHurt", "BroadcastPlate" },
	Front = 12, -- studs in front of the camera a moment's cue (and the panel's tap) plays from: inside every cue's Near, never on the listener (8.5 dB down there, AR39)
	-- A shard's drop note by its grade, as playback speeds (TR64's note set, A C D E): G and the octave stay the reveal's,
	-- so a drop never sounds like a Legendary. A grade not here (a starter's) plays the Standard's.
	Notes = { Standard = 1, Enriched = 1.189, Prismatic = 1.335, Named = 1.498 } :: { [string]: number },
}

-- TR42's second round: each own cue (Own) as what played in its place before, a copy of its layers, so a change to one
-- never reaches the other: the heavy wind-up for a signature's beat, the light hit for a ranged M1's touch, and nothing
-- for a ranged M1's cast or the held note, which had no sound of their own.
local function before(from: Cue?, voices: number): Cue
	local layers: { Layer } = {}
	for _, layer in if from then from.Layers else {} do
		table.insert(layers, table.clone(layer))
	end
	return {
		Layers = layers,
		Bus = "Lead",
		Pitch = if from then table.clone(from.Pitch) else { 0.97, 1.03 },
		Volume = if from then table.clone(from.Volume) else { 0.9, 1 },
		Voices = voices,
		Near = 30,
		Range = 160,
	}
end
do
	local cues = Config.Cues
	cues.Haymaker = before(cues.HeavyWind, 2)
	cues.ScarfStep = before(cues.HeavyWind, 2)
	cues.LanternBurst = before(cues.HeavyWind, 2)
	cues.GroundWire = before(cues.HeavyWind, 2)
	cues.HeldNote = before(nil, 2)
	cues.MageShot = before(nil, 3)
	cues.MageHit = before(cues.LightHit, 4)
	cues.HealerShot = before(nil, 3)
	cues.HealerHit = before(cues.LightHit, 4)
	cues.RookHit = before(cues.LightHit, 4)
	cues.KirraHit = before(cues.LightHit, 4)
	cues.WattHit = before(cues.LightHit, 4)
	-- TR64's big moments (Moments; docs/test-requests.md, TR64), silent, so the listening panel has their tabs. On the
	-- lead's bus: each is the player's own.
	cues.LevelUp = before(nil, 1)
	cues.ShardDrop = before(nil, 3)
	cues.KeeperFall = before(nil, 1)
	cues.LeadDown = before(nil, 1)
	cues.GoalDone = before(nil, 1)
	cues.Record = before(nil, 1)
	cues.Reinforced = before(nil, 1)
	cues.ReinforceFailed = before(nil, 1)
	cues.MachineStage = before(nil, 2)
	cues.LeadHurt = before(nil, 2)
	cues.BroadcastPlate = before(nil, 1) -- TR57's plate: someone else's find, on its fade-in (Rules.Broadcast.Chimes)
end

-- An arrangement of a pilot: its own layers, and its pilot's bus, spreads, voices and reach.
local function like(pilot: Cue, layers: { Layer }): Cue
	return { Layers = layers, Bus = pilot.Bus, Pitch = pilot.Pitch, Volume = pilot.Volume, Voices = pilot.Voices, Near = pilot.Near, Range = pilot.Range }
end

-- Round 1 (Modulo's recipes, docs/asset-requests.md, AR39, "Round 1"; build/handoff/Audio/ar39/round1.luau at 4d31e29):
-- every slice a licensed library recording's (docs/asset-log.md), every level a seed, unheard.
-- AR39's arrangements: begin
Config.Arrangements.LightHit = {
	-- one recorded contact, nothing else: a slap of skin or cloth carries the hit whole, in the band a phone keeps.
	A1 = like(Config.Cues.LightHit, {
		{ Takes = "LibContact", At = 0, Volume = 0.359 }, -- body
	}),
	-- a recorded contact with recorded weight under it from a second recording. Our spark is gone.
	A3 = like(Config.Cues.LightHit, {
		{ Takes = "LibContact", At = 0, Volume = 0.313 }, -- body
		{ Takes = "LibLow", At = 0, Volume = 0.126 }, -- weight
	}),
	-- a recorded contact with a clap's crack laid on its edge: the transient from one recording, the body from another.
	A4 = like(Config.Cues.LightHit, {
		{ Takes = "LibContact", At = 0, Volume = 0.328 }, -- body
		{ Takes = "LibSnap", At = 0, Volume = 0.128 }, -- attack
	}),
}
Config.Arrangements.HeavyHit = {
	-- one recorded heavy body, and a deep glove thump from a second recording under it for the weight, where our sub was.
	B1 = like(Config.Cues.HeavyHit, {
		{ Takes = "LibHeavyBody", At = 0, Volume = 0.639 }, -- body
		{ Takes = "LibLowLong", At = 0, Volume = 0.167 }, -- weight
	}),
	-- two recordings: a deep glove thump for the weight, and the light hit's own contact over it, so a heavy hit is a light one with a body behind it.
	B2 = like(Config.Cues.HeavyHit, {
		{ Takes = "LibLowLong", At = 0, Volume = 0.304 }, -- weight
		{ Takes = "LibContact", At = 0, Volume = 0.426 }, -- attack
	}),
	-- three recordings stacked: a heavy body, a leather or clap snap on its edge, and a deep thump under both.
	B3 = like(Config.Cues.HeavyHit, {
		{ Takes = "LibHeavyBody", At = 0, Volume = 0.595 }, -- body
		{ Takes = "LibHeavySnap", At = 0, Volume = 0.379 }, -- attack
		{ Takes = "LibLowLong", At = 0, Volume = 0.147 }, -- weight
	}),
}
Config.Arrangements.ShadeSwipe = {
	-- paper's flick for the tell, a pass through the air for the swipe.
	C1 = like(Config.Cues.ShadeSwipe, {
		{ Takes = "LibFlick", At = -0.2, Lead = "Peak", Volume = 0.16 }, -- tell
		{ Takes = "LibAir", At = 0, Lead = "Peak", Volume = 0.2 }, -- body
	}),
	-- a paper-edged pass: paper's flick for the tell, then the air's pass with a sheet's rustle riding its top.
	C2 = like(Config.Cues.ShadeSwipe, {
		{ Takes = "LibFlick", At = -0.2, Lead = "Peak", Volume = 0.147 }, -- tell
		{ Takes = "LibAir", At = 0, Lead = "Peak", Volume = 0.174 }, -- body
		{ Takes = "LibRustle", At = 0, Lead = "Peak", Volume = 0.233 }, -- character
	}),
	-- the paper drawn back, then the pass: a longer rustle ending in its flick for the tell, and the recorded pass alone.
	C3 = like(Config.Cues.ShadeSwipe, {
		{ Takes = "LibRustle", At = -0.2, Lead = "Peak", Volume = 0.216 }, -- tell
		{ Takes = "LibAir", At = 0, Lead = "Peak", Volume = 0.191 }, -- body
	}),
}
-- AR39's arrangements: end
-- AR39's match: begin (CueCheck's Match for the arrangements above, dB)
Config.Match.Db = {
	LightHit = { A1 = 9.72, A3 = 9.62, A4 = 9.65 },
	HeavyHit = { B1 = 14.34, B2 = 14.46, B3 = 14.49 },
	ShadeSwipe = { C1 = 22.23, C2 = 22.22, C3 = 22.22 },
}
-- AR39's match: end

return Config
