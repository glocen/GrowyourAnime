"""Pip's design sheet (AR4, delivery 1): the apprentice, as a blockout on the R6 body.

blender.exe -b --factory-startup --python tools/blender/pip_sheet.py -- <out_dir> [small]

The idea: a hat with a boy under it, and the one spell he has, kept in a lantern. The hat is half his outline: its
brim hangs to his collar and its tip has fallen over to his left; the lantern floats at his right, so the two balance. The robe was cut for
someone taller: the sleeves hang past his hands and the collar stands to his chin. A book as big as his back is strapped
to it, which is what the player's camera sees. Workbench only, so no GPU turn. Studs, X right, Y forward, Z up, Pip
faces +Y, and every piece hangs from one of R6's six parts at the engine's own pivots, as rook_sheet.py's do (its
shapes and sheet tools are used here). The hat hangs from the head and the lantern is its own piece: both want to lag
in a clip. The flame's glow is drawn on the picture, as the Shade's light is.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

PALETTE = {
    "Inkwell": "#46348A", "InkwellDeep": "#2A1F56", "Chalk": "#EFE8D8", "ChalkShade": "#CDC3AC", "Flame": "#FF8A3D",
    "Brass": "#C2933F", "BrassDeep": "#8A6526", "Leather": "#7C4B2A", "LeatherLight": "#A06A3C",
    "Chestnut": "#4A2A1E", "Skin": "#E4B18C", "Ink": "#1E1B22", "Slate": "#2B2C38",
}
CHIPS = (("Inkwell", "the robe, the hat"), ("Chalk", "collar, cuffs, bands"), ("Flame", "the lantern"))
NEUTRALS = ("Brass", "Leather", "Chestnut", "Skin")
HAT = (0, 0, 4.95)  # where the hat sits on the head, and turns
LAMP = (2.75, 0.3, 4.3)  # the lantern's middle at rest: beside his right shoulder, at the height of his eyes
PIVOTS = dict(rs.PIVOTS, hat=HAT)
B = rs.B
loft, slab, hexa = rs.loft, rs.slab, rs.hexa


def materials():
    made = {}
    for name, code in {**PALETTE, "Glow": PALETTE["Flame"]}.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def tube(name, sections, material):
    """A bent taper, for the hat's fallen tip. Sections: (x, z of the middle, the half-width's x and z, half the depth)
    at the hat's own y."""
    y = -0.08
    made = []
    for (ax, az, aux, auz, ad), (bx, bz, bux, buz, bd) in zip(sections, sections[1:]):
        made.append(hexa(name, [(ax + aux, y - ad, az + auz), (ax + aux, y + ad, az + auz), (ax - aux, y + ad, az - auz), (ax - aux, y - ad, az - auz),
                                (bx + bux, y - bd, bz + buz), (bx + bux, y + bd, bz + buz), (bx - bux, y + bd, bz - buz), (bx - bux, y - bd, bz - buz)],
                         material))
    return made


def lantern(scene, m, hot):
    """The lantern: a brass cage round a flame, a peaked lid with a ring, two paper slips under it that trail when it
    moves. Hot, the flame fills the cage. Its own piece, at its own empty: it floats, and nothing holds it."""
    lx, ly, lz = LAMP
    k = 1.35 if hot else 1.0
    flame = [(lz - 0.3, 0.16), (lz - 0.17, 0.32 * k), (lz + 0.02, 0.28 * k), (lz + 0.2, 0.13 * k), (lz + 0.3, 0.03)]
    pieces = [
        bl.place(bl.cylinder("LampBase", 0.29, 0.1, 12, m["Brass"]), location=(lx, ly, lz - 0.4)),
        bl.place(bl.cylinder("LampFoot", 0.16, 0.08, 10, m["BrassDeep"]), location=(lx, ly, lz - 0.48)),
        *[slab("LampPost", (lx + a * 0.2, ly + b * 0.2, lz), (0.055, 0.055, 0.72), m["BrassDeep"]) for a in (-1, 1) for b in (-1, 1)],
        loft("LampLid", [(lz + 0.35, lx, ly, 0.74, 0.74), (lz + 0.42, lx, ly, 0.66, 0.66), (lz + 0.62, lx, ly, 0.16, 0.16)], m["Brass"], n=2),
        slab("LampRing", (lx, ly, lz + 0.7), (0.16, 0.05, 0.18), m["BrassDeep"]),
        loft("LampFlame", [(z, lx, ly, w, w) for z, w in flame], m["Glow"], n=2),
        slab("LampSlip", (lx - 0.07, ly, lz - 0.76), (0.13, 0.02, 0.5), m["Chalk"], rot=(0, 5, 0)),
        slab("LampSlip", (lx + 0.09, ly + 0.02, lz - 0.68), (0.11, 0.02, 0.32), m["ChalkShade"], rot=(0, -7, 0)),
    ]
    lamp = bpy.data.objects.new("lamp", None)
    scene.collection.objects.link(lamp)
    lamp.location = LAMP
    lamp.rotation_mode = "QUATERNION"
    for o in pieces:
        o.parent = lamp
        o.matrix_parent_inverse = Matrix.Translation(-Vector(LAMP))
    return lamp


def arc(a, b, c, d, steps):
    """Points along a cubic curve from a to d, drawn toward b and c."""
    a, b, c, d = (Vector(p) for p in (a, b, c, d))
    return [a * (1 - t) ** 3 + b * 3 * t * (1 - t) ** 2 + c * 3 * t * t * (1 - t) + d * t ** 3
            for t in (i / (steps - 1) for i in range(steps))]


# The robe's long folds, for the model: (the angle round him it runs down, front is 90; its width, degrees; the height
# it starts at). Each stands out more toward the hem. The sleeves' are round each sleeve's own middle, its outside at 0.
FOLDS = ((58, 6, 3.9), (113, 5, 3.3), (128, 6, 3.9), (27, 7, 3.0), (152, 7, 3.0), (-55, 6, 3.9), (-78, 5, 2.3), (-100, 5, 2.3),
         (-122, 6, 3.9))
SLEEVE_FOLDS = ((62, 9, 3.8), (-72, 9, 3.6), (4, 10, 3.2))
LOW = 1.3  # where a fold stands out fully


def fold(a, z, folds=FOLDS, shift=0.0):
    """How far the folds stand out at angle `a` (degrees) and height `z`, 0 to 1. `shift` reads it a fold's width or
    so to one side: the valley beside a fold. Numbers or arrays."""
    total = 0.0
    for i, (at, wide, top) in enumerate(folds):
        d = (a - at - 3.0 * np.sin(1.7 * z + i) + 180.0) % 360.0 - 180.0
        total = total + np.clip((top - z) / (top - LOW), 0.0, 1.0) ** 0.8 * np.exp(-((d / wide - shift) ** 2))
    return np.minimum(total, 1.0)


def cloth_value(a, z, folds=FOLDS):
    """What the colour map's cloth is multiplied by: lighter along a fold's top, darker in the valley each side."""
    ridge = fold(a, z, folds)
    valley = np.maximum(fold(a, z, folds, 1.6), fold(a, z, folds, -1.6)) * (1 - ridge)
    return 1 + 0.26 * ridge - 0.18 * valley


def bunch(a, z):
    """The robe stacked over its hem, added to cloth_value: a crease round it and the roll above, and a shorter crease
    higher up at his front."""
    at = 1.67 + 0.06 * np.sin(np.radians(3 * a + 40))
    low = 0.1 * np.exp(-((z - at - 0.11) / 0.07) ** 2) - 0.14 * np.exp(-((z - at) / 0.035) ** 2)
    high = 1.99 + 0.04 * np.sin(np.radians(2 * a))
    return low - 0.09 * np.exp(-((z - high) / 0.03) ** 2) * np.clip(np.sin(np.radians(a - 20)), 0.0, 1.0)


def pleated(name, rings, material, out=0.12, segs=56):
    """rook_sheet.loft for the robe: the same rings, their points spread evenly round them (a block's ring has none on
    its faces), each pushed out by the folds."""
    bm = bmesh.new()
    loops = []
    for z, cx, cy, w, d in rings:
        dense = list(rs.ring(cx, cy, w, d, B, 1440))
        run = [0.0]
        for (ax, ay, _), (bx, by, _) in zip(dense, dense[1:] + dense[:1]):
            run.append(run[-1] + math.hypot(bx - ax, by - ay))
        loop, k = [], 0
        for i in range(segs):
            while run[k + 1] < run[-1] * i / segs:
                k += 1
            x, y, t = dense[k]
            height = z(t) if callable(z) else z
            push = 1 + out * float(fold(math.degrees(math.atan2(y, x)), height)) / math.hypot(x, y)
            loop.append(bm.verts.new((x * push, y * push, height)))
        loops.append(loop)
    for a, b in zip(loops, loops[1:]):
        for k in range(segs):
            bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
    bm.faces.new(list(reversed(loops[0])))
    bm.faces.new(loops[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def build(scene, hot=False, model=False):
    """Pip, standing square. Returns the joints: empties at R6's pivots, the hat's on the head, and the lantern's.
    `model` is the build pip_model.py finishes: the robe's hem fuller front and back, so a walk's stride stays inside
    it, long folds down the robe and the cloth stacked over its hem, the hair's locks, and the hat's fallen tip as
    one round taper."""
    full = 0.2 if model else 0.0
    m = materials()
    joints = {}
    for name, at in PIVOTS.items():
        j = bpy.data.objects.new(name, None)
        scene.collection.objects.link(j)
        j.location = at
        j.rotation_mode = "QUATERNION"
        if name != "root":
            parent = "neck" if name == "hat" else "root"
            j.parent = joints[parent]
            j.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[parent]))
        joints[name] = j

    def on(part, *objs):
        for o in objs:
            o.parent = joints[part]
            o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[part]))

    # the robe: R6's torso in a shell that belongs to someone taller. It falls past the knees as a bell the legs
    # swing inside, its hem uneven where he's trodden on it, a chalk band above the hem
    def hem(t, lift=0.0):
        return 1.22 + 0.09 * math.sin(3 * t + 0.7) + lift

    band = [(lambda t: hem(t, 0.16), 0, 0, 2.55, 1.75 + full * 0.96), (lambda t: hem(t, 0.3), 0, 0, 2.5, 1.7 + full * 0.92)]
    def roll(t, lift):
        return 1.67 + 0.06 * math.sin(3 * t + math.radians(40)) + lift

    if model:  # cut for someone taller (research's fix 1 on the model): the folds, and a roll of cloth over the hem
        robe = [pleated("Robe", [(hem, 0, 0, 2.56, 1.96), (1.5, 0, 0, 2.52, 1.88), (lambda t: roll(t, 0.0), 0, 0, 2.4, 1.7),
                                 (lambda t: roll(t, 0.17), 0, 0, 2.46, 1.76),
                                 (2.1, 0, 0, 2.2, 1.36), (2.55, 0, 0, 2.12, 1.2), (3.0, 0, 0, 2.08, 1.08), (3.6, 0, 0, 2.06, 1.07),
                                 (4.0, 0, 0, 2.06, 1.07)], m["Inkwell"]),
                pleated("HemBand", band, m["Chalk"])]
    else:
        robe = [loft("Robe", [(hem, 0, 0, 2.56, 1.76), (2.0, 0, 0, 2.2, 1.3), (3.0, 0, 0, 2.08, 1.08), (4.0, 0, 0, 2.06, 1.07)], m["Inkwell"], n=B),
                loft("HemBand", band, m["Chalk"], n=B)]
    on("root",
       *robe,
       loft("HemHollow", [(lambda t: hem(t, -0.012), 0, 0, 2.4, 1.6 + full), (lambda t: hem(t, 0.012), 0, 0, 2.4, 1.6 + full)], m["Ink"], n=B),
       *[slab("Toggle", (0, 0.555 + 0.012 * i, 3.62 - i * 0.42), (0.34, 0.07, 0.11), m["Brass"]) for i in range(3)],
       *[slab("Strap", (e * 0.62, 0.55, 3.5), (0.17, 0.05, 1.02), m["Leather"]) for e in (-1, 1)],
       *[slab("StrapTop", (e * 0.62, 0.0, 4.02), (0.17, 1.12, 0.05), m["Leather"]) for e in (-1, 1)])
    # the collar: a roll of chalk cloth that stands to his chin
    on("root",
       loft("Collar", [(3.94, 0, 0, 1.62, 1.32), (4.13, 0, -0.02, 1.8, 1.5), (4.13, 0, -0.02, 1.52, 1.24), (3.94, 0, 0, 1.42, 1.14)],
            m["Chalk"], n=3, closed=True),
       loft("CollarShade", [(3.96, 0, 0, 1.44, 1.16), (4.1, 0, -0.02, 1.52, 1.24)], m["ChalkShade"], n=3, caps=False))
    # the book on his back, as big as his back: what the player's camera sees. Two boards, a spine, the pages' edge,
    # brass at the corners, and one plain brass disc on the cover
    by = -0.8
    on("root",
       slab("BookBoard", (0, by - 0.16, 3.02), (1.34, 0.06, 1.56), m["Leather"]),
       slab("BookBoard", (0, by + 0.16, 3.02), (1.34, 0.06, 1.56), m["Leather"]),
       slab("BookSpine", (-0.66, by, 3.02), (0.08, 0.38, 1.56), m["LeatherLight"]),
       slab("BookPages", (0.02, by, 3.02), (1.24, 0.27, 1.46), m["Chalk"]),
       *[slab("BookCorner", (e * 0.56, by - 0.185, 3.02 + f * 0.67), (0.24, 0.03, 0.24), m["Brass"]) for e in (-1, 1) for f in (-1, 1)],
       ss.plate("BookDisc", ss.disc(0, 3.02, 0.24, 16), by - 0.215, 0.03, m["Brass"]),
       slab("BookClasp", (0.62, by, 3.02), (0.12, 0.42, 0.2), m["Brass"]))

    # the sleeves: they hang half a stud past his hands and open like bells, chalk at the cuff, dark inside
    for part, e in (("rs", 1), ("ls", -1)):
        on(part,
           loft("Sleeve", [(1.46, e * 1.6, 0, 1.5, 1.5), (2.3, e * 1.54, 0, 1.2, 1.2), (3.2, e * 1.5, 0, 1.07, 1.07), (4.02, e * 1.5, 0, 1.05, 1.05)],
                m["Inkwell"], n=B, caps=False),
           loft("SleeveTop", [(4.0, e * 1.5, 0, 1.05, 1.05), (4.02, e * 1.5, 0, 1.05, 1.05)], m["Inkwell"], n=B),
           loft("Cuff", [(1.44, e * 1.6, 0, 1.55, 1.55), (1.66, e * 1.59, 0, 1.47, 1.47), (1.66, e * 1.59, 0, 1.36, 1.36),
                         (1.44, e * 1.6, 0, 1.4, 1.4)], m["Chalk"], n=B, closed=True),
           loft("CuffHollow", [(2.08, e * 1.55, 0, 1.2, 1.2), (2.1, e * 1.55, 0, 1.2, 1.2)], m["InkwellDeep"], n=B),
           loft("Hand", [(1.72, e * 1.5, 0, 0.8, 0.8), (2.05, e * 1.5, 0, 0.92, 0.92)], m["Skin"], n=B))

    # R6's round head, a fringe cut straight across the brow, and a face that looks up from under the brim: large
    # eyes, each with one catchlight, short brows raised in the middle, a small open mouth
    radius = 0.625

    def face(name, x, z, w, h, material, tilt=0.0, proud=0.0):
        y = math.sqrt(radius * radius - x * x)
        return slab(name, (x, y + proud, z), (w, 0.05, h), material, rot=(0, tilt, -math.degrees(math.asin(x / radius))))

    def fringe(t):
        edge = 4.84 - 0.6 * min(1.0, (1 - math.sin(t)) * 0.8) ** 2
        if model:  # a lock down each cheek, one shape with the fringe (research's fix 2 on the model)
            edge -= 0.34 * sum(math.exp(-((t - math.radians(at)) / math.radians(13)) ** 2) for at in (28, 152))
        return edge

    tufts = [] if model else [
        hexa("Tuft", [(e * 0.56, -0.2, 4.5), (e * 0.56, 0.2, 4.5), (e * 0.66, 0.2, 4.72), (e * 0.66, -0.2, 4.72),
                      (e * 0.9, -0.05, 4.36), (e * 0.9, 0.08, 4.36), (e * 0.92, 0.08, 4.44), (e * 0.92, -0.05, 4.44)], m["Chestnut"])
        for e in (-1, 1)]
    on("neck",
       loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                     (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2),
       loft("Hair", [(fringe, 0, 0, 1.32, 1.32), (5.06, 0, 0, 1.32, 1.32), (5.15, 0, 0, 1.05, 1.05)], m["Chestnut"], n=2),
       *tufts,
       face("BrowR", 0.27, 4.76, 0.22, 0.05, m["Chestnut"], tilt=11, proud=0.03),
       face("BrowL", -0.27, 4.76, 0.22, 0.05, m["Chestnut"], tilt=-11, proud=0.03),
       face("EyeR", 0.26, 4.52, 0.2, 0.28, m["Ink"]),
       face("EyeL", -0.26, 4.52, 0.2, 0.28, m["Ink"]),
       face("LightR", 0.3, 4.6, 0.07, 0.08, m["Chalk"], proud=0.012),
       face("LightL", -0.22, 4.6, 0.07, 0.08, m["Chalk"], proud=0.012),
       face("Mouth", 0.0, 4.25, 0.15, 0.09, m["Ink"], proud=0.006))

    # the hat, half his outline (research's fix 1): a brim wider than his shoulders that hangs to his collar behind
    # and at the sides, pushed up at the front so he can see, chalk round its edge (fix 3) and round the crown; a
    # crown as tall as his body that slumps to his left; and a tip that has fallen as far as his brow, weighted by a
    # brass bead and a tassel
    def edge(t, lift=0.0):
        return 4.36 + 0.34 * max(0.0, math.sin(t)) ** 1.5 + 0.05 * math.sin(2 * t + 0.6) + lift

    if model:
        path = arc((-0.6, -0.08, 7.14), (-1.3, -0.08, 7.52), (-2.06, -0.08, 7.0), (-2.02, -0.08, 5.6), 10)
        tip = [bl.tube_along("Tip", path, [0.25 - 0.19 * (i / 9) ** 0.8 for i in range(10)], sides=12, material=m["Inkwell"])]
    else:
        tip = tube("Tip", [(-0.62, 7.2, 0.05, 0.22, 0.22), (-1.3, 7.1, -0.09, 0.14, 0.17), (-1.85, 6.4, -0.11, 0.05, 0.12),
                           (-2.02, 5.62, -0.06, 0.012, 0.07)], m["Inkwell"])
    on("hat",
       loft("Brim", [(edge, 0, 0, 3.8, 3.8), (lambda t: edge(t, 0.07), 0, 0, 3.8, 3.8), (4.99, 0, 0, 1.5, 1.5), (4.92, 0, 0, 1.5, 1.5)],
            m["Inkwell"], n=2, closed=True),
       loft("BrimEdge", [(lambda t: edge(t, -0.025), 0, 0, 3.86, 3.86), (lambda t: edge(t, 0.1), 0, 0, 3.86, 3.86),
                         (lambda t: edge(t, 0.16), 0, 0, 3.6, 3.6), (lambda t: edge(t, 0.03), 0, 0, 3.6, 3.6)], m["Chalk"], n=2, closed=True),
       loft("Crown", [(4.98, 0, 0, 1.52, 1.52), (5.7, -0.05, -0.03, 1.36, 1.36), (6.4, -0.18, -0.06, 1.08, 1.08),
                      (6.95, -0.4, -0.08, 0.8, 0.8), (7.3, -0.62, -0.08, 0.54, 0.5)], m["Inkwell"], n=2),
       loft("Band", [(5.02, 0, 0, 1.58, 1.58), (5.3, -0.02, -0.01, 1.5, 1.5)], m["Chalk"], n=2),
       loft("Crease", [(6.38, -0.18, -0.06, 1.12, 1.12), (6.44, -0.19, -0.06, 1.1, 1.1)], m["InkwellDeep"], n=2),
       *tip,
       slab("Bead", (-2.03, -0.08, 5.5), (0.19, 0.19, 0.19), m["Brass"]),
       slab("Tassel", (-2.03, -0.08, 5.23), (0.13, 0.13, 0.38), m["Chalk"]))

    # the legs: slate leggings into boots a size too big, their tops turned over
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(part,
           loft("Legging", [(0.9, cx, 0, 0.98, 1.0), (2.0, cx, 0, 0.98, 1.0)], m["Slate"], n=B),
           loft("Sole", [(0.0, cx, 0.1, 1.04, 1.3), (0.09, cx, 0.1, 1.04, 1.3)], m["Ink"], n=B),
           loft("Boot", [(0.09, cx, 0.09, 1.04, 1.28), (0.36, cx, 0.07, 1.04, 1.2), (0.5, cx, 0.0, 1.02, 1.04), (0.92, cx, 0, 1.02, 1.04)],
                m["Leather"], n=B),
           loft("BootTop", [(0.8, cx, 0, 1.1, 1.12), (1.02, cx, 0, 1.1, 1.12)], m["LeatherLight"], n=B))
    joints["hat"].rotation_quaternion = Quaternion((1, 0, 0), math.radians(5)) @ Quaternion((0, 1, 0), math.radians(-4))
    joints["lamp"] = lantern(scene, m, hot)
    return joints


# --- poses ----------------------------------------------------------------------------------------------------

def settle(joints, lamp, turn=0.0, tilt=0.0):
    """Stands him on the floor and hangs the lantern at a place on the stage."""
    rs.stand_on_floor(joints)
    joints["lamp"].location = lamp
    joints["lamp"].rotation_quaternion = Quaternion((0, 0, 1), math.radians(turn)) @ Quaternion((1, 0, 0), math.radians(tilt))
    bpy.context.view_layer.update()


def pose_square(joints):
    rs.aim(joints["rs"], Quaternion(), (0.14, 0.0, -1.0))
    rs.aim(joints["ls"], Quaternion(), (-0.14, 0.0, -1.0))
    settle(joints, LAMP)


def pose_idle(joints):
    """How he stands: turned a little toward the lantern, toes in, the chin up so he can see from under the brim, one
    sleeve drawn in over the other."""
    body = Matrix.Rotation(math.radians(-10), 3, "Z").to_quaternion()
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rs"], body, (0.2, 0.16, -1.0), stage=False)
    rs.aim(joints["ls"], body, (0.24, 0.3, -1.0), stage=False)
    joints["neck"].rotation_quaternion = body.inverted() @ Quaternion((0, 0, 1), math.radians(-18)) @ Quaternion((1, 0, 0), math.radians(7))
    rs.aim(joints["lh"], body, (0.05, 0.04, -1.0), twist=-8)
    rs.aim(joints["rh"], body, (0.02, -0.05, -1.0), twist=8)
    settle(joints, (2.75, 0.6, 4.4), turn=-12)


def pose_send(joints):
    """Lantern Burst's key pose, the send: one sleeve goes level, straight down the lantern's line, and the lantern
    goes, hot, its slips streaming. The spell kicks: he's thrown back on his heels, the hat lifts off his head, and the
    other hand has the brim by its front and clamps it down. Never two arms up (research's fix 2)."""
    body = (Matrix.Rotation(math.radians(15), 3, "X") @ Matrix.Rotation(math.radians(14), 3, "Z")).to_quaternion()
    root = joints["root"]
    root.rotation_quaternion = body
    root.location = (0, -0.25, 3)
    rs.aim(joints["rs"], body, (0.0, 1.0, -0.2))
    rs.aim(joints["ls"], body, (0.42, 0.78, 0.62), twist=-30)
    joints["neck"].rotation_quaternion = body.inverted() @ Quaternion((1, 0, 0), math.radians(-2))
    joints["hat"].rotation_quaternion = Quaternion((1, 0, 0), math.radians(21)) @ Quaternion((0, 1, 0), math.radians(-8))
    rs.aim(joints["rh"], body, (0.12, 0.6, -1.0))
    rs.aim(joints["lh"], body, (-0.2, -0.3, -1.0), twist=20)
    settle(joints, (1.3, 6.1, 2.95), tilt=-80)


POSES = {"square": pose_square, "idle": pose_idle, "send": pose_send}


# --- pictures -------------------------------------------------------------------------------------------------

def takes(wanted, size=(1000, 1000), span=10.0):
    """{(pose, view): picture}, with the flame's glow drawn on, and what was measured. `wanted`: pose -> {view:
    (azimuth, elevation, centre)}."""
    out = {}
    for pose, views in wanted.items():
        scene = bl.reset_scene()
        joints = build(scene, hot=pose == "send")
        POSES[pose](joints)
        for view, (azimuth, elevation, centre) in views.items():
            passes = []
            for flat in (False, True):
                rs.workbench(scene, *size, flat=flat)
                path = OUT / f"_{pose}_{view}_{int(flat)}.png"
                passes.append(rs.shoot(scene, path, azimuth, elevation, centre, span))
                path.unlink()
            out[pose, view] = ss.lit(*passes, rs.rgb(PALETTE["Flame"]), reach=round(size[0] * (0.02 if pose == "send" else 0.012)))
        meshes = [o for o in scene.objects if o.type == "MESH"]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        out[pose, "size"] = tuple(round(max(q[i] for q in pts) - min(q[i] for q in pts), 2) for i in range(3))
        out[pose, "top"] = round(max(q.z for q in pts), 2)
        out["tris"] = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
    return out


MID, FAR = (0.4, 0, 3.5), (0.4, 2.6, 3.5)
GAME, FRONT = rs.GAME, (150, 8)
FLINCH = (136, 6)  # from the target's side, past the sleeve that points
PAPER, NIGHT, DAY = rs.PAPER, rs.NIGHT, rs.DAY
DUSK = rs.rgb("#2F2148")  # Lantern Row's own violet, where players meet him: the hat's outline has to hold on it


def sheet(small):
    wanted = {"square": {"front": (180, 0, MID), "back": (0, 0, MID)},
              "idle": {"front": (*FRONT, MID), "game": (*GAME, MID)},
              "send": {"flinch": (*FLINCH, FAR), "side": (90, 3, FAR), "game": (*GAME, FAR)}}
    s = takes(wanted)
    print(f"square {s['square', 'size']} studs, top {s['square', 'top']}; send {s['send', 'size']}, top {s['send', 'top']}; "
          f"blockout tris {s['tris']}")
    W, H = 1920, 1290
    page = rs.canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 64, "PIP", ink),
            (210, 36, 24, "Common / Intelligence / Mage / Fire. An apprentice, one of the three starters.", ink),
            (210, 70, 20, "One idea: a hat with a boy under it, and the one spell he has, kept in a lantern.", soft)]

    # row A: who he is
    k, floor = 0.56, 570
    cols = ((20, 340, "idle", "front", True, "outline"), (360, 340, "square", "front", False, "front, on the R6 body"),
            (700, 340, "square", "back", False, "back"), (1040, 340, "idle", "front", False, "three-quarter, how he stands"),
            (1380, 300, "idle", "game", False, "from the player's camera"))
    for x, width, pose, view, dark, label in cols:
        shot = rs.shrink(s[pose, view], k)
        rs.stand(page, ss.solid(shot) if dark else shot, x, floor, width)
        text.append((x + 14, floor + 14, 19, label, soft))
    rs.fill(page, 30, floor + 2, 1640, 2, rs.rgb("#BDB8AE"))

    # the chips
    x = 1700
    for i, (name, role) in enumerate(CHIPS):
        y = 120 + i * 118
        rs.fill(page, x, y, 96, 96, rs.rgb(PALETTE[name]))
        text += [(x + 108, y + 10, 22, name, ink), (x + 108, y + 40, 16, PALETTE[name], soft), (x + 108, y + 64, 16, role, soft)]
    for i, name in enumerate(NEUTRALS):
        rs.fill(page, x + i * 54, 480, 46, 46, rs.rgb(PALETTE[name]))
        text.append((x + i * 54, 534, 11, name, soft))
    text += [(x, 568, 16, "Reads, in order:", ink), (x, 592, 16, "1 the hat: half of him", soft),
             (x, 614, 16, "2 the lantern, lit, at his right", soft), (x, 636, 16, "3 the chalk bands; the book", soft)]

    # row B: Lantern Burst's key pose
    floor, k = 1130, 0.54
    text.append((40, 620, 30, "LANTERN BURST, the send", ink))
    text.append((40, 662, 18, "One sleeve goes level down the lantern's line and the lantern goes, hot. The spell kicks: he's thrown back, the hat lifts, the other hand clamps its brim.", soft))
    for x, width, view, dark, label in ((20, 540, "flinch", False, "three-quarter, from the target's side"), (570, 480, "side", True, "outline, side on"),
                                        (1050, 370, "game", False, "from the player's camera")):
        shot = rs.shrink(s["send", view], k)
        rs.stand(page, ss.solid(shot) if dark else shot, x, floor, width)
        text.append((x + 14, floor + 14, 19, label, soft))
    rs.fill(page, 30, floor + 2, 1380, 2, rs.rgb("#BDB8AE"))

    # at 64 px: a 5-stud body 64 px tall, over a dark and a bright ground, and in black
    f64 = 64 / 500
    x0, y0 = 1440, 676
    text.append((x0, y0, 19, "at 64 px: dark, Lantern Row's dusk, bright", soft))
    for r, (ground, sil) in enumerate(((NIGHT, False), (DUSK, False), (DAY, False), (PAPER, True))):
        y = y0 + 30 + r * 98
        rs.fill(page, x0, y, 450, 96, ground)
        for c, key in enumerate((("idle", "game"), ("idle", "front"), ("send", "game"), ("send", "flinch"))):
            shot = rs.shrink(s[key], f64)
            rs.stand(page, ss.solid(shot) if sil else shot, x0 + 8 + c * 110, y + 94, 104)
    y = y0 + 30 + 4 * 98 + 4
    text.append((x0, y, 19, "values", soft))
    for c, key in enumerate((("idle", "front"), ("idle", "game"), ("send", "flinch"))):
        rs.stand(page, rs.grey(rs.shrink(s[key], 0.2)), x0 + c * 150, 1252, 150)

    sizes = s["square", "size"]
    text.append((40, 1262, 15, f"Blockout on R6 at the player's height: 5 studs to the crown, {s['square', 'top']} to the hat's top, the brim 3.8 wide, "
                 f"{sizes[0]} across with the lantern. The hat hangs from the head and the lantern is its own piece. Views are orthographic. "
                 f"The flame's glow is drawn on the picture.", soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "pip_sheet.png")
    if small:
        rs.save(rs.shrink(page, 0.5), OUT / "pip_sheet_small.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    sheet("small" in sys.argv[sys.argv.index("--") + 2:])
