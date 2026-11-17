--!strict
-- Voidkin (shared, content): the thirty-one fighters, one row each, keyed by an id that never changes and never shows to
-- players. Generated from docs/roster.md, "The thirty-one", on 2026-11-12: the roster is the design, these rows are what the
-- game reads. A row changes in both, the roster first. A kit (Kit here; its passive in Definitions.Passives) joins as each
-- fighter is built.
-- Zone is the first ground (Definitions.Grounds, by Order) whose shards hold it. Aptitude is its work in a bay, 1 to 3.
-- Model and Kit are the build's, not the roster's: the fighter's own body and moves, once they're installed.

-- A Voidkin's moves (Definitions.Actions ids), written once here: every other table reads them (Actions.KitOf, SkipOf,
-- IdleOf, RoleOf). Each clip's role, for its fades (Config.Animations.Fades), is its place in the kit.
export type Kit = {
	Signature: string, -- tried first, so it goes as soon as it's ready
	Combo: string,
	-- A ranged lead's skip back, a Mage's or a Healer's: never chosen as an attack, taken on its own rule
	-- (Rules.Fight.ShouldSkip; docs/design.md, "Combat")
	Skip: string?,
	Idle: string?, -- its own stance's clip, when it isn't its rig's Idle (Config.Animations.Rigs)
}

export type Row = {
	Id: string,
	Name: string,
	Rarity: string, -- Definitions.Rarity
	Type: string, -- Red, Orange, Blue, Purple or Green: named by the colour it wears (TR36), id and name alike
	Class: string, -- Warrior, Tank, Assassin, Mage or Healer
	Element: string, -- Fire, Frost, Storm, Void, or "" for none
	Zone: number,
	Aptitude: number,
	-- Its body, ServerStorage.Templates.<Model> (tools/studio/Models/<Model>.luau): an R6 rig whose meshes ride its hidden
	-- parts, so it plays the R6 clips. Without one, a lead wears the grey R6 stand-in (FightService).
	Model: string?,
	-- Its body's shared reactions, a set in Config.Animations.Rigs: "R6" (open legs, the default) or "Robe".
	Rig: string?,
	-- Its moves, once built; without them a lead fights with the stand-in's (Actions.StandIn) on the grey R6 rig
	Kit: Kit?,
	-- A body installed ahead of its clips: where they come from. Until they land it fights on the stand-in's kit and
	-- reveals as the stand-in (UI.Reveal.Figure), and the logic cases ask for it gone once they have.
	ClipsDue: string?,
	-- Its own nudge to its class's walk speed in a fight, 1 either way at most (TR14; Config.Stats.Speed; docs/design.md,
	-- "Speed"): research's seeds, not the roster's columns.
	Speed: number?,
	-- Its signature and its passive in plain words, as players read them: the roster's own columns, word for word
	-- (one Voidkin's screen, TR17).
	Words: { Signature: string, Passive: string },
}

local rows: { Row } = {
	{ Id = "rook", Name = "Rook", Rarity = "Common", Type = "Red", Class = "Warrior", Element = "", Zone = 1, Aptitude = 2, Model = "Rook", Kit = { Signature = "RookHaymaker", Combo = "RookCombo" }, Words = { Signature = "Haymaker: a long wind-up, one straight punch, a shockwave along the ground", Passive = "Second Wind: takes less damage below 30% health" } },
	{ Id = "kirra", Name = "Kirra", Rarity = "Common", Type = "Blue", Class = "Assassin", Element = "", Zone = 1, Aptitude = 1, Speed = 1, Model = "Kirra", Kit = { Signature = "KirraScarfStep", Combo = "KirraCombo", Idle = "KirraIdle" }, Words = { Signature = "Scarf Step: vanishes, crosses the target, cuts on the way out", Passive = "First Strike: her first hit on a new target always crits" } },
	{ Id = "pip", Name = "Pip", Rarity = "Common", Type = "Purple", Class = "Mage", Element = "Fire", Zone = 1, Aptitude = 2, Model = "Pip", Rig = "Robe", Kit = { Signature = "PipLanternBurst", Combo = "PipCombo", Skip = "PipSkip" }, Words = { Signature = "Lantern Burst: the lantern flies out and bursts over a small area", Passive = "Kindle: his third shot adds Fire damage" } },
	{ Id = "watt", Name = "Watt", Rarity = "Common", Type = "Orange", Class = "Tank", Element = "Storm", Zone = 1, Aptitude = 3, Model = "Watt", Rig = "Watt", Kit = { Signature = "WattGroundWire", Combo = "WattCombo" }, Words = { Signature = "Ground Wire: plants his weapon, shields himself, and a pulse stops nearby enemies for a moment", Passive = "Insulated: takes less elemental damage" } },
	{ Id = "patch", Name = "Patch", Rarity = "Common", Type = "Green", Class = "Healer", Element = "", Zone = 2, Aptitude = 2, Words = { Signature = "Quick Fix: heals the ally with the least health, herself when alone", Passive = "Triage: her heals are stronger on a target under half health" } },
	{ Id = "tumble", Name = "Tumble", Rarity = "Common", Type = "Blue", Class = "Warrior", Element = "", Zone = 2, Aptitude = 1, Words = { Signature = "Cartwheel Kick: a spinning double kick that hits all around", Passive = "Momentum: each hit in a row on one target adds damage, up to a cap" } },
	{ Id = "brick", Name = "Brick", Rarity = "Common", Type = "Red", Class = "Tank", Element = "", Zone = 2, Aptitude = 3, Words = { Signature = "Door Slam: slams the door down, pushes enemies back and draws them onto him", Passive = "Hard Hat: blocks the first hit of every fight" } },
	{ Id = "sable", Name = "Sable", Rarity = "Uncommon", Type = "Green", Class = "Assassin", Element = "", Zone = 1, Aptitude = 1, Words = { Signature = "Riposte: takes a guard, turns the next hit aside and lunges", Passive = "Footwork: harder to hit for a few seconds after his signature" } },
	{ Id = "cinder", Name = "Cinder", Rarity = "Uncommon", Type = "Purple", Class = "Mage", Element = "Fire", Zone = 2, Aptitude = 2, Words = { Signature = "Cinder Ring: a ring of fire closes on the target's ground", Passive = "Smoulder: targets she has set alight take more from her" } },
	{ Id = "gantry", Name = "Gantry", Rarity = "Uncommon", Type = "Orange", Class = "Warrior", Element = "", Zone = 2, Aptitude = 3, Words = { Signature = "Piston Drive: two piston punches, the second one shoves", Passive = "Counterweight: can't be pushed, and blocks more often" } },
	{ Id = "mallow", Name = "Mallow", Rarity = "Uncommon", Type = "Red", Class = "Healer", Element = "", Zone = 2, Aptitude = 2, Words = { Signature = "Hot Meal: throws a dish that heals everyone near it for a few seconds", Passive = "Hearty: more maximum health" } },
	{ Id = "rill", Name = "Rill", Rarity = "Uncommon", Type = "Blue", Class = "Mage", Element = "Frost", Zone = 3, Aptitude = 1, Words = { Signature = "Cold Snap: the ring flies out, freezes and breaks", Passive = "Slipstream: harder to hit while she keeps her distance" } },
	{ Id = "dirge", Name = "Dirge", Rarity = "Uncommon", Type = "Green", Class = "Tank", Element = "Void", Zone = 3, Aptitude = 2, Words = { Signature = "Toll: one stroke of the bell draws every enemy near", Passive = "Mourner: takes less damage for each enemy on him, up to a cap" } },
	{ Id = "juno", Name = "Juno", Rarity = "Uncommon", Type = "Purple", Class = "Warrior", Element = "Storm", Zone = 3, Aptitude = 2, Words = { Signature = "Thunder Draw: a quick draw and a dash through the target", Passive = "Study: crits more on a target she has hit five times" } },
	{ Id = "lyric", Name = "Lyric", Rarity = "Rare", Type = "Green", Class = "Healer", Element = "Storm", Zone = 1, Aptitude = 2, Model = "Lyric", Rig = "Robe", Kit = { Signature = "LyricHeldNote", Combo = "LyricCombo", Skip = "LyricSkip", Idle = "LyricIdle" }, Words = { Signature = "Held Note: a wave of sound that heals allies and hurts enemies in a cone", Passive = "Tempo: Held Note comes back sooner" } },
	{ Id = "mirage", Name = "Mirage", Rarity = "Rare", Type = "Blue", Class = "Assassin", Element = "Fire", Zone = 3, Aptitude = 1, Words = { Signature = "Heat Haze: leaves an afterimage that strikes a second time", Passive = "Shimmer: after a dodge, her next hit crits" } },
	{ Id = "bulwark", Name = "Bulwark", Rarity = "Rare", Type = "Orange", Class = "Tank", Element = "Frost", Zone = 3, Aptitude = 3, Words = { Signature = "Rampart: raises an ice wall that shields allies behind it", Passive = "Rime: a blocked hit gives him a small shield" } },
	{ Id = "sliptail", Name = "Sliptail", Rarity = "Rare", Type = "Purple", Class = "Mage", Element = "Void", Zone = 3, Aptitude = 2, Words = { Signature = "Nine Slips: the slips leave the fan and home on targets", Passive = "Trickster: after a dodge, reappears behind the attacker" } },
	{ Id = "gauge", Name = "Gauge", Rarity = "Rare", Type = "Red", Class = "Warrior", Element = "Storm", Zone = 4, Aptitude = 2, Words = { Signature = "Overpressure: the arm vents steam, then one enormous punch", Passive = "Redline: more damage as his health drops, up to a cap" } },
	{ Id = "wren", Name = "Wren", Rarity = "Rare", Type = "Blue", Class = "Healer", Element = "", Zone = 4, Aptitude = 1, Words = { Signature = "Mending Volley: a fan of arrows that heal allies and hurt enemies", Passive = "Updraft: an ally she heals is harder to hit for a moment" } },
	{ Id = "halcyon", Name = "Halcyon", Rarity = "Epic", Type = "Purple", Class = "Healer", Element = "Frost", Zone = 3, Aptitude = 2, Words = { Signature = "Still Snow: snow falls on a wide circle, healing allies and chilling enemies", Passive = "Thaw: healing past full health becomes a shield, up to a cap" } },
	{ Id = "ashen", Name = "Ashen", Rarity = "Epic", Type = "Red", Class = "Assassin", Element = "Fire", Zone = 4, Aptitude = 1, Words = { Signature = "Last Ember: a single draw cut that sets the target alight", Passive = "Cinderwalk: his first hit after moving to a new target lands harder" } },
	{ Id = "ironhymn", Name = "Ironhymn", Rarity = "Epic", Type = "Orange", Class = "Mage", Element = "Storm", Zone = 4, Aptitude = 3, Words = { Signature = "Pipe Barrage: bolts arc out of the pipes and fall on the target", Passive = "Resonance: each bolt on the same target adds Storm damage, up to a cap" } },
	{ Id = "noct", Name = "Noct", Rarity = "Epic", Type = "Green", Class = "Assassin", Element = "Void", Zone = 5, Aptitude = 1, Words = { Signature = "Rift Lunge: throws the spear and arrives where it lands", Passive = "Hunter's Mark: one marked target takes more from him" } },
	{ Id = "marigold", Name = "Marigold", Rarity = "Epic", Type = "Orange", Class = "Tank", Element = "Fire", Zone = 1, Aptitude = 2, Words = { Signature = "Lion's Roar: a roar that draws every enemy and shields allies", Passive = "Drumbeat: each hit he takes charges his next roar" } },
	{ Id = "stellane", Name = "Stellane", Rarity = "Legendary", Type = "Purple", Class = "Mage", Element = "Storm", Zone = 4, Aptitude = 2, Words = { Signature = "Starfall Chart: draws a constellation, and a bolt falls on each star", Passive = "Zenith: every third signature is stronger" } },
	{ Id = "crane", Name = "Crane", Rarity = "Legendary", Type = "Blue", Class = "Warrior", Element = "", Zone = 1, Aptitude = 1, Words = { Signature = "Hundred Steps: a storm of palm strikes from afterimages, ended by one draw of the sword", Passive = "Calm: harder to hit and crits more the longer he goes unhit" } },
	{ Id = "shiomaru", Name = "Shiomaru", Rarity = "Legendary", Type = "Orange", Class = "Tank", Element = "Frost", Zone = 6, Aptitude = 3, Words = { Signature = "Anchor Drop: hauls enemies in on the chain and slams the anchor down", Passive = "Breakwater: allies behind it take less damage" } },
	{ Id = "aegir", Name = "Aegir", Rarity = "Mythical", Type = "Blue", Class = "Assassin", Element = "Storm", Zone = 6, Aptitude = 3, Words = { Signature = "Glint Drive: gone in a streak of white wind, through every enemy on a line, then the lance fires back along it", Passive = "Tailwind: each enemy it finishes refills part of its signature" } },
	{ Id = "umbriel", Name = "Umbriel", Rarity = "Mythical", Type = "Green", Class = "Mage", Element = "Void", Zone = 6, Aptitude = 2, Words = { Signature = "Hands of the Void: the two hands close on the target's ground", Passive = "Sovereign: enemies near her resist elements less" } },
	{ Id = "solkar", Name = "Solkar", Rarity = "Mythical", Type = "Red", Class = "Warrior", Element = "Fire", Zone = 6, Aptitude = 2, Words = { Signature = "Dawnbreaker: a leap, and the sword opens a line of fire", Passive = "Dragon's Blood: his signature heals him for part of its damage" } },
}

local byId: { [string]: Row } = {}
for _, row in rows do
	byId[row.Id] = row
end

-- Whether a Voidkin is made: its body and its moves installed, no clips still due. Only a made Voidkin comes out of a
-- shard (Rules.Odds; TR24, "a must-fix before any public build": a shard rolled Sable, who has no model, kit or
-- portrait; the director, 2026-11-17, 02:40: launch has five, Sable, Marigold and Crane wait), so each joins the
-- shards' tables on its own once it's built. Its portrait is the logic cases' check.
local function made(row: Row): boolean
	return row.Model ~= nil and row.Kit ~= nil and row.ClipsDue == nil
end

return {
	List = rows, -- in the roster's order
	ById = byId,
	Made = made,
}
