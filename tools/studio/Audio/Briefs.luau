--!strict
-- Briefs: what each sound cue should sound like, so Shortlist can search Roblox's audio library for it and rank what it finds by
-- shape (Waveform) before anyone listens (handbook/visuals/audio.md, "The pipeline"). Studio tool data, not shipped.
--   Brief: the sound in words.
--   Keywords: library searches; wide on purpose (unrelated sounds often hold the perfect slice).
--   Avoid: title words that rule a sound out for this cue (Shortlist adds the global gore, IP and junk words).
--   Prefer: title words that make a sound likelier to fit.
--   Mode: Hit (one burst), Sequence (several bursts), Rise (swells to a late peak), Fall (starts loud and fades), Loop.
--   Slice: how long the cue's slice may last (seconds). Attack: start to peak. Tail: peak to 40 dB down.
--   Bands: the rough energy balance it should have (low: body, thump; high: air, metal, hiss).
--   Events: for a Sequence, how many bursts it should hold. MaxFile: the longest file worth searching (seconds).

export type Brief = {
	Brief: string,
	Keywords: { string },
	Avoid: { string }?,
	Prefer: { string }?,
	Mode: "Hit" | "Sequence" | "Rise" | "Fall" | "Loop",
	Slice: { number },
	Attack: { number },
	Tail: { number },
	Bands: { Low: number, Mid: number, High: number },
	Events: { number }?,
	MaxFile: number?,
}

local briefs: { [string]: Brief } = {
	-- Rook's Haymaker on the strike (docs/asset-requests.md, AR1, section 7): an iron ram driven by a piston into a body.
	-- Weight first: a deep, hard thump with an iron edge, one burst, a short tail; its body above 250 Hz too, for phones.
	HaymakerStrike = {
		Brief = "a heavy iron-gauntlet punch landing: a deep, hard thump with a short metal clank in it, one burst",
		Keywords = {
			"heavy punch", "punch impact", "hard punch", "body hit heavy", "metal impact heavy", "heavy metal hit",
			"hammer hit", "sledgehammer", "anvil hit", "piston slam", "heavy slam", "iron hit", "cannon thump",
			"heavy impact", "impact hit", "body slam", "thud heavy", "punch heavy", "impact metal", "fist hit", "boxing punch",
		},
		Avoid = { "whoosh", "swoosh", "swing", "swish", "miss", "sword", "blade", "glass", "shatter", "explosion", "rain", "door" },
		Prefer = { "punch", "impact", "heavy", "metal", "hit", "slam", "iron", "hammer" },
		Mode = "Hit",
		Slice = { 0.25, 0.7 },
		Attack = { 0, 0.03 },
		Tail = { 0.15, 0.5 },
		Bands = { Low = 0.45, Mid = 0.4, High = 0.15 },
		MaxFile = 4,
	},
	-- The reveal's cues (docs/test-requests.md, TR4, research's sound cues of 2026-11-13). Each one's weight above 250 Hz,
	-- or a phone loses it.
	RevealCrack = {
		Brief = "a dry, short crystal crack, one source: a seam splitting in a shard of glass, no ring after it",
		Keywords = {
			"glass crack", "ice crack", "crystal crack", "glass snap", "ice snap", "crack small", "glass tap", "ice break",
			"crystal break", "glass clink", "crack", "ice cracking", "glass cracking", "stone crack small",
		},
		Avoid = { "whoosh", "swoosh", "explosion", "gun", "shot", "whip", "knuckle", "door", "egg" },
		Prefer = { "crack", "glass", "ice", "crystal", "snap", "small" },
		Mode = "Hit",
		Slice = { 0.06, 0.25 },
		Attack = { 0, 0.01 },
		Tail = { 0.03, 0.2 },
		Bands = { Low = 0.1, Mid = 0.4, High = 0.5 },
		MaxFile = 5,
	},
	RevealRung = {
		Brief = "one clean glass chime, a short tail of about 0.4 s: the shard's light climbing a rung",
		Keywords = {
			"glass chime", "crystal chime", "chime", "glass ding", "glass ping", "wine glass", "small bell", "bell ding",
			"glockenspiel", "triangle", "ding", "chime single", "magic chime", "crystal ding", "ting", "bell tone", "mallet",
			"celesta", "vibraphone", "music box", "glass hit", "sparkle tone", "tone ding",
		},
		Avoid = { "whoosh", "door", "doorbell", "phone", "alarm", "error", "wrong", "fail", "church", "wind chimes" },
		Prefer = { "chime", "glass", "crystal", "ding", "bell", "ping" },
		Mode = "Fall",
		Slice = { 0.3, 0.7 },
		Attack = { 0, 0.02 },
		Tail = { 0.25, 0.6 },
		Bands = { Low = 0.05, Mid = 0.35, High = 0.6 },
		MaxFile = 5,
	},
	RevealBreath = {
		Brief = "an air swell drawn inward, a reversed shimmer rising to its loudest at the end, where it's cut dead",
		Keywords = {
			"reverse shimmer", "reverse cymbal", "reversed cymbal", "riser", "swell", "reverse whoosh", "suck in",
			"magic rise", "reverse wind", "reverse", "uprising", "inhale magic", "reverse sparkle", "build up",
		},
		Avoid = { "music", "song", "loop", "beat", "vocal", "breathing", "sigh" },
		Prefer = { "reverse", "riser", "rise", "swell", "shimmer", "cymbal" },
		Mode = "Rise",
		Slice = { 0.35, 0.9 },
		Attack = { 0.3, 0.9 },
		Tail = { 0, 0.15 },
		Bands = { Low = 0.1, Mid = 0.35, High = 0.55 },
		MaxFile = 6,
	},
	RevealSplitLow = {
		Brief = "a glassy pop with a short sparkle after it, one source: a small shard bursting open",
		Keywords = {
			"glass pop", "magic pop", "crystal pop", "sparkle pop", "pop sparkle", "magic sparkle", "glass burst",
			"ice shatter small", "crystal burst", "twinkle", "magic poof", "glass break small", "pop", "bubble glass",
			"magic hit", "crystal hit", "ice hit", "glass impact", "magic impact", "spell", "magic spell", "ice crystal",
		},
		Avoid = { "gun", "cork", "balloon", "mouth", "lip", "cartoon", "fart", "bubble wrap", "popcorn" },
		Prefer = { "pop", "sparkle", "glass", "magic", "crystal", "burst" },
		Mode = "Hit",
		Slice = { 0.3, 0.9 },
		Attack = { 0, 0.02 },
		Tail = { 0.2, 0.8 },
		Bands = { Low = 0.15, Mid = 0.45, High = 0.4 },
		MaxFile = 5,
	},
	RevealSplitHigh = {
		Brief = "a full burst: a bright crystal shatter over a body in the low mids, its tail about 1.5 s",
		Keywords = {
			"crystal shatter", "glass shatter", "magic explosion", "shatter", "ice shatter", "magic burst", "energy burst",
			"glass break big", "impact shatter", "crystal explosion", "magic impact", "shatter impact", "glass smash",
		},
		Avoid = { "gun", "bomb", "grenade", "nuke", "car", "bottle", "window", "plate", "dish" },
		Prefer = { "shatter", "crystal", "magic", "burst", "glass", "impact" },
		Mode = "Fall",
		Slice = { 1.1, 2.2 },
		Attack = { 0, 0.03 },
		Tail = { 0.9, 2 },
		Bands = { Low = 0.3, Mid = 0.35, High = 0.35 },
		MaxFile = 6,
	},
	RevealName = {
		Brief = "a heavy metal stamp with a short ring, no tail past 0.3 s: the name pressed onto the screen",
		Keywords = {
			"metal stamp", "stamp", "heavy stamp", "metal slam", "anvil", "metal hit", "metal clang", "press stamp",
			"hammer metal", "impact metal", "latch heavy", "metal impact", "stamp press", "machine stamp",
		},
		Avoid = { "glass", "whoosh", "paper", "rubber", "foot", "footstep", "door", "scrape", "scraping" },
		Prefer = { "stamp", "metal", "slam", "anvil", "impact", "press" },
		Mode = "Hit",
		Slice = { 0.15, 0.4 },
		Attack = { 0, 0.01 },
		Tail = { 0.08, 0.3 },
		Bands = { Low = 0.25, Mid = 0.45, High = 0.3 },
		MaxFile = 4,
	},
	RevealGlint = {
		Brief = "a short high shing: light running along a thin metal rule",
		Keywords = {
			"shing", "glint", "sword shing", "blade shing", "metal shing", "sparkle short", "twinkle", "shine", "ting",
			"unsheathe", "knife sharpen", "metal ring short", "sparkle", "glimmer",
		},
		Avoid = { "whoosh", "swing", "swoosh", "hit", "stab", "slash", "loop" },
		Prefer = { "shing", "glint", "shine", "twinkle", "ting", "sparkle" },
		Mode = "Hit",
		Slice = { 0.12, 0.4 },
		Attack = { 0, 0.03 },
		Tail = { 0.08, 0.35 },
		Bands = { Low = 0.02, Mid = 0.28, High = 0.7 },
		MaxFile = 4,
	},
	RevealBed = {
		Brief = "a soft held shimmer pad, no melody and no beat: air and glints under the Voidkin's reveal",
		Keywords = {
			"shimmer pad", "magic shimmer", "ambient shimmer", "shimmer", "sparkle loop", "magic loop", "ethereal pad",
			"ethereal", "celestial", "magic ambience", "drone shimmer", "pad", "glitter", "fairy dust",
		},
		Avoid = { "music", "song", "beat", "melody", "piano", "guitar", "vocal", "choir", "voice", "drum" },
		Prefer = { "shimmer", "pad", "ethereal", "magic", "sparkle", "ambient" },
		Mode = "Loop",
		Slice = { 1.2, 3 },
		Attack = { 0.05, 1 },
		Tail = { 0.2, 2 },
		Bands = { Low = 0.1, Mid = 0.4, High = 0.5 },
		MaxFile = 12,
	},
}

return briefs
