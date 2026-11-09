# Test requests

The builder's and QA's queue, in order. A piece's record is its entry here: the feel line, what the block contains, what waits, the checks, the verdict. Nothing about a piece is written twice.

## TR1: Day one: the kit, the place, the boot (Faber)

Tooling, with nothing players see, so no feel line and no blockout. Step 0 of `docs/production-plan.md`. The folder was made on 2026-11-09 by research, at the director's ask, from the handbook's Rojo starter and NEXT Button's team files (rules, briefs, skills, agents, hooks, launcher). It holds no game code.

- **Bring in the kit,** one group at a time, by `handbook/tech/README.md`, "Setup steps": the runtime pieces, the self-test, the logic tests, the debug bridge with live numbers, and the type check (`tech/checks/` into `tools/checks/`, its known list frozen at what a clean start gives).
- **Trim the starter** to this game: one place role, and the `Hub` and `Match` folders renamed or dropped.
- **Three calls that are yours, each recorded in `docs/engineering-plan.md`:**
  - the save library: the director's data system, kept, adapted, or replaced with the reason (the directive, section 9);
  - Roblox's Server Authority mode, on or off (the plan's own section gives research's reading);
  - the first LYNX experiment: a headless runner for pure rules, tried on one small rule module.
- **The place:** the director creates the experience under the studio's group. Rojo serves on port 34876. Its ids go in `CLAUDE.md`, "Places".
- **Correct what was carried:** `/ga-start`, `/ga-finish` and `/ga-studio-test` name NEXT Button's kit. Make them say what exists here. In `.claude/hooks/open_cloud_guard.py`, the store's paths stay empty until this game's universe exists and the director says yes to store writes.
- **The hooks, first run in a second folder:** each session's start should name its role (`handbook/start/new-game.md`, "Not known yet"). Say in this entry whether it did.

**Pass:** Studio boots clean on both sides; the self-test runs with nothing failing; the type check prints `0 new`; each teammate's session is told its role at start.

**Waits:** saving's build (step 2), and everything of the game.

**Status:** open. Starts when the director calls the team here.

## TR2: The grey loop: the first 20 seconds in boxes (Faber, to research's feel line)

Step 1 of the plan. A blockout: grey boxes, stand-ins, no art, no sound, no saving. It exists to answer one question: does the loop want a second go?

**Feel line:** you hold the handle and someone grows in the machine under your own power, steps out, strikes a pose, and takes over the work: the base lights up without you and starts to pay.

**The block contains:**

- one base pad: two Void Breakers, a dynamo station, a Board, and cables between them that light with what flows;
- at spawn, a shard already in the first Breaker and a handle to hold. Holding it is the only way to make power until a fighter exists;
- about four seconds of growth while the handle is held: a grey body scaling up in the Breaker, the rarity's colour building on it;
- the reveal: the Breaker opens, the stand-in steps out and holds one pose, its name and rarity show, and the Index pays the first credits;
- the takeover: the stand-in walks to the dynamo and works it. MAKE, USE and the credits ticking from the spare show on screen;
- a stall on the Strip, eight seconds away at most, with two types of shard, a limit on each and a countdown (a fixed list behind it for now). Bought shards grow in the Breakers with no hand on the handle;
- one fight: the stand-in goes up the first floor of a Tower stub, the fight is settled at once by a pure rule into a list of events, then played back as moves and numbers, and it pays a shard;
- every number above live in the debug bridge, so it's tuned by playing.

**It tries four proposals** (`docs/design.md`; trying one in a blockout is tier 1): the first shard grown by hand, then the fighter takes over; power is the money, with the spare sold each second; a shard's type names its fighter; a fight as a list of events played back.

**The measures,** timed from the spawn, against `docs/north-star.md`, "The first 20 seconds": seconds to the first input, to the pose, to the first credits, to the second purchase, to the first Clash. Text the player must read before the first input: none.

**What waits:** saving and ids (step 2), any art or sound, screens beyond the three numbers and the stall's list, traits and mutations, the real rotation from the clock, batteries and the hours away, other players, the arena, Calamity.

**Verdict:** research's, in `/ga-review`'s form, here. The director's pick when present.

**Status:** open, after TR1.
