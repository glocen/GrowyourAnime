"""The chest opening's look, in three directions, before anything is finished (AR24; TR34 in docs/test-requests.md
holds the feel line and the beats). The director's form (2026-11-17, 02:20): a translucent black band across the whole
screen, a title on top, the items centred, OK below. Mockups, not finished art, at a phone's size in landscape (812 x
375 points, 2 pixels a point), over Faber's phone capture of our own bag (TR24), dimmed:

  A, the seam: the void's own. The band opens as one hairline of pale light across the screen that parts into its two
     edges; inside, violet-black. The best's colour runs out along both edges from it, and an upright shaft of its
     light stands behind it, cut at the edges.
  B, the banner: anime poster energy. The band tilts up to the right, black with fine diagonal lines, a bold stripe
     along its top. The best: straight focus lines in its colour inside the band, its rarity's word on a slanted tag.
  C, the tray: the bag's lacquer (AR18's A). Warm black, brass rules along both edges, the chest's picture in a brass
     ring hung over the top edge. The best stands on a brass bar in a halo of its light; OK hangs from the bottom rule.

Each is drawn settled (37 Shade Chests of Lantern Row, the best a Rare) and in three beats: the tap (the band opening
before the server answers), the pour (from Common up, one tile popping in), and the best landing (the sting); and a
single chest. The content check's conditions (2026-11-17): one line for the rest of the haul, no reel or casino words,
nothing to buy, the best's light in hard lines with nothing pooling under a tile. Text is Blender's face standing in.

    blender -b --factory-startup --python tools/blender/chest_band_directions.py -- build/scratch/modulo/ar24
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
from inventory_directions import H, K, RARITY, W, mix, poly, rrect, vramp  # noqa: E402
from ui_sheet import c  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
BACKDROP = REPO / "build" / "scratch" / "modulo" / "ar24" / "bag_backdrop.png"  # Faber's TR24 capture, 1624 x 750
CHEST = REPO / "build" / "handoff" / "UI" / "chests" / "images" / "ChestShade.png"
CREDITS, STONES = "#40DCC6", "#B9C6D8"  # Config.UIKit's Credits; the forge stones' stand-in

# The haul of 37, sorted from Common up, identical items merged; the best last.
HAUL = (("GearIronSword", 7), ("GearScrapRing", 5), ("GearBronzeHelmet", 5), ("GearIronShoulders", 4),
        ("GearBronzeShortSword", 3), ("GearRowsmithSword", 4), ("GearLanternsteelRing", 4), ("GearStallguardHelmet", 2),
        ("GearRowsmithShoulders", 1), ("GearBandOfGales", 1))
BEST = "GearBladeOfEmbers"
MANY = dict(title="37 Shade Chests of Lantern Row", haul=(("+1,284", "Credits", CREDITS), ("+46", "forge stones", STONES)),
            tiles=HAUL, best=BEST)
ONE = dict(title="A Shade Chest of Lantern Row", haul=(("+36", "Credits", CREDITS),), tiles=(), best="GearLanternsteelRing")

S, GAP, BEST_S, BEST_GAP = 48.0, 6.0, 64.0, 16.0  # a tile, between tiles, the best a size up, before it
BAND_H, MID = 150.0, 205.0  # the band's height and its middle: centred in what Roblox's top bar leaves
SETTLED = dict(open=1.0, shown=99, pop=0.0, best=1.0, title=True)
BEATS = (("The tap: the band opens before the server answers (anticipation)", dict(open=0.4, shown=0, pop=0.0, best=0.0, title=False)),
         ("The pour, from Common up: the sixth tile popping in", dict(open=1.0, shown=6, pop=0.6, best=0.0, title=True)),
         ("The best lands last, a size up: the sting (the band held 80 ms)", dict(open=1.0, shown=99, pop=0.0, best=0.5, title=True)))


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def gauss(x, mu, sigma):
    return np.exp(-((x - mu) / sigma) ** 2)


# --- the layout, shared by the three, so they compare as looks --------------------------------------------------------

def layout(content):
    """Where every tile and the best stand: one row, centred; the best last and a size up."""
    n = len(content["tiles"])
    total = n * S + max(n - 1, 0) * GAP + (BEST_GAP if n else 0) + BEST_S
    x = (W - total) / 2
    y0 = MID - BAND_H / 2
    row = y0 + 58.0
    cells = []
    for stem, count in content["tiles"]:
        cells.append((x, row, S, stem, count))
        x += S + GAP
    x += BEST_GAP - GAP if n else 0
    best = (x, row + S / 2 - BEST_S / 2, BEST_S, content["best"], 1)
    return y0, y0 + BAND_H, cells, best


def rarity(stem):
    return inv.GEAR[stem]["rarity"]


def backdrop(scr, dim):
    scr.paste(rs.load(BACKDROP), 0, 0)
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, c("#000000"), dim)


def count_mark(scr, x, y, s, n):
    if n > 1:
        t = scr.area(x + s - 24, y + s - 15, x + s, y + s)
        t.paint(rrect(t, x + s - 23, y + s - 14, x + s - 2, y + s - 2, 2.5), c("#000000"), 0.62)
        scr.text(x + s - 4, y + s - 11, 9, f"×{n}", "#FFFFFF", "RIGHT", bold=0.2)


def pop_of(i, beat):
    """A tile's state in a beat: hidden, popping (its scale and flash) or in."""
    if i >= beat["shown"]:
        return None
    return beat["pop"] if i == beat["shown"] - 1 else 0.0


def title_group(scr, content, y, size, colour, align="CENTER", x=None, shear=0.0, pic=24.0):
    """The chest's picture and the title beside it."""
    tw = inv.width(content["title"], size) * 0.86
    x0 = (W - (pic + 7 + tw)) / 2 if align == "CENTER" else x
    if pic:
        scr.paste(inv.picture(CHEST, pic), x0, y + size * ui.CAP / 2 - pic / 2)
    t_x = x0 + (pic + 7 if pic else 0)
    scr.sheet.items.append(dict(x=scr.ox + t_x, y=scr.oy + y, size=size, text=content["title"], colour=colour,
                                align="LEFT", layer="plain", shear=shear, bold=0.25 * K))


def haul_width(content, size):
    return sum(inv.width(f"{n} {what}", size) * 0.86 + 22 for n, what, _ in content["haul"]) - 22


def haul_line(scr, content, y, size, align="CENTER", x=None):
    """The rest of the haul: one line, each in its own colour (the content check's condition 1)."""
    parts = [(f"{n} {what}", col) for n, what, col in content["haul"]]
    widths = [inv.width(s, size) * 0.86 for s, _ in parts]
    total = haul_width(content, size)
    x0 = (W - total) / 2 if align == "CENTER" else (x - total if align == "RIGHT" else x)
    for (s, col), w in zip(parts, widths):
        scr.text(x0, y, size, s, col)
        x0 += w + 22


# --- A, the seam ------------------------------------------------------------------------------------------------------

SEAM = dict(light="#EDE4FF", inside=("#1A1430", "#08070E"), well=("#1B1728", "#0C0A13"), text="#F1ECFF", soft="#B9B0D6")


def a_tile(scr, x, y, s, stem, n, pop=0.0, best=False):
    p, col = SEAM, RARITY[rarity(stem)]
    if pop:
        k = 0.82 + 0.18 * pop
        x, y, s = x + s * (1 - k) / 2, y + s * (1 - k) / 2, s * k
    t = scr.area(x, y, x + s, y + s, 14)
    d = rrect(t, x, y, x + s, y + s, 3.0)
    if best:
        t.glow(d, 9.0, c(col), 0.5)
    t.paint(d, vramp(t, p["well"][0], p["well"][1], y, y + s), 0.96)
    rise = np.exp(-(np.hypot((t.X - x - s / 2) * 0.8, t.Y - y - s) / (s * 0.42)) ** 2) * (d < 0)
    t.paint(d, c(col), 0.38 * rise)
    t.line(d, 2.0 if best else 1.0, c(col), 0.95 if best else 0.7)
    inv.item_art(scr, stem, x + 2, y + 2, s - 4)
    if pop:
        t = scr.area(x, y, x + s, y + s, 4)
        t.paint(rrect(t, x, y, x + s, y + s, 3.0), c("#FFFFFF"), 0.55 * (1 - pop) + 0.15)
    count_mark(scr, x, y, s, n)


def draw_a(scr, content, beat):
    p = SEAM
    backdrop(scr, 0.5)
    y0, y1, cells, best = layout(content)
    mid, o = (y0 + y1) / 2, smooth(beat["open"])
    top, foot = mid - (y1 - y0) / 2 * o, mid + (y1 - y0) / 2 * o
    bx, by = best[0] + best[2] / 2, best[1] + best[2] / 2
    best_col = RARITY[rarity(best[3])]
    t = scr.area(0, top - 20, W, foot + 20)
    inside = np.maximum(top - t.Y, t.Y - foot)
    if foot - top > 0.5:
        t.paint(inside, t.ramp(p["inside"][0], p["inside"][1], np.abs(t.Y - mid) / ((foot - top) / 2)), 0.92)
    if beat["best"]:  # the shaft: upright, cut hard at the edges (no pooling, condition 4)
        k = 0.62 if beat["best"] < 1 else 0.36
        t.paint(inside, c(best_col), k * gauss(t.X, bx, 30.0 + 12 * beat["best"]))
    run = beat["best"]
    reach = 90.0 + 300.0 * min(run * 2, 1.0)
    weight = (gauss(t.X, bx, reach) if run else t.X * 0)[..., None]
    colour = c(p["light"]) * (1 - weight) + c(best_col) * weight
    prof = 0.2 + 0.8 * gauss(t.X, W / 2, 340.0)
    if run:
        prof = np.maximum(prof, gauss(t.X, bx, reach))
    hot = 1.0 + 1.6 * (1 - o)  # the seam is brightest as it opens
    edge = np.minimum(np.abs(t.Y - top), np.abs(t.Y - foot)) - 0.6
    t.glow(edge, 4.0 * hot, colour, np.clip(0.42 * prof * hot, 0, 1))
    t.paint(edge, colour, np.clip(prof * hot, 0, 1))
    if beat["title"]:
        title_group(scr, content, y0 + 15, 15, p["text"])
        haul_line(scr, content, y0 + 37, 11)
    for i, (x, y, s, stem, n) in enumerate(cells):
        pop = pop_of(i, beat)
        if pop is not None:
            a_tile(scr, x, y, s, stem, n, pop)
    if beat["best"]:
        flash = beat["best"] < 1
        a_tile(scr, *best, pop=0.0, best=True)
        if flash:
            t = scr.area(bx - 80, by - 80, bx + 80, by + 80)
            t.glow(np.hypot(t.X - bx, t.Y - by) - best[2] * 0.3, 16.0, c("#FFFFFF"), 0.55)
    if beat["title"] and (beat["best"] >= 1 or not content["tiles"]):
        t = scr.area(W / 2 - 60, y1 - 34, W / 2 + 60, y1 - 6)
        d = rrect(t, W / 2 - 56, y1 - 32, W / 2 + 56, y1 - 8, 12.0)
        t.paint(d, c("#0B0913"), 0.7)
        t.line(d, 1.0, c(p["light"]), 0.85)
        scr.mid(W / 2, y1 - 20, 12, "OK", p["text"], "CENTER", bold=0.25)


# --- B, the banner ----------------------------------------------------------------------------------------------------

BANNER = dict(ink="#08080B", lines="#1B1B24", stripe="#F5F3F8", foot="#585866", well=("#15151C", "#0B0B10"),
              text="#FFFFFF", soft="#A9A9B8")
TILT = -0.05  # the band rises to the right: 40 points over the screen


def b_tile(scr, x, y, s, stem, n, pop=0.0, best=False):
    p, col = BANNER, RARITY[rarity(stem)]
    if pop:
        x = x - 14 * (1 - pop)  # it slides in along the row
    t = scr.area(x, y, x + s, y + s, 14)
    cut = 7.0 if best else 5.0
    d = poly(t, ui.cut_box(x, y, x + s, y + s, tl=cut, br=cut))
    if best:
        t.glow(d, 6.0, c(col), 0.45)
    t.paint(d, vramp(t, p["well"][0], p["well"][1], y, y + s), 0.97)
    t.paint(np.maximum(d, poly(t, [(x, y + s - 14), (x + 14, y + s), (x, y + s)])), c(col), 0.95)  # the corner's flag
    t.line(d, 2.0 if best else 1.0, c("#FFFFFF" if best else col), 0.95 if best else 0.75)
    inv.item_art(scr, stem, x + 2, y + 2, s - 4)
    if pop:
        t = scr.area(x, y, x + s, y + s, 2)
        t.paint(poly(t, ui.cut_box(x, y, x + s, y + s, tl=cut, br=cut)), c("#FFFFFF"), 0.5 * (1 - pop) + 0.1)
    count_mark(scr, x, y, s, n)


def draw_b(scr, content, beat):
    p = BANNER
    backdrop(scr, 0.45)
    y0, y1, cells, best = layout(content)
    mid = (y0 + y1) / 2
    bx, by = best[0] + best[2] / 2, best[1] + best[2] / 2
    best_col = RARITY[rarity(best[3])]
    t = scr.area(0, 0, W, H)
    lift = TILT * (t.X - W / 2)
    top, foot = y0 - 6 + lift, y1 + 6 + lift
    inside = np.maximum(top - t.Y, t.Y - foot)
    o = smooth(beat["open"])
    wipe = (t.X + (t.Y - mid) * 0.55) - o * (W + 160)  # the band runs in from the left, its front on the slant
    inside = np.maximum(inside, wipe)
    t.paint(inside, c(p["ink"]), 0.88)
    streaks = ((t.X + t.Y * 0.62) / 6.0) % 1.0
    away = 1 - 0.75 * gauss(t.X, W / 2, 230.0)
    t.paint(np.maximum(inside, (np.abs(streaks - 0.5) - 0.06) * 6.0), c(p["lines"]), 0.9 * away)
    stripe_col = mix(p["stripe"], best_col, 1.0) if beat["best"] else p["stripe"]
    t.paint(np.maximum(np.abs(t.Y - (top - 2.0)) - 2.0, wipe), c(stripe_col))
    t.paint(np.maximum(np.abs(t.Y - foot) - 0.5, wipe), c(p["foot"]))
    if beat["best"]:  # focus lines: straight and sharp (condition 4), inside the band
        ang = np.arctan2(t.Y - by, t.X - bx)
        r = np.hypot(t.X - bx, t.Y - by)
        slot = ang / (2 * np.pi) * 46.0
        idx = np.floor(slot)
        reach = 70.0 + 150.0 * ((idx * 0.618) % 1.0)
        width = np.abs((slot - idx) - 0.5) * (2 * np.pi / 46.0) * r - (0.6 + r * 0.012)
        k = 0.95 if beat["best"] < 1 else 0.7
        a = k * np.clip((reach - r) / 40.0, 0, 1) * (r > best[2] * 0.62)
        t.paint(np.maximum(width, inside), c(best_col), a)
    if beat["title"]:  # the title and the haul on a black tag hung from the stripe, over the focus lines
        tw, hw = inv.width(content["title"], 17) * 0.86 + 31, haul_width(content, 11) + 31
        x_left = cells[0][0] if cells else (W - max(tw, hw)) / 2
        xa, xb = x_left - 10, x_left + max(tw, hw) + 14
        ty = y0 + 6 + TILT * (x_left - W / 2)
        foot_y = ty + 19 + 11 * ui.CAP + 6
        t = scr.area(xa - 12, ty - 30, xb + 20, foot_y + 2)
        top_at = lambda x: y0 - 6 + TILT * (x - W / 2)  # noqa: E731
        tag = poly(t, [(xa + 6, top_at(xa + 6)), (xb + 14, top_at(xb + 14)), (xb + 6, foot_y), (xa - 2, foot_y)])
        t.paint(tag, c("#040406"), 0.94)
        t.paint(inv.seg(t, (xa + 6, top_at(xa + 6)), (xa - 2, foot_y)) - 1.5, c(stripe_col))
        title_group(scr, content, ty, 17, p["text"], align="LEFT", x=x_left, shear=0.18)
        haul_line(scr, content, ty + 19, 11, align="LEFT", x=x_left + 31)
    for i, (x, y, s, stem, n) in enumerate(cells):
        pop = pop_of(i, beat)
        if pop is not None:
            b_tile(scr, x, y, s, stem, n, pop)
    if beat["best"]:
        b_tile(scr, *best, pop=0.0, best=True)
        word = rarity(best[3]).upper()
        tw = inv.width(word, 9) * 0.9 + 14
        tx, ty = bx - tw / 2, best[1] + best[2] - 4
        t = scr.area(tx - 6, ty, tx + tw + 6, ty + 14)
        t.paint(poly(t, [(tx + 4, ty), (tx + tw + 4, ty), (tx + tw - 4, ty + 13), (tx - 4, ty + 13)]), c(best_col))
        scr.mid(bx, ty + 6.5, 9, word, "#101015", "CENTER", bold=0.3)
        if beat["best"] < 1:
            t = scr.area(bx - 80, by - 80, bx + 80, by + 80)
            t.glow(np.hypot(t.X - bx, t.Y - by) - best[2] * 0.3, 14.0, c("#FFFFFF"), 0.6)
    if beat["title"] and (beat["best"] >= 1 or not content["tiles"]):
        cx, cy = W / 2, y1 - 11
        t = scr.area(cx - 70, cy - 15, cx + 70, cy + 15)
        t.paint(poly(t, [(cx - 50, cy - 11), (cx + 58, cy - 11), (cx + 50, cy + 11), (cx - 58, cy + 11)]), c("#FFFFFF"))
        scr.mid(cx, cy, 13, "OK", "#0B0B0F", "CENTER", bold=0.35)


# --- C, the tray ------------------------------------------------------------------------------------------------------

TRAY = inv.LACQUER


def c_tile(scr, x, y, s, stem, n, pop=0.0, best=False):
    if pop:
        y = y + 8 * (1 - pop)  # it settles down onto the row
    if best:
        col = RARITY[rarity(stem)]
        t = scr.area(x, y, x + s, y + s, 14)
        t.glow(rrect(t, x, y, x + s, y + s, 2.0), 8.0, c(mix(col, TRAY["brass"], 0.3)), 0.5)
    inv.a_cell(scr, TRAY, x, y, s, stem, inv.ROOK)
    if best:
        t = scr.area(x, y, x + s, y + s, 4)
        t.line(rrect(t, x, y, x + s, y + s, 2.0), 1.6, c(RARITY[rarity(stem)]))
    if pop:
        t = scr.area(x, y, x + s, y + s, 2)
        t.paint(rrect(t, x, y, x + s, y + s, 2.0), c(TRAY["text"]), 0.45 * (1 - pop) + 0.1)
    count_mark(scr, x, y, s, n)


def draw_c(scr, content, beat):
    p = TRAY
    backdrop(scr, 0.5)
    y0, y1, cells, best = layout(content)
    mid, o = (y0 + y1) / 2, smooth(beat["open"])
    top, foot = mid - (y1 - y0) / 2 * o, mid + (y1 - y0) / 2 * o
    bx, by = best[0] + best[2] / 2, best[1] + best[2] / 2
    best_col = RARITY[rarity(best[3])]
    t = scr.area(0, top - 24, W, foot + 24)
    inside = np.maximum(top - t.Y, t.Y - foot)
    if foot - top > 0.5:
        t.paint(inside, vramp(t, "#211B16", "#0B0907", top, foot), 0.94)
        t.paint(np.maximum(inside, np.abs(t.Y - (top + 7)) - 3.0), c("#FFFFFF"), 0.035)  # the lacquer's sheen
    prof = 0.25 + 0.75 * gauss(t.X, W / 2, 360.0)
    for yy, w, a in ((top, 1.0, 1.0), (foot, 1.0, 1.0), (top + 4, 0.5, 0.45), (foot - 4, 0.5, 0.45)):
        if foot - top > 9 or a == 1.0:
            t.paint(np.abs(t.Y - yy) - w / 2, c(p["brass"]), a * prof)
    if beat["best"]:  # a halo behind the best, round, never a pool under it (condition 4)
        k = 0.75 if beat["best"] < 1 else 0.6
        t.paint(inside, c(mix(best_col, p["brass"], 0.2)), k * np.exp(-(np.hypot(t.X - bx, (t.Y - by) * 1.15) / 54.0) ** 2))
    if beat["title"] or o > 0.6:  # the chest in a brass ring, hung over the top rule
        r = 17.0
        t = scr.area(W / 2 - r - 6, top - r - 6, W / 2 + r + 6, top + r + 6)
        d = np.hypot(t.X - W / 2, t.Y - top) - r
        t.glow(d, 5.0, c("#000000"), 0.5)
        t.paint(d, vramp(t, "#2A221B", "#0E0B08", top - r, top + r))
        t.line(d, 1.3, c(p["brass"]))
        t.line(d + 3.0, 0.5, c(p["brass"]), 0.55)
        scr.paste(inv.picture(CHEST, 24), W / 2 - 12, top - 12)
    if beat["title"]:
        title_group(scr, content, y0 + 24, 14, p["text"], pic=0)
        haul_line(scr, content, y0 + 43, 11)
    for i, (x, y, s, stem, n) in enumerate(cells):
        pop = pop_of(i, beat)
        if pop is not None:
            c_tile(scr, x, y, s, stem, n, pop)
    if beat["best"]:
        c_tile(scr, *best, pop=0.0, best=True)
        t = scr.area(bx - 48, by + best[2] / 2 + 2, bx + 48, by + best[2] / 2 + 10)
        yb = by + best[2] / 2 + 5.5
        t.paint(np.abs(t.Y - yb) - 0.6 + 0 * t.X, c(p["brass"]), np.clip((40 - np.abs(t.X - bx)) / 4, 0, 1))
        for sx in (-1, 1):
            t.paint(np.abs(t.X - (bx + sx * 42)) + np.abs(t.Y - yb) - 3.0, c(p["brass"]))
        if beat["best"] < 1:
            t = scr.area(bx - 80, by - 80, bx + 80, by + 80)
            t.glow(np.hypot(t.X - bx, t.Y - by) - best[2] * 0.3, 15.0, c("#FFF6E4"), 0.55)
    if beat["title"] and (beat["best"] >= 1 or not content["tiles"]):
        inv.a_button(scr, p, W / 2 - 52, y1 - 13, 104, 26, "OK", True)


# --- the sheets -------------------------------------------------------------------------------------------------------

DIRECTIONS = (
    ("A", "the seam", draw_a, (
        "The void's own: the band opens as one hairline of pale light across the screen that parts into its two edges, "
        "the shard's crack of our reveal turned on its side. Inside, violet-black. Tiles come in out of the light.",
        "The best: its colour runs out along both edges from it, and an upright shaft of its light stands behind it, "
        "cut hard at the band. Calm until the sting, then the whole band is the best's colour.")),
    ("B", "the banner", draw_b, (
        "Anime poster energy: the band tilts up to the right and runs in from the left on its slant, black with fine "
        "diagonal lines that thin out behind the tiles, a bold stripe along its top. The title is big and slanted, the "
        "haul under it, both on a black tag hung from the stripe.",
        "The best: straight focus lines in its colour burst from behind it inside the band, the top stripe takes its "
        "colour, and its rarity's word sits on a slanted tag under it.")),
    ("C", "the tray", draw_c, (
        "The bag's lacquer (AR18's A, the director's pick for the bag): warm black, brass rules along both edges, the "
        "chest's own picture in a brass ring hung over the top rule. The tiles are the bag's cells, so what lands here "
        "looks as it will in the bag.",
        "The best stands on a short brass bar in a round halo of its light, rimmed in its colour. OK hangs from the "
        "bottom rule, under the thumb's reach of the middle.")),
)
STANDINS = ("Stand-ins: the text is Blender's face; the haul's numbers, the forge stones' colour and the band's place "
            "are seeds. Behind is Faber's phone capture of our own bag (TR24), dimmed. One row of tiles here; a big open "
            "takes two rows and '+N more', and an Epic or better first gets its own short reveal (TR34, beat 4): both "
            "wait for the picked direction. Motion is judged in the block, from a phone capture.")
M, HEAD = 20.0, 46.0
FRAME_W = (W - 12) / 2  # a beat's frame on the sheet, in points


def screen_image(draw, content, beat):
    """One screen, drawn on its own sheet with its text, at 2 pixels a point."""
    sheet = ui.Sheet(W, H, "#000000")
    scr = inv.Screen(sheet, 0, 0)
    draw(scr, content, beat)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def direction_sheet(out, key, title, draw, notes):
    hero = screen_image(draw, MANY, SETTLED)
    frames = [(caption, screen_image(draw, MANY, beat)) for caption, beat in BEATS]
    frames.append(("One chest: the band with its one tile, in its light", screen_image(draw, ONE, SETTLED)))
    lines = [line for n in notes + (STANDINS,) for line in textwrap.wrap(n, 140)]
    fh = FRAME_W * H / W
    h = HEAD + 18 + H + 16 + 2 * (fh + 34) + len(lines) * 16 + 20
    sheet = ui.Sheet(W + 2 * M, h, "#16161A")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(M, 14, 18, f"Grow your Anime, the chest opening: {key}, {title}", "#ECE8F2", bold=0.2 * K)
    t.text(M, HEAD, 13, "Settled: 37 Shade Chests of Lantern Row, the best a Rare (phone, landscape)", "#9C98A8")
    rs.paste(sheet.px, hero, round(M * K), round((HEAD + 18) * K))
    y = HEAD + 18 + H + 16
    for i, (caption, px) in enumerate(frames):
        x = M + (i % 2) * (FRAME_W + 12)
        yy = y + (i // 2) * (fh + 34)
        t.text(x, yy, 12, f"{i + 1}. {caption}", "#9C98A8")
        small = rs.shrink(px, FRAME_W / W)
        rs.paste(sheet.px, small, round(x * K), round((yy + 16) * K))
    y += 2 * (fh + 34) + 4
    for i, line in enumerate(lines):
        t.text(M, y + i * 16, 12, line, "#9C98A8")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / f"chest_band_{key}.png")
    return rs.shrink(hero, 1 / K)


def glance_sheet(out, heroes):
    """The three settled, at a phone's own size, a pixel a point, side by side."""
    gap = 16.0
    ui.K, kk = 1, K
    sheet = ui.Sheet(3 * W + 4 * gap, H + 60, "#202228")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    for i, ((key, title, *_), px) in enumerate(zip(DIRECTIONS, heroes)):
        x = gap + i * (W + gap)
        rs.paste(sheet.px, px, round(x), 40)
        t.text(x, 14, 16, f"{key}, {title}", "#E9E4D8")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    ui.K = kk
    rs.save(sheet.px, out / "chest_band_glance.png")


def main():
    out = bl.out_dir()
    only = sys.argv[sys.argv.index("--") + 2:] if len(sys.argv) > sys.argv.index("--") + 2 else None
    heroes = []
    for key, title, draw, notes in DIRECTIONS:
        if only and key not in only:
            continue
        heroes.append(direction_sheet(out, key, title, draw, notes))
        inv.IMAGES.clear()
    if not only:
        glance_sheet(out, heroes)


if __name__ == "__main__":
    main()
