---
name: "ga-studio-test"
description: Test and inspect Grow your Anime in Roblox Studio through the Studio MCP. Playtests, self-test, debug commands, logic tests, world report, timed input tests and screen captures. Load before any playtest, capture or debug-bridge call.
---

# Testing in Studio (shared by the team)

## Before you trust a result

- Before any Run, the type check: `py tools/checks/luau_check.py` (about 3 seconds, Studio open or closed). `0 new` means go. A new finding is fixed first, never frozen away: `--freeze` only after fixing, so `tools/checks/luau-known.txt` shrinks. Exit code 2 means the check itself couldn't run.
- `list_roblox_studios` first: the `studio_id` changes when Studio restarts.
- Check Studio has your latest code (search a script's `Source` for your new line). A playtest runs the code it started with: restart it after edits.
- A network drop can end a Run, change the ids and cut Rojo from Studio while the server still answers. After one, search `Source` before trusting anything.
- A playtest locks the place's Edit DataModel, so MCP edits fail while it runs. Never playtest a place a teammate holds.
- One playtest at a time across places that share a save store. They load the same account's profile, which only one server may hold, so a second playtest kicks the first. Stop one before starting the other.
- If the director is playing during a test, their inputs show up in the logs. Ask them to step away for timed tests.
- The Studio window under test must be in front. One behind another window draws at 13 to 33 fps, and timing checks then fail with nothing wrong. The self-test's first line gives the client's frame rate and warns below 50. If the window can't come forward, report those timing cases NOT VERIFIED, never FAIL. Starting a Run can leave a terminal in front, so read the frame rate once the Run is up. A session can bring the window forward itself: user32 `SetForegroundWindow` after a tap of Alt.
- **A locked PC stops rendering.** On the Windows lock screen RenderStepped falls to 0 while Heartbeat, and so the self-test's fps line, still reads 59 to 60, and the viewport reads 1×1. Every effect, fade, guide and layout case then fails with nothing wrong. Before trusting a client failure, count RenderStepped over 1 s in the Client context. At 0, report those cases NOT VERIFIED, never FAIL, and never unlock the PC or work around it. Server-only checks still run.
- **After a template rebuild with new parts,** read every Weld's Part0 in Edit. A live Rojo sync has left a new part's Part0 nil while the file held it (2026-11-12). Set it in Studio to what the file holds and save, never patch it at spawn.
- Read logs and reports for what matters (counts, FAIL lines, errors). Don't pull whole logs into the conversation.
- Studio sessions save to the `"Test"` store and live servers to `"Live"` (`DataService`, since TR2), so a playtest never touches a player's save. `NL_Debug:Invoke("DataState")` says which store and whether Studio has API access; `("Data")` reads the save; `("DataWipe")` makes the player a new account; `("DataCredits", nil, n)` changes something to check a rejoin by.
- A client's action without a menu: `NL_Debug:Invoke("Act", nil, name, args, opId?)` runs it through the Act remote's own path, op id included (the same id twice tests a repeat). The base: `("Base")` reads it out; `("BaseSkip", nil, seconds, away?)` passes time without waiting (`away` = true counts it as a rejoin); `("BaseGive", nil, shardId, n)` puts shards in the bag.

## The tools

- **Regression self-test** (Client context, during a playtest): `NL_SelfTest:Invoke()`. Filter by a name to run only the touched cases. It builds its own pad and dummy, runs every check against Config and Definition numbers, cleans up and returns a PASS or FAIL report.
- **The whole suite outlasts an MCP call and loses its report.** Run it detached, writing into a `StringValue`, then read the value. Store only its FAIL, ERROR and summary lines: the whole report passes a StringValue's 200,000 characters, and the write fails.
- **Debug bridge** (Server context, Studio only): `NL_Debug:Invoke("Commands")`. `Commands` lists every command.
- **Live numbers:** `NL_Debug:Invoke("Tune", path, value)`, never a required Config, since a snippet's `require` is its own copy.
- **Logic tests:** `NL_Debug:Invoke("LogicTests")` check the rule math. **World report:** `NL_Debug:Invoke("WorldReport")` checks the place's tagged markers (empty means sound). Run both with the self-test after a change.
- **Pure rules with Studio closed:** `lune run tools/checks/logic_offline.luau src/server/Services/Core/LogicTestService/Cases` runs the same case files as `LogicTests`, in about a second. Exit 0 is a pass. A case that needs the engine reports `STUDIO`, never a pass.
- **Presets:** `NL_Debug:Invoke("Preset")` reads the one being played, `("Preset", name)` switches every side. The self-test and the logic tests run on `Baseline` and put the played one back.
- `t.Press` and `t.Hold` need the game's Scriptable bindings (`TestInput.ContextName`). The game has none yet, so a case that presses waits until a piece adds them.
- **Test input in a Run:** see `handbook/testing/studio-testing.md`.
- `TeleportService` doesn't work in Studio: teleports are tested in a published dev copy. Teleport error 773 means the target place isn't published.

## MCP limits

- `execute_luau` runs as a plugin with its own module instances, so it can't see live game state through `require`. Use the debug bridge from the Server context. Cold-require a module (`:Clone()`) after editing it.
- `Workspace.AuthorityMode` reads and sets from MCP in Edit (tested 2026-11-12). This game runs it Automatic (`docs/engineering-plan.md`, "The builder's calls"). A change in the open place lasts only once the place is saved.
- `HttpService` is disabled for MCP plugin code too.
- `user_mouse_input` and `user_keyboard_input` add about 0.3 s per action, too slow for combo timing. For exact timing, fire Scriptable test bindings from the Client context. Input-to-server delay varies between sessions, so timed tests measure it rather than assume it.
- To place a player for a test, set the root CFrame or use `character:PivotTo` from the Server context. Client placement doesn't hold under Server Authority.
- Activate Studio in Edit before a Run, never during one: with the cursor locked, activating it jolts the camera.
- Scripts open in Studio editor tabs keep their own document text. After writing `.Source`, sync open tabs with `ScriptEditorService:UpdateSourceAsync` (its callback returns one string), or a stale tab can overwrite the new code.

## Captures

- `screen_capture` is blank in edit mode and works in play mode, a moment late. It doesn't draw BillboardGuis, and its camera parameters don't move the play camera if the game drives it every frame.
- One capture at a time. Parallel calls share one camera: a frame can show another call's view, and the rest time out.
- Keep Studio's window visible. Minimized or covered, `screen_capture` comes back blank. Unfocused but visible, it still draws, at 15 to 16 fps.
- Each capture is an image in your context, costing ⌈width/28⌉ × ⌈height/28⌉ tokens (1920×1080 is 2,691). While iterating, capture small (about 960×540, 700 tokens). The review sizes, 1920×1080 and 1366×768, are for `/ga-finish`.
- Capture fast effects frozen or slowed instead of racing them: set a test time scale on the client's effect kit, play the effect, then set it and every emitter's `TimeScale` to 0.
- A far test pad can stream the Studio animation rig out on the client: clone the character for a posed preview. A client-only rig's Animator doesn't step, so preview poses by setting `Motor6D.Transform`.
