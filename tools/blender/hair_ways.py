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

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

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


# --- sculpted: a few big forms made one surface ------------------------------------------------------------------------

class Sculpted(Solid):
    """The director, 2026-11-24, by 22:20, on the study's takes: "ur hair is still horrible". Anime Vanguards' hair is one
    sculpted surface of a few big forms, smooth, creased where two forms meet, lit broadly. So: a dozen or so big round
    forms (Solid's), merged into one surface by a voxel remesh, smoothed, cut down to the game's count; its picture
    painted from its own shape: dark where the surface is shut in (the creases), light where it's open, a band of light."""

    def __init__(self, dark, light, sheen, voxel=0.022, tris=5000, seed=1, band=(0.5, 0.14, 0.5)):
        super().__init__(dark, light, seed=seed, band=band)
        self.tones = [np.array(rs.srgb(c)[:3]) for c in (dark, light, sheen)]
        self.voxel, self.tris = voxel, tris

    def _surface(self, obj):
        """The forms made one surface: remeshed, smoothed, cut down to about `tris` triangles."""
        for o in bpy.context.selected_objects:
            o.select_set(False)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        for kind, opts in (("SOLIDIFY", dict(thickness=0.06, offset=0.0)),   # the open forms closed, so the voxels fill
                           ("REMESH", dict(mode="VOXEL", voxel_size=self.voxel, adaptivity=0.0)),
                           ("SMOOTH", dict(factor=0.5, iterations=2)),
                           ("DECIMATE", dict(ratio=1.0))):
            m = obj.modifiers.new(kind, kind)
            for k, v in opts.items():
                setattr(m, k, v)
            if kind == "DECIMATE":
                m.ratio = min(1.0, self.tris / max(len(obj.data.polygons) * 2, 1))
            bpy.ops.object.modifier_apply(modifier=m.name)

    def _colours(self, mesh):
        """Each point's colour: how open it is to the sky over it (40 rays), dark in the creases, light in the open,
        with the band of light on what faces up."""
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bm.normal_update()
        tree = BVHTree.FromBMesh(bm)
        dirs = np.random.default_rng(7).normal(size=(40, 3))
        dirs = [Vector(d / np.linalg.norm(d)) for d in dirs]
        dark, light, sheen = self.tones
        z, wide, strength = self.band
        out = np.zeros((len(bm.verts), 3), np.float32)
        for v in bm.verts:
            nrm, hits, seen = v.normal, 0, 0
            for d in dirs:
                if d.dot(nrm) <= 0.05:
                    continue
                seen += 1
                hits += tree.ray_cast(v.co + nrm * 0.004, d, 0.45)[0] is not None
            t = float(np.clip((1 - hits / max(seen, 1) - 0.35) / 0.6, 0, 1)) ** 1.4
            c = dark + (light - dark) * t
            g = strength * math.exp(-((v.co.z - am.CENTRE.z - z) / wide) ** 2) * max(0.0, nrm.z * 0.5 + 0.5) * t
            out[v.index] = c + (sheen - c) * g
        bm.free()
        return out

    def build(self, folder, name="Hair"):
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        self._surface(obj)
        cols = self._colours(obj.data)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.quads_convert_to_tris()
        bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.01)
        bpy.ops.object.mode_set(mode="OBJECT")
        size = 512
        px = np.zeros((size, size, 3), np.float32)
        done = np.zeros((size, size), bool)
        uvl = obj.data.uv_layers.active.data
        for poly in obj.data.polygons:   # each triangle painted by its corners' colours, a little past its edges
            poly.use_smooth = True
            loops = list(poly.loop_indices)[:3]
            uv = np.array([uvl[li].uv[:] for li in loops]) * (size - 1)
            cc = cols[[obj.data.loops[li].vertex_index for li in loops]]
            x0, y0 = np.floor(uv.min(0)).astype(int) - 1
            x1, y1 = np.ceil(uv.max(0)).astype(int) + 2
            xs, ys = np.meshgrid(np.arange(max(x0, 0), min(x1, size)), np.arange(max(y0, 0), min(y1, size)))
            (ax, ay), (bx, by), (cx, cy) = uv
            den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(den) < 1e-9 or xs.size == 0:
                continue
            w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
            w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
            w = np.stack([w0, w1, 1 - w0 - w1], -1)
            inside = (w > -0.08).all(-1)
            if not inside.any():
                continue
            w = np.clip(w[inside], 0, 1)
            px[size - 1 - ys[inside], xs[inside]] = (w / w.sum(-1, keepdims=True)) @ cc
            done[size - 1 - ys[inside], xs[inside]] = True
        for _ in range(6):   # each island's colour bled past its edge, so no seam shows where the game filters
            grow = np.zeros_like(px)
            count = np.zeros((size, size), np.float32)
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                m = np.roll(done, (dy, dx), (0, 1))
                grow += np.roll(px, (dy, dx), (0, 1)) * m[..., None]
                count += m
            new = ~done & (count > 0)
            px[new] = grow[new] / count[new][:, None]
            done |= new
        px[~done] = cols.mean(0)
        px = np.clip(px, 0, 1)
        px = np.where(px <= 0.0031308, px * 12.92, 1.055 * px ** (1 / 2.4) - 0.055).astype(np.float32)
        mat = am.textured(name, px, folder)
        mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
        mat.use_backface_culling = True
        obj.data.materials.append(mat)
        am.PICTURES[obj.name] = px
        print(f"sculpted hair: {len(obj.data.polygons)} triangles")
        return obj


def rook_sculpt():
    h = Sculpted("#030304", "#11131C", "#525C80", seed=8, band=(0.6, 0.16, 0.65))
    h.shell(am.hairline(front=4.9, temple=4.6, nape=4.2))
    big = dict(taper=0.95, depth=0.22, rise=0.3)   # a flat lens in section, drawn to a point: the tutorials' profile
    for a, ph, length, width, heading in ((-38, 18, 1.0, 0.62, -10), (-8, 14, 1.12, 0.7, 6), (24, 16, 1.06, 0.66, 18),
                                          (52, 26, 0.86, 0.56, 22)):                                 # the fringe, four
        h.lay(a, ph, length, width, heading=heading, bend=6, off=0.14, flick=14, hold=0.8, **big)
    for s in (-1, 1):                                                                               # each side, two
        h.lay(s * 78, 36, 1.0, 0.6, heading=-s * 6, off=0.08, flick=16, hold=0.75, **big)
        h.lay(s * 112, 44, 0.95, 0.62, off=0.08, flick=26, hold=0.6, **big)
    for a in (140, 180, 220):                                                                       # the back, three
        h.lay(a, 50, 0.95, 0.72, off=0.08, flick=34, hold=0.5, **big)
    for a, length in ((-60, 0.95), (-20, 1.05), (20, 1.0), (60, 0.95)):                         # the top, lifted, out to the back
        h.lay(a, 30, length, 0.62, off=0.2, flick=40, hold=0.35, comb=BACK, **big)
    return h


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
    "rook": dict(takes={"Rook": rt.take_a, **{k: with_hair(rt, rt.take_a, lambda k=k: rook(k)) for k in "ABC"},
                        "S": with_hair(rt, rt.take_a, rook_sculpt)},
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
