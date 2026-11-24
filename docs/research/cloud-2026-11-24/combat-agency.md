# What the player does in an automatic fight, and how to make ours feel great

A cloud research session, 2026-11-24. It answers `design-review.md` challenge 3 and `state-of-the-game.md` ("the player only watches"). Read-only on main; every proposal waits for its tier's yes. Labels: SOURCED, COMMUNITY, OBSERVED, MEASURED, OPINION. Numbers are seeds to tune by playing.

## The verdict

1. **Today the player decides nothing inside a fight.** The one press we built (TR52) ships with Auto on, and Auto fires the signature the moment it's ready, so in the default mode the ring never waits for a thumb. OBSERVED.
2. **The games that solve this do three things:** the companion's big move waits for the player, the enemy shows a tell the player can answer with one press, and a good answer feeds the big move. Pokémon Legends Z-A, Zenless Zone Zero and Xenoblade all work this way. SOURCED.
3. **We already built two of the three parts and never joined them:** the signature on a tap (TR52) and the Recall dash (TR44's mode B, keeper only). The join is missing: a dodge that opens the enemy, and a signature that pays for landing in that opening.
4. **The proposal: "slip, then strike".** Two round buttons by the right thumb. Call pulls the lead to your side out of a marked strike. A strike slipped on purpose leaves its attacker Open and tops up the ring. A signature that lands on an Open enemy is a Finisher. Auto stays, and is the weaker way to play.
5. **Cost: two blocks of about 90 minutes** on rules that are mostly written. Shipping it needs the director's yes: it brings manual signatures into launch and changes "the player steers by standing".

## 1. Our fight today, precisely

**The player can** (all OBSERVED):
- Walk. The lead fights what's within 30 studs of the avatar and follows past 6 (`src/shared/Config/Combat.luau`, `Lead.Leash`, `Lead.Follow`).
- Turn the camera. The lead takes enemies inside 55 degrees of the camera's look first (`Lead.View.Arc`). Nothing on screen says so; I found no in-world mark on the lead's target in `src/`.
- Leave: one more pack or home, since health carries and a burst heals about 1 to 2% every 8 s (`docs/design.md`, "Combat").
- In TR52's block only: tap the signature's ring when it's full, with Auto off (`Rules.Fight.Tap`, `FightService.Tap`). Waiting on the director's run since 11-23.
- In a keeper's try only, by a debug switch: Off, A (the lead follows a 2-stud move out of the ring) or B (a Recall button: dash at 40 studs a second, hold 1 s, cooldown 4 s). The config's default is A (`Config.Combat.Keeper.Out`). The Dasher's line uses the same switch (`Definitions/Actions.luau`, `DasherLunge`).

**The player can't:** pick a target, dodge, guard, swap the lead in a fight (confirmed: "Lead and Regalia can't change while in combat"), spend anything, or be hit. The avatar "is never a target and never deals damage".

**What the numbers say** (MEASURED from `Definitions/Actions.luau` and `Config/World.luau`):
- Every signature has the same 10 s cooldown and no resource. Rook's combo is 3.2 of coefficient every 1.8 s, and Haymaker is 4.0 every 10 s. So the signature is about 18% of a lead's output (0.4 of 2.18 a second).
- After a tap, Haymaker's hit is 0.82 s away (Charge 0.13 to Strike 0.95), plus the round trip (147 ms in Studio, TR52). "Fires at once" is about 1.1 s to impact.
- The windows we give are shorter than that. A Dasher's back is open 0.8 s (Land 1.25 to Close 2.05). The Lamplighter's recovery is 1.07 s. A player who reacts to the opening can't land Haymaker in it.
- A Dasher's line shows 0.98 s before it lands (Line 0.27 to Land 1.25). A phone player needs about 0.35 s to react, 0.15 s of round trip and 0.1 s of dash: 0.6 s. That leaves 0.38 s of slack. Fine in Studio, thin on mobile data.
- Stage 1 is four Brawlers, then a bigger Brawler. No enemy in the first three minutes asks for a press. Those are the minutes Roblox's Home judges (`retention-and-discovery.md`).

**Frank critique** (OPINION unless marked):
- **The default hides the verb.** Auto on, firing instantly, is what a new player meets. HSR's auto does the same and its players call it wasteful [6]. A full ring must wait for the player in the default mode.
- **The ring stands under the walking thumb** (top left, under the lead's card). Research's read of TR52 already says so. The right thumb has a free field above the jump button. OBSERVED.
- **A tap cuts the combo "wherever it is".** That reads as an interruption. Anime reads as jab, hook, ram, then the big one.
- **Poise is designed as "the fight's payoff" and read by nothing** (`Config/Stats.luau`, line 96). OBSERVED.
- **A pack swings together.** Hitting one Shade turns its whole pack (`FightService`, `packHit`), and four cost "about ten times one" (`docs/research/combat-math.md`, item 3). Damage arrives as a wall nobody can read or answer.
- **Mode A makes the dare test the leash.** The player moves a body that can't be hit so that a body that can be hit walks after it at 26 studs a second. Z-A ships that same rule and its own guides tell players to stand close and recall instead [1].
- **A word to the director, since they invited it:** "simply do not touch player camera" (11-14) is kept in everything below. Its cost is real: most anime action energy in the reference games comes from camera cuts. With the camera frozen, the energy has to come from hitstop, sound and the screen's own layer. That is doable, and it is why the Finisher below is built from those three.

## 2. How other games do it

Read in full where marked "read"; the rest are from search summaries of the page, and say so.

**Pokémon Legends Z-A (2025): the closest game to ours.** SOURCED [1] (read), [2] (summaries).
- The trainer walks freely. "You can't control them directly, but they will follow your movements." Moves are on cooldowns, not a resource. There is no dodge order: you move, and it comes with you if you give it time [2].
- Against wide attacks the advice is to recall it "for a few seconds". Locking on to give orders slows the trainer and blocks the roll, so offence and safety trade against each other.
- Every 3 to 10 s the player decides: which move is off cooldown, stay locked or let go, walk it out or recall.
- Reviews praise the speed and the thinking it forces. Nintendo Life's review, as summarised, finds the fights at times "a little too chaotic and hard to track".
- **For us:** our leash is a proven rule, but only with a prompt follow, big tells and an explicit recall. Their weak point is ours too: steering through a follow is indirect. Take the recall as a first-class button. Touches `Config.Combat.Keeper.Out`, `SlamController`.

**Xenoblade Chronicles 1 to 3: auto-attack as the metronome.** COMMUNITY [3] (read), [4].
- Auto-attacks fire only while standing still, in a fixed three-hit chain worth 50, 80, 120. The player's arts are the decisions.
- **Cancelling:** using an art as an auto-attack lands gives more gauge: 3/8, 1/2 or 5/8 of a segment against 1/4 without. In XC3 the window is about 60 to 75% through the swing, and a gem widens it by 20%. It's a timing press on a rhythm that plays anyway.
- **Positionals:** Back Slash deals double from behind. Slit Edge from the side cuts defence by half, and the icon shows a mark when you stand right.
- **Break, Topple, Launch, Smash:** a fixed order; Topple and Launch last 5 s each and add 25% and 50% party damage. The whole party aims at one window.
- **Visions (XC1):** a lethal enemy art shows its name, target, damage and an 8 s countdown. The player answers by shielding, toppling or warning an ally. A tell with a named answer.
- **For us:** the lead's combo is our metronome (0.9, 0.9, 1.4 is the same rising shape). The cancel is the runner-up below. The Break chain is what our unbuilt poise bar is for. Positionals are out: a virtual stick is too coarse and the lead picks its own place (`Lead.Frame`).

**Zenless Zone Zero: defence feeds offence.** COMMUNITY [5] (summaries).
- Hits fill an enemy's Daze bar. Full, it's stunned, and a heavy hit starts a Chain Attack. Swapping just before an enemy's hit lands is a Perfect Assist: a parry that adds a lot of Daze.
- Reviews split: one calls it "extremely stylish" and "super responsive"; others call it repetitive, and PC Gamer gave it 55.
- **For us:** the loop "answer the tell, get the opening, spend the big move in it" is the one to take. The warning: with one enemy type it repeats fast. Ours needs F2's four stretches to stay different.

**Honkai Star Rail, AFK Journey, Anime Vanguards: the burst waits for you.** COMMUNITY [6][7][8] (summaries; [7] read).
- HSR: a full ultimate can be fired at any time, even inside an enemy's turn. Auto fires an ultimate as soon as it's available (healing ones excepted), and players complain it wastes them. A setting stops auto from using ultimates.
- AFK Journey: a manual ability slows time so the player can place it. Guides say to switch to manual when stuck.
- Anime Vanguards: units have active abilities fired by hand. Update 0.5 added an "On" switch over a unit that fires its ability when ready. The game the director pointed at is manual first, with auto added for routine play.
- **For us:** a burst is a decision only when a better moment is visible and holding has a cost. Auto must be the convenient way, never the best way. Touches TR52's Auto toggle.

**Final Fantasy XII gambits: the decision moved out of the fight.** SOURCED [9] (read).
- The team wanted to spare players picking "commands for every single one" of four fighters. The lasting criticism, in the retrospectives a search returned, is that strategy moved into preparation and out of the battle.
- **For us:** our build system (pillar 2) already is the preparation layer. It doesn't excuse an empty fight. Don't add scripting.

**Ni no Kuni Cross Worlds and Taichi Panda: what auto costs.** SOURCED [10] (summaries); `taichi-panda-study.md`.
- GameSpot's headline: an MMO "that mostly plays itself". Twinfinite: auto adds "soullessness". Siliconera: manual dodging is "a chore" that auto removes.
- **For us:** auto failed there because it did the player's verbs better than the player. Our Auto must never Call, and must spend the signature worse than a thumb would.

**Gears of War's active reload and Hades' Call: one press, made interesting.** COMMUNITY [11][12] (summaries).
- Active reload: a timing press inside an action that happens anyway. A hit is faster and stronger; a miss is slower than not trying. Bleszinski called the damage boost in multiplayer a mistake: fire, reload, bonus was cheap.
- Hades: the gauge fills by dealing and by taking damage. One slice buys a small Call; a full gauge buys a far stronger one.
- **For us:** reward a timed press with tempo (cooldown back), not damage, so nothing stacks (`docs/balance.md`). The Tower's fights get no presses, so the Clash stays build against build.

**Roblox: commanding a unit.** COMMUNITY [13] (summaries).
- Arise Crossover: you order your shadows onto the enemy you want at any time, and recruiting a beaten enemy is a hold inside a short window after the kill.
- Blade Ball: one block button, pressed just before the ball arrives. A whole game on one timed press, played on phones.
- I found no reliable write-up of Anime Fighters Simulator's or Pet Simulator 99's targeting, so neither is used here.
- **For us:** Roblox's phone players handle a timed press. One or two buttons is inside what this audience already plays.

## 3. The design space

| Kind of agency | A decision every | Cost on a phone | Build cost for us | Call |
|---|---|---|---|---|
| Time a burst (HSR, Vanguards) | 10 s | one tap; reads as a ring | built (TR52) | take |
| A defensive call (Z-A's recall, ZZZ's assist) | 4 to 8 s, when enemies show tells | one tap; needs tells that read small; latency matters | built for the keeper (TR44, B); about 1 h to open to every fight | take |
| An opening to hit (Break, Daze) | 15 to 30 s | no new input; a cue on the enemy | from slips: about 2 h. From poise: 6 to 8 h and a balance pass | take the first, poise later |
| A timed press on the auto rhythm (cancel, active reload) | each combo, 2 s | one tap; 150 ms of delay can feel unfair | about 90 min | runner-up |
| Positioning (Z-A, positionals) | always | the left stick; coarse | exists (the leash, A) | keep as the soft layer, never the test |
| Targeting (Palworld, Arise) | each pack | tapping a moving body in 3D is hard; a "next" button costs a slot | about 3 h | not now; show the target instead |
| A resource to spend (Hades) | 10 to 20 s | a second gauge on a quiet HUD | medium | later; the refunds below are the light form |
| Swap the lead (ZZZ, Z-A) | 10 to 20 s | a tap on a portrait; reads best of all | high: reverses a confirmed decision, needs clips for two or three leads | not for launch |
| Program it before (gambits) | once a build | menus | we have the build | don't add |

OPINION, from section 2's sources and our code.

## 4. The proposal: slip, then strike

Working words only: **Call**, **Open**, **Finisher**. Research writes the real ones, and each needs the IP-list check.

**Feel line:** a Dasher's line opens under your fighter; you thumb Call and it snaps back to your side as the lunge tears past; the Dasher skids with a cracked ring around it and your ring lights; you press it, and the signature lands on its open back with a freeze you feel in your hands.

**The rules:**
1. **Call**, in every fight. One press: the lead breaks its combo and dashes to its place by the avatar (TR44's B as built: 40 studs a second, cooldown 4 s). It isn't untouchable: a dash that ends inside a mark is hit.
2. **A slip.** A marked strike that misses a lead because of a Call pressed inside its tell. The server already tells these apart (`Rules.Mark.Purpose`: on purpose or by accident). A slip leaves the attacker **Open** for 2.0 s, adds 30% to the ring, and ends the lead's hold so it goes straight back in.
3. **The signature on a tap** (TR52), with the ring over the jump button. A signature whose hit lands on an Open enemy is a **Finisher**: a hitstop row of its own, a longer throw, and 30% of its cooldown back. No damage is added. A raised Guard broken by a signature counts as one too.
4. **Auto on waits 3 s for a thumb**, then fires. Auto off waits for good. Auto never Calls.

**The beats, with a Dasher** (seeds; t from the line appearing):

| t (s) | What happens | Lever |
|---|---|---|
| 0.00 | the line opens on the street; the Dasher is dead still | anticipation (built) |
| press | Call squeezes on the frame; a dry snap; a flash at the lead's feet, drawn on the client | response before the server answers |
| +0.15 | the lead breaks off and dashes 8 to 12 studs in 0.2 to 0.3 s; one streak from where it stood to your side, fast in, eased out | speed; one hero shape |
| 0.98 | the lunge lands on empty stone: dust and a skid | the miss is shown |
| 0.98 | slip: a 0.06 s white flash on the lead, a rising two-note chime, the ring jumps by 30%, the cracked ring closes around the Dasher | confirmation |
| to 2.98 | Open: a soft tick each 0.5 s as the ring closes | a clock by ear |
| tap | the ring squeezes; the signature starts its own clip (Haymaker: 0.82 s to the hit) | anticipation |
| hit −0.10 | the other fight sounds drop 6 dB | the hush before the hit |
| hit | Finisher: hold 0.18 s (a signature's is 0.13 today), tremble 0.3 studs, flash 0.1 s, trauma 0.8, a 0.08 s flash at the screen's edges; the ring restarts 30% full | hitstop; the one strong shake |

- **Camera:** nothing but the shake the director kept. The edge flash and any cut-in are on the screen's layer.
- **A cut-in** (a strip of the lead's eyes across the top third for 0.25 s, on a Finisher only) is the anime moment, and it waits: art for each Voidkin, and the director's eye on a quiet HUD.
- **Sound:** four new cues (the Call's snap, the slip's chime, the Open tick, the hush), Sonus's shortlist and the director's ear on TR42's panel.

**Input:**
- **Phone, landscape:** an arc round Roblox's jump button, which stands at 655,253, 70×70 on the 750×401 simulator (TR52's measure). The ring is over it at 658,177 (`Config.Hud.Readout.At = "Jump"`, built). Call is left of it at about 585,260, 56×56. Both are the right thumb's, so the left keeps walking. `devforum-ui.md`, tip 7, gives the same rule.
- **Gamepad:** Y for Call (built), X for the signature (seed). **Keyboard:** R for Call (built), Q for the signature (TR52's seed).

**Why it stays fair:**
- **The server decides everything:** whether the ring was full, whether Call was ready, whether the strike missed, whether the target was Open at the hit's beat. All of it is pure Luau beside `Rules.Fight.Tap` and `Rules.Mark`, with logic cases. The client only draws.
- **The reward is bounded.** MEASURED: the signature is 18% of output, so a refund on every single cast adds about 8% at most. Slipping every lunge is already priced: "one that misses, less" (`Actions.luau`, `DasherLunge`).
- **Skill buys run length, not loot.** Less damage taken means one more pack before home (health carries). Drops don't change.
- **Parked play still works.** Auto clears packs at its level on Normal as it does today. Dares, Hard and keepers ask for hands, which is what a dare is.
- **No presses in the Tower or the Clash.**

**The 90-minute block (block 1):** switches on what's built.
- Call shown in every fight, with the A, B and Off switch live.
- The ring at "Jump" by default, and Auto's 3 s wait.
- One debug read-out per fight: Calls, strikes missed on purpose and by accident, taps, seconds a full ring waited, damage taken, clear time.
- **Waits:** block 2 (slip, Open, Finisher: about 90 minutes more, in grey, reusing the Guard's stagger look); all art and sound; the Tower.

**How we'd know:**
- **The naming test:** after one run, the player names a choice they made in the last minute (`taichi-panda-study.md`, Avoid 1).
- **Presses:** one every 4 to 10 s in a fight. My estimate from the stops' data: stage 1 about one in 10 s, stage 3 one in 4 s, the keeper one in 5 s. Under one in 20 s it's still a screensaver; over one in 2 s it's a chore.
- **Misses on purpose are 70% or more** of missed strikes (TR44's own question).
- **The ring waits.** If every tap comes within 0.5 s of full, nobody is timing anything and Open doesn't read.
- **Hands against Auto,** same build, stage 3: hands finish with 15 to 30% more of the bar. Equal means decoration. If Auto can't clear, routine play now needs hands, and the directive forbids that.
- **Call on cooldown against Brawlers must clear slower** than not calling, or it becomes a chore that wins.
- The director's run first, then three first-time players the director picks, privately and silently.

**Cost and the yes:**
- **Faber:** block 1, 90 minutes; block 2, 90 minutes to 3 h. **Research:** two verdicts, the words. **At the finish:** Scintilla (streak, Open ring, edge flash), Sonus (four cues), Modulo (the Call's button, cut-ins).
- **Tier 1:** both blocks. **Tier 2:** the seeds (Open 2.0 s, 30%, the 3 s wait) and a longer line for the Dasher.
- **The director's yes (tier 3):** manual signatures in launch (`docs/design.md`, "Out of launch"); Call in every fight, which rewrites "the player steers by standing" and settles TR44's pick as B; Auto's new default; any cut-in.

### The runner-up: one button, released on the third hit

- **What:** no Call. Marks are escaped by walking (mode A). The ring flashes as the combo's third hit lands, and a tap within 0.35 s chains the signature off it: the same Finisher feedback and 20% of the cooldown back. It is Xenoblade's cancel, as our own rule.
- **For:** one button. It works against Brawlers, so stage 1 gets a skill. The fight reads as jab, hook, ram, signature. About 90 minutes.
- **Against:** it leaves the leash as the only defence, so stages 3 and 4 still test the follow. A 0.35 s window with 150 ms of delay will feel unfair on a bad connection; the server has to judge by arrival time with a grace.
- **Its place:** a third layer on the proposal once that is proven, not a replacement.

## 5. Eleven cheap feel wins for the auto fight

1. **Swings on tokens.** At most one Shade per lead winds up at a time (two on Hard). The rest circle. In the melee games Vossen studied an enemy attacks "every two-to-three seconds on average", never two at once [14]; the token pattern is DOOM 2016's [15]. *For us:* a pure rule in `Rules.Fight`; the Shades' Attack is solved again with research. Tier 2.
2. **Show the lead's target.** A thin ring under its feet in its type's colour. The camera already picks the target (`Lead.View`); the player should see it. OPINION, after Arise's and Palworld's "attack that enemy" [13].
3. **The lead itself shows "ready".** A glow at its hands when the ring is full. The eye is on the fight, not a corner. Doom Eternal marks a staggered demon with a glow for the same reason [16]. Scintilla.
4. **A glint before an ordinary swing.** 0.3 s on the mask before it lands. Tells are what make a hit feel fair, and stronger attacks get plainer ones [14]. It also gives Call a use in stage 1.
5. **One mark at a time on a lead.** WildStar's telegraphs were loved in small fights and became "a technicolour wash" in crowds [17]. The hit resolves as the fill completes, as FFXIV does [18] and TR44 already does.
6. **No marked strike from out of view.** In the games Vossen studied, enemies rarely attack from off screen [14]. We already receive the camera's look (Net "View"): a Dasher outside it waits or circles.
7. **The lock says how to open it.** A raised Guard shows the ring's own glyph over its shield. An enemy that falls to one mechanic only has to say so plainly [14].
8. **A rising three.** The class's M1 sound steps up in pitch across hits 1, 2, 3, with the third on the heavier hold (rung 3 exists). Xenoblade's chain is 50, 80, 120 [3]. Sonus. OPINION on the pitch.
9. **Save the shake.** A critical adds 0.35 trauma (`Hitstop.Rungs`, From 4) and criticals are common, so the camera ticks all fight. Seed 0.15; the Finisher keeps 0.8. OPINION: a shake that fires all fight stops meaning anything.
10. **Your press, your number.** Damage from a tapped signature carries the ring's glyph, so the player sees what their thumb did. OPINION, after Koster in `docs/research/design-holes.md`, H1.
11. **A beat for the pack's last fall.** The last Shade's fall holds 0.2 s, then one chime, and the drops leave together. The kill's hold exists (`Hitstop.Kill` 0.13). OPINION.

## Top 5 to act on

| # | What | Who | Cost | The director's yes? |
|---|---|---|---|---|
| 1 | **Block 1:** Call in every fight, the ring over the jump button, Auto waits 3 s, the read-out. Then the director's one sitting covers TR52, TR44 and this | Faber builds, research reads | 90 min | no for the block (tier 1); yes to ship |
| 2 | **Block 2:** slip, Open, Finisher, in grey, with logic cases | Faber | 90 min to 3 h | no for the block; yes to ship (tier 3) |
| 3 | **Swings on tokens,** and the Shades solved again | Faber and research | about 2 h and a sim run | no (tier 2, balance) |
| 4 | **Tells a thumb can answer:** the Dasher's line at 1.2 s or more on Normal, Open at 2.0 s, a glint before swings, nothing marked from out of view | research's seeds, Faber | about 2 h | no (tier 2) |
| 5 | **Say what the press did:** the target ring, the lead's ready glow, the press's number, the shake saved for the Finisher, four cues | Scintilla, Sonus, Faber | about a day across three seats | no (tiers 1 and 2); the cut-in waits for the director |

## Sources

Fetched and read: [1], [3] (first 100k characters), [4] (Vision), [7], [9], [14], [15]. From search summaries only: the rest. Not fetched: Bulbapedia's Z-A battle page, Destructoid's Bleszinski piece and a Medium essay on auto-battle (all HTTP 403); no video was watched.

- [1] Nintendo Life, Z-A battle tips: <https://www.nintendolife.com/guides/pokemon-legends-z-a-battle-system-beginner-tips-how-to-become-a-pokemon-battling-pro>
- [2] Sportskeeda, Z-A combat guide: <https://www.sportskeeda.com/pokemon/pokemon-legends-za-complete-combat-guide>; Nintendo Life's review: <https://www.nintendolife.com/reviews/nintendo-switch-2/pokemon-legends-z-a-nintendo-switch-2-edition>
- [3] Xeno Series Wiki, auto-attack (XC2): <https://www.xenoserieswiki.org/wiki/Auto-attack_(XC2)>; Back Slash: <https://www.xenoserieswiki.org/wiki/Back_Slash_(XC1)>; Slit Edge: <https://nintendo.fandom.com/wiki/Slit_Edge>; Twinfinite on Driver Combos: <https://twinfinite.net/guides/xenoblade-chronicles-2-battle-system-explained-everything-need-know/2/>
- [4] Xeno Series Wiki, Vision: <https://www.xenoserieswiki.org/wiki/Vision>; XC3 cancels: <https://www.gamepressure.com/xenoblade-chronicles-3/canceling-attacks-how-to-do-it/z9101d3>
- [5] Game8, ZZZ combat: <https://game8.co/games/Zenless-Zone-Zero/archives/435715>; PC Gamer's review: <https://pcgamer.com/games/rpg/zenless-zone-zero-review>
- [6] HSR wiki, Auto-Battle: <https://honkai-star-rail.fandom.com/wiki/Auto-Battle>
- [7] Pocket Gamer, AFK Journey combat: <https://www.pocketgamer.com/afk-journey/combat-guide>
- [8] Sportskeeda, Anime Vanguards update 0.5: <https://www.sportskeeda.com/roblox-news/anime-vanguards-update-0-5-slayer-s-corp-new-game-mode-raid-shop>
- [9] Game Developer, FFXII's gambits: <https://www.gamedeveloper.com/design/why-i-final-fantasy-iv-i-was-key-to-i-ffxii-i-s-ai-driven-gambit-system>
- [10] GameSpot on Ni no Kuni Cross Worlds: <https://www.gamespot.com/articles/ni-no-kuni-cross-worlds-is-a-robust-mobile-mmo-that-mostly-runs-itself/1100-6503785/>; Siliconera: <https://www.siliconera.com/ni-no-kuni-cross-worlds-falls-into-mobile-game-tedium/>
- [11] Giant Bomb, active reload: <https://giantbomb.com/wiki/Concepts/Active_Reload>
- [12] Gamepressure, Hades' Call: <https://www.gamepressure.com/hades/call-how-does-it-work/z3ec5f>
- [13] Sportskeeda, Arise Crossover: <https://sportskeeda.com/roblox-news/arise-crossover-a-beginner-s-guide>; Dot Esports, Blade Ball: <https://dotesports.com/roblox/news/roblox-blade-ball-how-to-play-tips-and-tricks>; Gameskinny, Palworld: <https://www.gameskinny.com/tips/palworld-how-to-control-pals-in-your-party/>
- [14] B. Vossen, "Enemy design and enemy AI for melee combat systems", Game Developer, 2015: <https://www.gamedeveloper.com/design/enemy-design-and-enemy-ai-for-melee-combat-systems>
- [15] StraySpark, attack tokens: <https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair>
- [16] PlayStation Blog on Doom Eternal: <https://blog.playstation.com/?p=220711>
- [17] PC Gamer, "Why I love WildStar's telegraphs": <https://www.pcgamer.com/why-i-love-wildstars-telegraphs>
- [18] FFXIV wiki, AoE markers: <https://ffxiv.consolegameswiki.com/wiki/AoE_marker>
