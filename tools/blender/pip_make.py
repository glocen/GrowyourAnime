"""Pip in the make (docs/requests/AR63.md): the picked take, A the first-year (research's pick, 2026-11-24, 14:20), as
the files the builder installs. The design is pip_make_takes.py's `take_a`, with what the finish adds:
- his own face (the director, 2026-11-27, 12:47: "voidkin shouldnt have the same face"): two for research's pick,
  `face_eager` and `face_set`, beside Rook's (the kit's) and Kirra's (the cut);
- the hair laid on a scalp fitted to his head, its rim tucked in, as Kirra's (AR60, 2026-11-27);
- the lantern as one piece that reads at 64 px beside the hat (research's must-fix): the takes' dark iron cage, a size
  up, its panes lit from inside with the flame's shape glowing through each. The game draws no glass to see through
  (tools/studio/ModelRecipe.luau sets no transparency), so the flame is in the panes. Its glow is the Emissive map's;
  its strength is the game's to play (COLD at rest, HOT through the send).

He keeps the first Pip's joints (pip_model.py), so his clips (pip_clips.py) still work them: the hat on a Motor6D "Hat"
on the Head at the first pivot, the lantern on "Lamp" on the Torso at its rest beside his right shoulder.

    blender.exe -b --factory-startup --python tools/blender/pip_make.py -- <out_dir> targets [takes] [sheet]
    blender.exe -b --factory-startup --python tools/blender/pip_make.py -- <out_dir> model [1|2]
    blender.exe -b --factory-startup --python tools/blender/pip_make.py -- <out_dir> sheet

`targets` draws Rook, Kirra, Pip today and the finish with each face, and lays pip_faces.png: the faces at the lead
card's size, and the lantern at the game's camera and at 64 px. `model` builds the picked face and writes
<out_dir>/handoff (Pip_Color.png, Pip_Roughness.png, Pip_Emissive.png, a mesh a piece and Pip.recipe.json, as
ModelRecipe.luau reads them) and <out_dir>/handoff/model/pip_model.blend, which pip_clips.py reads (PIP_MODEL=<that
folder>). `sheet` lays pip_make_sheet.png from those files.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
from anime_make import INK, mix, tone  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import pip_make_takes as pt  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_sheet as rs  # noqa: E402

NAME, TAKE = "Pip", "A"
HAT_PIVOT = (0.0, 0.0, 4.95)   # the first Pip's hat joint, on the Head (pip_model.py): the clips turn the hat about it
HOME = (2.75, 0.3, 4.3)        # the first Pip's lantern joint, on the Torso: its rest and the flame's middle (pip_clips.HOME)
LAMP = 1.65                    # the lantern's size: the takes' 1.35 read small at 64 px; 1.65 is the first Pip's height
COLD, HOT = 1.2, 3.0           # its glow at rest and through Lantern Burst's send (the first Pip's)
SKIN = "#F3D2B8"               # take A's


# --- his face: two for research's pick ---------------------------------------------------------------------------------
# Rook's (the kit's) is a rounded lid over a round iris with two lights, a crease, a lower lash, a ticked nose; Kirra's
# (the cut) narrow almond eyes, a lash running out into a wing, a mark under her eye. His are a boy's, each its own.

def eye_shape(p, upper, lower):
    return p.poly(np.vstack([am.smooth2(upper, 16), am.smooth2(lower, 16)[1:-1]]))


def nose(p, skin):
    p.lay(p.soft(p.poly([(0.004, 0.395), (0.03, 0.35), (-0.012, 0.345)]), 0.003), tone(skin, 0.74), 0.9)


def face_eager(p, skin, iris="#E08A2A", brow="#8A3E1C"):
    """1, the eager: big round eyes open wide, a tall iris warm at its foot with two big lights high on one side; a
    thick soft lash ending in a short tick down at the outer corner, no wing, no crease; a short lower lid under the
    middle; short thick brows set high and arched; freckles over his nose; a small open grin."""
    kt.face_skin(p, skin)
    ew, eh, ex, ey = 0.29, 0.27, 0.27, 0.5
    for s in (-1, 1):
        def at(lx, ly):
            return (s * (ex + lx), ey + ly)
        upper = [at(-ew / 2, -0.06 * eh), at(-0.3 * ew, 0.4 * eh), at(0.12 * ew, 0.52 * eh), at(ew / 2, 0.14 * eh)]
        lower = [at(ew / 2, 0.14 * eh), at(0.34 * ew, -0.36 * eh), at(-0.08 * ew, -0.5 * eh), at(-ew / 2, -0.06 * eh)]
        shape = eye_shape(p, upper, lower)
        p.lay(shape, "#F6F4F1")
        p.lay(shape * p.rise(ey + 0.1 * eh, ey + 0.5 * eh), "#C9B8A8", 0.6)
        cx, cy = s * (ex + 0.02 * ew), ey - 0.02 * eh
        rx, ry = 0.34 * ew, 0.6 * eh
        ir = np.minimum(p.ellipse(cx, cy, rx, ry), shape)
        p.lay(ir, iris)
        p.lay(ir * p.rise(cy, cy + 0.9 * ry), tone(iris, 0.42), 0.9)
        p.lay(np.minimum(p.ellipse(cx, cy - 0.5 * ry, rx * 0.7, ry * 0.34), ir), mix(iris, "#FFE7A8", 0.55), 0.85)
        p.lay(np.clip(ir - p.ellipse(cx, cy, rx * 0.86, ry * 0.9), 0, 1), tone(iris, 0.3), 0.9)
        p.lay(np.minimum(p.ellipse(cx, cy + 0.04 * ry, rx * 0.4, ry * 0.44), shape), tone(iris, 0.14))
        p.lay(np.minimum(p.ellipse(cx - 0.34 * rx, cy + 0.36 * ry, rx * 0.36, ry * 0.3), shape), "#FFFFFF")
        p.lay(np.minimum(p.ellipse(cx + 0.38 * rx, cy - 0.36 * ry, rx * 0.16, ry * 0.13), shape), "#FFFFFF", 0.9)
        p.lay(p.stroke(upper, (0.014, 0.036, 0.05, 0.042)), INK)
        p.lay(p.stroke([at(ew / 2 - 0.01, 0.16 * eh), at(ew / 2 + 0.035, 0.02 * eh)], (0.03, 0.006)), INK)
        p.lay(p.stroke([at(-0.14 * ew, -0.56 * eh), at(0.06 * ew, -0.6 * eh), at(0.24 * ew, -0.54 * eh)], (0.0, 0.012, 0.0)),
              tone(skin, 0.5), 0.7)
        p.lay(p.stroke([at(-0.36 * ew, 0.205), at(0.02 * ew, 0.24), at(0.4 * ew, 0.22)], (0.034, 0.04, 0.012)), brow)
        for fx, fy in ((0.09, 0.36), (0.15, 0.375), (0.125, 0.33), (0.19, 0.35)):
            p.lay(p.ellipse(s * fx, fy, 0.009, 0.008), tone(skin, 0.68), 0.75)
    nose(p, skin)
    grin = p.poly(np.vstack([am.smooth2([(-0.055, 0.25), (0.0, 0.246), (0.055, 0.252)], 10),
                             am.smooth2([(0.055, 0.252), (0.03, 0.212), (-0.025, 0.21), (-0.055, 0.25)], 12)[1:-1]]))
    p.lay(grin, "#6E2A26")
    p.lay(np.minimum(p.ellipse(0.004, 0.214, 0.03, 0.016), grin), "#C9605A")
    p.lay(p.stroke([(-0.058, 0.252), (0.0, 0.247), (0.058, 0.254)], (0.004, 0.01, 0.004)), tone(skin, 0.38))


def face_set(p, skin, iris="#E08A2A", brow="#8A3E1C"):
    """2, the set: a level lid low over a round iris, set on what he means to do, one small square light; a heavy
    straight lash with a short flick out at the corner; a full lower lash; thick straight brows pulled down to the
    middle; a pressed mouth, one corner up."""
    kt.face_skin(p, skin)
    ew, eh, ex, ey = 0.32, 0.2, 0.27, 0.5
    for s in (-1, 1):
        def at(lx, ly):
            return (s * (ex + lx), ey + ly)
        upper = [at(-ew / 2, 0.02 * eh), at(-0.26 * ew, 0.44 * eh), at(0.2 * ew, 0.46 * eh), at(ew / 2, 0.3 * eh)]
        lower = [at(ew / 2, 0.3 * eh), at(0.34 * ew, -0.3 * eh), at(-0.1 * ew, -0.52 * eh), at(-ew / 2, 0.02 * eh)]
        shape = eye_shape(p, upper, lower)
        p.lay(shape, "#F4F3F2")
        cx, cy = s * (ex + 0.03 * ew), ey - 0.06 * eh
        rx, ry = 0.3 * ew, 0.66 * eh
        ir = np.minimum(p.ellipse(cx, cy, rx, ry), shape)
        p.lay(ir, iris)
        p.lay(ir * p.rise(cy, cy + 0.7 * ry), tone(iris, 0.3), 0.95)
        p.lay(np.minimum(p.ellipse(cx, cy - 0.45 * ry, rx * 0.66, ry * 0.3), ir), mix(iris, "#FFE7A8", 0.5), 0.8)
        p.lay(np.clip(ir - p.ellipse(cx, cy, rx * 0.86, ry * 0.9), 0, 1), tone(iris, 0.28), 0.9)
        p.lay(np.minimum(p.ellipse(cx, cy + 0.02 * ry, rx * 0.36, ry * 0.46), shape), tone(iris, 0.12))
        p.lay(np.minimum(p.ellipse(cx - 0.3 * rx, cy + 0.2 * ry, rx * 0.18, ry * 0.18, turn=45), shape), "#FFFFFF")
        p.lay(shape * p.rise(ey + 0.1 * eh, ey + 0.46 * eh), "#2A2230", 0.3)
        p.lay(p.stroke(upper + [at(ew / 2 + 0.05, 0.42 * eh)], (0.02, 0.044, 0.05, 0.04, 0.0), n=40), INK)
        p.lay(p.stroke(lower[:3], (0.0, 0.012, 0.018)), INK, 0.7)
        p.lay(p.stroke([at(-0.5 * ew, 0.12), at(0.05 * ew, 0.15), at(0.56 * ew, 0.172)], (0.042, 0.042, 0.03)), brow)
    nose(p, skin)
    p.lay(p.stroke([(-0.045, 0.232), (0.0, 0.229), (0.035, 0.234), (0.056, 0.246)], (0.006, 0.016, 0.014, 0.004)), tone(skin, 0.38))


FACES = {"1": ("1, the eager", face_eager), "2": ("2, the set", face_set)}
PICK = dict(face="1")   # research's pick of FACES (2026-11-28, AR63): 1, the eager


# --- the lantern -----------------------------------------------------------------------------------------------------

class LitBuilt(am.Built):
    """A built piece some of whose colours glow: `lit(colour, k)` marks a colour's glow, 0 to 1, as the Emissive map's
    mask holds it."""

    def __init__(self, name):
        super().__init__(name)
        self.hot = {}

    def lit(self, colour, k):
        self.hot[self._cell(colour)] = k
        return colour

    def build(self, folder):
        obj = super().build(folder)
        mask = np.zeros(am.PICTURES[obj.name].shape[:2], np.float32)
        c, a = self.CELL, self.ACROSS
        for i, k in self.hot.items():
            mask[(i // a) * c:(i // a + 1) * c, (i % a) * c:(i % a + 1) * c] = k
        am.GLOWS[obj.name] = mask
        return obj


def hex_ring(c, r, z, n, sub):
    """`n` corners as pip_make_takes.ring lays them, each side cut in `sub`: a pane's columns."""
    corners = pt.ring(c, r, z, n)
    return [corners[j].lerp(corners[(j + 1) % n], t / sub) for j in range(n) for t in range(sub)]


ROWS, COLUMNS = 10, 3   # each pane's cells, its foot to its top and across


def heat(u, v):
    """The flame's light through a pane, 0 to 1: `u` up it (0 to 1), `v` across (-1 to 1). Hottest a third of the way
    up and in the middle, cooling to its top; frosted glass, so it runs smooth, never a drawn flame in stripes."""
    rise = 0.55 + 0.45 * u / 0.35 if u < 0.35 else 1.0 - 0.7 * ((u - 0.35) / 0.65) ** 1.3
    return round((0.22 + 0.78 * rise) * (1.0 - 0.16 * abs(v)), 2)


GLASS = ((0.22, "#9C4A22"), (0.45, "#D9662A"), (0.65, pt.FLAME[2]), (0.82, pt.FLAME[1]), (1.0, pt.FLAME[0]))


def glass_colour(h):
    for (h0, c0), (h1, c1) in zip(GLASS, GLASS[1:]):
        if h <= h1:
            return mix(c0, c1, max(0.0, (h - h0) / (h1 - h0)))
    return GLASS[-1][1]


def lamp(at=HOME, size=LAMP):
    """His lantern as one piece: the takes' iron cage (pip_make_takes.lantern), and six panes lit from inside, the
    flame's teardrop glowing through each, hottest a third of the way up its middle."""
    c, S, n = Vector(at), size, 6
    b = LitBuilt("Lamp")
    iron, iron_lit = pt.IRON, pt.IRON_LIT
    shade = pt.lit_round(iron, n, low=0.8, high=1.6)
    base = [pt.ring(c, 0.1 * S, c.z - 0.36 * S, n), pt.ring(c, 0.2 * S, c.z - 0.32 * S, n), pt.ring(c, 0.25 * S, c.z - 0.27 * S, n),
            pt.ring(c, 0.25 * S, c.z - 0.22 * S, n), pt.ring(c, 0.2 * S, c.z - 0.2 * S, n)]
    b.tube(base, lambda i, k: shade(k) if i != 2 else tone(iron_lit, 1.1), caps=(tone(iron, 0.6), tone(iron, 0.9)), smooth=False)
    for q in pt.ring(c, 0.205 * S, 0.0, n):
        pt.bar(b, (q.x, q.y, c.z), -0.2 * S, 0.22 * S, iron_lit, 0.03 * S)
    mid = [pt.ring(c, 0.215 * S, c.z - 0.01 * S, n), pt.ring(c, 0.215 * S, c.z + 0.02 * S, n)]
    b.tube(mid, lambda i, k: shade(k), caps=None, smooth=False)
    cap = [pt.ring(c, 0.2 * S, c.z + 0.22 * S, n), pt.ring(c, 0.27 * S, c.z + 0.25 * S, n), pt.ring(c, 0.26 * S, c.z + 0.29 * S, n),
           pt.ring(c, 0.12 * S, c.z + 0.42 * S, n), pt.ring(c, 0.05 * S, c.z + 0.47 * S, n), pt.ring(c, 0.06 * S, c.z + 0.5 * S, n),
           pt.ring(c, 0.0, c.z + 0.53 * S, n)]
    b.tube(cap, lambda i, k: tone(iron_lit, 1.05) if i == 1 else shade(k), caps=(tone(iron, 0.6), None), smooth=False)
    pt.torus(b, (c.x, c.y, c.z + 0.6 * S), 0.07 * S, 0.016 * S, iron_lit)
    z0, z1 = c.z - 0.2 * S, c.z + 0.22 * S
    panes = [hex_ring(c, 0.197 * S, z0 + (z1 - z0) * i / ROWS, n, COLUMNS) for i in range(ROWS + 1)]

    def glass(i, k):
        h = heat((i + 0.5) / ROWS, ((k % COLUMNS) + 0.5) / COLUMNS * 2 - 1)
        return b.lit(glass_colour(h), h)

    b.tube(panes, glass, caps=None, smooth=False)
    return [b]


def emit(material, mask_path, strength):
    """The glow in our own pictures, as the game draws it: the colour map times the mask, at `strength`."""
    tree = material.node_tree
    bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    colour = next(link.from_node for link in tree.links if link.to_socket == bsdf.inputs["Base Color"])
    mask = tree.nodes.new("ShaderNodeTexImage")
    mask.image = bpy.data.images.load(str(mask_path))
    mask.image.colorspace_settings.name = "Non-Color"
    mask.interpolation = colour.interpolation
    times = tree.nodes.new("ShaderNodeVectorMath")
    times.operation = "MULTIPLY"
    tree.links.new(colour.outputs["Color"], times.inputs[0])
    tree.links.new(mask.outputs["Color"], times.inputs[1])
    tree.links.new(times.outputs["Vector"], bsdf.inputs["Emission Color" if "Emission Color" in bsdf.inputs else "Emission"])
    bsdf.inputs["Emission Strength"].default_value = strength


def hair_shadow(made, colour, drop=0.045, soft=0.02, alpha=0.75):
    """The hair's own outline cast on his head's picture, `drop` studs under it and softened: each lock leaves a shade
    on the skin just below its edge, so the hair lies on his head instead of stopping on it (the director, on art that
    must be composited: layers bound by edge and shadow). The head's picture is drawn again with it."""
    head, hair = made["head"], made["hair"]
    px = am.PICTURES[head.name]
    p = am.Paint(px, -math.pi * am.R, 2 * math.pi * am.R, 1.25)
    v = np.array([hair.matrix_world @ q.co for q in hair.data.vertices])
    r = np.hypot(v[:, 0], v[:, 1])
    x, y = np.arctan2(-v[:, 0], v[:, 1]) * am.R, v[:, 2] - am.CHIN - drop   # where on the head's picture
    cover = np.zeros(px.shape[:2], np.float32)
    for f in hair.data.polygons:
        ids = list(f.vertices)
        if r[ids].min() > am.R + 0.2 or np.ptp(x[ids]) > math.pi * am.R:   # off the head, or across the picture's seam
            continue
        for i in range(1, len(ids) - 1):
            (x0, y0), (x1, y1), (x2, y2) = ((x[j], y[j]) for j in (ids[0], ids[i], ids[i + 1]))
            d = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
            if abs(d) < 1e-9:
                continue
            win = p._win(min(x0, x1, x2), max(x0, x1, x2), min(y0, y1, y2), max(y0, y1, y2))
            X, Y = p.X[win], p.Y[win]
            l0 = ((y1 - y2) * (X - x2) + (x2 - x1) * (Y - y2)) / d
            l1 = ((y2 - y0) * (X - x2) + (x0 - x2) * (Y - y2)) / d
            cover[win] = np.maximum(cover[win], ((l0 >= 0) & (l1 >= 0) & (l0 + l1 <= 1)).astype(np.float32))
    p.lay(am.blur(cover, soft * p.k), colour, alpha)
    tex = next(n for n in head.active_material.node_tree.nodes if n.type == "TEX_IMAGE")
    rs.save(np.dstack([np.clip(px, 0, 1), np.ones(px.shape[:2], np.float32)]), Path(bpy.path.abspath(tex.image.filepath)))
    tex.image.reload()


def take(face_draw):
    """Take A as the finish makes it: `face_draw` his face, the fitted hair casting on his head, the lantern lit
    through its panes."""
    def made(joints, folder):
        figure = pt.take_a(joints, folder, face_draw=face_draw, fitted=True, lamp=lamp)
        hair_shadow(figure, mix(SKIN, "#B5654F", 0.4))
        obj = figure["Lamp"]
        path = folder / "Lamp_glow.png"
        mask = am.GLOWS[obj.name]
        rs.save(np.dstack([mask, mask, mask, np.ones_like(mask)]), path)
        emit(obj.active_material, path, COLD)
        return figure
    return made


# --- the files for the install -----------------------------------------------------------------------------------------

def turn(q):
    return [round(q[0], 4), round(q[2], 4), round(-q[1], 4)]   # the kit's frame to Roblox's


def points():
    return [("Lantern", f"{NAME}_Lamp", HOME, "the flame's middle: where the burst's light starts"),
            ("Sleeve", "Right Arm", (1.5, 0.0, 2.0), "the right cuff's opening: the send's line starts here"),
            ("Chest", "Torso", (0.0, 0.6, 3.2), "where a hit lands")]


def recipe_joints(recipe):
    """The first Pip's two joints, his clips' (pip_model.py's recipe), on the new pieces; his glow as the first's."""
    for entry in recipe["pieces"]:
        piece = entry["name"][len(NAME) + 1:]
        if piece == "Hat":
            entry.update({"motor": "Hat", "pivot": turn(HAT_PIVOT)})
        elif piece == "Lamp":
            entry.update({"motor": "Lamp", "pivot": turn(HOME)})
    recipe["motors"] = {
        "Hat": {"note": "Turns about its pivot on the head: it lags every move and lifts on the send. Its rest tilt is in "
                        "the mesh. CastShadow off on this piece, or the brim puts his face in the dark."},
        "Lamp": {"note": "Floats beside his right shoulder, held by nothing. Its joint is on the Torso, and the clips move and "
                         "turn it; Lantern Burst sends it. CastShadow off: it's a light. A light in the tint around it is "
                         "the builder's call, tuned in the engine."}}
    recipe["stride"] = {"degrees": 25, "note": "the clips keep the first Pip's 25 degrees a leg; his trousers would allow more"}
    recipe["emissive"].update({
        "tint": "#FFFFFF", "cold": COLD, "hot": HOT,
        "note": "The mask covers the lantern's panes, the flame seen through them, and nothing else. It burns at cold as it "
                "floats and goes to hot through Lantern Burst's send. The face and the eyes take no glow, ever. The tint is "
                "white because Roblox multiplies the glow by the colour map, which already holds the flame's orange."})
    return recipe


def finish(key, made, out):
    hand = out / "handoff"
    recipe = am.handoff(NAME, made, hand, points(), tint="#FFFFFF", hot=HOT,
                        extra={"Hat": ("Hat", "Head"), "Lamp": ("Lamp", "Torso")},
                        make="tools/blender/anime_make.py and pip_make.py: R6's own blocks and round head with the clothes and "
                             "the face drawn on them, the hair one mesh; built pieces: the hat and the lantern, each on a joint "
                             "of its own (the first Pip's).")
    (hand / f"{NAME}.recipe.json").write_text(json.dumps(recipe_joints(recipe), indent=1))
    emit(made["torso"].active_material, hand / f"{NAME}_Emissive.png", COLD)   # one material for every piece
    folder = hand / "model"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / f"{NAME}.recipe.json").write_text((hand / f"{NAME}.recipe.json").read_text())
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / "pip_model.blend"), copy=True)
    pt.measured(key, made)


def model_run(out):
    rmt.TAKES[TAKE] = take(FACES[PICK["face"]][1])
    rmt.takes_run(out, [TAKE], finish=lambda key, made: finish(key, made, out))


def sheet_run(out):
    if not (out / "layers" / "Shade_foe.npz").exists():
        rmt.shade_run(out)
    rmt.proof_run(out, TAKE, title="PIP IN THE MAKE: THE MODEL FOR THE INSTALL", about="Common / Purple / Mage / Fire.",
                  whose="his", stem="pip_make", beside=list(kt.BESIDE), tag="AR63: the finish")
    proof = rs.load(out / "pip_make.png")
    recipe = json.loads((out / "handoff" / f"{NAME}.recipe.json").read_text())
    gap, W, side = 24, proof.shape[1], 560
    ink, soft, paper = "#EDE6D6", "#B4AC9C", "#101117"
    low = rs.canvas(W, 60 + side + 30, rs.rgb(paper))
    text = [(gap, 14, 18, "What goes up: the one picture every piece wears, at 0.55 of its size, and the glow's mask beside it.",
             ink)]
    x = gap
    for kind in ("Color", "Emissive"):
        rs.paste(low, rs.shrink(rs.load(out / "handoff" / recipe["maps"][kind]), side / am.ATLAS), x, 50)
        text.append((x, 50 + side + 8, 14, recipe["maps"][kind], soft))
        x += side + gap
    facts = [f"{recipe['tris']} triangles in {len(recipe['pieces'])} pieces", f"{recipe['texels_per_stud']} texels a stud on the body",
             "pieces: " + ", ".join(f"{p['name'][len(NAME) + 1:]} {p['tris']}" for p in recipe["pieces"]),
             "joints of their own: Hat (on the Head), Lamp (on the Torso), the first Pip's",
             f"the glow: the lantern's panes, {COLD} at rest, {HOT} through the send",
             "points: " + ", ".join(p["name"] for p in recipe["points"])]
    text += [(x, 60 + i * 24, 15, line, soft) for i, line in enumerate(facts)]
    rs.paste(low, rs.text_layer(W, low.shape[0], text), 0, 0)
    whole = rs.canvas(W, proof.shape[0] + low.shape[0], rs.rgb(paper))
    whole[:proof.shape[0]], whole[proof.shape[0]:] = proof, low
    rs.save(whole, (out / "pip_make_sheet.png").resolve())


# --- the faces' targets ------------------------------------------------------------------------------------------------

def targets_run(out, keys):
    import kirra_make as km
    rmt.TAKES = {"Rook": kt.TAKES["Rook"], "Kirra": lambda j, f: kt.take_a(j, f, pieces=km.made_pieces(), face_draw=kt.face_cut),
                 "A": pt.take_a, **{k: take(draw) for k, (_, draw) in FACES.items()}}
    rmt.SAID = {"Rook": ("Rook", ("the kit's face",)), "Kirra": ("Kirra", ("the cut",)), "A": ("Pip today", ("the kit's face",)),
                **{k: (said, ("",)) for k, (said, _) in FACES.items()}}
    rmt.WHO = tuple(rmt.TAKES)
    if "takes" in keys:
        rmt.takes_run(out, [k for k in keys if k in rmt.WHO] or list(rmt.WHO), finish=pt.measured)
    if "sheet" in keys:
        faces_sheet(out)


def faces_sheet(out):
    """The faces in the lead card's pose (half size, then the card's size on the smallest phone and twice it); then Pip
    today and the finish from the game's camera, and at 64 px over dark: the lantern beside the hat."""
    shots = out / "shots"
    gap, W = 24, 1900
    ink, soft, paper = "#EDE6D6", "#B4AC9C", "#101117"
    who = [("Rook", "Rook, the kit's"), ("Kirra", "Kirra, the cut"), ("A", "Pip today, the kit's")] + \
          [(k, f"Pip {said}") for k, (said, _) in FACES.items()]
    busts = [(said, rs.load(shots / f"{k}_bust.png")) for k, said in who]
    half_h = rs.shrink(busts[0][1], 0.5).shape[0]
    games = [(said, rs.trim(rs.load(shots / f"{k}_game.png"))) for k, said in who[2:]]
    gk = 0.5
    game_h = max(rs.shrink(t, gk).shape[0] for _, t in games)
    page = rs.canvas(W, 56 + half_h + 12 + 220 + 60 + 40 + game_h + 40, rs.rgb(paper))
    text = [(gap, 16, 20, "AR63: Pip's own face, two for research's pick, beside Rook's and Kirra's. The lead card's pose: half "
                          "size, then the card's size on the smallest phone and twice it.", ink)]
    x = gap
    for said, img in busts:
        half = rs.shrink(img, 0.5)
        rs.paste(page, half, x, 56)
        small, twice = rs.shrink(img, rmt.CARD), rs.shrink(img, rmt.CARD * 2)
        rs.paste(page, small, x, 56 + half.shape[0] + 12)
        rs.paste(page, twice, x + small.shape[1] + 10, 56 + half.shape[0] + 12)
        text.append((x, 56 + half.shape[0] + 12 + twice.shape[0] + 8, 14, said, soft))
        x += half.shape[1] + gap
    y = 56 + half_h + 12 + 220 + 60
    text.append((gap, y, 18, "The game's camera, half size, then at 64 px high and that three times: the lantern beside the hat. "
                             "Today's, then the finish's, a size up, its panes lit (the same in 1 and 2), the hair fitted.", ink))
    x = gap
    for said, t in games:
        g = rs.shrink(t, gk)
        rs.paste(page, g, x, y + 36)
        tiny = rs.shrink(t, 64 / t.shape[0])
        rs.paste(page, tiny, x + g.shape[1] + 10, y + 36 + g.shape[0] - tiny.shape[0])
        zoom = np.repeat(np.repeat(tiny, 3, axis=0), 3, axis=1)   # the 64 px read, three times, its pixels kept
        rs.paste(page, zoom, x + g.shape[1] + tiny.shape[1] + 20, y + 36 + g.shape[0] - zoom.shape[0])
        text.append((x, y + 36 + game_h + 6, 14, said + "; at 64 px, then that x3", soft))
        x += g.shape[1] + tiny.shape[1] + zoom.shape[1] + gap * 2
    rs.paste(page, rs.text_layer(W, page.shape[0], text), 0, 0)
    rs.save(page, (out / "pip_faces.png").resolve())


if __name__ == "__main__":
    rmt.TAKES, rmt.SAID, rmt.WHO = dict(pt.TAKES), dict(pt.SAID), tuple(pt.TAKES)
    rmt.SAID[TAKE] = ("Pip, the finish", ("A, the first-year (research's pick, 2026-11-24, 14:20)",))
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    if rest and rest[0] == "targets":
        targets_run(OUT, rest[1:] or ("takes", "sheet"))
    else:
        if len(rest) > 1 and rest[1] in FACES:   # a face in place of the pick, to try the files before it
            PICK["face"] = rest[1]
        {"model": model_run, "sheet": sheet_run}[rest[0] if rest else "model"](OUT)
