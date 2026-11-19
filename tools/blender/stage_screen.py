"""AR42: the stages' picker in three directions, on the kit in AR40's C, at the smallest phone, for research's pick.
Drawn in code: shapes and Blender's own face standing in for the kit's, nothing rendered, nothing exported.

What it holds (docs/asset-requests.md, AR42; Faber's grey screen, src/client/UI/StageScreen.luau): Lantern Row's four
stages, each with its mark, who stands there, its recommended Combat Power, and its best clear or why it's shut; the
Normal/Hard switch, where Hard reads harder at a glance. A full screen (Kit/Screen, Screen.Full): Back, the ground's
name, the player's own Combat Power and the switch in the band Roblox's top bar leaves free, the stages in the body.
Faber's panel can't hold four tiles on a phone held sideways (AR42, "The picker in three directions, planned").

    A  One road: the four tiles side by side over one road along their feet, lit to where the player stands.
    B  The climb: the tiles step up from bottom left to top right, each on a stair's tread, toward the Lamplighter.
    C  The street and its card: Lantern Row's street as one winding road with four round stops, and the chosen
       stop's card with one Start.

Measured in rendered points at the smallest phone (Theme.Smallest, 568 x 320), the kit's sizes at the scale's floor
(0.85): Pad 7, Gap 5, a tap 44, no text under 14. The band is Roblox's top bar, 58 tall; where Roblox's own buttons
end is read live in game, drawn at 104 as a stand-in. Combat Power and the bests are stand-ins.

    blender -b --factory-startup --python tools/blender/stage_screen.py -- <abs out>

Writes stage_screen_A.png, stage_screen_B.png, stage_screen_C.png (each direction's three phones) and
stage_screen_all.png (the nine at half size).
"""

import math
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
TOP, FOOT = BAND + PAD, H - PAD

# AR40's C, the system panel (tools/colour/ar40_directions.py, SYSTEM "C")
C = dict(panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", text="#FFF6E2", soft="#D9E8E2", faint="#A9C0BC",
         channel="#0E1D23", well="#21414A", button=("#447480", "#366270"), accent="#CDBBFF",
         chosen=("#F0E2C4", "#DCCBA6"), ink="#1E3238", row="#3C6A76", backing="#2E525C", ready="#FFD880",
         quiet=("#21434C", "#193740"), quiet_edge="#8FC4C8", glass="#16343C")
FIELD = {False: C["backing"], True: C["glass"]}           # Hard drops the field a step darker, never to black
LIT = {False: C["ready"], True: C["accent"]}              # the walked road, and the next stage's edge
SHADE_BODY, SHADE_GLOW = "#13262B", "#FFF6E2"

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)  # codes, painted


# --- the kit's pieces ----------------------------------------------------------------------------------------------

def circle(t, cx, cy, r):
    return np.hypot(t.x - cx, t.y - cy) - r


def box(t, x0, y0, x1, y1, fill, line=None, lw=1.0, cut=3.0):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.paint(d, t.ramp(fill[0], fill[1], (t.y - y0) / max(y1 - y0, 1)) if isinstance(fill, tuple) else fill)
    if line:
        t.line(d, lw, line)
    return d


def press(t, x0, y0, x1, y1, words, kind="quiet", size=SMALL):
    """A press: the one action is C's sand plate in ink; a quiet press a deep teal well in a pale teal edge; off, the
    Well's plate and faint words."""
    fill, edge, colour = {"one": (C["chosen"], C["text"], C["ink"]), "quiet": (C["quiet"], C["quiet_edge"], C["text"]),
                          "off": (C["well"], C["row"], C["faint"]), "side": (C["button"], C["row"], C["text"])}[kind]
    box(t, x0, y0, x1, y1, fill, edge, 1.0, 4.0)
    if words:
        t.text((x0 + x1) / 2, (y0 + y1) / 2 - size * 0.36, size, words, colour, align="CENTER", bold=0.2)


def chevrons(t, cx, cy, s, colour):
    for k in (0, 1):
        y = cy - s * 0.25 + k * s * 0.55
        t.stroke([(cx - s * 0.5, y + s * 0.3), (cx, y - s * 0.12), (cx + s * 0.5, y + s * 0.3)], s * 0.2, colour)


def lock(t, cx, cy, s, colour):
    arc = [(cx + s * 0.28 * math.cos(a), cy - s * 0.1 - s * 0.32 * math.sin(a)) for a in np.linspace(0, math.pi, 9)]
    t.stroke(arc, s * 0.11, colour)
    box(t, cx - s * 0.42, cy - s * 0.12, cx + s * 0.42, cy + s * 0.48, colour, cut=s * 0.08)
    t.paint(circle(t, cx, cy + s * 0.14, s * 0.07), C["well"])


def check(t, cx, cy, r):
    t.paint(circle(t, cx, cy, r), C["chosen"][0])
    t.stroke([(cx - r * 0.45, cy), (cx - r * 0.1, cy + r * 0.38), (cx + r * 0.5, cy - r * 0.38)], r * 0.22, C["ink"])


def badge(t, x, y, n, hard, lit):
    """A stage's mark: its number in a cut badge; on Hard, Hard's two chevrons beside it."""
    s = 26
    box(t, x, y, x + s, y + s, C["chosen"] if lit else (C["well"], C["well"]), C["edge"] if lit else C["row"], 1.0, 5)
    t.text(x + s / 2, y + s / 2 - 6.5, TITLE, str(n), C["ink"] if lit else C["text"], align="CENTER", bold=0.3)
    if hard:
        box(t, x + s + 3, y, x + s + 3 + 18, y + s, (C["well"], C["well"]), C["accent"], 1.0, 4)
        chevrons(t, x + s + 12, y + s / 2, 11, C["accent"])


def ellipse(t, cx, cy, rx, ry, angle=0.0):
    ca, sa = math.cos(angle), math.sin(angle)
    dx, dy = t.x - cx, t.y - cy
    return (np.hypot((dx * ca + dy * sa) / rx, (-dx * sa + dy * ca) / ry) - 1) * min(rx, ry)


def mask(t, mx, my, rx, ry, tilt):
    """Our festival mask (the content check's condition 1): a tilted cream oval in a gold rim, painted gold cheeks,
    laughing eye slits and a wide crescent grin in ink, nothing red in it."""
    ca, sa = math.cos(tilt), math.sin(tilt)

    def at(u, v):
        return (mx + u * rx * ca - v * ry * sa, my + u * rx * sa + v * ry * ca)
    t.paint(ellipse(t, mx, my, rx * 1.14, ry * 1.1, tilt), C["ready"])
    t.paint(ellipse(t, mx, my, rx, ry, tilt), C["text"])
    for side in (-1, 1):
        t.paint(ellipse(t, *at(side * 0.6, 0.22), rx * 0.16, ry * 0.07, tilt), "#C99A3E")
        t.stroke([at(side * 0.42 - 0.2, -0.16), at(side * 0.42, -0.32), at(side * 0.42 + 0.2, -0.16)], rx * 0.13,
                 C["ink"])
    grin = np.maximum(ellipse(t, *at(0, 0.3), rx * 0.6, ry * 0.36, tilt), -ellipse(t, *at(0, 0.1), rx * 0.72, ry * 0.36, tilt))
    t.paint(grin, C["ink"])


def shade(t, cx, cy, s, elite=False, dim=False):
    """A Shade: a festival-goer the Void has filled, a dark body in a glowing outline, broad shoulders and a round head,
    the Brawler's festival mask worn pushed to one side on its cord, so it reads as a mask and the dark head shows
    beside it; an elite is larger, with its second mask worn on its shoulder by a strap (docs/roster.md, "Enemies:
    Shades"; the content check's conditions 1 and 3, AR42)."""
    hx, hy = cx, cy - s * 0.5
    body = t.poly([(cx - s * 0.52, cy - s * 0.14), (cx + s * 0.52, cy - s * 0.14), (cx + s * 0.8, cy + s * 0.9),
                   (cx - s * 0.8, cy + s * 0.9)])
    d = np.minimum.reduce([body, circle(t, hx, hy, s * 0.38), circle(t, cx - s * 0.52, cy + s * 0.05, s * 0.22),
                           circle(t, cx + s * 0.52, cy + s * 0.05, s * 0.22)])
    if dim:
        t.paint(d, C["well"])
        t.line(d, 1.2, C["faint"])
        return
    t.glow(d, 4.0, SHADE_GLOW, 0.3)
    t.paint(d, SHADE_BODY)
    t.line(d, 1.5, SHADE_GLOW)
    t.stroke([(hx - s * 0.37, hy - s * 0.1), (hx + s * 0.37, hy - s * 0.04)], s * 0.045, C["ready"])   # the cord
    mask(t, hx + s * 0.13, hy + s * 0.02, s * 0.22, s * 0.28, 0.32)
    if elite:
        t.stroke([(cx + s * 0.52, cy + s * 0.14), (cx + s * 0.2, cy - s * 0.14)], s * 0.05, C["ready"])
        mask(t, cx + s * 0.54, cy + s * 0.18, s * 0.15, s * 0.19, 0.22)


def lantern(t, cx, cy, s, dim=False):
    """The Lamplighter's paper lantern: ribbed paper, two dark caps, its hook and its tassel, lit on a dark bed."""
    ring = [(cx + s * 0.46 * math.cos(a), cy + s * 0.56 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 40)[:-1]]
    d = t.poly(ring)
    paper, rib, cap = (C["well"], C["faint"], C["faint"]) if dim else (C["ready"], "#C99A3E", C["ink"])
    if not dim:
        t.glow(d, 9.0, C["ready"], 0.45)
    t.paint(d, paper)
    if dim:
        t.line(d, 1.2, C["faint"])
    for k in (-2, -1, 0, 1, 2):
        y = cy + k * s * 0.19
        half = s * 0.46 * math.sqrt(max(0.0, 1 - (k * 0.19 / 0.56) ** 2))
        t.stroke([(cx - half * 0.96, y), (cx, y + s * 0.04), (cx + half * 0.96, y)], s * 0.035, rib)
    for sign in (-1, 1):
        y = cy + sign * s * 0.6
        box(t, cx - s * 0.22, y - s * 0.06, cx + s * 0.22, y + s * 0.06, cap, cut=s * 0.03)
    t.stroke([(cx, cy - s * 0.66), (cx, cy - s * 0.82)], s * 0.05, cap)
    t.stroke([(cx - s * 0.1, cy - s * 0.82), (cx + s * 0.1, cy - s * 0.82)], s * 0.05, cap)
    t.stroke([(cx, cy + s * 0.66), (cx, cy + s * 0.9)], s * 0.06, cap)


def picture(t, kind, cx, cy, s, dim=False):
    if kind == "lantern":
        lantern(t, cx, cy, s * 0.92, dim)
    else:
        shade(t, cx, cy + s * 0.08, s * (1.0 if kind == "shade" else 1.06 if kind == "elite" else 1.18),
              elite=kind != "shade", dim=dim)


def window(t, x0, y0, x1, y1, kind, state, hard, n, scale=0.42):
    """A tile's picture: a dark bed, who stands there, the stage's mark, a check once cleared, a lock while shut."""
    box(t, x0, y0, x1, y1, (C["glass"], C["channel"]), None, 1.0, 4)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2 + 2
    s = (y1 - y0) * scale
    picture(t, kind, cx, cy, s, dim=state == "shut")
    if state == "shut":
        lock(t, cx, cy + s * 0.1, s * 0.62, C["text"])
    badge(t, x0 + 4, y0 + 4, n, hard, state != "shut")
    if state == "cleared":
        check(t, x1 - 15, y0 + 15, 10)


# --- the phone, its band, and the three directions -----------------------------------------------------------------

STAGES = [(1, "Stage 1", "shade"), (2, "Stage 2", "elite"), (3, "Stage 3", "big"), (4, "Lamplighter", "lantern")]
KEEPER_WHY = "Beat the Lamplighter on Normal"
HARD_SAYS = "Hard: every foe is 10 levels higher"


def band(t, state):
    hard = state["hard"]
    box(t, 0, 0, ROBLOX, BAND, "#1B2C31", cut=0)
    t.text(ROBLOX / 2, BAND / 2 - 12, SMALL, "Roblox's", "#6E8A90", align="CENTER")
    t.text(ROBLOX / 2, BAND / 2 + 4, SMALL, "buttons", "#6E8A90", align="CENTER")
    back = (ROBLOX + PAD, (BAND - TAP) / 2, ROBLOX + PAD + 58, (BAND + TAP) / 2)
    press(t, *back, None)
    t.stroke([(back[0] + 34, BAND / 2 - 8), (back[0] + 25, BAND / 2), (back[0] + 34, BAND / 2 + 8)], 2.2, C["text"])
    t.text(back[2] + 8, BAND / 2 - 6, TITLE, "Lantern Row", C["text"], bold=0.25)
    t.text(300, BAND / 2 - 16, SMALL, "Your power", C["faint"])
    t.text(300, BAND / 2 + 2, TITLE, f"{state['cp']} CP", C["text"], bold=0.2)
    x0, x1 = W - PAD - 164, W - PAD
    mid = (x0 + x1) / 2
    press(t, x0, (BAND - TAP) / 2, mid, (BAND + TAP) / 2, None, "side" if hard else "one")
    press(t, mid, (BAND - TAP) / 2, x1, (BAND + TAP) / 2, None, "one" if hard else "side")
    y = BAND / 2 - SMALL * 0.36
    t.text((x0 + mid) / 2, y, SMALL, "Normal", C["text"] if hard else C["ink"], align="CENTER", bold=0.2)
    chevrons(t, mid + 18, BAND / 2, 11, C["ink"] if hard else C["text"])
    t.text(mid + 30, y, SMALL, "Hard", C["ink"] if hard else C["text"], bold=0.2)
    if state["hard_shut"]:
        lock(t, x1 - 14, BAND / 2, 13, C["ink"] if hard else C["faint"])


def tile_text(t, x0, x1, y, n, title, row, compact=False):
    """Under a tile's picture: its stage, its recommended Combat Power, then its best, or why it's shut."""
    state, cp, said = row
    cx = (x0 + x1) / 2
    t.text(cx, y, TITLE, title, C["text"] if state != "shut" else C["soft"], align="CENTER", bold=0.25)
    t.text(cx, y + 22, SMALL, "Recommended", C["faint"], align="CENTER")
    t.text(cx, y + 38, TITLE, f"{cp} CP", C["text"] if state != "shut" else C["soft"], align="CENTER", bold=0.2)
    if said:
        for k, words in enumerate(said):
            t.text(cx, y + 60 + k * 17, SMALL, words, C["soft"] if state != "next" else C["text"], align="CENTER")


def tile(t, x0, y0, x1, y1, n, title, kind, row, hard, pic):
    state = row[0]
    if state == "next":
        d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 6, 6, 6))
        t.glow(d, 6.0, LIT[hard], 0.35)
    fill = (C["well"], C["well"]) if state == "shut" else C["panel"]
    edge = LIT[hard] if state == "next" else (C["row"] if state == "shut" else (C["accent"] if hard else C["edge"]))
    box(t, x0, y0, x1, y1, fill, edge, 2.2 if state == "next" else 1.2, 6)
    window(t, x0 + 6, y0 + 6, x1 - 6, y0 + 6 + pic, kind, state, hard, n)
    if state == "next":
        tag = (x1 - 6 - 46, y0 - 9, x1 - 6, y0 + 11)
        box(t, *tag, C["chosen"], None, 1.0, 4)
        t.text((tag[0] + tag[2]) / 2, tag[1] + 3, SMALL, "Next", C["ink"], align="CENTER", bold=0.25)
    tile_text(t, x0, x1, y0 + pic + 14, n, title, row)


def wrapped(row):
    """Faber's words, wrapped to a tile's width."""
    state, cp, said = row
    if said is None:
        return (state, cp, None)
    if said.startswith("Clear Stage"):
        return (state, cp, [said[:-6], "first"])
    return (state, cp, [said])


def road_a(t, state):
    """A: one road, the tiles side by side over it, lit from the first to where the player stands."""
    hard, rows = state["hard"], state["rows"]
    wide = (W - 2 * PAD - 3 * GAP) / 4
    y0, y1, ry = TOP + 6, 266, 280
    xs = [PAD + k * (wide + GAP) for k in range(4)]
    nxt = next((k for k, r in enumerate(rows) if r[0] == "next"), None)
    box(t, PAD, ry - 5, W - PAD, ry + 5, C["channel"], C["row"], 1.0, 4)
    if nxt is not None:
        end = xs[nxt] + wide / 2
        box(t, PAD + 2, ry - 2, end, ry + 2, LIT[hard], cut=1.5)
        t.glow(circle(t, end, ry, 7), 4.0, LIT[hard], 0.4)
        t.paint(np.abs(circle(t, end, ry, 7)) - 1.6, C["text"])
    for k, (n, title, kind) in enumerate(STAGES):
        row = wrapped(rows[k])
        lift = 6 if row[0] == "next" else 0
        tile(t, xs[k], y0 - lift, xs[k] + wide, y1, n, title, kind, row, hard, 86)
    if hard:
        t.text(W / 2, ry + 12, SMALL, KEEPER_WHY_LONG if state["hard_shut"] else HARD_SAYS, C["text"], align="CENTER")


KEEPER_WHY_LONG = "Hard opens when you beat the Lamplighter on Normal"


def climb_b(t, state):
    """B: the climb, each tile on a stair's tread, stepping up toward the Lamplighter."""
    hard, rows = state["hard"], state["rows"]
    wide, high, step = 124.0, 178.0, 20.0
    gap = (W - 2 * PAD - 4 * wide) / 3
    nxt = next((k for k, r in enumerate(rows) if r[0] == "next"), None)
    for k, (n, title, kind) in enumerate(STAGES):
        x0 = PAD + k * (wide + gap)
        y0 = TOP + 7 + (3 - k) * step
        tread = y0 + high + 4
        walked = nxt is not None and k <= nxt
        stair = (x0 - (gap if k else 0), tread, x0 + wide + (gap if k < 3 else 0), H)
        box(t, stair[0], stair[1], stair[2], stair[3], (C["row"], C["backing"] if not hard else C["glass"]), cut=0)
        box(t, stair[0], tread - 1.5, stair[2], tread + 2.5, LIT[hard] if walked else C["channel"], cut=0)
        row = wrapped(rows[k])
        lift = 5 if row[0] == "next" else 0
        if hard:                                     # Hard: a notched crown along each tile's top
            teeth = 6
            for j in range(teeth):
                a = x0 + 10 + j * (wide - 20) / (teeth - 1)
                t.paint(t.poly([(a - 6, y0 - lift + 1), (a, y0 - lift - 6), (a + 6, y0 - lift + 1)]),
                        C["accent"] if row[0] != "shut" else C["row"])
        tile(t, x0, y0 - lift, x0 + wide, y0 + high, n, title, kind, row, hard, 64)
    if hard:
        words = (["Hard opens when you beat", "the Lamplighter on Normal"] if state["hard_shut"]
                 else ["Hard: every foe is", "10 levels higher"])
        for k, w in enumerate(words):
            t.text(PAD + 6, TOP + 6 + k * 18, SMALL, w, C["text"])


STOPS = [(64, 258), (146, 206), (226, 150), (292, 98)]
STREET = [(PAD, 300), (40, 282), (64, 258), (100, 238), (146, 206), (186, 186), (226, 150), (262, 128), (292, 98)]


def street_c(t, state):
    """C: Lantern Row's street as one winding road with its four stops, and the chosen stop's card with one Start."""
    hard, rows = state["hard"], state["rows"]
    nxt = next((k for k, r in enumerate(rows) if r[0] == "next"), None)
    chosen = state.get("chosen", nxt if nxt is not None else 0)
    t.stroke(STREET, 16, C["row"])
    t.stroke(STREET, 10, C["channel"])
    if nxt is not None:                              # walked: from the street's start to the next stop
        end = STREET.index(STOPS[nxt])
        t.stroke(STREET[:end + 1], 3.2, LIT[hard])
    for k, ((cx, cy), (n, title, kind)) in enumerate(zip(STOPS, STAGES)):
        st = rows[k][0]
        r = 27
        if hard:                                     # Hard: a three-point crown over each stop
            for a in (-0.5, 0.0, 0.5):
                px, py = cx + math.sin(a) * (r + 2), cy - math.cos(a) * (r + 2)
                t.paint(t.poly([(px - 5 * math.cos(a), py - 5 * math.sin(a)), (px + 10 * math.sin(a), py - 10 * math.cos(a)),
                                (px + 5 * math.cos(a), py + 5 * math.sin(a))]), C["accent"] if st != "shut" else C["row"])
        if k == chosen:
            t.glow(circle(t, cx, cy, r + 3), 5.0, LIT[hard], 0.45)
        t.paint(circle(t, cx, cy, r + 1.5), C["row"] if st == "shut" else (LIT[hard] if k == chosen else C["edge"]))
        t.paint(circle(t, cx, cy, r - 1), C["glass"])
        picture(t, kind, cx, cy + 2, r * 0.82, dim=st == "shut")
        if st == "shut":
            lock(t, cx, cy + 3, r * 0.6, C["text"])
        if st == "cleared":
            check(t, cx + r * 0.78, cy - r * 0.78, 8.5)
        bx, by = cx - r - 10, cy + r - 16
        box(t, bx, by, bx + 20, by + 20, C["chosen"] if st != "shut" else (C["well"], C["well"]),
            C["edge"] if st != "shut" else C["row"], 1.0, 4)
        t.text(bx + 10, by + 4, SMALL, str(n), C["ink"] if st != "shut" else C["text"], align="CENTER", bold=0.3)
    if hard:
        t.text(PAD + 4, TOP + 4, SMALL, HARD_SAYS if not state["hard_shut"] else "Hard opens when you beat", C["text"])
        if state["hard_shut"]:
            t.text(PAD + 4, TOP + 22, SMALL, "the Lamplighter on Normal", C["text"])
    # the card
    x0, x1, y0, y1 = 336, W - PAD, TOP, FOOT
    n, title, kind = STAGES[chosen]
    st, cp, said = rows[chosen]
    box(t, x0, y0, x1, y1, C["panel"], C["accent"] if hard else C["edge"], 1.3, 6)
    window(t, x0 + 6, y0 + 6, x1 - 6, y0 + 96, kind, st, hard, n, scale=0.36)
    name = ("Hard " if hard else "") + ("Stage 4, the Lamplighter" if n == 4 else title)
    t.text(x0 + 10, y0 + 104, TITLE, name, C["text"], bold=0.25)
    t.text(x0 + 10, y0 + 130, SMALL, "Recommended", C["faint"])
    t.text(x1 - 10, y0 + 128, TITLE, f"{cp} CP", C["text"], align="RIGHT", bold=0.2)
    if st == "shut":
        words = [KEEPER_WHY] if said is None else [said]
        for k, w in enumerate(words):
            t.text(x0 + 10, y0 + 156 + k * 18, SMALL, w, C["soft"])
        press(t, x0 + 6, y1 - 6 - TAP, x1 - 6, y1 - 6, "Start", "off", TITLE)
    else:
        t.text(x0 + 10, y0 + 154, SMALL, "Your best", C["faint"])
        t.text(x1 - 10, y0 + 154, SMALL, said.replace("Best ", "") if said else "Not cleared", C["text"], align="RIGHT")
        press(t, x0 + 6, y1 - 6 - TAP, x1 - 6, y1 - 6, "Start", "one", TITLE)


DRAW = {"A": road_a, "B": climb_b, "C": street_c}
NAMES = {"A": "One road", "B": "The climb", "C": "The street and its card"}

STATES = [
    ("Normal: stages 1 and 2 cleared, 3 next, 4 shut", dict(
        hard=False, hard_shut=False, cp="1,480",
        rows=[("cleared", "420", "Best 2:41"), ("cleared", "780", "Best 3:05"), ("next", "1,250", "Not cleared"),
              ("shut", "2,100", "Clear Stage 3 first")])),
    ("Hard while it's shut: the Lamplighter not yet beaten on Normal", dict(
        hard=True, hard_shut=True, cp="2,050",
        rows=[("shut", "4,800", None), ("shut", "6,900", None), ("shut", "9,400", None), ("shut", "13,000", None)])),
    ("Hard open: Hard 1 cleared, 2 next, 3 and 4 shut", dict(
        hard=True, hard_shut=False, cp="6,200",
        rows=[("cleared", "4,800", "Best 3:52"), ("next", "6,900", "Not cleared"), ("shut", "9,400", "Clear Stage 2 first"),
              ("shut", "13,000", "Clear Stage 3 first")])),
]

NOTES = {
    "A": ["The four stages side by side over one road along their",
          "feet, lit from the first to the ring where the player",
          "stands; the next stage raised, its edge lit, tagged Next.",
          "Hard: the field a step darker, the edges and the walked",
          "road in C's pale violet, Hard's chevrons by each mark,",
          "and one line under the road says what changes."],
    "B": ["The stages step up from bottom left to top right, each",
          "on a stair's tread, toward the Lamplighter: the walked",
          "treads lit, the next stage raised and tagged Next.",
          "Hard: the field a step darker, the violet edges, and a",
          "notched crown along each tile's top; the line top left",
          "says what changes."],
    "C": ["Lantern Row's street as one winding road with its four",
          "stops, walked to the next; the chosen stop's card at the",
          "right, the next by default, with one Start (off while",
          "shut, and why). Two taps to begin a stage that isn't the",
          "next. Hard: the darker field, the violet road, and a",
          "three-point crown over each stop."],
}
COMMON = ["Every tap 44 or more, no text under 14, Pad 7, Gap 5 (rendered).",
          "Stand-ins: Combat Power, the bests, where Roblox's buttons end."]


def phone(sheet, ox, oy, direction, state):
    t = sheet.tile(ox, oy, W, H)
    box(t, 0, 0, W, H, FIELD[state["hard"]], cut=0)
    band(t, state)
    DRAW[direction](t, state)


def page(out, direction):
    ui.K = 2                                  # the smallest phone's own pixels: two a point
    gap, head_h = 24, 64
    width, height = gap + 2 * (W + gap), head_h + 2 * (H + 40) + 20
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, f"AR42, the stages' picker, {direction}: {NAMES[direction]}, in AR40's C, at the smallest phone "
                        "(568 x 320 points)", "#EDE6D6", bold=0.2)
    for k, (said, state) in enumerate(STATES):
        x, y = gap + (k % 2) * (W + gap), head_h + (k // 2) * (H + 40)
        t.text(x, y - 4, SMALL, f"{k + 1}. {said}", "#B4AC9C")
        phone(sheet, x, y + 16, direction, state)
    x, y = gap + W + gap, head_h + H + 40 + 16
    for k, words in enumerate(NOTES[direction] + [""] + COMMON):
        t.text(x + 8, y + 6 + k * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / f"stage_screen_{direction}.png")
    return sheet.px, head_h + 16, gap


def main():
    out = bl.out_dir()
    pages = {d: page(out, d) for d in DRAW}
    # the nine at half size: a direction a row, its three states across
    scale, gap = 0.5, 12
    pw, ph = round(W * 2 * scale), round(H * 2 * scale)
    all_px = np.zeros((3 * (ph + gap) + gap, 3 * (pw + gap) + gap, 4), dtype=np.float32)
    all_px[..., :3], all_px[..., 3] = ui.c("#101117"), 1.0
    for r, (d, (px, top, left)) in enumerate(pages.items()):
        for k in range(3):
            x, y = left + (k % 2) * (W + 24), top + (k // 2) * (H + 40)
            shot = px[round(y * 2):round((y + H) * 2), round(x * 2):round((x + W) * 2)]
            rs.paste(all_px, rs.shrink(shot, scale), gap + k * (pw + gap), gap + r * (ph + gap))
    rs.save(all_px, out / "stage_screen_all.png")
    # the nine again at 64 pixels high, over dark: the content check's small read (AR42, condition 7)
    small = 64 / (H * 2)
    sw, sh = round(W * 2 * small), 64
    tiny = np.zeros((3 * (sh + gap) + gap, 3 * (sw + gap) + gap, 4), dtype=np.float32)
    tiny[..., :3], tiny[..., 3] = ui.c("#101117"), 1.0
    for r, (d, (px, top, left)) in enumerate(pages.items()):
        for k in range(3):
            x, y = left + (k % 2) * (W + 24), top + (k // 2) * (H + 40)
            shot = px[round(y * 2):round((y + H) * 2), round(x * 2):round((x + W) * 2)]
            rs.paste(tiny, rs.shrink(shot, small), gap + k * (sw + gap), gap + r * (sh + gap))
    rs.save(tiny, out / "stage_screen_64.png")
    pictures(out)


def pictures(out):
    """The tiles' pictures for the content check: each four times over, then at a tile's size and at 64 pixels, open
    and shut, over dark."""
    ui.K = 1
    big, cell, gap = 320, 86, 16
    sheet = ui.Sheet(gap + 4 * (big + gap), 40 + big + gap + 2 * (cell + gap) + 30, "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 20, "AR42, the tiles' pictures: four times over, then at a tile's size (open, shut) and at 64 px",
           "#EDE6D6", bold=0.2)
    for k, (n, title, kind) in enumerate(STAGES):
        x = gap + k * (big + gap)
        window(t, x, 40, x + big, 40 + big, kind, "open", False, n)
        for j, state in enumerate(("open", "shut")):
            window(t, x + j * (cell + gap), 40 + big + gap, x + j * (cell + gap) + cell, 40 + big + gap + cell, kind,
                   state, False, n)
        x64 = x + 2 * (cell + gap)
        window(t, x64, 40 + big + gap, x64 + 64, 40 + big + gap + 64, kind, "open", False, n)
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "stage_screen_pictures.png")


if __name__ == "__main__":
    main()
