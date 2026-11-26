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
		-- Each signature: one finished sound of its own, never a stack, simple and very appealing, an anime game's first in
		-- its words (the director, 2026-11-24, "One each", through research).
		-- Rook's Haymaker: the wound-up punch, its top on the strike
		{ Name = "Haymaker", Label = "Haymaker", Max = 1.5, Beat = true, Words = { "anime punch", "anime power punch", "anime shockwave", "power punch", "shockwave", "impact boom" } },
		-- Kirra's Scarf Step: the blink in and the cut, its top on the cut
		-- "anime dash slash" and "anime quick slash" found UI sounds and ripped game files on 2026-11-25: 4 of 20 usable
		{ Name = "ScarfStep", Label = "Scarf Step", Max = 0.8, Beat = true, Words = { "anime dash", "anime teleport", "dash slash", "dash whoosh", "quick dash", "blink whoosh" } },
		-- Pip's Lantern Burst: the flame bursting at the Shades' feet, its top on the burst
		{ Name = "LanternBurst", Label = "Lantern Burst", Max = 1.6, Beat = true, Words = { "anime fire explosion", "anime explosion", "fire burst", "fire explosion", "flame burst", "magic explosion" } },
		-- Watt's Ground Wire: the wire planted, the shock round him, its top on the plant
		{ Name = "GroundWire", Label = "Ground Wire", Max = 1.5, Beat = true, Words = { "anime lightning", "anime electric", "lightning strike", "electric shock", "electricity burst", "thunder impact" } },
		-- Lyric's Held Note: the note sweeping out, once as it begins
		{ Name = "HeldNote", Label = "Held Note", Max = 1.6, Beat = true, Tonal = true, Words = { "anime magic wave", "anime energy wave", "sonic wave", "magic chime", "energy wave", "sound wave" } },
		-- The basic attack's sound, one per class, shared by every Voidkin of the class (the director, 2026-11-23: "1 type
		-- of sfx for m1 per class"; it replaced the M1's own sound per Voidkin, and with it research's "a Mage of another
		-- element gets cues of its own" of 2026-11-19). So a class's words name no element: the element is the effect's.
		-- At launch each class has one Voidkin, whose combo plays its class's cue (Config.Cues.Own). Sonus, 2026-11-24.
		-- Simple and pleasant, "very very appealing, like anime vanguard type" (the director, 2026-11-24): one finished sound
		-- a class, never one a weapon, so an anime game's crisp, bright hit leads each class's words, a real recording after.
		-- the Mage's (Pip's lantern shots today): the cast on its beat, then the touch on the Shade
		-- a cast may run 0.8 s: at 0.6 the run of 2026-11-25 left 271 of 275 out as too long, 4 kept
		{ Name = "MageShot", Label = "Mage cast", Max = 0.8, Beat = true, Words = { "anime magic shot", "anime energy blast", "magic shot", "spell cast", "energy blast", "magic whoosh" } },
		{ Name = "MageHit", Label = "Mage hit", Max = 0.7, Beat = false, Words = { "anime magic hit", "anime impact", "magic hit", "magic impact", "spell impact", "energy impact" } },
		-- the Healer's (Lyric's speaker shots today): the blast on its beat, then the touch
		-- 2026-11-25: "sonic" found 14 music clips under made-up titles; "pulse shot" and "chime shot" found guns and a
		-- jet's radar beeps. So a bright sparkle or chime that flies, and "magic shot" stays the Mage's own. 2026-11-26:
		-- these words kept 5 of 257 at 0.8 s, the rest ringing on; "short sparkle" and "short chime" found car chimes, a
		-- train whistle and menu clicks. So 1.2 s: a sparkle rings far under its top, and the shots overlap at 0.25 s anyway
		{ Name = "HealerShot", Label = "Healer cast", Max = 1.2, Beat = true, Tonal = true, Words = { "anime sparkle", "magic sparkle", "sparkle whoosh", "chime whoosh", "fairy magic", "light magic" } },
		-- no "magic hit" or "energy impact": they're the Mage's words, and on 2026-11-25 they gave the two tabs the same sounds
		{ Name = "HealerHit", Label = "Healer hit", Max = 0.7, Beat = false, Tonal = true, Words = { "anime energy hit", "anime spark hit", "chime hit", "sparkle hit", "energy hit", "spark hit" } },
		-- the Warrior's (Rook's jab, hook and ram today): fists, so the light hit's 32 keeps
		{ Name = "RookHit", Label = "Warrior's hits", Max = 0.7, Beat = false, Keeps = "LightHit", Words = {} },
		-- the Assassin's (Kirra's three cuts today): a quick cut, never a punch
		{ Name = "KirraHit", Label = "Assassin's cuts", Max = 0.7, Beat = false, Words = { "anime slash", "anime sword slash", "slash hit", "sword slash", "katana slash", "blade slash" } },
		-- the Tank's (Watt's shaft, butt and driven spear today): heavy and short, a weighted blow, never harsh
		{ Name = "WattHit", Label = "Tank's blows", Max = 0.8, Beat = false, Words = { "anime heavy hit", "anime impact", "heavy hit", "heavy impact", "heavy strike", "blunt impact" } },
		-- The silent big moments (docs/test-requests.md, TR64: each cue's moment, longest and never in its tables; research's
		-- words, 2026-11-26). Each plays on its moment, not on a fighter's beat, so Beat here only says how it's measured:
		-- whole, its rise kept (a chime, a charge), or cut to its top (KeeperFall and LeadHurt, impacts on their frame). The
		-- moment's hook (Faber's) says when it starts. Round 1, the first session's:
		{ Name = "LevelUp", Label = "Level up", Max = 1.0, Beat = true, Tonal = true, Words = { "level up", "power up chime", "achievement chime", "magic chime", "rising chime" } },
		-- one note, pitched by grade in the game (A C D E), so it's found and heard at its own pitch. 1.0 s, not TR64's 0.6:
		-- the finder's event runs until the ring is 45 dB down, so at 0.6 "crystal ding" and "sparkle ding" kept none and the
		-- tab 4 by title on 2026-11-26 (the Healer's cast showed the same)
		{ Name = "ShardDrop", Label = "Shard drop", Max = 1.0, Beat = true, Tonal = true, Words = { "crystal ding", "glass chime", "bell ding", "chime single", "sparkle ding" } },
		-- research's five kept 4 by title on 2026-11-26 (the rest splashes, a pack's numbered files, other works), so three
		-- shatter words of the glass family
		{ Name = "KeeperFall", Label = "Keeper's fall", Max = 2.0, Beat = false, Words = { "boss defeated", "victory impact", "gong hit", "big impact", "shatter", "crystal shatter", "magic shatter", "anime shatter" } },
		{ Name = "LeadDown", Label = "Lead down", Max = 1.5, Beat = true, Words = { "defeat", "power down", "fail", "lose", "shutdown" } },
		-- Round 2 (Record heard right after GoalDone; LeadHurt last, an impact that repeats):
		-- no "achievement": on 2026-11-26 it found Steam's, Xbox's and consoles' sounds, and the tab kept 3 by title
		{ Name = "GoalDone", Label = "Goal done", Max = 0.8, Beat = true, Tonal = true, Words = { "quest complete", "goal complete", "mission complete", "objective complete", "success chime", "task complete", "bell chime" } },
		{ Name = "Record", Label = "New record", Max = 1.0, Beat = true, Tonal = true, Words = { "new record", "achievement unlocked", "victory chime", "success" } },
		{ Name = "Reinforced", Label = "Reinforced", Max = 0.8, Beat = true, Tonal = true, Words = { "upgrade", "enchant", "forge success", "power up chime" } },
		{ Name = "ReinforceFailed", Label = "Reinforce failed", Max = 0.6, Beat = true, Words = { "fail", "error low", "crack", "negative" } },
		{ Name = "MachineStage", Label = "Machine stage", Max = 1.5, Beat = true, Words = { "power up", "charge up", "energy rise", "magic charge" } },
		{ Name = "LeadHurt", Label = "Lead hurt", Max = 0.4, Beat = false, Words = { "body hit", "low impact", "damage hit", "thud" } },
	} :: { Spec },
	Pages = 2, -- the library's pages of 25 read a word
	Keep = 20, -- candidates kept a cue, in the library's order (the panel shows ten at a time); 20 since 2026-11-25, Sonus
	-- cuts each to five to eight by title before the listen (docs/briefs/sound.md), and a run of eleven tabs stays short
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
		-- TR64's, from the study's mix chart (docs/research/cloud-2026-11-24/audio-direction.md, "The mix chart"): a reward
		-- -6, the UI -12, the Shades' hurt -4; the keeper's fall over a Shade's burst, at a light hit's
		LevelUp = -6,
		ShardDrop = -6,
		KeeperFall = 0,
		LeadDown = -6,
		GoalDone = -6,
		Record = -6,
		Reinforced = -6,
		ReinforceFailed = -12,
		MachineStage = -6,
		LeadHurt = -4,
	},
	Ceiling = -1, -- dBTP: a candidate's top at its matched level stays under it, so the bus's limiter takes 0 dB

	-- The head (TR42, "On the hit"): a contact's top lands within Top of its start; the cut falls on the quietest sample
	-- in reach, so it never clicks. A swipe keeps its whole rise, started ahead by the engine (Lead "Peak").
	Top = 0.008,
	Tail = 0.02, -- s kept past the first event's end, then faded over it when the file goes on
	Gap = 0.08, -- s of quiet that end the first event (tools/studio/Audio/Waveform's split)
	Floor = -45, -- dB under the read's loudest that count as quiet
	Event = -20, -- dB: the first event is the first whose top comes within this of the loudest; quieter noise before it is cut
}
