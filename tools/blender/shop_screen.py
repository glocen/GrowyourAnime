"""AR38's screen in grey: the Void Shop's counter screen at the smallest phone, in its states, for research's read.
Throwaway: grey boxes and Blender's own face standing in for the kit's, nothing exported.

What it holds (docs/design.md, "The Strip", the Void Shop; AR38, "The block contains"): six lines (three common, two
uncommon, and a rare line in some stocks), the rare offer's place apart, each line's price, the count left to this
player, the countdown to the next stock, and the tables' chances. A full screen (Kit/Screen, Screen.Full): Back and the
title in the band Roblox's top bar leaves free, then the body.

Measured in rendered points at the smallest phone (Theme.Smallest, 568 x 320), with the kit's sizes at the scale's
floor of 0.85: Pad 8 and Gap 6 authored draw 7 and 5, a tap 44, and no text under 14. The band is Roblox's top bar,
58 tall; where Roblox's own buttons end is read live in game (GuiService.TopbarInset), drawn here at 104 as a stand-in.
Prices, the counts and the rare line's chance are stand-ins too, until tools/balance/seeds.json sets them.

    blender -b --factory-startup --python tools/blender/shop_screen.py -- <abs out>

Writes shop_screen.png. Eevee's not used: the text is set by ui_sheet's own pass.
"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

W, H = 568, 320          # the smallest phone, in points
BAND = 58                # Roblox's top bar
ROBLOX = 104             # stand-in: where Roblox's own buttons end
PAD, GAP, TAP = 7, 5, 44
SMALL, TITLE = 14, 17

G = dict(cover="#191B23", panel="#262935", line="#5D6275", strong="#A3A8BA", text="#E6E8EF", soft="#9EA3B4",
         lit="#F2F2F8", spent="#3A3D4C", bad="#FF8A78", button="#454A5E", off="#2E3140", roblox="#30323C")
WEIGHT = {"Common": 1.2, "Uncommon": 2.2, "Rare": 3.2, "Epic": 3.2}   # in grey, a rarity is its frame's weight

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)  # codes, painted


def box(t, x0, y0, x1, y1, fill, line=None, lw=1.0, cut=3.0):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.paint(d, fill)
    if line:
        t.line(d, lw, line)
    return d


def coin(t, cx, cy, colour):
    """Credits' stand-in mark: a ring with a bar."""
    d = np.hypot(t.x - cx, t.y - cy)
    t.paint(np.abs(d - 5.2) - 1.3, colour)
    t.paint(np.maximum(np.abs(t.x - cx) - 1.1, np.abs(t.y - cy) - 2.6), colour)


def buy(t, x0, y0, x1, y1, price=None, word=None, on=True):
    """Buy: the price on the button, Credits' mark before it; off, it's dimmed and its line says why."""
    box(t, x0, y0, x1, y1, G["button"] if on else G["off"], G["strong"] if on else G["line"], 1.0, 4.0)
    colour = G["text"] if on else G["soft"]
    cy = (y0 + y1) / 2
    if price:
        coin(t, x0 + 16, cy, colour)
        t.text((x0 + 26 + x1) / 2, cy - 5, SMALL, price, colour, align="CENTER", bold=0.15)
    else:
        t.text((x0 + x1) / 2, cy - 5, SMALL, word, colour, align="CENTER", bold=0.15)


def icon(t, kind, cx, cy, rarity, dim=False):
    """Grey stand-ins for the pictures (AR21's shards, AR31's stones and emblems): a shard, a stack, a badge."""
    box(t, cx - 18, cy - 18, cx + 18, cy + 18, G["off"], G["strong"] if not dim else G["line"], WEIGHT[rarity], 3)
    colour = G["strong"] if not dim else G["line"]
    if kind == "shard":
        t.paint(t.poly([(cx, cy - 12), (cx + 7, cy), (cx, cy + 12), (cx - 7, cy)]), colour)
    elif kind == "stones":
        for dx, dy in ((-5, 5), (5, 5), (0, -4)):
            t.paint(t.poly(ui.cut_box(cx + dx - 4.5, cy + dy - 4.5, cx + dx + 4.5, cy + dy + 4.5, 2, 2, 2, 2)), colour)
    else:
        pts = [(cx + 10 * np.cos(a), cy + 10 * np.sin(a)) for a in np.radians(np.arange(30, 390, 60))]
        t.paint(t.poly(pts), colour)


def rates(t, x1, cy):
    """Drop rates' mark (AR30's): three rules, longest first; the line's top half is its tap."""
    for i, length in enumerate((10.0, 7.5, 5.0)):
        y = cy + (i - 1) * 4.4
        t.paint(np.maximum(np.abs(t.y - y) - 0.9, np.abs(t.x - (x1 - length / 2)) - length / 2), G["soft"])


def clock(t, x, y, shares):
    """The building's clock, carried to the band: five minutes, each lit while it's to run, from its foot."""
    for k, share in enumerate(shares):
        x0 = x + k * 9
        box(t, x0, y, x0 + 6, y + 20, G["spent"], cut=1.0)
        if share > 0:
            box(t, x0, y + 20 * (1 - share), x0 + 6, y + 20, G["lit"], cut=1.0)


def line_card(t, x0, y0, x1, y1, line):
    """One line of the shelf: its picture, its name, the count left to this player, Buy with its price."""
    if line is None:
        box(t, x0, y0, x1, y1, G["cover"], G["line"], 1.0)
        t.text((x0 + x1) / 2, (y0 + y1) / 2 - 18, SMALL, "No rare line", G["soft"], align="CENTER")
        t.text((x0 + x1) / 2, (y0 + y1) / 2 + 2, SMALL, "this stock", G["soft"], align="CENTER")
        return
    kind, rarity, name, sub, price, left, state = line
    box(t, x0, y0, x1, y1, G["panel"], G["line"], 1.0)
    icon(t, kind, x0 + 5 + 18, y0 + 5 + 18, rarity, dim=state == "bought")
    t.text(x0 + 46, y0 + 8, SMALL, name, G["text"], bold=0.1)
    t.text(x0 + 46, y0 + 25, SMALL, sub, G["soft"])
    if kind == "shard":
        rates(t, x1 - 6, y0 + 52)
    if state == "need":
        t.text(x0 + 6, y0 + 46, SMALL, left, G["bad"])
    else:
        t.text(x0 + 6, y0 + 46, SMALL, left, G["soft"] if state == "bought" else G["text"])
    if state == "bought":
        buy(t, x0 + 5, y1 - 5 - TAP, x1 - 5, y1 - 5, word="Bought", on=False)
    else:
        buy(t, x0 + 5, y1 - 5 - TAP, x1 - 5, y1 - 5, price=price, on=state != "need")


def portrait(t, x0, y0, s, dim=False):
    """The rare offer's Voidkin, a grey head and shoulders in its Epic frame: two lines, the outer one apart."""
    colour = G["line"] if dim else G["strong"]
    box(t, x0 - 3, y0 - 3, x0 + s + 3, y0 + s + 3, G["cover"], colour, 1.2, 6)
    box(t, x0, y0, x0 + s, y0 + s, G["off"], colour, 2.4, 5)
    cx = x0 + s / 2
    t.paint(np.hypot(t.x - cx, t.y - (y0 + s * 0.38)) - s * 0.17, colour)
    t.paint(t.poly([(cx - s * 0.34, y0 + s - 4), (cx - s * 0.22, y0 + s * 0.62), (cx + s * 0.22, y0 + s * 0.62),
                    (cx + s * 0.34, y0 + s - 4)]), colour)


def rare_card(t, x0, y0, x1, y1, offer):
    """The rare offer's place, apart from the shelf: whom it is, or that none is in, with its chance always."""
    cx = (x0 + x1) / 2
    box(t, x0, y0, x1, y1, G["panel"] if offer else G["cover"], G["strong"] if offer else G["line"], 2.0 if offer else 1.0, 6)
    t.text(cx, y0 + 8, SMALL, "Rare offer", G["text"], align="CENTER", bold=0.15)
    t.text(cx, y0 + 26, SMALL, "about 1 stock in 12", G["soft"], align="CENTER")
    if offer is None:
        for k, words in enumerate(("None this stock.", "When one is in,", "the Shop's crown", "is lit.")):
            t.text(cx, y0 + 96 + k * 19, SMALL, words, G["soft"], align="CENTER")
        return
    name, said, price, left, shut = offer
    s = 74
    portrait(t, cx - s / 2, y0 + 50, s, dim=shut is not None)
    t.text(cx, y0 + 134, TITLE, name, G["text"], align="CENTER", bold=0.2)
    t.text(cx, y0 + 155, SMALL, said, G["soft"], align="CENTER")
    if shut:
        buy(t, x0 + 6, y1 - 6 - TAP - 22, x1 - 6, y1 - 6 - 22, word="Opens with", on=False)
        t.text(cx, y1 - 22, SMALL, shut, G["bad"], align="CENTER")
    else:
        buy(t, x0 + 6, y1 - 6 - TAP - 22, x1 - 6, y1 - 6 - 22, price=price)
        t.text(cx, y1 - 22, SMALL, left, G["text"], align="CENTER")


def phone(sheet, ox, oy, state):
    t = sheet.tile(ox, oy, W, H)
    box(t, 0, 0, W, H, G["cover"], cut=0)
    # the band: Roblox's buttons, then Back and the title, then the countdown and the player's Credits
    box(t, 0, 0, ROBLOX, BAND, G["roblox"], cut=0)
    t.text(ROBLOX / 2, BAND / 2 - 12, SMALL, "Roblox's", "#6E7280", align="CENTER")
    t.text(ROBLOX / 2, BAND / 2 + 4, SMALL, "buttons", "#6E7280", align="CENTER")
    back = (ROBLOX + PAD, (BAND - TAP) / 2, ROBLOX + PAD + 58, (BAND + TAP) / 2)
    box(t, *back, G["button"], G["strong"], 1.0, 4)
    t.stroke([(back[0] + 34, BAND / 2 - 8), (back[0] + 25, BAND / 2), (back[0] + 34, BAND / 2 + 8)], 2.2, G["text"])
    t.text(back[2] + 8, BAND / 2 - 6, TITLE, "Void Shop", G["text"], bold=0.25)
    clock(t, 300, BAND / 2 - 10, state["clock"])
    t.text(350, BAND / 2 - 15, SMALL, "Next stock", G["soft"])
    t.text(350, BAND / 2 + 3, TITLE, state["left"], G["text"], bold=0.2)
    box(t, 452, BAND / 2 - 15, W - PAD, BAND / 2 + 15, G["panel"], G["line"], 1.0, 15)
    coin(t, 468, BAND / 2, G["text"])
    t.text(480, BAND / 2 - 5, SMALL, state["credits"], G["text"], bold=0.15)
    # the body: the rare offer apart on the left, the shelf's six lines, the tables' chances under them
    top, foot = BAND + PAD, H - PAD
    rare_card(t, PAD, top, PAD + 148, foot, state["offer"])
    gx0, gx1 = PAD + 148 + GAP + 2, W - PAD
    cw = (gx1 - gx0 - 2 * GAP) / 3
    ch = (foot - 24 - top - GAP) / 2
    for k, line in enumerate(state["lines"]):
        x = gx0 + (k % 3) * (cw + GAP)
        y = top + (k // 3) * (ch + GAP)
        line_card(t, x, y, x + cw, y + ch, line)
    t.text(gx0 + 2, foot - 16, SMALL, "Each stock: 3 common, 2 uncommon. A rare line: about 1 in 3.", G["soft"])


STATES = [
    ("A stock with a rare offer in, and a rare line; the common emblem bought", dict(
        left="3:20", clock=[0, 1 / 3, 1, 1, 1], credits="46,800",
        offer=("Halcyon", "Epic Healer", "40,000", "1 left", None),
        lines=[("shard", "Common", "Standard", "shard", "800", "3 left", "on"),
               ("stones", "Common", "Grade 1", "stones x10", "600", "5 left", "on"),
               ("emblem", "Common", "Common", "emblem", "900", "None left", "bought"),
               ("shard", "Uncommon", "Enriched", "shard", "2,400", "2 left", "on"),
               ("stones", "Uncommon", "Grade 2", "stones x5", "1,800", "3 left", "on"),
               ("shard", "Rare", "Prismatic", "shard", "9,000", "1 left", "on")])),
    ("The usual stock in its last minute: no rare offer, no rare line; one line out of reach", dict(
        left="0:48", clock=[0, 0, 0, 0, 0.8], credits="1,950", offer=None,
        lines=[("shard", "Common", "Standard", "shard", "800", "3 left", "on"),
               ("stones", "Common", "Grade 1", "stones x10", "600", "5 left", "on"),
               ("emblem", "Common", "Common", "emblem", "900", "1 left", "on"),
               ("shard", "Uncommon", "Enriched", "shard", "2,400", "Need 450 more", "need"),
               ("emblem", "Uncommon", "Uncommon", "emblem", "1,500", "2 left", "on"),
               None])),
    ("A rare offer whose ground is still shut for this player", dict(
        left="2:05", clock=[0, 0, 0.41, 1, 1], credits="46,800",
        offer=("Halcyon", "Epic Healer", "40,000", "1 left", "Mask Parade"),
        lines=[("shard", "Common", "Standard", "shard", "800", "3 left", "on"),
               ("stones", "Common", "Grade 1", "stones x10", "600", "5 left", "on"),
               ("emblem", "Common", "Common", "emblem", "900", "1 left", "on"),
               ("stones", "Uncommon", "Grade 2", "stones x5", "1,800", "3 left", "on"),
               ("emblem", "Uncommon", "Uncommon", "emblem", "1,500", "2 left", "on"),
               ("emblem", "Rare", "Rare", "emblem", "7,500", "1 left", "on")])),
]

NOTES = [
    "What it is: the Shop's counter opens a full screen (Kit/Screen, Screen.Full).",
    "The band: Back and the title, then the countdown with the building's",
    "five-minute clock, and the player's Credits, since the HUD's pills are covered.",
    "The rare offer stands apart on the left, the whole height, its chance always on it.",
    "The shelf: commons on top, the uncommon two and the rare line under them.",
    "A line: its picture, its name, the count left to this player, and Buy with",
    "its price on it. Off, Buy is dimmed and the count's place says why.",
    "A shard line's top half opens its Drop rates (the Breaker's panel, the same),",
    "marked with AR30's three rules; a Named shard needs none: it's whom you see.",
    "Sizes: every tap 44 or more, no text under 14, Pad 7, Gap 5 (rendered).",
    "In grey, a rarity is its frame's weight; the pictures are stand-ins for",
    "AR21's shards and AR31's stones and emblems. Stand-ins too: the prices,",
    "the counts, the rare line's chance, and where Roblox's buttons end.",
]


def main():
    out = bl.out_dir()
    ui.K = 2                                  # the smallest phone's own pixels: two a point
    gap, head = 24, 64
    width = gap + 2 * (W + gap)
    height = head + 2 * (H + 40) + 20
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, "AR38, the Void Shop's screen in grey, at the smallest phone (568 x 320 points, at its own pixels)",
           "#EDE6D6", bold=0.2)
    for k, (said, state) in enumerate(STATES):
        x = gap + (k % 2) * (W + gap)
        y = head + (k // 2) * (H + 40)
        t.text(x, y - 4, SMALL, f"{'ABC'[k]}. {said}", "#B4AC9C")
        phone(sheet, x, y + 16, state)
    x, y = gap + W + gap, head + H + 40 + 16
    for k, words in enumerate(NOTES):
        t.text(x + 8, y + 6 + k * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "shop_screen.png")


if __name__ == "__main__":
    main()
