"""The Lamplighter's direction sheet (AR7, delivery 1): Lantern Row's keeper, three cheap directions on the Shade's
body, with the pick.

blender.exe -b --factory-startup --python tools/blender/lamplighter_sheet.py -- <out_dir> [small]

A Shade in full festival dress (docs/roster.md, "Enemies"): the Shade's empty coat and its lit hollows as AR2 built
them (shade_sheet.build), its own keeper's mask in place of the four, a festival coat over the coat, a hat or a hood,
and a long pole with a hook and a great lantern: the gate's lantern (lantern_row_kit.keepers_gate), its paper the
street's cyan round a warm white heart. Its lit edges are Intelligence's colour. Built in the Shade's units, then
scaled by SCALE. Workbench only, so no GPU turn; Rook beside it in the ring is his baked model in Eevee. The glow is
drawn on the picture, as the Shade's sheet does, from a pass where each light has a key colour of its own.
"""
import math
import sys
import textwrap
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
ROOK = REPO / "build" / "scratch" / "modulo" / "rook" / "model" / "rook_model.blend"
SCALE = 1.5        # against an ordinary Shade: past the elite's 1.35 (Definitions/Enemies), the ground's master
TYPE = "Intelligence"
SW = {name: kit.SWATCHES[name][0] for name in ("indigo", "red", "cream", "rope", "dark", "brass", "post", "mustard", "cyan", "warm")}
DRESS = {"Coat": SW["indigo"], "Trim": SW["red"], "Band": SW["cream"], "Straw": SW["rope"], "Lacquer": SW["dark"],
         "Brass": SW["brass"], "Pole": SW["post"], "Sash": SW["mustard"]}
# The lit pieces: the colour each is drawn in, and the key it wears in the pass that finds it (no dress colour is near)
LIGHTS = {"Glow": (ss.TYPES[TYPE], (0.0, 1.0, 0.0)), "Cyan": (SW["cyan"], (1.0, 0.0, 1.0)), "Warm": (SW["warm"], (0.0, 0.0, 1.0))}
POLE_TOP = 7.7     # the pole's top over the floor, in the Shade's units (11.6 studs at SCALE): the lantern hangs at the
                   # mask's height, since held over the hat it leaves the ring's frame at TR2's zoom
LAMP = (1.0, 2.3)  # the great lantern's radius and height, in the Shade's units: about 60% of the gate's
HOOP = 0.16

DIRECTIONS = {
    "A": dict(name="The Bearer", what="a sedge hat over a lantern-faced mask; the pole planted upright, the lantern hung from its crook",
              wrong=("From above, the hat's brim hides the mask's brow; the ring's", "camera sees it from level, so both eyes show. A staff and a",
                     "cone hat could read as a generic mage: the lantern and the", "festival coat have to carry it.")),
    "B": dict(name="The Warden", what="a peaked hood round a crescent mask; the pole over the shoulder, the lantern behind the head",
              wrong=("A hood and a long pole over the shoulder is a scythe-bearer's", "outline: it reads as death, not as the festival's master.",
                     "The lantern hides behind the head from the player's camera.", "")),
    "C": dict(name="The Crier", what="a tall lacquer cap over a lattice mask; the pole held out, the lantern hung in front",
              wrong=("The lantern hangs between the keeper and the player, so from", "the player's camera it covers the mask and the coat. Held out",
                     "level, the pole reads as a fishing rod, not as a weapon it", "can bring down.")),
}
PICK = "A"


# --- materials ------------------------------------------------------------------------------------------------

def materials():
    made = {}
    for name, code in {**ss.PALETTE, **DRESS, **{k: v[0] for k, v in LIGHTS.items()}}.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def keyed(m, on):
    """The lit pieces in their key colours (on) or their own."""
    for name, (code, key) in LIGHTS.items():
        m[name].diffuse_color = (*key, 1.0) if on else rs.srgb(code)


# --- shapes ---------------------------------------------------------------------------------------------------

def lathe(name, profile, centre, sides, material, spin=0.0):
    """A solid turned about Z: `profile` (radius, height) from the top down, `sides` flat faces round."""
    bm = bmesh.new()
    cx, cy, cz = centre
    rings = [[bm.verts.new((cx + r * math.cos(spin + 2 * math.pi * k / sides), cy + r * math.sin(spin + 2 * math.pi * k / sides), cz + dz))
              for k in range(sides)] for r, dz in profile]
    for a, b in zip(rings, rings[1:]):
        for k in range(sides):
            bm.faces.new((a[k], a[(k + 1) % sides], b[(k + 1) % sides], b[k]))
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def strip(name, x0, x1, profile, material, lift=0.006, thick=0.04):
    """A band laid down the coat's front, from x0 to x1: `profile` is (z, the front's y) from the hem up."""
    bm = bmesh.new()
    quads = [[bm.verts.new((x, y + lift + t, z)) for x, t in ((x0, 0), (x1, 0), (x1, thick), (x0, thick))] for z, y in profile]
    for a, b in zip(quads, quads[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(list(reversed(quads[0])))
    bm.faces.new(quads[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def arc3(a, b, c, n):
    """Points from a to c on the circle through a, b and c, the way that passes b."""
    (ax, ay), (bx, by), (cx, cy) = a, b, c
    d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
    uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
    r = math.hypot(ax - ux, ay - uy)
    ta, tb, tc = (math.atan2(p[1] - uy, p[0] - ux) for p in (a, b, c))
    turn = 2 * math.pi
    span = (tc - ta) % turn if (tb - ta) % turn < (tc - ta) % turn else -((ta - tc) % turn)
    return [(ux + r * math.cos(ta + span * i / n), uy + r * math.sin(ta + span * i / n)) for i in range(n + 1)]


# --- the keeper's masks: each its own outline, none of the four's ------------------------------------------------

def mask_lantern(m):
    """A: the face is a paper lantern: a barrel with a dark hoop at head and foot, two ribs inked across, the eyes
    closed and calm, a small round mouth, all cut through to the light."""
    y, c = ss.MASK_Y, 4.95
    face = []
    for i in range(36):
        t = 2 * math.pi * i / 36
        x = 0.8 * math.copysign(abs(math.cos(t)) ** (2 / 2.6), math.cos(t))
        z = 1.08 * math.copysign(abs(math.sin(t)) ** (2 / 2.6), math.sin(t))
        face.append((x, c + max(-0.9, min(0.92, z))))
    eyes = [ss.cut("Eye", ss.arc(e * 0.36, c + 0.16, 0.24, 200, 340, 8) + ss.arc(e * 0.36, c + 0.25, 0.22, 336, 204, 8), m) for e in (-1, 1)]
    hoops = [rs.slab("Hoop", (0, y + 0.08, c + k * 0.97), (1.16, 0.2, 0.17), m["Lacquer"]) for k in (1, -1)]
    ribs = [rs.slab("InkRib", (0, y + 0.148, c + dz), (w, 0.016, 0.045), m["Ink"]) for dz, w in ((0.62, 1.12), (-0.62, 1.12))]
    return [ss.raised("Mask", face, y, 0.14, m["Paper"], inset=0.86), ss.rim(face, m, 1.06), *eyes,
            ss.cut("Mouth", ss.disc(0, c - 0.36, 0.085, 10), m), *hoops, *ribs, *ss.ties(m, c, 0.86)]


def mask_crescent(m):
    """B: a crescent, its horns to the right: two eye slits on its broad side."""
    y, c = ss.MASK_Y, 4.95
    outer = ss.arc(0, c, 1.0, 55, 305, 22)
    face = outer + arc3(outer[-1], (0.2, c), outer[0], 12)[1:-1]
    eyes = [ss.cut("Eye", [(x - 0.17, z - 0.03), (x + 0.17, z + 0.03), (x + 0.17, z + 0.1), (x - 0.17, z + 0.04)], m)
            for x, z in ((-0.62, c + 0.14), (-0.2, c + 0.1))]
    return [ss.plate("Mask", face, y, 0.14, m["Paper"]), ss.rim(face, m, 1.05), *eyes,
            rs.slab("InkLine", (-0.4, y + 0.148, c - 0.42), (0.5, 0.016, 0.05), m["Ink"], rot=(0, 12, 0)), *ss.ties(m, c, 0.95)]


def mask_lattice(m):
    """C: a hexagon, taller than wide, its eyes two lattice windows and its mouth a slit barred in ink."""
    y, c = ss.MASK_Y, 4.95
    face = [(-0.55, c + 1.05), (0.55, c + 1.05), (0.95, c), (0.55, c - 1.05), (-0.55, c - 1.05), (-0.95, c)]
    panes = [ss.cut("Pane", [(px - 0.065, pz - 0.065), (px + 0.065, pz - 0.065), (px + 0.065, pz + 0.065), (px - 0.065, pz + 0.065)], m)
             for e in (-1, 1) for px in (e * 0.38 - 0.08, e * 0.38 + 0.08) for pz in (c + 0.17, c + 0.33)]
    frames = [rs.slab("InkFrame", (e * 0.38, y + 0.146, c + 0.25), (0.42, 0.012, 0.42), m["Ink"]) for e in (-1, 1)]
    bars = [rs.slab("InkBar", (x, y + 0.158, c - 0.45), (0.04, 0.012, 0.13), m["Ink"]) for x in (-0.12, 0.0, 0.12)]
    return [ss.raised("Mask", face, y, 0.14, m["Paper"], inset=0.88), ss.rim(face, m, 1.06), *frames, *panes,
            ss.cut("Mouth", [(-0.26, c - 0.49), (0.26, c - 0.49), (0.26, c - 0.41), (-0.26, c - 0.41)], m), *bars, *ss.ties(m, c, 0.9)]


MASKS = {"A": mask_lantern, "B": mask_crescent, "C": mask_lattice}


# --- the dress ------------------------------------------------------------------------------------------------

def coat(m, direction):
    """The festival coat over the Shade's: a long bell to the shins, open down the front so the light shows in a
    seam between two cream bands, its hem lit and dark inside. A and C belt it; C's is cut short in front with tails."""
    if direction == "C":
        hem = lambda t: 0.98 + 0.42 * math.sin(t)  # noqa: E731  short in front (t = 90 degrees), long behind
        start = (1.6, 1.04)
    else:
        hem, start = 0.62, (0.82, 1.19)
    rings = [(hem, 0, 0, 3.0, 2.5), (1.7, 0, 0, 2.62, 1.86), (2.9, 0, 0, 2.3, 1.34), (4.02, 0, 0, 2.2, 1.16)]
    shift = (lambda d: (lambda t: hem(t) + d)) if callable(hem) else (lambda d: hem + d)
    made = [rs.loft("LongCoat", rings, m["Coat"], n=ss.B),
            rs.loft("CoatHem", [(shift(-0.02), 0, 0, 3.06, 2.56), (shift(0.2), 0, 0, 3.0, 2.5)], m["Glow"], n=ss.B),
            rs.loft("CoatHollow", [(shift(-0.035), 0, 0, 2.9, 2.4), (shift(-0.01), 0, 0, 2.9, 2.4)], m["Ink"], n=ss.B)]
    # the coat's front from just over the lit hem up: (z, half the coat's depth there)
    profile = [start, (1.7, 0.93), (2.9, 0.67), (4.02, 0.58)]
    made += [strip("Band", s * 0.09, s * 0.4, profile, m["Band"]) for s in (-1, 1)]
    made.append(strip("Seam", -0.09, 0.09, profile, m["Glow"], lift=-0.004))
    if direction in ("A", "C"):
        wide = "Sash" if direction == "C" else "Trim"
        top, bottom = (2.95, 2.3) if direction == "C" else (2.8, 2.45)
        made.append(rs.loft("Sash", [(bottom, 0, 0, 2.46, 1.56), (top, 0, 0, 2.38, 1.44)], m[wide], n=ss.B))
        made += [rs.slab("Knot", (-0.55, 0.82, (top + bottom) / 2), (0.42, 0.18, 0.36), m[wide]),
                 rs.slab("Tail", (-0.44, 0.86, bottom - 0.42), (0.16, 0.05, 0.9), m[wide], rot=(0, 6, 0)),
                 rs.slab("Tail", (-0.68, 0.84, bottom - 0.34), (0.16, 0.05, 0.74), m[wide], rot=(0, -9, 0))]
    if direction in ("A", "C"):  # the keeper's crest on its back: a cream disc with a lantern inked on it
        made += [ss.plate("Crest", ss.disc(0, 3.36, 0.55, 28), -0.7, 0.05, m["Band"]),
                 ss.plate("CrestLamp", [(x * 0.22, 3.36 + z * 0.3) for x, z in ss.disc(0, 0, 1.0, 20)], -0.715, 0.016, m["Ink"]),
                 ss.plate("CrestHoop", [(-0.14, 3.71), (0.14, 3.71), (0.14, 3.64), (-0.14, 3.64)], -0.715, 0.016, m["Ink"]),
                 ss.plate("CrestHoop", [(-0.14, 3.08), (0.14, 3.08), (0.14, 3.01), (-0.14, 3.01)], -0.715, 0.016, m["Ink"])]
    return made


def oversleeve(m, e):
    """A wide festival sleeve over the Shade's own, cut square and trimmed: the Shade's lit cuff shows under it."""
    return [rs.loft("Oversleeve", [(2.3, e * 1.8, 0, 1.52, 1.76), (3.2, e * 1.8, 0, 1.4, 1.5), (4.02, e * 1.8, 0, 1.22, 1.16)], m["Coat"], n=ss.B),
            rs.loft("SleeveTrim", [(2.27, e * 1.8, 0, 1.58, 1.82), (2.42, e * 1.8, 0, 1.56, 1.8)], m["Trim"], n=ss.B),
            rs.loft("SleeveHollow", [(2.25, e * 1.8, 0, 1.4, 1.62), (2.28, e * 1.8, 0, 1.4, 1.62)], m["Ink"], n=ss.B)]


def headwear(m, direction):
    if direction == "A":  # a wide sedge hat, its crown a low cone, two inked rings of weave, a red cord tied behind
        hat = bl.place(bl.cylinder("Hat", 1.75, 0.95, 40, m["Straw"], radius_top=0.07), location=(0, 0.04, 6.08 + 0.475))
        under = bl.place(bl.cylinder("HatUnder", 1.7, 0.03, 40, m["Ink"]), location=(0, 0.04, 6.065))
        weave = [bl.place(bl.torus("InkWeave", r + 0.012, 0.018, 48, 6, m["Ink"]), location=(0, 0.04, 6.08 + 0.95 * (1.75 - r) / 1.68))
                 for r in (1.25, 0.72)]
        cords = [bl.tube_along("Cord", [Vector((e * 1.0, 0.0, 6.1)), Vector((e * 0.62, -0.42, 4.95)), Vector((e * 0.12, -0.66, 4.4))],
                               [0.035] * 3, 6, m["Trim"]) for e in (-1, 1)]
        return [hat, under, *weave, *cords]
    if direction == "B":  # a peaked hood that falls to a capelet, the face's opening lit, dark round the mask
        hood = rs.loft("Hood", [(4.05, 0, -0.3, 2.3, 1.9), (4.9, 0, -0.32, 2.15, 1.75), (5.9, 0, -0.45, 1.7, 1.35),
                                (6.7, 0, -0.7, 0.9, 0.72), (7.5, 0, -1.1, 0.1, 0.1)], m["Coat"], n=2.6)
        hollow = ss.plate("HoodHollow", [(x * 1.12, 4.95 + z * 1.28) for x, z in ss.disc(0, 0, 1.0, 28)], 0.66, 0.03, m["Ink"])
        ring = []
        bm = bmesh.new()
        outer = [(1.24 * math.cos(2 * math.pi * k / 32), 4.95 + 1.4 * math.sin(2 * math.pi * k / 32)) for k in range(32)]
        inner = [(1.1 * math.cos(2 * math.pi * k / 32), 4.95 + 1.26 * math.sin(2 * math.pi * k / 32)) for k in range(32)]
        vo = [bm.verts.new((x, 0.7, z)) for x, z in outer]
        vi = [bm.verts.new((x, 0.7, z)) for x, z in inner]
        for k in range(32):
            bm.faces.new((vo[k], vo[(k + 1) % 32], vi[(k + 1) % 32], vi[k]))
        ring.append(bl.object_from_bmesh("HoodRim", bm, m["Glow"]))
        return [hood, hollow, *ring]
    # C: a tall cap of lacquered paper, folded over at its top, a cream band and a red cord at its foot
    cap = rs.loft("Cap", [(5.86, 0, 0.0, 1.16, 1.32), (7.1, 0, -0.08, 0.94, 1.1), (7.95, 0, 0.1, 0.72, 0.9)], m["Lacquer"], n=5.0)
    fold = rs.hexa("CapFold", [(-0.36, -0.3, 7.9), (0.36, -0.3, 7.9), (0.36, 0.56, 7.9), (-0.36, 0.56, 7.9),
                               (-0.36, -0.3, 8.0), (0.36, -0.3, 8.0), (0.36, 0.86, 7.55), (-0.36, 0.86, 7.55)], m["Lacquer"])
    band = rs.loft("CapBand", [(5.84, 0, 0.0, 1.2, 1.36), (6.12, 0, 0.0, 1.17, 1.33)], m["Band"], n=5.0)
    cord = bl.tube_along("Cord", [Vector((0.6, 0.0, 6.0)), Vector((0.75, 0.3, 5.5)), Vector((0.7, 0.5, 5.05))], [0.035] * 3, 6, m["Trim"])
    return [cap, fold, band, cord]


def great_lantern(m, centre, r=LAMP[0], h=LAMP[1], sides=8):
    """The gate's great lantern at the keeper's size: its paper cyan round a warm white band where the flame sits,
    dark hoops at head and foot, the mustard tuft under it."""
    x, y, z = centre
    spin = math.pi / sides
    cyan_top = [(r * 0.62, h / 2), (r, h * 0.26), (r, h * 0.1)]
    cyan_low = [(r, -h * 0.1), (r, -h * 0.26), (r * 0.62, -h / 2)]
    parts = [lathe("LampTop", cyan_top, centre, sides, m["Cyan"], spin), lathe("LampHeart", [(r, h * 0.1), (r, -h * 0.1)], centre, sides, m["Warm"], spin),
             lathe("LampFoot", cyan_low, centre, sides, m["Cyan"], spin)]
    parts += [lathe("LampHoop", [(r * 0.66, HOOP / 2), (r * 0.66, -HOOP / 2)], (x, y, z + k * (h / 2 + HOOP / 2)), sides, m["Lacquer"], spin) for k in (1, -1)]
    parts.append(rs.slab("Tuft", (x, y, z - h / 2 - HOOP - 0.3), (0.16, 0.16, 0.5), m["Sash"]))
    return parts


HOOKS = {"crook": ((0, 0), (0.35, 0.12), (0.5, 0.55), (0.3, 0.92), (-0.1, 1.02)),
         "tip": ((0, 0), (0.35, 0.28), (0.8, 0.42), (1.08, 0.2), (1.12, -0.12))}


def pole(m, foot, top, w, shape, lamp=None):
    """The pole from its foot to its top, a brass hook at the top opening toward `w`, and the great lantern on it:
    hung plumb from the hook's tip, or at `lamp` on a taut cord."""
    foot, top, w = Vector(foot), Vector(top), Vector(w)
    u = (top - foot).normalized()
    w = (w - u * w.dot(u)).normalized()
    made = [bl.tube_along("Pole", [foot, top], [0.1, 0.09], 10, m["Pole"]),
            bl.tube_along("Ferrule", [foot, foot + u * 0.3], [0.12, 0.12], 10, m["Brass"])]
    pts = bl.smooth_path([top + a * u + b * w for a, b in HOOKS[shape]], 16)
    made.append(bl.tube_along("Hook", pts, [0.075] * len(pts), 10, m["Brass"]))
    tip = pts[-1]
    if lamp is None:
        lamp = tip - Vector((0, 0, 0.3 + HOOP + LAMP[1] / 2))
    lamp = Vector(lamp)
    made.append(bl.tube_along("LampCord", [tip, lamp + Vector((0, 0, LAMP[1] / 2 + HOOP))], [0.03, 0.03], 6, m["Lacquer"]))
    return made + great_lantern(m, lamp)


# --- the figure -----------------------------------------------------------------------------------------------

def on(joints, part, *objs):
    for o in objs:
        o.parent = joints[part]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(ss.PIVOTS[part]))


def cuff(joints, part):
    """Where a sleeve's cuff is, posed: a pole held in it passes through here."""
    e = 1 if part == "rs" else -1
    bpy.context.view_layer.update()
    return joints[part].matrix_world @ (Vector((e * 1.8, 0, 1.95)) - Vector(ss.PIVOTS[part]))


def pose(joints, direction, beat):
    """Upright, as the ground's master stands: no Shade's forward hang. Each direction holds its pole its own way;
    `windup` is A's signature drawn back: the pole planted ahead and leaned back, both sleeves on it, the mask up."""
    lean = {"windup": 6}.get(beat, 0)
    body = Quaternion((1, 0, 0), math.radians(lean)) @ Quaternion((0, 0, 1), math.radians(-6))
    joints["root"].rotation_quaternion = body
    arms = {"A": ((0.35, 0.2, -1.0), (-0.08, 0.05, -1.0)), "B": ((0.08, 0.05, -1.0), (0.25, 0.75, -0.6)),
            "C": ((0.1, 1.0, -0.45), (-0.08, 0.05, -1.0))}[direction]
    if beat == "windup":
        arms = ((0.25, 0.9, 0.15), (0.75, 0.85, -0.35))
    rs.aim(joints["rs"], body, arms[0])
    rs.aim(joints["ls"], body, arms[1])
    for part in ("rh", "lh"):
        rs.aim(joints[part], body, (0.0, 0.0, -1.0))
    nod = 12 if beat == "windup" else -4
    joints["neck"].rotation_quaternion = body.inverted() @ Quaternion((1, 0, 0), math.radians(nod))
    rs.stand_on_floor(joints)


def build(scene, direction, m, beat="idle"):
    """The keeper, posed, in a group scaled to its size. Returns the group's empty and the joints."""
    four = ss.mask
    ss.mask = lambda kind, mm: MASKS[direction](mm)  # the keeper's own mask in place of the four, for this build only
    try:
        joints = ss.build(scene, "Keeper", m)
    finally:
        ss.mask = four
    on(joints, "root", *coat(m, direction))
    for part, e in (("rs", 1), ("ls", -1)):
        on(joints, part, *oversleeve(m, e))
    on(joints, "neck", *headwear(m, direction))
    pose(joints, direction, beat)
    if beat == "windup":
        foot = Vector((1.3, 2.4, 0.0))
        lean = Vector((0.05, -0.45, 1.0)).normalized()
        top = foot + lean * POLE_TOP
        held = pole(m, foot, top, (0, 1, 0), "crook", lamp=top + Vector((0.1, -1.0, 0.6)))
    elif direction == "A":
        c = cuff(joints, "rs")
        # the crook opens outward and a little back: the lantern hangs beside the face from the front and from the
        # ring's camera, never between them
        held = pole(m, (c.x, c.y, 0.0), (c.x, c.y, POLE_TOP), (1.0, -0.25, 0), "crook")
    elif direction == "B":
        c = cuff(joints, "ls")
        d = Vector((-0.55, -2.6, 6.0)).normalized()
        held = pole(m, c - d * 1.0, c + d * 6.4, (0, -1, 0), "crook")
    else:
        c = cuff(joints, "rs")
        d = Vector((0.08, 1.0, 0.42)).normalized()
        held = pole(m, c - d * 1.6, c + d * 5.2, (0, 0, 1), "tip")
    group = bpy.data.objects.new("Keeper", None)
    scene.collection.objects.link(group)
    for o in (joints["root"], *held):
        o.parent = group
    group.scale = (SCALE,) * 3
    bpy.context.view_layer.update()
    return group, joints


# --- pictures -------------------------------------------------------------------------------------------------

def glow(shaded, flat, keys, reach):
    """The shaded picture with its lit pieces drawn hot and given a halo, each in its own colour: found by their keys."""
    out = shaded.copy()
    out[..., :3] = out[..., :3] * 0.5 + flat[..., :3] * 0.5
    found = []
    for code, key in LIGHTS.values():
        piece = (np.abs(keys[..., :3] - np.array(key, dtype=np.float32)).max(axis=-1) < 0.09) * keys[..., 3]
        colour = np.array(rs.rgb(code), dtype=np.float32)
        hot = colour + (1 - colour) * 0.16
        out[..., :3] = out[..., :3] * (1 - piece[..., None]) + hot * piece[..., None]
        found.append((piece, colour))
    inside = out[..., 3:] > 0.01
    spill, cover, union = np.zeros_like(out[..., :3]), np.zeros_like(out[..., 3:]), np.zeros_like(out[..., 3:])
    for piece, colour in found:
        halo = np.clip(ss.blur(piece, reach) * 1.7, 0, 0.7)[..., None]
        out[..., :3] = np.where(inside, out[..., :3] + colour * halo * (1 - out[..., :3]), out[..., :3])
        spill += colour * halo
        cover += halo
        union = 1 - (1 - union) * (1 - halo * 0.85)
    out[..., :3] = np.where(inside, out[..., :3], spill / np.maximum(cover, 1e-6))
    out[..., 3:] = np.maximum(out[..., 3:], union)
    return out


def three_passes(scene, m, size, render):
    """The shaded, flat and keyed passes through `render(path)`, glowed."""
    passes = []
    for flat, keys in ((False, False), (True, False), (True, True)):
        keyed(m, keys)
        rs.workbench(scene, *size, flat=flat)
        path = OUT / "_pass.png"
        passes.append(render(path))
        path.unlink()
    keyed(m, False)
    return glow(*passes, reach=max(2, round(size[0] * 0.012)))


def take(direction, views, beat="idle", size=(900, 900), span=15.0, centre=(0, 0, 6.6), ground=None):
    """One keeper: {view: picture}, and its size. `ground`: a cyan circle on the floor ahead, the signature's tell."""
    scene = bl.reset_scene()
    m = materials()
    group, _ = build(scene, direction, m, beat)
    if ground:
        at, r = ground
        bm = bmesh.new()
        outer = [bm.verts.new((at[0] + r * math.cos(2 * math.pi * k / 48), at[1] + r * math.sin(2 * math.pi * k / 48), 0.02)) for k in range(48)]
        inner = [bm.verts.new((at[0] + r * 0.8 * math.cos(2 * math.pi * k / 48), at[1] + r * 0.8 * math.sin(2 * math.pi * k / 48), 0.02)) for k in range(48)]
        for k in range(48):
            bm.faces.new((outer[k], outer[(k + 1) % 48], inner[(k + 1) % 48], inner[k]))
        bl.object_from_bmesh("Tell", bm, m["Cyan"])
    out = {view: three_passes(scene, m, size, lambda path, a=az, e=el: rs.shoot(scene, path, a, e, centre, span))
           for view, (az, el) in views.items()}
    meshes = [o for o in scene.objects if o.type == "MESH" and o.name != "Tell"]
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    out["size"] = tuple(round(max(q[i] for q in pts) - min(q[i] for q in pts), 2) for i in range(3))
    return out


# the ring as TR2 frames it, measured off build/captures/tr2/keeper_framing.jpg with Roblox's 70 degrees up and down:
# the avatar a third of the frame high (the camera 10 studs back, 10 degrees down, the horizon a third from the top),
# the keeper 8 studs past it and 5 right, Rook right of the keeper and a little nearer, the two facing each other
RING = dict(size=(960, 540), fov=70.0, focus=(0.0, 0.0, 4.5), zoom=10.0, pitch=10.0,
            keeper=((5.0, 8.0), 221.6), rook=((8.2, 4.4), 41.6))
SEEN = (125, 2)    # how the ring's camera sees the keeper: 55 degrees round to its right, from a touch below the mask
DUSK, PAVING = rs.rgb("#2F2148"), "#4A4260"


def perspective(scene):
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle_y = math.radians(RING["fov"])
    cam.data.clip_end = 400
    focus = Vector(RING["focus"])
    p = math.radians(RING["pitch"])
    cam.location = focus + Vector((0, -math.cos(p), math.sin(p))) * RING["zoom"]
    cam.rotation_euler = (focus - cam.location).to_track_quat("-Z", "Y").to_euler()
    return cam


def rendered(scene, path):
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    return rs.load(path)


def ring_floor():
    scene = bl.reset_scene()
    m = bpy.data.materials.new("Paving")
    m.diffuse_color = rs.srgb(PAVING)
    bl.place(bl.cylinder("Ring", 40.0, 0.2, 96, m), location=(3.0, 6.0, -0.1))
    perspective(scene)
    rs.workbench(scene, *RING["size"], flat=False)
    scene.display.shading.show_object_outline = False
    path = OUT / "_floor.png"
    shot = rendered(scene, path)
    path.unlink()
    return shot


def ring_rook():
    """Rook, his baked model, and the player's grey R6 avatar between him and the camera, in Eevee."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Ring")
    with bpy.data.libraries.load(str(ROOK)) as (src, dst):
        dst.objects = list(src.objects)
    holder = bpy.data.objects.new("Rook", None)
    scene.collection.objects.link(holder)
    for o in dst.objects:
        if o.type == "MESH":
            scene.collection.objects.link(o)
            if o.parent is None:
                o.parent = holder
    (x, y), turn = RING["rook"]
    holder.location, holder.rotation_euler = (x, y, 0), (0, 0, math.radians(turn))
    grey = bpy.data.materials.new("Avatar")
    grey.diffuse_color = (0.42, 0.42, 0.44, 1)
    grey.use_nodes = True
    grey.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.42, 0.44, 1)
    for size, at in (((2, 1, 2), (0, 0, 3)), ((1.2, 1.2, 1.2), (0, 0, 4.6)), ((1, 1, 2), (1.5, 0, 3)), ((1, 1, 2), (-1.5, 0, 3)),
                     ((1, 1, 2), (0.5, 0, 1)), ((1, 1, 2), (-0.5, 0, 1))):
        bl.place(bl.box("Avatar", size, grey), location=at)
    perspective(scene)
    rm.eevee(scene, *RING["size"])
    rm.sun_for(scene, 0.0)
    path = OUT / "_rook.png"
    shot = rendered(scene, path)
    path.unlink()
    return shot


HELD = ("Pole", "Ferrule", "Hook", "LampCord", "LampTop", "LampHeart", "LampFoot", "LampHoop", "Tuft")


def ring_keeper(direction):
    """The keeper in the ring, glowed, and how much of the frame's height its body takes, the pole and lantern left out."""
    from bpy_extras.object_utils import world_to_camera_view
    scene = bl.reset_scene()
    m = materials()
    group, _ = build(scene, direction, m)
    (x, y), turn = RING["keeper"]
    group.location, group.rotation_euler = (x, y, 0), (0, 0, math.radians(turn))
    cam = perspective(scene)
    bpy.context.view_layer.update()
    body = [o for o in scene.objects if o.type == "MESH" and not o.name.startswith(HELD)]
    top = max((o.matrix_world @ v.co for o in body for v in o.data.vertices), key=lambda p: p.z)
    share = world_to_camera_view(scene, cam, top).y - world_to_camera_view(scene, cam, Vector((x, y, 0.0))).y
    return three_passes(scene, m, RING["size"], lambda path: rendered(scene, path)), share


def ring_frame(floor, keeper, rook):
    w, h = RING["size"]
    shot, share = keeper
    page = rs.canvas(w, h, DUSK)
    rs.paste(page, floor, 0, 0)
    rs.paste(page, shot, 0, 0)
    rs.paste(page, rook, 0, 0)
    whole = np.nonzero(shot[..., 3].max(axis=1) > 0.62)[0]
    return page, share, (whole.max() - whole.min() + 1) / h if len(whole) else 0.0


def figure_height(shot):
    rows = np.nonzero(shot[..., 3].max(axis=1) > 0.62)[0]
    return rows.max() - rows.min() + 1


def sheet(small):
    ss.OUT = OUT
    views = {"front": (180, 4), "player": SEEN}
    takes = {d: take(d, {**views, **({"back": (0, 4)} if d == PICK else {})}) for d in DIRECTIONS}
    windup = take(PICK, {"quarter": (138, 12)}, beat="windup", size=(1400, 900), span=28.0, centre=(1.5, 2.0, 6.4),
                  ground=((0.0, 7.5), 2.2))
    shade = ss.take("Brawler", "Strength", "hung", {"player": ss.PLAYER})
    floor, rook = ring_floor(), ring_rook()
    rings = {d: ring_frame(floor, ring_keeper(d), rook) for d in DIRECTIONS}
    for d, t in takes.items():
        print(f"{d}: {t['size']} studs; in the ring its body {rings[d][1]:.0%} of the frame's height, {rings[d][2]:.0%} with its pole")

    W, H = 1920, 1640
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft, pale = "#1E1B22", "#6A655E", "#B9B4C6"
    text = [(40, 30, 56, "THE LAMPLIGHTER", ink),
            (520, 34, 24, "Lantern Row's keeper: a Shade in full festival dress, three directions. My pick is A.", ink),
            (520, 68, 18, "The Shade's empty coat and lit hollows under a festival coat, its own mask, a hat or hood, and the gate's great lantern on a pole.", soft)]

    # row 1: the three, front, as the player sees it, outline, on the dusk they're met in
    top, floor_y, col = 110, 640, 626
    rs.fill(page, 20, top, W - 40, floor_y - top + 30, ss.NIGHT)
    for i, (d, spec) in enumerate(DIRECTIONS.items()):
        x = 24 + i * col
        t = takes[d]
        rs.stand(page, rs.shrink(t["front"], 0.46), x + 6, floor_y, 320)
        rs.stand(page, rs.shrink(t["player"], 0.36), x + 320, floor_y, 190)
        rs.stand(page, ss.solid(rs.shrink(t["player"], 0.18)), x + 512, floor_y, 100)
        text += [(x + 10, top + 10, 30, f"{d}  {spec['name']}", "#FFF4D6" if d == PICK else pale),
                 (x + 140, floor_y + 6, 14, "front", pale), (x + 336, floor_y + 6, 14, "as the ring sees it", pale),
                 (x + 530, floor_y + 6, 14, "outline", pale)]
        y = floor_y + 44
        text += [(x + 6, y + k * 20, 15, line, ink) for k, line in enumerate(textwrap.wrap(spec["what"], 66)[:2])]
        text.append((x + 6, y + 48, 15, "What's wrong:", ink))
        text += [(x + 6, y + 68 + k * 19, 14, line, soft) for k, line in enumerate(spec["wrong"]) if line]

    # row 2: in the ring beside Rook, as TR2 frames the fight
    y2 = 860
    text.append((40, y2 - 34, 22, "IN THE RING, BESIDE ROOK", ink))
    text.append((420, y2 - 30, 16, "TR2's framing: the camera behind the player's avatar (grey), Rook fighting at the keeper's side.", soft))
    for i, d in enumerate(DIRECTIONS):
        frame, share, whole = rings[d]
        x = 24 + i * col + 8
        rs.paste(page, rs.shrink(frame, 600 / RING["size"][0]), x, y2)
        text.append((x, y2 + 344, 15, f"{d}: its body {share:.0%} of the frame's height, {whole:.0%} with the pole (TR2's box: a third)", soft))

    # row 3: at 64 px, the pick's back, and its signature's wind-up
    y3 = 1290
    text.append((40, y3 - 34, 22, "AT 64 PX", ink))
    text.append((200, y3 - 30, 16, "as the ring sees it, whole with its pole in 64 px, beside an ordinary Shade at the same scale", soft))
    grounds = ((ss.NIGHT, False), (ss.DAY, False), (ss.PAPER, True))
    k64 = {d: 64 / figure_height(takes[d]["player"]) for d in DIRECTIONS}
    for r, (ground, dark) in enumerate(grounds):
        rs.fill(page, 30, y3 + r * 92, 560, 90, ground)
        for c, d in enumerate(DIRECTIONS):
            shot = rs.shrink(takes[d]["player"], k64[d])
            rs.stand(page, ss.solid(shot) if dark else shot, 40 + c * 120, y3 + r * 92 + 86, 110)
        small_shade = rs.shrink(shade["player"], k64[PICK] * (900 / 15.0) / 100.0)
        rs.stand(page, ss.solid(small_shade) if dark else small_shade, 400, y3 + r * 92 + 86, 80)
    text += [(90 + c * 120, y3 + 280, 13, d, soft) for c, d in enumerate(DIRECTIONS)] + [(414, y3 + 280, 13, "a Shade", soft)]

    x4 = 640
    rs.fill(page, x4, y3, 300, 272, ss.NIGHT)
    rs.stand(page, rs.shrink(takes[PICK]["back"], 0.32), x4, y3 + 262, 300)
    text.append((x4 + 8, y3 + 6, 14, f"{PICK} from behind: the crest", pale))
    x5 = 960
    rs.fill(page, x5, y3, 560, 272, ss.NIGHT)
    rs.stand(page, rs.shrink(windup["quarter"], 0.29), x5, y3 + 262, 560)
    text += [(x5 + 8, y3 + 6, 14, "The signature's pose, a seed: the pole planted, the lantern swung up,", pale),
             (x5 + 8, y3 + 24, 14, "a cyan circle lit under the lead before the slam", pale)]
    x6 = 1540
    text += [(x6, y3, 18, "Why A", ink),
             (x6, y3 + 28, 14, "The planted pole is the signature's own", soft), (x6, y3 + 46, 14, "start, so its stance already says what", soft),
             (x6, y3 + 64, 14, "it will do. The cone hat is an outline no", soft), (x6, y3 + 82, 14, "Shade has. The lantern hangs at the", soft),
             (x6, y3 + 100, 14, "mask's height, so lamp and face read as", soft), (x6, y3 + 118, 14, "one, and the face is a lantern too:", soft),
             (x6, y3 + 136, 14, "the street's master wears the street.", soft)]
    sz, third = takes[PICK]["size"], SCALE * (1 / 3) / rings[PICK][1]
    text.append((40, H - 48, 15, f"Blockout on R6 at {SCALE} times a Shade (the elite is 1.35): A stands {sz[2]} studs to the pole's top, its body "
                 f"{rings[PICK][1]:.0%} of the ring's frame. A third, as TR2's box, would be {third:.2f}: under the elite. The scale is the builder's number.", soft))
    text.append((40, H - 26, 15, "Workbench, orthographic but for the ring. The glow is drawn on the picture, not rendered. Rook is his baked model in Eevee.", soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "lamplighter_sheet.png")
    if small:
        rs.save(rs.shrink(page, 0.5), OUT / "lamplighter_sheet_small.png")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    sheet("small" in sys.argv[sys.argv.index("--") + 2:])
