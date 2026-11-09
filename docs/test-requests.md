# Test requests

The builder's and QA's queue, in order. A piece's record is its entry here: the feel line, what the block contains, what waits, the checks, the verdict. Nothing about a piece is written twice.

## TR1: Day one: the kit, the place, the boot (Faber)

Tooling, with nothing players see, so no feel line and no blockout. Step 0 of `docs/production-plan.md`. The folder was made on 2026-11-09 by research, at the director's ask, from the handbook's Rojo starter and NEXT Button's team files (rules, briefs, skills, agents, hooks, launcher). It holds no game code.

- **Bring in the kit,** one group at a time, by `handbook/tech/README.md`, "Setup steps": the runtime pieces, the self-test, the logic tests, the debug bridge with live numbers, and the type check (`tech/checks/` into `tools/checks/`, its known list frozen at what a clean start gives).
- **Trim the starter** to this game: one place role, and the `Hub` and `Match` folders renamed or dropped.
- **Three calls that are yours, each recorded in `docs/engineering-plan.md`:**
  - the save library: the director's data system, kept, adapted, or replaced with the reason (the directive, section 9). It isn't in this folder: its source is NEXT Button's `src/owner/`, and bringing it here waits for the director's OK;
  - Roblox's Server Authority mode, on or off (the plan's own section gives research's reading);
  - the first LYNX experiment: a headless runner for pure rules, tried on one small rule module.
- **The place:** the director creates the experience under the studio's group. Rojo serves on port 34876. Its ids go in `CLAUDE.md`, "Places".
- **Correct what was carried:** `/ga-start`, `/ga-finish` and `/ga-studio-test` name NEXT Button's kit. Make them say what exists here. In `.claude/hooks/open_cloud_guard.py`, the store's paths stay empty until this game's universe exists and the director says yes to store writes.
- **The hooks, first run in a second folder:** each session's start should name its role (`handbook/start/new-game.md`, "Not known yet"). Say in this entry whether it did.

**Pass:** Studio boots clean on both sides; the self-test runs with nothing failing; the type check prints `0 new`; each teammate's session is told its role at start.

**Waits:** saving's build (step 2), and everything of the game.

**Status:** open. Starts when the director calls the team here.

## TR2: The grey loop: the first three minutes in boxes (Faber, to research's feel line)

Step 1 of the plan. A blockout: grey boxes, stand-ins, no art, no sound, no saving. It exists to answer one question: do the first three minutes want a fourth? Rewritten once before its start, after the cold read (`docs/research/cold-read.md`).

**Feel line:** you hold the handle and someone grows in the machine under your own power, steps out, strikes a pose, and takes over the work: the base lights up without you and starts to pay.

**The block contains:**

- one base pad: two Void Breakers, three dynamo stations, a Board, and cables between them that light with what flows;
- at spawn, a shard already in each Breaker and a handle on the first. Holding it is the only way to make power until a fighter exists;
- **the handle:** on a phone it's one large hold button in the thumb's reach, with the camera on the Breaker, so the thumb never covers it. On a keyboard, one key. A hold or repeated taps both grow the body, and letting go early pauses the growth and never resets it;
- about four seconds of growth: a grey body scaling up in the Breaker, the rarity's colour building on it;
- the reveal: the Breaker opens, the stand-in steps out and holds one pose, its name and rarity show, and the Index pays the first credits;
- the takeover: the stand-in walks to a dynamo and works it. MAKE, USE and the credits ticking from the spare show on screen. The second Breaker then grows a different stand-in with no hand on it, glows when done, and waits to be opened;
- **the roll:** each break may come out mutated (one mutation: a tint and a multiplier), rolled by the server when the break finishes;
- a stall on the Strip, eight seconds away at most, with four types of shard at rising prices, always stocked, and a countdown (a fixed list behind it for now). A bought shard goes in the pocket, and a tap on an empty Breaker loads it, with a row to pick from when the pocket holds more than one type;
- three floors of a Tower stub, each one fight: settled at once by a pure rule into a list of events, then played back as moves and numbers. The fighter sent leaves its station for the fight. A first clear pays credits, and floor 1's pays a mystery shard whose pool and odds show on it;
- **one debug switch** between two economies: the spare power sells each second (proposal 1), and fighters pay credits directly with power only a cap (its simplest option). Research plays both;
- a machine can be paused, with its progress kept;
- every number above live in the debug bridge, so it's tuned by playing.

**Starting numbers** are yours to set from these targets, and all of them are tuned live: the first break 4 seconds by hand; the second about 10 seconds unaided; the first purchase affordable by second 30; a third fighter growing by second 120; the fourth shard type out of reach before minute 3. The director's sketch gives a first scale: a Breaker draws 10 kW.

**The clock under it:** progress is advanced by one pure function from one time to another, used every time the Grid changes, so the same code later covers time away (`docs/engineering-plan.md`, "The shape", line 4). Your call how.

**It tries six proposals** (`docs/design.md`; trying one in a blockout is tier 1): the first shard grown by hand, then the fighter takes over; power is the money, against its simplest option; a shard's type names its fighter; a roll on every break; a finished Breaker waits for its owner; a fight as a list of events played back.

**The measures,** timed from the spawn, against `docs/north-star.md`, "The first 20 seconds": seconds to the first input, to the pose, to the first credits, to the second reveal, to the first purchase, to the first Clash, and whether credits ever stop. Text the player must read before the first input: none.

**What waits:** saving and ids (step 2), any art or sound, screens beyond the three numbers and the stall's list, traits, the Void weather, the real rotation from the clock, batteries and the hours away, other players and their teams, the arena, Calamity.

**Verdict:** research's, in `/ga-review`'s form, here. The director's pick when present.

**Status:** open, after TR1.
