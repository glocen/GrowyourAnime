"""Haymaker's effect in its art, beside Rook's clip (AR1, delivery 4; handbook/visuals/vfx.md, the workflow's step 4).

blender.exe -b --factory-startup --python tools/blender/rook_haymaker_art.py -- <out_dir>

The block-in's thrown frame (rook_haymaker_fx.py, B: research dropped C's wake at the art sheet) with its one picture drawn:
- haymaker_bar.png: one bar, struck like a chisel's stroke, in three tones (a cream core, Rook's ember, an ink rim),
  and the eight frames in which it's eaten: from its ends and its slits first, in hard chips along its length.
  512 x 1024, the frames stacked from the top. Every element of the effect is this bar: the charge's square, the
  strike's square, the thrown bracket's posts and lintel, and the two lines scored on the floor.
- haymaker_art.png: the sheet. The frames on a dark and a bright ground and in grey, then the effect played at the
  block-in's numbers from the player's assumed camera, on a dark and a bright floor, from the side, and at 64 px.
The preview draws each bar as a flat picture in the scene, unlit, cut by its alpha. Workbench, so no GPU turn.
Stage directions as rook_clips.py: right, forward, up, in studs, from where he stands.
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_haymaker_fx as fx  # noqa: E402
import rook_sheet as rs  # noqa: E402

CORE, EMBER, RIM = "#FFF1CC", rs.PALETTE["Ember"], rs.PALETTE["Ink"]
FRAMES, FW, FH = 8, 512, 128
EATEN = (0.0, 0.07, 0.16, 0.28, 0.42, 0.57, 0.72, 0.86)  # the share of the bar that's gone, frame by frame
# How deep the ink rim runs, frame by frame. The last two are finer: there the chips are small, and at the target's
# depth a full rim round each read as a dark chain over the floor (AR1, section 8, the retake).
INK = (0.12, 0.12, 0.12, 0.12, 0.12, 0.12, 0.075, 0.05)
BODY, SPAN = 0.6, 0.92  # the share of a frame's height and of its width the whole stroke fills
# A tint multiplies the picture, as an ImageColor3 would: a scored line cools to a scorch.
TINTS = {"hot": (1.0, 1.0, 1.0), "cool": (0.34, 0.26, 0.3)}
LEAVES = 6  # frames the hero takes to be eaten, once it has flown: the end is as hard as the start
GAME_ROWS = ((40, 52, 56, 57, 58, 59, 60, 61), (62, 64, 66, 68, 70, 72, 74, 78))
BURST = (57, 58, 59, 60, 62, 66, 70, 74)


# --- the picture ----------------------------------------------------------------------------------------------

def bar_frames(seed=7):
    """The bar's eight frames, each FH x FW, straight alpha, row 0 at the top. One field says how deep a texel sits in
    the stroke (0 at an edge, 1 at its heart); a frame keeps what's deeper than its threshold, so the edges, the slits
    and the cracks between its chips go first, and the tones follow the edge inward: as it's eaten it cools, from the
    core to the ember to the rim."""
    k = 2
    w, h = FW * k, FH * k
    u = (np.arange(w) + 0.5) / w
    v = 1 - (np.arange(h) + 0.5) / h * 2
    U, V = np.meshgrid(u, v)
    rng = np.random.default_rng(seed)

    def cut(step, depth):  # an edge cut in straight strokes
        knots = np.arange(0, 1 + step, step)
        return np.interp(u, knots, BODY + rng.uniform(-depth, depth, len(knots)))

    deep = np.minimum(cut(0.09, 0.05)[None, :] - V, V + cut(0.12, 0.05)[None, :]) / BODY * 2.2
    left, right = 0.03 + 0.04 * (V + 1) / 2, 0.93 + 0.04 * (V + 1) / 2  # both ends are cut on the slant
    deep = np.minimum(deep, np.minimum(U - left, right - U) / 0.07)
    # the slits: three thin wedges run in from the ends
    for end, at, length, width in ((0, 0.2, 0.26, 0.05), (1, -0.14, 0.32, 0.05), (1, 0.34, 0.14, 0.04)):
        along = (U - left) if end == 0 else (right - U)
        deep = np.minimum(deep, (np.abs(V - at) - width * (1 - along / length)) / 0.16)
    # the chips: slanted blocks in two rows, each with its own share, and the cracks between them open first
    size = 0.085
    knots = np.linspace(-0.1, 1.1, 15)
    steps = np.concatenate([[0.0], np.cumsum(rng.uniform(0.45, 1.6, len(knots) - 1))])  # no two chips the same length
    middle = np.interp(u, np.linspace(0, 1, 9), rng.uniform(-0.2, 0.2, 9))[None, :]  # where the two rows part
    row = (V > middle).astype(int)
    across = np.interp(U + 0.07 * V, knots, steps) + row * 0.5
    ci = np.floor(across).astype(int)
    crack = np.minimum(np.abs(across - np.round(across)) * size / 0.03, np.abs(V - middle) / 0.09)
    deep = np.minimum(np.clip(deep, 0, 1), 0.3 + 0.7 * crack) * rng.uniform(0.5, 1.0, (64, 2))[ci % 64, row]
    drawn = deep[deep > 0]
    rim, ember, core = (np.array(rs.rgb(c), dtype=np.float32) for c in (RIM, EMBER, CORE))
    frames = []
    for gone, ink in zip(EATEN, INK):
        left_in = deep - (np.quantile(drawn, gone) if gone else 0.0)
        frame = np.empty((h, w, 4), dtype=np.float32)
        frame[..., :3] = np.where((left_in < ink)[..., None], rim, np.where((left_in < 0.34)[..., None], ember, core))
        frame[..., 3] = left_in > 0
        frame = rs.shrink(frame, 1 / k)
        frame[..., :3] = np.where(frame[..., 3:] > 1e-6, frame[..., :3], rim)  # an empty texel keeps the rim's colour
        frames.append(frame)
    return frames


def picture(name, sheet):
    """A material that shows `sheet` (rows from the top) unlit and cut by its alpha."""
    h, w = sheet.shape[:2]
    image = bpy.data.images.new(name, w, h, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(sheet[::-1]).ravel())
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    bsdf = nodes.get("Principled BSDF")
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    nodes.active = tex
    return material


# --- the effect, frame by frame ---------------------------------------------------------------------------------

def art(line, f):
    """Every bar drawn on frame `f`: (tint, where it lies, which of its eight frames)."""
    out = []
    lean_sin, lean_cos = math.sin(fx.LEAN), math.cos(fx.LEAN)

    def up(tint, x, y, z, length, bar, roll, frame, lean=fx.LEAN):
        out.append((tint, Matrix.Translation((x, y, z)) @ Matrix.Rotation(-lean, 4, "X") @ Matrix.Rotation(math.radians(roll), 4, "Y")
                    @ Matrix.Diagonal((length / SPAN, 1, bar / BODY, 1)), frame))

    def bracket(tint, s, frame, tall=1.0, thick=1.0, opens=1.0, lift=0.0, add=0.0):
        (x, y), (w, h, bar) = line.at(s), line.size(s)
        w, h, bar = w * opens, h * tall * opens, (bar + add) * thick
        low = h * lift
        z = low + (h - low) / 2
        for side in (-1, 1):
            up(tint, x + side * w / 2, y + z * lean_sin, z * lean_cos, h - low + bar, bar, 90, frame)
        up(tint, x, y + h * lean_sin, h * lean_cos, w + bar, bar, 0, frame)  # flush at the corners: a bracket, not a gate

    # the punctuation: the charge's square thrown open round the ram, for the strike's frame and the next
    if f in (fx.STRIKE, fx.SHOCK):
        side, bar, frame = (3.0, 0.8, 0) if f == fx.STRIKE else (3.7, 0.7, 3)
        for sign in (-1, 1):
            up("hot", line.x, line.y + 0.3, line.z + sign * side / 2, side + bar, bar, 0, frame, lean=0)
            up("hot", line.x + sign * side / 2, line.y + 0.3, line.z, side + bar, bar, 90, frame, lean=0)
    # the hero: one bracket thrown down the line. It boils between its first two frames while it flies, then is eaten.
    if fx.SHOCK < f <= fx.SHOCK + fx.FLY + LEAVES:
        leaves = fx.clamp((f - fx.SHOCK - fx.FLY) / LEAVES)
        frame = f % 2 if leaves == 0 else min(7, 1 + round(leaves * 6))
        bracket("hot", fx.far(f), frame, opens=1 + 0.06 * leaves, lift=0.3 * leaves ** 2, add=0.1)
    # the ground mark: two lines scored under the posts, hot for three frames, then a scorch that's eaten from the near end
    pieces = 6
    for i in range(pieces):
        a = i / pieces
        age = f - next(frame for frame in range(fx.SHOCK, fx.SHOCK + 60) if fx.far(frame) > a)
        b = min((i + 1) / pieces, fx.far(f)) if age >= 0 else a
        if b - a < 0.01 or age > 11:
            continue
        for side in (-1, 1):
            (xa, ya), (xb, yb) = line.at(a), line.at(b)
            xa, xb = xa + side * line.size(a)[0] / 2, xb + side * line.size(b)[0] / 2
            out.append(("hot" if age < 3 else "cool",
                        Matrix.Translation(((xa + xb) / 2, (ya + yb) / 2, 0.03)) @ Matrix.Rotation(math.atan2(yb - ya, xb - xa), 4, "Z")
                        @ Matrix.Rotation(math.pi / 2, 4, "X") @ Matrix.Diagonal((math.hypot(xb - xa, yb - ya) / SPAN + 0.3, 1, 0.5 / BODY, 1)),
                        0 if age < 4 else age - 4))
    return out


class Stage(fx.Stage):
    """The block-in's stage with its boxes put away and the bars drawn as pictures."""

    def __init__(self, scene, rig, line, sheet):
        super().__init__(scene, rig, line)
        for bar in self.ring:
            bar.hide_render = True
        self.show = True
        self.pictures = {tint: picture(f"Fx.{tint}", sheet * np.array((*colour, 1), dtype=np.float32)) for tint, colour in TINTS.items()}
        self.bars = {tint: [] for tint in TINTS}
        self.charge = [self.bar("hot") for _ in range(4)]
        for bar in self.charge:
            bar.parent = rig.parts["Right Arm"]

    def bar(self, tint):
        mesh = bpy.data.meshes.new("Fx.Bar")
        mesh.from_pydata([(-0.5, 0, -0.5), (0.5, 0, -0.5), (0.5, 0, 0.5), (-0.5, 0, 0.5)], [], [(0, 1, 2, 3)])
        mesh.uv_layers.new(name="UV")
        mesh.materials.append(self.pictures[tint])
        obj = bpy.data.objects.new("Fx.Bar", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    @staticmethod
    def frame(obj, k):
        v0, v1 = 1 - (k + 1) / FRAMES, 1 - k / FRAMES
        for loop, uv in zip(obj.data.uv_layers[0].data, ((0, v0), (1, v0), (1, v1), (0, v1))):
            loop.uv = uv

    def set(self, scene, *_):
        f = scene.frame_current
        used = {tint: 0 for tint in TINTS}
        for tint, matrix, k in (art(self.line, f) if self.show else ()):
            if used[tint] == len(self.bars[tint]):
                self.bars[tint].append(self.bar(tint))
            obj = self.bars[tint][used[tint]]
            used[tint] += 1
            obj.matrix_world, obj.hide_render = matrix, False
            self.frame(obj, k)
        for tint, n in used.items():
            for obj in self.bars[tint][n:]:
                obj.hide_render = True
        # The charge: the square forms out of its chips, is drawn tight onto the ram's face through the hold, and boils.
        start = fx.WIND - 6
        drawn = self.show and start <= f < fx.STRIKE
        side = 2.9 - 1.1 * fx.clamp((f - start) / (fx.HELD - start)) ** 2 - 0.1 * fx.clamp((f - fx.HELD) / 4)
        k = max(0, 7 - (f - start)) if f < start + 8 else f % 2
        for i, bar in enumerate(self.charge):
            across, sign = i < 2, 1 if i % 2 else -1
            bar.hide_render = not drawn
            at = Vector(fx.KNUCKLES) + (Vector((0, sign * side / 2, 0)) if across else Vector((sign * side / 2, 0, 0)))
            turn = Matrix.Rotation(-math.pi / 2, 4, "X")
            if not across:
                turn = Matrix.Rotation(math.pi / 2, 4, "Z") @ turn
            bar.matrix_basis = Matrix.Translation(at) @ turn @ Matrix.Diagonal(((side + 0.5) / SPAN, 1, 0.3 / BODY, 1))
            self.frame(bar, k)
        self.struck(f)


# --- the sheet --------------------------------------------------------------------------------------------------

def shoot(scene, stage, camera, f, label, size, out):
    """One tile: the clip shaded as ever, and the effect over it unlit, in its own colours. Three passes: the scene
    shaded without the effect, then flat with it and flat without, which tells the effect's pixels from the rest."""
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    shading = scene.display.shading
    path = out / "_tile.png"
    scene.render.filepath = str(path)
    passes = []
    for flat, show in ((False, False), (True, True), (True, False)):
        stage.show = show
        shading.light = "FLAT" if flat else "STUDIO"
        shading.show_shadows = shading.show_cavity = shading.show_object_outline = not flat
        scene.render.use_stamp = not flat
        scene.render.stamp_note_text = label
        scene.frame_set(f)
        bpy.ops.render.render(write_still=True)
        passes.append(rs.load(path))
    path.unlink()
    shaded, lit, bare = passes
    drawn = (np.abs(lit[..., :3] - bare[..., :3]).max(axis=-1) > 0.03)[..., None]
    return np.where(drawn, lit, shaded)


def main():
    out = bl.out_dir()
    rs.OUT = out
    frames = bar_frames()
    sheet = np.concatenate(frames, axis=0)
    rs.save(sheet, out / "haymaker_bar.png")
    print(f"wrote {out / 'haymaker_bar.png'} {sheet.shape[1]}x{sheet.shape[0]}")

    scene, rig, costume, undress, feet = rc.build()
    take = rc.Take(rig, feet, "Haymaker", 0)
    rc.haymaker(take)
    rc.ground(rig, feet, [take])
    scene.frame_set(fx.STRIKE)
    line = fx.Line(rig.parts["Right Arm"].matrix_world @ Vector(fx.KNUCKLES))
    stage = Stage(scene, rig, line, sheet)
    game = fx.camera(scene, "game", rc.GAME[0], rc.GAME[1], 15.5, (0.8, 4.2, 2.5), 46.0)
    side = fx.camera(scene, "side", 90.0, 6.0, 25.0, (0.0, 5.0, 2.6), 30.0)
    floor = bpy.data.objects["Floor"].data.materials[0]
    dark, bright = (0.16, 0.14, 0.17, 1), (0.74, 0.72, 0.68, 1)
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note, r.stamp_font_size = True, 20

    big, low, tiny = (236, 162), (236, 124), (93, 64)
    rows = [[shoot(scene, stage, game, f, fx.label(f), big, out) for f in row] for row in GAME_ROWS]
    rows.append([shoot(scene, stage, side, f, fx.label(f), low, out) for f in BURST])
    small = [[shoot(scene, stage, game, f, "", tiny, out) for f in BURST]]
    floor.diffuse_color = bright
    rows.append([shoot(scene, stage, game, f, fx.label(f), big, out) for f in BURST])
    small.append([shoot(scene, stage, game, f, "", tiny, out) for f in BURST])
    floor.diffuse_color = dark
    bpy.app.handlers.frame_change_pre.remove(stage.set)

    W, H = 1920, 1290
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 54, "HAYMAKER, THE ART", ink),
            (640, 34, 22, "One bar, drawn once. Everything in the effect is this bar: the charge, the strike's square, the thrown bracket, the floor's lines.", ink),
            (640, 64, 18, "A chisel's stroke in three tones: a cream core, Rook's ember, an ink rim that holds on a bright floor. It's eaten from its ends and slits, in hard chips along its length.", soft)]
    # the eight frames, on a dark ground, a bright one, and in grey
    x0, y = 40, 112
    for r_, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, x0, y + r_ * 62, 1840, 60, ground)
        for k, frame in enumerate(frames):
            small_frame = rs.shrink(frame, 0.44)
            rs.paste(page, rs.grey(small_frame) if grey else small_frame, x0 + 2 + k * 230, y + r_ * 62 + 2)
    for k in range(FRAMES):
        text.append((x0 + 4 + k * 230, y + 190, 14, f"frame {k}: {round(EATEN[k] * 100)}% eaten", soft))
    text.append((x0, y + 212, 14, "haymaker_bar.png, 512 x 1024, eight frames of 512 x 128 stacked from the top. The hero plays frames 0 and 1 in turn while it flies, then 1 to 7 over 6 frames. "
                 "A tint cools a scored line after three hot frames: x (0.34, 0.26, 0.30).", soft))
    # the effect, played
    y = 358
    text.append((x0, y, 20, "From the player's camera, on a dark floor (the clip's frames, 60 a second; Strike is 57)", ink))
    for i, row in enumerate(rows[:2]):
        for c, tile in enumerate(row):
            rs.paste(page, tile, x0 + c * 230, y + 28 + i * 166)
    y = 726
    text.append((x0, y, 20, "On a bright floor", ink))
    for c, tile in enumerate(rows[3]):
        rs.paste(page, tile, x0 + c * 230, y + 28)
    y = 926
    text.append((x0, y, 20, "From the side", ink))
    for c, tile in enumerate(rows[2]):
        rs.paste(page, tile, x0 + c * 230, y + 28)
    y = 1090
    text.append((x0, y, 20, "At 64 px, dark and bright, and in grey", ink))
    for i, row in enumerate(small):
        for c, tile in enumerate(row):
            rs.paste(page, tile, x0 + c * 97, y + 28 + i * 68)
            rs.paste(page, rs.grey(tile), x0 + 820 + c * 97, y + 28 + i * 68)
    for i, words in enumerate(("The stand-in body and the camera", "are the block-in's. The bars are", "drawn unlit, with no glow added:",
                               "the game's bloom, if any, is the", "builder's to add.")):
        text.append((1660, y + 30 + i * 20, 14, words, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "haymaker_art.png")
    print(f"wrote {out / 'haymaker_art.png'} {W}x{H}")


if __name__ == "__main__":
    main()
