# The steering brief, second edition (2026-11-24)

Faber, from a cloud session. It answers the director's words of 11-24: "we are lossing control of the wheel", "it fine to confront my idea and choice", and "look at how gta 6 systems marry each other ... just to make it 1 whole premium game". One page that ranks what the 32 studies in this folder found, with an action sheet for each teammate.

**Every item is a proposal** unless it's under "Done on this branch". Anything touching the core, a confirmed decision, the economy or scope waits for the director's yes to a plain restatement (`AGENTS.md`, "Changing the core"). **No release:** the director, 11-24: "no publishing the game isnt ready". A "phone run" below means the director's own private save, never players.

## The diagnosis, in six lines

1. **The engineering is solid and ahead of the game.** Pure rules have about 29,900 offline checks, and the server owns every valuable, each flow fuzzed.
2. **Nobody has played the current build on a phone since 11-17.** Every pace number in the game is still a seed.
3. **The fight is the only hub, and the player has little to do in it.** It feeds six systems; only the roster and gear feed it back (`systems-map.md`). With no workers at all, a fight is identical.
4. **The systems work, but nothing passes between them.** Seven pieces announce events and each decides alone (`orchestration.md`). Almost no passage between states tells the player anything (`seams-and-states.md`). This is the gap between "systems" and "one premium game".
5. **The deep game outran the small loop.** Gear has 14 slots and four layers, and only one layer holds real choices (`build-depth.md`). Meanwhile 53% of the small details a player expects are in (`detail-pass.md`).
6. **Paper costs as much as play,** and AI verdicts keep passing looks the director then rejects (`directors-taste.md`).

## Done on this branch (implemented and tested here; NOT VERIFIED in Studio)

- **Play opens a panel of game modes** (the director asked twice): the Festival and the Tower, a card each. Commit c5aa6d6; `src/shared/Rules/Modes.luau`, `src/client/UI/ModeScreen.luau`, `src/client/Controllers/Main/ModeController.luau`. `Config.Hud.Modes.On = false` gives Play the Arc panel as before. Owed on the PC: the self-test run and the player-camera review.
- **One call made here:** both cards always show. `state-of-the-game.md` says hide the Tower in a first session, but a panel with one card is the exact thing the director objected to. Research can hide it by a `Goals` fact at the feel line's review.
- **The base view's Upgrade press** (a66cd2e): the level's plate and each machine's panel carry Upgrade with its price. `Rules.BaseLevels.Ask`, `src/client/UI/BaseView.luau`. Grey, no art.
- **Five small fixes from the holes below and `detail-pass.md`:** a refusal never shows its code and Begin always answers (d0cbe09); a favourite sorts first (40a48c8); the restock chip only where the Shop stands (f0743c5); the bay picker leads with the best worker and shows the gain (4ac79ee); the run's card waits until the keeper's fade is back (ca87da1). The table and what's owed in Studio: `build/handoff/faber-cloud-2026-11-20.md`, "Game changes of 2026-11-24".
- **The splitter for the two request files** (`tools/docs/split_requests.py`, byte-for-byte, with a way back): ready for the builder to run on the PC (`reorganisation-plan.md`).

## The ranked list

Ranked by what it unblocks. "Yes?" marks what needs the director's word.

| # | What | Why now | Who | Cost | Yes? |
|---|---|---|---|---|---|
| 1 | **One private phone sitting, with a stopwatch.** The first ten minutes, one clean Normal run, and the trip to the Festival and back. | Three studies rest on unmeasured time. The pace seed says 450 kills an hour; the run as staged gives 136 to 204. A run is about 5.5 to 7 minutes on our seeds against a target of 10 to 15. The trip's watchdog is 40 s against the north star's half-minute. | the director and the builder | 30 min | their hand |
| 2 | **Close the holes that stop the loop.** See "Holes" below: the base can't be upgraded from any screen, a fallen lead can't stand again in the Festival, the win card is covered by the keeper's fade, and Reinforce stops near +10 of 30. | These aren't polish. A first session hits three of them. | the builder | 2 days | no |
| 3 | **Give the fight a press and the street some beats.** The signature on a tap is already TR52. Then: waves in place of the respawn quota, each elite its stretch's role with one move, the Lamplighter's phases 2 and 3 in grey, Hard that changes behaviour. | 76% of what's killed before the keeper is one Shade. All three elites are the same one. | research, the builder, Modulo | 4 days | tier 2; shipping the press is theirs |
| 4 | **A conductor.** One door for notices, two lanes, a pure ordering rule, a hold during fights and ceremonies, and the results card as the run's ledger. Then the eight silent big moments get a sound, and every refusal gets words. | The importance ladder exists for hits and nothing else. A keeper's fall borrows a Shade's sound. | the builder, Sonus, research | 3 days | no; the director's ear picks cues |
| 5 | **Close the loop at every ending.** The run card, the fall card, the Tower's results and the reveal each end on the same Next line plus one fact from another system. The return card says what the base made. The session's last card names tomorrow's three. | The away summary is computed and thrown away (`BaseService.luau:88`). | the builder; research the lines | 2 days | no |
| 6 | **Make electricity matter to the fight.** Overflow pays the workers in experience before Credits; a work knack per Voidkin gives the bays a real choice. | The design says a worker levels by working. No rule pays it. | research, then the builder | 1.5 days | yes (economy) |
| 7 | **Stop selling the currency that buys rolls, and give Reinforce forge heat** (replaced "make Reinforce sure", 11-24: `launch-design.md`, section 3). | Rule 4. Roblox's clarification of 2026-05-26 (DevForum, Announcements, topic 4654622) says every outcome must give some benefit. A failed Reinforce gives none. | the director | a decision, then 2 h | yes |
| 8 | **Stage the gear.** Six slots first, then Reinforce, then the Condenser and more slots, emblems at the first Hard keeper win. ~~Hold jewels~~: withdrawn, since the director's word of 11-17 puts jewels at launch (`launch-design.md`, section 5). | Combat Power pays the balanced build 21 to 48% more, so the number steers everyone to one build. | research, the builder | 2 days | yes |
| 9 | **One look.** "Night glass" for the UI; cel paint and the hair recipe for the Voidkin; one clip in three timings to pick the house timing; a reference beside every take. | The director rejects what the team passes. The reference is the missing instrument. | Modulo, Scintilla, research | per study | Night glass: yes |
| 10 | **One voice.** The voice page and its ten questions into `docs/ui.md`; fifteen weak strings rewritten; one meaning for "Void". | A first session asks for about 40 game words. | research words, the builder edits | 3 h | the Shop's name and the dock's Home: yes |
| 11 | **The paper diet and one ranked list.** Split the request files, a status line per piece, closed pieces to the archive. | 83% of the docs' words are in two files. | research and the builder | 2 h | the rule's wording: yes |

## Holes found by reading the code

Re-checked on this branch after its study reported it: the Upgrade press, the lit Retry, the card's and the fade's seconds, the raw code, Noct's row, the favourite sort and the Reinforce cost. The rest stand as their study reported them. None was seen in play.

| Hole | Where | Fix | Status |
|---|---|---|---|
| No screen calls `UpgradeBase` or `UpgradeMachine`. The base can't level in play, so bays 3 to 6, the Condenser and machine stages can't be reached. | `src/client/UI/BaseView.luau` is still TR21's blockout | The Upgrade press with before and after (`docs/ui.md`, 7) | done here, a66cd2e; Studio owed |
| A fallen lead can only stand again on a plot. The Festival has none. Retry is lit and answers "Your lead is down". | `FightService.luau:1371`, `StageScreen.luau:113` | Research's rule (the Arrival pad counts as home, or a fall carries the player home), then Home lit and Retry dim | tier 2 |
| On a win the card rises at 1.2 s and the keeper's black fade covers it at 2.4 s. | `StageService.luau:261`, `KeeperService.luau:332` | The card after the fade | done here, ca87da1; Studio owed |
| Mid and High forge stones can't realistically be had, so Reinforce stops near +10. | `Config/Drops.luau` | Say the honest cap, or add the source | research; proposed: High from the Condenser (`launch-design.md`, section 5) |
| Six machines to level 30 cost about 792,000 Credits; everything else at launch about 37,000. | `Config/Base.luau` | Hold the ceiling at 6 at launch | the director's "ok" (11-24), restated with a correction to 15 (`launch-design.md`, section 4); waiting on 6 or 15 |
| A refusal can show a raw code, and the stage menu's Begin can say nothing. | `BaseController.luau:173`, `StageScreen.luau:114` | One table of words | done here, d0cbe09; Studio owed |
| Noct: the name plus "throws the spear and arrives where it lands" is one famous lead's name and move. | `docs/roster.md:63`, `Definitions/Voidkin.luau:71` | ~~A new name and a new signature~~ | **closed:** Noct stays, the director, 11-24 (`launch-design.md`, section 12) |
| `docs/roblox-rules.md` says the paid-random-items page "says nothing on an outcome that gives nothing". | line 29 | Add the 2026-05-26 clarification | research; now SOURCED from the Community Standards (`launch-design.md`, section 3) |
| The Blender clip tools read `src/shared/Config/Camera.luau`, which doesn't exist. | `tools/blender/r6anim.py:1004` | Read `Config/Hud.luau`'s camera, or pass it in | Modulo |
| A favourite doesn't sort first, though the rule's comment says it does. | `src/client/UI/Read.luau` | Sort it | done here, 40a48c8 |
| Research Points, jewels' sockets, the Tower's weekly board: fields with no source, sink or reward. | `systems-map.md`, section 6 | One truth pass over `docs/design.md` | research |

## Action sheets

**The director (about an hour in all, in this order)**
1. The private phone sitting (item 1). Nothing else is as cheap for what it settles.
2. The six questions of `launch-design.md`, section 13: the currencies, Credits and forge heat, the ceiling, the chests, the Broadcast, the welcome week. (The phone sitting: "ok"; Noct stays: both 11-24.)
3. "Night glass": yes, no, or "show me a mock first".
4. The ten questions in `directors-taste.md`, section 8, sent as one card with pictures.
5. Later, when asked with numbers: the gear's staging, jewels held, the machines' ceiling, overflow as experience, a one-week scope freeze, which names stay English in translation.

**The builder (Faber, on the PC)**
1. Run the Play panel's self-test and review it from the player's camera. Then the base's Upgrade press.
2. The fall in the Festival and the card's timing, once research writes the rule.
3. The conductor (`orchestration.md`, section 5), then the return card and the endings' Next line.
4. One day of small provable fixes from `detail-pass.md`: the favourite sort, drop rates that mark who you own, the bay picker's best fit, claim all, "can't afford: where to earn", the bag remembering its tab.
5. Write `emitter.Rate` only on change (`FighterController/Rows.luau:733`), and one hour of Studio tests for Modulo (`character-art-pipeline.md`, item 4).

**Research (Quaestor)**
1. The fallen lead's rule, and the truth pass on `docs/design.md` (`systems-map.md`, section 6).
2. Refit the pace seed from the timed run. Until then no number that rests on 450 is quoted.
3. The wave lists and the elites' moves (`grounds-and-encounters.md`), and the ladder of importance with its semantic sheet (`orchestration.md`, 5a and 5b).
4. The voice page into `docs/ui.md`; a content check on Noct, Mirage, Cinder and Dawnbreaker.
5. Four lines in every verdict before "Tier": the reference, the festival's limit, 3x zoom, the director's words as typed. A text yes on a look means "go sketch".
6. A "Standing decisions" page at the top of `docs/decisions.md`.

**The asset maker (Modulo)**
1. Cel paint in the kit and the hair recipe, proven on Rook (`character-art-pipeline.md`, items 1 and 2).
2. One clip in three timings (`animation-craft.md`, item 1); poses apart from timing in the clip scripts.
3. Number gates and the game's real camera in the sheets. Fix the missing `Config/Camera.luau` read.
4. Three block clips for the elites; a heavy flinch.

**Effects (Scintilla)**
1. Main shapes in bursts, meshes or beams, never on `Rate`: phones cap an emitter at 100 a second. Watt's Ground Wire asks for 420.
2. The stepped-timing trial at 12 to 15 fps, and a smear kit in grey on one action.
3. The press's answer in a fight: the target ring and the lead's ready glow (`combat-agency.md`, item 5).

**Sound (Sonus)**
1. The eight silent moments: the keeper's fall, level-up, lead hurt and down, the drop's rarity note, goal done, upgrade result, machine stage, record.
2. The UI family as a block, and one listening sitting of about 20 minutes for the director.
3. A content check of the 63 keeps, with one licensed alternate per cue.

## What not to do

- Don't add a mode card for anything that isn't built.
- Don't quote a per-hour number until one run is timed.
- Don't sell Credits while Credits buy a roll.
- Don't take "heavy inspiration from famous anime IP" past rule 3. Research held that line correctly on 11-23.
- Don't polish a system's screen before its loop closes: a passage with no message costs more than a plain panel.
- Don't trust a "no reader found" claim in a study without a second grep. Each study lists its own claims to double-check.

## The studies, by subject

Every finding is labelled SOURCED, COMMUNITY, MEASURED, OBSERVED or OPINION. Three early ones (`state-of-the-game.md`, `design-review.md`, `directing-the-game.md`) say "publish" or "strangers play": read that as the director's private phone run.

| Subject | Files |
|---|---|
| **The launch game, from the ground up** (11-24, the director's ask: currencies, Reinforce, chests, the Broadcast) | `launch-design.md` |
| Where we stand, and how to steer | `state-of-the-game.md`, `design-review.md`, `directing-the-game.md`, `directors-taste.md`, `reorganisation-plan.md` |
| The whole: how systems join | `systems-that-marry.md` (the method), `systems-map.md` (ours, measured), `seams-and-states.md`, `orchestration.md`, `detail-pass.md` |
| The first session and the long game | `first-session-script.md`, `long-game.md`, `retention-and-discovery.md` |
| The fight and the grounds | `combat-agency.md`, `grounds-and-encounters.md`, `taichi-panda-study.md` |
| Collecting, gear and the economy | `collection-and-economy.md`, `build-depth.md`, `reveal-and-showcase.md`, `base-and-neighbourhood.md` |
| Characters, worlds and words | `characters-and-worlds.md`, `character-art-pipeline.md`, `animation-craft.md`, `voice-and-naming.md` |
| Effects and sound | `vfx-quality.md`, `audio-direction.md` |
| The UI | `play-mode-panel.md`, `ui-colour-review.md`, `menu-layout-and-motion.md`, `reference-menu-video.md`, `devforum-ui.md` |
| Engineering | `devforum-engineering.md` |

## Two figures corrected while checking

- One item to +30 costs 7,282 x G Credits in expectation, not 33,895 (`collection-and-economy.md`, corrected; `build-depth.md` had it right).
- The Kids and Select gate (`retention-and-discovery.md`, finding 1) involves a fee or Premium. That's spending, so rule 1 applies before anyone acts on it.
