# The player-facing assessment (research, 2026-11-27, 23:5x)

An answer to ChatGPT's review of 2026-11-27 (pasted by the director). It's research's own read. Gemini's and Codex's independent reads were stopped by low memory and will be added as a second pass. Evidence: the director's rejections of 2026-11-27, our captures, and Codex's read of the world code (`codex/transcripts/2026-11-27_maps-code.md`). Times are active hours, and they're estimates (HYPOTHESIS) unless marked.

## The review, assessed

- **Right: the gap is real.** In one day the director rejected the icon (three rounds), the thumbnails, the 2D fire, the HUD's left, Lantern Row, the keeper's ring, the main map, and the old makes in the page images. Each had passed our own checks or was in progress. Our verdicts pass pieces that fail in the whole frame.
- **Right: documentation is out of proportion.** Research's own commits today are mostly word logs, records and messages. That changes (below).
- **Disproportionate: "a comprehensive audit of everything."** Ten audits would be ten documents, the failure the review warns about. One recorded first ten minutes, at phone size, beside a shipped game's first ten minutes, finds the problems that matter. The gate below replaces the audit.
- **Not the problem: engineering.** No architectural overhaul is planned. The checks are cheap and they keep valuables safe. Art direction and world design hold the game back, not code.
- **Agreed: experiential acceptance.** Feel lines and verdicts exist per piece. What's missing is a gate on the whole session.

## The greatest weaknesses, worst first

| # | Weakness | Underlying cause |
|---|---|---|
| 1 | **The worlds read as test spaces:** a straight street, the boss on a plain disc, a base with floating signs | The world code lays them out for function (OBSERVED, `WorldService`), and no one owned them as designed places |
| 2 | **2D art below the genre:** the icon, the UI art, the portraits | Code-drawn vectors and 3D renders by an AI without an eye on the canvas. AI 2D art (the director's yes, 2026-11-27) is the technique change |
| 3 | **Effects read as flat stickers** (the fire) | Outlined flame pictures on flat cards and Beams (OBSERVED in the engine, AR69) |
| 4 | **The cast isn't whole:** Pip's new make is unfinished, and Rook's face and his Haymaker aren't verified | Seven-plus rounds on hair, and makes rejected as corny or as sketches before the current make |
| 5 | **The first ten minutes are unproven as a whole** | Retry after a fall is NOT VERIFIED, and seven first-session sounds are missing |
| 6 | **The HUD's left cluster** | Rejected by the director (AR74) |

**Causes under all six:**
- Pieces are judged one at a time, cropped, while the director judges the whole frame.
- Studio runs one at a time on 15.5 GB, so every in-engine look waits in a queue.
- Six sessions spend hours on hand-offs.

## Launch-critical, fixed now

Everything else waits until after launch unless the director names it.

| Piece | Who | Depends on | Hours |
|---|---|---|---|
| The icon and three thumbnails: S2 finished beside a painted AI take, the director picks | Modulo, research | the director's pick | 3 to 5 |
| The fall and the burn (AR69 round 1) | Scintilla, Faber | a Studio turn | 2 to 3 |
| Rook verified: face, Haymaker, hair | Faber, research | a Studio turn | 1 |
| Pip's new make (AR63) | Modulo | — | the critical path; Modulo's estimate |
| The keeper's arena | Tessera (meshes), Faber (code) | the director's pick of a target; Tessera opened | 4 to 6 |
| Lantern Row re-laid (the S-curve, four landmarks) | Tessera, Faber (the gate fix) | the pick | 6 to 9 |
| The base: its three lifts | Tessera, Faber | the pick | 4 to 6 |
| The HUD's left (AR74) | Modulo, Faber | — | 2 to 3 |
| The seven missing sounds | Sonus, Faber | a Studio turn | 2 |
| Retry after a fall, and Rook's respawn place | Faber | — | 1 |
| **The gate:** a recorded first ten minutes at phone size, beside a shipped game's | Faber (capture), research and a blind reader, then the director | all of the above | 1 to 2 |

Total: about 30 to 45 active hours of making, spread over four makers and gated by the Studio queue (HYPOTHESIS).

## After launch

- Pip's throw, rebuilt with the fire kit, and Gemini's extra fire layers (scorch, twisted meshes, ribbons).
- A melee lead losing long fights to a ranged rival (TR73), before any long fight ships.
- The UI's painted art beyond the HUD's left (card art, portraits through AI 2D art), unless the gate shows it's launch-critical.
- The polish-later list, at the director's whole-game review.

## How the engineering speeds this up

- **Worlds laid out by code:** a new street or arena is a code change. It's tested, rolled back with git, and the same in every place.
- **The self-test's capture tools** record the gate's first ten minutes without a manual sitting.
- **One fire kit** (the two-layer streak, the band ring, stretched sparks) serves the fall, the burn, Pip's throw and any later flame.
- **Gemini and Codex as cold readers,** asked to disagree, at no added cost.

## Against perfectionism

- **The list above is the launch.** A new idea goes to `docs/polish-later.md` unless the director names it.
- **Two rounds on one cause, then the technique changes** (R5). A third round of the same fix doesn't happen.
- **The gate decides readiness,** not a sum of piece verdicts.

## What research changes in its own work

- Verdicts on whole-frame captures, never on crops alone.
- Records of a few lines, and messages only when someone must act.
- No word-log commit per remark: one at each piece boundary.
