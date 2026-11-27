"""AR70, the game page's icon: three targets for the director's side by side (docs/requests/AR70.md).

    py tools/ui/ar70_icon_targets.py <renders_dir> <out_dir>

Rook is tools/blender/ar70_icon.py's render: the make's model on his own Haymaker clip, in the game's day light, his
right wraps heated as the move heats them (`<renders>/<shot>.png`, with `<shot>.json`: where his fist and head fall).
Everything else is painted here with the top-left plate's own tools (hud_m_lead_targets.py): the HUD's slate and
ember, its halftone, lacquer and ink, and Montserrat Black for the words. No outside picture is used.

  A, the strike: his fist driven at the lens out of an ember burst, the speed of it radiating behind him.
  B, the card: the HUD's ember card behind him, his reach crossing it, the slate blade under him carrying the words.
  C, the stare: in close, the fist cocked and burning by his face, its light raking him from the side.

Each is drawn at 1024 px (2 px a point on a 512-point square) and shown at 512, 150 and 100 px: Roblox's page states
the icon at 512 and "like 150x150" on its pages; 100 is the hard case (research, 2026-11-27, AR70). Out: `<out>/
icon_<A|B|C>.png` (512), the small sizes, and `icon_sheet.png`, the three side by side at each size on Roblox's dark
and light pages.
"""
import json
import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import hud_m_lead_targets as hl  # noqa: E402
import style_frames as sf  # noqa: E402

S = 512                     # the icon's square, in points
hl.PPP = 2                  # 2 px a point: drawn at 1024, shown at 512
hl.set_grid(0, 0, S, S)
P = hl.PPP
SLATE_TOP, SLATE_BOT = hl.SLATE_TOP, hl.SLATE_BOT
EMBER, EMBER_HOT, EMBER_DEEP, CREAM = hl.EMBER, hl.EMBER_HOT, hl.EMBER_DEEP, hl.CREAM
WORDS = "EARLY ACCESS"
K = 0.26                    # the HUD's slant: points across a point down (A's card and blade)


# --- the figure -------------------------------------------------------------------------------------------------------

def place(renders, name, k, ox, oy):
    """The render on the canvas, premultiplied: its pixel (u, v) lands at points (ox + u k, oy + v k). Its marks too."""
    img = hl.read_png(renders / f"{name}.png")
    marks = json.loads((renders / f"{name}.json").read_text())
    u = (hl.GX - ox) / k - 0.5
    v = (hl.GY - oy) / k - 0.5
    pre = np.dstack([img[..., :3] * img[..., 3:4], img[..., 3]])
    out = np.stack([ndimage.map_coordinates(pre[..., c], [v, u], order=1, mode="constant", cval=0.0) for c in range(4)], -1)
    pts = {key: (ox + val[0] * k, oy + val[1] * k) for key, val in marks.items() if key != "size"}
    return np.clip(out, 0, 1), pts


def ink_edge(alpha, width):
    """The figure cut out in the HUD's ink: a line `width` points wide round its silhouette, drawn under it."""
    outside = ndimage.distance_transform_edt(alpha < 0.5) / P
    return hl.layer(hl.INK, hl.cov(outside - width))


def rim(alpha, light, colour, width, k=1.0):
    """A painted rim inside the silhouette, on the side that faces `light` (a direction in the picture, y down)."""
    b = ndimage.gaussian_filter(alpha, max(width * 0.6, 1.0) * P)
    gy, gx = np.gradient(b)
    n = np.hypot(gx, gy) + 1e-6
    lx, ly = np.array(light, float) / math.hypot(*light)
    facing = np.clip(-(gx * lx + gy * ly) / n, 0, 1) ** 0.8
    inside = ndimage.distance_transform_edt(alpha > 0.5) / P
    band = np.clip(1 - inside / width, 0, 1) ** 1.4
    return hl.layer(hl.rgb(colour), np.clip(facing * band * k, 0, 1) * alpha)


def warm(fig, centre, radius, colour, k):
    """The fist's own light on him: a screen of `colour` falling off from `centre`, on the figure only."""
    d = np.hypot(hl.GX - centre[0], hl.GY - centre[1]) / radius
    f = (np.clip(1 - d, 0, 1) ** 2 * k)[..., None] * hl.rgb(colour)
    a = fig[..., 3:4]
    u = np.where(a > 1e-4, fig[..., :3] / np.maximum(a, 1e-4), 0)
    u = 1 - (1 - u) * (1 - f)
    return np.dstack([u * a, a])


def grade(fig, lift=0.0, contrast=1.12, sat=1.1):
    """A finish on the render: a touch more contrast and colour, as key art is graded."""
    a = fig[..., 3:4]
    u = np.where(a > 1e-4, fig[..., :3] / np.maximum(a, 1e-4), 0)
    grey = u.mean(axis=-1, keepdims=True)
    u = grey + (u - grey) * sat
    u = np.clip((u - 0.5) * contrast + 0.5 + lift, 0, 1)
    return np.dstack([u * a, a])


# --- light and speed --------------------------------------------------------------------------------------------------

def screen(base, light):
    """`light` (H, W, 3, 0..1) screened over an opaque picture."""
    return np.dstack([1 - (1 - base[..., :3]) * (1 - np.clip(light, 0, 1)), base[..., 3:4]])


def flare(centre, r, rays=11, seed=1, spin=0.0, length=(1.6, 3.4)):
    """The strike's light at the fist: a hot core, an ember halo, and thin rays, as a field to screen on."""
    cx, cy = centre
    d = np.hypot(hl.GX - cx, hl.GY - cy)
    th = np.arctan2(hl.GY - cy, hl.GX - cx)
    rng = np.random.default_rng(seed)
    beams = np.zeros_like(d)
    for i in range(rays):
        a = spin + i * 2 * math.pi / rays + rng.uniform(-0.22, 0.22)
        ln = r * rng.uniform(*length)
        w = rng.uniform(1.2, 3.0)
        off = np.abs(np.sin(th - a)) * d                  # distance from the ray's line, in points
        ahead = np.cos(th - a) > 0
        taper = np.clip(1 - d / ln, 0, 1)
        beams = np.maximum(beams, hl.cov(off - w * taper) * taper ** 1.3 * ahead)
    core = np.exp(-(d / (r * 0.32)) ** 2)
    halo = np.exp(-(d / r) ** 2)
    glow = np.exp(-(d / (r * 2.6)) ** 2)
    col = (hl.rgb("#FFF4E6") * core[..., None] + hl.rgb(EMBER_HOT) * (halo * 0.9)[..., None]
           + hl.rgb(EMBER) * (glow * 0.55)[..., None] + hl.rgb(EMBER_HOT) * (beams * 0.9)[..., None])
    return col


def sparks(centre, r0, r1, n, seed, colour=EMBER_HOT, size=(5, 14), width=1.1):
    """Embers thrown off the strike: short streaks pointing away from `centre`, between radii r0 and r1."""
    rng = np.random.default_rng(seed)
    acc = np.zeros(hl.GX.shape)
    cx, cy = centre
    for _ in range(n):
        a = rng.uniform(0, 2 * math.pi)
        rr = rng.uniform(r0, r1)
        ln = rng.uniform(*size) * (1 - (rr - r0) / (r1 - r0) * 0.5)
        x0, y0 = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        x1, y1 = x0 + math.cos(a) * ln, y0 + math.sin(a) * ln
        dx, dy = x1 - x0, y1 - y0
        t = np.clip(((hl.GX - x0) * dx + (hl.GY - y0) * dy) / (dx * dx + dy * dy), 0, 1)
        dist = np.hypot(hl.GX - (x0 + t * dx), hl.GY - (y0 + t * dy))
        acc = np.maximum(acc, hl.cov(dist - width * (1 - t * 0.7)) * rng.uniform(0.6, 1.0))
    return acc[..., None] * hl.rgb(colour)


def radial_lines(centre, n, seed, r0, width=(0.8, 2.6), alpha=0.5):
    """Speed radiating from the strike: thin wedges from r0 out past the canvas, each at its own strength."""
    rng = np.random.default_rng(seed)
    cx, cy = centre
    d = np.hypot(hl.GX - cx, hl.GY - cy)
    th = np.arctan2(hl.GY - cy, hl.GX - cx)
    acc = np.zeros_like(d)
    for _ in range(n):
        a = rng.uniform(-math.pi, math.pi)
        w = rng.uniform(*width)
        start = r0 * rng.uniform(0.9, 1.6)
        off = np.abs(np.sin(th - a)) * d
        ahead = (np.cos(th - a) > 0) & (d > start)
        grow = np.clip((d - start) / 120, 0, 1)
        acc = np.maximum(acc, hl.cov(off - w * grow) * grow * ahead * rng.uniform(0.4, 1.0))
    return acc * alpha


# --- grounds ----------------------------------------------------------------------------------------------------------

def slate(top=SLATE_TOP, bot=SLATE_BOT):
    t = np.clip(hl.GY / S, 0, 1)[..., None]
    c = hl.rgb(top) * (1 - t) + hl.rgb(bot) * t
    return np.dstack([hl.grain(c, k=0.02, seed=5), np.ones(hl.GX.shape)])


def burst(centre, r, deep_at=1.0):
    """An ember burst on the slate: hot at the centre, ember, then the deep ember, the slate beyond, the turn between
    them dotted in the HUD's halftone."""
    d = np.hypot(hl.GX - centre[0], hl.GY - centre[1]) / r
    hot = np.clip(1 - d * 1.6, 0, 1)
    mid = np.clip(1 - np.abs(d - 0.55) * 2.2, 0, 1)
    deep = np.clip(1 - np.abs(d - deep_at) * 2.0, 0, 1)
    c = hl.rgb(EMBER_HOT) * hot[..., None] + hl.rgb(EMBER) * mid[..., None] + hl.rgb(EMBER_DEEP) * deep[..., None]
    a = np.clip(hot + mid + deep, 0, 1)
    dots = hl.halftone(9.0, 3.6, np.clip((d - 0.75) * 2.2, 0, 1)) * (d > 0.75) * (d < 1.35)
    out = hl.layer(np.clip(c / np.maximum(a[..., None], 1e-4), 0, 1), a)
    return hl.over(out, hl.layer(hl.rgb(EMBER_DEEP) * 0.9, dots * 0.8))


def vignette(img, k=0.45):
    d = np.hypot(hl.GX - S / 2, hl.GY - S / 2) / (S * 0.72)
    f = 1 - np.clip(d, 0, 1) ** 2.2 * k
    return np.dstack([img[..., :3] * f[..., None], img[..., 3:4]])


def slant(x0, x1, y0, y1):
    """A parallelogram in the HUD's slant, its foot from x0 to x1 at y1, leaning right as it rises to y0."""
    return hl.convex([(x0 + (y1 - y0) * K, y0), (x1 + (y1 - y0) * K, y0), (x1, y1), (x0, y1)])


def blade(x0, x1, y0, y1, edge=EMBER):
    """The HUD's slate blade, lacquered, an ember line on its top edge."""
    sd = slant(x0, x1, y0, y1)
    c = hl.grain(hl.lacquer(hl.vgrad(sd, SLATE_TOP, SLATE_BOT), sd, rim="#C9CED8", rim_k=0.5, band=5))
    out = hl.over(hl.layer(hl.INK, hl.cov(sd - 3.0)), hl.layer(c, hl.cov(sd)))
    top = np.maximum(sd, -(hl.GY - (y0 + 4.5)))      # the band along its top, 4.5 points deep
    return hl.over(out, hl.layer(hl.rgb(edge), hl.cov(top)))


def card(x0, x1, y0, y1):
    """The HUD's ember card (A's), at the icon's size: lacquered ember, its halftone deepening toward its foot."""
    sd = slant(x0, x1, y0, y1)
    r = np.clip((hl.GY - y0) / (y1 - y0), 0, 1)
    c = (hl.rgb(EMBER_HOT) * np.clip(1 - r * 1.7, 0, 1)[..., None] + hl.rgb(EMBER) * np.clip(1 - np.abs(r * 1.7 - 0.85), 0, 1)[..., None]
         + hl.rgb(EMBER_DEEP) * np.clip(r * 1.7 - 0.7, 0, 1)[..., None])
    c = hl.grain(hl.lacquer(c, sd, rim=EMBER_HOT, rim_k=0.6, band=6))
    out = hl.over(hl.layer(hl.INK, hl.cov(sd - 4.0)), hl.layer(c, hl.cov(sd)))
    return hl.over(out, hl.layer(hl.rgb(EMBER_DEEP) * 0.55, hl.halftone(8.0, 3.4, r * 1.5 - 0.35) * hl.cov(sd) * 0.7))


# --- the words --------------------------------------------------------------------------------------------------------

def words_svg(x, y, size, anchor="start", fill=CREAM, stroke=3.2, track=1.5, hard=3.0, skew=0.0):
    """'EARLY ACCESS' in the HUD's type: Montserrat Black, an ink stroke round it and a hard ink copy under it."""
    common = (f'font-family="MontBlack" font-size="{size}" text-anchor="{anchor}" letter-spacing="{track}" '
              f'stroke-linejoin="round" paint-order="stroke" transform="translate({x} {y}) skewX({skew})"')
    return (f'<text {common} x="0" y="{hard}" fill="#0B0C10" stroke="#0B0C10" stroke-width="{stroke * 2}">{WORDS}</text>'
            f'<text {common} x="0" y="0" fill="{fill}" stroke="#0B0C10" stroke-width="{stroke * 2}">{WORDS}</text>')


def shoot(art_png, words, path):
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
           f'<image href="{Path(art_png).as_uri()}" x="0" y="0" width="{S}" height="{S}"/>{words}</svg>')
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{hl.css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body>{svg}</body></html>')
    sf.shoot(html, path, S, S, scale=P)


def sizes(big, out, key):
    made = {}
    for px in (512, 150, 100):
        dst = out / f"icon_{key}_{px}.png" if px != 512 else out / f"icon_{key}.png"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(big), "-vf", f"scale={px}:{px}:flags=lanczos", str(dst)],
                       check=True)
        made[px] = dst
    return made


# --- the three --------------------------------------------------------------------------------------------------------

def option_a(renders):
    """The strike: the fist at the lens, out of an ember burst behind it; speed radiating from it."""
    fig, m = place(renders, "s57_az30", 0.38, -65, -78)
    fist = m["fist"]
    img = slate()
    img = hl.over(img, burst((fist[0] + 30, fist[1] - 40), 340, deep_at=1.05))
    img = hl.over(img, hl.layer(hl.rgb("#FFE4C4"), radial_lines(fist, 70, 4, 150, alpha=0.32)))
    a = fig[..., 3]
    fig = grade(fig, contrast=1.2)
    fig = warm(fig, fist, 280, EMBER_HOT, 0.35)
    fig = hl.over(fig, rim(a, (-1.0, 0.3), EMBER_HOT, 8.0, 1.0))
    img = hl.over(img, ink_edge(a, 4.0))
    img = hl.over(img, fig)
    img = screen(img, flare(fist, 92, rays=12, seed=3, spin=0.3))
    img = screen(img, sparks(fist, 60, 230, 34, 9))
    img = vignette(img, 0.4)
    img = hl.over(img, blade(150, 540, 432, 496))
    words = words_svg(352, 479, 35, anchor="middle", skew=-14.6, track=1.0)
    return img, words


def option_b(renders):
    """The card: the HUD's ember card behind him, his reach across it, the slate blade under him with the words."""
    fig, m = place(renders, "r55_side", 0.413, -2, -37)
    fist = m["fist"]
    img = slate("#2C3139", "#121418")
    img = hl.over(img, card(150, 420, 40, 452))
    img = hl.over(img, hl.layer(hl.rgb("#FFE4C4"), radial_lines((fist[0] - 260, fist[1]), 40, 6, 200, width=(0.8, 2.2), alpha=0.22)
                                * hl.cov(-slant(150, 420, 40, 452))))
    a = fig[..., 3]
    fig = grade(fig, contrast=1.2)
    fig = warm(fig, fist, 240, EMBER_HOT, 0.55)
    fig = hl.over(fig, rim(a, (-1.0, -0.2), EMBER_HOT, 7.0, 1.0))
    img = hl.over(img, ink_edge(a, 4.0))
    img = hl.over(img, fig)
    img = screen(img, flare(fist, 56, rays=10, seed=5, spin=0.0))
    img = screen(img, sparks(fist, 46, 170, 26, 11))
    img = vignette(img, 0.35)
    img = hl.over(img, blade(-20, 470, 430, 494))
    words = words_svg(256, 476, 40, anchor="middle", skew=-14.6, track=1.6)
    return img, words


def option_c(renders):
    """The stare: in close, the fist cocked and burning by his face, its light raking him from the left."""
    fig, m = place(renders, "c52_hero", 0.48, -82, -142)
    fist = m["fist"]
    img = slate("#262B33", "#0F1114")
    side = np.clip(1 - hl.GX / 330, 0, 1) ** 1.6
    img = hl.over(img, hl.layer(hl.rgb(EMBER_DEEP), side * 0.85))
    img = hl.over(img, hl.layer(hl.rgb(EMBER_DEEP) * 0.7, hl.halftone(9.0, 3.6, side * 1.4 - 0.2) * 0.8))
    a = fig[..., 3]
    fig = grade(fig, contrast=1.2)
    fig = warm(fig, fist, 300, EMBER_HOT, 0.4)
    fig = hl.over(fig, rim(a, (-1.0, -0.2), EMBER_HOT, 8.0, 1.0))
    fig = hl.over(fig, rim(a, (1.0, -0.3), "#AFC3E0", 4.0, 0.45))     # a cool edge on the far side: the slate's sky
    img = hl.over(img, ink_edge(a, 4.0))
    img = hl.over(img, fig)
    img = screen(img, flare(fist, 64, rays=11, seed=8, spin=-0.4))
    img = screen(img, sparks(fist, 54, 200, 30, 13))
    img = vignette(img, 0.42)
    img = hl.over(img, blade(-20, 364, 436, 500, edge=EMBER))
    words = words_svg(178, 483, 35, anchor="middle", skew=-14.6, track=1.0)
    return img, words


OPTIONS = {"A": ("A, the strike", option_a), "B": ("B, the card", option_b), "C": ("C, the stare", option_c)}


def sheet(out, made):
    """The three side by side at 512, then at 150 and 100 on Roblox's dark and light pages."""
    def img(p, w):
        return f'<img src="{Path(p).as_uri()}" style="width:{w}px;height:{w}px;display:block;border-radius:{w * 0.08:.0f}px">'
    big = "".join(f'<td><div class="l">{OPTIONS[k][0]}</div>{img(made[k][512], 512)}</td>' for k in made)
    rows = []
    for bg, fg, name in (("#111216", "#E8E2D6", "dark"), ("#F2F4F5", "#1B1D1F", "light")):
        cells = "".join(f'<td style="padding:10px 14px">{img(made[k][150], 150)}<div class="t" style="color:{fg}">Grow your Anime</div></td>' for k in made)
        cells += "".join(f'<td style="padding:10px 14px">{img(made[k][100], 100)}</td>' for k in made)
        rows.append(f'<tr style="background:{bg}"><td class="side" style="color:{fg}">Roblox, {name}: 150 px and 100 px</td>{cells}</tr>')
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{hl.css()} body{{margin:0;background:#1A1C21;color:#E8E2D6;'
            f'font-family:Builder}} td{{padding:10px;vertical-align:top}} .l{{font-size:22px;margin:4px 0 8px}} h1{{font-size:28px;margin:18px 14px 4px}}'
            f' p{{margin:0 14px 10px;color:#B9B2A6;font-size:18px}} .t{{font-size:14px;margin-top:6px;font-family:Builder}} .side{{font-size:16px;width:130px}}</style></head><body>'
            f'<h1>AR70: the game page icon, three targets</h1><p>Rook mid-strike on his own Haymaker, the make’s model in the game’s light, finished in the HUD’s slate and ember. '
            f'At 512 px, then at Roblox’s 150 px and at 100 px. Shipped icons at the same sizes: not on hand yet (research asked the director).</p>'
            f'<table><tr>{big}</tr></table><table style="margin:8px 0 18px">{"".join(rows)}</table></body></html>')
    sf.shoot(html, out / "icon_sheet.png", 1640, 1150, scale=1)


def main(renders, out, keys):
    renders, out = Path(renders).resolve(), Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    work = out / "work"
    work.mkdir(exist_ok=True)
    made = {}
    for key in keys:
        art, words = OPTIONS[key][1](renders)
        art_png = work / f"{key}_art.png"
        hl.write_png(art_png, np.clip(art[..., :3], 0, 1))
        big = work / f"{key}_1024.png"
        shoot(art_png, words, big)
        made[key] = sizes(big, out, key)
        print(f"{key}: {made[key][512]}")
    if len(made) == len(OPTIONS):
        sheet(out, made)
        print(f"sheet: {out / 'icon_sheet.png'}")


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[0], a[1], a[2:] or list(OPTIONS))
