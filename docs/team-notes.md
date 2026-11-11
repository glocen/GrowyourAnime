# Team notes

## Now

Each teammate rewrites its own row: two to five lines. Open asks sit under "Waiting on the director".

**Quaestor (research).** 2026-11-11: the design is written from the director's package and words: `docs/north-star.md`, `docs/design.md`, `docs/balance.md` with its simulation, `docs/ui.md`, `docs/roster.md`, `docs/decisions.md`, the plan and the first requests. Next: TR2's verdict when the circuit runs; AR1's sheet when it's drawn. On Opus 5.5 high from the next session.

**Faber (builder).** 2026-11-12: TR1 done (`docs/test-requests.md`): the repo joined and pushed, the kit in, both guards live, the three calls in `docs/engineering-plan.md`. Next: TR2, the circuit in grey, starting with its data contract and the save layer. The package's changes (research's tier 2 notice): I read them at TR2's start and answer here.

**Modulo (assets).** Not started here. First: AR1, Rook to the bar and timed, starting with his sheet; then AR2 the Shade and AR3 the UI kit's direction sheet (`docs/asset-requests.md`).

**Turns.** Studio: nobody. Blender: nobody. Timing tests: nobody.

**The count.** Pieces closed and playable this week: 0.

### Waiting on the director

Nothing blocks the start. When you want them (`docs/decisions.md`, "Waiting on the director"):

1. A second look at gear belonging to the account, before phase 3.
2. The cut line for launch, once Lantern Row is at the bar.
3. The store's design, before anything is sold.

### Notices

- Tier 2, research, 2026-11-11: the changes from the package (`docs/decisions.md`, "What changed from the package"). Faber and Modulo: say in your row what you'd change.
- Research, 2026-11-11: every number in `tools/balance/seeds.json` is a seed. Simulated, not played.
- Tier 1, Faber, 2026-11-12: Server Authority is off, and the place runs `AuthorityMode` Automatic (`docs/engineering-plan.md`, "The builder's calls"). Modulo: by the handbook, a clip registered from a `KeyframeSequence` plays in a playtest under Automatic, unpublished (`handbook/art/animation.md`).
- Faber, for research, 2026-11-12: the director's word that the player's avatar is R6 only, for the register; and the handbook's lessons from the kit's first run here. Both are in TR1's entry.

## Entries

### 2026-11-12. Day one: the repo, the kit, the calls (Faber)

- **What:** the repo joined to GitHub and pushed. The kit is in `src/`: remotes, live numbers, presets, the debug bridge, the self-test, the logic tests. Both guards are installed. The starter is trimmed to one role, and three calls are made: ProfileStore kept under our own save layer, Server Authority off, pure rules run with Studio closed under Lune.
- **Where:** `docs/test-requests.md`, TR1; `docs/engineering-plan.md`, "The builder's calls"; `tools/checks/`.
- **Tested:** the self-test 11 of 11, the logic tests 29 of 29 in Studio and offline, the type check `0 new`, the hooks' self-test 126 of 126.
- **Open:** the place waits for a save to keep `AuthorityMode` Automatic. The next piece is TR2.
- **For:** everyone who runs a check: the commands are in `.claude/skills/ga-studio-test/SKILL.md`.

### 2026-11-11. The design, the balance model and the start of production (research)

- **What:** the director's package of 2026-11-11 read whole and turned into the game's own pages. Eighteen open decisions answered. Balance rebuilt so nothing compounds, and tested by a simulation (`py tools/balance/sim.py`). Thirty-one Voidkin, the Shades and six grounds authored. The HUD's direction. The first requests: TR1, TR2, AR1 to AR5.
- **Where:** `docs/`; `tools/balance/`. The package itself is in `docs/archive/package-v13/` (kept out of git: it's large, and partly superseded). The directive of 2026-11-09 is in `docs/archive/`.
- **The folder** is now `C:\Users\gloce\GrowyourAnime`, with `origin` set. The kit was refreshed from the studio's corrected templates.
- **Tested:** the simulation only. Nothing is built, nothing is played, nothing is drawn.
- **Open:** the local history and the remote's first commit aren't joined, so nothing is pushed yet (TR1's first step). The ids aren't checked. The handbook clone here is behind.
- **For:** everyone. Start at `docs/north-star.md`, then your row.
