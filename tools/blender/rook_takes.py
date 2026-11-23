"""Rook, redesigned to the anime bar (AR59, research, 2026-11-23): three directions in colour on the R6 body, for
research's pick and then the director's look. Each is a different character from an anime's cast inside a Common's
limit: three or four elements, a plain palette, red the one accent. Quick blockouts: the hair, the clothes and the
gauntlet as rough meshes, never finished.

    A, the stray: wild black hair swept up to one side with one red clump, a grin; a bone-white cropped jacket with a
       standing collar lined red, its right sleeve cut off at the shoulder; a dark iron gauntlet with a red ram.
    B, the captain: a long teal-grey tail tied high with a red cord, two long bangs, narrow calm eyes; a long navy coat
       in a school uniform's cut, open and lined red, over a white shirt; a slim steel gauntlet, a white ribbon tied
       over the left cuff.
    C, the sleeper: a heavy sand-olive mop over his left eye, one half-shut gold eye; a sleeveless dark top under a
       big rolled hood-collar, very wide oxblood trousers gathered at the ankle; a bone-white gauntlet to the elbow
       with a red ram, the left forearm taped.

His rig holds: the gauntlet is on the right arm with its ram along the arm, and something light swings from the left.

Each is drawn as the player meets it: three-quarter front and the game's camera in the game's day light; the bust in
the lead card's pose; and in a fight on the deck from the player's camera at the smallest phone's size, beside today's
Rook and a Shade. The deck is a stand-in (its pale plates and a day sky): no capture of a fight there has a solved
camera, so the camera, the sun and the fill are hard_ember.py's, the game's own. Studs, X right, Y forward, Z up; he
faces +Y; every piece hangs from one of R6's six parts at the engine's own pivots, as watt_takes.py's do.

    blender.exe -b --factory-startup --python tools/blender/rook_takes.py -- <out_dir> takes|rook|shade|sheet

`takes`, `rook` and `shade` each draw their own pictures into <out_dir>/shots and <out_dir>/layers (Eevee, no GPU
turn); `sheet` lays them into rook_takes.png and its parts.
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
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402

PALETTE = {
    "Ink": "#1B1A20", "Charcoal": "#34343D", "CharcoalDeep": "#232329", "Bone": "#EFE6D2", "BoneShade": "#CDC1A6",
    "Red": "#D8323C", "Oxblood": "#8E2B30", "OxbloodDeep": "#5A181F", "Iron": "#4B5059", "IronDeep": "#2E323A",
    "Steel": "#A9AFBA", "Navy": "#27304E", "NavyDeep": "#171D33", "White": "#F4F1EA", "Skin": "#EDBE98",
    "SkinShade": "#C48E6C", "Amber": "#E39A2B", "Grey": "#8D97A6", "Gold": "#DDB94E",
}
# a head of hair: its root's colour, its ends'
HAIR = {"A": ("#141319", "#42414F"), "ARed": ("#A3202C", "#F0504F"), "B": ("#35565E", "#A3C6C3"), "C": ("#695A39", "#C2B17C")}
loft, slab, hexa = rs.loft, rs.slab, rs.hexa
rig, on, rod, face = wt.rig, wt.on, wt.rod, wt.face
B, R = wt.B, wt.R
VIEWS = {"front": (146, 8), "game": rs.GAME}
SHOT, SPAN, MID = 820, 7.9, (0.0, 0.0, 3.1)      # a full figure: pixels square, studs across, the crop's middle
BUST = dict(side=1, body=34, turn=22, tilt=-3, nod=5, elevation=3, centre=(-0.1, 0, 4.72), span=2.9)  # hud_art's Rook, wider
BUST_PX = (624, 752)
CARD = 0.853 * 1.12 / 8.0             # the bust's render to the lead card's portrait on the smallest phone
LEAD, FOE = (-2.5, -7.0), (2.2, -11.5)            # a fight: the lead a few studs in front of the avatar, and its foe
ROW_Z, ROW_X = -6.0, (-9.0, -4.5, 0.0, 4.5, 9.0)  # a line-up at the lead's distance, turned to the player
WHO = ("Rook", "A", "B", "C")
TALL = 7.2
SAID = {
    "Rook": ("Today's Rook", ("the model in the game: cropped oxblood jacket,", "taped fists, the oversized gauntlet")),
    "A": ("A, the stray", ("wild black hair swept up to one side, one red clump", "a bone jacket, its right sleeve cut off; red lining",
                           "a dark iron gauntlet, a red ram; a taped left hand", "a grin and amber eyes")),
    "B": ("B, the captain", ("a long teal-grey tail tied high with a red cord", "a long navy coat, open, lined red, over a white shirt",
                             "a slim steel gauntlet; a white ribbon on the left cuff", "narrow calm grey eyes")),
    "C": ("C, the sleeper", ("a heavy sand-olive mop over his left eye", "a big rolled hood-collar, very wide oxblood trousers",
                             "a bone-white gauntlet to the elbow, a red ram", "one half-shut gold eye")),
}


# --- the pieces every take is cut from ------------------------------------------------------------------------------

def materials():
    made = {}
    for name, code in PALETTE.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        bsdf, _, _ = bl._principled(m)
        bsdf.inputs["Base Color"].default_value = rs.srgb(code)
        bsdf.inputs["Roughness"].default_value = 1.0
        made[name] = m
    hair = bpy.data.materials.new("Hair")  # painted root to tip, a colour a point
    bsdf, nodes, links = bl._principled(hair)
    paint = nodes.new("ShaderNodeVertexColor")
    paint.layer_name = "Col"
    links.new(paint.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    made["Hair"] = hair
    return made


def painted(obj, colours):
    """A colour a point on a mesh, in its points' own order."""
    attr = obj.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    for d, c in zip(attr.data, colours):
        d.color = (c[0], c[1], c[2], 1.0)
    return obj


def blend(pair, u):
    a, b = rs.srgb(pair[0]), rs.srgb(pair[1])
    return [a[k] + (b[k] - a[k]) * u for k in range(3)]


def lock(m, name, points, width, thick, pair, samples=9):
    """A clump of hair: a broad blade along a curve through `points`, drawn evenly to a point, a ridge down its outer
    face, its root's colour running to its end's."""
    path = bl.smooth_path(points, samples)
    middle = Vector((0.0, 0.0, 4.6))
    bm = bmesh.new()
    rings, shades = [], []
    for i, p in enumerate(path):
        u = i / (samples - 1)
        along = (path[min(i + 1, samples - 1)] - path[max(i - 1, 0)]).normalized()
        out = p - middle
        out -= along * out.dot(along)
        out = out.normalized() if out.length > 1e-4 else along.orthogonal().normalized()
        side = along.cross(out).normalized()
        s = (1 - u) ** 0.8 * (1 + 0.25 * math.sin(math.pi * u))
        if i == samples - 1:
            ring = [bm.verts.new(p)]
        else:
            ring = [bm.verts.new(p + side * width / 2 * s), bm.verts.new(p + out * thick * 0.6 * s),
                    bm.verts.new(p - side * width / 2 * s), bm.verts.new(p - out * thick * 0.4 * s)]
        rings.append(ring)
        shades += [blend(pair, u ** 1.3)] * len(ring)
    bm.faces.new(list(reversed(rings[0])))
    for a, b in zip(rings, rings[1:]):
        for k in range(4):
            if len(b) == 4:
                bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
            else:
                bm.faces.new((a[k], a[(k + 1) % 4], b[0]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return painted(bl.object_from_bmesh(name, bm, m["Hair"]), shades)


def cap(m, pair, hairline, wide=1.34, top=5.22):
    """The hair close on the skull, from the hairline up: darker at the root."""
    o = loft("HairCap", [(hairline, 0, -0.02, wide, wide), (top - 0.22, 0, -0.03, wide + 0.05, wide + 0.05),
                         (top - 0.08, 0, -0.04, wide - 0.12, wide - 0.12), (top, 0, -0.05, wide * 0.55, wide * 0.55)], m["Hair"], n=2)
    return painted(o, [blend(pair, min(max((v.co.z - 4.2) / 1.2, 0.0), 1.0) * 0.45) for v in o.data.vertices])


def head(m):
    return [wt.head(m), face("Nose", 0.0, 4.27, 0.035, 0.07, m["SkinShade"], proud=0.004)]


def eyes(m, iris, tall=0.2, wide=0.23, x=0.27, z=4.42, lid=0.05, slant=0.0, brow=0.0, lift=0.13, sides=(1, -1)):
    """An anime eye a side: its white, a coloured iris, the pupil, one light, a heavy upper line with a flick at its
    outer end, and a thin brow. A slant above zero drops the outer end (sleepy); below zero, the inner end (fierce)."""
    made = []
    open_ = min(tall, 0.2)
    for e in sides:
        cx = e * x
        made += [face("EyeWhite", cx, z, wide, tall, m["White"]),
                 face("Iris", cx, z - 0.008, min(0.15, wide * 0.66), open_, m[iris], proud=0.008),
                 face("Pupil", cx, z - 0.012, 0.062, open_ * 0.5, m["Ink"], proud=0.016),
                 face("Light", cx + 0.04, z + open_ * 0.2, 0.05, min(0.05, tall * 0.42), m["White"], proud=0.024),
                 face("Lid", cx, z + tall / 2 + lid / 2 - 0.005, wide + 0.05, lid, m["Ink"], tilt=e * slant, proud=0.026),
                 face("Flick", cx + e * (wide / 2 + 0.03), z + tall / 2 - 0.012, 0.04, 0.075, m["Ink"], tilt=e * (slant + 20), proud=0.026),
                 face("Brow", cx, z + tall / 2 + lift, 0.27, 0.04, m["Ink"], tilt=e * brow, proud=0.03)]
    return made


def gauntlet(j, m, g, shell, deep, ram, cuff, cx=1.5):
    """The gauntlet on the right arm, today's numbers scaled by `g`: the fist, the ram's flat plate under its
    knuckles, the wrist, the cuff up to `cuff`, and the ram's rod along the arm."""
    w, d = 1.55 * g, 1.4 * g
    zb = 2.0 - 0.45 * g
    ft = zb + 0.8 * g
    wr = ft + 0.34
    on(j, "rs",
       loft("Fist", [(zb, cx, 0.04, w * 0.92, d * 0.92), (zb + 0.12, cx, 0.04, w, d), (ft - 0.1, cx, 0.04, w, d),
                     (ft, cx, 0.03, w * 0.9, d * 0.9)], m[shell], n=B),
       slab("Ram", (cx, 0.04, zb - 0.07), (w * 0.84, d * 0.84, 0.2), m[ram]),
       slab("Knuckles", (cx, 0.04 + d / 2, zb + 0.34 * g), (w * 0.8, 0.07, 0.3 * g), m[deep]),
       loft("Wrist", [(ft, 1.5, 0, 1.1, 1.1), (wr, 1.5, 0, 1.14, 1.14)], m[deep], n=B),
       loft("Cuff", [(wr, 1.5, 0, 1.28, 1.28), (cuff, 1.5, 0, 1.36, 1.36)], m[shell], n=B),
       loft("CuffBand", [(cuff - 0.13, 1.5, 0, 1.41, 1.41), (cuff, 1.5, 0, 1.41, 1.41)], m[deep], n=B),
       rod("RamRod", (cx + w / 2 - 0.02, -0.12, zb + 0.3), (1.5 + 0.7, -0.12, cuff - 0.08), 0.085, m["Steel"]))


def collar(m, outer, lining, back, front=4.02, wide=1.64, deep=1.5):
    """A standing collar, high behind and open at the throat, and its lining seen from the front."""
    def top(t):
        return front + (back - front) * (1 - max(0.0, math.sin(t)) ** 3)

    def under(t):
        return top(t) - 0.015

    return [loft("Collar", [(3.9, 0, 0, wide + 0.04, deep + 0.02), (top, 0, 0, wide, deep), (top, 0, 0, wide - 0.12, deep - 0.12),
                            (3.9, 0, 0, wide - 0.12, deep - 0.12)], m[outer], n=2.6, closed=True),
            loft("CollarLining", [(3.9, 0, 0, wide - 0.13, deep - 0.13), (under, 0, 0, wide - 0.13, deep - 0.13),
                                  (under, 0, 0, wide - 0.2, deep - 0.2), (3.9, 0, 0, wide - 0.2, deep - 0.2)], m[lining], n=2.6, closed=True)]


def legs(j, m, trouser, boot, top=0.62):
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(j, part,
           loft("Trouser", [(top - 0.1, cx, 0, 0.98, 1.0), (2.0, cx, 0, 1.0, 1.02)], m[trouser], n=B),
           loft("Sole", [(0.0, cx, 0.1, 1.04, 1.32), (0.14, cx, 0.1, 1.04, 1.32)], m["Ink"], n=B),
           loft("Boot", [(0.14, cx, 0.08, 1.0, 1.26), (0.4, cx, 0.04, 1.0, 1.12), (top, cx, 0, 1.02, 1.06)], m[boot], n=B))


# --- A, the stray -------------------------------------------------------------------------------------------------

def take_a(scene):
    m, j = materials(), rig(scene)
    on(j, "root",
       loft("Top", [(2.0, 0, 0, 2.04, 1.06), (4.0, 0, 0, 2.04, 1.06)], m["Ink"], n=B),
       loft("Jacket", [(2.84, 0, 0, 2.2, 1.2), (3.94, 0, 0, 2.2, 1.18), (4.03, 0, 0, 1.92, 1.0)], m["Bone"], n=B),
       loft("Hem", [(2.76, 0, 0, 2.24, 1.24), (2.88, 0, 0, 2.24, 1.24)], m["Red"], n=B),
       slab("Opening", (0, 0.575, 3.4), (0.5, 0.12, 1.3), m["Ink"]),
       slab("LiningR", (0.29, 0.59, 3.4), (0.08, 0.1, 1.3), m["Red"]),
       slab("LiningL", (-0.29, 0.59, 3.4), (0.08, 0.1, 1.3), m["Red"]),
       *collar(m, "Bone", "Red", 4.5),
       slab("Yoke", (0, -0.6, 3.6), (1.56, 0.05, 0.15), m["Red"]),
       loft("Belt", [(1.96, 0, 0, 2.1, 1.12), (2.13, 0, 0, 2.1, 1.12)], m["CharcoalDeep"], n=B))
    on(j, "ls",  # the whole sleeve, a taped hand, the tape's loose end
       loft("Sleeve", [(2.5, -1.5, 0, 1.14, 1.14), (3.96, -1.5, 0, 1.14, 1.14), (4.05, -1.46, 0, 0.92, 0.94)], m["Bone"], n=B),
       loft("Cuff", [(2.4, -1.5, 0, 1.19, 1.19), (2.58, -1.5, 0, 1.19, 1.19)], m["BoneShade"], n=B),
       loft("Hand", [(2.0, -1.5, 0, 0.97, 0.97), (2.42, -1.5, 0, 0.97, 0.97)], m["BoneShade"], n=B),
       slab("TapeEnd", (-2.06, -0.05, 1.84), (0.11, 0.04, 0.64), m["Bone"], rot=(0, 14, 0)))
    on(j, "rs",  # the sleeve cut off at the shoulder and hemmed, the bare arm
       loft("Shoulder", [(3.62, 1.5, 0, 1.16, 1.16), (3.96, 1.5, 0, 1.16, 1.16), (4.05, 1.46, 0, 0.92, 0.94)], m["Bone"], n=B),
       loft("ShoulderHem", [(3.55, 1.5, 0, 1.2, 1.2), (3.66, 1.5, 0, 1.2, 1.2)], m["BoneShade"], n=B),
       loft("Arm", [(2.6, 1.5, 0, 0.98, 0.98), (3.6, 1.5, 0, 0.98, 0.98)], m["Skin"], n=B))
    gauntlet(j, m, 1.15, "Iron", "IronDeep", "Red", 3.0)
    legs(j, m, "Charcoal", "CharcoalDeep")

    def hairline(t):
        s = math.sin(t)
        return 4.45 + 0.35 * max(0.0, s) ** 1.5 - 0.3 * max(0.0, -s)

    h, red = HAIR["A"], HAIR["ARed"]
    hair = [cap(m, h, hairline, wide=1.5, top=5.36),
            # broad spikes all swept up and over to his right, the red one standing among them
            lock(m, "Top", [(0.4, 0.15, 5.05), (0.95, 0.05, 5.4), (1.45, -0.1, 5.5)], 0.8, 0.42, h),
            lock(m, "TopRed", [(0.15, 0.2, 5.2), (0.6, 0.1, 5.75), (1.05, -0.1, 6.1)], 0.72, 0.4, red),
            lock(m, "Top", [(-0.15, 0.1, 5.22), (0.15, -0.15, 5.85), (0.55, -0.45, 6.3)], 0.8, 0.42, h),
            lock(m, "Top", [(-0.45, 0.05, 5.15), (-0.4, -0.2, 5.7), (-0.1, -0.55, 6.05)], 0.78, 0.42, h),
            lock(m, "Top", [(-0.6, -0.1, 5.0), (-0.85, -0.35, 5.4), (-0.8, -0.75, 5.7)], 0.72, 0.4, h),
            lock(m, "Top", [(0.25, -0.35, 5.15), (0.6, -0.8, 5.5), (1.0, -1.2, 5.65)], 0.78, 0.42, h),
            lock(m, "Top", [(-0.25, -0.35, 5.15), (-0.3, -0.85, 5.45), (-0.2, -1.3, 5.6)], 0.78, 0.42, h),
            lock(m, "Top", [(0.0, -0.5, 5.02), (0.15, -1.0, 5.1), (0.35, -1.45, 5.2)], 0.8, 0.42, h),
            lock(m, "Back", [(0.42, -0.55, 4.72), (0.64, -0.95, 4.52), (0.84, -1.2, 4.42)], 0.66, 0.36, h),
            lock(m, "Back", [(-0.42, -0.55, 4.72), (-0.64, -0.95, 4.52), (-0.84, -1.2, 4.44)], 0.66, 0.36, h),
            lock(m, "Nape", [(0.0, -0.62, 4.52), (0.0, -0.95, 4.22), (0.06, -1.1, 4.0)], 0.62, 0.34, h),
            lock(m, "Burn", [(0.68, 0.12, 4.82), (0.8, 0.28, 4.45), (0.7, 0.36, 4.08)], 0.42, 0.24, h),
            lock(m, "Burn", [(-0.68, 0.12, 4.82), (-0.8, 0.28, 4.45), (-0.7, 0.36, 4.08)], 0.42, 0.24, h),
            # the fringe, down to the brows
            lock(m, "Fringe", [(0.1, 0.5, 5.14), (0.2, 0.82, 4.9), (0.1, 0.74, 4.5)], 0.6, 0.3, h),
            lock(m, "Fringe", [(-0.3, 0.48, 5.12), (-0.48, 0.74, 4.9), (-0.52, 0.62, 4.56)], 0.58, 0.3, h),
            lock(m, "Fringe", [(0.46, 0.44, 5.1), (0.64, 0.64, 4.9), (0.66, 0.46, 4.58)], 0.54, 0.3, h)]
    grin = [face("GrinLine", 0.02, 4.13, 0.34, 0.12, m["Ink"], tilt=-4, proud=0.004),
            face("Grin", 0.02, 4.132, 0.29, 0.07, m["White"], tilt=-4, proud=0.012)]
    on(j, "neck", *head(m), *hair, *eyes(m, "Amber", tall=0.22, wide=0.25, slant=-5, brow=-9), *grin)
    return j


# --- B, the captain -----------------------------------------------------------------------------------------------

def take_b(scene):
    m, j = materials(), rig(scene)
    on(j, "root",
       loft("Shirt", [(2.0, 0, 0, 2.04, 1.06), (4.0, 0, 0, 2.04, 1.06)], m["White"], n=B),
       loft("Coat", [(2.0, 0, 0, 2.24, 1.22), (3.94, 0, 0, 2.24, 1.2), (4.04, 0, 0, 1.94, 1.02)], m["Navy"], n=B),
       slab("ShirtFront", (0, 0.585, 3.08), (0.56, 0.12, 1.9), m["White"]),
       slab("BeltFront", (0, 0.59, 2.06), (0.56, 0.12, 0.17), m["Ink"]),
       slab("Buckle", (0, 0.655, 2.06), (0.2, 0.03, 0.13), m["Steel"]),
       slab("LiningR", (0.32, 0.6, 3.02), (0.08, 0.1, 2.04), m["Red"]),
       slab("LiningL", (-0.32, 0.6, 3.02), (0.08, 0.1, 2.04), m["Red"]),
       loft("Band", [(3.92, 0, 0, 1.44, 1.34), (4.12, 0, 0, 1.42, 1.32), (4.12, 0, 0, 1.36, 1.26), (3.92, 0, 0, 1.36, 1.26)],
            m["White"], n=2.6, closed=True),
       *collar(m, "Navy", "Red", 4.3, front=4.0, wide=1.72, deep=1.56),
       # the tails: the back and the two sides, open in front, their lining seen past the legs
       hexa("TailBack", [(-1.36, -0.8, 0.85), (1.36, -0.8, 0.85), (1.36, -0.72, 0.85), (-1.36, -0.72, 0.85),
                         (-1.12, -0.61, 2.05), (1.12, -0.61, 2.05), (1.12, -0.53, 2.05), (-1.12, -0.53, 2.05)], m["Navy"]),
       hexa("TailBackLining", [(-1.3, -0.72, 0.9), (1.3, -0.72, 0.9), (1.3, -0.69, 0.9), (-1.3, -0.69, 0.9),
                               (-1.08, -0.53, 2.05), (1.08, -0.53, 2.05), (1.08, -0.5, 2.05), (-1.08, -0.5, 2.05)], m["Red"]),
       # the vent in the back, the lining showing in it
       hexa("Vent", [(-0.24, -0.83, 0.84), (0.24, -0.83, 0.84), (0.24, -0.79, 0.84), (-0.24, -0.79, 0.84),
                     (-0.03, -0.66, 1.9), (0.03, -0.66, 1.9), (0.03, -0.62, 1.9), (-0.03, -0.62, 1.9)], m["Red"]))
    for s in (1, -1):
        on(j, "root",
           hexa("TailSide", [(s * 1.3, -0.78, 0.85), (s * 1.38, -0.78, 0.85), (s * 1.38, 0.5, 0.85), (s * 1.3, 0.5, 0.85),
                             (s * 1.06, -0.6, 2.05), (s * 1.14, -0.6, 2.05), (s * 1.14, 0.58, 2.05), (s * 1.06, 0.58, 2.05)], m["Navy"]),
           hexa("TailSideLining", [(s * 1.27, -0.72, 0.9), (s * 1.3, -0.72, 0.9), (s * 1.3, 0.47, 0.9), (s * 1.27, 0.47, 0.9),
                                   (s * 1.03, -0.55, 2.05), (s * 1.06, -0.55, 2.05), (s * 1.06, 0.55, 2.05), (s * 1.03, 0.55, 2.05)], m["Red"]))
    on(j, "ls",  # the long sleeve, a white ribbon tied over its cuff, its two ends cut square
       loft("Sleeve", [(2.32, -1.5, 0, 1.14, 1.14), (3.96, -1.5, 0, 1.14, 1.14), (4.05, -1.46, 0, 0.92, 0.94)], m["Navy"], n=B),
       loft("Hand", [(2.0, -1.5, 0, 0.95, 0.95), (2.34, -1.5, 0, 0.95, 0.95)], m["Skin"], n=B),
       loft("Ribbon", [(2.4, -1.5, 0, 1.2, 1.2), (2.58, -1.5, 0, 1.2, 1.2)], m["White"], n=B),
       slab("RibbonEnd", (-2.13, -0.1, 2.12), (0.05, 0.16, 0.6), m["White"], rot=(0, 10, 0)),
       slab("RibbonEnd", (-2.15, 0.12, 2.2), (0.05, 0.16, 0.46), m["White"], rot=(0, 16, 0)))
    on(j, "rs",  # the sleeve pushed up to the elbow
       loft("Sleeve", [(3.02, 1.5, 0, 1.14, 1.14), (3.96, 1.5, 0, 1.14, 1.14), (4.05, 1.46, 0, 0.92, 0.94)], m["Navy"], n=B),
       loft("Roll", [(2.9, 1.5, 0, 1.22, 1.22), (3.1, 1.5, 0, 1.22, 1.22)], m["NavyDeep"], n=B),
       loft("Arm", [(2.6, 1.5, 0, 0.96, 0.96), (2.95, 1.5, 0, 0.96, 0.96)], m["Skin"], n=B))
    gauntlet(j, m, 0.84, "Steel", "Iron", "IronDeep", 2.86)
    legs(j, m, "NavyDeep", "Ink")

    def hairline(t):
        s = math.sin(t)
        return 4.5 + 0.38 * max(0.0, s) ** 1.2 - 0.25 * max(0.0, -s)

    h = HAIR["B"]
    hair = [cap(m, h, hairline, wide=1.42, top=5.3),
            # two long bangs framing the face, parted over the brow
            lock(m, "Bang", [(0.16, 0.52, 5.14), (0.64, 0.6, 4.72), (0.76, 0.46, 4.2), (0.66, 0.42, 3.8)], 0.52, 0.26, h, samples=11),
            lock(m, "Bang", [(-0.16, 0.52, 5.14), (-0.64, 0.6, 4.72), (-0.76, 0.46, 4.2), (-0.7, 0.42, 3.95)], 0.52, 0.26, h, samples=11),
            lock(m, "Part", [(0.06, 0.56, 5.16), (0.32, 0.78, 4.96), (0.44, 0.7, 4.68)], 0.42, 0.24, h),
            lock(m, "Part", [(-0.06, 0.56, 5.16), (-0.28, 0.78, 5.0), (-0.36, 0.72, 4.76)], 0.4, 0.24, h),
            # the tail: up from the cord, then down to the shoulder blades in sharp ends
            lock(m, "Tail", [(0.0, -0.6, 5.26), (0.0, -1.2, 5.6), (0.05, -1.62, 5.0), (0.02, -1.56, 3.95), (0.12, -1.36, 2.9)],
                 0.95, 0.56, h, samples=15),
            lock(m, "Tail", [(0.12, -0.6, 5.24), (0.4, -1.15, 5.46), (0.56, -1.5, 4.8), (0.6, -1.44, 3.9), (0.74, -1.3, 3.3)],
                 0.66, 0.4, h, samples=13),
            lock(m, "Tail", [(-0.12, -0.6, 5.24), (-0.38, -1.15, 5.4), (-0.56, -1.46, 4.7), (-0.54, -1.4, 3.6)], 0.66, 0.4, h, samples=11),
            lock(m, "Tail", [(0.0, -0.62, 5.2), (0.2, -1.3, 5.2), (0.3, -1.6, 4.5), (0.34, -1.5, 3.55)], 0.6, 0.38, h, samples=11),
            lock(m, "Spray", [(0.04, -0.56, 5.3), (0.2, -0.86, 5.82), (0.4, -1.1, 6.04)], 0.46, 0.28, h),
            lock(m, "Spray", [(-0.06, -0.56, 5.3), (-0.3, -0.9, 5.7), (-0.6, -1.1, 5.72)], 0.44, 0.28, h),
            bl.place(bl.box("Cord", (0.44, 0.26, 0.24), m["Red"]), location=(0, -0.66, 5.28), rotation=(-35, 0, 0))]
    mouth = [face("Mouth", 0.0, 4.13, 0.13, 0.028, m["Ink"], proud=0.004)]
    on(j, "neck", *head(m), *hair, *eyes(m, "Grey", tall=0.125, wide=0.25, lid=0.045, slant=-4, brow=-3, lift=0.11), *mouth)
    return j


# --- C, the sleeper -----------------------------------------------------------------------------------------------

def take_c(scene):
    m, j = materials(), rig(scene)

    def roll(t):  # the hood-collar's top: under his mouth in front, high behind
        return 3.93 + 0.6 * (1 - max(0.0, math.sin(t)) ** 2)

    def part_way(share):
        return lambda t: 3.58 + share * (roll(t) - 3.58)

    on(j, "root",
       loft("Top", [(2.0, 0, 0, 2.04, 1.06), (4.0, 0, 0, 2.04, 1.06)], m["Charcoal"], n=B),
       loft("Cowl", [(3.58, 0, -0.05, 2.36, 1.56), (part_way(0.4), 0, -0.08, 3.02, 2.12), (part_way(0.82), 0, -0.1, 2.94, 2.06),
                     (roll, 0, -0.1, 2.4, 1.8), (roll, 0, -0.1, 1.72, 1.56), (3.9, 0, -0.05, 1.5, 1.36)], m["Bone"], n=2.6, closed=True),
       loft("Hood", [(3.05, 0, -0.74, 1.2, 0.46), (3.6, 0, -0.86, 1.76, 0.8), (4.2, 0, -0.84, 1.66, 0.78), (4.5, 0, -0.7, 1.1, 0.5)],
            m["BoneShade"], n=2.5),
       loft("Waist", [(1.7, 0, 0, 2.34, 1.36), (2.32, 0, 0, 2.14, 1.14)], m["OxbloodDeep"], n=B),
       loft("Rope", [(2.08, 0, 0, 2.3, 1.3), (2.24, 0, 0, 2.3, 1.3)], m["Bone"], n=B),
       rod("RopeEnd", (-0.5, 0.68, 2.16), (-0.56, 0.72, 1.82), 0.07, m["Bone"]),
       rod("RopeEnd", (-0.34, 0.68, 2.16), (-0.3, 0.72, 1.9), 0.07, m["Bone"]))
    on(j, "ls",  # the bare arm, its forearm taped, the tape's long loose end
       loft("Arm", [(2.0, -1.5, 0, 0.98, 0.98), (3.96, -1.5, 0, 0.98, 0.98), (4.04, -1.47, 0, 0.86, 0.88)], m["Skin"], n=B),
       loft("Tape", [(2.0, -1.5, 0, 1.05, 1.05), (2.95, -1.5, 0, 1.05, 1.05)], m["Bone"], n=B),
       slab("TapeEnd", (-2.1, -0.08, 1.7), (0.12, 0.04, 0.95), m["Bone"], rot=(0, 13, 0)))
    on(j, "rs",
       loft("Arm", [(3.0, 1.5, 0, 0.98, 0.98), (3.96, 1.5, 0, 0.98, 0.98), (4.04, 1.47, 0, 0.86, 0.88)], m["Skin"], n=B))
    gauntlet(j, m, 1.4, "Bone", "BoneShade", "Red", 3.26, cx=1.72)
    for part, s in (("rh", 1), ("lh", -1)):  # very wide, gathered at the ankle
        cx = s * 0.5
        on(j, part,
           loft("Trouser", [(0.46, s * 0.54, 0, 0.98, 1.06), (0.8, s * 0.62, 0, 1.4, 1.56), (1.45, s * 0.6, 0, 1.34, 1.5),
                            (2.0, cx, 0, 1.06, 1.14)], m["Oxblood"], n=5),
           loft("Gather", [(0.36, cx, 0, 0.98, 1.02), (0.5, cx, 0, 1.04, 1.1)], m["OxbloodDeep"], n=B),
           loft("Ankle", [(0.12, cx, 0.02, 0.92, 1.0), (0.38, cx, 0, 0.92, 0.98)], m["Charcoal"], n=B),
           loft("Shoe", [(0.0, cx, 0.1, 1.0, 1.3), (0.14, cx, 0.08, 1.0, 1.26)], m["Ink"], n=B))

    def hairline(t):
        s = math.sin(t)
        return 4.4 + 0.36 * max(0.0, s) ** 1.5 - 0.2 * max(0.0, -s)

    h = HAIR["C"]
    hair = [cap(m, h, hairline, wide=1.6, top=5.44),
            # the fringe: heavy clumps drooping over his left eye
            lock(m, "Fringe", [(-0.14, 0.5, 5.3), (-0.4, 0.9, 4.92), (-0.32, 0.8, 4.22)], 0.74, 0.38, h),
            lock(m, "Fringe", [(-0.5, 0.42, 5.22), (-0.72, 0.7, 4.84), (-0.68, 0.56, 4.16)], 0.66, 0.38, h),
            lock(m, "Fringe", [(0.12, 0.54, 5.3), (0.0, 0.9, 5.0), (-0.04, 0.8, 4.56)], 0.62, 0.34, h),
            lock(m, "Fringe", [(0.44, 0.46, 5.24), (0.72, 0.64, 4.98), (0.84, 0.44, 4.66)], 0.6, 0.34, h),
            # a soft crown lying over to one side, and short ends drooping round the ears and the nape
            lock(m, "Crown", [(0.1, 0.1, 5.36), (-0.3, 0.0, 5.62), (-0.78, -0.1, 5.5)], 0.7, 0.4, h),
            lock(m, "Crown", [(0.1, -0.2, 5.36), (0.5, -0.4, 5.56), (0.9, -0.5, 5.36)], 0.7, 0.4, h),
            lock(m, "Ear", [(0.72, 0.02, 5.0), (0.96, 0.08, 4.6), (0.88, 0.1, 4.16)], 0.64, 0.36, h),
            lock(m, "Ear", [(-0.72, 0.02, 5.0), (-0.96, 0.08, 4.6), (-0.88, 0.1, 4.22)], 0.64, 0.36, h),
            lock(m, "Nape", [(0.44, -0.56, 5.0), (0.66, -0.9, 4.56), (0.58, -0.92, 4.12)], 0.68, 0.38, h),
            lock(m, "Nape", [(-0.44, -0.56, 5.0), (-0.66, -0.9, 4.56), (-0.58, -0.92, 4.18)], 0.68, 0.38, h),
            lock(m, "Nape", [(0.0, -0.64, 5.0), (0.0, -1.0, 4.52), (0.0, -0.94, 4.02)], 0.7, 0.38, h)]
    mouth = [face("Mouth", 0.02, 4.13, 0.12, 0.028, m["Ink"], tilt=-5, proud=0.004)]
    on(j, "neck", *head(m), *hair, *eyes(m, "Gold", tall=0.15, wide=0.27, lid=0.075, slant=7, brow=6, lift=0.12, sides=(1,)), *mouth)
    return j


TAKES = {"A": take_a, "B": take_b, "C": take_c}


# --- the pictures ---------------------------------------------------------------------------------------------------

def fill_for(scene, azimuth):
    """A fill from the camera itself, as the card's portraits have: a fringe mustn't put the eyes in shade."""
    fill = bpy.data.objects.get("Fill")
    if fill is None:
        fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN"))
        fill.data.energy, fill.data.use_shadow = 1.1, False
        scene.collection.objects.link(fill)
    a = math.radians(azimuth)
    fill.rotation_euler = Vector((-math.sin(a), math.cos(a), -0.12)).to_track_quat("-Z", "Y").to_euler()


def full_views(scene, shots, key):
    rm.eevee(scene, SHOT, SHOT)
    for view, (azimuth, elevation) in VIEWS.items():
        rm.sun_for(scene, azimuth)
        fill_for(scene, azimuth)
        rs.shoot(scene, shots / f"{key}_{view}.png", azimuth, elevation, MID, SPAN)


def bust_view(scene, shots, key):
    rm.eevee(scene, *BUST_PX)
    azimuth = 180.0 - BUST["side"] * BUST["body"]
    rm.sun_for(scene, azimuth)
    fill_for(scene, azimuth)
    rs.shoot(scene, shots / f"{key}_bust.png", azimuth, BUST["elevation"], BUST["centre"], BUST["span"])


def spots(key):
    """Where a figure stands in the capture's frame: (stem, x, z, faces toward)."""
    import shade_elites as el
    x = ROW_X[(WHO + ("Shade",)).index(key)]
    fight = ("foe", *FOE, LEAD) if key == "Shade" else ("fight", *LEAD, FOE)
    return [fight, ("row", x, ROW_Z, el.toward((x, ROW_Z), 26.0))]


def keep(he, scene, layers, stem, x, z):
    """One figure's layer, cut to its own pixels."""
    he.border(scene, x, z, 1.25, TALL / 1.25)
    path = layers / f"{stem}.npy"
    he.render(scene, path)
    full = np.load(path)
    rows, cols = np.nonzero(full[..., 3] > 0)
    y0, y1, x0, x1 = rows.min(), rows.max() + 1, cols.min(), cols.max() + 1
    np.savez_compressed(path.with_suffix(".npz"), px=full[y0:y1, x0:x1], at=np.array([x0, y0]))
    path.unlink()


def takes_run(out):
    import hard_ember as he
    import r6anim as r6
    shots, layers = out / "shots", out / "layers"
    shots.mkdir(parents=True, exist_ok=True)
    layers.mkdir(parents=True, exist_ok=True)
    for key, build in TAKES.items():
        scene = bl.reset_scene()
        scene.world = bpy.data.worlds.new("Takes")
        j = build(scene)
        rs.POSES["idle"](j)
        bpy.context.view_layer.update()
        meshes = [o for o in scene.objects if o.type == "MESH"]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        size = [max(p[i] for p in pts) - min(p[i] for p in pts) for i in range(3)]
        tris = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
        print(f"{key}: {size[0]:.2f} x {size[1]:.2f} x {size[2]:.2f} studs, {tris} triangles")
        full_views(scene, shots, key)
        idle = {name: (joint.location.copy(), joint.rotation_quaternion.copy()) for name, joint in j.items()}
        # the lead card's pose: the gauntlet's shoulder forward, the head turned back to the player
        for joint in j.values():
            joint.rotation_quaternion = (1, 0, 0, 0)
        j["root"].location = wt.PIVOTS["root"]
        rs.POSES["square"](j)
        yaw = -math.radians(BUST["side"] * BUST["turn"])
        j["neck"].rotation_quaternion = (Matrix.Rotation(yaw, 3, "Z") @ Matrix.Rotation(math.radians(BUST["nod"]), 3, "X")
                                         @ Matrix.Rotation(math.radians(BUST["tilt"]), 3, "Y")).to_quaternion()
        bust_view(scene, shots, key)
        for name, joint in j.items():
            joint.location, joint.rotation_quaternion = idle[name]
        bpy.context.view_layer.update()
        base = j["root"].matrix_world.copy()
        he.setup(scene)
        for stem, x, z, faces in spots(key):
            at = Vector((x, he.ROOT, z))
            m = r6.to_blender(r6.look_at(at, at + he.facing((x, z), faces)))
            j["root"].matrix_world = m @ Matrix.Translation((0, 0, -he.ROOT)) @ base
            keep(he, scene, layers, f"{key}_{stem}", x, z)


def rook_run(out):
    """Today's Rook, the model in the game, in the same pictures."""
    import hard_ember as he
    import hud_art as ha
    import rook_clips as rc
    shots, layers = out / "shots", out / "layers"
    shots.mkdir(parents=True, exist_ok=True)
    layers.mkdir(parents=True, exist_ok=True)
    scene, rig_, _, undress, _ = rc.build()
    undress(False)
    last = he.key(rig_, he.REPO / "build" / "handoff" / "Rook" / "clips" / "Rook_Idle.json")
    for o in [o for o in scene.objects if o.type in ("LIGHT", "CAMERA")]:
        bpy.data.objects.remove(o)
    if "Floor" in bpy.data.objects:
        bpy.data.objects["Floor"].hide_render = True
    scene.frame_set(0)
    full_views(scene, shots, "Rook")
    he.setup(scene)
    for stem, x, z, faces in spots("Rook"):
        he.stand(rig_, x, z, faces, 1.0)
        scene.frame_set(7 % last)
        keep(he, scene, layers, f"Rook_{stem}", x, z)
    ha.PORTRAITS["Rook"].update(centre=BUST["centre"], span=BUST["span"])
    rs.save(ha.shoot_portrait("Rook", shots, BUST_PX), shots / "Rook_bust.png")


def shade_run(out):
    """A Brawler in the game's Idle, as the foe and at the row's end."""
    import hard_cut as hc
    import shade_kinds as sk
    layers = out / "layers"
    layers.mkdir(parents=True, exist_ok=True)
    he, scene, rig_, last, _, wear, wear_mask = sk.staged()
    wear("Normal", dict(he.SHADE, body="#" + hc.type_tints()["Red"]))
    wear_mask("Brawler")
    for stem, x, z, faces in spots("Shade"):
        he.stand(rig_, x, z, faces, 1.0)
        scene.frame_set(11 % last)
        keep(he, scene, layers, f"Shade_{stem}", x, z)


# --- the sheet ------------------------------------------------------------------------------------------------------

def deck(he):
    """The base's deck by day, a stand-in in the capture's frame: pale plates with their seams, a day sky. Linear."""
    gx, gz = he.ground_points()
    horizon = int(round(he.project((0.0, he.EYE.y, -4000.0))[1]))
    lin = lambda code: he.to_linear(np.array(rs.rgb(code), np.float32)[:3])  # noqa: E731
    out = np.ones((he.H, he.W, 4), np.float32)
    rise = np.linspace(0.0, 1.0, horizon)[:, None, None]
    out[:horizon, :, :3] = lin("#4C93DE") * (1 - rise) + lin("#CFE4F4") * rise
    x, z = np.nan_to_num(gx[horizon:]), np.nan_to_num(gz[horizon:])
    far = np.hypot(x - he.EYE.x, z - he.EYE.z)
    seam = np.minimum(4 - np.abs((x / 8) % 1 - 0.5) * 8, 4 - np.abs((z / 8) % 1 - 0.5) * 8)
    line = np.clip(1 - seam / (0.05 + far * 0.0022), 0, 1) * np.clip(60 / np.maximum(far, 1), 0, 1)
    ground = lin("#CCD2D9") * (1 - line[..., None]) + lin("#A4ACB7") * line[..., None]
    haze = np.exp(-far / 260.0)[..., None]
    out[horizon:, :, :3] = ground * haze + lin("#CFE4F4") * (1 - haze)
    return out, gx, gz


def sheet_run(out):
    import brawler_mask_look as bm
    import hard_cut as hc
    import hard_ember as he
    import shade_elites as el
    shots, layers = out / "shots", out / "layers"
    backdrop, gx, gz = deck(he)
    phone = el.PHONE_H / he.H

    def layer(stem):
        got = np.load(layers / f"{stem}.npz")
        px, (x0, y0) = got["px"].astype(np.float32), got["at"]
        full = np.zeros((he.H, he.W, 4), np.float32)
        full[y0:y0 + px.shape[0], x0:x0 + px.shape[1]] = px
        return full

    def laid(stems_at):
        got = [(he.project((x, 0, z))[2], layer(stem)) for stem, x, z in stems_at]
        return he.lay(backdrop, got, [(x, z, 1.0) for _, x, z in stems_at], "Normal", gx, gz)

    def box(places, half, pad):
        x0, y0, w, h = bm.box(places, half, TALL - 0.6, pad)
        x0, y0 = max(x0, 0), max(y0, 0)
        return x0, y0, min(w, he.W - x0), min(h, he.H - y0)

    def over(stem, at, colour, dark=False):
        """A figure's own pixels at 64 to a 5-stud body, over a flat ground."""
        got = np.load(layers / f"{stem}.npz")["px"].astype(np.float32)
        base = he.to_linear(np.array(rs.rgb(colour), np.float32)[:3])
        comp = np.empty(got.shape[:2] + (4,), np.float32)
        comp[..., :3] = he.to_srgb((0.0 if dark else got[..., :3]) + base * (1 - got[..., 3:]))
        if dark:
            comp[..., :3] = he.to_srgb(base * (1 - got[..., 3:]) + he.to_linear(np.array((0.04, 0.04, 0.05), np.float32)) * got[..., 3:])
        comp[..., 3] = 1.0
        return rs.shrink(comp, 64 / 5.0 / (he.F / he.project((at[0], 0, at[1]))[2]))

    gap, W = 24, 1900
    ink, soft, paper, plate = "#EDE6D6", "#B4AC9C", "#101117", "#1A1B24"
    parts, text_of = [], []

    def part(height, name):
        page = rs.canvas(W, height, rs.rgb(paper))
        parts.append((name, page))
        text_of.append([])
        return page, text_of[-1]

    col = (W - 2 * gap) // 4
    # 1. each from the front and from the game's camera
    page, text = part(1090, "full")
    text.append((gap, 20, 30, "AR59: ROOK, THREE DIRECTIONS, BESIDE TODAY'S", ink))
    text += hc.wrapped(gap, 60, 16, "Common / Red / Warrior, no element: the lead every new player holds. In colour on the R6 body, in a day "
                                   "light. Quick blockouts: rough meshes for the hair, the clothes and the gauntlet, never finished. His "
                                   "rig holds: the gauntlet on the right arm, something light swinging from the left. Each from the "
                                   "three-quarter front, then from the game's camera behind his right shoulder. Research picks one.",
                       soft, W - 2 * gap)
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        title, lines = SAID[key]
        text.append((x0, 112, 24, title, ink))
        text += [(x0, 146 + k * 20, 14, line, soft) for k, line in enumerate(lines)]
        front = rs.shrink(rs.trim(rs.load(shots / f"{key}_front.png")), 0.7)
        game = rs.shrink(rs.trim(rs.load(shots / f"{key}_game.png")), 0.48)
        rs.stand(page, front, x0, 740, col - gap)
        rs.stand(page, game, x0, 1076, col - gap)

    # 2. the bust in the lead card's pose
    page, text = part(470, "bust")
    text.append((gap, 14, 18, "The bust in the lead card's pose, then at the card's size on the smallest phone (and twice that).", ink))
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        shot = rs.load(shots / f"{key}_bust.png")
        big, small = rs.shrink(shot, 0.5), rs.shrink(shot, CARD)
        rs.fill(page, x0, 46, big.shape[1], big.shape[0], rs.rgb(plate))
        rs.paste(page, big, x0, 46)
        sx = x0 + big.shape[1] + 12
        rs.fill(page, sx, 46, small.shape[1], small.shape[0], rs.rgb(plate))
        rs.paste(page, small, sx, 46)
        twice = rs.shrink(shot, CARD * 2)
        rs.fill(page, sx, 60 + small.shape[0], twice.shape[1], twice.shape[0], rs.rgb(plate))
        rs.paste(page, twice, sx, 60 + small.shape[0])
        text.append((x0, 46 + big.shape[0] + 10, 14, SAID[key][0], soft))

    # 3. in a fight on the deck, from the player's camera
    fight_box = box([LEAD, FOE], 3.2, 10)
    fights = {key: rs.shrink(he.crop(laid([(f"{key}_fight", *LEAD), ("Shade_foe", *FOE)]), *fight_box), phone) for key in WHO}
    fw, fh = fights["A"].shape[1], fights["A"].shape[0]
    k = max(1, min(3, (col - gap) // fw))
    page, text = part(60 + fh + 16 + fh * k + 40, "fight")
    text.append((gap, 14, 18, f"In a fight on the deck from the player's camera, at the smallest phone ({el.PHONE_H} pixels high): at its "
                              f"own size, then {k} times. The deck is a stand-in; the camera and the light are the game's.", ink))
    for i, key in enumerate(WHO):
        x0 = gap + i * col
        rs.paste(page, fights[key], x0, 46)
        rs.paste(page, bm.zoomed(fights[key], k), x0, 46 + fh + 16)
        text.append((x0, 46 + fh + 16 + fh * k + 8, 14, SAID[key][0], soft))

    # 4. the line-up at the lead's distance
    row_box = box([(ROW_X[0], ROW_Z), (ROW_X[-1], ROW_Z)], 3.0, 10)
    row = rs.shrink(he.crop(laid([(f"{key}_row", x, ROW_Z) for key, x in zip(WHO + ("Shade",), ROW_X)]), *row_box), phone)
    rw, rh = row.shape[1], row.shape[0]
    kr = max(1, min(4, (W - 3 * gap - rw) // rw))
    page, text = part(60 + rh * kr + 20, "row")
    text.append((gap, 14, 18, f"At the lead's distance, turned to the player: today's Rook, A, B, C and a Brawler. At the smallest phone, "
                              f"then {kr} times.", ink))
    rs.paste(page, row, gap, 46)
    rs.paste(page, bm.zoomed(row, kr), gap + rw + gap, 46)

    # 5. at 64 pixels
    page, text = part(400, "small")
    text.append((gap, 14, 18, "At 64 pixels to a 5-stud body: turned to the player and fighting, from behind. Over night, over the deck, "
                              "and the outline.", ink))
    x = gap
    for key in WHO + ("Shade",):
        pair = [(f"{key}_row", (ROW_X[(WHO + ("Shade",)).index(key)], ROW_Z)), (f"{key}_foe" if key == "Shade" else f"{key}_fight",
                                                                              FOE if key == "Shade" else LEAD)]
        text.append((x, 46, 14, SAID[key][0] if key in SAID else "A Brawler", soft))
        widest = 0
        for stem, at in pair:
            for r, (ground, dark) in enumerate((("#101117", False), ("#CCD2D9", False), ("#E9E4D8", True))):
                tile = over(stem, at, ground, dark)
                rs.paste(page, tile, x + widest, 72 + r * 106 + (100 - tile.shape[0]))
            widest += tile.shape[1] + 8
        x += widest + 40

    height = sum(p.shape[0] for _, p in parts)
    whole = rs.canvas(W, height, rs.rgb(paper))
    y = 0
    for (name, page), text in zip(parts, text_of):
        rs.paste(page, rs.text_layer(W, page.shape[0], text), 0, 0)
        rs.save(page, out / f"rook_takes_{name}.png")
        whole[y:y + page.shape[0]] = page
        y += page.shape[0]
    rs.save(whole, out / "rook_takes.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    mode = sys.argv[sys.argv.index("--") + 2] if len(sys.argv) > sys.argv.index("--") + 2 else "sheet"
    {"takes": takes_run, "rook": rook_run, "shade": shade_run, "sheet": sheet_run}[mode](OUT)
