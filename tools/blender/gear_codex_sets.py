"""AR6, batch 3: the Codex in three designs at each rarity, in grey: a blockout for research's verdict.

The Healer's off hand. One family: a slim, light book standing upright, turned so its fore-edge shows, shut by a
clasp that carries the Baton's own cut crystal. The Mage's Tome is its opposite, thick, dark and heavy, so the two
never meet at 38 points. A design is the clasp, the fittings and what the cover carries. A rarity keeps the ladder's
rule, a set keeps its word (gear_parts.py), and the near word from Rare up is Folio.

Each Legendary's one new form changes the silhouette: Kouseki's pages unfold from its fore-edge in a folded trail;
Ryuukou grows a tall crystal from the head of its spine; Hoshimi has a crystal at each corner pointing out.

    blender -b --factory-startup --python tools/blender/gear_codex_sets.py -- build/handoff/Gear/codex_sets

Writes the sheet gear_codex_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_crystal_baton_sets as cb  # noqa: E402
import gear_parts as p  # noqa: E402
import gear_sword_ladder as g  # noqa: E402
import gear_tome_sets as tm  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

g.GREY.setdefault("vellum", 0.8)     # the Codex's light covers, between cloth and ivory
mat = p.mat
TILT, SPIN = 6.0, -28.0
FILL, DROP, LEAST = 0.84, 0.0, 0.86
W, H, T, C = 1.7, 2.6, 0.4, 0.08
FRONT = -T / 2


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(cover="vellum", crystal="stone", corners="tip", clasps=1, gem=0.6,
                                                         spine_bands=2, frame=False, window=False, rivets=False,
                                                         form=None), **more))


DESIGNS = (
    design("Iron Codex", "Common", "Pale covers, iron tips on its corners, an iron clasp with a crystal.", "iron"),
    design("Bronze Codex", "Common", "A bronze spine and a bronze clasp, plain corners.", "bronze",
           corners=None, spine_bands=3),
    design("Scrap Codex", "Common", "Covers of thin plate riveted at the edge, a cord for a clasp.", "scrap",
           cover="scrap", rivets=True, corners=None, spine_bands=0),

    design("Lanternsteel Codex", "Uncommon", "Steel tips, a brass clasp, a long crystal.", "steel", trim="brass",
           gem=1.15),
    design("Rowsmith Codex", "Uncommon", "Two brass clasps, each with its crystal.", "steel", trim="brass",
           clasps=2, corners=None),
    design("Stallguard Codex", "Uncommon", "A brass frame round the cover, a window on its pages.", "steel",
           trim="brass", frame=True, window=True, corners=None),

    design("Folio of Embers", "Rare", "A swelling frame round a stone on the cover.", "blued",
           trim="filigree", orn="Embers", stone=("stone", 0.2), line="filigree"),
    design("Folio of Hoarfrost", "Rare", "A square stone in a spade, square tips.", "blued",
           trim="filigree", orn="Hoarfrost", stone=("stone", 0.2), cut="square", line="filigree", corners="square"),
    design("Folio of Gales", "Rare", "A vane sweeping across the cover from its stone.", "blued",
           trim="filigree", orn="Gales", stone=("stone", 0.2), line="filigree", corners=None),

    design("Stormcall Folio", "Epic", "Filigree curls roll out from its corners, a glowing crystal.", "rich",
           trim="filigree", orn="Stormcall", stone=("glow", 0.22), crystal="glow", line="filigree", corners=None),
    design("Gloamforge Folio", "Epic", "Filigree prongs in a row along its top, a square stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.22), crystal="glow", cut="square", line="filigree"),
    design("Nightloom Folio", "Epic", "A shuttle bound across the cover by threads round the book.", "rich",
           trim="filigree", orn="Nightloom", stone=("glow", 0.22), crystal="glow", line="filigree", corners=None),

    design("Kouseki, the Light Trail", "Legendary", "Its one new form: its pages unfold from the fore-edge in a "
           "folded trail.", "gilt", trim="ivory", cover="ivory", stone=("lit", 0.22), crystal="lit", edge=True,
           form="trail", clasps=0),
    design("Ryuukou, the High Spire", "Legendary", "Its one new form: a tall crystal grows from the head of its "
           "spine.", "gilt", trim="ivory", cover="ivory", stone=("lit", 0.22), crystal="lit", edge=True,
           form="spire"),
    design("Hoshimi, the Star Watch", "Legendary", "Its one new form: a crystal at each corner, pointing out.",
           "gilt", trim="ivory", cover="ivory", stone=("lit", 0.22), crystal="lit", edge=True, form="points",
           corners=None),
)


def body(d):
    parts = []
    for side in (-1, 1):
        parts.append(p.flat("Cover", tm.rounded(W, H, 0.08), C, d["cover"], y=side * (T / 2 - C / 2), bevel=0.02))
    parts.append(bl.place(bl.box("Pages", (W - 0.1, T - 2 * C, H - 0.12), mat("ivory")), (0.03, 0, 0)))
    for k in range(3):
        parts.append(bl.place(bl.box("Leaf", (0.012, (T - 2 * C) * 0.9, H - 0.14), mat("cloth")),
                              (W / 2 - 0.02, -T / 2 + C + (k + 1) * (T - 2 * C) / 4, 0)))
    spine = bl.cylinder("Spine", T / 2, H, segments=20, material=mat(d["cover"]))
    parts.append(bl.smooth_by_angle(bl.place(spine, (-W / 2, 0, 0), (0, 0, 0), (0.45, 1, 1)), 40.0))
    zs = {2: (-0.7, 0.7), 3: (-0.8, 0.0, 0.8)}.get(d["spine_bands"], ())
    for z in zs:
        band = bl.torus("Band", T / 2, 0.035, 28, 8, mat(d["trim"] if d["rarity"] != "Common" else d["key"]))
        parts.append(bl.smooth_by_angle(bl.place(band, (-W / 2, 0, z), (0, 0, 0), (0.5, 1.06, 1)), 40.0))
    return parts


def clasp(d, z):
    """A strap from the back cover over the fore-edge onto the front, carrying the Baton's cut crystal."""
    key, trim, parts, y = d["key"], d["trim"], [], FRONT - 0.02
    metal = trim if d["rarity"] in ("Uncommon",) else key
    if key == "scrap":
        parts.append(bl.place(bl.box("Cord", (0.5, 0.05, 0.06), mat("cord")), (W / 2 - 0.2, y, z)))
        parts.append(bl.place(bl.box("Cord", (0.06, T + 0.08, 0.06), mat("cord")), (W / 2 + 0.03, 0, z)))
    else:
        parts.append(p.flat("Strap", [(W / 2 - 0.5, z + 0.12), (W / 2 + 0.04, z + 0.12), (W / 2 + 0.04, z - 0.12),
                                      (W / 2 - 0.5, z - 0.12)], 0.04, metal, y=y, bevel=0.0))
        parts.append(bl.place(bl.box("Wrap", (0.06, T + 0.06, 0.24), mat(metal)), (W / 2 + 0.05, 0, z)))
    gem = cb.crystal("Crystal", 0.11 + 0.05 * (d["gem"] - 0.6), d["gem"], d["crystal"], 0.0, 6)
    p.move(gem, Matrix.Translation((W / 2 - 0.3, y - 0.12, z - 0.3)))
    parts.append(gem)
    for side in (-1, 1):
        prong = p.tube("Prong", [(W / 2 - 0.3 + side * 0.13, y - 0.02, z - 0.16), (W / 2 - 0.3 + side * 0.15, y - 0.1, z),
                                 (W / 2 - 0.3 + side * 0.09, y - 0.14, z + 0.12)], 0.025, metal, sides=6)
        parts.append(prong)
    return parts


def fittings(d):
    key, trim, parts, y = d["key"], d["trim"], [], FRONT - 0.02
    metal = trim if d["rarity"] in ("Uncommon",) else key
    if d["corners"]:
        for sx in (-1, 1):
            for sz in (-1, 1):
                tri = ([(0, 0), (-0.36, 0), (-0.36, -0.08), (-0.08, -0.36), (0, -0.36)] if d["corners"] == "square"
                       else [(0, 0), (-0.38, 0), (-0.3, -0.07), (-0.07, -0.3), (0, -0.38)])
                pts = [(sx * (W / 2 + 0.02 + x), sz * (H / 2 + 0.02 + z)) for x, z in tri]
                parts.append(p.flat("Corner", pts, 0.03, metal, y=y, bevel=0.01))
    if d["frame"]:
        a, b, k = W / 2 - 0.08, H / 2 - 0.08, 0.12
        for bar in ([(-a, b), (a, b), (a, b - k), (-a, b - k)], [(-a, -b + k), (a, -b + k), (a, -b), (-a, -b)],
                    [(-a, b - k), (-a + k, b - k), (-a + k, -b + k), (-a, -b + k)],
                    [(a - k, b - k), (a, b - k), (a, -b + k), (a - k, -b + k)]):
            parts.append(p.flat("Frame", bar, 0.035, trim, y=y, bevel=0.008))
    if d["window"]:
        parts.append(p.flat("Window", tm.rounded(0.7, 0.9, 0.3), 0.03, "ivory", y=y - 0.005, bevel=0.0))
        parts[-1].data.transform(Matrix.Translation((-0.1, 0, 0.35)))
        parts.append(p.facing("Window rim", 0.48, 0.03, trim, (-0.1, y - 0.02, 0.35)))
    if d["rivets"]:
        for x, z in ((-0.62, 1.12), (0.62, 1.12), (-0.62, -1.12), (0.62, -1.12), (-0.62, 0.0)):
            parts.append(p.ball("Rivet", 0.05, "iron", (x, y, z), squash=(1, 0.6, 1), segments=6, rings=4))
    if d["line"]:
        ring = tm.rounded(W - 0.42, H - 0.42, 0.1)
        parts.append(p.tube("Line", [(x, y - 0.02, z) for x, z in ring + ring[:2]], 0.02, d["line"], sides=6))
    if d["edge"]:
        ring = tm.rounded(W - 0.26, H - 0.26, 0.1)
        parts.append(p.tube("Edge", [(x, y - 0.02, z) for x, z in ring + ring[:2]], 0.026, "lit", sides=6))
    for k in range(d["clasps"]):
        parts += clasp(d, 0.0 if d["clasps"] == 1 else (0.62 if k == 0 else -0.62))

    orn, at = d["orn"], (-0.12, y - 0.03, 0.35)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Ornament", p.set_ornament(orn, 0.9, (at[0], at[2])), 0.035, trim, y=y - 0.01))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, at[0] - 0.05, at[2] - 0.05, 0.8, 0.8), 0.035, trim, y=y - 0.01))
    elif orn == "Stormcall":
        for sx in (-1, 1):
            for sz in (-1, 1):
                root = (sx * (W / 2 - 0.12), sz * (H / 2 - 0.12))
                parts.append(p.curl(root, sx, 0.68, trim, y=y - 0.02, turn=11.0 if sz > 0 else 101.0, r=0.065))
    elif orn == "Gloamforge":
        for x in (-0.38, 0.4):
            parts.append(p.flat("Crest", p.set_ornament(orn, 0.52, (x, H / 2 - 0.1)), 0.08, trim, y=0.0))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, at[0], at[2], 2.1, 1.5), 0.05, trim, y=y - 0.02))
        ring = tm.rounded(W + 0.06, T + 0.08, 0.06)
        for z in (0.75, -0.1):
            parts.append(p.tube("Thread", [(x + 0.04, yy, z) for x, yy in ring + ring[:2]], 0.025, trim, sides=6))
    parts += p.stone_of(d, 1.0, at)
    return parts


def legend(d):
    trim, parts, form = d["trim"], [], d["form"]
    if form == "trail":
        at, a, height = Vector((W / 2, 0.0, 0.0)), 0.0, H - 0.3
        for k in range(5):
            a = math.radians(-40.0 if k % 2 == 0 else 40.0)
            step = Vector((math.cos(a), math.sin(a), 0.0)) * 0.78
            mid = at + step / 2
            panel = bl.place(bl.box("Fold", (0.78, 0.035, height), mat("ivory")), (0, 0, 0))
            p.move(panel, Matrix.Translation(mid) @ Matrix.Rotation(a, 4, "Z"))
            parts.append(panel)
            for z in (height / 2 - 0.05, -height / 2 + 0.05):
                rim = bl.place(bl.box("Fold rim", (0.78, 0.05, 0.05), mat(trim)), (0, 0, z))
                p.move(rim, Matrix.Translation(mid) @ Matrix.Rotation(a, 4, "Z"))
                parts.append(rim)
            at, height = at + step, height * 0.9
        parts += p.stone("lit", 0.12, (at.x, at.y - 0.06, 0.0), trim)
    elif form == "spire":
        cup = p.lathe("Cup", [(0.12, 0.0), (0.2, 0.08), (0.26, 0.18)], d["key"], thick=0.04)
        p.move(cup, Matrix.Translation((-W / 2 + 0.05, 0, H / 2)))
        parts.append(cup)
        spire = cb.crystal("Spire", 0.22, 1.7, "lit", 0.0, 6)
        p.move(spire, Matrix.Translation((-W / 2 + 0.05, 0, H / 2 + 0.06)))
        parts.append(spire)
        for k in range(3):
            small = cb.crystal("Small", 0.1, 0.7, "lit", 0.0, 6)
            a = 2 * math.pi * k / 3 + 0.4
            p.move(small, Matrix.Translation((-W / 2 + 0.05 + 0.2 * math.cos(a), 0.2 * math.sin(a), H / 2 + 0.05)) @
                   Matrix.Rotation(math.radians(24), 4, Vector((-math.sin(a), math.cos(a), 0))))
            parts.append(small)
    elif form == "points":
        for sx in (-1, 1):
            for sz in (-1, 1):
                gem = cb.crystal("Point", 0.13, 1.0, "lit", 0.0, 6)
                direction = Vector((sx, 0, sz * 1.15)).normalized()
                q = Vector((0, 0, 1)).rotation_difference(direction)
                p.move(gem, Matrix.Translation((sx * (W / 2 - 0.12), FRONT - 0.04, sz * (H / 2 - 0.12))) @
                       q.to_matrix().to_4x4())
                parts.append(gem)
                parts.append(p.ball("Setting", 0.12, trim, (sx * (W / 2 - 0.12), FRONT - 0.04, sz * (H / 2 - 0.12)),
                                    squash=(1, 0.6, 1), segments=10, rings=6))
    return parts


def codex(d):
    return body(d) + fittings(d) + legend(d)


def build(d):
    return p.scene_of(lambda: codex(d), TILT, SPIN)


WORDS = dict(
    file="gear_codex_sets.png",
    title="Grow your Anime: the Codex in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Healer's off hand: a slim, light book standing upright, turned so its fore-edge shows, shut by a clasp that "
         "carries the Baton's cut crystal. A design is the clasp, the fittings and what the cover carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Folio.",
        "Each Legendary's one new form: Kouseki (a trail of light), pages unfolding in a folded trail; Ryuukou (a flowing "
        "light), a tall crystal from its spine; Hoshimi (star-watching), a crystal at each corner.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a codex, slim and light beside the Tome, and apart from its two neighbours, at "
        "38 points? Does each Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
