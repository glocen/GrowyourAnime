"""AR19: the generator, the Void Mill (research's pick of 2026-11-16, 15:04; its three fixes passed at 15:38).

A wheel facing the gate turns down into the well's dark. Its band of buckets comes up on the gate's right through the
void's light, and a collector's shoe high on that side takes it. The lit arc's height up the rim is the generation; a
bone diamond on a rail outside the rim is the demand, and the arc past it means power to spare. In front, a concrete
sill across the well carries a trestle and the front bearing; the collector is an arm clamped on that bearing.

One source for two uses: generator_directions.py's sheet draws the whole mill (`mill`), and the base kit takes
`PIECES` (base_kit.py), the mill cut the way the builder drives it (Faber, 2026-11-16):
  Generator          all that stands still: the well and its kerb, the back bearing on its raked frame, the sill, the
                     trestle and the front bearing, the collector arm with its shoe, the demand's rail, the current's
                     cable, and the dark plate behind the band that the buckets turn across.
  GeneratorWheel     the rims, the buckets' walls, the spokes, the hub and the axle with its nut: its origin on the axle,
                     AXLE up, turning about the line to the gate. From the gate it turns anticlockwise: the buckets rise
                     on the gate's right.
  GeneratorArc1..8   the gauge: eight still steps of the void's light between the plate and the band, from the well up
                     the gate's right to the collector's shoe, each an eighth of the generation's share. A step is
                     shown or hidden, never dimmed: hidden, the dark plate shows through the band.
  GeneratorDemand    the demand's bone diamond with its lit pip, on the rail: its origin on the axle, made at a share of
                     0, turned about the axle by the share, the way the wheel turns.
Stages II and III are drawn in the sheet only: the builder's first install judges Stage I's pace alone.

The frame is the kit's: a piece's front (+Y) toward the gate, its origin on the floor at the well's middle (on the
axle for the wheel and the demand), one unit a stud. A part built about Z is turned by FACING so its Z looks at the
gate: an angle `a` about it is then at (cos a, -sin a) across and up from the axle. Violet in, yellow out.

The content check (2026-11-16, by 15:36) holds for the finish: both sets of spokes straight and radial; Stage III's
dynamos square cages about the hub's height either side of a trestle that keeps its splayed A and tie; the collector
one straight rigid arm with nothing hung from it; copper on the orange side; the demand's mark a plain diamond with a
plain pip; the violet emissive stepped light and the well dark with motes.

Not run by itself.
"""

import math
import sys
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
import lantern_row_kit as kit  # noqa: E402

Mesh, Piece = bm.Mesh, kit.Piece
UP = Vector((0.0, 0.0, 1.0))
FACING = Matrix.Rotation(-math.pi / 2, 4, "X")   # a part built about Z, turned so its Z looks at the gate (+Y)

AXLE = 10.0           # the wheel's axle, up from the floor
GAUGE_TOP = 250.0     # the collector's shoe, about the wheel's own Z: high on the gate's right, short of the top
DEEP = 3.0            # the band of buckets, from its outer rim in
STEPS = 8             # the gauge's steps
GAP = 1.6             # degrees of dark between two steps, so the light reads stepped
REACH = 2.6           # the front bearing, out from the wheel's face


# --- shapes ------------------------------------------------------------------------------------------------------------

def put(m, part, M):
    """`part`'s faces into `m`, moved by the 4x4 `M`, its drawn edge with it."""
    for face, uv in zip(part.f, part.uv):
        m.face([M @ Vector(part.v[i]) for i in face], uv)
    if part.ink is not None and m.ink is not None:
        for face in part.ink.f:
            m.ink.face([M @ Vector(part.ink.v[i]) for i in face], [(0, 0)] * len(face))


def turned(profile, sides, sw, ink=True, caps=True):
    """A solid turned about Z (the kit's lathe: `profile` is (radius, height) from its head down), with its drawn
    edge: the same shape grown by the hull and turned inside out."""
    m = Mesh()
    m.lathe(profile, (0, 0, 0), sides, sw, caps=caps)
    if ink:
        t = m.ink_t
        zs = [z for _, z in profile]
        top, foot = max(zs), min(zs)
        grown = [(r + t, z + (t if z == top else -t if z == foot else 0.0)) for r, z in profile]
        hull = Mesh(None)
        hull.lathe(grown, (0, 0, 0), sides, "ink", caps=caps)
        for face in hull.f:
            m.ink.face([hull.v[i] for i in face][::-1], [(0, 0)] * len(face))
    return m


def at(x, y, z):
    return Matrix.Translation((x, y, z))


def along(a, b):
    """The 4x4 that stands a part built up Z on the line from a to b."""
    a, b = Vector(a), Vector(b)
    return Matrix.Translation(a) @ UP.rotation_difference((b - a).normalized()).to_matrix().to_4x4()


def rod(m, a, b, r, sw, sides=8, ink=True):
    length = (Vector(b) - Vector(a)).length
    put(m, turned([(r, length), (r, 0.0)], sides, sw, ink=ink), along(a, b))


def bar(m, a, b, w, sw, d=None, ink=True):
    """A square beam from a to b, `w` across (and `d` the other way)."""
    a, b = Vector(a), Vector(b)
    m.box((w, d or w, (b - a).length), (a + b) / 2, sw, rot=UP.rotation_difference((b - a).normalized()).to_matrix(), ink=ink)


def disc(m, centre, r, thick, sw, axis=(0, 1, 0), sides=16, ink=True):
    """A flat round plate, its face looking along `axis`."""
    c, n = Vector(centre), Vector(axis).normalized()
    put(m, turned([(r, thick / 2), (r, -thick / 2)], sides, sw, ink=ink), Matrix.Translation(c) @ UP.rotation_difference(n).to_matrix().to_4x4())


def ring_up(m, centre, r0, r1, thick, sw, sides=16, ink=True):
    """A ring lying flat about an upright, its middle at `centre`."""
    bm.hoop(m, centre, r0, r1, thick, sides, sw, ink=ink, lying=True)


def floor_disc(m, centre, r, sw, sides=32):
    x, y, z = centre
    m.face([Vector((x + r * math.cos(math.tau * i / sides), y + r * math.sin(math.tau * i / sides), z)) for i in range(sides)],
           [kit.sw_uv(sw, 0.5, 1.0)] * sides)


def cable(m, points, r=0.22):
    """A cable laid straight from clamp to clamp, the current's yellow along its top."""
    m.tube(points, r, "rubber")
    m.tube([Vector(p) + Vector((0, 0, r * 0.95)) for p in points], r * 0.42, "power")
    for p in points[1:-1]:
        m.box((0.7, 0.7, 0.7), p, "steel")


def motes(m, points, size=0.22):
    """Small motes of the void's light: light, never drops."""
    for p in points:
        m.box((size, size, size), p, "void", rot=(0.6, 0.4, 0.8))


def sector(m, r0, r1, a, b, z0, z1, sw, t=0.85, n=4):
    """A curved slab about Z, from `r0` out to `r1` and from `a` to `b` degrees, between `z0` and `z1`."""
    angles = [math.radians(a + (b - a) * k / n) for k in range(n + 1)]
    ring = [[Vector((r * math.cos(q), r * math.sin(q), z)) for q in angles] for r, z in ((r0, z0), (r1, z0), (r1, z1), (r0, z1))]
    uv = [kit.sw_uv(sw, 0.0, t)] * 4
    for k in range(n):
        q = (angles[k] + angles[k + 1]) / 2
        inside = Vector(((r0 + r1) / 2 * math.cos(q), (r0 + r1) / 2 * math.sin(q), (z0 + z1) / 2))
        for i in range(4):
            j = (i + 1) % 4
            m.out([ring[i][k], ring[j][k], ring[j][k + 1], ring[i][k + 1]], uv, inside)
        if k in (0, n - 1):
            e = k if k == 0 else k + 1
            m.out([ring[i][e] for i in range(4)], uv, inside)


def toothed(r, teeth, thick, hole):
    """A spur gear about Z: a web from `hole` out, its teeth at `r`."""
    g = Mesh()
    bm.hoop(g, (0, 0, 0), hole, r - 0.3, thick, max(teeth, 12), "girder", lying=True)
    for k in range(teeth):
        a = math.tau * k / teeth
        g.box((0.65, 0.65, thick), Vector((math.cos(a), math.sin(a), 0)) * r, "girder", rot=(0, 0, a))
    return g


def dynamo(m, x, y0, y1, z, stand_from):
    """A dynamo, housed (research's fix 3): a copper drum lying along the line to the gate inside a steel cage, square
    bolted end plates joined by four corner bars and strapped round, a bone boss on its front, a terminal box on its
    top, on a stand down to `stand_from`. From the gate it's a square plate round a boss, never a ball."""
    s, length = 3.6, y1 - y0
    put(m, turned([(1.45, length - 0.6), (1.45, 0.0)], 14, "copper"), at(x, y0 + 0.3, z) @ FACING)
    for y in (y0 + 0.25, y1 - 0.25):
        m.box((s, 0.5, s), (x, y, z), "steel", ink=True)
    for cx in (-1, 1):
        for cz in (-1, 1):
            m.box((0.5, length - 0.5, 0.5), (x + cx * (s / 2 - 0.25), (y0 + y1) / 2, z + cz * (s / 2 - 0.25)), "steel")
    for f in (0.35, 0.65):
        put(m, turned([(1.7, 0.45), (1.7, 0.0)], 14, "steel"), at(x, y0 + length * f - 0.22, z) @ FACING)
    put(m, turned([(0.85, 0.45), (0.85, 0.0)], 10, "bone"), at(x, y1, z) @ FACING)
    m.box((1.6, 1.8, 1.0), (x, (y0 + y1) / 2, z + s / 2 + 0.5), "dark", ink=True)
    high = z - s / 2 - stand_from
    m.box((2.6, 2.0, high), (x, (y0 + y1) / 2 - 0.2, stand_from + high / 2), "steel", ink=True)


# --- the mill ----------------------------------------------------------------------------------------------------------

def size(stage):
    """The wheel's radius and its band's width: from Stage II the wheel is a twin, wider and a little taller."""
    return (11.6, 4.0) if stage == 1 else (12.2, 5.0)


def start(stage):
    """Where a bucket leaves the well on the gate's right: the angle about the wheel's own Z at which its rim clears
    the well's floor (1 up), and 3 more."""
    return 180.0 - math.degrees(math.asin((AXLE - 1.0) / size(stage)[0])) + 3.0


def span(stage):
    """The gauge's arc, in degrees: from the well to the collector's shoe."""
    return GAUGE_TOP - start(stage)


def lit_to(share, stage):
    """The gauge (research's fix 1): the angle up to which the rising side is lit, from the well at a share of 0 to
    the collector's shoe at 1."""
    return start(stage) + max(0.0, min(1.0, share)) * span(stage)


def steps_lit(share):
    """How many of the gauge's steps a share lights: the nearest whole step."""
    return int(round(max(0.0, min(1.0, share)) * STEPS))


def rail_radius(stage):
    """The rail's middle, outside the rim (outside the casing at Stage III)."""
    return size(stage)[0] + (2.6 if stage == 3 else 0.6) + 0.45


def wheel(stage):
    """The wheel, built about Z, its front at +Z: a deep band of buckets between an inner and an outer rim, open at
    the back onto the still plate; heavy spokes, a filled hub bolted in bone, and the axle out through the front
    bearing to its nut. The light isn't the wheel's: it stands still behind the band."""
    r, width = size(stage)
    w = Mesh()
    hub, buckets = 3.0, (20 if stage == 1 else 24)
    bm.hoop(w, (0, 0, 0), r - 0.6, r, width, 44, "steel", lying=True)                         # the outer rim
    bm.hoop(w, (0, 0, 0), r - DEEP - 0.6, r - DEEP, width, 44, "steel", lying=True)           # the inner rim
    mid = r - DEEP / 2 - 0.3
    for k in range(buckets):
        a = math.tau * k / buckets
        out = Vector((math.cos(a), math.sin(a), 0.0))
        w.box((DEEP - 0.2, 0.45, width), out * mid, "girder", rot=(0.0, 0.0, a + 0.18), ink=True)   # a bucket's wall
    for z in ((-width / 2 + 0.6, width / 2 - 0.6) if stage > 1 else (0.0,)):
        for k in range(6):
            a = math.tau * (k + 0.5) / 6
            out = Vector((math.cos(a), math.sin(a), 0.0))
            length = r - DEEP - 0.6 - hub
            w.box((length + 0.6, 1.3, 1.3), out * (hub + length / 2) + Vector((0, 0, z)), "girder", rot=(0.0, 0.0, a), ink=True)
    put(w, turned([(hub, width / 2 + 0.3), (hub, -width / 2 - 0.3)], 16, "steel"), Matrix.Identity(4))   # the hub, filled
    for k in range(8):                                                                       # its bolts
        a = math.tau * (k + 0.5) / 8
        w.box((0.5, 0.5, 0.3), (2.25 * math.cos(a), 2.25 * math.sin(a), width / 2 + 0.4), "bone", rot=(0.0, 0.0, a))
    nut = width / 2 + REACH + 1.2                                                            # on the bearing's cap
    put(w, turned([(1.0, nut), (1.0, width / 2)], 12, "girder"), Matrix.Identity(4))         # the axle
    put(w, turned([(1.15, nut + 0.5), (1.15, nut)], 6, "bone"), Matrix.Identity(4))          # its nut
    return w


def plate(stage):
    """The dark plate behind the band, still, about the wheel's Z: what shows through the band where it isn't lit."""
    r, width = size(stage)
    m = Mesh()
    bm.hoop(m, (0, 0, -width / 2 - 0.31), r - DEEP - 0.3, r - 0.3, 0.3, 44, "dark", ink=False, lying=True)
    return m


def arc_step(stage, i):
    """The gauge's step `i` (0 at the well), still, about the wheel's Z: a curved slab of the void's light between the
    plate and the band, an eighth of the arc less a sliver of dark."""
    r, width = size(stage)
    d = span(stage) / STEPS
    a = start(stage) + i * d
    m = Mesh()
    sector(m, r - DEEP + 0.1, r - 0.7, a + GAP / 2, a + d - GAP / 2, -width / 2 - 0.16, -width / 2 - 0.04, "void")
    return m


def demand_mark(stage):
    """The demand's mark at a share of 0, about the wheel's Z: a bone diamond on the rail pointing in at the rim, a
    lit pip in its face so it holds at dusk, where unlit bone facing the gate reads dark."""
    r, width = size(stage)
    front = width / 2
    a = math.radians(start(stage))
    out = Vector((math.cos(a), math.sin(a), 0.0))
    m = Mesh()
    m.box((2.0, 2.0, 1.4), out * (rail_radius(stage) + 0.51) + Vector((0, 0, front - 0.2)), "bone", rot=(0.0, 0.0, a + math.pi / 4), ink=True)
    m.box((0.95, 0.95, 0.3), out * (rail_radius(stage) + 0.51) + Vector((0, 0, front + 0.6)), "lamp", rot=(0.0, 0.0, a + math.pi / 4), occ=0.5)
    return m


def still(stage, top=None):
    """All of the mill that stands still. `top`, the gauge's lit angle, lights Stage III's casing's windows."""
    m = Mesh()
    r, width = size(stage)
    front = width / 2
    a0 = start(stage)
    top = a0 if top is None else top
    face = at(0, 0, AXLE) @ FACING                                   # the wheel's frame, for what stands still round it
    centre = Vector((0.0, 0.0, AXLE))
    # the well: a low steel kerb round the dark the wheel turns down into, motes of light rising in it
    ring_up(m, (0, 0, 0.7), 9.4, 10.6, 1.4, "steel", sides=44)
    floor_disc(m, (0, 0, 1.0), 9.4, "dark")
    motes(m, [(-1.5, 0.4, 1.1), (3.2, -0.8, 1.1), (-5.6, 0.9, 1.1), (6.0, 1.2, 1.1), (-3.4, -1.6, 1.1), (0.6, 1.8, 1.1)], size=0.3)
    put(m, plate(stage), face)
    # behind: the back bearing on its raked frame
    back = -front - 1.6
    m.box((3.6, 2.4, 3.6), (0, back, AXLE), "steel", ink=True)
    for sx in (-1, 1):
        bar(m, (sx * 7.6, -14.0, 0.3), (sx * 1.5, back, AXLE - 1.3), 1.3, "girder")
        m.box((2.8, 2.8, 0.6), (sx * 7.6, -14.0, 0.3), "concrete", ink=True)
    # in front (research's fix 2): a concrete sill across the well, a trestle on it, the front bearing at its head
    yf = front + REACH
    m.box((22.4, 1.8, 1.0), (0, yf, 0.9), "concrete", ink=True)
    for sx in (-1, 1):
        bar(m, (sx * 3.6, yf, 1.4), (sx * 0.9, yf, AXLE - 1.6), 1.1, "girder")
    bar(m, (-2.45, yf, 4.4), (2.45, yf, 4.4), 0.8, "girder")
    m.box((4.8, 2.4, 1.6), (0, yf, AXLE - 1.6), "steel", ink=True)                              # the pillow block
    put(m, turned([(1.8, 1.2), (1.8, -1.2)], 14, "steel"), at(0, yf, AXLE) @ FACING)            # its cap
    for sx in (-1, 1):
        m.box((0.55, 0.55, 0.5), (sx * 2.0, yf, AXLE - 0.6), "bone", ink=True)
    # the collector (fix 2): an arm clamped on the bearing's cap, out across the wheel's face to the top of the gauge,
    # where its copper shoe rides the buckets' lips; it carries the rail's head beyond the rim
    phi = math.radians(GAUGE_TOP)
    dirn = Vector((math.cos(phi), 0.0, -math.sin(phi)))
    turn = (0.0, -math.atan2(dirn.z, dirn.x), 0.0)
    mid = r - DEEP / 2 - 0.3
    rr = rail_radius(stage)
    head = centre + Vector((0, yf, 0))
    tip, end = head + dirn * mid, head + dirn * rr
    m.box((1.0, 2.8, 1.6), head + dirn * 2.0, "steel", rot=turn, ink=True)                     # the clamp
    bar(m, head + dirn * 1.8, end, 1.2, "steel", d=0.9)
    bar(m, tip + Vector((0, -0.4, 0)), Vector((tip.x, front + 0.55, tip.z)), 0.8, "steel")     # the shoe's holder
    m.box((1.3, 0.5, 2.2), (tip.x, front + 0.3, tip.z), "copper", rot=turn, ink=True)          # the shoe
    bm.insulator(m, tuple(head + dirn * (mid * 0.62) + Vector((0, 0.7, 0.5))), 1.4)
    bar(m, end + Vector((0, -0.4, 0)), Vector((end.x, front + 0.2, end.z)), 0.8, "steel")      # down to the rail
    # the gauge's rail (fix 1): a steel arc outside the rim on the rising side, from the well to the collector
    rail = Mesh()
    lo, hi, n = a0 - 6.0, GAUGE_TOP, 16
    for k in range(n):
        a = math.radians(lo + (hi - lo) * (k + 0.5) / n)
        chord = 2 * rr * math.sin(math.radians(hi - lo) / n / 2) + 0.06
        rail.box((0.9, chord, 1.0), Vector((math.cos(a), math.sin(a), 0.0)) * rr + Vector((0, 0, front - 0.2)),
                 "steel", rot=(0.0, 0.0, a), ink=True)
    put(m, rail, face)
    if stage == 3:
        # the casing: an armoured half drum over the twin wheel, its window band lit only as far as the gauge
        shell, band = Mesh(), Mesh()
        ra, rb = r + 1.0, r + 2.0
        for k in range(14):
            a = math.radians(188 + k * 12 + 6)
            shell.box(((ra + rb) / 2 * 0.22 + 0.25, rb - ra, width + 1.6), Vector((math.cos(a), math.sin(a), 0.0)) * (ra + rb) / 2,
                      "steel", rot=(0.0, 0.0, a + math.pi / 2), ink=True)
        for k in range(7):
            a = 194 + k * 11.5
            band.box((0.4, 1.6, 0.3), Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0.0)) * (ra + rb) / 2,
                     "void" if a <= top else "dark", rot=(0.0, 0.0, math.radians(a)), occ=0.5)
        put(m, shell, face)
        put(m, band, at(0, width / 2 + 0.85, AXLE) @ FACING)
        for x in (-10.6, -8.4, -6.0, 6.0, 8.4, 10.6):                                          # the crown of rods
            z = AXLE + math.sqrt(max(rb * rb - x * x, 0.0))
            rod(m, (x, -0.4, z - 0.6), (x, -0.4, z + 3.2), 0.28, "steel")
            bm.insulator(m, (x, -0.4, z + 3.2), 1.1)
            m.box((0.6, 0.6, 0.45), (x, -0.4, z + 4.5), "copper", ink=True)
    if stage >= 2:
        # the dynamos the gear train drives, housed, on their stands on the sill: Stage II's on the descending side,
        # Stage III's a second on the rising side; and the frame plated
        for sx in ((1,) if stage == 2 else (1, -1)):
            px, pz = pinion(sx)
            dynamo(m, px, front + 1.4, front + 5.6, pz, 1.4)
            cable(m, [(px, front + 3.5, pz + 2.5), (sx * 9.0, front + 3.5, pz + 2.5), (sx * 9.8, yf + 0.9, 1.4),
                      (sx * 11.4, -4.0, 0.3), (sx * 3.4, -18.0, 0.2)], r=0.3)
        for sx in (-1, 1):
            bar(m, (sx * 6.8, -13.2, 0.6), (sx * 1.9, back, AXLE - 0.4), 2.0, "steel", d=0.5)
    # the current: from the shoe along the arm, round the bearing, down the trestle and away on the floor
    cable(m, [tuple(tip + Vector((0, 0.75, 0))), tuple(head + dirn * 2.4 + Vector((0, 0.75, 0))),
              (-2.8, yf + 0.8, AXLE - 0.4), (-2.8, yf + 0.8, AXLE - 2.6), (-3.9, yf + 0.8, 1.6),
              (-9.8, yf + 0.9, 1.4), (-11.4, -4.0, 0.3), (-3.4, -18.0, 0.2)], r=0.3)
    return m


def pinion(sx):
    """A pinion's axle, across and up: on the gear's rim, 30 degrees under the axle's level."""
    return sx * 6.0 * math.cos(math.radians(30.0)), AXLE - 6.0 * math.sin(math.radians(30.0))


def mill(stage, gen=0.6, demand=0.45):
    """The whole mill as the builder will stand it, at a generation and a demand, for the sheet: the still parts, the
    wheel at rest, the steps the generation lights, the demand's mark turned to its share, and from Stage II the gear
    train (the gears turn with the wheel, the pinions the other way)."""
    a0, d = start(stage), span(stage) / STEPS
    lit = steps_lit(gen)
    m = still(stage, top=a0 + lit * d)
    face = at(0, 0, AXLE) @ FACING
    put(m, wheel(stage), face)
    for i in range(lit):
        put(m, arc_step(stage, i), face)
    put(m, demand_mark(stage), face @ Matrix.Rotation(math.radians(max(0.0, min(1.0, demand)) * span(stage)), 4, "Z"))
    if stage >= 2:
        front = size(stage)[1] / 2
        put(m, toothed(4.2, 24, 0.8, 1.0), at(0, front + 0.9, AXLE) @ FACING)
        for sx in ((1,) if stage == 2 else (1, -1)):
            px, pz = pinion(sx)
            put(m, toothed(1.65, 10, 0.8, 0.5), at(px, front + 0.9, pz) @ FACING)
    return m


# --- the kit's pieces (Stage I) ------------------------------------------------------------------------------------------

def generator():
    r, width = size(1)
    yf = width / 2 + REACH
    return Piece("Generator", still(1),
                 solid=f"in the piece's frame (across, toward the gate, up): the well shut to walking, a cylinder of "
                       f"radius 10.6, 3 high, at the middle; the sill a box 22.4 across, 1.8 deep and 1.4 high, its "
                       f"middle {yf:g} toward the gate; each raked leg's foot a box 2.8 square, 1 high, at across "
                       f"+-7.6, 14 back; each raked leg a Part 1.3 thick along its line, from (+-7.6, -14, 0.3) to "
                       f"(+-1.5, {-width / 2 - 1.6:g}, {AXLE - 1.3:g}). The trestle stands on the sill and the arm "
                       f"over the well: look only",
                 note=f"its middle on the well's. The wheel (GeneratorWheel) turns on its axle {AXLE:g} up, 23.2 "
                      f"across; the gauge's steps (GeneratorArc1 to {STEPS}) stand still behind its band, and the "
                      f"demand's mark (GeneratorDemand) rides the rail outside its rim. The collector's arm reaches "
                      f"about 22.5 up. The well light stays: VoidWell, 1.6 up in its middle")


def generator_wheel():
    m = Mesh()
    put(m, wheel(1), FACING)
    return Piece("GeneratorWheel", m,
                 note=f"its origin is its axle's middle, {AXLE:g} up at the generator's middle; its axle lies along "
                      f"the piece's Y (Roblox's Z), the line to the gate. From the gate it turns anticlockwise, so the "
                      f"buckets rise on the gate's right and run under the collector's shoe: in Roblox, "
                      f"CFrame.Angles(0, 0, -angle) with the angle growing, faster as the plant generates more. Its "
                      f"lower edge runs 1.6 under the floor, inside the well's dark")


def generator_arc(i):
    def make():
        lo, hi = i / STEPS, (i + 1) / STEPS
        a = start(1) + i * span(1) / STEPS
        return Piece(f"GeneratorArc{i + 1}", put_still(arc_step(1, i)),
                     note=f"the gauge's step {i + 1} of {STEPS}, from the well up: the generation's share from "
                          f"{lo:g} to {hi:g}, {a:.1f} to {a + span(1) / STEPS:.1f} degrees about the axle. Still, at "
                          f"the generator's place. Light the first k steps, k the share times {STEPS} rounded: shown "
                          f"or hidden (Transparency), never dimmed, since its colour is the void's pale light; hidden, "
                          f"the dark plate behind it shows. Look only")
    return make


def put_still(part):
    m = Mesh()
    put(m, part, at(0, 0, AXLE) @ FACING)
    return m


def generator_demand():
    m = Mesh()
    put(m, demand_mark(1), FACING)
    return Piece("GeneratorDemand", m,
                 note=f"its origin on the axle, {AXLE:g} up at the generator's middle, made at a demand's share of 0 "
                      f"at the rail's foot by the well. The rail is an arc about the axle, so the mark turns, not "
                      f"slides: about the axle the way the wheel turns, by the share times {span(1):.1f} degrees "
                      f"(CFrame.Angles(0, 0, -share * math.rad({span(1):.1f}))); at 1 it stands by the collector's "
                      f"shoe, {rail_radius(1) + 0.51:.2f} from the axle, about "
                      f"{math.radians(span(1)) * (rail_radius(1) + 0.51):.0f} studs of travel. The share is on the "
                      f"gauge's own scale, the demand over the same top as the generation's, so the lit steps reach "
                      f"the mark when generation meets demand. Under a share of 0.12 it sinks into the well's kerb. "
                      f"Look only")


PIECES = {"Generator": generator, "GeneratorWheel": generator_wheel,
          **{f"GeneratorArc{i + 1}": generator_arc(i) for i in range(STEPS)}, "GeneratorDemand": generator_demand}
