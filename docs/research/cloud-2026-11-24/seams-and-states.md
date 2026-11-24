# Seams and states: every passage between systems, and what the game does there

Research study, 2026-11-24. Scope: transitions, overlaps, interruptions and edge states. Siblings written today cover the rest (`systems-that-marry.md`, and the map, orchestration and detail-pass studies); this one doesn't repeat them. Code paths are in the main checkout. Labels: SOURCED, COMMUNITY, OBSERVED (path given), MEASURED, OPINION. Every number proposed here is a seed to tune by playing.

## Verdict (5 lines)

1. **The valuables are safe; the moments are not.** Getting, spending and opening are server-decided with op ids and fuzzed cases. What's missing is what the player sees and is told at each passage. (OBSERVED, below)
2. **The worst seam is a fall in the Festival.** The results card pops at the instant of the fall, lights "Retry", and Retry answers "Your lead is down", because a fallen lead can only stand again on a plot and the Festival has none. (OBSERVED, to confirm in play)
3. **Nothing that happens while you're elsewhere is ever said.** The away summary is computed and thrown away; the HUD's notice skips the first copy after any join or trip; a shard turning Ready during a run is silent. Pillar 3 ("a shard cracking while you fight") has no signal across places.
4. **The teleport is the least proven seam in the game.** A static grey card, a 40 s watchdog, no cancel, health carry lost on the way, and the real trip has never run (`docs/test-requests.md`, TR45: NOT VERIFIED).
5. **Thirteen of the twenty fixes are cheap** (about 25 builder-hours in all, most provable in logic cases). Seven need a design call first, two of them the director's.

## 1. The player's states and the changes between them

All OBSERVED. "s" values are config names with today's value. "Not measured" means no number exists anywhere in the repo.

| From → to | Trigger | What the game does and shows | How long | Code |
|---|---|---|---|---|
| Roblox loading → arriving at the base | Join | Black cover from the client's first frame; lifts when the HUD reports "Whole". Plot given, avatar set down, fade in. No word on the cover. | Cover up to `OPEN_MOST` 8 s, then `OPEN_BACK` 0.6; set-down fade `WorldConfig.Arrive` 0.4; a request waits up to `Config.Data.LoadWaitSeconds` 30 for the save | `src/client/Controllers/Main/FadeController.luau`, `src/server/Services/Main/WorldService.luau`, `src/server/Services/Core/DataService.luau` |
| Away → returning | Save ready | `advance(player, "BaseReturn", true)` moves the base's time forward. Its answer (Finished, Made, Credits, Trained, Levels) is discarded. Nothing is shown. | Instant; the battery counts at most `Battery.AwayHours` 2 | `src/server/Services/Main/BaseService.luau:88` |
| Base → a screen open | Tile or prompt | One screen at a time; opening one closes the one before. Full screens hide the HUD and world plates. | Screen motion times: not read | `src/client/UI/Kit/Screen.luau`, `src/client/UI/World.luau:436` |
| Shard in the Breaker → Ready → reveal | Insert; timer; Open | The server's Open commits first, then the client plays the reveal. Starter and Named shards open themselves on the plot. | Standard 30 s, Enriched 900, Prismatic 10800, Starter and Named 6 (`Config.Shards`); `Config.Reveal.Skip` 1.0, `CardHold` 0.3 | `src/client/Controllers/Main/BaseController.luau:322`, `:639` |
| Anywhere in Main → the base | Base tile | Refused in order: already here, boss's arena, event, fight, cooldown. Then charge, flash, FOV pull, settle. | `Charge` 0.6, `Hold` 0.4, `Flash` 0.15, `Settle` 0.3, `Cooldown` 20, fight tail `Fight` 4 | `src/server/Services/Main/HomeService.luau`, `src/shared/Rules/Home.luau`, `src/shared/Config/Home.luau` |
| Base → the Festival's door → menu | Walk through the door | Net "StagePick" opens the stage menu. | Walk time: not measured | `src/server/Services/Main/StageService.luau`, `src/client/Controllers/Main/StageController.luau` |
| Menu → travelling → in a run | Begin | Refusals (NoData, InTry, NoLead). "Leaving" raises the travel card (`IN` 0.3). Up to `Calls` 5 teleport calls, `Gap` 1 s apart. On arrival the card is taken over, the server waits for the lead to stand (up to `Hold` 20), begins the run at the save's checkpoint, fires "Arrived", card lifts (`OUT` 0.4). | Real trip: never measured (TR45) | `src/server/Services/Main/TravelService.luau`, `src/client/Controllers/Main/TravelController.luau`, `src/first/Arrival.client.luau`, `StageService.luau` ≈409–438 |
| Travelling → failed | `TeleportInitFailed` or the watchdog | Retries by `Rules.Travel.Next` (`Flooded` 15 s, `Failure` 1 s, `Most` 4). Then the card lifts and a toast says "The trip didn't go through. Try again." | Up to `Watchdog` 40 s | `TravelService.luau`, `src/shared/Rules/Travel.luau`, `src/shared/Config/Travel.luau` |
| In a run → between stretches | Last Shade of a stretch | "StageClear" saved (dare pay in the same step), the line's check plays, the next stretch begins. | `Config.Stages.Results.After` 1.2 | `StageService.luau:238–261` |
| Stretch → the keeper's try | Hold the Challenge prompt | Fade, set down in the ring, both frozen for the try. | `Combat.Keeper.Hold` 0.5; fade Out 0.25, Hold 0.2, Back 0.35 | `src/server/Services/Main/KeeperService.luau`, `src/shared/Config/Combat.luau` |
| Keeper's try → win | Keeper falls | Win saved first. Results card at 1.2 s. At `WinPause` 2.4 s a black fade sets the avatar down by the shortcut pad. | 1.2 s, then 2.4 s + about 0.8 s of fade | `KeeperService.luau:332`, `StageService.luau:261–283`, `Combat.luau:201` |
| Run → fallen | Lead's health reaches 0 | Lead "Down" for `Combat.Lead.Leave` 1.6 s. Results card sent at once, no delay. In a keeper's try, `LossPause` 1 s then a fade back before the gate. | 0 s to the card | `StageService.luau:289–294`, `KeeperService.luau:351`, `src/server/Services/Main/FightService.luau` ≈1281 |
| Results card → retry, Hard, or home | Press | Won: Retry, Home lit (Hard lit when it just opened). Lost: Retry lit, Home. Home asks for the base server the player came from. The HUD is hidden while the card is up. | Trip time: not measured | `src/client/UI/StageScreen.luau:713+`, `:954–984` |
| Festival → base by the shortcut pad | Touch the pad | The trip home starts on touch. No charge, no confirm. | — | `KeeperService.luau` ≈452 |
| In a run → no run, no card | Walk `Config.Stages.Off` 30 studs off the street, start another run, or leave | The run ends silently. The checkpoint is kept; a run is never saved. | Instant | `StageService.luau:22`, `src/shared/Config/Stages.luau:41` |
| Base → the Tower → results | Tower entry; a floor falls or the lead does | `Rise` 2.5, `Leap` 0.5, fast mode `Gap` 10 and `Rise` 0.8, `Rest` 4. Results are kept in the save until seen. | As named | `src/server/Services/Main/TowerService.luau`, `src/shared/Config/Tower.luau` |
| Any → away | Leave or drop | Session ended and released. Health carry forgotten. Stage run gone. A Tower run is ended and its results kept. | — | `DataService.luau`, `src/server/Services/Main/LeadService.luau:60`, `:236`, `TowerService.luau:618` |

## 2. The seams, walked

**Join (arriving).** OBSERVED: after Roblox's own loading screen the player gets our black cover for up to 8 s with no text (`FadeController.luau`). A slow save (ProfileStore waiting on another server's lock) shows nothing either; "loading your save" wording: not found. OPINION: black with no word reads as a hang on a phone. **For us:** one line under the cover after 2 s (fix C9).

**Returning after time away.** OBSERVED: the server knows exactly what finished (`BaseService.luau:88`), and tells nobody. `HudController.luau:930–931` returns when there is no earlier copy, so the first profile after a join never produces a notice. Searched "Welcome back", "While you", "AwaySummary": not found. `docs/research/design-holes.md` F4 already designs the return moment (about 3 h plus a card); it isn't built. **For us:** this is the cheapest "premium" in the list, since the data already exists (fix C4).

**Base → Festival (the trip out).** OBSERVED:
- The card is a grey plate with a title and a 2 px rule (`src/client/UI/TravelCard.luau`; its own note says the look waits for AR42). No progress, no tip, no cancel.
- `Active` is set nowhere in `TravelCard.luau`, and the fade's cover sets `Active = false` (`FadeController.luau:113`). So taps likely pass through to the HUD and the avatar can still walk under the card. Needs a Studio check.
- The watchdog is 40 s (`Config/Travel.luau`). `docs/north-star.md` says nothing in the first session waits more than about half a minute. The failure path can exceed the vision's own limit.
- The card (DisplayOrder 110) sits over the fade (100). On arrival the order is card → black → world: two lifts where one would do.
- State carry: the ticket carries the ground, difficulty, stage and where the player came from; the run begins at the save's checkpoint, never the ticket's word (`Rules/Travel.luau`, case `Cases/Travel.luau:102`). Good.
- Not carried: lead health and the fallen wait. `carried` is a table in server memory (`LeadService.luau:60`), and a lead with no entry spawns whole (`src/shared/Rules/Carry.luau:41`). A trip heals everything. Camera: starts fresh in the new place.
- The stage menu's Begin says nothing on NoAnswer, Busy, NoData or NoStart (`StageScreen.luau:113–124`): a dead press on a slow connection.
- First ever and hundredth are identical: no first-time branch found in `TravelController.luau`. `first-session-script.md` already counts three teleports in the first session and asks for a "first breach"; this study adds only that the code has no hook for it yet.

**Festival → base (coming home with loot).** OBSERVED: the save holds everything (each stretch's pay is saved as it's won). But the home HUD starts with no earlier copy, so shards, chests and Credits earned on the run are never acknowledged at the base. The chip then points at the Breaker if there are shards (`src/shared/Rules/Hud.luau:538+`), which is right, but nothing says "you brought these back". **For us:** a 3 s "From the run" strip on arrival (fix C5).

**Stretch to stretch.** OBSERVED: 1.2 s, saved first, the gate says "Clear Stretch N to go on" if the player runs ahead. A save that fails is logged and the run moves on (`StageService.luau`). OPINION: this seam is sound. Keep it.

**The keeper's win.** OBSERVED in code, not seen in play: the card rises at 1.2 s and hides the HUD while `WinPause` (2.4 s) exists "so the fall is seen" (`Combat.luau:201`). At 2.4 s the black fade, which sits over every screen, covers the card for about 0.8 s and moves the avatar. The best moment of a run is cut twice. Then the avatar is set down beside a pad that starts a trip on touch.

**The fall.** OBSERVED: the card is sent the instant the lead falls (`StageService.luau:294`), over the 1.6 s meant to show the fall. The lit press is Retry. `FightService.luau:1372` reads the player's "Plot" attribute to decide whether a lead can stand again, and the Festival sets none (`WorldService.luau:6`, plots are a Main-place thing). So a fallen lead never stands again in the Festival. With one usable Voidkin, Retry always answers "Your lead is down" and the only way on is Home. `Rules.Hud.AfterFall` (case `Cases/Home.luau:88`) would point the way, but the HUD is hidden under the card. With a second whole Voidkin, Send should work (`LeadService.luau:184`); not verified in the Festival.

**A reveal that finishes while elsewhere.** OBSERVED: `NextStep` returns nothing away from home except the keeper's line (`Rules/Hud.luau`). ShardHint is home-only by the director's word of 2026-11-15, which covers the hint, not a one-time "ready" notice. A 30 s Standard shard set before a run is Ready before the first stretch ends, silently.

**Same taps both ways?** MEASURED from the code paths: out is door (walk) → menu → Begin: 2 presses and a walk. Back is results → Home: 1 press, or 1 touch of the pad, or (in Main only) the Base tile. Not symmetrical, and that's fine; the hole is that the Base tile's behaviour in the Festival goes through a trip with no "this leaves the Festival" word (`HomeService.luau`).

## 3. Overlaps

| Overlap | What the code does today (OBSERVED) | Right? | The missing detail |
|---|---|---|---|
| Shard finishes during a fight or while away | Stamps advance on the server in both places (`BaseService.luau`; cases `Cases/Breaker.luau:137`, `:150`). No notice anywhere but home's chip. | Rule right, telling missing | One quiet "A shard is ready at home" after the fight's tail, once per shard |
| Battery full during a run | Overflow rule runs by stamps (`Cases/Base.luau:149`, `:169`). No signal off the plot. | Rule right | Say it once on return (in C4's summary), not during the run |
| Level-up during a reveal | `LevelNotice` is one plate over the HUD; the reveal is a full ceremony. No hold or queue found (`src/client/UI/Kit`). | Unknown in play | Notices wait while a ceremony is up, then land 0.4 s after it closes |
| Goal completes mid-fight | Reaches the client only through the profile: pips and the Home tile's rim (`src/server/Services/Main/GoalService.luau`). No toast. | Too quiet | One toast after the fight; never during a keeper's try |
| Chest drops with the bag full | Chests stack outside the cap; opening is refused `BagFull` before any roll, with the way out (`src/shared/Rules/Chests.luau`; cases `Cases/Chests.luau:328`, `:537`). | Right | Nothing warns before the cap; the count turns red only at 300 (`src/client/UI/VoidkinScreen/Bag.luau:1208`) |
| Shop stock turns with the screen open | The screen refills in place; a late buy is refused "Gone" (`Cases/Shop.luau:241`). A server hop never refills (`:203`). | Right | A one-beat "New stock" flash so the swap isn't mistaken for a glitch |
| Restock chip while in the Festival | Shown whenever under `ShopConfig.Warn` 60 s and the Shop isn't open; no place check (`src/client/Controllers/Main/ShopController.luau:198`). | Wrong | The chip advertises a shop a teleport away, 60 s of every 300 |
| Keeper's prompt while a screen is open | World plates hide under a screen (`World.luau:436`). Code that disables ProximityPrompts under a screen: not found (search only). | To verify in Studio | Prompts off while a screen is open |
| Two notices at once | Toasts stack 2, last 2.5 s, the newest pushes the oldest out; no rank (`src/client/UI/Kit/Toast.luau`). | Weak | A refusal can be pushed out by "+1 shard" twice |
| Lead falls during its signature | `fall` calls `endAction` first, then clears the target (`FightService.luau` ≈1281). | Right in code | Whether the effect's tail is cut cleanly: Studio only |
| Opening a screen during combat | Allowed; combat is automatic and goes on underneath. A results card closes whatever screen was open, and any screen opened closes the results card for good. | Half right | The card's Retry and Home are lost; the pay is already saved |

## 4. Interruptions and failure

| Moment | What happens (OBSERVED unless marked) | Case | Hole |
|---|---|---|---|
| Disconnect mid-reveal | The Voidkin is already saved; the ceremony is lost. No "unseen" flag in `src/shared/Data/Profile.luau`. | `Cases/Breaker.luau:386` | The game's main reward moment can be missed for good |
| Mid-purchase or mid-open | One step with an op id; a repeat returns the first answer (`Config.Data.OpsKept` 32). | `Cases/OpLedger.luau:20`, `Cases/Chests.luau:369`, `Cases/Shop.luau:278` | None found |
| Mid-run (stage) | Run gone, checkpoint kept; rejoin lands at the base. | `Cases/Stages.luau:209` | Nothing says so on return |
| Mid-teleport | Ticket is a request, checked on arrival; a stale one (over 600 s) is refused; no ticket and a fresh player begins Normal 1, others get the menu. | `Cases/Travel.luau:45`, `:81`, `:125`, `:136` | Real trip never run (TR45) |
| Mid-Tower floor | Run ended at leave, shutdown or next join; results open once. | `Cases/Tower.luau:257`, `:333`, `:428` | None found |
| Stage results card up | Rewards saved before the card; the card itself isn't kept. | — | Tower's card survives, the stage's doesn't |
| Phone app backgrounded | Handling of window focus: not found. Roblox decides when to drop the client. | — | A returning player gets Roblox's own reconnect prompt, then the join seam above |
| Slow connection | No optimistic UI; buttons show a waiting ring and refuse a second press (`src/client/UI/Kit/Button.luau`). One retry after 1 s with the same id (`src/client/Controllers/Core/ProfileController.luau`). | — | "NoAnswer" has words only in the Shop (`ShopScreen.luau:75`); `BaseController.luau:173` can show "Not now: <code>" |
| Server shutdown | `BindToClose` only in the Tower (`TowerService.luau:618`) and ProfileStore's own. `ServerRestartScheduled`: not found. | — | No word to the player; a Festival run just ends |
| Full main server | "no free plot" is a server warning only (`WorldService.luau`). | — | A player with no plot and no explanation; check the place's max players against the plot count |
| Save fails to load | Kick: "Your data couldn't load. Please rejoin." Elsewhere: "Your data was opened in another server. Please rejoin." (`DataService.luau`) | `Cases/Data.luau:229` | Fine. ProfileStore's critical state is logged, never shown |
| Second device | The older session is ended and kicked with the line above. | — | Fine |
| Respawn or reset | Avatar set down with a 0.4 s fade; the lead is brought again. In the Festival the respawn point is the Arrival spawn, likely past `Off`, so the run ends with no card (inferred from code). `ResetButtonCallback`, `Humanoid.Died` handling: not found. | — | A run lost to a reset says nothing |
| Falling off the map | Not found beyond Roblox's default (fall, die, respawn). | — | Same as respawn |
| Idle kick | `Idled` handling: not found. `docs/design.md` allows auto-farming while connected. | — | Parked players are dropped by Roblox with no warning from us |

## 5. Empty, full, first, last

OBSERVED present: empty bag ("Nothing in the bag yet", `Bag.luau:986–990`); Breaker with no shard ("No shard yet. They drop on Lantern Row.", `BreakerScreen.luau:930`); empty and locked chambers; Shop with none in stock; Tower "No chests this run"; Reinforce at its cap; Condenser "Tray full"; star cap 7 with spare copies turned to Credits (`Config.Voidkin.MaxStars`); level cap 125 (`Config.Growth.MaxLevel`).

Not found: what the lead's card says at level 125; a line when every goal of the day is claimed; a top floor for the Tower (`Config/Tower.luau`); a warning before the bag fills (`docs/design.md` says the bag "says so before it fills"); a first-time version of any transition (first trip, first fall, first return). OPINION: the first fall matters most. `Combat.Lead.Home.FirstFallen` 20 s shows someone already softened it at home; the Festival fall above undoes that.

## 6. Outside study (short)

Web search was unavailable this session (budget used up), so this part is thinner than asked. What was fetched:

- SOURCED: Roblox's teleport guide says the default is the standard loading screen, a client can replace it with `SetTeleportGui`, and "Any scripts within the ScreenGui do not run." A teleport "can still fail at the last moment without throwing an error", which fires `TeleportInitFailed`. Teleport data is "visible to the client and unencrypted". https://create.roblox.com/docs/projects/teleport — **For us:** the frozen part is only Roblox's handoff. Our card can move before the call (we own that screen) and after arrival (`Arrival.client.luau` runs in ReplicatedFirst). Display-only data (the run's haul) may ride the teleport data; anything owned may not.
- SOURCED: Roblox's update guide says a restart "Automatically teleports players to the updated version", players from one old server land together, and `ServerRestartScheduled` gives the restart time so a game can "show a countdown, prompt players to save progress, or teleport them at a convenient time". https://create.roblox.com/docs/projects/update-games — **For us:** no home-made soft shutdown is needed; a word and a clean run end are.
- COMMUNITY: the long-standing DevForum soft-shutdown resource (2017) was updated to say that since March 2024 it is "no longer necessary", for the reason above. https://devforum.roblox.com/t/47588
- SOURCED (secondary): God of War (2018) "is presented in a continuous shot, with no camera cuts or loading screens". https://en.wikipedia.org/wiki/God_of_War_(2018_video_game) — the usable rule: a load is hidden inside something the player is doing or watching, never shown as a wait. **For us:** the walk through the Festival's door is that moment; the card should rise during the last steps, not after a menu press.
- SOURCED (secondary): reviews of GTA V praised its "absence of load screens" and noted that switching characters "helped avoid long travel times". https://en.wikipedia.org/wiki/Grand_Theft_Auto_V — the rule: a transition that shows where you're going reads as travel, not loading.
- Not fetched, so OPINION only: Nintendo's habit of answering every input within a frame or two; mobile games' resume-where-you-left-off and welcome-back screens; the 20-minute idle disconnect (the `Idled` event exists on the Player reference page, the 20 minutes was not confirmed there). `docs/research/game-mode-places.md` and `design-holes.md` F4 already hold sourced notes on teleports and the return moment.

## Frank critique

- The engineering under the seams is better than the seams look. Every failure case that could lose a Voidkin or pay twice has a case. Almost none of the failure cases that confuse a player has a line of text.
- The game answers "what did I get?" only when the player is standing still at home with a previous profile copy in memory. Across every boundary that matters (join, trip, return) it goes silent. That's the opposite of the director's "synchronization ... 1 whole premium game".
- Two-place design made the teleport the spine of the loop before the teleport was ever run. Three unmeasured trips sit inside the first session (`first-session-script.md`). I'd measure that on a phone before any polish on either side of it.
- The results card was built as a screen. It should be a beat in the fight's ending. Its timing fights the keeper's own.

## 7. The seam list: the 20 most valuable fixes

"Offline" means provable in a logic case with Studio closed. Costs are builder-hours unless said.

### Cheap and certain (13)

| # | Seam | Today (OBSERVED) | Should happen | Cost, who | Proof |
|---|---|---|---|---|---|
| C1 | Results card vs the fall | Win: card at 1.2 s, black fade over it at 2.4 s. Loss: card at 0 s (`StageService.luau:261`, `:294`; `Combat.luau:201–202`) | Win: fall plays, fade and set-down, then the card (seed 3.4 s after the fall). Loss: card at `Leave` + 0.3 (seed 1.9 s). | 2–3 h, builder | Order offline (a pure "card at" rule); look in Studio |
| C2 | The lit press after a fall | Retry is lit and answers "Your lead is down" (`StageScreen.luau:954–984`, `:113–124`) | The card reads the lead: if none can be sent, Home is lit and Retry is dim with its reason. | 1–2 h, builder | Offline |
| C3 | Silent and raw refusals | Begin says nothing on NoAnswer, Busy, NoData; "Not now: <code>" elsewhere (`BaseController.luau:173`) | One shared table of words for every error code; no press ever ends without a line. | 2 h, builder; words by research | Offline: every code has words |
| C4 | The return after time away | Summary computed and dropped (`BaseService.luau:88`) | Away over 60 s (seed): one card, up to 3 lines, "2 shards ready · +1,240 Credits · 3 levels", closed by a tap. F4's design. | 3 h, builder; card art, asset maker | Content offline; look in Studio |
| C5 | Coming home with loot | First profile copy is never noticed (`HudController.luau:930–931`) | On arrival from a run, a 3 s strip: what the run brought. Display-only data. | 2 h, builder | Studio |
| C6 | Things that finish while you're busy | Shard Ready, goal done: silent off the plot (`Rules/Hud.luau:538+`, `GoalService.luau`) | One quiet toast each, held until the fight's tail ends (seed 4 s), never in a keeper's try. | 2 h, builder | Offline (hold rule) |
| C7 | Restock chip in the Festival | No place check (`ShopController.luau:198`) | Chip only in the place that has the Shop. | 15 min, builder | Studio |
| C8 | The travel card | Static, doesn't sink taps, avatar free under it (`TravelCard.luau`) | Sinks input, freezes the avatar, one line of text, moves before the call and after arrival; one lift, not two. | 2 h, builder; art waits for AR42, asset maker | Studio |
| C9 | The join cover | Black, no word, up to 8 s (`FadeController.luau`) | After 2 s (seed), one line under the cover; a second line if the save is slow. | 1 h, builder | Studio |
| C10 | Notices colliding | Two toasts, no rank, no hold for ceremonies (`Kit/Toast.luau`) | Three ranks (refusal, reward, info); notices wait while a reveal, card or fade is up, then land 0.4 s after. Shared with the orchestration study. | 3 h, builder | Offline (pure queue) |
| C11 | The bag before it fills | Red only at 300 (`Bag.luau:1208`) | Amber at 270, one toast at 285 per session (seeds). The design already asks for it. | 1 h, builder | Offline |
| C12 | A run that ends without a word | Off the street, respawn, another screen over the card (`StageService.luau:22`) | Every run end says "Run ended. Stretch N is kept." The last card can be reopened until the next run. | 2 h, builder | Offline (end reasons); Studio |
| C13 | The shortcut pad | Trip on touch (`KeeperService.luau` ≈452) | Stand-to-charge like the Base tile (seed 1.0 s, step off to cancel). | 1 h, builder | Studio |

### Needs a design decision (7)

| # | Seam | Today (OBSERVED) | The decision | Cost, who | Proof |
|---|---|---|---|---|---|
| D1 | A fallen lead in the Festival | It can never stand again there (`FightService.luau:1372`, no plot) | Either the Arrival pad counts as home (seed: 20 s first fall, 45 s after), or a fall always carries the player home. Changes "a fall sends it home" in `docs/design.md`: research's design, tier 2. | 3–4 h, builder | Offline |
| D2 | Health across places | Carry lives in server memory; a trip heals all (`LeadService.luau:60`) | Write "the trip heals" as the rule (free, honest), or stamp the carry in the save. Touches `docs/balance.md`: research, tier 2. | 0 h or 3 h, builder | Offline |
| D3 | The trip's time budget | Watchdog 40 s; real trip unmeasured (`Config/Travel.luau`, TR45) | Measure first, on the director's phone, privately. Then set the budget (seed: offer "Stay" at 15 s). Whether the first fight needs a trip at all is the director's call. | 1 h to measure; **director's yes** for any change to the places | Studio and a real device |
| D4 | First trip vs hundredth | One path for both (`TravelController.luau`) | First time: a short ceremony at the door. Later: the shortest path. Builds on `first-session-script.md`. Research's design. | 3 h, builder; art, asset maker | Studio |
| D5 | A reveal cut by a drop | Voidkin kept, ceremony lost (`BaseController.luau:639`, `Profile.luau`) | A "not yet seen" mark, replayed short at the next join, as the Tower does for results. A data-contract change: builder's call, research's design. | 3 h, builder | Offline |
| D6 | A restart during a run | No handling (`ServerRestartScheduled`: not found) | A countdown line; in the Festival, end the run at the stretch's end and go home together. | 3 h, builder | Studio only |
| D7 | Parked players | No `Idled` handling; design allows auto-farming while connected | Let Roblox's idle drop stand and let the away rule take over, with a "Still there?" line first; or keep players in. Economy: **director's yes**. | 1–2 h, builder | Studio |

## Top 5 to act on

1. **Fix the fall in the Festival (D1 + C2 + C1).** Research writes the rule this week; builder about 7 h. D1 is tier 2 (research and balance), no director's yes unless the fallen wait's numbers change the economy.
2. **Build the return moment (C4 + C5).** Builder 5 h, asset maker one card. No director's yes: F4 is already designed.
3. **Run and time the real trip on a phone before anything else touches it (D3), then make the card honest (C8).** 1 h with the director present, then builder 2 h. Any change to the two-place design needs the director's yes.
4. **Give every refusal words and every run end a line (C3 + C12).** Builder 4 h, research the words. No director's yes.
5. **One notice queue with ranks and a ceremony hold (C10 + C6).** Builder 5 h, all provable offline. No director's yes; agree the ranks with the orchestration study first.

Not fetched: web search (budget used up), so nothing on Nintendo's feedback practice, mobile reconnect patterns or the 20-minute idle rule is sourced here. Read from code and not seen in play: the card and fade timing at the keeper, the Festival fall, taps passing through the travel card, the respawn ending a run.
