--!strict
-- Audition (shared Config): the sound audition panel's numbers (docs/test-requests.md, TR42). Studio only: the director
-- taps finished library sounds in a fight, and the one that's right is kept. The finder (tools/studio/Audio/Audition,
-- in Edit) searches on Words, leaves out what can't be a candidate, measures the rest, and hands them to the playtest;
-- the panel (client, Core/AuditionController) plays them on the fight's own cues. Tuned live:
-- NL_Debug:Invoke("Tune", "Audition.Levels.HeavyHit", 5).

return {
	-- The pilots, in the panel's order, each with its tab's name, research's search words (TR42, "Research's search
	-- words": finished sounds, never a recording of an object), and the longest its first event may play, s. A beat's
	-- cue (Beat) is started ahead by its top on its attacker's clock; the others play on the touch.
	Cues = {
		{ Name = "LightHit", Label = "Light hit", Max = 0.7, Beat = false, Words = { "punch", "punch hit", "melee hit", "hit impact", "kick hit", "combat hit" } },
		{ Name = "HeavyHit", Label = "Heavy hit", Max = 1.5, Beat = false, Words = { "heavy punch", "heavy hit", "strong impact", "power hit", "smash impact", "slam" } },
		{ Name = "ShadeSwipe", Label = "Shade swipe", Max = 1.0, Beat = true, Words = { "sword swing", "slash", "swoosh", "claw swipe", "swing whoosh" } },
	},
	Pages = 2, -- the library's pages of 25 read a word
	Keep = 50, -- candidates kept a cue, in the library's order (the panel shows ten at a time)
	Page = 10, -- rows a page

	-- The match (TR42, "A fair listen"): every candidate of a cue plays at one short-term loudness, set against today's
	-- LightHit as the finder measured it, by these dB: AR39's gate 4 (HeavyHit 3 to 5 LU over LightHit, ShadeSwipe 3 to 6
	-- under), their middles to start. "Old" plays today's cue as it is.
	Levels = { LightHit = 0, HeavyHit = 4, ShadeSwipe = -4.5 },
	Ceiling = -1, -- dBTP: a candidate's top at its matched level stays under it, so the bus's limiter takes 0 dB

	-- The head (TR42, "On the hit"): a contact's top lands within Top of its start; the cut falls on the quietest sample
	-- in reach, so it never clicks. A swipe keeps its whole rise, started ahead by the engine (Lead "Peak").
	Top = 0.008,
	Tail = 0.02, -- s kept past the first event's end, then faded over it when the file goes on
	Gap = 0.08, -- s of quiet that end the first event (tools/studio/Audio/Waveform's split)
	Floor = -45, -- dB under the read's loudest that count as quiet
	Event = -20, -- dB: the first event is the first whose top comes within this of the loudest; quieter noise before it is cut
	Preview = 12, -- studs in front of the camera a tap's play is heard from: inside every cue's Near, never on the listener
}
