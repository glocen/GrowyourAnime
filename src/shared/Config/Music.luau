--!strict
-- Music (shared Config): the game's music, by where the player is (the director, 2026-11-19: "add a music modular script
-- and tell me where i paste the ID so that we have the music, i will put those myself"). The client's MusicController
-- plays the list of the place the player is in, its tracks one after another in a shuffle, never the same one twice
-- running, and crosses to another list when the player goes somewhere else (Rules.Music). A list left empty is silence
-- there. Every track pasted joins docs/asset-log.md with its id and author, as every sound does (AGENTS.md, rule 2).
-- Tuned live: NL_Debug:Invoke("Tune", "Music.Volume", 0.3).
--
-- HOW TO ADD A TRACK: copy the track's number from its Creator Store page (the digits in the page's address) and paste
-- it between the braces of the place it plays in, a comma after each one. "rbxassetid://..." pasted whole works too.
--     Strip = { Ids = { 1234567890, 2345678901 }, Volume = 1 },
-- Volume beside it sets that place's level against the others: 1 as it is, 0.5 half as loud.

export type List = { Ids: { number | string }, Volume: number }

return {
	Volume = 0.4, -- every track's fader: a Sound's Volume, for a place's Volume of 1
	Fade = 2, -- seconds a change of place crosses from one track to the other over
	Gap = 1.5, -- seconds of quiet between two tracks of the same place
	Load = 8, -- seconds a track has to load in; one that doesn't is skipped, and the place's next one plays
	Lists = {
		-- The Strip: the hub between the plots and the grounds, with the Void Shop. Everywhere none of the others is.
		Strip = { Ids = {}, Volume = 1 },
		-- The player's own plot: the base.
		Base = { Ids = {}, Volume = 1 },
		-- Lantern Row: the festival street north of the Festival Gate, its stages.
		LanternRow = { Ids = {}, Volume = 1 },
		-- A fight with the Lamplighter: a keeper's try, from its start to its end.
		Keeper = { Ids = {}, Volume = 1 },
		-- A Tower run, from its first floor to its results.
		Tower = { Ids = {}, Volume = 1 },
	} :: { [string]: List },
}
