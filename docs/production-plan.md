# Production plan

What's next, in order. The game is in `docs/north-star.md`, its systems in `docs/design.md`. A status changes here and nowhere else.

**Status, 2026-11-26, 14:11:** the overhaul, on the director's word (`docs/decisions.md`, 13:25 and 14:06: "we shouldnt rush we need to polish and make it a premium experience", "overhaul the systems that you believe geniuelly need so and rework the others to make them better"). Polish comes before new content, so no new system starts until the three overhauls below are in.

**The aim:** a premium game (`docs/north-star.md`, "The bar"). One ground at the bar before six grounds in grey.

## The overhaul (research's picks, 2026-11-26)

**Overhauled: the design changes.** Where the old design was the director's, the new one is built beside it and the director picks. In this order:
1. **The fight.** The vision's core and its weakest part. The player watches, 76% of what's killed before the keeper is one Shade, and no basic hit has its own read or sound.
   - **What changes:** the hit (wind-up, a strike of 2 or 3 frames, hitstop, knockback; TR66, rows 12 and 13); the street (waves in place of the respawn quota, one move and a role for each elite, the keeper's phases, a Hard that changes behaviour; `docs/research/cloud-2026-11-24/grounds-and-encounters.md`); TR52's tap, judged in play.
   - **Who:** research writes the feel line and the spec; Faber, Modulo and Scintilla build.
2. **The break and its reveal.** A collection game's big moment, and today it's an overlay.
   - **What changes:** a full-screen void moment; the Voidkin standing in 3D on a burst in its rarity's hue, with its number ("No. 1,284"); a counter strip and a sorted summary for a multi-break (`docs/research/anime-crusaders-ui.md`, "Lessons for us").
   - **Who:** research's feel line; Scintilla's and Modulo's targets.
3. **How the game talks.** Seven systems announce on their own, and the big moments are silent.
   - **What changes:** one conductor for notices (one door, an order, a hold during fights and ceremonies); every ending closes with a Next line; the whole-screen return card the director asked for on 11-24 (`docs/research/cloud-2026-11-24/orchestration.md`, section 5; TR53).
   - **Who:** Faber builds, research writes the words.

**Reworked: the design stays and is made better.** The base's look (AR65); the style frame, then every screen (AR62); the Voidkin's make (AR64 on); the Tower (TR67, AR56's clouds); the words (TR68); the hit and signature sounds (TR42, picked by Sonus, judged by the director in play); and electricity's worker experience, which is built but still owes its Studio check.

**Kept as they are:** the currencies and the economy (the director, 11-24), the fourteen gear slots (11-25), the Tower's rules and the shard system.

**Faber's order:** the director's asks and the bugs first (TR65, TR66 row 11); then AR65's cut made real; TR68; the fight's spec as it lands; then the conductor. AR7 and C4 go into the fight.

## How we run here

- The rules: `AGENTS.md`. A piece is a request entry: `docs/test-requests.md` for the builder and QA, `docs/asset-requests.md` for the asset maker.
- **Lighter:** one write per piece, one home per fact, no document that isn't a rule, a design, a request or the board.
- **Quality:** every piece players see goes feel line, then a target the director picks, then the build with checkpoints beside the target, then review in pairs from the player's camera (`AGENTS.md`, "target first, verdicts in pairs", 2026-11-24). The director's word accepts a look.
- **Numbers** live in the seeds, then in the game's Definitions, and are tuned by playing with them exposed at runtime.
- LYNX runs one experiment at a time, between pieces: `handbook/studio/lynx.md`.

## Who makes what

The director asked, 2026-11-11, whether Modulo should make all the HUD design, the UI textures and effects, textures and the map. **Yes for everything that's a look, with an order, and with two things split off.**

| Work | Who | Note |
|---|---|---|
| Voidkin and Shades: models, textures, clips | Modulo | the game's main content, and always first in Modulo's queue |
| Combat effects: hits, the Shades' and the keeper's, the element states, each Voidkin's M1 and signature, from the look to the game | Scintilla, the builder reviewing before merge (the director, 2026-11-23) | the shared kit first; each Voidkin's own after its redesign |
| The UI kit: frames, icons, bars, the two themes, the look of interface effects | Modulo, from `docs/ui.md` | one kit, made once |
| Where things sit on a screen, what shows when, the hierarchy | Quaestor | `docs/ui.md` |
| Building the screens and making them behave | Faber | from one component library |
| The world kit: stalls, lanterns, gates, the base's machines | Modulo | after the first three fighters |
| The map's layout: where grounds, gates and bases sit | Quaestor lays it out in grey, Faber installs it | a level designer isn't opened |
| Effects in the engine: timing, hit-stop, camera | Faber, to Scintilla's look, in the same session | `/ga-action` |
| Sounds | Sonus shortlists and loads them into the listening panel; the director's ear picks each cue (the director, 2026-11-23); TR42, TR64 and TR57's 22 cues: Sonus picks them, the director judges them in play (2026-11-26, 20:48) | `AGENTS.md`, rule 2; the M1's sound is one per class |

One maker is one queue. If the board's count shows the team waiting on Modulo for more than a piece at a time, research proposes a second art seat (environment art) to the director. Not before.

## The team

| Seat | Who | From |
|---|---|---|
| Design, research, quality | Quaestor | now |
| Code | Faber | now |
| Art | Modulo | now |
| Effects | Scintilla | 2026-11-23 (the director: "we need agents for the combat visually and sfx to save us time") |
| Sound | Sonus | 2026-11-23, the same word |
| Outside voice | Gemini, through research | 2026-11-26 |
| QA | Probator | at phase 4's end, for the whole game before launch (the director, 2026-11-13). Level design and environment art aren't opened, since the grounds are one kit recoloured (`docs/roster.md`). Until then, the builder's checks and player-camera captures are a piece's evidence, and research reads them as QA would: the test output, the angles still missing, what regressed |

The PC's limits hold: two Studios at most, one render at a time. A seat opens when work waits for it.

## Models

The director's words, 2026-11-11 (`docs/decisions.md`): Modulo on Fable 5.2 high; Quaestor and Faber on Opus 5.5; a Fable pass later on whatever needs it. On 2026-11-25, Modulo moves to Opus 5.5 too, so the whole team runs on Opus.

- **Quaestor: Opus 5.5 high** (set in the launcher, the director, 2026-11-27). Research asks the director for Fable only for: the store's design, the retune after the first real play data, or a verdict the team disputes.
- **Faber: Opus 5.5 high** (the director, 2026-11-27, to save usage): each piece has a tight request and its tests, which catch what less thinking misses. A bug unexplained after one pass goes to xhigh for that piece. What gets a Fable read first when the reset comes: `docs/engineering-plan.md`, "For the Fable pass". A read, not a rewrite, unless the read finds one is needed.
- **Scintilla: Opus 5.5 xhigh** (the director, 2026-11-23). **Sonus: Opus 5.5 high** (the director, 2026-11-27): he shortlists, installs and logs, and the director judges in play.
- **Modulo: Opus 5.5 xhigh** (the director, 2026-11-25, by 21:32: "modulo should run on opus 5.5 now you decide if he go on high or xhigh effort"). Research picked xhigh: the look is where the bar is won, his open work is the hardest taste work on the team (AR64's hair, rejected seven times; the Voidkin judged beside shipped anime games), and every other maker runs at xhigh. What it costs: more usage per piece and slower turns. Before that, from 2026-11-12, Opus 5.5 xhigh until the Fable limit resets, then back on Fable 5.2 high (`docs/decisions.md`, 2026-11-12). Later on 2026-11-12, back on Fable for the last 9% of its usage. From 2026-11-13, Opus 5.5 xhigh again: Fable's usage is at 100% (the director: "he will be back on opus so record we are at 100% for fable"), and Fable returns at its reset, this weekend (the director, 2026-11-13: "he will be back on fable this weekend, his approaches to art as fable so far is incredible"). Each delivery names its model.

**Made on Opus, for Modulo's look on Fable.** Research lists each piece Modulo delivers on Opus, from its request entry. At the reset Modulo reads them and reworks what it judges needs it, as a fix round in each piece's entry. The Fable pieces before it: everything up to the elite's second mask (AR2, commit 95a5089).

- Lyric's model on R6 (AR4, section 5), delivered on Opus
- Lyric's five clips (AR4, section 6)
- The elite's second mask without its ties (AR2, section 7)
- The Shade's burst: the block-in and the art sheet (AR2, sections 8 and 11)
- The elite's contact sheet (AR2, section 10)
- Pip's Lantern Burst block-in (AR4, section 7)
- Haymaker's frames 7 and 8 with finer rims (AR1, section 8)
- Pip's Lantern Burst art sheet (AR4, section 8)
- Lyric's Held Note block-in (AR4, section 9)
- Haymaker's B, the stamp from above: the block-in (AR1, section 9)
- Pip's Lantern Burst, round 2: the recoil and the flame standing up (AR4, section 8)
- Lyric's Held Note: the lunge and the crest's ribbon and veil (AR4, section 10)
- Lyric's Held Note art sheet and her lunge into the mic (AR4, section 10)
- Pip's Lantern Burst, the full art run of round 2 (AR4, section 8)
- Lyric's Held Note clip: the speakers' fly-out on the crests, and the crests' markers (AR4, section 9)
- Lantern Row's direction sheet, round 1 (AR5, section 1): superseded by round 2 and the kit, both on Fable, so likely nothing to rework

On Fable since 2026-11-12, 22:05: Lantern Row's round 2 and its kit with the night (AR5), the HUD's portraits and the critical's stroke, both rounds (AR3, section 3). From 2026-11-13, on Opus again: the reveal's block-in (AR3, section 4), made on Fable up to the first shard sheet and on Opus from the shard's reshape on (Modulo, 1f8f58a).

## Phases

Each ends on something playable. No dates are promised past phase 1: see "The date".

**Phase 0. Day one** (TR1). The repo joined and pushed, the ids checked, the kit and Rojo running, the builder's three calls made.

**Phase 1. The circuit, in grey** (TR2, AR1, AR2). The whole loop with stand-ins: a base, the Breaker with chambers, three starter shards, a lead that fights by the real rules, Shades as boxes, Lantern Row as a grey street, a Named shard, a bay, electricity, saving. It answers: is the loop worth playing before any art? Meanwhile Modulo makes Rook and one Shade to the bar, and times them.

**Phase 2. One ground at the bar.** Rook, Pip and Lyric finished and timed. Lantern Row dressed. The HUD, the reveal and the Breaker screen on the real kit. The Lamplighter. The first session reviewed whole, from a phone. This is the game's proof and its advert. Its signature effects close at competent; the push toward exceptional waits for the finish pass before launch (the director, 2026-11-13, `docs/decisions.md`). **Content as data** (Faber, after TR6, before the next Voidkin is installed): `docs/engineering-plan.md`, "Content at scale", items 1 to 5, so each Voidkin, effect and Shade after it is mostly data and art.

**Phase 3. The build.** It opens with the director's package of 2026-11-16 (the yes at 16:50), in this order, each a block first: the base's three sizes in grey; attributes in the resolver with the stat sheet; items, class rules and the comparison; chests and bulk opening; the inventory on its chosen direction; the generator and the machines' stages; the Tower's run; the responsive pass across every screen. Then the Forge and the Stone Condenser that feeds it, emblems, jewels, research. Gear stays the account's (the same yes). The evidence behind the order and its risks: `docs/research/rework-2026-11-16.md`, part 12. Four more on the director's yes of 2026-11-16, 21:39 (`docs/decisions.md`), after TR24's fixes: the card on return (TR31), the first session measured (TR32), inspecting another player (TR33) and the chests' opening show (TR34).

**Phase 3's order from 2026-11-17, 11:12** (research's, on the director's word that the game comes before the Voidkin):
- **Faber:**
  1. TR36, the two attributes;
  2. AR16's three base sizes captured for the pick, which frees the map (AR17);
  3. TR28's bag rebuilt in the seam's skin (AR18), then TR40, Regen in bursts (the director, 12:54);
  3b. TR41, the passed screens never wired: the galaxy Breaker, Power's Eclipse images, the level-up notice, the shard's tag (research's audit, 2026-11-17, 14:05); then AR29's rail and bar on B;
  4. TR34, the chest opening on AR24's A;
  5. AR23, Combat Power's number;
  6. TR29's three fixes and TR10's marker captures;
  7. the Forge and the Stone Condenser, then emblems, then jewels (research writes each request first);
  8. TR31, TR32, TR33, TR35 and the responsive pass.
- **Modulo:**
  1. AR19's two notes: the dynamos and crown read as real-world parts, and the teeth are too wide;
  2. the Forge's and the Stone Condenser's look, three directions;
  3. AR22 again: the Chest Armor, Shoulders, Rings and Earrings marks, and the 15 Shoulders' pictures as one pauldron (the director, 12:19);
  4. AR17's map kit at the chosen base size;
  5. the icons for forge stones, emblems and jewels, and TR10's two.
  6. AR29, the Voidkin screen's rail and top bar on B (the director, 14:03), then AR30, every button in the game in that make.
  7. AR32, the Void Breaker's three stages (research, 16:37), then the bays' and the battery's in the design's order.
  8. AR35, the Training machine's three stages (research, 18:38), then the Forge's and the Condenser's.
  9. AR36, the Forge's and the Stone Condenser's three stages (research, 19:05).
  10. AR37, a stage lands: the moment a machine changes (research, 20:03).
  10b. AR39, the sound rescue's three pilots: briefs, shortlists and arrangements (the director's directive, 21:19), before AR38.
  11. AR38, the Void Shop: the building and its screen (research, 21:10).
  12. AR40, less purple and less black by day: three directions, captured in the place (the director's remark, 22:17), after AR39's first round; AR38's colour waits on its pick.
- **Research:** the Forge, emblem and jewel requests with their numbers, the verdicts as pieces land, then the Void Shop's and the Robux store's design, checked against Roblox's rules, for the director.

**The design review's follow-up, 2026-11-18** (the director's brief, evening; the decisions D1 to D8 in `docs/decisions.md`). Research's sort, in hours of active work, seeds. Built from the brief and the repo: this morning's pack wasn't seen, so the launch review's own list stands where it differs.
- **In, Faber:**
  1. the branch `claude/design-review-rules` cherry-picked onto main (four commits: Elemental Attack only with an element, the Tower's fixed opening five and sure first chest, salvage, "HP Regen"), then the self-test: 1 h;
  2. the stages on Normal and Hard, in grey, with their picker, locked tiles stating their condition, and the results naming what just opened and tomorrow's dailies (D2, 5.2): 4 h;
  3. the slam (`KeeperSignature`) in the Lamplighter's rotation, with its marked footprint, and the two lead-movement blocks on that fight, A (follow during a marked strike) and B (a Recall button, 4 s), for research's verdict and the director's pick: 4 h;
  4. gear's budgets by stage and difficulty, the sure usable first item, Hard's Keeper's Rare chance shown, and a line the fighter can't use dimmed with its reason (D7, 4.4): 3 h, after 2 and research's refit;
  5. Combat Power at a tenth, compared unrounded, and the cases that hold a scaled number (D3): 1 h;
  6. the salvage button on the item's card, "n / 300" on the bag, and a full-bag message that says how to free a slot (4.5): 2 h;
  7. the Tower: the results with Retry and Home, the heal cap explained the first time, one solo board, and foes drawn from a weekly seed with chests on the run's own (4.3; the seed is research's tier 2, taken): 3 h;
  8. bays 2, 3 and 4 with 5 and 6 locked (D5), "HP Regen" with "every 8 s" under it (4.6), and the Voidkin screen's "nothing worn yet" read from the preset (4.10): 1.5 h;
  9. the Void Shop's launch shelf in pure Luau with its cases (D6), in phase 4: 4 h;
  10. TR32's marks (section 6) before any stranger plays: 3 h;
  11. the Voidkin's names kept untranslated (D8): 0.5 h.
- **In, research:** the loot refit to 10 to 15 minutes (`chests.py --fit`, the Pace table's first row) and level 3's price (`sim.py`, section 15), before Faber's 4: 2 h; the Combat Power fit run again (section 16): 0.5 h; the verdicts on 2 and 3; what the Lamplighter's win shows at launch, with one ground (4.9): 0.5 h.
- **The director's hand:** translation's switch in Creator Hub (D8); the pick between A and B (3).
- **After everything else:** parties, with their health table and the AFK guard (D1, 4.2), in a reserved server.
- **After early access:** the second form (D4).
- **Research disagrees, one line:** the shop's draw on the Unix time can't be shared code alone, or a client predicts the next stock: it's salted on the server (`docs/design.md`, "The Strip").

**The Tower's room** (the director, 2026-11-19, by 11:12): built after the main game's open pieces, each player's own copy of one detailed room, with the entrance and the record's marker on the lot behind the base (`docs/design.md`, "The Tower"). Until then the grey Tower runs as it is.

**Phase 4. Breadth.** The Void Shop. The Rift moves after launch (the director, 2026-11-17, 02:40). Both shops, the Robux store and the Void Shop, are designed and set up here (the director, 2026-11-12).

**Phase 5. The Strip.** The Clash Grounds; the Calamity after launch (the director, 2026-11-15).

**Phase 6. Launch, as early access** (free to join, labelled Early Access on the game page and in its title: the director, 2026-11-17, by 12:16). First the finish pass: `docs/polish-later.md`, "The finish pass", with Fable if its one-effect trial earns it. Then the director's approval of the store (its design is done before phase 4's Voidkin), the game page, a real phone, a soft opening, then public on the director's go.

## The cut line

**One ground at launch** (the director, 2026-11-13, `docs/decisions.md`): the Festival of Battles opens on Lantern Row alone.
- **Five Voidkin at launch** (the director, 2026-11-17, 02:40): Rook, Kirra, Pip and Watt (Common) and Lyric (Rare), each perfected and looking its rarity.
  - Every one's basic attack and signature are its own, each with its own effect, at Anime Vanguards' level of flash. Each signature has its own sound; the basic attack's sound is one per class, shared by the class (the director, 2026-11-23).
  - Rook, Kirra, Pip and Lyric are redesigned now, one at a time, each on the director's acceptance (the director, 2026-11-23, by 22:52).
  - **Every Voidkin piece waits for the end** (the director, 2026-11-17, by 11:10): the basic attacks' effects (AR26), Ground Wire's fix (AR11) and the idles (AR27) are built with the finish pass. The game's systems come first.
  - Lantern Row's shards roll Common and Rare only: the guard drops each tier with no Voidkin made and keeps the rest's proportions, so about 87 and 13 in a Standard shard. An Enriched or Prismatic shard always gives Lyric.
- **Small named updates after launch, every 2 to 4 weeks** (the director, 2026-11-23, 15:06, replacing "1 massive updates" of 2026-11-17), carry everything delayed: Sable, Marigold and Crane, the Rift, the Research Lab, Drum Court and the grounds after it, and the Calamity. Each update has its name and its own featured stock in the Void Shop. Their order is set nearer launch. Why: Roblox's guidance (updates every 2 to 4 weeks; curation checks for at least monthly) and the five Voidkin's reveals running out early (`docs/research/design-holes.md`, H9).
- **Translation launches** (the director, 2026-11-18, D8): Roblox's automatic translation, switched on in Creator Hub by the director, with the Voidkin's names kept untranslated. No build hours.
- **What launches:** phases 0 to 4 and the Tower. The Clash Grounds launch if they're at the bar, and are in the update if they aren't.
- **The foundation** makes a new ground, Voidkin or effect mostly data and art, so the update is fast (`docs/engineering-plan.md`, its own section, Faber's).

## The date

**No new date is worked out** (the director, 2026-11-18: "no new launch date let not waste time and grind no more wasting time just planning and action"). The estimate below stays as it was written.

**Research's estimate, 2026-11-17, 02:31, kept as the record.** It's read from the commit clock, not measured.
- **The pace so far:** phases 0 to 2 and the first half of phase 3's blocks took the team about 76 hours with commits in them, 2026-11-12 to 17, about 15 a day.
- **What's left for the launch line** (phases 0 to 4, the Tower, one ground, Lantern Row's eight Voidkin):
  - phase 2's tail;
  - phase 3's rest: TR31 to TR35, the Forge and the Stone Condenser, emblems, jewels, research, the responsive pass, and each block's finish;
  - the launch five: Kirra and Watt to finish, then each one's own basic attack (an effect and a sound), and at the finish pass Rook, Kirra, Pip and Lyric redesigned. The three Voidkin no longer made before launch about pay for the four redesigns, so it's still the long pole (the director, 02:40);
  - phase 4: the Void Shop and the Robux store, designed, checked against Roblox's rules and approved;
  - phase 6: the finish pass at the director's bar of 2026-11-17, the game page, Roblox's maturity questionnaire, and a soft opening.
- **The earliest public date:** about Sunday 2026-11-29 if nothing slips, more likely the first week of December. Sunday 2026-11-22 isn't reachable at the bar.
- **The director's cut** (02:40): the Rift and the Research Lab move to the big update, and launch has five Voidkin. The date above stands, since the redesigns spend what the cut saves.

## The count

Pieces closed and playable this week, with hours: on the board (`docs/team-notes.md`).
