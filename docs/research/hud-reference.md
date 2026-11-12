# The unit card and the damage numbers: a reference study

Research, 2026-11-12. For the HUD's lead and target cards and the damage numbers (`docs/ui.md`, "The HUD, in the world").

**The question:** how the reference shows a fighter's card and its numbers, so ours reads as clearly with our own look.

**The evidence:** three screenshots of Taichi Panda 3: Dragon Hunter's arena the director shared on 2026-11-12, in `build/reference/dragon-hunter/` (gitignored, internal): `2026-11-12_arena-normal-damage.png`, `2026-11-12_arena-damage-received.png`, `2026-11-12_arena-critical.png`. Phone captures from a video, 2000 px wide. The director's words: the card at the top left is the HUD wanted (the place may differ in ours), the bar under health may change its width and colour; the critical, the normal hit and the damage received as shown; healing as damage received but green; an element as a normal hit in the element's colour.

## OBSERVED

1. **The card:** the portrait in a frame standing on its corner, the level on a small badge below it, overlapping the frame. Beside it, two bars that start under the portrait's edge: health, long and thick, with current and maximum written inside it in full ("19717748/23186442"); under it a thinner, slightly shorter second bar with its own numbers. The bars end in a slanted cut. The target's card at the top centre is the same build, with the name above the bars.
2. **A normal hit** (`arena-normal-damage`): pale silver-white digits, thin and tall, very widely spaced, with commas, a dark outline and a soft shadow. Upright. Large: about a third of the character's height. It reads as a measured sum, calm.
3. **Damage received** (`arena-damage-received`): the same face and spacing in a muted red, larger still, over the fighter who took it. The red says "this is yours, lost".
4. **A critical** (`arena-critical`): a different treatment altogether: gold digits, heavy and bold, slanted forward, a thick dark outline, on an orange brushstroke that sweeps behind them. Larger than a normal hit and placed above the target's head, with a small word cue ("Dodge") nearby on its own red pointer.
5. **The numbers are huge** at that game's endgame (six and seven digits), and their spacing makes even a long number read at a glance.

## DESIGN (ours)

- **Our card** keeps the structure (portrait framed, level badge on the frame, health long with its numbers written inside, a thinner bar beneath) and our look: the kit's rarity frame (AR3) for the portrait, the kit's chamfered cut and conduit bars. The thinner bar is experience, in its own colour, width our choice [D].
- **Five number styles,** from three treatments:
  - **A hit dealt:** pale ivory, upright, widely spaced, outlined.
  - **An element's number:** the same as a hit dealt, in the element's colour [D], offset a beat in time and place so the two read as one blow.
  - **Damage received** by your lead: the same face, muted red, a size larger [D].
  - **Healing:** as damage received, green [D].
  - **A critical:** gold, heavy, slanted forward, on a swept stroke of our own shape behind it, larger, above the target [D].
  - A dodge, a block or an absorb [D]: a short word on a small pointer, grey. Absorb is a hit a shield took whole (Watt's Ground Wire, Halcyon's Thaw).
- **Spacing does the work:** wide letter spacing and thousands separators on every number, so a large number reads at a glance.

## Images looked at

The three above, whole. No crops made.
