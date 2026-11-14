"""Watt's design sheet (AR11, delivery 1): the mechanic, as a blockout on the R6 body.

blender.exe -b --factory-startup --python tools/blender/watt_sheet.py -- <out_dir> [small]
    the sheet; `small` also writes a half-size copy to iterate on
blender.exe -b --factory-startup --python tools/blender/watt_sheet.py -- <out_dir> check
    builds every pose and prints where the wrench, the hands and the lens land, without rendering: light on memory

The idea: a man and his tool, wired in one line. The current runs from the generator on his back, out of its two
coils, into the wrench and down into the street, and Ground Wire is that path made visible. The wrench's head is wider
than he is, and its handle ends in a copper ground rod: he plants it, and the head stands up as his shield. Against
Rook, the other broad body: Rook's outline is one collar wall over the shoulders and one ram on the right arm; Watt's
is a head between two posts, and a wrench beside him. Workbench only, so no GPU turn. Studs, X right, Y forward, Z up,
Watt faces +Y, and every piece of his body hangs from one of R6's six parts at the engine's own pivots, as
rook_sheet.py's do. The wrench is a prop of its own, set in each pose where his hands are. Rook is drawn beside him by
rook_sheet.py's own builder; kirra_sheet.py's render and measures are used as they are, so the numbers compare.
"""
import colorsys
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import lyric_sheet as lys  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_sheet as rs  # noqa: E402

PALETTE = {
    "Kiln": "#C46A2A", "KilnDeep": "#8A451B", "Steel": "#A8ACB2", "SteelDeep": "#6C727B", "Storm": "#FF6FD8",
    "Graphite": "#2E3035", "GraphiteDeep": "#212327", "Copper": "#B5713C", "CopperDeep": "#7E4A26",
    "Cream": "#E8DCC4", "Skin": "#6A4330", "SkinShade": "#55352A", "Ink": "#18171C", "Ghost": "#A4A3AB",
}
CHIPS = (("Kiln", "the coverall"), ("Steel", "the wrench, the generator"), ("Storm", "only what's lit"))
NEUTRALS = ("Graphite", "Copper", "Cream", "Skin")
SKY = "#47A6F5"  # Kirra's scarf: Storm sits beside it on the sheet
PIVOTS = rs.PIVOTS
B = rs.B
loft, slab, bar = rs.loft, rs.slab, ks.bar

PACK_Y = -1.04  # the generator housing's middle, behind him
COIL_X = 0.9  # the coils' posts, either side: clear of his head's outline from behind
VISOR_UP = 100.0  # degrees the visor turns up about its pivots, at rest
VISOR_PIVOT = Vector((0, 0.1, 4.8))
HEAD_W, HEAD_H, HEAD_Z = 3.6, 2.4, 4.2  # the wrench's head: across (wider than his chest, a tower shield), tall, its
#                                          middle up the handle from the rod's tip. The draft's 2.6 by 1.6 read as a big
#                                          wrench, never a shield, and left his outline 0.71 to 0.74 of Rook's.
JAW_W, JAW_DEPTH = 1.5, 1.45  # the jaw's open gap, and how deep it cuts below the shorter jaw's tip
JAW_TILT = 15.0  # degrees the gap leans off the handle's line, as a spanner's does: one jaw stands longer. Square and
#                 narrow, the gap left two even lobes, and three-quarter on the head read as a double axe
HEAD_N = 2.6  # the head's roundness: 2 an ellipse; boxier corners read as blades
GRIP_AT = 2.45  # the rubber grip's middle, up the handle from the tip: where a hand closes, stood
PLANTED = 0.3  # how deep the rod stands in the street, planted
WIRE_LEAN = 22.0  # Ground Wire's lean over the wrench, degrees: R6's legs don't bend, so the head comes down this way
LOW_GRIP = 1.0  # where his hand holds it, leant
SHADE_AT = 5.0  # the grey Shade in Ground Wire, ahead of him: a lead stands about this far from its target
RING = 5.6  # the ring's radius on the sheet, round the rod: a sheet number until Ground Wire's reach is data


def materials(lit=False):
    made = {}
    for name, code in {**PALETTE, "Lens": PALETTE["Storm" if lit else "Ink"]}.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


def arc_shell(name, radius, a0, a1, z0, z1, thick, material, segs=5):
    """A band of a cylinder about the vertical, from angle a0 to a1 (degrees, the front at 90), z0 to z1 high,
    `thick` deep outward, in `segs` flat facets: the visor."""
    bm = bmesh.new()
    rows = []
    for i in range(segs + 1):
        a = math.radians(a0 + (a1 - a0) * i / segs)
        c, s = math.cos(a), math.sin(a)
        rows.append([bm.verts.new((r * c, r * s, z)) for r, z in ((radius, z0), (radius, z1), (radius + thick, z1), (radius + thick, z0))])
    for a, b in zip(rows, rows[1:]):
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(list(reversed(rows[0])))
    bm.faces.new(rows[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, material)


def turned(objs, about, axis, degrees):
    """Turns pieces' meshes about a line through `about`, before they're parented."""
    m = Matrix.Translation(about) @ Matrix.Rotation(math.radians(degrees), 4, axis) @ Matrix.Translation(-about)
    for o in objs:
        o.data.transform(m)
        o.data.update()
    return objs


# --- the wrench -----------------------------------------------------------------------------------------------

def head_outline():
    """The wrench head's outline, (across, up the handle), and the gap's bottom and its mouth at the shorter jaw, up
    the handle along the gap's middle line."""
    pts, bottom, mouth, _ = head()
    return pts, bottom, mouth


def jaw_walls():
    """Each of the gap's two walls, as (its middle point, (across, up), just inside the gap; its length)."""
    return head()[3]


def head(steps=48, round_steps=12):
    """A superellipse HEAD_W by HEAD_H with the jaw's gap cut from its top, straight-walled and round at the bottom,
    leaning JAW_TILT off the handle's line: the outline, the gap's bottom and mouth, and its walls."""
    hw, hh, r, n = HEAD_W / 2, HEAD_H / 2, JAW_W / 2, HEAD_N
    tilt = math.radians(JAW_TILT)
    o = Vector((0, HEAD_Z))
    a = Vector((math.sin(tilt), math.cos(tilt)))  # the gap's middle line, out through the top
    b = Vector((a.y, -a.x))  # across the gap

    def rim(t):
        c, s = math.cos(t), math.sin(t)
        return Vector((hw * math.copysign(abs(c) ** (2 / n), c), HEAD_Z + hh * math.copysign(abs(s) ** (2 / n), s)))

    def crossing(v):  # where the head's upper rim meets the gap's wall at `v` across; the rim runs +b to -b
        lo, hi = 0.0, math.pi
        for _ in range(60):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if (rim(mid) - o).dot(b) > v else (lo, mid)
        return (lo + hi) / 2

    t_r, t_l = crossing(r), crossing(-r)
    span = t_r - (t_l - 2 * math.pi)
    pts = [rim(t_r - span * i / steps) for i in range(steps + 1)]
    mouth = min((rim(t) - o).dot(a) for t in (t_r, t_l))
    middle = mouth - JAW_DEPTH + r
    for k in range(round_steps + 1):
        angle = math.pi + math.pi * k / round_steps
        pts.append(o + a * (middle + r * math.sin(angle)) + b * (r * math.cos(angle)))
    walls = [(o + a * ((middle + top) / 2) + b * (e * (r - 0.01)), top - middle)
             for e, top in ((1, (rim(t_r) - o).dot(a)), (-1, (rim(t_l) - o).dot(a)))]
    return [tuple(p) for p in pts], HEAD_Z + (middle - r) * a.y, HEAD_Z + mouth * a.y, walls


def gap_across(up):
    """Where the gap's middle line runs across the head (the wrench's own x) at `up` along the handle."""
    return -(up - HEAD_Z) * math.tan(math.radians(JAW_TILT))  # the head is drawn across Y and turned 90: across is -x


def wrench(m, lit=False):
    """The wrench in its own frame: the rod's tip at the origin, the handle up +Z, the head's width along X and its
    broad face toward +Y. Steel, the grip rubber, the rod copper. Lit, the jaw's inner walls carry Storm."""
    outline = head_outline()[0]
    pieces = [bl.place(bl.cylinder("Rod", 0.02, 0.55, 12, m["Copper"], radius_top=0.13), location=(0, 0, 0.275)),
              bl.place(bl.cylinder("Ferrule", 0.17, 0.16, 16, m["SteelDeep"]), location=(0, 0, 0.63)),
              slab("Handle", (0, 0, 1.85), (0.48, 0.28, 2.3), m["Steel"]),
              slab("Grip", (0, 0, GRIP_AT), (0.56, 0.36, 0.6), m["GraphiteDeep"]),
              bl.place(bl.profile("Neck", [(-0.25, 2.8), (0.25, 2.8), (0.95, 3.25), (-0.95, 3.25)], 0.34, m["Steel"]), rotation=(0, 0, 90)),
              bl.place(bl.profile("WrenchHead", outline, 0.36, m["Steel"]), rotation=(0, 0, 90))]
    if lit:  # each wall's line, inside the gap; the drawing's across is the wrench's -x, so the lean turns about Y by -tilt
        pieces += [slab("JawLit", (-p.x, 0, p.y), (0.03, 0.4, length), m["Storm"], rot=(0, -JAW_TILT, 0)) for p, length in jaw_walls()]
    for o in pieces:
        o["wrench"] = True
    return pieces


def slot_middle():
    _, bottom, top = head_outline()
    return (bottom + top) / 2


def set_wrench(pieces, matrix):
    for o in pieces:
        o.data.transform(matrix)
        o.data.update()


def frame(u, w):
    """The wrench's turn: its handle along u (the tip toward the head), its width along w."""
    n = u.cross(w)
    return Matrix((w, n, u)).transposed().to_4x4()


# --- the body -------------------------------------------------------------------------------------------------

def point_on(joints, part, p):
    """Where a point of a part's rest pose (world studs, standing square) is, once posed."""
    bpy.context.view_layer.update()
    return joints[part].matrix_world @ (Vector(p) - Vector(PIVOTS[part]))


def build(scene, visor_up=True, lit=False):
    """Watt, standing square, without the wrench. Returns the joints: empties at R6's pivots. `visor_up`: flipped up
    on his brow, as at rest; down, it covers his eyes. `lit`: the lens in Storm, as in a fight's peak."""
    m = materials(lit)
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

    # the waist: the coverall's top half pulled down, its sleeves knotted round him at his left hip and their ends
    # hanging, the back panel over his seat; a rubber belt with a steel buckle
    on("root",
       loft("Hips", [(2.0, 0, 0, 2.04, 1.08), (2.42, 0, 0, 2.04, 1.08)], m["Kiln"], n=B),
       loft("Belt", [(2.2, 0, 0, 2.08, 1.12), (2.36, 0, 0, 2.08, 1.12)], m["GraphiteDeep"], n=B),
       slab("Buckle", (0.32, 0.57, 2.28), (0.22, 0.04, 0.14), m["Steel"]),
       loft("TiedSleeves", [(2.36, 0, 0, 2.18, 1.2), (2.6, 0, 0, 2.16, 1.18)], m["Kiln"], n=B),
       slab("Knot", (-0.94, 0.4, 2.46), (0.36, 0.46, 0.36), m["KilnDeep"], rot=(14, 0, 18)),
       bar("SleeveEnd", (-0.98, 0.5, 2.36), (-1.02, 0.52, 1.66), 0.32, 0.12, m["Kiln"]),
       bar("SleeveEnd", (-0.8, 0.6, 2.36), (-0.68, 0.62, 1.78), 0.3, 0.12, m["Kiln"]),
       slab("SleeveCuff", (-1.02, 0.52, 1.66), (0.34, 0.14, 0.1), m["KilnDeep"]),
       slab("SleeveCuff", (-0.68, 0.62, 1.78), (0.32, 0.14, 0.1), m["KilnDeep"]),
       slab("BackPanel", (0, -0.62, 2.06), (1.86, 0.08, 0.86), m["Kiln"], rot=(-6, 0, 0)),
       slab("PanelSeam", (0, -0.665, 2.42), (1.86, 0.02, 0.06), m["KilnDeep"]))
    # a heavy work shirt, short-sleeved, and a canvas harness: straps over the shoulders and down his chest to the
    # belt, a rubber chest strap with a steel clip
    on("root",
       loft("Shirt", [(2.5, 0, 0, 2.04, 1.08), (3.3, 0, 0, 2.06, 1.1), (3.96, 0, 0, 2.08, 1.1), (4.03, 0, 0, 1.9, 1.0)], m["Graphite"], n=B),
       loft("Collar", [(3.96, 0, 0.02, 1.36, 1.18), (4.08, 0, 0.02, 1.36, 1.18)], m["Graphite"], n=2.5),
       slab("ChestStrap", (0, 0.6, 3.4), (1.3, 0.04, 0.14), m["GraphiteDeep"]),
       slab("Clip", (0, 0.625, 3.4), (0.22, 0.04, 0.2), m["Steel"]))
    for e in (-1, 1):
        on("root",
           bar("Strap", (e * 0.56, 0.57, 4.0), (e * 0.62, 0.57, 2.42), 0.26, 0.05, m["Cream"]),
           slab("StrapTop", (e * 0.56, -0.02, 4.05), (0.26, 1.2, 0.06), m["Cream"]))
    # the generator on his back: a steel housing on a rubber frame, vents and a gauge on the camera's side; two
    # copper coils on posts at its top corners, each capped in Storm, where an effect starts
    on("root",
       *[bar("Rail", (e * 1.04, PACK_Y, 4.14), (e * 1.04, PACK_Y, 2.4), 0.12, 0.16, m["GraphiteDeep"]) for e in (-1, 1)],
       slab("RailTop", (0, PACK_Y, 4.14), (2.2, 0.16, 0.1), m["GraphiteDeep"]),
       loft("Housing", [(2.5, 0, PACK_Y, 1.9, 0.86), (2.62, 0, PACK_Y, 1.96, 0.9), (3.9, 0, PACK_Y, 1.96, 0.9),
                        (4.06, 0, PACK_Y, 1.84, 0.82)], m["Steel"], n=5),
       loft("HousingBase", [(2.44, 0, PACK_Y, 2.0, 0.94), (2.6, 0, PACK_Y, 2.0, 0.94)], m["SteelDeep"], n=5),
       *[slab("Vent", (-0.3, PACK_Y - 0.455, z), (0.9, 0.03, 0.07), m["SteelDeep"]) for z in (2.9, 3.08, 3.26)],
       bl.place(bl.cylinder("GaugeRim", 0.24, 0.06, 20, m["GraphiteDeep"]), location=(0.46, PACK_Y - 0.47, 3.62), rotation=(90, 0, 0)),
       bl.place(bl.cylinder("GaugeFace", 0.19, 0.04, 20, m["Cream"]), location=(0.46, PACK_Y - 0.49, 3.62), rotation=(90, 0, 0)),
       slab("Needle", (0.5, PACK_Y - 0.515, 3.66), (0.03, 0.01, 0.15), m["Storm"], rot=(0, -35, 0)))
    for e in (-1, 1):
        x = e * COIL_X
        on("root",
           bl.place(bl.cylinder("Post", 0.08, 0.3, 12, m["GraphiteDeep"]), location=(x, PACK_Y, 4.2)),
           bl.place(bl.cylinder("Coil", 0.26, 1.0, 20, m["Copper"]), location=(x, PACK_Y, 4.85)),
           *[bl.place(bl.cylinder("Winding", 0.275, 0.05, 20, m["CopperDeep"]), location=(x, PACK_Y, z)) for z in (4.5, 4.7, 4.9, 5.1)],
           bl.place(bl.cylinder("CoilCollar", 0.21, 0.06, 16, m["SteelDeep"]), location=(x, PACK_Y, 5.38)),
           bl.place(bl.sphere("Cap", 0.16, 16, 8, m["Storm"]), location=(x, PACK_Y, 5.52)))

    # the arms: the shirt's short sleeves, bare upper arms, rubber gloves to mid-forearm with a flared cuff
    for part, e in (("rs", 1), ("ls", -1)):
        cx = e * 1.5
        on(part,
           loft("Sleeve", [(3.34, cx, 0, 1.04, 1.04), (4.0, cx, 0, 1.04, 1.04), (4.06, e * 1.46, 0, 0.88, 0.9)], m["Graphite"], n=B),
           loft("SleeveHem", [(3.3, cx, 0, 1.08, 1.08), (3.42, cx, 0, 1.08, 1.08)], m["GraphiteDeep"], n=B),
           loft("Arm", [(2.7, cx, 0, 0.96, 0.96), (3.36, cx, 0, 0.98, 0.98)], m["Skin"], n=B),
           loft("Glove", [(1.82, cx, 0.02, 0.9, 0.94), (2.24, cx, 0.02, 0.94, 0.98), (2.5, cx, 0, 0.98, 1.0),
                          (2.84, cx, 0, 1.12, 1.12), (2.9, cx, 0, 1.12, 1.12)], m["GraphiteDeep"], n=B))

    # R6's round head, deep brown; a close crop under a cream headband; a shadow of stubble on a strong jaw; heavy
    # level brows, a broad nose, a small crooked line of a mouth: pleased with himself. The welding visor hangs from
    # two steel pivots at his temples, up or down.
    radius = 0.625

    def face(name, x, z, w, h, material, tilt=0.0, proud=0.0):
        y = math.sqrt(radius * radius - x * x)
        return slab(name, (x, y + proud, z), (w, 0.05, h), material, rot=(0, tilt, -math.degrees(math.asin(x / radius))))

    def hairline(t):
        front, back = max(0.0, math.sin(t)), max(0.0, -math.sin(t))
        return 4.62 + 0.22 * front ** 1.5 - 0.1 * back

    visor = [arc_shell("Visor", 0.7, 10, 170, 4.12, 4.9, 0.07, m["Steel"]),
             slab("LensRim", (0, 0.765, 4.5), (0.72, 0.04, 0.24), m["GraphiteDeep"]),
             slab("Lens", (0, 0.775, 4.5), (0.62, 0.05, 0.16), m["Lens"])]
    if visor_up:
        turned(visor, VISOR_PIVOT, "X", VISOR_UP)
    on("neck",
       loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                     (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2),
       loft("Stubble", [(3.98, 0, 0.08, 1.2, 1.12), (4.12, 0, 0.1, 1.27, 1.2), (4.3, 0, 0.1, 1.27, 1.2), (4.36, 0, 0.06, 1.2, 1.1)],
            m["SkinShade"], n=2),
       loft("Hair", [(hairline, 0, 0, 1.3, 1.3), (5.0, 0, -0.02, 1.33, 1.33), (5.12, 0, -0.04, 1.18, 1.16), (5.18, 0, -0.05, 0.7, 0.68)],
            m["Ink"], n=2),
       loft("Headband", [(4.78, 0, 0, 1.36, 1.36), (4.9, 0, 0, 1.36, 1.36)], m["Cream"], n=2),
       *[bl.place(bl.cylinder("Pivot", 0.09, 0.08, 12, m["Steel"]), location=(e * 0.74, VISOR_PIVOT.y, VISOR_PIVOT.z), rotation=(0, 90, 0))
         for e in (-1, 1)],
       *visor,
       face("BrowR", 0.25, 4.67, 0.3, 0.07, m["Ink"], proud=0.03),
       face("BrowL", -0.25, 4.67, 0.3, 0.07, m["Ink"], proud=0.03),
       face("EyeR", 0.24, 4.5, 0.15, 0.13, m["Ink"]),
       face("EyeL", -0.24, 4.5, 0.15, 0.13, m["Ink"]),
       face("LightR", 0.27, 4.53, 0.05, 0.05, m["Cream"], proud=0.012),
       face("LightL", -0.21, 4.53, 0.05, 0.05, m["Cream"], proud=0.012),
       face("Nose", 0.0, 4.37, 0.18, 0.15, m["SkinShade"], proud=0.05),
       face("Mouth", 0.04, 4.22, 0.24, 0.04, m["Ink"], tilt=-8, proud=0.085))

    # the legs: the coverall's legs, turned up at the boot; rubber knee pads; heavy rubber boots, thick soles, steel toes
    for part, s in (("rh", 1), ("lh", -1)):
        cx = s * 0.5
        on(part,
           loft("Trouser", [(0.6, cx, 0, 0.98, 1.0), (1.3, cx, 0, 1.0, 1.02), (2.0, cx, 0, 1.0, 1.02)], m["Kiln"], n=B),
           loft("Cuff", [(0.56, cx, 0.02, 1.04, 1.06), (0.72, cx, 0.02, 1.04, 1.06)], m["KilnDeep"], n=B),
           slab("KneePad", (cx, 0.53, 1.14), (0.72, 0.08, 0.42), m["GraphiteDeep"]),
           loft("Sole", [(0.0, cx, 0.1, 1.04, 1.34), (0.16, cx, 0.1, 1.04, 1.34)], m["Ink"], n=B),
           loft("Boot", [(0.16, cx, 0.08, 1.0, 1.28), (0.42, cx, 0.04, 0.98, 1.12), (0.62, cx, 0, 0.96, 1.0)], m["GraphiteDeep"], n=B),
           slab("ToeCap", (cx, 0.62, 0.3), (0.86, 0.16, 0.28), m["Steel"]))
    return joints


# --- poses ----------------------------------------------------------------------------------------------------

def pose_square(joints):
    """Square on, the arms held off the body; the wrench planted beside him, broadside, so its size reads."""
    rs.aim(joints["rs"], Quaternion(), (0.3, 0.0, -1.0))
    rs.aim(joints["ls"], Quaternion(), (-0.3, 0.0, -1.0))
    rs.stand_on_floor(joints)
    set_wrench(wrench(joints["m"]), Matrix.Translation((4.3, 0, -0.35)))


def pose_stood(joints):
    """Take A, how he stands: the wrench planted on its rod ahead of his right side, broadside, his hand on its grip,
    the head at his chest; the left hand by the knot; the chin up a touch, pleased with the job before it starts."""
    body = ks.turn(-10)
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rs"], body, (0.36, 0.42, -1.0), stage=False)
    rs.aim(joints["ls"], body, (-0.12, 0.16, -1.0), stage=False)
    joints["neck"].rotation_quaternion = body.inverted() @ ks.turn(-4, 3)
    rs.aim(joints["rh"], body, (0.14, -0.06, -1.0))
    rs.aim(joints["lh"], body, (-0.16, 0.1, -1.0), twist=8)
    rs.stand_on_floor(joints)
    hand = point_on(joints, "rs", (1.5, 0, 2.1))
    tip = Vector((hand.x + 0.1, hand.y + 0.1, -PLANTED))
    set_wrench(wrench(joints["m"]), Matrix.Translation(tip) @ Matrix.Rotation(math.radians(-20), 4, "Z"))
    joints["wrench"] = ("stood", tip)


def pose_leant(joints):
    """Take B, how he stands: the wrench's head rests on the street ahead of his right foot, its handle leaning back
    into his right hand, the rod past his wrist; the weight on it, easy."""
    body = ks.turn(-8)
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rs"], body, (0.26, 0.5, -1.0), stage=False)
    rs.aim(joints["ls"], body, (-0.12, 0.08, -1.0), stage=False)
    joints["neck"].rotation_quaternion = body.inverted() @ ks.turn(-12, 2)
    rs.aim(joints["rh"], body, (0.12, 0.08, -1.0))
    rs.aim(joints["lh"], body, (-0.14, -0.1, -1.0), twist=6)
    rs.stand_on_floor(joints)
    hand = point_on(joints, "rs", (1.5, 0, 2.1))
    pieces = wrench(joints["m"])
    verts = [v.co.copy() for o in pieces for v in o.data.vertices]
    yaw = math.radians(-20)  # his heading, and 12 degrees out to his right
    ahead = Vector((-math.sin(yaw), math.cos(yaw), 0))

    def placed(lean):
        u = (ahead * math.cos(lean) - Vector((0, 0, 1)) * math.sin(lean)).normalized()
        w = u.cross(Vector((0, 0, 1))).normalized()
        return Matrix.Translation(hand - u * LOW_GRIP) @ frame(u, w)

    low, high = math.radians(10), math.radians(80)
    for _ in range(40):  # the lean that sets the head's lowest point on the street
        mid = (low + high) / 2
        if min((placed(mid) @ v).z for v in verts) > 0:
            low = mid
        else:
            high = mid
    set_wrench(pieces, placed((low + high) / 2))
    joints["wrench"] = ("leant", math.degrees((low + high) / 2))


def pose_wire(joints):
    """Ground Wire's key pose, the hold after the slam: the wrench driven in rod first before him, its head a wall at
    his chest; hunched behind it, one foot braced back, both hands on the head's edges, the visor down and lit, the lens through the
    jaw's gap. In grey, one Shade ahead, and the ring round the rod. R6's spread legs lift the body (the soles' edges
    go lowest), so the head comes down by the lean over the wrench, and the stance braces one foot back."""
    body = ks.turn(0, -WIRE_LEAN)
    joints["root"].rotation_quaternion = body
    rs.aim(joints["rh"], body, (0.16, -0.26, -1.0), twist=-12)
    rs.aim(joints["lh"], body, (-0.14, 0.2, -1.0), twist=8)
    rs.aim(joints["rs"], body, (0.0, 1.0, -0.05))
    rs.aim(joints["ls"], body, (0.0, 1.0, -0.05))
    joints["neck"].rotation_quaternion = body.inverted() @ ks.turn(0, -24)  # chin down, into the gap
    rs.stand_on_floor(joints)
    lens = point_on(joints, "neck", (0, 0.775, 4.5))
    ends = [point_on(joints, part, (e * 1.5, 0, 1.82)) for part, e in (("rs", 1), ("ls", -1))]
    down = min(lens.z - slot_middle(), -PLANTED)
    tip = Vector((lens.x - gap_across(lens.z - down), max(p.y for p in ends) + 0.18, down))  # the gap leans: its middle on the lens
    set_wrench(wrench(joints["m"], lit=True), Matrix.Translation(tip))
    m = joints["m"]
    ring = bl.place(bl.torus("Ring", RING, 0.18, 96, 6, m["Ghost"]), location=(0, tip.y, 0.06), scale=(1, 1, 0.35))
    ring["ghost"] = True
    ks.ghost(m, Vector((0, SHADE_AT, 0)))
    joints["wrench"] = ("wire", tip, lens)


POSES = {"square": pose_square, "stood": pose_stood, "leant": pose_leant, "wire": pose_wire}
VISOR = {"square": True, "stood": True, "leant": True, "wire": False}


# --- pictures -------------------------------------------------------------------------------------------------

GAME, FRONT = rs.GAME, ps.FRONT
PAPER, NIGHT, DAY, DUSK = rs.PAPER, rs.NIGHT, rs.DAY, ps.DUSK
RUN_PX = ks.PX  # pixels a stud in this run's renders; a draft halves it (ks.F64 follows, so the 64 px block holds)


def posed(scene, pose):
    if pose == "rook":
        joints = rs.build(scene, rs.CHOSEN)
        rs.POSES["idle"](joints)
        return joints
    joints = build(scene, visor_up=VISOR[pose], lit=pose == "wire")
    POSES[pose](joints)
    return joints


def takes(wanted, ghosted=()):
    """{(pose, view): picture} at PX a stud, cut to what's drawn, and what was measured, as kirra_sheet's takes. A
    pose "rook" is Rook standing, by his own builder. A view in `ghosted` has the grey pieces drawn faint behind."""
    out = {}
    for pose, views in wanted.items():
        scene = bl.reset_scene()
        joints = posed(scene, pose)
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
                out[pose, view] = rs.trim(ks.render(scene, view, azimuth, elevation, *close))
                continue
            shot = ks.render(scene, view, azimuth, elevation, centre, span, RUN_PX)
            if (pose, view) in ghosted:
                for o in ghosts:
                    o.hide_render = False
                for o in body:
                    o.hide_render = True
                shade = ks.faded(ks.render(scene, view, azimuth, elevation, centre, span, RUN_PX), 0.5)
                for o in body:
                    o.hide_render = False
                out[pose, view, "ghost"] = rs.trim(ks.over(shot, shade))
                out[pose, view, "ghost dark"] = rs.trim(ks.over(rs.black(shot), shade))
            out[pose, view] = rs.trim(shot)
        bp = [o.matrix_world @ v.co for o in body for v in o.data.vertices]
        out[pose, "size"] = tuple(round(max(q[i] for q in bp) - min(q[i] for q in bp), 2) for i in range(3))
        out[pose, "top"] = round(max(q.z for q in bp), 2)
        out[pose, "wrench"] = joints.get("wrench")
        out["tris", pose] = sum(len(f.vertices) - 2 for o in body for f in o.data.polygons)
    return out


def hue(code):
    r, g, b = (int(code[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hls(r, g, b)[0] * 360


def check():
    """Every pose built and measured, nothing rendered."""
    for pose in ("square", "stood", "leant", "wire", "rook"):
        scene = bl.reset_scene()
        joints = posed(scene, pose)
        bpy.context.view_layer.update()
        meshes = [o for o in scene.objects if o.type == "MESH" and not o.get("ghost")]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        tool = [o.matrix_world @ v.co for o in meshes if o.get("wrench") for v in o.data.vertices]
        size = tuple(round(max(q[i] for q in pts) - min(q[i] for q in pts), 2) for i in range(3))
        line = f"{pose}: {size} studs, top {max(q.z for q in pts):.2f}, low {min(q.z for q in pts):.2f}"
        if tool:
            line += f"; wrench from {min(q.z for q in tool):.2f} to {max(q.z for q in tool):.2f} high"
        print(line, joints.get("wrench") or "")
        if pose == "wire":
            _, bottom, top = head_outline()
            tip, lens = joints["wrench"][1], joints["wrench"][2]
            across = tip.x + gap_across(lens.z - tip.z)
            print(f"  the lens at {lens.z:.2f} high, the jaw's gap from {tip.z + bottom:.2f} to {tip.z + top:.2f}; "
                  f"the rod {-tip.z:.2f} into the street; the lens {tip.y - 0.18 - lens.y:.2f} behind the head's back face; "
                  f"across, the lens at {lens.x:.2f} and the gap's middle at {across:.2f}, {JAW_W / 2:.2f} each side")
        print(f"  tris {sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)}")
    print(f"Storm {hue(PALETTE['Storm']):.0f} deg of hue, Kirra's Sky {hue(SKY):.0f}: {abs(hue(PALETTE['Storm']) - hue(SKY)):.0f} apart")


def wanted_views():
    close = (Vector((0, -0.45, 4.45)), 3.9, 2 * RUN_PX)  # the head, the visor and the coils, at twice the scale
    return {"square": {"front": (180, 0), "back": (0, 0), "close front": (156, 6, *close), "close back": (24, 14, *close)},
            "stood": {"front": FRONT, "game": GAME, "flat": (180, 0)},
            "leant": {"front": FRONT, "game": GAME},
            "wire": {"met": (165, 6), "side": (90, 3), "game": GAME},
            "rook": {"front": FRONT, "game": GAME}}


def measures(s):
    """The numbers, printed: sizes, triangles, and each take's outline against Rook's at 64 px."""
    print(f"square {s['square', 'size']} studs, top {s['square', 'top']}; stood {s['stood', 'size']}; leant {s['leant', 'size']}, "
          f"{s['leant', 'wrench']}; wire {s['wire', 'size']}")
    print(f"tris: square {s['tris', 'square']}, wire {s['tris', 'wire']}")
    measured = {}
    for take in ("stood", "leant"):
        for view in ("game", "front"):
            watt, rook = ks.silhouette(s[take, view]), ks.silhouette(s["rook", view])
            measured[take, view] = ks.overlap(watt, rook)
            print(f"at 64 px, {take} {view}: Watt {watt.shape[1]}x{watt.shape[0]} px, cover {watt.mean():.2f}; "
                  f"Rook {rook.shape[1]}x{rook.shape[0]} px, cover {rook.mean():.2f}; overlap {measured[take, view]:.2f}")
    measured.update(baseline(s))
    apart = abs(hue(PALETTE["Storm"]) - hue(SKY))
    print(f"Storm and Kirra's Sky: {apart:.0f} degrees of hue apart")
    return measured, apart


def baseline(s):
    """Pip and Lyric, leads already drawn, against Rook by the same measure: how far two R6 leads part at 64 px, so
    Watt's number has a scale. Two broad R6 bodies share most of their pixels whatever they carry."""
    f = 64 / (5 * 100)  # their takes draw 1000 px over 10 studs: 100 px a stud, whatever this run's RUN_PX
    out = {}
    for name, mod in (("Pip", ps), ("Lyric", lys)):
        p = mod.takes({"idle": {view: (*angle, mod.MID) for view, angle in (("game", GAME), ("front", FRONT))}})
        for view in ("game", "front"):
            out[name, view] = ks.overlap(rs.shrink(rs.trim(p["idle", view]), f)[..., 3], ks.silhouette(s["rook", view]))
        print(f"at 64 px, {name} against Rook: game {out[name, 'game']:.2f}, front {out[name, 'front']:.2f}")
    return out


def draft():
    """The takes at half the pixels a stud, their numbers, and one plain strip of pictures, no text: to judge the look
    while memory is short. The 64 px measures hold, as the block shrinks to the same 64 px."""
    s = takes(wanted_views(), ghosted={("wire", "game")})
    measures(s)
    page = rs.canvas(2400, 1500, PAPER)
    labels = []
    ks.fit_row(page, labels, [(rs.black(s["stood", "flat"]), ""), (s["square", "front"], ""), (s["square", "back"], ""),
                              (s["stood", "front"], ""), (s["stood", "game"], ""), (s["leant", "front"], ""), (s["leant", "game"], ""),
                              (s["rook", "game"], "")], 30, 2370, 560, 520, PAPER, gap=30)
    ks.fit_row(page, labels, [(s["square", "close front"], ""), (s["square", "close back"], ""), (s["wire", "met"], ""),
                              (s["wire", "side"], ""), (s["wire", "game", "ghost"], "")], 30, 1700, 1180, 560, PAPER, gap=30)
    keys = [("stood", "game"), ("stood", "front"), ("leant", "game"), ("leant", "front"), ("wire", "game"), ("wire", "met"),
            ("rook", "game"), ("rook", "front")]
    x, y = 1740, 640
    for row, ground in enumerate((NIGHT, DUSK, DAY)):
        rs.fill(page, x, y + row * 96, 640, 92, ground)
        cx = x + 8
        for key in keys:
            q = rs.shrink(rs.trim(s[key]), ks.F64)
            rs.stand(page, q, cx, y + row * 96 + 88, q.shape[1])
            cx += q.shape[1] + 12
    rs.save(page, OUT / "watt_draft.png")


def sheet(small):
    s = takes(wanted_views(), ghosted={("wire", "side"), ("wire", "game")})
    measured, apart = measures(s)

    W, H = 1920, 1920
    page = rs.canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 64, "WATT", ink),
            (250, 36, 24, "Common / Endurance / Tank / Storm. A mechanic: the guaranteed second Voidkin, and the first worker.", ink),
            (250, 70, 20, "One idea: a man and his tool, wired in one line, from the generator on his back to the wrench to the street.", soft)]

    # row A: who he is, and take A
    ks.fit_row(page, text, [(rs.black(s["stood", "flat"]), "outline"), (s["square", "front"], "front, on R6"),
                            (s["square", "back"], "back"), (s["stood", "front"], "A, stood: how he stands"),
                            (s["stood", "game"], "A, the player's camera")], 30, 1890, 410, 300, soft, gap=40)
    rs.fill(page, 30, 412, 1860, 2, rs.rgb("#BDB8AE"))

    # row A2: up close, take B, and what each piece is
    ks.fit_row(page, text, [(s["square", "close front"], "up close, front"), (s["square", "close back"], "and back"),
                            (s["leant", "front"], "B, leant"), (s["leant", "game"], "B, the player's camera")],
               30, 1300, 860, 400, soft, gap=36)
    length = max(p[1] for p in head_outline()[0])  # the rod's tip to the longer jaw's
    notes = [f"The wrench: its head {HEAD_W} studs across, wider than his chest,",
             f"{length:.2f} end to end, the jaw leaning {JAW_TILT:.0f} degrees, a spanner's.",
             "A copper ground rod ends the handle: he plants it, and",
             "the head stands up as his shield. The generator: a steel",
             "housing, the back's light mass. Two copper coils on posts",
             "over his shoulders, capped in Storm: where an effect starts.",
             "No cable: the coils arc to the wrench in Ground Wire.",
             "A welding visor on a cream band, up at rest. In a fight",
             "it comes down, its lens lit Storm. One hinge.",
             "The coverall's top half pulled down, its sleeves knotted",
             "at his left hip. Rubber gloves, thick boots, steel toes:",
             "Insulated is in the clothes."]
    text += [(1330, 470 + i * 30, 17, line, soft) for i, line in enumerate(notes)]
    text += [(1330, 470 + len(notes) * 30 + 16, 17, f"Against Rook at 64 px: A {measured['stood', 'game']:.2f} from the camera, "
                                                    f"{measured['stood', 'front']:.2f} front;", ink),
             (1330, 470 + len(notes) * 30 + 44, 17, f"B {measured['leant', 'game']:.2f} and {measured['leant', 'front']:.2f} "
                                                    "(1 is the same outline).", ink),
             (1330, 470 + len(notes) * 30 + 72, 17, f"For scale: Pip {measured['Pip', 'game']:.2f} and {measured['Pip', 'front']:.2f}, "
                                                    f"Lyric {measured['Lyric', 'game']:.2f} and {measured['Lyric', 'front']:.2f}.", soft)]
    rs.fill(page, 30, 862, 1860, 2, rs.rgb("#BDB8AE"))

    # row B: Ground Wire's key pose
    text += [(40, 910, 30, "GROUND WIRE, the hold", ink),
             (40, 952, 18, "The wrench driven in rod first, its head a wall at his chest; hunched behind it, one foot braced back, both hands "
                           "on the head's edges, the visor down, its lit lens through the jaw's gap.", soft),
             (40, 976, 18, f"In grey: one Shade {SHADE_AT:.0f} studs ahead, and the ring at {RING} studs round the rod, a sheet number until "
                           "Ground Wire's reach is data.", soft)]
    ks.fit_row(page, text, [(s["wire", "met"], "from the Shades' side"),
                            (s["wire", "side", "ghost dark"], "side on, the Shade and the ring in grey"),
                            (s["wire", "game", "ghost"], "the player's camera")], 30, 1890, 1370, 360, soft, gap=40)
    rs.fill(page, 30, 1372, 1860, 2, rs.rgb("#BDB8AE"))

    # row C: the chips, Storm beside Kirra's Sky, the block at 64 px beside Rook, the values
    x, y = 40, 1420
    for i, (name, role) in enumerate(CHIPS):
        yy = y + i * 104
        rs.fill(page, x, yy, 88, 88, rs.rgb(PALETTE[name]))
        text += [(x + 100, yy + 8, 22, name, ink), (x + 100, yy + 38, 16, PALETTE[name], soft), (x + 100, yy + 60, 16, role, soft)]
    for i, name in enumerate(NEUTRALS):
        rs.fill(page, x + 320 + (i % 2) * 120, y + (i // 2) * 84, 52, 52, rs.rgb(PALETTE[name]))
        text.append((x + 320 + (i % 2) * 120, y + (i // 2) * 84 + 58, 12, name, soft))
    for i, (code, label) in enumerate(((PALETTE["Storm"], "Storm"), (SKY, "Kirra's Sky"))):
        rs.fill(page, x + 320 + i * 60, y + 172, 56, 56, rs.rgb(code))
    text += [(x + 320, y + 234, 12, f"Storm, Kirra's Sky: {apart:.0f} deg apart", soft),
             (x + 320, y + 262, 16, "Reads, in order:", ink), (x + 320, y + 286, 16, "1 the wrench, a shield at his side", soft),
             (x + 320, y + 308, 16, "2 two coils over his shoulders", soft), (x + 320, y + 330, 16, "3 orange under a steel pack", soft)]

    x0, y0 = 620, 1410
    keys = [("stood", "game"), ("stood", "front"), ("leant", "game"), ("leant", "front"), ("wire", "game"), ("wire", "met"),
            ("rook", "game"), ("rook", "front")]
    small_shots = [rs.shrink(rs.trim(s[key]), ks.F64) for key in keys]
    widths = [q.shape[1] + 10 for q in small_shots]
    widths[5] += 26  # a gap before Rook
    text += [(x0, y0, 19, "at 64 px over dark, Lantern Row's dusk, noon, and in black", soft),
             (x0 + 8, y0 + 26, 15, "Watt: A, B, Ground Wire", ink), (x0 + 8 + sum(widths[:6]), y0 + 26, 15, "Rook, beside him", ink)]
    for row, (ground, black) in enumerate(((NIGHT, False), (DUSK, False), (DAY, False), (PAPER, True))):
        yy = y0 + 48 + row * 96
        rs.fill(page, x0, yy, sum(widths) + 8, 92, ground)
        cx = x0 + 8
        for q, w in zip(small_shots, widths):
            rs.stand(page, rs.black(q) if black else q, cx, yy + 88, q.shape[1])
            cx += w
    vx = x0 + sum(widths) + 44
    text.append((vx, y0, 19, "values", soft))
    for c, key in enumerate((("stood", "front"), ("stood", "game"), ("wire", "met"))):
        shot = rs.grey(rs.shrink(rs.trim(s[key]), 0.2))
        rs.stand(page, shot, vx + c * 130, y0 + 300, shot.shape[1])

    sizes = s["square", "size"]
    text.append((40, H - 40, 15, f"Blockout on R6 at the player's height: 5 studs to the crown, {s['square', 'top']} to the visor's top at rest, "
                 f"{sizes[0]} across with the wrench beside him. The wrench is a prop of its own; on the model it rides his hand. "
                 f"Views are orthographic.", soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "watt_sheet.png")
    if small:
        rs.save(rs.shrink(page, 0.5), OUT / "watt_sheet_small.png")


if __name__ == "__main__":
    OUT = rs.OUT = ks.OUT = ps.OUT = lys.OUT = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "check" in args:
        check()
    elif "draft" in args:
        RUN_PX = ks.PX // 2
        ks.F64 = 64 / (5 * RUN_PX)
        draft()
    else:
        sheet("small" in args)
