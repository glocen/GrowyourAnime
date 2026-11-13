"""Pip's Lantern Burst reworked, in its art: the coil (AR8, part B1; docs/asset-requests.md).

blender.exe -b --factory-startup --python tools/blender/pip_burst_coil_art.py -- <out_dir> [pictures]

The rework's blockout, H, picked by research with the feel line signed: "then the lantern's flame, let out, winds up
round the Shades twice his height and flies off upward". With research's fix (B1, its verdict): at 64 px H's coil broke
into hatching, so one mass and one focal point. The grey that answered it is pip_burst_rework.py's K: three fat ribbons,
two thirds of a turn each, that leave the area's edge and pull in fast to one twisting column, close to a point over
the target, flare there on 70 and climb away, gone by 93.

Drawn into the picture Lantern Burst already plays (pip_burst_art.py), so the build is one new upload: the same 15 stud
square standing on the ground under where the lantern stops, the same sixteen cells on the same frames (66 to 69 one a
frame, 70 to 93 two a frame; the last four in 128 cells), the heat's four cells as they were. The coil is drawn as seen
from the side, tipped TILT toward the camera, so the picture faces the camera from any heading; it's never laid flat
(the content check's condition 5: a three-armed whirl seen from above).

The look, to vfx-reference.md's rule 3: one mass, a bright interior with a darker, saturated edge. The three ribbons are
drawn as one body: one dark amber rim round the whole (EDGE: browner and yellower than #FF8A3D, never redder) in place
of the old ink, so it holds on the bright floor without the cut-out line, and where a nearer ribbon passes over a
farther only a thin seam of the flame's orange, so the twist shows inside the shape without cutting it into pieces.
One value ladder: each ribbon's foot is a run of orange along the floor, its column gold with a cream core, and the
flare where they meet is white at its middle, the top value for its two frames. Tongues lick up off every ribbon,
about one a stud, travelling up it from frame to frame; its head is a tongue pointing along its travel, and its foot
goes round, never to a point, as it lifts off: nothing hangs or points down (the check's condition 2). As it climbs
away it cools from cream to gold to orange and thins to a thread, its tongues tearing on upward, so the last of it is a
forked flicker, never an egg or a drop. The secondary, a breath after the peak, lower and softer: a small flame left
standing where each outer foot leaves the floor, dying down by thinning. It takes the place of the blockout's low wall
of light, which drawn into a picture that faces the camera read as a flat white ring on the floor from every view
(conditions 3 and 5).
Writes pip_burst.png (the coil's sixteen cells and the heat's four, 1024 x 896), pip_burst_trail.png (as it was), the
sheet pip_burst_coil_art.png beside the art as it plays and the grey K, and pip_burst_coil_art.json (what plays on every
frame: the table as before). With `pictures`, the pictures and a look at them. Workbench, so no GPU turn.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import pip_burst_art as pa  # noqa: E402  (the picture's layout, the stage, the table, the heat and the trail)
import pip_burst_fx as fx  # noqa: E402
import pip_burst_rework as rw  # noqa: E402  (the blockout: its K in grey, beside)
import rook_haymaker_fx as hx  # noqa: E402
import rook_sheet as rs  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
BEFORE = ROOT / "build" / "handoff" / "Pip" / "fx" / "pip_burst.png"  # the art as it plays, the "before"
CORE, GOLD, FLAME = (np.array(rs.rgb(c), dtype=np.float32) for c in (pa.CORE, pa.GOLD, pa.FLAME))
WHITE, EDGE = (np.array(rs.rgb(c), dtype=np.float32) for c in ("#FFFFFF", "#A85A1A"))
SPAN, K, AREA, LIFE = pa.SPAN, pa.K, rw.AREA, rw.LIFE
# K's coil (pip_burst_rework.column): ribbons, turns each, width at the foot and how much it narrows to the head, how
# fast they pull in off the area's edge
RIBBONS, TURNS, FAT, PULL = 3, 0.67, (2.7, 1.0), 3.5
BASE = 0.6                      # the first ribbon's angle at its foot, from the right, round toward the far side
TILT = math.radians(10.0)       # the picture's view, tipped down this much: the ring an ellipse, the coil from the side
LIFT = 0.95 * AREA * math.sin(TILT)  # so the near foot stands on the picture's bottom
SAMPLES, RIM = 44, 0.24         # points along a ribbon; studs of dark amber at the edge, about a pixel at 64 px
SEAM, JOIN = 0.14, 0.35         # the orange seam where one ribbon passes over another; the soft join that makes one mass
HEAD = 0.35                     # the share of a ribbon's length its head tapers to a point over: the top a flame's point
CLIMB = 0.82                    # how far up the coil its foot climbs by the last frame
# Every cell, by the frame it first shows (the Burst's 66 is t 0): the leap's four one a frame, then two a frame
CELLS_T = (0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26)
# The flare: on t, its size and how hot; its tongues, by angle, reach and width (shares of its size), uneven and up
FLARE = {3: (0.85, 0.6), 4: (1.7, 1.0), 6: (0.95, 0.3)}
TIPS = ((90, 1.7, 0.45), (64, 1.45, 0.4), (118, 1.5, 0.4), (38, 1.1, 0.34), (144, 1.0, 0.34), (14, 0.75, 0.28),
        (168, 0.7, 0.28))  # a fan, wider than tall: a bloom, not a bulb


def smooth(u):
    u = np.clip(u, 0.0, 1.0)
    return u * u * (3 - 2 * u)


def ends(t):
    """How far up the coil its head and its foot are on frame t: K's, but the foot climbs to CLIMB of the way, so what's
    left as it goes is a flame that thins to a thread, taller than wide to the last, never an egg or a drop."""
    return rw.grow(t, 5), CLIMB * (1 - (1 - hx.clamp((t - 5) / (LIFE - 5))) ** 1.7)


def thickness(t):
    """How thick the ribbons are on frame t, as a share: thinner as it climbs away, to a thread on the last frame."""
    return 1 - 0.92 * (1 - (1 - hx.clamp((t - 5) / (LIFE - 5))) ** 1.7)


def coil(t):
    """The ribbons on frame t after the Burst, each as its points seen in the picture: x across, y up, its depth (away
    from the camera), its half width, and s, how far up the coil (0 at the floor, 1 at the point)."""
    head, tail = ends(t)
    gone = hx.clamp((t - 5) / (LIFE - 5))  # 0 as it lets go of the floor, 1 on the last frame
    # the block's 11 to 13 studs, a little lower, so the flare and the last wisp stay inside the picture's square
    top, spin = 10.4 + 1.6 * tail, 1.8 * hx.out_fast(t / LIFE)
    out, lifted = [], float(smooth((tail - 0.02) / 0.15))
    for k in range(RIBBONS):
        s = np.linspace(tail, head, SAMPLES)
        u = (s - tail) / (head - tail)
        rho = 0.3 + (0.95 * AREA - 1.5) * (1 - s) ** PULL + 1.2 * (1 - s ** 2.5)
        # off the floor, its ends drawn in under it, a flame's round foot, and more as it goes: a thread, never a drop
        rho = rho * (1 - (0.35 + 0.55 * gone) * lifted * (1 - u) ** 2)
        rho = rho * (1 - 0.9 * smooth((u - 0.6) / 0.4))  # the three heads meet in one point: one tip, never a dome
        a = BASE + k * 2 * math.pi / RIBBONS + 2 * math.pi * TURNS * s * (1 - 0.35 * tail) + spin
        x, y, z = rho * np.cos(a), rho * np.sin(a), 0.2 + top * s
        # narrower where it leaves the floor, a run of flame rather than a log's end; its head a point
        r = (0.5 * (FAT[0] - FAT[1] * s) * thickness(t) * (0.6 + 0.4 * smooth(s / 0.15))
             * np.clip((1 - u) / HEAD, 0, 1) ** 0.75)
        out.append(dict(x=x, y=z * math.cos(TILT) + y * math.sin(TILT) + LIFT,
                        depth=y * math.cos(TILT) - z * math.sin(TILT), r=r, s=s))
    return out


def apex(t):
    """Where the ribbons meet, in the picture, on frame t: the flare's middle."""
    head, tail = ends(t)
    return np.array((0.0, (0.2 + (10.4 + 1.6 * tail) * head) * math.cos(TILT) + LIFT))


def pieces(ribbon):
    """A ribbon cut where it turns back across the picture, so no piece crosses itself: each is drawn whole, and the
    nearer one over the farther."""
    turn = np.sign(np.diff(ribbon["x"]))
    cuts = [0] + [i + 1 for i in range(len(turn) - 1) if turn[i] != turn[i + 1] and turn[i + 1] != 0] + [SAMPLES - 1]
    return [{key: value[a:b + 1] for key, value in ribbon.items()} for a, b in zip(cuts, cuts[1:]) if b > a]


def box(xs, ys, x0, x1, y0, y1):
    """The grid's rows and columns inside a box, as slices."""
    cols, rows = np.nonzero((xs >= x0) & (xs <= x1))[0], np.nonzero((ys >= y0) & (ys <= y1))[0]
    if not len(cols) or not len(rows):
        return None
    return slice(rows[0], rows[-1] + 1), slice(cols[0], cols[-1] + 1)


def field(X, Y, p):
    """A piece's distance field (studs, positive inside), and at each texel the nearest point's half width, height
    up the coil and depth."""
    D = np.full(X.shape, -1e3)
    R, S, Z = (np.zeros(X.shape) for _ in range(3))
    for i in range(len(p["x"]) - 1):
        ax, ay, bx, by = p["x"][i], p["y"][i], p["x"][i + 1], p["y"][i + 1]
        dx, dy = bx - ax, by - ay
        u = np.clip(((X - ax) * dx + (Y - ay) * dy) / max(dx * dx + dy * dy, 1e-9), 0, 1)
        r = p["r"][i] + (p["r"][i + 1] - p["r"][i]) * u
        d = r - np.hypot(X - (ax + u * dx), Y - (ay + u * dy))
        near = d > D
        D = np.where(near, d, D)
        R = np.where(near, r, R)
        S = np.where(near, p["s"][i] + (p["s"][i + 1] - p["s"][i]) * u, S)
        Z = np.where(near, p["depth"][i] + (p["depth"][i + 1] - p["depth"][i]) * u, Z)
    return D, R, S, Z


def licks(X, Y, p, t, k):
    """Tongues licking up off a piece, about one a stud along it, travelling up it from frame to frame and each a
    little out of step. Each roots on the piece's upper side (its outer side where it stands upright) and its tip goes
    up, leaning along the ribbon's way: never down."""
    x, y, r, s = p["x"], p["y"], p["r"], p["s"]
    run = np.concatenate([[0.0], np.cumsum(np.hypot(np.diff(x), np.diff(y)))])
    count, out = min(6, max(int(run[-1] > 0.5) * 2, int(run[-1] / 1.8))), []
    for j in range(count):
        i = int(np.clip(np.searchsorted(run, (j + 0.5 + (t / 6.0 + 0.3 * k) % 1.0) / (count + 1) * run[-1]), 1,
                        len(x) - 2))
        if r[i] < 0.08:  # down to the last thin frames, so even the smallest is forked like a flame, never a drop
            continue
        tx, ty = x[i + 1] - x[i - 1], y[i + 1] - y[i - 1]
        norm = math.hypot(tx, ty) + 1e-9
        nx, ny = -ty / norm, tx / norm
        if ny + 0.5 * math.copysign(1.0, x[i]) * nx < 0:  # the upper side, or the outer one where it stands upright
            nx, ny = -nx, -ny
        way = math.copysign(1.0, tx)
        wave = 0.5 + 0.5 * math.sin(2 * math.pi * (t / 5.0 + 0.37 * j + 0.23 * k))
        length = r[i] * (0.9 + 1.3 * wave) * (0.55 + 0.45 * float(smooth((s[i] - 0.05) / 0.35)))
        length *= 1 + 1.6 * hx.clamp((t - 12) / 14)  # as it climbs away its body thins and its tongues tear on upward
        ux, uy = 0.9 * nx + 0.25 * way, 1.0  # up, and out where the piece stands upright: off its flanks
        reach = (length + 0.5 * r[i]) / math.hypot(ux, uy)
        root = (x[i] + 0.5 * r[i] * nx, y[i] + 0.5 * r[i] * ny)
        tip = (root[0] + ux * reach, root[1] + uy * reach)
        out.append(pa.lick(X, Y, pa.s_curve(root, tip, 0.2 * way * r[i]), 0.7 * r[i], p=1.15, n=28))
    return out


def belly(X, Y, ribbons):
    """Once the coil lets go of the floor: one round belly under it where the ribbons' ends are, so it goes up as one
    flame with a round bottom, never three lobes and never a point down. As a piece: its field, its half height as
    its width, its height up the coil (the coolest) and its depth (the middle)."""
    tail = float(ribbons[0]["s"][0])
    grown = float(smooth((tail - 0.02) / 0.15))
    if grown <= 0:
        return None
    feet = np.array([(ribbon["x"][0], ribbon["y"][0]) for ribbon in ribbons])
    r0 = float(ribbons[0]["r"][0])
    rx = grown * (0.85 * (feet[:, 0].max() - feet[:, 0].min()) / 2 + 0.9 * r0)
    ry = grown * (0.9 * r0 + 0.2)
    D = pa.belly(X, Y, feet[:, 0].mean(), feet[:, 1].min() + 0.3 * ry, rx, ry)
    return D, np.full(X.shape, ry), np.full(X.shape, tail), np.zeros(X.shape)


def tones(D, R, S, Z, cool):
    """Hard bands by how deep a texel is in its ribbon, hotter up the coil and nearer the camera, cooling as it climbs
    away: cream, gold, the flame orange."""
    heat = smooth((S - 0.04) / 0.4) * (1 - 0.25 * np.clip(Z / 2.0, 0, 1)) * (1 - 0.95 * cool)
    q = D / np.maximum(R, 0.15)
    return np.where((q > 0.66 + 0.5 * (1 - heat))[..., None], CORE,
                    np.where((q > 0.3 + 0.4 * (1 - heat))[..., None], GOLD, FLAME))


def body(X, Y, t):
    """The coil as one mass: its colour and where it's drawn. Each piece's field with its tongues; the nearest piece
    gives a texel its tone, a soft join of all of them its outline, the rim round that alone, and a seam of orange
    where a nearer piece's edge lies over a farther one."""
    xs, ys = X[0], Y[:, 0]
    ribbons = coil(t)
    fields = [b for b in [belly(X, Y, ribbons) if ribbons else None] if b is not None]
    for k, ribbon in enumerate(ribbons):
        for p in pieces(ribbon):
            pad = float(p["r"].max()) * 2.8 + 0.6 + JOIN
            where = box(xs, ys, p["x"].min() - pad, p["x"].max() + pad, p["y"].min() - pad, p["y"].max() + pad)
            if where is None:
                continue
            D, R, S, Z = (np.full(X.shape, v) for v in (-1e3, 1.0, 0.0, np.inf))
            d, R[where], S[where], Z[where] = field(X[where], Y[where], p)
            more = licks(X[where], Y[where], p, t, k)
            D[where] = pa.union([d] + more, 0.22) if more else d
            fields.append((D, R, S, Z))
    if not fields:
        return None, None
    D, R, S, Z = (np.stack(f) for f in zip(*fields))
    mass = pa.union(list(D), JOIN * thickness(t))  # the join no wider than the ribbons, or three threads swell to a blob
    near = np.where(D > 0, Z, np.inf)
    win = np.where(np.isfinite(near.min(axis=0)), near.argmin(axis=0), D.argmax(axis=0))[None]
    d, r, s, z = (np.take_along_axis(A, win, axis=0)[0] for A in (D, R, S, Z))
    colour = tones(d, r, s, z, hx.clamp((t - 10) / 12))
    colour = np.where(((d < SEAM) & (mass >= RIM))[..., None], FLAME, colour)
    # a gap closed in by the ribbons is part of the body, in the seam's orange; the rim is only round the outside
    outside = spread(mass <= 0, None)
    rim = (mass < RIM) & spread(outside, int(RIM * X.shape[1] / SPAN) + 1)
    return np.where(rim[..., None], EDGE, colour), ~outside


def spread(where, steps):
    """`where` grown a texel at a time into its four neighbours: `steps` times, or with None, through the empty
    texels from the square's border until it stops: everything outside the shape."""
    if steps is None:
        out, room = np.zeros_like(where), where
        out[0], out[-1], out[:, 0], out[:, -1] = room[0], room[-1], room[:, 0], room[:, -1]
    else:
        out, room = where.copy(), np.ones_like(where)
    for _ in range(steps or 10 ** 6):
        grown = out.copy()
        grown[1:] |= out[:-1]
        grown[:-1] |= out[1:]
        grown[:, 1:] |= out[:, :-1]
        grown[:, :-1] |= out[:, 1:]
        grown &= room
        if steps is None and (grown == out).all():
            break
        out = grown
    return out


def ground(X, Y, t, near):
    """The secondary, a breath after the peak, lower and softer: where each ribbon's foot leaves the floor at the
    area's edge, a small flame is left standing that dies down, shrinking and lifting a little as it goes. Gold and
    orange, never the cream. In place of the blockout's low wall of light, which as a picture facing the camera reads
    as a flat ring on the floor (the content check's conditions 3 and 5). The far ones, or the near ones."""
    a = t - 5
    if not 0 <= a <= 8:
        return None, None
    # it goes out by thinning and lifting, its height held longer than its width, and forking: its side tongues
    # spread and stand up as it thins, so its last frames are two or three tips, never one round-bottomed drop
    size, fields = 1 - 0.55 * a / 8, []
    thin, fork = 1 - 0.75 * (a / 8) ** 1.3, float(smooth((a - 1) / 5))
    for k in range(RIBBONS):
        angle = BASE + k * 2 * math.pi / RIBBONS + 1.8 * hx.out_fast(5 / LIFE)  # where the foot was as it let go
        x = 0.95 * AREA * math.cos(angle)
        # one under the coil as it lifts would read as a drop hanging from it: only those out past its sides
        if (math.sin(angle) < 0) != near or abs(x) < 2.6:
            continue
        y = 0.95 * AREA * math.sin(angle) * math.sin(TILT) + LIFT + 0.8 * a / 8
        h = (3.2 - 0.45 * k) * size * (1 + 0.15 * math.sin(1.3 * t + 2 * k))
        w = thin * (1 - 0.15 * k)
        side, lean = 0.35 * w + 0.22 * fork, 0.35 * w + 0.3 * fork
        fields += [pa.belly(X, Y, x, y, 0.7 * w + 0.2 * fork, 0.35 * w),
                   pa.lick(X, Y, pa.s_curve((x, y), (x + 0.3 * w, y + h), 0.2 * w), 0.5 * w + 0.08 * fork, p=1.1,
                           n=28),
                   pa.lick(X, Y, pa.s_curve((x - side, y), (x - side - lean, y + (0.6 + 0.08 * fork) * h), -0.15 * w),
                           0.36 * w + 0.06 * fork, p=1.1, n=24),
                   pa.lick(X, Y, pa.s_curve((x + side, y), (x + side + lean, y + (0.45 + 0.1 * fork) * h), 0.15 * w),
                           0.3 * w + 0.06 * fork, p=1.1, n=24)]
    if not fields:
        return None, None
    D = pa.union(fields, 0.15)
    colour = np.where((D > 0.35 * thin)[..., None], GOLD, FLAME)
    return np.where((D < RIM * min(1.0, 1.4 * thin))[..., None], EDGE, colour), D > 0


def flare(X, Y, at, t):
    """Where the ribbons meet over the target, on 70: a burst of flame at the top value, white in its middle, its
    tongues uneven, up and out, never down."""
    if t not in FLARE:
        return None, None
    size, hot = FLARE[t]
    fields = [pa.belly(X, Y, at[0], at[1] - 0.1 * size, 1.35 * size, 0.6 * size)]
    for j, (angle, reach, width) in enumerate(TIPS):
        th = math.radians(angle + 7 * math.sin(1.7 * t + 2 * j))
        root = (at[0] + 0.35 * size * math.cos(th), at[1] + 0.35 * size * math.sin(th))
        tip = (at[0] + size * reach * math.cos(th), at[1] + size * reach * math.sin(th))
        fields.append(pa.lick(X, Y, pa.s_curve(root, tip, 0.15 * size * (-1) ** j), width * size, p=1.1, n=28))
    D = pa.union(fields, 0.22)
    q = D / size
    if hot > 0.5:
        colour = np.where((q > 0.42)[..., None], WHITE, np.where((q > 0.18)[..., None], CORE, GOLD))
    else:
        colour = np.where((q > 0.5)[..., None], CORE, np.where((q > 0.22)[..., None], GOLD, FLAME))
    return np.where((D < 0.7 * RIM)[..., None], EDGE, colour), D > 0


def bleed(frame):
    """An empty texel takes the colour of the drawn ones beside it, so the engine's filtering pulls no other colour
    into the edge: the rim's amber round the flame, the flare's colour round its tongues."""
    colour, known = frame[..., :3], frame[..., 3] > 1e-6
    for _ in range(3):
        total, count = np.zeros_like(colour), np.zeros(known.shape, dtype=np.float32)
        for shift in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            near = np.roll(known, shift, axis=(0, 1))
            total += np.where(near[..., None], np.roll(colour, shift, axis=(0, 1)), 0)
            count += near
        fill = ~known & (count > 0)
        colour[fill] = total[fill] / count[fill][:, None]
        known = known | fill
    colour[~known] = EDGE
    return frame


def cell(t, px):
    """One cell of the coil, frame t after the Burst, px square, back to front: the far ground flames, the coil, the
    near ground flames, the flare."""
    X, Y = pa.grid((px, px), (SPAN, SPAN))
    colour = np.empty(X.shape + (3,), dtype=np.float32)
    colour[:] = EDGE
    alpha = np.zeros(X.shape, dtype=np.float32)
    for lit, inside in (ground(X, Y, t, False), body(X, Y, t), ground(X, Y, t, True), flare(X, Y, apex(t), t)):
        if lit is not None:
            colour[:] = np.where(inside[..., None], lit, colour)
            alpha = np.where(inside, 1.0, alpha)
    frame = rs.shrink(np.concatenate([colour, alpha[..., None]], axis=-1).astype(np.float32), 1 / K)
    edge = np.concatenate([frame[:2, :, 3].ravel(), frame[:, :2, 3].ravel(), frame[:, -2:, 3].ravel()])
    if edge.max() > 0.01:  # anything cut by the square's top or sides shows as a straight edge in the game
        print(f"WARNING: the cell at t {t} is cut at the square's edge (alpha {edge.max():.2f})")
    return bleed(frame)


def frames():
    """The picture's twenty cells: the coil's sixteen, in pip_burst_art's places, and the heat's four as they were."""
    out = [cell(t, pa.rect(n)[2]) for n, t in enumerate(CELLS_T)]
    for n in pa.HEAT:  # pip_burst_art.flame_frames, for the heat's cells alone
        s = pa.FRAMES[n]
        X, Y = pa.grid(pa.rect(n)[2:], (SPAN, SPAN))
        settings = {key: value for key, value in s.items() if key not in pa.PLACED}
        d = pa.shape(X, Y, **settings)
        inner = [pa.shape(X, Y, **layer) if layer["thin"] > 0.02 else -np.ones_like(X) for layer in pa.nested(s)]
        out.append(pa.finish(pa.tones(d, Y, 0.0, 0.0, inner, 1.0), d > 0))
    return out


def glance(sheet, path):
    """The picture on the night, a bright ground and in grey, full size."""
    W, H = 3 * 1050 + 40, 1000
    page = rs.canvas(W, H, rs.PAPER)
    for i, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, 10 + i * 1055, 10, 1044, 980, ground)
        rs.paste(page, rs.grey(sheet) if grey else sheet, 20 + i * 1055, 20)
    rs.save(page, path)


# --- the sheet: the stage of pip_burst_art, with the "before" and the grey K beside ---------------------------------

def use(stage, material):
    """Draw the burst from another picture: the art as it plays, or the coil."""
    stage.sheet_material = material
    for obj in stage.quads:
        obj.data.materials[0] = material


SHEET = (51, 60, 64, 66, 67, 68, 69, 70, 72, 74, 76, 78, 80, 84, 88, 92)  # the player's camera, four rows of four
ROW = (66, 67, 69, 70, 72, 76, 80, 86)                                      # the other views
SMALL = (60, 66, 67, 68, 69, 70, 72, 74, 76, 80, 84, 90)                    # at 64 px
PEAK = (67, 69, 70, 72, 76, 80, 86)                                         # the share of the screen


def main():
    out = bl.out_dir()
    rs.OUT = out
    sheet, trail = pa.atlas(frames()), pa.trail_frame()
    rs.save(sheet, out / "pip_burst.png")
    rs.save(trail, out / "pip_burst_trail.png")
    if "pictures" in sys.argv[sys.argv.index("--") + 1:]:
        glance(sheet, out / "pip_burst_coil_glance.png")
        return

    # the grey K beside it: the blockout's stage, as pip_burst_rework runs it
    fx.VARIANTS, fx.layout, fx.size_of = rw.VARIANTS, rw.layout, rw.size_of
    fx.Stage.make, fx.Stage.__init__ = rw.make, rw.init
    scene, rig, costume, undress, feet, ctl, motors = fx.pc.build()
    count = fx.key(rig)
    print(f"LanternBurst: {count} frames, the markers at {fx.MARKS}")
    stage = pa.Stage(scene, rig, count, sheet, trail)
    stage.variant = "K"
    coil_material = stage.sheet_material
    before_material = pa.ha.picture("Fx.Before", rs.load(BEFORE))
    cams = {}
    for name in ("fight", "fight50", "beside", "hidden"):  # behind the avatar, looking at its head (the game's camera)
        look, spot = fx.staged(name)
        azimuth = math.degrees(math.atan2(-look.x, -look.y))
        cams[name] = hx.camera(scene, name, azimuth, fx.PITCH, fx.EYE / math.cos(math.radians(fx.PITCH)),
                               (spot.x, spot.y, 4.5), 50.0 if name == "fight50" else 70.0)
    cams["side"] = hx.camera(scene, "side", 90.0, 6.0, 34.0, (0.3, 7.0, 4.5), 36.0)
    bpy.data.objects["Floor"].scale *= 4
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk, bright = tuple(floor.diffuse_color), (0.74, 0.72, 0.68, 1)
    r = scene.render
    r.use_stamp_date = r.use_stamp_render_time = r.use_stamp_camera = r.use_stamp_lens = False
    r.use_stamp_scene = r.use_stamp_filename = r.use_stamp_frame = r.use_stamp_time = False
    r.use_stamp_note, r.stamp_font_size = True, 18

    def shoot(camera, f, label, size, mode="art"):
        return pa.shoot(scene, stage, cams[camera], f, label, size, out, mode)

    big, row, tiny = (456, 256), (228, 128), (75, 64)
    area = big[0] * big[1]
    game = [shoot("fight", f, pa.label(f), big) for f in SHEET]
    rows = {view: [shoot(view, f, pa.label(f), row)[0] for f in ROW] for view in ("beside", "hidden", "side")}
    small = {"block": [shoot("fight50", f, "", tiny, "block") for f in SMALL],
             "dark": [shoot("fight50", f, "", tiny) for f in SMALL]}
    peak = {f: shoot("fight", f, "", big)[1] for f in PEAK}
    use(stage, before_material)
    rows["before"] = [shoot("fight", f, pa.label(f), row)[0] for f in ROW]
    small["before"] = [shoot("fight50", f, "", tiny) for f in SMALL]
    peak_before = {f: shoot("fight", f, "", big)[1] for f in PEAK}
    use(stage, coil_material)
    floor.diffuse_color = bright
    rows["bright"] = [shoot("fight", f, pa.label(f), row)[0] for f in ROW]
    small["bright"] = [shoot("fight50", f, "", tiny) for f in SMALL]
    use(stage, before_material)
    rows["before, bright"] = [shoot("fight", f, pa.label(f), row)[0] for f in ROW]
    use(stage, coil_material)
    floor.diffuse_color = dusk
    bpy.app.handlers.frame_change_pre.remove(stage.set)

    numbers = pa.table(stage)
    numbers["burst"]["cells"] = ("0 to 3, one a frame from the Burst: the ribbons leave the area's edge and wind up; "
                                 "4: the flare where they meet, on 70 and 71; 5 to 7: the coil standing, spinning; "
                                 "8 to 15: it lets go of the floor and climbs away, cooling, to a wisp. Played straight "
                                 "through: BoilPlays 1")
    numbers["checks"] = {
        "share_at_peak": {str(f): {"before": round(peak_before[f] / area, 4), "art": round(peak[f] / area, 4)}
                          for f in PEAK},
        "pixels_at_64": {key: dict(zip(map(str, SMALL), (t[1] for t in tiles))) for key, tiles in small.items()},
        "camera": f"the player's: behind the avatar, {fx.EYE} studs, {fx.PITCH} degrees down, 70 degrees, {big[0]} x {big[1]}"}
    (out / "pip_burst_coil_art.json").write_text(json.dumps(numbers, indent=1))
    print(json.dumps(numbers["checks"], indent=1))

    W, H = 1920, 3060
    page = rs.canvas(W, H, rs.PAPER)
    ink, soft = "#1E1B22", "#6A655E"
    x0 = 40
    text = [(x0, 30, 54, "PIP'S LANTERN BURST, THE COIL", ink),
            (900, 30, 20, "The rework's H, with research's fix: one mass and one focal point. Three fat ribbons leave the", ink),
            (900, 54, 20, "area's edge, pull in to one twisting column, flare white where they meet on 70, and climb away.", ink)]
    y = 104
    text.append((x0, y, 20, "pip_burst.png, 1024 x 896, one upload in the old one's places: the coil's sixteen cells (the last four in 128 cells), then the heat's four as they were", ink))
    shrunk = rs.shrink(sheet, 0.5)
    for i, (ground, grey) in enumerate(((rs.NIGHT, False), (rs.DAY, False), (rs.rgb("#77777B"), True))):
        rs.fill(page, x0 + i * 600, y + 30, 532, 468, ground)
        rs.paste(page, rs.grey(shrunk) if grey else shrunk, x0 + 10 + i * 600, y + 40)
    for i, words in enumerate((
            f"One a frame from the Burst ({pa.FIRST} to {pa.FIRST + 3}): the ribbons leave the area's edge and wind in. Cell 4, on 70 and 71: the flare where they meet, white at its middle. "
            "Then two frames each: the coil standing and spinning (72 to 77),",
            f"then letting go of the floor and climbing away, cooling from cream to gold to orange, to a wisp ({pa.FIRST + 12} to {pa.LAST}). Pip's cream, gold and orange inside, "
            "a dark amber rim (#A85A1A, never redder than #FF8A3D); the secondary, a small flame left where each outer foot lets go.")):
        text.append((x0, y + 510 + i * 20, 15, words, soft))
    y = 680
    text.append((x0, y, 20, f"From the player's camera: behind the avatar, Pip 33 degrees off his front and 30 studs away (the clip's frames, 60 a second; Burst is {pa.FIRST})", ink))
    for n, (tile, _, _) in enumerate(game):
        rs.paste(page, tile, x0 + (n % 4) * 466, y + 28 + (n // 4) * 266)
    y = 1780
    for title, key in (("Before: the art as it plays, the same frames", "before"), ("On a bright floor", "bright"),
                       ("Before, on the bright floor", "before, bright"),
                       ("Beside: the camera looking across the fight", "beside"),
                       ("Hidden: the avatar facing its target dead on", "hidden"), ("From the side", "side")):
        text.append((x0, y, 18, title, ink))
        for c, tile in enumerate(rows[key]):
            rs.paste(page, tile, x0 + c * 232, y + 24)
        y += 160
    y += 10
    text.append((x0, y, 18, "At 64 px from the player's camera: before, the grey K, then the coil on dark and on bright, and in grey. Under each, the effect's pixels", ink))
    for i, key in enumerate(("before", "block", "dark", "bright")):
        for c, (tile, n, _) in enumerate(small[key]):
            rs.paste(page, tile, x0 + c * 80, y + 26 + i * 86)
            text.append((x0 + c * 80 + 2, y + 26 + i * 86 + 66, 12, f"{SMALL[c]}: {n}", soft))
        text.append((x0 + 12 * 80 + 8, y + 50 + i * 86, 14, ("before, as it plays", "the grey K", "the coil, dark",
                                                              "the coil, bright")[i], soft))
    for c, (tile, _, _) in enumerate(small["dark"]):
        rs.paste(page, rs.grey(tile), x0 + 1240 + (c % 6) * 80, y + 26 + (c // 6) * 86)
    y += 376
    peaks = ", ".join(f"{f}: {peak_before[f] / area:.1%} to {peak[f] / area:.1%}" for f in PEAK)
    for i, words in enumerate((f"The burst's share of the player's screen, before to the coil: {peaks}.",
                               "The heat, the trail and the glow are as they were (AR4, section 8). The pictures are drawn flat and unlit, facing the camera, with no glow added: the game's bloom is the builder's.")):
        text.append((x0, y + i * 24, 16, words, soft))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / "pip_burst_coil_art.png")
    print(f"wrote {out / 'pip_burst_coil_art.png'} {W}x{H}")


if __name__ == "__main__":
    main()
