"""AR64: the Voidkin's hair, as good Roblox hair is made: long flat locks from one whorl, in layers. On Rook and Kirra.

Four tries were rejected on 2026-11-24 (leaves, solid spikes, a mass of forty round locks, one remeshed surface: "it
still horrible ur hair is horrendous"), then: "browse more example". The wider study (docs/research/hair-read.md, "A
wider look": Roblox's most-favourited catalog hair, Anime Vanguards' heads at full size, Sketchfab) says what every good
one does: every lock is born at one whorl on the crown and runs away from it, turning the same way; the locks lie in
rings like roof tiles, each hiding the roots of the one below; a lock is long and flat, with hard edges; the whole is a
dome bigger than the head, and only a lock's last third leaves it; the fringe falls from the whorl to the brows; under
it all the head is covered in the hair's shade. So here (`Blades`): a cap, and on it rings of flat wedges from one
whorl (`ring`, `lay`), the broad face light and the narrow one in shade, at three grains of one layout.

    blender.exe -b --factory-startup --python tools/blender/hair_ways.py -- <out_dir> <who> takes|shade|sheet [keys]

`who` is rook or kirra: each gets its own sheet, today's first (rook_make_takes.py's sheet: square on beside two
Anime Vanguards units, the three-quarter front, the game camera, the bust, the phone).
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402

KEY = Vector((-0.35, 0.45, 0.82)).normalized()   # where the drawn light comes from: over the face, a little to his left


class Blades(am.Hair):
    """Hair as the genre makes it. `root` and `tip` are a lock's light face at its root and at its point; `shade` is what
    its narrow face is multiplied by; `under`, its underside; the cap takes the shade's colour."""

    def __init__(self, root, tip, shade=(0.62, 0.64, 0.72), under=(0.4, 0.42, 0.5), seed=1):
        super().__init__(root, tip, seed=seed)
        self.shade, self.under = np.array(shade), np.array(under)

    def cap(self, hairline, segments=36):
        self.shell(hairline, segments)
        self.scalp = self.tone(0.45) * self.shade

    def tone(self, u):
        return self.pair[0] + (self.pair[1] - self.pair[0]) * min(1.0, max(0.0, u)) ** 0.9

    def wedge(self, line, width, rise=0.24, depth=0.2, ridge=0.36, peak=0.3, root=0.62, sharp=1.25):
        """One lock along `line`, a list of (point, the way out of the head there): `width` across at its widest,
        `peak` of the way along; `root` of that at its root; drawn to a point, fuller the higher `sharp`. A wedge in
        section: its ridge `rise` of its width out, `ridge` of the way across from its shaded edge; its keel `depth`
        of it in. The broad face is the one turned to the drawn light."""
        n, frames = len(line), []
        for i, (q, o) in enumerate(line):
            along = (line[min(i + 1, n - 1)][0] - line[max(i - 1, 0)][0]).normalized()
            o = o - along * o.dot(along)
            o = o.normalized() if o.length > 1e-4 else along.orthogonal().normalized()
            frames.append((q, o, along.cross(o).normalized()))
        _, o, side = frames[n // 2]
        flip = 1.0 if side.dot(KEY) >= 0 else -1.0
        rings, shades = [], []
        for i, (q, o, side) in enumerate(frames):
            u = i / (n - 1)
            v = min(u / peak, 1.0)
            s = root + (1 - root) * v * v * (3 - 2 * v) if u <= peak else 1 - ((u - peak) / (1 - peak)) ** sharp
            w = width * max(s, 0.0)
            c = self.tone(u)
            shades.append([c, c * (1 + self.shade) / 2, c * self.shade, c * self.under, c * self.under * 0.8])
            if i == n - 1:
                rings.append([self._vert(q)] * 8)
                continue
            left, right = q + side * (w / 2), q - side * (w / 2)
            top = q - side * (flip * w * (0.5 - ridge)) + o * (w * rise)
            keel = q - o * (w * depth)
            rings.append([self._vert(p) for p in (left, top, top, right, right, keel, keel, left)])
        strip = len(self.strips)
        self.strips.append(np.clip(np.array(shades, np.float32), 0, 1))
        col = (0.0, 0.3, 1.7, 2.0, 3.0, 4.0, 4.0, 3.0) if flip > 0 else (2.0, 1.7, 0.3, 0.0, 3.0, 4.0, 4.0, 3.0)
        for j, (lo, hi) in enumerate(zip(rings, rings[1:])):
            for a, b in ((0, 1), (2, 3), (4, 5), (6, 7)):
                if j < n - 2:
                    f = self.bm.faces.new((lo[a], hi[a], hi[b], lo[b]))
                    where = [(j, col[a]), (j + 1, col[a]), (j + 1, col[b]), (j, col[b])]
                else:
                    f = self.bm.faces.new((lo[a], hi[0], lo[b]))
                    where = [(j, col[a]), (j + 1, (col[a] + col[b]) / 2), (j, col[b])]
                f.smooth = True   # smooth along the lock; across it the points are apart, so each face stays flat
                self.charts.append((f, strip, where))
        self.locks += 1

    def blade(self, pts, width, twist=0.0, n=9, out=None, **kw):
        """A lock through the curve's control points `pts` (three or four), free of the head: a tail, a tuft."""
        P = [Vector(p) for p in pts]

        def at(t):
            q = P
            while len(q) > 1:
                q = [a.lerp(b, t) for a, b in zip(q, q[1:])]
            return q[0]

        pts = [at(i / (n - 1)) for i in range(n)]
        o, line = (Vector(out) if out is not None else pts[0] - am.CENTRE), []
        for i, q in enumerate(pts):
            along = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            o = o - along * o.dot(along)                      # the face carried along the curve, never flipping
            o = o.normalized() if o.length > 1e-4 else along.orthogonal().normalized()
            line.append((q, Matrix.Rotation(math.radians(twist) * i / (n - 1), 3, along) @ o if twist else o.copy()))
        self.wedge(line, width, **kw)

    def lay(self, a, ph, length, width, heading=0.0, bend=0.0, off=0.12, flick=30.0, hold=0.6, comb=None, n=10, **kw):
        """A lock that lies on the head: rooted `a` degrees round and `ph` down from the whorl, it runs `length` down
        the head (`heading` degrees off straight down, turning `bend` by its end), `off` clear of the scalp, and from
        `hold` of the way along it leaves the head, its point turned `flick` degrees out."""
        self.wedge(self.spine(a, ph, length, heading, bend, comb, hold, flick, off, n), width, **kw)


# --- Rook: black, short and spiked, from one whorl; a fringe to his brows, one lock between his eyes --------------------

TILE, LEAF = dict(root=0.78, peak=0.22, sharp=1.1), dict(root=0.3, peak=0.42, sharp=1.2)
SWIRL = 14   # every lock turns the same way round the whorl
LONG, TURN = (1.0, 1.12, 0.94, 1.16, 1.02), (1.0, 1.3, 0.9, 1.22, 0.86)   # a ring's rhythm: no two neighbours alike
# the same hair at three grains: A as the genre's fighters wear it, B fewer and bigger, C finer, the catalog's fluff
GRAIN = {"A": dict(hem=9, mid=10, crown=6, fringe=5), "B": dict(hem=6, mid=7, crown=4, fringe=4),
         "C": dict(hem=13, mid=14, crown=9, fringe=7)}


def ring(h, count, around, ph, length, cover, flick, shape, was, **kw):
    """`count` locks round the head from `around[0]` to `around[1]` degrees, `ph` down from the whorl: each `cover`
    times its share of the ring wide, so they overlap, in the ring's rhythm. `was`: the count the numbers were
    drawn at, so a ring of fewer locks has them longer and turned out further."""
    a0, a1 = around
    arc = math.radians(a1 - a0) * am.SCALP * math.sin(math.radians(min(ph + 30, 90))) ** 0.75
    big = (was / count) ** 0.35
    for i in range(count):
        a = a0 + (a1 - a0) * (i + 0.5) / count
        h.lay(a, ph, length * LONG[i % 5] * big, cover * arc / count, flick=flick * TURN[i % 5] * big ** 0.5, **shape, **kw)


def rook(key):
    g = GRAIN[key]
    h = Blades("#08080A", "#33343C", shade=(0.5, 0.5, 0.55), under=(0.3, 0.3, 0.34), seed=5)
    h.cap(am.hairline(front=5.04, temple=4.56, nape=4.14))
    # the hem, from under the rest: down the back and the sides, its points turned out at the neck
    ring(h, g["hem"], (64, 296), 52, 0.8, 1.55, 42, TILE, 9, bend=SWIRL, off=0.1, hold=0.46)
    # over it, a ring with its points out at the ears' height
    ring(h, g["mid"], (52, 308), 26, 0.8, 1.6, 40, TILE, 10, bend=SWIRL, off=0.19, hold=0.48)
    # the crown: leaves from the whorl over the back and the sides, lying on the rest, their points a little lifted
    ring(h, g["crown"], (58, 302), 6, 0.86, 1.5, 38, LEAF, 6, heading=8, bend=SWIRL + 6, off=0.32, hold=0.56)
    # the fringe: leaves from the whorl's front, over the forehead to the brows, the middle one between the eyes
    n = g["fringe"]
    for i in range(n):
        a = -54 + 104 * (i + 0.5) / n
        mid = 1 - abs(a + 2) / 54
        h.lay(a, 9, 0.94 + 0.26 * mid ** 1.5, 2.9 / n ** 0.9 * 0.46, bend=a * 0.34, off=0.23, flick=6, hold=0.74,
              n=12, root=0.4, peak=0.42, sharp=1.5)
    for s in (-1, 1):                                                 # one before each ear, to the cheek
        h.lay(s * 68, 36, 0.82, 0.34, bend=s * -10, off=0.14, flick=30, hold=0.55, **TILE)
    return h


# --- Kirra: silver, combed up to a high tail; a fringe swept to her left, a long lock by each cheek --------------------

TIE = (180, 24)


def kirra(key):
    g = GRAIN[key]
    h = Blades("#A9B2C8", "#FFFFFF", shade=(0.62, 0.66, 0.8), under=(0.42, 0.46, 0.62), seed=33)
    h.cap(am.hairline(front=5.04, temple=4.6, nape=4.3))
    tie = h.at(*TIE)[0] + h.at(*TIE)[1] * 0.12
    # the back and the sides, combed up to the tie: broad and flat on the head
    n = g["hem"] + 1
    for i in range(n):
        a = 58 + 244 * (i + 0.5) / n
        far = abs(a - 180) / 122
        h.lay(a, 80 - 6 * far, 0.74 + 0.62 * far ** 1.3, 5.2 / n, comb=(0, -0.7, 1), off=0.07, flick=0, hold=1.0, n=10,
              root=0.92, peak=0.3, sharp=2.4, rise=0.14)
    # the fringe: leaves from the whorl's front, swept to her left, to the brows
    n = g["fringe"] + 1
    for i in range(n):
        a = -58 + 112 * (i + 0.5) / n
        h.lay(a, 9, 0.98 + 0.12 * math.sin(i * 2.1), 3.1 / n ** 0.9 * 0.46, heading=10, bend=16 + a * 0.22, off=0.23, flick=8,
              hold=0.74, n=12, root=0.4, peak=0.42, sharp=1.5)
    for s in (-1, 1):
        h.lay(s * 66, 30, 1.34, 0.32, bend=s * -8, off=0.15, flick=14, hold=0.8, n=12, **TILE)   # a long lock by each cheek
        h.lay(s * 84, 40, 0.7, 0.36, bend=s * 14, off=0.14, flick=44, hold=0.5, **TILE)          # one flicked out over the ear
    # the tail: up from the tie, over, and down close behind the head, in broad blades of three lengths
    for dx, lift, drop, back, w in ((0.0, 0.46, -1.5, 0.74, 0.62), (0.24, 0.4, -1.22, 0.68, 0.54), (-0.24, 0.4, -1.3, 0.68, 0.54),
                                    (0.42, 0.3, -0.86, 0.56, 0.44), (-0.42, 0.3, -0.76, 0.56, 0.44), (0.1, 0.52, -0.98, 0.86, 0.46),
                                    (-0.12, 0.5, -1.1, 0.84, 0.46)):
        h.blade([tie, tie + Vector((dx * 0.5, -0.3, lift)), tie + Vector((dx, -back, 0.1)),
                 tie + Vector((dx * 1.25, -back * 0.86, drop))], w, out=(0, -0.3, 1), n=12, root=0.5, peak=0.4, sharp=1.3)
    return h, tie


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
WAYS = {"A": ("A", ("from one whorl, in three layers",)), "B": ("B", ("fewer, bigger locks",)), "C": ("C", ("finer locks",))}


def words(who):
    name = who.capitalize()
    return dict(
        stem=f"hair_{who}",
        beside=f"{name}'s three hairs square on, between two Anime Vanguards units at the same height. Internal: the two are reference.",
        title=f"AR64: {name.upper()}'S HAIR, FROM ONE WHORL",
        about=f"Long flat locks from one whorl, in three layers on a cap in the hair's shade; the fringe falls from the "
              f"whorl to the brows (docs/research/hair-read.md, 'A wider look'). One layout at three grains. The body "
              f"is today's {name}, untouched.",
        row=f"today's {name}, A, B, C and a Brawler")


def measured(key, made):
    v = [p.co for p in made["hair"].data.vertices]
    print(f"{key}: the hair is {(max(p.x for p in v) - min(p.x for p in v)) / 1.25:.2f} heads wide and stands "
          f"{(max(p.z for p in v) - 5.125) / 1.25:.2f} of a head over the head; "
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
