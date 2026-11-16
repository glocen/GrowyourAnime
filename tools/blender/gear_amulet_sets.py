"""AR6, batch 2: Amulets in three designs at each rarity, in grey: a blockout for research's verdict.

One family: a necklace seen from the front and a little above, its loop lying as it would round a neck, its front
dipping to a pendant. A loop and a pendant, so it never reads as the Ring's band or the Earring's single drop. A design
is the chain or cord and the pendant. A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py), and the
near words are Pendant (Rare) and Talisman (Epic). The earring (gear_earring_sets.py) takes its pendants from here.

Each Legendary's one new form changes the silhouette: Yakou hangs a long drop of light in a filigree cage, Akebono's sun
rises from a cradle with its rays fanning above, Tsukigasa is a moon's halo, two rings round a stone held on four
spokes.

    blender -b --factory-startup --python tools/blender/gear_amulet_sets.py -- build/handoff/Gear/amulet_sets

Writes the sheet gear_amulet_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 22.0, 10.0    # from the front and a little above, so the loop's back shows
FILL, DROP = 0.8, 0.0
LEAST = 0.86
FRONT = -0.5               # the loop's front, where it dips to the pendant


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(chain="chain", chain_mat=key, form="disc", rims=None,
                                                         studs=None, size=1.0), **more))


DESIGNS = (
    design("Iron Amulet", "Common", "A plain iron disc on a leather cord.", "iron", chain="cord", chain_mat="leather"),
    design("Bronze Amulet", "Common", "A bronze ring hung on a cord.", "bronze", chain="cord", chain_mat="cord",
           form="ring"),
    design("Scrap Amulet", "Common", "A bent tag of scrap with a rivet, on an iron chain.", "scrap", chain_mat="iron",
           form="tag"),

    design("Lanternsteel Amulet", "Uncommon", "A steel disc with a brass rim on a steel chain.", "steel", rims="brass",
           chain_mat="steel"),
    design("Rowsmith Amulet", "Uncommon", "A brass lozenge in a steel frame.", "steel", form="lozenge", rims="brass"),
    design("Stallguard Amulet", "Uncommon", "A steel shield with brass studs, a brass chain.", "steel", form="shield",
           studs="brass", chain_mat="brass"),

    design("Pendant of Embers", "Rare", "A swelling frame round one stone, on a filigree chain.", "blued",
           trim="filigree", chain_mat="filigree", orn="Embers", stone=("stone", 0.2), form=None),
    design("Pendant of Hoarfrost", "Rare", "A spade round a square stone.", "blued", trim="filigree",
           chain_mat="filigree", orn="Hoarfrost", stone=("stone", 0.2), cut="square", form=None),
    design("Pendant of Gales", "Rare", "Two vanes sweep up and out from a stone.", "blued", trim="filigree",
           chain_mat="filigree", orn="Gales", stone=("stone", 0.2), form=None),

    design("Stormcall Talisman", "Epic", "Filigree hooks curl out round a glowing stone.", "rich", trim="filigree",
           chain_mat="filigree", orn="Stormcall", stone=("glow", 0.24), form=None),
    design("Gloamforge Talisman", "Epic", "Filigree prongs stand round a square glowing stone.", "rich",
           trim="filigree", chain_mat="filigree", orn="Gloamforge", stone=("glow", 0.24), cut="square", form=None),
    design("Nightloom Talisman", "Epic", "A shuttle lies across a glowing stone, a tassel below.", "rich",
           trim="filigree", chain_mat="filigree", orn="Nightloom", stone=("glow", 0.24), form=None),

    design("Yakou, the Night Glow", "Legendary", "Its one new form: a long drop of light hangs in a filigree cage.",
           "gilt", trim="ivory", chain_mat="gilt", orn="drop", stone=None, edge=True, form=None),
    design("Akebono, the Dawn", "Legendary", "Its one new form: a sun rises from a cradle, its rays fanning above.",
           "gilt", trim="ivory", chain_mat="gilt", orn="dawn", stone=("lit", 0.26), edge=True, form=None),
    design("Tsukigasa, the Moon Halo", "Legendary", "Its one new form: two rings, a moon's halo, round a stone on four "
           "spokes.", "gilt", trim="ivory", chain_mat="gilt", orn="halo", stone=("lit", 0.22), edge=True, form=None),
)


def loop(n):
    """The necklace's loop as it lies round a neck: an oval whose front dips to the pendant."""
    pts = []
    for i in range(n + 1):
        th = 2 * math.pi * i / n
        dip = ((1 + math.cos(th)) / 2) ** 3
        pts.append((0.78 * math.sin(th), FRONT * math.cos(th), 1.25 - 0.95 * dip))
    return pts


def chain(d):
    if d["chain"] == "cord":
        return [p.tube("Cord", loop(64), 0.035, d["chain_mat"], sides=8)]
    out = []
    pts = loop(56)
    for k, at in enumerate(pts[:-1]):
        if k % 2:
            out.append(p.ball("Link", 0.045, d["chain_mat"], at, squash=(1.0, 1.0, 0.6), segments=8, rings=5))
        else:
            out.append(p.facing("Link", 0.045, 0.016, d["chain_mat"], at))
    return out


def pendant(d, at=(0.0, FRONT, -0.28), scale=1.0):
    """The pendant, centred at `at`, hanging from its bail above it: shared with the earrings."""
    key, trim, parts = d["key"], d["trim"], []
    x0, y0, z0 = at
    k = scale * d["size"]
    form, orn = d["form"], d["orn"]
    sx = lambda outline: p.shifted(outline, x0, z0, k, k)  # noqa: E731
    if form == "disc":
        parts.append(p.flat("Disc", sx(p.ellipse(0.38, 0.38, 32)), 0.08 * k, key, y=y0))
        # a plain disc keeps a rolled edge in its own metal: face on, the flat catches no key light, the edge does
        parts.append(p.facing("Rim", 0.38 * k, 0.035 * k, d["rims"] or key, (x0, y0 - 0.02, z0)))
    elif form == "ring":
        parts.append(p.facing("Ring", 0.3 * k, 0.08 * k, key, (x0, y0, z0)))
    elif form == "tag":
        tag = p.turned([(-0.2, 0.32), (0.2, 0.3), (0.22, -0.34), (-0.18, -0.3)], 8.0)
        parts.append(p.flat("Tag", sx(tag), 0.05 * k, key, y=y0))
        parts.append(p.ball("Rivet", 0.05 * k, "iron", (x0, y0 - 0.04, z0 - 0.08 * k)))
    elif form == "lozenge":
        parts.append(p.flat("Frame", sx([(0, 0.52), (0.36, 0), (0, -0.52), (-0.36, 0)]), 0.07 * k, key, y=y0))
        parts.append(p.flat("Lozenge", sx([(0, 0.38), (0.25, 0), (0, -0.38), (-0.25, 0)]), 0.06 * k, d["rims"],
                            y=y0 - 0.04))
    elif form == "shield":
        shield = [(0, 0.4), (0.34, 0.36), (0.34, 0.0), (0.2, -0.3), (0, -0.46), (-0.2, -0.3), (-0.34, 0.0), (-0.34, 0.36)]
        parts.append(p.flat("Shield", sx(shield), 0.08 * k, key, y=y0))
        for sxz in ((-0.18, 0.18), (0.18, 0.18), (0.0, -0.18)):
            parts.append(p.ball("Stud", 0.05 * k, d["studs"], (x0 + sxz[0] * k, y0 - 0.06, z0 + sxz[1] * k)))
    elif orn in ("Embers", "Hoarfrost", "Stormcall", "Gloamforge"):
        size = dict(Embers=0.62, Hoarfrost=0.62, Stormcall=0.58, Gloamforge=0.6)[orn]
        lift = dict(Stormcall=-0.32, Gloamforge=-0.2).get(orn, 0.0)
        parts.append(p.flat("Frame", p.set_ornament(orn, size * k, (x0, z0 + lift * k)), 0.07 * k, trim, y=y0))
    elif orn == "Gales":
        for side in (-1, 1):
            parts.append(p.flat("Vane", p.shifted(p.VANE, x0 + 0.08 * side * k, z0 - 0.1 * k, 0.62 * side * k, 0.62 * k),
                                0.06 * k, trim, y=y0))
        parts.append(p.flat("Setting", sx(p.ellipse(0.24, 0.26, 20)), 0.07 * k, key, y=y0 + 0.02))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, x0, z0, 1.5 * k, 1.5 * k), 0.08 * k, trim, y=y0))
        parts.append(p.tube("Tassel", [(x0, y0, z0 - 0.2 * k), (x0, y0, z0 - 0.62 * k)], [0.04 * k, 0.09 * k], "cord",
                            sides=8))
    elif orn == "drop":
        drop = [(0.0, 0.2), (0.14, 0.05), (0.26, -0.3), (0.28, -0.6), (0.2, -0.82), (0.0, -0.9), (-0.2, -0.82),
                (-0.28, -0.6), (-0.26, -0.3), (-0.14, 0.05)]
        parts.append(p.flat("Drop", sx(drop), 0.14 * k, "lit", y=y0))
        for side in (-1, 0, 1):
            cage = [(0.0, 0.24), (0.2 * side, -0.1), (0.32 * side, -0.55), (0.18 * side, -0.88), (0.0, -0.98)]
            parts.append(p.tube("Cage", p.curve([(x0 + cx * k, y0 - 0.09, z0 + cz * k) for cx, cz in cage], 14),
                                0.022 * k, trim, sides=6))
        parts.append(p.ball("Cap", 0.1 * k, key, (x0, y0, z0 + 0.26 * k)))
    elif orn == "dawn":
        cradle = [(0.46 * math.cos(math.radians(a)), 0.46 * math.sin(math.radians(a))) for a in range(180, 361, 12)]
        inner = [(0.32 * math.cos(math.radians(a)), 0.06 + 0.32 * math.sin(math.radians(a))) for a in range(360, 179, -12)]
        parts.append(p.flat("Cradle", sx(cradle + inner), 0.08 * k, key, y=y0))
        for j, a in enumerate(range(-60, 61, 20)):
            ray = p.turned(p.leaf(0.62 + 0.22 * (a == 0) + 0.1 * (abs(a) == 20), 0.13), -a, (0, 0))
            parts.append(p.flat("Ray", sx(p.shifted(ray, 0, 0.3)), 0.05 * k, trim if j % 2 else key, y=y0 + 0.04))
        at = (x0, y0 - 0.02, z0 + 0.12 * k)
    elif orn == "halo":
        parts.append(p.facing("Halo", 0.56 * k, 0.04 * k, trim, (x0, y0, z0)))
        parts.append(p.facing("Halo", 0.42 * k, 0.03 * k, key, (x0, y0, z0)))
        for a in (45, 135, 225, 315):
            c, s_ = math.cos(math.radians(a)), math.sin(math.radians(a))
            parts.append(p.tube("Spoke", [(x0 + 0.16 * c * k, y0, z0 + 0.16 * s_ * k), (x0 + 0.54 * c * k, y0,
                                                                                          z0 + 0.54 * s_ * k)],
                                0.022 * k, key, sides=6))
        for a in (0, 90, 180, 270):
            c, s_ = math.cos(math.radians(a)), math.sin(math.radians(a))
            parts.append(p.flat("Star", p.shifted(p.star(4, 0.12 * k, 0.04 * k), x0 + 0.56 * c * k, z0 + 0.56 * s_ * k),
                                0.04 * k, "lit", y=y0 - 0.02))
    if d.get("edge"):
        parts.append(p.facing("Bail", 0.07 * k, 0.025 * k, "lit", (x0, y0, z0 + 0.5 * k)))
    else:
        parts.append(p.facing("Bail", 0.07 * k, 0.025 * k, d["chain_mat"], (x0, y0, z0 + 0.46 * k)))
    if d["stone"]:
        kind, f = d["stone"]
        sat = at if orn == "dawn" else (x0, y0 - 0.06, z0)
        parts += p.stone(kind, f * k, sat, trim, square=d.get("cut") == "square")
    return parts


PENDANT = 1.45             # the pendant's size against the loop: at 32 pixels the pendant is the design


def necklace(d):
    return chain(d) + pendant(d, (0.0, FRONT, 0.25 - 0.47 * PENDANT), PENDANT)


def build(d):
    return p.scene_of(lambda: necklace(d), TILT, SPIN)


WORDS = dict(
    file="gear_amulet_sets.png",
    title="Grow your Anime: Amulets in three designs at each rarity, in grey (AR6, batch 2)",
    lead="A necklace from the front and a little above, its loop lying as it would round a neck, its front dipping to a "
         "pendant. A design is the chain or cord and the pendant.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near words are "
        "Pendant and Talisman.",
        "Each Legendary's one new form: Yakou (a glow in the night), a long drop of light in a filigree cage; Akebono "
        "(dawn), a sun rising from a cradle; Tsukigasa (a halo round the moon), two rings round a stone on four spokes.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as an amulet, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
