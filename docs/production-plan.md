# Production plan

What's next, in order. The design is in `docs/north-star.md` and `docs/decisions.md`. A status changes here and nowhere else.

**Status, 2026-11-09:** preproduction. The folder and the foundation exist. Nothing is built, and no place exists.

**The aim** (the director, `docs/directive.md`, sections 1 and 17): "Build an excellent small experience first. Design its foundations intelligently. Expand through justified systems." Every estimate here is a guess until a piece has closed.

## How we run here

- The rules: `AGENTS.md`. The process stays light: this repo keeps the vision, the design, the decisions, the contracts, the backlog, the risks, the asset log, the tests and the current state. Everything about how the studio works is in `handbook/`, linked and never copied.
- The director, 2026-11-09: "dont bother with what was said about project lynx framework ... we will use our brand new one". So where the directive describes LYNX (section 16, and item G of section 22), the studio's own LYNX in the handbook is what holds.
- LYNX runs one experiment at a time, between pieces: `handbook/studio/lynx.md`. This game's three: `docs/engineering-plan.md`, "New experiments".
- A piece is a request entry: `docs/test-requests.md` for the builder and QA, `docs/asset-requests.md` for the makers.

## The team

Research's recommendation, 2026-11-09, on the director's "think how much of the Teammates we need": **five seats at most, three to start.**

| Seat | Who | From | Why |
|---|---|---|---|
| Design, research, quality | Quaestor | now | the decisions, the numbers, the verdicts |
| Code | Faber | now | the data, the rules, the base, the fights, the screens |
| Fighters | Modulo | Wednesday 2026-11-11 (AR1) | each fighter's model, clips and the look of its skill: the game's main content |
| QA | Probator | the slice's first playable (step 2) | fighters are valuables: someone must try to duplicate, lose and break them, and run two players. Before a build there's nothing to test |
| World and screens' art | Tessera | once the grey slice is proven (after step 3) | the base kit, the pods, the plaza, the arena and the screens' art kit, so Modulo stays on fighters |

- **Not opened:** a level designer (the map is one small ring: research lays it out, and Tessera builds it); a second fighter artist, unless the count shows fighters are what the team waits on.
- **The limits are the PC's:** 15.5 GB of memory, two Studios at most, one Cycles render at a time. Every open tab spends tokens while it works, so a seat opens when work waits for it.
- The launcher, `tools/team-terminal.cmd`, calls everyone with one key. A seat joins it by taking `rem` off its line.

## The slice

The smallest loop that proves the game (the directive, section 17). Grey boxes until step 3. One step at a time, each judged before the next.

| Step | What exists at its end | Who | It's proven when |
|---|---|---|---|
| 0. Day one | the kit, the place, the boot, the type check, the choice of save library (TR1) | Faber; the director's two hands below | Studio boots clean on both sides; the self-test runs |
| 1. The grey loop | a base, two Void Breakers, a shard grown by hand, two grey fighters, one that powers the base, credits ticking from the spare, a roll on each break, a stall that sells the next shards, and three floors (TR2) | Faber, to research's feel line | the first three minutes are timed against `docs/north-star.md`, and research's verdict says they want a fourth |
| 2. Keeping it | saving, a fighter's unique id, each transaction safe to repeat and to interrupt; leave, rejoin, the same state | Faber; QA joins | the logic cases on repeats and interruptions pass, and a real leave and rejoin holds |
| 3. The first fighter | one original fighter at the bar: model, pose, idle, training loop, attack, one skill with its effect; the reveal as the signature moment | Modulo, Faber | research's verdict and a blind read on the reveal; the director's eye |
| 4. A small game | three fighters, the Tower's first floors, the shop's real rotation from the clock, batteries and the hours away, the Index's first page, the first screens on one kit | all | a session of ten minutes has something to do in every minute, and a night away comes back to a base that worked |
| 5. Neighbours | several bases round the plaza, joins and leaves, two real players, a phone | all; the director | two players see each other's reveals; the phone holds its frame rate |

After step 5 the slice gets a whole-game verdict, and what comes next is chosen from what was measured: traits, mutations, stars, the Grid's deeper layers, the arena, Calamity, the player's own progress (`docs/design.md`). None of those is a commitment yet, and each enters through its own blockout.

**The date:** the director, 2026-11-09, wants the team at work on Wednesday 2026-11-11 "with a clear vision". Until then research closes the foundation: the cold read is in (`docs/research/cold-read.md`), and the director's answers are still to come. Step 0 starts that Wednesday.

## Content

- **Fighters.** A design sheet first: silhouette, stance, one signature move, palette, in grey. Then the model on the R6 rig, the clips, the effect's look. Three for the slice, one of each type (close, blade, ranged). The launch count is open (`docs/decisions.md`).
- **The world.** The director's map: eight bases in two rows across a Strip that holds the shop, the arena and the Calamity ground, with a Tower behind each base (`docs/design.md`, "The map"). A base is a kit of pieces on slots, so a theme or a layout is data later.
- **Screens.** One kit before any panel: the type, the colours, a card, a button, a rarity treatment. First three screens: the stall, the fighter's card, the fight's HUD. Phone first.
- **Effects** go through the studio's effect player, once the craft upgrade delivers it (NEXT Button's repo, `docs/test-requests.md`, TR43).
- **Sound** from Roblox's audio library, each cue heard in the game and logged (`AGENTS.md`, rule 2).

## The director's hands

What only the director can do, when the step needs it:

1. **An empty private GitHub repo** for this game. Until it exists, commits stay on this PC.
2. **A new experience under the studio's group,** and its place opened in Studio with Rojo connected on port 34876 (step 0).
3. **A real second player and a real phone** (step 5).
4. **The answers research asks for** under "Waiting on the director" on the Now board. Few, and only what changes the game's identity, economy, scope or risk.
