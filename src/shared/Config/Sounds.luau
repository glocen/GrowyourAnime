--!strict
-- Sounds (shared Config): the game's sound cues, slices of Roblox's audio library (AGENTS.md, rule 2; every id and author
-- logged in docs/asset-log.md, so a claimed one is quick to swap). Picked by measure with tools/studio/Audio (Shortlist,
-- Waveform; handbook/visuals/audio.md): a cue is provisional until the director's ear accepts it. Played by the client's
-- FighterController/Sounds, all through one SoundGroup. Tuned live: NL_Debug:Invoke("Tune", "Sounds.Cues.HaymakerStrike.Volume", 1.2).

export type Cue = {
	Id: number, -- the library's asset id
	From: number, -- the slice, seconds into the file
	To: number,
	Level: number, -- the slice's measured loudness, dBFS: each cue is levelled to Reference, so Volume is purely the mix
	Volume: number,
	Pitch: { number }, -- the spread a play picks from, so no two sound alike
	Near: number, -- studs from the listener it plays at full volume within
	Range: number, -- and fades out by; both 0 for a cue that only plays on the screen (Rules.Sound.Screen)
}

return {
	Reference = -14, -- dBFS every cue is levelled to
	Gain = { 0.25, 2 }, -- the levelling's bounds: down is free, up past 2 brings the file's noise with it, so pick a louder source
	Combat = 1, -- the combat group's fader
	Reveal = 1, -- the reveal's group's fader (UI/Reveal; its cues' levels are Config.Reveal.Sounds)

	Cues = {
		-- Rook's Haymaker on the strike (docs/asset-requests.md, AR1, section 7): a hard metal clunk with a short ring, the
		-- iron ram landing. ProSoundEffects' "Metal Impact Heavy Clunking Hits Scraping 3", its third hit.
		HaymakerStrike = {
			Id = 9116673915,
			From = 2.35,
			To = 3.05,
			Level = -5.8,
			Volume = 1,
			Pitch = { 0.96, 1.04 },
			Near = 30,
			Range = 160,
		} :: Cue,

		-- The reveal's (docs/test-requests.md, TR4, research's cues): on the screen, not in the world, so Near and Range are 0
		-- (Rules.Sound.Screen); their levels against each other are Config.Reveal.Sounds. Provisional until the director's ear
		-- accepts them.
		-- a seam cracking: ProSoundEffects' "Glass Breaks 12", its opening snap, dry
		RevealCrack = { Id = 9114592103, From = 0.61, To = 0.86, Level = -20.1, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- a rung of the leak's climb: ProSoundEffects' "Synth Sparkle Tone High Pitch Tone Burst 4", a clean high tone, 40 dB
		-- down by 0.31 s; pitched up a step a rung by the schedule
		RevealRung = { Id = 9119833793, From = 0.03, To = 0.51, Level = -20.7, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- the breath before the split, Epic up: "504_Reverse_Cymbal", a community upload (kyleamida), its last half second
		-- swelling to the peak it ends dead on
		RevealBreath = { Id = 119247066943033, From = 0.9, To = 1.4, Level = -13.5, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- the split, Common to Epic: ProSoundEffects' "Ice Hammer Hitting Large Chunks 13", a glassy pop, its sparkle 40 dB down
		-- by 0.58 s; slower a rarity up (Config.Reveal.Sounds.SplitLow.Speed), so deeper and longer as it climbs
		RevealSplitLow = { Id = 9114865796, From = 0, To = 0.9, Level = -18.4, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- the full burst at the two peaks: ProSoundEffects' "Glass Smashes 3", a bright shatter with body in the mids
		RevealSplitHigh = { Id = 9114614830, From = 0.17, To = 1.71, Level = -14.2, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- the name's stamp: ProSoundEffects' "Metal Ladder Bang Slams Against Body 1", 40 dB down by 0.22 s
		RevealName = { Id = 9116717868, From = 0, To = 0.4, Level = -17.7, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- the light along the rule: ProSoundEffects' "Knife Shing 4"
		RevealGlint = { Id = 9116197039, From = 0, To = 0.23, Level = -21.6, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
		-- the bed from the colours into the card: ProSoundEffects' "Magic Tone Tonal Shimmer Shaking Rattle 3"
		RevealBed = { Id = 9116420454, From = 1, To = 4, Level = -27.7, Volume = 1, Pitch = { 1, 1 }, Near = 0, Range = 0 } :: Cue,
	},
}
