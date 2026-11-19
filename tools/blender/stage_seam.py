"""AR42: the stages' screens in Seam's lit glass, the kit Equipment and Settings wear (research's B, 15:04): the picker,
the results card and the run's line. The director's 14:56 scope moves the picker from AR40's C to Seam; research's pass
(16:34) moves the card and the line with it, for one look.

The layout is A's, One road (research's pick, 02:06): the four stages side by side over one road, lit to where the
player stands, the next one raised and tagged. The pictures are stage_screen.py's: the Shade in the Brawler's paper
mask, the elite with its second mask, the Lamplighter's lantern. What changes is the glass:
    - every tile lighter at its top, its hairline lit from above, with the kit's corner glint;
    - every picture on its light (research's must-fix 1, 16:34): the Shade's Void body lifted at its top, rimmed by the
      tile's top light, a bloom behind it on every open tile, the next one's strongest;
    - the next tile washed with light, a glint down it once a loop;
    - the walked road a conduit filling with light, to a lit ring with the kit's comet round it;
    - the side of the switch chosen is the lit press, white falling to lavender, its sheen across once a loop.
Hard's one accent is an ember, white falling to coral (accepted, 16:34): the chosen Hard half, the edges, the chevrons,
the walked road, the ring and the bloom. Hard keeps Normal's value (must-fix 2, 16:34): nothing else darkens.

Measured in rendered points at the smallest phone (568 x 320), as stage_screen.py. Drawn in code; nothing is exported.

    blender -b --factory-startup --python tools/blender/stage_seam.py -- <abs out> [quick]

Writes:
    stage_seam.png               the picker's three states, with the notes
    stage_seam_results.png       the card's four states
    stage_seam_line.png          the line's four states
    stage_seam_64.png            the picker's three and the card's four at 64 pixels high
    stage_seam_close.png         the next tile, its road and the switch at the phone's own pixels, twice over
    stage_seam_strip.png         the picker's opening and the switch, Normal to Hard and back
    stage_seam_card_strip.png    the card's opening: its check, then the light running on
    stage_seam_line_strip.png    the line as a Shade falls, and as the last foe rises
    frames/f0000.png ...         the picker's clip (ffmpeg joins them; the frames are then deleted). "quick" skips it.
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

W, H = ss.W, ss.H
PAD, GAP = ss.PAD, ss.GAP
SMALL, TITLE = ss.SMALL, ss.TITLE
K, FPS = 2, 30
P = sk.LIT
LIGHT = up.SEAM["light"]

# Normal's light is the kit's; Hard's is an ember. Each: the edge and chevrons, a lit plate's fill, the road's fill, the
# bloom, a glow.
ACC = {False: dict(edge=LIGHT, lit=P["lit"], road=(P["facet"], LIGHT), bloom="#5C48AC", glow=P["lit"][1]),
       True: dict(edge="#FF9A80", lit=("#FFF4EE", "#FFB4A0"), road=("#C2503F", "#FFC2B2"), bloom="#E85A44",
                  glow="#FF9A80")}
# Hard keeps Normal's value (research's must-fix 2, 16:34): one ground, one tile, one shut tile for both.
GROUND, TILE, SHUT = P["backing"], P["panel"], ("#1C1834", "#110E20")
BLOOM = {False: 0.30, True: 0.24}            # the ground's bloom behind the next tile
PIC_BLOOM = {("next", False): 0.75, ("next", True): 0.55, ("open", False): 0.42, ("open", True): 0.32}
READY = "#FFD880"                            # Theme.Colour.Ready: what a run opened, a new best
VOID, VOID_LIFT = "#1B1728", "#2C2542"       # the Shade's own Void, and its lift (shade_sheet.py's PALETTE)

# The pictures' own colours, on Seam: stage_screen's C read for the shut silhouettes, the lock, the check and the bed.
ss.C.update(well="#262044", faint=P["faint"], text=P["text"], soft=P["soft"], ink=P["ink"], chosen=P["lit"],
            glass=sk.SOCKET_DARK[0], channel=sk.SOCKET_DARK[1], row=P["edge"], edge=P["facet"])
ss.SHADE_BODY = VOID                         # the model's own Void, not C's teal
SHADE_DIM = ss.shade


def shade_lit(t, cx, cy, s, elite=False, dim=False):
    """stage_screen's Shade on its light (research's must-fix 1, 16:34): its Void body lifted toward its top, and a rim
    of the tile's top light along every edge that faces up. Shut, it stays the dim silhouette."""
    if dim:
        return SHADE_DIM(t, cx, cy, s, elite, dim)
    hx, hy = cx, cy - s * 0.5
    outline = [(cx - s * 0.52, cy - s * 0.14), (cx + s * 0.52, cy - s * 0.14), (cx + s * 0.8, cy + s * 0.9),
               (cx - s * 0.8, cy + s * 0.9)]

    def body(x, y):
        return np.minimum.reduce([ui.sd_polygon(x, y, outline), np.hypot(x - hx, y - hy) - s * 0.38,
                                  np.hypot(x - cx + s * 0.52, y - cy - s * 0.05) - s * 0.22,
                                  np.hypot(x - cx - s * 0.52, y - cy - s * 0.05) - s * 0.22])
    d = body(t.x, t.y)
    t.glow(d, 4.0, ss.SHADE_GLOW, 0.3)
    top, foot = hy - s * 0.38, cy + s * 0.9
    t.paint(d, t.ramp(VOID_LIFT, VOID, np.clip((t.y - top) / (foot - top) * 1.6, 0, 1)))
    t.paint(d, LIGHT, 0.12 * np.exp(-(t.y - top) / (s * 0.45)))          # the top light falling on it
    t.line(d, 1.2, ss.SHADE_GLOW)
    lift = s * 0.16                                    # inside, with the point above outside: the edges facing up
    up_ = np.maximum(d, -body(t.x, t.y - lift))
    inside = np.minimum(d, 0)
    t.paint(up_, LIGHT, 0.3 * np.exp(inside / (lift * 0.9)))           # its spill, soft
    t.paint(up_, LIGHT, 0.9 * np.exp(inside / (lift * 0.35)))          # the rim: the outline thickening into light
    t.stroke([(hx - s * 0.37, hy - s * 0.1), (hx + s * 0.37, hy - s * 0.04)], s * 0.045, ss.PAPER_SHADE)
    ss.mask(t, hx + s * 0.13, hy + s * 0.02, s * 0.25, 0.32)
    if elite:
        t.stroke([(cx + s * 0.52, cy + s * 0.14), (cx + s * 0.2, cy - s * 0.14)], s * 0.05, ss.PAPER_SHADE)
        ss.mask(t, cx + s * 0.54, cy + s * 0.18, s * 0.17, 0.22)


ss.shade = shade_lit                         # stage_screen's picture() draws it

TOP, Y1, RY = ss.TOP + 6, 266, 280          # the tiles' top and foot, the road's middle (A's)
WIDE = (W - 2 * PAD - 3 * GAP) / 4
XS = [PAD + k * (WIDE + GAP) for k in range(4)]
PIC = 86                                     # a tile's picture, tall
SWITCH = (W - PAD - 156, 7, W - PAD, 51)     # Normal and Hard, two halves in the band

STATES = [
    ("Normal: stages 1 and 2 cleared, 3 next, 4 shut", dict(
        hard=False, hard_shut=True, cp="1,480",
        rows=[("cleared", "420", "Best 2:41"), ("cleared", "780", "Best 3:05"), ("next", "1,250", "Not cleared"),
              ("shut", "2,100", "Clear Stage 3 first")])),
    ("Hard while it's shut: the same player taps Hard", dict(
        hard=True, hard_shut=True, cp="1,480",
        rows=[("shut", "4,800", None), ("shut", "6,900", None), ("shut", "9,400", None), ("shut", "13,000", None)])),
    ("Hard open, later: Hard 1 cleared, 2 next, 3 and 4 shut", dict(
        hard=True, hard_shut=False, cp="6,200",
        rows=[("cleared", "4,800", "Best 3:52"), ("next", "6,900", "Not cleared"), ("shut", "9,400", "Clear Stage 2 first"),
              ("shut", "13,000", "Clear Stage 3 first")])),
]
NOTES = [
    "A's One road in Seam's lit glass, the kit Equipment wears.",
    "Every tile is lighter at its top, its hairline lit from above.",
    "Every picture on its light: the Shade lifted at its top and",
    "rimmed by the tile's light, a bloom behind every open one.",
    "The next is raised and washed with light, a glint down it",
    "once a loop. The walked road fills with light to a lit ring,",
    "the comet round it. The switch's chosen side is the lit press.",
    "Hard keeps Normal's value: its one accent, an ember, on the",
    "chosen half, the edges, the chevrons, the road, the ring and",
    "the bloom. The player's power stands at the road's start.",
]


def nxt(state):
    return next((k for k, r in enumerate(state["rows"]) if r[0] == "next"), None)


def bloom_at(state):
    k = nxt(state)
    return (XS[k] + WIDE / 2, TOP + 6 + PIC / 2) if k is not None else (W / 2, 170)


# --- the pieces ----------------------------------------------------------------------------------------------------

def lit_plate(t, x0, y0, x1, y1, acc, phase, cut=5.0, glow=0.45):
    """The kit's lit press: white falling to its light, a glow round it, its sheen across once a loop."""
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.glow(d, 7.0, acc["glow"], glow)
    t.paint(d, up.shade(t, acc["lit"], y0, y1))
    at = x0 - 30 + (x1 - x0 + 60) * phase
    t.paint(d, "#FFFFFF", 0.75 * np.exp(-(((t.x - at) + (t.y - y0) * 0.5) / 6) ** 2))
    t.paint(d, acc["lit"][1], 0.35 * np.clip((t.y - y0) / (y1 - y0) - 0.4, 0, 1))
    t.line(d, 1.0, "#FFFFFF", 0.9)
    return d


def quiet_plate(t, x0, y0, x1, y1, edge, cut=5.0):
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.paint(d, up.shade(t, P["button"], y0, y1))
    t.paint(d, P["glint"], 0.12 * np.exp(-np.maximum(t.y - y0, 0) / 9))
    top = np.clip(1 - (t.y - y0) / (y1 - y0), 0, 1)
    t.line(d, 1.0, edge, 0.45 + 0.45 * top)
    return d


def ground(t, state):
    hard = state["hard"]
    whole = t.poly([(0, 0), (W, 0), (W, H), (0, H)])
    t.paint(whole, t.ramp(GROUND[0], GROUND[1], t.y / H))
    bx, by = bloom_at(state)
    t.paint(whole, ACC[hard]["bloom"], BLOOM[hard] * np.exp(-(((t.x - bx) / 150) ** 2 + ((t.y - by) / 120) ** 2)))
    t.paint(whole, P["glint"], 0.06 * np.exp(-t.y / 40))


def band(t, state, phase):
    """Equipment's band: Roblox's buttons (a stand-in), Back, the ground's name, and the switch. The player's power
    doesn't fit beside them at the smallest phone: it stands at the road's start (foot)."""
    hard = state["hard"]
    up.box(t, 6, 8, 160, 50, P["channel"], P["edge"], 1.0, 6)
    t.text(83, 15, SMALL, "Roblox's", P["faint"], "CENTER")
    t.text(83, 31, SMALL, "buttons", P["faint"], "CENTER")
    t.text(196, 22, SMALL, "<  BACK", P["text"], "CENTER", bold=0.3)
    t.stroke([(178, 44), (214, 44)], 1.4, LIGHT, 0.8)
    t.text(232, 20, TITLE, "Lantern Row", P["text"], bold=0.35)
    x0, y0, x1, y1 = SWITCH
    mid = (x0 + x1) / 2
    halves = ((x0, mid - 1), (mid + 1, x1))
    for k, (a, b) in enumerate(halves):
        chosen = (k == 1) == hard
        if chosen:
            lit_plate(t, a, y0, b, y1, ACC[hard], phase)
        else:
            quiet_plate(t, a, y0, b, y1, ACC[True]["edge"] if k == 1 else P["facet"])
    y = (y0 + y1) / 2 - SMALL * 0.36
    t.text((x0 + mid) / 2, y, SMALL, "Normal", P["text"] if hard else P["ink"], "CENTER", bold=0.3)
    ss.chevrons(t, mid + 17, (y0 + y1) / 2, 11, P["ink"] if hard else ACC[True]["edge"])
    t.text(mid + 28, y, SMALL, "Hard", P["ink"] if hard else P["text"], bold=0.3)
    if state["hard_shut"]:
        ss.lock(t, x1 - 9, y0 + 9, 10, P["ink"] if hard else P["soft"])


def badge(t, x, y, n, hard, lit):
    """A stage's mark: its number on a lit plate (or the well's, shut); on Hard, Hard's chevrons beside it."""
    s = 26
    if lit:
        d = t.poly(ui.cut_box(x, y, x + s, y + s, 5, 5, 5, 5))
        t.glow(d, 4.0, ACC[hard]["glow"], 0.3)
        t.paint(d, up.shade(t, ACC[hard]["lit"], y, y + s))
        t.paint(d, "#FFFFFF", 0.5 * np.exp(-np.maximum(t.y - y, 0) / 4))
        t.line(d, 1.0, "#FFFFFF", 0.9)
    else:
        up.box(t, x, y, x + s, y + s, P["well"], P["edge"], 1.0, 5)
    t.text(x + s / 2, y + s / 2 - 6.5, TITLE, str(n), P["ink"] if lit else P["soft"], "CENTER", bold=0.3)
    if hard:
        up.box(t, x + s + 3, y, x + s + 21, y + s, ("#2A1626", "#170C16"), ACC[True]["edge"], 1.0, 4)
        ss.chevrons(t, x + s + 12, y + s / 2, 11, ACC[True]["edge"])


def window(t, x0, y0, x1, y1, kind, state, hard, n):
    """A tile's picture on its violet-black bed, a bloom behind who stands there unless it's shut."""
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 4, 4, 4, 4))
    t.paint(d, up.shade(t, sk.SOCKET_DARK, y0, y1))
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2 + 2
    if state != "shut":                      # every picture on its light: the next one's bloom, softer on the rest
        strength = PIC_BLOOM[("next" if state == "next" else "open", hard)]
        t.paint(d, ACC[hard]["bloom"], strength * np.exp(-(((t.x - cx) / ((x1 - x0) * 0.38)) ** 2 +
                                                           ((t.y - cy - 6) / ((y1 - y0) * 0.42)) ** 2)))
    t.line(d, 1.0, P["edge"], 0.8)
    s = (y1 - y0) * 0.42
    ss.picture(t, kind, cx, cy, s, dim=state == "shut")
    if state == "shut":
        ss.lock(t, cx, cy + s * 0.1, s * 0.62, P["soft"])
    badge(t, x0 + 4, y0 + 4, n, hard, state != "shut")
    if state == "cleared":
        ss.check(t, x1 - 15, y0 + 15, 10)


def tile_text(t, x0, x1, y, title, row):
    state, cp, said = row
    cx, shut = (x0 + x1) / 2, state == "shut"
    t.text(cx, y, TITLE, title, P["soft"] if shut else P["text"], "CENTER", bold=0.3)
    t.text(cx, y + 22, SMALL, "Recommended", P["soft"], "CENTER")
    t.text(cx, y + 38, TITLE, f"{cp} CR", P["soft"] if shut else P["text"], "CENTER", bold=0.25)
    for k, words in enumerate(said or ()):
        t.text(cx, y + 60 + k * 17, SMALL, words, P["text"] if state == "next" else P["soft"], "CENTER")


def tile(t, k, row, hard, phase):
    n, title, kind = ss.STAGES[k]
    state = row[0]
    acc = ACC[hard]
    lift = 6 if state == "next" else 0
    x0, y0, x1, y1 = XS[k], TOP - lift, XS[k] + WIDE, Y1
    d = t.poly(ui.cut_box(x0, y0, x1, y1, 6, 6, 6, 6))
    if state == "next":
        t.glow(d, 8.0, acc["glow"], 0.38)
    t.paint(d, up.shade(t, SHUT if state == "shut" else TILE, y0, y1))
    down = np.clip(1 - (t.y - y0) / ((y1 - y0) * 0.85), 0, 1)
    if state != "shut":
        t.paint(d, P["glint"], 0.11 * np.exp(-np.maximum(t.y - y0, 0) / 24))       # the kit's top sheen
    if state == "next":
        t.paint(d, acc["edge"], 0.12 * down)                                       # washed with its light
        at = y0 - 40 + (y1 - y0 + 80) * phase                                      # a glint down it, once a loop
        t.paint(d, P["glint"], 0.14 * np.exp(-(((t.y - at) + (t.x - x0) * 0.35) / 10) ** 2))
        t.line(d, 2.0, acc["edge"], 0.55 + 0.45 * down)
    elif state == "shut":
        t.line(d, 1.0, P["edge"], 0.8)
    else:
        t.line(d, 1.0, acc["edge"] if hard else P["facet"], 0.3 + 0.6 * down)
        t.line(d, 1.3, P["glint"], 0.7 * np.exp(-np.hypot(t.x - x0 - 24, t.y - y0) / 46))   # the corner glint
    window(t, x0 + 6, y0 + 6, x1 - 6, y0 + 6 + PIC, kind, state, hard, n)
    if state == "next":
        tag = (x1 - 52, y0 - 9, x1 - 6, y0 + 11)
        lit_plate(t, *tag, acc, phase, cut=4, glow=0.3)
        t.text((tag[0] + tag[2]) / 2, tag[1] + 3, SMALL, "Next", P["ink"], "CENTER", bold=0.3)
    tile_text(t, x0, x1, y0 + PIC + 14, title, ss.wrapped(row))


def ring(t, cx, cy, hard, phase, scale=1.0):
    """Where the player stands: a lit disc, its outer ring lit from above with the kit's comet round it."""
    acc = ACC[hard]
    r = 7.5 * scale
    dist = np.hypot(t.x - cx, t.y - cy)
    disc = dist - r
    t.glow(disc, 7.0, acc["glow"], 0.55)
    t.paint(disc, up.shade(t, acc["lit"], cy - r, cy + r))
    t.paint(disc, "#FFFFFF", 0.6 * np.exp(-np.maximum(t.y - cy + r, 0) / (r * 0.35)))
    t.line(disc, 1.0, "#FFFFFF", 0.9)
    outer = dist - (r + 4.5 * scale)
    ang = np.arctan2(t.y - cy, t.x - cx)
    t.line(outer, 1.2, acc["edge"], 0.3 + 0.55 * (1 - np.sin(ang)) / 2)
    sk.NOW["phase"] = phase
    sk.comet(t, outer, ang, 1.8)


def road(t, state, phase, run=1.0, ring_scale=1.0, track=True):
    """The road along the tiles' feet: a dark conduit, filled with light from the first tile to the ring."""
    hard = state["hard"]
    acc = ACC[hard]
    if track:
        d = t.poly(ui.cut_box(PAD, RY - 5, W - PAD, RY + 5, 4, 4, 4, 4))
        t.paint(d, P["channel"])
        t.line(d, 1.0, P["edge"], 0.9)
    k = nxt(state)
    if k is None:
        return
    end = XS[k] + WIDE / 2
    at = PAD + 2 + (end - PAD - 2) * run
    if at > PAD + 4:
        fill = t.poly(ui.cut_box(PAD + 2, RY - 3, at, RY + 3, 2, 0, 0, 2))
        t.paint(fill, t.ramp(acc["road"][0], acc["road"][1], np.clip((t.x - PAD) / max(end - PAD, 1), 0, 1)))
        t.paint(fill, "#FFFFFF", 0.35 * np.exp(-np.maximum(t.y - RY + 3, 0) / 1.5))
        t.glow(fill, 4.0, acc["edge"], 0.22)
        if run >= 1.0:                                     # a light along the walked road, once a loop
            go = PAD + (end - PAD) * phase
            t.paint(fill, "#FFFFFF", 0.55 * np.exp(-((t.x - go) / 14) ** 2))
    if ring_scale > 0:
        ring(t, end, RY, hard, phase, ring_scale)


def foot(t, state):
    """Under the road: the player's own power at its start, where they stand; on Hard, what changes, at the right."""
    y = RY + 15
    t.text(PAD + 2, y, SMALL, "Your power", P["soft"])
    t.text(PAD + 84, y - 2, TITLE, f"{state['cp']} CR", P["text"], bold=0.3)
    if state["hard"]:
        words = ss.KEEPER_WHY_LONG if state["hard_shut"] else ss.HARD_SAYS
        t.text(W - PAD - 2, y, SMALL, words, P["text"], "RIGHT")


def phone(sheet, ox, oy, state, phase=0.0, parts="all", run=1.0, ring_scale=1.0):
    """The picker. parts: "all"; "bare", the ground and the band; "tracked", all but the road's light and ring."""
    t = sheet.tile(ox, oy, W, H)
    ground(t, state)
    band(t, state, phase)
    if parts == "bare":
        return
    for k in range(4):
        tile(t, k, state["rows"][k], state["hard"], phase)
    if parts == "tracked":
        road(t, state, phase, run=0.0, ring_scale=0.0)
    else:
        road(t, state, phase, run, ring_scale)
    foot(t, state)


# --- the results card and the run's line ---------------------------------------------------------------------------

def stand_in(t):
    """Roblox's own buttons at the top bar's left, as the picker's band draws them: a stand-in."""
    up.box(t, 6, 8, 160, 50, P["channel"], P["edge"], 1.0, 6)
    t.text(83, 15, SMALL, "Roblox's", P["faint"], "CENTER")
    t.text(83, 31, SMALL, "buttons", P["faint"], "CENTER")


def glass(t, x0, y0, x1, y1, hard, cut=8.0, width=1.2):
    """A tile's glass, as a plate over the world: its shadow under it, lighter at its top, its hairline lit from above
    (ember on Hard), the corner glint."""
    d = t.poly(ui.cut_box(x0, y0, x1, y1, cut, cut, cut, cut))
    t.glow(t.poly(ui.cut_box(x0, y0 + 3, x1, y1 + 3, cut, cut, cut, cut)), 8.0, P["channel"], 0.6)
    t.paint(d, up.shade(t, TILE, y0, y1))
    t.paint(d, P["glint"], 0.11 * np.exp(-np.maximum(t.y - y0, 0) / 24))
    down = np.clip(1 - (t.y - y0) / ((y1 - y0) * 0.85), 0, 1)
    t.line(d, width, ACC[True]["edge"] if hard else P["facet"], 0.35 + 0.6 * down)
    t.line(d, 1.3, P["glint"], 0.85 * np.exp(-np.hypot(t.x - x0 - 24, t.y - y0) / 46))
    return d


def fill(t, x0, x1, y, half, acc, span_x1=None):
    """A road's light from x0 to x1: its colour along the whole road (to span_x1), lit at its top edge, glowing."""
    span = (span_x1 or x1) - x0
    f = t.poly(ui.cut_box(x0, y - half, x1, y + half, 1, 0, 0, 1))
    t.paint(f, t.ramp(acc["road"][0], acc["road"][1], np.clip((t.x - x0) / max(span, 1), 0, 1)))
    t.paint(f, "#FFFFFF", 0.35 * np.exp(-np.maximum(t.y - y + half, 0) / 1.2))
    t.glow(f, 3.5, acc["edge"], 0.22)


def press(t, x0, y0, x1, y1, words, kind, into_hard, phase=0.0):
    """The one press is the lit press (an ember into a Hard stage, with Hard's chevrons); the rest are quiet."""
    if kind == "one":
        lit_plate(t, x0, y0, x1, y1, ACC[into_hard], phase)
        colour = P["ink"]
    else:
        quiet_plate(t, x0, y0, x1, y1, P["facet"])
        colour = P["text"]
    cx, cy = (x0 + x1) / 2 + (8 if into_hard else 0), (y0 + y1) / 2
    if into_hard:
        ss.chevrons(t, cx - ss.wide_of(words, TITLE) / 2 - 11, cy, 12, colour)
    t.text(cx, cy - TITLE * 0.36, TITLE, words, colour, "CENTER", bold=0.3)


def marks(t, x0, x1, y, rows, hard, run=1.0, pop=1.0):
    """The four stages' marks on their road, as the picker's: lit to the stage just cleared, then on (`run`) to where
    the player now stands; the next mark ringed in light; the one just cleared with its check lit (`pop` its size)."""
    acc = ACC[hard]
    tab = 21 if hard else 0
    step = (x1 - x0 - 12 - 26 - tab) / 3
    xs = [x0 + 6 + k * step for k in range(4)]
    d = t.poly(ui.cut_box(x0, y - 3, x1, y + 3, 2, 2, 2, 2))
    t.paint(d, P["channel"])
    t.line(d, 1.0, P["edge"], 0.9)
    nxt_ = next((k for k, r in enumerate(rows) if r == "next"), None)
    just = next((k for k, r in enumerate(rows) if r == "just"), None)
    end = xs[nxt_] + 13 if nxt_ is not None else x1 - 1
    start = xs[just] + 13 if just is not None else end
    at = start + (end - start) * run
    fill(t, x0 + 1, at, y, 2, acc, end)
    for k, row in enumerate(rows):
        bx, by = xs[k], y - 13
        if row == "next":
            ring_in = float(np.clip((run - 0.75) / 0.25, 0, 1))
            if ring_in > 0:
                r = t.poly(ui.cut_box(bx - 3, by - 3, bx + 29 + tab, by + 29, 6, 6, 6, 6))
                t.glow(r, 6.0, acc["glow"], 0.5 * ring_in)
                t.line(r, 2.0, acc["edge"], ring_in)
        badge(t, bx, by, k + 1, hard, row != "shut")
        if row == "cleared":
            ss.check(t, bx, by, 6)
        if row == "just" and pop > 0:                # the stage just cleared: its check, lit, at the badge's corner
            t.glow(np.hypot(t.x - bx, t.y - by) - 7.5 * pop, 5.0, acc["glow"], 0.7 * min(pop, 1.0))
            ss.check(t, bx, by, 7.5 * pop)


def results(t, st, run=1.0, pop=1.0, phase=0.0):
    """The card at a run's end (StageScreen.Results), on the picker's glass over the street dimmed under it. `run` and
    `pop` are the marks' beats as it opens: the check popping in, then the light running on."""
    hard, lost = st["hard"], st.get("lost", False)
    x0, x1 = 124, 444
    cx = (x0 + x1) / 2
    spans = [("marks", 30), ("title", 28), ("time", 22)]
    if st.get("gave"):
        spans.append(("gave", 28))
    if st.get("opened"):
        spans.append(("opened", 34 if st["opened"] == "Hard" else 20))
    inner = sum(h for _, h in spans) + 8 * (len(spans) - 1)
    total = 12 + inner + 14 + ss.TAP + 10
    y0 = max(ss.BAND + 4, ss.BAND + (H - ss.BAND - total) / 2)
    y1 = y0 + total
    glass(t, x0, y0, x1, y1, hard, 8, 1.4)
    y = y0 + 12
    for kind, h in spans:
        if kind == "marks":
            marks(t, x0 + 16, x1 - 16, y + h / 2, st["marks"], hard, run, pop)
        elif kind == "title":
            t.text(cx, y + 2, ss.BIG, st["title"], ss.HURT if lost else P["text"], "CENTER", bold=0.35)
        elif kind == "time" and lost:
            t.text(cx, y + 3, SMALL, st["said"], P["soft"], "CENTER")
        elif kind == "time" and st.get("new_best"):
            tw, chip = ss.wide_of(st["time"], TITLE), ss.wide_of("a new best", SMALL) + 18
            left = cx - (tw + 10 + chip) / 2
            t.text(left, y + 2, TITLE, st["time"], P["text"], bold=0.3)
            up.box(t, left + tw + 10, y, left + tw + 10 + chip, y + 22, sk.SOCKET_DARK, READY, 1.2, 4)
            t.text(left + tw + 10 + chip / 2, y + 4, SMALL, "a new best", READY, "CENTER", bold=0.3)
        elif kind == "time":
            t.text(cx, y + 3, SMALL, f"{st['time']}   ·   best {st['best']}", P["soft"], "CENTER")
        elif kind == "gave":
            chips = [(what, words, ss.MINT if what == "credits" else P["text"]) for what, words in st["gave"]]
            widths = [38 + ss.wide_of(words, TITLE) + 8 for _, words, _ in chips]
            left = cx - (sum(widths) + 6 * (len(chips) - 1)) / 2
            for (what, words, colour), cw in zip(chips, widths):
                up.box(t, left, y, left + cw, y + h, P["well"], P["edge"], 1.0, 4)
                ss.icon(t, what, left + 5, y + 3, 22)
                t.text(left + 33, y + 6, TITLE, words, colour, bold=0.3)
                left += cw + 6
        elif kind == "opened" and st["opened"] == "Hard":
            band_ = t.poly(ui.cut_box(x0 + 16, y, x1 - 16, y + h, 5, 5, 5, 5))
            t.glow(band_, 6.0, ACC[True]["glow"], 0.3)
            t.paint(band_, up.shade(t, sk.SOCKET_DARK, y, y + h))
            t.paint(band_, ACC[True]["bloom"], 0.35 * np.exp(-((t.x - cx) / 110) ** 2))
            t.line(band_, 1.4, ACC[True]["edge"])
            t.text(cx, y + 6, ss.BIG, "Hard is open", READY, "CENTER", bold=0.35)
            for side in (-1, 1):
                ss.chevrons(t, cx + side * (ss.wide_of("Hard is open", ss.BIG) / 2 + 18), y + h / 2, 13,
                            ACC[True]["edge"])
        elif kind == "opened":
            t.text(cx, y + 1, TITLE, st["opened"], READY, "CENTER", bold=0.3)
        y += h + 8
    py = y1 - 10 - ss.TAP
    widths = [p[2] for p in st["presses"]]
    left = cx - (sum(widths) + 6 * (len(widths) - 1)) / 2
    for words, kind, wide, into_hard in st["presses"]:
        press(t, left, py, left + wide, py + ss.TAP, words, kind, into_hard, phase)
        left += wide + 6


def card(sheet, ox, oy, st, **beat):
    """The card over the street (ui_sheet's noon stand-in), dimmed under it, with Roblox's buttons."""
    t = sheet.tile(ox, oy, W, H)
    ui.world(t, "noon")
    t.paint(np.full_like(t.x, -1.0), P["channel"], 0.5)
    stand_in(t)
    results(t, st, **beat)


CARD_NOTES = [
    "The card at a run's end, over the street, on the picker's glass. The four marks sit on their road, lit to the stage",
    "just cleared, then on to where the player now stands, the next mark ringed in light. Then the stage cleared, its time",
    "(a new best in Ready's gold), what it gave on the game's own pictures (Credits in their mint), what it opened, and",
    "Retry, Next and Home, with Next the lit press. Hard keeps Normal's value: its edge, road, chevrons and a press into a",
    "Hard stage are the ember. \"Hard is open\" is its own band, gold words over an ember glow. A lost run: the lead fell,",
    "and Retry is the press. 2: Faber's card has no Next after the keeper on Normal (StageService: Next is nil); Hard 1",
    "is drawn as a proposal. Stand-ins: the times, what each stage gives, the street. Every tap 44, no text under 14.",
]
CARD_BEATS = [        # the card's opening, on the first card: Equipment's rise and fade, then the marks' two beats
    ("0.22 s: the card is in, the road lit to Stage 3", dict(run=0.0, pop=0.0)),
    ("0.34 s: Stage 3's check pops in, a little over", dict(run=0.0, pop=1.3)),
    ("0.50 s: the light runs on toward Stage 4", dict(run=0.55, pop=1.0)),
    ("0.70 s: Stage 4 rings in light; the press's sheen", dict(run=1.0, pop=1.0, phase=0.45)),
]

LINE_H = ss.LINE_H


def stage_line(t, st, kills=None, flash=0.0, ring_pop=1.0):
    """The run under Roblox's top bar (StageController's label), on the picker's glass: the stage's mark and name, its
    Shades on a short road (a notch a Shade) lit as they fall, to its last foe's ring, and Faber's words at the right.
    The ring lights when the last foe is up and takes a check once the stage is cleared; on the keeper's stage the road
    runs straight to the keeper. `kills` may fall between two counts (the light easing on a notch); `flash`, the light
    at its head; `ring_pop`, the ring's size as it lights."""
    hard, quota, last = st["hard"], st["quota"], st["last"]
    kills = st["kills"] if kills is None else kills
    acc = ACC[hard]
    x0, x1, y0, y1 = 100, 468, ss.BAND + 4, ss.BAND + 48
    glass(t, x0, y0, x1, y1, hard, 6, 1.2)
    badge(t, x0 + 8, y0 + 9, st["stage"], hard, True)
    tx = x0 + 8 + 26 + (24 if hard else 0) + 10
    name = ("Hard " if hard else "") + f"Stage {st['stage']}"
    t.text(tx, y0 + 6, TITLE, name, P["text"], bold=0.3)
    if quota:                                        # the count steps at the fall; the light eases after it
        t.text(tx + ss.wide_of(name, TITLE) + 12, y0 + 8, SMALL, f"{math.ceil(kills)} / {quota} Shades", P["text"])
        right = ("its last foe down" if kills < quota else "cleared") if last else "then its last foe"
    else:
        right = "cleared" if last else "the keeper"
    t.text(x1 - 10, y0 + 8, SMALL, right, P["soft"], "RIGHT")
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
        fill(t, rx0 + 1, lit, ry, 1.6, acc, ex - 6)
    if flash > 0:
        t.glow(np.hypot(t.x - lit, (t.y - ry) * 1.6) - 2, 5.0, "#FFFFFF", 0.8 * flash)
    if last:
        t.glow(np.hypot(t.x - ex, t.y - ry) - 7.5, 5.0, acc["glow"], 0.45)
        ss.check(t, ex, ry, 7.5)
    elif risen and ring_pop > 0:                     # the last foe is up: its ring lit through
        r = 6.5 * ring_pop
        disc = np.hypot(t.x - ex, t.y - ry) - r
        t.glow(disc, 6.0, acc["glow"], 0.6)
        t.paint(disc, up.shade(t, acc["lit"], ry - r, ry + r))
        t.line(disc, 1.0, "#FFFFFF", 0.9)
        t.paint(np.hypot(t.x - ex, t.y - ry) - 2.2 * ring_pop, P["ink"])
    else:
        disc = np.hypot(t.x - ex, t.y - ry) - 6.5
        t.paint(disc, P["channel"])
        t.line(disc, 1.2, P["edge"])


def line_strip(sheet, ox, oy, st, **beat):
    t = sheet.tile(ox, oy, W, LINE_H)
    ui.world(t, "noon")
    stand_in(t)
    stage_line(t, st, **beat)


STAGE_2 = ss.LINES[0][1]
LINE_BEATS = [        # Stage 2: a Shade falls, then the last foe rises
    ("a Shade falls: the count steps to 7 at once", dict(kills=6.15, flash=1.0)),
    ("0.18 s on: the light has eased onto its notch", dict(kills=7.0, flash=0.3)),
    ("the tenth falls, the last foe rises: its ring lights, over", dict(kills=10.0, ring_pop=1.35)),
    ("0.20 s on: the ring settles, lit through", dict(kills=10.0, ring_pop=1.0)),
]
LINE_NOTES = [
    "The run under Roblox's top bar, on the picker's glass: the stage's mark and name, its Shades on a short road (a notch",
    "a Shade) lit as they fall, to its last foe's ring, and Faber's words at the right. The ring lights when the last foe",
    "is up and takes a check once the stage is cleared; on the keeper's stage the road runs straight to the keeper. Hard",
    "keeps Normal's value: its edge, chevrons and road are the ember.",
]


# --- the sheets ----------------------------------------------------------------------------------------------------

def sheets(out):
    common = "in Seam's lit glass, at the smallest phone (568 x 320 points)"
    shots = ss.sheet_of(out, "stage_seam.png", f"AR42, the stages' picker, A: One road, {common}", STATES, H, NOTES,
                        lambda sheet, x, y, st: phone(sheet, x, y, st))
    cards = ss.sheet_of(out, "stage_seam_results.png", f"AR42, the results card, {common}", ss.CARDS, H, CARD_NOTES,
                        lambda sheet, x, y, st: card(sheet, x, y, st))
    ss.sheet_of(out, "stage_seam_line.png", f"AR42, the run's line at the top of the screen, {common}", ss.LINES,
                LINE_H, LINE_NOTES, lambda sheet, x, y, st: line_strip(sheet, x, y, st))
    first = ss.CARDS[0][1]
    ss.sheet_of(out, "stage_seam_card_strip.png", "AR42, the card's opening, on its first card", CARD_BEATS, H,
                ["The card rises 12 points as it fades in (0.22 s, Equipment's); then its marks' two beats."],
                lambda sheet, x, y, beat: card(sheet, x, y, first, **beat))
    ss.sheet_of(out, "stage_seam_line_strip.png", "AR42, the run's line as Stage 2's Shades fall", LINE_BEATS, LINE_H,
                ["Every Shade's fall steps the count; the light eases on a notch, a flash at its head."],
                lambda sheet, x, y, beat: line_strip(sheet, x, y, STAGE_2, **beat))
    gap, small = 12, 64 / (H * 2)
    sw, sh = round(W * 2 * small), 64
    tiny = np.zeros((2 * sh + 3 * gap, 4 * (sw + gap) + gap, 4), dtype=np.float32)
    tiny[..., :3], tiny[..., 3] = ui.c("#101117"), 1.0
    for row, group_ in enumerate((shots, cards)):
        for k, shot in enumerate(group_):
            rs.paste(tiny, rs.shrink(shot, small), gap + k * (sw + gap), gap + row * (sh + gap))
    rs.save(tiny, out / "stage_seam_64.png")
    # the next tile and its road, and the switch, at the phone's own pixels, twice over: the gradients' read
    def crop(shot, x0, y0, x1, y1):
        part = shot[round(y0 * 2):round(y1 * 2), round(x0 * 2):round(x1 * 2)]
        return np.repeat(np.repeat(part, 2, axis=0), 2, axis=1)
    tiles = [crop(shots[0], XS[2] - 16, TOP - 22, XS[3] + 20, H), crop(shots[2], XS[1] - 16, TOP - 22, XS[2] + 20, H)]
    bands = [crop(shots[0], 224, 0, W, 58), crop(shots[2], 224, 0, W, 58)]
    width = gap + max(sum(c.shape[1] + gap for c in tiles), bands[0].shape[1] + gap)
    height = gap + tiles[0].shape[0] + gap + sum(c.shape[0] + gap for c in bands)
    page = np.zeros((height, width, 4), dtype=np.float32)
    page[..., :3], page[..., 3] = ui.c("#101117"), 1.0
    rs.paste(page, tiles[0], gap, gap)
    rs.paste(page, tiles[1], gap + tiles[0].shape[1] + gap, gap)
    y = gap + tiles[0].shape[0] + gap
    for c in bands:
        rs.paste(page, c, gap, y)
        y += c.shape[0] + gap
    rs.save(page, out / "stage_seam_close.png")


# --- the motion ----------------------------------------------------------------------------------------------------

MOTION = dict(
    open_time=0.22, open_rise=12.0,               # the screen rises 12 points as it fades in (Equipment's)
    tile_start=0.04, tile_gap=0.05, tile_time=0.22, tile_from=18.0,   # the tiles rise in, left to right
    road_start=0.30, road_time=0.36,              # the road fills with light from the first tile to the ring
    ring_start=0.60, ring_time=0.26, ring_from=0.4, ring_back=1.8,    # the ring pops in where the light stops
    cross_time=0.22,                              # the switch: the two sides crossfade, the road drains meanwhile
    refill_start=0.18,                            # back on a side with a next, the road fills again from there
)
NORMAL, HARD_SHUT = STATES[0][1], STATES[1][1]
OPEN_AT, HARD_AT, NORMAL_AT, END = 0.25, 3.40, 5.40, 7.60
BEHIND = up.REPO / "build" / "scratch" / "faber" / "stills" / "burst-phone.png"


def ease_out(u):
    u = np.clip(u, 0.0, 1.0)
    return 1 - (1 - u) ** 3


def ease_in_out(u):
    u = np.clip(u, 0.0, 1.0)
    return u * u * (3 - 2 * u)


def back_out(u, s):
    u = min(max(u, 0.0), 1.0)
    return 1 + (s + 1) * (u - 1) ** 3 + s * (u - 1) ** 2


def group(i):
    x, y = i["x"], i["y"]
    if y < 58:
        return "band"
    if y > RY + 6:
        return "said"
    return f"tile{min(3, max(0, int((x - PAD) // (WIDE + GAP))))}"


class Paints:
    """A state's paints, kept: the loop's phases, the bare and tracked ones; its words a layer per group."""

    def __init__(self, state):
        self.state, self.loop = state, {}
        steps = round(sk.LOOP * FPS)
        self.steps = steps
        first = self.sheet(0.0)
        for i in first.items:
            i["layer"] = group(i)
        self.words = ui.text_layers(W * K, H * K, first.items)
        self.loop[0] = first.px
        self.bare = self.sheet(0.0, "bare").px
        self.tracked = self.sheet(0.0, "tracked").px
        yy, xx = np.mgrid[0:H * K, 0:W * K] / K
        self.x, self.y = xx, yy
        self.drawn = np.clip(np.abs(self.loop[0][..., :3] - self.bare[..., :3]).sum(-1) / 0.05, 0, 1)
        k = nxt(state)
        self.end = XS[k] + WIDE / 2 if k is not None else None
        self.road = (yy > RY - 14) & (yy < RY + 14)
        self.ring = (np.hypot(xx - (self.end or 0), yy - RY) < 15) if k is not None else np.zeros_like(yy, bool)

    def sheet(self, phase, parts="all"):
        sheet = ui.Sheet(W, H, "#000000")
        phone(sheet, 0, 0, self.state, phase, parts)
        return sheet

    def at(self, phase):
        """The paint at the loop's phase; a few kept, the first always (the clip asks them in time order)."""
        n = round(phase * self.steps) % self.steps
        if n not in self.loop:
            while len(self.loop) > 4:
                self.loop.pop(next(k for k in self.loop if k != 0))
            self.loop[n] = self.sheet(n / self.steps).px
        return self.loop[n]

    def tiles(self, k):
        x0 = XS[k] - 12
        return (self.x >= x0) & (self.x < x0 + WIDE + 24) & (self.y >= TOP - 26) & (self.y < Y1 + 4)

    def road_at(self, base, run, ring_scale, phase):
        """`base` with the road's light run to `run` (0 to 1) and the ring at `ring_scale`."""
        out = base.copy()
        if self.end is None:
            return out
        full = self.at(phase)
        at = PAD + 2 + (self.end - PAD - 2) * run
        reveal = self.road & ~self.ring & (self.x <= at)
        over(out, self.tracked, self.road & ~reveal)
        over(out, full, reveal)
        if 0 < run < 1:                                      # the light's head
            head = 0.8 * np.exp(-(((self.x - at) / 7) ** 2 + ((self.y - RY) / 3.5) ** 2))
            over(out, np.ones_like(out) * np.array([1, 1, 1, 1], np.float32), head)
        if ring_scale <= 0:
            over(out, self.tracked, self.ring)
        elif ring_scale != 1:
            s = ring_scale
            sx = np.clip(((self.end + (self.x - self.end) / s) * K).astype(int), 0, W * K - 1)
            sy = np.clip(((RY + (self.y - RY) / s) * K).astype(int), 0, H * K - 1)
            over(out, self.tracked, self.ring)
            lit = np.clip(np.abs(full[..., :3] - self.tracked[..., :3]).sum(-1) / 0.05, 0, 1)
            over(out, full[sy, sx], (lit * self.ring)[sy, sx] * min(s * 2, 1.0))
        return out


def over(dst, src, alpha):
    a = np.clip(np.asarray(alpha, dtype=np.float32), 0, 1)
    if a.ndim == 2:
        a = a[..., None]
    dst[..., :3] = src[..., :3] * a + dst[..., :3] * (1 - a)


def shifted(img, dx, dy=0):
    out = np.zeros_like(img)
    h, w = img.shape[:2]
    dx, dy = int(round(dx)), int(round(dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    out[yd, xd] = img[ys, xs]
    return out


def words(dst, layers, names, alpha=1.0, dy=0):
    for name in names:
        if name in layers:
            layer = shifted(layers[name], 0, dy)
            over(dst, layer, layer[..., 3] * alpha)


def opening(p, tau, phase=0.0):
    """The picker opening: the screen rises in; the tiles rise in left to right; the road fills; the ring pops."""
    m = MOTION
    out = p.bare.copy()
    full = p.at(phase)
    for k in range(4):
        a = ease_out((tau - m["tile_start"] - k * m["tile_gap"]) / m["tile_time"])
        if a <= 0:
            continue
        dy = m["tile_from"] * (1 - a) * K
        mask = p.tiles(k) & ~p.road
        over(out, shifted(full, 0, dy), shifted(p.drawn * mask, 0, dy) * a)
        words(out, p.words, [f"tile{k}"], a, dy)
    a_road = ease_out((tau - m["tile_start"]) / m["tile_time"])
    over(out, p.tracked, p.road * p.drawn * a_road)
    run = ease_in_out((tau - m["road_start"]) / m["road_time"])
    u = (tau - m["ring_start"]) / m["ring_time"]
    scale = 0.0 if u <= 0 else m["ring_from"] + (1 - m["ring_from"]) * back_out(u, m["ring_back"])
    if run > 0:
        out = np.where(p.road[..., None], p.road_at(out, run, scale, phase), out)
    words(out, p.words, ["band", "said"])
    return out


def opened(p, tau, back, phase=0.0):
    m = MOTION
    a = ease_out(tau / m["open_time"])
    out = back.copy()
    over(out, shifted(opening(p, tau, phase), 0, m["open_rise"] * (1 - a) * K), np.full(out.shape[:2], a))
    return out


def switch(a, b, u, phase):
    """A tap on the switch: the sides crossfade; the old road drains back over the crossfade; on a side with a next,
    its road fills again after it and its ring pops."""
    m = MOTION
    c = ease_in_out(u / m["cross_time"])
    drain = 1 - ease_in_out(u / m["cross_time"])
    old = a.road_at(a.at(phase), drain, drain, phase) if a.end is not None else a.at(phase)
    run = ease_in_out((u - m["refill_start"]) / m["road_time"])
    w = (u - m["refill_start"] - m["road_time"] + 0.06) / m["ring_time"]
    scale = 0.0 if w <= 0 else m["ring_from"] + (1 - m["ring_from"]) * back_out(w, m["ring_back"])
    new = b.road_at(b.at(phase), run, scale, phase) if b.end is not None else b.at(phase)
    out = old * (1 - c) + new * c
    gone = 1 - ease_in_out(2 * u / m["cross_time"])        # the tiles' words: the old out over the first half,
    come = ease_in_out(2 * u / m["cross_time"] - 1)        # the new in over the second, never both at once
    tiles = [f"tile{k}" for k in range(4)]
    words(out, a.words, ["band", "said"], 1 - c)
    words(out, b.words, ["band", "said"], c)
    words(out, a.words, tiles, gone)
    words(out, b.words, tiles, come)
    return out


def behind():
    img = rs.load(BEHIND)
    h, w = img.shape[:2]
    scale = max(W * K / w, H * K / h)
    ys = np.clip(((np.arange(H * K) + 0.5) / scale + (h - H * K / scale) / 2).astype(int), 0, h - 1)
    xs = np.clip(((np.arange(W * K) + 0.5) / scale + (w - W * K / scale) / 2).astype(int), 0, w - 1)
    out = img[ys][:, xs].copy()
    out[..., 3] = 1.0
    return out


def idle(p, phase):
    out = p.at(phase).copy()
    words(out, p.words, list(p.words))
    return out


def frame_at(now, normal, hard, back):
    if now < OPEN_AT:
        return back
    tau = now - OPEN_AT
    phase = tau / sk.LOOP % 1.0
    if tau < 1.0:
        return opened(normal, tau, back, phase)
    if now < HARD_AT:
        return idle(normal, phase)
    if now < HARD_AT + 0.4:
        return switch(normal, hard, now - HARD_AT, phase)
    if now < NORMAL_AT:
        return idle(hard, phase)
    if now < NORMAL_AT + 0.9:
        return switch(hard, normal, now - NORMAL_AT, phase)
    return idle(normal, phase)


def strip(out, normal, hard, back):
    picks = [("Opening", t) for t in (0.0, 0.08, 0.16, 0.30, 0.48, 0.80)] + \
            [("Tap on Hard", u) for u in (0.04, 0.11, 0.30)] + [("Tap on Normal", u) for u in (0.11, 0.36, 0.70)]
    gap, head = 16, 64
    ui.K = 1
    sheet = ui.Sheet(gap + 3 * (W + gap), head + 4 * (H + 34) + 70, "#101117")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 16, 20, "AR42, the picker opening and the switch, in Seam's lit glass (half the clip's size)",
           "#EDE6D6", bold=0.2)
    pics = []
    for n, (kind, at) in enumerate(picks):
        ui.K = K
        if kind == "Opening":
            px = opened(normal, at, back)
        elif kind == "Tap on Hard":
            px = switch(normal, hard, at, 0.0)
        else:
            px = switch(hard, normal, at, 0.0)
        half = px.astype(np.float32).reshape(H, K, W, K, 4).mean(axis=(1, 3))
        x, y = gap + (n % 3) * (W + gap), head + (n // 3) * (H + 34)
        pics.append((half, x, y + 22))
        t.text(x, y, 14, f"{kind}, {at:.2f} s", "#B4AC9C")
    ui.K = 1
    for half, x, y in pics:
        rs.paste(sheet.px, half, x, y)
    notes = ["The screen rises 12 points as it fades in (0.22 s); the tiles rise 18 points, left to right, 0.05 s apart; "
             "the road fills from the first tile (0.36 s) and the ring pops (0.4 to 1, Back 1.8).",
             "A tap on the switch: the two sides crossfade in 0.22 s as the road drains, the tiles' words out then in, "
             "never both; on a side with a next, the road fills again from 0.18 s and its ring pops. Idle: the kit's 2.4 s."]
    for k, line in enumerate(notes):
        t.text(gap + 4, head + 4 * (H + 34) + 6 + k * 22, 14, line, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "stage_seam_strip.png")
    ui.K = K


def main():
    out = bl.out_dir()
    quick = "quick" in sys.argv[sys.argv.index("--") + 1:]
    sk.wear("B")
    sheets(out)
    ui.K = K
    normal, hard = Paints(NORMAL), Paints(HARD_SHUT)
    back = behind()
    strip(out, normal, hard, back)
    if quick:
        return
    frames = out / "frames"
    frames.mkdir(exist_ok=True)
    for n in range(int(END * FPS)):
        path = frames / f"f{n:04d}.png"
        if not path.exists():                    # a run stopped part way goes on where it was
            rs.save(frame_at(n / FPS, normal, hard, back).astype(np.float32), path)


if __name__ == "__main__":
    main()
