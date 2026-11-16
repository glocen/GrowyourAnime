# The director's package of 2026-11-16

Sent to research's session and read between 13:41 and 13:45 by the clock, addressed to Quaestor, Faber and Modulo. Kept word for word below. What it covers, research's restatement and the director's answer are in `docs/decisions.md`, "The director's words".

---

UI Art Direction — Full Creative Freedom

Modulo has full creative freedom to redesign the colors, shapes, silhouettes, proportions, framing and visual composition of any UI element in Grow Your Anime.

Do not restrict Modulo to our existing UI shapes, chamfered corners, rectangular panels, button designs or established palettes.

This includes:

* Inventory and equipment interfaces.
* Character Overview and stat panels.
* Combat HUD and health bars.
* Buttons, frames, borders and navigation.
* Icons, rarity frames and item slots.
* Machine interfaces, shop menus and reward screens.
* Any other UI component that would benefit from a redesign.

Modulo may explore completely different geometries, asymmetric compositions, custom silhouettes, layered frames and original decorative elements.

The current UI is a foundation, not a visual constraint.

However, creative freedom must still respect:

* Readability and intuitive navigation.
* Comfortable touch targets on mobile.
* Consistency between related interfaces.
* Clear hierarchy and restrained visual complexity.
* Performance and maintainability.
* Our mature, premium anime-inspired identity.

The mobile inventory remains the immediate redesign priority, but this freedom applies to the entire game's UI.

For major redesigns, present 2–3 genuinely distinct directions for review before implementation.

Quaestor judges composition and usability. Faber evaluates implementation feasibility. Modulo leads the artistic direction.

I want genuinely excellent original UI design, not just polished versions of generic Roblox interface patterns. Don't preserve an existing shape, layout or color simply because it's already implemented.

Grow Your Anime — Design, Progression & Visual Rework

To: Quaestor, Faber and Modulo

I want to revise several aspects of Grow Your Anime before advancing too far into Phase 3.

Our objective remains a premium, polished, anime-inspired collection and action RPG with deep progression, excellent visuals, strong performance and intuitive gameplay.

Review existing decisions, code, assets and system contracts before implementing changes. Preserve what works. Quality takes priority over arbitrary deadlines.

⸻

1. Basic Attributes — New Progression System

Introduce Basic Attributes inspired by Taichi Panda 3: Dragon Hunter.

Basic Attributes must directly generate Battle Attributes through explicit numerical conversions.

For example:

1 Strength = +1 Health and +2 Attack.

100 Strength therefore provides +100 Health and +200 Attack.

These are examples, not approved balance values.

Quaestor must determine and simulate the actual coefficients.

Proposed attributes

* Strength: Primarily contributes Attack, potentially some Health or Defence.
* Agility: Contributes Hit, Dodge and potentially Critical-related stats.
* Stamina: Primarily contributes Health and Defence.
* Spirit: Contributes Regeneration and potentially healing effectiveness.
* Intelligence (optional): Could contribute magical or Elemental Attack. We do not have mana, so retain Intelligence only if it serves a distinct purpose.

Four meaningful attributes are preferable to five poorly differentiated ones.

Class-specific conversions

I approve different classes benefiting differently from Basic Attributes.

For example, Warriors could obtain greater offensive value from Strength, while Tanks benefit more from Stamina.

Mages need a sensible offensive specialization, without requiring an unnecessary mana system.

Requirements:

* Explicit conversion formulas for every attribute.
* Useful secondary attributes.
* Meaningful class identities.
* No universally optimal attribute.
* Avoid uncontrolled multiplicative scaling.
* Prevent double-counting existing stat bonuses.
* Integrate conversions into the existing stat resolver.
* Update Combat Power calculations.
* Allow equipment to provide Basic Attributes.
* No manual stat-point allocation at launch.

Use simulations to determine balance before implementation.

⸻

2. Character Overview Reorganization

Use the Taichi Panda 3 screenshots I supplied as references for information hierarchy, not for copying their visual design.

Separate the Overview into:

BASIC ATTRIBUTES

Strength, Agility, Stamina, Spirit and Intelligence if retained.

BATTLE ATTRIBUTES

Core: Health, Attack, Defence, Regeneration, Speed, Poise.

Offensive: Hit, Critical, Critical Damage, Penetration, Elemental Attack, Lifesteal, Damage Bonus.

Defensive: Dodge, Block, Critical Resist, Critical Guard, Elemental Resist, Damage Reduction.

Quaestor may reorganize these categories if a better hierarchy exists.

Numerical presentation

Audit the current rating-based implementation of Hit, Dodge, Critical and other combat statistics.

The Taichi Panda 3 reference uses percentages, including Hit values exceeding 100%.

Decide whether our statistics should be displayed as raw ratings, flat values, percentages or derived effective chances.

A Hit value exceeding 100% must not be misrepresented as a literal probability of landing an attack.

Do not simply append percentage symbols to existing ratings.

Ensure displayed values correspond to their actual combat formulas.

Presentation

Use clean grouping, consistent alignment, readable typography, correct number formatting and efficient scrolling.

Keep the appearance premium without unnecessary descriptions or decorative clutter.

Equipment upgrades should produce clear and satisfying numerical improvements.

⸻

3. Mobile and Desktop UI Improvements

Our UI already supports responsive scaling, but I want a proper review of layout composition.

Mobile

Prioritize:

* Touch-friendly controls.
* Compact, readable panels.
* Efficient scrolling.
* Safe-area compatibility.
* Better spacing and visual hierarchy.
* Minimal screen obstruction.

Desktop

Use the additional screen space for:

* Wider information panels.
* Comfortable equipment management.
* Improved stat presentation.
* More visible content.
* Mouse hover interactions.
* Less unnecessary scrolling.

Automatically detect viewport dimensions and preferred input capabilities.

Do not ask players to select PC or Mobile every time they join.

Reuse the existing UI component library. Do not create two completely independent systems.

Support tablets and gamepads appropriately.

⸻

4. Inventory UI — Major Mobile Visual Redesign

I am not satisfied with the current Inventory HUD/UI, particularly on mobile.

It feels too clunky, and I want a substantial visual redesign rather than minor adjustments.

New color palette

The inventory needs a completely refreshed color direction.

Do not simply recolor the existing frames and call it finished.

I want Modulo to explore a fresh palette that feels:

* Premium and slightly mature.
* Appropriate for our anime-inspired visual identity.
* Clean and well composed.
* Pleasant to look at for extended periods.
* Distinctive without excessive saturation or glow.
* Consistent with the wider game's visual language.

The inventory doesn't necessarily need to use the same colors as the combat HUD.

Different interfaces can have their own palette when that improves their identity, provided the whole game remains coherent.

Preserve meaningful rarity colors and the established color language of gameplay statistics.

Less clunky mobile composition

The phone layout needs particular attention.

Problems to address:

* Unnecessarily bulky panels.
* Excessive visual framing.
* Awkward spacing.
* Too much information competing for attention.
* Inefficient use of limited screen space.
* Uncomfortable navigation between inventory categories.
* Excessively large decorative components when they provide little value.

Reconsider the actual composition instead of simply shrinking every element.

Desired inventory design

I want:

* A cleaner inventory grid.
* Better item icon presentation.
* More elegant category navigation.
* Properly sized touch targets.
* Clear rarity identification.
* A well-composed equipment details panel.
* Better separation between the item collection and selected item information.
* Smoother visual transitions.
* More responsive pressing and scrolling.
* Less wasted space.
* A stronger overall visual identity.

The inventory should immediately feel intuitive when opened.

Players should be able to browse items, inspect equipment, compare gear, identify compatible classes and equip valid items comfortably on a phone.

Don't sacrifice usability to make the UI visually interesting.

Character screen integration

Our Inventory is part of the broader Voidkin/Regalia interface.

Review how the inventory panel interacts with:

* The selected Voidkin.
* Its equipment slots.
* Basic and Battle Attributes.
* Gear comparisons.
* Class restrictions.
* The Bag's categories.
* The existing left navigation rail.

The entire interface should feel like one coherent design, not unrelated screens pushed together.

However, the mobile inventory is the main priority of this redesign.

The desktop version can retain more of its current structure if it already works well, although its colors and visual language should remain consistent with the updated design.

Review process

Modulo should produce two or three distinct visual directions for the mobile inventory.

Quaestor should judge their readability, composition and fit with our game.

Faber should evaluate implementation complexity and responsive behavior.

Select the strongest direction, refine it, then implement it using the existing UI component system.

Judge the final result from actual phone-sized gameplay captures, including populated inventories, long item names, equipment comparisons and empty states.

I want this to feel like a genuinely premium RPG inventory, not a generic Roblox simulator menu.

⸻

5. Reduce the Base Footprint

The current base is unnecessarily large.

Reduce its total ground area by approximately 50%.

Our current base measures around 200 × 200 studs.

Around 140 × 140 studs would represent approximately half the area, but this is only a reference.

Choose the actual size based on gameplay testing.

Requirements:

* Preserve eight player bases.
* Shorten travel distances.
* Keep bases close for social interaction.
* Preserve every necessary machine.
* Leave room for future upgrades.
* Avoid overcrowding.
* Keep clear pathways and sightlines.
* Maintain the functional production-facility identity.
* Review surrounding map geometry and placement systems.

Do not uniformly scale existing machines.

Recompose the base so it feels compact, attractive and purposeful.

⸻

6. Tower — Definitive Launch Design

Replace the oversized Tower concept with a simple ascending sequence of circular fighting platforms.

The design is inspired by the general progression concept of Grow a Chicken Fighter, but must have our own original visual identity.

The Tower starts empty

There should not be an enormous, fully constructed stack of platforms standing permanently behind every base.

When the player begins a Tower run:

1. A circular fighting platform appears.
2. An enemy NPC Voidkin spawns.
3. The player's Voidkin fights automatically.
4. Winning causes another platform to appear above.
5. The player's Voidkin advances to that platform.
6. Another enemy appears.
7. The process repeats until the player's Voidkin dies.

The structure should visibly grow vertically with each victory.

Transitions should feel satisfying without slowing gameplay unnecessarily.

Persistent Health

The Voidkin does not recover HP after defeating an opponent.

Example:

* Floor 1: 1,000 HP → wins with 850.
* Floor 2: starts with 850 → wins with 520.
* Floor 3: starts with 520.

No automatic healing between floors.

Review existing regeneration, lifesteal and healing mechanics so they don't trivialize the challenge. Normal in-combat sustain should be balanced separately.

Death and reset

When the Voidkin dies:

* The run ends.
* The current Tower progress resets to floor 0.
* Temporary platforms are removed or reset.
* A complete results interface appears.

Results UI

Show:

* Highest floor reached.
* Total opponents defeated.
* Currency earned.
* Items and chests obtained.
* Other rewards from the run.

The UI should be polished and well composed, with rare rewards appropriately distinguished.

Reward claims must be server-authoritative and protected against duplication.

Define how interruptions, disconnects and rejoining affect an active run.

Persistent records may remain, but the current run resets.

No unnecessary launch additions

Do not add special milestone bosses, early-extraction choices, branching routes or extra currencies merely to complicate the mode.

We can improve the Tower after launch.

The launch loop is:

Fight → Win → Rise → Fight → Die → Rewards → Reset.

Keep its geometry visually clean and performant. Avoid retaining hundreds of active platforms when unnecessary.

⸻

7. Machine Art Rework

Several machine models need significant improvements.

The generator is my highest-priority redesign. Its current appearance is unattractive.

Some level 1 machines look excessively advanced, while others lack detail or have weak silhouettes.

Level 1 direction

Machines should look like early-stage industrial equipment, but still be exceptionally well designed.

Use:

* Recognizable mechanical construction.
* Logical functional components.
* Attractive silhouettes.
* Appropriate detail density.
* Clear electricity pathways.
* Coherent materials.
* Satisfying animation.
* Our original mature anime-industrial aesthetic.

Avoid meaningless decorative complexity.

Visual evolution stages

I approve a limited number of machine appearance tiers.

Stage I — Primitive: Simple machinery, exposed components, modest energy effects.

Stage II — Developed: Better construction, more components and stronger mechanical detail.

Stage III — Advanced: Sophisticated mechanisms, refined silhouettes and stronger effects.

Several numerical upgrades may share one visual stage.

Choose visual progression thresholds that make meaningful upgrades satisfying.

Priorities:

1. Generator.
2. Void Breaker.
3. Extraction bays.
4. Battery and Training machine.
5. Other machines.

All designs require review from gameplay camera angles.

⸻

8. Class-Specific Weapons and Equipment Compatibility

Equipment must respect class identity.

Initial examples:

Class	Weapon archetypes
Warrior	Sword and Shield
Tank	Heavy weapon and Shield
Assassin	Daggers
Mage	Staff and Spellbook
Healer	Sceptre and Tome

Quaestor should finalize the compatibility rules.

Create coherent models and icons for weapon archetypes.

Important visual restriction

I do not want equipped loot to dynamically change each Voidkin's appearance.

Voidkin should retain their recognizable designs and signature weapons.

The gear system primarily affects numerical attributes and equipment information.

Avoid unnecessary systems for swapping visible weapons and adapting every attack animation.

Example

An enemy drops a Common Sword.

A Warrior can equip it.

A Mage cannot.

The sword stays in the inventory even when incompatible.

Implement:

* Weapon categories.
* Equipment slot rules.
* Class restrictions.
* Server-side validation.
* Clear compatibility feedback.
* Correct stat bonuses.
* Compatibility with the 14-slot Regalia system.

Non-weapon gear should remain broadly compatible unless restrictions serve a clear purpose.

Account-wide gear presets must never allow incompatible equipment bonuses to apply to the wrong class.

Gear comparisons

When inspecting an item, show:

* Equipped item.
* Selected alternative.
* Basic Attribute differences.
* Resulting Battle Attribute differences.
* Combat Power difference.

Keep the comparison readable and compact, especially on mobile.

⸻

9. Chest Drops — Sailor Piece-Style Convenience

Defeated enemies should sometimes drop chests containing equipment.

Example:

1. Defeat an ordinary enemy.
2. Obtain a Common Chest.
3. Open the chest.
4. Receive a Common Sword.
5. Store or equip it if compatible.

Quaestor must balance chest rates, loot tables and equipment rarity.

Rarer items must remain genuinely difficult to obtain.

Convenience features

I approve:

* Automatic nearby chest collection.
* Stacking identical unopened chests.
* Bulk chest opening.
* Efficient reward summaries.
* Fast handling of ordinary loot.
* More distinctive presentation for rare rewards.

Use Sailor Piece as a reference for convenient loot progression, not something to directly copy.

A player should not need to open hundreds of ordinary chests individually.

All rewards must be processed reliably on the server.

Prevent duplication and ensure every bulk-opened reward is granted correctly.

⸻

10. Integration and Balance

These systems must work together.

Attributes and Regalia: Basic Attribute conversions, class scaling, equipment bonuses and Battle Attributes must form one coherent calculation system.

Combat Power: Avoid double-counting and preserve its usefulness as an estimate of combat effectiveness.

Tower: Persistent HP, healing, enemy difficulty, rewards and reset behavior must remain correct.

Inventory and Chests: Support class restrictions, rarity, storage, bulk rewards and proper saving.

Machines and Base: Appearance stages and smaller base dimensions must work with the existing level and world systems.

Mobile and PC: Both must use the same gameplay data and server-authoritative actions.

Run appropriate simulations, logic tests, Studio tests and visual reviews.

⸻

11. Implementation Priorities

P0 — Design and mathematical foundations

* Finalize Basic Attribute conversion formulas.
* Finalize class-specific attribute scaling.
* Decide whether Intelligence stays.
* Correct percentage/rating representations.
* Redesign the Overview hierarchy.
* Finalize class equipment restrictions.
* Define Tower launch rules.
* Establish the mobile inventory's new art direction.

P1 — UI and world rework

* Redesign the mobile inventory UI with a fresh palette.
* Improve responsive mobile and desktop layouts.
* Reduce and recompose the base.
* Redesign the generator.
* Establish machine visual evolution stages.
* Replace the excessive Tower structure.

P2 — Progression and Phase 3 integration

* Integrate Basic Attributes with Regalia and Combat Power.
* Implement class-compatible equipment and comparisons.
* Prepare weapon archetype models and icons.
* Implement chests, loot tables and bulk opening.
* Implement the Tower's circular platform progression, persistent HP and results UI.
* Connect machine appearance upgrades to progression.

These priorities should not unnecessarily interrupt the final Phase 2 acceptance tests.

Quaestor should coordinate the actual order according to dependencies.

⸻

12. Expected Deliverables and Quality Standard

Quaestor should return a cohesive implementation proposal covering:

1. Final Basic Attributes and mathematical conversions.
2. Class-specific scaling.
3. Whether Intelligence remains.
4. Correct stat presentation and Overview hierarchy.
5. A new mobile inventory color palette and visual composition.
6. Responsive mobile and PC layout decisions.
7. Reduced base dimensions and layout.
8. Tower gameplay and visual design.
9. Generator redesign and machine evolution stages.
10. Class-specific weapon archetypes and compatibility.
11. Chest drop and reward systems.
12. Implementation order, risks and verification criteria.

Modulo should present the mobile inventory redesign and generator's new direction for review rather than immediately committing to a final visual design.

Faber should preserve the modular architecture and avoid unnecessary code duplication.

Do not rush. Do not sacrifice polish merely to finish faster.

Our goal is not to endlessly add features. It is to make every existing system feel coherent, satisfying, attractive and premium.

Continue building on our foundation, and iterate until the result reaches the quality standard we want for Grow Your Anime.
