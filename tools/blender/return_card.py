"""AR55, the return card's look, the blockout (docs/asset-requests.md, AR55; docs/test-requests.md, TR53): what the base
made while the player was away, three directions for research's pick, at the smallest phone (568 x 320 points, two
pixels a point). Each direction is drawn five times: the card with one line, with all four, and with a shard alone; the
base's state beside the run's line in the Festival; and the notice as the shard breaks.

    A, the Slip     a narrow slab under the pills, a line a change, the press at its foot under the right thumb. During
                    a run: a third pill under Electricity. The notice: a toast under it.
    B, the Sill     a low slab across the screen's foot, a cell a change, the press at its right end; the yard whole
                    above it. During a run: a tab hung from the run's line. The notice: the tab opens out.
    C, the Board    a slab in the middle in the Power screen's rows, a gauge a change. During a run: the next
                    step's plate, in the slab's teal. The notice: that plate, grown.

All in the system slab's make (Config.UIKit, System): the base speaking, not a reward. The content check's conditions on
the plan (2026-11-23) are kept: nothing sold or sped up on any piece; "Reveal" shows the shard's own picture and
promises nothing; no burst, rays or confetti; the breaking's mark is the shard's picture.

A block-in: the pictures are the game's own (the Power screen's battery and chips, the forge stone, the Lantern Row
shard), the yard is Faber's capture of TR51, the Festival's street and the HUD's other pieces are stand-ins, the words
are stand-ins but the three the request gives, and the text is Blender's face.

    blender -b --factory-startup --python tools/blender/return_card.py -- <abs out>

Writes return_card_A.png, _B.png, _C.png, and return_card_small.png (every phone at 64 pixels high).
"""
import gc
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import stage_screen as ss  # noqa: E402
import stage_seam as sm  # noqa: E402

W, H = ss.W, ss.H
SMALL, TITLE = ss.SMALL, ss.TITLE
P = sm.P
UI = up.REPO / "build" / "handoff" / "UI"
YARD = up.REPO / "build" / "captures" / "tr51" / "phone_stage3_court.png"
# Config.UIKit, System: the deep teal slab in a sand edge, ivory ink; Main, the one main action's sand plate in ink
SYS = dict(panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", facet="#A9DCD4", glint="#F2FFF9", text="#FFF6E2", soft="#D9E8E2",
           faint="#A9C0BC", channel="#0E1D23", row="#3C6A76", main=("#F0E2C4", "#DCCBA6"), ready=("#FFE29A", "#F2C766"),
           ink="#1E3238")
POWER, ROSE, CYAN, SILVER, CREDITS = ui.CHARGE, "#FF8FAE", "#4FD1FF", "#E6ECF7", "#40DCC6"
HEAD, AWAY = "While you were away", "3 h 12 min"
NOTICE = ("Your shard broke.", "Its Voidkin waits at home.")
LEFT = "12:40"
# A change: its picture (and how large it's drawn against its box), the gain, what it is, its machine, its light
GAINS = {
    "battery": dict(pic=UI / "hud" / "colour" / "images" / "Battery.png", grow=1.0, gain="+12.4 kWh", what="stored",
                    name="Battery", colour=POWER),
    "stones": dict(pic=UI / "upgrades" / "images" / "StoneLow.png", grow=1.05, gain="+6", what="Low stones",
                   name="Stone Condenser", colour=ROSE),
    "training": dict(pic=UI / "hud" / "colour" / "images" / "PowerChipTraining.png", grow=1.4, gain="+2 levels", what="Rook",
                     name="Training machine", colour=CYAN),
    "shard": dict(pic=UI / "shards" / "shard_standard_small.png", grow=1.15, gain="1 shard", what="ready",
                  name="Void Breaker", colour=SILVER),
}
ALL = ("battery", "stones", "training", "shard")
_px = {}


def wide(text, size, bold=False):
    return ss.wide_of(text, size) * (1.05 if bold else 1.0)


def picture(t, key, cx, cy, size, alpha=1.0):
    """A change's picture, `size` points across, its middle at (cx, cy)."""
    g = GAINS[key]
    if key == "stones":                                  # the Forge's stone in the kit's Common item cell, as AR53 drew it
        up.cell(t, cx - size / 2, cy - size / 2, size, "Common", g["pic"])
        return
    if key not in _px:
        _px[key] = rs.load(g["pic"])
    s = size * g["grow"]
    im = rs.shrink(_px[key], s * ui.K / _px[key].shape[0])
    im[..., 3] *= alpha
    t.image(im, cx - s / 2, cy - s / 2)


# --- the system slab's parts --------------------------------------------------------------------------------------------

def slab(t, x0, y0, x1, y1, cut=8.0, alpha=0.95):
    pts = lambda dy: ui.cut_box(x0, y0 + dy, x1, y1 + dy, cut, cut * 0.3, cut, cut * 0.3)  # noqa: E731
    t.glow(t.poly(pts(3)), 8.0, "#04090B", 0.5)
    d = t.poly(pts(0))
    t.paint(d, t.ramp(SYS["panel"][0], SYS["panel"][1], (t.y - y0) / (y1 - y0)), alpha)
    t.paint(d, SYS["glint"], 0.10 * np.exp(-np.maximum(t.y - y0, 0) / 16))
    t.line(d, 1.3, SYS["edge"], 0.95)
    return d


def press(t, x0, y0, x1, y1, word):
    """The card's one press: the main action's sand plate in ink; "Reveal" on the slab's Ready gold."""
    fill = SYS["ready"] if word == "Reveal" else SYS["main"]
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 2, 6, 2))
    t.glow(d, 5.0, fill[0], 0.32 if word == "Reveal" else 0.16)
    t.paint(d, t.ramp(fill[0], fill[1], (t.y - y0) / (y1 - y0)))
    t.line(d, 1.0, "#FFFFFF", 0.55)
    t.text((x0 + x1) / 2, (y0 + y1) / 2 - TITLE * 0.42, TITLE, word, SYS["ink"], "CENTER", bold=0.45)


def word_of(keys):
    return "Reveal" if "shard" in keys else "Collect"


def bar(t, x, y, w, spans):
    """A gauge's bed with its lit spans: (from, to, colour, how solid), shares of its length."""
    d = t.poly(ui.cut_box(x, y, x + w, y + 7, 2, 0, 2, 0))
    t.paint(d, SYS["channel"])
    for a, b, colour, solid in spans:
        lit = np.maximum.reduce([d + 1.0, (x + 1 + (w - 2) * a) - t.x, t.x - (x + 1 + (w - 2) * b)])
        if solid >= 1:
            t.glow(lit, 3.0, colour, 0.35)
        t.paint(lit, colour, solid)


def gauge(t, key, x, y, w):
    """C's gauge of a change, from its machine's screen: what there was, dim, and what came, lit."""
    colour = GAINS[key]["colour"]
    if key == "battery":                                 # 19 of 60 kWh before, 31.4 now
        bar(t, x, y, w, [(0, 19 / 60, colour, 0.4), (19 / 60, 31.4 / 60, colour, 1.0)])
    elif key == "stones":                                # the tray's twelve cups: 2 lay there, 6 came
        for k in range(12):
            cx = x + 5 + k * (w - 10) / 11
            d = t.poly([(cx + 4.2 * np.cos(np.radians(a)), y + 3.5 + 4.2 * np.sin(np.radians(a))) for a in range(0, 360, 60)])
            t.paint(d, SYS["channel"])
            if k < 8:
                if k >= 2:
                    t.glow(d, 2.5, colour, 0.3)
                t.paint(d + 1.0, colour, 0.4 if k < 2 else 1.0)
    elif key == "training":                              # level 7 to 9: two whole steps, then a little of the next
        for k, (solid, share) in enumerate(((1.0, 1.0), (1.0, 1.0), (0.4, 0.3))):
            x0 = x + k * (w + 4) / 3
            bar(t, x0, y, (w - 8) / 3, [(0, share, colour, solid)])
    else:                                                # the shard is through: its bar whole
        bar(t, x, y, w, [(0, 1.0, colour, 1.0)])


# --- the card, three ways -----------------------------------------------------------------------------------------------

def slip(t, keys):
    """A: a narrow slab that rises on the right, under the pills; a line a change; the press at its foot."""
    x0, x1, y1 = 380, 560, 314
    y0 = y1 - (6 + 18 + len(keys) * 26 + 4 + 44 + 6)
    slab(t, x0, y0, x1, y1)
    t.text(x0 + 10, y0 + 7, SMALL, HEAD, SYS["soft"])
    y = y0 + 26
    for key in keys:
        g = GAINS[key]
        t.stroke([(x0 + 8, y), (x1 - 8, y)], 1.0, SYS["facet"], 0.22)
        picture(t, key, x0 + 21, y + 13, 22)
        t.text(x0 + 38, y + 5, TITLE, g["gain"], SYS["text"], bold=0.35)
        t.text(x1 - 12, y + 7, SMALL, g["what"], SYS["soft"], "RIGHT")
        y += 26
    press(t, x0 + 8, y1 - 50, x1 - 8, y1 - 6, word_of(keys))


def sill(t, keys):
    """B: a low slab across the foot, grown from the right as far as its changes reach; its head a tab on its top."""
    cells = [26 + 6 + max(wide(GAINS[k]["gain"], TITLE, True), wide(GAINS[k]["what"], SMALL)) for k in keys]
    x1, y0, y1 = 560, 248, 312
    x0 = x1 - (8 + sum(cells) + 6 * (len(keys) - 1) + 8 + 78 + 8)
    tw = wide(HEAD, SMALL) + 18
    tab = t.poly(ui.cut_box(x0, y0 - 21, x0 + tw, y0 + 6, 6, 6, 0, 0))
    t.glow(tab, 6.0, "#04090B", 0.4)
    t.paint(tab, SYS["panel"][1], 0.95)
    t.line(tab, 1.0, SYS["edge"], 0.7)
    slab(t, x0, y0, x1, y1)
    t.text(x0 + 9, y0 - 16, SMALL, HEAD, SYS["soft"])
    x = x0 + 8
    for k, key in enumerate(keys):
        g = GAINS[key]
        if k:
            t.stroke([(x - 3, y0 + 12), (x - 3, y1 - 12)], 1.0, SYS["facet"], 0.25)
        picture(t, key, x + 13, y0 + 32, 26)
        t.text(x + 32, y0 + 13, TITLE, g["gain"], SYS["text"], bold=0.35)
        t.text(x + 32, y0 + 35, SMALL, g["what"], SYS["soft"])
        x += cells[k] + 6
    press(t, x1 - 86, y0 + 10, x1 - 8, y1 - 10, word_of(keys))


def board(t, keys):
    """C: a slab in the middle, in the Power screen's rows: a machine a row, its gauge showing what came."""
    tall = 8 + 26 + len(keys) * 38 + 4 + 44 + 8
    x0, x1 = 160, 450
    y0 = max(62, 186 - tall / 2)
    y1 = y0 + tall
    slab(t, x0, y0, x1, y1)
    t.text(x0 + 14, y0 + 10, TITLE, HEAD, SYS["text"], bold=0.3)
    y = y0 + 34
    for key in keys:
        g = GAINS[key]
        t.paint(t.poly(ui.cut_box(x0 + 8, y, x1 - 8, y + 34, 4, 1, 4, 1)), SYS["row"], 0.55)
        picture(t, key, x0 + 27, y + 17, 24)
        t.text(x0 + 46, y + 4, SMALL, g["name"], SYS["text"])
        gauge(t, key, x0 + 46, y + 23, 130)
        t.text(x1 - 16, y + 2, TITLE, g["gain"], SYS["text"], "RIGHT", bold=0.35)
        t.text(x1 - 16, y + 19, SMALL, g["what"], SYS["soft"], "RIGHT")
        y += 38
    t.text(x0 + 14, y1 - 36, SMALL, "Away " + AWAY, SYS["faint"])
    press(t, x1 - 110, y1 - 52, x1 - 8, y1 - 8, word_of(keys))


CARDS = {"A": slip, "B": sill, "C": board}


# --- the HUD round them: stand-ins ---------------------------------------------------------------------------------------

def ghost(t, x0, y0, x1, y1, *words):
    d = up.box(t, x0, y0, x1, y1, "#0B0D14", None, 1.0, 5)
    t.line(d, 1.0, "#5A6070", 0.8)
    for k, w in enumerate(words):
        t.text((x0 + x1) / 2, (y0 + y1) / 2 - len(words) * 8 + k * 16 + 1, SMALL, w, "#8A90A0", "CENTER")


def pill(t, x0, y0, x1, y1, colour, words, key=None, lit=False):
    """A pill of the HUD's column: its block in its system's colour, its reading."""
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 5, 2, 5, 2))
    t.glow(d, 5.0, colour if lit else "#04090B", 0.4)
    t.paint(d, t.ramp("#1A222C", "#0D1218", (t.y - y0) / (y1 - y0)), 0.94)
    t.line(d, 1.2, colour, 0.95)
    block = np.maximum(d, t.x - (x0 + y1 - y0))
    t.paint(block, colour, 0.9)
    if key:
        picture(t, key, x0 + (y1 - y0) / 2, (y0 + y1) / 2, (y1 - y0) - 6)
    t.text(x1 - 7, (y0 + y1) / 2 - SMALL * 0.42, SMALL, words, "#FFFFFF", "RIGHT", bold=0.3)


def pills(t, stored, under=False):
    """Credits and Electricity. `under`: the board stands over Electricity's left, so the sheet leaves its words out
    (a sheet's words are laid last, over every piece)."""
    pill(t, 455, 72, 560, 97, CREDITS, "46,310")
    pill(t, 392, 103, 560, 128, POWER, stored if under else "2.4 kW      " + stored)


def lead(t):
    ghost(t, 8, 77, 155, 150, "the lead's card")


def step(t):
    ghost(t, 162, 222, 405, 247, "the next step's plate")


def dock(t):
    for k in range(3):
        ghost(t, 203 + k * 56, 262, 253 + k * 56, 304)


def home(t, way, keys):
    """The yard as the player comes back to it (TR51's capture), the HUD's pieces as stand-ins, and the card."""
    if "yard" not in _px:
        px = rs.load(YARD)
        _px["yard"] = rs.shrink(px, W * ui.K / px.shape[1])
    t.px[..., :3], t.px[..., 3] = ui.c("#9DB0BA"), 1.0
    t.image(_px["yard"], 0, 0)
    sm.stand_in(t)
    lead(t)
    pills(t, "19.0 kWh", under=way == "C" and len(keys) > 2)
    if way == "A":                                       # the slip leaves the dock where it is; the other two take its place
        dock(t)
    if way == "C":                                       # the board stands over the pills' column: the HUD recedes under it
        t.paint(np.full_like(t.x, -1.0), "#06090C", 0.45)
    CARDS[way](t, keys)


# --- during a run, in the Festival --------------------------------------------------------------------------------------

LINE = (163, 448, 62)       # the run's line as the game lays it on this phone (build/captures/tr50/line.png)


def run_line(t):
    acc = sm.ACC[False]
    x0, x1, y0 = LINE
    sm.glass(t, x0, y0, x1, y0 + 40, False, 6, 1.2)
    sm.badge(t, x0 + 7, y0 + 7, 2, False, True)
    tx = x0 + 41
    t.text(tx, y0 + 5, TITLE, "Stretch 2 of 4", P["text"], bold=0.3)
    t.text(x1 - 10, y0 + 7, SMALL, "5 / 10", P["soft"], "RIGHT")
    ry, ex = y0 + 31, x1 - 16
    d = t.poly(ui.cut_box(tx, ry - 3, ex - 6, ry + 3, 2, 2, 2, 2))
    t.paint(d, P["channel"])
    t.line(d, 1.0, P["edge"], 0.9)
    sm.fill(t, tx + 1, tx + (ex - 6 - tx) * 0.5, ry, 1.6, acc, ex - 6)
    disc = t.poly([(ex + 6.5 * np.cos(a), ry + 6.5 * np.sin(a)) for a in np.linspace(0, 2 * np.pi, 24, endpoint=False)])
    t.paint(disc, P["channel"])
    t.line(disc, 1.2, P["edge"])


def two_lines(t, x, y, colour=SYS["text"], soft=SYS["soft"]):
    t.text(x, y, SMALL, NOTICE[0], colour, bold=0.3)
    t.text(x, y + 18, SMALL, NOTICE[1], soft)


def festival(t, way, broke):
    """The run's HUD on a stand-in street: the base's state beside the run's line, then the notice as the shard breaks."""
    ui.world(t, "noon")
    sm.stand_in(t)
    lead(t)
    pills(t, "31.4 kWh")
    dock(t)
    if way != "C":
        step(t)
    x0, x1, y0 = LINE
    if way == "A":                                       # a third pill under Electricity; the toasts step down under it
        run_line(t)
        pill(t, 482, 134, 560, 157, SILVER, "Ready" if broke else LEFT, "shard", lit=broke)
        if broke:
            slab(t, 318, 164, 560, 210, 6)
            picture(t, "shard", 338, 187, 28)
            two_lines(t, 358, 171)
    elif way == "B":                                     # a tab hung from the line beside the dare's; it opens into the notice
        sm.glass(t, x0 + 8, y0 + 30, x0 + 34, y0 + 64, False, 4, 1.0)      # the dare's tab (AR53), its neighbour
        if broke:                                        # clear of the Electricity pill, 5 under the line's right end
            sm.glass(t, x0 + 40, y0 + 30, 386, y0 + 88, False, 6, 1.2)
            run_line(t)
            picture(t, "shard", x0 + 54, y0 + 65, 24)
            two_lines(t, x0 + 68, y0 + 48, P["text"], P["soft"])
        else:
            sm.glass(t, x0 + 40, y0 + 30, x0 + 112, y0 + 64, False, 4, 1.0)
            run_line(t)
            picture(t, "shard", x0 + 54, y0 + 52, 16)
            t.text(x0 + 104, y0 + 46, SMALL, LEFT, P["soft"], "RIGHT")
    else:                                                # the next step's plate speaks for the base, in its teal; it grows
        run_line(t)
        if broke:
            slab(t, 162, 201, 405, 247, 6)
            picture(t, "shard", 182, 224, 28)
            two_lines(t, 202, 208)
        else:
            slab(t, 162, 222, 405, 247, 5)
            picture(t, "shard", 177, 234.5, 16)
            t.text(190, 228, SMALL, "Shard breaking", SYS["soft"])
            t.text(397, 228, SMALL, LEFT, SYS["text"], "RIGHT", bold=0.3)


# --- the sheets ---------------------------------------------------------------------------------------------------------

CELLS = [
    ("One change: the battery alone", dict(keys=("battery",))),
    ("All four, a shard among them: the press is Reveal", dict(keys=ALL)),
    ("A shard alone", dict(keys=("shard",))),
    ("During a run: the shard breaking at home, its time left", dict(broke=False)),
    ("The shard breaks: the notice, never over the fight's middle", dict(broke=True)),
]
NAMES = {
    "A": "A, the Slip",
    "B": "B, the Sill",
    "C": "C, the Board",
}
NOTES = {
    "A": [
        "A, the Slip. A narrow slab rises on the right, under the pills: a line a change,",
        "the gain large, the press across its foot under the right thumb. It grows up",
        "from the foot with each change; the dock and the pills stay. With all four it",
        "stands in the toasts' place for as long as it's up. During a run the base is a",
        "third pill under Electricity, the Breaker's silver: the toasts step down under",
        "it. The notice is a toast, two lines tall (the sentence is 44 letters; the",
        "kit's toast holds one line).",
        "In all three the next step's plate waits while the card is up.",
        "Stand-ins: the words but Collect, Reveal and the notice; the HUD's grey boxes.",
    ],
    "B": [
        "B, the Sill. A low slab across the foot, grown from the right as far as its",
        "changes reach, its head a tab on its top: a cell a change, the press at its",
        "right end. The yard stays whole above it; the dock steps down while it's up.",
        "With all four it's the screen's width: 553 of 568 by the sheet's letters.",
        "During a run the base is a tab hung from the run's line beside the dare's tab,",
        "and the notice opens out of that tab, clear of the Electricity pill (it sits",
        "5 under the line's right end).",
        "In all three the next step's plate waits while the card is up.",
        "Stand-ins: the words but Collect, Reveal and the notice; the HUD's grey boxes.",
    ],
    "C": [
        "C, the Board. A slab in the middle in the Power screen's rows: a machine a row,",
        "its name, and a gauge of what came (the battery's bar with the gain lit, the",
        "tray's cups, the levels' steps), the gain at the right, the press at the foot's",
        "right. The most said, and the most covered: with four rows it stands over",
        "the Electricity pill, so the HUD recedes under it, as under Home.",
        "During a run the next step's plate speaks for the base, in the slab's teal",
        "(no new piece on the HUD), and the notice is that plate, grown to two lines.",
        "In all three the next step's plate waits while the card is up.",
        "Stand-ins: the words but Collect, Reveal and the notice; the HUD's grey boxes.",
    ],
}


def main():
    out = bl.out_dir()
    rs.OUT = out
    groups = []
    for way in "ABC":
        def cell(sheet, ox, oy, st, way=way):
            t = sheet.tile(ox, oy, W, H)
            if "keys" in st:
                home(t, way, st["keys"])
            else:
                festival(t, way, st["broke"])
        shots = ss.sheet_of(out, f"return_card_{way}.png",
                            f"AR55, the return card, {NAMES[way]}: a blockout at the smallest phone (568 x 320 points)", CELLS, H,
                            NOTES[way], cell)
        groups.append([rs.shrink(shot, 64 / (H * 2)) for shot in shots])
        del shots
        gc.collect()
    gap = 12
    sw = groups[0][0].shape[1]
    page = rs.canvas(gap + len(CELLS) * (sw + gap), gap + 3 * (64 + gap), tuple(rs.rgb("#101117")))
    for r, shots in enumerate(groups):
        for k, shot in enumerate(shots):
            rs.paste(page, shot, gap + k * (sw + gap), gap + r * (64 + gap))
    rs.save(page, out / "return_card_small.png")


if __name__ == "__main__":
    main()
