"""The effects kit's drawn sheets (AR9, docs/asset-requests.md): flipbooks of our own, each in two passes and a dark twin,
for particles, beside fx_kit.py's meshes and 2x2 textures.

blender.exe -b --factory-startup --python tools/blender/fx_sheets.py -- <out_dir> [puff ring crescent starburst spark glint
flame]
blender.exe -b --factory-startup --python tools/blender/fx_sheets.py -- <out_dir> movie

(No names: all seven. movie: the kit's movie, from the sheets already drawn in <out_dir>.)

Each sheet is 1024 px, a 4 x 4 grid of 256 px frames, read left to right and top to bottom (FlipbookLayout Grid4x4,
OneShot: one pass through the grid over a particle's life). Three textures a sheet, all white with alpha, tinted in the
game by the emitter's Color, so one drawing serves every palette:
- fx_<name>_line: the outline pass, the drawing's ink, heavier on the shadow side (down and right). Alone, it's a quiet
  hit; with the fill, a signature.
- fx_<name>_fill: the fill pass, in flat toon steps (shadow, body, highlight), lit from up and to the left.
- fx_<name>_dark: the dark twin, played under the other two at LightEmission 0 in a near-black colour: the silhouette
  grown and nudged down and to the right, lagging the bright passes as they break, so the shape holds on a pale sky.
Drawn at SS times the size and boxed down. The clear texels carry each pass's own value, so no rim comes in where the
engine filters an edge.

How every sheet ends (research's read of the pilot, AR9): it never holds still and then pops. It keeps moving to its last
frame, and it breaks over five or six frames, each texel in its own turn (`first`: the edges and the top go first for a
cloud), into pieces drawn out along the shape's own flow that shrink to nothing. As a texel breaks, its fill flattens to
one tone and thins toward clear, its ink dashes and thins, and the twin under it fades. The fill's colour over life goes
from its own tint toward the twin's cool tone (COOL), never toward brown: that's the row's ColorSequence, written for the
builder in fx_sheets.json with each sheet's life and break.

Also writes <name>_frames.png (every frame at 128 px, each pass alone and all three, on our noon sky and our night),
fx_kit_preview.mp4 (every sheet looping at its own life, at 128 and 64 px, on both skies) with a poster still, and
fx_sheets.json. Workbench is never used: no GPU turn.
"""
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import frames_to_movie  # noqa: E402
import rook_sheet as rs  # noqa: E402

CELL, GRID, SS = 256, 4, 3      # a frame's px, frames across and down, supersampling
FRAMES = GRID * GRID
PX = 2.0 / (CELL * SS)          # one supersampled texel, in half widths
NOON, NIGHT = rs.rgb("#5FADDA"), rs.rgb("#0E1018")  # the base's noon sky and Lantern Row's night (levelup_column_art)
HEX = {"line": "#FFF6E6", "fill": "#E9E2D6", "dark": "#1C1726", "cool": "#5B5670"}
TINTS = {name: rs.rgb(h) for name, h in HEX.items()}  # the preview's Colors; cool: where the fill's colour goes
DARK_ALPHA = 0.85               # the twin's opacity in the preview: a row's Transparency 0.15
GAP, FPS = 0.25, 60             # the preview: the pause between lives, in seconds, and its rate

LIGHT = np.array((-0.45, 0.6, 0.66)) / np.linalg.norm((-0.45, 0.6, 0.66))  # from up and to the left, toward the viewer
SHADOW = (0.6, -0.8)            # the shadow side, down and to the right: the ink is heavier there
STEPS = ((0.15, 0.46, 0.7), (0.62, 0.7, 0.95))  # the fill's toon steps: (shade where it changes, from, to)
BODY = STEPS[0][2]              # the body's tone, where a breaking piece flattens to
INK = 0.034                     # the outline's width, in half widths
GROW, NUDGE, SOFT = 0.045, (0.015, -0.02), 0.025  # the twin: grown by, nudged by (x, y), its edge's softness
LAG = 0.02                      # how far the twin's break runs behind the bright passes (of its life)
PACE = 1.2                      # a texel's break: its pace, from 0 to 1 over its own turn
TEAR = (1.45, 0.5)              # a tearing shape keeps the texels whose hole is under this, from first (above any hole,
                                # so nothing is pricked before its turn) to last
SHRINK = 0.3                    # how far a tearing shape's edge shrinks too, of its depth
THIN_BY = 1.1                   # how deep a thinning shape (it shrinks, it doesn't tear) eats by its end, of its depth
FLAT = 0.85                     # how far a breaking piece's shading flattens to one tone, so it never reads as a lump
SINK = 0.25                     # how far a breaking piece's value sinks
THIN = 0.6                      # how far a breaking piece's fill thins toward clear
WRAP = 6                        # the wrapped noises' cells once round: a shape's flow, for pieces drawn out along it

# --- the drawing's tools ---------------------------------------------------------------------------------------------


def smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


def step(x, edge, width):
    """0 below `edge`, 1 above, through `width` (a drawn edge, antialiased by the supersampling)."""
    return smooth((x - edge) / width + 0.5)


def wrap(a):
    return (a + math.pi) % (2 * math.pi) - math.pi


class Noise:
    """Smooth value noise on a lattice, 0 to 1, wrapped every `nx` cells across and `ny` down."""

    def __init__(self, seed, nx=64, ny=64):
        self.t, self.nx, self.ny = np.random.default_rng(seed).random((ny, nx)).astype(np.float32), nx, ny

    def __call__(self, x, y):
        xi, yi = np.floor(x), np.floor(y)
        fx, fy = smooth(x - xi), smooth(y - yi)
        xi, yi = xi.astype(np.int64) % self.nx, yi.astype(np.int64) % self.ny
        x1, y1, t = (xi + 1) % self.nx, (yi + 1) % self.ny, self.t
        a = t[yi, xi] + (t[yi, x1] - t[yi, xi]) * fx
        b = t[y1, xi] + (t[y1, x1] - t[y1, xi]) * fx
        return a + (b - a) * fy


def smin(a, b, k):
    """A smooth union of two distances: shapes melt into each other over `k`."""
    h = np.maximum(k - np.abs(a - b), 0.0) / k
    return np.minimum(a, b) - h * h * k * 0.25


def field(n=CELL * SS):
    """x, y across a frame, -1 to 1, y up, at texel centres; row 0 is the top."""
    c = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(c, -c)
    return x, y


def normals(d):
    """The outward direction of a distance field at each texel, as unit x, y (y up)."""
    g_row, g_col = np.gradient(d)
    gx, gy = g_col, -g_row
    n = np.hypot(gx, gy) + 1e-9
    return gx / n, gy / n


def as_distance(c, floor=0.3):
    """A field cut at zero, made a distance by its own slope (to a first order), so its edge takes an even ink line and
    a crisp twin."""
    g_row, g_col = np.gradient(c)
    return c / np.maximum(np.hypot(g_row, g_col) / PX, floor)


def pillow(d, bevel):
    """A shape's shade as a rounded relief: its edge turns away over `bevel`, its middle faces the viewer. A thin shape
    with `bevel` its half width shades as a tube."""
    gx, gy = normals(d)
    side = 1 - np.clip(-d / bevel, 0.0, 1.0)
    nz = np.sqrt(np.clip(1 - side * side, 0.0, 1.0))
    return gx * side * LIGHT[0] + gy * side * LIGHT[1] + nz * LIGHT[2]


def toon(shade):
    value = np.full_like(shade, STEPS[0][1])
    for edge, lo, hi in STEPS:
        value = value + (hi - lo) * step(shade, edge, 0.04)
    return value


def pack(value, cover, bleed):
    """A pass's texels at SS times the size, boxed down to a frame: white-valued with alpha; the clear texels take
    `bleed`, the pass's own value."""
    rgba = np.empty(cover.shape + (4,), dtype=np.float32)
    rgba[..., :3] = np.clip(value, 0, 1)[..., None]
    rgba[..., 3] = np.clip(cover, 0, 1)
    out = rs.shrink(rgba, 1 / SS)
    clear = out[..., 3] < 1e-3
    out[clear, :3] = bleed
    return out


# --- every sheet's finish: the break, the fill, the ink, the twin ----------------------------------------------------


def finish(s, t, e, x, y, noise, schedule):
    """The three passes from a shape `s` at time `t` (e: how far its break has gone, 0 to 1): (line, fill, dark), each
    (value, cover, bleed). `s` holds d (the whole shape's distance, negative inside), hole (about 0.5 to 1.4: a tearing
    shape loses its high texels first, so the pieces left are the low cells of this field, drawn out along the shape's
    flow; a thinning shape eats deepest where it's high), first (1: this texel breaks first), depth (the shape's
    thickest half width), and either shade or bevel, with ink (a width factor), seams and thin (it shrinks, it doesn't
    tear) if it has them. `schedule`: (start, sweep, each) of its life: the first texels start breaking at start, the
    last at start + sweep, each taking `each`."""
    start, sweep, each = schedule

    def local(at):
        return np.clip((at - (start + (1 - s["first"]) * sweep)) / each, 0.0, 1.0)

    if s.get("thin"):
        def broken(at):
            return s["d"] + THIN_BY * s["depth"] * s["hole"] * at ** PACE
    else:
        def broken(at):
            keep = TEAR[0] + (TEAR[1] - TEAR[0]) * at ** PACE
            return np.maximum(s["d"] + SHRINK * s["depth"] * at, as_distance(s["hole"] - keep))

    lb, ld = local(t), local(t - LAG)
    d, d_dark = broken(lb), broken(ld)
    aa = 1.5 * PX
    ink_k = s.get("ink", 1.0)

    # the fill: toon steps, the highlights shrinking as it breaks, a breaking piece one tone that thins toward clear
    shade = (s["shade"] if "shade" in s else pillow(s["d"], s["bevel"])) - 0.5 * lb
    flat = FLAT * smooth((lb - 0.1) / 0.5)
    value = (toon(shade) * (1 - flat) + BODY * flat) * (1 - SINK * lb)
    fill = (value, step(-d, 0.0, aa) * (1 - THIN * smooth(lb)), BODY * (1 - SINK * e))

    # the ink: heavier on the shadow side, thinning and breaking into dashes as it goes
    gx, gy = normals(d)
    heavy = gx * SHADOW[0] + gy * SHADOW[1]
    width = INK * ink_k * (0.75 + 0.3 * heavy) * (1 - 0.45 * lb)
    dash = step(noise[5](x * 12, y * 12), 0.85 * lb - 0.05, 0.06)
    line = step(width / 2 - np.abs(d + width * 0.35), 0.0, aa) * dash
    if "seams" in s:
        line = np.maximum(line, s["seams"] * (1 - smooth(lb / 0.3)) * step(-d, width, aa))
    line_pass = (1.0, line * (1 - 0.5 * lb), 1.0)

    # the twin: grown, nudged, a little late to break, a thin margin round the pieces; it stays crisp (a fade texel by
    # texel smudges), only lighter as the whole breaks
    grow = GROW * ink_k * (1 - 0.8 * ld)
    dark = step(-(d_dark - grow), 0.0, SOFT) * (1 - 0.6 * smooth(e))
    dx, dy = int(round(NUDGE[0] / PX)), int(round(-NUDGE[1] / PX))
    dark = np.roll(np.roll(dark, dy, axis=0), dx, axis=1)
    return line_pass, fill, (1.0, dark, 1.0)


# --- the puff: a knot that bursts into round billows, rises and curls, then tears into wisps from its edges and top --

R = 0.74                      # the cloud's reach, in a frame's half width
LOBES = (                     # each billow: its heading in degrees, how far out (of R), its radius (of R), how far it drifts
    (0, 0.0, 0.42, 0.0), (90, 0.5, 0.36, 1.1), (35, 0.55, 0.33, 0.9), (-15, 0.6, 0.3, 1.2),
    (-70, 0.5, 0.32, 0.8), (-120, 0.52, 0.3, 1.0), (-170, 0.58, 0.31, 1.15), (140, 0.55, 0.34, 0.95),
)
KNOT = 0.18                   # the size it starts at (of its full size)
RISE, CURL = 0.1, 8.0         # how far it rises over its life (half widths), and how far it turns (degrees)
SEAM = 0.012                  # a seam's width, in half widths
FAN, FAN_FROM = 16, 0.6       # the break's pieces: how many round, and how far under the centre they fan from (of R)
PUFF_TEAR = Noise(57, nx=FAN)  # wrapped once round, so the pieces have no seam


def grown(t, fast=0.8, ease=4.5):
    """Growth that never stops: most of it at once (ease out), the rest steadily to the last frame."""
    return fast * (1 - (1 - t) ** ease) + (1 - fast) * t


def puff(t, e, f, x, y, noise):
    size = KNOT + (1 - KNOT) * grown(t)  # about 70% by frame 5, still growing at 16
    rise = RISE * smooth(t) + 0.08 * e
    # the wobble is the cloud's own, so it grows with it; a little of it changes every frame, like a drawing
    u, v = x / size, (y - rise) / size
    wx = (noise[0](u * 2.6, v * 2.6) - 0.5) + 0.25 * (noise[1](u * 7 + f * 3.1, v * 7) - 0.5)
    wy = (noise[2](u * 2.6, v * 2.6) - 0.5) + 0.25 * (noise[3](u * 7, v * 7 + f * 2.7) - 0.5)
    px, py = x + 0.07 * size * wx, y + 0.07 * size * wy

    centres, radii, dist = [], [], None
    for heading, out, radius, drift in LOBES:
        a = math.radians(heading + CURL * t)
        reach = R * size * out * (1 + 0.25 * drift * t + 0.3 * drift * e)  # the wisps drift apart as it breaks
        cx, cy = reach * math.cos(a), reach * math.sin(a) + rise + (0.04 * t if out and math.sin(a) > 0 else 0.0)
        r = R * size * radius * (1 + 0.15 * t)
        centres.append((cx, cy))
        radii.append(r)
        d = np.hypot(px - cx, py - cy) - r
        dist = d if dist is None else smin(dist, d, 0.1 * R * size)

    # the break: long pieces pointing outward and up, as smoke leaves (research's pass on the kit: pieces long round
    # the centre tore it as a whirlpool). They fan from a point under the cloud, so the top's point up and the sides'
    # out; narrow across, long along, bent a little with the curl. The edges and the top first, raggedly
    off_x, off_y = px - centres[0][0], py - centres[0][1]
    out_ = np.hypot(off_x, off_y) / (R * size)
    fx_, fy_ = off_x, off_y + FAN_FROM * R * size
    fan = ((np.arctan2(fy_, fx_) / (2 * math.pi) + 0.5) * FAN - CURL * t / 360 * FAN
           + 0.6 * np.hypot(fx_, fy_) / (R * size))
    hole = (0.25 * noise[4](u * 2.4, v * 2.4) + 0.1 * noise[6](u * 6.5, v * 6.5)
            + 0.65 * PUFF_TEAR(fan, np.hypot(fx_, fy_) / (R * size) * 1.6)) * 0.9 + 0.5
    up = np.clip(off_y / (R * size), -1, 1)
    first = np.clip(0.55 * out_ + 0.45 * (0.5 + 0.5 * up) + 0.25 * (noise[4](u * 3.1, v * 3.1) - 0.5), 0, 1)

    # each billow as a ball: the front-most one at a texel gives its shade; where two meet is a seam
    heights, shades, turned = [], [], []
    for (cx, cy), r in zip(centres, radii):
        qx, qy = (px - cx) / r, (py - cy) / r
        z = np.sqrt(np.clip(1 - qx * qx - qy * qy, 0, 1))
        heights.append(np.where(z > 0, r * z, -1.0))
        shades.append(qx * LIGHT[0] + qy * LIGHT[1] + z * LIGHT[2])
        turned.append(qx * SHADOW[0] + qy * SHADOW[1])  # how far round to its shadow side a texel is on a billow
    heights, shades, turned = np.stack(heights), np.stack(shades), np.stack(turned)
    order = np.argsort(heights, axis=0)
    front = order[-1:]
    h1 = np.take_along_axis(heights, front, 0)[0]
    h2 = np.take_along_axis(heights, order[-2:-1], 0)[0]
    shade = np.where(h1 > 0, np.take_along_axis(shades, front, 0)[0], -1.0)
    away = np.take_along_axis(turned, front, 0)[0]
    # a seam only where a billow's shadow side lies over the one behind it: a short curl, never a web
    seam = SEAM * (0.6 + 0.4 * size)
    seams = step(seam - (h1 - h2), 0.0, 1.5 * PX) * step(h2, 0.1 * R * size, 0.02) * step(away, 0.35, 0.3)
    return {"d": dist, "hole": hole, "first": first, "depth": 0.45 * R * size, "shade": shade, "seams": seams,
            "ink": 0.55 + 0.45 * size}


# --- the ring burst: a knot that opens into a ring and keeps spreading, thinning, then tears into arcs from the top ---

def ring(t, e, f, x, y, noise):
    g = grown(t, 0.85, 5)
    rho, th = np.hypot(x, y), np.arctan2(y, x)
    a = (th / (2 * math.pi) + 0.5) * WRAP
    w = 0.03 + 0.16 * (1 - t) ** 1.6                       # the tube's half width: a full knot at first, a thread at last
    rr = (0.06 + 0.68 * g) * (1 + 0.1 * (noise[7](a, 0.15 * f) - 0.5))  # uneven round, boiling a little
    ww = w * (1 + 0.6 * (noise[8](a, 3.3 + 0.1 * f) - 0.5))  # thicker and thinner round the ring
    across = (rho - rr) / ww
    d = np.abs(rho - rr) - ww
    hole = (0.7 * noise[9](2 * a + 0.4 * across, across * 0.9 + 5) + 0.3 * noise[4](x * 4, y * 4)) * 0.9 + 0.5
    first = np.clip(0.5 + 0.2 * np.sin(th) + 0.6 * (noise[6](x * 2.5, y * 2.5) - 0.5), 0, 1)  # all round, the top first
    return {"d": d, "hole": hole, "first": first, "depth": 1.3 * w, "bevel": ww, "ink": 0.6 + 0.4 * g}


# --- the crescent: an arc that sweeps out in four frames, thickest near its head, then thins from its tail -----------

A0, SPAN = math.radians(-50), math.radians(200)  # where the arc starts (lower right), and how far it sweeps (anticlockwise)


def crescent(t, e, f, x, y, noise):
    rho, th = np.hypot(x, y), np.arctan2(y, x)
    a = (th / (2 * math.pi) + 0.5) * WRAP
    head = SPAN * (1 - (1 - min(t / 0.3, 1.0)) ** 3)
    tail = SPAN * 0.35 * smooth((t - 0.3) / 0.7)
    phi = wrap(th - A0 - SPAN / 2) + SPAN / 2
    p = (phi - tail) / max(head - tail, 1e-4)  # 0 at its tail, 1 at its head
    profile = np.where(p < 0.72, np.clip(p / 0.72, 0, 1) ** 0.8, np.clip((1 - p) / 0.28, 0, 1) ** 0.6)
    big = 0.15 * (1 - 0.45 * smooth(t))
    w = big * profile * (1 + 0.25 * (noise[7](a, 0.15 * f) - 0.5))
    rc = 0.52 + 0.12 * (1 - (1 - t) ** 3) + 0.06 * e         # the outer edge, a clean circle, spreading
    mid = rc - w
    beyond = np.maximum(tail - phi, phi - head) * rho        # negative along the arc, so it never caps the inside
    d = np.maximum(np.abs(rho - mid) - w, beyond)
    across = (rho - mid) / np.maximum(w, 1e-3)
    hole = (0.7 * noise[9](a + 0.3 * across, across * 0.8 + 2) + 0.3 * noise[4](x * 4, y * 4)) * 0.9 + 0.5
    first = np.clip(0.85 * (1 - np.clip(p, 0, 1)) + 0.3 * (noise[6](x * 3, y * 3) - 0.5), 0, 1)
    return {"d": d, "hole": hole, "first": first, "depth": big, "bevel": np.maximum(w, 0.01), "ink": 0.8}


# --- the starburst: an impact's burst, a nine-pointed star at the middle that throws out nine hooked tongues, each
# widest near its root and drawn to a sharp point; they let go of the middle and fly on, and break into flecks along
# their length. Named for what it is (research's pass on the kit), so nobody builds a liquid on it: it was first drawn
# as a splash. Nothing liquid in it (the content check, 2026-11-14): no round tips, no thrown drops, no beads as it breaks,
# because a drop or spray shape reads as a stain once tinted (handbook/platform/rules-and-moderation.md, "Traps"). Its
# PASS holds while the hooks stay mixed in direction and uneven in length: made uniform and all turning one way, a ring
# of hooked arms needs a new check against the hate-symbol line

STARBURST = [(k * 2 * math.pi / 9 + j, length, width, hook)
          for k, (j, length, width, hook) in enumerate(zip(
              np.random.default_rng(41).uniform(-0.12, 0.12, 9), np.random.default_rng(42).uniform(0.52, 0.8, 9),
              np.random.default_rng(43).uniform(0.085, 0.115, 9), np.random.default_rng(44).uniform(-0.45, 0.45, 9)))]


def starburst(t, e, f, x, y, noise):
    rho, th = np.hypot(x, y), np.arctan2(y, x)
    a = (th / (2 * math.pi) + 0.5) * WRAP
    reach = 1 - (1 - min(t / 0.3, 1.0)) ** 3
    points = 1 - np.abs(wrap(9 * th)) / math.pi               # 1 toward each of the star's nine points, 0 between
    core = 0.24 * (1 - smooth(t / 0.4)) * (0.6 + 0.6 * points) - 0.02
    d = rho - core                                            # the burst's middle, a star, gone by frame 7
    for heading, length, width, hook in STARBURST:
        tip = length * (0.2 + 0.8 * reach) + 0.06 * e
        neck = tip * 0.7 * smooth((t - 0.25) / 0.6)         # the tongue lets go of the middle, from the inside out
        delta = wrap(th - heading - hook * np.clip(rho / length, 0, 1.3) ** 2)
        along, lat = rho * np.cos(delta), rho * np.abs(np.sin(delta))
        p = np.clip(along / tip, 0, 1)
        thick = width * (1 - 0.35 * t)
        w = thick * np.where(p < 0.3, 0.6 + 0.4 * p / 0.3, ((1 - p) / 0.7) ** 0.85)  # widest near the root, a point
        body = np.maximum(np.maximum(lat - w, along - tip), neck - along)
        d = smin(d, body, 0.04)
    hole = (0.65 * noise[9](a * 3, rho * 2.2) + 0.35 * noise[4](x * 6, y * 6)) * 0.9 + 0.5  # flecks along the tongues
    first = np.clip(1 - rho / 0.9 + 0.3 * (noise[6](x * 3, y * 3) - 0.5), 0, 1)
    return {"d": d, "hole": hole, "first": first, "depth": 0.11, "bevel": 0.06, "ink": 0.8}


# --- the spark: a flash at the centre for three frames, eight needles shot out that shorten from behind as they fly ---

SPARKS = [(k * math.pi / 4 + j, (0.86 if k % 2 == 0 else 0.56) * s)
          for k, (j, s) in enumerate(zip(np.random.default_rng(51).uniform(-0.12, 0.12, 8),
                                          np.random.default_rng(52).uniform(0.9, 1.1, 8)))]


def needle(rho, th, heading, tail, tip, width, widest):
    """A faceted needle from `tail` to `tip` along `heading`, widest at `widest` of its length, pointed at both ends."""
    delta = wrap(th - heading)
    along, lat = rho * np.cos(delta), rho * np.abs(np.sin(delta))
    p = (along - tail) / max(tip - tail, 1e-4)
    w = width * np.clip(np.where(p < widest, p / max(widest, 1e-4), (1 - p) / (1 - widest)), 0, None)
    return np.maximum(lat - w, np.maximum(tail - along, along - tip))


def spark(t, e, f, x, y, noise):
    rho, th = np.hypot(x, y), np.arctan2(y, x)
    fly = 1 - (1 - min(t / 0.25, 1.0)) ** 3
    width = 0.06 * (1 - 0.4 * t)
    d = rho - 0.2 * (1 - smooth(t / 0.17))                   # the flash: frames 1 to 3, never more
    for heading, length in SPARKS:
        tip = length * (0.25 + 0.75 * fly) + 0.08 * e
        tail = 0.06 + tip * 0.85 * smooth((t - 0.12) / 0.75)
        d = np.minimum(d, needle(rho, th, heading, tail, tip, width, 0.3))
    hole = 1.0 + 0.2 * (noise[4](x * 6, y * 6) - 0.5)     # it thins, it doesn't tear
    first = np.clip(1 - rho / 0.9, 0, 1)
    return {"d": d, "hole": hole, "first": first, "depth": width, "bevel": 0.9 * width, "ink": 0.55, "thin": True}


# --- the glint: a four-point star that pops in two frames, settles, twinkles, turns a little, then draws its arms in --

def glint(t, e, f, x, y, noise):
    rho, th = np.hypot(x, y), np.arctan2(y, x)
    pop = 1.15 * (1 - (1 - min(t / 0.12, 1.0)) ** 2) - 0.15 * smooth((t - 0.12) / 0.15)
    s = pop * (1 - smooth((t - 0.55) / 0.42))
    turn = math.radians(12 * t)
    twinkle = 0.08 * math.sin(2 * math.pi * 2.5 * t)
    d = rho - 0.07 * s
    for k in range(4):
        long_ = k % 2 == 1
        length = (0.72 * (1 + twinkle) if long_ else 0.54 * (1 - twinkle)) * s
        d = np.minimum(d, needle(rho, th, turn + k * math.pi / 2, -0.02, length, 0.075 * s, 0.02))
        d = np.minimum(d, needle(rho, th, turn + math.pi / 4 + k * math.pi / 2, -0.02, 0.28 * s, 0.045 * s, 0.02))
    return {"d": d, "hole": np.ones_like(x), "first": np.ones_like(x), "depth": 0.075, "bevel": 0.06, "ink": 0.45,
            "thin": True}


# --- the flame: a tongue that licks up in five frames with two smaller beside it, its top split into licks that climb
# through it, then tears from its top into rising wisps --

def flame(t, e, f, x, y, noise):
    grow = 1 - (1 - min(t / 0.3, 1.0)) ** 2
    height = 1.5 * (0.3 + 0.7 * grow) * (1 + 0.06 * math.sin(2 * math.pi * t * 3))
    rb = 0.26 * (0.6 + 0.4 * grow) * (1 - 0.3 * smooth((t - 0.5) / 0.5))
    base = -0.82
    yy = y - 0.25 * e                                         # the torn pieces rise
    up = np.clip((yy - base) / height, 0, 1)
    xx = (x + 0.3 * up ** 1.4 * (noise[0](x * 2.0, yy * 2.0 - f * 0.6) - 0.5)
          + 0.05 * (noise[1](x * 5, yy * 5 - f * 0.9) - 0.5))  # the flicker rises through it

    def tongue(cx, h, r):
        cy = base + r
        q = (yy - cy) / max(h - r, 1e-4)
        side = np.abs(xx - cx) - r * np.clip(1 - q, 0, 1) ** 1.5
        return np.where(yy < cy, np.hypot(xx - cx, yy - cy) - r, np.maximum(side, yy - (cy + h - r)))

    beat = 2 * math.pi * t * 2.2
    d = tongue(0.0, height, rb)
    d = smin(d, tongue(-0.85 * rb, height * (0.62 + 0.1 * math.sin(beat)), 0.6 * rb), 0.07)
    d = smin(d, tongue(0.9 * rb, height * (0.5 + 0.1 * math.sin(beat + 2)), 0.55 * rb), 0.07)
    # the licks: high up, the flame splits into tongues that climb a little every frame; the middle tongue keeps its
    # point until the break, so the crown is never cut flat
    lick = noise[2](x * 3.4, yy * 1.6 - f * 0.4)
    point = 0.35 * np.exp(-(xx / (0.5 * rb)) ** 2) * (1 - smooth(e / 0.4))
    d = np.maximum(d, as_distance(lick - (1.1 + point - 0.55 * up ** 1.5), 0.5))
    # its shade is heat, not light: a bright core low in the middle, the edge and the top darker
    shade = 1.2 * np.clip(-d / (0.55 * rb), 0, 1) - 0.1 - 0.45 * up
    # the tear's pattern rides with the flame as it rises (yy), so a texel once torn stays torn
    hole = (0.65 * noise[4](x * 5, yy * 1.6) + 0.35 * noise[6](x * 9, yy * 9)) * 0.9 + 0.5
    first = np.clip(0.85 * up + 0.3 * (noise[5](x * 3, yy * 3) - 0.5), 0, 1)
    return {"d": d, "hole": hole, "first": first, "depth": rb, "shade": shade, "ink": 0.8}


class Sheet:
    def __init__(self, shape, seed, life, schedule):
        self.shape, self.seed, self.life, self.schedule = shape, seed, life, schedule

    def progress(self, t):
        start, sweep, each = self.schedule
        return min(max((t - start) / (sweep + each), 0.0), 1.0)


SHEETS = {  # each: its shape, its noise's seed, a particle's life in seconds, and its break (start, sweep, each)
    "puff": Sheet(puff, 31, 0.6, (0.45, 0.2, 0.37)),
    "ring": Sheet(ring, 61, 0.5, (0.34, 0.25, 0.37)),
    "crescent": Sheet(crescent, 71, 0.4, (0.3, 0.3, 0.37)),
    "starburst": Sheet(starburst, 81, 0.55, (0.36, 0.25, 0.37)),
    "spark": Sheet(spark, 91, 0.3, (0.3, 0.3, 0.4)),
    "glint": Sheet(glint, 101, 0.35, (0.85, 0.0, 0.15)),
    "flame": Sheet(flame, 111, 0.7, (0.36, 0.25, 0.37)),
}


def draw(sheet):
    """Every frame's three passes at a frame's size: {pass: [16 frames]}, and how far the break has gone at each."""
    x, y = field()
    noise = [Noise(sheet.seed + k) for k in range(7)] + [Noise(sheet.seed + 7 + k, nx=WRAP) for k in range(3)]
    out, progress, border = {"line": [], "fill": [], "dark": []}, [], 0.0
    for f in range(FRAMES):
        t = (f + 0.5) / FRAMES
        e = sheet.progress(t)
        progress.append(e)
        for name, (value, cover, bleed) in zip(("line", "fill", "dark"),
                                               finish(sheet.shape(t, e, f, x, y, noise), t, e, x, y, noise,
                                                      sheet.schedule)):
            value = np.broadcast_to(np.float32(value), cover.shape) if np.ndim(value) == 0 else value
            frame = pack(value, cover, bleed)
            alpha = frame[..., 3]
            border = max(border, alpha[:2].max(), alpha[-2:].max(), alpha[:, :2].max(), alpha[:, -2:].max())
            out[name].append(frame)
    print(f"  16 frames; the most a frame's edge holds: {border:.3f}" + ("  (CUT: it leaves its frame)" if border > 0.01
                                                                          else ""))
    return out, progress


def sheet_page(frames):
    page = np.zeros((CELL * GRID, CELL * GRID, 4), dtype=np.float32)
    for f, frame in enumerate(frames):
        r, c = divmod(f, GRID)
        page[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = frame
    return page


# --- the previews ------------------------------------------------------------------------------------------------------

LOOKS = (("line", ("line",)), ("fill", ("fill",)), ("dark", ("dark",)), ("all three", ("dark", "fill", "line")))


def colour(name, e):
    """A pass's Color at a frame, as the row plays it: the fill goes toward the twin's cool tone as it breaks."""
    if name != "fill":
        return np.array(TINTS[name], dtype=np.float32)
    k = float(smooth(e))
    return np.array(TINTS["fill"], dtype=np.float32) * (1 - k) + np.array(TINTS["cool"], dtype=np.float32) * k


def scaled(passes, progress, px):
    """{pass: [frames]} at `px`, tinted as the preview plays them."""
    out = {}
    for name, frames in passes.items():
        out[name] = []
        for frame, e in zip(frames, progress):
            small = rs.shrink(frame, px / CELL)
            small[..., :3] *= colour(name, e)
            if name == "dark":
                small[..., 3] *= DARK_ALPHA
            out[name].append(small)
    return out


def frames_sheet(passes, progress, name, out):
    """Every frame at 128 px: a row a look (each pass alone, then all three), on the noon sky, then at night."""
    px, gap, left, top = 128, 6, 150, 40
    small = scaled(passes, progress, px)
    w = left + FRAMES * (px + gap)
    h = top + 2 * len(LOOKS) * (px + gap) + 30
    page = rs.canvas(w, h, rs.rgb("#16171C"))
    text = [(10, 10, 18, f"{name}: the 16 frames at 128 px, each pass alone and all three, on our noon sky and our night",
             "#E8E8E8")]
    for k, sky in enumerate((NOON, NIGHT)):
        for i, (label, layers) in enumerate(LOOKS):
            yy = top + (k * len(LOOKS) + i) * (px + gap)
            text.append((10, yy + px // 2 - 8, 14, f"{'noon' if k == 0 else 'night'}, {label}", "#BFC3CC"))
            for f in range(FRAMES):
                xx = left + f * (px + gap)
                rs.fill(page, xx, yy, px, px, sky)
                for layer in layers:
                    rs.paste(page, small[layer][f], xx, yy)
    for f in range(FRAMES):
        text.append((left + f * (px + gap) + 4, h - 24, 12, f"{f + 1}", "#8A8F99"))
    rs.paste(page, rs.text_layer(w, h, text), 0, 0)
    rs.save(page, out / f"{name}_frames.png")


def saved(name, out):
    """A sheet's passes as drawn, read back from its three textures, and how far its break has gone at each frame."""
    passes = {}
    for pass_name in ("line", "fill", "dark"):
        page = rs.load(out / f"fx_{name}_{pass_name}.png")
        passes[pass_name] = [page[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL].copy()
                             for r in range(GRID) for c in range(GRID)]
    return passes, [SHEETS[name].progress((f + 0.5) / FRAMES) for f in range(FRAMES)]


def write(pixels, path):
    """rs.save without keeping the image: the movie writes hundreds of pages, and each image kept holds its buffers."""
    h, w = pixels.shape[:2]
    image = bpy.data.images.new("Page", w, h, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(pixels[::-1]).ravel())
    image.filepath_raw, image.file_format = str(path), "PNG"
    image.save()
    bpy.data.images.remove(image)


KIT_SIZES = (96, 128, 64)  # the kit's strip, then the movie's two sizes


def kit_looks(out):
    """Every sheet at the kit's sizes, tinted, read back one sheet at a time so the full-size frames never pile up."""
    looks = {}
    for name in SHEETS:
        passes, progress = saved(name, out)
        looks[name] = {px: scaled(passes, progress, px) for px in KIT_SIZES}
        del passes
    return looks


def kit_frames(looks, out):
    """The whole kit on one page: a sheet's 16 frames at 96 px in a row, all three passes, on noon, then at night."""
    px, gap, left, top = 96, 4, 120, 36
    rows = [(name, sky) for name in looks for sky in (NOON, NIGHT)]
    w, h = left + FRAMES * (px + gap), top + len(rows) * (px + gap) + 24
    page = rs.canvas(w, h, rs.rgb("#16171C"))
    text = [(10, 8, 16, "the kit: every sheet's 16 frames, all three passes, on our noon and our night", "#E8E8E8")]
    for i, (name, sky) in enumerate(rows):
        yy = top + i * (px + gap)
        if sky is NOON:
            text.append((10, yy + px - 8, 13, name, "#E8E8E8"))
        for f in range(FRAMES):
            xx = left + f * (px + gap)
            rs.fill(page, xx, yy, px, px, sky)
            for layer in ("dark", "fill", "line"):
                rs.paste(page, looks[name][px][layer][f], xx, yy)
    for f in range(FRAMES):
        text.append((left + f * (px + gap) + 4, h - 20, 11, f"{f + 1}", "#8A8F99"))
    rs.paste(page, rs.text_layer(w, h, text), 0, 0)
    rs.save(page, out / "fx_kit_frames.png")


def kit_movie(looks, out):
    """Every sheet in a column, looping at its own life with GAP between: all three at 128 px on noon, the line alone
    on noon, all three at night, then all three at 64 px on noon and at night."""
    names = list(looks)
    both = ("dark", "fill", "line")
    rows = (("noon", NOON, both, 128), ("noon, line", NOON, ("line",), 128), ("night", NIGHT, both, 128),
            ("noon, 64 px", NOON, both, 64), ("night, 64 px", NIGHT, both, 64))
    gap, left, top = 10, 110, 58
    w = left + len(names) * (128 + gap) + 10
    h = top + sum(px + gap for *_, px in rows) + 10
    w, h = w + w % 2, h + h % 2
    base = rs.canvas(w, h, rs.rgb("#16171C"))
    text = [(10, 8, 16, "the kit, each sheet looping at its own life: all three passes, and the line alone", "#E8E8E8")]
    places = []
    yy = top
    for label, sky, layers, px in rows:
        text.append((10, yy + px // 2 - 8, 12, label, "#BFC3CC"))
        for i, name in enumerate(names):
            xx = left + i * (128 + gap) + (128 - px) // 2
            rs.fill(base, xx, yy, px, px, sky)
            places.append((name, px, layers, xx, yy))
        yy += px + gap
    for i, name in enumerate(names):
        text.append((left + i * (128 + gap) + 4, top - 22, 13, f"{name}, {SHEETS[name].life} s", "#E8E8E8"))
    rs.paste(base, rs.text_layer(w, h, text), 0, 0)
    folder = out / "_kit_movie"
    folder.mkdir(exist_ok=True)
    span = 4 * (max(SHEETS[n].life for n in names) + GAP)
    for n in range(round(span * FPS)):
        page = base.copy()
        for name, px, layers, xx, yy in places:
            life = SHEETS[name].life
            phase = (n / FPS) % (life + GAP)
            if phase < life:
                f = min(FRAMES - 1, int(phase / life * FRAMES))
                for layer in layers:
                    rs.paste(page, looks[name][px][layer][f], xx, yy)
        write(page, folder / f"{n:04d}.png")
        if n == round(0.15 * FPS):
            write(page, out / "fx_kit_preview_poster.png")  # one page of it, to read the layout without playing
    frames_to_movie.assemble(folder, out / "fx_kit_preview.mp4", FPS)
    shutil.rmtree(folder)


def spec(out):
    """fx_sheets.json, for the builder's rows: each sheet's files, life, break, and the fill's ColorSequence."""
    data = {"flipbook": "Grid4x4, OneShot", "tints": HEX, "dark_transparency": round(1 - DARK_ALPHA, 2), "sheets": {}}
    for name in SHEETS:
        sheet = SHEETS[name]
        start, sweep, each = sheet.schedule
        end = min(1.0, start + sweep + each)
        data["sheets"][name] = {
            "files": [f"fx_{name}_{p}.png" for p in ("line", "fill", "dark")],
            "life": sheet.life,
            "break": [start, round(end, 3)],
            "fill_color": [[0.0, HEX["fill"]], [start, HEX["fill"]], [round(end, 3), HEX["cool"]]],
        }
    (out / "fx_sheets.json").write_text(json.dumps(data, indent=2) + "\n", newline="\n")


def main():
    out = bl.out_dir()
    rs.OUT = out
    args = sys.argv[sys.argv.index("--") + 2:]
    names = [a for a in args if a in SHEETS] or list(SHEETS)
    if "movie" in args:  # from the sheets already drawn, so a run never holds all seven while it draws
        looks = kit_looks(out)
        kit_frames(looks, out)
        kit_movie(looks, out)
        return
    for name in names:
        print(f"{name}:")
        passes, progress = draw(SHEETS[name])
        for pass_name, frames in passes.items():
            rs.save(sheet_page(frames), out / f"fx_{name}_{pass_name}.png")
        frames_sheet(passes, progress, name, out)
    spec(out)


if __name__ == "__main__":
    main()
