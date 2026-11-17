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

The colour pass (after research's verdict and its second look, 2026-11-17) gives each kind its own colour, as AR6's gear
is finished (gear_icons.py: a key's paint, then a metal's tones laid by how bright it renders, then the finish):
  - the stones in the forge's light, orange to white-hot, never deep red: a warm grey lump, a whetstone of slate and
      sand, a polished dark ingot in brass bands;
  - the emblems in AR6's ladder of metals, so a Rare never reads as a Legendary's gold: Common iron, Uncommon steel,
      Rare blued steel; a deep violet enamel, the six stats' marks in ivory (TR38: Strength, Endurance, Health, Attack,
      Defence, Critical);
  - the jewels in their type's colour, the stone's own facets toned dark to light: Critical Damage the crit number's
      gold (UIKit Critical), Critical Immunity a cool steel blue, Lifesteal a clear rose-violet, never a blood red; the
      setting a dark gunmetal, so the stone stays the brightest thing;
  - the empty sockets' marks on the item card, as AR22's slots' are: the badge's and the stone's own form, white on
      alpha, inset, for the card to tint.

Run: blender --background --factory-startup --python tools/blender/upgrade_icons.py -- build/handoff/UI/upgrades [colour]
"""
import json
import math
import sys
import textwrap
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import bvhtree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import chest_icons as ch  # noqa: E402
import gear_icons as gi  # noqa: E402
import gear_parts as p  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import rook_sheet as rs  # noqa: E402
import slot_marks as sl  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
GEAR = ROOT / "build" / "handoff" / "UI" / "gear" / "images"
CHESTS = ROOT / "build" / "handoff" / "UI" / "chests" / "images"
mat = p.mat
for key, value in (("rock", 0.4), ("grit_dark", 0.32), ("grit_pale", 0.62), ("polished", 0.5), ("enamel", 0.24),
                   ("gem", 0.9), ("setting", 0.4)):
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


def frustum(name, foot, top, h, key, z=0.0):
    """A block with a rectangular foot and a smaller top, its sides sloping: (across, deep) at each."""
    bm = bmesh.new()
    corners = [bm.verts.new((sx * a / 2, sy * b / 2, z + dz)) for (a, b), dz in ((foot, 0.0), (top, h))
               for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    bm.faces.new(corners[:4])
    bm.faces.new(corners[4:])
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((corners[i], corners[j], corners[4 + j], corners[4 + i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bl.object_from_bmesh(name, bm, mat(key))


def high():
    """The stone cut to an ingot and polished, lying, bound in two bands that follow its slope, a line of light round
    the edge of its top, flush with it (research's pick of B, and its fix: closed, not a trough)."""
    foot, top, h = (2.5, 1.35), (1.9, 0.8), 0.78
    parts = [bl.bevel(frustum("Ingot", foot, top, h, "polished"), 0.06, 1)]
    for x in (-0.62, 0.62):  # two bands across it, as wide as the stone at every height and a little proud
        band = frustum("Band", (0.2, foot[1] + 0.08), (0.2, top[1] + 0.08), h + 0.02, "brass", z=-0.01)
        parts.append(bl.bevel(bl.place(band, (x, 0, 0)), 0.02, 1))
    a, b = top[0] - 0.08, top[1] - 0.08
    for (x0, y0), (x1, y1) in (((-a / 2, -b / 2), (a / 2, -b / 2)), ((a / 2, -b / 2), (a / 2, b / 2)),
                               ((a / 2, b / 2), (-a / 2, b / 2)), ((-a / 2, b / 2), (-a / 2, -b / 2))):
        length = math.hypot(x1 - x0, y1 - y0) + 0.08
        bar = bl.box("Light", (length, 0.08, 0.03) if y0 == y1 else (0.08, length, 0.03), mat("lit"))
        parts.append(bl.place(bar, ((x0 + x1) / 2, (y0 + y1) / 2, h + 0.003)))
    return parts


# --- War Emblems --------------------------------------------------------------------------------------------------------

def hexagon(radius):
    return [(radius * math.sin(math.radians(a)), radius * math.cos(math.radians(a))) for a in range(0, 360, 60)]


def fitted(points, scale):
    """A drawn outline centred on its own box and scaled, so a mark that doesn't mirror sits in the face's middle."""
    xs, zs = [x for x, _ in points], [z for _, z in points]
    mx, mz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
    return [((x - mx) * scale, (z - mz) * scale) for x, z in points]


# A stat's mark, drawn from the front at about 0.5 of the badge, each from its right half where it mirrors. Strength
# and Endurance are new in the colour pass (TR38's six at launch): Strength, power, a flexed arm, fist up; Endurance,
# toughness, an anvil that takes every blow, its horn to the left. Neither shares an outline with the other four.
GLYPHS = dict(
    # the fist curled in over a round biceps, the gap between them the read (a square fist upright read as a boot)
    Strength=fitted([(-0.62, -0.50), (0.30, -0.52), (0.52, -0.44), (0.62, -0.26), (0.60, 0.00), (0.52, 0.22),
                     (0.50, 0.30), (0.56, 0.40), (0.54, 0.58), (0.40, 0.68), (0.18, 0.66), (0.04, 0.58), (0.0, 0.46),
                     (0.06, 0.38), (0.18, 0.36), (0.26, 0.30), (0.28, 0.12), (0.22, 0.0), (0.10, 0.12), (-0.04, 0.28),
                     (-0.20, 0.32), (-0.38, 0.24), (-0.54, 0.06), (-0.62, -0.10)], 0.86),
    Endurance=fitted([(-0.66, 0.32), (-0.34, 0.44), (0.58, 0.44), (0.58, 0.16), (0.30, 0.12), (0.20, -0.14),
                      (0.40, -0.30), (0.46, -0.48), (-0.40, -0.48), (-0.34, -0.30), (-0.16, -0.14), (-0.24, 0.12),
                      (-0.40, 0.20)], 0.86),
    Attack=p.mirrored([(0.0, 0.6), (0.08, 0.46), (0.08, -0.16), (0.27, -0.16), (0.27, -0.26), (0.06, -0.26), (0.06, -0.44),
                       (0.11, -0.5), (0.06, -0.57), (0.0, -0.6)]),
    Defence=p.mirrored([(0.0, 0.5), (0.4, 0.5), (0.42, 0.1), (0.33, -0.22), (0.16, -0.44), (0.0, -0.56)]),
    Health=p.mirrored([(0.0, 0.26), (0.12, 0.44), (0.3, 0.5), (0.46, 0.4), (0.51, 0.2), (0.43, -0.03), (0.22, -0.28),
                       (0.0, -0.5)]),
    Critical=p.star(4, 0.62, 0.17, turn=90.0),
)
# Rare is blued steel, AR6's Rare metal, not the grey's gilt: in colour a gilt badge reads as a Legendary's gold.
EMBLEM = dict(Common=("iron", 0, None), Uncommon=("steel", 4, (1.5, 0.62, 45.0)), Rare=("blued", 8, (1.52, 0.86, 90.0)))


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
    # Research's must-fix (2026-11-17): the stone is the hero at every tier. Its facets and table are the brightest thing;
    # the setting is thin and darker; the halo is small faceted stones with gaps, close in, never a ring (it read a cog).
    r = 0.5 if tier == 1 else 0.78
    parts = [brilliant("Stone", r, 6 if tier == 1 else 12, "gem")]
    if tier >= 3:
        # the setting seen from above: a thin dark bezel at the girdle, its cup under, four small claws over the edge
        parts.append(p.lathe("Cup", [(0.0, -0.66 * r), (0.42 * r, -0.66 * r), (0.96 * r, -0.12 * r), (1.04 * r, 0.0),
                                     (1.02 * r, 0.04 * r)], "setting", thick=0.03))
        parts.append(p.hoop("Bezel", 1.03 * r, 0.045, "setting", 0.0))
        for k in range(4):
            a = math.radians(45 + 90 * k)
            ca, sa = math.cos(a), math.sin(a)
            # dark prongs over the bright crown: the stone reads set, and stays the brightest thing
            parts.append(p.tube("Claw", p.curve([(1.07 * r * ca, 1.07 * r * sa, -0.08 * r), (1.04 * r * ca, 1.04 * r * sa, 0.12 * r),
                                                 (0.72 * r * ca, 0.72 * r * sa, 0.3 * r)], 8), [0.1, 0.095, 0.075], "setting", sides=8))
    if tier >= 4:
        halo = 1.24 * r
        for k in range(10):
            a = math.radians(18 + 36 * k)
            parts.append(brilliant("Small", 0.11, 6, "gem", (halo * math.cos(a), halo * math.sin(a), -0.02)))
    if tier >= 5:
        rays = []
        for i in range(8):
            a = math.radians(45 * i)
            length = 2.2 * r if i % 2 == 0 else 1.65 * r
            rays.append((length * math.cos(a), length * math.sin(a)))
            b = math.radians(45 * i + 22.5)
            rays.append((1.12 * r * math.cos(b), 1.12 * r * math.sin(b)))
        parts.append(bl.place(p.flat("Rays", rays, 0.05, "setting", bevel=0.015), (0, 0, -0.2 * r), (90, 0, 0)))
        parts.append(p.hoop("Light", 0.8 * r, 0.03, "lit", 0.4 * r * 0.2 / 0.44 + 0.02))   # on the crown, inside the girdle
    return parts


# --- the renders --------------------------------------------------------------------------------------------------------

STONES = (("Low", "Low forge stone", low, "A rough lump, one crack of light across it."),
          ("Mid", "Mid forge stone", mid, "A whetstone of two grits on the diagonal, a seam of light where they meet."),
          ("High", "High forge stone", high, "The stone cut to an ingot and polished, lying, bound in two bands, a line "
           "of light round its top's edge."))
VIEWS = dict(stone=(24.0, -32.0), emblem=(8.0, -18.0), jewel=(55.0, -12.0))   # tilt, spin
FILL = dict(Low=0.64, Mid=0.8, High=0.88, Common=0.7, Uncommon=0.8, Rare=0.88)
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
    t.text(20, y, 11, "Forge stones, Low, Mid, High: worked more as the grade rises (High is research's B, its top closed)",
           g.INK)
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
        alone(sh, x + 236, y + 20, shots[f"{rarity}Attack"])
        alone(sh, x + 236, y + 50, shots[f"{rarity}Critical"])
        t.text(x, y + 158, 10, f"{rarity}: Attack close; every mark at 38 points", g.INK)
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
    words = ("The stone leads at every tier (research's fix). Tier 1 a small stone, 6 facets; 2 a larger one, 12 facets; "
             "3 in a thin dark bezel with four small claws; 4 ten small stones round it, apart; 5 eight rays under them, "
             "and a line of light on its crown.")
    t.text(30, y + 156, 8.5, words, g.SOFT_INK)
    # the bag's row, among AR6's gear and AR21's chests
    y = 680
    row = (("GearMeigetsu", "Legendary"), ("High", None), ("RareAttack", "Rare"), ("Jewel5", None), ("Mid", None),
           ("UncommonDefence", "Uncommon"), ("Jewel3", None), ("ChestKeeper", None), ("Low", None),
           ("CommonHealth", "Common"), ("Jewel4", None), ("Jewel1", None))

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


# --- the colour pass ----------------------------------------------------------------------------------------------------

# A key's paint: its colour, how metal it is, how rough. The metals are AR6's own (gear_icons.PAINT).
# The stones are one family of dark stone, so the forge's light carries all three: a warm grey lump; a whetstone of a
# dark and a pale grit, both stone, never a tan that reads as wood; a near-black ingot, polished, a value above the
# cell's ground. A tan grit read as a wooden block, and a navy ingot as a cushioned bench.
PAINT = dict(
    rock=("#6A625D", 0.0, 0.9), grit_dark=("#4C5058", 0.0, 0.85), grit_pale=("#A29A8E", 0.0, 0.85),
    polished=("#4A4850", 0.3, 0.18), brass=gi.PAINT["brass"], lit=("#FFC27A", 0.0, 0.3),
    iron=gi.PAINT["iron"], steel=gi.PAINT["steel"], blued=gi.PAINT["blued"], enamel=("#2F2756", 0.0, 0.25),
    ivory=gi.PAINT["ivory"], gem=("#CFCFD4", 0.0, 0.12), setting=("#6A6E78", 0.35, 0.35))
# The forge's light round a lit line: its face white-hot, its light orange, never a deep red (the content check).
FORGE = ("#FF8A2A", (10, 1.0), (28, 0.6))   # wide enough to show orange at 38 points, the line itself kept thin
# A jewel's type: its stone's tones, from its facets' shade to their light, and the light of tier 5's ring. A cut gem's
# colour, never a rarity's: a jewel's cell has no rarity frame (research, AR31's verdict). `words` is the type's colour
# for its line on the card and in the haul.
JEWELS = {
    "Critical Damage": dict(tones=((0.0, "#3A2606"), (0.35, "#A8740E"), (0.7, "#FFCF4D"), (1.0, "#FFF8DC")),
                            light="#FFE08A", words="#FFCF4D"),
    "Critical Immunity": dict(tones=((0.0, "#0E1A2C"), (0.35, "#2F5A8A"), (0.7, "#8DB4DE"), (1.0, "#F2F8FF")),
                              light="#CFE4FF", words="#9CC2EA"),
    "Lifesteal": dict(tones=((0.0, "#2A0F33"), (0.35, "#86308C"), (0.7, "#E07AD6"), (1.0, "#FFE6FA")),
                      light="#F4B8EE", words="#E98ADF"),
}
STONE_WORDS = "#FFB15C"   # a stone's line in the haul (AR24): the forge's orange
LOOK = dict(Low=dict(light=FORGE), Mid=dict(light=FORGE), High=dict(sheen={"polished"}, light=FORGE),
            Common=dict(lift="iron"), Uncommon=dict(sheen={"steel"}),
            Rare=dict(tone={"blued": gi.TEMPER["blued"]}, light=("#E6F0FF", (4, 0.7), (10, 0.25))))


def paint(key):
    return PAINT[key]


def mask(scene, out, keys):
    """What of `keys` shows, flat, 0 to 1."""
    for m in bpy.data.materials:
        m.diffuse_color = (1, 1, 1, 1) if m.name[5:] in keys else (0, 0, 0, 1)
    rs.workbench(scene, g.SIZE, g.SIZE, flat=True)
    px = gi.render(scene, out)
    return px[..., 0] * px[..., 3]


def coloured(out, build, view, fill, look):
    """As AR6's gear is shot in colour: lit; a metal's or a stone's tones laid by how bright it renders; a polished
    streak; then the finish, with the light of what's lit."""
    g.PAINT = paint
    scene, parts = p.scene_of(build, *VIEWS[view])
    x0, x1, z0, z1 = g.bounds(parts)
    cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(cam)
    scene.camera, cam.data.type, cam.data.clip_end = cam, "ORTHO", 200
    cam.data.ortho_scale = max(x1 - x0, z1 - z0) / fill
    cam.location, cam.rotation_euler = ((x0 + x1) / 2, -40, (z0 + z1) / 2), (math.radians(90), 0, 0)
    rs.workbench(scene, g.SIZE, g.SIZE)
    shading = scene.display.shading
    shading.show_specular_highlight = True
    shading.cavity_ridge_factor, shading.cavity_valley_factor = 1.8, 1.3
    shading.curvature_ridge_factor, shading.curvature_valley_factor = 1.5, 1.2
    px = gi.render(scene, out)
    lit = mask(scene, out, {"lit"})
    for key, metal in look.get("tone", {}).items():
        px = gi.tempered(px, mask(scene, out, {key}), metal)
    if look.get("lift"):
        px = gi.lifted(px, mask(scene, out, {look["lift"]}), gi.LIFT[look["lift"]])
    if look.get("sheen"):
        px = gi.sheened(px, *gi.normals(scene, out, look["sheen"]))
    if look.get("facets"):
        px = faceted(px, *gi.normals(scene, out, {"gem"}), look["facets"], VIEWS[view][0])
    g.PAINT = None
    return gi.finish(px, lit, np.zeros(lit.shape, np.float32), "#FFFFFF", look.get("light", FORGE))


FACET_LIGHT = np.array([-0.5, 0.7, 0.5]) / np.linalg.norm([-0.5, 0.7, 0.5])   # from the upper left, toward the camera


def faceted(px, n, where, tones, tilt):
    """A cut stone's facets, each its own value, so the stone reads cut, not domed: lit from the upper left with its
    contrast pushed, a play of light round the crown so no two neighbours match, the table a steady light. Then the
    type's tones, dark to near white. `n` is the camera's normals (x right, y up, z toward the camera)."""
    t = math.radians(tilt)
    table = np.array([0.0, math.cos(t), math.sin(t)])   # the stone's up, as the view lays it
    across, up = np.array([1.0, 0.0, 0.0]), np.cross(table, [1.0, 0.0, 0.0])
    az = np.arctan2(n @ up, n @ across)
    v = 0.12 + 0.8 * np.clip((n @ FACET_LIGHT - 0.15) / 0.75, 0, 1) + 0.2 * np.cos(6 * az + 0.9)
    v = np.where(n @ table > 0.995, 0.8, np.clip(v, 0, 1))
    at, stops = [s[0] for s in tones], np.array([c(s[1])[:3] for s in tones])
    tone = np.stack([np.interp(v, at, stops[:, i]) for i in range(3)], axis=-1).astype(np.float32)
    px = px.copy()
    px[..., :3] += (tone - px[..., :3]) * where[..., None]
    return px


def badge():
    """An emblem's socket: the badge's plate and face alone."""
    return [p.flat("Plate", hexagon(1.0), 0.22, "iron", y=0.0, bevel=0.04),
            p.flat("Face", hexagon(0.85), 0.08, "enamel", y=-0.13, bevel=0.015)]


def setting():
    """A jewel's socket: tier 3's setting with no stone in it, its cup, bezel and four claws (a stone's own form had
    no seams to draw, and read as a plain oval)."""
    parts = jewel(3)
    bpy.data.objects.remove(parts.pop(0), do_unlink=True)
    return parts


def renders_colour(out):
    """Every delivered picture, by its file's stem, and the sockets' two marks."""
    shots = {}
    for key, _, build, _ in STONES:
        shots[f"Stone{key}"] = coloured(out, build, "stone", FILL[key], LOOK[key])
    for rarity in EMBLEM:
        for stat in GLYPHS:
            shots[f"Emblem{rarity}{stat}"] = coloured(out, lambda: emblem(rarity, stat), "emblem", FILL[rarity],
                                                      LOOK[rarity])
    for kind, j in JEWELS.items():
        look = dict(facets=j["tones"], light=(j["light"], (4, 0.7), (10, 0.3)))
        for tier in range(1, 6):
            shots[f"Jewel{kind.replace(' ', '')}{tier}"] = coloured(out, lambda: jewel(tier), "jewel",
                                                                     JEWEL_FILL[tier - 1], look)
    sockets = {}
    for name, build, view, fill in (("SocketEmblem", badge, "emblem", 0.8),
                                    ("SocketJewel", setting, "jewel", 0.8)):
        shot = coloured(out, build, view, fill, dict(light=FORGE))
        sockets[name] = sl.mark(name, px=rs.shrink(shot, gi.ICON / shot.shape[0]))
    return shots, sockets


def big_alone(sh, x, y, picture, ground=None):
    """A delivered picture at 64 pixels over dark, as the content check reads it."""
    tile = sh.tile(x, y, 34, 34)
    tile.paint(tile.poly(ui.cut_box(0, 0, 34, 34)), c(ground or g.DARK))
    rs.paste(sh.px, rs.shrink(picture, 64 / picture.shape[1]), round((x + 1) * ui.K), round((y + 1) * ui.K))


def sheet_colour(out, shots, sockets):
    ui.K = 2
    sh = ui.Sheet(1240, 1300, g.GROUND)
    t = sh.tile(0, 0, sh.w, sh.h)
    t.text(20, 12, 15, "Grow your Anime: forge stones, War Emblems and jewels, in colour (AR31)", g.INK)
    t.text(20, 36, 9.5, "Each read by its shape, then its colour: a stone's grade in the forge's light, an emblem's rarity "
           "in AR6's metals and its stat's mark, a jewel's tier by its shape and its type by its colour.", g.SOFT_INK)
    y = 64
    t.text(20, y, 11, "Forge stones, Low, Mid, High: the forge's light, orange to white-hot", g.INK)
    for i, (key, title, _, words) in enumerate(STONES):
        x = 30 + i * 300
        plain(sh, x, y + 20, 130.0, shots[f"Stone{key}"])
        plain(sh, x + 142, y + 20, 38.0, shots[f"Stone{key}"])
        alone(sh, x + 142, y + 70, shots[f"Stone{key}"])
        t.text(x, y + 158, 10, title, g.INK)
        for j, line in enumerate(textwrap.wrap(words, 50)):
            t.text(x, y + 174 + j * 12, 8.5, line, g.SOFT_INK)
    y = 284
    t.text(20, y, 11, "War Emblems, Common iron, Uncommon steel, Rare blued steel: the six stats at launch (TR38)", g.INK)
    for i, rarity in enumerate(EMBLEM):
        x = 30 + i * 400
        ch.cell(sh, x, y + 20, 130.0, shots[f"Emblem{rarity}Strength"], rarity)
        for k, stat in enumerate(GLYPHS):
            ch.cell(sh, x + 142 + (k % 2) * 44, y + 20 + (k // 2) * 44, 38.0, shots[f"Emblem{rarity}{stat}"], rarity)
        for k, stat in enumerate(GLYPHS):
            alone(sh, x + 236 + (k % 2) * 30, y + 20 + (k // 2) * 30, shots[f"Emblem{rarity}{stat}"])
        t.text(x, y + 158, 10, f"{rarity}: Strength close; then each at 38 points, and alone at 32 px", g.INK)
    t.text(30, y + 176, 8.5, "In each grid: Strength (a flexed arm), Endurance (an anvil), Health (a heart), Attack (a "
           "sword), Defence (a shield), Critical (a burst). The face a deep violet enamel, the mark ivory.", g.SOFT_INK)
    y = 494
    t.text(20, y, 11, "Jewels, tiers 1 to 5 by shape, three types by colour", g.INK)
    for row, kind in enumerate(JEWELS):
        yy = y + 20 + row * 96
        t.text(30, yy + 30, 10, kind, g.INK)
        for tier in range(1, 6):
            x = 150 + (tier - 1) * 210
            stem = f"Jewel{kind.replace(' ', '')}{tier}"
            plain(sh, x, yy, 84.0, shots[stem])
            plain(sh, x + 92, yy, 38.0, shots[stem])
            alone(sh, x + 92, yy + 46, shots[stem])
    t.text(30, y + 312, 8.5, "Critical Damage the crit number's gold, Critical Immunity a cool steel blue, Lifesteal a clear "
           "rose-violet. The setting is a dark gunmetal, so the stone is the brightest thing at every tier.", g.SOFT_INK)
    y = 834
    t.text(20, y, 11, "The item card's empty sockets, as AR22's slots: the form, tinted; beside each, a filled one", g.INK)
    x = 30
    for name, filled, rarity in (("SocketEmblem", "EmblemRareAttack", "Rare"), ("SocketJewel", "JewelLifesteal3", None)):
        for s in (32.0, 24.0):
            sl.cell(sh, x, y + 22, s, sockets[name])
            ch.cell(sh, x + s + 8, y + 22, s, shots[filled], rarity)
            x += 2 * s + 30
    t.text(30, y + 64, 8.5, "Each at 32 and 24 points, the stand-in socket A's slot; the card's own socket is Faber's.",
           g.SOFT_INK)
    y = 924
    row = (("GearMeigetsu", "Legendary"), ("StoneHigh", None), ("EmblemRareStrength", "Rare"), ("JewelLifesteal5", None),
           ("StoneMid", None), ("EmblemUncommonEndurance", "Uncommon"), ("JewelCriticalImmunity3", None),
           ("ChestKeeper", None), ("StoneLow", None), ("EmblemCommonHealth", "Common"), ("JewelCriticalDamage4", None),
           ("JewelCriticalDamage1", None))

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
    y = 1110
    t.text(20, y, 11, f"Every picture as uploaded, at 64 px over dark ({len(shots)}), and the two sockets' marks over the "
           "card's tint", g.INK)
    for i, (name, shot) in enumerate(shots.items()):
        big_alone(sh, 30 + (i % 33) * 36, y + 20 + (i // 33) * 38, shot)
    for i, (name, m) in enumerate(sockets.items()):
        tinted = sl.tinted(m, 64)
        big_alone(sh, 30 + (len(shots) % 33 + i) * 36, y + 20 + (len(shots) // 33) * 38, tinted)
    for layer in ui.text_layers(sh.px.shape[1], sh.px.shape[0], sh.items).values():
        rs.paste(sh.px, layer, 0, 0)
    rs.save(sh.px, out / "upgrades_colour.png")


def deliver(out, shots, sockets):
    """The pictures at 256 pixels, as AR6's gear, the sockets' marks at 128 as AR22's, and their json."""
    (out / "images").mkdir(exist_ok=True)
    for stem, shot in shots.items():
        gi.keep(rs.shrink(shot, gi.ICON / shot.shape[0]), out / "images" / f"{stem}.png")
    for stem, m in sockets.items():
        rs.save(m, out / "images" / f"{stem}.png")
    data = dict(
        note="AR31's pictures, for TR37's Stones tab, TR38's War Emblems and TR39's Jewels. Each is laid as a gear "
             "picture is: its square 0.94 of the cell, centred. An emblem takes its rarity's cell, as an item does; a "
             "stone's and a jewel's cell keep the plain edge an empty cell has, with no rarity's bar, rim or light. The "
             "tier's number and the stack's count are the bag's. `words` is the colour of a line naming one (the item "
             "card, AR24's haul). The sockets' marks are white on alpha, for the item card to tint at `tint` and "
             "`transparency`, as AR22's slots are.",
        pixels=[gi.ICON, gi.ICON],
        stones={key: f"images/Stone{key}.png" for key, *_ in STONES},
        emblems={rarity: {stat: f"images/Emblem{rarity}{stat}.png" for stat in GLYPHS} for rarity in EMBLEM},
        jewels={kind: [f"images/Jewel{kind.replace(' ', '')}{tier}.png" for tier in range(1, 6)] for kind in JEWELS},
        words=dict(stones=STONE_WORDS, jewels={kind: j["words"] for kind, j in JEWELS.items()}),
        sockets=dict(pixels=[sl.SIDE, sl.SIDE], tint=sl.TINT, transparency=round(1 - sl.OPACITY, 2),
                     emblem="images/SocketEmblem.png", jewel="images/SocketJewel.png"),
    )
    (out / "upgrade_icons.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("wrote", out / "upgrade_icons.json")


def main():
    out = bl.out_dir()
    if "colour" in sys.argv[sys.argv.index("--") + 1:]:
        shots, sockets = renders_colour(out)
        sheet_colour(out, shots, sockets)
        deliver(out, shots, sockets)
        return
    sheet(out, renders(out))


if __name__ == "__main__":
    main()
