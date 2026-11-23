"""AR50: the base's levels 2 and 3, the whole yard's look, as base kit pieces (docs/asset-requests.md, AR50).

Research picked D of the blockout's four directions (base_levels_block.py): one sign for each place a player stands,
and one more of each a level. The game's camera looks 20 degrees down, so from near only what stands under about 20
studs is seen: a level needs a low sign and a high one.
  For the owner at the gate's line, the floor: at level 2 the way in lights down both its edges and runs into a second
  ring round the well; at level 3 rays join the two rings.
  For a visitor at the gate, the fins: a small tower of the gate's own make on each of its shoulders at level 2, a
  second pair outside them at level 3.
  For the Strip, the rings afloat, a halo stacked on one axle through the plot's heart: at level 2 a slim ring of
  the gate's teal over the floor's second ring and of its size, wide of the generator at every stage, its gate side
  raised so its face shows, turning slowly; at level 3 a second on the same axle, wider and higher, turning the other
  way (research's call of 2026-11-23, 03:22: the sky echoes the floor, and level 3 stays one halo).
And a bay that wakes lights its line: the bus's current runs on to it and its ground's frame lights.

The pieces (base_kit.py takes PIECES), each stood in the plot's frame by tables(), plan.json's machines.baseLevels:
  LevelFloor      level 2's light on the deck: the way in's two lines and the second ring
  LevelRays       level 3's: the rays between the rings
  LevelFin        level 2's fin, one on each shoulder of the gate
  LevelFinOuter   level 3's, lower, outside them
  LevelRing       level 2's ring afloat; it turns
  LevelRingOuter  level 3's; it turns the other way
  BayWake         a woken bay's lit line and frame, in the bay's own frame (bays 3 and 4)

Nothing here is violet (AR40: violet only on what's alive). The floor's light is the current's yellow, as the
conduits'; the rings' is the void's teal. Every light on a body lies in a dark bed (AR40).

The review, the finish at the blockout's four stands by day, and the rings turning:
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_levels.py -- <abs out_dir> see <2|3> [fast] [in] [gate] [strip] [far] [spin=<degrees>]
blender.exe -b --factory-startup --python-exit-code 1 --python tools/blender/base_levels.py -- <abs out_dir> sheet

The rings' audit, after every export (no Blender): py tools/blender/base_levels_clear.py
"""

import math
import sys
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
from base_mill import Mesh, at, prism, put, turned  # noqa: E402
from lantern_row_kit import Piece  # noqa: E402

# The plot's own numbers, base_kit.py's (which takes this module's pieces, so they're held to it in tables())
GATE, ROW, LANE, RING, OUTER, FAR, SLEEPS = 22.0, 52.0, 12.5, 18.0, 31.5, 54.5, 6.2

SECOND = 23.0                         # the second ring on the deck, round the well: clear of the bays' frames by 2
MEETS = math.degrees(math.asin(LANE / SECOND))   # where a line of the way in runs into it, from the line to the gate
LIT, BED, SLICE = 0.17, 0.11, 0.06    # a light on the deck and its dark bed: their middles up, and how thick each is
FINS = {"LevelFin": dict(tall=12.5, wide=1.9, reach=4.6), "LevelFinOuter": dict(tall=9.5, wide=1.7, reach=8.4)}
# The rings' one axle: it stands on the heart's own upright at level 2's ring's middle, AXLE_UP over the deck, its top
# leant into the plot so each ring's gate side is raised (`tilt`), and across it not at all (`lean`: above zero, a
# ring's right side from the gate dips). Measured by base_levels_clear.py, after every export, against everything that
# stands on a plot at levels 2 and 3: at this tilt and height level 2's ring is whole in the frame from the gate's line
# and passes over the flood masts' heads; two degrees more and it leaves the frame's top.
AXLE_UP, AXLE = 14.0, dict(tilt=9.0, lean=0.0)
# A ring afloat: its radius, its section (across, up), its lengths in degrees, a bead in each gap, its tips' length;
# how far up the axle its middle stands from level 2's ring's, and its turning, in turns a second.
RINGS = {
    "LevelRing": dict(radius=SECOND, section=(1.6, 1.05), spans=[(k * 90.0 + 4.5, k * 90.0 + 85.5) for k in range(4)],
                      beads=[0.0, 90.0, 180.0, 270.0], bead=(0.6, 1.3), tips=2.4, rise=0.0, sign=1, rate=0.02),
    "LevelRingOuter": dict(radius=27.0, section=(2.1, 1.35),
                           spans=[(3.75, 117.25), (124.75, 176.25), (183.75, 297.25), (304.75, 356.25)],
                           beads=[0.0, 121.0, 180.0, 301.0], bead=(0.8, 1.8), tips=3.0, rise=10.6, sign=-1, rate=0.012),
}
QUARTER = Matrix.Rotation(math.pi / 4, 4, "Z")   # a four-sided turned shape, its faces square to the piece
TIP = 0.05                            # a point's own radius: a turned shape closed to nothing loses its faces


# --- shapes ------------------------------------------------------------------------------------------------------------

def _p(r, q, z):
    return Vector((r * math.cos(math.radians(q)), r * math.sin(math.radians(q)), z))


def arc(m, r0, r1, z0, z1, a, b, sw, n, tips=0.0, ink=True):
    """A curved bar about Z, from `r0` out to `r1` and `z0` up to `z1`, from `a` to `b` degrees in `n` lengths, with
    its drawn edge. With `tips`, that many studs of each end are drawn to a point on its middle line."""
    rm, zm = (r0 + r1) / 2, (z0 + z1) / 2
    edge = m.ink_t if ink and m.ink is not None else None
    point = math.degrees(tips / rm)
    for grow, hull in ((0.0, False),) + (((edge, True),) if edge else ()):
        near, far, low, high = r0 - grow, r1 + grow, z0 - grow, z1 + grow
        more = 0.0 if tips else math.degrees(grow / rm)
        start, end = a + point - more, b - point + more
        qs = [start + (end - start) * k / n for k in range(n + 1)]

        def shade(t, corners=4):
            return [(0, 0)] * corners if hull else [kit.sw_uv(sw, 0.0, t)] * corners

        walls = (((far, low), (far, high), 0.55), ((far, high), (near, high), 0.9), ((near, high), (near, low), 0.55),
                 ((near, low), (far, low), 0.25))
        for k in range(n):
            core = _p(rm, (qs[k] + qs[k + 1]) / 2, zm)
            for (ra, za), (rb, zb), t in walls:
                m.out([_p(ra, qs[k], za), _p(rb, qs[k], zb), _p(rb, qs[k + 1], zb), _p(ra, qs[k + 1], za)], shade(t),
                      core, ink=hull)
        for q, way in ((start, -1), (end, 1)):
            core = _p(rm, q - way * 0.5, zm)
            if not tips:
                m.out([_p(near, q, low), _p(far, q, low), _p(far, q, high), _p(near, q, high)], shade(0.55), core, ink=hull)
                continue
            tip = q + way * (point + 1.6 * math.degrees(grow / rm))
            m.out([_p(near, q, high), _p(far, q, high), _p(rm, tip, high)], shade(0.9, 3), core, ink=hull)
            m.out([_p(near, q, low), _p(far, q, low), _p(rm, tip, low)], shade(0.25, 3), core, ink=hull)
            for r in (near, far):
                m.out([_p(r, q, low), _p(r, q, high), _p(rm, tip, high), _p(rm, tip, low)], shade(0.55), core, ink=hull)


def strip(m, a, b, n, sw, rail0, rail1, core):
    """A curved face about Z from `a` to `b` degrees, between two rails (radius, height), turned away from the body
    whose middle line is `core` (radius, height): a line of light on a ring's face, or its bed."""
    qs = [a + (b - a) * k / n for k in range(n + 1)]
    uv = [kit.sw_uv(sw, 0.0, 0.9)] * 4
    for k in range(n):
        m.out([_p(rail0[0], qs[k], rail0[1]), _p(rail1[0], qs[k], rail1[1]), _p(rail1[0], qs[k + 1], rail1[1]),
               _p(rail0[0], qs[k + 1], rail0[1])], uv, _p(core[0], (qs[k] + qs[k + 1]) / 2, core[1]))


def bead(m, where, wide, half):
    """A bead of the void's teal light afloat: eight faces, pointed up and down."""
    put(m, turned([(TIP, half), (wide, 0.0), (TIP, -half)], 4, "cyan", ink=False), at(*where) @ QUARTER)


def laid(m, a, b, wide, bed=0.3):
    """A line of light on the deck from a to b (across, toward the gate), in its dark bed."""
    a, b = Vector((*a, 0.0)), Vector((*b, 0.0))
    run, mid = (b - a).length, (a + b) / 2
    rot = (0.0, 0.0, math.atan2(b.y - a.y, b.x - a.x))
    m.box((run, wide, SLICE), (mid.x, mid.y, LIT), "power", rot=rot)
    m.box((run + 2 * bed, wide + 2 * bed, SLICE), (mid.x, mid.y, BED), "well", rot=rot)


def node(m, where, size=0.9, turn=45.0):
    """Where two lines of light meet on the deck: a square of light on its point, in its bed."""
    rot = (0.0, 0.0, math.radians(turn))
    m.box((size, size, SLICE), (*where, LIT + 0.02), "power", rot=rot)
    m.box((size + 0.8, size + 0.8, SLICE), (*where, BED + 0.02), "well", rot=rot)


# --- the floor's light -----------------------------------------------------------------------------------------------

def level_floor():
    m = Mesh(None)
    for side in (-1, 1):                                # the way in's own two lines, lit from the sill to the ring
        x = side * LANE
        laid(m, (x, -3.0), (x, -(ROW - SECOND * math.cos(math.radians(MEETS)))), 0.5)
        node(m, (x, -3.0))
    g = Mesh(None)                                      # the second ring, open toward the gate between the two lines
    start, end = 90.0 + MEETS, 450.0 - MEETS
    arc(g, SECOND - 0.25, SECOND + 0.25, LIT - SLICE / 2, LIT + SLICE / 2, start, end, "power", 60, ink=False)
    arc(g, SECOND - 0.55, SECOND + 0.55, BED - SLICE / 2, BED + SLICE / 2, start - 0.6, end + 0.6, "well", 60, ink=False)
    put(m, g, at(0, -ROW, 0))
    for q in (start, end, 0.0, 180.0, 45.0, 135.0, 225.0, 315.0, 270.0):   # where it meets the way in's lines and
        where = _p(SECOND, q, 0.0)                                         # crosses each line leaving the heart
        node(m, (where.x, where.y - ROW), turn=q + 45.0)
    return Piece("LevelFloor", m,
                 note=f"base level 2's light on the deck, from level 2 on: the way in's two lines lit from the sill "
                      f"to a second ring round the well, {SECOND:g} in radius, open toward the gate between them, a "
                      f"node where it crosses each line leaving the heart. Its lights' tops are 0.2 up, over the "
                      f"floors' pictures. Stood at the plot's front edge, on its middle line. Look only, CastShadow off")


def level_rays():
    m = Mesh(None)
    r0, r1 = RING + 1.4, SECOND - 1.1
    centre = Vector((0.0, -ROW, 0.0))
    count = 0
    for k in range(16):
        q = math.radians((k + 0.5) * 22.5)
        o, s = Vector((math.cos(q), math.sin(q), 0.0)), Vector((-math.sin(q), math.cos(q), 0.0))
        if o.y > 0 and abs(o.x) * SECOND < LANE + 2.0:   # none on the way in
            continue
        count += 1
        for sw, grow, z in (("power", 0.0, LIT), ("well", 0.3, BED)):
            lift = Vector((0, 0, z))
            rim = [centre + o * (r0 - grow) - s * (0.45 + grow) + lift, centre + o * (r1 + grow) - s * (0.16 + grow) + lift,
                   centre + o * (r1 + grow) + s * (0.16 + grow) + lift, centre + o * (r0 - grow) + s * (0.45 + grow) + lift]
            prism(m, rim, SLICE, sw, centre + o * (r0 + r1) / 2 + lift)
    return Piece("LevelRays", m,
                 note=f"base level 3's light on the deck, beside LevelFloor: {count} rays from the first ring out to "
                      f"the second, each narrowing outward, none across the way in. Stood at the plot's front edge, "
                      f"on its middle line. Look only, CastShadow off")


def bay_wake():
    m = Mesh(None)
    for k in range(4):                                  # the ground's frame, heavy at its corners, as the open bay's
        rot = Matrix.Rotation(math.pi / 2 * k, 3, "Z")
        for size, where, bed in (((2 * SLEEPS, 0.24), (0.0, SLEEPS), 0.22), ((2.6, 0.6), (SLEEPS - 1.3, SLEEPS), 0.22),
                                 ((2.6, 0.6), (-(SLEEPS - 1.3), SLEEPS), 0.22)):
            for sw, grow, z in (("power", 0.0, LIT), ("well", bed, BED)):
                m.box((size[0] + 2 * grow, size[1] + 2 * grow, SLICE), tuple(rot @ Vector((*where, z))), sw, rot=rot)
    reach = FAR - OUTER - SLEEPS                        # the bus's current, on from the bay before it
    m.box((reach - SLEEPS - 0.9, 0.64, SLICE), ((reach + SLEEPS) / 2, 0.0, LIT), "power")
    for x in (SLEEPS + 0.05, reach):
        node(m, (x, 0.0), size=1.1)
    return Piece("BayWake", m,
                 note=f"a woken bay's light on the deck, for bays 3 and 4 (the bus's line outward): its ground's "
                      f"frame lit, {2 * SLEEPS:g} square and heavy at its corners as an open bay's is in the floor's "
                      f"picture, and the bus's current run on to it from the bay before, over the dead casing. In the "
                      f"bay's own frame, stood at the bay's place with the bay's turn (0 on the plot's left, 180 on "
                      f"its right), while the bay is awake. Look only, CastShadow off")


# --- the fins --------------------------------------------------------------------------------------------------------

def fin(name):
    def make():
        f = FINS[name]
        tall, wide = f["tall"], f["wide"]
        m = Mesh()
        waist, head = round(tall * 0.58, 2), tall - 1.7
        m.box((wide + 0.9, wide + 0.9, 1.2), (0, 0, 0.6), "concrete", ink=True)
        m.box((wide, wide, waist - 1.2), (0, 0, (waist + 1.2) / 2), "girder", ink=True)
        run = waist - 3.2
        for way in (-1, 1):                             # a line of light down its Strip and yard faces, as the towers'
            bm.lamp(m, (0.5, 0.16, run), (0, way * (wide / 2 + 0.04), 2.4 + run / 2), "power", 1, way, pad=0.2)
        m.box((wide + 0.5, wide + 0.5, 0.4), (0, 0, waist + 0.2), "bone", ink=True)
        root, neck = (wide - 0.45) / math.sqrt(2), (wide - 0.95) / math.sqrt(2)
        put(m, turned([(neck, head - 0.35), (root, waist + 0.4)], 4, "girder"), QUARTER)
        m.box((wide - 0.4, wide - 0.4, 0.35), (0, 0, head - 0.175), "bone", ink=True)
        put(m, turned([(TIP, tall), (neck * 0.94, head)], 4, "girder"), QUARTER)
        bead(m, (0, 0, tall + 1.45), 0.4, 0.95)
        which = ("level 2's, one on each shoulder of the gate" if name == "LevelFin"
                 else "level 3's, lower, one outside each of level 2's")
        return Piece(name, m, solid=f"a box, {wide + 0.9:g} square, {tall:g} high",
                     note=f"a fin of the gate's own make, {which}: a teal shaft on a concrete foot, a line of light in "
                          f"its dark bed on its Strip and yard faces, a bone collar, a narrowing shaft, a bone cap and "
                          f"a spire to {tall:g}, a bead of teal light afloat over it. It stands astride the gate's "
                          f"shoulder wall, {GATE + f['reach']:g} from the plot's middle line, the same piece on both "
                          f"sides")
    return make


# --- the rings afloat ------------------------------------------------------------------------------------------------

def ring(name):
    def make():
        r = RINGS[name]
        radius, (wide, tall) = r["radius"], r["section"]
        r0, r1 = radius - wide / 2, radius + wide / 2
        m = Mesh()
        for a, b in r["spans"]:
            point = math.degrees(r["tips"] / radius)
            n = max(4, round((b - a - 2 * point) / 7.0))
            arc(m, r0, r1, -tall / 2, tall / 2, a, b, "girder", n, tips=r["tips"])
            la, lb = a + point + 1.5, b - point - 1.5   # its light: on its inner and outer faces, and under it
            for (face, inward), half in (((r0, 1), 0.27 * tall), ((r1, -1), 0.27 * tall)):
                for sw, out, reach in (("well", 0.03, half + 0.14 * tall), ("cyan", 0.06, half)):
                    strip(m, la, lb, n, sw, (face - inward * out, reach), (face - inward * out, -reach), (radius, 0.0))
            for sw, out, reach in (("well", 0.03, 0.4 * wide), ("cyan", 0.06, 0.27 * wide)):
                strip(m, la, lb, n, sw, (radius - reach, -tall / 2 - out), (radius + reach, -tall / 2 - out), (radius, 0.0))
        for q in r["beads"]:
            bead(m, tuple(_p(radius, q, 0.0)), *r["bead"])
        which = ("level 2's, over the floor's second ring and of its size" if name == "LevelRing"
                 else "level 3's, wider and higher on the same axle")
        return Piece(name, m,
                     note=f"a ring afloat, {which}: {2 * r1:g} across, {wide:g} by {tall:g} in section, in the gate's "
                          f"teal, in {len(r['spans'])} lengths drawn to a point at each end, a bead of teal light in "
                          f"each gap, a line of teal light in its dark bed on its inner and outer faces and under it. "
                          f"Built lying flat, its origin its middle, its axle the piece's Z (Roblox's Y). It stands "
                          f"tilted and turns about its own axle by machines.baseLevels. Look only")
    return make


PIECES = {"LevelFloor": level_floor, "LevelRays": level_rays, "BayWake": bay_wake, "LevelFin": fin("LevelFin"),
          "LevelFinOuter": fin("LevelFinOuter"), "LevelRing": ring("LevelRing"), "LevelRingOuter": ring("LevelRingOuter")}
FLAT = ("LevelFloor", "LevelRays", "BayWake")   # light on the deck: these cast no shadow


# --- where each stands ------------------------------------------------------------------------------------------------

def lean_of(name, turned_by=0.0):
    """A ring's turn in Blender's piece frame: about its own axle, then its gate side raised, then its lean."""
    return (Matrix.Rotation(math.radians(-AXLE["lean"]), 3, "Y") @ Matrix.Rotation(math.radians(AXLE["tilt"]), 3, "X")
            @ Matrix.Rotation(math.radians(turned_by * RINGS[name]["sign"]), 3, "Z"))


def rows(level):
    """What a level adds, in the plot's frame: across from its middle line, along from its front edge (toward the
    gate above zero, so into the plot is below), up."""
    made = []
    for name in (("LevelFloor", "LevelFin", "LevelRing") if level == 2 else ("LevelRays", "LevelFinOuter", "LevelRingOuter")):
        if name in FINS:
            made += [dict(piece=name, across=side * (GATE + FINS[name]["reach"]), along=0.0, up=0.0, moves="still")
                     for side in (-1, 1)]
        elif name in RINGS:
            r = RINGS[name]
            axle = lean_of(name) @ Vector((0, 0, 1))
            middle = Vector((0.0, -ROW, AXLE_UP)) + axle * r["rise"]   # both rings' middles are on the one axle
            made.append(dict(piece=name, across=round(middle.x, 2), along=round(middle.y, 2), up=round(middle.z, 2),
                             moves="turns", tilt=AXLE["tilt"], lean=AXLE["lean"], sign=r["sign"], rate=r["rate"],
                             axle=[round(axle.x, 4), round(axle.z, 4), round(-axle.y, 4)]))
        else:
            made.append(dict(piece=name, across=0.0, along=0.0, up=0.0, moves="still"))
    return made


def tables():
    import base_kit as base
    assert (GATE, ROW, LANE, RING, OUTER, FAR, SLEEPS) == (base.GATE, base.ROW, base.LANE, base.RING, base.OUTER, base.FAR,
                                                           base.SLEEPS), "base_levels.py's plot numbers aren't base_kit's"
    return dict(baseLevels=dict(
        note="AR50: what the yard gains at base levels 2 and 3, over level 1's plan. Not a machine: it stands with the "
             "base's level (Config.Base), and a level's pieces stand beside those of the level under it, never in "
             "their place. Each row is in the plot's frame, laid as a placement is: `across` from its middle line, "
             "`along` from its front edge (toward the gate above zero), `up`. `moves`: still; turns, always, about "
             "the piece's own axle at `rate` turns a second, the way `sign` gives. A ring stands at its row's place as "
             "CFrame.Angles(0, 0, math.rad(lean)) * CFrame.Angles(math.rad(tilt), 0, 0) * CFrame.Angles(0, angle * "
             "sign, 0) in the plot's frame: `tilt` raises its gate side, `lean` dips its right side as seen from the "
             "gate, and `axle` is where its axle then points, in Roblox's frame, to check the turn by. LevelFloor, "
             "LevelRays and BayWake are light on the deck: no collision, CastShadow off. The fins and the rings are "
             "the gate's teal with their light in the mesh's glow, never Neon. The two rings share one axle (the same "
             "`tilt`, `lean` and `axle`), through the plot's heart: LevelRing over the floor's second ring and of its "
             "size, LevelRingOuter further up it, so its `along` is a little behind the heart's line. Measured against "
             "the exported meshes over a full turn (docs/asset-requests.md, AR50, the rings' refit): both pass every "
             "stage of the generator and every other piece on the plot by more than 1.2.",
        levels={str(level): dict(pieces=rows(level)) for level in (2, 3)},
        bayWake=dict(piece="BayWake", bays=[3, 4],
                     note="stood at the bay's own place with the bay's turn while that bay is awake; bays 5 and 6, "
                          "whose line runs back along the wall, wait for their levels")))


def stood(level, spin=0.0):
    """The review's rows at a level: piece, across, in from the front edge, up, turn, and a ring's own turn."""
    made = []
    for at_level in range(2, level + 1):
        for row in rows(at_level):
            made.append((row["piece"], row["across"], -row["along"], row["up"], 0.0,
                         lean_of(row["piece"], spin) if row["piece"] in RINGS else None))
    for index in range(2, {1: 2, 2: 3, 3: 4}[level]):   # docs/design.md, "The base": two bays, then three, then four
        made.append(("BayWake", (-FAR, FAR)[index - 2], ROW, 0.0, (0.0, 180.0)[index - 2], None))
    return made


# --- the review ---------------------------------------------------------------------------------------------------------

def main():
    import base_levels_block as block
    import blcommon as bl
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    if args[0] == "sheet":
        block.second(out, "F")
    else:
        spin = [float(a[5:]) for a in args if a.startswith("spin=")]
        block.see(out, "F", int(args[1]), "fast" in args, [a for a in args[2:] if a != "fast" and "=" not in a],
                  spin[0] if spin else None)


if __name__ == "__main__":
    main()
