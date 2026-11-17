# Production plan

What's next, in order. The game is in `docs/north-star.md`, its systems in `docs/design.md`. A status changes here and nowhere else.

**Status, 2026-11-17, 10:09:** phase 3 is open, on the director's word (`docs/decisions.md`, 02:31: "phase 3 can start when it can dont need to wait for me"). Its first package is in the game as blocks (TR25 to TR30). Phase 2's tail runs beside it: the Door (installed at 09:01; research passed it and its sign's fix, and it closes on research's side), Sable's guard (in at 10:09: only a made Voidkin comes out of a shard; TR24, "Sable's guard"), the lead card's fixes, the Breaker's pictures, the timing cases, and AR13 for the director's ear.

**The aim:** a premium game (`docs/north-star.md`, "The bar"). One ground at the bar before six grounds in grey.

## How we run here

- The rules: `AGENTS.md`. A piece is a request entry: `docs/test-requests.md` for the builder and QA, `docs/asset-requests.md` for the asset maker.
- **Lighter:** one write per piece, one home per fact, no document that isn't a rule, a design, a request or the board.
- **Quality:** every piece players see goes feel line, blockout, build, review from the player's camera. Research's verdict closes it.
- **Numbers** live in the seeds, then in the game's Definitions, and are tuned by playing with them exposed at runtime.
- LYNX runs one experiment at a time, between pieces: `handbook/studio/lynx.md`.

## Who makes what

The director asked, 2026-11-11, whether Modulo should make all the HUD design, the UI textures and effects, textures and the map. **Yes for everything that's a look, with an order, and with two things split off.**

| Work | Who | Note |
|---|---|---|
| Voidkin and Shades: models, textures, clips, the look of each signature | Modulo | the game's main content, and always first in Modulo's queue |
| The UI kit: frames, icons, bars, the two themes, the look of interface effects | Modulo, from `docs/ui.md` | one kit, made once |
| Where things sit on a screen, what shows when, the hierarchy | Quaestor | `docs/ui.md` |
| Building the screens and making them behave | Faber | from one component library |
| The world kit: stalls, lanterns, gates, the base's machines | Modulo | after the first three fighters |
| The map's layout: where grounds, gates and bases sit | Quaestor lays it out in grey, Faber installs it | a level designer isn't opened |
| Effects in the engine: timing, hit-stop, camera | Faber, to Modulo's look, in the same session | `/ga-action` |
| Sounds | Faber picks from Roblox's library to research's cue list | `AGENTS.md`, rule 2 |

One maker is one queue. If the board's count shows the team waiting on Modulo for more than a piece at a time, research proposes a second art seat (environment art) to the director. Not before.

## The team

| Seat | Who | From |
|---|---|---|
| Design, research, quality | Quaestor | now |
| Code | Faber | now |
| Art | Modulo | now |
| QA | Probator | at phase 4's end, for the whole game before launch (the director, 2026-11-13). Through phase 4 the team stays three; level design and environment art aren't opened, since the grounds are one kit recoloured (`docs/roster.md`). Until then, the builder's checks and player-camera captures are a piece's evidence, and research reads them as QA would: the test output, the angles still missing, what regressed |

The PC's limits hold: two Studios at most, one render at a time. A seat opens when work waits for it.

## Models

The director's words, 2026-11-11 (`docs/decisions.md`): Modulo on Fable 5.2 high; Quaestor and Faber on Opus 5.5; a Fable pass later on whatever needs it.

- **Quaestor: Opus 5.5 high** from the next session. Research asks the director for Fable only for: the store's design, the retune after the first real play data, or a verdict the team disputes.
- **Faber: Opus 5.5 xhigh.** Good for this work when each piece has a tight request and its tests. What gets a Fable read first when the reset comes: `docs/engineering-plan.md`, "For the Fable pass". A read, not a rewrite, unless the read finds one is needed.
- **Modulo: Fable 5.2 high.** The look is where the bar is won. From 2026-11-12, Opus 5.5 xhigh until the Fable limit resets, then back on Fable 5.2 high (`docs/decisions.md`, 2026-11-12). Later on 2026-11-12, back on Fable for the last 9% of its usage. From 2026-11-13, Opus 5.5 xhigh again: Fable's usage is at 100% (the director: "he will be back on opus so record we are at 100% for fable"), and Fable returns at its reset, this weekend (the director, 2026-11-13: "he will be back on fable this weekend, his approaches to art as fable so far is incredible"). Each delivery names its model.

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

**Phase 4. Breadth.** The Void Shop. The Rift moves after launch (the director, 2026-11-17, 02:40). Both shops, the Robux store and the Void Shop, are designed and set up here (the director, 2026-11-12).

**Phase 5. The Strip.** The Clash Grounds; the Calamity after launch (the director, 2026-11-15).

**Phase 6. Launch, as early access** (free to join, labelled Early Access on the game page and in its title: the director, 2026-11-17, by 12:16). First the finish pass: `docs/polish-later.md`, "The finish pass", with Fable if its one-effect trial earns it. Then the director's approval of the store (its design is done before phase 4's Voidkin), the game page, a real phone, a soft opening, then public on the director's go.

## The cut line

**One ground at launch** (the director, 2026-11-13, `docs/decisions.md`): the Festival of Battles opens on Lantern Row alone.
- **Five Voidkin at launch** (the director, 2026-11-17, 02:40): Rook, Kirra, Pip and Watt (Common) and Lyric (Rare), each perfected and looking its rarity.
  - Every one's basic attack and signature are its own, each with its own effect and sound, at Anime Vanguards' level of flash.
  - Rook, Kirra, Pip and Lyric are redesigned to the anime bar at the end, in the finish pass.
  - **Every Voidkin piece waits for the end** (the director, 2026-11-17, by 11:10): the basic attacks' effects (AR26), Ground Wire's fix (AR11), the idles (AR27) and the redesigns are built with the finish pass. The game's systems come first.
  - Lantern Row's shards roll Common and Rare only: the guard drops each tier with no Voidkin made and keeps the rest's proportions, so about 87 and 13 in a Standard shard. An Enriched or Prismatic shard always gives Lyric.
- **One big update after launch** carries everything delayed: Sable, Marigold and Crane, the Rift, the Research Lab, Drum Court and the grounds after it, and the Calamity.
- **What launches:** phases 0 to 4 and the Tower. The Clash Grounds launch if they're at the bar, and are in the update if they aren't.
- **The foundation** makes a new ground, Voidkin or effect mostly data and art, so the update is fast (`docs/engineering-plan.md`, its own section, Faber's).

## The date

**Research's estimate, 2026-11-17, 02:31.** It's read from the commit clock, not measured.
- **The pace so far:** phases 0 to 2 and the first half of phase 3's blocks took the team about 76 hours with commits in them, 2026-11-12 to 17, about 15 a day.
- **What's left for the launch line** (phases 0 to 4, the Tower, one ground, Lantern Row's eight Voidkin):
  - phase 2's tail;
  - phase 3's rest: TR31 to TR35, the Forge and the Stone Condenser, emblems, jewels, research, the responsive pass, and each block's finish;
  - the launch five: Kirra and Watt to finish, then each one's own basic attack (an effect and a sound), and at the finish pass Rook, Kirra, Pip and Lyric redesigned. The three Voidkin no longer made before launch about pay for the four redesigns, so it's still the long pole (the director, 02:40);
  - phase 4: the Void Shop and the Robux store, designed, checked against Roblox's rules and approved;
  - phase 6: the finish pass at the director's bar of 2026-11-17, the game page, Roblox's maturity questionnaire, and a soft opening.
- **The earliest public date:** about Sunday 2026-11-29 if nothing slips, more likely the first week of December. Sunday 2026-11-22 isn't reachable at the bar.
- **The director's cut** (02:40): the Rift and the Research Lab move to the big update, and launch has five Voidkin. The date above stands, since the redesigns spend what the cut saves.
- The estimate is updated on the board each week.

## The count

Pieces closed and playable this week, with hours: on the board (`docs/team-notes.md`).
