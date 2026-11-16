"""AR6, batch 3: the Tome in three designs at each rarity, in grey: a blockout for research's verdict.

The Mage's off hand. One family: a heavy, thick, dark book, closed and standing, turned so its rounded spine and its
top edge's pages show, its covers in dark leather and its metal at the corners. The Healer's Codex is its opposite,
slim, light and upright with a crystal clasp, so the two never meet at 38 points. A design is the fittings (corners,
a boss, bands on the spine, a frame), the clasp, and what the cover carries. A rarity keeps the ladder's rule, a set
keeps its word (gear_parts.py), and the near word from Rare up is Grimoire.

Each Legendary's one new form changes the silhouette: Yamiyo lies open, its covers spread and its pages fanned;
Seiza carries a star chart's dial on its cover, the ring wider than the book and its needle past it; Rinkou has
three broad ribbon markers sweeping out of the head of its pages past the fore-edge, fanned, each with a cut stone set
on it and a forked end: never at the book's foot, never a strand ending in a round drop.

    blender -b --factory-startup --python tools/blender/gear_tome_sets.py -- build/handoff/Gear/tome_sets

Writes the sheet gear_tome_sets.png. Workbench only: no GPU turn.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import gear_parts as p  # noqa: E402
from mathutils import Matrix  # noqa: E402

mat = p.mat
TILT, SPIN = 16.0, 30.0
FILL, DROP, LEAST = 0.84, 0.0, 0.86
W, H, T, C = 2.0, 2.6, 0.92, 0.12      # the book's width, height, thickness; a cover's thickness
FRONT = -T / 2                          # the front cover's face


def rounded(w, h, r, n=4):
    """A rectangle w by h about the origin, its corners rounded by r."""
    out = []
    for cx, cz, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180),
                       (w / 2 - r, -h / 2 + r, 270)):
        for i in range(n + 1):
            a = math.radians(a0 + 90 * i / n)
            out.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return out

# The covers' dark leather and the pages: grey as the lining and the cloth were, so the grey sheet stays as it is; in
# colour each its own (gear_icons.py: the boards' leather agrees with the rarity, the paper is cream).
p.g.GREY.setdefault("boards", p.g.GREY["liner"])
p.g.GREY.setdefault("paper", p.g.GREY["cloth"])


def design(name, rarity, note, key, **more):
    return p.design(name, rarity, note, key, **dict(dict(cover="boards", pages="paper", corners="cap", boss=None,
                                                         spine_bands=2, clasp="strap", frame=False, studs=0,
                                                         cord=False, bolts=False, form=None), **more))


DESIGNS = (
    # lift, glint: in colour, research's verdict on batch 3 in colour (gear_icons.py): plain iron toned to a mid grey with a light edge, a flat bronze face's streak
    design("Iron Tome", "Common", "Dark leather, iron caps on its corners, an iron strap clasp.", "iron", lift="boards"),
    design("Bronze Tome", "Common", "A bronze boss on the cover, bronze corners, three bands on the spine.", "bronze",
           boss=0.3, spine_bands=3, clasp=None, lift="boards"),
    design("Scrap Tome", "Common", "Covers of plate bolted on, a cord tied round it twice.", "scrap",
           cover="scrap", corners=None, cord=True, bolts=True, clasp=None, spine_bands=0),

    design("Lanternsteel Tome", "Uncommon", "Steel corners, a brass clasp, steel bands on the spine.", "steel",
           trim="brass", spine_bands=3),
    design("Rowsmith Tome", "Uncommon", "A ring of brass studs on the cover round a boss.", "steel",
           trim="brass", boss=0.22, studs=10, clasp=None),
    design("Stallguard Tome", "Uncommon", "A brass frame round the cover, a lock plate on its clasp.", "steel",
           trim="brass", frame=True, clasp="lock", corners=None),

    design("Grimoire of Embers", "Rare", "A swelling frame round a stone on the cover, filigree corners.", "blued",
           trim="filigree", orn="Embers", stone=("stone", 0.26), line="filigree"),
    design("Grimoire of Hoarfrost", "Rare", "Corners cut square, a square stone in a spade.", "blued",
           trim="filigree", orn="Hoarfrost", stone=("stone", 0.26), cut="square", line="filigree", corners="square"),
    design("Grimoire of Gales", "Rare", "A vane sweeping across the cover from its stone.", "blued",
           trim="filigree", orn="Gales", stone=("stone", 0.26), line="filigree", clasp=None),

    design("Stormcall Grimoire", "Epic", "Filigree curls roll out from its corners, a glowing stone.", "rich",
           trim="filigree", orn="Stormcall", stone=("glow", 0.3), line="filigree", frame=True, corners=None),
    design("Gloamforge Grimoire", "Epic", "Filigree prongs in a row along its top, a square stone.", "rich",
           trim="filigree", orn="Gloamforge", stone=("glow", 0.3), cut="square", line="filigree", spine_bands=3),
    design("Nightloom Grimoire", "Epic", "A shuttle bound across the cover by threads round the book.", "rich",
           trim="filigree", orn="Nightloom", stone=("glow", 0.3), line="filigree", clasp=None),

    design("Yamiyo, the Dark Night", "Legendary", "Its one new form: it lies open, its pages fanned.", "gilt",
           trim="ivory", cover="rich", pages="ivory", stone=("lit", 0.28), form="open", edge=True),
    design("Seiza, the Star Chart", "Legendary", "Its one new form: a star chart's dial on its cover, wider than "
           "the book.", "gilt", trim="ivory", cover="rich", pages="ivory", stone=("lit", 0.24), form="dial",
           edge=True, corners="cap"),
    design("Rinkou, the Pale Glow", "Legendary", "Its one new form: three ribbon markers sweep out of its head, "
           "forked, a cut stone on each.", "gilt", trim="ivory", cover="rich", pages="ivory", stone=("lit", 0.28), form="ribbons",
           edge=True, frame=True, corners=None),
)


def body(d, w=W):
    """The closed book: covers, the page block, the rounded spine (on the left, -x)."""
    parts = []
    for side in (-1, 1):
        parts.append(p.flat("Cover", p.shifted(rounded(w, H, 0.1), 0.0, 0.0), C, d["cover"], y=side * (T / 2 - C / 2),
                            bevel=0.03))
    parts.append(bl.place(bl.box("Pages", (w - 0.14, T - 2 * C, H - 0.16), mat(d["pages"])), (0.03, 0, 0)))
    for k in range(5):      # the pages' lines along the top edge
        parts.append(bl.place(bl.box("Leaf", (w - 0.16, 0.012, 0.02), mat("liner")),
                              (0.03, -T / 2 + C + (k + 1) * (T - 2 * C) / 6, H / 2 - 0.075)))
    spine = bl.cylinder("Spine", T / 2, H, segments=24, material=mat(d["cover"]))
    parts.append(bl.smooth_by_angle(bl.place(spine, (-w / 2, 0, 0), (0, 0, 0), (0.5, 1, 1)), 40.0))
    zs = {2: (-0.55, 0.55), 3: (-0.8, 0.0, 0.8)}.get(d["spine_bands"], ())
    for z in zs:
        band = bl.torus("Band", T / 2, 0.045, 32, 8, mat(d["trim"] if d["rarity"] != "Common" else d["key"]))
        parts.append(bl.smooth_by_angle(bl.place(band, (-w / 2, 0, z), (0, 0, 0), (0.5 + 0.08, 1.06, 1)), 40.0))
    return parts


def fittings(d, w=W):
    key, trim, parts, y = d["key"], d["trim"], [], FRONT - 0.02
    metal = trim if d["rarity"] in ("Uncommon",) else key
    if d["corners"]:
        for sx in (-1, 1):
            for sz in (-1, 1):
                if d["corners"] == "square":
                    tri = [(0, 0), (-0.5, 0), (-0.5, -0.12), (-0.12, -0.5), (0, -0.5)]
                else:
                    tri = [(0, 0), (-0.55, 0), (-0.42, -0.1), (-0.1, -0.42), (0, -0.55)]
                pts = [(sx * (w / 2 + 0.03 + x), sz * (H / 2 + 0.03 + z)) for x, z in tri]
                for yy in (y, -y):
                    parts.append(p.flat("Corner", pts, 0.04, metal, y=yy, bevel=0.012))
    if d["frame"]:
        a, b, k = w / 2 - 0.08, H / 2 - 0.08, 0.15      # the frame: four bars inside the cover's edge
        for bar in ([(-a, b), (a, b), (a, b - k), (-a, b - k)], [(-a, -b + k), (a, -b + k), (a, -b), (-a, -b)],
                    [(-a, b - k), (-a + k, b - k), (-a + k, -b + k), (-a, -b + k)],
                    [(a - k, b - k), (a, b - k), (a, -b + k), (a - k, -b + k)]):
            parts.append(p.flat("Frame", bar, 0.04, trim, y=y, bevel=0.01))
    if d["line"]:
        ring = rounded(w - 0.5, H - 0.5, 0.12)
        parts.append(p.tube("Line", [(x, y - 0.02, z) for x, z in ring + ring[:2]], 0.022, d["line"], sides=6))
    if d["edge"]:
        ring = rounded(w - 0.3, H - 0.3, 0.1)
        parts.append(p.tube("Edge", [(x, y - 0.02, z) for x, z in ring + ring[:2]], 0.03, "lit", sides=6))
    if d["boss"]:
        parts.append(p.ball("Boss", d["boss"], metal, (0, y, 0.1), squash=(1, 0.5, 1), segments=16, rings=8))
    if d["studs"]:
        for i in range(d["studs"]):
            a = 2 * math.pi * i / d["studs"]
            parts.append(p.ball("Stud", 0.06, trim, (0.62 * math.cos(a), y, 0.1 + 0.62 * math.sin(a)), squash=(1, 0.6, 1),
                                segments=8, rings=4))
    if d["clasp"]:
        parts.append(p.flat("Strap", [(w / 2 - 0.55, 0.13), (w / 2 + 0.05, 0.13), (w / 2 + 0.05, -0.13),
                                      (w / 2 - 0.55, -0.13)], 0.04, "liner", y=y, bevel=0.0))
        parts.append(bl.place(bl.box("Wrap", (0.08, T + 0.06, 0.26), mat("liner")), (w / 2 + 0.06, 0, 0)))
        if d["clasp"] == "lock":
            parts.append(p.flat("Lock", rounded(0.36, 0.44, 0.06), 0.06, trim, y=y - 0.02))
            parts[-1].data.transform(Matrix.Translation((w / 2 - 0.3, 0, 0)))
        else:
            parts.append(p.flat("Buckle", rounded(0.22, 0.34, 0.05), 0.05, metal, y=y - 0.02))
            parts[-1].data.transform(Matrix.Translation((w / 2 - 0.42, 0, 0)))
    if d["cord"]:
        for z in (-0.5, 0.45):
            loop = bl.torus("Cord", 1.0, 0.045, 40, 6, mat("cord"))
            parts.append(bl.smooth_by_angle(bl.place(loop, (0.05, 0, z), (0, 0, 0), ((w + 0.05) / 2, (T + 0.08) / 2, 1)), 40.0))
    if d["bolts"]:
        for x, z in ((-0.6, 1.0), (0.75, 1.0), (-0.6, -1.0), (0.75, -1.0), (0.75, 0.0)):
            parts.append(p.ball("Bolt", 0.07, "iron", (x, y, z), squash=(1, 0.6, 1), segments=6, rings=4))

    orn, at = d["orn"], (0.0, y - 0.03, 0.1)
    if orn in ("Embers", "Hoarfrost"):
        parts.append(p.flat("Ornament", p.set_ornament(orn, 1.15, (at[0], at[2])), 0.04, trim, y=y - 0.01))
    elif orn == "Gales":
        parts.append(p.flat("Vane", p.shifted(p.VANE, -0.05, 0.05, 0.95, 0.95), 0.04, trim, y=y - 0.01))
    elif orn == "Stormcall":
        for sx in (-1, 1):
            for sz in (-1, 1):
                root = (sx * (w / 2 - 0.15), sz * (H / 2 - 0.15))
                parts.append(p.curl(root, sx, 0.8, trim, y=y - 0.02, turn=11.0 if sz > 0 else 101.0, r=0.075))
    elif orn == "Gloamforge":
        for x in (-0.42, 0.52):     # two pairs of prongs in a row along the top: a crown, never a pair of ears
            parts.append(p.flat("Crest", p.set_ornament(orn, 0.62, (x, H / 2 - 0.1)), 0.1, trim, y=0.0))
    elif orn == "Nightloom":
        parts.append(p.flat("Shuttle", p.shifted(p.SHUTTLE, 0.0, 0.1, 2.5, 1.7), 0.06, trim, y=y - 0.02))
        for z in (0.55, -0.35):
            loop = bl.torus("Thread", 1.0, 0.03, 40, 6, mat(trim))
            parts.append(bl.smooth_by_angle(bl.place(loop, (0.05, 0, z), (0, 0, 0), ((w + 0.06) / 2, (T + 0.1) / 2, 1)), 40.0))
    parts += p.stone_of(d, 1.0, at)
    return parts


def legend(d):
    """The Legendaries' new forms, beside the closed book."""
    trim, parts, form, y = d["trim"], [], d["form"], FRONT - 0.04
    if form == "dial":
        parts.append(p.facing("Dial", 1.3, 0.07, trim, (0, y, 0.1)))
        parts.append(p.facing("Dial", 0.95, 0.04, d["key"], (0, y, 0.1)))
        parts.append(p.facing("Rete", 0.55, 0.035, trim, (0.18, y - 0.02, 0.28)))
        for a in range(0, 360, 30):
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            parts.append(p.tube("Tick", [(0.95 * ca, y, 0.1 + 0.95 * sa), (1.3 * ca, y, 0.1 + 1.3 * sa)], 0.025, trim,
                                sides=6))
        parts.append(p.flat("Needle", [(-1.75, 0.0), (0.0, 0.07), (1.75, 0.0), (0.0, -0.07)], 0.04, "lit",
                            y=y - 0.05, bevel=0.0))
        parts[-1].data.transform(Matrix.Translation((0, 0, 0.1)) @ Matrix.Rotation(math.radians(-35), 4, "Y"))
        for x, z in ((0.5, 0.75), (-0.62, 0.38), (0.3, -0.5), (-0.25, 0.9), (0.7, -0.05)):
            parts.append(p.ball("Star", 0.06, "lit", (x, y - 0.03, z), segments=8, rings=4))
    elif form == "ribbons":
        # three broad markers out of the head of the pages, sweeping out past the fore-edge to one side and fanned,
        # each forked at its end with a lozenge stone on its open length: never at the book's foot, never a drop
        hw, fork, yr = 0.14, 0.32, y - 0.08      # laid over the cover's front, pale on the dark leather
        for i in range(3):
            pts = [(0.05 + 0.32 * i, yr, H / 2 + 0.02), (W / 2 - 0.1 + 0.05 * i, yr, H / 2 + 0.5 - 0.26 * i),
                   (W / 2 + 0.75, yr, H / 2 + 0.32 - 0.66 * i), (W / 2 + 1.3, yr, H / 2 - 0.05 - 1.0 * i)]
            path = p.curve(pts, 18)
            left, right = [], []
            for k, (x, _, z) in enumerate(path):
                a, b = path[max(k - 1, 0)], path[min(k + 1, len(path) - 1)]
                dx, dz = b[0] - a[0], b[2] - a[2]
                ln = math.hypot(dx, dz)
                nx, nz = -dz / ln, dx / ln
                left.append((x + nx * hw, z + nz * hw))
                right.append((x - nx * hw, z - nz * hw))
            ux, uz = -nz, nx                       # the ribbon's way at its end
            ex, ez = path[-1][0], path[-1][2]
            tips = [(left[-1][0] + ux * fork, left[-1][1] + uz * fork), (ex, ez),
                    (right[-1][0] + ux * fork, right[-1][1] + uz * fork)]
            parts.append(p.flat("Ribbon", left + tips + list(reversed(right)), 0.02, trim, y=yr, bevel=0.0))
            sx, _, sz = path[9]
            parts.append(p.flat("Setting", [(sx, sz + 0.27), (sx + 0.16, sz), (sx, sz - 0.27), (sx - 0.16, sz)], 0.03,
                                d["key"], y=yr - 0.03, bevel=0.0))
            parts.append(p.flat("Stone", [(sx, sz + 0.2), (sx + 0.1, sz), (sx, sz - 0.2), (sx - 0.1, sz)], 0.05, "lit",
                                y=yr - 0.07, bevel=0.015))
    return parts


def opened(d):
    """Yamiyo: the book lying open, its two halves spread on the spine and its pages fanned between them."""
    parts, half = [], W - 0.1
    spread = 28.0        # each cover lifted this far from lying flat
    for side in (-1, 1):
        cover = p.flat("Cover", p.shifted(rounded(half, H, 0.1), side * half / 2, 0.0), C, d["cover"], y=0.0, bevel=0.03)
        block = bl.place(bl.box("Pages", (half - 0.1, 0.24, H - 0.16), mat(d["pages"])), (side * (half / 2 - 0.02), -0.18, 0))
        for obj in (cover, block):
            obj.data.transform(Matrix.Rotation(math.radians(-side * spread), 4, "Z"))
            parts.append(obj)
        for lift in ((44.0, 60.0, 76.0) if side < 0 else (46.0, 66.0)):    # leaves turning, fanned between the covers
            leaf = bl.place(bl.box("Leaf", (half - 0.2, 0.025, H - 0.3), mat(d["pages"])), (side * (half / 2 - 0.02), -0.3, 0))
            leaf.data.transform(Matrix.Rotation(math.radians(-side * lift), 4, "Z"))
            parts.append(leaf)
    spine = bl.cylinder("Spine", 0.2, H, segments=16, material=mat(d["cover"]))
    parts.append(bl.smooth_by_angle(bl.place(spine, (0, 0.12, 0)), 40.0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            cap = p.flat("Corner", [(sx * half, sz * H / 2), (sx * (half - 0.55), sz * H / 2), (sx * half, sz * (H / 2 - 0.55))],
                         0.16, d["key"], bevel=0.012)
            cap.data.transform(Matrix.Rotation(math.radians(-sx * spread), 4, "Z"))
            parts.append(cap)
    parts += p.stone("lit", 0.26, (0, -0.1, H / 2 + 0.22), d["trim"])
    return parts


def tome(d):
    if d["form"] == "open":
        return opened(d)
    return body(d) + fittings(d) + legend(d)


def build(d):
    tilt, spin = (-42.0, 12.0) if d["form"] == "open" else (TILT, SPIN)
    return p.scene_of(lambda: tome(d), tilt, spin)


WORDS = dict(
    file="gear_tome_sets.png",
    title="Grow your Anime: the Tome in three designs at each rarity, in grey (AR6, batch 3)",
    lead="The Mage's off hand: a heavy, thick, dark book standing closed, turned so its spine and its pages' top edge "
         "show. A design is its fittings, its clasp and what its cover carries.",
    notes=(
        "A set keeps its word and its ornament on every kind: Embers swells round its stone, Hoarfrost is cut square, Gales "
        "sweeps back, Stormcall curls out, Gloamforge stands in prongs, Nightloom lies in a shuttle. The near word is "
        "Grimoire.",
        "Each Legendary's one new form: Yamiyo (a dark night), open with its pages fanned; Seiza (a constellation), a star "
        "chart's dial wider than the book; Rinkou (a pale glow), three forked ribbon markers sweeping out of its head, a cut stone on each.",
        "No flame and no cloud anywhere: a light is a stone or a line.",
        "For the verdict: does each read as a tome, heavy and dark beside the Codex, and apart from its two neighbours, "
        "at 38 points? Does each Legendary outrank every Epic by shape? Not here yet: colour, frames, the class mark.",
    ),
)

if __name__ == "__main__":
    p.main(__import__(__name__))
