# The combat math, reviewed (Quaestor, 2026-11-19)

The director, 13:45 to 13:53: "The stats formula need to be revised dont it? like the defense calculation with attack with everything else do it really work? ... we need a lot of thought on this and make it great", then "it need to be perfect".

## How it was done

**The studies:**
- Every number comes from the game's own rules (`Rules.Hit`, `Rules.Stats`, Config), run offline under Lune, with exact expected values over the roll outcomes or fights simulated hit by hit.
- Four studies ran apart: the formula; Combat Power; the enemies against the players' real builds; the five attributes.
- A fifth pass applied the changes together, in order, re-fitting each after the ones before it.
- An independent check then tried to break that pass. It found a wrong rate model (each kit's combo and signature run side by side) and three packaging gaps. The pass was redone with one action at a time, as `FightService` runs it, and its paste and evaluation come from one file.

**Labels:**
- OBSERVED: a measurement of today's code.
- MODEL: a simulation of play. It's not play: passives such as Pip's and Lyric's skips and Kirra's Opener, the lead's area hits and movement are left out.
- DESIGN: the proposal.

**Where things are:**
- Scripts: `build/scratch/quaestor/` (`review_formula/`, `cr_design/`, `enemies/`, `attr5/`, `integrate/`, `verify/`).
- The changes, ready to diff: `build/scratch/quaestor/integrate/out/`.
  - `integration.patch` against `src/shared`, and `server.patch`.
  - `shared/` copies of `Rules/{Stats,Hit,Hud}` and `Config/{Stats,Enemies,Hud,Chests,Growth}`.
  - `cases_draft.luau`: 206 checks, passing.
  - The evaluation tables.

## What works (OBSERVED)

- **Defence.** It's a hyperbola, `D/(D + K·G)`: each point adds the same effective health until the 75% cap, which no launch build reaches.
- **The ratings** compare mine against theirs.
- **Same-level fights** are identical at levels 1, 30, 60 and 125: Rook kills an even foe in 4.96 s at each.
- **Smaller pieces:**
  - Type advantage, +25% and −15%.
  - The 2.0 damage bonus cap, never reached.
  - Regen: a burst is 1.8 to 5.5% of the bar. Faber's "Watt can't die" ran on Watt's plot, under the home heal.

## What doesn't (OBSERVED)

1. **A hidden level bonus.** Five of the six chance terms read the wrong fighter's level (`Hit.luau:59-68, 113`). Every one favours the higher side.
   - Kirra at 30 against the Lamplighter at 20 crits 36.8% instead of 31.2%. The keeper's Defence stops 12.3% instead of 19.6%.
   - At a 10-level gap, Rook's cost per kill is 28 to 49% worse than the stats alone make it.
   - It breaks "a higher level gets no bonus", and the sheet's percentages aren't the fighter's own.
2. **Combat Power can't compare a Voidkin with a Shade, or two ways of spending gear.** It's a weighted sum, so a Shade's large Health and weak Attack inflate its CR.
   - In 1,890 PvE pairs, the higher CR lost 1,003 times. The ratio was off from the fight's cost by ×4.6 at the median.
   - With one extra budget spent two ways, it picked the better build 57% of the time. The bag's arrows and the comparison panel stand on that.
3. **The enemies were authored against a bare Common Warrior** (TR25) and never retuned for gear. With a Lantern Row set, the keeper costs 30% of the bar instead of 79%, an elite 15% instead of 40%, an ordinary 3%.
   - **The other way (MODEL):** since stages, a quota of 10 means three pack rounds with only Regen between them. A pack swings together, because hitting one Shade turns its whole pack on the lead (`FightService`, `packHit`). A pack of four costs about ten times one Shade.
   - **The levels outrun the lead:** the first Normal clear takes the lead from 1 to 3 while the foes go from 1 to 9.
4. **Half the player's stats do nothing in PvE.** Ordinaries and Elites have Health, Attack and Defence only, and the keeper adds Dodge, Block and the resists.
   - No foe has Hit, Critical or an element. So Critical Resist, Elemental Resist, Critical Immunity and Watt's Insulated buy nothing.
   - Penetration gives +1.4 to 4.6% per 100 CR, against Attack's +19 to 32%, since Shade Defence stops only 21%.
5. **Block's cut depends on other effects.** A block adds 0.5 inside the 0.7 reduction cap: 50% alone, 62% beside Second Wind, 0% at the cap.
6. **Lifesteal is computed but never applied in a fight.** The planned cap of 0.8% of max health a second would leave 85% of the stat's range dead.
7. **Kindle's fire is a share of the physical hit.** So it crits and goes through Defence, against `docs/balance.md`, "One hit", item 6.
8. **No ratio of two CRs can see the level gap,** so the skulls need their own measure.

## The proposal (DESIGN, with MODEL results)

1. **Each rating against its owner's level** (`Hit.Odds`).
   - Defence, Block, Dodge and Elemental Resist read the defender's level. Critical and Penetration read the attacker's.
   - A same-level hit is unchanged, to 2e-16. Only a block under another reduction moves (item 2).
   - **The level gap is then the director's rule alone.** A lower attacker deals, by levels below: 3, ×0.85; 4, ×0.72; 5, ×0.61; 6, ×0.52; 8, ×0.38; 10, ×0.27; 12, ×0.20; 16, ×0.10; 20 or more, ×0.05. A higher attacker gets nothing.
2. **A block halves what's left,** outside the reduction cap. It's always worth the same.
3. **Lifesteal is wired:** heal = Lifesteal × min(damage, 8% of max health a second), with the stat capped at 10%. Every point counts.
4. **Kindle's fire takes the elemental path:** past Defence, never critical, only with an element. `FightService`'s old add (886-890) goes, so it can't count twice.
5. **The Shades fight back with every stat** (per G):
   - **Every Kind:** Defence 70.
   - **Ordinary:** 0.75 of the even foe's ratings (Hit 57, Dodge 31, Critical 47, Block 31), Critical Damage 0.5, and a quarter of its Attack as Void.
   - **Elite:** the even foe's ratings, Critical Damage 0.75, Void 0.25.
   - **Keeper:** the even foe's full row, Critical Damage 1.0, and 0.35 of its Attack as Fire.
   - Every player stat now meets something it acts on. Its worth per 100 CR, against Attack's 1.0: Critical 0.50 to 1.18, Dodge 0.70 to 1.11, Block 0.38 to 1.13, Defence 0.65 to 1.07, Hit 0.45 to 0.69, Penetration 0.35 to 0.71, Elemental Resist 0.25 to 0.78, Critical Resist 0.14 to 0.32. Critical Resist is the one still to watch.
6. **The Shades re-authored against the build a player has** at each stage's first play, from the loot pace.
   - **Per G (Health, Attack):** Ordinary 660 and 0.9, Elite 1800 and 3.4, Keeper 6050 and 3.15.
   - **Hard lifts (Health and Attack):** Ordinary ×1.6 and ×1.6, Elite ×2.05 and ×1.5, Keeper ×1.7 and ×1.2.
   - **Stage factors on Attack:** Normal stage 1 ×0.8, Normal stage 3 ×1.2, Hard stage 1 ×0.8. They're read by one function, `Stats.Enemy(def, level, difficulty, stage)`.
   - **The lead's first levels come faster:** `Growth.Early = {2, 4, 6, 8, 10, 12, 14}`. The first clear meets the keeper at level 7, inside the gap's free band.
   - **The lowest health in each stage, at the expected build:** Normal 66, 67, 49 and 40%; Hard 27, 26, 32 and 27%.
   - **Times to kill:**
     - On Normal: an Ordinary 3.6 to 5.5 s, an Elite 10 to 16 s, the keeper 45 s.
     - On Hard: 4.7 to 6.0 s, 17 to 22 s, and 61 s.
   - **The weak builds:**
     - A bare lead feels Normal (66, 52, 21, 4%) and can't do Hard.
     - A lead three levels under the expected one falls in Normal 3 and 4.
     - On Hard 4, Kirra and Pip fall at the expected build. That's a class gap to watch, since their skips and Opener aren't modelled.
7. **Combat Power measures the fight:** `CR = 3.431 × sqrt(effective health × damage a second)`.
   - Both are taken against an even foe at the fighter's own level, at the kit's real rate (one action at a time), with Regen and Lifesteal counted. It's closed form, about 7 µs a call.
   - Watt at level 8 reads about where it does today, and the Shades read under the leads that beat them.
   - **Same-level duels:** the higher CR wins 94.6% of the time, and 100% without a type edge.
   - **With one extra budget spent two ways,** it picks the better build in every duel and in 90% of Elite fights.
   - Every stat raises it, and a level's step follows G's.
   - **The comparison panel** shows the true CR change, from the resolver run twice. A breakdown by source is scaled to sum to it.
   - **Gear-line prices** are its gains at a fixed reference body (`Power.Reference`), so `PowerPerG` keeps its meaning.
8. **The skull reads the fight itself:** the share of the lead's bar one fight against this foe takes, with Regen and the level gap.
   - **Cuts:** grey under 0.15 (a scratch), white under 0.5 (a fight), yellow under 1.0 (a hard fight), red from 1.0 (you'd lose).
   - A foe at the lead's level or above is never grey, which keeps the director's order: same level white.
   - **MODEL:** the winner is called wrong in 3 of 1,890 pairs, and every loss reads red. Today's ratio is wrong in 1,003.
9. **The five attributes** are fitted under all of the above. Every class holds a real share, 12% or more, in each.

**What it doesn't reach:**
- The class-against-class edges move by up to 0.046 (target 0.03).
- An Assassin's or Mage's Agility is worth 0.46 of the Main (band 0.6 to 0.8).
- The Tank's and Mage's level-1 Health is 88 to 89% of today's.
- **Across 3 to 12 levels,** CR picks the duel winner 85% of the time. The skull is what reads a gap.
- **Regen** is worth 4 to 14 times its price over a whole stage, since one fight's CR can't see the healing between packs. No gear gives Regen, so only the shown number is low.

**The one playtest owed first:** a new account through Stage 1, as it stands today. The model says its packs are lethal, but the model swings the whole pack at once and leaves out the lead's area hits.

## For the director: the decisions

Each is a restatement: what changes, what it replaces, what it touches. Nothing is built before the yes.

1. **Levels count only through your rule.**
   - **What changes:** every hit chance and Defence reads its owner's level, so a higher level gets no hidden bonus, and your 0.85 rule is the whole gap.
   - **It replaces:** the mixed levels in `Hit.Odds`.
   - **It touches:** fights across levels, and the sheet's percentages, which become the Voidkin's own.
2. **Combat Power becomes a measure of the fight, and the skulls read the fight's cost.**
   - **It replaces:** the weighted sum and the CR ratio's cuts.
   - **It touches:** every CR shown, the bag's arrows, the comparison panel, gear prices, and the recommended power.
3. **The Shades get every stat, and are re-authored for the gear players have.**
   - **What changes:** Hit, Critical, Dodge, Block, an element and Defence 70; new Health and Attack; Hard's own lifts; faster first levels.
   - **It replaces:** TR25's numbers against a bare Warrior.
   - **It touches:** every fight in Lantern Row and the Tower.
4. **Block, Lifesteal and Kindle fixed** as above. It touches those three only.
5. **Spirit also gives Health.**
   - **Your words:** Regen, Critical Resist, Elemental Resist.
   - **With only those,** Spirit is worth 0.26 to 0.38 of a class's Main: a weak jewel and a weak choice. Level-1 Health falls to 79%.
   - **With Health added,** it's 0.47 to 0.54, and Health holds.
   - Research recommends adding Health.
6. **Every Voidkin gets an element.**
   - **The finding:** 10 of the 31 have none, and Intelligence (element and Penetration) is worth 0.08 to 0.15 of the Main to them, a dead blue jewel.
   - **With an element each,** it's worth 0.55 to 0.79.
   - **The alternative fails:** an Attack share in Intelligence lifts them only to 0.42, and makes Intelligence beat an elemental Healer's own Main.
   - It touches the roster: each needs an element that fits its look and kit.
