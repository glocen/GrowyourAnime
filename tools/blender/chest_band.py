"""The chest opening's band: B, the banner, research's pick (AR24, 2026-11-17, 6a1ea69), with its three fixes. TR34 in
docs/test-requests.md holds the feel line and the beats; the director's form (2026-11-17, 02:20) is a translucent black
band across the whole screen, a title on top, the items centred, OK below. The three directions it was picked from are
02ee5aa's chest_band_directions.py.

The band's body is level, full width and translucent: the bag shows faintly through it, and the cover rises only behind
the words, on a black tag. The slant lives in the cuts: the stripe's ends, the tag's sides, the OK plate. The best's
moment scales with its rarity (research took it, AR24): a Common best gets only its size-up, an Uncommon its rim and the
stripe in its colour, Rare and up the full burst: straight focus lines in its colour inside the band, a white rim, its
rarity's word on a slanted tag.

A mockup at a phone's size in landscape (812 x 375 points, 2 pixels a point), over Faber's phone capture of our own bag
(TR24), dimmed; Blender's face stands in for the game's. Drawn settled (37 Shade Chests of Lantern Row, the best a Rare)
and for one chest (an Uncommon), with the numbers for Faber's block. The content check's conditions (2026-11-17): one
line for the rest of the haul, no reel or casino words, nothing to buy, the best's light in hard lines with nothing
pooling under a tile, the sheets in scratch only.

    blender -b --factory-startup --python tools/blender/chest_band.py -- build/scratch/modulo/ar24
"""
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import inventory_directions as inv  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from inventory_directions import H, K, RARITY, W, poly, vramp  # noqa: E402
from ui_sheet import c  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
BACKDROP = REPO / "build" / "scratch" / "modulo" / "ar24" / "bag_backdrop.png"  # Faber's TR24 capture, 1624 x 750
CHEST = REPO / "build" / "handoff" / "UI" / "chests" / "images" / "ChestShade.png"
CREDITS, STONES = "#40DCC6", "#B9C6D8"  # Config.UIKit's Credits; the forge stones' stand-in

# The haul of 37, sorted from Common up, identical items merged; the best last.
HAUL = (("GearIronSword", 7), ("GearScrapRing", 5), ("GearBronzeHelmet", 5), ("GearIronShoulders", 4),
        ("GearBronzeShortSword", 3), ("GearRowsmithSword", 4), ("GearLanternsteelRing", 4), ("GearStallguardHelmet", 2),
        ("GearRowsmithShoulders", 1), ("GearBandOfGales", 1))
MANY = dict(title="37 Shade Chests of Lantern Row", haul=(("+1,284", "Credits", CREDITS), ("+46", "forge stones", STONES)),
            tiles=HAUL, best="GearBladeOfEmbers")
ONE = dict(title="A Shade Chest of Lantern Row", haul=(("+36", "Credits", CREDITS),), tiles=(), best="GearLanternsteelRing")

# The numbers, in points (seeds for Faber's block, tuned there)
BAND_H, MID = 150.0, 205.0          # the band's height and its middle: centred in what Roblox's top bar leaves
BAND = dict(ink="#08080B", cover=0.7, lines="#1E1E28", lines_cover=0.5, line_pitch=6.0)
STRIPE = dict(colour="#F5F3F8", h=5.0, inset=36.0, lean=18.0)    # along the band's top, its ends cut on the slant
FOOT = dict(colour="#585866", h=1.5, inset=36.0, lean=6.0)        # along its foot
TAG = dict(ink="#040406", cover=0.94, lean=10.0, pad=18.0, accent=2.0)  # the black tag behind the words
TITLE, HAUL_SIZE, ROW_Y = 17.0, 11.0, 58.0                         # the title's size, the haul's, the row's top in the band
S, GAP, BEST_S, BEST_GAP = 48.0, 6.0, 64.0, 16.0                   # a tile, between tiles, the best a size up, before it
OK = dict(w=108.0, h=22.0, lean=8.0, rise=13.0)                    # the OK plate, its middle `rise` over the band's foot
BURST = dict(lines=46, reach=(70.0, 220.0), cover=0.7)             # the focus lines: how many, how far, how strong
LEVEL = {"Common": 0, "Uncommon": 1}                                # Rare and up: 2, the full burst


def rarity(stem):
    return inv.GEAR[stem]["rarity"]


def layout(content):
    """Where every tile and the best stand: one row, centred; the best last and a size up."""
    n = len(content["tiles"])
    total = n * S + max(n - 1, 0) * GAP + (BEST_GAP if n else 0) + BEST_S
    x, y0 = (W - total) / 2, MID - BAND_H / 2
    row = y0 + ROW_Y
    cells = []
    for stem, count in content["tiles"]:
        cells.append((x, row, S, stem, count))
        x += S + GAP
    x += BEST_GAP - GAP if n else 0
    return y0, y0 + BAND_H, cells, (x, row + S / 2 - BEST_S / 2, BEST_S, content["best"], 1)


def slanted(x0, x1, top, foot, lean):
    """A bar whose ends are cut on the slant, leaning right: its top runs `lean` ahead of its foot."""
    return [(x0 + lean, top), (x1 + lean, top), (x1, foot), (x0, foot)]


def haul_width(content, size):
    return sum(inv.width(f"{n} {what}", size) * 0.86 + 22 for n, what, _ in content["haul"]) - 22


def haul_line(scr, content, y, size):
    """The rest of the haul: one line, centred, each in its own colour (the content check's condition 1)."""
    x = (W - haul_width(content, size)) / 2
    for n, what, col in content["haul"]:
        s = f"{n} {what}"
        scr.text(x, y, size, s, col)
        x += inv.width(s, size) * 0.86 + 22


def count_mark(scr, x, y, s, n):
    if n > 1:
        t = scr.area(x + s - 24, y + s - 15, x + s, y + s)
        t.paint(inv.rrect(t, x + s - 23, y + s - 14, x + s - 2, y + s - 2, 2.5), c("#000000"), 0.62)
        scr.text(x + s - 4, y + s - 11, 9, f"×{n}", "#FFFFFF", "RIGHT", bold=0.2)


def tile(scr, x, y, s, stem, n, level=None):
    """A tile: two corners cut, a dark well, its rarity a flag in the low corner and a fine rim. The best (`level` set):
    an Uncommon's rim in its colour, Rare and up a white rim in a glow of its colour."""
    col = RARITY[rarity(stem)]
    t = scr.area(x, y, x + s, y + s, 14)
    cut = 7.0 if level is not None else 5.0
    d = poly(t, ui.cut_box(x, y, x + s, y + s, tl=cut, br=cut))
    if level == 2:
        t.glow(d, 6.0, c(col), 0.45)
    t.paint(d, vramp(t, "#15151C", "#0B0B10", y, y + s), 0.97)
    t.paint(np.maximum(d, poly(t, [(x, y + s - 14), (x + 14, y + s), (x, y + s)])), c(col), 0.95)
    rim = {None: (1.0, col, 0.75), 0: (1.0, col, 0.75), 1: (2.0, col, 1.0), 2: (2.0, "#FFFFFF", 0.95)}[level]
    t.line(d, rim[0], c(rim[1]), rim[2])
    inv.item_art(scr, stem, x + 2, y + 2, s - 4)
    count_mark(scr, x, y, s, n)


def draw(scr, content):
    backdrop = rs.load(BACKDROP)
    scr.paste(backdrop, 0, 0)
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, c("#000000"), 0.45)  # the screen dims behind the band
    y0, y1, cells, best = layout(content)
    bx, by = best[0] + best[2] / 2, best[1] + best[2] / 2
    level = LEVEL.get(rarity(best[3]), 2)
    best_col = RARITY[rarity(best[3])]

    # the body: level, full width, translucent, fine diagonal lines thinning out behind the row
    inside = np.maximum(y0 - t.Y, t.Y - y1)
    t.paint(inside, c(BAND["ink"]), BAND["cover"])
    streaks = ((t.X + t.Y * 0.62) / BAND["line_pitch"]) % 1.0
    away = 1 - 0.75 * np.exp(-((t.X - W / 2) / 230.0) ** 2)
    t.paint(np.maximum(inside, (np.abs(streaks - 0.5) - 0.06) * BAND["line_pitch"]), c(BAND["lines"]),
            BAND["lines_cover"] * away)

    if level == 2:  # the burst: straight focus lines from behind the best, sharp, inside the band only
        ang, r = np.arctan2(t.Y - by, t.X - bx), np.hypot(t.X - bx, t.Y - by)
        slot = ang / (2 * np.pi) * BURST["lines"]
        idx = np.floor(slot)
        lo, hi = BURST["reach"]
        reach = lo + (hi - lo) * ((idx * 0.618) % 1.0)
        width = np.abs((slot - idx) - 0.5) * (2 * np.pi / BURST["lines"]) * r - (0.6 + r * 0.012)
        a = BURST["cover"] * np.clip((reach - r) / 40.0, 0, 1) * (r > best[2] * 0.62)
        t.paint(np.maximum(width, inside), c(best_col), a)

    # the stripe along the top and the line along the foot, their ends cut on the slant
    stripe = best_col if level >= 1 else STRIPE["colour"]
    t.paint(poly(t, slanted(STRIPE["inset"], W - STRIPE["inset"] - STRIPE["lean"], y0 - STRIPE["h"] / 2,
                            y0 + STRIPE["h"] / 2, STRIPE["lean"])), c(stripe))
    t.paint(poly(t, slanted(FOOT["inset"], W - FOOT["inset"] - FOOT["lean"], y1 - FOOT["h"] / 2,
                            y1 + FOOT["h"] / 2, FOOT["lean"])), c(FOOT["colour"]))

    # the words on their black tag, hung from the stripe, centred over the row
    tw = inv.width(content["title"], TITLE) * 0.86 + 31
    w = max(tw, haul_width(content, HAUL_SIZE)) + 2 * TAG["pad"]
    xa, top, foot = (W - w) / 2 - TAG["lean"] / 2, y0 + STRIPE["h"] / 2, y0 + 12 + 19 + HAUL_SIZE * ui.CAP + 7
    tag = poly(t, slanted(xa, xa + w, top, foot, TAG["lean"]))
    t.paint(tag, c(TAG["ink"]), TAG["cover"])
    t.paint(inv.seg(t, (xa + TAG["lean"], top), (xa, foot)) - TAG["accent"] / 2, c(stripe))
    x0 = (W - tw) / 2
    scr.paste(inv.picture(CHEST, 24.0), x0, y0 + 12 + TITLE * ui.CAP / 2 - 12)
    scr.sheet.items.append(dict(x=scr.ox + x0 + 31, y=scr.oy + y0 + 12, size=TITLE, text=content["title"],
                                colour="#FFFFFF", align="LEFT", layer="plain", shear=0.18, bold=0.25 * K))
    haul_line(scr, content, y0 + 12 + 19, HAUL_SIZE)

    for x, y, s, stem, n in cells:
        tile(scr, x, y, s, stem, n)
    tile(scr, *best, level=level)
    if level == 2:  # its rarity's word on a slanted tag under it
        word = rarity(best[3]).upper()
        ww = inv.width(word, 9) * 0.9 + 14
        tx, ty = bx - ww / 2, best[1] + best[2] - 4
        tt = scr.area(tx - 6, ty, tx + ww + 6, ty + 14)
        tt.paint(poly(tt, slanted(tx - 4, tx + ww - 4, ty, ty + 13, 8.0)), c(best_col))
        scr.mid(bx, ty + 6.5, 9, word, "#101015", "CENTER", bold=0.3)

    cx, cy = W / 2, y1 - OK["rise"]
    tt = scr.area(cx - 70, cy - 15, cx + 70, cy + 15)
    tt.paint(poly(tt, slanted(cx - OK["w"] / 2, cx + OK["w"] / 2 - OK["lean"], cy - OK["h"] / 2, cy + OK["h"] / 2,
                              OK["lean"])), c("#FFFFFF"))
    scr.mid(cx, cy, 13, "OK", "#0B0B0F", "CENTER", bold=0.35)


# --- the sheet --------------------------------------------------------------------------------------------------------

NOTES = (
    "Research's pick with its three fixes: the body is level and full width, the slant lives in the cuts (the stripe's "
    "ends, the tag's sides, the OK plate); the title and the haul are centred over the row on their black tag; the body "
    "is translucent, the bag faint through it, and the cover rises only behind the words.",
    "The best's moment scales with its rarity: a Common best gets only its size-up; an Uncommon its rim and the stripe "
    "in its colour (the one chest, below); Rare and up the full burst: focus lines in its colour inside the band, a "
    "white rim in its glow, its rarity's word on a slanted tag (above).",
    f"For Faber's block, in points: the band {BAND_H:g} high, centred at {MID:g} of 375, {BAND['ink']} at "
    f"{BAND['cover']:g} cover, its diagonal lines {BAND['lines']} every {BAND['line_pitch']:g}, thinning behind the "
    f"row. The stripe {STRIPE['h']:g} high, {STRIPE['inset']:g} in from each side, its ends leaning {STRIPE['lean']:g}; "
    f"the foot line {FOOT['h']:g} in {FOOT['colour']}. The tag {TAG['ink']} at {TAG['cover']:g}, its sides leaning "
    f"{TAG['lean']:g}, its left side a {TAG['accent']:g} line in the stripe's colour. The title {TITLE:g}, slanted; the "
    f"haul {HAUL_SIZE:g}. Tiles {S:g} with {GAP:g} between, the best {BEST_S:g} after {BEST_GAP:g}. OK a white plate "
    f"{OK['w']:g} by {OK['h']:g}, leaning {OK['lean']:g}. The burst: {BURST['lines']} lines reaching "
    f"{BURST['reach'][0]:g} to {BURST['reach'][1]:g} from the best's middle, at {BURST['cover']:g}, cut at the band.",
    "Stand-ins: the text is Blender's face; the haul's numbers and the forge stones' colour are seeds. Behind is Faber's "
    "phone capture of our own bag (TR24), dimmed: the slate bag, before the lacquer rebuild. Two rows and '+N more' and "
    "the Epic-or-better reveal are TR34's, in the block.",
)
M, HEAD = 20.0, 46.0


def screen_image(content):
    sheet = ui.Sheet(W, H, "#000000")
    draw(inv.Screen(sheet, 0, 0), content)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def main():
    out = bl.out_dir()
    screens = (("Settled: 37 Shade Chests of Lantern Row, the best a Rare (the full burst)", screen_image(MANY)),
               ("One chest: the best an Uncommon (its rim and the stripe)", screen_image(ONE)))
    lines = [line for n in NOTES for line in textwrap.wrap(n, 140)]
    h = HEAD + 2 * (18 + H + 14) + len(lines) * 16 + 16
    sheet = ui.Sheet(W + 2 * M, h, "#16161A")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(M, 14, 18, "Grow your Anime, the chest opening: B, the banner (research's pick, fixed)", "#ECE8F2",
           bold=0.2 * K)
    y = HEAD
    for caption, px in screens:
        t.text(M, y, 13, caption, "#9C98A8")
        rs.paste(sheet.px, px, round(M * K), round((y + 18) * K))
        y += 18 + H + 14
    for i, line in enumerate(lines):
        t.text(M, y + i * 16, 12, line, "#9C98A8")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "chest_band_B_fixed.png")
    phone = [rs.shrink(px, 1 / K) for _, px in screens]  # the phone's own size, a pixel a point, side by side
    strip = rs.canvas(2 * round(W) + 16, round(H), (0.13, 0.13, 0.16))
    for i, px in enumerate(phone):
        rs.paste(strip, px, i * (round(W) + 16), 0)
    rs.save(strip, out / "chest_band_B_fixed_phone.png")


if __name__ == "__main__":
    main()
