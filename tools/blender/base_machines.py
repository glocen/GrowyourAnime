"""AR15: the base's machines (docs/asset-requests.md), one at a time, in the base kit's language: steel and bone,
plates, trusses and ribbed insulators, the current in Power's yellow. Each stands where the builder's stand-in stands
(WorldService.plot), on the same footprint, so an install moves no rule.

They are base_kit.py's pieces like the others: on the kit's own atlas, a piece's front toward +Y (the Strip), its
origin on the floor at the stand-in's middle, one unit a stud. What a machine does shows in its own light, which the
builder turns up and down by the piece's EmissiveStrength.

The Void Breaker (`Breaker`, `BreakerChamber`, `BreakerWaiting`): a gantry over a steel housing. Power comes in yellow
along the housing; the break is cyan, the Breaker's own colour. A chamber is its own piece, stood once a chamber the
base has, so each can be lit by itself: bright while it breaks a shard, low when it's empty.

An extraction bay (`Bay`, `BayHalo`): a steel deck with a copper collector ring stood behind the worker. The bay's
own light is a piece by itself, in one pale swatch, so the builder gives it the worker's rarity colour (TR22).

The generator (`Generator`, `GeneratorRotor`): a dynamo on a steel housing, its rotor open to view between two end
bells under a yoke of three bushings. The rotor is its own piece, its origin on its axle, so the builder turns it:
faster as the plant generates more.

The battery (`BatteryRack`, `BatteryCell`): a bank. A low rack with eight seats and a bus bar down its middle, and a
cell a seat as the battery's cap grows with the base's level (research, 2026-11-15: 60, 150 and 400 kWh), two, four
and eight. A cell is its own piece, so the bank is its own meter: the builder lights the cells one after another as
the charge rises.

Not run by itself: base_kit.py takes PIECES into its own.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lantern_row_kit as kit  # noqa: E402

Mesh, Piece = kit.Mesh, kit.Piece
SIGNS = ((1, 1), (-1, 1), (-1, -1), (1, -1))
ROUND = ("+x", "-x", "+y", "-y")

# The Breaker's stand-in, the builder's (Faber, 2026-11-15): the body, and the chambers' middles on its top
BODY = (14.0, 6.0, 5.0)          # across, deep, high
CHAMBERS = (3.5, 7.0, 4.0)       # a chamber's middle: across (each side), up; and its cube's side
GAP = (5.85, 8.35)               # the shard's room in a chamber, between the two points: from, to (up from the floor)
BAY = (10.0, 0.4)                # a bay's stand-in, its pad: its side and its height
HALO = (4.9, 2.0, 2.6)           # a bay's collector ring: its middle up from the floor, its inner and outer radius
PLANT = (6.0, 5.0, 8.0)          # the generator's stand-in: across, deep, high
AXLE = 5.3                       # the generator's rotor: its axle, up from the floor, along X
BANK = (6.0, 4.0, 3.0)           # the battery's stand-in: across, deep, high
SEAT = 0.6                       # a cell's seat on the rack, up from the floor
# a cell's seat on the rack, across and toward the Strip, in the order the bank fills: the spawn's row first, from
# the middle out
SEATS = [(-0.75, -0.95), (0.75, -0.95), (-0.75, 0.95), (0.75, 0.95), (-2.25, -0.95), (2.25, -0.95), (-2.25, 0.95), (2.25, 0.95)]
CELLS_AT = {1: 2, 2: 4, 3: 8}    # cells by the base's level, with the battery's cap


def post(m, x, y, z0, z1, t, sw, ink=False):
    m.box((t, t, z1 - z0), (x, y, (z0 + z1) / 2), sw, ink=ink)


def insulator(m, at, length, r=0.34, ribs=3, sides=5):
    """A ribbed ceramic stack standing up from `at`, as the kit's."""
    step = length / ribs
    profile = []
    for i in range(ribs):
        z = length - i * step
        profile += [(r * 0.45, z), (r, z - step * 0.4), (r * 0.45, z - step * 0.8)]
    profile.append((r * 0.45, 0.0))
    m.lathe(profile, at, sides, "ceramic")


def breaker():
    """The Void Breaker's body: a steel housing on a concrete plinth, 14 studs by 6 and 5 high as the stand-in is, a
    gantry over it to 10.4 with a point reaching down into each chamber, an insulator stack and the Breaker's lamp at
    its middle. Both long faces are fronts: the Strip sees one, the spawn the other."""
    m = Mesh()
    wide, deep, high = BODY
    m.box((wide + 0.6, deep + 0.6, 0.6), (0, 0, 0.3), "concrete", ink=True)
    m.box((wide + 0.2, deep + 0.2, 0.5), (0, 0, 0.85), "yellow", pics={k: "hazard" for k in ROUND})
    m.box((wide, deep, 3.4), (0, 0, 2.8), "steel", pics={"+y": "panel", "-y": "panel"}, ink=True)
    m.box((wide + 0.4, deep + 0.4, 0.5), (0, 0, high - 0.25), "bone", ink=True)
    across, up, side = CHAMBERS
    for sy in (-1, 1):
        y = sy * (deep / 2 + 0.03)
        m.box((2.6, 0.16, 2.4), (0, y, 2.9), "dark")                                 # the core's window, the void in it
        m.box((0.34, 0.2, 1.9), (0, y + sy * 0.02, 2.9), "cyan")
        for sx in (-1, 1):
            m.box((4.6, 0.14, 0.22), (sx * 4.3, y, 4.1), "power")                    # the current, in along the housing
            m.box((0.22, 0.14, 1.4), (sx * 1.9, y, 3.5), "power")                    # and up into the core
    for sx in (-1, 1):                                                               # the rail's coupling at each end
        m.box((0.5, 2.2, 1.8), (sx * (wide / 2 + 0.2), 0, 2.0), "girder", ink=True)
        m.box((0.14, 1.4, 0.24), (sx * (wide / 2 + 0.47), 0, 2.0), "power")
    # the gantry: a leg at each end, a bone head over both chambers, a point down into each
    head = 10.0
    for sx in (-1, 1):
        post(m, sx * 6.55, 0, high, head - 0.35, 0.55, "girder", ink=True)
        m.tube([(sx * 6.55, 0, high + 2.6), (sx * 5.2, 0, head - 0.4)], 0.12, "girder")
        m.box((0.9, 0.9, 0.5), (sx * across, 0, head - 0.6), "girder")
        m.lathe([(0.42, 0.75), (0.09, 0.0)], (sx * across, 0, GAP[1] + 0.12), 6, "copper", caps=False)
        m.box((0.22, 0.22, 0.2), (sx * across, 0, GAP[1] + 0.06), "cyan")
    m.box((14.0, 1.3, 0.7), (0, 0, head), "bone", ink=True)
    m.box((13.4, 0.16, 0.16), (0, 0.68, head), "power")
    m.box((13.4, 0.16, 0.16), (0, -0.68, head), "power")
    # the middle: the stack between the chambers, up to the head, and the lamp on it
    m.box((1.7, 1.7, 0.8), (0, 0, high + 0.4), "girder", ink=True)
    insulator(m, (0, 0, high + 0.8), head - 0.35 - (high + 0.8), r=0.72, ribs=5, sides=6)
    m.box((1.5, 1.5, 0.45), (0, 0, head + 0.57), "girder", ink=True)
    m.box((0.9, 0.9, 0.7), (0, 0, head + 1.15), "cyan")
    for sy in (-1, 1):                                                               # the feed, up the back and the front
        m.tube([(1.1, sy * 2.6, high), (1.1, sy * 1.5, high + 2.4), (0.5, sy * 0.7, head - 0.4)], 0.1, "rubber")
        m.tube([(-1.1, sy * 2.6, high), (-1.1, sy * 1.5, high + 2.4), (-0.5, sy * 0.7, head - 0.4)], 0.1, "rubber")
    return Piece("Breaker", m, solid="a box, 14 by 6, 5 high, and the gantry's two legs",
                 note=f"on the stand-in's footprint. A chamber stands at across {across:g} each side, its foot on the "
                      f"body's top at {high:g}. The lamp is at {head + 1.15:g} up, a stud over the builder's BreakerLamp")


def breaker_chamber():
    """One chamber, its foot on the Breaker's top: a girder seat with a cyan line round it, four bone posts with a
    ceramic clamp each, a ring at its head left open for the gantry's point, and its own point standing up from the
    seat. The shard sits between the two points. Its glow is the chamber's state."""
    m = Mesh()
    _, up, side = CHAMBERS
    foot = BODY[2]
    half = side / 2 - 0.15
    m.box((side + 0.2, side + 0.2, 0.3), (0, 0, 0.15), "girder", ink=True)
    m.box((3.0, 3.0, 0.1), (0, 0, 0.35), "dark")
    for s in (-1, 1):
        m.box((3.4, 0.14, 0.12), (0, s * 1.75, 0.36), "cyan")
        m.box((0.14, 3.4, 0.12), (s * 1.75, 0, 0.36), "cyan")
        m.box((side, 0.22, 0.22), (0, s * half, side - 0.2), "girder")
        m.box((0.22, side, 0.22), (s * half, 0, side - 0.2), "girder")
    for sx, sy in SIGNS:
        post(m, sx * half, sy * half, 0.3, side - 0.1, 0.22, "bone")
        m.box((0.42, 0.42, 0.34), (sx * half, sy * half, side / 2), "ceramic")
    m.lathe([(0.09, GAP[0] - foot - 0.12), (0.46, 0.4)], (0, 0, 0.0), 6, "copper", caps=False)
    m.box((0.22, 0.22, 0.2), (0, 0, GAP[0] - foot - 0.06), "cyan")
    return Piece("BreakerChamber", m,
                 note=f"its place is the chamber's middle across, on the body's top ({foot:g} up): the stand-in's cube "
                      f"from {up - side / 2:g} to {up + side / 2:g}. The shard's room is between the points, "
                      f"{GAP[0]:g} to {GAP[1]:g} up, its middle at {sum(GAP) / 2:g}. Look only")


def breaker_waiting():
    """A place in the waiting line: a low cradle on a concrete foot, a cyan mark on its tray."""
    m = Mesh()
    m.box((2.5, 2.5, 0.4), (0, 0, 0.2), "concrete", ink=True)
    m.box((2.1, 2.1, 0.4), (0, 0, 0.6), "girder", ink=True)
    m.box((1.5, 1.5, 0.08), (0, 0, 0.84), "dark")
    for s in (-1, 1):
        m.box((2.1, 0.2, 0.3), (0, s * 0.95, 0.95), "bone")
    m.box((0.5, 0.5, 0.06), (0, 0, 0.9), "cyan")
    return Piece("BreakerWaiting", m, solid="a box, 2.5 square, 1 high",
                 note="on the stand-in's pad, 2.5 square and 1 high; a waiting shard stands on its tray, 0.9 up")


def ring(m, x, z, r0, r1, thick, sides, sw):
    """A flat ring stood on its edge, its axle along X, its middle at (x, 0, z): seen from both sides."""
    turned = Mesh(None)
    turned.lathe([(r0, 0.0), (r0, thick), (r1, thick), (r1, 0.0), (r0, 0.0)], (0, 0, 0), sides, sw, caps=False)
    for face, uv in zip(turned.f, turned.uv):                      # the lathe's Z laid along X
        m.face([(x + turned.v[i][2] - thick / 2, turned.v[i][1], z - turned.v[i][0]) for i in face], uv)


def bay():
    """An extraction bay: the stand-in's pad, 10 studs square and 0.4 high, as a steel deck where the worker stands,
    and on its outer side (-X) a frame holding a copper collector ring behind the worker, so the court and the gate
    see the worker against it. The current the worker makes leaves in yellow, along the deck to the ring's foot.
    The other three sides stay open: two low posts mark the inner corners."""
    m = Mesh()
    side, top = BAY
    back, mid = -(side / 2 - 0.55), HALO[0]
    m.box((side, side, top), (0, 0, top / 2), "concrete", ink=True)
    m.box((side + 0.1, side + 0.1, 0.22), (0, 0, 0.2), "yellow", pics={k: "hazard" for k in ROUND})
    m.box((7.8, 7.8, 0.06), (0.3, 0, top + 0.03), "steel", pics={"+z": "plate"})
    for sy in (-1, 1):
        m.box((1.5, 0.2, 0.05), (back + 1.2, sy * 0.5, top + 0.085), "power")         # the current, out to the ring's foot
        # an inner corner's post: low, so nothing stands between the court and the worker
        m.box((0.7, 0.7, 0.8), (side / 2 - 0.6, sy * (side / 2 - 0.6), top + 0.4), "girder", ink=True)
        insulator(m, (side / 2 - 0.6, sy * (side / 2 - 0.6), top + 0.8), 0.6, r=0.3, ribs=2)
        m.box((0.3, 0.3, 0.26), (side / 2 - 0.6, sy * (side / 2 - 0.6), top + 1.5), "power")
        # the frame's post, its insulator and its tip
        y = sy * (side / 2 - 0.65)
        m.box((1.0, 1.0, 0.5), (back, y, top + 0.25), "girder", ink=True)
        post(m, back, y, top + 0.5, 8.0, 0.5, "bone", ink=True)
        insulator(m, (back, y, 8.0), 1.0)
        m.box((0.3, 0.3, 0.3), (back, y, 9.15), "power")
        # the ring's stays, to the post
        reach = HALO[2] * 0.7071
        for sz in (-1, 1):
            m.tube([(back, sy * reach, mid + sz * reach), (back, y - sy * 0.2, mid + sz * 2.5)], 0.11, "girder")
    m.box((0.45, side - 0.8, 0.45), (back, 0, 7.75), "girder", ink=True)              # the frame's head
    m.box((0.12, side - 2.0, 0.14), (back + 0.25, 0, 7.75), "power")
    m.box((0.6, 0.7, 0.36), (back, 0, mid + HALO[2] - 0.08), "girder")                # the ring's clamp under it
    ring(m, back, mid, HALO[1], HALO[2], 0.36, 12, "copper")
    m.box((0.9, 1.6, 1.0), (back, 0, top + 0.5), "girder", ink=True)                  # the ring's foot: where the current leaves
    m.box((0.1, 1.0, 0.2), (back + 0.48, 0, top + 0.6), "power")
    post(m, back, 0, top + 1.0, mid - HALO[2] + 0.05, 0.3, "rubber")
    return Piece("Bay", m, solid="a box, 10 square, 0.4 high, and the frame's two posts",
                 note=f"on the stand-in's pad. Its ring stands on -X: turn 0 on the plot's left, 180 on its right, so "
                      f"the ring is on the outer side and the worker is seen against it from the court and the gate. "
                      f"The worker stands at the pad's middle; the ring's middle is {mid:g} up")


def bay_halo():
    """A working bay's own light, a piece by itself: a ring of light inside the collector ring and a square on the
    deck round the worker's feet. Every face is one pale swatch, so the builder gives it the worker's rarity colour
    (docs/test-requests.md, TR22) and takes it away when the bay is empty."""
    m = Mesh(None)
    side, top = BAY
    back, mid = -(side / 2 - 0.55), HALO[0]
    ring(m, back, mid, HALO[1] - 0.42, HALO[1] - 0.04, 0.14, 12, "lamp")
    for s in (-1, 1):
        m.box((4.6, 0.18, 0.05), (0, s * 2.21, top + 0.085), "lamp")
        m.box((0.18, 4.24, 0.05), (s * 2.21, 0, top + 0.085), "lamp")
    return Piece("BayHalo", m, lights=[("Rarity", (back + 1.4, 0.0, mid + 0.4), "#F6FCFF")],
                 note="stands where its Bay stands, the same turn, only while a worker works there. One pale swatch on "
                      "every face: the worker's rarity colour is the builder's (a tint, or the mesh in Neon without "
                      "the kit's pictures). Its light is a PointLight in the same colour, the first to go if the "
                      "plot's lights weigh. Look only")


def laid(m, turned, z):
    """A shape turned about Z, laid along X: its heights become its places across, its axle `z` up."""
    for face, uv in zip(turned.f, turned.uv):
        m.face([(turned.v[i][2], turned.v[i][1], z - turned.v[i][0]) for i in face], uv)


def generator():
    """The generator: on the stand-in's footprint, 6 studs by 5, a steel housing with the plant's meter on both its
    faces, two bone end bells on girder saddles holding the rotor open to view between them, and over it a yoke with
    three bushings, to 8.5 studs. Both long faces are fronts: the spawn sees one, the Strip the other."""
    m = Mesh()
    wide, deep, _ = PLANT
    m.box((wide + 0.4, deep + 0.4, 0.5), (0, 0, 0.25), "concrete", ink=True)
    m.box((wide + 0.2, deep + 0.2, 0.4), (0, 0, 0.7), "yellow", pics={k: "hazard" for k in ROUND})
    m.box((wide, deep, 2.4), (0, 0, 2.1), "steel", pics={"+y": "panel", "-y": "panel"}, ink=True)
    m.box((wide + 0.3, deep + 0.3, 0.3), (0, 0, 3.35), "bone", ink=True)
    for sy in (-1, 1):
        y = sy * (deep / 2 + 0.03)
        m.box((2.6, 0.14, 1.2), (0, y, 2.2), "dark")                                  # the meter's window
        for k, tall in enumerate((0.35, 0.55, 0.75, 0.95)):                           # and its bars, rising
            m.box((0.32, 0.18, tall), (-0.84 + 0.56 * k, y + sy * 0.02, 1.72 + tall / 2), "power")
        for sx in (-1, 1):
            m.box((0.2, 0.14, 1.5), (sx * 2.4, y, 2.0), "power")                      # the current, down to the floor's lines
    bells = Mesh(None)
    for sx in (-1, 1):
        m.box((0.9, 3.6, 1.0), (sx * 2.2, 0, 4.0), "girder", ink=True)                # a saddle
        bells.lathe([(1.6, sx * 2.2 + 0.45), (1.6, sx * 2.2 - 0.45)], (0, 0, 0), 10, "bone")
        bells.lathe([(0.5, sx * 2.2 + sx * 0.6 + 0.15), (0.5, sx * 2.2 + sx * 0.6 - 0.15)], (0, 0, 0), 6, "power")   # the axle's eye
        post(m, sx * 2.2, 0, AXLE + 1.5, 7.35, 0.5, "girder")                         # the yoke's post
        m.tube([(sx * 2.85, 0, 7.4), (sx * 3.05, 1.6, 3.5)], 0.1, "rubber")
        m.tube([(sx * 2.85, 0, 7.4), (sx * 3.05, -1.6, 3.5)], 0.1, "rubber")
    laid(m, bells, AXLE)
    m.box((wide, 0.8, 0.45), (0, 0, 7.57), "girder", ink=True)                        # the yoke, over the rotor
    m.box((wide - 0.6, 0.14, 0.14), (0, 0.42, 7.57), "power")
    m.box((wide - 0.6, 0.14, 0.14), (0, -0.42, 7.57), "power")
    for x in (-1.6, 0.0, 1.6):                                                        # three bushings
        insulator(m, (x, 0, 7.8), 0.55, r=0.36, ribs=2)
        m.box((0.26, 0.26, 0.2), (x, 0, 8.45), "power")
    return Piece("Generator", m, solid="a box, 6 by 5, 8 high",
                 note=f"on the stand-in's footprint, 8.55 high with its bushings. Its rotor is GeneratorRotor, its axle "
                      f"along X, {AXLE:g} up at the machine's middle: it turns clear of everything, 1.75 at its widest")


def generator_rotor():
    """The generator's rotor, a piece by itself, its origin on its axle (along X): a copper winding between two bone
    rims, six bars of the current's yellow along it, which streak when it turns."""
    m = Mesh(None)
    turned = Mesh(None)
    turned.lathe([(1.5, 1.4), (1.5, -1.4)], (0, 0, 0), 10, "copper", caps=False)
    for sx in (-1, 1):
        turned.lathe([(1.75, sx * 1.55 + 0.15), (1.75, sx * 1.55 - 0.15)], (0, 0, 0), 10, "bone")
    turned.lathe([(0.4, 1.75), (0.4, -1.75)], (0, 0, 0), 6, "girder", caps=False)     # the axle
    laid(m, turned, 0.0)
    for k in range(6):
        a = math.tau * k / 6
        m.box((2.8, 0.34, 0.2), (0, -1.58 * math.sin(a), 1.58 * math.cos(a)), "power", rot=(a, 0.0, 0.0))
    return Piece("GeneratorRotor", m,
                 note=f"its origin is its axle's middle: it stands {AXLE:g} up at the generator's middle and turns "
                      f"about its own X, faster as the plant generates more. Look only")


def battery_rack():
    """The battery's rack: on the stand-in's footprint, 6 studs by 4, a girder deck with eight dark seats, a copper
    bus bar down its middle with the current's line on it, and a low terminal post at each end. An empty seat is a
    cell the base hasn't earned yet."""
    m = Mesh()
    wide, deep, _ = BANK
    m.box((wide + 0.3, deep + 0.3, 0.3), (0, 0, 0.15), "concrete", ink=True)
    m.box((wide, deep, 0.3), (0, 0, 0.45), "girder", ink=True)
    for x, y in SEATS:
        m.box((1.24, 1.5, 0.05), (x, y, SEAT + 0.025), "dark")
    m.box((wide - 0.5, 0.3, 0.24), (0, 0, SEAT + 0.12), "copper")
    m.box((wide - 0.9, 0.12, 0.06), (0, 0, SEAT + 0.27), "power")
    for sx in (-1, 1):
        post(m, sx * (wide / 2 - 0.22), 0, SEAT, 2.1, 0.3, "girder", ink=True)
        insulator(m, (sx * (wide / 2 - 0.22), 0, 2.1), 0.55, r=0.3, ribs=2)
        m.box((0.24, 0.24, 0.2), (sx * (wide / 2 - 0.22), 0, 2.75), "power")
    return Piece("BatteryRack", m, solid="a box, 6 by 4, 3 high",
                 note=f"on the stand-in's footprint, 2.85 high at its posts. Its eight seats are {SEAT:g} up; a "
                      f"BatteryCell stands on each seat the base's level has earned (plan.json, machines, battery)")


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


PIECES = {"Breaker": breaker, "BreakerChamber": breaker_chamber, "BreakerWaiting": breaker_waiting,
          "Bay": bay, "BayHalo": bay_halo, "Generator": generator, "GeneratorRotor": generator_rotor,
          "BatteryRack": battery_rack, "BatteryCell": battery_cell}
