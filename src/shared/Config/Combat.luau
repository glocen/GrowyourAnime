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
	-- Step: the most degrees round its target a fighter heads for at once, so it walks round the target, not through it.
	Slots = { Spacing = 60, Arc = 20, Step = 60 },

	-- The lead (docs/design.md, "Combat"): it fights what's near the avatar and comes back when the avatar walks away.
	Lead = {
		Leash = 30, -- it fights enemies within this of the avatar
		Follow = 6, -- with nothing to fight, it walks to the avatar's side once it's this far away
		Side = 3.5, -- the spot it walks to: this far right of the avatar and a stud behind
		-- Engaged, it stands beyond its target along the avatar's facing, turned this many degrees round toward the side it's
		-- on, so the camera frames the fight and the target doesn't hide it (research's verdict on TR2, 2026-11-12). A seed.
		Frame = 45,
		-- Against a target wider than itself it'd stand hidden behind it, so against these kinds it takes the target's side,
		-- and both read side by side from the avatar's place (research's read of TR2's closing takes, 2026-11-12).
		Beside = { Elite = 90, Keeper = 90 },
		-- Degrees off the avatar's facing within which such a target reads straight ahead: there the lead keeps the side it's
		-- nearer; past it, the side away from the avatar's line of sight, so the avatar's own body hides neither.
		Straight = 5,
		WalkSpeed = 16,
		CatchUpSpeed = 26, -- once it's CatchUpFrom away, so it keeps up with a running avatar
		CatchUpFrom = 18,
		TeleportFrom = 90, -- past this it reappears at the avatar's side
		DownSeconds = 4, -- down, then up at the avatar's side at full health, with nothing lost
		-- It heals After seconds from the last hit it took, PerSecond of its health a second, but never while a Shade is
		-- engaged with it: so it walks into the next pack whole (research's read of TR2's fixes, 2026-11-12; tier 2).
		Heal = { After = 2, PerSecond = 0.25 },
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

	-- A crowd on one Shade (research's verdict on TR2, 2026-11-12): from the From-th lead that hits it, each further lead adds
	-- Share of its health, to its most and to what it has left. A seed.
	Crowd = { From = 3, Share = 0.5 },

	-- Who flinches: a short reaction that never cancels an action (docs/design.md, "States in a fight").
	Flinch = { Seconds = 0.28, Kinds = { Lead = true, Ordinary = true, Dummy = true } },

	-- How far a push moves each body, against its Push (handbook/feel/combat.md: a heavy enemy moves less).
	Weight = { Lead = 1, Ordinary = 1, Elite = 0.4, Keeper = 0.15, Dummy = 1 },

	-- The hit's four moments (handbook/feel/combat.md, "Hit reactions and knockback"). The hold is the client's, presentation
	-- only; the server pushes once the hold is over, so the body jumps on the frame it lets go.
	Hitstop = { Light = 0.09, Heavy = 0.13 },
	-- The push: Seconds at a steady pace, on the server. Shown: each screen draws it from its own hold's end instead of
	-- waiting for the body's replica, which comes a replication delay late (AR1, section 8); Wait is the longest it waits
	-- for the replica to catch up, then it hands the body back over HandBack seconds.
	Push = { Seconds = 0.1, Shown = true, Wait = 0.4, HandBack = 0.1 },
	-- The camera, the client's: magnitude in studs, roughness a second, fade in seconds (handbook/feel/game-feel.md).
	Shake = {
		Heavy = { Magnitude = 1.6, Roughness = 14, Fade = 0.15 }, -- the player's own lead lands a heavy hit
		Hurt = { Magnitude = 0.6, Roughness = 12, Fade = 0.2 }, -- the player's own lead is hit hard (a tenth of its health)
		HurtShare = 0.1,
	},
	-- Damage numbers over the target: they rise this many studs over this many seconds. A flurry, one press's hits on one
	-- body, is one counting number (docs/ui.md, "Damage numbers"): each hit after the first counts it up to the new total
	-- over Count seconds, swelling it Pop times and settling, and its fade starts over from that hit. The builder's
	-- numbers, 2026-11-12, to tune by playing.
	Numbers = { Rise = 2.5, Seconds = 0.8, Size = 24, Count = 0.12, Pop = 1.3 }, -- Size: pixels at the phone's size (UI.Theme.Author), scaled with the screen

	-- The keeper's try (KeeperService; docs/test-requests.md, TR2, "the keeper, fought alone"). The builder's numbers, 2026-11-12.
	Keeper = {
		Hold = 0.5, -- seconds the gate's Challenge is held: a try is a decision
		Reach = 10, -- studs from the gate it can be asked
		Fade = { Out = 0.25, Hold = 0.2, Back = 0.35 }, -- the fade around each move; the move is in the middle of Hold
		-- Studs from the keeper, at the ring's middle, the avatar arrives facing it: near enough that the fight fills about a
		-- third of the frame's height (research's read of TR2's closing takes, 2026-11-12; at 34 it was a fifth).
		Arrive = 14,
		-- Degrees the avatar's facing turns off the keeper there, so its own body, near the camera, hides none of the keeper:
		-- the fight sits right of the frame's middle (the avatar 4 studs wide 12.5 from the camera, the keeper 4.2 wide).
		Turn = 26,
		WinPause = 2, -- seconds after the keeper's fall before the fade out: the fall is seen
		LossPause = 1, -- seconds after the lead's fall
		Before = 10, -- studs before the keeper's gate a loss sets the avatar down
		-- It notices its challenger anywhere in its copy (a 41-stud ring inside a fenced square: 133 corner to corner) and
		-- never gives up, so a fight at the rim can't reset it. Copies stand 600 apart.
		Notice = 140,
	},

	-- The replay (the ga-action skill): an action on a clean pad, from the player's camera, the numbers live.
	Replay = {
		Distance = 0, -- the lead stands this far beyond the dummy; 0 is the action's own spacing, where a lead fights from (Range - Approach)
		Behind = 9, -- the avatar stands this far behind the dummy and Lead.Side to its left, the lead beyond it at Lead.Frame, as in play
		Pitch = 20, -- degrees the camera looks down, over the avatar onto the fight
		Every = 3.5, -- seconds from one press to the next
		FreezeAt = 0, -- Studio: above 0, the player's own lead stops this many seconds into each press (clip, effect, sparks), to capture or study a beat; 0 is off
	},
}
