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

	-- AR39, the sound rescue's three pilots (docs/asset-requests.md, AR39; the director's directive of 2026-11-17).
	-- Recorded material first: one brief per recorded role, so a pilot's arrangements can be built differently, never as
	-- pitch copies. Searched wide and in one batch: Shortlist.Run(name, { Count = 14, Measure = 80, Pages = 3 }).
	-- The bands' edges are Waveform's, 250 and 2500 Hz, so "Mid" is the body a phone keeps.

	-- A, LightHit: the contact itself, a body or cloth punch. Its body lives from 200 Hz to 2 kHz, it's done inside
	-- 150 ms, and it decays fast and clean, so six in a second stay six hits. One burst, nothing before it.
	LightHitBody = {
		Brief = "a quick, clean punch landing on a body or a padded jacket: a short low-mid thock, one burst, no ring",
		Keywords = {
			"punch", "body punch", "punch impact", "punch hit", "jab", "light punch", "quick punch", "fast punch", "fist punch",
			"fist hit", "cloth punch", "jacket punch", "leather punch", "glove hit", "boxing glove", "boxing punch",
			"martial arts punch", "kung fu punch", "karate punch", "fight punch", "fight hit", "combat hit", "body hit",
			"hit body", "punch foley", "foley punch", "kick hit", "kick impact", "thump", "soft impact", "hand hit",
		},
		Avoid = {
			"whoosh", "swoosh", "swing", "swish", "miss", "sword", "blade", "knife", "glass", "metal", "metallic", "gun",
			"explosion", "heavy", "slam", "bag", "wood", "door", "bell", "rock", "stone", "cinematic", "trailer", "boom",
			"bass", "sub", "reverb", "echo", "rain", "loop",
		},
		Prefer = { "punch", "jab", "body", "cloth", "fist", "foley", "impact", "hit" },
		Mode = "Hit",
		Slice = { 0.06, 0.15 },
		Attack = { 0, 0.008 },
		Tail = { 0.04, 0.12 },
		Bands = { Low = 0.25, Mid = 0.6, High = 0.15 },
		MaxFile = 4,
	},
	-- A and B's attack, when a body's own onset is soft: a crisp leather or cloth snap, a few milliseconds to its top and
	-- gone in 60, laid on a body from another recording. Never the whole hit.
	LightHitSnap = {
		Brief = "a crisp leather or cloth snap: a glove slapping, a towel snapped taut, very short, no tail",
		Keywords = {
			"leather snap", "cloth snap", "fabric snap", "towel snap", "slap", "hand slap", "glove slap", "leather slap",
			"skin slap", "clap", "hand clap", "snap", "leather hit", "belt snap", "whip crack", "flick", "cloth flick",
		},
		Avoid = {
			"whoosh", "swoosh", "swing", "miss", "sword", "blade", "glass", "metal", "gun", "explosion", "applause", "crowd",
			"reverb", "echo", "loop", "finger", "fingers", "cinematic", "camera", "shutter", "lighter", "branch", "twig",
		},
		Prefer = { "snap", "slap", "leather", "cloth", "crisp", "short" },
		Mode = "Hit",
		Slice = { 0.03, 0.08 },
		Attack = { 0, 0.004 },
		Tail = { 0.015, 0.06 },
		Bands = { Low = 0.05, Mid = 0.55, High = 0.4 },
		MaxFile = 3,
	},

	-- B, HeavyHit and Haymaker's base: a recorded heavy body, one contact, never a cluster of knocks. Its weight must
	-- hold through a phone (a 200 Hz high-pass): energy under 120 Hz at most half its total, so the low mids carry it,
	-- and our sub only reinforces. Haymaker keeps its own HaymakerStrike on top.
	HeavyHitBody = {
		Brief = "a heavy, solid body blow: a fist or a padded ram sinking into a sandbag or a leather mass, one deep thud",
		Keywords = {
			"heavy punch", "body blow", "punch heavy", "hard punch", "strong punch", "power punch", "big punch", "sandbag",
			"sandbag hit", "punching bag", "heavy bag", "boxing bag", "bag hit", "bag punch", "leather hit", "leather thud",
			"heavy thud", "thud", "body thud", "body slam", "body fall", "body impact", "wood thud", "heavy wood hit",
			"wood impact heavy", "heavy impact", "impact thud", "heavy kick", "kick heavy", "mattress hit", "pillow hit",
		},
		Avoid = {
			"whoosh", "swoosh", "swing", "swish", "miss", "glass", "metal", "metallic", "explosion", "gun", "shot", "debris",
			"rumble", "crash", "door", "car", "cinematic", "trailer", "boom", "bass", "sub", "drop", "braam", "riser",
			"reverb", "echo", "rain", "loop", "water", "splash",
		},
		Prefer = { "punch", "body", "heavy", "thud", "bag", "leather", "blow", "impact" },
		Mode = "Hit",
		Slice = { 0.18, 0.5 },
		Attack = { 0, 0.012 },
		Tail = { 0.12, 0.4 },
		Bands = { Low = 0.4, Mid = 0.5, High = 0.1 },
		MaxFile = 5,
	},

	-- C, ShadeSwipe's tell: the Shade's paper drawn back taut before it strikes, a sound a player learns to dodge on.
	-- Short and crisp, mid and high, so it reads under the lead's hits; it lands about 0.2 s before the swipe's top.
	ShadeTellPaper = {
		Brief = "a sheet of stiff paper or cloth drawn back and pulled taut: a short dry rustle ending in a crisp flick",
		Keywords = {
			"paper rustle", "paper crinkle", "paper flutter", "paper shake", "paper snap", "paper flick", "paper handling",
			"paper foley", "page flip", "page turn", "paper movement", "cloth rustle", "fabric rustle", "clothing rustle",
			"cloth movement", "fabric movement", "flag flutter", "flag snap", "banner flap", "sheet shake", "rustle",
			"flutter", "flap",
		},
		Avoid = {
			"loop", "ambience", "ambient", "rain", "fire", "wind", "crowd", "office", "printer", "tear", "tearing", "rip",
			"ripping", "bird", "wings", "bag", "plastic", "chips", "footstep", "footsteps", "walk", "reverb",
		},
		Prefer = { "paper", "cloth", "fabric", "flick", "snap", "rustle", "short" },
		Mode = "Hit",
		Slice = { 0.12, 0.3 },
		Attack = { 0.02, 0.15 },
		Tail = { 0.03, 0.12 },
		Bands = { Low = 0.05, Mid = 0.45, High = 0.5 },
		MaxFile = 5,
	},
	-- C, the swipe: paper or cloth cutting the air, one pass, its top on the swipe's beat (the cue leads it by its peak).
	-- Lighter and higher than the lead's hits, so it sits under them.
	ShadeSwipeAir = {
		Brief = "a quick swipe of cloth or paper through the air: one soft-edged pass, rising to its top and gone",
		Keywords = {
			"cloth whoosh", "cloth swish", "fabric whoosh", "fabric swish", "paper whoosh", "paper swish", "cape whoosh",
			"cloak whoosh", "coat whoosh", "robe swish", "jacket whoosh", "flag whoosh", "towel whoosh", "swish", "swipe",
			"quick whoosh", "short whoosh", "soft whoosh", "air swipe", "hand whoosh", "arm swing", "fan swish",
			"whoosh foley", "foley whoosh",
		},
		Avoid = {
			"sword", "blade", "knife", "katana", "metal", "laser", "fire", "magic", "energy", "sci fi", "scifi", "electric",
			"car", "plane", "jet", "wind", "loop", "ambience", "rain", "punch", "hit", "impact", "heavy", "big", "bass",
			"cinematic", "trailer", "riser", "reverse",
		},
		Prefer = { "cloth", "fabric", "paper", "swish", "swipe", "cape", "short", "foley" },
		Mode = "Hit",
		Slice = { 0.18, 0.4 },
		Attack = { 0.05, 0.2 },
		Tail = { 0.05, 0.22 },
		Bands = { Low = 0.05, Mid = 0.45, High = 0.5 },
		MaxFile = 4,
	},

	-- AR39's second batch (Modulo, 2026-11-17): the three thin roles again, in the licensed libraries' own words, run
	-- with AnyAuthor = false so every pick is one a monetized game may use. The first batch's keywords were a player's
	-- ("punch", "jab"); the libraries title a file by what was recorded ("Body Hits Leather Glove", "Thigh Slap").
	-- The first batch's wrong sounds join each Avoid.
	LightHitBody2 = {
		Brief = "a quick, clean hit on a body or padded cloth, as a foley library titles it: a short low-mid thock, one burst",
		Keywords = {
			"body hits", "body hit", "body punch", "body punches", "body blow", "punches", "fist into bag", "bag punch",
			"punching bag", "martial arts punch", "martial arts hit", "kick into pad", "face punch", "chest hit", "chest thump",
			"chest pat", "body pats", "body slap", "shoulder pat", "back slap", "fist into palm", "fist palm", "palm hit",
			"glove hits", "boxing hits", "focus mitt", "punching mitt", "kick pad", "pad hit", "cloth hits", "jacket hits",
			"leather jacket hit", "coat hit", "pillow punch", "pillow hit", "cushion punch", "karate hit", "thigh slap",
		},
		Avoid = {
			"whoosh", "swoosh", "swing", "swish", "miss", "sword", "blade", "knife", "glass", "window", "vehicle", "metal",
			"metallic", "gun", "explosion", "slam", "door", "bell", "rock", "stone", "cinematic", "trailer", "boom", "bass",
			"sub", "reverb", "echo", "rain", "loop", "bird", "plastic", "applause", "crowd", "fall", "drop",
		},
		Prefer = { "body", "hits", "punch", "cloth", "leather", "glove", "pat", "slap" },
		Mode = "Hit",
		Slice = { 0.06, 0.15 },
		Attack = { 0, 0.008 },
		Tail = { 0.04, 0.12 },
		Bands = { Low = 0.25, Mid = 0.6, High = 0.15 },
		MaxFile = 6,
	},
	HeavyHitBody2 = {
		Brief = "one heavy, soft-edged body blow, as a foley library titles it: a body or a full sack landing, a deep thud",
		Keywords = {
			"body fall", "body falls", "bodyfall", "body drop", "body slam", "body hits heavy", "heavy body hit",
			"sandbag", "sand bag drop", "sack drop", "heavy bag hits", "punching bag hits", "medicine ball", "mattress hits",
			"mattress hit", "couch hits", "cushion hits", "pillow hits heavy", "duffel bag drop", "leather bag drop",
			"wrestling mat", "gym mat", "body kick", "kick body", "heavy thuds", "dull thud", "muffled thud",
			"leather couch hit", "boxing hits heavy",
		},
		Avoid = {
			"whoosh", "swoosh", "swing", "swish", "miss", "glass", "metal", "metallic", "explosion", "gun", "shot", "debris",
			"rumble", "crash", "door", "car", "cinematic", "trailer", "boom", "riser", "reverb", "echo", "rain", "loop",
			"water", "splash", "bird", "plastic", "paper", "scrapbook", "sprinkling", "stretching", "grab", "handling",
			"rock", "dirt", "gravel", "stairs", "roll", "rolling",
		},
		Prefer = { "body", "heavy", "thud", "bag", "leather", "fall", "hits", "mat" },
		Mode = "Hit",
		Slice = { 0.18, 0.5 },
		Attack = { 0, 0.012 },
		Tail = { 0.12, 0.4 },
		Bands = { Low = 0.4, Mid = 0.5, High = 0.1 },
		MaxFile = 6,
	},
	ShadeSwipeAir2 = {
		Brief = "one quick pass of cloth or paper through the air, as a foley library titles it: soft-edged, rising and gone",
		Keywords = {
			"cloth whoosh", "cloth whooshes", "cloth swish", "cloth swishes", "cloth swing", "fabric whoosh", "towel whip",
			"towel swing", "towel whoosh", "flag whoosh", "flag swing", "cape", "cape whoosh", "coat swing", "jacket swing",
			"jacket whoosh", "sheet whoosh", "blanket whoosh", "paper whoosh", "paper swish", "cardboard whoosh",
			"whooshes cloth", "whooshes fast", "swishes", "stick whoosh", "bamboo swish", "rope swish", "fan whoosh",
		},
		Avoid = {
			"sword", "blade", "knife", "katana", "metal", "laser", "fire", "magic", "energy", "sci fi", "scifi", "electric",
			"car", "plane", "jet", "wind", "loop", "ambience", "rain", "punch", "hit", "impact", "heavy", "big", "bass",
			"cinematic", "trailer", "riser", "reverse", "ui", "gui", "interface", "button", "bird", "wing", "wings",
		},
		Prefer = { "cloth", "fabric", "paper", "swish", "whoosh", "towel", "flag", "short", "fast" },
		Mode = "Hit",
		Slice = { 0.18, 0.4 },
		Attack = { 0.05, 0.2 },
		Tail = { 0.05, 0.22 },
		Bands = { Low = 0.05, Mid = 0.45, High = 0.5 },
		MaxFile = 5,
	},
}

return briefs
