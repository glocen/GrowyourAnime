"""AR19: the generator, the Void Mill (research's pick of 2026-11-16, 15:04; its three fixes passed at 15:38).

A wheel facing the gate turns down into the well's dark. Its band of buckets comes up on the gate's right through the
void's light, and a collector's claw high on that side takes it. The lit arc's height up the rim is the generation; a
bone diamond on a rail outside the rim is the demand, and the arc past it means power to spare. In front, a concrete
sill across the well carries a trestle and the front bearing; the collector is an arm clamped on that bearing.

One source for two uses: generator_directions.py's sheet draws the whole mill (`mill`), and the base kit takes
`PIECES` (base_kit.py), the mill cut the way the builder drives it (Faber, 2026-11-16):
  Generator          all that stands still: the well and its kerb, the back bearing on its raked frame, the sill, the
                     trestle and the front bearing, the collector arm with its claw, the demand's rail, the current's
                     cable, and the dark plate behind the band that the buckets turn across.
  GeneratorWheel     the rims, the buckets' walls, the spokes, the hub and the axle with its nut: its origin on the axle,
                     AXLE up, turning about the line to the gate. From the gate it turns anticlockwise: the buckets rise
                     on the gate's right.
  GeneratorArc1..8   the gauge: eight still steps of the void's light between the plate and the band, from the well up
                     the gate's right to the collector's claw, each an eighth of the generation's share. A step is
                     shown or hidden, never dimmed: hidden, the dark plate shows through the band.
  GeneratorDemand    the demand's bone diamond with its lit pip, on the rail: its origin on the axle, made at a share of
                     0, turned about the axle by the share, the way the wheel turns.
Stages II and III (Faber, 2026-11-16: the generator takes the stage of the base's ceiling, II at base level 2 and III
at 3) are cut the same way, every piece of stage n named Generator<n>..., with what a later stage keeps from the one
before named once: `STAGES` lists each stage's pieces, and base_plan.py writes it into the plan as the swap's table.
  Generator2, Generator3          the stage's still body. Stage III's casing windows stand dark in it.
  Generator2Wheel                 the twin wheel and the spur gear on its axle, which turns with it: Stages II and III.
                                  The pinions turn the void's cages on the sill (Generator2, 3).
  Generator2Pinion                the pinion on the descending side, turning the other way, 24/10 as fast: II and III.
  Generator3Pinion                the pinion on the rising side: III.
  Generator2Arc1..8, 3Arc1..8     the gauge's steps on the twin wheel. Stage III's carry the casing's windows over them,
                                  so a window lights with its step.
  Generator2Demand, 3Demand       the demand's mark: Stage III's rail runs outside the casing.

The frame is the kit's: a piece's front (+Y) toward the gate, its origin on the floor at the well's middle (on the
axle for the wheel and the demand), one unit a stud. A part built about Z is turned by FACING so its Z looks at the
gate: an angle `a` about it is then at (cos a, -sin a) across and up from the axle. Violet in, yellow out.

The content check (2026-11-16, by 15:36) holds for the finish: both sets of spokes straight and radial; Stage III's
cages square about the hub's height either side of a trestle that keeps its splayed A and tie; the collector one
straight rigid arm with nothing hung from it; the demand's mark a plain diamond with a plain pip; the violet emissive
stepped light and the well dark with motes. The crown stays unlit, three and three, its top's middle open, and the
collector's claw stays unlit, since a light at the gauge's top would read as the gauge full.

The machines are void machines built from parts you can read, never real electrical plant (the director, 2026-11-15;
docs/design.md, the base): AR19's class fix (2026-11-17) took out the copper dynamos, the ceramic insulators and the
copper shoe and blocks, for cages of void stone round a lit shard, horns of void stone and a claw of bone. Gears,
bearings, clamps and cables stay.

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
GAUGE_TOP = 250.0     # the collector's claw, about the wheel's own Z: high on the gate's right, short of the top
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


TOOTH = (0.32, 0.4, 0.55, 0.24)   # a tooth: out past the pitch circle, in under it, its width at the root and at the tip


def toothed(r, teeth, thick, hole):
    """A spur gear about Z: a web from `hole` out to the teeth's root, its teeth tapered from the root to the tip
    about the pitch circle `r` (AR19's tooth fix, 2026-11-17: narrower than the gaps between them, so a pair meshes
    through its whole pass with the faces never crossing)."""
    add, ded, w_root, w_tip = TOOTH
    g = Mesh()
    bm.hoop(g, (0, 0, 0), hole, r - ded + 0.02, thick, max(teeth, 12), "girder", lying=True)
    r0, r1 = r - ded, r + add
    for k in range(teeth):
        a = math.tau * k / teeth
        out, side = Vector((math.cos(a), math.sin(a), 0.0)), Vector((-math.sin(a), math.cos(a), 0.0))
        rim = [out * r0 - side * w_root / 2, out * r1 - side * w_tip / 2, out * r1 + side * w_tip / 2, out * r0 + side * w_root / 2]
        prism(g, rim, thick, "girder", out * (r0 + r1) / 2)
    return g


def prism(m, rim, thick, sw, inside):
    """A flat shape about Z stood `thick` along it: `rim` its corners in order, `inside` a point within it."""
    lo = [p + Vector((0, 0, -thick / 2)) for p in rim]
    hi = [p + Vector((0, 0, thick / 2)) for p in rim]
    m.out(hi, [kit.sw_uv(sw, 0.0, 0.9)] * len(rim), inside)
    m.out(lo, [kit.sw_uv(sw, 0.0, 0.9)] * len(rim), inside)
    for i in range(len(rim)):
        j = (i + 1) % len(rim)
        m.out([lo[i], lo[j], hi[j], hi[i]], [kit.sw_uv(sw, 0.0, 0.55)] * 4, inside)


def claw(r, reach=19.0, root=1.8, thick=0.5, n=5):
    """The collector's claw, about the wheel's Z (AR19's class fix, 2026-11-17, in place of the copper shoe): a flat
    claw of bone on the band's face, from the arm at the gauge's top down the band against the rising buckets,
    `reach` degrees, `root` wide across the band where it leaves the arm and pointed at its end. Flat to the gate, so
    its pale face reads from the player's camera: bone, since void stone is lost on the dark band. Unlit: a light at
    the gauge's top would read as the gauge full."""
    m = Mesh()
    a0 = GAUGE_TOP + 1.0
    angles = [a0 - reach * k / n for k in range(n + 1)]
    widths = [root * (1.0 - (k / n) ** 1.6) + 0.06 for k in range(n + 1)]

    def on(a, rr, z=0.0):
        return Vector((rr * math.cos(math.radians(a)), rr * math.sin(math.radians(a)), z))

    for k in range(n):
        a, b, wa, wb = angles[k], angles[k + 1], widths[k] / 2, widths[k + 1] / 2
        rim = [on(a, r - wa), on(b, r - wb), on(b, r + wb), on(a, r + wa)]
        prism(m, rim, thick, "bone", on((a + b) / 2, r))
    return m


def cage(m, x, y0, y1, z, stand_from):
    """Where the gear train's turning does the void's work (AR19's class fix, 2026-11-17, in place of the housed
    dynamo): a square back plate of void stone, four claws from its corners reaching toward the gate and closing
    round a floating shard of the void's light, a vein down each claw's inner edge to it, on a girder stand down to
    `stand_from`. The current leaves from a block on the plate's top. From the gate it's a square of claws round a
    lit diamond at the hub's height, as the square cage the content check passed was: never a drum."""
    s, mid = 3.6, (y0 + y1) / 2
    m.box((s, 0.6, s), (x, y0 + 0.3, z), "abyss", ink=True)
    for cx, cz in bm.SIGNS:
        claw = [(x + cx * 1.5, y0 + 0.6, z + cz * 1.5), (x + cx * 1.78, mid, z + cz * 1.78), (x + cx * 0.95, y1, z + cz * 0.95)]
        widths = [0.4, 0.34, 0.05]
        bm.horn(m, claw, widths, "abyss", flat=(-cz, 0.0, cx))
        bm.vein(m, claw[:2] + [(x + cx * 1.15, y1 - 0.5, z + cz * 1.15)], widths[:2] + [0.12], (x, mid, z), r=0.07)
    bm.shard(m, (x, mid + 0.3, z), 0.62, 2.5, "void", lean=0.55)
    m.box((1.2, 0.9, 0.6), (x, y0 + 0.45, z + s / 2 + 0.3), "girder", ink=True)          # where the current leaves
    high = z - s / 2 - stand_from
    m.box((2.6, 1.8, high), (x, y0 + 0.9, stand_from + high / 2), "girder", ink=True)


# --- the mill ----------------------------------------------------------------------------------------------------------

def size(stage):
    """The wheel's radius and its band's width: from Stage II the wheel is a twin, wider and a little taller."""
    return (11.6, 4.0) if stage == 1 else (12.2, 5.0)


def start(stage):
    """Where a bucket leaves the well on the gate's right: the angle about the wheel's own Z at which its rim clears
    the well's floor (1 up), and 3 more."""
    return 180.0 - math.degrees(math.asin((AXLE - 1.0) / size(stage)[0])) + 3.0


def span(stage):
    """The gauge's arc, in degrees: from the well to the collector's claw."""
    return GAUGE_TOP - start(stage)


def lit_to(share, stage):
    """The gauge (research's fix 1): the angle up to which the rising side is lit, from the well at a share of 0 to
    the collector's claw at 1."""
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
    m.box((1.25, 1.25, 0.06), out * (rail_radius(stage) + 0.51) + Vector((0, 0, front + 0.51)), "well",
          rot=(0.0, 0.0, a + math.pi / 4))                                           # the pip's dark bed (AR40)
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
    # where a claw of bone reaches down the band from it, against the rising buckets, and takes their light
    # (AR19's class fix, 2026-11-17: the claw and the bare arm in place of a copper shoe and an insulator; the claw
    # curves beside the arm, never behind it); it carries the rail's head beyond the rim
    phi = math.radians(GAUGE_TOP)
    dirn = Vector((math.cos(phi), 0.0, -math.sin(phi)))
    turn = (0.0, -math.atan2(dirn.z, dirn.x), 0.0)
    mid = r - DEEP / 2 - 0.3
    rr = rail_radius(stage)
    head = centre + Vector((0, yf, 0))
    tip, end = head + dirn * mid, head + dirn * rr
    m.box((1.0, 2.8, 1.6), head + dirn * 2.0, "steel", rot=turn, ink=True)                     # the clamp
    bar(m, head + dirn * 1.8, end, 1.2, "steel", d=0.9)
    bar(m, tip + Vector((0, -0.4, 0)), Vector((tip.x, front + 0.55, tip.z)), 0.8, "steel")     # the claw's holder
    put(m, claw(mid), at(0, front + 0.35, AXLE) @ FACING)
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
        shell = Mesh()
        ra, rb = r + 1.0, r + 2.0
        for k in range(14):
            a = math.radians(188 + k * 12 + 6)
            shell.box(((ra + rb) / 2 * 0.22 + 0.25, rb - ra, width + 1.6), Vector((math.cos(a), math.sin(a), 0.0)) * (ra + rb) / 2,
                      "steel", rot=(0.0, 0.0, a + math.pi / 2), ink=True)
        put(m, shell, face)
        put(m, windows(stage, [a for a in WINDOWS if a <= top], "void"), at(0, width / 2 + 0.85, AXLE) @ FACING)
        put(m, windows(stage, [a for a in WINDOWS if a > top], "dark"), at(0, width / 2 + 0.85, AXLE) @ FACING)
        # the crown (AR19's class fix, 2026-11-17, in place of rods with insulators): three horns of void stone each
        # side, rising from the casing along its radius and leaning a little toward the middle, the longest nearest it,
        # the top's middle open. Unlit: no vein, no glow at a tip
        for x, length in ((6.0, 4.6), (8.4, 3.8), (10.6, 3.0)):
            for sx in (-1, 1):
                a = math.asin(x / rb)
                out = Vector((sx * math.sin(a), 0.0, math.cos(a)))
                foot = Vector((0.0, -0.4, AXLE)) + out * (rb - 0.3)
                knee = foot + out * (length * 0.45)
                point = knee + (out + Vector((-sx * 0.35, 0.0, 1.0)).normalized()).normalized() * (length * 0.55)
                bm.horn(m, [tuple(foot), tuple(knee), tuple(point)], [0.5, 0.42, 0.05], "abyss", flat=(0.0, 1.0, 0.0), deep=1.4)
    if stage >= 2:
        # the cages the gear train drives, on their stands on the sill: Stage II's on the descending side, Stage III's
        # a second on the rising side; and the frame plated
        for sx in ((1,) if stage == 2 else (1, -1)):
            px, pz = pinion(sx)
            y0 = front + 1.4
            cage(m, px, y0, front + 5.6, pz, 1.4)
            cable(m, [(px, y0 + 0.45, pz + 2.4), (sx * 9.0, y0 + 0.45, pz + 2.4), (sx * 9.8, yf + 0.9, 1.4),
                      (sx * 11.4, -4.0, 0.3), (sx * 3.4, -18.0, 0.2)], r=0.3)
        for sx in (-1, 1):
            bar(m, (sx * 6.8, -13.2, 0.6), (sx * 1.9, back, AXLE - 0.4), 2.0, "steel", d=0.5)
    # the current: from the claw along the arm, round the bearing, down the trestle and away on the floor
    cable(m, [tuple(tip + Vector((0, 0.75, 0))), tuple(head + dirn * 2.4 + Vector((0, 0.75, 0))),
              (-2.8, yf + 0.8, AXLE - 0.4), (-2.8, yf + 0.8, AXLE - 2.6), (-3.9, yf + 0.8, 1.6),
              (-9.8, yf + 0.9, 1.4), (-11.4, -4.0, 0.3), (-3.4, -18.0, 0.2)], r=0.3)
    return m


WINDOWS = [194 + k * 11.5 for k in range(7)]   # Stage III's casing windows, degrees about the wheel's Z


def windows(stage, angles, sw, lift=0.0):
    """Stage III's casing windows at `angles`, about the wheel's Z, on the casing's front band; `lift` toward the gate."""
    r, width = size(stage)
    mid = r + 1.5
    band = Mesh()
    for a in angles:
        band.box((0.4, 1.6, 0.3), Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0.0)) * mid + Vector((0, 0, lift)),
                 sw, rot=(0.0, 0.0, math.radians(a)), occ=0.5)
    return band


CENTRES = 6.0                          # from the wheel's axle to a pinion's
GEAR = (CENTRES * 24 / 34, 24)         # the spur gear on the axle: its pitch radius, teeth
PINION = (CENTRES * 10 / 34, 10)       # a pinion: the pitch radii share the centres in the teeth's ratio, so they roll


def pinion(sx):
    """A pinion's axle, across and up: on the gear's rim, 30 degrees under the axle's level."""
    return sx * CENTRES * math.cos(math.radians(30.0)), AXLE - CENTRES * math.sin(math.radians(30.0))


def pinion_gear(sx):
    """A pinion about its own Z, turned so a gap between its teeth takes the gear's tooth where the two meet: the gear's
    teeth stand every 15 degrees from 0, so one points at each pinion (30 degrees about its Z on the descending side,
    150 on the rising), and the pinion's gap faces back along that line."""
    toward = 30.0 if sx > 0 else 150.0
    pitch = 360.0 / PINION[1]
    phase = (toward + 180.0 - pitch / 2) % pitch
    m = Mesh()
    put(m, toothed(PINION[0], PINION[1], 0.8, 0.5), Matrix.Rotation(math.radians(phase), 4, "Z"))
    return m


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
        put(m, toothed(GEAR[0], GEAR[1], 0.8, 1.0), at(0, front + 0.9, AXLE) @ FACING)
        for sx in ((1,) if stage == 2 else (1, -1)):
            px, pz = pinion(sx)
            put(m, pinion_gear(sx), at(px, front + 0.9, pz) @ FACING)
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
                      f"buckets rise on the gate's right and run under the collector's claw: in Roblox, "
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
                      f"claw, {rail_radius(1) + 0.51:.2f} from the axle, about "
                      f"{math.radians(span(1)) * (rail_radius(1) + 0.51):.0f} studs of travel. The share is on the "
                      f"gauge's own scale, the demand over the same top as the generation's, so the lit steps reach "
                      f"the mark when generation meets demand. Under a share of 0.12 it sinks into the well's kerb. "
                      f"Look only")


# --- the kit's pieces (Stages II and III) -------------------------------------------------------------------------------

def reach(stage):
    """How high the collector's arm reaches: the rail's head, beyond the rim."""
    return AXLE + rail_radius(stage) * -math.sin(math.radians(GAUGE_TOP)) + 0.6


def solid(stage):
    """What a player walks into, in the piece's frame: Stage I's, with the sill and the legs' heads where the wider
    wheel puts them. The cages stand on the sill inside the well's cylinder, and the casing and its crown overhead."""
    width = size(stage)[1]
    return (f"in the piece's frame (across, toward the gate, up): the well shut to walking, a cylinder of radius 10.6, "
            f"3 high, at the middle; the sill a box 22.4 across, 1.8 deep and 1.4 high, its middle "
            f"{width / 2 + REACH:g} toward the gate; each raked leg's foot a box 2.8 square, 1 high, at across +-7.6, 14 "
            f"back; each raked leg a Part 1.3 thick along its line, from (+-7.6, -14, 0.3) to "
            f"(+-1.5, {-width / 2 - 1.6:g}, {AXLE - 1.3:g}). The trestle and the cages stand on the sill, the arm"
            f"{', the casing and its crown' if stage == 3 else ''} over the well: look only")


def generator_stage(stage):
    def make():
        r, width = size(stage)
        grown = ("a twin wheel 24.4 across with two sets of spokes, the spur gear on its axle driving a pinion and its "
                 "void cage on the sill (the descending side): four claws round a lit shard; the back frame plated"
                 if stage == 2 else
                 "Stage II's, with the armoured half drum of a casing over the wheel and its crown of six unlit horns, "
                 "a second pinion and cage on the rising side; the casing's seven windows stand dark here: the gauge's "
                 "steps 5 to 8 (Generator3Arc5 to 8) carry the lit ones of the five over them, and the two past the "
                 "collector's claw stay dark")
        return Piece(f"Generator{stage}", still(stage),
                     solid=solid(stage),
                     note=f"Stage {'II' if stage == 2 else 'III'}'s still body, in place of Generator at the same place: "
                          f"{grown}. Its middle on the well's. The collector's arm reaches about {reach(stage):.1f} up"
                          f"{', the crown about 27.7' if stage == 3 else ''}. On the ground it stands where Stage I "
                          f"stands, its sill 0.5 nearer the gate. The well light stays: VoidWell, 1.6 up "
                          f"in its middle")
    return make


def generator_wheel_twin():
    m = Mesh()
    put(m, wheel(2), FACING)
    put(m, toothed(GEAR[0], GEAR[1], 0.8, 1.0), at(0, size(2)[1] / 2 + 0.9, 0) @ FACING)
    return Piece("Generator2Wheel", m,
                 note=f"Stages II and III: the twin wheel, 24.4 across, with the spur gear ({GEAR[1]} teeth) on its axle "
                      f"in front of the hub, which turns with it. As GeneratorWheel: its origin is its axle's middle, "
                      f"{AXLE:g} up at the generator's middle, its axle along the piece's Y (Roblox's Z), the line to "
                      f"the gate; from the gate it turns anticlockwise, CFrame.Angles(0, 0, -angle) with the angle "
                      f"growing. Its lower edge runs 2.2 under the floor, inside the well's dark")


def generator_pinion(stage, sx):
    px, pz = pinion(sx)
    side = "descending" if sx > 0 else "rising"
    ratio = GEAR[1] / PINION[1]

    def make():
        m = Mesh()
        put(m, pinion_gear(sx), FACING)
        return Piece(f"Generator{stage}Pinion", m,
                     note=f"the pinion on the {side} side ({PINION[1]} teeth), meshing with the wheel's gear: its origin "
                          f"on its own axle, {px:+.3f} across, {size(2)[1] / 2 + 0.9:g} toward the gate and {pz:g} up "
                          f"from the generator's place, its axle along the piece's Y like the wheel's. It turns the "
                          f"other way, {ratio:g} times as fast: CFrame.Angles(0, 0, angle * {ratio:g}) with the wheel's "
                          f"angle. Made with its teeth meshed at the wheel's angle 0")
    return make


def arc_stage(stage, i):
    def make():
        width = size(stage)[1]
        d = span(stage) / STEPS
        lo, hi = start(stage) + i * d, start(stage) + (i + 1) * d
        m = put_still(arc_step(stage, i))
        mine = [a for a in WINDOWS if lo < a <= hi] if stage == 3 else []
        if mine:   # its casing windows, lit, just in front of the dark ones in Generator3
            put(m, windows(stage, mine, "void", lift=0.06), at(0, width / 2 + 0.85, AXLE) @ FACING)
        return Piece(f"Generator{stage}Arc{i + 1}", m,
                     note=f"Stage {'II' if stage == 2 else 'III'}'s gauge, step {i + 1} of {STEPS}: the generation's "
                          f"share from {i / STEPS:g} to {(i + 1) / STEPS:g}, {lo:.1f} to {hi:.1f} degrees about the "
                          f"axle{f', with {len(mine)} of the casing windows over it' if mine else ''}. As GeneratorArc"
                          f"{i + 1}: still, at the generator's place; light the first k, k the share times {STEPS} "
                          f"rounded, shown or hidden, never dimmed. Look only")
    return make


def demand_stage(stage):
    def make():
        m = Mesh()
        put(m, demand_mark(stage), FACING)
        rr = rail_radius(stage) + 0.51
        return Piece(f"Generator{stage}Demand", m,
                     note=f"Stage {'II' if stage == 2 else 'III'}'s demand mark, as GeneratorDemand: its origin on "
                          f"the axle, {AXLE:g} up, made at a share of 0 by the well, turned about the axle by the share "
                          f"times {span(stage):.1f} degrees (CFrame.Angles(0, 0, -share * math.rad({span(stage):.1f})))"
                          f", {rr:.2f} from the axle{', outside the casing' if stage == 3 else ''}. Look only")
    return make


def stages():
    """The swap's table: each stage's pieces, where each stands from the generator's place (across, toward the gate,
    up), and how it moves. `rate` is a turning piece's against the wheel's angle: CFrame.Angles(0, 0, -angle * rate)."""
    table = {}
    for stage in (1, 2, 3):
        tag = "" if stage == 1 else str(stage)
        front = size(stage)[1] / 2 + 0.9
        rows = [dict(piece=f"Generator{tag}", at=[0.0, 0.0, 0.0], moves="still")]
        rows.append(dict(piece="GeneratorWheel" if stage == 1 else "Generator2Wheel", at=[0.0, 0.0, AXLE],
                         moves="turns", rate=1.0))
        for sx in (() if stage == 1 else (1,) if stage == 2 else (1, -1)):
            px, pz = pinion(sx)
            rows.append(dict(piece="Generator2Pinion" if sx > 0 else "Generator3Pinion",
                             at=[round(px, 3), front, round(pz, 3)], moves="turns", rate=-GEAR[1] / PINION[1]))
        rows += [dict(piece=f"GeneratorArc{i + 1}" if stage == 1 else f"Generator{stage}Arc{i + 1}", at=[0.0, 0.0, 0.0],
                      moves="gauge", step=i + 1) for i in range(STEPS)]
        rows.append(dict(piece=f"Generator{tag}Demand", at=[0.0, 0.0, AXLE], moves="demand",
                         degrees=round(span(stage), 2)))
        table[str(stage)] = rows
    return table


PIECES = {"Generator": generator, "GeneratorWheel": generator_wheel,
          **{f"GeneratorArc{i + 1}": generator_arc(i) for i in range(STEPS)}, "GeneratorDemand": generator_demand,
          "Generator2": generator_stage(2), "Generator3": generator_stage(3), "Generator2Wheel": generator_wheel_twin,
          "Generator2Pinion": generator_pinion(2, 1), "Generator3Pinion": generator_pinion(3, -1),
          **{f"Generator{st}Arc{i + 1}": arc_stage(st, i) for st in (2, 3) for i in range(STEPS)},
          "Generator2Demand": demand_stage(2), "Generator3Demand": demand_stage(3)}
