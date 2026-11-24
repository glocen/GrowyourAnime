--!strict
-- Audition (shared Config): the sound audition panel's numbers (docs/test-requests.md, TR42). Studio only: the director
-- taps finished library sounds in a fight, and the one that's right is kept. The finder (tools/studio/Audio/Audition,
-- in Edit) searches on Words, leaves out what can't be a candidate, measures the rest, and hands them to the playtest;
-- the panel (client, Core/AuditionController) plays them on the fight's own cues. Tuned live:
-- NL_Debug:Invoke("Tune", "Audition.Levels.HeavyHit", 5).

export type Spec = { Name: string, Label: string, Max: number, Beat: boolean, Done: boolean?, Keeps: string?, Tonal: boolean?, Words: { string } }

return {
	-- The pilots, in the panel's order, each with its tab's name, its search words (finished sounds, never a recording of
	-- an object), and the longest its first event may play, s. A beat's cue (Beat) is started ahead by its top on its
	-- attacker's clock; the others play on the touch. Done: picked, so the finder and the panel pass it by, and Others
	-- silences it with the rest. The first round's words are research's (TR42, "Research's search words"); the second
	-- round's, the launch five's signatures and the ranged M1s (the director, 2026-11-19), the builder's, each from its
	-- action's look (Definitions.Actions; Config.Cues.Own says where each plays). Keeps: its candidates are that picked
	-- cue's own takes, not the library's (research's read of the second round: the light hits split by fighter, 4 to 6
	-- each, by the director's ear). Tonal: a single tone or chime is what it wants, so a title's "music" or "musical"
	-- doesn't leave it out; a tune's own words still do (research, the same read).
	Cues = {
		{ Name = "LightHit", Label = "Light hit", Max = 0.7, Beat = false, Done = true, Words = { "punch", "punch hit", "melee hit", "hit impact", "kick hit", "combat hit" } },
		{ Name = "HeavyHit", Label = "Heavy hit", Max = 1.5, Beat = false, Done = true, Words = { "heavy punch", "heavy hit", "strong impact", "power hit", "smash impact", "slam" } },
		{ Name = "ShadeSwipe", Label = "Shade swipe", Max = 1.0, Beat = true, Done = true, Words = { "sword swing", "slash", "swoosh", "claw swipe", "swing whoosh" } },
		-- Rook's Haymaker: the wound-up punch, its top on the strike
		{ Name = "Haymaker", Label = "Haymaker", Max = 1.5, Beat = true, Words = { "power punch", "punch whoosh", "shockwave", "impact boom", "ground pound", "punch swing" } },
		-- Kirra's Scarf Step: the blink in and the cut, its top on the cut
		{ Name = "ScarfStep", Label = "Scarf Step", Max = 0.8, Beat = true, Words = { "dash whoosh", "teleport whoosh", "quick slash", "blade swoosh", "vanish", "swift slash" } },
		-- Pip's Lantern Burst: the flame bursting at the Shades' feet, its top on the burst
		{ Name = "LanternBurst", Label = "Lantern Burst", Max = 1.6, Beat = true, Words = { "fire explosion", "fire burst", "fireball explosion", "flame burst", "flame whoosh", "magic explosion" } },
		-- Watt's Ground Wire: the wire planted, the shock round him, its top on the plant
		{ Name = "GroundWire", Label = "Ground Wire", Max = 1.5, Beat = true, Words = { "electric shock", "electric zap", "lightning strike", "electricity burst", "thunder impact", "shock wave" } },
		-- Lyric's Held Note: the note sweeping out, once as it begins
		{ Name = "HeldNote", Label = "Held Note", Max = 1.6, Beat = true, Tonal = true, Words = { "sonic wave", "sound wave", "magic chime", "energy wave", "sonic blast", "resonance" } },
		-- The basic attack's sound, one per class, shared by every Voidkin of the class (the director, 2026-11-23: "1 type
		-- of sfx for m1 per class"; it replaced the M1's own sound per Voidkin, and with it research's "a Mage of another
		-- element gets cues of its own" of 2026-11-19). So a class's words name no element: the element is the effect's.
		-- At launch each class has one Voidkin, whose combo plays its class's cue (Config.Cues.Own). Sonus, 2026-11-24.
		-- the Mage's (Pip's lantern shots today): the cast on its beat, then the touch on the Shade
		{ Name = "MageShot", Label = "Mage cast", Max = 0.6, Beat = true, Words = { "magic shot", "spell cast", "magic projectile", "energy blast", "spell shoot", "magic whoosh" } },
		{ Name = "MageHit", Label = "Mage hit", Max = 0.7, Beat = false, Words = { "magic hit", "spell impact", "magic impact", "spell hit", "energy impact", "magic burst" } },
		-- the Healer's (Lyric's speaker shots today): the blast on its beat, then the touch
		{ Name = "HealerShot", Label = "Healer cast", Max = 0.6, Beat = true, Tonal = true, Words = { "sonic blast", "energy shot", "magic shot", "pulse", "sonic pulse", "zap shot" } },
		{ Name = "HealerHit", Label = "Healer hit", Max = 0.7, Beat = false, Tonal = true, Words = { "magic hit", "energy hit", "magic impact", "zap hit", "spark hit", "energy impact" } },
		-- the Warrior's (Rook's jab, hook and ram today): fists, so the light hit's 32 keeps
		{ Name = "RookHit", Label = "Warrior's hits", Max = 0.7, Beat = false, Keeps = "LightHit", Words = {} },
		-- the Assassin's (Kirra's three cuts today): two short blades, so a cut, never a punch
		{ Name = "KirraHit", Label = "Assassin's cuts", Max = 0.6, Beat = false, Words = { "sword slash", "blade slash", "katana slash", "slash hit", "sword hit", "blade cut" } },
		-- the Tank's (Watt's shaft, butt and driven spear today): heavy and short, a weighted blow
		{ Name = "WattHit", Label = "Tank's blows", Max = 0.8, Beat = false, Words = { "heavy impact", "blunt impact", "heavy strike", "heavy melee hit", "impact thud", "body impact" } },
	} :: { Spec },
	Pages = 2, -- the library's pages of 25 read a word
	Keep = 50, -- candidates kept a cue, in the library's order (the panel shows ten at a time)
	Page = 10, -- rows a page

	-- The match (TR42, "A fair listen"): every candidate of a cue plays at one short-term loudness, set against today's
	-- LightHit as the finder measured it, by these dB: AR39's gate 4 (HeavyHit 3 to 5 LU over LightHit, ShadeSwipe 3 to 6
	-- under), their middles to start. "Old" plays today's cue as it is. The second round's are the builder's seeds: a
	-- signature's beat a little over a light hit and under the heavy hit it lands with, a cast under the hit it sends.
	Levels = {
		LightHit = 0,
		HeavyHit = 4,
		ShadeSwipe = -4.5,
		Haymaker = 2,
		ScarfStep = -1,
		LanternBurst = 3,
		GroundWire = 2,
		HeldNote = 0,
		MageShot = -4,
		MageHit = -1,
		HealerShot = -4,
		HealerHit = -2,
		RookHit = 0, -- the light hit's own level, as the keeps were heard
		KirraHit = -1, -- a cut a little under a punch; the Tank's blow between the light hit and the heavy (Sonus's seeds)
		WattHit = 2,
	},
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
