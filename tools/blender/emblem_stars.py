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

    blender -b --factory-startup --python tools/blender/emblem_stars.py -- <abs out> [cut]

Writes emblem_stars.png. Nothing is exported.

With `cut`, the twelve sets on B (research's pick and sets, AR43, 13:12; Moonward's half-lit moon, 13:36): each set's
white symbol drawn in code from shapes (SYMBOLS), one bold mark, no letters, on its rarity's star. Into
build/handoff/UI/emblems: images/Emblem<Set>.png (64 points at 4 pixels a point, transparent, never tinted),
emblems.json, and emblems_cut.png, the check sheet: each symbol alone, on its star, in the bag's cell at 44 points, and
each image at 64 px.
"""

import json
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


SETS = {
    "Uncommon": ("Talon", "Spearhead", "Palisade"),
    "Rare": ("Tidebreak", "Warhorn", "Compass"),
    "Epic": ("SerpentCoil", "SwornRings", "Moonward"),
    "Legendary": ("Zenith", "Highcrown", "Radiance"),
}
SAID = {"SerpentCoil": "Serpent Coil", "SwornRings": "Sworn Rings"}
SYMBOL = 0.43       # a symbol's unit, as a share of the star's R: the symbols are drawn within about +-0.9 of it


def taper(t, a, b, wa, wb):
    """A stroke from a to b, its half width wa at a easing to wb at b, as a distance."""
    ex, ey, px, py = b[0] - a[0], b[1] - a[1], t.x - a[0], t.y - a[1]
    h = np.clip((px * ex + py * ey) / max(ex * ex + ey * ey, 1e-9), 0, 1)
    return np.hypot(px - ex * h, py - ey * h) - (wa + (wb - wa) * h)


def path(t, pts, widths):
    """A stroke along a polyline, its half width eased point to point."""
    return np.minimum.reduce([taper(t, a, b, wa, wb) for a, b, wa, wb in zip(pts, pts[1:], widths, widths[1:])])


def bezier(p0, p1, p2, p3, n=24):
    u = np.linspace(0, 1, n)[:, None]
    p = (1 - u) ** 3 * np.array(p0) + 3 * (1 - u) ** 2 * u * np.array(p1) + 3 * (1 - u) * u ** 2 * np.array(p2) + u ** 3 * np.array(p3)
    return [tuple(q) for q in p]


def symbol(t, key, cx, cy, S):
    """A set's white symbol, as a distance (negative inside): drawn in a unit of S, x right and y down from its middle.
    Each is one bold shape, read at 44 points; the dark cuts inside a shape are returned apart, as `cuts` (a distance
    painted dark over the white)."""
    P = lambda x, y: (cx + x * S, cy + y * S)  # noqa: E731
    r = np.hypot(t.x - cx, t.y - cy)
    ang = np.arctan2(t.y - cy, t.x - cx)
    big = np.full(t.x.shape, 1e6, np.float32)
    cuts = big
    if key == "Talon":                      # three parallel claw strokes, slanting down to the left, sharp at both ends
        d = big
        for k, dx in enumerate((-0.42, 0.0, 0.42)):
            line = bezier(P(dx + 0.36, -0.78), P(dx + 0.24, -0.3), P(dx - 0.06, 0.24), P(dx - 0.36, 0.78), 16)
            wide = [S * 0.15 * np.sin(np.pi * (0.08 + 0.84 * i / 15)) ** 0.8 for i in range(16)]
            d = np.minimum(d, path(t, line, wide))
    elif key == "Spearhead":                # a leaf blade pointing up, its collar, the socket's stub
        d = np.minimum.reduce([t.poly([P(0, -0.92), P(0.2, -0.62), P(0.4, -0.12), P(0.34, 0.12), P(0.14, 0.3),
                                       P(-0.14, 0.3), P(-0.34, 0.12), P(-0.4, -0.12), P(-0.2, -0.62)]),
                               t.poly([P(-0.24, 0.4), P(0.24, 0.4), P(0.24, 0.54), P(-0.24, 0.54)]),
                               t.poly([P(-0.13, 0.62), P(0.13, 0.62), P(0.1, 0.9), P(-0.1, 0.9)])])
        cuts = taper(t, P(0, -0.66), P(0, 0.18), S * 0.02, S * 0.045)
    elif key == "Palisade":                 # three stakes, the middle tallest, each pointed, bound by one lashing
        d = big
        for dx, top in ((-0.44, -0.6), (0.0, -0.86), (0.44, -0.6)):
            d = np.minimum(d, t.poly([P(dx - 0.16, 0.82), P(dx - 0.16, top + 0.26), P(dx, top), P(dx + 0.16, top + 0.26),
                                      P(dx + 0.16, 0.82)]))
        cuts = np.maximum(np.abs(t.y - (cy + 0.3 * S)) - S * 0.035, d)
    elif key == "Tidebreak":                # one wave breaking left: a long low back, a high crest, a lip of foam
        # Research's must-fix (14:12): the first curl closed into a "2" over its flat sea. Now the wave has its own
        # profile: its back slopes long and low to a point on the right, its crest stands high on the left, and its lip
        # breaks into two fingers of foam over a hollow left open below. The foot swells and runs out to points, never
        # a base line. Spray flies back off the crest; one line of foam follows the lip.
        d = t.poly(bezier(P(-0.34, 0.64), P(0.0, 0.5), P(0.42, 0.72), P(0.98, 0.5), 12)          # the swell
                   + bezier(P(0.98, 0.5), P(0.6, 0.3), P(0.26, -0.62), P(-0.2, -0.74), 14)[1:]   # the back
                   + bezier(P(-0.2, -0.74), P(-0.62, -0.84), P(-0.94, -0.46), P(-0.84, -0.02), 12)[1:]  # the lip
                   + [P(-0.72, -0.2), P(-0.6, -0.04)]                                           # its foam
                   + bezier(P(-0.52, -0.28), P(-0.42, -0.44), P(-0.26, -0.44), P(-0.14, -0.32), 6)  # under it
                   + bezier(P(-0.14, -0.32), P(-0.02, -0.14), P(0.0, 0.3), P(-0.34, 0.64), 10)[1:-1])  # the face
        for x, y, rr in ((0.16, -0.8, 0.1), (0.4, -0.66, 0.085), (0.58, -0.46, 0.07)):
            d = np.minimum(d, np.hypot(t.x - (cx + x * S), t.y - (cy + y * S)) - rr * S)
        cuts = path(t, bezier(P(-0.04, -0.58), P(-0.36, -0.68), P(-0.62, -0.5), P(-0.66, -0.26), 10),
                    [S * w for w in np.linspace(0.012, 0.042, 10)])
    elif key == "Warhorn":                  # a horn: a bone mouthpiece, a gentle bend down and left to a flared bell
        line = bezier(P(0.76, -0.7), P(0.62, -0.14), P(0.16, 0.26), P(-0.36, 0.3), 20)
        wide = [S * (0.1 + 0.2 * (i / 19) ** 1.1) for i in range(20)]
        bell = (np.hypot((t.x - (cx - 0.52 * S)) / 0.17, (t.y - (cy + 0.3 * S)) / 0.48) / S - 1.0) * S * 0.17
        d = np.minimum.reduce([path(t, line, wide), bell, np.hypot(t.x - (cx + 0.78 * S), t.y - (cy - 0.74 * S)) - S * 0.12])
        mouth = (np.hypot((t.x - (cx - 0.57 * S)) / 0.08, (t.y - (cy + 0.3 * S)) / 0.35) / S - 1.0) * S * 0.08
        bands = []
        for u in (0.42, 0.68):                              # two bands round the horn, across its line
            k = round(u * 19)
            (x0, y0), (x1, y1) = line[k - 1], line[k + 1]
            nx, ny = -(y1 - y0), x1 - x0
            n = np.hypot(nx, ny)
            mx, my, half = line[k][0], line[k][1], wide[k] + S * 0.06
            bands.append(taper(t, (mx - nx / n * half, my - ny / n * half), (mx + nx / n * half, my + ny / n * half),
                               S * 0.03, S * 0.03))
        cuts = np.minimum(mouth, np.maximum(np.minimum.reduce(bands), d))
    elif key == "Compass":                  # a compass rose: four long points, four short between, a dark heart
        long_ = np.minimum.reduce([t.poly([P(0, 0), P(0.17 * np.cos(a + 0.785), 0.17 * np.sin(a + 0.785)),
                                           P(0.92 * np.cos(a), 0.92 * np.sin(a)),
                                           P(0.17 * np.cos(a - 0.785), 0.17 * np.sin(a - 0.785))])
                                   for a in np.arange(4) * np.pi / 2])
        short = np.minimum.reduce([t.poly([P(0, 0), P(0.14 * np.cos(a + 0.785), 0.14 * np.sin(a + 0.785)),
                                           P(0.52 * np.cos(a), 0.52 * np.sin(a)),
                                           P(0.14 * np.cos(a - 0.785), 0.14 * np.sin(a - 0.785))])
                                   for a in np.arange(4) * np.pi / 2 + np.pi / 4])
        d = np.minimum(long_, short)
        cuts = r - S * 0.09
    elif key == "SerpentCoil":              # a serpent in an S, leaning: its wedge head at the top right, the tail a point
        lean = 0.55
        Q = lambda x, y: P(x * np.cos(lean) - y * np.sin(lean), x * np.sin(lean) + y * np.cos(lean))  # noqa: E731
        line = (bezier(Q(0.2, -0.6), Q(-0.1, -0.84), Q(-0.56, -0.62), Q(-0.42, -0.24), 12)
                + bezier(Q(-0.42, -0.24), Q(-0.3, 0.04), Q(0.42, -0.04), Q(0.44, 0.32), 12)[1:]
                + bezier(Q(0.44, 0.32), Q(0.46, 0.72), Q(-0.1, 0.9), Q(-0.6, 0.66), 12)[1:])
        n = len(line)
        wide = [S * (0.19 - 0.15 * (i / (n - 1)) ** 1.6) for i in range(n)]
        head = t.poly([Q(0.06, -0.66), Q(0.3, -0.86), Q(0.7, -0.84), Q(0.86, -0.62), Q(0.6, -0.42), Q(0.12, -0.44)])
        d = np.minimum(path(t, line, wide), head)
        eye = Q(0.5, -0.68)
        cuts = np.hypot(t.x - eye[0], t.y - eye[1]) - S * 0.065
    elif key == "SwornRings":               # two rings linked side by side, each passing over the other once
        ca, cb, rr, w, g = P(-0.3, 0), P(0.3, 0), S * 0.46, S * 0.12, S * 0.08
        A = np.abs(np.hypot(t.x - ca[0], t.y - ca[1]) - rr) - w
        B = np.abs(np.hypot(t.x - cb[0], t.y - cb[1]) - rr) - w
        d = np.minimum(A, B)                    # B passes over A at the top, A over B at the foot: a gap cut beside each
        cuts = np.minimum(np.maximum.reduce([B - g, -B, A, t.y - cy]), np.maximum.reduce([A - g, -A, B, cy - t.y]))
    elif key == "Moonward":                 # a half-lit moon: the lit half a solid half disc, the dark half its ring line
        R0 = S * 0.74
        ring = np.abs(r - R0) - S * 0.07
        lit = np.maximum(r - R0, t.x - cx)
        d = np.minimum(ring, lit)
        cuts = np.minimum.reduce([np.hypot(t.x - (cx + x * S), t.y - (cy + y * S)) - c * S     # its craters
                                  for x, y, c in ((-0.38, -0.3, 0.13), (-0.24, 0.3, 0.09), (-0.56, 0.12, 0.07))])
    elif key == "Zenith":                   # a ring with a dot at its heart
        d = np.minimum(np.abs(r - S * 0.62) - S * 0.13, r - S * 0.22)
    elif key == "Highcrown":                # a crown of three points on its band
        d = t.poly([P(-0.74, 0.62), P(-0.74, 0.3), P(-0.86, -0.56), P(-0.34, -0.02), P(0, -0.86), P(0.34, -0.02),
                    P(0.86, -0.56), P(0.74, 0.3), P(0.74, 0.62)])
        cuts = np.maximum(np.abs(t.y - (cy + 0.3 * S)) - S * 0.035, d)
    elif key == "Radiance":                 # a sunburst: a disc, eight short rays apart from it
        rays = np.minimum.reduce([t.poly([P(0.44 * np.cos(a - 0.17), 0.44 * np.sin(a - 0.17)),
                                          P(0.9 * np.cos(a), 0.9 * np.sin(a)),
                                          P(0.44 * np.cos(a + 0.17), 0.44 * np.sin(a + 0.17))])
                                  for a in np.arange(8) * np.pi / 4 - np.pi / 2])
        d = np.minimum(r - S * 0.32, rays)
    else:
        raise KeyError(key)
    return d, cuts


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
    t.line(body, max(1.2, R * 0.025), C("#000000"), 0.85)
    if mark_kind in MARKS:
        g = mark(t, mark_kind, cx, cy + R * 0.04, R * d["mark"])
        t.paint(g - 1.6, C("#05040A"), 0.9)
        t.paint(g, C("#FFFFFF"))
        return
    white(t, mark_kind, cx, cy + R * 0.04, R * SYMBOL)


def white(t, key, cx, cy, S):
    """A set's symbol as it sits on the star: a dark rim so it reads over the colour and the rock alike, then the white,
    then its dark cuts."""
    C = ui.c
    g, cuts = symbol(t, key, cx, cy, S)
    t.glow(g, S * 0.14, C("#05040A"), 0.55)
    t.paint(g - S * 0.07, C("#05040A"), 0.92)
    t.paint(g, C("#FFFFFF"))
    t.paint(cuts, C("#05040A"), 0.92)


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


HANDOFF = Path(__file__).resolve().parents[2] / "build" / "handoff" / "UI" / "emblems"
IMAGE = 64.0                                    # an emblem's image, in points (4 pixels a point)
CENTRE, RADIUS = 0.53, 0.44                     # the star's middle and its R, as shares of the image
IN_CELL = 40.0                                  # the image's size in the bag's 44 point cell: its star the cell's 0.4


def emblem(rarity, key):
    """One set's emblem image: star B in its rarity, the set's symbol on it, on a clear ground, 4 pixels a point."""
    ui.K = 4
    sheet = ui.Sheet(IMAGE, IMAGE, "#000000")
    sheet.px[:] = 0
    star(sheet.tile(0, 0, IMAGE, IMAGE), DIRS["B"], IMAGE / 2, IMAGE * CENTRE, IMAGE * RADIUS, rarity, key)
    return sheet.px.copy()


def cut(out):
    """The twelve emblems for Faber, and their check sheet."""
    made = {(r, key): emblem(r, key) for r in RARITIES for key in SETS[r]}
    (HANDOFF / "images").mkdir(parents=True, exist_ok=True)
    for (r, key), px in made.items():
        rs.save(px, HANDOFF / "images" / f"Emblem{key}.png")
    (HANDOFF / "emblems.json").write_text(json.dumps(dict(
        what="AR43, War Emblems: the twelve sets' emblems on star B, each its rarity's colour over the black rock with "
             "its set's white symbol (research's sets, 13:12; Moonward a half-lit moon, 13:36). Drawn in code by "
             "tools/blender/emblem_stars.py (cut); no image input",
        pixelsPerPoint=4, points=[IMAGE, IMAGE], pixels=[round(IMAGE * 4)] * 2,
        use="an ImageLabel, never tinted, ImageTransparency 0, its colour in the picture; transparent round the star. "
            f"The star's middle at ({IMAGE / 2:g}, {IMAGE * CENTRE:g}) points, its R {IMAGE * RADIUS:g}",
        inCell=f"in the bag's 44 point cell (AR18: its well, its rarity's tint and rim), the image {IN_CELL:g} points "
               f"square, its top left at (2, 2), so the star is the cell's 0.4 as drawn in emblems_cut.png",
        emblems=[dict(image=f"Emblem{key}", set=SAID.get(key, key), rarity=r, colour=LIT[r])
                 for r in RARITIES for key in SETS[r]],
    ), indent=2) + "\n")

    ui.K = K
    alone, big, csz, small = 80.0, 96.0, 44.0, IMAGE / 2
    block = alone + 8 + big + 8 + csz + 8 + small + 20
    width, row_h = 16 + 3 * block + 4, 24 + big + 12
    height = 76 + 4 * row_h + 34
    sheet = ui.Sheet(width, height, "#101117")
    ink, soft = "#EDE6D6", "#B4AC9C"
    head = sheet.tile(0, 0, width, 72)
    head.text(16, 16, 20, "AR43, War Emblems: the twelve sets on star B, cut for Faber, for the content check", ink,
              bold=0.2)
    head.text(16, 46, 13, "Each set: its symbol alone; the emblem as uploaded (64 points, drawn at 96); in the bag's cell "
                          "at 44 points; the image at 64 px.", soft)
    pastes = []
    for row, r in enumerate(RARITIES):
        y = 76 + row * row_h
        for k, key in enumerate(SETS[r]):
            x = 16 + k * block
            sheet.tile(x, y, block, 22).text(0, 2, 14, f"{SAID.get(key, key)}  ·  {r}", ink)
            t = sheet.tile(x, y + 24, block - 12, big)
            t.paint(t.poly(ui.cut_box(0, (big - alone) / 2, alone, (big + alone) / 2, 8, 0, 8, 0)), ui.c("#1A1C24"))
            white(t, key, alone / 2, big / 2, alone * 0.4)
            cell(t, alone + 8 + big + 8, (big - csz) / 2, csz, r, DIRS["B"], key)
            pastes.append((made[(r, key)], 0.5 * big / IMAGE, x + alone + 8, y + 24))
            pastes.append((made[(r, key)], (small / IMAGE) * 0.5, x + alone + 8 + big + 8 + csz + 8,
                           y + 24 + (big - small) / 2))
    sheet.tile(16, height - 30, width, 24).text(0, 0, 13, "Star B lit from the upper left, facet by facet; the symbols "
                                                          "white with a dark rim, read over the colour and the rock alike.",
                                                soft)
    for got in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        ui.over(sheet.px, got[..., :3], got[..., 3])
    for px, scale, x, y in pastes:
        rs.paste(sheet.px, rs.shrink(px, scale), round(x * K), round(y * K))
    rs.save(sheet.px, HANDOFF / "emblems_cut.png")
    print(f"cut: {len(made)} emblems, {round(IMAGE * 4)} px, into {HANDOFF}")


if __name__ == "__main__":
    rest = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    {"cut": cut}.get(rest[1] if len(rest) > 1 else None, main)(bl.out_dir())
