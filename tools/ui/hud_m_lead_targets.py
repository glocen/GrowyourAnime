"""AR68 M: the top-left overhaul's targets (the director, 2026-11-27, after 14:08: "the top left hud need a overhaul").

Three compositions of the lead's plate, each painted as image art at 4 px a point (lit surfaces from signed distance
fields, a texture, an ink edge, a cast shadow; Rook's own portrait graded in 2D) and laid over Faber's capture with the
plate's words as live type would draw them (Montserrat, a fill, an outer stroke, a hard shadow):

  A, the blade:     a slanted slate blade; Rook's bust breaks out of its top through an ember window; the bars ride the
                    blade.
  B, the medallion: Rook in a round mount whose rim is his health; the name on a swept ribbon beside it.
  C, bare:          no plate; the bust cut out over one ember slash, the name large on the world, a chunky bar.

  py tools/ui/hud_m_lead_targets.py <out> day=build/captures/ar68/m/m_day_fight.png dusk=build/captures/ar68/m/m_dusk_awake.png

Writes, for each light, <out>/<light>/<A|B|C>_phone.png (the whole frame at the capture's size), <A|B|C>_zoom.png (the
top-left at 4 px a point) and today_zoom.png; then <out>/lead_sheet.png. The old plate's area is filled by normalised
convolution, and the sheet says so. A, picked, is drawn from the game's layers that tools/ui/hud_m_lead_export.py cuts."""
import math
import struct
import subprocess
import sys
import zlib
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_frames as sf  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
BUST = REPO / "build/handoff/Rook/make/portraits/PortraitRook.png"
PPP = 4                                  # pixels a point
W, H = 568, 320                          # the frame in points (the capture is 1.5x)
CX0, CY0, CW, CH = 0, 40, 236, 104       # the painted canvas, in the frame's points
INK = np.array([11, 12, 16]) / 255
SLATE_TOP, SLATE_BOT = "#343A44", "#15181D"
EMBER, EMBER_HOT, EMBER_DEEP = "#E8622A", "#FFB070", "#7A2112"
RED_TOP, RED_MID, RED_BOT, RED_LIT = "#FF6B6B", "#E3283F", "#97122C", "#FFD3CC"
LAG = "#FFE4C4"
XP, XP_LIT = "#F2C35A", "#FFE7A6"
CREAM = "#F2EADB"
HP, HP_MAX, HP_SHARE, LAG_SHARE = "2,518", "4,061", 0.62, 0.69
LEVEL, NAME = "27", "ROOK"
FONT_DIR = sf.FONTS
FACES = {"MontBlack": "Montserrat-Black.ttf", "MontBold": "Montserrat-Bold.ttf", "Builder": "BuilderSans-Bold.otf"}

# the painted canvas's grid, in the frame's points (pixel centres)
GX, GY = np.meshgrid(CX0 + (np.arange(CW * PPP) + 0.5) / PPP, CY0 + (np.arange(CH * PPP) + 0.5) / PPP)


def set_grid(x0, y0, w, h):
    """Paint on another canvas of the frame's points (whole points): every shape and texture follows."""
    global CX0, CY0, CW, CH, GX, GY
    CX0, CY0, CW, CH = x0, y0, w, h
    GX, GY = np.meshgrid(CX0 + (np.arange(CW * PPP) + 0.5) / PPP, CY0 + (np.arange(CH * PPP) + 0.5) / PPP)


def rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)]) / 255


def cov(sd, soft=0.0):
    """Coverage from a signed distance in points (negative inside), antialiased over one pixel, or softened."""
    w = 1 / PPP + soft
    return np.clip(0.5 - sd / w, 0, 1)


def convex(pts):
    """The signed distance to a convex polygon, in points."""
    p = np.array(pts, float)
    area = sum(p[i, 0] * p[(i + 1) % len(p), 1] - p[(i + 1) % len(p), 0] * p[i, 1] for i in range(len(p)))
    s = 1 if area > 0 else -1
    d = None
    for i in range(len(p)):
        a, b = p[i], p[(i + 1) % len(p)]
        e = b - a
        n = np.array([e[1], -e[0]]) * s / np.hypot(*e)
        di = (GX - a[0]) * n[0] + (GY - a[1]) * n[1]
        d = di if d is None else np.maximum(d, di)
    return d


def circle(cx, cy, r):
    return np.hypot(GX - cx, GY - cy) - r


def arc(cx, cy, r, w, a0, a1):
    """A ring's arc, angles in degrees clockwise from the top, a0 < a1."""
    d = np.abs(np.hypot(GX - cx, GY - cy) - r) - w / 2
    th = np.degrees(np.arctan2(GX - cx, -(GY - cy))) % 360
    mid, half = (a0 + a1) / 2, (a1 - a0) / 2
    off = (np.abs((th - mid + 180) % 360 - 180) - half) * math.pi / 180 * r
    return np.maximum(d, off)


def layer(col, a):
    """A premultiplied RGBA layer from a colour (3,) or field (H, W, 3) and a coverage."""
    c = np.broadcast_to(col, a.shape + (3,)) if np.ndim(col) == 1 else col
    return np.dstack([c * a[..., None], a])


def over(dst, src):
    return src + dst * (1 - src[..., 3:4])


def blur(a, pts):
    return ndimage.gaussian_filter(a, pts * PPP)


def shift(a, dx, dy):
    return ndimage.shift(a, (dy * PPP, dx * PPP), order=1, mode="constant")


def vgrad(sd, top, bot, y0=None, y1=None):
    """A vertical gradient over the shape's own height."""
    rows = np.nonzero((sd < 0).any(axis=1))[0]
    ya = CY0 + rows.min() / PPP if y0 is None else y0
    yb = CY0 + rows.max() / PPP if y1 is None else y1
    t = np.clip((GY - ya) / max(yb - ya, 1e-3), 0, 1)[..., None]
    return rgb(top) * (1 - t) + rgb(bot) * t


def lacquer(base, sd, rim="#FFFFFF", rim_k=0.55, shade_k=0.45, band=1.6, light=(0.35, -1.0)):
    """Lights a shape's colour field from its own edge: the face toward the light brightens toward `rim`, the far edge
    darkens, within `band` points of the edge."""
    a = cov(sd)
    b = blur(a, 0.9)
    gy, gx = np.gradient(b)
    n = np.hypot(gx, gy) + 1e-6
    lx, ly = light
    ln = math.hypot(lx, ly)
    dot = (-(gx / n) * lx - (gy / n) * ly) / ln          # the outward normal toward the light
    edge = np.clip(1 + sd / band, 0, 1) ** 1.6           # 1 at the edge, 0 a band inside
    up = np.clip(dot, 0, 1) * edge * rim_k
    down = np.clip(-dot, 0, 1) * edge * shade_k
    c = base * (1 - up[..., None]) + rgb(rim) * up[..., None]
    return c * (1 - down[..., None])


def grain(c, k=0.025, seed=3):
    r = np.random.default_rng(seed).normal(0, 1, c.shape[:2])
    return np.clip(c + (blur(r, 0.12) * k)[..., None], 0, 1)


def halftone(pitch, rmax, field, angle=45):
    """Dots on a turned grid, each dot's radius rmax * field (0..1) at its place."""
    t = math.radians(angle)
    u = (GX * math.cos(t) + GY * math.sin(t)) / pitch
    v = (-GX * math.sin(t) + GY * math.cos(t)) / pitch
    d = np.hypot(u - np.round(u), v - np.round(v)) * pitch
    return cov(d - rmax * np.clip(field, 0, 1))


def speedlines(sd_clip, n, seed, ang=-14, width=(0.25, 0.7), alpha=0.35):
    """Thin streaks along a direction inside a clip, tapering at both ends."""
    rng = np.random.default_rng(seed)
    t = math.radians(ang)
    u = GX * math.cos(t) + GY * math.sin(t)
    v = -GX * math.sin(t) + GY * math.cos(t)
    vs = v[cov(sd_clip) > 0.5]
    us = u[cov(sd_clip) > 0.5]
    acc = np.zeros(GX.shape)
    for _ in range(n):
        v0 = rng.uniform(vs.min(), vs.max())
        u0 = rng.uniform(us.min(), us.max())
        ln = rng.uniform(10, 30)
        w = rng.uniform(*width)
        s = np.clip(1 - np.abs(u - u0) / ln, 0, 1)
        acc = np.maximum(acc, cov(np.abs(v - v0) - w * s) * s * rng.uniform(0.5, 1))
    return acc * cov(sd_clip) * alpha


def read_png(path):
    p = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0", str(path)],
                       capture_output=True, text=True, check=True).stdout.strip().split(",")
    w, h = int(p[0]), int(p[1])
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgba", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(h, w, 4).astype(float) / 255


def write_png(path, img):
    a = (np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w, c = a.shape
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))

    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6 if c == 4 else 2, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))


def unpremul(img):
    a = img[..., 3:4]
    return np.dstack([np.where(a > 1e-4, img[..., :3] / np.maximum(a, 1e-4), 0), a])


# Rook's bust: the portrait (4 px a point at its own scale), placed by the head's height and the face's centre.
HAIR_TOP, CHIN, FACE_X = 287, 500, 362


def bust(head_pts, face_x, hair_y, rim_k=0.9, key=True, tilt=0.0, portrait=BUST, marks=(HAIR_TOP, CHIN, FACE_X)):
    """A portrait (Rook's unless named) placed by the head's height, the face's centre and the hair's top, turned
    `tilt` degrees (clockwise) about the face; a warm key from the upper right, the far side cooler, an ember rim toward
    the light. `marks`: the portrait's hair top and chin rows and the face's centre column, in its pixels."""
    HAIR_TOP, CHIN, FACE_X = marks
    src = read_png(portrait)
    pm = src.copy()
    pm[..., :3] *= pm[..., 3:4]
    s = head_pts * PPP / (CHIN - HAIR_TOP)              # canvas pixels a source pixel
    pm = np.stack([ndimage.gaussian_filter(pm[..., i], max(0.0, 0.5 / s - 0.5)) for i in range(4)], -1)
    t = math.radians(tilt)
    py = hair_y + head_pts * 0.5                         # the pivot: mid head
    dx, dy = GX - face_x, GY - py
    ux = dx * math.cos(t) + dy * math.sin(t)             # undo the turn
    uy = -dx * math.sin(t) + dy * math.cos(t)
    sx = FACE_X + ux * PPP / s
    sy = HAIR_TOP + (CHIN - HAIR_TOP) * 0.5 + uy * PPP / s
    out = np.stack([ndimage.map_coordinates(pm[..., i], [sy, sx], order=1, mode="constant") for i in range(4)], -1)
    a = out[..., 3]
    if key:
        k = np.clip(((GX - face_x) * 0.6 - (GY - py)) / (head_pts * 1.2) + 0.5, 0, 1)[..., None]
        out[..., :3] = np.clip(out[..., :3] * (0.82 + 0.26 * k) * (np.array([1.0, 0.97, 0.94]) * k
                                                                    + np.array([0.9, 0.94, 1.04]) * (1 - k)), 0, None)
    lit = shift(a, -1.3, 0.9)                            # the alpha seen from the light (upper right)
    rim = blur(np.clip(a - lit, 0, 1), 0.25) * rim_k
    return over(out, layer(rgb(EMBER_HOT), np.clip(rim, 0, 1) * a))


def name_w(size, track):
    """ROOK's width in Montserrat Black, in points (measured from the first render)."""
    return 3.26 * size + 3 * track


def ink_of(a, pts):
    """An ink edge round an alpha: the alpha grown by `pts`."""
    r = int(round(pts * PPP))
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    fp = (xx ** 2 + yy ** 2) <= r * r
    return np.clip(blur(ndimage.maximum_filter(a, footprint=fp), 0.12), 0, 1)


def shadow(a, dy=1.4, soft=1.4, k=0.55):
    return layer(np.zeros(3), np.clip(shift(blur(a, soft), 0, dy) * k, 0, 1))


def bar_fill(sd_trough, x0, x1, share, lag):
    """The health's fill in a trough: red lit from the top, a gloss line, the lag chip, a bright leading edge."""
    xs, xl = x0 + (x1 - x0) * share, x0 + (x1 - x0) * lag
    inner = sd_trough + 0.0
    body = np.maximum(inner, GX - xs)
    chip = np.maximum(np.maximum(inner, GX - xl), xs - GX)
    out = layer(vgrad(inner, RED_TOP, RED_BOT), cov(body))
    rows = np.nonzero((inner < 0).any(axis=1))[0]
    ytop = CY0 + rows.min() / PPP
    gloss = cov(np.abs(GY - (ytop + 1.6)) - 0.35) * cov(body + 0.8) * 0.55
    out = over(out, layer(rgb(RED_LIT), gloss))
    hatch = cov(np.abs(((GX + GY * 0.58) / 3.2) % 1 - 0.5) * 3.2 - 0.45)   # a fine grain across the fill, leaning
    out = over(out, layer(rgb("#FF9A9A"), hatch * cov(body) * 0.16))
    out = over(out, layer(rgb(LAG), cov(chip) * 0.92))
    edge = cov(np.abs(GX - xs + 0.4) - 0.4) * cov(inner)
    out = over(out, layer(rgb("#FFF4EC"), edge * 0.9))
    return out


def xp_fill(sd, x0, x1, share=0.42):
    body = np.maximum(sd, GX - (x0 + (x1 - x0) * share))
    return layer(vgrad(sd, XP_LIT, XP), cov(body))


def trough(sd):
    """A dark well, its top edge in shadow."""
    c = vgrad(sd, "#07080A", "#1A1E25")
    return layer(c, cov(sd))


def gem(cx, cy, r, col):
    sd = circle(cx, cy, r)
    out = layer(INK, cov(sd - 0.9))
    c = lacquer(vgrad(sd, "#FF8A80", col), sd, rim="#FFFFFF", rim_k=0.7, band=r)
    out = over(out, layer(c, cov(sd)))
    return over(out, layer(np.ones(3), cov(circle(cx - r * 0.3, cy - r * 0.35, r * 0.28)) * 0.85))


def mark(cx, cy, r):
    sd = circle(cx, cy, r)
    out = layer(INK, cov(sd - 0.8))
    out = over(out, layer(lacquer(vgrad(sd, "#3A404B", "#1B1F26"), sd, band=r * 0.6), cov(sd)))
    t = math.radians(-45)
    u = (GX - cx) * math.cos(t) + (GY - cy) * math.sin(t)
    v = -(GX - cx) * math.sin(t) + (GY - cy) * math.cos(t)
    blade = np.maximum(np.abs(v) - 0.55 * np.clip(1 - np.abs(u) / (r * 0.75), 0.2, 1), np.abs(u) - r * 0.72)
    return over(out, layer(rgb(CREAM), cov(blade)))


# ---------------------------------------------------------------------------------------------------------------- A
# The card and the blade (research's pick, 2026-11-27, 14:29), drawn as the game's layers so the export
# (tools/ui/hud_m_lead_export.py) cuts the same pixels: the plate under the bust, the bust, the health's fill and lag
# chip (whole, revealed to their shares), its leading edge, the experience, the level's tab, the marks, the words.
A_K, A_YB = 0.26, 115.0                 # the slant (points across a point down) and the shared foot
A_HP = (66, 182, 98.0, 110.0)           # the health's trough: x0, x1 at its foot before the slant, its top, its foot
A_XP = (111.6, 113.2)                   # the experience's trough, top and foot
A_NAME = dict(x=70, y=95.2, size=16.5, track=1.2)
A_BUST = dict(head=44, face_x=34, hair_y=56, tilt=5)


def a_sl(x, y):
    """A point on A's slant: `x` at the foot, leaning right as it rises."""
    return (x + (A_YB - y) * A_K, y)


def a_shapes():
    sl = a_sl
    hx0, hx1, hy0, hy1 = A_HP
    xy0, xy1 = A_XP
    return dict(
        card=convex([sl(2, A_YB), sl(2, 67), sl(62, 67), sl(62, A_YB)]),
        blade=convex([sl(50, A_YB), sl(50, 81), sl(186, 81), sl(186, A_YB)]),
        hp=convex([sl(hx0, hy1), sl(hx0, hy0), sl(hx1, hy0), sl(hx1, hy1)]),
        xp=convex([sl(hx0 - 1, xy1), sl(hx0 - 1, xy0), sl(hx1 - 1, xy0), sl(hx1 - 1, xy1)]),
        lv=convex([sl(0.5, 122), sl(0.5, 108), sl(25, 108), sl(25, 122)]),
        hold=convex([sl(1.2, A_YB), sl(1.2, 30), sl(62.8, 30), sl(62.8, A_YB)]))


def a_hp_span():
    """The health's reveal runs from the trough's lowest left to its highest right: none shows none, all shows all."""
    hx0, hx1, hy0, hy1 = A_HP
    return a_sl(hx0, hy1)[0], a_sl(hx1, hy0)[0]


def a_plate():
    """Everything under the bust: the card and the blade, their shadow and ink, the bars' troughs."""
    sh = a_shapes()
    card_sd, blade = sh["card"], sh["blade"]
    info = np.maximum(blade, -card_sd)
    img = np.zeros(GX.shape + (4,))
    img = over(img, shadow(np.maximum(cov(blade), cov(card_sd)), 1.8, 1.6, 0.6))
    img = over(img, layer(INK, cov(np.minimum(blade, card_sd) - 1.3)))
    # the blade: slate lacquer, a fine ember halftone fading right, a hot hairline along its top
    c = grain(lacquer(vgrad(blade, SLATE_TOP, SLATE_BOT), blade, rim="#C9CED8", rim_k=0.5, band=1.4))
    img = over(img, layer(c, cov(info)))
    fade = np.clip(1 - (GX - 66) / 70, 0, 1) * np.clip((GY - 81) / 34, 0, 1)
    img = over(img, layer(rgb(EMBER), halftone(1.9, 0.62, fade) * cov(info) * 0.4))
    top = np.maximum(info, np.abs(GY - 81.5) - 0.45)
    img = over(img, layer(rgb("#FFD7B5"), cov(top) * np.clip(1 - (GX - 60) / 140, 0.2, 1)))
    # the card: the ember aura, hottest behind the head, deep at the foot; halftone and rising streaks
    r = np.hypot((GX - 36) * 0.9, GY - 78) / 42
    aura = (rgb("#FFC27A") * np.clip(1 - r * 1.7, 0, 1)[..., None] ** 1.1
            + rgb(EMBER) * np.clip(1 - np.abs(r * 1.7 - 0.85), 0, 1)[..., None]
            + rgb(EMBER_DEEP) * np.clip(r * 1.7 - 0.7, 0, 1)[..., None])
    aura = lacquer(np.clip(aura, 0, 1), card_sd, rim="#FFE6C8", rim_k=0.6, band=1.4)
    img = over(img, layer(grain(aura, 0.03), cov(card_sd)))
    img = over(img, layer(rgb(EMBER_DEEP) * 0.55, halftone(1.6, 0.62, r * 1.5 - 0.35) * cov(card_sd) * 0.65))
    img = over(img, layer(rgb("#FFF1DC"), speedlines(card_sd, 20, 5, ang=-75, alpha=0.5)))
    # the card's hot edge where the blade leaves it
    div = np.maximum(np.maximum(blade, card_sd - 0.0), np.abs(GX - (62 + (A_YB - GY) * A_K)) - 0.9)
    img = over(img, layer(rgb(EMBER_HOT), cov(div)))
    # the troughs: the health's well with its ink, the experience's
    img = over(img, layer(INK, cov(sh["hp"] - 1.0)))
    img = over(img, trough(sh["hp"]))
    return over(img, layer(rgb("#07080A"), cov(sh["xp"])))


def a_bust(portrait=BUST, marks=(HAIR_TOP, CHIN, FACE_X)):
    """A lead's bust: turned into the strike, held by the card's sides and foot, the hair free above the card's top;
    an ink edge round it inside the hold."""
    b = bust(A_BUST["head"], A_BUST["face_x"], A_BUST["hair_y"], tilt=A_BUST["tilt"], portrait=portrait, marks=marks)
    hold = cov(np.maximum(a_shapes()["hold"], GY - A_YB + 0.2))
    b = b * hold[..., None]
    return over(layer(INK, np.clip(ink_of(b[..., 3], 1.1) * hold - b[..., 3], 0, 1)), b)


def a_health():
    """The health's fill, whole: red lit from the top, a gloss line, a fine leaning grain."""
    hp = a_shapes()["hp"]
    out = layer(vgrad(hp, RED_TOP, RED_BOT), cov(hp))
    rows = np.nonzero((hp < 0).any(axis=1))[0]
    ytop = CY0 + rows.min() / PPP
    out = over(out, layer(rgb(RED_LIT), cov(np.abs(GY - (ytop + 1.6)) - 0.35) * cov(hp + 0.8) * 0.55))
    hatch = cov(np.abs(((GX + GY * 0.58) / 3.2) % 1 - 0.5) * 3.2 - 0.45)
    return over(out, layer(rgb("#FF9A9A"), hatch * cov(hp) * 0.16))


def a_lag():
    """The last hit's chip, whole: cream in the trough."""
    return layer(rgb(LAG), cov(a_shapes()["hp"]) * 0.92)


def reveal(img, x):
    """An image shown left of `x` only (a clipping frame's right edge)."""
    return img * cov(GX - x)[..., None]


def a_edge(x):
    """The fill's leading edge: a light line 0.8 wide at the reveal's end."""
    return layer(rgb("#FFF4EC"), cov(np.abs(GX - x + 0.4) - 0.4) * cov(a_shapes()["hp"]) * 0.9)


def a_xp(share=0.42):
    return xp_fill(a_shapes()["xp"], A_HP[0], A_HP[1], share)


def a_tab():
    """The level's slate tab on the card's foot, its shadow and ink."""
    lv = a_shapes()["lv"]
    img = shadow(cov(lv), 1.2, 1.0, 0.5)
    img = over(img, layer(INK, cov(lv - 1.1)))
    return over(img, layer(grain(lacquer(vgrad(lv, "#3A404B", "#15181D"), lv, rim="#D9DEE6", rim_k=0.6, band=1.4)),
                           cov(lv)))


def a_marks(name_width):
    """The type's gem and the class's mark after the name (the target's own drawing of the kit's two icons)."""
    gx = A_NAME["x"] + name_width + 6
    return over(gem(gx, 89.6, 4.0, "#E3283F"), mark(gx + 11, 89.6, 4.3))


def a_texts(name=NAME, hp=HP, most=HP_MAX, level=LEVEL, name_size=None):
    hx0, hx1 = A_HP[:2]
    return [
        dict(t=name, x=A_NAME["x"], y=A_NAME["y"], size=name_size or A_NAME["size"], face="MontBlack", fill=CREAM,
             stroke=1.3, track=A_NAME["track"]),
        dict(t=f"{hp}  /  {most}", x=(hx0 + hx1) / 2 + (A_YB - 104) * A_K, y=107.6, size=9.4, face="MontBlack",
             fill="#FFFFFF", stroke=1.2, anchor="middle", track=0.3),
        dict(t=level, x=14.5, y=119.0, size=11.5, face="MontBlack", fill="#FFFFFF", stroke=1.2, anchor="middle"),
    ]


def option_a(share=HP_SHARE, lag=LAG_SHARE):
    """The card and the blade: a tall ember card holds the bust, his hair breaking its top; a slate blade carries the
    name and the bars from the card's side. Composed from the game's layers."""
    x0, x1 = a_hp_span()
    xs, xl = x0 + (x1 - x0) * share, x0 + (x1 - x0) * max(lag, share)
    img = over(a_plate(), a_bust())
    img = over(img, reveal(a_lag(), xl))
    img = over(img, reveal(a_health(), xs))
    if 0 < share < 0.99:
        img = over(img, a_edge(xs))
    img = over(img, a_xp())
    img = over(img, a_tab())
    img = over(img, a_marks(name_w(A_NAME["size"], A_NAME["track"])))
    return img, a_texts()


# ---------------------------------------------------------------------------------------------------------------- B
def option_b():
    """The medallion: a round mount, its rim the health; the name on a swept ribbon."""
    cx, cy = 37.0, 93.0
    img = np.zeros(GX.shape + (4,))
    # the ribbon first, tucked under the medallion: tapered, a swallowtail at its end
    rb = convex([(40, 72), (172, 72), (166, 94), (40, 94)])
    tail = np.maximum(convex([(162, 72), (182, 72), (182, 94), (162, 94)]), -convex([(182, 69), (170, 83), (182, 97)]))
    ribbon = np.minimum(rb, np.maximum(tail, GX - 182))
    img = over(img, shadow(cov(ribbon), 1.6, 1.4, 0.55))
    img = over(img, layer(INK, cov(ribbon - 1.2)))
    c = grain(lacquer(vgrad(ribbon, SLATE_TOP, SLATE_BOT), ribbon, rim="#C9CED8", rim_k=0.5, band=1.4))
    img = over(img, layer(c, cov(ribbon)))
    img = over(img, layer(rgb(EMBER), halftone(1.9, 0.62, np.clip(1 - (GX - 64) / 90, 0, 1)) * cov(ribbon) * 0.38))
    # the experience along the ribbon's foot
    xpt = np.maximum(ribbon, np.abs(GY - 92.2) - 0.95)
    img = over(img, layer(rgb("#07080A"), cov(xpt)))
    img = over(img, xp_fill(np.maximum(xpt, GX - 168), 62, 168))
    top = np.maximum(ribbon, np.abs(GY - 72.6) - 0.45)
    img = over(img, layer(rgb("#FFD7B5"), cov(top) * np.clip(1 - (GX - 64) / 140, 0.2, 1)))
    # the medallion
    outer = circle(cx, cy, 31.5)
    img = over(img, shadow(cov(outer), 1.8, 1.8, 0.6))
    img = over(img, layer(INK, cov(outer - 1.3)))
    img = over(img, layer(grain(lacquer(vgrad(outer, "#3E444F", "#121418"), outer, rim="#D7DCE4", rim_k=0.6, band=1.8)), cov(outer)))
    a0, a1 = 205.0, 515.0                                # the health's sweep, the gap at the foot for the level
    ring = arc(cx, cy, 27.4, 6.0, a0, a1)
    img = over(img, layer(vgrad(ring, "#2A0E14", "#120609"), cov(ring)))
    fill = arc(cx, cy, 27.4, 6.0, a0, a0 + (a1 - a0) * HP_SHARE)
    lagr = arc(cx, cy, 27.4, 6.0, a0 + (a1 - a0) * HP_SHARE, a0 + (a1 - a0) * LAG_SHARE)
    rr = np.hypot(GX - cx, GY - cy)
    t = np.clip((rr - 24.4) / 6.0, 0, 1)[..., None]
    red = rgb(RED_TOP) * (1 - t) + rgb(RED_BOT) * t
    img = over(img, layer(red, cov(fill)))
    img = over(img, layer(rgb(RED_LIT), cov(np.maximum(fill, np.abs(rr - 29.0) - 0.35)) * 0.5))
    img = over(img, layer(rgb(LAG), cov(lagr) * 0.92))
    face = circle(cx, cy, 24.2)
    img = over(img, layer(INK, cov(face - 0.9)))
    r = np.hypot(GX - cx, GY - (cy - 4)) / 26
    aura = rgb(EMBER_HOT) * np.clip(1 - r * 1.3, 0, 1)[..., None] + rgb(EMBER) * np.clip(1 - np.abs(r * 1.3 - 0.75), 0, 1)[..., None] \
        + rgb(EMBER_DEEP) * np.clip(r * 1.5 - 0.7, 0, 1)[..., None]
    img = over(img, layer(np.clip(aura, 0, 1), cov(face)))
    img = over(img, layer(rgb(EMBER_DEEP) * 0.6, halftone(1.6, 0.6, r * 1.4 - 0.35) * cov(face) * 0.6))
    img = over(img, layer(rgb("#FFF1DC"), speedlines(face, 18, 9, ang=-75, alpha=0.45)))
    # the bust: inside the face, the hair over the ring at the top
    b = bust(41, cx + 0.5, 57.5)
    head = cov(GY - 86) * cov(circle(cx, cy - 6, 30))
    clip = np.maximum(cov(face), head)
    b = b * clip[..., None]
    img = over(img, layer(INK, np.clip(ink_of(b[..., 3], 1.0) * (1 - cov(face + 0.5)) - b[..., 3], 0, 1)))
    img = over(img, b)
    # the level: a hot pill in the ring's gap
    pill = np.minimum(np.minimum(circle(30.5, 123.5, 5.5), circle(43.5, 123.5, 5.5)), convex([(30.5, 118), (43.5, 118), (43.5, 129), (30.5, 129)]))
    img = over(img, shadow(cov(pill), 1.0, 1.0, 0.5))
    img = over(img, layer(INK, cov(pill - 1.1)))
    img = over(img, layer(grain(lacquer(vgrad(pill, "#FF8A4A", "#B83A16"), pill, rim="#FFE0C8", rim_k=0.6, band=1.6)), cov(pill)))
    gx = 74 + name_w(17, 1.2) + 6
    img = over(img, gem(gx, 82.6, 4.1, "#E3283F"))
    img = over(img, mark(gx + 11, 82.6, 4.4))
    texts = [
        dict(t=NAME, x=74, y=88.6, size=17, face="MontBlack", fill=CREAM, stroke=1.3, track=1.2),
        dict(t=HP, x=74, y=108.5, size=11.5, face="MontBlack", fill="#FFFFFF", stroke=1.4, track=0.3,
             tail=f" / {HP_MAX}", tail_size=9, tail_fill="#E8DCCB"),
        dict(t=LEVEL, x=37, y=127.4, size=9.6, face="MontBlack", fill="#FFFFFF", stroke=1.1, anchor="middle"),
    ]
    return img, texts


# ---------------------------------------------------------------------------------------------------------------- C
def option_c():
    """Bare: no plate; the bust cut out over one ember slash; the name large on the world; a chunky bar."""
    img = np.zeros(GX.shape + (4,))
    # the burst: jagged ember spikes from behind the head, longest toward the upper right; held above the cut
    bx, by = 33, 84
    rng = np.random.default_rng(23)
    ang = np.arctan2(GX - bx, -(GY - by))                # clockwise from up
    rr = np.hypot(GX - bx, GY - by)
    reach = np.full(GX.shape, 22.0)
    for _ in range(18):
        a0 = rng.uniform(-math.pi, math.pi)
        lean = math.cos(a0 - math.radians(50))           # toward the upper right, longer
        ln = 30 + 10 * max(lean, 0) + rng.uniform(-3, 5)
        w = rng.uniform(0.10, 0.17)
        d = np.abs((ang - a0 + math.pi) % (2 * math.pi) - math.pi)
        reach = np.maximum(reach, 22 + (ln - 22) * np.clip(1 - d / w, 0, 1))
    sd = (rr - reach) * 0.8
    sd = np.maximum(sd, np.maximum(GY - (119 - (GX - 6) * 0.2), 56 - GY))
    heat = np.clip(1 - rr / 44, 0, 1)
    col = rgb(EMBER_DEEP) * (1 - heat[..., None]) ** 2 + rgb(EMBER) * (2 * heat * (1 - heat))[..., None] * 1.4 \
        + rgb("#FFC27A") * (heat ** 2)[..., None]
    col = lacquer(np.clip(col, 0, 1), sd, rim="#FFE1C2", rim_k=0.4, band=1.0)
    img = over(img, layer(INK, cov(sd - 1.1)))
    img = over(img, layer(grain(col, 0.04), cov(sd)))
    img = over(img, layer(rgb(EMBER_DEEP) * 0.6, halftone(1.6, 0.6, rr / 34 - 0.15) * cov(sd) * 0.55))
    # the bust: cut by a slanted line across the chest, a heavy ink edge, the ember rim; the cut's edge hot
    b = bust(44, 31, 56, rim_k=1.0, tilt=4)
    line = 118 - (GX - 6) * 0.2
    b = b * cov(GY - line)[..., None]
    img = over(img, shadow(b[..., 3], 1.6, 1.6, 0.45))
    img = over(img, layer(INK, np.clip(ink_of(b[..., 3], 1.5) * cov(GY - line - 1.6) - b[..., 3], 0, 1)))
    img = over(img, b)
    img = over(img, layer(rgb(EMBER_HOT), cov(np.abs(GY - line) - 0.55) * ink_of(b[..., 3], 0.3)))
    # the level: a slate sticker on the cut's right end
    lv = convex([(40, 110), (63, 106), (63, 118), (40, 122)])
    img = over(img, shadow(cov(lv), 1.2, 1.0, 0.5))
    img = over(img, layer(INK, cov(lv - 1.2)))
    img = over(img, layer(grain(lacquer(vgrad(lv, "#3A404B", "#15181D"), lv, rim="#D9DEE6", rim_k=0.6, band=1.4)), cov(lv)))
    # the bar: chunky, rounded, a heavy ink edge
    x0, x1, y0, y1 = 68, 194, 93.5, 106.5
    rad = 3.2
    hp = np.minimum(np.minimum(convex([(x0 + rad, y0), (x1 - rad, y0), (x1 - rad, y1), (x0 + rad, y1)]),
                               convex([(x0, y0 + rad), (x1, y0 + rad), (x1, y1 - rad), (x0, y1 - rad)])),
                    np.minimum.reduce([circle(x0 + rad, y0 + rad, rad), circle(x1 - rad, y0 + rad, rad),
                                       circle(x0 + rad, y1 - rad, rad), circle(x1 - rad, y1 - rad, rad)]))
    img = over(img, shadow(cov(hp), 1.6, 1.4, 0.5))
    img = over(img, layer(INK, cov(hp - 1.6)))
    img = over(img, trough(hp))
    img = over(img, bar_fill(hp, x0, x1, HP_SHARE, LAG_SHARE))
    xp = convex([(x0 + 1, 109.3), (x0 + 100, 109.3), (x0 + 100, 111.5), (x0 + 1, 111.5)])
    img = over(img, layer(INK, cov(xp - 1.0)))
    img = over(img, layer(rgb("#07080A"), cov(xp)))
    img = over(img, xp_fill(xp, x0 + 1, x0 + 100))
    nx, ns, nt = 68, 22, 1.0
    gx = nx + name_w(ns, nt) + 7
    img = over(img, gem(gx, 81.0, 4.4, "#E3283F"))
    img = over(img, mark(gx + 12, 81.0, 4.7))
    texts = [
        dict(t=NAME, x=nx, y=88.8, size=ns, face="MontBlack", fill=CREAM, stroke=1.8, track=nt, hard=1.6, grad=True),
        dict(t=f"{HP}  /  {HP_MAX}", x=(x0 + x1) / 2, y=103.4, size=9.8, face="MontBlack", fill="#FFFFFF", stroke=1.2,
             anchor="middle", track=0.3),
        dict(t=LEVEL, x=52, y=118.2, size=11, face="MontBlack", fill="#FFFFFF", stroke=1.2, anchor="middle"),
    ]
    return img, texts


# ------------------------------------------------------------------------------------------------------ the frame
def clean_capture(cap, out):
    """The capture with the old plate's area filled by normalised convolution (no HUD-off capture yet)."""
    img = read_png(cap)
    h, w = img.shape[:2]
    m = np.ones((h, w))
    m[int(90 * h / 480):int(170 * h / 480), 0:int(298 * w / 852)] = 0
    c = img[..., :3]
    acc = np.zeros_like(c)
    for sig in (40, 16, 6, 2):
        num = np.stack([ndimage.gaussian_filter(c[..., i] * m, sig) for i in range(3)], -1)
        den = ndimage.gaussian_filter(m, sig)[..., None]
        fill = num / np.maximum(den, 1e-6)
        acc = np.where((den > 0.02), fill, acc) if sig == 40 else np.where(den > 0.25, fill, acc)
    res = c * m[..., None] + acc * (1 - m[..., None])
    write_png(out, res)
    return out


def css():
    return "".join(f'@font-face{{font-family:"{fam}";src:url("{(FONT_DIR / f).as_uri()}")}}' for fam, f in FACES.items())


def text_svg(d):
    a = d.get("anchor", "start")
    tr = d.get("track", 0)
    s = d["stroke"] * 2
    body = d["t"]
    if d.get("tail"):
        body = (f'{d["t"]}<tspan font-size="{d["tail_size"]}" fill="{d["tail_fill"]}">{d["tail"]}</tspan>')
    common = (f'x="{d["x"]}" font-family="{d["face"]}" font-size="{d["size"]}" text-anchor="{a}" letter-spacing="{tr}"'
              f' stroke-linejoin="round" paint-order="stroke"')
    out = []
    hard = d.get("hard", 1.0)
    out.append(f'<text {common} y="{d["y"] + hard}" fill="#0B0C10" stroke="#0B0C10" stroke-width="{s}">{body}</text>')
    fill = "url(#nameGrad)" if d.get("grad") else d["fill"]
    out.append(f'<text {common} y="{d["y"]}" fill="{fill}" stroke="#0B0C10" stroke-width="{s}">{body}</text>')
    return "".join(out)


def frame_html(bg, art, texts):
    defs = ('<linearGradient id="nameGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/>'
            '<stop offset="1" stop-color="#F2DCC2"/></linearGradient>')
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{defs}</defs>'
           f'<image href="{Path(bg).as_uri()}" x="0" y="0" width="{W}" height="{H}" preserveAspectRatio="none"/>'
           + (f'<image href="{Path(art).as_uri()}" x="{CX0}" y="{CY0}" width="{CW}" height="{CH}"/>' if art else "")
           + "".join(text_svg(t) for t in texts) + "</svg>")
    return (f'<!doctype html><html><head><meta charset="utf-8"><style>{css()} html,body{{margin:0;background:#000}}'
            f' svg{{display:block}}</style></head><body>{svg}</body></html>')


def crop(src, dst, x, y, w, h, scale=1):
    vf = f"crop={w}:{h}:{x}:{y}" + (f",scale=iw*{scale}:ih*{scale}:flags=lanczos" if scale != 1 else "")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(src), "-vf", vf, str(dst)], check=True)


ZOOM = (0, 46, 232, 90)   # the top-left in points, shown at 4 px a point


LABELS = {"today": "Today's plate, as built (13:42's images)",
          "A": "A, the card and the blade: the bust breaks out of a tall ember card; the blade carries the name and bars",
          "B": "B, the medallion: the round mount's rim is his health; the name on a swept ribbon",
          "C": "C, bare: no plate; the bust over a burst of ember, the name large on the world, a chunky bar"}


def render(cap, out):
    """One light: today's top-left and the three options, zoomed and whole, over the capture with the old plate's
    area filled."""
    out.mkdir(parents=True, exist_ok=True)
    work = out / "work"
    work.mkdir(exist_ok=True)
    bg = clean_capture(cap, work / "capture_filled.png")
    zx, zy, zw, zh = ZOOM
    crop(cap, out / "today_zoom.png", int(zx * 1.5), int(zy * 1.5), int(zw * 1.5), int(zh * 1.5), scale=f"{PPP}/1.5")
    for key, fn in (("A", option_a), ("B", option_b), ("C", option_c)):
        img, texts = fn()
        art = work / f"{key}_art.png"
        write_png(art, unpremul(img))
        html = frame_html(bg, art, texts)
        sf.shoot(html, out / f"{key}_phone.png", W, H, scale=1.5)
        big = work / f"{key}_big.png"
        sf.shoot(html, big, W, H, scale=PPP)
        crop(big, out / f"{key}_zoom.png", zx * PPP, zy * PPP, zw * PPP, zh * PPP)


def sheet(out, lights, caps):
    """The review sheet: the zooms (day and dusk side by side, today first), then the whole frames at the phone's size."""
    def img(p, w):
        return f'<img src="{Path(p).as_uri()}" style="width:{w}px;display:block">'
    rows = []
    for key in ("today", "A", "B", "C"):
        cells = "".join(f'<td>{img(out / l / ((key if key != "today" else "today") + "_zoom.png"), 928)}</td>' for l in lights)
        rows.append(f'<tr><td colspan="{len(lights)}" class="l">{LABELS[key]}</td></tr><tr>{cells}</tr>')
    phones = []
    for l in lights:
        cells = [img(caps[l], 852)] + [img(out / l / f"{k}_phone.png", 852) for k in "ABC"]
        phones.append(f'<tr><td colspan="2" class="l">The whole frame at the capture\'s size, {l}: today, A / B, C</td></tr>'
                      f'<tr><td>{cells[0]}</td><td>{cells[1]}</td></tr><tr><td>{cells[2]}</td><td>{cells[3]}</td></tr>')
    note = " Where the old plate stood, the world is filled by hand; the smudge there is that, not the plate."
    html = (f'<!doctype html><html><head><meta charset="utf-8"><style>{css()} body{{margin:0;background:#101216;color:#E8E2D6;'
            f'font-family:Builder;font-size:22px}} td{{padding:6px;vertical-align:top}} .l{{padding-top:16px}} h1{{font-size:28px;margin:18px 12px 4px}}'
            f' p{{margin:0 12px 8px;color:#B9B2A6}}</style></head><body><h1>AR68 M: the top-left, overhauled. Three compositions beside today’s.</h1>'
            f'<p>In a fight at 62% health, the last hit’s lag chip showing. At 4 px a point (zooms), then at the capture’s size (1.5 px a point). Day: Faber’s m_day_fight; dusk: m_dusk_awake.{note}</p>'
            f'<table>{"".join(rows)}</table><table>{"".join(phones)}</table></body></html>')
    h = 140 + 4 * (360 + 50) + len(lights) * (2 * 480 + 60)
    sf.shoot(html, out / "lead_sheet.png", 1880, h, scale=1)


def main(out, caps):
    out = Path(out).resolve()
    caps = {k: Path(v).resolve() for k, v in caps.items()}
    for l, c in caps.items():
        render(c, out / l)
    sheet(out, list(caps), caps)
    print("done")


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[0], dict(x.split("=", 1) for x in a[1:]))
