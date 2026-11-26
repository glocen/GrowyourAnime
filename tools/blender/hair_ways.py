"""AR64: the Voidkin's hair, as good Roblox hair is made: long flat locks from one whorl, in layers. On Rook and Kirra.

Four tries were rejected on 2026-11-24 (leaves, solid spikes, a mass of forty round locks, one remeshed surface: "it
still horrible ur hair is horrendous"), then: "browse more example". The wider study (docs/research/hair-read.md, "A
wider look": Roblox's most-favourited catalog hair, Anime Vanguards' heads at full size, Sketchfab) says what every good
one does: every lock is born at one whorl on the crown and runs away from it, turning the same way; the locks lie in
rings like roof tiles, each hiding the roots of the one below; a lock is long and flat, with hard edges; the whole is a
dome bigger than the head, and only a lock's last third leaves it; the fringe falls from the whorl to the brows; under
it all the head is covered in the hair's shade. So here (`Blades`): a cap, and on it rings of flat wedges from one
whorl (`ring`, `lay`), the broad face light and the narrow one in shade, at three grains of one layout.

That round was rejected too ("your hair still look bad.": the shape, the locks, the colour). Rook's is now made the
other way round (`Locks`, `rook`): the design drawn flat and picked first (tools/art/hair_designs.py), then modelled lock
for lock as the pros do (hair-read.md, "How the pros make it"): smooth closed leaves of three sizes in three layers, lit
as one mass, with one ring of light. Kirra's is still the rings, until hers is drawn. `match` shoots a take's head in
the drawn designs' views.

    blender.exe -b --factory-startup --python tools/blender/hair_ways.py -- <out_dir> <who> takes|shade|sheet [keys]

`bare` shoots the head with no hair, face on, three-quarter and side on: what the drawn designs are laid over.
`who` is rook or kirra: each gets its own sheet, today's first (rook_make_takes.py's sheet: square on beside two
Anime Vanguards units, the three-quarter front, the game camera, the bust, the phone).
"""
import math
import sys
from pathlib import Path

import bpy
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
# the same hair at three grains: A as the genre's fighters wear it, B fewer and bigger, C finer, the catalog's fluff
GRAIN = {"A": dict(hem=9, mid=10, crown=6, fringe=5), "B": dict(hem=6, mid=7, crown=4, fringe=4),
         "C": dict(hem=13, mid=14, crown=9, fringe=7)}


ROUND = 0.3                 # how far a lock's light is the whole head's, not its own
RING = (0.78, 0.05, 0.07)   # the ring of light: its height over the head's middle, its half width, its dip on a lock


class Locks(Blades):
    """Hair as it is drawn in tools/art/hair_designs.py: a few big locks, each placed by hand. A lock is a closed leaf,
    round over its top and smooth all the way round, with a picture of its own: its two tones turned to the drawn
    light, a dark line at its edges, and one streak of light on its lit side."""

    def __init__(self, lit, shade, glint, seed=1):
        super().__init__(shade, lit, seed=seed)
        self.lit, self.dark, self.glint = (np.array(rs.srgb(c)[:3]) for c in (lit, shade, glint))

    def cap(self, hairline, segments=36):
        self.shell(hairline, segments)
        self.scalp = self.dark * 0.8

    def leaf(self, line, width, rise=0.28, belly=0.68, start=0.3, sharp=1.5, roll=0.0, size=(40, 80)):
        """A lock along `line`, [(point, the way out of the head)]: `width` at its widest, `belly` of the way along,
        `start` of that at its root; `rise` of its width tall; rolled `roll` degrees so one edge lies on its
        neighbour."""
        n, grid, k, lit = len(line), [], math.radians(roll), 0.0
        for i, (q, out) in enumerate(line):
            u = i / (n - 1)
            along = (line[min(i + 1, n - 1)][0] - line[max(i - 1, 0)][0]).normalized()
            out = out - along * out.dot(along)
            out = out.normalized() if out.length > 1e-3 else along.orthogonal().normalized()
            side = along.cross(out).normalized()
            side, out = side * math.cos(k) + out * math.sin(k), out * math.cos(k) - side * math.sin(k)
            v = min(u / belly, 1.0)
            s = start + (1 - start) * v * v * (3 - 2 * v) if u <= belly else max(1 - ((u - belly) / (1 - belly)) ** sharp, 0.04)
            w, r = width / 2 * s, width * rise * s ** 0.8
            lit += side.dot(KEY)
            grid.append([q + side * (w * t) + out * (r * h)
                         for t, h in ((-1, 0), (-0.55, 0.78), (0, 1), (0.55, 0.78), (1, 0), (0.5, -0.3), (-0.5, -0.3))])
        t0 = 0.32 if lit >= 0 else -0.32
        step = lambda x, lo, hi: (lambda y: y * y * (3 - 2 * y))(np.clip((x - lo) / (hi - lo), 0, 1))  # noqa: E731

        def paint(u, v, P, N):
            top = u <= 4 / 7
            t = np.where(top, u / (4 / 7) * 2 - 1, 0.0)
            ball = (P - np.array(am.CENTRE)) * np.array((1.0, 1.0, 0.85))
            ball /= np.maximum(np.linalg.norm(ball, axis=2, keepdims=True), 1e-9)
            n = N * (1 - ROUND) + ball * ROUND
            n /= np.maximum(np.linalg.norm(n, axis=2, keepdims=True), 1e-9)
            s = step(n @ np.array(KEY), -0.12, 0.28)
            c = self.dark + (self.lit - self.dark) * s[..., None]
            c = c * (0.62 + 0.38 * step(v, 0.0, 0.3))[..., None]
            # the ring of light: one band round the head at one height, dipping to a point on each lock
            high = (P[..., 2] - am.CENTRE.z - RING[0] + RING[2] * (1 - np.abs(t - t0 * 0.6))) / RING[1]
            band = step(1 - np.abs(high), 0.0, 0.35) * (0.25 + 0.75 * s) * step(ball[..., 2], 0.05, 0.3)
            c = c + (self.glint - c) * (0.7 * band)[..., None]
            c = c * (1 - 0.6 * step(np.abs(t), 0.8, 0.98))[..., None]
            return np.where(top[..., None], c, self.dark * 0.6)

        mids = [q for q, _ in line]
        self.sheet(grid, paint, size, lambda mid, r, c: mid - (mids[r] + mids[r + 1]) / 2, closed=True)

    def build(self, folder, name="Hair"):
        """The mesh, its normals turned most of the way to a ball's round the head: the hair takes the game's light as
        one mass, not lock by lock (how Guilty Gear Xrd's is lit; docs/research/hair-read.md, "How the pros make it")."""
        obj = super().build(folder, name)
        normals = []
        for v in obj.data.vertices:
            ball = v.co - am.CENTRE
            ball.z *= 0.85
            normals.append((v.normal * (1 - ROUND) + ball.normalized() * ROUND).normalized())
        obj.data.normals_split_custom_set_from_vertices(normals)
        return obj


def rook():
    """Rook's hair, the drawn design "Shag": every lock from the whorl, full and loose, over the forehead to the brows,
    its points turned out. A tier of short locks under the hem, the long ones over it, the fringe on top."""
    h = Locks("#1E2233", "#07080C", "#8E9BD2", seed=5)
    h.cap(am.hairline(front=5.0, temple=4.5, nape=4.1), segments=24)

    def put(a, length, width, off, hold, flick, bend=0.0, ph=1.5, roll=14.0, crown=0.6, n=11, **kw):
        line = h.spine(a, ph, length, 0.0, bend, None, hold, flick, off, n)
        # the kit's line dips into the head at its root; these stand `crown` of their height at the whorl, so it is the top
        ease = lambda x: (lambda v: v * v * (3 - 2 * v))(min(max(x, 0.0), 1.0))  # noqa: E731
        line = [(q + out * (0.07 * (1 - ease(i / (n - 1) / 0.2)) + off * crown * (1 - ease(i / (n - 1) / 0.35))), out)
                for i, (q, out) in enumerate(line)]
        h.leaf(line, width, roll=roll, **kw)

    turn = 22   # every lock turns the same way round the whorl
    # the base: short points under the hem, turned out
    for a, length, flick in ((98, 0.82, 30), (-98, 0.8, 26), (128, 0.92, 32), (-128, 0.86, 24), (154, 0.95, 30), (180, 0.86, 22),
                             (206, 0.96, 30)):
        put(a, length, 0.5, 0.06, 0.45, flick, ph=56, crown=0.0, n=7, belly=0.4, start=0.7, sharp=1.5)
    # the back, the biggest masses: three broad, two smaller lying over their joins
    for a, length, width, off, flick, bend in ((150, 1.6, 0.9, 0.2, 14, turn), (180, 1.78, 0.95, 0.2, 10, turn), (212, 1.55, 0.86, 0.2, 16, turn),
                                               (166, 1.3, 0.5, 0.27, 30, turn + 10), (197, 1.44, 0.46, 0.27, 24, turn - 12)):
        put(a, length, width, off, 0.7, flick, bend=bend, belly=0.72)
    # each side: the broad shoulder of the mass, a lock behind the ear, a long sharp one down the cheek
    for s in (-1, 1):
        put(s * 101, 1.2 + s * 0.06, 0.78, 0.2, 0.72, 12, bend=turn, belly=0.72)
        put(s * 124, 1.45 - s * 0.07, 0.5, 0.24, 0.66, 26, bend=turn + s * 8, belly=0.7)
        put(s * 72, 1.56 + s * 0.05, 0.4, 0.16, 0.8, 10, bend=turn * 0.4 - s * 8, belly=0.7, sharp=1.2)
    # the fringe: three chunks, the middle one the largest, each ending in two or three points; the forehead shows between
    for a, length, width in ((-20, 1.4, 0.5), (-6, 1.64, 0.6), (7, 1.46, 0.46),
                             (31, 1.36, 0.44), (46, 1.52, 0.54), (-41, 1.4, 0.5), (-55, 1.54, 0.48)):
        put(a, length, width, 0.18, 0.82, 8, bend=turn * 0.4 - a * 0.12, belly=0.64, sharp=1.5)
    # two small tufts standing at the whorl
    for a, length, width, flick in ((-25, 0.56, 0.34, 56), (38, 0.48, 0.3, 48)):
        put(a, length, width, 0.24, 0.25, flick, bend=30, n=8, belly=0.45, sharp=1.2)
    return h


class Sheets(am.Hair):
    """Hair as the catalog's best-loved boys' hairs are built, read at full size (docs/research/hair-read.md, "What the
    full-size pictures show"): never a lock apiece from root to tip. The hair is a few SHEETS draped from the whorl
    over the head, one over another. A sheet is pleated: each pleat a lock, round across, meeting its neighbours in
    sharp grooves, so the head between the tips is one surface. Only toward its end does a pleat leave its neighbours,
    narrow to a long point and lift off the head. Where neighbours part late they read as one clump with a notched
    end; where they part early the gap runs deep."""

    def __init__(self, lit, dark, glint, seed=1):
        super().__init__(dark, lit, seed=seed)
        self.lit, self.dark, self.glint = (np.array(rs.srgb(c)[:3]) for c in (lit, dark, glint))

    def cap(self, hairline, segments=28):
        self.shell(hairline, segments)
        self.scalp = self.dark * 0.8

    def sheet_of(self, start, pleats, ph0=1.5, off=0.08, swirl=18.0, relief=0.3, high=0.075, step=10.0, gloss=0.28, puff=0.0):
        """One sheet. Its pleats lie side by side from `start` degrees round, toward his left; each is (how many
        degrees wide, where it ends, where its left side leaves its neighbour, how far its point lifts off the head,
        how many degrees its point drifts to his left). The sheet starts `ph0` degrees down from the whorl, rides
        `off` over the head, and turns `swirl` degrees round the whorl by the head's widest."""
        edges = [start]
        for p in pleats:
            edges.append(edges[-1] + p[0])
        closed = abs(edges[-1] - edges[0] - 360) < 1e-6
        lefts = [p[2] for p in pleats]
        for i, p in enumerate(pleats):
            right = lefts[i + 1] if i + 1 < len(pleats) else (lefts[0] if closed else p[2])
            self.pleat(edges[i], edges[i + 1], p[1], lefts[i], right, p[3], p[4], ph0, off, swirl, relief, high, step, gloss, puff)

    def pleat(self, a0, a1, end, part0, part1, lift, drift, ph0, off, swirl, relief, high, step, gloss, puff, sharp=1.6):
        part0, part1 = min(part0, end - 6), min(part1, end - 6)
        first = min(part0, part1)
        phs = [ph0]
        while phs[-1] + step < end - 2:
            phs.append(phs[-1] + step)
        phs.append(end)
        tip = (a0 + a1) / 2 + drift
        turn = lambda ph: swirl * (ph - ph0) / 90   # noqa: E731

        def side(a, part, ph):
            if ph <= part:
                return a
            return a + (tip - a) * ((ph - part) / (end - part)) ** sharp

        grid, core = [], []
        for ph in phs:
            la, ra = side(a0, part0, ph) + turn(ph), side(a1, part1, ph) + turn(ph)
            if ra - la < 0.6:
                la, ra = (la + ra) / 2 - 0.3, (la + ra) / 2 + 0.3
            up = lift * max(0.0, (ph - first) / (end - first)) ** 1.7 + puff * math.cos(math.pi / 2 * min(ph / 72, 1.0)) ** 1.3
            pl, pr = self.at(la, ph)[0], self.at(ra, ph)[0]
            pm, nm, _ = self.at((la + ra) / 2, ph)
            tall = min(relief * (pr - pl).length, high)
            row = []
            for x in (-1.0, -0.42, 0.42, 1.0):
                q, n, _ = self.at((la + ra) / 2 + (ra - la) / 2 * x, ph)
                row.append(q + n * (off + up + tall * (1 - x * x) ** 0.75))
            row.append(pm + nm * (off + up - 0.02))
            grid.append(row)
            core.append(pm + nm * (off + up - 0.01))
        paint = self.painted(3 / 5, gloss)
        self.sheet(grid, paint, (28, 80), lambda mid, r, c: mid - (core[r] + core[r + 1]) / 2, closed=True)
        # the grooves are creases; over its top a pleat is smooth
        self.bm.verts.ensure_lookup_table()
        made = self.bm.verts[len(self.bm.verts) - len(phs) * 5:]
        for r in range(len(phs) - 1):
            for col in (0, 3):
                edge = self.bm.edges.get((made[r * 5 + col], made[(r + 1) * 5 + col]))
                if edge is not None:
                    edge.smooth = False

    def painted(self, rim, gloss):
        """A lock's picture: `rim` of the way round it is its top. Darker at its root, a few hairs drawn along it, a
        soft light on its crown, more of it at the height where the head's own shine sits, and dark in its grooves."""
        ease = lambda x, lo, hi: (lambda y: y * y * (3 - 2 * y))(np.clip((x - lo) / (hi - lo), 0, 1))  # noqa: E731
        lines = [(self.rng.uniform(-0.6, 0.6), self.rng.uniform(0.02, 0.05), self.rng.uniform(0.0, 0.35)) for _ in range(2)]
        band = am.CENTRE.z + 0.52

        def paint(u, v, P, N):
            top = u <= rim
            t = np.where(top, u / rim * 2 - 1, 0.0)            # across the lock: -1 and 1 in its grooves
            c = self.dark + (self.lit - self.dark) * (0.62 + 0.38 * ease(v, 0.0, 0.6))[..., None]
            for at, wide, begin in lines:
                c = c * (1 - 0.2 * np.exp(-((t - at) / wide) ** 2) * ease(v, begin, begin + 0.15))[..., None]
            ridge = np.exp(-((t + 0.1) / 0.5) ** 2)
            shine = np.exp(-((P[..., 2] - band) / 0.2) ** 2) * gloss + 0.1
            c = c + (self.glint - c) * (shine * ridge)[..., None]
            c = c * (1 - 0.62 * ease(np.abs(t), 0.5, 1.0))[..., None]
            return np.where(top[..., None], c, self.dark * 0.8)

        return paint

    def loose(self, root, tip, width, arch=0.3, sway=0.0, full=0.35, sharp=1.4, n=7, gloss=0.28):
        """A lock of its own, off the sheets: from `root` (degrees round, down) to `tip` (round, down, studs clear of
        the head), arched `arch` of its length away from the head and `sway` of it to its own left. Thin, round over
        its top like a pleat, widest `full` of the way along, drawn to a long point."""
        p0, n0, _ = self.at(*root)
        p2, n2, _ = self.at(*tip[:2])
        A, C = p0 + n0 * 0.02, p2 + n2 * tip[2]
        out = (n0 + n2).normalized() if (n0 + n2).length > 1e-3 else n0
        run = C - A
        left = run.cross(out).normalized() if run.cross(out).length > 1e-4 else Vector((1, 0, 0))
        B = (A + C) / 2 + out * (arch * run.length) + left * (sway * run.length)
        pts = [A * (1 - t) ** 2 + B * (2 * t * (1 - t)) + C * t * t for t in (i / (n - 1) for i in range(n))]
        o, grid = n0.copy(), []
        for i, q in enumerate(pts):
            u = i / (n - 1)
            along = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            o = o - along * o.dot(along)
            o = o.normalized() if o.length > 1e-4 else along.orthogonal().normalized()
            side = along.cross(o).normalized()
            v = min(u / full, 1.0)
            w = width / 2 * (0.7 + 0.3 * v * v * (3 - 2 * v) if u <= full else max(1 - ((u - full) / (1 - full)) ** sharp, 0.02))
            tall = min(0.3 * 2 * w, 0.075)
            grid.append([q + side * (w * x) + o * (tall * (1 - x * x) ** 0.75) for x in (-1.0, -0.42, 0.42, 1.0)] + [q - o * 0.02])
        self.sheet(grid, self.painted(3 / 5, gloss), (28, 64), lambda mid, r, c: mid - (pts[r] + pts[r + 1]) / 2, closed=True)


def rook_sheets():
    """Rook's hair: a short, tousled crop, black. One sheet over the whole head from the whorl: before, a fringe in
    three chunks to the brows, the middle one's point the longest, between his eyes; at the sides to the ears, the
    points kicked out; behind, thrown out over a shorter sheet that lies down the nape. On top, clumps thrown up and
    round, their points standing."""
    h = Sheets("#1C1D24", "#08090C", "#6C7183", seed=7)
    h.cap(am.hairline(front=5.0, temple=4.62, nape=4.3))
    # down the nape, under the rest: one surface almost to its hem, the points short
    h.sheet_of(98, [(15, 100, 84, 0.05, 3), (17, 112, 92, 0.07, -3), (15, 104, 90, 0.10, 4), (18, 120, 96, 0.06, -3),
                    (16, 110, 94, 0.10, 4), (18, 124, 98, 0.05, 0), (16, 112, 96, 0.10, -4), (18, 118, 94, 0.07, 3),
                    (15, 104, 92, 0.10, -5), (17, 110, 90, 0.07, 3), (19, 98, 84, 0.05, -3)],
               ph0=50, off=0.02, swirl=0.0, gloss=0.0)
    # the sheet over the whole head, from his right temple round by the front
    h.sheet_of(-55, [
        # the fringe: his right chunk, the middle one, his left
        (15, 74, 46, 0.03, 3), (18, 80, 62, 0.03, -2),
        (14, 76, 48, 0.03, 4), (15, 85, 64, 0.04, 2), (9, 70, 60, 0.03, -3),
        (16, 79, 48, 0.03, 4), (14, 72, 62, 0.03, -2), (9, 77, 58, 0.03, -4),
        # his left side: before the ear, over it, behind it
        (14, 100, 50, 0.03, -2), (22, 84, 68, 0.12, 6), (12, 92, 74, 0.06, -3), (24, 82, 66, 0.16, 6),
        # the back
        (14, 96, 64, 0.10, -4), (30, 82, 70, 0.20, 4), (16, 100, 72, 0.08, -3), (28, 86, 66, 0.18, 0),
        (12, 94, 72, 0.08, 4), (26, 82, 68, 0.20, -5),
        # his right side
        (16, 92, 66, 0.07, 4), (24, 82, 70, 0.14, -6), (12, 90, 72, 0.06, 3), (18, 98, 52, 0.03, 2)],
               off=0.09, puff=0.12)
    # over the crown, broad shells laid across the sheet's own run, parted deep, their ends notched
    h.sheet_of(-100, [(52, 50, 12, 0.05, 8), (30, 60, 44, 0.07, -6),
                      (46, 46, 12, 0.05, 10), (40, 58, 40, 0.08, -4), (24, 50, 46, 0.06, -8),
                      (50, 54, 12, 0.06, 8), (34, 62, 46, 0.08, -6), (44, 48, 12, 0.05, 8), (40, 56, 42, 0.07, -8)],
               off=0.15, swirl=34.0, relief=0.2, high=0.085, puff=0.14)
    # loose, along the hair's run: each leaves the mass and kicks out
    L = h.loose
    L((70, 40), (84, 86, 0.22), 0.22, arch=0.14)
    L((-76, 44), (-90, 84, 0.20), 0.20, arch=0.14)
    L((128, 46), (140, 90, 0.26), 0.22, arch=0.14)
    L((-136, 44), (-150, 86, 0.24), 0.22, arch=0.14)
    L((176, 48), (184, 96, 0.24), 0.24, arch=0.14)
    L((24, 44), (36, 78, 0.12), 0.18, arch=0.14)
    return h


class Ribbons(Sheets):
    """Hair as the catalog's best-loved are, lock by lock (hair-read.md, "What the full-size pictures show"): a lock is
    a long thin ribbon, five to eight times as long as wide, born at the whorl or under the layer above. It lies on
    the head for most of its length, turning as it goes, then leaves it, narrows to a needle and flicks out. Round
    across its top, tilted so one edge tucks under its neighbour, as roof tiles round the whorl. Neighbours differ in
    length, turn and flick, so they cross near their ends."""

    def run(self, a, ph, length, heading=0.0, bend=0.0, hold=0.65, flick=40.0, curl=0.0, off=(0.03, 0.12), n=10, rate=2.0):
        """A ribbon's middle line, as (point, the way out of the head there). From (`a` round, `ph` down) it walks
        the head `heading` degrees off straight down (toward his left), turning `bend` degrees by the time it leaves
        the head, `hold` of the way along. It rides from `off[0]` to `off[1]` over the head. Free, it turns `flick`
        degrees out of the head and `curl` degrees to its own left by its point, most of it near the point."""
        ease = lambda x: (lambda v: v * v * (3 - 2 * v))(min(max(x, 0.0), 1.0))  # noqa: E731
        step, line, free = length / (n - 1), [], None
        p, nrm, down, east = self.frame(a, ph)
        h = math.radians(heading)
        d = down * math.cos(h) + east * math.sin(h)
        for i in range(n):
            u = i / (n - 1)
            if free is None:
                line.append((p + nrm * (off[0] + (off[1] - off[0]) * ease(u / max(hold, 1e-3))), nrm.copy()))
                if u >= hold:
                    t0 = (line[-1][0] - line[-2][0]).normalized() if len(line) > 1 else d.copy()
                    n0 = (nrm - t0 * nrm.dot(t0)).normalized()
                    free = (t0, n0, t0.cross(n0).normalized())
                    continue
                p, nrm, down, east = self.frame(*self.where(p + d * step))
                d = d - nrm * d.dot(nrm)
                d = Matrix.Rotation(math.radians(bend * step / max(hold * length, 1e-3)), 3, nrm) @ d.normalized()
            else:
                t0, n0, s0 = free
                t = ((u - hold) / max(1 - hold, 1e-3)) ** rate
                up, yaw = math.radians(flick) * t, math.radians(curl) * t
                way = (t0 * math.cos(yaw) - s0 * math.sin(yaw)) * math.cos(up) + n0 * math.sin(up)
                line.append((line[-1][0] + way * step, n0 * math.cos(up) - t0 * math.sin(up)))
        return line

    def ribbon(self, line, width, full=0.62, sharp=1.5, root=0.5, tall=None, tilt=0.0, gloss=None, k=1.0, size=(20, 56)):
        """A ribbon along `line`: `root` of its width where it starts, its whole width from a quarter of the way to
        `full`, then drawn to a point. `tilt` degrees: turned about its own length, its first edge raised."""
        n, pts, grid = len(line), [q for q, _ in line], []
        tall = self.fold if tall is None else tall
        for i, (q, out) in enumerate(line):
            u = i / (n - 1)
            along = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            out = out - along * out.dot(along)
            out = out.normalized() if out.length > 1e-4 else along.orthogonal().normalized()
            if tilt:
                out = Matrix.Rotation(math.radians(tilt * (1 - 0.6 * u)), 3, along) @ out
            side = along.cross(out).normalized()
            v = min(u / 0.25, 1.0)
            grow = root + (1 - root) * v * v * (3 - 2 * v)
            w = width / 2 * (grow if u <= full else max(1 - ((u - full) / (1 - full)) ** sharp, 0.03))
            high = min(tall * 2 * w, 0.03 * max(tall / 0.16, 1.0))
            grid.append([q + side * (w * x) + out * (high * (x == -0.2)) for x in (-1.0, -0.2, 1.0)] + [q - out * 0.012])
        paint = self.painted(2 / 4, self.gloss if gloss is None else gloss)
        self.sheet(grid, lambda u, v, P, N: paint(u, v, P, N) * k, size, lambda mid, r, c: mid - (pts[r] + pts[r + 1]) / 2, closed=True)
        # the ridge and the two edges are creases: two flat faces, as a folded ribbon
        self.bm.verts.ensure_lookup_table()
        made = self.bm.verts[len(self.bm.verts) - n * 4:]
        for row in range(n - 1):
            for col in (0, 1, 2):
                edge = self.bm.edges.get((made[row * 4 + col], made[(row + 1) * 4 + col]))
                if edge is not None:
                    edge.smooth = False

    def painted(self, rim, gloss):
        """A ribbon's picture: flat, lit toward its raised edge and in shade where it tucks under its neighbour,
        darker at its root, a few hairs drawn along it, and the head's own ring of light where it crosses it."""
        ease = lambda x, lo, hi: (lambda y: y * y * (3 - 2 * y))(np.clip((x - lo) / (hi - lo), 0, 1))  # noqa: E731
        lines = [(self.rng.uniform(-0.75, 0.75), self.rng.uniform(0.03, 0.07), self.rng.uniform(0.0, 0.3)) for _ in range(3)]
        band = am.CENTRE.z + self.ring[0]

        if self.flat:   # one colour across, darker toward the root: the light and the occlusion draw the rest
            def flat(u, v, P, N):
                c = self.dark + (self.lit - self.dark) * (0.3 + 0.7 * ease(v, 0.0, 0.7))[..., None]
                return np.where((u <= rim)[..., None], c, self.dark * 0.8)
            return flat

        def paint(u, v, P, N):
            top = u <= rim
            t = np.where(top, u / rim * 2 - 1, 0.0)            # across the ribbon: -1 its raised edge, 1 its tucked one
            across = 0.9 - 0.05 * t if self.one_band else 0.82 - 0.18 * t   # a lock's raised edge lit over its tucked one
            c = self.dark + (self.lit - self.dark) * ((0.22 + 0.78 * ease(v, 0.0, 0.7)) * across)[..., None]
            for at, wide, begin in lines:
                c = c * (1 - 0.3 * np.exp(-((t - at) / wide) ** 2) * ease(v, begin, begin + 0.15))[..., None]
            shine = np.exp(-((P[..., 2] - band) / self.ring[1]) ** 2) * gloss + 0.05
            # the ring across the lock's whole face, so it crosses the mass as one band; held to a line down each lock,
            # every lock lying in the band's height carried a stripe down its length, a noodle's (round 41: "pasta")
            wide = 1 - 0.6 * ease(t, 0.4, 1.0) if self.one_band else np.exp(-((t + 0.3) / 0.45) ** 2)
            c = c + (self.glint - c) * (shine * wide)[..., None]
            c = c + (self.glint - c) * (self.sheen * np.exp(-((t + 0.35) / 0.3) ** 2) * ease(v, 0.15, 0.6) * (1 - ease(v, 0.8, 1.0)))[..., None]
            c = c * (1 - self.tuck * ease(t, 0.4, 1.0))[..., None] * (1 - 0.35 * ease(-t, 0.84, 1.0))[..., None]
            return np.where(top[..., None], c, self.dark * 0.7)

        return paint

    ring = (0.5, 0.2)   # the ring of light: its height over the head's middle, how tall it is
    gloss = 0.25        # how bright the ring is on a ribbon
    round = 0.0         # how far a ribbon's light is the whole mass's (a ball round the head), not its own

    tuck = 0.86         # how dark a ribbon's tucked edge falls: its crease
    one_band = False    # the ring of light across each lock's whole face, never a line down it
    spec = None         # the stage's sheen on the hair (Principled's Specular IOR Level); None leaves the stage's own
    flat = False        # each ribbon one colour across, graded only along: no tube of light (hair-read.md, "Against Anime Vanguards")
    ao = None           # the baked occlusion: (how far a texel looks, its darkest), or None
    fold = 0.16         # how high a ribbon's fold stands, of its half width
    rough = None        # the stage's roughness on the hair; None leaves the make's own (0.8)

    def occlude(self):
        """The occlusion baked into each picture: from a texel every fourth across and down, rays over its own side,
        and the share that meet hair or the cap within reach darken it. So a ribbon darkens where it tucks under its
        neighbour, at its root and along the cap: the depth as the catalog's, held whatever the engine's light does."""
        from mathutils.bvhtree import BVHTree
        reach, floor = self.ao
        self.bm.normal_update()
        tree = BVHTree.FromBMesh(self.bm)
        rng = np.random.default_rng(7)
        u1, u2 = rng.random(24), rng.random(24)
        rays = np.stack([np.sqrt(u1) * np.cos(2 * np.pi * u2), np.sqrt(u1) * np.sin(2 * np.pi * u2), np.sqrt(1 - u1)], 1)
        for (pic, _), (P, N) in zip(self.patches, self.texels):
            h, w = pic.shape[:2]
            rows, cols = np.unique(np.r_[np.arange(0, h, 4), h - 1]), np.unique(np.r_[np.arange(0, w, 4), w - 1])
            seen = np.ones((len(rows), len(cols)))
            for a, r in enumerate(rows):
                for b, c in enumerate(cols):
                    n = Vector(N[r, c])
                    if n.length < 1e-6:
                        continue
                    turn = Vector((0, 0, 1)).rotation_difference(n.normalized()).to_matrix()
                    o = Vector(P[r, c]) + n.normalized() * 0.004
                    hits = sum(tree.ray_cast(o, turn @ Vector(d), reach)[0] is not None for d in rays)
                    seen[a, b] = floor + (1 - floor) * (1 - hits / len(rays))
            across = np.array([np.interp(np.arange(w), cols, row) for row in seen])
            full = np.array([np.interp(np.arange(h), rows, col) for col in across.T]).T
            pic *= full[..., None].astype(np.float32)

    def build(self, folder, name="Hair"):
        if self.ao:
            self.occlude()
        obj = super().build(folder, name)
        if self.spec is not None:   # the stage only: the exported pictures are untouched
            for m in obj.data.materials:
                bsdf = m.node_tree.nodes.get("Principled BSDF")
                if bsdf is not None:
                    bsdf.inputs["Specular IOR Level"].default_value = self.spec
                    if self.rough is not None:
                        bsdf.inputs["Roughness"].default_value = self.rough
        if self.round:
            me = obj.data
            own = [Vector(c.vector) for c in me.corner_normals] if hasattr(me, "corner_normals") else None
            if own is None:
                me.calc_normals_split()
                own = [Vector(l.normal) for l in me.loops]
            normals = []
            for loop, n in zip(me.loops, own):
                ball = me.vertices[loop.vertex_index].co - am.CENTRE
                ball.z *= 0.85
                normals.append(tuple((n * (1 - self.round) + ball.normalized() * self.round).normalized()))
            me.normals_split_custom_set(normals)
        return obj
    sheen = 0.4         # the soft light down each ribbon's raised face
    under = 0.55        # the crown surface's tone between the ribbons, from dark (0) to lit (1)

    def crown(self, low=52.0, off=0.07, swirl=40.0, lines=46, gloss=0.25, segments=28):
        """The top as one surface, from the whorl `low` degrees down: fine hairs drawn along it, turning round the
        whorl. The ribbons lie on it, so between them there is hair."""
        phs = [3.0, 12.0, 24.0, 38.0, low]
        grid = [[(lambda f: f[0] + f[1] * off)(self.at(-180 + 360 * i / segments, ph)) for i in range(segments)] for ph in phs]
        marks = [(self.rng.uniform(0, 1), self.rng.uniform(0.004, 0.012), self.rng.uniform(0.15, 0.4)) for _ in range(lines)]
        band = am.CENTRE.z + self.ring[0]

        def paint(u, v, P, N):
            c = np.broadcast_to(self.dark + (self.lit - self.dark) * self.under, u.shape + (3,)).copy()
            w = (u - swirl / 360 * v) % 1.0
            for at, wide, deep in marks:
                d = np.abs(w - at)
                c = c * (1 - deep * np.exp(-(np.minimum(d, 1 - d) / wide) ** 2))[..., None]
            shine = np.exp(-((P[..., 2] - band) / self.ring[1]) ** 2) * gloss
            return c + (self.glint - c) * shine[..., None] * 0.6

        self.sheet(grid, paint, (200, 36), lambda mid, r, c: mid - am.CENTRE, closed=True)

    def onto(self, v):
        """The (degrees round, degrees down) of the hair surface's point in the direction `v` from the head's middle."""
        if not hasattr(self, "_table"):
            phs = np.linspace(0.0, 150.0, 601)
            el = []
            for ph in phs:
                q = self.frame(0.0, ph)[0] - am.CENTRE
                el.append(math.atan2(q.z, q.y))
            self._table = (np.array(el)[::-1], phs[::-1])
        v = v.normalized()
        e = math.atan2(v.z, math.hypot(v.x, v.y))
        return math.degrees(math.atan2(-v.x, v.y)), float(np.interp(e, *self._table))

    def lock(self, root, end, width, bow=0.0, ess=0.0, lift=0.0, tail=0.3, off=(0.03, 0.1), flick=40.0, curl=0.0, n=6, nt=5, tilt=12.0,
             k=1.0, rate=1.4, **make):
        """A ribbon laid over the head from `root` to `end` (each degrees round, degrees down), the shortest way,
        bowed `bow` of its length to one side and `ess` into an S; it rides from `off[0]` to `off[1]` over the head, and `lift` more at its middle. Then it leaves the
        head for `tail` studs, turning `flick` degrees out of it and `curl` degrees to its own left by its point."""
        p0, p1 = self.at(*root)[0] - am.CENTRE, self.at(*end)[0] - am.CENTRE
        v0, v1 = p0.normalized(), p1.normalized()
        side = v0.cross(v1)
        side = side.normalized() if side.length > 1e-4 else v0.orthogonal().normalized()
        line = []
        for i in range(n):
            u = i / (n - 1)
            v = v0.slerp(v1, u) if v0.angle(v1) > 1e-4 else v0
            v = (v + side * (bow * math.sin(math.pi * u) + ess * math.sin(2 * math.pi * u))).normalized()
            q, nrm, _ = self.at(*self.onto(v))
            e = u * u * (3 - 2 * u)
            line.append((q + nrm * (off[0] + (off[1] - off[0]) * e + lift * math.sin(math.pi * u) ** 1.5), nrm.copy()))
        t0 = (line[-1][0] - line[-2][0]).normalized()
        n0 = line[-1][1] - t0 * line[-1][1].dot(t0)
        n0 = n0.normalized()
        s0 = t0.cross(n0).normalized()
        step = tail / max(nt, 1)
        for i in range(1, nt + 1):
            t = (i / nt) ** rate
            up, yaw = math.radians(flick) * t, math.radians(curl) * t
            way = (t0 * math.cos(yaw) - s0 * math.sin(yaw)) * math.cos(up) + n0 * math.sin(up)
            line.append((line[-1][0] + way * step, n0 * math.cos(up) - t0 * math.sin(up)))
        made = dict(full=0.62, sharp=1.0, root=0.75)
        made.update(make)
        if "base" in made:
            made["root"] = made.pop("base")
        self.ribbon(line, width, tilt=tilt, k=k, **made)

    def strand(self, a, ph, length, width, tilt=14.0, full=0.62, sharp=1.5, root=0.5, gloss=0.25, k=1.0, **walk):
        self.ribbon(self.run(a, ph, length, **walk), width, full, sharp, root, tilt=tilt, gloss=gloss, k=k)

    def free(self, points, width, n=10, **make):
        """A ribbon through `points` in space, off the head: a tuft thrown up out of the whorl."""
        line = [(Vector(q), (Vector(q) - am.CENTRE).normalized()) for q in am.smooth2([tuple(q) for q in points], n)]
        self.ribbon(line, width, **make)

    def layer(self, around, ph, length, width, count, off, hold, flick, heading=0.0, bend=0.0, curl=22.0, jitter=1.0, n=9, tilt=14.0):
        """`count` ribbons round the head from `around[0]` to `around[1]` degrees, rooted `ph` down: no two alike in
        length, width, turn or flick, and alternate ones curling toward each other, so their points cross."""
        r = self.rng
        for i in range(count):
            a = around[0] + (around[1] - around[0]) * (i + 0.5 + r.uniform(-0.25, 0.25) * jitter) / count
            big = 1.0 + (0.16 if i % 3 == 0 else -0.12 if i % 3 == 1 else 0.0) * jitter
            self.strand(a, ph + r.uniform(-3, 3) * jitter, length * big * r.uniform(0.94, 1.06), width * r.uniform(0.85, 1.12) * (2 - big),
                        heading=heading + r.uniform(-10, 10) * jitter, bend=bend + r.uniform(-12, 12) * jitter,
                        hold=hold * r.uniform(0.92, 1.06), flick=flick * r.uniform(0.6, 1.3), curl=curl * (1 if i % 2 else -1) * r.uniform(0.5, 1.5),
                        off=(off[0], off[1] * r.uniform(0.85, 1.2)), n=n, tilt=tilt, k=r.uniform(0.9, 1.08))


def rook_ribbons(accent=None, solid=False, flat_paint=False):
    """Rook's hair: a short, tousled crop, black, as the catalog's best-loved boys' hairs are laid. The whorl sits at
    the back of the crown; from it thin ribbons sweep forward over the top to the brows and down round the sides and
    the back, each bowed, each leaving the head over its last part and hooking out. Three layers and a hem of short
    points; a few hooks stand out of the silhouette; two arcs rise out of the whorl."""
    h = Ribbons("#0B0B0D", "#020203", "#626266", seed=11)   # near-black, its light neutral grey: never grey-blue
    if flat_paint:   # flat across each ribbon, a dark grey the light can draw planes on, the depth baked (hair-read.md, "Against Anime Vanguards")
        # neutral: a cool one reads grey-blue on the stage (the hair's never grey-blue); the game's warm sun is Faber's check
        h = Ribbons("#1F1F23", "#08080A", "#626266", seed=11)
        h.flat, h.ao, h.fold = True, (0.3, 0.25), 0.3
    # lit as one mass with one band across the upper dome (the blind read of round 37: a sheen on every strand,
    # with dark creases between, reads grey and busy at size)
    h.ring, h.gloss, h.sheen, h.round, h.tuck = (0.74, 0.16), 0.2, 0.12, 0.85, 0.55
    # `solid` (the director, 2026-11-26, 13:0x, on round 41: "the hair look a bit like pasta"): the catalog's hairs are
    # one dense mass with short flat locks cut into its outline; ours hung loose, long and curling, each lit as a tube.
    # So: no light down each lock, a softer crease and a flatter fold, and the side and back layers fewer, wider,
    # shorter, closer to the head, with no thin twins and little curl.
    flat = dict(tall=0.07) if solid else {}
    if solid:
        # a crisp dark crease where a lock lies over the next, as the catalog's (the blind read of round 42: a soft
        # crease read rubbery, plastic leaves)
        h.sheen, h.round, h.tuck, h.one_band, h.ring = 0.0, 0.8, 0.78, True, (0.7, 0.12)
    # Calibrated, not measured in the engine: our stage's sky is one colour all round, the ground too, so its sheen
    # greys a black hair to a mean of 0.20, where Roblox's own pictures of the catalog's black hairs read 0.10 with
    # black between the locks (hair-read.md). Faber's install is the check.
    h.spec = 0.3 if flat_paint else 0.1
    h.cap(am.hairline(front=4.94, temple=4.58, nape=4.3))
    h.under = 0.18   # dark between the clumps, so they part as the catalog's do
    h.crown(low=62.0, off=0.13)
    r, W = h.rng, (180.0, 30.0)   # the whorl: round, down

    def fan(ends, ph_end, width, tail, off, bow=0.22, flick=(30, 60), curl=(25, 60), spread=8.0, n=6, nt=5, sweep=0.0, ess=0.0, split=0.0, nape=0.0, **make):
        """A lock from near the whorl to each of `ends` (degrees round), `ph_end` down; bowed alternately, so
        neighbours cross; their tails hook alternately left and right. `sweep` (from -1 to 1): a chunk whose locks
        all bow one way, as a combed fringe, with `ess` of an S in each. `nape`: degrees more at the middle of the
        back, fading out toward the ears, so the back runs down to a tapered nape and never stops in a bowl's line."""
        for k, a in enumerate(ends):
            ph_end_a = ph_end + nape * ((1 + math.cos(math.radians(a - 180))) / 2) ** 3
            sgn = (1 if k % 2 else -1) if not sweep else (1 if sweep > 0 else -1)
            root = (W[0] + r.uniform(-spread, spread) * 2.5, W[1] + r.uniform(-spread, spread) * 0.6)
            h.lock(root, (a + r.uniform(-4, 4), ph_end_a + r.uniform(-6, 6)), width * r.uniform(0.8, 1.2), bow=sgn * bow * r.uniform(0.5, 1.3),
                   ess=sgn * ess * r.uniform(0.6, 1.3),
                   tail=tail * r.uniform(0.8, 1.25), off=(off[0], off[1] * r.uniform(0.85, 1.15)), flick=r.uniform(*flick),
                   curl=sgn * r.uniform(*curl), n=n, nt=nt, k=r.uniform(0.88, 1.08), **make)
            if split:
                way = r.choice((-1, 1))
                h.lock(root, (a + way * split * r.uniform(0.8, 1.2), ph_end_a - r.uniform(2, 8)), width * r.uniform(0.4, 0.55),
                       bow=sgn * bow * r.uniform(0.5, 1.0), tail=tail * r.uniform(0.7, 1.0), off=(off[0], off[1] * r.uniform(1.0, 1.15)),
                       flick=r.uniform(*flick) + 10, curl=way * r.uniform(*curl), n=n, nt=nt, k=r.uniform(0.95, 1.1), **make)

    def ring(around, count, ph_root, ph_end, width, tail, off, flick=(20, 50), curl=(20, 50), turn=0.0, n=5, nt=4, **make):
        """A layer of locks rooted round the head at `ph_root`, each running down to `ph_end`, swung `turn`
        degrees round as it goes; no two alike."""
        for k in range(count):
            a = around[0] + (around[1] - around[0]) * (k + 0.5 + r.uniform(-0.3, 0.3)) / count
            sgn = 1 if k % 2 else -1
            h.lock((a, ph_root + r.uniform(-4, 4)), (a + turn + r.uniform(-10, 10), ph_end + r.uniform(-8, 8)), width * r.uniform(0.8, 1.2),
                   bow=sgn * r.uniform(0.05, 0.2), tail=tail * r.uniform(0.75, 1.3), off=(off[0], off[1] * r.uniform(0.85, 1.15)),
                   flick=r.uniform(*flick), curl=sgn * r.uniform(*curl), n=n, nt=nt, k=r.uniform(0.45, 0.55), **make)

    if solid:
        ring((70, 290), 7, 62, 80, 0.34, 0.12, (0.02, 0.03), flick=(8, 20), curl=(4, 12), nt=4, base=1.0, full=0.15, sharp=1.0, **flat)
        ring((48, 150), 5, 36, 70, 0.36, 0.16, (0.04, 0.04), turn=14, flick=(14, 28), curl=(4, 12), nt=5, base=1.0, full=0.15, sharp=1.0, **flat)
        ring((210, 312), 5, 36, 70, 0.36, 0.16, (0.04, 0.04), turn=-14, flick=(14, 28), curl=(4, 12), nt=5, base=1.0, full=0.15, sharp=1.0, **flat)
        ring((150, 210), 3, 36, 106, 0.38, 0.16, (0.04, 0.04), flick=(8, 20), curl=(4, 12), nt=5, base=1.0, full=0.15, sharp=1.0, **flat)
        for ends in ([58, 90, 122, 154], [-58, -90, -122, -154, 180]):
            fan(ends, 76, 0.58, 0.22, (0.12, 0.06), split=0, bow=0.14, ess=0.0, sweep=1, flick=(24, 40), curl=(0, 8), nt=5, nape=24,
                base=0.95, full=0.3, sharp=1.0, **flat)
    else:
        # the hem: short points under everything, round the back and the sides
        ring((70, 290), 9, 64, 86, 0.22, 0.14, (0.02, 0.03), flick=(15, 40), curl=(10, 25), nt=5, base=1.0, full=0.15, sharp=1.0)
        # the middle layer round the sides and the back, swung back from the face
        ring((48, 150), 7, 36, 74, 0.22, 0.2, (0.05, 0.05), turn=14, flick=(10, 30), curl=(10, 25), nt=6, base=1.0, full=0.15, sharp=1.0)
        ring((210, 312), 7, 36, 74, 0.22, 0.2, (0.05, 0.05), turn=-14, flick=(10, 30), curl=(10, 25), nt=6, base=1.0, full=0.15, sharp=1.0)
        ring((150, 210), 4, 36, 104, 0.22, 0.2, (0.05, 0.05), flick=(15, 35), curl=(10, 25), nt=6, base=1.0, full=0.15, sharp=1.0)
        # the top layer from the whorl, down round the sides and the back
        # the longest of all, so their points kick out past the shorter layers under them, never a cap over a fringe of shards
        fan([58, 90, 122, 154], 82, 0.46, 0.3, (0.17, 0.09), split=12, bow=0.16, ess=0.03, sweep=1, flick=(25, 55), curl=(15, 35), nt=6, nape=22, base=0.95, full=0.3, sharp=1.0)
        fan([-58, -90, -122, -154, 180], 82, 0.46, 0.3, (0.17, 0.09), split=12, bow=0.16, ess=0.03, sweep=1, flick=(25, 55), curl=(15, 35), nt=6, nape=22, base=0.95, full=0.3, sharp=1.0)
    # the top layer forward over the head to the brows: the fringe, broad at the root, overlapping, drawn to needles; the middle longest
    # it fans from its own point at the top of the front, so from the front its locks part outward, never run parallel
    F = (0.0, 16.0)
    # under it, a shorter, darker layer between its locks: the gaps read as dark wedges, as the catalog's, never a
    # curtain over the brows (the blind read of round 37)
    for a in (-76, -56, -36, -17, 1, 19, 38, 58, 78):
        h.lock((F[0] + a * 0.3 + r.uniform(-5, 5), F[1] + 10 + r.uniform(-4, 4)), (a + r.uniform(-4, 4), r.uniform(66, 72)), r.uniform(0.2, 0.25),
               bow=r.uniform(-0.08, 0.08), tail=0.1, off=(0.04, 0.12), flick=r.uniform(6, 16), curl=(1 if a > 0 else -1) * r.uniform(10, 25),
               n=7, nt=3, base=0.5, full=0.32, sharp=1.0, k=r.uniform(0.3, 0.4))
    # the fringe parts at its own point: no lock down the middle. The lead lock, to his right, is the biggest and longest
    for k, (a, ph, w) in enumerate(((-62, 76, 0.32), (-26, 86, 0.56), (26, 82, 0.4), (58, 74, 0.32))):
        h.lock((F[0] + a * 0.25 + r.uniform(-6, 6), F[1] + r.uniform(-4, 4)), (a, ph), w, bow=(1 if k % 2 else -1) * r.uniform(0.04, 0.12),
               ess=0.03, lift=0.03, tail=0.2, off=(0.1, 0.25 + r.uniform(-0.02, 0.02)), flick=r.uniform(14, 30),
               curl=(1 if a > 0 else -1) * (r.uniform(8, 18) if solid else r.uniform(15, 35)), n=8, nt=4,
               base=1.0, full=0.12, sharp=1.0, k=r.uniform(0.9, 1.06), **flat)
    # over the top, the outer locks: they lie broad over the crown and sweep forward and out
    fan([-62, -16, 30, 82], 64, 0.44, 0.22, (0.19, 0.27), split=0, bow=0.2, ess=0.04, sweep=1, flick=(6, 16), curl=(8, 18) if solid else (15, 35), spread=6, n=9,
        base=0.95, full=0.35, sharp=1.0, **flat)
    # the crown's accent: what makes the hair known in silhouette, as the catalog's (hair-read.md): thin crescents that
    # grow out of the top and fly outward low, never upright, their faces turned half to the front so they read as
    # blades, not wires or horns. Points in studs, the face's middle at y 0, the top of the mass near z 5.5.
    def crescent(points, width, facing=0.6, **make):
        line = []
        for q in am.smooth2([tuple(q) for q in points], 12):
            q = Vector(q)
            out = ((q - am.CENTRE).normalized() * (1 - facing) + Vector((0, 1, 0.25)).normalized() * facing).normalized()
            line.append((q, out))
        h.ribbon(line, width, **{**dict(full=0.3, sharp=1.2, root=0.9, k=1.0), **make})

    if accent == "split":   # two tips that run out along the top nearly level and lift past its shoulders, the bigger to his right
        crescent([(-0.1, 0.05, 5.5), (0.12, 0.04, 5.57), (0.34, 0.0, 5.58), (0.54, -0.04, 5.64), (0.7, -0.08, 5.78)], 0.17, root=0.7)
        crescent([(0.08, 0.0, 5.5), (-0.1, -0.01, 5.56), (-0.28, -0.04, 5.6), (-0.44, -0.07, 5.72)], 0.13, root=0.7)
    elif accent == "curl":   # one hook out of the top, up and over to his left
        crescent([(0.04, 0.04, 5.44), (0.1, 0.03, 5.6), (0.08, 0.0, 5.75), (-0.02, -0.02, 5.83), (-0.14, -0.03, 5.81), (-0.21, -0.03, 5.72)],
                 0.11, facing=0.85)
    elif accent == "hooks":   # three: the two tips and a smaller hook behind them, as a tousled top
        crescent([(-0.06, 0.06, 5.44), (0.12, 0.05, 5.55), (0.3, 0.01, 5.63), (0.44, -0.04, 5.73), (0.52, -0.07, 5.84)], 0.12)
        crescent([(0.06, 0.02, 5.44), (-0.1, 0.01, 5.54), (-0.24, -0.02, 5.62), (-0.34, -0.05, 5.72)], 0.09)
        crescent([(0.02, -0.12, 5.42), (0.05, -0.14, 5.58), (0.0, -0.17, 5.7), (-0.1, -0.2, 5.74), (-0.17, -0.22, 5.68)], 0.08, facing=0.8)
    return h


class Spikes(Ribbons):
    """Hair as Anime Vanguards makes its units' (hair-read.md, "Against Anime Vanguards"): a lock is a solid spike, not
    a ribbon. Its section is a lens, five points over its top with its ridge off the middle and two under it, smooth
    across so the light sweeps over it, hard at its two sides so its edge is crisp. One colour, darker toward the root,
    with the occlusion baked in: the engine's light draws the sweep. Laid by `Ribbons.lock` and `free`, as the ribbons
    were. (A four-point diamond, flat or smooth, read as folded paper and crumpled foil: the blind reads of 2026-11-26.)"""

    segs = 9                  # rings along a spike, its point included
    rise, keel = 0.2, 0.12    # the ridge's height over the spike and the keel's depth under it, of its width
    crown = 2.0               # the section's top: 2 a dome across the lock, 1 a ridge with a plane each side
    lean = 0.35               # how far off the middle the ridge runs, of the half width: the broad face mostly to the light
    root_tone = 0.5           # a spike's colour at its root, of its colour from its middle on
    under_tone = 0.7          # its keel's colour, of its top's
    along = True              # smooth along its length; False, every face flat
    hard = (0, 4)             # which of its long edges stay hard: 0 and 4 its sides, 2 its ridge, 5 and 6 under
    ao_reach, ao_floor, ao_rays = 0.35, 0.2, 32   # the baked occlusion: how far a point looks, its darkest, its rays

    def ribbon(self, line, width, full=0.22, sharp=1.0, root=0.85, tall=None, tilt=0.0, gloss=None, k=1.0, size=None, segs=None):
        segs = segs or self.segs
        pts, outs = [q for q, _ in line], [o for _, o in line]
        cum = [0.0]
        for a, b in zip(pts, pts[1:]):
            cum.append(cum[-1] + (b - a).length)
        line = []
        for i in range(segs):   # evenly along its length, so its planes are of one size
            s = cum[-1] * i / (segs - 1)
            j = int(min(max(np.searchsorted(cum, s) - 1, 0), len(pts) - 2))
            t = (s - cum[j]) / max(cum[j + 1] - cum[j], 1e-9)
            line.append((pts[j].lerp(pts[j + 1], t), outs[j].lerp(outs[j + 1], t)))
        n, pts = len(line), [q for q, _ in line]
        mid = (pts[n // 2 + 1] - pts[n // 2 - 1]).normalized()
        o_mid = line[n // 2][1] - mid * line[n // 2][1].dot(mid)
        flip = 1.0 if mid.cross(o_mid.normalized()).dot(KEY) >= 0 else -1.0
        if self.rng.uniform() < 0.25:
            flip = -flip
        ease = lambda x: (lambda v: v * v * (3 - 2 * v))(min(max(x, 0.0), 1.0))  # noqa: E731
        # the section, a lens: five points over its top, its ridge off the middle, two under it; across, each point's
        # place (1 one side, -1 the other) and its column in the lock's colours (0 to 2 its top, 3 to 4 under it)
        top_x, under_x = (1.0, 0.55, 0.0, -0.55, -1.0), (-0.5, 0.5)
        cols = [1 - x for x in top_x] + [3 + (1 - abs(x)) for x in under_x]
        rings, shades = [], []
        for i, (q, out) in enumerate(line):
            u = i / (n - 1)
            along = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            out = out - along * out.dot(along)
            out = out.normalized() if out.length > 1e-4 else along.orthogonal().normalized()
            if tilt:
                out = Matrix.Rotation(math.radians(tilt * (1 - 0.6 * u)), 3, along) @ out
            side = along.cross(out).normalized()
            v = min(u / full, 1.0)
            w = width / 2 * (root + (1 - root) * ease(v) if u <= full else 1 - ((u - full) / (1 - full)) ** sharp)
            c = self.lit * k * (self.root_tone + (1 - self.root_tone) * ease(u / 0.5))
            shades.append([c, c, c, c * self.under_tone, c * self.under_tone])
            if i == n - 1:
                rings.append([self._vert(q)] * len(cols))
                continue
            ring = [q + side * (w * (x - flip * self.lean * (1 - x * x))) + out * (self.rise * 2 * w * (1 - abs(x) ** self.crown))
                    for x in top_x]
            ring += [q + side * (w * x) - out * (self.keel * 2 * w * (1 - x * x)) for x in under_x]
            rings.append([self._vert(p) for p in ring])
        strip = len(self.strips)
        self.strips.append(np.clip(np.array(shades, np.float32), 0, 1))
        if not hasattr(self, "spines"):
            self.spines = []
        self.spines.append((strip, rings))
        m = len(cols)
        for j, (lo, hi) in enumerate(zip(rings, rings[1:])):
            centre = (pts[j] + pts[j + 1]) / 2
            for a in range(m):
                b = (a + 1) % m
                if j < n - 2:
                    f = self.bm.faces.new((lo[a], hi[a], hi[b], lo[b]))
                    where = [(j, cols[a]), (j + 1, cols[a]), (j + 1, cols[b]), (j, cols[b])]
                else:
                    f = self.bm.faces.new((lo[a], hi[0], lo[b]))
                    where = [(j, cols[a]), (j + 1, (cols[a] + cols[b]) / 2), (j, cols[b])]
                f.normal_update()
                if f.normal.dot(f.calc_center_median() - centre) < 0:   # wound outward: the game draws a face's front only
                    f.normal_flip()
                    where = [where[0]] + where[1:][::-1]
                f.smooth = self.along   # smooth, so the light sweeps across the lock as one surface
                self.charts.append((f, strip, where))
            for a in self.hard:   # the long edges kept hard: its two sides (0 and 4) give a crisp edge
                edge = self.bm.edges.get((lo[a], hi[a] if j < n - 2 else hi[0]))
                if edge is not None:
                    edge.smooth = False
        self.locks += 1

    def dome(self, low=44.0, off=(0.09, 0.02), tone=0.85, rim=0.6, segments=32):
        """The crown as one mass, as the bar's (the blind reads of 2026-11-26: a crown of many locks meeting at the
        whorl reads crumpled from the top and the back): a smooth dome from the top to `low` degrees down, `off[0]`
        over the head at the top and tucking to `off[1]` at its rim, so its edge sinks under the locks that leave it.
        One tone, `tone` of the locks' own, to `rim` of that at its edge; the locks' occlusion darkens it under them."""
        phs = [0.5, 8.0, 16.0, 24.0, 32.0, 38.0, low]
        grid = [[(lambda f: f[0] + f[1] * (off[0] + (off[1] - off[0]) * (ph / low) ** 2))(self.at(-180 + 360 * i / segments, ph))
                 for i in range(segments)] for ph in phs]

        def paint(u, v, P, N):
            ease = (lambda y: y * y * (3 - 2 * y))(np.clip(v, 0, 1))
            return np.broadcast_to(self.lit * tone, u.shape + (3,)) * (1 - (1 - rim) * ease)[..., None]

        self.sheet(grid, paint, (64, 32), lambda mid, r, c: mid - am.CENTRE, closed=True)

    def build(self, folder, name="Hair"):
        self.occlude()
        return super().build(folder, name)

    def occlude(self):
        """The occlusion baked into each spike's colours, point by point: rays from each point over its own side of
        the hair, and the share that meet hair or the cap within `ao_reach` darken it, to `ao_floor` at the most. So a
        spike darkens where it tucks under its neighbour, at its root and along the cap: the hair's depth in the
        picture, as the catalog's (hair-read.md), and it holds whatever the engine's light does."""
        from mathutils.bvhtree import BVHTree
        self.bm.normal_update()
        tree = BVHTree.FromBMesh(self.bm)
        rng = np.random.default_rng(7)
        u1, u2 = rng.random(self.ao_rays), rng.random(self.ao_rays)
        rays = [Vector((math.sqrt(a) * math.cos(2 * math.pi * b), math.sqrt(a) * math.sin(2 * math.pi * b), math.sqrt(1 - a)))
                for a, b in zip(u1, u2)]   # cosine-weighted, round +Z
        seen = {}

        def lit(v):
            if v not in seen:
                n = v.normal
                if n.length < 1e-6:
                    seen[v] = 1.0
                else:
                    turn = Vector((0, 0, 1)).rotation_difference(n).to_matrix()
                    o = v.co + n * 0.004
                    hits = sum(tree.ray_cast(o, turn @ d, self.ao_reach)[0] is not None for d in rays)
                    seen[v] = self.ao_floor + (1 - self.ao_floor) * (1 - hits / len(rays))
            return seen[v]

        for strip, rings in self.spines:
            s = self.strips[strip]
            for i, ring in enumerate(rings):
                left, ridge, right = lit(ring[0]), lit(ring[2]), lit(ring[4])
                s[i, 0] *= left
                s[i, 1] *= ridge
                s[i, 2] *= right
                s[i, 3] *= (left + right) / 2
                s[i, 4] *= (lit(ring[5]) + lit(ring[6])) / 2


def rook_spikes():
    """Rook's cut as the bar's big-spike heads (hair-read.md, "Against Anime Vanguards"): about 21 thick wedges, each
    a long ridge with a plane either side running its whole length, straight enough that no plane folds across it.
    Six lie under round the sides and the back; six make the outline from a whorl near the top, kicking out over the
    ears and down and out at the back; two short broad points lift out of the crown; three lie forward over the crown;
    four fall from the fringe's own point to the brows, the lead to his right. Charcoal, darker at the roots and where
    one tucks under the next, a low sheen."""
    h = Spikes("#2A2A2B", "#0B0B0C", "#626266", seed=5)
    h.spec, h.rough, h.root_tone, h.rise, h.keel, h.crown, h.segs = 0.2, 0.5, 0.5, 0.3, 0.16, 1.3, 6
    h.ao_reach, h.ao_floor = 0.4, 0.15
    h.cap(am.hairline(front=4.94, temple=4.58, nape=4.3))
    r, W = h.rng, (180.0, 12.0)

    def wedge(root, end, width, tail, flick, curl=0.0, off=(0.04, 0.1), bow=0.0, n=6, nt=3, lift=0.0, **make):
        h.lock(root, end, width * r.uniform(0.95, 1.05), bow=bow, lift=lift, tail=tail * r.uniform(0.92, 1.08), off=off,
               flick=flick + r.uniform(-3, 3), curl=curl, n=n, nt=nt, k=r.uniform(0.95, 1.05),
               **{**dict(base=0.9, full=0.25, sharp=0.9), **make})

    for a, ph in ((70, 90), (112, 94), (152, 98), (208, 98), (248, 94), (290, 90)):   # under, round the sides and back
        side = 1 if a < 180 else -1
        wedge((a - side * 4, 50), (a + side * 10, ph), 0.78, 0.16, 14, off=(0.0, 0.04))
    for a, ph, w, t, fl in ((80, 76, 0.85, 0.36, 48), (126, 88, 0.85, 0.32, 34), (164, 96, 0.82, 0.3, 26),   # the outline
                            (196, 96, 0.82, 0.3, 26), (234, 88, 0.85, 0.32, 34), (280, 76, 0.85, 0.36, 48)):
        side = 1 if a < 180 else -1
        wedge((W[0] - side * 16, W[1] + 8), (a, ph), w, t, fl, off=(0.04, 0.2), n=7)
    for a, ph, w in ((146, 34, 0.72), (212, 30, 0.64)):   # two short broad points lift out of the crown
        wedge((180 + (a - 180) * 0.3, 6), (a, ph), w, 0.3, 52, off=(0.2, 0.24), n=5)
    for a, ph in ((-52, 60), (2, 50), (50, 62)):   # forward over the crown, sweeping out to the fringe's sides
        side = 1 if a > 0 else -1 if a < 0 else 0
        wedge((W[0] - side * 10, W[1] + 2), (a, ph), 0.9, 0.22, 14, off=(0.03, 0.26), bow=side * 0.05, n=8, lift=0.05)
    F = (0.0, 14.0)
    for a, ph, w in ((-46, 74, 0.6), (-16, 80, 0.78), (14, 77, 0.66), (42, 72, 0.6)):   # the fringe, the lead to his right
        side = 1 if a > 0 else -1
        wedge((F[0] + a * 0.3, F[1]), (a, ph), w, 0.2, 18, off=(0.12, 0.2), bow=side * 0.04, n=7, lift=0.02)
    return h


def rook_wedges(planes=False, signature=None):
    """Rook's cut as the bar's heads (hair-read.md, "Against Anime Vanguards"; the blind reads of 2026-11-26): 24
    rounded wedges from a whorl at the back of the crown, swept one way, over a smooth crown mass, in a plain order of
    size: heroes and small points. Four mid ones lie under round the back and sides, and one over each ear; over them
    five big leaders of uneven length leave the head's outline, out over each ear and down and out at the back, with
    four small points tucked between their tips; three lie forward over the crown, close to it; the fringe is three
    big locks to the brows, the lead to his right the biggest, with three small points between. Matte charcoal leaning cool, rounded across, no hotspot, darker at the roots,
    under each lock and deep in the crack where one tucks under the next. (Two flat planes with a hard ridge read as
    folded paper: the blind read of 2026-11-26, 14:08.)"""
    h = Spikes("#29292C", "#070709", "#626266", seed=5)   # near neutral: a cool lean, never grey-blue
    h.spec, h.rough, h.root_tone, h.rise, h.keel, h.crown, h.segs = 0.06, 0.62, 0.4, 0.3, 0.14, 1.6, 7
    h.under_tone, h.ao_reach, h.ao_floor = 0.35, 0.45, 0.06
    if planes:   # each lock two flat planes with a hard step at its ridge, mid dark, no sheen (the blind read of 14:07)
        h = Spikes("#262628", "#0A0A0B", "#626266", seed=5)
        h.spec, h.rough, h.root_tone, h.rise, h.keel, h.crown, h.segs = 0.04, 0.75, 0.6, 0.32, 0.14, 1.0, 7
        h.hard, h.lean, h.ao_reach, h.ao_floor = (0, 2, 4), 0.15, 0.4, 0.2
    h.cap(am.hairline(front=4.94, temple=4.58, nape=4.3))
    h.scalp = h.lit * 0.25   # dark under the locks, so each crack reads, but not a black band at the brow
    h.dome(low=62.0, off=(0.1, 0.03))
    r, W = h.rng, (180.0, 26.0)

    def wedge(root, end, width, tail, flick, curl=0.0, off=(0.04, 0.1), bow=0.0, n=6, nt=3, lift=0.0, **make):
        h.lock(root, end, width * r.uniform(0.94, 1.06), bow=bow, lift=lift, tail=tail * r.uniform(0.9, 1.1), off=off,
               flick=flick + r.uniform(-3, 3), curl=curl, n=n, nt=nt, k=r.uniform(0.94, 1.05), tilt=8.0,
               **{**dict(base=0.9, full=0.25, sharp=r.uniform(0.75, 1.3)), **make})   # tips of uneven taper

    def tier(around, count, ph_root, ph_end, width, tail, flick, off, swing=12.0, **kw):
        for i in range(count):   # tiles laid edge over edge, every one turned the same way
            a = around[0] + (around[1] - around[0]) * (i + 0.5 + r.uniform(-0.15, 0.15)) / count
            back = swing if (a % 360) < 180 else -swing
            wedge((a, ph_root + r.uniform(-3, 3)), (a + back, ph_end + r.uniform(-4, 4)), width, tail, flick, off=off,
                  curl=(-1 if back > 0 else 1) * 6, **kw)

    tier((70, 290), 4, 56, 90, 0.62, 0.14, 8, (0.02, 0.05))     # the hem: four small ones tucked between
    for a in (74, 286):   # one down each side over the ear's top, so no gap shows the scalp from three-quarter
        side = 1 if a < 180 else -1
        wedge((a, 44), (a + side * 6, 90), 0.62, 0.16, 8, curl=-side * 4, off=(0.02, 0.06))
    # the five leaders leave the outline: flaring out over each ear, down and out at the back, gaps between their points
    for a, ph, w, t, fl in ((80, 84, 1.0, 0.52, 44), (130, 96, 1.04, 0.42, 26), (180, 106, 1.0, 0.44, 18),
                            (230, 94, 1.04, 0.36, 26), (280, 80, 1.0, 0.4, 44)):   # the heroes, uneven: his left the longest
        side = 1 if a < 180 else -1 if a > 180 else 0
        wedge((W[0] - side * 18 + r.uniform(-3, 3), W[1] + 8), (a, ph), w, t, fl, curl=-side * 8, off=(0.0, 0.13), n=7)
    for a in (106, 156, 204, 254):   # small points tucked between the heroes, poking out under their tips
        side = 1 if a < 180 else -1
        wedge((a - side * 4, 50), (a + side * 8, 96), 0.36, 0.24, 30, curl=-side * 6, off=(0.02, 0.1), n=6)
    for a, ph, w in ((-52, 60, 0.68), (0, 54, 0.66), (52, 62, 0.68)):   # forward over the crown, close to it
        side = 1 if a > 0 else -1 if a < 0 else 0
        wedge((W[0] - side * 12 + r.uniform(-3, 3), W[1] + r.uniform(-2, 2)), (a, ph), w, 0.2, 14, curl=side * 8,
              off=(0.04, 0.22), bow=side * 0.06, n=8, lift=0.05)
    F = (0.0, 14.0)
    # signature (the outline study, 2026-11-26, 14:30: the make holds at "close", and what's left is the cut's own outline;
    # every bar hair has one). "sweep": the fringe swept from a part over his left to his right, its lead past the
    # cheekbone outside the eye, so the face-on outline is uneven. "wolf": the nape runs down in long points and a piece
    # falls before each ear to the jaw, so the back, the fight camera's view, has a shape of its own.
    sweep = signature == "sweep"
    fringe = (((-80, 94, 0.42), (-58, 100, 0.9), (-32, 90, 0.6), (-6, 86, 0.34), (18, 80, 0.56), (44, 72, 0.3)) if sweep else
              ((-62, 76, 0.32), (-36, 82, 0.66), (-6, 86, 0.84), (14, 84, 0.3), (34, 80, 0.62), (56, 74, 0.32)))
    for a, ph, w in fringe:
        side = -1 if sweep else 1 if a > 0 else -1   # the fringe, to the brows, uneven, the lead to his right
        root = (30 + a * 0.2, F[1]) if sweep else (F[0] + a * 0.3, F[1])
        wedge((root[0] + r.uniform(-3, 3), root[1] + r.uniform(-2, 2)), (a, ph), w, 0.18, 26 + abs(a) * 0.2, curl=side * 14,
              off=(0.12, 0.2), bow=side * 0.04, n=7, lift=0.02)
    if signature == "wolf":
        for a, ph in ((150, 102), (180, 106), (210, 102)):   # the nape's long points, hanging clear of the back
            side = 1 if a < 180 else -1 if a > 180 else 0
            wedge((a - side * 6, 70), (a + side * 4, ph), 0.66, 0.5, 18, curl=-side * 6, off=(0.03, 0.07), n=7)
        for a in (64, 296):   # a piece before each ear, to the jaw
            side = 1 if a < 180 else -1
            wedge((a, 50), (a + side * 4, 108), 0.46, 0.22, 16, curl=-side * 6, off=(0.02, 0.06), n=7)
    return h

TIE = (180, 15)


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
    for dx, lift, drop, back, w in ((0.0, 0.9, -1.5, 0.8, 0.62), (0.3, 0.8, -1.22, 0.74, 0.54), (-0.3, 0.8, -1.3, 0.74, 0.54),
                                    (0.56, 0.62, -0.86, 0.6, 0.46), (-0.56, 0.62, -0.76, 0.6, 0.46), (0.12, 1.0, -0.98, 0.92, 0.46),
                                    (-0.14, 0.96, -1.1, 0.9, 0.46)):
        h.blade([tie, tie + Vector((dx * 0.7, -0.12, lift)), tie + Vector((dx, -back, lift * 0.5)),
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
    "rook": dict(takes={"Rook": rt.take_a, "A": with_hair(rt, rt.take_a, rook), "T": with_hair(rt, rt.take_a, rook_sheets),
                        "R": with_hair(rt, rt.take_a, rook_ribbons),
                        **{f"R{k[0].upper()}": with_hair(rt, rt.take_a, lambda k=k: rook_ribbons(k)) for k in ("split", "curl", "hooks")},
                       "RP": with_hair(rt, rt.take_a, lambda: rook_ribbons("split", solid=True)),
                       "SK": with_hair(rt, rt.take_a, rook_spikes),
                       "SW": with_hair(rt, rt.take_a, rook_wedges),
                       "SP": with_hair(rt, rt.take_a, lambda: rook_wedges(planes=True)),
                       "SS": with_hair(rt, rt.take_a, lambda: rook_wedges(signature="sweep")),
                       "SL": with_hair(rt, rt.take_a, lambda: rook_wedges(signature="wolf")),
                       "RF": with_hair(rt, rt.take_a, lambda: rook_ribbons("split", flat_paint=True))},
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
    elif mode in ("bare", "match", "alone"):   # the head with no hair or with the take's, in the drawn designs' views;
        # `alone`: the hair by itself from over the face, as the catalog pictures its own
        key = "Bare" if mode == "bare" else rest[2]
        module = rt if who == "rook" else kt
        scene = bl.reset_scene()
        scene.world = bpy.data.worlds.new("Takes")
        j = rt.wt.rig(scene)
        (OUT / "tex" / key).mkdir(parents=True, exist_ok=True)
        run = with_hair(module, module.take_a, lambda: am.Hair("#000000", "#000000")) if mode == "bare" else spec["takes"][key]
        made = run(j, OUT / "tex" / key)
        if mode != "bare":
            measured(key, made)
        j["root"].location = rt.wt.PIVOTS["root"]
        bpy.context.view_layer.update()
        views = (("front", 180, 2), ("three", 145, 2), ("side", 90, 2), ("back", 0, 2), ("top", 180, 60))
        if mode == "alone":
            for name, piece in made.items():
                piece.hide_render = name != "hair"
            views = (("over", 180, 24), ("over3", 150, 24), ("overback", 30, 24))
        for view, azimuth, elevation in views:
            rt.rm.eevee(scene, 1000, 1000)
            rt.rm.sun_for(scene, azimuth)
            am.fill_for(scene, azimuth)
            rs.shoot(scene, OUT / "shots" / f"{key}_{view}.png", azimuth, elevation, (0.0, 0.0, 4.85), 3.2)
