"""Kirra's blades, overhauled (docs/requests/AR78.md): the targets, the belt pair at 2.8 studs, round 3's technique.

The director, 2026-11-28, about 02:40: "kirra swords model on her back is horrible still look like toys". Research's
cause: thick flat blades in an even grey with a soft shine, like plastic; a guard and a grip too large for the blade;
bare steel worn on the back. Its direction: two short blades, sheathed in dark scabbards, crossed low on her back,
the grips wrapped in her blue, the metal thin and dark with one bright line, no shine.

Round 1 drew three carries at 1.58 studs (a low cross at 30 degrees, a belt pair at 8, a steep cross at 55). The
director, 2026-11-28, 11:04, on its sheet: "they are way to small and i like B pose more". So round 2 is B, the belt pair
(a flat X across her belt, 8 degrees off level, the grips out past her hips), at three sizes. Each scales research's
proportions whole, so the grip and guard stay in proportion to the blade (a guard and grip too large for it was a toy
cue):
- the blade: 1.58 x S studs from the pommel's end to the scabbard's end (today's 1.86), its grip 0.44 of them, in a
  cord of her blue wound in diamonds over the dark, a dark iron cap, a small oval guard of dark iron whose rim is the
  one bright line;
- a slim scabbard in near-black lacquer, matte; a dark iron mouth and end; her teal cord wound once under the mouth,
  a dark loop lower down (a lit line along it, tried, didn't read at 4x: dropped);
- the steel stays in it (its drawn look comes with the pick, for Scarf Step).

The director, 2026-11-28, 11:12, on round 2: "2.8 but they look like toys...". Round 3 (below, "round 3") keeps that
size and carry and changes the technique: each blade swept along one arch in oval tapered sections, a notched wrapped
grip with windows, a flat guard, a lacquer streak placed by the way a face looks, two keepers tying the pair to her;
slim (K1) and bold (K2). A blind reader: bold reads as real swords up close and from the game's camera, slim as
chopsticks; its toy cues left were the streak (one even stripe, a decal), the keepers (staples), dark ends that looked
cut off, guards lost in the dark, the X low over her legs. So: two glints that fade, a cord lashing at the X's middle,
muted silver caps and a guard rim with washers, the line raised 0.1; bold (K3) and bolder (K4).

    blender.exe -b --factory-startup --python tools/blender/kirra_blades_takes.py -- <out_dir> takes [T B3 K3 K4]
    blender.exe -b --factory-startup --python tools/blender/kirra_blades_takes.py -- <out_dir> sheet

`takes` draws today's Kirra (T), round 2 at the pick (B3) and round 3's two from her back, from behind her left, from the game's camera and in the
game's frame; `sheet` lays them side by side: at the reference unit's size, at the smallest phone's size in the game's
frame, and up close (internal, beside an Anime Vanguards unit: build/reference/takes/kirra_blades_beside.png; ours
alone: <out_dir>/kirra_blades.png).
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make as km  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_sheet as rs  # noqa: E402
from anime_make import tone  # noqa: E402

TODAY = dict(ks.SHEATHS)
NAVY, TEAL = "#26345F", "#1FA39A"                       # her top and her scarf
LACQUER, IRON, LINE = "#14171F", "#2A2F3A", "#D3DCE8"   # the scabbard, the fittings, the one bright line
CORD, UNDER = "#3A5598", "#0D1017"                      # her blue, lifted off her navy top, and the dark under it
LOOP = "#1B1F2B"
BASE = 1.58     # round 1's length, the pommel's end to the scabbard's end; each size scales it and every section whole
SIZES = {"B1": 1.4, "B2": 1.6, "B3": 1.8}
S = 1.0         # the take's size, set before its make


def carry(size, angle=8.0, z=2.62):
    """B's lines at `size`, (the pommel's end, the scabbard's end), the right one under: a flat X across her belt,
    `angle` degrees off level, each pommel out past her hip by 0.3 x size, the pair standing off her back by its
    thickness."""
    length, x = BASE * size, 1.0 + 0.3 * size
    inner = -0.52 - 0.06 * size
    outer = inner - 0.12 * size
    d = Vector((-math.cos(math.radians(angle)), 0.0, -math.sin(math.radians(angle))))
    right, left = Vector((x, inner, z)), Vector((-x, outer, z))
    return {"Right": (tuple(right), tuple(right + d * length)),
            "Left": (tuple(left), tuple(left + Vector((-d.x, 0.0, d.z)) * length))}


CARRIES = {k: carry(v) for k, v in SIZES.items()}
SAID = {
    "T": ("Today", ("the lacquered pair, in the game:", "crossed high, 1.86 studs, light fittings")),
    **{k: (f"B at {BASE * v:.1f} studs", ("the belt pair, a flat X at 8 degrees,", f"the grips past her hips, x{v:g} round 1"))
       for k, v in SIZES.items()},
    "K3": ("Round 3, bold", ("arched, oval, tapered; a wrapped grip, a flat", "guard, two glints, silver caps, a lashing")),
    "K4": ("Round 3, bolder", ("the same, 1.7 times round 3's slim", "across and through")),
}


def sized(rings):
    """Rings drawn at round 1's size, at the take's: along, across and through, all by S."""
    return [tuple(v * S for v in r) for r in rings]


def wrapped_grip(b, side, a, b_, w, t, rows=9):
    """The grip from `a` to `b_`: her blue cord wound in diamonds over the dark, each turn a stretch, the cord's
    crossings stepping round a side a turn."""
    rings = sized([(a + (b_ - a) * i / rows, w, t) for i in range(rows + 1)])
    km.turned(b, side, rings, lambda i, k: CORD if (i + k) % 2 == 0 else UNDER)


def hilt(b, side):
    km.turned(b, side, sized([(0.0, 0.042, 0.036), (0.01, 0.062, 0.052), (0.03, 0.062, 0.052)]), [IRON, IRON])   # the cap
    wrapped_grip(b, side, 0.03, 0.47, 0.058, 0.05, rows=8)
    # the guard: small and oval, dark iron, its rim the one bright line
    km.turned(b, side, sized([(0.47, 0.064, 0.052), (0.47, 0.1, 0.07), (0.482, 0.106, 0.074), (0.495, 0.1, 0.07),
                              (0.495, 0.064, 0.052)]), [IRON, LINE, LINE, IRON], sides=12, offset=15.0)


def scabbard(b, side):
    rings = [(0.497, 0.074, 0.056), (0.54, 0.074, 0.056),                             # the mouth, dark iron
             (0.54, 0.07, 0.052), (0.57, 0.07, 0.052),
             (0.57, 0.078, 0.06), (0.62, 0.078, 0.06), (0.62, 0.07, 0.052),           # her teal cord, wound once
             (0.98, 0.066, 0.05), (0.98, 0.075, 0.059), (1.04, 0.075, 0.059), (1.04, 0.066, 0.05),   # the loop
             (BASE - 0.08, 0.06, 0.046), (BASE - 0.08, 0.064, 0.049), (BASE - 0.025, 0.054, 0.043),
             (BASE, 0.026, 0.022)]   # the end, iron
    cols = [IRON, LACQUER, TEAL, TEAL, TEAL, LACQUER, LOOP, LOOP, LOOP, LACQUER, IRON, IRON, IRON, IRON]
    km.turned(b, side, sized(rings), cols)


def pair(line):
    """The make for kt.take_a: the scarf, a hilt a blade on its own piece, the scabbards one piece, the tail."""
    def make(colour, ends, guards):
        ks.SHEATHS = dict(line)
        blades = []
        for piece, side in km.BLADES.items():
            b = am.Built(piece)
            hilt(b, side)
            blades.append(b)
        sheaths = am.Built("Sheaths")
        for side in km.BLADES.values():
            scabbard(sheaths, side)
        return [kt.scarf(colour, ends, long_tail=False), *blades, sheaths, *km.tail_chain(colour, ends)]
    return make


# --- round 3: the technique changed ----------------------------------------------------------------------------------
# The director, 2026-11-28, 11:12, on round 2: "2.8 but they look like toys...", the second "toys" on this piece (R5).
# At 3x, round 2's cues: a big square checker in saturated blue for a grip; a white ring for a guard, like a washer; a
# straight round rod of even thickness for a scabbard, its long body iron grey (round 2's colour list ran a stretch
# behind its rings, so the lacquer fell on steps of no length); a bright teal sleeve; and nothing holding the pair to
# her. So the turned straight rings go. Each blade is swept along one arched line (the edge up, its middle raised), in
# oval sections that taper; the grip is dark cord in a notched outline with small pale windows between its crossings;
# the guard a flat dark disc; the lacquer near black with one sharp streak on the face toward the light and the camera;
# her teal only as two thin wraps of cord at the mouth; two keepers of her cloth tie the pair to her back.
PICK = 1.8                  # the director's size (11:12): 1.58 x 1.8, about 2.8 studs
LEN = BASE * PICK
SORI = 0.028                # the arch: its middle above the line by this much of the length
LACQ, CORD3, WINDOW, HORN = "#0E1016", "#1B2340", "#CDC7B8", "#111217"
IRON3, SHEEN, STRAP = "#262A32", "#DCE4F0", "#171D33"
FITTING = "#6B7381"         # the caps, the guard's rim and its two washers: muted silver iron, so the ends read capped
HL = Vector((0.0, -0.55, 0.83)).normalized()   # the streak's face: toward the light from behind her and the camera
ACROSS = {"K3": 1.4, "K4": 1.7}   # the bold pair (the blind reader's nearer, over the slim one) and a bolder, across and
                                  # through


def arch(side, along):
    """The arched line at `along` studs from the pommel's end: its centre, the way along, up across it, through it."""
    top, d, s_, n = km.axes(side)
    up = s_ if s_.z > 0 else -s_
    u = along / LEN
    c = top + d * along + up * (4 * SORI * LEN * u * (1 - u))
    t = (d * LEN + up * (4 * SORI * LEN * (1 - 2 * u))).normalized()
    return c, t, (up - t * up.dot(t)).normalized(), n


def swept(b, side, rings, colour, sides=16, caps=True):
    """Oval rings round the arched line, (studs along, half up across it, half through); `colour(i, k, out)` for the
    stretch `i`, its face `k` round and the way that face looks. Each face takes the light's fall, as turned()'s do."""
    pts, frames = [], []
    for along, hw, ht in rings:
        c, t, w, n = arch(side, along)
        frames.append((t, w, n))
        pts.append([c + w * (hw * math.cos(2 * math.pi * k / sides)) + n * (ht * math.sin(2 * math.pi * k / sides))
                    for k in range(sides)])

    def out(i, k):
        _, w, n = frames[i]
        a = 2 * math.pi * (k + 0.5) / sides
        return (w * math.cos(a) + n * math.sin(a)).normalized()

    def shade(i, k):
        o = out(i, k)
        return tone(colour(i, k, o), 0.62 + 0.48 * max(0.0, o.dot(km.LIGHT_DIR)))
    ends = (tone(colour(0, 0, out(0, 0)), 0.7), tone(colour(len(rings) - 2, 0, out(len(rings) - 2, 0)), 0.7))
    b.tube(pts, shade, caps=ends if caps else None, smooth=False)


def by_stretch(cols):
    return lambda i, k, o: cols[i]


def katana(hilt_b, sheath_b, side, k):
    """One blade, sheathed, along its arched line: `k` scales every size across it (the slim pair 1, the bold 1.4)."""
    L = LEN
    # the cap at the pommel's end, dark iron, a little domed
    swept(hilt_b, side, [(0.0, 0.034 * k, 0.027 * k), (0.014, 0.056 * k, 0.045 * k), (0.06, 0.059 * k, 0.047 * k)],
          by_stretch([FITTING, FITTING]))
    # the grip: dark cord, waisted, its outline notched where the cord crosses, a pale window between each crossing
    g0, g1, steps = 0.06, 0.80, 12
    rings = []
    for j in range(steps + 1):
        along = g0 + (g1 - g0) * j / steps
        waist = 1 - 0.07 * math.sin(math.pi * j / steps)
        w = (0.06 if j % 2 == 0 else 0.053) * k * waist
        rings.append((along, w, 0.8 * w))
    swept(hilt_b, side, rings, by_stretch([CORD3] * steps), caps=False)
    for j in range(1, steps, 2):
        along = g0 + (g1 - g0) * j / steps
        c, t, w, n = arch(side, along)
        half_w = rings[j][1]
        for face in (-1, 1):
            at = c + n * face * (0.8 * half_w + 0.003)
            dl, dw = t * (0.5 * (g1 - g0) / steps * 0.78), w * (half_w * 0.62)
            quad = [at - dl, at + dw, at + dl, at - dw]
            if (quad[1] - quad[0]).cross(quad[2] - quad[1]).dot(n * face) < 0:   # wound to look out on its own side
                quad.reverse()
            hilt_b.face([hilt_b.bm.verts.new(q) for q in quad],
                        tone(WINDOW, 0.62 + 0.48 * max(0.0, (n * face).dot(km.LIGHT_DIR))), False)
    # the collar, then the guard: a flat oval disc of dark iron
    swept(hilt_b, side, [(0.80, 0.062 * k, 0.05 * k), (0.822, 0.062 * k, 0.05 * k), (0.822, 0.072 * k, 0.06 * k),
                         (0.83, 0.072 * k, 0.06 * k), (0.83, 0.115 * k, 0.1 * k), (0.858, 0.115 * k, 0.1 * k),
                         (0.858, 0.072 * k, 0.06 * k), (0.866, 0.072 * k, 0.06 * k), (0.866, 0.064 * k, 0.052 * k)],
          by_stretch([IRON3, IRON3, FITTING, IRON3, FITTING, IRON3, FITTING, IRON3]), sides=24)
    # the scabbard: a horn mouth, near-black lacquer tapering to the end, two thin wraps of her teal near the mouth, and
    # an iron end; the lacquer's one streak on the face toward the light and the camera
    def lac(along):
        u = (along - 0.9) / (L - 0.97)
        return 0.062 * k * (1 - 0.16 * u), 0.048 * k * (1 - 0.16 * u)

    stations = [(0.866, 0.066 * k, 0.052 * k), (0.9, 0.066 * k, 0.052 * k), (0.9, *lac(0.9))]
    cols = [HORN, HORN]
    for a0 in (0.98, 1.025):
        wa, ta = lac(a0)
        stations += [(a0, wa, ta), (a0, wa + 0.009 * k, ta + 0.009 * k), (a0 + 0.016, wa + 0.009 * k, ta + 0.009 * k),
                     (a0 + 0.016, wa, ta)]
        cols += [LACQ, TEAL, TEAL, TEAL]
    run0, run1 = 1.041, L - 0.08
    for j in range(1, 19):
        stations.append((run0 + (run1 - run0) * j / 18, *lac(run0 + (run1 - run0) * j / 18)))
        cols.append(LACQ)
    # the end: a capped iron end in the fittings' silver, flared at its mouth
    stations += [(L - 0.08, 0.061 * k, 0.049 * k), (L - 0.02, 0.059 * k, 0.047 * k), (L - 0.005, 0.05 * k, 0.04 * k),
                 (L, 0.03 * k, 0.024 * k)]
    cols += [FITTING, FITTING, FITTING, FITTING]
    assert len(cols) == len(stations) - 1, (len(cols), len(stations))
    mids = [(a[0] + b_[0]) / 2 for a, b_ in zip(stations, stations[1:])]

    def glint(along):
        """How bright the streak is here: two glints along the arch, at a third and near the end, fading between."""
        u = (along - 0.9) / (L - 0.97)
        return max(math.exp(-((u - 0.3) / 0.13) ** 2), 0.8 * math.exp(-((u - 0.78) / 0.09) ** 2))

    def lacquer(i, k_, o):
        if cols[i] != LACQ:
            return cols[i]
        g, facing = glint(mids[i]), o.dot(HL)
        if facing > 0.975:
            return am.mix(LACQ, SHEEN, 0.18 + 0.82 * g)
        if facing > 0.85:
            return am.mix(LACQ, SHEEN, 0.3 * g)
        return LACQ
    swept(sheath_b, side, stations, lacquer)


def cord(b, path, r, colour, sides=6):
    """A round cord along a closed `path`, each face taking the light's fall."""
    rings, outs = [], []
    n_ = len(path)
    for i, q in enumerate(path):
        t = (path[(i + 1) % n_] - path[i - 1]).normalized()
        a = t.cross(Vector((0, 0, 1))) if abs(t.z) < 0.9 else t.cross(Vector((1, 0, 0)))
        a.normalize()
        c = t.cross(a)
        dirs = [a * math.cos(2 * math.pi * k / sides) + c * math.sin(2 * math.pi * k / sides) for k in range(sides)]
        rings.append([q + v * r for v in dirs])
        outs.append(dirs)
    rings.append(rings[0])
    outs.append(outs[0])
    b.tube(rings, lambda i, k: tone(colour, 0.62 + 0.48 * max(0.0, ((outs[i][k] + outs[i][(k + 1) % sides]).normalized())
                                                                     .dot(km.LIGHT_DIR))), smooth=False)


def lashing(b, k):
    """Three turns of her teal cord round the X at its middle, where the two scabbards lie one behind the other, and
    round her belt: wound on a slant, crossing, so the pair reads as tied on (round 3's keepers read as staples)."""
    stack = []
    for side in km.BLADES.values():
        lo, hi = 0.0, LEN
        for _ in range(40):   # the place along where the line passes her middle
            mid = (lo + hi) / 2
            if arch(side, mid)[0].x * arch(side, lo)[0].x > 0:
                lo = mid
            else:
                hi = mid
        stack.append(arch(side, (lo + hi) / 2)[0])
    r = 0.016 * k
    zc = sum(c.z for c in stack) / 2
    half_h = 0.062 * k + r
    back = min(c.y for c in stack) - 0.048 * k - r
    front = -0.47
    ym, ry = (front + back) / 2, (front - back) / 2
    for x0, lean in ((-0.045 * k, 14.0), (0.0, -14.0), (0.045 * k, 14.0)):
        slant = math.tan(math.radians(lean))
        path = []
        for j in range(24):
            f = 2 * math.pi * j / 24
            box = lambda v: math.copysign(abs(v) ** 0.3, v)   # noqa: E731  a rounded box round the stack, not an oval
            z = zc + half_h * box(math.sin(f))
            path.append(Vector((x0 + slant * (z - zc), ym + ry * box(math.cos(f)), z)))
        cord(b, path, r, tone(TEAL, 0.85))


def carry3(k):
    """The pick's line, 2.8 studs at 8 degrees, the guards at her sides and the grips past her hips; the pair as close
    to her back as their guards let them."""
    angle, z, x = 8.0, 2.72, 1.85   # raised off round 2's 2.62: its low end sat over the top of her legs
    inner = -0.51 - 0.095 * k
    outer = inner - 0.145 * k - 0.01
    d = Vector((-math.cos(math.radians(angle)), 0.0, -math.sin(math.radians(angle))))
    right, left = Vector((x, inner, z)), Vector((-x, outer, z))
    return {"Right": (tuple(right), tuple(right + d * LEN)),
            "Left": (tuple(left), tuple(left + Vector((-d.x, 0.0, d.z)) * LEN))}


def pair3(k):
    """The make for kt.take_a: round 3's pair, its keepers with the scabbards."""
    def make(colour, ends, guards):
        ks.SHEATHS = carry3(k)
        blades, sheaths = [], am.Built("Sheaths")
        for piece, side in km.BLADES.items():
            b = am.Built(piece)
            katana(b, sheaths, side, k)
            blades.append(b)
        lashing(sheaths, k)
        return [kt.scarf(colour, ends, long_tail=False), *blades, sheaths, *km.tail_chain(colour, ends)]
    return make


def belted(key):
    """A take: her, with a belt right round her hips in place of the strap from her shoulder (it held the blades high;
    the scabbards ride the belt now), and the pair on `key`'s carry."""
    def run(joints, folder):
        global S
        S = SIZES.get(key, 1.0)
        held, blocks_of, strap = {}, kt.blocks_of, kt.strap

        def keep(*args, **kw):
            held["b"] = blocks_of(*args, **kw)
            return held["b"]

        def belt(p, a, b, colour, wide=0.1):
            if "belt" not in held:   # once, all round: the strap was drawn on her front and her back
                held["belt"] = rmt.band(held["b"]["torso"].wrap, 0.36, 0.48, colour, tone(colour, 0.5))
        kt.blocks_of, kt.strap = keep, belt
        try:
            pieces = pair3(ACROSS[key]) if key in ACROSS else pair(CARRIES[key])
            return kt.take_a(joints, folder, pieces=pieces, face_draw=km.PICK["face"])
        finally:
            kt.blocks_of, kt.strap = blocks_of, strap
    return run


def today(joints, folder):
    ks.SHEATHS = dict(TODAY)
    return kt.take_a(joints, folder, pieces=km.gear_pieces(km.lacquer), face_draw=km.PICK["face"])


SHEET = ("T", "B3", "K3", "K4")   # today, round 2 at the pick, round 3 bold and bolder (the line-up has five places)
TAKES = {"T": today, **{k: belted(k) for k in SHEET[1:]}}


# --- the sheet -------------------------------------------------------------------------------------------------------

def up(img, k):
    return np.repeat(np.repeat(img, k, axis=0), k, axis=1)


def sheet_run(out):
    import hard_ember as he
    import shade_elites as el
    shots, layers = out / "shots", out / "layers"
    ink, soft, paper, pale = "#EDE6D6", "#B4AC9C", "#101117", "#DFE1E6"
    keys = list(SHEET)
    gap, W = 24, 2560
    views = (("back", "from behind"), ("game", "the game's camera"))
    full = {(k, v): rs.trim(rs.load(shots / f"{k}_{v}.png")) for k in keys for v in ("back", "back34", "game")}
    k_ = 0.46   # then smaller, all alike, till the row and the reference fit the page
    av_w = rmt.reference(kt.BESIDE[0][0], rmt.SHOT / rmt.SPAN * k_, kt.BESIDE[0][1]).shape[1]
    row_w = av_w + gap + sum(full[(k, v)].shape[1] * k_ + 10 for k in keys for v, _ in views) + gap * len(keys)
    k_ *= min(1.0, (W - 2 * gap) / row_w)
    per = rmt.SHOT / rmt.SPAN * k_
    tiles = {key: rs.shrink(t, k_) for key, t in full.items()}
    tall = max(t.shape[0] for t in tiles.values())
    phone = {k: rs.trim(rs.shrink(np.load(layers / f"{k}_fight.npz")["px"], el.PHONE_H / he.H)) for k in keys}
    ph = max(p.shape[0] for p in phone.values()) * 3
    close_h, close_w = 330, 480   # wide enough for round 3's grips, out past her hips
    H = 70 + tall + 60 + 40 + ph + 50 + 40 + close_h * 2 + 90
    for beside in (True, False):
        page = rs.canvas(W, H, rs.rgb(paper))
        text = [(gap, 16, 20, "AR78: Kirra's blades at 2.8 studs, round 3's technique (bold and bolder) beside round 2's and today's, from behind and from "
                              "the game's camera, at the same pixels a stud" + (" as an Anime Vanguards unit (reference)." if beside
                                                                               else "."), ink)]
        rs.fill(page, 0, 56, W, tall + 14, rs.rgb(pale))
        x = gap
        if beside:
            av = rmt.reference(kt.BESIDE[0][0], per, kt.BESIDE[0][1])
            rs.paste(page, av, x, 56 + tall - av.shape[0])
            x += av.shape[1] + gap
        for k in keys:
            for v, said in views:
                t = tiles[(k, v)]
                rs.paste(page, t, x, 56 + tall - t.shape[0])
                text.append((x, 56 + tall + 22, 14, f"{SAID[k][0]}, {said}", soft))
                x += t.shape[1] + 10
            x += gap
        y = 56 + tall + 60
        text.append((gap, y, 18, "In the game's frame on the smallest phone: each at its own pixels, then three times them.", ink))
        x = gap
        for k in keys:
            p = phone[k]
            rs.paste(page, p, x, y + 40 + ph - p.shape[0])
            big = up(p, 3)
            rs.paste(page, big, x + p.shape[1] + 12, y + 40 + ph - big.shape[0])
            text.append((x, y + 40 + ph + 8, 14, SAID[k][0], soft))
            x += p.shape[1] + big.shape[1] + gap * 2
        y += 40 + ph + 50
        text.append((gap, y, 18, "Up close: from behind and from behind her left, at twice the size above.", ink))
        x = gap
        for k in keys:
            for row, v in enumerate(("back", "back34")):
                t = full[(k, v)]
                h, w = t.shape[:2]
                # her middle, from the waist to the shoulders: the carry's rows on the full shot
                mid_x, mid_y = w // 2, int(h * 0.42)
                crop = t[max(0, mid_y - close_h // 2): mid_y + close_h // 2, max(0, mid_x - close_w // 2): mid_x + close_w // 2]
                rs.paste(page, crop, x, y + 40 + row * (close_h + 8))
            for i, said in enumerate((f"{SAID[k][0]}:", *SAID[k][1])):
                text.append((x, y + 40 + 2 * (close_h + 8) + i * 18, 14, said, soft))
            x += close_w + gap
        rs.paste(page, rs.text_layer(W, H, text), 0, 0)
        rs.save(page, rmt.internal("kirra_blades_beside.png") if beside else (out / "kirra_blades.png").resolve())


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "takes"
    rmt.TAKES, rmt.SAID, rmt.WHO = TAKES, SAID, tuple(TAKES)
    rmt.VIEWS.update(back=(0, 6), back34=(326, 6))
    if mode == "takes":
        rmt.takes_run(OUT, rest[1:] or list(TAKES), finish=kt.measured)
    elif mode == "sheet":
        sheet_run(OUT)
