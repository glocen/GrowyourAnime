"""AR70, option (b): the game page's icon as our own make with an anime finish (docs/requests/AR70.md, research's
brief of 2026-11-27, 17:17). Kirra face first, rendered toon-lit and inked by tools/blender/ar70_painted.py, finished
here: painted energy round her, her lit eyes bloomed, and the game's logotype.

    py tools/ui/ar70_painted_targets.py <renders_dir> <out_dir> logo
    py tools/ui/ar70_painted_targets.py <renders_dir> <out_dir> [A B C]
    py tools/ui/ar70_painted_targets.py <renders_dir> <out_dir> sheets <shipped_icons_dir> <beside_out_dir>

`sheets` lays ours alone (<out_dir>/icon_sheet.png, for the handoff) and ours among the shipped icons at 150 and 512
(<beside_out_dir>, internal: keep it under build/reference/, never delivered or uploaded).

The logotype is drawn as SVG through headless Chrome: GROW YOUR over ANIME, its I a Void Shard standing in the word,
cracked and lit (the shard is the game: you break one and a Voidkin comes out). ANIME is Bangers (OFL), cut and
leaned, filled from white through the HUD's gold to its ember, extruded, inked and glowing; GROW YOUR is Sarpanch
(OFL). The shard's facets take the game's own shard pictures' look (build/handoff/UI/shards/).
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ar70_icon_targets as it  # noqa: E402  (sets the 512-point canvas at 2 px a point)
import hud_m_lead_targets as hl  # noqa: E402
import style_frames as sf  # noqa: E402

S, P = it.S, it.P
INK = "#0A0D1C"
GOLD_TOP, GOLD, EMBER_LO, DEPTH = "#FFFDF2", "#FFD45C", "#FF7A1F", "#5A1606"
SHARD_HI, SHARD, SHARD_LO = "#F3EDFF", "#A98BFF", "#5B3FD0"
CYAN, CYAN_HOT = "#38D9FF", "#D9FBFF"


# --- the logotype ---------------------------------------------------------------------------------------------------------

def fonts_css():
    faces = {"Bangers": "Bangers-Regular.ttf", "Sarpanch": "Sarpanch-Bold.ttf"}
    return "".join(f'@font-face{{font-family:"{f}";src:url("{(sf.FONTS / n).as_uri()}")}}' for f, n in faces.items())


def shard_glyph(h, w):
    """The Void Shard as the I: a tall crystal, its point up, cut in facets, a crack across its middle with light in it.
    Centred on x 0, its foot on y 0, `h` tall and `w` wide (points)."""
    t, m, b = -h, -h * 0.5, 0.0
    outline = [(0, t - h * 0.1), (w * 0.5, t + h * 0.18), (w * 0.44, b - h * 0.08), (0, b + h * 0.06),
               (-w * 0.5, b - h * 0.1), (-w * 0.46, t + h * 0.2)]
    pts = " ".join(f"{x:.1f},{y:.1f}" for x, y in outline)
    facets = [  # (polygon, fill): the lit face left, the shaded face right, a top bevel
        ([(0, t - h * 0.1), (-w * 0.46, t + h * 0.2), (-w * 0.5, b - h * 0.1), (-w * 0.08, m + h * 0.04)], SHARD_HI),
        ([(0, t - h * 0.1), (w * 0.5, t + h * 0.18), (w * 0.44, b - h * 0.08), (w * 0.06, m - h * 0.02)], SHARD_LO),
        ([(0, t - h * 0.1), (-w * 0.08, m + h * 0.04), (0, b + h * 0.06), (w * 0.06, m - h * 0.02)], SHARD),
        ([(-w * 0.08, m + h * 0.04), (-w * 0.5, b - h * 0.1), (0, b + h * 0.06)], "#7C5CF0"),
    ]
    out = [f'<polygon points="{pts}" fill="none" stroke="{INK}" stroke-width="{w * 0.36:.1f}" stroke-linejoin="round"/>']
    for poly, fill in facets:
        out.append(f'<polygon points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in poly)}" fill="{fill}"/>')
    # facet lines, white, as the shard pictures draw them
    for a, b_ in (((0, t - h * 0.1), (-w * 0.08, m + h * 0.04)), ((-w * 0.08, m + h * 0.04), (0, b + h * 0.06)),
                  ((0, t - h * 0.1), (w * 0.06, m - h * 0.02))):
        out.append(f'<line x1="{a[0]:.1f}" y1="{a[1]:.1f}" x2="{b_[0]:.1f}" y2="{b_[1]:.1f}" stroke="#FFFFFF" '
                   f'stroke-width="{w * 0.05:.1f}" stroke-opacity="0.85"/>')
    # the crack, lit: a jagged line across, its light spilling
    crack = [(-w * 0.52, m + h * 0.08), (-w * 0.18, m - h * 0.02), (w * 0.02, m + h * 0.1), (w * 0.24, m - h * 0.04), (w * 0.52, m + h * 0.02)]
    cp = " ".join(f"{x:.1f},{y:.1f}" for x, y in crack)
    out.append(f'<polyline points="{cp}" fill="none" stroke="{CYAN}" stroke-width="{w * 0.34:.1f}" stroke-opacity="0.55" '
               f'filter="url(#soft)" stroke-linejoin="round"/>')
    out.append(f'<polyline points="{cp}" fill="none" stroke="{CYAN_HOT}" stroke-width="{w * 0.1:.1f}" stroke-linejoin="miter"/>')
    out.append(f'<polygon points="{pts}" fill="none" stroke="#FFFFFF" stroke-width="{w * 0.04:.1f}" stroke-opacity="0.6"/>')
    return "".join(out)


def logo_svg(cx, base, size=1.0, lean=-9, grow=("Sarpanch", 30, 5, 0.8)):
    """The logotype, its ANIME's baseline at `base`, centred on `cx`, at `size` (1: ANIME 96 points tall). `grow` sets
    GROW YOUR: its face, its size and letter spacing at size 1, and its baseline above ANIME's, in ANIME's heights."""
    big = 104 * size
    gap = 17 * size                    # the shard's half-width with its air
    sh, sw = big * 0.86, 26 * size     # the shard's height and width
    defs = (f'<defs><linearGradient id="gold" x1="0" y1="{-big * 0.78:.1f}" x2="0" y2="0" gradientUnits="userSpaceOnUse">'
            f'<stop offset="0" stop-color="{GOLD_TOP}"/><stop offset="0.42" stop-color="{GOLD}"/>'
            f'<stop offset="1" stop-color="{EMBER_LO}"/></linearGradient>'
            f'<linearGradient id="white" x1="0" y1="{-big:.1f}" x2="0" y2="{-big * 0.7:.1f}" gradientUnits="userSpaceOnUse">'
            f'<stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#CFEFFF"/></linearGradient>'
            f'<filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{3 * size:.1f}"/></filter>'
            f'<filter id="glow" x="-30%" y="-60%" width="160%" height="220%"><feGaussianBlur stdDeviation="{7 * size:.1f}"/></filter></defs>')

    def word(fill, stroke=None, sw_=0, dy=0.0, extra=""):
        common = (f'font-family="Bangers" font-size="{big:.1f}" letter-spacing="{2 * size:.1f}" stroke-linejoin="round" '
                  f'paint-order="stroke" {extra}')
        st = f'stroke="{stroke}" stroke-width="{sw_:.1f}"' if stroke else ""
        return (f'<text x="{-gap:.1f}" y="{dy:.1f}" text-anchor="end" fill="{fill}" {st} {common}>AN</text>'
                f'<text x="{gap:.1f}" y="{dy:.1f}" text-anchor="start" fill="{fill}" {st} {common}>ME</text>')

    depth = "".join(word(DEPTH, DEPTH, 12 * size, dy=k * size) for k in range(1, 8))
    body = [
        word(CYAN, CYAN, 16 * size, extra='filter="url(#glow)" opacity="0.8"'),      # the glow behind
        word(INK, INK, 15 * size, dy=8 * size),                                         # the extrusion's ink foot
        depth,
        word(INK, INK, 12 * size),                                                      # the ink round the face
        word("url(#gold)", "#7A2A06", 2.2 * size),                                      # the face, gold to ember
        # a shine across the letters' upper third
        word("#FFFFFF", extra=f'opacity="0.55" clip-path="url(#shine)"'),
    ]
    shine = (f'<clipPath id="shine"><rect x="{-400 * size:.1f}" y="{-big * 0.74:.1f}" width="{800 * size:.1f}" '
             f'height="{big * 0.1:.1f}"/></clipPath>')
    shard = f'<g transform="translate(0 {2 * size:.1f})">{shard_glyph(sh, sw)}</g>'
    face, small, spacing, lift = grow[0], grow[1] * size, grow[2] * size, grow[3]
    grow = (f'<g transform="translate({-gap * 0.2:.1f} {-big * lift:.1f})">'
            f'<text x="0" y="0" text-anchor="middle" font-family="{face}" font-size="{small:.1f}" letter-spacing="{spacing:.1f}" '
            f'fill="{INK}" stroke="{INK}" stroke-width="{9 * size:.1f}" stroke-linejoin="round" dy="{3 * size:.1f}">GROW YOUR</text>'
            f'<text x="0" y="0" text-anchor="middle" font-family="{face}" font-size="{small:.1f}" letter-spacing="{spacing:.1f}" '
            f'fill="url(#white)" stroke="{INK}" stroke-width="{7 * size:.1f}" stroke-linejoin="round" paint-order="stroke">GROW YOUR</text></g>')
    return (f'{defs}<g transform="translate({cx:.1f} {base:.1f}) skewX({lean})"><defs>{shine}</defs>'
            f'{"".join(body)}{shard}{grow}</g>')


def shoot(art_png, overlay, path):
    bg = f'<image href="{Path(art_png).as_uri()}" x="0" y="0" width="{S}" height="{S}"/>' if art_png else ""
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">{bg}{overlay}</svg>'
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{fonts_css()} html,body{{margin:0;background:#141A2E}}'
            f' svg{{display:block}}</style></head><body>{svg}</body></html>')
    sf.shoot(html, path, S, S, scale=P)


# --- paint ---------------------------------------------------------------------------------------------------------------

def field(top, bot, glow_at, glow_r, glow):
    """The ground: `top` to `bot` down the frame, a light of `glow` round `glow_at`."""
    t = np.clip(hl.GY / S, 0, 1)[..., None]
    c = hl.rgb(top) * (1 - t) + hl.rgb(bot) * t
    d = np.hypot(hl.GX - glow_at[0], hl.GY - glow_at[1]) / glow_r
    c = c + hl.rgb(glow) * (np.exp(-d ** 2) * 0.9)[..., None]
    return np.dstack([hl.grain(np.clip(c, 0, 1), k=0.015, seed=3), np.ones(hl.GX.shape)])


def slash(centre, r, a0, a1, width, colour, hot, seed=1):
    """A crescent of light: an arc from a0 to a1 (degrees clockwise from the top), widest in its middle, tapered to
    points, a white-hot core in a coloured body and a glow; as light to screen on."""
    cx, cy = centre
    d = np.hypot(hl.GX - cx, hl.GY - cy)
    th = np.degrees(np.arctan2(hl.GX - cx, -(hl.GY - cy))) % 360
    span = (a1 - a0) % 360
    u = ((th - a0) % 360) / span
    inside = u <= 1
    w = width * np.sin(np.clip(u, 0, 1) * math.pi) ** 0.7
    off = d - r
    body = np.clip(1 - np.abs(off - w * 0.2) / np.maximum(w, 1e-3), 0, 1) * inside
    core = np.clip(1 - np.abs(off - w * 0.35) / np.maximum(w * 0.3, 1e-3), 0, 1) * inside
    glow = np.exp(-(off / (width * 1.6)) ** 2) * inside * np.sin(np.clip(u, 0, 1) * math.pi)
    return (hl.rgb(colour) * (body ** 0.8 * 0.9)[..., None] + hl.rgb(hot) * (core ** 1.4)[..., None]
            + hl.rgb(colour) * (glow * 0.35)[..., None])


def bloom(fig, pick, radius, k):
    """Light from the picked parts of the figure (a coverage), spread wide: their own colour, as light to screen on."""
    a = fig[..., 3:4]
    u = np.where(a > 1e-4, fig[..., :3] / np.maximum(a, 1e-4), 0) * (pick * fig[..., 3])[..., None]
    out = np.zeros_like(u)
    for r, w in ((radius * 0.25, 0.9), (radius * 0.6, 0.6), (radius, 0.45)):
        out += np.stack([ndimage.gaussian_filter(u[..., c], r * P) for c in range(3)], -1) * w
    return np.clip(out * k, 0, 1)


def lit_eyes(fig):
    """The glare's lit irises in the render: cyan, bright, saturated (never the silver hair or the white of the eye)."""
    a = fig[..., 3:4]
    u = np.where(a > 1e-4, fig[..., :3] / np.maximum(a, 1e-4), 0)
    return (np.clip((u[..., 2] - u[..., 0] - 0.25) * 4, 0, 1) * np.clip((u[..., 1] - 0.8) * 8, 0, 1)
            * np.clip((u[..., 2] - 0.88) * 10, 0, 1))


def speckle(n, seed, box, size, colour):
    """Small four-point glints scattered in `box` (x0, y0, x1, y1), as light."""
    rng = np.random.default_rng(seed)
    acc = np.zeros(hl.GX.shape)
    for _ in range(n):
        x, y = rng.uniform(box[0], box[2]), rng.uniform(box[1], box[3])
        s = rng.uniform(*size)
        dx, dy = np.abs(hl.GX - x), np.abs(hl.GY - y)
        star = np.clip(1 - (dx * dy) ** 0.5 / (s * 0.25), 0, 1) * np.exp(-((dx + dy) / s) ** 2)
        acc = np.maximum(acc, star * rng.uniform(0.5, 1.0))
    return acc[..., None] * hl.rgb(colour)


def aura(alpha, colour, hot, reach, seed, rise=70.0):
    """An anime aura: light licking up off the silhouette in streaks, hot at the edge, `colour` farther out, as light."""
    base = ndimage.gaussian_filter(alpha, 3 * P)
    smear = np.zeros_like(base)
    for k in range(10):
        smear = np.maximum(smear, hl.shift(base, 0, -rise * k / 10) * (1 - k / 10) ** 1.2)
    rng = np.random.default_rng(seed)
    noise = ndimage.gaussian_filter(rng.random(base.shape), (22 * P, 2.2 * P))
    noise = (noise - noise.min()) / (np.ptp(noise) + 1e-6)
    out = ndimage.distance_transform_edt(alpha < 0.5) / P
    near = np.exp(-out / (reach * 0.25))
    far = np.clip(smear * (0.35 + noise * 1.3), 0, 1) * np.exp(-out / reach)
    return np.clip(hl.rgb(hot) * (near * 0.7)[..., None] + hl.rgb(colour) * (far * 1.1)[..., None], 0, 1)


def shade_below(fig, y0, y1, k):
    """The body sunk in shadow under the face: the figure darkened from y0 to y1 by up to `k`."""
    f = 1 - np.clip((hl.GY - y0) / (y1 - y0), 0, 1) ** 1.2 * k
    return np.dstack([fig[..., :3] * f[..., None], fig[..., 3:4]])


def eye_trails(fig, length, width, colour, hot, bend=0.0):
    """A glint trailing off each lit eye, out from the face: a tapered streak, hot at the eye, as light."""
    pick = lit_eyes(fig) > 0.5
    lab, n = ndimage.label(pick)
    if n == 0:
        return np.zeros(hl.GX.shape + (3,))
    sizes = ndimage.sum(pick, lab, range(1, n + 1))
    eyes = [np.array(ndimage.center_of_mass(pick, lab, i + 1))[::-1] / P for i in np.argsort(sizes)[-2:]]
    mid = np.mean(eyes, axis=0)
    acc = np.zeros(hl.GX.shape)
    for e in eyes:
        way = np.sign(e[0] - mid[0]) or 1.0
        x0, y0 = e
        t = (hl.GX - x0) * way / length
        y_line = y0 - bend * np.clip(t, 0, 1) ** 2 * length
        on = (t >= -0.02) & (t <= 1)
        w = width * (1 - np.clip(t, 0, 1)) ** 0.8 + 0.3
        acc = np.maximum(acc, hl.cov(np.abs(hl.GY - y_line) - w) * on * (1 - np.clip(t, 0, 1)) ** 0.6)
    glow = ndimage.gaussian_filter(acc, 4 * P)
    return np.clip(hl.rgb(hot) * acc[..., None] + hl.rgb(colour) * (glow * 1.8)[..., None], 0, 1)


def shard_pieces(path, n, seed, placements, edge_col="#FFFFFF", lift=1.25):
    """A Void Shard picture cut into `n` cells, chosen cells set down where the picture wants them: each placement is
    (cell, (x, y) its centre in points, scale, turn in degrees). Each piece is made solid and its cut edge lit.
    Returns a premultiplied layer."""
    img = hl.read_png(path)
    h, w = img.shape[:2]
    rng = np.random.default_rng(seed)
    ys, xs = np.nonzero(img[..., 3] > 0.3)
    pick = rng.choice(len(xs), n, replace=False)
    seeds = np.stack([xs[pick], ys[pick]], 1).astype(float)
    yy, xx = np.mgrid[0:h, 0:w]
    lab = np.argmin(((xx[..., None] - seeds[:, 0]) ** 2 + (yy[..., None] - seeds[:, 1]) ** 2), axis=-1)
    colour = np.clip(img[..., :3] * lift, 0, 1)
    out = np.zeros(hl.GX.shape + (4,))
    for cell_i, (x, y), scale, turn in placements:
        cell = (lab == cell_i) & (img[..., 3] > 0.25)
        if cell.sum() < 50:
            continue
        cell = ndimage.binary_erosion(cell, iterations=2)
        cyx = np.array(ndimage.center_of_mass(cell))[::-1]
        gx, gy = hl.GX - x, hl.GY - y
        c, s_ = math.cos(math.radians(-turn)), math.sin(math.radians(-turn))
        sx, sy = (gx * c - gy * s_) / scale + cyx[0], (gx * s_ + gy * c) / scale + cyx[1]
        mask = np.clip(ndimage.map_coordinates(cell.astype(float), [sy, sx], order=1, cval=0), 0, 1)
        col = np.stack([ndimage.map_coordinates(colour[..., k], [sy, sx], order=1, cval=0) for k in range(3)], -1)
        inside = ndimage.distance_transform_edt(mask > 0.5) / P
        rim_ = np.clip(1 - inside / 2.2, 0, 1) * mask
        col = col * (1 - rim_[..., None]) + hl.rgb(edge_col) * rim_[..., None]
        piece = np.dstack([col * mask[..., None], mask * 0.96])
        out = hl.over(out, piece)
    return np.clip(out, 0, 1)


def lighten(img, light):
    return it.screen(img, light)


def finish_figure(fig, rim_dir, rim_col, rim_w=7.0, contrast=1.15, sat=1.25):
    a = fig[..., 3].copy()
    fig = it.grade(fig, contrast=contrast, sat=sat)
    fig = hl.over(fig, it.rim(a, rim_dir, rim_col, rim_w, 1.0))
    return fig, a


def cut(p, q, width, colour, hot):
    """A blade's cut: a straight stroke from p to q, a lens widest at its middle and pointed at both ends, a white-hot
    core in a coloured glow; as light to screen on."""
    p, q = np.asarray(p, float), np.asarray(q, float)
    v = q - p
    length = np.hypot(*v)
    u = v / length
    gx, gy = hl.GX - p[0], hl.GY - p[1]
    t = np.clip((gx * u[0] + gy * u[1]) / length, 0, 1)
    off = np.abs(gx * -u[1] + gy * u[0])
    w = width * np.sin(np.pi * t) ** 0.7 + 0.2
    core = hl.cov(off - w) * ((gx * u[0] + gy * u[1]) / length >= 0) * ((gx * u[0] + gy * u[1]) / length <= 1)
    glow = ndimage.gaussian_filter(core, 5 * P)
    return np.clip(hl.rgb(hot) * core[..., None] + hl.rgb(colour) * (glow * 1.8)[..., None], 0, 1)


# --- the targets ---------------------------------------------------------------------------------------------------------

def target_a(renders):
    """The glare: Kirra looking back over her shoulder, eyes lit, her blades' cuts crossing the night behind her."""
    fig, m = it.place(renders, "A_hi", 0.46, -76, -128)
    head = m["head"]
    img = field("#071026", "#0B1838", (head[0] + 70, head[1] - 40), 260, "#0B6E8E")
    light = slash((head[0] + 10, head[1] + 30), 205, 300, 160, 26, CYAN, "#FFFFFF")
    light += slash((head[0] + 30, head[1] + 10), 250, 320, 120, 12, "#2BA8FF", CYAN_HOT) * 0.8
    light += it.radial_lines(head, 60, 7, 190, alpha=0.35)[..., None] * hl.rgb(CYAN)
    for p, q, w in (((500, 10), (360, 170), 4.5), ((380, 0), (515, 135), 3.5), ((-10, 120), (110, 30), 3.5)):
        light += cut(p, q, w, CYAN, "#FFFFFF")                 # her two short blades' cuts, crossed
    light += speckle(26, 5, (0, 0, S, 380), (5, 12), CYAN_HOT)
    img = lighten(img, light)
    fig, a = finish_figure(fig, (1.0, -0.4), CYAN, rim_w=7.0)
    img = lighten(img, aura(a, CYAN, CYAN_HOT, 60, 3))
    fig = shade_below(fig, head[1] + 110, head[1] + 230, 0.7)
    img = hl.over(img, it.ink_edge(a, 3.2))
    img = hl.over(img, fig)
    img = lighten(img, bloom(fig, lit_eyes(fig), 16, 2.2))
    img = lighten(img, eye_trails(fig, 120, 2.4, CYAN, "#FFFFFF", bend=0.12))
    img = lighten(img, it.sparks(head, 170, 300, 20, 4, colour=CYAN_HOT, size=(4, 12), width=1.0))
    img = it.vignette(img, 0.4)
    return img, logo_svg(256, 494, 1.1)


def target_b(renders):
    """The reveal: a Void Shard breaks and Kirra is in its light, its pieces flying out round her."""
    fig, m = it.place(renders, "B_hi", 0.44, -85, -112)
    head = m["head"]
    burst_at = (head[0] + 4, head[1] - 30)
    img = field("#050E22", "#0A1634", burst_at, 300, "#1F5FB8")
    d = np.hypot(hl.GX - burst_at[0], hl.GY - burst_at[1])
    light = (hl.rgb("#FFFFFF") * np.exp(-(d / 70) ** 2)[..., None] * 0.9 + hl.rgb("#9FE9FF") * np.exp(-(d / 180) ** 2)[..., None] * 0.6
             + hl.rgb(SHARD) * np.exp(-(d / 120) ** 2)[..., None] * 0.25 + hl.rgb(CYAN) * np.exp(-(d / 300) ** 2)[..., None] * 0.3)
    light += it.radial_lines(burst_at, 90, 3, 60, width=(1.0, 4.0), alpha=0.55)[..., None] * hl.rgb("#E6FAFF")
    img = lighten(img, light)
    shard = Path(__file__).resolve().parents[2] / "build/handoff/UI/shards/shard_prismatic.png"
    back = shard_pieces(shard, 14, 21, [(0, (70, 92), 0.42, -30), (3, (450, 70), 0.4, 25), (6, (36, 246), 0.36, -60),
                                         (9, (482, 228), 0.38, 40), (11, (150, 22), 0.3, 10), (12, (372, 18), 0.28, -20)])
    back = ndimage.gaussian_filter(back, (0.6 * P, 0.6 * P, 0))
    img = hl.over(img, back)
    fig, a = finish_figure(fig, (0.0, -1.0), "#E6FAFF", rim_w=9.0)
    img = lighten(img, aura(a, CYAN, "#F2FCFF", 50, 5, rise=50))
    fig = shade_below(fig, head[1] + 100, head[1] + 220, 0.72)
    img = hl.over(img, it.ink_edge(a, 3.2))
    img = hl.over(img, fig)
    img = lighten(img, bloom(fig, lit_eyes(fig), 16, 2.2))
    img = lighten(img, eye_trails(fig, 90, 2.0, CYAN, "#FFFFFF", bend=0.1))
    front = shard_pieces(shard, 14, 21, [(2, (34, 400), 0.75, -38), (7, (486, 380), 0.7, 32)])
    glow = ndimage.gaussian_filter(front[..., 3], 10 * P)[..., None] * hl.rgb(SHARD) * 0.9
    img = lighten(img, glow)
    img = hl.over(img, front)
    img = lighten(img, speckle(40, 9, (0, 0, S, 400), (4, 11), CYAN_HOT) * (1 - a)[..., None])
    img = it.vignette(img, 0.42)
    return img, logo_svg(256, 494, 1.1)


def target_c(renders):
    """The hunt: Kirra face first at the left, a Red Shade looming behind her, its grin lit; cyan against red."""
    foe, _ = it.place(renders, "sh_hi", 0.27, 176, 14)
    fa = foe[..., 3]
    fu = np.where(fa[..., None] > 1e-4, foe[..., :3] / np.maximum(fa[..., None], 1e-4), 0)
    hot = np.clip((fu.mean(-1) - 0.86) * 9, 0, 1) * fa                       # its eyes and grin
    lum = np.clip(fu.mean(-1), 0, 1)[..., None] ** 1.6                      # a silhouette in its own red dusk,
    dark = hl.rgb("#10040A") * (1 - lum) + hl.rgb("#6A1A26") * lum          # only its eyes and grin lit
    fu = dark * (1 - hot[..., None]) + hl.rgb("#FFF1E6") * hot[..., None]
    foe = np.dstack([fu * fa[..., None], fa])
    foe = hl.over(foe, it.rim(fa, (-1.0, 0.2), "#FF4A3D", 8.0, 1.0))
    fig, m = it.place(renders, "C_hi", 0.4, -150, -46)
    head = m["head"]
    img = field("#14070D", "#0A0E22", (370, 150), 300, "#8A1020")
    light = slash((head[0] + 20, head[1] + 20), 215, 200, 20, 18, "#FF3B3B", "#FFD2C4", seed=2) * 0.9
    light += it.radial_lines((360, 130), 70, 6, 120, alpha=0.3)[..., None] * hl.rgb("#FF6A55")
    img = lighten(img, light)
    img = lighten(img, aura(fa, "#FF2F3A", "#FF9A80", 55, 9, rise=60) * 0.9)
    img = hl.over(img, it.ink_edge(fa, 2.6))
    img = hl.over(img, foe)
    img = lighten(img, bloom(foe, hot / np.maximum(fa, 1e-4) * (fa > 0.5), 14, 1.4) * np.array([1.0, 0.45, 0.38]))
    img = lighten(img, it.sparks((360, 150), 120, 300, 30, 12, colour="#FF8A66", size=(4, 12), width=1.0))
    fig, a = finish_figure(fig, (1.0, -0.3), "#FF6A55", rim_w=7.0)
    fig = hl.over(fig, it.rim(a, (-1.0, -0.5), CYAN, 6.0, 0.9))
    img = lighten(img, aura(a, CYAN, CYAN_HOT, 55, 3))
    fig = shade_below(fig, head[1] + 110, head[1] + 230, 0.7)
    img = hl.over(img, it.ink_edge(a, 3.2))
    img = hl.over(img, fig)
    img = lighten(img, bloom(fig, lit_eyes(fig), 16, 2.2))
    img = lighten(img, eye_trails(fig, 110, 2.4, CYAN, "#FFFFFF", bend=0.1))
    img = lighten(img, speckle(18, 4, (0, 0, 220, 360), (5, 11), CYAN_HOT) * (1 - a)[..., None])
    img = it.vignette(img, 0.42)
    return img, logo_svg(256, 494, 1.1)


TARGETS = {"A": ("A, the glare", target_a), "B": ("B, the reveal", target_b), "C": ("C, the hunt", target_c)}


def main(renders, out, keys):
    made = {}
    for key in keys:
        art, words = TARGETS[key][1](renders)
        flat = out / "work" / f"art_{key}.png"
        flat.parent.mkdir(parents=True, exist_ok=True)
        hl.write_png(flat, np.dstack([art[..., :3], np.ones(art.shape[:2])]))
        big = out / "work" / f"icon_{key}_1024.png"
        shoot(flat, words, big)
        made[key] = it.sizes(big, out, key)
        print(f"{key}: {made[key][512]}")
    return made


def tile(path, w, title, fg):
    return (f'<div class="tile" style="width:{w}px"><img src="{Path(path).as_uri()}" style="width:{w}px;height:{w}px;'
            f'display:block;border-radius:{w * 0.08:.0f}px"><div class="t" style="color:{fg};font-size:{max(13, w // 11)}px">{title}</div></div>')


def page(body, bg="#111216"):
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{hl.css()} body{{margin:0;background:{bg};font-family:Builder}}'
            f' .grid{{display:flex;flex-wrap:wrap;gap:18px 16px;padding:18px}} .t{{margin-top:6px;white-space:nowrap;overflow:hidden;'
            f'text-overflow:ellipsis}} h1{{font-size:26px;margin:16px 18px 0;color:#E8E2D6}}</style></head><body>{body}</body></html>')


def sheets(out, refs, beside_out):
    """Ours alone (for the handoff): the targets at 512, then at Roblox's 150 and 100 on its dark and light pages.
    Beside (internal, kept with the references): the targets set among the shipped icons, at 150 and at 512."""
    keys = [k for k in TARGETS if (out / f"icon_{k}.png").exists()]
    ours = {k: out / f"icon_{k}.png" for k in keys}
    big = "".join(tile(ours[k], 512, TARGETS[k][0], "#E8E2D6") for k in keys)
    rows = ""
    for bg, fg in (("#111216", "#E8E2D6"), ("#F2F4F5", "#1B1D1F")):
        cells = "".join(tile(out / f"icon_{k}_150.png", 150, "Grow your Anime", fg) for k in keys)
        cells += "".join(tile(out / f"icon_{k}_100.png", 100, "", fg) for k in keys)
        cells += "".join(tile(ours[k], 64, "", fg) for k in keys)
        rows += f'<div class="grid" style="background:{bg};align-items:flex-start">{cells}</div>'
    body = f'<h1>AR70 (b): the game page icon, {len(keys)} targets, at 512, then 150, 100 and 64</h1><div class="grid">{big}</div>{rows}'
    sf.shoot(page(body, "#1A1C21"), out / "icon_sheet.png", 1640, 1060, scale=1)
    shipped = sorted(f for f in refs.glob("*.png") if not f.name.startswith("_"))
    order = [(f, f.stem.replace("_", " ").title()) for f in shipped]
    for i, k in zip((3, 10, 17), keys):
        order.insert(i, (ours[k], f"Grow your Anime {k}"))
    beside_out.mkdir(parents=True, exist_ok=True)
    for w, cols, width in ((150, 7, 1300), (512, 7, 3740)):
        body = (f'<h1>AR70 (b) among the shipped icons at {w} px: ours are "Grow your Anime A, B, C"</h1>'
                f'<div class="grid" style="width:{cols * (w + 16)}px">'
                + "".join(tile(f, w, t, "#E8E2D6") for f, t in order) + "</div>")
        rows_n = -(-len(order) // cols)
        height = 70 + rows_n * (w + w // 11 + 34)
        sf.shoot(page(body), beside_out / f"beside_{w}.png", width, height, scale=1)
        print(beside_out / f"beside_{w}.png")
    print(out / "icon_sheet.png")


if __name__ == "__main__":
    renders, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    keys = sys.argv[3:] or ["A", "B"]
    if keys[:1] == ["sheets"]:
        sheets(out, Path(keys[1]).resolve(), Path(keys[2]).resolve())
    elif keys == ["logo"]:
        shoot(None, logo_svg(256, 300, 1.0), out / "logo_test.png")
        print(out / "logo_test.png")
    else:
        main(renders, out, keys)
