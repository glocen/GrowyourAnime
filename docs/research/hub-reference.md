# What makes a shipped Roblox hub read as high quality (study)

**The question:** asked to look at our base at the gate, the director called it "a prototype" (2026-11-26, by 21:04; `docs/decisions.md`). What do shipped, high-quality Roblox games do in their hub that ours doesn't? This study is for the base's redo.

**The evidence so far:** one game. Anime Crusaders X's lobby, from the director's own captures of 2026-11-24 (`build/reference/anime-crusaders-x/i01_full.png` and `u02_full.png`, 2560 × 1600). Ours is `build/captures/ar65/ar67_installed_day.png` (852 × 480, the same frame the director judged). One game isn't enough: see "Not answered yet".

## What was seen (OBSERVED, i01 and u02)

- **The frame is full to its edges.** There's no open sky, no horizon and no empty floor. It works in three depths:
  - at the sides of the foreground, planters and braziers;
  - in the middle, players, their units and a raised ring;
  - at the back, trees in four colours (orange, green, blue, red) and tall lit buildings closing the view.
- **The floor is designed.** It has steps, a raised ring, glowing inlaid tiles framed in trims, and a patterned spot where the player stands. No part of it is a plain slab.
- **The light comes from many places.** The ambient is dark, with many local lights in more than one hue: braziers throwing yellow bursts, glowing floor inlays, lit windows and auras, warm against cool. It's dark without reading as somber, because the dark is full of coloured light.
- **Destinations get small markers.** An icon and a word sit high over each one (Leaderboard, Guilds, Boss Rush, Raids, Shops), smaller than a player's name.
- **The frame is alive.** Other players, their units and their auras move in it.

## Ours beside it (OBSERVED, `ar67_installed_day.png`)

- About a third of the frame is open floor. Sky and horizon fill the top half, and the machines stand apart.
- One flat light gives soft, short shadows on a pale palette.
- Six large labels float over the machines, about the size of the HUD's text.
- The director has called the base empty before: "the base feel empty now" (11-16, `docs/research/examples.md`).

## Lessons for the base (DESIGN; each change takes the tier it touches)

1. **Fill the frame from the player's camera.** Use three depths, with the yard's own walls and tall pieces hiding the horizon, and no open foreground.
2. **Design the floor.** Use levels, inlays and trims that lead to the machines.
3. **Light from many places, in more than one hue.** Our base is in daylight, and the director has named "too purple, black, somber" six times. So the lesson is local light and colour variety, not darkness.
4. **Use small icon markers in place of big labels,** with the full name shown on approach.
5. **Make it alive:** the bays' Voidkin at work, the Generator's motes, and movement in the frame.

These lessons are about structure only. No layout, prop, shape or palette of theirs is taken.

## Not answered yet

- **A hub in daylight.** Anime Crusaders' lobby is at night, and ours is in day. The next evidence is two or three more shipped games' hubs at the player's camera on the PC, captured as Anime Crusaders' were. Candidates: Anime Vanguards' lobby, and one bright, daytime hub.

## Images looked at

- `build/reference/anime-crusaders-x/`: a contact sheet of all 48 `_full` captures, then `i01_full.png` and `u02_full.png` at 1280 wide (`build/scratch/quaestor/hubstudy/`).
- `build/captures/ar65/ar67_installed_day.png`.
