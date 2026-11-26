"""TR70 B's targets: the reveal's new stage, painted over the game's own figure (docs/test-requests.md, TR70, "B. The
stage's look, targets first"). Scintilla's. Each target: its peak frame and a strip of its life, for a new Rare (Lyric)
and a copy of a Common (Rook), at the stage's size (844 x 390 points, drawn at twice that), beside today's stage.

Feel line (TR70): your shard splits and the screen drops into the void; a new Voidkin lands huge on a burst of its
rarity's colour, a frame worth a screenshot, while a copy is a one-second tick on its star bar.

The technique the targets stand for (TR70 B): a full-screen ViewportFrame with its own camera, the figure at 60 to 70% of
the screen's height on a burst in its rarity's hue, a ring of light at its feet; violet only where the void shows.
Everything here is drawn as the game could draw it: flat shapes and added light on the screen, the figure as the engine
renders it in a ViewportFrame (its matte captured in Studio over black and over white: tools/fx/reveal_capture.lua,
then reveal_frames.py).

    py tools/fx/reveal_targets.py [figure_dir] [out_dir]
        figure_dir: the mattes, <Model>_<t>.png with alpha (default build/handoff/Reveal/new_stage/figures)
        out_dir:    default build/handoff/Reveal/new_stage/targets

Directions (two or three, for research's pick in pairs):
- R1, the shard burst: long cut-crystal rays out from behind the figure's chest, each a lit facet and a shaded one with
  a bright edge, a white core, a ring at the feet broken by angled shard cuts.
- R2, the rift: the split stays open as a tall jagged tear of light behind the figure, a narrow fan of facets from it,
  speed lines drawn into the void, the same ring.
- R3, the hue's field: the void breaks at the split into a bright field of the rarity's colour, pale at the figure and
  deep at the edges, white rays over it: the frame light, not black (the director's "too purple, black, somber").
The card beat carries today's words (the name, the plate) so a target stands beside today's on equal terms; the words
are TR70 A's and Faber's, drawn here only where they sit.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from paintover import blur, hexc, linear_to_srgb, read_png, srgb_to_linear, strip, write_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FIGURES = ROOT / "build" / "handoff" / "Reveal" / "new_stage" / "figures"
OUT = ROOT / "build" / "handoff" / "Reveal" / "new_stage" / "targets"
SCALE = 2
W, H = 844 * SCALE, 390 * SCALE

HUE = {"Common": hexc("#AEB4C0"), "Uncommon": hexc("#7CF0A0"), "Rare": hexc("#6FB6FF"), "Epic": hexc("#D29CFF"),
       "Legendary": hexc("#FFD777"), "Mythical": hexc("#FF8794")}  # the rarity's own (Config.Reveal.Plate.Words)
# R1's loudness by rarity (research's pick, must-fix 2): spokes, their reach (a share of the frame's half-diagonal), their
# light, and a second ring of thin spokes; the full frame is kept for the top rarities, a Rare sits mid-ladder
LADDER = {
    "Common": {"n": 8, "reach": 0.36, "k": 0.5, "thin": 0},
    "Uncommon": {"n": 10, "reach": 0.48, "k": 0.62, "thin": 0},
    "Rare": {"n": 14, "reach": 0.62, "k": 0.78, "thin": 0},
    "Epic": {"n": 18, "reach": 0.8, "k": 0.92, "thin": 10},
    "Legendary": {"n": 22, "reach": 1.0, "k": 1.05, "thin": 16},
    "Mythical": {"n": 24, "reach": 1.1, "k": 1.15, "thin": 22},
}
GRAPHITE = hexc("#17181C")  # AR62's A: the dim behind a screen
PANEL = hexc("#23252B")
VOID = hexc("#3A2A6E")  # the void's own violet, only where it shows: its motes and cracks at the edges
WHITE = np.ones(3, np.float32)
KNEE = 0.72
BLOOM = ((0.006, 0.5), (0.03, 0.3))

# The new Rare's timeline (seconds from the tap; today's Rare beats: split 0.85, name 1.59, card 2.39, Config.RevealArt)
SPLIT, NAME, CARD = 0.85, 1.59, 2.39
LIFE = [0.15, 0.35, 0.75, 0.87, 0.95, 1.1, 1.6, 2.4]  # the drop, the void, before the split, the split, the burst, its
# settle, the name, the card
PEAK = 2.4
STRIKE = {"Lyric": 1.5, "Rook": 0.85}  # each Reveal clip's strike (Config.Reveal.Strikes)
# The figure: its height a share of the screen's, its feet and its middle (TR70 B: 60 to 70%)
FIG_H, FIG_FEET, FIG_X = 0.66, 0.9, 0.64


# --- drawing on the screen ------------------------------------------------------------------------------------------
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)


def ease_out(t):
    t = np.clip(t, 0, 1)
    return 1 - (1 - t) ** 3


def life(t, a, b):
    return float(np.clip((t - a) / max(b - a, 1e-6), 0, 1))


def polygon(points, soft=1.2):
    """A convex polygon's coverage, anti-aliased by its edges' signed distances, in either winding."""
    cov = np.ones((H, W), np.float32)
    pts = [np.asarray(p, np.float32) for p in points]
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))
    if area < 0:
        pts = pts[::-1]
    for a, b in zip(pts, pts[1:] + pts[:1]):
        e = b - a
        n = np.array([e[1], -e[0]]) / (np.hypot(*e) + 1e-6)
        d = (xx - a[0]) * n[0] + (yy - a[1]) * n[1]
        cov = np.minimum(cov, np.clip(0.5 - d / soft, 0, 1))
    return cov


def segment(a, b, width, soft=1.0):
    """A line's coverage, round-ended, `width` pixels across."""
    a, b = np.asarray(a, np.float32), np.asarray(b, np.float32)
    ab = b - a
    t = np.clip(((xx - a[0]) * ab[0] + (yy - a[1]) * ab[1]) / (ab @ ab + 1e-6), 0, 1)
    d = np.hypot(xx - (a[0] + t * ab[0]), yy - (a[1] + t * ab[1]))
    return np.clip((width / 2 - d) / soft + 0.5, 0, 1)


def radial(c, r, falloff=2.0):
    d = np.hypot(xx - c[0], yy - c[1]) / r
    return np.exp(-d ** falloff)


class Shot:
    """One frame of the stage: a ground laid, light added in linear light, then the knee and the bloom."""

    def __init__(self, ground):
        self.img = np.broadcast_to(np.asarray(ground, np.float32), (H, W, 3)).copy()
        self.light = np.zeros((H, W, 3), np.float32)

    def lay(self, cov, colour, a=1.0):
        k = (cov * a)[..., None]
        self.img = self.img * (1 - k) + k * np.asarray(colour, np.float32)

    def add(self, cov, colour, k=1.0):
        self.light += cov[..., None] * (np.asarray(colour, np.float32) * k)

    def figure(self, rgba, k=1.0):
        """The game's figure, laid over in sRGB as the ViewportFrame draws it."""
        if rgba is None:
            return
        rgb, a = srgb_to_linear(rgba[..., :3]), rgba[..., 3:] * k
        self.flush()
        self.img = self.img * (1 - a) + rgb * a

    def flush(self):
        x = self.img + self.light
        over = np.clip(x - 1, 0, None).max(axis=2, keepdims=True)
        for s, k in BLOOM:
            x = x + blur(over * np.ones(3), s * H) * k * np.clip(self.light.max(axis=2, keepdims=True) * 4, 0, 1)
        top = x.max(axis=2, keepdims=True)
        soft = np.where(top > KNEE, KNEE + (1 - KNEE) * (1 - np.exp(-(top - KNEE) / (1 - KNEE))), top)
        x = x * (soft / np.maximum(top, 1e-6))
        self.img, self.light = x, np.zeros_like(self.light)

    def out(self):
        self.flush()
        return linear_to_srgb(self.img)


# --- the pieces ------------------------------------------------------------------------------------------------------
def figure_box():
    h = FIG_H * H
    feet = FIG_FEET * H
    return FIG_X * W, feet - h, feet, h  # middle x, head y, feet y, height


def chest():
    x, top, feet, h = figure_box()
    return np.array([x, top + 0.32 * h], np.float32)


def core():
    """The burst's white core: behind the chest's middle, well under the head (research's must-fix 1)."""
    x, top, feet, h = figure_box()
    return np.array([x, top + 0.42 * h], np.float32)


def keep_off(shot, rgba, land):
    """Research's must-fix 1, with the figure about to be laid: the added light kept off the head and hair, and a dark
    band round the figure's edge so it holds the strongest contrast over the spokes, in colour and in grey."""
    if rgba is None:
        return
    a = rgba[..., 3]
    x, top, feet, h = figure_box()
    head = blur(a * (yy < top + 0.24 * h), 10 * SCALE)
    shot.light *= (1 - 0.85 * np.clip(head * 3, 0, 1))[..., None]
    shot.flush()
    band = np.clip(blur(a, 4 * SCALE) * 2.2, 0, 1)
    shot.lay(band, hexc("#0B0C10"), 0.6 * land)


def void(shot, t, k, world=None):
    """The screen dropped into the void: the world dims as graphite closes in over it from the edges to the shard, the
    iris's lip and the motes the void's own violet, the only violet on the screen."""
    if k <= 0:
        return
    edge = np.clip(np.hypot((xx / W - 0.5) * 1.6, (yy / H - 0.5) * 1.9), 0, 1.2)
    shut = ease_out(life(t, 0.0, 0.55))
    if world is not None and shut < 1:
        shot.img = srgb_to_linear(world) * (1 - 0.55 * shut)
        c = chest()
        r = np.hypot((xx - c[0]) / W, (yy - c[1]) / W)
        iris = (1 - shut) * 0.75
        shot.lay(np.clip((r - iris) / 0.01, 0, 1), GRAPHITE, k)
        shot.add(np.exp(-((r - iris) / 0.006) ** 2), VOID, 2.2 * (1 - shut))
    else:
        shot.lay(np.ones((H, W), np.float32), GRAPHITE, k)
    shot.lay(np.clip(edge - 0.55, 0, 1) * 1.4, hexc("#0D0E11"), k)
    rng = np.random.default_rng(7)
    for _ in range(26):  # motes drawn in from the edges toward the shard
        a = rng.uniform(0, math.tau)
        r0 = rng.uniform(0.62, 0.95)
        pull = r0 - 0.35 * life(t, 0.0, SPLIT) * rng.uniform(0.6, 1.0)
        p = chest() + np.array([math.cos(a) * W * 0.55 * pull, math.sin(a) * H * 0.6 * pull])
        q = p + np.array([math.cos(a), math.sin(a)]) * rng.uniform(10, 26) * SCALE
        shot.add(segment(p, q, 1.6 * SCALE), VOID, 1.6 * k)


def shard(shot, t, hue):
    """Today's shard, held where the figure will land, its seams lit; it splits on SPLIT (a stand-in until the capture)."""
    c = chest() + np.array([0, 0.08 * H])
    if t >= SPLIT + 0.12:
        return
    s = 54 * SCALE  # today's shard's share of the height
    pts = [(0, -1.25), (0.55, -0.45), (0.5, 0.75), (0, 1.15), (-0.5, 0.75), (-0.55, -0.45)]
    apart = ease_out(life(t, SPLIT, SPLIT + 0.12)) * 60 * SCALE
    for side in (-1, 1):
        half = [(x, y) for x, y in pts if x * side >= 0]
        half = [(0, -1.25)] + [(x, y) for x, y in half if x != 0] + [(0, 1.15)]
        if side < 0:
            half = half[::-1]
        poly = [(c[0] + (x * s) + side * apart, c[1] + y * s - abs(x) * apart * 0.2) for x, y in half]
        if side < 0:
            poly = poly[::-1]
        gone = 1.0 - life(t, SPLIT, SPLIT + 0.12)
        # the void's own object, so the void's violet: a lit face and a shaded one, a pale rim (today's shard's size)
        shot.lay(polygon(poly), hexc("#7A64D6") if side < 0 else hexc("#3A2A6E"), gone)
        for i in range(len(poly)):
            shot.add(segment(poly[i], poly[(i + 1) % len(poly)], 1.1 * SCALE), hexc("#C9BEFF"), 0.35 * gone)
    seam = life(t, SPLIT - 0.3, SPLIT)
    shot.add(segment(c + [0, -1.25 * s], c + [0, 1.15 * s], 3 * SCALE * (0.4 + seam)), hue, 2.5 * seam)
    shot.add(radial(c, 40 * SCALE * (0.5 + seam)), hue, 0.5 * seam)


def blade(shot, t, hue):
    """The split: a blade of the rarity's light, white at its core, up through where the shard was, gone in a breath."""
    k = 1 - life(t, SPLIT + 0.02, SPLIT + 0.16) if t >= SPLIT else 0.0
    if k <= 0:
        return
    x, top, feet, h = figure_box()
    shot.add(segment((x, top - 0.1 * h), (x, feet + 0.02 * h), 10 * SCALE * k), hue, 3 * k)
    shot.add(segment((x, top - 0.1 * h), (x, feet + 0.02 * h), 3 * SCALE * k), WHITE, 2.5 * k)
    shot.add(np.ones((H, W), np.float32), hue, 0.12 * k)


def rays(shot, t, hue, n=22, reach=1.0, fan=None, turn=6.0, k=1.0, thin=False, seed=3):
    """R1's burst: cut-crystal rays, each a lit facet and a shaded one along a bright edge, a white core behind the chest
    (never behind the head: research's must-fix 1). `k` its light (the ladder's), `thin` the second ring's needles."""
    grow = ease_out(life(t, SPLIT, SPLIT + 0.18)) * (1 + 0.06 * math.sin(min(life(t, SPLIT + 0.18, SPLIT + 0.5), 1) * math.pi))
    if grow <= 0:
        return
    c = core()
    rng = np.random.default_rng(seed)
    spin = math.radians(turn) * max(t - SPLIT, 0)
    big = math.hypot(W, H) * 0.62 * reach
    for i in range(n):
        if fan is None:
            a = i / n * math.tau + rng.uniform(-0.08, 0.08) + spin
        else:
            a = -math.pi / 2 + (i / (n - 1) - 0.5) * fan + rng.uniform(-0.04, 0.04) + spin * 0.3
        length = big * rng.uniform(0.55, 1.0) * grow
        half = math.radians(rng.uniform(2.2, 4.2) * (0.35 if thin else 1.0))
        r0 = 0.1 * H
        tip = c + length * np.array([math.cos(a), math.sin(a)])
        root = c + r0 * np.array([math.cos(a), math.sin(a)])
        left = c + r0 * 1.6 * np.array([math.cos(a - half * 3), math.sin(a - half * 3)]) + (tip - c) * 0.12
        right = c + r0 * 1.6 * np.array([math.cos(a + half * 3), math.sin(a + half * 3)]) + (tip - c) * 0.12
        fade = 0.55 + 0.45 * rng.uniform(0, 1)
        lit = polygon([root, tip, left])
        shade = polygon([root, right, tip])
        along = np.clip(np.hypot(xx - c[0], yy - c[1]) / max(length, 1), 0, 1)
        falloff = (1 - along) ** 1.3
        shot.add(lit * falloff, hue, 1.25 * fade * k)
        shot.add(shade * falloff, hue, 0.45 * fade * k)
        shot.add(segment(root, tip, 1.4 * SCALE) * falloff, WHITE, 0.9 * fade * k)
    if not thin:
        shot.add(radial(c, 0.075 * H), WHITE, 2.0 * grow * k)
        shot.add(radial(c, 0.2 * H, 1.6), hue, 0.55 * grow * k)


def rift(shot, t, hue):
    """R2's tear: the split held open behind the figure, a tall jagged lens of light, white inside, its hue at the lips."""
    open_ = ease_out(life(t, SPLIT, SPLIT + 0.2))
    if open_ <= 0:
        return
    x, top, feet, h = figure_box()
    rng = np.random.default_rng(11)
    ys = np.linspace(-0.02 * H, feet + 0.02 * h, 17)
    widths = np.sin(np.linspace(0.15, math.pi - 0.05, len(ys))) ** 0.7 * 0.17 * W * open_
    jag = rng.uniform(-0.35, 0.35, len(ys)) * widths * 0.5
    for i in range(len(ys) - 1):
        for side in (-1, 1):
            quad = [(x + jag[i], ys[i]), (x + side * widths[i] + jag[i], ys[i]),
                    (x + side * widths[i + 1] + jag[i + 1], ys[i + 1]), (x + jag[i + 1], ys[i + 1])]
            if side > 0:
                quad = quad[::-1]
            cov = polygon(quad)
            shot.add(cov, hue, 0.5)
            shot.add(segment(quad[1] if side < 0 else quad[2], quad[2] if side < 0 else quad[1], 2.2 * SCALE), hue, 1.8)
    for i in range(len(ys) - 1):  # the seam: white only down its middle
        shot.add(segment((x + jag[i], ys[i]), (x + jag[i + 1], ys[i + 1]), 5 * SCALE * open_), WHITE, 1.6)
    shot.add(radial((x, top + 0.35 * h), 0.26 * H, 1.6), hue, 0.5 * open_)
    # speed lines drawn into the void toward the rift
    rng = np.random.default_rng(5)
    for _ in range(34):
        a = rng.uniform(0, math.tau)
        r = rng.uniform(0.5, 0.9)
        p = np.array([x, top + 0.4 * h]) + np.array([math.cos(a) * W * r, math.sin(a) * H * r])
        q = p + (np.array([x, top + 0.4 * h]) - p) * rng.uniform(0.15, 0.3)
        shot.add(segment(p, q, 1.3 * SCALE), hexc("#4A4F5A"), 0.5 * open_)


def ring(shot, t, hue, cuts=6):
    """The ring of light at the feet: a flat ellipse, white core and hue glow, broken by angled shard cuts."""
    grow = ease_out(life(t, SPLIT + 0.03, SPLIT + 0.3))
    if grow <= 0:
        return
    x, top, feet, h = figure_box()
    rx, ry = 0.36 * h * (0.6 + 0.4 * grow), 0.075 * h * (0.6 + 0.4 * grow)
    d = np.hypot((xx - x) / rx, (yy - feet) / ry)
    ang = np.arctan2((yy - feet) / ry, (xx - x) / rx)
    gap = np.ones_like(d)
    for i in range(cuts):
        a0 = i / cuts * math.tau + 0.4
        gap *= np.clip(np.abs(np.angle(np.exp(1j * (ang - a0 - (d - 1) * 2.5)))) / 0.06 - 0.5, 0, 1)
    band = np.clip(1 - np.abs(d - 1) * ry / (2.2 * SCALE), 0, 1) * gap
    core = np.clip(1 - np.abs(d - 1) * ry / (0.9 * SCALE), 0, 1) * gap
    shot.add(np.exp(-np.clip(d, 0, None) ** 2 * 1.6) * 0.5, hue, 0.6 * grow)
    shot.add(band, hue, 1.6 * grow)
    shot.add(core, WHITE, 1.4 * grow)


# --- the words at the card beat (today's lines, where they sit; the fonts are the game's: Theme.Font) ---------------
FONTS = ROOT / "build" / "scratch" / "modulo" / "fonts"  # the game's own font files, copied from Studio's content
DISPLAY, BODY, STRONG = "Oswald-Bold.ttf", "BuilderSans-Medium.otf", "BuilderSans-Bold.otf"
INK, MUTED = hexc("#F3EEE4"), hexc("#A9AEB8")
_text = {}


def text(words, font, pt, x, y, align="left", shear=0.0):
    """Coverage of `words` at (x, y) points (its top left; `align` right puts x at its right end), drawn by ffmpeg's
    drawtext in the game's font, sheared forward by `shear` (Display's italic lean)."""
    key = (words, font, pt, x, y, align, shear)
    if key in _text:
        return _text[key]
    import subprocess
    assert not any(c in words for c in ":,'\\"), words
    fx = f"{x * SCALE}-tw" if align == "right" else f"{x * SCALE}"
    vf = (f"drawtext=fontfile={(FONTS / font).relative_to(ROOT).as_posix()}:text={words}:fontsize={pt * SCALE}:"
          f"fontcolor=white:x={fx}:y={y * SCALE}")
    raw = subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i", f"color=c=black:s={W}x{H}", "-vf", vf,
                          "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "gray", "-"], capture_output=True, check=True,
                         cwd=ROOT).stdout
    cov = np.frombuffer(raw, np.uint8).reshape(H, W).astype(np.float32) / 255
    if shear:
        base = (y + pt) * SCALE
        src = np.clip((xx - (base - yy) * shear).astype(int), 0, W - 1)
        cov = np.take_along_axis(cov, src.astype(np.intp), axis=1)
    _text[key] = cov
    return cov


def words(shot, t, hue, name, light=False, rarity="Rare"):
    """The name at NAME and the plate at CARD, at today's places: the name large at the left over a bar of the hue,
    the plate under it (TR70 A's lines are Faber's; today's are drawn)."""
    shot.flush()
    k = ease_out(life(t, NAME - 0.1, NAME))
    if k > 0:
        dx = (1 - k) * -24
        shot.lay(text(name.upper(), DISPLAY, 58, 48 + dx, 115, shear=0.2), hexc("#0B1020"), 0.6 * k)  # its drop
        shot.lay(text(name.upper(), DISPLAY, 58, 46 + dx, 112, shear=0.2), INK if not light else hexc("#FFFFFF"), k)
        shot.lay(polygon([((40 + dx) * SCALE, 192 * SCALE), ((236 + dx) * SCALE, 192 * SCALE),
                          ((230 + dx) * SCALE, 197 * SCALE), ((36 + dx) * SCALE, 197 * SCALE)]), hue, k)
    k = ease_out(life(t, CARD - 0.14, CARD))
    if k > 0:
        cx, cy, w, h = 186 * SCALE, (250 + (1 - k) * 8) * SCALE, 300 * SCALE, 78 * SCALE
        body = cut_panel(cx, cy, w, h, 12 * SCALE)
        shot.lay(body, PANEL, 0.94 * k)
        shot.lay(np.clip(body - cut_panel(cx, cy, w - 3, h - 3, 12 * SCALE - 1), 0, 1), hexc("#4A4F5A"), k)
        y0 = 250 + (1 - k) * 8 - 39
        shot.lay(text("A new Voidkin", BODY, 13, 50, y0 + 10), MUTED, k)
        gem = (50 * SCALE + 4 * SCALE, (y0 + 38) * SCALE)
        shot.lay(polygon([(gem[0], gem[1] - 6 * SCALE), (gem[0] + 4 * SCALE, gem[1]), (gem[0], gem[1] + 6 * SCALE),
                          (gem[0] - 4 * SCALE, gem[1])]), hue, k)
        word = text(rarity, STRONG, 15, 62, y0 + 29)
        shot.lay(word, hue, k)
        cols = np.nonzero(word.max(axis=0) > 0.3)[0]
        end = cols.max() / SCALE if len(cols) else 99
        shot.lay(text("· Green · Healer", BODY, 15, end + 5, y0 + 29), INK, k)
        shot.lay(text("In your collection", BODY, 15, 50, y0 + 51), INK, k)


# --- R3's field --------------------------------------------------------------------------------------------------
def field(shot, t, hue):
    """R3: the void breaks at the split into the rarity's own field, pale at the figure, deep at the edges, a white
    light behind the chest, as a banner's pull lights its frame."""
    k = ease_out(life(t, SPLIT + 0.02, SPLIT + 0.2))
    if k <= 0:
        return
    c = chest()
    r = np.clip(np.hypot((xx - c[0]) / W, (yy - c[1]) / H * 0.55), 0, 1)
    pale = hue * 0.6 + 0.4 * np.asarray([0.92, 0.96, 1.0], np.float32)
    deep = hue * 0.2
    edge = hexc("#0E2550")
    mix = np.clip(r / 0.42, 0, 1)[..., None] ** 0.7
    ground = pale * (1 - mix) + deep * mix
    out = np.clip((r - 0.45) / 0.35, 0, 1)[..., None]
    ground = ground * (1 - out) + edge * out
    shot.img = shot.img * (1 - k) + ground * k


# --- the copy: Flash, a one-second tick on its star bar (TR70 A: 0.7 s, closes by itself 0.8 s after) ----------------
COPY_LIFE = [0.05, 0.12, 0.25, 0.32, 0.5, 0.8, 0.88, 1.0]
COPY_PEAK = 0.32  # the tick
COPY_CARD = (0.5, 0.47, 232, 196)  # its middle (shares of the screen) and its size in points: a panel, r10, AR62's material
TICK, CLOSE = 0.3, 0.8  # the plate closes itself after 0.8 s, gone by 0.95: done by 1.0 s from the tap (TR70's gate)


def cut_panel(cx, cy, w, h, cut):
    """AR62's panel: a box with the shard cut, its top-left and bottom-right corners chamfered by `cut`."""
    x0, x1, y0, y1 = cx - w / 2, cx + w / 2, cy - h / 2, cy + h / 2
    return polygon([(x0 + cut, y0), (x1, y0), (x1, y1 - cut), (x1 - cut, y1), (x0, y1), (x0, y0 + cut)])


def rounded(cx, cy, w, h, r, soft=1.2):
    dx = np.clip(np.abs(xx - cx) - (w / 2 - r), 0, None)
    dy = np.clip(np.abs(yy - cy) - (h / 2 - r), 0, None)
    return np.clip(0.5 - (np.hypot(dx, dy) - r) / soft, 0, 1)


def portrait(rgba, box):
    """Its head and shoulders: the top of its matte, fitted to the card's picture box."""
    if rgba is None:
        return None
    a = rgba[..., 3]
    rows, cols = np.where(a > 0.05)
    y0, y1 = rows.min(), rows.min() + int((rows.max() - rows.min()) * 0.46)
    mid = int(np.median(cols[rows < y1]))
    half = int((y1 - y0) * 0.62)
    crop = rgba[y0:y1, max(0, mid - half):mid + half]
    x, y, w, h = box
    k = min(w / crop.shape[1], h / crop.shape[0])
    nh, nw = int(crop.shape[0] * k), int(crop.shape[1] * k)
    ys = np.clip((np.arange(nh) / k).astype(int), 0, crop.shape[0] - 1)
    xs = np.clip((np.arange(nw) / k).astype(int), 0, crop.shape[1] - 1)
    out = np.zeros((H, W, 4), np.float32)
    oy, ox = int(y + h - nh), int(x + (w - nw) / 2)
    out[oy:oy + nh, ox:ox + nw] = crop[ys][:, xs]
    return out


def copy_frame(t, rook, world):
    hue = HUE["Common"]
    shot = Shot(GRAPHITE)
    if world is not None:
        shot.img = srgb_to_linear(world) * 0.55
    show = ease_out(life(t, 0.0, 0.12)) * (1 - life(t, CLOSE, CLOSE + 0.15))
    if show <= 0:
        return shot.out()
    cx, cy = COPY_CARD[0] * W, COPY_CARD[1] * H - (1 - show) * 14 * SCALE
    cw, ch = COPY_CARD[2] * SCALE * (0.9 + 0.1 * show), COPY_CARD[3] * SCALE * (0.9 + 0.1 * show)
    body = cut_panel(cx, cy, cw, ch, 14 * SCALE)
    shot.lay(body, hexc("#23252B"), show)
    shot.lay(np.clip(body - cut_panel(cx, cy, cw - 3, ch - 3, 14 * SCALE - 1), 0, 1), hexc("#4A4F5A"), show)
    shot.lay(rounded(cx, cy - ch / 2 + 1.5, cw - 24 * SCALE, 1.2 * SCALE, 0.6 * SCALE), hexc("#F3EEE4"), 0.25 * show)
    pic = (cx - cw / 2 + 12 * SCALE, cy - ch / 2 + 12 * SCALE, cw - 24 * SCALE, ch - 76 * SCALE)
    inside = rounded(pic[0] + pic[2] / 2, pic[1] + pic[3] / 2, pic[2], pic[3], 6 * SCALE)
    shot.lay(inside, hexc("#30333B"), show)
    c = np.array([pic[0] + pic[2] / 2, pic[1] + pic[3] * 0.52])
    burst = ease_out(life(t, 0.04, 0.2)) * (1 - 0.4 * life(t, 0.4, 0.9)) + 0.6 * max(0.0, 1 - abs(t - TICK) / 0.08)
    rng = np.random.default_rng(9)
    for i in range(12):  # a small grey facet burst behind the portrait, inside its box
        a = i / 12 * math.tau + rng.uniform(-0.1, 0.1) + 0.3 * t
        L = pic[3] * rng.uniform(0.55, 0.9) * burst
        half = math.radians(5)
        tip = c + L * np.array([math.cos(a), math.sin(a)])
        side = c + L * 0.18 * np.array([math.cos(a - half * 4), math.sin(a - half * 4)])
        shot.add(polygon([c, tip, side]) * inside, hue, 0.8 * show)
        shot.add(segment(c, tip, 1.2 * SCALE) * inside, WHITE, 0.4 * show)
    shot.add(radial(c, 0.12 * H) * inside, hue, 0.5 * burst * show)
    shot.figure(portrait(rook, pic), show)
    shot.flush()
    # its name and its copies, the count turning on the tick (TR70 A: "3 of 4 copies")
    row = (pic[1] + pic[3]) / SCALE + 7
    left, right = (cx - cw / 2) / SCALE + 14, (cx + cw / 2) / SCALE - 14
    shot.lay(text("Rook", STRONG, 15, left, row), INK, show)
    shot.lay(text(f"{3 if t >= TICK else 2} of 4 copies", BODY, 12, right, row + 3, align="right"), MUTED, show)
    # the star bar: four pips across the card, the third filling on the tick with a white flash
    bar_y = cy + ch / 2 - 16 * SCALE
    pw = (cw - 28 * SCALE - 3 * 6 * SCALE) / 4
    for i in range(4):
        px = cx - cw / 2 + 14 * SCALE + pw / 2 + i * (pw + 6 * SCALE)
        pip = rounded(px, bar_y, pw, 6 * SCALE, 3 * SCALE)
        shot.lay(pip, hexc("#3E424C"), show)
        fill = 1.0 if i < 2 else (ease_out(life(t, TICK - 0.04, TICK + 0.06)) if i == 2 else 0.0)
        shot.lay(pip, hexc("#F3EEE4"), fill * show)
        if i == 2:
            flash = max(0.0, 1 - abs(t - TICK - 0.02) / 0.1)
            shot.add(radial((px, bar_y), 16 * SCALE, 2), WHITE, 1.6 * flash * show)
    return shot.out()


# --- the frames ------------------------------------------------------------------------------------------------------
def load_figure(folder: Path, model: str, t: float):
    """The figure's matte nearest t, sized and placed: FIG_H of the screen, its feet at FIG_FEET, its middle at FIG_X."""
    files = sorted(folder.glob(f"{model}_*.png"))
    if not files:
        return None
    best = min(files, key=lambda p: abs(float(p.stem.split("_")[-1]) - t))
    rgba = read_rgba(best)
    a = rgba[..., 3]
    rows, cols = np.where(a > 0.05)
    y0, y1, x0, x1 = rows.min(), rows.max() + 1, cols.min(), cols.max() + 1
    crop = rgba[y0:y1, x0:x1]
    x, top, feet, h = figure_box()
    k = h / (y1 - y0)
    nh, nw = int(round((y1 - y0) * k)), int(round((x1 - x0) * k))
    ys = np.clip((np.arange(nh) / k).astype(int), 0, crop.shape[0] - 1)
    xs = np.clip((np.arange(nw) / k).astype(int), 0, crop.shape[1] - 1)
    big = crop[ys][:, xs]
    out = np.zeros((H, W, 4), np.float32)
    ox, oy = int(x - nw / 2), int(feet - nh)
    sy0, sx0 = max(0, -oy), max(0, -ox)
    ey, ex = min(nh, H - oy), min(nw, W - ox)
    out[oy + sy0:oy + ey, ox + sx0:ox + ex] = big[sy0:ey, sx0:ex]
    return out


def read_rgba(path):
    import subprocess
    import json
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                            "-of", "json", str(path)], capture_output=True, check=True)
    s = json.loads(probe.stdout)["streams"][0]
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgba", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(s["height"], s["width"], 4).astype(np.float32) / 255


def frame(direction, t, rarity, figures, world=None, name="Lyric"):
    hue = HUE[rarity]
    shot = Shot(GRAPHITE)
    void(shot, t, 1.0 - 0.6 * life(t, SPLIT, SPLIT + 0.3), world)
    if direction == "R1_burst":
        step = LADDER[rarity]
        if step["thin"]:
            rays(shot, t, hue, n=step["thin"], reach=step["reach"] * 1.05, k=step["k"] * 0.8, thin=True, seed=8)
        rays(shot, t, hue, n=step["n"], reach=step["reach"], k=step["k"])
    elif direction == "R2_rift":
        rift(shot, t, hue)
        rays(shot, t, hue, n=9, reach=0.75, fan=math.radians(150), turn=0)
    else:
        field(shot, t, hue)
        rays(shot, t, WHITE * 0.3 + hue * 0.4, n=18)
    ring(shot, t, hue if direction != "R3_field" else WHITE * 0.5 + hue * 0.5)
    shard(shot, t, hue)
    if t >= SPLIT + 0.04:
        land = ease_out(life(t, SPLIT + 0.04, SPLIT + 0.14))
        if direction == "R1_burst":
            keep_off(shot, figures(t), land)
        shot.figure(figures(t), land)
    blade(shot, t, hue)
    words(shot, t, hue, name, rarity=rarity)
    return shot.out()


def main(argv):
    flags = [x for x in argv if x.startswith("--")]
    argv = [x for x in argv if not x.startswith("--")]
    folder = Path(argv[0]) if argv else FIGURES
    out = Path(argv[1]) if len(argv) > 1 else OUT
    out.mkdir(parents=True, exist_ok=True)
    cache = {}

    def lyric(t):  # the new stage lands the figure at the split: its clip at its strike a breath after
        clip = STRIKE["Lyric"] + (t - SPLIT - 0.1)
        key = round(clip, 2)
        if key not in cache:
            cache[key] = load_figure(folder, "Lyric", clip)
        return cache[key]

    world = folder / "world.png"  # the frame the reveal starts over: the Breaker in the world, its HUD hidden
    # Studio's viewport is 1.8:1 and the phone's 2.16:1: its width fitted from the top, so Roblox's top bar stays whole
    # as a phone shows it (never stretched); the capture's marker at the corner painted out with the sky beside it
    if world.exists():
        world = read_png(world, size=(W, H), vf=f"scale={W}:-2,crop={W}:{H}:0:0").copy()
        world[:14, :14] = world[16, 16]
    else:
        world = None
    # research's pick (TR70, 2026-11-26): R1 and C1; R2 and R3 stay on file (e68f68f3), drawn again with --all
    ladder = [frame("R1_burst", PEAK, r, lyric, world)[::2, ::2] for r in LADDER]
    strip(ladder, out / "R1_burst_ladder.png", cols=3)
    (out / "R1_burst_ladder.txt").write_text(
        f"R1's ladder at {PEAK:.2f} s from the tap, one frame per rarity: " + ", ".join(LADDER) + " (rows of three)" + chr(10),
        encoding="utf-8")
    print("R1 ladder done")
    for direction in ("R1_burst", "R2_rift", "R3_field") if "--all" in flags else ("R1_burst",):
        write_png(frame(direction, PEAK, "Rare", lyric, world), out / f"{direction}_Lyric_peak.png")
        tiles = [frame(direction, t, "Rare", lyric, world)[::2, ::2] for t in LIFE]
        strip(tiles, out / f"{direction}_Lyric_strip.png", cols=len(LIFE))
        (out / f"{direction}_Lyric_strip.txt").write_text(
            f"{direction}, a new Rare (Lyric), its life at " + ", ".join(f"{t:.2f}" for t in LIFE) + " s from the tap\n",
            encoding="utf-8")
        print(direction, "done")
    rook = load_figure_raw(folder, "Rook", 1.6)
    write_png(copy_frame(COPY_PEAK, rook, world), out / "C1_copy_Rook_peak.png")
    strip([copy_frame(t, rook, world)[::2, ::2] for t in COPY_LIFE], out / "C1_copy_Rook_strip.png", cols=len(COPY_LIFE))
    (out / "C1_copy_Rook_strip.txt").write_text(
        "C1, a copy of a Common (Rook), its life at " + ", ".join(f"{t:.2f}" for t in COPY_LIFE) + " s from the tap" + chr(10),
        encoding="utf-8")
    print("C1_copy done")


def load_figure_raw(folder: Path, model: str, t: float):
    files = sorted(folder.glob(f"{model}_*.png"))
    if not files:
        return None
    return read_rgba(min(files, key=lambda p: abs(float(p.stem.split("_")[-1]) - t)))


if __name__ == "__main__":
    main(sys.argv[1:])
