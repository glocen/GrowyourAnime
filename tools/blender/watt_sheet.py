"""Watt, take A, the quiet wall, in colour (AR11: the director's pick, 2026-11-15, "def A, but looks at vanguard units
then compare", then "it need colors too"). The grey take is built again the way the comparison in AR11 says:

    the body is R6's own size, and the coat is painted on it: flat shapes laid on the blocks' faces, in our own cel
       tones and ink line; only the collar and the rolled cuffs are built;
    the hair is sculpted: curved tapering locks swept back, half again as wide as his head, with a fringe, the lifted
       ends in Storm's pale pink;
    the face is painted on the head: half-lidded eyes with irises, drawn lids and brows; the collar stops at his jaw;
    three values at 64 px: a deep petrol coat, a pale shirt and forearms, stone trousers between;
    the spear is thin, taller than he is, and slung with its head clear of his own from every heading.

The sheet: four views, the face close, the grey take beside it, and both at 64 px over noon and night beside the leads
before him. Workbench only, so no GPU turn. Studs, X his right, Y forward, Z up; every piece hangs from one of R6's six
parts at the engine's own pivots, as rook_sheet.py's do.

    blender.exe -b --factory-startup --python tools/blender/watt_sheet.py -- <out_dir> [new] [old] [Rook] [Kirra] [Pip] [Lyric] [sheet]

With no stage named, all run; a stage alone reads the others' pictures from <out_dir>. Writes watt_colour.png.
"""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import lyric_sheet as lys  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402

PALETTE = {
    "Ink": "#141821",
    "Coat": "#1F4954", "CoatShade": "#15323B", "CoatLight": "#2F6672",
    "Storm": "#FFB3E8", "StormShade": "#EC93D0", "StormDeep": "#C85FA9",
    "Shirt": "#EFE9DE", "ShirtShade": "#CBC2B5",
    "Trouser": "#B4AEA2", "TrouserShade": "#8E887E",
    "Boot": "#252932", "Sole": "#DAD4C8",
    "Leather": "#A9683A", "LeatherShade": "#7C4826",
    "Skin": "#F3CFB1", "SkinShade": "#DDAB8B",
    "Hair": "#232738", "HairLight": "#4A5478",
    "Iron": "#262A32", "Ceramic": "#F5F2EB", "Steel": "#C9D2DC", "White": "#FFFFFF",
}
CHIPS = (("Coat", "the coat"), ("Storm", "its lining, the hair's ends, his eyes"), ("Shirt", "shirt, wrap, ceramic"),
         ("Trouser", "trousers"), ("Leather", "strap, belt"), ("Hair", "hair"), ("Skin", "skin"))
PIVOTS = rs.PIVOTS
slab, loft, spike = rs.slab, rs.loft, ks.spike
on, rod = wt.on, wt.rod
R = wt.R  # the head's radius
HEAD = Vector((0, 0, 4.5))
LIFT = 0.006  # how far a painted shape stands off its block, a layer
LIGHT = Vector((-0.45, 0.35, 0.82)).normalized()  # where a lock's lit side faces: over his left brow
GAME, FRONT = rs.GAME, ps.FRONT
PAPER, NIGHT, DAY = rs.PAPER, rs.NIGHT, rs.DAY
PX = ks.PX
CLOSE = (Vector((0, 0, 4.72)), 2.6, 2 * PX)


def materials():
    made = {}
    for name, code in PALETTE.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(code)
        m.roughness = 1.0
        made[name] = m
    return made


# --- painting on a block ---------------------------------------------------------------------------------------------

def front(y=0.5):
    """A block's front face: shapes are given in (x, z)."""
    return (Vector((0, y, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0)))


def back(y=-0.5):
    return (Vector((0, y, 0)), Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, -1, 0)))


def side(x):
    """A block's outer face at x: shapes are given in (y, z)."""
    return (Vector((x, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)), Vector((math.copysign(1, x), 0, 0)))


def paint(name, plane, pts, material, layer=1):
    """A painted shape: flat on one face of a block, lifted a hair so it draws over what's under it."""
    origin, u, v, n = plane
    bm = bmesh.new()
    verts = [bm.verts.new(origin + u * a + v * b + n * (LIFT * layer)) for a, b in pts]
    for tri in tessellate_polygon([[Vector((a, b, 0.0)) for a, b in pts]]):
        f = bm.faces.new([verts[i] for i in tri])
        f.normal_update()
        if f.normal.dot(n) < 0:
            f.normal_flip()
    return bl.object_from_bmesh(name, bm, material)


def on_head(name, pts, material, layer=1, cuts=2):
    """A shape painted on his face. Points are (s, z): s runs along the head's surface from the middle of his face
    toward his right."""
    bm = bmesh.new()
    verts = [bm.verts.new((a, b, 0.0)) for a, b in pts]
    for tri in tessellate_polygon([[Vector((a, b, 0.0)) for a, b in pts]]):
        bm.faces.new([verts[i] for i in tri])
    if cuts:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    r = R + LIFT * layer
    for v in bm.verts:
        s, z = v.co.x, v.co.y
        v.co = (r * math.sin(s / R), r * math.cos(s / R), z)
    for f in bm.faces:
        f.normal_update()
        c = f.calc_center_median()
        if f.normal.dot(Vector((c.x, c.y, 0))) < 0:
            f.normal_flip()
    return bl.object_from_bmesh(name, bm, material)


def mirror(pts):
    return [(-a, b) for a, b in reversed(pts)]


def disc(cx, cz, r, n=10):
    return [(cx + r * math.cos(2 * math.pi * i / n), cz + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def band(a, b, width):
    """A straight band from a to b on a face."""
    (ax, az), (bx, bz) = a, b
    length = math.hypot(bx - ax, bz - az)
    nx, nz = -(bz - az) / length * width / 2, (bx - ax) / length * width / 2
    return [(ax + nx, az + nz), (bx + nx, bz + nz), (bx - nx, bz - nz), (ax - nx, az - nz)]


def fuse(base, *others):
    """Joins shapes into one object, so no outline is drawn between them: a tone inside a colour, not a patch on it."""
    others = [o for o in others if o is not None]
    if not others:
        return base
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in (base, *others):
        o.select_set(True)
    bpy.context.view_layer.objects.active = base
    bpy.ops.object.join()
    return base


# --- the hair --------------------------------------------------------------------------------------------------------

def lock(name, root, c1, c2, tip, width, thick, m, pink=0.0, seg=9):
    """A lock of hair: a flat blade with a ridge, drawn along a curve from root past c1 and c2 to a point at tip,
    lying on the head where it starts. `pink`: the share of its length, from the tip, in Storm."""
    root, c1, c2, tip = Vector(root), Vector(c1), Vector(c2), Vector(tip)
    bm = bmesh.new()
    rings, where = [], {}
    for i in range(seg):
        t = i / seg
        s = 1 - t
        p = root * s ** 3 + c1 * (3 * s * s * t) + c2 * (3 * s * t * t) + tip * t ** 3
        tan = ((c1 - root) * (s * s) + (c2 - c1) * (2 * s * t) + (tip - c2) * (t * t)).normalized()
        out = p - HEAD
        out -= tan * out.dot(tan)
        out = out.normalized() if out.length > 1e-4 else Vector((0, 0, 1))
        across = tan.cross(out).normalized()
        w = width / 2 * (0.75 + 0.25 * min(1.0, t / 0.2)) * (1 - max(0.0, (t - 0.2) / 0.8) ** 1.35)
        th = thick * (1 - 0.6 * t)
        rings.append([bm.verts.new(p - across * w), bm.verts.new(p + out * th + across * w * 0.2), bm.verts.new(p + across * w),
                      bm.verts.new(p - out * th * 0.3)])
    point = bm.verts.new(tip)
    bm.faces.new(list(reversed(rings[0])))
    for i, (a, b) in enumerate(zip(rings, rings[1:])):
        for k in range(4):
            where[bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))] = (i, k)
    for k in range(4):
        where[bm.faces.new((rings[-1][k], rings[-1][(k + 1) % 4], point))] = (seg - 1, k)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    first_pink = round(seg * (1 - pink))
    for f, (i, k) in where.items():
        if pink and i >= first_pink:
            f.material_index = 1
        elif k in (0, 1) and f.normal.dot(LIGHT) > 0.45:
            f.material_index = 2
    obj = bl.object_from_bmesh(name, bm, m["Hair"])
    obj.data.materials.append(m["Storm"])
    obj.data.materials.append(m["HairLight"])
    return obj


def smooth(obj):
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def hair(m):
    def hairline(t):  # high over his brow, long at the nape
        return 4.64 + 0.26 * max(0.0, math.sin(t)) ** 1.5 - 0.3 * max(0.0, -math.sin(t))

    made = [smooth(loft("HairCap", [(hairline, 0, -0.02, 1.33, 1.33), (5.0, 0, -0.04, 1.38, 1.38), (5.15, 0, -0.06, 1.2, 1.2),
                                    (5.2, 0, -0.08, 0.7, 0.7)], m["Hair"], n=2))]
    # the sweep: up off his brow in a wave, back over the crown. The static lifts the middle ends: they flick up behind
    # the crown in a row, so the game's camera, behind him, sees pink points standing and not ends pointing at it
    for x, lift in ((-0.62, 0.1), (-0.42, 0.34), (-0.2, 0.56), (0.02, 0.42), (0.22, 0.64), (0.42, 0.3), (0.62, 0.1)):
        made.append(lock("Sweep", (x * 0.9, 0.52 - 0.28 * abs(x), 4.92), (x * 1.1, 0.64 - 0.3 * abs(x), 5.55 - 0.12 * abs(x) + 0.14 * lift),
                         (x * 1.35, -0.6, 5.5 + 0.1 * lift), (x * 1.5, -0.86 - 0.1 * lift, 5.3 + 1.15 * lift), 0.54, 0.075, m,
                         pink=0.32 if lift > 0.25 else 0.0))
    for x, drop in ((-0.5, 0.0), (-0.25, 0.12), (0.04, 0.04), (0.3, 0.14), (0.52, 0.0)):  # behind the crown, lying down his head
        made.append(lock("Crown", (x, -0.15, 5.1), (x * 1.1, -0.5, 5.32), (x * 1.3, -0.98, 5.12), (x * 1.42, -1.14, 4.78 - drop),
                         0.5, 0.07, m))
    for e in (1, -1):  # over his ears, back, the ends turned out
        made.append(lock("Side", (e * 0.6, 0.3, 4.8), (e * 0.82, 0.1, 4.96), (e * 0.9, -0.45, 4.86), (e * 1.08, -0.9, 5.14),
                         0.46, 0.07, m, pink=0.22))
        made.append(lock("SideLow", (e * 0.62, 0.05, 4.63), (e * 0.8, -0.15, 4.67), (e * 0.84, -0.55, 4.58), (e * 0.84, -0.95, 4.76),
                         0.38, 0.06, m))
        made.append(lock("Burn", (e * 0.58, 0.3, 4.86), (e * 0.68, 0.36, 4.72), (e * 0.67, 0.37, 4.56), (e * 0.62, 0.38, 4.42),
                         0.2, 0.05, m, seg=6))
    for x in (-0.38, 0.0, 0.38):  # the nape, over the collar
        made.append(lock("Nape", (x, -0.55, 4.62), (x * 1.1, -0.75, 4.57), (x * 1.3, -0.92, 4.55), (x * 1.5, -1.05, 4.7),
                         0.36, 0.06, m, seg=6))
    # the fringe, parted over his right brow: one long lock down the bridge of his nose
    for pts, w in ((((0.12, 0.52, 4.98), (-0.02, 0.74, 4.96), (-0.1, 0.74, 4.76), (-0.05, 0.66, 4.5)), 0.3),
                   (((-0.24, 0.5, 4.97), (-0.38, 0.68, 4.95), (-0.48, 0.68, 4.82), (-0.5, 0.6, 4.66)), 0.28),
                   (((0.36, 0.46, 4.97), (0.48, 0.62, 4.95), (0.56, 0.62, 4.86), (0.6, 0.54, 4.72)), 0.26),
                   (((0.2, 0.5, 4.98), (0.28, 0.7, 4.95), (0.33, 0.7, 4.86), (0.3, 0.64, 4.76)), 0.2)):
        made.append(lock("Fringe", *pts, w, 0.06, m, seg=7))
    return made


# --- the face --------------------------------------------------------------------------------------------------------

EYE = (0.285, 4.5)  # an eye's middle: along the head's surface from the middle of his face, and its height
WHITE = [(-0.13, -0.005), (-0.08, 0.035), (0.0, 0.045), (0.08, 0.042), (0.14, 0.02), (0.1, -0.04), (0.02, -0.06), (-0.07, -0.045)]
LID = [(-0.145, -0.012), (-0.085, 0.038), (0.0, 0.05), (0.085, 0.046), (0.15, 0.02), (0.205, 0.045), (0.15, 0.064), (0.085, 0.086),
       (0.0, 0.09), (-0.09, 0.07)]
UNDER = [(0.03, -0.062), (0.1, -0.042), (0.142, 0.012), (0.118, -0.05), (0.03, -0.076)]
EYE_SIZE = 1.16
BROW = [(-0.14, 0.13), (0.0, 0.162), (0.17, 0.158), (0.175, 0.178), (0.0, 0.196), (-0.14, 0.158)]


def face(m):
    """His face, painted: the outer end of each shape is the one away from his nose."""
    def eye(e, pts):
        s0, z0 = EYE
        shape = [(e * (s0 + a * EYE_SIZE), z0 + b * EYE_SIZE) for a, b in pts]
        return shape if e > 0 else list(reversed(shape))

    def round_(e, a, b, r, low=-0.058, high=0.045, n=14):
        return eye(e, [(a + r * math.cos(2 * math.pi * i / n), min(high, max(low, b + r * math.sin(2 * math.pi * i / n))))
                       for i in range(n)])

    soft, hard = [], []
    for e in (1, -1):
        hard.append(fuse(on_head("EyeWhite", eye(e, WHITE), m["Shirt"], 1),
                         on_head("Iris", round_(e, 0.0, -0.008, 0.074), m["StormDeep"], 2),
                         on_head("IrisLow", round_(e, 0.0, -0.034, 0.046), m["Storm"], 3),
                         on_head("Pupil", round_(e, 0.0, -0.006, 0.03), m["Ink"], 4),
                         on_head("Glint", round_(e, -0.032 * e, 0.018, 0.018, n=8), m["White"], 5, cuts=0)))
        hard.append(on_head("Lid", eye(e, LID), m["Ink"], 6))
        hard.append(on_head("Under", eye(e, UNDER), m["Ink"], 6, cuts=1))
        hard.append(on_head("Brow", eye(e, BROW), m["Ink"], 2))
    # the fringe's shadow on his brow, and his nose
    top = [(-0.8 + 0.2 * i, 5.0) for i in range(9)]
    low = [(0.8, 4.8), (0.62, 4.86), (0.45, 4.76), (0.3, 4.85), (0.12, 4.74), (-0.05, 4.84), (-0.22, 4.75), (-0.42, 4.86),
           (-0.6, 4.78), (-0.8, 4.84)]
    soft.append(on_head("BrowShade", top + low, m["SkinShade"], 1, cuts=1))
    soft.append(on_head("Nose", [(0.012, 4.38), (0.058, 4.3), (-0.004, 4.306)], m["SkinShade"], 1, cuts=0))
    hard.append(on_head("Mouth", [(-0.055, 4.172), (0.0, 4.166), (0.06, 4.176), (0.0, 4.182)], m["Ink"], 2, cuts=1))
    return soft, hard


# --- the build -------------------------------------------------------------------------------------------------------

def collar_top(t):
    """At his jaw, open in front in the coat's own notch, so his nose and mouth show; higher behind."""
    s = math.sin(t)
    return 4.33 - 0.05 * s - 0.24 * max(0.0, s) ** 10


def build(scene):
    m, j = materials(), wt.rig(scene)
    f, b = front(), back()

    # the torso: the coat, open over a pale shirt, its edges turned to show the lining
    torso = slab("Torso", (0, 0, 3), (2, 1, 2), m["Coat"])
    tones = []
    for pts in ([(0.72, 3.3), (0.8, 2.0), (1.0, 2.0), (1.0, 3.9)], [(0.5, 2.0), (0.62, 2.0), (0.74, 2.95)],
                [(0.3, 2.0), (0.38, 2.0), (0.42, 2.6)]):
        tones += [paint("Shade", f, pts, m["CoatShade"]), paint("Shade", f, mirror(pts), m["CoatShade"])]
    lit = [(0.24, 4.0), (1.0, 4.0), (1.0, 3.64), (0.3, 3.84)]
    tones += [paint("Lit", f, lit, m["CoatLight"]), paint("Lit", f, mirror(lit), m["CoatLight"])]
    tones += [paint("Yoke", b, [(-1, 4.0), (1, 4.0), (1, 3.62), (0, 3.48), (-1, 3.62)], m["CoatLight"]),
              paint("Seam", b, [(-0.014, 3.48), (0.014, 3.48), (0.014, 2.0), (-0.014, 2.0)], m["Ink"], 2)]
    for pts in ([(0.74, 3.2), (0.82, 2.0), (1.0, 2.0), (1.0, 3.5)], [(0.2, 2.0), (0.3, 2.0), (0.36, 2.7)]):
        tones += [paint("Shade", b, pts, m["CoatShade"]), paint("Shade", b, mirror(pts), m["CoatShade"])]
    fuse(torso, *tones)

    shirt = fuse(paint("Shirt", f, [(-0.13, 4.0), (0.13, 4.0), (0.2, 2.22), (-0.2, 2.22)], m["Shirt"], 2),
                 paint("ShirtShade", f, [(-0.13, 4.0), (0.13, 4.0), (0.14, 3.7), (0.0, 3.56), (-0.14, 3.7)], m["ShirtShade"], 3),
                 paint("ShirtFold", f, [(0.06, 2.9), (0.19, 2.3), (0.15, 2.22), (0.02, 2.22)], m["ShirtShade"], 3))
    edge = [(0.13, 4.0), (0.2, 4.0), (0.27, 2.0), (0.2, 2.0)]
    belt = fuse(paint("Belt", f, [(-0.2, 2.0), (0.2, 2.0), (0.2, 2.22), (-0.2, 2.22)], m["Leather"], 3),
                paint("BeltShade", f, [(-0.2, 2.0), (0.2, 2.0), (0.2, 2.06), (-0.2, 2.06)], m["LeatherShade"], 4))
    toggles = [paint("Toggle", f, disc(x, z, 0.062), m["Ceramic"], 3) for x, z in ((0.47, 3.45), (0.49, 3.0), (0.51, 2.55))]
    loops = [paint("Loop", f, band((-0.5, z), (-0.3, z), 0.035), m["Ink"], 3) for z in (3.45, 3.0, 2.55)]
    strap = [fuse(paint("Strap", face_, band((0.96, 4.0), (-1.0, 2.5), 0.2), m["Leather"], 5),
                  paint("StrapShade", face_, band((0.99, 3.94), (-0.97, 2.44), 0.06), m["LeatherShade"], 6))
             for face_ in (f, b)]
    buckle = fuse(paint("Buckle", f, band((0.42, 3.59), (0.22, 3.435), 0.26), m["Ceramic"], 7),
                  paint("BuckleBar", f, band((0.36, 3.545), (0.28, 3.48), 0.3), m["Iron"], 8))
    collar = [smooth(loft("Collar", [(3.96, 0, 0, 1.52, 1.46), (collar_top, 0, 0, 1.66, 1.6)], m["Coat"], n=2.5, caps=False)),
              loft("CollarLining", [(collar_top, 0, 0, 1.66, 1.6), (collar_top, 0, 0, 1.56, 1.5), (3.96, 0, 0, 1.44, 1.38)],
                   m["Storm"], n=2.5, caps=False)]
    on(j, "root", torso, shirt, paint("Lining", f, edge, m["Storm"], 4), paint("Lining", f, mirror(edge), m["Storm"], 4), belt,
       paint("BeltBuckle", f, [(-0.075, 2.04), (0.075, 2.04), (0.075, 2.19), (-0.075, 2.19)], m["Ceramic"], 5),
       *toggles, *loops, *strap, buckle, *collar)

    # the arms: the coat's sleeve rolled to the elbow, its lining turned out; bare forearms
    for part, e in (("rs", 1), ("ls", -1)):
        def x(pts, e=e):
            return pts if e > 0 else mirror(pts)

        sleeve = slab("Sleeve", (e * 1.5, 0, 3.5), (1, 1, 1), m["Coat"])
        fuse(sleeve,
             paint("Lit", f, x([(1.2, 4.0), (2.0, 4.0), (2.0, 3.72), (1.3, 3.86)]), m["CoatLight"]),
             paint("Shade", f, x([(1.0, 4.0), (1.14, 4.0), (1.1, 3.0), (1.0, 3.0)]), m["CoatShade"]),
             paint("Fold", f, x([(1.3, 3.0), (1.84, 3.0), (1.64, 3.26)]), m["CoatShade"]),
             paint("Lit", b, x([(1.2, 4.0), (2.0, 4.0), (2.0, 3.74), (1.3, 3.88)]), m["CoatLight"]),
             paint("Fold", b, x([(1.2, 3.0), (1.74, 3.0), (1.4, 3.3)]), m["CoatShade"]),
             paint("Fold", side(e * 2.0), [(-0.3, 3.0), (0.32, 3.0), (0.1, 3.34)], m["CoatShade"]),
             paint("Lit", side(e * 2.0), [(-0.5, 4.0), (0.5, 4.0), (0.5, 3.78), (-0.5, 3.7)], m["CoatLight"]))
        cuff = fuse(slab("Cuff", (e * 1.5, 0, 3.0), (1.1, 1.1, 0.19), m["Storm"]),
                    slab("CuffShade", (e * 1.5, 0, 2.93), (1.104, 1.104, 0.05), m["StormShade"]))
        arm = slab("Forearm", (e * 1.5, 0, 2.44), (1, 1, 0.88), m["Skin"])
        fuse(arm, paint("Shade", f, x([(1.0, 2.88), (1.2, 2.88), (1.12, 2.0), (1.0, 2.0)]), m["SkinShade"]),
             paint("Shade", b, x([(1.0, 2.88), (1.24, 2.88), (1.14, 2.0), (1.0, 2.0)]), m["SkinShade"]),
             paint("CuffShadow", f, x([(1.0, 2.88), (2.0, 2.88), (2.0, 2.8), (1.0, 2.76)]), m["SkinShade"], 2))
        pieces = [sleeve, cuff, arm]
        if e < 0:  # his left forearm wrapped in pale tape
            pieces.append(fuse(slab("Wrap", (e * 1.5, 0, 2.42), (1.04, 1.04, 0.52), m["Shirt"]),
                               *[slab("WrapLine", (e * 1.5, 0, z), (1.044, 1.044, 0.02), m["ShirtShade"]) for z in (2.3, 2.42, 2.54)]))
        else:
            pieces.append(slab("Band", (e * 1.5, 0, 2.2), (1.04, 1.04, 0.1), m["Iron"]))
        on(j, part, *pieces)

    # the legs: the coat's skirt is painted on them, open in front over the trousers, vented behind
    for part, e in (("rh", 1), ("lh", -1)):
        def x(pts, e=e):
            return pts if e > 0 else mirror(pts)

        skirt = slab("Skirt", (e * 0.5, 0, 1.425), (1, 1, 1.15), m["Coat"])
        fuse(skirt,
             paint("Shade", f, x([(0.84, 2.0), (1.0, 2.0), (1.0, 0.85), (0.9, 0.85)]), m["CoatShade"]),
             paint("Fold", f, x([(0.56, 2.0), (0.66, 2.0), (0.76, 0.85), (0.7, 0.85)]), m["CoatShade"]),
             paint("Hem", f, x([(0.48, 0.85), (1.0, 0.85), (1.0, 0.93), (0.465, 0.93)]), m["CoatLight"], 2),
             paint("Shade", b, x([(0.8, 2.0), (1.0, 2.0), (1.0, 0.85), (0.88, 0.85)]), m["CoatShade"]),
             paint("Fold", b, x([(0.4, 2.0), (0.5, 2.0), (0.56, 0.85), (0.5, 0.85)]), m["CoatShade"]),
             paint("Hem", b, x([(0.16, 0.85), (1.0, 0.85), (1.0, 0.93), (0.14, 0.93)]), m["CoatLight"], 2),
             paint("Hem", side(e * 1.0), [(-0.5, 0.85), (0.5, 0.85), (0.5, 0.93), (-0.5, 0.93)], m["CoatLight"], 2),
             paint("Fold", side(e * 1.0), [(-0.1, 2.0), (0.06, 2.0), (0.16, 0.93), (0.06, 0.93)], m["CoatShade"]))
        trouser = fuse(paint("Trouser", f, x([(0.0, 2.0), (0.2, 2.0), (0.42, 0.85), (0.0, 0.85)]), m["Trouser"], 2),
                       paint("TrouserShade", f, x([(0.0, 2.0), (0.06, 2.0), (0.1, 0.85), (0.0, 0.85)]), m["TrouserShade"], 3))
        shin = slab("Shin", (e * 0.5, 0, 0.675), (1, 1, 0.35), m["Trouser"])
        fuse(shin, paint("Shade", f, x([(0.0, 0.85), (1.0, 0.85), (1.0, 0.77), (0.0, 0.8)]), m["TrouserShade"]),
             paint("Shade", b, x([(0.0, 0.85), (1.0, 0.85), (1.0, 0.77), (0.0, 0.8)]), m["TrouserShade"]),
             paint("Shade", side(e * 1.0), [(-0.5, 0.85), (0.5, 0.85), (0.5, 0.77), (-0.5, 0.77)], m["TrouserShade"]))
        on(j, part, skirt, trouser, shin,
           paint("Lining", f, x([(0.2, 2.0), (0.27, 2.0), (0.49, 0.85), (0.42, 0.85)]), m["Storm"], 3),
           paint("Vent", b, x([(0.0, 1.5), (0.16, 0.85), (0.0, 0.85)]), m["Storm"], 2),
           slab("Boot", (e * 0.5, 0.06, 0.3), (1.0, 1.12, 0.44), m["Boot"]),
           slab("BootCuff", (e * 0.5, 0.02, 0.49), (1.04, 1.08, 0.07), m["Iron"]),
           slab("Sole", (e * 0.5, 0.06, 0.04), (1.02, 1.16, 0.08), m["Sole"]))

    # the head: a painted face under sculpted hair
    head = smooth(loft("Head", [(3.875, 0, 0, 0.95, 0.95), (3.92, 0, 0, 1.14, 1.14), (4.02, 0, 0, 1.25, 1.25), (4.98, 0, 0, 1.25, 1.25),
                         (5.08, 0, 0, 1.14, 1.14), (5.125, 0, 0, 0.95, 0.95)], m["Skin"], n=2))
    soft, hard = face(m)
    on(j, "neck", fuse(head, *soft), *hard, *hair(m))

    # the spear-staff, taller than he is, slung from behind his left calf to over his right shoulder and leaning back:
    # its discs and blade stand above his hair and outside it, with ground between from every heading (the content check)
    a, top = Vector((-0.6, -0.68, 0.7)), Vector((2.7, -1.3, 7.6))
    u, length = (top - a).normalized(), (top - a).length
    lean = math.degrees(math.atan2(u.x, u.z))
    on(j, "root",
       rod("Shaft", a, a + u * (length - 0.62), 0.055, m["Iron"]),
       *[bl.place(bl.cylinder("Disc", 0.24, 0.06, 16, m["Ceramic"]), location=a + u * (length - s), rotation=(0, lean, 0))
         for s in (0.84, 1.07, 1.3)],
       spike("Blade", a + u * (length - 0.64), top + u * 0.12, 0.105, m["Steel"]),
       rod("Butt", a - u * 0.1, a + u * 0.12, 0.085, m["Leather"]))
    return j


# --- the sheet -------------------------------------------------------------------------------------------------------

def figure(build_it, views):
    """{view: picture} at PX a stud for one build, its size, its highest point and its triangles."""
    scene = bl.reset_scene()
    joints = build_it(scene)
    rs.stand_on_floor(joints)
    bpy.context.view_layer.update()
    meshes = [o for o in scene.objects if o.type == "MESH"]
    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    low, high = Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)])
    centre, span = (low + high) / 2, (high - low).length * 1.02
    out = {}
    for view, at in views.items():
        if view == "face":
            out[view] = rs.trim(ks.render(scene, view, *at, *CLOSE))
        else:
            out[view] = rs.trim(ks.render(scene, view, *at, centre, span, PX))
    out["size"] = tuple(round(high[i] - low[i], 2) for i in range(3))
    out["top"] = round(high.z, 2)
    out["tris"] = sum(len(f.vertices) - 2 for o in meshes for f in o.data.polygons)
    return out


NEW = {"front": (180, 4), "three": FRONT, "side": (96, 6), "game": GAME, "flat": (180, 0), "face": (168, 4)}
OLD = {"three": FRONT, "game": GAME, "face": (166, 4)}


def keep(prefix, pictures):
    """Saves a stage's pictures, so the sheet is put together in a run of its own: this PC's memory is short."""
    facts = {}
    for key, value in pictures.items():
        name = key if isinstance(key, str) else "_".join(key)
        if hasattr(value, "shape"):
            rs.save(value, OUT / f"_{prefix}_{name}.png")
        else:
            facts[name] = value
    (OUT / f"_{prefix}.json").write_text(json.dumps(facts), encoding="utf-8")


def kept(prefix, keys):
    facts = OUT / f"_{prefix}.json"
    out = dict(json.loads(facts.read_text(encoding="utf-8"))) if facts.exists() else {}
    for key in keys:
        name = key if isinstance(key, str) else "_".join(key)
        out[key] = rs.load(OUT / f"_{prefix}_{name}.png")
    return out


def lead(name):
    """One lead before him, standing, from the game's camera and the front, by its own sheet's builder (as
    watt_takes.leads does, one to a run)."""
    views = (("game", GAME), ("front", FRONT))
    if name == "Rook":
        scene = bl.reset_scene()
        joints = rs.build(scene, rs.CHOSEN)
        rs.POSES["idle"](joints)
        meshes = [o for o in scene.objects if o.type == "MESH"]
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        low, high = Vector([min(q[i] for q in pts) for i in range(3)]), Vector([max(q[i] for q in pts) for i in range(3)])
        return {view: rs.trim(ks.render(scene, view, *at, (low + high) / 2, (high - low).length * 1.02, PX)) for view, at in views}
    if name == "Kirra":
        made = ks.takes({"idle": dict(views)})
    else:
        mod = {"Pip": ps, "Lyric": lys}[name]
        made = mod.takes({"idle": {view: (*at, mod.MID) for view, at in views}})
    return {view: rs.trim(made["idle", view]) for view, _ in views}


def sheet():
    new, old = kept("new", NEW), kept("old", OLD)
    leads = [name for name in wt.LEADS if (OUT / f"_{name}_game.png").exists()]  # a lead's run may have been stopped
    others = {(name, "game"): kept(name, ("game",))["game"] for name in leads}
    print(f"size {new['size']} studs, top {new['top']}, {new['tris']} triangles")
    measured = {name: ks.overlap(ks.silhouette(new["game"]), ks.silhouette(others[name, "game"])) for name in leads}
    print("at 64 px from the game's camera, against " + ", ".join(f"{k} {v:.2f}" for k, v in measured.items()))

    W, H = 1920, 1560
    page = rs.canvas(W, H, PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    text = [(40, 30, 56, "WATT, take A in colour", ink),
            (700, 36, 22, "Common / Endurance / Tank / Storm. The quiet wall: the director's pick, built again after the comparison.", ink),
            (700, 68, 18, "The body is R6's own size, the coat painted on it; the hair sculpted; the face painted. Workbench, our own shapes.", soft)]
    ks.fit_row(page, text, [(new["front"], "front"), (new["three"], "three-quarter front"), (new["side"], "his right side"),
                            (new["game"], "the game's camera")], 40, 1880, 610, 470, soft, gap=70)
    ks.fit_row(page, text, [(new["face"], "the face, close"), (old["face"], "the grey take's face"),
                            (old["three"], "the grey take, before"), (rs.black(new["flat"]), "outline")],
               40, 1300, 1130, 440, soft, gap=50)
    x0 = 1360
    text.append((x0, 700, 20, "his colours", ink))
    for k, (name, what) in enumerate(CHIPS):
        rs.fill(page, x0, 736 + k * 46, 56, 34, rs.rgb(PALETTE[name]))
        text.append((x0 + 70, 744 + k * 46, 17, f"{name} {PALETTE[name]}: {what}", soft))
    text += [(x0, 1070, 16, "One accent, Storm's pale pink: the hair's lifted ends, his eyes,", soft),
             (x0, 1094, 16, "and the coat's lining where it turns out (cuffs, edges, vent, collar).", soft)]
    rs.fill(page, 30, 1180, 1860, 2, rs.rgb("#BDB8AE"))

    y0 = 1200
    small = [rs.shrink(rs.trim(p), ks.F64) for p in (new["game"], new["three"], new["front"], new["side"], old["game"], old["three"])]
    small += [rs.shrink(rs.trim(others[name, "game"]), ks.F64) for name in leads]
    widths = [q.shape[1] + 16 for q in small]
    widths[3] += 30
    widths[5] += 30
    text.append((40, y0, 19, "at 64 px over noon and night: in colour from the game's camera, the three-quarter front, the front and "
                             "his right side; the grey take; then the leads before him", soft))
    for label, k in (("in colour", 0), ("grey, before", 4), *((name, 6 + i) for i, name in enumerate(leads))):
        text.append((48 + sum(widths[:k]), y0 + 30, 15, label, ink))
    for row, ground in enumerate((DAY, NIGHT)):
        yy = y0 + 54 + row * 110
        rs.fill(page, 40, yy, sum(widths) + 8, 106, ground)
        cx = 48
        for q, w in zip(small, widths):
            rs.stand(page, q, cx, yy + 102, q.shape[1])
            cx += w
    nx = 40 + sum(widths) + 50
    notes = [f"{new['size'][0]} x {new['size'][1]} x {new['size'][2]} studs, {new['tris']} triangles.",
             "At 64 px from the game's camera, his outline against",
             ", ".join(f"{k} {v:.2f}" for k, v in measured.items()) + " (1 is the same outline).",
             "The game's camera is behind his right shoulder and above:",
             "an assumption until Config holds its numbers. Views are orthographic."]
    missing = [name for name in wt.LEADS if name not in leads]
    if missing:
        notes.append(f"Not drawn here: {', '.join(missing)} (the PC's memory was short for that run).")
    text += [(nx, y0 + 54 + k * 26, 16, line, soft) for k, line in enumerate(notes)]
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, OUT / "watt_colour.png")


if __name__ == "__main__":
    OUT = rs.OUT = ks.OUT = ps.OUT = lys.OUT = wt.OUT = bl.out_dir()
    stage = sys.argv[sys.argv.index("--") + 2:]
    if not stage or "new" in stage:  # one stage a run when memory is short
        looks = figure(build, NEW)
        print(f"size {looks['size']} studs, top {looks['top']}, {looks['tris']} triangles")
        keep("new", looks)
    if not stage or "old" in stage:
        keep("old", figure(wt.take_a, OLD))
    for name in wt.LEADS:
        if not stage or name in stage:
            keep(name, lead(name))
    if not stage or "sheet" in stage:
        sheet()
