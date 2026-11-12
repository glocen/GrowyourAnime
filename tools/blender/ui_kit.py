"""AR3, the UI kit's images (docs/asset-requests.md, AR3; docs/ui.md): the kit as slices with their insets, the six
rarity frames in two cuts, the five type gems, the five class icons, the four element marks, the coin, the bolt and
the small marks, with the sheets that review them.

A slice is white wherever a palette colours it, so a palette is a row of colours and never new images: the engine
tints a slice (ImageColor3, or a UIGradient for a panel's two colours). A rarity's frame, a gem and a mark keep their
own colours on every palette. `panel`, `button`, `bar` and `frame` below build a piece from its slices alone, in the
order the engine must layer them: the palettes sheet is made that way, so what it shows is what the slices give.

Drawn at 4 pixels a point (SliceScale 0.25). No image carries text: the sheets' labels are Blender's face, the game's
text is Roblox's. Nothing is taken from anywhere else.

Run: blender -b --factory-startup --python tools/blender/ui_kit.py -- build/scratch/modulo/ui/kit
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import BLACK, WHITE, c, cut_box  # noqa: E402

K = 4  # pixels a point in a slice
SK = 2  # pixels a point on a review sheet
DARK = "#0A0B0F"  # a channel baked into a slice: it stays dark under any tint
INK = "#F3EFE6"
SEAT = dict(well="#0B0C10", edge="#434A57")  # a class mark's seat: the same dark inlay on every palette
BOX = 32.0  # an icon's canvas, in points
DEEP = {"#B3122E": "#C2102E", "#D8A23C": "#C98A1E"}  # a coloured rarity's light on a pale panel, by its metal's deep end

# A palette is one row. Graphite and Pearl are the sheet's (ui_sheet.THEMES). The two below are rooms of their own
# (the director, 2026-11-12: some screens get a palette of their own, chosen here, so long as the whole holds
# together). What a palette may change: a panel's body, its edge and glint, the ink, and `accent`, the light a button
# and a selection burn with. What it never changes: the cut, the frames, the gems and marks, health's ivory light,
# green and red, the numbers. The accent lights buttons and selections only: it never rings a portrait's frame, where
# Dynamo's yellow would be taken for Legendary's gold (research, 2026-11-12).
PALETTES = {
    "Graphite Dark": dict(ui.THEMES["Graphite Dark"], accent=ui.LIGHT, core=0.5),
    # a pale button can't be lit by a ring of ivory, so Pearl's selected one fills with ink and its label goes pale
    "Pearl Light": dict(ui.THEMES["Pearl Light"], accent=ui.LIGHT, core=0.9, selected=("#2A2E38", "#14161B"),
                        selectedText="#FAF7F0"),
    # the machine room: warm iron, and the light is the charge the bays make
    "Dynamo": dict(panel=("#2C261C", "#17130E"), alpha=0.94, edge="#62563F", facet="#B09F78", glint="#EBDCA6",
                   text="#F3EFE6", soft="#B8AD95", faint="#7F7660", channel="#080705", well="#0E0C09",
                   button=("#40382A", "#2B251B"), pressed=("#1F1B14", "#2C261C"), ground="#34302A",
                   accent=ui.CHARGE, core=0.5),
    # where a shard opens: the darkest room, violet, so the rarity's own light is the brightest thing in it
    "Void Violet": dict(panel=("#241B3A", "#110C1F"), alpha=0.95, edge="#5D4C8E", facet="#9E8CD2", glint="#DACDFF",
                        text="#F3EFE6", soft="#B2A8CA", faint="#7B7194", channel="#07050C", well="#0C0914",
                        button=("#392D5A", "#261D3F"), pressed=("#1B142C", "#241B3A"), ground="#2B2542",
                        accent="#DCCBFF", core=0.5),
}
SCREENS = {
    "Graphite Dark": "the HUD and its cards, the dock, Voidkin, one Voidkin, Regalia, confirm, error, toast, reward",
    "Dynamo": "the Breaker, the base's bays; later the Forge, the Condenser and the Lab",
    "Void Violet": "the reveal's card; later the Void Shop",
    "Pearl Light": "what's read like a printed page: the map, a shard's odds, where a stat's points come from",
}
IMAGES = {}


def blank(w, h):
    """A transparent tile, w by h points."""
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px[:] = 0
    return sheet.tile(0, 0, w, h)


def keep(name, t, tint=None, cut=None, pad=0.0, use="", ship=True):
    """`tint`: what colours a white slice. `cut`: its insets in points, left, top, right, bottom. `pad`: how far the
    image reaches past the piece's own box on every side."""
    IMAGES[name] = dict(px=t.px, w=t.w, h=t.h, tint=tint, cut=cut, pad=pad, use=use, ship=ship)


# --- the slices -----------------------------------------------------------------------------------------------------

def boxes(prefix, cuts, inset, shadow, bold=1.6, lip=0.0):
    """A cut box's layers: its body, its edge at two weights, its shadow. The bold edge is a bordered palette's black
    border. With `lip` it's a rule set that far in from the box's edge, so a lip of the pale body stands outside it:
    a black line at the very edge of a pale panel is lost against a dark world."""
    size, pad = inset * 2 + 8, 16.0
    ruled = "a bordered palette's edge" + (f": a rule {bold} wide, set {lip} in from the edge" if lip else "")
    for name, tint, draw, use in (("Fill", "body", lambda t, d: t.paint(d, WHITE), ""),
                                  ("Edge", "edge", lambda t, d: t.line(d, 1.0, WHITE), ""),
                                  ("EdgeBold", "edge", lambda t, d: t.line(d + lip, bold, WHITE), ruled)):
        t = blank(size, size)
        draw(t, t.poly(cut_box(0, 0, size, size, *cuts)))
        keep(prefix + name, t, tint, (inset,) * 4, use=use)
    t = blank(size + 2 * pad, size + 2 * pad)
    t.glow(t.poly(cut_box(pad, pad, pad + size, pad + size, *cuts)), shadow[0], BLACK, shadow[1])
    keep(prefix + "Shadow", t, None, (inset + pad,) * 4, pad, "under the body")
    return size


def panels():
    cut = 10.0
    cuts = (cut, cut * 0.3, cut, cut * 0.3)
    size = boxes("Panel", cuts, 12.0, (6.0, 0.3), bold=2.0, lip=1.5)
    t = blank(size, size)
    t.paint(ui.sd_segment(t.x, t.y, (0.5, cut), (cut, 0.5)) - 0.6, WHITE, 0.85)
    t.paint(ui.sd_segment(t.x, t.y, (size - cut, size - 0.5), (size - 0.5, size - cut)) - 0.5, WHITE, 0.35)
    keep("PanelGlint", t, "glint", (12.0,) * 4, use="the light on the two deep cuts; a pill wears it too")
    size = 36.0 + 8 + 12
    t = blank(size, size)
    t.paint(np.maximum(t.poly(cut_box(0, 0, size, size, *cuts)), t.x + t.y - cut * 3.4), WHITE)
    keep("PanelFacet", t, "facet", (36.0, 36.0, 12.0, 12.0), use="at 7 in 100, on a panel 48 points or more each way")


def buttons():
    size = boxes("Button", (8.0, 0.0, 8.0, 0.0), 10.0, (4.0, 0.22))
    inset, pad = (10.0,) * 4, 16.0

    def shape(t, o=0.0):
        return t.poly(cut_box(o, o, o + size, o + size, 8.0, 0.0, 8.0, 0.0))

    t = blank(size, size)
    d = shape(t)
    t.paint(np.maximum(d, size - 3.6 - t.y), c(DARK))
    t.paint(np.maximum(d + 0.8, size - 2.8 - t.y), WHITE)
    keep("ButtonBase", t, "accent", inset, use="the light on the lower edge that says it can be pressed")
    t = blank(size + 2 * pad, size + 2 * pad)
    t.glow(np.maximum(shape(t, pad) + 0.8, pad + size - 2.8 - t.y), 3.2, WHITE, 0.7)
    keep("ButtonBaseGlow", t, "accent", (inset[0] + pad,) * 4, pad, "at 45 in 100 at rest, whole when pressed")
    t = blank(size, size)
    t.lit(shape(t), 1.4, WHITE, c(DARK))
    keep("ButtonRing", t, "accent, green or red", inset,
         use="selected, succeeded, failed; waiting, with a window run round it; never round a portrait's frame")
    t = blank(size + 2 * pad, size + 2 * pad)
    t.glow(shape(t, pad), 5.0, WHITE, 0.5)
    keep("ButtonRingGlow", t, "accent, green or red", (inset[0] + pad,) * 4, pad, "under the body")
    t = blank(size, size)
    t.paint(np.maximum(shape(t), t.y - 5.0), BLACK, 0.22)
    keep("ButtonPressedShade", t, None, inset, use="pressed: the top of the body in shade")
    t = blank(52.0, 14.0)
    t.paint(t.poly(cut_box(0, 0, 52.0, 14.0, 5.0, 0.0, 5.0, 0.0)), c(DARK))
    keep("DotsWell", t, None, use="waiting: the three dots' well")
    t = blank(12.0, 12.0)
    dot = np.hypot(t.x - 6.0, t.y - 6.0) - 2.8
    t.glow(dot, 2.0, WHITE, 0.4)
    t.paint(dot, WHITE)
    keep("Dot", t, "accent", use="waiting: one of the three, each smaller and fainter than the last")
    t = blank(20.0, 16.0)
    t.stroke([(3.0, 8.0), (8.0, 13.0), (17.0, 2.5)], 2.4, WHITE)
    keep("Tick", t, "green", use="succeeded")


def bars():
    """A conduit, drawn 10 points high, and a thread, drawn 4: the slant is 6 across for 10 down at any height, so the
    one light fits both, scaled."""
    for name, h, cap in (("Bar", 10.0, 8.0), ("Thread", 4.0, 4.0)):
        s, w = 0.6 * h, cap * 2 + 8
        pts = [(s, 0), (w, 0), (w - s, h), (0, h)]
        t = blank(w, h)
        t.paint(t.poly(pts), WHITE)
        keep(name + "Channel", t, "channel", (cap, 0.0, cap, 0.0))
        t = blank(w, h)
        t.line(t.poly(pts), 0.75, WHITE)
        keep(name + "Edge", t, "edge", (cap, 0.0, cap, 0.0))
    h, s, cap, pad = 8.0, 4.8, 6.0, 14.0
    w = cap * 2 + 4

    def lit(t, o=0.0, width=w):
        return t.poly([(o + s, o), (o + width, o), (o + width - s, o + h), (o, o + h)])

    t = blank(w, h)
    across = np.clip(1 - np.abs(2 * t.y / h - 1), 0, 1)
    t.paint(lit(t), t.ramp(WHITE * 0.82, WHITE, across))
    keep("BarLight", t, "the light, or its warm edge on a pale panel", (cap, 0.0, cap, 0.0))
    t = blank(w, h)
    ui.over(t.px, WHITE, np.clip(0.5 - lit(t) * K, 0, 1) * across ** 1.3)
    keep("BarCore", t, None, (cap, 0.0, cap, 0.0), use="white, at the palette's `core`")
    width = 20.0
    t = blank(width, h)
    back = ((t.x - width) + t.y * s / h) / math.hypot(1.0, s / h)
    ui.over(t.px, WHITE, np.clip(0.5 - lit(t, width=width) * K, 0, 1) * np.clip(1 + back / 9.6, 0, 1) * 0.75)
    keep("BarHead", t, None, use="white, at the light's leading end")
    t = blank(w + 2 * pad, h + 2 * pad)
    t.glow(lit(t, pad), 4.4, WHITE, 0.4)
    keep("BarGlow", t, "the light", (cap + pad, 0.0, cap + pad, 0.0), pad, "under the light")


def frames():
    """Each rarity's frame in two cuts: the full one, 80 by 96 points, and the small one, 40 by 48, with the crest
    alone. Back is the glow and the well, under the portrait. The frame itself goes over it. Seat is the dark seat a
    pale panel gives it. Mask cuts a portrait to the frame, and isn't shipped."""
    for rarity, full in ui.RARITIES.items():
        for small in (False, True):
            r = {k: v for k, v in full.items() if not (small and k in ("base", "wing", "shards"))}
            w, pad = (40.0, 26.0) if small else (80.0, 52.0)
            h, scale, name = w * 1.2, w / 80.0, "Frame" + rarity + ("Small" if small else "")
            r["cut"] = tuple(v * scale for v in r["cut"])
            x0, y0, x1, y1 = pad, pad, pad + w, pad + h

            def tile():
                t = blank(w + 2 * pad, h + 2 * pad)
                return t, t.poly(ui.outline(x0, y0, x1, y1, r))

            t, d = tile()
            if "glow" in r:
                code, radius, strength = r["glow"]
                t.glow(d, radius * scale, c(code), strength)
            t.paint(d, t.ramp("#1B1E26", "#090A0D", (t.y - y0) / h))
            keep(name + "Back", t, pad=pad, use="its light and its well, under the portrait")
            t, d = tile()
            if "glow" in r and r["metal"][1] in DEEP:
                ui.over(t.px, c(DEEP[r["metal"][1]]), 0.9 * np.exp(-(np.maximum(d, 0) / (r["glow"][1] * scale * 0.5)) ** 1.4)
                        * np.clip(0.5 + (d + 1.0) * K, 0, 1))
            t.paint(np.maximum(d - 1.6 * max(scale, 0.75), -d - 1.0), c("#20232B"), 0.92)
            keep(name + "Seat", t, pad=pad, use="over Back, on a pale panel only")
            t, d = tile()
            metal = t.ramp(r["metal"][0], r["metal"][1], (t.y - y0) / h)
            t.paint(np.maximum(d, y1 - h * 0.3 - t.y), BLACK, 0.25)  # the floor of the slot
            width = r["stroke"] * max(scale, 0.75)
            t.line(d, width, metal)
            if r.get("inner"):
                t.line(d + width + 1.2, 0.7, metal, 0.75)
            if r.get("hot"):
                t.line(d + width * 0.3, 0.8, WHITE, 0.9)
            tl, br = r["cut"][0], r["cut"][2]
            for i in range(r.get("shards", 0)):  # splinters the cuts threw off: straight-edged, never on the small cut
                o, size = 3.0 + i * 3.2, (4.0 - i * 0.8) * scale
                for px, py, sx, sy in ((x1 - br * 0.5, y1 - br * 0.5, 1, 1), (x0 + tl * 0.5, y0 + tl * 0.5, -1, -1))[:1 + (i > 0)]:
                    ax, ay = px + sx * o * 0.7, py + sy * o * 0.7
                    tri = t.poly([(ax + sx * size, ay - sy * size * 0.2), (ax - sx * size * 0.2, ay + sy * size),
                                  (ax + sx * size * 0.75, ay + sy * size * 0.75)])
                    if "glow" in r:
                        t.glow(tri, 2.0, WHITE, 0.3)
                    t.paint(tri, c(r["splinter"]) if "splinter" in r else metal)
            keep(name, t, pad=pad, use="over the portrait" + ("; under 64 points wide" if small else "; 64 points wide and up"))
            t, d = tile()
            t.paint(d + r["stroke"] * 0.5, WHITE)
            keep(name + "Mask", t, pad=pad, ship=False)


# --- the gems, the marks ----------------------------------------------------------------------------------------------

# A type is its colour and its cut, so the five are told apart without colour too.
GEMS = {
    "Strength": [(0, -1), (0.82, -0.36), (0.82, 0.36), (0, 1), (-0.82, 0.36), (-0.82, -0.36)],
    "Endurance": [(-0.58, -0.8), (0.58, -0.8), (0.8, -0.58), (0.8, 0.58), (0.58, 0.8), (-0.58, 0.8), (-0.8, 0.58), (-0.8, -0.58)],
    "Agility": [(0, -1.04), (0.6, -0.2), (0, 1.04), (-0.6, -0.2)],
    "Intelligence": [(-0.12, -0.96), (0.12, -0.96), (0.98, 0.56), (0.84, 0.8), (-0.84, 0.8), (-0.98, 0.56)],
    "Technique": [(-0.55, -0.82), (0.55, -0.82), (0.98, -0.3), (0, 0.96), (-0.98, -0.3)],
}
CLASSES = ("Warrior", "Tank", "Assassin", "Mage", "Healer")
VOID_BODY = ("#3A2670", "#1C1238")  # Void's mark, top to bottom


def stone(t, cx, cy, r, colour, pts, seat=0.0):
    """A type's gem: a hard-cut stone with its table and facets, lit from the top left, in a dark rim. In a frame's
    cut it sits in a dark seat, so Strength's red holds against Mythical's light."""
    colour = c(colour)
    gx, gy = sum(x for x, _ in pts) / len(pts), sum(y for _, y in pts) / len(pts)
    outer = [(cx + x * r, cy + y * r) for x, y in pts]
    table = [(cx + (gx + (x - gx) * 0.48) * r, cy + (gy + (y - gy) * 0.48) * r) for x, y in pts]
    d = t.poly(outer)
    if seat:
        t.paint(d - seat * r, c(ui.STROKE), 0.92)
    t.paint(d - r / 6, c(ui.STROKE))
    t.paint(d, colour)
    slope = (t.y - cy) + (t.x - cx) * 0.55
    t.paint(np.maximum(d, slope + r * 0.2), WHITE, 0.38)
    t.paint(np.maximum(d, -slope + r * 0.3), BLACK, 0.3)
    for a, b in zip(outer, table):
        t.paint(np.maximum(d, ui.sd_segment(t.x, t.y, a, b) - r * 0.025), BLACK, 0.2)
    inner = t.poly(table)
    t.paint(inner, WHITE, 0.16)
    t.line(inner, r * 0.05, WHITE, 0.4)
    px, py, g = cx + (gx - 0.22) * r, cy + (gy - 0.42) * r, r * 0.13
    t.paint(t.poly([(px, py - g), (px + g * 0.7, py), (px, py + g), (px - g * 0.7, py)]), WHITE, 0.9)


def glyph(name, t, cx, cy, r):
    """A class's mark, as the distance from its outline. Warrior: a blade on the slant, with its taper and guard.
    Tank: a shield with its boss. Assassin: a cowl with a leaning peak and one narrowed slit for the eyes. Mage: a
    broken ring round a core. Healer: a cut heart."""
    u, v = (t.x - cx) / r, (t.y - cy) / r

    def poly(pts):
        return ui.sd_polygon(u, v, list(pts)) * r

    if name == "Warrior":
        def turn(pts):
            return [((a + b) * 0.7071, (b - a) * 0.7071) for a, b in pts]
        return np.minimum.reduce([
            poly(turn([(-0.3, -0.3), (0.5, -0.26), (1.1, 0), (0.5, 0.26), (-0.3, 0.3)])),
            poly(turn([(-0.5, -0.46), (-0.3, -0.46), (-0.3, 0.46), (-0.5, 0.46)])),
            poly(turn([(-0.9, -0.11), (-0.5, -0.11), (-0.5, 0.11), (-0.9, 0.11)])),
            poly(turn([(-1.14, 0), (-0.97, -0.19), (-0.8, 0), (-0.97, 0.19)]))])
    if name == "Tank":
        shield = poly([(-0.5, -0.88), (0.78, -0.88), (0.78, 0.08), (0, 0.95), (-0.78, 0.08), (-0.78, -0.56)])
        return np.maximum(shield, -(np.abs(shield + 0.26 * r) - 0.07 * r))
    if name == "Assassin":
        # Shaped like a head, widest at the cheek and narrowing to the jaw, its peak leaning like cloth. The slit sits
        # high and narrows to the bridge of the nose: lower, or dipping in the middle, it reads as a smile at 16 px.
        cowl = poly([(-0.22, -1.04), (0.6, -0.46), (0.8, 0.3), (0.46, 0.96), (-0.5, 0.96), (-0.86, 0.3), (-0.74, -0.4)])
        slit = poly([(-0.62, -0.34), (-0.02, -0.14), (0.56, -0.34), (0.56, 0.14), (-0.02, 0.04), (-0.62, 0.14)])
        return np.maximum(cowl, -slit)
    if name == "Mage":
        def ring(radius):
            return poly([(radius * math.cos(math.radians(22.5 + 45 * i)), radius * math.sin(math.radians(22.5 + 45 * i)))
                         for i in range(8)])
        broken = np.maximum(np.maximum(ring(0.95), -ring(0.66)), -(np.abs(u - v) / 1.4142 - 0.12) * r)
        return np.minimum(broken, poly([(0, -0.4), (0.4, 0), (0, 0.4), (-0.4, 0)]))
    return poly([(0, -0.4), (0.44, -0.86), (0.92, -0.44), (0.92, 0.06), (0, 0.95), (-0.92, 0.06), (-0.92, -0.44), (-0.44, -0.86)])


def element(name, t, cx, cy, r):
    """An element's mark and the lighter part inside it, as distances. Fire: a flame of three straight tongues.
    Frost: three bars crossed. Storm: a cloud and its one bolt. Void: a dark shard, and the white crack through it."""
    u, v = (t.x - cx) / r, (t.y - cy) / r

    def poly(pts):
        return ui.sd_polygon(u, v, list(pts)) * r

    if name == "Fire":
        return (poly([(0.05, -1), (0.34, -0.42), (0.62, -0.62), (0.8, 0.2), (0.42, 0.92), (-0.42, 0.92), (-0.8, 0.25),
                      (-0.5, -0.3), (-0.3, -0.02)]), poly([(0.02, -0.12), (0.32, 0.5), (0, 0.8), (-0.32, 0.5)]))
    if name == "Frost":
        bar = [(-1, 0), (-0.84, -0.13), (0.84, -0.13), (1, 0), (0.84, 0.13), (-0.84, 0.13)]
        turned = [[(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)) for x, y in bar]
                  for a in (math.radians(90), math.radians(30), math.radians(150))]
        return (np.minimum.reduce([poly(p) for p in turned]), poly([(0, -0.26), (0.22, 0), (0, 0.26), (-0.22, 0)]))
    if name == "Storm":
        bolt = poly([(0.18, -0.05), (-0.38, 0.52), (-0.06, 0.52), (-0.3, 1.0), (0.42, 0.36), (0.1, 0.36), (0.4, -0.05)])
        cloud = poly([(-0.92, 0.02), (-0.92, -0.3), (-0.6, -0.62), (-0.25, -0.62), (-0.02, -0.92), (0.5, -0.92),
                      (0.78, -0.64), (0.78, -0.34), (0.95, -0.34), (0.95, 0.02)])
        return (np.minimum(cloud, bolt), np.maximum(bolt, 0.02 * r - (t.y - cy)))
    # A fracture across the shard, corner to corner: five uneven runs and one short spur that ends inside it. Never
    # three strokes upright, which in white on dark is a rune's shape (the content check, 2026-11-12), and never a
    # second spur, which would make a fork.
    line = [(0.52, -0.78), (0.2, -0.42), (0.3, -0.18), (-0.08, 0.08), (-0.02, 0.36), (-0.5, 0.78)]
    crack = np.minimum.reduce([ui.sd_segment(u, v, a, b) for a, b in zip(line, line[1:])]) * r - 0.1 * r
    spur = ui.sd_segment(u, v, (-0.08, 0.08), (-0.38, -0.08)) * r - 0.065 * r
    return (poly([(0, -1), (0.72, 0), (0, 1), (-0.72, 0)]), np.minimum(crack, spur))


def icons():
    m, r = BOX / 2, 12.0
    for name, pts in GEMS.items():
        for seated in (False, True):
            t = blank(BOX, BOX)
            stone(t, m, m, 10.5 if seated else r, ss.TYPES[name], pts, 0.37 if seated else 0.0)
            keep("Gem" + name + ("Seated" if seated else ""), t, use="in a frame's top cut" if seated else "on a panel")
    for name in CLASSES:
        t = blank(BOX, BOX)
        seat = t.poly(cut_box(m - 13, m - 13, m + 13, m + 13, 6.5, 0, 6.5, 0))
        t.paint(seat - 2.0, c(ui.STROKE))
        t.paint(seat, c(SEAT["well"]))
        t.line(seat, 1.5, c(SEAT["edge"]))
        t.paint(glyph(name, t, m, m, 8.6), c(INK))
        keep("Class" + name, t, use="in its seat: on a frame's bottom cut, on a card")
        t = blank(BOX, BOX)
        t.paint(glyph(name, t, m, m, r), WHITE)
        keep("Class" + name + "Glyph", t, "ink", use="bare: a filter, a tab")
    for name, code in ui.ELEMENTS.items():
        t = blank(BOX, BOX)
        d, inner = element(name, t, m, m, 11.0)
        t.paint(d - 11.0 / 6, c(ui.STROKE))
        slope = (t.y - m) + (t.x - m) * 0.55
        if name == "Void":  # dark, its element's colour kept to a rim and the crack's halo: Intelligence's gem is violet too
            t.paint(d, t.ramp(VOID_BODY[0], VOID_BODY[1], (t.y - m + 11.0) / 22.0))
            t.paint(np.maximum(d, slope + 2.0), WHITE, 0.1)
            t.line(d, 1.3, c(code))
            t.paint(np.maximum(d, inner - 1.1), c(code), 0.7)
            t.paint(np.maximum(d, inner), WHITE)
        else:
            t.paint(d, c(code))
            t.paint(np.maximum(d, slope + 2.0), WHITE, 0.3)
            t.paint(np.maximum(d, -slope + 3.0), BLACK, 0.22)
            t.paint(np.maximum(d, inner), WHITE, 0.6)
        keep("Element" + name, t)
    t = blank(BOX, BOX)
    ui.coin(t, m, m, r)
    keep("Coin", t, use="Credits")
    t = blank(BOX, BOX)
    d = t.poly([(m + r * 0.25, m - r), (m - r * 0.55, m + r * 0.12), (m - r * 0.05, m + r * 0.12), (m - r * 0.3, m + r),
                (m + r * 0.55, m - r * 0.2), (m + r * 0.05, m - r * 0.2)])
    t.paint(d - 2.0, c(ui.STROKE))
    t.paint(d, t.ramp("#FFF7C2", ui.CHARGE, (t.y - m + r) / (2 * r)))
    keep("Bolt", t, use="Electricity")
    t = blank(BOX, BOX)
    pts = [(m + (r if i % 2 == 0 else r * 0.3) * math.cos(math.radians(45 * i - 78)),
            m + (r if i % 2 == 0 else r * 0.3) * math.sin(math.radians(45 * i - 78))) for i in range(8)]
    d = t.poly(pts)
    t.paint(d - 2.2, c(ui.STROKE))
    t.paint(d, WHITE)
    keep("Spark", t, "the critical's gold", use="the mark on a critical hit")


# --- a piece from its slices, as the engine layers it ----------------------------------------------------------------

def shade(tint, rows):
    if isinstance(tint, (tuple, list)) and isinstance(tint[0], str):
        return c(tint[0]) + (c(tint[1]) - c(tint[0])) * np.linspace(0, 1, rows, dtype=np.float32)[:, None, None]
    return (c(tint) if isinstance(tint, str) else np.asarray(tint, dtype=np.float32))[None, None, :]


def stretch(px, cut, w, h, scale=1.0):
    """A slice drawn out to w by h points: its corners keep their size, its middle stretches."""
    if scale != 1.0:
        px = rs.shrink(px, scale)

    def index(n, a, b, n2):
        if n2 <= a + b:
            return np.minimum((np.arange(n2) * n / max(n2, 1)).astype(int), n - 1)
        mid = n2 - a - b
        return np.concatenate([np.arange(a), a + ((np.arange(mid) + 0.5) * (n - a - b) / mid).astype(int), n - b + np.arange(b)])

    left, top, right, bottom = (round(v * K * scale) for v in cut)
    return px[index(px.shape[0], top, bottom, round(h * K))][:, index(px.shape[1], left, right, round(w * K))]


class Stage:
    """A corner of a screen, in points, built from the slices."""

    def __init__(self, w, h, ground):
        self.w, self.h, self.items = w, h, []
        self.px = rs.canvas(round(w * K), round(h * K), tuple(c(ground)))

    def lay(self, name, x, y, w=None, h=None, tint=None, alpha=1.0, scale=1.0, window=None):
        im = IMAGES[name]
        px, pad = im["px"], im["pad"] * scale
        if im["cut"]:
            px = stretch(px, im["cut"], w + 2 * pad, h + 2 * pad, scale)
        elif scale != 1.0:
            px = rs.shrink(px, scale)
        px = px.copy()
        if tint is not None:
            px[..., :3] *= shade(tint, px.shape[0])
        if window is not None:
            px[..., 3] *= window(px.shape[0], px.shape[1])
        px[..., 3] *= alpha
        rs.paste(self.px, px, round((x - pad) * K), round((y - pad) * K))

    def icon(self, name, cx, cy, size, tint=None, alpha=1.0):
        self.lay(name, cx - size / 2, cy - size / 2, tint=tint, alpha=alpha, scale=size / IMAGES[name]["w"])

    def text(self, x, y, size, text, colour, align="LEFT"):
        self.items.append(dict(x=x, y=y, size=size, text=text, colour=colour, align=align, layer="plain", shear=0.0, bold=0.0))


def panel(st, x, y, w, h, p):
    bold = "Bold" if p.get("border", 1.0) > 1.0 else ""
    st.lay("PanelShadow", x, y, w, h)
    st.lay("PanelFill", x, y, w, h, tint=p["panel"], alpha=p["alpha"])
    if min(w, h) >= 48:
        st.lay("PanelFacet", x, y, w, h, tint=p["facet"], alpha=0.07)
    st.lay("PanelEdge" + bold, x, y, w, h, tint=p["edge"], alpha=0.95)
    st.lay("PanelGlint", x, y, w, h, tint=p["glint"])


def bar(st, x, y, w, h, fill, p, light=ui.LIGHT):
    kind, base = ("Thread", 4.0) if h < 7 else ("Bar", 10.0)
    st.lay(kind + "Channel", x, y, w, h, tint=p["channel"], scale=h / base)
    st.lay(kind + "Edge", x, y, w, h, tint=p["edge"], alpha=0.9, scale=h / base)
    if fill <= 0:
        return
    rim, s, colour = min(p.get("rim", 1.0), h * 0.2), 0.6 * h, c(light)
    lx, ly, lh = x + 1.77 * rim, y + rim, h - 2 * rim
    lw, k = min(s + (w - s) * fill - 2.37 * rim, w - 3.53 * rim), (h - 2 * rim) / 8.0
    warm = p.get("warm") is not None and colour[2] < colour[0]  # a warm light on a pale panel: gold at its edges
    st.lay("BarGlow", lx, ly, lw, lh, tint=colour, scale=k)
    st.lay("BarLight", lx, ly, lw, lh, tint=colour * np.asarray(p["warm"], dtype=np.float32) if warm else colour, scale=k)
    st.lay("BarCore", lx, ly, lw, lh, alpha=p["core"] if warm else 0.5, scale=k)
    st.lay("BarHead", lx + lw - 20.0 * k, ly, scale=k)


def button(st, x, y, w, h, label, p, state="rest", reason=None):
    y += 1.0 if state == "pressed" else 0.0
    bold = "Bold" if p.get("border", 1.0) > 1.0 else ""
    lit = {"selected": p["accent"], "succeeded": ui.GOOD, "failed": ui.BAD}.get(state)
    if state != "pressed":
        st.lay("ButtonShadow", x, y, w, h)
    if lit:
        st.lay("ButtonRingGlow", x, y, w, h, tint=lit)
    inked = state == "selected" and "selected" in p  # a palette whose selected button fills with ink
    st.lay("ButtonFill", x, y, w, h, tint=p["pressed"] if state == "pressed" else p["selected"] if inked else p["button"])
    if state == "disabled":
        st.lay("ButtonFill", x, y, w, h, tint=p["ground"], alpha=0.55)
    st.lay("ButtonEdge" + bold, x, y, w, h, tint=p["edge"], alpha=0.45 if state == "disabled" else 1.0)
    if state == "pressed":
        st.lay("ButtonPressedShade", x, y, w, h)
    if lit:
        st.lay("ButtonRing", x, y, w, h, tint=lit)
    elif state in ("rest", "pressed"):
        st.lay("ButtonBase", x, y, w, h, tint=WHITE if state == "pressed" else p["accent"])
        st.lay("ButtonBaseGlow", x, y, w, h, tint=p["accent"], alpha=1.0 if state == "pressed" else 0.45)
    elif state == "waiting":  # one moment of the light's run round the edge
        def run(rows, cols):
            across = np.clip(1 - np.abs(np.linspace(0, 1, cols) - 0.62) / 0.24, 0, 1) ** 0.5
            return across[None, :] * (np.arange(rows) < 7 * K)[:, None]
        st.lay("ButtonRing", x, y, w, h, tint=p["accent"], window=run)
        st.lay("DotsWell", x + w / 2 - 26, y + h / 2 - 7)
        for i in range(3):
            st.icon("Dot", x + w / 2 - 13 + 13 * i, y + h / 2, 12.0 * (1 - 0.17 * i), tint=p["accent"], alpha=1.0 - 0.3 * i)
    ink = p["faint"] if state == "disabled" else p["selectedText"] if inked else p["text"]
    ty = y + (h - 14 * ui.CAP) / 2
    if state == "succeeded":
        st.icon("Tick", x + 29, y + h / 2, 20.0, tint=ui.GOOD)
        st.text(x + w / 2 + 12, ty, 14, label, ink, "CENTER")
    elif state != "waiting":
        st.text(x + w / 2, ty, 14, label, ink, "CENTER")
    if reason:
        st.text(x + w / 2, y + h + 6, 11, reason, p["soft"], "CENTER")


def frame(st, x, y, rarity, p, face=None, small=False, type_="Strength", class_="Warrior"):
    name = "Frame" + rarity + ("Small" if small else "")
    w = 40.0 if small else 80.0
    h, scale = w * 1.2, w / 80.0
    st.lay(name + "Back", x, y)
    if p.get("seat"):
        st.lay(name + "Seat", x, y)
    if face is not None:
        st.lay(cut_face(name, face, w, h), x, y)
    st.lay(name, x, y)
    if not small:
        st.icon("Gem" + type_ + "Seated", x + 5.5 * scale, y + 5.5 * scale, BOX * 6.5 / 10.5)
        st.icon("Class" + class_, x + w - 6.5 * scale, y + h - 6.5 * scale, BOX * 6.0 / 13.0)


def cut_face(name, face, w, h):
    """The portrait cut to a frame's mask. In the game, each Voidkin's portrait is cut this way before it's uploaded."""
    key = "_Face" + name
    if key not in IMAGES:
        mask = IMAGES[name + "Mask"]
        px = np.zeros_like(mask["px"])
        side = round((w - 2) * K)
        small = rs.shrink(face, side / face.shape[1])
        x0, y0 = round((mask["pad"] + 1) * K), round((mask["pad"] + h - 1) * K) - side
        px[y0:y0 + small.shape[0], x0:x0 + small.shape[1]] = small
        px[..., 3] *= mask["px"][..., 3]
        IMAGES[key] = dict(px=px, w=mask["w"], h=mask["h"], tint=None, cut=None, pad=mask["pad"], use="", ship=False)
    return key


def pill(st, x, y, w, p, icon, value, extra=None, fill=None):
    h = 30.0
    st.lay("PanelShadow", x, y, w, h)
    st.lay("PanelFill", x, y, w, h, tint=p["panel"], alpha=p["alpha"])
    st.lay("PanelEdge" + ("Bold" if p.get("border", 1.0) > 1.0 else ""), x, y, w, h, tint=p["edge"], alpha=0.95)
    st.lay("PanelGlint", x, y, w, h, tint=p["glint"])
    st.icon(icon, x + 19, y + h / 2, BOX * 8.0 / 12.0)
    ty = y + (h - 14 * ui.CAP) / 2 - (2 if fill is not None else 0)
    st.text(x + 33, ty, 14, value, p["text"])
    if extra:
        st.text(x + w - 10, ty, 14, extra, p["soft"], "RIGHT")
    if fill is not None:
        bar(st, x + 31, y + h - 8, w - 40, 3.0, fill, p, ui.CHARGE)


BLOCK = (284.0, 412.0)


def demo(p, face, rarity):
    """One corner of a screen in a palette: the pills, a panel with a framed Voidkin, its bars and two buttons, and
    the other states."""
    st = Stage(*BLOCK, "#23262D")
    st.px[: round(40 * K), :, :3] = c("#3B3350")  # a strip of dusk behind the pills
    pill(st, 8, 6, 100, p, "Coin", "12,480")
    pill(st, 114, 6, 162, p, "Bolt", "8,240 / 9,000", "+12/s", 0.9)
    panel(st, 8, 46, 268, 212, p)
    st.text(20, 58, 14, "Bay 2", p["text"])
    st.text(264, 58, 14, "Lv 12", p["soft"], "RIGHT")
    frame(st, 20, 92, rarity, p, face)
    st.icon("GemStrength", 118, 89, BOX * 6.0 / 12.0)
    st.icon("ClassWarrior", 133, 89, BOX * 5.5 / 13.0)
    st.icon("ElementFire", 148, 89, BOX * 6.0 / 12.0)
    st.text(160, 84, 14, "Rook", p["text"])
    for i, (fill, word) in enumerate(((1.0, "full"), (0.22, "low"), (0.0, "empty"))):
        bar(st, 112, 108 + i * 20, 152, 10.0, fill, p)
        st.text(264, 120 + i * 20, 8, word, p["faint"], "RIGHT")
    bar(st, 112, 170, 152, 4.0, 0.6, p, "#C9B8FF")
    button(st, 20, 204, 118, 44, "Break", p)
    button(st, 146, 204, 118, 44, "Voidkin", p, "selected")
    panel(st, 8, 268, 268, 136, p)
    for i, (state, label) in enumerate((("pressed", "Break"), ("disabled", "Break"), ("waiting", ""))):
        button(st, 18 + i * 84, 278, 78, 44, label, p, state, "Needs 200" if state == "disabled" else None)
    button(st, 18, 340, 120, 44, "Done", p, "succeeded")
    button(st, 146, 340, 120, 44, "Break", p, "failed", "No free chamber")
    return st


# --- the sheets -------------------------------------------------------------------------------------------------------

def bleed(px, passes=8):
    """Gives a clear pixel its neighbours' colour, so a scaled edge never darkens toward black."""
    rgb, known = px[..., :3].copy(), px[..., 3] > 0.004
    if not known.any():
        return
    for _ in range(passes):
        total, count = np.zeros_like(rgb), np.zeros(known.shape, dtype=np.float32)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dx or dy:
                    near = np.roll(np.roll(known, dy, axis=0), dx, axis=1)
                    total += np.roll(np.roll(rgb, dy, axis=0), dx, axis=1) * near[..., None]
                    count += near
        new = ~known & (count > 0)
        rgb[new] = total[new] / count[new][:, None]
        known |= new
    rgb[~known] = rgb[known].mean(axis=0)
    px[..., :3] = rgb


def finish(sheet, path):
    """Sets a sheet's text and saves it."""
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, path)


def put(sheet, px, x, y):
    """A picture on a sheet, its top-left corner at x, y in the sheet's pixels."""
    rs.paste(sheet.px, px, round(x), round(y))


def fit(px, longest):
    return rs.shrink(px, longest / max(px.shape[:2]))


def chip(sheet, x, y, w, h, colour):
    sheet.px[round(y):round(y + h), round(x):round(x + w), :3] = c(colour)


NOTE, HEAD, GROUND, PALE = "#C9CDD6", "#F3EFE6", "#14161B", "#F2EEE4"


def palettes_sheet(out, face):
    stages = {name: demo(p, face, rarity) for (name, p), rarity in zip(PALETTES.items(), ("Legendary", "Epic", "Rare", "Mythical"))}
    ui.K = SK
    bw, bh, gap = BLOCK[0], BLOCK[1], 16.0
    sheet = ui.Sheet(gap + len(stages) * (bw + gap), 70 + bh + 24 + bh / 2 + 24 + 16 * len(SCREENS) + 16, "#33363E")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 17, "Grow your Anime: the UI kit, one set of images in four palettes", HEAD)
    t.text(gap, 36, 10, "AR3. Every piece here is built from the kit's slices alone, tinted by its palette's row, the way the "
           "engine layers them. Frames, gems and marks are the same images in all four.", NOTE)
    for i, (name, st) in enumerate(stages.items()):
        x = gap + i * (bw + gap)
        t.text(x, 54, 11, name, HEAD)
        put(sheet, rs.shrink(st.px, SK / K), x * SK, 70 * SK)
        sheet.items += [dict(item, x=x + item["x"], y=70 + item["y"]) for item in st.items]
    y = 70 + bh + 8
    t.text(gap, y, 10, "The same four at 1 pixel a point:", NOTE)
    y2 = y + 16 + bh / 2 + 10
    for i, (name, words) in enumerate(SCREENS.items()):
        t.text(gap, y2 + i * 16, 10, f"{name}: {words}.", NOTE)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    for i in range(len(stages)):
        x0, y0 = round((gap + i * (bw + gap)) * SK), 70 * SK
        small = rs.shrink(sheet.px[y0:y0 + round(bh * SK), x0:x0 + round(bw * SK)].copy(), 0.5)
        put(sheet, small, (gap + i * (bw / 2 + gap)) * SK, (y + 16) * SK)
    rs.save(sheet.px, out / "kit_palettes.png")
    for i, name in enumerate(stages):
        x0 = round((gap + i * (bw + gap)) * SK)
        rs.save(sheet.px[round(50 * SK):round((70 + bh) * SK), x0 - 8:x0 + round(bw * SK) + 8].copy(),
                out / f"kit_palette_{name.split()[0].lower()}.png")
    ui.K = K


def whole(name, face=None, seat=False):
    """A frame's layers as one picture: its light and well, its seat on a pale panel, a portrait, the frame."""
    small = name.endswith("Small")
    layers = [name + "Back"] + ([name + "Seat"] if seat else [])
    layers += [cut_face(name, face, 40.0 if small else 80.0, 48.0 if small else 96.0)] if face is not None else []
    px = np.zeros_like(IMAGES[name]["px"])
    for layer in layers + [name]:
        src = IMAGES[layer]["px"]
        ui.over(px, src[..., :3], src[..., 3].copy())
    return px


def frames_sheets(out, face):
    """A sheet a rarity: the full cut with its light and the frame alone, at full size; the small cut the same; then
    each 64 px wide and the small cut at 1 pixel a point, over dark and on a pale panel in its seat."""
    def trim(px, name, keep):
        cut = round((IMAGES[name]["pad"] - keep) * K)
        return px[cut:-cut, cut:-cut]

    for rarity in ui.RARITIES:
        ui.K = SK
        full, small = "Frame" + rarity, "Frame" + rarity + "Small"
        sheet = ui.Sheet(600, 530, GROUND)
        t = sheet.tile(0, 0, sheet.w, sheet.h)
        t.text(8, 8, 12, f"{rarity}: its light and well with no portrait; the frame alone. Full size, 4 pixels a point.", NOTE)
        put(sheet, trim(whole(full), full, 32), 10, 50)
        put(sheet, trim(IMAGES[full]["px"], full, 32), 606, 50)
        y = 700
        t.text(8, y / SK, 9, "The small cut, with a portrait and alone.", NOTE)
        t.text(294, y / SK, 9, "64 px wide: whole, the frame alone, the small cut; the small cut at 1 pixel a point.", NOTE)
        put(sheet, trim(whole(small, face), small, 14), 10, y + 30)
        put(sheet, trim(IMAGES[small]["px"], small, 14), 290, y + 30)
        for row, seat in ((y + 40, False), (y + 190, True)):
            if seat:
                chip(sheet, 580, row - 8, 610, 150, PALE)
            put(sheet, rs.shrink(trim(whole(full, face, seat), full, 32), 64 / (80 * K)), 590, row)
            put(sheet, rs.shrink(trim(whole(full, None, seat), full, 32), 64 / (80 * K)), 730, row)
            put(sheet, rs.shrink(trim(whole(small, face, seat), small, 14), 64 / (40 * K)), 870, row)
            put(sheet, rs.shrink(trim(whole(small, face, seat), small, 14), 1 / K), 1010, row + 20)
            put(sheet, rs.shrink(trim(whole(small, None, seat), small, 14), 1 / K), 1100, row + 20)
        finish(sheet, out / f"kit_frame_{rarity.lower()}.png")
    ui.K = K


def icons_sheet(out):
    """Each gem and mark over dark at 128, 64, 32 and 16 px, and over a pale panel at 64, 32 and 16."""
    ui.K = SK
    names = [n for n in IMAGES if n.startswith(("Gem", "Class", "Element")) or n in ("Coin", "Bolt", "Spark", "Tick", "Dot")]
    rows = (len(names) + 1) // 2
    cw, rh = 900, 150
    sheet = ui.Sheet((cw * 2 + 40) / SK, (50 + rows * rh) / SK, GROUND)
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(10, 8, 12, "The gems and marks: over dark at 128, 64, 32 and 16 px, and over a pale panel at 64, 32 and 16.", NOTE)
    for i, name in enumerate(names):
        x, y = 20 + (i // rows) * cw, 50 + (i % rows) * rh
        px = IMAGES[name]["px"]
        t.text(x / SK, (y + 56) / SK, 9, name, HEAD)
        chip(sheet, x + 560, y + 4, 300, 136, PALE)
        for j, (size, at) in enumerate(((128, 250), (64, 395), (32, 475), (16, 520), (64, 580), (32, 670), (16, 730))):
            small = (fit(px, size) if size < px.shape[0] else px).copy()
            if j > 3 and IMAGES[name]["tint"]:  # a white slice on a pale panel wears the pale palette's ink
                small[..., :3] *= c(ui.GOOD if name == "Tick" else PALETTES["Pearl Light"]["text"])
            put(sheet, small, x + at, y + (136 - small.shape[0]) / 2 + 4)
    finish(sheet, out / "kit_icons.png")
    ui.K = K


def slices_sheet(out):
    """Every stretching slice over a mid ground: at its own size, and drawn out to a piece's size, at 2 pixels a point."""
    ui.K = SK
    names = [n for n in IMAGES if IMAGES[n]["ship"] and not n.startswith(("Frame", "Gem", "Class", "Element"))
             and n not in ("Coin", "Bolt", "Spark", "Tick", "Dot")]
    cw, rh, per = 580, 300, 4
    rows = (len(names) + per - 1) // per
    sheet = ui.Sheet((cw * per + 40) / SK, (50 + rows * rh) / SK, "#4A4E58")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(10, 8, 12, "The slices, white where a palette colours them: each at full size (4 pixels a point), then drawn out "
           "to a piece's size at 2.", NOTE)
    for i, name in enumerate(names):
        im = IMAGES[name]
        x, y = 20 + (i % per) * cw, 50 + (i // per) * rh
        t.text(x / SK, (y + 4) / SK, 9, f"{name}  {im['px'].shape[1]}x{im['px'].shape[0]}", HEAD)
        put(sheet, im["px"], x, y + 30)
        if im["cut"]:
            tall = im["cut"][1] or im["cut"][3]
            w, h = (118.0, 44.0) if tall else (118.0, im["h"])
            drawn = stretch(im["px"], im["cut"], w, h)
            put(sheet, rs.shrink(drawn, SK / K), x + 290, y + 30)
    finish(sheet, out / "kit_slices.png")
    ui.K = K


def manifest(out):
    data = dict(
        pixelsPerPoint=K, sliceScale=1 / K,
        note="A white slice takes its palette's colour. `cut` is left, top, right, bottom in points, `pad` how far the "
             "image reaches past the piece's box. The layer order of a panel, a button, a bar and a frame is "
             "tools/blender/ui_kit.py's `panel`, `button`, `bar` and `frame`. A palette with `selected` fills its "
             "selected button with those two colours and writes its label in `selectedText`. A palette's accent never "
             "rings a portrait's frame.",
        bar=dict(slant="0.6 x height", rim="min(palette rim or 1, 0.2 x height)",
                 light="x + 1.77 rim, y + rim, height - 2 rim; width min(slant + (width - slant) x fill - 2.37 rim, "
                       "width - 3.53 rim); SliceScale (height - 2 rim) / 8 / pixelsPerPoint"),
        palettes={name: {k: v for k, v in p.items()} for name, p in PALETTES.items()},
        screens=SCREENS, good=ui.GOOD, bad=ui.BAD, light=ui.LIGHT, charge=ui.CHARGE, numbers=ui.NUMBER, elements=ui.ELEMENTS,
        images={name: dict(file=f"images/{name}.png", pixels=[im["px"].shape[1], im["px"].shape[0]], points=[im["w"], im["h"]],
                           **({"tint": im["tint"]} if im["tint"] else {}), **({"cut": list(im["cut"])} if im["cut"] else {}),
                           **({"pad": im["pad"]} if im["pad"] else {}), **({"use": im["use"]} if im["use"] else {}))
                for name, im in IMAGES.items() if im["ship"]})
    (out / "kit.json").write_text(json.dumps(data, indent=1), encoding="utf-8", newline="\n")
    print(f"wrote {out / 'kit.json'}: {len(data['images'])} images")


def main():
    out = bl.out_dir()
    face = ui.portrait()
    ui.K = K
    panels()
    buttons()
    bars()
    frames()
    icons()
    for folder in ("images", "masks"):
        (out / folder).mkdir(exist_ok=True)
    for name, im in IMAGES.items():
        bleed(im["px"])
        rs.save(im["px"], out / ("images" if im["ship"] else "masks") / f"{name}.png")
    manifest(out)
    palettes_sheet(out, face)
    frames_sheets(out, face)
    icons_sheet(out)
    slices_sheet(out)


if __name__ == "__main__":
    main()
