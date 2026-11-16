"""AR6, batch 3: the Throwing Blades in three designs at each rarity, in grey: a blockout for research's verdict.

The Assassin's off hand. One family: three slim blades fanned from one ring that passes through their tangs, the fan
laid on the diagonal with its middle blade pointing up and to the right. No other kind is a fan of blades, so it's
never the Dagger at 38 points. A design is the blades' shape (a leaf, a diamond, a needle, a swept blade), the
fan's spread, the ring and what binds or rides on it. A rarity keeps the ladder's rule, a set keeps its word
(gear_parts.py), and the near word from Rare up is Talons. An Uncommon's name keeps "Blades" alone: the full slot's
words run past the 24 a name may take.

Each Legendary's one new form changes the silhouette: Shokou fans five blades in a half circle, a sunrise's rays;
Getsurin's five blades are crescents turning round the ring, a wheel (five, never four:
four hooked arms turning round a centre must never read as a sign); Tenkou's three are long feathers, a wing.

    blender -b --factory-startup --python tools/blender/gear_throwing_blades_sets.py -- build/handoff/Gear/throwing_blades_sets

Writes the sheet gear_throwing_blades_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402
from mathutils import Matrix  # noqa: E402

mat = p.mat
FILL, DROP, LEAST = 0.84, 0.0, 0.9
RING, TANG = 0.34, 0.55             # the ring's radius; how far a blade's tang runs from the ring to its blade


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(shape="leaf", length=2.0, width=0.46, spread=26.0, count=3,
                                                         ring=RING, wraps=False, tassel=False, bend=0.0, form=None),
                                                    **more))


DESIGNS = (
    design("Iron Throwing Blades", "Common", "Three plain iron leaves on an iron ring.", "iron"),
    design("Bronze Throwing Blades", "Common", "Three broad bronze leaves fanned wide.", "bronze",
           width=0.6, spread=32.0, length=1.8),
    design("Scrap Throwing Blades", "Common", "Three cut diamonds of plate, their tangs wrapped in cord.", "scrap",
           shape="diamond", wraps=True),

    design("Lanternsteel Blades", "Uncommon", "Three slim needles of bright steel on a brass ring.", "steel",
           trim="brass", shape="needle", length=2.2, width=0.32, spread=20.0),
    design("Rowsmith Blades", "Uncommon", "Three leaves, their tangs bound in brass, a tassel from the ring.", "steel",
           trim="brass", wraps=True, tassel=True),
    design("Stallguard Blades", "Uncommon", "Three diamonds fanned wide on a large brass ring.", "steel",
           trim="brass", shape="diamond", spread=32.0, ring=0.44),

    design("Talons of Embers", "Rare", "A stone in a swelling frame in the ring, three leaves.", "blued",
           trim="filigree", orn="Embers", stone=("stone", 0.2), line="filigree"),
    design("Talons of Hoarfrost", "Rare", "Three diamonds, a square stone in a spade in the ring.", "blued",
           trim="filigree", orn="Hoarfrost", stone=("stone", 0.2), cut="square", line="filigree", shape="diamond"),
    design("Talons of Gales", "Rare", "Three blades swept back like vanes, the stone in the ring.", "blued",
           trim="filigree", orn="Gales", stone=("stone", 0.2), line="filigree", shape="swept", bend=0.32),

    design("Stormcall Talons", "Epic", "Filigree curls roll out from the ring, a glowing stone.", "rich",
           trim="filigree", orn="Stormcall", stone=("glow", 0.22), line="filigree", length=2.1),
    design("Gloamforge Talons", "Epic", "Filigree prongs standing under the ring, a square stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.22), cut="square", line="filigree", shape="diamond",
           length=2.1),
    design("Nightloom Talons", "Epic", "A shuttle binding the three tangs, the stone on it.", "rich",
           trim="filigree", orn="Nightloom", stone=("glow", 0.22), line="filigree", shape="needle", width=0.36,
           length=2.2),

    design("Shokou, the First Light", "Legendary", "Its one new form: five blades fanned in a half circle, a "
           "sunrise's rays.", "gilt", trim="ivory", stone=("lit", 0.22), edge=True, count=5, spread=36.0,
           shape="needle", width=0.36, length=2.0, form="rays"),
    design("Getsurin, the Moon Wheel", "Legendary", "Its one new form: five crescent blades turning round the ring.",
           "gilt", trim="ivory", stone=("lit", 0.24), edge=True, form="wheel", ring=0.42),
    design("Tenkou, the Sky Feather", "Legendary", "Its one new form: three long feathers for blades, a wing.",
           "gilt", trim="ivory", stone=("lit", 0.22), edge=True, shape="feather", length=2.5, width=0.62,
           spread=22.0, form="wing"),
)


def blade_outline(d):
    """One blade from its foot at the origin up +z."""
    L, w, shape = d["length"], d["width"], d["shape"]
    if shape == "diamond":
        return [(0.0, 0.0), (w / 2, L * 0.38), (0.0, L), (-w / 2, L * 0.38)]
    if shape == "needle":
        return [(0.0, 0.0), (w / 2, L * 0.22), (w * 0.3, L * 0.7), (0.0, L), (-w * 0.3, L * 0.7), (-w / 2, L * 0.22)]
    if shape == "feather":
        right = [(0.06, 0.0), (w * 0.42, L * 0.2), (w * 0.5, L * 0.45), (w * 0.36, L * 0.48), (w * 0.46, L * 0.62),
                 (w * 0.3, L * 0.8), (w * 0.12, L * 0.95), (0.0, L)]
        left = [(-0.06, 0.0), (-w * 0.3, L * 0.22), (-w * 0.4, L * 0.5), (-w * 0.28, L * 0.56), (-w * 0.32, L * 0.72),
                (-w * 0.14, L * 0.9)]
        return right + list(reversed(left))
    return p.leaf(L, w, bend=d["bend"])


def blade(d, angle, key, eye=True):
    """A blade, its tang and its eye on the ring, turned `angle` degrees off the fan's middle (toward -x)."""
    trim, parts = d["trim"], []
    foot = d["ring"] + TANG
    outline = p.shifted(blade_outline(d), 0.0, foot)
    parts.append(p.flat("Blade", outline, 0.07, key, bevel=0.02))
    parts.append(p.rod("Tang", d["ring"] - 0.02, foot + 0.12, 0.055, key, sides=8))
    if eye:
        parts.append(p.ball("Eye", 0.09, key, (0, 0, d["ring"] + 0.02), squash=(1, 0.8, 1), segments=10, rings=6))
    if d["wraps"]:
        parts += p.bands([d["ring"] + 0.14 + 0.09 * k for k in range(4)], 0.055,
                         "cord" if d["key"] == "scrap" else trim, minor=0.03)
    if d["line"] or d["shape"] in ("leaf", "diamond", "needle"):
        top = foot + d["length"] * 0.82
        pts = [(d["bend"] * ((z - foot) / d["length"]) ** 2, -0.04, z) for z in
               [foot + 0.08 + (top - foot - 0.08) * k / 8 for k in range(9)]]
        parts.append(p.tube("Ridge", pts, 0.018 if not d["line"] else 0.02, d["line"] or key, sides=6))
    if d["edge"]:
        pts = [(x * 0.84, -0.045, foot + (z - foot) * 0.97 + 0.04) for x, z in outline if x > 0.02]
        if len(pts) > 2:
            parts.append(p.tube("Edge", p.curve(pts, 16), 0.022, "lit", sides=6))
    rot = Matrix.Rotation(math.radians(angle), 4, "Y")
    for obj in parts:
        p.move(obj, rot)
    return parts


def crescent(d, angle, key):
    """Getsurin's: a crescent blade bending away from the ring's turn, five of them making a wheel."""
    foot = d["ring"] + 0.06
    leaf = p.leaf(1.4, 0.56, bend=-0.7)
    outline = p.shifted(leaf, 0.0, foot)
    parts = [p.flat("Crescent", outline, 0.07, key, bevel=0.02)]
    outside = [(x * 0.9, -0.045, z) for x, z in outline[2:len(leaf) // 2 + 1]]
    parts.append(p.tube("Edge", p.curve(outside, 16), 0.022, "lit", sides=6))
    rot = Matrix.Rotation(math.radians(angle), 4, "Y")
    for obj in parts:
        p.move(obj, rot)
    return parts


def throwing_blades(d):
    key, trim, parts = d["key"], d["trim"], []
    if d["form"] == "wheel":
        for k in range(5):
            parts += crescent(d, 72.0 * k + 20.0, key)
    else:
        n, spread = d["count"], d["spread"]
        for k in range(n):
            parts += blade(d, spread * (k - (n - 1) / 2), key)
    ring_key = trim if d["rarity"] != "Common" else key
    parts.append(p.facing("Ring", d["ring"], 0.07, ring_key, (0, 0, 0)))
    if d["tassel"]:
        cord = [(0.0, 0, -d["ring"]), (0.05, 0, -d["ring"] - 0.35), (0.0, 0, -d["ring"] - 0.55)]
        parts.append(p.tube("Cord", cord, 0.035, "cloth", sides=6))
        parts.append(p.rod("Tassel", -d["ring"] - 1.2, -d["ring"] - 0.55, 0.05, "cloth", top=0.13, sides=10))

    orn = d["orn"]
    at = (0.0, -0.04, 0.0)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.42, (0.0, 0.0)), 0.04, trim, y=-0.02))
    elif orn == "Gales":
        vane = p.turned(p.shifted(p.VANE, 0, 0, 0.8, 0.8), -120.0)
        parts.append(p.flat("Vane", p.shifted(vane, d["ring"] * 0.7, -d["ring"] * 0.7), 0.06, trim))
    elif orn == "Stormcall":
        for side in (-1, 1):
            parts.append(p.curl((side * d["ring"], -0.05), side, 0.7, trim, turn=60.0, r=0.07))
    elif orn == "Gloamforge":
        crest = p.turned(p.set_ornament(orn, 0.6, (0, 0)), 180.0)
        parts.append(p.flat("Crest", p.shifted(crest, 0.0, -d["ring"] - 0.12), 0.07, trim))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0.0, d["ring"] + 0.35, 1.7, 1.6), 0.08, trim, y=-0.08))
        at = (0.0, -0.13, d["ring"] + 0.35)
    parts += p.stone_of(d, 1.0, at)
    return p.laid(parts, spin=10.0)


def build(d):
    return p.scene_of(lambda: throwing_blades(d), 0.0, 0.0)


WORDS = dict(
    file="gear_throwing_blades_sets.png",
    title="Grow your Anime: the Throwing Blades in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Assassin's off hand: three slim blades fanned from one ring through their tangs, the middle one pointing up "
         "and to the right. A design is the blades' shape, the fan's spread, the ring and what binds or rides on it.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Talons. An Uncommon's name keeps \"Blades\" alone.",
        "Each Legendary's one new form: Shokou (first light), five blades in a half circle; Getsurin (the moon's disc), "
        "five crescents turning round the ring; Tenkou (the sky's light), three long feathers.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as throwing blades, never the Dagger, and apart from its two neighbours, at 38 "
        "points? Does each Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
