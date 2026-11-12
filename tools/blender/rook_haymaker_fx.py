"""Haymaker's effect as a grey block-in beside Rook's clip (AR1, delivery 4; the ga-action skill, step 3).

blender.exe -b --factory-startup --python tools/blender/rook_haymaker_fx.py -- <out_dir> [A B ...]

Timing and size only: plain boxes in two greys, a stand-in body that takes the blow, no art. One sheet a variant
(the player's assumed camera over the side view), one sheet of the variants on a bright floor, and one at 64 px.
Needs rook_model.py's output, as rook_clips.py does. Workbench, so no GPU turn.

The hero shape is the ram's own face, a square bracket standing on the ground across the hit's line:
- A, the corridor: five brackets punched up one after another down the line, each larger, fast then slowing. They
  stay where they were laid and leave from the near end.
- B, the thrown frame: one bracket leaves the knuckles and flies down the line, growing, stretched along its travel
  while it is fast.
- C, the thrown frame and its wake: B, and where it passed it leaves A's brackets standing, thinner and greyer.
All share the charge (one square drawn tight onto the ram's face through the hold), the punctuation (the same square
thrown open round the ram for the strike's frame and the next), and two lines scored on the floor under the brackets'
feet. A bracket leans the way it goes, for whoever watches from the side.
Stage directions as rook_clips.py: right, forward, up, in studs, from where he stands.
"""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_clips as rc  # noqa: E402

WIND, HELD, STRIKE, SHOCK = 34, 52, 57, 58  # the clip's own frames: the hold's two ends, and its markers
REACH = 8.0  # studs the shock runs from the knuckles: a stand-in until the action's Config holds its range
TARGET = (0.0, 7.0)  # where the stand-in body stands
LIFE = 20  # frames a bracket lives
POPS = ((0.12, 58), (0.34, 59), (0.56, 60), (0.78, 62), (1.0, 65))  # A: how far down the line, and its frame
FLY = 10  # B: frames the bracket takes down the line
WAKE = (0.12, 0.27, 0.42)  # C: where the wake stands. It stops short of the target, at half the hero's height (research)
KNOCK = 60  # the frame the shock reaches the body
KNUCKLES = (0.22, 0.06, -1.7825)  # rook_clips.KNUCKLES in the arm object's own frame
LEAN = math.radians(16)  # a bracket leans the way it goes, so a watcher at the side reads the direction
SHADES = {"white": (0.93, 0.93, 0.93), "mid": (0.6, 0.6, 0.6), "dark": (0.02, 0.02, 0.025)}
SHEET = (40, 52, 56, 57, 58, 59, 60, 62, 64, 68, 74, 82)
BURST = (57, 58, 59, 60, 62, 65, 70, 78)
NAMES = {34: "wound", 52: "held", 57: "Strike", 58: "Shock", 63: "Step", 70: "Vent"}


def clamp(u):
    return min(1.0, max(0.0, u))


def out_fast(u):
    """Snaps out and settles: most of the way in the first third."""
    return 1 - (1 - clamp(u)) ** 3


class Line:
    """The hit's line on the floor, from under the knuckles at the strike to the target and on."""

    def __init__(self, knuckles: Vector):
        self.x, self.y, self.z = knuckles

    def at(self, s):
        along = REACH * s
        to_target = TARGET[1] - self.y
        return self.x + (TARGET[0] - self.x) * clamp(along / to_target), self.y + along

    @staticmethod
    def size(s):
        """A bracket's width, height and bar, by how far down the line it stands: the body fits inside from halfway."""
        return 2.2 + 3.6 * s, 2.0 + 3.4 * s, 0.75 + 0.5 * s


def bracket(out, x, y, w, h, bar, depth=0.3, lift=0.0, shades=("dark", "white")):
    """Two posts and a lintel across the line, leaning the way it goes. The dark one is larger and stands at the far
    half, as the light one's rim from behind."""
    def bar_at(shade, bx, z, size):
        out.append((shade, (bx, y + back + z * math.sin(LEAN), z * math.cos(LEAN)), size, (-LEAN, 0.0)))

    for shade in shades:
        grow, back, deep = (0.16, depth * 0.25 + 0.06, depth * 0.5) if shade == "dark" else (0.0, 0.0, depth)
        if h - lift > 0.05:
            for side in (-1, 1):
                bar_at(shade, x + side * w / 2, lift + (h - lift) / 2, (bar + grow, deep, h - lift + grow))
        bar_at(shade, x, h, (w + bar + grow, deep, bar + grow))


def scored(out, line, tail, front, pieces=6):
    """The two lines the brackets' feet score on the floor, from `tail` to `front` down the line."""
    if front - tail < 0.01:
        return
    for i in range(pieces):
        a, b = tail + (front - tail) * i / pieces, tail + (front - tail) * (i + 1) / pieces
        for side in (-1, 1):
            (xa, ya), (xb, yb) = line.at(a), line.at(b)
            xa, xb = xa + side * line.size(a)[0] / 2, xb + side * line.size(b)[0] / 2
            length, yaw = math.hypot(xb - xa, yb - ya), math.atan2(-(xb - xa), yb - ya)
            centre = ((xa + xb) / 2, (ya + yb) / 2)
            out.append(("dark", (*centre, 0.02), (0.7, length, 0.04), (0.0, yaw)))
            out.append(("white", (*centre, 0.05), (0.4, length, 0.04), (0.0, yaw)))


def shared(out, line, f):
    """The punctuation: the charge's square thrown open round the ram's face, thick, for the strike's frame and the
    next. Larger than the ram, since the ram hides its own face from the camera behind him."""
    if f in (STRIKE, SHOCK):
        side, bar = (3.0, 0.8) if f == STRIKE else (3.7, 0.45)
        for shade, grow, back in (("dark", 0.16, 0.12), ("white", 0.0, 0.0)):
            for sign in (-1, 1):
                out.append((shade, (line.x, line.y + 0.3 + back, line.z + sign * side / 2), (side + bar + grow, 0.1, bar + grow), (0.0, 0.0)))
                out.append((shade, (line.x + sign * side / 2, line.y + 0.3 + back, line.z), (bar + grow, 0.1, side + bar + grow), (0.0, 0.0)))


def corridor(line, f):
    out = []
    shared(out, line, f)
    for s, pop in POPS:
        age = f - pop
        (x, y), (w, h, bar) = line.at(s), line.size(s)
        if age == -1:  # the dark runs a frame ahead of the white
            bracket(out, x, y, w, h * 0.7, bar, shades=("dark",))
        elif 0 <= age < LIFE:
            opens = 1.08 if age == 0 else 1.0 + 0.06 * age / LIFE  # it never stands still: it opens to its last frame
            leaves = clamp((age - 8) / (LIFE - 8)) ** 2
            bracket(out, x, y, w * opens, h * opens, bar * (1 - leaves), lift=h * 0.5 * leaves)
    if f >= SHOCK:
        tail = clamp((f - 66) / 19)
        scored(out, line, tail * tail * (3 - 2 * tail), out_fast((f - SHOCK) / 7))
    return out


def far(frame):
    """How far down the line the thrown bracket is: it never quite stops."""
    return out_fast((frame - SHOCK) / FLY) + max(0, frame - SHOCK - FLY) * 0.004


def thrown(line, f):
    out = []
    shared(out, line, f)
    if SHOCK < f <= 80:
        s, leaves = far(f), clamp((f - SHOCK - FLY) / 12) ** 2
        (x, y), (w, h, bar) = line.at(s), line.size(s)
        depth = max(0.3, 0.7 * REACH * (s - far(f - 1)))  # stretched along its travel while it is fast
        opens = 1.0 + 0.06 * leaves
        bracket(out, x, y - depth / 2, w * opens, h * opens, (bar + 0.1) * (1 - leaves), depth=depth, lift=h * 0.5 * leaves)
    if f >= SHOCK:
        tail = clamp((f - 64) / 20)
        scored(out, line, tail * tail * (3 - 2 * tail), clamp(out_fast((f - SHOCK) / FLY)))
    return out


def wake(line, f):
    out = thrown(line, f)
    for s in WAKE:
        age = f - next(frame for frame in range(SHOCK, SHOCK + 40) if far(frame) >= s) - 1
        if 0 <= age < 14:
            (x, y), (w, h, bar) = line.at(s), line.size(s)
            leaves = clamp((age - 4) / 10) ** 2
            bracket(out, x, y, w * (1 + 0.05 * age / 14), h * 0.5 * (1 + 0.05 * age / 14), bar * 0.5 * (1 - leaves),
                    lift=h * 0.25 * leaves, shades=("mid",))
    return out


VARIANTS = {"A": ("the corridor", corridor), "B": ("the thrown frame", thrown), "C": ("the thrown frame and its wake", wake)}


class Stage:
    """The boxes the block-in is drawn with, set on every frame from the variant's layout."""

    def __init__(self, scene, rig, line):
        self.line, self.variant = line, "A"
        self.pool = {shade: [] for shade in SHADES}
        self.materials = {shade: r6.flat_material(f"Fx.{shade}", colour) for shade, colour in SHADES.items()}
        grey = r6.flat_material("Fx.Body", (0.36, 0.36, 0.38))
        self.body = r6._empty("Fx.Body", None, Matrix.Identity(4), 0.2)
        for name, size, at in (("Legs", (1.9, 0.95, 2.0), 1.0), ("Chest", (2.0, 1.0, 2.0), 3.0), ("Head", (1.2, 1.2, 1.1), 4.6),
                               ("Arms", (4.0, 0.95, 0.9), 3.5)):
            box = bl.box(f"Fx.Body.{name}", size, grey)
            box.parent, box.location = self.body, (0, 0, at)
        self.ring = [self.box("white") for _ in range(4)]
        arm = rig.parts["Right Arm"]
        for bar in self.ring:
            bar.parent = arm
        bpy.app.handlers.frame_change_pre.append(self.set)

    def box(self, shade):
        obj = bl.box(f"Fx.{shade}", (1, 1, 1), self.materials[shade])
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    def set(self, scene, *_):
        f = scene.frame_current
        used = {shade: 0 for shade in SHADES}
        for shade, centre, size, (lean, yaw) in VARIANTS[self.variant][1](self.line, f):
            if used[shade] == len(self.pool[shade]):
                self.pool[shade].append(self.box(shade))
            obj = self.pool[shade][used[shade]]
            used[shade] += 1
            obj.location, obj.scale, obj.rotation_euler, obj.hide_render = centre, size, (lean, 0, yaw), False
        for shade, n in used.items():
            for obj in self.pool[shade][n:]:
                obj.hide_render = True
        # The charge: one square drawn tight onto the ram's face through the hold, cut at the strike.
        drawn = WIND - 6 <= f < STRIKE
        side = 2.9 - 1.1 * clamp((f - WIND + 6) / (HELD - WIND + 6)) ** 2 - 0.1 * clamp((f - HELD) / 4)
        for i, bar in enumerate(self.ring):
            across, sign = i < 2, 1 if i % 2 else -1
            bar.hide_render = not drawn
            bar.location = Vector(KNUCKLES) + Vector((0, sign * side / 2, 0) if across else (sign * side / 2, 0, 0))
            bar.scale = (side + 0.2, 0.2, 0.2) if across else (0.2, side + 0.2, 0.2)
        self.struck(f)

    def struck(self, f):
        """The stand-in body takes it: thrown back down the line, leaning away, then upright again."""
        go = clamp((f - KNOCK) / 18)
        self.body.location = (TARGET[0], TARGET[1] + 3.5 * out_fast(go) * (f >= KNOCK), 0)
        self.body.rotation_mode = "XYZ"
        self.body.rotation_euler = (-math.radians(20) * math.sin(math.pi * go) ** 0.7 if 0 < go < 1 else 0, 0, 0)


def camera(scene, name, azimuth, elevation, distance, focus, fov):
    a, e = math.radians(azimuth), math.radians(elevation)
    eye = Vector(focus) + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * distance
    return r6.fixed_camera(scene, r6.point_to_roblox(eye), r6.point_to_roblox(Vector(focus)), fov, name)


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def main():
    out = bl.out_dir()
    wanted = [a for a in sys.argv[sys.argv.index("--") + 2:] if a in VARIANTS] or list(VARIANTS)
    scene, rig, costume, undress, feet = rc.build()
    take = rc.Take(rig, feet, "Haymaker", 0)
    rc.haymaker(take)
    rc.ground(rig, feet, [take])
    scene.frame_set(STRIKE)
    line = Line(rig.parts["Right Arm"].matrix_world @ Vector(KNUCKLES))
    print(f"the knuckles at the strike: {line.x:.2f} right, {line.y:.2f} forward, {line.z:.2f} up")
    stage = Stage(scene, rig, line)
    game = camera(scene, "game", rc.GAME[0], rc.GAME[1], 15.5, (0.8, 4.2, 2.5), 46.0)
    side = camera(scene, "side", 90.0, 6.0, 25.0, (0.0, 5.0, 2.6), 30.0)
    floor = bpy.data.objects["Floor"].data.materials[0]
    for key in wanted:
        stage.variant = key
        scene.render.resolution_x, scene.render.resolution_y = 495, 340
        shots = [(game, f, f"{key}, {VARIANTS[key][0]}: {label(f)}" if f == SHEET[0] else label(f)) for f in SHEET]
        print(f"wrote {r6.render_shots(scene, shots, out / f'blockin_{key}.png', columns=4)}")
    shots = [(side, f, f"{key} {f}", key) for key in wanted for f in BURST]
    print(f"wrote {render_variants(scene, stage, shots, out / 'blockin_side.png', len(BURST), (247, 130))}")
    shots = [(game, f, f"{key} {f}", key) for key in wanted for f in BURST]
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    print(f"wrote {render_variants(scene, stage, shots, out / 'blockin_bright.png', len(BURST), (247, 170))}")
    floor.diffuse_color = (0.16, 0.14, 0.17, 1)
    print(f"wrote {render_variants(scene, stage, shots, out / 'blockin_64.png', len(BURST), (93, 64))}")


def render_variants(scene, stage, shots, path, columns, size):
    """r6.render_shots a variant at a time, joined into one sheet by rows."""
    import numpy as np
    scene.render.resolution_x, scene.render.resolution_y = size
    rows = []
    for key in dict.fromkeys(shot[3] for shot in shots):
        stage.variant = key
        row = path.with_name(f"{path.stem}_{key}.png")
        r6.render_shots(scene, [shot[:3] for shot in shots if shot[3] == key], row, columns=columns)
        image = bpy.data.images.load(str(row))
        w, h = image.size
        rows.append(np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4))
        bpy.data.images.remove(image)
        row.unlink()
    sheet = np.concatenate(rows[::-1], axis=0)  # Blender images start at the bottom row
    image = bpy.data.images.new(path.stem, sheet.shape[1], sheet.shape[0], alpha=True)
    image.pixels = sheet.ravel()
    image.filepath_raw, image.file_format = str(path), "PNG"
    image.save()
    return path


if __name__ == "__main__":
    main()
