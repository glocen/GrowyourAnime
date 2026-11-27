# How a mature, original anime UI is designed (study, 2026-11-27)

For the UI's complete overhaul (AR68). The director, 2026-11-27, at about 02:16: "this whole Ui modulo made is horrendous it just the design.", "it need a complete overhaul", then "it just not mature nor high quality nor original".

- **The question:** what makes a fight HUD and a home screen read as mature, high quality and original, by design (layout, scale, share of the screen, type, shape, colour, identity) and not by surface.
- **The labels:** OBSERVED (seen in an image), REPORTED (a developer said it), ANALYSIS (a third-party breakdown), INFERENCE (ours).
- **Sources:** public text only. The full notes and their links are in `build/scratch/quaestor/overhaul/web_findings.md` (about 20 sources).
- **Coverage:** Persona 5, NieR: Automata, Arknights and the type of Honkai: Star Rail and Zenless Zone Zero are well sourced. Wuthering Waves, Punishing: Gray Raven and Roblox's mature games (Type Soul, Deepwoken) are thin.

## What we had, measured (OBSERVED)

- **Our rejected fight HUD** (`build/handoff/UI/hud_overhaul/painted_fight/P_fight.png`):
  - The two cards cover 29% and 28% of the width.
  - The HUD's bounding box covers 66% of the width and 34% of the height, and sits above the action.
  - The kit is the casual mobile one: a boxed portrait, a level badge, a pill bar, a skull.
  - One bubbly italic face with thick strokes sets everything.
- **Anime Crusaders X in a match** (`g05_full`):
  - Three small chips at the top centre, about 3.6% of the height.
  - The rest sits on the edges, and the centre 80% is the world. Its plates' area is about a tenth of ours.
  - Its type is chunky and stroked too: it's the bar for finish and discipline, not for tone.
- **Taichi Panda 3: Dragon Hunter, in the arena:**
  - No plate behind the lead: a painted bust cut out over the scene.
  - Two thin slanted bars, about 3% of the height each, with a plain condensed sans and a thin diamond frame.

## What the premium games do

1. **The centre belongs to the fighters.**
   - Combat information sits small, on the edges and corners. REPORTED: Guild Wars 3 has "significantly less UI" because "it's a lean-back experience" (TechRadar, 2026). ANALYSIS: Persona 5's battle layout.
   - In auto-play the HUD is read in glances, and it grows only at a decision or a result (INFERENCE).
2. **The UI is a device or a voice inside the fiction.**
   - Arknights' UI is PRTS, the terminal the Doctor runs (ANALYSIS, GCORES). Blue Archive's is the Sensei's own tablet (REPORTED, its director). Persona 5's battle UI comes from sports broadcasts because a character commentates (REPORTED, Soejima).
   - A borrowed style with no reason in the fiction read as "a shallow coat of paint" (ANALYSIS, Inverse, on Persona 5 Tactica).
3. **One identity hue, neutrals for the rest.**
   - Persona 5 holds one red, and each Atlus game had its own single colour (REPORTED). NieR holds a warm beige (REPORTED).
   - State goes by value, weight and motion. Rarity hues stay on collection screens (INFERENCE).
4. **One working face.**
   - Body text and numbers are set in one neutral face, often DIN-like. Display type is for titles and peak moments only.
   - Star Rail sets one family in one weight and makes hierarchy from size and colour (ANALYSIS, GCORES). Roblox's own guidance: "use stylized text sparingly" (ANALYSIS).
5. **No heavy stroked display face as running text,** and lighter weights on dark grounds (ANALYSIS: GCORES's critique of ZZZ's ultra-bold everywhere).
6. **Thin lines and flat or cut shapes,** with frames only where the fiction calls for one (REPORTED: NieR's Kijima; ANALYSIS: Arknights). No source puts a thick black stroke round everything.
7. **No pure black, pure white or full saturation** as working colours (ANALYSIS, GCORES).
8. **Motion says where you went or what changed, then settles.** Loops for attention read as casual (ANALYSIS: Arknights' transitions follow its navigation; the ZZZ critique).
9. **Clean alone is bland.** Kijima's strictly flat first pass was bland, and one specific motif (a musical score) made it NieR's (REPORTED).
10. **The UI's energy follows the game's state:** muted at rest, kinetic at the climax (ANALYSIS, Persona 5 Royal).
11. **Style is tuned until it reads.** Persona 5's menus were "impossible to read at first" and were iterated until they read (REPORTED, Hashino). Metaphor aimed at expression "without going too far" (REPORTED, Ise).

## Lessons for us (DESIGN)

- Our rejected HUD was the shared kit of casual mobile, finished with Anime Crusaders' casual surface. Finish can't fix a design with no voice of its own.
- Each direction answers one question: **whose device or voice is this UI, inside our fiction?** The fiction: the Void Shards and the Voidkin, the base's bays making power, the fights through the grounds.
- The directions and their targets: AR68.
