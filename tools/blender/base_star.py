"""AR54: the yard's star on the deck, as geometry: each machine's ground and the line that feeds it. No Blender.

The spots are base_fit.PLAN's, and a ground is its machine's Stage III footprint (base_fit's, from the handoff's own
meshes) with a margin, so the deck is drawn once for what each machine grows into. The floor's pictures (base_kit.py),
the levels' light on the deck (base_levels.py) and the plan (base_plan.py) all read this, so a spot that moves takes its
ground and its line with it.

    py tools/blender/base_star.py        every ground and every line, to read

Across is the plot's own X from its middle line, the Breaker's side above zero (the left, seen from the gate); inward is
studs in from the front edge. A bearing is a line's direction out of the heart, in degrees anticlockwise from the
Breaker's side as seen from above, so 90 is toward the gate (the levels' own turn).

The lines, each from the heart outward:
  the ring      round the well, open toward the gate; a link from the well's rim to it on each side and at its back
  the slants    the ring's two open ends run on at 45 degrees to the Breaker's ground and the Door's
  the spokes    a line straight out of the heart to bays 1 and 2 and the Condenser; and, with no current yet, to the
                Lab's stone and to sleeping bays 3, 4 and 6. Bay 5's is the main line, straight back from the ring
  the branches  a spoke can't reach the Training machine (bay 1's ground is in its way) or the Forge (bay 2's), nor the
                battery (the Lab's stone): the Training machine's line leaves bay 2's spoke at a node and runs across to
                it; the Forge's runs on from the Training machine's ground along the wall; the battery's runs on from
                the Breaker's ground on the slant
"""
import math

import base_fit as fit

PLAN = fit.PLAN
GENERATOR = PLAN["generator"][:2]
ROW = GENERATOR[1]                 # the heart's line, in from the front edge
WELL = 9.0                         # the generator's ground: a well of void under the plant's heart, its radius
RING = 18.0                        # the ring of current round the well, open toward the gate: its radius
SLEEPS = 6.2                       # a bay's ground, open or asleep, and the Lab's stone's: its frame's half side
LANE = 8.5                         # the way in's two edge lines, across: inside the way's 20 studs, since the
                                   # Breaker's Stage III ground comes to 9.3 of the middle line (they were at 12.5)
EDGE = 0.9                         # a machine's ground past its Stage III footprint, all round
OPEN = ("bay1", "bay2")            # level 1's bays
LATER = ("bay3", "bay4", "bay5", "bay6")   # in the order they open: level 2's, level 3's, then the two locked at launch
MACHINES = ("breaker", "door", "battery", "training", "forge", "condenser")
FRAMED = OPEN + LATER + ("lab",)   # a square frame about the spot
LIVE = ("breaker", "door", "bay1", "bay2", "condenser", "training", "forge", "battery")
_boxes = {}


def spot(name):
    return PLAN[name][:2]


def ground(name):
    """A place's ground on the deck: across from and to, inward from and to."""
    x, z = spot(name)
    if name in FRAMED:
        return (x - SLEEPS, x + SLEEPS, z - SLEEPS, z + SLEEPS)
    if not _boxes:
        _boxes.update(fit.boxes(PLAN, 3))
    x0, x1, z0, z1, _ = _boxes[name]
    return (round(x0 - EDGE, 2), round(x1 + EDGE, 2), round(z0 - EDGE, 2), round(z1 + EDGE, 2))


def _enter(a, u, box):
    """Where the ray from `a` along `u` first meets a ground's edge."""
    x0, x1, z0, z1 = box
    near, far = 0.0, math.inf
    for p, d, lo, hi in ((a[0], u[0], x0, x1), (a[1], u[1], z0, z1)):
        if abs(d) < 1e-9:
            assert lo <= p <= hi, "the line misses its ground"
            continue
        t0, t1 = sorted(((lo - p) / d, (hi - p) / d))
        near, far = max(near, t0), min(far, t1)
    assert near <= far, "the line misses its ground"
    return (round(a[0] + u[0] * near, 2), round(a[1] + u[1] * near, 2))


def _out(u):
    """A line out of the heart along `u`: its end on the ring."""
    return (GENERATOR[0] + RING * u[0], GENERATOR[1] + RING * u[1])


def _toward(name):
    dx, dz = spot(name)[0] - GENERATOR[0], spot(name)[1] - GENERATOR[1]
    reach = math.hypot(dx, dz)
    return (dx / reach, dz / reach)


def lines():
    """Every line to a place: where it starts, where it ends on the place's ground, whether current runs in it at
    level 1, and its bearing out of the heart when it leaves the ring itself."""
    made = {}

    def add(name, a, u, heart=True):
        made[name] = dict(a=(round(a[0], 2), round(a[1], 2)), b=_enter(a, u, ground(name)), live=name in LIVE,
                          bearing=round(math.degrees(math.atan2(-u[1], u[0])) % 360.0, 2) if heart else None)

    s = math.sqrt(0.5)
    add("breaker", _out((s, -s)), (s, -s))
    add("door", _out((-s, -s)), (-s, -s))
    for name in ("bay1", "bay2", "condenser", "lab", "bay3", "bay4", "bay6"):
        add(name, _out(_toward(name)), _toward(name))
    add("bay5", _out((0.0, 1.0)), (0.0, 1.0))
    # the Training machine's, from a node on bay 2's spoke level with its spot
    (bx, bz), (tx, tz) = spot("bay2"), spot("training")
    t = (tz - ROW) / (bz - ROW)
    add("training", (GENERATOR[0] + t * (bx - GENERATOR[0]), tz), (math.copysign(1.0, tx - bx), 0.0), heart=False)
    # the Forge's, on from the Training machine's ground, straight back
    add("forge", (tx, ground("training")[3]), (0.0, 1.0), heart=False)
    # the battery's, on from the Breaker's ground on the slant, to the middle of its ground's front edge
    x1 = ground("breaker")[1]
    kx, kz = spot("battery")[0], ground("battery")[2]
    made["battery"] = dict(a=(x1, round(kz - (kx - x1), 2)), b=(kx, kz), live=True, bearing=None)
    return made


def node():
    """Where the Training machine's line leaves bay 2's spoke."""
    return lines()["training"]["a"]


def bearings():
    """The bearing of every line that leaves the ring, live or not, by its place."""
    return {name: line["bearing"] for name, line in lines().items() if line["bearing"] is not None}


def check():
    """A line crosses no ground but its own (and, for a branch, the one it leaves), and stays clear of it by a
    casing's width."""
    made, starts = lines(), dict(forge="training", battery="breaker")
    problems = []
    for name, line in made.items():
        (ax, az), (bx, bz) = line["a"], line["b"]
        for other in MACHINES + FRAMED:
            if other in (name, starts.get(name)):
                continue
            x0, x1, z0, z1 = ground(other)
            for k in range(41):
                x, z = ax + (bx - ax) * k / 40, az + (bz - az) * k / 40
                if x0 - 1.2 < x < x1 + 1.2 and z0 - 1.2 < z < z1 + 1.2:
                    problems.append(f"{name}'s line passes {other}'s ground")
                    break
    return problems


def main():
    for name in MACHINES + FRAMED:
        x0, x1, z0, z1 = ground(name)
        print(f"{name:10s} ground {x0:7.2f} to {x1:7.2f} across, {z0:6.2f} to {z1:6.2f} inward")
    for name, line in lines().items():
        bearing = "" if line["bearing"] is None else f", bearing {line['bearing']:g}"
        length = math.dist(line["a"], line["b"])
        print(f"{name:10s} line {line['a']} to {line['b']}, {length:.1f} long, {'live' if line['live'] else 'no current'}{bearing}")
    print("node", node())
    print("check:", check() or "every line is clear of every other ground")


if __name__ == "__main__":
    main()
