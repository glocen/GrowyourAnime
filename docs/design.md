# Design

The systems of Grow your Anime, as they stand. Research's design of 2026-11-11, from the director's production package (`docs/archive/package-v13/`) and the director's words (`docs/decisions.md`). Where this page and the package differ, this page is the design and `docs/decisions.md`, "What changed from the package", says why.

**Status:** designed on paper. Nothing here is built. The numbers are in `docs/balance.md` and `tools/balance/seeds.json`, never here.

Marks: **[D]** the director's: their own words, or a choice the package records as theirs. Everything unmarked is research's design, open to change at its blockout.

## Words

| Word | What it is |
|---|---|
| Voidkin | the fighters. Each is an original character [D] |
| Void Shard | what's broken open to uncover a Voidkin [D] |
| Void Breaker | the machine in the base that breaks shards [D] |
| Lead | the one Voidkin that fights beside the player |
| Worker | a Voidkin placed in an extraction bay |
| Champion | the one Voidkin sent to the Clash Grounds |
| Extraction bay | a work station in the base. Six at most [D] |
| Electricity | what bays make and the Breaker uses [D] |
| Regalia | the account's gear: fourteen slots, worn by whichever Voidkin fights |
| Festival of Battles | the grounds where the lead fights [D] |
| Keeper | the boss at the end of a ground |
| Shade | the enemies (`docs/roster.md`) |
| The Strip | the shared space between the eight bases: the Void Shop, the Clash Grounds, the Calamity [D] |

## The loop

Break a shard, meet a Voidkin. Lead with one, fight through a ground, win shards, gear and stones. Put others to work for electricity. Spend what the fights gave on Regalia. Beat the keeper, open the next ground, find rarer shards. The base keeps working while the player is away [D].

## Voidkin

- **Thirty-one at launch,** in `docs/roster.md`. Rarities at launch: Common to Mythical. Limited and the tiers above Mythical come in updates (`docs/decisions.md`, D05).
- **Type** is what it beats, five in a ring [D]: Agility beats Strength, Strength beats Endurance, Endurance beats Intelligence, Intelligence beats Technique, Technique beats Agility. An edge, never a verdict (`docs/balance.md`, "Type").
- **Class** is how it fights [D: each Voidkin has a class]. Class and type are separate: any type can be any class, so a counter never dictates a role.

| Class | Range | What it's for | Its tell |
|---|---|---|---|
| Warrior | melee | steady damage, no weakness | the plain combo, done well |
| Tank | melee | takes hits, holds enemies on itself | a guard or a taunt in its kit |
| Assassin | melee | bursts one target, picks the weak | opens with a dash |
| Mage | ranged | hits areas, often with an element | stands back |
| Healer | ranged | keeps itself up alone, keeps others up in a group | heals in its signature |

- **Element** (Fire, Frost, Storm, Void) is optional. A Voidkin with one deals a second, coloured damage number [D: elemental damage with its own number].
- **A kit** is a basic combo (two families: the melee three-hit and the ranged three-shot, with stance and tempo of its own), one **signature** on a cooldown, and one **passive**. The signature fires by itself, with a readout the player can watch. Firing it by hand is a later option (`docs/polish-later.md`).
- **Bodies.** No height stat [D]. Humanoid Voidkin stand at the R6 player's height, on the shared R6 rig [D]. Machines and other large bodies use a custom rig and stand taller [D]. Size is a look: the hurtbox comes from a small set of size classes, so a big body is never a free weakness.
- **Its own progress:** level (from fighting, working or training, up to 125 [D]), stars (from duplicates), a nickname the player may give it [D], favourite and lock.
- **Skill points: later, in a skill tree** [D, 2026-11-14, night: "1 level = 1 skill points and with this they can upgrade their stats except some that would be to busted"; then, at the board's take, "we are not doing this stats points increased like this!" and "Remove now, tree later"]. Not in the game now: a Voidkin's stats come from its level, stars and gear. Skill points return inside the skill tree, designed when it's built. Already settled for it: never Dodge, Block, Damage Reduction or Damage Bonus [D], nor Critical Damage or Speed (research's). The stat board's rule and save are kept in git (TR15).
- **Speed** [D, 2026-11-14, night: "a new type of stats which is speed (walk speed) for now with all these units it all the same"; by class with a nudge per Voidkin]. A lead's walk speed in a fight, closing on and moving between targets. Seeds, tier 2, research's: Tank 14, Warrior, Mage and Healer 16, Assassin 19 studs a second; each Voidkin's own entry may move its class's figure by 1 either way (Kirra +1). Never from skill points or gear. Following the avatar, a lead keeps up whatever its Speed (the catch-up stays).
- **Stars** [D: the director's idea, 2026-11-12]. A duplicate isn't a second copy: it waits on its Voidkin as a copy to spend. The player spends them by hand on the next star, zero to seven, at any level, and sees the gain before taking it. Each star costs twice the one before: 1, 2, 4, up to 64 copies for the seventh (the counts in the seeds). Each star is a fixed small gain, not game changing [D]. A Common reaches seven stars where a Mythical never will, and that's the point: the Common gets something the Mythical can't. Past seven, a copy sells for Credits.
- **Evolution.** One at launch, Rook's, to prove the idea: the same character further along, with a changed look and a stronger signature. More follow only if the first is worth its cost.
  - **Open, for when evolution is built** [D, 2026-11-14, night: "evolution isnt for now ... just let remember about this"]: how stars carry through an evolution. Research's take for then: the evolved form is the same entry in the collection, so it keeps its stars, and copies of either form feed them.
- **Roles.** A Voidkin is the lead, a worker, the champion, or resting. One role at a time. Each role earns its own experience, and a lead far below the account's best levels faster (`docs/balance.md`, "Catch-up").

## Combat

Real time, in the world, automatic [D: one automatic combat lead].

- **The lead owns the fight.** It has the health and the hurtbox. The player's avatar is never a target and never deals damage.
- **The player steers by standing.** The lead fights what's near the avatar, within a leash of about 30 studs. Walking away calls it back. Enemies left alone reset.
- **A ranged lead keeps its distance: the skip back** [research, 2026-11-13, tier 2, from the director's question; the director: "we need to make it right and balanced and not awkward"]. A Mage or Healer lead doesn't stand and shoot point-blank. It's an action of its own, built through `/ga-action`; the numbers below are seeds, tuned live in the replay.
  - **When:** an enemy is inside Close studs of it (seed 5: a Shade's swing reaches 4), it's between actions, and its last skip was at least Every seconds ago (seed 4). Never during an action of its own, and never while an enemy's swing at it is winding up, so a skip never dodges a hit already coming: it only spends time, the lead's and the enemy's.
  - **Where:** back to its place in the frame (`Lead.Frame`), at its action's range from its target, so it lands where the camera already wants it. If that spot is off the ground, inside a wall or a stall, past the leash, or beside another enemy, it takes the nearest clear spot at the same range. When none is clear (cornered or surrounded) it doesn't skip: it fights where it stands.
  - **How it looks:** one quick skip, not a walk. About 0.35 s, still facing its target, feet just off the ground, landing into its next action, which may start on the landing. No moonwalk, no jitter: after a skip it fires from where it lands while its target is within range, and doesn't walk in again.
  - **Why it's fair:** a skip costs the lead its 0.35 s, and costs the enemy the walk back in (about 0.5 s for a Shade at 12 studs a second). Neither side wins time on one enemy. The class numbers already price a ranged lead as hit like a melee one (a Mage's health 0.9, defence 0.85), and the skip keeps that true. Measured, not argued: the balance check below.
  - **The balance check,** in the replay: Pip and Lyric against Lantern Row's first pack at their level, ten runs with the skip and ten without. Damage taken and time to clear each stay within 10% between the two, and neither lead falls more often. If the skip helps more, Every goes up; if it costs more, Close comes down.
  - **Its signature** is drawn for its own distance (Pip's lantern flies 12 studs), so the skip is also what keeps it landing where it's drawn.
  - **The clip:** a block clip for the robe set (Pip and Lyric), Modulo's, made while TR7's framing is built so the skip's blockout is judged on a real move; its finish at the shared finish (research, 2026-11-13, tier 1). The open set's ranged Voidkin get theirs when the first one is made.
- **The camera is the player's** [D, 2026-11-14, night: "simply do not touch player camera"]. The game never eases or moves it in a fight. The lead's place in the frame (`Lead.Frame`, `Lead.Beside`, the keeper's `Turn`) keeps the fight clear of the avatar. Two touches stay by the director's word: a short shake on a heavy hit, and the turn behind the avatar inside a move's black fade.
- **Spectate** [D, 2026-11-14]: a small button on the HUD, a toggle, never a setting. On, the camera follows the lead, the player's drag and zoom working as ever; off, or when the lead falls, it's back on the avatar. Its place: `docs/ui.md`.
- **Health carries** [D, 2026-11-14, night]. Nothing heals a lead quickly after a fight, so each pack leaves its mark and the player chooses: one more pack, or home.
  - **Regen:** a lead heals a fixed number of health a second, always, in a fight too. A value, never a share of its health, from its level and its gear (a Regalia stat), so it grows with the account. A Healer's class carries more. Its seeds are set through the simulation (`docs/test-requests.md`, TR12).
  - **At home:** on its plot, a lead heals to full in about 30 s (seed).
- **A fall sends it home** [D, 2026-11-14, night; it replaces D02's quick return]. A lead that falls leaves as light (never a body left lying) and is home on its plot. There it heals slowly to full (seed: about 90 s), then waits. It follows the player again once the player is back at the base. While it's home without the player it trains (`The base`, "The Training machine"). A fall in a keeper's ring ends the try, and costs nothing else.
- **The next lead** [D, 2026-11-14, night]: once the lead has fallen, the player may send out another Voidkin they own at once, anywhere out of combat. The fall ends the fight for the player. A fallen lead can't be sent out again until it's healed. Its card shows it's healing at home, with the time left.
- **Bosses are a decision.** A keeper is fought in its own ring. Lead and Regalia are frozen from the first hit to the end. Losing costs nothing but the try.
- **Changing things mid-fight.** Lead and Regalia can't change while in combat. Out of combat, a gear change keeps the lead's health as a share of its new maximum.
- **Auto-farming while connected is allowed.** A player who parks beside enemies and watches is playing the game as designed.
- **Fights can be long** [D]: nothing ends a fight early. Two hard-to-kill builds may trade for minutes, and that's the build system working.
- **No gore** (`AGENTS.md`, rule 4): Shades burst into light and paper, Voidkin kneel and fade.

### States in a fight

[D: "stagger, heavy stagger, stun etc.", the director, 2026-11-12.] One ladder for everyone who fights: Voidkin, Shades and keepers alike. Each state has its own cue, readable at phone size, made of light, dust and shapes, never wounds.

| State | Caused by | What it does | Its cue |
|---|---|---|---|
| Flinch | any hit | a short reaction. It never cancels an action, so two automatic fighters can't lock each other | a spark where it lands |
| Stagger | the poise bar filling | cancels the action under way; open for a moment; the bar empties | a ring that cracks around it |
| Heavy stagger | a heavy hit (marked on the action: Haymaker is the first) that fills the bar, or lands with it past half | a longer stagger, knocked back. A signature being wound up is broken, and its cooldown starts over | thrown back in a burst of dust |
| Stun | only an action that says so | can't act or move for its time | sparks circling the head |
| Knockdown | a launcher or a kit's finisher that says so | down and up; can't be hit while rising | dust where it lands |
| Burn (Fire) | Fire hits | part of the Fire damage arrives over a few seconds | embers |
| Chill, then Freeze (Frost) | Frost hits add chill; full chill freezes | chill slows actions and movement; a freeze is a stun inside ice | frost creeping, then a shell of ice |
| Shock (Storm) | Storm hits | the next hits fill its poise bar faster | crackling light |
| Sap (Void) | Void hits | it heals less for a few seconds | dark motes |

- **Poise.** Every fighter has a poise bar that fills from hits and drains when it's left alone. Class sets its size: a Tank's is the largest, an Assassin's the smallest. An elite's and a keeper's bar sits on the target's card. Filling it is the fight's payoff: a heavy stagger and a window to hit hard.
- **Elites and keepers** don't flinch, and a stun or a freeze lasts half as long on them.
- **No lock.** After a stun or a freeze, a fighter can't be stunned or frozen again for a while. A long fight between two automatic builds stays a fight.
- **Nothing on top.** A state changes timing, movement or healing. An element's effect is paid out of that element's own damage (`docs/balance.md`, "One damage order"), so nothing is added on top and no stat is multiplied.
- **A signature names its state** in its roster row when it has one: Rill's Cold Snap freezes, Ashen's Last Ember burns, Rook's Haymaker is heavy.
- **The numbers** are the builder's, in Config, starting from `handbook/feel/combat.md` ("Hitstun, stagger and chains") and tuned by playing.
- **When:** TR2 keeps its block, with a flinch and a down-and-up. The states join with the Lamplighter as a real fight, where poise first matters. Reactions are one shared clip set per rig (R6, the Shade's), not one per Voidkin, and R6 has two: open legs and long robes. A leg inside a robe stays within 25 degrees of the torso, so the open set's falls come out of the hem. The robe set is Pip's Hit, Down and Up, and Cinder, Halcyon, Crane, Umbriel and Lyric (her jacket's tail) wear it too. A Voidkin's definition names its set. A prop on its own joint (Pip's hat and lantern) is keyed in the clip that made it; on another body, the prop's joint has no track and follows by its spring [research, 2026-11-12, tier 2: `docs/asset-requests.md`, AR4, section 3].

## Shards and the Void Breaker

- **Three grades** [D]: Standard (breaks in about half a minute [D]), Enriched, Prismatic. A **Named** shard holds one stated Voidkin, never a roll.
- **Shards belong to a ground.** A shard holds Voidkin of that ground and earlier ones, with the ground's own and the one before it featured. Each ground has a headliner (`docs/roster.md`, the Zone column).
- **Odds are shown** on every shard, per Voidkin, before it's broken (`docs/roblox-rules.md`).
- **Chambers.** The Breaker has two chambers at the start and up to four. Each breaks one shard at a time. Behind them is a waiting line, fed shortest first unless the player reorders it. Taking a shard out keeps the work done on it.
- **Breaking draws power** ("The base", "Power"). With less than its rated power, the Breaker slows in proportion; it never stops dead and never loses a shard.
- **Infusion.** Stored energy from the battery put into one shard lifts the odds of its two highest tiers, at Low voltage or High voltage [D, 2026-11-15: "let use real electrician words"]. The price is the same whatever the shard, so it belongs on the rare ones. Not offered on Named shards. Luck from every source adds into one number with one ceiling [D: luck never comes from the Rift].
- **The Breaker works while the player is away,** as far as the battery lasts.
- **The reveal** is the game's signature moment: the shard cracks along its own lines, the silhouette shows before the colours, then the name. Rarer is longer and louder, never slower to skip.

## The base

Eight bases in two rows, a Tower behind each [D]. A plot is given at join and the base itself is saved on the account.

- **Extraction bays:** up to six [D], opened by the base's level. A worker's output comes from its aptitude and its level, and the bay's own level adds to it.
- **Power: the base is a power plant** [D, 2026-11-14, night: "not showing electricity "600" but power generation 30Kw, power demand 30Kw ... with generator output control to slide a scroll bar horizontal and select where to spend this power ... the more power the highest effects it has the less power the less effects/speed"; "Yes, as restated" to research's restatement]. Tier 3, the director's.
  - **Generation:** the bays generate power, in kW, the sum of their workers' output. It's shown as power, never as a stock: "Generation 30 kW · Demand 34 kW".
  - **Demand:** each machine that works draws power up to its rated kW: the Breaker, the Stone Condenser and the Training machine. A machine's level raises its rating and its full speed together.
  - **The generator:** one large machine in the world, the plant's heart, showing generation and demand on its own face at the scale of the base. It opens the Power screen.
  - **The Power screen:** one horizontal bar is the whole generation, split among the machines by dragging its handles, with +/- on each share for a precise touch. Auto is the default and shares by demand. A machine runs at its share over its rating, up to full speed, and never stops dead.
  - **What isn't routed charges the battery,** in kWh. The battery covers routed demand above generation, while the player is away too, and pays for infusion.
  - **The HUD** shows generation against demand, not a stored number.
  - **When it shows:** the Power screen opens once the base has a second machine drawing power. Until then, Auto runs it unseen.
  - **The numbers** (ratings, kW per worker, the battery's kWh, infusion's price) are seeds, set with the simulation before the build.
- **Upgrades: the base and each machine** [D, 2026-11-12: "the whole base can be upgrade it cost a lot, the machines too"]. Both cost a lot, in Credits, the game's largest sink. Research's design of what they give:
  - **The base's level** opens the next bay, raises the ceiling every machine can reach (a machine never passes its base), and changes how the base looks: it grows across its 200 studs, so a visitor reads a base's level at a glance.
  - **A machine's level** raises its own work: the Breaker its speed, then its third and fourth chambers; a bay its output; the Condenser its rate, its grade and its tray; the Forge and the Lab their later uses.
  - Each level shows its gain before it's bought, in plain numbers, and the machine changes in the world when it lands.
- **The battery** stores what isn't routed ("Power"), to a cap, and is what keeps the base working while the player is away. Past the cap, the overflow sells itself into Credits at a poor rate, so nothing is thrown away. Its cap rises with the base's level, never by an upgrade of its own, so there is no choice to keep it small for the overflow (the director's question, 2026-11-12). The screen shows the cap as the hours of work it holds, not a number of units. Electricity is always worth more spent than sold: a full battery's overflow is a few kills' Credits.
- **Machines:** the Void Breaker, the Forge, the Stone Condenser, the Research Lab [D]. Each is a place to walk to, with its own sound.
- **The Stone Condenser makes forge stones, online and away** [D, 2026-11-12: "a machine at base that produce stones ... it will work offlines making players come back and get very strong"]. It draws electricity like the Breaker, so the workers feed it too (research's). What it makes lands in its tray, which has a cap: a full tray stops, and coming back to empty it is the reason to return. Its grade and speed rise with its level. Turning lower stones into higher ones stays its second job. Stones still drop from enemies, keepers and the Tower [D]. More uses come later [D: "for now only this"].
- **The Training machine** [D, 2026-11-14, night: "the voidkin that we equipped train with a machine and get level (even offline)"]. It trains one Voidkin at a time: the one at home without the player, a fallen lead once it's healed, or the player's lead while the player is offline. When the player is on the plot, the lead leaves it and follows. At its full power it earns a fixed amount of experience a minute that never grows: a third of what fighting earns in Lantern Row (seed, through the simulation). With less power it trains slower, in proportion ("Power", below). No cap [D: "simply no cap"; "it will be slow at high level tho"; then "Fixed rate, no cap"]: each level costs more, so training is fast at the start and slows steeply as levels rise. Earning a share of fighting at its own level was tried in the simulation and reached the last level in a week. Its time away is worked out on the server at the next join, as the Breaker's and the battery's are. It draws power like every machine [D, 2026-11-14, night: "Yes, as restated" to the power plant; it replaces "it draws nothing"].
- **Room for it all** [D, 2026-11-12: bases "way bigger", since six workers in their machines take room]: the Breaker, six bays each with its Voidkin at work inside, the battery, the Forge, the Condenser, the Lab, and the Tower behind. The plot's size comes from these, set at TR2's verdict.
- **Visiting** another base is free and safe [D]: look, never touch.

## Regalia: gear

The largest change from the package, and reversible until gear is built (`docs/decisions.md`, "What changed from the package").

- **Gear belongs to the account,** not to one Voidkin. Fourteen slots [D]: Main Hand, Off Hand, Helmet, Shoulders, Chest Armor, Gloves, Bracers, Boots, Cloak, Amulet, Ring I, Ring II, Earring I, Earring II. The two hands are the two weapon slots [D, 2026-11-12]: they take the places of the package's Weapon and Shield, since the Tank's shield is its off hand.
- **Weapons belong to a class** [D]: only that class wields them. Each class has its pair:

| Class | Main Hand | Off Hand |
|---|---|---|
| Tank | Great Axe [D] | Shield [D] |
| Mage | Staff [D] | Tome [D] |
| Assassin | Dagger [D] | Throwing Blades |
| Warrior | Sword [D] | Short Sword [D: two swords] |
| Healer | Crystal Baton [D] | Codex [D: a book] |

  The pairs are final by the director's word (the Assassin's off hand is research's, taken). The Warrior's off-hand sword is shorter, so the two slots never show the same icon. Every main hand is a silhouette no other class shares. The Mage and the Healer both hold a book: the Mage's Tome is heavy and dark, the Healer's Codex light and clasped with the baton's crystal, and every weapon icon carries its class mark on the frame, so the two never read as one.
- **Presets.** A preset holds the twelve shared slots and one weapon pair for each class. One at the start, up to five. Each Voidkin is linked to a preset and fights with its own class's pair from it, so a Tank wears the tank set and an Assassin the crit set, and swapping the lead swaps nothing by hand. One item may sit in several presets. A preset whose pair is empty for the lead's class says so with a mark on the slot, never silently.
- **A weapon that drops** is for the lead's class. Five classes would otherwise split every weapon drop five ways. The Void Shop's stock may hold any class.
- **Why:** a counter system asks players to swap leads often. Gear worn per Voidkin would make every swap a chore of fourteen items and their sockets, and it would bury new Voidkin under the cost of dressing them.
- **Gear is never shown on the body** [D]: each Voidkin's look is authored. An item's whole look is its icon, so the icon carries all of gear's appeal. Each item kind is modelled in Blender and rendered to its icon, lit, with its rarity's frame and light; rarity also shows in its material, from plain iron to gilt. Dawn has designs of its own. How many designs per kind is set when the item art's request is written (`docs/asset-requests.md`, AR6), after a reference study of the director's references for what makes an icon worth wanting.
- **An item** has a rarity, a level tier, one main stat fixed by its slot, and a few rolled lines.
- **Forge ranks sit on the slot,** not the item. Raising the Main Hand strengthens whatever is held there, by every class, in every preset, for good. Replacing an item never loses the work.
- **War Emblems** go in an item's sockets: one on a Common item, two on Uncommon, three on Rare, four on Epic and above [D: four at most]. Emblems obtainable at launch are Common, Uncommon and Rare [D]. Taking one out is free, and replacing an item carries its emblems across.
- **Jewels:** one jewel socket on items of Rare and above. Jewels carry the percent stats (critical damage, critical guard, lifesteal).
- **The Stone Condenser** turns lower forge stones into higher ones. **The Research Lab** spends Research Points on permanent, flat gains: stat points and Breaker tuning. A machine's capacity (chambers, bay output) comes from its own level, and the battery's from the base's, so the two never buy the same thing.
- **Dawn** is the premium Legendary series [D]: Legendary rarity, above ordinary Legendary items [D, 2026-11-12], and the top gear of launch, earned in the last ground and the Tower. Its pieces read as one set (`docs/research/gear-icons.md`).

### Combat Power

One number for how strong the lead is with its preset, made to be watched rising [D: appealing, 2026-11-12].

- **It never lies.** It's a weighted sum of the lead's resolved stats (`docs/balance.md`, "The stats"), and the weights are fitted by the simulation so that, with no type edge, the higher Combat Power wins more often. A number players chase has to be one they can trust.
- **Every upgrade moves it.** Everything adds points, so every real gain, an emblem included, raises it by a whole, visible number, never by zero. Its scale is large, set in the seeds.
- **Where it shows.** On the Voidkin screen (Regalia's screen is merged into it, 2026-11-15), at the Voidkin's feet between the slot columns, large, so it reads as the character's own [D: where is research's choice]. The same view is what a visiting player sees of your lead.
- **The moment** [D, 2026-11-12]. When an upgrade lands, the number pops a little, the gain shows in green with a "+", and the gold counter rolls to its new value. A loss shows as a plain number down. Over the world, the gain rises beside the lead's card for a second, then the HUD is quiet again.
- **The pull.** In the bag, an item that would raise it carries an up arrow; a slot with a better item waiting carries a dot. Each ground, keeper and Tower floor shows its recommended Combat Power, the player's beside it in green, amber or red.
- **Honest.** A tap on it shows how much each source gives, and the parts sum to the total (`docs/ui.md`, "Stats, shown honestly").
- It's for reading, matchmaking and the Clash's rewards, and never used to compute damage.

## The Festival of Battles

Six grounds at launch (`docs/roster.md`), each a recolour and rearrangement of one festival kit. A ground has ordinary Shades, elites, one keeper, and a gate. Beating the keeper opens the next ground for good, and a shortcut gate back to the base [D].

- **Keepers are fought alone.** Everyone gets their own fight, so nobody is carried and nobody waits.
- **Fighting together** happens at elites, which anyone near may join, and at the Calamity.
- **Each ground leans on two types,** so a second and a third lead are worth raising.

## The Strip

- **The Void Shop** [D]: stock changes every five minutes, the same in every server, with a limit per player. It sells for Credits: shards, stones, emblems. The rare offer is the reason to look up at the clock.
- **The Void Rift** [D]: a short burst on a schedule, the same everywhere. While it's open, the Breakers of everyone online run many times faster. Speed only, never luck [D].
- **The Calamity** [D]: a great boss that arrives on a schedule in each server. Everyone who does a minimum share of the damage is rewarded, the top three most [D]. One claim per arrival per account.
- **The Clash Grounds** (the director's Void Clash [D]): an arena where every player may station one champion. Champions fight each other on their own, all day, in the open, and the players watch. Beating another champion pays the winner's owner: Credits and progress on a daily track [D: rewards when their Voidkin beats another]. A stronger champion beating a far weaker one earns little, and the same pair pays only so often. A beaten champion goes home and can be sent again after a short wait. Echoes, server-run stand-ins, keep the arena busy when few players have a champion out. The server's best champion wears a crown.

## The Tower

Behind each base [D]. Floor after floor of authored opponents at launch, fought with a line-up of three, where class finally matters to a solo player: a Tank to hold, a Healer to keep, a third to finish. First clears pay. Other players' saved teams as floor holders [D] follow in an update, on the same contract.

## The world, in grey

Research's layout for TR2, 2026-11-12. The builder installs it in grey; how it looks comes later with the festival kit (AR5). Times are the design. Studs are worked out at Roblox's default walk of 16 studs a second (R6 stands 5), so if Config changes the walk, the studs move and the times hold. Once the numbers are in Config, Config is their home.

```
              [Tower][Tower]    gate    [Tower][Tower]
              [ P1 ] [ P2 ]      ||      [ P3 ] [ P4 ]
   Calamity ═══════════════ the Strip ═══╬═══════════════ Clash Grounds
              [ P5 ] [ P6 ]     Shop     [ P7 ] [ P8 ]
              [Tower][Tower]            [Tower][Tower]
```

- **Eight plots, two rows of four, facing each other across the Strip** [D: eight bases, a Tower behind each]. A plot is 200 studs square [D, 2026-11-12] and opens onto the Strip; the Festival Door takes its walk to the grounds. The Breaker stands at its front, so a passer-by sees the shards cracking. The bays line its sides, and the battery sits between them. Its back is kept for the Forge, the Lab and the Condenser, with the Tower behind that (phase 3; TR2 leaves the space). Neighbours stand 48 studs apart (TR2's verdict).
- **The Strip** is 3 s wide (48 studs). It breaks at its middle into a crossing one plot wide. North of the crossing a side street runs out between the Towers to the **festival gate**. South of it stands **the Shop**: every trip out and back passes the clock. The Strip's two ends are kept for the Calamity and the Clash Grounds (phase 5).
- **From the front of any plot to the first Shade: 20 s at most,** about 14 s from the nearest. That's 10 s at most to the crossing, 8 s up the side street past the plots and Towers to the gate, and 2 s past it to the first pack, which can be seen from the gate.
- **Lantern Row** is one street, 44 studs wide between the stall fronts (TR2's verdict, on the director's word), in one rhythm: three packs, the elite's square, three packs, the keeper's gate, one pack spacing apart each. Its length follows the spacing: about 37 s on foot at 80 studs (about 590 studs), so tuning one number keeps the rhythm (the builder's read, 2026-11-12).
  - **Six packs** of three Brawler Shades, 80 studs apart, past the lead's 30-stud leash, so the lead takes one pack at a time and the player chooses when to step on.
  - **A pack belongs to everyone.** Every player whose lead hit one of its Shades gets that Shade's drop in full, as at the elite. Nobody walks past a fight they can't join, and nobody steals a kill. A pack comes back a set time after its last Shade falls (Config). That wait is also what limits how much faster a group earns than a player alone.
  - **The elite** stands in a square at the street's middle, 4 s across (64 studs), so anyone near can join (design, "The Festival of Battles").
  - **At the far end, the keeper's gate,** and behind it **the Lamplighter's ring** (80 studs across). Every player gets their own fight; how is the builder's call.
  - **Beyond the ring:** Drum Court's gate, shut, in view. Beside it, the **shortcut home**, opened by the first win: in grey, a pad that sets the player down at their own plot.
- **The Festival Door** [D, 2026-11-12: "a door or something at the base to teleport to zones easily"]: a door on every plot that takes the player to the gate of any ground they've opened, with its twin at each gate to come home. So a plot can grow and stand apart without lengthening the trip to a fight, and the walk to the first Shade stops setting the plots' size. The Strip keeps what's worth walking to: the Shop, the Clash Grounds, the Calamity, and the other bases. Built with TR2's verdict and its numbers.
- **Arrival:** the player's spawn is on their own plot, facing the Breaker and the three shards ("The first session").
- **What the world marks** for code to read (the names and the contract are the builder's, `docs/engineering-plan.md`): each plot and its spawn, the Breaker, each bay, the battery, the festival gate, each pack's spawn, the elite's, the keeper's gate, the ring, the shortcut and its landing, the shut gate.
- **Tuned by walking, not on paper:** the walk times, pack spacing and the street's length are first guesses, judged at TR2's verdict from the player's camera.

## What the player holds

| Currency | Comes from | Goes to |
|---|---|---|
| Credits | fights, overflow electricity, copies past seven stars, the Clash | the Void Shop, forge ranks, the Condenser, the base's and machines' upgrades |
| Electricity | workers | breaking shards, infusion, the Condenser |
| Research Points | first clears, Tower floors, the daily track, the Calamity | the Research Lab |
| Forge stones, three grades | enemies by ground, keepers, the Tower, the Condenser, the shop | forge ranks |

**The bag** [D, 2026-11-12: "we will need a inventory systems"] holds everything owned that isn't a Voidkin: items, emblems, jewels, stones, shards. One screen with tabs by kind, sort and filter, a lock on anything precious, and a count of its space. Items that would raise Combat Power carry the up arrow (Combat Power, above).

Void Essence is out of launch: nothing needed it that these four don't cover (`docs/polish-later.md`).

## Out of launch

No height stat, no prestige, no player traits, clans or races [D]. Fusion, mutations and traits on Voidkin, manual signatures, parties, saved-player Tower teams, Limited Voidkin and the tiers above Mythical wait for updates. Each is a line in `docs/polish-later.md`.

## What's sold

Nothing random, and nothing that multiplies on top of another boost (`docs/balance.md`, "Earning"). The store's design is its own piece before launch, approved by the director (`docs/production-plan.md`, phase 6; `docs/roblox-rules.md`).
