# The roster

The thirty-one Voidkin of launch, the enemies, and the six grounds of the Festival. Research's design, 2026-11-11. Aegir as a white wind mech at Mythical, and a new Legendary in his old place, are the director's words of that day (`docs/decisions.md`). How fighters work: `docs/design.md`, "Voidkin". The numbers behind them: `docs/balance.md`.

**Status:** designed on paper. None is built, drawn or reviewed. A row changes at its design sheet (`docs/asset-requests.md`): the sheet is where a look is judged, and a look that fails there is redrawn, not renamed.

**One home.** Until the builder's Definitions exist, the id, rarity, type, class, element, zone and aptitude columns here are the truth, and `tools/balance/sim.py` reads this table. Once Definitions hold them, those columns leave this page and the creative columns stay.

## How to read a row

- **Type** is what a Voidkin beats: Blue beats Red, Red beats Orange, Orange beats Purple, Purple beats Green, Green beats Blue.
- **Class** is how it fights: Warrior, Tank, Assassin, Mage, Healer (`docs/design.md`, "Classes").
- **Element** colours its second damage number. A dash means it deals none.
- **Zone** is the first ground whose shards hold it. It stays in the next ground's shards too.
- **Apt** is its aptitude in an extraction bay, 1 to 3. It has nothing to do with combat.
- **Passive,** Common to Epic: one plain effect in a few words, with at most one plain condition (the director, 2026-11-13, `docs/decisions.md`). Those not yet written so are rewritten when their Voidkin is built.
- **Roots** are genre-level only, for the team. They name no work and no character.

## The look

Every Voidkin is drawn as a character from a real anime's cast (the director, 2026-11-15, night, `docs/decisions.md`). It's judged against that bar, at the game's camera, never against its own sheet's brief.

- **A character, not a job.** Its silhouette comes from fashion: a coat, a jacket, a uniform's cut, layers, a scarf or a wrap, with one asymmetry. Never an occupation's costume or a working tool.
- **Hair is the identity:** a hairstyle with a silhouette of its own, in sharp clumps, and a colour of its own. It's read first at the game's camera.
- **An anime face,** drawn for the character's personality: eyes with highlights, sharp brows, a small mouth. No two Voidkin share a face.
- **One weapon or focus with style,** sized to the body. Never a cartoon prop.
- **The element is a motif:** a colour accent, a light, a charm, a pattern, its effects. Never a trade's gear.
- **The body is our R6** (the director's "A", 2026-11-15). Hair, face, clothes and the weapon carry the look, with no custom proportions.
- **Rarity sets the detail.**
  - A Common or Uncommon has three or four elements and a plain palette with one accent. Its signature and passive are modest. Like an anime's side character, it's simple, never corny.
  - Each rarity up adds layers, trims, light, and pieces that move.
- **Already made:** Rook, Kirra, Pip and Lyric keep their looks now, and are redesigned to this bar at the end, in the finish pass before launch [D, 2026-11-17, 02:40: "Redesign them all", then "we wont redesign the old voidkin now right we said at the end"]. The Shade and the Lamplighter stay as they are until an overhaul much later.
- **A basic attack and a signature of its own** [D, 2026-11-17, 02:40]: every Voidkin's basic attack (M1) and signature have their own effect and their own sound, at Anime Vanguards' level of flash. No two share a hit.
- **The "Look" column below was written before this rule.** A row whose look is a trade's costume is designed again at its sheet. It keeps its rarity, type, class, element and its signature's function.

## The thirty-one

| id | Name | Rarity | Type | Class | Element | Zone | Apt | Look | Signature | Passive | Roots |
|---|---|---|---|---|---|---|---|---|---|---|---|
| rook | Rook | Common | Red | Warrior | - | 1 | 2 | Street brawler: cropped jacket with a high collar, taped fists, one oversized gauntlet | Haymaker: a long wind-up, one straight punch, a shockwave along the ground | Second Wind: takes less damage below 30% health | fighting manga |
| kirra | Kirra | Common | Blue | Assassin | - | 1 | 1 | Courier ninja: a scarf twice her length, a satchel, two short blades crossed on her back | Scarf Step: vanishes, crosses the target, cuts on the way out | First Strike: her first hit on a new target always crits | ninja action |
| pip | Pip | Common | Purple | Mage | Fire | 1 | 2 | Apprentice: a hat too big, sleeves too long, a lantern that floats beside him | Lantern Burst: the lantern flies out and bursts over a small area | Kindle: his third shot adds Fire damage | fantasy school |
| watt | Watt | Common | Orange | Tank | Storm | 1 | 3 | The quiet wall (AR11, take A, the director's pick, 2026-11-15): a long coat with a standing collar under his nose, swept dark hair lifting to pink tips, a thin black iron spear-staff with three white ceramic discs, slung | Ground Wire: plants his weapon, shields himself, and a pulse stops nearby enemies for a moment | Insulated: takes less elemental damage | the stoic guardian |
| patch | Patch | Common | Green | Healer | - | 2 | 2 | Field medic: a cross-strap satchel, bandage ribbons from both wrists, round glasses | Quick Fix: heals the ally with the least health, herself when alone | Triage: her heals are stronger on a target under half health | medical drama |
| tumble | Tumble | Common | Blue | Warrior | - | 2 | 1 | Acrobat: wide trousers, wrapped forearms, bells at the ankles | Cartwheel Kick: a spinning double kick that hits all around | Momentum: each hit in a row on one target adds damage, up to a cap | street dance |
| brick | Brick | Common | Red | Tank | - | 2 | 3 | Site worker: a hard hat, heavy boots, a steel door carried as a shield | Door Slam: slams the door down, pushes enemies back and draws them onto him | Hard Hat: blocks the first hit of every fight | working-class hero |
| sable | Sable | Uncommon | Green | Assassin | - | 1 | 1 | Duelist: a rapier and a fencer's stance. The look is designed at its sheet (AR25), and the feathered cap is out | Riposte: takes a guard, turns the next hit aside and lunges | Footwork: harder to hit for a few seconds after his signature | swashbuckler |
| cinder | Cinder | Uncommon | Purple | Mage | Fire | 2 | 2 | Pyre-keeper: a hooded robe with an ember hem, a censer swung on a chain | Cinder Ring: a ring of fire closes on the target's ground | Smoulder: targets she has set alight take more from her | dark fantasy |
| gantry | Gantry | Uncommon | Orange | Warrior | - | 2 | 3 | Loader mech: a boxy body with a caged cockpit, hazard stripes, piston arms | Piston Drive: two piston punches, the second one shoves | Counterweight: can't be pushed, and blocks more often | mecha, industrial |
| mallow | Mallow | Uncommon | Red | Healer | - | 2 | 2 | Tea-house cook: an iron pan across her back, an apron, a bun held by two chopsticks | Hot Meal: throws a dish that heals everyone near it for a few seconds | Hearty: more maximum health | cooking manga |
| rill | Rill | Uncommon | Blue | Mage | Frost | 3 | 1 | River sprite: a reed hat, sleeves that pour like water, a ring of water turning above one hand | Cold Snap: the ring flies out, freezes and breaks | Slipstream: harder to hit while she keeps her distance | water-spirit folklore |
| dirge | Dirge | Uncommon | Green | Tank | Void | 3 | 2 | Bell knight: dented plate, a tattered tabard, a handbell the size of a mace | Toll: one stroke of the bell draws every enemy near | Mourner: takes less damage for each enemy on him, up to a cap | gothic knight |
| juno | Juno | Uncommon | Purple | Warrior | Storm | 3 | 2 | School swordswoman: a blazer over wide pleated trousers, a wooden practice sword that crackles | Thunder Draw: a quick draw and a dash through the target | Study: crits more on a target she has hit five times | school battle |
| lyric | Lyric | Rare | Green | Healer | Storm | 1 | 2 | Stage singer: a two-tone bob cut at a slant, a headset, a mic-staff, two speaker drones | Held Note: a wave of sound that heals allies and hurts enemies in a cone | Tempo: Held Note comes back sooner | virtual singer |
| mirage | Mirage | Rare | Blue | Assassin | Fire | 3 | 1 | Desert blade dancer: a veil, two curved daggers, a belt of coins | Heat Haze: leaves an afterimage that strikes a second time | Shimmer: after a dodge, her next hit crits | desert adventure |
| bulwark | Bulwark | Rare | Orange | Tank | Frost | 3 | 3 | Knight mech: a tower shield with frost vents, a helm with one slit of light, shoulders like ramparts | Rampart: raises an ice wall that shields allies behind it | Rime: a blocked hit gives him a small shield | mecha, knightly |
| sliptail | Sliptail | Rare | Purple | Mage | Void | 3 | 2 | Fox fortune-teller: a fox mask worn on the side of the head, paper slips orbiting in a fan, long sleeves | Nine Slips: the slips leave the fan and home on targets | Trickster: after a dodge, reappears behind the attacker | fox-spirit folklore |
| gauge | Gauge | Rare | Red | Warrior | Storm | 4 | 2 | Rail-yard brawler: one mechanical arm with a pressure dial, an engineer's cap, a long coat | Overpressure: the arm vents steam, then one enormous punch | Redline: more damage as his health drops, up to a cap | steampunk |
| wren | Wren | Rare | Blue | Healer | - | 4 | 1 | Sky courier: a feathered cloak, flight goggles, a short bow | Mending Volley: a fan of arrows that heal allies and hurt enemies | Updraft: an ally she heals is harder to hit for a moment | sky adventure |
| halcyon | Halcyon | Epic | Purple | Healer | Frost | 3 | 2 | Snow-shrine keeper: a layered white robe with an icicle fringe, a crown of paper cranes, a hand-bell | Still Snow: snow falls on a wide circle, healing allies and chilling enemies | Thaw: healing past full health becomes a shield, up to a cap | snow-woman folklore |
| ashen | Ashen | Epic | Red | Assassin | Fire | 4 | 1 | Wandering swordsman: a straw hat with burn holes, one long blade across the shoulders, one sleeve burned away | Last Ember: a single draw cut that sets the target alight | Cinderwalk: his first hit after moving to a new target lands harder | wandering swordsman |
| ironhymn | Ironhymn | Epic | Orange | Mage | Storm | 4 | 3 | Organ mech: organ pipes as exhausts on its back, a chest plate like a stained-glass window | Pipe Barrage: bolts arc out of the pipes and fall on the target | Resonance: each bolt on the same target adds Storm damage, up to a cap | mecha, cathedral |
| noct | Noct | Epic | Green | Assassin | Void | 5 | 1 | Gate hunter: a long dark coat with glowing seams, a folding spear, a shadow that moves a beat late | Rift Lunge: throws the spear and arrives where it lands | Hunter's Mark: one marked target takes more from him | hunter manhwa |
| marigold | Marigold | Epic | Orange | Tank | Fire | 1 | 2 | Lion dancer: a great lion-head mask worn as helmet and shield, a tasselled body | Lion's Roar: a roar that draws every enemy and shields allies | Drumbeat: each hit he takes charges his next roar | lion-dance folklore |
| stellane | Stellane | Legendary | Purple | Mage | Storm | 4 | 2 | Star-charter: a compass staff, a cape that shows a moving night sky, boots that never touch the ground | Starfall Chart: draws a constellation, and a bolt falls on each star | Zenith: every third signature is stronger | magical girl, grown up |
| crane | Crane | Legendary | Blue | Warrior | - | 1 | 1 | Sect elder: a white robe with an ink-wash hem, hands behind his back, a sheathed sword he rarely draws | Hundred Steps: a storm of palm strikes from afterimages, ended by one draw of the sword | Calm: harder to hit and crits more the longer he goes unhit | martial-arts manhwa |
| shiomaru | Shiomaru | Legendary | Orange | Tank | Frost | 6 | 3 | Sea-fortress mech: an anchor on a chain, shoulders plated like a hull, a lighthouse lamp for a head | Anchor Drop: hauls enemies in on the chain and slams the anchor down | Breakwater: allies behind it take less damage | mecha, naval |
| aegir | Aegir | Mythical | Blue | Assassin | Storm | 6 | 3 | White wind mech, slim and fast: pearl-white armour, pale light in the seams, one narrow visor line, long swept fins on the back that open like a fan when it boosts, a slender lance, and a trail of white air behind every move | Glint Drive: gone in a streak of white wind, through every enemy on a line, then the lance fires back along it | Tailwind: each enemy it finishes refills part of its signature | mecha, high-speed |
| umbriel | Umbriel | Mythical | Green | Mage | Void | 6 | 2 | Void empress: a crown of floating shards, a gown that fades into starless black, two giant spectral hands that act for her | Hands of the Void: the two hands close on the target's ground | Sovereign: enemies near her resist elements less | dark empress |
| solkar | Solkar | Mythical | Red | Warrior | Fire | 6 | 2 | Dragon-blooded champion: a horned open helm, one scaled arm, a torn wing worn as a cloak, a greatsword cut from cooled lava | Dawnbreaker: a leap, and the sword opens a line of fire | Dragon's Blood: his signature heals him for part of its damage | dragon knight |

**What the table guarantees:**

- Six of each type, and a seventh for Blue. Seven Warriors, six Tanks, six Assassins, seven Mages, five Healers.
- Every type and every class exists among the Commons and Uncommons, so no counter and no role waits on luck.
- Five machines (Gantry, Bulwark, Ironhymn, Shiomaru, Aegir), one in each rarity from Uncommon to Mythical.
- Twenty-one with an element (six Fire, four Frost, seven Storm, four Void) and ten with none.
- Seven Commons, seven Uncommons, six Rares, five Epics, three Legendaries, three Mythicals.
- The starters are Rook, Kirra and Pip: the player picks one. Watt is the guaranteed second.

## The order they're made in

Three first, to measure what one costs (`docs/production-plan.md`, phase 2): **Rook** (the plain melee fighter everything else reuses), **Pip** (the ranged family and the first element), **Lyric** (a complex signature and a heal). Then the rest of ground 1, then by ground. The count at launch is what's at the bar by then: about thirty is the director's target, and no fighter ships below the bar to reach it.

**Names** may be Japanese or from any language that fits the fighter. A name is checked against `docs/ip-list.md` and nothing else.

**Bodies** (the director, 2026-11-11). Humanoid Voidkin stand at the R6 player's height, on the shared R6 rig. The five machines share one custom rig and stand taller: a seed of about one and a half times a player for Gantry and Bulwark, up to about twice for Ironhymn, Shiomaru and Aegir, settled at the first machine's sheet. Height is a look, never a stat.

**The first evolution** is Rook's: the same fighter with both gauntlets and a stronger Haymaker. One, built and judged, before a second is promised.

## Enemies: Shades

Festival-goers the Void has filled: a dark body, a glowing outline, and a festival mask. One rig, one clip family, four behaviours.

A fall knocks the mask loose, and the festival-goer walks home, remembering nothing [D, 2026-11-23, 15:23]. It stays inside Lantern Row's fights: the Mask Ledger that kept the masks was cut, and no mask goes on the base (the director, 2026-11-23, by 18:38; `docs/design.md`, "Goals").

| Behaviour | The mask | What it does | How it's beaten |
|---|---|---|---|
| Brawler | round, grinning | walks up and trades hits | by hitting harder |
| Guard | square, with a brow | raises a shield for a moment, then drops it | by waiting, or by breaking through |
| Dasher | long, pointed | shows a line, then lunges along it | by a Tank, or by dodging |
| Support | half-mask, veiled | heals and shields the others, and is fragile | by reaching it first: an Assassin's job |

The outline's colour is the Shade's type, in the same five colours as the Voidkin's gems. An elite is a larger Shade with a second mask on its shoulder. A ground's keeper is a Shade in full festival dress with one signature of its own.

## The Festival of Battles: six grounds at launch

A festival the Void has walked into. One kit of stalls, lanterns, banners and gates, recoloured and rearranged for each ground. The table is content, and a seventh ground is a new row.

| # | Ground | Levels | The look | Its Shades' types | Its keeper | The keeper's type |
|---|---|---|---|---|---|---|
| 1 | Lantern Row | 1 to 9 | a street of paper lanterns at dusk, cyan and warm white | Orange, Red, Green | the Lamplighter | Purple |
| 2 | Drum Court | 10 to 19 | a square of great drums and red banners | Blue, Purple | the Drum Major | Red |
| 3 | Mask Parade | 20 to 29 | a parade route under strings of masks, violet and gold | Green, Orange | the Masked Marshal | Blue |
| 4 | Kite Heights | 30 to 39 | rooftops and kites in a high wind, jade and white | Red, Blue | the Kite Master | Green |
| 5 | Ember Stalls | 40 to 49 | night food stalls and forges, amber and coal | Purple, Green | the Stall Queen | Orange |
| 6 | Mirror Pavilion | 50 to 60 | a hall of mirrors over still water, indigo and silver | all five | the Reflection | changes each third of its health |

- Ground 1's Shades give each starter something it beats, and its keeper is neutral to all three starters.
- **Lantern Row's shards at launch** [D, 2026-11-17, 02:40: "we will launch 5 voidkins for the launch not 8"; the five, "The 5 already in"]: Rook, Kirra, Pip and Watt (Common) and Lyric (Rare). Sable (Uncommon), Marigold (Epic) and Crane (Legendary) come in the big update after launch. Patch moves to Drum Court.
  - **Why these two:** without an Epic and a Legendary, an Enriched or Prismatic shard on the one ground holds nothing above Rare, and there's nothing to chase.
  - **Marigold** is the lion dancer, the festival's own figure. As an Orange Tank it beats the keeper, the top tier of Watt's line.
  - **Crane** is Blue like Kirra and a Warrior like Rook, so the top tier extends a starter's line. His afterimage storm is the ground's showpiece.
  - **Marigold's passive** is rewritten to the Common to Epic rule when he's built.
- Each ground after the first leans on two types, so a player has a reason to raise a second and a third lead.
- A keeper is fought alone, in its own ring, and beating it opens the next ground's gate for good (`docs/design.md`, "The Festival").
