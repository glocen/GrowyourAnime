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
	Range: number, -- and fades out by
}

return {
	Reference = -14, -- dBFS every cue is levelled to
	Gain = { 0.25, 2 }, -- the levelling's bounds: down is free, up past 2 brings the file's noise with it, so pick a louder source
	Combat = 1, -- the combat group's fader

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
	},
}
