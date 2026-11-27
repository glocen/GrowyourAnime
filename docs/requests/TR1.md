# TR1. Day one: the repo, the place, the kit (Faber)

Tooling, with nothing players see, so no feel line and no blockout. Phase 0 of `docs/production-plan.md`.

- **Join the repo.** The folder has local history and `origin` (`github.com/glocen/GrowyourAnime`) has one first commit with a README. They've never met, and research's session can't join them. Join them without losing either (a merge that allows unrelated histories, keeping this folder's files), then push. From then on, pull and push as `AGENTS.md` says.
- **Update the handbook clone** in `handbook/`: it's behind the studio's.
- **Check the ids** the director gave on 2026-11-11: universe 9093907961, place 78052287756826, under group 35516567. Correct `CLAUDE.md`, "Places", if anything differs. Open the place in Studio with Rojo on port 34876.
- **Bring in the kit,** one group at a time, by `handbook/tech/README.md`, "Setup steps": the runtime pieces, the self-test, the logic tests, the debug bridge with live numbers, the type check.
- **Trim the starter** to this game: one place role; the `Hub` and `Match` folders renamed or dropped.
- **Three calls that are yours,** each recorded in `docs/engineering-plan.md`:
  - the save library: the director's data system from NEXT Button's `src/owner/`, kept, adapted or replaced, with the reason. Bringing it into this folder is reading outside the project, so it waits for the director's OK;
  - Roblox's Server Authority mode, on or off;
  - a headless runner for the pure rules, tried on one small rule module.
- **Read `docs/engineering-plan.md`** and correct it: it's yours from today.
- **The hooks' first run here:** say in this entry whether each session was told its role at start.

**Pass:** the repo is pushed and level; Studio boots clean on both sides; the self-test runs with nothing failing; the type check prints `0 new`; each teammate's session is told its role.

**Status:** done, 2026-11-12 (Faber). Implemented and tested; nothing players see, so no visual pass; not yet director-accepted.

- **The repo:** joined by a merge that allows unrelated histories (`57c8145`), this folder's tree unchanged, pushed, `main` tracking `origin/main`. The handbook clone pulled level with the studio's.
- **The ids:** the open place reads place 78052287756826, universe 9093907961, created by group 35516567. `CLAUDE.md` needed no change. Rojo serves on 34876.
- **The kit, in `src/`:** `Net`; `Log` (prefix `[GA]`), `Signal`, `Parts`, `Tune`, `Preset`, `TestInput` in `Shared.Util`; `Config.Presets` with `Baseline`; in `Services/Core` the debug bridge (`BootErrors` added), `TuneService` (live numbers, and a `Preset` command), `LogicTestService`, `SelfTestService`; in `Controllers/Core` `TuneController` and `SelfTestController`, cut to this game (no stamina, lock-on or entity state: the avatar never fights). Not brought in, until a piece uses them: `Raycast`, `Vector`, `UiLint`, the action stage, and the capture, animation, audio and effects tools.
- **The checks:** `tools/checks/luau_check.py` (luau-lsp, new solver) found 18 findings in the kit's own files and all were fixed in code, so `luau-known.txt` is empty. `tools/checks/logic_offline.luau` under Lune, now taking a folder of case lists.
- **The trim:** one role, `Main`; `Hub`, `Match` and the empty `Simulation` dropped. Pure rules live in `Shared.Rules`.
- **The three calls:** in `docs/engineering-plan.md`, "The builder's calls": ProfileStore kept under a save layer of our own (the director's word of 2026-11-12 on NEXT Button's data system is quoted there); Server Authority off, and the place switched to `AuthorityMode` Automatic; Lune for pure rules, tried on `Shared.Rules.OpLedger`.
- **The hooks:** the instruction lint and the tool guard installed on the director's yes (2026-11-12), exactly the handbook's example without the Studio lock. Hooks self-test 126 passed; the lint 0 findings; the guard refused a `git stash` live and let the builder's Studio calls through. **Each session was told its role at start:** Quaestor as Research, Faber as Builder, Modulo as Assets (`.claude/state/roles/`, 2026-11-11 23:17 UTC).
- **The director, 2026-11-12:** "player avatar will be R6 only do not worry". It covers the player's avatar. The self-test's `Avatar: R6` case holds it.
- **Tested, 2026-11-12, in the open place under Automatic:** boot 0 errors on both sides; the self-test 11 passed, 0 failed (1.7 s, 60 fps); `LogicTests` 29 passed; offline, the same 29 pass, and a planted bug (a repeat overwriting the first answer) fails 2; the type check `0 new`.
- **Learned:** a folder rename under a served Rojo crashed it (00:27), as `handbook/engineering/project-setup.md` warns. `AuthorityMode` reads and sets from MCP now. Without Server Authority the place has no input-action controls, and `TestInput.MoveBinding`'s two 5-second waits cost every self-test 10 s: it now looks once. These, and the 18 type fixes to the kit's files, are the handbook's to take (research).
- **Open:** the place's `AuthorityMode` change waits for a save of the place. `rbxassetid://203785492` fails to load at play start ("Asset type does not match requested type"). It's in no instance of the place, so the player's own avatar appearance is the likely source, unverified.

