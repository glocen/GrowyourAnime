"""AR6, batch 1: the Short Sword in three designs at each rarity, in grey: a blockout for research's verdict.

The Warrior's off hand. It's built from the Sword's parts (gear_sword_sets.py) and must never be taken for it at the
slot's size (AR6, "Batch 1, research's spec": "shorter and broader, with its own guard"):

- **Its blade** is a broad wedge, about two and a half times as long as it's wide (the Sword's is seven and a half), so
  in its square it's a wide leaf of metal where the Sword is a line.
- **Its guard droops toward the hand,** where the Sword's turns toward the point.
- **Its grip is shorter,** a one-hand grip.

A rarity keeps the ladder's rule, and a set keeps its word (Iron, Bronze, Scrap; Lanternsteel, Rowsmith, Stallguard; of
Embers, of Hoarfrost, of Gales; Stormcall, Gloamforge, Nightloom). From Rare up its kind's near word is "Edge", so no
name repeats a Sword's. Each Legendary has one new form that changes the silhouette at 38 points: a window in the blade
with a light in it, a bow from the guard to the pommel, an arm that holds a second light out beside the blade.

    blender -b --factory-startup --python tools/blender/gear_short_sword_sets.py -- build/handoff/Gear/short_sword_sets

Writes the sheet gear_short_sword_sets.png. Workbench only: no GPU turn.
"""
import sys
from pathlib import Path

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import gear_sword_sets as s  # noqa: E402

mat = g.material
LONG, WIDE, GRIP = 3.9, 1.5, 1.15  # the blade, and the one-hand grip

# The guards, each from its right half, top middle round to foot middle. Every one droops toward the hand.
DROOP = [(0.0, 0.18), (0.75, 0.18), (1.2, 0.02), (1.42, -0.4), (1.22, -0.46), (1.02, -0.16), (0.6, -0.14), (0.0, -0.2)]
SHELL = [(0.0, 0.5), (0.5, 0.46), (0.92, 0.3), (1.16, 0.04), (1.22, -0.3), (1.04, -0.3), (0.9, -0.14), (0.0, -0.18)]
# Hoshiakari's arm, drawn on the right: it leaves the guard and rises beside the blade to hold a second light.
ARM = [(0.3, 0.12), (1.0, 0.2), (1.62, 0.7), (1.86, 1.4), (1.62, 1.46), (1.42, 0.92), (0.95, 0.52), (0.3, 0.42)]
STAR = (1.78, 1.72)  # where the arm's light sits


def design(name, rarity, note, mats, **more):
    base = dict(length=LONG, width=WIDE, profile="wedge", grip_len=GRIP, span=2.3, window=None, bow=False, arm=False)
    return s.design(name, rarity, note, mats, **dict(base, **more))


BRONZE, SCRAP = ("bronze", "bronze", "leather", "bronze"), ("scrap", "scrap", "leather", "scrap")
DESIGNS = (
    # lift: in colour, plain iron toned to a mid grey with a light edge (gear_icons.py; research's look at batch 3's fixes, 2026-11-16: the same rule for batch 1's two iron swords)
    design("Iron Short Sword", "Common", "A broad wedge with a ridge, a short thick bar, a wheel pommel.", s.IRON,
           section="ridge", bands=(0.5,), lift="iron"),
    design("Bronze Short Sword", "Common", "A short leaf blade with a rib, a thick stub of a guard, a cap pommel.", BRONZE,
           length=3.8, width=1.3, start=0.62, profile="leaf", section="ridge", span=1.75, bands=(0.08, 0.92), pommel="cap"),
    design("Scrap Short Sword", "Common", "A flat bar, its point cut on the slant; bolt heads on the guard, a wrapped "
           "grip, a cap.", SCRAP, width=1.3, profile="parallel", tip="clip", section="flat", span=2.1, ends="disc",
           wraps=4, pommel="cap"),

    design("Lanternsteel Short Sword", "Uncommon", "A fuller, a guard that droops to the hand, a wrap, a brass collar and "
           "rim.", s.STEEL, guard=DROOP, collar=True, wraps=5, rim="brass"),
    design("Rowsmith Short Sword", "Uncommon", "A ridge, a bar with end blocks, brass bands and a brass lozenge pommel.",
           ("steel", "steel", "leather", "brass"), section="ridge", span=2.4, ends="block", bands=(0.08, 0.92),
           band_mat="brass", pommel="lozenge"),
    design("Stallguard Short Sword", "Uncommon", "An even blade, a bar that ends in brass acorns, a pear pommel.", s.STEEL,
           width=1.3, start=0.7, profile="parallel", span=2.3, ends="acorn", trim="brass", wraps=5, pommel="pear"),

    design("Edge of Embers", "Rare", "A drooping guard with one small stone, a line in the fuller, the pommel cut in "
           "facets.", s.BLUED, guard=DROOP, stone=("stone", 0.19), wraps=5, bands=(0.05, 0.95), pommel="facet",
           lines=((0.0, 0.3, 0.34),)),
    design("Edge of Hoarfrost", "Rare", "An even blade, a shell guard rising over its foot, the stone on the shell, a "
           "pear pommel.", s.BLUED, width=1.3, start=0.7, profile="parallel", guard=SHELL, stone=("stone", 0.19), wraps=5,
           pommel="pear", lines=((0.0, 0.42, 0.4),)),
    design("Edge of Gales", "Rare", "A leaf blade with a rib and two lines, an S guard, a fishtail pommel with the stone "
           "set in it.", s.BLUED, length=3.8, width=1.3, start=0.62, profile="leaf", section="ridge", guard="s", wraps=5, bands=(0.05,),
           pommel="tail", pommel_stone=("stone", 0.14), lines=((-0.22, 0.4, 0.3), (0.22, 0.4, 0.3))),

    design("Stormcall Edge", "Epic", "The drooping guard a step larger, a filigree foot, the stone in a bezel.", s.RICH,
           guard=s.scaled(DROOP, 1.3, 1.35), trim="filigree", stone=("glow", 0.24), bezel="ring", foot="plate", wraps=6,
           bands=(0.05, 0.95), pommel="facet", stud="filigree", lines=((0.0, 0.5, 0.3),)),
    design("Gloamforge Edge", "Epic", "An even blade, a wide shell with two filigree tines up the blade, a lozenge "
           "pommel.", s.RICH, width=1.3, start=0.7, profile="parallel", guard=s.scaled(SHELL, 1.32, 1.2), trim="filigree",
           stone=("glow", 0.24), bezel="ring", foot="tines", wraps=6, bands=(0.05, 0.95), band_mat="filigree",
           pommel="lozenge", stud="filigree"),
    design("Nightloom Edge", "Epic", "A leaf blade with two filigree lines, a long bar with a shuttle at each end, a "
           "spool pommel.", ("rich", "rich", "leather", "filigree"), length=3.8, width=1.3, start=0.62, profile="leaf", section="ridge", span=3.0,
           ends="shuttle", trim="filigree", stone=("glow", 0.24), bezel="ring", wraps=6, bands=(0.05, 0.95),
           pommel="spool", lines=((-0.22, 0.4, 0.3), (0.22, 0.4, 0.3))),

    design("Hotaru, the Small Light", "Legendary", "Its one new form: a window cut through the blade, with a light "
           "held in it.", s.GILT, section="ridge", guard=DROOP, trim="ivory", stone=("lit", 0.24), bezel="ring",
           window=(0.4, 0.36, 0.7), bands=(0.05, 0.5, 0.95), pommel="facet", stud="ivory", edge=True),
    design("Yukiakari, the Snowlight", "Legendary", "Its one new form: a bow runs from the guard to the pommel, over "
           "the hand.", s.GILT, width=1.3, start=0.7, profile="parallel", span=2.5, ends="lozenge", trim="ivory",
           stone=("lit", 0.24), bow=True, bands=(0.05, 0.95), pommel="pear", lines=((0.0, 0.42, 0.4),), edge=True),
    design("Hoshiakari, the Far Star", "Legendary", "Its one new form: an arm leaves the guard and holds a second light "
           "out beside the blade.", s.GILT, length=3.8, width=1.3, start=0.62, profile="leaf", section="ridge", guard=DROOP, trim="ivory",
           stone=("lit", 0.24), bezel="ring", arm=True, bands=(0.05, 0.95), pommel="facet", stud="ivory", edge=True),
)
assert all(len(d["name"]) <= 24 for d in DESIGNS), "a name is over 24 characters"


def more(d, parts):
    """The three Legendaries' new forms."""
    out = []
    if d["window"]:  # a long six-sided window through the blade, and the light in it
        at, wide, long = d["window"]
        z = at * d["length"]
        cut = g.plate("Cut", [(0, z + long), (wide, z + long * 0.4), (wide, z - long * 0.4), (0, z - long),
                              (-wide, z - long * 0.4), (-wide, z + long * 0.4)], 1.0, d["blade"])
        bl.smooth_by_angle(bl.subtract(parts[0], [cut]), 20.0)
        out.append(bl.place(bl.sphere("Light", 0.25, 8, 4, mat("lit")), (0, 0, z), (0, 0, 0), (1, 0.55, 1.7)))
    if d["bow"]:  # from the bar's lower end, out over the hand, in to the pommel
        foot = s.TOP - d["grip_len"]
        path = bl.smooth_path([(d["span"] / 2 - 0.05, 0, 0.0), (1.62, 0, -0.5), (1.55, 0, foot + 0.2), (1.0, 0, foot - 0.3),
                               (0.2, 0, foot - 0.33)], 22)
        out.append(bl.smooth_by_angle(bl.tube_along("Bow", [Vector(p) for p in path], [0.085] * len(path), sides=8,
                                                    material=mat(d["guard_mat"])), 40.0))
    if d["arm"]:  # on the side that lies upper left in the square
        out.append(g.plate("Arm", [(-x, z) for x, z in ARM[::-1]], 0.24, d["guard_mat"], bevel=0.05))
        x, z = -STAR[0], STAR[1]
        for side in (-1, 1):
            star = bl.sphere("Star", 0.3, segments=6, rings=3, material=mat("lit"))
            out.append(bl.place(star, (x, side * 0.05, z), (0, 0, 30), (1, 0.5, 1.15)))
        out.append(bl.place(bl.torus("Bezel", 0.33, 0.055, 20, 8, mat(d["trim"])), (x, 0, z), (90, 0, 0)))
    return out


WORDS = dict(
    file="gear_short_sword_sets.png",
    title="Grow your Anime: the Short Sword in three designs at each rarity, in grey (AR6, batch 1)",
    lead="The Warrior's off hand, from the Sword's parts. Never taken for the Sword at the slot's size: a broad wedge where the "
         "Sword is a line, a guard that droops to the hand where the Sword's turns to the point, a one-hand grip.",
    notes=(
        "A set keeps its word. From Rare up this kind's near word is \"Edge\", so no name repeats a Sword's; the ladder's \"Brand "
        "of Sparks\" and \"Duskwire Brand\" give way to the sets. The ring stays on Scrap Sword alone.",
        "Each Legendary's one new form: Hotaru (a firefly), a window in the blade with a light in it; Yukiakari (the glow of snow "
        "at night), a bow over the hand; Hoshiakari (starlight), an arm that holds a second light out.",
        "For the verdict: is it never the Sword at 38 points (the Sword's five stand at the right of the row)? Does each read "
        "apart from its two neighbours? Does each Legendary outrank every Epic by shape?",
        "Not here yet: colour, frames, the class mark. Yukiakari and Hoshiakari are new names, for research's check (the content check offers Myojo too).",
    ),
)


def main():
    out = bl.out_dir()
    swords = [d for d in s.DESIGNS if d["name"].endswith("*")]  # the Sword's own five, one a rarity
    beside = ("The Sword, one a rarity", list(s.renders(out, swords).values()))
    s.sheet(out, s.renders(out, DESIGNS, more), DESIGNS, WORDS, beside)


if __name__ == "__main__":
    main()
