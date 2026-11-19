"""AR45: the foes' cards with their difficulty skulls, and CR's gold tab (docs/asset-requests.md, AR45; docs/ui.md, "The
HUD, in the world"; the director's word of 2026-11-19, by 11:30). A blockout sheet for research's pick, drawn in code:
shapes, the kit's type gems, and Blender's own face standing in for the game's. Nothing is exported.

    the skull   one icon of our own, cut like a shard: a faceted crown, two slanted eyes, a small diamond nose, a jaw
                apart with three teeth. Four tiers by the foe's CR against the lead (research's seeds: grey under 0.6,
                white to 1.05, yellow to 1.3, red above): faint grey, white, yellow, red. The level's text takes its
                tier's colour.
    the cards   the target's card for a Shade, an elite (horns on its frame) and a keeper (wider, its phases on the bar,
                horns and a crest), in the Menu's composition (AR43): one panel cut at its top left and foot right, a
                hairline edge, the skull and the level, the name, the type gem with its edge's arrow, health as an
                Ember light with its numbers. Two palettes, for the pick: A, the Menu's own (Seam); B, AR40's C, the
                system panel's teal.
    CR's tab    "CR" on a small slanted gold tab, the number beside it in pale ivory, upright and wide apart (AR44's
                plain digits; Blender's face stands in for Oswald): at the lead's feet, on the Overview, on an item's row.

    blender -b --factory-startup --python tools/blender/foe_cards.py -- <abs out>        the sheet, foe_cards.png
    blender -b --factory-startup --python tools/blender/foe_cards.py -- <abs out> cut    research's pick B, cut
    blender -b --factory-startup --python tools/blender/foe_cards.py -- <abs out> fit    the cards in the game's HUD

The sheet is at 2 pixels a point, its fight views at 1 too. The cut writes <out>/images (the new images at 4 pixels a
point), foes.json (what each is for, its tint and its place on the card), and foe_cards_cut.png, the check sheet: each
image alone at full size and at 64 px, the skull's tiers, and B's cards built from the kit's slices and these images.
Since research's second look (12:32) the cut is B on the fight HUD's slant: the plate in three images (fill, edge, the
elite's brass edge) and the elite's solid shards. The first cut's upright edge, thin horns, crest and notch stay drawn,
as uploaded, and are listed unused in foes.json. The fit writes foe_cards_fit.png: the cards built from the cut's images
in Faber's phone capture of a fight, in the old target card's place beside the game's own HUD, at 2 pixels a point and
at the phone's 1. The sheet mode's `card(..., slant=)` draws the same card in shapes, for blockouts.
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

ui.K = 2
REPO = Path(__file__).resolve().parents[2]
KIT = REPO / "build" / "handoff" / "UI" / "kit" / "images"
STILL = REPO / "build" / "scratch" / "faber" / "stills" / "burst-crowded-phone.png"   # a fight, ~1.11 px a point
MENU = REPO / "build" / "scratch" / "modulo" / "upgrades" / "upgrade_menu.png"         # AR43's Menu at 2 px a point
STILL_PPT = 1.11

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)  # codes, painted

# The Menu's own (Config.UIKit, Palettes.Seam) and AR40's C system panel (upgrade_pages.py's SEAM and C_SYS).
SEAM = dict(panel=("#1A1430", "#0C0A16"), edge="#3B3358", facet="#8F84B8", glint="#DCD3FF", text="#F1ECFF",
            soft="#B9B0D6", well=("#07060C", "#110E1B"), channel="#050409", ink="#0B0913")
C_SYS = dict(panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", facet="#8FC4C8", glint="#FFF6E2", text="#FFF6E2",
             soft="#D9E8E2", well=("#1B3840", "#14303A"), channel="#0E1D23", ink="#0E1D23")
TAKES = {"A, the Menu's own (Seam)": SEAM, "B, AR40's C (the system panel)": C_SYS}

# The tiers: name, the skull's and the level's colour, the skull's opacity.
TIERS = (("Much weaker", "#A3A1B2", 0.55), ("About even", "#F6F2E8", 1.0), ("Stronger", "#FFC83A", 1.0),
         ("Much stronger", "#FF4F42", 1.0))
LEVEL_FAINT = "#A3A1B2"
BRASS = ("#F4D88A", "#B07E2C")
EMBER = ((0.0, "#FFB27A"), (0.22, "#FF7E52"), (0.5, "#EE4E3A"), (0.56, "#DC3F33"), (1.0, "#9E2620"))   # health's light
UP, DOWN = "#7CF0A4", "#FF786E"
GOLD = ("#FFEBA8", "#E3A63A")
IVORY = "#F7F1E3"
INK_GOLD = "#4A2A08"

# The skull, in a box one unit high, centred: the crown and face, the jaw apart under it, and what's cut out of them.
CROWN = [(-0.27, -0.5), (0.27, -0.5), (0.46, -0.3), (0.47, 0.02), (0.31, 0.21), (-0.31, 0.21), (-0.47, 0.02),
         (-0.46, -0.3)]
JAW = [(-0.29, 0.27), (0.29, 0.27), (0.23, 0.5), (-0.23, 0.5)]
EYES = [[(-0.37, -0.1), (-0.07, -0.01), (-0.1, 0.12), (-0.31, 0.09)],
        [(0.37, -0.1), (0.07, -0.01), (0.1, 0.12), (0.31, 0.09)]]
NOSE = [(0.0, 0.1), (0.055, 0.17), (0.0, 0.22), (-0.055, 0.17)]
TEETH = [[(-0.115, 0.31), (-0.055, 0.31), (-0.06, 0.45), (-0.11, 0.45)],
         [(0.055, 0.31), (0.115, 0.31), (0.11, 0.45), (0.06, 0.45)]]


def skull(t, cx, cy, s, colour, alpha=1.0, ink="#0B0913", lit=0.2):
    """The difficulty skull, `s` points high: a dark rim round the whole, so it reads over any ground; the right half
    of the crown a facet darker, the upper left lit."""
    shape = lambda pts: t.poly([(cx + x * s, cy + y * s) for x, y in pts])   # noqa: E731
    head = np.minimum(shape(CROWN), shape(JAW))
    holes = np.minimum.reduce([shape(p) for p in EYES + [NOSE] + TEETH])
    body = np.maximum(head, -holes)
    t.paint(head - max(0.09 * s, 1.0), ink, 0.9 * alpha)
    t.paint(body, colour, alpha)
    t.paint(np.maximum(body, -(t.x - cx)), "#000000", 0.16 * alpha)
    t.paint(np.maximum(body, (t.y - cy) + (t.x - cx) * 0.7 + 0.12 * s), "#FFFFFF", lit * alpha)


def pic(t, path, x, y, size, alpha=1.0):
    rgba = rs.load(path)
    rgba = rs.shrink(rgba, size * ui.K / rgba.shape[1])
    if alpha != 1.0:
        rgba[..., 3] *= alpha
    t.image(rgba, x, y)


def arrow(t, cx, cy, s, up, colour=None):
    """The type edge's arrow: up, green, the lead hits this foe harder; down, red, it hits the lead harder."""
    k = -1 if up else 1
    t.paint(t.poly([(cx, cy + k * s * 0.5), (cx + s * 0.45, cy - k * s * 0.15), (cx + s * 0.16, cy - k * s * 0.15),
                    (cx + s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.15),
                    (cx - s * 0.45, cy - k * s * 0.15)]) - 0.7, "#0B0913", 0.9)
    t.paint(t.poly([(cx, cy + k * s * 0.5), (cx + s * 0.45, cy - k * s * 0.15), (cx + s * 0.16, cy - k * s * 0.15),
                    (cx + s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.15),
                    (cx - s * 0.45, cy - k * s * 0.15)]), colour or (UP if up else DOWN))


def bar(t, x0, y0, x1, h, share, pal, phases=0):
    """Health as light in its dark channel, cut on the slant, Ember from its top to its foot; a keeper's phases as
    notches with a brass point over each."""
    s = h * 0.45
    d = t.poly([(x0 + s, y0), (x1, y0), (x1 - s, y0 + h), (x0, y0 + h)])
    t.paint(d - 1.0, pal["ink"], 0.9)
    t.paint(d, pal["channel"])
    xe = x0 + s + (x1 - x0 - s) * share
    lit = np.maximum(d + 0.8, (t.x - xe) + (t.y - y0) * s / h)
    v = np.clip((t.y - y0) / h, 0, 1)
    ramp = np.zeros(t.x.shape + (3,), np.float32)
    stops = [(p, ui.c(code)) for p, code in EMBER]
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        f = np.clip((v - p0) / max(p1 - p0, 1e-6), 0, 1)[..., None]
        inside = ((v >= p0) & (v <= p1))[..., None]
        ramp = np.where(inside, c0 + (c1 - c0) * f, ramp)
    t.paint(lit, ramp)
    t.paint(np.maximum(lit, np.abs(t.y - (y0 + 1.6)) - 0.5), "#FFE3B8", 0.55)        # its sheen along the top
    t.paint(np.maximum(lit, -((t.x - xe) + (t.y - y0) * s / h) - 1.2), "#FFFFFF", 0.6)   # its bright front
    for k in range(1, phases):
        notch(t, x0 + s + (x1 - x0 - s) * k / phases, y0, h, s, pal["ink"])
    t.line(d, 0.75, pal["edge"], 0.9)


def horn(t, bx, y0, size, side, metal=BRASS):
    """One of an elite's horns: a shard swept out and up from the frame's top, its root at (bx, y0)."""
    pts = [(bx - side * 5, y0 + 0.5), (bx + side * 4, y0 + 0.5), (bx + side * (size * 0.9), y0 - size),
           (bx + side * (size * 0.35), y0 - size * 0.45)]
    d = t.poly(pts)
    t.paint(d - 1.0, "#0B0913", 0.9)
    t.paint(d, t.ramp(metal[0], metal[1], (y0 - t.y) / size * -1 + 1))
    t.paint(np.maximum(d, (t.x - bx) * side * -1 + (t.y - y0) * 0.2), "#FFFFFF", 0.25)


def horns(t, x0, x1, y0, size, metal):
    """An elite's horns: two shards swept out and up from the frame's top corners."""
    for side in (-1, 1):
        horn(t, x0 + 14 if side < 0 else x1 - 14, y0, size, side, metal)


def notch(t, px, y0, h, s, ink):
    """A keeper's phase on its bar: a dark notch through the light on the bar's slant, a brass point over it."""
    t.paint(t.poly([(px - 0.8, y0 - 1.5), (px + 0.8, y0 - 1.5), (px + 0.8 - s, y0 + h + 1.5), (px - 0.8 - s, y0 + h + 1.5)]),
            ink, 0.95)
    t.paint(t.poly([(px - 2.6, y0 - 4.5), (px + 2.6, y0 - 4.5), (px, y0 - 0.5)]), BRASS[0])


def tab(t, x0, ty, th, tw, slant):
    """CR's gold tab: a small slanted plate, its top's light, a hairline of deeper gold."""
    d = t.poly([(x0 + th * slant, ty), (x0 + tw + th * slant, ty), (x0 + tw, ty + th), (x0, ty + th)])
    t.paint(d - 1.0, INK_GOLD, 0.9)
    t.paint(d, t.ramp(GOLD[0], GOLD[1], (t.y - ty) / th))
    t.paint(np.maximum(d, np.abs(t.y - (ty + 1.0)) - 0.45), "#FFFFFF", 0.7)
    t.line(d, 0.6, "#A8701E", 0.8)


def crest(t, cx, y0, size):
    """A keeper's crest: one tall shard on the frame's top, between two short ones."""
    for dx, h, w in ((0, size, size * 0.34), (-size * 0.5, size * 0.55, size * 0.22), (size * 0.5, size * 0.55, size * 0.22)):
        d = t.poly([(cx + dx, y0 - h), (cx + dx + w, y0 - h * 0.35), (cx + dx, y0 + 2), (cx + dx - w, y0 - h * 0.35)])
        t.paint(d - 1.0, "#0B0913", 0.9)
        t.paint(d, t.ramp(BRASS[0], BRASS[1], (t.y - (y0 - h)) / (h + 2)))
        t.paint(np.maximum(d, (t.x - (cx + dx))), "#000000", 0.18)


def card(t, x0, y0, kind, tier, pal, name, level, share, health, gem="Strength", edge=None, slant=0.0):
    """The target's card. Returns its size. With `slant`, the fight HUD's plate instead of the kit's cut panel: a
    parallelogram leaning like the lead's card and the old target card (its ends `slant` of its height across), its lit
    end the left, and the health's digits on a dark band (AR45's must-fix 1)."""
    w, h = {"Shade": (216, 42), "Elite": (216, 42), "Keeper": (300, 50)}[kind]
    x1, y1 = x0 + w, y0 + h
    lean = h * slant
    if slant:
        d = t.poly([(x0 + lean, y0), (x1, y0), (x1 - lean, y1), (x0, y1)])
    else:
        d = t.poly(ui.cut_box(x0, y0, x1, y1, 9, 0, 9, 0))
    t.glow(d, 6.0, "#000000", 0.4)
    t.paint(d, t.ramp(pal["panel"][0], pal["panel"][1], (t.y - y0) / h), 0.93)
    t.paint(np.maximum(d, (t.x - x0) + (t.y - y0) - 9 * 3.4 - lean), pal["facet"], 0.08)
    if kind == "Shade":
        t.line(d, 1.0, pal["edge"], 0.95)
    else:   # an elite's and a keeper's frame: brass, a hairline of the panel's edge inside it
        t.line(d, 1.6, BRASS[1], 1.0)
        t.line(d, 0.8, BRASS[0], 0.9)
        t.line(d + 1.6, 0.6, pal["edge"], 0.8)
    if slant:
        t.paint(ui.sd_segment(t.x, t.y, (x0 + 0.6, y1 - 0.8), (x0 + lean + 0.2, y0 + 0.6)) - 0.7, pal["glint"], 0.85)
        t.paint(ui.sd_segment(t.x, t.y, (x1 - lean, y1 - 0.6), (x1 - 0.6, y0 + 0.8)) - 0.5, pal["glint"], 0.35)
    else:
        t.paint(ui.sd_segment(t.x, t.y, (x0 + 0.5, y0 + 9), (x0 + 9, y0 + 0.5)) - 0.6, pal["glint"], 0.85)
        t.paint(ui.sd_segment(t.x, t.y, (x1 - 9, y1 - 0.5), (x1 - 0.5, y1 - 9)) - 0.5, pal["glint"], 0.35)
    if kind == "Elite":
        horns(t, x0 + lean, x1, y0, 11, BRASS)
    if kind == "Keeper":
        horns(t, x0 + lean, x1, y0, 14, BRASS)
        crest(t, (x0 + lean + x1) / 2, y0, 12)
    big = kind == "Keeper"
    name_size = 16 if big else 14
    row = y0 + (6 if not big else 7)
    s = 15 if not big else 17
    ink_in = lean * 0.75                     # the top row starts clear of the lit end
    _, colour, alpha = TIERS[tier]
    skull(t, x0 + 14 + ink_in, row + name_size * 0.36, s, colour, alpha, pal["ink"])
    lv = f"Lv {level}"
    faint = LEVEL_FAINT_B if pal is C_SYS else LEVEL_FAINT
    t.text(x0 + 25 + ink_in, row, name_size, lv, faint if tier == 0 else colour, bold=0.25 if tier else 0.1,
           layer="outlined")
    t.text(x0 + 25 + ink_in + len(lv) * name_size * 0.5 + 7, row, name_size, name, pal["text"], bold=0.12,
           layer="outlined")
    gx = x1 - 22
    pic(t, KIT / f"Gem{gem}.png", gx - 7, row - 2.5, 15)
    if edge is not None:
        arrow(t, gx + 12, row + 5, 9, edge)
    bh = 13 if not big else 15
    by = y1 - bh - 5
    bar(t, x0 + 5 + 5 * slant, by, x1 - 5 - (h - 5 - bh) * slant, bh, share, pal, phases=3 if big else 0)
    mid = (x0 + x1) / 2
    if slant:
        nw = len(health) * 11 * 0.52 + 14
        band = t.poly([(mid - nw / 2 + bh * 0.3, by + 0.5), (mid + nw / 2, by + 0.5), (mid + nw / 2 - bh * 0.3, by + bh - 0.5),
                       (mid - nw / 2, by + bh - 0.5)])
        t.paint(band, pal["channel"], 0.72)
    t.text(mid, by + (bh - 11 * 0.72) / 2, 11, health, IVORY, "CENTER", bold=0.1, layer="outlined")
    return w, h


def cr_tab(t, x0, y0, size, value, slant=0.32):
    """CR's look: "CR" on a small slanted gold tab, the number beside it in pale ivory, upright and wide apart. `size`
    is the number's text size; the tab stands as high as its digits and a little more."""
    th = size * 0.72 + size * 0.22
    tw = size * 1.25
    ty = y0 - size * 0.11
    tab(t, x0, ty, th, tw, slant)
    small = size * 0.62
    t.text(x0 + tw / 2 + th * slant / 2, ty + (th - small * 0.72) / 2, small, "CR", INK_GOLD, "CENTER", shear=0.2,
           bold=0.35)
    t.text(x0 + tw + th * slant + size * 0.3, y0, size, value, IVORY, layer="ivory", bold=0.06)
    t.sheet.items[-1]["space"] = 1.18     # wide apart, as AR44's plain digits
    return tw + th * slant + size * 0.3 + len(value) * size * 0.62


def finish(sheet):
    """The sheet's words: plain ones as they are, the cards' with a hairline dark edge, the ivory digits with a hairline
    edge and a soft shadow under them (AR44's plain take)."""
    layers = ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items)
    for name, layer in layers.items():
        a = layer[..., 3]
        if name == "outlined":
            ui.over(sheet.px, "#0B0913", np.clip(ui.spread(a, 2) * 0.9, 0, 1))
        if name == "ivory":
            soft = np.roll(np.roll(ui.spread(a, 2), 2, 0), 1, 1)
            ui.over(sheet.px, "#000000", soft * 0.35)
            ui.over(sheet.px, "#15120E", ui.spread(a, 1) * 0.9)
        rs.paste(sheet.px, layer, 0, 0)


def scaled(px, factor):
    h, w = px.shape[:2]
    H, W = round(h * factor), round(w * factor)
    ys = np.clip((np.arange(H) + 0.5) / factor - 0.5, 0, h - 1)
    xs = np.clip((np.arange(W) + 0.5) / factor - 0.5, 0, w - 1)
    y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
    y1, x1 = np.minimum(y0 + 1, h - 1), np.minimum(x0 + 1, w - 1)
    fy, fx = (ys - y0)[:, None, None], (xs - x0)[None, :, None]
    rows = px[y0] * (1 - fy) + px[y1] * fy
    return (rows[:, x0] * (1 - fx) + rows[:, x1] * fx).astype(np.float32)


def blank(px, r0, r1, c0, c1):
    """A box filled from its top row to its bottom row, column by column: the old readout lifted out of a capture."""
    top, foot = px[r0 - 1, c0:c1].copy(), px[r1, c0:c1].copy()
    f = np.linspace(0, 1, r1 - r0)[:, None, None]
    px[r0:r1, c0:c1] = top[None] * (1 - f) + foot[None] * f


def main():
    out = bl.out_dir()
    W = 16 + 4 * (300 + 16)
    rows_h = 46 + 3 * 70
    H = 1400
    sheet = ui.Sheet(W, H, "#101117")
    t = sheet.tile(0, 0, W, H)
    ink, soft = "#EDE6D6", "#B4AC9C"
    t.text(16, 16, 20, "AR45: the foes' cards with their difficulty skulls, and CR's gold tab (blockout, for research's pick)",
           ink, bold=0.2)
    t.text(16, 44, 13, "At 2 pixels a point. The skull's tier is the foe's CR against the lead's (research's seeds: grey under "
                       "0.6, white to 1.05, yellow to 1.3, red above). Blender's face stands in for the kit's.", soft)
    # --- the skull alone
    y = 76
    t.text(16, y, 15, "1. The skull, ours: cut like a shard. At 16 points over the card and over the lanterns; at 48 to read "
                      "its shape", ink)
    lanterns = rs.load(STILL)[18:83, 330:570]
    t.image(scaled(lanterns, 2 / STILL_PPT)[:120, :640], 16 + 4 * 100 + 40, y + 24)
    for k, (word, colour, alpha) in enumerate(TIERS):
        bx = 16 + k * 100
        t.paint(t.poly(ui.cut_box(bx, y + 24, bx + 90, y + 84, 6, 0, 6, 0)), t.ramp(SEAM["panel"][0], SEAM["panel"][1],
                                                                                     (t.y - y - 24) / 60))
        skull(t, bx + 22, y + 44, 16, colour, alpha, SEAM["ink"])
        t.text(bx + 34, y + 37, 14, "Lv 12", LEVEL_FAINT if k == 0 else colour, bold=0.25 if k else 0.1, layer="outlined")
        t.text(bx + 4, y + 90, 11, word, soft)
        skull(t, 16 + 4 * 100 + 40 + 30 + k * 48, y + 44, 16, colour, alpha, SEAM["ink"])
        skull(t, 16 + 4 * 100 + 40 + 340 + k * 64, y + 48, 48, colour, alpha, SEAM["ink"])
    y += 150
    # --- the cards, in each take, every tier
    cast = [("Shade", "Brawler", 12, 0.62, "679/1,096", "Strength", True),
            ("Elite", "Brawler", 14, 0.4, "1,204/3,010", "Technique", False),
            ("Keeper", "The Lamplighter", 15, 0.73, "11,284/15,457", "Intelligence", None)]
    for take, pal in TAKES.items():
        t.text(16, y, 15, f"2. The target's card, {take}: a Shade, an elite, a keeper, in each tier", ink)
        for r, (kind, name, level, share, health, gem, edge) in enumerate(cast):
            for k in range(4):
                card(t, 16 + k * 316, y + 34 + r * 70, kind, k, pal, name, level, share, health, gem, edge)
        y += rows_h + 30
    # --- in a fight, at the phone's own size
    t.text(16, y, 15, "3. In a fight, top centre: A and B over the still's lanterns, at 2 pixels a point and at the phone's 1 "
                      "(a Shade, yellow; an elite, red; a keeper, white)", ink)
    still = rs.load(STILL)
    crop = still[60:200, 230:730].copy()
    blank(crop, 38, 96, 122, 378)                          # the old card lifted out
    top = scaled(crop, 2 / STILL_PPT)                      # the top centre of the phone
    spots = []
    for j, pal in enumerate(TAKES.values()):
        x = 16 + j * 470
        t.image(top[:, :900], x, y + 24)
        card(t, x + 120, y + 24 + 36, "Shade", 2, pal, "Brawler", 12, 0.62, "679/1,096", "Strength", True)
        spots.append((x, y + 24, 450, 126))
    t.image(top[:, :900], 16 + 2 * 470, y + 24)
    card(t, 16 + 2 * 470 + 75, y + 24 + 34, "Keeper", 1, SEAM, "The Lamplighter", 15, 0.73, "11,284/15,457", "Intelligence")
    spots.append((16 + 2 * 470, y + 24, 450, 126))
    y += 24 + 126 + 20
    small_y = y
    y += 90
    # --- CR's tab
    t.text(16, y, 15, "4. CR's tab: alone, at the lead's feet in a fight, on the Overview in the Shard light's place, on an "
                      "item's row", ink)
    for k, size in enumerate((14, 18, 24)):
        cr_tab(t, 16 + k * 190, y + 34, size, "29,070")
    feet = scaled(still[220:380, 380:640], 2 / STILL_PPT)
    t.image(feet, 16 + 600, y + 24)
    cr_tab(t, 16 + 600 + 70, y + 24 + 116, 14, "29,070")
    menu = rs.load(MENU)
    box = menu[360:784, 243:640].copy()
    blank(box, 616 - 360, 702 - 360, 290 - 243, 525 - 243)   # AR23's readout lifted out
    t.image(box, 16 + 900, y + 24)
    cr_tab(t, 16 + 900 + 30, y + 24 + 132, 22, "29,070")
    rowx, rowy = 16, y + 110
    t.paint(t.poly(ui.cut_box(rowx, rowy, rowx + 270, rowy + 48, 6, 0, 6, 0)),
            t.ramp(SEAM["panel"][0], SEAM["panel"][1], (t.y - rowy) / 48))
    t.line(t.poly(ui.cut_box(rowx, rowy, rowx + 270, rowy + 48, 6, 0, 6, 0)), 1.0, SEAM["edge"])
    t.text(rowx + 12, rowy + 9, 14, "Rook", SEAM["text"], bold=0.12)
    t.text(rowx + 12, rowy + 29, 11, "Common · Level 12", SEAM["soft"])
    cr_tab(t, rowx + 136, rowy + 17, 16, "29,070")
    y += 24 + 300
    finish(sheet)
    # the phone's own size: each fight view at 1 pixel a point, under the views
    for k, (x, sy, w, h) in enumerate(spots):
        crop = sheet.px[round(sy * 2):round((sy + h) * 2), round(x * 2):round((x + w) * 2)]
        rs.paste(sheet.px, rs.shrink(crop, 0.5), round((16 + k * 470) * 2), round(small_y * 2))
    rs.save(sheet.px, out / "foe_cards.png")


# --- the cut: research's pick, B (AR45, "Research's verdict on the sheet", 2026-11-19, 11:59) ---------------------------

KIT_CUT = (10.0, 3.0, 10.0, 3.0)    # the kit's panel: cut 10 at its top left and foot right, 3 at the others (ui_kit.py)
LEVEL_FAINT_B = "#D3D1DC"           # the grey tier's level on B's teal: 4.6 to 1 over the panel's top (must-fix 2)
SLICE_INK = "#0E1D23"               # B's ink: a rim that stays dark under any tint
TINTS = ((LEVEL_FAINT, 0.45), ("#F6F2E8", 0.0), ("#FFC83A", 0.0), ("#FF4F42", 0.0))   # a skull's tint, ImageTransparency


def clear(w, h):
    """A transparent tile, w by h points, at the image's own 4 pixels a point."""
    sheet = ui.Sheet(w, h, "#000000")
    sheet.px[:] = 0
    return sheet.tile(0, 0, w, h)


def luminance(code):
    """WCAG's relative luminance of a colour code."""
    v = np.array([int(code[i:i + 2], 16) / 255 for i in (1, 3, 5)])
    v = np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4)
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def images():
    """AR45's new images in B, at 4 pixels a point; every other piece of the cards is the kit's own (the panel's
    slices tinted in C's system colours, the type gems, the bar). Returns {name: (pixels, entry)}."""
    ui.K = 4
    made = {}

    t = clear(18, 18)
    skull(t, 9, 9, 16, "#F2F2F2", ink=SLICE_INK, lit=0.6)
    made["Skull"] = (t.px.copy(), dict(
        points=[18, 18], tint="the tier's colour (ImageColor3); its rim stays dark under any tint",
        anchor=[9, 9], drawnAt=16,
        use="the difficulty skull: drawn 16 points high in an 18 point box, its centre the anchor. On a Shade's and an "
            "elite's card at 15 high (the box 16.9), a keeper's at 17 (19.1); its centre 14 from the card's left, on the "
            "level's row. The faint tier at ImageTransparency 0.45; the others solid"))

    t = clear(10, 10)
    arrow(t, 5, 5, 9, True, colour="#FFFFFF")
    made["EdgeArrow"] = (t.px.copy(), dict(
        points=[10, 10], tint="green (#7CF0A4) up, red (#FF786E) down", anchor=[5, 5],
        use="the type edge, right of the type gem, 9 points high: up as drawn; down at Rotation 180"))

    t = clear(32, 32)
    d = t.poly(ui.cut_box(0, 0, 32, 32, *KIT_CUT))
    t.line(d, 1.6, BRASS[1])
    t.line(d, 0.8, BRASS[0], 0.9)
    made["CardRankEdge"] = (t.px.copy(), dict(
        points=[32, 32], cut=[12, 12, 12, 12], tint=None,
        use="an elite's and a keeper's edge, in place of PanelEdge: brass, the kit panel's own cut, sliced like it "
            "(Cut 12 each side). Its own colours, never tinted"))

    t = clear(20, 17)
    horn(t, 14.6, 15.5, 14, -1)
    left = t.px.copy()
    made["RankHornLeft"] = (left, dict(
        points=[20, 17], tint=None, anchor=[14.6, 15.5], drawnAt=14,
        use="a horn's root (the anchor) on the card's top edge, 14 in from its left corner. A keeper's at 14 high, as "
            "drawn; an elite's at 11 (scale 11/14, its anchor with it). Over the card, under nothing"))
    made["RankHornRight"] = (np.ascontiguousarray(left[:, ::-1]), dict(
        points=[20, 17], tint=None, anchor=[5.4, 15.5], drawnAt=14,
        use="the left horn mirrored: its root 14 in from the card's right corner"))

    t = clear(20, 17)
    crest(t, 10, 14, 12)
    made["RankCrest"] = (t.px.copy(), dict(
        points=[20, 17], tint=None, anchor=[10, 14],
        use="a keeper's crest: three brass shards, the anchor on the card's top edge at its middle"))

    h, s = 15.0, 15.0 * 0.45
    t = clear(12, 22)
    notch(t, 8, 5, h, s, SLICE_INK)
    made["PhaseNotch"] = (t.px.copy(), dict(
        points=[12, 22], tint=None, anchor=[8, 5],
        use="a keeper's phase: the anchor on the bar's top edge, at 1/3 and 2/3 of its length. Drawn for the keeper's "
            "15 point bar with its slant (0.45 of its height); the dark cut through the light, the brass point above"))

    size = 24.0
    th, tw = size * 0.94, size * 1.25
    t = clear(40, 25)
    tab(t, 1.2, 1.2, th, tw, 0.32)
    made["CrTab"] = (t.px.copy(), dict(
        points=[40, 25], tint=None, plate=[1.2, 1.2, round(tw + th * 0.32, 2), round(th, 2)],
        use="CR's gold tab, drawn for a 24 point number: its plate's left, top, width and height in the box. It scales "
            "with the number (a 14 point number takes 14/24). \"CR\" is the game's text over it: dark ink #4A2A08, "
            "bold, 0.62 of the number's size, centred on the plate; the number right of it in ivory #F7F1E3, upright "
            "and wide apart, with AR44's plain take's outline and shadow"))

    # --- B on the fight HUD's slant (research's second look, 12:32): the plate in three, and the elite's shards
    sw, sh = SLANT_BOX
    x0, y0, x1, y1 = SLANT_PAD, SLANT_PAD, sw - SLANT_PAD, sh - SLANT_PAD
    lean = (y1 - y0) * SLANT
    plate = [(x0 + lean, y0), (x1, y0), (x1 - lean, y1), (x0, y1)]
    common = dict(points=[sw, sh], cut=list(SLANT_CUT), pad=SLANT_PAD)
    slicing = ("Sliced at Cut (left, top, right, foot), its slanted ends inside the end slices: drawn at its own height, "
               "it stretches along only. The card's box is the image less Pad on every side.")

    t = clear(sw, sh)
    d = t.poly(plate)
    t.glow(d, 6.0, "#000000", 0.4)
    t.paint(d, "#FFFFFF")
    made["CardSlantFill"] = (t.px.copy(), dict(
        common, tint="C's panel, #34606C at its top to #2A4E5A at its foot (a UIGradient), ImageTransparency 0.06; "
                     "its shadow stays black under any tint",
        use="the target card's plate, leaning like the lead's card (its ends 0.4 of its height across). " + slicing))

    t = clear(sw, sh)
    d = t.poly(plate)
    t.line(d, 1.0, "#FFFFFF", 0.95)
    t.paint(ui.sd_segment(t.x, t.y, (x0 + 0.6, y1 - 0.8), (x0 + lean + 0.2, y0 + 0.6)) - 0.7, "#FFFFFF")
    made["CardSlantEdge"] = (t.px.copy(), dict(
        common, tint="C's edge, #E2CFA4",
        use="a Shade's edge over the plate: a hairline, its lit end the left. " + slicing))

    t = clear(sw, sh)
    d = t.poly(plate)
    t.line(d, 1.6, BRASS[1])
    t.line(d, 0.8, BRASS[0], 0.9)
    t.line(d + 1.6, 0.6, C_SYS["edge"], 0.8)
    t.paint(ui.sd_segment(t.x, t.y, (x0 + 0.6, y1 - 0.8), (x0 + lean + 0.2, y0 + 0.6)) - 0.6, "#FFF3C8", 0.9)
    made["CardSlantRankEdge"] = (t.px.copy(), dict(
        common, tint=None,
        use="an elite's edge, in place of CardSlantEdge: brass, a hairline of C's edge inside it, its own colours, "
            "never tinted. " + slicing))

    t = clear(*SHARD_BOX)
    shard(t, *SHARD_ROOT, -1)
    left = t.px.copy()
    made["RankShardLeft"] = (left, dict(
        points=list(SHARD_BOX), tint=None, anchor=list(SHARD_ROOT),
        use="an elite's mark: a solid brass shard about 6 points tall, leaning out. Its root (the anchor) on the card's "
            "top edge, 14 in from where the top edge starts (the plate's lean, then 14). Its own colours; never scaled "
            "down"))
    made["RankShardRight"] = (np.ascontiguousarray(left[:, ::-1]), dict(
        points=list(SHARD_BOX), tint=None, anchor=[SHARD_BOX[0] - SHARD_ROOT[0], SHARD_ROOT[1]],
        use="the left shard mirrored: its root 14 in from the card's top right corner"))
    return made


# B on the slant: the plate's box, its cut and its pad (points), and the shard's box and root
SLANT_PAD = 8.0
SLANT_BOX = (66.0, 58.0)            # a 50 by 42 plate in an 8 point pad, its ends 16.8 across
SLANT_CUT = (29.0, 28.0, 29.0, 28.0)
SHARD_BOX = (10.0, 10.0)
SHARD_ROOT = (5.5, 8.0)
UNUSED = {"CardRankEdge": "the upright cut, replaced by B on the slant (research, 12:32)",
          "RankHornLeft": "the thin horns, replaced by the shards (research's must-fix, 12:32)",
          "RankHornRight": "the thin horns, replaced by the shards (research's must-fix, 12:32)",
          "RankCrest": "the keeper keeps TR5's BossBar (the director, 12:24)",
          "PhaseNotch": "the keeper keeps TR5's BossBar (the director, 12:24)"}


def shard(t, ax, ay, side):
    """An elite's mark: a solid brass shard about 6 points tall, leaning out from its root at (ax, ay) on the card's top
    edge, its base sunk a point into the edge. Two faces, the outer lit, the inner in shade, a dark rim to read over
    the sky."""
    tip = (ax + side * 2.6, ay - 6.2)
    base_out, base_in = (ax + side * 3.6, ay + 1.0), (ax - side * 3.4, ay + 1.0)
    ridge = (ax - side * 0.2, ay + 1.0)
    d = t.poly([base_out, tip, (ax - side * 1.6, ay - 2.6), base_in])
    t.paint(d - 1.0, "#0B0913", 0.92)
    t.paint(d, BRASS[1])
    outer = t.poly([base_out, tip, ridge])
    t.paint(np.maximum(d, outer), t.ramp(BRASS[0], "#D9A94E", (t.y - (ay - 6.2)) / 7.2))
    t.paint(np.maximum(d, ui.sd_segment(t.x, t.y, tip, ridge) - 0.35), "#FFF3C8", 0.7)


def lay_slice(page, px, cut, x, y, w, h, pad=0.0, tint=None, alpha=1.0):
    """A kit slice (4 pixels a point) drawn out to w by h points onto a 2 pixel a point page, as the engine slices it."""
    import ui_kit as uk
    big = uk.stretch(px, cut, w + 2 * pad, h + 2 * pad).copy()
    if tint is not None:
        big[..., :3] *= uk.shade(tint, big.shape[0])
    big[..., 3] *= alpha
    rs.paste(page, rs.shrink(big, 0.5), round((x - pad) * 2), round((y - pad) * 2))


def put(page, px, x, y, scale=1.0, tint=None, alpha=1.0, turn=False):
    """An image (4 pixels a point) at `scale`, its box's top left at (x, y) points, onto the 2 pixel a point page."""
    im = rs.shrink(px, 0.5 * scale).copy()
    if turn:
        im = np.ascontiguousarray(im[::-1, ::-1])
    if tint is not None:
        im[..., :3] *= np.array(rs.rgb(tint), np.float32)
    im[..., 3] *= alpha
    rs.paste(page, im, round(x * 2), round(y * 2))


def built_slant(sheet, made, x, y, kind, tier, name, level, share, health, gem, edge, marks=True):
    """B on the fight HUD's slant as the game builds it: the plate's three images, the shards, then the card's own
    pieces, each clear of the plate's lit end."""
    w, h = 216, 42
    page, pal = sheet.px, C_SYS
    lean = h * SLANT
    lay_slice(page, made["CardSlantFill"][0], SLANT_CUT, x, y, w, h, pad=SLANT_PAD, tint=pal["panel"], alpha=0.94)
    if kind == "Shade":
        lay_slice(page, made["CardSlantEdge"][0], SLANT_CUT, x, y, w, h, pad=SLANT_PAD, tint=pal["edge"])
    else:
        lay_slice(page, made["CardSlantRankEdge"][0], SLANT_CUT, x, y, w, h, pad=SLANT_PAD)
        if marks:
            ax, ay = SHARD_ROOT
            put(page, made["RankShardLeft"][0], x + lean + 14 - ax, y - ay)
            put(page, made["RankShardRight"][0], x + w - 14 - (SHARD_BOX[0] - ax), y - ay)
    name_size, row = 14, y + 6
    inset = lean * 0.75
    colour, see = TINTS[tier]
    sc = 15 / 16
    put(page, made["Skull"][0], x + 14 + inset - 9 * sc, row + name_size * 0.36 - 9 * sc, sc, colour, 1 - see)
    t = sheet.tile(x, y - 2, w, h + 4)
    lv = f"Lv {level}"
    t.text(25 + inset, row - y + 2, name_size, lv, LEVEL_FAINT_B if tier == 0 else colour, bold=0.25, layer="outlined")
    t.text(25 + inset + len(lv) * name_size * 0.5 + 7, row - y + 2, name_size, name, pal["text"], bold=0.12,
           layer="outlined")
    gx = x + w - 22
    gem_px = rs.load(KIT / f"Gem{gem}.png")
    put(page, gem_px, gx - 7, row - 2.5, 15 * 4 / gem_px.shape[1])
    if edge is not None:
        put(page, made["EdgeArrow"][0], gx + 12 - 5, row + 5 - 5, 1.0, UP if edge else DOWN, turn=not edge)
    bh = 13
    by = y + h - bh - 5
    bx0, bx1 = 5 + 5 * SLANT, w - 5 - (h - 5 - bh) * SLANT
    bar(sheet.tile(x, by - 6, w, bh + 8), bx0, 6, bx1, bh, share, pal, phases=0)
    nw = len(health) * 11 * 0.52 + 14
    mid = (bx0 + bx1) / 2
    band = sheet.tile(x + mid - nw / 2 - 4, by, nw + 8, bh)
    band.paint(band.poly([(4 + bh * 0.3, 0.5), (nw + 4, 0.5), (nw + 4 - bh * 0.3, bh - 0.5), (4, bh - 0.5)]),
               pal["channel"], 0.72)
    sheet.tile(x, by, w, bh).text(mid, (bh - 11 * 0.72) / 2, 11, health, IVORY, "CENTER", bold=0.1, layer="outlined")
    return w, h


def cut(out):
    made = images()
    folder = out / "images"
    folder.mkdir(parents=True, exist_ok=True)
    listing = {}
    for name, (px, entry) in made.items():
        rs.save(rs.bleed(px), folder / f"{name}.png")
        listing[name] = dict(file=f"images/{name}.png", pixels=[px.shape[1], px.shape[0]], **entry)
        if name in UNUSED:
            listing[name]["unused"] = UNUSED[name]
    ratios = {f"{code} over {pal}": round(contrast(code, pal), 2)
              for code in (LEVEL_FAINT_B, "#F6F2E8", "#FFC83A", "#FF4F42") for pal in C_SYS["panel"]}
    import json
    (out / "foes.json").write_text(json.dumps(dict(
        pixelsPerPoint=4, palette="C_SYS (AR40's C, the system panel), research's pick B, on the fight HUD's slant",
        card=dict(points=[216, 42], slant=SLANT,
                  note="the Shade's and the elite's card; the keeper keeps TR5's BossBar. The top row starts 0.75 of "
                       "the lean (12.6) further in than on an upright card; the bar runs from 5 + 0.4 x 5 to 5 + 0.4 x "
                       "24 in from the card's ends, at the foot and the top"),
        levels=dict(colours=[LEVEL_FAINT_B, "#F6F2E8", "#FFC83A", "#FF4F42"], contrast=ratios,
                    note="each over B's panel, top and foot; every level wears the dark outline of AR44's plain take"),
        images=listing), indent=1), encoding="utf-8")
    ui.K = 2
    W, H = 1100, 860
    sheet = ui.Sheet(W, H, "#101117")
    head = sheet.tile(0, 0, W, 90)
    ink, soft = "#EDE6D6", "#B4AC9C"
    head.text(16, 16, 20, "AR45, cut in B on the fight HUD's slant (research, 12:32), for the content check and Faber",
              ink, bold=0.2)
    head.text(16, 44, 13, "Each image in use as it ships at 4 pixels a point over dark, then at 64 px over dark. The rest of the "
                          "card is the kit's own: the type gems, the bar. The keeper keeps TR5's purple bar.", soft)
    # 1. each alone, full size, then 64 px
    x, y = 16, 76
    sheet.tile(0, y, W, 20).text(16, 0, 14, "1. Each in use, alone: as it ships (4 px a point, drawn here at 1 px a pixel), "
                                            "and at 64 px", ink)
    y += 24
    for name, (px, entry) in made.items():
        if name in UNUSED:
            continue
        rs.paste(sheet.px, px, round(x * 2), round(y * 2))
        rs.paste(sheet.px, scaled(px, 64 / max(px.shape[:2])), round(x * 2), round((y + px.shape[0] / 2 + 8) * 2))
        sheet.tile(x, y + px.shape[0] / 2 + 8 + 36, 120, 14).text(0, 0, 11, name, soft)
        x += max(px.shape[1] / 2, 64) + 22
    y += max(px.shape[0] / 2 for name, (px, _) in made.items() if name not in UNUSED) + 66
    # 2. the skull's four tiers, and the arrow both ways
    sheet.tile(0, y, W, 20).text(16, 0, 14, "2. The skull tinted for its four tiers at 64 px and at 16 points (2 and 1 px a point), "
                                            "over B's panel; the arrow up and down", ink)
    y += 24
    plate = sheet.tile(16, y, 620, 80)
    plate.paint(plate.poly(ui.cut_box(0, 0, 620, 80, 10, 3, 10, 3)), plate.ramp(C_SYS["panel"][0], C_SYS["panel"][1],
                                                                                  plate.y / 80))
    for k, (colour, see) in enumerate(TINTS):
        sk = made["Skull"][0]
        put(sheet.px, sk, 26 + k * 90, y + 6, 64 / sk.shape[0] * 2, colour, 1 - see)
        put(sheet.px, sk, 400 + k * 34, y + 14, 1.0, colour, 1 - see)
        small = rs.shrink(sk, 0.25).copy()                  # 1 pixel a point, drawn twice the size to be seen
        small[..., :3] *= np.array(rs.rgb(colour), np.float32)
        small[..., 3] *= 1 - see
        rs.paste(sheet.px, np.repeat(np.repeat(small, 2, 0), 2, 1), round((400 + k * 34) * 2), round((y + 44) * 2))
    put(sheet.px, made["EdgeArrow"][0], 560, y + 16, 1.0, UP)
    put(sheet.px, made["EdgeArrow"][0], 580, y + 16, 1.0, DOWN, turn=True)
    sheet.tile(400, y + 64, 240, 14).text(0, 0, 10, "16 pt at 2 px a point; below, at 1 (doubled)", soft)
    y += 100
    # 3. the cards, built from the kit's slices and these images
    sheet.tile(0, y, W, 20).text(16, 0, 14, "3. The cards built from these images: a Shade (yellow), an elite (red) with its "
                                            "shards, a Shade (the faint tier), an elite (white) with its brass edge alone", ink)
    y += 40
    built_slant(sheet, made, 16, y, "Shade", 2, "Brawler", 12, 0.62, "679/1,096", "Strength", True)
    built_slant(sheet, made, 284, y, "Elite", 3, "Brawler", 14, 0.4, "1,204/3,010", "Technique", False)
    built_slant(sheet, made, 552, y, "Shade", 0, "Brawler", 9, 0.95, "412/433", "Agility", True)
    built_slant(sheet, made, 820, y, "Elite", 1, "Brawler", 11, 0.8, "2,410/3,010", "Intelligence", None, marks=False)
    y += 70
    # 4. CR's tab, built: the image, "CR" and the number as the game's text
    sheet.tile(0, y, W, 20).text(16, 0, 14, "4. CR's tab built: the image, \"CR\" and the number as the game's text (upright), "
                                            "for a 14, 18 and 24 point number", ink)
    y += 30
    tx = 16
    th, tw = 24 * 0.94, 24 * 1.25
    for size in (14, 18, 24):
        sc = size / 24
        put(sheet.px, made["CrTab"][0], tx, y, sc)
        pw, ph = (tw + th * 0.32) * sc, th * sc
        tt = sheet.tile(tx, y, 200, 30)
        tt.text(1.2 * sc + pw / 2, 1.2 * sc + (ph - size * 0.62 * 0.72) / 2, size * 0.62, "CR", INK_GOLD, "CENTER", bold=0.35)
        tt.text(1.2 * sc + pw + size * 0.3, 1.2 * sc + (ph - size * 0.72) / 2, size, "29,070", IVORY, layer="ivory", bold=0.06)
        tx += 260
    # the contrast of each tier's level over the panel
    y += 50
    sheet.tile(0, y, W, 20).text(16, 0, 12, "Each level's colour over B's panel, top / foot: " + "; ".join(
        f"{code} {contrast(code, C_SYS['panel'][0]):.1f} / {contrast(code, C_SYS['panel'][1]):.1f}"
        for code in (LEVEL_FAINT_B, "#F6F2E8", "#FFC83A", "#FF4F42")) + " (to 1). Red is carried by its dark outline.", soft)
    finish(sheet)
    rs.save(sheet.px[:round((y + 30) * 2)], out / "foe_cards_cut.png")


# --- the fit: the cards over the game's own HUD (the director, 12:24: "make sure it compose well to our game") ----------

FIGHT = REPO / "build" / "scratch" / "faber" / "ar44" / "take-now-fight.jpg"   # Faber's phone capture, ~1.11 px a point
OLD_CARD = (95, 162, 338, 604)      # the old target card and the floor's title over it, the capture's rows and columns
OLD_MIDDLE, OLD_TOP = 471, 98       # the old card's middle and top, the capture's pixels
SLANT = 0.4                         # the old target card's lean: its ends 0.4 of its height across (the capture)


def fit(out):
    """Every HUD piece around the cards is the game's own, in Faber's capture: the lead's card, the economy pills, the
    skill buttons, the dock. The old target card is lifted and the new one laid in its place, its middle and top."""
    made = images()
    ui.K = 2
    shot = rs.load(FIGHT)
    lifted = shot.copy()
    blank(lifted, *OLD_CARD)
    f = 2 / STILL_PPT
    now, bare = scaled(shot, f), scaled(lifted, f)
    pw, ph = now.shape[1] / 2, now.shape[0] / 2
    W = 16 + 2 * (pw + 16)
    H = 70 + 2 * (24 + ph + 14) + 24 + ph / 2 + 16
    sheet = ui.Sheet(W, H, "#101117")
    ink, soft = "#EDE6D6", "#B4AC9C"
    head = sheet.tile(0, 0, W, 66)
    head.text(16, 16, 20, "AR45, the fit: B on the fight HUD's slant, built from the cut's images, in Faber's phone capture "
                          "(AR44, Tower floor 1)", ink, bold=0.2)
    head.text(16, 44, 13, "At 2 pixels a point, then each at the phone's own size. Everything but the target card is the game as it "
                          "is; the old card and the floor's title over it are lifted, and the new card laid at its middle and top.",
              soft)
    panes = (("1. Now: the game as it is", None),
             ("2. A Shade, stronger", ("Shade", 2, ("Brawler", 12, 0.62, "679/1,096", "Strength", True), True)),
             ("3. An elite, much stronger: the brass edge and its shards (research's must-fix)",
              ("Elite", 3, ("Brawler", 14, 0.4, "1,204/3,010", "Technique", False), True)),
             ("4. An elite, about even: the brass edge alone (research's fallback)",
              ("Elite", 1, ("Brawler", 11, 0.8, "2,410/3,010", "Intelligence", None), False)))
    spots = []
    for k, (label, what) in enumerate(panes):
        x, y = 16 + (k % 2) * (pw + 16), 70 + (k // 2) * (24 + ph + 14)
        sheet.tile(x, y, pw, 22).text(0, 2, 14, label, ink)
        y += 24
        rs.paste(sheet.px, now if what is None else bare, round(x * 2), round(y * 2))
        spots.append((x, y))
        if what is not None:
            kind, tier, args, marks = what
            built_slant(sheet, made, x + OLD_MIDDLE / STILL_PPT - 108, y + OLD_TOP / STILL_PPT, kind, tier, *args,
                        marks=marks)
    y = 70 + 2 * (24 + ph + 14)
    sheet.tile(0, y, W, 22).text(16, 2, 14, "At the phone's own size (1 pixel a point), in the order above", ink)
    finish(sheet)
    gap = (W - 16 - 4 * pw / 2) / 4
    for k, (x, sy) in enumerate(spots):
        crop = sheet.px[round(sy * 2):round((sy + ph) * 2), round(x * 2):round((x + pw) * 2)]
        rs.paste(sheet.px, rs.shrink(crop, 0.5), round((16 + k * (pw / 2 + gap)) * 2), round((y + 24) * 2))
    rs.save(sheet.px, out / "foe_cards_fit.png")


if __name__ == "__main__":
    rest = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    mode = rest[1] if len(rest) > 1 else None
    if mode == "cut":
        cut(bl.out_dir())
    elif mode == "fit":
        fit(bl.out_dir())
    else:
        main()
