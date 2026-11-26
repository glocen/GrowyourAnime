"""TR69 B's elites' tells, their targets for research's pick in pairs (AGENTS.md, "Every action, world, effect and
screen"). Painted over the street stage at the player's camera (the Festival place at night, a Brawler up the street, Rook
on it; build/handoff/Fight/stage/stage_street.json), with today's R4 mark on the foe as the build draws it. Scintilla's.

    py tools/fx/elite_tell_targets.py [out_dir] [O1_weight,O2_halo,F1_...]   (default: build/handoff/Fight/targets/elite)
    py tools/fx/elite_tell_targets.py --pictures [out_dir]   (the picks' pictures; default: build/handoff/Shade/fx/pictures)

Research picked O2, F1 and S1 (2026-11-26). Their rows are written by tools/fx/shade_tells.py, and the pictures the
game uses (O2's ring, S1's wall) are drawn here by pictures(), with the targets' own strokes.

Feel line (research, 2026-11-26, 22:05, tier 2): from the player's camera, each elite's one move announces itself a beat
before it lands, so the player knows which elite it is and when to step away. The Brawler elite's overhead gathers over
its head through the 1.2 s wind-up; the Dasher's three lines are drawn on the ground before it runs them; the Guard's
screen stands as a wall you can see through.

The class every enemy tell holds (research's condition): one language for "this will hit here", from a Shade to the
keeper. It is D1's, the Dasher's picked lane (AR52; tools/fx/shade_tells.py): the hit's own shape laid flat on the
street in faint deep amber, its rim a clean amber line with a white core where the reach ends, and a brighter fill growing
from where the blow starts to where it ends, reaching it on the hit: the time left to move. The keeper's footprint (TR44,
still grey) is the same idea, a ring with a disc growing to meet it, so its finish takes this make. Warm and hostile:
amber, never the foe's type colour, never violet, nothing red. R4, the lead's target mark, is a small cut chevron in the
type's colour over the head: no tell is a chevron, and none shares R4's spot with it.

Room over the head at the player's camera (this stage, the foe 25 studs off, 33 pixels a stud): R4's wings stand 1 stud
over the mask's top, and the target card's foot about 4 studs over it. An elite is 1.35 times the size, so its head and
R4 stand about 70 pixels higher and leave under 30 pixels to the card: a gather can't stand over R4.

The overhead (TR69 B: every third swipe, a 1.2 s wind-up and a 1.5 s recovery). Its footprint, the same in both: a disc
Radius studs across centred Ahead studs before the elite toward its target (seeds), cut open in 5 frames on the wind-up's
first, its fill growing from the middle to the rim on Strike, a flash there, closed in 6. Its levers: anticipation (the
gather, eased in so it fills faster as the blow nears, and a squeeze in the last 8 frames), the release (the gathered
light falls along the blow's arc to the footprint in 4 frames, a comet a third as wide at its tail, S5's make), and the
punctuation (the footprint flashes, a ring runs out flat and needles of light are thrown off it). Two hero shapes:
- O1, the weight: a ball of amber light between the raised fists, just over the mask, growing out of a point as streaks
  of light are drawn into it from round about, ever faster; white-hot and squeezed in the last 8 frames, then it is the
  blow. It takes R4's spot, so R4 fades out over its first 4 frames and back in 4 frames after the blow (a hook change:
  the ball says which foe while it stands).
- O2, the halo: a thin amber ring round the mask, closing on it at a steady rate from 4.2 studs across to the mask's
  own size: when the ring meets the mask, the blow lands (the honest timer, as the fill is). The mask lights as it
  closes, as the ordinary swing's glint (G1) does in a beat. R4 stays on, the ring passing round it.
Both release from the fists, Over studs above the mask's top.

The Dasher's fan (TR69 B: a fan of three lines, then 1.5 s out of breath; research's geometry, 2026-11-26, 22:15): three
lanes from the Dasher's feet, the middle one at its target and the others Spread degrees either side, each the hit's own
stadium as D1's (Half 2 either side of a line 14 long, round at both ends), all drawn at once and run in one lunge on the
Dasher's beats (Line, then Lunge 44 frames on, Land 59): the body down the middle, an afterimage down each side, a slash
where each lands. Between the lanes, past where they part, the street is safe. Two hero shapes:
- F1, the fan: the three lanes as one shape, one rim round all of it with the two notches where the safe gaps run in,
  one faint fill, and the fuse a single front sweeping out from the feet as an arc across all three.
- F2, the blades: three slashes of light down the lanes' middles, pointed at both ends like a claw's marks, raked open
  in turn (left, middle, right, 3 frames apart), dim until the fuse runs down each and lights it white-cored; each
  lane's reach a faint fill and a hair of rim. The feel line's "three lines", drawn as lines.
At this camera the fan runs through the avatar's spot, so the avatar hides most of a fill growing from the Dasher's feet
until late. So every tell here also heats its rim as its hit nears (from 0.55 to 1.3 of its light): a timer that reads
wherever any of the rim shows. The footprint takes it too.

The Guard's screen (TR69 B: in the square, 8 studs wide, covering 2 Brawlers who join at its half health): not a hit but
a wall, so it speaks the Guard's own language, not the tells': W2's make (AR52, the picked ward; tools/fx/ward_targets.py),
lines only, azure with a white core and a hair of deep azure ink, tapered brush strokes, no surface, no glass (the
director's 12:57 verdict on the ward). It stands Ahead studs before the Guard toward its target, Wide across on a gentle
curve (a slice of a Curve-stud circle), High tall, and on GuardRaise's beats: drawn up from the street over the 8 frames
before Raise, a click on Raise, light running along its strokes in the hold, a glance lighting the strokes round where a
blow lands with a white core and needles back at the attacker, drawn off over 8 frames from Drop. Strokes are 1.6 times
W2's, since the wall stands as far off as the foe. Two hero shapes:
- S1, the lantern wall: W2's frame widened, nine ribs from the street to its top rail, the two outer ones heavier, and a
  rail along its foot and its top; light climbing the ribs one after another.
- S2, the fence: five rails across it between three posts (its ends and its middle), drawn out from the middle; light
  running along the rails.
It faces the way the lead comes in, here from the player's side, as it rises when a wave meets the lead. Where the lead
then stands beside the foe at 45 degrees (TR69 F), the screen turns with it and is seen 42 degrees off face on: about 180
pixels of 2042 for its 8 studs, the lead over its left end (tried at 22:27, not kept).

Frames at 60 a second from the wind-up's first. Each strip's tiles share the stage's one frozen frame: an ordinary
Brawler at Scale 1, its pose not the overhead's. The strip judges the tell's life, not the body: the gather's rows scale
with the elite's body (Scale 1.35), the footprint is the hit's own size in studs.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fight_read_targets import INK as MARK_INK, STAGE, Street  # noqa: E402
from paintover import hexc, phone_sheets, strip, write_png  # noqa: E402
from shade_targets import (  # noqa: E402
    AMBER, AMBER_DEEP, AZURE, back_out, band, ease_out, life, on_cylinder, on_plane, paint, region, soft,
)
from ward_targets import INK as WARD_INK, INK_A, ink_light, taper  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "handoff" / "Fight" / "targets" / "elite"
UP = np.array([0.0, 1.0, 0.0])
WHITE = hexc("#FFFFFF")
INK = hexc("#2A1400")  # the warm ink hair under a pale line (D1's deep, darker)
WIND = 72  # the overhead's wind-up, 1.2 s: Strike's frame
FOOT = {"Ahead": 3.4, "Radius": 3.0}  # the overhead's footprint, seeds (the swipe's Reach is 5.5)
OVER = 0.35  # the raised fists' height over the mask's top, studs (the body's, scaled with it)
CROP = [820, 230, 800, 470]

FAN = {"Spread": 25, "Half": 2.0, "Length": 14.0, "Run": 12.0}  # Config.Combat.Dasher.Line's lane, three times
LUNGE, LAND = 44, 59  # DasherLunge's beats after Line, in frames (the elite's clip keeps them)
FAN_CROP = [560, 330, 1000, 588]
SCREEN = {"Wide": 8.0, "High": 3.6, "Ahead": 2.2, "Curve": 7.0}  # seeds
DROP = 120  # Drop after Raise, frames (GuardRaise's 0.3 s and 2.3 s)
SCREEN_GLANCE = 40
SCREEN_CROP = [900, 330, 620, 365]

TARGETS = {
    # name: (peak frame, the strip's frames, the frame the strip counts from)
    "O1_weight": (60, [0, 4, 24, 44, 60, 68, 72, 74, 78], "the wind-up's first; Strike at 72"),
    "O2_halo": (60, [0, 4, 24, 44, 60, 68, 72, 74, 78], "the wind-up's first; Strike at 72"),
    "F1_fan": (30, [0, 2, 4, 8, 20, 40, LUNGE + 7, LAND, LAND + 3], "Line; Lunge at 44, Land at 59"),
    "F2_blades": (30, [0, 2, 4, 8, 20, 40, LUNGE + 7, LAND, LAND + 3], "Line; Lunge at 44, Land at 59"),
    "S1_lantern": (20, [-6, -3, 0, 3, 20, SCREEN_GLANCE, SCREEN_GLANCE + 2, SCREEN_GLANCE + 6, DROP + 4],
                   "Raise; a glance at 40, Drop at 120"),
    "S2_fence": (20, [-6, -3, 0, 3, 20, SCREEN_GLANCE, SCREEN_GLANCE + 2, SCREEN_GLANCE + 6, DROP + 4],
                 "Raise; a glance at 40, Drop at 120"),
}


def draw_mark(fr, st, k):
    """R4 settled on the foe as the build draws it (fight_read_targets.py, R4_mark), at opacity k."""
    if k <= 0:
        return
    top = st.mask_at[1] + st.mask_size[1] / 2
    apex = np.array([st.root[0], top + 0.55, st.root[2]])
    px = fr.cam.px(apex, 1.0)
    a = fr.at(apex)
    wings = [a + np.array([-0.5, -0.46]) * px, a + np.array([0.5, -0.46]) * px]
    for w_ in wings:
        fr.streak(w_, a, 0.2 * px, 0.2 * px, MARK_INK, ink=0.6 * k, screen=True)
    for w_ in wings:
        fr.streak(w_, a, 0.14 * px, 0.14 * px, st.type, 1.3 * k, screen=True)
    for w_ in wings:
        fr.streak(w_, a, 0.045 * px, 0.045 * px, WHITE, 1.4 * k, screen=True)


def behind(fr, st, before, names=("Lead", "Avatar")):
    """Light added since `before` (a copy of fr.light), put behind the nearer bodies."""
    occ = st.mask(*names)
    fr.light = before + (fr.light - before) * (1 - occ[..., None])


def gather_point(st):
    top = st.mask_at[1] + st.mask_size[1] / 2
    return np.array([st.root[0], top + OVER, st.root[2]])


def foot_centre(st):
    return np.array([st.root[0], st.ground + 0.04, st.root[2]]) + st.aim * FOOT["Ahead"]


def heat(f, hit):
    """The rim's light as its hit nears: 0.55 at the cut to 1.3 on the hit, eased in."""
    return 0.55 + 0.75 * life(f, 0, hit) ** 1.5


# --- the footprint: D1's make on a disc ---------------------------------------------------------------------------------
def draw_footprint(fr, st, f):
    if f < 0 or f > WIND + 8:
        return
    R = FOOT["Radius"]
    C = foot_centre(st)
    side = np.cross(UP, st.aim)
    corners = [C + side * sx * R * 1.35 + st.aim * va * R * 1.35 for sx in (-1, 1) for va in (-1, 1)]
    sl = region(fr, corners)
    u, v, t, cos = on_plane(fr, sl, C, side, st.aim)
    ok = t > 0
    aa = np.where(ok, t, 1e3) / fr.cam.focal * 1.3 / np.maximum(np.abs(cos), 0.12) * 0.35
    r = np.hypot(u, v)
    edge_r = R * min(back_out(life(f, 0, 5), 1.0), 1.06)
    fuse = R * life(f, 0, WIND)  # linear: the honest timer
    landed = f >= WIND
    close = 1 - life(f, WIND + 2, WIND + 8)
    flash = 0.9 if WIND <= f < WIND + 2 else 0.0
    rim = r - edge_r
    inside = soft(rim, aa)
    edge = (band(rim, 0.06) * 3.0 + band(rim, 0.22) * 0.8) * heat(f, WIND)
    filled = soft(r - fuse, aa) * inside
    front = band(r - fuse, 0.10) * 2.4 * inside * float(not landed) * float(f > 2)
    light = (inside * 0.22 + filled * 0.55 + edge + front) * close * (1 + flash)
    laid = np.clip(inside * 0.22 + filled * 0.18, 0, 1) * close
    occ = st.mask("Lead", "Shade", "Avatar")
    paint(fr, sl, np.where(ok, laid, 0), np.where(ok, light, 0), AMBER, AMBER_DEEP, 1.0, occ)
    if WIND <= f <= WIND + 8:  # the punctuation: a ring run out flat, needles thrown off, a light
        before = fr.light.copy()
        g = f - WIND
        k = 1 - life(g, 1, 8)
        ring_r = R * (1.0 + 0.35 * ease_out(g / 6))
        ring = band(r - ring_r, 0.12) * 2.2 * k
        fr.add(sl, np.where(ok, ring, 0) * (1 - occ[sl]), AMBER, 1.0)
        fr.add(sl, np.where(ok, band(r - ring_r, 0.04), 0) * k * (1 - occ[sl]), WHITE, 1.2)
        fr.spikes(C + UP * 0.3, 9, R * (0.7 + 0.5 * ease_out(g / 4)), 0.16, AMBER, 1.9 * k, seed=5, up=0.35, flat=0.45)
        fr.core(C + UP * 0.5, 0.45, AMBER, 2.6 * (1 - life(g, 0, 6)))
        behind(fr, st, before)


# --- the blow: the gathered light falls along the overhead's arc ---------------------------------------------------------
def draw_blow(fr, st, f):
    if f < WIND or f > WIND + 6:
        return
    G, C = gather_point(st), foot_centre(st) + UP * 0.4
    ctrl = G + st.aim * FOOT["Ahead"] * 0.9 + UP * 0.6
    g = life(f, WIND, WIND + 4)
    fade = 1 - life(f, WIND + 4, WIND + 6)

    def at(s):
        return (1 - s) ** 2 * G + 2 * (1 - s) * s * ctrl + s * s * C

    before = fr.light.copy()
    tail0 = max(0.0, g - 0.75)
    steps = 14
    for i in range(steps):
        s0 = tail0 + (g - tail0) * i / steps
        s1 = tail0 + (g - tail0) * (i + 1) / steps
        w0 = 0.17 + 0.33 * i / steps
        w1 = 0.17 + 0.33 * (i + 1) / steps
        fr.streak(at(s0), at(s1), w0, w1, AMBER, 1.5 * fade, soft=0.8)
        fr.streak(at(s0), at(s1), w0 * 0.35, w1 * 0.35, WHITE, 1.6 * fade, soft=0.8)
    fr.core(at(g), 0.32, AMBER, 2.4 * fade)
    behind(fr, st, before)


# --- O1, the weight -----------------------------------------------------------------------------------------------------
def draw_weight(fr, st, f):
    if f < 0 or f >= WIND:
        return
    G = gather_point(st)
    grow = life(f, 0, WIND - 8) ** 1.6  # eased in: it fills faster as the blow nears
    squeeze = ease_out(life(f, WIND - 8, WIND))
    radius = (0.2 + 0.62 * grow) * (1 - 0.22 * squeeze)  # 0.82 at most: an elite's stays under the target card
    k = 0.5 + 0.9 * grow
    # the streaks drawn in: each runs from 2.4 studs to the ball's edge in 14 frames, faster as it goes
    rng = np.random.default_rng(11)
    starts = np.arange(-12, WIND - 6, 2)
    for i, s in enumerate(starts):
        a = rng.uniform(0, 2 * math.pi)
        g = (f - s) / 14
        if g < 0 or g > 1:
            continue
        reach = 2.4 - (2.4 - radius) * g * g
        dirv = np.array([math.cos(a), math.sin(a) * 0.85])
        c = fr.at(G)
        px = fr.cam.px(G, 1.0)
        head = c + dirv * reach * px
        tail = c + dirv * min(reach + 0.5 + 0.9 * g, 2.9) * px
        b = (0.6 + 0.9 * grow) * math.sin(math.pi * g) ** 0.5
        fr.streak(tail, head, 0.02 * px, 0.15 * px, AMBER, 1.5 * b, screen=True)
        fr.streak(tail, head, 0.01 * px, 0.05 * px, WHITE, 1.3 * b, screen=True)
    # the ball: a lit shell with its rim, a white core, a small light round it (a body, not a bloom)
    fr.glow(G, radius * 1.9, AMBER, 0.16 * k, falloff=1.8)
    fr.dome(G, radius, AMBER, fill=0.55, rim=1.5 * k, rim_width=0.2)
    fr.glow(G, radius * 0.85, AMBER, 0.9 * k, falloff=6)
    fr.glow(G, radius * 0.45, WHITE, (1.0 + 2.2 * squeeze) * k, falloff=3)


# --- O2, the halo -------------------------------------------------------------------------------------------------------
def draw_halo(fr, st, f):
    if f < 0 or f >= WIND:
        return
    M = st.mask_at + st.mask_look * st.mask_size[2] * 0.3
    c = fr.at(M)
    px = fr.cam.px(M, 1.0)
    cut = ease_out(life(f, 0, 4))
    least = st.mask_size[:2].max() * 0.62  # the mask's own size: where the ring meets it
    left = 1 - life(f, 0, WIND)  # linear: the honest timer
    r = least + (2.1 - least) * left + 0.3 * (1 - cut)
    near = life(f, WIND - 10, WIND)
    k = (0.7 + 0.6 * life(f, 0, WIND) + 0.8 * near) * cut
    steps = 96
    pts = [c + np.array([math.cos(a), math.sin(a)]) * r * px for a in np.linspace(0, 2 * math.pi, steps + 1)]
    for p0, p1 in zip(pts, pts[1:]):
        fr.streak(p0, p1, 0.17 * px, 0.17 * px, INK, ink=0.45 * cut, screen=True)
    for p0, p1 in zip(pts, pts[1:]):
        fr.streak(p0, p1, (0.1 + 0.04 * near) * px, (0.1 + 0.04 * near) * px, AMBER, 1.1 * k, screen=True, soft=0.8)
        fr.streak(p0, p1, 0.035 * px, 0.035 * px, WHITE, 1.0 * k, screen=True, soft=0.8)
    # the mask lights as the ring closes on it: its face, its cuts kept, and a warm light round it
    glint = life(f, WIND - 24, WIND) ** 2
    if glint > 0:
        sl = region(fr, [st.mask_at + d * st.mask_size.max() * 0.7 for d in (np.array([1, 0, 0]), np.array([-1, 0, 0]), UP, -UP)], pad=40)
        face = st.masks["Shade"][sl] * (fr.yy[sl] < fr.at(st.mask_at - st.mask_up * st.mask_size[1] * 0.45)[1])
        face = face * (1 - st.mask("Lead", "Avatar")[sl])
        fr.add(sl, face, AMBER, 0.35 * glint)
        fr.add(sl, face, WHITE, 0.12 * glint)
        fr.glow(M, 1.0, AMBER, 0.45 * glint)
    # the fists' light, where the blow will come from, in the last frames
    G = gather_point(st)
    fr.core(G, 0.12 + 0.18 * near, AMBER, 2.0 * near)


# --- the fan: D1's lane, three times ------------------------------------------------------------------------------------
def lane_dirs():
    out = []
    for deg in (-FAN["Spread"], 0, FAN["Spread"]):
        t = math.radians(deg)
        out.append((math.sin(t), math.cos(t)))  # in (across, along) of the middle lane
    return out


def draw_fan(fr, st, f, shape):
    if f < 0 or f > LAND + 8:
        return
    L, half = FAN["Length"], FAN["Half"]
    feet = np.array([st.root[0], st.ground + 0.04, st.root[2]])
    side = np.cross(UP, st.aim)
    dirs = lane_dirs()
    pts = [feet + side * (dx * (L + half + 1) + sx) + st.aim * (dy * (L + half + 1)) for dx, dy in dirs for sx in (-half - 1, half + 1)]
    pts += [feet - st.aim * (half + 1) + side * sx for sx in (-half - 1, half + 1)]
    sl = region(fr, pts)
    u, v, t, cos = on_plane(fr, sl, feet, side, st.aim)
    ok = t > 0
    aa = np.where(ok, t, 1e3) / fr.cam.focal * 1.3 / np.maximum(np.abs(cos), 0.12) * 0.35
    landed = f >= LAND
    close = 1 - life(f, LAND, LAND + 6)
    flash = 0.7 if LAND <= f < LAND + 2 else 0.0
    fuse = L * life(f, 0, LAND)  # linear: the honest timer
    rims, alongs, acrosses, cuts = [], [], [], []
    for i, (dx, dy) in enumerate(dirs):
        along = u * dx + v * dy
        across = u * dy - v * dx
        start = 0 if shape == "F1_fan" else (0, 3, 6)[i]
        cuts.append(ease_out(life(f, start, start + 4)))
        cut = ease_out(life(f, start, start + 4))
        width = half * (0.25 + 0.75 * ease_out(life(f, start + 1, start + 5)))
        reach = (L + half) * cut
        rim = np.hypot(across, along - np.clip(along, 0, L)) - width
        rims.append(np.maximum(rim, along - reach))  # cut open from the feet
        alongs.append(along)
        acrosses.append(across)
    if shape == "F1_fan":
        rim = np.minimum.reduce(rims)
        inside = soft(rim, aa)
        edge = (band(rim, 0.06) * 3.0 + band(rim, 0.22) * 0.8) * heat(f, LAND)
        r = np.hypot(u, v)
        filled = soft(r - fuse, aa) * inside
        front = band(r - fuse, 0.10) * 2.4 * inside * float(not landed) * float(f > 2)
        light = (inside * 0.22 + filled * 0.55 + edge + front) * close * (1 + flash)
        laid = np.clip(inside * 0.22 + filled * 0.18, 0, 1) * close
    else:  # the blades
        rim = np.minimum.reduce(rims)
        inside = soft(rim, aa)
        hair = band(rim, 0.04) * 1.1 * heat(f, LAND)
        blade_light = np.zeros_like(u)
        blade_laid = np.zeros_like(u)
        for al, ac, cut in zip(alongs, acrosses, cuts):
            s_ = np.clip(al / L, 0, 1)
            w = 0.62 * np.sin(np.pi * s_) ** 0.6 + 0.03  # pointed at both ends, widest at the middle: a claw's mark
            drawn = soft(al - L * cut, aa) * (al > 0)
            blade = soft(np.abs(ac) - w, aa) * drawn
            lit = soft(al - fuse, aa) if not landed else np.ones_like(al)
            core = band(ac, 0.09) * blade * lit
            tip = band(al - fuse, 0.18) * soft(np.abs(ac) - w * 1.6, aa) * drawn * float(not landed) * float(f > 2)
            blade_light = np.maximum(blade_light, blade * (0.75 + 1.1 * lit) + core * 1.8 + tip * 2.6)
            blade_laid = np.maximum(blade_laid, blade * (0.35 + 0.25 * lit))
        light = (inside * 0.12 + hair + blade_light) * close * (1 + flash)
        laid = np.clip(inside * 0.14 + blade_laid, 0, 1) * close
    occ = st.mask("Lead", "Shade", "Avatar")
    paint(fr, sl, np.where(ok, laid, 0), np.where(ok, light, 0), AMBER, AMBER_DEEP, 1.0, occ)
    # the lunge: the body down the middle, an afterimage down each side, from Lunge to Land; a slash where each lands
    if LUNGE <= f <= LAND + 6:
        before = fr.light.copy()
        chest = st.chest[1] - st.ground
        g = life(f, LUNGE, LAND)
        k = 1 - life(f, LAND, LAND + 4)
        for i, (dx, dy) in enumerate(dirs):
            d = side * dx + st.aim * dy
            head = feet + d * (FAN["Run"] * g) + UP * chest
            tail = feet + d * max(FAN["Run"] * g - 5.5, 0) + UP * chest
            body = 1.0 if i == 1 else 0.7
            if f <= LAND + 4:
                fr.streak(tail, head, 0.05, 0.55 * body, AMBER, 1.6 * k * body)
                fr.streak(tail, head, 0.02, 0.18 * body, WHITE, 1.6 * k * body)
            if f >= LAND:
                h = f - LAND
                p = feet + d * FAN["Run"] + UP * chest
                fr.core(p, 0.3, AMBER, 3.0 * (1 - life(h, 0, 5)) * body)
                fr.spikes(p, 7, 1.6 * (0.5 + 0.5 * ease_out(h / 4)), 0.12, AMBER, 1.8 * (1 - life(h, 1, 6)) * body, seed=3 + i, up=0.2)
        behind(fr, st, before, ("Avatar",))


# --- the Guard's screen: W2's make, a wall ------------------------------------------------------------------------------
def screen_beats(f):
    if f < -8 or f > DROP + 8:
        return 0.0, 0.0
    drawn = ease_out(life(f, -8, -1)) * (1 - life(f, DROP, DROP + 8))
    click = 1 + 1.4 * (1 - life(f, 0, 5)) * float(f >= 0)
    return drawn, click


def screen_strokes(su, yv, aa, f, drawn, shape, run_k=1.0, halo=0.25):
    """The screen's strokes at (su across from its middle, yv up from the street), studs: lists of (ink, light, core)
    per stroke, W2's ink_light. Drawn up from the street to `drawn` of its height (the rails out from its middle), the
    light running along them at `run_k` (0: the still frame), with `halo` of glow round each (the game's pictures have
    none, the ward's must-fix). The targets and the game's pictures (pictures()) both."""
    W, H = SCREEN["Wide"], SCREEN["High"]
    edges, lights, cores = [], [], []
    base = 0.15
    top = base + (H - base) * drawn
    if shape == "S1_lantern":
        for i, c in enumerate(np.linspace(-W / 2, W / 2, 9)):
            outer = i in (0, 8)
            sf = np.clip((yv - base) / max(top - base, 1e-3), 0, 1)
            inside = (yv >= base) & (yv <= top)
            bow = 0.05 * np.sin(np.pi * sf) * np.sign(c)
            d = np.abs(su - c - bow)
            width = (0.2 if outer else 0.13) * taper(sf) * inside
            phase = (f / 50 + 0.17 * i) % 1.4 - 0.2
            run = 1 + 0.9 * run_k * np.exp(-((sf - phase) / 0.09) ** 2)
            e, l_, co = ink_light(d, width, aa, 1.0, core_k=1.0 if outer else 0.6, halo=halo)
            edges.append(e), lights.append(l_ * run), cores.append(co * run)
        rails = [(0.3, 0.17), (H - 0.2, 0.17)]
        run_rails = False
    else:
        for i, c in enumerate((-W / 2, 0.0, W / 2)):
            sf = np.clip((yv - base) / max(top - base, 1e-3), 0, 1)
            inside = (yv >= base) & (yv <= top)
            d = np.abs(su - c)
            width = 0.2 * taper(sf) * inside
            e, l_, co = ink_light(d, width, aa, 1.0, halo=halo)
            edges.append(e), lights.append(l_), cores.append(co)
        rails = [(h, 0.13) for h in np.linspace(0.5, H - 0.25, 5)]
        run_rails = True
    for j, (h, wd) in enumerate(rails):
        if h > top + 0.05:
            continue
        half = W / 2 * drawn
        sf = (su + half) / max(2 * half, 1e-3)
        d = np.abs(yv - h - 0.04 * np.sin(np.pi * np.clip(sf, 0, 1)) * (1 if h > H / 2 else -1))
        width = wd * taper(sf)
        e, l_, co = ink_light(d, width, aa, 1.0, core_k=0.8, halo=halo)
        if run_rails:
            phase = (f / 60 + 0.23 * j) % 1.4 - 0.2
            l_ = l_ * (1 + 0.9 * run_k * np.exp(-((np.clip(sf, 0, 1) - phase) / 0.08) ** 2))
        edges.append(e), lights.append(l_), cores.append(co)
    return edges, lights, cores


def draw_screen(fr, st, f, shape):
    drawn, click = screen_beats(f)
    if drawn <= 0:
        return
    W, H, Rc = SCREEN["Wide"], SCREEN["High"], SCREEN["Curve"]
    feet = np.array([st.root[0], st.ground, st.root[2]])
    facing = st.avatar - feet  # the way the lead comes in: from the player's side
    facing[1] = 0
    facing = facing / np.linalg.norm(facing)
    side = np.cross(UP, facing)
    centre = feet + facing * (SCREEN["Ahead"] - Rc)
    pts = []
    for sv in (-W / 2 - 0.5, 0, W / 2 + 0.5):
        a = sv / Rc
        d = facing * math.cos(a) + side * math.sin(a)
        pts += [centre + d * Rc + UP * y for y in (-0.3, H + 0.4)]
    sl = region(fr, pts, pad=30)
    (s0, y0, t0, _), (s1, y1, t1, _) = on_cylinder(fr, sl, centre, Rc, facing)
    y0, y1 = y0 - st.ground, y1 - st.ground
    in0 = (np.abs(s0) <= W / 2 + 0.4) & (y0 > -0.3) & (y0 < H + 0.4) & np.isfinite(t0)
    in1 = (np.abs(s1) <= W / 2 + 0.4) & (y1 > -0.3) & (y1 < H + 0.4) & np.isfinite(t1)
    su, yv = np.where(in0, s0, s1), np.where(in0, y0, y1)
    t = np.where(in0, t0, np.where(in1, t1, 1e3))
    ok = in0 | in1
    aa = t / fr.cam.focal * 1.2
    edges, lights, cores = screen_strokes(su, yv, aa, f, drawn, shape)
    edge = np.clip(sum(edges), 0, 1)
    light = sum(lights) * click
    core = sum(cores) * click
    g = f - SCREEN_GLANCE
    contact_s, contact_y = 0.0, 3.0
    if 0 <= g <= 14:  # the strokes round where the blow lands, lit
        near = np.exp(-((su - contact_s) ** 2 + (yv - contact_y) ** 2) / 0.9 ** 2)
        lit = 1 + 2.2 * near * (1 - life(g, 0, 14))
        light, core = light * lit, core * lit
    keep = (1 - st.mask("Lead", "Avatar")[sl]) * ok
    fr.lay(sl, edge * keep, WARD_INK, INK_A)
    fr.add(sl, light * keep, AZURE, 2.0)
    fr.add(sl, core * keep, WHITE, 1.1)
    if 0 <= g <= 8:  # a white core where it lands and needles skating back at the attacker
        before = fr.light.copy()
        p = centre + facing * Rc + UP * contact_y
        back = st.lead_chest - p
        back[1] = 0
        back = back / np.linalg.norm(back)
        fr.core(p, 0.22, AZURE, 2.6 * (1 - life(g, 0, 6)))
        rng = np.random.default_rng(7)
        for _ in range(5):
            jitter = side * rng.uniform(-0.6, 0.6) + UP * rng.uniform(-0.4, 0.5)
            dirv = back + jitter
            dirv = dirv / np.linalg.norm(dirv)
            reach = 0.4 + 1.2 * ease_out(g / 6)
            fr.streak(p + dirv * reach * 0.35, p + dirv * reach, 0.07, 0.01, AZURE, 1.6 * (1 - life(g, 2, 8)))
        behind(fr, st, before)


DRAW = {"O1_weight": draw_weight, "O2_halo": draw_halo}
FANS = ("F1_fan", "F2_blades")
SCREENS = ("S1_lantern", "S2_fence")


def render(st, name, f):
    fr = st.frame()
    if name in FANS or name in SCREENS:  # R4 stays on
        draw_mark(fr, st, 1.0)
        (draw_fan if name in FANS else draw_screen)(fr, st, f, name)
        out = fr.render()
        return out if st.hud is None else out * (1 - st.hud) + st.base * st.hud
    if name == "O1_weight":  # the ball takes R4's spot: R4 out over 4 frames, back 4 after the blow
        draw_mark(fr, st, 1 - life(f, 0, 4) + life(f, WIND + 6, WIND + 10))
    else:
        draw_mark(fr, st, 1.0)
    draw_footprint(fr, st, f)
    DRAW[name](fr, st, f)
    draw_blow(fr, st, f)
    out = fr.render()
    return out if st.hud is None else out * (1 - st.hud) + st.base * st.hud


def crop(img, box):
    x, y, w, h = box
    return img[y:y + h, x:x + w]


# --- the game's pictures: research's picks of 2026-11-26, 22:55 (O2's ring, S1's wall) ----------------------------------
PICTURES = ROOT / "build" / "handoff" / "Shade" / "fx" / "pictures"
HALO = {"End": 1.3, "Start": 2.4, "Share": 0.78}
# The ring's radius on the strike and on the wind-up's first frame, studs at Scale 1. The Brawler's mask is 2.7 wide and
# 2.1 tall: the ring ends tight on it, round its height, and starts 1.85 times as wide (research's must-fix: 1.8 times or
# more). Share: its radius as a share of its card's half, so the card is 2 x radius / Share across.
HALO_STROKE = 0.12  # the ring's body at its end, studs; twice that at its start, as its card is
HALO_PIC = 512
SCREEN_EXT = 4.3  # studs from the screen picture's middle to its edges, both ways: the wall's 8 across and its ink
SCREEN_MID = (0.15 + SCREEN["High"]) / 2  # the wall's middle over the street, the picture's middle
SCREEN_PIC = 1024  # pixels a side: 119 a stud, a rib about 15
SCREEN_RUN = 70  # frames: the light climbs the ribs once every 1.4 x 50 frames (screen_strokes)
SCREEN_CELL = 256  # a Grid4x4 flipbook's cell, the sheet 1024 a side, Roblox's most


def pictures(out=PICTURES):
    """The picks' pictures, white with straight alpha, tinted in the game, row 0 at the top:
    - overhead_ring_ink, _light, _core: O2's ring at its end size, its hair of ink, its body and its white core;
    - guard_screen_ink, _light, _core: S1's wall drawn whole and flat (the target's curve left out: a particle is flat),
      no running light; guard_screen_run: the light the run adds, 16 steps of one cycle, a Grid4x4 sheet, looped."""
    from ward_targets import BORDER, LIGHT_MAX, write_rgba
    out = Path(out)

    def write(name, alpha):
        write_rgba(alpha, out / f"{name}.png")
        print(name, (out / f"{name}.png").resolve().relative_to(ROOT).as_posix(), f"coverage {float((alpha > 0.02).mean()):.3f}")

    half = HALO["End"] / HALO["Share"]
    step = 2 * half / HALO_PIC
    axis = -half + (np.arange(HALO_PIC) + 0.5) * step
    u, v = np.meshgrid(axis, -axis)
    d = np.abs(np.hypot(u, v) - HALO["End"])
    edge, light, core = ink_light(d, np.full_like(d, HALO_STROKE), step, 1.0, halo=0.0)
    write("overhead_ring_ink", np.clip(edge, 0, 1))
    write("overhead_ring_light", np.clip(light / LIGHT_MAX, 0, 1))
    write("overhead_ring_core", np.clip(core, 0, 1))

    def plane(size):
        st_ = 2 * SCREEN_EXT / size
        ax = -SCREEN_EXT + (np.arange(size) + 0.5) * st_
        su, v_ = np.meshgrid(ax, -ax)
        window = np.clip((SCREEN_EXT - np.maximum(np.abs(su), np.abs(v_))) / BORDER, 0, 1) ** 2
        return su, v_ + SCREEN_MID, st_, window

    su, yv, step, window = plane(SCREEN_PIC)
    edges, lights, cores = screen_strokes(su, yv, step, 0, 1.0, "S1_lantern", run_k=0.0, halo=0.0)
    write("guard_screen_ink", np.clip(sum(edges), 0, 1) * window)
    write("guard_screen_light", np.clip(sum(lights) / LIGHT_MAX, 0, 1) * window)
    write("guard_screen_core", np.clip(sum(cores), 0, 1) * window)
    su, yv, step, window = plane(SCREEN_CELL)
    still = sum(screen_strokes(su, yv, step, 0, 1.0, "S1_lantern", run_k=0.0, halo=0.0)[1])
    cells = [np.clip(sum(screen_strokes(su, yv, step, k * SCREEN_RUN / 16, 1.0, "S1_lantern", halo=0.0)[1]) - still, 0, None)
             for k in range(16)]
    top = max(float(c.max()) for c in cells)
    sheet = np.concatenate([np.concatenate(cells[r * 4:(r + 1) * 4], axis=1) for r in range(4)], axis=0)
    write("guard_screen_run", sheet / top * np.tile(window, (4, 4)))


def main(argv):
    if argv[:1] == ["--pictures"]:
        pictures(Path(argv[1]) if len(argv) > 1 else PICTURES)
        return
    out = Path(argv[0]) if argv else OUT
    only = argv[1].split(",") if len(argv) > 1 else None
    out.mkdir(parents=True, exist_ok=True)
    st = Street(STAGE)
    st.avatar = np.array(json.loads(STAGE.read_text(encoding="utf-8"))["Avatar"], float)
    peaks, names = [], []
    for name, (peak, times, counted) in TARGETS.items():
        if only and name not in only:
            continue
        path = out / f"{name}_street_peak.png"
        write_png(render(st, name, peak), path)
        peaks.append(path)
        names.append(f"{name} (street, frame {peak} from {counted.split(';')[0]})")
        box = FAN_CROP if name in FANS else SCREEN_CROP if name in SCREENS else CROP
        strip([crop(render(st, name, f), box) for f in times], out / f"{name}_street_strip.png")
        (out / f"{name}_street_strip.txt").write_text(
            f"frames from {counted}, at 60 a second: " + ", ".join(map(str, times)) + "\n", encoding="utf-8")
        print(name, "peak", peak)
    if peaks:
        sheet = out / "phone_street"
        sheet.mkdir(exist_ok=True)
        phone_sheets(peaks, sheet, names)


if __name__ == "__main__":
    main(sys.argv[1:])
