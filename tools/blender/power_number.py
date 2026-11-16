"""AR23: Combat Power's number, chromatic. Three takes on A's doll beside today's gold, at the smallest phone's size (the
director, 2026-11-16, 21:37: "the combat power text need to be chromatic ish right now it feels basics").

A take is what Faber builds from: the digits' fill as a UIGradient (its stops over the digits' box and its rotation), a
dark UIStroke, and its motion, if any. Each runs a few of the game's own hues (Config.UIKit's elements, Power's gold, the
emblem's violet), never a full rainbow and never a rarity's colour alone. The sheet shows each in A's doll at the
smallest phone (Theme.Smallest, 320 high: the layer draws at 0.85, 1.7 pixels a point), the number close, and its motion
in frames.

Run: blender --background --factory-startup --python tools/blender/power_number.py -- build/handoff/UI/inventory
"""
import math
import sys
import textwrap
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import inventory_directions as inv  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
from ui_sheet import c  # noqa: E402

K = inv.K  # A's sheet: 2 pixels a point
SMALLEST = 0.85  # Theme.Scale.Floor: the smallest phone held sideways draws a layer at 0.85
ZOOM = 6  # pixels a point, the number close

# Each take: its stops (place, colour) over the digits' box, the gradient's rotation (UIGradient.Rotation: 0 runs left to
# right, 90 top to bottom), the stroke's colour and thickness in points, and its motion.
TAKES = (
    # research's pick, with its fix (AR23, "Research's pick"): at the smallest phone the frost tops faded and the number
    # read as one lilac, so the white holds clear over the tops and Storm's pink reaches higher at the feet
    dict(key="A", name="Shard light", stops=((0.0, "#FFFFFF"), (0.22, "#FFFFFF"), (0.42, "#8FD8FF"), (0.6, "#B58CFF"),
                                             (0.78, "#FF6FD8"), (1.0, "#FF6FD8")),
         rotation=90.0, stroke=("#170E2A", 1.5), motion="sheen",
         words="The emblem's crystal carried into the digits: frost white at their tops, through Frost and Void to "
               "Storm's pink at their feet, each digit a shard. Motion: a pale sheen crosses the number every 4 s, "
               "0.9 s across, leaning with it; it never blinks."),
    dict(key="B", name="Ember to dusk", stops=((0.0, "#FFE38A"), (0.36, "#FF9A52"), (0.7, "#FF6FB8"), (1.0, "#B58CFF")),
         rotation=14.0, stroke=("#22101E", 1.5), motion="drift",
         words="A run across the number, from Power's gold through Fire and Storm to the emblem's Void: warm where it "
               "starts, dusk where it ends. Motion: the run drifts, its offset swinging 0.12 either way on a slow "
               "6 s sine, so the hues slide through the digits."),
    dict(key="C", name="Nacre", stops=((0.0, "#FFF2DA"), (0.28, "#FFC9E4"), (0.52, "#BFE6FF"), (0.76, "#DCCBFF"),
                                       (1.0, "#FFF2DA")),
         rotation=35.0, stroke=("#1A1424", 1.75), motion="drift",
         words="Pearl: ivory, with a blush, a frost and a lilac passing through it, as nacre changes when it's turned; "
               "quiet in the dark band, rich up close. Motion: the run drifts as in B, on 8 s."),
)


def stops_at(stops, t):
    """A ColorSequence's colour at t, between its stops, in sRGB as Roblox blends a sequence."""
    t = np.clip(t, 0.0, 1.0)
    out = np.zeros(t.shape + (3,), dtype=np.float32)
    for (a, ca), (b, cb) in zip(stops, stops[1:]):
        k = np.clip((t - a) / max(b - a, 1e-6), 0.0, 1.0)[..., None]
        inside = ((t >= a) & (t <= b))[..., None]
        out = np.where(inside, c(ca)[:3] + (c(cb)[:3] - c(ca)[:3]) * k, out)
    return out


def along(alpha, rotation, offset=0.0):
    """Where each pixel falls along a UIGradient's axis over the digits' box, 0 to 1, moved by its offset."""
    rows, cols = np.nonzero(alpha > 0.05)
    y0, y1, x0, x1 = rows.min(), rows.max() + 1, cols.min(), cols.max() + 1
    y, x = np.mgrid[0:alpha.shape[0], 0:alpha.shape[1]].astype(np.float32)
    u, v = (x - (x0 + x1) / 2) / max(x1 - x0, 1), (y - (y0 + y1) / 2) / max(y1 - y0, 1)
    a = math.radians(rotation)
    reach = abs(math.cos(a)) + abs(math.sin(a))
    return (u * math.cos(a) + v * math.sin(a)) / reach + 0.5 - offset


def sheen(alpha, at):
    """The sheen: a second label over the first, white, its gradient's transparency a narrow band leaning at 30
    degrees, its offset swept from -1 to 1 while `at` goes 0 to 1. None while it rests."""
    if at is None:
        return np.zeros_like(alpha)
    t = along(alpha, -60.0, -1.0 + 2.0 * at)
    return np.clip(1.0 - np.abs(t - 0.5) / 0.13, 0.0, 1.0) ** 1.5


def number(alpha, take, k, offset=0.0, glint=None):
    """The digits in a take: the stroke's dark under the fill, the sheen over it, on alpha."""
    stroke = ui.spread(alpha, max(1, round(take["stroke"][1] * k)))
    fill = stops_at(take["stops"], along(alpha, take["rotation"], offset))
    s = sheen(alpha, glint)[..., None]
    fill = fill + (1.0 - fill) * s
    out = np.zeros(alpha.shape + (4,), dtype=np.float32)
    a = alpha[..., None]
    out[..., :3] = fill * a + c(take["stroke"][0])[:3] * (1 - a)
    out[..., 3] = np.maximum(stroke, alpha)
    return out


def mask(items, w, h, k):
    """White text alone, its cover: the sheet's own text path, at `k` pixels a point."""
    keep = ui.K
    ui.K = k
    try:
        layer = ui.text_layers(w, h, [dict(i, colour="#FFFFFF", layer="plain") for i in items])["plain"]
    finally:
        ui.K = keep
    return layer[..., 3]


def screen_without_power(ground):
    """A's first screen, Rook's, drawn whole but for the number, its text laid; the number's own text item."""
    sheet = ui.Sheet(inv.W, inv.H, ground)
    state, who, chosen = inv.STATES[0]
    inv.draw_a(inv.Screen(sheet, 0, 0), state, who, chosen)
    power = [i for i in sheet.items if i["text"] == who["power"] and i["colour"] == inv.POWER_GOLD]
    assert len(power) == 1, power
    sheet.items.remove(power[0])
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    return sheet.px, power[0]


def main():
    out = bl.out_dir()
    p = inv.LACQUER
    who = inv.ROOK
    inv.FIGURES[who["who"]] = inv.figure_render(who["blend"])
    base, item = screen_without_power(p["top"])
    # today's number, as A draws it, then each take, all on the same screen
    today = mask([item], base.shape[1], base.shape[0], K)
    gold = np.zeros(base.shape, dtype=np.float32)
    gold[..., :3], gold[..., 3] = c(inv.POWER_GOLD)[:3], today
    variants = [("Today: Power's gold, flat", gold)]
    for take in TAKES:
        variants.append((f"{take['key']}, {take['name']}", number(today, take, K, glint=0.42)))
    # the doll's column, cut out, at the smallest phone
    crop = (104.0, 40.0, inv.A_BAG - 4.0, 375.0)
    cx0, cy0, cx1, cy1 = (round(v * K) for v in crop)
    shots = []
    for title, layer in variants:
        px = base.copy()
        rs.paste(px, layer, 0, 0)
        shots.append((title, rs.shrink(px[cy0:cy1, cx0:cx1], SMALLEST)))
    # the number close, and its motion
    pad = 8.0
    size = item["size"]
    w_pt = inv.width(who["power"], size) + 2 * pad
    h_pt = size + 2 * pad
    close_item = dict(item, x=pad, y=pad)
    close_big = dict(close_item, bold=item["bold"] * ZOOM / K)
    close = mask([close_big], round(w_pt * ZOOM), round(h_pt * ZOOM), ZOOM)
    small = mask([close_item], round(w_pt * K), round(h_pt * K), K)

    sh_w = 2 * 20 + 4 * (crop[2] - crop[0]) * SMALLEST * K / ui.K + 3 * 24
    cell_w = (crop[2] - crop[0]) * SMALLEST * K / ui.K
    lines = {take["key"]: textwrap.wrap(take["words"], 42) for take in TAKES}
    sh_h = 1000.0
    bottom = 0.0
    sheet = ui.Sheet(sh_w, sh_h, "#15120F")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(20, 14, 18, "Grow your Anime: Combat Power's number, three takes (AR23)", p["text"], bold=0.2 * ui.K)
    head = ("The director, 21:37: \"the combat power text need to be chromatic ish right now it feels basics\". Each "
            "take runs a few of the game's own hues with a dark edge; never a full rainbow, never a rarity's colour "
            "alone. Top: A's doll at the smallest phone (iPhone SE held sideways: the layer at 0.85, 1.7 pixels a "
            "point), each take caught mid-motion. Under it: the number close, at 6 pixels a point; then its motion, at "
            "the phone's size.")
    for k, line in enumerate(textwrap.wrap(head, 170)):
        t.text(20, 42 + k * 16, 11.5, line, p["soft"])
    y = 42 + 16 * len(textwrap.wrap(head, 170)) + 10
    for i, (title, shot) in enumerate(shots):
        x = 20 + i * (cell_w + 24)
        t.text(x, y, 13, title, p["text"])
        rs.paste(sheet.px, shot, round(x * ui.K), round((y + 20) * ui.K))
    y += 20 + shot.shape[0] / ui.K + 18
    for i, (title, layer) in enumerate(variants):
        x = 20 + i * (cell_w + 24)
        take = TAKES[i - 1] if i else None
        big = number(close, take, ZOOM, glint=0.42) if take else None
        if big is None:
            big = np.zeros(close.shape + (4,), dtype=np.float32)
            big[..., :3], big[..., 3] = c(inv.POWER_GOLD)[:3], close
        scale = min(1.0, cell_w * ui.K / big.shape[1])
        big = rs.shrink(big, scale) if scale < 1.0 else big
        box = sheet.tile(x, y, cell_w, big.shape[0] / ui.K + 8)
        box.paint(box.x * 0 - 1, c("#0A0807"))
        rs.paste(sheet.px, big, round(x * ui.K), round((y + 4) * ui.K))
        if take is None:
            t.text(x, y + big.shape[0] / ui.K + 16, 11, "Today: #FFD36B, no edge, still.", p["soft"])
            continue
        yy = y + big.shape[0] / ui.K + 16
        st = take["stops"]
        rows = ["  ".join(f"{a:.2f} {h}" for a, h in st[n:n + 2]) for n in range(0, len(st), 2)]
        t.text(x, yy, 10.5, f"UIGradient, Rotation {take['rotation']:.0f}:", p["text"])
        for n, row in enumerate(rows):
            t.text(x, yy + 15 + n * 15, 10.5, row, p["soft"])
        yy += 15 * (len(rows) - 2)
        t.text(x, yy + 45, 10.5, f"UIStroke {take['stroke'][0]}, {take['stroke'][1]} points", p["soft"])
        yy += 15
        # its motion, in frames at the phone's size
        frames = ((0.15, 0.0), (0.42, 0.0), (0.7, 0.0), (None, 0.0)) if take["motion"] == "sheen" else \
            ((None, -0.12), (None, -0.04), (None, 0.04), (None, 0.12))
        fy = yy + 52
        t.text(x, fy, 10.5, "Its sheen, 0.9 s across, every 4 s:" if take["motion"] == "sheen" else
               "Its drift, the offset from -0.12 to 0.12:", p["text"])
        for j, (glint, offset) in enumerate(frames):
            frame = rs.shrink(number(small, take, K, offset=offset, glint=glint), SMALLEST)
            fx = x + (j % 2) * (cell_w / 2)
            fyy = fy + 18 + (j // 2) * (frame.shape[0] / ui.K + 6)
            tile = sheet.tile(fx, fyy, frame.shape[1] / ui.K, frame.shape[0] / ui.K)
            tile.paint(tile.x * 0 - 1, c("#0A0807"))
            rs.paste(sheet.px, frame, round(fx * ui.K), round(fyy * ui.K))
        ty = fy + 18 + 2 * (frame.shape[0] / ui.K + 6) + 8
        for k, line in enumerate(lines[take["key"]]):
            t.text(x, ty + k * 15, 10.5, line, p["soft"])
        bottom = max(bottom, ty + 15 * len(lines[take["key"]]))
    notes = ("The number is A's 18 points, Blender's face standing in for the game's; the stroke and the stops are the "
             "build's numbers. The gradient's stops run over the digits' own box (the label sized to its text). The "
             "sheen is a second label over the first: white, its UIGradient's transparency a narrow band, its offset "
             "swept from -1 to 1.",
             "Not here: the same treatment anywhere else (its own word); the card's gains stay green and red.")
    wrapped = [line for n in notes for line in textwrap.wrap(n, 170)]
    ny = bottom + 16
    for k, line in enumerate(wrapped):
        t.text(20, ny + k * 16, 11, line, p["soft"])
    sheet.px = sheet.px[:round((ny + 16 * len(wrapped) + 14) * ui.K)].copy()
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "power_number.png")
    print(f"wrote {out / 'power_number.png'} {sheet.px.shape[1]}x{sheet.px.shape[0]}")


main()
