# Turing: how the studio works

Research, 2026-11-27, 12:24. Written in on the director's word of 12:24 ("write it now ... he helped a lot let built on top of it"), on research's yes to the restatement (03:47; `docs/decisions.md`). Built from the director's Turing document v1.5 (with GPT) as a helper, Gemini's part 1 and draft (u1, u2), the lean audit's parts 1 to 4, and research's own read. The draft and the sources: `build/scratch/quaestor/turing/`.

**What it's for.** Better work reaches the game with less wasted work, and the studio gets easier to run. Research informs a decision, and evidence closes it. The director decides the looks and the core. The four supreme rules don't change.

## Why: where the work was lost (measured, 2026-11-26 and 27)

- **Look verdicts overturned as a whole:** research's pass of the press I1, its pick and pass of B, its pick of F2 ("a sketch"), its recommendation of the painted HUD, and AR65 and AR67 passed piece by piece ("a prototype"). AR64's hair took seven rejected rounds. Sources: `docs/research/examples.md` and the register.
- **False greens:** the self-test said PASSED when it had run no case (fixed, bef56ab4).
- **Reading load:** about 1,200 lines at each session's start, registers of 1.4 MB, and 236 of 520 commits docs-only since 11-20.
- **One PC with 15.5 GB:** Gemini's runs were reaped for low memory twice.

## The rules, where they sit

| # | The rule, in short | Home |
|---|---|---|
| R1 | One piece first: a picked direction's first piece is built in the game and judged on a phone before anything else in it | AGENTS.md, "Every action, world, effect and screen" |
| R2 | Every verdict is a comparison, beside today's game and a shipped frame, BETTER/UNCHANGED/WORSE/NOT VERIFIED on named dimensions | AGENTS.md, same section; `ga-review` |
| R3 | A blind second reader for every direction and signature piece | `ga-review` |
| R4 | A new direction goes to the director as options, with no research recommendation; research picks inside a direction | AGENTS.md, "The pick" |
| R5 | Two rounds on one cause, then the technique changes or the director decides | AGENTS.md, "Two rounds, then the technique" |
| R6 | A like holds for its piece at its moment; second-hand words stay UNVERIFIED | AGENTS.md, "The director's words keep their scope" |
| R7 | Evidence has a date; a check that ran nothing says NOT VERIFIED | AGENTS.md, "Evidence has a date" |
| R8 | Measure only what changes a decision, always with a quality gate | `docs/briefs/research.md` |
| R9 | Nobody changes the director's PC without the director's word for that change | AGENTS.md, "The director's PC" |

## The floor, kept by tools instead of memory

| Tool | What it does | Owner | State |
|---|---|---|---|
| The self-test verdict | FAILED, then NOT VERIFIED, then PASSED; frames counted on RenderStepped | Faber | done (bef56ab4) |
| The reference guard | Takes scripts write their beside sheets into `build/reference/`; a pre-commit check refuses any `*_beside*` image, or a reference game's folder name, outside it. It exempts `_beside_target` | Modulo (scripts), Faber (the check) | done (f1e8f437) |
| The memory guard | Before a Studio playtest or a Blender render, it reads free memory and the locks; below 2 GB, or with a render running, it refuses and names the holder. If the hook itself errors, it warns and lets the call through. Still to fix: it refuses a Blender launch when the lock is the launcher's own | Faber | done (28d93e06), one fix open |
| The lint freeze | `luau_check.py --freeze` only shrinks | Faber | done (1589991e) |
| The logic runner's verdict | The server's logic runner says PASSED only with assertions run, like the client's `Verdict.Of` | Faber | to fix (Codex, 13:21) |
| One Studio at a time | Replaces "at most two Studios" | everyone | in force |

## Less to read: the lean initiative, under Turing

Turing adopts the direction now: the registers hold open work, closed entries and old words move to archive files no session loads, the Now board holds rows and live notices only, and the briefs hold only what differs for their role. The exact cuts come in their own restatement, for the director's yes, once the lean audit is complete. Done: parts 1 to 4 by Gemini (`build/scratch/quaestor/gemini/transcripts/`, lean-l1 to l4), and 5 to 7 plus a check of these rules by Codex, on the director's word of 12:41 (`build/scratch/quaestor/codex/transcripts/`, lean-c5 to c7, turing-c8). Gemini comes back after its weekly reset to say what to add or remove. **The order:** before Sunday's early access, only the release fixes (the Hard keeper, the logic verdict, the live round trip). The cuts come after, in their restatement.

Gemini's draft numbers are the starting proposal: `decisions.md` live at 16 KB or less with the words kept whole in a monthly log; one file per open piece, 55 lines or less; the Now board at 70 lines or less; about 63% less read at each session's start.

## Pilot 1: the look gate (R1 to R4), on AR68

- **Owner:** research.
- **Baseline:** the last five look verdicts on the UI and the base, all overturned as a whole.
- **Measure:** of the next three look pieces under the gate, counted at the director's first view in the game (AR68's first fight-HUD piece, Kirra's AR60 cut, the next look piece), how many the director overturns as a whole ("horrendous", "a prototype", "redo it"). The picks are logged apart: AR68's system was research's, on the director's "you choice" (13:08). With no such view within five days, the pilot is NOT VERIFIED.
- **Stop:** two of three overturned. Then the gate is redesigned: the director picks anchor frames before any research pick. Also stop if a specimen needs more than two rounds, or more than six team hours, to reach a phone capture.
- **Length:** three decisions or five days, whichever comes first. Everything is in git.

## Not adopted, with the reason

- **Appendix B as a standing document, phases A to E, A/B session trials, screening quotas, shadow full runs:** their running cost beats their gain.
- **Speculative runtime optimizations** without a profiler trace.
- **The six "the director said" lines in Appendix B** that aren't in the register: they wait for the director (R6).
- **WIP of three pieces at most, studio-wide:** it would idle makers, against the director's word ("Makers never idle"). One piece at a time per teammate already holds.
- **Code standards** (fixture-aggregated tests, the src/shared split, pure Rules, events over polling): proposals to Faber in his own area, not Turing rules.
- **Dropping the quarter-cap check:** no evidence yet; revisited after pilot 1.
