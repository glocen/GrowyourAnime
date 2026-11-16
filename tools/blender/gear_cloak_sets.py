"""AR6, batch 2: Cloaks in three designs at each rarity, in grey: a blockout for research's verdict.

One family: a cloak seen from behind and a little to the side, hanging from the shoulders, its folds widening to the
hem, a collar, a hood, or a rolled collar and its clasp at the neck. A cape's outline, so it reads as nothing else. A
design is the cloth, its collar, its hem, and what the back carries. A rarity keeps the ladder's rule, a set keeps its
word (gear_parts.py), and the near word from Rare up is Mantle. Cloth takes its own greys (wool, silk, velvet, white),
never a metal's, so the finals never paint a cloak as plate.

Each Legendary's one new form changes the silhouette: Kyokkou's hem streams out in ribbons like an aurora's curtains,
Yuuyake's hem is cut in long points like the sun's last rays going down, Tsukiakari's hem parts in two long tails that
curve out like a new moon's horns.

    blender -b --factory-startup --python tools/blender/gear_cloak_sets.py -- build/handoff/Gear/cloak_sets

Writes the sheet gear_cloak_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

# dyed is Rare's silk, silk's grey here and deep blue in colour, as blued steel is to steel
for _key, _value in dict(wool=0.5, silk=0.68, dyed=0.68, velvet=0.36, white=0.9).items():
    p.g.GREY.setdefault(_key, _value)

mat = p.mat
TILT, SPIN = 10.0, 158.0   # from behind and a little to the side, a little from above
FILL, DROP = 0.8, 0.0
LEAST = 0.86
NECK, HEM = 1.0, -1.5      # the collar's height and the hem's
SPREAD = 112.0             # the cloth's reach round from the back's middle to each front edge, in degrees
DEEP = 0.72


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(hood=False, collar=False, capelet=False, hem=None, folds=7,
                                                         ragged=False, patches=False, studs=None, lozenge=None,
                                                         tie="cord"), **more))


DESIGNS = (
    design("Wool Cloak", "Common", "Plain wool, a rolled collar, an iron clasp at the throat.", "wool"),
    design("Hooded Cloak", "Common", "Wool with its hood down over the shoulders.", "wool", hood=True),
    design("Scrap Cloak", "Common", "Patched cloth with a ragged hem.", "wool", patches=True, ragged=True),

    design("Lanternweave Cloak", "Uncommon", "Fine cloth, a standing collar, a brass band along the hem.", "silk",
           collar=True, hem="brass", trim="brass"),
    design("Rowsmith Cloak", "Uncommon", "A short cape over the shoulders and a brass lozenge on the back.", "silk",
           capelet=True, lozenge="brass", trim="brass"),
    design("Stallguard Cloak", "Uncommon", "Brass studs along the shoulders, a brass band along the hem.", "silk",
           studs="brass", hem="brass", trim="brass"),

    design("Mantle of Embers", "Rare", "A short cape over it, a swelling frame round one stone on the back.", "dyed",
           trim="filigree", capelet=True, line="filigree", orn="Embers", stone=("stone", 0.13)),
    design("Mantle of Hoarfrost", "Rare", "A standing collar, deep square folds, a square stone in a spade.", "dyed",
           trim="filigree", collar=True, folds=5, line="filigree", orn="Hoarfrost", stone=("stone", 0.13),
           cut="square"),
    design("Mantle of Gales", "Rare", "Vanes sweep out from the shoulders, the stone on the back.", "dyed",
           trim="filigree", line="filigree", orn="Gales", stone=("stone", 0.13)),

    design("Stormcall Mantle", "Epic", "Filigree hooks rise from the collar and curl out. A glowing stone.", "velvet",
           trim="filigree", collar=True, hem="filigree", orn="Stormcall", stone=("glow", 0.17)),
    design("Gloamforge Mantle", "Epic", "Filigree prongs stand over the collar, a short cape, a square glowing stone.",
           "velvet", trim="filigree", collar=True, capelet=True, orn="Gloamforge", stone=("glow", 0.17), cut="square"),
    design("Nightloom Mantle", "Epic", "A shuttle lies across the shoulders, a filigree hem, a glowing stone.", "velvet",
           trim="filigree", hem="filigree", line="filigree", orn="Nightloom", stone=("glow", 0.17)),

    design("Kyokkou, the Aurora", "Legendary", "Its one new form: the hem streams out in ribbons like an aurora's "
           "curtains.", "white", trim="gilt", collar=True, hem="ivory", orn="ribbons", stone=("lit", 0.15),
           edge=True),
    design("Yuuyake, the Sunset", "Legendary", "Its one new form: the hem is cut in long points like the sun's last "
           "rays.", "white", trim="gilt", collar=True, capelet=True, orn="points", stone=("lit", 0.15), edge=True),
    design("Tsukiakari, the Moonglow", "Legendary", "Its one new form: the hem parts in two long tails that curve out "
           "like a new moon's horns.", "white", trim="gilt", hood=True, hem="ivory", orn="tails",
           stone=("lit", 0.15), edge=True),
)


# --- the cloth, by a (degrees round from the back's middle) and v (0 at the collar, 1 at the hem) ---------------------

def smooth(a, b, x):
    k = min(max((x - a) / (b - a), 0.0), 1.0)
    return k * k * (3 - 2 * k)


def cloth_point(d, a, v, inset=0.0, length=1.0):
    over = smooth(0.0, 0.16, v)                      # over the shoulders first, then falling
    r = 0.48 + 0.5 * math.sqrt(over) + 0.34 * v
    r *= 1.0 + 0.08 * v * math.sin(math.radians(a) * d["folds"])
    if d["ragged"]:
        r *= 1.0 + 0.02 * math.sin(math.radians(a) * 23)
    r -= inset
    z = NECK - 0.18 * over - (NECK - 0.18 - HEM) * max(0.0, v - 0.1) / 0.9 * length
    if d["ragged"] and v > 0.97:
        z -= 0.08 * (1 + math.sin(math.radians(a) * 19))
    return (r * math.sin(math.radians(a)), r * DEEP * math.cos(math.radians(a)), z)


def back(d, v, out=0.0):
    x, y, z = cloth_point(d, 0.0, v)
    return (x, y + 0.04 + out, z)


def cloak(d):
    key, trim, parts = d["key"], d["trim"], []
    angles = [-SPREAD + 2 * SPREAD * i / 48 for i in range(49)]
    vs = [j / 20 for j in range(21)]
    parts.append(p.sheet_surface("Cloth", key, lambda a, v: cloth_point(d, a, v), angles, vs, thick=0.04))
    parts.append(p.sheet_surface("Lining", "liner", lambda a, v: cloth_point(d, a, v, inset=0.035), angles, vs,
                                 thick=0.02))
    if d["capelet"]:
        cape = [-SPREAD * 1.02 + 2 * SPREAD * 1.02 * i / 40 for i in range(41)]
        parts.append(p.sheet_surface("Capelet", key, lambda a, v: cloth_point(d, a, v * 0.3, inset=-0.06), cape,
                                     [j / 8 for j in range(9)], thick=0.04))
        hem_v, hem_out = 0.3, -0.06
    else:
        hem_v, hem_out = None, 0.0
    if d["hood"]:
        hood = p.lathe("Hood", [(0.02, 0.0), (0.42, 0.08), (0.6, 0.34), (0.62, 0.64), (0.5, 0.9)], key, 110.0, 250.0,
                       thick=0.04, deep=1.0, steps=24)
        parts.append(p.move(hood, Matrix.Translation((0.0, 0.34, NECK - 0.56))))
    if d["collar"]:
        # a standing collar round the back of the neck, open at the front (the lathe's 0 faces the front)
        parts.append(p.lathe("Collar", [(0.48, NECK - 0.04), (0.5, NECK + 0.2), (0.58, NECK + 0.34)], trim, 40.0,
                             320.0, thick=0.05, deep=DEEP * 1.15, steps=32))
    elif not d["hood"]:
        # with no collar and no hood, the cloth rolls over at the neck and a clasp at the throat shows over it, seen from
        # behind and above: without one a cloak reads as a skirt from behind (research's verdict, 2026-11-16)
        parts.append(p.lathe("Roll", [(0.5, NECK - 0.06), (0.58, NECK + 0.08), (0.68, NECK - 0.02)], key, 40.0, 320.0,
                             thick=0.06, deep=DEEP * 1.1, steps=32))
        metal = trim if trim != key else "iron"
        parts.append(p.ball("Clasp", 0.17, metal, (0.0, -0.5 * DEEP, NECK + 0.14), squash=(1, 0.4, 1)))
        parts.append(p.facing("Clasp", 0.17, 0.04, metal, (0.0, -0.5 * DEEP + 0.04, NECK + 0.14)))
    neck = [cloth_point(d, a, 0.0) for a in range(-110, 111, 10)]
    parts.append(p.tube("Neck", p.curve(neck, 24), 0.05, d["tie"] if not d["collar"] else trim, sides=8))
    hem = [cloth_point(d, a, 1.0) for a in angles[::2]]
    if d["hem"]:
        parts.append(p.tube("Hem", p.curve(hem, 48), 0.05, d["hem"], sides=8))
    if d["line"]:
        line = [cloth_point(d, a, 0.86) for a in angles[::2]]
        parts.append(p.tube("Line", p.curve([(x * 1.01, y * 1.01, z) for x, y, z in line], 48), 0.025, d["line"],
                            sides=6))
    if d["edge"]:
        for side in (-1, 1):
            edge = [cloth_point(d, SPREAD * side, j / 10) for j in range(11)]
            parts.append(p.tube("Edge", p.curve(edge, 20), 0.03, "lit", sides=6))
    if d["patches"]:
        for a, v, w in ((-30, 0.45, 0.22), (40, 0.7, 0.18), (5, 0.25, 0.16)):
            x, y, z = cloth_point(d, a, v)
            patch = p.flat("Patch", [(-w, -w), (w, -w * 0.9), (w * 1.1, w), (-w * 0.9, w * 1.05)], 0.03, "leather",
                           y=0.0)
            parts.append(p.move(patch, Matrix.Translation((x, y + 0.03, z)) @ Matrix.Rotation(math.radians(-a), 4, "Z")))
    if d["studs"]:
        for a in range(-90, 91, 30):
            x, y, z = cloth_point(d, a, 0.12)
            parts.append(p.ball("Stud", 0.055, d["studs"], (x * 1.03, y * 1.03 + 0.02, z)))
    if d["lozenge"]:
        y = back(d, 0.32)[1] + 0.02
        parts.append(p.flat("Lozenge", p.shifted([(0, 0.28), (0.2, 0.0), (0, -0.28), (-0.2, 0.0)], 0, back(d, 0.32)[2]),
                            0.06, d["lozenge"], y=y))

    # what the back carries: the set's ornament round its stone, or a Legendary's new form
    orn = d["orn"]
    stone_at = back(d, 0.34, 0.06)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.5, (0, stone_at[2])), 0.05, trim, y=stone_at[1] - 0.03))
    elif orn == "Gales":
        for side in (-1, 1):
            x, y, z = cloth_point(d, 80 * side, 0.12)
            parts.append(p.flat("Vane", p.shifted(p.VANE, x, z - 0.1, 1.15 * side, 1.15), 0.07, trim, y=y))
    elif orn in ("Stormcall", "Gloamforge"):
        parts.append(p.flat("Crest", p.set_ornament(orn, 0.62, (0, NECK + 0.26)), 0.07, trim, y=0.5))
    elif orn == "Nightloom":
        z = cloth_point(d, 0.0, 0.14)[2]
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, z, 3.2, 1.4), 0.08, trim, y=back(d, 0.14)[1] + 0.04))
        stone_at = back(d, 0.14, 0.1)
    elif orn == "ribbons":
        # broad streamers blown out to one side from the hem, rising a little: curtains, never claws
        for k, a in enumerate((-90, -55, -20, 15, 50)):
            x, y, z = cloth_point(d, a, 0.94)
            ribbon = p.turned(p.leaf(1.9 - 0.15 * k, 0.5, bend=0.7), 112.0 + 8 * k, (0, 0))
            parts.append(p.flat("Ribbon", p.shifted(ribbon, x, z), 0.04, trim if k % 2 else key, y=y + 0.05 * k))
    elif orn == "points":
        # the hem itself cut in points, edge to edge: a sawtooth of rays going down
        for k, a in enumerate(range(-104, 105, 16)):
            x, y, z = cloth_point(d, a, 0.99)
            length = 0.5 + 0.45 * math.cos(math.radians(a)) ** 2
            point = [(-0.23, 0.08), (0.23, 0.08), (0.0, -length)]
            parts.append(p.flat("Point", p.shifted(point, x, z), 0.04, trim if k % 2 else key, y=y))
    elif orn == "tails":
        for side in (-1, 1):
            x, y, z = cloth_point(d, 70 * side, 0.98)
            tail = p.leaf(1.5, 0.5, bend=0.9 * side)
            parts.append(p.flat("Tail", p.shifted(p.turned(tail, 180.0, (0, 0)), x, z + 0.1), 0.05, key, y=y))
            parts.append(p.flat("TailEdge", p.shifted(p.turned(p.leaf(1.3, 0.12, bend=0.8 * side), 180.0, (0, 0)),
                                                       x, z + 0.04), 0.03, "lit", y=y + 0.05))
    parts += p.stone_of(d, 1.0, stone_at)
    return parts


def build(d):
    return p.scene_of(lambda: cloak(d), TILT, SPIN)


WORDS = dict(
    file="gear_cloak_sets.png",
    title="Grow your Anime: Cloaks in three designs at each rarity, in grey (AR6, batch 2)",
    lead="A cloak from behind and a little to the side, hanging from the shoulders, its folds widening to the hem, a "
         "collar, a hood, or a rolled collar and its clasp at the neck. A design is the cloth, its collar and hem and what "
         "the back carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Mantle.",
        "Each Legendary's one new form: Kyokkou (the aurora), the hem streaming in ribbons; Yuuyake (the sunset glow), the "
        "hem cut in long points; Tsukiakari (moonlight), two tails curving out like a new moon's horns.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a cloak, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
