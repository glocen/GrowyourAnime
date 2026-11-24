# Why our hair reads messy and theirs clean

Modulo, 2026-11-24, 21:38, on the director's word on AR64's first spike takes: "those hair are still messy do research". It feeds AR64. The labels:
- **OBSERVED:** seen in an image.
- **DESIGN:** ours, for the takes.

The images stay internal (`build/reference/anime-vanguards/`, `build/scratch/modulo/study/`).

## What was looked at

- **Anime Vanguards:** eight unit renders, their heads cropped at full resolution: `ichiga`, `kinnua`, `genitsu`, `noruto`, `jon`, `shinzi`, `rukio`, `todays-strongest` (`study/hs1.png`, `hs2.png`); `compare_heads.png`.
- **Ours:** today's Rook (AR59's pick) and Kirra (AR60), and the first spike takes (`hair/rook/busts.png`, 21:35).
- **The web:** two searches and one article (80.lv, Kensyouen_Y's anime hair). Nothing measurable. One idea came from the search, from a CG Cookie guide's search summary: big shapes make the silhouette, the clumps sit inside them. The guide's page itself refused the fetch. The answer came from the images.

## What theirs does, and ours didn't (OBSERVED)

1. **The hair comes down over the face.** On seven of the eight units the fringe reaches the brows, or the eyes. The sides cover the head's top corners and come down past the ears. The block of the head never shows above the brow. Ours sat on top of the head like a cap, over a bare forehead, with a hard line across it.
2. **One mass from one crown.** Every lock runs out from one point near the top, back, and turns down the head to its edge. Ours had rows of locks combed different ways, which crossed at the crown.
3. **Locks touch at the root and part only at their ends.** Each lock is wide where it starts and overlaps its neighbours, so the silhouette is one shape with a toothed edge. Ours stood apart, with the dark scalp showing between them: the "artifacts".
4. **Round locks, lit ridge, dark edges.** Each lock is round over its top and smooth-shaded. Its ridge is the light colour, and it falls to a dark edge where it meets the next. That gives clean dark lines between locks, the way an anime drawing does. Ours were thin leaves with grey undersides, or faceted diamonds: noise.
5. **Three sizes, all in the same direction.** A few big locks make the shape, with smaller ones between them. None go against the flow.

## The way, for AR64 (DESIGN)

- Built in `tools/blender/hair_ways.py`, `Solid`.
- The three takes are this way at three degrees:
  - **A, the mass:** the points part only at their ends.
  - **B, spiked:** the ends lifted clear, and the crown standing.
  - **C, sleek:** fewer, broader locks lying close.
- The first spike takes (21:35) are dropped. They kept points 2 to 4 of what was wrong.
