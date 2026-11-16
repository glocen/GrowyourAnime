"""AR6, batch 2: Bracers in three designs at each rarity, in grey: a blockout for research's verdict.

One family: one vambrace lying on the diagonal, the elbow high on the left and the wrist low on the right, a sleeve of
plate open at both ends so its hollow shows, strapped round. A sleeve on the slant, so it never reads as the Gloves'
cuff or the Boots. A design is the sleeve, its plates and straps, and what its outer face carries. A rarity keeps the
ladder's rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Vambraces.

Each Legendary's one new form changes the silhouette: Asayake's rays fan out from its outer side as the sun comes up,
Hokushin carries a four-pointed star whose points reach past the sleeve, Hakkou wears a ring of light round its middle.

    blender -b --factory-startup --python tools/blender/gear_bracers_sets.py -- build/handoff/Gear/bracers_sets

Writes the sheet gear_bracers_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 16.0, 18.0    # a little from above, turned to show the sleeve's round
FILL, DROP = 0.8, 0.0
LEAST = 0.86
SLANT = -48.0              # the sleeve's lean from upright: the elbow's end high on the picture's left
DEEP = 0.86                # the sleeve's depth to its width: a forearm's oval
OPEN = (-150.0, 150.0)     # the sleeve's plate: open at its back, where it's laced


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(straps=2, strap_mat="leather", bands=0, flare=False,
                                                         rims=None, studs=None, rivets=False, lozenge=None,
                                                         facets=False, ridge=False), **more))


DESIGNS = (
    design("Iron Bracers", "Common", "A plain iron sleeve on two leather straps.", "iron"),
    design("Bronze Bracers", "Common", "Bronze with a rolled rim at each end, one strap.", "bronze", rims="bronze",
           straps=1),
    design("Scrap Bracers", "Common", "Plates beaten flat and riveted, three cord straps.", "scrap", facets=True,
           rivets=True, straps=3, strap_mat="cord"),

    design("Lanternsteel Bracers", "Uncommon", "Bright steel in three bands, a brass rim at each end.", "steel", bands=3,
           rims="brass", straps=0),
    design("Rowsmith Bracers", "Uncommon", "A ridge down the outside, a brass lozenge, a flared elbow.", "steel",
           ridge=True, lozenge="brass", flare=True),
    design("Stallguard Bracers", "Uncommon", "Brass studs down the outside, a brass rim at each end.", "steel",
           studs="brass", rims="brass"),

    design("Vambraces of Embers", "Rare", "A swelling frame round one stone on the outside, a line round each end.",
           "blued", line="filigree", orn="Embers", stone=("stone", 0.12)),
    design("Vambraces of Hoarfrost", "Rare", "A sleeve cut in facets, a square stone in a spade.", "blued", facets=True,
           line="filigree", orn="Hoarfrost", stone=("stone", 0.12), cut="square"),
    design("Vambraces of Gales", "Rare", "A vane sweeps back from the elbow, the stone on the outside.", "blued",
           line="filigree", orn="Gales", stone=("stone", 0.12), flare=True),

    design("Stormcall Vambraces", "Epic", "Filigree hooks rise from the outer side and curl out. A glowing stone.",
           "rich", trim="filigree", line="filigree", bands=2, orn="Stormcall", stone=("glow", 0.15)),
    design("Gloamforge Vambraces", "Epic", "Filigree prongs stand on the outer side, a ridge, a square glowing stone.",
           "rich", trim="filigree", ridge=True, flare=True, orn="Gloamforge", stone=("glow", 0.15), cut="square"),
    design("Nightloom Vambraces", "Epic", "A shuttle lies along the outside, four bands, a glowing stone.", "rich",
           trim="filigree", bands=4, line="filigree", orn="Nightloom", stone=("glow", 0.15)),

    design("Asayake, the Red Morning", "Legendary", "Its one new form: rays fan out from the outer side as the sun "
           "comes up.", "gilt", trim="ivory", rims="ivory", orn="rays", stone=("lit", 0.15), edge=True,
           strap_mat="ivory"),
    design("Hokushin, the Pole Star", "Legendary", "Its one new form: a four-pointed star on the outside, its points "
           "past the sleeve.", "gilt", trim="ivory", rims="ivory", bands=2, orn="star", stone=("lit", 0.18),
           edge=True, strap_mat="ivory"),
    design("Hakkou, the Radiance", "Legendary", "Its one new form: a ring of light stands round the sleeve's middle.",
           "gilt", trim="ivory", line="ivory", flare=True, orn="ring", stone=("lit", 0.15), edge=True,
           strap_mat="ivory"),
)


# --- the sleeve, built upright: z up the arm from the wrist (-1) to the elbow (1); -y is its outer face ---------------

def radius(z):
    return 0.42 + 0.12 * (z + 1) / 2 + 0.04 * math.sin(math.pi * (z + 1) / 2)


def face(z, out=0.0):
    """A point on the sleeve's outer face (toward the camera) at height z."""
    return (0.0, -radius(z) * DEEP - 0.03 - out, z)


def arc_rim(name, r, minor, key, z):
    t = bl.torus(name, r, minor, 48, 8, mat(key), arc=OPEN[1] - OPEN[0])
    bl.place(t, (0, 0, 0), (0, 0, OPEN[0] - 90.0))
    return bl.smooth_by_angle(bl.place(t, (0, 0, z), (0, 0, 0), (1, DEEP, 1)), 40.0)


def sleeve(d):
    key, trim, parts = d["key"], d["trim"], []
    steps = 10 if d["facets"] else 44
    top = 1.0
    prof = [(radius(-1.0 + 2.0 * i / 10), -1.0 + 2.0 * i / 10) for i in range(11)]
    if d["flare"]:
        prof += [(radius(1.0) + 0.08, 1.12), (radius(1.0) + 0.2, 1.24)]
        top = 1.24
    if d["bands"]:
        for k in range(d["bands"]):
            z0, z1 = -1.0 + 2.0 * k / d["bands"], -1.0 + 2.0 * (k + 1) / d["bands"] + 0.06
            # each band laps over the one before it with a lip, so its seam catches the light at slot size
            band = [(radius(z) + 0.035 * k, z) for z in (z0, (z0 + z1) / 2, z1)]
            parts.append(p.lathe("Band", band, key, *OPEN, thick=0.05, deep=DEEP, steps=steps))
        if d["flare"]:
            parts.append(p.lathe("Flare", prof[-3:], key, *OPEN, thick=0.05, deep=DEEP, steps=steps))
    else:
        parts.append(p.lathe("Sleeve", prof, key, *OPEN, thick=0.05, deep=DEEP, steps=steps))
    parts.append(p.lathe("Liner", [(r * 0.94, z) for r, z in prof], "liner", *OPEN, thick=0.02, deep=DEEP, steps=steps))
    for z in (-1.0, top):
        r = radius(-1.0) if z < 0 else prof[-1][0]
        if d["rims"]:
            parts.append(arc_rim("Rim", r + 0.01, 0.04, d["rims"], z))
        if d["line"]:
            parts.append(arc_rim("Line", r + 0.005, 0.022, d["line"], z * 0.86))
    if d["edge"]:
        parts.append(arc_rim("Edge", radius(0.0) + 0.02, 0.025, "lit", -0.62))
    for k in range(d["straps"]):
        z = -0.6 + 1.2 * k / max(1, d["straps"] - 1) if d["straps"] > 1 else 0.0
        parts.append(p.hoop("Strap", radius(z) + 0.03, 0.045, d["strap_mat"], z, deep=DEEP, high=1.6))
        bx, by, bz = face(z, 0.04)
        parts.append(bl.place(bl.cylinder("Buckle", 0.09, 0.06, segments=4, material=mat(trim if d["orn"] else
                                                                                       "iron")),
                              (0.36, by * 0.82, bz), (90, 0, 45)))
    if d["ridge"]:
        crest = [(-1.0, 0.0), (1.0, 0.0), (1.0, 0.07), (0.0, 0.1), (-1.0, 0.07)]
        pts = [(face(z)[1] - h, z) for z, h in crest]
        parts.append(bl.profile("Ridge", pts, 0.08, mat(key)))
    if d["studs"]:
        for z in (-0.7, -0.35, 0.0, 0.35, 0.7):
            parts.append(p.ball("Stud", 0.06, d["studs"], face(z)))
    if d["rivets"]:
        for z in (-0.8, 0.0, 0.8):
            for a in (-60, 0, 60):
                x = radius(z) * math.sin(math.radians(a))
                y = -radius(z) * DEEP * math.cos(math.radians(a)) - 0.02
                parts.append(p.ball("Rivet", 0.045, key, (x, y, z), segments=8, rings=5))
    if d["lozenge"]:
        parts.append(p.flat("Lozenge", [(0, 0.36), (0.18, 0.0), (0, -0.36), (-0.18, 0.0)], 0.06, d["lozenge"],
                            y=face(0.0)[1] - 0.06))

    # what the outer face carries: the set's ornament round its stone, or a Legendary's new form
    orn, stone_at = d["orn"], face(0.05, 0.06)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.42, (0, 0.05)), 0.05, trim, y=stone_at[1] + 0.04))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, 0.36, 0.9, 1.0, 1.0), 0.07, trim, y=0.0))
    elif orn in ("Stormcall", "Gloamforge"):
        crest = p.turned(p.set_ornament(orn, 0.62, (0, 0)), -90.0, (0, 0))   # standing out from the outer side
        parts.append(p.flat("Crest", p.shifted(crest, radius(0.0) + 0.16, 0.0), 0.07, trim, y=0.0))
    elif orn == "Nightloom":
        shuttle = p.turned(p.shifted(p.SHUTTLE, 0, 0, 2.6, 1.3), 90.0, (0, 0))
        parts.append(p.flat("Shuttle", shuttle, 0.08, trim, y=face(0.0)[1] - 0.02))
    elif orn == "rays":
        for k, angle in enumerate(range(-60, 61, 20)):
            ray = p.turned(p.leaf(0.7 + 0.35 * math.cos(math.radians(angle) * 1.4), 0.2), -90.0 - angle, (0, 0))
            parts.append(p.flat("Ray", p.shifted(ray, radius(0.0) - 0.05, 0.0), 0.05, trim if k % 2 else key, y=0.06))
    elif orn == "star":
        parts.append(p.flat("Star", p.star(4, 1.0, 0.24, turn=90.0, long=1.0), 0.07, trim, y=face(0.0)[1] - 0.02))
    elif orn == "ring":
        ring = bl.torus("Ring", 1.05, 0.05, 48, 8, mat("lit"))
        parts.append(bl.smooth_by_angle(bl.place(ring, (0, 0, 0.05), (78, 0, 0), (1, 1, 1)), 40.0))
        parts.append(bl.smooth_by_angle(bl.place(bl.torus("Ring", 1.18, 0.03, 48, 8, mat(trim)), (0, 0, 0.05),
                                                 (78, 0, 0)), 40.0))
    parts += p.stone_of(d, 1.0, stone_at)
    slant = Matrix.Rotation(math.radians(SLANT), 4, "Y")
    for obj in parts:
        p.move(obj, slant)
    return parts


def build(d):
    return p.scene_of(lambda: sleeve(d), TILT, SPIN)


WORDS = dict(
    file="gear_bracers_sets.png",
    title="Grow your Anime: Bracers in three designs at each rarity, in grey (AR6, batch 2)",
    lead="One vambrace on the slant, the elbow high and the wrist low, a sleeve of plate open at both ends, strapped "
         "round. A design is the sleeve, its plates and straps and what its outer face carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Vambraces.",
        "Each Legendary's one new form: Asayake (a red morning sky), rays fanning from the outer side; Hokushin "
        "(the pole star), a four-pointed star past the sleeve; Hakkou (radiance), a ring of light round the middle.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as bracers, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
