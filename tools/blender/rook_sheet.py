"""Rook's design sheet (AR1, delivery 1): a blockout of his look on the R6 body, and the sheet it's judged on.

blender.exe -b --factory-startup --python tools/blender/rook_sheet.py -- <out_dir> pack
    the silhouette pack: every variant in VARIANTS, black, standing and in Haymaker's wind-up, with a 64 px row
blender.exe -b --factory-startup --python tools/blender/rook_sheet.py -- <out_dir> sheet [variant] [small]
    the design sheet of one variant (the chosen one by default); `small` also writes a half-size copy to iterate on

Workbench only, so no GPU lock. Studs, X right, Y forward, Z up, the character faces +Y. Every piece hangs from one
of R6's six parts at the engine's own pivots (r6rig.py), so a pose here is one the rig can hold. The shapes are the
model's own low mesh: rook_model.py (delivery 2) takes build() from here, finishes the pieces and bakes them."""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402

# --- the palette (sRGB) --------------------------------------------------------------------------------------

PALETTE = {
    "Oxblood": "#8E2B30", "OxbloodDeep": "#5A181F", "Bone": "#EADFC7", "BoneShade": "#C9BBA0", "Ember": "#FFA630",
    "Ink": "#1E1B22", "Charcoal": "#3A3840", "Iron": "#5C6370", "IronDeep": "#3D434F",
    "Steel": "#9197A3", "Skin": "#D9A47E", "SkinShade": "#9C6A4F",
}
CHIPS = (("Oxblood", "the jacket"), ("Bone", "tape, wrap, mark"), ("Ember", "the ram's heat"))
NEUTRALS = ("Ink", "Charcoal", "Iron", "Skin")

# --- the variants ---------------------------------------------------------------------------------------------
# hair: notch | merlon | wedge | crop.  collar: how high its back stands (studs from the floor).  g: the gauntlet's
# size.  fist: ram | drum.  The rest are switches.  BASE is the chosen design, and the pack sets the others beside it.

BASE = dict(hair="notch", collar=4.72, g=1.25, fist="ram", pauldron=True, pipes=False, tails=False, tail=1.0)
VARIANTS = {
    "chosen": {},
    "small ram": dict(g=0.95, pauldron=False),
    "merlon hair": dict(hair="merlon"),
    "crop, tall collar": dict(hair="crop", collar=5.05),
    "drum": dict(fist="drum", g=1.2),
    "tails, pipes": dict(tails=True, pipes=True),
    "giant ram": dict(g=1.5, pipes=True, tail=1.4),
    "plain wedge": dict(hair="wedge", pauldron=False),
}
CHOSEN = "chosen"

SEGS = 28
B = 14.0  # the superellipse of a block: square, with the corner just eased
DOWN = Vector((0, 0, -1))


# --- shapes ---------------------------------------------------------------------------------------------------

def srgb(code):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return tuple(lin(int(code[i:i + 2], 16) / 255) for i in (1, 3, 5)) + (1.0,)


def rgb(code):
    return tuple(int(code[i:i + 2], 16) / 255 for i in (1, 3, 5))


def materials(hot=False):
    """One material per palette colour, and Glow: the knuckles and the piston's rod, steel until the ram is hot."""
    made = {}
    for name, code in {**PALETTE, "Glow": PALETTE["Ember" if hot else "Steel"]}.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def ring(cx, cy, w, d, n, segs=SEGS):
    """A superellipse: n = 2 is an ellipse, higher is boxier. Angle 90° is the front."""
    for i in range(segs):
        t = 2 * math.pi * i / segs
        c, s = math.cos(t), math.sin(t)
        yield (cx + 0.5 * w * math.copysign(abs(c) ** (2 / n), c), cy + 0.5 * d * math.copysign(abs(s) ** (2 / n), s), t)


def loft(name, rings, material, n=4.0, caps=True, closed=False):
    """Rings (z, cx, cy, w, d) from the bottom up, skinned. A ring's z may be a function of the angle. `closed`
    joins the last ring to the first: a wall with thickness, like a collar."""
    bm = bmesh.new()
    loops = [[bm.verts.new((x, y, z(t) if callable(z) else z)) for x, y, t in ring(cx, cy, w, d, n)]
             for z, cx, cy, w, d in rings]
    pairs = list(zip(loops, loops[1:])) + ([(loops[-1], loops[0])] if closed else [])
    for a, b in pairs:
        for k in range(SEGS):
            bm.faces.new((a[k], a[(k + 1) % SEGS], b[(k + 1) % SEGS], b[k]))
    if caps and not closed:
        bm.faces.new(list(reversed(loops[0])))
        bm.faces.new(loops[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def slab(name, centre, size, material, rot=(0, 0, 0)):
    return bl.place(bl.box(name, size, material), location=centre, rotation=rot)


def hexa(name, verts, material):
    """Eight corners: the bottom four, then the top four, both going round the same way."""
    bm = bmesh.new()
    v = [bm.verts.new(p) for p in verts]
    for f in ((3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
        bm.faces.new([v[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def wedge(name, x0, x1, y0, y1, z0, top_back, top_front, material, lean=0.0):
    """A block whose top rises from the back to the front, and whose front leans out."""
    return hexa(name, [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                       (x0, y0, top_back), (x1, y0, top_back), (x1, y1 + lean, top_front), (x0, y1 + lean, top_front)],
                material)


# --- the body -------------------------------------------------------------------------------------------------

PIVOTS = {"root": (0, 0, 3), "neck": (0, 0, 4), "rs": (1, 0, 3.5), "ls": (-1, 0, 3.5), "rh": (1, 0, 2), "lh": (-1, 0, 2)}


def gauntlet(p):
    """The gauntlet's numbers: the fist's width and depth, its bottom, the fist's top, the wrist, the cuff."""
    g = p["g"]
    zb = 2.0 - 0.45 * g
    return 1.55 * g, 1.4 * g, zb, zb + 0.8 * g, zb + 0.8 * g + 0.4, 3.3


def build(scene, variant, hot=False, model=False):
    """Rook, standing square. Returns the joints: empties at R6's pivots, with every piece parented to its part.
    `hot` lights the knuckles and draws the piston out: the gauntlet as it is through Haymaker's wind-up. `model`
    builds the piston's rod at its full length, sunk in its case, for the piece that slides (rook_model.py)."""
    p = dict(BASE, **VARIANTS[variant])
    m = materials(hot)
    joints = {}
    for name, at in PIVOTS.items():
        j = bpy.data.objects.new(name, None)
        scene.collection.objects.link(j)
        j.location = at
        j.rotation_mode = "QUATERNION"
        if name != "root":
            j.parent = joints["root"]
            j.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS["root"]))
        joints[name] = j

    def on(part, *objs):
        for o in objs:
            o.parent = joints[part]
            o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[part]))

    # torso: the waistband, the wrap, the cropped jacket, its collar, the mark on its back
    # The body is R6's own blocks (the director, 2026-11-12: "it should look more R6"): clothes are thin shells on
    # them, and only the gauntlet, the collar, the hair and the tape ends stand off the blocks.
    hem = 2.98
    on("root",
       loft("Waist", [(2.0, 0, 0, 2.02, 1.02), (2.22, 0, 0, 2.02, 1.02)], m["Ink"], n=B),
       slab("Buckle", (0, 0.52, 2.11), (0.36, 0.07, 0.2), m["Steel"]),
       loft("Wrap", [(2.2, 0, 0, 2.0, 1.0), (3.02, 0, 0, 2.0, 1.0)], m["Bone"], n=B),
       *[loft("WrapTurn", [(z, 0, 0, 2.02, 1.02), (z + 0.035, 0, 0, 2.02, 1.02)], m["BoneShade"], n=B) for z in (2.4, 2.6, 2.8)],
       loft("Jacket", [(hem, 0, 0, 2.1, 1.1), (3.2, 0, 0, 2.06, 1.07), (4.0, 0, 0, 2.06, 1.07)], m["Oxblood"], n=B),
       hexa("OpenWrap", [(-0.22, 0.5, hem - 0.01), (0.22, 0.5, hem - 0.01), (0.22, 0.56, hem - 0.01), (-0.22, 0.56, hem - 0.01),
                         (-0.28, 0.5, 3.5), (0.28, 0.5, 3.5), (0.28, 0.55, 3.5), (-0.28, 0.55, 3.5)], m["Bone"]),
       hexa("OpenChest", [(-0.28, 0.5, 3.5), (0.28, 0.5, 3.5), (0.28, 0.55, 3.5), (-0.28, 0.55, 3.5),
                          (-0.36, 0.5, 4.0), (0.36, 0.5, 4.0), (0.36, 0.55, 4.0), (-0.36, 0.55, 4.0)], m["Skin"]),
       *[hexa("Lapel", [(min(e * 0.22, e * 0.32), 0.5, hem - 0.01), (max(e * 0.22, e * 0.32), 0.5, hem - 0.01),
                        (max(e * 0.22, e * 0.32), 0.575, hem - 0.01), (min(e * 0.22, e * 0.32), 0.575, hem - 0.01),
                        (min(e * 0.36, e * 0.5), 0.5, 4.0), (max(e * 0.36, e * 0.5), 0.5, 4.0),
                        (max(e * 0.36, e * 0.5), 0.56, 4.0), (min(e * 0.36, e * 0.5), 0.56, 4.0)], m["OxbloodDeep"])
         for e in (-1, 1)])
    back = p["collar"]

    def collar_top(t, lift=0.0):
        w = min(1.0, max(0.0, ((1 - math.sin(t)) / 2 - 0.42) / 0.45))  # 0 round the front and sides, 1 across the back
        return 4.1 + (back - 4.1) * (w * w * (3 - 2 * w)) + lift

    on("root", loft("Collar", [(3.96, 0, -0.02, 1.5, 1.44), (collar_top, 0, -0.1, 1.56, 1.6),
                                (lambda t: collar_top(t, -0.02), 0, -0.1, 1.44, 1.48), (3.96, 0, -0.02, 1.38, 1.32)],
                    m["Oxblood"], closed=True),
       loft("CollarLining", [(3.98, 0, -0.02, 1.39, 1.33), (lambda t: collar_top(t, -0.04), 0, -0.1, 1.45, 1.49)],
            m["OxbloodDeep"], caps=False),
       *[slab("CollarMerlon", (x, -0.85, back + 0.07), (0.3, 0.1, 0.2), m["Oxblood"]) for x in (-0.42, 0, 0.42)],
       slab("Mark", (0, -0.535, 3.3), (1.5, 0.05, 0.14), m["Bone"]),
       *[slab("Mark", (x, -0.535, 3.5), (0.38, 0.05, 0.28), m["Bone"]) for x in (-0.56, 0, 0.56)])
    if p["tails"]:
        on("root", *[hexa("Tail", [(x - 0.42, -0.6, 2.3), (x + 0.3, -0.6, 2.3), (x + 0.3, -0.52, 2.3), (x - 0.42, -0.52, 2.3),
                                   (x - 0.5, -0.66, 3.0), (x + 0.5, -0.66, 3.0), (x + 0.5, -0.56, 3.0), (x - 0.5, -0.56, 3.0)],
                          m["Oxblood"]) for x in (-0.56, 0.56)])

    # the right arm: a sleeve, a shoulder cap, then the ram: a fist block on a narrow taped wrist, and a piston on
    # its back that draws out through the wind-up. Its axis sits a quarter stud wide of the arm's, so he carries it
    # held off the hip.
    g = p["g"]
    wf, df, zb, zf, zw, zc = gauntlet(p)
    n_fist = 6.0 if p["fist"] == "ram" else 2.4
    gx = 1.72

    def gr(z, k, y=0.06):  # a gauntlet ring, k of the fist's width
        return (z, gx, y, wf * k, df * k)

    glow = m["Glow"]
    zs = zb + 0.64 * (zf - zb)  # the seam round the fist, where its two plates meet
    on("rs",
       loft("Sleeve", [(3.0, 1.5, 0, 1.05, 1.05), (4.02, 1.5, 0, 1.05, 1.05)], m["Oxblood"], n=B),
       loft("Fist", [gr(zb, 0.9), gr(zb + 0.12, 1.0), gr(zs - 0.035, 1.0), gr(zs - 0.03, 0.95), gr(zs + 0.03, 0.95),
                     gr(zs + 0.035, 1.0), gr(zf - 0.12, 1.0), gr(zf, 0.9)], m["Iron"], n=n_fist),
       loft("Heat", [gr(zf - 0.02, 0.72), gr(zf + 0.14, 0.68)], m["Ember"], n=n_fist),
       loft("Forearm", [gr(zf + 0.12, 0.6), gr(zw + 0.12, 0.6), gr(zw + 0.14, 0.76), gr(zc, 0.76), gr(zc + 0.02, 0.86), gr(zc + 0.18, 0.86),
                        gr(zc + 0.2, 0.6)],
            m["IronDeep"], n=5),
       loft("Strap", [gr(zw - 0.1, 0.63), gr(zw + 0.1, 0.63)], m["Bone"], n=5))
    if p["fist"] == "ram":
        on("rs", *[slab("Knuckle", (gx + k * wf * 0.34, 0.06, zb - 0.09), (wf * 0.24, df * 0.84, 0.26), glow) for k in (-1, 0, 1)])
    else:
        on("rs", loft("Band", [gr(zb + 0.2, 1.04), gr(zb + 0.36, 1.04)], glow, n=n_fist))
    for along, across in ((0, 1), (1, 0)):  # two bolts on the fist's outer face, two on its front
        for k in (-1, 1):
            at = (gx + wf * (0.5 * across + 0.26 * k * along), 0.06 + df * (0.5 * along + 0.26 * k * across), zb + 0.3 * (zf - zb))
            on("rs", bl.place(bl.cylinder("Bolt", 0.085 * g, 0.09, 10, m["Steel"]), location=at, rotation=(90 * along, 90 * across, 0)))
    px, py, drawn = gx + wf * 0.12, 0.06 - df * 0.4, 0.75 if hot else 0.1
    rod = 0.85 if model else drawn + 0.1
    on("rs",
       bl.place(bl.cylinder("PistonCase", 0.21 * g, zc - zw + 0.25, 14, m["Iron"]), location=(px, py, (zc + zw) / 2 + 0.1)),
       bl.place(bl.cylinder("PistonRod", 0.1 * g, rod, 10, glow), location=(px, py, zc + 0.27 + drawn - rod / 2)),
       bl.place(bl.cylinder("PistonCap", 0.24 * g, 0.16, 14, m["Steel"]), location=(px, py, zc + 0.3 + drawn)))
    if p["pauldron"]:
        on("rs", loft("Pauldron", [(3.78, 1.56, 0, 1.3, 1.3), (4.1, 1.56, 0, 1.3, 1.3), (4.22, 1.54, 0, 1.0, 1.0)], m["Iron"], n=8))
    if p["pipes"]:
        for x in (-0.22, 0.22):
            pipe = bl.place(bl.cylinder("Pipe", 0.13 * g, 0.7 * g, 12, m["Steel"]), rotation=(-35, 0, 0))
            on("rs", bl.place(pipe, location=(gx + x * g, 0.06 - df * 0.5, zw + 0.5)))

    # the left arm: the sleeve torn off, bare, taped from the elbow, two loose ends of tape
    on("ls",
       loft("SleeveTorn", [(lambda t: 3.5 + 0.07 * math.sin(7 * t), -1.5, 0, 1.05, 1.05), (4.02, -1.5, 0, 1.05, 1.05)],
            m["Oxblood"], n=B),
       loft("UpperArm", [(2.9, -1.5, 0, 1.0, 1.0), (3.6, -1.5, 0, 1.0, 1.0)], m["Skin"], n=B),
       loft("Tape", [(2.0, -1.5, 0, 1.03, 1.03), (2.95, -1.5, 0, 1.03, 1.03)], m["Bone"], n=B),
       *[loft("TapeTurn", [(z, -1.5, 0, 1.05, 1.05), (z + 0.035, -1.5, 0, 1.05, 1.05)], m["BoneShade"], n=B)
         for z in (2.2, 2.42, 2.64)])
    k = p["tail"]
    for length, x, spread in ((0.85 * k, -2.0, 0.0), (0.5 * k, -2.05, 0.1)):
        path = [(-0.4, 2.44), (-0.58 - spread, 2.4), (-0.7 - spread, 2.44 - 0.4 * length), (-0.76 - spread, 2.44 - 0.8 * length),
                (-0.7 - spread, 2.44 - 1.15 * length)]
        on("ls", bl.place(bl.band_along("TapeEnd", path, 0.05, 0.2, m["Bone"]), location=(x, 0, 0), rotation=(0, 0, -12)))

    # R6's own head: the round one, 1.25 studs across and tall, about the Head part's centre. The face is drawn on
    # its curve the way a face decal sits: two dark eyes set level and well apart, each with one catchlight on the
    # same side, under flat heavy brows. The flat-top is cut like a battlement.
    crop = p["hair"] == "crop"
    radius = 0.625

    def face(name, x, z, w, h, material, tilt=0.0, proud=0.0):
        y = math.sqrt(radius * radius - x * x)
        return slab(name, (x, y + proud, z), (w, 0.05, h), material, rot=(0, tilt, -math.degrees(math.asin(x / radius))))

    on("neck",
       loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                     (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2),
       loft("HairCap", [(lambda t: 4.96 - 0.62 * min(1.0, (1 - math.sin(t)) * 0.8) ** 2, 0, 0, 1.31, 1.31),
                        (5.06, 0, 0, 1.31, 1.31), (5.26 if crop else 5.17, 0, 0, 1.05, 1.05)], m["Ink"], n=2),
       face("BrowR", 0.27, 4.74, 0.32, 0.075, m["Ink"], tilt=-9, proud=0.012),
       face("BrowL", -0.27, 4.74, 0.32, 0.075, m["Ink"], tilt=9, proud=0.012),
       face("EyeR", 0.27, 4.56, 0.17, 0.2, m["Ink"]),
       face("EyeL", -0.27, 4.56, 0.17, 0.2, m["Ink"]),
       face("LightR", 0.305, 4.615, 0.055, 0.06, m["Bone"], proud=0.012),
       face("LightL", -0.235, 4.615, 0.055, 0.06, m["Bone"], proud=0.012),
       face("Plaster", 0.0, 4.4, 0.3, 0.085, m["Bone"], tilt=7, proud=0.006),
       face("Mouth", 0.05, 4.2, 0.26, 0.035, m["SkinShade"], tilt=-7))
    blocks = {"notch": ((-0.64, -0.4), (-0.22, 0.64)), "merlon": ((-0.64, -0.28), (-0.17, 0.17), (0.28, 0.64)),
              "wedge": ((-0.64, 0.64),), "crop": ()}[p["hair"]]

    def flat_top(x0, x1, back, front):
        """Hair that grows from the hairline: wider and further forward at its top than at its roots, so it reads
        as a cut, never as a cap's brim."""
        a, b = (0.05 if x0 < -0.6 else 0.0), (0.05 if x1 > 0.6 else 0.0)
        return hexa("Hair", [(x0, -0.6, 5.08), (x1, -0.6, 5.08), (x1, 0.6, 4.94), (x0, 0.6, 4.94),
                             (x0 - a, -0.66, back), (x1 + b, -0.66, back), (x1 + b, 0.72, front), (x0 - a, 0.72, front)], m["Ink"])

    on("neck", *[flat_top(x0, x1, 5.36, 5.62) for x0, x1 in blocks])
    if p["hair"] == "notch":
        on("neck", flat_top(-0.42, -0.2, 5.24, 5.46))

    # the legs: R6's blocks as plain trousers, and shoes that are the block's foot with a heavy sole and a short toe
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(part,
           loft("Trouser", [(0.3, cx, 0, 1.0, 1.02), (2.0, cx, 0, 1.0, 1.02)], m["Charcoal"], n=B),
           loft("TrouserCuff", [(0.3, cx, 0, 1.05, 1.07), (0.54, cx, 0, 1.05, 1.07)], m["Charcoal"], n=B),
           loft("Sole", [(0.0, cx, 0.08, 1.0, 1.2), (0.1, cx, 0.08, 1.0, 1.2)], m["BoneShade"], n=B),
           loft("Shoe", [(0.1, cx, 0.07, 1.0, 1.16), (0.3, cx, 0.05, 1.0, 1.12), (0.34, cx, 0.0, 0.96, 1.0)], m["Ink"], n=B))
    return joints


# --- poses ----------------------------------------------------------------------------------------------------

def aim(joint, body, direction, twist=0.0, stage=True):
    """Points a limb along a direction, by the shortest turn from hanging, then twists it about its length. The
    direction is the stage's, or the body's own when `stage` is off: a turned body's arm is keyed in its frame."""
    d = Vector(direction).normalized()
    if stage:
        d = body.inverted() @ d
    joint.rotation_quaternion = DOWN.rotation_difference(d) @ Quaternion((0, 0, 1), math.radians(twist))


def stand_on_floor(joints):
    bpy.context.view_layer.update()
    low = min((o.matrix_world @ v.co).z for part in ("rh", "lh") for o in joints[part].children for v in o.data.vertices)
    joints["root"].location.z -= low
    bpy.context.view_layer.update()


def pose_square(joints):
    """Square on, arms held off the body, as a model sheet stands a figure."""
    aim(joints["rs"], Quaternion(), (0.36, 0.0, -1.0))
    aim(joints["ls"], Quaternion(), (-0.12, 0.0, -1.0))
    stand_on_floor(joints)


def pose_idle(joints):
    """How he stands: bladed a little, feet apart, the gauntlet hanging heavy and wide of the hip."""
    body = Matrix.Rotation(math.radians(-14), 3, "Z").to_quaternion()
    joints["root"].rotation_quaternion = body
    aim(joints["rs"], body, (0.36, 0.1, -1.0), stage=False)
    aim(joints["ls"], body, (-0.2, 0.2, -1.0), stage=False)
    joints["neck"].rotation_quaternion = body.inverted() @ Quaternion((1, 0, 0), math.radians(-4))
    aim(joints["lh"], body, (-0.2, 0.2, -1.0), twist=10)
    aim(joints["rh"], body, (0.2, -0.16, -1.0))
    stand_on_floor(joints)


def pose_windup(joints):
    """Haymaker's key pose: the body wound round until his back half-shows, sunk onto the back foot, the gauntlet
    drawn as far behind him as the arm goes, the taped hand out at the target, the eyes never leaving it."""
    body = (Matrix.Rotation(math.radians(16), 3, "X") @ Matrix.Rotation(math.radians(-68), 3, "Z")).to_quaternion()
    root = joints["root"]
    root.rotation_quaternion = body
    root.location = (0, -0.45, 3)
    aim(joints["rs"], body, (0.3, -0.88, 0.4), stage=False)
    aim(joints["ls"], body, (-0.05, 1.0, -0.1))
    joints["neck"].rotation_quaternion = body.inverted() @ Quaternion((1, 0, 0), math.radians(-8))
    aim(joints["lh"], body, (-0.28, 0.78, -1.0), twist=50)
    aim(joints["rh"], body, (0.25, -0.5, -1.0))
    stand_on_floor(joints)


POSES = {"square": pose_square, "idle": pose_idle, "windup": pose_windup}


# --- rendering ------------------------------------------------------------------------------------------------

def workbench(scene, width, height, flat=False):
    r = scene.render
    r.engine = "BLENDER_WORKBENCH"
    r.resolution_x, r.resolution_y, r.resolution_percentage = width, height, 100
    r.film_transparent = True
    r.image_settings.file_format = "PNG"
    r.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    s = scene.display.shading
    s.light = "FLAT" if flat else "STUDIO"
    s.color_type = "MATERIAL"
    s.show_object_outline = not flat
    s.object_outline_color = (0.03, 0.025, 0.04)
    s.show_cavity = not flat
    if not flat:
        s.cavity_type = "BOTH"
    s.show_shadows = False
    s.show_specular_highlight = False
    scene.display.render_aa = "16"


def shoot(scene, path, azimuth, elevation, centre, span):
    """An orthographic view. Azimuth 0 looks at his back, 180 at his face, 90 at his right side."""
    cam = scene.camera
    if cam is None:
        cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
        scene.collection.objects.link(cam)
        scene.camera = cam
        cam.data.type = "ORTHO"
        cam.data.clip_end = 200
    cam.data.ortho_scale = span
    a, e = math.radians(azimuth), math.radians(elevation)
    offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e))) * 40
    cam.location = Vector(centre) + offset
    cam.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    return load(path)


def load(path):
    image = bpy.data.images.load(str(path))
    w, h = image.size
    data = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(h, w, 4)[::-1].copy()  # row 0 = the top


def save(pixels, path):
    h, w = pixels.shape[:2]
    image = bpy.data.images.new("Sheet", w, h, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(pixels[::-1]).ravel())
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    print(f"wrote {path} {w}x{h}")


# --- sheet pieces ---------------------------------------------------------------------------------------------

def shrink(rgba, factor):
    """Area-averaged, on premultiplied colour, so an edge keeps its own colour."""
    pm = rgba.copy()
    pm[..., :3] *= pm[..., 3:]
    for axis in (0, 1):
        pm = np.moveaxis(pm, axis, 0)
        count = pm.shape[0]
        size = max(1, round(count * factor))
        total = np.concatenate([np.zeros_like(pm[:1], dtype=np.float64), np.cumsum(pm, axis=0, dtype=np.float64)])
        edges = np.linspace(0, count, size + 1)
        whole = np.minimum(edges.astype(int), count - 1)
        at = total[whole] + (edges - whole).reshape(-1, 1, 1) * pm[whole]
        pm = np.moveaxis(((at[1:] - at[:-1]) * size / count).astype(np.float32), 0, axis)
    alpha = pm[..., 3:]
    pm[..., :3] = np.where(alpha > 1e-6, pm[..., :3] / np.maximum(alpha, 1e-6), 0)
    return pm


def black(rgba, colour=(0.04, 0.04, 0.05)):
    out = rgba.copy()
    out[..., :3] = colour
    return out


def grey(rgba):
    out = rgba.copy()
    lin = np.where(out[..., :3] <= 0.04045, out[..., :3] / 12.92, ((out[..., :3] + 0.055) / 1.055) ** 2.4)
    y = lin @ np.array((0.2126, 0.7152, 0.0722), dtype=np.float32)
    y = np.where(y <= 0.0031308, y * 12.92, 1.055 * np.maximum(y, 1e-9) ** (1 / 2.4) - 0.055)
    out[..., :3] = y[..., None]
    return out


def canvas(width, height, colour):
    c = np.empty((height, width, 4), dtype=np.float32)
    c[..., :3], c[..., 3] = colour, 1.0
    return c


def fill(target, x, y, w, h, colour):
    target[max(y, 0):y + h, max(x, 0):x + w, :3] = colour


def paste(target, rgba, x, y):
    """Alpha-over, with the picture's top-left corner at x, y. What falls outside is cut."""
    h, w = rgba.shape[:2]
    x0, y0, x1, y1 = max(x, 0), max(y, 0), min(x + w, target.shape[1]), min(y + h, target.shape[0])
    if x1 <= x0 or y1 <= y0:
        return
    src = rgba[y0 - y:y1 - y, x0 - x:x1 - x]
    a = src[..., 3:]
    target[y0:y1, x0:x1, :3] = src[..., :3] * a + target[y0:y1, x0:x1, :3] * (1 - a)


def trim(rgba):
    """Cuts a picture to what's drawn in it."""
    ys, xs = np.nonzero(rgba[..., 3] > 0.02)
    return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def stand(target, rgba, x, floor, width):
    """Pastes a figure cut to its outline, centred in a column `width` wide from x, its feet on the row `floor`."""
    cut = trim(rgba)
    paste(target, cut, x + (width - cut.shape[1]) // 2, floor - cut.shape[0])


def text_layer(width, height, items):
    """Every line of text on the sheet, as one transparent picture. Items: (x, y of the cap's top, size, text, sRGB)."""
    scene = bl.reset_scene()
    made = {}
    for x, y, size, text, code in items:
        curve = bpy.data.curves.new("Text", "FONT")
        curve.body = text
        curve.size = size
        obj = bpy.data.objects.new("Text", curve)
        scene.collection.objects.link(obj)
        obj.location = (x, height - y - size * 0.72, 0)
        if code not in made:
            made[code] = bpy.data.materials.new(code)
            made[code].diffuse_color = srgb(code)
        curve.materials.append(made[code])
    workbench(scene, width, height, flat=True)
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(width, height)
    cam.location = (width / 2, height / 2, 10)
    path = OUT / "_text.png"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    layer = load(path)
    path.unlink()
    return layer


def takes(variant, wanted, size, span, centre=(0, 0, 3.35)):
    """Renders one variant: {(pose, view): picture}, and what was measured. `wanted`: pose -> {view: (azimuth, elevation)}."""
    out = {}
    for pose, views in wanted.items():
        scene = bl.reset_scene()
        joints = build(scene, variant, hot=pose == "windup")
        POSES[pose](joints)
        workbench(scene, *size)
        for view, (azimuth, elevation) in views.items():
            path = OUT / f"_{pose}_{view}.png"
            out[pose, view] = shoot(scene, path, azimuth, elevation, centre, span)
            path.unlink()
        meshes = [o for o in scene.objects if o.type == "MESH"]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        out[pose, "size"] = tuple(round(max(q[i] for q in pts) - min(q[i] for q in pts), 2) for i in range(3))
        out[pose, "top"] = round(max(q.z for q in pts), 2)
        out["tris"] = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
    return out


GAME = (28, 18)  # the player's camera, behind his right shoulder and above: an assumption until Config holds its numbers
FRONT = (146, 8)
FLINCH = (128, 6)  # what the one he's about to hit sees
PAPER, NIGHT, DAY = rgb("#DDDAD3"), rgb("#14161D"), rgb("#EDE7D8")


def pack():
    wanted = {"idle": {"front": FRONT, "game": GAME}, "windup": {"side": (90, 4), "game": GAME}}
    size, span = (300, 400), 9.0
    per_stud = size[1] / span
    tile = (150, 200)
    names = list(VARIANTS)
    rows = (("idle", "front"), ("idle", "game"), ("windup", "side"), ("windup", "game"))
    small = 64 / (5 * per_stud)
    sh = round(size[1] * small)
    height = len(rows) * tile[1] + 2 * sh + 30
    sheet = canvas(len(names) * tile[0], height, PAPER)
    fill(sheet, 0, len(rows) * tile[1], sheet.shape[1], sh, NIGHT)
    for i, name in enumerate(names):
        shots = takes(name, wanted, size, span)
        print(f"{name}: idle {shots['idle', 'size']} studs, wind-up top {shots['windup', 'top']}, blockout tris {shots['tris']}")
        for r, key in enumerate(rows):
            paste(sheet, shrink(black(shots[key]), 0.5), i * tile[0], r * tile[1])
        y = len(rows) * tile[1]
        paste(sheet, shrink(shots["idle", "game"], small), i * tile[0] + 4, y)
        paste(sheet, shrink(shots["windup", "game"], small), i * tile[0] + 70, y)
        paste(sheet, shrink(black(shots["idle", "game"]), small), i * tile[0] + 4, y + sh)
        paste(sheet, shrink(black(shots["windup", "game"]), small), i * tile[0] + 70, y + sh)
    labels = [(i * tile[0] + 6, height - 24, 17, name, "#222222") for i, name in enumerate(names)]
    paste(sheet, text_layer(sheet.shape[1], height, labels), 0, 0)
    save(sheet, OUT / "rook_pack.png")


def sheet(variant, small):
    wanted = {"square": {"front": (180, 0), "back": (0, 0)},
              "idle": {"front": FRONT, "game": GAME},
              "windup": {"flinch": FLINCH, "side": (90, 3), "game": GAME}}
    size, span = (1000, 1000), 10.0  # 100 px a stud
    s = takes(variant, wanted, size, span)
    p = dict(BASE, **VARIANTS[variant])
    wf, df, zb, zf, zw, zc = gauntlet(p)
    print(f"{variant}: square {s['square', 'size']} studs, top {s['square', 'top']}; wind-up {s['windup', 'size']}, "
          f"top {s['windup', 'top']}; gauntlet {wf:.2f} x {df:.2f} x {zc + 0.15 - zb + 0.21:.2f}; blockout tris {s['tris']}")
    W, H = 1920, 1200
    page = canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 64, "ROOK", ink),
            (268, 36, 24, "Common / Strength / Warrior. A street brawler, the first Voidkin.", ink),
            (268, 70, 20, "One idea: a square tower of a man with one battering ram. Everything he owns is on his right arm.", soft)]

    # row A: who he is. 0.86 of the render, so 86 px a stud
    k, floor = 0.62, 570
    cols = ((20, 340, "idle", "front", True, "outline"), (360, 340, "square", "front", False, "front, on the R6 body"),
            (700, 340, "square", "back", False, "back"), (1040, 340, "idle", "front", False, "three-quarter, how he stands"),
            (1380, 300, "idle", "game", False, "from the player's camera"))
    for x, width, pose, view, dark, label in cols:
        shot = shrink(s[pose, view], k)
        stand(page, black(shot) if dark else shot, x, floor, width)
        text.append((x + 14, floor + 14, 19, label, soft))
    fill(page, 30, floor + 2, 1640, 2, rgb("#BDB8AE"))

    # the chips
    x = 1700
    for i, (name, role) in enumerate(CHIPS):
        y = 120 + i * 118
        fill(page, x, y, 96, 96, rgb(PALETTE[name]))
        text += [(x + 108, y + 10, 22, name, ink), (x + 108, y + 40, 16, PALETTE[name], soft), (x + 108, y + 64, 16, role, soft)]
    for i, name in enumerate(NEUTRALS):
        fill(page, x + i * 54, 480, 46, 46, rgb(PALETTE[name]))
        text.append((x + i * 54, 534, 11, name, soft))
    text += [(x, 568, 16, "Reads, in order:", ink), (x, 592, 16, "1 the ram, low and wide", soft),
             (x, 614, 16, "2 the flat-top and collar", soft), (x, 636, 16, "3 the bone band", soft)]

    # row B: Haymaker's key pose
    floor, k = 1130, 0.7
    text.append((40, 620, 30, "HAYMAKER, the wind-up", ink))
    text.append((40, 662, 18, "Wound round until his back half-shows. The piston draws out and the knuckles light. "
                 "The taped hand marks the target.", soft))
    for x, width, view, dark, label in ((20, 520, "flinch", False, "three-quarter, from the target's side"), (540, 540, "side", True, "outline, side on"),
                                        (1080, 340, "game", False, "from the player's camera")):
        shot = shrink(s["windup", view], k)
        stand(page, black(shot) if dark else shot, x, floor, width)
        text.append((x + 14, floor + 14, 19, label, soft))
    fill(page, 30, floor + 2, 1380, 2, rgb("#BDB8AE"))

    # at 64 px: a 5-stud body 64 px tall, over a dark and a bright ground, and in black
    f64 = 64 / 500
    x0, y0 = 1440, 676
    text.append((x0, y0, 19, "at 64 px, dark and bright grounds", soft))
    for r, (ground, sil) in enumerate(((NIGHT, False), (DAY, False), (PAPER, True))):
        y = y0 + 30 + r * 98
        fill(page, x0, y, 450, 96, ground)
        for c, key in enumerate((("idle", "game"), ("idle", "front"), ("windup", "game"), ("windup", "flinch"))):
            shot = shrink(s[key], f64)
            stand(page, black(shot) if sil else shot, x0 + 8 + c * 110, y + 92, 104)
    # the value read: the same figures in grey
    y = y0 + 30 + 3 * 98 + 4
    text.append((x0, y, 19, "values", soft))
    for c, key in enumerate((("idle", "front"), ("idle", "game"), ("windup", "flinch"))):
        stand(page, grey(shrink(s[key], 0.24)), x0 + c * 150, 1156, 150)

    sizes = s["square", "size"]
    text.append((40, 1174, 15, f"Blockout on R6 at the player's height: 5 studs to the crown, {s['square', 'top']} to the hair's tip, "
                 f"{sizes[0]} wide. Gauntlet {wf:.1f} x {df:.1f} x {zc + 0.36 - zb:.1f} studs, 0.25 wide of the arm. Views are orthographic. "
                 f"The player's camera is assumed (behind, 18 degrees up) until Config holds it.", soft))
    paste(page, text_layer(W, H, text), 0, 0)
    save(page, OUT / "rook_sheet.png")
    if small:
        save(shrink(page, 0.5), OUT / "rook_sheet_small.png")


if __name__ == "__main__":
    OUT = bl.out_dir()
    ARGS = sys.argv[sys.argv.index("--") + 2:]
    if ARGS and ARGS[0] == "pack":
        pack()
    else:
        names = [a for a in ARGS[1:] if a != "small"]
        sheet(" ".join(names) or CHOSEN, "small" in ARGS)
