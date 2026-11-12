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
}

return briefs
