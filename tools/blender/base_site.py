"""AR14, delivery 5: the building site's pieces (docs/asset-requests.md). At level 1 the base is a plant still going up
(the director, 2026-11-15: "at level 1 it rly need to look like it under construction"), so its plain ground carries a
site's own things: a tower crane, steel frames half raised, scaffolds, foundations with their bars standing, stacked
plates and girders, cable drums, barriers, a site cabin.

They are base_kit.py's pieces like the others: on the kit's own atlas (no new picture), a piece's front toward +Y, its
origin on the floor, one unit a stud. What is built wears the kit's steel and bone; what is going up wears primer
orange (the atlas's copper) and hazard yellow, so the two read apart from the gate.

Not run by itself: base_kit.py takes PIECES into its own.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lantern_row_kit as kit  # noqa: E402

Mesh, Piece = kit.Mesh, kit.Piece
SIGNS = ((1, 1), (-1, 1), (-1, -1), (1, -1))
HAZARD = {"+y": "hazard", "-y": "hazard"}

JIB = 42.0                       # the crane's jib, from its mast along +X
MAST = 44.0                      # the mast's head


def post(m, x, y, z0, z1, t, sw, ink=False):
    """An upright from z0 to z1 (a tube can't stand straight up)."""
    m.box((t, t, z1 - z0), (x, y, (z0 + z1) / 2), sw, ink=ink)


def crane(reach=30.5, hook=20.0):
    """A tower crane: a yellow lattice mast on a concrete foot, its jib along +X with a load slung under the trolley
    at `reach`, the counterweights behind, a lit cab, beacons on its head and its jib's end. The site's landmark: it
    stands over the wall from the Strip."""
    m = Mesh()
    m.box((7.0, 7.0, 1.0), (0, 0, 0.5), "concrete", ink=True)
    m.box((3.6, 3.6, 1.2), (0, 0, 1.6), "yellow", pics={k: "hazard" for k in ("+x", "-x", "+y", "-y")})
    w, foot, lifts = 1.3, 2.2, 8
    for sx, sy in SIGNS:
        post(m, sx * w, sy * w, foot, MAST, 0.34, "yellow")
    step = (MAST - foot) / lifts
    for k in range(lifts):
        z0, z1 = foot + k * step, foot + (k + 1) * step
        for i in range(4):
            a, b = SIGNS[i], SIGNS[(i + 1) % 4]
            m.tube([(a[0] * w, a[1] * w, z1), (b[0] * w, b[1] * w, z1)], 0.1, "yellow")
            if k % 2:
                a, b = b, a
            m.tube([(a[0] * w, a[1] * w, z0), (b[0] * w, b[1] * w, z1)], 0.08, "girder")
    m.box((3.4, 3.4, 1.4), (0, 0, MAST + 0.7), "girder", ink=True)                  # the slewing ring
    m.box((2.2, 2.0, 2.4), (1.7, -2.5, MAST + 0.2), "bone", ink=True)               # the cab, under the jib's root
    m.box((0.12, 1.6, 1.0), (2.84, -2.5, MAST + 0.5), "lamp")
    m.box((1.8, 0.12, 1.0), (1.7, -3.54, MAST + 0.5), "lamp")
    top = MAST + 10.0
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.tube([(sx * 1.0, sy * 1.2, MAST + 1.4), (0, 0, top)], 0.14, "yellow")
    m.box((0.5, 0.5, 0.5), (0, 0, top + 0.3), "beacon")
    # the jib: two foot chords and a head chord, laced
    zb, zt, hw, root, bays = MAST + 1.4, MAST + 3.6, 1.0, 1.7, 8
    seg = (JIB - root) / bays
    for sy in (-1, 1):
        m.tube([(root, sy * hw, zb), (JIB, sy * hw, zb)], 0.13, "yellow")
    m.tube([(root + seg / 2, 0, zt), (JIB - seg / 2, 0, zt)], 0.13, "yellow")
    for k in range(bays):
        x0, x1 = root + k * seg, root + (k + 1) * seg
        for sy in (-1, 1):
            m.tube([(x0, sy * hw, zb), ((x0 + x1) / 2, 0, zt), (x1, sy * hw, zb)], 0.07, "yellow")
        m.tube([(x1, -hw, zb), (x1, hw, zb)], 0.07, "yellow")
        if k % 2:
            m.box((0.34, 0.34, 0.2), (x1, 0, zb - 0.2), "lamp")                     # the jib's lamps, over the site
    m.box((0.45, 0.45, 0.45), (JIB, 0, zb + 0.5), "beacon")
    # the counter-jib and its weights
    m.box((12.0, 2.2, 0.4), (-7.7, 0, zb), "girder")
    for k in range(3):
        m.box((1.6, 2.0, 2.2), (-9.4 - 1.8 * k, 0, zb - 1.3), "concrete", ink=True)
    m.tube([(0, 0, top), (root + seg * 5.5, 0, zt)], 0.06, "rubber")
    m.tube([(0, 0, top), (-13.2, 0, zb + 0.2)], 0.06, "rubber")
    # the trolley, the line, the hook and what it carries: a deck plate with two girders on it
    m.box((1.8, 2.4, 0.5), (reach, 0, zb - 0.4), "girder")
    post(m, reach, 0, hook, zb - 0.6, 0.1, "rubber")
    m.box((0.9, 0.5, 1.1), (reach, 0, hook - 0.5), "yellow", pics=HAZARD, ink=True)
    load = hook - 6.0
    for sx in (-1, 1):
        for sy in (-1, 1):
            m.tube([(reach, 0, hook - 1.0), (reach + sx * 3.0, sy * 0.9, load + 0.9)], 0.05, "rubber")
    m.box((7.0, 2.2, 0.4), (reach, 0, load + 0.2), "steel", ink=True)
    for sy in (-1, 1):
        m.box((7.0, 0.45, 0.45), (reach, sy * 0.6, load + 0.62), "copper")
    return Piece("Crane", m, solid="a box round its foot, 7 square, 3 high",
                 note=f"the jib runs {JIB:g} studs along +X at {MAST + 1.4:g} up, the load hangs {reach:g} out and "
                      f"{load:g} over the floor; {top + 0.6:g} studs to its beacon")


def frame():
    """A steel frame going up, 16 studs by 12 in primer orange: six columns on concrete feet, the first floor's beams
    all round, the second floor's on two bays only, a plank deck, a hazard board on its edge, a work lamp."""
    m = Mesh()
    for x in (-8.0, 0.0, 8.0):
        tall = 14.0 if x < 8.0 else 8.6
        for y in (-6.0, 6.0):
            m.box((1.8, 1.8, 0.6), (x, y, 0.3), "concrete", ink=True)
            post(m, x, y, 0.6, tall, 0.6, "copper", ink=True)
            m.box((0.8, 0.8, 0.24), (x, y, tall + 0.12), "yellow")
        m.box((0.5, 12.0, 0.6), (x, 0, 7.0), "copper")
    for y in (-6.0, 6.0):
        m.box((16.0, 0.5, 0.6), (0, y, 7.0), "copper", ink=True)
        m.box((8.0, 0.5, 0.6), (-4.0, y, 13.6), "copper", ink=True)
    for x in (-8.0, 0.0):
        m.box((0.5, 12.0, 0.6), (x, 0, 13.6), "copper")
    m.tube([(-8.0, -6.0, 0.6), (0.0, -6.0, 6.7)], 0.12, "girder")
    m.tube([(0.0, -6.0, 0.6), (-8.0, -6.0, 6.7)], 0.12, "girder")
    m.tube([(-8.0, -6.0, 7.3), (-8.0, 6.0, 13.3)], 0.12, "girder")
    m.box((7.4, 5.2, 0.2), (-4.0, -3.2, 7.4), "bone")
    m.box((7.6, 0.15, 0.8), (-4.0, -6.1, 8.1), "yellow", pics=HAZARD)
    m.box((0.5, 0.5, 0.4), (0.0, 6.0, 6.4), "lamp")
    return Piece("Frame", m, solid="a box round each column's foot, 1.8 square",
                 note="16 by 12, 14 high: a machine hall's frame before its walls")


def scaffold():
    """A scaffold, 8 studs along X and 3 deep, three lifts to 10.8: standards, ledgers, plank decks, a guard rail on
    its top lift, a hazard toe board on its middle one."""
    m = Mesh(None)
    for x in (-4.0, 0.0, 4.0):
        for y in (-1.5, 1.5):
            post(m, x, y, 0.0, 12.2, 0.18, "girder")
    for lift in (3.6, 7.2, 10.8):
        for y in (-1.5, 1.5):
            m.box((8.3, 0.14, 0.14), (0, y, lift), "girder")
        for x in (-4.0, 4.0):
            m.box((0.14, 3.2, 0.14), (x, 0, lift), "girder")
        m.box((8.0, 2.6, 0.14), (0, 0, lift + 0.14), "bone")
    for y in (-1.5, 1.5):
        m.box((8.3, 0.12, 0.12), (0, y, 12.1), "girder")
    m.tube([(-4.0, 1.5, 0.0), (0.0, 1.5, 3.6), (4.0, 1.5, 7.2)], 0.07, "girder")
    m.tube([(4.0, 1.5, 0.0), (0.0, 1.5, 3.6)], 0.07, "girder")
    m.box((8.0, 0.1, 0.6), (0, 1.58, 7.7), "yellow", pics=HAZARD)
    return Piece("Scaffold", m, solid="a box, 8 by 3, 11 high",
                 note="8 studs along X, 3 deep: stand it along a wall or a site's edge")


def foundation():
    """A foundation poured and waiting: a concrete slab 12 studs square in its formwork, a plinth at its middle with
    its bolts, the starter bars standing at its four corners."""
    m = Mesh()
    m.box((12.0, 12.0, 0.5), (0, 0, 0.25), "concrete", ink=True)
    for s in (-1, 1):
        m.box((12.4, 0.2, 1.0), (0, s * 6.1, 0.5), "bone")
        m.box((0.2, 12.4, 1.0), (s * 6.1, 0, 0.5), "bone")
    m.box((4.0, 4.0, 0.5), (0, 0, 0.75), "concrete", ink=True)
    for sx, sy in SIGNS:
        m.box((0.2, 0.2, 0.5), (sx * 1.4, sy * 1.4, 1.2), "yellow", skip=("-z",))
        for ox, oy in SIGNS:
            m.box((0.12, 0.12, 2.3), (sx * 4.2 + ox * 0.35, sy * 4.2 + oy * 0.35, 1.65), "copper", skip=("-z",))
        m.box((0.95, 0.95, 0.1), (sx * 4.2, sy * 4.2, 2.2), "copper")
    return Piece("Foundation", m, solid="a box, 12 square, 1 high, and a box round each corner's bars, 1 square and 2.8 "
                 "high, 4.2 from the middle each way: nobody stands in the bars",
                 note="12 studs square: on a lot, where the level that opens it stands its machine")


def stack():
    """A site's stock: deck plates stacked on bearers, girders in primer beside them, two cones."""
    m = Mesh()
    for x in (-2.2, 0.0, 2.2):
        m.box((0.4, 4.4, 0.4), (x, -1.2, 0.2), "bone")
    m.box((6.0, 4.0, 1.1), (0, -1.2, 0.95), "steel", ink=True)
    m.box((6.0, 4.0, 0.22), (0.35, -1.0, 1.61), "steel")
    m.box((6.0, 4.0, 0.22), (-0.2, -1.35, 1.83), "steel", ink=True)
    for x in (-2.6, 2.6):
        m.box((0.4, 2.4, 0.4), (x, 2.6, 0.2), "bone")
    for k, (y, z) in enumerate(((1.9, 0.65), (2.6, 0.65), (3.3, 0.65), (2.25, 1.15))):
        m.box((8.0, 0.5, 0.5), (0.3 * (k % 2), y, z), "copper", ink=k in (0, 2))
    for x, y in ((4.4, -2.6), (-4.6, 0.6)):
        m.box((1.0, 1.0, 0.12), (x, y, 0.06), "rubber")
        m.lathe([(0.1, 1.3), (0.42, 0.12)], (x, y, 0.0), 4, "yellow", spin=math.pi / 4)
    return Piece("Stack", m, solid="a box, 8 by 7, 2 high", note="about 9 studs by 8")


def drum():
    """A cable drum on its rims, its axle along X, chocked: bone flanges, the cable wound in copper."""
    m = Mesh()
    r, wide = 1.7, 2.2
    turned = Mesh(None)
    for z0, z1, radius, sw in ((0.0, 0.22, r, "bone"), (wide - 0.22, wide, r, "bone"), (0.22, wide - 0.22, 1.05, "copper")):
        turned.lathe([(radius, z1), (radius, z0)], (0, 0, 0), 10, sw, caps=sw == "bone")
    for face, uv in zip(turned.f, turned.uv):                      # the lathe's Z laid along X, and stood on the floor
        m.face([(turned.v[i][2] - wide / 2, turned.v[i][1], r - turned.v[i][0]) for i in face], uv)
    for s in (-1, 1):
        m.box((wide, 0.5, 0.4), (0, s * 1.15, 0.2), "bone")
    return Piece("Drum", m, solid="a box, 2.2 by 3.4, 3.4 high", note="its axle lies along X: it rolls along Y")


def barrier():
    """A site barrier, 8 studs along X: two posts on rubber feet, a hazard board, a warning lamp on one post."""
    m = Mesh(None)
    for x in (-3.2, 3.2):
        m.box((0.5, 1.6, 0.3), (x, 0, 0.15), "rubber")
        post(m, x, 0, 0.3, 3.1, 0.22, "girder")
    m.box((7.6, 0.14, 0.9), (0, 0, 2.5), "yellow", pics=HAZARD)
    m.box((7.6, 0.1, 0.22), (0, 0, 1.3), "bone")
    m.box((0.4, 0.4, 0.45), (3.2, 0, 3.3), "beacon")
    return Piece("Barrier", m, solid="a wall, 8 long and 3 high", note="8 studs along X, centred on its place")


def cabin():
    """The site's cabin: a ribbed steel box on blocks, 10 studs by 4, a door and a lit window on its front, a lit end
    window, a lamp on its roof, an aerial with a beacon."""
    m = Mesh()
    for x in (-4.2, 4.2):
        for y in (-1.4, 1.4):
            m.box((1.0, 1.0, 0.6), (x, y, 0.3), "concrete")
    m.box((10.0, 4.0, 3.8), (0, 0, 2.5), "steel", pics={"+y": "panel", "-y": "panel"}, ink=True)
    m.box((10.06, 4.06, 0.4), (0, 0, 0.9), "yellow")
    m.box((10.4, 4.4, 0.3), (0, 0, 4.55), "bone", ink=True)
    m.box((1.4, 0.12, 2.6), (-3.0, 2.02, 2.4), "girder")
    m.box((2.6, 0.12, 1.3), (1.6, 2.02, 3.0), "lamp")
    m.box((0.12, 1.6, 1.1), (5.02, 0, 3.0), "lamp")
    m.box((1.8, 1.0, 0.5), (-3.0, 2.5, 0.25), "concrete")
    m.box((0.5, 0.5, 0.4), (4.4, 1.6, 4.9), "lamp")
    post(m, -4.4, -1.4, 4.7, 7.2, 0.08, "girder")
    m.box((0.3, 0.3, 0.3), (-4.4, -1.4, 7.35), "beacon")
    return Piece("Cabin", m, solid="a box, 10 by 4, 4.7 high", note="its door and its window face +Y")


PIECES = {"Crane": crane, "Frame": frame, "Scaffold": scaffold, "Foundation": foundation, "Stack": stack, "Drum": drum,
          "Barrier": barrier, "Cabin": cabin}
