"""AR6, batch 2: Boots in three designs at each rarity, in grey: a blockout for research's verdict.

One family: the right boot from its outer side and a little from the front, the toe to the right: a shaft to below the
knee, the foot, a sole and a heel. The boot's L, so it reads as nothing else. A design is the shaft, the foot's plates,
the knee, and what the outer side carries. A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and
the near word from Rare up is Greaves.

Each Legendary's one new form changes the silhouette: Komorebi's leaf blades fan back from the ankle, Asaborake's knee
guard rises into a tall arch with the dawn's light at its top, Hoshikuzu trails a sweep of small stars up from its heel.

    blender -b --factory-startup --python tools/blender/gear_boots_sets.py -- build/handoff/Gear/boots_sets

Writes the sheet gear_boots_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 8.0, -26.0    # nearly level, turned so the toe comes a little toward the camera
FILL, DROP = 0.8, 0.0
LEAST = 0.86
TOP = 1.3                  # the shaft's top, below the knee
SOLE = -0.42


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(shaft="leather", plated=False, toe=None, knee=False,
                                                         cuff=False, straps=0, strap_mat="leather", rims=None,
                                                         studs=None, rivets=False, lozenge=None, facets=False,
                                                         shin=False), **more))


DESIGNS = (
    design("Iron Boots", "Common", "Leather boots with an iron toe and an iron plate down the shin.", "iron", toe="iron",
           shin=True),
    design("Bronze Boots", "Common", "A bronze cuff turned down at the top, two straps.", "bronze", cuff=True,
           rims="bronze", straps=2),
    design("Scrap Boots", "Common", "Plates beaten flat and riveted to the shin, cord straps.", "scrap", shin=True,
           rivets=True, facets=True, straps=2, strap_mat="cord"),

    design("Lanternsteel Boots", "Uncommon", "Bright steel over the foot and the shin, a brass rim at the top.",
           "steel", plated=True, toe="steel", shin=True, rims="brass"),
    design("Rowsmith Boots", "Uncommon", "A steel knee guard, a brass lozenge on the shin plate.", "steel", knee=True,
           shin=True, lozenge="brass", toe="steel"),
    design("Stallguard Boots", "Uncommon", "Brass studs down the outer side, a brass rim, steel toe.", "steel",
           studs="brass", rims="brass", toe="steel", straps=1),

    design("Greaves of Embers", "Rare", "Plated, a swelling frame round one stone on the outer side.", "blued",
           plated=True, shin=True, toe="blued", line="filigree", orn="Embers", stone=("stone", 0.12)),
    design("Greaves of Hoarfrost", "Rare", "A shin cut in facets, a square stone in a spade.", "blued", plated=True,
           shin=True, facets=True, toe="blued", line="filigree", orn="Hoarfrost", stone=("stone", 0.12),
           cut="square"),
    design("Greaves of Gales", "Rare", "A vane sweeps back from the heel, the stone on the outer side.", "blued",
           plated=True, shin=True, toe="blued", line="filigree", orn="Gales", stone=("stone", 0.12)),

    design("Stormcall Greaves", "Epic", "Filigree hooks rise from the knee and curl out. A glowing stone.", "rich",
           trim="filigree", plated=True, shin=True, knee=True, toe="rich", orn="Stormcall", stone=("glow", 0.15)),
    design("Gloamforge Greaves", "Epic", "Filigree prongs stand over the knee, a square glowing stone.", "rich",
           trim="filigree", plated=True, shin=True, knee=True, toe="rich", orn="Gloamforge", stone=("glow", 0.15),
           cut="square"),
    design("Nightloom Greaves", "Epic", "A shuttle lies down the outer side, a turned cuff, a glowing stone.", "rich",
           trim="filigree", plated=True, shin=True, cuff=True, toe="rich", line="filigree", orn="Nightloom",
           stone=("glow", 0.15)),

    design("Komorebi, the Leaf Light", "Legendary", "Its one new form: leaf blades fan back from the ankle.", "gilt",
           trim="ivory", plated=True, shin=True, toe="gilt", rims="ivory", orn="leaves", stone=("lit", 0.15),
           edge=True, shaft="ivory"),
    design("Asaborake, the Dawnlight", "Legendary", "Its one new form: the knee guard rises into a tall arch, the "
           "dawn's light at its top.", "gilt", trim="ivory", plated=True, shin=True, toe="gilt", knee=True,
           orn="arch", stone=("lit", 0.13), edge=True, shaft="ivory"),
    design("Hoshikuzu, the Stardust", "Legendary", "Its one new form: a sweep of small stars rises from the heel.",
           "gilt", trim="ivory", plated=True, shin=True, toe="gilt", rims="ivory", cuff=True, orn="stars",
           stone=("lit", 0.13), edge=True, shaft="ivory"),
)


def r_shaft(z):
    return 0.34 + 0.06 * max(0.0, z) / TOP


def outer(z, out=0.0, x=0.0):
    """A point on the shaft's outer side (toward the camera) at height z."""
    return (x, -r_shaft(z) - 0.03 - out, z)


def boot(d):
    key, trim, parts = d["key"], d["trim"], []
    steps = 10 if d["facets"] else 40
    prof = [(r_shaft(z), z) for z in (-0.05, 0.3, 0.7, 1.0, TOP)]
    parts.append(p.lathe("Shaft", prof, d["shaft"], deep=1.0, thick=0.05, steps=40))
    parts.append(p.ball("Foot", 1.0, d["shaft"], (0.36, 0.0, -0.16), squash=(0.74, 0.34, 0.3), segments=24, rings=12))
    parts.append(p.ball("Heel", 1.0, d["shaft"], (-0.08, 0.0, -0.14), squash=(0.36, 0.34, 0.3), segments=20, rings=10))
    sole = [(-0.44, SOLE + 0.12), (-0.44, SOLE), (1.02, SOLE), (1.14, SOLE + 0.06), (1.1, SOLE + 0.14)]
    parts.append(p.flat("Sole", sole, 0.66, "liner", y=0.0))
    parts.append(p.flat("HeelBlock", [(-0.44, SOLE), (-0.1, SOLE), (-0.12, SOLE - 0.12), (-0.42, SOLE - 0.12)], 0.6,
                        "liner", y=0.0))
    if d["toe"]:
        parts.append(p.ball("Toe", 1.0, d["toe"], (0.82, 0.0, -0.17), squash=(0.32, 0.36, 0.27), segments=20,
                            rings=10))
    if d["plated"]:   # the sabaton: plates stepping down over the instep to the toe
        for k, (x, z, s) in enumerate(((0.2, 0.02, 0.36), (0.42, -0.04, 0.33), (0.62, -0.1, 0.3))):
            parts.append(p.ball("Plate", 1.0, key, (x, 0.0, z), squash=(0.2, s + 0.03, 0.2), segments=20, rings=10))
    if d["shin"]:     # a plate down the front and the outer side of the shin
        parts.append(p.lathe("Shin", [(r_shaft(z) + 0.04, z) for z in (0.06, 0.5, 0.9, TOP - 0.06)], key, -20.0,
                             120.0, thick=0.05, deep=1.0, steps=steps))
    if d["cuff"]:
        parts.append(p.lathe("Cuff", [(r_shaft(TOP) + 0.02, TOP + 0.04), (r_shaft(TOP) + 0.1, TOP - 0.2),
                                      (r_shaft(TOP) + 0.12, TOP - 0.3)], d["rims"] or key, deep=1.0, thick=0.05,
                             steps=steps))
    if d["rims"] and not d["cuff"]:
        parts.append(p.hoop("Rim", r_shaft(TOP) + 0.02, 0.045, d["rims"], TOP, deep=1.0))
    if d["line"]:
        parts.append(p.hoop("Line", r_shaft(0.9) + 0.05, 0.022, d["line"], 0.92, deep=1.0))
    if d["edge"]:
        parts.append(p.hoop("Edge", r_shaft(0.1) + 0.06, 0.025, "lit", 0.1, deep=1.0))
    if d["knee"] or d["orn"] == "arch":
        # the knee's cop sits over the front of the shaft's top, facing forward and a little up
        parts.append(p.aim(p.lathe("Knee", [(0.0, 0.3), (0.2, 0.27), (0.34, 0.14), (0.4, -0.04)], key, thick=0.05,
                                   steps=24), (0.16, 0.0, TOP - 0.06), (1.0, 0.0, 0.42)))
    for k in range(d["straps"]):
        z = 0.25 + 0.6 * k
        parts.append(p.hoop("Strap", r_shaft(z) + 0.05, 0.04, d["strap_mat"], z, deep=1.0, high=1.5))
        parts.append(bl.place(bl.cylinder("Buckle", 0.08, 0.05, segments=4, material=mat("iron")),
                              outer(z, 0.03), (90, 0, 45)))
    if d["studs"]:
        for z in (0.15, 0.45, 0.75, 1.05):
            parts.append(p.ball("Stud", 0.055, d["studs"], outer(z)))
    if d["rivets"]:
        for z in (0.2, 0.6, 1.0):
            for a in (20, 70):
                x, y = (r_shaft(z) + 0.06) * math.sin(math.radians(a)), -(r_shaft(z) + 0.06) * math.cos(math.radians(a))
                parts.append(p.ball("Rivet", 0.045, key, (x, y, z), segments=8, rings=5))
    if d["lozenge"]:
        parts.append(p.flat("Lozenge", p.shifted([(0, 0.3), (0.15, 0.0), (0, -0.3), (-0.15, 0.0)], 0.08, 0.7), 0.06,
                            d["lozenge"], y=outer(0.7)[1] - 0.06))

    # what the outer side carries: the set's ornament round its stone, or a Legendary's new form
    orn, stone_at = d["orn"], outer(0.7, 0.06)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.38, (0, 0.7)), 0.05, trim, y=stone_at[1] + 0.04))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, -0.36, -0.18, -1.0, 1.0), 0.07, trim, y=0.0))
        stone_at = outer(0.45, 0.06)
    elif orn in ("Stormcall", "Gloamforge"):
        parts.append(p.flat("Crest", p.set_ornament(orn, 0.5, (0.24, TOP + 0.3)), 0.07, trim, y=0.0))
    elif orn == "Nightloom":
        shuttle = p.turned(p.shifted(p.SHUTTLE, 0, 0, 2.0, 1.2), 90.0, (0, 0))
        parts.append(p.flat("Shuttle", p.shifted(shuttle, 0, 0.62), 0.08, trim, y=outer(0.6)[1] - 0.02))
        stone_at = outer(0.62, 0.1)
    elif orn == "leaves":
        for k, angle in enumerate((58, 78, 98, 118, 138)):
            leaf = p.turned(p.leaf(0.95 - 0.06 * abs(k - 2), 0.28, bend=-0.1), angle, (0, 0))
            parts.append(p.flat("Leaf", p.shifted(leaf, -0.3, 0.05), 0.05, trim if k % 2 else key, y=-0.05 * k))
    elif orn == "arch":
        arch = [(0.0, 0.0), (0.22, 0.3), (0.3, 0.8), (0.16, 1.2), (0.0, 1.38), (-0.16, 1.2), (-0.3, 0.8), (-0.22, 0.3)]
        inner = [(0.0, 0.3), (-0.12, 0.62), (-0.14, 0.9), (0.0, 1.08), (0.14, 0.9), (0.12, 0.62)]
        parts.append(p.flat("Arch", p.shifted(arch, 0.3, TOP - 0.1), 0.08, trim, y=0.0))
        parts.append(p.flat("ArchLight", p.shifted(inner, 0.3, TOP - 0.1), 0.06, "lit", y=-0.06))
        parts.append(p.ball("Light", 0.13, "lit", (0.3, -0.06, TOP + 1.3)))
    elif orn == "stars":
        for k in range(6):
            t = k / 5
            x, z = -0.42 - 0.4 * t - 0.1 * t * t, -0.1 + 1.25 * t
            size = 0.1 + 0.12 * (1 - abs(t - 0.5) * 2) + 0.04
            parts.append(p.flat("Star", p.shifted(p.star(4, size, size * 0.3), x, z), 0.05,
                                "lit" if k % 2 else trim, y=0.0))
    parts += p.stone_of(d, 1.0, stone_at)
    for obj in parts:   # the foot's rounded parts, smooth
        if obj.name.startswith(("Foot", "Heel", "Toe", "Plate")):
            bl.smooth_by_angle(obj, 70.0)
    return parts


def build(d):
    return p.scene_of(lambda: boot(d), TILT, SPIN)


WORDS = dict(
    file="gear_boots_sets.png",
    title="Grow your Anime: Boots in three designs at each rarity, in grey (AR6, batch 2)",
    lead="The right boot from its outer side and a little from the front, the toe to the right: a shaft to below the "
         "knee, the foot, a sole and a heel. A design is the shaft, the foot's plates, the knee and what the outer "
         "side carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Greaves.",
        "Each Legendary's one new form: Komorebi (sunlight through leaves), leaf blades fanning back from the ankle; "
        "Asaborake (the first faint dawn), the knee guard a tall arch with its light at the top; Hoshikuzu (stardust), a "
        "sweep of small stars up from the heel.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as boots, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
