"""The chest opening's band: A, the seam, the director's pick (AR24, 2026-11-17, 02:40: "i like A \"the seam more"), as
it stands. TR34 in docs/test-requests.md holds the feel line and the beats; the director's form (2026-11-17, 02:20) is a
translucent black band across the whole screen, a title on top, the items centred, OK below. The three directions it
was picked from are 02ee5aa's chest_band_directions.py.

The band opens as one hairline of pale light across the screen that parts into its two edges; inside, violet-black.
The best's moment scales with its rarity (AR24, taken by research and kept by the director's pick): a Common best gets
only its size-up; an Uncommon its colour on its rim and running out along both edges; Rare and up the full moment, the
edges' run, an upright shaft of its light behind it cut hard at the band, and its glow. If the moment doesn't hit in
the block, the levers are the run's speed and the light's brightness, never a new shape (research, AR24).

A mockup at a phone's size in landscape (812 x 375 points, 2 pixels a point), over Faber's phone capture of our own bag
(TR24), dimmed; Blender's face stands in for the game's. Drawn in four screens: the tap, the sting, settled (37 Shade
Chests of Lantern Row, the best a Rare) and one chest (an Uncommon), with the numbers for Faber's block. The content
check's conditions (2026-11-17): one line for the rest of the haul, no reel or casino words, nothing to buy, the best's
light in hard lines with nothing pooling under a tile, the sheets in scratch only.

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
from inventory_directions import H, K, RARITY, W, rrect, vramp  # noqa: E402
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
SEAM = dict(light="#EDE4FF", inside=("#1A1430", "#08070E"), cover=0.92, well=("#1B1728", "#0C0A13"), text="#F1ECFF")
EDGE = dict(width=1.0, glow=4.0, glow_cover=0.42, floor=0.2, spread=340.0, hot=1.6)  # the edges' light, its profile
RUN = dict(reach=(90.0, 390.0))     # the best's colour along the edges: from its middle, at the sting, then settled
SHAFT = dict(width=(42.0, 30.0), cover=(0.62, 0.36))  # the upright shaft behind the best: at the sting, then settled
TITLE, HAUL_SIZE, TITLE_Y, HAUL_Y, ROW_Y = 15.0, 11.0, 15.0, 37.0, 58.0  # sizes, and their tops in the band
S, GAP, BEST_S, BEST_GAP = 48.0, 6.0, 64.0, 16.0  # a tile, between tiles, the best a size up, before it
TILE = dict(corner=3.0, cover=0.96, rise=0.38, rim=(1.0, 0.7), best_rim=(2.0, 0.95), best_glow=(9.0, 0.5))
OK = dict(w=112.0, h=24.0, rise=20.0, fill="#0B0913", cover=0.7, edge=0.85)  # its middle `rise` over the band's foot
LEVEL = {"Common": 0, "Uncommon": 1}  # Rare and up: 2, the full moment

SETTLED = dict(open=1.0, best=1.0)
BEATS = (("The tap: one hairline of pale light parts into the band's two edges (before the server answers)",
          dict(open=0.4, best=0.0), MANY),
         ("The sting: the best lands last, a size up; its colour runs out along the edges, its shaft flares (the band "
          "held 80 ms)", dict(open=1.0, best=0.5), MANY),
         ("Settled: 37 Shade Chests of Lantern Row, the best a Rare (the full moment)", SETTLED, MANY),
         ("One chest: the best an Uncommon (its rim and the edges' run, no shaft)", SETTLED, ONE))


def rarity(stem):
    return inv.GEAR[stem]["rarity"]


def level(stem):
    return LEVEL.get(rarity(stem), 2)


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def gauss(x, mu, sigma):
    return np.exp(-((x - mu) / sigma) ** 2)


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


def title_group(scr, content, y):
    """The chest's picture and the title beside it, centred."""
    pic, tw = 24.0, inv.width(content["title"], TITLE) * 0.86
    x0 = (W - (pic + 7 + tw)) / 2
    scr.paste(inv.picture(CHEST, pic), x0, y + TITLE * ui.CAP / 2 - pic / 2)
    scr.sheet.items.append(dict(x=scr.ox + x0 + pic + 7, y=scr.oy + y, size=TITLE, text=content["title"],
                                colour=SEAM["text"], align="LEFT", layer="plain", shear=0.0, bold=0.25 * K))


def haul_line(scr, content, y):
    """The rest of the haul: one line, centred, each in its own colour (the content check's condition 1)."""
    parts = [(f"{n} {what}", col) for n, what, col in content["haul"]]
    x = (W - (sum(inv.width(s, HAUL_SIZE) * 0.86 + 22 for s, _ in parts) - 22)) / 2
    for s, col in parts:
        scr.text(x, y, HAUL_SIZE, s, col)
        x += inv.width(s, HAUL_SIZE) * 0.86 + 22


def count_mark(scr, x, y, s, n):
    if n > 1:
        t = scr.area(x + s - 24, y + s - 15, x + s, y + s)
        t.paint(rrect(t, x + s - 23, y + s - 14, x + s - 2, y + s - 2, 2.5), c("#000000"), 0.62)
        scr.text(x + s - 4, y + s - 11, 9, f"×{n}", "#FFFFFF", "RIGHT", bold=0.2)


def tile(scr, x, y, s, stem, n, best=False):
    """A tile: its well, its rarity's light rising from its foot, its rim. The best's rim and glow by its level."""
    col, lv = RARITY[rarity(stem)], level(stem)
    t = scr.area(x, y, x + s, y + s, 14)
    d = rrect(t, x, y, x + s, y + s, TILE["corner"])
    if best and lv == 2:
        t.glow(d, TILE["best_glow"][0], c(col), TILE["best_glow"][1])
    t.paint(d, vramp(t, SEAM["well"][0], SEAM["well"][1], y, y + s), TILE["cover"])
    rise = np.exp(-(np.hypot((t.X - x - s / 2) * 0.8, t.Y - y - s) / (s * 0.42)) ** 2) * (d < 0)
    t.paint(d, c(col), TILE["rise"] * rise)
    width, cover = TILE["best_rim"] if best and lv else TILE["rim"]
    t.line(d, width, c(col), cover)
    inv.item_art(scr, stem, x + 2, y + 2, s - 4)
    count_mark(scr, x, y, s, n)


def draw(scr, content, beat):
    inv_dim = 0.5
    scr.paste(rs.load(BACKDROP), 0, 0)
    t = scr.area(0, 0, W, H)
    t.paint(t.X * 0 - 1, c("#000000"), inv_dim)
    y0, y1, cells, best = layout(content)
    mid, o = (y0 + y1) / 2, smooth(beat["open"])
    top, foot = mid - (y1 - y0) / 2 * o, mid + (y1 - y0) / 2 * o
    bx, by = best[0] + best[2] / 2, best[1] + best[2] / 2
    best_col, lv = RARITY[rarity(best[3])], level(best[3])
    sting = 0.0 < beat["best"] < 1.0
    t = scr.area(0, top - 20, W, foot + 20)
    inside = np.maximum(top - t.Y, t.Y - foot)
    if foot - top > 0.5:
        t.paint(inside, t.ramp(SEAM["inside"][0], SEAM["inside"][1], np.abs(t.Y - mid) / ((foot - top) / 2)), SEAM["cover"])
    if beat["best"] and lv == 2:  # the shaft: upright, cut hard at the edges (no pooling, condition 4)
        k = 0 if sting else 1
        t.paint(inside, c(best_col), SHAFT["cover"][k] * gauss(t.X, bx, SHAFT["width"][k]))
    run = beat["best"] if lv else 0.0
    reach = RUN["reach"][0] + (RUN["reach"][1] - RUN["reach"][0]) * min(run * 2, 1.0)
    weight = (gauss(t.X, bx, reach) if run else t.X * 0)[..., None]
    colour = c(SEAM["light"]) * (1 - weight) + c(best_col) * weight
    prof = EDGE["floor"] + (1 - EDGE["floor"]) * gauss(t.X, W / 2, EDGE["spread"])
    if run:
        prof = np.maximum(prof, gauss(t.X, bx, reach))
    hot = 1.0 + EDGE["hot"] * (1 - o)  # the seam is brightest as it opens
    edge = np.minimum(np.abs(t.Y - top), np.abs(t.Y - foot)) - EDGE["width"] * 0.6
    t.glow(edge, EDGE["glow"] * hot, colour, np.clip(EDGE["glow_cover"] * prof * hot, 0, 1))
    t.paint(edge, colour, np.clip(prof * hot, 0, 1))
    if not beat["open"] >= 1:
        return
    title_group(scr, content, y0 + TITLE_Y)
    haul_line(scr, content, y0 + HAUL_Y)
    for x, y, s, stem, n in cells:
        tile(scr, x, y, s, stem, n)
    if beat["best"]:
        tile(scr, *best, best=True)
        if sting and lv:
            t = scr.area(bx - 80, by - 80, bx + 80, by + 80)
            t.glow(np.hypot(t.X - bx, t.Y - by) - best[2] * 0.3, 16.0, c("#FFFFFF"), 0.55)
    if beat["best"] >= 1:
        t = scr.area(W / 2 - OK["w"] / 2 - 4, y1 - OK["rise"] - OK["h"] / 2 - 4, W / 2 + OK["w"] / 2 + 4,
                     y1 - OK["rise"] + OK["h"] / 2 + 4)
        d = rrect(t, W / 2 - OK["w"] / 2, y1 - OK["rise"] - OK["h"] / 2, W / 2 + OK["w"] / 2, y1 - OK["rise"] + OK["h"] / 2,
                  OK["h"] / 2)
        t.paint(d, c(OK["fill"]), OK["cover"])
        t.line(d, 1.0, c(SEAM["light"]), OK["edge"])
        scr.mid(W / 2, y1 - OK["rise"], 12, "OK", SEAM["text"], "CENTER", bold=0.25)


# --- the sheet --------------------------------------------------------------------------------------------------------

NOTES = (
    "The director's pick, as it stands: the band opens as one hairline of pale light across the screen that parts into "
    "its two edges; inside, violet-black. The best lands last, a size up, and its moment scales with its rarity: a "
    "Common gets only its size-up; an Uncommon its colour on its rim and running out along both edges; Rare and up the "
    "edges' run, an upright shaft of its light cut hard at the band, and its glow. If it doesn't hit in motion, the "
    "levers are the run's speed and the light's brightness, never a new shape.",
    f"For Faber's block, in points: the band {BAND_H:g} high, centred at {MID:g} of 375. Inside, a ramp from "
    f"{SEAM['inside'][0]} at the middle to {SEAM['inside'][1]} at the edges, at {SEAM['cover']:g} cover. The edges "
    f"{EDGE['width']:g} in {SEAM['light']}, strongest at the screen's middle (falling to {EDGE['floor']:g} at the ends "
    f"over {EDGE['spread']:g}), a {EDGE['glow']:g} glow at {EDGE['glow_cover']:g}; while the seam opens they burn up to "
    f"{1 + EDGE['hot']:g} times as bright. The run: the best's colour along the edges from its middle, {RUN['reach'][0]:g} "
    f"out at the sting to {RUN['reach'][1]:g} settled. The shaft: {SHAFT['width'][0]:g} wide at {SHAFT['cover'][0]:g} "
    f"at the sting, {SHAFT['width'][1]:g} at {SHAFT['cover'][1]:g} settled. The title {TITLE:g} with the chest's "
    f"picture at 24, {TITLE_Y:g} under the band's top; the haul {HAUL_SIZE:g} at {HAUL_Y:g}. Tiles {S:g} with {GAP:g} "
    f"between, from {ROW_Y:g} under the top, the best {BEST_S:g} after {BEST_GAP:g}. A tile: corners "
    f"{TILE['corner']:g}, its well {SEAM['well'][0]} to {SEAM['well'][1]}, its rarity's light rising from its foot at "
    f"{TILE['rise']:g}, its rim {TILE['rim'][0]:g} at {TILE['rim'][1]:g}; the best's {TILE['best_rim'][0]:g} at "
    f"{TILE['best_rim'][1]:g}, its glow {TILE['best_glow'][0]:g} at {TILE['best_glow'][1]:g}. OK a pill {OK['w']:g} by "
    f"{OK['h']:g}, {OK['fill']} at {OK['cover']:g}, edged in the light, its middle {OK['rise']:g} over the band's foot.",
    "Stand-ins: the text is Blender's face; the haul's numbers and the forge stones' colour are seeds. Behind is Faber's "
    "phone capture of our own bag (TR24), dimmed. Two rows and '+N more' and the Epic-or-better reveal are TR34's, in the "
    "block.",
)
M, HEAD = 20.0, 46.0


def screen_image(content, beat):
    sheet = ui.Sheet(W, H, "#000000")
    draw(inv.Screen(sheet, 0, 0), content, beat)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px


def main():
    out = bl.out_dir()
    screens = [(caption, screen_image(content, beat)) for caption, beat, content in BEATS]
    lines = [line for n in NOTES for line in textwrap.wrap(n, 140)]
    h = HEAD + len(screens) * (18 + H + 14) + len(lines) * 16 + 16
    sheet = ui.Sheet(W + 2 * M, h, "#16161A")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(M, 14, 18, "Grow your Anime, the chest opening: A, the seam (the director's pick)", "#ECE8F2", bold=0.2 * K)
    y = HEAD
    for caption, px in screens:
        t.text(M, y, 13, caption, "#9C98A8")
        rs.paste(sheet.px, px, round(M * K), round((y + 18) * K))
        y += 18 + H + 14
    for i, line in enumerate(lines):
        t.text(M, y + i * 16, 12, line, "#9C98A8")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "chest_band_A_seam.png")
    phone = [rs.shrink(px, 1 / K) for _, px in screens[2:]]  # settled and one chest at the phone's own size, a pixel a point
    strip = rs.canvas(2 * round(W) + 16, round(H), (0.13, 0.13, 0.16))
    for i, px in enumerate(phone):
        rs.paste(strip, px, i * (round(W) + 16), 0)
    rs.save(strip, out / "chest_band_A_seam_phone.png")


if __name__ == "__main__":
    main()
