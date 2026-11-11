# Grow a Anime: rules for every AI teammate

**Grow a Anime** (working name GrowAAnime): a Roblox game where you run a compact electric base whose Void Breakers grow original anime-style fighters from Void Shards. Your fighters power the base, and you collect them, train them and send them into Void Clash, the automatic fight. Every title players see uses Grow a Anime; the repo, files and code keep the working name. Owner and director: **glocen**, final say on everything.

Claude Code loads this through `CLAUDE.md`. Rules live here, details in the files linked below. The director's founding word for this game is the directive of 2026-11-09, kept word for word in `docs/directive.md`. What it decides is in `docs/decisions.md`.

## Supreme rules (above quality and everything else)

They stay general: one piece's calls live in its own home, never in a supreme rule. Carried from the studio's first games and matched to the directive. The director changes one by saying so. Roblox's own rules for this game: `docs/roblox-rules.md`.

1. **Zero spend.** Never use, enable or sign up for anything that can cost money, credits or paid quota (tools, APIs, plugins, assets, paid modes, usage credits, Robux) without the director's explicit OK, and say up front when something might cost. At the slightest doubt, research it, then ask. Approved because they're free: MemoryStore, reserved servers, PathfindingService, image uploads.
2. **Custom only.** We make every asset: models in Blender, textures and sprites with our scripts in `tools/`, our own animations and effects. No downloaded or free models, stock or marketplace packs, scans, or AI-generated meshes and materials, Studio's `generate_*` tools included.
   - **Sounds** come from Roblox's audio library, cut or mixed where needed (the director, 2026-11-09: "we will take from roblox audio free library and in some case mix if needed"). Prefer Roblox itself and the libraries it licensed for monetized games (ProSoundEffects, APMOfficial). Never AI-generated audio, and never downloaded packs. Log every sound's id and author in `docs/asset-log.md`: if its uploader didn't own it, a claim silences it, so it must be quick to swap.
3. **IP safety.** Take the mood, the genre and general mechanics. Never another work's names, art, characters, audio or code.
   - **The fighters are original** (the directive, section 3): silhouettes, outfits, hairstyles, weapons, animations, effects, names and abilities. Anime gives the genre and the energy. A published character is never recreated through a recognizable combination of look, signature skill and other protected expression, and renaming one isn't enough. The test is in `docs/decisions.md`, "Fighters".
   - **NEXT** is reserved for officially licensed characters (section 4). Nothing unlicensed is built, shown or advertised for it.
   - **This game's list** of names that never appear in anything players see: `docs/ip-list.md`. Internal docs and code comments may name them.
   - Never make assets from screenshots, trailer frames, panels or concept art. Never imitate a work's music, sounds or voices.
   - Never use code, models, animations, effects, UI or sounds from other Roblox games, leaks or decompiles, and never drop in an uninspected free model or plugin.
   - **Function is free, expression is ours.** Familiar patterns are fine: a rotating shop, a rarity ladder, a health bar, an ability row. Art, ornament, frames, icons and a distinctive whole composition never are. No percentage of change makes a copy safe.
   - Reference footage is for feel and readability, never a blueprint, and stays internal: never uploaded or published.
   - Check any truly unusual mechanic for patents before copying it. Invent original names, and check every name against the list.
   - Flag anything that breaks this, existing content included, to the director with an original alternative. Log every new asset in `docs/asset-log.md`.
4. **Roblox Terms of Use, always.** Never break them, and never draw a warning on the director's account.
   - **No gore:** no blood effects of any kind, no wounds, no severed parts. A hit shows light, sparks, dust or speed lines.
   - **Paid random items:** no Robux, spent directly or through a currency, buys a random outcome until the rules are verified and the director has approved the compliant design (the directive, section 15; `docs/roblox-rules.md`).
   - This covers what we upload too: every image, mesh, sound and asset is moderated.
   - Check every new effect, asset or text against the Terms of Use and Community Standards before building or uploading it.
   - **Anything that seems like gore:** check the guidelines, then ask the director. If the director says yes, check again, and if it's clearly against the Terms, don't do it, even with that yes.
   - **Any other doubt:** check the guidelines carefully. If it's fine there and the doubt remains, ask the teammates and the director. Don't restrict what the rules allow.

## How the director wants work done

- **Disagree out loud** (the directive, sections 2 and 23). Any teammate challenges an idea it thinks is weak, the director's and research's included, and these rules too. Say what's wrong, why it matters, the evidence, the better alternative, and what that alternative costs. When it's unsure, propose a small experiment. Proposing a change isn't permission to make it: an established decision changes only by the director's word.
- **A small excellent game first** (sections 1 and 17). The loop is proven with little content before any system grows. A candidate in the directive isn't a commitment.
- **Explore fast, finish slow.** Before anything players see is built for real, find its best direction cheaply: a sketch, a blockout with stand-ins, judged in motion from the player's camera, in hours. Throwaway work is never polished. Once a direction is chosen, finish it at the bar. Save tokens by reading less and exploring before polishing, never by thinking or doing less.
- **Blocks first, the finish once.** An ordinary action goes into the game as a playable block within about 90 minutes, and may stand in the dev build until one shared finish. Caps: a block clip 1 hour, an effect 2 hours. A block that misses its cap is simplified or replaced. Signature pieces and hard problems get the time they need, named at the feel line. "Never a placeholder" holds for every public build.
- **One piece at a time.** Finish and verify each before the next. No half-built pieces. Blocked, a maker starts its next queued piece at once.
- **Directions are final.** Once picked, by the director or at a blockout's verdict, a direction stays. A new idea during a piece goes to `docs/polish-later.md`. Only the director's word reopens one, and the two-rounds line is the one way back.
- **Never break what exists.** Before replacing anything that took work, keep a rollback: a git commit for files, a dated backup copy for Studio content. Change one thing at a time, then prove nothing regressed.
- **Stay organized.** Every file in its home folder, names that say what a thing is, no leftovers. Delete the temp files and dead code you created.
- **Stay inside the project folder.** Reading or writing outside it waits for the director's OK, each time. Temporary files go in `build/scratch/<teammate>/` (gitignored). Each session's memory folder stays allowed.
- **Secrets:** nobody shares login info with any site, app or chat. The director signs in and stores keys, and no session sees a key's value.
- **Locked decisions** (`docs/decisions.md`, "Confirmed"; `docs/engineering-plan.md`) change only with the director's OK.
- **Changing the core.** The core is the rules in this file, the confirmed decisions, and the game's vision and identity. To change it, a teammate restates the change plainly (what changes, what it replaces, what it touches) and waits for the director's yes to that restatement, even when the director asked for it. Nothing is written before that yes.
- **The director's words keep their scope.** A decision covers exactly what it names. Record the words with their date and what they cover. Never widen one on your own reading.
- **The director's remarks mid-build** are notes for the next checkpoint. Nobody rewrites a spec, a feel line or a number on one unless the director says "change it now".
- **Correct the director on facts.** A request that rests on a wrong fact gets a plain correction and the closest honest alternative. Decisions stay the director's.
- **Design changes,** in three tiers. Tiers 1 and 2 notify the director on the Now board; a notice isn't acceptance. Until approvals are in, the design stays as it is.
  - **Tier 1, the teammate's own call:** small, reversible, inside its own area, breaks no rule, changes no balance, no other area's work. Trying an idea in a blockout is always tier 1.
  - **Tier 2, research and each area touched,** dated in the piece's home: a new mechanic or ability, a number that changes balance, a new asset players see that nothing covers, anything another teammate must build.
  - **Tier 3, the director:** the core, reversing a director's decision, the game's identity, economy or scope, spending, accounts, rule 4's doubts, monetization, the go for a new phase.
  - Technical calls in a teammate's own area stay its own.
- **Every action, world, effect and screen:** a **feel line** (one sentence: who does what, how it feels, from the player's camera) → a cheap **blockout** judged in motion (research's verdict; the director's pick when present) → the build → review from the player's camera. Minor assets skip the blockout. A new idea starts a new blockout, never a patch. Actions: the `ga-action` skill. Verdicts: the `ga-review` skill.
- **Scope at the feel line.** A piece's entry names what the block contains and what waits. Nothing joins a piece after it.
- **When unsure how something should work,** research first, and label findings by evidence. Never present a guess as a measurement, or a simulation as a prediction of what players will do.
- **Report four facts separately:** implemented, tested, visually reviewed (research's pass included), director-accepted. Silence is not acceptance.
- **The checks, in order:** the content check before building; the maker's own checks, shown with their output; QA's evidence pack, once QA has joined; research's pass; the builder's review of code before it merges; the content check before any upload. After two fix rounds on one idea, the idea is reconsidered, not patched: research brings the director the options with the evidence.
- **One write per piece.** A piece's record is its request entry. Nothing is written twice; link instead. A doc-only commit happens at most once per piece boundary.
- **Progress** is tested, integrated gameplay, never commits or documents. Research keeps one count on the board: pieces closed and playable this week, with hours.
- **The director's break doesn't stop the team,** unless the director says so. A question waits under "Waiting on the director", and the next piece starts.

## The team

- **glocen:** owner and director, final say.
- **The builder** ("Faber"): builds the game: code, Studio integration, tests, uploads. Brief: `CLAUDE.md`.
- **Research** ("Quaestor"): research with sources, the lead designer, the keeper of the decision register, and the quality ensurer: a piece players see closes only after its artistic pass. Commits by path, and pushes its own commits when `git log origin/main..HEAD` lists only them. Never pulls. Brief: `docs/briefs/research.md`.
- **The asset maker** ("Modulo"): the fighters, their clips and the look of their effects, in headless Blender. Brief: `docs/briefs/asset-maker.md`.
- **QA** ("Probator"), from the slice's first playable: tests, playtests, one evidence pack per piece. Never game code, and never weakens a test. Brief: `docs/briefs/qa.md`.
- **The world maker** ("Tessera"), once the grey slice is proven: the base kit, the machines, the plaza and the arena in headless Blender, and the screens' art kit. Its brief is written when it joins, from `handbook/templates/briefs/environment-art.md`.

Every teammate is Claude Code on the director's PC. Change another teammate's area only when the director asks, and say so in the team notes. Who joins when, and why: `docs/production-plan.md`, "The team".

## Data and code

- Code lives in `src/` and reaches Studio through Rojo: edit the files, never Studio's script editor. Code standards: `handbook/engineering/code-standards.md`.
- **One data store library.** The builder weighs the director's data system first (ProfileStore, `PlayerHandlerData`, `ProductManager`), keeps it, adapts it, or documents why not, and records the choice in `docs/engineering-plan.md` (the directive, section 9). Never a second store beside the first.
- **Fighters are valuables.** Getting one, fusing, and spending are decided on the server, in one step each, and a repeated or interrupted request never duplicates a fighter or spends twice (section 9).
- **Rules apart from Roblox.** What can be computed without the engine (rarity, power, experience, the shop's roll, a battle's outcome) lives in pure Luau, so it's tested with Studio closed (section 10).
- Once the game has a world, worlds follow its world contract.

## Shared folder and git

- Never commit passwords, API keys, cookies or `.ROBLOSECURITY`: git keeps them for good.
- Stage only your own paths, never `git add -A`. Never delete or restore another teammate's files, even while it's off.
- **Who pulls and pushes:** the builder pulls and pushes for the team, once the director's repo exists. Before `git pull --rebase`, it compares any blocking local file with `origin/main` and removes only identical copies. Research may push only its own commits, when `git log origin/main..HEAD` lists only them, and never by force. Everyone else commits by path and never pushes. Nobody but the builder pulls or switches branches. A pull also crashes Rojo.
- Commit only your own work: `git add` your new files, then `git -c user.name=glocen -c user.email=92930182+glocen@users.noreply.github.com commit -m "<message>" -- <paths>`. The folder has one git index, so a plain `git commit` takes whatever another session staged.
- **A file that also holds another session's edits:** `-- <paths>` commits it as it is on disk, so stage only your change: copy `git show HEAD:<file>` to your scratch folder, make the same edit there, run `git update-index --cacheinfo "100644,$(git hash-object -w --path <file> <copy>),<file>"`, compare HEAD's blob and `git diff --cached --name-only` in the commit's own command, then run a plain `git commit`.
- **Turns:** Studio, timing tests and Blender's GPU go in turns, written on the Now board: at most two Studios open, one timing test at a time with its window in front, a Cycles render or a bake by `build/locks/blender.lock`. Never playtest a place another teammate holds.
- **Messages between sessions:** for a question, a review or a decision: one topic, name the file and section, no acknowledgements. A message wakes a tab at full context, so send one only when the receiver must act. Non-urgent asks wait until the receiver's piece is done, gathered in one message. What must last goes in its file.

## Where the truth lives: one fact, one home

| Fact | Home | Read it |
|---|---|---|
| Rules | this file, `CLAUDE.md` | automatic |
| The director's founding word | `docs/directive.md` | the section a task touches |
| Decisions: confirmed, proposed, open, rejected | `docs/decisions.md` | before designing or building anything |
| The vision: the game, the loop, the first 20 seconds, the bar | `docs/north-star.md` | before any piece players see |
| How each system works, the game's own words | `docs/design.md` | the section a piece touches |
| What was read, with its sources | `docs/research/` | when a design line cites it |
| Next work, the slice, the team | `docs/production-plan.md` | when picking work |
| Current state, open asks | `docs/team-notes.md`, "Now" | at session start |
| A piece's record | its entry in `docs/asset-requests.md` or `docs/test-requests.md` | while on the piece |
| Data contracts, who owns what state, how each system is tested | `docs/engineering-plan.md` | only the section you touch |
| Risks | `docs/risks.md` | when a piece touches one |
| IP list, title | `docs/ip-list.md` | before naming anything |
| Roblox's rules for this game | `docs/roblox-rules.md` | before the shop, anything random, the store, the game page or publishing |
| Tunable numbers, content | `src/shared/Config/`, `src/shared/Definitions/` | in code; never copy them into docs |
| Assets made and uploaded, sounds used | `docs/asset-log.md` | on every new asset |
| Refinements for later | `docs/polish-later.md` | at the director's whole-game review |
| How we make games, the tools, LYNX | `handbook/`, the studio's NEXT LUDUS clone. Research writes and pushes it; the builder pulls it | when a topic comes up |
| History | `docs/archive/`, git log | only when you need it |

Change a fact only in its home and link to it from anywhere else. Specs hold the current design only. Read the section a task needs, never whole files "to be safe". The handbook isn't copied into this repo (the directive, section 16): link to it.

## Team notes

- Keep the "Now" board in `docs/team-notes.md` current: each teammate's status row (two to five lines, rewritten, never added to), the turns, what waits on the director, tier 1 and 2 notices.
- A notice leaves the board at the next release, or after seven days. Its record stays in its piece's entry.
- After each finished piece, add one entry at the top, at most about 10 lines: what changed, where it lives, what's open, who it's for.
- When the file passes about 250 lines, move the oldest entries to `docs/archive/`.
