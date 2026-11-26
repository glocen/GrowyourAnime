"""AR67: the Generator, A, the held core (research's pick of 2026-11-26, 19:06), in place of AR19's Void Mill.

A core of cyan light held up in an opened graphite pod, over a lit column that is its gauge: from the gate it reads in
one look as the thing that makes your power, the core the one large glow and the lightest mass. The director's word of
about 17:46 freed the generator from turning a wheel ("just make it the best it can be"). The pod holds still; the
core turns about its upright and breathes, faster as the plant generates more, and motes go round it the other way.
The column's lit steps are the generation, and a steel collar on the column is the demand: the steps reach the collar
when generation meets demand. The battery's cells sit in the foot's three faces toward the gate.

The pieces, as the builder drives them (the Mill's contract where it fits; `stages` is the swap's table, which
base_plan.py writes into the plan):
  Generator            Stage I's still body: the foot (two octagonal tiers, the battery's cells on the faces to the
                       gate), the column's seat, its dark bed and cap, and the pod's two blades on their sockets.
  GeneratorCore        Stage I's core, smaller: its origin at its middle, CORE up. It turns about its own upright,
                       faster as the plant generates more (the wheel's speed), and breathes: its size swells by BREATH
                       and back over PERIOD seconds.
  GeneratorMotes       five motes round the core, their origin at the core's middle: they turn about the same upright
                       the other way, half as fast, driven from the core's angle. Every stage keeps them.
  GeneratorArc1..8     the column's steps of light, each an eighth of the generation's share, shown or hidden, never
                       dimmed, as the Mill's were. Every stage keeps them.
  GeneratorDemand      the steel collar: its origin at its middle, made at a demand's share of 0 at the column's foot;
                       it rises up the column by the share times RISE studs, on the gauge's own scale. Every stage
                       keeps it.
  Generator2           Stage II's still body: the pod's three blades.
  Generator2Core       Stages II and III's core, at full size; it turns and breathes as Stage I's.
  Generator3           Stage III's: the blades taller, their tips grown in to meet in a steel clasp over the core,
                       the pod closed at its crown. No ring: base levels 2 and 3 float their teal rings on the
                       generator's upright already, and level 3 stays one halo (research, 2026-11-23, 03:22).

The frame is the kit's: a piece's front (+Y) toward the gate, its origin on the floor at the generator's middle (at
its own middle for a moving piece), Z up, one unit a stud. Graphite (bone, abyss, well) with cyan the only accent, and
steel for the collar, the sockets and Stage III's clasp.

The content check: a pod of three smooth blades and a round core, no real electrical kit (the director, 2026-11-15),
no living thing's shape, no text. Not run by itself.
"""

import math
import sys
from pathlib import Path

from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import base_machines as bm  # noqa: E402
import base_mill as mill  # noqa: E402  (its geometry helpers: put, motes)
import base_star as star  # noqa: E402  (the well's radius)
import lantern_row_kit as kit  # noqa: E402

Mesh, Piece = bm.Mesh, kit.Piece

STEPS = 8              # the gauge's steps, as the Mill's
COLUMN = (3.2, 0.8, 0.2)   # the column's first step's foot, a step's height, the dark gap between two
CORE = 14.4            # the core's middle, up from the floor
RISE = 8.0             # the collar's travel from a share of 0 to 1: a step and its gap a share of an eighth
COLLAR = 3.0           # the collar's middle at a share of 0: just over the seat, under the first step's head
BREATH, PERIOD = 0.04, 2.4   # the core's breath: its size, out and back
CLASP = [(0.0, 28.9), (0.5, 28.6), (1.05, 27.9), (1.1, 27.4), (0.7, 26.9), (0.0, 26.7)]   # Stage III's, over the core
BLADE = [(4.2, 2.6), (5.9, 5.0), (7.1, 8.8), (7.5, 12.8), (7.1, 16.8), (5.9, 20.0), (4.3, 22.5), (3.2, 23.6)]
BLADE_R = [0.72, 0.84, 0.86, 0.82, 0.74, 0.58, 0.36, 0.1]
CORE_PROFILE = [(0.0, 17.9), (1.55, 17.3), (2.6, 16.1), (3.0, 14.4), (2.65, 12.7), (1.6, 11.5), (0.0, 10.9)]
MOTES = [(4.4, 60, 16.8), (4.9, 200, 12.4), (3.9, 320, 19.0), (5.2, 110, 9.6), (4.2, 250, 18.4)]


# --- shapes ------------------------------------------------------------------------------------------------------------

def lathe(profile, sides, sw, spin=0.0, ink=True, caps=True):
    """A solid turned about Z, `profile` (radius, height) from its head down, with its drawn edge."""
    m = Mesh()
    m.lathe(profile, (0, 0, 0), sides, sw, caps=caps, spin=spin)
    if ink:
        t = m.ink_t / math.cos(math.pi / sides)
        zs = [z for _, z in profile]
        top, foot = max(zs), min(zs)
        grown = [(r + t, z + (t if z == top else -t if z == foot else 0.0)) for r, z in profile]
        hull = Mesh(None)
        hull.lathe(grown, (0, 0, 0), sides, "ink", caps=caps, spin=spin)
        for face in hull.f:
            m.ink.face([hull.v[i] for i in face][::-1], [(0, 0)] * len(face))
    return m


def polar(r, a_deg, z):
    a = math.radians(a_deg)
    return (r * math.cos(a), r * math.sin(a), z)


def facing(a_deg):
    """The 3x3 that turns a box's Y to look out along `a_deg`."""
    return Matrix.Rotation(math.radians(a_deg) - math.pi / 2, 3, "Z")


def spans():
    """Each of the column's steps, its foot and head, from the first up."""
    z0, step, gap = COLUMN
    return [(z0 + k * (step + gap), z0 + k * (step + gap) + step) for k in range(STEPS)]


def foot(m):
    """The foot: two octagonal tiers, a face to the gate, and on the lower tier's three faces there the battery's
    cells, a dark bed with three lit cells on each."""
    spin, (r_low, h_low), (r_up, h_up) = math.pi / 8, (7.0, 1.6), (5.4, 1.0)
    mill.put(m, lathe([(r_low, h_low), (r_low, 0.0)], 8, "bone", spin=spin), Matrix())
    mill.put(m, lathe([(r_up, h_low + h_up), (r_up, h_low)], 8, "abyss", spin=spin), Matrix())
    apothem, width, height, z = r_low * math.cos(math.pi / 8), 2 * r_low * math.sin(math.pi / 8) * 0.74, h_low * 0.62, h_low / 2
    for a in (45, 90, 135):
        rot, out = facing(a), Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0.0))
        m.box((width, 0.3, height), Vector((0, 0, z)) + out * (apothem - 0.08), "well", rot=rot)
        w, across = (width - 0.5) / 3, Vector((-out.y, out.x, 0.0))
        for k in range(3):
            c = Vector((0, 0, z)) + out * (apothem + 0.06) + across * (-width / 2 + 0.25 + w * (k + 0.5))
            m.box((w - 0.22, 0.12, height - 0.34), c, "cyan", rot=rot)


def column(m):
    """The column's seat on the foot, its dark bed the steps stand on, and its cap under the core."""
    steps, gap = spans(), COLUMN[2]
    mill.put(m, lathe([(3.6, 2.9), (4.2, 2.6)], 16, "bone"), Matrix())
    mill.put(m, lathe([(0.9, steps[-1][1] + gap), (0.9, COLUMN[0] - gap)], 12, "well", ink=False), Matrix())
    mill.put(m, lathe([(1.5, steps[-1][1] + 0.55), (1.2, steps[-1][1] + 0.2)], 12, "abyss"), Matrix())


def blades(m, angles, grown=False):
    """The pod: broad smooth blades, a ridge down each, cupped round the core and open between them, each on a steel
    socket on the foot. Grown (Stage III): taller, the tips bent in to meet in a steel clasp over the core."""
    path = [(r, z) for r, z in BLADE]
    if grown:
        path = [(r * 1.04, 2.6 + (z - 2.6) * 1.1) for r, z in BLADE[:-1]] + [(2.4, 26.6), (0.9, 27.5)]
        mill.put(m, lathe(CLASP, 12, "steel"), Matrix())
    radii = BLADE_R if not grown else BLADE_R[:-1] + [0.26, 0.16]
    for a in angles:
        bm.horn(m, [polar(r, a, z) for r, z in path], radii, "bone", flat=polar(1.0, a + 90, 0.0), deep=2.9)
        m.box((3.4, 2.0, 1.1), polar(4.4, a, 3.0), "steel", rot=facing(a), ink=True)


def core(scale):
    """The core about its own middle: a round of the void's light, widest a little under its middle."""
    m = Mesh()
    mill.put(m, lathe([(r * scale, (z - CORE) * scale) for r, z in CORE_PROFILE], 14, "cyan", ink=False), Matrix())
    return m


# --- the pieces --------------------------------------------------------------------------------------------------------

STAGE_BLADES = {1: (0, 180), 2: (270, 30, 150), 3: (270, 30, 150)}   # Stage I's two clasp it side on, open to the gate
CORE_SCALE = {1: 0.8, 2: 1.0, 3: 1.0}
SOLID = (f"in the piece's frame (across, toward the gate, up): the well shut to walking, a cylinder of radius "
         f"{star.WELL:g} (the painted well's), 2.6 high, at the middle: the foot stands in it, 14 across its corners. "
         f"The blades, the column and the core stand over the foot's top: look only")


def body(stage):
    m = Mesh()
    foot(m)
    column(m)
    blades(m, STAGE_BLADES[stage], grown=stage == 3)
    return m


def generator():
    return Piece("Generator", body(1), solid=SOLID,
                 note=f"its middle on the well's. Stage I: the pod's two blades clasp the core side on, open to the "
                      f"gate. The core (GeneratorCore) and its motes (GeneratorMotes) turn {CORE:g} up over the "
                      f"column; the column's steps (GeneratorArc1 to {STEPS}) light up it, and the collar "
                      f"(GeneratorDemand) rides it. About {max(z for _, z in BLADE):g} studs tall")


def generator_stage(stage):
    def make():
        top = CLASP[0][1] if stage == 3 else max(z for _, z in BLADE)
        return Piece(f"Generator{stage}", body(stage), solid=SOLID,
                     note=f"Stage {'II' if stage == 2 else 'III'}'s still body, in place of the stage before's: the "
                          f"pod's three blades" + (", taller, their tips met in a steel clasp over the core" if stage == 3 else "")
                          + f". About {top:g} studs tall")
    return make


def generator_core(stage):
    name = "GeneratorCore" if stage == 1 else "Generator2Core"

    def make():
        return Piece(name, core(CORE_SCALE[stage]),
                     note=f"its origin is its middle, {CORE:g} up at the generator's middle. It turns about its own "
                          f"upright (Roblox's Y, CFrame.Angles(0, angle, 0)), faster as the plant generates more, "
                          f"still at none: the Mill's wheel's speed (Generator.Wheel). It breathes: its size "
                          f"{1 + BREATH:g} times and back over {PERIOD:g} seconds, about its middle, while it turns. "
                          f"The one large glow: the void's pale light. Look only")
    return make


def generator_motes():
    m = Mesh()
    mill.motes(m, [polar(r, a, z - CORE) for r, a, z in MOTES], 0.32)
    return Piece("GeneratorMotes", m,
                 note=f"its origin at the core's middle, {CORE:g} up. The motes go round the core the other way, half "
                      f"as fast: turned about the same upright by the core's angle times -0.5, so they never run on "
                      f"a clock of their own. Look only")


def generator_arc(i):
    def make():
        foot_, head = spans()[i]
        m = Mesh()
        mill.put(m, lathe([(1.06, head), (1.06, foot_)], 12, "cyan", ink=False), Matrix())
        return Piece(f"GeneratorArc{i + 1}", m,
                     note=f"the column's step {i + 1} of {STEPS}, from the foot up, {foot_:g} to {head:g} up: the "
                          f"generation's share from {i / STEPS:g} to {(i + 1) / STEPS:g}. Still, at the generator's "
                          f"place. Light the first k steps, k the share times {STEPS} rounded: shown or hidden "
                          f"(Transparency), never dimmed; hidden, the column's dark bed shows. Look only")
    return make


def generator_demand():
    m = Mesh()
    bm.hoop(m, (0, 0, 0), 1.12, 1.62, 0.34, 16, "steel", lying=True)
    return Piece("GeneratorDemand", m,
                 note=f"its origin is its middle, made at a demand's share of 0, {COLLAR:g} up on the column's foot. "
                      f"It rises up the column by the share times {RISE:g} studs, on the gauge's own scale (the "
                      f"demand over the same top as the generation's), so the lit steps reach it when generation meets "
                      f"demand: at 1 its middle is {COLLAR + RISE:g} up, under the column's cap. Gliding there as the "
                      f"Mill's mark did (Generator.Gauge.Glide). Look only")


def stages():
    """The swap's table: each stage's pieces, where each stands from the generator's place (across, toward the gate,
    up), and how it moves. `turns` with `rate` 1 is a stage's core, about its own upright at the plant's speed, and
    `breathes` its size's swell over `period` seconds; any other rate follows the core's angle times the rate, the
    way the Mill's pinions followed its wheel; `gauge` a step, lit while the generation's share reaches it; `rises`
    the collar, by the demand's share times `studs`."""
    table = {}
    for stage in (1, 2, 3):
        rows = [dict(piece="Generator" if stage == 1 else f"Generator{stage}", at=[0.0, 0.0, 0.0], moves="still"),
                dict(piece="GeneratorCore" if stage == 1 else "Generator2Core", at=[0.0, 0.0, CORE], moves="turns",
                     axis="up", rate=1.0, breathes=BREATH, period=PERIOD),
                dict(piece="GeneratorMotes", at=[0.0, 0.0, CORE], moves="turns", axis="up", rate=-0.5)]
        rows += [dict(piece=f"GeneratorArc{i + 1}", at=[0.0, 0.0, 0.0], moves="gauge", step=i + 1) for i in range(STEPS)]
        rows.append(dict(piece="GeneratorDemand", at=[0.0, 0.0, COLLAR], moves="rises", studs=RISE))
        table[str(stage)] = rows
    return table


PIECES = {"Generator": generator, "GeneratorCore": generator_core(1), "GeneratorMotes": generator_motes,
          **{f"GeneratorArc{i + 1}": generator_arc(i) for i in range(STEPS)}, "GeneratorDemand": generator_demand,
          "Generator2": generator_stage(2), "Generator3": generator_stage(3), "Generator2Core": generator_core(2)}
