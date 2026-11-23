"""The make of a Voidkin on the R6 body (AR59's redo, research, 2026-11-23): the way the genre's Roblox games make a
unit, which is what reads as anime at that size.

    the body   R6's six plain blocks, nothing built on them; the clothes are a picture drawn on the blocks' faces:
               flat colours, a soft painted shade, drawn fold lines, trims, a belt;
    the head   Roblox's round head, with an anime face drawn on it: almond eyes with a coloured iris and a light, a
               lash line, thin brows, a tick for the nose, a short mouth;
    the hair   one dense smooth mesh: dozens of thin tapering locks over a shell, shaded root to tip;
    built      few pieces and thin ones, none thicker than the limb it sits on.

This file is the kit, and a plain stand-in with no design in it to judge the make by:

    blender.exe -b --factory-startup --python tools/blender/anime_make.py -- <out_dir>

writes the pictures drawn on the blocks to <out_dir>/tex and the stand-in's views to <out_dir>/shots (Eevee, no GPU
turn). Studs, X his right, Y forward, Z up; he faces +Y, feet on z 0. A drawn face is laid out in studs as the viewer
sees it: x to the viewer's right, y up.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402

PPU = 128          # texels a stud on the body
FACE_PPU = 256     # and on the head
R = 0.625          # the head's radius
CHIN = 3.875       # the head's lowest point
CENTRE = Vector((0.0, 0.0, 4.5))  # the scalp's middle
SCALP, SCALP_TOP = 0.685, 0.69    # the hair's shell: its radius, and its top above the middle
INK = "#1B161A"


# --- drawing ---------------------------------------------------------------------------------------------------------

def rgb(colour):
    if isinstance(colour, str):
        return np.array([int(colour[i:i + 2], 16) / 255 for i in (1, 3, 5)], dtype=np.float32)
    return np.asarray(colour, dtype=np.float32)


def tone(colour, k):
    """A colour made darker (k under 1) or lighter."""
    return np.clip(rgb(colour) * k, 0, 1)


def mix(a, b, u):
    return rgb(a) * (1 - u) + rgb(b) * u


def smooth2(pts, n):
    """A curve through the points, `n` samples of it."""
    P = np.array(pts, dtype=np.float64)
    if len(P) == 2:
        return P[0] + (P[1] - P[0]) * np.linspace(0, 1, n)[:, None]
    Q = np.vstack([2 * P[0] - P[1], P, 2 * P[-1] - P[-2]])
    out, segs = [], len(P) - 1
    for s in np.linspace(0, segs, n):
        i = min(int(s), segs - 1)
        t = s - i
        p0, p1, p2, p3 = Q[i], Q[i + 1], Q[i + 2], Q[i + 3]
        out.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (3 * p1 - p0 - 3 * p2 + p3) * t ** 3))
    return np.array(out)


def blur(a, radius):
    r = int(round(radius))
    if r < 1:
        return a
    for axis in (0, 1):
        n = a.shape[axis]
        for _ in range(2):
            pad = [(0, 0), (0, 0)]
            pad[axis] = (r + 1, r)
            c = np.cumsum(np.pad(a, pad, mode="edge"), axis=axis, dtype=np.float64)
            a = ((np.take(c, np.arange(2 * r + 1, 2 * r + 1 + n), axis=axis) - np.take(c, np.arange(n), axis=axis))
                 / (2 * r + 1)).astype(np.float32)
    return a


class Paint:
    """A flat picture drawn in studs: x from x0 to x0 + w, left to right as the viewer sees it; y from 0 up to h.
    Every shape is a cover, 0 to 1 a texel, with a soft edge one texel wide; `lay` puts a colour through a cover."""

    def __init__(self, px, x0, w, h):
        self.px, self.x0, self.w, self.h = px, x0, w, h
        self.rows, self.cols = px.shape[:2]
        self.k, self.ky = self.cols / w, self.rows / h
        self.mid = x0 + w / 2
        xs = x0 + (np.arange(self.cols, dtype=np.float32) + 0.5) / self.k
        ys = h - (np.arange(self.rows, dtype=np.float32) + 0.5) / self.ky
        self.X, self.Y = np.meshgrid(xs, ys)

    def lay(self, cover, colour, alpha=1.0):
        a = (np.clip(cover, 0, 1) * alpha)[..., None]
        self.px[...] = self.px * (1 - a) + rgb(colour) * a

    def _win(self, x0, x1, y0, y1):
        c0, c1 = max(int((x0 - self.x0) * self.k) - 2, 0), min(int((x1 - self.x0) * self.k) + 3, self.cols)
        r0, r1 = max(int((self.h - y1) * self.ky) - 2, 0), min(int((self.h - y0) * self.ky) + 3, self.rows)
        return slice(r0, max(r1, r0)), slice(c0, max(c1, c0))

    def rect(self, x0, y0, x1, y1):
        return (np.clip((self.X - x0) * self.k + 0.5, 0, 1) * np.clip((x1 - self.X) * self.k + 0.5, 0, 1)
                * np.clip((self.Y - y0) * self.ky + 0.5, 0, 1) * np.clip((y1 - self.Y) * self.ky + 0.5, 0, 1))

    def rise(self, y0, y1):
        """0 at y0 running to 1 at y1 (either may be the higher)."""
        return np.clip((self.Y - y0) / (y1 - y0), 0, 1)

    def run(self, x0, x1):
        return np.clip((self.X - x0) / (x1 - x0), 0, 1)

    def poly(self, pts):
        P = np.array(pts, dtype=np.float32)
        win = self._win(P[:, 0].min(), P[:, 0].max(), P[:, 1].min(), P[:, 1].max())
        X, Y = self.X[win], self.Y[win]
        inside = np.zeros(X.shape, bool)
        dist = np.full(X.shape, 1e9, np.float32)
        for (x0, y0), (x1, y1) in zip(P, np.roll(P, -1, axis=0)):
            if y0 != y1:
                inside ^= ((y0 > Y) != (y1 > Y)) & (X < x0 + (Y - y0) * (x1 - x0) / (y1 - y0))
            dist = np.minimum(dist, _seg(X, Y, x0, y0, x1, y1)[0])
        out = np.zeros(self.X.shape, np.float32)
        out[win] = np.clip(0.5 + np.where(inside, dist, -dist) * self.k, 0, 1)
        return out

    def ellipse(self, cx, cy, rx, ry, turn=0.0):
        reach = max(rx, ry)
        win = self._win(cx - reach, cx + reach, cy - reach, cy + reach)
        c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))
        dx, dy = self.X[win] - cx, self.Y[win] - cy
        u, v = (dx * c + dy * s) / rx, (-dx * s + dy * c) / ry
        out = np.zeros(self.X.shape, np.float32)
        out[win] = np.clip((1 - np.sqrt(u * u + v * v)) * min(rx, ry) * self.k + 0.5, 0, 1)
        return out

    def stroke(self, pts, widths, n=28):
        """A line through the points, its width running through `widths` from one end to the other."""
        path = smooth2(pts, n)
        half = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(widths)), widths) / 2
        reach = half.max() + 2 / self.k
        win = self._win(path[:, 0].min() - reach, path[:, 0].max() + reach, path[:, 1].min() - reach, path[:, 1].max() + reach)
        X, Y = self.X[win], self.Y[win]
        cover = np.zeros(X.shape, np.float32)
        for i in range(n - 1):
            d, t = _seg(X, Y, *path[i], *path[i + 1])
            cover = np.maximum(cover, np.clip((half[i] + (half[i + 1] - half[i]) * t - d) * self.k + 0.5, 0, 1))
        out = np.zeros(self.X.shape, np.float32)
        out[win] = cover
        return out

    def soft(self, cover, studs):
        return blur(cover, studs * self.k)


def _seg(X, Y, x0, y0, x1, y1):
    dx, dy = x1 - x0, y1 - y0
    length = dx * dx + dy * dy
    t = np.clip(((X - x0) * dx + (Y - y0) * dy) / length, 0, 1) if length > 1e-12 else np.zeros_like(X)
    return np.hypot(X - (x0 + t * dx), Y - (y0 + t * dy)), t


def textured(name, pixels, folder):
    """A material that draws a picture, saved beside the others."""
    path = folder / f"{name}.png"
    rs.save(np.dstack([np.clip(pixels, 0, 1), np.ones(pixels.shape[:2], np.float32)]), path)
    m = bpy.data.materials.new(name)
    bsdf, nodes, links = bl._principled(m)
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(str(path))
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 1.0
    return m


# --- the body's blocks -------------------------------------------------------------------------------------------------

class Block:
    """One of R6's blocks with a picture on each face. `faces` are its six pictures; `wrap` is the four sides as one
    strip, x 0 at the front's middle, running round to the viewer's right, its seam at the back's far corner."""

    def __init__(self, name, centre, size, colour):
        self.name, self.centre, self.size = name, centre, size
        w, d, h = size
        self.px = np.empty((int(round((h + d) * PPU)), int(round(2 * (w + d) * PPU)), 3), np.float32)
        self.px[:] = rgb(colour)
        k, tall = PPU, int(round(h * PPU))
        # where each face sits in the picture, in studs from its left and from its top
        self.at = {"right": (0, 0, d, h), "front": (d, 0, w, h), "left": (d + w, 0, d, h), "back": (2 * d + w, 0, w, h),
                   "top": (0, h, w, d), "bottom": (w, h, w, d)}
        self.faces = {}
        for key, (x, y, fw, fh) in self.at.items():
            view = self.px[int(round(y * k)):int(round((y + fh) * k)), int(round(x * k)):int(round((x + fw) * k))]
            self.faces[key] = Paint(view, -fw / 2, fw, fh)
        self.wrap = Paint(self.px[:tall], -w / 2 - d, 2 * (w + d), h)

    @property
    def sides(self):
        return [self.faces[k] for k in ("right", "front", "left", "back")]

    def build(self, folder):
        (cx, cy, cz), (w, d, h) = self.centre, self.size
        world = {
            "front": lambda x, y: (cx - x, cy + d / 2, cz - h / 2 + y),
            "back": lambda x, y: (cx + x, cy - d / 2, cz - h / 2 + y),
            "right": lambda x, y: (cx + w / 2, cy + x, cz - h / 2 + y),
            "left": lambda x, y: (cx - w / 2, cy - x, cz - h / 2 + y),
            "top": lambda x, y: (cx + x, cy - d / 2 + y, cz + h / 2),
            "bottom": lambda x, y: (cx - x, cy - d / 2 + y, cz - h / 2),
        }
        rows, cols = self.px.shape[:2]
        bm = bmesh.new()
        uv = bm.loops.layers.uv.new("UVMap")
        inset = 0.5 / PPU
        for key, (ax, ay, fw, fh) in self.at.items():
            corners = [(-fw / 2, 0), (fw / 2, 0), (fw / 2, fh), (-fw / 2, fh)]
            f = bm.faces.new([bm.verts.new(world[key](x, y)) for x, y in corners])
            for loop, (x, y) in zip(f.loops, corners):
                u = ax + min(max(x + fw / 2, inset), fw - inset)
                v = ay + fh - min(max(y, inset), fh - inset)
                loop[uv].uv = (u * PPU / cols, 1 - v * PPU / rows)
        mesh = bpy.data.meshes.new(self.name)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.materials.append(textured(self.name, self.px, folder))
        return obj


def shade(block, dark, amount=0.3, low=0.5):
    """The painted shade: every side of a block darker toward its two edges and its foot."""
    for p in block.sides:
        edge = np.clip((np.abs(p.X - p.mid) - (p.w / 2 - 0.24)) / 0.24, 0, 1) ** 1.5
        foot = np.clip((low - p.Y) / low, 0, 1) * 0.6 if low > 0 else 0.0
        p.lay(np.maximum(edge, foot), dark, amount)


def folds(p, lines, colour, alpha=0.8):
    """Fold lines: each (points, widest), drawn to a point at both ends."""
    for pts, wide in lines:
        p.lay(p.stroke(pts, (0.0, wide, wide * 0.7, 0.0), n=20), colour, alpha)


# --- the head and its face ---------------------------------------------------------------------------------------------

class Head:
    """Roblox's round head, its picture wrapped once round it: x is the way round from the face's middle in studs,
    to the viewer's right, and y the height above the chin."""

    def __init__(self, skin):
        self.px = np.empty((int(round(1.25 * FACE_PPU)), int(round(2 * math.pi * R * FACE_PPU)), 3), np.float32)
        self.px[:] = rgb(skin)
        self.paint = Paint(self.px, -math.pi * R, 2 * math.pi * R, 1.25)

    def build(self, folder, segments=40):
        profile = [(0.0, 0.76), (0.045, 0.912), (0.145, 1.0), (1.105, 1.0), (1.205, 0.912), (1.25, 0.76)]
        bm = bmesh.new()
        uv = bm.loops.layers.uv.new("UVMap")
        grid = []
        for i in range(segments):
            a = (i / segments * 2 - 1) * math.pi
            grid.append([bm.verts.new((-R * share * math.sin(a), R * share * math.cos(a), CHIN + y)) for y, share in profile])
        for i in range(segments):
            n = (i + 1) % segments
            for k in range(len(profile) - 1):
                f = bm.faces.new((grid[i][k], grid[n][k], grid[n][k + 1], grid[i][k + 1]))
                f.smooth = True
                for loop, (col, row) in zip(f.loops, ((i, k), (i + 1, k), (i + 1, k + 1), (i, k + 1))):
                    loop[uv].uv = (col / segments, profile[row][0] / 1.25)
        for ring in ([g[-1] for g in grid], [g[0] for g in reversed(grid)]):
            f = bm.faces.new(ring)
            f.smooth = True
            for loop in f.loops:
                loop[uv].uv = (0.5, 0.006)  # skin, under the chin
        mesh = bpy.data.meshes.new("Head")
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new("Head", mesh)
        bpy.context.scene.collection.objects.link(obj)
        mesh.materials.append(textured("Head", self.px, folder))
        return obj


def draw_face(p, look):
    """An anime face. `look`: skin, iris, the eyes' size and place, their tilt (above zero lifts the outer corner),
    how far the lid is shut (0 open to 1), the brows' place and tilt, and the mouth's line."""
    skin = look["skin"]
    line = tone(skin, 0.55)
    # the skin's own shade: under the hair, and round toward the ears
    p.lay(p.rise(0.86, 1.12), tone(skin, 0.78), 0.55)
    p.lay(np.clip((np.abs(p.X) - 0.5) / 0.3, 0, 1), tone(skin, 0.86), 0.5)
    ew, eh, ex, ey = look["eye_w"], look["eye_h"], look["eye_x"], look["eye_y"]
    tilt, shut = look.get("tilt", 0.0), look.get("shut", 0.0)
    top = eh * (0.5 - 0.42 * shut)
    for s in (-1, 1):
        def at(lx, ly):
            return (s * (ex + lx), ey + ly)
        upper = [at(-ew / 2, -0.12 * eh), at(-0.27 * ew, top * 0.74), at(0.12 * ew, top), at(ew / 2, 0.16 * eh + tilt)]
        lower = [at(ew / 2, 0.16 * eh + tilt), at(0.3 * ew, -0.4 * eh), at(-0.18 * ew, -0.5 * eh), at(-ew / 2, -0.12 * eh)]
        shape = p.poly(np.vstack([smooth2(upper, 16), smooth2(lower, 16)[1:-1]]))
        p.lay(shape, "#F6F4F1")
        p.lay(shape * p.rise(ey + 0.02 * eh, ey + top), "#AEB6C8", 0.75)
        cx, cy = s * (ex + 0.02 * ew), ey + 0.0 * eh
        rx, ry = 0.3 * ew, 0.58 * eh
        iris = np.minimum(p.ellipse(cx, cy, rx, ry), shape)
        p.lay(iris, look["iris"])
        p.lay(iris * p.rise(cy - 0.1 * ry, cy + 0.9 * ry), tone(look["iris"], 0.38), 0.9)
        p.lay(np.minimum(p.ellipse(cx, cy - 0.42 * ry, rx * 0.62, ry * 0.4), iris), mix(look["iris"], "#FFFFFF", 0.45), 0.7)
        p.lay(np.clip(iris - p.ellipse(cx, cy, rx * 0.84, ry * 0.88), 0, 1), tone(look["iris"], 0.3), 0.9)
        p.lay(np.minimum(p.ellipse(cx, cy + 0.05 * ry, rx * 0.36, ry * 0.42), shape), tone(look["iris"], 0.16))
        # the lights sit on the same side of both eyes
        p.lay(np.minimum(p.ellipse(cx - 0.36 * rx, cy + 0.4 * ry, rx * 0.3, ry * 0.24, turn=-20), shape), "#FFFFFF")
        p.lay(np.minimum(p.ellipse(cx + 0.4 * rx, cy - 0.42 * ry, rx * 0.14, ry * 0.11), shape), "#FFFFFF", 0.85)
        p.lay(p.stroke(upper, (0.012, 0.03, 0.046, 0.03)), INK)
        p.lay(p.stroke(lower[:3], (0.02, 0.011, 0.0)), INK, 0.8)
        crease = [at(-0.3 * ew, top * 0.74 + 0.045), at(0.1 * ew, top + 0.05), at(0.44 * ew, 0.3 * eh + tilt + 0.05)]
        p.lay(p.stroke(crease, (0.0, 0.01, 0.0)), line, 0.6)
        by, bt = look["brow_y"], look.get("brow_tilt", 0.0)
        brow = [at(-0.6 * ew, by - ey - bt), at(-0.05 * ew, by - ey + 0.03), at(0.66 * ew, by - ey + bt)]
        p.lay(p.stroke(brow, (0.03, 0.042, 0.03, 0.006)), look.get("brow", INK))
    p.lay(p.stroke([(0.012, 0.4), (0.034, 0.355), (0.008, 0.342)], (0.004, 0.014, 0.008)), line, 0.9)
    p.lay(p.stroke(look["mouth"], (0.006, 0.016, 0.006)), tone(skin, 0.4))
    my = min(y for _, y in look["mouth"])
    p.lay(p.stroke([(-0.03, my - 0.045), (0.03, my - 0.045)], (0.0, 0.012, 0.0)), line, 0.45)


# --- the hair --------------------------------------------------------------------------------------------------------

class Hair:
    """One mesh of hair: a shell over the scalp and locks laid on it in rings. Each lock is a thin blade drawn to a
    point, smooth across its ridge and sharp along its two edges, its root's colour running to its end's."""

    def __init__(self, root, tip, seed=1):
        self.bm = bmesh.new()
        self.col = []
        self.pair = (np.array(rs.srgb(root)[:3]), np.array(rs.srgb(tip)[:3]))
        self.rng = np.random.default_rng(seed)
        self.locks = 0

    def _vert(self, at, colour):
        self.col.append(colour)
        return self.bm.verts.new(at)

    def colour(self, u, k=1.0):
        return np.clip((self.pair[0] * (1 - u) + self.pair[1] * u) * k, 0, 1)

    def shell(self, hairline, segments=36):
        """The scalp's cover, down to `hairline(degrees round from the face's middle)`."""
        rings, c = [], self.colour(0.3, 0.9)
        top = CENTRE.z + SCALP_TOP
        for i in range(segments):
            deg = (i / segments * 2 - 1) * 180
            a, low = math.radians(deg), hairline(abs(deg))
            line = [(0.5, top - 0.005), (0.63, top - 0.06), (SCALP, top - 0.17)]
            line += [(SCALP, top - 0.17 + (low - top + 0.17) * f) for f in (0.34, 0.67, 1.0)] + [(R * 0.98, low)]
            rings.append([self._vert((-r * math.sin(a), r * math.cos(a), z), c) for r, z in line])
        crown = self._vert((0, 0, top), c)
        for i in range(segments):
            n = (i + 1) % segments
            self.bm.faces.new((crown, rings[i][0], rings[n][0])).smooth = True
            for k in range(len(rings[0]) - 1):
                self.bm.faces.new((rings[i][k], rings[i][k + 1], rings[n][k + 1], rings[n][k])).smooth = True

    def lock(self, root, mid, tip, width, thick, samples=9, k=1.0, point=1.0):
        root, mid, tip = Vector(root), Vector(mid), Vector(tip)
        rings = []
        for i in range(samples):
            u = i / (samples - 1)
            at = root * (1 - u) ** 2 + mid * (2 * u * (1 - u)) + tip * (u * u)
            along = ((mid - root) * (1 - u) + (tip - mid) * u).normalized()
            out = at - CENTRE
            out -= along * out.dot(along)
            if out.length < 0.05:
                out = Vector((0, 0, 1)) - along * along.z
            out = out.normalized() if out.length > 1e-4 else along.orthogonal().normalized()
            side = along.cross(out).normalized()
            s = min(1.0, 0.7 + u * 1.5) * (1 - u ** point) ** 0.8
            c = self.colour(u ** 1.2, k)
            if i == samples - 1:
                rings.append([self._vert(at, c)])
            else:
                rings.append([self._vert(at + side * (width / 2 * s), c * 0.86), self._vert(at + out * (thick * 0.56 * s), np.clip(c * 1.1, 0, 1)),
                              self._vert(at - side * (width / 2 * s), c * 0.86), self._vert(at - out * (thick * 0.44 * s), c * 0.55)])
        self.bm.faces.new(list(reversed(rings[0])))
        for a, b in zip(rings, rings[1:]):
            for q in range(4):
                n = (q + 1) % 4
                f = self.bm.faces.new((a[q], a[n], b[n], b[q]) if len(b) == 4 else (a[q], a[n], b[0]))
                f.smooth = True
            if len(b) == 4:
                for q in (0, 2):
                    self.bm.edges.get((a[q], b[q])).smooth = False
            else:
                for q in (0, 2):
                    self.bm.edges.get((a[q], b[0])).smooth = False
        for q in range(4):
            self.bm.edges.get((rings[0][q], rings[0][(q + 1) % 4])).smooth = False
        self.locks += 1

    def ring(self, count, polar, around, length, width, lift, droop=0.0, sweep=0.0, bend=0.0, jitter=0.2, thick=0.1):
        """A ring of locks. `polar`: degrees down from the crown. `around`: the degrees it runs through round the
        head, 0 at the face's middle, growing toward his left. `lift`: 1 stands a lock straight off the scalp, 0 lays
        it down along it. `droop`: how far its end falls, in its own lengths. `sweep`: how far it turns round the head,
        toward his left above zero. `bend`: how far its middle bows off the scalp."""
        a0, a1 = around
        step = (a1 - a0) / count
        up = Vector((0, 0, 1))
        for i in range(count):
            a = math.radians(a0 + step * (i + 0.5 + self.rng.uniform(-1, 1) * jitter))
            ph = math.radians(polar + self.rng.uniform(-1, 1) * jitter * 14)
            long_, wide = length * (1 + self.rng.uniform(-1, 1) * jitter), width * (1 + self.rng.uniform(-1, 1) * jitter * 0.6)
            out = Vector((-math.sin(a), math.cos(a), 0))
            v = out * math.sin(ph) + up * math.cos(ph)
            reach = SCALP / max(math.sin(ph), 1e-6)
            if math.cos(ph) > 1e-6:
                reach = min(reach, SCALP_TOP / math.cos(ph))
            root = CENTRE + v * (reach - 0.07)
            down, round_ = out * math.cos(ph) - up * math.sin(ph), Vector((-math.cos(a), -math.sin(a), 0))
            d = (v * lift + down * (1 - lift) + round_ * sweep).normalized()
            mid = root + d * (long_ * 0.55) + v * (bend * long_)
            tip = root + d * long_ - up * (droop * long_) + round_ * (sweep * long_ * 0.4)
            self.lock(root, mid, tip, wide, thick, k=1 + self.rng.uniform(-1, 1) * 0.07)

    def on_scalp(self, a, ph, off=0.0):
        """A point on the shell (and straight down from its rim, below it): `a` degrees round, `ph` down from the crown."""
        a, ph = math.radians(a), math.radians(min(ph, 172))
        v = Vector((-math.sin(a) * math.sin(ph), math.cos(a) * math.sin(ph), math.cos(ph)))
        reach = SCALP / max(math.sin(ph), 1e-6)
        if math.cos(ph) > 1e-6:
            reach = min(reach, SCALP_TOP / math.cos(ph))
        flat = Vector((v.x, v.y, 0))
        out = (v if math.cos(ph) > 0.3 else flat).normalized()
        return CENTRE + v * reach + out * off, out

    def flow(self, count, polar, around, fall, width, flick=0.1, sweep=0.0, jitter=0.2, thick=0.13, point=2.2, off=0.05):
        """A ring of clumps that lie along the head: each starts `polar` degrees down from the crown, runs `fall`
        degrees further down hugging the shell, turns `sweep` degrees round the head on the way, and ends standing
        `flick` studs off it."""
        a0, a1 = around
        step = (a1 - a0) / count
        for i in range(count):
            a = a0 + step * (i + 0.5 + self.rng.uniform(-1, 1) * jitter)
            ph = polar + self.rng.uniform(-1, 1) * jitter * 10
            run = fall * (1 + self.rng.uniform(-1, 1) * jitter)
            turn = sweep * (1 + self.rng.uniform(-1, 1) * jitter)
            wide = width * (1 + self.rng.uniform(-1, 1) * jitter * 0.6)
            root, _ = self.on_scalp(a, ph, -0.06)
            through, _ = self.on_scalp(a + turn * 0.5, ph + run * 0.5, off)
            end, out = self.on_scalp(a + turn, ph + run, off * 0.5)
            tip = end + out * (flick * (1 + self.rng.uniform(-1, 1) * jitter))
            self.lock(root, through * 2 - (root + tip) / 2, tip, wide, thick, k=1 + self.rng.uniform(-1, 1) * 0.07, point=point)

    def build(self, name="Hair"):
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        attr = mesh.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        for d, c in zip(attr.data, self.col):
            d.color = (c[0], c[1], c[2], 1.0)
        m = bpy.data.materials.new(name)
        bsdf, nodes, links = bl._principled(m)
        paint = nodes.new("ShaderNodeVertexColor")
        paint.layer_name = "Col"
        links.new(paint.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.8
        mesh.materials.append(m)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def hairline(front=4.96, temple=4.5, nape=4.08):
    return lambda deg: float(np.interp(deg, [0, 38, 78, 125, 180], [front, front - 0.02, temple, nape + 0.1, nape]))


# --- a plain stand-in, to judge the make by ----------------------------------------------------------------------------

SKIN = "#F0C3A0"
BODY = {"torso": ((0, 0, 3), (2, 1, 2)), "rs": ((1.5, 0, 3), (1, 1, 2)), "ls": ((-1.5, 0, 3), (1, 1, 2)),
        "rh": ((0.5, 0, 1), (1, 1, 2)), "lh": ((-0.5, 0, 1), (1, 1, 2))}
JOINT = {"torso": "root", "rs": "rs", "ls": "ls", "rh": "rh", "lh": "lh"}


def stand_in(joints, folder):
    """A plain figure: a short jacket open over a shirt, trousers, shoes, short spiked hair. No design is meant."""
    jacket, shirt, trouser, shoe, trim = "#3A4C6B", "#ECE7DD", "#2A2B36", "#1D1C22", "#C9B27A"
    made = {}
    blocks = {key: Block(key, centre, size, jacket if key in ("torso", "rs", "ls") else trouser) for key, (centre, size) in BODY.items()}

    t = blocks["torso"]
    w = t.wrap
    w.lay(w.rect(-9, 0.0, 9, 0.2), trouser)
    f = t.faces["front"]
    f.lay(f.poly([(-0.34, 2.0), (0.34, 2.0), (0.2, 0.34), (-0.2, 0.34)]), shirt)
    f.lay(f.poly([(-0.22, 2.0), (0.22, 2.0), (0.0, 1.66)]), SKIN)
    f.lay(f.stroke([(-0.22, 2.0), (0.0, 1.66), (0.22, 2.0)], (0.02, 0.02, 0.02)), tone(shirt, 0.72))
    folds(f, [([(-0.02, 1.5), (0.0, 1.0), (0.02, 0.5)], 0.012), ([(-0.16, 1.2), (-0.1, 1.0), (-0.13, 0.75)], 0.014),
              ([(0.15, 0.95), (0.1, 0.75), (0.13, 0.55)], 0.014)], tone(shirt, 0.7))
    # the jacket's two front edges, a lapel each, and its hem
    for s in (-1, 1):
        f.lay(f.poly([(s * 0.34, 2.0), (s * 0.62, 2.0), (s * 0.34, 1.3), (s * 0.27, 1.38)]), tone(jacket, 1.25))
        f.lay(f.stroke([(s * 0.62, 2.0), (s * 0.34, 1.3), (s * 0.2, 0.34)], (0.02, 0.024, 0.02)), tone(jacket, 0.55))
        folds(f, [([(s * 1.0, 1.6), (s * 0.74, 1.46), (s * 0.56, 1.44)], 0.03), ([(s * 0.92, 0.82), (s * 0.7, 0.62), (s * 0.56, 0.42)], 0.026)],
              tone(jacket, 0.6))
        f.lay(f.soft(f.poly([(s * 1.0, 1.52), (s * 0.7, 1.38), (s * 0.62, 0.9), (s * 1.0, 0.7)]), 0.06), tone(jacket, 0.6), 0.35)
    b = t.faces["back"]
    folds(b, [([(0.0, 1.9), (0.01, 1.2), (0.0, 0.34)], 0.014), ([(-0.9, 1.6), (-0.5, 1.45), (-0.2, 1.5)], 0.03),
              ([(0.9, 1.6), (0.5, 1.45), (0.2, 1.5)], 0.03), ([(-0.8, 0.9), (-0.5, 0.7), (-0.3, 0.42)], 0.026),
              ([(0.8, 0.9), (0.5, 0.7), (0.3, 0.42)], 0.026)], tone(jacket, 0.6))
    b.lay(b.poly([(-0.5, 2.0), (0.5, 2.0), (0.44, 1.82), (-0.44, 1.82)]), tone(jacket, 1.25))
    w.lay(w.rect(-9, 0.2, 9, 0.36), "#17161B")
    w.lay(w.rect(-9, 0.335, 9, 0.36), tone(jacket, 0.5))
    f.lay(f.rect(-0.13, 0.2, 0.13, 0.36), trim)
    f.lay(f.rect(-0.07, 0.24, 0.07, 0.32), "#17161B")
    shade(t, tone(jacket, 0.42), 0.4)
    t.faces["top"].lay(t.faces["top"].ellipse(0, 0.5, 0.36, 0.36), SKIN)

    for key, s in (("rs", 1), ("ls", -1)):
        a = blocks[key]
        w = a.wrap
        w.lay(w.rect(-9, 0.0, 9, 0.44), SKIN)
        w.lay(w.rect(-9, 0.44, 9, 0.6), tone(jacket, 1.25))
        w.lay(w.rect(-9, 0.585, 9, 0.61), tone(jacket, 0.5))
        w.lay(w.rect(-9, 0.425, 9, 0.45), tone(jacket, 0.5))
        for p in a.sides:
            folds(p, [([(-0.42, 1.24), (-0.05, 1.12), (0.34, 1.2)], 0.03), ([(-0.28, 1.02), (0.1, 0.96), (0.42, 1.04)], 0.024)],
                  tone(jacket, 0.6))
            # the fingers' lines on the hand
            folds(p, [([(-0.2, 0.3), (-0.2, 0.08)], 0.012), ([(0.0, 0.3), (0.0, 0.06)], 0.012), ([(0.2, 0.3), (0.2, 0.08)], 0.012)],
                  tone(SKIN, 0.62), 0.55)
        shade(a, tone(jacket, 0.42), 0.4, low=0.0)
        for p in a.sides:
            p.lay(p.rect(-9, 0, 9, 0.425) * np.clip((np.abs(p.X) - 0.26) / 0.24, 0, 1), tone(SKIN, 0.7), 0.45)
        a.faces["bottom"].px[:] = rgb(SKIN)

    for key, s in (("rh", 1), ("lh", -1)):
        g = blocks[key]
        w = g.wrap
        w.lay(w.rect(-9, 0.0, 9, 0.34), shoe)
        w.lay(w.rect(-9, 0.0, 9, 0.07), "#E4E0D8")
        w.lay(w.rect(-9, 0.31, 9, 0.345), tone(trouser, 0.5))
        for p in g.sides:
            folds(p, [([(-0.4, 1.16), (-0.05, 1.04), (0.36, 1.12)], 0.03), ([(-0.3, 0.6), (0.0, 0.46), (0.34, 0.5)], 0.03)],
                  tone(trouser, 0.5))
        fr = g.faces["front"]
        fr.lay(fr.poly([(-0.34, 0.07), (0.34, 0.07), (0.3, 0.2), (-0.3, 0.2)]), tone(shoe, 1.9))
        shade(g, tone(trouser, 0.4), 0.4, low=0.0)
        g.faces["bottom"].px[:] = rgb("#E4E0D8")

    for key, block in blocks.items():
        made[key] = block.build(folder)
        wt.on(joints, JOINT[key], made[key])

    head = Head(SKIN)
    draw_face(head.paint, dict(skin=SKIN, iris="#3F8FD0", eye_w=0.31, eye_h=0.175, eye_x=0.27, eye_y=0.54, tilt=0.022,
                               shut=0.2, brow_y=0.7, brow_tilt=-0.03, brow="#3B2A24",
                               mouth=[(-0.075, 0.232), (0.0, 0.224), (0.08, 0.238)]))
    hair = Hair("#33241F", "#A87B52", seed=7)
    hair.shell(hairline())
    hair.flow(9, 3, (-180, 180), 56, 0.54, flick=0.16, sweep=38, jitter=0.12)
    hair.flow(7, 16, (-160, 200), 44, 0.46, flick=0.2, sweep=30)
    hair.flow(12, 34, (40, 320), 50, 0.44, flick=0.2, sweep=20)
    hair.flow(12, 66, (62, 298), 44, 0.4, flick=0.18, sweep=10)
    hair.flow(9, 96, (92, 268), 30, 0.34, flick=0.12, sweep=4, thick=0.11)
    hair.flow(7, 26, (-66, 66), 50, 0.36, flick=0.06, sweep=12, thick=0.11)
    hair.flow(3, 52, (-104, -62), 46, 0.28, flick=0.05, thick=0.1)
    hair.flow(3, 52, (62, 104), 46, 0.28, flick=0.05, thick=0.1)
    hair.ring(5, 22, (-150, 150), 0.42, 0.3, 0.8, droop=0.1, sweep=0.3, thick=0.12)
    made["head"], made["hair"] = head.build(folder), hair.build()
    wt.on(joints, "neck", made["head"], made["hair"])
    print(f"hair: {hair.locks} locks")
    return made


VIEWS = {"front": (146, 8), "face": (180, 4), "game": rs.GAME}
BUST = dict(side=1, body=34, turn=22, tilt=-3, nod=5, elevation=3, centre=(-0.1, 0, 4.6), span=2.6)


def fill_for(scene, azimuth):
    fill = bpy.data.objects.get("Fill")
    if fill is None:
        fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN"))
        fill.data.energy, fill.data.use_shadow = 1.1, False
        scene.collection.objects.link(fill)
    a = math.radians(azimuth)
    fill.rotation_euler = Vector((-math.sin(a), math.cos(a), -0.12)).to_track_quat("-Z", "Y").to_euler()


def views(scene, joints, shots, key):
    """The figure's pictures: three-quarter front, face on, the game's camera, and the lead card's bust."""
    rs.POSES["idle"](joints)
    rm.eevee(scene, 820, 820)
    for view, (azimuth, elevation) in VIEWS.items():
        rm.sun_for(scene, azimuth)
        fill_for(scene, azimuth)
        rs.shoot(scene, shots / f"{key}_{view}.png", azimuth, elevation, (0.0, 0.0, 3.0), 7.4)
    for joint in joints.values():
        joint.rotation_quaternion = (1, 0, 0, 0)
    joints["root"].location = wt.PIVOTS["root"]
    rs.POSES["square"](joints)
    yaw = -math.radians(BUST["side"] * BUST["turn"])
    joints["neck"].rotation_quaternion = (Matrix.Rotation(yaw, 3, "Z") @ Matrix.Rotation(math.radians(BUST["nod"]), 3, "X")
                                          @ Matrix.Rotation(math.radians(BUST["tilt"]), 3, "Y")).to_quaternion()
    rm.eevee(scene, 624, 752)
    azimuth = 180.0 - BUST["side"] * BUST["body"]
    rm.sun_for(scene, azimuth)
    fill_for(scene, azimuth)
    rs.shoot(scene, shots / f"{key}_bust.png", azimuth, BUST["elevation"], BUST["centre"], BUST["span"])


def run(out):
    shots, folder = out / "shots", out / "tex"
    shots.mkdir(parents=True, exist_ok=True)
    folder.mkdir(parents=True, exist_ok=True)
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Make")
    joints = wt.rig(scene)
    made = stand_in(joints, folder)
    bpy.context.view_layer.update()
    tris = sum(len(f.vertices) - 2 for o in made.values() for f in o.data.polygons)
    print(f"stand-in: {tris} triangles, hair {sum(len(f.vertices) - 2 for f in made['hair'].data.polygons)}")
    views(scene, joints, shots, "standin")


if __name__ == "__main__":
    rs.OUT = bl.out_dir()
    run(rs.OUT)
