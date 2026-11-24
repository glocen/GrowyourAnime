# Faber's cloud session, 2026-11-20 (offline, no Studio)

The branch is `claude/faber-cloud-offline-tests-6kqqad`, cut from main at `d51d2ee`. The brief was everything in the builder's area that can be proven with Studio closed, so nothing players see was changed. AR49 wasn't touched: its work in progress is only on the PC.

## What changed

**Pure rules (section 10).** Each was taken out of a service, and the service now only wires it.
- **`Rules.Stages`** (5058a78, f511b0a, 939e049): Counts, Regrows, Shut, TryAt, KeeperFell, Holdings, Won, Lost, Published, Parse, Label and Way.
  - They come from StageService: its counting, its gate, its keeper hooks, its two cards, its attributes, its log name and its Travel pick.
  - StageController shares `Parse`.
- **`Rules.Travel.Joined`** (939e049): TravelService's inline check that a ticket came from one of our places.

**One behaviour change (section 9, f511b0a).** `Progress.KeeperWon` refuses with `Resting` while the keeper rests from this player's last win.
- No try begins in the rest (`KeeperService.Try`), so a win then can only be that same win again.
- Before, only KeeperService's in-memory flag stopped a second chest and emblem. A server's own change carries no op id, so the ledger couldn't stop it.
- A real win can't land inside the rest, so players see no difference.

**New cases.** Each one was mutation-checked: I broke the rule, saw the case fail, and restored it.

| Case | What breaking it showed |
|---|---|
| Stages (TR50): falls and regrowth, the gate, the cards and attributes | Counts' Normal and Hard rule, Shut's ground check, the gains' floor at 0, Parse's anchors |
| Stages (TR48): the keeper in a run, Normal and Hard | TryAt's ground check |
| Progress (section 9): a keeper's win repeated while it rests | the rest guard (7 failures) |
| Travel (TR45): the pick's checkpoint, the ticket's source, the round trip | Joined's place check |
| Base (section 9, 5aa02fc): the shard's whole way, 300 seeded steps of the nine base actions and SetLead, repeated or cut short, never makes or loses a shard or a fighter | Open's take from Ready, AddShard's spend, SetWorker's move, Uncover's one of a kind, SetLead's recall, the ledger's memory, Transaction's rollback (7 of 7) |
| Chests (section 9, d00eca5): gear's whole way, 400 seeded steps of Open, Reinforce, Socket, Unsocket, Equip with Move, SalvageItem and SetSalvage, never makes or loses a chest, an item, a Credit, a stone or an emblem | salvaging a worn item, auto-salvage's Credits, Open's chest removal, Reinforce's stones, Socket's swap back to the bag, Unsocket's clearing, Transfer's kept emblems, the ledger's memory, Transaction's rollback (9 of 9) |
| Regalia (section 9): 400 seeded equips with Move, repeated, fresh or cut short | Transfer's swap, its kept emblems, the ledger's memory, Transaction's rollback |
| Shop (section 9, 57787dc): 400 seeded buys over about forty stocks, pressed late, past a limit, too poor, repeated and cut short: each Credit spent once, no line past its limit, the piece the shelf's own | the limit, the spend, the Poor check, the count's reset at a new stock, the late press's refusal, an extra shard, an extra piece, the ledger's memory, Transaction's rollback (9 of 9) |
| Tower (section 9, d3f7e58): 500 seeded server calls through starts, floors won, ends and joins' recoveries, doubled, stale and cut short: each floor pays once, each run is granted once | a floor paying again, a stale run's floor, End leaving the run, End's Credits, stones and chests, a stale end, a start over a run, Transaction's rollback (9 of 9) |
| Breaker (section 9): an advance repeated at one moment pays its overflow once | the stamp, the carried rest |
| Collection (section 9): a star under one op id is bought once, and a cut one spends nothing | the copies' spend |
| Tower (section 9): an end cut short grants nothing, and the next join recovers it once | End's clearing, Transaction's rollback |

Breaking Open's chest removal also makes the older "1,000 opened in steps" case loop forever. That mutation ran on a scratch copy of `Cases/Chests.luau` holding only the gear fuzz, and every lune run was wrapped in `timeout`.

**Smaller changes.**
- `OpLedger`'s header no longer claims to catch a double tap (f601df5). A double tap is two requests with two ids: the kit Button's pending guard and the rule's own refusal stop it.
- **Docs:** a "Faber's cloud session" handoff under TR45, TR47, TR48 and TR50 in `docs/test-requests.md`.
- **`docs/engineering-plan.md`:** the stages contract, `Travel.Joined`, two Transactions bullets (the second tap, and the server's own changes), and the Transactions test row.
- `docs/team-notes.md` and the design docs weren't touched: Quaestor keeps them.

## Test outputs, at the branch's head

```
luau check: 0 new, 11 known, 0 gone since the freeze (5.0 s)
LOGIC OFFLINE PASSED: 30936 passed, 0 failed, 0 need Studio (3.55 s, Lune)
Built project to check.rbxl                      (rojo build default.project.json)
hooks selftest: 126 passed, 0 failed
```

Read at ca87da1, 2026-11-24. The first handoff's head read 28,980.

Main at `d51d2ee`, the same runner: 28,834 passed, 0 failed, so the branch adds 146 checks.

## What needs Studio (NOT VERIFIED)

- **Studio's `LogicTests`** after the pull. It's the same cases and the same code, so it should match the offline count plus Studio's own cases.
- **The Festival place's playtest:**
  - the self-test's run case "Stages (TR50)", and the cases tagged `Place` for the Keeper, Drops and Stages. The offline cases that share the "Stages (TR50):" prefix already pass;
  - the run's log line in a real run (`logRun` now names it through `Stages.Label`);
  - the keeper in a real run, Normal and Hard, with one chest per win.
- **TR49's Stage 1 playtest.**
- **TR45: a real trip** between the published places, which exercises `Travel.Joined` on a real `GetJoinData`.
- **Still waiting from the Now row:** TR10's marker in its world, TintMask on a phone, and TR44's phone take (that one waits for the director's go).
- **Noted, not fixed:** StageController's `look()` gate skips the server's ground check and its Ending state. It can't show while there's one ground. At ground 2 it should call `Rules.Stages.Shut`.

## The py shim

Not installed. Here the hooks run under `python3`, and the self-test passes 126/0.
- The guard reads the role from the session's title. This session's title starts with "Faber", so it counts as the builder and its push was allowed.
- Without that title the guard would refuse `git push`, as designed.
- No hook was changed, so the PC's `py` setup stands as it is.

## Merging the branch on the PC (the builder, at a piece boundary)

1. **Stop the playtests.** AR49's `build/scratch/faber/ar49-wip/` is gitignored, so the merge doesn't touch it.
   - The branch changes none of the files its patch names (the panel's Config, `Figure`, `UI.HomePanel`).
   - I couldn't run `git apply --check tracked.patch` here, because the patch isn't in this container.
2. **Sync main first:** `git pull --rebase` on main, as `/ga-start` does.
3. **Merge:** `git fetch origin claude/faber-cloud-offline-tests-6kqqad`, then `git merge --no-edit FETCH_HEAD`.
   - Only `docs/test-requests.md` and `docs/engineering-plan.md` can conflict, if main appended to the same TR entries.
   - My parts are whole sections, so keep both sides.
   - Quaestor's cloud branch merges the same way. It keeps the board and the design docs, which this branch didn't touch.
4. **Check:** run `py tools/checks/luau_check.py`, then `lune run tools/checks/logic_offline.luau src/server/Services/Core/LogicTestService/Cases`. Expect 0 new, and 28,980/0 plus whatever main gained.
5. **Reconnect:** restart Rojo with `tools/rojo-serve.ps1` on port 34876, since a pull crashes it. The director then reconnects each Studio.
   - Check Studio has the code: StageService's `Source` should contain `Stages.Published`.
6. **Studio checks:** run `LogicTests`, then the Festival place's playtest for the items above (`/ga-studio-test` first).
7. **Push main.** Delete the cloud branch only with the director's OK.

**For Faber's Now row,** on the board's next rewrite: TR50's run rules, TR48's keeper and TR45's trip checks are now pure and offline, and a keeper's win can't be granted twice, and seeded runs prove the shard's way, gear's way, the shop and the Tower never make, lose or double-spend a valuable. "Open, tests" adds the Festival run of these cases and the gate drift note.

## Game changes of 2026-11-24 (code; all NOT VERIFIED in Studio)

The director's words of 11-24: "i asked for the play button to open a panel of gamemode", then "browse the whole grow your anime repo and edit/add/remove/change whatever you find wrong". Each is one commit, by path, with the type check, the offline suite and the Rojo build green after it.

| Commit | What | Its proof here | Owed in Studio |
|---|---|---|---|
| c5aa6d6 | **Play opens a panel of game modes:** the Festival and the Tower, a card each. `Rules/Modes.luau`, `UI/ModeScreen.luau`, `Controllers/Main/ModeController.luau`. `Config.Hud.Modes.On = false` gives Play the Arc panel back | `Cases/Modes.luau` | `ModeCases` (3), the dock's case, the player-camera review, the feel line's review |
| a66cd2e | **The base view's Upgrade press:** the level's plate carries Upgrade with its price; a chip's tap opens its machine's panel (what it does, what the next level gives, its press). `Rules.BaseLevels.Ask` says what each spot buys. Before this no client sent `UpgradeBase` or `UpgradeMachine` | `Cases/BaseAsk.luau`: every press bought through `Rules.Base` to the cap | `BaseViewCases` (Main), the smallest phone's fit, the review. Grey: no art |
| d0cbe09 | **A refusal never shows its code:** `BaseController` warned nothing and toasted "Not now: <code>"; `StageScreen`'s begin said nothing on NoAnswer, NoData or NoStart | type check | a refused press in play |
| 40a48c8 | **A favourite sorts first,** as `Collection.SetMark`'s comment promised. `Collection.Roster`: the lead, the favourites, level, name, id | a case in `Cases/Collection.luau` | the Voidkin grid and the bay picker |
| f0743c5 | **The restock chip shows only where the Void Shop stands** | type check | the Festival place's HUD in a stock's last minute |
| 4ac79ee | **A bay's picker leads with the best worker** and shows the base's gain: "Lv 12 · 18 kW · +4 kW". `Rules.Power.Staff` | `Cases/Staff.luau`: each gain shown is the gain `SetWorker` gives | the row's fit on a phone |
| ca87da1 | **The run's card waits until the keeper's fade is back** (3.3 s on today's numbers; it was sent at 1.2 s and the black fade covered it at 2.4 s). `Rules.Stages.After` | a case in `Cases/Stages.luau` | the Festival's Stages (TR50) case, a real keeper's win |

Tier 1 notices for the Now board, all of them: small, reversible, no balance touched. The Play panel's shape and the Upgrade panel's look are blockouts for their feel lines' reviews.

**Looked at and left alone, on purpose:**
- **A fallen lead in the Festival** (Retry lit, "Your lead is down", no plot to stand again on): the card's presses follow a rule research hasn't written. Tier 2.
- **The weak strings** in `docs/research/cloud-2026-11-24/voice-and-naming.md`, section 3: the words are research's. "Inventory" and "the bag" both come from the director's own words, so neither was renamed.
- **`docs/roblox-rules.md`, line 29:** a study cites a 2026-05-26 forum clarification (every outcome must give some benefit). The fetch to verify it failed from here, so the file is untouched. Research reads it at the source.
- **`emitter.Rate` written each frame** (`FighterController/Rows.luau`): no measurement says it costs anything.
- **`tools/blender/r6anim.py:1004`** reads `src/shared/Config/Camera.luau`, which doesn't exist: Modulo's area.

## Research for the team (2026-11-24, docs only)

The director asked for research, a review of our work and notes for the team. Start at `docs/research/cloud-2026-11-24/README.md`: the steering brief, ten ranked proposals, and what waits on the director. Twelve studies sit beside it. None of it is accepted. For Quaestor: the 11-24 words "i asked for the play button to open a panel of gamemode" replace part 3 of the 11-19 23:19 row (`play-mode-panel.md`, with a build-ready entry). For the builder on main: `FighterController/Rows.luau:733` writes `emitter.Rate` every frame (`vfx-quality.md`). The branch's code is unchanged since the case commits above.
