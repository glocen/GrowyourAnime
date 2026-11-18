"""AR38's screen in grey: the Void Shop's counter screen at the smallest phone, in its states, for research's read.
Throwaway: grey boxes and Blender's own face standing in for the kit's, nothing exported.

What it holds (docs/design.md, "The Strip", the Void Shop; D6 in docs/decisions.md, which replaced the six lines and
the rare offer of 2026-11-17): the featured gear piece's place apart, with how often one comes up, its preview and its
price; the Standard shard's line with its Drop rates, the count left to this player and its price; the countdown to
the next stock. A full screen (Kit/Screen, Screen.Full): Back and the title in the band Roblox's top bar leaves free,
then the body.

Measured in rendered points at the smallest phone (Theme.Smallest, 568 x 320), with the kit's sizes at the scale's
floor of 0.85: Pad 8 and Gap 6 authored draw 7 and 5, a tap 44, and no text under 14. The band is Roblox's top bar,
58 tall; where Roblox's own buttons end is read live in game (GuiService.TopbarInset), drawn here at 104 as a stand-in.
Prices, counts, stats and the featured stock's chance are stand-ins too, until tools/balance/seeds.json sets them.

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
SPLIT = PAD + 272        # the featured piece's place ends here; the shard's starts a gap after
CHANCE = "about 1 stock in 6"   # stand-in: how often a featured stock comes up

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


def picture(t, kind, cx, cy, rarity, dim=False):
    """Grey stand-ins for the pictures (AR21's shard, AR22's gear): a shard, gloves, an axe, in a frame of 64."""
    colour = G["strong"] if not dim else G["line"]
    box(t, cx - 32, cy - 32, cx + 32, cy + 32, G["off"], colour, WEIGHT[rarity], 5)
    if kind == "shard":
        t.paint(t.poly([(cx, cy - 22), (cx + 12, cy), (cx, cy + 22), (cx - 12, cy)]), colour)
    elif kind == "gloves":
        box(t, cx - 12, cy - 16, cx + 10, cy + 8, colour, cut=5)
        t.paint(t.poly([(cx + 8, cy - 6), (cx + 18, cy - 12), (cx + 20, cy - 6), (cx + 10, cy + 4)]), colour)
        box(t, cx - 14, cy + 11, cx + 12, cy + 19, colour, cut=2)
    else:
        t.stroke([(cx - 16, cy + 22), (cx + 10, cy - 18)], 3.2, colour)
        t.paint(t.poly([(cx + 2, cy - 26), (cx + 22, cy - 20), (cx + 20, cy + 2), (cx + 6, cy - 12)]), colour)


def rates(t, x1, cy):
    """Drop rates' mark (AR30's): three rules, longest first."""
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


def head(t, x0, y0, x1, title, aside):
    t.text(x0 + 10, y0 + 8, SMALL, title, G["text"], bold=0.15)
    t.text(x1 - 10, y0 + 8, SMALL, aside, G["soft"], align="RIGHT")


def count_and_buy(t, x0, x1, y1, price, left, state, preview=False):
    """The count left to this player over Buy; the featured piece's Preview stands before Buy."""
    t.text(x0 + 10, y1 - 6 - TAP - 22, SMALL, left, G["bad"] if state == "need" else
           G["soft"] if state == "bought" else G["text"])
    bx = x0 + 6
    if preview:
        buy(t, bx, y1 - 6 - TAP, bx + 96, y1 - 6, word="Preview")
        bx += 96 + GAP
    if state == "bought":
        buy(t, bx, y1 - 6 - TAP, x1 - 6, y1 - 6, word="Bought", on=False)
    else:
        buy(t, bx, y1 - 6 - TAP, x1 - 6, y1 - 6, price=price, on=state != "need")


def featured_card(t, x0, y0, x1, y1, item):
    """The featured gear piece apart, with how often one comes up always on it; or that none is in."""
    box(t, x0, y0, x1, y1, G["panel"] if item else G["cover"], G["strong"] if item else G["line"],
        2.0 if item else 1.0, 6)
    head(t, x0, y0, x1, "Featured", CHANCE)
    if item is None:
        cx = (x0 + x1) / 2
        for k, words in enumerate(("None this stock.", "When one is in,", "the Shop's crown is lit.")):
            t.text(cx, y0 + 82 + k * 19, SMALL, words, G["soft"], align="CENTER")
        return
    kind, rarity, name, slot, stats, reason, price, left, state = item
    picture(t, kind, x0 + 10 + 32, y0 + 36 + 32, rarity, dim=state == "bought")
    t.text(x0 + 86, y0 + 40, TITLE, name, G["text"], bold=0.2)
    t.text(x0 + 86, y0 + 62, SMALL, slot, G["soft"])
    t.text(x0 + 86, y0 + 80, SMALL, rarity, G["text"])
    t.text(x0 + 10, y0 + 108, SMALL, stats, G["text"])
    if reason:
        t.text(x0 + 10, y0 + 127, SMALL, reason, G["bad"])
    count_and_buy(t, x0, x1, y1, price, left, state, preview=True)


def shard_card(t, x0, y0, x1, y1, shard):
    """The Standard shard's line: its picture, whom it draws from, its Drop rates, the count left, Buy."""
    price, left, state = shard
    box(t, x0, y0, x1, y1, G["panel"], G["line"], 1.0, 6)
    head(t, x0, y0, x1, "Shards", "2 each player, each stock")
    picture(t, "shard", x0 + 10 + 32, y0 + 36 + 32, "Common", dim=state == "bought")
    t.text(x0 + 86, y0 + 40, TITLE, "Standard shard", G["text"], bold=0.2)
    t.text(x0 + 86, y0 + 62, SMALL, "a Voidkin of Lantern Row", G["soft"])
    t.text(x0 + 86, y0 + 80, SMALL, "Common", G["text"])
    ry0 = y0 + 104
    box(t, x0 + 6, ry0, x1 - 6, ry0 + TAP, G["off"], G["line"], 1.0, 4.0)
    rates(t, x0 + 6 + 22, ry0 + TAP / 2)
    t.text(x0 + 36, ry0 + TAP / 2 - 6, SMALL, "Drop rates", G["text"])
    t.stroke([(x1 - 22, ry0 + TAP / 2 - 6), (x1 - 16, ry0 + TAP / 2), (x1 - 22, ry0 + TAP / 2 + 6)], 1.8, G["soft"])
    count_and_buy(t, x0, x1, y1, price, left, state)


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
    # the body: the featured piece apart on the left, the shard's line on the right, the stock's rule under them
    top, foot = BAND + PAD, H - PAD
    featured_card(t, PAD, top, SPLIT, foot - 24, state["featured"])
    shard_card(t, SPLIT + GAP, top, W - PAD, foot - 24, state["shard"])
    t.text(PAD + 2, foot - 16, SMALL, "A new stock every 5 minutes, in every server. Your counts are your own.", G["soft"])


STATES = [
    ("A featured stock: gloves for every class; one shard bought", dict(
        left="3:20", clock=[0, 1 / 3, 1, 1, 1], credits="46,800",
        featured=("gloves", "Rare", "Rare Gloves", "Gloves, any class", "Attack +86, Health +240", None,
                  "6,000", "1 left", "on"),
        shard=("800", "1 left", "on"))),
    ("The usual stock in its last minute: none featured; the shard out of reach", dict(
        left="0:48", clock=[0, 0, 0, 0, 0.8], credits="650", featured=None,
        shard=("800", "Need 150 more", "need"))),
    ("A featured weapon of a class this player has none of; the shards bought out", dict(
        left="2:05", clock=[0, 0, 0.41, 1, 1], credits="46,800",
        featured=("axe", "Rare", "Great Axe", "Main Hand, Tank only", "Attack +140", "You have no Tank yet",
                  "7,500", "1 left", "on"),
        shard=("800", "None left", "bought"))),
]

NOTES = [
    "What it is: the Shop's counter opens a full screen (Kit/Screen, Screen.Full).",
    "The band: Back and the title, then the countdown with the building's",
    "five-minute clock, and the player's Credits, since the HUD's pills are covered.",
    "On D6's shelf: the featured gear piece apart on the left, how often one",
    "comes up always on it; the Standard shard's line on the right.",
    "Preview opens the bag's item card on the lead, unchanged. A piece for a",
    "class the player hasn't got says so in red, and can still be bought.",
    "Drop rates opens the Breaker's panel, the same, marked with AR30's rules.",
    "Off, Buy is dimmed and the count's place says why; bought out, \"Bought\".",
    "Sizes: every tap 44 or more, no text under 14, Pad 7, Gap 5 (rendered).",
    "Stand-ins: the prices, counts, stats, the featured chance, the pictures",
    "(AR21's shard, AR22's gear), where Roblox's buttons end; in grey,",
    "a rarity is its frame's weight.",
]


def main():
    out = bl.out_dir()
    ui.K = 2                                  # the smallest phone's own pixels: two a point
    gap, head_h = 24, 64
    width = gap + 2 * (W + gap)
    height = head_h + 2 * (H + 40) + 20
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, "AR38, the Void Shop's screen on D6's shelf, in grey, at the smallest phone (568 x 320 points)",
           "#EDE6D6", bold=0.2)
    for k, (said, state) in enumerate(STATES):
        x = gap + (k % 2) * (W + gap)
        y = head_h + (k // 2) * (H + 40)
        t.text(x, y - 4, SMALL, f"{'ABC'[k]}. {said}", "#B4AC9C")
        phone(sheet, x, y + 16, state)
    x, y = gap + W + gap, head_h + H + 40 + 16
    for k, words in enumerate(NOTES):
        t.text(x + 8, y + 6 + k * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "shop_screen.png")


if __name__ == "__main__":
    main()
