# Production plan

What's next, in order. The game is in `docs/north-star.md`, its systems in `docs/design.md`. A status changes here and nowhere else.

**Status, 2026-11-12:** phase 0 done (TR1): the repo is joined and pushed, the kit and both guards run, the builder's three calls are made. Phase 1 starts with TR2, the circuit in grey. Nothing players see is built yet.

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
| QA | Probator | when the director decides (2026-11-12): not at phase 1's end. Until then, the builder's checks and player-camera captures are a piece's evidence, and research reads them as QA would: the test output, the angles still missing, what regressed |

The PC's limits hold: two Studios at most, one render at a time. A seat opens when work waits for it.

## Models

The director's words, 2026-11-11 (`docs/decisions.md`): Modulo on Fable 5.2 high; Quaestor and Faber on Opus 5.5; a Fable pass later on whatever needs it.

- **Quaestor: Opus 5.5 high** from the next session. Research asks the director for Fable only for: the store's design, the retune after the first real play data, or a verdict the team disputes.
- **Faber: Opus 5.5 xhigh.** Good for this work when each piece has a tight request and its tests. What gets a Fable read first when the reset comes: `docs/engineering-plan.md`, "For the Fable pass". A read, not a rewrite, unless the read finds one is needed.
- **Modulo: Fable 5.2 high.** The look is where the bar is won. From 2026-11-12, Opus 5.5 xhigh until the Fable limit resets, then back on Fable 5.2 high (`docs/decisions.md`, 2026-11-12).

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
- Pip's Lantern Burst look on the replay, Modulo's part of fix round 2, when made (AR4, section 8)

## Phases

Each ends on something playable. No dates are promised past phase 1: see "The date".

**Phase 0. Day one** (TR1). The repo joined and pushed, the ids checked, the kit and Rojo running, the builder's three calls made.

**Phase 1. The circuit, in grey** (TR2, AR1, AR2). The whole loop with stand-ins: a base, the Breaker with chambers, three starter shards, a lead that fights by the real rules, Shades as boxes, Lantern Row as a grey street, a Named shard, a bay, electricity, saving. It answers: is the loop worth playing before any art? Meanwhile Modulo makes Rook and one Shade to the bar, and times them.

**Phase 2. One ground at the bar.** Rook, Pip and Lyric finished and timed. Lantern Row dressed. The HUD, the reveal and the Breaker screen on the real kit. The Lamplighter. The first session reviewed whole, from a phone. This is the game's proof and its advert.

**Phase 3. The build.** Regalia with presets, the bag, the Forge and the Stone Condenser that feeds it, emblems, jewels, research. Grounds 2 and 3. The Tower's first floors. The director's second look at gear-as-the-account's comes before this phase builds it.

**Phase 4. Breadth.** Grounds 4 to 6, the rest of the roster as each reaches the bar, the Void Shop, the Rift.

**Phase 5. The Strip.** The Clash Grounds, the Calamity.

**Phase 6. Launch.** The store's design and the director's approval, the game page, a real phone, a soft opening, then public on the director's go.

## The cut line

The director's, set once phase 2 is judged. Research's recommendation until then: launch needs phases 0 to 4 and the Tower. The Clash Grounds and the Calamity launch if they're at the bar, and are the first update if they aren't. A Voidkin below the bar waits for an update: the count at launch is what's finished. That count is a floor, not a cap (the director, 2026-11-12, `docs/decisions.md`). At least Rook, Kirra, Pip, Watt and Lyric, and up to eight with one Uncommon, one Epic and one Legendary, whatever is finished when the systems are ready. Updates follow soon after launch. A faster launch comes from cutting systems here, not the roster.

## The date

Sunday 2026-11-15 was the hope. For this game at this bar it isn't reachable, and saying otherwise would cost the bar. What's honest today:

- **Phase 1** is days of the builder's work. It's the first thing the director can play.
- **Everything after** depends on what one Voidkin costs to make. Nobody knows until Rook, Pip and Lyric are timed (AR1, AR4). Thirty-one of them is the long pole.
- Research gives a dated estimate when phase 1 closes and three fighters are timed, and updates it on the board each week.

## The count

Pieces closed and playable this week, with hours: on the board (`docs/team-notes.md`).
