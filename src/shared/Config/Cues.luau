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
-- faded in over In and out over Out, s, so its edges never click.
export type Take = { Id: number, Seconds: number, Peak: number, From: number?, To: number?, In: number?, Out: number? }
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

return {
	Volume = 1, -- every cue's fader
	-- Roblox doubled an AudioPlayer's volume in 2025 (docs/research/sound.md, "The engine, for Faber", the level trap): this
	-- takes it back, so a cue's Volume means what a Sound's does, beside Config.Sounds' cues.
	Trim = 0.5,
	-- On the player's own lead's hit, the Shades' bus goes down by Db at once, holds, and comes back over Release (AR13: "the
	-- Shade's sounds and the ambience drop 3 to 4 dB for 150 ms").
	Duck = { Db = -3.5, Hold = 0.15, Release = 0.05 },
	-- A layer's start is handed to the mixer's clock this long before it, s (AR39). A start the mixer holds can't be
	-- taken back (FighterController/Cues), so this is also the longest a stopped voice waits before it plays again.
	Lookahead = 0.05,
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
}
