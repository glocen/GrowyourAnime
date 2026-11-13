"""The effects kit's drawn sheets (AR9, docs/asset-requests.md): flipbooks of our own, each in two passes and a dark twin,
for particles, beside fx_kit.py's meshes and 2x2 textures.

blender.exe -b --factory-startup --python tools/blender/fx_sheets.py -- <out_dir> [puff] [still]

(still: the sheets and the frames, without the movie.)

Each sheet is 1024 px, a 4 x 4 grid of 256 px frames, read left to right and top to bottom (FlipbookLayout Grid4x4,
OneShot: one pass through the grid over a particle's life). Three textures a sheet, all white with alpha, tinted in the
game by the emitter's Color, so one drawing serves every palette:
- fx_<name>_line: the outline pass, the drawing's ink. Alone, it's a quiet hit; with the fill, a signature.
- fx_<name>_fill: the fill pass, in flat toon steps (shadow, body, highlight): a bright core, darker where it turns
  away from the light (up and to the left). Its value sinks over the last half of its life, so it fades toward
  black, never only to clear (docs/research/vfx-reference.md, "What the vault teaches, beside ours").
- fx_<name>_dark: the dark twin, played under the other two at LightEmission 0 in a near-black colour: the silhouette
  grown and nudged down and to the right, lagging the bright passes as they break up, so the shape holds on a pale sky.
Drawn at SS times the size and boxed down. The clear texels carry each pass's own value, so no rim comes in where the
engine filters an edge.

Also writes <name>_frames.png (every frame at 128 px, each pass alone and all three, on our noon sky and our night) and
<name>_preview.mp4 (the puff looping at a particle's life, at 128 and 64 px, on both skies). Workbench is never used:
no GPU turn.

The puff: a knot that bursts into a cloud of round billows, half its growth in its first tenth (ease out), rises a
little and curls, then breaks into wisps from its middle out, the wisps going dark as they go.
"""
import math
import shutil
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import frames_to_movie  # noqa: E402
import rook_sheet as rs  # noqa: E402

CELL, GRID, SS = 256, 4, 3      # a frame's px, frames across and down, supersampling
FRAMES = GRID * GRID
NOON, NIGHT = rs.rgb("#5FADDA"), rs.rgb("#0E1018")  # the base's noon sky and Lantern Row's night (levelup_column_art)
TINTS = {"line": rs.rgb("#FFF6E6"), "fill": rs.rgb("#E9E2D6"), "dark": rs.rgb("#1C1726")}  # the preview's Colors
DARK_ALPHA = 0.85               # the twin's opacity in the preview: a row's Transparency 0.15
LIFE, GAP, FPS = 0.6, 0.25, 60  # the preview: a particle's life and the pause between, in seconds

# --- the drawing's tools ---------------------------------------------------------------------------------------------


def smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


def step(x, edge, width):
    """0 below `edge`, 1 above, through `width` (a drawn edge, antialiased by the supersampling)."""
    return smooth((x - edge) / width + 0.5)


class Noise:
    """Smooth value noise on a wrapped lattice, 0 to 1."""

    def __init__(self, seed, n=64):
        self.t, self.n = np.random.default_rng(seed).random((n, n)).astype(np.float32), n

    def __call__(self, x, y):
        xi, yi = np.floor(x), np.floor(y)
        fx, fy = smooth(x - xi), smooth(y - yi)
        xi, yi = xi.astype(np.int64) % self.n, yi.astype(np.int64) % self.n
        x1, y1, t = (xi + 1) % self.n, (yi + 1) % self.n, self.t
        a = t[yi, xi] + (t[yi, x1] - t[yi, xi]) * fx
        b = t[y1, xi] + (t[y1, x1] - t[y1, xi]) * fx
        return a + (b - a) * fy


def smin(a, b, k):
    """A smooth union of two distances: lobes melt into each other over `k`."""
    h = np.maximum(k - np.abs(a - b), 0.0) / k
    return np.minimum(a, b) - h * h * k * 0.25


def field(n=CELL * SS):
    """x, y across a frame, -1 to 1, y up, at texel centres; row 0 is the top."""
    c = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(c, -c)
    return x, y


def pack(value, cover, bleed):
    """A pass's texels at SS times the size, boxed down to a frame: white-valued with alpha; the clear texels take
    `bleed`, the pass's own value."""
    rgba = np.empty(value.shape + (4,), dtype=np.float32)
    rgba[..., :3] = np.clip(value, 0, 1)[..., None]
    rgba[..., 3] = np.clip(cover, 0, 1)
    out = rs.shrink(rgba, 1 / SS)
    clear = out[..., 3] < 1e-3
    out[clear, :3] = bleed
    return out


# --- the puff ----------------------------------------------------------------------------------------------------------

R = 0.74                      # the cloud's reach, in a frame's half width
LOBES = (                     # each billow: its heading in degrees, how far out (of R), its radius (of R), how far it drifts
    (0, 0.0, 0.42, 0.0), (90, 0.5, 0.36, 1.1), (35, 0.55, 0.33, 0.9), (-15, 0.6, 0.3, 1.2),
    (-70, 0.5, 0.32, 0.8), (-120, 0.52, 0.3, 1.0), (-170, 0.58, 0.31, 1.15), (140, 0.55, 0.34, 0.95),
)
LIGHT = np.array((-0.45, 0.6, 0.66)) / np.linalg.norm((-0.45, 0.6, 0.66))  # from up and to the left, toward the viewer
KNOT, EASE = 0.18, 5          # the size it starts at (of its full size), and its ease out: 1 - (1 - t)^EASE
RISE, CURL = 0.1, 8.0         # how far it rises over its life (half widths), and how far it turns (degrees)
CURLS = 6                     # the break-up's wisps: noise cells once round the cloud
BREAK = (0.48, 0.97)          # when it breaks up: from, to (of its life)
EAT, PACE = 0.5, 1.8          # how deep the break-up has eaten by its end, and its pace: holes by frame 10, wisps by 12,
                              # specks by 14, gone at 16
FLAT = 0.85                   # how far a breaking wisp's shading flattens to one tone, so pieces never read as pebbles
LAG = 0.02                    # how far the dark twin's break-up runs behind the bright passes (of its life)
GROW, NUDGE, SOFT = 0.045, (0.015, -0.02), 0.025  # the twin: grown by, nudged by, its edge's softness
INK, SEAM = 0.034, 0.012      # the outline's width and a seam's, in half widths
STEPS = ((0.15, 0.46, 0.7), (0.62, 0.7, 0.95))  # the fill's toon steps: (shade where it changes, from, to)
SINK = 0.35                   # how far the fill's value sinks by its last frame


def puff_frame(f, x, y, noise):
    """The three passes of frame `f` at SS times the size: (line, fill, dark), each (value, cover, bleed)."""
    t = (f + 0.5) / FRAMES
    size = KNOT + (1 - KNOT) * (1 - (1 - t) ** EASE)
    rise = RISE * smooth(t)

    def ramp(at):
        return min(max((at - BREAK[0]) / (BREAK[1] - BREAK[0]), 0.0), 1.0)

    e = smooth(ramp(t))
    eat, eat_dark = EAT * ramp(t) ** PACE, EAT * ramp(t - LAG) ** PACE
    # the wobble is the cloud's own, so it grows with it; a little of it changes every frame, like a drawing
    u, v = x / size, (y - rise) / size
    wx = (noise[0](u * 2.6, v * 2.6) - 0.5) + 0.25 * (noise[1](u * 7 + f * 3.1, v * 7) - 0.5)
    wy = (noise[2](u * 2.6, v * 2.6) - 0.5) + 0.25 * (noise[3](u * 7, v * 7 + f * 2.7) - 0.5)
    px, py = x + 0.07 * size * wx, y + 0.07 * size * wy

    centres, radii, dist = [], [], None
    for heading, out, radius, drift in LOBES:
        a = math.radians(heading + CURL * t)
        reach = R * size * out * (1 + 0.25 * drift * t + 0.2 * drift * e)  # the wisps drift apart as it breaks
        cx, cy = reach * math.cos(a), reach * math.sin(a) + rise + (0.04 * t if out and math.sin(a) > 0 else 0.0)
        r = R * size * radius * (1 + 0.15 * t)
        centres.append((cx, cy))
        radii.append(r)
        d = np.hypot(px - cx, py - cy) - r
        dist = d if dist is None else smin(dist, d, 0.1 * R * size)

    # the break-up: holes open where the noise is high, the middle first, with ragged edges, and drawn out along the
    # cloud's curl, so what's left is wisps, never round balls; the twin's runs a little late
    off_x, off_y = px - centres[0][0], py - centres[0][1]
    round_ = (np.arctan2(off_y, off_x) / (2 * math.pi) + 0.5) * CURLS - CURL * t / 360 * CURLS
    along = noise[7](round_, np.hypot(off_x, off_y) / (R * size) * 9.0)
    hole = (0.35 * noise[4](u * 2.4, v * 2.4) + 0.15 * noise[6](u * 6.5, v * 6.5) + 0.5 * along) * 0.9 + 0.5
    middle = np.clip(1 - np.hypot(off_x, off_y) / (0.6 * R * size), 0, 1)

    def eaten(amount):
        return dist + amount * R * size * (hole + 0.2 * middle)

    d, d_dark = eaten(eat), eaten(eat_dark)
    px_size = 2.0 / (CELL * SS)  # one supersampled texel, in half widths
    inside = step(-d, 0.0, 1.5 * px_size)

    # each billow as a ball: the front-most one at a texel gives its shade; where two meet is a seam
    heights, shades, turned = [], [], []
    for (cx, cy), r in zip(centres, radii):
        qx, qy = (px - cx) / r, (py - cy) / r
        z = np.sqrt(np.clip(1 - qx * qx - qy * qy, 0, 1))
        heights.append(np.where(z > 0, r * z, -1.0))
        shades.append(qx * LIGHT[0] + qy * LIGHT[1] + z * LIGHT[2])
        turned.append(qx * 0.6 - qy * 0.8)  # how far round to its shadow side (down and right) a texel is on a billow
    heights, shades, turned = np.stack(heights), np.stack(shades), np.stack(turned)
    order = np.argsort(heights, axis=0)
    front = order[-1:]
    h1 = np.take_along_axis(heights, front, 0)[0]
    h2 = np.take_along_axis(heights, order[-2:-1], 0)[0]
    shade = np.where(h1 > 0, np.take_along_axis(shades, front, 0)[0], -1.0)
    away = np.take_along_axis(turned, front, 0)[0]
    # the highlights shrink as it breaks up
    shade = shade - 0.5 * e

    sink = 1 - SINK * e
    value = np.full_like(x, STEPS[0][1])
    for edge, lo, hi in STEPS:
        value = value + (hi - lo) * step(shade, edge, 0.04)
    flat = FLAT * smooth((e - 0.15) / 0.45)
    value = value * (1 - flat) + STEPS[0][2] * flat
    fill = (value * sink, inside, STEPS[0][2] * sink)

    # the ink: the silhouette's line, heavier on the shadow side (down and right), thinning and breaking as it goes;
    # a seam only where a billow's shadow side lies over the one behind it, a short curl, never a web; gone once it
    # starts to break
    heavy = np.clip(((px - centres[0][0]) * 0.6 - (py - centres[0][1]) * 0.8) / (R * size), -1, 1)
    width = INK * (0.75 + 0.3 * heavy) * (1 - 0.45 * e) * (0.55 + 0.45 * size)
    dash = step(noise[5](u * 9, v * 9), 0.85 * e, 0.06) if e > 0 else 1.0
    line = step(width / 2 - np.abs(d + width * 0.35), 0.0, 1.5 * px_size) * dash
    seam = SEAM * (0.6 + 0.4 * size)
    seams = (step(seam - (h1 - h2), 0.0, 1.5 * px_size) * step(h2, 0.1 * R * size, 0.02)
             * step(away, 0.35, 0.3) * (1 - smooth(e / 0.3)) * step(-d, width, 1.5 * px_size))
    ink = np.maximum(line, seams) * (1 - 0.5 * e)
    line_pass = (np.ones_like(x), ink, 1.0)

    # the twin: grown, nudged, soft, late to break, and gone by its last frames
    dx, dy = int(round(NUDGE[0] / px_size)), int(round(-NUDGE[1] / px_size))
    grow = GROW * (0.6 + 0.4 * size) * (1 - 0.8 * e)  # a thin margin round the wisps, never a dark ball round each
    dark = np.roll(np.roll(step(-(d_dark - grow), 0.0, SOFT), dy, axis=0), dx, axis=1)
    dark = dark * (1 - smooth((t - 0.6) / 0.3))
    return line_pass, fill, (np.ones_like(x), dark, 1.0)


def draw(frame_fn, seed):
    """Every frame's three passes at a frame's size: {pass: [16 frames]}."""
    x, y = field()
    noise = [Noise(seed + k) for k in range(7)] + [Noise(seed + 7, CURLS)]  # the last wraps once round the cloud
    out = {"line": [], "fill": [], "dark": []}
    for f in range(FRAMES):
        for name, (value, cover, bleed) in zip(("line", "fill", "dark"), frame_fn(f, x, y, noise)):
            value = np.broadcast_to(value, x.shape) if np.ndim(value) == 0 else value
            out[name].append(pack(value, cover, bleed))
        print(f"  frame {f + 1} of {FRAMES}")
    return out


def sheet(frames):
    page = np.zeros((CELL * GRID, CELL * GRID, 4), dtype=np.float32)
    for f, frame in enumerate(frames):
        r, c = divmod(f, GRID)
        page[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = frame
    return page


# --- the previews ------------------------------------------------------------------------------------------------------

LOOKS = (("line", ("line",)), ("fill", ("fill",)), ("dark", ("dark",)), ("all three", ("dark", "fill", "line")))


def tinted(frame, name, px):
    out = rs.shrink(frame, px / CELL)
    out[..., :3] *= np.array(TINTS[name], dtype=np.float32)
    if name == "dark":
        out[..., 3] *= DARK_ALPHA
    return out


def scaled(passes, px):
    """{pass: [frames]} at `px`, tinted as the preview plays them."""
    return {name: [tinted(fr, name, px) for fr in frames] for name, frames in passes.items()}


def frames_sheet(passes, name, out):
    """Every frame at 128 px: a row a look (each pass alone, then all three), on the noon sky, then at night."""
    px, gap, left, top = 128, 6, 150, 40
    small = scaled(passes, px)
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


def movie(passes, name, out):
    """The puff looping at a particle's life (LIFE, then GAP clear), four times: at 128 and 64 px, each look in a
    column, the noon sky over the night."""
    sizes, gap, top = (128, 64), 10, 34
    scaled_looks = {px: scaled(passes, px) for px in sizes}
    cols = len(LOOKS)
    w = 20 + sum(cols * (px + gap) + 20 for px in sizes)
    h = top + 2 * (128 + gap) + 26
    w, h = w + w % 2, h + h % 2
    base = rs.canvas(w, h, rs.rgb("#16171C"))
    text = [(10, 8, 16, f"{name}, looping at {LIFE} s a life: each pass alone, then all three; 128 px, then 64 px",
             "#E8E8E8")]
    x0 = 20
    places = []
    for px in sizes:
        for i, (label, layers) in enumerate(LOOKS):
            xx = x0 + i * (px + gap)
            text.append((xx, h - 22, 12, label, "#BFC3CC"))
            for k, sky in enumerate((NOON, NIGHT)):
                yy = top + k * (128 + gap) + (128 - px) // 2
                rs.fill(base, xx, yy, px, px, sky)
                places.append((px, layers, xx, yy))
        x0 += cols * (px + gap) + 20
    rs.paste(base, rs.text_layer(w, h, text), 0, 0)
    folder = out / f"_{name}_movie"
    folder.mkdir(exist_ok=True)
    life, every = round(LIFE * FPS), round((LIFE + GAP) * FPS)
    n = 0
    for _ in range(4):
        for k in range(every):
            page = base.copy()
            if k < life:
                f = min(FRAMES - 1, int(k / life * FRAMES))
                for px, layers, xx, yy in places:
                    for layer in layers:
                        rs.paste(page, scaled_looks[px][layer][f], xx, yy)
            rs.save(page, folder / f"{n:04d}.png")
            if n == life * 2 // 3:
                rs.save(page, out / f"{name}_preview_poster.png")  # one page of it, to read the layout without playing
            n += 1
    frames_to_movie.assemble(folder, out / f"{name}_preview.mp4", FPS)
    shutil.rmtree(folder)


SHEETS = {"puff": (puff_frame, 31)}


def main():
    out = bl.out_dir()
    rs.OUT = out
    args = sys.argv[sys.argv.index("--") + 2:]
    for name in [a for a in args if a in SHEETS] or list(SHEETS):
        frame_fn, seed = SHEETS[name]
        print(f"{name}:")
        passes = draw(frame_fn, seed)
        for pass_name, frames in passes.items():
            rs.save(sheet(frames), out / f"fx_{name}_{pass_name}.png")
        frames_sheet(passes, name, out)
        if "still" not in args:
            movie(passes, name, out)


if __name__ == "__main__":
    main()
