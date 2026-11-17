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
	-- the only one inside a layer.
	Takes = {
		ShadeTell = {
			{ Id = 97312586605765, Seconds = 0.25, Peak = 0.1956 }, -- ShadeTell_1
			{ Id = 137300621783110, Seconds = 0.25, Peak = 0.1924 }, -- ShadeTell_2
			{ Id = 103776257086025, Seconds = 0.25, Peak = 0.1871 }, -- ShadeTell_3
		},
		ShadeSwipe = {
			{ Id = 94311601578482, Seconds = 0.32, Peak = 0.2070 }, -- ShadeSwipe_1
			{ Id = 125055624173226, Seconds = 0.32, Peak = 0.1690 }, -- ShadeSwipe_2
			{ Id = 88090019338072, Seconds = 0.32, Peak = 0.2241 }, -- ShadeSwipe_3
		},
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
		LightHitSpark = {
			{ Id = 75782635990998, Seconds = 0.1, Peak = 0.0013 }, -- LightHitSpark_1
			{ Id = 86552286887294, Seconds = 0.11, Peak = 0.0013 }, -- LightHitSpark_2
			{ Id = 119152742564388, Seconds = 0.095, Peak = 0.0015 }, -- LightHitSpark_3
			{ Id = 82434748319026, Seconds = 0.105, Peak = 0.0016 }, -- LightHitSpark_4
			{ Id = 129008793593363, Seconds = 0.1, Peak = 0.0018 }, -- LightHitSpark_5
		},
		HeavyRiser = {
			{ Id = 97515716318295, Seconds = 0.18, Peak = 0.1720 }, -- HeavyRiser_1
			{ Id = 114077736762662, Seconds = 0.15, Peak = 0.1415 }, -- HeavyRiser_2
			{ Id = 132895683656890, Seconds = 0.2, Peak = 0.1902 }, -- HeavyRiser_3
		},
		HeavySub = {
			{ Id = 131024884243061, Seconds = 0.42, Peak = 0.0070 }, -- HeavySub_1
			{ Id = 120793628140783, Seconds = 0.36, Peak = 0.0065 }, -- HeavySub_2
			{ Id = 107728705766262, Seconds = 0.48, Peak = 0.0075 }, -- HeavySub_3
		},
		HeavyImpacts = {
			{ Id = 76017942066366, Seconds = 0.205, Peak = 0.0018 }, -- HeavyImpacts_1
			{ Id = 81050093874356, Seconds = 0.183, Peak = 0.0031 }, -- HeavyImpacts_2
			{ Id = 125931756554986, Seconds = 0.251, Peak = 0.0017 }, -- HeavyImpacts_3
		},
		HeavyTail = {
			{ Id = 133486795651631, Seconds = 0.7, Peak = 0.0177 }, -- HeavyTail_1
			{ Id = 103173593979012, Seconds = 0.7, Peak = 0.0308 }, -- HeavyTail_2
			{ Id = 81041412529438, Seconds = 0.7, Peak = 0.0230 }, -- HeavyTail_3
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
	} :: { [string]: { Take } },

	Cues = {
		-- 1. A Shade's swipe, on its clock, landed or not: the tell rising from the wind-up, then the whoosh topping on the
		-- hit. Quieter than the lead's hits. Library layers (paper rustle, paper-edged whoosh) wait on the shortlist.
		ShadeSwipe = {
			Layers = {
				{ Takes = "ShadeTell", At = -0.2, Volume = 0.25 }, -- about a third of the swipe's (Modulo's seed)
				{ Takes = "ShadeSwipe", At = 0, Lead = "Peak", Volume = 0.7 },
			},
			Bus = "Shade",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
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
		-- 4. A light hit, on the touch: the spark tick an octave lower. No sub: it stays fast. Its library snap and body wait
		-- on the shortlist.
		LightHit = {
			Layers = { { Takes = "LightHitSpark", At = 0, Volume = 1 } },
			Bus = "Lead",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
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
		-- 5b. A heavy hit, on the touch: the sub, the micro-impacts and the tail by the hit's strength. The library's body is
		-- the strike's own cue where it has one (Haymaker's, Config.Sounds).
		HeavyHit = {
			Layers = {
				{ Takes = "HeavySub", At = 0, Volume = 1 },
				{ Takes = "HeavyImpacts", At = 0, Volume = 0.9 },
				{ Takes = "HeavyTail", At = 0, Volume = 0.7, Strength = true },
			},
			Bus = "Lead",
			Pitch = { 0.92, 1.08 },
			Volume = { 0.85, 1 },
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
	Use = { LightHit = "Old", HeavyHit = "Old", ShadeSwipe = "Old" },
	Arrangements = {} :: { [string]: { [string]: Cue } },
	-- AR39, the A/B at matched level (research, 2026-11-17): while On, an arrangement plays Db louder, so it meets its old
	-- cue's short-term loudness. Db is CueCheck's Match, measured on the mix with this off, and is measured again after
	-- every round. For the listen only: the level that ships is gate 4's. NL_Debug:Invoke("Tune", "Cues.Match.On", false).
	Match = { On = true, Db = {} :: { [string]: { [string]: number } } },
}

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
