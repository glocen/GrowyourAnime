--!strict
-- Passives (shared, content): each Voidkin's passive, one row of data keyed by its id (docs/roster.md, "Passive"). Common to
-- Epic, a passive is one plain effect with at most one plain condition (the director, 2026-11-13), so five kinds cover
-- them, each read by one rule (Rules.Passive):
--   Reduction: it takes Share less damage while its health is under Below of its most.
--   Extra: one beat of one action adds Share of that hit's damage again, in the Voidkin's element, as its own coloured number.
--   Cooldown: one action's cooldown is Share shorter.
--   Opener: its first hit to land on a target crits at Share at least (1: always), past the critical's cap. A dodged swing
--   hasn't landed; a Shade walked home is fought anew. The critical's own number is its cue.
--   Resist: it takes Share less elemental damage, always (Rules.Hit's Reduction bucket, on the elemental part alone).
-- A new Voidkin's passive is a row, and its cue a look the client already has (FighterController/Passives). The numbers
-- are research's seeds (docs/test-requests.md, TR7, part 3; tier 2), tuned by playing: "Passives.rook.Share".
-- No Roblox API: it runs with Studio closed.

local Tune = require(script.Parent.Parent.Util.Tune)

export type Kind = "Reduction" | "Extra" | "Cooldown" | "Opener" | "Resist"

export type Row = {
	Id: string, -- the Voidkin's id
	Name: string, -- what players read (docs/roster.md)
	Kind: Kind,
	Share: number, -- of the damage taken, of the hit, of the cooldown
	Below: number?, -- Reduction: a share of its most health
	Action: string?, -- Extra and Cooldown: the action's id (Definitions.Actions)
	Beat: string?, -- Extra: the beat its hit lands on
	-- Its look (FighterController/Passives): "Shell" round the body while a Reduction holds, "Flare" at an attachment of
	-- that name on the body (At) as an Extra lands; nil for none.
	Cue: string?,
	At: string?,
}

local rows: { Row } = {
	-- Second Wind: below 30% health he takes 20% less damage. A faint shell round him while it holds.
	{ Id = "rook", Name = "Second Wind", Kind = "Reduction", Share = 0.2, Below = 0.3, Cue = "Shell" },
	-- Kindle: his combo's third shot adds Fire worth 40% of the shot, as its own number. The lantern flares on it.
	{ Id = "pip", Name = "Kindle", Kind = "Extra", Share = 0.4, Action = "PipCombo", Beat = "Shot3", Cue = "Flare", At = "Lantern" },
	-- Tempo: Held Note's cooldown is 20% shorter. No cue: the song comes round more often.
	{ Id = "lyric", Name = "Tempo", Kind = "Cooldown", Share = 0.2, Action = "LyricHeldNote" },
	-- First Strike: her first hit on a new target always crits (docs/roster.md). No cue of its own: the critical's number.
	{ Id = "kirra", Name = "First Strike", Kind = "Opener", Share = 1 },
	-- Insulated: he takes 25% less elemental damage (docs/roster.md). No cue: it's in his gloves and boots (AR11). A seed.
	{ Id = "watt", Name = "Insulated", Kind = "Resist", Share = 0.25 },
}

local Passives = {}

Passives.List = rows
Passives.ById = {} :: { [string]: Row }
for _, row in rows do
	Passives.ById[row.Id] = row
end

-- Tune's paths into the rows: "Passives.<Voidkin id>.<key>".
Tune.Roots.Passives = function(keys: { string }): (any, number)
	return Passives.ById, 2
end

return Passives
