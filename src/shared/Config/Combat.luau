--!strict
-- Combat (shared Config): how a fight moves and how it's shown (docs/design.md, "Combat"). Studs are at Roblox's default
-- walk of 16 a second. The builder's numbers, 2026-11-12, from handbook/feel/combat.md and game-feel.md's starting points,
-- tuned by playing: NL_Debug:Invoke("Tune", "Combat.Hitstop.Heavy", 0.16).

return {
	Think = 0.1, -- seconds between a fighter's decisions; beats are checked every frame
	-- A fighter walks to this far inside an action's range. More than the Humanoid's own stop: Humanoid:MoveTo counts itself
	-- arrived about 0.6 studs short of its point (measured 2026-11-12), and at 0.5 a lead and a keeper closing on each other
	-- both stopped 0.1 outside their reach and stood there.
	Approach = 1,
	Arc = 70, -- degrees either side of a fighter's facing that its hits reach
	-- Fighters closing on one target take places around it (Rules/Fight.Spread): they don't collide, so this is what keeps a
	-- pack from stacking. Spacing in degrees apart; a fighter acts once within Arc degrees of its place, else walks to it.
	Slots = { Spacing = 60, Arc = 20 },

	-- The lead (docs/design.md, "Combat"): it fights what's near the avatar and comes back when the avatar walks away.
	Lead = {
		Leash = 30, -- it fights enemies within this of the avatar
		Follow = 6, -- with nothing to fight, it walks to the avatar's side once it's this far away
		Side = 3.5, -- the spot it walks to: this far right of the avatar and a stud behind
		WalkSpeed = 16,
		CatchUpSpeed = 26, -- once it's CatchUpFrom away, so it keeps up with a running avatar
		CatchUpFrom = 18,
		TeleportFrom = 90, -- past this it reappears at the avatar's side
		DownSeconds = 4, -- down, then up at the avatar's side at full health, with nothing lost
		Heal = { After = 5, PerSecond = 0.1 }, -- out of a fight: after 5 s without a hit either way, a tenth a second
	},

	-- Shades (docs/test-requests.md, TR2, "the builder's read"): a pack notices a lead within 20 studs and gives up past 40
	-- from its spawn, so a fight never pulls the next pack, 80 studs on.
	Shade = {
		Notice = 20,
		GiveUp = 40,
		WalkSpeed = 12,
		ResetSpeed = 24, -- walking home after giving up, untouchable
		FadeSeconds = 1.2, -- a fallen Shade bursts into light and paper, then is gone
	},

	-- Who flinches: a short reaction that never cancels an action (docs/design.md, "States in a fight").
	Flinch = { Seconds = 0.28, Kinds = { Lead = true, Ordinary = true, Dummy = true } },

	-- How far a push moves each body, against its Push (handbook/feel/combat.md: a heavy enemy moves less).
	Weight = { Lead = 1, Ordinary = 1, Elite = 0.4, Keeper = 0.15, Dummy = 1 },

	-- The hit's four moments (handbook/feel/combat.md, "Hit reactions and knockback"). The hold is the client's, presentation
	-- only; the server pushes once the hold is over, so the body jumps on the frame it lets go.
	Hitstop = { Light = 0.09, Heavy = 0.13 },
	Push = { Seconds = 0.1 },
	-- The camera, the client's: magnitude in studs, roughness a second, fade in seconds (handbook/feel/game-feel.md).
	Shake = {
		Heavy = { Magnitude = 1.6, Roughness = 14, Fade = 0.15 }, -- the player's own lead lands a heavy hit
		Hurt = { Magnitude = 0.6, Roughness = 12, Fade = 0.2 }, -- the player's own lead is hit hard (a tenth of its health)
		HurtShare = 0.1,
	},
	-- Damage numbers over the target: they rise this many studs over this many seconds.
	Numbers = { Rise = 2.5, Seconds = 0.8, Size = 24 }, -- Size: pixels at the phone's size (UI.Theme.Author), scaled with the screen

	-- The keeper's try (KeeperService; docs/test-requests.md, TR2, "the keeper, fought alone"). The builder's numbers, 2026-11-12.
	Keeper = {
		Hold = 0.5, -- seconds the gate's Challenge is held: a try is a decision
		Reach = 10, -- studs from the gate it can be asked
		Fade = { Out = 0.25, Hold = 0.2, Back = 0.35 }, -- the fade around each move; the move is in the middle of Hold
		Entry = 6, -- studs inside the copy's rim the avatar arrives, facing the keeper at its middle
		WinPause = 2, -- seconds after the keeper's fall before the fade out: the fall is seen
		LossPause = 1, -- seconds after the lead's fall
		Before = 10, -- studs before the keeper's gate a loss sets the avatar down
		-- It notices its challenger anywhere in its copy (a 41-stud ring inside a fenced square: 133 corner to corner) and
		-- never gives up, so a fight at the rim can't reset it. Copies stand 600 apart.
		Notice = 140,
	},

	-- The replay (the ga-action skill): an action on a clean pad, from the player's camera, the numbers live.
	Replay = {
		Distance = 0, -- the dummy stands this far ahead of the lead; 0 is the action's own spacing, where a lead fights from (Range - Approach)
		Behind = 9, -- the avatar stands this far behind the lead, and Lead.Side to its left, as in play; the camera behind the avatar
		Pitch = 20, -- degrees the camera looks down, over the avatar onto the fight
		Every = 3.5, -- seconds from one press to the next
		FreezeAt = 0, -- Studio: above 0, the player's own lead stops this many seconds into each press (clip, effect, sparks), to capture or study a beat; 0 is off
	},
}
