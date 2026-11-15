"""Watt, designed again (AR11, "Designed again", research, 2026-11-15, night): three takes in grey on the R6 body, for
research's pick. Each is a different character from an anime's cast, inside a Common's limit: three or four elements
and Storm's one accent. Quick blockouts: hair, clothes and the weapon as rough meshes, never finished.

    A, the quiet wall: a long coat with a standing collar up to his nose, heavy hair swept back with lifted pale pink
       tips, a black iron spear-staff with three white ceramic discs slung across his back.
    B, the hothead: a sleeveless high-necked top, his jacket tied round his waist, hair spiked up and back over one
       shaved side with one pale pink lock, a slab of dark steel on his forearm with a spike at its foot.
    C, the sleepy one: an oversized hoodie with its hood down, wide trousers, a soft mop floating up with static, a
       long taped iron stake with one white ceramic ring, planted, that he leans on.

Each: three-quarter front and the game's camera, the face close up, and at 64 px over noon and night beside the leads
before him. Workbench only, so no GPU turn. Studs, X right, Y forward, Z up; he faces +Y; every piece hangs from one of
R6's six parts at the engine's own pivots, as rook_sheet.py's do.

    blender.exe -b --factory-startup --python tools/blender/watt_takes.py -- <out_dir>
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import lyric_sheet as lys  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_sheet as rs  # noqa: E402

PALETTE = {
    "Ink": "#17171A", "DarkDeep": "#202124", "Dark": "#2E2F33", "MidDeep": "#515359", "Mid": "#74767C", "Light": "#B6B7BC",
    "White": "#ECEBE7", "Skin": "#A3A3A7", "SkinShade": "#85858A", "Storm": "#FFB3E8",
}
PIVOTS = rs.PIVOTS
B = rs.B
loft, slab, bar, spike = rs.loft, rs.slab, ks.bar, ks.spike
R = 0.625  # the head's radius
GAME, FRONT = rs.GAME, ps.FRONT
PAPER, NIGHT, DAY = rs.PAPER, rs.NIGHT, rs.DAY
PX = ks.PX


def materials():
    made = {}
    for name, code in PALETTE.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def rig(scene):
    """Empties at R6's pivots, the limbs' on the torso's."""
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
    return joints


def on(joints, part, *objs):
    for o in objs:
        o.parent = joints[part]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[part]))


def rod(name, a, b, radius, material, segments=10):
    """A round bar from a to b, any way it leans."""
    a, b = Vector(a), Vector(b)
    o = bl.cylinder(name, radius, (b - a).length, segments, material)
    o.data.transform(Matrix.Translation((a + b) / 2) @ Vector((0, 0, 1)).rotation_difference((b - a).normalized()).to_matrix().to_4x4())
    return o


def tipped(name, base, tip, half, m, hair, share=0.34):
    """A clump of hair, its end in Storm."""
    base, tip = Vector(base), Vector(tip)
    axis = (tip - base).normalized()
    return [spike(name, base, tip, half, m[hair]),
            spike(name + "Tip", base + (tip - base) * (1 - share), tip + axis * 0.03, half * share * 1.12, m["Storm"])]


def face(name, x, z, w, h, material, tilt=0.0, proud=0.0):
    y = math.sqrt(R * R - x * x)
    return slab(name, (x, y + proud, z), (w, 0.05, h), material, rot=(0, tilt, -math.degrees(math.asin(x / R))))


def head(m):
    return loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                         (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2)


def eyes(m, opened, lid, lid_tilt=0.0, brow_tilt=0.0, brow_z=4.66, z=4.47):
    """An anime eye a side: its white, a grey iris, the pupil, one light, the lid's dark line and a brow. A tilt above
    zero drops the outer end (sleepy); below zero, the inner end (fierce)."""
    made = []
    for e in (1, -1):
        x = e * 0.25
        made += [face("EyeWhite", x, z, 0.21, opened, m["White"]),
                 face("Iris", x, z, 0.125, min(opened, 0.17), m["Mid"], proud=0.008),
                 face("Pupil", x, z, 0.06, min(opened, 0.1) * 0.9, m["Ink"], proud=0.016),
                 face("Light", x + 0.035, z + opened * 0.2, 0.04, min(0.04, opened * 0.4), m["White"], proud=0.024),
                 face("Lid", x, z + opened / 2 + lid / 2 - 0.005, 0.25, lid, m["Ink"], tilt=e * lid_tilt, proud=0.026),
                 face("Brow", x, brow_z, 0.27, 0.05, m["Ink"], tilt=e * brow_tilt, proud=0.03)]
    return made


def legs(joints, m, trouser, boot, top=0.62):
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(joints, part,
           loft("Trouser", [(top - 0.1, cx, 0, 0.98, 1.0), (2.0, cx, 0, 1.0, 1.02)], m[trouser], n=B),
           loft("Sole", [(0.0, cx, 0.1, 1.04, 1.32), (0.14, cx, 0.1, 1.04, 1.32)], m["Ink"], n=B),
           loft("Boot", [(0.14, cx, 0.08, 1.0, 1.26), (0.4, cx, 0.04, 1.0, 1.12), (top, cx, 0, 1.02, 1.06)], m[boot], n=B))


# --- A, the quiet wall ---------------------------------------------------------------------------------------------

def take_a(scene):
    m, j = materials(), rig(scene)

    def collar_top(t):  # at his nose in front, higher behind
        return 4.37 + 0.16 * max(0.0, -math.sin(t))

    on(j, "root",
       loft("Coat", [(2.0, 0, 0, 2.1, 1.12), (3.3, 0, 0, 2.1, 1.12), (3.96, 0, 0, 2.12, 1.12), (4.03, 0, 0, 1.9, 1.0)], m["Dark"], n=B),
       loft("Skirt", [(0.42, 0, -0.04, 2.44, 1.46), (2.05, 0, 0, 2.12, 1.14)], m["Dark"], n=B),
       slab("Opening", (0, 0.63, 1.22), (0.36, 0.2, 1.6), m["MidDeep"]),
       slab("Seam", (0, 0.565, 3.0), (0.05, 0.03, 1.9), m["DarkDeep"]),
       loft("Collar", [(3.9, 0, 0, 1.6, 1.5), (collar_top, 0, 0, 1.54, 1.46), (collar_top, 0, 0, 1.4, 1.32), (3.9, 0, 0, 1.44, 1.36)],
            m["Dark"], n=2.5, closed=True),
       bar("Strap", (-0.9, 0.585, 2.3), (0.9, 0.585, 3.9), 0.16, 0.04, m["MidDeep"]))
    for part, e in (("rs", 1), ("ls", -1)):  # the coat's sleeves pushed to the elbows, bare forearms
        cx = e * 1.5
        on(j, part,
           loft("Sleeve", [(3.02, cx, 0, 1.1, 1.1), (4.0, cx, 0, 1.1, 1.1), (4.06, e * 1.46, 0, 0.9, 0.92)], m["Dark"], n=B),
           loft("Roll", [(2.86, cx, 0, 1.2, 1.2), (3.08, cx, 0, 1.2, 1.2)], m["DarkDeep"], n=B),
           loft("Forearm", [(2.0, cx, 0, 0.94, 0.94), (2.9, cx, 0, 0.96, 0.96)], m["Skin"], n=B))
    legs(j, m, "MidDeep", "DarkDeep")

    def hairline(t):  # swept back off his brow, long at the nape
        return 4.62 + 0.26 * max(0.0, math.sin(t)) ** 1.5 - 0.3 * max(0.0, -math.sin(t))

    hair = [loft("Hair", [(hairline, 0, -0.02, 1.32, 1.32), (5.0, 0, -0.04, 1.37, 1.37), (5.15, 0, -0.06, 1.2, 1.2),
                          (5.21, 0, -0.08, 0.72, 0.7)], m["Ink"], n=2)]
    for x, lift, reach in ((-0.44, 0.3, 1.0), (-0.2, 0.62, 1.2), (0.03, 0.42, 1.32), (0.25, 0.72, 1.16), (0.46, 0.34, 1.02)):
        hair += tipped("Clump", (x, 0.18, 4.98), (x * 1.3, -reach, 5.2 + lift), 0.27, m, "Ink")
    for x, lift in ((-0.42, 0.2), (0.0, 0.05), (0.42, 0.26)):  # the nape's ends, lifting
        hair += tipped("Nape", (x, -0.42, 4.62), (x * 1.5, -1.2, 4.72 + lift), 0.24, m, "Ink")
    on(j, "neck", head(m), *hair, *eyes(m, 0.12, 0.055, lid_tilt=0.0, brow_tilt=-4.0, brow_z=4.63))

    # the spear-staff slung across his back, its blade over his right shoulder: black iron, three white discs
    a, b = Vector((-1.3, -0.8, 1.0)), Vector((1.5, -0.8, 6.15))
    u, length = (b - a).normalized(), (b - a).length
    lean = math.degrees(math.atan2(u.x, u.z))
    on(j, "root",
       rod("Shaft", a, a + u * (length - 0.7), 0.075, m["Ink"]),
       *[bl.place(bl.cylinder("Disc", 0.3, 0.07, 16, m["White"]), location=a + u * (length - s), rotation=(0, lean, 0))
         for s in (0.95, 1.22, 1.49)],
       spike("Blade", a + u * (length - 0.72), b + u * 0.1, 0.15, m["Light"]),
       rod("Butt", a - u * 0.12, a + u * 0.1, 0.11, m["MidDeep"]))
    return j


# --- B, the hothead ------------------------------------------------------------------------------------------------

def take_b(scene):
    m, j = materials(), rig(scene)
    on(j, "root",
       loft("Top", [(2.0, 0, 0, 2.02, 1.04), (3.96, 0, 0, 2.04, 1.06), (4.03, 0, 0, 1.86, 0.98)], m["Dark"], n=B),
       loft("HighNeck", [(3.94, 0, 0, 1.26, 1.24), (4.17, 0, 0, 1.24, 1.22)], m["Dark"], n=2.5),
       # the jacket tied round his waist: its band, the knot at his left hip, two sleeve ends, its body behind
       loft("Tied", [(2.0, 0, 0, 2.2, 1.24), (2.42, 0, 0, 2.18, 1.22)], m["Mid"], n=B),
       slab("Knot", (-0.55, 0.66, 2.2), (0.42, 0.3, 0.38), m["MidDeep"], rot=(10, 0, 20)),
       bar("SleeveEnd", (-0.72, 0.7, 2.1), (-0.98, 0.7, 1.28), 0.3, 0.12, m["Mid"]),
       bar("SleeveEnd", (-0.42, 0.74, 2.1), (-0.3, 0.74, 1.42), 0.3, 0.12, m["Mid"]),
       slab("Cuff", (-0.98, 0.7, 1.28), (0.34, 0.14, 0.12), m["Light"]),
       slab("Cuff", (-0.3, 0.74, 1.42), (0.34, 0.14, 0.12), m["Light"]),
       slab("JacketBack", (0, -0.68, 1.62), (1.96, 0.1, 0.96), m["Mid"], rot=(-5, 0, 0)),
       slab("JacketHem", (0, -0.73, 1.16), (1.96, 0.1, 0.12), m["Light"]))
    for part, e in (("rs", 1), ("ls", -1)):  # bare arms, fingerless gloves with a pale strap
        cx = e * 1.5
        on(j, part,
           loft("Arm", [(2.0, cx, 0, 0.98, 0.98), (4.0, cx, 0, 1.0, 1.0), (4.06, e * 1.46, 0, 0.86, 0.88)], m["Skin"], n=B),
           loft("Glove", [(2.06, cx, 0, 1.04, 1.04), (2.56, cx, 0, 1.04, 1.04)], m["DarkDeep"], n=B),
           loft("GloveStrap", [(2.52, cx, 0, 1.08, 1.08), (2.64, cx, 0, 1.08, 1.08)], m["Light"], n=B))
    # the slab of dark steel on his left forearm, taller than the arm, a spike at its foot for the street
    sx = -2.22
    on(j, "ls",
       slab("Slab", (sx, 0.05, 2.5), (0.3, 1.36, 2.5), m["DarkDeep"]),
       slab("SlabEdge", (sx, 0.75, 2.5), (0.34, 0.07, 2.5), m["Mid"]),
       slab("SlabTop", (sx, 0.05, 3.76), (0.34, 1.4, 0.08), m["Mid"]),
       slab("Mount", (-1.98, 0, 2.3), (0.3, 1.1, 0.16), m["MidDeep"]),
       slab("Mount", (-1.98, 0, 3.1), (0.3, 1.1, 0.16), m["MidDeep"]),
       spike("Spike", (sx, 0.05, 1.26), (sx, 0.05, 0.3), 0.2, m["Light"]))
    legs(j, m, "MidDeep", "Dark", top=0.95)

    def hairline(t):
        return 4.7 + 0.1 * max(0.0, math.sin(t)) - 0.28 * max(0.0, -math.sin(t))

    hair = [loft("Shaved", [(hairline, 0, -0.02, 1.29, 1.29), (5.0, 0, -0.02, 1.3, 1.3), (5.11, 0, -0.03, 1.14, 1.14),
                            (5.15, 0, -0.04, 0.7, 0.7)], m["MidDeep"], n=2)]
    for k, (x, y, lift) in enumerate(((0.44, 0.3, 0.2), (0.16, 0.34, 0.5), (-0.1, 0.24, 0.3), (0.5, -0.05, 0.42), (0.2, -0.08, 0.72),
                                      (-0.06, -0.16, 0.44), (0.42, -0.4, 0.3), (0.1, -0.44, 0.52))):
        hair.append(spike("Spike", (x, y, 4.98), (x * 1.3 + 0.1, y - 0.52 - 0.04 * k, 5.6 + lift), 0.25, m["Ink"]))
    for z, reach in ((4.86, 0.9), (4.62, 0.8)):  # his right side swept back
        hair.append(spike("Side", (0.56, 0.12, z), (0.98, -reach, z + 0.3), 0.2, m["Ink"]))
    hair.append(spike("Lock", (0.3, 0.5, 5.04), (0.52, 0.74, 4.5), 0.11, m["Storm"]))  # the one pale pink lock, over his right brow
    on(j, "neck", head(m), *hair, *eyes(m, 0.2, 0.035, lid_tilt=-8.0, brow_tilt=-16.0, brow_z=4.66),
       face("Nose", 0.0, 4.34, 0.06, 0.05, m["SkinShade"], proud=0.02),
       face("Grin", 0.03, 4.2, 0.37, 0.13, m["Ink"], tilt=-6, proud=0.03),
       face("Teeth", 0.03, 4.205, 0.31, 0.075, m["White"], tilt=-6, proud=0.04))
    for part, axis, deg in (("rh", (0, 1, 0), -5), ("lh", (0, 1, 0), 5), ("rs", (0, 1, 0), -9), ("ls", (0, 1, 0), 7)):  # feet and arms apart
        j[part].rotation_quaternion = Quaternion(axis, math.radians(deg))
    return j


# --- C, the sleepy one ---------------------------------------------------------------------------------------------

def take_c(scene):
    m, j = materials(), rig(scene)
    on(j, "root",
       loft("Hoodie", [(1.72, 0, 0, 2.3, 1.3), (1.9, 0, 0, 2.36, 1.36), (3.3, 0, 0, 2.3, 1.3), (3.96, 0, 0, 2.24, 1.24),
                       (4.04, 0, 0, 1.9, 1.0)], m["Mid"], n=8),
       loft("Hem", [(1.7, 0, 0, 2.34, 1.34), (1.92, 0, 0, 2.38, 1.38)], m["MidDeep"], n=8),
       loft("Hood", [(3.85, 0, -0.42, 1.9, 1.3), (4.1, 0, -0.5, 2.02, 1.38), (4.34, 0, -0.52, 1.72, 1.12)], m["Mid"], n=2.5),
       loft("Lining", [(4.33, 0, -0.52, 1.34, 0.78), (4.37, 0, -0.52, 1.24, 0.7)], m["Storm"], n=2.5),
       slab("Pocket", (0, 0.68, 2.36), (1.3, 0.06, 0.5), m["MidDeep"]),
       *[bar("String", (e * 0.22, 0.67, 3.92), (e * 0.27, 0.69, 3.16), 0.06, 0.05, m["Storm"]) for e in (-1, 1)])
    for part, e in (("rs", 1), ("ls", -1)):  # sleeves past his hands
        cx = e * 1.5
        on(j, part,
           loft("Sleeve", [(1.88, cx, 0, 1.2, 1.2), (2.0, cx, 0, 1.24, 1.24), (3.9, e * 1.52, 0, 1.2, 1.2), (4.06, e * 1.46, 0, 0.95, 0.95)],
                m["Mid"], n=8),
           loft("Cuff", [(1.84, cx, 0, 1.1, 1.1), (2.0, cx, 0, 1.12, 1.12)], m["MidDeep"], n=8),
           loft("Fingers", [(1.7, cx, 0.02, 0.7, 0.8), (1.86, cx, 0.02, 0.74, 0.84)], m["Skin"], n=B))
    for part, s in (("rh", 1), ("lh", -1)):  # wide trousers over pale shoes
        cx = s * 0.5
        on(j, part,
           loft("Wide", [(0.22, cx, 0, 1.3, 1.36), (0.9, cx, 0, 1.2, 1.24), (2.0, cx, 0, 1.04, 1.06)], m["Dark"], n=8),
           loft("Shoe", [(0.0, cx, 0.14, 0.92, 1.34), (0.24, cx, 0.12, 0.88, 1.22)], m["Light"], n=8))

    def hairline(t):  # a fringe down to his brows
        return 4.6 + 0.12 * max(0.0, math.sin(t)) - 0.22 * max(0.0, -math.sin(t))

    hair = [loft("Mop", [(hairline, 0, 0, 1.44, 1.44), (4.95, 0, 0, 1.64, 1.62), (5.3, 0, -0.02, 1.5, 1.46), (5.5, 0, -0.02, 0.9, 0.86)],
                 m["Light"], n=2)]
    for x in (-0.42, -0.16, 0.1, 0.36):
        hair.append(spike("Fringe", (x, 0.58, 4.98), (x * 1.05 + 0.03, 0.7, 4.66), 0.17, m["Light"]))
    for x, y, z, r in ((0.0, 0.0, 5.38, 0.42), (0.42, 0.15, 5.25, 0.36), (-0.44, 0.1, 5.22, 0.36), (0.3, -0.4, 5.2, 0.38),
                       (-0.32, -0.42, 5.18, 0.38), (0.0, 0.45, 5.12, 0.3), (0.62, -0.1, 4.95, 0.3), (-0.64, -0.12, 4.95, 0.3)):
        hair.append(bl.place(bl.sphere("Tuft", r, 10, 6, m["Light"]), location=(x, y, z)))  # soft lobes
    for x, y, dx, lift in ((0.05, 0.0, 0.06, 0.62), (0.44, 0.12, 0.2, 0.46), (-0.46, 0.06, -0.24, 0.5), (0.26, -0.42, 0.12, 0.56),
                           (-0.3, -0.44, -0.1, 0.42)):
        hair.append(spike("Wisp", (x, y, 5.42), (x + dx, y, 5.62 + lift), 0.065, m["Light"]))  # lifted by the static
    on(j, "neck", head(m), *hair, *eyes(m, 0.085, 0.07, lid_tilt=6.0, brow_tilt=8.0, brow_z=4.635),
       face("Mouth", 0.0, 4.2, 0.09, 0.035, m["Ink"], proud=0.03))

    # the stake, planted at his right side and held: iron, taped where he holds it, one white ceramic ring
    foot, top = Vector((2.25, 0.7, -0.25)), Vector((1.85, 0.55, 6.3))
    u, length = (top - foot).normalized(), (top - foot).length
    stake = [rod("Stake", foot + u * 0.5, top, 0.085, m["Ink"]),
             spike("Point", foot + u * 0.5, foot, 0.085, m["Ink"]),
             rod("Ring", foot + u * (length - 0.78), foot + u * (length - 0.66), 0.26, m["White"], 16),
             rod("Cap", top - u * 0.1, top + u * 0.04, 0.12, m["MidDeep"])]
    stake += [rod("Tape", foot + u * s, foot + u * (s + 0.2), 0.115, m["Light"]) for s in (2.3, 2.55, 2.8, 3.05, 3.3)]
    on(j, "root", *stake)
    j["rs"].rotation_quaternion = Quaternion((0, 1, 0), math.radians(-25)) @ Quaternion((1, 0, 0), math.radians(24))  # his hand on the tape
    j["root"].rotation_quaternion = Quaternion((0, 1, 0), math.radians(4))  # his weight on it
    j["neck"].rotation_quaternion = Quaternion((0, 1, 0), math.radians(9)) @ Quaternion((1, 0, 0), math.radians(5))
    return j


TAKES = {"A": take_a, "B": take_b, "C": take_c}
WHO = {
    "A": ("A, the quiet wall", ("a long coat, its standing collar up to his nose, sleeves pushed to the elbows",
                                "heavy hair swept back, its ends lifting, pale pink at the tips",
                                "a black iron spear-staff, three white discs under a short blade, slung across his back",
                                "half-lidded, steady eyes over the collar")),
    "B": ("B, the hothead", ("a sleeveless high-necked top, his jacket tied round his waist",
                             "hair spiked up and back over one shaved side, one pale pink lock",
                             "a slab of dark steel on his left forearm, a spike at its foot",
                             "a grin, and fingerless gloves")),
    "C": ("C, the sleepy one", ("an oversized hoodie, its hood down and lined in Storm, and wide trousers",
                                "a soft pale mop that floats up with the static",
                                "an iron stake taller than him, taped, with one white ceramic ring",
                                "he plants it and leans on it, eyes half asleep")),
}
CLOSE = (Vector((0, 0, 4.62)), 2.5, 2 * PX)


def shots():
    """{(take, view): picture} at PX a stud, cut to what's drawn, and each take's size and triangles."""
    out = {}
    for key, build in TAKES.items():
        scene = bl.reset_scene()
        joints = build(scene)
        rs.stand_on_floor(joints)
        bpy.context.view_layer.update()
        meshes = [o for o in scene.objects if o.type == "MESH"]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        low, high = Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)])
        centre, span = (low + high) / 2, (high - low).length * 1.02
        for view, (azimuth, elevation) in (("front", FRONT), ("game", GAME), ("flat", (180, 0))):
            out[key, view] = rs.trim(ks.render(scene, view, azimuth, elevation, centre, span, PX))
        out[key, "face"] = rs.trim(ks.render(scene, "face", 166, 4, *CLOSE))
        out[key, "size"] = tuple(round(high[i] - low[i], 2) for i in range(3))
        out[key, "tris"] = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
        print(f"{key}: {out[key, 'size']} studs, top {high.z:.2f}, {out[key, 'tris']} triangles")
    return out


def leads():
    """The leads before him, standing, from the game's camera and the front: Rook, Kirra, Pip, Lyric."""
    out = {}
    scene = bl.reset_scene()
    joints = rs.build(scene, rs.CHOSEN)
    rs.POSES["idle"](joints)
    meshes = [o for o in scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    low, high = Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)])
    for view, (azimuth, elevation) in (("game", GAME), ("front", FRONT)):
        out["Rook", view] = rs.trim(ks.render(scene, view, azimuth, elevation, (low + high) / 2, (high - low).length * 1.02, PX))
    k = ks.takes({"idle": {"game": GAME, "front": FRONT}})
    for view in ("game", "front"):
        out["Kirra", view] = rs.trim(k["idle", view])
    for name, mod in (("Pip", ps), ("Lyric", lys)):  # their takes draw 1000 px over 10 studs: 100 px a stud, as PX
        p = mod.takes({"idle": {view: (*angle, mod.MID) for view, angle in (("game", GAME), ("front", FRONT))}})
        for view in ("game", "front"):
            out[name, view] = rs.trim(p["idle", view])
    return out


LEADS = ("Rook", "Kirra", "Pip", "Lyric")


def measures(s, others):
    """Each take's outline at 64 px against each lead's, from the game's camera and the front: 1 is the same outline."""
    out = {}
    for key in TAKES:
        for view in ("game", "front"):
            mine = ks.silhouette(s[key, view])
            for name in LEADS:
                out[key, name, view] = ks.overlap(mine, ks.silhouette(others[name, view]))
        said = ", ".join(f"{name} {out[key, name, 'game']:.2f} and {out[key, name, 'front']:.2f}" for name in LEADS)
        print(f"at 64 px, {key} against each lead, game and front: {said}")
    for a, b in (("A", "B"), ("A", "C"), ("B", "C")):
        out[a, b] = ks.overlap(ks.silhouette(s[a, "game"]), ks.silhouette(s[b, "game"]))
        print(f"at 64 px, {a} against {b}, game: {out[a, b]:.2f}")
    for a, b in (("Pip", "Rook"), ("Lyric", "Rook"), ("Kirra", "Rook")):  # the scale: two leads already made
        out[a, b] = ks.overlap(ks.silhouette(others[a, "game"]), ks.silhouette(others[b, "game"]))
        print(f"at 64 px, {a} against {b}, game: {out[a, b]:.2f}")
    return out


def sheet():
    s, others = shots(), leads()
    measured = measures(s, others)
    W, H = 1920, 1700
    page = rs.canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 56, "WATT, three takes", ink),
            (560, 36, 22, "Common / Endurance / Tank / Storm. The first Voidkin a player didn't choose, and the first worker.", ink),
            (560, 68, 18, "In grey on the R6 body, Storm's pale pink the only colour. Quick blockouts: rough meshes, never finished. "
                          "Research picks one.", soft)]
    col = 626
    for i, key in enumerate(TAKES):
        x0 = 30 + i * col
        title, lines = WHO[key]
        text.append((x0 + 6, 118, 30, title, ink))
        ks.fit_row(page, text, [(s[key, "front"], "three-quarter front"), (s[key, "game"], "the game's camera")],
                   x0, x0 + col - 30, 640, 460, soft, gap=30)
        ks.fit_row(page, text, [(s[key, "face"], "the face, close"), (rs.black(s[key, "flat"]), "outline")],
                   x0, x0 + col - 30, 1010, 300, soft, gap=40)
        text += [(x0 + 6, 1052 + k * 24, 15, f"{k + 1}  {line}", soft) for k, line in enumerate(lines)]
        said = ", ".join(f"{name} {measured[key, name, 'game']:.2f}" for name in LEADS)
        text.append((x0 + 6, 1052 + 4 * 24 + 6, 15, f"At 64 px from the game's camera, against {said}.", ink))
        if i:
            rs.fill(page, x0 - 14, 110, 2, 1070, rs.rgb("#BDB8AE"))
    rs.fill(page, 30, 1190, 1860, 2, rs.rgb("#BDB8AE"))

    x0, y0 = 40, 1210
    keys = [(key, view) for key in TAKES for view in ("game", "front")]
    small = [rs.shrink(rs.trim(s[k]), ks.F64) for k in keys] + [rs.shrink(rs.trim(others[name, "game"]), ks.F64) for name in LEADS]
    widths = [q.shape[1] + 14 for q in small]
    for k in (1, 3, 5):
        widths[k] += 30
    text += [(x0, y0, 19, "at 64 px over noon, night, and in black: each take from the game's camera and the front, then the leads "
                          "before him from the game's camera", soft)]
    cx = x0 + 8
    for label, k in (("A", 0), ("B", 2), ("C", 4), ("Rook", 6), ("Kirra", 7), ("Pip", 8), ("Lyric", 9)):
        text.append((x0 + 8 + sum(widths[:k]), y0 + 30, 15, label, ink))
    for row, (ground, black) in enumerate(((DAY, False), (NIGHT, False), (PAPER, True))):
        yy = y0 + 54 + row * 110
        rs.fill(page, x0, yy, sum(widths) + 8, 106, ground)
        cx = x0 + 8
        for q, w in zip(small, widths):
            rs.stand(page, rs.black(q) if black else q, cx, yy + 102, q.shape[1])
            cx += w
    nx = x0 + sum(widths) + 50
    notes = ["1 is the same outline. For scale, two leads already made,",
             f"from the game's camera: Pip against Rook {measured['Pip', 'Rook']:.2f}, Lyric {measured['Lyric', 'Rook']:.2f},",
             f"Kirra {measured['Kirra', 'Rook']:.2f}.",
             f"The takes against each other: A and B {measured['A', 'B']:.2f}, A and C {measured['A', 'C']:.2f},",
             f"B and C {measured['B', 'C']:.2f}.",
             "The game's camera is behind his right shoulder and above:",
             "an assumption until Config holds its numbers.",
             "Views are orthographic. The body is R6 at the player's height,",
             "5 studs to the crown."]
    text += [(nx, y0 + 54 + k * 26, 16, line, soft) for k, line in enumerate(notes)]
    text.append((40, H - 36, 15, "Sizes in studs, across, deep, tall: " + "; ".join(
        f"{key} {s[key, 'size'][0]} x {s[key, 'size'][1]} x {s[key, 'size'][2]}, {s[key, 'tris']} triangles" for key in TAKES) + ".", soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "watt_takes.png")


if __name__ == "__main__":
    OUT = rs.OUT = ks.OUT = ps.OUT = lys.OUT = bl.out_dir()
    sheet()
