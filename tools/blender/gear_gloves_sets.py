"""AR6, batch 2: Gloves in three designs at each rarity, in grey: a blockout for research's verdict.

One family: the right gauntlet seen from the back of the hand, fingers up, the thumb out to the side, a plate over the
back of the hand and a cuff flaring at the wrist. A hand's outline, so it reads as nothing else. A design is the back
plate, the fingers' plates, the cuff, and what the hand carries. A rarity keeps the ladder's rule, a set keeps its word
(gear_parts.py), and the near word from Rare up is Gauntlets.

Each Legendary's one new form changes the silhouette: Kirameki's cuff spreads into a ring of points like a star's
glint, Nagareboshi trails a falling star's streak from the back of the hand past the wrist, Yuubae holds a setting sun's
disc behind the hand.

    blender -b --factory-startup --python tools/blender/gear_gloves_sets.py -- build/handoff/Gear/gloves_sets

Writes the sheet gear_gloves_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 6.0, -16.0    # nearly level, turned a little to show the hand's depth
FILL, DROP = 0.8, 0.0
LEAST = 0.86
# The fingers: x of the knuckle, length, splay in degrees; the thumb sits on the left (the right hand, from its back).
FINGERS = ((-0.4, 0.82, 8.0), (-0.13, 0.98, 2.0), (0.14, 0.94, -3.0), (0.41, 0.74, -9.0))
KNUCKLE = 0.62
BACK = -0.3                # the back of the hand's face, toward the camera


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(glove="leather", plated=False, knuckles=False, cuff="bell",
                                                         cuff_mat=key, rims=None, studs=None, rivets=False,
                                                         lozenge=None, facets=False), **more))


DESIGNS = (
    design("Iron Gloves", "Common", "Leather fingers, an iron plate on the back, a plain bell cuff.", "iron"),
    design("Bronze Gloves", "Common", "A short bronze cuff with a rolled rim, a bar over the knuckles.", "bronze",
           cuff="short", rims="bronze", knuckles=True),
    design("Scrap Gloves", "Common", "A riveted back plate and a cuff of beaten plates.", "scrap", rivets=True,
           facets=True),

    design("Lanternsteel Gloves", "Uncommon", "Bright steel plates down every finger, a brass rim on the cuff.",
           "steel", plated=True, rims="brass"),
    design("Rowsmith Gloves", "Uncommon", "A brass lozenge on the back, a bar over the knuckles, a long cuff.", "steel",
           lozenge="brass", knuckles=True, cuff="long"),
    design("Stallguard Gloves", "Uncommon", "Brass studs over the knuckles and round the cuff.", "steel", studs="brass",
           rims="brass"),

    design("Gauntlets of Embers", "Rare", "Plated fingers, a swelling frame round one stone on the back.", "blued",
           plated=True, line="filigree", orn="Embers", stone=("stone", 0.11)),
    design("Gauntlets of Hoarfrost", "Rare", "A plate cut in facets, a square stone in a spade.", "blued", facets=True,
           plated=True, line="filigree", orn="Hoarfrost", stone=("stone", 0.11), cut="square"),
    design("Gauntlets of Gales", "Rare", "A vane sweeps back from the cuff, the stone on the back.", "blued",
           plated=True, line="filigree", orn="Gales", stone=("stone", 0.11)),

    design("Stormcall Gauntlets", "Epic", "Filigree hooks rise from the cuff and curl out. A glowing stone.", "rich",
           trim="filigree", plated=True, line="filigree", orn="Stormcall", stone=("glow", 0.14)),
    design("Gloamforge Gauntlets", "Epic", "Filigree prongs on the cuff, a spike on each knuckle, a square glowing "
           "stone.", "rich", trim="filigree", plated=True, knuckles=True, orn="Gloamforge", stone=("glow", 0.14),
           cut="square"),
    design("Nightloom Gauntlets", "Epic", "A shuttle lies across the cuff, a long cuff, a glowing stone.", "rich",
           trim="filigree", plated=True, cuff="long", line="filigree", orn="Nightloom", stone=("glow", 0.14)),

    design("Kirameki, the Glint", "Legendary", "Its one new form: the cuff spreads into a ring of points like a "
           "star's glint.", "gilt", trim="ivory", plated=True, cuff="star", orn="glint", stone=("lit", 0.14),
           edge=True, glove="ivory"),
    design("Nagareboshi, the Meteor", "Legendary", "Its one new form: a falling star's streak trails from the back of "
           "the hand past the wrist.", "gilt", trim="ivory", plated=True, rims="ivory", orn="streak",
           stone=("lit", 0.16), edge=True, glove="ivory"),
    design("Yuubae, the Evening Glow", "Legendary", "Its one new form: a setting sun's disc stands behind the hand.",
           "gilt", trim="ivory", plated=True, rims="ivory", orn="sun", stone=("lit", 0.13), edge=True, glove="ivory"),
)


def finger(d, x, length, splay, radius=0.12):
    """A finger from its knuckle up, splayed and curling a little toward the camera; its plates if it's plated."""
    a = math.radians(splay)
    pts = []
    for i in range(7):
        t = i / 6
        pts.append((x - math.sin(a) * length * t, -0.05 - 0.14 * t * t, KNUCKLE + math.cos(a) * length * t))
    parts = [p.tube("Finger", pts, [radius, radius * 0.96, radius * 0.92, radius * 0.88, radius * 0.84, radius * 0.8,
                                    radius * 0.7], d["glove"], sides=10)]
    if d["plated"]:
        for k, (t0, t1) in enumerate(((0.04, 0.3), (0.36, 0.6), (0.66, 0.9))):
            seg = [pts[0]]
            seg = [(x - math.sin(a) * length * t, -0.05 - 0.14 * t * t - 0.02, KNUCKLE + math.cos(a) * length * t)
                   for t in (t0, (t0 + t1) / 2, t1)]
            parts.append(p.tube("Plate", seg, radius * (1.22 - 0.08 * k), d["key"], sides=10))
    return parts, pts[-1]


def hand(d):
    key, trim, parts = d["key"], d["trim"], []
    # the hand inside the glove, and the plate over its back
    parts.append(p.ball("Hand", 1.0, d["glove"], (0.0, 0.0, 0.08), squash=(0.6, 0.27, 0.6), segments=24, rings=14))
    across = 6 if d["facets"] else 15
    us = [-1.0 + 2.0 * i / (across - 1) for i in range(across)]
    vs = [j / 10 for j in range(11)]

    def back(u, v):   # a rounded plate over the back of the hand, bulging toward the camera, narrower at its ends
        w = 0.4 + 0.12 * math.sin(math.pi * v)
        return (u * w, BACK + 0.06 - 0.12 * (1 - u * u) - 0.04 * math.sin(math.pi * v), -0.34 + 0.84 * v)
    parts.append(p.sheet_surface("Back", key, back, us, vs, thick=0.05))
    tips = []
    for x, length, splay in FINGERS:
        more, tip = finger(d, x, length, splay)
        parts += more
        tips.append(tip)
    thumb = [(-0.5, -0.05, -0.05), (-0.74, -0.12, 0.12), (-0.92, -0.2, 0.36), (-1.0, -0.26, 0.56)]
    parts.append(p.tube("Thumb", p.curve(thumb, 10), [0.17, 0.16, 0.15, 0.14, 0.13, 0.12, 0.12, 0.11, 0.1, 0.09],
                        d["glove"], sides=10))
    if d["plated"]:
        parts.append(p.tube("Plate", p.curve(thumb[:3], 6), 0.17, key, sides=10))
    if d["knuckles"]:
        bar = [(x, -0.2, KNUCKLE - 0.02) for x, _, _ in FINGERS]
        parts.append(p.tube("Knuckles", p.curve([(-0.52, -0.16, KNUCKLE - 0.06)] + bar + [(0.52, -0.16, KNUCKLE - 0.06)],
                                                16), 0.07, d["rims"] or key, sides=8))
        if d["orn"] == "Gloamforge":
            for x, _, _ in FINGERS:
                spike = bl.cylinder("Spike", 0.07, 0.3, segments=8, material=mat(trim), radius_top=0.0)
                parts.append(p.aim(spike, (x, -0.3, KNUCKLE + 0.06), (0, -0.7, 0.7)))

    # the cuff: a bell flaring from the wrist, or short, long, or a ring of points
    tall = dict(bell=1.0, short=0.6, long=1.5, star=1.0)[d["cuff"]]
    prof = [(0.5, -0.36), (0.56, -0.36 - 0.3 * tall), (0.72, -0.36 - 0.62 * tall)]
    steps = 9 if d["facets"] else 40
    if d["cuff"] == "star":
        cuff = p.lathe("Cuff", prof, d["cuff_mat"], deep=0.62, thick=0.05, steps=40)
        parts.append(cuff)
        for k in range(9):   # a ring of points round the cuff's middle, out to both sides and down
            ang = -112.0 + 224.0 * k / 8
            pt = p.leaf(0.62 + 0.24 * (k % 2 == 0), 0.24)
            parts.append(p.flat("Point", p.shifted(p.turned(pt, ang + 180.0, (0, 0)), 0, -0.72), 0.05,
                                trim if k % 2 else key, y=0.12))
    else:
        parts.append(p.lathe("Cuff", prof, d["cuff_mat"], deep=0.62, thick=0.05, steps=steps))
    foot = prof[-1]
    if d["rims"]:
        parts.append(p.hoop("Rim", foot[0] + 0.01, 0.04, d["rims"], foot[1], deep=0.62))
    if d["line"]:
        parts.append(p.hoop("Line", 0.6, 0.022, d["line"], (prof[1][1] + prof[2][1]) / 2, deep=0.62))
    if d["edge"]:
        parts.append(p.hoop("Edge", 0.53, 0.025, "lit", -0.38, deep=0.62))
    if d["studs"]:
        for x, _, _ in FINGERS:
            parts.append(p.ball("Stud", 0.06, d["studs"], (x, -0.24, KNUCKLE - 0.06)))
        for a in range(-80, 81, 32):
            r = 0.64
            parts.append(p.ball("Stud", 0.05, d["studs"], (r * math.sin(math.radians(a)),
                                                            -r * 0.62 * math.cos(math.radians(a)) - 0.04, prof[1][1])))
    if d["rivets"]:
        for x in (-0.42, 0.42):
            for z in (-0.3, 0.1, 0.48):
                parts.append(p.ball("Rivet", 0.045, key, (x, BACK - 0.04, z), segments=8, rings=5))
    if d["lozenge"]:
        parts.append(p.flat("Lozenge", [(0, 0.38), (0.2, 0.1), (0, -0.18), (-0.2, 0.1)], 0.06, d["lozenge"],
                            y=BACK - 0.12))

    # what the hand carries: the set's ornament, or a Legendary's new form
    orn, stone_at = d["orn"], (0.0, BACK - 0.14, 0.12)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.4, (0, 0.12)), 0.05, trim, y=BACK - 0.11))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, 0.55, -0.85, 1.0, 1.0), 0.07, trim, y=0.0))
    elif orn in ("Stormcall", "Gloamforge"):
        parts.append(p.flat("Crest", p.set_ornament(orn, 0.6, (0, -0.9)), 0.07, trim, y=-0.56))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0, -0.72, 2.2, 1.2), 0.08, trim, y=-0.5))
    elif orn == "streak":
        streak = p.turned(p.leaf(1.9, 0.34, bend=0.0), 152.0, (0, 0))
        parts.append(p.flat("Streak", p.shifted(streak, 0.1, 0.2), 0.06, trim, y=BACK - 0.06))
        parts.append(p.flat("Streak", p.shifted(p.turned(p.leaf(1.4, 0.18), 160.0, (0, 0)), 0.3, 0.1), 0.05, "lit",
                            y=BACK - 0.1))
    elif orn == "sun":
        # the sun half set: a half disc on the horizon at the wrist, the hand rising out of it
        half = [(1.15 * math.cos(math.radians(a)), -0.5 + 1.15 * math.sin(math.radians(a))) for a in range(0, 181, 6)]
        parts.append(p.flat("Sun", half, 0.06, trim, y=0.45))
        parts.append(p.facing("Ring", 1.3, 0.04, "lit", (0, 0.42, -0.5), arc=180.0))
        parts.append(p.flat("Horizon", [(-1.5, -0.47), (1.5, -0.47), (1.5, -0.55), (-1.5, -0.55)], 0.1, "lit",
                            y=0.0))
    parts += p.stone_of(d, 1.0, stone_at)
    return parts


def build(d):
    return p.scene_of(lambda: hand(d), TILT, SPIN)


WORDS = dict(
    file="gear_gloves_sets.png",
    title="Grow your Anime: Gloves in three designs at each rarity, in grey (AR6, batch 2)",
    lead="The right gauntlet from the back of the hand, fingers up, the thumb out, a cuff flaring at the wrist. A design "
         "is the back plate, the fingers' plates, the cuff and what the hand carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Gauntlets.",
        "Each Legendary's one new form: Kirameki (a glint), the cuff a ring of points; Nagareboshi (a falling star), a "
        "streak from the back of the hand past the wrist; Yuubae (the evening glow), a setting sun's disc behind the hand.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as gloves, and apart from its two neighbours, at 38 points? Does each Legendary "
        "outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
