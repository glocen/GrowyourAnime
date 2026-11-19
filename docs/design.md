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
| Regalia | the account's gear: fourteen slots, worn by whichever Voidkin fights; worn in its numbers only, a picture in its slot and nothing on the model (the director, 2026-11-15) |
| Festival of Battles | the grounds where the lead fights [D] |
| Ground | one of the Festival's places (Lantern Row is the first). Players read it as "Arc" (the director, 2026-11-19); the docs and the code say ground |
| Keeper | the boss at the end of a ground |
| Shade | the enemies (`docs/roster.md`) |
| The Strip | the shared space between the eight bases: the Void Shop, the Clash Grounds, the Calamity [D] |

## The loop

Break a shard, meet a Voidkin. Lead with one, fight through a ground, win shards, gear and stones. Put others to work for electricity. Spend what the fights gave on Regalia. Beat the keeper, open the next ground, find rarer shards. The base keeps working while the player is away [D].

## Voidkin

- **Thirty-one at launch,** in `docs/roster.md`. Rarities at launch: Common to Mythical. Limited and the tiers above Mythical come in updates (`docs/decisions.md`, D05).
- **Type** is what it beats, five in a ring [D], named by their colours [D, 2026-11-17]: Blue beats Red, Red beats Orange, Orange beats Purple, Purple beats Green, Green beats Blue. An edge, never a verdict (`docs/balance.md`, "Type").
- **Class** is how it fights [D: each Voidkin has a class]. Class and type are separate: any type can be any class, so a counter never dictates a role.

| Class | Range | What it's for | Its tell |
|---|---|---|---|
| Warrior | melee | steady damage, no weakness | the plain combo, done well |
| Tank | melee | takes hits, holds enemies on itself | a guard or a taunt in its kit |
| Assassin | melee | bursts one target, picks the weak | opens with a dash |
| Mage | ranged | hits areas, often with an element | stands back |
| Healer | ranged | keeps itself up alone, keeps others up in a group | heals in its signature |

- **Element** (Fire, Frost, Storm, Void) is optional. A Voidkin with one deals a second, coloured damage number [D: elemental damage with its own number].
- **Basic Attributes** [D, 2026-11-19, 03:10: five, one per class's Main and one per jewel colour; it replaces "Two attributes only" of 2026-11-17]:
  - **Strength** (red, the Warrior's Main): Attack and Health. **Agility** (green, the Assassin's): Critical, Dodge and Hit. **Intelligence** (blue, the Mage's): its element and Penetration. **Endurance** (yellow, the Tank's): Health, Defence and Block. **Spirit** (purple, the Healer's): Regen, Critical Resist and Elemental Resist.
  - Every point converts into Battle Attributes by its attribute's row, the same for every class. The class's **Main** converts once more by its own row, which is the class difference. The rows are research's refit (`docs/balance.md`, "The stats"); until it lands, the two-attribute rows in `Config.Stats` stand.
  - Every other Battle Attribute comes from the Main's row, the Voidkin's levels and its gear's lines, never from an attribute of its own.
  - A Voidkin's own points are its class's shape × its rarity × G(level) × its stars. Gear adds points flat. Everything adds: nothing multiplies an attribute, and Combat Power reads only the resolved Battle Attributes, so no point counts twice.
  - None are spent by hand (skill points, below). The rows and the shapes: `docs/balance.md`, "The stats". The evidence: `docs/research/rework-2026-11-16.md`, parts 1 to 3.
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
  - **Regen:** a lead heals in **one burst every 8 seconds**, always, in a fight too [D, 2026-11-17, by 12:54: "it should come in burst and have a mid CD"]. A value, never a share of its health, from its level and its gear (a Regalia stat), so it grows with the account. A Healer's class carries more. **A burst heals half what 8 seconds healed before** [D: "Half"], and **it starts very slow** [D, by 12:56: "for the beginning it must be very slow"]: the level's own part is a quarter of before, so a burst is about 1% of health at level 1 and under 2% at level 12. Strong Regen comes from the build (Endurance, a Healer's Main, gear and emblems) over the updates [D: "some players voidkin build will have strong hp regen stats and it all fine"]. A burst shows a quick pop and its number on the lead. The sheet shows the burst's size. The seeds and the 8 s are in `Config.Stats.Regen` (TR40).
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
- **Chambers.** The Breaker has two chambers at the start and up to four. Each breaks one shard at a time. Behind them is a waiting line, fed shortest first unless the player reorders it. Taking a shard out keeps the work done on it. Only a shard ever sits in a chamber, never a fighter (the content check, AR16).
- **Breaking draws power** ("The base", "Power"). With less than its rated power, the Breaker slows in proportion; it never stops dead and never loses a shard.
- **Infusion is voltage** [D, 2026-11-15: names, "let use real electrician words"; effect, "Faster break"]. Stored energy from the battery, put into one shard, breaks it faster: Low voltage halves its time left, and High voltage breaks it at once. A shard takes it once, and its odds never change. The price follows the time saved: the energy its chamber would still draw over that time, plus a premium, so it belongs on the slow shards. A shard it would save less than a minute isn't offered it (`tools/balance/seeds.json`, "voltage"). Not offered on Named shards. Luck from every source adds into one number with one ceiling [D: luck never comes from the Rift].
- **The Breaker works while the player is away,** as far as the battery lasts.
- **The reveal** is the game's signature moment: the shard cracks along its own lines, the silhouette shows before the colours, then the name. Rarer is longer and louder, never slower to skip.

## The base

Eight bases in two rows, a Tower behind each [D]. A plot is given at join and the base itself is saved on the account. A plot stays a bare lot until a player in the server owns it [D, 2026-11-15, night: "if there 3 players out of 8 only 3 base are in"]: the base is built when its player arrives and cleared when they leave.

- **Extraction bays:** up to six [D], opened by the base's level. A worker's output comes from its aptitude and its level, and the bay's own level adds to it.
- **Power: the base is a power plant** [D, 2026-11-14, night: "not showing electricity "600" but power generation 30Kw, power demand 30Kw ... with generator output control to slide a scroll bar horizontal and select where to spend this power ... the more power the highest effects it has the less power the less effects/speed"; "Yes, as restated" to research's restatement]. Tier 3, the director's.
  - **Generation:** the bays generate power, in kW, the sum of their workers' output. It's shown as power, never as a stock: "Generation 30 kW · Demand 34 kW".
  - **Demand:** each machine that works draws power up to its rated kW: the Breaker, the Stone Condenser and the Training machine. A machine's level raises its rating and its full speed together.
  - **The generator:** one large machine in the world, the plant's heart: the Void Mill, a heavy wheel turning up out of the void's well. Its buckets light up the rising side as high as the generation, against a bone mark for the demand, so the machine is its own gauge (`docs/asset-requests.md`, AR19). It opens the Power screen.
  - **The Power screen:** one horizontal bar is the whole generation, split among the machines by dragging its handles, with +/- on each share for a precise touch. Auto is the default and shares by demand. A machine runs at its share over its rating, up to full speed, and never stops dead.
  - **What isn't routed charges the battery,** in kWh. The battery covers routed demand above generation, while the player is away too, and pays for infusion.
  - **The HUD** shows generation against demand, not a stored number.
  - **When it shows:** the Power screen opens once the base has a second machine drawing power. Until then, Auto runs it unseen.
  - **The numbers** (ratings, kW per worker, the battery's kWh, infusion's price) are seeds, set with the simulation before the build.
- **Upgrades: the base and each machine** [D, 2026-11-12: "the whole base can be upgrade it cost a lot, the machines too"]. Both cost a lot, in Credits, the game's largest sink. Research's design of what they give:
  - **The base's level, 1 to 20 for now** [D, 2026-11-15, night: "let say level max for now will be level 20"]. **Launch caps it at 3** [D, the same night: "for higher levels it will require items so for the launch the cap will be level 3 it will let us take our time and deliver high quality"]. It opens bays, raises the ceiling every machine can reach (at launch 2, 6 and 30, research's seeds: `docs/balance.md`, "Earning"), raises the battery's cap, and changes how the whole base looks [D: "the whole base visuals, changed based of the levels of the base itself"].
    - **The price:** levels 2 and 3 cost Credits. Higher levels also need items [D], designed when the cap rises.
    - **The pace at launch** (seeds): level 2 in the first session, 3 at about 5 hours of play. The ladder to 20 keeps its "hundreds of hours" [D] once its items exist, and its pace is set then (`docs/balance.md`).
    - **Bays** [D, 2026-11-18, D5]: two at level 1, three at 2, four at 3, since five Voidkin with one leading staff four at most. Bays 5 and 6 stand locked, "Opens with more Voidkin". Level 3's price is refitted to its one bay (`docs/balance.md`, "Earning").
    - **The look:** at launch, levels 1, 2 and 3 each have a look of their own for the whole base and its machines, readable from the gate. Its look as it stands in the game is kept [D, 2026-11-15, about 23:28: "that graphism was perfect"], with the toon outline on every machine and a bit more anime in small touches [D, the word after]. Three machines are reworked as void machines: the Void Breaker, the bays, and the generator, a lot bigger and still turning [D, 2026-11-15, 23:44 to 23:58]. It's spread across the whole plot with an open way in from the gate, less cluttered, the generator turning in view, and never a building site (`docs/asset-requests.md`, AR16). The levels past 3 get theirs when the cap rises. The base's level stands on its gate (`docs/asset-requests.md`, AR14). No mist in the base and the map around it, and less somber in every phase [D, 2026-11-16, 16:50]: a light world with the void as its one dark (`docs/asset-requests.md`, AR20).
    - **Where it's bought:** the base screen (`docs/ui.md`, 7).
    - **The base shows off its owner** [D, 2026-11-15, about 22:04, to Modulo: "dont forget the base need to show of each players etc"]. At launch, by research's call (tier 2; TR22), a passer-by on the Strip sees three things. The gate's plate carries the owner's name and the base's level. The showcase, research's idea brought into launch, is a lit plinth just inside the gate: a Voidkin the player picks stands on it, turning, with its Combat Power, and it's their strongest until they pick one. Each working bay is lit in its worker's rarity colour. A tap on the plinth to see that Voidkin as a visitor comes later.
  - **A machine's level** raises its own work (the Training machine has none, since its rate is fixed [D]): the Breaker its speed, then its third and fourth chambers; a bay its output; the Condenser its rate, its grade and its tray; the Forge and the Lab their later uses.
  - Each level shows its gain before it's bought, in plain numbers, and the machine changes in the world when it lands.
  - **Three stages for every machine** [D, 2026-11-16: the package's point 6]: Stage I, Primitive, at machine levels 1 to 5; Stage II, Developed, 6 to 14; Stage III, Advanced, 15 and up (research's thresholds). Each stage lands as a moment, the machine changing in the world. They're void machines built from parts you can read (gears, pistons, cables, clamps) doing void work, never a real power plant [D: the yes's reading of "anime-industrial"]. The generator first, then the Breaker, the bays, the battery and the Training machine, then the rest. **The generator has no level of its own:** it takes the stage of a machine standing at the base's ceiling, so the plant's heart changes when the base levels up, with the base's own look. At launch that's Stage II with the base's level 2, in the first session, and Stage III with level 3, at about 5 hours (research, on Faber's lean, 2026-11-16).
- **The battery** stores what isn't routed ("Power"), to a cap, and is what keeps the base working while the player is away. Past the cap, the overflow sells itself into Credits at a poor rate, so nothing is thrown away. Its cap rises with the base's level, never by an upgrade of its own, so there is no choice to keep it small for the overflow (the director's question, 2026-11-12). The screen shows the cap as the hours of work it holds, not a number of units. Electricity is always worth more spent than sold: a full battery's overflow is a few kills' Credits.
- **Machines:** the Void Breaker, the Forge, the Stone Condenser, the Research Lab [D]. Each is a place to walk to, with its own sound.
- **Upgrading gear needs no walk** [D, 2026-11-17, 12:25 and 12:27; the pages, D, 2026-11-19, 03:10]: Reinforce, Jewels and War Emblems are Equipment's screens, opened from Home [D, 03:38; Home, about 12:21]; jewels and emblems are put in and taken out there only, and the gear's card shows what's socketed. A gear cell shows only its Reinforce level. The base's Forge machine keeps its name, opens the same Equipment page, and its ram strikes the item when the player reinforces it there: optional, and the better show. The Forge's own use comes after launch, from the director.
- **Reinforce** [D, 2026-11-19, 03:10]: a gear's level, +1 a success, paid in stones and Credits. Success is 100% to +5, then 80%, 70%, 60%, 50%, and on down to 20% (seeds past +5). A failure spends its cost and the level stays. The chance is shown before every press, success and failure adding to 100% (`docs/roblox-rules.md`).
- **The Stone Condenser makes forge stones, online and away** [D, 2026-11-12: "a machine at base that produce stones ... it will work offlines making players come back and get very strong"]. It draws electricity like the Breaker, so the workers feed it too (research's). What it makes lands in its tray, which has a cap: a full tray stops, and coming back to empty it is the reason to return. Its grade and speed rise with its level. Turning lower stones into higher ones stays its second job. **It makes jewels too, from launch, the tier rising with its level** [D, 2026-11-17, 12:10: "same for the condenser it will drop higher jewel as it level go up"; "At launch, beside stones"]. Stones still drop from enemies, keepers and the Tower [D]. More uses come later [D: "for now only this"].
- **The Training machine** [D, 2026-11-14, night: "the voidkin that we equipped train with a machine and get level (even offline)"]. It trains one Voidkin at a time: the one at home without the player, a fallen lead once it's healed, or the player's lead while the player is offline. When the player is on the plot, the lead leaves it and follows. At its full power it earns a fixed amount of experience a minute that never grows: a third of what fighting earns in Lantern Row (seed, through the simulation). With less power it trains slower, in proportion ("Power", below). No cap [D: "simply no cap"; "it will be slow at high level tho"; then "Fixed rate, no cap"]: each level costs more, so training is fast at the start and slows steeply as levels rise. Earning a share of fighting at its own level was tried in the simulation and reached the last level in a week. Its time away is worked out on the server at the next join, as the Breaker's and the battery's are. It draws power like every machine [D, 2026-11-14, night: "Yes, as restated" to the power plant; it replaces "it draws nothing"].
- **Its size: about half** [D, 2026-11-16: the package's point 5, replacing "way bigger" of 2026-11-12]. It holds the Breaker, six bays each with its Voidkin at work inside, the battery, the Forge, the Condenser and the Lab, with the Tower behind.
  - **128 studs square** [D, 2026-11-17: "reduce a bit ... or i let you choose"; research's pick from the three tried in grey, 128, 144 and 160]: the smallest that passes every test below. Neighbours stand 32 apart instead of 48. If the player's camera finds it cluttered, 144 is the fallback.
  - The pick, from the player's camera: the gate to the Breaker in 4 s or less at a walk; every machine seen from the gate in one view; none within 12 studs of another's front; a clear way in; room kept for the Forge, the Condenser and the Lab as sleeping places.
  - The base is recomposed, never scaled: the machines keep their size. The world's numbers: `src/shared/Config/World.luau`.
- **Visiting** another base is free and safe [D]: look, never touch.

## Regalia: gear

The largest change from the package (`docs/decisions.md`, "What changed from the package"), kept by the director's yes of 2026-11-16, whose package has presets across the account.

- **Gear belongs to the account,** not to one Voidkin. Fourteen slots [D]: Main Hand, Off Hand, Helmet, Shoulders, Chest Armor, Gloves, Bracers, Boots, Cloak, Amulet, Ring I, Ring II, Earring I, Earring II. The two hands are the two weapon slots [D, 2026-11-12]: they take the places of the package's Weapon and Shield, since the Tank's shield is its off hand.
- **Weapons belong to a class** [D]: only that class wields them. Each class has its pair:

| Class | Main Hand | Off Hand |
|---|---|---|
| Tank | Great Axe [D] | Shield [D] |
| Mage | Staff [D] | Tome [D] |
| Assassin | Dagger [D] | Throwing Blades |
| Warrior | Sword [D] | Short Sword [D: two swords, 2026-11-12 and 2026-11-16] |
| Healer | Crystal Baton [D] | Codex [D: a book] |

  The pairs are final by the director's word (the Assassin's off hand is research's, taken), the Warrior's two swords included [D, 2026-11-16, 20:41]. The slots never decide a Voidkin's model: a Warrior may hold one long sword, two swords or anything its design gives it, and so may every class [D, the same]. The Warrior's off-hand sword is shorter, so the two slots never show the same icon. Every main hand is a silhouette no other class shares. The Mage and the Healer both hold a book: the Mage's Tome is heavy and dark, the Healer's Codex light and clasped with the baton's crystal, and every weapon icon carries its class mark on the frame, so the two never read as one.
- **Presets.** A preset holds the twelve shared slots and one weapon pair for each class. One at the start, up to five. Each Voidkin is linked to a preset and fights with its own class's pair from it, so a Tank wears the tank set and an Assassin the crit set, and swapping the lead swaps nothing by hand. One item may sit in several presets. A preset whose pair is empty for the lead's class says so with a mark on the slot, never silently.
- **Class rules** [D, 2026-11-16: the package's point 8]. Main Hand and Off Hand take only their class's pair; the other twelve slots suit every class. The resolver reads only the pair of the Voidkin's class, so a wrong-class bonus never applies, and the server checks every equip and refuses a wrong class with a reason the screen shows.
- **A weapon of any class may drop** and stays in the bag, usable or not [D, the same]. Drops lean to the lead's class, the rest among the classes the player owns, so a drop is rarely useless. The Void Shop's stock may hold any class.
- **Why:** a counter system asks players to swap leads often. Gear worn per Voidkin would make every swap a chore of fourteen items and their sockets, and it would bury new Voidkin under the cost of dressing them.
- **Gear is never shown on the body** [D]: each Voidkin's look is authored. An item's whole look is its icon, so the icon carries all of gear's appeal. Each item kind is modelled in Blender and rendered to its icon, lit, with its rarity's frame and light; rarity also shows in its material, from plain iron to gilt. Dawn has designs of its own. How many designs per kind is set when the item art's request is written (`docs/asset-requests.md`, AR6), after a reference study of the director's references for what makes an icon worth wanting.
- **An item's design** [research, 2026-11-16, on Faber's proposal]: each kind has three designs at each rarity (AR6), each with its own picture and name. An item's design is fixed when it drops and never changes after, even when its kind gains designs. A design is the look and the name only, never a stat, so no design is worth more than another of its rarity. The card's title is the design's name ("Blade of Embers", "Meigetsu, the Full Moon"), with its kind and rarity under it.
- **An item** has a rarity, a level tier, one main stat and a few rolled lines.
  - A weapon's main stat is Attack, and its lines favour its class's Main. An armour piece's is the Battle Attribute its slot fixes. A piece of jewellery's (the Amulet, the Rings, the Earrings) is a Basic Attribute rolled at the drop, one of the five: that's where the player chooses ("this ring is Agility").
  - Rolled lines come from the five attributes and the Battle Attributes. A line is priced by its Combat Power, so an attribute line and a Battle line of one budget are worth the same.
- **The comparison:** against what's worn in the same preset, for the weapon's class, or for the selected Voidkin with armour and jewellery. It shows the Basic Attribute changes, then the Battle Attribute changes, then Combat Power. Both sides come from the one resolver, so it can't drift.
- **Reinforce levels, emblems and jewels belong to the item** [D, 2026-11-17, 02:40: "they stick to a gears but if i equip a new gears i have this ui popped up that ask the player confirmation to transfer everything gears level, jewels etc"]. Equipping a new item over one that holds any of them asks once whether to move them all across. Yes moves the Reinforce level, the emblems and the jewels to the new item for free. No leaves them on the old item, which goes to the bag with them. What the new item can't hold stays on the old one (fewer emblem sockets). The prompt says so.
- **War Emblems** go in an item's sockets: one on a Common item, two on Uncommon, three on Rare, four on Epic and above [D: four at most]. **Emblems at launch are Uncommon, Rare, Epic and Legendary** [D, 2026-11-19, 03:13, replacing Common, Uncommon and Rare]: a black, rock-like star, its upper part in its rarity's colour, a white symbol in its middle. Three sets a rarity, each its symbol and name only, never a stat. Each emblem carries one stat, written on its card: Attack, Defence, Health, Critical, Hit or Dodge, and from Epic also Critical Damage, Critical Immunity or Lifesteal. Putting one in or taking it out is free, on the gear's card, and equipping a new item offers to move them across (above).
- **Jewels** [D, 2026-11-19, 03:10, replacing the percent-stat jewels and one socket from Rare]: every gear piece holds five, one of each colour, red, green, blue, yellow and purple. A jewel gives flat points of its colour's Basic Attribute. **Five levels at launch, more in later updates; three of one level make one of the next** [D, 2026-11-17, 12:10]. Its shape grows with its level: a small round grain, a tiny long crystal, a bigger long crystal, a triangle, a square [D]. Chests from a later update hold higher levels directly [D]. Critical Damage, Critical Immunity and Lifesteal come from gear's lines and the War Emblems.
- **The Stone Condenser** turns lower forge stones into higher ones. **The Research Lab** (after launch, in the big update [D, 2026-11-17, 02:40]) spends Research Points on permanent, flat gains: stat points and Breaker tuning. A machine's capacity (chambers, bay output) comes from its own level, and the battery's from the base's, so the two never buy the same thing.
- **Dawn** is the premium Legendary series [D]: Legendary rarity, above ordinary Legendary items [D, 2026-11-12], and the top gear of launch, earned in the last ground and the Tower. Its pieces read as one set (`docs/research/gear-icons.md`).

### Combat Power

One number for how strong the lead is with its preset, made to be watched rising [D: appealing, 2026-11-12].

- **Its word.** Players read it as "CR" wherever it shows [D, 2026-11-19, 10:36: "we are shorting combat power words to \"CR\""], from one string, `Sheet.Said.Power`. The docs and the code call it Combat Power.
- **It never lies.** It's a weighted sum of the lead's resolved stats (`docs/balance.md`, "The stats"), counting only what the fighter can use: Elemental Attack counts only for a fighter with an element (24f85e8, 2026-11-18), and the weights are fitted by the simulation so that, with no type edge, the higher Combat Power wins more often. A number players chase has to be one they can trust.
- **Every upgrade moves it.** Everything adds points, so every real gain, an emblem included, raises it by a visible number, never by zero: a whole one, or one decimal for a gain under 1 ("+0.4"). Its scale is a tenth of the seeds' first [D, 2026-11-18, D3: 60,382 reads about 6,038], a look that moves no balance. A gain is judged on the unrounded sum (`Stats.Compare`, `Chests.Keep`), so one under a half is never salvaged as none.
- **Where it shows.** On the Voidkin screen (Regalia's screen is merged into it, 2026-11-15), at the Voidkin's feet, large (between the slot columns on the Items page; alone under the figure on every other page), so it reads as the character's own [D: where is research's choice]. The same view is what a visiting player sees of your lead.
- **The moment** [D, 2026-11-12]. When an upgrade lands, the number pops a little, the gain shows in green with a "+", and the gold counter rolls to its new value. A loss shows as a plain number down. Over the world, the gain rises beside the lead's card for a second, then the HUD is quiet again.
- **The pull.** In the bag, an item that would raise it carries an up arrow; a slot with a better item waiting carries a dot. Each ground, keeper and Tower floor shows its recommended Combat Power, the player's beside it in green, amber or red.
- **Honest.** A tap on it shows how much each source gives, and the parts sum to the total (`docs/ui.md`, "Stats, shown honestly").
- It's for reading, matchmaking and the Clash's rewards, and never used to compute damage.

## Chests

[D, 2026-11-16: the package's point 9.] Earned by play, auto-collected, stacked and opened in bulk. **No chest, key or drop-rate boost is ever sold for Robux or a currency bought with Robux** (`docs/roblox-rules.md`).

- **Where they come from:** a Shade, at a small chance a kill, and the account's third kill always drops one, for the north star's "Build" beat; an elite, one every time, a tier up; a keeper, a better chest on the first win and a chest after; the Tower, a chance rising with the floor.
- **A chest is named for its ground and its kind** ("a Shade Chest of Lantern Row"). There are four kinds, Shade, Elite, Keeper's and Tower, each named for what drops it, and never a rarity's word or frame, since a chest isn't a rarity (research, TR29, 2026-11-16). In the bag, its picture says its kind, and its card gives its odds. Its table rolls the item's rarity, slot and lines on the server when it's opened.
- **The rarities' pace,** with the rates fitted to it by simulation (`docs/balance.md`, "Chests"). Being refitted to the stages' 10 to 15 minutes (D2), with research's seeds: the first piece worn by minute 3, the first Uncommon by the first Normal clear, the first Rare inside the first hour and sure on the first Hard Keeper's win, an Epic at 4 to 6 hours, a Legendary at 15 to 20. Until the fit, the table below stands:

| Rarity | The first one, at about | Mostly from |
|---|---|---|
| Uncommon | the first hour | Lantern Row |
| Rare | 3 to 4 hours | grounds 2 and 3 |
| Epic | 10 to 15 hours | grounds 4 and 5 |
| Legendary | 35 to 45 hours | ground 6 and the Tower's deep floors |
| Dawn | rarer still | the last ground and the Tower |

- **The convenience:** chests that fall near the avatar fly to it. Identical unopened chests stack ("Lantern Row Common × 37"). **Open all** opens a stack in one server step and shows one summary sorted by rarity, rare items lit; an Epic or better gets a short reveal of its own.
- **Auto-salvage** is a setting: items under a rarity the player picks turn into forge stones and Credits as they're opened, but never an item that would raise the Combat Power of the player's best Voidkin of its class (for a piece any class wears, of any class's best). A class the player owns no Voidkin of protects nothing.
- **The bag has a cap** and says so before it fills.
- **Safe by construction:** each open is one transaction with an id, so a repeat is a no-op and nothing is half-granted; every item is written in the save step that removes its chest; bulk opens go in chunks. Every number: `src/shared/Config/Chests.luau`.

## The Festival of Battles

Six grounds at launch (`docs/roster.md`), each a recolour and rearrangement of one festival kit. Each ground is a place of its own in the experience, its Normal and Hard played on its one map [D, 2026-11-19]. A ground has ordinary Shades, elites, one keeper, and a gate. Beating the keeper opens the next ground for good, and a shortcut gate back to the base [D].

- **Stages, each played on Normal or Hard** [D, 2026-11-18, D2; the shape is research's, on the director's grant]. Lantern Row is four stages, one mission each, and a Normal clear of the four takes 10 to 15 minutes. Hard opens for the ground when the Lamplighter falls on Normal, and is much harder; a stage needs the one before it on the same difficulty. Each tile shows its recommended Combat Power and, if locked, its condition. Each stage and difficulty rolls gear on its own budget: the first stage's first reward is sure to be an item the chosen fighter can use, and Hard's Keeper shows its Rare chance [D, D7]. The loot's pace is refitted to this length ("Chests", below).
- **A party plays in a reserved server** [D, 2026-11-18, D1], if parties come at launch ("Out of launch"). Its rules are pure Luau, blind to the transport, and progress travels in the save.
- **Keepers are fought alone.** Everyone gets their own fight, so nobody is carried and nobody waits.
- **Fighting together** happens at elites, which anyone near may join, and at the Calamity.
- **Each ground leans on two types,** so a second and a third lead are worth raising.

## The Strip

- **The Void Shop** [D]: stock changes every five minutes, the same in every server, with a limit per player. It sells for Credits: at launch, shards and a featured gear piece (D6, below). A featured stock is the reason to look up at the clock. How it works [research, 2026-11-17, 21:10, tier 2; its look: `docs/asset-requests.md`, AR38]:
  - **The clock.** A new stock every five minutes on world time, drawn from a seed that never reaches a client. Nobody sees a stock before it lands.
  - **The shelf at launch** [D, 2026-11-18, D6, replacing the six lines of 2026-11-17]: two Standard shards a player each stock, and on featured stocks one gear piece the player can preview before buying, for Credits only. The stock's index is the Unix time divided by 300, floored, and the shelf is a seeded draw on it, as `Tower.Draw` does, salted on the server so no client sees a stock early; every server shows the same shelf with no messaging. The rule is pure Luau, with offline cases (the shelf for an index, a buy, a refusal at the limit, a repeated request).
  - **Waiting for the roster:** the Enriched and Prismatic shard lines, and the rare offer (a Named shard of an Epic or rarer Voidkin, never a roll), come back when the roster holds what they sell. Lantern Row has no Epic.
  - **A limit per player, never a race.** Each line has its own count per player per stock, so one player's buy never empties another's. What's bought is saved against the stock's number, so a server hop never refills a line (`docs/engineering-plan.md`, the profile's `Shop`).
  - **Every chance shown.** The screen says how often a featured stock comes up, and every shard on the shelf shows its odds per Voidkin before it's bought, as every shard does.
  - **Bought at the counter.** The Shop stands on the Strip, a short walk through the Festival Door. In the last minute before a stock, the countdown chip shows under the pills (`docs/ui.md`). While a featured stock is in, the Shop's crown is lit for its five minutes.
  - **Never for Robux:** no paid restock and no bigger limit. Credits will be sold [D, 2026-11-19], so a shard bought with them is a paid random item, its odds shown before the buy (`docs/roblox-rules.md`, "What we do").
  - **Prices,** in Credits, are set in `tools/balance/seeds.json` from the simulation, so the shop takes about a quarter of income after five hours (`docs/balance.md`, "Earning").
- **The Void Rift** [D], after launch, in the big update [D, 2026-11-17, 02:40]: a short burst on a schedule, the same everywhere. While it's open, the Breakers of everyone online run many times faster. Speed only, never luck [D].
- **The Calamity** [D], after launch (the director, 2026-11-15): a great boss that arrives on a schedule in each server. Everyone who does a minimum share of the damage is rewarded, the top three most [D]. One claim per arrival per account.
- **The Clash Grounds** (the director's Void Clash [D]): an arena where every player may station one champion. Champions fight each other on their own, all day, in the open, and the players watch. Beating another champion pays the winner's owner: Credits and progress on a daily track [D: rewards when their Voidkin beats another]. A stronger champion beating a far weaker one earns little, and the same pair pays only so often. A beaten champion goes home and can be sent again after a short wait. Echoes, server-run stand-ins, keep the arena busy when few players have a champion out. The server's best champion wears a crown.

## The Tower

Its entrance stands behind each base [D], and the fight is in a room of its own [D, 2026-11-19, by 11:12, replacing the ring and the rising platforms of the package's point 4]. The launch loop: fight, win, the next foe, fight, die, rewards, reset.

- **The room:** one big circular room, well detailed, the same for everyone. Each player who steps in gets their own copy, set far from the map where nobody else sees it, made when they enter and removed when they leave, so a server holds eight at most. It's a move within the place, never a teleport to another.
- **The lot behind the base** keeps the entrance and a marker of the player's record floor, so a visitor still sees how high they've climbed.
- **A run:** the player steps into the entrance with their lead and stands in the room. An enemy Voidkin appears, fought automatically. On a win the next one appears in the same room and the floor's number rises; the camera stays the player's. The lead and its Regalia are frozen from the first fight to the end, as at a keeper.
- **Enemies:** our own Voidkin in an enemy look, darkened with void light, so no new models. Their level rises with the floor, on a lighter build than a player's (`docs/balance.md`, "The Tower").
- **Health carries:** nothing heals between floors. In a fight, healing tops out at a share of the lead's health a floor, the heal cap.
- **Death ends the run:** the results open: the highest floor this run and the record if it's beaten, opponents defeated, Credits, items and chests, rare rewards in their rarity's light. The next run starts from the ground.
- **Fast floors:** a floor far below the lead's power falls in one hit and the next foe comes at once, so the climb to where it gets hard takes seconds.
- **Rewards** by floor won: Credits rising with the floor, a chest chance rising with it, and a first-time bonus past the record. Fast floors pay nothing: they're the free ride to where it gets hard. One exception: floor 5's chest is sure the first time the account wins it, fast or not. Floors 1 to 5 are always Rook, Pip, Kirra, Lyric and Watt; the draw starts at floor 6 (branch `claude/design-review-rules`, a7cbd28, 2026-11-18). The Tower's chest has its own rarity row, so it gives Rare and better while Lantern Row is the only ground (`docs/balance.md`, "The Tower"). Each is written to the run's ledger on the server when its floor is won, and granted once when the run ends; a run's id makes a repeated claim a no-op.
- **Interruptions:** leaving the ring, going home, a disconnect or a shutdown end the run at its last floor won, and nothing won is lost. The results open once at the next join. A run never resumes.
- **The order** [D, 2026-11-19]: the room is built after the main game's open pieces. Until then the grey Tower, its platforms included, runs as it is.
- **Not at launch** [D]: milestone bosses, cash-outs, branches, extra currencies.

## The world, in grey

Research's layout for TR2, 2026-11-12. The builder installs it in grey; how it looks comes later with the festival kit (AR5). Times are the design. Studs are worked out at Roblox's default walk of 16 studs a second (R6 stands 5), so if Config changes the walk, the studs move and the times hold. Once the numbers are in Config, Config is their home.

```
              [Tower][Tower]    gate    [Tower][Tower]
              [ P1 ] [ P2 ]      ||      [ P3 ] [ P4 ]
   Calamity ═══════════════ the Strip ═══╬═══════════════ Clash Grounds
              [ P5 ] [ P6 ]     Shop     [ P7 ] [ P8 ]
              [Tower][Tower]            [Tower][Tower]
```

- **Eight plots, two rows of four, facing each other across the Strip** [D: eight bases, a Tower behind each]. A plot is 128 studs square ("The base", its size, above) and opens onto the Strip; the Festival Door takes its walk to the grounds. The Breaker stands at its front, so a passer-by sees the shards cracking. The bays line its sides, and the battery sits between them. Its back is kept for the Forge, the Lab and the Condenser, with the Tower behind that (phase 3; TR2 leaves the space). Neighbours stand 48 studs apart (TR2's verdict).
- **The Strip** is 3 s wide (48 studs). It breaks at its middle into a crossing one plot wide. North of the crossing a side street runs out between the Towers to the **festival gate**. South of it stands **the Shop**: every trip out and back passes the clock. The Strip's two ends are kept for the Calamity and the Clash Grounds (phase 5).
- **From the front of any plot to the first Shade: 20 s at most,** about 14 s from the nearest. That's 10 s at most to the crossing, 8 s up the side street past the plots and Towers to the gate, and 2 s past it to the first pack, which can be seen from the gate.
- **Lantern Row** is one street, 44 studs wide between the stall fronts (TR2's verdict, on the director's word), in one rhythm: three packs, the elite's square, three packs, the keeper's gate, one pack spacing apart each. Its length follows the spacing: about 37 s on foot at 80 studs (about 590 studs), so tuning one number keeps the rhythm (the builder's read, 2026-11-12).
  - **Six packs** of three Brawler Shades, 80 studs apart, past the lead's 30-stud leash, so the lead takes one pack at a time and the player chooses when to step on.
  - **A pack belongs to everyone.** Every player whose lead hit one of its Shades gets that Shade's drop in full, as at the elite. Nobody walks past a fight they can't join, and nobody steals a kill. A pack comes back a set time after its last Shade falls (Config). That wait is also what limits how much faster a group earns than a player alone.
  - **The elite** stands in a square at the street's middle, 4 s across (64 studs), so anyone near can join (design, "The Festival of Battles").
  - **At the far end, the keeper's gate,** and behind it **the Lamplighter's ring** (80 studs across). Every player gets their own fight; how is the builder's call.
  - **Beyond the ring:** Drum Court's gate, shut, in view. Beside it, the **shortcut home**, opened by the first win: in grey, a pad that sets the player down at their own plot.
- **The Festival Door** [D, 2026-11-12: "a door or something at the base to teleport to zones easily"]: a door on every plot that takes the player to the gate of any ground they've opened, with its twin at each gate to come home. It says where it leads [D, 2026-11-16, 00:43: "the portal need to be known it for festival of battle"]: from across the plot by the festival's light and lanterns, up close by its name on the plate over its ring, "Festival of Battles", and from afar by its sign with the ground's name. Once there are two grounds, its choice names each. So a plot can grow and stand apart without lengthening the trip to a fight, and the walk to the first Shade stops setting the plots' size. The Strip keeps what's worth walking to: the Shop, the Clash Grounds, the Calamity, and the other bases. Built with TR2's verdict and its numbers.
- **Arrival:** the player's spawn is on their own plot, facing the Breaker and the three shards ("The first session").
- **What the world marks** for code to read (the names and the contract are the builder's, `docs/engineering-plan.md`): each plot and its spawn, the Breaker, each bay, the battery, the festival gate, each pack's spawn, the elite's, the keeper's gate, the ring, the shortcut and its landing, the shut gate.
- **Tuned by walking, not on paper:** the walk times, pack spacing and the street's length are first guesses, judged at TR2's verdict from the player's camera.

## What the player holds

| Currency | Comes from | Goes to |
|---|---|---|
| Credits | fights, overflow electricity, copies past seven stars, the Clash | the Void Shop, Reinforce, the Condenser, the base's and machines' upgrades |
| Electricity | workers | breaking shards, infusion, the Condenser |
| Research Points | first clears, Tower floors, the daily track, the Calamity | the Research Lab |
| Forge stones, three grades | enemies by ground, keepers, the Tower, the Condenser, the shop | Reinforce |

**The bag** [D, 2026-11-12: "we will need a inventory systems"] holds everything owned that isn't a Voidkin: items, chests, emblems, jewels, stones, shards. One screen with tabs by kind, sort and filter, a lock on anything precious, and a count of its space. Items that would raise Combat Power carry the up arrow (Combat Power, above).

Void Essence is out of launch: nothing needed it that these four don't cover (`docs/polish-later.md`).

## Out of launch

No height stat, no prestige, no player traits, clans or races [D]. Fusion, mutations and traits on Voidkin, manual signatures, parties (built after everything else is finished [D, 2026-11-18]), saved-player Tower teams, Limited Voidkin and the tiers above Mythical wait for updates. Each is a line in `docs/polish-later.md`. A rare second form of each Voidkin comes after early access [D, 2026-11-18, D4]: a look found by roll, no stats, earned only and never sold.

## What's sold

Nothing random, and nothing that multiplies on top of another boost (`docs/balance.md`, "Earning"). The store's design is its own piece before launch, approved by the director (`docs/production-plan.md`, phase 6; `docs/roblox-rules.md`).
