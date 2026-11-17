"""AR15: the base's machines (docs/asset-requests.md), one at a time. Each stands where the builder's stand-in stands
(WorldService.plot), on the same footprint, so an install moves no rule; the generator alone outgrows its own.

They are base_kit.py's pieces like the others: on the kit's own atlas, a piece's front toward +Y (the Strip), its
origin on the floor at the stand-in's middle, one unit a stud. What a machine does shows in its own light, which the
builder turns up and down by the piece's EmissiveStrength.

Three of them are void machines (the director, 2026-11-15: the bay "should be a magic void like machine cause it
"take the power" of a voidkin who is placed there"; "the generator should a lot bigger and anime like but i like that
it keep this 3d animation like moving"; "the void breaker need to turn from that electricity machine into a
voidbreaker like machines"). One language for the three, set on the yard's steel: horns of dark void stone with a
vein of the void's violet, and what they hold floats between them and turns. The yard round them stays a power yard.

The Void Breaker (`Breaker`, `BreakerChamber`, `BreakerWaiting`): a block of void stone under two jaws that close
over the chambers, a fang reaching down into each, and the Breaker's crystal floating between the jaws' tips. The
break is cyan, the Breaker's own colour. A chamber is its own piece, stood once a chamber the base has, so each can
be lit by itself: bright while it breaks a shard, low when it's empty.

An extraction bay (`Bay`, `BayHalo`): a dais over a small well of void where the worker stands, and on its outer
side a crescent of two horns holding an eye, a ring round a floating shard, over the worker's head: what draws the
power out. The bay's own light is a piece by itself, in one pale swatch, so the builder gives it the worker's rarity
colour (TR22): a ring round the worker's feet, a ring in the eye, and motes rising from the worker to it.

The generator is the Void Mill (AR19): its own module, base_mill.py, whose pieces base_kit.py takes beside these.

The battery (`BatteryRack`, `BatteryCell`): a bank, the yard's own. A low rack with eight seats and a bus bar down its
middle, and a cell a seat as the battery's cap grows with the base's level (research, 2026-11-15: 60, 150 and 400
kWh), two, four and eight. A cell is its own piece, so the bank is its own meter: the builder lights the cells one
after another as the charge rises.

The Festival Door (`Door`, `DoorRing1` to `DoorRing4`, `DoorWay`; AR15, section 7): a ring tunnel. An upright ring of
void stone on a low step, its opening the way a player walks into, and four thinner rings floating behind it, each
further back, a little higher and aside, turning about the tunnel's axis each its own way, down to a warm core. Its
lines of light are the one warm light in the base: amber at the mouth, paler ring by ring to the core's pale gold.

The Training machine (`Training`, `TrainingCrown`): a sparring stone. A standing stone of void stone with blunt pegs
toward the one who trains, a target of the void's light floating before its face, and a pad out in front where the
Voidkin stands. Over the stone floats its crown, a ring with four weights of void stone round a spark, a piece by
itself that the builder turns while a Voidkin trains.

What the base will wake stands asleep where it will stand (`BaySleeping`, `SleepingStone`; research, 2026-11-16):
dark and unlit, lying low, never a building site. A sleeping bay is a bay folded down: its horns and its eye's hoop
lie on its dais. A sleeping stone is four fangs folded flat in two bars on a pad, for a machine that has no model yet.

Not run by itself: base_kit.py takes PIECES into its own.
"""

import math
import sys
from pathlib import Path

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_ink as ink  # noqa: E402
import lantern_row_kit as kit  # noqa: E402

Mesh, Piece = ink.Mesh, kit.Piece   # the kit's mesh, with the base's thinner hull
SIGNS = ((1, 1), (-1, 1), (-1, -1), (1, -1))
EDGES = ((1, 0), (0, 1), (-1, 0), (0, -1))
ROUND = ("+x", "-x", "+y", "-y")

# The Breaker's stand-in, the builder's (Faber, 2026-11-15): the body, and the chambers' middles on its top
BODY = (14.0, 6.0, 5.0)          # across, deep, high
CHAMBERS = (3.5, 7.0, 4.0)       # a chamber's middle: across (each side), up; and its cube's side
GAP = (5.85, 8.35)               # the shard's room in a chamber, between the two points: from, to (up from the floor)
BAY = (10.0, 0.4)                # a bay's stand-in, its pad: its side and its height
HALO = (8.0, 1.7, 2.0)           # a bay's eye: its middle up from the floor, its ring's inner and outer radius
BANK = (6.0, 4.0, 3.0)           # the battery's stand-in: across, deep, high
SEAT = 0.6                       # a cell's seat on the rack, up from the floor
# a cell's seat on the rack, across and toward the Strip, in the order the bank fills: the spawn's row first, from
# the middle out
SEATS = [(-0.75, -0.95), (0.75, -0.95), (-0.75, 0.95), (0.75, 0.95), (-2.25, -0.95), (2.25, -0.95), (-2.25, 0.95), (2.25, 0.95)]
CELLS_AT = {1: 2, 2: 4, 3: 8}    # cells by the base's level, with the battery's cap
CROWN = 8.0                      # the Training machine's crown: its middle, up from the floor
TRAINEE = 6.0                    # the Training machine's pad: its middle, out from the stone's toward the piece's front
TOWER = 172.0                    # the sleeping Tower's tip


def insulator(m, at, length, r=0.34, ribs=3, sides=5):
    """A ribbed ceramic stack standing up from `at`, as the kit's."""
    step = length / ribs
    profile = []
    for i in range(ribs):
        z = length - i * step
        profile += [(r * 0.45, z), (r, z - step * 0.4), (r * 0.45, z - step * 0.8)]
    profile.append((r * 0.45, 0.0))
    m.lathe(profile, at, sides, "ceramic")


# --- void stone's shapes -----------------------------------------------------------------------------------------------

def horn(m, points, radii, sw, flat=(0.0, 1.0, 0.0), deep=1.0, ink=True):
    """Void stone's own shape: a four-edged shaft swept along `points`, an edge toward each side, `radii[k]` its half
    width at each point. The points lie in one plane and `flat` is the line across that plane; the shaft's half depth
    along it is its half width times `deep`. A point at an end makes a fang or a horn's tip; three points with a wide
    middle make a shard. With `ink`, its drawn edge."""
    pts = [Vector(p) for p in points]
    across = Vector(flat).normalized()
    last = len(pts) - 1
    edge = m.ink_t if ink and m.ink is not None else None

    def section(k, grow):
        along = (pts[min(k + 1, last)] - pts[max(k - 1, 0)]).normalized()
        n = across.cross(along).normalized()
        at = pts[k] + along * (grow if k == last else -grow if k == 0 else 0.0)
        return [at + n * ((radii[k] + grow) * sx) + across * ((radii[k] * deep + grow) * sy) for sx, sy in EDGES]

    for grow, hull in ((0.0, False),) + (((edge, True),) if edge else ()):
        rings = [section(k, grow) for k in range(len(pts))]
        for k in range(last):
            mid = (pts[k] + pts[k + 1]) / 2
            for i in range(4):
                j = (i + 1) % 4
                uvs = [(0, 0)] * 4 if hull else [kit.sw_uv(sw, 0.0, q / last) for q in (k, k, k + 1, k + 1)]
                m.out([rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]], uvs, mid, ink=hull)
        for k, inside in ((0, (pts[0] + pts[1]) / 2), (last, (pts[last] + pts[last - 1]) / 2)):
            if hull or radii[k] > 0.08:
                uvs = [(0, 0)] * 4 if hull else [kit.sw_uv(sw, 0.5, k / last)] * 4
                m.out(rings[k], uvs, inside, ink=hull)


def well(m, at, r, sides=12, sw="dark"):
    """A well's dark floor on a dais, `at` the dais's foot: one flat face a hair over the dais's top. It has no wall:
    a wall that thin maps the whole swatch onto a sliver, which a distance blurs into its lit neighbours."""
    x, y, z = at
    m.face([Vector((x + r * math.cos(math.tau * i / sides), y + r * math.sin(math.tau * i / sides), z + 0.19))
            for i in range(sides)], [kit.sw_uv(sw, 0.5, 1.0)] * sides)


def shard(m, at, r, high, sw, lean=0.5, ink=False):
    """A floating shard, its widest at `at`: a point up and a point down, the lower one the shorter."""
    x, y, z = at
    horn(m, [(x, y, z - high * (1 - lean)), at, (x, y, z + high * lean)], [0.04, r, 0.04], sw, ink=ink)


def vein(m, points, radii, heart, sw="void", r=0.1):
    """A line of the void's light along a horn's edge, the one that looks at `heart`."""
    heart = Vector(heart)
    m.tube([Vector(p) + (heart - Vector(p)).normalized() * q * 0.97 for p, q in zip(points, radii)], r, sw)


def hoop(m, at, r0, r1, thick, sides, sw, ink=True, lying=False):
    """A ring about X, or about Z when `lying`, its middle at `at`: a band from `r0` out to `r1`, `thick` along its
    axle. With `ink`, its drawn edge."""
    at = Vector(at)
    edge = m.ink_t if ink and m.ink is not None else None

    def corner(r, h, a):
        if lying:
            return at + Vector((r * math.cos(a), r * math.sin(a), h))
        return at + Vector((h, -r * math.sin(a), r * math.cos(a)))

    for grow, hull in ((0.0, False),) + (((edge, True),) if edge else ()):
        near, far, half = r0 - grow, r1 + grow, thick / 2 + grow
        walls = (((far, -half), (far, half)), ((far, half), (near, half)), ((near, half), (near, -half)), ((near, -half), (far, -half)))
        for i in range(sides):
            a, b = math.tau * i / sides, math.tau * (i + 1) / sides
            core = corner((r0 + r1) / 2, 0.0, (a + b) / 2)
            for face, ((ra, ha), (rb, hb)) in enumerate(walls):
                uvs = [(0, 0)] * 4 if hull else [kit.sw_uv(sw, 0.0, (0.9, 0.55, 0.25, 0.55)[face])] * 4
                m.out([corner(ra, ha, a), corner(rb, hb, a), corner(rb, hb, b), corner(ra, ha, b)], uvs, core, ink=hull)


def ring(m, x, z, r0, r1, thick, sides, sw):
    """A flat ring stood on its edge, its axle along X, its middle at (x, 0, z): seen from both sides."""
    turned = Mesh(None)
    turned.lathe([(r0, 0.0), (r0, thick), (r1, thick), (r1, 0.0), (r0, 0.0)], (0, 0, 0), sides, sw, caps=False)
    for face, uv in zip(turned.f, turned.uv):                      # the lathe's Z laid along X
        m.face([(x + turned.v[i][2] - thick / 2, turned.v[i][1], z - turned.v[i][0]) for i in face], uv)


def laid(m, turned, z):
    """A shape turned about Z, laid along X: its heights become its places across, its axle `z` up."""
    for face, uv in zip(turned.f, turned.uv):
        m.face([(turned.v[i][2], turned.v[i][1], z - turned.v[i][0]) for i in face], uv)


# --- the Void Breaker --------------------------------------------------------------------------------------------------

def breaker():
    """The Void Breaker's body: a block of void stone on a steel plinth, 14 studs by 6 and 5 high as the stand-in is,
    a line of the break's cyan round its foot and the void's veins on its faces. Over it two jaws, a horn rising from
    each end and closing over the chambers to 12.6, a fang reaching down from each into its chamber, and between the
    jaws' tips the Breaker's crystal, floating. Both long faces are fronts: the Strip sees one, the spawn the other."""
    m = Mesh()
    wide, deep, high = BODY
    m.box((wide + 0.6, deep + 0.6, 0.6), (0, 0, 0.3), "girder", ink=True)
    m.box((wide + 0.2, deep + 0.2, 0.16), (0, 0, 0.74), "cyan")
    m.box((wide, deep, 3.4), (0, 0, 2.8), "abyss", ink=True)
    m.box((wide + 0.4, deep + 0.4, 0.5), (0, 0, high - 0.25), "bone", ink=True)
    across, up, side = CHAMBERS
    for sy in (-1, 1):
        y = sy * (deep / 2 + 0.03)
        m.box((2.6, 0.16, 2.4), (0, y, 2.9), "dark")                                 # the core's window, the void in it
        m.box((0.34, 0.2, 1.9), (0, y + sy * 0.02, 2.9), "cyan")
        for sx in (-1, 1):
            m.box((4.6, 0.14, 0.2), (sx * 4.3, y, 4.1), "void")                      # the void's veins, in along the block
            m.box((0.2, 0.14, 1.4), (sx * 1.9, y, 3.5), "void")                      # and down into the core
            m.box((0.2, 0.14, 1.9), (sx * 6.5, y, 3.25), "void")
    for sx in (-1, 1):                                                               # the rail's coupling at each end
        m.box((0.5, 2.2, 1.8), (sx * (wide / 2 + 0.2), 0, 2.0), "girder", ink=True)
        m.box((0.14, 1.4, 0.24), (sx * (wide / 2 + 0.47), 0, 2.0), "cyan")
    # the jaws: a horn from each end, closing over the chambers; a fang down into each
    for sx in (-1, 1):
        jaw = [(sx * 6.6, 0, high), (sx * 7.5, 0, 8.4), (sx * 6.0, 0, 11.4), (sx * 2.0, 0, 12.6)]
        widths = [0.85, 0.8, 0.6, 0.06]
        m.box((1.9, 2.2, 0.4), (sx * 6.6, 0, high + 0.2), "girder", ink=True)
        horn(m, jaw, widths, "abyss", deep=0.8)
        vein(m, jaw[:3] + [(sx * 3.4, 0, 12.18)], widths[:3] + [0.3], (0, 0, 8.0))
        horn(m, [(sx * 3.9, 0, 11.9), (sx * across, 0, GAP[1] + 0.12)], [0.5, 0.05], "abyss")
        m.box((0.22, 0.22, 0.2), (sx * across, 0, GAP[1] + 0.06), "cyan")
    # the middle: a seat between the chambers, a point standing on it, and the crystal over it, between the jaws' tips
    m.box((1.7, 1.7, 0.8), (0, 0, high + 0.4), "abyss", ink=True)
    horn(m, [(0, 0, high + 0.8), (0, 0, high + 2.3)], [0.5, 0.05], "abyss")
    shard(m, (0, 0, 10.2), 1.15, 5.2, "cyan")
    return Piece("Breaker", m, solid="a box, 14 by 6, 5 high, and the jaws' two feet",
                 note=f"on the stand-in's footprint, 12.8 high. A chamber stands at across {across:g} each side, its "
                      f"foot on the body's top at {high:g}. The crystal is the Breaker's lamp, its middle 10.2 up, where "
                      f"the builder's BreakerLamp is")


def breaker_chamber():
    """One chamber, its foot on the Breaker's top: a seat of void stone with a cyan line round it, four claws standing
    from its corners and closing a little over it, and its own point standing up from the seat. The shard sits
    between that point and the jaw's fang. Its glow is the chamber's state."""
    m = Mesh()
    _, up, side = CHAMBERS
    foot = BODY[2]
    half = side / 2 - 0.15
    m.box((side + 0.2, side + 0.2, 0.3), (0, 0, 0.15), "abyss", ink=True)
    m.box((3.0, 3.0, 0.1), (0, 0, 0.35), "dark")
    for s in (-1, 1):
        m.box((3.4, 0.14, 0.12), (0, s * 1.75, 0.36), "cyan")
        m.box((0.14, 3.4, 0.12), (s * 1.75, 0, 0.36), "cyan")
    for sx, sy in SIGNS:
        horn(m, [(sx * half, sy * half, 0.3), (sx * (half + 0.2), sy * (half + 0.2), 2.2), (sx * (half - 0.7), sy * (half - 0.7), side - 0.1)],
             [0.32, 0.28, 0.05], "abyss", flat=(sx, -sy, 0.0))
    horn(m, [(0, 0, 0.4), (0, 0, GAP[0] - foot - 0.12)], [0.46, 0.05], "abyss")
    m.box((0.22, 0.22, 0.2), (0, 0, GAP[0] - foot - 0.06), "cyan")
    return Piece("BreakerChamber", m,
                 note=f"its place is the chamber's middle across, on the body's top ({foot:g} up): the stand-in's cube "
                      f"from {up - side / 2:g} to {up + side / 2:g}. The shard's room is between the points, "
                      f"{GAP[0]:g} to {GAP[1]:g} up, its middle at {sum(GAP) / 2:g}. Look only")


def breaker_waiting():
    """A place in the waiting line: a low cradle of void stone on a steel foot, a cyan mark on its tray."""
    m = Mesh()
    m.box((2.5, 2.5, 0.4), (0, 0, 0.2), "girder", ink=True)
    m.box((2.1, 2.1, 0.4), (0, 0, 0.6), "abyss", ink=True)
    m.box((1.5, 1.5, 0.08), (0, 0, 0.84), "dark")
    for s in (-1, 1):
        m.box((2.1, 0.2, 0.3), (0, s * 0.95, 0.95), "bone")
    m.box((0.5, 0.5, 0.06), (0, 0, 0.9), "cyan")
    return Piece("BreakerWaiting", m, solid="a box, 2.5 square, 1 high",
                 note="on the stand-in's pad, 2.5 square and 1 high; a waiting shard stands on its tray, 0.9 up")


# --- an extraction bay -------------------------------------------------------------------------------------------------

def bay():
    """An extraction bay: the stand-in's pad, 10 studs square and 0.4 high, as a steel deck with a line of the void's
    light round its foot; on it a dais of void stone round a small dark well, where the worker stands. On its outer
    side (-X) a crescent, two horns rising from the deck and closing over the worker's head, holds the eye between
    its tips: a ring of void stone round a floating shard, which draws the worker's power out. What the eye takes
    leaves as current, in yellow, at the crescent's foot. The other three sides stay open: a low fang and a mote mark
    each inner corner."""
    m = Mesh()
    side, top = BAY
    back, eye = -(side / 2 - 0.55), HALO[0]
    m.box((side, side, top), (0, 0, top / 2), "girder", ink=True)
    m.box((side + 0.1, side + 0.1, 0.1), (0, 0, 0.2), "void")
    m.lathe([(4.1, 0.16), (4.3, 0.0)], (0, 0, top), 12, "abyss")
    m.lathe([(3.55, 0.17), (3.85, 0.17)], (0, 0, top), 12, "void", caps=False)        # the dais's line of light
    well(m, (0, 0, top), 2.6)                      # the well under the worker's feet
    m.box((1.3, side - 1.2, 0.6), (back, 0, top + 0.3), "abyss", ink=True)            # the crescent's foot, along the back
    for sy in (-1, 1):
        arm = [(back, sy * 3.7, top + 0.5), (back, sy * 4.9, 3.6), (back, sy * 4.3, 6.9), (back, sy * 2.3, 9.4)]
        widths = [0.8, 0.72, 0.5, 0.05]
        horn(m, arm, widths, "abyss", flat=(1.0, 0.0, 0.0), deep=0.75)
        vein(m, arm[:3] + [(back, sy * 3.2, 8.4)], widths[:3] + [0.25], (back, 0, 5.5), r=0.08)
        # an inner corner's fang and its mote: low, so nothing stands between the court and the worker
        horn(m, [(4.35, sy * 4.35, top), (3.75, sy * 3.75, top + 1.7)], [0.42, 0.05], "abyss", flat=(sy, -1.0, 0.0))
        shard(m, (3.6, sy * 3.6, top + 2.55), 0.24, 0.9, "void")
    hoop(m, (back, 0, eye), HALO[1], HALO[2], 0.4, 12, "abyss")
    shard(m, (back, 0, eye), 0.8, 3.0, "void", lean=0.55)
    m.box((0.9, 1.6, 1.0), (back + 0.3, 0, top + 0.5), "girder", ink=True)            # where the current leaves
    m.box((0.1, 1.0, 0.2), (back + 0.78, 0, top + 0.6), "power")
    return Piece("Bay", m, solid="a box, 10 square, 0.4 high, and the crescent's two feet",
                 note=f"on the stand-in's pad, 9.4 high at its horns' tips. Its crescent stands on -X: turn 0 on the "
                      f"plot's left, 180 on its right, so the eye is on the outer side and the worker is seen under it "
                      f"from the court and the gate. The worker stands at the pad's middle; the eye's middle is {eye:g} up")


def bay_halo():
    """A working bay's own light, a piece by itself: a ring round the worker's feet on the dais, a ring in the eye
    round its shard, and three motes drawn from over the worker's head into the eye, growing as they near it: the
    worker's power, drawn out. Every face is one pale swatch, so the builder gives it the worker's rarity colour
    (docs/test-requests.md, TR22) and takes it away when the bay is empty."""
    m = Mesh(None)
    side, top = BAY
    back, eye = -(side / 2 - 0.55), HALO[0]
    ring(m, back + 0.02, eye, HALO[1] - 0.42, HALO[1] - 0.08, 0.14, 12, "lamp")
    m.lathe([(2.75, 0.2), (3.05, 0.2)], (0, 0, top), 12, "lamp", caps=False)
    for x, z, r in ((-1.5, 8.25, 0.16), (-2.4, 8.15, 0.22), (-3.3, 8.05, 0.28)):   # over the tallest Voidkin's hat (Pip, 7.37: Faber's measure)
        shard(m, (x, 0, z), r, r * 3.4, "lamp")
    return Piece("BayHalo", m, lights=[("Rarity", (back + 1.4, 0.0, eye - 0.6), "#F6FCFF")],
                 note="stands where its Bay stands, the same turn, only while a worker works there. One pale swatch on "
                      "every face: the worker's rarity colour is the builder's (a tint, or the mesh in Neon without "
                      "the kit's pictures). Its light is a PointLight in the same colour, the first to go if the "
                      "plot's lights weigh. Look only")


def bay_sleeping():
    """A bay asleep, on a bay's own pad and turn, lying low: the same deck and dais, dark, and what the bay raises
    folded down on it. The crescent's two horns lie along its foot at the pad's back, tip to tip; the eye's hoop
    lies flat round the well, empty: its shard forms when the bay wakes. Nothing stands upright and nothing is lit
    (research, 2026-11-16). It lifts and lights into a Bay when its level wakes it."""
    m = Mesh()
    side, top = BAY
    back, lies = -(side / 2 - 0.55), top + 0.16
    m.box((side, side, top), (0, 0, top / 2), "girder", ink=True)
    m.lathe([(4.1, 0.16), (4.3, 0.0)], (0, 0, top), 12, "abyss")
    well(m, (0, 0, top), 2.6)
    m.box((1.3, side - 1.2, 0.6), (back, 0, top + 0.3), "abyss", ink=True)
    for sy in (-1, 1):
        horn(m, [(back + 1.25, sy * 4.3, lies + 0.4), (back + 1.45, sy * 2.6, lies + 0.4), (back + 1.3, sy * 0.25, lies + 0.4)],
             [0.7, 0.58, 0.05], "abyss", flat=(0.0, 0.0, 1.0), deep=0.55)
    hoop(m, (0.6, 0, lies + 0.2), HALO[1], HALO[2], 0.4, 12, "abyss", lying=True)
    return Piece("BaySleeping", m, solid="a box, 10 square, 0.4 high; the rest is under a stud high",
                 note="stands where a Bay will stand, the same turn, until the base's level wakes that bay; then the "
                      "Bay takes its place. It lies low, about 1.5 high. Nothing on it glows")


def sleeping_stone():
    """A machine asleep, for one that has no model yet, lying low: a steel pad with a dais of void stone round a dark
    well, and four fangs folded flat on it in two bars, one along each side of the pad, each two fangs laid tip to
    tip. Nothing stands upright and nothing is lit (research, 2026-11-16). The fangs never lie as spokes: from
    above, four spokes through the dais are a cross in a ring (Modulo's read of the view from straight above)."""
    m = Mesh()
    lies = 0.56
    m.box((9.0, 9.0, 0.4), (0, 0, 0.2), "girder", ink=True)
    m.lathe([(2.9, 0.16), (3.1, 0.0)], (0, 0, 0.4), 12, "abyss")
    well(m, (0, 0, 0.4), 1.9)
    for sx, sy in SIGNS:
        horn(m, [(sx * 3.75, sy * 4.1, lies + 0.4), (sx * 3.8, sy * 2.3, lies + 0.4), (sx * 3.75, sy * 0.2, lies + 0.4)],
             [0.68, 0.56, 0.05], "abyss", flat=(0.0, 0.0, 1.0), deep=0.55)
    return Piece("SleepingStone", m, solid="a box, 9 square, 0.4 high; the rest is under a stud high",
                 note="stands where a machine the base hasn't woken will stand (plan.json, layout, sleeping), until "
                      "that machine has its model and its phase. It lies low, about 1.5 high. Nothing on it glows")


def tower_sleeping():
    """The Tower, asleep, behind the back wall on the base's middle line: one silhouette in four tiers, broad
    and tall enough to read over the generator from the way in, and a faint shard of its own light over its tip. It has no
    name and no detail: phase 3 designs the Tower (research, 2026-11-16)."""
    m = Mesh(None)
    q = math.sqrt(2.0)
    tiers = [(0.6, TOWER), (3.0, TOWER - 22.0), (5.6, TOWER - 22.0), (6.6, 130.0), (9.0, 130.0), (10.0, 94.0), (12.6, 94.0), (14.0, 0.0)]
    m.lathe([(half * q, z) for half, z in tiers], (0, 0, 0), 4, "tower", spin=math.pi / 4)   # AR20: a violet slate, not black
    shard(m, (0, 0, TOWER + 6.0), 2.0, 7.5, "dawn")
    return Piece("TowerSleeping", m, solid="a box, 28 square, as high as it needs; nobody reaches it yet",
                 note=f"stands behind the back wall on the plot's middle line, on the Tower's own lot: {TOWER:g} high "
                      f"at its tip, 28 square at its foot. A violet slate, unlit but for the shard over its tip. No hull")


# --- the battery -------------------------------------------------------------------------------------------------------

def battery_deck(m):
    """The battery's deck, every stage's: on the stand-in's footprint, 6 studs by 4, a groove of void stone down its
    middle with the current's line in it, and a squared post of void stone at each end with its light. AR19's note,
    made in AR34: the copper bar and the insulators are gone, and so are the seats' plates, since the cells now stand
    in the stack's tiers (base_battery.py)."""
    wide, deep, _ = BANK
    m.box((wide + 0.3, deep + 0.3, 0.3), (0, 0, 0.15), "concrete", ink=True)
    m.box((wide, deep, 0.3), (0, 0, 0.45), "girder", ink=True)
    m.box((wide - 0.5, 0.34, 0.14), (0, 0, SEAT + 0.07), "abyss")
    m.box((wide - 0.9, 0.12, 0.05), (0, 0, SEAT + 0.165), "power")
    for sx in (-1, 1):
        x = sx * (wide / 2 - 0.22)
        m.box((0.42, 0.42, 2.45 - SEAT), (x, 0, (SEAT + 2.45) / 2), "abyss", ink=True)
        m.box((0.24, 0.24, 0.2), (x, 0, 2.55), "power")


def battery_rack():
    """The battery's Stage I (AR34): the deck, its two cells standing on it at the stack's foot."""
    m = Mesh()
    battery_deck(m)
    return Piece("BatteryRack", m, solid="a box, 6 by 4, 3 high",
                 note=f"Stage I, base level 1: on the stand-in's footprint, 2.65 high at its posts. Its cells stand "
                      f"{SEAT:g} up, on the seats machines.batteryStages gives each stage (AR34)")


def battery_cell():
    """One cell of the bank, its origin on its seat: a steel body with a bone cap and a ceramic terminal, and on the
    two faces the spawn and the Strip see a dark window with the charge's line in the current's yellow."""
    m = Mesh()
    m.box((1.2, 1.44, 1.5), (0, 0, 0.75), "steel", ink=True)
    m.box((1.3, 1.54, 0.2), (0, 0, 1.6), "bone", ink=True)
    for sy in (-1, 1):
        m.box((0.56, 0.08, 1.14), (0, sy * 0.73, 0.76), "dark")
        m.box((0.26, 0.1, 0.94), (0, sy * 0.75, 0.76), "power")
    m.box((0.4, 0.4, 0.3), (0, 0, 1.85), "ceramic")
    m.box((0.22, 0.22, 0.16), (0, 0, 2.08), "power")
    return Piece("BatteryCell", m,
                 note=f"its origin is its seat on the rack, {SEAT:g} up; 2.16 high above it. Its glow is its own "
                      f"charge: the builder lights the cells in the seats' order as the battery fills. Look only")


# --- the Festival Door -------------------------------------------------------------------------------------------------
# C, the ring tunnel (AR15, section 7: research's pick, 2026-11-17), with five rings, in take A's colours: warm all
# through. Its front is its mouth, toward -Y: at the plan's turn of 90 it looks down the way in.

MOUTH = (5.6, 6.4, 5.0, -1.0, 0.6)   # the front ring: its middle up from the floor, its outer and inner radius, its front and back along Y
STEP = (14.0, 4.0, 0.6, -0.6)         # the step it stands on: across, deep, high, and its middle along Y
# The rings behind, each its own piece turning about the tunnel's axis: how far back, its radius, its turn (degrees a
# second, anticlockwise seen from the mouth: they alternate, faster the deeper), and its three arcs (from, to, in degrees
# anticlockwise from across). Each stands a little aside and higher than the one before (DRIFT), so the tunnel drifts.
RINGS = ((1.7, 5.3, 9.0, (20, 135, 150, 262, 280, 350)), (3.0, 4.4, -14.0, (70, 170, 190, 300, 318, 410)),
         (4.1, 3.6, 20.0, (-30, 95, 112, 200, 222, 316)), (5.0, 2.9, -28.0, (40, 150, 168, 280, 296, 388)))
DRIFT = (0.25, 0.35)                  # a ring's step aside and up from the one before
CORE = (5.9, 2.4)                     # the core, where a fifth ring would stand: how far back, its radius
LINE = (0.22, 0.2)                    # a line of light: its width on the face, and its lip's depth back along the edge
NAME = (5.0, 0.5, 1.3)                # the name's plate, sunk into the front ring's crown: across, deep, high


def ring_at(k):
    """The middle of ring `k` (1 to 4; 5 is the core), in the Door's own frame: across, along its Y, up."""
    y = RINGS[k - 1][0] if k <= len(RINGS) else CORE[0]
    return (DRIFT[0] * k, y, MOUTH[0] + DRIFT[1] * k)


def _arc(r, a0, a1, n=36):
    """Points on a circle round the origin in X and Z, from a0 to a1 degrees; and whether it is whole."""
    whole = a1 - a0 >= 360.0
    steps = n if whole else max(2, round(n * (a1 - a0) / 360.0))
    pts = [(r * math.cos(math.radians(a0 + (a1 - a0) * i / steps)), r * math.sin(math.radians(a0 + (a1 - a0) * i / steps)))
           for i in range(steps if whole else steps + 1)]
    return pts, whole


def _face(m, pts, sw, toward, t):
    """One face in a swatch, turned to look along `toward`; `t` down the swatch, 0 its foot to 1 its head, a number or
    one a corner."""
    pts = [Vector(q) for q in pts]
    n = (pts[1] - pts[0]).cross(pts[2] - pts[0])
    if n.length < 1e-9:
        n = (pts[2] - pts[0]).cross(pts[-1] - pts[0])
    ts = list(t) if isinstance(t, (list, tuple)) else [t] * len(pts)
    if n.dot(Vector(toward)) < 0:
        pts, ts = pts[::-1], ts[::-1]
    m.face(pts, [kit.sw_uv(sw, 0.0, min(max(v, 0.0), 1.0)) for v in ts])


def _stone(m, r, wide, y0, y1, arcs, sw, lift, at=(0.0, 0.0)):
    """A ring's stone round `at` (X and Z), `wide` in from its outer radius, from y0 to y1 along Y: whole, or in arcs
    (from, to) with their ends. Its swatch runs foot to head with its height, `lift` over the floor."""
    def put(q, y):
        return (at[0] + q[0], y, at[1] + q[1])

    def t(*qs):
        return [(at[1] + q[1] + lift) / 14.0 for q in qs]

    centre = Vector((at[0], 0.0, at[1]))
    for a0, a1 in arcs:
        outer, whole = _arc(r, a0, a1)
        inner, _ = _arc(r - wide, a0, a1)
        k = len(outer)
        for i in range(k if whole else k - 1):
            j = (i + 1) % k
            o0, o1, i0, i1 = outer[i], outer[j], inner[i], inner[j]
            tt = t(o0, o1, i1, i0)
            _face(m, [put(o0, y0), put(o1, y0), put(i1, y0), put(i0, y0)], sw, (0, -1, 0), tt)
            _face(m, [put(o0, y1), put(o1, y1), put(i1, y1), put(i0, y1)], sw, (0, 1, 0), tt)
            mid = (Vector(put(o0, 0)) + Vector(put(o1, 0))) / 2
            _face(m, [put(o0, y0), put(o1, y0), put(o1, y1), put(o0, y1)], sw, mid - centre, t(o0, o1, o1, o0))
            mid = (Vector(put(i0, 0)) + Vector(put(i1, 0))) / 2
            _face(m, [put(i0, y0), put(i1, y0), put(i1, y1), put(i0, y1)], sw, centre - mid, t(i0, i1, i1, i0))
        if not whole:
            for i in (0, k - 1):
                o, n = outer[i], inner[i]
                side = Vector((o[0] - n[0], 0, o[1] - n[1])).cross(Vector((0, 1, 0)))
                _face(m, [put(o, y0), put(n, y0), put(n, y1), put(o, y1)], sw, side if i else -side, t(o, n, n, o))


def _line(m, r, y, arcs, sw, at=(0.0, 0.0)):
    """A line of light on a ring's inner edge, round `at`: a strip on the face toward the mouth at `y`, its inner edge at
    radius `r`, and a lip back along that edge, so it reads from the side too. One colour, so no gradient."""
    wide, deep = LINE
    for a0, a1 in arcs:
        outer, whole = _arc(r + wide, a0, a1)
        inner, _ = _arc(r, a0, a1)
        k = len(outer)
        for i in range(k if whole else k - 1):
            j = (i + 1) % k
            o0, o1, i0, i1 = ((at[0] + q[0], at[1] + q[1]) for q in (outer[i], outer[j], inner[i], inner[j]))
            _face(m, [(o0[0], y, o0[1]), (o1[0], y, o1[1]), (i1[0], y, i1[1]), (i0[0], y, i0[1])], sw, (0, -1, 0), 0.5)
            mid = Vector(((i0[0] + i1[0]) / 2 - at[0], 0, (i0[1] + i1[1]) / 2 - at[1]))
            _face(m, [(i0[0], y, i0[1]), (i1[0], y, i1[1]), (i1[0], y + deep, i1[1]), (i0[0], y + deep, i0[1])], sw,
                  -mid, 0.5)


def door():
    """The Festival Door: a stone ring standing on a low step, its opening the way a player walks into, a line of
    amber light round its inner edge, and the name's plate sunk into its crown. Void stone, the void machines' own: only
    its light is warm. The rings behind it and its core are pieces of their own."""
    m = Mesh()
    zc, outer, inner, front, back = MOUTH
    m.box(STEP[:3], (0, STEP[3], STEP[2] / 2), "abyss", ink=True)
    _stone(m, outer, outer - inner, front, back, [(0.0, 360.0)], "abyss", 0.0, at=(0.0, zc))
    _line(m, inner - 0.02, front - 0.04, [(0.0, 360.0)], "doormouth", at=(0.0, zc))
    m.box(NAME, (0, front - 0.15, zc + outer + 0.3), "rubber", ink=True)
    w, d, h = NAME
    way = (inner * 2, zc - inner, zc + inner)
    return Piece("Door", m, solid=f"the step, {STEP[0]:g} by {STEP[1]:g} and {STEP[2]:g} high, and the front ring, "
                                  f"{outer * 2:g} across and {back - front:g} deep, round its opening; the opening stays open",
                 note=f"its origin is the step's middle on the floor; its mouth looks toward -Y, so at the plan's turn "
                      f"of 90 it looks down the way in. The way a player walks into is the ring's opening: {way[0]:g} "
                      f"across, from {way[1]:g} to {way[2]:g} up, in the ring's front at {front:g} along its Y. The name "
                      f"goes on the plate's -Y face, {w:g} by {h:g}, its middle {zc + outer + 0.3:g} up. The line of "
                      f"light round the opening is the Door's own: full always")


def door_ring(k):
    """Ring `k` behind the front one, a piece by itself, built round its own middle: a thin stone back in three arcs,
    each with a line of light on its inner edge. The arcs' gaps are its own, so its turn shows."""
    y, r, rate, arcs = RINGS[k - 1]
    lift = ring_at(k)[2]
    spans = list(zip(arcs[0::2], arcs[1::2]))

    def make():
        m = Mesh(None)
        _stone(m, r, 0.32, 0.0, 0.3, spans, "abyss", lift)
        _line(m, r - 0.34, -0.04, [(a0 + 2, a1 - 2) for a0, a1 in spans], f"doorarc{k}")
        way = "anticlockwise" if rate > 0 else "clockwise"
        return Piece(f"DoorRing{k}", m,
                     note=f"ring {k} of {len(RINGS)} behind the Door's front ring, {y:g} behind it, {r:g} in radius. Its "
                          f"origin is its middle, on the tunnel's axis: it turns about its own Y, the axis, at {abs(rate):g} "
                          f"degrees a second, {way} seen from the mouth, always, whatever the Door's state. Look only")
    return make


def door_way():
    """The Door's core, where the tunnel ends, a piece by itself built round its own middle: a disc of warm light, its
    middle the palest, deepening to amber at its rim, so it reads as light, not a plate."""
    m = Mesh(None)
    r = CORE[1]
    rim, _ = _arc(r, 0.0, 360.0, 32)
    for (x0, z0), (x1, z1) in zip(rim, rim[1:] + rim[:1]):
        _face(m, [(0, 0, 0), (x0, 0, z0), (x1, 0, z1)], "doorcore", (0, -1, 0), [1.0, 0.0, 0.0])
    return Piece("DoorWay", m,
                 note=f"the Door's core, {r * 2:g} across, {CORE[0]:g} behind its mouth, facing it. Its origin is its "
                      f"middle. Its glow's strength is the Door's state: full while a ground is open to go to, low while "
                      f"none is. Keep its tint white, or its warmth goes. Look only: the way a player walks into is the "
                      f"Door's opening (the Door's note), not this")


def target(m, at, r0, r1, sides, sw):
    """A flat ring facing the piece's front and its back, its middle at `at`."""
    at = Vector(at)
    for i in range(sides):
        a, b = math.tau * i / sides, math.tau * (i + 1) / sides
        m.flat([at + Vector((r * math.sin(t), 0, r * math.cos(t))) for r, t in ((r0, a), (r1, a), (r1, b), (r0, b))], sw)


def training():
    """The Training machine: a sparring stone. A standing stone of void stone on a steel deck, two bands of the
    void's light round it, three blunt pegs toward the one who trains, and a target of the void's light floating
    before its face at a Voidkin's chest. Out in front, 6 studs toward the piece's front, the pad where the Voidkin
    stands, a small dais like a bay's, and a line of light on the floor from it to the stone."""
    m = Mesh()
    q = math.sqrt(0.5)
    m.box((6.0, 4.6, 0.5), (0, 0, 0.25), "girder", ink=True)
    m.box((6.1, 4.7, 0.1), (0, 0, 0.25), "void")
    horn(m, [(0, 0, 0.5), (0, 0, 3.4), (0, 0, 6.6)], [2.0, 1.8, 1.25], "abyss", flat=(q, q, 0.0))
    m.box((2.86, 2.86, 0.14), (0, 0, 1.4), "void")
    m.box((2.06, 2.06, 0.14), (0, 0, 5.8), "void")
    m.box((1.5, 1.5, 0.3), (0, 0, 6.75), "bone", ink=True)
    shard(m, (0, 0, CROWN), 0.42, 1.7, "void")
    for sx in (-1, 1):                                                                # the pegs, blunt
        horn(m, [(sx * 0.7, 0.9, 5.0), (sx * 1.3, 2.2, 5.25)], [0.3, 0.2], "abyss", flat=(0.0, 0.0, 1.0))
    horn(m, [(0, 1.15, 1.95), (0, 2.4, 1.8)], [0.3, 0.2], "abyss", flat=(1.0, 0.0, 0.0))
    face = 1.72                                                                       # the target, floating before the stone
    target(m, (0, face, 3.55), 0.02, 0.3, 8, "void")
    target(m, (0, face, 3.55), 0.72, 0.92, 12, "void")
    for sx, sz in EDGES:
        m.box((0.12 + 0.3 * abs(sx), 0.06, 0.12 + 0.3 * abs(sz)), (sx * 1.3, face, 3.55 + sz * 1.3), "void")
    m.box((4.0, 4.0, 0.4), (0, TRAINEE, 0.2), "girder", ink=True)                     # the pad
    m.box((4.1, 4.1, 0.1), (0, TRAINEE, 0.2), "void")
    m.lathe([(1.75, 0.16), (1.9, 0.0)], (0, TRAINEE, 0.4), 12, "abyss")
    m.lathe([(1.42, 0.17), (1.6, 0.17)], (0, TRAINEE, 0.4), 12, "void", caps=False)
    well(m, (0, TRAINEE, 0.4), 1.12)
    m.box((0.3, TRAINEE - 4.3, 0.08), (0, (TRAINEE + 0.3) / 2, 0.04), "void")
    return Piece("Training", m, solid=f"the deck, 6 by 4.6 and 0.5 high, the stone on it, about 2.8 square and 6.9 high, "
                                      f"and the pad, 4 square and 0.4 high, {TRAINEE:g} toward the piece's front",
                 note=f"its middle on the stand-in's; the pad is in the piece, {TRAINEE:g} toward its front, where the "
                      f"stand-in's pad is. The one who trains stands at the pad's middle, facing the stone. Its crown "
                      f"is TrainingCrown, floating {CROWN:g} up")


# The crown, a stage at a time, in AR35's family (research's class, 2026-11-17): a flat band of void stone with short
# crystals set through it and tall crystals standing near the spark, so its top line rises to its middle from every
# side while it turns, never weights at a bar's ends. A stage's band: its inner and outer radius and its sides; the
# crystals set through it: how many, half width, high; the tall ones: how many, how far out, half width, high. Every
# crystal is upright, never radial or leaning in, unlit, joined to nothing, and at least 3 times as tall as it is wide
# (the content check, 2026-11-17). Stage I is TrainingCrown; Stages II and III are base_training.py's pieces.
CROWNS = {1: dict(band=(2.9, 3.3), sides=16, rim=(4, 0.18, 1.1), core=(3, 1.5, 0.36, 2.6)),
          2: dict(band=(3.6, 4.05), sides=20, rim=(6, 0.26, 1.6), core=(4, 2.1, 0.42, 3.0)),
          3: dict(band=(4.3, 4.75), sides=24, rim=(8, 0.29, 1.8), core=(6, 2.4, 0.45, 3.6))}
RIM_LEAN, CORE_LEAN = 0.45, 0.6     # how much of a crystal stands over its widest: the tall ones mostly above the band


def crown(stage):
    """A stage's crown, built round its own middle: a flat band of void stone, two marks of the void's light on its
    rim for each crystal set through it, spaced evenly all round between them, and the tall crystals near the spark."""
    c = CROWNS[stage]
    m = Mesh()
    r0, r1 = c["band"]
    hoop(m, (0, 0, 0), r0, r1, 0.34, c["sides"], "abyss", lying=True)
    n, half, high = c["rim"]
    for k in range(2 * n):                     # the marks, a quarter step off the crystals
        a = math.tau * (k + 0.5) / (2 * n)
        m.box((0.3, 0.5, 0.42), ((r1 + 0.02) * math.cos(a), (r1 + 0.02) * math.sin(a), 0), "void", rot=(0.0, 0.0, a))
    for k in range(n):
        a = math.tau * (k + 0.5) / n
        shard(m, ((r0 + r1) / 2 * math.cos(a), (r0 + r1) / 2 * math.sin(a), 0.1), half, high, "abyss",
              lean=RIM_LEAN, ink=True)
    count, out, half, high = c["core"]
    for k in range(count):
        a = math.tau * k / count
        shard(m, (out * math.cos(a), out * math.sin(a), 0.1), half, high, "abyss", lean=CORE_LEAN, ink=True)
    return m


def crown_size(stage):
    """A stage's crown: across, at its rim's crystals; and the tall crystals' tips, up from its middle."""
    c = CROWNS[stage]
    across = 2 * max(c["band"][1], sum(c["band"]) / 2 + c["rim"][1])
    return across, 0.1 + c["core"][3] * CORE_LEAN


def training_crown():
    """The Training machine's crown at Stage I, a piece by itself, its origin its middle."""
    across, tip = crown_size(1)
    n, count = CROWNS[1]["rim"][0], CROWNS[1]["core"][0]
    return Piece("TrainingCrown", crown(1),
                 note=f"Stage I's crown, base level 1. Its origin is its middle: it floats {CROWN:g} up at the Training "
                      f"machine's middle, round the stone's spark, and turns about its own upright while a Voidkin "
                      f"trains, still when none does. A band of void stone with {n} short crystals set through it and "
                      f"{2 * n} marks of the void's light, and {count} tall crystals near the spark, their tips "
                      f"{tip:.2f} over its middle. {across:.1f} across. At base levels 2 and 3, TrainingCrown2 and "
                      f"TrainingCrown3 stand in its place (plan.json, machines.trainingStages). Look only")


PIECES = {"Door": door, **{f"DoorRing{k}": door_ring(k) for k in range(1, len(RINGS) + 1)}, "DoorWay": door_way, "Training": training, "TrainingCrown": training_crown,
          "Breaker": breaker, "BreakerChamber": breaker_chamber, "BreakerWaiting": breaker_waiting,
          "Bay": bay, "BayHalo": bay_halo, "BaySleeping": bay_sleeping, "SleepingStone": sleeping_stone, "TowerSleeping": tower_sleeping,
          "BatteryRack": battery_rack, "BatteryCell": battery_cell}
