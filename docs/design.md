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
- **Its own progress:** level (from fighting or working), stars (from duplicates), a nickname the player may give it [D], favourite and lock.
- **Stars** [D: the director's idea, 2026-11-12]. A duplicate isn't a second copy: it waits on its Voidkin as a copy to spend. The player spends them by hand on the next star, zero to seven, at any level, and sees the gain before taking it. Each star costs twice the one before: 1, 2, 4, up to 64 copies for the seventh (the counts in the seeds). Each star is a fixed small gain, not game changing [D]. A Common reaches seven stars where a Mythical never will, and that's the point: the Common gets something the Mythical can't. Past seven, a copy sells for Credits.
- **Evolution.** One at launch, Rook's, to prove the idea: the same character further along, with a changed look and a stronger signature. More follow only if the first is worth its cost.
- **Roles.** A Voidkin is the lead, a worker, the champion, or resting. One role at a time. Each role earns its own experience, and a lead far below the account's best levels faster (`docs/balance.md`, "Catch-up").

## Combat

Real time, in the world, automatic [D: one automatic combat lead].

- **The lead owns the fight.** It has the health and the hurtbox. The player's avatar is never a target and never deals damage.
- **The player steers by standing.** The lead fights what's near the avatar, within a leash of about 30 studs. Walking away calls it back. Enemies left alone reset.
- **Down, not out.** A lead that falls recovers at the avatar's side in a few seconds, with nothing lost. Out of a fight it heals quickly.
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
- **When:** TR2 keeps its block, with a flinch and a down-and-up. The states join with the Lamplighter as a real fight, where poise first matters. Reactions are one shared clip set per rig (R6, the Shade's), not one per Voidkin, and R6 has two: open legs and long robes. A leg inside a robe stays within 25 degrees of the torso, so the open set's falls come out of the hem. The robe set is Pip's Hit, Down and Up, and Cinder, Halcyon, Crane and Umbriel wear it too. A Voidkin's definition names its set. A prop on its own joint (Pip's hat and lantern) is keyed in the clip that made it; on another body, the prop's joint has no track and follows by its spring [research, 2026-11-12, tier 2: `docs/asset-requests.md`, AR4, section 3].

## Shards and the Void Breaker

- **Three grades** [D]: Standard (breaks in about half a minute [D]), Enriched, Prismatic. A **Named** shard holds one stated Voidkin, never a roll.
- **Shards belong to a ground.** A shard holds Voidkin of that ground and earlier ones, with the ground's own and the one before it featured. Each ground has a headliner (`docs/roster.md`, the Zone column).
- **Odds are shown** on every shard, per Voidkin, before it's broken (`docs/roblox-rules.md`).
- **Chambers.** The Breaker has two chambers at the start and up to four. Each breaks one shard at a time. Behind them is a waiting line, fed shortest first unless the player reorders it. Taking a shard out keeps the work done on it.
- **Breaking costs electricity,** paid as the work is done. Short of power, the Breaker slows in proportion; it never stops dead and never loses a shard.
- **Infusion.** Extra electricity put into one shard lifts the odds of its two highest tiers, a little or a lot. The price is the same whatever the shard, so it belongs on the rare ones. Not offered on Named shards. Luck from every source adds into one number with one ceiling [D: luck never comes from the Rift].
- **The Breaker works while the player is away,** as far as the battery lasts.
- **The reveal** is the game's signature moment: the shard cracks along its own lines, the silhouette shows before the colours, then the name. Rarer is longer and louder, never slower to skip.

## The base

Eight bases in two rows, a Tower behind each [D]. A plot is given at join and the base itself is saved on the account.

- **Extraction bays:** up to six [D], opened as the player advances. A worker's output comes from its aptitude and its level. Research adds to it.
- **The battery** stores what isn't used, to a cap. Past the cap, the overflow sells itself into Credits at a poor rate, so nothing is thrown away and hoarding is pointless.
- **Machines:** the Void Breaker, the Forge, the Stone Condenser, the Research Lab [D]. Each is a place to walk to, with its own sound.
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
| Warrior | Sword | Scabbard |
| Healer | Rod | Lantern |

  The unmarked pairs are research's, open to the director's word. Each pair is two silhouettes no other class shares, so an icon says its class before its frame is read.
- **Presets.** A preset holds the twelve shared slots and one weapon pair for each class. One at the start, up to five. Each Voidkin is linked to a preset and fights with its own class's pair from it, so a Tank wears the tank set and an Assassin the crit set, and swapping the lead swaps nothing by hand. One item may sit in several presets. A preset whose pair is empty for the lead's class says so with a mark on the slot, never silently.
- **A weapon that drops** is for the lead's class. Five classes would otherwise split every weapon drop five ways. The Void Shop's stock may hold any class.
- **Why:** a counter system asks players to swap leads often. Gear worn per Voidkin would make every swap a chore of fourteen items and their sockets, and it would bury new Voidkin under the cost of dressing them.
- **Gear is never shown on the body** [D]: each Voidkin's look is authored. An item's whole look is its icon, so the icon carries all of gear's appeal. Each item kind is modelled in Blender and rendered to its icon, lit, with its rarity's frame and light; rarity also shows in its material, from plain iron to gilt. Dawn has designs of its own. How many designs per kind is set when the item art's request is written (`docs/asset-requests.md`, AR6), after a reference study of the director's references for what makes an icon worth wanting.
- **An item** has a rarity, a level tier, one main stat fixed by its slot, and a few rolled lines.
- **Forge ranks sit on the slot,** not the item. Raising the Main Hand strengthens whatever is held there, by every class, in every preset, for good. Replacing an item never loses the work.
- **War Emblems** go in an item's sockets: one on a Common item, two on Uncommon, three on Rare, four on Epic and above [D: four at most]. Emblems obtainable at launch are Common, Uncommon and Rare [D]. Taking one out is free, and replacing an item carries its emblems across.
- **Jewels:** one jewel socket on items of Rare and above. Jewels carry the percent stats (critical damage, critical guard, lifesteal).
- **The Stone Condenser** turns lower forge stones into higher ones. **The Research Lab** spends Research Points on permanent, flat gains: stat points, bay output, battery size, a chamber, Breaker tuning.
- **Dawn** is the premium Legendary series [D]: the top gear of launch, earned in the last ground and the Tower.

### Combat Power

One number for how strong the lead is with its preset, made to be watched rising [D: appealing, 2026-11-12].

- **It never lies.** It's a weighted sum of the lead's resolved stats (`docs/balance.md`, "The stats"), and the weights are fitted by the simulation so that, with no type edge, the higher Combat Power wins more often. A number players chase has to be one they can trust.
- **Every upgrade moves it.** Everything adds points, so every real gain, an emblem included, raises it by a whole, visible number, never by zero. Its scale is large, set in the seeds.
- **The moment.** On any change, the number rolls up to its new value with a burst and a floating gain; a loss shows as a plain number down. Over the world, the gain rises beside the lead's card for a second, then the HUD is quiet again.
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

- **Eight plots, two rows of four, facing each other across the Strip** [D: eight bases, a Tower behind each]. A plot is 5 s across (80 studs) and opens onto the Strip. The Breaker stands at its front, so a passer-by sees the shards cracking. The bays line its sides, and the battery sits between them. Its back is kept for the Forge, the Lab and the Condenser, with the Tower behind that (phase 3; TR2 leaves the space). Neighbours stand a path apart (12 studs).
- **The Strip** is 3 s wide (48 studs). It breaks at its middle into a crossing one plot wide. North of the crossing a side street runs out between the Towers to the **festival gate**. South of it stands **the Shop**: every trip out and back passes the clock. The Strip's two ends are kept for the Calamity and the Clash Grounds (phase 5).
- **From the front of any plot to the first Shade: 20 s at most,** about 14 s from the nearest. That's 10 s at most to the crossing, 8 s up the side street past the plots and Towers to the gate, and 2 s past it to the first pack, which can be seen from the gate.
- **Lantern Row** is one street, 2 s wide between the stall fronts (32 studs), in one rhythm: three packs, the elite's square, three packs, the keeper's gate, one pack spacing apart each. Its length follows the spacing: about 37 s on foot at 80 studs (about 590 studs), so tuning one number keeps the rhythm (the builder's read, 2026-11-12).
  - **Six packs** of three Brawler Shades, 80 studs apart, past the lead's 30-stud leash, so the lead takes one pack at a time and the player chooses when to step on.
  - **A pack belongs to everyone.** Every player whose lead hit one of its Shades gets that Shade's drop in full, as at the elite. Nobody walks past a fight they can't join, and nobody steals a kill. A pack comes back a set time after its last Shade falls (Config). That wait is also what limits how much faster a group earns than a player alone.
  - **The elite** stands in a square at the street's middle, 4 s across (64 studs), so anyone near can join (design, "The Festival of Battles").
  - **At the far end, the keeper's gate,** and behind it **the Lamplighter's ring** (80 studs across). Every player gets their own fight; how is the builder's call.
  - **Beyond the ring:** Drum Court's gate, shut, in view. Beside it, the **shortcut home**, opened by the first win: in grey, a pad that sets the player down at their own plot.
- **Arrival:** the player's spawn is on their own plot, facing the Breaker and the three shards ("The first session").
- **What the world marks** for code to read (the names and the contract are the builder's, `docs/engineering-plan.md`): each plot and its spawn, the Breaker, each bay, the battery, the festival gate, each pack's spawn, the elite's, the keeper's gate, the ring, the shortcut and its landing, the shut gate.
- **Tuned by walking, not on paper:** the walk times, pack spacing and the street's length are first guesses, judged at TR2's verdict from the player's camera.

## What the player holds

| Currency | Comes from | Goes to |
|---|---|---|
| Credits | fights, overflow electricity, copies past seven stars, the Clash | the Void Shop, forge ranks, the Condenser |
| Electricity | workers | breaking shards, infusion |
| Research Points | first clears, Tower floors, the daily track, the Calamity | the Research Lab |
| Forge stones, three grades | enemies by ground, the shop | forge ranks |

Void Essence is out of launch: nothing needed it that these four don't cover (`docs/polish-later.md`).

## Out of launch

No height stat, no prestige, no player traits, clans or races [D]. Fusion, mutations and traits on Voidkin, manual signatures, parties, saved-player Tower teams, Limited Voidkin and the tiers above Mythical wait for updates. Each is a line in `docs/polish-later.md`.

## What's sold

Nothing random, and nothing that multiplies on top of another boost (`docs/balance.md`, "Earning"). The store's design is its own piece before launch, approved by the director (`docs/production-plan.md`, phase 6; `docs/roblox-rules.md`).
