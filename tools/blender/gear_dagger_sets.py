"""AR6, batch 3: the Dagger in three designs at each rarity, in grey: a blockout for research's verdict.

The Assassin's main hand. One family: a short curved single-edged fang laid on the diagonal, its point up and to the
right and bending back toward the top left, a short wrapped grip and a ring for a pommel. The Short Sword is straight,
two-edged and cross-guarded, so the two never meet at 38 points. A design is the blade's curve and width, the guard
(none, a hooked quillon on the edge's side, a disc), the ring, and what the blade carries. A rarity keeps the
ladder's rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Fang.

Each Legendary's one new form changes the silhouette: Kougetsu's guard sweeps back round the hand to its ring in a
crescent; Yuugure's ring carries a second, smaller fang turned the other way; Bunkou's blade opens into a fork of two points.

    blender -b --factory-startup --python tools/blender/gear_dagger_sets.py -- build/handoff/Gear/dagger_sets

Writes the sheet gear_dagger_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402

mat = p.mat
FILL, DROP, LEAST = 0.84, 0.0, 0.9
L, GRIP, RING = 3.0, 1.15, 0.3      # the blade's length, the grip's, the pommel ring's radius


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(bend=0.55, width=0.62, guard="block", ring=RING,
                                                         grip="leather", hole=False, notch=False, split=False,
                                                         back=False, moon=False, ridge=True), **more))


DESIGNS = (
    # lift, glint: in colour, research's verdict on batch 3 in colour (gear_icons.py): plain iron toned to a mid grey with a light edge, a flat bronze face's streak
    design("Iron Dagger", "Common", "A plain iron fang, a block for a guard, a plain ring.", "iron", grip="wood", lift="iron"),
    design("Bronze Dagger", "Common", "A broad bronze fang bent hard, a hooked quillon.", "bronze",
           bend=0.8, width=0.72, guard="hook", grip="cord", glint="bronze"),
    design("Scrap Dagger", "Common", "A cut strip of plate with a bolt hole, wrapped in cord.", "scrap",
           bend=0.4, width=0.56, guard=None, hole=True, grip="cord", ridge=False),

    design("Lanternsteel Dagger", "Uncommon", "A slim bright fang, a brass disc guard, a brass ring.", "steel",
           trim="brass", bend=0.6, width=0.56, guard="disc"),
    design("Rowsmith Dagger", "Uncommon", "A notch in the back, a brass hooked quillon.", "steel",
           trim="brass", notch=True, guard="hook"),
    design("Stallguard Dagger", "Uncommon", "A broad fang, a brass block guard and a large ring.", "steel",
           trim="brass", width=0.74, bend=0.45, ring=0.38),

    design("Fang of Embers", "Rare", "A swelling frame round a stone at the blade's root.", "blued",
           trim="filigree", orn="Embers", stone=("stone", 0.15), line="filigree", guard="disc"),
    design("Fang of Hoarfrost", "Rare", "A square stone in a spade, the guard cut square.", "blued",
           trim="filigree", orn="Hoarfrost", stone=("stone", 0.15), cut="square", line="filigree", guard="block",
           bend=0.4),
    design("Fang of Gales", "Rare", "A vane sweeping back off the guard, a hole through the blade.", "blued",
           trim="filigree", orn="Gales", stone=("stone", 0.15), line="filigree", hole=True, bend=0.7),

    design("Stormcall Fang", "Epic", "Filigree curls roll out from the guard, a glowing stone.", "rich",
           trim="filigree", orn="Stormcall", stone=("glow", 0.17), line="filigree", guard="disc", width=0.68),
    design("Gloamforge Fang", "Epic", "Filigree prongs standing on the back, a square stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.17), cut="square", line="filigree", guard="hook",
           width=0.68),
    design("Nightloom Fang", "Epic", "A shuttle laid across the guard, threads round the grip.", "rich",
           trim="filigree", orn="Nightloom", stone=("glow", 0.17), line="filigree", guard="block", bend=0.7,
           width=0.68),

    design("Kougetsu, the Pale Moon", "Legendary", "Its one new form: the guard sweeps back round the hand to the "
           "ring in a crescent.", "gilt", trim="ivory", stone=("lit", 0.17), edge=True, moon=True, guard="disc",
           width=0.7),
    design("Yuugure, the Nightfall", "Legendary", "Its one new form: a second fang on the ring, turned the other "
           "way.", "gilt", trim="ivory", stone=("lit", 0.17), edge=True, back=True, guard="hook", width=0.7),
    design("Bunkou, the Split Ray", "Legendary", "Its one new form: the blade opens into a fork of two points.", "gilt",
           trim="ivory", stone=("lit", 0.17), edge=True, split=True, guard="disc", width=0.78, bend=0.5),
)


SPLIT = 0.55                        # how far up a forked blade opens


def fang(d, length=L, scale=1.0):
    """The blade's outline from its root's edge side round the point to its root's back: the back (+x) a long
    convex curve, the edge (-x) hollowed, the point bending toward -x."""
    w, bend, n = d["width"] * scale, d["bend"] * scale, 14
    back, edge = [], []
    for i in range(n + 1):
        t = i / n
        cx = -bend * t * t
        hw = w / 2 * (1 - t ** 1.7)
        back.append((cx + hw * (1.0 + 0.15 * t), t * length))
        edge.append((cx - hw * (1.0 - 0.25 * t), t * length))
    if d["notch"]:
        k = int(n * 0.35)
        x, z = back[k]
        back[k] = (x - 0.14, z)
    if d["split"]:
        # the blade opens into a fork from its middle: two tines spreading apart, a deep crotch between them
        k = int(n * SPLIT)
        (ex, z0), (bx, _) = edge[k], back[k]
        rest = length - z0
        crotch = ((ex + bx) / 2, z0 + 0.28 * rest)
        tine_e = [(ex - 0.26, z0 + 0.5 * rest), (ex - 0.6, length), (ex - 0.06, z0 + 0.56 * rest)]
        tine_b = [(bx - 0.02, z0 + 0.6 * rest), (bx + 0.5, length * 1.03), (bx + 0.24, z0 + 0.45 * rest)]
        return edge[:k + 1] + tine_e + [crotch] + tine_b + list(reversed(back[:k + 1]))
    return edge + list(reversed(back[:-1]))


def blade_parts(d):
    key, trim, parts = d["key"], d["trim"], []
    outline = fang(d)
    parts.append(p.flat("Blade", outline, 0.1, key, bevel=0.03))
    n = 14
    top = int(n * SPLIT) if d["split"] else n          # a forked blade's ridge and edge stop where it opens
    if d["ridge"] or d["line"]:
        pts = [(-d["bend"] * (i / n) ** 2 + d["width"] / 2 * 0.35 * (1 - (i / n) ** 1.7), -0.055, (i / n) * L)
               for i in range(1, min(n - 1, top))]
        parts.append(p.tube("Ridge" if not d["line"] else "Line", pts, 0.018 if not d["line"] else 0.022,
                            d["line"] or key, sides=6))
    if d["edge"]:
        pts = [(-d["bend"] * (i / n) ** 2 - d["width"] / 2 * (1 - (i / n) ** 1.7) * 0.92, -0.055, (i / n) * L)
               for i in range(1, top + 1 if d["split"] else n)]
        parts.append(p.tube("Edge", pts, 0.026, "lit", sides=6))
    if d["hole"]:
        parts.append(p.facing("Hole", 0.11, 0.03, "liner" if d["key"] == "scrap" else trim, (-0.04, -0.05, 0.55)))
    return parts


def guard_parts(d):
    key, trim, parts, g = d["key"], d["trim"], [], d["guard"]
    metal = trim if d["rarity"] != "Common" else key
    if g == "block":
        parts.append(bl.place(bl.box("Guard", (0.88, 0.2, 0.18), mat(metal)), (0, 0, -0.04)))
    elif g == "hook":
        hook = [(0.38, 0.05), (0.38, -0.12), (-0.3, -0.12), (-0.56, 0.08), (-0.64, 0.42), (-0.52, 0.4), (-0.44, 0.12),
                (-0.28, 0.05)]
        parts.append(p.flat("Guard", hook, 0.14, metal, bevel=0.03))
    elif g == "disc":
        disc = bl.cylinder("Guard", 0.42, 0.12, segments=24, material=mat(metal))
        parts.append(bl.smooth_by_angle(bl.place(disc, (0, 0, -0.04), (0, 0, 0), (1, 0.55, 1)), 40.0))
    return parts


def handle_parts(d):
    key, trim, parts = d["key"], d["trim"], []
    metal = trim if d["rarity"] != "Common" else key
    if d["key"] == "scrap":
        parts.append(p.rod("Tang", -GRIP, -0.1, 0.12, "scrap", sides=6))
    parts += p.grip_wrap(-GRIP, -0.1, 0.11, d["grip"], 6)
    parts.append(p.rod("Ferrule", -GRIP - 0.1, -GRIP + 0.02, 0.13, metal, sides=12))
    r = d["ring"]
    parts.append(p.facing("Ring", r, 0.065, metal, (0, 0, -GRIP - 0.1 - r)))
    if d["back"]:
        back = fang(dict(d, notch=False, split=False), length=1.5, scale=0.62)
        back = [(-x, -GRIP - 0.1 - 2 * r - z) for x, z in back]
        parts.append(p.flat("Back fang", back, 0.08, d["key"], bevel=0.025))
        n = 10
        pts = [(d["bend"] * 0.62 * (i / n) ** 2 + d["width"] * 0.31 * (1 - (i / n) ** 1.7) * 0.9, -0.045,
                -GRIP - 0.1 - 2 * r - (i / n) * 1.5) for i in range(1, n)]
        parts.append(p.tube("Edge", pts, 0.022, "lit", sides=6))
    if d["moon"]:
        pts = [(-0.4, 0, -0.06), (-0.78, 0, -0.45), (-0.8, 0, -0.98), (-0.55, 0, -1.4), (-0.12, 0, -GRIP - 0.12 - r * 1.2)]
        path = p.curve(pts, 26)
        parts.append(p.tube("Crescent", path, [0.06 + 0.07 * math.sin(math.pi * i / 25) for i in range(26)], trim,
                            sides=10))
    return parts


def ornament_parts(d):
    trim, parts, orn = d["trim"], [], d["orn"]
    at = (0.02, -0.07, 0.42)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Frame", p.set_ornament(orn, 0.36, (at[0], at[2])), 0.04, trim, y=-0.06))
    elif orn == "Gales":
        vane = p.turned(p.shifted(p.VANE, 0, 0, 0.75, 0.75), -55.0)
        parts.append(p.flat("Vane", p.shifted(vane, 0.32, -0.02), 0.06, trim))
    elif orn == "Stormcall":
        for side in (-1, 1):
            parts.append(p.curl((side * 0.36, -0.02), side, 0.55, trim, turn=40.0, r=0.07))
    elif orn == "Gloamforge":
        crest = p.turned(p.set_ornament(orn, 0.5, (0, 0)), -78.0)
        parts.append(p.flat("Crest", p.shifted(crest, 0.42, 0.95), 0.06, trim))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0.0, -0.04, 1.5, 1.3), 0.08, trim, y=-0.1))
        parts += p.bands((-0.35, -0.85), 0.12, trim, minor=0.03)
    parts += p.stone_of(d, 1.0, at)
    return parts


def dagger(d):
    parts = blade_parts(d) + guard_parts(d) + handle_parts(d) + ornament_parts(d)
    return p.laid(parts, spin=18.0)


def build(d):
    return p.scene_of(lambda: dagger(d), 0.0, 0.0)


WORDS = dict(
    file="gear_dagger_sets.png",
    title="Grow your Anime: the Dagger in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Assassin's main hand: a short curved single-edged fang on the diagonal, its point bending back toward the "
         "top left, a ring for a pommel. A design is the blade's curve, the guard, the ring and what the blade carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Fang.",
        "Each Legendary's one new form: Kougetsu (a pale bright moon), a crescent guard round the hand; Yuugure "
        "(nightfall), a second fang on the ring; Bunkou (light split apart), a blade opening into a fork.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a dagger, never the Short Sword, and apart from its two neighbours, at 38 "
        "points? Does each Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
