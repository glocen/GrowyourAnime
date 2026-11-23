"""AR53, the goals' look, basic at launch (Modulo, 2026-11-23): the sheets, and the cut for TR54.

Three layers (docs/design.md, "Goals"; docs/test-requests.md, TR54), each in the make of the screen it joins:
    the dare        on the run's line under Roblox's top bar (stage_seam.py's line, as StageController builds it) and on
                    the run's card, in Seam's lit glass. The game has no start card: a run is four stretches under one
                    line, so a stretch's dare unfolds under that line as the stretch starts, then folds to a paper tag
                    hung from the line. The tag is the dare's mark: lit while the dare holds, dark once it's broken,
                    and on the card it hangs from the road after each stretch whose dare was kept. "Dare kept" carries
                    the forge stone in the kit's item cell, as the Forge draws it. A dare kept before a fall is paid,
                    so the fall's card shows its tags and its chip too.
    today's three   on Home's panel (home_cards.py, AR49's glass and leaning cards): a Today card in Settings' column
                    with Settings a cog tile over it (research's pick, B). It opens the list in the glass: a leaning
                    row a goal, its shard at the right.
    the Ledger      a Seam page: the kind's mask hung from a hook by its own strings, unlit until the first one falls,
                    its count, its three lines as they're reached, and Next on a plate over both panels.

The masks are the models' own cuts, flat: the Brawler's as stage_screen.mask, the Guard's and the Dasher's from
shade_sheet.mask (AR52), the Lamplighter's from lamplighter_sheet.mask_lantern. The content check's conditions on the
words and the plan (2026-11-23, 15:31) are drawn in: an unlit mask is dark paper in a thin rim, its holes painted at
the page's value (never see-through: the cut's own check); a lit one keeps its light inside its cuts, warm white, never a type's colour; each is a hung object
with its strings, knot, tails and hook; nothing is marked on a mask for its count; the tag is blank. The baked check
(17:41) let the Lamplighter's closed crescents stand as the model's own, the keeper's only, and asked that its hoops and
ribs stay drawn unlit.

Measured in points at the smallest phone (568 x 320), two pixels a point. Every new piece of art is drawn once as an
image at 4 pixels a point (cut_pieces), and the sheets are laid from those images as the game lays them. The words are
TR54's; widths are the sheet's face, not the game's.

    blender -b --factory-startup --python tools/blender/goals_look.py -- <abs out>
    blender -b --factory-startup --python tools/blender/goals_look.py -- <abs build/handoff/UI/goals> cut

Writes:
    goals_dare_line.png     the run's line: a stretch's start, the tag lit, dark and kept, Hard, the keeper
    goals_dare_card.png     the run's card: dares kept, the first clear, none kept, a fall with one kept, a fall
    goals_today.png         Home: the Today card waiting and at rest, then the list's states
    goals_ledger.png        the Ledger's page: a kind lit, unlit, full, and the keeper's twice
    goals_small.png         every phone at 64 pixels high
    goals_pictures.png      for the content check: each mask lit and unlit, large and at 64 pixels; the tag's three states
    goals_unlit.png         for the content check: the unlit masks' files on the page's dark and on white
With `cut`, in place of the last two:
    images/*.png            the cut: the tag, the Today card and the cog tile, the pips, the rows, the masks, the pool
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
GLOW = "#FFF6E2"                       # a mask's light and the tag's: the Shade's warm white, never a type's colour
UNLIT = "#120F22"                      # an unlit mask's paper: darker than the page, so its holes read lighter
THROUGH = "#221C40"                    # its cuts: painted at the page's value where it hangs, never see-through, so
                                       # the file reads as dark paper with dim holes on any ground (the cut's content
                                       # check: a see-through cut shows white on a light ground)
READY = sm.READY
IVORY = hc.IVORY
STONE = up.UPG / "StoneLow.png"
SHARD = ss.ICONS["shards"]
LINE_H = 150
SPOTS = {}                             # a few drawn boxes, in a phone's points, for the pictures sheet
CUT_K = 4                              # the cut's pixels a point, the kit's
PIECES = {}                            # the cut's images by name: px, box (its own points), tint, use
HANDOFF = up.REPO / "build" / "handoff" / "UI" / "goals"


def piece(name, box, draw, tint=None, use=""):
    """One image of the cut, drawn alone at 4 pixels a point on transparency. `box` is in the piece's own points, from
    its own origin (a tag's knot, a mask's middle, Home's glass's top left). Its last 3 points fade to nothing, so a
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


TAG = 16.0                             # the tag's image: this tall, its knot the origin
TAGS = {"lit": "DareTag", "kept": "DareTagKept", "dark": "DareTagDark"}


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
        lay(t, TAGS[st["tag"]], x0 + 20, y0 + 44)
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
        lay(t, "DareTag", x0 + 21, y0 + 46, 14 / TAG)
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

KEPT_W = ss.wide_of("Dare kept", SMALL) * 0.9


CELL = 26.0                            # the chip's stone: the kit's Common item cell, the size Reinforce draws it


def dare_wide(n):
    return 19 + KEPT_W + 6 + CELL + 4 + ss.wide_of(f"+{n}", TITLE) + 7


def dare_chip(t, x, y, n):
    """"Dare kept" on the time's row: the tag, the words, and the forge stone the kept dares paid, with how many. The
    stone is the Forge's own (research's must-fix 1): its picture in the kit's Common item cell with the cell's
    hairline, as Reinforce draws it under its ring, standing 2 points over the chip's top and foot."""
    wide = dare_wide(n)
    d = t.poly(ui.cut_box(x, y, x + wide, y + 22, 4, 4, 4, 4))
    t.glow(d, 5.0, GLOW, 0.22)
    t.paint(d, up.shade(t, sk.SOCKET_DARK, y, y + 22))
    t.line(d, 1.2, PAPER_SHADE)
    lay(t, "DareTagKept", x + 10, y + 1.5, 13 / TAG)
    t.text(x + 19, y + 4, SMALL, "Dare kept", PAPER, bold=0.3)
    sx = x + 19 + KEPT_W + 6
    stone = up.cell(t, sx, y - 2, CELL, "Common", STONE)
    t.line(stone, 1.0, up.P["edge"])
    t.text(sx + CELL + 4, y + 3, TITLE, f"+{n}", P["text"], bold=0.3)
    SPOTS.setdefault("chip", (x - 8, y - 8, x + wide + 8, y + 30))


def card(t, st):
    """The run's card (StageScreen.Results, stage_seam.results) with the dares: a tag hung from the road after each
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
                lay(t, "DareTagKept", x0 + 22 + (k - 1) * step + 26 + tab + 7, y + h / 2 + 2, 15 / TAG)
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
    "The run's card, as built, with the dares. A tag hangs from the road after",
    "each stretch whose dare was kept, so the four marks say which. \"Dare kept\"",
    "sits on the time's row in the paper's warm edge, with the forge stone those",
    "dares paid: the Forge's own stone, in the kit's item cell as Reinforce draws",
    "it, and how many. No new row on a win: the first clear's card already stands",
    "254 of the 262 points under Roblox's bar. A dare kept before a fall is paid",
    "(research, 17:49), so the fall's card hangs its tags too and gives the chip",
    "a row of its own. None kept, nothing is said and the card is today's.",
    "Stand-ins: the times, what the run gave, the presses, the street.",
]


# --- today's three, on Home's panel ---------------------------------------------------------------------------------

HOME = {}
ROW_H, ROW_GAP, LIST_TOP = 44.0, 4.0, 32.0
ROW_X = (10.0, 352.0)                  # a row's foot, in the glass's points
ROW_W = ROW_X[1] - ROW_X[0]
COG = (hc.TOP, hc.TOP + 44.0)          # Settings' cog tile: its top and foot, in the glass's points
TODAY_Y = (hc.TOP + 50.0, hc.FOOT)     # the Today card's
PIPS = {"open": "GoalPipOpen", "done": "GoalPipDone", "claimed": "GoalPipClaimed"}
ROWS = {"open": "GoalRow", "done": "GoalRowDone", "claimed": "GoalRowClaimed"}


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


def goal_row(t, px0, y0, words, state, count=None):
    """A goal: a leaning row in the glass, its words, and at its right its shard. Open, the shard waits dim; done, the
    row is the claim's press, lit gold; claimed, it sinks and takes a check."""
    xl = px0 + ROW_X[0]
    lean = hc.LEAN * ROW_H
    sx = xl + ROW_W - 40 + lean / 2
    lay(t, ROWS[state], xl, y0)
    said(t, xl + lean / 2 + 14, y0 + 15, SMALL, words, "#7E879A" if state == "claimed" else IVORY)
    if state == "claimed":
        lay(t, "GoalCheck", sx + 16, y0 + 22)
        return
    t.image(hc.image(SHARD, 32, alpha=1.0 if state == "done" else 0.5), sx, y0 + 6)
    if state == "done":
        said(t, sx - 8, y0 + 15, SMALL, "Claim", READY, "RIGHT", bold=0.45)
    elif count:
        said(t, sx - 8, y0 + 15, SMALL, count, "#AEB7C2", "RIGHT")


def today_list(t, px0, py0, st):
    """The list in the glass: Back and "Today" at its head, the Ledger's one way in at the right, then the rows."""
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
    if st["mode"] == "card":
        today_card(t, px0, py0, st["pips"])
    else:
        today_list(t, px0, py0, st)


TODAY = [
    ("The Today card, a goal waiting to be claimed: its rim and glow in gold",
     dict(mode="card", pips=("done", "open", "open"))),
    ("Nothing waiting: one claimed, two open",
     dict(mode="card", pips=("claimed", "open", "open"))),
    ("The list: one done (the row is its claim), one counting, one open",
     dict(mode="list", rows=[("Keep a dare.", "done"), ("Break three shards.", "open", "1 / 3"),
                             ("Lead a run with someone new.", "open")])),
    ("All three claimed: the list rests until the day turns",
     dict(mode="list", rows=[("Keep a dare.", "claimed"), ("Break three shards.", "claimed"),
                             ("Lead a run with someone new.", "claimed")])),
    ("Banked days, scrolled: an earlier day's goals under its heading",
     dict(mode="list", thumb=(60, 132), rows=["Yesterday", ("Win three Tower floors.", "done"),
                                              ("Let every bay run a full hour.", "open", "0:42 / 1:00"), "Two days ago"])),
    ("The longest lines, with their counts",
     dict(mode="list", rows=[("Knock the Lamplighter's mask loose.", "open"),
                             ("Train a Voidkin for an hour.", "open", "0:15 / 1:00"),
                             ("Collect the Condenser's tray.", "open")])),
]
TODAY_NOTES = [
    "Research's pick, B: today's three sit behind a Today card in Settings' column, the shard its picture (what waits",
    "there), three pips for the three goals; Settings is a cog tile over it, 44 tall. The card's rim and glow turn gold",
    "while a goal waits to be claimed. It opens the list in the glass: a leaning row a goal, its shard at the right.",
    "Open: the shard dim, a count where the goal counts. Done: the whole row is the claim's press, lit gold. Claimed:",
    "the row sinks and takes a check until the day turns. Banked days sit under their headings and the list scrolls",
    "(nine rows at most). \"Mask Ledger\" at the list's head is the Ledger's one way in. Rows 44 tall; no word under",
    "14. The words are TR54's. Stand-ins: the fight under Home, the counts.",
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
    which stays inside them. Unlit: the paper gone dark in a thin rim, its cuts painted as dim as the page. With `hook`
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
        t.paint(rim, UNLIT)
        t.paint(cuts, THROUGH)
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
PAGE_R = {"Brawler": 36.0, "Guard": 36.0, "Dasher": 30.0, "Lamplighter": 36.0}   # the hung mask: points a stud
RAIL_R = {"Brawler": 16.0, "Guard": 17.0, "Dasher": 13.0, "Lamplighter": 16.0}   # the rail's
DROP = 72.0                            # the hung mask's middle under its knot
DROPS = {"Dasher": 68.0}               # the kite is the tallest: it hangs a little shorter, clear of its name
HUNG = (-58, -18, 58, 134)             # the hung mask's image, from its knot
MARK = (-27, -27, 27, 27)              # the rail's, from its middle
POOL = (-87, -102, 87, 102)            # the lantern's pool on the wall, from its middle
RAIL = dict(x=(7, 67), top=65, pitch=62.5, tall=58)
NEXT = (73, 65, W - 7, 105)            # the page's boxes, in the phone's points
WALL = (73, 111, 247, 313)
SAYS = (253, 111, W - 7, 313)
HOOK = (160, 130)
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
NEXTS = [                                                # TR54's Next lines: the step, then what it opens
    ("Knock the Lamplighter's mask loose.", "Hard opens on Lantern Row."),
    ("Raise the base to level 2.", "A third bay opens, and the Condenser wakes."),
    ("Knock the Lamplighter's mask loose on Hard.", "The first time, its chest holds a Rare or better."),
    ("Raise the base to level 3.", "A fourth bay opens, and machines can climb to level 30."),
    ("Climb the Tower to floor 25.", "Each floor past your record pays a first-time bonus."),
    ("Drum Court's gate stays shut, for now.",),
]


def mask_name(kind, lit, hung):
    return ("LedgerMask" if hung else "LedgerMark") + kind + ("" if lit else "Unlit")


def pool(t):
    """A lantern's pool on the wall behind a lit mask: white, for the game to tint."""
    near = np.clip((POOL[2] - np.abs(t.x)) / 16, 0, 1) * np.clip((POOL[3] - np.abs(t.y)) / 16, 0, 1)
    ui.over(t.px, ui.WHITE, np.exp(-((t.x / 62) ** 2 + (t.y / 74) ** 2)) * near * near * (3 - 2 * near))


def ledger(t, st):
    kind, count, counts = st["kind"], st["count"], st["counts"]
    lit = count > 0
    whole = t.poly([(0, 0), (W, 0), (W, H), (0, H)])
    t.paint(whole, t.ramp(sm.GROUND[0], sm.GROUND[1], t.y / H))
    t.paint(whole, P["glint"], 0.06 * np.exp(-t.y / 40))
    # the band: Roblox's buttons, Back and the page's name
    sm.stand_in(t)
    t.text(196, 22, SMALL, "<  BACK", P["text"], "CENTER", bold=0.3)
    t.stroke([(178, 44), (214, 44)], 1.4, sm.LIGHT, 0.8)
    t.text(232, 20, TITLE, "Mask Ledger", P["text"], bold=0.35)
    # Next: the account's one next step and what it opens, a quiet plate over both panels
    sm.quiet_plate(t, *NEXT, P["facet"])
    words = NEXTS[st["next"]]
    t.text(NEXT[0] + 12, NEXT[1] + 14, SMALL, "Next", P["faint"], bold=0.3)
    for k, line in enumerate(words):
        t.text(NEXT[0] + 52, NEXT[1] + (6 + k * 17 if len(words) > 1 else 14), SMALL, line, P["text"] if k == 0 else P["soft"])
    # the rail: a tile a kind, its mask small, lit once one has fallen
    for k, name in enumerate(KINDS):
        y0 = RAIL["top"] + k * RAIL["pitch"]
        x0, x1 = RAIL["x"]
        if name == kind:
            d = t.poly(ui.cut_box(x0, y0, x1, y0 + RAIL["tall"], 5, 5, 5, 5))
            t.glow(d, 5.0, P["lit"][1], 0.35)
            t.paint(d, up.shade(t, P["card"], y0, y0 + RAIL["tall"]))
            t.line(d, 1.4, sm.LIGHT, 0.95)
        else:
            up.box(t, x0, y0, x1, y0 + RAIL["tall"], P["well"], P["edge"], 1.0, 5)
        lay(t, mask_name(name, counts[name] > 0, False), (x0 + x1) / 2, y0 + RAIL["tall"] / 2)
    # the mask, hung
    mx, hy = HOOK
    sm.glass(t, *WALL, False, 8, 1.2)
    if lit:                                              # a lantern's pool on the wall behind it
        lay(t, "LedgerPool", mx, hy + DROP - 6, tint="#FFDFA6", alpha=0.36)
    else:
        t.paint(t.poly(ui.cut_box(*WALL, 8, 8, 8, 8)), P["channel"], 0.3)
    lay(t, mask_name(kind, lit, True), mx, hy)
    t.text(mx, WALL[3] - 49, TITLE, NAMES[kind], P["text"] if lit else P["soft"], "CENTER", bold=0.35)
    number = f"{count:,}"
    label = "knocked loose"
    wide = ss.wide_of(number, TITLE) + 6 + ss.wide_of(label, SMALL) * 0.9
    t.text(mx - wide / 2, WALL[3] - 26, TITLE, number, P["text"] if lit else P["faint"], bold=0.35)
    t.text(mx - wide / 2 + ss.wide_of(number, TITLE) + 6, WALL[3] - 24, SMALL, label, P["soft"] if lit else P["faint"])
    # its three lines, as they're reached
    sm.glass(t, *SAYS, False, 8, 1.2)
    steps = STEPS[kind == "Lamplighter"]
    bx, tx, bw = SAYS[0] + 10, SAYS[0] + 67, 46
    for k, (need, words) in enumerate(zip(steps, SAID[kind])):
        y0 = SAYS[1] + 6 + k * 66
        reached = count >= need
        mark = f"{need:,}"
        if reached:
            d = t.poly(ui.cut_box(bx, y0 + 2, bx + bw, y0 + 24, 4, 4, 4, 4))
            t.paint(d, up.shade(t, sk.SOCKET_DARK, y0 + 2, y0 + 24))
            t.line(d, 1.2, PAPER_SHADE)
            t.text(bx + bw / 2, y0 + 7, SMALL, mark, PAPER, "CENTER", bold=0.3)
            for j, line in enumerate(wrap(words, 38)):
                t.text(tx, y0 + 5 + j * 17, SMALL, line, P["text"])
        else:
            up.box(t, bx, y0 + 2, bx + bw, y0 + 24, P["well"], P["edge"], 1.0, 4)
            t.text(bx + bw / 2, y0 + 7, SMALL, mark, P["faint"], "CENTER", bold=0.3)
            road = t.poly(ui.cut_box(tx, y0 + 10, W - 19, y0 + 16, 2, 2, 2, 2))
            t.paint(road, P["channel"])
            t.line(road, 1.0, P["edge"], 0.9)
            first = k == 0 or count >= steps[k - 1]
            if first and count > 0:
                sm.fill(t, tx + 1, tx + 1 + (W - 20 - tx - 1) * count / need, y0 + 13, 1.6, sm.ACC[False], W - 20)
        if k < 2:
            t.stroke([(bx, y0 + 61), (W - 17, y0 + 61)], 1.0, P["edge"], 0.6)


def ledger_cell(sheet, ox, oy, st):
    ledger(sheet.tile(ox, oy, W, H), st)


LEDGER = [
    ("The Brawler at 37: lit, its first line, the road to the second",
     dict(kind="Brawler", count=37, counts=dict(Brawler=37, Guard=0, Dasher=4, Lamplighter=2), next=1)),
    ("The Guard, none fallen yet: unlit, the page waiting",
     dict(kind="Guard", count=0, counts=dict(Brawler=37, Guard=0, Dasher=4, Lamplighter=0), next=0)),
    ("The Dasher at 1,204: all three lines, and the longest Next",
     dict(kind="Dasher", count=1204, counts=dict(Brawler=2310, Guard=1420, Dasher=1204, Lamplighter=31), next=3)),
    ("The Lamplighter at 1: the keeper's counts are 1, 10 and 100",
     dict(kind="Lamplighter", count=1, counts=dict(Brawler=412, Guard=180, Dasher=96, Lamplighter=1), next=2)),
    ("The Lamplighter at 112: every line, and nothing left to open",
     dict(kind="Lamplighter", count=112, counts=dict(Brawler=5210, Guard=3050, Dasher=2600, Lamplighter=112), next=5)),
]
LEDGER_NOTES = [
    "A Seam page. The kind's mask hangs from a hook by its own strings, a little",
    "off true, the knot's tails falling: an object left behind, nobody behind it.",
    "Unlit until the first one falls: the paper dark in a thin rim, its cuts",
    "as dim as the page. Lit after: the paper, its cuts full of warm white",
    "light that stays inside them, a lantern's pool on the wall behind. Under it,",
    "its name and count; at the right its three lines, each appearing at its",
    "count, the next one's road filling. Next lies over both panels: the step,",
    "then what it opens (TR54's lines; the band was too narrow for them at 14).",
    "The rail's small masks light the same way. No tap under 44, no word under 14.",
]


# --- the cut --------------------------------------------------------------------------------------------------------

def cut_pieces():
    """Every image of the cut, drawn once. The sheets are laid from these, as the game lays them."""
    for state, name in TAGS.items():
        piece(name, (-16, -6, 20, 36), lambda t, s=state: tag(t, 0, 0, TAG, s),
              use=f"the dare's tag, {dict(lit='lit while the dare holds', kept='its flare, kept', dark='dark once broken')[state]}")
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
    for kind in KINDS:
        for lit in (True, False):
            piece(mask_name(kind, lit, True), HUNG,
                  lambda t, k=kind, on=lit: kind_mask(t, k, 0, DROPS.get(k, DROP), PAGE_R[k], on, hook=(0, 0), tilt=TILTS[k]),
                  use=f"the {NAMES[kind][4:]}'s mask hung on the page, {'lit' if lit else 'unlit'}; its knot the origin")
            piece(mask_name(kind, lit, False), MARK, lambda t, k=kind, on=lit: kind_mask(t, k, 0, 0, RAIL_R[k], on),
                  use=f"the {NAMES[kind][4:]}'s mask on the rail, {'lit' if lit else 'unlit'}")
    piece("LedgerPool", POOL, pool, tint="#FFDFA6 at ImageTransparency 0.64", use="a lantern's pool on the wall behind a lit mask")


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
             "card. Every word is TR54's (docs/test-requests.md, TR54: the dares, today's three, the Ledger's lines, "
             "Next, the labels): this file holds where words sit, never the words.",
        units="points at the smallest phone (568 x 320); every box is left, top, width, height; a word's y is its "
              "capitals' top; images at 4 pixels a point, edge alpha 0. An image's `origin` is where its lay point sits "
              "in it, in points from its top left (times 4 for pixels): a lay's `origin` is where that point goes",
        sheets=["goals_dare_line.png", "goals_dare_card.png", "goals_today.png", "goals_ledger.png", "goals_cut.png"],
        dare=dict(
            line=dict(
                note="the run's line as StageController builds it; boxes from the line's glass's top left",
                unfolded=dict(grows=24, rule=dict(y=46, inset=8, height=1, colour=P["edge"], transparency=0.1),
                              tag=dict(image="DareTag", origin=[21, 46], scale=14 / TAG),
                              words=dict(x="the stretch's name's left", y=51, size=SMALL, colour=P["text"]),
                              held="about 3 s from the stretch's start (a seed: TR54's Config), then it folds"),
                folded=dict(tab=dict(box=[8, 30, 26, 40], make="the line's own glass, under it, corners cut 4"),
                            tag=dict(origin=[20, 44], scale=1.0,
                                     images=dict(holds="DareTag", broken="DareTagDark", kept="DareTagKept")),
                            broken="the tag's image swaps to DareTagDark; no words, no sound",
                            kept="DareTagKept once, as the stretch clears"),
                hard="the same row and tab in the Hard line's glass (the ember's edge)"),
            card=dict(
                tags=dict(image="DareTagKept", scale=15 / TAG,
                          origin="7 right of stretch k's mark's right edge, 2 under the road's middle, for each k kept"),
                chip=dict(row="last on the time's row, the row's gap (8) before it; on the fall's card a row of its own "
                              f"under the line that says where the next run starts, {CELL:g} tall, the chip centred, 2 down",
                          height=22, corners=4, fill=list(sk.SOCKET_DARK) if isinstance(sk.SOCKET_DARK, (tuple, list)) else sk.SOCKET_DARK,
                          edge=dict(colour=PAPER_SHADE, width=1.2), glow=dict(colour=GLOW, strength=0.22, reach=5),
                          tag=dict(image="DareTagKept", origin=[10, 1.5], scale=13 / TAG),
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
                none="no dare kept: no tag, no chip, on either card")),
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
                back=dict(chevron=[[22, 11], [16, 17], [22, 23]], width=1.8, colour=IVORY, tap="at least 44 each way"),
                head=dict(x=32, y=11, size=TITLE, colour=IVORY),
                ledger=dict(right=r2(hc.PANEL[0] - 28), y=12, size=SMALL, colour="#AEB7C2",
                            chevron=r2([[hc.PANEL[0] - 22, 12], [hc.PANEL[0] - 17, 17], [hc.PANEL[0] - 22, 22]]),
                            tap="at least 44 each way; the Ledger's one way in at launch"),
                rows=dict(left=ROW_X[0], top=LIST_TOP, height=ROW_H, gap=ROW_GAP, images=dict(ROWS, press="GoalRowPress"),
                          origin="a row's top, its foot's left corner",
                          words=dict(x=r2(lean / 2 + 14), y=15, size=SMALL, colour=IVORY, claimed="#7E879A"),
                          shard=dict(box=r2([sx, 6, 32, 32]), open="at 0.5", done="at 1"),
                          right=dict(x=r2(sx - 8), y=15, size=SMALL, align="RIGHT", count="#AEB7C2",
                                     claim=dict(colour=READY, bold=True)),
                          check=dict(image="GoalCheck", origin=r2([sx + 16, 22])),
                          done="the whole row is the claim's press", claimed="stays until the day turns"),
                day=dict(height=22, x=r2(ROW_X[0] + 14), y=4, size=SMALL, colour="#8F99A6"),
                scroll=dict(shows="three rows", thumb=dict(x=r2(hc.PANEL[0] - 5), width=2, colour="#55607A")))),
        ledger=dict(
            note="a Seam page in the Stages screen's make (its glass, wells, quiet plate and road); boxes on the phone",
            band=dict(back="the screens' Back", title=dict(x=232, y=20, size=TITLE, bold=True, colour=P["text"])),
            next=dict(box=ltwh(NEXT), make="the quiet plate, its edge the facet",
                      label=dict(x=NEXT[0] + 12, y=NEXT[1] + 14, size=SMALL, bold=True, colour=P["faint"]),
                      lines=dict(x=NEXT[0] + 52, y=[NEXT[1] + 6, NEXT[1] + 23], alone=NEXT[1] + 14, size=SMALL,
                                 colours=[P["text"], P["soft"]],
                                 note="the step, then what it opens: TR54's line split at its first full stop; the "
                                      "last line stands alone")),
            rail=dict(x=list(RAIL["x"]), top=RAIL["top"], pitch=RAIL["pitch"], height=RAIL["tall"], kinds=list(KINDS),
                      chosen="the card's shade, the light's hairline 1.4, its glow", rest="the well, the edge's hairline",
                      mask=dict(images={k: [mask_name(k, True, False), mask_name(k, False, False)] for k in KINDS},
                                origin="the tile's middle", lit="once one of its kind has fallen")),
            wall=dict(box=ltwh(WALL), make="a tile's glass; unlit, the channel over it at 0.3",
                      pool=dict(image="LedgerPool", origin=[HOOK[0], HOOK[1] + DROP - 6], colour="#FFDFA6", transparency=0.64,
                                shows="lit only"),
                      mask=dict(images={k: [mask_name(k, True, True), mask_name(k, False, True)] for k in KINDS},
                                origin=list(HOOK), note="lit, then unlit; the knot is the origin, the tilt is in the image"),
                      name=dict(x=HOOK[0], y=WALL[3] - 49, size=TITLE, bold=True, align="CENTER", colour=P["text"], unlit=P["soft"]),
                      count=dict(y=WALL[3] - 26, number=dict(size=TITLE, bold=True, colour=P["text"], unlit=P["faint"]),
                                 label=dict(size=SMALL, colour=P["soft"], unlit=P["faint"], gap=6, down=2),
                                 note="the number and its label centred together under the name")),
            says=dict(box=ltwh(SAYS), make="a tile's glass", pitch=66, first=SAYS[1] + 6,
                      entry="each line's badge, words, road and rule are measured from its own top: first + k x pitch",
                      counts=dict(shades=list(STEPS[False]), keeper=list(STEPS[True])),
                      badge=dict(box=[SAYS[0] + 10, 2, 46, 22], corners=4, reached=dict(edge=PAPER_SHADE, words=PAPER),
                                 waiting=dict(make="the well", words=P["faint"])),
                      words=dict(x=SAYS[0] + 67, y=5, pitch=17, size=SMALL, colour=P["text"], right=W - 17,
                                 note="wrapped, three rows at most"),
                      road=dict(box=[SAYS[0] + 67, 10, W - 19 - SAYS[0] - 67, 6], shows="on the first line not reached, filled to count / need"),
                      rule=dict(y=61, left=SAYS[0] + 10, right=W - 17, colour=P["edge"], transparency=0.4,
                                under="the first and the second line"))),
        images=images,
        motion="nothing moves here beyond what the kit does (a press, a screen opening). The unfold, the fold into the "
               "tab and the flare are TR54's block, and research reads them in motion there",
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
    """For the content check: each mask hung, lit and unlit, large and at 64 pixels over dark; the tag's three states;
    then the drawn pieces at twice the phone's pixels."""
    ui.K = 2
    cw, ch, gap = 190, 250, 14
    wide = gap + 4 * (cw + gap)
    doubled = [np.repeat(np.repeat(c, 2, axis=0), 2, axis=1) for c in crops]
    below = sum(c.shape[0] / 2 + gap + 22 for c in doubled)
    sheet = ui.Sheet(max(wide, max(c.shape[1] for c in doubled) / 2 + 2 * gap), 60 + 2 * (ch + gap) + 100 + 150 + below, "#101117")
    t = sheet.tile(0, 0, 1, 1)                           # for the words only: each picture draws on its own tile
    t.text(gap, 16, 20, "AR53, the Ledger's masks and the dare's tag: lit and unlit, large, then at 64 pixels", "#EDE6D6", bold=0.2)
    cells = []
    for row, lit in enumerate((True, False)):
        for k, kind in enumerate(KINDS):
            x, y = gap + k * (cw + gap), 56 + row * (ch + gap)
            c = sheet.tile(x, y, cw, ch)
            up.box(c, 0, 0, cw, ch, sm.TILE, P["edge"], 1.0, 6)
            kind_mask(c, kind, cw / 2, ch / 2 + (22 if kind == "Dasher" else 14), 52.0, lit, hook=(cw / 2, 26), tilt=TILTS[kind])
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
        c = sheet.tile(x, y, 136, 130)
        up.box(c, 0, 0, 136, 130, sm.TILE, P["edge"], 1.0, 6)
        tag(c, 60, 12, 78, state)
        lay(c, TAGS[state], 114, 40)
        t.text(x + 8, y + 112, SMALL, {"lit": "the dare holds", "kept": "kept", "dark": "broken"}[state], "#B4AC9C")
    y += 150
    for c, name in zip(doubled, ("the dare unfolded under the line", "\"Dare kept\" on the card's time row", "the list's rows")):
        t.text(gap, y + 2, SMALL, f"{name}, at twice the phone's pixels", "#B4AC9C")
        rs.paste(sheet.px, c, round(gap * 2), round((y + 22) * 2))
        y += c.shape[0] / 2 + gap + 22
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "goals_pictures.png")


def grounds(out):
    """For the content check: the unlit masks' files as they are, over the page's dark and over white, at their own
    pixels and at 64 pixels high."""
    ui.K = CUT_K
    names = [mask_name(kind, False, hung) for hung in (True, False) for kind in KINDS]
    gap, x, places = 14, 14, []
    for name in names:
        b = PIECES[name]["box"]
        places.append((name, x))
        x += b[2] - b[0] + gap
    tall = max(PIECES[n]["box"][3] - PIECES[n]["box"][1] for n in names)
    sheet = ui.Sheet(x, 44 + 2 * (tall + gap) + 2 * (16 + gap), "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 14, "AR53, the unlit masks' files at their own pixels, then at 64 pixels high: on the page's dark, on white",
           "#EDE6D6")
    for row, ground in enumerate(("#241F3D", "#FFFFFF")):
        y = 44 + row * (tall + gap)
        up.box(t, gap / 2, y - 4, x - gap / 2, y + tall + 4, ground, cut=0.0)
        for name, x0 in places:
            b = PIECES[name]["box"]
            lay(t, name, x0 - b[0], y - b[1])
        y = 44 + 2 * (tall + gap) + row * (16 + gap)
        up.box(t, gap / 2, y - 4, x - gap / 2, y + 20, ground, cut=0.0)
        for name, x0 in places:
            px = PIECES[name]["px"]
            t.image(rs.shrink(px, 64 / px.shape[0]), x0, y)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "goals_unlit.png")


def crop(shot, box):
    x0, y0, x1, y1 = (round(v * 2) for v in box)
    return shot[max(y0, 0):y1, max(x0, 0):x1].copy()


def main():
    out = bl.out_dir()
    rs.OUT = out
    home_made()
    cut_pieces()
    common = "at the smallest phone (568 x 320 points)"
    lines = ss.sheet_of(out, "goals_dare_line.png", f"AR53, the dare on the run's line, {common}", LINES, LINE_H,
                        LINE_NOTES, line_cell)
    crops = [crop(lines[0], SPOTS["line"])]
    del lines
    cards = ss.sheet_of(out, "goals_dare_card.png", f"AR53, the dare on the run's card, {common}", CARDS, H, CARD_NOTES,
                        card_cell)
    for said_, st in CARDS:
        print(f"card: {st['tall']:.0f} of {H - ss.BAND} points tall, its time row {st.get('row', 0):.0f} of 320: {said_}")
    crops.append(crop(cards[0], SPOTS["chip"]))
    groups = [thumbs(cards)]
    del cards
    today = ss.sheet_of(out, "goals_today.png", f"AR53, today's three on Home's panel, {common}", TODAY, H, TODAY_NOTES,
                        today_cell)
    crops.append(crop(today[2], SPOTS["rows"]))
    groups.append(thumbs(today))
    del today
    pages = ss.sheet_of(out, "goals_ledger.png", f"AR53, the Mask Ledger's page, {common}", LEDGER, H, LEDGER_NOTES,
                        ledger_cell)
    groups.append(thumbs(pages))
    del pages
    gc.collect()
    if sys.argv[-1] == "cut":
        cut(out)
        return
    small(out, groups)
    pictures(out, crops)
    grounds(out)


if __name__ == "__main__":
    main()
