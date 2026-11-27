# Game icons: how a Roblox player reads as the icon (AR70)

Modulo, 2026-11-27, 18:32. Research's order of 18:30 (`docs/requests/AR70.md`, "(b) rejected"): study before any more art. The question is how top Roblox icons that show a Roblox player as a 3D render are posed, lit, framed and finished, and what reads at Home's 150 px. It's for our icon: a player breaking a Void Shard, with a Voidkin bursting from its light.

**Images looked at:**
- `build/reference/game-icons/` (18 icons at 512, `_sheet.png`) and `build/reference/game-icons/render/` (20 icons at 512, `_sheet.png`). Both are Roblox's public thumbnails, internal and gitignored, for craft and read only (rule 3).
- At 512: Jailbreak, Steal a Brainrot, Fisch and Dead Rails.
- All 38 at 150 px: `build/scratch/modulo/icon_study/sheet150.png`.
- Our rejected (b) three: `build/handoff/GamePage/ar70/b/`.

Several of these icons are late-November event art (turkeys, leaves). Shipped icons change often, so this study holds for this set.

**The measures** (`build/scratch/modulo/icon_study/measure.py`). Each icon is reduced to 150 px. Luminance is Rec. 709, 0 to 1:
- contrast is its standard deviation;
- black is the share of pixels under 0.08;
- edges is the share of pixels with a gradient over 0.08 (more edges means smaller shapes);
- centre/edge is the mean of the middle half over the mean of a 20 px border.

## OBSERVED

**Which ones are renders of a player.**
- **A player as a 3D render, at the bar:** Jailbreak, Fisch and Steal a Brainrot.
- **3D renders with no player:** Grow a Garden, Natural Disaster, Brookhaven, Doors, Arsenal, Blade Ball and 99 Nights.
- **Correction to the brief:** Dead Rails isn't a render. It's a drawn cartoon, with ink outlines, cel shading and speed lines. Its blocky figures are drawn, not rendered.

**1. Bright, lit scenes, not a figure on dark.** This is the largest measured difference from our (b).

| at 150 px | lum | contrast | black | edges | centre/edge |
|---|---|---|---|---|---|
| Jailbreak | 0.43 | 0.23 | 0.01 | 0.18 | 0.90 |
| Fisch | 0.53 | 0.24 | 0.01 | 0.22 | 0.89 |
| Steal a Brainrot | 0.57 | 0.24 | 0.03 | 0.32 | 1.04 |
| the 20 render icons, median | 0.50 | 0.24 | 0.03 | 0.21 | 1.04 |
| the 18 top icons, median | 0.50 | 0.28 | 0.06 | 0.33 | 1.04 |
| ours, (b) A / B / C | 0.42 / 0.46 / 0.36 | 0.31 / 0.29 / 0.30 | **0.17 / 0.13 / 0.18** | 0.28 / 0.34 / 0.26 | **2.09 / 1.68 / 3.10** |

- The player icons put their figure in a whole lit place, with a sky, water or a street. The border is as bright as the centre (0.9 to 1.0).
- Ours spotlit a figure on near-black, with a centre two to three times the border and five to ten times the black.
- The dark icons (Murder Mystery 2, 99 Nights, Arsenal, Forsaken, Tower Defense Simulator) are horror or event art, and none shows a player.

**2. Pose and silhouette.** Each player is mid-action, limbs off the body, and the silhouette reads whole at 150:
- **Jailbreak:** running at the camera, one fist thrown forward and the other arm cocked high.
- **Fisch:** thrown back on a dock, hauling a rod in a long diagonal.
- **Steal a Brainrot:** sprinting away, one arm forward, mid-stride.

No player stands square or poses still.

**3. The face on a block head is small and plain.** Roblox's simple decal faces are used: a small set mouth under the hair (Jailbreak), a plain smile (Fisch and Steal a Brainrot). At 150 the head is about 25 to 40 px, and the face is two or three marks. The expression is the pose's, not the face's. None draws an anime eye on the block head. Ours were face-first, a drawn glare filling the frame, which is the painted icons' rule and not the renders'.

**4. Light.**
- **Jailbreak:**
  - a sunset sky as the backlight, pink to violet, with a warm rim on the hair and shoulders;
  - a soft fill from the front, a searchlight cone, police lights in the haze;
  - the background soft (depth of field), and a lifted, violet-pink grade in the shadows.
- **Fisch:** high daylight from the upper left, soft contact shadows, bright cyan water, the far shore soft.
- **Steal a Brainrot:** flat game daylight. Its big subject is self-lit: an emissive green with bloom, the brightest thing in the frame.

All three have a clear key, colour that separates the subject from the ground (orange on pink, yellow on cyan, green on red), and depth in two or three planes.

**5. Camera and lens.**
- **Jailbreak:** low, a wide lens. The near fist is about as large as the head, so it's foreshortened.
- **Fisch:** high, looking down the diagonal, wide.
- **Steal a Brainrot:** the game's own third-person height, wide.

Read off the 512 images: the near hand or object is close to the lens, and the figure overlaps or nearly touches a frame edge.

**6. One big thing that says the game.**
- **Jailbreak:** the escape, the player himself in a prison suit with a helicopter.
- **Fisch:** the huge catch on the line.
- **Steal a Brainrot:** the glowing creature with its price and rarity.

Where there's a second subject, it's two to three times the player's size and it's the brightest or most saturated thing.

**7. How much of the frame each fills** (read off the 512 images, about ±5% of the frame):
- **Jailbreak:** the player is about 70% wide by 60% tall, with the head about 25% wide. The logotype is the bottom 25%.
- **Fisch:** the player is about 58% by 58% in the lower left, and the catch about 57% by 57% in the upper right, crossing on the diagonal.
- **Steal a Brainrot:** the creature is about 56% by 64% on the left, and the player about 27% by 32%. The text block is the top 25%.

**8. The finish.**
- The three renders have no ink outlines.
- Bloom is on the light sources: the searchlight, the creature's glow and the water's glints. Haze or depth of field gives the depth.
- Saturation is high (median 0.54, and 0.51 to 0.62 for the three) without near-black.
- **Text:** Jailbreak's logotype sits on a painted swash. Steal a Brainrot's is outlined text, and Fisch has none. At 150, only big, short words read.

## DESIGN (ours, from the findings, not from any one icon)

- **A lit place, not the void's dark.** The scene is bright. Black under 5% at 150, the border near the centre's brightness, saturation about 0.5 to 0.6. The shard's light is the brightest thing.
  - This is the director's "too purple, black, somber" again, in measures. Our (b) failed it.
- **The subject:** our own generic blocky player, R6-shaped and made in Blender, in our own painted clothes. It's never a real avatar or catalog items (rule 2).
  - Its face is a simple decal face of our own: a determined set mouth and simple eyes, two or three marks.
  - The read is the pose.
- **The pose:** the player mid-action against the shard, limbs off the body, the silhouette whole at 150: two hands driving the shard down, or a fist breaking it, toward a low wide camera.
- **The big thing:** the Voidkin bursting from the shard's light, two to three times the player's size, the brightest, most saturated thing in the frame.
  - Shown as a figure of light rising, its shape read and its make not judged.
  - Or as a Voidkin's outline lit from within.
  - Rook isn't the centre.
- **The light:** the shard is the key, cyan-white from below and in front. A warm rim from a dusk or day sky behind. Haze and a soft background for two or three planes. Bloom only on the shard and the Voidkin.
- **The camera:** low and wide, the shard and the hand near the lens.
  - The player is about 55 to 65% of the frame's height, with the head about 20 to 25% wide (about 30 to 38 px at 150).
  - The Voidkin is about half the frame.
  - The logotype is the bottom quarter at most.
- **The logotype:** ours carries over, "GROW YOUR ANIME" with the shard I. At 150, ANIME must read; GROW YOUR may be small.
- **The IP line:** no shipped composition rebuilt. Not a figure running at the camera with a vehicle behind, not a diagonal haul against a catch, and not a creature card with price text. Our idea, the shard breaking in the player's hands and a fighter rising from its light, is the game's own hook.
- **Unknown:** whether a render of our blocky player reads at the bar beside these. It's judged in the targets at 512 and 150 among the shipped icons, not here.
