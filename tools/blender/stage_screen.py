"""AR42: the stages' screens in A, One road (research's pick, 2026-11-19), on the kit in AR40's C, at the smallest
phone. Drawn in code: shapes and Blender's own face stand in for the kit's. Nothing is rendered, nothing is exported.

What it holds (docs/asset-requests.md, AR42; Faber's grey screens, src/client/UI/StageScreen.luau and
src/client/Controllers/Main/StageController.luau):
    the picker   Lantern Row's four stages side by side over one road along their feet, lit to where the player
                 stands. Each stage has its mark, who stands there, its recommended Combat Power, and its best clear
                 or why it's shut. The Normal/Hard switch sits in the band. A full screen (Kit/Screen, Screen.Full).
    the results  the card at a run's end, over the street. The four marks sit on their road, lit on to the next. It
                 holds the stage cleared, its time and best, what it gave, what it opened, and Retry, Next and Home.
                 A lost run says the lead fell.
    the line     the run at the top of the screen: the stage's mark and name, and its Shades on a short road to its
                 last foe.
Research's two must-fixes:
    - the Shade's mask is the Brawler's mask as it's modelled (tools/blender/shade_sheet.py), never a face;
    - Hard takes the whole screen a full value darker.
B (The climb) and C (The street and its card) were drawn in 5b415c4.

Measured in rendered points at the smallest phone (Theme.Smallest, 568 x 320), at the kit's floor scale (0.85): Pad 7,
Gap 5, a tap 44, no text under 14. The band is Roblox's top bar, 58 tall. Where Roblox's own buttons end is read live
in game, and drawn at 104 as a stand-in. Combat Power, the times and what a stage gives are stand-ins. The street
behind the card and the line is ui_sheet's busy noon stand-in.

    blender -b --factory-startup --python tools/blender/stage_screen.py -- <abs out> [pictures]

Writes:
    stage_screen_A.png          the picker's three states
    stage_results.png           the card's four
    stage_line.png              the line's four
    stage_screen_64.png         the picker and the cards at 64 pixels high
    stage_screen_pictures.png   the tiles' pictures
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
SMALL, TITLE, BIG = 14, 17, 22
TOP, FOOT = BAND + PAD, H - PAD

# AR40's C, the system panel (tools/colour/ar40_directions.py, SYSTEM "C")
C = dict(panel=("#34606C", "#2A4E5A"), edge="#E2CFA4", text="#FFF6E2", soft="#D9E8E2", faint="#A9C0BC",
         channel="#0E1D23", well="#21414A", button=("#447480", "#366270"), accent="#CDBBFF",
         chosen=("#F0E2C4", "#DCCBA6"), ink="#1E3238", row="#3C6A76", backing="#2E525C", ready="#FFD880",
         quiet=("#21434C", "#193740"), quiet_edge="#8FC4C8", glass="#16343C")
# Hard takes the whole screen a full value darker (research's must-fix 2): the ground, every open tile and the card
# step to well, a shut tile a step under that. Never to black. Violet only on the edges, the chevrons and the road.
FIELD = {False: C["backing"], True: C["glass"]}
PANEL = {False: C["panel"], True: ("#24464F", "#1C3A42")}
SHUT = {False: (C["well"], C["well"]), True: ("#132C33", "#132C33")}
LIT = {False: C["ready"], True: C["accent"]}              # the walked road, and the next stage's edge
SHADE_BODY, SHADE_GLOW = "#13262B", "#FFF6E2"
PAPER, PAPER_SHADE, PRESSED, HOLE = "#EFE6D2", "#C9BA9C", "#E4D8BE", "#0E1D23"   # shade_sheet.py's paper; a cut
MINT, HURT = "#40DCC6", "#FF786E"   # Credits' own colour (Config.UIKit, Systems.Credits); Theme.Colour.Hurt

HANDOFF = Path(__file__).resolve().parents[2] / "build" / "handoff" / "UI"
ICONS = {"credits": HANDOFF / "hud" / "colour" / "images" / "CoinMint.png",      # the game's own pictures
         "shards": HANDOFF / "shards" / "shard_standard_small.png",
         "shade_chest": HANDOFF / "chests" / "images" / "ChestShade.png",
         "keeper_chest": HANDOFF / "chests" / "images" / "ChestKeeper.png"}
_icons = {}

_over = ui.over
ui.over = lambda dst, colour, a: _over(dst, ui.c(colour) if isinstance(colour, str) else colour, a)  # codes, painted


def wide_of(words, size):
    """About how wide Blender's face sets a line, in points: enough to lay a glyph beside centred words."""
    return len(words) * size * 0.52


# --- the kit's pieces ----------------------------------------------------------------------------------------------

def circle(t, cx, cy, r):
    return np.hypot(t.x - cx, t.y - cy) - r


def box(t, x0, y0, x1, y1, fill, line=None, lw=1.0, cut=3.0):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.paint(d, t.ramp(fill[0], fill[1], (t.y - y0) / max(y1 - y0, 1)) if isinstance(fill, tuple) else fill)
    if line:
        t.line(d, lw, line)
    return d


def press(t, x0, y0, x1, y1, words, kind="quiet", size=SMALL, hard=False):
    """A press: the one action is C's sand plate in ink; a quiet press a deep teal well in a pale teal edge; off, the
    Well's plate and faint words. A press into a Hard stage wears Hard's chevrons before its words."""
    fill, edge, colour = {"one": (C["chosen"], C["text"], C["ink"]), "quiet": (C["quiet"], C["quiet_edge"], C["text"]),
                          "off": (C["well"], C["row"], C["faint"]), "side": (C["button"], C["row"], C["text"])}[kind]
    box(t, x0, y0, x1, y1, fill, edge, 1.0, 4.0)
    if words:
        cx = (x0 + x1) / 2 + (8 if hard else 0)
        if hard:
            chevrons(t, cx - wide_of(words, size) / 2 - 10, (y0 + y1) / 2, 11, colour)
        t.text(cx, (y0 + y1) / 2 - size * 0.36, size, words, colour, align="CENTER", bold=0.2)


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


def ring(t, cx, cy, r, colour):
    """Where the player stands: the road's ring, lit."""
    t.glow(circle(t, cx, cy, r), 4.0, colour, 0.4)
    t.paint(circle(t, cx, cy, r), C["channel"])
    t.paint(np.abs(circle(t, cx, cy, r)) - 1.6, C["text"])


def badge(t, x, y, n, hard, lit):
    """A stage's mark: its number in a cut badge; on Hard, Hard's two chevrons beside it."""
    s = 26
    box(t, x, y, x + s, y + s, C["chosen"] if lit else (C["well"], C["well"]), C["edge"] if lit else C["row"], 1.0, 5)
    t.text(x + s / 2, y + s / 2 - 6.5, TITLE, str(n), C["ink"] if lit else C["text"], align="CENTER", bold=0.3)
    if hard:
        box(t, x + s + 3, y, x + s + 3 + 18, y + s, (C["well"], C["well"]), C["accent"], 1.0, 4)
        chevrons(t, x + s + 12, y + s / 2, 11, C["accent"])


def icon(t, kind, x, y, size):
    """One of the game's own pictures, at `size` points, its corner at x, y."""
    key = (kind, size, ui.K)
    if key not in _icons:
        rgba = rs.load(ICONS[kind])
        _icons[key] = rs.shrink(rgba, size * ui.K / rgba.shape[1])
    t.image(_icons[key], x, y)


def ellipse(t, cx, cy, rx, ry, angle=0.0):
    ca, sa = math.cos(angle), math.sin(angle)
    dx, dy = t.x - cx, t.y - cy
    return (np.hypot((dx * ca + dy * sa) / rx, (-dx * sa + dy * ca) / ry) - 1) * min(rx, ry)


BRAWLER = (1.0, 0.96, 1.03, 0.98, 1.02, 0.95, 1.0, 1.04, 0.97, 1.01, 0.96, 1.02)   # shade_sheet.py's radii, by 30°
TEETH = ((-0.4, 0.09, 0.0, 4), (-0.14, 0.06, -0.02, -3), (0.14, 0.1, 0.02, 2), (0.4, 0.06, 0.05, 7))
GRIN = 0.5   # the grin's radius: the model's 0.64 narrowed, so it doesn't run cheek to cheek (the content check, AR42, 02:24)


def mask(t, mx, my, r, tilt):
    """The Brawler's festival mask as it's modelled (shade_sheet.py, mask "Brawler"), r its radius.
    - One sheet of paper, cut not quite round, with a tab each side for its strings, on its darker paper rim.
    - Two level almond eye holes cut through, the left one wider.
    - A lopsided grin cut through behind four paper teeth, no two alike, narrower than the model's.
    Nothing is painted on: no cheeks, no closed eyes (research's must-fix 1, AR42). The content check's block (AR42)
    took the model's ink brows off, made its arched eyes almond holes, and narrowed its grin, so the picture never
    nears a known meme face; the ink nose went too, since round holes, a nose and teeth read as a skull. The teeth are
    drawn only where they're wider than a pixel."""
    ca, sa = math.cos(tilt), math.sin(tilt)

    def at(u, v):                                   # the mask's own axes, u right and v down, in its radius
        return (mx + (u * ca - v * sa) * r, my + (u * sa + v * ca) * r)
    du, dv = t.x - mx, t.y - my
    U, V = (du * ca + dv * sa) / r, (-du * sa + dv * ca) / r
    face = []
    for i, k in enumerate(BRAWLER):
        a = math.radians(15 + 30 * i)
        face.append((k * math.cos(a), -k * math.sin(a)))
        if i == 5:
            face += [(-1.26, -0.17), (-1.26, 0.15)]
        if i == 11:
            face += [(1.26, 0.17), (1.26, -0.15)]
    for scale, colour in ((1.07, PAPER_SHADE), (1.0, PRESSED), (0.84, PAPER)):   # the rim, the pressed edge, the front
        t.paint(t.poly([at(u * scale, v * scale) for u, v in face]), colour)
    fine = r * ui.K >= 14
    for e, a, b in ((-1, 0.2, 0.125), (1, 0.17, 0.105)):    # almond holes, level and open: a lens of two arcs
        rr = (a * a + b * b) / (2 * b)
        u, v = U - e * 0.38, V + 0.22
        t.paint(np.maximum(np.hypot(u, v - (rr - b)), np.hypot(u, v + (rr - b))) * r - rr * r, HOLE)
    low = [(0.02 + GRIN * math.cos(a), 0.0 - GRIN * math.sin(a)) for a in np.radians(np.linspace(200, 340, 13))]
    v0 = low[0][1]
    grin = low + [(u, v0 + (v - v0) * 0.3) for u, v in reversed(low[1:-1])]
    turn = math.radians(6)
    grin = [(u * math.cos(turn) + v * math.sin(turn), -u * math.sin(turn) + v * math.cos(turn)) for u, v in grin]
    cut = t.poly([at(u, v) for u, v in grin])
    t.paint(cut, HOLE)
    if fine:
        for x, w, dz, lean in TEETH:
            cl, sl = math.cos(math.radians(lean)), math.sin(math.radians(lean))
            corners = [(x * GRIN / 0.64 + p * cl - q * sl, 0.36 - dz + p * sl + q * cl)
                       for p, q in ((-w / 2, -0.25), (w / 2, -0.25), (w / 2, 0.25), (-w / 2, 0.25))]
            t.paint(np.maximum(t.poly([at(u, v) for u, v in corners]), cut), PAPER)


def shade(t, cx, cy, s, elite=False, dim=False):
    """A Shade: a festival-goer the Void has filled, a dark body in a glowing outline, broad shoulders and a round head,
    the Brawler's festival mask worn pushed to one side on its strings, so it reads as a mask and the dark head shows
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
    t.stroke([(hx - s * 0.37, hy - s * 0.1), (hx + s * 0.37, hy - s * 0.04)], s * 0.045, PAPER_SHADE)   # its strings
    mask(t, hx + s * 0.13, hy + s * 0.02, s * 0.25, 0.32)
    if elite:
        t.stroke([(cx + s * 0.52, cy + s * 0.14), (cx + s * 0.2, cy - s * 0.14)], s * 0.05, PAPER_SHADE)
        mask(t, cx + s * 0.54, cy + s * 0.18, s * 0.17, 0.22)


def lantern(t, cx, cy, s, dim=False):
    """The Lamplighter's paper lantern: ribbed paper, two dark caps, its hook and its tassel, lit on a dark bed."""
    ring_ = [(cx + s * 0.46 * math.cos(a), cy + s * 0.56 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 40)[:-1]]
    d = t.poly(ring_)
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


def roblox(t):
    """Roblox's own buttons at the top bar's left: a stand-in."""
    box(t, 0, 0, ROBLOX, BAND, "#1B2C31", cut=0)
    t.text(ROBLOX / 2, BAND / 2 - 12, SMALL, "Roblox's", "#6E8A90", align="CENTER")
    t.text(ROBLOX / 2, BAND / 2 + 4, SMALL, "buttons", "#6E8A90", align="CENTER")


# --- the picker ----------------------------------------------------------------------------------------------------

STAGES = [(1, "Stage 1", "shade"), (2, "Stage 2", "elite"), (3, "Stage 3", "big"), (4, "Lamplighter", "lantern")]
HARD_SAYS = "Hard: every foe is 10 levels higher"
KEEPER_WHY_LONG = "Hard opens when you beat the Lamplighter on Normal"


def band(t, state):
    hard = state["hard"]
    roblox(t)
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


def tile_text(t, x0, x1, y, n, title, row):
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
    fill = SHUT[hard] if state == "shut" else PANEL[hard]
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
        ring(t, end, ry, 7, LIT[hard])
    for k, (n, title, kind) in enumerate(STAGES):
        row = wrapped(rows[k])
        lift = 6 if row[0] == "next" else 0
        tile(t, xs[k], y0 - lift, xs[k] + wide, y1, n, title, kind, row, hard, 86)
    if hard:
        t.text(W / 2, ry + 12, SMALL, KEEPER_WHY_LONG if state["hard_shut"] else HARD_SAYS, C["text"], align="CENTER")


def picker(sheet, ox, oy, state):
    t = sheet.tile(ox, oy, W, H)
    box(t, 0, 0, W, H, FIELD[state["hard"]], cut=0)
    band(t, state)
    road_a(t, state)


PICKS = [
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
PICK_NOTES = [
    "The four stages side by side over one road along their",
    "feet, lit from the first to the ring where the player",
    "stands; the next stage raised, its edge lit, tagged Next.",
    "Hard: the whole screen a full value darker (the ground,",
    "every tile, a shut tile a step under), the edges and the",
    "walked road in C's pale violet, Hard's chevrons by each",
    "mark, and one line under the road says what changes.",
    "The Shade wears the Brawler's paper mask: holes cut",
    "through, a carved grin, nothing painted on.",
]


# --- the results card ----------------------------------------------------------------------------------------------

def marks(t, x0, x1, y, rows, hard):
    """The four stages' marks on their road, as the picker's: lit from the first to where the player now stands, the
    next mark ringed in light, the stage just cleared with its check lit."""
    tab = 21 if hard else 0
    step = (x1 - x0 - 12 - 26 - tab) / 3
    xs = [x0 + 6 + k * step for k in range(4)]
    box(t, x0, y - 3, x1, y + 3, C["channel"], C["row"], 1.0, 2)
    nxt = next((k for k, r in enumerate(rows) if r == "next"), None)
    end = xs[nxt] + 13 if nxt is not None else x1 - 1
    box(t, x0 + 1, y - 1.5, end, y + 1.5, LIT[hard], cut=1)
    for k, row in enumerate(rows):
        bx, by = xs[k], y - 13
        if row == "next":
            d = t.poly(ui.cut_box(bx - 3, by - 3, bx + 29 + tab, by + 29, 6, 6, 6, 6))
            t.glow(d, 5.0, LIT[hard], 0.45)
            t.line(d, 2.0, LIT[hard])
        badge(t, bx, by, k + 1, hard, row != "shut")
        if row == "just":
            t.glow(circle(t, bx, by, 7.5), 5.0, C["ready"], 0.7)
        if row in ("cleared", "just"):
            check(t, bx, by, 7.5 if row == "just" else 6)


def results(t, st):
    """The card at a run's end (StageScreen.Results), over the street dimmed under it."""
    hard, lost = st["hard"], st.get("lost", False)
    t.paint(np.full_like(t.x, -1.0), C["channel"], 0.5)
    roblox(t)
    x0, x1 = 124, 444
    cx = (x0 + x1) / 2
    rows = [("marks", 30), ("title", 28), ("time", 22)]
    if st.get("gave"):
        rows.append(("gave", 28))
    if st.get("opened"):
        rows.append(("opened", 34 if st["opened"] == "Hard" else 20))
    inner = sum(h for _, h in rows) + 8 * (len(rows) - 1)
    total = 12 + inner + 14 + TAP + 10
    y0 = max(BAND + 4, BAND + (H - BAND - total) / 2)
    y1 = y0 + total
    t.glow(t.poly(ui.cut_box(x0, y0, x1, y1, 8, 8, 8, 8)), 8.0, C["channel"], 0.6)
    box(t, x0, y0, x1, y1, PANEL[hard], C["accent"] if hard else C["edge"], 1.4, 8)
    y = y0 + 12
    for kind, h in rows:
        if kind == "marks":
            marks(t, x0 + 16, x1 - 16, y + h / 2, st["marks"], hard)
        elif kind == "title":
            t.text(cx, y + 2, BIG, st["title"], HURT if lost else C["text"], align="CENTER", bold=0.3)
        elif kind == "time" and lost:
            t.text(cx, y + 3, SMALL, st["said"], C["soft"], align="CENTER")
        elif kind == "time" and st.get("new_best"):
            tw, chip = wide_of(st["time"], TITLE), wide_of("a new best", SMALL) + 18
            left = cx - (tw + 10 + chip) / 2
            t.text(left, y + 2, TITLE, st["time"], C["text"], bold=0.2)
            box(t, left + tw + 10, y, left + tw + 10 + chip, y + 22, (C["well"], C["well"]), C["ready"], 1.2, 4)
            t.text(left + tw + 10 + chip / 2, y + 4, SMALL, "a new best", C["ready"], align="CENTER", bold=0.2)
        elif kind == "time":
            t.text(cx, y + 3, SMALL, f"{st['time']}   ·   best {st['best']}", C["soft"], align="CENTER")
        elif kind == "gave":
            chips = [(what, words, MINT if what == "credits" else C["text"]) for what, words in st["gave"]]
            widths = [38 + wide_of(words, TITLE) + 8 for _, words, _ in chips]
            left = cx - (sum(widths) + 6 * (len(chips) - 1)) / 2
            for (what, words, colour), cw in zip(chips, widths):
                box(t, left, y, left + cw, y + h, (C["well"], C["well"]), C["row"], 1.0, 4)
                icon(t, what, left + 5, y + 3, 22)
                t.text(left + 33, y + 6, TITLE, words, colour, bold=0.2)
                left += cw + 6
        elif kind == "opened" and st["opened"] == "Hard":
            box(t, x0 + 16, y, x1 - 16, y + h, (C["glass"], C["channel"]), C["accent"], 1.4, 5)
            t.text(cx, y + 6, BIG, "Hard is open", C["ready"], align="CENTER", bold=0.3)
            for side in (-1, 1):
                chevrons(t, cx + side * (wide_of("Hard is open", BIG) / 2 + 18), y + h / 2, 13, C["accent"])
        elif kind == "opened":
            t.text(cx, y + 1, TITLE, st["opened"], C["ready"], align="CENTER", bold=0.25)
        y += h + 8
    py = y1 - 10 - TAP
    presses = st["presses"]
    widths = [p[2] for p in presses]
    left = cx - (sum(widths) + 6 * (len(widths) - 1)) / 2
    for words, kind, wide, into_hard in presses:
        press(t, left, py, left + wide, py + TAP, words, kind, TITLE, hard=into_hard)
        left += wide + 6


def card(sheet, ox, oy, state):
    t = sheet.tile(ox, oy, W, H)
    ui.world(t, "noon")
    results(t, state)


CARDS = [
    ("Normal: Stage 3 cleared, a new best, Stage 4 opens", dict(
        hard=False, marks=["cleared", "cleared", "just", "next"], title="Stage 3 cleared", time="3:05", new_best=True,
        gave=[("credits", "+240"), ("shards", "+2"), ("shade_chest", "+1")], opened="Stage 4 is open",
        presses=[("Retry", "quiet", 82, False), ("Stage 4", "one", 124, False), ("Home", "quiet", 82, False)])),
    ("Normal: the Lamplighter beaten, and Hard opens", dict(
        hard=False, marks=["cleared", "cleared", "cleared", "just"], title="Stage 4 cleared", time="4:12", new_best=True,
        gave=[("credits", "+600"), ("shards", "+3"), ("keeper_chest", "+1")], opened="Hard",
        presses=[("Retry", "quiet", 82, False), ("Stage 1", "one", 124, True), ("Home", "quiet", 82, False)])),
    ("Hard: Stage 2 cleared again, not a best, Stage 3 open", dict(
        hard=True, marks=["cleared", "just", "next", "shut"], title="Hard Stage 2 cleared", time="3:58", best="3:40",
        gave=[("credits", "+520"), ("shards", "+1")], opened=None,
        presses=[("Retry", "quiet", 82, False), ("Stage 3", "one", 124, True), ("Home", "quiet", 82, False)])),
    ("Lost: the lead fell on Stage 3", dict(
        hard=False, lost=True, marks=["cleared", "cleared", "next", "shut"], title="Your lead fell",
        said="Stage 3: try it again, or grow first",
        presses=[("Retry", "one", 170, False), ("Home", "quiet", 124, False)])),
]
CARD_NOTES = [
    "The card at a run's end, over the street, on the picker's kit. The four marks sit on their road, lit on to where",
    "the player now stands: the light runs on along the road as the card opens. Then the stage cleared, its time (a new",
    "best in gold), what it gave on the game's own pictures (Credits in their mint), what it opened, and Retry, Next,",
    "Home, with Next the one sand press. Hard: the card a full value darker, its edge, chevrons and road violet.",
    "\"Hard is open\" is its own band, gold words in a violet edge. A lost run: the lead fell, and Retry is the press.",
    "2: Faber's card has no Next after the keeper on Normal (StageService: Next is nil). Hard 1 is drawn as a proposal.",
    "Stand-ins: the times, what each stage gives, the street. Every tap 44, no text under 14 (rendered).",
]


# --- the run's line ------------------------------------------------------------------------------------------------

LINE_H = 130


def stage_line(t, st):
    """The run at the top of the screen (StageController's label): the stage's mark and name, its Shades on a short road
    to its last foe's ring, and Faber's words. The ring lights when the last foe is up, and takes a check once it's
    down. On the keeper's stage there's no count: the road runs straight to the keeper."""
    hard, quota, kills, last = st["hard"], st["quota"], st["kills"], st["last"]
    x0, x1, y0, y1 = 100, 468, BAND + 4, BAND + 48
    box(t, x0, y0, x1, y1, PANEL[hard], C["accent"] if hard else C["edge"], 1.2, 6)
    badge(t, x0 + 8, y0 + 9, st["stage"], hard, True)
    tx = x0 + 8 + 26 + (24 if hard else 0) + 10
    name = ("Hard " if hard else "") + f"Stage {st['stage']}"
    t.text(tx, y0 + 6, TITLE, name, C["text"], bold=0.25)
    if quota:
        t.text(tx + wide_of(name, TITLE) + 12, y0 + 8, SMALL, f"{kills} / {quota} Shades", C["text"])
        right = ("its last foe down" if kills < quota else "cleared") if last else "then its last foe"
    else:
        right = "cleared" if last else "the keeper"
    t.text(x1 - 10, y0 + 8, SMALL, right, C["soft"], align="RIGHT")
    rx0, rx1, ry, ex = tx, x1 - 30, y0 + 34, x1 - 16
    up = quota == 0 or kills >= quota
    box(t, rx0, ry - 3, ex - 6, ry + 3, C["channel"], C["row"], 1.0, 2)
    for i in range(1, quota):
        x = rx0 + i * (rx1 - rx0) / quota
        t.stroke([(x, ry - 2.5), (x, ry + 2.5)], 1.0, C["row"])
    lit = ex - 6 if up else rx0 + kills / quota * (rx1 - rx0)
    if lit > rx0 + 1:
        box(t, rx0 + 1, ry - 1.5, lit, ry + 1.5, LIT[hard], cut=1)
    if last:
        check(t, ex, ry, 7.5)
    elif up:                                         # the last foe is up: its ring lit through
        t.glow(circle(t, ex, ry, 6.5), 5.0, LIT[hard], 0.6)
        t.paint(circle(t, ex, ry, 6.5), LIT[hard])
        t.paint(circle(t, ex, ry, 2.2), C["ink"])
    else:
        t.paint(circle(t, ex, ry, 6.5), C["channel"])
        t.paint(np.abs(circle(t, ex, ry, 6.5)) - 1.2, C["row"])


def line_strip(sheet, ox, oy, state):
    t = sheet.tile(ox, oy, W, LINE_H)
    ui.world(t, "noon")
    roblox(t)
    stage_line(t, state)


LINES = [
    ("Stage 2: seven of its ten Shades down", dict(hard=False, stage=2, quota=10, kills=7, last=False)),
    ("Stage 2: all ten down, its last foe up", dict(hard=False, stage=2, quota=10, kills=10, last=False)),
    ("Hard Stage 4: the keeper", dict(hard=True, stage=4, quota=0, kills=0, last=False)),
    ("Stage 2 cleared", dict(hard=False, stage=2, quota=10, kills=10, last=True)),
]
LINE_NOTES = [
    "The run at the top of the screen, under Roblox's top bar, on the picker's kit: the stage's mark and name, its",
    "Shades on a short road (a notch a Shade) lit as they fall, to its last foe's ring, and Faber's words at the right.",
    "The ring lights when the last foe is up, and takes a check once the stage is cleared. On the keeper's stage the",
    "road runs straight to the keeper. Hard: the plate a full value darker, its edge, chevrons and road violet.",
]


# --- the sheets ----------------------------------------------------------------------------------------------------

def sheet_of(out, name, title, cells, cell_h, notes, draw):
    """Each cell's phone (or strip) two across, its words over it; the notes in the empty slot, or under the cells."""
    ui.K = 2                                  # the smallest phone's own pixels: two a point
    gap, head_h = 24, 64
    rows = (len(cells) + 1) // 2
    under = len(cells) % 2 == 0
    width = gap + 2 * (W + gap)
    height = head_h + rows * (cell_h + 40) + (len(notes) * 23 + 10 if under else 0) + 10
    sheet = ui.Sheet(width, height, "#101117")
    t = sheet.tile(0, 0, width, height)
    t.text(gap, 18, 20, title, "#EDE6D6", bold=0.2)
    spots = []
    for k, (said, state) in enumerate(cells):
        x, y = gap + (k % 2) * (W + gap), head_h + (k // 2) * (cell_h + 40)
        t.text(x, y - 4, SMALL, f"{k + 1}. {said}", "#B4AC9C")
        draw(sheet, x, y + 16, state)
        spots.append((x, y + 16))
    x, y = (gap, head_h + rows * (cell_h + 40)) if under else (gap + W + gap, head_h + (rows - 1) * (cell_h + 40) + 16)
    for k, words in enumerate(notes):
        t.text(x + 8, y + 6 + k * 23, SMALL, words, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / name)
    return [sheet.px[round(y * 2):round((y + cell_h) * 2), round(x * 2):round((x + W) * 2)] for x, y in spots]


def main():
    out = bl.out_dir()
    if sys.argv[-1] == "pictures":            # the pictures alone, for a quick look
        pictures(out)
        return
    common = "in AR40's C, at the smallest phone (568 x 320 points)"
    picks = sheet_of(out, "stage_screen_A.png", f"AR42, the stages' picker, A: One road, {common}", PICKS, H,
                     PICK_NOTES, picker)
    cards = sheet_of(out, "stage_results.png", f"AR42, the results card, in A, {common}", CARDS, H, CARD_NOTES, card)
    sheet_of(out, "stage_line.png", f"AR42, the run's line at the top of the screen, in A, {common}", LINES, LINE_H,
             LINE_NOTES, line_strip)
    # the picker's three and the card's four at 64 pixels high, over dark: the content check's small read
    gap, small = 12, 64 / (H * 2)
    sw, sh = round(W * 2 * small), 64
    tiny = np.zeros((2 * (sh + gap) + gap, 4 * (sw + gap) + gap, 4), dtype=np.float32)
    tiny[..., :3], tiny[..., 3] = ui.c("#101117"), 1.0
    for r, shots in enumerate((picks, cards)):
        for k, shot in enumerate(shots):
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
