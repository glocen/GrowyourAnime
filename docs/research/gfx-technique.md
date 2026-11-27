# How Roblox GFX icons and thumbnails are made (Modulo, 2026-11-27, 23:17)

The director, 2026-11-27, 23:14: "why cant you js do art do research on how to do gfx for roblox anime icon etc". The question: how Roblox GFX artists build an icon or a thumbnail, from the render to the finish, and what of it our own Blender and code can do. Read with `docs/research/game-icons.md`, the icons' own study (pose, framing, measures at 150 px).

Sources are public DevForum tutorials, read as text only. No image from them entered the repo. **STATED** is the tutorial author's own step. **OPINION** is a commenter's view or a guess.

## The method, as the tutorials give it

- **The render is the base, and most of the finish is a paint-over.**
  - STATED: [Vesteria's thumbnail](https://devforum.roblox.com/t/the-making-of-my-vesteria-thumbnail/319524): "3D render of characters on a simple floor", then most of the work in Photoshop. The characters are recoloured to match the game, a rim line is drawn round each one, the background is unified with a sky-blue fog, and a white glow sits behind the centre.
- **The figure:** a rigged Roblox avatar, posed in Blender.
  - STATED: [the Blender GFX advertisement tutorial](https://devforum.roblox.com/t/intermediate-to-advanced-how-to-make-a-professional-looking-gfx-advertisement-in-blender/1249194): Ultimate Rig, a neutral pose holding a prop, looking at the camera.
- **The light: one big light behind the figure for the rim, or emission planes round it, on a black world.**
  - STATED, the same tutorial: a large area light behind the character, power "cranked up pretty high", and the world HDRI off.
  - STATED, [soft GFX lighting](https://devforum.roblox.com/t/making-soft-and-good-gfx-lighting/1264771):
    - two emission planes, hidden from the camera, placed round the character, the second in another colour at the same strength;
    - a fully black background;
    - no auto smooth or subdivision, so the shadows stay soft and right;
    - Cycles.
- **The render:** Cycles on the GPU, 500 samples, rendered at twice the size and downscaled (the advertisement tutorial, STATED).
- **The finish, in layers:**
  - contrast and levels;
  - a background photo with a Gaussian blur;
  - faint orange and blue gradients in Soft Light;
  - dust and smoke in Overlay or Screen, masked down;
  - "font choice is the most important part", with a texture over the text.
  - All STATED, the advertisement tutorial.
- **Rim lines by hand:** stroke the figure's edge with a hard round brush of about 6 px, with an outer glow (OPINION, a commenter in [rim lighting in GFX](https://devforum.roblox.com/t/how-do-i-achieve-rim-lighting-in-gfx/1162635)).
- **The anime look** (OPINION, [anime-style GFX](https://devforum.roblox.com/t/how-to-make-anime-style-gfx/1533816), a commenter's guess):
  - the render with hand-drawn hair and face over it;
  - a layered background;
  - a light beam over everything;
  - motion blur on everything but the character.
- **Not stated in any of the five:** the lens, the depth of field's f-stop, and the bloom's settings.

## What we can do, and what we can't (DESIGN)

- **Within our own Blender and code (rule 2), all of it but the hand-drawn strokes:**
  - our own player, posed;
  - a light behind for the rim, and emission planes in two colours;
  - Cycles, rendered large and downscaled;
  - in code: the glow behind the centre, the blurred backdrop, the gradients, the speed lines and the motion blur on everything but the figure, the logotype.
  - The rim line can be drawn in code from the render's own figure mask: an edge, widened, in a light colour, with a glow.
- **What code doesn't reach:** an illustrator's hand-painted hair, face and brush texture, the painted anime icons' level (Sailor Piece, Anime Vanguards). That's the case for rule 2's new line on AI-made 2D art, which research runs, not this pipeline.
- **For icon C's remake** (the director's pick, 23:15: the player smashing a Void Shard, a Voidkin rising out of the crack as a glowing silhouette of light). Gemini's and Codex's reads go into it:
  - a hard rim from behind;
  - a darker, blurred backdrop;
  - the brightest glow at the point of contact, near the face;
  - a read at 64 px without the logotype.
