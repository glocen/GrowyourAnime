"""AR6, batch 3: the Crystal Baton in three designs at each rarity, in grey: a blockout for research's verdict.

The Healer's main hand. One family: a short stout rod laid on the diagonal, its head up and to the right: a long cut
crystal held upright in curved prongs from a cup. The Mage's Staff is long and slim with an open ring and never a
crystal, so the two never meet at 38 points. A design is the crystal's cut and length, the prongs (three, four, with
knobs, with a ring round them), the cup and the rod's fittings. A rarity keeps the ladder's rule, a set keeps its word
(gear_parts.py), and the near word from Rare up is Sceptre. An Uncommon's name keeps "Baton" alone: "Lanternsteel
Crystal Baton" runs past the 24 a name may take.

Each Legendary's one new form changes the silhouette: Seikou wears a crown of five small crystals round its own;
Gyouten's prongs open into petals round the crystal, a flower at dawn; Reikou holds a second crystal at its foot.

    blender -b --factory-startup --python tools/blender/gear_crystal_baton_sets.py -- build/handoff/Gear/crystal_baton_sets

Writes the sheet gear_crystal_baton_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
FILL, DROP, LEAST = 0.84, 0.0, 0.9
R, FOOT, CUP = 0.18, -1.7, 0.85     # the rod's radius, its foot, where the cup sits


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(crystal="stone", sides=6, cr=0.3, cl=1.5, prongs=3,
                                                         knobs=False, hoop=False, disc=False, pommel="pear",
                                                         rod="wood", rod_bands=(), grip="leather", rough=False,
                                                         form=None), **more))


DESIGNS = (
    design("Iron Crystal Baton", "Common", "Three iron prongs round a pale crystal, an ash rod.", "iron",
           rod_bands=(-0.6, 0.4), pommel="cap"),
    design("Bronze Crystal Baton", "Common", "Four bronze prongs from a flared cup, a round pommel.", "bronze",
           prongs=4, cl=1.3, cr=0.34),
    design("Scrap Crystal Baton", "Common", "A pipe, wire twisted into prongs, a rough crystal.", "scrap",
           rod="scrap", rough=True, pommel="cap", grip="cord"),

    design("Lanternsteel Baton", "Uncommon", "Three prongs and a brass ring round them, a long crystal.", "steel",
           trim="brass", hoop=True, cl=1.7),
    design("Rowsmith Baton", "Uncommon", "Four prongs, a brass disc guarding the hand.", "steel",
           trim="brass", prongs=4, disc=True),
    design("Stallguard Baton", "Uncommon", "Three prongs tipped with brass knobs, a brass pommel.", "steel",
           trim="brass", knobs=True, pommel="brass", rod_bands=(0.3,)),

    design("Sceptre of Embers", "Rare", "A swelling frame round a stone on the cup.", "blued",
           trim="filigree", orn="Embers", line="filigree", rod="blued", pommel="facet"),
    design("Sceptre of Hoarfrost", "Rare", "A square-cut crystal, a square stone in a spade.", "blued",
           trim="filigree", orn="Hoarfrost", line="filigree", sides=4, prongs=4, rod="blued", pommel="facet"),
    design("Sceptre of Gales", "Rare", "A vane sweeping back off the cup, a long crystal.", "blued",
           trim="filigree", orn="Gales", line="filigree", cl=1.7, rod="blued", pommel="facet"),

    design("Stormcall Sceptre", "Epic", "Filigree curls roll out from the cup, a glowing crystal.", "rich",
           trim="filigree", orn="Stormcall", crystal="glow", line="filigree", rod="rich", rod_bands=(0.3,),
           pommel="spike"),
    design("Gloamforge Sceptre", "Epic", "Filigree prongs standing beside the crystal, cut square.", "rich",
           trim="filigree", orn="Gloamforge", crystal="glow", sides=4, line="filigree", rod="rich", pommel="spike"),
    design("Nightloom Sceptre", "Epic", "A shuttle laid across the cup under the crystal.", "rich",
           trim="filigree", orn="Nightloom", crystal="glow", line="filigree", rod="rich", pommel="spike", hoop=True),

    design("Seikou, the Starlight", "Legendary", "Its one new form: a crown of five small crystals round its own.",
           "gilt", trim="ivory", crystal="lit", rod="ivory", pommel="facet", edge=True, form="crown"),
    design("Gyouten, the Dawn Bloom", "Legendary", "Its one new form: its prongs open into petals round the crystal.",
           "gilt", trim="ivory", crystal="lit", rod="ivory", pommel="facet", edge=True, prongs=0, form="bloom"),
    design("Reikou, the Twin Light", "Legendary", "Its one new form: a second crystal held at its foot.", "gilt",
           trim="ivory", crystal="lit", rod="ivory", pommel=None, edge=True, form="twin"),
)


def crystal(name, r, length, key, z0, sides=6, rough=False):
    """A cut crystal standing up z from z0: a short point below, the body, a long point above."""
    tip, foot = length * 0.3, length * 0.12
    prof = [(0.0, z0), (r, z0 + foot), (r, z0 + length - tip), (0.0, z0 + length)]
    obj = p.lathe(name, prof, key, thick=0.0, steps=sides)
    if rough:
        for v in obj.data.vertices:
            k = 1.0 + 0.18 * math.sin(7.0 * v.co.z + 3.0 * math.atan2(v.co.y, v.co.x))
            v.co.x, v.co.y = v.co.x * k, v.co.y * k
    return bl.smooth_by_angle(obj, 25.0)


def head(d, z_cup, flip=1):
    """The cup, the prongs and the crystal, standing up z from z_cup (flip=-1 hangs them down)."""
    key, trim, parts = d["key"], d["trim"], []
    metal = trim if d["rarity"] not in ("Common",) else key
    cr, cl = d["cr"], d["cl"]
    cup = p.lathe("Cup", [(R * 0.9, 0.0), (R * 1.35, 0.1), (cr * 1.25, 0.24), (cr * 1.3, 0.3)], metal, thick=0.05)
    parts.append(cup)
    parts.append(crystal("Crystal", cr, cl, d["crystal"], 0.08, d["sides"], d["rough"]))
    n = d["prongs"]
    for k in range(n):
        a = 2 * math.pi * (k + 0.5) / n + math.radians(20)
        ca, sa = math.cos(a), math.sin(a)
        pts = [(ca * cr * 1.2, sa * cr * 1.2, 0.28), (ca * cr * 1.45, sa * cr * 1.45, 0.62),
               (ca * cr * 1.18, sa * cr * 1.18, 1.0), (ca * cr * 0.75, sa * cr * 0.75, 1.22)]
        path = p.curve(pts, 16)
        prong_key = "iron" if d["key"] == "scrap" else metal
        parts.append(p.tube("Prong", path, [0.07 - 0.03 * i / 15 for i in range(16)], prong_key, sides=8))
        if d["knobs"]:
            parts.append(p.ball("Knob", 0.08, trim, path[-1], segments=8, rings=6))
    if d["hoop"]:
        parts.append(p.hoop("Hoop", cr * 1.45, 0.04, trim, 0.62))
    if d["line"]:
        parts.append(p.hoop("Line", cr * 1.32, 0.025, d["line"], 0.3))
    if d["edge"]:
        parts.append(p.hoop("Edge", cr * 1.36, 0.028, "lit", 0.32))

    orn = d["orn"]
    if orn in ("Embers", "Hoarfrost"):
        front = -cr * 1.32       # a badge on the cup's front: the set's frame round a small stone of its own
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.48, (0.0, 0.16)), 0.05, trim, y=front))
        parts += p.stone("stone", 0.13, (0.0, front - 0.04, 0.16), trim, square=orn == "Hoarfrost")
    elif orn == "Gales":
        vane = p.turned(p.shifted(p.VANE, 0, 0, 0.9, 0.9), -60.0)
        parts.append(p.flat("Vane", p.shifted(vane, cr * 1.2, 0.2), 0.06, trim))
    elif orn == "Stormcall":
        for side in (-1, 1):
            parts.append(p.curl((side * cr * 1.25, 0.25), side, 0.7, trim, turn=10.0, r=0.07))
    elif orn == "Gloamforge":
        parts.append(p.flat("Crest", p.set_ornament(orn, 1.0, (0.0, 0.5)), 0.08, trim, y=0.06))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0.0, 0.18, 1.9, 1.6), 0.08, trim, y=-cr * 0.9))

    form = d["form"]
    if form == "crown":
        for k in range(5):
            a = 2 * math.pi * k / 5 + math.radians(90)
            small = crystal("Small", 0.16, 0.9, "lit", 0.0, 6)
            ca, sa = math.cos(a), math.sin(a)
            p.move(small, p.Matrix.Translation((ca * cr * 2.05, sa * cr * 2.05, 0.42)) @
                   p.Matrix.Rotation(math.radians(28), 4, p.Vector((-sa, ca, 0))))
            parts.append(small)
        parts.append(p.hoop("Crown", cr * 2.05, 0.05, trim, 0.42))
    elif form == "bloom":
        for k in range(6):
            a = 2 * math.pi * k / 6 + math.radians(15)
            petal = p.flat("Petal", p.leaf(1.15, 0.5, bend=0.18), 0.05, trim if k % 2 else key, bevel=0.015)
            ca, sa = math.cos(a), math.sin(a)
            p.move(petal, p.Matrix.Translation((ca * cr * 0.9, sa * cr * 0.9, 0.18)) @
                   p.Matrix.Rotation(a - math.pi / 2, 4, "Z") @ p.Matrix.Rotation(math.radians(-38), 4, "X"))
            parts.append(petal)
    for obj in parts:
        p.move(obj, p.Matrix.Translation((0, 0, z_cup)) if flip > 0 else
               p.Matrix.Translation((0, 0, z_cup)) @ p.Matrix.Rotation(math.pi, 4, "X"))
    return parts


def baton(d):
    key, trim, parts = d["key"], d["trim"], []
    parts += head(d, CUP)
    parts.append(p.rod("Rod", FOOT, CUP + 0.04, R, d["rod"], sides=20))
    band_key = trim if d["rarity"] != "Common" else ("iron" if key == "scrap" else key)
    parts += p.bands(d["rod_bands"], R, band_key, minor=0.045)
    parts += p.grip_wrap(FOOT + 0.2, FOOT + 1.25, R + 0.012, d["grip"], 5)
    if d["disc"]:
        disc = bl.cylinder("Disc", 0.46, 0.08, segments=28, material=mat(trim))
        parts.append(bl.smooth_by_angle(bl.place(disc, (0, 0, FOOT + 1.38)), 40.0))
    if d["form"] == "twin":
        parts += head(dict(d, form=None, cl=1.0, cr=0.24, prongs=3), FOOT, flip=-1)
    else:
        pommel = d["pommel"]
        parts += p.butt("pear" if pommel == "brass" else pommel, FOOT, R * 1.05,
                        "brass" if pommel == "brass" else trim if d["rarity"] != "Common" else key)
    return p.laid(parts, spin=14.0)


def build(d):
    return p.scene_of(lambda: baton(d), 0.0, 0.0)


WORDS = dict(
    file="gear_crystal_baton_sets.png",
    title="Grow your Anime: the Crystal Baton in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Healer's main hand: a short stout rod on the diagonal, a long cut crystal held in curved prongs. A design is "
         "the crystal's cut and length, the prongs, the cup and the rod's fittings.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Sceptre. An Uncommon's name keeps \"Baton\" alone.",
        "Each Legendary's one new form: Seikou (starlight), a crown of five small crystals; Gyouten (the dawn sky), petals "
        "opening round the crystal; Reikou (a cold light), a second crystal at its foot.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a healer's baton, never the Staff, and apart from its two neighbours, at 38 "
        "points? Does each Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
