"""AR43 (War Emblems): the star's blockout, three directions for research's pick, drawn flat in code. The shipped
emblem icons are rejected (the director, 2026-11-19, 02:58 to 03:10); this is the new look before any render.

The director's words (docs/decisions.md, the 02:58 and 03:13 rows): "The design is a black start rockish with the main
above part being a color of the rarity in question with in the middle a white mark the symbol will be the symbol of a
sets". Four rarities at launch, Uncommon (green), Rare (blue), Epic and Legendary; three sets a rarity, each its symbol.

The directions (one axis each: the star's points, its finish, how the colour meets the rock):
    A  the cut star     five points, crisp facets like worked obsidian; the colour above a straight line, a seam of
                        light where they meet.
    B  the rough star   five stubby points, chipped and uneven like a stone struck from a cliff; the colour above a
                        jagged break, glowing a little like ore.
    C  the four-point   four points, the top and foot long, faceted; the colour on the upper half, the arms' upper
                        faces.
Each is lit from the upper left, facet by facet (each facet a triangle from the raised middle to the outline). The
white mark is a stand-in for a set's symbol (three slashes, a spiral, twin fangs, a ring). The bag's cell is AR18's (its
rarity's tint and rim), at 44 points, then that cell at one pixel a point (harsher than any phone).

    blender -b --factory-startup --python tools/blender/emblem_stars.py -- <abs out>

Writes emblem_stars.png. Nothing is exported.
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402

K = 2
RARITIES = ("Uncommon", "Rare", "Epic", "Legendary")
LIT = {r: up.RIM[r] for r in RARITIES}                       # the bag's rims: the rarity's own colour
DEEP = {"Uncommon": "#145A34", "Rare": "#163F7A", "Epic": "#4E2380", "Legendary": "#7A4E0E"}
ROCK = ("#060509", "#2B2834", "#615B70")                     # in shadow, turned half to the light, facing it
LIGHT = np.array([-0.45, -0.75, 0.55]) / np.linalg.norm([-0.45, -0.75, 0.55])   # x right, y down, z to the eye
MARKS = ("slashes", "spiral", "fangs", "ring")    # stand-ins; never a crescent or a cross on a star (content check, 13:08)

DIRS = {
    "A": dict(name="The cut star", points=5, inner=0.44, tall=(1.0, 1.0), rough=0.0, split="line", at=-0.06, mark=0.46,
              said="five points, crisp facets like worked obsidian; the colour above a straight line, a seam of light"),
    "B": dict(name="The rough star", points=5, inner=0.58, tall=(1.0, 1.0), rough=1.0, split="jagged", at=-0.02,
              mark=0.48, said="five stubby points, chipped like a struck stone; the colour above a jagged break, as ore"),
    "C": dict(name="The four-point", points=4, inner=0.34, tall=(1.0, 0.72), rough=0.0, split="line", at=0.0, mark=0.36,
              said="four points, the top and foot long, faceted; the colour on its upper half"),
}


def outline(d, cx, cy, R, seed=3):
    """The star's corners, tips and inner corners in turn from the top tip, clockwise (a rough one's jittered), and
    its outline: the corners, or a rough one's with chips bitten from each edge. The facets run to the corners, so a
    rough star keeps big planes and only its edge is broken."""
    n, rng = d["points"], np.random.default_rng(seed)
    pts = []
    for k in range(2 * n):
        a = -np.pi / 2 + k * np.pi / n
        if k % 2 == 0:
            r = R * (d["tall"][0] if (k in (0, 4) if n == 4 else True) else d["tall"][1])
        else:
            r = R * d["inner"]
        if d["rough"]:
            r *= 1 + rng.uniform(-0.07, 0.05) * d["rough"]
            a += rng.uniform(-0.06, 0.06) * d["rough"]
        pts.append((cx + r * np.cos(a), cy + r * np.sin(a)))
    if not d["rough"]:
        return pts, pts
    chipped = []
    for k, p in enumerate(pts):                                 # chips bitten inward from each edge
        q = pts[(k + 1) % len(pts)]
        chipped.append(p)
        for f in (0.3, 0.6):
            mx, my = p[0] + (q[0] - p[0]) * f, p[1] + (q[1] - p[1]) * f
            bite = rng.uniform(0.86, 0.99)
            chipped.append((cx + (mx - cx) * bite, cy + (my - cy) * bite))
    return pts, chipped


def shade(a, b, c):
    """How a flat facet through three raised points faces the light, 0 to 1."""
    n = np.cross(np.subtract(b, a), np.subtract(c, a))
    n = n / np.linalg.norm(n)
    if n[2] < 0:
        n = -n
    return float(np.clip(n @ LIGHT, 0, 1))


def ramp(lo, mid, hi, v):
    v = float(np.clip(v, 0, 1))
    a, b, f = (lo, mid, v / 0.5) if v < 0.5 else (mid, hi, (v - 0.5) / 0.5)
    a, b = (ui.c(x) if isinstance(x, str) else np.asarray(x, np.float32) for x in (a, b))
    return tuple(a + (b - a) * f)


def above(t, d, cx, cy, R):
    """The colour's region as a distance: negative above its line, or above a jagged break."""
    y = cy + d["at"] * R
    if d["split"] == "line":
        return t.y - y
    rng = np.random.default_rng(11)
    xs = np.linspace(cx - 1.3 * R, cx + 1.3 * R, 9)
    ys = [y + rng.uniform(-0.12, 0.12) * R * (1 if k % 2 else -1) for k in range(len(xs))]
    return t.poly([(cx - 1.4 * R, cy - 1.5 * R), (cx + 1.4 * R, cy - 1.5 * R), (xs[-1], ys[-1])]
                  + list(zip(xs[::-1], ys[::-1]))[1:] + [(cx - 1.4 * R, ys[0])])


def mark(t, kind, cx, cy, s):
    """A set's stand-in symbol, white, as a distance."""
    r = np.hypot(t.x - cx, t.y - cy)
    if kind == "slashes":
        return np.minimum.reduce([t.poly([(cx + s * (0.36 + k * 0.24), cy - s * 0.46), (cx + s * (0.3 + k * 0.24), cy - s * 0.46),
                                          (cx + s * (-0.3 + k * 0.24), cy + s * 0.46)]) - s * 0.035 for k in (-1, 0, 1)])
    if kind == "ring":
        return np.abs(r - s * 0.3) - s * 0.09
    if kind == "spiral":
        turns = np.linspace(0, 2.6 * np.pi, 48)
        rad = lambda u: s * (0.04 + 0.42 * u / (2.6 * np.pi))  # noqa: E731
        pts = [(cx + rad(u) * np.cos(u), cy + rad(u) * np.sin(u)) for u in turns]
        return np.minimum.reduce([ui.sd_segment(t.x, t.y, a, b) for a, b in zip(pts, pts[1:])]) - s * 0.085
    fang = lambda side: t.poly([(cx + side * s * 0.1, cy - s * 0.48), (cx + side * s * 0.42, cy - s * 0.36),  # noqa: E731
                                (cx + side * s * 0.16, cy + s * 0.5), (cx + side * s * 0.04, cy + s * 0.05)])
    return np.minimum(fang(-1), fang(1))


def star(t, d, cx, cy, R, rarity, mark_kind):
    C, lit = ui.c, ui.c(LIT[rarity])
    pts, edge = outline(d, cx, cy, R)
    body = t.poly(edge)
    t.glow(body, R * 0.12, C("#000000"), 0.6)
    colour = above(t, d, cx, cy, R)
    if d["split"] == "jagged":
        t.glow(np.maximum(body, colour), R * 0.12, lit, 0.18)
    top = (cx, cy, R * 0.55)                                    # the raised middle
    pale = lit * 0.55 + 0.45                                    # the lit face stays its colour, never white
    for k, p in enumerate(pts):
        q = pts[(k + 1) % len(pts)]
        zp = 0.0 if np.hypot(p[0] - cx, p[1] - cy) > R * (d["inner"] + 0.15) else R * 0.08
        zq = 0.0 if np.hypot(q[0] - cx, q[1] - cy) > R * (d["inner"] + 0.15) else R * 0.08
        v = shade(top, (p[0], p[1], zp), (q[0], q[1], zq))
        tri = np.maximum(t.poly([(cx, cy), p, q]), body)
        t.paint(tri, ramp(*ROCK, v))
        t.paint(np.maximum(tri, colour), ramp(DEEP[rarity], lit, pale, 0.2 + 0.8 * v))
    if d["rough"]:                                              # two cracks in the rock below the break
        for a, b in (((-0.08, 0.1), (-0.3, 0.55)), ((0.12, 0.18), (0.36, 0.42))):
            t.stroke([(cx + a[0] * R, cy + a[1] * R), (cx + b[0] * R, cy + b[1] * R)], 0.8, C("#8A8399"), 0.35)
    for p in pts[::2]:                                          # the ridges, from the middle to each tip
        t.stroke([(cx, cy), p], 0.9, C("#FFFFFF"), 0.16)
    if d["split"] == "line":
        seam = np.maximum(body, np.abs(colour) - 0.6)
        t.paint(seam, lit, 0.9)
        t.glow(seam, 2.5, lit, 0.5)
    else:
        t.paint(np.maximum(body, np.abs(colour) - 0.5), C("#000000"), 0.6)
    t.line(body, 1.2, C("#000000"), 0.85)
    g = mark(t, mark_kind, cx, cy + R * 0.04, R * d["mark"])
    t.paint(g - 1.6, C("#05040A"), 0.9)
    t.paint(g, C("#FFFFFF"))


def cell(t, x, y, s, rarity, d, mark_kind):
    """AR18's bag cell: its well, its rarity's tint and light and rim; the star at 0.4 of it."""
    lit = ui.c(LIT[rarity])
    box = t.poly(ui.cut_box(x, y, x + s, y + s, s * 0.14, 0, s * 0.14, 0))
    t.paint(box, t.ramp("#0B0C10", "#07080B", (t.y - y) / s))
    t.paint(box, lit, 0.14)
    t.paint(box, lit, 0.3 * np.exp(-(((t.x - x - s / 2) / (s * 0.5)) ** 2 + ((t.y - y - s * 0.62) / (s * 0.5)) ** 2)))
    star(t, d, x + s / 2, y + s * 0.53, s * 0.4, rarity, mark_kind)
    t.line(box, 1.5, lit)


def main(out):
    ui.K = K
    big, csz, gap = 128.0, 44.0, 10.0
    width = 16 + 4 * (big + gap) + 24 + 4 * (csz + 6) + 24 + 4 * (csz / 2 + 4) + 16
    row_h = 26 + big + 14
    height = 76 + 3 * row_h + 40
    sheet = ui.Sheet(width, height, "#101117")
    ink, soft = "#EDE6D6", "#B4AC9C"
    head = sheet.tile(0, 0, width, 72)
    head.text(16, 16, 20, "AR43, War Emblems: the black rock star, three directions for research's pick", ink, bold=0.2)
    head.text(16, 46, 13, "Uncommon, Rare, Epic, Legendary: large, in the bag's cell at 44 points, then that cell at one pixel "
                          "a point (a phone shows two or three). White marks stand in for the sets.", soft)
    small = []
    for r, key in enumerate("ABC"):
        d = DIRS[key]
        y = 76 + r * row_h
        sheet.tile(16, y, width, 24).text(0, 2, 15, f"{key}. {d['name']}: {d['said']}", ink)
        t = sheet.tile(0, y + 26, width, big)
        for k, rarity in enumerate(RARITIES):
            star(t, d, 16 + k * (big + gap) + big / 2, big * 0.53, big * 0.42, rarity, MARKS[k])
        x0 = 16 + 4 * (big + gap) + 24
        for k, rarity in enumerate(RARITIES):
            cell(t, x0 + k * (csz + 6), big / 2 - csz / 2, csz, rarity, d, MARKS[k])
        small.append((x0, y + 26 + big / 2 - csz / 2, 4 * (csz + 6), csz))
    sheet.tile(16, height - 34, width, 24).text(0, 0, 13, "Lit from the upper left, facet by facet. Flat in code: the "
                                                          "chosen one is built and rendered next, with the sets' symbols.",
                                                soft)
    for got in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        ui.over(sheet.px, got[..., :3], got[..., 3])
    for x, y, w, h in small:                                    # the cells again at 1 pixel a point
        crop = sheet.px[round(y * K):round((y + h) * K), round(x * K):round((x + w) * K)]
        rs.paste(sheet.px, rs.shrink(crop, 0.5), round((x + w + 18) * K), round((y + h / 4) * K))
    rs.save(sheet.px, out / "emblem_stars.png")


if __name__ == "__main__":
    main(bl.out_dir())
