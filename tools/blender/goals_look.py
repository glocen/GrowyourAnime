"""AR53, the goals' look, basic at launch: the blockout (Modulo, 2026-11-23). Sheets for research's pick.

Three layers (docs/design.md, "Goals"; docs/test-requests.md, TR54), each in the make of the screen it joins:
    the dare        on the run's line under Roblox's top bar (stage_seam.py's line, as StageController builds it) and on
                    the run's card, in Seam's lit glass. The game has no start card: a run is four stretches under one
                    line, so a stretch's dare unfolds under that line as the stretch starts, then folds to a paper tag
                    hung from the line. The tag is the dare's mark: lit while the dare holds, dark once it's broken,
                    and on the card it hangs from the road after each stretch whose dare was kept.
    today's three   on Home's panel (home_cards.py, AR49's glass and leaning cards). The panel is full at the smallest
                    phone, so the three sit behind an entry, drawn two ways for the pick: A, a slip on the glass's top
                    edge; B, a Today card in Settings' column with Settings a cog over it (AR49 kept that column for
                    this). Either opens the same list in the glass: a leaning row a goal, its shard at the right.
    the Ledger      a Seam page: the kind's mask hung from a hook by its own strings, unlit until the first one falls,
                    its count, its three lines as they're reached, and Next in the band.

The masks are the models' own cuts, flat: the Brawler's as stage_screen.mask, the Guard's and the Dasher's from
shade_sheet.mask (AR52), the Lamplighter's from lamplighter_sheet.mask_lantern. The content check's conditions on the
words and the plan (2026-11-23, 15:31) are drawn in: an unlit mask is dark paper in a thin rim with the page showing
through its holes; a lit one keeps its light inside its cuts, warm white, never a type's colour; each is a hung object
with its strings, knot, tails and hook; nothing is marked on a mask for its count; the tag is blank. The baked check
(17:41) let the Lamplighter's closed crescents stand as the model's own, the keeper's only, and asked that its hoops and
ribs stay drawn unlit.

Measured in points at the smallest phone (568 x 320), two pixels a point. Drawn in code; nothing is exported.

    blender -b --factory-startup --python tools/blender/goals_look.py -- <abs out>

Writes:
    goals_dare_line.png     the run's line: a stretch's start, the tag lit, dark and kept, Hard, the keeper
    goals_dare_card.png     the run's card: dares kept, the first clear, none kept, a fall
    goals_today.png         Home: the two entries at rest and quiet, then the list's states
    goals_ledger.png        the Ledger's page: a kind lit, unlit, full, and the keeper's
    goals_small.png         every phone at 64 pixels high
    goals_pictures.png      for the content check: each mask lit and unlit, large and at 64 pixels; the tag's three states
"""

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
GLOW = "#FFF6E2"                       # a mask's light and the tag's: the Shade's warm white, never a type's colour
UNLIT = "#120F22"                      # an unlit mask's paper: darker than the page, so its holes read lighter
READY = sm.READY
IVORY = hc.IVORY
STONE = up.UPG / "StoneLow.png"
SHARD = ss.ICONS["shards"]
LINE_H = 150
SPOTS = {}                             # a few drawn boxes, in a phone's points, for the pictures sheet


def wrap(words, most):
    lines, line = [], ""
    for word in words.split():
        if line and len(line) + 1 + len(word) > most:
            lines.append(line)
            line = word
        else:
            line = f"{line} {word}".strip()
    return lines + [line]


def circle(t, cx, cy, r):
    return np.hypot(t.x - cx, t.y - cy) - r


# --- the dare's mark ------------------------------------------------------------------------------------------------

def tag(t, x, y, s, state="lit", lean=0.14):
    """The dare's mark: a blank paper tag on its string, tied at (x, y) and hanging a little off true, `s` tall. Lit
    while the dare holds; "kept", its flare; "dark", the paper gone dark in a thin rim once the dare is broken."""
    w, drop = s * 0.6, s * 0.3

    def at(u, v):
        return (x + u + v * lean, y + v)
    pts = [at(-w / 2, drop + s * 0.22), at(-w / 2 + s * 0.2, drop), at(w / 2 - s * 0.2, drop), at(w / 2, drop + s * 0.22),
           at(w / 2, drop + s), at(0, drop + s * 0.8), at(-w / 2, drop + s)]
    d = t.poly(pts)
    dark = state == "dark"
    t.stroke([(x, y), at(0, drop + s * 0.16)], max(0.8, s * 0.07), P["faint"] if dark else PAPER_SHADE)
    if dark:
        t.paint(d, UNLIT)
        t.paint(np.abs(d) - 0.45, P["faint"], 0.9)
    else:
        t.glow(d, s * (0.45 if state == "kept" else 0.22), GLOW, 0.6 if state == "kept" else 0.25)
        t.paint(d, t.ramp(PAPER, PRESSED, (t.y - y - drop) / s))
        t.line(d, 0.8, PAPER_SHADE)
    hx, hy = at(0, drop + s * 0.2)
    t.paint(circle(t, hx, hy, max(0.7, s * 0.07)), P["faint"] if dark else P["channel"])


# --- the dare on the run's line -------------------------------------------------------------------------------------

def run_line(t, st):
    """The run's line as StageController builds it (the stretch's mark, "Stretch 2 of 4", its Shades on their road),
    with the dare: unfolded under it as the stretch starts, then a tag hung from its foot."""
    hard, quota, kills, last = st["hard"], st["quota"], st["kills"], st["last"]
    acc = sm.ACC[hard]
    x0, x1, y0 = 100, 468, ss.BAND + 4
    said = st.get("dare")
    y1 = y0 + 44 + (24 if said else 0)
    if st.get("tag"):                                    # folded: a tab of the line's own glass under the stretch's mark
        sm.glass(t, x0 + 8, y0 + 30, x0 + 34, y0 + 70, hard, 4, 1.0)
    sm.glass(t, x0, y0, x1, y1, hard, 6, 1.2)
    if st.get("tag"):
        tag(t, x0 + 20, y0 + 44, 16, st["tag"])
    sm.badge(t, x0 + 8, y0 + 9, st["stage"], hard, True)
    tx = x0 + 8 + 26 + (24 if hard else 0) + 10
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
        t.stroke([(x0 + 8, y0 + 46), (x1 - 8, y0 + 46)], 1.0, P["edge"], 0.9)
        tag(t, x0 + 21, y0 + 46, 14, "lit")
        t.text(tx, y0 + 51, SMALL, said, P["text"])
        SPOTS.setdefault("line", (x0 - 6, y0 - 4, x1 + 6, y1 + 8))


def line_cell(sheet, ox, oy, st):
    t = sheet.tile(ox, oy, W, LINE_H)
    ui.world(t, "noon")
    sm.stand_in(t)
    run_line(t, st)


DARES = ["Finish with your lead above half.", "Break a raised shield with your signature.",
         "Let no Dasher's line touch you.", "Stand outside every slam."]
LINES = [
    ("Stretch 2 starts: its dare unfolds under the line, for about 3 s",
     dict(hard=False, stage=2, quota=10, kills=0, last=False, right="then the elite", dare=DARES[1])),
    ("Then it folds to its tag, lit while the dare holds",
     dict(hard=False, stage=2, quota=10, kills=5, last=False, right="then the elite", tag="lit")),
    ("The dare broken: the tag goes dark, and nothing is said",
     dict(hard=False, stage=3, quota=10, kills=4, last=False, right="then the elite", tag="dark")),
    ("The stretch cleared, its dare kept: the tag flares once",
     dict(hard=False, stage=2, quota=10, kills=10, last=True, right="cleared", tag="kept")),
    ("Hard, Stretch 1 starts: the same row in the ember's edge",
     dict(hard=True, stage=1, quota=10, kills=0, last=False, right="then the elite", dare=DARES[0])),
    ("Stretch 4, the keeper's: its dare",
     dict(hard=False, stage=4, quota=0, kills=0, last=False, right="the Lamplighter", dare=DARES[3])),
]
LINE_NOTES = [
    "The game has no start card: a run is four stretches under one line. So a stretch's dare unfolds under that line as",
    "the stretch starts (a second row, the line's own glass), and folds after about 3 s to a blank paper tag hung in a",
    "tab of that glass under the stretch's mark. The tag is the dare's mark everywhere: lit while the dare holds, dark in",
    "a thin rim once it's broken (no words, no sound), a flare when the stretch is cleared with it kept. The longest",
    "dare (Stretch 2's) fits in 14. Stand-ins: the words at the line's right, the street, Roblox's buttons.",
]


# --- the dare on the run's card -------------------------------------------------------------------------------------

def trimmed(path, size, alpha=1.0):
    """A picture cut to what's drawn in it, squared, `size` points wide."""
    px = rs.load(path)
    there = px[..., 3] > 0.05
    rows, cols = np.where(there.any(1))[0], np.where(there.any(0))[0]
    part = px[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1]
    side = max(part.shape[:2])
    square = np.zeros((side, side, 4), part.dtype)
    y, x = (side - part.shape[0]) // 2, (side - part.shape[1]) // 2
    square[y:y + part.shape[0], x:x + part.shape[1]] = part
    return hc.image(square, size, alpha=alpha)


KEPT_W = ss.wide_of("Dare kept", SMALL) * 0.9


def dare_wide(n):
    return 19 + KEPT_W + 5 + 18 + 3 + ss.wide_of(f"+{n}", TITLE) + 6


def dare_chip(t, x, y, n):
    """"Dare kept" on the time's row: the tag, the words, and the forge stones the kept dares paid."""
    wide = dare_wide(n)
    d = t.poly(ui.cut_box(x, y, x + wide, y + 22, 4, 4, 4, 4))
    t.glow(d, 5.0, GLOW, 0.22)
    t.paint(d, up.shade(t, sk.SOCKET_DARK, y, y + 22))
    t.line(d, 1.2, PAPER_SHADE)
    tag(t, x + 10, y + 1.5, 13, "kept")
    t.text(x + 19, y + 4, SMALL, "Dare kept", PAPER, bold=0.3)
    sx = x + 19 + KEPT_W + 5
    t.image(trimmed(STONE, 18), sx, y + 2)
    t.text(sx + 21, y + 3, TITLE, f"+{n}", P["text"], bold=0.3)
    SPOTS.setdefault("chip", (x - 8, y - 8, x + wide + 8, y + 30))


def card(t, st):
    """The run's card (StageScreen.Results, stage_seam.results) with the dares: a tag hung from the road after each
    stretch whose dare was kept, and "Dare kept" with its stones on the time's row. Missed, the card is as today."""
    hard, lost = st["hard"], st.get("lost", False)
    x0, x1 = 124, 444
    cx = (x0 + x1) / 2
    spans = [("marks", 30), ("title", 28), ("time", 22)]
    if st.get("gave"):
        spans.append(("gave", 28))
    if st.get("opened"):
        spans.append(("opened", 34))
    inner = sum(h for _, h in spans) + 8 * (len(spans) - 1)
    total = 12 + inner + 14 + ss.TAP + 10
    y0 = max(ss.BAND + 4, ss.BAND + (H - ss.BAND - total) / 2)
    y1 = y0 + total
    sm.glass(t, x0, y0, x1, y1, hard, 8, 1.4)
    kept = st.get("dares", ())
    y = y0 + 12
    for kind, h in spans:
        if kind == "marks":
            sm.marks(t, x0 + 16, x1 - 16, y + h / 2, st["marks"], hard)
            tab = 21 if hard else 0
            step = (x1 - x0 - 32 - 12 - 26 - tab) / 3
            for k in kept:
                tag(t, x0 + 22 + (k - 1) * step + 26 + tab + 7, y + h / 2 + 2, 15, "kept")
        elif kind == "title":
            t.text(cx, y + 2, BIG, st["title"], ss.HURT if lost else P["text"], "CENTER", bold=0.35)
        elif kind == "time" and lost:
            t.text(cx, y + 3, SMALL, st["said"], P["soft"], "CENTER")
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
    ("A fall: nothing about dares",
     dict(hard=False, lost=True, marks=["cleared", "cleared", "next", "shut"], title="Your lead fell",
          said="Your next run starts at Stretch 3 of 4",
          presses=[("Retry", "one", 170, False), ("Home", "quiet", 124, False)])),
]
CARD_NOTES = [
    "The run's card, as built, with the dares. A tag hangs from the road after each stretch whose dare was kept, so the",
    "four marks say which. \"Dare kept\" and the stones those dares paid sit on the time's row, in the paper's warm",
    "edge: no new row, because the first clear's card already stands 254 of the 262 points under Roblox's bar. With a",
    "new best the row holds the time, \"a new best\" and the dare's chip: about 290 of the card's 320 by the sheet's",
    "letter widths, so the finish measures it in the game's face. Missed, nothing is said and the card is today's.",
    "Stand-ins: the times, what the run gave, the presses, the street.",
]


# --- today's three, on Home's panel ---------------------------------------------------------------------------------

HOME = {}
ROW_H, ROW_GAP, LIST_TOP = 44.0, 4.0, 32.0
ROW_X = (10.0, 352.0)                  # a row's foot, in the glass's points


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
    """The smallest phone with Home open, laid from AR49's cut as home_cards.built lays it. "cards": the three cards;
    "card": Settings' card left out, for the Today card; "list": the glass alone."""
    made, world = home_made()["made"], HOME["world"]
    w, h = hp.size_of(world)
    px0, py0 = hc.panel_at(w, h, "small")
    out = hp.dimmed(world, "B", hc.DIM)
    light = hc.light_of("Common")
    for name, box, _draw, tint, _use in made["pieces"]:
        if name.endswith("Press") or (mode == "list" and name not in ("HomeGlass", "HomePointer")):
            continue
        if mode == "card" and name == "HomeSettings":
            continue
        x, y = px0 + box[0], py0 + box[1]
        if name == "HomePointer":
            x = w / 2 + box[0]
        fc.put(out, made["px"][name], x, y, tint=light if tint == "light" else tint)
        if name == "HomeVoidkinRimTop":
            ui.K = hc.SHEET_K
            vx, vy = hc.viewport_box()[:2]
            rs.paste(out, hc.stand_in(HOME["lead"], "Common"), round((px0 + vx) * 2), round((py0 + vy) * 2))
        if name == "HomeSettings":
            cx, cy, s = hc.cog_of()
            fc.put(out, made["cog"], px0 + cx - s / 2, py0 + cy - s / 2, s / (made["cog"].shape[1] / hc.K), "#C9D0D9")
    items = [] if mode == "list" else [i for i in hc.text_items(px0, py0) if not (mode == "card" and i["text"] == "Settings")]
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


def slip(t, px0, py0, pips, more=0):
    """A, the slip: a tab on the glass's top edge, over Settings: "Today" and its three pips. Gold when one waits."""
    waits = "done" in pips
    pts = leaned(px0 + 232, px0 + hc.PANEL[0] - 18, py0 - 25, py0 + 1, 4.0)
    d = t.poly(pts)
    if waits:
        t.glow(d, 6.0, READY, 0.4)
    t.paint(d, t.ramp("#232B3D", "#0F131C", (t.y - py0 + 25) / 26))
    t.line(d, 1.3 if waits else 1.0, READY if waits else "#55607A", 0.95)
    t.paint(np.maximum(d, np.abs(t.y - (py0 - 23.6)) - 0.6), "#CFDBFF", 0.3)
    said(t, px0 + 250, py0 - 18, SMALL, "Today", IVORY)
    for k, state in enumerate(pips):
        pip(t, px0 + 303 + k * 13, py0 - 12, state)
    if more:
        said(t, px0 + 340, py0 - 18, SMALL, f"+{more}", "#AEB7C2")


def today_card(t, sheet, ox, oy, px0, py0, pips):
    """B, the card: Today in Settings' column, the shard its picture; Settings a cog tile over it."""
    fx0, fx1 = hc.CARDS["Settings"]

    def col(y0, y1, cut=5.0):
        a = lambda fx, y: px0 + hc.at(fx, y)   # noqa: E731
        return [(a(fx0, y0 + cut), py0 + y0 + cut), (a(fx0, y0) + cut, py0 + y0), (a(fx1, y0), py0 + y0),
                (a(fx1, y1 - cut), py0 + y1 - cut), (a(fx1, y1) - cut, py0 + y1), (a(fx0, y1), py0 + y1)]
    mat = hc.MAT["Settings"]
    cog = t.poly(col(hc.TOP, hc.TOP + 44))
    t.glow(cog, 5.0, "#000000", 0.4)
    t.paint(cog, t.ramp(mat["body"][0], mat["body"][1], (t.y - py0 - hc.TOP) / 60))
    t.line(cog, 1.0, mat["rim"], 0.9)
    cx = px0 + (hc.at(fx0, hc.TOP + 22) + hc.at(fx1, hc.TOP + 22)) / 2
    fc.put(sheet.px, HOME["made"]["cog"], ox + cx - 12, oy + py0 + hc.TOP + 10, 24 / (HOME["made"]["cog"].shape[1] / hc.K), "#C9D0D9")
    waits = "done" in pips
    y0, y1 = hc.TOP + 50, hc.FOOT
    body = t.poly(col(y0, y1))
    t.glow(body, 6.0, READY if waits else "#000000", 0.4)
    t.paint(body, t.ramp("#232B3D", "#06080D", (t.y - py0 - y0) / (y1 - y0)))
    mx = px0 + (hc.at(fx0, y0 + 38) + hc.at(fx1, y0 + 38)) / 2
    t.paint(body, "#AFC6F0", 0.16 * np.exp(-(((t.x - mx) / 30) ** 2 + ((t.y - py0 - y0 - 36) / 30) ** 2)))
    t.line(body, 1.4 if waits else 1.0, READY if waits else mat["rim"], 0.95)
    t.image(hc.image(SHARD, 40), mx - 20, py0 + y0 + 14)
    px_ = px0 + (hc.at(fx0, y0 + 72) + hc.at(fx1, y0 + 72)) / 2
    for k, state in enumerate(pips):
        pip(t, px_ - 13 + k * 13, py0 + y0 + 72, state)
    said(t, px0 + (hc.at(fx0, y1 - 9) + hc.at(fx1, y1 - 9)) / 2, py0 + y1 - 9 - SMALL * 0.72, SMALL, "Today", IVORY, "CENTER")


def goal_row(t, px0, y0, words, state, count=None):
    """A goal: a leaning row in the glass, its words, and at its right its shard. Open, the shard waits dim; done, the
    row is the claim's press, lit gold; claimed, it sinks and takes a check."""
    xl, xr = px0 + ROW_X[0], px0 + ROW_X[1]
    y1 = y0 + ROW_H
    d = t.poly(leaned(xl, xr, y0, y1))
    lean = hc.LEAN * ROW_H
    sx = xr - 40 + lean / 2
    if state == "done":
        t.glow(d, 6.0, READY, 0.4)
        t.paint(d, t.ramp("#3B3220", "#15110A", (t.y - y0) / ROW_H))
        t.line(d, 1.4, READY, 0.95)
        t.paint(d, "#FFE9A8", 0.22 * np.exp(-(((t.x - sx - 16) / 26) ** 2 + ((t.y - y0 - 22) / 22) ** 2)))
    elif state == "claimed":
        t.paint(d, t.ramp("#12161F", "#07090E", (t.y - y0) / ROW_H))
        t.line(d, 1.0, "#2E3749", 0.95)
    else:
        t.paint(d, t.ramp("#232B3D", "#0B0E16", (t.y - y0) / ROW_H))
        t.line(d, 1.0, "#55607A", 0.9)
        t.paint(np.maximum(d, np.abs(t.y - (y0 + 1.4)) - 0.6), "#CFDBFF", 0.22)
    said(t, xl + lean / 2 + 14, y0 + 15, SMALL, words, "#7E879A" if state == "claimed" else IVORY)
    if state == "claimed":
        cx, cy = sx + 16, y0 + 22
        t.paint(circle(t, cx, cy, 8), "#39414F")
        t.stroke([(cx - 3.6, cy), (cx - 0.8, cy + 3), (cx + 4, cy - 3)], 1.8, "#B9C0CC")
        return
    t.image(hc.image(SHARD, 32, alpha=1.0 if state == "done" else 0.5), sx, y0 + 6)
    if state == "done":
        said(t, sx - 8, y0 + 15, SMALL, "Claim", READY, "RIGHT", bold=0.45)
    elif count:
        said(t, sx - 8, y0 + 15, SMALL, count, "#AEB7C2", "RIGHT")


def today_list(t, px0, py0, st):
    """The list in the glass: Back and "Today" at its head, the Ledger's way in at the right, then the rows."""
    t.stroke([(px0 + 22, py0 + 11), (px0 + 16, py0 + 17), (px0 + 22, py0 + 23)], 1.8, IVORY)
    said(t, px0 + 32, py0 + 11, TITLE, st.get("head", "Today"), IVORY)
    said(t, px0 + hc.PANEL[0] - 28, py0 + 12, SMALL, "Mask Ledger", "#AEB7C2", "RIGHT")
    x = px0 + hc.PANEL[0] - 22
    t.stroke([(x, py0 + 12), (x + 5, py0 + 17), (x, py0 + 22)], 1.6, "#AEB7C2")
    y = py0 + LIST_TOP
    for row in st["rows"]:
        if isinstance(row, str):                         # an earlier day's heading
            said(t, px0 + ROW_X[0] + 14, y + 4, SMALL, row, "#8F99A6")
            y += 22
            continue
        goal_row(t, px0, y, *row)
        y += ROW_H + ROW_GAP
    if st.get("thumb"):                                  # the list scrolls: its thumb
        a, b = st["thumb"]
        t.stroke([(px0 + hc.PANEL[0] - 5, py0 + LIST_TOP + a), (px0 + hc.PANEL[0] - 5, py0 + LIST_TOP + b)], 2.0, "#55607A")
    SPOTS.setdefault("rows", (px0 - 4, py0 - 4, px0 + hc.PANEL[0] + 4, py0 + hc.PANEL[1] + 4))


def today_cell(sheet, ox, oy, st):
    out, px0, py0, items = home_phone(st["mode"])
    rs.paste(sheet.px, out, round(ox * 2), round(oy * 2))
    sheet.items += [dict(i, x=i["x"] + ox, y=i["y"] + oy) for i in items]
    t = sheet.tile(ox, oy, W, H)
    if st["mode"] == "cards":
        slip(t, px0, py0, st["pips"], st.get("more", 0))
    elif st["mode"] == "card":
        today_card(t, sheet, ox, oy, px0, py0, st["pips"])
    else:
        today_list(t, px0, py0, st)


TODAY = [
    ("A, the slip: on the glass's top edge, gold while a goal waits to be claimed",
     dict(mode="cards", pips=("done", "open", "open"))),
    ("B, the card: Today in Settings' column, Settings a cog tile over it",
     dict(mode="card", pips=("done", "open", "open"))),
    ("A, nothing waiting: the slip quiet, one claimed, two open; two more banked",
     dict(mode="cards", pips=("claimed", "open", "open"), more=2)),
    ("B, nothing waiting",
     dict(mode="card", pips=("claimed", "open", "open"))),
    ("The list, from either: one done (the row is its claim), one counting, one open",
     dict(mode="list", rows=[("Keep a dare.", "done"), ("Break three shards.", "open", "1 / 3"),
                             ("Lead a run with someone new.", "open")])),
    ("All three claimed: the list rests until the day turns",
     dict(mode="list", rows=[("Keep a dare.", "claimed"), ("Break three shards.", "claimed"),
                             ("Lead a run with someone new.", "claimed")])),
    ("Banked days, scrolled: an earlier day's goals under its heading",
     dict(mode="list", thumb=(60, 132), rows=["Yesterday", ("Win three Tower floors.", "done"),
                                              ("Let every bay run a full hour.", "open", "0:42 / 1:00"), "Two days ago"])),
    ("The longest lines, with their counts",
     dict(mode="list", rows=[("Clear a stage on Hard.", "open"), ("Train a Voidkin for an hour.", "open", "0:15 / 1:00"),
                             ("Collect the Condenser's tray.", "open")])),
]
TODAY_NOTES = [
    "Home's glass is full at the smallest phone (three cards in 371 by 184), so today's three sit behind an entry, two",
    "ways for the pick. A: a slip on the glass's top edge with three pips; B: a Today card in Settings' column, the",
    "shard its picture, Settings a cog tile over it. Either turns gold while a goal waits to be claimed, and opens the",
    "same list in the glass: a leaning row a goal, its shard at the right. Open: the shard dim, a count where the goal",
    "counts. Done: the whole row is the claim's press, lit gold. Claimed: the row sinks and takes a check until the",
    "day turns. Banked days sit under their headings and the list scrolls (nine rows at most). \"Mask Ledger\" at the",
    "list's head is my proposal for the Ledger's way in. Rows 44 tall; A's slip is 26, its tap box reaching 18 over",
    "it; no word under 14. Stand-ins: the fight under Home, \"Claim\", the day headings, the counts.",
]


# --- the masks, flat ------------------------------------------------------------------------------------------------

def almond(cu, cv, a, b, n=9):
    rr = (a * a + b * b) / (2 * b)
    th = math.asin(a / rr)
    top = [(cu + rr * math.sin(x), cv + (rr - b) - rr * math.cos(x)) for x in np.linspace(-th, th, n)]
    low = [(cu + rr * math.sin(x), cv - (rr - b) + rr * math.cos(x)) for x in np.linspace(th, -th, n)]
    return top[:-1] + low[:-1]


def box_of(u0, v0, u1, v1):
    return [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]


def shape(kind):
    """A mask's cuts in its own axes, u right and v down, in studs from its middle: the models' numbers."""
    if kind == "Brawler":                                # stage_screen.mask, shade_sheet.mask "Brawler"
        face = []
        for i, k in enumerate(ss.BRAWLER):
            a = math.radians(15 + 30 * i)
            face.append((k * math.cos(a), -k * math.sin(a)))
            if i == 5:
                face += [(-1.26, -0.17), (-1.26, 0.15)]
            if i == 11:
                face += [(1.26, 0.17), (1.26, -0.15)]
        g = ss.GRIN
        low = [(0.02 + g * math.cos(a), -g * math.sin(a)) for a in np.radians(np.linspace(200, 340, 13))]
        v0 = low[0][1]
        grin = low + [(u, v0 + (v - v0) * 0.3) for u, v in reversed(low[1:-1])]
        c6, s6 = math.cos(math.radians(6)), math.sin(math.radians(6))
        grin = [(u * c6 + v * s6, -u * s6 + v * c6) for u, v in grin]
        teeth = []
        for x, w, dz, lean in ss.TEETH:
            cl, sl = math.cos(math.radians(lean)), math.sin(math.radians(lean))
            teeth.append([(x * g / 0.64 + p * cl - q * sl, 0.36 - dz + p * sl + q * cl)
                          for p, q in ((-w / 2, -0.25), (w / 2, -0.25), (w / 2, 0.25), (-w / 2, 0.25))])
        return dict(face=[face], cuts=[almond(-0.38, -0.22, 0.2, 0.125), almond(0.38, -0.22, 0.17, 0.105), grin],
                    teeth=teeth, dark=[], fold=[((0.06, -0.92), (0.03, 0.9))], ties=((-1.26, 0.0), (1.26, 0.0)), half=False)
    if kind == "Guard":                                  # shade_sheet.mask "Guard" (AR52): the brow is cut
        face = [(-0.9, 0.65), (-0.66, 0.9), (0.66, 0.9), (0.9, 0.65), (1.0, -0.9), (-1.0, -0.9)]
        tabs = [box_of(e * 1.0 - 0.12, -0.3, e * 1.0 + 0.12, 0.0) for e in (-1, 1)]
        eyes = [[(e * 0.08, -0.02), (e * 0.74, -0.02), (e * 0.74, -0.32), (e * 0.08, -0.13)] for e in (-1, 1)]
        return dict(face=[face, *tabs], cuts=[*eyes, box_of(-0.31, 0.47, 0.31, 0.57)], teeth=[], dark=[],
                    fold=[((-0.93, 0.28), (0.93, 0.28))], ties=((-1.12, -0.15), (1.12, -0.15)), half=False)
    if kind == "Dasher":                                 # shade_sheet.mask "Dasher" (AR52): a kite folded once
        face = [(-0.64, -0.58), (0.0, 1.7), (0.64, -0.58), (0.0, -1.7)]
        eyes = [[(e * 0.08, -0.2), (e * 0.5, -0.46), (e * 0.52, -0.7), (e * 0.08, -0.4)] for e in (-1, 1)]
        return dict(face=[face], cuts=eyes, teeth=[], dark=[], fold=[((0.0, -1.62), (0.0, 1.62))],
                    ties=((-0.6, -0.6), (0.6, -0.6)), half=True)
    face = []                                            # the Lamplighter's: lamplighter_sheet.mask_lantern
    for i in range(36):
        a = 2 * math.pi * i / 36
        u = 0.8 * math.copysign(abs(math.cos(a)) ** (2 / 2.6), math.cos(a))
        z = 1.08 * math.copysign(abs(math.sin(a)) ** (2 / 2.6), math.sin(a))
        face.append((u, -max(-0.9, min(0.92, z))))
    eyes = []
    for e in (-1, 1):
        outer = [(e * 0.36 + 0.24 * math.cos(a), -(0.16 + 0.24 * math.sin(a))) for a in np.radians(np.linspace(200, 340, 9))]
        inner = [(e * 0.36 + 0.22 * math.cos(a), -(0.25 + 0.22 * math.sin(a))) for a in np.radians(np.linspace(336, 204, 9))]
        eyes.append(outer + inner)
    mouth = [(0.085 * math.cos(a), 0.36 + 0.085 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 13)[:-1]]
    hoops = [box_of(-0.58, v - 0.085, 0.58, v + 0.085) for v in (-0.97, 0.97)]
    ribs = [(box_of(-0.56, v - 0.022, 0.56, v + 0.022), "#4A3F58") for v in (-0.62, 0.62)]
    return dict(face=[face, *hoops], cuts=[*eyes, mouth], teeth=[], dark=[*((h, "#221A2C") for h in hoops), *ribs],
                fold=[], ties=((-0.8, 0.0), (0.8, 0.0)), half=False)


def kind_mask(t, kind, cx, cy, r, lit, hook=None, tilt=0.0):
    """A kind's mask, its middle at (cx, cy), `r` points a stud. Lit: the paper, its cuts full of warm white light,
    which stays inside them. Unlit: the paper gone dark in a thin rim, the page showing through its cuts. With `hook`
    it hangs: its two strings up to a knot on a hook, the knot's two tails falling."""
    s = shape(kind)
    ca, sa = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))

    def at(p):
        return (cx + (p[0] * ca - p[1] * sa) * r, cy + (p[0] * sa + p[1] * ca) * r)

    def poly(pts):
        return t.poly([at(p) for p in pts])
    out = np.minimum.reduce([poly(f) for f in s["face"]])
    cuts = np.minimum.reduce([poly(c) for c in s["cuts"]])
    holes = cuts                                         # the cuts' outline, the teeth not counted
    if s["teeth"] and r * ui.K >= 14:                     # the teeth are paper tabs left in the grin's cut
        cuts = np.maximum(cuts, -np.minimum.reduce([poly(c) for c in s["teeth"]]))
    if hook is not None:
        hx, hy = hook
        string = PAPER_SHADE if lit else P["faint"]
        for p in s["ties"]:
            t.stroke([(hx, hy), at(p)], max(0.9, r * 0.03), string, 0.95 if lit else 0.7)
        for e in (-1, 1):
            t.stroke([(hx, hy), (hx + e * r * 0.1, hy + r * 0.34)], max(1.0, r * 0.045), PAPER if lit else P["faint"],
                     1.0 if lit else 0.7)
        up.box(t, hx - r * 0.1, hy - r * 0.06, hx + r * 0.1, hy + r * 0.07, PAPER if lit else P["faint"], cut=1.0)
        metal = P["facet"] if lit else P["edge"]
        t.stroke([(hx, hy - r * 0.07), (hx, hy - r * 0.3)], max(1.2, r * 0.05), metal)
        t.stroke([(hx - r * 0.13, hy - r * 0.3), (hx + r * 0.13, hy - r * 0.3)], max(1.2, r * 0.05), metal)
    rim = out - 0.06 * r
    if not lit:
        t.paint(np.maximum(rim, -cuts), UNLIT)
        t.paint(np.abs(rim) - 0.5, P["faint"], 0.9)
        t.paint(np.abs(holes) - 0.4, P["faint"], 0.5)
        for pts, _colour in s["dark"]:                   # the lantern's hoops and ribs stay drawn, so it hangs as a lantern
            t.paint(np.abs(poly(pts)) - 0.4, P["faint"], 0.7)
        return
    t.paint(rim, PAPER_SHADE)
    t.paint(out, PRESSED)
    front = out + 0.1 * r
    t.paint(front, t.ramp(PAPER, PRESSED, (t.y - cy + 1.2 * r) / (3.0 * r)))
    if s["half"]:                                        # folded once: the far half a step down
        u = ((t.x - cx) * ca + (t.y - cy) * sa)
        t.paint(np.maximum(out, -u), PAPER_SHADE, 0.4)
    for a, b in s["fold"]:
        t.stroke([at(a), at(b)], max(0.6, r * 0.014), PAPER_SHADE, 0.75)
    for pts, colour in s["dark"]:
        t.paint(poly(pts), colour)
    t.paint(cuts, GLOW)
    t.paint(cuts, "#FFFFFF", 0.6 * np.clip(-cuts / max(0.05 * r, 0.5), 0, 1))


# --- the Ledger's page ----------------------------------------------------------------------------------------------

KINDS = ("Brawler", "Guard", "Dasher", "Lamplighter")
NAMES = {"Brawler": "The Brawler", "Guard": "The Guard", "Dasher": "The Dasher", "Lamplighter": "The Lamplighter"}
TILTS = {"Brawler": -3.0, "Guard": 2.0, "Dasher": -2.0, "Lamplighter": 1.5}
SAID = {
    "Brawler": ("Round masks sold out first. Everyone wanted to grin that night.",
                "The grin is painted on. Most of the ones under it were scared.",
                "By dawn they're home, still grinning, with no idea why."),
    "Guard": ("Square masks were for the ones who came to watch, not to dance.",
              "A Guard holds its shield the way they'd hold a shutter in the rain.",
              "They wake on the curb with sore arms, sure they'd been holding something up."),
    "Dasher": ("The pointed masks were the runners'. They raced the lantern carts every year.",
               "The Void keeps what it finds. In a runner, it found the start line.",
               "They come to on the far side of the street, out of breath, and laugh without knowing why."),
    "Lamplighter": ("Someone has to light the lanterns. For forty years, it was them.",
                    "The Void came in through the last lantern they lit.",
                    "They light the row again each evening, and never ask why the last lantern sticks."),
}
STEPS = {False: (10, 100, 1000), True: (1, 10, 100)}     # a Shade kind's counts; the keeper's


def ledger(t, st):
    kind, count, counts = st["kind"], st["count"], st["counts"]
    lit = count > 0
    whole = t.poly([(0, 0), (W, 0), (W, H), (0, H)])
    t.paint(whole, t.ramp(sm.GROUND[0], sm.GROUND[1], t.y / H))
    t.paint(whole, P["glint"], 0.06 * np.exp(-t.y / 40))
    # the band: Roblox's buttons, Back, the page's name, and Next
    sm.stand_in(t)
    t.text(196, 22, SMALL, "<  BACK", P["text"], "CENTER", bold=0.3)
    t.stroke([(178, 44), (214, 44)], 1.4, sm.LIGHT, 0.8)
    t.text(232, 20, TITLE, "Mask Ledger", P["text"], bold=0.35)
    sm.quiet_plate(t, 338, 7, W - 7, 51, P["facet"])
    t.text(347, 22, SMALL, "Next", P["faint"], bold=0.3)
    for k, words in enumerate(st["next"]):
        t.text(384, 13 + k * 18, SMALL, words, P["text"] if k == 0 else P["soft"])
    # the rail: a tile a kind, its mask small, lit once one has fallen
    for k, name in enumerate(KINDS):
        y0 = 65 + k * 62.5
        chosen = name == kind
        if chosen:
            d = t.poly(ui.cut_box(7, y0, 67, y0 + 58, 5, 5, 5, 5))
            t.glow(d, 5.0, P["lit"][1], 0.35)
            t.paint(d, up.shade(t, P["card"], y0, y0 + 58))
            t.line(d, 1.4, sm.LIGHT, 0.95)
        else:
            up.box(t, 7, y0, 67, y0 + 58, P["well"], P["edge"], 1.0, 5)
        kind_mask(t, name, 37, y0 + 29, {"Dasher": 13.0, "Guard": 17.0}.get(name, 16.0), counts[name] > 0)
    # the mask, hung
    mx, my = 160, 166
    sm.glass(t, 73, 65, 247, 313, False, 8, 1.2)
    panel = t.poly(ui.cut_box(73, 65, 247, 313, 8, 8, 8, 8))
    if lit:                                              # a lantern's pool on the wall behind it
        t.paint(panel, "#FFDFA6", 0.36 * np.exp(-(((t.x - mx) / 70) ** 2 + ((t.y - my + 6) / 86) ** 2)))
    else:
        t.paint(panel, P["channel"], 0.3)
    r = 40.0
    kind_mask(t, kind, mx, my + (10 if kind == "Dasher" else 0), r, lit, hook=(mx, 86), tilt=TILTS[kind])
    t.text(mx, 262, TITLE, NAMES[kind], P["text"] if lit else P["soft"], "CENTER", bold=0.35)
    number = f"{count:,}"
    label = "knocked loose"
    wide = ss.wide_of(number, TITLE) + 6 + ss.wide_of(label, SMALL) * 0.9
    t.text(mx - wide / 2, 286, TITLE, number, P["text"] if lit else P["faint"], bold=0.35)
    t.text(mx - wide / 2 + ss.wide_of(number, TITLE) + 6, 288, SMALL, label, P["soft"] if lit else P["faint"])
    # its three lines, as they're reached
    sm.glass(t, 253, 65, W - 7, 313, False, 8, 1.2)
    steps = STEPS[kind == "Lamplighter"]
    for k, (need, words) in enumerate(zip(steps, SAID[kind])):
        y0 = 73 + k * 79
        reached = count >= need
        mark = f"{need:,}"
        bw = 46
        if reached:
            d = t.poly(ui.cut_box(263, y0 + 2, 263 + bw, y0 + 24, 4, 4, 4, 4))
            t.paint(d, up.shade(t, sk.SOCKET_DARK, y0 + 2, y0 + 24))
            t.line(d, 1.2, PAPER_SHADE)
            t.text(263 + bw / 2, y0 + 7, SMALL, mark, PAPER, "CENTER", bold=0.3)
            for j, line in enumerate(wrap(words, 33)):
                t.text(320, y0 + 6 + j * 18, SMALL, line, P["text"])
        else:
            up.box(t, 263, y0 + 2, 263 + bw, y0 + 24, P["well"], P["edge"], 1.0, 4)
            t.text(263 + bw / 2, y0 + 7, SMALL, mark, P["faint"], "CENTER", bold=0.3)
            road = t.poly(ui.cut_box(320, y0 + 10, W - 19, y0 + 16, 2, 2, 2, 2))
            t.paint(road, P["channel"])
            t.line(road, 1.0, P["edge"], 0.9)
            first = k == 0 or count >= steps[k - 1]
            if first and count > 0:
                sm.fill(t, 321, 321 + (W - 20 - 321) * count / need, y0 + 13, 1.6, sm.ACC[False], W - 20)
        if k < 2:
            t.stroke([(263, y0 + 75), (W - 17, y0 + 75)], 1.0, P["edge"], 0.6)


def ledger_cell(sheet, ox, oy, st):
    ledger(sheet.tile(ox, oy, W, H), st)


LEDGER = [
    ("The Brawler at 37: lit, its first line, the road to the second",
     dict(kind="Brawler", count=37, counts=dict(Brawler=37, Guard=0, Dasher=4, Lamplighter=0),
          next=("Raise the base to level 2.", "It opens the third bay."))),
    ("The Guard, none fallen yet: unlit, the page waiting",
     dict(kind="Guard", count=0, counts=dict(Brawler=37, Guard=0, Dasher=4, Lamplighter=0),
          next=("Raise the base to level 2.", "It opens the third bay."))),
    ("The Dasher at 1,204: all three lines",
     dict(kind="Dasher", count=1204, counts=dict(Brawler=2310, Guard=1420, Dasher=1204, Lamplighter=31),
          next=("Climb to Tower floor 25.", "It opens the next ground."))),
    ("The Lamplighter at 1: the keeper's counts are 1, 10 and 100",
     dict(kind="Lamplighter", count=1, counts=dict(Brawler=412, Guard=180, Dasher=96, Lamplighter=1),
          next=("The Lamplighter, on Hard.", "It opens base level 3."))),
]
LEDGER_NOTES = [
    "A Seam page. The kind's mask hangs from a hook by its own strings, a little off true, the knot's tails falling:",
    "an object left behind, nobody behind it. Unlit until the first one falls: the paper dark in a thin rim, the page",
    "showing through its cuts. Lit after: the paper, its cuts full of warm white light that stays inside them, and a",
    "lantern's pool on the wall behind. Each mask is its model's own cuts. Under it, its name and count; at the right",
    "its three lines, each appearing at its count, the next one's road filling. Nothing is marked on a mask for the",
    "count. The rail's small masks light the same way. Next sits in the band. Stand-ins, research's to write: the",
    "count's label (\"knocked loose\" here), each Next line and what it opens. No tap under 44, no word under 14.",
]


# --- the sheets -----------------------------------------------------------------------------------------------------

def small(out, groups):
    """Every phone at 64 pixels high, over dark."""
    gap, scale = 12, 64 / (H * 2)
    sw = round(W * 2 * scale)
    most = max(len(g) for g in groups)
    page = rs.canvas(gap + most * (sw + gap), gap + len(groups) * (64 + gap), tuple(rs.rgb("#101117")))
    for r, shots in enumerate(groups):
        for k, shot in enumerate(shots):
            rs.paste(page, rs.shrink(shot, scale), gap + k * (sw + gap), gap + r * (64 + gap))
    rs.save(page, out / "goals_small.png")


def pictures(out, crops):
    """For the content check: each mask hung, lit and unlit, large and at 64 pixels over dark; the tag's three states;
    then the drawn pieces at twice the phone's pixels."""
    ui.K = 2
    cw, ch, gap = 190, 250, 14
    wide = gap + 4 * (cw + gap)
    doubled = [np.repeat(np.repeat(c, 2, axis=0), 2, axis=1) for c in crops]
    below = sum(c.shape[0] / 2 + gap + 22 for c in doubled)
    sheet = ui.Sheet(max(wide, max(c.shape[1] for c in doubled) / 2 + 2 * gap), 60 + 2 * (ch + gap) + 100 + 150 + below, "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 16, 20, "AR53, the Ledger's masks and the dare's tag: lit and unlit, large, then at 64 pixels", "#EDE6D6", bold=0.2)
    cells = []
    for row, lit in enumerate((True, False)):
        for k, kind in enumerate(KINDS):
            x, y = gap + k * (cw + gap), 56 + row * (ch + gap)
            up.box(t, x, y, x + cw, y + ch, sm.TILE, P["edge"], 1.0, 6)
            kind_mask(t, kind, x + cw / 2, y + ch / 2 + (22 if kind == "Dasher" else 14), 52.0, lit, hook=(x + cw / 2, y + 26),
                      tilt=TILTS[kind])
            cells.append((x, y))
    y = 56 + 2 * (ch + gap)
    scale = 64 / (ch * 2)
    for k, (x, cy) in enumerate(cells):
        part = sheet.px[round(cy * 2):round((cy + ch) * 2), round(x * 2):round((x + cw) * 2)]
        rs.paste(sheet.px, rs.shrink(part, scale), round((gap + k * 60) * 2), round((y + 8) * 2))
    t.text(gap, y + 46, SMALL, "each at 64 pixels high: lit, then unlit", "#B4AC9C")
    y += 100
    for k, state in enumerate(("lit", "kept", "dark")):
        x = gap + k * 150
        up.box(t, x, y, x + 136, y + 130, sm.TILE, P["edge"], 1.0, 6)
        tag(t, x + 60, y + 12, 78, state)
        tag(t, x + 114, y + 40, 16, state)
        t.text(x + 8, y + 112, SMALL, {"lit": "the dare holds", "kept": "kept", "dark": "broken"}[state], "#B4AC9C")
    y += 150
    for c, name in zip(doubled, ("the dare unfolded under the line", "\"Dare kept\" on the card's time row", "the list's rows")):
        t.text(gap, y + 2, SMALL, f"{name}, at twice the phone's pixels", "#B4AC9C")
        rs.paste(sheet.px, c, round(gap * 2), round((y + 22) * 2))
        y += c.shape[0] / 2 + gap + 22
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "goals_pictures.png")


def crop(shot, box):
    x0, y0, x1, y1 = (round(v * 2) for v in box)
    return shot[max(y0, 0):y1, max(x0, 0):x1].copy()


def main():
    out = bl.out_dir()
    rs.OUT = out
    ss.ICONS["keeper_chest"] = ss.ICONS["keeper_chest"]
    common = "at the smallest phone (568 x 320 points)"
    lines = ss.sheet_of(out, "goals_dare_line.png", f"AR53, the dare on the run's line, {common}", LINES, LINE_H,
                        LINE_NOTES, line_cell)
    cards = ss.sheet_of(out, "goals_dare_card.png", f"AR53, the dare on the run's card, {common}", CARDS, H, CARD_NOTES,
                        card_cell)
    for said_, st in CARDS:
        print(f"card: {st['tall']:.0f} of {H - ss.BAND} points tall, its time row {st.get('row', 0):.0f} of 320: {said_}")
    today = ss.sheet_of(out, "goals_today.png", f"AR53, today's three on Home's panel, {common}", TODAY, H, TODAY_NOTES,
                        today_cell)
    pages = ss.sheet_of(out, "goals_ledger.png", f"AR53, the Mask Ledger's page, {common}", LEDGER, H, LEDGER_NOTES,
                        ledger_cell)
    small(out, (cards, today[:4], today[4:], pages))
    pictures(out, [crop(lines[0], SPOTS["line"]), crop(cards[0], SPOTS["chip"]), crop(today[4], SPOTS["rows"])])


if __name__ == "__main__":
    main()
