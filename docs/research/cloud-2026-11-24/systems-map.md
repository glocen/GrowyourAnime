# The systems map: what flows where, by the rules as designed and as coded

A cloud research agent, 2026-11-24, read-only on MAIN. It answers the director's words of that day: "make every systems well implemented and orchestrated ... look at how gta 6 systems marry each other this is the synchronization and holes details filed im talking just to make it 1 whole premium game". This is the structural map of ours. The outside study and the method are in `systems-that-marry.md`; the base's choices in `base-and-neighbourhood.md`; the collection's worth in `collection-and-economy.md`. It builds on MAIN's `docs/research/design-holes.md` (H1 to H9) and `docs/balance.md`, "Electricity at launch (F3)", and doesn't repeat them.

**Labels:** OBSERVED (read in MAIN; every path below is relative to MAIN), MEASURED (computed here from the Config, inputs given), OPINION (my call). No web source is used: the search budget was spent before my method check, so the method is the one in `systems-that-marry.md`, section 3. Every proposal is a proposal. Every number is a seed to tune by playing.

## Verdict

1. **The fight is the only hub.** It feeds six systems. Only two feed it back: the roster and gear. The base side (Breaker, power, Condenser, Training, shop) reaches a fight through one door, "a Voidkin came out of a shard", and that door closes after about 11 shards (`collection-and-economy.md`).
2. **Electricity doesn't tie collecting to fighting in code.** Unplug every worker and a fight changes by nothing. MEASURED: the player loses 1 forge stone an hour, 90 seconds per shard they aren't there to watch, and some away training. Its one taut use is the hours away, and nothing shows it.
3. **One wrong seed bends four systems.** `KillsPerHour = 450` (`src/shared/Config/Growth.luau`) sets levels, the shard rate and Training. The run as staged gives 136 to 204 kills an hour. So Training pays 56 to 83% of an hour's play, not "a third", and a day away out-levels an hour played by 3 to 20 times.
4. **The biggest sink buys the least.** Six machines to level 30 cost about 792,000 Credits (44 to 101 hours of fighting at the 450-kills-an-hour seed: corrected 2026-11-24, `launch-design.md`) for kW that is already surplus. Everything else on sale at launch (both base levels, fourteen items to +10) costs about 37,000.
5. **About fifteen links are designed and not coded, or coded and read by nothing.** Most cost one to three hours each. Three need the director's yes outright, and three more have a part that does. The list is in section 7.

## 1. The systems

"Case" is the logic case file under `src/server/Services/Core/LogicTestService/Cases/`. I read that each exists; I didn't run them. Rules are in `src/shared/Rules/`, numbers in `src/shared/Config/`, services in `src/server/Services/Main/`.

| # | System | Its one job | Home | State | Case |
|---|---|---|---|---|---|
| 1 | Shards and the Breaker | turn a shard into a Voidkin or a copy | `Base.luau`, `Breaker.luau`, `Odds.luau`; `BaseService` | built | Base, Breaker, Odds, Reveal |
| 2 | The roster | hold the Voidkin, stars, who leads | `Collection.luau`; `VoidkinService` | built | Collection, Mark |
| 3 | Growth | levels from experience | `Growth.luau` | built | none by name (used in Drops, Stats, Training) |
| 4 | The fight | resolve a lead against Shades | `Fight.luau`, `Hit.luau`, `Passive.luau`, `Stats.luau`; `FightService`, `LeadService` | built | Fight, Combat, Hit, Kit, Passive, Stats, States |
| 5 | Grounds and stretches | the run: four stages, elites, a keeper | `Stages.luau`, `Progress.luau`, `Cooldown.luau`; `StageService`, `PackService`, `KeeperService` | built, one ground | Stages, Progress, Cooldown, Shades |
| 6 | Drops | pay a fall | `Drops.luau`; `DropService` | built | Drops, Loot |
| 7 | Chests and gear | roll items, wear fourteen | `Chests.luau`, `Regalia.luau`, `Bag.luau`; `RegaliaService` | built | Chests, Gear, Regalia, Bag |
| 8 | Reinforce | raise an item with Credits and stones | `Reinforce.luau`, `Forge.luau` | built to +30, reachable to about +10 | Reinforce, Forge |
| 9 | War Emblems | socket flat stats | `Emblems.luau` | built, no way out of the bag | none by name |
| 10 | Power | bays to kW, battery, overflow | `Power.luau`, `BaseLevels.luau`, `BaseFit.luau` | built | BaseLevels, BaseFit, Breaker (none named Power) |
| 11 | The Condenser | make forge stones from power | `Condenser.luau` | built | Condenser |
| 12 | Training | level one Voidkin from power | `Training.luau`; `LeadService` | built | Training |
| 13 | The Void Shop | sell shards and a featured piece | `Shop.luau`; `ShopService` | built | Shop, Strip |
| 14 | The Tower | climb floors alone | `Tower.luau`; `TowerService`, `TowerBoardService` | built | Tower |
| 15 | Goals | dares, today's three, Next | `Goals.luau`, `GoalFacts.luau`; `GoalService` | built (TR54, three must-fixes open) | Goals |
| 16 | Home, travel, the heal | move between the two places, heal a fallen lead | `Home.luau`, `Travel.luau`, `Carry.luau` | built | Home, Travel (none named Carry) |
| 17 | Designed only | jewels, evolution, the Research Lab, Enriched and Prismatic shards, voltage, luck, presets 2 to 5, catch-up, the Clash, the Calamity, the Rift | `docs/design.md`; `docs/engineering-plan.md`, "Who owns what" | not built | none |

## 2. The resource ledger

OBSERVED, from the rules that write each field of `src/shared/Data/Profile.luau`.

| Resource | Sources | Sinks | Flag |
|---|---|---|---|
| **Credits** | a fall, 10 × G(level) × share (`Drops.luau:76`, `:172`); overflow at 0.5 a kWh (`Breaker.luau:218-234`); a copy past seven stars (`Collection.luau:34-40`); salvage (`Chests.luau:381`, `:427`); Tower floors (`Tower.luau:304`) | base level (`Base.luau:293-296`); machine levels (`:332-335`); Reinforce (`Reinforce.luau:76`); the shop (`Shop.luau:220`) | the hub. Its largest sink buys slack (section 3) |
| **Experience** | a fall, lead only (`Drops.luau:174`); Training (`Training.luau:67`, `Breaker.luau:92-99`) | levels (`Growth.luau:56-76`) | workers and the Tower earn none; no catch-up |
| **Standard shard** | 4% a Shade, 14.4% an elite, 36% a keeper (`Config/Drops.luau`); the shop, 2 per 5 minutes; a goal, 3 a day (`Goals.luau:158-171`); the first kill's named one (`Drops.luau:181-184`) | the Breaker (`Base.luau:104-119`) | **reward leading nowhere** after the roster is whole: a copy, then 10 Credits |
| **Copies and stars** | a repeat reveal (`Collection.luau:44-75`) | stars: 1, 2, 4 ... 64 copies, each +1.43% of own base (`Config/Voidkin.luau`) | 127 copies a Voidkin for about +10% |
| **Chests, then items** | 5% a Shade, every elite, the keeper's win, Tower floors (`Config/Chests.luau`, `Progress.luau:70-78`, `Tower.luau:238-256`); the shop's featured piece | wear; salvage for Credits | fine. Bag cap 300 |
| **Forge stones, Low** | 22% a fall on Normal, 28% on Hard (`Drops.luau:190-196`); the Condenser, 1 an hour; a dare (`Goals.luau:173-177`); Tower floors 1 to 38 | Reinforce +1 to +10 (`Reinforce.luau:77`); the convert, 5 for 1 Mid (`Base.luau:385-389`) | fine |
| **Forge stones, Mid** | the convert, at most 2 an hour; Tower floor 39 and up (foe level 20; `Tower.luau:52-54`, `Drops.luau:79-84`) | Reinforce +11 to +20 | **wall**: about 1,424 needed for fourteen items |
| **Forge stones, High** | Tower floor 79 and up only | Reinforce +21 to +30 | **wall** |
| **War Emblems** | 30% an elite, 75% a keeper's win, the first sure (`Config/Drops.luau`) | at most 56 sockets | **source with no sink**: no merge, sale or salvage found |
| **Jewels** | none found | none found (`Regalia.luau:95-98` only moves them between items) | **orphan**. `Stats.luau:16` says "when they're built" |
| **Electricity** | workers, aptitude × 6 kW × (1 + 2% a level) × the bay's level (`Power.luau:41-60`) | Breaker 15 kW a chamber, Training 10, Condenser 10 (`Power.luau:87-97`); battery; overflow | **surplus**; one wanted sink, see section 4 |
| **Research Points** | none | none | **orphan**, known and kept unseen |
| **Luck** | none: `Luck = 0` (`Base.luau:92`) | the shard's roll | **sink with no source** |
| **The index** (`data.Index`) | every reveal (`Collection.luau:47-51`) | no reader found, client or server | **orphan** |
| **Marks** | `Locked` (`Collection.luau:137-148`); a stage's best time (`Progress.Stages.Best`) | nothing spends a Voidkin, so the lock guards nothing; no reward reads a time | orphans |

**Two resources doing one job:** Reinforce and War Emblems both add flat gear stats, and jewels would be a third. OPINION: at one ground that's one job told three ways. Keep the two that exist and don't add the third before a second ground.

**A typical hour, MEASURED.** Inputs: a Normal run of Lantern Row is 30 quota Shades, 3 elites and the keeper, 34 kills (`Config/Stages.luau:43`, `Config/World.luau:99-133`); 4 to 6 runs an hour, from the design's 10 to 15 minutes (`docs/design.md:235`), not from a logged time; shares 1, 3.6 and 9 (`Config/Drops.luau`).

| Per hour, Normal | In | Against |
|---|---|---|
| Credits | 3,100 to 4,600 (773 a run); Hard about 1,720 a run | base level 2 costs 840, level 3 costs 18,000; fourteen items to +10 about 18,000; a shop shard 299; a featured piece 2,216 to 9,972 |
| Experience | 3,100 to 4,600 | Training alone: 2,579 an hour |
| Kills | 136 to 204 | the seed everything is fitted to: 450 |
| Shards | 8 to 12 dropped (the Config's comment says 18); up to 24 bought for 7,176 Credits | the roster is whole after about 11 |
| Chests | 22 to 33 | `docs/balance.md` says about 43 |
| Low stones | 45 to 65, plus 1 from the Condenser | 34 for one item to +10; 472 for fourteen |
| Emblems | 7 to 10 | 56 sockets at most, then every one is a spare |
| Electricity | 30 to 54 kWh made | at most about 24.5 kWh wanted; the rest pays 15 Credits |

## 3. The interaction matrix

OBSERVED. Each cell is what the row gives the column. "–" is nothing. BR Breaker, RO roster, FI fight and grounds, GE gear, FO Reinforce and emblems, PW power, CO Condenser, TR Training, SH shop, TW Tower, GO goals.

| gives → | BR | RO | FI | GE | FO | PW | CO | TR | SH | TW | GO |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **BR** | · | a Voidkin or a copy | – | – | – | – | – | – | – | – | "break three" |
| **RO** | – | · | the lead | the class's weapon pair | – | workers' kW | – | who trains | – | the lead; floors 1 to 5 wear the five | "new lead", "level up" |
| **FI** | shards | lead's experience | · | chests | stones, emblems | – | – | a fallen lead to heal | Credits | – | keeper, dares, Next |
| **GE** | – | – | stats | · | items to raise | – | – | – | – | stats | – |
| **FO** | – | – | via gear | +1/30 a level | · | – | – | – | – | via gear | "forge once" |
| **PW** | break speed | – | – | – | – | · | runs it | runs it | – | – | "bays an hour" |
| **CO** | – | – | – | – | 1 Low an hour | – | · | – | – | – | "collect the tray" |
| **TR** | – | experience, one Voidkin | – | – | – | – | – | · | – | – | "train an hour" |
| **SH** | 2 shards a stock | – | – | 1 featured piece | – | – | – | – | · | – | – |
| **TW** | – | – | – | chests | stones | – | – | – | Credits | · | floors, best |
| **GO** | 3 shards a day | – | a dare in the run | – | 1 stone a dare | – | – | – | – | – | · |

**How it reads.**

- **The hub is the fight.** Its row has six gifts. Its column has two: the roster and gear. That's healthy for an action RPG, and it means the base is a spectator unless it gives the fight something.
- **The base's column of gifts to the fight is empty.** BR, PW, CO, TR and SH together reach FI only through RO and FO, and each of those links is weak today: copies are worth 1.43%, the Condenser is about 2% of stones, Training runs only after a fall or while away (`Training.luau:84-97`).
- **Islands.** The Tower's weekly board (`TowerBoardService`, `Config/Tower.luau`, Week and Board) pays nothing I could find. Training has one giver and one taker. The Power screen's split has one right setting, Auto (`docs/balance.md:199-209`).
- **Pairs that should talk and don't.** (a) A bay's work and that worker's growth: `docs/design.md:55` says a level comes "from fighting, working or training"; code gives a worker nothing. (b) The Tower and levels: no experience from a floor. That's by design (`docs/balance.md`), so say it on the Tower's card. (c) Base level and the fight: level 3 opens a bay and a ceiling, nothing a keeper feels. (d) Gear and goals: no goal names an item except "forge once".
- **Conflicting pulls, real or a tax?**
  - *Credits.* Not a choice at launch. MEASURED order of worth: base level 2 (a gate, 840), Reinforce to +10 (about 1,283 an item for +33% of its stats), a featured piece, base level 3, and machines last. A shop shard at 299 returns 10 Credits once the roster is full. One right answer makes it a queue.
  - *The five Voidkin.* The lead can't work (`Base.luau`, "Leading"). With five owned and four bays, every other one works. No choice, and it wouldn't matter: kW is surplus.
  - *Time.* A run pays Credits, experience, shards and stones. The Tower pays 34% of the Credits and no experience (`Config/Tower.luau`). It's a real choice only for chests. OPINION: fine for a side mode, once its card says so.
  - *Low stones.* Reinforce now, or five for one Mid. The only real small choice in the economy.

## 4. The loops, as coded

```
CORE   shard -> Breaker -> Voidkin or copy -> lead fights a run -> Credits, experience, shards, chests, stones, emblems
       -> shards back to the Breaker
BASE   workers -> kW -> Breaker speed, Condenser, Training -> surplus -> battery -> overflow -> Credits
       -> machine levels -> more kW
BUILD  chests -> items -> Reinforce (Credits + stones) and emblems -> stats -> Hard and the Tower -> chests
```

- **Core closes, then leaks.** After the fifth Voidkin the loop's prize is a copy. Past seven stars a Common pays 10 Credits (`Config/Voidkin.luau`, SellCredits). It stalls at the Next list's last line, "Drum Court's gate stays shut, for now" (`src/shared/Definitions/Goals.luau`).
- **Base closes on itself.** Credits buy machine levels, which make more of a surplus, which pays 15 Credits an hour. No arrow leaves for the fight.
- **Build closes, then walls.** Reinforce stops near +10 for want of Mid stones (section 2). Hard Lantern Row still drops Low: the grade follows the ground, not the difficulty (`Drops.luau:79-84`).

**Electricity, end to end, against "Electricity is what ties collecting to fighting" (`docs/north-star.md`, pillar 3).**

1. A worker makes kW. Watt 18, Rook, Pip and Lyric 12, Kirra 6, at level 1. MEASURED from `Config/Base.luau` and the aptitudes in `Definitions/Voidkin.luau`.
2. The Breaker takes 15 kW a busy chamber. A Standard shard breaks in 30 seconds, or 120 with no power at all (`Config/Base.luau`, MinSpeed 0.25; `Power.luau:98-117`). A run lasts 10 minutes or more in another place, so the player never waits for either.
3. The Condenser takes 10 kW for 1 stone an hour. Fighting makes 45 to 65.
4. Training takes 10 kW. While the player is in the game it runs only for a lead that fell and healed, and never while they stand on their plot (`Training.luau:84-97`).
5. The rest fills the battery, then pays 0.5 Credits a kWh.
6. **The one place it binds: away.** Bays make power for 2 hours (`Config/Base.luau:29-35`, AwayHours), then the battery carries Training and the Condenser, then both drop to a quarter speed. So the charge a player leaves with is hours of full-speed training. MEASURED: at base level 1, up to 8 hours at full speed; at level 3 with a full 400 kWh battery, about 22.
7. **The unplug test, MEASURED:** with no workers at all, a fight is identical. The lead still trains away at a quarter speed, about 645 experience an hour.

OPINION: the pillar is true on the screen (the bays, the hum) and false in the rules. The link that exists is "power is tomorrow's levels", and no screen says it. The return card (TR53) is where it should be said.

## 5. Clocks

| Clock | Value | Config |
|---|---|---|
| Standard shard; named and starter | 30 s; 6 s | `Config/Shards.luau`, Grades |
| Pack back; elite back (the whole server); keeper rest (per player, per ground) | 15 s; 120 s; 300 s | `Config/World.luau:127-132` |
| Shop stock; its warning; a featured piece | 300 s; 60 s; 1 stock in 6 | `Config/Shop.luau` |
| Home: charge, cooldown, "in a fight" | 0.6 s; 20 s; 4 s | `Config/Home.luau` |
| Lead's heal at home: whole, fallen, first fall | 30 s; 90 s; 20 s | `Config/Combat.luau:67` |
| Travel: watchdog, arrival hold | 40 s; 20 s | `Config/Travel.luau` |
| Tower: rest, rise, fast rise; the week | 4 s; 2.5 s; 0.8 s; 7 days | `Config/Tower.luau` |
| Goals: reset, bank; "bays" and "train" goals | 00:00 UTC, 3 days; 3,600 s each | `Config/Goals.luau`, `Definitions/Goals.luau` |
| Away power; battery | 2 h; 60, 150, 400 kWh | `Config/Base.luau:29-52` |
| Condenser: a stone, the tray, a convert | 1 h; 12 stones; 1,800 s | `Config/Condenser.luau` |
| Training's credit; the base's clock | 30 s; 60 s at most | `Config/Growth.luau`, `Config/Base.luau` |
| Day and night | 28 minutes a turn | `Config/Lighting.luau:28` |
| A run | 10 to 15 minutes (design, not measured) | `docs/design.md:235` |

**Do they fit a 5 to 15 minute phone session?** OPINION, from the table:

- **One run is the whole session.** There's no 3-minute unit except a single stretch from its checkpoint (`Stages.luau:100-134`). That's worth a line on the Arc panel: "one stretch, about 3 minutes".
- **The shop's clock can't be answered from a run.** The shop is in the main place, the run in the Festival place (`Config/Game.luau`). Two or three stocks pass per run. A featured piece shows about twice an hour for 5 minutes each; a player who is mostly in runs will see few of them.
- **Two daily goals ask for an hour.** "Bays an hour" needs 3,600 seconds with every bay staffed; "train an hour" moves only after a fall or while away. `docs/design.md:316` promises goals "done in ordinary play, about five minutes past it". These two are done by being absent.
- **Things that finish unseen:** the featured piece; the tray at 12 stones (it stops); the away power at 2 hours; the battery's top.
- **Waits that stack:** a fall costs the 90-second heal, then the trip back, then the stretch again. A keeper's rest is per ground, not per difficulty (`Progress.luau:57`, `:67`), so a Normal win can refuse a Hard keeper for 5 minutes. On Normal the elite is everyone's and returns 120 s after anyone fells it (`Stages.luau:141-142`), so a stretch can wait up to 2 minutes for a foe another player took. I read both in the rules; neither was played.
- **A loophole to know:** once stretches 1 to 3 are cleared, a run can start at stretch 4 (`Stages.luau:111-128`). The keeper's 300 s is then the only brake on its sure chest and 75% emblem.

## 6. Design against code

OBSERVED. "Design" is `docs/design.md` unless said.

| # | The design says | The code does |
|---|---|---|
| 1 | l.5: "Nothing here is built" | sixteen systems are built |
| 2 | l.55, l.61: a level comes from fighting, working or training; each role earns its own experience | a worker earns nothing (`Breaker.luau:92-99`; `Growth.AddXp` has three callers) |
| 3 | l.61, and `docs/balance.md:93-95`: a lead far below the account's best levels faster | no catch-up in any rule, config or service |
| 4 | l.158: Training earns "a third of what fighting earns in Lantern Row" | 0.33 × 450 kills an hour (`Training.luau:44-46`): 2,579 an hour against 3,100 to 4,600 played |
| 5 | l.157, l.193: the Condenser makes jewels "from launch" | no jewel source or sink; the Jewels page says "coming" (`src/client/UI/EquipmentScreen/Jewels.luau`, header) |
| 6 | l.227: auto-salvage gives "forge stones and Credits" | Credits only (`Chests.luau:381`, `:427`; `Config/Chests.luau:106`) |
| 7 | l.181: presets, "up to five" | one, and no rule adds one (`Profile.luau:237`) |
| 8 | l.119, l.124: three shard grades, voltage, luck "from every source" | one grade (`Definitions/Shards.luau`); voltage never offered on a 30 s shard; luck always 0 |
| 9 | l.59: one evolution at launch, Rook's | no code |
| 10 | l.333-336: stones "from the shop"; Credits "to the Condenser" | the shop sells shards and gear only; the Condenser costs Credits only to level |
| 11 | "The Tower": no weekly board named | a week, weekly foes and a board exist (`Config/Tower.luau`; `TowerBoardService`); no entry in `docs/decisions.md` found |
| 12 | Drum Court's gate stays shut | a keeper's win opens Drum Court's record in the save (`Progress.luau:80-85`) |
| 13 | not said | a worker made lead leaves its bay empty, and the old lead goes home idle (`Collection.luau:113-133`) |
| 14 | not said | a salvaged item's emblems and Reinforce level go with it (`Chests.luau:417-429`); a worn item is refused, a socketed one isn't |

## 7. The holes, ranked

OPINION on rank and fix; each rests on the OBSERVED and MEASURED lines above. Cost is the builder's unless said. "Yes" means the director's.

| # | What's missing | Why it matters to one whole game | The cheapest honest fix, as a rule | Files | Cost | Whose call |
|---|---|---|---|---|---|---|
| 1 | Power's surplus buys nothing wanted, and a bay's work grows nobody | pillar 3 is false in the rules; the base is a screen saver | "Overflow pays the workers in experience, split evenly, before any Credits." Seed: 20 experience a kWh. It builds design l.55 and makes each kW and each machine level worth a bench level | `Breaker.luau:218-234`, `Config/Base.luau`, a case | 3 h, research's simulation 1 h | **yes** (economy; overflow to Credits is the director's design) |
| 2 | One pace seed is wrong: 450 kills an hour against 136 to 204 staged | Training out-earns play; levels run 1.5 to 2.3 times slower than `PaceHours`; shards 8 to 12, not 18 | "The pace is read from the stages: a run's kills over a run's seconds." One seed, `RunSeconds`, set from a timed run by the director or QA | `Config/Growth.luau`, `Growth.luau:31-39`, `Training.luau:44-46`, `Config/Drops.luau` | 2 h, research 1 h | tier 2; tell the director, since "fixed rate, no cap" is theirs and stays |
| 3 | A shard is worth nothing after shard 11 | the core loop's prize dies in the first hour | see `collection-and-economy.md`, proposals. Cheapest stopgap: "a copy also pays its Voidkin the experience of ten kills at its level" | `Collection.luau:44-75` | 1 h | **yes** (economy) |
| 4 | 792,000 Credits of machine levels for slack | the largest sink teaches that the base doesn't matter | "At launch a machine's ceiling is 6, then 15 when Drum Court opens." 27,000 for all six instead of 792,000 | `Config/Base.luau:44-52`, Ceiling | 15 min, research's refit (F3) | **yes** (economy) |
| 5 | Catch-up, designed and not built | a counter system asks for a second lead; today it costs the full price | "A lead 3 or more levels under the account's best earns double." Seed | `Drops.luau:174`, `Growth.luau`, a case | 2 h | tier 2 (already designed) |
| 6 | A lead swap leaks a bay | the one real roster act silently breaks the base | "The old lead takes the new lead's bay, in the same step." | `Collection.luau:113-133`, a case | 1 h | tier 1 |
| 7 | Mid and High stones can't be had | Reinforce shows +30 and stops near +10 with no word why | "Reinforce's cap is 10 a ground opened, and the forge says so." Or Hard drops the next grade | `Reinforce.luau:38-47`, `Config/Reinforce.luau` | 1 h | tier 2 for the honest cap; **yes** for Hard's grade |
| 8 | Emblems have no way out, and salvage eats the socketed ones | a drop that turns into clutter by hour 8 | "Salvage returns an item's emblems to the bag. Three emblems of a kind merge into one of the next rarity." | `Chests.luau:417-429`, `Emblems.luau` | 3 h | tier 1 for the return; tier 2 for the merge |
| 9 | Two daily goals are done by absence | goals should point at acts, in this session | Replace "bays an hour" with "staff every bay" and "train an hour" with "collect what training banked" | `Definitions/Goals.luau`, `GoalFacts.luau` | 1 h | tier 2, research's rows |
| 10 | Away training's worth is unseen | electricity's one taut use has no face | The return card says "Trained 5 h on the battery; 3 h more at a quarter: the battery ran dry." | TR53's entry, `Breaker.luau:267-289` | 1.5 h on top of TR53 | tier 2 |
| 11 | The Tower's week and board are in no design, and pay nothing | a weekly reason to return with no prize and no record | Write it into `docs/design.md`, "The Tower". A prize is a separate ask | `docs/design.md` | research 30 min | tier 2 for the doc; **yes** for any prize |
| 12 | Jewels: a page, a bag key, no rule | a "coming" page in a premium menu reads as unfinished | "A page with no rule behind it isn't shown." Hide part A until part B is decided | `src/client/UI/EquipmentScreen/Jewels.luau` | 30 min | tier 1 to hide; **yes** to build |
| 13 | The shop's clock can't be answered from a run | a timer in one place, the player in another | "A featured piece stays until the player has opened the shop once." | `Shop.luau`, `Config/Shop.luau` | 2 h | tier 2 |
| 14 | A shared elite and a per-ground keeper rest can stall a run | a wait with no cause the player can see | Check both in play first. Then: "a stretch's elite is back at once for a run that needs it"; "the rest is per difficulty" | `Stages.luau`, `Progress.luau:57-67`, `StageService` | 30 min to check, 2 h | tier 1 |
| 15 | Fields nothing reads, and stale design lines | the map and the save drift apart, and the next teammate builds on a wrong line | One pass: the index, the lock, luck, best times, Drum Court's early record, each wired, hidden or noted as reserved; section 6's rows fixed in `docs/design.md` | `docs/design.md`, `docs/engineering-plan.md` | research 1.5 h, builder 1 h | tier 1 |

## A frank critique

- **We built the nouns and not the verbs between them.** Sixteen systems have rules and cases. The rows of the matrix that should carry the game's promise (base to fight) are dashes.
- **The economy is a six-ground economy on a one-ground game.** F3 said it of electricity (`docs/balance.md:199-209`). It's also true of Reinforce's three grades, the machines' thirty levels and the seven stars.
- **The simulation is fitted to a seed nobody timed.** 450 kills an hour appears in levels, shards, chests and Training. A stopwatch on one run fixes four systems at once.
- **The design doc lags the code.** Fourteen rows in section 6. `docs/design.md` is the home every teammate reads first.
- **What's sound:** one-step rules with a ledger, goals noted inside the rules, the fight as a clear hub, and a base clock that already knows about time away. The links are cheap because the rules are clean.

## Top 5 to act on

| # | Action | Who | Cost | Director's yes? |
|---|---|---|---|---|
| 1 | Time one Normal run in private, then set the pace seed from it (hole 2) | the director or QA times it; research refits; Faber 2 h | 3 h in all | no: tier 2, told on the board |
| 2 | Overflow pays the workers in experience (hole 1), simulated first | research 1 h, Faber 3 h | 4 h | **yes** |
| 3 | The lead swap in one step, and catch-up (holes 5 and 6) | Faber | 3 h, two cases | no: tier 1 and tier 2 |
| 4 | Hold the machines' ceiling at 6 and say Reinforce's honest cap (holes 4 and 7) | research's numbers, Faber 1 h | 2 h | **yes** for the ceiling |
| 5 | One truth pass: `docs/design.md` against section 6, hide the Jewels page, note the orphan fields (holes 12 and 15) | research 1.5 h, Faber 1.5 h | 3 h | no, except building jewels |

**Not fetched, not verified.** No web page was fetched (the search budget was spent). Run length is the design's 10 to 15 minutes, not a measurement, and every per-hour line rests on it. I didn't run a logic case or the game. The lines to check in play: the quarter-speed floor while away with an empty battery, the keeper's rest across difficulties, the shared elite's stall, and that salvage takes a socketed item whole.
