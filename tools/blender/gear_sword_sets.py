"""AR6, batch 1: the Sword in three designs at each rarity, in grey: a blockout for research's verdict and the director's eye
(the director, 2026-11-15: "there need to be multiple commons, rares, epics, legendarys like multiples sets of each
rarity anything from common to epic is  simple anyways legendary too").

Fifteen long swords from one set of parts (gear_sword_ladder.py's family): a design is a blade's outline and section, a
guard, a grip, a pommel, and its rarity's materials. Every one stays the Sword: long, on the square's diagonal, point
up and to the right. A rarity keeps the ladder's rule (dark iron; bright steel and one second metal; blued, a small
stone, engraving; a darker metal with filigree and a glowing stone; gilt and ivory with one new form). Research's fix 1
on the ladder is in: an Epic's guard is a clear step larger than a Rare's, so the two part by shape.

Research's two fixes on this sheet are in (AR6, its verdict of 2026-11-15). Every Legendary's one new form changes the
silhouette at 38 points, away from the guard's crossing: Akari's wings, Kiribi's lantern grown to a real lantern,
Inabikari's blade forked (the hoop is gone). The ring stays on Scrap Sword alone: Stallguard's bar ends in brass acorns,
Gales has a fishtail pommel, Nightloom a bar with shuttle ends and a spool pommel.

    blender -b --factory-startup --python tools/blender/gear_sword_sets.py -- build/handoff/Gear/sword_sets

Writes the sheet gear_sword_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

THICK, GRIP, TOP = 0.12, 1.5, -0.14  # the blade's half depth, the grip's length, where the grip starts under the guard
g.GREY.update(bronze=0.52, scrap=0.4)
g.METAL = g.METAL + ("bronze", "scrap")
mat = g.material

# The guards drawn as plates, each from its right half, top middle round to foot middle.
VEE = [(0.0, 0.16), (0.3, 0.16), (1.2, 0.54), (1.31, 0.37), (0.36, -0.14), (0.0, -0.2)]
FLARE = [(0.0, 0.15), (0.85, 0.13), (1.14, 0.27), (1.36, 0.25), (1.36, -0.25), (1.14, -0.27), (0.85, -0.13), (0.0, -0.15)]
CURLED = [(0.0, 0.2), (0.45, 0.2), (1.0, 0.3), (1.28, 0.55), (1.34, 0.92), (1.12, 1.12), (1.2, 1.34), (1.56, 1.16),
          (1.72, 0.72), (1.66, 0.3), (1.2, -0.06), (0.45, -0.24), (0.0, -0.28)]
TINES = [(0.11, 0.2), (0.3, 0.2), (0.3, 1.0), (0.2, 1.55), (0.11, 1.0)]
# Inabikari's fork, drawn on the right: a branch leaves the blade above the guard, turns, and runs on beside it to a point
# of its own. The first and last points sit inside the blade.
FORK = [(0.3, 0.9), (1.4, 1.7), (1.46, 2.6), (1.3, 3.7), (1.06, 2.6), (1.04, 1.95), (0.3, 1.42)]


def scaled(outline, sx, sz=1.0):
    return [(x * sx, z * sz) for x, z in outline]


def design(name, rarity, note, mats, **more):
    blade, guard, grip, pommel = mats
    return dict(dict(name=name, rarity=rarity, note=note, blade=blade, guard_mat=guard, grip=grip, pommel_mat=pommel,
                     length=6.4, width=0.86, profile="taper", tip="point", section="fuller", guard="bar", span=2.3,
                     ends=None, trim=guard, stone=None, bezel=None, foot=None, collar=False, wings=False, fork=False,
                     wraps=0, bands=(), band_mat=guard, pommel="wheel", rim=None, stud=None, pommel_stone=None,
                     lines=(), edge=False, grip_len=GRIP), **more)


IRON, STEEL, BLUED, RICH, GILT = (("iron", "iron", "wood", "iron"), ("steel", "steel", "leather", "steel"),
                                  ("blued", "blued", "leather", "blued"), ("rich", "rich", "leather", "rich"),
                                  ("gilt", "gilt", "ivory", "gilt"))
LINE = ((0.0, 0.34, 0.34),)  # an engraved line: where across the blade, where along it, how long

# A star marks research's own name, kept. Each name fits 24 characters.
DESIGNS = (
    # lift: in colour, plain iron toned to a mid grey with a light edge (gear_icons.py; research's look at batch 3's fixes, 2026-11-16: the same rule for batch 1's two iron swords)
    design("Iron Sword*", "Common", "The ladder's own: a ridge, a plain bar, a wheel pommel.", IRON,
           section="ridge", bands=(0.5,), lift="iron"),
    design("Bronze Sword", "Common", "A leaf blade with a rib, a short thick guard, a cap pommel.",
           ("bronze", "bronze", "leather", "bronze"), length=6.0, width=0.92, profile="leaf", section="ridge", span=1.5,
           bands=(0.08, 0.92), pommel="cap"),
    design("Scrap Sword", "Common", "A flat bar of a blade, its point cut on the slant; bolt heads on the bar, a ring to "
           "hang it by.", ("scrap", "scrap", "leather", "scrap"), length=6.2, width=0.9, profile="parallel", tip="clip",
           section="flat", span=2.0, ends="disc", wraps=5, pommel="ring"),

    design("Lanternsteel Sword*", "Uncommon", "The ladder's own: a fuller, end blocks, a wrap, a brass collar and rim.",
           STEEL, ends="block", collar=True, wraps=7, rim="brass"),
    design("Rowsmith Sword", "Uncommon", "A ridge, a guard slanted toward the point, brass bands and a brass lozenge "
           "pommel.", ("steel", "steel", "leather", "brass"), section="ridge", guard=VEE, bands=(0.08, 0.92),
           band_mat="brass", pommel="lozenge"),
    design("Stallguard Sword", "Uncommon", "A broad even blade, a bar that ends in brass acorns, a pear pommel.", STEEL,
           width=0.92, profile="parallel", span=2.2, ends="acorn", trim="brass", wraps=7, pommel="pear"),

    design("Blade of Embers*", "Rare", "The ladder's own: a guard turned to the point, one small stone, a line in the "
           "fuller.", BLUED, guard=g.TURNED, stone=("stone", 0.17), wraps=7, bands=(0.05, 0.95), pommel="facet",
           lines=((0.0, 0.3, 0.34),)),
    design("Blade of Hoarfrost", "Rare", "An even blade, a straight guard with spade ends, the stone at its middle, a "
           "pear pommel.", BLUED, profile="parallel", guard=FLARE, stone=("stone", 0.17), wraps=7, pommel="pear",
           lines=((0.0, 0.36, 0.44),)),
    design("Brand of Gales", "Rare", "A leaf blade with a rib and two lines, an S guard, a fishtail pommel with the "
           "stone set in it.", BLUED, length=6.2, width=0.92, profile="leaf", section="ridge", guard="s", wraps=7,
           bands=(0.05,), pommel="tail", pommel_stone=("stone", 0.14), lines=((-0.17, 0.4, 0.3), (0.17, 0.4, 0.3))),

    design("Stormcall Blade*", "Epic", "The ladder's own, its guard a step larger: the hooks curl back. A filigree foot, "
           "the stone in a bezel.", RICH, guard=CURLED, trim="filigree", stone=("glow", 0.22), bezel="ring", foot="plate",
           wraps=9, bands=(0.05, 0.95), pommel="facet", stud="filigree", lines=((0.0, 0.42, 0.34),)),
    design("Gloamforge Blade", "Epic", "A wide slanted guard with two filigree tines up the blade, the stone in a lozenge, "
           "a lozenge pommel.", RICH, profile="parallel", guard=scaled(VEE, 1.4, 1.25), trim="filigree",
           stone=("glow", 0.22), bezel="lozenge", foot="tines", wraps=9, bands=(0.05, 0.95), band_mat="filigree",
           pommel="lozenge", stud="filigree"),
    design("Nightloom Brand", "Epic", "A leaf blade with two filigree lines, a long bar with a shuttle at each end, "
           "the stone in a bezel, a spool pommel.", ("rich", "rich", "leather", "filigree"), length=6.2, width=0.92,
           profile="leaf", section="ridge", span=3.0, ends="shuttle", trim="filigree", stone=("glow", 0.22), bezel="ring",
           wraps=9, bands=(0.05, 0.95), pommel="spool", lines=((-0.17, 0.42, 0.36), (0.17, 0.42, 0.36))),

    design("Akari, the First Light*", "Legendary", "The ladder's own. Its one new form: a small wing each side of the "
           "guard.", GILT, guard=g.TURNED, trim="ivory", stone=("lit", 0.22), bezel="ring", foot="plate", wings=True,
           bands=(0.05, 0.5, 0.95), pommel="facet", stud="ivory", lines=((0.0, 0.42, 0.34),), edge=True),
    design("Kiribi, the Struck Spark", "Legendary", "Its one new form: the pommel is a lantern, roof and cage, with a "
           "second light inside it.", GILT, length=5.3, guard=g.HOOKED, trim="ivory", stone=("lit", 0.22), bezel="ring", foot="tines",
           bands=(0.05, 0.95), pommel="lantern", edge=True),
    design("Inabikari, the Far Flash", "Legendary", "Its one new form: the blade forks. A branch leaves it above the "
           "guard and runs on to a point of its own. Lozenge ends, a pear pommel.", GILT, profile="parallel", span=2.6,
           ends="lozenge", trim="ivory", stone=("lit", 0.22), fork=True, bands=(0.05, 0.95), pommel="pear", lines=((0.0, 0.4, 0.4),), edge=True),
)
assert all(len(d["name"].rstrip("*")) <= 24 for d in DESIGNS), "a name is over 24 characters"
RARITIES = ("Common", "Uncommon", "Rare", "Epic", "Legendary")


# --- the parts ---------------------------------------------------------------------------------------------------------

def outline(d):
    """The blade's two edges at u of its length, for this design's outline and point."""
    kind, clip = d["profile"], d["tip"] == "clip"
    start = d.get("start") or dict(parallel=0.86, wedge=0.72).get(kind, 0.8)  # where the point begins

    def half(u):
        t = min(u, start) / start
        if kind == "taper":
            return d["width"] / 2 * (1 - 0.2 * t)
        if kind == "parallel":
            return d["width"] / 2 * (1 - 0.05 * t)
        if kind == "wedge":  # broad at the foot, straight to its point
            return d["width"] / 2 * (1 - 0.42 * t)
        return d["width"] / 2 * (0.86 + 0.2 * math.sin(math.pi * t ** 1.25))  # a leaf: a waist, a swell, then the point

    def edges(u):
        hw = half(u)
        if u <= start:
            return -hw, hw
        v = (u - start) / (1 - start)
        if clip:  # the left edge cut straight to the point, as the kit cuts a corner
            return -hw + 1.55 * hw * v, hw - 0.45 * hw * v ** 2.3
        k = 1.25 if kind == "parallel" else 1.5
        return -hw * (1 - v ** k), hw * (1 - v ** k)

    return edges, (half(1.0) * 0.55 if clip else 0.0)


def blade(d):
    edges, tip_x = outline(d)
    fuller = d["section"] == "fuller"
    dip = dict(ridge=1.45, fuller=0.42, flat=1.0)[d["section"]]
    bm = bmesh.new()
    rings = []
    for u in (0.0, 0.08, 0.15, 0.22, 0.3, 0.38, 0.45, 0.55, 0.62, 0.72, 0.8, 0.86, 0.91, 0.95, 0.98):
        z, (xl, xr) = u * d["length"], edges(u)
        mid, wide = (xl + xr) / 2, xr - xl
        h = THICK * (1 - 0.35 * u)
        inset = min(0.2, wide * 0.3)
        f = min(0.11, wide * 0.14) * (1.0 if not fuller else min(1.0, max(0.02, (0.62 - u) / 0.1)))
        front = [(xl, 0.0), (xl + inset, -h), (mid - f, -h), (mid - 0.6 * f, -h * dip), (mid + 0.6 * f, -h * dip),
                 (mid + f, -h), (xr - inset, -h), (xr, 0.0)]
        ring = front + [(x, -y) for x, y in front[-2:0:-1]]
        rings.append([bm.verts.new((x, y, z)) for x, y in ring])
    tip = bm.verts.new((tip_x, 0, d["length"]))
    n = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for k in range(n):
            bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
    for k in range(n):
        bm.faces.new((rings[-1][k], rings[-1][(k + 1) % n], tip))
    bm.faces.new(list(reversed(rings[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.smooth_by_angle(bl.object_from_bmesh("Blade", bm, mat(d["blade"])), 20.0)


def stone(key, radius, y, z=0.0):
    """A cut stone on a face, and its twin on the back."""
    out = []
    for side in (-1, 1):
        s = bl.sphere("Stone", radius, segments=6, rings=3, material=mat(key))
        out.append(bl.place(s, (0, side * y, z), (0, 0, 30), (1, 0.55, 1.2)))
    return out


def guard(d):
    key, trim, parts = d["guard_mat"], d["trim"], []
    if d["guard"] == "bar":
        span, thick = d["span"], 0.34 if d["span"] < 1.8 else 0.26
        parts.append(bl.bevel(bl.box("Guard", (span, 0.3, thick), mat(key)), 0.045, segments=1))
        for side in (-1, 1):
            x = side * span / 2
            if d["ends"] == "block":
                parts.append(bl.bevel(bl.place(bl.box("End", (0.24, 0.36, 0.38), mat(key)), (x, 0, 0)), 0.045, segments=1))
            elif d["ends"] == "disc":  # a bolt's head
                head = bl.cylinder("End", 0.21, 0.36, segments=6, material=mat(key))
                parts.append(bl.bevel(bl.place(head, (x, 0, 0), (90, 0, 0)), 0.035, segments=1))
            elif d["ends"] == "lozenge":
                parts.append(g.plate("End", [(x, 0.3), (x + 0.22, 0.0), (x, -0.3), (x - 0.22, 0.0)], 0.36, key, bevel=0.04))
            elif d["ends"] == "acorn":  # a cup on the bar's end and a nut in it
                parts.append(bl.place(bl.cylinder("Cup", 0.2, 0.12, segments=12, material=mat(trim)), (x, 0, 0), (0, 90, 0)))
                nut = bl.sphere("End", 0.19, 12, 8, mat(trim))
                parts.append(bl.smooth_by_angle(bl.place(nut, (x + side * 0.16, 0, 0), (0, 0, 0), (1.35, 1, 1)), 40.0))
            elif d["ends"] == "shuttle":  # a loom's shuttle: a long pointed oval, lying along the bar
                a, b = x - side * 0.3, x + side * 0.62
                parts.append(g.plate("End", [(a, 0.0), ((a + b) / 2, 0.24), (b, 0.0), ((a + b) / 2, -0.24)], 0.36, trim,
                                     bevel=0.05))
    elif d["guard"] == "s":  # one arm turned to the point, the other to the hand
        half = g.TURNED
        parts.append(g.plate("Guard", half + [(-x, -z) for x, z in half if x > 1e-6], 0.34, key, bevel=0.045))
    else:
        parts.append(g.plate("Guard", g.mirrored(d["guard"]), 0.34, key, bevel=0.045))
    if d["collar"]:
        parts.append(bl.place(bl.torus("Collar", 0.2, 0.075, 24, 8, mat("brass")), (0, 0, -0.2)))
    if d["stone"]:
        kind, radius = d["stone"]
        parts += stone(kind, radius, 0.2)
        for side in (-1, 1):
            if d["bezel"] == "ring":
                parts.append(bl.place(bl.torus("Bezel", radius * 1.18, 0.042, 20, 8, mat(trim)), (0, side * 0.18, 0.0), (90, 0, 0)))
            elif d["bezel"] == "lozenge":
                s = radius * 1.75
                parts.append(g.plate("Bezel", [(0, s), (s * 0.82, 0), (0, -s), (-s * 0.82, 0)], 0.06, trim, y=side * 0.17,
                                     bevel=0.015))
    for side in (-1, 1):
        y = side * (THICK + 0.015)
        if d["foot"] == "plate":
            parts.append(g.plate("Foot", g.mirrored(g.FOOT), 0.04, trim, y=y, bevel=0.01))
        elif d["foot"] == "tines":
            for flip in (-1, 1):
                parts.append(g.plate("Tine", [(flip * x, z) for x, z in TINES], 0.04, trim, y=y, bevel=0.01))
    if d["wings"]:
        for side in (-1, 1):
            parts.append(g.plate("Wing", [(side * x, z) for x, z in (g.WING if side > 0 else g.WING[::-1])], 0.18, key,
                                 bevel=0.035))
    if d["fork"]:  # one branch, on the side that lies upper left in the square
        parts.append(g.plate("Fork", [(-x, z) for x, z in FORK[::-1]], 0.2, d["blade"], bevel=0.06))
    return parts


def grip(d):
    key, parts, long = d["grip"], [], d["grip_len"]
    body = bl.cylinder("Grip", 0.15, long, segments=20, material=mat(key), radius_top=0.175)
    parts.append(bl.smooth_by_angle(bl.place(body, (0, 0, TOP - long / 2)), 40.0))
    for i in range(d["wraps"]):  # the wrap: turns of cord, each a little tilted
        z = TOP - 0.2 - (long - 0.4) * i / (d["wraps"] - 1)
        parts.append(bl.place(bl.torus("Wrap", 0.17, 0.04, 18, 6, mat(key)), (0, 0, z), (10, 6, 0)))
    for u in d["bands"]:
        parts.append(bl.place(bl.torus("Band", 0.175, 0.05, 20, 8, mat(d["band_mat"])), (0, 0, TOP - long * u)))
    return parts


def pommel(d):
    kind, key, z = d["pommel"], d["pommel_mat"], TOP - d["grip_len"]
    if kind == "wheel":
        parts = [bl.bevel(bl.place(bl.cylinder("Pommel", 0.3, 0.22, segments=20, material=mat(key)), (0, 0, z - 0.22),
                                   (90, 0, 0)), 0.04, segments=1)]
        if d["rim"]:
            parts.append(bl.place(bl.torus("Rim", 0.3, 0.045, 24, 8, mat(d["rim"])), (0, 0, z - 0.22), (90, 0, 0)))
        if d["pommel_stone"]:
            parts += stone(d["pommel_stone"][0], d["pommel_stone"][1], 0.12, z - 0.22)
    elif kind == "cap":  # a low mushroom
        parts = [bl.bevel(bl.place(bl.cylinder("Pommel", 0.33, 0.2, segments=16, material=mat(key)), (0, 0, z - 0.08)),
                          0.06, segments=1)]
    elif kind == "ring":
        parts = [bl.place(bl.torus("Pommel", 0.23, 0.075, 24, 8, mat(key)), (0, 0, z - 0.26), (90, 0, 0))]
    elif kind == "lozenge":
        zc = z - 0.3
        parts = [g.plate("Pommel", [(0, zc + 0.36), (0.3, zc), (0, zc - 0.36), (-0.3, zc)], 0.26, key, bevel=0.05)]
    elif kind == "pear":
        body = bl.place(bl.cylinder("Pommel", 0.14, 0.4, segments=16, material=mat(key), radius_top=0.3), (0, 0, z - 0.2),
                        (180, 0, 0))
        dome = bl.place(bl.sphere("Dome", 0.3, 16, 8, mat(key)), (0, 0, z - 0.4), (0, 0, 0), (1, 1, 0.55))
        parts = [bl.smooth_by_angle(body, 40.0), bl.smooth_by_angle(dome, 40.0)]
    elif kind == "tail":  # a fish's tail: it flares from the grip and ends in a notch
        parts = [g.plate("Pommel", [(-0.14, z), (0.14, z), (0.42, z - 0.6), (0.0, z - 0.4), (-0.42, z - 0.6)], 0.24, key,
                         bevel=0.05)]
        if d["pommel_stone"]:
            parts += stone(d["pommel_stone"][0], d["pommel_stone"][1], 0.13, z - 0.24)
    elif kind == "spool":  # a bobbin: two flanges and a waist
        parts = [bl.place(bl.cylinder("Flange", 0.31, 0.09, segments=16, material=mat(key)), (0, 0, z - 0.05)),
                 bl.place(bl.cylinder("Waist", 0.15, 0.36, segments=12, material=mat(d["guard_mat"])), (0, 0, z - 0.27)),
                 bl.place(bl.cylinder("Flange", 0.31, 0.09, segments=16, material=mat(key)), (0, 0, z - 0.49)),
                 bl.place(bl.sphere("Stud", 0.1, 10, 6, mat(key)), (0, 0, z - 0.56))]
    elif kind == "lantern":  # a real lantern: a roof with eaves, six bars, a light inside, a base and a drop under it
        parts = [bl.place(bl.cylinder("Roof", 0.64, 0.36, segments=6, material=mat(key), radius_top=0.2), (0, 0, z - 0.18)),
                 bl.place(bl.cylinder("Base", 0.5, 0.12, segments=6, material=mat(key)), (0, 0, z - 1.32)),
                 bl.place(bl.cylinder("Drop", 0.09, 0.22, segments=6, material=mat(key), radius_top=0.32), (0, 0, z - 1.49)),
                 bl.place(bl.sphere("Finial", 0.1, 10, 6, mat(key)), (0, 0, z - 1.64)),
                 bl.place(bl.sphere("Light", 0.3, 12, 8, mat("lit")), (0, 0, z - 0.82), (0, 0, 0), (1, 1, 1.35))]
        for i in range(6):
            a = math.radians(60 * i + 30)
            parts.append(bl.place(bl.cylinder("Bar", 0.045, 0.92, segments=6, material=mat(key)),
                                  (0.44 * math.cos(a), 0.44 * math.sin(a), z - 0.82)))
    else:  # cut in facets: it widens down from the grip, then closes
        parts = [bl.place(bl.cylinder("Pommel", 0.17, 0.36, segments=8, material=mat(key), radius_top=0.3), (0, 0, z - 0.18),
                          (180, 0, 0)),
                 bl.place(bl.cylinder("Cap", 0.3, 0.16, segments=8, material=mat(key), radius_top=0.09), (0, 0, z - 0.44),
                          (180, 0, 0))]
    if d["stud"]:
        low = dict(facet=0.54, lozenge=0.7)[kind]
        parts.append(bl.place(bl.sphere("Stud", 0.09, 10, 6, mat(d["stud"])), (0, 0, z - low)))
    return parts


def extras(d):
    parts, edges = [], outline(d)[0]
    key = "ivory" if d["rarity"] == "Legendary" else "filigree"
    for x, at, long in d["lines"]:  # engraved lines, front and back: in the fuller, or on the flats beside a rib
        deep = THICK * (0.42 if abs(x) < 0.01 and d["section"] == "fuller" else 0.8)
        for side in (-1, 1):
            parts.append(bl.place(bl.box("Line", (0.05, 0.02, d["length"] * long), mat(key)), (x, side * deep, d["length"] * at)))
    if d["edge"]:  # a light on the edge
        for side in (0, 1):
            path = [Vector((edges(u)[side], 0, u * d["length"])) for u in np.linspace(0.05, 0.995, 28)]
            parts.append(bl.tube_along("Edge", path, [0.03] * len(path), sides=6, material=mat("lit")))
        if d["fork"]:  # the branch's own edge, lit round its point
            path = [Vector((-x, 0, z)) for x, z in FORK[1:6]]
            parts.append(bl.tube_along("Edge", path, [0.035] * len(path), sides=6, material=mat("lit")))
    return parts


def sword(d, more=None):
    """The sword in a scene of its own, laid on the diagonal. `more(d, parts)` is another kind's own parts: it may cut
    the blade (parts[0]) and returns what it adds."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Room")
    parts = [blade(d)] + guard(d) + grip(d) + pommel(d) + extras(d)
    if more:
        parts += more(d, parts)
    lay = Matrix.Rotation(math.radians(g.LEAN), 4, "Y") @ Matrix.Rotation(math.radians(g.SPIN), 4, "Z")
    for obj in parts:
        obj.data.transform(lay)
    return scene, parts


def renders(out, designs=DESIGNS, more=None):
    """All fifteen at one scale, set by the largest, each centred in its square."""
    sizes = []
    for d in designs:
        x0, x1, z0, z1 = g.bounds(sword(d, more)[1])
        sizes.append(max(x1 - x0, z1 - z0))
    span = max(sizes) / g.FILL
    shots = {}
    for d, size in zip(designs, sizes):
        scene, parts = sword(d, more)
        x0, x1, z0, z1 = g.bounds(parts)
        shots[d["name"]] = g.shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2), span)
        print(f"{d['name']}: fills {size / span:.2f} of the square")
    return shots


# --- the sheet ---------------------------------------------------------------------------------------------------------

WORDS = dict(
    file="gear_sword_sets.png",
    title="Grow your Anime: the Sword in three designs at each rarity, in grey (AR6, batch 1)",
    lead="Fifteen long swords from one set of parts, at one scale, one camera and one light. A grey is its material's value. "
         "A rarity keeps the ladder's rule; a design changes the blade's outline, the guard and the pommel.",
    notes=(
        "Three at each rarity is the batch's count (the director's yes, 2026-11-15). A set is its word, carried across the kinds: "
        "Iron, Bronze, Scrap; Lanternsteel, Rowsmith, Stallguard; of Embers, of Hoarfrost, of Gales; Stormcall, Gloamforge, Nightloom.",
        "A Legendary is named alone, in the family of lights. A star is research's own name. Kiribi: the sparks struck from flint "
        "for luck at a door. Inabikari: a flash of lightning.",
        "Research's two fixes are in. Each Legendary's one new form shows at 38 points: Akari's wings, Kiribi's lantern grown, "
        "Inabikari's blade forked (its hoop is gone). The ring stays on Scrap Sword alone: acorns, a fishtail, shuttles and a spool.",
        "Not here yet: colour, frames, the class mark.",
    ),
)


def sheet(out, shots, designs=DESIGNS, words=WORDS, beside=None):
    """The fifteen at 220 points, at the slot's 38, and as silhouettes. Another kind's script passes its own designs
    and words, and `beside`: a label and five shots of a kind it must not be taken for."""
    ui.K = K = 2
    w, pitch_x, pitch_y, top = 220.0, 230.0, 272.0, 94.0
    sh = ui.Sheet(1180, top + 3 * pitch_y + 232, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, words["title"], g.INK)
    t.text(20, 36, 9.5, "The director, 2026-11-15: \"there need to be multiple commons, rares, epics, legendarys like multiples "
           "sets of each rarity anything from common to epic is simple anyways legendary too\".", g.SOFT_INK)
    t.text(20, 50, 9.5, words["lead"], g.SOFT_INK)
    by = {r: [d for d in designs if d["rarity"] == r] for r in RARITIES}
    for i, r in enumerate(RARITIES):
        t.text(20 + i * pitch_x, top - 20, 12, r, g.NOTE)
        for j, d in enumerate(by[r]):
            x, y = 20 + i * pitch_x, top + j * pitch_y
            tile = sh.tile(x, y, w, w)
            tile.paint(tile.poly(ui.cut_box(0, 0, w, w, 8, 0, 8, 0)), c(g.CELL))
            rs.paste(sh.px, rs.shrink(shots[d["name"]], w * K / g.SIZE), round(x * K), round(y * K))
            t.text(x + 8, y + 7, 11, d["name"], g.INK if not d["name"].endswith("*") else g.SOFT_INK)
            for k, line in enumerate(g.lines(d["note"], 46)):
                t.text(x, y + w + 6 + k * 12, 8.5, line, g.SOFT_INK)

    # At the slot's size and alone as a silhouette, a rarity's three side by side.
    y = top + 3 * pitch_y + 4
    t.text(20, y, 10, "At the Voidkin screen's slot, 38 points; under it each silhouette alone at 32 pixels (shown at twice its "
           "size). A rarity's three stand together.", g.SOFT_INK)
    def slot(x, shot):
        tile = sh.tile(x, y + 18, 44, 44)
        tile.paint(tile.poly(ui.cut_box(0, 0, 44, 44, 4, 0, 4, 0)), c(g.DARK))
        rs.paste(sh.px, rs.shrink(shot, 38 * K / g.SIZE), round((x + 3) * K), round((y + 21) * K))
        tile = sh.tile(x, y + 68, 44, 44)
        tile.paint(tile.poly(ui.cut_box(0, 0, 44, 44, 4, 0, 4, 0)), c("#8A8F9C"))
        tiny = rs.shrink(rs.black(shot), 32 / g.SIZE)
        rs.paste(sh.px, np.repeat(np.repeat(tiny, 2, axis=0), 2, axis=1), round((x + 6) * K), round((y + 74) * K))

    n = 0
    for i, r in enumerate(RARITIES):
        for d in by[r]:
            slot(20 + n * 50 + i * 26, shots[d["name"]])
            n += 1
        t.text(20 + (n - 3) * 50 + i * 26, y + 116, 8, r, g.SOFT_INK)
    if beside:  # another kind's five, to tell the two apart at the slot's size
        label, others = beside
        for k, shot in enumerate(others):
            slot(926 + k * 50, shot)
        t.text(926, y + 116, 8, label, g.SOFT_INK)
    y += 136
    for i, line in enumerate(words["notes"]):
        t.text(20, y + i * 15, 9, line, g.SOFT_INK)
    layers = ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items)
    for layer in layers.values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / words["file"])


def main():
    out = bl.out_dir()
    sheet(out, renders(out))


if __name__ == "__main__":
    main()
