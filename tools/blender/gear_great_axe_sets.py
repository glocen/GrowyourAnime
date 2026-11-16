"""AR6, batch 3: the Great Axe in three designs at each rarity, in grey: a blockout for research's verdict.

The Tank's main hand. One family: a two-hand haft laid on the diagonal as the swords lie, its head up and to the right,
a broad blade on the haft's upper side so its mass fills the square's top left, and the head's back (a spike, a
hammer's face, prongs) toward the bottom right. No other class holds a blade on a haft, so it's never the Sword, the
Staff or the Baton at 38 points. A design is the blade's outline, the head's back, the haft's fittings and what the
blade's face carries. A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and the near word from
Rare up is Greataxe.

Each Legendary's one new form changes the silhouette: Meigetsu's blade has a twin on its back, the two crescents
making a full moon's round; Gingetsu's upper horn sweeps up past the haft like a bow's tip; Kinsei's haft rises over
its head into a spear's point with a four-pointed star at its foot.

    blender -b --factory-startup --python tools/blender/gear_great_axe_sets.py -- build/handoff/Gear/great_axe_sets

Writes the sheet gear_great_axe_sets.png. Workbench only: no GPU turn.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
FILL, DROP, LEAST = 0.86, 0.0, 0.9
R = 0.15                        # the haft's radius
FOOT, HEAD0, HEAD1 = -2.3, 1.65, 3.05   # the haft's foot; the socket, bottom and top

# The blades, on the haft's upper side (-x), each as three spans drawn smooth: the top from the socket to the upper
# horn, the edge from horn to horn, the beard from the lower horn back to the socket. The horns stay sharp.
CRESCENT = ([(-0.18, 2.95), (-0.65, 3.08), (-1.2, 3.4), (-1.62, 3.82)],
            [(-1.62, 3.82), (-1.96, 3.45), (-2.16, 2.8), (-2.16, 2.1), (-1.96, 1.4), (-1.62, 0.86), (-1.42, 0.66)],
            [(-1.42, 0.66), (-1.3, 1.05), (-0.95, 1.48), (-0.55, 1.72), (-0.18, 1.8)])
HALF_MOON = ([(-0.18, 2.88), (-0.85, 3.2), (-1.5, 3.42)],
             [(-1.5, 3.42), (-2.0, 3.1), (-2.22, 2.45), (-2.05, 1.78), (-1.55, 1.4)],
             [(-1.55, 1.4), (-0.88, 1.56), (-0.18, 1.86)])
CLEAVER = ([(-0.18, 3.0), (-1.9, 3.2)],
           [(-1.9, 3.2), (-2.04, 3.1), (-2.13, 2.35), (-2.06, 1.48)],
           [(-2.06, 1.48), (-1.0, 1.62), (-0.18, 1.88)])
BEARD = ([(-0.18, 3.0), (-0.9, 3.06), (-1.62, 3.3)],
         [(-1.62, 3.3), (-1.95, 2.95), (-2.06, 2.2), (-1.9, 1.4), (-1.62, 0.7), (-1.36, 0.36)],
         [(-1.36, 0.36), (-1.24, 0.82), (-0.85, 1.42), (-0.18, 1.8)])
FAN = ([(-0.18, 2.92), (-0.75, 3.2), (-1.3, 3.62), (-1.75, 3.92)],
       [(-1.75, 3.92), (-2.1, 3.4), (-2.24, 2.5), (-2.08, 1.6), (-1.65, 0.98), (-1.36, 0.82)],
       [(-1.36, 0.82), (-1.2, 1.25), (-0.7, 1.64), (-0.18, 1.84)])
# Gingetsu's: the upper horn sweeps on past the haft's top, like a bow's tip.
BOW = ([(-0.18, 2.95), (-0.6, 3.25), (-0.92, 3.75), (-1.0, 4.35), (-0.88, 4.95)],
       [(-0.88, 4.95), (-1.3, 4.58), (-1.75, 3.95), (-2.08, 3.2), (-2.18, 2.5), (-2.1, 1.85), (-1.85, 1.3), (-1.45, 0.8)],
       [(-1.45, 0.8), (-1.3, 1.12), (-0.95, 1.5), (-0.55, 1.74), (-0.18, 1.8)])


def outline(spans):
    """The blade's outline: each span drawn smooth through its points, the corners between them kept."""
    out = []
    for span in spans:
        pts = p.curve(span, max(2, 5 * (len(span) - 1)))
        out += pts[:-1]
    return out + [spans[-1][-1]]


def edge_of(spans):
    """The cutting edge, from horn to horn."""
    return p.curve(spans[1], 32)

# The head's back (+x).
SPIKE = [(0.18, 2.72), (0.7, 2.56), (1.26, 2.38), (0.7, 2.24), (0.18, 2.1)]
HOOK = [(0.18, 2.75), (0.8, 2.66), (1.25, 2.4), (1.32, 2.0), (1.12, 2.2), (0.72, 2.28), (0.18, 2.1)]


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(blade=CRESCENT, back=None, haft="wood", haft_bands=(),
                                                         grip="wood", turns=0, collar=None, butt="cap", top="cap",
                                                         bolts=False, cut=None, twin=False, spear=False), **more))


DESIGNS = (
    design("Iron Greataxe", "Common", "A bearded crescent, a plain socket, iron bands on an ash haft.", "iron",
           haft_bands=(-1.5, -0.2, 1.2)),
    design("Bronze Greataxe", "Common", "A round half moon of bronze, a hammer's face on its back.", "bronze",
           blade=HALF_MOON, back="hammer", haft_bands=(-0.4,), butt="pear"),
    design("Scrap Greataxe", "Common", "A slab of plate cut square and bolted on, a cord grip.", "scrap",
           blade=CLEAVER, bolts=True, grip="cord", turns=6, haft_bands=(1.2,)),

    design("Lanternsteel Greataxe", "Uncommon", "A wide fan of bright steel, a brass collar, a wrapped grip.", "steel",
           blade=FAN, collar="brass", grip="leather", turns=7, butt="pear"),
    design("Rowsmith Greataxe", "Uncommon", "A long beard, a spike on the back, brass bands down the haft.", "steel",
           blade=BEARD, back="spike", haft_bands=(-0.4, 0.6), trim="brass", grip="leather", turns=6),
    design("Stallguard Greataxe", "Uncommon", "A bearded crescent and a hammer's face, a brass cap and foot.", "steel",
           back="hammer", collar="brass", top="brass", butt="brass", grip="leather", turns=6),

    design("Greataxe of Embers", "Rare", "A half moon, a swelling frame round one stone on the blade.", "blued",
           blade=HALF_MOON, orn="Embers", stone=("stone", 0.13), line="filigree", grip="leather", turns=7,
           butt="facet"),
    design("Greataxe of Hoarfrost", "Rare", "A cleaver's square blade, a square stone in a spade, a hooked back.",
           "blued", blade=CLEAVER, back="hook", orn="Hoarfrost", stone=("stone", 0.13), cut="square",
           line="filigree", grip="leather", turns=7, butt="facet"),
    design("Greataxe of Gales", "Rare", "A fan blade, a vane sweeping back from the socket, the stone at its root.",
           "blued", blade=FAN, orn="Gales", stone=("stone", 0.13), line="filigree", grip="leather", turns=7,
           butt="facet"),

    design("Stormcall Greataxe", "Epic", "Filigree curls roll out from the blade's top, a glowing stone, a spike.", "rich",
           trim="filigree", back="spike", orn="Stormcall", stone=("glow", 0.15), line="filigree", haft="rich",
           haft_bands=(-0.4, 0.6), grip="leather", turns=7, collar="filigree", butt="spike"),
    design("Gloamforge Greataxe", "Epic", "A long beard, filigree prongs standing on the back, a square stone.", "rich",
           trim="filigree", blade=BEARD, orn="Gloamforge", stone=("glow", 0.15), cut="square", line="filigree",
           haft="rich", grip="leather", turns=7, collar="filigree", butt="spike"),
    design("Nightloom Greataxe", "Epic", "A fan blade, a shuttle lashed along the haft under the head.", "rich",
           trim="filigree", blade=FAN, orn="Nightloom", stone=("glow", 0.15), line="filigree", haft="rich",
           grip="leather", turns=7, collar="filigree", butt="spike"),

    design("Meigetsu, the Full Moon", "Legendary", "Its one new form: a twin blade on the back, the two crescents "
           "a full moon's round.", "gilt", trim="ivory", stone=("lit", 0.15), haft="ivory", haft_bands=(-0.4, 0.6),
           grip="leather", turns=7, collar="ivory", butt="facet", top="facet", twin=True, edge=True),
    design("Gingetsu, the Silver Bow", "Legendary", "Its one new form: the blade's upper horn sweeps up past the haft "
           "like a bow's tip.", "gilt", trim="ivory", blade=BOW, back="spike", stone=("lit", 0.15), haft="ivory",
           haft_bands=(-0.4, 0.6), grip="leather", turns=7, collar="ivory", butt="facet", edge=True),
    design("Kinsei, the Golden Star", "Legendary", "Its one new form: the haft rises over the head into a spear's "
           "point, a star at its foot.", "gilt", trim="ivory", blade=HALF_MOON, stone=("lit", 0.15), haft="ivory",
           haft_bands=(-0.4, 0.6), grip="leather", turns=7, collar="ivory", butt="facet", spear=True, edge=True),
)


def head(d):
    key, trim, parts = d["key"], d["trim"], []
    blade = d["blade"]
    parts.append(p.flat("Blade", outline(blade), 0.14, key, bevel=0.035))
    if d["edge"]:
        pts = [(x - 0.02, -0.075, z) for x, z in edge_of(blade)]
        parts.append(p.tube("Edge", p.curve(pts, 30), 0.03, "lit"))
    if d["line"]:
        inner = [(x * 0.82, z) for x, z in edge_of(blade)]
        mid = sum(z for _, z in inner) / len(inner)
        pts = [(x, -0.075, mid + (z - mid) * 0.86) for x, z in inner]
        parts.append(p.tube("Line", p.curve(pts, 24), 0.022, d["line"]))
    if d["twin"]:
        parts.append(p.flat("Twin", p.flipped(outline(CRESCENT)), 0.14, key, bevel=0.035))
        pts = [(-x + 0.02, -0.075, z) for x, z in edge_of(CRESCENT)]
        parts.append(p.tube("Edge", p.curve(pts, 30), 0.03, "lit"))
    back = d["back"]
    if back in ("spike", "hook"):
        parts.append(p.flat("Back", SPIKE if back == "spike" else HOOK, 0.14, trim if back == "hook" else key,
                            bevel=0.03))
    elif back == "hammer":
        parts.append(bl.place(bl.box("Hammer", (0.62, 0.5, 0.62), mat(key)), (0.48, 0, 2.42)))
        parts.append(bl.place(bl.box("Face", (0.08, 0.58, 0.7), mat(key)), (0.8, 0, 2.42)))
    parts.append(p.rod("Socket", HEAD0, HEAD1, 0.21, key, sides=8))
    if d["collar"]:
        parts += p.bands((HEAD0 - 0.02, HEAD1 + 0.02), 0.21, d["collar"], minor=0.05)
    top = d["top"]
    if d["spear"]:
        parts.append(p.rod("Neck", HEAD1, HEAD1 + 0.5, 0.11, key))
        parts.append(p.flat("Point", [(0, 5.3), (0.26, 4.4), (0.16, 3.62), (0, 3.52), (-0.16, 3.62), (-0.26, 4.4)],
                            0.1, key, bevel=0.03))
        parts.append(p.flat("Star", p.shifted(p.star(4, 0.95, 0.22, long=1.0), 0, 3.62), 0.08, trim))
        parts += p.stone("lit", 0.13, (0, -0.09, 3.62), trim)
    elif top in ("cap", "brass"):
        parts.append(p.rod("Top", HEAD1, HEAD1 + 0.14, 0.23, "brass" if top == "brass" else key, top=0.17, sides=8))
    elif top == "facet":
        gem = bl.sphere("Top", 0.24, segments=6, rings=3, material=mat(trim))
        parts.append(bl.place(gem, (0, 0, HEAD1 + 0.2), (0, 0, 30), (1, 1, 1.4)))
    if d["bolts"]:
        for x, z in ((-0.55, 2.75), (-0.55, 2.05), (-1.6, 2.85), (-1.62, 1.82)):
            parts.append(p.ball("Bolt", 0.08, "iron", (x, -0.08, z), squash=(1, 0.6, 1), segments=6, rings=4))

    # what the blade's face carries: the set's ornament round its stone
    orn, at = d["orn"], (-0.95, -0.09, 2.38)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.8, (at[0], at[2])), 0.05, trim, y=-0.08))
    elif orn == "Gales":
        vane = p.turned(p.shifted(p.VANE, 0, 0, 1.1, 1.1), -30.0, (0, 0))
        parts.append(p.flat("Vane", p.shifted(vane, 0.2, 2.3), 0.1, trim))
    elif orn == "Stormcall":
        parts.append(p.curl((-0.95, 3.28), -1, 1.5, trim, turn=10.0, r=0.08))
        parts.append(p.curl((-0.45, 3.05), 1, 1.05, trim, turn=-10.0, r=0.08))
    elif orn == "Gloamforge":
        crest = p.turned(p.set_ornament(orn, 0.7, (0, 0)), -90.0, (0, 0))
        parts.append(p.flat("Crest", p.shifted(crest, 0.5, 2.42), 0.1, trim))
    elif orn == "Nightloom":
        shuttle = p.turned(p.shifted(p.SHUTTLE, 0, 0, 2.6, 2.0), 90.0, (0, 0))
        parts.append(p.flat("Shuttle", p.shifted(shuttle, 0, 0.4), 0.12, trim, y=-0.16))
        parts += p.bands((-0.4, 1.2), R + 0.1, trim, minor=0.035)
    parts += p.stone_of(d, 1.9, at)
    return parts


def axe(d):
    parts = head(d)
    parts.append(p.rod("Haft", FOOT, HEAD0, R, d["haft"]))
    parts += p.bands(d["haft_bands"], R, d["trim"] if d["haft"] != "wood" else "iron" if d["key"] == "scrap" else d["key"])
    if d["turns"]:
        parts += p.grip_wrap(FOOT + 0.25, FOOT + 1.75, R + 0.015, d["grip"], d["turns"])
    parts += p.butt(d["butt"] if d["butt"] not in ("brass",) else "cap", FOOT, R,
                    "brass" if d["butt"] == "brass" else d["trim"] if d["rarity"] != "Common" else d["key"])
    return p.laid(parts)


def build(d):
    return p.scene_of(lambda: axe(d), 0.0, 0.0)


WORDS = dict(
    file="gear_great_axe_sets.png",
    title="Grow your Anime: the Great Axe in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Tank's main hand: a two-hand haft on the diagonal, its broad blade filling the square's top left and the "
         "head's back toward the bottom right. A design is the blade's outline, the back, the haft and what the blade carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Greataxe.",
        "Each Legendary's one new form: Meigetsu (the bright full moon), a twin blade on the back; Gingetsu (the silver "
        "moon), the upper horn drawn past the haft like a bow; Kinsei (Venus, the golden star), a spear's point and a star.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a great axe, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
