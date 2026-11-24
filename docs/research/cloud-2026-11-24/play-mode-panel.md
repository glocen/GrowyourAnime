# Play opens a mode panel: the register's correction and a build-ready entry

Faber, cloud, 2026-11-24. This is a proposal for Quaestor to record and for the builder on the director's PC to build. Nothing here is built. Anything players see stays NOT VERIFIED until it's seen in Studio.

## The director's words, and the register's reading

- **2026-11-19, 23:19** (`docs/decisions.md`, row 28): "i do not like the play button when we click on it it show a panels of gamemode for now it only show FOB then when we click on it the arc".
  - The sentence reads two ways: "I don't like that Play opens a panel with only FoB in it" or "I'd like Play to open a mode panel; for now it only shows FoB". Research took the first reading.
  - Part 3 of the row records it: Play opens the Arc panel straight away while the Festival is the only mode. TR50 built that, and it's what runs on main (`StageController.luau:414`, `HudController.OpenPlay = StageController.Pick`).
- **2026-11-24** (to Faber): "i asked for the play button to open a panel of gamemode yet it only open festival of battle".
  - This settles it. Play opens a **panel of game modes**, and part 3 of the 11-19 row was a misreading.
  - It also says why the first version disappointed: a mode panel holding one mode reads as a detour. The panel has to show more than one real mode.

**For Quaestor (the register):** record the 11-24 words with their scope. They cover what Play opens, nothing else. They replace part 3 of the 11-19 row; parts 1 and 2 (one mission per Arc, checkpoints) stand. This reverses a recorded reading, not a director's choice, so it needs no new yes. The Tower card below is a new way into a mode, so it's tier 2: research, plus the area touched (Faber's).

## Feel line

The player taps Play and the world dims behind a short row of large picture cards, one per mode, each with what it is and one gold button. The Festival's button says where they'll go ("Lantern Row · Normal"), so a return player is fighting in two taps. The Tower card shows their record and walks them to the ring. It feels like a choice between places, not a menu.

## What the block contains

1. **A mode panel** opened by the dock's Play tile, in the existing Glass and Theme kit (`src/client/UI/Kit`). It's a light panel, not a full-screen takeover (`reference-menu-video.md`, "What not to take").
2. **The Festival of Battles card**, first and largest:
   - its title, one line ("Fight through the grounds with your lead"), and the last ground and difficulty played;
   - the primary button **Continue** starts that ground on that difficulty through the existing `StageScreen`'s begin path, so it's 2 taps from the dock;
   - a quiet second action, **Choose Arc**, opens today's `StageScreen.Pick`, unchanged.
3. **The Tower card:**
   - its title, the player's best floor (`Progress.Tower` in the profile view), and one line;
   - the button **Go to the Tower** closes the panel and points `Guide.Point({ ring })` at the player's own `TowerRing` (`Markers.Find("TowerRing", { Plot = plot })`, as `TowerController` already does). The run still starts by stepping into the ring, so the server's rules are untouched.
   - `Config.Tower` on main has no gate, so the card is always open. If one is added, the card shows its lock and the real condition.
4. **No other cards.** A mode that isn't built gets no card, and there's no "coming soon": "never a placeholder" holds (`menu-layout-and-motion.md`, the teaser line).
5. **Gamepad and keyboard:** the cards in one focus row, A or Enter presses the focused primary, B or Esc closes.

**What waits:** mode art (each card shows a stand-in still from a fixed camera in its own place, a capture, not a drawing); a server-side "start the Tower from the menu" (only if the walk proves too slow when played); keepers and the arena as cards, once they exist as modes; any change to `StageScreen`.

## Wiring (on main)

- `HudController.OpenPlay` is the dock's hook (`HudController.luau:1358` declares it, `:1537` calls it). Today `StageController.Start` sets it to `StageController.Pick`.
- **The change:** a new `UI/ModeScreen.luau` (pure layout plus `Open(view, on)`, `Shown()`, `Close()` like `TowerScreen`), and a small `ModeController` that sets `HudController.OpenPlay` to open it. `StageController` keeps `Pick` and stops setting the hook. Its `on` handlers:
  - `Continue(ground, which)` calls the same begin `StageScreen` uses;
  - `Arc()` calls `StageController.Pick()`;
  - `Tower()` points the Guide.
- **The last ground and difficulty played:** read from the profile view if it holds them, else Lantern Row on Normal. If the view has neither, that's a one-field data contract change in `docs/engineering-plan.md`, and the builder decides it.
- The server's `StagePick` push stays as it is: it opens the Arc panel directly, as a keeper's prompt needs.

## Motion (seeds, tuned live)

These are from `menu-layout-and-motion.md`, "Our rules". The panel opens in 200 to 260 ms from a 0.96 scale, Quint Out, with the world dimming over 200 to 240 ms. The cards stagger 40 ms apart, rising 12 to 16 px. It closes in about 160 ms. A second open within a minute skips the stagger. A press answers in the same frame. Scale goes through a UIScale on a wrapper outside any layout.

## Acceptance

- **Self-test** (`SelfTestController`):
  - the dock's Play opens the mode panel with exactly two cards;
  - Continue reaches the same begin call as the Arc panel;
  - Choose Arc opens `StageScreen`;
  - Go to the Tower leaves the Guide pointing at the player's own ring;
  - Esc closes the panel, and the `StagePick` push still opens the Arc panel directly.
- **Player-camera review** on a phone in landscape: the cards read in under a second, and the gold is on the primary buttons only (`ui-colour-review.md`).
- **Research's artistic pass.**

The director's acceptance is reported separately.
