"""AR42: the stages' picker in Seam's lit glass, the kit Equipment and Settings wear (research's B, 15:04). The
director's 14:56 scope, as research recorded it, moves the picker from AR40's C to Seam. The results card and the run's
line aren't named in it and keep C.

The layout is A's, One road (research's pick, 02:06, with its two must-fixes): the four stages side by side over one
road, lit to where the player stands, the next one raised and tagged. The pictures are stage_screen.py's: the Shade in
the Brawler's paper mask, the elite with its second mask, the Lamplighter's lantern. What changes is the glass:
    - every tile lighter at its top, its hairline lit from above, with the kit's corner glint;
    - the next tile washed with light, a glint down it once a loop, a bloom behind its picture;
    - the walked road a conduit filling with light, to a lit ring with the kit's comet round it;
    - the side of the switch chosen is the lit press, white falling to lavender, its sheen across once a loop.
Hard (must-fix 2, the whole screen a full value darker) can't take C's violet on a violet screen, so its one accent is
an ember, white falling to coral: the chosen Hard half, the edges, the chevrons, the walked road, the ring and the
bloom. Everything else on Hard steps a value down.

Measured in rendered points at the smallest phone (568 x 320), as stage_screen.py. Drawn in code; nothing is exported.

    blender -b --factory-startup --python tools/blender/stage_seam.py -- <abs out> [quick]

Writes:
    stage_seam.png         the picker's three states, with the notes
    stage_seam_64.png      the three at 64 pixels high
    stage_seam_close.png   the next tile, its road and the switch at the phone's own pixels, twice over
    stage_seam_strip.png   the opening's beats and the switch's, Normal to Hard and back
    frames/f0000.png ...   the clip's frames (ffmpeg joins them; the frames are then deleted). "quick" skips them.
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
# Hard, a full value darker: the ground, every open tile, a shut tile a step under that.
GROUND = {False: P["backing"], True: ("#120E28", "#050409")}
TILE = {False: P["panel"], True: ("#1E1838", "#0B0915")}
SHUT = {False: ("#1C1834", "#110E20"), True: ("#100D1E", "#08070F")}
BLOOM = {False: 0.30, True: 0.22}

# The pictures' own colours, on Seam: stage_screen's C read for the shut silhouettes, the lock, the check and the bed.
ss.C.update(well="#262044", faint=P["faint"], text=P["text"], soft=P["soft"], ink=P["ink"], chosen=P["lit"],
            glass=sk.SOCKET_DARK[0], channel=sk.SOCKET_DARK[1], row=P["edge"], edge=P["facet"])
ss.SHADE_BODY = "#1B1728"                    # the model's own Void (shade_sheet.py's PALETTE), not C's teal

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
    "The next is raised and washed with light, with a glint down",
    "it once a loop and a bloom behind its picture. The walked",
    "road fills with light to a lit ring, the comet round it. The",
    "side of the switch chosen is the lit press, its sheen across.",
    "Hard: the whole screen a full value darker, its one accent",
    "an ember on the chosen half, the edges, the chevrons, the",
    "road, the ring and the bloom. The player's power stands at",
    "the road's start; Combat Power reads CR, as in the game.",
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
    t.paint(whole, t.ramp(GROUND[hard][0], GROUND[hard][1], t.y / H))
    bx, by = bloom_at(state)
    t.paint(whole, ACC[hard]["bloom"], BLOOM[hard] * np.exp(-(((t.x - bx) / 150) ** 2 + ((t.y - by) / 120) ** 2)))
    t.paint(whole, ACC[hard]["edge"] if hard else P["glint"], 0.06 * np.exp(-t.y / 40))


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
    if state != "shut":
        colour, strength = (ACC[hard]["bloom"], 0.5 if hard else 0.75) if state == "next" else (P["facet"], 0.22)
        t.paint(d, colour, strength * np.exp(-(((t.x - cx) / ((x1 - x0) * 0.38)) ** 2 +
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
    t.paint(d, up.shade(t, SHUT[hard] if state == "shut" else TILE[hard], y0, y1))
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


# --- the sheets ----------------------------------------------------------------------------------------------------

def sheets(out):
    common = "in Seam's lit glass, at the smallest phone (568 x 320 points)"
    shots = ss.sheet_of(out, "stage_seam.png", f"AR42, the stages' picker, A: One road, {common}", STATES, H, NOTES,
                        lambda sheet, x, y, st: phone(sheet, x, y, st))
    gap, small = 12, 64 / (H * 2)
    sw, sh = round(W * 2 * small), 64
    tiny = np.zeros((sh + 2 * gap, 3 * (sw + gap) + gap, 4), dtype=np.float32)
    tiny[..., :3], tiny[..., 3] = ui.c("#101117"), 1.0
    for k, shot in enumerate(shots):
        rs.paste(tiny, rs.shrink(shot, small), gap + k * (sw + gap), gap)
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
