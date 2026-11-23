# What makes it a game: the designers' lessons, and the holes between our systems

Research (Quaestor), 2026-11-23, for the director's question of that day: "what have we progressed so far and what do we need to do left it still doesnt like a game there is many issue especially design issue so i want you to study from many renowned game designer how certain stuff are made from A to Z and take all the good notes remember i noticed many holes in between systems take a look on many games not only this one but gta 6 for example".

Five research strands were run on the web, and their sources are linked below:
- the designers' foundations;
- systems and economy design;
- Rockstar and GTA VI;
- the genre's peers;
- Roblox's own retention guidance.

Our side was audited against `docs/design.md`, `docs/north-star.md`, `docs/balance.md`, the requests and the code.

**Labels.**
- **(read):** a strand read the page itself.
- **(excerpt):** only a search snippet or a headline was seen.
- **UNVERIFIED:** couldn't be confirmed.
- Our own numbers are MEASURED, SIMULATED or MODEL, as `docs/balance.md` uses them.

The fixes in section 4 are proposals. Nothing here changes the design until the director says yes. A tier 3 fix is written as a restatement for that yes.

## 1. Where we stand

**From 2026-11-09 to 2026-11-23:** 1,366 commits, 51 test requests (TR) and 51 asset requests (AR).

**Built and in the game:**
- the loop's whole circuit;
- five Voidkin with their models, clips and signatures;
- the Shade rig;
- Lantern Row and its keeper;
- the HUD, the reveal, the Breaker and the Power screen;
- Regalia with its 14 slots, Reinforce, emblems and jewels, and Combat Power;
- the chests, the Tower in grey, and the base's levels and machines.

**Built but not verified.** These pieces are implemented and tested offline, but none of them has run in Studio:
- AR49, TR51 and TR37 (the Forge and the Condenser);
- the Festival place's run cases.

The reason: the Studio MCP attaches to a blank Studio window (`docs/team-notes.md`, Faber's row). The board's count reads **0 pieces closed and playable this week.**

**Delivered but not installed.** These art pieces wait on Faber's install, in the order on the board:
- AR40, AR43, AR44, AR48, AR49, AR50 and AR51;
- TR50's palettes.

**What the director plays** is the build without most of them. That alone explains part of "it doesn't feel like a game": a good share of the recent work isn't in the game yet.

**Left for launch** (`docs/production-plan.md`, "Phases" and "The cut line"):
- **Phase 3's tail:** the installs above, TR31 to TR35, and the responsive pass.
- **Phase 4:** the Void Shop, built, and the Robux store, designed, checked against Roblox's rules and approved by the director.
- **Phase 5:** the Clash Grounds, only if they reach the bar.
- **The Voidkin, at the end:** each one's own basic attack and signature, and the redesigns of Rook, Kirra, Pip and Lyric.
- **Phase 6:**
  - the finish pass;
  - the game page and Roblox's maturity questionnaire;
  - a real phone;
  - a soft opening.

## 2. The lessons, A to Z

### 2.1 What a game is, and how it's built

**MDA (Hunicke, LeBlanc, Zubek, 2004)** (read): https://cdn.aaai.org/Workshops/2004/WS-04-04/WS04-04-001.pdf
- A game has three layers:
  - **mechanics:** the rules and the data;
  - **dynamics:** "the run-time behavior of the mechanics acting on player inputs";
  - **aesthetics:** what the player feels.
- The designer builds from the mechanics up. The player meets the feeling first.
- How it's built:
  1. Name the feeling you want.
  2. Model the dynamics that make it.
  3. Choose the mechanics that drive those dynamics.
  4. Tune by playing.
- A loop where the rich get richer loses its tension, and "Dramatic tension and agency are lost" (their Monopoly example).

**Sid Meier** (read):
- **A game is a series of interesting decisions.** A decision is dull if the player always picks the same option, or if the outcome is random. Good decisions trade risk against reward, or now against later, and "Good decisions are situational." Every decision must be acknowledged: "The worst thing you can do is just move on." https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions
- **The player has the fun,** not the computer. Hidden systems that choose for the player drain the fun, and the player must "always be the star."
- **The Covert Action rule:** two games inside one compete for attention unless one clearly serves the other.
- **Tuning:** double it or halve it, never 5%. https://www.designer-notes.com/?p=119
- **Rewards:** reward early, inside the first 15 minutes, and show progress often. https://www.gamedeveloper.com/pc/gdc-sid-meier-s-lessons-on-gamer-psychology

**Raph Koster** (read):
- Fun is learning a pattern.
- "Games are machines built around uncertainty."
- The verbs repeat while the situations change: the progression loop is "a spiral".
- Feedback must "show what you can do, that you did it, what difference it made, and whether it helped".
- If a new enemy can be beaten with the old tactics, "This is where players find repetition."
- Sources: https://www.raphkoster.com/?p=48717, https://www.raphkoster.com/?p=4090

**Jesse Schell, the lenses:**
- **Toy:** "If my game had no goal, would it be fun at all?" (read) https://schellgames.com/blog/the-lens-of-the-toy
- **Economy:** "What can my players buy? Why?", "Is money too easy to get? Too hard?", "Are choices about earning and spending meaningful ones?" (read) https://schellgames.com/blog/the-lens-of-economy
- **Meaningful Choice, Reward, Interest Curve:** paraphrased; the exact wording is UNVERIFIED.

**Masahiro Sakurai:**
- Risk and reward, the push and pull, is "the very core of game essence". https://nintendolife.com/news/2022/08/video-masahiro-sakurai-breaks-down-risk-and-reward-in-games
- Combat should reward strategy, not button smashing. https://www.gamedeveloper.com/marketing/postcard-from-the-gdc-2004-masahiro-sakurai-on-risk-and-reward
- "Work" games, the ones that earn income (Cookie Clicker, PowerWash Simulator), hold players without push and pull, but they are a different pleasure.

**Nintendo, one concept per stage** (read):
- Hayashida: learn the mechanic, meet it in "a slightly more complicated scenario", then a twist that "throws them for a loop", then "demonstrate ... mastery". https://www.gamedeveloper.com/design/the-structure-of-fun-learning-from-i-super-mario-3d-land-i-s-director
- Miyamoto: World 1-1 teaches by playing.

**Daniel Cook** (read):
- **Skill atoms** run action, simulation, feedback, then the player's model. A skill nothing uses burns out, and burnout spreads to the skills around it: "If nothing interesting happens on platforms, players stop jumping." https://www.gamedeveloper.com/design/the-chemistry-of-game-design
- **Loops** repeat. **Arcs** are used once: "An arc is a broken loop you exit immediately."

**Steve Swink, and Jonasson and Purho:**
- Swink: game feel is real-time control, polished. https://www.gamedeveloper.com/design/game-feel-the-secret-ingredient
- Juice is "maximum output for minimum input". https://gdcvault.com/play/1016487/Juice-It-or-Lose
- **The counterweight:** Purho's later talk, "Don't Juice It or Lose It", argues that juice can cost immersion. https://gdcvault.com/play/1020861/Don-t-Juice-It-or

**What keeps players** (read):
- **Self-Determination Theory:** autonomy, competence and relatedness each predict enjoyment and future play. Autonomy comes from "choice over tasks and goals". https://doi.org/10.1007/s11031-006-9051-8
- **Hodent:** players learn by doing, about three things at a time, and you show the locks before the keys. https://celiahodent.com/gamers-brain-ux-onboarding/
- **Pecorella (idle games):** "the longer you're away from the game, the greater your incentive to return", "a natural energy system without the need for an energy currency". https://gamedeveloper.com/design/the-rise-of-games-you-mostly-don-t-play

### 2.2 Systems that interlock: the economy

**Adams and Dormans, Machinations** (read):
- Every resource moves through sources, drains, converters and traders. State connections let one system change another without a resource passing.
- A *static engine* makes a steady flow and "rarely inspires long-term strategy". A *converter engine* can deadlock.
- A loop's analysis finds the design's flaws, the dominant strategies among them.
- Sources: https://www.gamedeveloper.com/design/the-designer-s-notebook-machinations-a-new-way-to-design-game-mechanics, https://machinations.gitbook.io/docs/getting-started/framework-basics

**Cook, "Value chains"** (read): https://lostgarden.com/2021/12/12/value-chains/
- Every resource leads, node by node, to an **anchor**, a real need the player has. "Value for a particular action comes from how it facilitates subsequent activities."
- The chain should be "pulled somewhat taut": sinks a little larger than sources. "Big pools reduce pull."
- The holes he names:
  - a broken chain (nothing after the action);
  - a weak anchor;
  - pooling;
  - inputs that are all alike, so whole sources dangle;
  - no overflow after a cap.

**Sellers** (read in excerpt):
- Move between the parts, the loops and the whole.
- "Are there systems that operate independently of the players?"
- Do the parts "support the desired gameplay experience or get in its way?"

**Katkoff** (read):
- The Clash of Clans Builder Base had no "meaningful shared progress or resources" with the home village, so it felt like a mini-game. https://www.deconstructoroffun.com/blog/2017/6/18/the-good-bad-ugly-of-clash-of-clans-builder-base
- The core loop is a dual loop: a short session loop and a long one.

**Google, Android Developers:** a currency surplus means players lack a reason to spend. https://android-developers.googleblog.com/2015/10/virtual-currency-sources-and-sinks.html

**How to find the holes, in short:**
1. List every resource, slots and rates included.
2. Type each source and each sink.
3. Trace each resource to an anchor.
4. Ask whether spending it changes what the player does.
5. Draw a matrix of which system feeds which: an empty row or column is an island.
6. Name each positive loop's brake.
7. Compare sources with sinks at day 1, day 7 and day 30.
8. Make sure every capped resource spills over somewhere.

### 2.3 The genre's peers

**AFK Arena and AFK Journey** (read):
- The decision is the team, before the fight, and the fight shows it: "a battle plays out that reflects who put together the more cohesive squad". https://www.avclub.com/afk-journey-honor-duel-auto-chess
- **One act stays the player's inside the fight:** the ultimate's timing. In AFK Journey the player also aims where it lands. https://www.pocketgamer.com/afk-journey/review/
- How far you've cleared sets the idle income, so idling is a reason to fight. https://www.deconstructoroffun.com/blog/2019/6/6/afk-arena-puts-lilith-into-the-billionaire-club
- **Upkeep shrinks as the roster grows:** gear belongs to the class, and one hall shares levels. http://www.pocketgamer.biz/game-analysis-the-evolution-of-idle-rpg-systems/

**Honkai: Star Rail:** auto-play and 2x speed, but the ultimate fires "at any time ... without consuming any player turns". https://naavik.co/deep-dives/how-honkai-star-rail-reveals-cracks-in-the-hoyoverse/

**Palworld** (read):
- The same creatures fight and work, so every catch has two reasons.
- Every Pal "should have something that gives players a reason to remember it". https://mp1st.com/?p=316945
- The base's output becomes the gear for the next hunt. "Just about everything you do has a real time cost." https://gamingbolt.com/palworld-1-0-review-the-pals-are-put-to-work
- **Its warning:** "It feels like a treadmill – or maybe a hamster wheel". https://www.videogameschronicle.com/review/palworld-10-review/

**Pokémon:**
- Masuda: "rock-paper-scissors is a deep game".
- Approachable first, with depth for those who want it.
- Source: Iwata Asks, BW2.

**Vampire Survivors** (read):
- The only control is movement, and it's enough: a dance through the horde.
- Each run offers fresh build choices.
- The pace swings between easy dominance and rising tension.
- Source: https://theconversation.com/vampire-survivors-how-developers-used-gambling-psychology-to-create-a-bafta-winning-game-203613

**Grow a Garden** (read):
- **A global shop that restocks every five minutes:** "so there's always something pulling you back into the game".
- **Crops grow while you're away.**
- **Weekly updates:** each record peak came with a named update.
- Sources: https://www.click2houston.com/business/2025/07/30/millions-are-flocking-to-grow-virtual-gardens-in-viral-roblox-game-created-by-teenager/, https://gamesbeat.com/janzen-madsen-interview/

**Steal a Brainrot:** the base is a game because it can be lost and defended. https://en.wikipedia.org/wiki/Steal_a_Brainrot

**Naavik on Roblox hits:** mechanics that live in "menus or idle timers need to be turned into things players can walk through, show off, and do together". https://naavik.co/digest/predicting-the-next-big-hits-on-roblox/

**Where auto combat fails** (read):
- Kotaku on Alchemy Stars: "As soon as I set the battle to auto, my game is tied up by an AI playing matches badly". https://kotaku.com/turn-based-strategy-game-alchemy-stars-needs-a-smarter-1847828686
- Oscar Clark: a game that encourages him not to play it annoys him. https://www.pocketgamer.biz/mobile-mavens-auto-play/

**Anime Vanguards, Anime Defenders, Pet Simulator 99, Blox Fruits:** no developer interview or reputable analysis was found. Any design claim about them is UNVERIFIED.

### 2.4 Rockstar and GTA VI

**Status.** GTA VI is out, released 2026-11-19 (OFFICIAL, https://www.rockstargames.com/VI). OpenCritic's top critics average 99 (https://opencritic.com/game/15398/grand-theft-auto-vi).
- **Praised:** how dense the world is, and how it reacts.
- **Criticised:** 30 fps, clunky controls, missions "a bit on rails", and the pacing.

What carries over to us:
- **The world exists without you.** Houser: "if I did nothing, the world still existed" (Lex Fridman #484). RDR2 began from the camp: making the gang react to Arthur upgraded the AI for the whole world.
- **Cohesion is the filter.** Houser judged the game by "the way the whole thing sat together". Garbut: "This is not a collection of missions inside a big world filled with blips for pick-ups and minigames."
- **The same rules inside and outside missions** (Nelson, GTA VI). A set piece is the open game's rules, dressed.
- **The story paces what unlocks:**
  - Houser: unlocking is "an art and a skill";
  - GTA V's three leads came one at a time;
  - GTA V opened on "very intense missions from the start".
- **Danger you read at a glance.** GTA VI's stars say what the police know: solid, flashing, red or hollow. The tuning was "lots and lots of iteration", because the police were "too easy or too hard" (Hynd, TechRadar, 2026-11-19).
- **Money matters.** "We have made money matter more in this story." GTA V's crew traded their cut against their skill.
- **Passive income needs a moment, not a chore.** GTA Online's nightclub: owning one is fun, but "keeping it successful is a little boring". https://pcgamer.com/owning-a-nightclub-in-gta-online-is-fun-but-keeping-it-successful-is-a-little-boring
- **Fix a stingy economy fast.** Red Dead Online paid $3 to $5 a mission while a pistol cost $1,000, and Rockstar raised the rewards within weeks.

**What not to copy:**
- RDR2's slow first half ("outrageously languid", Kotaku).
- Controls that answer late. Weight should come from the picture: anticipation, hitstop, knockback.
- Systems the game "under-explains".
- Polish bought with overtime (Kotaku, 2018).

### 2.5 Roblox's own guidance (read; dated)

- **Fun within five minutes.** "Ensure users have fun within the first five minutes of joining your game." "Avoid a complex or time consuming FTUE." https://create.roblox.com/docs/production/analytics/retention
- **The first session's three jobs:**
  - teach what to do and why;
  - get to the fun fast, with low early thresholds;
  - leave players wanting more, with short, mid and long goals "in highly visible places", ending on "an intentionally designed moment of joy".
  - Source: https://create.roblox.com/docs/production/game-design/onboarding
- **Discovery.** It reads a first-play bounce under 60 seconds and at 61 to 180 seconds as a "most important" negative signal. Play days over day 1, days 2 to 7 and days 8 to 28 count too, and playtime is capped at 60 minutes a day per user. Since 2026-06-15 the signals cover 28 days. https://create.roblox.com/docs/discovery
- **Single-player games struggle.** "Don't create barriers like individual server instances that prevent users from playing with friends." Roblox measures co-play sessions at 1.9 times longer than solo (its own figure).
- **Update cadence:** small updates every 2 to 4 weeks and big ones every 2 to 3 months. Curation for Standout Games asks for at least monthly updates, and checks that new players understand the game on first play and that it runs on low-end devices. https://devforum.roblox.com/t/4005089
- **Quests and dailies.** Quests teach by playing, and dailies reward a return each day.

## 3. Our holes, each against the lessons

Ordered by how much of "it doesn't feel like a game" each one explains, in research's judgment.

**H1. The player has almost nothing to do in a fight.**
- **The design:** "The player's avatar is never a target and never deals damage." The player steers by standing, within a leash of about 30 studs, and the signature fires on its own. "A player who parks beside enemies and watches is playing the game as designed" (`docs/design.md`, "Combat").
- **The one act inside a fight** is TR44: moving the lead out of the Lamplighter's marked slam. It exists only in the keeper's fight, isn't verified, and waits on the director's go and the pick between A and B.
- **The design already defers the fix.** Firing the signature by hand is listed under "Out of launch" (`docs/design.md`) and parked in `docs/polish-later.md`.
- **The director's own directive warns of this:** "Do not mistake a mathematically valid auto-battle simulation for a fun combat system" (`docs/archive/directive-2026-11-09.md`, section 10).
- **Lessons it breaks:**
  - Meier: the player must be the star.
  - Koster: feedback that shows what *you* did.
  - Every auto battler studied leaves the ultimate's timing to the player (AFK, AFK Journey, HSR), and Vampire Survivors leaves movement and dodging.
  - Kotaku and Clark describe exactly this failure.

**H2. Every fight asks the same question, and one answer always wins it.**
- **The code:** `src/shared/Definitions/Enemies.luau` holds a Brawler, a bigger Brawler as the elite, the Lamplighter and a dummy.
- **The roster:** `docs/roster.md` designs four behaviours: Brawler, Guard ("by waiting, or by breaking through"), Dasher ("shows a line, then lunges") and Support ("by reaching it first: an Assassin's job"). Three were never built.
- **Types:** every ordinary Shade and elite is Red, and the keeper is Purple. The type ring is "worth as much as a third of a build" (`docs/balance.md`, SIMULATED), so the best lead for Lantern Row is the same in every run: a decision made once.
- **The director's word of 03:25** already names this: each phase "need[s] to be varied between phase and fun".
- **Lessons it breaks:**
  - Koster: old tactics beat the new enemy, so this is where players find repetition.
  - Hayashida: introduce, develop, twist, master.
  - Meier: a choice with one answer isn't a choice.
  - Pokémon and AFK: readable counters.

**H3. The lead choice and the bay choice hardly exist at launch.**
- Five Voidkin, one leading, and four bays at base level 3 (D5): every Voidkin that isn't leading works, and "who works" is never a choice.
- Aptitude (1 to 3) changes output, but not who goes where.
- **Lessons:** Palworld and Genshin make "who works where" a choice only because the roster is larger than the slots, and the work types differ.

**H4. Electricity may not be a real trade-off.**
- **The simulation:** the bays cover the Breaker's demand 1.5 to 1.7 times over for a player on half an hour a day, and the chambers are under 12% busy (`docs/balance.md`, SIMULATED). That run predates the Training machine's and the Condenser's draw, so today's balance is unknown.
- **If it's still slack,** the Power screen's split (the director's own design of 2026-11-14) is a choice with one answer: Auto.
- **Lessons:**
  - Dormans: a static engine "rarely inspires long-term strategy".
  - Cook: a chain "pulled somewhat taut".
  - Google: a surplus means no reason to spend.

**H5. The economy and the deep build were fitted to a bigger game.**
- `docs/balance.md` was fitted to six grounds, 31 Voidkin and about 57 hours. Launch has one ground (a 10 to 15 minute run, on Normal then Hard), five Voidkin and the Tower.
- The full build still launches: 14 slots, Reinforce, emblems, jewels and the Forge. TR48's MODEL puts a Legendary at about 18 hours of Lantern Row repeats.
- **Lessons:**
  - Levy: design the power, the currency and the content together.
  - Cook: pooling and treadmills.
  - Red Dead Online's launch economy.
  - Meier's Covert Action rule: a build system bigger than the fights it serves competes with them.

**H6. Nothing tells the player what to aim for next.**
- No quests, no daily goals, no mission list: the design has none, and the code has none.
- "The daily track" is named once, as a source of Research Points under the Clash Grounds (`docs/design.md`, "What the player holds"), and the Clash Grounds may not launch.
- **Lessons:**
  - Roblox: short, mid and long goals "in highly visible places"; D7 is progression; dailies reward a return.
  - SDT: autonomy comes from choice over goals, which needs goals to choose between.

**H7. The base and the fights are two islands.**
- Lantern Row is a separate place, reached by teleport (TR45). That breaks pillar 3's "a shard cracking while you fight" (`docs/north-star.md`).
- The players in the base's neighbourhood aren't the ones a player fights beside.
- What links the two today is a state connection: electricity speeds up the Breaker, which makes the shards. Nothing of the base is seen or felt during a run, and nothing marks the return.
- **Lessons:**
  - Katkoff's Builder Base.
  - Naavik: walk through, show off, do together.
  - Roblox: no instances that split friends, and co-play sessions run 1.9 times longer.
  - Pecorella and AFK: a payoff on return.

**H8. The first session points at content that doesn't launch, and its first fight is behind a teleport.**
- The "Want" beat: "sees the keeper's gate, the next ground behind it" (`docs/north-star.md`). In the design, that's Drum Court's gate, shut (`docs/design.md`, "The world, in grey"), and Drum Court is in the update after launch.
- The first fight needs a teleport into the Festival place, inside Roblox's 61 to 180 second bounce window.
- Whether a teleport inside the same experience counts as a bounce is UNVERIFIED. A load screen in the first minutes is the cost GameAnalytics' "Win the first two minutes" warns about.

**H9. The delayed content is planned as one big update.**
- The director's word of 2026-11-17, 02:40: "everything we delayed will likely come in 1 massive updates".
- Roblox's guidance: small updates every 2 to 4 weeks, at least monthly for curation. Grow a Garden's peaks each came with a named update.
- With five Voidkin, a player owns them all early, and every reveal after that is a copy for stars. The reveal, "an event" by pillar 4, fades the fastest.

**Checked and fine:**
- **Research Points:** they exist in the profile, but nothing pays them out and nothing spends them, so no currency is left orphaned at launch.
- **The Void Shop's clock:** global, five minutes, salted on the server, with a limit per player. That's Grow a Garden's strongest pull, done right.
- **Overflow:** power past the battery's cap sells for Credits at a poor rate, which is Cook's overflow.
- **Health carries,** so "one more pack, or home" is a real push and pull (Sakurai).
- **The keeper is a decision,** and losing costs only the try.
- **No paid random item** without the director's approval.

## 4. The fixes, ranked

Each fix gives what it is, the lesson behind it, its cost in active hours (seeds), and its tier. A block is judged in motion before anything is finished.

**F1. One act of the player's in every fight: the signature on a tap** (answers H1; tier 3, because it brings an "Out of launch" item into launch and changes how combat plays).
- **What:** the lead's signature fills a gauge, and the player taps one button to fire it. An Auto toggle keeps parked play allowed, so routine progression never needs the tap. That keeps the directive's line: "Avoid requiring constant tedious manual interaction for routine progression."
- **With it:** TR44's rule, moving the lead out of a marked strike, extends from the keeper to the Dasher's line (F2). The two acts become the player's skill: when to spend the signature, and where the lead stands.
- **Lessons:** AFK, AFK Journey and HSR, Meier, Koster.
- **Cost:** a block, Faber about 3 h, inside the 90-minute cap per action plus the HUD button, then research's verdict.
- **Restatement for the yes:**
  - **Changes:** the signature is fired by the player when its gauge is full; Auto fires it as today.
  - **Replaces:** the signature firing on its own as the only mode, and "manual signatures" in "Out of launch".
  - **Touches:** `docs/design.md`, "Voidkin" (the kit), "Combat" and "Out of launch"; `docs/polish-later.md`'s line; the HUD, with one button; the Voidkin's signatures' timing; the Tower's fights.

**F2. Four stretches, four questions** (answers H2, and the director's word of 03:25; tier 2 for the content, which the roster already designs; tier 3 for the order, since the director put the Festival after the main map and the systems).
- **The stretches:**
  1. Brawlers (learn).
  2. Guards join, and the shield is beaten by waiting or by a well-timed signature.
  3. Dashers join, each showing its line before the lunge: move the lead off it. A Support stands at the back, and is an Assassin's job.
  4. The Lamplighter: everything at once.
- **Types:** the packs mix two or three types, so the lead you bring is a plan for the run, not a fixed answer.
- **Lessons:** Hayashida's four beats, Koster, Pokémon's counters.
- **Cost:** Modulo, two masks on the existing rig (Guard and Dasher; the Support after), with their block clips. Faber, three behaviours in the Shade's rules, about 6 h. Research, the stretches' mix and its numbers.
- **The order question:** start now, or after the main map and the systems.

**F3. Fit the economy to the game that launches** (answers H5 and H4; research's own, tier 1 to run, tier 2 for any number that changes).
- **What:**
  - re-run `tools/balance/sim.py` and the loot fit with one ground, Normal and Hard, five Voidkin, the Tower, and every machine that draws power;
  - set the launch's length: the hours until a player has done Lantern Row on Hard and the Tower's first milestones;
  - check every resource against section 2.2's eight steps, at day 1, day 7 and day 30.
- **Out of it:** the electricity margin made taut, so running every machine asks about 1.2 to 1.4 times what the bays make (a seed) and a split beats Auto for a purpose. Any build layer with nothing to chew on at launch goes to the director as a cut or a gate.
- **Cost:** research about 4 h, starting now.

**F4. The return moment** (answers H7's missing payoff; tier 2).
- **What:** coming back to the base, after a run or the next day, shows what it made while you were away, collected in one tap:
  - the battery's kWh;
  - the Condenser's stones;
  - the Training machine's levels;
  - the shard that broke.
- **Lessons:** Pecorella, AFK's chest, HSR's one-tap assignments, Rockstar's nightclub warning.
- **Cost:** Faber about 3 h, and Modulo a card in the system slab's make.

**F5. Three goals always in view** (answers H6; tier 3, a new system for launch).
- **What:** one short goal (this run's), three for today, and one long one (the account's next step: Hard's keeper, base level 3, a Tower milestone), on the HUD or Home's panel. Rewards in Credits and stones, never paid.
- **Lessons:** Roblox's guidance, SDT, Meier.
- **Cost:** research's design about 2 h, Faber about 6 h, Modulo the panel.
- **Restatement for the yes:**
  - **Changes:** launch has a goal layer, with dailies.
  - **Replaces:** no goals beyond the loop itself.
  - **Touches:** `docs/design.md`, a new section; `docs/ui.md`; Credits' sources in `docs/balance.md`.

**F6. The base felt during a run** (answers H7; tier 2).
- **What:** in the Festival place, one line of the base's state (the shard's time left, the battery), and a notice when a shard breaks: "Your shard broke. Its Voidkin waits at home." The profile is the same across the universe, so the Festival server can read it.
- **Lessons:** pillar 3, Katkoff, Rockstar's "the world exists without you".
- **Cost:** Faber about 2 h.

**F7. The first session in what launches** (answers H8; tier 3, because it touches the vision's beats).
- **What:**
  - the "Want" beat points at Hard's Lamplighter, the Tower's door and the shop's featured stock;
  - Drum Court's gate stays shut and says it opens in an update;
  - the first fight happens before the first teleport, if it can be built cheaply (to be checked).
- **Restatement for the yes:**
  - **Changes:** the first session's last beat, and possibly where the first fight is.
  - **Replaces:** "sees the keeper's gate, the next ground behind it".
  - **Touches:** `docs/north-star.md`, "The first session"; `docs/design.md`, "The world, in grey"; TR32's funnel steps.

**F8. Updates as a cadence, not one drop** (answers H9; tier 3, the director's word of 2026-11-17).
- **What:** the delayed content ships as named updates every two to four weeks (Sable, the Rift, Drum Court, and so on), each with its own featured stock on the shop.
- **Lessons:** Roblox's guidance and curation criteria, Grow a Garden's named peaks.
- **Restatement for the yes:**
  - **Changes:** after launch, small named updates every 2 to 4 weeks.
  - **Replaces:** "1 massive update".
  - **Touches:** `docs/production-plan.md`, "The cut line".

**F9. Make the game playable before making more of it** (process; research's proposal for the board).
- **What:** Faber's install and verification backlog goes first, as the board already orders it. Modulo's new pieces for the main map wait until that backlog is down to about two. The director can't judge what isn't in the build.
- **Lessons:** Meier: success depends on how many times the loop of playing and changing runs. Rockstar: cohesion, judged on the whole.

**Not proposed:** stealing from bases. It's Steal a Brainrot's strongest pull, but it clashes with "Fighters are valuables" (`AGENTS.md`). Visiting a base and showing it off is the safe version, after launch.

## 5. What's uncertain, and the cheap tests

- **F1:** whether a tap feels like play or like a chore on a phone. A 90-minute block, judged in motion, with Auto on and off.
- **F2:** whether the Guard's shield reads at phone size, and whether players move the lead off the Dasher's line. The block counts hits and misses, as TR44 does.
- **F3:** today's electricity margin. Measured by the simulation, not argued.
- **H8:** whether a same-experience teleport counts as a first-play bounce: UNVERIFIED. TR32's funnel shows where new players stop, once strangers play.
- **The 1.9-times figure for co-play** is Roblox's own internal number.
