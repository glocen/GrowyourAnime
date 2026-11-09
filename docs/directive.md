# The director's directive, 2026-11-09

The director's own text, given to research on 2026-11-09, kept word for word. Only the headings and the one table were set as Markdown. What it decides, and what the director said beside it the same day: `docs/decisions.md`. Change nothing here: a later word from the director goes in the register.

GROW A ANIME

NEXT LUDUS — Game Foundation & LYNX Production Directive

Date: November 9, 2026
To: Quaestor and the NEXT LUDUS development team
Framework: Project LYNX
Status: Preproduction — preserve established decisions, validate assumptions before implementation
Authority: NEXT LUDUS Director


## 1. The mission

Quaestor,

Our next Roblox project is Grow a Anime.

This game should benefit from everything NEXT LUDUS has learned while developing NEXT Button and Umbra Vesper, including the new LYNX engineering initiative.

Our ambition is to create an original, highly replayable, socially engaging game with a simple initial gameplay loop and substantial room for expansion.

The game should feel immediately accessible, satisfying to play, visually distinctive, and rewarding over the long term.

However, I do not want another rushed implementation that works only for the first version of a feature.

I want intelligent engineering: strong fundamentals, justified extensibility, efficient implementation, and excellent execution.

We are not trying to build the largest game on day one. We are trying to build the right foundation for a game that can become substantially larger.


## 2. An explicit instruction: you are allowed to disagree

Quaestor, Faber, Modulo, and QA are explicitly authorized and encouraged to challenge ideas—including my ideas, previous AI recommendations, and our existing studio rules.

If something looks technically weak, unnecessarily restrictive, inefficient, inconsistent, unoriginal, difficult to maintain, or harmful to the player’s experience, say so.

Do not agree merely because I am the Director.

Do not agree merely because Quaestor proposed it.

Do not obey a previous engineering convention when a clearly superior, permissible alternative exists.

A good disagreement should explain:

1. What appears wrong or suboptimal.
2. Why it matters.
3. What evidence supports the concern.
4. What alternative is better.
5. What trade-offs that alternative introduces.

When uncertainty remains, propose a small experiment rather than pretending the answer is obvious.

For ordinary reversible technical choices within approved scope, exercise professional engineering judgment and proceed.

For established creative decisions, major scope changes, security-sensitive changes, or consequential architectural departures, present the recommendation and obtain the required approval.

Disagreement is encouraged. Silent disregard of approved requirements is not.

The objective is an intellectually honest engineering team, not a team that agrees with every instruction.


## 3. Established game identity

The following decisions have already been established and must be preserved unless I explicitly change them.

Core premise

Players operate a compact personal base containing electricity-powered machinery used to uncover or process Void Shards.

Void Shards are part of the fighter-acquisition process.

Players obtain, train, improve, collect, and battle with original anime-style fighters.

The game combines collection, progression, base development, and automated fighter combat.

Do not replace Void Shards with anime seeds or convert the game into a conventional planting simulator.

The exact fictional explanation and detailed processing mechanics can still be refined.

Compact social neighborhood

Player bases should be positioned near one another.

The world should encourage players to see other players’ progress, fighters, machines, and achievements without needing excessive travel.

Avoid enormous empty spaces and unnecessarily separated bases.

Social interaction should emerge naturally from the environment and progression systems.

Original R6 fighters

The initial game uses original, anime-inspired R6 fighters.

Design original silhouettes, outfits, hairstyles, weapons, animations, effects, names, and abilities.

Anime can inspire the overall genre and energy, but existing copyrighted characters must not be recreated through recognizable combinations of appearance, signature skills, and other protected expression.

Renaming a recognizable character is not sufficient.

Void Clash

The automated battle arena is officially named:

VOID CLASH

Not Void PIT.

Fighters should be able to gain levels through both base training and participating in battles.

The exact battle rules, match structure, team size, and competitive modes still require design.

Permanent Fighter Index

Create a persistent collection Index displaying the fighters players have discovered.

The Index should make collecting meaningful and should support future content without requiring a rewrite.

Fusion, traits, and mutations

These are important planned systems.

They should provide meaningful progression and interesting combinations rather than being purely cosmetic numerical inflation.

Their precise mechanics, costs, and limitations remain open for design.


## 4. Official fighter rarity hierarchy

Preserve the following exact order and spelling:

1. Common
2. Uncommon
3. Rare
4. Epic
5. Legendary
6. Mythical
7. Radiant
8. Secret
9. Divine
10. Transcendant
11. NEXT

Transcendant is the intended spelling.

NEXT must remain capitalized.

Special rule for NEXT

NEXT is reserved for potential future collaborations involving officially licensed anime intellectual property.

Original fighters released at launch must not occupy the NEXT rarity.

Ordinary original fighters cannot evolve or fuse into NEXT.

The existence of this rarity is not evidence that any license has been obtained.

Do not develop, advertise, or publish unauthorized licensed characters in anticipation of a future agreement.

Launch content can include original fighters through Transcendant, subject to the actual production scope.

There is no requirement to populate every rarity tier immediately if doing so would produce rushed or low-quality content.


## 5. Fighter strength and rarity philosophy

Rarity must matter without making lower-rarity fighters automatically worthless.

I want meaningful variation through:

* Base attributes.
* Levels.
* Traits.
* Mutations.
* Skills.
* Fusion outcomes.
* Potential build synergies.

An optimized Legendary fighter should potentially outperform an unmodified Mythical fighter.

This should be supported by intentional balancing, not accidental statistical imbalance.

Avoid a progression model where obtaining a higher rarity instantly invalidates every previous investment.

Do not create a system where every optimization produces uncontrolled exponential power growth.

Before implementing detailed formulas, define the intended relationship between rarity, progression, build quality, and combat performance.

Create simulations for representative fighter builds and compare outcomes.


## 6. The primary gameplay loop

The proposed core loop is:

Acquire Void Shards → Process them with powered machinery → Discover fighters → Train and develop fighters → Enter Void Clash → Earn progression rewards → Improve the base and collection → Repeat

This loop must be satisfying at a small scale before we add dozens of supporting systems.

Void Shard acquisition

Explore a rotating shop inspired by the satisfying availability and collection dynamics of games such as Grow a Garden.

We may incorporate relevant progression ideas from Grow a Chicken Fighter.

These are references to broad design patterns, not instructions to clone another game’s interface, assets, balancing, or distinctive implementation.

A short rotating inventory—previously discussed as potentially around five minutes—is a design candidate, not yet a locked timing requirement.

Research rotation frequency, scarcity, accessibility, and player retention before finalizing it.

Electricity and machinery

The player’s base should contain machinery that uses electricity to process or uncover fighters.

The player should be able to improve the operation over time.

Consider:

* Processing speed.
* Machine capacity.
* Electricity generation or availability.
* Upgrade costs.
* Visual progression.
* More convenient interaction.
* Suitable automation as the player advances.

Do not invent a complicated electrical engineering simulator unless it demonstrably improves the game.

The electricity mechanic should provide understandable choices and satisfying progression, not excessive management.

Training

Fighters develop through base training.

Training should be visually readable, satisfying, and relevant to future combat performance.

Avoid requiring constant tedious manual interaction for routine progression.

Void Clash battles

Automated combat should communicate:

* Which fighters are participating.
* What actions and skills they use.
* Damage and important effects.
* Why a battle was won or lost.
* What rewards and experience were earned.

Strong presentation matters.

Fast, uninteresting combat animations will not be acceptable merely because the underlying formulas are correct.

PvE is a reasonable initial prototype candidate. PvP, rankings, challenges, and other multiplayer modes require separate design decisions.

Do not silently treat those candidates as approved launch commitments.


## 7. Fusion and mutations

These systems need particularly careful design because they affect the game’s long-term economy.

Fusion

Fusion should make collecting duplicate or complementary fighters meaningful.

Research possible systems such as:

* Combining duplicates.
* Increasing a fighter’s potential.
* Unlocking alternative configurations.
* Improving selected attributes.
* Unlocking special cosmetic or ability variations.

These are candidates, not final mechanics.

Before implementation, determine:

* What resources are consumed.
* What the player receives.
* Whether outcomes are deterministic or random.
* Whether fighter progress is preserved.
* Whether the player can preview results.
* How the system affects rarity balance.
* What happens to inventory and Index records.

Do not accidentally destroy a valuable fighter because a client request was replayed or a server operation failed partway through.

The NEXT rarity restriction must be enforced at the server-authoritative rules level.

Mutations and traits

These should create meaningful strategic differences.

Avoid filling the game with dozens of nearly identical percentage bonuses.

Prefer a manageable number of distinctive, understandable effects.

If mutations or traits can be randomized through paid items, the current Roblox paid-random-item requirements must be incorporated before monetization.


## 8. Game architecture — Design for legitimate expansion

This is a direct lesson from NEXT Button’s earlier zone-event development.

Faber must consider justified future extensions before implementing shared systems.

However, do not overengineer.

Core domains to consider

* Player profiles and persistence.
* Fighter definitions.
* Owned fighter instances.
* Void Shard inventory.
* Shop inventory and rotation.
* Machines and electricity.
* Training and experience.
* Combat and rewards.
* Traits and mutations.
* Fusion.
* Fighter Index.
* Base ownership and placement.
* UI and audio.
* Monetization, if later approved.

These are conceptual responsibilities, not a mandate to create one ModuleScript or service for every item.

Choose boundaries according to actual coupling, testability, and server authority.

Definitions versus owned instances

A fighter’s definition should describe its identity and fundamental behavior.

An owned fighter instance should retain its individual progress and rolled properties.

For example, multiple copies of the same original fighter may have different levels, mutations, or traits.

Use stable identifiers for persistent instances.

Do not rely on display names as permanent identifiers.

Do not store unnecessary visual objects directly in player profiles.

The extension test

Before finalizing the initial architecture, examine whether we can reasonably introduce:

* Another fighter rarity.
* A new original fighter.
* A new machine upgrade.
* A new Void Shard type.
* Another base layout or theme.
* A new training activity.
* Another combat mode.

The purpose is to identify obvious structural mistakes.

Do not implement hypothetical expansions merely to prove the system is extensible.


## 9. Persistence, inventory, and transaction safety

Fighters are valuable persistent player possessions.

The data architecture must be designed carefully from the beginning.

Plan for:

* Unique owned-fighter identifiers.
* Levels and experience.
* Traits and mutations.
* Fusion history where required.
* Index discovery records.
* Currency and shard inventories.
* Base progression.
* Machine upgrades.
* Combat progression.
* Save/rejoin behavior.
* Schema evolution.

Fighter acquisition, fusion, and resource spending must be server-authoritative.

Test interrupted and repeated operations.

A network retry must not duplicate a fighter or spend the same resource twice incorrectly.

Reusing existing NEXT LUDUS systems

Evaluate our established ProfileStore, PlayerHandlerData, and ProductManager patterns.

Reuse them if they are suitable.

Adapt them if a focused change is sufficient.

Choose a different architecture if there is a documented technical reason and an approved migration plan.

Do not force Grow a Anime to use NEXT Button’s exact data model merely because that system came first.

Likewise, do not rewrite a proven persistence library just to create a new system.

Choose based on correctness, complexity, maintenance cost, and the actual game’s needs.


## 10. Combat engineering

Void Clash requires a reliable and understandable simulation.

The implementation must define:

* Fighter statistics.
* Target selection.
* Action timing.
* Skill activation.
* Status effects.
* Damage resolution.
* Victory conditions.
* Experience and rewards.

Favor a deterministic or reproducible combat-rules layer where practical.

The server should decide authoritative outcomes.

The client should present the battle attractively without being trusted to award resources or determine official results.

Headless testing opportunity

Much of the underlying battle mathematics may be suitable for pure Luau tests.

Use LYNX’s local testing approach to validate:

* Damage formulas.
* Cooldowns.
* Skill priorities.
* Trait interactions.
* Mutation interactions.
* Outcome reproducibility.
* Boundary values.
* Balance across rarities.

Then test actual animations, replication, visuals, and gameplay presentation in Roblox Studio.

Do not mistake a mathematically valid auto-battle simulation for a fun combat system.


## 11. Character and animation production

We intend to use original R6 fighters.

Establish a reusable but not excessively rigid pipeline for:

* Original character concepts.
* R6 proportions and rigs.
* Clothing and materials.
* Hairstyles and accessories.
* Idle animations.
* Training animations.
* Combat animations.
* Skills and VFX.
* Asset export and Roblox import.
* Performance validation.

Characters must be visually recognizable and have distinct personalities.

Do not use procedural generation merely because it is fast if the result looks generic or artificial.

A small roster of excellent original fighters is preferable to an enormous roster of repetitive models.

Retain the existing Blender and animation validation tools where they work.

Verify R6 compatibility before adopting newly announced R15-specific animation capabilities.


## 12. World design and social interaction

The starting map should feel compact, inviting, colorful, and alive.

Players should naturally see each other’s bases and progress.

Key spaces should be easy to find:

* Player bases.
* Void Shard shop or acquisition area.
* Machinery.
* Training.
* Void Clash.
* Collection and progression interfaces.

The map must support the actual expected number of players and machine/fighter activity.

Do not build an enormous environment simply to create a sense of scale.

Prioritize strong visual landmarks, readable navigation, and low travel friction.

Multiplayer validation

Test:

* Base assignment.
* Players joining and leaving.
* Base ownership isolation.
* Multiple players processing shards.
* Fighter visibility.
* Combat-session isolation.
* Replication and network usage.
* Server performance with populated bases.

The map should support future content without requiring every new feature to be inserted into a single hardcoded first-base implementation.


## 13. UI and user experience

NEXT Button taught us that technically functioning UI can still be visually unsatisfactory.

Grow a Anime must establish a coherent visual identity before producing many independent panels.

Likely interfaces include:

* Void Shard shop.
* Machine management.
* Fighter inventory.
* Fighter details.
* Training.
* Fusion.
* Mutations and traits.
* Fighter Index.
* Void Clash.
* Settings.

These do not all need to be finished for the first playable prototype.

Required quality approach

Use the existing NEXT LUDUS UI tools where appropriate.

Automate geometric checks:

* Clipping.
* Text overflow.
* Overlap.
* Scaling.
* Touch interaction.
* Safe areas.
* Missing assets.

Also inspect the real rendered UI for:

* Composition.
* Color.
* Hierarchy.
* Readability.
* Consistency.
* Animation.
* Artistic quality.

The interface should remain understandable on phones.

Use real game-state examples, including empty and full inventories, rare fighter information, and long names.

No important interface should be considered polished solely because it passes automated linting.


## 14. Sound design and music

Use the developing NEXT LUDUS Audio Workshop.

Grow a Anime needs distinct audio for:

* Void Shard processing.
* Machinery.
* Fighter discovery.
* Rarity reveals.
* Training.
* Fusion.
* Combat impacts.
* Skills.
* Victory and defeat.
* UI interactions.
* World ambience and music.

Audio should reinforce anticipation and reward.

Rare discoveries must feel meaningful without becoming excessively loud or repetitive.

Use authorized samples, original sound design, and suitable procedural generation where valuable.

Maintain provenance and licensing records.

Audition important sounds in gameplay.

Do not assume waveform analysis establishes artistic quality.


## 15. Monetization and player fairness

Do not design monetization by blindly copying popular simulator games.

First establish an enjoyable free progression loop.

Then evaluate optional monetization that does not mislead players or undermine the experience.

Paid random items

Roblox’s current paid-random-item requirements are particularly relevant to Void Shards, randomized fighter discovery, fusion, luck modifiers, and potential reroll systems.

Direct or indirect Robux spending on random outcomes can trigger requirements for:

* Accurate numerical outcome disclosure.
* Up-to-date probabilities.
* Restrictions for ineligible players.
* Relevant PolicyService checks.
* Accurate game compliance declarations.

Do not assume converting Robux into an intermediate currency avoids these rules.

Do not implement paid randomness until its rules are verified and its compliant design is approved.

IP licensing

The initial game uses original fighters.

The NEXT rarity remains reserved for potential officially licensed content.

Do not upload recognizable copyrighted characters without the necessary rights.

A future licensing opportunity should be evaluated against the actual contract, revenue share, permitted uses, and platform requirements.


## 16. Apply LYNX, but do not create another bureaucracy

Grow a Anime is an opportunity to test whether LYNX actually improves game production.

Do not copy the entire LYNX handbook into the game repository.

Link to the studio-wide authoritative documentation.

Keep only the game’s own:

* Vision and approved decisions.
* Implementation contracts.
* Task backlog.
* Game-specific risk register.
* Asset manifests.
* Tests and acceptance criteria.
* Current operational state.

Use the shared LYNX infrastructure for:

* Risk-based agent workflows.
* Efficient reasoning allocation.
* Architectural foresight.
* Git isolation.
* Selene, StyLua, and Luau LSP.
* Suitable Lune tests.
* Rojo builds.
* Open Cloud validation.
* Automated Studio gameplay QA.
* Asset generation.
* Audio production.
* Controlled staging and deployment.
* Measured self-improvement.

Each additional tool must justify its value.


## 17. The first playable vertical slice

Do not begin by implementing the entire rarity system, dozens of fighters, fusion, all UI screens, and a sophisticated combat arena simultaneously.

Start by proving the gameplay.

A strong initial experiment should allow a player to:

1. Enter a compact base.
2. Obtain a Void Shard through a simple acquisition mechanism.
3. Use powered machinery to uncover an original R6 fighter.
4. View and manage that fighter.
5. Train it.
6. Enter a basic Void Clash battle.
7. Receive progression rewards.
8. Save, leave, rejoin, and retain the correct state.

This should demonstrate that the fundamental loop is entertaining and technically sound.

Use placeholder quantities and limited content where appropriate for a private prototype.

Do not publish unfinished placeholder content as a polished release.

Once this loop works, test it with multiple players and representative mobile devices.

Only then expand the roster, Index, traits, mutations, fusion, shop depth, and long-term progression according to measured priorities.


## 18. Engineering verification

Create tests proportional to risk.

Local headless tests

Prioritize:

* Fighter definitions.
* Rarity order.
* Stat calculations.
* Training rewards.
* Experience curves.
* Shop inventory logic.
* Machine-processing rules.
* Combat resolution.
* Fusion eligibility.
* Inventory capacity.
* Currency validation.

Open Cloud checks

Use where appropriate for Roblox engine integration without a normal running game session.

Do not expect full gameplay physics or player simulation.

Studio tests

Validate:

* Machine operation.
* Fighter spawning and presentation.
* R6 animations.
* Combat visuals.
* Multiple player bases.
* UI and touch controls.
* Asset loading.
* Replication.
* Audio.
* Performance.
* Save/rejoin behavior.

Every automated test should identify the actual behavior it establishes.

Do not claim a visual-quality pass from static checks.


## 19. Scientific balancing

Avoid assigning arbitrary values without evaluating the progression they produce.

Build lightweight simulations for:

* Fighter acquisition.
* Shard availability.
* Machine upgrade progression.
* Training speed.
* Combat reward pacing.
* Rarity distribution.
* Fusion economics.
* Trait and mutation strength.
* Long-term collection progression.

Test different player behaviors.

For example:

* A new player.
* A player with limited playtime.
* An experienced optimizing player.
* Someone with an unusually strong lower-rarity fighter.

Do not claim these simulations predict actual player retention.

Use real playtesting and later live analytics to calibrate the game.

Our goal is satisfying progression, not simply mathematically smooth curves.


## 20. Continuous improvement in Grow a Anime

LYNX must learn from actual game development.

For every meaningful failure, ask whether there is a reusable engineering lesson.

Examples:

* Rewriting a machine system because a second machine type was not anticipated.
* Duplicating fighter definitions across interfaces.
* UI breaking when a fighter has a long name.
* Fusion corrupting inventory state after an interrupted operation.
* R6 animations importing incorrectly.
* Combat tests passing while the battle looks uninteresting.
* Too much agent effort spent on unnecessary documentation.

Investigate the root cause.

Create the smallest useful correction.

Verify that correction on later tasks.

Promote proven lessons into the shared NEXT LUDUS engineering knowledge.

Remove obsolete instructions when appropriate.

Do not confuse recording a lesson with actually improving the system.


## 21. Decisions still open

Quaestor should research and present recommendations for these areas rather than silently inventing binding decisions:

| Area | Decision needed |
|---|---|
| Void Shard shop | Rotation rules, pricing, inventory behavior |
| Electricity | Meaningful depth without unnecessary complexity |
| Processing | Timing, interaction, upgrade paths |
| Initial roster | Number and diversity of original fighters |
| Training | Active, passive, and automation balance |
| Void Clash | Team size, matchmaking, PvE/PvP scope |
| Combat | Skill complexity and presentation standards |
| Fusion | Deterministic versus random outcomes, costs, inheritance |
| Traits/mutations | Variety, balance, acquisition |
| Economy | Currencies, sinks, rewards, progression |
| Monetization | Fair, compliant, clearly communicated products |
| Release scope | Smallest polished experience worth launching |

For each important recommendation, identify the simplest plausible option and its trade-offs.

Do not ask the Director to choose dozens of trivial implementation details.

Escalate decisions that materially affect the game’s identity, economy, production scope, or risk.


## 22. What Quaestor must deliver first

Before assigning large implementation tasks, provide:

A. Game design foundation

A concise description of the gameplay loop, player goals, and distinguishing features.

B. Decision register

Confirmed requirements, proposed ideas, unresolved questions, and rejected directions.

C. Minimal playable slice

A prioritized sequence that proves the core loop with limited content.

D. Architecture sketch

Major data contracts, state ownership, server/client boundaries, and justified extension points.

E. Content production plan

Original R6 fighters, world, UI, animation, VFX, and audio.

F. Technical risk register

Persistence, combat authority, asset compatibility, paid randomness, permissions, and multiplayer performance.

G. LYNX validation plan

Which existing tools can test each major system, and which new experiments are genuinely necessary.

H. Recommended improvements and disagreements

A dedicated, concise section explaining which parts of the Director’s vision or existing studio conventions the team believes should be challenged and why.

Do not write an enormous speculative design bible before proving gameplay.

Do not create a new framework solely for Grow a Anime if the shared LYNX tools already suffice.


## 23. Final instruction to the team

Quaestor, Faber, Modulo, and QA:

You are not expected to be passive executors.

I want you to think, critique, experiment, and develop sound technical and creative judgment.

If you believe one of my decisions is bad, tell me.

If an architectural requirement will slow development or create unnecessary complexity, explain it.

If a proposed mechanic will damage player enjoyment or balancing, challenge it.

If a better implementation exists, present it.

If an existing NEXT LUDUS convention does not fit Grow a Anime, do not force it blindly.

But always distinguish between proposing a change and receiving permission to change an established requirement.

Our engineering must remain honest, efficient, safe, and evidence-based.

Our artistic ambition must remain high.

Grow a Anime should become a game with its own identity—not a collection of borrowed systems.

Build an excellent small experience first. Design its foundations intelligently. Expand through justified systems. Let LYNX make the production process faster and better with each milestone.

The Director remains the final decision-maker.

And the team is explicitly encouraged to help the Director make better decisions through constructive disagreement.

NEXT LUDUS creates the games. LYNX develops the studio. Grow a Anime should demonstrate what both can achieve together.
