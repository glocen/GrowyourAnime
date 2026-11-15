"""The level-up as a notice on the left, takes for the director's pick (the director, 2026-11-15, night: "the leveling
up text need a rework", all of it; then "the level up could come as a notice like on the left usually ui but different
color with the name of the voidkin + level text reworked"; docs/decisions.md).

Three takes beside today's. Each is a shape, a colour and its words, and the three can be mixed: every shape is also
drawn in the other two colours. The notice stands on the left under the lead's card and its readout, where its Voidkin
lives. The screen is V2, Block with the new dock and the lead's card as picked (round two's F, one solid bar in D's
ruby), just after the level: the card already says the new level and experience starts again.

Mocks only, drawn here from plain shapes; the level's chevrons are TR17's mark.

    blender -b --factory-startup --python tools/blender/levelup_notice_takes.py -- build/handoff/UI/hud/levelup_takes

Writes the sheet levelup_notice_takes.png.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lead_card_round2 as r2  # noqa: E402

lt = r2.lt
h, dk = lt.h, lt.dk
kit, ui, c, lc = h.kit, h.ui, h.c, h.lc
K4 = h.K4
S = lc.SLANT
MG = 16.0  # a plate's margin, for its shadow and its glow
BOLD = 0.7  # a strong word's extra weight, in a sheet's pixels at true size

CARD = {k: v for k, v in dict(r2.TAKES[3], hp=r2.RUBY).items() if k != "cells"}  # the director's pick
NOTICE = (lt.CARD_X, 238.0)  # under the readout's row (its foot at 230), over the thumbstick (its top at 289)

# A colour: the plate's body, top and foot; its block; what's drawn on the block; the words; the quieter words; the rim.
PEARL = dict(key="Pearl", body=("#FFFFFF", "#DAD3C2"), block=("#3A4050", "#14161B"), on="#FFFFFF", text="#14161B",
             soft="#565C69", rim="#FFFFFF", glow="#FFFFFF")
VIOLET = dict(key="Violet", body=("#4C3BA0", "#170F36"), block=("#F6F1FF", "#B79CF5"), on="#1D1245", text="#FFFFFF",
              soft="#D8C8FF", rim="#C9B2FF", glow="#B79CF5")
LIME = dict(key="Lime", body=("#3B4C10", "#151C05"), block=("#E6FF8A", "#A6DA28"), on="#141C05", text="#F4FFD2",
            soft="#C8F550", rim="#C2F24A", glow="#B8F23C")
COLOURS = (PEARL, VIOLET, LIME)

WIDE = dict.fromkeys("iljtfrI1.,·'", 0.36)
WIDE.update({" ": 0.3, "m": 0.9, "w": 0.82, "M": 0.86, "W": 0.94, "+": 0.6})


STEP = (44.0, 40.0)  # B's plate: how tall it is, and how wide its block


def est(text, size, space=1.0):
    """A word's width in points, near enough to lay a plate round it: Blender's face stands in for the game's."""
    if text in h.NAME_W and space == 1.0:
        return h.NAME_W[text] * size / 16.0  # measured for the lead's card
    each = (WIDE.get(ch, 0.6 if ch.isdigit() else 0.7 if ch.isupper() else 0.57) for ch in text)
    return sum(each) * size * space * 0.86  # measured on the first sheet: the plain sum ran a sixth long


def word(st, x, y, size, text, colour, align="LEFT", bold=0.0, shear=0.0, space=1.0):
    st.items.append(dict(x=x, y=y, size=size, text=text, colour=colour, align=align, layer="plain", shear=shear,
                         bold=bold, space=space))


def plate_tile(w, tall, bw, col):
    """A leaning plate, as the card's rows lean: its body, a block of its colour at the left end, a rim, one sheen. On a
    tile of its own, MG wider on every side for its shadow and its glow."""
    t = kit.blank(w + 2 * MG, tall + 2 * MG)
    t.x -= MG
    t.y -= MG
    lean = tall * S
    body = t.poly([(lean, 0), (w, 0), (w - lean, tall), (0, tall)])
    v = t.y / tall
    fade = np.clip(1 - np.maximum(body, 0) / (MG - 1), 0, 1)  # both glows are out by the tile's edge
    ui.over(t.px, ui.BLACK, 0.55 * np.exp(-(np.maximum(body, 0) / 5.0) ** 1.4) * fade)
    ui.over(t.px, c(col["glow"]), 0.2 * np.exp(-(np.maximum(body, 0) / 7.0) ** 1.4) * fade)
    t.paint(body, lc.stops(t, v, ((0, col["body"][0]), (1, col["body"][1]))))
    past = (t.x - bw - (tall - t.y) * S)  # right of the block's leaning end
    t.paint(np.maximum(body, past), lc.stops(t, v, ((0, col["block"][0]), (1, col["block"][1]))))
    t.paint(np.maximum(body, np.abs(past - 0.5) - 0.6), c("#000000"), 0.6)
    sheen = np.clip(1 - np.abs(t.x - (w - 40.0) - (tall - t.y) * S) / 14.0, 0, 1)
    ui.over(t.px, c("#FFFFFF"), lc.cover(np.maximum(body, -past)) * sheen * 0.1)
    t.paint(np.maximum(body, np.abs(t.y - 1.9) - 0.5), c("#FFFFFF"), 0.28)
    t.line(body + 1.1, 0.7, c("#000000"), 0.8)
    t.line(body, 1.1, c(col["rim"]))
    return t


def plate(st, x, y, w, tall, bw, col):
    h.place(st, plate_tile(w, tall, bw, col), x - MG, y - MG)


def slab(st, x, y, col, who, n):
    """The name over the level: two lines, the level the larger."""
    tall, bw = 40.0, 28.0
    name, big = who.upper(), f"LEVEL {n}"
    w = bw + tall * S + 9 + max(est(name, 11, 1.12) + 10, est(big, 20) + 4) + 12
    plate(st, x, y, w, tall, bw, col)
    st.icon("LevelChevrons", x + (bw + tall * S) / 2 - 1, y + tall / 2, 19.0, tint=col["on"])
    word(st, x + bw + (tall - 10) * S + 9, y + 6.5, 11, name, col["soft"], space=1.12)  # the kit's smallest text
    word(st, x + bw + (tall - 28) * S + 9, y + 20, 20, big, col["text"], bold=BOLD, shear=0.16)
    return w, tall


def step(st, x, y, col, who, n):
    """The number first, on the block; the name; then what happened."""
    tall, bw = STEP
    line = "LEVEL UP"
    w = bw + tall * S + 10 + max(est(who, 16), est(line, 11, 1.14)) + 14
    plate(st, x, y, w, tall, bw, col)
    size = {1: 27, 2: 25, 3: 19}[len(str(n))]
    word(st, x + (bw + tall * S) / 2 - 1, y + (tall - size * ui.CAP) / 2, size, str(n), col["on"], "CENTER", bold=BOLD)
    word(st, x + bw + (tall - 13) * S + 10, y + 8, 16, who, col["text"])
    word(st, x + bw + (tall - 32) * S + 10, y + 28, 11, line, col["soft"], space=1.14)
    return w, tall


def ribbon(st, x, y, col, who, n):
    """One line at a toast's height: the name, then its level."""
    tall, bw = 28.0, 24.0
    level = f"LEVEL {n}"
    left = bw + tall * S / 2 + 9
    w = left + est(who, 14) + 12 + est(level, 14) + 4 + tall * S / 2 + 8
    plate(st, x, y, w, tall, bw, col)
    st.icon("LevelChevrons", x + (bw + tall * S) / 2 - 1, y + tall / 2, 15.0, tint=col["on"])
    ty = y + (tall - 14 * ui.CAP) / 2
    word(st, x + left, ty, 14, who, col["text"])
    word(st, x + left + est(who, 14) + 12, ty, 14, level, col["soft"], bold=BOLD * 0.8, shear=0.12)
    return w, tall


def today(st, sc):
    """As it is: a toast under the pills in experience's blue, and the word over the lead."""
    l, tp, r, _ = h.SAFE
    x, y = r - h.PAD - 220, tp + 92
    kit.panel(st, x, y, 220, 28, h.GRAPHITE)
    st.text(x + 8, y + (28 - 14 * ui.CAP) / 2, 14, f"{sc['who']} reached level {sc['level']}", "#4E9BFF")
    word(st, (l + r) / 2 - 60, 196, 22, f"Level {sc['level']}", "#FFFFFF", "CENTER", bold=BOLD)


TAKES = (
    dict(key="Now", name="as it is", crop=(468.0, 64.0),
         notes=("A toast under the pills on the right, in experience's blue: \"Rook reached level 12\". Over the lead, "
                "\"Level 12\" in white and a column of light.",)),
    dict(key="A", name="Slab, in pearl", draw=slab, colour=PEARL,
         notes=("The one pale plate on a dark HUD: a colour of its own by its light, on dusk and on noon. The name in "
                "small capitals over the level, the level's chevrons at its head.",
                "Words: \"ROOK\" over \"LEVEL 12\".")),
    dict(key="B", name="Step, in the card's violet", draw=step, colour=VIOLET,
         notes=("The number first, in ink on a lavender block, as V2, Block sets a mark; the body is the lead's card's "
                "violet, so it reads as the card speaking.",
                "Words: \"12\", \"Rook\", \"LEVEL UP\".")),
    dict(key="C", name="Ribbon, in lime", draw=ribbon, colour=LIME,
         notes=("The usual notice's one line and height, on the left, in a hue nothing on the HUD wears. Lime falls "
                "near Power's yellow for a deuteranope (AR12's measure): its place and words tell it apart.",
                "Words: \"Rook\", then \"LEVEL 12\".")),
)
CROP = (58.0, 160.0, 290.0, 132.0)  # the corner up close: left, top, width, height
STRIP_W = h.W - 2 * CROP[2]
LONG = ("Little Storm Cloud", 100)  # a nickname near its twenty characters, at the highest level


def screen(sc, take):
    """The HUD as V2, Block lays it out, the lead's card as picked, and the take's notice."""
    st = kit.Stage.__new__(kit.Stage)  # its ground is the street, not a fill
    st.w, st.h, st.items = h.W, h.H, []
    st.px = h.backdrop(sc["kind"])
    l, tp, r, b = h.SAFE
    h.phone(st)
    h.target(st, (l + r) / 2 - 108, tp + h.TOP + 18, 0.56)
    r2.card(st, lt.CARD_X, lt.CARD_Y, sc, CARD)
    foot = tp + h.TOP + 89
    h.readout(st, l + h.PAD + 2, foot + 10, 58.0, sc["share"], sc["signature"])
    h.spectate(st, l + h.PAD + 2 + 58 + 10, foot + 10 + 7, 44.0, sc["eye"])
    px, py = r - h.PAD, tp + h.TOP + h.PILL + h.GAP
    h.pill(st, px - 120, tp + h.TOP, 120, h.CREDITS, h.BLOCK, "CoinMint", "35,170")
    h.pill(st, px - 200, py, 200, h.POWER, h.BLOCK, "Bolt", "30 kW", "24 kW used", None, 24 / 30)
    dk.dock(st, (l + r) / 2 - dk.DW / 2, b - h.PAD - dk.DH)
    if "draw" in take:
        take["draw"](st, *NOTICE, take["colour"], sc["who"], sc["level"])
    else:
        today(st, sc)
    return h.bytes8(h.halve(st.px)), st.items


def small(items):
    """A picture's words, for the picture at half its size."""
    return [dict(i, x=i["x"] / 2, y=i["y"] / 2, size=i["size"] / 2, bold=i["bold"] / 2) for i in items]


def crop(px, items, box):
    """A corner of a screen, as drawn, and the words that begin in it."""
    x0, y0 = box
    w, tall = CROP[2], CROP[3]
    k = 2  # a screen is kept at two pixels a point
    cut = px[round(y0 * k):round((y0 + tall) * k), round(x0 * k):round((x0 + w) * k)]
    words = [dict(i, x=i["x"] - x0, y=i["y"] - y0) for i in items
             if (x0 <= i["x"] <= x0 + w - 30 or i["align"] != "LEFT" and x0 + 30 <= i["x"] <= x0 + w)
             and y0 <= i["y"] <= y0 + tall - 8]
    return cut, words


def others(take):
    """The take's shape in the other two colours."""
    st = kit.Stage(STRIP_W, CROP[3], h.PARTS_GROUND)
    if "draw" not in take:
        st.text(STRIP_W / 2, 60, 10, "Today's, for the comparison.", h.NOTE, "CENTER")
        return h.bytes8(h.halve(st.px)), st.items
    st.text(10, 8, 10, "The same shape in the other two colours:", h.NOTE)
    y = 28.0
    for col in COLOURS:
        if col is not take["colour"]:
            take["draw"](st, 10, y, col, "Rook", 12)
            y += 52
    return h.bytes8(h.halve(st.px)), st.items


def longest():
    """Each take at its longest: a nickname near twenty characters, at level 100."""
    st = kit.Stage(h.W, 66.0, h.PARTS_GROUND)
    x = 0.0
    for take in TAKES:
        if "draw" in take:
            w, _ = take["draw"](st, x + 4, 14, take["colour"], *LONG)
            x += w + 14
    return h.bytes8(h.halve(st.px)), st.items


def sheet(out, rows, tail):
    ui.K = 2
    m, head, cap = 20.0, 92.0, 56.0
    w, tall = CROP[2], CROP[3]
    per = cap + tall + 6 + h.H / 2 + 16
    sh = ui.Sheet(h.W + 2 * m, head + len(rows) * per + 30 + 66 + 16, h.GROUND)
    t = sh.tile(0, 0, sh.w, head)
    t.text(m, 14, 17, "Grow your Anime: the level-up as a notice on the left, three takes beside today's", h.HEAD)
    for i, line in enumerate((
            "Each take stands under the lead's card, where its Voidkin lives: up close at dusk (Rook reaches 12) and at "
            "noon (a Mythical reaches 48), then on the whole HUD at a phone's size.",
            "A shape, a colour and the words can be picked from different takes. Proposed for all three, drawn after "
            "the pick: it slides out of the left edge in 0.2 s, the level lands with a pop",
            "and one sheen crosses the plate; it holds 2.5 s and leaves the way it came. Over the lead, the column of "
            "light stays and its word goes: the notice carries the words.")):
        t.text(m, 40 + i * 14, 10, line, h.NOTE)
    y = head
    for take, shots, strip in rows:
        tt = sh.tile(m, y, h.W, cap)
        tt.text(0, 6, 13, f"{take['key']}: {take['name']}", h.HEAD)
        for i, line in enumerate(take["notes"]):
            tt.text(0, 26 + i * 14, 10, line, h.NOTE)
        y += cap
        for i, (px, items) in enumerate(shots):
            h.add(sh, *crop(px, items, take.get("crop", CROP[:2])), m + i * w, y)
        h.add(sh, *strip, m + 2 * w, y)
        y += tall + 6
        for i, (px, items) in enumerate(shots):
            h.add(sh, h.halve(h.floats(px)), small(items), m + i * (h.W / 2), y)
        y += h.H / 2 + 16
    tt = sh.tile(m, y, h.W, 30)
    tt.text(0, 6, 13, "At their longest", h.HEAD)
    tt.text(120, 9, 10, "A nickname near its twenty characters, at level 100: A, B and C.", h.NOTE)
    h.add(sh, *tail, m, y + 30)
    kit.finish(sh, out / "levelup_notice_takes.png")


def main():
    out = bl.out_dir()
    ui.K = K4
    h.stage("started")
    kit.panels()
    kit.buttons()
    kit.bars()
    kit.icons()
    h.icons()
    h.card_images()
    lt.vm.marks()
    rows = []
    scenes = (dict(h.SCENES[0], xp=0.06), dict(h.SCENES[1], xp=0.04, covering=False))
    for take in TAKES:
        shots = [screen(sc, take) for sc in scenes]
        rows.append((take, shots, others(take)))
        h.stage(take["key"])
    tail = longest()
    h.BACKDROPS.clear()
    kit.IMAGES.clear()
    h.IMG.clear()
    sheet(out, rows, tail)
    h.stage("the sheet")


if __name__ == "__main__":
    main()
