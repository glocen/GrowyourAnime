"""AR19: the generator's three directions for Stage I, and how each grows (docs/asset-requests.md, AR19).

blender.exe -b --factory-startup --python tools/blender/generator_directions.py -- <out_dir> [fast | small | A]

`small` makes only the content check's sheet (generator_64.png) from the views already rendered in <out_dir>.

Blocks in the base kit's own swatches (base_kit.SWATCHES), set in the yard as it stands (base_plan.Yard, today's
generator taken out) and seen from the game's camera:
  - from the spawn, at the start zoom and pitch;
  - from behind a player 30 studs before the machine, the camera turned up to it;
  - from the side, 12 studs before it and 14 across.
Each direction's Stages II and III are seen from the near view. B and C are also seen at low and high generation,
since their gauge is the machine itself. It writes each view, a sheet a direction (generator_A.png, _B, _C) and the
three side by side (generator_glance.png). Stage I stands about 30 studs tall, over today's 26.

  A, the Void Mill   A wheel facing the gate turns down into the well's dark. Its band of buckets comes up lit on
                     the gate's right and gives its light to a collector's shoe high on that side. The lit arc's
                     height is the generation, read against a bone mark on a rail outside the rim for the demand.
                     (Research's pick, with its three fixes: `A` renders only A, as generator_A_fixes.png.)
  B, the Beam Pump   A walking beam rocks on the head of a hooped column, and its two pumps lift the well's light into
                     the column. The column's lit height is the generation, and a collar marks the demand.
  C, the Governor    A spindle over a vaned turbine flings three flat weights out and up as the plant generates. A
                     yellow ring on the frame's legs marks the demand: the weights fly over it when there's power
                     to spare.

The frame is the kit's: a piece's front (+Y) toward the gate, its origin on the floor at the well's middle, one unit a
stud. Violet comes in and yellow goes out. The content check of 2026-11-16 holds:
  - the violet is light, never a surface that could be read as a liquid;
  - spokes and arms are straight and radial;
  - B's column is straight with even hoops;
  - C's weights are flat eight-sided plates under an angular head held by the frame, never a capped shaft standing
    free, and its frame's legs splay out and meet in stays at the head, never two posts and a crossbar;
  - no growth becomes a tall tapering tower with a lit crown.
"""

import math
import sys
import textwrap
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_kit as base  # noqa: E402
import base_machines as bm  # noqa: E402
from base_mill import (FACING, UP, Mesh, at, along, bar, cable, disc, floor_disc, mill, motes, put, ring_up, rod,  # noqa: E402,F401
                       turned)
import base_plan as plan  # noqa: E402
import blcommon as bl  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

GX, GI = base.GENERATOR


# --- B's and C's shapes (the mill's, and those the three share, are base_mill.py's) ----------------------------------

def plinth(m, r, high=0.5, band=True):
    """The machine's round concrete plinth over the well, the yard's yellow band round its edge."""
    put(m, turned([(r, high), (r, 0.0)], 32, "concrete"), at(0, 0, 0))
    if band:
        ring_up(m, (0, 0, high - 0.12), r - 0.05, r + 0.08, 0.24, "yellow", sides=32, ink=False)


def dial(m, centre, r, gen, demand, needles=1):
    """A round gauge facing the gate: a bone rim, a dark face, a scale of ticks over 220°, the generation's needle in
    the current's yellow (a second, shorter one from Stage II), and the demand's notch in bone on the rim. No
    lettering."""
    c = Vector(centre)
    face = Mesh()
    face.lathe([(r, 0.2), (r, -0.2)], (0, 0, 0), 24, "dark")
    put(m, face, Matrix.Translation(c) @ FACING)
    rim = Mesh()
    bm.hoop(rim, (0, 0, 0), r, r * 1.17, 0.55, 24, "bone", lying=True)
    put(m, rim, Matrix.Translation(c) @ FACING)
    span, start = math.radians(220.0), math.radians(200.0)
    for k in range(9):
        a = start - span * k / 8
        p = c + Vector((math.cos(a), 0.0, math.sin(a))) * (r * 0.85) + Vector((0, 0.24, 0))
        m.box((r * 0.19, 0.1, r * 0.06), p, "bone", rot=(0.0, -a, 0.0))
    for n in range(needles):
        a = start - span * min(1.0, gen * (1.0 - 0.18 * n))
        length = r * (0.9 - 0.25 * n)
        p = c + Vector((math.cos(a), 0.0, math.sin(a))) * (length / 2) + Vector((0, 0.3 + 0.05 * n, 0))
        m.box((length, 0.12, r * (0.09 - 0.025 * n)), p, "power", rot=(0.0, -a, 0.0))
    a = start - span * demand
    p = c + Vector((math.cos(a), 0.0, math.sin(a))) * (r * 1.2) + Vector((0, 0.1, 0))
    m.box((r * 0.33, 0.5, r * 0.17), p, "bone", rot=(0.0, -a, 0.0), ink=True)
    disc(m, c + Vector((0, 0.32, 0)), r * 0.15, 0.16, "steel", ink=False)


A_FIXES = (
    "Research's pick with its three fixes (AR19, research's verdict, 15:04). 1. The gauge is the machine: the "
    "buckets light as they leave the well on the gate's right, and the lit arc's height up the rim is the "
    "generation, from the well to the collector's shoe; a bone diamond on a steel rail outside the rim is the "
    "demand, a lit pip in its face so it holds at dusk. The arc past the mark means power to spare. The dial is gone. 2. Heavy, not a portal: a concrete sill across "
    "the well carries a trestle and the front bearing, the axle running from the hub into it; the collector is an "
    "arm clamped on that bearing, out across the wheel's face to its copper shoe; the band is 3 deep and 4 wide, the "
    "hub filled and bolted, and the rim lit only on the rising side. 3. Each stage tells from the gate: Stage II "
    "puts a spur gear on the axle and its pinion driving a housed dynamo on the sill, in front; Stage III adds the "
    "casing, the crown of rods and a second dynamo. The wheel is 23 studs across (24 from Stage II), its top 22 up.",
    "For the builder: the wheel turns about the line to the gate as its own piece; the lit arc is a glow piece that "
    "stays still while the buckets turn through it, cut in steps so its top follows the generation, and the bone "
    "mark slides along the rail with the demand. The gears turn with the wheel, the pinions the other way.",
)


# --- B, the Beam Pump --------------------------------------------------------------------------------------------------

def column(m, x, y, r, z0, z1, fill, demand, ticks=True, steps=7):
    """A straight column in even steel hoops: the void's light up to its lit height, dark above, four tie rods, the
    demand's bone collar clamped on it."""
    lit = z0 + (z1 - z0) * fill
    put(m, turned([(r, lit), (r, z0)], 14, "void", ink=False), at(x, y, 0))
    put(m, turned([(r, z1), (r, lit)], 14, "dark", ink=False), at(x, y, 0))
    hull = turned([(r, z1), (r, z0)], 14, "dark")
    for face in hull.ink.f:
        m.ink.face([Vector(hull.ink.v[i]) + Vector((x, y, 0)) for i in face], [(0, 0)] * len(face))
    for k in range(steps + 1):
        ring_up(m, (x, y, z0 + (z1 - z0) * k / steps), r - 0.05, r + 0.45, 0.6, "steel")
    for k in range(4):
        a = math.radians(45 + 90 * k)
        foot = (x + (r + 0.55) * math.cos(a), y + (r + 0.55) * math.sin(a))
        bar(m, (*foot, z0 - 0.4), (*foot, z1 + 0.4), 0.42, "girder")
    if ticks:
        step = (z1 - z0) / steps
        for k in range(steps):
            m.box((0.7, 0.14, 0.18), (x, y + r + 0.22, z0 + step * (k + 0.5)), "bone")
    put(m, turned([(r + 1.0, z0), (r + 1.0, z0 - 1.2)], 14, "bone"), at(x, y, 0))
    put(m, turned([(r * 0.6, z1 + 1.4), (r + 0.6, z1 + 0.6), (r + 0.6, z1)], 14, "steel"), at(x, y, 0))
    zd = z0 + (z1 - z0) * demand
    ring_up(m, (x, y, zd), r + 0.4, r + 1.1, 0.7, "bone")
    m.box((0.9, 1.1, 0.7), (x, y + r + 1.35, zd), "bone", ink=True)


def pump_cylinder(m, x, y, rod_top, high=8.0, r=1.5):
    m.box((3.4, 3.4, 0.6), (x, y, 0.3), "concrete", ink=True)
    put(m, turned([(r, high), (r, 0.6)], 12, "steel"), at(x, y, 0))
    for z in (2.4, high - 1.6):
        ring_up(m, (x, y, z), r - 0.05, r + 0.3, 0.45, "steel")
    ring_up(m, (x, y, high), r * 0.7, r + 0.45, 0.5, "bone")
    put(m, turned([(0.65, high + 0.9), (0.65, high)], 8, "bone"), at(x, y, 0))
    rod(m, (x, y, high + 0.9), rod_top, 0.38, "girder")
    m.box((1.2, 1.2, 1.2), rod_top, "steel", ink=True)


def pipe(m, a, b, r=0.5):
    """A steel pipe at the floor, the void's light along its top."""
    rod(m, a, b, r, "steel")
    a, b = Vector(a), Vector(b)
    m.box(((b - a).length * 0.8, 0.24, 0.14), (a + b) / 2 + Vector((0, 0, r + 0.06)), "void", rot=(0, 0, math.atan2(b.y - a.y, b.x - a.x)))


def beam(m, pivot, half, t):
    """The walking beam, deeper at its middle, tilted by `t` about the pivot's line (Y). Its two ends."""
    rot = (0.0, t, 0.0)
    m.box((2 * half, 1.2, 1.3), pivot, "girder", rot=rot, ink=True)
    m.box((half * 1.1, 1.3, 2.6), pivot, "girder", rot=rot, ink=True)
    m.box((half * 0.5, 1.4, 3.4), pivot, "steel", rot=rot, ink=True)
    ends = [pivot + Vector((sx * half * math.cos(t), 0.0, -sx * half * math.sin(t))) for sx in (-1, 1)]
    for e in ends:
        m.box((1.4, 1.6, 2.4), e, "bone", rot=rot, ink=True)
    return ends


def pump(stage, gen=0.55, demand=0.45, tilt=6.0):
    m = Mesh()
    t = math.radians(tilt)
    plinth(m, 6.2 if stage < 3 else 7.0)
    if stage == 1:
        cols = [(0.0, 0.0, 2.2)]
    elif stage == 2:
        cols = [(-2.9, 0.0, 1.8), (2.9, 0.0, 1.8)]
    else:
        cols = [(sx * 2.7, sy * 2.7, 1.5) for sx in (-1, 1) for sy in (-1, 1)]
    z0, z1 = (1.8, 21.6) if stage < 3 else (4.0, 22.4)
    for x, y, r in cols:
        column(m, x, y, r, z0, z1, gen, demand, ticks=stage < 3 or y > 0)
    if stage < 3:
        # the beam's bearing sits on the column's head (a bridge over both heads from Stage II), and two stays brace
        # the head from behind
        span = 3.4 if stage == 1 else 9.4
        m.box((span, 3.4, 1.6), (0, 0, z1 + 1.9), "steel", ink=True)
        pivot = Vector((0, 0, z1 + 4.0))
        for sy in (-1, 1):
            m.box((1.6, 0.9, 2.6), (0, sy * 1.25, z1 + 3.4), "bone", ink=True)
        rod(m, (0, -1.9, pivot.z), (0, 1.9, pivot.z), 0.55, "bone")
        for sx in (-1, 1):
            bar(m, (sx * (span / 2 + 2.2), -9.0, 0.5), (sx * (span / 2 - 0.6), -1.4, z1 + 1.2), 0.9, "girder")
            m.box((2.2, 2.2, 0.5), (sx * (span / 2 + 2.2), -9.0, 0.25), "concrete", ink=True)
        half = 11.4 if stage == 1 else 12.6
        ends = beam(m, pivot, half, t)
        pump_cylinder(m, ends[0].x, 0.0, ends[0] - Vector((0, 0, 1.6)))
        pipe(m, (ends[0].x + 1.6, 0.0, 1.5), (cols[0][0] - cols[0][2] - 1.0, 0.0, 1.5))
        if stage == 1:
            pump_cylinder(m, ends[1].x, 0.0, ends[1] - Vector((0, 0, 1.6)))
            pipe(m, (ends[1].x - 1.6, 0.0, 1.5), (cols[0][2] + 1.0, 0.0, 1.5))
        else:
            # the crank: a rod from the beam's right end down to a flywheel beside it, facing the gate
            fx, fz = ends[1].x + 2.4, 7.0
            wheel = Mesh()
            bm.hoop(wheel, (0, 0, 0), 4.0, 5.0, 1.1, 28, "steel", lying=True)
            for k in range(6):
                a = math.tau * (k + 0.5) / 6
                wheel.box((3.4, 0.6, 0.6), Vector((math.cos(a), math.sin(a), 0)) * 2.4, "girder", rot=(0, 0, a), ink=True)
            put(wheel, turned([(1.1, 0.9), (1.1, -0.9)], 10, "bone"), Matrix.Identity(4))
            put(m, wheel, at(fx, 1.4, fz) @ FACING)
            pin = Vector((fx + 3.0 * math.cos(1.1), 2.3, fz + 3.0 * math.sin(1.1)))
            bar(m, pin, ends[1] + Vector((0, 1.1, -1.0)), 0.55, "steel")
            m.box((2.8, 3.2, fz), (fx, -0.8, fz / 2), "steel", ink=True)
            rod(m, (fx, -2.4, fz), (fx, 1.4, fz), 0.6, "girder")
            for sx in (-1, 1):                                                      # the stays plated
                bar(m, (sx * (span / 2 + 1.9), -8.0, 0.8), (sx * (span / 2 - 0.3), -2.2, 12.0), 2.2, "steel", d=0.4)
            m.box((5.6, 1.4, 3.0), (0, 7.2, 1.5), "steel", ink=True)                # the cabinet of gauges
            for k, g in enumerate((gen, demand, gen * 0.8)):
                dial(m, (-1.8 + 1.8 * k, 7.95, 1.8), 0.65, g, demand)
            pipe(m, (-1.2, 0.0, 1.5), (1.2, 0.0, 1.5))
        # the current out: from insulators on the bearing block's back corners, down the stays and away on the floor
        for sx in (-1, 1):
            bm.insulator(m, (sx * (span / 2 - 0.5), -1.3, z1 + 2.7), 1.1)
            cable(m, [(sx * (span / 2 - 0.5), -1.3, z1 + 4.0), (sx * (span / 2 - 0.1), -2.2, z1 + 0.6),
                      (sx * (span / 2 + 1.6), -9.2, 1.0), (sx * (span / 2 + 2.6), -17.8, 0.2)], r=0.28)
    else:
        # the crown cam: a turning plate over the four columns, and four pumps in a ring pushing up on its rim
        put(m, turned([(4.8, 4.0), (5.2, 0.5)], 16, "steel"), at(0, 0, 0))
        ring_up(m, (0, 0, 3.6), 4.9, 5.25, 0.36, "yellow", ink=False)
        put(m, turned([(1.1, 24.2), (1.1, 4.0)], 8, "girder"), at(0, 0, 0))
        put(m, turned([(10.4, 25.4), (10.4, 24.2)], 32, "steel"), at(0, 0, 0))     # a wide cam, not a lit crown
        ring_up(m, (0, 0, 24.8), 10.4, 10.8, 0.6, "copper", sides=32)
        m.box((3.6, 3.6, 1.6), (0, 0, 26.4), "steel", ink=True)
        for k in range(4):
            a = math.radians(45 + 90 * k)
            c, s = math.cos(a), math.sin(a)
            pump_cylinder(m, 10.0 * c, 10.0 * s, Vector((10.0 * c, 10.0 * s, 23.6)), high=9.0, r=1.7)   # straight up
            pipe(m, (8.3 * c, 8.3 * s, 1.5), (5.2 * c, 5.2 * s, 1.5))
            b = math.radians(90 * k)
            bar(m, (6.4 * math.cos(b), 6.4 * math.sin(b), 0.5), (6.4 * math.cos(b), 6.4 * math.sin(b), 24.2), 1.2, "girder")
            m.box((2.4, 2.4, 0.6), (6.4 * math.cos(b), 6.4 * math.sin(b), 0.3), "concrete", ink=True)
            bm.insulator(m, (2.6 * c, 2.6 * s, 25.4), 1.1)
        for sx in (-1, 1):
            cable(m, [(sx * 1.84, -1.84, 26.7), (sx * 11.0, -1.0, 26.0), (sx * 11.4, -1.3, 0.7), (sx * 11.8, -17.8, 0.2)], r=0.28)
    return m


# --- C, the Governor ---------------------------------------------------------------------------------------------------

def theta_of(gen):
    return math.radians(30.0 + 44.0 * gen)


def collar_at(hinge, arm, theta):
    """The sliding collar's height for arms at `theta`: links from it reach each arm's middle."""
    half = arm / 2
    across = 0.1 + half * math.sin(theta)
    return hinge - half * math.cos(theta) - math.sqrt(max(half * half - across * across, 0.0))


def governor(stage, gen=0.55, demand=0.4):
    m = Mesh()
    plinth(m, 8.0 if stage == 1 else 9.0)
    if stage < 3:
        hr = 6.4 if stage == 1 else 7.6
        put(m, turned([(3.8, 5.8), (hr, 4.3), (hr, 0.5)], 18, "steel"), at(0, 0, 0))
        ring_up(m, (0, 0, 4.3), hr - 0.1, hr + 0.4, 0.5, "steel")
        slots = 14 if stage == 1 else 18
        for k in range(slots):                                                      # the vanes, the swirl lit behind them
            a = math.tau * k / slots
            n = Vector((math.cos(a), math.sin(a), 0.0))
            m.box((0.14, 0.9, 2.8), n * (hr + 0.02) + Vector((0, 0, 2.4)), "void", rot=(0, 0, a))
            m.box((0.5, 0.42, 3.3), n * (hr + 0.16) + Vector((0, 0, 2.4)), "girder", rot=(0, 0, a + math.tau / slots / 2))
        if stage == 2:
            ring_up(m, (0, 0, 1.2), hr - 0.1, hr + 0.4, 0.6, "steel")
            for k in range(8):
                a = math.tau * (k + 0.5) / 8
                m.box((1.1, 0.6, 0.6), Vector((math.cos(a), math.sin(a), 0)) * (hr + 0.4) + Vector((0, 0, 4.3)), "bone", rot=(0, 0, a))
        top = 5.8
    else:
        put(m, turned([(5.4, 5.4), (8.8, 3.8), (8.8, 0.5)], 8, "steel"), at(0, 0, 0))
        for k in range(8):                                                          # the slots in its faces, lit
            a = math.tau * (k + 0.5) / 8
            n = Vector((math.cos(a), math.sin(a), 0.0))
            m.box((0.12, 2.2, 2.6), n * 8.15 + Vector((0, 0, 2.2)), "void", rot=(0, 0, a))
        top = 5.4
    put(m, turned([(1.6, top + 1.0), (1.85, top)], 6, "steel"), at(0, 0, 0))
    head = 27.4 if stage == 1 else 28.4
    rod(m, (0, 0, top + 1.0), (0, 0, head - 1.1), 0.55, "girder")
    # the head: an angular bearing block where the legs' stays meet, a flat stack of copper rings under it
    m.box((3.8, 3.8, 2.2), (0, 0, head), "steel", ink=True)
    m.box((2.6, 2.6, 0.6), (0, 0, head + 1.4), "girder", ink=True)
    rings = 3 if stage == 1 else 5
    for k in range(rings):
        put(m, turned([(1.25, head - 1.5 - 0.7 * k), (1.25, head - 1.9 - 0.7 * k)], 12, "copper"), at(0, 0, 0))
        if stage == 3:
            put(m, turned([(0.9, head - 1.9 - 0.7 * k), (0.9, head - 2.2 - 0.7 * k)], 12, "power", ink=False), at(0, 0, 0))
    # the frame: legs splayed at the foot, rising clear of the weights' sweep to a knee, then stays up to the head
    posts = [math.radians(a) for a in ((30, 150, 270) if stage == 1 else (45, 135, 225, 315))]
    foot, knee, knee_z = (13.6, 11.4, 21.4) if stage == 1 else (14.6, 12.2, 22.2)
    for a in posts:
        c, s = math.cos(a), math.sin(a)
        bar(m, (foot * c, foot * s, 0.5), (knee * c, knee * s, knee_z), 1.3, "girder")
        m.box((3.0, 3.0, 0.6), (foot * c, foot * s, 0.3), "concrete", ink=True)
        m.box((1.9, 1.9, 1.6), (knee * c, knee * s, knee_z), "steel", ink=True)
        bar(m, (knee * c, knee * s, knee_z + 0.3), (1.8 * c, 1.8 * s, head), 1.2, "girder", d=1.0)
        m.box((0.6, 0.6, 1.1), (1.55 * c, 1.55 * s, head - 1.6), "copper", ink=True)    # a brush on the rings
        if stage > 1:                                                               # the legs plated low
            bar(m, (foot * c, foot * s, 0.8), (((foot + knee) / 2) * c, ((foot + knee) / 2) * s, knee_z / 2), 2.0, "steel", d=0.5)
    if stage == 3:                                                                  # the back pair braced
        a0, a1 = posts[2], posts[3]
        lo = lambda a, f: Vector(((foot + (knee - foot) * f) * math.cos(a), (foot + (knee - foot) * f) * math.sin(a), 0.5 + (knee_z - 0.5) * f))  # noqa: E731
        bar(m, lo(a0, 0.1), lo(a1, 0.9), 0.6, "girder")
        bar(m, lo(a1, 0.1), lo(a0, 0.9), 0.6, "girder")
    # the flyweights: arms from the hinge collar, flat steel discs at their ends facing out, links down to the
    # sliding collar. The front weight faces the gate, so at rest no two round shapes flank the spindle.
    tiers = [(21.6, 8.0, 2.2, 3, 90.0)] if stage == 1 else [(22.2, 8.2, 2.3, 4, 0.0)] if stage == 2 else \
        [(23.4, 6.0, 1.7, 4, 45.0), (18.2, 8.0, 2.3, 4, 0.0)]
    theta = theta_of(gen)
    for hinge, arm, wr, count, offset in tiers:
        put(m, turned([(1.2, hinge + 0.6), (1.2, hinge - 0.6)], 8, "steel"), at(0, 0, 0))
        lift = collar_at(hinge, arm, theta)
        put(m, turned([(1.35, lift + 0.55), (1.35, lift - 0.55)], 8, "copper"), at(0, 0, 0))
        for k in range(count):
            phi = math.radians(offset + (360.0 / count) * k)
            out = Vector((math.cos(phi), math.sin(phi), 0.0))
            d = out * math.sin(theta) - UP * math.cos(theta)
            root = Vector((0, 0, hinge)) + out * 0.9
            tip = root + d * arm
            bar(m, root, tip, 0.6, "girder")
            bar(m, Vector((0, 0, lift)) + out * 0.8, root + d * (arm / 2), 0.42, "girder")
            disc(m, tip + d * (wr * 0.5), wr, 0.95, "steel", axis=out, sides=8)
            disc(m, tip + d * (wr * 0.5), wr * 0.5, 1.15, "girder", axis=out, sides=8, ink=False)
            rim = Mesh()
            bm.hoop(rim, (0, 0, 0), wr - 0.05, wr + 0.3, 0.5, 8, "void", ink=False, lying=True)
            put(m, rim, Matrix.Translation(tip + d * (wr * 0.5)) @ UP.rotation_difference(out).to_matrix().to_4x4())
    # the demand: a yellow ring held on the legs at the height the weights fly when generation meets demand; weights
    # over it mean power to spare, under it the battery is covering
    hinge, arm, wr = tiers[-1][:3]
    zd = hinge - (arm + wr * 0.5) * math.cos(theta_of(demand))
    rr = foot - (foot - knee) * (zd - 0.5) / (knee_z - 0.5) - 1.0
    ring_up(m, (0, 0, zd), rr - 0.4, rr, 0.45, "yellow", sides=48)
    for a in posts:
        m.box((1.3, 0.6, 0.6), ((rr + 0.5) * math.cos(a), (rr + 0.5) * math.sin(a), zd), "steel", rot=(0, 0, a), ink=True)
    # the current out: from insulators on the head block, down the back stay and leg, away on the floor
    back = posts[2]
    c, s = math.cos(back), math.sin(back)
    for o in (-0.5, 0.5):
        side = Vector((-s, c, 0)) * o
        bm.insulator(m, (side.x + 1.0 * c, side.y + 1.0 * s, head + 1.1), 1.1)
        cable(m, [Vector((1.0 * c, 1.0 * s, head + 2.4)) + side, Vector((knee * 1.02 * c, knee * 1.02 * s, knee_z + 1.6)) + side,
                  Vector((foot * 1.04 * c, foot * 1.04 * s, 0.7)) + side,
                  Vector((foot * 1.04 * c + (0 if stage == 1 else -2.0), -18.0, 0.2)) + side], r=0.28)
    return m


# --- the yard, the views, the sheets -----------------------------------------------------------------------------------

def yard_without_generator(out: Path, fast):
    """base_plan's look as it stands, its generator taken out, a player's size where each view's player stands."""
    made = plan.machines

    def machines(level=1):
        return [row for row in made(level) if not row[0].startswith("Generator")]

    plan.machines = machines
    d = look.DIRECTIONS["M"]
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, 1, out / "maps")
    yard.plot(0.0, 1)
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    yard.person((base.SPAWN[0], -base.SPAWN[1]))
    for name, where in PLAYERS.items():
        yard.person(where, name)
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Floor")):
            obj.visible_shadow = False
    look.sky(scene, d)
    look.sun(scene, d)
    r = scene.render
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            r.engine = engine
            break
        except TypeError:
            continue
    r.resolution_x, r.resolution_y, r.resolution_percentage = *look.SIZE, 100
    scene.view_settings.view_transform = "Standard"
    scene.eevee.taa_render_samples = 8 if fast else 32
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("use_raytracing", False)):
        try:
            setattr(scene.eevee, attr, val)
        except AttributeError:
            pass
    return scene, yard, d


PLAYERS = {"Near": (0.0, -(GI - 30.0)), "Side": (-14.0, -(GI - 12.0))}
OWNER = {"spawn": "Avatar", "near": "Near", "side": "Side"}


def player_view(where, target):
    """The game's camera behind a player at `where`, turned toward `target`, at the start zoom and pitch."""
    pitch = math.radians(20.0)
    focus = Vector((where[0], where[1], 3.0 + look.FOCUS))
    flat = Vector((target[0] - where[0], target[1] - where[1], 0.0)).normalized()
    eye = focus - flat * math.cos(pitch) * look.ZOOM + UP * math.sin(pitch) * look.ZOOM
    return tuple(eye), tuple(target)


def views():
    g = (GX, -GI)
    near_eye, _ = player_view(PLAYERS["Near"], (*g, 0.0))
    return {
        "spawn": plan.behind((base.SPAWN[0], -base.SPAWN[1]), -1),
        "near": (near_eye, (g[0], g[1], 9.5)),
        "side": (player_view(PLAYERS["Side"], (*g, 0.0))[0], (g[0], g[1], 13.0)),
    }


class Shots:
    def __init__(self, out, scene, yard, d):
        self.out, self.scene, self.yard, self.d = out, scene, yard, d
        self.views = views()
        self.made = {}
        self.tris = {}

    def take(self, key, mesh, names):
        data = mesh.whole().to_object(f"Gen{key}", self.yard.stock.mats["Kit"])
        obj = bpy.data.objects.new(f"Gen{key}", data)
        obj.location = (GX, -GI, 0.0)
        self.scene.collection.objects.link(obj)
        self.tris[key] = mesh.whole().tris()
        for name in names:
            for who in ("Avatar", *PLAYERS):                                        # only this view's own player
                for part in ("Legs", "Body", "Head"):
                    person = bpy.data.objects.get(f"{who}{part}")
                    if person is not None:
                        person.hide_render = who != OWNER[name]
            eye, target = self.views[name]
            self.scene.camera = plan.camera(self.scene, f"Cam{key}{name}", eye, target)
            path = self.out / f"generator_{key}_{name}.png"
            linear = look.render_linear(self.scene, path.with_suffix(".exr"))
            px = look.finish(linear, self.d)
            rs.save(px, path)
            path.with_suffix(".exr").unlink(missing_ok=True)
            self.made[(key, name)] = px
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)


DIRECTIONS = (
    ("A", "the Void Mill", mill, A_FIXES),
    ("B", "the Beam Pump", pump, (
        "A walking beam rocks on the head of a straight column bound in even steel hoops. Its two pumps stand at the "
        "well's edge and lift the well's light up the pipes into the column's foot. The column's lit height is the "
        "generation, read against its bone ticks, and a bone collar clamped on it is the demand: light over the collar "
        "means power to spare, under it the battery is covering. The current leaves in yellow from two insulators on "
        "the beam's bearing block, down the two stays behind and away on the floor.",
        "The motion: the beam rocks at a pace set by the generation, the pumps stroke, and each stroke sends an even "
        "band of light up the column. Its gauge is the plainest of the three from the gate: a column filling, which a "
        "new player reads without being told, and the column with its beam makes a T no other machine in the yard "
        "has. The risk: the beam's reach (23 studs) is wide, and at rest it can read as a seesaw or a scale.",
        "Growth: Stage II has two columns under a bridge that carries the beam, a flywheel on a crank at the beam's "
        "right end, the stays plated, and a cabinet of three small gauges at the front. Stage III drops the beam: four "
        "columns round a core under a wide turning cam, its four pumps standing straight under the rim and pushing it "
        "up in turn, and the light kept in the columns. For the builder: the beam, each pump's rod and the flywheel are their own "
        "pieces, and the column's light is a piece scaled to the generation.")),
    ("C", "the Governor", governor, (
        "A spindle stands on a turbine housing over the well, where the void's light swirls behind slotted vanes. "
        "Three flat eight-sided weights on hinged arms swing out and up as it spins, and a copper collar slides up the "
        "spindle with them. The higher the weights fly the more power, and a yellow ring held on the frame's legs is "
        "the demand: weights flying over the ring mean power to spare, under it the battery is covering. The frame is "
        "three splayed legs that rise clear of the weights' sweep to their knees, then stays up to an angular bearing "
        "block at the head, a flat stack of copper collector rings under it, whose brushes send the current out in "
        "yellow down the back stay and leg.",
        "The motion: the spin, and the weights climbing as the plant generates more and dropping as it falls. Of the "
        "three it's the one whose motion is itself the reading: a player who adds a worker sees the weights rise past "
        "the ring. The risk: the weights are smaller than the wheel or the beam, so from the gate the frame carries "
        "the silhouette, and the reading wants the near view.",
        "Growth: the weights stay the main shape. Stage II has four weights, a wider housing with a bolted band, four "
        "legs plated low and five collector rings. Stage III has two tiers of weights, a low eight-sided housing with "
        "lit slots, the back legs braced, and the collector stack lit between its rings. For the builder: the spindle "
        "with its arms is one piece turning about the upright; each arm's angle and the collar's height follow the "
        "generation, and the ring's height follows the demand.")),
)
CAPTIONS = {"spawn": "Stage I from the spawn: the game's start camera, 62 studs before it (the base's new size brings it nearer)",
            "near": "Stage I from 30 studs before it, the camera turned up to it",
            "side": "Stage I from the side, 12 studs in front and 14 across, the camera turned up to it",
            "lowgen": "Stage I, low generation (under the demand)",
            "highgen": "Stage I, high generation",
            "II": "Stage II, machine levels 6 to 14, from 30 studs",
            "III": "Stage III, levels 15 and up, from 30 studs"}
STANDINS = ("Blocks in the base kit's own swatches, rendered in Blender under the place's dusk; nothing is seen in "
            "Studio. Violet in, yellow out. Stages and their levels are research's seeds (rework part 9). The white "
            "figures are a player's size.")


def direction_sheet(out, key, title, notes, cells, tris, name=None):
    gap, w, h = 16, *look.SIZE
    cols = 2
    rows = (len(cells) + cols - 1) // cols
    lines = [line for n in notes + (STANDINS + " Triangles, Stages I, II and III with the drawn edge: " +
                                     ", ".join(f"{t:,}" for t in tris) + ".",) for line in textwrap.wrap(n, 210)]
    width = cols * w + (cols + 1) * gap
    height = 48 + rows * (h + 34) + 14 + len(lines) * 19 + 16
    sheet = ui.Sheet(width, height, "#14151C")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 14, 20, f"Grow your Anime, the generator: {key}, {title}", "#EDE6D6", bold=0.2)
    for i, (caption, px) in enumerate(cells):
        x, y = gap + (i % cols) * (w + gap), 48 + (i // cols) * (h + 34)
        t.text(x, y, 14, caption, "#B4AC9C")
        rs.paste(sheet.px, px, x, y + 22)
    y = 48 + rows * (h + 34) + 6
    for i, line in enumerate(lines):
        t.text(gap, y + i * 19, 14, line, "#B4AC9C")
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / (name or f"generator_{key}.png"))


def glance_sheet(out, shots):
    """The three side by side from the spawn and from 30 studs, at two thirds' size."""
    gap = 16
    w, h = (round(s * 2 / 3) for s in look.SIZE)
    sheet = ui.Sheet(3 * w + 4 * gap, 44 + 2 * (h + 30), "#14151C")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    for i, (key, title, *_) in enumerate(DIRECTIONS):
        x = gap + i * (w + gap)
        for row, name in enumerate(("spawn", "near")):
            y = 44 + row * (h + 30)
            t.text(x, y - 22 if row == 0 else y, 15, f"{key}, {title}" if row == 0 else "", "#EDE6D6")
            rs.paste(sheet.px, rs.shrink(shots[(key, name)], 2 / 3), x, y + (0 if row == 0 else 4))
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "generator_glance.png")


def small_sheet(out, made):
    """For the content check: each direction's Stages I and III from the front at rest, cut to the machine, at 64 px
    tall over the dark, and the same at twice that beside it."""
    gap, crop = 16, (50, 410, 280, 680)        # rows and columns of a near view that hold the machine
    cells = [(f"{key} {stage}", made[(f"{key}{'' if stage == 'I' else stage}", "near")]) for key, *_ in DIRECTIONS for stage in ("I", "III")]
    tall = (64, 128)
    widths = [[round((crop[3] - crop[2]) * t / (crop[1] - crop[0])) for t in tall] for _ in cells]
    width = gap + sum(w[1] + gap for w in widths)
    sheet = ui.Sheet(width, 44 + tall[0] + tall[1] + 3 * gap + 20, "#0E0F14")
    t = sheet.tile(0, 0, sheet.w, sheet.h)
    t.text(gap, 12, 14, "The generator's directions at 64 px and 128 px tall, from the front at rest, over the dark", "#B4AC9C")
    x = gap
    for (label, px), (w64, w128) in zip(cells, widths):
        cut = px[crop[0]:crop[1], crop[2]:crop[3]]
        small = rs.shrink(cut, tall[0] / (crop[1] - crop[0]))
        big = rs.shrink(cut, tall[1] / (crop[1] - crop[0]))
        rs.paste(sheet.px, small, x, 40)
        rs.paste(sheet.px, big, x, 40 + tall[0] + gap)
        t.text(x, 40 + tall[0] + tall[1] + 2 * gap - 4, 13, label, "#EDE6D6")
        x += w128 + gap
    for layer in ui.text_layers(sheet.px.shape[1], sheet.px.shape[0], sheet.items).values():
        rs.paste(sheet.px, layer, 0, 0)
    rs.save(sheet.px, out / "generator_64.png")


def fixes_sheet(out, shots):
    """A after research's three fixes, from the game's camera, with its last near view before them."""
    shots.take("A", mill(1), ("spawn", "near", "side"))
    shots.take("Alowgen", mill(1, gen=0.2), ("near",))
    shots.take("Ahighgen", mill(1, gen=0.95), ("near",))
    shots.take("AII", mill(2), ("near",))
    shots.take("AIII", mill(3), ("near",))
    ui.K = 1
    cells = [(CAPTIONS["spawn"], shots.made[("A", "spawn")]),
             (CAPTIONS["near"] + ", generation 0.6, demand 0.45", shots.made[("A", "near")]),
             (CAPTIONS["side"], shots.made[("A", "side")]),
             ("Stage I, low generation (0.2): the arc under the demand's mark", shots.made[("Alowgen", "near")]),
             ("Stage I, high generation (0.95): the arc up to the collector", shots.made[("Ahighgen", "near")]),
             (CAPTIONS["II"], shots.made[("AII", "near")]), (CAPTIONS["III"], shots.made[("AIII", "near")])]
    before = out / "generator_A_before_near.png"
    if before.exists():
        cells.append(("Before the fixes: the direction research picked, from 30 studs", rs.load(before)))
    direction_sheet(out, "A", "the Void Mill, with research's three fixes", A_FIXES, cells,
                    [shots.tris["A"], shots.tris["AII"], shots.tris["AIII"]], name="generator_A_fixes.png")
    print("triangles:", {k: v for k, v in shots.tris.items()})


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if "small" in args:                                     # the 64 px sheet alone, from views already rendered here
        ui.K = 1
        small_sheet(out, {(f"{key}{s}", "near"): rs.load(out / f"generator_{key}{s}_near.png")
                          for key, *_ in DIRECTIONS for s in ("", "III")})
        return
    fast = "fast" in args
    scene, yard, d = yard_without_generator(out, fast)
    if "A" in args:                                         # research's pick alone, with its three fixes
        fixes_sheet(out, Shots(out, scene, yard, d))
        return
    shots = Shots(out, scene, yard, d)
    for key, title, build, _ in DIRECTIONS:
        shots.take(key, build(1), ("spawn", "near", "side"))
        if key != "A":
            shots.take(f"{key}lowgen", build(1, gen=0.18), ("near",))
            shots.take(f"{key}highgen", build(1, gen=0.95), ("near",))
        shots.take(f"{key}II", build(2), ("near",))
        shots.take(f"{key}III", build(3), ("near",))
    ui.K = 1
    for key, title, build, notes in DIRECTIONS:
        names = [("spawn", key), ("near", key), ("side", key)]
        names += [] if key == "A" else [("lowgen", f"{key}lowgen"), ("highgen", f"{key}highgen")]
        names += [("II", f"{key}II"), ("III", f"{key}III")]
        cells = [(CAPTIONS[c], shots.made[(k, "near" if c in ("lowgen", "highgen", "II", "III") else c)]) for c, k in names]
        direction_sheet(out, key, title, notes, cells, [shots.tris[key], shots.tris[f"{key}II"], shots.tris[f"{key}III"]])
    glance_sheet(out, shots.made)
    small_sheet(out, shots.made)
    print("triangles:", {k: v for k, v in shots.tris.items()})


if __name__ == "__main__":
    main()
