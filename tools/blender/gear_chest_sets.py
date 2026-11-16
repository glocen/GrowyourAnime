"""AR6, batch 2: Chest Armor in three designs at each rarity, in grey: a blockout for research's verdict.

One family: a breastplate seen from the front and a little to the side: a shell cut to a torso, its neck scooped, its
arms cut away, the back plate showing over the neck, a belt at the waist and the fauld's lames below. A torso's
outline, so it reads as nothing else. A design is the plate, its lames, and what its chest carries. A rarity keeps the
ladder's rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Cuirass.

Each Legendary's one new form changes the silhouette: Hinode's rays stand behind its collar as the sun comes up,
Tsukiyo's collar rises into a crescent moon's two horns, Amanogawa wears a sash of stars that falls past its hip.

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
TILT, SPIN = 8.0, 22.0     # a little from above, turned a little to show the plate's curve
FILL, DROP = 0.8, 0.0
LEAST = 0.86
FOOT = -0.8                # the plate's foot, at the belt
CHEST = 0.3                # where the chest carries its stone


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(lames=2, lame_mat=key, rims=None, neck=None, keel=False,
                                                         lozenge=None, studs=None, rivets=False, facets=False,
                                                         belt="leather"), **more))


DESIGNS = (
    design("Iron Chestplate", "Common", "A plain iron plate, two lames under a leather belt.", "iron"),
    design("Bronze Chestplate", "Common", "Smooth bronze with a rolled neck and one lame.", "bronze", neck="bronze",
           lames=1),
    design("Scrap Chestplate", "Common", "Plates beaten flat and riveted, a belt of cord.", "scrap", rivets=True,
           facets=True, belt="cord"),

    design("Lanternsteel Chestplate", "Uncommon", "Bright steel, three lames, a brass rim on each.", "steel", lames=3,
           rims="brass"),
    design("Rowsmith Chestplate", "Uncommon", "A keel down the middle and a brass lozenge on the chest.", "steel",
           keel=True, lozenge="brass"),
    design("Stallguard Chestplate", "Uncommon", "Brass studs round the neck and down each side, a brass rim.", "steel",
           studs="brass", neck="brass", rims="brass"),

    design("Cuirass of Embers", "Rare", "A swelling frame round one stone on the chest, a line round the neck.",
           "blued", neck="filigree", orn="Embers", stone=("stone", 0.13)),
    design("Cuirass of Hoarfrost", "Rare", "A plate cut in facets, a square stone in a spade.", "blued", facets=True,
           neck="filigree", orn="Hoarfrost", stone=("stone", 0.13), cut="square"),
    design("Cuirass of Gales", "Rare", "A vane sweeps back from each side of the belt, the stone on the chest.",
           "blued", lames=1, neck="filigree", orn="Gales", stone=("stone", 0.13)),

    design("Stormcall Cuirass", "Epic", "Filigree hooks rise from each shoulder and curl out. A glowing stone.", "rich",
           trim="filigree", neck="filigree", orn="Stormcall", stone=("glow", 0.17)),
    design("Gloamforge Cuirass", "Epic", "Filigree prongs stand on each shoulder, three lames, a square glowing stone.",
           "rich", trim="filigree", lames=3, keel=True, orn="Gloamforge", stone=("glow", 0.17), cut="square"),
    design("Nightloom Cuirass", "Epic", "A shuttle lies across the chest, four long lames, a glowing stone.", "rich",
           trim="filigree", lames=4, neck="filigree", orn="Nightloom", stone=("glow", 0.17)),

    design("Hinode, the Sunrise", "Legendary", "Its one new form: rays stand behind the collar, the sun's stone on the "
           "chest.", "gilt", trim="ivory", neck="ivory", rims="ivory", orn="rays", stone=("lit", 0.2), edge=True,
           belt="ivory"),
    design("Tsukiyo, the Moonlit Sky", "Legendary", "Its one new form: the collar rises behind the neck into a crescent "
           "moon's two horns.", "gilt", trim="ivory", neck="ivory", orn="crescent", stone=("lit", 0.16), edge=True,
           belt="ivory"),
    design("Amanogawa, the Starway", "Legendary", "Its one new form: a sash of stars crosses the chest and falls past "
           "the hip.", "gilt", trim="ivory", rims="ivory", lames=3, orn="sash", stone=("lit", 0.13), edge=True,
           belt="ivory"),
)


# --- the plate's shell, by u across (-1 to 1) and t up (0 at the belt, 1 at the top) ----------------------------------

def smooth(a, b, x):
    k = min(max((x - a) / (b - a), 0.0), 1.0)
    return k * k * (3 - 2 * k)


def half_width(t):
    return 0.78 + 0.22 * smooth(0.25, 0.75, t) - 0.1 * smooth(0.85, 1.0, t)


def top(u, back=False):
    """The top edge: the neck scooped in the middle (less at the back), the arms cut away at the sides."""
    scoop = (0.14 if back else 0.34) * max(0.0, 1 - (u / 0.42) ** 2)
    return 1.0 - scoop - 0.5 * smooth(0.72, 1.0, abs(u)) + (0.06 if back else 0.0)


def depth(t):
    return 0.5 + 0.14 * smooth(0.3, 0.75, t)


def shell_point(u, t, keel=False, back=False, inset=0.0):
    z = FOOT + (top(u, back) - FOOT) * t
    y = depth(t) * math.sqrt(max(0.0, 1 - u * u)) * (0.86 if back else 1.0) - inset
    if keel and not back:
        y += 0.1 * max(0.0, 1 - abs(u) / 0.3) * smooth(0.1, 0.6, t)
    return (u * half_width(t) * (1 - inset), y if back else -y, z)


def front_at(z, u=0.0):
    """A point on the plate's face, at height z (approximately: the shell's t found by its top at u)."""
    t = (z - FOOT) / (top(u) - FOOT)
    x, y, zz = shell_point(u, t)
    return (x, y - 0.04, zz)


def arc_rim(name, radius, minor, key, z, a0, a1, deep):
    t = bl.torus(name, radius, minor, 48, 8, mat(key), arc=a1 - a0)
    bl.place(t, (0, 0, 0), (0, 0, a0 - 90.0))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, deep, 1)), 40.0)


def plate(d):
    key, trim, parts = d["key"], d["trim"], []
    across = 9 if d["facets"] else 25
    us = [-1.0 + 2.0 * i / (across - 1) for i in range(across)]
    ts = [j / 14 for j in range(15)]
    parts.append(p.sheet_surface("Plate", key, lambda u, t: shell_point(u, t, d["keel"]), us, ts, thick=0.06))
    parts.append(p.sheet_surface("Liner", "liner", lambda u, t: shell_point(u, t, d["keel"], inset=0.04), us, ts,
                                 thick=0.02))
    parts.append(p.sheet_surface("Back", key, lambda u, t: shell_point(u, t, back=True), us, ts, thick=0.06))
    # the back plate's inside, seen through the neck and the arms, is lined dark too: an empty garment, never a body
    parts.append(p.sheet_surface("BackLiner", "liner", lambda u, t: shell_point(u, t, back=True, inset=0.04), us, ts,
                                 thick=0.02))

    # the belt and the fauld's lames below it
    w0 = half_width(0.0)
    deep = depth(0.0) / w0
    parts.append(p.lathe("Belt", [(w0 + 0.03, FOOT - 0.02), (w0 + 0.03, FOOT + 0.14)], d["belt"], deep=deep, thick=0.05))
    for k in range(1, d["lames"] + 1):
        hi, lo = FOOT - 0.04 - 0.17 * (k - 1), FOOT - 0.2 - 0.17 * (k - 1)
        r0, r1 = w0 + 0.02 + 0.03 * k, w0 + 0.05 + 0.05 * k
        parts.append(p.lathe("Lame", [(r0, hi), (r1, lo)], d["lame_mat"], -100.0, 100.0, thick=0.05, deep=deep))
        if d["rims"]:
            parts.append(arc_rim("Rim", r1, 0.03, d["rims"], lo, -100.0, 100.0, deep))

    # the neck's rolled rim, and the Legendary's lit edge along it
    neck = [shell_point(u / 10, 1.0) for u in range(-7, 8)]
    if d["neck"]:
        parts.append(p.tube("Neck", p.curve(neck, 24), 0.05, d["neck"], sides=8))
    if d["edge"]:
        parts.append(p.tube("Edge", p.curve([(x, y - 0.05, z - 0.08) for x, y, z in neck], 24), 0.025, "lit", sides=6))
    if d["lozenge"]:
        y = front_at(CHEST)[1]
        parts.append(p.flat("Lozenge", [(0, CHEST + 0.26), (0.2, CHEST), (0, CHEST - 0.26), (-0.2, CHEST)], 0.06,
                            d["lozenge"], y=y))
    if d["studs"]:
        for u in (-0.55, -0.35, 0.35, 0.55):
            parts.append(p.ball("Stud", 0.06, d["studs"], shell_point(u, 0.93)))
        for side in (-1, 1):
            for t in (0.2, 0.4, 0.6):
                x, y, z = shell_point(0.8 * side, t)
                parts.append(p.ball("Stud", 0.06, d["studs"], (x, y - 0.02, z)))
    if d["rivets"]:
        for u in (-0.6, 0.0, 0.6):
            for t in (0.15, 0.5, 0.85):
                x, y, z = shell_point(u, t)
                parts.append(p.ball("Rivet", 0.05, key, (x, y - 0.01, z), segments=8, rings=5))
        for side in (-1, 1):   # the straps over the shoulders, buckled at the front
            x, y, z = shell_point(0.62 * side, 1.0)
            parts.append(p.tube("Strap", p.curve([(x, y - 0.02, z - 0.3), (x, y - 0.06, z), (x, 0.0, z + 0.1),
                                                  (x, -y * 0.85, z - 0.1)], 12), 0.05, "leather", sides=6))

    # what the chest carries: the set's ornament round its stone, or a Legendary's new form
    orn, stone_at = d["orn"], front_at(CHEST)
    size = 1.0
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.46, (0, CHEST)), 0.06, trim, y=stone_at[1] + 0.03))
    elif orn == "Gales":
        for side in (-1, 1):
            x, y, z = shell_point(0.95 * side, 0.1)
            vane = p.shifted(p.VANE, x + 0.05 * side, z - 0.05, 1.0 * side, 0.9)
            parts.append(p.flat("Vane", vane, 0.07, trim, y=y * 0.4))
    elif orn in ("Stormcall", "Gloamforge"):
        for side in (-1, 1):
            x, y, z = shell_point(0.6 * side, 1.0)
            parts.append(p.flat("Crest", p.set_ornament(orn, 0.36, (x, z + 0.1)), 0.07, trim, y=y * 0.4))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, CHEST, 2.1, 1.3), 0.08, trim, y=stone_at[1] + 0.06))
    elif orn == "rays":
        for k, angle in enumerate(range(-72, 73, 24)):
            length = 0.95 + 0.35 * math.cos(math.radians(angle) * 1.2)
            ray = p.turned(p.leaf(length, 0.22), -angle, (0, 0))
            parts.append(p.flat("Ray", p.shifted(ray, 0, 0.72), 0.06, trim if k % 2 else d["key"], y=0.3))
    elif orn == "crescent":
        outer = [(1.0 * math.cos(math.radians(a)), 1.0 * math.sin(math.radians(a))) for a in range(190, 351, 8)]
        inner = [(0.86 * math.cos(math.radians(a)), 0.3 + 0.86 * math.sin(math.radians(a))) for a in range(342, 197, -8)]
        parts.append(p.flat("Crescent", p.shifted(outer + inner, 0, 1.5, 1.3, 1.25), 0.09, trim, y=0.32))
    elif orn == "sash":
        path = [shell_point(0.66, 1.0), shell_point(0.3, 0.72), shell_point(-0.2, 0.42), shell_point(-0.7, 0.12)]
        path = [(x, y - 0.06, z) for x, y, z in path] + [(-1.0, -0.3, FOOT - 0.1), (-1.15, -0.2, FOOT - 0.5),
                                                           (-1.12, -0.15, FOOT - 0.85)]
        parts.append(p.tube("Sash", p.curve(path, 28), 0.11, trim, sides=8))
        for k, (x, y, z) in enumerate(p.curve(path, 9)[1:-1]):
            parts.append(p.ball("Star", 0.07 if k % 2 else 0.05, "lit", (x, y - 0.1, z)))
    parts += p.stone_of(d, size, stone_at)
    return parts


def build(d):
    return p.scene_of(lambda: plate(d), TILT, SPIN)


WORDS = dict(
    file="gear_chest_sets.png",
    title="Grow your Anime: Chest Armor in three designs at each rarity, in grey (AR6, batch 2)",
    lead="A breastplate from the front and a little to the side: cut to a torso, its neck scooped, its arms cut away, a "
         "belt and the fauld's lames below. A design is the plate, its lames and what the chest carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is Cuirass.",
        "Each Legendary's one new form: Hinode (sunrise), rays standing behind the collar; Tsukiyo (a moonlit night), the "
        "collar rising into a crescent's two horns; Amanogawa (the river of stars), a sash of stars past the hip.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as chest armour, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
