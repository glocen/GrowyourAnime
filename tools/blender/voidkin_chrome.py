"""AR29: the Voidkin screen's chrome made mature (the director, 2026-11-17, 13:16: "those ui need a massive polished it
looks childish and not good"). Three directions for the page rail and the top bar's buttons, each drawn over Faber's
phone captures of the real screen, beside today's: the Overview at the smallest phone, the Items page on an iPhone.

The feel line (AR29): the player opens their Voidkin, and the screen's frame reads like a premium anime game's menu:
sharp, quiet and heavy, its pages a set of cut tabs, with the chosen one lit by the seam's light. Never a toy's bubbles.

One family of page icons, our own drawing, shared by the three, so the pick is on the make:
  A, Lit plates: each page a plate cut like the bag's cells; the chosen one turns into a plate of light, as Equip is.
  B, The seam: no plates; the icons stand on a line of light down the rail's edge, and the chosen page is a tab of dark
     glass opening from it, lit where it meets the line.
  C, Blades: each page a leaning blade of lacquer, stacked; the chosen one slides out toward its page, its edge lit.
A page that isn't built yet is hidden until it opens (Modulo's proposal); each direction also shows its one quiet
lock state, for research to weigh, and the rail with all seven open at the smallest phone, the longest word chosen.
Only the chosen page shows its word, in mixed case as today's; the rail's pitch keeps room for War Emblems' two lines,
so the seven stand whole at the smallest phone and opening a page never moves the others.

blender -b --factory-startup --python tools/blender/voidkin_chrome.py -- <abs out>
Reads the captures in build/handoff/UI/voidkin/chrome/ (base_*.png). Writes, in <out>: voidkin_chrome_phone.png (the
eight screens at the capture's own size), voidkin_chrome_close.png (each make up close: the rails, the bars, the seven
and the lock state) and voidkin_chrome_icons.png (the icons large, idle and chosen; their phone size is on the screens).
The page words are Blender's own face, standing in for the game's.
Every number is a seed, in the capture's pixels at an iPhone (the smallest phone scales them by SMALL).
"""
import sys
import textwrap
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools" / "blender"))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

K = 3
ui.K = K
CHROME = REPO / "build" / "handoff" / "UI" / "voidkin" / "chrome"

# The seam's palette, as UIKit.Palettes.Seam has it (AR18).
SEAM = {
    "Panel": ("#1A1430", "#0C0A16"),
    "Edge": "#3B3358",
    "Facet": "#8F84B8",
    "Text": "#F1ECFF",
    "Soft": "#B9B0D6",
    "Faint": "#6F6790",
    "Channel": "#050409",
    "Button": ("#2A2244", "#1A1530"),
    "Light": "#EDE4FF",
    "Ink": "#0B0913",
}

BUILT = ("Overview", "Items", "Kit", "Stars")
LATER = ("Forge", "Jewels", "War Emblems")

# Each capture: where today's rail and top bar stand, measured on the capture (pixels), and the scale of its pieces.
# The smallest phone draws the same screen at about 0.8 of an iPhone's size.
SMALL = 0.8
BASES = {
    "overview": dict(file="base_overview.png", s=SMALL, chosen="Overview",
                     rail=(80, 60, 147, 352), cx=111.0, top=64.0, foot=346.0, stage=151.0,
                     bar=(250, 1, 480, 56), bar_y=(6.0, 50.0),
                     buttons=((256, 316), (322, 371), (376, 424), (430, 475))),
    "items": dict(file="base_items.png", s=1.0, chosen="Items",
                  rail=(86, 62, 163, 440), cx=121.0, top=68.0, foot=432.0, stage=170.0,
                  bar=(240, 1, 506, 60), bar_y=(4.0, 54.0),
                  buttons=((258, 336), (343, 390), (399, 445), (454, 501))),
}


# --- a screen: the capture enlarged K times, painted in its own pixels ------------------------------------------------

def enlarge(a):
    """K times, smoothed, so the capture underneath reads as it does on a phone."""
    r = np.repeat(np.repeat(a, K, axis=0), K, axis=1)
    for axis in (0, 1):
        r = (np.roll(r, 1, axis=axis) + r + np.roll(r, -1, axis=axis)) / 3.0
    return r


class Area:
    """A window on a screen, measured in the capture's pixels, its X and Y the screen's own."""

    def __init__(self, px, x0, y0, x1, y1):
        a, b = max(int(x0 * K), 0), max(int(y0 * K), 0)
        e, f = min(int(np.ceil(x1 * K)), px.shape[1]), min(int(np.ceil(y1 * K)), px.shape[0])
        self.px = px[b:f, a:e]
        gy, gx = np.mgrid[b:f, a:e]
        self.X, self.Y = ((gx + 0.5) / K).astype(np.float32), ((gy + 0.5) / K).astype(np.float32)

    def poly(self, pts):
        return ui.sd_polygon(self.X, self.Y, list(pts))

    def circle(self, x, y, r):
        return np.hypot(self.X - x, self.Y - y) - r

    def seg(self, a, b):
        return ui.sd_segment(self.X, self.Y, a, b)

    def paint(self, d, colour, alpha=1.0):
        ui.over(self.px, colour if not isinstance(colour, str) else c(colour), np.clip(0.5 - d * K, 0, 1) * alpha)

    def line(self, d, width, colour, alpha=1.0):
        """A line of `width` just inside an outline."""
        self.paint(np.abs(d + width / 2) - width / 2, colour, alpha)

    def glow(self, d, radius, colour, strength):
        ui.over(self.px, c(colour), strength * np.exp(-(np.maximum(d, 0) / radius) ** 1.4))

    def vramp(self, top, foot, y0, y1):
        t = np.clip((self.Y - y0) / max(y1 - y0, 1e-3), 0, 1)[..., None]
        return c(top) + (c(foot) - c(top)) * t

    def hramp(self, left, right, x0, x1):
        t = np.clip((self.X - x0) / max(x1 - x0, 1e-3), 0, 1)[..., None]
        return c(left) + (c(right) - c(left)) * t


def erase(px, box, pad=4, both=True):
    """Today's chrome taken out: each row filled from the clean ground either side of it, or from its left only
    where the right meets the stage."""
    x0, y0, x1, y1 = (int(round(v * K)) for v in box)
    left = px[y0:y1, x0 - pad * K:x0 - 1].mean(axis=1)
    right = px[y0:y1, x1 + 1:x1 + pad * K].mean(axis=1) if both else left
    t = np.linspace(0.0, 1.0, x1 - x0, dtype=np.float32)[None, :, None]
    px[y0:y1, x0:x1] = left[:, None, :] * (1 - t) + right[:, None, :] * t


def say(items, x, y, size, text, colour, align="CENTER", bold=0.0, space=1.0, shear=0.0):
    """Text with its capitals' top at y, in the capture's pixels; `bold` thickens it by that many of them."""
    items.append(dict(x=x, y=y, size=size, text=text, colour=colour, align=align, layer="plain", shear=shear,
                      bold=bold * K, space=space))


# --- the icons: one family, our own drawing ---------------------------------------------------------------------------
# Each in a box of 2 units (-1 to 1, y down), drawn at a half-size `r` in pixels. Solid shapes, one weight of line,
# every corner cut or sharp: the kit's shard language, never a stock pictogram.

W = 0.19   # the family's line, of r


def star4(u, v, tall, wide, waist):
    return [(u, v - tall), (u + waist, v - waist), (u + wide, v), (u + waist, v + waist), (u, v + tall * 0.92),
            (u - waist, v + waist), (u - wide, v), (u - waist, v - waist)]


def diamond(u, v, h):
    return [(u, v - h), (u + h * 0.8, v), (u, v + h), (u - h * 0.8, v)]


def along_axis(points, cu, cv, angle):
    """Points given along a line (s) and across it (n), laid at a centre and an angle (degrees, 0 to the right, y down)."""
    ca, sa = np.cos(np.radians(angle)), np.sin(np.radians(angle))
    return [(cu + s * ca - n * sa, cv + s * sa + n * ca) for s, n in points]


def glyph(a, name, cx, cy, r, colour, alpha=1.0, on=False):
    def P(pts):
        return a.poly([(cx + u * r, cy + v * r) for u, v in pts])

    def C(u, v, rad):
        return a.circle(cx + u * r, cy + v * r, rad * r)

    def S(pts, w):
        return np.minimum.reduce([a.seg((cx + p[0] * r, cy + p[1] * r), (cx + q[0] * r, cy + q[1] * r))
                                  for p, q in zip(pts, pts[1:])]) - w * r / 2

    cut = W * r * 0.9  # the gap between a glyph's parts
    if name == "Overview":
        # a bust in a cut frame: the Voidkin's own card
        frame = P(ui.cut_box(-0.92, -0.92, 0.92, 0.92, 0.42, 0, 0.42, 0))
        ring = np.abs(frame + W * r / 2) - W * r / 2
        head = C(0, -0.22, 0.3)
        bust = np.maximum(P([(-0.7, 1.0), (-0.62, 0.5), (-0.3, 0.26), (0.3, 0.26), (0.62, 0.5), (0.7, 1.0)]),
                          -(C(0, -0.22, 0.3) - cut))
        bust = np.maximum(bust, frame + W * r + cut * 0.8)
        d = np.minimum.reduce([ring, head, bust])
    elif name == "Items":
        # the chest: a raked lid over its box, a diamond clasp across the seam
        lid = P([(-0.9, -0.2), (-0.7, -0.74), (0.7, -0.74), (0.9, -0.2)])
        box = P(ui.cut_box(-0.9, -0.2 + W * 0.9, 0.9, 0.86, 0, 0, 0.26, 0))
        clasp = P(diamond(0, -0.14, 0.38))
        d = np.maximum(np.minimum(lid, box), -(clasp - cut * 0.5))
        d = np.minimum(d, P(diamond(0, -0.14, 0.24)))
    elif name == "Kit":
        # a blade drawn through its own slash: what a Voidkin does
        blade = P(along_axis([(1.12, 0), (0.78, 0.17), (-0.34, 0.17), (-0.34, -0.17), (0.78, -0.17)], -0.05, 0.05, -45))
        guard = P(along_axis([(-0.36, 0.42), (-0.5, 0.42), (-0.5, -0.42), (-0.36, -0.42)], -0.05, 0.05, -45))
        grip = P(along_axis([(-0.5, 0.09), (-0.98, 0.09), (-0.98, -0.09), (-0.5, -0.09)], -0.05, 0.05, -45))
        # the swing's arc, from the grip round to the tip, thickest at its middle
        slash = np.maximum(C(-0.02, -0.02, 0.98), -C(0.2, 0.2, 0.98))
        slash = np.maximum(slash, -(np.minimum.reduce([blade, guard, grip]) - cut))
        d = np.minimum.reduce([blade, guard, grip, slash])
    elif name == "Stars":
        # a tall four-point star with a small one beside it: the next star waiting
        big = P(star4(-0.14, 0.1, 0.98, 0.7, 0.17))
        small = P(star4(0.62, -0.6, 0.36, 0.3, 0.08))
        d = np.minimum(big, np.maximum(small, -(big - cut)))
    elif name == "Forge":
        # an anvil with a spark over its face
        anvil = P([(-0.5, -0.4), (0.96, -0.4), (0.96, -0.1), (0.42, -0.02), (0.26, 0.18), (0.26, 0.46), (0.66, 0.6),
                   (0.66, 0.84), (-0.56, 0.84), (-0.56, 0.6), (-0.18, 0.46), (-0.18, 0.18), (-0.36, 0.0),
                   (-0.62, -0.12), (-1.02, -0.36)])
        spark = P(star4(0.42, -0.8, 0.26, 0.2, 0.05))
        d = np.minimum(anvil, spark)
    elif name == "Jewels":
        # a cut gem, side on: crown and pavilion apart at the girdle, two facets cut
        crown = P([(-0.5, -0.66), (0.5, -0.66), (0.94, -0.2), (-0.94, -0.2)])
        pavilion = P([(-0.94, -0.2 + W * 0.9), (0.94, -0.2 + W * 0.9), (0, 0.96)])
        facets = np.minimum.reduce([a.seg((cx - 0.16 * r, cy - 0.66 * r), (cx - 0.36 * r, cy - 0.2 * r)),
                                    a.seg((cx + 0.16 * r, cy - 0.66 * r), (cx + 0.36 * r, cy - 0.2 * r)),
                                    a.seg((cx - 0.36 * r, cy - 0.02 * r), (cx, cy + 0.96 * r)),
                                    a.seg((cx + 0.36 * r, cy - 0.02 * r), (cx, cy + 0.96 * r))]) - cut * 0.35
        d = np.maximum(np.minimum(crown, pavilion), -facets)
    elif name == "War Emblems":
        # a swallowtailed banner on its bar, a diamond device on it
        bar = P(ui.cut_box(-0.86, -0.98, 0.86, -0.78, 0, 0, 0, 0))
        banner = P([(-0.62, -0.78 + W * 0.9), (0.62, -0.78 + W * 0.9), (0.62, 0.98), (0, 0.6), (-0.62, 0.98)])
        device = P(diamond(0, -0.06, 0.34))
        d = np.minimum(bar, np.maximum(banner, -(device - cut * 0.5)))
        d = np.minimum(d, P(diamond(0, -0.06, 0.2)))
    elif name == "Back":
        d = P([(0.4, -0.78), (0.0, 0.0), (0.4, 0.78), (0.1, 0.78), (-0.3, 0.0), (0.1, -0.78)])
    elif name == "Favourite":
        # a heart cut from straight edges; drawn in outline when off, solid when on
        heart = P([(0, -0.42), (0.32, -0.8), (0.68, -0.8), (0.96, -0.48), (0.96, -0.08), (0, 0.86), (-0.96, -0.08),
                   (-0.96, -0.48), (-0.68, -0.8), (-0.32, -0.8)])
        d = heart if on else np.abs(heart + W * r * 0.55) - W * r * 0.55
    elif name == "Lock":
        lift = 0.0 if on else -0.24
        shackle = S([(-0.44, -0.12 + lift), (-0.44, -0.52 + lift), (-0.24, -0.84 + lift), (0.24, -0.84 + lift),
                     (0.44, -0.52 + lift), (0.44, -0.12 if on else -0.42 + lift)], W * 1.05)
        body = P(ui.cut_box(-0.76, -0.14, 0.76, 0.88, 0.22, 0, 0.22, 0))
        d = np.maximum(np.minimum(shackle, body), -(P(diamond(0, 0.36, 0.2))))
    elif name == "Rename":
        pen = P(along_axis([(-0.98, 0), (-0.56, 0.2), (0.98, 0.2), (0.98, -0.2), (-0.56, -0.2)], 0.0, -0.08, 135))
        band = np.abs(np.asarray((a.X - cx) * 0.7071 - (a.Y - cy - (-0.08) * r) * 0.7071, dtype=np.float32) -
                      0.5 * r) - cut * 0.4
        pen = np.maximum(pen, -band)
        under = P(ui.cut_box(-0.06, 0.78, 0.96, 0.96, 0, 0, 0, 0))
        d = np.minimum(pen, under)
    else:
        raise KeyError(name)
    a.paint(d, colour, alpha)
    return d


# --- the three makes --------------------------------------------------------------------------------------------------

def layout(base, pages, chosen, word, gap_word):
    """Each page's tab, top to foot: the pitch holds the seven whole at this phone, so opening a page never moves
    the others."""
    s = base["s"]
    reserve = word * max(len(lines(page)) for page in BUILT + LATER)  # room for the longest word, chosen
    pitch = min(50.0 * s, (base["foot"] - base["top"] - reserve) / 7)
    y, out = base["top"], []
    for page in pages:
        out.append((page, y, page == chosen))
        y += pitch + (gap_word * len(lines(page)) if page == chosen else 0)
    return pitch, out


WORD = 13.5   # the chosen page's word, as today's: mixed case, bold, read at the smallest phone


def lines(page):
    """A long word takes two lines under its tab: War Emblems."""
    return page.split() if len(page) > 9 else [page]


def word_at(items, x, y, s, page, shear=0.0):
    for i, line in enumerate(lines(page)):
        say(items, x, y + i * WORD * 1.05 * s, WORD * s, line, SEAM["Text"], bold=0.4, shear=shear)


def make_a(px, base, items, pages, chosen, locked=(), marks=None):
    """A, Lit plates."""
    s, cx = base["s"], base["cx"]
    word = 17.0 * s
    pitch, tabs = layout(base, pages, chosen, word, word)
    x0, x1 = base["rail"][0], base["rail"][2]
    a = Area(px, x0 - 4, base["rail"][1], x1 + 12, base["rail"][3])
    hw, h = 23.0 * s, pitch - 9.0 * s
    k = 9.0 * s
    for page, y, lit in tabs:
        d = a.poly(ui.cut_box(cx - hw, y, cx + hw, y + h, k, 0, k, 0))
        if page in locked:
            a.line(d, 1.0 * s, SEAM["Edge"], 0.9)
            glyph(a, page, cx, y + h / 2, 9.5 * s, SEAM["Faint"], 0.55)
            lock_tag(a, cx + hw - 3.5 * s, y + h - 3.5 * s, s)
            continue
        if lit:
            a.glow(d, 7.0 * s, SEAM["Light"], 0.32)
            a.paint(d, a.vramp("#FFFFFF", SEAM["Light"], y, y + h))
            # the page's light runs on into its panel: a seam from the plate to the stage's edge
            ys = y + h / 2
            end = base["stage"] - 4.0 * s
            stub = np.maximum(np.abs(a.Y - ys) - 0.75 * s, np.maximum(cx + hw - 1 - a.X, a.X - end))
            fall = np.clip(1.0 - (a.X - (cx + hw)) / (end - cx - hw), 0.25, 1.0)
            a.glow(np.maximum(stub, 0) + 0.0, 2.5 * s, SEAM["Light"], 0.4 * fall)
            a.paint(stub, SEAM["Light"], fall)
            glyph(a, page, cx, y + h / 2, 10.5 * s, SEAM["Ink"])
            word_at(items, cx, y + h + 4.0 * s, s, page)
        else:
            a.paint(d, a.vramp(SEAM["Button"][0], SEAM["Button"][1], y, y + h), 0.94)
            a.line(d, 1.0 * s, SEAM["Edge"])
            top = np.maximum(np.abs(a.Y - (y + 1.2 * s)) - 0.5 * s, d + 0.6 * s)
            a.paint(np.maximum(top, -(a.X - (cx - hw + k))), SEAM["Facet"], 0.45)
            glyph(a, page, cx, y + h / 2, 10.0 * s, SEAM["Soft"])
    bar_a(px, base, items, marks or {})


def bar_a(px, base, items, marks):
    s = base["s"]
    y0, y1 = base["bar_y"]
    b0, b1 = base["bar"][0], base["bar"][2]
    a = Area(px, b0 - 2, 0, b1 + 4, y1 + 6)
    k = 8.0 * s
    for (x0, x1), name in zip(base["buttons"], ("Back", "Favourite", "Lock", "Rename")):
        on = marks.get(name, False)
        d = a.poly(ui.cut_box(x0, y0, x1, y1, k, 0, k, 0))
        mid = (y0 + y1) / 2
        if on:
            a.glow(d, 6.0 * s, SEAM["Light"], 0.3)
            a.paint(d, a.vramp("#FFFFFF", SEAM["Light"], y0, y1))
            ink = SEAM["Ink"]
        else:
            a.paint(d, a.vramp(SEAM["Button"][0], SEAM["Button"][1], y0, y1), 0.94)
            a.line(d, 1.0 * s, SEAM["Edge"])
            top = np.maximum(np.abs(a.Y - (y0 + 1.2 * s)) - 0.5 * s, d + 0.6 * s)
            a.paint(np.maximum(top, -(a.X - (x0 + k))), SEAM["Facet"], 0.45)
            ink = SEAM["Text"] if name == "Back" else SEAM["Soft"]
        if name == "Back":
            glyph(a, "Back", x0 + 15.0 * s, mid, 7.0 * s, ink)
            say(items, (x0 + x1) / 2 + 7.0 * s, mid - 4.7 * s, 15.0 * s, "BACK", ink, bold=0.5, space=1.1)
        else:
            glyph(a, name, (x0 + x1) / 2, mid, 10.5 * s, ink, on=on)


def seam_x(base):
    return base["rail"][2] - 1.0 * base["s"]


def make_b(px, base, items, pages, chosen, locked=(), marks=None):
    """B, The seam."""
    s, cx = base["s"], base["cx"] - 4.0 * base["s"]
    word = 17.0 * s
    pitch, tabs = layout(base, pages, chosen, word, 0.0)
    pitch_tab = pitch
    x0, x1 = base["rail"][0], base["rail"][2]
    sx = seam_x(base)
    a = Area(px, x0 - 4, base["rail"][1], x1 + 12, base["rail"][3])
    chosen_y = next(y for page, y, lit in tabs if lit) + pitch_tab / 2 + word / 2
    # the line of light down the rail's edge, strongest at the chosen page
    line = np.maximum(np.abs(a.X - sx) - 0.5 * s, np.abs(a.Y - (base["top"] + base["foot"]) / 2) -
                      (base["foot"] - base["top"]) / 2)
    strength = 0.16 + 0.84 * np.exp(-((a.Y - chosen_y) / (70.0 * s)) ** 2)
    a.glow(np.abs(a.X - sx), 3.0 * s, SEAM["Light"], 0.28 * strength * (line < 2))
    a.paint(line, SEAM["Light"], strength)
    y = base["top"]
    for page, _, lit in tabs:
        h = pitch_tab + (word * len(lines(page)) if lit else 0.0)
        mid = y + h / 2
        if lit:
            t0, t1 = y + 2.0 * s, y + h - 2.0 * s
            d = a.poly([(x0 + 4.0 * s, t0 + 12.0 * s), (x0 + 4.0 * s + 12.0 * s, t0), (sx, t0), (sx, t1),
                        (x0 + 8.0 * s, t1), (x0 + 4.0 * s, t1 - 4.0 * s)])
            a.paint(d, a.vramp(SEAM["Panel"][0], SEAM["Panel"][1], t0, t1), 0.97)
            a.paint(d, a.hramp(SEAM["Light"], SEAM["Light"], x0, sx),
                    np.clip((a.X - (x0 + 4.0 * s)) / (sx - x0 - 4.0 * s), 0, 1) ** 2.0 * 0.34)
            a.line(d, 1.0 * s, SEAM["Edge"])
            # where it meets the line, the line runs bright and wide
            meet = np.maximum(np.abs(a.X - sx) - 1.3 * s, np.abs(a.Y - mid) - (t1 - t0) / 2)
            a.glow(meet, 7.0 * s, SEAM["Light"], 0.5)
            a.paint(meet, SEAM["Light"])
            glyph(a, page, cx, t0 + 16.0 * s, 11.0 * s, SEAM["Text"])
            word_at(items, cx, t1 - 14.0 * s - (len(lines(page)) - 1) * WORD * 1.05 * s, s, page)
        else:
            if page in locked:
                glyph(a, page, cx, mid, 10.0 * s, SEAM["Faint"], 0.45)
                lock_tag(a, cx + 9.0 * s, mid + 8.0 * s, s)
            else:
                glyph(a, page, cx, mid, 10.5 * s, SEAM["Soft"])
            # a short rule at each page on the line, an index's mark
            tick = np.maximum(np.abs(a.Y - mid) - 0.5 * s, np.maximum(a.X - sx, sx - 6.0 * s - a.X))
            a.paint(tick, SEAM["Light"], 0.5)
        y += h
    bar_b(px, base, items, marks or {})


def bar_b(px, base, items, marks):
    s = base["s"]
    y0, y1 = base["bar_y"]
    b0, b1 = base["bar"][0], base["bar"][2]
    a = Area(px, b0 - 2, 0, b1 + 4, y1 + 6)
    mid = (y0 + y1) / 2
    (bx0, bx1), rest = base["buttons"][0], base["buttons"][1:]
    # Back: no plate, its word on the band over a line of light
    glyph(a, "Back", bx0 + 11.0 * s, mid, 7.0 * s, SEAM["Text"])
    say(items, bx0 + 22.0 * s, mid - 4.7 * s, 15.0 * s, "BACK", SEAM["Text"], align="LEFT", bold=0.5, space=1.1)
    under = np.maximum(np.abs(a.Y - (y1 - 3.0 * s)) - 0.5 * s, np.maximum(bx0 + 4 * s - a.X, a.X - (bx1 - 4 * s)))
    prof = 0.15 + 0.85 * np.exp(-((a.X - (bx0 + bx1) / 2) / (22.0 * s)) ** 2)
    a.glow(np.maximum(under, 0), 2.5 * s, SEAM["Light"], 0.3 * prof)
    a.paint(under, SEAM["Light"], prof)
    # the three marks share one cut channel, split by hairlines
    x0, x1 = rest[0][0], rest[-1][1]
    k = 8.0 * s
    d = a.poly(ui.cut_box(x0, y0 + 3 * s, x1, y1 - 3 * s, k, 0, k, 0))
    a.paint(d, c(SEAM["Channel"]), 0.72)
    a.line(d, 1.0 * s, SEAM["Edge"])
    for (m0, m1), (n0, _) in zip(rest, rest[1:]):
        split = np.maximum(np.abs(a.X - (m1 + n0) / 2) - 0.5 * s, np.abs(a.Y - mid) - (y1 - y0) / 2 + 12.0 * s)
        a.paint(split, SEAM["Edge"])
    for (m0, m1), name in zip(rest, ("Favourite", "Lock", "Rename")):
        on = marks.get(name, False)
        glyph(a, name, (m0 + m1) / 2, mid, 10.5 * s, SEAM["Light"] if on else SEAM["Soft"], on=on)
        if on:
            lit = np.maximum(np.abs(a.Y - (y1 - 4.2 * s)) - 0.6 * s, np.abs(a.X - (m0 + m1) / 2) - 9.0 * s)
            a.glow(np.maximum(lit, 0), 3.0 * s, SEAM["Light"], 0.45)
            a.paint(lit, SEAM["Light"])


SHEAR = 0.24  # how far a blade leans: its top runs this much of its height to the right


def blade(a, x0, y0, x1, y1, lean):
    k = (y1 - y0) * lean
    return a.poly([(x0 + k, y0), (x1 + k, y0), (x1, y1), (x0, y1)])


def make_c(px, base, items, pages, chosen, locked=(), marks=None):
    """C, Blades."""
    s, cx = base["s"], base["cx"] - 3.0 * base["s"]
    word = 17.0 * s
    pitch, tabs = layout(base, pages, chosen, word, word)
    x0, x1 = base["rail"][0], base["rail"][2]
    a = Area(px, x0 - 4, base["rail"][1], x1 + 12, base["rail"][3])
    hw, h = 22.0 * s, pitch - 5.0 * s
    for page, y, lit in tabs:
        shift = 7.0 * s if lit else 0.0
        bx0, bx1 = cx - hw + shift - h * SHEAR / 2, cx + hw + shift - h * SHEAR / 2
        d = blade(a, bx0, y, bx1, y + h, SHEAR)
        mid = y + h / 2
        if page in locked:
            a.paint(d, c(SEAM["Channel"]), 0.5)
            a.line(d, 1.0 * s, SEAM["Edge"], 0.8)
            glyph(a, page, cx, mid, 8.5 * s, SEAM["Faint"], 0.5)
            lock_tag(a, cx + 12.0 * s, mid + 7.0 * s, s)
            continue
        a.paint(d, a.vramp(SEAM["Button"][0], SEAM["Button"][1], y, y + h), 0.95)
        a.line(d, 1.0 * s, SEAM["Edge"])
        top = np.maximum(np.abs(a.Y - (y + 1.0 * s)) - 0.55 * s, d + 0.5 * s)
        a.paint(top, SEAM["Facet"], 0.55)
        if lit:
            # light washes the blade from its leading edge, and the edge itself is a bar of light
            a.paint(d, c(SEAM["Light"]), np.clip((a.X - bx0) / (bx1 - bx0), 0, 1) ** 2.4 * 0.32)
            k = h * SHEAR
            edge = a.poly([(bx1 + k - 3.2 * s, y), (bx1 + k, y), (bx1, y + h), (bx1 - 3.2 * s, y + h)])
            a.glow(edge, 6.0 * s, SEAM["Light"], 0.55)
            a.paint(edge, SEAM["Light"])
            glyph(a, page, cx + shift - 1.5 * s, mid, 10.0 * s, SEAM["Text"])
            word_at(items, cx + shift - 2.0 * s, y + h + 4.0 * s, s, page, shear=0.2)
        else:
            glyph(a, page, cx, mid, 10.0 * s, SEAM["Soft"])
    bar_c(px, base, items, marks or {})


def bar_c(px, base, items, marks):
    s = base["s"]
    y0, y1 = base["bar_y"]
    b0, b1 = base["bar"][0], base["bar"][2]
    a = Area(px, b0 - 2, 0, b1 + 4, y1 + 6)
    mid = (y0 + y1) / 2
    lean = 0.22
    for (x0, x1), name in zip(base["buttons"], ("Back", "Favourite", "Lock", "Rename")):
        on = marks.get(name, False)
        k = (y1 - y0) * lean
        d = blade(a, x0, y0, x1 - k, y1, lean)
        a.paint(d, a.vramp(SEAM["Button"][0], SEAM["Button"][1], y0, y1), 0.95)
        a.line(d, 1.0 * s, SEAM["Edge"])
        top = np.maximum(np.abs(a.Y - (y0 + 1.0 * s)) - 0.55 * s, d + 0.5 * s)
        a.paint(top, SEAM["Facet"], 0.55)
        cxm = (x0 + x1) / 2
        if on:
            edge = a.poly([(x1 - 3.0 * s, y0), (x1, y0), (x1 - k, y1), (x1 - k - 3.0 * s, y1)])
            a.glow(edge, 5.0 * s, SEAM["Light"], 0.5)
            a.paint(edge, SEAM["Light"])
        ink = SEAM["Light"] if on else (SEAM["Text"] if name == "Back" else SEAM["Soft"])
        if name == "Back":
            glyph(a, "Back", x0 + 14.0 * s, mid, 7.0 * s, ink)
            say(items, cxm + 4.0 * s, mid - 4.7 * s, 15.0 * s, "BACK", ink, bold=0.5, space=1.1, shear=0.2)
        else:
            glyph(a, name, cxm - 1.5 * s, mid, 10.5 * s, ink, on=on)


def lock_tag(a, x, y, s):
    """A page that opens later: its small lock, in the corner of its tab."""
    glyph(a, "Lock", x, y, 4.2 * s, SEAM["Faint"], 0.9, on=True)


MAKES = {"A": ("A, Lit plates", make_a), "B": ("B, The seam", make_b), "C": ("C, Blades", make_c)}


# --- the screens and the sheets ---------------------------------------------------------------------------------------

def screen(key, make, pages=BUILT, chosen=None, locked=(), marks=None):
    """One capture with a direction's chrome over it, at K times its size."""
    base = BASES[key]
    px = enlarge(rs.load(CHROME / base["file"]))
    if make is None:
        return px
    erase(px, base["rail"], both=False)
    erase(px, base["bar"])
    items = []
    make(px, base, items, pages, chosen or base["chosen"], locked, marks)
    for layer in ui.text_layers(px.shape[1], px.shape[0], items).values():
        rs.paste(px, layer, 0, 0)
    return px


def crop(px, box):
    x0, y0, x1, y1 = (int(round(v * K)) for v in box)
    return px[y0:y1, x0:x1].copy()


class Board:
    """A review sheet, in its own pixels, with its words."""

    def __init__(self, w, h, ground="#100E14"):
        self.px = rs.canvas(w, h, tuple(c(ground)))
        self.items = []

    def put(self, img, x, y):
        rs.paste(self.px, img, int(x), int(y))

    def text(self, x, y, size, text, colour="#EDE4FF", bold=0.0, align="LEFT"):
        self.items.append(dict(x=x / K, y=y / K, size=size / K, text=text, colour=colour, align=align, layer="plain",
                               shear=0.0, bold=bold / K, space=1.0))

    def save(self, path, height=None):
        if height:
            self.px = self.px[:int(height)].copy()
        for layer in ui.text_layers(self.px.shape[1], self.px.shape[0], self.items).values():
            rs.paste(self.px, layer, 0, 0)
        rs.save(self.px, path)
        print("wrote", path, self.px.shape)


def phone_sheet(out, shots):
    """The eight screens at the capture's own size, a column a page, a row a make."""
    gap, head = 24, 92
    w, h = 950, 450
    b = Board(gap * 3 + w * 2, head + (h + 50) * 4 + gap)
    b.text(gap, 18, 26, "Grow your Anime: the Voidkin screen's chrome, three directions (AR29)", bold=0.6)
    lead = ("Each over Faber's capture of the real screen at its own size: the Overview at the smallest phone, the Items "
            "page on an iPhone. Only the rail and the top bar's buttons are drawn; the rest is the build as it stands. "
            "The pages not built yet are hidden (Modulo's proposal); the lock state and the seven are on the close sheet.")
    for i, line in enumerate(textwrap.wrap(lead, 150)):
        b.text(gap, 52 + i * 18, 14, line, "#B9B0D6")
    y = head
    for key, label in (("Today", "Today's"), ("A", MAKES["A"][0]), ("B", MAKES["B"][0]), ("C", MAKES["C"][0])):
        b.text(gap, y + 12, 18, label, bold=0.4)
        for i, page in enumerate(("overview", "items")):
            b.put(rs.shrink(shots[key][page], 1 / K), gap + i * (w + gap), y + 40)
        y += h + 50
    b.save(out / "voidkin_chrome_phone.png")


def close_sheet(out, shots, sevens, locks):
    """Each make up close, at K times the capture: the rail and the bar on both pages, then the seven and the lock."""
    gap = 30
    rail_i = (82, 60, 175, 300)
    rail_o = (76, 58, 158, 350)
    bar_i = (236, 0, 512, 62)
    widths = (rail_i[2] - rail_i[0]) * K, (rail_o[2] - rail_o[0]) * K
    col = gap + widths[0] + gap + widths[1] + gap + (bar_i[2] - bar_i[0]) * K
    b = Board(max(col + gap, gap + 6 * (widths[1] + 20) + 3 * 20), 140 + 4 * ((rail_o[3] - rail_o[1]) * K + 70) + (rail_o[3] - rail_o[1]) * K + 200)
    b.text(gap, 18, 26, "AR29 up close: each make three times the capture's size", bold=0.6)
    lead = ("Left, the Items page's rail on an iPhone; middle, the Overview's at the smallest phone; right, the top bar "
            "(Back, favourite, lock, rename) with favourite and lock shown on, under it as the capture has them. "
            "Last row: each make with all seven pages open at the smallest phone, War Emblems chosen, and its lock state.")
    for i, line in enumerate(textwrap.wrap(lead, 170)):
        b.text(gap, 54 + i * 20, 15, line, "#B9B0D6")
    y = 120
    for key, label in (("Today", "Today's"), ("A", MAKES["A"][0]), ("B", MAKES["B"][0]), ("C", MAKES["C"][0])):
        b.text(gap, y, 20, label, bold=0.4)
        y += 34
        x = gap
        b.put(crop(shots[key]["items"], rail_i), x, y)
        x += widths[0] + gap
        b.put(crop(shots[key]["overview"], rail_o), x, y)
        x += widths[1] + gap
        b.put(crop(shots[key]["items"], bar_i), x, y)
        if key in shots and "on" in shots[key]:
            b.put(crop(shots[key]["on"], bar_i), x, y + (bar_i[3] - bar_i[1]) * K + 16)
            b.text(x, y + 2 * (bar_i[3] - bar_i[1]) * K + 24, 14, "favourite and lock on", "#B9B0D6")
        y += (rail_o[3] - rail_o[1]) * K + 36
    b.text(gap, y, 20, "All seven open (War Emblems chosen), and the lock state, at the smallest phone", bold=0.4)
    y += 34
    x = gap
    for key in ("A", "B", "C"):
        for img, note in ((sevens[key], "seven"), (locks[key], "locked")):
            b.put(crop(img, rail_o), x, y)
            b.text(x, y + (rail_o[3] - rail_o[1]) * K + 8, 15, f"{key}, {note}", "#B9B0D6")
            x += widths[1] + 20
        x += 20
    b.save(out / "voidkin_chrome_close.png", y + (rail_o[3] - rail_o[1]) * K + 40)


def icon_sheet(out):
    """The family alone: each icon idle and chosen in each make's colours, at the rail's size and four times it."""
    names = BUILT + LATER + ("Back", "Favourite", "Lock", "Rename")
    cell = 46
    big = 4
    w = 40 + len(names) * (cell * big * K // 3 + 16)
    px = rs.canvas(w, 60 + 2 * (cell * big * K // 3 + 30), tuple(c("#100E14")))
    items = []
    x = 20
    for name in names:
        size = cell * big * K // 3
        for row, (ground, ink, on) in enumerate(((SEAM["Button"][1], SEAM["Soft"], False),
                                                 (SEAM["Light"], SEAM["Ink"], True))):
            y = 60 + row * (size + 30)
            a = Area(px, x / K, y / K, (x + size) / K, (y + size) / K)
            a.paint(a.poly(ui.cut_box(x / K, y / K, (x + size) / K, (y + size) / K, 14, 0, 14, 0)), c(ground))
            glyph(a, name, (x + size / 2) / K, (y + size / 2) / K, size / K * 0.34, ink, on=on)
        items.append(dict(x=x / K, y=20 / K, size=14 / K, text=name, colour="#EDE4FF", align="LEFT", layer="plain",
                          shear=0.0, bold=0.1, space=1.0))
        x += size + 16
    for layer in ui.text_layers(px.shape[1], px.shape[0], items).values():
        rs.paste(px, layer, 0, 0)
    rs.save(px, out / "voidkin_chrome_icons.png")
    print("wrote", out / "voidkin_chrome_icons.png", px.shape)


def main():
    out = bl.out_dir()
    shots = {"Today": {page: screen(page, None) for page in BASES}}
    on = {"Favourite": True, "Lock": True}
    for key, (_, make) in MAKES.items():
        shots[key] = {page: screen(page, make) for page in BASES}
        shots[key]["on"] = screen("items", make, marks=on)
    sevens = {key: screen("overview", make, pages=BUILT + LATER, chosen="War Emblems")
              for key, (_, make) in MAKES.items()}
    locks = {key: screen("overview", make, pages=BUILT + LATER, locked=LATER) for key, (_, make) in MAKES.items()}
    phone_sheet(out, shots)
    close_sheet(out, shots, sevens, locks)
    icon_sheet(out)


if __name__ == "__main__":
    main()
