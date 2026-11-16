"""AR6, batch 2: Earrings in three designs at each rarity, in grey: a blockout for research's verdict.

One family: one earring seen from the front and a little to the side, hanging from its hook (or its stud, or as a
hoop), a short drop below. A hook and a single drop, so it never reads as the Amulet's loop or the Ring's band. A design
is the hook and the drop. A rarity keeps the ladder's rule, a set keeps its word (gear_parts.py; the set drops are the
amulet's pendants, drawn smaller), and the near word from Rare up is Eardrop.

Each Legendary's one new form changes the silhouette: Kagayaki hangs a cascade of lights in three tiers widening down,
Yuzuki holds a pearl in a crescent's cradle, Hatsuhi's rays fan up and back past its hook like the year's first sun.

    blender -b --factory-startup --python tools/blender/gear_earring_sets.py -- build/handoff/Gear/earring_sets

Writes the sheet gear_earring_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_amulet_sets as am  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
TILT, SPIN = 4.0, 24.0     # nearly level, turned so the hook shows its curve
FILL, DROP = 0.8, 0.0
LEAST = 0.86
DROP_AT = (0.0, 0.0, -0.1)   # the drop's middle


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(top="hook", chain_mat=key, form=None, rims=None, studs=None,
                                                         size=1.0, links=1), **more))


DESIGNS = (
    design("Iron Earring", "Common", "A small iron ring on an iron hook.", "iron", form="ring"),
    design("Bronze Earring", "Common", "A bronze bead on a hook.", "bronze", form="bead"),
    design("Scrap Earring", "Common", "A bent tag of scrap on an iron hook.", "scrap", chain_mat="iron", form="tag"),

    design("Lanternsteel Earring", "Uncommon", "A steel hoop with a brass bead hung at its foot.", "steel", top="hoop",
           form="hoopbead", rims="brass"),
    design("Rowsmith Earring", "Uncommon", "A brass lozenge in a steel frame, on a hook.", "steel", form="lozenge",
           rims="brass"),
    design("Stallguard Earring", "Uncommon", "A steel stud and three brass beads on a short chain.", "steel", top="stud",
           form="beads", studs="brass"),

    design("Eardrop of Embers", "Rare", "A swelling frame round one stone, on a filigree hook.", "blued",
           trim="filigree", chain_mat="filigree", orn="Embers", stone=("stone", 0.2)),
    design("Eardrop of Hoarfrost", "Rare", "A spade round a square stone.", "blued", trim="filigree",
           chain_mat="filigree", orn="Hoarfrost", stone=("stone", 0.2), cut="square"),
    design("Eardrop of Gales", "Rare", "Two vanes sweep up and out from a stone.", "blued", trim="filigree",
           chain_mat="filigree", orn="Gales", stone=("stone", 0.2)),

    design("Stormcall Eardrop", "Epic", "Filigree hooks curl out round a glowing stone, two links.", "rich",
           trim="filigree", chain_mat="filigree", orn="Stormcall", stone=("glow", 0.24), links=2),
    design("Gloamforge Eardrop", "Epic", "Filigree prongs round a square glowing stone.", "rich", trim="filigree",
           chain_mat="filigree", orn="Gloamforge", stone=("glow", 0.24), cut="square"),
    design("Nightloom Eardrop", "Epic", "A shuttle across a glowing stone, a tassel below.", "rich", trim="filigree",
           chain_mat="filigree", orn="Nightloom", stone=("glow", 0.24)),

    design("Kagayaki, the Brilliance", "Legendary", "Its one new form: a cascade of lights in three tiers widening "
           "down.", "gilt", trim="ivory", chain_mat="gilt", form="cascade", stone=("lit", 0.12), edge=True),
    design("Yuzuki, the Evening Moon", "Legendary", "Its one new form: a pearl of light held in a crescent's cradle.",
           "gilt", trim="ivory", chain_mat="gilt", form="crescent", edge=True),
    design("Hatsuhi, the First Sun", "Legendary", "Its one new form: rays fan up and back past the hook, a stone at "
           "their foot.", "gilt", trim="ivory", chain_mat="gilt", form="fan", stone=("lit", 0.18), edge=True),
)


def hook(d):
    """What the earring hangs from: a hook through the ear, a stud, or the hoop itself."""
    top, metal = d["top"], d["chain_mat"]
    if top == "hoop":
        return [p.facing("Hoop", 0.5, 0.05, d["key"], (0.0, 0.0, 0.62))]
    if top == "stud":
        return [p.ball("Stud", 0.13, d["key"], (0.0, 0.0, 0.92), squash=(1, 0.6, 1)),
                p.tube("Post", [(0.0, 0.0, 0.92), (0.0, 0.3, 0.92)], 0.025, metal, sides=6)]
    path = [(0.0, 0.0, 0.62), (0.0, 0.0, 0.86), (0.04, 0.02, 1.08), (0.18, 0.1, 1.26), (0.36, 0.2, 1.2),
            (0.42, 0.26, 0.98), (0.38, 0.3, 0.72)]
    out = [p.tube("Hook", p.curve(path, 20), 0.03, metal, sides=8)]
    for k in range(d["links"]):
        out.append(p.facing("Link", 0.06, 0.02, metal, (0.0, 0.0, 0.58 - 0.12 * k)))
    return out


def drop(d):
    key, trim, form, parts = d["key"], d["trim"], d["form"], []
    x0, y0, z0 = DROP_AT
    if form == "none":
        return parts
    if form == "bead":
        parts.append(p.ball("Bead", 0.22, key, (x0, y0, z0 + 0.2), segments=20, rings=12))
    elif form == "hoopbead":
        parts.append(p.facing("Link", 0.05, 0.018, d["rims"], (x0, y0, 0.08)))
        parts.append(p.ball("Bead", 0.13, d["rims"], (x0, y0, -0.06), segments=16, rings=10))
    elif form == "beads":
        for k in range(3):
            z = 0.66 - 0.32 * k
            parts.append(p.facing("Link", 0.05, 0.018, key, (x0, y0, z + 0.14)))
            parts.append(p.ball("Bead", 0.1 + 0.03 * k, d["studs"], (x0, y0, z - 0.02), segments=16, rings=10))
    elif form == "cascade":
        for tier, (count, width, z) in enumerate(((1, 0.0, 0.36), (3, 0.36, 0.0), (5, 0.7, -0.42))):
            if count > 1:
                parts.append(p.tube("Bar", p.curve([(x0 - width, y0, z + 0.12), (x0, y0, z + 0.04),
                                                    (x0 + width, y0, z + 0.12)], 12), 0.025, trim, sides=6))
            for j in range(count):
                x = x0 + (width * (2 * j / (count - 1) - 1) if count > 1 else 0.0)
                length = 0.22 + 0.08 * tier
                parts.append(p.flat("Drop", p.shifted([(0, 0.08), (0.07, 0.0), (0.05, -length), (0, -length - 0.06),
                                                       (-0.05, -length), (-0.07, 0.0)], x, z + 0.04), 0.06,
                                    "lit" if (j + tier) % 2 == 0 else trim, y=y0))
            if tier < 2:
                parts.append(p.tube("Thread", [(x0, y0, z - 0.02), (x0, y0, z - 0.26)], 0.018, trim, sides=6))
    elif form == "crescent":
        outer = [(0.5 * math.cos(math.radians(a)), 0.5 * math.sin(math.radians(a))) for a in range(196, 345, 8)]
        inner = [(0.4 * math.cos(math.radians(a)), 0.14 + 0.4 * math.sin(math.radians(a))) for a in range(336, 203, -8)]
        parts.append(p.flat("Crescent", p.shifted(outer + inner, x0, z0 + 0.1), 0.07, trim, y=y0))
        parts.append(p.ball("Pearl", 0.2, "lit", (x0, y0, z0 + 0.04), segments=20, rings=12))
        parts.append(p.tube("Hanger", [(x0, y0, z0 + 0.54), (x0, y0, z0 + 0.25)], 0.02, key, sides=6))
    elif form == "fan":
        for j, a in enumerate(range(-20, 81, 20)):
            ray = p.turned(p.leaf(0.9 + 0.3 * math.cos(math.radians(a - 30)), 0.16), -a, (0, 0))
            parts.append(p.flat("Ray", p.shifted(ray, x0 + 0.05, z0 + 0.2), 0.05, trim if j % 2 else key,
                                y=y0 + 0.12 + 0.02 * j))
        parts += p.stone("lit", 0.18, (x0 + 0.05, y0 - 0.04, z0 + 0.2), trim)
        return parts
    else:   # the set's drops and the plain forms: the amulet's pendants, drawn smaller
        return am.pendant(dict(d, form=form if form in ("tag", "lozenge", "ring") else None), (x0, y0, 0.12), 0.8)
    if d["stone"] and form == "cascade":
        parts += p.stone(d["stone"][0], d["stone"][1], (x0, y0 - 0.04, 0.4), trim)
    if d["edge"] and form != "fan":
        parts.append(p.facing("Glint", 0.08, 0.02, "lit", (x0, y0, 0.56)))
    return parts


def build(d):
    def parts():
        out = hook(d) + drop(d)
        for obj in out:   # the round ones, smooth
            if obj.name.startswith(("Bead", "Pearl", "Stud")):
                bl.smooth_by_angle(obj, 80.0)
        return out
    return p.scene_of(parts, TILT, SPIN)


WORDS = dict(
    file="gear_earring_sets.png",
    title="Grow your Anime: Earrings in three designs at each rarity, in grey (AR6, batch 2)",
    lead="One earring from the front and a little to the side, hanging from its hook, its stud, or as a hoop, a short "
         "drop below. A design is the hook and the drop.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Eardrop.",
        "Each Legendary's one new form: Kagayaki (brilliance), a cascade in three tiers; Yuzuki (the evening moon), a pearl "
        "in a crescent; Hatsuhi (the year's first sunrise), rays fanning up past the hook.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as an earring, and apart from its two neighbours, at 38 points? Does each "
        "Legendary outrank every Epic by shape? Not here yet: colour, frames.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
