"""AR50's blockout (docs/asset-requests.md, AR50): the base's levels 2 and 3, the whole yard's look, read from the gate
and from the Strip. Three directions for what grows from level 1 to 2 to 3, each a different lever:

    A, the edge rises     the gate gains an arch a level, its towers climbing, and every wall post a taller head; the
                          corners become towers. The yard's outline is the level.
    B, the current climbs the edge keeps its shape and the light grows: a blade of light on every post, the gate's
                          towers lit their whole height, a second ring round the well and the way in lit; at level 3
                          a standing current at each corner and over the gate.
    C, the halo           the void lifts stone: a broken ring of the yard's own stone floats round the generator at its
                          axle's height, open toward the gate, and a shard floats over each gate tower; at level 3
                          a second, wider ring over the first, tilted, and a shard over each corner.

In every direction the level's new bay stands awake with its line lit (bays 2, 3, 4 at levels 1, 2, 3: docs/design.md,
"The base"; base_kit's BAYS_AT still holds the older 2, 4, 6 and is set here for the run only). The machines keep
their level 1 models: their stages are TR51's.

Block-in pieces, in the kit's own swatches on the plan as it stands (base_plan), in the game's day (base_light, AR40's
C). Nothing is exported and no kit file is written over. One level of one direction a run, under the guard (each is a
whole world in memory):

    guard.ps1 tools/blender/base_levels_block.py <abs out> see <A|B|C|D> <1|2|3> [fast] [in] [gate] [strip] [far]
    guard.ps1 tools/blender/base_levels_block.py <abs out> sheet

`see` writes <out>/<key><level>_in.png, _gate.png, _strip.png and _far.png (or the stands named) at the smallest phone's
pixels (852 by 480, 1.5 a point), from the game's camera at its start zoom behind a player at four stands (THRESHOLD,
ARRIVING, WALKER and FAR below). Level 1 is the same in every direction, so it's rendered once, as A1. `sheet` writes
base_levels_<stand>.png for each, and base_levels_64.png (every frame at 64 px high).

D came out of the first three's read (AR50, "The blockout"): no one lever is seen from every stand, so D takes one
sign for each stand and adds one of each a level: B's floor for the owner at the gate, A's fins on the gate's
shoulders for a visitor, and C's ring for the Strip. Research picked D with two fixes (AR50, "Research's verdict and
pick: D"), drawn here: the rings slim, in teal, tilted to show their face, and the fins in the gate towers' make.
`see ... spin=<degrees>` writes a frame with the rings turned (<key><level>_<stand>_t<degrees>.png); `second` lays D's
second look: base_levels_d.png, base_levels_d_64.png and base_levels_turn.png.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_light as day  # noqa: E402

plan, base, look, kit, bl = day.plan, day.base, day.look, day.kit, day.bl
rs = plan.rs
Mesh, Piece, lamp = base.Mesh, kit.Piece, base.machines.lamp

SIZE = (852, 480)
BAYS_AT = {1: 2, 2: 3, 3: 4}            # docs/design.md, "The base": the director's D5 of 2026-11-18
NAMES = {"A": "A. The edge rises", "B": "B. The current climbs", "C": "C. The halo", "D": "D. One sign a stand"}
GATE, HALF, YARD, ROW = base.GATE, base.HALF, base.YARD, base.ROW
CORNERS = [(-HALF, 0.0), (HALF, 0.0), (-HALF, YARD), (HALF, YARD)]
# The game's camera looks 20 degrees down, so its frame ends 15 degrees over the level: a thing H studs tall is whole
# in it only from (H - 8.8) / 0.268 studs off. A gate 42 tall needs 124. So height is read from far down the Strip,
# and from near only what stands under about 20 studs is seen. Three stands:
THRESHOLD = (0.0, 1.0)                  # the owner at the gate's line, looking in at the yard
ARRIVING = (0.0, base.STRIP / 2)        # a visitor in the Strip's middle, facing the gate, 24 studs off
WALKER = (-90.0, base.STRIP / 2)        # a passer-by coming down the Strip, looking along it: this base ahead on the
                                        # right, a level 1 base across the road on the left
FAR = (-150.0, base.STRIP / 2)          # and the same from further off
VIEWS = (("in", "at the gate, looking in"), ("gate", "from the Strip, facing the gate"),
         ("strip", "from 90 studs down the Strip: this base on the right, a level 1 base on the left"),
         ("far", "from 150 studs down the Strip: this base on the right, a level 1 base on the left"))


def light_line(m, size, at, axis, sign=1):
    """A line of light on a body's face, in its dark well (AR40), by the kit's own lamp: `axis` is the face's normal
    and `sign` the way it looks. With `sign` 0 the light runs through the body and shows on both faces."""
    for way in ((-1, 1) if sign == 0 else (sign,)):
        lamp(m, size, at, "power", axis, way, pad=0.18)


def crystal(m, at, tall, wide, sides=5):
    """A shard: teal glass, its tip the void's light (AR40: violet only in a small core or tip)."""
    x, y, z = at
    m.lathe([(0.0, z + tall * 0.82), (wide, z + tall * 0.55), (0.0, z)], (x, y, 0), sides, "far")
    m.lathe([(0.0, z + tall), (wide * 0.42, z + tall * 0.8), (0.0, z + tall * 0.74)], (x, y, 0), sides, "void")


# --- A: the edge rises --------------------------------------------------------------------------------------------------

def a_gate(level):
    def make():
        m = Mesh()
        for side in (-1, 1):
            x = side * GATE
            m.box((2.2, 2.2, 8.2), (x, 0, 22.0), "girder", ink=True)            # the tower on up, over its old head
            m.box((3.0, 3.0, 0.5), (x, 0, 26.35), "bone", ink=True)
            if level == 2:
                m.box((0.6, 0.6, 0.6), (x, 0, 26.95), "power")
                m.box((0.8, 0.8, 0.1), (x, 0, 26.62), "well")
        span = 2 * GATE - 2.2
        m.box((span, 1.3, 1.7), (0, 0, 23.6), "bone", ink=True)                 # the second arch
        light_line(m, (span - 1.0, 1.42, 0.26), (0, 0, 23.6), 1, 0)
        m.box((2.6, 1.6, 0.9), (0, 0, 22.5), "girder", ink=True)                # its clamp, and the shard it holds
        crystal(m, (0, 0, 18.6), 3.6, 0.9, 4)
        for side in (-1, 1):                                                    # and at eye level: a fin on each shoulder,
            for reach, tall in (((4.4, 11.0),) if level == 2 else ((4.4, 14.0), (8.0, 10.0))):   # stepping down outward
                x = side * (GATE + reach)
                m.box((1.5, 2.2, tall), (x, 0, tall / 2), "girder", ink=True)
                m.box((1.9, 2.6, 0.45), (x, 0, tall + 0.22), "bone", ink=True)
                light_line(m, (0.3, 2.32, tall - 6.4), (x, 0, 5.6 + (tall - 6.4) / 2), 1, 0)
        if level == 3:
            for side in (-1, 1):
                x = side * GATE
                m.box((1.8, 1.8, 8.0), (x, 0, 30.6), "girder", ink=True)
                m.box((2.6, 2.6, 0.5), (x, 0, 34.85), "bone", ink=True)
                crystal(m, (x, 0, 35.3), 5.0, 1.1)
                # the crest: a blade from each tower's head up toward the middle
                rise, run = 6.5, GATE - 7.0
                tilt = -side * math.atan2(rise, run)
                m.box((math.hypot(rise, run), 1.1, 1.3), (side * (7.0 + run / 2), 0, 31.2 + rise / 2), "bone",
                      rot=(0.0, tilt, 0.0), ink=True)
            m.box((2 * GATE - 1.8, 1.1, 1.3), (0, 0, 30.6), "bone", ink=True)   # the third arch
            light_line(m, (2 * GATE - 3.0, 1.22, 0.24), (0, 0, 30.6), 1, 0)
            for k in range(16):                                                 # and the ring it carries, the shard in it
                a = math.tau * k / 16
                m.box((2.1, 1.0, 0.9), (5.2 * math.cos(a), 0, 38.4 + 5.2 * math.sin(a)), "bone",
                      rot=(0.0, math.pi / 2 - a, 0.0), ink=True)
            crystal(m, (0, 0, 34.6), 7.4, 1.9, 6)
        return Piece(f"A{level}Gate", m)
    return make


def a_post(level, corner=False):
    def make():
        m = Mesh()
        if corner:
            tall = {2: 7.0, 3: 12.0}[level]
            m.box((2.6, 2.6, 7.4), (0, 0, 3.7), "concrete", ink=True)           # the corner thickens into a tower
            m.box((2.0, 2.0, tall), (0, 0, 7.4 + tall / 2), "girder", ink=True)
            m.box((2.8, 2.8, 0.5), (0, 0, 7.65 + tall), "bone", ink=True)
            light_line(m, (0.2, 2.12, tall - 1.6), (0, 0, 7.4 + tall / 2), 1, 0)   # a line of light up each face
            light_line(m, (2.12, 0.2, tall - 1.6), (0, 0, 7.4 + tall / 2), 0, 0)
            if level == 3:
                crystal(m, (0, 0, 8.1 + tall), 4.2, 0.95)
            else:
                m.box((0.7, 0.7, 0.7), (0, 0, 8.25 + tall), "power")
        else:
            tall = {2: 3.0, 3: 5.6}[level]
            m.box((1.0, 1.0, tall), (0, 0, 7.0 + tall / 2), "girder", ink=True)  # the post's head, taller
            m.box((1.5, 1.5, 0.4), (0, 0, 7.2 + tall), "bone", ink=True)
            m.box((0.6, 0.6, 0.5), (0, 0, 7.65 + tall), "power")
            m.box((0.8, 0.8, 0.1), (0, 0, 7.45 + tall), "well")
            if level == 3:
                light_line(m, (1.12, 0.2, tall - 1.2), (0, 0, 7.0 + tall / 2), 0, 0)
        return Piece(f"A{level}{'Corner' if corner else 'Post'}", m)
    return make


# --- B: the current climbs ----------------------------------------------------------------------------------------------

def b_blade(level):
    def make():
        m = Mesh()
        tall = {2: 5.5, 3: 8.5}[level]
        m.box((0.46, 0.46, tall), (0, 0, 7.5 + tall / 2), "well")
        m.box((0.2, 0.6, tall - 0.3), (0, 0, 7.5 + tall / 2), "power")
        m.box((0.6, 0.2, tall - 0.3), (0, 0, 7.5 + tall / 2), "power")
        return Piece(f"B{level}Blade", m)
    return make


def b_gate(level):
    def make():
        m = Mesh()
        for side in (-1, 1):
            x = side * GATE
            light_line(m, (0.16, 1.0, 12.6), (x + side * 1.34, 0, 10.6), 0, side)   # the towers lit on every face
            light_line(m, (1.0, 2.84, 12.6), (x, 0, 10.6), 1, 0)
        for y in (-1.14, 1.14):                                                  # and the plate framed in light
            for z in (13.6, 18.4):
                m.box((11.6, 0.12, 0.22), (0, y, z), "power")
            for x in (-5.7, 5.7):
                m.box((0.22, 0.12, 4.8), (x, y, 16.0), "power")
        return Piece(f"B{level}Gate", m)
    return make


def b_floor(level):
    def make():
        m = Mesh(None)
        r = 23.0                                                                 # a second ring round the well
        m.lathe([(r - 0.3, 0.2), (r + 0.3, 0.2)], (0, -ROW, 0), 64, "power", caps=False)
        m.lathe([(r - 0.6, 0.12), (r + 0.6, 0.12)], (0, -ROW, 0), 64, "well", caps=False)
        reach = ROW - math.sqrt(r * r - 100.0) - 1.0                             # the way in, lit down both edges
        for x in (-base.AVENUE / 2, base.AVENUE / 2):
            m.box((0.5, reach - 2.0, 0.08), (x, -(reach + 2.0) / 2, 0.2), "power")
            m.box((1.0, reach - 2.0, 0.08), (x, -(reach + 2.0) / 2, 0.12), "well")
        if level == 3:                                                           # and the whole yard's foot
            for x in (-HALF + 1.6, HALF - 1.6):
                m.box((0.5, YARD - 4.0, 0.08), (x, -YARD / 2, 0.2), "power")
                m.box((1.0, YARD - 4.0, 0.08), (x, -YARD / 2, 0.12), "well")
        return Piece(f"B{level}Floor", m)
    return make


def b_beam(tall):
    def make():
        m = Mesh(None)
        steps = 8
        for k in range(steps):                                                   # a standing current, thinning as it climbs
            wide = 0.8 * (1 - k / steps) + 0.1
            m.box((wide, wide, tall / steps), (0, 0, tall / steps * (k + 0.5)), "power")
        return Piece(f"BBeam{tall:g}", m)
    return make


# --- C: the halo --------------------------------------------------------------------------------------------------------

def c_halo(radius, up, tilt, blocks, gap, open_=0.0, roll=0.0):
    """A broken ring of the yard's stone afloat about the generator's upright, its light on its inner face and under
    it. `open_`: degrees left open toward the gate, so the wheel's face stays clear from the way in. `tilt` leans it
    about the line across the plot (below zero, its gate side dips), `roll` about the line to the gate."""
    def make():
        from mathutils import Matrix, Vector
        m = Mesh()
        lean = Matrix.Rotation(math.radians(roll), 3, "Y") @ Matrix.Rotation(math.radians(tilt), 3, "X")
        long = math.tau * radius / blocks * 0.96
        for k in range(blocks):
            a = math.tau * k / blocks
            away = abs((math.degrees(a) - 90.0 + 180.0) % 360.0 - 180.0)         # from the gate's side, +Y
            if k % gap == gap - 1 or away < open_ / 2:                           # the ring is broken: stone, then sky
                continue
            turn = lean @ Matrix.Rotation(a + math.pi / 2, 3, "Z")
            at = lean @ Vector((radius * math.cos(a), radius * math.sin(a), 0.0)) + Vector((0, 0, up))
            ends = k % gap in (0, gap - 2)
            m.box((long, 2.4, 1.7), tuple(at), "girder" if ends else "abyss", rot=turn, ink=True)
            inner = lean @ Vector(((radius - 1.25) * math.cos(a), (radius - 1.25) * math.sin(a), 0.0)) + Vector((0, 0, up))
            m.box((long * 0.9, 0.16, 0.36), tuple(inner), "power", rot=turn)     # the light on its inner face
            under = at - lean @ Vector((0, 0, 0.9))
            m.box((long * 0.9, 0.5, 0.14), tuple(under), "power", rot=turn)      # and under it, seen from the yard
        return Piece(f"Halo{radius:g}", m)
    return make


def c_shard(tall, ring=False):
    def make():
        m = Mesh()
        crystal(m, (0, 0, 0.9), tall, tall * 0.22)
        m.box((1.3, 1.3, 0.5), (0, 0, 0.25), "bone", ink=True)                   # a collar of the yard's stone, afloat under it
        if ring:
            for k in range(10):
                a = math.tau * k / 10
                m.box((1.25, 0.5, 0.5), (2.0 * math.cos(a), 2.0 * math.sin(a), 0.9 + tall * 0.45), "bone",
                      rot=(0.0, 0.0, a + math.pi / 2), ink=True)
        return Piece(f"CShard{tall:g}{'Ring' if ring else ''}", m)
    return make


# --- D: one sign a stand, one more a level ---------------------------------------------------------------------------------

SPIN = 0.0      # how far D's rings have turned, in degrees: the turning strip's frames


def d_fins(level):
    """A fin on each of the gate's shoulders, then two: the gate towers' own make (research's fix 2), a teal shaft on
    a concrete foot, a line of light in its dark bed on its Strip and yard faces, a bone collar and cap, a spire."""
    def make():
        m = Mesh()
        for side in (-1, 1):
            for reach, tall in (((4.6, 11.0),) if level == 2 else ((4.6, 14.0), (8.4, 10.0))):
                x = side * (GATE + reach)
                waist = round(tall * 0.62, 2)
                m.box((2.8, 2.8, 1.2), (x, 0, 0.6), "concrete", ink=True)
                m.box((1.9, 1.9, waist - 1.2), (x, 0, (waist + 1.2) / 2), "girder", ink=True)
                light_line(m, (0.6, 2.02, waist - 3.4), (x, 0, (waist + 1.2) / 2 + 0.3), 1, 0)
                m.box((2.3, 2.3, 0.4), (x, 0, waist + 0.2), "bone", ink=True)
                m.box((1.3, 1.3, tall - waist - 2.4), (x, 0, (tall + waist - 1.6) / 2), "girder", ink=True)
                m.box((1.7, 1.7, 0.35), (x, 0, tall - 1.82), "bone", ink=True)
                m.lathe([(0.0, tall), (0.62, tall - 1.65)], (x, 0, 0), 4, "girder", spin=math.pi / 4)
        return Piece(f"D{level}Fins", m)
    return make


def d_ring(radius, up, tilt, roll, section, way, arcs=3, gap=11.0, blocks=72):
    """A ring afloat about the generator, tilted so its face shows from the gate's line and from the Strip (research's
    fix 1): slim, in the gate's teal, a line of the void's teal light on its inner and outer faces and under it, in
    `arcs` lengths with a bead of light afloat in each gap. `tilt` raises its gate side, `roll` leans it across the
    plot; it turns about its own upright, `way` to a degree of SPIN."""
    def make():
        from mathutils import Matrix, Vector
        m = Mesh()
        lean = Matrix.Rotation(math.radians(roll), 3, "Y") @ Matrix.Rotation(math.radians(tilt), 3, "X")
        lift = Vector((0, 0, up))
        wide, tall = section
        long = math.tau * radius / blocks * 1.04
        turned = math.radians(way * SPIN)
        for k in range(blocks):
            a = math.tau * k / blocks
            if (math.degrees(a) + gap / 2) % (360.0 / arcs) < gap:               # the gap: sky, and a bead in it
                continue
            a += turned
            turn = lean @ Matrix.Rotation(a + math.pi / 2, 3, "Z")
            out = Vector((math.cos(a), math.sin(a), 0.0))
            m.box((long, wide, tall), tuple(lean @ (out * radius) + lift), "girder", rot=turn, ink=True)
            for r in (radius - wide / 2 - 0.02, radius + wide / 2 + 0.02):       # the light on its inner and outer faces
                m.box((long, 0.1, tall * 0.6), tuple(lean @ (out * r) + lift), "cyan", rot=turn)
            m.box((long, wide * 0.6, 0.1), tuple(lean @ (out * radius - Vector((0, 0, tall / 2 + 0.02))) + lift), "cyan",
                  rot=turn)                                                      # and under it, seen from the yard
        for k in range(arcs):
            a = math.tau * k / arcs + turned
            x, y, z = lean @ Vector((radius * math.cos(a), radius * math.sin(a), 0.0)) + lift
            m.lathe([(0.0, z + 1.5), (0.75, z), (0.0, z - 1.5)], (x, y, 0), 4, "cyan")
        return Piece(f"Ring{radius:g}", m)
    return make


def d_rays():
    m = Mesh(None)
    for k in range(16):                                                         # level 3: the two rings joined by rays
        a = math.tau * (k + 0.5) / 16
        if abs(math.cos(a)) * 20.5 < base.AVENUE / 2 + 1.0 and math.sin(a) > 0:  # none on the way in
            continue
        at = (20.5 * math.cos(a), -ROW + 20.5 * math.sin(a))
        m.box((3.6, 0.5, 0.08), (*at, 0.2), "power", rot=(0.0, 0.0, a))
        m.box((3.6, 1.0, 0.08), (*at, 0.12), "well", rot=(0.0, 0.0, a))
    return Piece("DRays", m)


PIECES = {
    "D2Fins": d_fins(2), "D3Fins": d_fins(3), "DRays": d_rays,
    "A2Gate": a_gate(2), "A3Gate": a_gate(3), "A2Post": a_post(2), "A3Post": a_post(3),
    "A2Corner": a_post(2, True), "A3Corner": a_post(3, True),
    "B2Blade": b_blade(2), "B3Blade": b_blade(3), "B2Gate": b_gate(2), "B3Gate": b_gate(3),
    "B2Floor": b_floor(2), "B3Floor": b_floor(3), "BBeam34": b_beam(34.0), "BBeam40": b_beam(40.0),
    "CHalo16": c_halo(16.0, 13.5, 0.0, 24, 4, 76.0), "CHalo24": c_halo(24.0, 29.0, 11.0, 28, 4),
    "CShard4": c_shard(4.0), "CShard5": c_shard(5.0), "CShard5Ring": c_shard(5.0, True),
}
# D's rings, by projection through the game's camera at each stand: the first, 14 in radius, is whole in the frame
# from the gate's line with its near arc 2 studs over the wheel's head; the second, 22 in radius, stands over the
# skyline from the Strip (the wheel's head is 22 up, a pylon's 25) and passes overhead from the gate's line
PIECES.update({"DRing14": d_ring(14.0, 15.5, 30.0, 0.0, (1.3, 0.9), 1.0),
               "DRing22": d_ring(22.0, 25.0, 26.0, -12.0, (2.0, 1.3), -0.6)})


def bay_line(level):
    """The newly opened bays' lines, lit: the bus on from the open bay to the next (base_kit.dead_runs)."""
    def make():
        m = Mesh(None)
        for index in range(2, BAYS_AT[level]):
            side = math.copysign(1.0, base.BAYS[index][0])
            x0, x1 = base.OUTER + 6.2, base.FAR - base.SLEEPS
            m.box((x1 - x0, 0.5, 0.08), (side * (x0 + x1) / 2, -ROW, 0.2), "power")
        return Piece(f"BayLine{level}", m)
    return make


PIECES.update({"BayLine2": bay_line(2), "BayLine3": bay_line(3)})


def posts(level):
    """Where the wall's posts stand: across, in. The corners apart."""
    at = sorted({(x, -along) for name, x, along, _ in plan.plan(level)[0] if name.startswith("Wall")})
    return [p for p in at if p not in CORNERS], [p for p in at if p in CORNERS]


def grown(key, level):
    """What a direction stands at a level, over level 1's plan: piece, across, in, up."""
    if level == 1:
        return []
    wall, corners = posts(level)
    made = [(f"BayLine{level}", 0.0, 0.0, 0.0)]
    if key == "A":
        made.append((f"A{level}Gate", 0.0, 0.0, 0.0))
        made += [(f"A{level}Post", x, i, 0.0) for x, i in wall]
        made += [(f"A{level}Corner", x, i, 0.0) for x, i in corners]
    elif key == "B":
        made += [(f"B{level}Gate", 0.0, 0.0, 0.0), (f"B{level}Floor", 0.0, 0.0, 0.0)]
        made += [(f"B{level}Blade", x, i, 0.0) for x, i in wall + corners]
        if level == 3:
            made += [("BBeam34", x, i, 7.6) for x, i in corners]
            made += [("BBeam40", side * GATE, 0.0, 20.7) for side in (-1, 1)]
    elif key == "C":
        made.append(("CHalo16", 0.0, ROW, 0.0))
        made += [("CShard5Ring" if level == 3 else "CShard4", side * GATE, 0.0, 21.6) for side in (-1, 1)]
        if level == 3:
            made.append(("CHalo24", 0.0, ROW, 0.0))
            made += [("CShard5", x, i, 9.0) for x, i in corners]
    elif key == "D":                    # for the owner the floor's light, at the gate the fins, from afar the halo
        made += [("B2Floor", 0.0, 0.0, 0.0), (f"D{level}Fins", 0.0, 0.0, 0.0), ("DRing14", 0.0, ROW, 0.0)]
        if level == 3:
            made += [("DRays", 0.0, 0.0, 0.0), ("DRing22", 0.0, ROW, 0.0)]
    return made


def behind(at, toward):
    """The game's camera behind a player at `at` who looks toward `toward`: its start zoom, 20 degrees down."""
    from mathutils import Vector
    pitch = math.radians(20.0)
    heading = (Vector((*toward, 0.0)) - Vector((*at, 0.0))).normalized()
    focus = Vector((at[0], at[1], 3.0 + look.FOCUS))
    eye = focus - heading * math.cos(pitch) * look.ZOOM + Vector((0, 0, math.sin(pitch))) * look.ZOOM
    return tuple(eye), tuple(focus)


def see(out: Path, key, level, fast, only=(), spin=None):
    import bpy  # noqa: F401
    global SPIN
    SPIN = spin or 0.0
    base.BAYS_AT.update(BAYS_AT)
    base.PIECES.update(PIECES)
    look.SIZE = SIZE
    d = day.light("day")
    look.FOG.update(colour=look.srgb(d["fog"][0]), density=d["fog"][1], azimuth=d.get("glow_az", 0.0),
                    away=look.srgb(d["fog_away"]) if "fog_away" in d else None)
    scene = bl.reset_scene()
    base.write_pictures(out / "maps")
    yard = plan.Yard(scene, level, out / "maps")
    yard.plot(0.0, 1)
    for i, (name, x, inward, up) in enumerate(grown(key, level)):
        yard.stock.stand(name, f"G{i}", yard.at(0.0, 1, x, inward, up), 0.0)
    yard.level = 1                                                  # across the road: a base at level 1
    yard.plot(plan.STRIP, -1)
    yard.kit.block("Strip", (3 * plan.PLOT, plan.STRIP, 0.4), (0, plan.STRIP / 2, -0.22), yard.stone)
    yard.kit.block("Ground", (5 * plan.PLOT, 4 * plan.PLOT, 0.4), (0, plan.STRIP / 2, -0.3), yard.flat["ground"])
    stands = {"in": (THRESHOLD, (0.0, -ROW)), "gate": (ARRIVING, (0.0, 0.0)), "strip": (WALKER, (0.0, WALKER[1])),
              "far": (FAR, (0.0, FAR[1]))}
    stands = {name: stand for name, stand in stands.items() if not only or name in only}
    for obj in yard.kit.pieces:
        if obj.name.startswith(("PowerSpan", "Court", "Yard", "Wings", "B2Floor", "B3Floor", "BayLine", "BBeam", "DRays")):
            obj.visible_shadow = False
    for name, (at, _) in stands.items():
        yard.person(at, f"Stand{name}")
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
    for name, (at, toward) in stands.items():
        eye, target = behind(at, toward)
        scene.camera = plan.camera(scene, name, eye, target)
        for obj in bpy.data.objects:                                # the player stands only in their own view
            if obj.name.startswith("Stand"):
                obj.hide_render = not obj.name.startswith(f"Stand{name}")
        path = out / (f"{key}{level}_{name}" + ("" if spin is None else f"_t{spin:03.0f}"))
        rs.save(look.finish(look.render_linear(scene, path.with_suffix(".exr")), d), path.with_suffix(".png"))
        path.with_suffix(".exr").unlink(missing_ok=True)
    print(f"AR50: {key}{level} done, {len(yard.kit.pieces)} objects")


def sheet(out: Path):
    rs.OUT = out
    w, h = SIZE
    pad, head, side = 10, 26, 150
    small = []
    for view, what in VIEWS:
        board = rs.canvas(side + 3 * (w + pad) + pad, len(NAMES) * (h + head) + pad + 30, (0.93, 0.93, 0.94))
        words = [(pad, 8, 17, f"AR50, the base's levels, {what}. By day, the player's camera, the smallest phone's pixels",
                  "#16182A")]
        for row, key in enumerate(NAMES):
            y = 30 + row * (h + head) + head
            words.append((pad, y + 6, 15, NAMES[key], "#16182A"))
            for level in (1, 2, 3):
                file = out / f"{'A' if level == 1 else key}{level}_{view}.png"
                if not file.exists():
                    continue
                page = rs.load(file)
                page[..., 3] = 1.0
                x = side + (level - 1) * (w + pad)
                rs.paste(board, page, x, y)
                words.append((x, y - 20, 14, f"Level {level}" + (" (the same in every direction)" if level == 1 else ""),
                              "#16182A"))
                small.append((view, row, level, rs.shrink(page, 64 / h)))
        rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
        rs.save(board, out / f"base_levels_{view}.png")
    if small:
        tw = small[0][3].shape[1]
        order = [v for v, _ in VIEWS]
        board = rs.canvas(len(order) * (3 * (tw + 6) + 6) + 6, len(NAMES) * 70 + 6, (0.93, 0.93, 0.94))
        for view, row, level, tile in small:
            col = order.index(view)
            rs.paste(board, tile, 6 + (col * 3 + level - 1) * (tw + 6) + col * 6, 6 + row * 70)
        rs.save(board, out / "base_levels_64.png")
    print("AR50: sheets done")


def second(out: Path):
    """The second look at D: its levels at each stand, the same at 64 px high, and the rings turning."""
    rs.OUT = out
    w, h = SIZE
    pad, head = 10, 24
    board = rs.canvas(3 * (w + pad) + pad, len(VIEWS) * (h + head) + pad + 30, (0.93, 0.93, 0.94))
    words = [(pad, 8, 17, "AR50, D after research's two fixes: levels 1, 2 and 3 at the four stands. By day, the player's "
              "camera, the smallest phone's pixels", "#16182A")]
    small = rs.canvas(3 * (int(w * 64 / h) + 6) + 6, len(VIEWS) * 70 + 6, (0.93, 0.93, 0.94))
    for row, (view, what) in enumerate(VIEWS):
        y = 30 + row * (h + head) + head
        words.append((pad, y - 19, 14, what[0].upper() + what[1:], "#16182A"))
        for level in (1, 2, 3):
            page = rs.load(out / f"{'A' if level == 1 else 'D'}{level}_{view}.png")
            page[..., 3] = 1.0
            rs.paste(board, page, pad + (level - 1) * (w + pad), y)
            tile = rs.shrink(page, 64 / h)
            rs.paste(small, tile, 6 + (level - 1) * (tile.shape[1] + 6), 6 + row * 70)
    rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
    rs.save(board, out / "base_levels_d.png")
    rs.save(small, out / "base_levels_d_64.png")
    frames = sorted(out.glob("D3_strip_t*.png"))
    if frames:
        half = 0.5
        tw, th = int(w * half), int(h * half)
        board = rs.canvas(len(frames) * (tw + 6) + 6, 2 * (th + head) + 36, (0.93, 0.93, 0.94))
        words = [(6, 8, 15, "AR50, D's rings turning, each its own way: level 3 from the gate's line (above) and from 90 "
                  "studs down the Strip, at half the phone's pixels", "#16182A")]
        for row, view in enumerate(("in", "strip")):
            for col, file in enumerate(frames):
                page = rs.load(file.with_name(file.name.replace("_strip_", f"_{view}_")))
                page[..., 3] = 1.0
                rs.paste(board, rs.shrink(page, half), 6 + col * (tw + 6), 34 + row * (th + head))
                words.append((6 + col * (tw + 6), 34 + row * (th + head) + th + 3, 13, f"turned {file.stem[-3:].lstrip('0') or '0'} degrees",
                              "#16182A"))
        rs.paste(board, rs.text_layer(board.shape[1], board.shape[0], words), 0, 0)
        rs.save(board, out / "base_levels_turn.png")
    print("AR50: second look laid")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "sheet":
        sheet(out)
    elif args[0] == "second":
        second(out)
    else:
        spin = [float(a[5:]) for a in args if a.startswith("spin=")]
        see(out, args[1], int(args[2]), "fast" in args, [a for a in args[3:] if a != "fast" and "=" not in a],
            spin[0] if spin else None)


if __name__ == "__main__":
    main()
