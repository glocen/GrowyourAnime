# TR6. The UI effects kit (Faber)

Research's request, 2026-11-13, from the UI effects study the director asked for that day (`docs/research/vfx-reference.md`, "UI effects", its DESIGN part). Tier 2, research and Faber.

**Feel line:** every press answers the thumb at once with a squeeze and a tick, and every reward flies to its counter and lands with a pulse sized to what it's worth, so the screens feel expensive without ever getting loud.

**The block contains:**
- one kit (Pop, Press, Fly, Count, Shine, Rays, Burst) with its tokens in `UI/Theme.Motion`;
- the press on every button;
- Credits and Electricity flying in after a kill and on a collect;
- the level-up's rays.

It's judged in motion at phone size, beside the before.

**Waits:** the reveal's own layers (TR4, closed, stays), the Breaker screen's effects (with its piece), and sounds beyond the existing cues.

**Order in the queue:** after TR5. **Time, forecast:** about 2 hours.

**Status:** built, 2026-11-14 (Faber).
- **Implemented.**
  - The kit: `src/client/UI/Kit/` Fly, Count, Rays, Shine and Burst, beside AR8 C's Pop and Press, unchanged. Their pure rules are `Rules.Hud`'s ExpoOut, Flock and Arc. Their tokens are `Config.Hud.Motion`'s Haptic, Fly, Count, Rays, Shine and Burst, plus `Pop.Rungs.Fly`.
  - The press: a touch on a button that takes it plays Roblox's UIClick haptic (`Button.Haptic`).
  - A kill's Credits fly from where the Shade fell into the pill's coin. As the first one lands, the number counts up (Expo out), the pill pops at rung 5 and its "+N" rises. A win from nowhere on screen counts and pops at once, at its own rung. A spend shows at once.
  - The level-up: rays behind the word as it lands, one light band across its fill and its edge, and a gold burst off the badge.
- **Calls inside the piece (tier 1, Faber's).**
  - The tokens live in `Config.Hud.Motion`, not `UI/Theme.Motion`, so Tune changes them live.
  - The squeeze stays AR8 C's 0.92, not the study's 0.96: research named it AR8 C's bold thing, and the logic case holds it between 0.88 and 0.95.
  - The game has no Electricity collect, so Electricity flies on the battery's jump (a return from away), from the screen's middle.
  - The shine goes only on the level's word, the one rare reward the HUD shows now.
- **Tested.**
  - The type check: 0 new.
  - The logic: 4039 passing offline, with a new case for the count, the flock and the arc.
  - The self-test's new TR6 case and the level-up's four new checks wait on the Studio MCP, with TR5's.
- **Visually reviewed:** not yet. The captures at phone size, beside the before, go here once Studio is back.
- **Accepted:** no.

