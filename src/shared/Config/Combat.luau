--!strict
-- Combat (shared Config): how a fight moves and how it's shown (docs/design.md, "Combat"). Studs are at Roblox's default
-- walk of 16 a second. The builder's numbers, 2026-11-12, from handbook/feel/combat.md and game-feel.md's starting points,
-- tuned by playing: NL_Debug:Invoke("Tune", "Combat.Hitstop.Rungs.4.Hold", 0.16) (a list's row by its number).

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
		-- Against these kinds, past Straight, the side toward the avatar's line of sight instead: a try's lead, set down on the
		-- avatar's left, never walks across the camera's line to the keeper, and the fight comes off the frame's edge
		-- (research's call on AR7's fix 4, option A, 2026-11-13).
		Near = { Keeper = true },
		-- Its walk after the avatar, whatever its Speed: Roblox's own walk, the avatar's, so every lead keeps up on the street.
		-- In a fight it walks at its Speed (TR14; Config.Stats.Speed), which replaced the one walk speed every lead had.
		FollowWalk = 16,
		CatchUpSpeed = 26, -- once it's CatchUpFrom away, so it keeps up with a running avatar
		CatchUpFrom = 18,
		TeleportFrom = 90, -- past this it reappears at the avatar's side
		-- A fall sends it home (TR12; docs/design.md, "A fall sends it home"): down Leave seconds, its fall seen, then it
		-- leaves as light and is home on its plot, on the Training machine's pad (Config.World.Grey.Training).
		Leave = 1.6,
		-- Health carries (TR12; docs/design.md): a lead heals only its Regen a second (Config.Stats.Regen), in a fight or
		-- out; on its own plot it heals from nothing to full in Home.Full seconds besides, and so does one at home that isn't
		-- out. One that fell heals from nothing to full in Home.Fallen seconds, then waits. Research's seeds, 2026-11-14.
		Home = { Full = 30, Fallen = 90 },
	},

	-- Shades (docs/test-requests.md, TR2, "the builder's read"): a pack notices a lead within 20 studs and gives up past 40
	-- from its spawn, so a fight never pulls the next pack, 80 studs on.
	Shade = {
		Notice = 20,
		GiveUp = 40,
		WalkSpeed = 12,
		ResetSpeed = 24, -- walking home after giving up, untouchable
		-- Walking home, it's stuck once it has come no Gain studs nearer for Seconds (a wall between it and home: TR7's
		-- balance batch saw a push carry one through Lantern Row's east wall), and it's set down at home. The builder's seeds.
		ResetStuck = { Gain = 0.5, Seconds = 3 },
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
	-- By the hit's rung on the importance ladder (Actions.Hit.Rung; docs/research/vfx-reference.md, rules 1 and 2), the
	-- highest row at or under it (Rules.Fight.Lever): Hold, seconds both bodies freeze; Flash, seconds the struck body
	-- glows white, from Glow (the fill's opacity at its first picture) eased out; Tremble, studs the struck body shakes
	-- inside the freeze, shrinking to nothing at its end (rung 7 and up); Trauma, the camera's added on the player's own
	-- lead's hit (Shake). A critical is at least rung Critical, and a killing hit holds at least Kill seconds, the old light
	-- hold, so the last blow lands before the burst. AR8 A, the builder's starting numbers, tuned by playing.
	Hitstop = {
		Rungs = {
			{ From = 2, Hold = 0.045, Flash = 0.06, Glow = 0.55, Tremble = 0, Trauma = 0 }, -- an ordinary hit
			{ From = 3, Hold = 0.05, Flash = 0.06, Glow = 0.6, Tremble = 0, Trauma = 0 }, -- a combo's last, the Shade's swing
			{ From = 4, Hold = 0.07, Flash = 0.08, Glow = 0.7, Tremble = 0, Trauma = 0.35 }, -- a critical
			{ From = 7, Hold = 0.13, Flash = 0.1, Glow = 0.9, Tremble = 0.18, Trauma = 0.8 }, -- a Voidkin's signature
			{ From = 8, Hold = 0.14, Flash = 0.1, Glow = 0.9, Tremble = 0.22, Trauma = 0.8 }, -- the keeper's signature
		},
		Critical = 4,
		Kill = 0.09,
		Tremble = { Rate = 45 }, -- the struck body's shake: direction changes a second
	},
	-- The push: Seconds at a steady pace, on the server. Shown: each screen draws it from its own hold's end instead of
	-- waiting for the body's replica, which comes a replication delay late (AR1, section 8); Wait is the longest it waits
	-- for the replica to catch up, then it hands the body back over HandBack seconds.
	Push = { Seconds = 0.1, Shown = true, Wait = 0.4, HandBack = 0.1 },
	-- The camera, the client's, as trauma (handbook/feel/game-feel.md; docs/research/vfx-reference.md, item 12): each jolt
	-- adds trauma, capped at 1, which falls by 1 every Decay seconds; the shake is trauma squared, so a big jolt lands and a
	-- small one barely ticks. At full shake the camera moves Studs and turns Degrees (roll, with half of it in pitch and
	-- yaw), its noise changing Rate times a second. A hit's trauma is its rung's (Hitstop.Rungs); Hurt is the player's own
	-- lead hit hard (HurtShare of its health). AR8 A, the builder's starting numbers, tuned by playing.
	Shake = {
		Decay = 0.35,
		Studs = 1.2,
		Degrees = 2.5,
		Rate = 16,
		Hurt = 0.45,
		HurtShare = 0.1,
	},
	-- A ranged lead's skip back (docs/design.md, "Combat"; TR7, part 2; research's seeds, tier 2): it skips when an enemy is
	-- inside Close studs (a Shade's swing reaches 4), it's between actions, its last skip was Every seconds ago or more, and
	-- no enemy's swing at it is winding up. It lands at its next action's range from its target, in its place in the frame;
	-- if that spot isn't clear, the nearest that is, Step degrees round the target at a time; with none clear, it fights
	-- where it stands. Clear: on the ground (Ground studs of drop at most), no wall on the way (Body studs wide), within the
	-- leash, no enemy within Close of it, and the way never nearer an enemy than Body. It travels from its start to Land.
	-- On: off for the balance check's runs without it (Tune "Combat.Skip.On"). Every 2.5 from 4 (research's verdict on the
	-- blockout, 2026-11-13: at 4 the Shade was back within half a second and the leads shot point-blank most of the take).
	Skip = { On = true, Close = 5, Every = 2.5, Step = 30, Body = 1.5, Ground = 2 },
	-- The leads' passives (Definitions.Passives; Rules.Passive): off for the balance check's runs without them.
	Passives = { On = true },
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
		-- the fight sits right of the frame's middle (the avatar 4 studs wide 12.5 from the camera, the keeper 4.2 wide). 40
		-- from 26 with the shoulder camera (TR7, the framing's verdict): the lone lantern stands in open sky beside the avatar.
		Turn = 40,
		-- Studs right of the avatar its lead is set down, and walks back to, in a try: on its left, clear of the Challenge
		-- and the fall's line (research's verdict on AR7's install, fix 1).
		Side = -3.5,
		WinPause = 2.4, -- seconds after the keeper's fall before the fade out: the fall is seen, its scraps' last included
		LossPause = 1, -- seconds after the lead's fall
		Before = 10, -- studs before the keeper's gate a loss sets the avatar down
		-- It notices its challenger anywhere in its copy (a 41-stud ring inside a fenced square: 133 corner to corner) and
		-- never gives up, so a fight at the rim can't reset it. Copies stand 600 apart.
		Notice = 140,
		-- Its own walk (research's tier 2, AR7, section 4: a master walks, it doesn't scurry): near its clip's stride at rate 1
		-- (Config.Animations.Strides.LamplighterWalk), up to 7 if a ranged lead's free hits on its approach come to more than
		-- about 1.5 s.
		WalkSpeed = 5,
		-- Seconds from its fall until the server takes its body: past the Down clip's Gone, with the longest hold and the
		-- replication's delay to spare (AR7, section 5: the server keeps the body until Gone; a logic case holds it).
		FadeSeconds = 2.1,
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
