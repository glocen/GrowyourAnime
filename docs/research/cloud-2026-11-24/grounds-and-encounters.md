# Grounds and encounters: how a small combat map stays interesting, and a frank review of Lantern Row

A cloud research session, 2026-11-24, read-only on main. Themes and world pitches are in `characters-and-worlds.md`; this note is layout, pacing, encounters, enemies and the keeper. Labels: SOURCED, COMMUNITY, OBSERVED (our repo), MEASURED (computed here), OPINION. "(snippet)" means only a search summary was read. Every number proposed is a seed to tune by playing. Every proposal waits for its tier's yes.

## The verdict, in five lines

1. **A run is shorter and emptier than its target.** On our own seeds a clean Normal run is about 5.5 to 7 minutes, not 10 to 15, and the rest can only be standing still: respawn timers, regen, the elite's cooldown (MEASURED, below).
2. **The quota is met by killing the same pack again.** Stretch 1 is four Brawlers three times with two 15 s waits. About 76% of everything killed before the keeper is a Brawler, all three elites included (MEASURED).
3. **Each stretch has an idea on paper, but no beats.** The new Shade is never met alone, nothing twists, the Guard and the Dasher never meet, and the elite never carries its stretch's idea.
4. **The Lamplighter teaches one move and repeats it 3 or 4 times.** No escalation, no midpoint, no arena. **Hard is numbers and a skin.**
5. **The frame is right and cheap to fill:** four stretches with checkpoints are a good phone unit, the mark system (circles and lines) already exists, and a Shade's row already takes its own signature and timing. Most fixes below are data and one small service change, not new systems.

## 1. Lantern Row as built (OBSERVED unless marked)

- **The street:** one straight line, 44 studs wide, about 590 long, flat; eight stops 80 studs apart at 32, 112, 192, 272 (the square, 64 across), 352, 432, 512 and 592 (the keeper's gate; ring 80 across). End to end is 37 s on foot. `src/shared/Config/World.luau`, `Row`; `Config/Kits/LanternRow/Plan.json` (271 placements of 16 pieces).

| Stretch | Stops (level) | What stands there | Quota |
|---|---|---|---|
| 1 | pack (1), elite (2) | 4 Brawlers; an elite Brawler | 10 |
| 2 | pack (3), elite in the square (5) | 2 Brawlers and 2 Guards; an elite Brawler | 10 |
| 3 | pack (6), pack (7), elite (8) | 2 Brawlers and 1 Dasher, twice; an elite Brawler | 10 |
| 4 | keeper (9) | the Lamplighter | 0 |

- **How a stretch clears:** 10 ordinary Shades fall to the player and its last stop falls (`src/shared/Rules/Stages.luau`). A pack stands again 15 s after its last Shade falls (`Row.Respawn`). The elite is shared on Normal and comes back 120 s after it falls (`Row.Back.Elite`).
- **The Shades** (`src/shared/Definitions/Enemies.luau`, `Actions.luau`, `Config/Combat.luau`):
  - Brawler: one swipe, 1.1 s long, landing at 0.5 s.
  - Guard: opens by raising a paper shield at 0.3 s and holds it to 2.3 s; 20% of a hit gets through; a heavy hit or a signature breaks it for a 1.0 s stagger; again every 4.8 s.
  - Dasher: 1.5 s after it spawns it shows a line at 0.27 s and lands at 1.25 s (a 0.98 s tell), 12 studs long and 4 wide, heavy; again every 6 s.
  - Support: designed in `docs/roster.md`, not built (the director, 11-23: it waits).
  - Elite: a Brawler at 1.35 size with about 2.7 times the health. No move of its own. Guard and Dasher elite looks are ordered (AR57); the config still uses `brawler_elite` three times.
- **The Lamplighter:** a Challenge (1.5 s), a swing every 1.6 s, and a slam first at 8 s then every 12 s. The slam's ring (radius 5) goes down at the Plant and lands 1.57 s later. In "A" mode the lead follows the avatar out. No phases, nothing keyed to its health, nothing in the ring.
- **Hard:** +10 levels; health and attack times 1.6 and 1.6 (ordinary), 2.05 and 1.5 (elite), 1.7 and 1.2 (keeper); the foes are the player's own; an ember-cracked look. Same stops, quotas, moves and timings (`Config/Enemies.luau`, `Lift`; `StageService.luau`).
- **The time, MEASURED on paper** from `docs/research/combat-math.md` (an ordinary Shade 3.6 to 5.5 s, an elite 10 to 16 s, the keeper 45 s), walking at 16 studs a second:
  - Stretch 1 about 95 s, of which 30 s is waiting for the pack. Stretch 2 about 105 s (30 s waiting). Stretch 3 about 80 s. Stretch 4 about 55 s.
  - **Total about 5.5 to 7 minutes.** Not measured in play: no logged run time was found. A lead that must rest, or an elite another player just took, adds only waiting.

## 2. The craft, and what each point means for us

**Pacing**

- SOURCED. Nintendo's four steps, in Hayashida's words: "first, you have to learn how to use that gameplay mechanic", then "a slightly more complicated scenario", then "something crazy happens that makes you think about it in a way you weren't expecting", then "you get to demonstrate... what sort of mastery you've gained" ([Game Developer](https://www.gamedeveloper.com/design/the-secret-to-i-mario-i-level-design)). `docs/research/design-holes.md`, F2, applied this across the four stretches.
  - **For us:** apply it again *inside* each stretch. A stretch is four beats (meet it alone, meet it mixed, a twist, the elite), not a count to 10.
- SOURCED. The Level Design Book: teach, test, twist, with the twist spaced out; rests "re-sensitize" the player; "start slow and quiet"; "players adjust to prolonged periods of high intensity"; "any intense boss fight will feel like a slog after 10+ minutes"; avoid a maximum-intensity finale ([pacing](https://book.leveldesignbook.com/process/preproduction/pacing)). Its tool is a beat sheet and an intensity graph against minutes.
  - **For us:** a rest is an authored beat with something to look at, never a respawn timer. Research keeps one beat sheet per ground (section 4).
- COMMUNITY (snippet). Halo's "30 seconds of fun": the cut half of Griesemer's line was that the 30 seconds are replayed across different environments, weapons and enemies ([Engadget](https://www.engadget.com/2011-07-14-half-minute-halo-an-interview-with-jaime-griesemer.html)).
  - **For us:** our 30 seconds are: step in, read the wave, choose where to stand and where to look, press the signature, step the lead off a mark. A stretch is that loop four or five times with one thing changed each time.

**Layout**

- SOURCED. Arenas "usually need gating"; a corridor gives "authorship, control, and certainty"; a "combat bowl" is a small open area with cover in the middle; a one-way drop adds height cheaply; slopes and bright light speed a corridor up, alcoves slow it ([typology](https://book.leveldesignbook.com/process/layout/typology)).
- SOURCED. The "door problem": give the player a foothold to survey a fight first. The fairest form is a vista with a one-way entrance: the enemies seen from a high point, then a short drop in ([encounter](https://book.leveldesignbook.com/process/combat/encounter)).
  - **For us:** Lantern Row is one corridor with two arenas (the square, the ring) and no height. Three kit-only changes: a **pinch** (carts narrow the street to about 20 studs where the Guards stand, so a shield matters); a **dog-leg** at the square (the keeper's gate hidden, then shown: the landmark staging of `characters-and-worlds.md`); a **4-stud step down** into the ring (a vista, a one-way entrance, and our first height). The 44-stud width is on the director's word, so the pinch is a local exception to confirm.

**Encounters**

- SOURCED. Stout: "your job is to ask your players Questions"; four archetypes at the extremes (Near, Far, Swarmer, Heavy); setups grow from one type on flat ground, to two types, to types on terrain; he rarely needed more than four or five archetypes ([Trinity 5](https://www.gamedeveloper.com/design/trinity-part-5-setups)).
- SOURCED. Palette: one type is a tutorial or a rest, two is the regular fight, three is complex and hard to read. Each type needs a unique silhouette readable at about 10 m. "The same tactic used against each type alone should work less well against mixed groups" ([encounter](https://book.leveldesignbook.com/process/combat/encounter), [enemy](https://book.leveldesignbook.com/process/combat/enemy)).
- SOURCED. Doom (2016): 16 archetypes "easy for players to understand", "combat chess" (which demon first), and **attack tokens**: an enemy asks for a token to attack and gives it back, and "each difficulty level has a different set of token counts" ([Game Developer](https://www.gamedeveloper.com/design/cyber-demons-the-ai-of-doom-2016-)).
  - **For us:** we have Near (Brawler), a blocker (Guard) and a charger (Dasher). No Far, no Swarmer, no priority target, so no encounter can ask "who first". And the player *does* have a "who first" verb nobody designs for: the lead takes what's inside 55 degrees of the camera's look first (`Config/Combat.luau`, `Lead.View`). A Support at the back is beaten by looking at it.
  - **For us:** I found no token rule in `Rules/Fight.luau` or `Config/Combat.luau` (a search, not a full read). Seed: at most 2 swings and 1 ground mark in flight per lead on Normal, 3 and 2 on Hard. That's readability on a phone, and a difficulty lever that isn't a number on a stat.

**Tells and windows**

- SOURCED. Dark Souls 3, measured by a designer: signal plus attack never under 340 ms; a bait pose 240 ms; perceive, think, act is about 100 + 70 + 70 ms; difficulty rises by shortening the signal, shortening the recovery, and sharing opening poses ([Game Developer](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3)). For Honor: a 400 ms attack leaves about 300 ms to react (snippet, [Ubisoft](https://www.ubisoft.com/en-au/game/for-honor/news-updates/9OPowoU28h2YRO8zSvw5z/testing-grounds-how-attacks-are-changing)). God of War's first Valkyrie teaches with 2 to 3 s of anticipation and one colour per answer ([encounter](https://book.leveldesignbook.com/process/combat/encounter)).
- MEASURED. Those floors assume a button dodge. Ours is a walk: react (0.3 s), walk the avatar about 7 studs clear of a radius-5 ring (0.44 s at 16 studs a second), and the lead follows at 26. That's about 0.9 to 1.0 s. The slam's 1.57 s leaves 0.6 s spare; the Dasher's 0.98 s leaves about 0.3 s.
  - **For us (seeds):** on a phone no circle of radius 5 lands under 1.2 s on Normal or 0.9 s on Hard; no 4-wide line under 0.9 s or 0.7 s. A first meeting gets 1.5 times the normal tell. One shape per answer everywhere: a circle means leave, a line means step aside.

**Bosses**

- SOURCED. Stout: a boss is a test of skills already taught, and a story in eight beats: build-up, reveal, business as usual (where anything new is taught, safely), escalation, a midpoint ("a false victory, false defeat, or transformation"), "it's ON", a kill sequence, a victory sequence ([Game Developer](https://www.gamedeveloper.com/design/boss-battle-design-and-structure)).
- COMMUNITY (snippet). Auto-battlers make bosses interesting by constraining the few inputs the player has: AFK Journey's Dream Realm bosses lock ultimates, cage a hero until allies free it, or fire a laser only the right team survives ([Prydwen](https://prydwen.gg/afk-journey/guides/dream-realm), [Dot Esports](https://dotesports.com/afk-journey/guides/snow-stomper-guide-best-team-comp-afk-journey)). Final Fantasy XIV builds whole fights from a small alphabet of floor markers: circle, line, donut, stack, spread ([wiki](https://ffxiv.consolegameswiki.com/wiki/Common_mechanics_and_markers)).
  - **For us:** our inputs are where the avatar stands, where the camera looks, and one press. A keeper is interesting when each phase asks for a different one of the three. The marker alphabet is the cheapest content we can make: `Rules.Mark` already draws a circle and a line.

**Difficulty and replay**

- COMMUNITY (snippet). Hades' Extreme Measures gives each boss new moves, a changed arena or added foes, one region per rank ([guide](https://www.trueachievements.com/game/Hades/walkthrough/7)). Diablo III raised the number of elite affixes with difficulty, 1 to 4 ([Maxroll](https://maxroll.gg/d3/resources/elite-affixes), [wiki](https://di.diablowiki.net/Boss_mods)). Blizzard on Mythic+ affixes: their purpose is "not to add difficulty but to add variety" (interview recap, [Wowhead](https://wowhead.com/cn/news/more-significant-affix-changes-coming-wowhead-interview-with-morgan-day-and-ion-343162)).
- COMMUNITY. Anime Vanguards: Legend stages run 15 waves with a boss last (a Story act's counter also reads 15); Nightmare offers three modifiers, pick one (exploding, fast, regen, shielded, split in two, champions); Challenge slots refresh every 30 minutes, daily and weekly; one mode gives 3 stars per floor ([modes](https://bloxodes.com/wiki/anime-vanguards/gamemodes), [modifiers](https://www.droidgamers.com/guides/anime-vanguards-modifiers-guide/), [Legend stages](https://www.sportskeeda.com/roblox-news/how-legend-stages-anime-vanguards)). Arise Crossover: multi-room dungeons ending in a boss, ranks E to SS, about 15 minutes to clear before it despawns, runes that change a dungeon's mobs (snippet, [Destructoid](https://www.destructoid.com/arise-crossover-dungeon-guide/)). Blox Fruits raids: five islands on a timer, quoted from 12.5 to 15 minutes (snippet, sources disagree, [wiki](https://bloxodes.com/wiki/blox-fruits/raids)).
  - **For us:** the Roblox anime field's replay answer is one map, many rule sets, a clock on the rotation. Ours is one map, one rule set, twice. A second difficulty should change what Shades *do*; modifiers are rows in a table.

**Session length**

- SOURCED. Roblox games over 1 million monthly players, August 2025 to July 2026: the median game's session is 9.8 minutes, the top 5% 16.6; the median player's is 7.28 ([GameAnalytics, summarised](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)). No mobile-only figure was found.
- SOURCED. Diablo Immortal designed activities of "one minute or three minutes or five minutes" ([TechRadar](https://www.techradar.com/news/diablo-immortal-will-be-a-mobile-mmo-developers-reveal-at-blizzcon-2021)), with dungeons reported at 10 to 15 minutes (COMMUNITY, [wiki](https://diablo.fandom.com/wiki/Dungeon_(Diablo_Immortal))). Supercell sells Brawl Stars as modes "in under three minutes" ([Supercell](https://supercell.com/en/games/clashroyale/blog/news/introducing-brawl-stars/)).
  - **For us:** a 10 to 15 minute run is longer than the median whole session on Roblox, in a game whose session also has a base, a Breaker and a shop to visit. The stretch (2 to 3 minutes, with a checkpoint) is the right phone unit. The run is the long form.

## 3. Lantern Row, frankly (OPINION on the facts above)

1. **Where it's flat:** the two 15 s waits in stretches 1 and 2, the walk between stops with nothing to read, and a keeper fight whose second half is its first half. A quarter to a third of stretches 1 and 2 is standing.
2. **Where it repeats:** pack, the same pack, the same pack, a big Brawler, three times. The Brawler's swipe is the only attack in about three quarters of the run.
3. **Does each stretch have its own idea?** Half. The mix differs (AR52), which answers the director's "varied between phase and fun" (11-23, 03:25) in content but not yet in play: a Dasher is one Shade in three, a new Shade is never met alone, and nothing combines stretch 2 with stretch 3 before the keeper.
4. **Can a role be read at a glance?** Not proven, and I doubt it. Role is a mask shape about one stud wide on one shared body; the outline's colour is spent on type. The book's test is a silhouette at about 10 m. Ours should be a 64 px black-on-grey test at 25 studs, before more masks are made.
5. **Does the keeper teach then test?** It teaches. Of Stout's eight beats it has the build-up (the gate, the doze), the reveal (the Challenge), business as usual and the two endings. Escalation, the midpoint and "it's ON" are missing. It tests the Dasher's lesson (leave a mark) and never the Guard's (when to press).
6. **Is Hard more than numbers?** No. "Much harder" (D2) is honoured by level and two multipliers. A player learns nothing new on Hard and sees nothing new but the cracks.
7. **Is 10 to 15 minutes right for a phone?** For a first clear with a fall or two and checkpoints, yes. For the run a player farms, no: once the keeper has fallen every run starts at stretch 1, so the farm unit is the whole run. Aim the clean, repeat run at 6 to 8 minutes with under 20 s of it standing still. Today's real figure is unknown; nobody has timed one.
8. **Two things to check in code:** on Normal a run can reach an elite another player took up to 120 s ago and wait for it; and `Config/Stats.luau` says poise is "read by nothing" yet, so the design's "poise first matters at the Lamplighter" has no window to open.
9. **What's good and should stay:** health carrying inside a run, the keeper as a decision, the gate between stretches, the shared square, the mark that the lead follows the avatar out of, the fall that frees a festival-goer.

## 4. Proposals

### A. A beat chart for one Normal run (about 8.5 minutes clean; seeds)

The change underneath: **a stop holds a short list of waves, not one pack on a respawn timer.** The next wave steps out of the stall fronts 2 to 3 s after the last Shade falls, with a 1 s tell (the lanterns on that stall flicker). The quota stays 10 a stretch, so the loot's fit by kills holds.

| Time | Place | Encounter | The question | Breather after | Reward |
|---|---|---|---|---|---|
| 0:00 | the gate (a vista) | none: the street's lantern line runs to the square's arch; the keeper's lantern swings over the far roofs | where am I going? | n/a | n/a |
| 0:10 | stop 1 | 3 Brawlers, backs turned at a stall | can I choose when a fight starts? | 3 s | the sure first chest |
| 0:35 | stop 1 | 4 Brawlers, two from each side | where do I stand so my lead isn't ringed? | 3 s | drops |
| 1:00 | stop 1 | 3 Brawlers, one much larger in type colour | does type matter? | the 80-stud walk, the elite seen ahead | drops |
| 1:25 | stop 2 | elite Brawler: every third swipe is an overhead with a 1.2 s wind-up and a 1.5 s recovery | do I see a wind-up? | the gate opens, a heal mark | elite chest, the dare's stone |
| 2:05 | stop 3, the pinch | 1 Guard alone, shield up, facing the player | what stops my hits? (wait, or press) | 3 s | drops |
| 2:30 | stop 3 | 2 Guards in front of 2 Brawlers | who first? | 3 s | drops |
| 2:55 | stop 3 | 3 Guards raising in turn, one always up | when do I press? | the walk into the square | drops |
| 3:25 | the square | elite Guard: a screen 8 studs wide that also covers 2 Brawlers who join at half health | break it or walk round it? | the midpoint: the square is safe, the second half in view, a heal mark | elite chest, stone |
| 4:20 | stop 5 | 1 Dasher alone, far up the street | can I step my lead off a line? | 3 s | drops |
| 4:40 | stop 5 | 2 Brawlers pin, 1 Dasher behind (as built) | can I do it while fighting? | the walk | drops |
| 5:10 | stop 6 | 2 Dashers from the two alleys, their lines crossing | where is the safe wedge? | 3 s | drops |
| 5:35 | stop 6 | 1 Guard in front, 1 Dasher behind it, 2 Brawlers | both lessons at once | the walk | drops |
| 6:05 | stop 7 | elite Dasher: three lines in a fan, then 1.5 s out of breath | can I wait for my opening? | the keeper's gate: the music thins, the Lamplighter dozing below the step, a heal mark; in or home? | elite chest, stone |
| 7:00 | the ring | the Lamplighter, three phases, about 80 s | everything, one input at a time | the street relights back to the gate | keeper's chest, the shortcut |

Heal marks and "every run starts at full health" are `design-review.md`'s proposal; they touch the director's health words, so they're tier 3.

### B. Shade roles: six, read by body shape, not by mask alone

| Role | One-line behaviour | Silhouette, in words | State |
|---|---|---|---|
| Brawler | walks up and trades hits | a square: wide stance, fists low, round mask | built |
| Guard | holds a screen up, then tires | a tall rectangle beside the body: a folded paper screen carried on one arm, even when lowered | built; the screen is the proposal |
| Dasher | shows a line, lunges down it | an arrow: a low crouch, a sash twice its length trailing flat behind | built; the sash is the proposal |
| Support | shields and mends one other, and is fragile | a thin T: upright and still at the back, a pole with a round paper fan above its head, a thread of light to whoever it covers | designed, waits [D, 11-23] |
| Lobber (new) | stays back and arcs a slow shot onto a marked circle of radius 3, 1.2 s | lopsided: one arm cocked high, three paper balls on a cord at the hip | proposal |
| Stray masks (new) | five masks with no wearer drift in at knee height, each weak, all at once; one area hit clears them | a loose low flock, nothing above the knee | proposal |

- The props are attachments on the one rig. That's inside AR52 and AR57's kind of work, but `docs/roster.md`, "The look", records the director's word that the Shade and the Lamplighter "stay as they are until an overhaul much later": confirm props aren't an overhaul.
- The swarm is bodiless on purpose. A Shade at 0.6 size would read as a child, and hitting it would be a rule-4 doubt.
- Role names shown to players and "Stray masks" need the `docs/ip-list.md` check. Elites become a role plus one move of their own, never a size alone.

### C. The Lamplighter in three phases (about 80 s on Normal; seeds)

| Phase | Its health | What it does | The tell | The window | Which input |
|---|---|---|---|---|---|
| 1, the lesson | 100 to 70% | the swing; the slam every 12 s (as built) | 1.57 s, radius 5 | the lantern sticks in the street 1.5 s: hits land harder (poise, once it's read) | stand |
| midpoint | at 70% | 2 s, untouchable: it lights the ring's six posts one by one | n/a | n/a | n/a |
| 2, the street lights | 70 to 35% | the posts drop pools of light (radius 4) round the ring in order, 1 s apart; the slam is double: the second lands where the avatar stands 0.9 s after the first | 1.2 s each | 2.0 s after the second slam | stand, moving |
| false ending | at 35% | its lantern goes out, it kneels, the ring goes dark for 1 s, then relights violet | n/a | n/a | n/a |
| 3, it's on | 35 to 0% | the lantern on its pole sweeps a 120-degree line over 1.6 s; 2 Brawlers answer its stamp, once; the slam at 1.2 s | 0.9 s before the sweep starts | 2.0 s after the sweep | look (the adds or the keeper), and press (the signature clears the adds or breaks its poise) |
| the kill | n/a | the mask falls, an old lamplighter blinks, and relights the real lanterns back down the street | n/a | n/a | n/a |

- Hard keeps the three phases and adds rules, not only numbers: phase 1 lasts to 85%; a slam leaves a pool that burns 6 s; the posts light two at a time; the sweep goes there and back; tells at the Hard floors of section 2.
- 80 s is above the 45 s the keeper's health was solved for, and inside the 45 to 75 s band `docs/balance.md` gives keepers, near its top. It's a balance number: tier 2. Phase 1 is today's fight unchanged, so the blockout only adds.

### D. Six cheap run modifiers (data on today's systems; after the scope freeze)

1. **Lights out:** the street's lanterns dim to a third; marks and masks stay lit. It changes what you read, and the night kit does the work.
2. **Paper wind:** every 10 s a gust crosses the street for 2 s and pushes leads 6 studs downwind, into or out of marks.
3. **Second masks:** the last Shade of each wave leaves a flock of Stray masks.
4. **Crowded street:** the next wave arrives when the current one is half down.
5. **Escort:** every wave gains one Guard, and each elite a Support.
6. **The clock:** a run timer and a grade at 6, 8 and 10 minutes.

- **How:** one modifier a day for everyone, drawn on the Unix day the way the shop draws its stock; on Hard the player may add up to two. Each one kept pays forge stones on the run's card, as dares do. Never sold, never random for Robux.
- It grows "a pool of dares per stretch", which `docs/design.md` lists as "Not at launch": scope, tier 3.

### E. The ground brief: one page before any ground is built

1. **The arc and the feel line:** one sentence from the player's camera.
2. **The verb:** the one thing this ground teaches that the last didn't (Lantern Row: leave a mark).
3. **The landmark:** what's seen from the gate, where it's hidden, where it returns.
4. **The path:** a top-down sketch with studs: length, widths, each pinch, each arena's size, each change of height. Seconds on foot between beats: 5 at most without something to read.
5. **The beat sheet:** section A's table, with an intensity mark from 1 to 5 for each row.
6. **The palette:** at most three roles new or changed, each with a silhouette line and where it's met alone, mixed and twisted.
7. **The elites:** one for each stretch, each its stretch's role plus one move.
8. **The keeper:** its eight beats, its phases with tells and windows, which input each phase asks for, and its Hard rules.
9. **Time targets:** first clear, clean repeat, seconds standing still (under 20).
10. **The kit list:** pieces reused, pieces new, triangle and light budget against Lantern Row's 125,690 triangles and 10 lights.
11. **The markers** code will read, and what Hard and each modifier change.
12. **The two types it leans on,** and which Voidkin that favours.
13. **Checks before building:** the IP list for every name, the content check, the silhouette test at 64 px.

## What changes a confirmed decision

- A clean run of 6 to 8 minutes against D2's "a Normal clear takes 10 to 15 minutes" (and the loot fitted to it): **the director's yes.**
- Heal marks and full health at a run's start: the director's health words of 11-14. **The director's yes.**
- Props on the Shade: against "stay as they are until an overhaul much later" (a line about looks). **Confirm with the director.** The Lamplighter's phases add moves and block clips, not a new look.
- Modifiers: "Not at launch". **The director's yes,** after the freeze.
- Doing any of this now: the director's order of 11-23, 00:05, puts the Festival after the main map and the systems. **The order is the director's.**
- Not changed: one mission per Arc, four stretches, checkpoints, Normal and Hard on one map, keepers fought alone, the 44-stud street outside one pinch.

## Top 5 to act on

| # | What | Who | Cost | Needs the director's yes? |
|---|---|---|---|---|
| 1 | **Time one clean Normal run on a phone, then settle the length.** Log each stretch's seconds fighting, walking and standing. Until then "10 to 15" is a wish. | the builder, with `StageBegin` | 30 min | the measuring no; changing D2 yes |
| 2 | **Waves in place of the respawn quota:** a `Waves` list per stop, the next wave 2 to 3 s after the last falls, each new Shade met alone first. Section A's chart is the seed. | research writes the lists (2 h); the builder, `Config.World.Row.Stops` and `PackService` (4 to 6 h) | about 1 day | tier 2; the order of work yes |
| 3 | **Each elite is its stretch's role with one move of its own** (the overhead, the wide screen, the fan of lines). The looks are already ordered (AR57). | the builder through `/ga-action`, 3 blocks of 90 min; Modulo, 3 block clips | about 1 day | tier 2 |
| 4 | **The Lamplighter's phases 2 and 3 in grey,** on the circle and line `Rules.Mark` already draws, judged in motion before any art. Name it a signature piece at its feel line. | research (the feel line, the verdict); the builder (6 to 8 h); Modulo (2 block clips) | 1.5 days | tier 2: the fight's length is a balance number |
| 5 | **Hard changes behaviour:** one rule per role as Hard rows in `Definitions/Enemies.luau` (Guards raise in turn, Dashers lunge twice, 2 marks in flight where Normal allows 1), then the 64 px silhouette test and the ground brief before ground 2. | the builder (3 h); Modulo (the silhouette sheet, 2 h); research (the brief, 1 h) | about 1 day | tier 2; the props, confirm |

## Not fetched, and limits

- The GDC talks themselves (Doom's "push forward combat", God of War's combat) and Griesemer's full quote: only write-ups and snippets.
- No primary Blizzard line for Diablo Immortal's 10 to 15 minute dungeons; no mobile-only Roblox session figure; no per-genre mobile session table.
- World // Zero, Dungeon Quest and Anime Fighters' trials: nothing usable found. Anime Vanguards' minutes per act: not found (only the 15 waves).
- Hades, Diablo III, Final Fantasy XIV and AFK Journey points come from wikis and guides, not from their developers.
- Nothing here was played. The run's time is arithmetic on seeds, not a measurement of play.
