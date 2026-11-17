"""AR31: the pictures of what raises an item, forge stones, War Emblems and jewels, in grey first.

The feel line (Modulo's, for research's verdict): the player opens the bag's Stones, Emblems or Jewels and reads each
one's worth from its shape before reading a word or a number: a stone's grade, an emblem's rarity and its stat, a
jewel's tier.

Each kind is its own family of things, apart from the shards (crystals, pointed) and the chests:
  - a forge stone is opaque stone with the forge's light in it, worked more as its grade rises:
      Low, a rough lump with one crack of light; Mid, a whetstone of two grits with a seam of light where they meet,
      lying on the diagonal; High, a polished block standing, bound in two bands, its light behind a window;
  - a War Emblem is a six-sided badge, never a coin: a dark enamel face with its stat's mark raised in pale, in a
      rim; Common the badge alone in iron, Uncommon four points behind it in steel, Rare eight in gilt with a ring of
      light inside the rim. Its rarity's cell does the rest, as an item's does;
  - a jewel is a cut stone lying face up, and its tier is its shape (the director, TR39): tier 1 a small stone, 2 a
      larger one with more facets, 3 set in a cup with four claws, 4 with a halo of small stones, 5 with four rays
      and its own light. Its type is its colour, in the colour pass.

Built in code on gear_parts.py's shapes and rendered in Workbench, as AR6's gear and AR21's chests are. The sheet shows
each in the bag's cell (AR18's A) seen close, at 38 points and alone at 32 pixels over dark, then a row of the bag with
AR6's gear and AR21's chests among them.

Run: blender --background --factory-startup --python tools/blender/upgrade_icons.py -- build/handoff/UI/upgrades
"""
import math
import sys
import textwrap
from pathlib import Path

import bmesh
import numpy as np
from mathutils import bvhtree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import chest_icons as ch  # noqa: E402
import gear_parts as p  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
GEAR = ROOT / "build" / "handoff" / "UI" / "gear" / "images"
CHESTS = ROOT / "build" / "handoff" / "UI" / "chests" / "images"
mat = p.mat
for key, value in (("rock", 0.4), ("grit_dark", 0.32), ("grit_pale", 0.62), ("polished", 0.5), ("enamel", 0.24),
                   ("gem", 0.7)):
    g.GREY.setdefault(key, value)


# --- forge stones -------------------------------------------------------------------------------------------------------

def low():
    """A rough lump, wider than tall, its facets broken, one crack of light across its face."""
    rng = np.random.default_rng(31)
    bm = bmesh.new()
    for _ in range(26):
        v = rng.normal(size=3)
        v /= np.linalg.norm(v)
        r = 1.0 + rng.uniform(-0.1, 0.1)
        bm.verts.new((v[0] * 1.3 * r, v[1] * 1.0 * r, max(v[2] * 0.9 * r, -0.62)))
    hull = bmesh.ops.convex_hull(bm, input=list(bm.verts))
    loose = {v for v in hull["geom_interior"] + hull["geom_unused"] if isinstance(v, bmesh.types.BMVert)}
    bmesh.ops.delete(bm, geom=list(loose), context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    tree = bvhtree.BVHTree.FromBMesh(bm)
    lump = bl.object_from_bmesh("Lump", bm, mat("rock"))
    # the crack: a jagged line across the front, laid on the stone by casting from the camera's side
    path, crack = [(-1.0, 0.42), (-0.62, 0.2), (-0.38, 0.32), (-0.08, -0.02), (0.22, 0.06), (0.5, -0.26), (0.86, -0.18)], []
    for (x0, z0), (x1, z1) in zip(path, path[1:]):
        for k in range(8):
            t = k / 8
            hit = tree.ray_cast((x0 + (x1 - x0) * t, -5.0, z0 + (z1 - z0) * t), (0, 1, 0))[0]
            if hit is not None:
                crack.append(tuple(hit))
    return [lump, p.tube("Crack", crack, 0.055, "lit", sides=6)]


def mid():
    """A whetstone of two grits lying on the diagonal, a seam of light where they meet."""
    w, d, h, seam = 2.5, 1.05, 0.7, 0.12
    parts = []
    for side, key in ((-1, "grit_dark"), (1, "grit_pale")):
        half = (w - seam) / 2
        parts.append(bl.bevel(bl.place(bl.box("Grit", (half, d, h), mat(key)), (side * (half + seam) / 2, 0, 0)), 0.07, 1))
    parts.append(bl.bevel(bl.box("Seam", (seam, d + 0.04, h + 0.04), mat("lit")), 0.01, 1))
    for obj in parts:
        bl.place(obj, (0, 0, 0), (0, -28, 0))  # its right end raised: laid on the picture's diagonal
    return parts


def high_block():
    """A: a polished block standing, square and chamfered, bound at its foot and head, its light behind a window."""
    side, h = 1.25, 1.9
    parts = [bl.bevel(bl.place(bl.box("Block", (side, side, h), mat("polished")), (0, 0, h / 2)), 0.1, 1)]
    for z in (0.3, h - 0.3):
        parts.append(bl.bevel(bl.place(bl.box("Band", (side + 0.12, side + 0.12, 0.2), mat("brass")), (0, 0, z)), 0.03, 1))
    window = [(0.0, 0.5), (0.22, 0.0), (0.0, -0.5)]
    parts.append(bl.place(p.flat("Core", p.mirrored(window), 0.05, "lit"), (0, -side / 2 - 0.01, h / 2)))
    for x in (-0.36, 0.36):  # two lines of light from the window to the bands
        parts.append(bl.place(bl.box("Vein", (0.05, 0.04, h - 0.82), mat("lit")), (x, -side / 2 - 0.01, h / 2)))
    return parts


def high_ingot():
    """B: the stone cut to an ingot and polished, lying, bound in two bands, a line of light round its top."""
    foot, top, h = (2.5, 1.35), (1.9, 0.8), 0.78
    bm = bmesh.new()
    corners = [bm.verts.new((sx * a / 2, sy * b / 2, z)) for (a, b), z in ((foot, 0.0), (top, h))
               for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    bm.faces.new(corners[:4])
    bm.faces.new(corners[4:])
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((corners[i], corners[j], corners[4 + j], corners[4 + i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    parts = [bl.bevel(bl.object_from_bmesh("Ingot", bm, mat("polished")), 0.06, 1)]
    for x in (-0.62, 0.62):  # two bands across it, a little proud of its foot
        parts.append(bl.bevel(bl.place(bl.box("Band", (0.2, foot[1] + 0.1, h + 0.08), mat("brass")), (x, 0, h / 2)), 0.03, 1))
    a, b = top[0] - 0.22, top[1] - 0.22
    for (x0, y0), (x1, y1) in (((-a / 2, -b / 2), (a / 2, -b / 2)), ((a / 2, -b / 2), (a / 2, b / 2)),
                               ((a / 2, b / 2), (-a / 2, b / 2)), ((-a / 2, b / 2), (-a / 2, -b / 2))):
        length = math.hypot(x1 - x0, y1 - y0) + 0.05
        bar = bl.box("Light", (length, 0.1, 0.07) if y0 == y1 else (0.1, length, 0.07), mat("lit"))
        parts.append(bl.place(bar, ((x0 + x1) / 2, (y0 + y1) / 2, h + 0.02)))
    return parts


# --- War Emblems --------------------------------------------------------------------------------------------------------

def hexagon(radius):
    return [(radius * math.sin(math.radians(a)), radius * math.cos(math.radians(a))) for a in range(0, 360, 60)]


# A stat's mark, drawn from the front at about 0.5 of the badge, each from its right half where it mirrors.
GLYPHS = dict(
    Attack=p.mirrored([(0.0, 0.6), (0.08, 0.46), (0.08, -0.16), (0.27, -0.16), (0.27, -0.26), (0.06, -0.26), (0.06, -0.44),
                       (0.11, -0.5), (0.06, -0.57), (0.0, -0.6)]),
    Defence=p.mirrored([(0.0, 0.5), (0.4, 0.5), (0.42, 0.1), (0.33, -0.22), (0.16, -0.44), (0.0, -0.56)]),
    Health=p.mirrored([(0.0, 0.26), (0.12, 0.44), (0.3, 0.5), (0.46, 0.4), (0.51, 0.2), (0.43, -0.03), (0.22, -0.28),
                       (0.0, -0.5)]),
    Critical=p.star(4, 0.62, 0.17, turn=90.0),
)
EMBLEM = dict(Common=("iron", 0, None), Uncommon=("steel", 4, (1.5, 0.62, 45.0)), Rare=("gilt", 8, (1.52, 0.86, 90.0)))


def emblem(rarity, stat):
    """A six-sided badge: a metal plate, a dark enamel face proud of it, the stat's mark raised; points behind it by
    rarity, and Rare's ring of light inside the rim."""
    metal, points, star = EMBLEM[rarity]
    parts = [p.flat("Plate", hexagon(1.0), 0.22, metal, y=0.0, bevel=0.04),
             p.flat("Face", hexagon(0.85), 0.08, "enamel", y=-0.13, bevel=0.015),
             p.flat("Mark", [(x * 1.15, z * 1.15) for x, z in GLYPHS[stat]], 0.07, "ivory", y=-0.2, bevel=0.012)]
    if points:
        outer, inner, turn = star
        parts.append(p.flat("Points", p.star(points, outer, inner, turn=turn), 0.12, metal, y=0.12, bevel=0.03))
    if rarity == "Rare":
        ring = [(x, z) for x, z in hexagon(0.74)]
        for (x0, z0), (x1, z1) in zip(ring, ring[1:] + ring[:1]):
            length = math.hypot(x1 - x0, z1 - z0)
            bar = bl.box("Ring", (length, 0.04, 0.045), mat("lit"))
            parts.append(bl.place(bar, ((x0 + x1) / 2, -0.18, (z0 + z1) / 2), (0, -math.degrees(math.atan2(z1 - z0, x1 - x0)), 0)))
    return parts


# --- jewels -------------------------------------------------------------------------------------------------------------

def brilliant(name, r, facets, key, at=(0.0, 0.0, 0.0)):
    """A cut stone lying face up, its facets flat: a table, a crown of triangles, a girdle, a pavilion to its point."""
    x, y, z = at
    bm = bmesh.new()
    step = 2 * math.pi / facets
    top, girdle, point = z + 0.4 * r, z, z - 0.72 * r
    table = [bm.verts.new((x + 0.56 * r * math.cos((i + 0.5) * step), y + 0.56 * r * math.sin((i + 0.5) * step), top))
             for i in range(facets)]
    rim = [bm.verts.new((x + r * math.cos(i * step), y + r * math.sin(i * step), girdle)) for i in range(facets)]
    foot = bm.verts.new((x, y, point))
    bm.faces.new(table)
    for i in range(facets):
        j = (i + 1) % facets
        bm.faces.new((rim[i], rim[j], table[i]))
        bm.faces.new((table[i], rim[j], table[j]))
        bm.faces.new((rim[j], rim[i], foot))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, mat(key))


def jewel(tier):
    """Its tier is its shape: a small stone; a larger one, more facets; set in a cup with four claws; a halo of small
    stones round it; four rays under the halo and a light inside it."""
    r = 0.5 if tier == 1 else 0.78
    parts = [brilliant("Stone", r, 6 if tier == 1 else 12, "gem")]
    if tier >= 3:
        # the setting seen from above: a bright bezel round the girdle, its cup under, four claws standing out past it
        parts.append(p.lathe("Cup", [(0.0, -0.66 * r), (0.42 * r, -0.66 * r), (0.96 * r, -0.12 * r), (1.06 * r, 0.0),
                                     (1.02 * r, 0.05 * r)], "steel", thick=0.03))
        parts.append(p.hoop("Bezel", 1.05 * r, 0.1, "steel", 0.02))
        for k in range(4):
            a = math.radians(45 + 90 * k)
            ca, sa = math.cos(a), math.sin(a)
            parts.append(p.tube("Claw", p.curve([(1.2 * r * ca, 1.2 * r * sa, -0.1 * r), (1.18 * r * ca, 1.18 * r * sa, 0.12 * r),
                                                 (0.92 * r * ca, 0.92 * r * sa, 0.3 * r)], 8), [0.12, 0.11, 0.08], "steel", sides=8))
            parts.append(p.ball("Knob", 0.13, "steel", (1.2 * r * ca, 1.2 * r * sa, 0.0)))
    if tier >= 4:
        halo = 1.42 * r
        parts.append(p.hoop("Halo", halo, 0.07, "steel", -0.08 * r))
        for k in range(8):
            a = math.radians(22.5 + 45 * k)
            parts.append(brilliant("Small", 0.2, 6, "gem", (halo * math.cos(a), halo * math.sin(a), 0.02)))
    if tier >= 5:
        rays = []
        for i in range(8):
            a = math.radians(45 * i)
            length = 2.35 * r if i % 2 == 0 else 1.75 * r
            rays.append((length * math.cos(a), length * math.sin(a)))
            b = math.radians(45 * i + 22.5)
            rays.append((0.62 * r * math.cos(b), 0.62 * r * math.sin(b)))
        parts.append(bl.place(p.flat("Rays", rays, 0.08, "gilt", bevel=0.02), (0, 0, -0.16 * r), (90, 0, 0)))
        parts.append(p.hoop("Light", 1.2 * r, 0.035, "lit", 0.0))
    return parts


# --- the renders --------------------------------------------------------------------------------------------------------

STONES = (("Low", "Low forge stone", low, "A rough lump, one crack of light across it."),
          ("Mid", "Mid forge stone", mid, "A whetstone of two grits on the diagonal, a seam of light where they meet."),
          ("HighBlock", "High forge stone, A", high_block, "A polished block standing, bound at its foot and head, its "
           "light behind a window."),
          ("HighIngot", "High forge stone, B", high_ingot, "The stone cut to an ingot and polished, lying, bound in two "
           "bands, a line of light round its top."))
VIEWS = dict(stone=(24.0, -32.0), emblem=(8.0, -18.0), jewel=(55.0, -12.0))   # tilt, spin
FILL = dict(Low=0.64, Mid=0.8, HighBlock=0.84, HighIngot=0.88, Common=0.7, Uncommon=0.8, Rare=0.88)
JEWEL_FILL = (0.48, 0.6, 0.7, 0.8, 0.9)   # tiers 1 to 5: the size climbs with the shape


def shot(out, build, view, fill):
    scene, parts = p.scene_of(build, *VIEWS[view])
    x0, x1, z0, z1 = g.bounds(parts)
    return g.shoot(scene, out, ((x0 + x1) / 2, (z0 + z1) / 2), max(x1 - x0, z1 - z0) / fill)


def renders(out):
    shots = {}
    for key, _, build, _ in STONES:
        shots[key] = shot(out, build, "stone", FILL[key])
    for rarity in EMBLEM:
        for stat in GLYPHS:
            shots[f"{rarity}{stat}"] = shot(out, lambda: emblem(rarity, stat), "emblem", FILL[rarity])
    for tier in range(1, 6):
        shots[f"Jewel{tier}"] = shot(out, lambda: jewel(tier), "jewel", JEWEL_FILL[tier - 1])
    return shots


# --- the sheet ----------------------------------------------------------------------------------------------------------

def plain(sh, x, y, s, picture):
    ch.cell(sh, x, y, s, picture)


def alone(sh, x, y, picture):
    tile = sh.tile(x, y, 24, 24)
    tile.paint(tile.poly(ui.cut_box(0, 0, 24, 24)), c(g.DARK))
    rs.paste(sh.px, rs.shrink(picture, 32 / picture.shape[1]), round((x + 4) * ui.K), round((y + 4) * ui.K))


def sheet(out, shots):
    ui.K = 2
    sh = ui.Sheet(1240, 900, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: forge stones, War Emblems and jewels, in grey (AR31, the block)", g.INK)
    t.text(20, 36, 9.5, "Each read by its shape before a word or a number: a stone's grade, an emblem's rarity and stat, a "
           "jewel's tier. A light is white here; the colour pass gives each kind its own.", g.SOFT_INK)
    # the stones: close, at 38 points, alone at 32 pixels
    y = 64
    t.text(20, y, 11, "Forge stones, Low, Mid, High: worked more as the grade rises (two Highs, for research's pick)", g.INK)
    for i, (key, title, _, words) in enumerate(STONES):
        x = 30 + i * 300
        plain(sh, x, y + 20, 130.0, shots[key])
        plain(sh, x + 142, y + 20, 38.0, shots[key])
        alone(sh, x + 142, y + 70, shots[key])
        t.text(x, y + 158, 10, title, g.INK)
        for j, line in enumerate(textwrap.wrap(words, 50)):
            t.text(x, y + 174 + j * 12, 8.5, line, g.SOFT_INK)
    # the emblems: each rarity close with Attack, then every mark at 38 points in its rarity's cell
    y = 284
    t.text(20, y, 11, "War Emblems, Common, Uncommon, Rare: a six-sided badge, its stat's mark raised; points behind it "
           "by rarity", g.INK)
    for i, rarity in enumerate(EMBLEM):
        x = 30 + i * 300
        ch.cell(sh, x, y + 20, 130.0, shots[f"{rarity}Attack"], rarity)
        for k, stat in enumerate(GLYPHS):
            ch.cell(sh, x + 142 + (k % 2) * 44, y + 20 + (k // 2) * 44, 38.0, shots[f"{rarity}{stat}"], rarity)
        alone(sh, x + 142, y + 110, shots[f"{rarity}Attack"])
        alone(sh, x + 186, y + 110, shots[f"{rarity}Critical"])
        t.text(x, y + 158, 10, f"{rarity}: Attack close; Attack, Defence, Health, Critical at 38 points", g.INK)
    t.text(30, y + 176, 8.5, "Common the badge alone in iron; Uncommon four points behind it in steel; Rare eight in gilt, "
           "a ring of light inside its rim. The face is a dark enamel, the mark pale, so the stat reads on every rarity.",
           g.SOFT_INK)
    # the jewels: the five tiers close, at 38 points and alone
    y = 494
    t.text(20, y, 11, "Jewels, tiers 1 to 5: the shape grows with the tier; the type is its colour, in the colour pass",
           g.INK)
    for tier in range(1, 6):
        x = 30 + (tier - 1) * 238
        plain(sh, x, y + 20, 110.0, shots[f"Jewel{tier}"])
        plain(sh, x + 120, y + 20, 38.0, shots[f"Jewel{tier}"])
        alone(sh, x + 120, y + 70, shots[f"Jewel{tier}"])
        t.text(x, y + 138, 10, f"Tier {tier}", g.INK)
    words = ("Tier 1 a small stone, 6 facets; 2 a larger one, 12 facets; 3 set in a bezel with four claws; 4 a halo of "
             "eight small stones round it; 5 four long rays and four short under the halo, and a ring of light inside it.")
    t.text(30, y + 156, 8.5, words, g.SOFT_INK)
    # the bag's row, among AR6's gear and AR21's chests
    y = 680
    row = (("GearMeigetsu", "Legendary"), ("HighBlock", None), ("RareAttack", "Rare"), ("Jewel5", None), ("Mid", None),
           ("UncommonDefence", "Uncommon"), ("Jewel3", None), ("ChestKeeper", None), ("Low", None),
           ("CommonHealth", "Common"), ("HighIngot", None), ("Jewel1", None))

    def picture(name):
        if name.startswith("Gear"):
            return rs.load(GEAR / f"{name}.png")
        if name.startswith("Chest"):
            return rs.load(CHESTS / f"{name}.png")
        return shots[name]

    t.text(20, y, 11, "In the bag at 38 points, among AR6's gear and AR21's chests (the All tab)", g.INK)
    for i, (name, rarity) in enumerate(row):
        ch.cell(sh, 30 + i * 44, y + 20, 38.0, picture(name), rarity)
    t.text(20, y + 72, 11, "The same row, twice the size", g.INK)
    for i, (name, rarity) in enumerate(row):
        ch.cell(sh, 30 + i * 88, y + 92, 76.0, picture(name), rarity)
    t.text(20, sh.h - 22, 9, "Not here: colour, the stats' marks past these four, the empty sockets' marks, the stack's "
           "count (the bag's), a jewel's tier number.", g.SOFT_INK)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / "upgrades_grey.png")


def main():
    out = bl.out_dir()
    sheet(out, renders(out))


if __name__ == "__main__":
    main()
