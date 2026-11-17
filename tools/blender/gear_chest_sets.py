"""AR6, batch 2: Chest Armor in three designs at each rarity, in grey: a blockout for research's verdict.

One family: armour for the whole torso, seen from the front and a little to the side, closed from the throat to the
hips (the director, 2026-11-17, 13:17: "it need to feels more like a armor that cover the whole torso right now it feel
like a spartiate design"). A gorget and a collar standing in two rings at the throat; broad, square shoulders with the
armholes on the sides, their edges rolled, so it never reads sleeveless; the breastplate with a ridge down its middle and
its lower edge dipping to a point; the belly closed in two lames down to the belt; the fauld's lames over the hips,
arched at the front over the legs. Never the muscled cuirass, never a shirt or skin between plates. Front only: the
pictures are flat (13:18). A design is the body, its lames, and what its chest carries. A rarity keeps the ladder's
rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Cuirass.

Each Legendary's one new form changes the silhouette: Hinode's rays fan out behind the whole body as the sun comes up,
Tsukiyo's crescent moon rises behind its shoulders, Amanogawa wears a sash of stars that falls past its hip.

    blender -b --factory-startup --python tools/blender/gear_chest_sets.py -- build/handoff/Gear/chest_sets

Writes the sheet gear_chest_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 5.0, 18.0     # barely from above, turned a little to show the plate's curve
FILL, DROP = 0.8, 0.0
LEAST = 0.86
FOOT = -0.3                # the breastplate's foot, where the belly's plates begin
WAIST = -0.78              # the belt
CHEST = 0.42               # where the chest carries its stone


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(lames=2, lame_mat=key, rims=None, neck=None, keel=False,
                                                         lozenge=None, studs=None, rivets=False, facets=False,
                                                         belt="leather"), **more))


DESIGNS = (
    design("Iron Chestplate", "Common", "Plain iron, two lames under a leather belt.", "iron"),
    design("Bronze Chestplate", "Common", "Smooth bronze, its collar rolled.", "bronze", neck="bronze",
           lames=1),
    design("Scrap Chestplate", "Common", "Plates beaten flat and riveted, a belt of cord.", "scrap", rivets=True,
           facets=True, belt="cord"),

    design("Lanternsteel Chestplate", "Uncommon", "Bright steel, three lames, a brass rim on each.", "steel", lames=3,
           rims="brass"),
    design("Rowsmith Chestplate", "Uncommon", "A keel down the middle and a brass lozenge on the chest.", "steel",
           keel=True, lozenge="brass"),
    design("Stallguard Chestplate", "Uncommon", "Brass studs round the gorget and down each side, brass rims.", "steel",
           studs="brass", neck="brass", rims="brass"),

    design("Cuirass of Embers", "Rare", "A swelling frame round one stone on the chest, a line round the neck.",
           "blued", neck="filigree", orn="Embers", stone=("stone", 0.13)),
    design("Cuirass of Hoarfrost", "Rare", "A plate cut in facets, a square stone in a spade.", "blued", facets=True,
           neck="filigree", orn="Hoarfrost", stone=("stone", 0.13), cut="square"),
    design("Cuirass of Gales", "Rare", "A vane sweeps back from each side of the belt, the stone on the chest.",
           "blued", lames=1, neck="filigree", orn="Gales", stone=("stone", 0.13)),

    design("Stormcall Cuirass", "Epic", "Filigree hooks curl out either side of the collar. A glowing stone.", "rich",
           trim="filigree", neck="filigree", orn="Stormcall", stone=("glow", 0.17)),
    design("Gloamforge Cuirass", "Epic", "Filigree prongs either side of the collar, three lames, a square glowing stone.",
           "rich", trim="filigree", lames=3, keel=True, orn="Gloamforge", stone=("glow", 0.17), cut="square"),
    design("Nightloom Cuirass", "Epic", "A shuttle lies across the chest, four long lames, a glowing stone.", "rich",
           trim="filigree", lames=4, neck="filigree", orn="Nightloom", stone=("glow", 0.17)),

    design("Hinode, the Sunrise", "Legendary", "Its one new form: rays fan out behind the whole body, the sun's stone "
           "on the chest.", "gilt", trim="ivory", neck="ivory", rims="ivory", orn="rays", stone=("lit", 0.2), edge=True,
           belt="ivory"),
    design("Tsukiyo, the Moonlit Sky", "Legendary", "Its one new form: a crescent moon rises behind its shoulders.", "gilt", trim="ivory", neck="ivory", orn="crescent", stone=("lit", 0.16), edge=True,
           belt="ivory"),
    design("Amanogawa, the Starway", "Legendary", "Its one new form: a sash of stars crosses the chest and falls past "
           "the hip.", "gilt", trim="ivory", rims="ivory", lames=3, orn="sash", stone=("lit", 0.13), edge=True,
           belt="ivory"),
)


# --- the body's shell, by u across (-1 to 1, round the front to just past each side) and z up ----------------------
# Front only: the pictures are flat, seen from the front (the director, 2026-11-17, 13:18: "no need for the back since it
# 2d visual"). Widths and depths go by height, so the armholes scoop in as a real breastplate's do.

TOP, PIT = 1.0, 0.32       # the throat, under the collar; the armpit, at the side
SIDE = 100.0               # how far round the front the shell wraps, each way, in degrees
SCOOP = 0.72               # where the armhole begins, in u: the shoulders broad, the armholes on the sides
VEE = 0.16                 # how far the breastplate's lower edge dips to a point at the middle
RIDGE = 0.05               # the ridge down every breastplate's middle; a keel's is three times it
ARCH = 0.1                 # how far each lower lame of the fauld rises at the front, over the legs
SHOULDER = 1.04            # the shoulders' width to the chest's


def smooth(a, b, x):
    k = min(max((x - a) / (b - a), 0.0), 1.0)
    return k * k * (3 - 2 * k)


def width(z):
    return 0.8 + 0.2 * smooth(FOOT, 0.3, z) + (SHOULDER - 1.0) * smooth(0.5, TOP, z)


def depth(z):
    """The shell's depth: deepest at the chest, turning back a little under the gorget at the top."""
    return 0.5 + 0.12 * smooth(FOOT, 0.3, z) - 0.18 * smooth(0.65, TOP, z)


def top(u):
    """The top edge: level under the collar, sloping a little to the shoulder, then the armhole's scoop to the side."""
    a = abs(u)
    shoulder = TOP - 0.06 * smooth(0.28, SCOOP, a)
    if a <= SCOOP:
        return shoulder
    s = (a - SCOOP) / (1.0 - SCOOP)
    return shoulder - (shoulder - PIT) * math.sqrt(max(0.0, 1 - (1 - s) ** 2))


def at(u, z, keel=False, inset=0.0):
    phi = math.radians(u * SIDE)
    x = width(z) * math.sin(phi) * (1 - inset)
    y = -(depth(z) - inset) * math.cos(phi)
    ridge = RIDGE * (3.0 if keel else 1.0)
    y -= ridge * max(0.0, 1 - abs(u) / 0.3) * smooth(FOOT - VEE, 0.4, z) * (1 - smooth(0.75, TOP, z))
    return (x, y, z)


def foot(u):
    """The breastplate's lower edge, dipping to a point at the middle."""
    return FOOT - VEE * max(0.0, 1 - abs(u) / 0.6) ** 1.3


def shell_point(u, t, keel=False, inset=0.0):
    lo = foot(u)
    return at(u, lo + (top(u) - lo) * t, keel, inset)


def front_at(z, u=0.0):
    x, y, zz = at(u, z)
    return (x, y - 0.04, zz)


def arc_rim(name, radius, minor, key, z, a0, a1, deep):
    t = bl.torus(name, radius, minor, 48, 8, mat(key), arc=a1 - a0)
    bl.place(t, (0, 0, 0), (0, 0, a0 - 90.0))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, deep, 1)), 40.0)


def lame(name, key, z0, z1, r0, r1, deep, arch=0.0, rim=None):
    """A plate round the front between two heights, flaring from r0 to r1, its lower edge rising `arch` at the middle
    over the legs, a rolled edge along it if it has one."""
    def lift(u):
        return arch * max(0.0, 1 - (u / 0.42) ** 2)

    def point(u, v):
        phi = math.radians(u * SIDE)
        r = r0 + (r1 - r0) * v
        return (r * math.sin(phi), -r * deep * math.cos(phi), z0 + (z1 + lift(u) - z0) * v)

    us = [-1.0 + 2.0 * i / 40 for i in range(41)]
    out = [p.sheet_surface(name, key, point, us, [0.0, 0.5, 1.0], thick=0.05)]
    if rim:
        edge = [point(u, 1.0) for u in us[::2]]
        out.append(p.tube("Rim", [(x, y - 0.015, z) for x, y, z in edge], 0.03, rim, sides=6))
    return out


def plate(d):
    key, trim, parts = d["key"], d["trim"], []
    across = 9 if d["facets"] else 25
    us = [-1.0 + 2.0 * i / (across - 1) for i in range(across)]
    ts = [j / 16 for j in range(17)]
    parts.append(p.sheet_surface("Plate", key, lambda u, t: shell_point(u, t, d["keel"]), us, ts, thick=0.06))
    # the inside, seen through the armholes, is lined dark: an empty garment, never a body
    parts.append(p.sheet_surface("Liner", "liner", lambda u, t: shell_point(u, t, inset=0.05), us, ts,
                                 thick=0.02))
    edge = d["neck"] or key
    # the armholes' rolled edges, built, so it never reads sleeveless
    for side in (-1, 1):
        hole = [shell_point(side * (SCOOP - 0.04 + k * (1.0 - SCOOP + 0.04) / 10), 1.0) for k in range(11)]
        parts.append(p.tube("Armhole", p.curve([(x, y - 0.02, z) for x, y, z in hole], 20), 0.055, edge, sides=8))
    # the gorget: a plate sloping over the top of the breastplate, and the collar standing from it at the throat, flared
    # and rolled at its top
    ring = 0.82
    parts.append(p.lathe("Gorget", [(0.7, TOP - 0.16), (0.58, TOP - 0.02), (0.46, TOP + 0.06)], key, thick=0.05,
                         deep=0.7, steps=48))
    parts.append(arc_rim("GorgetEdge", 0.7, 0.035, edge, TOP - 0.16, -180.0, 180.0, 0.7))
    # the collar in two rings, each stepping in from the one below, each edge rolled
    for k, (r0, r1, z0, z1) in enumerate(((0.5, 0.47, TOP + 0.0, TOP + 0.15), (0.45, 0.43, TOP + 0.12, TOP + 0.26))):
        parts.append(p.lathe("Collar", [(r0, z0), (r1, z1)], key, thick=0.05, deep=ring, steps=40))
        parts.append(arc_rim("Neck", r1 + 0.005, 0.035, d["neck"] or key, z1, -180.0, 180.0, ring))
    parts.append(p.lathe("CollarLiner", [(0.44, TOP + 0.02), (0.39, TOP + 0.24)], "liner", thick=0.015, deep=ring,
                         steps=40))
    if d["edge"]:
        parts.append(arc_rim("Edge", 0.47, 0.02, "lit", TOP + 0.08, -150.0, 150.0, ring * 1.02))

    # the breastplate's lower edge rolled, and the belly closed under it down to the belt in two lames, each stepping
    # out from under the one above
    hem = [shell_point(-1.0 + 2.0 * i / 30, 0.0, d["keel"]) for i in range(31)]
    parts.append(p.tube("Hem", [(x, y - 0.02, z) for x, y, z in hem], 0.04, d["rims"] or edge, sides=6))
    belly = depth(FOOT - VEE) / width(FOOT - VEE)
    mid = (FOOT + WAIST) / 2 - 0.04
    for k, (z0, z1) in enumerate(((FOOT - 0.02, mid), (mid + 0.05, WAIST + 0.02))):
        parts += lame("Belly", d["lame_mat"], z0, z1, 0.75 - 0.02 * k, 0.84 - 0.02 * k, belly, rim=d["rims"])

    # the belt, and the fauld's lames flaring over the hips
    w0 = width(WAIST)
    deep = depth(WAIST) / w0
    parts.append(p.lathe("Belt", [(w0 + 0.03, WAIST - 0.14), (w0 + 0.03, WAIST + 0.02)], d["belt"], -SIDE, SIDE,
                         deep=deep, thick=0.05))
    fauld = max(2, d["lames"])
    for k in range(fauld):
        hi, lo = WAIST - 0.1 - 0.2 * k, WAIST - 0.36 - 0.2 * k
        parts += lame("Lame", d["lame_mat"], hi, lo, w0 + 0.02 + 0.07 * k, w0 + 0.1 + 0.07 * k, deep,
                      arch=ARCH * (k + 1), rim=d["rims"])

    if d["lozenge"]:
        y = front_at(CHEST)[1]
        parts.append(p.flat("Lozenge", [(0, CHEST + 0.24), (0.18, CHEST), (0, CHEST - 0.24), (-0.18, CHEST)], 0.06,
                            d["lozenge"], y=y))
    if d["studs"]:
        for turn in (-60, -30, 0, 30, 60):
            r = math.radians(turn)
            parts.append(p.ball("Stud", 0.05, d["studs"], (0.62 * math.sin(r), -0.62 * 0.7 * math.cos(r) - 0.04,
                                                             TOP - 0.06)))
        for side in (-1, 1):
            for z in (0.1, -0.1, FOOT + 0.1):
                x, y, zz = at(0.82 * side, z)
                parts.append(p.ball("Stud", 0.06, d["studs"], (x, y - 0.02, zz)))
    if d["rivets"]:
        for u in (-0.6, 0.0, 0.6):
            for z in (FOOT + 0.12, 0.25, 0.62):
                if z < top(u) - 0.08:
                    x, y, zz = at(u, z)
                    parts.append(p.ball("Rivet", 0.05, key, (x, y - 0.01, zz), segments=8, rings=5))

    # what the chest carries: the set's ornament round its stone, or a Legendary's new form
    orn, stone_at = d["orn"], front_at(CHEST)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.44, (0, CHEST)), 0.06, trim, y=stone_at[1] + 0.03))
    elif orn == "Gales":
        for side in (-1, 1):
            x, y, z = at(0.9 * side, WAIST - 0.06)
            vane = p.shifted(p.VANE, x + 0.05 * side, z - 0.05, 1.0 * side, 0.9)
            parts.append(p.flat("Vane", vane, 0.07, trim, y=y * 0.4))
    elif orn in ("Stormcall", "Gloamforge"):
        # laid on the upper chest either side of the collar, never standing off the shoulders
        for side in (-1, 1):
            x, y, z = front_at(0.62, 0.4 * side)
            crest = p.shifted(p.set_ornament(orn, 0.3, (0, 0)), x, z, side, 1.0)
            parts.append(p.flat("Crest", crest, 0.06, trim, y=y - 0.02))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, CHEST, 2.0, 1.2), 0.08, trim, y=stone_at[1] + 0.05))
    elif orn == "rays":
        # the sun coming up behind the whole body: its rays fan out past the shoulders and over the collar
        for k, angle in enumerate(range(-84, 85, 21)):
            length = 1.45 + 0.35 * math.cos(math.radians(angle))
            ray = p.turned(p.leaf(length, 0.24), -angle, (0, 0))
            parts.append(p.flat("Ray", p.shifted(ray, 0, 0.35), 0.06, trim if k % 2 else key, y=0.42))
    elif orn == "crescent":
        outer = [(1.0 * math.cos(math.radians(a)), 1.0 * math.sin(math.radians(a))) for a in range(190, 351, 8)]
        inner = [(0.86 * math.cos(math.radians(a)), 0.3 + 0.86 * math.sin(math.radians(a))) for a in range(342, 197, -8)]
        parts.append(p.flat("Crescent", p.shifted(outer + inner, 0, TOP + 0.55, 1.55, 1.15), 0.09, trim, y=0.42))
    elif orn == "sash":
        path = [at(0.55, 0.88), at(0.3, 0.6), at(-0.2, 0.25), at(-0.7, FOOT + 0.05)]
        path = [(x, y - 0.06, z) for x, y, z in path] + [(-0.95, -0.3, WAIST - 0.2), (-1.08, -0.25, WAIST - 0.6),
                                                           (-1.05, -0.2, WAIST - 0.95)]
        parts.append(p.tube("Sash", p.curve(path, 28), 0.1, trim, sides=8))
        for k, (x, y, z) in enumerate(p.curve(path, 9)[1:-1]):
            parts.append(p.ball("Star", 0.07 if k % 2 else 0.05, "lit", (x, y - 0.1, z)))
    parts += p.stone_of(d, 1.0, stone_at)
    return parts


def build(d):
    return p.scene_of(lambda: plate(d), TILT, SPIN)


WORDS = dict(
    file="gear_chest_sets.png",
    title="Grow your Anime: Chest Armor in three designs at each rarity, in grey (AR6, batch 2)",
    lead="Armour for the whole torso, from the front and a little to the side: a collar standing at the throat, broad "
         "shoulders, the breastplate's edge dipping to a point, the belly in lames, the fauld arched over the hips. A "
         "design is the body, its lames and what the chest carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is Cuirass.",
        "Each Legendary's one new form: Hinode (sunrise), rays fanning out behind the whole body; Tsukiyo (a moonlit "
        "night), a crescent rising behind the shoulders; Amanogawa (the river of stars), a sash of stars past the hip.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as chest armour, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
