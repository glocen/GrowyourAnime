--!strict
-- Actions (shared, content): every action a fighter takes, one row of named beats each (the ga-action skill, step 2). A
-- clip's markers carry the same names at the same times, which the self-test holds together, and the hit, the effect, the
-- sound and the camera hang on the names. Times are seconds from the action's start, on its clip's clock. Hitstop is the
-- client's presentation: it pauses that clock on screen, never the server's.
-- Feel numbers first (length, cancel, cooldown, each hit's weight and push), geometry second (range, reach).
-- Tuned live in a playtest: NL_Debug:Invoke("Tune", "Actions.RookHaymaker.Hits.Strike.Push", 6).
-- No Roblox API: it runs with Studio closed.

local Tune = require(script.Parent.Parent.Util.Tune)

export type Hit = {
	Coefficient: number, -- times Attack (docs/balance.md, "One hit")
	Heavy: boolean, -- the heavy hitstop and shake now; the heavy stagger when the states arrive (docs/design.md, "States in a fight")
	Reach: number, -- studs, root to root, flat: how far the target may stand when the beat comes
	Push: number, -- studs the target is knocked back, before its body's weight (Config.Combat.Weight)
}

export type Action = {
	Id: string,
	Clip: string?, -- the clip a client plays (Config.Animations); nil: a box rig's stand-in motion on the same beats
	Length: number, -- seconds the action holds its fighter, unless the next starts from CancelFrom
	CancelFrom: number, -- the next action may start from here: the chain's rhythm
	Cooldown: number, -- seconds from its start before it may start again; 0 for none
	Beats: { [string]: number }, -- named moments, seconds from the start
	Hits: { [string]: Hit }, -- by the beat each lands on
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
			Hit3 = { Coefficient = 1.4, Heavy = false, Reach = 6, Push = 1.2 }, -- the ram opens space for the next lunge
		},
		Range = 4.5,
		Heavy = false,
		State = nil,
		Levers = { "hitstop (light)", "knockback (the third hit opens space)", "a spark on contact" },
		Signed = nil,
	},
	{
		-- Rook's signature (docs/roster.md): a long wind-up, one straight punch, a shockwave along the ground. One target in
		-- TR2's block: the roster's shockwave reads as the bracket's travel, not yet a second hit (the builder's read).
		Id = "RookHaymaker",
		Clip = "RookHaymaker",
		Length = 2.0,
		CancelFrom = 1.7,
		Cooldown = 10,
		Beats = { Charge = 0.1333, Strike = 0.95, Shock = 0.9667, Step = 1.05, Vent = 1.1667 },
		Hits = {
			Strike = { Coefficient = 4.0, Heavy = true, Reach = 9, Push = 4 },
		},
		Range = 6,
		Heavy = true,
		State = nil, -- heavy, not a state: the heavy stagger joins with the states (docs/design.md, "States in a fight")
		Levers = {
			"anticipation (the hold, Charge to Strike, with the charge square drawing tight)",
			"hitstop (heavy)",
			"knockback (thrown back)",
			"screen shake (own heavy hit)",
			"the bracket thrown along the ground through the target",
		},
		Signed = "the feel line: Quaestor, 2026-11-12 (docs/asset-requests.md, AR1, delivery 4)",
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
			Hit = { Coefficient = ENEMY_PER_SECOND * 1.1, Heavy = false, Reach = 5.5, Push = 0.5 },
		},
		Range = 4,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the coat turns away)", "hitstop (light)", "knockback" },
		Signed = nil,
	},
	{
		-- The Lamplighter's one attack in TR2: health and a basic swing (docs/test-requests.md, TR2).
		Id = "KeeperSwing",
		Clip = nil,
		Length = 1.6,
		CancelFrom = 1.6,
		Cooldown = 0,
		Beats = { Wind = 0, Strike = 0.8, Recover = 1.0 },
		Hits = {
			Strike = { Coefficient = ENEMY_PER_SECOND * 1.6, Heavy = false, Reach = 8, Push = 1.5 },
		},
		Range = 6,
		Heavy = false,
		State = nil,
		Levers = { "anticipation (the lean back)", "hitstop (light)", "knockback" },
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

-- Each Voidkin's kit, in the order a fighter tries them: the signature first, so it goes as soon as it's ready. TR2 has one
-- kit, Rook's, and every lead fights with it on the R6 stand-in until its own is built (docs/test-requests.md, TR2).
Actions.Kits = {
	rook = { "RookHaymaker", "RookCombo" },
} :: { [string]: { string } }
Actions.StandIn = "rook"

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
