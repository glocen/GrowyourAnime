"""TR22: the base shows its owner (docs/test-requests.md). The showcase: a lit plinth just inside the gate, where one
Voidkin of the owner's stands turning under its Combat Power, seen from the Strip.

A piece of base_kit.py's like the others: on the kit's own atlas, its origin on the floor at its middle, one unit a
stud. The plinth doesn't turn: the builder turns the Voidkin on it.

Not run by itself: base_kit.py takes PIECES into its own.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lantern_row_kit as kit  # noqa: E402

Mesh, Piece = kit.Mesh, kit.Piece
TOP = 1.2                        # where the Voidkin stands, up from the floor
SIDES = 8
FLAT = math.pi / SIDES           # a flat side toward the Strip
LIGHT = ("Show", (0.0, 2.6, 3.2), "#F6FCFF")   # on the Strip's side of the figure, at chest height


def showcase():
    """The showcase's plinth: three eight-sided steps, concrete, steel and bone, a line of light under the top one
    and a ring of light on it round the Voidkin's feet, and four low lamps on the middle step's corners, so the
    figure is lit from below on every side and nothing stands beside it."""
    m = Mesh(None)
    m.lathe([(3.3, 0.4), (3.3, 0.0)], (0, 0, 0), SIDES, "concrete", spin=FLAT)
    m.lathe([(2.85, 0.8), (2.85, 0.4)], (0, 0, 0), SIDES, "steel", spin=FLAT)
    m.lathe([(2.15, 0.92), (2.15, 0.8)], (0, 0, 0), SIDES, "lamp", spin=FLAT, caps=False)   # the line of light under the top
    m.lathe([(2.35, TOP), (2.35, 0.92)], (0, 0, 0), SIDES, "bone", spin=FLAT)
    m.lathe([(1.55, TOP + 0.02), (1.85, TOP + 0.02)], (0, 0, 0), 12, "lamp", caps=False)  # the ring round the feet
    for k in range(4):
        a = math.tau * (k + 0.5) / 4
        x, y = 2.4 * math.cos(a), 2.4 * math.sin(a)
        rot = (0.0, 0.0, a)
        m.box((0.4, 0.4, 0.7), (x, y, 1.15), "girder", rot=rot)
        m.box((0.3, 0.3, 0.2), (x, y, 1.6), "lamp", rot=rot)
    return Piece("Showcase", m, lights=[LIGHT],
                 solid="an eight-sided block, 6.6 across and 1.2 high, or its box",
                 note=f"the Voidkin stands at its middle, {TOP:g} up, and turns there: the plinth doesn't. Its "
                      f"Combat Power sits above the figure. Its light is a PointLight on the Strip's side of the "
                      f"figure, at chest height")


PIECES = {"Showcase": showcase}
