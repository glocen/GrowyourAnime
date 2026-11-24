"""The make of a Voidkin on the R6 body (AR59's redo, research, 2026-11-23): the way the genre's Roblox games make a
unit, which is what reads as anime at that size.

    the body   R6's six plain blocks, nothing built on them; the clothes are a picture drawn on the blocks' faces:
               flat colours, a soft painted shade, drawn fold lines, trims, a belt;
    the head   Roblox's round head, with an anime face drawn on it: almond eyes with a coloured iris and a light, a
               lash line, thin brows, a tick for the nose, a short mouth;
    the hair   one mesh: a few dozen broad leaf-shaped clumps laid like roof tiles on a shell, from the nape up to
               the crown, each lying on the head with only its point turned out, dark under each;
    built      few pieces and thin ones, none thicker than the limb it sits on. Since the director's word of
               2026-11-24 ("it fine if the model has some attachment or ovexageration") a Voidkin may carry some:
               a scarf, a blade, a ribbon (`Built`). The clothes stay drawn on the body.

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
SCALP, SCALP_TOP = 0.78, 0.8      # the hair's mass under its clumps, an egg: its radius, and its top above the middle
FACE = R + 0.07                   # how far from the head's middle a lock hangs past the egg, before the face
GUT = 12 / PPU                    # studs kept clear round a block's top and bottom pictures, so none bleeds into another
PICTURES, GLOWS = {}, {}          # each built piece's own picture, and its glow's shape if it has one, by its object's name
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
        self.px = np.empty((int(round((h + d + 2 * GUT) * PPU)), int(round(2 * (w + d) * PPU)), 3), np.float32)
        self.px[:] = rgb(colour)
        self.glow = None  # the light it can put out, 0 to 1 a texel of its picture (light_up)
        k, tall = PPU, int(round(h * PPU))
        # where each face sits in the picture, in studs from its left and from its top
        self.at = {"right": (0, 0, d, h), "front": (d, 0, w, h), "left": (d + w, 0, d, h), "back": (2 * d + w, 0, w, h),
                   "top": (GUT, h + GUT, w, d), "bottom": (w + 3 * GUT, h + GUT, w, d)}
        self.faces = {}
        for key, (x, y, fw, fh) in self.at.items():
            view = self.px[int(round(y * k)):int(round((y + fh) * k)), int(round(x * k)):int(round((x + fw) * k))]
            self.faces[key] = Paint(view, -fw / 2, fw, fh)
        self.wrap = Paint(self.px[:tall], -w / 2 - d, 2 * (w + d), h)

    @property
    def sides(self):
        return [self.faces[k] for k in ("right", "front", "left", "back")]

    def light_up(self, cover, end=0.0):
        """What glows when the game lights this block: `cover` over its four sides, and `end` over its bottom face."""
        self.glow = np.zeros(self.px.shape[:2], np.float32)
        self.glow[:cover.shape[0]] = np.clip(cover, 0, 1)
        x, y, fw, fh = self.at["bottom"]
        self.glow[int(round(y * PPU)):int(round((y + fh) * PPU)), int(round(x * PPU)):int(round((x + fw) * PPU))] = end

    def bleed(self, reach=6):
        """The sides' feet and the two end pictures drawn a little past their edges, so a far-off texel stays theirs."""
        tall = int(round(self.size[2] * PPU))
        for px in (self.px,) if self.glow is None else (self.px, self.glow):
            px[tall:tall + reach] = px[tall - 1]
            for key in ("top", "bottom"):
                x, y, fw, fh = self.at[key]
                r0, r1, c0, c1 = (int(round(v * PPU)) for v in (y, y + fh, x, x + fw))
                pad = ((reach, reach), (reach, reach)) + (((0, 0),) if px.ndim == 3 else ())
                px[r0 - reach:r1 + reach, c0 - reach:c1 + reach] = np.pad(px[r0:r1, c0:c1], pad, mode="edge")

    def build(self, folder):
        self.bleed()
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
        PICTURES[obj.name] = self.px  # by the object's own name: Blender numbers a name it already holds
        if self.glow is not None:
            GLOWS[obj.name] = self.glow
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


# The cloth, painted the way the genre paints it (AR59, research's pick, must-fixes 4 and 5): soft shade and a grain,
# never flat colour; and folds that follow the cloth's pull (from a shoulder, an elbow, a button, a waist), never the
# muscles under it.

def dark(p, cover, amount=0.3):
    """A painted shade: what is under `cover` darker and a little cooler."""
    p.px[...] = p.px * (1 - np.clip(cover, 0, 1)[..., None] * amount * np.array((1.0, 1.04, 0.9), np.float32))


def light(p, cover, amount=0.2):
    p.px[...] = p.px + (1 - p.px) * np.clip(cover, 0, 1)[..., None] * amount


def shadow(block, amount=0.34, low=0.5, edge=0.26):
    """Every side of a block darker toward its two edges and its foot, whatever is drawn there."""
    for p in block.sides:
        side = np.clip((np.abs(p.X - p.mid) - (p.w / 2 - edge)) / edge, 0, 1) ** 1.5
        foot = np.clip((low - p.Y) / low, 0, 1) * 0.6 if low > 0 else 0.0
        dark(p, np.maximum(side, foot), amount)


def lit(block, top=0.16, side=0.08):
    """The light a painter gives a figure: every side lighter toward its top, his right side a little lighter and
    his left a little darker."""
    h = block.size[2]
    for q in block.sides:
        light(q, np.clip((q.Y - h * 0.45) / (h * 0.55), 0, 1) ** 1.3, top)
    light(block.faces["right"], np.ones_like(block.faces["right"].X), side)
    dark(block.faces["left"], np.ones_like(block.faces["left"].X), side)


def creases(p, lines, amount=0.4, wide=0.03):
    """Painted folds: each a line that swells and ends in points, a soft shade spreading under it and a little light
    on the cloth above it, as a brush leaves them. On dark cloth a shade alone is lost, so the darker the cloth under
    a fold, the more its lit edge carries it, wider and brighter (AR60, research's must-fix 3); and every fold is
    `FOLD` deep, a step past AR59's."""
    for pts in lines:
        under = p.soft(p.stroke([(x, y - wide * 1.6) for x, y in pts], (0.0, wide * 3.2, wide * 2.4, 0.0), n=20), wide * 1.4)
        over = p.stroke([(x, y + wide * 1.3) for x, y in pts], (0.0, wide * 1.6, wide * 1.2, 0.0), n=20)
        weight = float(under.sum())
        value = float((p.px.mean(axis=2) * under).sum() / weight) if weight > 0 else 0.5
        low = float(np.clip((0.5 - value) / 0.3, 0, 1))   # 0 on middling or light cloth, 1 on dark
        dark(p, under, amount * 0.55 * FOLD)
        light(p, p.soft(over, wide * (0.9 + 0.5 * low)), amount * (0.16 + 0.34 * low))
        dark(p, p.soft(p.stroke(pts, (0.0, wide, wide * 0.7, 0.0), n=20), 0.008), min(0.95, amount * FOLD * (1 + 0.3 * low)))


FOLD = 1.2   # the folds' depth over AR59's (polish-later's "one step deeper", pulled forward by AR60)


def grain(block, amount=0.06, seed=1):
    """The cloth's grain over a block's sides: soft clouds of lighter and darker, and a fine tooth."""
    rng = np.random.default_rng(seed)
    px = block.wrap.px
    noise = lambda: rng.standard_normal(px.shape[:2]).astype(np.float32)  # noqa: E731

    def cloud(studs):
        c = blur(noise(), PPU * studs)
        return np.clip(c / max(float(c.std()) * 2.5, 1e-6), -1, 1)

    px[...] = np.clip(px * (1 + ((cloud(0.1) * 0.65 + cloud(0.035) * 0.35) * amount + noise() * amount * 0.12)[..., None]), 0, 1)


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
        PICTURES[obj.name] = self.px
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

def bent(d, degrees):
    """`d` turned toward the ground by `degrees` (below zero: toward the sky), never past it."""
    goal = Vector((0, 0, -1.0 if degrees >= 0 else 1.0))
    axis = d.cross(goal)
    if axis.length < 1e-5:
        return d.copy()
    return Matrix.Rotation(min(math.radians(abs(degrees)), d.angle(goal)), 3, axis.normalized()) @ d


class Hair:
    """One mesh of hair, built the way the genre's is: a dark egg over the scalp, and on it a few dozen broad clumps
    laid like roof tiles, from the nape up to the crown. A clump roots in the egg, lies along the head the way the
    hair is combed, then leaves it and lifts to its point. It is a leaf: narrow at the root, widest a third along,
    drawn to a sharp point, with one ridge off its middle, so it shows a broad lit face, a narrow darker one and a
    dark underside. It is smooth from root to tip and over its ridge, sharp only at its edges, and one band of
    light runs round the whole mass. Its colours are a picture of its own, a small strip a clump (the game draws a
    mesh by a picture, never by colours on its points). What makes it read as hair, and not as spines: few clumps, of three sizes;
    each lying on the one below; the tips turned out, never the whole clump; one way round the crown for all."""

    def __init__(self, root, tip, seed=1, band=(0.5, 0.11, 0.4)):
        self.bm = bmesh.new()
        self.strips, self.charts = [], []  # each clump's colours, ring by ring; and each of its faces' places in them
        self.pair = (np.array(rs.srgb(root)[:3]), np.array(rs.srgb(tip)[:3]))
        self.band = band  # the one band of light round the mass: its height over the scalp's middle, its width, its strength
        self.rng = np.random.default_rng(seed)
        self.locks = 0
        self.patches = []   # whole pieces with pictures of their own (`sheet`): (the picture, its faces and their uv)

    def _vert(self, at):
        return self.bm.verts.new(at)

    def colour(self, u, k=1.0):
        """The hair's colour `u` of the way along a clump: in the shade of the clumps above at its root."""
        v = 0.3 + 0.7 * u ** 1.3
        return np.clip((self.pair[0] * (1 - v) + self.pair[1] * v) * k * (0.5 + 0.5 * min(1.0, u / 0.42) ** 0.8), 0, 1)

    def shine(self, at, c):
        """`c` with the band of light where `at` stands in it."""
        z, wide, strength = self.band
        g = strength * math.exp(-((at.z - CENTRE.z - z) / wide) ** 2)
        return c + (np.clip(self.pair[1] * 1.5 + 0.08, 0, 1) - c) * g

    def frame(self, a, ph):
        """A point on the head's hair surface, the way out of it there, the way down it and the way round it toward
        his left: `a` degrees round from the face's middle toward his left, `ph` degrees down from the crown. The
        surface is the egg down to its widest, then the face and neck a little clear of the skin (135 is the chin)."""
        r = math.radians(a)
        flat, east = Vector((-math.sin(r), math.cos(r), 0)), Vector((-math.cos(r), -math.sin(r), 0))

        def point(deg):
            if deg <= 90:
                q = math.radians(max(deg, 0.0))
                return CENTRE + flat * (SCALP * math.sin(q) ** 0.75) + Vector((0, 0, SCALP_TOP * math.cos(q)))
            d = deg - 90
            return CENTRE + flat * (FACE + (SCALP - FACE) * math.exp(-d / 22)) + Vector((0, 0, -d * SCALP_TOP * math.pi / 180))

        ph = max(ph, 1.5)
        down = (point(ph + 1) - point(ph - 1)).normalized()
        return point(ph), down.cross(east).normalized(), down, east

    def at(self, a, ph):
        return self.frame(a, ph)[:3]

    def where(self, p):
        """The degrees round and down of the surface's point under `p`."""
        v = p - CENTRE
        if v.z >= 0:
            return math.degrees(math.atan2(-v.x, v.y)), math.degrees(math.acos(min(1.0, v.z / SCALP_TOP)))
        return math.degrees(math.atan2(-v.x, v.y)), 90 - v.z / (SCALP_TOP * math.pi / 180)

    def shell(self, hairline, segments=36):
        """The scalp's cover, down to `hairline(degrees round from the face's middle)`: what shows between clumps."""
        rings = []
        self.scalp = self.pair[0] * 0.5
        for i in range(segments):
            deg = (i / segments * 2 - 1) * 180
            a, low = math.radians(deg), hairline(abs(deg))
            end = math.degrees(math.acos(max(-0.1, min(0.95, (low + 0.03 - CENTRE.z) / SCALP_TOP))))
            line = [self.at(deg, end * f)[0] for f in (0.18, 0.36, 0.54, 0.72, 0.88, 1.0)]
            line.append(Vector((-math.sin(a) * R * 0.98, math.cos(a) * R * 0.98, low)))
            rings.append([self._vert(q) for q in line])
        crown = self._vert(CENTRE + Vector((0, 0, SCALP_TOP)))
        for i in range(segments):
            n = (i + 1) % segments
            self.bm.faces.new((crown, rings[i][0], rings[n][0])).smooth = True
            for k in range(len(rings[0]) - 1):
                self.bm.faces.new((rings[i][k], rings[i][k + 1], rings[n][k + 1], rings[n][k])).smooth = True

    def spine(self, a, ph, length, heading, bend, comb, hold, flick, off, n):
        """A clump's middle line, as (point, the way out of the head there). It walks the surface from its root, the
        way `heading` says (degrees from down the head, toward his left; or from `comb`, a direction laid on the
        head), turning `bend` degrees by its end; `hold` of the way along it leaves the head and by its point has
        turned `flick` degrees off it."""
        smooth = lambda x: (lambda v: v * v * (3 - 2 * v))(min(max(x, 0.0), 1.0))  # noqa: E731
        step, line, free = length / (n - 1), [], None
        p, nrm, down, east = self.frame(a, ph)
        h = math.radians(heading)
        d = down * math.cos(h) + east * math.sin(h)
        for i in range(n):
            u = i / (n - 1)
            if free is None:
                if comb is not None:
                    way = Vector(comb) - nrm * nrm.dot(Vector(comb))
                    if way.length > 1e-3:
                        d = Matrix.Rotation(math.radians(heading + bend * u), 3, nrm) @ way.normalized()
                q = p + nrm * (-0.07 * (1 - smooth(u / 0.2)) + off * smooth(u / 0.35))
                line.append((q, nrm.copy()))
                if u >= hold:
                    free = (d.copy(), nrm.copy())
                    continue
                p, nrm, down, east = self.frame(*self.where(p + d * step))
                d = d - nrm * d.dot(nrm)
                d = Matrix.Rotation(math.radians(bend / (n - 1)), 3, nrm) @ d.normalized()
            else:
                t0, n0 = free
                turn = math.radians(flick) * ((u - hold) / max(1 - hold, 1e-3)) ** 0.8
                q = line[-1][0] + (t0 * math.cos(turn) + n0 * math.sin(turn)) * step
                line.append((q, n0 * math.cos(turn) - t0 * math.sin(turn)))
        return line

    def blade(self, line, width, thick, ridge=0.35, taper=1.6, k=1.0, gleam=None, root=0.0):
        """A leaf along `line`: `ridge` is how far off its middle its ridge runs, toward its left edge (below zero,
        toward its right). `gleam`, (where along it, how wide, how strong): a band of light of its own, for a lock
        that hangs below the mass's band, so a tail shines as the crown does. `root`: how far along its colour starts,
        so a lock laid on the head from a hairline has no dark root."""
        n, rings, shades = len(line), [], []
        for i, (q, out) in enumerate(line):
            u = i / (n - 1)
            along = (line[min(i + 1, n - 1)][0] - line[max(i - 1, 0)][0]).normalized()
            out = out - along * out.dot(along)
            out = out.normalized() if out.length > 1e-3 else along.orthogonal().normalized()
            side = along.cross(out).normalized()
            v = min(u / 0.25, 1.0)
            s = (1 - u ** taper) * (0.7 + 0.3 * v * v * (3 - 2 * v))
            c = self.colour(root + (1 - root) * u, k)
            if gleam:
                c = c + (np.clip(self.pair[1] * 1.5 + 0.08, 0, 1) - c) * gleam[2] * math.exp(-((u - gleam[0]) / gleam[1]) ** 2)
            if i == n - 1:
                rings.append([self._vert(q)] * 5)
                shades.append([self.shine(q, c * 1.06)] * 5)
                continue
            left, right = q + side * (width / 2 * s), q - side * (width / 2 * s)
            top = q + side * (width / 2 * s * ridge) + out * (thick * s)
            rings.append([self._vert(at) for at in (left, top, right, right, left)])
            shades.append([self.shine(left, c * 0.82), self.shine(top, c * 1.04), self.shine(right, c * 0.82), c * 0.56, c * 0.56])
        strip = len(self.strips)
        self.strips.append(np.clip(np.array(shades, np.float32), 0, 1))
        for j, (lo, hi) in enumerate(zip(rings, rings[1:])):
            for q, m in ((0, 1), (1, 2), (3, 4)):  # the ridge's two faces, sharing its points so it is smooth, and the one under
                if j < n - 2:
                    f, where = self.bm.faces.new((lo[q], hi[q], hi[m], lo[m])), [(j, q), (j + 1, q), (j + 1, m), (j, m)]
                else:
                    f, where = self.bm.faces.new((lo[q], hi[0], lo[m])), [(j, q), (j + 1, (q + m) / 2), (j, m)]
                f.smooth = True
                self.charts.append((f, strip, where))
        self.locks += 1

    def lock(self, points, width, thick=None, out=None, n=10, ridge=0.35, taper=1.6, k=1.0, gleam=None):
        """A free lock through `points` in space, off the head: a tail, a long lock over a shoulder. Its lit face is
        turned `out` (a direction), or away from the head's middle."""
        line = []
        for q in smooth2([tuple(q) for q in points], n):
            q = Vector(q)
            line.append((q, (Vector(out) if out is not None else q - CENTRE).normalized()))
        self.blade(line, width, thick or width * 0.3, ridge, taper, k, gleam)

    def sweep(self, start, end, width, off=(0.04, 0.09), thick=None, n=12, ridge=0.35, taper=1.6, k=1.0, lift=0.0):
        """A broad lock laid on the head from `start` to `end`, each (degrees round, degrees down), the shortest way
        over the egg: hair combed back or up to a tie, a few big lit planes instead of a ring of small clumps (AR60,
        research's must-fix 1). It rides `off` studs over the head from its root to its end, and `lift` more at its
        middle, so the locks laid later lie on the earlier."""
        a, b = (self.at(*start)[0] - CENTRE).normalized(), (self.at(*end)[0] - CENTRE).normalized()
        turn = a.angle(b)
        line = []
        for i in range(n):
            u = i / (n - 1)
            v = a.slerp(b, u) if turn > 1e-4 else a
            p, nrm = self.at(*self.where(CENTRE + v))[:2]
            line.append((p + nrm * (off[0] + (off[1] - off[0]) * u + lift * math.sin(math.pi * u)), nrm))
        self.blade(line, width, thick or width * 0.22, ridge, taper, k, root=0.45)

    def sheet(self, grid, paint, size, outward, closed=False):
        """A smooth surface through `grid` (rows of points), wearing a picture of its own, `size` (texels across, down),
        that `paint(u, v, P, N)` lays: `u` across the rows, `v` down them, P and N each texel's point and the way out
        there. `outward(point, row, col)` says which way the surface faces. `closed`: each row's last point joins its
        first. One piece of hair as a whole: no edges or undersides between leaves to catch the light (AR60)."""
        rows, cols = len(grid), len(grid[0])
        span = cols if closed else cols - 1
        verts = [[self._vert(q) for q in row] for row in grid]
        faces = []
        for r in range(rows - 1):
            for c in range(span):
                c1 = (c + 1) % cols
                quad = (verts[r][c], verts[r][c1], verts[r + 1][c1], verts[r + 1][c])
                uv = {quad[0]: (c / span, r / (rows - 1)), quad[1]: ((c + 1) / span, r / (rows - 1)),
                      quad[2]: ((c + 1) / span, (r + 1) / (rows - 1)), quad[3]: (c / span, (r + 1) / (rows - 1))}
                f = self.bm.faces.new(quad)
                f.normal_update()
                mid = sum((v.co for v in quad), Vector()) / 4
                if f.normal.dot(outward(mid, r, c)) < 0:
                    f.normal_flip()
                f.smooth = True
                faces.append((f, uv))
        # each texel's point and way out, from the grid's own, between its rows and columns
        P = np.array([[tuple(q) for q in row] + ([tuple(row[0])] if closed else []) for row in grid], np.float64)
        du = np.gradient(P, axis=1)
        dv = np.gradient(P, axis=0)
        N = np.cross(du, dv)
        N /= np.maximum(np.linalg.norm(N, axis=2, keepdims=True), 1e-9)
        mids = P.mean(axis=(0, 1))
        if np.sum(N * (P - mids)) < 0:
            N = -N
        w, h = size
        u, v = np.meshgrid(np.linspace(0, 1, w), np.linspace(0, 1, h))
        cu, rv = u * (P.shape[1] - 1), v * (P.shape[0] - 1)
        c0, r0 = np.minimum(cu.astype(int), P.shape[1] - 2), np.minimum(rv.astype(int), P.shape[0] - 2)
        fc, fr = (cu - c0)[..., None], (rv - r0)[..., None]

        def at(A):
            top = A[r0, c0] * (1 - fc) + A[r0, c0 + 1] * fc
            low = A[r0 + 1, c0] * (1 - fc) + A[r0 + 1, c0 + 1] * fc
            return top * (1 - fr) + low * fr

        n = at(N)
        n /= np.maximum(np.linalg.norm(n, axis=2, keepdims=True), 1e-9)
        self.patches.append((np.clip(paint(u, v, at(P), n), 0, 1).astype(np.float32), faces))
        self.locks += 1

    def grooves(self, u, v, count, seed, start=(0.0, 0.35), end=(0.85, 1.0), dark=0.24, wide=0.006):
        """Lines of parted hair along `v`, `count` of them round `u`, each from a start to an end of its own and of a
        strength of its own, with a soft lit side: what makes a smooth mass read as a few big locks. A factor to
        multiply a colour by."""
        rng = np.random.default_rng(seed)
        k = np.ones_like(u)
        for i in range(count):
            at = (i + 0.5 + rng.uniform(-0.3, 0.3)) / count
            v0, v1, s = rng.uniform(*start), rng.uniform(*end), rng.uniform(0.6, 1.0)
            d = (u - at + 0.5) % 1.0 - 0.5
            fade = np.clip((v - v0) / 0.12, 0, 1) * np.clip((v1 - v) / 0.12, 0, 1)
            k -= dark * s * fade * np.exp(-(d / wide) ** 2)
            k += 0.07 * s * fade * np.exp(-((d - wide * 3.5) / (wide * 3)) ** 2)
        return k

    def mass(self, hairline, tie, opening=0.12, tips=(), rows=14, cols=72, off=(0.03, 0.1), lift=0.06, grooves=24, seed=1,
             size=(200, 64), k=1.0, inside=6):
        """The hair's whole mass in one piece, combed from its edge to a tie at `tie` (degrees round, down), where it
        leaves an `opening` (studs) under the tie: rows from the edge up, each line the shortest way over the egg.
        `hairline(degrees round)` is the edge's height; `tips`, each (degrees round, half its width, degrees down),
        are the points it hangs past it. It stands `off` over the head from the edge to the tie and `lift` more at
        its middle; a rim turned under at its edge gives it a thickness."""
        T = (self.at(*tie)[0] - CENTRE).normalized()
        grid = []
        for c in range(cols):
            a = 360.0 * c / cols
            wrapped = (a + 180) % 360 - 180
            z = hairline(abs(wrapped))
            ph = (math.degrees(math.acos(max(-1.0, min(1.0, (z - CENTRE.z) / SCALP_TOP)))) if z >= CENTRE.z
                  else 90 - (z - CENTRE.z) / (SCALP_TOP * math.pi / 180))
            for at_, half, deep in tips:
                d = abs((wrapped - at_ + 180) % 360 - 180)
                ph += deep * max(0.0, 1 - d / half) ** 1.4
            A = (self.at(a, ph)[0] - CENTRE).normalized()
            turn = A.angle(T)
            E = T.slerp(A, min(0.9, opening / SCALP / max(turn, 1e-4)))
            line = []
            for r in range(rows):
                s = (r / (rows - 1)) ** 0.85
                p, nrm = self.at(*self.where(CENTRE + A.slerp(E, s)))[:2]
                line.append(p + nrm * (off[0] + (off[1] - off[0]) * s + lift * math.sin(math.pi * s)))
            p0, n0 = self.at(a, ph)[:2]
            rim = line[0] - n0 * 0.07 + (line[1] - line[0]).normalized() * 0.04
            grid.append([rim] + line)
        grid = [list(row) for row in zip(*grid)]   # rows round the head, from the rim up to the tie
        top, band = self.pair[1], self.band
        base = self.colour(0.6, k)

        def paint(u, v, P, N):
            c = np.broadcast_to(base, P.shape).copy()
            g = band[2] * np.exp(-((P[..., 2] - CENTRE.z - band[0]) / band[1]) ** 2)
            c += (np.clip(top * 1.5 + 0.08, 0, 1) - c) * g[..., None]
            c *= (0.78 + 0.22 * np.clip((P[..., 2] - 4.3) / 0.7, 0, 1))[..., None]   # the lower sides in the mass's shade
            c *= (1 - 0.14 * np.clip((v - 0.86) / 0.14, 0, 1))[..., None]           # and under the tie
            c *= self.grooves(u, v, grooves, seed, start=(0.05, 0.4), end=(0.8, 0.96), dark=0.34, wide=0.007)[..., None]
            first = 1 / (rows)                                                       # the rim, turned under
            return np.where((v < first * 0.9)[..., None], c * 0.66, c)

        self.sheet(grid, paint, size, lambda q, r, c: q - CENTRE, closed=True)
        # its inner face along the edge, where it hangs clear of the head: a single face seen from inside is a hole,
        # and the points before the ears would break into splinters
        inner = [[q - (q - CENTRE).normalized() * 0.035 for q in row] for row in grid[1:inside + 1]]

        def under(u, v, P, N):
            c = np.broadcast_to(base * 0.62, P.shape).copy()
            return c * self.grooves(u, v, grooves // 2, seed + 1, start=(0.0, 0.2), end=(0.8, 1.0), dark=0.2, wide=0.01)[..., None]

        self.sheet(inner, under, (size[0] // 2, 16), lambda q, r, c: CENTRE - q, closed=True)

    def tail(self, points, radii, n=18, around=10, flat=0.75, gleam=(0.3, 0.14, 0.25), grooves=9, seed=2, size=(48, 120), k=1.0):
        """A tail as one solid lock: a tube through `points`, its radius along it from `radii` ((how far along, studs)
        each), flattened to `flat` of it toward the head; a band of light of its own where it turns over."""
        spine = [Vector(q) for q in smooth2([tuple(q) for q in points], n)]
        along_v = [i / (n - 1) for i in range(n)]
        rv = np.interp(along_v, [q[0] for q in radii], [q[1] for q in radii])
        grid, mids = [], []
        for i, q in enumerate(spine):
            t = (spine[min(i + 1, n - 1)] - spine[max(i - 1, 0)]).normalized()
            o = q - CENTRE
            o = (o - t * o.dot(t)).normalized()
            s = t.cross(o).normalized()
            r = max(float(rv[i]), 0.012)
            grid.append([q + s * math.cos(2 * math.pi * j / around) * r + o * math.sin(2 * math.pi * j / around) * r * flat
                         for j in range(around)])
            mids.append(q)
        base = self.colour(0.64, k)
        light = np.clip(self.pair[1] * 1.5 + 0.08, 0, 1)

        def paint(u, v, P, N):
            c = np.broadcast_to(base, P.shape).copy()
            c *= (0.72 + 0.34 * np.clip(N[..., 2] * 0.6 + 0.4, 0, 1))[..., None]
            g = gleam[2] * np.exp(-((v - gleam[0]) / gleam[1]) ** 2)
            c += (light - c) * g[..., None]
            c *= (1 - 0.16 * np.clip((0.06 - v) / 0.06, 0, 1))[..., None]          # in the tie's shade
            return c * self.grooves(u, v, grooves, seed, start=(0.02, 0.2), end=(0.75, 1.0), dark=0.3, wide=0.025)[..., None]

        self.sheet(grid, paint, size, lambda q, r, c: q - mids[r], closed=True)
        return spine

    def clump(self, a, ph, length, width, heading=0.0, bend=0.0, off=0.06, flick=30.0, hold=0.5, thick=None, comb=None,
              split=0, taper=1.6, k=None, n=None):
        """One clump, rooted `a` degrees round and `ph` down from the crown, `length` studs long and `width` across.
        It lies `off` studs over the head. `split`: smaller leaves from the same root, fanned to its sides, as a
        clump parts toward its end."""
        u = self.rng.uniform
        side = 1 if u(0, 1) < 0.5 else -1
        k = k or 1 + u(-1, 1) * 0.06
        n = n or (6 if length < 0.45 else 8 if length < 0.7 else 10)  # a long clump bends more, so it has more rings
        self.blade(self.spine(a, ph, length, heading, bend, comb, hold, flick, off, n), width, thick or width * 0.3, side * 0.35, taper, k)
        for i in range(split):
            s = side if i % 2 == 0 else -side
            self.blade(self.spine(a, ph, length * u(0.55, 0.8), heading + s * u(14, 26), bend + s * u(0, 14), comb, hold * u(0.8, 1.0),
                                  flick * u(0.9, 1.5), max(off - 0.02, 0.01), n), width * u(0.42, 0.58), (thick or width * 0.3) * 0.6,
                       s * 0.35, taper, k * 0.95)

    def row(self, count, ph, around, length, width, heading=0.0, bend=0.0, off=0.06, flick=30.0, hold=0.5, jitter=0.3, split=0.45,
            comb=None, sizes=(1.0, 0.74, 1.14, 0.66, 0.9), thick=None):
        """A row of clumps round the head through the degrees `around`, big, middling and small in turn, each a
        little off the row's own measures."""
        a0, a1 = around
        step = (a1 - a0) / count
        first = int(self.rng.integers(0, len(sizes)))
        j = lambda: self.rng.uniform(-1, 1) * jitter  # noqa: E731
        for i in range(count):
            size = sizes[(i + first) % len(sizes)] * (1 + j() * 0.3)
            self.clump(a0 + step * (i + 0.5 + j() * 0.7), ph + j() * 12, length * size, width * (0.55 + 0.45 * size), heading + j() * 40,
                       bend + j() * 40, off * (1 + j() * 0.5), flick * (1 + j()), min(0.95, hold * (1 + j() * 0.5)), thick, comb,
                       (1 + int(self.rng.uniform(0, 1) < 0.35)) if size > 0.85 and self.rng.uniform(0, 1) < split else 0)

    def build(self, folder, name="Hair"):
        # the picture: a strip a clump, its lit faces three points across and its underside two, `step` texels from
        # one of a clump's points to the next, so the game's own smoothing gives the colours between them
        step, cell, across = 4, 20, 220
        pitch = (max(len(s) for s in self.strips) - 1) * step + 4
        per_row = across // cell
        strips_tall = -(-len(self.strips) // per_row) * pitch + 8
        # the whole pieces' pictures below the strips, side by side where they fit
        places, x, y, row_h = [], 0, strips_tall, 0
        for pic, _ in self.patches:
            h, w = pic.shape[:2]
            if x + w + 2 > across:
                x, y, row_h = 0, y + row_h + 2, 0
            places.append((x + 1, y + 1))
            x, row_h = x + w + 2, max(row_h, h + 2)
        tall = y + row_h
        px = np.empty((tall, across, 3), np.float32)
        px[:] = self.colour(0.6)
        px[strips_tall - 8:strips_tall, :8] = getattr(self, "scalp", self.colour(0.4))
        for (pic, _), (x0, y0) in zip(self.patches, places):
            h, w = pic.shape[:2]
            px[y0 - 1:y0 + h + 1, x0 - 1:x0 + w + 1] = np.pad(pic, ((1, 1), (1, 1), (0, 0)), mode="edge")

        def spread(grid):
            n, k = grid.shape[:2]
            rows, cols = np.linspace(0, n - 1, (n - 1) * step + 1), np.linspace(0, k - 1, (k - 1) * step + 1)
            r0, c0 = np.minimum(rows.astype(int), n - 2), np.minimum(cols.astype(int), k - 2)
            fr, fc = (rows - r0)[:, None, None], (cols - c0)[None, :, None]
            g = grid[r0] * (1 - fr) + grid[r0 + 1] * fr
            return np.pad(g[:, c0] * (1 - fc) + g[:, c0 + 1] * fc, ((1, 1), (1, 1), (0, 0)), mode="edge")

        corner = lambda i: ((i % per_row) * cell, (i // per_row) * pitch)  # noqa: E731
        for i, s in enumerate(self.strips):
            x0, y0 = corner(i)
            lit, under = spread(s[:, :3]), spread(s[:, 3:])
            px[y0:y0 + lit.shape[0], x0:x0 + lit.shape[1]] = lit
            px[y0:y0 + under.shape[0], x0 + 11:x0 + 11 + under.shape[1]] = under
        px = np.clip(px, 0, 1)   # the clumps' colours are light's own measure; a picture holds the screen's
        px = np.where(px <= 0.0031308, px * 12.92, 1.055 * px ** (1 / 2.4) - 0.055).astype(np.float32)
        uv = self.bm.loops.layers.uv.new("UVMap")
        for f in self.bm.faces:
            for loop in f.loops:
                loop[uv].uv = (4 / across, 1 - (strips_tall - 4) / tall)  # the scalp's colour
        for f, i, where in self.charts:
            x0, y0 = corner(i)
            for loop, (j, col) in zip(f.loops, where):
                x = x0 + 1.5 + col * step if col <= 2 else x0 + 12.5 + (col - 3) * step
                loop[uv].uv = (x / across, 1 - (y0 + 1.5 + j * step) / tall)
        for (pic, faces), (x0, y0) in zip(self.patches, places):
            h, w = pic.shape[:2]
            for f, where in faces:
                for loop in f.loops:
                    pu, pv = where[loop.vert]
                    loop[uv].uv = ((x0 + 0.5 + pu * (w - 1)) / across, 1 - (y0 + 0.5 + pv * (h - 1)) / tall)
        mesh = bpy.data.meshes.new(name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        m = textured(name, px, folder)
        m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
        m.use_backface_culling = True  # as the game draws it: a leaf wound the wrong way shows as a hole
        mesh.materials.append(m)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        PICTURES[obj.name] = px
        return obj


# --- built pieces ------------------------------------------------------------------------------------------------------

class Built:
    """A built attachment: a scarf's loop and its tail, a blade, a ribbon. One mesh that rides one part, closed on
    every side, since the game draws a face from its front only. Its colours are flat, one to a face, kept as a
    small picture of swatches: the light's fall along a piece is its faces' own colours, one stretch after another."""

    CELL, ACROSS = 8, 16

    def __init__(self, name):
        self.name, self.bm, self.cells, self.faces = name, bmesh.new(), [], []

    def _cell(self, colour):
        c = tuple(round(float(v), 3) for v in np.clip(rgb(colour), 0, 1))
        if c not in self.cells:
            self.cells.append(c)
        return self.cells.index(c)

    def face(self, points, colour, smooth=True):
        """One face through `points` (places, or points already made), wound so it faces the viewer who sees them
        turn anticlockwise."""
        verts = [v if isinstance(v, bmesh.types.BMVert) else self.bm.verts.new(v) for v in points]
        f = self.bm.faces.new(verts)
        f.smooth = smooth
        self.faces.append((f, self._cell(colour)))
        return verts

    def tube(self, rings, colours, caps=None, smooth=True):
        """A skin over `rings` (each the same count of places, going the same way round): `colours` gives a colour
        for the stretch `i` between two rings and the side `k` round it. `caps`: a colour for each end, or None to
        leave it open."""
        made = [[self.bm.verts.new(v) for v in ring] for ring in rings]
        n = len(made[0])
        for i in range(len(made) - 1):
            for k in range(n):
                a, b = made[i], made[i + 1]
                self.face((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]), colours(i, k), smooth)
        if caps:
            if caps[0] is not None:
                self.face(list(reversed(made[0])), caps[0], False)
            if caps[1] is not None:
                self.face(made[-1], caps[1], False)
        return made

    def ribbon(self, spine, widths, colour, side=(1, 0, 0), thick=0.04, under=0.6, edge=0.45, turn=None, caps=(True, True)):
        """Cloth along `spine`: `widths` across at each point, `thick` through. `side` is the way its width lies at
        the first point, carried along from there; `turn` adds a twist, degrees at each point. `colour`: one, or a
        function of how far along (0 to 1). Its underside is `under` as bright, its two edges `edge`. `thick` may be
        one or one a point; `caps`, whether each end is closed (a link tucked into the next is left open)."""
        pts = [Vector(q) for q in spine]
        n = len(pts)
        widths = [widths] * n if np.isscalar(widths) else list(widths)
        thicks = [thick] * n if np.isscalar(thick) else list(thick)
        s = Vector(side).normalized()
        rings = []
        for i, q in enumerate(pts):
            d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            s = (s - d * s.dot(d)).normalized()
            w = Matrix.Rotation(math.radians(turn[i]), 3, d) @ s if turn else s
            up = d.cross(w).normalized()
            half, t2 = w * widths[i] / 2, up * thicks[i] / 2
            rings.append([q - half + t2, q + half + t2, q + half - t2, q - half - t2])
        shade = colour if callable(colour) else (lambda u: colour)

        def colours(i, k):
            c = shade((i + 0.5) / (n - 1))
            return c if k == 0 else tone(c, under) if k == 2 else tone(c, edge)

        self.tube(rings, colours, caps=(tone(shade(0.0), edge) if caps[0] else None, tone(shade(1.0), edge) if caps[1] else None),
                  smooth=False)

    def loop(self, centre, radius, tall, colour, thick=0.16, segments=20, lean=None, squash=1.0, shades=(1.12, 1.0, 0.72, 0.5)):
        """A scarf's turn round the neck: a soft ring about `centre` (its foot), `radius` out and `squash` as deep
        front to back, `tall` high and `thick` through. `lean`: its height the way round, a function of degrees
        from the front, in place of `tall`. `shades`: its top, its outside, its underside and its inside."""
        c = Vector(centre)
        rings = []
        for i in range(segments):
            a = i / segments * 2 * math.pi
            h = lean(math.degrees(a) if a <= math.pi else math.degrees(a) - 360) if lean else tall
            out = Vector((math.sin(a), math.cos(a) * squash, 0.0))
            mid = c + out * radius
            rings.append([mid + out * thick * 0.5 + Vector((0, 0, h * 0.82)), mid + out * thick * 0.5 + Vector((0, 0, h * 0.12)),
                          mid - out * thick * 0.5, mid - out * thick * 0.5 + Vector((0, 0, h)), ])
        made = [[self.bm.verts.new(v) for v in ring] for ring in rings]
        for i in range(segments):
            a, b = made[i], made[(i + 1) % segments]
            for k, s in enumerate((shades[1], shades[2], shades[3], shades[0])):   # outside, under, inside, top
                self.face((a[k], b[k], b[(k + 1) % 4], a[(k + 1) % 4]), tone(colour, s))

    def blade(self, base, tip, width, colours, grip=0.42, thick=0.05, guard=0.07, flat=(0, 1, 0), point=0.3):
        """A short blade from the grip's end at `base` to its `tip`: a wrapped grip, a small guard, then a flat
        blade with one ridge, drawn to a point over its last `point` studs. `flat`: the way its flat faces.
        `colours`: the grip, the guard, the blade's lit bevel and its dark one."""
        a, b = Vector(base), Vector(tip)
        d = (b - a).normalized()
        n = Vector(flat)
        n = (n - d * n.dot(d)).normalized()
        s = d.cross(n).normalized()
        wrap, metal, lit_, dim = colours
        long_ = (b - a).length

        def ring(at, w, th):
            q = a + d * at
            return [q + n * th, q + s * w, q - n * th, q - s * w]

        g = width * 0.3
        self.tube([ring(0.0, g, g * 0.8), ring(grip, g, g * 0.8)], lambda i, k: tone(wrap, 1.0 if k in (0, 3) else 0.7),
                  caps=(tone(wrap, 0.6), None), smooth=False)
        self.tube([ring(grip, width * 0.75, thick * 1.3), ring(grip + guard, width * 0.75, thick * 1.3)],
                  lambda i, k: tone(metal, 1.0 if k in (0, 3) else 0.7), caps=(tone(metal, 0.7), tone(metal, 0.7)), smooth=False)
        self.tube([ring(grip + guard, width / 2, thick / 2), ring(long_ - point, width / 2, thick / 2), ring(long_, 0.004, 0.004)],
                  lambda i, k: lit_ if k in (0, 2) else dim, smooth=False)

    def build(self, folder):
        cell, across = self.CELL, self.ACROSS
        rows = -(-len(self.cells) // across)
        px = np.zeros((rows * cell, across * cell, 3), np.float32)
        for i, c in enumerate(self.cells):
            px[(i // across) * cell:(i // across + 1) * cell, (i % across) * cell:(i % across + 1) * cell] = c
        for i in range(len(self.cells), rows * across):   # the spare cells take the last colour, so no black bleeds in
            px[(i // across) * cell:(i // across + 1) * cell, (i % across) * cell:(i % across + 1) * cell] = self.cells[-1]
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])   # every face outward, whatever way it was wound
        uv = self.bm.loops.layers.uv.new("UVMap")
        for f, i in self.faces:
            at = (((i % across) + 0.5) * cell / px.shape[1], 1 - ((i // across) + 0.5) * cell / px.shape[0])
            for loop in f.loops:
                loop[uv].uv = at
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        m = textured(self.name, px, folder)
        m.use_backface_culling = True
        mesh.materials.append(m)
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        PICTURES[obj.name] = px
        return obj


def hairline(front=4.96, temple=4.5, nape=4.08):
    return lambda deg: float(np.interp(deg, [0, 38, 78, 125, 180], [front, front - 0.02, temple, nape + 0.1, nape]))


# --- a plain stand-in, to judge the make by ----------------------------------------------------------------------------

SKIN = "#F0C3A0"
BODY = {"torso": ((0, 0, 3), (2, 1, 2)), "rs": ((1.5, 0, 3), (1, 1, 2)), "ls": ((-1.5, 0, 3), (1, 1, 2)),
        "rh": ((0.5, 0, 1), (1, 1, 2)), "lh": ((-0.5, 0, 1), (1, 1, 2))}
JOINT = {"torso": "root", "rs": "rs", "ls": "ls", "rh": "rh", "lh": "lh"}


def stand_in(joints, folder):
    """A plain figure: a short jacket open over a shirt, trousers, shoes, short messy hair. No design is meant."""
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
    hair = Hair("#4A2C1C", "#D6A068", seed=7)
    hair.shell(hairline())
    # from the nape up, each row lying on the one below, all turned one way round the crown; the tips turn out
    hair.row(7, 92, (105, 255), 0.5, 0.34, heading=6, off=0.03, flick=15, hold=0.5)
    hair.row(9, 60, (70, 290), 0.8, 0.42, heading=12, off=0.07, flick=22, hold=0.4)
    hair.row(8, 34, (50, 310), 0.9, 0.46, heading=18, off=0.11, flick=26, hold=0.4)
    hair.row(6, 10, (-180, 180), 0.85, 0.46, heading=25, off=0.14, flick=28, hold=0.45)
    hair.row(3, 7, (-180, 180), 0.6, 0.32, heading=55, off=0.12, flick=48, hold=0.2, split=1.0)
    # the fringe: five clumps down the forehead, the one beside the nose the longest, parted off the middle
    for a, length, width, heading, bend, split in ((-46, 0.62, 0.36, -14, -12, 1), (-24, 0.74, 0.4, -8, 10, 1), (-4, 0.84, 0.34, 6, -10, 0),
                                                   (16, 0.7, 0.4, 12, 8, 1), (40, 0.6, 0.36, 18, 12, 1)):
        hair.clump(a, 40, length, width, heading=heading, bend=bend, off=0.07, flick=16, hold=0.7, split=split)
    # and a lock before each ear, to the jaw
    for s in (-1, 1):
        hair.clump(s * 72, 52, 0.78, 0.3, heading=s * -6, bend=s * 8, off=0.05, flick=14, hold=0.75, split=1)
    made["head"], made["hair"] = head.build(folder), hair.build(folder)
    wt.on(joints, "neck", made["head"], made["hair"])
    print(f"hair: {hair.locks} locks")
    return made


# --- the handoff: one picture, and the pieces as the builder's recipe reads them ----------------------------------------

ATLAS, PAD = 1024, 4
KEEP = {"head": 156 / FACE_PPU, "hair": 1.0}   # how much of its own size a picture keeps in the one picture
BODY_KEEP = 96 / PPU                           # the body's: 96 texels a stud
PIECE = {"torso": ("Torso", "Torso"), "rs": ("RightArm", "Right Arm"), "ls": ("LeftArm", "Left Arm"), "rh": ("RightLeg", "Right Leg"),
         "lh": ("LeftLeg", "Left Leg"), "head": ("Head", "Head"), "hair": ("Hair", "Head")}   # a piece's name, and R6's part it rides
ROUGH = {"hair": 0.8}                          # the rest is cloth and skin, 1


def handoff(name, made, out, points=(), tint="#FFA630", hot=5.0, extra=None, make=None):
    """What the builder installs (tools/studio/ModelRecipe.luau), from a figure as `figure` builds it: <name>_Color.png,
    every piece's picture laid in one; <name>_Roughness.png; <name>_Emissive.png if a block lights up; a piece's mesh
    each, <name>_<Piece>.json; and <name>.recipe.json. The pieces then wear the one picture, so whatever is drawn of
    them after this is drawn from the files that go up. `points` are (name, R6's part, where) in the kit's frame.
    `extra`: the built pieces, {key: (piece, what it rides)}; their pictures go in whole. `make`: the recipe's word on
    how it is made, if not the kit's alone."""
    import json
    out.mkdir(parents=True, exist_ok=True)
    colour, rough = rs.canvas(ATLAS, ATLAS, (0.5, 0.5, 0.5)), rs.canvas(ATLAS, ATLAS, (1.0, 1.0, 1.0))
    glow = rs.canvas(ATLAS, ATLAS, (0.0, 0.0, 0.0))
    shelves, lit = [], []
    tiles = {}
    for key, obj in made.items():
        px, keep = PICTURES[obj.name], 1.0 if key in (extra or {}) else KEEP.get(key, BODY_KEEP)
        small = lambda a, keep=keep: a if keep == 1.0 else rs.shrink(np.dstack([a, np.ones(a.shape[:2], np.float32)]), keep)[..., :3]  # noqa: E731
        tiles[key] = (small, small(px))
    for key in sorted(made, key=lambda k: -tiles[k][1].shape[0]):   # the tallest first: they pack closest
        obj = made[key]
        small, tile = tiles[key]
        th, tw = tile.shape[:2]
        shelf = next((s for s in shelves if s[1] + tw + PAD <= ATLAS and th <= s[2]), None)
        if shelf is None:
            shelf = [shelves[-1][0] + shelves[-1][2] + 2 * PAD if shelves else PAD, PAD, th]
            shelves.append(shelf)
        y, x = shelf[0], shelf[1]
        assert y + th + PAD <= ATLAS, (f"{name}: {key}'s picture, {tw} x {th}, doesn't fit the one picture: "
                                       + ", ".join(f"{k} {t.shape[1]}x{t.shape[0]}" for k, (_, t) in tiles.items()))
        shelf[1] = x + tw + 2 * PAD
        colour[y - PAD:y + th + PAD, x - PAD:x + tw + PAD, :3] = np.pad(tile, ((PAD, PAD), (PAD, PAD), (0, 0)), mode="edge")
        rough[y - PAD:y + th + PAD, x - PAD:x + tw + PAD, :3] = ROUGH.get(key, 1.0)
        if obj.name in GLOWS:
            glow[y:y + th, x:x + tw, :3] = small(np.repeat(GLOWS[obj.name][..., None], 3, axis=2))
            lit.append(key)
        for d in obj.data.uv_layers.active.data:
            u, v = d.uv
            d.uv = ((x + u * tw) / ATLAS, 1 - (y + (1 - v) * th) / ATLAS)
    maps = {"Color": colour, "Roughness": rough, **({"Emissive": glow} if lit else {})}
    for kind, px in maps.items():
        rs.save(px, out / f"{name}_{kind}.png")
    m = bpy.data.materials.new(name)
    bsdf, nodes, links = bl._principled(m)
    for kind, socket in (("Color", "Base Color"), ("Roughness", "Roughness")):
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(out / f"{name}_{kind}.png"))
        if kind != "Color":
            tex.image.colorspace_settings.name = "Non-Color"
        links.new(tex.outputs["Color"], bsdf.inputs[socket])
    m.use_backface_culling = True
    turn = lambda q: [round(q[0], 4), round(q[2], 4), round(-q[1], 4)]  # noqa: E731  the kit's frame to Roblox's
    pieces, total = [], 0
    for key, obj in made.items():
        piece, on = (extra or {}).get(key) or PIECE[key]
        obj.name = obj.data.name = f"{name}_{piece}"
        obj.data.materials.clear()
        obj.data.materials.append(m)
        tris = bl.export_mesh_json(obj, out / f"{obj.name}.json")
        total += tris
        box = [v.co for v in obj.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        pieces.append({"name": obj.name, "mesh": f"{obj.name}.json", "on": on,
                       "centre": json.loads((out / f"{obj.name}.json").read_text())["c"], "size": size, "tris": tris})
        print(f"{obj.name}: {tris} tris, {size} studs")
    recipe = {
        "name": name,
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0)",
        "rig": "R6. Every piece carries the body's own surface: the six rig parts are hidden (Transparency 1).",
        "make": make or "tools/blender/anime_make.py: R6's own blocks and round head with the clothes and the face drawn on them, "
                        "and the hair one mesh. Nothing rides a joint of its own.",
        "maps": {kind: f"{name}_{kind}.png" for kind in maps},
        "texels_per_stud": round(BODY_KEEP * PPU),
        "pieces": pieces,
        "points": [{"name": n, "on": on, "at": turn(at), **({"note": note} if note else {})} for n, on, at, note in points],
        "tris": total,
    }
    if lit:
        recipe["emissive"] = {"tint": tint, "cold": 0, "hot": hot, "pieces": [f"{name}_{((extra or {}).get(key) or PIECE[key])[0]}" for key in lit],
                              "note": "the mask is the light's shape, 0 to 1. Roblox draws the glow through the colour map, "
                                      "(mask x strength x tint + light) x colour; the strength is the game's to play."}
    (out / f"{name}.recipe.json").write_text(json.dumps(recipe, indent=1))
    return recipe


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


def turnaround(scene, joints, shots, key):
    """The head from six sides in one picture: face on, each three-quarter, a side, the back and the game's camera."""
    for joint in joints.values():
        joint.rotation_quaternion = (1, 0, 0, 0)
    joints["root"].location = wt.PIVOTS["root"]
    rs.POSES["square"](joints)
    rm.eevee(scene, 420, 420)
    tiles = []
    for azimuth, elevation in ((180, 4), (146, 8), (214, 8), (90, 4), (0, 6), rs.GAME):
        rm.sun_for(scene, azimuth)
        fill_for(scene, azimuth)
        rs.shoot(scene, shots / f"{key}_turn.png", azimuth, elevation, (0.0, 0.0, 4.55), 2.9)
        tiles.append(rs.load(shots / f"{key}_turn.png"))
    page = rs.canvas(420 * 3, 420 * 2, rs.rgb("#2A2D36"))
    for i, tile in enumerate(tiles):
        rs.paste(page, tile, (i % 3) * 420, (i // 3) * 420)
    rs.save(page, shots / f"{key}_turn.png")


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
    turnaround(scene, joints, shots, "standin")


if __name__ == "__main__":
    rs.OUT = bl.out_dir()
    run(rs.OUT)
