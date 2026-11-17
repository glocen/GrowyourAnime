-- AR39, round2: Modulo's arrangements (tools/audio/ar39_arrange.py). Seeds, unheard. Gain is new: a library
-- take's own level inside its list, times its layer's Volume. Our lists stay as Config.Cues has them.
Takes = {
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
},
Cues = {
	-- one recorded contact, nothing else: a slap of skin or cloth carries the hit whole, in the band a phone keeps.
	LightHit_A1 = { Layers = {
		{ Takes = "LibContact", At = 0, Volume = 0.359 }, -- body
	} },
	-- a recorded contact with recorded weight under it from a second recording. Our spark is gone.
	LightHit_A3 = { Layers = {
		{ Takes = "LibContact", At = 0, Volume = 0.313 }, -- body
		{ Takes = "LibLow", At = 0, Volume = 0.126 }, -- weight
	} },
	-- a recorded contact with a clap's crack laid on its edge: the transient from one recording, the body from another.
	LightHit_A4 = { Layers = {
		{ Takes = "LibContact", At = 0, Volume = 0.328 }, -- body
		{ Takes = "LibSnap", At = 0, Volume = 0.128 }, -- attack
	} },
	-- one recorded heavy body, and a deep glove thump from a second recording under it for the weight, where our sub was.
	HeavyHit_B1 = { Layers = {
		{ Takes = "LibHeavyBody", At = 0, Volume = 0.639 }, -- body
		{ Takes = "LibLowLong", At = 0, Volume = 0.167 }, -- weight
	} },
	-- two recordings: a deep glove thump for the weight, and the light hit's own contact over it, so a heavy hit is a light one with a body behind it.
	HeavyHit_B2 = { Layers = {
		{ Takes = "LibLowLong", At = 0, Volume = 0.304 }, -- weight
		{ Takes = "LibContact", At = 0, Volume = 0.426 }, -- attack
	} },
	-- three recordings stacked: a heavy body, a leather or clap snap on its edge, and a deep thump under both.
	HeavyHit_B3 = { Layers = {
		{ Takes = "LibHeavyBody", At = 0, Volume = 0.595 }, -- body
		{ Takes = "LibHeavySnap", At = 0, Volume = 0.379 }, -- attack
		{ Takes = "LibLowLong", At = 0, Volume = 0.147 }, -- weight
	} },
	-- paper's flick for the tell, a pass through the air for the swipe.
	ShadeSwipe_C1 = { Layers = {
		{ Takes = "LibFlick", At = -0.2, Lead = "Peak", Volume = 0.16 }, -- tell
		{ Takes = "LibAir", At = 0, Lead = "Peak", Volume = 0.2 }, -- body
	} },
	-- a paper-edged pass: paper's flick for the tell, then the air's pass with a sheet's rustle riding its top.
	ShadeSwipe_C2 = { Layers = {
		{ Takes = "LibFlick", At = -0.2, Lead = "Peak", Volume = 0.147 }, -- tell
		{ Takes = "LibAir", At = 0, Lead = "Peak", Volume = 0.174 }, -- body
		{ Takes = "LibRustle", At = 0, Lead = "Peak", Volume = 0.233 }, -- character
	} },
	-- the paper drawn back, then the pass: a longer rustle ending in its flick for the tell, and the recorded pass alone.
	ShadeSwipe_C3 = { Layers = {
		{ Takes = "LibRustle", At = -0.2, Lead = "Peak", Volume = 0.216 }, -- tell
		{ Takes = "LibAir", At = 0, Lead = "Peak", Volume = 0.191 }, -- body
	} },
},
