---
name: "ga-review"
description: The verdict research gives on a piece players see, at its checkpoints and its final. Felt, the measured gates, the comparison beside today's game and a shipped frame, the blind second reader, must-fixes. Load before any artistic review, and to know what a review will judge.
effort: high
---

# The verdict (research gives it; the makers read it)

The director, 2026-11-24, 20:52: a look passes against its picked target and the director's judged examples, never on research's eye alone. AI eyes judge pairs well and single scores badly (`docs/research/quality-and-speed.md`). Turing (2026-11-27) made every verdict a comparison (R2) with a blind second reader (R3), after five look verdicts were overturned as a whole (`docs/turing.md`).

**The form,** in order:
- **Felt:** one sentence, the piece watched once at full speed from the player's camera.
- **Gates, measured** on a phone-size capture. A failed gate is a must-fix, whatever the eye says.
  - The squint: blurred to thumbnail sharpness, the main shape and the one focal point still read.
  - Greyscale: the values group into a few masses, and the focal point holds the strongest contrast.
  - The silhouette at 64 px, for a character or a key pose: one figure doing one thing.
  - A screen: the UI lint (the style frame's tokens, text at 4.5:1, touch at 44 pt).
- **The comparison (R2):** the build beside today's game and a shipped game's frame, at the same size, and beside its picked target while it has one.
  - The dimensions are named before the work starts: the feel line or the three tests, the glance read on the smallest phone, the share of the screen, motion.
  - Each gets BETTER, UNCHANGED, WORSE or NOT VERIFIED against today's game, never an average. A still that fails in motion is WORSE. Without a shipped frame beside it, the verdict is NOT VERIFIED.
  - Read in both orders. The gaps are listed by where they sit, and whether each touches the main read (shape, focal point, colour or timing). If the two orders disagree, it's "no clear difference", never a pass.
  - Could our frame be taken for the shipped one? A yes is a finding, however well the piece matches (`handbook/platform/ip-safety.md`).
- **The blind second reader (R3),** for every direction and every signature piece: Gemini, or `ga-fresh-eyes` when Gemini's quota is out. It isn't told which version is new or what research thinks. A disagreement is recorded, never averaged.
- **Beside the examples:** is it nearer the director's accepted or rejected looks (`docs/research/examples.md`)? Only rows a later word hasn't superseded count (R6).
- **Must-fixes,** each one line, naming what it serves and its class.

**The pass line:** inside a picked direction, a piece passes when its main read is BETTER, no named dimension is WORSE, the gates pass, and it sits nearer the accepted examples. A new direction isn't research's to pass: it goes to the director as options, with no recommendation (R4). A piece without a picked target can't pass: its target comes first. Where the pair and research's eye disagree, the pair wins. Refinements beyond the pass go to `docs/polish-later.md`.

**What weighs:** composition, personality and impact at phone size. Motion is judged by its poses on a contact sheet and in play, and its timing by numbers, since models read fine motion poorly.

**The measures:** the picked target; the director's examples; the vision and the bar (`docs/north-star.md`, "The look" included); the style frame (AR62) once picked; the chapters under `handbook/visuals/`.

**For an effect, the technique comes first.**
- A shape with depth drawn on a camera-facing card is a finding before any number is.
- After two failed rounds, question the technique before the numbers (`handbook/visuals/vfx.md`).

**Precision,** for anyone reviewing: a pose or an effect beside the benchmark is read part by part (head, shoulders, arms, hips, legs and the silhouette at 64 px, or each layer of an effect), with a number for both sides, at full size, from every clear instance in the footage, at least three where they exist, from the same camera where possible. "The rig can't" or "a limit" stands only once a tried lever is shown.

**The checkpoints:** the pick before the build (the director's for a direction, research's for a target inside one); a direction's first piece in the game, judged on a phone, before anything else in it (R1); the build beside its target at a quarter and at half of its cap (a miss on the main read changes the technique or simplifies, never polishes); the final, from QA's pack. Two rounds on one cause, then the technique changes or the options go to the director with the images (R5).

**Fix rounds converge** (adopted 2026-11-17, from Anthropic's code review practice: capped rounds and re-reviewing only what changed brought its mean review rounds from 2.08 to 1.32):
- Each fix is a **must-fix**, which holds the pass. Anything less goes to `docs/polish-later.md` at once, never into the fix list.
- A fix names its **class**, so every instance is fixed at once, not only the one in the still.
- **A second look judges what changed:** the fixes, and anything they broke. An older problem seen then is raised only if it's a must-fix, and said to be older. A finding is never raised twice.
- **Accepting on cases** names what the cases can't show, and where it will first be seen.

**Where it goes:** once, in the piece's request entry, with the pair image's path. Nothing is written twice; link instead. Under eight lines, and no new document. Each word the director gives on a look adds a row to `docs/research/examples.md`, with the image the director saw.
