# Polish later

Ideas that came up during a piece and didn't belong in it. One line each: the idea, where it came from, the date. Read at the director's whole-game review. Nothing here is a commitment.

## Out of launch, from the design of 2026-11-11

Each waits for an update, and for its own feel line and blockout (`docs/design.md`, "Out of launch").

- Firing a signature by hand.
- Fusion, mutations and traits on Voidkin.
- More evolutions, after Rook's proves the idea.
- Parties, and keepers fought together.
- Other players' saved teams as Tower floor holders.
- Limited Voidkin, and the rarities above Mythical.
- Void Essence, if a system ever needs a fifth currency.
- A second art seat for the world, if the count shows the team waiting on one maker.

## The finish pass

On the director's word of 2026-11-13 (`docs/decisions.md`): after the whole game is built, before launch and before anything public. Each push starts from its piece's competent verdict, and is judged beside it in motion at phone size.
- **The bar** (the director, 2026-11-17, 02:08): "There is more stuff like this that would clearly not fit for a release so the final polish must be very good". Every piece players see is read up close at phone size, zoomed in, in each of its states (full and empty, first and last), for seams, halos, stray marks and colour breaks, and judged against shipped anime games, never against our own takes.
- **The HUD's look, redone** ("the whole aesthic being not what i would call art", on the lead's card, AR12). It starts from a reference study of shipped anime games' HUDs (`/ga-reference-study`), and the directions go to the director.
- **The older four's redesign** (`docs/roster.md`, "The look"). Lyric's portrait: her headset's band lies on her head's outline from the front, so at phone size it reads as a dark line round her hair (AR12, research's pass). Her new portrait makes it read as a band.
- **First, a trial:** Fable takes one effect, beside Opus's version of the same one. The trial decides which model runs the rest.
- **The signature effects, from competent toward exceptional:**
  - Haymaker (AR8 B5). Against a keeper, its hang sits above the frame, since a cap at the hat was blocked (TR7, "The hang's fixes"). The lever to try is the camera's, not the square's: a short tilt up through the hang;
  - Lantern Burst (AR8 B1);
  - Held Note (AR8 B2);
  - the Lamplighter's signature (AR7);
  - each later Voidkin's, as they close.

## From the pieces

- **The Today card's pips and the win card's last dare mark** (TR54, research, 2026-11-24, 01:56): the open and claimed pips are close at 5 px (an outline beside a grey fill); stretch 4's kept mark on the win card's road sits past the road's end, near the card's edge.
- **Rook's hair and cloth, one step toward the reference** (AR59, research, 2026-11-24, 01:38): lift the crown's points to 0.45 to 0.6 of a head over the crown, so they break the outline at 64 px, and make the kit's fold shade one step deeper. Both are numbers in `tools/blender/anime_make.py` and `rook_make_takes.py`. The fold shade was pulled forward by research on 2026-11-24 (AR60, must-fix 3).
- **Kirra's scarf, cloth at the card's size** (AR60, research's pick, 2026-11-24, 11:01): the turn round her neck reads as a smooth tube at the card's portrait; a fold or a turned edge would make it read as cloth.
- **The Dasher's elite's second mask, face-out through the tell and the flight** (AR57, research, 2026-11-23, 22:25): it's seen edge-on for about 0.73 s, a pale strip beside the sleeve. Fixing it is a re-pose of the left arm's keys, and it goes back to the content check.
- **The Tower room's height** (AR56, research, 2026-11-23, 21:54; the director kept the room as it is). A raised stand and a landing at the door were each read blind as only "faintly" high, because "nothing measures the fall". Try the cues fresh eyes named: a far, smaller cloud layer in haze, and the tower's shaft running down into it.

- **A pulse along the base's live lines** (AR54's read in the game, research, 2026-11-23, 20:26; `plan.json`'s `current` runs, in the floor's pictures): one slow pulse out from the heart, only along a run whose machine is drawing, so the floor says which machines are working. Judge it in motion from the gate, at the shared finish.

- **The away rule said on the Power screen** (research, 2026-11-23, 20:07, from TR31's dropped line "Your bays worked 2 h of your 9 h away"): the workers generate for `Config.Base.Battery.AwayHours` away, then the machines run on the battery. Said beside the battery's hours, if players misread a return.

- **The 2D cartoon fire is redone, the director's word (13:59, 2026-11-17):** "i despise those 2d cartoonish fire vfx cant we fix it later on i shared a long batch of real vfx". It covers Pip's Lantern Burst (its coil's burn and the flames left standing at the target, AR4 and AR8) and every fire drawn the same way, flat and outlined. The redo starts from the shared packs' fire (`docs/research/vfx-reference.md`, "From the vault"), adapted to our look and logged, as a new blockout judged in motion. It waits with the Voidkin work for the end (`docs/decisions.md`).
- **Moved into the effects pass, 2026-11-13** (`docs/asset-requests.md`, AR8, on the director's word of that day): Haymaker's B5 (its block-in and costs in AR1, section 9), Pip's Lantern Burst's planned rework (AR4, section 8), the billboards drawn a picture late (AR2, section 13), and the level-up's flat ring (TR3).
- **Planned rework, the director's word (2026-11-12): the Voidkin's faces.** "we shouldnt give them all those identical face." Rook, Pip and Lyric keep their faces for now. The rework gives each Voidkin a face of its own, part of its silhouette, and every new Voidkin is designed with its own face from the start (`docs/roster.md`).

- The base's world plates as wide as what they say, not as their longest possible line: on a large screen the Breaker's and the bays' plates show empty room on the right. For the finished kit (AR3). TR2, the builder, 2026-11-12.
- The killing hit's number and the Shade's rising flame cross for about 4 frames (31 to 34). The number could drift aside when its target bursts. Brief and legible now (AR2, section 13).
- The reveal's fold from Epic up reads as a crouched figure with its head up, the ram's handle only a short line at the hip. Each Voidkin's Reveal clip could show its weapon more boldly in the fold (AR3, section 5, research, 2026-11-13).
- The type edge's arrow on the target's card is about 7 points tall on a phone, readable once you know it, small for what it decides. It could grow, or tint the card's edge (TR3, research, 2026-11-13).
- An engaged lead turns to its target ten times a second (`Combat.Think`) through an Align of 40, so a Shade running in leaves it 25 to 32° off when it skips (the skip turns it at once). Aiming it each frame while engaged would hold it square (TR7, the skip's self-test, the builder, 2026-11-13).
- The skip back's puff at take-off and scuff at the landing, from the kit's rows at rung 2: what sells a short skip seen end-on, as Pip's often is (TR7, research's verdict on the skip back's blockout).
- Lantern Row's other lanterns dimming as its keeper falls, so the keeper's lantern is the street's last light and then goes out. For the street's dressing, with level design (AR7, section 5, research, 2026-11-13).
- A mark on the dock's Voidkin while its skill points wait, so a player sees from the base that a point is ready (Faber's "what I'd change", TR15, research, 2026-11-14). Kept for the HUD's shared finish, beside the collection row's "· N to spend".
- The Void Mill's spur gear and pinions with narrower teeth: the blocky teeth (0.65) are wider than the gaps (0.4 to 0.45), so their corners cross through every pass, steady at about a third of a tooth's face. Mostly behind the dynamo's housing from the gate. For the generator's finish (AR19, "Stages II and III as kit pieces", the content check's note, Modulo, 2026-11-16).
- Combat Power measured against a panel, not summed: the lead's edge over one fighter of each spec at its level, turned into a number. In the sim it picks the better of two spends of one budget 90% of the time, where the sum is near a coin, and it ranks every same-level duel where the sum ranks 97%. Its tap's parts would have to be shared out, since it isn't a sum (TR17 fix 10, research, 2026-11-15).
- The Voidkin standing in a ring of its fourteen slots, the void's ring made the frame: the best single picture of AR18's three directions, set aside for the bag because the bag shrinks to two rows. For a page about the Voidkin itself, when one is designed (AR18, research's verdict, 2026-11-16).
- The Festival Door's shut core in a look of its own: today open and shut differ by about 10 in blue at its middle, and the slice never shows it shut (AR15, research's pass on the ring tunnel, 2026-11-17).
- A screen plate never covers the player's own lead: at mid distance on a phone, the band pushes the Door's sign onto the lead's head, and the machines' plates do the same when a lead stands before them (AR15, research's second look at the sign, 2026-11-17).
- **Power's bar, an idle share** (TR41 (b), research, 2026-11-17, 17:24): an idle machine's share wears the battery's gold, so its handle splits gold from gold. A dimmed trace of the machine's own colour would show where its share ends.
- **The level-up notice, a long name** (TR41 (c), research, 2026-11-17, 18:00): cut to one word ("Little…"), it loses who levelled. Shrink the name a step before cutting it.
- **The HUD's machine colours and the world's lights differ** (AR35, Modulo's fact, research, 2026-11-17, 18:39): the power panel gives the Training machine cyan (`#4FD1FF`) where its model glows violet, and the Breaker pale (`#E6ECF7`) where it glows cyan. Whether a machine's HUD colour should match its light is a tier 2 question, not opened until then.
- **The Breaker strip's ground band at the smallest phone** (TR41 (d), research, 2026-11-17, 18:40): 3.6 points reads as a faint line under the chip's gold edge, not yet as Lantern Row's colour. A step thicker, or the band brighter there.
- **A stage lands, the coil** (AR37, research, 2026-11-17, 20:32): C's winding ribbon, Modulo's pick, has more turn than A's hoop. Try it as A's climb once A is in the game, if it reads from the court.
- **The Void Shop's clock by day from far off** (AR38's second look, research, 2026-11-19, 01:14): at 160 studs at noon the lit teeth are no lighter than the sky. A dark back behind the brow's opening would set the lower teeth on dark. The count reads now by its gaps, and the crown is the far signal.
- **The stages' tiles share one picture** (AR42's pick, research, 2026-11-19, 02:06): stages 1 to 3 show the Shade, with 2 and 3 identical. Give each stretch its own mark once the stretches differ.
- **The stages' band's Back** (AR42's install, research, 2026-11-19, 18:51): a black plate, the darkest thing on the lit-glass screen. It could be the kit's quiet glass press.
- **The bag's tab row's edge** (AR43's take 2 pass, research, 2026-11-19, 22:59): at the smallest phone, "Chests" is cut to "Ches" at the row's right edge with no fade. A soft fade at the scrolling edge would show the row goes on.
- **The reveal's room is a violet-black ground** (TR50's class sweep, research, 2026-11-23, 02:05): `reveal_room.png` bakes `#2B2542` to `#07050C` as the whole room, the one ground left on the too-purple line. It's a closed piece, so a new image waits for the finish pass, judged beside the rarity's light it frames.
- **Level 3's stacked halo from the gate's line** (AR50's pass, research, 2026-11-23, 14:04): the upper ring is half out of the frame, and in a still its far arc crowds the lower ring's near arc, so the stack reads busy, not crowned. Judge it first in motion in the game. If it still crowds, set the upper ring higher or wider on the same axle, kept inside the frame.
- **The Condenser's cups as its own lit state** (AR51's pick, research, 2026-11-23, 14:29): Modulo's C, five small cups round one, lit by the convert's state, standing under B's card. It's the better object, and the machine would show its state without words. A new blockout, at the finish pass.
- **The Guard's mask, one more paper detail** (AR52, research's pick, 2026-11-23, 15:25): a fold or one painted mark at the clip's finish; it's the plainest of the three Shades' masks.
- **The dock's Open, its own mark** (AR30, research's read in the game, 2026-11-23, 15:27): at 0.6 it's hard to tell from rest at 0.4 in the dock alone; for example the foot's bar lit across the cell. The panel and its pointer carry it on screen until then.
- **The dare's tag unfolds again on a tap** (AR53's pick, research, 2026-11-23, 17:49): a player who missed the 3 s unfold reads the dare again from its tag, a 44 tap box over it.
- **AR57, the Guard elite's second mask at night** (research, 2026-11-24): at the player's camera it reads at the hand as a blank white card. Tip it a little toward the camera at rest so its features read.
- **Life without new clips** (the Gemini addendum, research's pick, 2026-11-26, 13:06): the lead's head turns to its target with Roblox's own `IKControl`, a lean into a run and a bank into a turn on the root, and a recoil kick on a hit taken. Faber's feel, tuned by playing.
- **Hair, scarves and tails moved at runtime** (the same): a damped spring on their joints in place of the baked scarf layers (`kirra_clips.py`), so every Voidkin's cloth answers dashes and hitstop. Faber's and Modulo's technical call; first measure its cost on the smallest phone.
- **A signature's impact frame** (the same): one or two frames of high-contrast silhouette on a signature's hit only. Fired at most once a second, never on ordinary hits, and off under reduced motion, since full-screen flashes risk photosensitive players. Scintilla's, as a target beside the signature's build.
- AR62's frame (research, 2026-11-26, 14:24): our own round buttons, such as Spectate's eye, take the shard cut with the panels. Roblox's top-left buttons stay as Roblox draws them.

## Done

Lines pulled forward and drawn. The record is in each piece's entry.

- **The Stars page's empty stars** (AR29's read, research, 2026-11-17, 20:06): at 0 of 7 the seven empty stars are nearly invisible on the panel's top. A faint outline would let the row read as seven to win. Done: AR43's cut in B draws them with a Facet hairline (research, 2026-11-19, 21:28).
- **The plain damage digits' tracking** (AR44's second look, research, 2026-11-19, 13:20): pulled forward by research on 2026-11-19. Loose at full speed too, so Modulo set the plain styles' `Gap` to 0.12, and Faber's Config change is next (AR44, "The plain digits' tracking, from polish-later").
- **Jewels' levels 2 and 3 at 38 points** (AR43, research's pass, 14:12): pulled forward by research on 2026-11-19. Level 3 now lies true at 40 degrees, reaching across the cell, and the content check passed. Faber's upload of the five is next (AR43, "Jewel level 3's own read at 38 points, from polish-later").
- **TR10's elite icon** (research, 2026-11-17, 16:24): its masks ran near white. It was redrawn on AR47's mask on 2026-11-19, since the old one showed the blocked brows. The paper is now the game's tan, with lit holes and grin, and the content check passed (TR10, "The elite's icon on AR47's mask").
- **A guard broken by the Haymaker** (research, 2026-11-26, 15:26; AR52's final): AR1's gold square leads, and the ward's ring and chips follow 0.17 s later. Judge the order, and whether the square should yield to the break, at TR69's hit pass.
- **Training's plate up close** (research, 2026-11-26, 18:12; AR65's verdict in game): inside about 12 studs it hides, because its near plate always overlaps the avatar's or the lead's outline. A near plate rises clear of them before it hides.
