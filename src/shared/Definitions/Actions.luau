--!strict
-- Actions (shared, content): every action a fighter takes, one row of named beats each (the ga-action skill, step 2). A
-- clip's markers carry the same names at the same times, which the self-test holds together, and the hit, the effect, the
-- sound and the camera hang on the names. Times are seconds from the action's start, on its clip's clock. Hitstop is the
-- client's presentation: it pauses that clock on screen, never the server's.
-- Feel numbers first (length, cancel, cooldown, each hit's weight and push), geometry second (range, reach).
-- Tuned live in a playtest: NL_Debug:Invoke("Tune", "Actions.RookHaymaker.Hits.Strike.Push", 6).
-- No Roblox API: it runs with Studio closed.

local Tune = require(script.Parent.Parent.Util.Tune)
local Voidkin = require(script.Parent.Voidkin)
local Enemies = require(script.Parent.Enemies)
local Animations = require(script.Parent.Parent.Config.Animations)

export type Hit = {
	Coefficient: number, -- times Attack (docs/balance.md, "One hit")
	Heavy: boolean, -- the heavy hitstop and shake now; the heavy stagger when the states arrive (docs/design.md, "States in a fight")
	Reach: number, -- studs, root to root, flat: how far the target may stand when the beat comes
	Push: number, -- studs the target is knocked back, before its body's weight (Config.Combat.Weight)
	Area: number?, -- studs round the target: every enemy standing within takes the hit too
	-- Degrees either side of the fighter's line to its target: every enemy within Reach of the fighter inside that cone
	-- takes the hit too (Rules.Fight.InCone)
	Cone: number?,
	-- Studs behind the fighter the cone's point stands, its degrees measured from there (Lyric's: where her speakers'
	-- lines meet, AR4, section 9); 0 when nil
	Apex: number?,
	-- A share of the healed one's health, given on the beat: to the fighter itself, and with a Cone to every ally lead
	-- standing inside it (docs/design.md: a Healer keeps itself up alone and others up in a group)
	Heal: number?,
	-- The fighter never holds on this hit, only its target: a run of beats that must keep their count (Lyric's crests)
	Steady: boolean?,
	-- Its rung on the importance ladder (docs/research/vfx-reference.md, rule 1), which sets its hold, its flash, the struck
	-- body's tremble and the camera's trauma (Config.Combat.Hitstop): 2 when nil, an ordinary hit; 3 a combo's last or
	-- the Shade's swing; 7 a Voidkin's signature; 8 the keeper's. A critical raises it (Rules.Fight.Rung).
	Rung: number?,
	-- Studs round the fighter itself: every enemy standing within takes the hit, its target too, whichever way it faces
	-- (Ground Wire's pulse); the target needn't be in Reach
	Round: number?,
	-- It lands on its fighter's footprint (FightService; Rules.Mark; Config.Combat.Keeper.Mark), put down on its action's
	-- Aim beat: every enemy whose centre is inside it, in place of Reach and the arc (TR44)
	Mark: boolean?,
	-- With Mark, its footprint is a line, not the keeper's ring: from its fighter's feet along its look, its action's Along
	-- move's Most and Config.Combat.Dasher.Line.Past more, Line.Half either side (AR52, the Dasher; Rules.Mark.OnLine)
	Line: boolean?,
	-- Seconds each enemy it lands on is stopped, unable to act or move (docs/design.md, "States in a fight": Stun), as a
	-- share of them on a tough kind and never again inside a lock after one (Config.Combat.Stun; Rules.Fight.Stun)
	Stun: number?,
	-- The fighter takes Share less damage for Seconds from the beat (Rules.Hit's Reduction bucket; Rules.Fight.Shield),
	-- whether or not anything is in reach
	Shield: { Share: number, Seconds: number }?,
	-- The rows effects that ride what it holds, played by the client for as long as each holds (Config.Effects.Lasting):
	-- Stun on each body it stops, ended with its stun, and Shield on the fighter, ended with the shield (AR11)
	Looks: { Stun: string?, Shield: string? }?,
}

-- The server carrying its fighter from a beat (Rules.Fight.MoveEnd; FightService): an Assassin's dash in, Kirra's blink.
export type Move = {
	Seconds: number, -- how long the carry takes; 0 sets it down there at once (a blink), facing back along its path
	Gap: number, -- studs short of its target's point on the path where it ends; negative, past it
	Most: number?, -- the farthest it's carried, studs
	Turn: number?, -- degrees its path turns at its spot toward its avatar's side of the line to its target; 0 or nil: straight at it
	-- Along its aim, fixed on its action's Aim beat, its Most in full and not at its target: the Dasher's lunge down its
	-- line (AR52), through whoever stands on it, stopped only by a wall. Its Gap is unused (0).
	Along: boolean?,
}

export type Action = {
	Id: string,
	Clip: string?, -- the clip a client plays (Config.Animations); nil: a box rig's stand-in motion on the same beats
	-- Its effect on its beats: a Config.Effects.Rows entry (FighterController/Effects, Play), or one of the three older
	-- signatures (Config.Effects.Older) until the finish pass; nil: a landed hit's spark only
	Effect: string?,
	Length: number, -- seconds the action holds its fighter, unless the next starts from CancelFrom
	CancelFrom: number, -- the next action may start from here: the chain's rhythm
	Cooldown: number, -- seconds from its start before it may start again; 0 for none
	Beats: { [string]: number }, -- named moments, seconds from the start
	Hits: { [string]: Hit }, -- by the beat each lands on
	Moves: { [string]: Move }?, -- by the beat each starts on: the server carries the body, the clip moves in place
	Aim: string?, -- the beat from which its aim is fixed: its fighter turns to its target until then, and a Mark hit's footprint is put down on it
	-- Its fighter's shield (AR52, the Guard): raised on its From beat, let down on its To; meanwhile each hit on it lets
	-- Config.Combat.Guard.Keep through, until a heavy hit or a signature breaks it (Rules.Fight.Guarded, Breaks)
	Guard: { From: string, To: string }?,
	-- The beat its cast lands on (AR58, the Support): one of its pack mended or shielded, as Rules.Support.Pick says
	-- (Config.Combat.Support; FightService). Its fighter casts it only while one of its pack stands to take it.
	Support: string?,
	Range: number, -- studs, root to root: its fighter walks this close before it starts it
	Heavy: boolean, -- it carries a heavy hit
	State: string?, -- the state it causes, when it names one (Stun, Knockdown): none in TR2
	Levers: { string }, -- the feel levers it uses, on purpose (the builder's brief)
	Signed: string?, -- who signed its line, and when: the design approval (tier 2)
}

-- An enemy's coefficient a second is the reference lead's (Rook's combo running, Haymaker on its cooldown), which is what
-- tools/balance/sim.py assumes of both sides (coef_per_second, 2.18 at the seeds). A case holds them together.
local ENEMY_PER_SECOND = (0.9 + 0.9 + 1.4) / 1.8 + 4.0 / 10

local rows: { Action } = {
	{
		-- Rook's three hits: jab, hook, the ram. AR1's clip, markers on whole frames at 60 fps.
		Id = "RookCombo",
		Clip = "RookCombo",
		Length = 2.0,
		CancelFrom = 1.8, -- the next jab starts here: hit 3 to hit 1 is 0.57 s, as hit to hit inside the chain (0.6, 0.63)
		Cooldown = 0,
		Beats = { Hit1 = 0.2, Hit2 = 0.8, Hit3 = 1.4333 },
		Hits = {
			Hit1 = { Coefficient = 0.9, Heavy = false, Reach = 6, Push = 0.4 },
			Hit2 = { Coefficient = 0.9, Heavy = false, Reach = 6, Push = 0.4 },
			Hit3 = { Coefficient = 1.4, Heavy = false, Reach = 6, Push = 1.2, Rung = 3 }, -- the ram opens space for the next lunge
		},
		Range = 4.5,
		Heavy = false,
		State = nil,
		Levers = { "hitstop (light)", "knockback (the third hit opens space)", "a spark on contact" },
		Signed = nil,
	},
	{
		-- Rook's signature (docs/roster.md): a long wind-up, then the ram driven down into the floor before the Shade, a
		-- square of light slammed onto it on the same frame, the Shade pinned where it stood: B5's block (docs/asset-requests.md,
		-- AR8, "B5"; the director's planned rework, 2026-11-12). One target, as in TR2's block.
		Id = "RookHaymaker",
		Clip = "RookHaymaker",
		Effect = "Haymaker",
		Length = 2.0,
		CancelFrom = 1.7,
		Cooldown = 10,
		Beats = { Charge = 0.1333, Strike = 0.95, Shock = 0.9667, Step = 1.05, Vent = 1.1667 },
		Hits = {
			-- Push 0: the pin. The stamp lands on the target and it stays under it (tier 2, research, 2026-11-13: AR8, "B5")
			Strike = { Coefficient = 4.0, Heavy = true, Reach = 9, Push = 0, Rung = 7 },
		},
		Range = 6,
		Heavy = true,
		State = nil, -- heavy, not a state: the heavy stagger joins with the states (docs/design.md, "States in a fight")
		Levers = {
			"anticipation (the hold, Charge to Strike: the ram cocked over his shoulder, the square hung over the target, drawn tight)",
			"the snap (up to down in two frames, the square falling with the ram)",
			"hitstop (heavy)",
			"the pin (no knockback: the target held where the stamp lands)",
			"screen shake (own heavy hit)",
			"squash (the stamp flattened into the floor on Shock)",
		},
		Signed = "the feel line: Quaestor, 2026-11-13 (docs/asset-requests.md, AR8, \"B5\")",
	},
	{
		-- Pip's three shots (AR4, section 3): two flicks off his sleeve, the lantern spitting and kicked back, then the whole
		-- sleeve jabbed and the lantern kicked clean over. He fights from his signature's spacing, so the lantern's throw
		-- lands where it's drawn to. Coefficients a second as Rook's combo's (a seed: docs/asset-requests.md, AR4, section 8).
		Id = "PipCombo",
		Clip = "PipCombo",
		Effect = "PipShots",
		Length = 1.6667,
		CancelFrom = 1.5, -- the next flick: Shot3 to Shot1 is 0.63 s
		Cooldown = 0,
		Beats = { Shot1 = 0.1667, Shot2 = 0.4333, Shot3 = 1.0333 },
		Hits = {
			Shot1 = { Coefficient = 0.75, Heavy = false, Reach = 15.5, Push = 0.3 },
			Shot2 = { Coefficient = 0.75, Heavy = false, Reach = 15.5, Push = 0.3 },
			Shot3 = { Coefficient = 1.17, Heavy = false, Reach = 15.5, Push = 1.0, Rung = 3 }, -- the lantern kicked clean over
		},
		Range = 14.5,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the third: feet set, under the brim)", "hitstop (light)", "a streak from the lantern to the target" },
		Signed = nil,
	},
	{
		-- Pip's signature (docs/roster.md; AR4, sections 7 and 8): the lantern heats in its cage, he heaves it and is rocked
		-- back by his own throw, it flies the clip's 12 studs and lets its flame out over an area, then comes home spent. He
		-- fights 13.5 studs off (Range - Approach), so it stops a stud and a half short of the target's middle, as drawn.
		Id = "PipLanternBurst",
		Clip = "PipLanternBurst",
		Effect = "LanternBurst",
		Length = 2.2,
		CancelFrom = 2.0,
		Cooldown = 10,
		Beats = { Heat = 0.1333, Send = 0.85, Burst = 1.1, Return = 1.6333 },
		Hits = {
			Burst = { Coefficient = 2.5, Heavy = true, Reach = 15.5, Push = 1.5, Area = 5, Rung = 7 }, -- each Shade in the flame's foot
		},
		Range = 14.5,
		Heavy = true,
		State = nil,
		Levers = {
			"anticipation (the heat climbing in the cage, Heat to Send)",
			"recoil (rocked back by his own throw)",
			"hitstop (heavy)",
			"the flame let out, twice his height, over the area",
			"the lantern home dark, relit over the cooldown: the readout",
		},
		Signed = "the feel line: Quaestor, 2026-11-12 (docs/asset-requests.md, AR4, section 7)",
	},
	{
		-- Lyric's three hits (AR4, section 6): she stamps the base and the right speaker fires; she cuts her free hand at
		-- you and the left one fires; she hoists the whole stand, drives it down, and both fire. Pip's seeds (a second's
		-- worth as Rook's combo's), from her signature's spacing (docs/asset-requests.md, AR4, section 9).
		Id = "LyricCombo",
		Clip = "LyricCombo",
		Effect = "LyricShots",
		Length = 1.75,
		CancelFrom = 1.5, -- the next stamp: Shot3 to Shot1 is 0.75 s
		Cooldown = 0,
		Beats = { Shot1 = 0.25, Shot2 = 0.5, Shot3 = 1.0 },
		Hits = {
			Shot1 = { Coefficient = 0.75, Heavy = false, Reach = 13, Push = 0.3 },
			Shot2 = { Coefficient = 0.75, Heavy = false, Reach = 13, Push = 0.3 },
			Shot3 = { Coefficient = 1.17, Heavy = false, Reach = 13, Push = 1.0, Rung = 3 }, -- both speakers at once
		},
		Range = 12,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the stand hoisted clear before the third)", "hitstop (light)", "a streak from a speaker to the target" },
		Signed = nil,
	},
	{
		-- Pip's skip back (docs/design.md, "Combat", the skip back; TR7, part 2): a quick hop back to his place in the frame,
		-- at his next action's range from his target, still facing it. Modulo's block clip moves in place: the gather to
		-- frame 5, off at 9, the top at 15, Land at 21. The server carries the body from the start to Land
		-- (FightService.trySkip); his next action may start on Land. No hit: it spends time, his and the enemy's.
		Id = "PipSkip",
		Clip = "PipSkip",
		Length = 0.5333,
		CancelFrom = 0.35, -- Land: the settle is cut by the next action
		Cooldown = 0, -- its own Every (Config.Combat.Skip), and no ring on the HUD
		Beats = { Land = 0.35 },
		Hits = {},
		Range = 0, -- never chosen from a kit (Actions.Skips)
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the gather, to frame 5)", "movement during (the travel back, from the start to Land)", "the landing cut into the next action" },
		Signed = "the feel line: Quaestor, 2026-11-13 (docs/design.md, \"Combat\"; TR7)",
	},
	{
		-- Lyric's skip back, as Pip's: the same hop in her robe, the stand up in her fist and down on Land.
		Id = "LyricSkip",
		Clip = "LyricSkip",
		Length = 0.55,
		CancelFrom = 0.35,
		Cooldown = 0,
		Beats = { Land = 0.35 },
		Hits = {},
		Range = 0,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the gather, to frame 5)", "movement during (the travel back, from the start to Land)", "the landing cut into the next action" },
		Signed = "the feel line: Quaestor, 2026-11-13 (docs/design.md, \"Combat\"; TR7)",
	},
	{
		-- Lyric's signature (docs/roster.md; AR4, section 9): a breath, she lunges into the mic, and the note sweeps out
		-- across the Shades in crests on every half-beat until she lets go. Each crest touches every Shade in the cone, a
		-- fifth of the signature's total, and heals her and every ally lead in it (research's tier 2). The cone is 14 studs
		-- from her (research's design number), 24 degrees each side of her line, as her speakers throw it. She fights 11 off
		-- (Range - Approach), where the cone's middle meets her target, as the block-in framed it.
		Id = "LyricHeldNote",
		Clip = "LyricHeldNote",
		Effect = "HeldNote",
		Length = 2.5,
		CancelFrom = 2.3,
		Cooldown = 10,
		Beats = { Breath = 0.0667, Note = 0.5, Crest2 = 0.75, Crest3 = 1.0, Crest4 = 1.25, Release = 1.5 },
		-- Each crest an ordinary hit's rung, not the signature's: five a quarter-second apart, and a signature's hold on each
		-- would freeze the struck half the note. The wave's own look carries the rung (AR8 A, the builder's call).
		Hits = {
			Note = { Coefficient = 0.5, Heavy = false, Reach = 14, Push = 0.3, Cone = 24, Apex = 3.9, Heal = 0.01, Steady = true },
			Crest2 = { Coefficient = 0.5, Heavy = false, Reach = 14, Push = 0.3, Cone = 24, Apex = 3.9, Heal = 0.01, Steady = true },
			Crest3 = { Coefficient = 0.5, Heavy = false, Reach = 14, Push = 0.3, Cone = 24, Apex = 3.9, Heal = 0.01, Steady = true },
			Crest4 = { Coefficient = 0.5, Heavy = false, Reach = 14, Push = 0.3, Cone = 24, Apex = 3.9, Heal = 0.01, Steady = true },
			Release = { Coefficient = 0.5, Heavy = false, Reach = 14, Push = 0.3, Cone = 24, Apex = 3.9, Heal = 0.01, Steady = true },
		},
		Range = 12,
		Heavy = false,
		State = nil,
		Levers = {
			"anticipation (the breath, the speakers drawn back)",
			"a crest on every half-beat, the count kept: her hold never stops on a touch (Steady)",
			"hitstop (light, on the Shades only)",
			"the heal washing over her and her allies",
		},
		Signed = "the feel line: Quaestor, 2026-11-12 (docs/asset-requests.md, AR4, section 9)",
	},
	{
		-- Kirra's three cuts (AR10, section 4): the dash is the first cut. She comes in low, her hand already on the grip
		-- (Dash, frame 0), draws across the Shade (Hit1, 12), wears the X (Hit2, 26), and rises up through it (Hit3, 56),
		-- sheathing both at 64. The clip moves in place; the server carries her in over the dash's 9 frames to Gap studs
		-- short of her target, so a later round, already close, steps in place (the builder's call on section 3's question:
		-- one clip, from 0 every time). Pip's seeds: a second's worth as Rook's combo's, over her 1.4 s chain.
		Id = "KirraCombo",
		Clip = "KirraCombo",
		Length = 1.6667,
		CancelFrom = 1.4, -- frame 84, low and ready: Hit3 to the next Hit1 is 0.67 s
		Cooldown = 0,
		Beats = { Dash = 0, Hit1 = 0.2, Hit2 = 0.4333, Hit3 = 0.9333, Sheathe = 1.0667 },
		Hits = {
			Hit1 = { Coefficient = 0.7, Heavy = false, Reach = 6, Push = 0.4 },
			Hit2 = { Coefficient = 0.7, Heavy = false, Reach = 6, Push = 0.4 },
			Hit3 = { Coefficient = 1.09, Heavy = false, Reach = 6, Push = 1.2, Rung = 3 }, -- up through it, lifted
		},
		Moves = {
			Dash = { Seconds = 0.15, Gap = 3.5, Most = 4 },
		},
		Range = 8, -- she stands 7 off (Range - Approach) and the dash brings her to 3.5, Rook's spacing
		Heavy = false,
		State = nil,
		Levers = { "the dash (movement during: in low over 0.15 s, the first cut on arrival)", "hitstop (light)", "a spark on contact" },
		Signed = nil,
	},
	{
		-- Kirra's signature (docs/roster.md; AR10's feel line): she blinks out, her scarf draws one straight line through the
		-- Shade, and the cut lands as she's already leaving, behind it, facing it. She sets with her hand on the grip (to frame
		-- 8), is gone on Blink (13) and past it on Land (16), and the cut lands on Cut (18). The server sets her down Gap
		-- studs past her target on Blink, facing back along her path; Turn swings that path off the Shade's middle, toward
		-- the camera's side (take B, AR10, section 5), and 0 is take A, straight through. Rook's Haymaker's seeds: one target,
		-- rung 7, a 10 s cooldown.
		Id = "KirraScarfStep",
		Clip = "KirraScarfStep",
		Effect = "KirraScarfStep", -- the grey block's rows (AR10, section 5), both takes in one file
		Length = 1.6,
		CancelFrom = 1.25, -- frame 75: the scarf settled (70), the blade home (65)
		Cooldown = 10,
		Beats = { Blink = 0.2167, Land = 0.2667, Cut = 0.3 },
		Hits = {
			Cut = { Coefficient = 4.0, Heavy = true, Reach = 8, Push = 1.5, Rung = 7 },
		},
		Moves = {
			Blink = { Seconds = 0, Gap = -3.8, Turn = 0 },
		},
		Range = 6, -- she sets 5 off (Range - Approach), the clip's spacing
		Heavy = true,
		State = nil,
		Levers = {
			"anticipation (the set, to frame 8: low, her hand on the grip)",
			"the blink (gone at 0.22 s, past it at 0.27: no travel shown)",
			"hitstop (heavy, rung 7) on the Cut, as she's already leaving",
			"the held line (the scarf straight through its chest, 16 to 40, let go from the tip)",
		},
		Signed = "the feel line: Quaestor, 2026-11-14 (docs/asset-requests.md, AR10)",
	},
	{
		-- Watt's three (AR11, delivery 4): the shaft across in both fists (Hit1, frame 21), the butt rising (Hit2, 36), and
		-- the spear lifted in both hands and driven into the street (Hit3, 60), held on it (72) and back by his foot (88),
		-- where the next round's lean starts. Heavy and short, the Tank's way. A second's worth as Rook's combo's over his
		-- 1.47 s chain, Rook's spacing (seeds).
		Id = "WattCombo",
		Clip = "WattCombo",
		Length = 1.8333,
		CancelFrom = 1.4667, -- frame 88, the spear back by his foot: Hit3 to the next Hit1 is 0.82 s, the drive held
		Cooldown = 0,
		Beats = { Hit1 = 0.35, Hit2 = 0.6, Hit3 = 1.0 },
		Hits = {
			Hit1 = { Coefficient = 0.73, Heavy = false, Reach = 6, Push = 0.4 },
			Hit2 = { Coefficient = 0.73, Heavy = false, Reach = 6, Push = 0.4 },
			Hit3 = { Coefficient = 1.15, Heavy = false, Reach = 6, Push = 1.2, Rung = 3 }, -- into the street
		},
		Range = 4.5,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the lift before the drive, 54 to 60)", "hitstop (light)", "a spark on contact" },
		Signed = nil,
	},
	{
		-- Watt's signature, Ground Wire (docs/roster.md; AR11's feel line): he lifts the spear in both hands and drives its
		-- butt into the street (Plant, frame 25), a ring of Storm's light snaps out along the ground, and the Shades round
		-- him lock mid-step while he stands behind it, shielded, until he pulls it free (Release, 124). The pulse takes
		-- every enemy within Round of him, whichever way it faces, and stops it for the hold, Plant to Release; his shield
		-- outlasts it. Seeds: Pip's area burst's weight, rung 7, a 10 s cooldown; the shield's share and time (tier 2).
		Id = "WattGroundWire",
		Clip = "WattGroundWire",
		Effect = "WattGroundWire", -- the grey block's rows (AR11, "Ground Wire's look"); its stop and shield are the hit's Looks
		Length = 2.8333,
		CancelFrom = 2.5, -- frame 150, upright again after he straightens (136)
		Cooldown = 10,
		Beats = { Plant = 0.4167, Release = 2.0667 },
		Hits = {
			-- Push 0: locked where they stood, never thrown (AR11: "stopped, never hurt")
			Plant = { Coefficient = 2.5, Heavy = true, Reach = 9, Push = 0, Rung = 7, Round = 9, Stun = 1.65, Shield = { Share = 0.3, Seconds = 5 },
				Looks = { Stun = "WattGroundWireStop", Shield = "WattGroundWireShield" } },
		},
		Range = 4.5,
		Heavy = true,
		State = "Stun",
		Levers = {
			"anticipation (the lift, both hands up, 0 to 16)",
			"the snap (the drive home in a fifth of a second, 16 to 25)",
			"hitstop (heavy, rung 7) on the Plant",
			"the stop (every Shade round him locked mid-step through the hold)",
			"the hold (the planted spear, blade and discs above his head, 25 to 124)",
		},
		Signed = "the seeds: Quaestor, 2026-11-17 (docs/asset-requests.md, AR11)",
	},
	{
		-- A Brawler Shade's swing, AR2's Attack: the coat turns away and the sleeve is flung round after it, landing on `Hit`
		-- (frame 30). Its length is the clip's, and its hit is a second's worth of the lead's, as before. A client plays the
		-- clip or its mirror at random (Config.Animations.Mirrors).
		Id = "ShadeSwipe",
		Clip = "ShadeAttack",
		Length = 1.1,
		CancelFrom = 1.1,
		Cooldown = 0,
		Beats = { Hit = 0.5 },
		Hits = {
			Hit = { Coefficient = ENEMY_PER_SECOND * 1.1, Heavy = false, Reach = 5.5, Push = 0.5, Rung = 3 },
		},
		Range = 4,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the coat turns away)", "hitstop (light)", "knockback" },
		Signed = nil,
	},
	{
		-- AR52, the Guard's (docs/asset-requests.md; docs/roster.md, "Enemies: Shades"): its sleeves come up and shut into a
		-- paper shield by Raise and hold it to Drop, hardly breathing, while each hit on it glances off
		-- (Config.Combat.Guard.Keep goes through) until a heavy hit or a signature breaks it open, Guard.Stagger seconds
		-- stunned. Then it fights as a Brawler, its swing, until the next raise: its cooldown is the hold and the open after
		-- Drop, research's 2.5 s. Its row's Signature, so it's tried first whenever ready. The shield's look is a grey
		-- stand-in (SlamController) until the effects teammate's. Seeds, tuned in play.
		Id = "GuardRaise",
		Clip = "ShadeGuard",
		Length = 2.7333,
		CancelFrom = 2.7333,
		Cooldown = 2.3 + 2.5,
		Beats = { Raise = 0.3, Drop = 2.3 },
		Guard = { From = "Raise", To = "Drop" },
		Hits = {},
		Range = 8,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the sleeves come up and shut)", "the hold (still, behind the paper)", "the break (a stagger)" },
		Signed = nil,
	},
	{
		-- AR52, the Dasher's: it folds down behind its mask's point and its line opens on the street at Line, from its feet
		-- toward its target, its aim fixed there; dead still to Lunge, then down the line in 0.25 s to Land, where its hit
		-- takes whoever stands on the line (Mark, Line: Rules.Mark.OnLine), its back open to Close. Moving the lead works as
		-- at the keeper's slam (TR44's switch, Config.Combat.Keeper.Out). Its hit is its length's worth of the swing's rate,
		-- so a Dasher that lands every lunge deals what a Brawler does; one that misses, less. Seeds, tuned in play.
		Id = "DasherLunge",
		Clip = "ShadeLunge",
		Length = 2.3,
		CancelFrom = 2.3,
		Cooldown = 6,
		Beats = { Line = 0.2667, Lunge = 1.0, Land = 1.25, Close = 2.05 },
		Aim = "Line",
		Moves = {
			Lunge = { Seconds = 0.25, Gap = 0, Most = 12, Along = true },
		},
		Hits = {
			Land = { Coefficient = ENEMY_PER_SECOND * 2.3, Heavy = true, Reach = 2.5, Push = 2, Rung = 5, Mark = true, Line = true },
		},
		Range = 10,
		Heavy = true,
		State = nil,
		Levers = { "anticipation (folded behind the point, dead still, the line on the street)", "the lunge (12 studs in 0.25 s)", "hitstop (rung 5)", "knockback", "recovery (its back open)" },
		Signed = nil,
	},
	{
		-- AR58, the Support's (docs/asset-requests.md, AR58): its sleeves go up wide by Cast and hold, and on Cast the one of
		-- its pack Rules.Support.Pick names is mended or shielded; they come down from Lower. Its row's Signature, tried
		-- first whenever it's ready and one of its pack stands to take it; between casts it keeps to its pack's back
		-- (FightService). Range is its reach to that one, not to the lead. Its looks, Scintilla's rows: SupportCast on the
		-- caster, SupportHeal on the mended (FighterController's HEALS), and SupportShield worn while the shield holds
		-- (Config.Combat.Support.Shield.Look). The builder's seeds, tuned in play.
		Id = "SupportCast",
		Clip = "ShadeCast",
		Effect = "SupportCast",
		Length = 1.7,
		CancelFrom = 1.7,
		Cooldown = 5,
		Beats = { Cast = 0.4, Lower = 1.4 },
		Support = "Cast",
		Hits = {},
		Range = 18,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the mask dips, the sleeves gather)", "the hold (sleeves up wide, who casts)", "the payoff on the ally (health back, or a shield)" },
		Signed = nil,
	},
	{
		-- The Lamplighter's one attack in TR2: health and a basic swing (docs/test-requests.md, TR2). AR7's clip: it draws the
		-- pole's foot back past its hip like a lance, then sweeps it round and across at the lead's chest, the lantern flung
		-- wide behind its shoulder and back by Recover (docs/asset-requests.md, AR7, section 4).
		Id = "KeeperSwing",
		Clip = "LamplighterSwing",
		Length = 1.6,
		CancelFrom = 1.6,
		Cooldown = 0,
		Beats = { Wind = 0, Strike = 0.8, Recover = 1.0 },
		Hits = {
			Strike = { Coefficient = ENEMY_PER_SECOND * 1.6, Heavy = false, Reach = 8, Push = 1.5, Rung = 3 },
		},
		Range = 6,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the pole's foot drawn back past its hip)", "hitstop (light)", "knockback", "the lantern's weight (flung wide, swinging back)" },
		Signed = nil,
	},
	{
		-- The Lamplighter's Challenge, held as a try starts (AR7, section 4: the fade clears about 0.45 s in, so the Lift is
		-- seen): it hears you, lifts its face to the player's camera on Lift and stamps its pole on Stamp, and ends in Ready.
		-- It never hits, and it's no one's to choose: the keeper's row starts it as it's spawned (Definitions.Enemies' Enter).
		Id = "KeeperChallenge",
		Clip = "LamplighterChallenge",
		Length = 1.5333,
		CancelFrom = 1.5333,
		Cooldown = 0,
		Beats = { Lift = 0.7333, Stamp = 0.9667 },
		Hits = {},
		Range = 0,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the head lifted to you before it moves)", "the stamp: the pole lifted a hand and set down" },
		Signed = nil,
	},
	{
		-- The Lamplighter's signature (AR7, sections 6 and 7; AR8, the keeper's signature): it plants its pole, leans its
		-- lantern out over your fighter as the light gathers in it, wrenches it high on Wrench and slams it down beside them on
		-- Slam, and the light leaps back up out of the street as a column. Its effect is its rows (Config.Effects.Rows.
		-- KeeperSignature). In the keeper's fight since TR44: its row's Signature, the first Config.Combat.Keeper.First after
		-- the Challenge, then on its cooldown; aimed until Plant, where its footprint goes down (Config.Combat.Keeper.Mark)
		-- and the tell runs to the Slam, 1.57 s. Its cooldown and coefficient are seeds, signed with the fight's rotation.
		Id = "KeeperSignature",
		Clip = "LamplighterSignature",
		Effect = "KeeperSignature",
		Length = 3.0333,
		CancelFrom = 3.0333,
		Cooldown = 12,
		Beats = { Plant = 0.4, Light = 0.7333, Wrench = 1.7667, Slam = 1.9667 },
		Aim = "Plant",
		Hits = {
			-- Reach is the replay's and a fighter's with no footprint down; in the fight the footprint decides (Mark)
			Slam = { Coefficient = ENEMY_PER_SECOND * 3, Heavy = true, Reach = 10, Push = 2.5, Rung = 8, Mark = true },
		},
		-- the lantern lands 6.33 studs ahead of the keeper and 1.92 to its left (AR7, section 7): from 7.5 it's down beside
		-- your fighter, 2.25 from its middle, its drum clear of the body
		Range = 7.5,
		Heavy = true,
		State = nil,
		Levers = {
			"anticipation (the long hold: the lantern leant out over your fighter, its light gathering, the camera lifted to it)",
			"the flare on the Wrench",
			"the streak trailing the fall",
			"hitstop (rung 8, the keeper's), the flash and the hurt shake on Slam",
			"knockback",
			"the column (the hero shape), its foot letting go and climbing away",
		},
		Signed = nil,
	},
}

local Actions = {}
Actions.List = rows
Actions.ById = {} :: { [string]: Action }
for _, row in rows do
	Actions.ById[row.Id] = row
end
Actions.EnemyPerSecond = ENEMY_PER_SECOND

-- Each Voidkin's kit is on its row (Definitions.Voidkin, Kit), written once. These are read from the rows, never edited:
--   Kits[def]   its attacks, in the order a fighter tries them: the signature first, so it goes as soon as it's ready.
--               A lead whose kit isn't built yet fights with the stand-in's on the R6 rig (docs/test-requests.md, TR2).
--   Skips[def]  a ranged lead's skip back (a Mage's or a Healer's): never in Kits, so never chosen as an attack; the
--               lead takes it on its own rule (Rules.Fight.ShouldSkip)
--   RoleOf(clip)  the game's name for a clip, for its fades: its place in a kit (Signature, Combo, Skip, Idle), else
--               the shared clips' (Config.Animations.Roles: the rigs' reactions, the enemies')
--   IdleOf(def)   a fighter's own stance, a Voidkin's (its Kit) or an enemy's (its row), over its rig's Idle; nil: none
Actions.Kits = {} :: { [string]: { string } }
Actions.Skips = {} :: { [string]: string }
Actions.StandIn = "rook"

local kitRoles: { [string]: string } = {}
local function role(id: string?, as: string)
	local action = if id then Actions.ById[id] else nil
	if action and action.Clip then
		kitRoles[action.Clip] = as
	end
end
for _, row in Voidkin.List do
	local kit = row.Kit
	if kit then
		Actions.Kits[row.Id] = { kit.Signature, kit.Combo }
		Actions.Skips[row.Id] = kit.Skip
		role(kit.Signature, "Signature")
		role(kit.Combo, "Combo")
		role(kit.Skip, "Skip")
		if kit.Idle then
			kitRoles[kit.Idle] = "Idle"
		end
	end
end
for _, row in Enemies.List do
	if row.Idle then
		kitRoles[row.Idle] = "Idle"
	end
end

function Actions.RoleOf(clip: string): string?
	return kitRoles[clip] or Animations.Roles[clip]
end

function Actions.IdleOf(def: string): string?
	local voidkin = Voidkin.ById[def]
	if voidkin then
		return if voidkin.Kit then voidkin.Kit.Idle else nil
	end
	local enemy = Enemies.ById[def]
	return if enemy then enemy.Idle else nil
end

function Actions.SkipOf(def: string): Action?
	local id = Actions.Skips[def]
	return if id then Actions.ById[id] else nil
end

function Actions.KitOf(def: string): { Action }
	local ids = Actions.Kits[def] or Actions.Kits[Actions.StandIn]
	local kit = {}
	for _, id in ids do
		table.insert(kit, Actions.ById[id])
	end
	return kit
end

-- Tune's paths into the rows: "Actions.<Id>.<key>...".
Tune.Roots.Actions = function(keys: { string }): (any, number)
	return Actions.ById, 2
end

return Actions
