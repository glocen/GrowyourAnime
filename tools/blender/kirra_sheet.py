"""Kirra's design sheet (AR10, delivery 1): the courier, as a blockout on the R6 body.

blender.exe -b --factory-startup --python tools/blender/kirra_sheet.py -- <out_dir> [small]

The idea: a small body with a long streak. Her scarf is wound once up to her chin and trails twice her length behind
her even at rest, and it's the line Scarf Step draws through a Shade. Against Pip, the other small, quick starter: his
outline is tall and top-heavy (the hat, the bell robe, the lantern); hers is low, narrow and long. The player's camera
sees her back: two short blades crossed in an X, their saffron grips over her shoulders, and the satchel at her left
hip. Workbench only, so no GPU turn. Studs, X right, Y forward, Z up, Kirra faces +Y, and every piece hangs from one of
R6's six parts at the engine's own pivots, as rook_sheet.py's do (its shapes and sheet tools are used here). On the
sheet the scarf's tail is one ribbon; on the model it becomes a chain the clips carry.
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
import pip_sheet as ps  # noqa: E402
import rook_sheet as rs  # noqa: E402

PALETTE = {
    "Sky": "#47A6F5", "SkyDeep": "#2D5EA6", "Navy": "#283459", "NavyLift": "#3B4A7C", "Saffron": "#F0A830",
    "Bone": "#E9E0CC", "BoneShade": "#C6BBA2", "Leather": "#8A5530", "LeatherLight": "#A86F42", "LeatherDeep": "#4E2E1C",
    "Steel": "#BCC3CB", "SteelDeep": "#6E7681", "Soot": "#262230", "Skin": "#E8B894", "Ink": "#1A1820",
    "Ghost": "#A4A3AB",
}
CHIPS = (("Sky", "the scarf"), ("Navy", "jacket, trousers"), ("Saffron", "grips, cords, buckle"))
NEUTRALS = ("Bone", "Leather", "Steel", "Soot", "Skin")
PIVOTS = rs.PIVOTS
B = rs.B
loft, slab = rs.loft, rs.slab
KNOT = (-0.72, 0.02, 4.1)  # where the scarf is knotted, at the left of her neck: the tail leaves from here
TAIL = 10.0  # the tail's length, studs: twice her height
# The tail at rest, laid on her heading (her lean doesn't lift it): out past her left shoulder, back and to her left
# about evenly, so both the player's camera and a front view see its length, up to her eyes' height and down into an
# S that flicks up at its end. Scaled from the knot to TAIL.
REST = ((-0.72, 0.02, 4.1), (-1.3, -0.25, 4.3), (-2.1, -1.0, 4.6), (-3.0, -2.0, 4.5), (-3.8, -3.0, 4.05),
        (-4.6, -3.9, 3.85), (-5.4, -4.7, 4.1), (-6.0, -5.5, 4.45))
STEP_ANGLE = 35.0  # Scarf Step crosses the Shade this far right of the line from the player's camera, so its line
#                    has length on the screen (straight away from the camera it'd fold to a streak)
TARGET = Vector((0, 5, 0))  # the Shade's feet, in Scarf Step
PAST = 3.8  # how far beyond the Shade she lands


def materials():
    made = {}
    for name, code in PALETTE.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def bar(name, a, b, width, depth, material):
    """A slab from a to b, in a plane of constant y: straps, sheaths."""
    a, b = Vector(a), Vector(b)
    d = b - a
    return slab(name, (a + b) / 2, (width, depth, d.length), material, rot=(0, math.degrees(math.atan2(d.x, d.z)), 0))


def spike(name, base, tip, half, material):
    """A lock of hair: a square base round `base`, drawn to a point at `tip`."""
    base, tip = Vector(base), Vector(tip)
    axis = (tip - base).normalized()
    side = axis.cross(Vector((0, 0, 1)) if abs(axis.z) < 0.9 else Vector((1, 0, 0))).normalized()
    up = axis.cross(side).normalized()
    bm = bmesh.new()
    ring = [bm.verts.new(base + (side * a + up * b) * half) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    point = bm.verts.new(tip)
    bm.faces.new(list(reversed(ring)))
    for k in range(4):
        bm.faces.new((ring[k], ring[(k + 1) % 4], point))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def ribbon(name, points, widths, thick, material, twists=None):
    """A flat band through `points`, its width held as near upright as the path allows, then turned `twists`
    (degrees) about the path: the scarf."""
    bm = bmesh.new()
    count = len(points)
    rings = []
    for i, p in enumerate(points):
        t = (points[min(i + 1, count - 1)] - points[max(i - 1, 0)]).normalized()
        w = Vector((0, 0, 1)) - t * t.z
        w = w.normalized() if w.length > 1e-4 else Vector((1, 0, 0))
        if twists:
            w = Quaternion(t, math.radians(twists[i])) @ w
        n = t.cross(w).normalized()
        rings.append([bm.verts.new(p + w * (widths[i] / 2) * a + n * (thick / 2) * b)
                      for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    for a, b in zip(rings, rings[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def run_length(points):
    run = [0.0]
    for a, b in zip(points, points[1:]):
        run.append(run[-1] + (b - a).length)
    return run


def tail(points, m, twist=35.0, turns=1.2):
    """The scarf's tail along `points` (from the knot out): Sky, narrowing a little, its last half-stud Bone so the
    line's end reads. Returns the pieces and the length."""
    run = run_length(points)
    total = run[-1]
    widths = [0.72 - 0.14 * s / total for s in run]
    twists = [twist * math.sin(2 * math.pi * turns * s / total) for s in run]
    cut = next(i for i, s in enumerate(run) if s >= total - 0.55)
    main = ribbon("Scarf", points[:cut + 1], widths[:cut + 1], 0.07, m["Sky"], twists[:cut + 1])
    end = ribbon("ScarfEnd", points[cut:], [w * 1.02 for w in widths[cut:]], 0.075, m["Bone"], twists[cut:])
    return [main, end], total


def knot_at(joints):
    bpy.context.view_layer.update()
    return joints["root"].matrix_world @ (Vector(KNOT) - Vector(PIVOTS["root"]))


def lay_rest_tail(joints, heading=0.0):
    """REST through a smooth curve, scaled from the knot so the tail is TAIL long, turned to her heading and hung from
    the knot where the pose has put it."""
    path = bl.smooth_path(REST, samples=48)
    k = TAIL / run_length(path)[-1]
    knot, yaw = Vector(KNOT), Matrix.Rotation(math.radians(heading), 3, "Z")
    at = knot_at(joints)
    tail([at + yaw @ ((p - knot) * k) for p in path], joints["m"])


def sheathed(name, top, tip, m, drawn=False):
    """A short blade in its sheath, slung across her back: a steel pommel, a saffron grip over her shoulder, a guard,
    the leather sheath with two saffron bindings and a steel chape. Drawn, only the empty sheath."""
    top, tip = Vector(top), Vector(tip)
    d = (tip - top).normalized()
    size = (tip - top).length

    def along(a, b, w, depth, material, label):
        return bar(f"{name}{label}", top + d * a, top + d * b, w, depth, material)

    pieces = [] if drawn else [along(0.0, 0.07, 0.2, 0.2, m["SteelDeep"], "Pommel"), along(0.07, 0.55, 0.16, 0.16, m["Saffron"], "Grip"),
                               along(0.55, 0.61, 0.38, 0.22, m["SteelDeep"], "Guard")]
    pieces += [along(0.61, size, 0.27, 0.14, m["Leather"], "Sheath"), along(0.61, 0.71, 0.31, 0.17, m["LeatherDeep"], "Throat"),
               along(size - 0.13, size, 0.29, 0.16, m["SteelDeep"], "Chape")]
    for f in (0.4, 0.74):
        c = 0.61 + (size - 0.61) * f
        pieces.append(along(c, c + 0.06, 0.31, 0.17, m["Saffron"], "Binding"))
    return pieces


def blade_in_hand(m):
    """The drawn blade, in the right fist at R6's hand: forward grip, the blade angled a little off the arm."""
    hand = (1.5, 0, 2.04)
    edge = [(-0.09, -0.36), (0.11, -0.36), (0.11, -1.48), (0.0, -1.8), (-0.09, -1.6)]
    pieces = [slab("DrawnGrip", (0, 0, -0.04), (0.15, 0.15, 0.5), m["Saffron"]),
              slab("DrawnGuard", (0, 0, -0.33), (0.32, 0.22, 0.05), m["SteelDeep"]),
              bl.profile("DrawnBlade", edge, 0.05, m["Steel"])]
    return [bl.place(o, location=hand, rotation=(28, 0, 0)) for o in pieces]


def ghost(m, at):
    """A grey Shade where Scarf Step's target stands: the line is read through it."""
    x, y = at.x, at.y
    g = m["Ghost"]
    pieces = [loft("GhostLeg", [(0.0, x + e * 0.5, y, 0.95, 0.95), (2.0, x + e * 0.5, y, 0.95, 0.95)], g, n=B) for e in (-1, 1)]
    pieces += [loft("GhostCoat", [(1.2, x, y, 2.7, 1.7), (2.6, x, y, 2.2, 1.2), (4.0, x, y, 2.1, 1.1)], g, n=B),
               loft("GhostHead", [(4.0, x, y, 1.1, 1.1), (5.0, x, y, 1.25, 1.25), (5.12, x, y, 0.9, 0.9)], g, n=2)]
    for o in pieces:
        o["ghost"] = True
    return pieces


def build(scene, drawn=False):
    """Kirra, standing square. Returns the joints: empties at R6's pivots. `drawn`: the blade over her right shoulder
    is in her hand. The scarf's long tail isn't here: each pose lays it from the knot once the body is posed."""
    m = materials()
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
    joints["m"] = m

    def on(part, *objs):
        for o in objs:
            o.parent = joints[part]
            o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[part]))

    # the jacket: short, cut at the waist, a lighter hem and a placket down its front; a belt with a saffron buckle,
    # the trousers' top under it
    on("root",
       loft("Hips", [(2.0, 0, 0, 2.0, 1.04), (2.26, 0, 0, 2.0, 1.04)], m["Navy"], n=B),
       loft("Belt", [(2.22, 0, 0, 2.04, 1.1), (2.42, 0, 0, 2.04, 1.1)], m["LeatherDeep"], n=B),
       slab("Buckle", (0.0, 0.565, 2.32), (0.24, 0.04, 0.16), m["Saffron"]),
       loft("Jacket", [(2.4, 0, 0, 2.1, 1.16), (2.9, 0, 0, 1.98, 1.08), (3.5, 0, 0, 2.06, 1.1), (3.96, 0, 0, 2.1, 1.12),
                       (4.03, 0, 0, 1.9, 1.0)], m["Navy"], n=B),
       loft("JacketHem", [(2.38, 0, 0, 2.14, 1.2), (2.52, 0, 0, 2.12, 1.18)], m["NavyLift"], n=B),
       slab("Placket", (0.14, 0.575, 3.22), (0.1, 0.03, 1.56), m["NavyLift"]))
    # the satchel's strap, from her right shoulder across her chest to the left hip, and down her back to the satchel
    on("root",
       bar("Strap", (0.72, 0.6, 3.98), (-0.95, 0.6, 2.42), 0.2, 0.05, m["LeatherDeep"]),
       slab("StrapTop", (0.72, 0.0, 4.04), (0.2, 1.24, 0.06), m["LeatherDeep"]),
       bar("StrapBack", (0.72, -0.6, 3.98), (-0.45, -0.6, 2.66), 0.2, 0.05, m["LeatherDeep"]),
       slab("StrapSide", (-1.04, 0.02, 2.44), (0.05, 1.18, 0.18), m["LeatherDeep"]))
    # the satchel at her left hip, behind: a flap with a saffron buckle, a paper parcel tied with cord in its mouth
    satchel = [slab("Satchel", (0, 0, 0), (0.95, 0.36, 0.7), m["Leather"]),
               slab("Flap", (0, -0.19, 0.12), (0.97, 0.05, 0.5), m["LeatherLight"]),
               slab("FlapTop", (0, 0, 0.36), (0.97, 0.4, 0.04), m["LeatherLight"]),
               slab("SatchelBuckle", (0, -0.225, -0.06), (0.16, 0.03, 0.14), m["Saffron"]),
               slab("Parcel", (0.2, 0.02, 0.5), (0.36, 0.26, 0.26), m["Bone"]),
               slab("Cord", (0.2, 0.02, 0.5), (0.38, 0.28, 0.04), m["Saffron"]),
               slab("Cord", (0.2, 0.02, 0.5), (0.05, 0.28, 0.28), m["Saffron"])]
    on("root", *[bl.place(o, location=(-0.62, -0.74, 2.3), rotation=(0, 0, 20)) for o in satchel])
    # the blades on her back, crossed in an X, their grips over her shoulders: what the player's camera sees
    on("root",
       *sheathed("Right", (0.78, -0.68, 4.45), (-0.5, -0.68, 2.78), m, drawn=drawn),
       *sheathed("Left", (-0.78, -0.84, 4.45), (0.5, -0.84, 2.78), m))
    # the scarf: wound once to her chin, knotted at the left of her neck, a short end down her chest; the long tail
    on("root",
       loft("Wrap", [(3.92, 0, 0.0, 1.56, 1.42), (4.06, 0, 0.02, 1.64, 1.48), (4.2, 0, 0.04, 1.5, 1.36), (4.2, 0, 0.04, 1.28, 1.12),
                     (3.92, 0, 0.0, 1.3, 1.14)], m["Sky"], n=2.5, closed=True),
       slab("Knot", KNOT, (0.42, 0.42, 0.36), m["Sky"], rot=(15, 10, 30)),
       *tail([Vector(p) for p in bl.smooth_path(((-0.72, 0.02, 4.1), (-0.62, 0.45, 3.85), (-0.52, 0.66, 3.4), (-0.5, 0.7, 3.02)), 10)],
             m, twist=12.0, turns=0.5)[0])

    # the sleeves pushed up past the elbow and rolled; the forearms bound in bone wraps; bare hands
    for part, e in (("rs", 1), ("ls", -1)):
        cx = e * 1.5
        on(part,
           loft("Sleeve", [(3.04, cx, 0, 0.92, 0.92), (3.6, cx, 0, 0.96, 0.96), (4.0, cx, 0, 0.98, 0.98), (4.06, e * 1.46, 0, 0.82, 0.84)],
                m["Navy"], n=B),
           loft("Roll", [(2.92, cx, 0, 1.0, 1.0), (3.12, cx, 0, 1.0, 1.0)], m["NavyLift"], n=B),
           loft("Wraps", [(2.2, cx, 0, 0.8, 0.8), (2.94, cx, 0, 0.84, 0.84)], m["Bone"], n=B),
           *[loft("WrapLine", [(z, cx, 0, 0.85, 0.85), (z + 0.04, cx, 0, 0.85, 0.85)], m["BoneShade"], n=B) for z in (2.42, 2.68)],
           loft("Hand", [(1.86, cx, 0, 0.72, 0.74), (2.22, cx, 0, 0.8, 0.8)], m["Skin"], n=B))
    if drawn:
        on("rs", *blade_in_hand(m))

    # R6's round head; a choppy crop swept back as if she's always running into wind, a fringe of three locks swept to
    # her left, a jaw-length lock before each ear; a courier's goggles pushed up on her brow, amber lenses; blue eyes
    # under a lash line that flicks up at the outer corner, the brows level and low: she's already decided
    radius = 0.625

    def face(name, x, z, w, h, material, tilt=0.0, proud=0.0):
        y = math.sqrt(radius * radius - x * x)
        return slab(name, (x, y + proud, z), (w, 0.05, h), material, rot=(0, tilt, -math.degrees(math.asin(x / radius))))

    def hairline(t):
        front, back = max(0.0, math.sin(t)), max(0.0, -math.sin(t))
        return 4.5 + 0.38 * front ** 1.5 - 0.16 * back

    def around(t, z, r):
        a = math.radians(t)
        return Vector((math.cos(a) * r, math.sin(a) * r, z)), Vector((math.cos(a), math.sin(a), 0))

    pieces = []
    for t, z, reach in ((185, 4.62, 0.36), (208, 4.5, 0.46), (234, 4.44, 0.54), (262, 4.42, 0.58), (290, 4.44, 0.54),
                        (316, 4.5, 0.46), (340, 4.62, 0.36)):
        base, out = around(t, z, 0.66)
        pieces.append(spike("Lock", base, base + out * 0.22 + Vector((0, -reach, -0.06)), 0.15, m["Soot"]))
    for t, reach in ((215, 0.32), (250, 0.4), (290, 0.4), (325, 0.32)):
        base, out = around(t, 5.08, 0.52)
        pieces.append(spike("Crown", base, base + out * 0.2 + Vector((0, -reach, -0.04)), 0.17, m["Soot"]))
    for t in (24, 156):  # jaw-length, curving toward her chin: they frame the face
        base, out = around(t, 4.7, 0.66)
        pieces.append(spike("Sidelock", base, base + out * 0.04 + Vector((0, 0.16, -0.68)), 0.17, m["Soot"]))
    for (x0, z0), (x1, z1) in (((0.34, 4.98), (0.16, 4.6)), ((0.08, 5.0), (-0.16, 4.56)), ((-0.18, 4.98), (-0.44, 4.5))):
        pieces.append(spike("Fringe", (x0, math.sqrt(0.66 ** 2 - x0 ** 2) - 0.06, z0),
                            (x1, math.sqrt(0.7 ** 2 - x1 ** 2) + 0.02, z1), 0.14, m["Soot"]))
    goggles = [loft("GoggleBand", [(4.9, 0, -0.01, 1.42, 1.42), (5.02, 0, -0.02, 1.42, 1.42)], m["LeatherDeep"], n=2)]
    for e in (-1, 1):
        x = e * 0.25
        y = math.sqrt(0.71 ** 2 - x ** 2)
        tilt = -math.degrees(math.asin(x / 0.71))
        goggles += [bl.place(bl.cylinder("GoggleRim", 0.19, 0.12, 16, m["SteelDeep"]), location=(x, y, 5.0), rotation=(-80, 0, tilt)),
                    bl.place(bl.cylinder("GoggleLens", 0.14, 0.14, 16, m["Saffron"]), location=(x, y + 0.02, 5.0), rotation=(-80, 0, tilt))]
    on("neck",
       loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                     (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2),
       loft("Hair", [(hairline, 0, 0, 1.36, 1.36), (5.0, 0, -0.03, 1.42, 1.42), (5.18, 0, -0.08, 1.3, 1.26), (5.3, 0, -0.12, 0.86, 0.82)],
            m["Soot"], n=2),
       *pieces, *goggles,
       face("BrowR", 0.27, 4.75, 0.22, 0.035, m["Soot"], tilt=-12, proud=0.03),
       face("EyeR", 0.25, 4.48, 0.19, 0.21, m["SkyDeep"], tilt=-6),
       face("EyeL", -0.25, 4.48, 0.19, 0.21, m["SkyDeep"], tilt=6),
       face("LashR", 0.27, 4.6, 0.27, 0.05, m["Ink"], tilt=-14, proud=0.01),
       face("LashL", -0.27, 4.6, 0.27, 0.05, m["Ink"], tilt=14, proud=0.01),
       face("LightR", 0.29, 4.53, 0.06, 0.06, m["Bone"], proud=0.012),
       face("LightL", -0.21, 4.53, 0.06, 0.06, m["Bone"], proud=0.012),
       face("Mouth", 0.02, 4.27, 0.13, 0.04, m["Ink"], proud=0.006))

    # the legs: fitted trousers into bone wraps from knee to ankle, soft low boots
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(part,
           loft("Trouser", [(0.98, cx, 0, 0.88, 0.9), (1.6, cx, 0, 0.92, 0.94), (2.0, cx, 0, 0.96, 0.98)], m["Navy"], n=B),
           loft("ShinWrap", [(0.3, cx, 0, 0.8, 0.82), (1.06, cx, 0, 0.86, 0.88)], m["Bone"], n=B),
           *[loft("ShinLine", [(z, cx, 0, 0.87, 0.89), (z + 0.04, cx, 0, 0.87, 0.89)], m["BoneShade"], n=B) for z in (0.55, 0.8)],
           loft("Sole", [(0.0, cx, 0.08, 0.9, 1.2), (0.08, cx, 0.08, 0.9, 1.2)], m["Ink"], n=B),
           loft("Boot", [(0.08, cx, 0.07, 0.9, 1.16), (0.26, cx, 0.03, 0.88, 1.02), (0.36, cx, 0, 0.84, 0.9)], m["LeatherDeep"], n=B))
    return joints


# --- poses ----------------------------------------------------------------------------------------------------

def turn(z=0.0, x=0.0):
    return (Matrix.Rotation(math.radians(z), 3, "Z") @ Matrix.Rotation(math.radians(x), 3, "X")).to_quaternion()


def pose_square(joints):
    rs.aim(joints["rs"], Quaternion(), (0.2, 0.0, -1.0))
    rs.aim(joints["ls"], Quaternion(), (-0.2, 0.0, -1.0))
    rs.stand_on_floor(joints)
    lay_rest_tail(joints)


def pose_idle(joints):
    """How she stands: weight forward on the balls of her feet as if the start's about to go, one foot well ahead, the
    left hand resting on the satchel at her hip, the right loose and ready, eyes level on what's next."""
    body = turn(-10, -16)
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rs"], body, (0.16, 0.3, -1.0), stage=False)
    rs.aim(joints["ls"], body, (-0.1, -0.42, -1.0), stage=False)
    joints["neck"].rotation_quaternion = body.inverted() @ turn(-4, -2)
    rs.aim(joints["rh"], body, (0.08, 0.42, -1.0), twist=-8)
    rs.aim(joints["lh"], body, (-0.1, -0.4, -1.0), twist=6)
    rs.stand_on_floor(joints)
    lay_rest_tail(joints, -10)


def step_axes():
    """Scarf Step's line: u, the way she travelled (STEP_ANGLE right of straight ahead); r, her right once she's turned
    back to face the Shade."""
    a = math.radians(STEP_ANGLE)
    u = Vector((math.sin(a), math.cos(a), 0))
    return u, (-u).cross(Vector((0, 0, 1)))


def pose_step(joints):
    """Scarf Step's key pose, leaving: she has gone through the Shade and lands past it, sliding on along her line but
    already turned back to face it, low. The back leg brakes, long; the blade arm trails low behind her on the cut's
    follow-through; the other hand reaches toward the Shade; and the scarf runs from her neck in one straight line back
    through it, toward where she started."""
    u, r = step_axes()
    down = Vector((0, 0, -1))
    heading = 180.0 - STEP_ANGLE
    body = turn(heading, -30)
    root = joints["root"]
    root.rotation_quaternion = body
    root.location = (TARGET + u * PAST).to_tuple()[:2] + (3.0,)
    rs.aim(joints["rh"], body, u * math.sin(math.radians(62)) + r * 0.12 + down * math.cos(math.radians(62)), twist=-10)
    rs.aim(joints["lh"], body, -u * math.sin(math.radians(52)) - r * 0.1 + down * math.cos(math.radians(52)))
    rs.aim(joints["rs"], body, u * 0.75 + r * 0.5 + down * 0.36, twist=-20)
    rs.aim(joints["ls"], body, -u * 0.72 - r * 0.32 + down * 0.5)
    joints["neck"].rotation_quaternion = body.inverted() @ turn(heading, 12)
    rs.stand_on_floor(joints)
    knot = knot_at(joints)
    line = (TARGET + Vector((0, 0, 3.0)) - knot).normalized()
    side = line.cross(Vector((0, 0, 1))).normalized()
    points = []
    for i in range(40):
        f = i / 39
        flick = max(0.0, (f - 0.72) / 0.28)  # taut to the Shade and past it, the last stretch still snapping straight
        points.append(knot + line * TAIL * f * (1 - 0.03 * flick) + Vector((0, 0, 0.32 * flick * math.sin(math.pi * 1.5 * flick)))
                      + side * 0.18 * flick ** 2)
    tail(points, joints["m"], twist=90.0, turns=0.25)
    ghost(joints["m"], TARGET)
    bpy.context.view_layer.update()
    joints["line"] = (knot, line)


POSES = {"square": pose_square, "idle": pose_idle, "step": pose_step}


# --- pictures -------------------------------------------------------------------------------------------------

PX = 100  # pixels a stud, in every render: the 64 px block shrinks them all by the same factor
F64 = 64 / (5 * PX)


def mixed(shaded, flat):
    out = shaded.copy()
    out[..., :3] = shaded[..., :3] * 0.5 + flat[..., :3] * 0.5
    return out


def over(top, bottom):
    """Alpha-over of two pictures of one size."""
    ta, ba = top[..., 3:], bottom[..., 3:]
    a = ta + ba * (1 - ta)
    out = np.empty_like(top)
    out[..., :3] = np.where(a > 1e-6, (top[..., :3] * ta + bottom[..., :3] * ba * (1 - ta)) / np.maximum(a, 1e-6), 0)
    out[..., 3:] = a
    return out


def faded(shot, alpha):
    out = shot.copy()
    out[..., 3] *= alpha
    return out


def render(scene, view, azimuth, elevation, centre, span, px=PX):
    size = math.ceil(span * px)
    passes = []
    for flat in (False, True):
        rs.workbench(scene, size, size, flat=flat)
        path = OUT / f"_{view}_{int(flat)}.png"
        passes.append(rs.shoot(scene, path, azimuth, elevation, centre, span))
        path.unlink()
    return mixed(*passes)


def takes(wanted, ghosted=()):
    """{(pose, view): picture}, at PX a stud, cut to what's drawn, and what was measured. `wanted`: pose -> {view:
    (azimuth, elevation)}, or (azimuth, elevation, centre, span, pixels a stud) for a close view. A view in `ghosted`
    has the grey Shade drawn faint behind her. Every other view of a pose is framed on the same box, so each holds the
    whole figure."""
    out = {}
    for pose, views in wanted.items():
        scene = bl.reset_scene()
        joints = build(scene, drawn=pose == "step")
        POSES[pose](joints)
        meshes = [o for o in scene.objects if o.type == "MESH"]
        ghosts = [o for o in meshes if o.get("ghost")]
        body = [o for o in meshes if not o.get("ghost")]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        low, high = Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)])
        centre, span = (low + high) / 2, (high - low).length * 1.02
        for view, (azimuth, elevation, *close) in views.items():
            for o in ghosts:
                o.hide_render = True
            if close:
                out[pose, view] = rs.trim(render(scene, view, azimuth, elevation, *close))
                continue
            shot = render(scene, view, azimuth, elevation, centre, span)
            if (pose, view) in ghosted:
                for o in ghosts:
                    o.hide_render = False
                for o in body:
                    o.hide_render = True
                shade = faded(render(scene, view, azimuth, elevation, centre, span), 0.5)
                for o in body:
                    o.hide_render = False
                out[pose, view, "ghost"] = rs.trim(over(shot, shade))
                out[pose, view, "ghost dark"] = rs.trim(over(rs.black(shot), shade))
            out[pose, view] = rs.trim(shot)
        bp = [o.matrix_world @ v.co for o in body for v in o.data.vertices]
        out[pose, "size"] = tuple(round(max(q[i] for q in bp) - min(q[i] for q in bp), 2) for i in range(3))
        out[pose, "top"] = round(max(q.z for q in bp), 2)
        if pose == "step":
            out["line"] = joints["line"]
        out["tris", pose] = sum(len(f.vertices) - 2 for o in body for f in o.data.polygons)
    return out


def silhouette(shot):
    return rs.shrink(rs.trim(shot), F64)[..., 3]


def overlap(a, b):
    """How much two outlines at 64 px cover the same pixels, stood on the same floor with their centres of mass
    level: 1 is the same outline."""
    def placed(s, h, w):
        canvas = np.zeros((h, w), dtype=np.float32)
        cx = int(round((s.sum(axis=0) * np.arange(s.shape[1])).sum() / s.sum()))
        x0 = w // 2 - cx
        canvas[h - s.shape[0]:, max(x0, 0):x0 + s.shape[1]] = s[:, max(-x0, 0):s.shape[1] - max(x0 + s.shape[1] - w, 0)]
        return canvas
    h, w = max(a.shape[0], b.shape[0]), 2 * max(a.shape[1], b.shape[1]) + 4
    pa, pb = placed(a, h, w), placed(b, h, w)
    return float(np.minimum(pa, pb).sum() / np.maximum(pa, pb).sum())


def fit_row(page, text, items, x0, x1, floor, height, soft, gap=24):
    """Stands pictures (at PX a stud) on one floor, all at the one scale that fits the row's width and height."""
    cut = [(rs.trim(p), label) for p, label in items]
    width = sum(p.shape[1] for p, _ in cut)
    k = min(height / max(p.shape[0] for p, _ in cut), (x1 - x0 - gap * (len(cut) - 1)) / width, 0.62)
    x = x0
    for p, label in cut:
        shot = rs.shrink(p, k)
        rs.stand(page, shot, x, floor, shot.shape[1])
        text.append((x + 4, floor + 14, 18, label, soft))
        x += shot.shape[1] + gap
    return k


GAME, FRONT = rs.GAME, ps.FRONT
PAPER, NIGHT, DAY, DUSK = rs.PAPER, rs.NIGHT, rs.DAY, ps.DUSK


def sheet(small):
    u, r = step_axes()
    heading = 180.0 - STEP_ANGLE  # she faces back along the line; azimuth 0 is behind a body facing +Y
    met = (heading + 180.0 - 50.0) % 360  # from the Shade's side, her front and her right, the blade arm
    side = (heading + 180.0 - 90.0) % 360  # side on to the line, from her right
    close = (Vector((0, 0, 3.75)), 3.4, 2 * PX)  # the head and the chest, at twice the scale
    wanted = {"square": {"front": (180, 0), "back": (0, 0), "close front": (156, 6, *close), "close back": (24, 14, *close)},
              "idle": {"front": FRONT, "game": GAME, "flat": (180, 0)},
              "step": {"met": (met, 6), "side": (side, 3), "game": GAME}}
    s = takes(wanted, ghosted={("step", "side"), ("step", "game")})
    ps.OUT = OUT
    p = ps.takes({"idle": {"game": (*GAME, ps.MID), "front": (*ps.FRONT, ps.MID)}})

    # the numbers first
    knot, line = s["line"]
    a, e = math.radians(GAME[0]), math.radians(GAME[1])
    view = -Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e)))
    on_screen = TAIL * math.sqrt(max(0.0, 1 - line.dot(view) ** 2))
    print(f"square {s['square', 'size']} studs, top {s['square', 'top']}; idle {s['idle', 'size']}; step {s['step', 'size']}, "
          f"top {s['step', 'top']}; knot at {tuple(round(c, 2) for c in knot)}")
    print(f"Scarf Step's line: {TAIL} studs, {math.degrees(math.acos(abs(line.dot(view)))):.0f} deg off the game camera's axis, "
          f"{on_screen:.1f} studs long on the screen")
    print(f"tris: square {s['tris', 'square']}, step {s['tris', 'step']}")
    for view_name in ("game", "front"):
        kirra, pip = silhouette(s["idle", view_name]), silhouette(p["idle", view_name])
        print(f"at 64 px, idle {view_name}: Kirra {kirra.shape[1]}x{kirra.shape[0]} px, cover {kirra.mean():.2f}; "
              f"Pip {pip.shape[1]}x{pip.shape[0]} px, cover {pip.mean():.2f}; overlap {overlap(kirra, pip):.2f}")

    W, H = 1920, 1920
    page = rs.canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 64, "KIRRA", ink),
            (250, 36, 24, "Common / Agility / Assassin. A courier, one of the three starters.", ink),
            (250, 70, 20, "One idea: a small body with a long streak. Her scarf trails twice her length, and it's the line she draws.", soft)]

    # row A: who she is
    fit_row(page, text, [(rs.black(s["idle", "flat"]), "outline"), (s["square", "front"], "front, on R6"),
                         (s["square", "back"], "back"), (s["idle", "front"], "how she stands"),
                         (s["idle", "game"], "the player's camera")], 30, 1890, 410, 300, soft, gap=40)
    rs.fill(page, 30, 412, 1860, 2, rs.rgb("#BDB8AE"))

    # row A2: up close, and what each piece is
    fit_row(page, text, [(s["square", "close front"], "up close, front"), (s["square", "close back"], "and back")],
            30, 980, 860, 400, soft, gap=40)
    notes = ["The scarf: wound once to her chin, knotted at her left, a short end down her chest.",
             f"The tail is {TAIL:.0f} studs, its last half-stud bone so the line's end reads. On the model it's",
             "a chain of joints the clips carry; at rest it floats in an S, never hangs.",
             "Goggles pushed up on her brow, amber lenses: the courier, not the ninja.",
             "Hair cut short and choppy, swept back as if she's always running into wind.",
             "Two short blades, a forearm long, in leather sheaths crossed on her back;",
             "the saffron grips stand over her shoulders, where the player's camera looks.",
             "The satchel at her left hip, its strap across her chest; a parcel tied with cord in its mouth.",
             "Sleeves pushed up, forearms and shins bound in bone: four light bands that carry",
             "her limbs' motion at a distance, on a dark body the scarf stands out from."]
    text += [(1010, 470 + i * 30, 17, line, soft) for i, line in enumerate(notes)]
    rs.fill(page, 30, 862, 1860, 2, rs.rgb("#BDB8AE"))

    # row B: Scarf Step's key pose
    text += [(40, 910, 30, "SCARF STEP, leaving", ink),
             (40, 952, 18, "Through the Shade and out the far side, already turned to face it: the back leg brakes long, the blade trails "
                           "low on the cut, and the scarf runs back through the Shade in one straight line.", soft),
             (40, 976, 18, f"She crosses {STEP_ANGLE:.0f} degrees right of the line from the player's camera, so the line keeps its "
                           f"length on the screen: {on_screen:.1f} of its {TAIL:.0f} studs.", soft)]
    fit_row(page, text, [(s["step", "met"], "from the Shade's side"),
                         (s["step", "side", "ghost dark"], "side on, the Shade in grey"),
                         (s["step", "game", "ghost"], "the player's camera")], 30, 1890, 1370, 360, soft, gap=40)
    rs.fill(page, 30, 1372, 1860, 2, rs.rgb("#BDB8AE"))

    # row C: the chips, the block at 64 px beside Pip, the values
    x, y = 40, 1420
    for i, (name, role) in enumerate(CHIPS):
        yy = y + i * 104
        rs.fill(page, x, yy, 88, 88, rs.rgb(PALETTE[name]))
        text += [(x + 100, yy + 8, 22, name, ink), (x + 100, yy + 38, 16, PALETTE[name], soft), (x + 100, yy + 60, 16, role, soft)]
    for i, name in enumerate(NEUTRALS):
        rs.fill(page, x + 300 + (i % 2) * 120, y + (i // 2) * 84, 52, 52, rs.rgb(PALETTE[name]))
        text.append((x + 300 + (i % 2) * 120, y + (i // 2) * 84 + 58, 12, name, soft))
    text += [(x + 300, y + 262, 16, "Reads, in order:", ink), (x + 300, y + 286, 16, "1 the scarf's streak", soft),
             (x + 300, y + 308, 16, "2 low, narrow, leaning on", soft), (x + 300, y + 330, 16, "3 the grips over her shoulders", soft)]

    x0, y0 = 600, 1410
    keys = [(s, ("idle", "game")), (s, ("idle", "front")), (s, ("step", "game")), (s, ("step", "met")), (p, ("idle", "game")), (p, ("idle", "front"))]
    small_shots = [rs.shrink(rs.trim(src[key]), F64) for src, key in keys]
    widths = [q.shape[1] + 10 for q in small_shots]
    widths[3] += 26  # a gap before Pip
    text += [(x0, y0, 19, "at 64 px over dark, Lantern Row's dusk, bright, and in black", soft),
             (x0 + 8, y0 + 26, 15, "Kirra", ink), (x0 + 8 + sum(widths[:4]), y0 + 26, 15, "Pip, beside her", ink)]
    for row, (ground, black) in enumerate(((NIGHT, False), (DUSK, False), (DAY, False), (PAPER, True))):
        yy = y0 + 48 + row * 96
        rs.fill(page, x0, yy, sum(widths) + 8, 92, ground)
        cx = x0 + 8
        for q, w in zip(small_shots, widths):
            rs.stand(page, rs.black(q) if black else q, cx, yy + 88, q.shape[1])
            cx += w
    vx = x0 + sum(widths) + 50
    text.append((vx, y0, 19, "values", soft))
    for c, key in enumerate((("idle", "front"), ("idle", "game"), ("step", "met"))):
        shot = rs.grey(rs.shrink(rs.trim(s[key]), 0.2))
        rs.stand(page, shot, vx + c * 140, y0 + 300, shot.shape[1])

    sizes = s["square", "size"]
    text.append((40, H - 40, 15, f"Blockout on R6 at the player's height: 5 studs to the crown, {s['square', 'top']} to the hair's top, "
                 f"{sizes[0]} across with the scarf at rest, its tail {TAIL:.0f} studs. On the model the tail is a chain of joints. "
                 f"Views are orthographic.", soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "kirra_sheet.png")
    if small:
        rs.save(rs.shrink(page, 0.5), OUT / "kirra_sheet_small.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    sheet("small" in sys.argv[sys.argv.index("--") + 2:])
