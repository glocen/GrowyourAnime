"""AR28: the Forge and the Stone Condenser, Stage I (docs/asset-requests.md, AR28), on research's pick of 2026-11-17,
12:20: the Forge's A, the Press, and the Condenser's A, the Comb. They are base_kit.py's pieces like the machines: on
the kit's own atlas, a piece's front toward +Y (the Strip), its origin on the floor at its middle, one unit a stud.
Each stands on its sleeping place (plan.json, layout, sleeping) in the SleepingStone's stead once the builder wakes it.

The Forge, the Press (`Forge`, `ForgeRam`, `ForgeGear`): two horns of void stone rise from the deck's sides and curve
in to meet over the seat, in a head of void stone with two meshing gears on its face. Between them hangs the ram, a
broad eight-sided block with a flat disc of the void's light under it and a band of it round its crown, on two rods
that slide up into sleeves under the head. The item lies on the seat's flat lit plate. The rank-up rides one motion:
the ram lifts to the sleeves' foot, its band lit, the gears turning, the rods' bone caps rising out of the head (the
tell); it drops onto the item (the contact); it lifts back (the recovery). The stones go in at the cradle on the front
corner, and a vein runs from it to the right horn's foot and up the horn.

The Stone Condenser, the Comb (`Condenser`, `CondenserCore`, `CondenserStone`, `CondenserJewel`): a six-sided panel of
void stone facing the gate, set in two horns that hug its sides and close over its top, the core between their tips: a
ring with four clamps round a floating shard, turning while it works, still when the tray is full. The panel's face is
a comb of 37 six-sided cups in seven rows, 4 to 7 to 4, and it is the tray: each stone or jewel the Condenser makes
goes into the lowest empty cup, so the comb fills from the bottom row up and its lit height is the fill. An empty cup
is dark. A cup with a stone is `CondenserStone` stood in it, lit in the void's violet. A cup with a jewel is
`CondenserJewel`, one pale swatch the builder tints in the jewel type's colour, so a jewel's cup reads from a stone's
(the director, 2026-11-17, 12:10: the Condenser makes jewels too, from launch). Its electricity comes in on a cable at
its back; the five-into-one is the small cradle on its front corner.

The content check before drawing (2026-11-17), kept: no red or orange in the machines' own light, no drip or liquid,
no text or emblem; the Press's ram flat underneath and wider than tall, its horns visibly curved, nothing overhanging
where they meet; the Comb's cups six-sided. On the blocks' renders: the Press's contact light stays flat round the
plate, never a ring standing upright at the seat (the builder's effect).

blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_forge.py -- <abs out_dir> [fast]
renders Stage I's review sheets beside the Breaker, on forge_condenser_directions.py's bench. base_kit.py takes PIECES
into its own for the handoff.
"""

import math
import sys
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
from base_mill import FACING, Mesh, at, bar, cable, disc, motes, prism, put, rod, turned  # noqa: E402
import lantern_row_kit as kit  # noqa: E402

Piece = kit.Piece
DECK = 8.6                # a sleeping place's deck, square
PLATE = 2.76              # the Forge's seat: its lit plate's top, up from the floor, where the item lies
HEAD = (10.9, 12.5)       # the Forge's head: its foot and its top
SLEEVE = 8.8              # the sleeves' foot, under the head: the ram's crown never rises past it
RAM = (2.0, 1.5)          # the ram: its radius at its corners, its height
RODS = (0.9, 4.9, 0.2)    # the ram's rods: across each side, their length over its crown, their radius
POSES = {"rest": 5.6, "tell": 7.2, "contact": 2.8}   # the ram's underside, up from the floor; 2.8 lays it on the plate
GEAR = (0.85, 1.32, 11.7, 8)   # a gear: across each side, out toward the front, up; and its teeth. Its pitch radius is its across
TURN = 90.0               # the gears' turn, degrees a stud of the ram's rise, for the review's poses
CELL = (0.5, 1.04)        # a cup: its six-sided radius, and the spacing over touching
FACE = 0.1                # the comb's face, along +Y from the Condenser's middle
PANEL = (4.04, 0.14)      # the comb's panel: its middle up from the floor, its margin round the cups
CORE = (0.0, -0.4, 9.5)   # the core's middle: across, along +Y, up
ROWS = (4, 5, 6, 7, 6, 5, 4)


# --- shared shapes -----------------------------------------------------------------------------------------------------

def deck(m):
    """A sleeping place's deck, as a machine's: steel, a line of the void's light round its foot."""
    m.box((DECK, DECK, 0.5), (0, 0, 0.25), "girder", ink=True)
    m.box((DECK + 0.1, DECK + 0.1, 0.1), (0, 0, 0.25), "void")


def stone(m, p, r=0.22):
    """A forge stone: small, faceted, upright, the void's light."""
    bm.shard(m, p, r, r * 2.4, "void", lean=0.5)


def cradle(m, x, y, stones=0):
    """A low cradle of void stone on the deck, a bone lip each side and a lit mark on its tray."""
    m.box((1.5, 1.5, 0.5), (x, y, 0.75), "abyss", ink=True)
    for s in (-1, 1):
        m.box((1.5, 0.16, 0.2), (x, y + s * 0.67, 1.08), "bone")
    m.box((0.9, 0.5, 0.04), (x, y, 1.02), "void")
    for k in range(stones):
        stone(m, (x - 0.4 + 0.4 * k, y, 1.35))


CRACK = ((0.42, 0.05), (0.55, 0.16), (0.68, 0.1))   # a gear's vein: its bends, out from the hub, as parts of r
FIELD = (0.72, 1.205)     # the lit field behind the gears: its half height, inside the teeth's tips; its face, along +Y


def field(m, x, z, w):
    """The void's light behind gears, `w` across round (x, z) on the head's face, in the light's deep violet: the dark
    gears and their teeth read against it, and the field's edges show the teeth biting past it."""
    hh, y = FIELD
    pts = [Vector((x - w / 2, y, z - hh)), Vector((x + w / 2, y, z - hh)), Vector((x + w / 2, y, z + hh)),
           Vector((x - w / 2, y, z + hh))]
    m.out(pts, [kit.sw_uv("voidfield", 0.0, 0.0)] * 4, Vector((x, y - 1.0, z)))   # one step under the void's glow


def cog(r, teeth, thick):
    """A gear about Z, `r` its pitch radius, its teeth in proportion to it and narrower than the gaps: void stone, as
    the horns are, never steel (research, AR36's picks), with a vein of the void's light on its face, one crack from
    the hub's edge out, short of the teeth's root, and an unlit bone hub."""
    g = Mesh()
    p = math.tau * r / teeth
    add, ded, w_root, w_tip = 0.3 * p, 0.35 * p, 0.5 * p, 0.26 * p
    bm.hoop(g, (0, 0, 0), r * 0.32, r - ded + 0.02, thick, max(teeth, 8), "abyss", lying=True)
    r0, r1 = r - ded, r + add
    for k in range(teeth):
        a = math.tau * (k + 0.5) / teeth
        out, side = Vector((math.cos(a), math.sin(a), 0.0)), Vector((-math.sin(a), math.cos(a), 0.0))
        rim = [out * r0 - side * w_root / 2, out * r1 - side * w_tip / 2, out * r1 + side * w_tip / 2, out * r0 + side * w_root / 2]
        prism(g, rim, thick, "abyss", out * (r0 + r1) / 2)
    face = thick / 2 + 0.015
    crack = [Vector((r * u, r * v, face)) for u, v in CRACK]
    for a, b in zip(crack, crack[1:]):
        bar(g, a, b, 0.07 * r / 0.85, "void", d=0.03, ink=False)
    disc(g, (0, 0, 0), r * 0.34, thick + 0.12, "bone", axis=(0, 0, 1), sides=8)
    return g


def hexagon(x, y, z, r):
    """A six-sided ring of corners facing the front, a corner up, round (x, y, z)."""
    return [Vector((x + r * math.cos(math.radians(90 + 60 * k)), y, z + r * math.sin(math.radians(90 + 60 * k)))) for k in range(6)]


def plug(m, x, y, z, r, sw):
    """A flat six-sided face looking toward the front."""
    m.out(hexagon(x, y, z, r), [kit.sw_uv(sw, 0.0, 0.8)] * 6, Vector((x, y - 1.0, z)))


# --- the Forge, the Press ----------------------------------------------------------------------------------------------

def forge(head=True):
    """The Press, all of it that stands still: the deck, the seat with its flat lit plate, the two horns curving in to
    the head, the sleeves the ram's rods ride in, the stones' cradle and its vein. Without its `head`, for a later
    stage's lintel in its place (AR36, base_forge_stages.py)."""
    m = Mesh()
    deck(m)
    m.box((3.2, 2.6, 2.0), (0, 0, 1.5), "abyss", ink=True)                 # the seat, its top at 2.5
    m.box((3.4, 2.8, 0.2), (0, 0, 2.6), "bone", ink=True)
    m.box((2.4, 1.8, 0.06), (0, 0, PLATE - 0.03), "void")                  # the flat lit plate
    for sx in (-1, 1):
        m.box((0.2, 0.14, 1.3), (sx * 0.9, 1.33, 1.45), "void")            # the seat's veins, down its front
    for sx in (-1, 1):
        arch = [(sx * 3.2, 0, 0.5), (sx * 4.7, 0, 4.4), (sx * 4.1, 0, 8.8), (sx * 1.7, 0, 11.3)]
        widths = [0.8, 0.72, 0.58, 0.42]
        m.box((1.9, 2.2, 0.4), (sx * 3.2, 0, 0.7), "girder", ink=True)
        bm.horn(m, arch, widths, "abyss", deep=0.9)
        bm.vein(m, arch, widths, (0, 0, 6.0))
    low, top = HEAD
    if head:
        m.box((3.6, 2.4, top - low), (0, 0, (low + top) / 2), "abyss", ink=True)   # where they meet, inside their outer edge
        field(m, 0.0, GEAR[2], 3.2)                                         # the void's light behind its two gears
    for sx in (-1, 1):
        rod(m, (sx * RODS[0], 0, low + 0.05), (sx * RODS[0], 0, SLEEVE), 0.36, "girder")
    cradle(m, 3.0, 3.0, stones=3)
    m.box((0.18, 1.15, 0.04), (3.1, 1.67, 0.52), "void")                    # the cradle's vein, to the horn's foot
    return m


def forge_ram():
    """The ram, its origin the middle of its underside: a broad eight-sided block of void stone, 4 across and 1.5 high,
    a flat disc of the void's light let into its underside and a band of it round its crown, and its two rods standing
    up from bone collars, a bone cap on each."""
    m = Mesh()
    r, high = RAM
    put(m, turned([(r, high), (r, 0.0)], 8, "abyss"), at(0, 0, 0))
    put(m, turned([(r + 0.08, 0.3), (r + 0.08, 0.0)], 8, "void"), at(0, 0, high - 0.4))
    disc(m, (0, 0, 0), 1.6, 0.08, "void", axis=(0, 0, 1), sides=8, ink=False)
    x, length, thick = RODS
    for sx in (-1, 1):
        m.box((0.7, 0.7, 0.2), (sx * x, 0, high + 0.1), "bone", ink=True)
        rod(m, (sx * x, 0, high + 0.2), (sx * x, 0, high + length), thick, "steel")
        put(m, turned([(0.3, 0.35), (0.3, 0.0)], 8, "bone"), at(sx * x, 0, high + length - 0.35))
    return m


def forge_gear():
    """One of the head's two gears, its origin its middle, its axle toward the front."""
    m = Mesh()
    r, _, _, teeth = GEAR
    put(m, cog(r, teeth, 0.3), FACING)
    return m


def gear_turn(sx, angle):
    """Where a gear stands on the Forge, turned `angle` degrees about its axle: the left one as given, the right one
    the other way and half a tooth on, so the two mesh through the whole turn."""
    x, y, z, teeth = GEAR
    half = 0.0 if sx < 0 else 180.0 / teeth
    return at(sx * x, y, z) @ Matrix.Rotation(math.radians(sx * -angle + half), 4, "Y")


def press(pose="rest"):
    """The whole Press in a pose, for the review: the Forge with its ram and its two gears where the pose puts them."""
    m = forge()
    low = POSES[pose]
    put(m, forge_ram(), at(0, 0, low))
    for sx in (-1, 1):
        put(m, forge_gear(), gear_turn(sx, (low - POSES["rest"]) * TURN))
    return m


# --- the Stone Condenser, the Comb -------------------------------------------------------------------------------------

def cups():
    """The comb's cups in the order they fill: by rows from the bottom up, each row from its middle out, the right one
    first. Across and up, in the Condenser's frame; every cup on the comb's face."""
    r, spacing = CELL
    dx, dz = math.sqrt(3) * r * spacing, 1.5 * r * spacing
    out = []
    for row, n in enumerate(ROWS):
        z = PANEL[0] + (row - 3) * dz
        xs = [(i - (n - 1) / 2) * dx for i in range(n)]
        out += [(round(x, 3) + 0.0, round(z, 3)) for x in sorted(xs, key=lambda x: (abs(round(x, 3)), -x))]
    return out


def panel_radius():
    """The panel's corner radius: the cups' own six-sided outline, grown by a cup's radius and the margin."""
    r, spacing = CELL
    return (3 * 1.5 * r * spacing + r + PANEL[1]) * 2 / math.sqrt(3)


HORN = [0.6, 0.46, 0.38, 0.07]   # a Condenser horn's half widths, foot to tip


def horn(rp, mid):
    """A Condenser horn's bends, the right one's: its foot on the deck, its widest beside the panel's middle, its
    shoulder, its tip by the core."""
    return [(2.7, -0.4, 0.5), (rp + 0.8, -0.4, mid), (3.0, -0.4, 7.7), (1.65, -0.4, 9.8)]


def cup(m, x, z):
    """A cup on the comb's face at (x, z): a dark plug in a six-sided rim, its lip toward the front."""
    r = CELL[0]
    ri, ro, lip = 0.78 * r, 0.98 * r, 0.22
    uv = [kit.sw_uv("girder", 0.0, 0.6)] * 4
    plug(m, x, FACE + 0.02, z, ri + 0.03, "ink")
    inner, outer = hexagon(x, FACE, z, ri), hexagon(x, FACE, z, ro)
    front_in, front_out = hexagon(x, FACE + lip, z, ri), hexagon(x, FACE + lip, z, ro)
    axis = Vector((x, FACE + lip / 2, z))
    for k in range(6):
        j = (k + 1) % 6
        m.out([front_in[k], front_out[k], front_out[j], front_in[j]], uv, Vector((x, FACE - 1.0, z)))
        m.out([outer[k], outer[j], front_out[j], front_out[k]], uv, axis)
        wall = [inner[k], inner[j], front_in[j], front_in[k]]
        m.out(wall, uv, axis + (sum(wall, Vector()) / 4 - axis) * 3.0)


def condenser():
    """The Comb, all of it that stands still: the deck, the panel's foot, the six-sided panel and its 37 cups, dark
    until a cup's stone or jewel stands in it, the two horns hugging the panel's sides and closing over its top, the
    core's shard floating between their tips with a few motes round it, the cable in at its back and the cradle on its
    front corner."""
    m = Mesh()
    deck(m)
    rp, mid = panel_radius(), PANEL[0]
    m.box((4.0, 1.4, 0.6), (0, -0.4, 0.8), "girder", ink=True)             # the panel's foot, under its flat bottom
    put(m, turned([(rp, 1.0), (rp, 0.0)], 6, "abyss"), at(0, FACE - 1.0, mid) @ FACING)
    for x, z in cups():
        cup(m, x, z)
    for sx in (-1, 1):
        side = [(sx * x, y, z) for x, y, z in horn(rp, mid)]
        widths = HORN
        m.box((1.6, 1.8, 0.4), (sx * 2.7, -0.4, 0.7), "girder", ink=True)
        bm.horn(m, side, widths, "abyss", deep=0.9)
        bm.vein(m, side, widths, (0, -0.4, mid))
    bm.shard(m, CORE, 0.45, 1.6, "void")
    cx, cy, cz = CORE
    motes(m, [(cx + d * math.cos(a), cy + 0.3, cz + d * math.sin(a))
              for a, d in ((0.35, 2.1), (1.25, 2.25), (1.95, 2.0), (2.85, 2.2), (-0.5, 1.9), (3.7, 1.95))], 0.18)
    m.box((1.1, 0.9, 0.8), (1.2, -3.6, 0.9), "girder", ink=True)           # where the electricity comes in
    cable(m, [(1.2, -4.9, 0.25), (1.2, -4.3, 0.25), (1.2, -3.6, 0.9)], r=0.24)
    cradle(m, -3.0, 3.2)
    return m


def condenser_core():
    """The core, its origin its middle, its face toward the front: a ring of void stone with a line of light round its
    face and four clamps reaching in from it toward the shard, which stands in the Condenser itself. It turns in its
    own plane while the Condenser works."""
    m = Mesh()
    t = Mesh()
    bm.hoop(t, (0, 0, 0), 0.95, 1.3, 0.4, 12, "abyss", lying=True)
    put(m, t, FACING)
    lit = Mesh(None)
    bm.hoop(lit, (0, 0, 0), 1.06, 1.17, 0.44, 24, "void", ink=False, lying=True)
    put(m, lit, FACING)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        c, s = math.cos(a), math.sin(a)
        bm.horn(m, [(c * 1.22, 0, s * 1.22), (c * 0.62, 0, s * 0.62)], [0.26, 0.05], "abyss")
    return m


def condenser_stone():
    """A cup with a stone in it, its origin the cup's middle on the comb's face: a lit plug of the void's violet and
    the stone standing in it."""
    m = Mesh(None)
    plug(m, 0, 0.04, 0, 0.78 * CELL[0] + 0.03, "void")
    stone(m, (0, 0.32, 0), 0.2)
    return m


def condenser_jewel(sw="lamp"):
    """A cup with a jewel in it, its origin the cup's middle on the comb's face: a lit plug and a cut jewel, its flat
    table toward the front, every face one pale swatch so the builder tints the whole cup in the jewel type's colour.
    One shape for every tier: the jewel's own icon grows with its tier."""
    m = Mesh(None)
    plug(m, 0, 0.04, 0, 0.78 * CELL[0] + 0.03, sw)
    gem = Mesh(None)
    gem.lathe([(0.2, 0.16), (0.33, 0.0), (0.03, -0.2)], (0, 0, 0), 8, sw, spin=math.pi / 8)
    put(m, gem, at(0, 0.3, 0) @ FACING)
    return m


def comb(fill=0.5, jewels=(), jewel_sw="lamp"):
    """The whole Comb at a fill, for the review: its core, and a stone in each of the first `fill` of its cups, or a
    jewel in the cups numbered in `jewels` (0 the first to fill)."""
    m = condenser()
    put(m, condenser_core(), at(*CORE))
    places = cups()
    for k, (x, z) in enumerate(places[:round(len(places) * fill)]):
        put(m, condenser_jewel(jewel_sw) if k in jewels else condenser_stone(), at(x, FACE, z))
    return m, len(places)


# --- the pieces --------------------------------------------------------------------------------------------------------

def _forge():
    low, top = HEAD
    return Piece("Forge", forge(), solid=f"the deck, {DECK:g} square and 0.5 high; the seat, 3.4 by 2.8 and {PLATE:g} high; "
                                         f"the horns' two feet",
                 note=f"on a sleeping place, its front toward the Strip, {top:g} high at its head. The item lies on the "
                      f"seat's lit plate, at its middle, {PLATE:g} up. The ram is ForgeRam, the gears ForgeGear: "
                      f"plan.json, machines.forge")


def _ram():
    return Piece("ForgeRam", forge_ram(),
                 note=f"its origin is its underside's middle, over the Forge's middle: up {POSES['rest']:g} at rest, "
                      f"{POSES['tell']:g} at most (the sleeves' foot), {POSES['contact']:g} on the plate. Its band and "
                      f"its disc are its light: dim at rest, bright for the tell. Look only")


def _gear():
    return Piece("ForgeGear", forge_gear(),
                 note="its origin is its middle, its axle toward the front: void stone with a vein of the void's light "
                      "and a bone hub. Two stand on the Forge's head at Stage I, four and six on the lintel at II and "
                      "III, each turning the other way from the one it meshes as the ram moves (plan.json, "
                      "machines.forge and machines.forgeStages). Look only")


def _condenser():
    return Piece("Condenser", condenser(), solid=f"the deck, {DECK:g} square and 0.5 high, and the panel as a box "
                                                  f"{2 * panel_radius():.1f} by 1 by {math.sqrt(3) * panel_radius():.1f}",
                 note=f"on a sleeping place, its comb toward the Strip, about 11 high at its core. The comb's {len(cups())} "
                      f"cups are its tray, dark when empty; a cup's stone or jewel is CondenserStone or CondenserJewel "
                      f"stood in it, and the core is CondenserCore: plan.json, machines.condenser")


def _core():
    return Piece("CondenserCore", condenser_core(),
                 note=f"its origin is its middle, at across {CORE[0]:g}, {-CORE[1]:g} toward the back and {CORE[2]:g} up "
                      f"on the Condenser, round the shard: it turns in its own plane while the Condenser works, still "
                      f"when the tray is full or the power is out. Look only")


def _stone():
    return Piece("CondenserStone", condenser_stone(),
                 note="a stone in a cup: stood at the cup's place on the comb (plan.json, machines.condenser), the "
                      "Condenser's turn. Lit, the void's violet. Look only")


def _jewel():
    return Piece("CondenserJewel", condenser_jewel(),
                 note="a jewel in a cup: stood at the cup's place on the comb, the Condenser's turn. One pale swatch on "
                      "every face: the jewel type's colour is the builder's (a tint, or the mesh in Neon without the "
                      "kit's pictures), so the cup reads from a stone's at 14 studs. Look only")


PIECES = {"Forge": _forge, "ForgeRam": _ram, "ForgeGear": _gear, "Condenser": _condenser, "CondenserCore": _core,
          "CondenserStone": _stone, "CondenserJewel": _jewel}


def tables():
    """The moving parts' places, for plan.json's machines: each in the machine's own frame, across, along (minus in:
    toward the front is plus) and up from its place, turned with it."""
    return dict(
        forge=dict(
            note="AR28: the Forge, the Press, Stage I. Every place here is in the Forge's own frame, turned with it: "
                 "`across` to its right, `along` toward its front (the Strip), `up` from its floor. "
                 "ForgeRam stands over the Forge's middle, raised by its underside "
                 "between `ram`'s heights: rest, the tell's top (the sleeves' foot: never higher) and the contact (on "
                 "the plate; on an item the builder lays there, that much higher). Its light is the tell: dim at rest, "
                 "bright as it lifts. The two ForgeGear stand at `gears`, the right one turned half a tooth about its "
                 "axle so they mesh, and turn opposite ways with the ram: the left anticlockwise seen from the front as "
                 "it lifts. `degreesPerStud` is the review's rate.",
            ram=dict(across=0.0, along=0.0, **POSES),
            gears=[dict(across=sx * GEAR[0], along=GEAR[1], up=GEAR[2], turnedHalfTooth=sx > 0) for sx in (-1, 1)],
            halfTooth=180.0 / GEAR[3], degreesPerStud=TURN, plate=PLATE),
        condenser=dict(
            note="AR28: the Stone Condenser, the Comb, Stage I. Every place here is in the Condenser's own frame, as "
                 "the Forge's. The comb is the tray: the cups in `cups` fill in their "
                 "order, a stone or a jewel to a cup, so the comb's lit height is the fill. A cup holding a stone stands "
                 "CondenserStone at its place, one holding a jewel CondenserJewel, tinted in the jewel type's colour; "
                 "an empty cup stands nothing. CondenserCore stands at `core` and turns about its own front axis while "
                 "the Condenser works, still when the tray is full or the power is out.",
            core=dict(across=CORE[0], along=CORE[1], up=CORE[2]),
            cups=[dict(across=x, along=FACE, up=z) for x, z in cups()]))


# --- the review: Stage I beside the Breaker, from the game's camera ----------------------------------------------------

def review(out, fast):
    import forge_condenser_directions as fcd
    import lantern_row_look as look
    import rook_sheet as rs
    import ui_sheet as ui

    ui.K = 1
    bench = fcd.Bench(out, fast)
    later, tris = [], {}

    def stand(key, mesh, where):
        tris.setdefault(key.split("_")[0], mesh.whole().tris())
        return bench.stand(key, mesh, where)

    # the Forge, the Press
    obj = stand("Press_rest", press("rest"), fcd.BESIDE)
    box = bench.frame([obj], bench.near)
    both = bench.frame([obj] + fcd.breaker_parts(bench.scene), bench.near)
    rest = bench.shot("press_beside", bench.near)
    black = bench.silhouette("press_silhouette", ("Press_", "Breaker"), bench.near)
    close = {"rest": bench.shot("press_close_rest", bench.close, who=None)}
    bench.drop(obj)
    for pose in ("tell", "contact"):
        obj = stand(f"Press_{pose}", press(pose), fcd.BESIDE)
        close[pose] = bench.shot(f"press_close_{pose}", bench.close, who=None)
        if pose == "tell":
            far_tell = bench.shot("press_beside_tell", bench.near)
        bench.drop(obj)
    pieces = {name: PIECES[name]().mesh.whole().tris() for name in PIECES}
    cells = [("Stage I at rest beside the Breaker, from the game's camera 30 studs before the two", rest),
             ("At the tell, from the same view: the ram drawn up to the sleeves, its rods' caps out of the head", far_tell),
             ("At rest, from the game's camera behind a player 14 studs before it (the player hidden)", close["rest"]),
             ("The tell: the ram drawn up, its band and its disc lit, the gears turned (the light is the builder's to turn up)", close["tell"]),
             ("The contact: the ram down on the plate (the effect is the builder's, flat round the plate)", close["contact"]),
             ("Its silhouette in black, with the Breaker's, from the 30 studs' view, drawn larger", fcd.fit(fcd.cut(black, both)))]
    notes = ("The Forge's Stage I, the Press: research's pick (AR28, 2026-11-17, 12:20). Two horns of void stone curve in "
             "from the deck's sides to a head with two meshing gears on its face. Between them the ram, a broad eight-"
             "sided block with a disc of the void's light under it and a band round its crown, rides on two rods that "
             "slide up into sleeves under the head. The pieces: Forge (still), ForgeRam (raised by the builder between "
             f"{POSES['contact']:g} and {POSES['tell']:g}), ForgeGear twice (turning opposite ways with the ram).",
             "Triangles with the drawn edge: " + ", ".join(f"{n} {pieces[n]:,}" for n in ("Forge", "ForgeRam", "ForgeGear"))
             + ". Rendered in Blender under the place's dusk, in the yard as it stands at 200; nothing is seen in Studio.")
    later.append((fcd.sheet, (out, "forge_stage1.png", "Grow your Anime, the Forge: Stage I, the Press", notes, cells)))
    strip_rows = [("the Forge, at rest", fcd.cut(rest, box), fcd.cut(black, box))]

    # the Stone Condenser, the Comb
    mesh, count = comb(0.5, jewels=(3, 9), jewel_sw="cyan")
    obj = stand("Comb_half", mesh, fcd.BESIDE)
    box = bench.frame([obj], bench.near)
    both = bench.frame([obj] + fcd.breaker_parts(bench.scene), bench.near)
    half = bench.shot("comb_beside", bench.near)
    near = bench.shot("comb_close", bench.close, who=None)
    black = bench.silhouette("comb_silhouette", ("Comb_", "Breaker"), bench.near)
    bench.drop(obj)
    gates, gate_box = {}, None
    for fill, word in ((1.0, "full"), (0.5, "half"), (0.0, "empty")):
        obj = stand(f"Comb_{word}", comb(fill, jewels=(3, 9), jewel_sw="cyan")[0], fcd.GATE_AT)
        gate_box = gate_box or bench.frame([obj], bench.gate, pad=10)
        gates[word] = bench.shot(f"comb_gate_{word}", bench.gate, who="Avatar", hide=fcd.TO_GATE)
        bench.drop(obj)
    crops = [fcd.cut(gates[w], gate_box) for w in ("full", "half", "empty")]
    ch, cw = crops[0].shape[:2]
    k = max(1, min(290 // max(cw, 1), 480 // max(ch, 1)))
    states = rs.canvas(look.SIZE[0], look.SIZE[1], (0.08, 0.08, 0.11))
    for i, c in enumerate(crops):
        rs.paste(states, fcd.bigger(c, k), 15 + i * (cw * k + 20), 30)
    cells = [(f"Stage I part-full ({round(count / 2)} of {count} cups, two of them jewels) beside the Breaker, from the game's camera 30 studs off", half),
             ("Part-full, from the game's camera behind a player 14 studs before it (the player hidden)", near),
             ("From the gate, 86 studs off as on the base at 128, full: the game's whole view", gates["full"]),
             (f"From the gate: full, part-full, empty, cut from that view and drawn {k} times its size", states),
             ("Its silhouette in black, with the Breaker's, from the 30 studs' view, drawn larger", fcd.fit(fcd.cut(black, both)))]
    notes = ("The Stone Condenser's Stage I, the Comb: research's pick (AR28, 2026-11-17, 12:20). A six-sided panel of void "
             "stone faces the gate, set in two horns that hug its sides and close over its top, the core between their "
             f"tips. Its face is a comb of {count} six-sided cups in seven rows, and it is the tray: each stone or jewel "
             "goes into the lowest empty cup, so its lit height is the fill. A jewel's cup is one pale swatch the builder "
             "tints in the jewel type's colour: cyan here, for the preview only. The pieces: Condenser (still), "
             "CondenserCore (turning while it works), CondenserStone and CondenserJewel (one a filled cup).",
             "Triangles with the drawn edge: " + ", ".join(f"{n} {pieces[n]:,}" for n in ("Condenser", "CondenserCore", "CondenserStone", "CondenserJewel"))
             + ". The gate's view hides today's battery, which stands on that line in the 200 yard. Rendered in Blender "
               "under the place's dusk; nothing is seen in Studio.")
    later.append((fcd.sheet, (out, "condenser_stage1.png", "Grow your Anime, the Stone Condenser: Stage I, the Comb", notes, cells)))
    strip_rows.append(("the Condenser, part-full", fcd.cut(half, box), fcd.cut(black, box)))
    later.append((fcd.strip, (out, "forge_condenser_stage1_64.png", "Stage I at 64 px and 128 px tall, from the game's "
                                                                   "camera 30 studs off; the silhouette at 64 px", strip_rows)))
    for make, made in later:
        make(*made)
    print("pieces:", pieces)
    print("cups:", count, "panel", round(2 * panel_radius(), 2), "by", round(math.sqrt(3) * panel_radius(), 2))


def main():
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    review(out, "fast" in args)


if __name__ == "__main__":
    main()
