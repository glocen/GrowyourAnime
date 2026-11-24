---
name: "ga-review"
description: The verdict research gives on a piece players see, at its checkpoints and its final. The measured gates, the build beside its picked target, then beside the director's accepted and rejected examples, then Felt, the bold thing and fixes. Load before any artistic review, and to know what a review will judge.
effort: high
---

# The verdict, in pairs (research gives it; the makers read it)

Adopted on the director's word, 2026-11-24, 20:50 (`docs/decisions.md`). Why: research's verdict alone disagreed with the director's on every recorded look pick. Vision models judge reliably when comparing two images, and poorly when scoring one alone (`docs/research/quality-and-speed.md`). So a look is never judged alone.

**No target, no review.** A piece players see is judged beside the target the director picked (`AGENTS.md`, "target first"). Without a picked target, the piece goes back for one, and nothing is judged.

**The order, each step written in the entry:**
1. **The gates,** measured on a phone-size capture from the player's camera. A failed gate is a must-fix, whatever the eye says.
   - **The squint:** blurred to thumbnail sharpness, the main shape and the one focal point still read.
   - **Greyscale:** the values group into a few masses, and the focal point holds the strongest contrast.
   - **The silhouette at 64 px,** for a character or a move's key pose: one figure doing one thing.
   - **A screen:** the UI lint, once it exists. Only the style frame's tokens; text contrast at least 4.5:1; touch targets at least 44 pt.
   - **Motion:** timing by its numbers (frames from the beats), and poses on the stepped key-pose sheet and in play. Models read fine motion poorly, so a motion verdict never rests on stills alone.
2. **The pair:** the build beside its target, at the same size, from the same camera, read twice, once in each order. Name each gap by where it sits (the head, the panel's top left, the peak frame) and whether it touches the main read: shape, focal point, colour or timing.
   - If the two orders disagree, it's "no clear difference", never a pass.
3. **The examples:** the build beside the nearest accepted and nearest rejected example of its area (`docs/research/examples.md`). Which is it closer to, and why, in one clause.
4. **Felt:** one sentence, the piece watched once at full speed from the player's camera. Then **the one bold thing** that carries the read; if nothing does, that's the finding. Then **fixes,** each one line, each naming what it serves.

**The pass line:**
- A piece passes research when:
  - its gates pass;
  - the pair finds no gap on the main read;
  - it sits nearer the accepted examples than the rejected ones.
- Research's pass is needed, never enough: only the director's word accepts a look. Where the pair and research's eye disagree, the pair wins, and the gap goes to the director with both images.
- Refinements beyond the pass go to `docs/polish-later.md`.

**On a signature piece,** `ga-fresh-eyes` reads the same pair blind, beside research's.

**The measures:**
- the target the director picked;
- the director's examples;
- the style frame and its tokens (AR62), once picked;
- the vision and the bar (`docs/north-star.md`);
- the feel line;
- the chapters under `handbook/visuals/`.

The target is this game's reference. Footage of other games is for feel only, held by research, and never shown as the pair.

**Checkpoints per piece:**
- the target's pick (the director);
- a quarter and half of the cap, beside the target. A miss on the main read changes the technique or simplifies, never polishes, and after two techniques miss, the director picks from images (`AGENTS.md`, "Blocks first").
- the final, from QA's pack.

Two fix rounds on one idea, then the options go to the director with the evidence.

**For an effect, the technique comes first.**
- A shape with depth drawn on a camera-facing card is a finding before any number is.
- After two failed rounds, question the technique before the numbers (`handbook/visuals/vfx.md`).

**The side-by-side question,** whenever a piece is set beside another game's work: could our frame be taken for theirs? A yes is a finding, however well the piece matches. Mechanics are free, but copying a look and feel almost exactly can infringe (`handbook/platform/ip-safety.md`).

**Precision,** for anyone reviewing:
- A pose or an effect beside its target is read part by part, with a number for both sides, at full size: head, shoulders, arms, hips, legs and the silhouette at 64 px, or each layer of an effect.
- "The rig can't" or "a limit" stands only once a tried lever is shown.

**Fix rounds converge** (adopted 2026-11-17, from Anthropic's code review practice: capped rounds and re-reviewing only what changed brought its mean review rounds from 2.08 to 1.32):
- Each fix is a **must-fix**, which holds the pass. Anything less goes to `docs/polish-later.md` at once, never into the fix list.
- A fix names its **class**, so every instance is fixed at once, not only the one in the still.
- **A second look judges what changed:** the fixes, and anything they broke. An older problem seen then is raised only if it's a must-fix, and said to be older. A finding is never raised twice.
- **Accepting on cases** names what the cases can't show, and where it will first be seen.

**Where it goes:**
- Once, in the piece's request entry, with the pair image's path. Nothing is written twice; link instead. Under ten lines, and no new document.
- A verdict the director gives on a look adds a row to `docs/research/examples.md`, with the image the director saw, committed.
