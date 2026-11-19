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

    blender -b --factory-startup --python tools/blender/foe_cards.py -- <abs out>

Writes foe_cards.png, at 2 pixels a point, the fight views at 1 too.
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


def skull(t, cx, cy, s, colour, alpha=1.0, ink="#0B0913"):
    """The difficulty skull, `s` points high: a dark rim round the whole, so it reads over any ground; the right half
    of the crown a facet darker, the upper left lit."""
    shape = lambda pts: t.poly([(cx + x * s, cy + y * s) for x, y in pts])   # noqa: E731
    head = np.minimum(shape(CROWN), shape(JAW))
    holes = np.minimum.reduce([shape(p) for p in EYES + [NOSE] + TEETH])
    body = np.maximum(head, -holes)
    t.paint(head - max(0.09 * s, 1.0), ink, 0.9 * alpha)
    t.paint(body, colour, alpha)
    t.paint(np.maximum(body, -(t.x - cx)), "#000000", 0.16 * alpha)
    t.paint(np.maximum(body, (t.y - cy) + (t.x - cx) * 0.7 + 0.12 * s), "#FFFFFF", 0.2 * alpha)


def pic(t, path, x, y, size, alpha=1.0):
    rgba = rs.load(path)
    rgba = rs.shrink(rgba, size * ui.K / rgba.shape[1])
    if alpha != 1.0:
        rgba[..., 3] *= alpha
    t.image(rgba, x, y)


def arrow(t, cx, cy, s, up):
    k = -1 if up else 1
    t.paint(t.poly([(cx, cy + k * s * 0.5), (cx + s * 0.45, cy - k * s * 0.15), (cx + s * 0.16, cy - k * s * 0.15),
                    (cx + s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.15),
                    (cx - s * 0.45, cy - k * s * 0.15)]) - 0.7, "#0B0913", 0.9)
    t.paint(t.poly([(cx, cy + k * s * 0.5), (cx + s * 0.45, cy - k * s * 0.15), (cx + s * 0.16, cy - k * s * 0.15),
                    (cx + s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.5), (cx - s * 0.16, cy - k * s * 0.15),
                    (cx - s * 0.45, cy - k * s * 0.15)]), UP if up else DOWN)


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
        px = x0 + s + (x1 - x0 - s) * k / phases
        t.paint(t.poly([(px - 0.8 + s * 0.0, y0 - 1.5), (px + 0.8, y0 - 1.5), (px + 0.8 - s, y0 + h + 1.5),
                        (px - 0.8 - s, y0 + h + 1.5)]), pal["ink"], 0.95)
        t.paint(t.poly([(px - 2.6, y0 - 4.5), (px + 2.6, y0 - 4.5), (px, y0 - 0.5)]), BRASS[0])
    t.line(d, 0.75, pal["edge"], 0.9)


def horns(t, x0, x1, y0, size, metal):
    """An elite's horns: two shards swept out and up from the frame's top corners."""
    for side in (-1, 1):
        bx = x0 + 14 if side < 0 else x1 - 14
        pts = [(bx - side * 5, y0 + 0.5), (bx + side * 4, y0 + 0.5), (bx + side * (size * 0.9), y0 - size),
               (bx + side * (size * 0.35), y0 - size * 0.45)]
        d = t.poly(pts)
        t.paint(d - 1.0, "#0B0913", 0.9)
        t.paint(d, t.ramp(metal[0], metal[1], (y0 - t.y) / size * -1 + 1))
        t.paint(np.maximum(d, (t.x - bx) * side * -1 + (t.y - y0) * 0.2), "#FFFFFF", 0.25)


def crest(t, cx, y0, size):
    """A keeper's crest: one tall shard on the frame's top, between two short ones."""
    for dx, h, w in ((0, size, size * 0.34), (-size * 0.5, size * 0.55, size * 0.22), (size * 0.5, size * 0.55, size * 0.22)):
        d = t.poly([(cx + dx, y0 - h), (cx + dx + w, y0 - h * 0.35), (cx + dx, y0 + 2), (cx + dx - w, y0 - h * 0.35)])
        t.paint(d - 1.0, "#0B0913", 0.9)
        t.paint(d, t.ramp(BRASS[0], BRASS[1], (t.y - (y0 - h)) / (h + 2)))
        t.paint(np.maximum(d, (t.x - (cx + dx))), "#000000", 0.18)


def card(t, x0, y0, kind, tier, pal, name, level, share, health, gem="Strength", edge=None):
    """The target's card. Returns its size."""
    w, h = {"Shade": (216, 42), "Elite": (216, 42), "Keeper": (300, 50)}[kind]
    x1, y1 = x0 + w, y0 + h
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 9, 0, 9, 0))
    t.glow(d, 6.0, "#000000", 0.4)
    t.paint(d, t.ramp(pal["panel"][0], pal["panel"][1], (t.y - y0) / h), 0.93)
    t.paint(np.maximum(d, (t.x - x0) + (t.y - y0) - 9 * 3.4), pal["facet"], 0.08)
    if kind == "Shade":
        t.line(d, 1.0, pal["edge"], 0.95)
    else:   # an elite's and a keeper's frame: brass, a hairline of the panel's edge inside it
        t.line(d, 1.6, BRASS[1], 1.0)
        t.line(d, 0.8, BRASS[0], 0.9)
        t.line(d + 1.6, 0.6, pal["edge"], 0.8)
    t.paint(ui.sd_segment(t.x, t.y, (x0 + 0.5, y0 + 9), (x0 + 9, y0 + 0.5)) - 0.6, pal["glint"], 0.85)
    t.paint(ui.sd_segment(t.x, t.y, (x1 - 9, y1 - 0.5), (x1 - 0.5, y1 - 9)) - 0.5, pal["glint"], 0.35)
    if kind == "Elite":
        horns(t, x0, x1, y0, 11, BRASS)
    if kind == "Keeper":
        horns(t, x0, x1, y0, 14, BRASS)
        crest(t, (x0 + x1) / 2, y0, 12)
    big = kind == "Keeper"
    name_size = 16 if big else 14
    row = y0 + (6 if not big else 7)
    s = 15 if not big else 17
    _, colour, alpha = TIERS[tier]
    skull(t, x0 + 14, row + name_size * 0.36, s, colour, alpha, pal["ink"])
    lv = f"Lv {level}"
    t.text(x0 + 25, row, name_size, lv, LEVEL_FAINT if tier == 0 else colour, bold=0.25 if tier else 0.1,
           layer="outlined")
    t.text(x0 + 25 + len(lv) * name_size * 0.5 + 7, row, name_size, name, pal["text"], bold=0.12, layer="outlined")
    gx = x1 - 22
    pic(t, KIT / f"Gem{gem}.png", gx - 7, row - 2.5, 15)
    if edge is not None:
        arrow(t, gx + 12, row + 5, 9, edge)
    bh = 13 if not big else 15
    by = y1 - bh - 5
    bar(t, x0 + 5, by, x1 - 5, bh, share, pal, phases=3 if big else 0)
    t.text((x0 + x1) / 2, by + (bh - 11 * 0.72) / 2, 11, health, IVORY, "CENTER", bold=0.1, layer="outlined")
    return w, h


def cr_tab(t, x0, y0, size, value, slant=0.32):
    """CR's look: "CR" on a small slanted gold tab, the number beside it in pale ivory, upright and wide apart. `size`
    is the number's text size; the tab stands as high as its digits and a little more."""
    th = size * 0.72 + size * 0.22
    tw = size * 1.25
    ty = y0 - size * 0.11
    pts = [(x0 + th * slant, ty), (x0 + tw + th * slant, ty), (x0 + tw, ty + th), (x0, ty + th)]
    d = t.poly(pts)
    t.paint(d - 1.0, INK_GOLD, 0.9)
    t.paint(d, t.ramp(GOLD[0], GOLD[1], (t.y - ty) / th))
    t.paint(np.maximum(d, np.abs(t.y - (ty + 1.0)) - 0.45), "#FFFFFF", 0.7)
    t.line(d, 0.6, "#A8701E", 0.8)
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


if __name__ == "__main__":
    main()
