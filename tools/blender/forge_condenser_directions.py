"""AR28: the Forge's and the Stone Condenser's three directions each, Stage I, for research's pick
(docs/asset-requests.md, AR28).

blender.exe -b --factory-startup --python tools/blender/forge_condenser_directions.py -- <out_dir> [fast]

Blocks in the base kit's own swatches, the family of the Breaker, the bays and the generator (base_machines.py): horns
of void stone with veins of the void's violet, shards floating, steel decks with a line of violet round their foot.
Each stands on a sleeping place's footprint, its deck 8.6 studs square, and under the Breaker's 12.8. It's set in the
yard as it stands (generator_directions' yard, the generator taken out) on the Breaker's inner side, 17.5 studs from
its middle, and seen from the game's camera behind a player 30 studs before the two:
  - in the kit's swatches, and as a grey block-in (every face grey but its light) beside the finished Breaker;
  - its silhouette in black, with the Breaker's;
  - at 64 px and 128 px tall.
Each is also seen close, from the game's camera behind a player 14 studs before it and 5 aside (the player hidden):
the Forge's at rest, at the tell and at the contact of the motion its rank-up rides, the Condenser's part-full. The
Condenser's are also seen from the gate, 86 studs off as on the halved base (spawn to its sleeping place at 128), at
full, part-full and empty. Each direction gets a sheet (forge_A.png ... condenser_C.png), each machine a glance sheet
and a 64 px sheet. The sheets are made after every view, since their text pass clears the scene's materials.

  The Forge     A, the Press    two horns curve in to an arch; a broad eight-sided ram drops between them
                B, the Clasp    two straight arms on meshed gears stand open in a V and clap shut over the item
                C, the Sting    one arm in five segments, a gear at each joint, hooks over the seat and strikes down
  The Condenser A, the Comb     an upright comb of six-sided cups, filling from the bottom up
                B, the Cup      six claws on three horns, tipped toward the gate, the stones heaped inside
                C, the Shelves  four shelves of cups stepping down toward the gate, filling from the lowest

The content check before drawing (2026-11-17) passed all six, on these conditions, kept here:
  - no red or orange, no drip or liquid shape, no text or emblem on any face;
  - the Press: the ram's underside flat and level, the ram wider than tall, the seat a flat lit plate, never a ring
    or notch; the horns visibly curved, never two parallel uprights; nothing overhangs where they meet;
  - the Clasp: the arms stone with gears and clamps, never hand-shaped, their tips never curled;
  - the Sting: a clear gear at each joint, never ribbed like a spine; the tip dry and faceted, never a needle; it
    strikes only the item;
  - the Comb: the cups six-sided, never stars;
  - the Cup: three separate, slightly curved horns, never a tight bundle, nothing standing out beside it; six claws,
    never five, never jointed like fingers;
  - the Shelves: every step an open row of cups, nothing lying on the top step, stones only in the cups.
"""

import math
import sys
import textwrap
from contextlib import contextmanager
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
from base_mill import FACING, Mesh, at, cable, disc, motes, prism, put, ring_up, rod, turned  # noqa: E402
import base_plan as plan  # noqa: E402
import blcommon as bl  # noqa: E402
import generator_directions as gd  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import lantern_row_look as look  # noqa: E402
import rook_sheet as rs  # noqa: E402
import ui_sheet as ui  # noqa: E402

BESIDE = (8.5, -46.0)      # the block's middle, on the Breaker's inner side (the scene's frame: x across, y = -in)
ME = (17.0, -16.0)         # the player, 30 studs before the two
TARGET = (17.0, -46.0, 6.0)
CLOSE = (BESIDE[0] - 5.0, BESIDE[1] + 14.0)   # the player 14 studs before the block, 5 aside, away from the Breaker
GATE_AT = (22.0, -93.0)    # 86 studs from the spawn, on the halved base's bearing to the Condenser's place
TO_GATE = ("BatteryRack_", "BatteryCell_")   # what stands on that line in today's yard, hidden for the gate's view
LIT = {"void", "cyan", "lamp", "power", "ink"}
DECK = 8.6


# --- shared shapes -----------------------------------------------------------------------------------------------------

def deck(m):
    m.box((DECK, DECK, 0.5), (0, 0, 0.25), "girder", ink=True)
    m.box((DECK + 0.1, DECK + 0.1, 0.1), (0, 0, 0.25), "void")


def item(m, centre):
    """The item's stand-in: a flat plate of bone."""
    m.box((1.6, 0.9, 0.22), centre, "bone", ink=True)


def stone(m, p, r=0.28):
    """A forge stone: small, faceted, the void's light."""
    bm.shard(m, p, r, r * 2.4, "void", lean=0.5)


def cog(m, centre, r, teeth, thick, sw="girder"):
    """A gear facing the gate (+Y), `r` its pitch radius, its teeth in proportion to it, a bone hub."""
    g = Mesh()
    p = math.tau * r / teeth
    add, ded, w_root, w_tip = 0.3 * p, 0.35 * p, 0.5 * p, 0.26 * p
    bm.hoop(g, (0, 0, 0), r * 0.32, r - ded + 0.02, thick, max(teeth, 8), sw, lying=True)
    r0, r1 = r - ded, r + add
    for k in range(teeth):
        a = math.tau * (k + 0.5) / teeth
        out, side = Vector((math.cos(a), math.sin(a), 0.0)), Vector((-math.sin(a), math.cos(a), 0.0))
        rim = [out * r0 - side * w_root / 2, out * r1 - side * w_tip / 2, out * r1 + side * w_tip / 2, out * r0 + side * w_root / 2]
        prism(g, rim, thick, sw, out * (r0 + r1) / 2)
    disc(g, (0, 0, 0), r * 0.34, thick + 0.12, "bone", axis=(0, 0, 1), sides=8)
    put(m, g, at(*centre) @ FACING)


def facing_ring(m, centre, r0, r1, thick, sw, sides=12, ink=True):
    """A ring standing on its edge, its face toward the gate."""
    t = Mesh() if ink else Mesh(None)
    bm.hoop(t, (0, 0, 0), r0, r1, thick, sides, sw, ink=ink, lying=True)
    put(m, t, at(*centre) @ FACING)


def burst(m, centre, r, flat=True):
    """The contact's stand-in for Faber's effect: a thin ring of light and motes thrown out from it."""
    x, y, z = centre
    if flat:
        ring_up(m, centre, r, r + 0.35, 0.06, "void", sides=16, ink=False)
        motes(m, [(x + (r + 0.9) * math.cos(a), y + (r + 0.9) * math.sin(a), z + 0.3) for a in np.linspace(0, math.tau, 9)[:-1]], 0.22)
    else:
        facing_ring(m, centre, r, r + 0.35, 0.06, "void", sides=16, ink=False)
        motes(m, [(x + (r + 0.9) * math.cos(a), y + 0.2, z + (r + 0.9) * math.sin(a)) for a in np.linspace(0, math.tau, 9)[:-1]], 0.22)


def cradle(m, x, y, n=3):
    """Where the stones go in: a low cradle of void stone, a bone lip, stones on its tray."""
    m.box((1.5, 1.5, 0.5), (x, y, 0.75), "abyss", ink=True)
    for s in (-1, 1):
        m.box((1.5, 0.16, 0.2), (x, y + s * 0.67, 1.08), "bone")
    for k in range(n):
        stone(m, (x - 0.4 + 0.4 * k, y, 1.35), 0.22)


def core(m, centre, r=1.0):
    """The Condenser's core: a ring of void stone facing the gate, four clamps reaching in from it, a shard of the
    void's light floating in the middle, and motes drawn in toward it."""
    x, y, z = centre
    facing_ring(m, centre, r, r + 0.35, 0.4, "abyss")
    for k in range(4):
        a = math.radians(45 + 90 * k)
        c, s = math.cos(a), math.sin(a)
        bm.horn(m, [(x + c * (r + 0.6), y, z + s * (r + 0.6)), (x + c * (r - 0.35), y, z + s * (r - 0.35))], [0.3, 0.05], "abyss")
    bm.shard(m, centre, 0.45, 1.6, "void")
    motes(m, [(x + (r + d) * math.cos(a), y + 0.1, z + (r + d) * math.sin(a))
              for a, d in ((0.3, 1.0), (1.4, 1.5), (2.6, 1.1), (3.5, 1.7), (4.4, 1.2), (5.6, 1.4))], 0.18)


def current_in(m, x):
    """The electricity it draws, in at its back on a cable."""
    m.box((1.1, 0.9, 0.8), (x, -3.6, 0.9), "girder", ink=True)
    cable(m, [(x, -4.9, 0.25), (x, -4.3, 0.25), (x, -3.6, 0.9)], r=0.24)


# --- the Forge ---------------------------------------------------------------------------------------------------------

def press(pose="rest"):
    """A, the Press: two horns rise from the deck's sides and curve in to meet over the seat, in a block with two
    meshing gears on its face. The ram, a broad eight-sided block with a flat disc of light under it, rides on two
    rods between the horns. Tell: it lifts high, its band lit. Contact: it drops onto the item."""
    m = Mesh()
    deck(m)
    m.box((3.2, 2.6, 2.0), (0, 0, 1.5), "abyss", ink=True)                 # the seat, its top at 2.5
    m.box((3.4, 2.8, 0.2), (0, 0, 2.6), "bone", ink=True)
    m.box((2.4, 1.8, 0.06), (0, 0, 2.73), "void")                          # the flat lit plate
    item(m, (0, 0, 2.87))
    for sx in (-1, 1):
        arch = [(sx * 3.2, 0, 0.5), (sx * 4.7, 0, 4.4), (sx * 4.1, 0, 8.8), (sx * 1.7, 0, 11.3)]
        widths = [0.8, 0.72, 0.58, 0.42]
        m.box((1.9, 2.2, 0.4), (sx * 3.2, 0, 0.7), "girder", ink=True)
        bm.horn(m, arch, widths, "abyss", deep=0.9)
        bm.vein(m, arch, widths, (0, 0, 6.0))
    m.box((3.6, 2.4, 1.6), (0, 0, 11.7), "abyss", ink=True)               # where they meet, inside their outer edge
    for sx in (-1, 1):
        cog(m, (sx * 0.85, 1.32, 11.7), 0.85, 8, 0.3)
    low = {"rest": 6.6, "tell": 8.4, "contact": 3.0}[pose]
    put(m, turned([(2.0, 1.5), (2.0, 0.0)], 8, "abyss"), at(0, 0, low))   # the ram: 4 across, 1.5 tall
    put(m, turned([(2.08, 0.3), (2.08, 0.0)], 8, "void" if pose == "tell" else "bone"), at(0, 0, low + 1.1))
    disc(m, (0, 0, low - 0.04), 1.6, 0.08, "void", axis=(0, 0, 1), sides=8, ink=False)
    for sx in (-1, 1):
        rod(m, (sx * 0.9, 0, 10.9), (sx * 0.9, 0, 9.6), 0.36, "girder")
        rod(m, (sx * 0.9, 0, 9.7), (sx * 0.9, 0, low + 1.5), 0.2, "steel")
    cradle(m, 3.0, 3.0)
    if pose == "contact":
        burst(m, (0, 0, 2.8), 2.4)
    return m


def clasp(pose="rest"):
    """B, the Clasp: a short pillar holds the item in a ring of light. Two straight arms of void stone, banded in
    steel, stand open in a V from axles at the pillar's foot, each on a gear, the two gears meshing in front of the
    pillar. Tell: the item rises in a column of light and the arms lean wider. Contact: they clap shut on it."""
    m = Mesh()
    deck(m)
    m.box((1.2, 1.2, 2.6), (0, 0, 1.8), "abyss", ink=True)
    m.box((1.5, 1.5, 0.2), (0, 0, 3.2), "bone", ink=True)
    lift = {"rest": 3.45, "tell": 6.4, "contact": 6.4}[pose]
    if pose != "rest":
        m.box((0.24, 0.24, lift - 3.3), (0, 0, (lift + 3.3) / 2), "void")
    ring_up(m, (0, 0, lift - 0.12), 0.95, 1.15, 0.1, "void", sides=12, ink=False)
    item(m, (0, 0, lift))
    lean = math.radians({"rest": 22.0, "tell": 32.0, "contact": 0.0}[pose])
    for sx in (-1, 1):
        foot = Vector((sx * 1.1, 0.0, 1.75))
        d = Vector((sx * math.sin(lean), 0.0, math.cos(lean)))
        turn = (0.0, sx * lean, 0.0)
        bm.horn(m, [tuple(foot), tuple(foot + d * 4.3)], [0.45, 0.4], "abyss", deep=1.2)
        for q in (1.6, 3.0):
            m.box((1.15, 1.3, 0.3), foot + d * q, "steel", rot=turn, ink=True)
        head = foot + d * 5.2
        m.box((1.9, 1.5, 2.2), head, "abyss", rot=turn, ink=True)             # the head: a flat-faced block
        inward = Vector((math.cos(sx * lean), 0.0, -math.sin(sx * lean))) * -sx
        m.box((0.06, 1.0, 1.5), head + inward * 0.97, "void", rot=turn)       # its striking face
        cog(m, (sx * 1.1, 0.95, 1.75), 1.1, 10, 0.4)
    if pose == "contact":
        burst(m, (0, 0.2, 6.9), 1.6, flat=False)
    cradle(m, 3.0, 3.0)
    return m


STING = {"base": (-3.2, 1.4), "lengths": (4.0, 3.4, 2.8, 2.3, 2.1),
         "poses": {"rest": (108, (-40, -42, -51, -56, -34)), "tell": (121, (-25, -30, -38, -45, -30)),
                   "contact": (109, (-63, -57, -44, -37, -31))}}   # each pose's first heading and its bends, solved
                                                                  # so the tip lands on the seat (build/scratch, ar28)


def sting_points(pose):
    a, bends = STING["poses"][pose]
    pts = [STING["base"]]
    for k, length in enumerate(STING["lengths"]):
        if k:
            a += bends[k - 1]
        x, z = pts[-1]
        pts.append((x + length * math.cos(math.radians(a)), z + length * math.sin(math.radians(a))))
    return [(x, 0.0, z) for x, z in pts]


def sting(pose="rest"):
    """C, the Sting: from a block at the deck's left, one arm of void stone in five segments, a gear on each joint,
    rises and hooks over the seat on the right. Its last segment is a broad faceted point with a lit core. Tell: the
    arm draws up and back. Contact: the point strikes down onto the item."""
    m = Mesh()
    deck(m)
    m.box((2.6, 2.4, 2.0), (1.8, 0, 1.5), "abyss", ink=True)
    m.box((2.8, 2.6, 0.2), (1.8, 0, 2.6), "bone", ink=True)
    m.box((2.0, 1.6, 0.06), (1.8, 0, 2.73), "void")
    item(m, (1.8, 0, 2.87))
    m.box((2.6, 2.6, 0.9), (-3.2, 0, 0.95), "abyss", ink=True)               # the arm's block
    pts = [Vector(p) for p in sting_points(pose)]
    widths = (0.72, 0.64, 0.56, 0.48, 0.45)
    for k in range(4):
        bm.horn(m, [tuple(pts[k]), tuple(pts[k + 1])], [widths[k], widths[k + 1]], "abyss")
    mid = pts[4] + (pts[5] - pts[4]) * 0.45
    bm.horn(m, [tuple(pts[4]), tuple(mid), tuple(pts[5])], [0.45, 0.85, 0.16], "abyss")   # the point, broad and blunt
    bm.vein(m, [tuple(p) for p in pts[:5]], list(widths), (0.5, 0, 5.5))
    d = (pts[5] - pts[4]).normalized()
    m.box((0.36, 0.06, 0.6), mid + Vector((0, 0.87, 0)), "void", rot=(0.0, math.atan2(d.x, d.z), 0.0))
    cog(m, (pts[0].x, 1.45, pts[0].z), 0.7, 8, 0.36)
    for p in pts[1:5]:
        cog(m, (p.x, 0.78, p.z), 0.6, 8, 0.3)
    cradle(m, -1.0, 3.1)
    if pose == "contact":
        burst(m, (1.8, 0, 2.8), 1.5)
    return m


# --- the Stone Condenser ------------------------------------------------------------------------------------------------

def comb(fill=0.5):
    """A, the Comb: an upright panel of void stone facing the gate, held from its sides by two horns that close over
    its top, the core between their tips. Its face is a comb of six-sided cups; the stones go into the lowest empty
    cup, so the lit height is the fill."""
    m = Mesh()
    deck(m)
    m.box((5.0, 0.9, 0.5), (0, -0.4, 0.75), "girder", ink=True)
    m.box((7.0, 1.0, 6.4), (0, -0.4, 4.2), "abyss", ink=True)                # z 1 to 7.4
    R = 0.6
    cells = []
    for col in range(7):
        for row in range(5):
            x = (col - 3) * 1.5 * R * 1.02
            z = 1.75 + row * math.sqrt(3) * R * 1.02 + (col % 2) * math.sqrt(3) / 2 * R
            if z < 7.0:
                cells.append((z, x))
    cells.sort()
    full = round(len(cells) * fill)
    for k, (z, x) in enumerate(cells):
        facing_ring(m, (x, 0.2, z), R * 0.72, R * 0.98, 0.3, "girder", sides=6)
        lit = k < full
        disc(m, (x, 0.12, z), R * 0.74, 0.06, "void" if lit else "ink", axis=(0, 1, 0), sides=6, ink=False)
        if lit:
            stone(m, (x, 0.42, z), 0.24)
    for sx in (-1, 1):
        side = [(sx * 3.75, -0.4, 0.5), (sx * 4.3, -0.4, 4.2), (sx * 3.9, -0.4, 7.9), (sx * 1.5, -0.4, 9.9)]
        widths = [0.75, 0.68, 0.55, 0.08]
        m.box((1.8, 2.0, 0.4), (sx * 3.75, -0.4, 0.7), "girder", ink=True)
        bm.horn(m, side, widths, "abyss", deep=0.9)
        bm.vein(m, side, widths, (0, -0.4, 5.0))
    core(m, (0, -0.4, 9.5), 0.95)
    current_in(m, 1.2)
    cradle(m, -3.0, 3.2, n=2)
    return m, len(cells)


def cup(fill=0.5):
    """B, the Cup: three separate horns, a little curved, rise to a hub, and over it six claws open in a cup tipped
    toward the gate, a ring round their middles. The stones heap inside, and the ring's eight marks light from the
    cup's low side up as it fills. The core floats over it."""
    m = Mesh()
    deck(m)
    for k in range(3):
        a = math.radians(-90 + 120 * k)
        c, s = math.cos(a), math.sin(a)
        stalk = [(1.5 * c, 1.5 * s, 0.5), (1.3 * c, 1.3 * s, 2.8), (0.8 * c, 0.8 * s, 4.9)]
        bm.horn(m, stalk, [0.5, 0.42, 0.34], "abyss", flat=(-s, c, 0.0))
        m.box((1.2, 1.2, 0.4), (1.5 * c, 1.5 * s, 0.7), "girder", ink=True)
    put(m, turned([(1.05, 0.8), (1.05, 0.0)], 8, "abyss"), at(0, 0, 4.9))
    tip = at(0, 0, 5.6) @ Matrix.Rotation(math.radians(-30.0), 4, "X")          # the cup's own frame, its axle leaning to the gate
    c = Mesh()
    for k in range(6):
        a = math.radians(30 + 60 * k)
        cs, sn = math.cos(a), math.sin(a)
        claw = [(0.85 * cs, 0.85 * sn, 0.1), (1.9 * cs, 1.9 * sn, 1.0), (2.5 * cs, 2.5 * sn, 2.3)]
        bm.horn(c, claw, [0.42, 0.36, 0.06], "abyss", flat=(-sn, cs, 0.0))
    put(c, turned([(0.95, 0.25), (0.95, 0.0)], 8, "abyss"), at(0, 0, 0.0))     # the floor under the heap
    bm.hoop(c, (0, 0, 1.25), 1.95, 2.2, 0.22, 16, "abyss", lying=True)
    marks = sorted(range(8), key=lambda i: abs(((22.5 + 45 * i) - 90 + 180) % 360 - 180))
    lit = set(marks[:round(8 * fill)])
    for i in range(8):
        a = math.radians(22.5 + 45 * i)
        c.box((0.5, 0.12, 0.3), (2.25 * math.cos(a), 2.25 * math.sin(a), 1.25), "void" if i in lit else "ink",
              rot=(0.0, 0.0, a + math.pi / 2))
    heap = [(0.0, 0.0, 0.45)] + [(0.7 * math.cos(math.tau * k / 6), 0.7 * math.sin(math.tau * k / 6), 0.45) for k in range(6)]
    heap += [(1.2 * math.cos(math.tau * (k + 0.5) / 9), 1.2 * math.sin(math.tau * (k + 0.5) / 9), 0.7) for k in range(9)]
    heap += [(0.4 * math.cos(math.tau * k / 4), 0.4 * math.sin(math.tau * k / 4), 0.95) for k in range(4)]
    heap += [(1.0 * math.cos(math.tau * (k + 0.3) / 7), 1.0 * math.sin(math.tau * (k + 0.3) / 7), 1.15) for k in range(7)]
    heap += [(0.0, 0.0, 1.4)] + [(0.55 * math.cos(math.tau * k / 5), 0.55 * math.sin(math.tau * k / 5), 1.5) for k in range(5)]
    for p in heap[:round(len(heap) * fill)]:
        stone(c, p, 0.3)
    put(m, c, tip)
    core(m, tuple(tip @ Vector((0, 0, 3.7))), 0.9)
    current_in(m, 1.2)
    cradle(m, -3.0, 3.2, n=2)
    return m, len(heap)


def shelves(fill=0.5):
    """C, the Shelves: four shelves stepping down toward the gate, each an open row of six cups, and under each cup a
    mark on the step's lip. The stones go into the lowest shelf first, so the stair's lit height is the fill. Behind
    the top, two horns rise and hold the core between their tips."""
    m = Mesh()
    deck(m)
    back = -2.4
    cups = []
    for k in range(4):
        front, top = 2.4 - 1.2 * k, 0.5 + 0.9 * (k + 1)
        m.box((7.0, front - back, top - 0.5), (0, (front + back) / 2, (top + 0.5) / 2), "abyss", ink=True)
        m.box((7.1, 0.16, 0.14), (0, front, top - 0.07), "bone")
        for j in range(6):
            cups.append((k, j, -2.75 + 1.1 * j, front - 0.6, top, front))
    full = round(len(cups) * fill)
    for n, (k, j, x, y, top, front) in enumerate(cups):
        lit = n < full
        bm.hoop(m, (x, y, top + 0.08), 0.3, 0.46, 0.2, 8, "girder", lying=True)
        disc(m, (x, y, top + 0.05), 0.32, 0.06, "void" if lit else "ink", axis=(0, 0, 1), sides=8, ink=False)
        m.box((0.86, 0.06, 0.3), (x, front + 0.03, top - 0.4), "void" if lit else "ink")
        if lit:
            stone(m, (x, y, top + 0.45), 0.26)
    for sx in (-1, 1):
        side = [(sx * 3.0, -2.9, 0.5), (sx * 3.5, -2.9, 4.6), (sx * 3.1, -2.9, 7.4), (sx * 1.4, -2.9, 9.0)]
        widths = [0.7, 0.62, 0.5, 0.08]
        m.box((1.7, 1.6, 0.4), (sx * 3.0, -2.9, 0.7), "girder", ink=True)
        bm.horn(m, side, widths, "abyss", deep=0.9)
        bm.vein(m, side, widths, (0, -2.9, 5.0))
    core(m, (0, -2.9, 8.5), 0.9)
    m.tube([Vector((0.0, -2.6, 7.4)), Vector((0.0, -2.45, 4.25))], 0.1, "void")    # the groove the stones roll down
    current_in(m, 1.2)
    cradle(m, -3.0, 3.4, n=2)
    return m, len(cups)


FORGE = (
    ("A", "the Press", press, (
        "Two horns of void stone rise from the deck's sides and curve in to meet over the seat, in a block with two "
        "meshing gears on its face. Between them the ram, a broad eight-sided block with a flat disc of light under "
        "it, rides on two rods. The item lies on the seat's flat lit plate. The motion is a press: the ram lifts high, "
        "its band lit (the tell), drops onto the item (the contact), and lifts back. The stones go in at the cradle on "
        "the front corner, and their light runs up the horns' veins.",
        "Growth: Stage II has a heavier ram on four rods and the horns plated. Stage III has a second pair of horns "
        "across the first, the ram's face carved in a ring of light.")),
    ("B", "the Clasp", clasp, (
        "A short pillar holds the item in a ring of light. Two straight arms of void stone, banded in steel, stand open "
        "in a V from axles at the pillar's foot, each on a gear, and the two gears mesh in front of the pillar, so the "
        "arms always move together. Each carries a flat-faced head. The motion is a clap: the item rises in a column "
        "of light and the arms lean wider (the tell), they clap shut on it (the contact), and open as it sinks back.",
        "Growth: Stage II has a second, shorter pair of arms at right angles to the first. Stage III has the arms "
        "ribbed with clamps, and the pillar floats.")),
    ("C", "the Sting", sting, (
        "From a block at the deck's left, one arm of void stone in five segments, a gear on each joint, rises and "
        "hooks over the seat on the right. Its last segment is a broad faceted point with a lit core. The motion is a "
        "strike: the arm draws up and back (the tell), the point strikes down onto the item (the contact), and it "
        "curls back. Of the three it's the one whose silhouette is its own: a hook, unlike any machine in the base.",
        "Growth: Stage II has a second, shorter arm beside it. Stage III has the segments plated and the point three "
        "points. \"Sting\" is a working name: players see the Forge.")),
)
CONDENSER = (
    ("A", "the Comb", comb, (
        "An upright panel of void stone faces the gate, held from its sides by two horns that close over its top, with "
        "the core between their tips: a ring with four clamps round a floating shard, drawing motes in. Its face is a "
        "comb of six-sided cups. Each stone the core makes drops into the lowest empty cup, so the comb fills from the "
        "bottom up and its lit height is the fill: a whole lit face when full, a dark comb when empty.",
        "Growth: Stage II has a wider comb on four horns. Stage III has a second comb behind it at an angle, and the "
        "core in two rings.")),
    ("B", "the Cup", cup, (
        "Three separate horns of void stone, a little curved, rise to a hub, and over it six claws open in a cup tipped "
        "toward the gate, a ring round their middles. The stones heap inside as they come, and the ring's eight marks "
        "light from the cup's low side up as it fills. The core floats over the cup.",
        "Growth: Stage II has a second, lower cup on the other side. Stage III has three cups round the stalk, "
        "stepped, never in one row.")),
    ("C", "the Shelves", shelves, (
        "Four shelves step down toward the gate, each an open row of six cups, with a mark under each cup on the "
        "step's lip. Behind the top, two horns rise and hold the core between their tips, and the stones it makes "
        "roll down a groove to the lowest shelf. The shelves fill from the lowest up, so the stair's lit height is the "
        "fill: the whole stair lit when full, a dark stair when empty.",
        "Growth: Stage II has a wider stair with a second core. Stage III has the stair round in a half ring.")),
)
COMMON = ("Blocks in the base kit's own swatches, rendered in Blender under the place's dusk; nothing is seen in Studio. "
          "Each stands on the Breaker's inner side, 17.5 studs from its middle, its deck 8.6 studs square, the size of "
          "a sleeping place. The white figures are a player's size. Violet is the void's light, yellow is electricity.")


# --- the bench ---------------------------------------------------------------------------------------------------------

@contextmanager
def grey():
    """Every swatch but the lit ones built as the kit's concrete: the block-in's grey."""
    real = kit.sw_uv
    kit.sw_uv = lambda name, occ, t: real(name if name in LIT else "concrete", occ, t)
    try:
        yield
    finally:
        kit.sw_uv = real


class Bench:
    def __init__(self, out, fast):
        self.out = out
        self.scene, self.yard, self.d = gd.yard_without_generator(out, fast)
        self.yard.person(ME, "Me")
        self.people = ("Avatar", "Me", *gd.PLAYERS)
        self.near = (gd.player_view(ME, TARGET)[0], TARGET)
        self.gate = (gd.player_view((0.0, -10.0), (*GATE_AT, 0.0))[0], (*GATE_AT, 4.5))
        self.close = (gd.player_view(CLOSE, (*BESIDE, 0.0))[0], (*BESIDE, 5.5))
        self.later = []           # the sheets, made after every view: their text pass clears the scene
        self.tris = {}

    def stand(self, key, mesh, where):
        data = mesh.whole().to_object(key, self.yard.stock.mats["Kit"])
        obj = bpy.data.objects.new(key, data)
        obj.location = (*where, 0.0)
        self.scene.collection.objects.link(obj)
        self.tris.setdefault(key.split("_")[0], mesh.whole().tris())
        return obj

    def drop(self, obj):
        data = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(data)

    def camera(self, name, view):
        eye, target = view
        self.scene.camera = plan.camera(self.scene, f"Cam{name}", eye, target)
        return self.scene.camera

    def people_seen(self, who):
        for person in self.people:
            for part in ("Legs", "Body", "Head"):
                obj = bpy.data.objects.get(f"{person}{part}")
                if obj is not None:
                    obj.hide_render = person != who

    def shot(self, name, view, who="Me", hide=()):
        self.people_seen(who)
        hidden = [o for o in self.scene.objects if hide and o.name.startswith(hide) and not o.hide_render]
        for o in hidden:
            o.hide_render = True
        self.camera(name, view)
        path = self.out / f"{name}.png"
        px = look.finish(look.render_linear(self.scene, path.with_suffix(".exr")), self.d)
        rs.save(px, path)
        path.with_suffix(".exr").unlink(missing_ok=True)
        for o in hidden:
            o.hide_render = False
        return px

    def silhouette(self, name, keep, view):
        """Black on white: only the objects named from `keep`, from the view."""
        self.camera(name, view)
        hidden = [o for o in self.scene.objects if o.type == "MESH" and not o.hide_render and not o.name.startswith(keep)]
        for o in hidden:
            o.hide_render = True
        self.scene.render.film_transparent = True
        path = self.out / f"{name}.exr"
        alpha = look.render_linear(self.scene, path)[..., 3]
        path.unlink(missing_ok=True)
        self.scene.render.film_transparent = False
        for o in hidden:
            o.hide_render = False
        px = np.ones((*alpha.shape, 4), np.float32)
        px[..., :3] = 1.0 - np.clip(alpha, 0, 1)[..., None] * 0.96
        rs.save(px, self.out / f"{name}.png")
        return px

    def frame(self, objs, view, pad=8):
        """The rows and columns of the view that hold `objs`, from their corners projected."""
        cam = self.camera("Frame", view)
        bpy.context.view_layer.update()     # a new camera's and a new piece's places, before projecting
        w, h = look.SIZE
        xs, ys = [], []
        for obj in objs:
            for v in obj.data.vertices:
                p = world_to_camera_view(self.scene, cam, obj.matrix_world @ v.co)
                xs.append(p.x * w)
                ys.append((1 - p.y) * h)
        return (max(0, int(min(ys)) - pad), min(h, int(max(ys)) + pad), max(0, int(min(xs)) - pad), min(w, int(max(xs)) + pad))


def cut(px, box):
    r0, r1, c0, c1 = box
    return px[r0:r1, c0:c1]


def tall(px, height):
    return rs.shrink(px, height / px.shape[0])


def bigger(px, k):
    return np.repeat(np.repeat(px, k, axis=0), k, axis=1)


def fit(px):
    """Drawn the most whole times its size that fits a cell."""
    w, h = look.SIZE
    return bigger(px, max(1, min(w // px.shape[1], h // px.shape[0])))


def sheet(out, name, title, notes, cells, cols=2):
    gap, w, h = 16, *look.SIZE
    rows = (len(cells) + cols - 1) // cols
    lines = [line for n in notes for line in textwrap.wrap(n, 210)]
    width = cols * w + (cols + 1) * gap
    height = 48 + rows * (h + 34) + 14 + len(lines) * 19 + 16
    s = ui.Sheet(width, height, "#14151C")
    t = s.tile(0, 0, s.w, s.h)
    t.text(gap, 14, 20, title, "#EDE6D6", bold=0.2)
    for i, (caption, px) in enumerate(cells):
        x, y = gap + (i % cols) * (w + gap), 48 + (i // cols) * (h + 34)
        t.text(x, y, 14, caption, "#B4AC9C")
        rs.paste(s.px, px, x + (w - px.shape[1]) // 2, y + 22 + (h - px.shape[0]) // 2)
    y = 48 + rows * (h + 34) + 6
    for i, line in enumerate(lines):
        t.text(gap, y + i * 19, 14, line, "#B4AC9C")
    for layer in ui.text_layers(s.px.shape[1], s.px.shape[0], s.items).values():
        rs.paste(s.px, layer, 0, 0)
    rs.save(s.px, out / name)


def strip(out, name, title, rows):
    """Each direction at 64 px and 128 px tall over the dark, and its silhouette at 64 px over white."""
    gap = 16
    cells = []
    for label, look_px, black in rows:
        small, big, shape = tall(look_px, 64), tall(look_px, 128), tall(black, 64)
        cells.append((label, small, big, shape))
    width = gap + sum(max(c[2].shape[1], c[1].shape[1] + c[3].shape[1] + gap) + 2 * gap for c in cells)
    width = max(width, 2 * gap + 7 * len(title))      # the title whole, at about 7 px a letter
    s = ui.Sheet(width, 44 + 128 + 64 + 3 * gap + 26, "#0E0F14")
    t = s.tile(0, 0, s.w, s.h)
    t.text(gap, 12, 14, title, "#B4AC9C")
    x = gap
    for label, small, big, shape in cells:
        rs.paste(s.px, small, x, 40)
        rs.paste(s.px, shape, x + small.shape[1] + gap, 40)
        rs.paste(s.px, big, x, 40 + 64 + gap)
        t.text(x, 40 + 64 + 128 + 2 * gap - 4, 13, label, "#EDE6D6")
        x += max(big.shape[1], small.shape[1] + shape.shape[1] + gap) + 2 * gap
    for layer in ui.text_layers(s.px.shape[1], s.px.shape[0], s.items).values():
        rs.paste(s.px, layer, 0, 0)
    rs.save(s.px, out / name)


def glance(out, name, title, shots):
    gap = 16
    w, h = (round(v * 2 / 3) for v in look.SIZE)
    s = ui.Sheet(3 * w + 4 * gap, 48 + h + 30, "#14151C")
    t = s.tile(0, 0, s.w, s.h)
    t.text(gap, 12, 18, title, "#EDE6D6", bold=0.2)
    for i, (label, px) in enumerate(shots):
        x = gap + i * (w + gap)
        t.text(x, 40, 15, label, "#EDE6D6")
        rs.paste(s.px, rs.shrink(px, 2 / 3), x, 64)
    for layer in ui.text_layers(s.px.shape[1], s.px.shape[0], s.items).values():
        rs.paste(s.px, layer, 0, 0)
    rs.save(s.px, out / name)


def breaker_parts(scene):
    return [o for o in scene.objects if o.name.startswith(("Breaker_", "BreakerChamber_", "BreakerWaiting_"))]


def forge(bench, out):
    rows, near = [], []
    for key, title, build, notes in FORGE:
        tag = f"Forge{key}"
        obj = bench.stand(f"{tag}_rest", build("rest"), BESIDE)
        box = bench.frame([obj], bench.near)
        both = bench.frame([obj] + breaker_parts(bench.scene), bench.near)
        rest = bench.shot(f"forge_{key}_beside", bench.near)
        black = bench.silhouette(f"forge_{key}_silhouette", (f"{tag}_", "Breaker"), bench.near)
        close = {"rest": bench.shot(f"forge_{key}_close_rest", bench.close, who=None)}
        bench.drop(obj)
        with grey():
            obj = bench.stand(f"{tag}_grey", build("rest"), BESIDE)
        greyed = bench.shot(f"forge_{key}_grey", bench.near)
        bench.drop(obj)
        for pose in ("tell", "contact"):
            obj = bench.stand(f"{tag}_{pose}", build(pose), BESIDE)
            close[pose] = bench.shot(f"forge_{key}_close_{pose}", bench.close, who=None)
            bench.drop(obj)
        cells = [("Stage I at rest beside the Breaker, from the game's camera 30 studs before the two", rest),
                 ("The grey block-in beside the finished Breaker (every face grey but its light)", greyed),
                 ("At rest, from the game's camera behind a player 14 studs before it (the player hidden)", close["rest"]),
                 ("The tell: it draws back and gathers its light", close["tell"]),
                 ("The contact: it strikes the item (the burst is a stand-in for Faber's effect)", close["contact"]),
                 ("Its silhouette in black, with the Breaker's, from the 30 studs' view, drawn larger", fit(cut(black, both)))]
        bench.later.append((sheet, (out, f"forge_{key}.png", f"Grow your Anime, the Forge: {key}, {title}", notes + (
            COMMON + f" Triangles, Stage I with the drawn edge: {bench.tris[tag]:,}.",), cells)))
        rows.append((f"{key}, {title}", cut(rest, box), cut(black, box)))
        near.append((f"{key}, {title}", rest))
    bench.later.append((strip, (out, "forge_64.png", "The Forge's directions at 64 px and 128 px tall, at rest, from the "
                                                     "game's camera 30 studs off; the silhouette at 64 px", rows)))
    bench.later.append((glance, (out, "forge_glance.png", "The Forge's three directions beside the Breaker, from the game's camera", near)))


def condenser(bench, out):
    rows, near = [], []
    for key, title, build, notes in CONDENSER:
        tag = f"Condenser{key}"
        mesh, count = build(0.5)
        obj = bench.stand(f"{tag}_half", mesh, BESIDE)
        box = bench.frame([obj], bench.near)
        both = bench.frame([obj] + breaker_parts(bench.scene), bench.near)
        half = bench.shot(f"condenser_{key}_beside", bench.near)
        close = bench.shot(f"condenser_{key}_close", bench.close, who=None)
        black = bench.silhouette(f"condenser_{key}_silhouette", (f"{tag}_", "Breaker"), bench.near)
        bench.drop(obj)
        with grey():
            obj = bench.stand(f"{tag}_grey", build(0.5)[0], BESIDE)
        greyed = bench.shot(f"condenser_{key}_grey", bench.near)
        bench.drop(obj)
        gates, gate_box = {}, None
        for fill, word in ((1.0, "full"), (0.5, "half"), (0.0, "empty")):
            obj = bench.stand(f"{tag}_{word}", build(fill)[0], GATE_AT)
            gate_box = gate_box or bench.frame([obj], bench.gate, pad=10)
            gates[word] = bench.shot(f"condenser_{key}_gate_{word}", bench.gate, who="Avatar", hide=TO_GATE)
            bench.drop(obj)
        crops = [cut(gates[w], gate_box) for w in ("full", "half", "empty")]
        ch, cw = crops[0].shape[:2]
        k = max(1, min(290 // max(cw, 1), 480 // max(ch, 1)))
        states = rs.canvas(look.SIZE[0], look.SIZE[1], (0.08, 0.08, 0.11))
        for i, c in enumerate(crops):
            rs.paste(states, bigger(c, k), 15 + i * (cw * k + 20), 30)
        cells = [(f"Stage I part-full ({round(count / 2)} of {count}) beside the Breaker, from the game's camera 30 studs before the two", half),
                 ("The grey block-in beside the finished Breaker (every face grey but its light)", greyed),
                 ("Part-full, from the game's camera behind a player 14 studs before it (the player hidden)", close),
                 ("From the gate, 86 studs off as on the halved base, full: the game's whole view", gates["full"]),
                 (f"From the gate: full, part-full, empty, cut from that view and drawn {k} times its size", states),
                 ("Its silhouette in black, with the Breaker's, from the 30 studs' view, drawn larger", fit(cut(black, both)))]
        bench.later.append((sheet, (out, f"condenser_{key}.png", f"Grow your Anime, the Stone Condenser: {key}, {title}", notes + (
            COMMON + " The gate's view hides today's battery, which stands on that line in the yard as it is; the "
                     f"re-lay at 128 keeps the line clear. Triangles, Stage I part-full with the drawn edge: {bench.tris[tag]:,}.",), cells)))
        rows.append((f"{key}, {title}", cut(half, box), cut(black, box)))
        near.append((f"{key}, {title}", half))
    bench.later.append((strip, (out, "condenser_64.png", "The Condenser's directions at 64 px and 128 px tall, part-full, "
                                                         "from the game's camera 30 studs off; the silhouette at 64 px", rows)))
    bench.later.append((glance, (out, "condenser_glance.png", "The Stone Condenser's three directions beside the Breaker, "
                                                              "part-full, from the game's camera", near)))


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    bench = Bench(out, "fast" in args)
    ui.K = 1
    if "condenser" not in args:
        forge(bench, out)
    if "forge" not in args:
        condenser(bench, out)
    for make, made in bench.later:
        make(*made)
    print("triangles:", bench.tris)


if __name__ == "__main__":
    main()
