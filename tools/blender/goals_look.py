"""AR53, the goals' look, basic at launch (Modulo, 2026-11-23): the sheets, and the cut for TR54.

Two layers (docs/design.md, "Goals"; docs/test-requests.md, TR54), each in the make of the screen it joins. The Mask
Ledger is cut (the director, 2026-11-23, by 18:38; docs/decisions.md): nothing here wears Lantern Row's festival.
    the dare        on the run's line under Roblox's top bar (stage_seam.py's line, as StageController builds it) and on
                    the run's card, in Seam's lit glass. The game has no start card: a run is four stretches under one
                    line, so a stretch's dare unfolds under that line as the stretch starts, then folds to its mark in
                    a tab of the line's glass. The mark is a hard four-point shape in the kit's ivory: lit while the
                    dare holds, dark and split once it's broken, and on the card it sits on the road after each stretch
                    whose dare was kept. "Dare kept" carries the forge stone in the kit's item cell, as the Forge draws
                    it. A dare kept before a fall is paid, so the fall's card shows its marks and its chip too.
    today's three   on Home's panel (home_cards.py, AR49's glass and leaning cards): a Today card in Settings' column
                    with Settings a cog tile over it (research's pick, B). It opens the list in the glass: Next, the
                    account's one next step and what it opens, pinned at its head; under it a leaning row a goal, its
                    shard at the right, scrolling.

Measured in points at the smallest phone (568 x 320), two pixels a point. Every new piece of art is drawn once as an
image at 4 pixels a point (cut_pieces), and the sheets are laid from those images as the game lays them. The words are
TR54's; widths are the sheet's face, not the game's.

    blender -b --factory-startup --python tools/blender/goals_look.py -- <abs out>
    blender -b --factory-startup --python tools/blender/goals_look.py -- <abs build/handoff/UI/goals> cut
    blender -b --factory-startup --python tools/blender/goals_look.py -- <abs build/handoff/UI/goals> line
                                        (the dare's line alone: its sheet and goals.json, no image touched)

Writes:
    goals_dare_line.png     the run's line: a stretch's start, the mark lit, dark and kept, Hard, the keeper
    goals_dare_card.png     the run's card: dares kept, the first clear, none kept, a fall with one kept, a fall
    goals_today.png         Home: the Today card waiting and at rest, then the list under each of Next's six lines
    goals_small.png         every phone at 64 pixels high
    goals_pictures.png      for the content check: the mark's three states large, then the drawn pieces at twice the
                            phone's pixels
    goals_new.png           for the content check: the mark's and Next's files on the page's dark and on white
With `cut`, in place of the last three:
    images/*.png            the cut: the mark, the Today card and the cog tile, the pips, Next's plates, the rows
    goals.json              where each lies, and what the game's kit builds beside it
    goals_cut.png           every image over the page's dark
"""

import gc
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402
import upgrade_pages as up  # noqa: E402
import seam_kit as sk  # noqa: E402
import stage_screen as ss  # noqa: E402
import stage_seam as sm  # noqa: E402
import foe_cards as fc  # noqa: E402
import home_panel as hp  # noqa: E402
import home_cards as hc  # noqa: E402

W, H = ss.W, ss.H
P = sm.P
SMALL, TITLE, BIG = ss.SMALL, ss.TITLE, ss.BIG
PAPER, PAPER_SHADE, PRESSED = ss.PAPER, ss.PAPER_SHADE, ss.PRESSED
GLOW = "#FFF6E2"                       # the mark's light: a warm white, never a type's colour
UNLIT = "#120F22"                      # a broken dare's mark: dark, in a thin rim
READY = sm.READY
IVORY = hc.IVORY
STONE = up.UPG / "StoneLow.png"
SHARD = ss.ICONS["shards"]
LINE_H = 166
SPOTS = {}                             # a few drawn boxes, in a phone's points, for the pictures sheet
CUT_K = 4                              # the cut's pixels a point, the kit's
PIECES = {}                            # the cut's images by name: px, box (its own points), tint, use
HANDOFF = up.REPO / "build" / "handoff" / "UI" / "goals"


def piece(name, box, draw, tint=None, use=""):
    """One image of the cut, drawn alone at 4 pixels a point on transparency. `box` is in the piece's own points, from
    its own origin (the mark's middle, a row's top left, Home's glass's top left). Its last 3 points fade to nothing, so a
    glow's tail never meets the image's edge."""
    keep = ui.K
    px = hc.cut_piece(box, draw)
    ui.K = keep
    h, w = px.shape[:2]
    gy, gx = np.mgrid[0:h, 0:w]
    px[..., 3] *= np.clip(np.minimum(np.minimum(gx, w - 1 - gx), np.minimum(gy, h - 1 - gy)) / (3.0 * CUT_K), 0, 1)
    PIECES[name] = dict(px=px, box=box, tint=tint, use=use)


def lay(t, name, x, y, scale=1.0, tint=None, alpha=1.0):
    """A cut image on a tile, its own origin at (x, y): as the game lays it."""
    p = PIECES[name]
    f = ui.K / CUT_K * scale
    im = (rs.shrink(p["px"], f) if f < 1 else p["px"]).copy()
    if tint:
        im[..., :3] *= ui.c(tint)
    im[..., 3] *= alpha
    t.image(im, x + p["box"][0] * scale, y + p["box"][1] * scale)


def bounds(pts, pad):
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return (math.floor(min(xs) - pad), math.floor(min(ys) - pad), math.ceil(max(xs) + pad), math.ceil(max(ys) + pad))


def circle(t, cx, cy, r):
    return np.hypot(t.x - cx, t.y - cy) - r


# --- the dare's mark ------------------------------------------------------------------------------------------------

def star(x, y, s):
    """The mark's outline: four hard points, taller than wide, `s` tall, its middle at (x, y)."""
    a, b, q = s / 2, s * 0.4, s * 0.15
    return [(x, y - a), (x + q, y - q), (x + b, y), (x + q, y + q), (x, y + a), (x - q, y + q), (x - b, y), (x - q, y - q)]


def dare_mark(t, x, y, s, state="lit"):
    """The dare's mark: a hard four-point shape in the kit's ivory, in a dark socket's rim so it reads on a lit road.
    Lit while the dare holds; "kept", its flare; "dark", once the dare is broken: dark in a thin rim, split across,
    its lower half dropped."""
    if state == "dark":
        nx, ny, gap = 0.37, 0.93, s * 0.05
        side = (t.x - x) * nx + (t.y - y) * ny
        dx, dy = s * 0.07, s * 0.06
        low = (t.x - x - dx) * nx + (t.y - y - dy) * ny
        halves = (np.maximum(t.poly(star(x, y, s)), side + gap), np.maximum(t.poly(star(x + dx, y + dy, s)), gap - low))
        for d in halves:
            t.paint(d - s * 0.06, P["channel"], 0.9)
        for d in halves:
            t.paint(d, UNLIT)
            t.paint(np.abs(d) - 0.45, P["faint"], 0.9)
        return
    d = t.poly(star(x, y, s))
    t.glow(d, s * (0.45 if state == "kept" else 0.22), GLOW, 0.6 if state == "kept" else 0.25)
    t.paint(d - s * 0.06, P["channel"], 0.9)
    t.paint(d, t.ramp(PAPER, PRESSED, (t.y - y + s / 2) / s))
    t.line(d, 0.8, PAPER_SHADE)


MARK_H = 16.0                          # the mark's image: this tall, its middle the origin
MARKS = {"lit": "DareMark", "kept": "DareMarkKept", "dark": "DareMarkDark"}


# --- the dare on the run's line -------------------------------------------------------------------------------------

DARE_RIGHT = 263.0                     # the opened dare's right, from the line's left, at the smallest phone: 6 short of
                                       # the Electricity pill (392 of 568 on screen, the line's left at 163, drawn at 0.85)


def face_wide(words, size):
    """How wide the sheet's face sets a line, in points (Blender's face stands in for the game's)."""
    import bpy
    curve = bpy.data.curves.new("Measure", "FONT")
    curve.body, curve.size = words, size
    obj = bpy.data.objects.new("Measure", curve)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    wide = float(obj.dimensions.x)
    bpy.data.objects.remove(obj)
    bpy.data.curves.remove(curve)
    return wide


def broken(words, room, size=14.0):
    """A dare's rows: one when it fits `room`, else two, broken at the word that leaves the rows most alike."""
    if face_wide(words, size) <= room:
        return [words]
    parts = words.split(" ")
    rows = min(([" ".join(parts[:k]), " ".join(parts[k:])] for k in range(1, len(parts))),
               key=lambda r: max(face_wide(r[0], size), face_wide(r[1], size)))
    assert max(face_wide(r, size) for r in rows) <= room, (words, room)
    return rows


def run_line(t, st):
    """The run's line as StageController builds it (the stretch's mark, "Stretch 2 of 4", its Shades on their road),
    with the dare: unfolded under it as the stretch starts, then its mark in a tab under the line's foot."""
    hard, quota, kills, last = st["hard"], st["quota"], st["kills"], st["last"]
    acc = sm.ACC[hard]
    x0, x1, y0 = 100, 468, ss.BAND + 4
    said = st.get("dare")
    y1 = y0 + 44
    tx = x0 + 8 + 26 + (24 if hard else 0) + 10
    rows = broken(said, DARE_RIGHT - 8 - (tx - x0)) if said else []
    if said:                                             # unfolded: the dare's tab opened to the right, never the line grown
        right = min(DARE_RIGHT, tx - x0 + max(face_wide(r, SMALL) for r in rows) + 10)
        sm.glass(t, x0 + 8, y0 + 30, x0 + right, y0 + (70 if len(rows) == 1 else 88), hard, 4 if len(rows) == 1 else 6, 1.0)
        print(f"dare {'Hard ' if hard else ''}{said!r}: {face_wide(said, SMALL):.0f} wide in {DARE_RIGHT - 8 - (tx - x0):.0f}, "
              f"{len(rows)} row(s), the panel's right {right:.0f}")
    if st.get("mark"):                                   # folded: a tab of the line's own glass under the stretch's mark
        sm.glass(t, x0 + 8, y0 + 30, x0 + 34, y0 + 70, hard, 4, 1.0)
    sm.glass(t, x0, y0, x1, y1, hard, 6, 1.2)
    if st.get("mark"):
        lay(t, MARKS[st["mark"]], x0 + 21, y0 + 57)
        SPOTS.setdefault("tab", (x0 - 6, y0 - 4, x0 + 150, y0 + 78))
    sm.badge(t, x0 + 8, y0 + 9, st["stage"], hard, True)
    name = f"Stretch {st['stage']} of 4"
    t.text(tx, y0 + 6, TITLE, name, P["text"], bold=0.3)
    if quota:
        t.text(tx + ss.wide_of(name, TITLE) + 6, y0 + 8, SMALL, f"{kills} / {quota} Shades", P["text"])
    t.text(x1 - 10, y0 + 8, SMALL, st["right"], P["soft"], "RIGHT")
    rx0, rx1, ry, ex = tx, x1 - 30, y0 + 34, x1 - 16
    risen = quota == 0 or kills >= quota
    d = t.poly(ui.cut_box(rx0, ry - 3, ex - 6, ry + 3, 2, 2, 2, 2))
    t.paint(d, P["channel"])
    t.line(d, 1.0, P["edge"], 0.9)
    for i in range(1, quota):
        x = rx0 + i * (rx1 - rx0) / quota
        t.stroke([(x, ry - 2.5), (x, ry + 2.5)], 1.0, P["edge"])
    lit = ex - 6 if risen else rx0 + kills / quota * (rx1 - rx0)
    if lit > rx0 + 1:
        sm.fill(t, rx0 + 1, lit, ry, 1.6, acc, ex - 6)
    if last:
        t.glow(circle(t, ex, ry, 7.5), 5.0, acc["glow"], 0.45)
        ss.check(t, ex, ry, 7.5)
    else:
        disc = circle(t, ex, ry, 6.5)
        t.paint(disc, P["channel"])
        t.line(disc, 1.2, P["edge"])
    if said:
        lay(t, "DareMark", x0 + 21, y0 + 57)
        for k, row in enumerate(rows):
            t.text(tx, y0 + (51 if len(rows) == 1 else 48 + 18 * k), SMALL, row, P["text"])
        SPOTS.setdefault("line", (x0 - 6, y0 - 4, x1 + 6, y0 + 96))


def line_cell(sheet, ox, oy, st):
    t = sheet.tile(ox, oy, W, LINE_H)
    ui.world(t, "noon")
    sm.stand_in(t)
    run_line(t, st)


DARES = ["Finish with your lead above half.", "Break a raised shield with your signature.",
         "Let no Dasher's line touch you.", "Stand outside every slam."]
FALLBACK = "Finish without your lead falling."        # a stretch's dare until its own piece is in (TR54)
LINES = [
    ("Stretch 2 starts: its dare's tab opens under the line, for about 3 s. A long dare breaks at a word",
     dict(hard=False, stage=2, quota=10, kills=0, last=False, right="then the elite", dare=DARES[1])),
    ("Then it folds to its mark, lit while the dare holds",
     dict(hard=False, stage=2, quota=10, kills=5, last=False, right="then the elite", mark="lit")),
    ("The dare broken: the mark goes dark and splits, and nothing is said",
     dict(hard=False, stage=3, quota=10, kills=4, last=False, right="then the elite", mark="dark")),
    ("The stretch cleared, its dare kept: the mark flares once",
     dict(hard=False, stage=2, quota=10, kills=10, last=True, right="cleared", mark="kept")),
    ("Hard, Stretch 1 starts: the same tab in the ember's edge; Hard's wider mark leaves less room",
     dict(hard=True, stage=1, quota=10, kills=0, last=False, right="then the elite", dare=DARES[0])),
    ("Stretch 4, the keeper's: a short dare stays on one row, in the tab's own height",
     dict(hard=False, stage=4, quota=0, kills=0, last=False, right="the Lamplighter", dare=DARES[3])),
]
LINE_NOTES = [
    "The game has no start card: a run is four stretches under one line. So a stretch's dare hangs under that line in a",
    "tab of the line's own glass, under the stretch's mark. As the stretch starts the tab is open to the right with the",
    "dare's words, and after about 3 s it closes round its mark, which never moves. The line itself never grows: an open",
    "dare lies over no other piece of the HUD. Its right stops 6 short of the Electricity pill (263 from the line's left",
    "at the smallest phone), and a dare too long for that breaks at a word into two rows, in the height of the base's",
    "notice (AR55). The mark is a hard four-point shape in the kit's ivory, the dare's mark everywhere: lit while the",
    "dare holds, dark and split once it's broken (no words, no sound), a flare when the stretch is cleared with it kept.",
    "Stand-ins: the words at the line's right, the street, Roblox's buttons.",
]


# --- the dare on the run's card -------------------------------------------------------------------------------------

KEPT_W = ss.wide_of("Dare kept", SMALL) * 0.9


CELL = 26.0                            # the chip's stone: the kit's Common item cell, the size Reinforce draws it


def dare_wide(n):
    return 19 + KEPT_W + 6 + CELL + 4 + ss.wide_of(f"+{n}", TITLE) + 7


def dare_chip(t, x, y, n):
    """"Dare kept" on the time's row: the mark, the words, and the forge stone the kept dares paid, with how many. The
    stone is the Forge's own (research's must-fix 1): its picture in the kit's Common item cell with the cell's
    hairline, as Reinforce draws it under its ring, standing 2 points over the chip's top and foot."""
    wide = dare_wide(n)
    d = t.poly(ui.cut_box(x, y, x + wide, y + 22, 4, 4, 4, 4))
    t.glow(d, 5.0, GLOW, 0.22)
    t.paint(d, up.shade(t, sk.SOCKET_DARK, y, y + 22))
    t.line(d, 1.2, PAPER_SHADE)
    lay(t, "DareMarkKept", x + 10, y + 11, 13 / MARK_H)
    t.text(x + 19, y + 4, SMALL, "Dare kept", PAPER, bold=0.3)
    sx = x + 19 + KEPT_W + 6
    stone = up.cell(t, sx, y - 2, CELL, "Common", STONE)
    t.line(stone, 1.0, up.P["edge"])
    t.text(sx + CELL + 4, y + 3, TITLE, f"+{n}", P["text"], bold=0.3)
    SPOTS.setdefault("chip", (x - 8, y - 8, x + wide + 8, y + 30))


def card(t, st):
    """The run's card (StageScreen.Results, stage_seam.results) with the dares: the mark on the road after each
    stretch whose dare was kept, and "Dare kept" with its stone on the time's row. The fall's card has no time, so its
    chip takes a row of its own under the line that says where the next run starts. None kept, the card is today's."""
    hard, lost = st["hard"], st.get("lost", False)
    x0, x1 = 124, 444
    cx = (x0 + x1) / 2
    kept = st.get("dares", ())
    spans = [("marks", 30), ("title", 28), ("time", 22)]
    if lost and kept:                                    # a dare kept before the fall is paid: the fall's card says so
        spans.append(("dare", CELL))
    if st.get("gave"):
        spans.append(("gave", 28))
    if st.get("opened"):
        spans.append(("opened", 34))
    inner = sum(h for _, h in spans) + 8 * (len(spans) - 1)
    total = 12 + inner + 14 + ss.TAP + 10
    y0 = max(ss.BAND + 4, ss.BAND + (H - ss.BAND - total) / 2)
    y1 = y0 + total
    sm.glass(t, x0, y0, x1, y1, hard, 8, 1.4)
    y = y0 + 12
    for kind, h in spans:
        if kind == "marks":
            sm.marks(t, x0 + 16, x1 - 16, y + h / 2, st["marks"], hard)
            tab = 21 if hard else 0
            step = (x1 - x0 - 32 - 12 - 26 - tab) / 3
            for k in kept:
                lay(t, "DareMarkKept", x0 + 22 + (k - 1) * step + 26 + tab + 10, y + h / 2, 15 / MARK_H)
            SPOTS.setdefault("road", (x0 - 4, y0 - 4, x1 + 4, y + h + 8))
        elif kind == "title":
            t.text(cx, y + 2, BIG, st["title"], ss.HURT if lost else P["text"], "CENTER", bold=0.35)
        elif kind == "time" and lost:
            t.text(cx, y + 3, SMALL, st["said"], P["soft"], "CENTER")
        elif kind == "dare":
            dare_chip(t, cx - dare_wide(len(kept)) / 2, y + 2, len(kept))
        elif kind == "time":
            said = None if st.get("new_best") else f"{st['time']}   ·   best {st['best']}"
            parts = [("said", ss.wide_of(said, SMALL) * 0.9)] if said else [("clock", ss.wide_of(st["time"], TITLE)), ("best", 98)]
            if kept:
                parts.append(("dare", dare_wide(len(kept))))
            st["row"] = sum(w for _, w in parts) + 8 * (len(parts) - 1)
            left = cx - st["row"] / 2
            for what, wide in parts:
                if what == "said":
                    t.text(left, y + 4, SMALL, said, P["soft"])
                elif what == "clock":
                    t.text(left, y + 2, TITLE, st["time"], P["text"], bold=0.3)
                elif what == "best":
                    up.box(t, left, y, left + wide, y + 22, sk.SOCKET_DARK, READY, 1.2, 4)
                    t.text(left + wide / 2, y + 4, SMALL, "a new best", READY, "CENTER", bold=0.3)
                else:
                    dare_chip(t, left, y, len(kept))
                left += wide + 8
        elif kind == "gave":
            chips = [(what, words, ss.MINT if what == "credits" else P["text"]) for what, words in st["gave"]]
            widths = [38 + ss.wide_of(words, TITLE) + 8 for _, words, _ in chips]
            left = cx - (sum(widths) + 6 * (len(chips) - 1)) / 2
            for (what, words, colour), cw in zip(chips, widths):
                up.box(t, left, y, left + cw, y + h, P["well"], P["edge"], 1.0, 4)
                ss.icon(t, what, left + 5, y + 3, 22)
                t.text(left + 33, y + 6, TITLE, words, colour, bold=0.3)
                left += cw + 6
        elif kind == "opened":
            band = t.poly(ui.cut_box(x0 + 16, y, x1 - 16, y + h, 5, 5, 5, 5))
            t.glow(band, 6.0, sm.ACC[True]["glow"], 0.3)
            t.paint(band, up.shade(t, sk.SOCKET_DARK, y, y + h))
            t.paint(band, sm.ACC[True]["bloom"], 0.35 * np.exp(-((t.x - cx) / 110) ** 2))
            t.line(band, 1.4, sm.ACC[True]["edge"])
            t.text(cx, y + 6, BIG, "Hard is open", READY, "CENTER", bold=0.35)
            for side in (-1, 1):
                ss.chevrons(t, cx + side * (ss.wide_of("Hard is open", BIG) / 2 + 18), y + h / 2, 13, sm.ACC[True]["edge"])
        y += h + 8
    py = y1 - 10 - ss.TAP
    widths = [p[2] for p in st["presses"]]
    left = cx - (sum(widths) + 6 * (len(widths) - 1)) / 2
    for words, kind, wide, into_hard in st["presses"]:
        sm.press(t, left, py, left + wide, py + ss.TAP, words, kind, into_hard)
        left += wide + 6
    st["tall"] = total


def card_cell(sheet, ox, oy, st):
    t = sheet.tile(ox, oy, W, H)
    ui.world(t, "noon")
    t.paint(np.full_like(t.x, -1.0), P["channel"], 0.5)
    sm.stand_in(t)
    card(t, st)


WON = ["cleared", "cleared", "cleared", "just"]
CARDS = [
    ("Lantern Row cleared, three dares kept, a new best",
     dict(hard=False, marks=WON, title="Lantern Row cleared", time="12:40", new_best=True, dares=(1, 2, 4),
          gave=[("credits", "+1,240"), ("shards", "+3"), ("keeper_chest", "+1")],
          presses=[("Retry", "quiet", 100, False), ("Home", "one", 150, False)])),
    ("The first clear, one dare kept: the tallest card (Hard opens)",
     dict(hard=False, marks=WON, title="Lantern Row cleared", time="14:55", new_best=True, dares=(1,),
          gave=[("credits", "+1,240"), ("shards", "+3"), ("keeper_chest", "+1")], opened="Hard",
          presses=[("Retry", "quiet", 100, False), ("Home", "one", 150, False)])),
    ("Hard, no dare kept: the card as it is today, nothing said",
     dict(hard=True, marks=WON, title="Lantern Row cleared", time="16:02", best="15:10", dares=(),
          gave=[("credits", "+2,480"), ("shards", "+4")],
          presses=[("Retry", "quiet", 100, False), ("Home", "one", 150, False)])),
    ("A fall in Stretch 3, one dare kept before it: it's paid, so the card says so",
     dict(hard=False, lost=True, marks=["cleared", "cleared", "next", "shut"], title="Your lead fell", dares=(2,),
          said="Your next run starts at Stretch 3 of 4",
          presses=[("Retry", "one", 170, False), ("Home", "quiet", 124, False)])),
    ("A fall, no dare kept: the card as it is today",
     dict(hard=False, lost=True, marks=["cleared", "cleared", "next", "shut"], title="Your lead fell",
          said="Your next run starts at Stretch 3 of 4",
          presses=[("Retry", "one", 170, False), ("Home", "quiet", 124, False)])),
]
CARD_NOTES = [
    "The run's card, as built, with the dares. The dare's mark sits on the road",
    "after each stretch whose dare was kept, so the road says which. \"Dare kept\"",
    "sits on the time's row in a warm ivory edge, with the forge stone those",
    "dares paid: the Forge's own stone, in the kit's item cell as Reinforce draws",
    "it, and how many. No new row on a win: the first clear's card already stands",
    "254 of the 262 points under Roblox's bar. A dare kept before a fall is paid",
    "(research, 17:49), so the fall's card shows its marks too and gives the chip",
    "a row of its own. None kept, nothing is said and the card is today's.",
    "Stand-ins: the times, what the run gave, the presses, the street.",
]


# --- today's three, on Home's panel ---------------------------------------------------------------------------------

HOME = {}
ROW_H, ROW_GAP, LIST_PAD = 44.0, 2.0, 3.0   # the list's inset from the glass's top and foot
ROW_X = (10.0, 352.0)                  # a row's foot, in the glass's points
ROW_W = ROW_X[1] - ROW_X[0]
COG = (hc.TOP, hc.TOP + 44.0)          # Settings' cog tile: its top and foot, in the glass's points
TODAY_Y = (hc.TOP + 50.0, hc.FOOT)     # the Today card's
PIPS = {"open": "GoalPipOpen", "done": "GoalPipDone", "claimed": "GoalPipClaimed"}
ROWS = {"open": "GoalRow", "done": "GoalRowDone", "claimed": "GoalRowClaimed"}
LIST_FOOT = hc.PANEL[1] - LIST_PAD     # the rows' foot: 3 + 40 + 2 + 3 x 44 + 2 x 2 + 3 = 184, the glass
NEXT_H = 40.0                          # Next's plate, the list's head (research's 46 less 6: the list keeps 3 clear of
                                       # the glass's rim at its top and its foot)
NEXT_X, NEXT_Y, NEXT_ONE = 50.0, (6.0, 23.0), 15.0     # its words' left; its two lines' capitals' tops; a line alone
NEXT_MOST = 45                         # letters in what Next opens (TR54): 272 of the 280 the row holds in the sheet's face
BACK = [(29.0, 14.0), (23.0, 20.0), (29.0, 26.0)]      # the back press's chevron, from the plate's top and foot's left
BACK_END = 40.0                        # where the back press ends: a hairline in the plate
NEXT_BLUE = "#AFC6F0"                  # Next's bar and its label: the Today card's pale light
NEXTS = [                              # TR54's Next lines: the step, then what it opens
    ("Bring down the Lamplighter.", "Hard opens on Lantern Row."),
    ("Raise the base to level 2.", "A third bay opens, and the Condenser wakes."),
    ("Bring down the Lamplighter on Hard.", "Its first chest holds a Rare or better."),
    ("Raise the base to level 3.", "A fourth bay opens. Machines reach level 30."),
    ("Climb the Tower to floor 25.", "Each new floor pays a first-time bonus."),
    ("Drum Court's gate stays shut, for now.",),
]


def home_made():
    if not HOME:
        images = hc.HANDOFF / "images"
        made = dict(pieces=hc.pieces(None), px={}, cog=rs.load(hc.UI / "home" / "images" / "HomeMarkSettings.png"))
        for name, *_ in made["pieces"]:
            made["px"][name] = rs.load(images / f"{name}.png")
        HOME.update(made=made, lead=rs.load(up.REPO / "build" / "scratch" / "modulo" / "home_cards" / hc.LEAD_PNG),
                    world=hp.worlds()["small"])
    return HOME


def home_phone(mode):
    """The smallest phone with Home open, laid from AR49's cut as home_cards.built lays it. "card": the cards, with
    Settings' card and its word left out for the Today card and the cog tile; "list": the glass alone."""
    made, world = home_made()["made"], HOME["world"]
    w, h = hp.size_of(world)
    px0, py0 = hc.panel_at(w, h, "small")
    out = hp.dimmed(world, "B", hc.DIM)
    light = hc.light_of("Common")
    for name, box, _draw, tint, _use in made["pieces"]:
        if name.endswith("Press") or name == "HomeSettings" or (mode == "list" and name not in ("HomeGlass", "HomePointer")):
            continue
        x, y = px0 + box[0], py0 + box[1]
        if name == "HomePointer":
            x = w / 2 + box[0]
        fc.put(out, made["px"][name], x, y, tint=light if tint == "light" else tint)
        if name == "HomeVoidkinRimTop":
            ui.K = hc.SHEET_K
            vx, vy = hc.viewport_box()[:2]
            rs.paste(out, hc.stand_in(HOME["lead"], "Common"), round((px0 + vx) * 2), round((py0 + vy) * 2))
    items = [] if mode == "list" else [i for i in hc.text_items(px0, py0) if i["text"] != "Settings"]
    return out, px0, py0, items


def said(t, x, y, size, words, colour, align="LEFT", bold=0.3):
    """Home's words: the kit's face leaning with the cards, a soft dark under it."""
    t.text(x + 0.8, y + 1.2, size, words, "#000000", align, layer="a_shade", shear=hc.LEAN, bold=bold)
    t.text(x, y, size, words, colour, align, layer="plain", shear=hc.LEAN, bold=bold)


def leaned(xl, xr, y0, y1, cut=5.0):
    """A leaning plate in Home's make: its foot from xl to xr, leaning right as it rises, two corners cut."""
    lean = hc.LEAN * (y1 - y0)
    return [(xl + lean - cut * hc.LEAN, y0 + cut), (xl + lean + cut, y0), (xr + lean, y0), (xr + cut * hc.LEAN, y1 - cut),
            (xr - cut, y1), (xl, y1)]


def pip(t, cx, cy, state, r=4.2):
    """One of today's three: a small diamond. Open, a steel outline; done and waiting, lit gold; claimed, ivory."""
    d = (np.abs(t.x - cx) + np.abs(t.y - cy)) - r
    if state == "done":
        t.glow(d, 3.5, READY, 0.6)
        t.paint(d, READY)
    elif state == "claimed":
        t.paint(d, "#B9C0CC")
    else:
        t.paint(d, "#0B0E16")
        t.paint(np.abs(d) - 0.6, "#8F99A6")


def column(y0, y1, cut=5.0):
    """Settings' column between two heights, in the glass's points: the cards' lean, two corners cut."""
    fx0, fx1 = hc.CARDS["Settings"]
    return [(hc.at(fx0, y0 + cut), y0 + cut), (hc.at(fx0, y0) + cut, y0), (hc.at(fx1, y0), y0),
            (hc.at(fx1, y1 - cut), y1 - cut), (hc.at(fx1, y1) - cut, y1), (hc.at(fx0, y1), y1)]


def cog_tile(t):
    """Settings, a cog tile at the column's head (the cog itself is AR43's mark, laid over)."""
    mat = hc.MAT["Settings"]
    d = t.poly(column(*COG))
    t.glow(d, 5.0, "#000000", 0.4)
    t.paint(d, t.ramp(mat["body"][0], mat["body"][1], (t.y - COG[0]) / 60))
    t.line(d, 1.0, mat["rim"], 0.9)


def today_body(t):
    """The Today card: the column under the cog tile, a pale light where its shard sits."""
    y0, y1 = TODAY_Y
    d = t.poly(column(y0, y1))
    t.glow(d, 6.0, "#000000", 0.4)
    t.paint(d, t.ramp("#232B3D", "#06080D", (t.y - y0) / (y1 - y0)))
    mx = hc.middle("Settings", y0 + 38)
    t.paint(d, "#AFC6F0", 0.16 * np.exp(-(((t.x - mx) / 30) ** 2 + ((t.y - y0 - 36) / 30) ** 2)))
    t.line(d, 1.0, hc.MAT["Settings"]["rim"], 0.95)


def today_waits(t):
    """Over the Today card while a goal waits to be claimed: its glow and its rim in gold."""
    d = t.poly(column(*TODAY_Y))
    ui.over(t.px, ui.c(READY), 0.4 * np.exp(-(np.maximum(d, 0) / 6.0) ** 1.4) * hc.outside(d))
    t.line(d, 1.4, READY, 0.95)


def today_card(t, px0, py0, pips):
    """B, research's pick: Today in Settings' column, the shard its picture, today's three as pips; Settings a cog
    tile over it. Laid from the cut."""
    lay(t, "HomeCog", px0, py0)
    t.image(hc.image(HOME["made"]["cog"], 24, "#C9D0D9"), px0 + hc.middle("Settings", COG[0] + 22) - 12, py0 + COG[0] + 10)
    lay(t, "HomeToday", px0, py0)
    if "done" in pips:
        lay(t, "HomeTodayWaits", px0, py0)
    y0, y1 = TODAY_Y
    t.image(hc.image(SHARD, 40), px0 + hc.middle("Settings", y0 + 38) - 20, py0 + y0 + 14)
    for k, state in enumerate(pips):
        lay(t, PIPS[state], px0 + hc.middle("Settings", y0 + 72) - 13 + k * 13, py0 + y0 + 72)
    said(t, px0 + hc.middle("Settings", y1 - 9), py0 + y1 - 9 - SMALL * 0.72, SMALL, "Today", IVORY, "CENTER")


def row_plate(t, state):
    """A goal's row alone, its top at 0 and its foot's left corner at x 0. Open: steel glass. Done: the claim's press,
    lit gold, a warm light where its shard sits. Claimed: sunk."""
    d = t.poly(leaned(0, ROW_W, 0, ROW_H))
    sx = ROW_W - 40 + hc.LEAN * ROW_H / 2
    if state == "done":
        ui.over(t.px, ui.c(READY), 0.4 * np.exp(-(np.maximum(d, 0) / 6.0) ** 1.4) * hc.outside(d))
        t.paint(d, t.ramp("#3B3220", "#15110A", t.y / ROW_H))
        t.line(d, 1.4, READY, 0.95)
        t.paint(d, "#FFE9A8", 0.22 * np.exp(-(((t.x - sx - 16) / 26) ** 2 + ((t.y - 22) / 22) ** 2)))
    elif state == "claimed":
        t.paint(d, t.ramp("#12161F", "#07090E", t.y / ROW_H))
        t.line(d, 1.0, "#2E3749", 0.95)
    else:
        t.paint(d, t.ramp("#232B3D", "#0B0E16", t.y / ROW_H))
        t.line(d, 1.0, "#55607A", 0.9)
        t.paint(np.maximum(d, np.abs(t.y - 1.4) - 0.6), "#CFDBFF", 0.22)


def row_check(t):
    """A claimed goal's check, where its shard was."""
    t.paint(circle(t, 0, 0, 8), "#39414F")
    t.stroke([(-3.6, 0), (-0.8, 3), (4, -3)], 1.8, "#B9C0CC")


def goal_row(t, px0, y0, words, state, count=None, whole=True):
    """A goal: a leaning row in the glass, its words, and at its right its shard. Open, the shard waits dim; done, the
    row is the claim's press, lit gold; claimed, it sinks and takes a check. `whole` False: the list's foot cuts the
    row above its words, so they aren't drawn."""
    xl = px0 + ROW_X[0]
    lean = hc.LEAN * ROW_H
    sx = xl + ROW_W - 40 + lean / 2
    lay(t, ROWS[state], xl, y0)
    if whole:
        said(t, xl + lean / 2 + 14, y0 + 15, SMALL, words, "#7E879A" if state == "claimed" else IVORY)
    if state == "claimed":
        lay(t, "GoalCheck", sx + 16, y0 + 22)
        return
    t.image(hc.image(SHARD, 32, alpha=1.0 if state == "done" else 0.5), sx, y0 + 6)
    if not whole:
        return
    if state == "done":
        said(t, sx - 8, y0 + 15, SMALL, "Claim", READY, "RIGHT", bold=0.45)
    elif count:
        said(t, sx - 8, y0 + 15, SMALL, count, "#AEB7C2", "RIGHT")


def next_plate(t):
    """Next's plate alone, the list's head, its top at 0 and its foot's left corner at x 0. Never a press but for the
    back press at its left, which ends at a hairline: deeper than a row, its top hairline lit, a pale bar down its
    leaning left side."""
    h = NEXT_H
    d = t.poly(leaned(0, ROW_W, 0, h))
    t.paint(d, t.ramp("#1B2333", "#0A0D14", t.y / h))
    t.line(d, 1.0, "#55607A", 0.9)
    t.paint(np.maximum(d, np.abs(t.y - 1.4) - 0.6), "#CFDBFF", 0.3)
    t.paint(np.maximum(d, t.x - hc.LEAN * (h - t.y) - 3.5), NEXT_BLUE, 0.9)
    rule = np.maximum(np.abs(t.x - hc.LEAN * (h - t.y) - BACK_END) - 0.5, np.maximum(7 - t.y, t.y - (h - 7)))
    t.paint(rule, "#55607A", 0.8)


def today_list(t, px0, py0, st):
    """The list in the glass: Next at its head, a plate that holds the back press and the account's next step; under
    it the rows, today's three whole at rest. With a banked day they scroll between Next's foot and the glass's."""
    step, *opens = NEXTS[st["next"]]
    assert not opens or len(opens[0]) <= NEXT_MOST, opens
    xl, yn = px0 + ROW_X[0], py0 + LIST_PAD
    lay(t, "GoalNext", xl, yn)
    t.stroke([(xl + x, yn + y) for x, y in BACK], 1.8, IVORY)
    lines = [step] + opens
    for j, words in enumerate(lines):
        y = NEXT_Y[j] if len(lines) > 1 else NEXT_ONE
        x = xl + NEXT_X + hc.LEAN * (NEXT_H - 5 - y)
        if j == 0:
            said(t, x, yn + y, SMALL, "Next", NEXT_BLUE, bold=0.45)
            x += 38
        said(t, x, yn + y, SMALL, words, IVORY if j == 0 else "#AEB7C2")
    top, foot = yn + NEXT_H + ROW_GAP, py0 + LIST_FOOT
    k = t.px.shape[0] / t.h
    above = t.px[:round((yn + NEXT_H) * k)].copy()       # the scrolling frame: from Next's foot to the glass's
    below = t.px[round((py0 + hc.PANEL[1]) * k):].copy()
    y = top
    for row in st["rows"]:
        if y >= foot:
            break
        if isinstance(row, str):                         # an earlier day's heading
            if y + 20 <= foot:
                said(t, px0 + ROW_X[0] + 14, y + 4, SMALL, row, "#8F99A6")
            y += 22
            continue
        goal_row(t, px0, y, *row, whole=y + 31 <= foot)
        y += ROW_H + ROW_GAP
    t.px[:above.shape[0]] = above
    t.px[t.px.shape[0] - below.shape[0]:] = below
    a, b = st.get("thumb", (0.0, 1.0))                   # at rest today's three fill the frame: no thumb
    if b - a < 1:
        x = px0 + hc.PANEL[0] - 5
        t.stroke([(x, top + 2 + a * (foot - top - 4)), (x, top + 2 + b * (foot - top - 4))], 2.0, "#55607A")
    SPOTS.setdefault("rows", (px0 - 4, py0 - 4, px0 + hc.PANEL[0] + 4, py0 + hc.PANEL[1] + 4))


def today_cell(sheet, ox, oy, st):
    out, px0, py0, items = home_phone(st["mode"])
    rs.paste(sheet.px, out, round(ox * 2), round(oy * 2))
    sheet.items += [dict(i, x=i["x"] + ox, y=i["y"] + oy) for i in items]
    t = sheet.tile(ox, oy, W, H)
    if st["mode"] == "card":
        today_card(t, px0, py0, st["pips"])
    else:
        today_list(t, px0, py0, st)


TODAY = [
    ("The Today card, a goal waiting to be claimed: its rim and glow in gold",
     dict(mode="card", pips=("done", "open", "open"))),
    ("Nothing waiting: one claimed, two open",
     dict(mode="card", pips=("claimed", "open", "open"))),
    ("The list at rest: Next its head, with the back press; today's three whole, one its claim, one counting",
     dict(mode="list", next=0, rows=[("Keep a dare.", "done"), ("Break three shards.", "open", "1 / 3"),
                                     ("Lead a run with someone new.", "open")])),
    ("The longest Next (what it opens: 44 letters) over three open goals",
     dict(mode="list", next=3, rows=[("Let every bay run a full hour.", "open", "0:15 / 1:00"),
                                     ("Collect the Condenser's tray.", "open"),
                                     ("Lead a run with someone new.", "open")])),
    ("The longest step; a claim waiting at the list's foot",
     dict(mode="list", next=2, rows=[("Clear a stretch on Hard.", "open"), ("Train a Voidkin for an hour.", "open", "0:15 / 1:00"),
                                     ("Raise a Voidkin a level.", "done")])),
    ("All three claimed: the list rests until the day turns",
     dict(mode="list", next=1, rows=[("Keep a dare.", "claimed"), ("Break three shards.", "claimed"),
                                     ("Lead a run with someone new.", "claimed")])),
    ("Banked days, scrolled: the rows pass under Next, and the thumb shows",
     dict(mode="list", next=4, thumb=(0.3, 0.6), rows=["Yesterday", ("Win three Tower floors.", "done"),
                                                       ("Let every bay run a full hour.", "open", "0:42 / 1:00"),
                                                       "Two days ago"])),
    ("Everything done: Next's last line stands alone",
     dict(mode="list", next=5, rows=[("Bring down the Lamplighter.", "claimed"), ("Break three shards.", "done"),
                                     ("Forge once.", "open")])),
]
TODAY_NOTES = [
    "Research's pick, B: today's three sit behind a Today card in Settings' column, the shard its picture (what waits",
    "there), three pips for the three goals; Settings is a cog tile over it, 44 tall. The card's rim and glow turn gold",
    "while a goal waits to be claimed. It opens the list in the glass. Next is the list's head (research's second",
    "look): a plate that holds the back press at its left, up to a hairline, then the account's one next step and what",
    "it opens, at 14. It isn't a press beyond the hairline: deeper than a row, a pale bar down its side. Under it today's",
    "three show whole at once: 3 + 40 + 2 + 3 x 44 + 2 x 2 + 3 = 184, the glass. The plate is 40, not 46: at 46 the list",
    "lies on the glass's rim at its top and its foot; at 40 it keeps 3 clear of both, and its two lines still sit at 14.",
    "A leaning row a goal, its shard at the right. Open: the shard dim, a count where the goal counts. Done: the whole",
    "row is the claim's press, lit gold. Claimed: the row sinks and takes a check until the day turns. Banked days",
    "scroll under Next. Rows 44 tall; no word under 14. The words are TR54's. Stand-ins: the fight, the counts.",
]


# --- the cut --------------------------------------------------------------------------------------------------------

def cut_pieces():
    """Every image of the cut, drawn once. The sheets are laid from these, as the game lays them."""
    for state, name in MARKS.items():
        piece(name, (-20, -20, 20, 20), lambda t, s=state: dare_mark(t, 0, 0, MARK_H, s),
              use=f"the dare's mark, {dict(lit='lit while the dare holds', kept='its flare, kept', dark='dark and split once broken')[state]}")
    piece("HomeCog", bounds(column(*COG), 10), cog_tile, use="Settings, a cog tile at the head of Settings' column")
    piece("HomeCogPress", bounds(column(*COG), 10), lambda t: hc.press(t, t.poly(column(*COG)), 10),
          tint="the kit's lit press", use="over the cog tile while it's held")
    piece("HomeToday", bounds(column(*TODAY_Y), 12), today_body, use="the Today card, under the cog tile")
    piece("HomeTodayWaits", bounds(column(*TODAY_Y), 12), today_waits, use="over the Today card while a goal waits to be claimed")
    piece("HomeTodayPress", bounds(column(*TODAY_Y), 12), lambda t: hc.press(t, t.poly(column(*TODAY_Y)), 12),
          tint="the kit's lit press", use="over the Today card while it's held")
    for state, name in PIPS.items():
        piece(name, (-14, -14, 14, 14), lambda t, s=state: pip(t, 0, 0, s), use=f"one of today's three on the card: {state}")
    row = bounds(leaned(0, ROW_W, 0, ROW_H), 12)
    for state, name in ROWS.items():
        piece(name, row, lambda t, s=state: row_plate(t, s), use=f"a goal's row: {state}")
    piece("GoalRowPress", row, lambda t: hc.press(t, t.poly(leaned(0, ROW_W, 0, ROW_H)), 12), tint="the kit's lit press",
          use="over a done row while it's held: the row is the claim's press")
    piece("GoalCheck", (-12, -12, 12, 12), row_check, use="a claimed goal's check, where its shard was")
    piece("GoalNext", bounds(leaned(0, ROW_W, 0, NEXT_H), 12), next_plate,
          use="Next's plate, the Today list's head: pinned; the back press at its left, up to its hairline")


def r2(v):
    return [r2(x) for x in v] if isinstance(v, (list, tuple)) else round(float(v), 2)


def ltwh(box):
    """A box as the handoffs give it: left, top, width, height."""
    x0, y0, x1, y1 = box
    return r2([x0, y0, x1 - x0, y1 - y0])


def record():
    """goals.json: where each image lies and what the game's own kit builds beside it. Points, the smallest phone."""
    lean = hc.LEAN * ROW_H
    sx = ROW_W - 40 + lean / 2
    y0, y1 = TODAY_Y
    images = {name: dict(file=f"images/{name}.png", pixels=[p["px"].shape[1], p["px"].shape[0]],
                         origin=r2([-p["box"][0], -p["box"][1]]), **({"tint": p["tint"]} if p["tint"] else {}), use=p["use"])
              for name, p in PIECES.items()}
    return dict(
        what="AR53, the goals' look, for TR54: research's pick B (2026-11-23, 17:49) with its must-fix 1 and the fall's "
             "card, redrawn on the director's cut of the Mask Ledger (2026-11-23, by 18:38): the dare's mark in the "
             "kit's make, Next the Today list's head (research's second look, 18:54). Every word is TR54's (docs/test-requests.md, TR54: the "
             "dares, today's three, Next, the labels): this file holds where words sit, never the words.",
        units="points at the smallest phone (568 x 320); every box is left, top, width, height; a word's y is its "
              "capitals' top; images at 4 pixels a point, edge alpha 0. An image's `origin` is where its lay point sits "
              "in it, in points from its top left (times 4 for pixels): a lay's `origin` is where that point goes",
        sheets=["goals_dare_line.png", "goals_dare_card.png", "goals_today.png", "goals_cut.png"],
        dare=dict(
            line=dict(
                note="the run's line as StageController builds it; boxes from the line's glass's top left",
                unfolded=dict(
                    make="the folded tab opened to the right, in the line's own glass, under the line. The line never "
                         "grows, and the mark stays where it is folded (origin 21, 57, scale 1)",
                    box=dict(left=8, top=30, foot=dict(one_row=70, two_rows=88), corners=dict(one_row=4, two_rows=6),
                             right="its widest row's end and 10, and never past the limit"),
                    limit="6 short of any HUD piece the open dare would lie over: the Electricity pill, 263 from the "
                          "line's left at the smallest phone. An open dare lies over no other HUD piece, at any phone "
                          "(research's must-fix, 2026-11-23, 20:07)",
                    words=dict(x="the stretch's name's left", size=SMALL, colour=P["text"], y=dict(one_row=51, two_rows=[48, 66]),
                               rows="one when the dare ends 8 inside the limit; else two, broken at the word that leaves "
                                    "the rows most alike"),
                    beside="the base's tab (AR55, build/handoff/UI/return/return.json) rides the open dare's foot, its top "
                           "14 above it as under the line: 26 lower under one row, 44 under two",
                    held="about 3 s from the stretch's start (a seed: TR54's Config), then it closes to the tab"),
                folded=dict(tab=dict(box=[8, 30, 26, 40], make="the line's own glass, under it, corners cut 4"),
                            mark=dict(origin=[21, 57], scale=1.0,
                                      images=dict(holds="DareMark", broken="DareMarkDark", kept="DareMarkKept")),
                            broken="the mark's image swaps to DareMarkDark; no words, no sound",
                            kept="DareMarkKept once, as the stretch clears"),
                hard="the same row and tab in the Hard line's glass (the ember's edge)"),
            card=dict(
                marks=dict(image="DareMarkKept", scale=15 / MARK_H,
                           origin="10 right of stretch k's mark's right edge, on the road's middle, for each k kept"),
                chip=dict(row="last on the time's row, the row's gap (8) before it; on the fall's card a row of its own "
                              f"under the line that says where the next run starts, {CELL:g} tall, the chip centred, 2 down",
                          height=22, corners=4, fill=list(sk.SOCKET_DARK) if isinstance(sk.SOCKET_DARK, (tuple, list)) else sk.SOCKET_DARK,
                          edge=dict(colour=PAPER_SHADE, width=1.2), glow=dict(colour=GLOW, strength=0.22, reach=5),
                          mark=dict(image="DareMarkKept", origin=[10, 11], scale=13 / MARK_H),
                          words=dict(text="TR54's chip label", x=19, y=4, size=SMALL, bold=True, colour=PAPER),
                          stone=dict(left="the words' right + 6", top=-2, size=CELL,
                                     make="the kit's Common item cell with the forge stone's picture of the ground's "
                                          "grade (StoneLow on Lantern Row) at 0.94 and a hairline in the edge "
                                          f"{up.P['edge']} over its rim, as Reinforce draws its stone"),
                          count=dict(left="the cell's right + 4", y=3, size=TITLE, bold=True, colour=P["text"],
                                     words="+N, one stone a kept dare"),
                          pad=7, width="follows its words",
                          widest="with a new best the row is about 297 of the card's 320 by the sheet's letter widths: "
                                 "not measured in the game's face, so the first capture checks it"),
                none="no dare kept: no mark, no chip, on either card"),
            note="the mark's image is 40 points square, its middle the origin: the mark itself is 16 tall and 12.8 wide"),
        today=dict(
            note="boxes from Home's glass's top left (build/handoff/UI/home_cards/home_cards.json). HomeSettings, "
                 "HomeSettingsPress and the Settings label leave the panel: Settings is the cog tile",
            cog=dict(images=["HomeCog", "HomeCogPress"], origin=[0, 0], tap=ltwh(bounds(column(*COG), 0)),
                     mark=dict(image="HomeMarkSettings (AR43's)", centre=r2([hc.middle("Settings", COG[0] + 22), COG[0] + 22]),
                               size=24, colour="#C9D0D9")),
            card=dict(images=["HomeToday", "HomeTodayWaits", "HomeTodayPress"], origin=[0, 0],
                      tap=ltwh(bounds(column(*TODAY_Y), 0)),
                      waits="HomeTodayWaits shows while any goal, today's or banked, waits to be claimed",
                      shard=dict(image="the Lantern Row shard's small picture (shard_standard_small)",
                                 box=r2([hc.middle("Settings", y0 + 38) - 20, y0 + 14, 40, 40])),
                      pips=dict(images=PIPS, centres=[r2([hc.middle("Settings", y0 + 72) - 13 + k * 13, y0 + 72]) for k in range(3)],
                                note="today's three in the lists' order: fight, base, roster"),
                      word=dict(x=r2(hc.middle("Settings", y1 - 9)), y=r2(y1 - 9 - SMALL * 0.72), size=SMALL, colour=IVORY,
                                align="CENTER", make="Home's words: bold, leaning, a soft dark under")),
            list=dict(
                note="in the glass alone: the three cards, the cog tile and the Today card hidden, HomeGlass and "
                     "HomePointer kept",
                next=dict(note="the list's head: pinned, never scrolling. TR54's line split at its first full stop: the "
                               "step, then what it opens (45 letters or fewer: one row each); the last line stands alone",
                          image="GoalNext", left=ROW_X[0], top=LIST_PAD, height=NEXT_H,
                          origin="the plate's top, its foot's left corner",
                          back=dict(chevron=r2([[ROW_X[0] + x, LIST_PAD + y] for x, y in BACK]), width=1.8, colour=IVORY,
                                    tap=r2([ROW_X[0] - 2, 1, 46, 44]),
                                    note="the plate's one press: it ends at the hairline drawn in the image"),
                          lines=dict(x=f"{NEXT_X:g} + 0.2 x ({NEXT_H - 5:g} - y) from the plate's left: the plate's lean",
                                     y=list(NEXT_Y), alone=NEXT_ONE, size=SMALL, colours=[IVORY, "#AEB7C2"],
                                     holds="280 points: 45 letters are 272 in the sheet's face"),
                          label=dict(colour=NEXT_BLUE, bold=True, note="on the first line, the step 38 to its right")),
                rows=dict(left=ROW_X[0], top=LIST_PAD + NEXT_H + ROW_GAP, foot=LIST_FOOT, height=ROW_H, gap=ROW_GAP,
                          images=dict(ROWS, press="GoalRowPress"), origin="a row's top, its foot's left corner",
                          frame=f"the scrolling frame runs from Next's foot ({LIST_PAD + NEXT_H:g}) to the glass's "
                                f"({hc.PANEL[1]:g}), its rows padded {ROW_GAP:g} at the top and {LIST_PAD:g} at the foot",
                          words=dict(x=r2(lean / 2 + 14), y=15, size=SMALL, colour=IVORY, claimed="#7E879A"),
                          shard=dict(box=r2([sx, 6, 32, 32]), open="at 0.5", done="at 1"),
                          right=dict(x=r2(sx - 8), y=15, size=SMALL, align="RIGHT", count="#AEB7C2",
                                     claim=dict(colour=READY, bold=True)),
                          check=dict(image="GoalCheck", origin=r2([sx + 16, 22])),
                          done="the whole row is the claim's press", claimed="stays until the day turns"),
                day=dict(height=22, x=r2(ROW_X[0] + 14), y=4, size=SMALL, colour="#8F99A6"),
                scroll=dict(shows="136 points of rows: today's three whole at rest (3 x 44 + 2 x 2); the list scrolls "
                                  "only with a banked day",
                            thumb=dict(x=r2(hc.PANEL[0] - 5), width=2, colour="#55607A")))),
        images=images,
        motion="nothing moves here beyond what the kit does (a press, a screen opening). The unfold, the fold into the "
               "tab, the flare and the mark's split are TR54's block, and research reads them in motion there",
    )


def cut(out):
    """The images, goals.json and the cut's own sheet: every image over the page's dark, at half its pixels."""
    images = out / "images"
    images.mkdir(parents=True, exist_ok=True)
    for old in images.glob("*.png"):
        old.unlink()
    for name, p in PIECES.items():
        rs.save(p["px"], images / f"{name}.png")
        a = p["px"][..., 3]
        edge = float(max(a[0].max(), a[-1].max(), a[:, 0].max(), a[:, -1].max()))
        print(f"{name:28s} {a.shape[1]}x{a.shape[0]}  edge alpha {edge * 255:.1f}")
        assert edge * 255 < 1.0, f"{name} has alpha at its edge"
    (out / "goals.json").write_text(json.dumps(record(), indent=1), encoding="utf-8", newline="\n")
    ui.K = 2
    gap, wide = 14, 1180
    x, y, tall, places = gap, 56, 0, []
    for name, p in PIECES.items():
        w, h = (p["box"][2] - p["box"][0]), (p["box"][3] - p["box"][1])
        cw = max(w, ss.wide_of(name, SMALL) * 0.9) + gap
        if x + cw > wide:
            x, y, tall = gap, y + tall + 26 + gap, 0
        places.append((name, x, y))
        x, tall = x + cw, max(tall, h)
    sheet = ui.Sheet(wide, y + tall + 26 + gap, "#241F3D")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 16, 20, f"AR53, the goals' cut: {len(PIECES)} images at 4 pixels a point, shown at 2, on the page's dark", "#EDE6D6",
           bold=0.2)
    for name, x, y in places:
        p = PIECES[name]
        lay(t, name, x - p["box"][0], y + 18 - p["box"][1])
        t.text(x, y, SMALL, name, "#C6BDE4")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "goals_cut.png")


# --- the sheets -----------------------------------------------------------------------------------------------------

def thumbs(shots):
    """A sheet's phones at 64 pixels high: all that's kept of a sheet once it's saved (a sheet is 80 MB)."""
    return [rs.shrink(shot, 64 / (H * 2)) for shot in shots]


def small(out, groups):
    """Every phone at 64 pixels high, over dark."""
    gap = 12
    sw = groups[0][0].shape[1]
    most = max(len(g) for g in groups)
    page = rs.canvas(gap + most * (sw + gap), gap + len(groups) * (64 + gap), tuple(rs.rgb("#101117")))
    for r, shots in enumerate(groups):
        for k, shot in enumerate(shots):
            rs.paste(page, shot, gap + k * (sw + gap), gap + r * (64 + gap))
    rs.save(page, out / "goals_small.png")


def pictures(out, crops):
    """For the content check: the dare's mark in its three states, large, with its image beside it at the phone's
    size; then the drawn pieces at twice the phone's pixels."""
    ui.K = 2
    gap = 14
    doubled = [np.repeat(np.repeat(c, 2, axis=0), 2, axis=1) for c in crops]
    below = sum(c.shape[0] / 2 + gap + 22 for c in doubled)
    sheet = ui.Sheet(max(gap + 3 * 150, max(c.shape[1] for c in doubled) / 2 + 2 * gap), 56 + 150 + below, "#101117")
    t = sheet.tile(0, 0, 1, 1)                           # for the words only: each picture draws on its own tile
    t.text(gap, 16, 20, "AR53's redraw: the dare's mark, large and at the phone's size; then each piece as drawn", "#EDE6D6", bold=0.2)
    y = 56
    for k, state in enumerate(("lit", "kept", "dark")):
        x = gap + k * 150
        c = sheet.tile(x, y, 136, 130)
        up.box(c, 0, 0, 136, 130, sm.TILE, P["edge"], 1.0, 6)
        dare_mark(c, 52, 56, 80, state)
        lay(c, MARKS[state], 114, 56)
        t.text(x + 8, y + 112, SMALL, {"lit": "the dare holds", "kept": "kept", "dark": "broken"}[state], "#B4AC9C")
    y += 150
    names = ("the dare unfolded under the line", "folded: its mark in the line's tab", "the marks on the card's road",
             "\"Dare kept\" on the card's time row", "the list, Next its head")
    for c, name in zip(doubled, names):
        t.text(gap, y + 2, SMALL, f"{name}, at twice the phone's pixels", "#B4AC9C")
        rs.paste(sheet.px, c, round(gap * 2), round((y + 22) * 2))
        y += c.shape[0] / 2 + gap + 22
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "goals_pictures.png")


def grounds(out):
    """For the content check: the redraw's four files as they are, over the page's dark and over white: the mark's
    three at their own pixels and at 64 pixels high, then Next's plate at its own pixels and at 64 pixels high."""
    ui.K = CUT_K
    marks, plates = list(MARKS.values()), ["GoalNext"]

    def size(name):
        b = PIECES[name]["box"]
        return b[2] - b[0], b[3] - b[1]
    gap = 14
    cw = max(size(n)[0] for n in plates) + gap
    tall = 44 + 40 + gap + 16 + gap + sum(size(n)[1] + gap + 16 + gap for n in plates)
    sheet = ui.Sheet(gap + 2 * (cw + gap), tall + gap, "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 14, "AR53's redraw, the new files: the mark and Next's plate, at their own pixels and at 64 pixels high; on the "
           "page's dark, on white", "#EDE6D6")
    for col, ground in enumerate(("#241F3D", "#FFFFFF")):
        x0 = gap + col * (cw + gap)
        up.box(t, x0 - gap / 2, 38, x0 + cw - gap / 2, tall + gap / 2, ground, cut=0.0)
        x = x0
        for name in marks:
            b = PIECES[name]["box"]
            lay(t, name, x - b[0], 44 - b[1])
            px = PIECES[name]["px"]
            t.image(rs.shrink(px, 64 / px.shape[0]), x, 44 + 40 + gap)
            x += size(name)[0] + gap
        y = 44 + 40 + gap + 16 + gap
        for name in plates:
            b = PIECES[name]["box"]
            lay(t, name, x0 - b[0], y - b[1])
            y += size(name)[1] + gap
            px = PIECES[name]["px"]
            t.image(rs.shrink(px, 64 / px.shape[0]), x0, y)
            y += 16 + gap
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "goals_new.png")


def crop(shot, box):
    x0, y0, x1, y1 = (round(v * 2) for v in box)
    return shot[max(y0, 0):y1, max(x0, 0):x1].copy()


def main():
    out = bl.out_dir()
    rs.OUT = out
    home_made()
    cut_pieces()
    for words in DARES + [FALLBACK]:                     # the five dares in the sheet's face, against the smallest phone's room
        print(f"measure {words!r}: {face_wide(words, SMALL):.0f} wide; rows in 211: {len(broken(words, 211))}, "
              f"in Hard's 187: {len(broken(words, 187))}")
    common = "at the smallest phone (568 x 320 points)"
    lines = ss.sheet_of(out, "goals_dare_line.png", f"AR53, the dare on the run's line, {common}", LINES, LINE_H,
                        LINE_NOTES, line_cell)
    crops = [crop(lines[0], SPOTS["line"]), crop(lines[1], SPOTS["tab"])]
    del lines
    if sys.argv[-1] == "line":                           # the dare's line alone: its sheet and goals.json, no image touched
        (out / "goals.json").write_text(json.dumps(record(), indent=1), encoding="utf-8", newline="\n")
        return
    cards = ss.sheet_of(out, "goals_dare_card.png", f"AR53, the dare on the run's card, {common}", CARDS, H, CARD_NOTES,
                        card_cell)
    for said_, st in CARDS:
        print(f"card: {st['tall']:.0f} of {H - ss.BAND} points tall, its time row {st.get('row', 0):.0f} of 320: {said_}")
    crops += [crop(cards[0], SPOTS["road"]), crop(cards[0], SPOTS["chip"])]
    groups = [thumbs(cards)]
    del cards
    today = ss.sheet_of(out, "goals_today.png", f"AR53, today's three on Home's panel, {common}", TODAY, H, TODAY_NOTES,
                        today_cell)
    crops.append(crop(today[2], SPOTS["rows"]))
    groups.append(thumbs(today))
    del today
    gc.collect()
    if sys.argv[-1] == "cut":
        cut(out)
        return
    small(out, groups)
    pictures(out, crops)
    grounds(out)


if __name__ == "__main__":
    main()
