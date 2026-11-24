"""AR64: the Voidkin's hair, the study's way. Three takes on Rook's and Kirra's heads, beside today's.

The director, 2026-11-24, 21:4x, on the first solid-spike takes: "those hair are still messy do research". The study
(docs/research/hair-read.md) found why ours reads messy and Anime Vanguards' clean: theirs is one mass from one crown
that comes down over the forehead and the sides, its locks wide at the root and touching, apart only at their ends,
each lit on its ridge and dark at its edges; ours sat on top of the head as separate pieces, a bare forehead below,
the scalp showing between them, each lock going its own way. So every take here is that mass, in solid round locks
(`Solid.spike`), and the three differ only in how far the ends leave it (FEEL): A the mass, B spiked, C sleek.

    blender.exe -b --factory-startup --python tools/blender/hair_ways.py -- <out_dir> <who> takes|shade|sheet

`who` is rook or kirra: each gets its own sheet, today's first (rook_make_takes.py's sheet: square on beside two
Anime Vanguards units, the three-quarter front, the game camera, the bust, the phone).
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402


class Solid(am.Hair):
    """Hair of solid locks, round over their tops, with the kit's colours: dark at the root, light toward the tip, one
    band of light round the mass. `edge`: how dark a lock's edges fall, the crevice between two locks."""

    edge = 0.42
    light = 0.0   # how far the whole hair is lifted toward white: a light hair keeps its value in the root's shade

    def colour(self, u, k=1.0):
        c = super().colour(u, k)
        return c + (1 - c) * self.light

    def _shades(self, q, u, k):
        """The colours of one ring: its left edge, ridge, right edge, under its edges, its keel."""
        c, e = self.colour(u, k), self.edge
        return [c * e, self.shine(q, c * 1.12), c * e, c * e * 0.85, c * e * 0.7]

    ARC = (180, 150, 120, 90, 60, 30, 0)

    def spike(self, line, width, depth=0.32, rise=0.42, taper=0.85, k=1.0):
        """A solid lock along `line`, (point, the way out) pairs: `width` across, round over its top (`rise` of that
        out) and keeled under (`depth` of it in), narrowing to a sharp point. Round, so its colour runs from a dark
        edge to a lit ridge and back: two locks side by side meet in a dark crevice, as the genre's do."""
        n, rings, shades = len(line), [], []
        for i, (q, out) in enumerate(line):
            u = i / (n - 1)
            along = (line[min(i + 1, n - 1)][0] - line[max(i - 1, 0)][0]).normalized()
            out = out - along * out.dot(along)
            out = out.normalized() if out.length > 1e-3 else along.orthogonal().normalized()
            side = along.cross(out).normalized()
            v = min(u / 0.15, 1.0)
            s = (1 - u) ** taper * (0.8 + 0.2 * v * v * (3 - 2 * v))     # a cone from its root to a sharp point
            shades.append(self._shades(q, u, k))
            if i == n - 1:
                rings.append([self._vert(q)] * 10)
                continue
            arc = [q + side * (math.cos(math.radians(t)) * width / 2 * s) + out * (math.sin(math.radians(t)) * width * rise * s)
                   for t in self.ARC]
            keel = q - out * (width * depth * s)
            rings.append([self._vert(p) for p in arc] + [self._vert(arc[-1]), self._vert(keel), self._vert(arc[0])])
        strip = len(self.strips)
        self.strips.append(np.clip(np.array(shades, np.float32), 0, 1))
        col = [(180 - t) / 90 for t in self.ARC] + [3, 4, 3]
        pairs = [(m, m + 1) for m in range(6)] + [(7, 8), (8, 9)]
        for j, (lo, hi) in enumerate(zip(rings, rings[1:])):
            for q, m in pairs:
                if j < n - 2:
                    f = self.bm.faces.new((lo[q], hi[q], hi[m], lo[m]))
                    where = [(j, col[q]), (j + 1, col[q]), (j + 1, col[m]), (j, col[m])]
                else:
                    f = self.bm.faces.new((lo[q], hi[0], lo[m]))
                    where = [(j, col[q]), (j + 1, (col[q] + col[m]) / 2), (j, col[m])]
                f.smooth = True
                self.charts.append((f, strip, where))
        self.locks += 1

    def lay(self, a, ph, length, width, heading=0.0, bend=0.0, off=0.06, flick=30.0, hold=0.5, comb=None,
            depth=0.32, rise=0.42, taper=0.85, n=None):
        """A lock rooted on the head, combed and lifted as the kit's clumps are (Hair.spine)."""
        n = n or (7 if length < 0.45 else 9 if length < 0.75 else 11)
        self.spike(self.spine(a, ph, length, heading, bend, comb, hold, flick, off, n), width, depth, rise, taper,
                   1 + self.rng.uniform(-1, 1) * 0.04)

    def free(self, points, width, out=None, depth=0.3, rise=0.4, taper=0.8, n=10):
        """A lock through `points` in space, off the head: a tail's."""
        line = [(Vector(q), (Vector(out) if out is not None else Vector(q) - am.CENTRE).normalized())
                for q in am.smooth2([tuple(q) for q in points], n)]
        self.spike(line, width, depth, rise, taper)

    def ring(self, count, ph, around, length, width, sizes=(1.0, 0.72, 1.12, 0.64, 0.9), jitter=0.2, **kw):  # noqa: E501
        """Locks round the head through the degrees `around`, big, middling and small in turn."""
        a0, a1 = around
        step = (a1 - a0) / count
        first = int(self.rng.integers(0, len(sizes)))
        j = lambda: self.rng.uniform(-1, 1) * jitter  # noqa: E731
        for i in range(count):
            size = sizes[(i + first) % len(sizes)]
            self.lay(a0 + step * (i + 0.5 + j() * 0.6), ph + j() * 8, length * size, width * (0.6 + 0.4 * size), **kw)


# --- the study's way (docs/research/hair-read.md), in three degrees ------------------------------------------------------
# Every take: one crown, every lock running out from it, each wide at its root so the roots overlap and the scalp never
# shows; the fringe down over the forehead to the brow and the sides past the ears, so the head's block reads as hair;
# a lock's edges fall dark and its ridge is lit, so two locks meet in a crevice. They differ only in how far the ends
# leave the mass:
#   A  the mass     the points separate only at their ends
#   B  spiked       the same locks, their ends lifted clear and sharper, the crown standing up
#   C  sleek        fewer, broader locks lying close, a smooth silhouette broken only by its points

FEEL = {"A": dict(lift=1.0, hug=1.0, count=1.0, taper=0.7),
        "B": dict(lift=1.9, hug=0.7, count=1.0, taper=0.95),
        "C": dict(lift=0.45, hug=1.12, count=0.72, taper=0.55)}
BACK = (0, -1, 0.3)
UP = (0, -0.7, 1)
TIE = (180, 24)


def rook(key):
    f = FEEL[key]
    lift, hug = f["lift"], (lambda x: min(0.96, x * f["hug"]))
    n = lambda c: max(2, round(c * f["count"]))   # noqa: E731
    wide = 1 / f["count"] ** 0.6
    h = Solid("#08080D", "#3A4266", seed=5, band=(0.56, 0.1, 0.55))
    h.shell(am.hairline(front=4.86, temple=4.6, nape=4.15))
    big = dict(taper=f["taper"], depth=0.3, rise=0.34)
    ring = lambda count, ph, around, length, width, flick, hold, **kw: h.ring(   # noqa: E731
        n(count), ph, around, length, width * wide, flick=flick * lift, hold=hug(hold), **big, **kw)
    ring(7, 62, (120, 240), 0.95, 0.62, 26, 0.6, off=0.04, sizes=(1.0, 0.82, 1.12, 0.9))           # the back
    ring(7, 34, (110, 250), 0.95, 0.62, 36, 0.5, off=0.08, sizes=(1.0, 0.82, 1.12, 0.9))
    for s in (-1, 1):                                                                             # the sides
        ring(3, 40, (s * 66, s * 108), 1.0, 0.58, 14, 0.8, off=0.06, sizes=(1.0, 0.85, 1.1))
    ring(6, 14, (-64, 64), 1.06, 0.6, 12, 0.82, off=0.13, heading=8, sizes=(1.0, 0.8, 1.12, 0.88, 0.95, 0.85))   # the fringe
    ring(5, 10, (130, 230), 0.8, 0.56, 55, 0.25, off=0.14, comb=BACK, sizes=(1.0, 0.8, 1.15))           # the crown's points
    for s in (-1, 1):
        h.lay(s * 40, 6, 0.75, 0.56 * wide, off=0.16, flick=48 * lift, hold=hug(0.3), comb=(s * 0.4, -1, 0.6), **big)
    return h


def kirra_tail(h, f):
    tie = h.at(*TIE)[0] + h.at(*TIE)[1] * 0.12
    spine = [tie + Vector(q) for q in ((0, 0.0, -0.02), (0.02, -0.3, 0.24), (0.04, -0.7, 0.26), (0.06, -1.0, -0.06),
                                         (0.1, -1.08, -0.72), (0.2, -0.98, -1.4))]
    fan = 0.6 + 0.4 * f["lift"]
    for dx, dz, w in ((0.0, 0.0, 0.62), (0.16 * fan, 0.06, 0.42), (-0.16 * fan, 0.06, 0.42)):   # three locks off the one line
        pts = [q + Vector((dx * t, 0, dz * t)) for q, t in zip(spine, (0, 0.2, 0.5, 0.8, 1.0, 1.15))]
        h.free(pts, w, out=(0, -0.2, 1), taper=f["taper"], n=14)
    return tie


def kirra(key):
    f = FEEL[key]
    lift, hug = f["lift"], (lambda x: min(0.97, x * f["hug"]))
    n = lambda c: max(2, round(c * f["count"]))   # noqa: E731
    wide = 1 / f["count"] ** 0.6
    h = Solid("#D2D8E6", "#FFFFFF", seed=33, band=(0.5, 0.12, 0.35))
    h.shell(am.hairline(front=4.86, temple=4.6, nape=4.3))
    h.edge, h.light = 0.7, 0.5
    h.scalp = h.colour(0.2) * 0.6
    big = dict(taper=f["taper"], depth=0.3, rise=0.34)
    ring = lambda count, ph, around, length, width, flick, hold, **kw: h.ring(   # noqa: E731
        n(count), ph, around, length, width * wide, flick=flick * lift, hold=hug(hold), **big, **kw)
    ring(6, 96, (118, 242), 0.95, 0.66, 4, 0.95, off=0.03, comb=UP, sizes=(1.0, 0.9, 1.08))          # the back, up to the tie
    for s in (-1, 1):
        ring(3, 70, (s * 62, s * 116), 0.95, 0.6, 4, 0.95, off=0.04, comb=UP, sizes=(1.0, 0.9, 1.08))
    ring(5, 16, (-80, 80), 0.9, 0.62, 6, 0.95, off=0.08, comb=(0, -1, 0.4))                      # the top, back to the tie
    fringe = ((-50, 0.92, 0.5, 14), (-30, 1.08, 0.58, 18), (-10, 1.16, 0.62, 22), (10, 1.14, 0.6, 26), (30, 1.04, 0.56, 30),
              (50, 0.9, 0.5, 30)) if f["count"] >= 1 else         ((-44, 1.0, 0.62, 16), (-14, 1.16, 0.7, 22), (16, 1.1, 0.68, 28), (44, 0.92, 0.6, 30))
    for a, length, width, heading in fringe:                                                       # the fringe, to her left
        h.lay(a, 10, length, width, heading=heading, bend=8, off=0.12, flick=10 * lift, hold=hug(0.88), **big)
    for s in (-1, 1):
        h.lay(s * 80, 40, 1.15, 0.4, off=0.06, flick=4 * lift, hold=hug(0.92), **big)          # a long lock before each ear
    return h, kirra_tail(h, f)


# --- the takes: today's bodies, the hair swapped -------------------------------------------------------------------------

def with_hair(module, take, make):
    """`take` with its hair replaced by `make()`'s, everything else as it is today. Kirra's tie rides the new tail."""
    def run(joints, folder):
        original = module.figure

        def figure(joints, folder, blocks, head, hair, *rest):
            made = make()
            new, tie = made if isinstance(made, tuple) else (made, None)
            if tie is not None and rest:
                rest = ([p for p in rest[0] if getattr(p, "name", "") != "Tie"] + [tie_loop(tie)],)
            return original(joints, folder, blocks, head, new, *rest)

        module.figure = figure
        try:
            return take(joints, folder)
        finally:
            module.figure = original
    return run


def tie_loop(tie):
    t = am.Built("Tie")
    t.loop(tie + Vector((0, -0.02, -0.02)), 0.17, 0.18, "#1FA39A", thick=0.1, segments=12, squash=0.9, lean=None)
    return t


WHO_ = {
    "rook": dict(takes={"Rook": rt.take_a, **{k: with_hair(rt, rt.take_a, lambda k=k: rook(k)) for k in "ABC"}},
                 today="Today's Rook (AR59's pick)"),
    "kirra": dict(takes={"Kirra": kt.take_a, **{k: with_hair(kt, kt.take_a, lambda k=k: kirra(k)) for k in "ABC"}},
                  today="Today's Kirra (AR60's fix)"),
}
WAYS = {"A": ("A, the mass", ("one crown, every lock out from it", "the fringe down to the brow",
                              "the points apart only at their ends")),
        "B": ("B, spiked", ("A's locks", "their ends lifted clear and sharper", "the crown standing up")),
        "C": ("C, sleek", ("fewer, broader locks lying close", "a smooth outline", "broken only by its points"))}


def words(who):
    name = who.capitalize()
    return dict(
        stem=f"hair_{who}",
        beside=f"{name}'s three hairs square on, between two Anime Vanguards units at the same height. Internal: the two are reference.",
        title=f"AR64: {name.upper()}'S HAIR, THREE NEW WAYS",
        about=f"The study's way (docs/research/hair-read.md): one mass from one crown, down over the forehead and the "
              f"sides, its locks wide at the root and touching, each lit on its ridge and dark at its edges, so two meet "
              f"in a crevice. The takes differ only in how far the ends leave the mass. The body is today's {name}, "
              f"untouched. Research picks one.",
        row=f"today's {name}, A, B, C and a Brawler")


def measured(key, made):
    top = max(v.co.z for v in made["hair"].data.vertices)
    print(f"{key}: the hair stands {(top - kt.CROWN) / 1.25:.2f} of a head over the crown; "
          f"{sum(len(f.vertices) - 2 for f in made['hair'].data.polygons)} triangles")


if __name__ == "__main__":
    rest = sys.argv[sys.argv.index("--") + 2:]
    who, mode = rest[0], rest[1]
    spec = WHO_[who]
    rt.TAKES, rt.WHO = spec["takes"], tuple(spec["takes"])
    rt.SAID = {tuple(spec["takes"])[0]: (spec["today"], ("as it is today",)), **WAYS}
    OUT = rs.OUT = bl.out_dir()
    if mode == "takes":
        rt.takes_run(OUT, rest[2:] or list(spec["takes"]), finish=measured)
    elif mode == "shade":
        rt.shade_run(OUT)
    elif mode == "sheet":
        rt.sheet_run(OUT, words(who), kt.BESIDE)
