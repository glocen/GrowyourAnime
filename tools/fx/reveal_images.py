"""TR70 B's install images for R1, the shard burst (Scintilla's): the picked target (reveal_targets.py) cut into the
images the reveal's ScreenGui lays, and a check that lays them as the engine does, beside the target.

    py tools/fx/reveal_images.py [figure_dir] [out_dir]
        figure_dir: the mattes, as reveal_targets.py takes them (default build/handoff/Reveal/new_stage/figures)
        out_dir:    default build/handoff/Reveal/new_stage/images; the check goes to new_stage/sheets/R1_install_check.png

Each image is white, so ImageColor3 tints it with the rarity's hue (Config.Reveal.Plate.Words), and its alpha is the
light the target adds over the void's graphite. UI blends by alpha in sRGB, so a light I becomes an alpha I ** 0.45.
The white parts (the ridge, the core, the ring's line) are their own images, laid untinted over the tinted ones.

- fx_reveal_spoke (128 x 1024): one cut-crystal ray, root at the bottom and tip at the top. A lit facet left of the
  ridge, a shaded one right, both fading to the tip. Tinted.
- fx_reveal_spoke_edge (128 x 1024): the bright ridge alone, on the same canvas, laid over the spoke. White.
- fx_reveal_core (256): the white core behind the chest. White.
- fx_reveal_glow (256): the hue's wide glow round the core. Tinted.
- fx_reveal_ring (1024 x 224): the ring at the feet with its angled shard cuts and the glow inside it, drawn at the
  ellipse's own aspect for its resolution. Tinted.
- fx_reveal_ring_core (1024 x 224): the ring's white line, on the same canvas. White.

How the install lays them (reveal_targets.py's rays() and ring(), seed 3; sizes in points on the 844 x 390 stage, so
half the target's pixels; the core is behind the chest, 0.42 of the figure down):
- Each spoke i, angle a, length L from the core, half-angle h (rays()): an ImageLabel of size
  (1.6 * r0 * sin(3h) / 0.4, L - r0) with r0 = 0.1 of the stage's height, its centre at core + dir(a) * (r0 + L) / 2,
  Rotation = deg(a) + 90, so its top points out. The edge is a second label, the same size and place.
  ImageTransparency: the spoke 1 - min(1, (1.25 * fade * k) ** 0.45), the edge 1 - min(1, (0.9 * fade * k) ** 0.45),
  with fade the spoke's own (0.55 to 1) and k the ladder's light (LADDER). A thin spoke (Epic and up) is the same
  pair at 0.35 of h, seed 8.
- The core: 7 * 0.075 of the stage's height square at the core, 1 - k ** 0.45. The glow: 9 * 0.2 of it square,
  1 - (0.55 * k) ** 0.45.
- The light kept off the head (research's must-fix 1): the core image again, ImageColor3 black, ImageTransparency
  0.3, 7 * 0.08 of the figure's height square at the head's middle (0.13 of the figure down), over the burst and
  under the figure, so it sits mostly behind the head (at 0.12 and 0.15 it showed as a dark blob over the hair).
- The dark band round the figure: its ViewportFrame twice more behind it, ImageColor3 black, 6% larger at
  ImageTransparency 0.7 and 3% larger at 0.55, each grown about the figure's middle: one copy drew a hard outline.
- The ring: (4.4 * rx, 4.62 * ry) at the feet, rx = 0.36 and ry = 0.075 of the figure's height, both times
  (0.6 + 0.4 * grow); its line the same. ImageTransparency 1 - grow ** 0.45.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from scipy.ndimage import map_coordinates

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reveal_targets as rt  # noqa: E402
from paintover import linear_to_srgb, strip, write_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "build" / "handoff" / "Reveal" / "new_stage"
GAMMA = 0.45  # a light's alpha over a dark ground, in sRGB

SPOKE = (128, 1024)  # width, height
WIDE = 0.4  # the kite's half-width, a share of the canvas's width
KNEE_AT = 0.233  # where the kite is widest, a share of its length from the root (a Rare's mean spoke)
ROOT_SHARE = 0.14  # r0 / L for a Rare's mean spoke: where the root sits on the falloff from the core
EDGE_PT = 1.4  # the ridge's width in points (rays(): 1.4 * SCALE pixels)
CORE_D, GLOW_D = 3.5, 4.5  # how far each radial runs, in its own radii, before it is gone
RING = (1024, 224)
RING_X, RING_Y = 2.2, 2.31  # the ring's canvas, in the ellipse's own radii each way
RY_PT = 0.075 * rt.FIG_H * 390  # the ring's vertical radius in points, which sets its line's width


def window(d, edge=1.0):
    """1 inside, smoothly 0 at `edge`: no image ends on a visible cut."""
    u = np.clip((d / edge - 0.85) / 0.15, 0, 1)
    return 1 - u * u * (3 - 2 * u)


def kite_coverage(xx, yy, pts, soft=1.0):
    cov = np.ones_like(xx)
    pts = [np.asarray(p, np.float32) for p in pts]
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))
    if area < 0:
        pts = pts[::-1]
    for a, b in zip(pts, pts[1:] + pts[:1]):
        e = b - a
        n = np.array([e[1], -e[0]]) / (np.hypot(*e) + 1e-6)
        d = (xx - a[0]) * n[0] + (yy - a[1]) * n[1]
        cov = np.minimum(cov, np.clip(0.5 - d / soft, 0, 1))
    return cov


def white(alpha):
    out = np.ones(alpha.shape + (4,), np.float32)
    out[..., 3] = np.clip(alpha, 0, 1)
    return out


def spoke_images():
    w, h = SPOKE
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32) + 0.5
    mid = w / 2
    root, tip = (mid, h), (mid, 0)
    left, right = (mid - WIDE * w, h * (1 - KNEE_AT)), (mid + WIDE * w, h * (1 - KNEE_AT))
    s = 1 - yy / h  # 0 at the root, 1 at the tip
    falloff = (1 - (ROOT_SHARE + (1 - ROOT_SHARE) * s)) ** 1.3
    lit = kite_coverage(xx, yy, [root, tip, left])
    shade = kite_coverage(xx, yy, [root, right, tip])
    spoke = lit * falloff ** GAMMA + shade * (0.45 / 1.25 * falloff) ** GAMMA
    px_per_pt = WIDE * w / (1.6 * 0.1 * 390 * math.sin(math.radians(3 * 3.2)))  # a mean Rare spoke's width
    edge_w = EDGE_PT * px_per_pt
    ridge = np.clip((edge_w / 2 - np.abs(xx - mid)) + 0.5, 0, 1) * (yy > 0)
    return white(spoke), white(ridge * falloff ** GAMMA)


def radial_image(size, reach, light, falloff):
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32) + 0.5
    d = np.hypot(xx - size / 2, yy - size / 2) / (size / 2) * reach
    return white(np.clip(light * np.exp(-d ** falloff), 0, 1) ** GAMMA * window(d, reach))


def ring_images():
    w, h = RING
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32) + 0.5
    nx, ny = (xx - w / 2) / (w / 2) * RING_X, (yy - h / 2) / (h / 2) * RING_Y
    d = np.hypot(nx, ny)
    ang = np.arctan2(ny, nx)
    gap = np.ones_like(d)
    for i in range(6):  # ring()'s six angled shard cuts
        a0 = i / 6 * math.tau + 0.4
        gap *= np.clip(np.abs(np.angle(np.exp(1j * (ang - a0 - (d - 1) * 2.5)))) / 0.06 - 0.5, 0, 1)
    band = np.clip(1 - np.abs(d - 1) * RY_PT / 2.2, 0, 1) * gap
    line = np.clip(1 - np.abs(d - 1) * RY_PT / 0.9, 0, 1) * gap
    fade = window(np.maximum(np.abs(nx) / RING_X, np.abs(ny) / RING_Y))
    glow = 0.3 * np.exp(-np.clip(d, 0, None) ** 2 * 1.6)
    return white(np.clip(1.6 * band + glow, 0, 1) ** GAMMA * fade), white(np.clip(1.4 * line, 0, 1) ** GAMMA * fade)


def write_rgba(img, path):
    import subprocess
    h, w, _ = img.shape
    data = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8).tobytes()
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{w}x{h}", "-i", "-",
                    "-pix_fmt", "rgba", str(path)], input=data, check=True)


# --- the check: the images laid as the engine lays them, in the target's pixels --------------------------------------
def lay(canvas, img, centre, size, rotation, tint=(1.0, 1.0, 1.0), opacity=1.0):
    """An ImageLabel: `img` stretched to `size` (pixels), its centre at `centre`, turned `rotation` degrees clockwise
    about its centre, its colour times `tint` (sRGB), laid by alpha over `canvas` (sRGB)."""
    H, W, _ = canvas.shape
    th = math.radians(rotation)
    right = np.array([math.cos(th), math.sin(th)])
    down = np.array([-math.sin(th), math.cos(th)])
    half = 0.5 * math.hypot(*size) + 2
    x0, x1 = int(max(0, centre[0] - half)), int(min(W, centre[0] + half))
    y0, y1 = int(max(0, centre[1] - half)), int(min(H, centre[1] + half))
    if x0 >= x1 or y0 >= y1:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32) + 0.5
    qx, qy = xx - centre[0], yy - centre[1]
    u = ((qx * right[0] + qy * right[1]) / size[0] + 0.5) * img.shape[1] - 0.5
    v = ((qx * down[0] + qy * down[1]) / size[1] + 0.5) * img.shape[0] - 0.5
    a = map_coordinates(img[..., 3], [v, u], order=1, cval=0.0) * opacity
    rgb = np.stack([map_coordinates(img[..., c], [v, u], order=1, cval=0.0) for c in range(3)], -1)
    rgb = rgb * np.asarray(tint, np.float32)
    k = a[..., None]
    canvas[y0:y1, x0:x1] = canvas[y0:y1, x0:x1] * (1 - k) + rgb * k


def spokes(canvas, imgs, hue, n, reach, k, thin, seed, t):
    spoke, edge = imgs
    c = rt.core()
    rng = np.random.default_rng(seed)
    spin = math.radians(6.0) * max(t - rt.SPLIT, 0)
    big = math.hypot(rt.W, rt.H) * 0.62 * reach
    r0 = 0.1 * rt.H
    for i in range(n):  # rays()'s draws, in its order, so each spoke is the target's own
        a = i / n * math.tau + rng.uniform(-0.08, 0.08) + spin
        length = big * rng.uniform(0.55, 1.0)
        h = math.radians(rng.uniform(2.2, 4.2) * (0.35 if thin else 1.0))
        fade = 0.55 + 0.45 * rng.uniform(0, 1)
        width = 1.6 * r0 * math.sin(3 * h) / WIDE
        centre = c + np.array([math.cos(a), math.sin(a)]) * (r0 + length) / 2
        rot = math.degrees(a) + 90
        lay(canvas, spoke, centre, (width, length - r0), rot, hue, min(1, (1.25 * fade * k) ** GAMMA))
        lay(canvas, edge, centre, (width, length - r0), rot, (1, 1, 1), min(1, (0.9 * fade * k) ** GAMMA))


def install_frame(rarity, imgs, figures):
    t = rt.PEAK
    hue = tuple(float(x) for x in linear_to_srgb(rt.HUE[rarity]))
    shot = rt.Shot(rt.GRAPHITE)
    rt.void(shot, t, 1.0 - 0.6 * rt.life(t, rt.SPLIT, rt.SPLIT + 0.3))
    canvas = shot.out().astype(np.float32)
    step = rt.LADDER[rarity]
    c = rt.core()
    lay(canvas, imgs["glow"], c, (2 * GLOW_D * 0.2 * rt.H,) * 2, 0, hue, min(1, (0.55 * step["k"]) ** GAMMA))
    if step["thin"]:
        spokes(canvas, imgs["spoke"], hue, step["thin"], step["reach"] * 1.05, step["k"] * 0.8, True, 8, t)
    spokes(canvas, imgs["spoke"], hue, step["n"], step["reach"], step["k"], False, 3, t)
    lay(canvas, imgs["core"], c, (2 * CORE_D * 0.075 * rt.H,) * 2, 0, (1, 1, 1), min(1, step["k"] ** GAMMA))
    x, top, feet, h = rt.figure_box()
    lay(canvas, imgs["core"], (x, top + 0.13 * h), (2 * CORE_D * 0.08 * h,) * 2, 0, (0, 0, 0), 0.7)  # off the head
    size = (2 * RING_X * 0.36 * h, 2 * RING_Y * 0.075 * h)
    lay(canvas, imgs["ring"], (x, feet), size, 0, hue)
    lay(canvas, imgs["ring_core"], (x, feet), size, 0)
    fig = figures(t)
    if fig is not None:  # the dark band: the figure's ViewportFrame again in black, larger, behind it
        box = np.array([x, top + h / 2])  # grown about the figure's own middle
        frame_mid = np.array([fig.shape[1] / 2, fig.shape[0] / 2])
        black = np.zeros_like(fig)
        black[..., 3] = fig[..., 3]
        for grow, a in ((1.06, 0.3), (1.03, 0.45)):  # two steps, so the band softens outward as the target's blur does
            lay(canvas, black, box + grow * (frame_mid - box), (fig.shape[1] * grow, fig.shape[0] * grow), 0, (0, 0, 0), a)
        k = fig[..., 3:]
        canvas = canvas * (1 - k) + fig[..., :3] * k
    return canvas


def main(argv):
    folder = Path(argv[0]) if argv else rt.FIGURES
    out = Path(argv[1]) if len(argv) > 1 else STAGE / "images"
    spoke, edge = spoke_images()
    ring, ring_core = ring_images()
    imgs = {"spoke": (spoke, edge), "core": radial_image(256, CORE_D, 2.0, 2.0),
            "glow": radial_image(256, GLOW_D, 1.0, 1.6), "ring": ring, "ring_core": ring_core}
    for name, img in (("spoke", spoke), ("spoke_edge", edge), ("core", imgs["core"]), ("glow", imgs["glow"]),
                      ("ring", ring), ("ring_core", ring_core)):
        write_rgba(img, out / f"fx_reveal_{name}.png")
    print("images:", ", ".join(sorted(p.name for p in out.glob("fx_reveal_*.png"))))

    cache = {}

    def lyric(t):
        clip = rt.STRIKE["Lyric"] + (t - rt.SPLIT - 0.1)
        key = round(clip, 2)
        if key not in cache:
            cache[key] = rt.load_figure(folder, "Lyric", clip)
        return cache[key]

    rt.words = lambda *a, **k: None  # the burst compared alone: the card's words are the same on both sides
    tiles = []
    for rarity in ("Rare", "Legendary"):
        tiles.append(rt.frame("R1_burst", rt.PEAK, rarity, lyric)[::2, ::2])
        tiles.append(install_frame(rarity, imgs, lyric)[::2, ::2])
    sheet = STAGE / "sheets" / "R1_install_check.png"
    strip(tiles, sheet, cols=2)
    sheet.with_suffix(".txt").write_text(
        "R1 at its peak, the target (left) beside its install images laid as the engine lays them (right): a Rare, "
        "then a Legendary with its thin needles. The card's words left out of both.\n", encoding="utf-8")
    print("wrote", sheet.relative_to(ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
