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
    "rook": dict(takes={"Rook": rt.take_a, "A": with_hair(rt, rt.take_a, rook), "T": with_hair(rt, rt.take_a, rook_sheets)},
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
    elif mode in ("bare", "match"):   # the head alone, with no hair or with the take's, in the drawn designs' three views
        key = "Bare" if mode == "bare" else rest[2]
        module = rt if who == "rook" else kt
        scene = bl.reset_scene()
        scene.world = bpy.data.worlds.new("Takes")
        j = rt.wt.rig(scene)
        (OUT / "tex" / key).mkdir(parents=True, exist_ok=True)
        run = with_hair(module, module.take_a, lambda: am.Hair("#000000", "#000000")) if mode == "bare" else spec["takes"][key]
        made = run(j, OUT / "tex" / key)
        if mode == "match":
            measured(key, made)
        j["root"].location = rt.wt.PIVOTS["root"]
        bpy.context.view_layer.update()
        for view, azimuth, elevation in (("front", 180, 2), ("three", 145, 2), ("side", 90, 2), ("back", 0, 2), ("top", 180, 60)):
            rt.rm.eevee(scene, 1000, 1000)
            rt.rm.sun_for(scene, azimuth)
            am.fill_for(scene, azimuth)
            rs.shoot(scene, OUT / "shots" / f"{key}_{view}.png", azimuth, elevation, (0.0, 0.0, 4.85), 3.2)
