"""AR75's Shades, round 2: research picked none of round 1 (2026-11-28, 01:37). Each read as a person in a costume on
an R6 block, where Jujutsu Infinite's enemies are a non-human mass, and today's Brawler beat two of them on menace. The
cause is the concept, so the technique changes: built pieces that make a Void creature.

Every take starts from round 1's B, the hooded dark mass with the lit mask inside (shade_redo_takes.take_b):
- The body is a deep slate-teal, off red, black and army green, so it stands dark against the pale street. Nothing
  is violet.
- The type's colour (Red, the Brawler's, from Config.Shades) is in one place: the paint on the mask's brow. The coat's
  red edges are gone.
- The Void shows at phone size as cracks lit cyan in the coat, the sleeves and the built pieces.

Each take adds one built piece that changes the outline:

    Hem, the fraying hem: a robe from the waist flares past the knees and frays into nine tongues of smoke that trail
       back, their edge lit by the Void. Below it, the legs are smoke.
    Hunch, the hunched mass: a mantle stands over his shoulders and rises over his head, leaning forward. The lit mask
       looks out of its mouth, the mouth is rimmed in the Void's light, and the inside glows faintly. The mantle's
       lower edge frays and is lit, cracks run down it, and the smoke hands come out below.
    Horns, the mask grown into horns: two horns grow from the mask's brow through the hood, sweeping up, out and
       back. They are the mask's bone at the root, darkening to the Void's slate at the tips, with cracks lit at the
       roots.

No gore: the Void is light and smoke, never a drip. Nothing falls from the mask's mouth.

    blender.exe -b --factory-startup --python tools/blender/shade_void_takes.py -- <out_dir> takes [Pip Hem Hunch Horns]
    blender.exe -b --factory-startup --python tools/blender/shade_void_takes.py -- <out_dir> rook|shade|sheet

The sheet is shade_redo_takes.sheet_run's, on these takes:
- each take from the front and from the game's camera;
- the head from six sides;
- each fighting Pip, then Rook, on the deck;
- each as a pack in Lantern Row's street by day;
- the line-up, and each at 64 px.
It is written to <out_dir>/shade_void_takes.png. The internal sheet, beside Jujutsu Infinite's frames, goes to
build/reference/takes/shade_void_beside.png.
"""
import math
import sys
from pathlib import Path

import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import pip_make as pm  # noqa: E402
import pip_make_takes as pt  # noqa: E402
import pip_redo_takes as pr  # noqa: E402
import rook_make_takes as rt  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_redo_takes as sr  # noqa: E402
import watt_takes as wt  # noqa: E402
from anime_make import cel, mix, rgb, tone  # noqa: E402
from rook_make_takes import band, blocks_of, grain, line, lit, neck, shadow  # noqa: E402
from shade_redo_takes import VOID, VOID_CORE, brawler_mask, lights, tint, void_hands  # noqa: E402

# the slate-teal mass, darkest inside
COAT, LINING, TROUSER, SMOKE, DEEP = "#274853", "#183039", "#1E3740", "#11232A", "#0B171C"
HOOD = ("#18303A", "#3A5F6B")          # the hood's root and its lit top
PLATE = "#EFE8DA"                     # the mask's bone
GLOW = dict(sr.GLOW, Robe=1.7, Mantle=1.7, Horns=1.6)


# --- the body every take shares: round 1's B, slate-teal, cracked ------------------------------------------------------

def crack(p, start, heading, length, wide, seed, forks=1):
    """A crack the Void shows through: a zigzag from `start` along `heading` (degrees, 0 up the face, 90 toward +x),
    `wide` at its root narrowing to nothing, with `forks` branches off it. Each step leans off the heading, never
    wanders: it reads as a break, not a vein."""
    rng = np.random.default_rng(seed)

    def walk(x, y, heading, length, wide, forks):
        steps = max(3, int(length / 0.1))
        pts = [(x, y)]
        for _ in range(steps):
            a = math.radians(heading) + rng.uniform(-0.75, 0.75)
            x, y = x + 0.1 * math.sin(a), y + 0.1 * math.cos(a)
            pts.append((x, y))
        for i in range(steps):
            w0, w1 = wide * (1 - i / steps) + 0.008, wide * (1 - (i + 1) / steps) + 0.008
            p.lay(p.stroke([pts[i], pts[i + 1]], (w0, w1), n=4), VOID)
        for _ in range(forks):
            k = int(rng.integers(1, steps - 1))
            walk(*pts[k], heading + rng.choice([-1, 1]) * rng.uniform(40, 70), length * 0.45, wide * (1 - k / steps) * 0.8, 0)

    walk(*start, heading, length, wide, forks)


def body(tails=True, seed=500, mark=False, clump=True):
    """B's hooded coat in the slate-teal, cracked by the Void: blocks, head with the mask, and the hood. `mark`: the
    type's colour as one small mark in the middle of the brow, in place of the two strokes over the eyes, where horns
    grow from the brow (the content check, 2026-11-28: red at a horn's root reads as a wound)."""
    hem = 0.9   # on the legs: where the coat's tails end
    b = blocks_of({"torso": COAT, "rs": COAT, "ls": COAT, "rh": TROUSER, "lh": TROUSER})

    t = b["torso"]
    w, f, back = t.wrap, t.faces["front"], t.faces["back"]
    f.lay(f.poly([(-0.08, 2.0), (0.12, 2.0), (0.16, 0.0), (-0.12, 0.0)]), LINING)
    for x0, x1 in ((-0.08, -0.12), (0.12, 0.16)):
        line(f, [(x0, 2.0), (x1, 0.0)], 0.03, tone(COAT, 1.4), 1.0)
    for s in (-1, 1):
        cel(f, [(s * 0.92, 1.94), (s * 0.72, 1.46), (s * 0.58, 0.94)], 0.22, COAT)
        cel(f, [(s * 0.4, 0.68), (s * 0.48, 0.36), (s * 0.52, 0.04)], 0.16, COAT)
        cel(back, [(s * 0.94, 1.9), (s * 0.74, 1.36), (s * 0.6, 0.7)], 0.22, COAT)
    band(w, 0.7, 0.84, LINING, tone(LINING, 0.55))
    f.lay(f.rect(-0.12, 0.7, 0.16, 0.84), LINING)
    back.lay(back.rect(-0.5, 1.84, 0.5, 2.0), LINING)
    # the Void through the coat: from the chest's opening out across the breast, and a great break across the back
    crack(f, (0.2, 1.42), 60, 0.62, 0.07, seed)
    crack(f, (-0.12, 1.1), -110, 0.5, 0.06, seed + 1, forks=0)
    crack(back, (0.0, 1.3), -50, 0.8, 0.09, seed + 2, forks=2)
    crack(back, (0.06, 1.24), 125, 0.6, 0.07, seed + 3)
    lights(t, VOID)
    shadow(t, 0.3)
    lit(t)
    grain(t, seed=seed + 10)
    neck(t, DEEP)

    for i, key in enumerate(("rs", "ls")):
        a = b[key]
        aw = a.wrap
        band(aw, 0.36, 0.5, LINING, None)
        am.cel_sides(a, am.SLEEVE_CEL, COAT)
        crack(a.faces["right" if key == "rs" else "left"], (0.05, 1.7), 170, 0.7, 0.06, seed + 20 + i, forks=1)
        lights(a, VOID)
        void_hands(a, SMOKE, 0.36)
        shadow(a, 0.3, low=0.0)
        lit(a)
        a.faces["top"].px[:] = rgb(COAT)
        grain(a, seed=seed + 12 + i)
    pr.tops(b, COAT)

    for i, (key, s) in enumerate((("rh", -1), ("lh", 1))):
        g = b[key]
        gw, gf = g.wrap, g.faces["front"]
        if tails:   # the coat's tails to the knee, round the sides and back
            gw.lay(gw.rect(-9, hem, 9, 2.0), COAT)
            gf.lay(gf.poly([(s * 0.5, 2.0), (-s * 0.5, 2.0), (-s * 0.5, hem), (s * 0.5, hem)]), TROUSER)
            gf.lay(gf.poly([(s * 0.5, 2.0), (s * 0.28, 2.0), (s * 0.34, hem), (s * 0.5, hem)]), COAT)
            line(gf, [(s * 0.28, 2.0), (s * 0.34, hem)], 0.03, tone(COAT, 1.4), 1.0)
            am.cel_sides(g, {"out": [([(0.38, 1.9), (0.22, 1.4), (0.14, 1.0)], 0.16)],
                             "back": [([(0.36, 1.88), (0.2, 1.4), (0.1, 1.0)], 0.16)]}, COAT)
            gw.lay(gw.rect(-9, hem - 0.03, 9, hem + 0.03), LINING)
            cel(gf, [(-s * 0.3, 0.86), (-s * 0.1, 0.6), (-s * 0.04, 0.4)], 0.12, TROUSER)
            band(gw, 0.0, 0.42, SMOKE, tone(SMOKE, 0.6))
        else:       # under the robe the legs are smoke, darker to the feet
            for p in g.sides:
                p.lay(p.rise(1.4, 0.0) ** 0.8, SMOKE, 0.95)
        g.faces["bottom"].px[:] = rgb(SMOKE)
        shadow(g, 0.26, low=0.0)
        lit(g, 0.1)
        grain(g, seed=seed + 14 + i)

    head = am.Head(DEEP)
    glow = brawler_mask(head.paint, PLATE, None if mark else tint(), tone(DEEP, 0.6))
    if mark:   # a lozenge between the brows: bone all round it, well clear of both roots (at 0.36 either side)
        head.paint.lay(head.paint.poly([(0.0, 1.07), (0.055, 0.99), (0.0, 0.91), (-0.055, 0.99)]), tint())
    hood = am.Hair(*HOOD, seed=307, band=(0.5, 0.12, 0.12), scalp=am.HEAD_EGG)
    hood.mass(am.hairline(front=5.08, temple=4.3, nape=3.86), (180, 34), opening=0.0, seed=307, grooves=5,   # closed: no dot at the crown
              tips=((180, 26, 16),), lift=0.1, off=(0.06, 0.16), ease=1.4, tuck=0.06)
    if clump:   # the hood's tail behind: under Hunch's mantle it pokes through, so that take has none
        hood.clump(180, 46, 0.62, 0.5, heading=0, off=0.12, flick=10, hold=0.7, comb=(0, -1.0, -0.6), thick=0.12)
    return b, head, hood, glow


def figure(joints, folder, b, head, hood, glow, built=()):
    """The blocks, head and hood (rook_make_takes.figure), each built piece on its joint, the hood cast on the head,
    and every glowing piece lit by its own map."""
    made = rt.figure(joints, folder, b, head, hood)
    for piece, joint in built:
        made[piece.name] = piece.build(folder)
        wt.on(joints, joint, made[piece.name])
    pm.hair_shadow(made, "#081012", alpha=0.7)
    am.GLOWS[made["head"].name] = glow
    for key, obj in made.items():
        mask = am.GLOWS.get(obj.name)
        if mask is None or GLOW.get(key, 1.2) <= 0 or float(mask.max()) <= 0:
            continue
        path = folder / f"{key}_glow.png"
        rs.save(np.dstack([mask, mask, mask, np.ones_like(mask)]), path)
        pm.emit(obj.active_material, path, GLOW.get(key, 1.2))
    return made


# --- the built pieces ----------------------------------------------------------------------------------------------------

class VoidBuilt(pm.LitBuilt):
    """A built piece of the Void creature. Its `sheet` is cloth with a thickness, closed at every edge, so the game
    draws its inside too. A colour given as (colour, k) glows at k."""

    def paint(self, c):
        if isinstance(c, tuple):
            return self.lit(c[0], c[1])
        return c

    def sheet(self, outer, inner, colour, wrap=False):
        """`outer` and `inner`: grids of places, rows from the top down, columns round. `colour(part, i, j)` for
        the part "out", "in", "top", "hem" or "side" (the open edges of a sheet that isn't wrapped)."""
        O = [[self.bm.verts.new(v) for v in row] for row in outer]
        I_ = [[self.bm.verts.new(v) for v in row] for row in inner]
        rows, cols = len(O), len(O[0])
        span = range(cols) if wrap else range(cols - 1)
        for i in range(rows - 1):
            for j in span:
                j2 = (j + 1) % cols
                self.face((O[i][j], O[i][j2], O[i + 1][j2], O[i + 1][j]), self.paint(colour("out", i, j)))
                self.face((I_[i][j], I_[i + 1][j], I_[i + 1][j2], I_[i][j2]), self.paint(colour("in", i, j)))
        for i, part in ((0, "top"), (rows - 1, "hem")):
            for j in span:
                j2 = (j + 1) % cols
                self.face((O[i][j], I_[i][j], I_[i][j2], O[i][j2]), self.paint(colour(part, i, j)), smooth=False)
        if not wrap:
            for j in (0, cols - 1):
                for i in range(rows - 1):
                    self.face((O[i][j], O[i + 1][j], I_[i + 1][j], I_[i][j]), self.paint(colour("side", i, j)), smooth=False)


def superellipse(a, b, n, th):
    """The point at `th` (radians from the front, +y, round to his right, +x) on |x/a|^n + |y/b|^n = 1."""
    s, c = math.sin(th), math.cos(th)
    r = (abs(s / a) ** n + abs(c / b) ** n) ** (-1 / n)
    return r * s, r * c


def tongue(th, count, phase=0.0, sharp=1.6):
    """1 at a tongue's tip, 0 between two."""
    return (0.5 + 0.5 * math.cos(count * th + phase)) ** sharp


def edge_band(t, start):
    """Where a row stands in the lit edge: 0 above `start`, rising to 1 at the hem."""
    return 0.0 if t < start else (t - start) / (1 - start)


def ridge_tone(c, ridge, lo=0.78, hi=1.08):
    return tone(c, lo + (hi - lo) * ridge)


def surface_crack(v, at, a0, b0, steps, seed, da=0.6, db=0.012, wide=0.075):
    """A crack on a built piece's surface: a thin ribbon lit by the Void lying just outside it, zigzagging down.
    `at(a, b, inset)` is the surface's place (`a` down it, `b` across); it starts at (a0, b0) and takes `steps`
    steps of `da` down, each leaning off by up to `db` across."""
    rng = np.random.default_rng(seed)
    a, b, spine = a0, b0, []
    for _ in range(steps + 1):
        spine.append(at(a, b, -0.014))
        a, b = a + da, b + float(rng.choice([-1, 1])) * rng.uniform(0.4, 1.0) * db
    side = Vector(at(a0, b0 + 0.002, -0.014)) - Vector(spine[0])
    widths = [wide * (1 - i / (steps + 1)) + 0.012 for i in range(steps + 1)]
    v.ribbon(spine, widths, VOID, side=tuple(side.normalized()), thick=0.016, under=1.0, edge=1.0)


ROBE_T = (0.0, 0.16, 0.32, 0.46, 0.58, 0.68, 0.76, 0.83, 0.89, 0.945, 1.0)
ROBE_TONGUES, ROBE_COLS = 9, 54
ROBE_LONG = (1.0, 0.7, 1.3, 0.85, 1.15, 0.72, 1.35, 0.9, 1.05)   # each tongue's own length: smoke is never even


def robe():
    """The fraying hem: from under the belt, closing round the torso's foot, flaring past the knees, and fraying
    into ROBE_TONGUES tongues of smoke. The tongues trail back and turn out at their tips, and the Void lights the
    last of them: half-lit, then fully lit at the edge. It rides the root."""
    v = VoidBuilt("Robe")
    z_top, z_low = 2.3, 0.62

    def place(t, th, inset):
        a = 1.1 + 0.52 * t ** 1.4 - inset
        b = 0.6 + 0.56 * t ** 1.4 - inset
        x, y = superellipse(a, b, 6.0 - 3.4 * t, th)
        fray = t ** 3
        turn = th + 0.3 * fray                      # the tongues twist as they fall, as smoke does
        tip = tongue(turn, ROBE_TONGUES, 0.4)
        long_ = ROBE_LONG[round((turn * ROBE_TONGUES + 0.4) / (2 * math.pi)) % ROBE_TONGUES]
        z = z_top + (z_low - z_top) * t + fray * (0.42 * (1 - tip) - 0.36 * tip * long_)
        out = 1 + 0.14 * tip * fray * long_
        return (x * out, y * out - 0.3 * t ** 2 - 0.2 * tip * fray * long_, z)

    cols = [j / ROBE_COLS * 2 * math.pi for j in range(ROBE_COLS)]
    outer = [[place(t, th, 0.0) for th in cols] for t in ROBE_T]
    inner = [[place(t, th, 0.07) for th in cols] for t in ROBE_T]

    def colour(part, i, j):
        th = (j + 0.5) / ROBE_COLS * 2 * math.pi
        t = (ROBE_T[i] + ROBE_T[min(i + 1, len(ROBE_T) - 1)]) / 2
        ridge = tongue(th, ROBE_TONGUES, 0.4, 1.0)
        if part == "hem":
            return (VOID, 1.0)
        if part == "top":
            return COAT
        if part == "in":
            lit_ = edge_band(t, 0.7)
            return (mix(DEEP, VOID, round(0.3 * lit_, 2)), round(0.4 * lit_, 2)) if lit_ > 0 else DEEP
        if i >= len(ROBE_T) - 2:
            return (VOID, 1.0)
        if i == len(ROBE_T) - 3:
            return (mix(SMOKE, VOID, 0.45), 0.45)
        c = ridge_tone(COAT, round(ridge * 4) / 4)
        return mix(c, SMOKE, round(min(1.0, max(0.0, (t - 0.5) / 0.35)) * 4) / 4)

    v.sheet(outer, inner, colour, wrap=True)
    v.lit(VOID, 1.0)
    for k, (th0, seed) in enumerate(((0.5, 1), (2.2, 2), (3.4, 3), (4.4, 4), (5.6, 5))):
        surface_crack(v, lambda a, b, inset: place(a, b, inset), 0.84, th0, 5, 810 + seed, da=-0.1, db=0.09)
    return v


MANTLE_ROWS, MANTLE_COLS, MANTLE_TONGUES = 16, 52, 13


def mantle(seed=600):
    """The hunched mass: a mantle over the shoulders that rises over the head and leans forward. It is a thick
    shell of an egg behind the head, open at the front from the brow down, so the lit mask looks out of its mouth.
    - The mouth's edges are lit by the Void, and its inside glows faintly.
    - Its lower edge hangs lower at the back and frays into MANTLE_TONGUES tongues, half-lit, then lit.
    - Cracks run down it, lit.
    It rides the root."""
    v = VoidBuilt("Mantle")
    centre, radii, lean = Vector((0.0, -0.22, 3.75)), (2.35, 1.32, 1.9), Matrix.Rotation(math.radians(-18), 3, "X")
    # (its back stands clear of the hood: at y -0.1 and 1.25 deep, the lean brought it into the hood's crown)

    def place(r, u, inset):
        t = r / (MANTLE_ROWS - 1)
        mouth = 0.6 * min(1.0, max(0.0, (t - MOUTH_T) / 0.24)) ** 0.55  # the opening's half-angle: a round arch from the brow,
                                                                         # closed over the head (no slit up to the crown)
        th = mouth + u * (2 * math.pi - 2 * mouth)
        back = 0.5 - 0.5 * math.cos(th)
        tip = tongue(th, MANTLE_TONGUES)
        phi_low = 1.95 + 0.35 * back + 0.3 * tip * min(1.0, back * 3)
        phi = 0.015 + (phi_low - 0.015) * t   # its top ring a pinpoint: no hole at the crown
        rx, ry, rz = (q - inset for q in radii)
        # the back rises higher, a hump, not a ball; all of the crown's ring at one height, or the crown is a slit
        hump = 1 + 0.22 * max(0.0, math.cos(phi)) ** 2 * (0.5 + (back - 0.5) * min(1.0, phi / 0.5))
        p = Vector((rx * math.sin(phi) * math.sin(th), ry * math.sin(phi) * math.cos(th), rz * math.cos(phi) * hump))
        return tuple(centre + lean @ p)

    us = [j / (MANTLE_COLS - 1) for j in range(MANTLE_COLS)]
    outer = [[place(r, u, 0.0) for u in us] for r in range(MANTLE_ROWS)]
    inner = [[place(r, u, 0.08) for u in us] for r in range(MANTLE_ROWS)]

    def colour(part, i, j):
        u = (j + 0.5) / (MANTLE_COLS - 1)
        t = (i + 0.5) / (MANTLE_ROWS - 1)
        mouth = min(u, 1 - u) < 0.06 and t > MOUTH_T
        if part in ("hem", "side"):
            return (VOID, 1.0) if part == "hem" or t > MOUTH_T else COAT
        if part == "top":
            return COAT
        if part == "in":
            return (mix(DEEP, VOID, 0.22), 0.4) if mouth else DEEP
        if i >= MANTLE_ROWS - 2:
            return (VOID, 1.0)
        if i == MANTLE_ROWS - 3:
            return (mix(SMOKE, VOID, 0.45), 0.45)
        th = u * 2 * math.pi
        c = ridge_tone(COAT, round(tongue(th, MANTLE_TONGUES, 0.0, 1.0) * 4) / 4, 0.82, 1.06)
        return mix(c, SMOKE, round(min(1.0, max(0.0, (t - 0.55) / 0.3)) * 4) / 4)

    v.sheet(outer, inner, colour)
    v.lit(VOID, 1.0)
    for k, u0 in enumerate((0.12, 0.27, 0.42, 0.58, 0.73, 0.88)):
        surface_crack(v, lambda a, b, inset: place(a, b, inset), 3.0 + k % 3, u0, 9, seed + k, da=0.9, db=0.016)
    return v


MOUTH_T = 0.19   # where the mantle's mouth opens, down from its crown (0 to 1)
HORN_RINGS, HORN_SIDES = 18, 8


def horns():
    """The mask grown into horns: two from the mask's brow, through the hood, sweeping up, out and back. Each is
    the mask's bone at the root, ridged, darkening to the slate at its tip, with cracks lit in its root. They ride
    the neck."""
    v = VoidBuilt("Horns")
    v.lit(VOID, 1.0)
    bone_dark = tone(COAT, 0.55)
    for s in (-1, 1):
        ctrl = [Vector(q) for q in ((s * 0.3, 0.5, 4.86), (s * 0.58, 0.66, 5.28), (s * 0.98, 0.36, 5.8), (s * 1.12, -0.24, 6.12))]
        pts = []
        for i in range(HORN_RINGS):
            t = i / (HORN_RINGS - 1)
            pts.append(ctrl[0] * (1 - t) ** 3 + ctrl[1] * 3 * t * (1 - t) ** 2 + ctrl[2] * 3 * t ** 2 * (1 - t) + ctrl[3] * t ** 3)
        rings, side = [], Vector((s, 0, 0))
        for i, q in enumerate(pts):
            t = i / (HORN_RINGS - 1)
            d = (pts[min(i + 1, HORN_RINGS - 1)] - pts[max(i - 1, 0)]).normalized()
            side = (side - d * side.dot(d)).normalized()
            up = d.cross(side).normalized()
            r = 0.17 * (1 - t) ** 0.85 + 0.01
            rings.append([q + (side * math.cos(a) + up * math.sin(a)) * r
                          for a in np.linspace(0, 2 * math.pi, HORN_SIDES, endpoint=False)])
        def colour(i, k):
            t = (i + 0.5) / (HORN_RINGS - 1)
            dark_ = min(1.0, max(0.0, (t - 0.3) / 0.6)) ** 1.2
            c = mix(PLATE, bone_dark, round(dark_ * 8) / 8)
            return tone(c, (0.9 if i % 3 == 2 else 1.0) * (0.84 if k in (3, 4, 5) else 1.0))

        v.tube(rings, colour, caps=(PLATE, bone_dark))
        # the cracks: two thin lit ribbons up the horn's root, on its front and its outer side, each just outside it
        frames = [(q, rings[i]) for i, q in enumerate(pts)]
        for start, seed in ((1.2, 1), (3.6, 2)):
            rng = np.random.default_rng(700 + seed + (s > 0) * 10)
            a, spine, sides = start, [], []
            for i in range(1, 8):
                q, ring = frames[i]
                k = a % HORN_SIDES
                k0, f = int(k), k - int(k)
                on = Vector(ring[k0]).lerp(Vector(ring[(k0 + 1) % HORN_SIDES]), f)
                out = (on - q).normalized()
                spine.append(tuple(q + out * ((on - q).length + 0.012)))
                sides.append(Vector(ring[(k0 + 1) % HORN_SIDES]) - Vector(ring[k0]))
                a += float(rng.choice([-1, 1])) * rng.uniform(0.3, 0.7)
            widths = [0.05 * (1 - i / len(spine)) + 0.01 for i in range(len(spine))]
            v.ribbon(spine, widths, VOID, side=tuple(sides[0].normalized()), thick=0.012, under=1.0, edge=1.0)
    return v


# --- the takes ---------------------------------------------------------------------------------------------------------

def take_hem(joints, folder):
    b, head, hood, glow = body(tails=False, seed=500)
    return figure(joints, folder, b, head, hood, glow, built=((robe(), "root"),))


def take_hunch(joints, folder):
    b, head, hood, glow = body(seed=520, clump=False)
    return figure(joints, folder, b, head, hood, glow, built=((mantle(), "root"),))


def take_horns(joints, folder):
    b, head, hood, glow = body(seed=540, mark=True)
    return figure(joints, folder, b, head, hood, glow, built=((horns(), "neck"),))


TAKES = {"Pip": pr.finish_c, "Hem": take_hem, "Hunch": take_hunch, "Horns": take_horns}
SAID = {
    "Hem": ("Hem, the fraying hem", ("B's hood and lit mask, slate-teal", "a robe flaring past the knees,",
                                     "fraying into smoke, its edge lit", "cracks lit in the coat")),
    "Hunch": ("Hunch, the hunched mass", ("a mantle over the shoulders, rising", "over the head and leaning forward:",
                                          "the mask looks out of its lit mouth", "its edge frays, lit; cracks run down it")),
    "Horns": ("Horns, the mask grown into horns", ("two horns from the mask's brow,", "through the hood, up and back:",
                                                   "bone at the root, slate at the tip", "the type's mark between the horns")),
}


def settle():
    """Round 2's names and words into shade_redo_takes' sheet, and the takes into rook_make_takes' runner."""
    sr.SAID.update(SAID)
    sr.SAID["Pip"] = ("Pip (C, the finish)", ())
    sr.WHO = ("Hem", "Hunch", "Horns")
    sr.FOES = ("Shade",) + sr.WHO
    sr.ROW = ("Rook", "Pip", "Shade") + sr.WHO
    sr.ROW_SAID = "Rook, Pip, today's Brawler, Hem, Hunch, Horns"
    sr.STEM, sr.BESIDE = "shade_void_takes", "shade_void_beside.png"
    sr.TITLE = "AR75: THE SHADES AS VOID CREATURES, ROUND 2, THREE TAKES"
    sr.ABOUT = ("From round 1's B, the hooded dark mass with the lit mask inside, made a Void creature with a built piece "
                "each (research, 2026-11-28, 01:37): a hem fraying into smoke, a hunched mass, a mask grown into horns. The "
                "body is a deep slate-teal, off red, black and army green, and dark against the pale street. The Void shows as "
                "cracks and edges lit cyan. The type's colour (Red, the Brawler's) is in one place, the paint on the mask's brow (Horns: one mark between them). "
                "Research picks one; the Guard's, the Dasher's and the Support's follow the pick.")
    rt.TAKES, rt.SAID, rt.WHO = TAKES, sr.SAID, tuple(TAKES)
    rt.spots = sr.spots


if __name__ == "__main__":
    settle()
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    mode = rest[0] if rest else "sheet"
    if mode == "takes":
        rt.takes_run(OUT, rest[1:] or list(TAKES), finish=pt.measured)
    elif mode == "rook":
        rt.rook_run(OUT)
    elif mode == "shade":
        rt.shade_run(OUT)
    elif mode == "sheet":
        sr.sheet_run(OUT)
