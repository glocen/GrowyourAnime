"""A blockout as plain parts: blocks, wedges and cylinders with a place, two axes and a colour, written as one file the
builder can lay in Studio with stock parts, and drawn with Studio and Blender closed by view.py. Nothing here is an asset.

The frame is a plot's own, as build/handoff/Base/plan.json's: `across` (the plot's +X), `along` (studs out of the front
edge toward the Strip, so everything on the plot is negative) and `up` from the plot's floor. A part gives its centre
(`at`), and its own X and Y axes as unit vectors in that frame (`x`, `y`); its Z is X cross Y. `size` is Roblox's own
Size, along the part's X, Y and Z.

To Roblox, in the plot's frame with front = -deep / 2: a vector (across, along, up) is Vector3.new(across, up, -along),
so a part is CFrame.fromMatrix(Vector3.new(across, floorY + up, front - along), X, Y) with X and Y mapped the same way.
A Cylinder's length is its X. A Wedge is Roblox's own: its tall face is on its +Z, its slope falls toward -Z.
"""
import json
import math
from pathlib import Path

import numpy as np

UP = np.array((0.0, 0.0, 1.0))


def unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def turned(degrees):
    """The unit vector `degrees` anticlockwise from +across, seen from above."""
    a = math.radians(degrees)
    return np.array((math.cos(a), math.sin(a), 0.0))


def euler(rx, ry, rz):
    """Two axes of a plane turned by XYZ angles in degrees (Blender's order)."""
    cx, sx, cy, sy, cz, sz = (f(math.radians(a)) for a in (rx, ry, rz) for f in (math.cos, math.sin))
    r = (np.array(((cz, -sz, 0), (sz, cz, 0), (0, 0, 1))) @ np.array(((cy, 0, sy), (0, 1, 0), (-sy, 0, cy)))
         @ np.array(((1, 0, 0), (0, cx, -sx), (0, sx, cx))))
    return r[:, 0], r[:, 1]


class Parts:
    def __init__(self):
        self.parts, self.lights, self.anchors = [], [], {}

    def part(self, name, shape, size, at, x, y, colour, group, glow=0.0, collide=False, view_only=False):
        x, y = unit(x), unit(y)
        assert abs(float(x @ y)) < 1e-6, name
        self.parts.append(dict(name=name, group=group, shape=shape, size=[float(s) for s in size], at=[float(c) for c in at],
                               x=[float(c) for c in x], y=[float(c) for c in y], colour=colour, glow=float(glow),
                               collide=bool(collide), viewOnly=bool(view_only)))

    # --- the shapes ---------------------------------------------------------------------------------------------------
    def block(self, name, wide, deep, high, at, colour, group, turn=0.0, **more):
        """A block standing level: `wide` along its turn, `deep` across it, its centre at `at`."""
        self.part(name, "Block", (wide, high, deep), at, turned(turn), UP, colour, group, **more)

    def disc(self, name, radius, high, at, colour, group, **more):
        """A round slab lying level, its centre at `at`."""
        self.part(name, "Cylinder", (high, 2 * radius, 2 * radius), at, UP, (1, 0, 0), colour, group, **more)

    def line(self, name, a, b, wide, up, colour, group, high=0.1, **more):
        """A flat strip from a to b (across, along), its middle `up` high."""
        a, b = np.asarray(a, float), np.asarray(b, float)
        run = b - a
        self.part(name, "Block", (float(np.hypot(*run)), high, wide), (*((a + b) / 2), up), (*run, 0.0), UP, colour, group, **more)

    def ring(self, name, radius, wide, high, at, colour, group, plane=((1, 0, 0), (0, 1, 0)), segs=16, arc=(0.0, 360.0), **more):
        """A ring of straight pieces in the plane of two axes: `wide` across the band, `high` along the ring's own axis."""
        e1, e2 = unit(plane[0]), unit(plane[1])
        axis = np.cross(e1, e2)
        step = math.radians(arc[1] - arc[0]) / segs
        length = 2 * (radius + wide / 2) * math.tan(step / 2)
        for k in range(segs):
            a = math.radians(arc[0]) + step * (k + 0.5)
            spot = np.asarray(at, float) + radius * (math.cos(a) * e1 + math.sin(a) * e2)
            self.part(f"{name}{k}", "Block", (length, high, wide), spot, -math.sin(a) * e1 + math.cos(a) * e2, axis, colour, group, **more)

    def blade(self, name, base, axis, x, high, half, thick, colour, group, **more):
        """A pointed slab, two wedges back to back: its foot's middle at `base`, its point `high` along `axis`."""
        axis, x, base = unit(axis), unit(x), np.asarray(base, float)
        z = np.cross(x, axis)
        for tag, side in (("a", 1.0), ("b", -1.0)):
            self.part(f"{name}{tag}", "Wedge", (thick, high, half), base + axis * high / 2 - side * z * half / 2, side * x, axis,
                      colour, group, **more)

    def spire(self, name, foot, high, half, colour, group, turn=0.0, lean=(0.0, 0.0), thick=None, **more):
        """A standing stone with a point: two blades crossed. `lean` is how far its point stands off its foot."""
        axis = unit((lean[0], lean[1], high))
        x = turned(turn)
        x = unit(x - axis * float(x @ axis))
        thick = half * 0.7 if thick is None else thick
        length = float(np.linalg.norm((lean[0], lean[1], high)))
        self.blade(f"{name}X", foot, axis, x, length, half, thick, colour, group, **more)
        self.blade(f"{name}Z", foot, axis, np.cross(x, axis), length, half, thick, colour, group, **more)

    def crystal(self, name, at, radius, up, down, colour, group, turn=0.0, axis=UP, **more):
        """A cut stone hanging in the air: a point over its middle and one under, four blades."""
        axis = unit(axis)
        x = turned(turn)
        x = unit(x - axis * float(x @ axis))
        for tag, way, high in (("Up", axis, up), ("Down", -axis, down)):
            self.blade(f"{name}{tag}X", at, way, x, high, radius, radius * 0.7, colour, group, **more)
            self.blade(f"{name}{tag}Z", at, way, np.cross(x, axis), high, radius, radius * 0.7, colour, group, **more)

    def figure(self, name, at):
        """A person's stand-in, for the pictures only: the game has its own."""
        x, y, z = at
        for tag, size, up in (("Legs", (2, 1, 2), 1.0), ("Body", (4, 1, 2), 3.0), ("Head", (1.2, 1.2, 1.2), 4.6)):
            self.block(f"{name}{tag}", size[0], size[1], size[2], (x, y, z + up), "#E9E2D2", "figure", view_only=True)

    def light(self, name, at, colour, power, reach, group):
        self.lights.append(dict(name=name, group=group, at=[float(c) for c in at], colour=colour, power=float(power), reach=float(reach)))

    # --- out ----------------------------------------------------------------------------------------------------------
    def write(self, path: Path, head: dict):
        laid = [{k: ([round(c, 4) for c in v] if isinstance(v, list) else v) for k, v in p.items() if k != "viewOnly"}
                for p in self.parts if not p["viewOnly"]]
        counts = {}
        for p in laid:
            counts[p["group"]] = counts.get(p["group"], 0) + 1
        body = dict(head, frame=__doc__.split("\n\n")[1].replace("\n", " "), toRoblox=__doc__.split("\n\n")[2].replace("\n", " ").strip(),
                    anchors=self.anchors, lights=self.lights, budget=dict(parts=len(laid), lights=len(self.lights), byGroup=counts),
                    parts=laid)
        path.write_text(json.dumps(body, indent=1), encoding="utf-8", newline="\n")
        return len(laid)


# --- a part's faces, for the view -------------------------------------------------------------------------------------
BLOCK_FACES = ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3))
WEDGE_FACES = ((0, 1, 4, 3), (1, 2, 5, 4), (0, 3, 5, 2), (0, 2, 1), (3, 4, 5))
ROUND = 20


def faces(p):
    """A part's faces as lists of corners, in the plot's frame."""
    at, x, y = (np.array(p[k]) for k in ("at", "x", "y"))
    z = np.cross(x, y)
    hx, hy, hz = (s / 2 for s in p["size"])
    if p["shape"] == "Block":
        corners = [at + sx * hx * x + sy * hy * y + sz * hz * z for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        return [[corners[i] for i in f] for f in BLOCK_FACES]
    if p["shape"] == "Wedge":                                        # low front, low back, high back, on each side
        corners = [at + sx * hx * x + cy * hy * y + cz * hz * z for sx in (-1, 1) for cy, cz in ((-1, -1), (-1, 1), (1, 1))]
        return [[corners[i] for i in f] for f in WEDGE_FACES]
    if p["shape"] == "Cylinder":                                     # its length is its X
        rim = [(math.cos(math.tau * k / ROUND), math.sin(math.tau * k / ROUND)) for k in range(ROUND)]
        low = [at - hx * x + c * hy * y + s * hz * z for c, s in rim]
        top = [at + hx * x + c * hy * y + s * hz * z for c, s in rim]
        sides = [[low[k], low[(k + 1) % ROUND], top[(k + 1) % ROUND], top[k]] for k in range(ROUND)]
        return sides + [low, top]
    raise ValueError(p["shape"])
