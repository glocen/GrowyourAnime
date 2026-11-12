"""Pip's Lantern Burst in its art, on his delivered clip (AR4, section 7; handbook/visuals/vfx.md, step 4).

blender.exe -b --factory-startup --python tools/blender/pip_burst_art.py -- <out_dir> [pictures]

The block-in's B, the flame let out (pip_burst_fx.py), with research's two fixes: Pip's half reads at 30 studs (the
lantern's own flame climbs up out of its cage through the heat, and the send draws a bright trail from his cuff toward
the target); and the flame lives through its hold, boiling, its tongues licking up and breaking off. Two pictures:
- pip_burst.png, 1024 x 896: the flame's sixteen frames, the first twelve in 256 cells, the last four of the end and the
  heat's four in 128 cells along the bottom. The leap: a curl off the lantern that unrolls into the tall flame, its foot
  wide where the hit lands. The boil: four frames whose tongues lick up, thin and snap back, out of step, while the flame
  stands up (its foot drawn in, its root pinched, the outer tongues up its flanks off the ground) and its top climbs a
  little, so no outline is held (research's round 2). The end: eight frames in which the whole flame is drawn in and
  lifted off the ground as its tip climbs, cooling from the cream to the gold to Pip's orange. Each is three
  nested flames (orange, gold, cream), each with its own tongues. Every frame is drawn where it stands in one 15 stud
  square on the ground, so the burst is one picture that doesn't move. The heat: its own four, a round belly in the cage.
- pip_burst_trail.png, 512 x 128: the flame blown back into three tongues, for a Beam from the tail to the lantern.
Four tones, hard edges: a warm cream core, a gold, Pip's flame orange (#FF8A3D, the reddest thing in it) and his ink as
the rim. Nothing in it hangs, drips or falls: every tongue and every piece that breaks off points up.
Writes the two pictures, the sheet pip_burst_art.png, and pip_burst_art.json (what plays on every frame, for the builder).
With `pictures`, only the pictures and a look at them. Workbench, so no GPU turn.
Stage directions as pip_burst_fx.py: right, forward, up, in studs, from where Pip stands; he faces forward.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import pip_burst_fx as fx  # noqa: E402
import pip_sheet as ps  # noqa: E402
import rook_haymaker_art as ha  # noqa: E402  (picture)
import rook_haymaker_fx as hx  # noqa: E402  (camera, clamp, out_fast)
import rook_sheet as rs  # noqa: E402

CORE, GOLD, FLAME, INK = "#FFF4DC", "#FFC65A", ps.PALETTE["Flame"], ps.PALETTE["Ink"]
CELL, SPAN, K = 256, 15.0, 2      # a frame in px; the studs it spans across and up, as drawn; supersampling
ATLAS = (4 * CELL, 3 * CELL + CELL // 2)  # 1024 x 896
TRAIL_PX, TRAIL_UNITS = (512, 128), (8.0, 2.0)
RIM = 0.3                          # studs of ink round the flame: about a pixel at 64 px from the player's camera
DEPTH = 2.2                        # studs inside the edge where the flame is as hot as it gets
FIRST = fx.BURST                   # 66: the hit's frame, the curl's first
# The heat: its own four frames at the lantern, in a square of HEAT_SIZE studs set so the flame's round belly is on
# the lantern's middle: in the cage, its tongues licking up out of the lid and, by the send, past the cage's sides.
HEAT_SIZE = ((fx.HEAT, 1.0), (30, 1.9), (45, 2.8), (fx.SEND, 3.2), (fx.BURST - 1, 2.6))
HEAT_BELLY = 2.9 / SPAN            # the belly's height in its square, as a share
# The trail: a Beam from where the lantern was LAG frames before (never before the send: his cuff) to the lantern. Once
# it stops, the tail closes on it over CLOSE frames, into the burst.
# The flight runs mostly at the player's camera, so the tail holds at his cuff through all of it: the trail is drawn
# from him to the target, and leaves his hand only on the Burst, pulled into the flame.
LAG, CLOSE, WIDTH0, WIDTH1 = 15, 5, 0.6, 2.4
# The lantern's glow mask (Pip_Lamp's EmissiveStrength, the recipe's cold and hot): it climbs from cold at Heat to hot
# at Send, slow and then fast, is held through the flight, is out from the Burst (spent), and relights over the cooldown.
COLD, HOT = 1.2, 3.0


# --- the pictures ----------------------------------------------------------------------------------------------------

def grid(px, units, k=K):
    """Texel centres in studs, x across from the middle, y up from the foot; row 0 at the top."""
    (w, h), (uw, uh) = px, units
    xs = (np.arange(w * k) + 0.5) / (w * k) * uw - uw / 2
    ys = uh - (np.arange(h * k) + 0.5) / (h * k) * uh
    return np.meshgrid(xs, ys)


def curve(points, n):
    P = np.asarray(points, dtype=np.float64)
    t = np.linspace(0.0, 1.0, n)[:, None]
    if len(P) == 3:
        return (1 - t) ** 2 * P[0] + 2 * t * (1 - t) * P[1] + t * t * P[2]
    return (1 - t) ** 3 * P[0] + 3 * t * (1 - t) ** 2 * P[1] + 3 * t * t * (1 - t) * P[2] + t ** 3 * P[3]


def lick(X, Y, points, w0, p=1.0, n=56):
    """A tongue of flame: round at its root, tapering to a point along a curve. Its distance field, studs, positive
    inside."""
    d = np.full(X.shape, -1e3)
    t = np.linspace(0.0, 1.0, n)
    for (cx, cy), s in zip(curve(points, n), t):
        r = w0 * (1 - s) ** p
        if r <= 0.01:
            continue
        d = np.maximum(d, r - np.hypot(X - cx, Y - cy))
    return d


def belly(X, Y, cx, cy, rx, ry):
    return (1 - np.hypot((X - cx) / rx, (Y - cy) / ry)) * min(rx, ry)


def union(fields, k=0.28):
    """A soft union: the tongues grow out of the body with a fillet, never a seam."""
    m = np.maximum.reduce(fields)
    return m + k * np.log(sum(np.exp(np.maximum(f - m, -60 * k) / k) for f in fields))


def s_curve(root, tip, bend):
    """A tongue's four points: out of its root, leaning `bend` one way, then the other at its tip."""
    r, t = np.asarray(root, float), np.asarray(tip, float)
    run = t - r
    side = np.array((run[1], -run[0])) / (np.linalg.norm(run) + 1e-9)
    return r, r + run * 0.33 + side * bend, r + run * 0.68 - side * bend * 0.6, t


# The full flame, in studs in its 15 stud square, x across from its middle, y up from the ground. A foot on the ground
# the area's width, a column out of it, and tongues: three that split the column's tip, two up its sides, two from the
# foot, two small ones low at the area's edge. Each: root, tip, bend, width at the root, phase in the boil.
FOOT = (0.0, 0.0, 5.0, 2.5)        # a half ellipse standing on the ground: centre, radii
BELLY = (0.0, 2.9, 3.8, 2.6)       # the heat's round belly instead, in the lantern
COLUMN = ((0.0, 0.8), (0.15, 10.4), 0.3, 2.9)
TONGUES = (
    ((0.1, 7.6), (0.5, 13.2), 0.35, 1.35, 0.0),     # the column's tip, split in three: the tallest
    ((-0.9, 7.2), (-2.0, 12.1), -0.4, 1.05, 0.45),
    ((1.0, 7.0), (2.2, 11.5), 0.4, 1.0, 0.7),
    ((-1.9, 4.4), (-3.4, 10.0), -0.6, 1.35, 0.22),  # up its sides
    ((1.9, 4.1), (3.5, 9.4), 0.55, 1.3, 0.88),
    ((-3.5, 1.5), (-5.2, 6.9), -0.5, 1.15, 0.6),    # from the foot
    ((3.6, 1.4), (5.3, 6.3), 0.5, 1.1, 0.1),
    ((-4.6, 0.7), (-6.3, 3.7), -0.4, 0.72, 0.35),   # low at the area's edge
    ((4.7, 0.6), (6.4, 3.3), 0.4, 0.68, 0.95),
)
# Research's round 2 on the boil (AR4 section 8: "both readers called it a bonfire"): stood up, the flame draws its foot
# in (FOOT's width times 1 - STAND_FOOT) and stands it taller, its column's root rises STAND_ROOT studs so it pinches
# to the ground like a flame's root rather than standing on it as a block, and the four outer tongues leave the
# ground for its flanks, licking up: each one's root and tip, stood.
STAND_FOOT, STAND_RISE, STAND_ROOT = 0.6, 0.16, 1.3
STOOD = {5: ((-2.2, 3.4), (-3.9, 8.6)), 6: ((2.3, 3.2), (4.0, 8.0)),
         7: ((-2.3, 2.2), (-3.5, 5.6)), 8: ((2.4, 2.0), (3.6, 5.3))}


def shape(X, Y, phase, grow=1.0, narrow=1.0, lift=0.0, top=13.2, hook=0.0, foot=1.0, lamp=False, thin=1.0, tongues=9,
          k=0.28, stand=0.0, pinch=None):
    """The flame's distance field on one frame. `phase`: the boil, 0 to 1 a cycle. Through it each tongue licks up,
    longer and thinner and swaying, then snaps back short as its tip goes; their phases differ, so some tongue is always
    reaching. `grow`: how far the tongues are out (the leap). `narrow`, `lift`, `top`: the end, the flame drawn in and
    its foot off the ground. `hook`: the tallest tongue's tip still curled over, as it unrolls. `foot`: how much of the
    foot is left. `lamp`: a round belly for the heat, not a foot. `thin`: every width, for the flames drawn inside;
    `tongues`, how many of them they keep, and `k`, how softly they're joined, so an inner flame is one piece.
    `stand`, 0 to 1: how far it has stood up (STOOD), its foot drawn in and its outer tongues off the ground; `pinch`,
    the foot's share of it, if not the same."""
    pinch = stand if pinch is None else pinch
    def at(x, y):  # the flame's own place to where it's drawn this frame
        return x * narrow, lift + y * (top - lift) / 13.2

    squash = (top - lift) / 13.2
    fields = []
    if foot > 0.02:
        cx, cy, rx, ry = BELLY if lamp else FOOT
        if not lamp:
            rx, ry = rx * (1 - STAND_FOOT * pinch), ry * (1 + STAND_RISE * pinch)
        bx, by = at(cx, cy)
        fields.append(belly(X, Y, bx, by, rx * narrow * foot * thin, ry * foot * squash * thin))
    root, tip, bend, width = COLUMN
    if lamp:
        root = (0.0, BELLY[1])
    else:
        root = (root[0], root[1] + STAND_ROOT * pinch)
    r0, t0 = np.array(at(*root)), np.array(at(tip[0], root[1] + (tip[1] - root[1]) * grow))
    fields.append(lick(X, Y, s_curve(r0, t0, bend * narrow), width * narrow ** 0.7 * thin, p=0.9))
    for i, (root, tip, bend, width, offset) in enumerate(TONGUES):
        if i >= tongues or (lamp and i >= 7):  # the area's edge: the burst's alone
            continue
        if lamp and i >= 5:
            root = (root[0] * 0.8, max(root[1], 1.6))
        elif i in STOOD and stand > 0:
            (sr, st), s = STOOD[i], stand
            root = tuple(a + (b - a) * s for a, b in zip(root, sr))
            tip = tuple(a + (b - a) * s for a, b in zip(tip, st))
        f = (phase + offset) % 1.0
        g = grow * (0.6 + 0.62 * f)
        sway = bend + 0.8 * math.sin(2 * math.pi * f) * (1 if bend >= 0 else -1)
        r0 = np.array(at(root[0], root[1] * (0.6 + 0.4 * grow)))
        t0 = np.array(at(root[0] + (tip[0] - root[0]) * (0.5 + 0.5 * g), root[1] + (tip[1] - root[1]) * g))
        if i == 0 and hook:
            t0[0] -= 1.4 * hook
        w = width * narrow ** 0.5 * (1 - 0.2 * f) * thin
        points = list(s_curve(r0, t0, sway * narrow))
        if i == 0 and hook:  # the curl: past its top it rolls over to one side
            points[2] = points[2] + np.array((2.4 * hook, 0.5 * hook))
        fields.append(lick(X, Y, points, w, p=1.05))
    return union(fields, k)


def tones(d, Y, lift, cool, inner=None, fine=1.0):
    """Hard bands, hottest low in the middle: cream, gold, orange, and the ink rim. With `inner` (the gold flame's
    field and the cream's, each a smaller flame with its own tongues) the bands nest as flames; without, they're by
    how deep a texel is. Cooling eats the cream first, then the gold."""
    ink, flame, gold, core = (np.array(rs.rgb(c), dtype=np.float32) for c in (INK, FLAME, GOLD, CORE))
    if inner is None:
        heat = np.clip(d / DEPTH, 0, 1) ** 0.85 * (1 - 0.6 * np.clip((Y - lift - 2.0) / 9.0, 0, 1))
        warm, hot = heat > 0.33 + 0.3 * cool, heat > 0.68 + 0.4 * cool
    else:
        # the gold's field is let out a little, so the gaps between its tongues' roots close: no orange pinholes
        warm, hot = (inner[0] > -0.25) & (d > RIM + 0.22), (inner[1] > 0) & (d > RIM + 0.5)
    colour = np.where(hot[..., None], core, np.where(warm[..., None], gold, flame))
    rim = fine * RIM * (1 - 0.4 * np.clip((Y - lift - 5.0) / 7.0, 0, 1))  # finer up the tongues, so their tips stay flame
    return np.where((d < rim)[..., None], ink, colour)


# The gold flame and the cream: narrow, height, thin, phase, foot, the cooling that puts it out, its tongues, its join.
NEST = ((0.78, 0.84, 0.66, 0.3, 0.85, 0.85, 5, 0.4), (0.55, 0.62, 0.75, 0.6, 0.6, 0.28, 1, 0.3))


PLACED = ("cool", "scale", "rise")  # a frame's settings that aren't the shape's: how hot, and where it's drawn


def nested(s):
    """The gold flame's settings and the cream's, from a frame's: each narrower, lower and thinner, out of step with
    the one round it, so its tongues lick between; the cream goes out first as the flame cools."""
    cool, lift, top = s.get("cool", 0.0), s.get("lift", 0.0), s.get("top", 13.2)
    out = []
    for narrow, height, thin, phase, foot, cools, tongues, k in NEST:
        left = max(0.0, 1 - cool / cools)
        inner = {key: value for key, value in s.items() if key not in PLACED}
        inner.update(phase=s["phase"] + phase, narrow=s.get("narrow", 1.0) * narrow * (0.5 + 0.5 * left),
                     top=lift + (top - lift) * height * (0.6 + 0.4 * left), hook=0.6 * s.get("hook", 0.0),
                     foot=foot * s.get("foot", 1.0), thin=thin * left * s.get("thin", 1.0),
                     tongues=min(tongues, s.get("tongues", 9)),
                     k=k * max(left, 0.6))  # the soft join swells where fields meet: it shrinks with the flame, never to holes
        out.append(inner)
    return out


def finish(colour, keep, k=K):
    """Straight alpha at the frame's size; an empty texel keeps the ink's colour, so nothing fringes."""
    frame = np.empty((*keep.shape, 4), dtype=np.float32)
    frame[..., :3], frame[..., 3] = colour, keep
    frame = rs.shrink(frame, 1 / k)
    frame[..., :3] = np.where(frame[..., 3:] > 1e-6, frame[..., :3], np.array(rs.rgb(INK), dtype=np.float32))
    return frame


def curl(X, Y, n):
    """The leap's first two frames, drawn by hand: a curl of flame off the lantern, then the curl opened, its foot on
    the ground. Both clear a Shade's head (5.8 studs), so the first frame reads over the target."""
    if n == 0:
        return union([belly(X, Y, 0.0, 2.9, 0.9, 0.7),
                      lick(X, Y, ((0.0, 2.7), (-0.5, 6.0), (2.3, 8.3), (0.4, 9.4)), 1.1, p=0.85),
                      lick(X, Y, s_curve((-0.5, 2.9), (-2.0, 6.8), -0.35), 0.75),
                      lick(X, Y, s_curve((0.6, 2.9), (2.0, 5.6), 0.3), 0.62),
                      lick(X, Y, s_curve((-0.7, 2.6), (-1.7, 4.6), -0.2), 0.45)])
    return union([belly(X, Y, 0.0, 1.5, 2.5, 1.5),
                  lick(X, Y, ((0.0, 1.4), (-0.7, 6.6), (3.0, 10.1), (0.9, 11.3)), 2.2, p=0.9),
                  lick(X, Y, s_curve((-1.4, 1.8), (-2.8, 6.4), -0.45), 0.95),
                  lick(X, Y, s_curve((1.5, 1.7), (2.9, 5.8), 0.4), 0.85),
                  lick(X, Y, s_curve((-0.6, 4.5), (-1.6, 8.6), -0.3), 0.7)])


# Every frame, by its place in the picture: ("curl", n) or the shape's settings. The boil's phase runs on unbroken from
# the leap's last frame through the end, so the tongues never jump back.
def ending(k):
    """The end: the whole flame, tongues and all, drawn in and lifted off the ground while its tip still climbs, so
    it goes up as it goes out, smaller and cooler every frame: never a stem, never a piece hanging below."""
    # The whole boiling flame, smaller and raised as one, so it keeps its own proportions: its tongues stay on it to the
    # last, nothing is left under it as a stem, and its tip stays near where it was while its foot leaves the ground.
    u = k / 7
    scale = 1 - 0.85 * u ** 0.9  # to a wisp by the last, so nothing big is cut off when it's gone
    return dict(phase=0.75 + (4 + k) / 4, scale=scale, rise=0.85 * CLIMB[-1] * (1 - scale), foot=max(0.0, 1 - 1.6 * u),
                # on from where the boil stood and climbed to, its tongues still up its flanks; the foot's pinch lets go
                # as it lifts off, or the drawn-in foot hangs under it as a point, a drop: its bottom goes round
                cool=u, stand=1.0, pinch=max(0.0, 1 - 2 * u), top=CLIMB[-1],
                tongues=9 if k < 3 else 7)  # the outermost pair go with the foot, or they'd stand off its sides


# Research's round 2: through the boil the flame stands up (STAND, from the leap's wide foot, which shows the area the
# hit lands on) and its outline climbs a little (CLIMB, its top as drawn), so no outline is held.
STAND, CLIMB = (0.6, 0.9, 1.0, 1.0), (13.2, 13.55, 13.9, 14.25)
FRAMES = (
    "curl", "curl",
    dict(phase=0.3, grow=0.84, narrow=0.84, top=12.4, hook=0.55, foot=0.9),
    dict(phase=0.5, grow=0.96, narrow=0.98, top=13.0, hook=0.2, stand=0.2),
    *(dict(phase=0.75 + n / 4, stand=STAND[n], top=CLIMB[n]) for n in range(4)),     # the boil
    *(ending(k) for k in range(8)),                     # the end
    *(dict(phase=n / 4, lamp=True) for n in range(4)),  # the heat, in the lantern
)
LEAP, BOIL, END, HEAT = (0, 1, 2, 3), (4, 5, 6, 7), tuple(range(8, 16)), (16, 17, 18, 19)
# The burst on the clip's frames: the leap one a frame (66 to 69), the boil (70 to 77) and the end (78 to 93) two a frame.
LAST = FIRST + len(LEAP) + 2 * len(BOIL) + 2 * len(END) - 1


def rect(n):
    """Frame n's rectangle in the picture: twelve of 256 px in three rows, then eight of 128 in one."""
    if n < 12:
        y, x = divmod(n, 4)
        return (x * CELL, y * CELL, CELL, CELL)
    return ((n - 12) * CELL // 2, 3 * CELL, CELL // 2, CELL // 2)


def flame_frames():
    out = []
    for n, s in enumerate(FRAMES):
        X, Y = grid(rect(n)[2:], (SPAN, SPAN))
        if s == "curl":
            d, lift, cool, inner, fine = curl(X, Y, n), (2.0 if n == 0 else 0.0), 0.0, None, 1.0
        else:
            settings = {key: value for key, value in s.items() if key not in PLACED}
            sc, rise = s.get("scale", 1.0), s.get("rise", 0.0)
            X, Y = X / sc, (Y - rise) / sc  # the flame's own place; distances back in studs, so the ink stays a pixel
            d, lift, cool = shape(X, Y, **settings) * sc, s.get("lift", 0.0), s.get("cool", 0.0)
            inner = [shape(X, Y, **layer) * sc if layer["thin"] > 0.02 else -np.ones_like(X) for layer in nested(s)]
            # a small flame's rim goes finer with it, or the last wisp is a dark speck
            fine = 0.5 + 0.5 * sc
        out.append(finish(tones(d, Y, lift, cool, inner, fine), d > 0))
    return out


def trail_frame():
    """The flame blown back: a round head at the right, three tongues streaming left to points."""
    X, Y = grid(TRAIL_PX, TRAIL_UNITS)
    X = X + TRAIL_UNITS[0] / 2  # 0 at the tail, 8 at the head
    Y = Y - TRAIL_UNITS[1] / 2
    head = (7.05, 0.0)
    fields = [lick(X, Y, s_curve(head, tip, bend), w, p=1.1, n=90) for tip, bend, w in
              (((0.2, 0.08), 0.12, 0.92), ((2.0, 0.6), -0.15, 0.55), ((2.6, -0.62), 0.15, 0.5))]
    d = union(fields, k=0.12)
    ink, flame, gold, core = (np.array(rs.rgb(c), dtype=np.float32) for c in (INK, FLAME, GOLD, CORE))
    heat = np.clip(d / 0.75, 0, 1) ** 0.8 * np.clip(0.35 + X / 8.0, 0, 1)
    colour = np.where((heat > 0.62)[..., None], core, np.where((heat > 0.26)[..., None], gold, flame))
    colour = np.where((d < 0.09)[..., None], ink, colour)
    return finish(colour, d > 0)


def atlas(frames):
    sheet = np.zeros((ATLAS[1], ATLAS[0], 4), dtype=np.float32)
    sheet[..., :3] = rs.rgb(INK)
    for n, frame in enumerate(frames):
        x, y, w, h = rect(n)
        sheet[y:y + h, x:x + w] = frame
    return sheet


def glance(sheet, trail, path):
    """The two pictures on the dusk ground, a bright one and in grey: for a first look without the stage."""
    W, H = 3 * 540 + 40, 560 + 160
    page = rs.canvas(W, H, rs.PAPER)
    small = rs.shrink(sheet, 0.5)
    for i, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, 10 + i * 545, 10, 532, 532, ground)
        rs.paste(page, rs.grey(small) if grey else small, 14 + i * 545, 14)
        rs.fill(page, 10 + i * 545, 560, 532, 150, ground)
        rs.paste(page, rs.grey(trail) if grey else trail, 14 + i * 545, 570)
    rs.save(page, path)


# --- the effect, frame by frame --------------------------------------------------------------------------------------

def burst_frame(f):
    """Which of the sixteen frames the burst shows on clip frame f, or None."""
    t = f - FIRST
    if t < 0 or f > LAST:
        return None
    if t < len(LEAP):
        return LEAP[t]
    t -= len(LEAP)
    if t < 2 * len(BOIL):
        return BOIL[t // 2]
    return END[(t - 2 * len(BOIL)) // 2]


def heat_size(f):
    for (f0, s0), (f1, s1) in zip(HEAT_SIZE, HEAT_SIZE[1:]):
        if f0 <= f <= f1:
            u = (f - f0) / (f1 - f0)
            return s0 + (s1 - s0) * (u * u * (3 - 2 * u))
    return None


def glow(f):
    """Pip_Lamp's EmissiveStrength on clip frame f (the cooldown's relight is the builder's, after the clip)."""
    if f < fx.HEAT:
        return COLD
    if f < fx.SEND:
        return COLD + (HOT - COLD) * hx.clamp((f - fx.HEAT) / (fx.SEND - fx.HEAT)) ** 1.6
    if f < fx.BURST:
        return HOT
    return 0.0


def trail_ends(lamp, f):
    """The Beam's tail and head on clip frame f, or None."""
    if not fx.SEND < f < FIRST + CLOSE:
        return None
    head = lamp[min(f, FIRST)]
    tail = lamp[max(fx.SEND, min(f, FIRST) - LAG)]
    if f > FIRST:
        tail = tail.lerp(head, (f - FIRST) / CLOSE)
    if (head - tail).length < 0.15:
        return None
    return tail, head


def art(stage, f):
    """Every picture on frame f: ("quad", what, centre, size, rect) or ("beam", what, tail, head, width0, width1)."""
    out = []
    s = heat_size(f) if fx.HEAT <= f < FIRST else None
    if s:
        n = HEAT[(f // 2) % 4]
        out.append(("quad", "heat", stage.lamp[f] + Vector((0.0, 0.0, s * (0.5 - HEAT_BELLY))), (s, s), rect(n)))
    ends = trail_ends(stage.lamp, f)
    if ends:
        out.append(("beam", "trail", *ends, WIDTH0, WIDTH1))
    n = burst_frame(f)
    if n is not None:
        at = stage.lamp[FIRST]
        out.append(("quad", "burst", Vector((at.x, at.y, SPAN / 2)), (SPAN, SPAN), rect(n)))
    return out


class Stage(fx.Stage):
    """The block-in's stage: its grey shapes for the block-in's B, or the pictures, each a quad facing the camera, as
    a BillboardGui's ImageLabel and a Beam with FaceCamera draw them."""

    def __init__(self, scene, rig, frames, sheet, trail):
        self.mode, self.quads, self.half_only, self.back = "art", [], False, 0.0
        self.sheet_material = ha.picture("Fx.Burst", sheet)
        self.trail_material = ha.picture("Fx.Trail", trail)
        super().__init__(scene, rig, frames)
        self.variant = "B"
        mesh = bpy.data.meshes.new("Fx.Beam")
        mesh.from_pydata([(0, 0, 0)] * 4, [], [(0, 1, 2, 3)])
        uv = mesh.uv_layers.new(name="UV")
        for loop, co in zip(uv.data, ((0, 0), (1, 0), (1, 1), (0, 1))):
            loop.uv = co
        mesh.materials.append(self.trail_material)
        self.beam = bpy.data.objects.new("Fx.Beam", mesh)
        scene.collection.objects.link(self.beam)
        self.beam.display.show_shadows = False
        self.beam.hide_render = True

    def quad(self):
        mesh = bpy.data.meshes.new("Fx.Picture")
        mesh.from_pydata([(-0.5, 0, -0.5), (0.5, 0, -0.5), (0.5, 0, 0.5), (-0.5, 0, 0.5)], [], [(0, 1, 2, 3)])
        mesh.uv_layers.new(name="UV")
        mesh.materials.append(self.sheet_material)
        obj = bpy.data.objects.new("Fx.Picture", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    @staticmethod
    def uv(obj, r):
        x, y, w, h = r
        u0, u1 = x / ATLAS[0], (x + w) / ATLAS[0]
        v0, v1 = 1 - (y + h) / ATLAS[1], 1 - y / ATLAS[1]
        for loop, co in zip(obj.data.uv_layers[0].data, ((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
            loop.uv = co

    def set(self, scene, *_):
        if not hasattr(self, "beam"):
            return
        f = scene.frame_current
        if self.mode == "block":
            fx.Stage.set(self, scene)
            for obj in self.quads + [self.beam]:
                obj.hide_render = True
            return
        self.place_avatar(scene)
        self.flame.hide_render = True
        for pool in self.pool.values():
            for obj in pool:
                obj.hide_render = True
        items = art(self, f) if self.show and scene.camera else []
        if self.half_only:
            items = [item for item in items if item[1] != "burst"]
        self.beam.hide_render = True
        used = 0
        if items:
            view = scene.camera.matrix_world.to_3x3().normalized()
            face = Matrix((view.col[0], -view.col[2], view.col[1])).transposed()  # across the screen, at the camera, up it
            eye = scene.camera.matrix_world.translation
            look = -view.col[2]
        for item in items:
            if item[0] == "beam":
                _, _, tail, head, w0, w1 = item
                across = (head - tail).cross(eye - (head + tail) / 2).normalized()
                for v, co in zip(self.beam.data.vertices, (tail - across * w0 / 2, head - across * w1 / 2,
                                                          head + across * w1 / 2, tail + across * w0 / 2)):
                    v.co = co
                self.beam.data.update()
                self.beam.hide_render = False
                continue
            _, what, centre, (w, h), r = item
            if what == "burst":
                centre = centre + look * self.back
            if used == len(self.quads):
                self.quads.append(self.quad())
            obj = self.quads[used]
            used += 1
            obj.matrix_world = Matrix.Translation(centre) @ (face @ Matrix.Diagonal((w, 1, h))).to_4x4()
            self.uv(obj, r)
            obj.hide_render = False
        for obj in self.quads[used:]:
            obj.hide_render = True


# --- the sheet -------------------------------------------------------------------------------------------------------

def shoot(scene, stage, camera, f, label, size, out, mode="art"):
    """One tile: the clip shaded, and the effect over it unlit in its own colours; the count of the effect's pixels,
    and of Pip's half alone (the heat and the trail)."""
    stage.mode = mode
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    shading = scene.display.shading
    path = out / "_tile.png"
    scene.render.filepath = str(path)
    passes = []
    for flat, show, half in ((False, False, False), (True, True, False), (True, False, False), (True, True, True)):
        stage.show, stage.half_only = show, half
        shading.light = "FLAT" if flat else "STUDIO"
        shading.show_shadows = shading.show_cavity = shading.show_object_outline = not flat
        scene.render.use_stamp = bool(label) and not flat
        scene.render.stamp_note_text = label
        scene.frame_set(f)
        bpy.ops.render.render(write_still=True)
        passes.append(rs.load(path))
    shaded, lit, bare, half = passes
    drawn = np.abs(lit[..., :3] - bare[..., :3]).max(axis=-1) > 0.03
    own = np.abs(half[..., :3] - bare[..., :3]).max(axis=-1) > 0.03
    path.unlink()
    stage.show, stage.mode, stage.half_only = True, "art", False
    return np.where(drawn[..., None], lit, shaded), int(drawn.sum()), int(own.sum())


SHEET = (8, 30, 45, 51, 53, 56, 60, 66, 67, 69, 72, 76, 80, 84, 88, 93)  # the player's camera, four rows of four
ROW = (45, 55, 66, 67, 69, 74, 82, 90)                                     # the other views
SMALL = (30, 45, 51, 55, 60, 66, 67, 69, 72, 76, 82, 90)                   # at 64 px
HALF = (30, 45, 51, 55, 60)                                                # Pip's half, counted against the block-in
PEAK = (67, 69, 72, 76)                                                    # the burst's share of the screen
NAMES = {f: name for name, f in fx.MARKS.items()}


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def table(stage):
    """What plays on every frame, for the builder, by rule rather than by place: the burst's cell; the heat's cell, its
    size and how far its centre sits above the lantern; the trail's tail as the frame whose lantern it starts from, and
    how far it has closed; the lantern's glow."""
    frames = {}
    for f in range(fx.HEAT, LAST + 1):
        entry = {"glow": round(glow(f), 3)}
        s = heat_size(f) if fx.HEAT <= f < FIRST else None
        if s:
            entry["heat"] = {"rect": list(rect(HEAT[(f // 2) % 4])), "size": round(s, 3), "up": round(s * (0.5 - HEAT_BELLY), 3)}
        if trail_ends(stage.lamp, f):
            entry["trail"] = {"tail_frame": max(fx.SEND, min(f, FIRST) - LAG), "head_frame": min(f, FIRST),
                              "closed": round(max(0.0, (f - FIRST) / CLOSE), 3)}
        n = burst_frame(f)
        if n is not None:
            entry["burst"] = list(rect(n))
        frames[str(f)] = entry
    return {"pictures": {"pip_burst.png": list(ATLAS), "pip_burst_trail.png": list(TRAIL_PX)}, "fps": 60,
            "markers": fx.MARKS, "area": fx.AREA,
            "lantern": {name: [round(v, 2) for v in stage.lamp[f]] for name, f in {**fx.MARKS, "Home": fx.HOME}.items()},
            "axes": "right, forward, up, studs, from where Pip stands; he faces forward",
            "burst": {"size": SPAN, "per_area": SPAN / fx.AREA, "foot": "on the ground under the lantern's Burst position",
                      "first": FIRST, "last": LAST},
            "heat": {"belly": HEAT_BELLY, "keys": [list(k) for k in HEAT_SIZE], "frames_per_cell": 2},
            "trail": {"lag": LAG, "close": CLOSE, "width0": WIDTH0, "width1": WIDTH1,
                      "texture": "U = 0 at the tail (Attachment0), U = 1 at the lantern (Attachment1), stretched once"},
            "glow": {"piece": "Pip_Lamp", "cold": COLD, "hot": HOT, "curve": 1.6, "relight": "over the cooldown, the builder's"},
            "frames": frames}


def main():
    out = bl.out_dir()
    rs.OUT = out
    frames = flame_frames()
    sheet, trail = atlas(frames), trail_frame()
    rs.save(sheet, out / "pip_burst.png")
    rs.save(trail, out / "pip_burst_trail.png")
    print(f"wrote {out / 'pip_burst.png'} and {out / 'pip_burst_trail.png'}")
    if "pictures" in sys.argv[sys.argv.index("--") + 1:]:
        glance(sheet, trail, out / "pip_burst_glance.png")
        return

    scene, rig, costume, undress, feet, ctl, motors = fx.pc.build()
    count = fx.key(rig)
    print(f"LanternBurst: {count} frames, the markers at {fx.MARKS}")
    stage = Stage(scene, rig, count, sheet, trail)
    cams = {}
    for name in ("fight", "fight50", "beside", "hidden"):  # behind the avatar, looking at its head (the game's camera)
        look, spot = fx.staged(name)
        azimuth = math.degrees(math.atan2(-look.x, -look.y))
        cams[name] = hx.camera(scene, name, azimuth, fx.PITCH, fx.EYE / math.cos(math.radians(fx.PITCH)),
                               (spot.x, spot.y, 4.5), 50.0 if name == "fight50" else 70.0)
    cams["side"] = hx.camera(scene, "side", 90.0, 6.0, 34.0, (0.3, 7.0, 4.5), 36.0)
    bpy.data.objects["Floor"].scale *= 4  # past the camera's edges
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk, bright = tuple(floor.diffuse_color), (0.74, 0.72, 0.68, 1)
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note, r.stamp_font_size = True, 18

    big, row, tiny = (456, 256), (228, 128), (75, 64)
    game = [shoot(scene, stage, cams["fight"], f, label(f), big, out) for f in SHEET]
    rows = {view: [shoot(scene, stage, cams[view], f, label(f), row, out)[0] for f in ROW]
            for view in ("beside", "hidden", "side")}
    stage.back = 2.0
    rows["back"] = [shoot(scene, stage, cams["fight"], f, label(f), row, out)[0] for f in ROW]
    stage.back = 0.0
    small = {"block": [shoot(scene, stage, cams["fight50"], f, "", tiny, out, "block") for f in SMALL],
             "dark": [shoot(scene, stage, cams["fight50"], f, "", tiny, out) for f in SMALL]}
    half = {f: (shoot(scene, stage, cams["fight"], f, "", big, out, "block")[1],
                shoot(scene, stage, cams["fight"], f, "", big, out)[2]) for f in HALF}
    peak = {f: (shoot(scene, stage, cams["fight"], f, "", big, out, "block")[1],
                shoot(scene, stage, cams["fight"], f, "", big, out)[1]) for f in PEAK}
    floor.diffuse_color = bright
    rows["bright"] = [shoot(scene, stage, cams["fight"], f, label(f), row, out)[0] for f in ROW]
    small["bright"] = [shoot(scene, stage, cams["fight50"], f, "", tiny, out) for f in SMALL]
    floor.diffuse_color = dusk
    bpy.app.handlers.frame_change_pre.remove(stage.set)

    area = big[0] * big[1]
    numbers = table(stage)
    numbers["checks"] = {
        "pips_half_pixels_at_the_players_camera": {str(f): {"block": b, "art": a} for f, (b, a) in half.items()},
        "share_at_peak": {str(f): {"block": round(b / area, 4), "art": round(a / area, 4)} for f, (b, a) in peak.items()},
        "pixels_at_64": {key: dict(zip(map(str, SMALL), (t[1] for t in tiles))) for key, tiles in small.items()},
        "camera": f"the player's: behind the avatar, {fx.EYE} studs, {fx.PITCH} degrees down, 70 degrees, {big[0]} x {big[1]}"}
    (out / "pip_burst_art.json").write_text(json.dumps(numbers, indent=1))
    print(json.dumps(numbers["checks"], indent=1))

    W, H = 1920, 3210
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    x0 = 40
    text = [(x0, 30, 54, "PIP'S LANTERN BURST, THE ART", ink),
            (900, 30, 20, "The block-in's B, the flame let out, with research's two fixes: Pip's half reads from the player's camera", ink),
            (900, 54, 20, "(the heat climbs out of the cage, the send draws a trail), and the flame boils through its hold. No red past Pip's orange.", ink)]
    y = 104
    text.append((x0, y, 20, "pip_burst.png, 1024 x 896, one upload: the leap, the boil and the end's first four in 256 cells; the end's last four and the heat in 128 cells along the bottom", ink))
    shrunk = rs.shrink(sheet, 0.5)
    for i, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, x0 + i * 600, y + 30, 532, 468, ground)
        rs.paste(page, rs.grey(shrunk) if grey else shrunk, x0 + 10 + i * 600, y + 40)
        rs.fill(page, x0 + i * 600, y + 508, 532, 148, ground)
        rs.paste(page, rs.grey(trail) if grey else trail, x0 + 10 + i * 600, y + 518)
    for i, words in enumerate((
            f"The leap, one a frame from the Burst ({FIRST} to {FIRST + 3}): a curl off the lantern that unrolls into the tall flame. The boil, two frames each ({FIRST + 4} to {FIRST + 11}): "
            "every tongue licks up, thins and snaps back, out of step, as the flame stands up off its wide foot and its top climbs.",
            f"The end, two frames each ({FIRST + 12} to {LAST}): the whole flame smaller and raised as one, its foot leaving the ground, cooling from the cream to the gold to Pip's orange. "
            "Three nested flames, each with its own tongues.",
            f"pip_burst_trail.png, 512 x 128: the flame blown back, its head at the right, for a Beam with FaceCamera from his cuff (where the lantern was at the Send, "
            f"or {LAG} frames before) to the lantern, {WIDTH0} to {WIDTH1} studs.",
            f"The heat: four 128 cells at the lantern, two frames each, its round belly on the lantern's middle, {HEAT_SIZE[0][1]} stud at Heat to {HEAT_SIZE[3][1]} at Send.")):
        text.append((x0, y + 666 + i * 20, 15, words, soft))
    y = 860
    text.append((x0, y, 20, f"From the player's camera: behind the avatar, Pip 33 degrees off his front and 30 studs away, the lead past its target (the clip's frames, 60 a second; Burst is {FIRST})", ink))
    for n, (tile, _, _) in enumerate(game):
        rs.paste(page, tile, x0 + (n % 4) * 466, y + 28 + (n // 4) * 266)
    y = 1960
    for title, key in (("On a bright floor", "bright"), ("Beside: the camera looking across the fight", "beside"),
                       ("Hidden: the avatar facing its target dead on", "hidden"), ("From the side", "side"),
                       ("The builder's Back at 2 studs: the burst's plane pushed away from the camera, so the Shades stand in front of it", "back")):
        text.append((x0, y, 18, title, ink))
        for c, tile in enumerate(rows[key]):
            rs.paste(page, tile, x0 + c * 232, y + 24)
        y += 160
    y += 10
    text.append((x0, y, 18, "At 64 px from the player's camera: the block-in's B, then the art on dark and on bright, and in grey. Under each, the effect's pixels", ink))
    for i, key in enumerate(("block", "dark", "bright")):
        for c, (tile, n, _) in enumerate(small[key]):
            rs.paste(page, tile, x0 + c * 80, y + 26 + i * 86)
            text.append((x0 + c * 80 + 2, y + 26 + i * 86 + 66, 12, f"{SMALL[c]}: {n}", soft))
        text.append((x0 + 12 * 80 + 8, y + 50 + i * 86, 14, ("the block-in", "the art, dark", "the art, bright")[i], soft))
    for c, (tile, _, _) in enumerate(small["dark"]):
        rs.paste(page, rs.grey(tile), x0 + 1180 + (c % 6) * 80, y + 26 + (c // 6) * 86)
    y += 290
    halves = ", ".join(f"{f}: {b} to {a}" for f, (b, a) in half.items())
    peaks = ", ".join(f"{f}: {b / area:.1%} to {a / area:.1%}" for f, (b, a) in peak.items())
    for i, words in enumerate((f"Pip's half from the player's camera, the block-in's pixels to the art's ({big[0]} x {big[1]}): {halves}.",
                               f"The burst's share of the player's screen, the block-in's to the art's: {peaks}.",
                               f"Not drawn here, the builder's: Pip_Lamp's glow, EmissiveStrength {COLD} cold to {HOT} hot from Heat to Send (slow, then fast), held through the flight, 0 from the Burst, relit over the cooldown.",
                               "The pictures are drawn flat and unlit, facing the camera, with no glow added: the game's bloom is the builder's. pip_burst_art.json has what plays on every frame.")):
        text.append((x0, y + i * 24, 16, words, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "pip_burst_art.png")
    print(f"wrote {out / 'pip_burst_art.png'} {W}x{H}")


if __name__ == "__main__":
    main()
