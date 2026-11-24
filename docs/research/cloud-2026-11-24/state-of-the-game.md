# State of the game, 2026-11-24: where it stands against the vision, and how to take the wheel back

A producer's audit. It's read-only, from `main` at `1e282f7`. The checkout is shallow: it holds the last 202 commits, from 2026-11-19 to 11-24, and older history comes from the docs' own counts. Labels: **OBSERVED** (a file, section or commit you can check), **OPINION** (my judgement). Everything here is a proposal. Changing the core waits for the director's yes.

## Verdict (5 lines)

1. The engineering is real and solid: about 105k lines of Luau, pure rules with thousands of checks, a server that owns valuables. But no stranger has ever played the game, and the director last played it on a phone on 11-17.
2. The team built the deep game (14 gear slots, Reinforce, emblems, jewels, a Forge, a Condenser, chests, the Tower, element states, goals) before proving that the small loop is fun. The founding directive forbade exactly that (section 17).
3. The two things the vision is about, characters worth owning and fights that feel good, are the weakest parts. The Voidkin are being redesigned from scratch, and in a fight the player has nothing to do.
4. Paper and review loops now eat about as much effort as the build. Docs hold about 660k words, and a piece takes 10 to 20 commits. Taste checks keep passing work that the director then rejects.
5. To take the wheel back: freeze new scope, publish, play the first ten minutes on a phone, fix only what that run shows, and steer through one short daily card.

## 1. What is actually playable today, from a new player's seat

**Verified** (checks with output on record):
- **The whole suite in Studio.** 3,376 passed and 1 failed, on `f0f7f88`, at TR50's close on 11-23 (OBSERVED, commit `5de7f52`). The offline logic cases run about 26k checks (OBSERVED, TR32 and TR45 in `docs/test-requests.md`).
- **One whole first session, driven by Faber in Studio's phone simulator,** on 2026-11-16. That predates chests, gear, goals and the Arc panel. It found: nothing tells the player what to do, no gear drops, waits of 30 s and 90 s, and the lead dies on the way to the keeper (OBSERVED, TR24, "The run" and "The fix list"). The fixes were built afterwards, and the whole run was never repeated.
- **The director's own phone run on 11-17:** "obviouslt it still far to look like a game, no SFX that add depth..." (OBSERVED, `docs/decisions.md`, row of 2026-11-17, by 00:17).

**What a new player would meet, as the docs describe the build (claimed, not run end to end):**
- **At home:** they arrive at the base, pick one of three starter shards, and get a reveal.
- **The trip:** they tap Play, the Arc panel opens, and they teleport to the Festival place for Lantern Row on Normal.
- **The fight:** the lead fights Brawlers on its own, and since 11-24 Guards and Dashers too. Watt's shard and chests with gear drop.
- **Back at the base:** they teleport home, put Watt in a bay, see the power come on, and equip gear or use the Forge.
- **Around that:** Today's goals and each stretch's dare (TR54, held on three must-fixes), and the Tower in grey.

**Not verified, and the cause of each:**
- **The teleport.** It has never run for real: "Studio can't teleport", and the Festival place isn't published (OBSERVED, TR45, "Not yet"; the Now board, "Waiting on the director", item 4).
- **The animations.** Only two clips are published, `ShadeGuard` and `ShadeLunge` (OBSERVED, `src/shared/Config/Animations.luau`, `Ids`). In a live server no Voidkin, Shade or keeper would animate (OBSERVED, `docs/research/making-greatness.md`, section 4).
- **The music.** Every track list is empty (OBSERVED, `src/shared/Config/Music.luau`: `Ids = {}` five times: Strip, Base, Lantern Row, Keeper, Tower; the director said on 11-19 that they would paste the ids themselves).
- **The director's phone run of the current build.** Research gave the go on 2026-11-16 at 23:34, and it still waits on one Alt+P publish, eight days later (OBSERVED, TR24, "Research's go"; board item 4).
- **The keeper's gate.** The "Want" beat's case runs only in the Festival place, and nobody has run it there (OBSERVED, TR32, "NOT VERIFIED").
- **Several pieces implemented "not yet run in Studio".** AR49, TR51 and TR37, because the Studio MCP attached to a blank window (OBSERVED, `docs/research/design-holes.md`, section 1).

**Plainly:** the loop exists as code. Nobody has seen it from end to end in the form a player would get (OPINION, from the above).

## 2. The gap

**To the vision's first session** (`docs/north-star.md`, "The first session"):

| Beat | Where it stands |
|---|---|
| Arrive | Built. The base is being "reimagined" again (decisions, 01:58: Modulo is art director over the base and the HUD) |
| Choose | Built, but every Voidkin is a pre-bar model. Rook's redesign is waiting for acceptance, and Kirra's has just started (Now board) |
| Fight | Behind a menu and a teleport. The player only watches (H1 in `design-holes.md`). The signature on a tap (TR52) is waiting on the director's run |
| Find | Built. A toast at the screen's edge, with no shard in the world (TR24) |
| Work | Built. With five Voidkin and four bays, "who works" is never a real choice (H3) |
| Build | Built, but very deep: 14 slots, three layers of sockets and stones (design.md, "Regalia") |
| Want | Rewritten to point at the Lamplighter on Hard, the Tower and the shop (F7). Never seen in a run |

**To a publishable small excellent game, still missing:**
- the animations published (about every clip);
- music;
- a real trip measured;
- the five Voidkin at the bar, each with its own basic attack (none has one; making-greatness, section 4);
- the store's design (waiting on the director since 11-17);
- the game page and the maturity questionnaire;
- a real phone, and a stranger's first ten minutes.

Most of it is integration and taste, not new systems (OPINION).

## 3. Where the nonsense is

**3.1 Systems built before the loop is fun** (the directive, sections 6 and 17: "satisfying at a small scale before we add dozens of supporting systems"; "test it with multiple players and representative mobile devices. Only then expand").
- **What launches:** a 14-slot account gear set, presets, Reinforce, War Emblems in up to four sockets, five jewels on every piece at five levels, three grades of forge stones, a Stone Condenser, chests with Epic and Legendary odds, Combat Power with skulls, five element states, the Tower, dares, and Today's three (OBSERVED, `docs/design.md`, "Regalia", "Chests", "Goals"; `src/shared/Rules/`, 45 modules).
- **What it serves:** one ground with a 10 to 15 minute run, five Voidkin and no multiplayer test (OBSERVED, `docs/production-plan.md`, "The cut line").
- **Research's own audit says the same.** "The economy and the deep build were fitted to a bigger game": `balance.md` is fitted to six grounds, 31 Voidkin and about 57 hours (OBSERVED, `design-holes.md`, H5). Electricity, the pillar that "ties collecting to fighting", may be slack: the bays cover demand 1.5 to 1.7 times over (H4).
- **The newest work keeps adding systems.** Research wrote at 00:01 on 11-24 "No new system until it passes" (`making-greatness.md`, section 5.1). Ninety minutes later the goals system went in (TR54, `2331a81`), and a new redesign started (AR60, `0ec6bff`). The plan isn't steering the work (OPINION).

**3.2 Drift from the founding vision** (`docs/archive/directive-2026-11-09.md`, section 3).
- **Void Clash.** The directive's named arena and the loop's "Enter Void Clash" step have become the Clash Grounds: phase 5, launching only "if they're at the bar" (OBSERVED, production-plan, "Phases" and "The cut line"). The Tower, which isn't in the directive, launches for sure. The game's own identity piece is now optional (OPINION).
- **The Fighter Index.** The directive calls it "established identity": "a persistent collection Index". `design.md`, `ui.md` and `roster.md` have no Index (OBSERVED, a grep for "Index" finds none).
- **The compact neighbourhood and "the base is alive".** The pillar says "a shard cracking while you fight". The fight moved to a separate place behind a teleport, on the director's word of 2026-11-19, 02:05 ("festival of battle is a game mode it need a new places"; OBSERVED, TR45). Research itself flags it as H7 and H8. **This one is the director's own choice, and it breaks two pillars.**
- **"An anime game", not a lantern festival.** The director said on 11-23, 18:35: "dont make the whole game about lantern drum festival... we make an anime game!" The roster still plans "six grounds at launch", all festival: Drum Court, Mask Parade, Kite Heights, Ember Stalls and the rest. The foes are masked festival-goers, and the keeper is the Lamplighter (OBSERVED, `roster.md`, "The Festival of Battles: six grounds at launch"). The fiction comes from research, not from the anime genre (OPINION).
- **Fusion, mutations and traits.** The directive calls them "important planned systems". They're out of launch, while jewels and emblems are in (OBSERVED, design.md, "Out of launch"). That's defensible, but it means the build depth comes from gear, not from the fighters (OPINION).

**3.3 Names players won't understand.** One ground and five fighters come with about 50 proper nouns:
- **Shards and machines:** Void Shard (Standard, Enriched, Prismatic, Named), Breaker, chambers, Low and High voltage infusion, kW and kWh, battery, overflow.
- **Foes and places:** Shades (Brawler, Guard, Dasher, Support, elites), keeper, Lamplighter, Festival of Battles, the Strip, Festival Door.
- **Gear:** Regalia, presets, Reinforce, War Emblems, Jewels, forge stones, Condenser, Forge, Dawn.
- **Currencies and numbers:** Credits, Research Points, Combat Power, skulls, five Basic Attributes plus the Battle Attributes, a colour-type ring, five classes, element states (Burn, Chill, Freeze, Shock, Sap), Kindle, stars, aptitude.
- **Goals:** dares, Today and Next (OBSERVED, design.md, "Words", "Regalia", "What the player holds"; `docs/roster.md`).
- **One run has five names.** Players see "Arc", the docs say "ground", the run's parts are "stretches" (formerly "stages"), and the director says "phase" (OBSERVED, design.md "Words"; decisions, 11-19 23:19 and 11-23 03:25).
- **Plainly:** a new player on a phone meets a spreadsheet's vocabulary before meeting a character (OPINION).

**3.4 Process eating the build.**
- **Paper against code:** `docs/` holds about 645k words. `asset-requests.md` alone is 390k words, about four novels. `test-requests.md` is 110k and `decisions.md` 30k. The code is about 105k lines (OBSERVED, `wc`). Since 11-19, about 100k words of docs were added, against about 149k words of code (OBSERVED, `git diff 55af041 HEAD`).
- **Where the commits go:** of the last 202 commits, 49 touch `src/` and 98 touch only docs. 83 are verdicts, picks or must-fix rounds (OBSERVED, git log). Research counts 20% of commits touching `src/` since 11-17 (`making-greatness.md`, section 4).
- **Commit subjects are essays:** the median is about 400 characters and the longest 1,744 (OBSERVED).
- **The loop for one piece:** feel line, three-way blockout, research's pick, finish, verdict, must-fixes, second look, install, in-game read, director. Commits per piece: AR49 20, TR50 22, AR53 17, AR48 15 (OBSERVED, git log).
- **The rules undercut themselves:**
  - the "Notices" list holds about 20 entries, some from 11-15, against its own seven-day rule;
  - the production plan's status line is dated 11-17;
  - the board's count read 0 while two pieces had closed (OBSERVED, team-notes "Notices"; production-plan line 5; `making-greatness.md`, section 4).
- **The directive asked for the opposite.** Section 16: "Apply LYNX, but do not create another bureaucracy... Each additional tool must justify its value." Five AI seats share a 15.5 GB PC with at most two Studios, so verification, not making, is the bottleneck (OBSERVED, `CLAUDE.md`; F9 in `design-holes.md`).

**3.5 Contradictions on the page right now** (OBSERVED):
- `roster.md` plans "six grounds at launch", and the cut line says one.
- `design.md` says "Thirty-one at launch" and "Nothing here is built", and the cut line has five Voidkin while most of the design is in code.
- The production plan still says "Every Voidkin piece waits for the end". The director reversed that on 11-23 at 22:52 ("Fighter redesigns now").
- The north star has the player "walk onto Lantern Row", and the build opens a menu and teleports.
- "Directions are final" (AGENTS.md), yet the HUD and the base are both being "reimagined" after about 15 pieces passed at competent (decisions, 11-24 01:58; the AR30, AR40, AR43 to AR45, AR49, AR50 and AR54 entries).

**3.6 Things redone over and over.**
- **The Voidkin.**
  - The director called them "horrible" on 11-20 and promised examples "tomorrow".
  - The examples never came, and research and Modulo built without them.
  - AR59's three Rook takes then got "OMG NO NO NO LOOK at anime VANGUARD" on 11-23 at 23:45.
  - The make was rebuilt that night, with the hair reworked twice (OBSERVED, decisions; `cabf600`, `8afb600`, `2805c92`).
- **Sound.** AR13's 33 made takes were "genuinely horrible", and AR39's round was "plain nonsense". Then came an audition panel and now a dedicated seat (OBSERVED, decisions 11-17).
- **The goals.** The Mask Ledger was designed, drawn as 33 images and then cut: "we make an anime game" (OBSERVED, `f46f34d`, `cee7783`).
- **The HUD and the base.** Each has had five or more passes, and both are now reopened.
- **The pattern:** research's "competent" doesn't predict the director's taste. The director's references arrive after the work, not before (OPINION, from the above).

**3.7 The director's own choices, confronted** (OPINION, each with its evidence).
- **"I don't want Faber or Modulo to stop working"** (decisions, 11-18, 22:30). This made output the goal. Modulo drew the Tower room, the elites and the Support ahead of a Faber queue of 7 to 10 uninstalled pieces (decisions, 11-23, 20:01 to 22:26). Idle is cheaper than inventory nobody can judge.
- **The 11-16 package and later [D] adds** widened the build before anyone played: 14 slots, five jewels on every piece, emblem rarities, the Forge and the Condenser. They are the director's choices, and they cause H5.
- **Moving the fight to its own place** (11-19) cost the neighbourhood and "a shard cracking while you fight".
- **The director's attention goes to the small, the big asks wait.** 253 dated director's-word rows in about 15 days, many on details: the dock "a bit to shiny", a "corny" line, a crit's chrome. Meanwhile one publish has waited eight days, and the store has waited a week.
- **Late taste, not early references.** "I will give batch exemple tomorrow" (11-20) didn't happen, and the redo followed. Ten reference images up front would have saved a night.
- **"Heavy inspiration from famous anime IP"** (11-23, 23:52) pushes against supreme rule 3. Research held the line correctly.
  - Watch AR60 Kirra: take A is silver hair and a quick assassin with blades who vanishes through the target.
  - The take sheets are drawn beside two reference units, one of them `kinnua-….webp` (`tools/blender/rook_make_takes.py`, `BESIDE`; checked by Faber). Comparing against a reference is fine. The risk is the combination: silver hair, a quick assassin and the name Kirra sit close to one famous character, and two or three such traits together are what the "Fighters" test forbids. PLAUSIBLE, not confirmed: take A should go through the content check before any build.
- **Leadership handed to research** (decisions, 11-24, 01:58). This gives approval to the seat whose "competent" verdicts the director has rejected three times this week (AR59, AR53's Ledger, sound). Reasonable as a stopgap, but risky for anything players see.

## 4. Course correction (proposals; the core waits for the director's yes)

**In order:**
1. **Freeze scope for one week** (tier 3). No new system, mechanic or screen, and no art that isn't on the first ten minutes' path. TR53, TR33, TR34, the Tower room's install, the Support Shade's behaviour, emblems and jewels polish, and AR60 onward all wait. Write the freeze as the production plan's first line, and have research refuse pieces against it. What's built stays built.
2. **Make it real: publish** (the director, about 10 minutes, plus Faber).
   - The director presses Alt+P on both places (item 4).
   - Faber publishes every clip under the group, and Sonus fills the five music lists from the library.
   - Faber times the real trip.
   - This single step unblocks more verification than any new piece (OBSERVED, section 1).
3. **The director plays the first ten minutes on a phone, then three people who've never seen it do,** each silent, explaining the goal back afterwards (research's own section 5.5). The output is one ranked list of what felt worst, at most 10 lines. That list becomes the next two weeks' only queue.
4. **Put the fight back in the player's hands and the player's base** (tier 3, for the director).
   - Decide TR52, the signature on a tap, in one sitting: play it with Auto on and off.
   - Decide F7's "first breach": the first fight in the main place, before any teleport. It restores pillar 3 and the neighbourhood for the first minutes at little cost, since Shades already run in both places (OBSERVED, `216fc2f`).
5. **The Voidkin, with references first.**
   - The director sends 8 to 12 reference images of the bar (the genre's side cast, kept inside rule 3) before Kirra's takes.
   - Rook, once accepted, becomes the make's template.
   - Each Voidkin gets one take and one fix round, then the director's yes. No three-way blockouts for fighters.
   - Each gets its own basic attack (Scintilla) right after its model. A fighter isn't "done" without the hit.
6. **Shrink what the first session shows** (tier 3). Keep items, Reinforce and the lead's Combat Power. Hide emblems, jewels, the Condenser, the element states' detail and the Tower behind levels or the first update. Pick one word for the run and use it everywhere: players and docs both say "Arc", and its parts are "stretches". This is a UI gate, not a deletion: the code stays and is tested.
7. **Put the paper on a diet** (tier 1, research and Faber):
   - commit subjects of one line, 72 characters at most, with detail in the body;
   - a verdict of 10 lines at most;
   - closed AR and TR entries moved to `docs/archive/`;
   - the Notices list emptied of anything older than seven days;
   - the three contradictions in 3.5 fixed in their homes.
   - Target: under 1 doc-only commit for every 2 code commits.
8. **Cap the queue, not the hands.** Art may run at most two pieces ahead of install (F9). A maker with nothing on the path does a verification job (captures, a phone run, a lint) or stops. That needs the director's word to amend "never stand idle" (11-18).

**Freeze or cut until the loop passes a stranger:**
- **Frozen at the current state:** the Tower room, the Clash Grounds, parties, the store's random items, the after-launch updates' content, new Shades, new element states, and the HUD and base "reimagining" (finish what's in first).
- **Proposed cuts from launch (tier 3):** jewels, or one jewel socket instead of five per piece, and War Emblems. They multiply grind on a 10 to 15 minute ground (H5).
- **Re-raise rather than drop:** Void Clash. Either name it the launch's second mode in place of the Tower, or say plainly that it moved to an update. It's the directive's named identity.

**A rhythm the director can run in 15 minutes a day:**
- **Daily, 15 minutes:**
  - 5 minutes: play the latest build on the phone, or watch Faber's 60-second capture of the first ten minutes.
  - 5 minutes: answer the "Director's card", at the top of the Now board. It holds three questions at most, each a yes or no with research's recommendation and one image.
  - 5 minutes: write one line, "what felt worst today", which research turns into the next fix.
  - Nothing else reaches the director unless it's rule 4, money, accounts or publishing.
- **Weekly (Sunday, about 45 minutes):**
  - watch one silent stranger playtest;
  - accept or reject that week's pieces;
  - name the next week's three pieces, no more;
  - research reports one number: pieces closed and playable, with hours, plus the D1 funnel once strangers play (TR32).
- **Every two weeks:** a "nonsense check". Research lists every system, word and screen a new player meets in the first ten minutes, and the director cuts one.
- **Why this works** (OPINION): the director's best calls this month came from playing ("far to look like a game", "we make an anime game"). The rhythm makes playing the input and documents the output, not the other way round.
