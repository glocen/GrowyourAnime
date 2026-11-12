"""AR3, the UI kit's direction sheet (docs/asset-requests.md, AR3; docs/ui.md): the lead's card, a rarity frame for each
of the six launch rarities, a pill, a button in all its states, a panel and the damage numbers, in Graphite Dark and
Pearl Light, at phone size, over a dark world and a bright one.

Everything is drawn here: shapes as distances from their outlines, at 2 pixels a point, text set by Blender. The face in
the frames is Rook's, rendered from his model. Nothing is taken from anywhere else.

Run: blender -b --factory-startup --python tools/blender/ui_sheet.py -- build/scratch/modulo/ui/sheet
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

K = 2  # pixels a point: a phone draws two or three
ROOK = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "rook" / "model"
CAP = 0.72  # a capital's height, of the text's size


def c(code):
    return np.array(rs.rgb(code), dtype=np.float32)


WHITE, BLACK = c("#FFFFFF"), c("#000000")
LIGHT = "#FFF4D6"  # the conduit's light: ivory, the colour of a plain hit, so health and the damage that takes it match
CHARGE = "#FFE266"  # electricity
GOOD, BAD = "#7CF0A4", "#FF7A66"  # the server said yes; the server said no
NUMBER = {"plain": "#F8F1DF", "critical": "#FFCF4D", "heal": "#6FE695", "miss": "#B9BEC9"}
ELEMENTS = {"Fire": "#FF8A3D", "Frost": "#8FE3FF", "Storm": "#FF6FD8", "Void": "#B58CFF"}  # Storm is research's, 2026-11-12
STROKE = "#0E0F14"

THEMES = {
    "Graphite Dark": dict(panel=("#20242C", "#13151A"), alpha=0.94, edge="#434A57", facet="#8A93A6", glint="#C9D2E4",
                          text="#F3EFE6", soft="#A6ADBA", faint="#6E7482", channel="#06070A", well="#0B0C10",
                          button=("#323845", "#22262F"), pressed=("#1A1D24", "#20242C"), ground="#2B2E36"),
    # the director, 2026-11-12: Pearl's pieces carry a black border
    "Pearl Light": dict(panel=("#FAF7F0", "#E9E4D8"), alpha=0.96, edge=STROKE, border=1.6, facet="#FFFFFF", glint="#FFFFFF",
                        text="#191B21", soft="#535967", faint="#8C909B", channel="#20232B", well="#D8D2C4",
                        button=("#FFFFFF", "#EFEADF"), pressed=("#DAD4C6", "#E6E1D5"), ground="#CFCBC2",
                        rim=2.0, seat=1.6, warm=(1.0, 0.7, 0.3)),
}

# A rarity is the frame's shape and its light, never a hue: the five hues belong to the types. Each step up adds one
# thing seen at 64 px (research's fix 1): a hairline in dark iron; a thick band of bright steel; a point on top and
# the first glow; points all four ways, white-hot; a crown of three in gold; a broken crown in red light (the director,
# 2026-11-12: reddish, not a rainbow). Its red is deeper than the failed button's and it burns white at its core: the
# glance strip stands it beside that button and the Strength gem.
RARITIES = {
    "Common": dict(cut=(6, 0, 6, 0), stroke=1.2, metal=("#666C78", "#444852")),
    "Uncommon": dict(cut=(8, 4, 8, 4), stroke=3.2, metal=("#DCE2EC", "#939CAD"), inner=True),
    "Rare": dict(cut=(10, 4, 10, 4), stroke=3.0, metal=("#F0F4FA", "#A7B1C2"), glow=("#DCE9FF", 6.0, 0.5),
                 crest=((0.5, 9, 10),)),
    "Epic": dict(cut=(11, 5, 11, 5), stroke=3.2, metal=("#FFFFFF", "#BCC6D8"), hot=True, glow=("#EEF4FF", 10.0, 0.78),
                 crest=((0.5, 9, 13),), base=((0.5, 8, 10),), wing=7, shards=1),
    "Legendary": dict(cut=(12, 5, 12, 5), stroke=3.5, metal=("#FFEDB0", "#D8A23C"), hot=True, glow=("#FFD777", 11.0, 0.75),
                      crest=((0.24, 6, 8), (0.5, 9, 16), (0.76, 6, 8)), base=((0.5, 8, 9),), wing=6, shards=2),
    "Mythical": dict(cut=(13, 6, 13, 9), stroke=3.5, metal=("#FF8794", "#B3122E"), hot=True, inner=True, glow=("#FF2848", 12.0, 0.7),
                     crest=((0.24, 5, 9), (0.41, 7, 20), (0.62, 6, 13), (0.8, 5, 7)), base=((0.36, 6, 7), (0.62, 7, 11)),
                     wing=7, shards=3, splinter="#FFF1F2"),  # white-hot: a red splinter under a frame could read as a drop
}


# --- drawing --------------------------------------------------------------------------------------------------------

def over(dst, colour, a):
    """Lays a colour (one, or one a pixel) over a picture, by the cover `a`."""
    colour = np.asarray(colour, dtype=np.float32)
    if colour.ndim == 1:
        colour = colour[None, None, :]
    da = dst[..., 3]
    out = a + da * (1 - a)
    dst[..., :3] = (colour * a[..., None] + dst[..., :3] * (da * (1 - a))[..., None]) / np.maximum(out, 1e-6)[..., None]
    dst[..., 3] = out


def sd_polygon(x, y, pts):
    """The distance from a polygon's outline, negative inside."""
    d = np.full(x.shape, 1e9, dtype=np.float32)
    inside = np.zeros(x.shape, dtype=bool)
    for (ax, ay), (bx, by) in zip(pts, pts[1:] + pts[:1]):
        ex, ey, px, py = bx - ax, by - ay, x - ax, y - ay
        t = np.clip((px * ex + py * ey) / max(ex * ex + ey * ey, 1e-9), 0, 1)
        d = np.minimum(d, np.hypot(px - ex * t, py - ey * t))
        if abs(ey) > 1e-9:
            inside ^= ((ay <= y) != (by <= y)) & (x < ax + (y - ay) / ey * ex)
    return np.where(inside, -d, d)


def sd_segment(x, y, a, b):
    ex, ey, px, py = b[0] - a[0], b[1] - a[1], x - a[0], y - a[1]
    t = np.clip((px * ex + py * ey) / max(ex * ex + ey * ey, 1e-9), 0, 1)
    return np.hypot(px - ex * t, py - ey * t)


def cut_box(x0, y0, x1, y1, tl=0.0, tr=0.0, br=0.0, bl=0.0):
    """A box with its corners cut, clockwise from the top left."""
    pts = [(x0, y0 + tl), (x0 + tl, y0)] if tl else [(x0, y0)]
    pts += [(x1 - tr, y0), (x1, y0 + tr)] if tr else [(x1, y0)]
    pts += [(x1, y1 - br), (x1 - br, y1)] if br else [(x1, y1)]
    pts += [(x0 + bl, y1), (x0, y1 - bl)] if bl else [(x0, y1)]
    return pts


class Sheet:
    def __init__(self, width, height, ground):
        self.w, self.h = width, height
        self.px = rs.canvas(round(width * K), round(height * K), tuple(c(ground)))
        self.items = []

    def tile(self, x, y, w, h):
        return Tile(self, x, y, w, h)


class Tile:
    """A window on the sheet, measured in points from its own corner."""

    def __init__(self, sheet, x, y, w, h):
        self.sheet, self.ox, self.oy, self.w, self.h = sheet, x, y, w, h
        x0, y0 = round(x * K), round(y * K)
        self.px = sheet.px[y0:y0 + round(h * K), x0:x0 + round(w * K)]
        gy, gx = np.mgrid[0:self.px.shape[0], 0:self.px.shape[1]]
        self.x, self.y = ((gx + 0.5) / K).astype(np.float32), ((gy + 0.5) / K).astype(np.float32)

    def poly(self, pts):
        return sd_polygon(self.x, self.y, list(pts))

    def paint(self, d, colour, alpha=1.0):
        over(self.px, colour, np.clip(0.5 - d * K, 0, 1) * alpha)

    def line(self, d, width, colour, alpha=1.0):
        """A line of `width` just inside an outline."""
        self.paint(np.abs(d + width / 2) - width / 2, colour, alpha)

    def glow(self, d, radius, colour, strength):
        over(self.px, colour, strength * np.exp(-(np.maximum(d, 0) / radius) ** 1.4))

    def lit(self, d, width, colour, channel):
        """A line of light just inside an outline, in its dark channel: light reads on a pale panel only against one."""
        self.line(d, width + 1.4, channel)
        self.line(d + 0.7, width, colour)

    def ramp(self, a, b, t):
        a, b = (c(v) if isinstance(v, str) else np.asarray(v, dtype=np.float32) for v in (a, b))
        return a + (b - a) * np.clip(t, 0, 1)[..., None]

    def stroke(self, pts, width, colour, alpha=1.0):
        d = np.minimum.reduce([sd_segment(self.x, self.y, a, b) for a, b in zip(pts, pts[1:])])
        self.paint(d - width / 2, colour, alpha)

    def image(self, rgba, x, y, d=None):
        x0, y0 = round(x * K), round(y * K)
        region = self.px[max(y0, 0):y0 + rgba.shape[0], max(x0, 0):x0 + rgba.shape[1]]
        src = rgba[max(-y0, 0):max(-y0, 0) + region.shape[0], max(-x0, 0):max(-x0, 0) + region.shape[1]]
        a = src[..., 3].copy()
        if d is not None:
            a *= np.clip(0.5 - d[max(y0, 0):y0 + rgba.shape[0], max(x0, 0):x0 + rgba.shape[1]] * K, 0, 1)
        over(region, src[..., :3], a)

    def text(self, x, y, size, text, colour, align="LEFT", layer="plain", shear=0.0, bold=0.0):
        """Text with its capitals' top at y."""
        self.sheet.items.append(dict(x=self.ox + x, y=self.oy + y, size=size, text=text, colour=colour, align=align,
                                     layer=layer, shear=shear, bold=bold))


# --- the kit's pieces -----------------------------------------------------------------------------------------------

def panel(t, x0, y0, x1, y1, th, cut=10.0, shadow=True):
    """A panel cut from a shard: two opposite corners cut deep, the other two just broken, a facet off the top cut."""
    d = t.poly(cut_box(x0, y0, x1, y1, cut, cut * 0.3, cut, cut * 0.3))
    if shadow:
        t.glow(d, 6.0, BLACK, 0.3)
    t.paint(d, t.ramp(th["panel"][0], th["panel"][1], (t.y - y0) / (y1 - y0)), th["alpha"])
    t.paint(np.maximum(d, (t.x - x0) + (t.y - y0) - cut * 3.4), c(th["facet"]), 0.07)
    t.line(d, th.get("border", 1.0), c(th["edge"]), 0.95)
    t.paint(sd_segment(t.x, t.y, (x0 + 0.5, y0 + cut), (x0 + cut, y0 + 0.5)) - 0.6, c(th["glint"]), 0.85)
    t.paint(sd_segment(t.x, t.y, (x1 - cut, y1 - 0.5), (x1 - 0.5, y1 - cut)) - 0.5, c(th["glint"]), 0.35)
    return d


def conduit(t, x0, y0, x1, h, fill, th, light=LIGHT):
    """A bar: a dark channel cut on the slant, and light running through it as far as `fill`, brightest at its head."""
    s = h * 0.6
    d = t.poly([(x0 + s, y0), (x1, y0), (x1 - s, y0 + h), (x0, y0 + h)])
    t.paint(d, c(th["channel"]))
    t.line(d, 0.75, c(th["edge"]), 0.9)
    if fill <= 0:
        return
    xe = x0 + s + (x1 - x0 - s) * fill
    norm = math.hypot(1.0, s / h)
    cutoff = ((t.x - xe) + (t.y - y0) * s / h) / norm  # the slanted end of the light
    lit = np.maximum(d + min(th.get("rim", 1.0), h * 0.2), cutoff)  # on a pale panel the channel shows all round
    colour = c(light)
    t.glow(lit, h * 0.55, colour, 0.4)
    across = 1 - np.abs(2 * (t.y - y0) / h - 1)
    edge = colour * 0.82
    if th.get("warm") and colour[2] < colour[0]:  # a warm light on a pale panel: gold at its edges, white at its core
        edge, across = colour * np.asarray(th["warm"], dtype=np.float32), np.clip(across, 0, 1) ** 1.6
    t.paint(lit, t.ramp(edge, 0.5 * colour + 0.5 * WHITE, across))
    head = np.clip(1 + cutoff / max(h * 1.2, 5.0), 0, 1)
    over(t.px, WHITE, np.clip(0.5 - lit * K, 0, 1) * head * 0.75)


def gem(t, cx, cy, r, colour, seat=0.0):
    """A type's gem: a cut stone, lit from the top left. The stand-in for the kit's five. In a frame's cut it sits in
    a dark `seat`, so the Strength gem holds against Mythical's red light."""
    colour = c(colour)
    d = t.poly([(cx, cy - r), (cx + r * 0.82, cy - r * 0.36), (cx + r * 0.82, cy + r * 0.36), (cx, cy + r),
                (cx - r * 0.82, cy + r * 0.36), (cx - r * 0.82, cy - r * 0.36)])
    if seat:
        t.paint(d - seat, c(STROKE), 0.92)
    else:
        t.glow(d, r * 0.45, colour, 0.35)
    t.paint(d - 1.0, c(STROKE))
    t.paint(d, colour)
    slope = (t.y - cy) + (t.x - cx) * 0.55
    t.paint(np.maximum(d, slope + r * 0.2), WHITE, 0.38)
    t.paint(np.maximum(d, -slope + r * 0.3), BLACK, 0.3)
    t.paint(np.hypot(t.x - (cx - r * 0.25), t.y - (cy - r * 0.42)) - r * 0.14, WHITE, 0.9)


def class_mark(t, cx, cy, r, th):
    """The Warrior's mark, a short blade: the stand-in for the kit's five class icons."""
    d = t.poly(cut_box(cx - r, cy - r, cx + r, cy + r, r * 0.5, 0, r * 0.5, 0))
    t.paint(d - 1.0, c(STROKE))
    t.paint(d, c(th["well"]))
    t.line(d, 0.75, c(th["edge"]))
    ink = c(th["text"])
    t.paint(t.poly([(cx, cy - r * 0.72), (cx + r * 0.26, cy + r * 0.12), (cx, cy + r * 0.3), (cx - r * 0.26, cy + r * 0.12)]), ink)
    t.stroke([(cx - r * 0.45, cy + r * 0.34), (cx + r * 0.45, cy + r * 0.34)], r * 0.2, ink)
    t.stroke([(cx, cy + r * 0.34), (cx, cy + r * 0.74)], r * 0.2, ink)


def outline(x0, y0, x1, y1, r):
    """A rarity's frame: the cut box, with points rising from its top, falling from its base, and standing out of its sides."""
    tl, tr, br, bl = r["cut"]
    w, n, my = x1 - x0, r.get("wing", 0) * (x1 - x0) / 80.0, (y0 + y1) / 2
    pts = [(x0, y0 + tl), (x0 + tl, y0)] if tl else [(x0, y0)]
    k = w / 80.0
    for f, hw, hh in r.get("crest", ()):
        pts += [(x0 + w * f - hw * k, y0), (x0 + w * f, y0 - hh * k), (x0 + w * f + hw * k, y0)]
    pts += [(x1 - tr, y0), (x1, y0 + tr)] if tr else [(x1, y0)]
    if n:
        pts += [(x1, my - n * 1.3), (x1 + n, my), (x1, my + n * 1.3)]
    pts += [(x1, y1 - br), (x1 - br, y1)] if br else [(x1, y1)]
    for f, hw, hh in sorted(r.get("base", ()), reverse=True):
        pts += [(x0 + w * f + hw * k, y1), (x0 + w * f, y1 + hh * k), (x0 + w * f - hw * k, y1)]
    pts += [(x0 + bl, y1), (x0, y1 - bl)] if bl else [(x0, y1)]
    if n:
        pts += [(x0, my + n * 1.3), (x0 - n, my), (x0, my - n * 1.3)]
    return pts


def frame(t, x0, y0, w, h, rarity, face, th, type_="Strength", marks=True):
    """A portrait in its rarity's frame, the type's gem in the top cut and the class's mark in the bottom one."""
    r = RARITIES[rarity]
    x1, y1, cx, cy = x0 + w, y0 + h, x0 + w / 2, y0 + h / 2
    d = t.poly(outline(x0, y0, x1, y1, r))
    scale = w / 80.0
    metal = t.ramp(r["metal"][0], r["metal"][1], (t.y - y0) / h)
    if "glow" in r:
        code, radius, strength = r["glow"]
        t.glow(d, radius * scale, c(code), strength)
    if th.get("seat"):  # pale metal on a pale panel: the frame sits in a dark seat
        t.paint(d - th["seat"] * max(scale, 0.75), c(th["channel"]), 0.92)
    t.paint(d, t.ramp("#1B1E26", "#090A0D", (t.y - y0) / h))
    side = round((w - 2) * K)
    t.image(rs.shrink(face, side / face.shape[1]), x0 + 1, y1 - side / K - 1, d + r["stroke"] * 0.5)
    t.paint(np.maximum(d, y1 - h * 0.3 - t.y), BLACK, 0.25)  # the floor of the slot, so the marks read over any face
    width = r["stroke"] * max(scale, 0.75)
    t.line(d, width, metal)
    if r.get("inner"):
        t.line(d + width + 1.2, 0.7, metal, 0.75)
    if r.get("hot"):
        t.line(d + width * 0.3, 0.8, WHITE, 0.9)
    tl, br = r["cut"][0], r["cut"][2]
    for i in range(r.get("shards", 0) if scale >= 0.75 else 0):  # splinters the cuts threw off; none on a small frame
        o, s = 3.0 + i * 3.2, (4.0 - i * 0.8) * scale
        for px, py, sx, sy in ((x1 - br * 0.5, y1 - br * 0.5, 1, 1), (x0 + tl * 0.5, y0 + tl * 0.5, -1, -1))[:1 + (i > 0)]:
            ax, ay = px + sx * o * 0.7, py + sy * o * 0.7
            tri = t.poly([(ax + sx * s, ay - sy * s * 0.2), (ax - sx * s * 0.2, ay + sy * s), (ax + sx * s * 0.75, ay + sy * s * 0.75)])
            if "glow" in r:
                t.glow(tri, 2.0, WHITE, 0.3)
            t.paint(tri, c(r["splinter"]) if "splinter" in r else metal)
    if marks:
        gem(t, x0 + 1.5 * scale + 4 * scale, y0 + 1.5 * scale + 4 * scale, 6.5 * max(scale, 0.8), ss.TYPES[type_],
            seat=2.4 * max(scale, 0.8))
        class_mark(t, x1 - 6.5 * scale, y1 - 6.5 * scale, 6.0 * max(scale, 0.8), th)
    return d


def button(t, x0, y0, w, h, label, th, state="rest", reason=None):
    """A button in one of its states. The light on its lower edge is what says it can be pressed."""
    dy = 1.0 if state == "pressed" else 0.0
    y0 += dy
    d = t.poly(cut_box(x0, y0, x0 + w, y0 + h, 8, 0, 8, 0))
    fill = th["pressed"] if state == "pressed" else th["button"]
    lit = {"selected": LIGHT, "succeeded": GOOD, "failed": BAD}.get(state)
    if state != "pressed":
        t.glow(d, 4.0, BLACK, 0.22)
    if lit:
        t.glow(d, 5.0, c(lit), 0.5)
    alpha = 0.45 if state == "disabled" else 1.0
    t.paint(d, t.ramp(fill[0], fill[1], (t.y - y0) / h), 1.0)
    if state == "disabled":
        t.paint(d, c(th["ground"]), 0.55)
    t.line(d, th.get("border", 1.0), c(th["edge"]), alpha)
    channel = c(th["channel"])
    if state == "pressed":
        t.paint(np.maximum(d, t.y - y0 - 5), BLACK, 0.22)
    if lit:
        t.lit(d, 1.4, c(lit), channel)
    elif state in ("rest", "pressed"):  # pressed, the light flares
        t.paint(np.maximum(d, y0 + h - 3.6 - t.y), channel)
        base = np.maximum(d + 0.8, y0 + h - 2.8 - t.y)
        t.glow(base, 4.0 if state == "pressed" else 2.5, c(LIGHT), 0.7 if state == "pressed" else 0.3)
        t.paint(base, WHITE if state == "pressed" else c(LIGHT))
    elif state == "waiting":  # the light runs round the edge while the server is asked
        along = np.abs(t.x - (x0 + w * 0.62)) - w * 0.2
        t.paint(np.maximum(np.maximum(np.abs(d + 1.5) - 1.5, along - 1.0), t.y - y0 - 6), channel)
        run = np.maximum(np.maximum(np.abs(d + 1.5) - 0.8, along), t.y - y0 - 6)
        t.glow(run, 3.0, c(LIGHT), 0.55)
        t.paint(run, c(LIGHT))
    ink = th["faint"] if state == "disabled" else th["text"]
    cx, base_y = x0 + w / 2, y0 + (h - 14 * CAP) / 2
    if state == "waiting":
        t.paint(t.poly(cut_box(cx - 26, y0 + h / 2 - 7, cx + 26, y0 + h / 2 + 7, 5, 0, 5, 0)), channel)
        for i in range(3):
            dot = np.hypot(t.x - (cx - 13 + 13 * i), t.y - (y0 + h / 2)) - (2.8 - 0.5 * i)
            t.glow(dot, 2.0, c(LIGHT), 0.4 - 0.1 * i)
            t.paint(dot, c(LIGHT), 1.0 - 0.3 * i)
    elif state == "succeeded":
        t.stroke([(x0 + 22, y0 + h / 2), (x0 + 27, y0 + h / 2 + 5), (x0 + 36, y0 + h / 2 - 6)], 2.4, c(GOOD))
        t.text(cx + 12, base_y, 14, label, ink, "CENTER")
    else:
        t.text(cx, base_y, 14, label, ink, "CENTER")
    if reason:
        t.text(cx, y0 - dy + h + 7, 14, reason, th["soft"], "CENTER")


def coin(t, cx, cy, r):
    d = t.poly([(cx + r * math.cos(a), cy + r * math.sin(a)) for a in (math.radians(22.5 + 45 * i) for i in range(8))])
    t.paint(d - 1.0, c(STROKE))
    t.paint(d, t.ramp("#FFF6DE", "#CDBE98", (t.y - cy + r) / (2 * r)))
    t.line(d + 1.6, 0.9, c("#8C7F5E"), 0.9)
    t.paint(t.poly([(cx, cy - r * 0.42), (cx + r * 0.3, cy), (cx, cy + r * 0.42), (cx - r * 0.3, cy)]), c("#8C7F5E"))


def bolt(t, cx, cy, r):
    d = t.poly([(cx + r * 0.25, cy - r), (cx - r * 0.55, cy + r * 0.12), (cx - r * 0.05, cy + r * 0.12), (cx - r * 0.3, cy + r),
                (cx + r * 0.55, cy - r * 0.2), (cx + r * 0.05, cy - r * 0.2)])
    t.glow(d, r * 0.5, c(CHARGE), 0.4)
    t.paint(d - 1.0, c(STROKE))
    t.paint(d, t.ramp("#FFF7C2", CHARGE, (t.y - cy + r) / (2 * r)))


def pill(t, x0, y0, w, th, icon, value, extra=None, fill=None):
    """A pill: an amount with its mark. Electricity's holds its store over its cap, the rate, and a thread of charge."""
    h = 30.0
    d = t.poly(cut_box(x0, y0, x0 + w, y0 + h, 9, 3, 9, 3))
    t.glow(d, 5.0, BLACK, 0.28)
    t.paint(d, t.ramp(th["panel"][0], th["panel"][1], (t.y - y0) / h), th["alpha"])
    t.line(d, th.get("border", 1.0), c(th["edge"]), 0.95)
    t.paint(sd_segment(t.x, t.y, (x0 + 0.5, y0 + 9), (x0 + 9, y0 + 0.5)) - 0.6, c(th["glint"]), 0.85)
    icon(t, x0 + 19, y0 + h / 2, 8.0)
    ty = y0 + (h - 14 * CAP) / 2 - (2 if fill is not None else 0)
    t.text(x0 + 33, ty, 14, value, th["text"])
    if extra:
        t.text(x0 + w - 10, ty, 14, extra, th["soft"], "RIGHT")
    if fill is not None:
        conduit(t, x0 + 31, y0 + h - 8, x0 + w - 9, 3.0, fill, th, CHARGE)


def lead_card(t, x0, y0, th, face, name, level, health, experience, rarity="Common", width=212.0):
    """The lead's card: the portrait in its frame, the name with its type and class, health as light, experience as a
    thread under it."""
    h = 62.0
    panel(t, x0, y0, x0 + width, y0 + h, th, cut=9)
    frame(t, x0 + 7, y0 + 7, 40, 48, rarity, face, th, marks=False)
    tx = x0 + 56
    t.text(tx, y0 + 9, 14, name, th["text"])
    t.text(x0 + width - 9, y0 + 9, 14, f"Lv {level}", th["soft"], "RIGHT")
    gem(t, tx + 6, y0 + 33, 6.0, ss.TYPES["Strength"])
    class_mark(t, tx + 21, y0 + 33, 5.5, th)
    conduit(t, tx + 32, y0 + 28, x0 + width - 9, 10.0, health, th)
    conduit(t, tx, y0 + 46, x0 + width - 9, 4.0, experience, th, "#C9B8FF")


def spark(t, cx, cy, r, colour):
    """The mark on a critical hit: a four-point spark."""
    pts = []
    for i in range(8):
        a, rad = math.radians(45 * i - 90 + 12), (r if i % 2 == 0 else r * 0.3)
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    d = t.poly(pts)
    t.paint(d - 1.5, c(STROKE))
    t.paint(d, c(colour))


def numbers(t, x0, y0):
    """The damage numbers, as they'd rise from a body: slanted and stroked, so they read over anything."""
    def n(x, y, size, text, colour):
        t.text(x0 + x, y0 + y, size, text, colour, "CENTER", layer="number" if size >= 20 else "number_small",
               shear=0.22, bold=0.012)
    n(40, 34, 20, "248", NUMBER["plain"])
    n(52, 60, 15, "86", ELEMENTS["Fire"])
    spark(t, x0 + 92, y0 + 16, 8.0, NUMBER["critical"])
    n(140, 6, 28, "1,204", NUMBER["critical"])
    n(162, 44, 15, "112", ELEMENTS["Frost"])
    n(112, 46, 15, "74", ELEMENTS["Storm"])
    n(190, 62, 15, "95", ELEMENTS["Void"])
    n(234, 30, 20, "+320", NUMBER["heal"])
    n(246, 64, 16, "Dodge", NUMBER["miss"])


def world(t, kind):
    """A stand-in for the game behind the HUD: a festival street at dusk, and the same street at noon. Busy on purpose."""
    w, h = t.w, t.h
    v = t.y / h
    if kind == "dusk":
        sky = t.ramp("#16122B", "#3A2550", v * 1.5)
        ground, stalls, lamp = c("#17141F"), ("#241B36", "#1C1730", "#2D2140"), "#FFB866"
    else:
        sky = t.ramp("#9FD3F2", "#F6EBCB", v * 1.5)
        ground, stalls, lamp = c("#E4D6B2"), ("#C9694A", "#4E8FA8", "#E9C46A"), "#FFFFFF"
    t.px[..., :3], t.px[..., 3] = sky, 1.0
    t.paint(h * 0.66 - t.y, ground)
    rng = np.random.default_rng(7)
    x = -20.0
    while x < w:
        sw, sh = rng.uniform(46, 90), rng.uniform(0.3, 0.52) * h
        top = h * 0.66 - sh
        body = c(stalls[int(rng.integers(len(stalls)))])
        t.paint(t.poly(cut_box(x, top, x + sw, h * 0.66)), body)
        t.paint(t.poly([(x - 5, top + 8), (x + sw + 5, top + 8), (x + sw, top - 4), (x, top - 4)]), body * 0.8 + 0.2 * c(lamp))
        stripes = np.maximum(t.poly(cut_box(x, top - 4, x + sw, top + 8)), np.sin(t.x * 0.9) * 2)
        t.paint(stripes, WHITE, 0.25 if kind == "noon" else 0.08)
        lx, ly = x + sw * 0.5, top + 20
        if kind == "dusk":
            t.glow(np.hypot(t.x - lx, t.y - ly) - 3, 16.0, c(lamp), 0.55)
            t.glow(np.hypot(t.x - lx - sw * 0.3, t.y - ly + 6) - 2, 10.0, c("#7FE9F2"), 0.4)
        t.paint(np.hypot(t.x - lx, t.y - ly) - 3.5, c(lamp))
        x += sw + rng.uniform(4, 16)
    if kind == "noon":  # the sun on the street
        t.glow(np.hypot(t.x - w * 0.7, (t.y - h * 0.9) * 3) - 30, 60.0, WHITE, 0.5)


def lantern_row(t):
    """The five type gems under Lantern Row's light, cyan and warm white at dusk (docs/roster.md): Agility's blue has
    to stay its own beside the cyan."""
    t.px[..., :3], t.px[..., 3] = t.ramp("#16122B", "#2B1F42", t.y / t.h), 1.0
    for lx, code in ((18, "#5FE3F0"), (96, "#FFE2B8")):
        lamp = np.hypot(t.x - lx, t.y - 16) - 5
        t.glow(lamp, 26.0, c(code), 0.6)
        t.paint(lamp, 0.4 * c(code) + 0.6 * WHITE)
    for i, code in enumerate(ss.TYPES.values()):
        gem(t, 17 + i * 20, 30, 7.0, code)
        gem(t, 17 + i * 20, 48, 4.5, code)


# --- text -----------------------------------------------------------------------------------------------------------

def text_layers(width, height, items):
    """Each layer of text as a transparent picture the sheet's size. Blender's own face stands in for the game's."""
    layers = {}
    for layer in sorted({i["layer"] for i in items}):
        scene, made = bl.reset_scene(), {}
        for i in (i for i in items if i["layer"] == layer):
            curve = bpy.data.curves.new("Text", "FONT")
            curve.body, curve.size, curve.align_x = i["text"], i["size"] * K, i["align"]
            curve.shear, curve.offset = i["shear"], i["bold"]
            curve.space_character = i.get("space", 1.0)
            obj = bpy.data.objects.new("Text", curve)
            scene.collection.objects.link(obj)
            obj.location = (i["x"] * K, height - i["y"] * K - i["size"] * K * CAP, 0)
            if i["colour"] not in made:
                made[i["colour"]] = bpy.data.materials.new(i["colour"])
                made[i["colour"]].diffuse_color = rs.srgb(i["colour"])
            curve.materials.append(made[i["colour"]])
        rs.workbench(scene, width, height, flat=True)
        cam = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
        scene.collection.objects.link(cam)
        scene.camera = cam
        cam.data.type, cam.data.ortho_scale = "ORTHO", max(width, height)
        cam.location = (width / 2, height / 2, 10)
        path = bl.out_dir() / f"_text_{layer}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        layers[layer] = rs.load(path)
        path.unlink()
    return layers


def spread(alpha, radius):
    """A picture's cover, grown by `radius` pixels: the stroke round a number."""
    out = alpha.copy()
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if (dx or dy) and dx * dx + dy * dy <= radius * radius + 1:
                out = np.maximum(out, np.roll(np.roll(alpha, dy, axis=0), dx, axis=1))
    return out


def portrait(size=400):
    """Rook's face, from his model, three-quarter on."""
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Portrait")
    with bpy.data.libraries.load(str(ROOK / "rook_model.blend")) as (src, dst):
        dst.objects = list(src.objects)
    for o in dst.objects:
        if o.type == "MESH":
            scene.collection.objects.link(o)
    rm.eevee(scene, size, size)
    rm.sun_for(scene, 150)
    path = bl.out_dir() / "_portrait.png"
    shot = rs.shoot(scene, path, 150, 4, (0, 0, 4.42), 2.05)
    path.unlink()
    return shot


# --- the sheet ------------------------------------------------------------------------------------------------------

COLUMN, GUTTER, MARGIN = 570.0, 20.0, 20.0
STATES = (("rest", "Break", None), ("pressed", "Break", None), ("selected", "Voidkin", None),
          ("disabled", "Break", "Needs 200 Credits"), ("waiting", "", None), ("succeeded", "Done", None),
          ("failed", "Break", "No free chamber"))


def column(sheet, x, name, face):
    th = THEMES[name]
    note, ink = "#C9CDD6", "#F3EFE6"
    head = sheet.tile(x, 58, COLUMN, 20)
    head.text(0, 2, 13, name, ink)
    y = 84.0
    for kind in ("dusk", "noon"):  # the HUD's pieces over a world
        t = sheet.tile(x, y, COLUMN, 150)
        world(t, kind)
        lead_card(t, 10, 10, th, face, "Rook", 12, 0.68, 0.4)
        pill(t, COLUMN - 10 - 176 - 8 - 104, 10, 104, th, coin, "12,480")
        pill(t, COLUMN - 10 - 176, 10, 176, th, bolt, "3,120 / 5,000", "+14/s", 0.62)
        numbers(t, 236, 62)
        y += 158
    t = sheet.tile(x, y, COLUMN, 22)
    t.text(0, 6, 10, "The six rarities: the frame's shape and its light. The hue is the type's, on the gem.", note)
    y += 22
    t = sheet.tile(x, y, COLUMN, 150)
    panel(t, 0.5, 0.5, COLUMN - 0.5, 149.5, th, shadow=False)
    for i, rarity in enumerate(RARITIES):
        frame(t, 15 + i * 93, 27, 74, 94, rarity, face, th, type_=list(ss.TYPES)[i % 5])
        t.text(15 + i * 93 + 37, 136, 9, rarity, th["soft"], "CENTER")
    y += 158
    t = sheet.tile(x, y, COLUMN, 22)
    t.text(0, 6, 10, "A button's states: rest, pressed, selected, disabled with its reason, waiting, succeeded, failed.", note)
    y += 22
    t = sheet.tile(x, y, COLUMN, 172)
    panel(t, 0.5, 0.5, COLUMN - 0.5, 171.5, th, shadow=False)
    for i, (state, label, reason) in enumerate(STATES):
        bx, by = 15 + (i % 4) * 136, 14 + (i // 4) * 80
        button(t, bx, by, 124, 44, label, th, state, reason)
    t.text(15 + 3 * 136 + 62, 14 + 80 + 15, 9, "disabled and failed", th["faint"], "CENTER")
    t.text(15 + 3 * 136 + 62, 14 + 80 + 28, 9, "say why, in words", th["faint"], "CENTER")
    y += 180
    t = sheet.tile(x, y, COLUMN, 22)
    t.text(0, 6, 10, "A panel, the bars, and a long name.", note)
    y += 22
    t = sheet.tile(x, y, COLUMN, 150)
    world(t, "dusk" if name == "Graphite Dark" else "noon")
    panel(t, 10, 10, 290, 140, th, cut=14)
    t.text(26, 24, 16, "Break this shard?", th["text"])
    t.text(26, 50, 14, "Chamber 2, ready in 4 min", th["soft"])
    button(t, 26, 84, 118, 44, "Break", th, "rest")
    button(t, 156, 84, 118, 44, "Not now", th, "rest")
    lead_card(t, 304, 10, th, face, "Sledgehammer Sunday", 40, 0.22, 0.85, rarity="Legendary", width=256)
    conduit(t, 304, 86, 436, 10.0, 1.0, th)
    conduit(t, 304, 104, 436, 10.0, 0.08, th, "#FFB24A")
    conduit(t, 304, 122, 436, 10.0, 0.0, th)
    lantern_row(sheet.tile(x + 446, y + 82, 114, 58))
    return y + 158


def glance(name, face):
    """Research's tests for fixes 1 and 2, as a strip at 1 pixel a point: the six frames out of order, 64 px wide, and
    a bar full, low and empty, on the theme's panel."""
    th = THEMES[name]
    sheet = Sheet(COLUMN, 120, th["ground"])
    t = sheet.tile(0, 0, COLUMN, 120)
    panel(t, 0.5, 0.5, COLUMN - 0.5, 119.5, th, shadow=False)
    for i, rarity in enumerate(("Epic", "Common", "Mythical", "Rare", "Uncommon", "Legendary")):
        frame(t, 16 + i * 77, 26, 64, 80, rarity, face, th, marks=False)
    for i, (fill, light) in enumerate(((1.0, LIGHT), (0.08, "#FFB24A"), (0.0, LIGHT))):
        conduit(t, 478, 40 + i * 22, 556, 10.0, fill, th, light)
    return rs.shrink(sheet.px, 0.5)


def reds(name, face):
    """The director's Mythical beside the kit's other reds, at 1 pixel a point: its frame with a Strength gem in the cut,
    a failed button with its words, the gem alone, and the lead's card in a Mythical frame on low health. It has to
    sort as the top rarity and never read as "failed"."""
    th = THEMES[name]
    sheet = Sheet(COLUMN, 120, th["ground"])
    t = sheet.tile(0, 0, COLUMN, 120)
    panel(t, 0.5, 0.5, COLUMN - 0.5, 119.5, th, shadow=False)
    frame(t, 18, 26, 64, 80, "Mythical", face, th, type_="Strength")
    button(t, 104, 26, 124, 44, "Break", th, "failed", "No free chamber")
    gem(t, 250, 40, 6.5, ss.TYPES["Strength"])
    gem(t, 250, 76, 10.0, ss.TYPES["Strength"])
    lead_card(t, 284, 29, th, face, "Rook", 60, 0.22, 0.85, rarity="Mythical", width=270)
    return sheet


def main():
    out = bl.out_dir()
    face = portrait()
    height = 84 + 2 * 158 + 22 + 158 + 22 + 180 + 22 + 158 + 196
    sheet = Sheet(MARGIN * 2 + COLUMN * 2 + GUTTER, height, "#33363E")
    t = sheet.tile(0, 0, sheet.w, 56)
    t.text(MARGIN, 14, 17, "Grow your Anime: the UI kit, a direction sheet", "#F3EFE6")
    t.text(MARGIN, 38, 10, "AR3. Drawn at 2 pixels a point. A panel cut from a shard, a bar that fills like light through a conduit, "
           "quiet until something happens. The gems, the class mark and the type face are stand-ins.", "#C9CDD6")
    bottom = 0.0
    for i, name in enumerate(THEMES):
        bottom = column(sheet, MARGIN + i * (COLUMN + GUTTER), name, face)
    t = sheet.tile(0, bottom, sheet.w, 196)
    t.text(MARGIN, 4, 10, "At 1 pixel a point, the smallest a phone would ever draw it:", "#C9CDD6")
    t.text(MARGIN, 104, 10, "The glance test at 1 pixel a point: the six frames out of order, 64 px wide, and a bar full, low and empty. "
           "Beside it, Mythical's red with the kit's other reds: a failed button and the Strength gem.", "#C9CDD6")
    strips = {name: reds(name, face) for name in THEMES}
    for i, strip in enumerate(strips.values()):  # their text joins the sheet's, at its own place and half its size
        ox, oy = MARGIN + i * (COLUMN + GUTTER) + COLUMN / 2 + 4, bottom + 122
        sheet.items += [dict(item, x=ox + item["x"] / 2, y=oy + item["y"] / 2, size=item["size"] / 2) for item in strip.items]
        rs.paste(sheet.px, rs.shrink(strip.px, 0.5), round(ox * K), round(oy * K))
    layers = text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items)
    for name, stroke in (("number", 3), ("number_small", 2)):
        if name in layers:
            number = layers.pop(name)
            over(sheet.px, c(STROKE), spread(number[..., 3], stroke))
            rs.paste(sheet.px, number, 0, 0)
    for layer in layers.values():
        rs.paste(sheet.px, layer, 0, 0)
    for i in range(len(THEMES)):  # the dusk and noon strips again, at half their size
        for j in range(2):
            x0, y0 = round((MARGIN + i * (COLUMN + GUTTER)) * K), round((84 + j * 158) * K)
            small = rs.shrink(sheet.px[y0:y0 + 150 * K, x0:x0 + round(COLUMN * K)].copy(), 0.5)
            rs.paste(sheet.px, small, round((MARGIN + i * (COLUMN + GUTTER) + j * (COLUMN / 2 + 4)) * K), round((bottom + 20) * K))
    for i, name in enumerate(THEMES):
        rs.paste(sheet.px, glance(name, face), round((MARGIN + i * (COLUMN + GUTTER)) * K), round((bottom + 122) * K))
    rs.save(sheet.px, out / "ui_sheet.png")
    rs.save(sheet.px[round((bottom + 118) * K):].copy(), out / "ui_glance.png")  # the glance strips alone, for a close read


if __name__ == "__main__":
    main()
