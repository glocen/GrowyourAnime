"""Paint-over targets for an effect: light drawn over a game capture, for the target before the hours (AGENTS.md, "Every
action, world, effect and screen": an effect's peak frame and a strip of its life). Scintilla's.

A target is light laid on a frame of the game, placed in the world by the capture's own camera, so a shape sized in studs
lands where the engine would draw it and every tile of a strip agrees. Nothing is installed: numpy, and ffmpeg to read and
write the pictures.

    from paintover import Frame
    f = Frame("capture.png", camera)       # camera: {"CFrame": [12 numbers], "Fov": deg, "Viewport": [w, h]}
    f.glow(p, 1.5, MINT, 2.0)               # p a world point in studs; sizes in studs
    f.save("out.png")

How the light is drawn:
- Light adds in linear light, as an emitter at LightEmission 1 does, then a soft knee takes it to 1: a bright enough colour
  goes white where all three channels pass the knee, so a white-hot core comes from intensity, not from painting white.
- A bloom spreads what passes 1, at two radii, so the brightest parts halo the way the game's Bloom does.
- A dome's fill is laid over (alpha), its rim added: a lit shell, not a solid ball.
"""
from __future__ import annotations

import json
import math
import subprocess
from pathlib import Path

import numpy as np

KNEE = 0.72  # where the soft clip starts, in linear light
BLOOM = ((0.006, 0.55), (0.03, 0.35))  # (sigma as a share of the frame's height, strength) for what passes 1


def srgb_to_linear(c):
    c = np.asarray(c, dtype=np.float32)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


def hexc(h: str):
    """A hex colour as linear RGB."""
    h = h.lstrip("#")
    return srgb_to_linear([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])


def read_png(path, size=None, vf=None) -> np.ndarray:
    """An image as sRGB floats in 0..1, HxWx3. With size=(w, h) and an ffmpeg filter `vf` ending at that size, read
    through the filter (a phone-size or squinted copy)."""
    if size is None:
        probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                                "-of", "json", str(path)], capture_output=True, check=True)
        s = json.loads(probe.stdout)["streams"][0]
        size = (s["width"], s["height"])
    w, h = size
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), *(["-vf", vf] if vf else []), "-f", "rawvideo",
                          "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(h, w, 3).astype(np.float32) / 255


def write_png(img: np.ndarray, path) -> None:
    h, w, _ = img.shape
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w}x{h}", "-i", "-",
                    str(path)], input=data, check=True)


def blur(a: np.ndarray, sigma: float) -> np.ndarray:
    """A Gaussian, near enough: three box passes each way."""
    if sigma < 0.5:
        return a
    r = max(1, int(round(math.sqrt(12 * sigma * sigma / 3 + 1) / 2)))
    out = a
    for axis in (0, 1):
        for _ in range(3):
            pad = [(0, 0)] * out.ndim
            pad[axis] = (r + 1, r)
            c = np.cumsum(np.pad(out, pad, mode="edge"), axis=axis, dtype=np.float32)
            hi = np.take(c, np.arange(2 * r + 1, c.shape[axis]), axis=axis)
            lo = np.take(c, np.arange(0, c.shape[axis] - 2 * r - 1), axis=axis)
            out = (hi - lo) / (2 * r + 1)
    return out


class Camera:
    """The capture's camera: a world point to the picture's pixels and its depth."""

    def __init__(self, cam: dict, size):
        m = cam["CFrame"]
        self.pos = np.array(m[0:3], np.float64)
        self.rot = np.array(m[3:12], np.float64).reshape(3, 3)  # rows of Roblox's components: R00 R01 R02 / R10 ...
        vw, vh = cam["Viewport"]
        w, h = size
        self.scale = w / vw
        self.cx, self.cy = w / 2, h / 2
        self.focal = (vh / 2) / math.tan(math.radians(cam["Fov"]) / 2) * self.scale

    def project(self, p):
        local = self.rot.T @ (np.asarray(p, np.float64) - self.pos)
        z = -local[2]
        return np.array([self.cx + self.focal * local[0] / z, self.cy - self.focal * local[1] / z]), z

    def px(self, p, studs: float) -> float:
        """How many pixels a length in studs spans at p, facing the camera."""
        return self.focal * studs / self.project(p)[1]


class Frame:
    def __init__(self, picture, cam: dict, base: np.ndarray | None = None):
        img = read_png(picture) if base is None else base
        self.base = srgb_to_linear(img)
        self.h, self.w, _ = self.base.shape
        self.cam = Camera(cam, (self.w, self.h))
        self.light = np.zeros_like(self.base)
        self.over = np.zeros_like(self.base)  # premultiplied colour laid over the frame
        self.alpha = np.zeros(self.base.shape[:2], np.float32)
        yy, xx = np.mgrid[0:self.h, 0:self.w].astype(np.float32)
        self.xx, self.yy = xx, yy

    # --- where -------------------------------------------------------------------------------------------------------
    def at(self, p):
        return self.cam.project(p)[0]

    def box(self, c, r):
        """A slice round a screen point, r pixels each way, clipped to the frame."""
        x0, x1 = max(0, int(c[0] - r)), min(self.w, int(c[0] + r) + 1)
        y0, y1 = max(0, int(c[1] - r)), min(self.h, int(c[1] + r) + 1)
        return slice(y0, max(y0, y1)), slice(x0, max(x0, x1))

    def add(self, sl, field, colour, k):
        if field.size:
            self.light[sl] += field[..., None] * (np.asarray(colour, np.float32) * k)

    # --- shapes, sized in studs ---------------------------------------------------------------------------------------
    def glow(self, p, radius, colour, k=1.0, falloff=2.0):
        """A soft round light facing the camera: exp(-(d/r)^falloff)."""
        c = self.at(p)
        r = self.cam.px(p, radius)
        sl = self.box(c, r * 3.2)
        d = np.hypot(self.xx[sl] - c[0], self.yy[sl] - c[1]) / max(r, 0.5)
        self.add(sl, np.exp(-d ** falloff), colour, k)

    def core(self, p, radius, colour, k=3.0):
        """A white-hot core: a tight bright disk inside its own glow. Its colour blows to white by intensity."""
        self.glow(p, radius, colour, k, falloff=4.0)
        self.glow(p, radius * 2.4, colour, k * 0.35, falloff=1.6)

    def streak(self, a, b, width_a, width_b, colour, k=1.0, soft=0.6, screen=False):
        """A tapered line of light from a to b (world points, or pixels with screen=True), widths in studs (or pixels)."""
        pa, pb = (np.asarray(a, float), np.asarray(b, float)) if screen else (self.at(a), self.at(b))
        wa, wb = (width_a, width_b) if screen else (self.cam.px(a, width_a), self.cam.px(b, width_b))
        r = max(wa, wb) * 3 + 2
        x0, x1 = min(pa[0], pb[0]) - r, max(pa[0], pb[0]) + r
        y0, y1 = min(pa[1], pb[1]) - r, max(pa[1], pb[1]) + r
        sl = (slice(max(0, int(y0)), max(0, min(self.h, int(y1) + 1))), slice(max(0, int(x0)), max(0, min(self.w, int(x1) + 1))))
        X, Y = self.xx[sl], self.yy[sl]
        d = pb - pa
        L2 = max(float(d @ d), 1e-6)
        t = np.clip(((X - pa[0]) * d[0] + (Y - pa[1]) * d[1]) / L2, 0, 1)
        dist = np.hypot(X - (pa[0] + t * d[0]), Y - (pa[1] + t * d[1]))
        wid = (wa + (wb - wa) * t) / 2
        f = np.clip(1 - (dist - wid * (1 - soft)) / np.maximum(wid * soft * 2, 0.6), 0, 1) ** 2
        self.add(sl, f, colour, k)

    def spikes(self, p, n, length, width, colour, k=1.6, seed=1, up=0.0, spread=(0.45, 1.0), inner=0.15, flat=1.0):
        """Radial needles thrown out of p: n of them, lengths a share of `length` (studs), thick at the root, a point at
        the tip. up > 0 leans them upward; flat < 1 squashes them toward the ground's ellipse."""
        rng = np.random.default_rng(seed)
        c = self.at(p)
        L = self.cam.px(p, length)
        W = self.cam.px(p, width)
        for i in range(n):
            ang = (i + rng.uniform(-0.35, 0.35)) / n * 2 * math.pi
            v = np.array([math.cos(ang), math.sin(ang) * flat])
            v[1] -= up
            v /= max(np.linalg.norm(v), 1e-6)
            share = rng.uniform(*spread)
            a = c + v * L * inner
            b = c + v * L * share
            self.streak(a, b, W * rng.uniform(0.7, 1.2), 0.3, colour, k * rng.uniform(0.7, 1.15), screen=True)

    def ring(self, p, radius, width, colour, k=1.0, normal=(0, 1, 0), steps=96):
        """A ring of light in the world, round p in the plane of `normal`, as streaks along its circle."""
        n = np.asarray(normal, float)
        n /= np.linalg.norm(n)
        u = np.cross(n, [0, 0, 1] if abs(n[2]) < 0.9 else [1, 0, 0])
        u /= np.linalg.norm(u)
        v = np.cross(n, u)
        pts = [np.asarray(p, float) + radius * (math.cos(a) * u + math.sin(a) * v) for a in np.linspace(0, 2 * math.pi, steps + 1)]
        for a, b in zip(pts, pts[1:]):
            self.streak(a, b, width, width, colour, k, soft=0.8)

    def dome(self, p, radius, colour, fill=0.12, rim=1.2, rim_width=0.18, squash=1.0):
        """A lit shell round p: a thin fill laid over, and a rim of light where the shell turns away (its fresnel).
        squash < 1 flattens it into a dome sitting on its base."""
        c = self.at(p)
        r = self.cam.px(p, radius)
        sl = self.box(c, r * 1.3)
        dx = (self.xx[sl] - c[0]) / max(r, 0.5)
        dy = (self.yy[sl] - c[1]) / max(r * squash, 0.5)
        d = np.hypot(dx, dy)
        inside = np.clip((1 - d) / 0.02, 0, 1)
        nz = np.sqrt(np.clip(1 - d * d, 0, 1))  # the shell's facing: 1 at the middle, 0 at the edge
        fres = np.clip(1 - nz, 0, 1) ** (1 / max(rim_width, 0.02) * 0.25)
        col = np.asarray(colour, np.float32)
        a = fill * inside * (0.55 + 0.45 * fres)
        self.over[sl] += (a[..., None] * col) * (1 - self.alpha[sl][..., None])
        self.alpha[sl] += a * (1 - self.alpha[sl])
        self.add(sl, fres * inside, colour, rim)

    def motes(self, points, size, colour, k=1.5):
        for q in points:
            self.glow(q, size, colour, k, falloff=2.5)

    def arc(self, a, b, height, width_a, width_b, colour, k=1.0, steps=24, until=1.0):
        """A curve of light from a to b, lifted `height` studs at its middle; drawn to `until` of its length."""
        a, b = np.asarray(a, float), np.asarray(b, float)
        mid = (a + b) / 2 + np.array([0, height, 0])
        pts = []
        for i in range(steps + 1):
            t = i / steps * until
            pts.append((1 - t) ** 2 * a + 2 * (1 - t) * t * mid + t * t * b)
        for i, (p0, p1) in enumerate(zip(pts, pts[1:])):
            t0, t1 = i / steps, (i + 1) / steps
            self.streak(p0, p1, width_a + (width_b - width_a) * t0, width_a + (width_b - width_a) * t1, colour, k, soft=0.75)
        return pts[-1]

    # --- out ----------------------------------------------------------------------------------------------------------
    def render(self) -> np.ndarray:
        lin = self.base * (1 - self.alpha[..., None]) + self.over + self.light
        hot = np.clip(self.light - 0.6, 0, None)
        for sigma, k in BLOOM:
            lin = lin + blur(hot, sigma * self.h) * k
        over = np.clip(lin - KNEE, 0, None)
        lin = np.where(lin > KNEE, KNEE + (1 - KNEE) * (1 - np.exp(-over / (1 - KNEE))), lin)
        # where one channel is pinned, the rest follow toward white: a hot core, as the engine's clip shows it
        peak = lin.max(axis=2, keepdims=True)
        spill = np.clip((peak - 0.97) / 0.03, 0, 1) * np.clip(self.light.max(axis=2, keepdims=True) - 1.2, 0, 1)
        lin = lin + (1 - lin) * spill * 0.85
        return linear_to_srgb(lin)

    def save(self, path) -> None:
        write_png(self.render(), path)


def strip(tiles, out, cols=None, gap=6, grey=0.18):
    """Tiles (each an sRGB array, the same size) in one row, or wrapped at `cols`, on a grey gutter."""
    cols = cols or len(tiles)
    h, w, _ = tiles[0].shape
    rows = math.ceil(len(tiles) / cols)
    sheet = np.full((rows * h + (rows + 1) * gap, cols * w + (cols + 1) * gap, 3), grey, np.float32)
    for i, t in enumerate(tiles):
        r, c = divmod(i, cols)
        y, x = gap + r * (h + gap), gap + c * (w + gap)
        sheet[y:y + h, x:x + w] = t
    write_png(sheet, out)


def phone_sheets(peaks, out_dir, names, phone=(667, 370), thumb=96, cols=3) -> None:
    """The review sheets of a set of peaks: peaks_phone.png (each at a small landscape phone) and peaks_squint.png (each
    brought to `thumb` px high and back up: does the shape still read at a glance?), with peaks_phone.txt naming them."""
    w, h = phone
    tiles = [read_png(p, phone, f"scale={w}:{h}:flags=area") for p in peaks]
    squints = [read_png(p, phone, f"scale=-2:{thumb}:flags=area,scale={w}:{h}:flags=bilinear") for p in peaks]
    out_dir = Path(out_dir)
    strip(tiles, out_dir / "peaks_phone.png", cols=cols)
    strip(squints, out_dir / "peaks_squint.png", cols=cols)
    (out_dir / "peaks_phone.txt").write_text(
        f"The peaks at a small landscape phone ({w}x{h}), left to right, {cols} a row: " + ", ".join(names) + ".\n"
        f"peaks_squint.png: the same, brought to {thumb} px high and back up (does the shape still read at a glance?).\n",
        encoding="utf-8")
