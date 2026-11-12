"""Pip's Lantern Burst as a grey block-in on his delivered clip (AR4, delivery 4; the block-in step for an effect).

blender.exe -b --factory-startup --python tools/blender/pip_burst_fx.py -- <out_dir> [A B C ...]

Timing and size only: plain shapes in white and grey, no art. Pip plays his delivered LanternBurst clip, and the effect
hangs on its markers: Heat 8, Send 51, Burst 66, Return 98. A grey stand-in Shade is the target, the lantern stopping a
stud and a half short of its middle; a second stands inside the area; a grey stand-in for the avatar stands where the
player's camera looks past it. Writes one sheet a variant from the player's camera, then the variants side by side from
the side, from the camera the game uses beside an elite, on a bright floor and at 64 px, and the effect's share of the
screen. Needs pip_model.py's output, as pip_clips.py does. Workbench, so no GPU turn.

Shared by every variant, one idea three times (the flame in his lantern, small, then bigger than he is):
- the heat: the flame grows in the cage through the wind-up, fills it by 30 and spills out of it by 45;
- the send: a ring kicks back off the lantern at his cuff, the push that throws him (51 to 57), and the lantern streaks
  out, its trail long while it's fast and gone as it stops (51 to 65);
- the punctuation: a ball of light at the lantern on the Burst frame (66).
The burst, by variant, over the area (a stand-in radius; the area is the builder's):
- A, the bloom: tongues of flame fly out of the lantern level, and swing up to stand round the area's edge as they
  get there; then they lift off and go out.
- B, the flame let out: one flame, the area wide at its foot and twice his height, leaps up out of the lantern, then
  tears off the ground and goes up and out.
- C, the lantern of light: the lantern's own bars spring out to the area's edge and up past twice his height, a lid on
  them and the flame filling them a moment; then the bars break outward and go out.
The lantern goes home spent: its flame is out from the burst until it's home (128), then it relights.

Cameras, as the game frames a fight (Config.Combat.Lead): the lead stands beyond its target, turned Frame (45) degrees
round, so the player's camera, 12.5 studs behind the avatar and looking at its head, sees past the avatar and the target
to Pip's front-left, and the burst is nearer than he is. The avatar faces 26 degrees past its target (LOOKS), so its
body hides none of the fight; "hidden" is the worst case, dead on. Against an elite or a keeper the lead stands beside
it (Beside, 90), and the throw crosses the screen. Field of view 70, the game's, at 16:9; the 64 px row at 50.
The flames are a flame's outline turned round its middle (flame_mesh), the rest plain boxes, a ring and a lid.
Stage directions: right, forward, up, in studs, from where Pip stands; he faces forward and throws forward.
"""
import json
import math
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (camera, render_variants, clamp, out_fast)
import pip_clips as pc  # noqa: E402

CLIP = Path(__file__).resolve().parents[2] / "build" / "handoff" / "Pip" / "clips" / "Pip_LanternBurst.json"
HEAT, SEND, BURST, RETURN, HOME = 8, 51, 66, 98, 128  # the clip's markers, and the frame the lantern is home
MARKS = {"Heat": HEAT, "Send": SEND, "Burst": BURST, "Return": RETURN}
AREA = 5.0                 # the area's radius: a stand-in, the builder's
TARGET = (0.3, 13.5)       # the target's middle: the lantern stops a stud and a half short of it
OTHER = (4.3, 11.5)        # a second Shade, inside the area
BACK, EYE, PITCH = 8.0, 12.5, 14.0  # the avatar from the target, the camera behind the avatar, and its tilt down
# Each camera: the way it looks (degrees round from right, Pip's stage) and how far the avatar faces past its target.
# 26 is the game's own turn for a keeper's ring (Config.Combat.Keeper.Turn): the avatar's body hides none of the fight.
# "hidden" is the worst case, the avatar facing its target dead on: its body and the target's hide the burst's middle.
LOOKS = {"fight": (-45.0, 26.0), "beside": (0.0, 26.0), "hidden": (-45.0, 0.0)}
PETALS, BARS = 7, 6
SHADES = {"white": (0.93, 0.93, 0.93), "mid": (0.6, 0.6, 0.6)}
SHEET = (8, 30, 45, 51, 53, 56, 60, 66, 67, 69, 72, 76, 81, 88, 98, 128)
STRIP = (51, 55, 66, 67, 69, 72, 76, 82, 90)
SHARE = (66, 67, 68, 70, 72, 76, 80, 86)
NAMES = {f: name for name, f in MARKS.items()}
UP = Vector((0.0, 0.0, 1.0))


def smooth(u):
    u = hx.clamp(u)
    return u * u * (3 - 2 * u)


def toward(direction):
    """The turn that points a shape's own up along `direction`."""
    return UP.rotation_difference(direction.normalized())


def staged(name):
    """A camera's way of looking, and where the avatar stands for it."""
    heading, turn = LOOKS[name.removesuffix("50")]
    h, g = math.radians(heading), math.radians(heading + turn)
    return Vector((math.cos(h), math.sin(h))), Vector(TARGET) - Vector((math.cos(g), math.sin(g))) * BACK


def flame_mesh():
    """A flame's outline turned round its middle: a stud tall about its centre and two across at its belly, a foot a
    little narrower than the belly, then a long taper to the tip."""
    rings, around = 16, 24
    verts, faces = [], []
    for i in range(rings):
        h = 0.97 * i / (rings - 1)
        r = 0.78 + 0.22 * math.sin(h / 0.22 * math.pi / 2) if h <= 0.22 else (1 - (h - 0.22) / 0.78) ** 1.5
        verts += [(r * math.cos(2 * math.pi * j / around), r * math.sin(2 * math.pi * j / around), h - 0.5) for j in range(around)]
    tip, foot = len(verts), len(verts) + 1
    verts += [(0.0, 0.0, 0.5), (0.0, 0.0, -0.5)]
    for i in range(rings - 1):
        for j in range(around):
            a, b = i * around + j, i * around + (j + 1) % around
            faces.append((a, b, b + around, a + around))
    last = (rings - 1) * around
    faces += [(last + j, last + (j + 1) % around, tip) for j in range(around)]
    faces += [((j + 1) % around, j, foot) for j in range(around)]
    mesh = bpy.data.meshes.new("Fx.Flame")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    return mesh


# --- the shared beats ------------------------------------------------------------------------------------------------

def heat(f):
    """The flame in the cage, as a box at the lantern: its side, or 0 while it's out."""
    if f < HEAT:
        return 0.35
    if f < 30:
        return 0.35 + 0.35 * smooth((f - HEAT) / (30 - HEAT))
    if f < 45:
        return 0.7 + 0.45 * (f - 30) / 15
    if f < SEND:
        return 1.15 + 0.1 * (f - 45) / (SEND - 45)
    if f < BURST:
        return 1.1
    if f < HOME:
        return 0.0  # spent: it goes home empty
    return 0.35 * hx.clamp((f - HOME + 1) / 4)


def kick(stage, f):
    """The push that throws him: a ring off the lantern at the cuff, pushed back toward him as it opens."""
    t = f - SEND
    if not 0 <= t <= 6:
        return []
    start, line = stage.lamp[SEND], stage.lamp[BURST] - stage.lamp[SEND]
    r = 0.7 + 2.6 * hx.out_fast(t / 6)
    thick = 1.4 * (1 - hx.clamp((t - 2) / 5))
    centre = start - line.normalized() * 0.9 * hx.out_fast(t / 6)
    return [("ring", "mid", centre, (r, r, max(0.2, thick)), toward(line))]


def trail(stage, f):
    """The lantern's streak: from where it is back to where it was four frames ago."""
    t = f - SEND
    if not 1 <= t < BURST - SEND:
        return []
    head, tail = stage.lamp[f], stage.lamp[max(SEND, f - 4)]
    span = head - tail
    if span.length < 0.1:
        return []
    w = 0.95 * (1 - 0.5 * t / (BURST - SEND))
    return [("box", "white", (head + tail) / 2, (w, w, span.length), toward(span))]


# --- the burst, by variant -------------------------------------------------------------------------------------------

def bloom(stage, t):
    """A: tongues out of the lantern, level, standing up round the area's edge as they get there, then lifting off."""
    out, at = [], stage.lamp[BURST]
    for angle, reach, lag in stage.petals:
        a = t - lag
        if a < 1:
            continue
        go = hx.out_fast(a / 5)
        rim = Vector((math.cos(angle), math.sin(angle), 0.0))
        base = at + rim * (0.4 + (AREA * reach - 0.4) * go)
        base.z = at.z + (0.6 - at.z) * go + 0.22 * max(0.0, a - 11) ** 1.3
        pitch = math.radians(90 * smooth((a - 1) / 7))
        length = (2.2 + 2.6 * hx.out_fast(a / 7)) * (1 - hx.clamp((a - 12) / 12) ** 1.5)
        width = 1.4 * (1 - 0.55 * hx.clamp((a - 4) / 14))
        if length < 0.15:
            continue
        axis = rim * math.cos(pitch) + UP * math.sin(pitch)
        out.append(("flame", "white", base + axis * (length / 2), (width / 2, width / 2, length), toward(axis)))
    return out


def let_out(stage, t):
    """B: one flame, the area wide at its foot, leaping up from the lantern, then tearing off the ground."""
    at = stage.lamp[BURST]
    rb = AREA * hx.out_fast(t / 4) * (1 - 0.75 * hx.clamp((t - 6) / 18))
    h = 13.0 * hx.out_fast(t / 6) * (1 - 0.45 * hx.clamp((t - 12) / 14))
    gone = 1 - hx.clamp((t - 20) / 6)
    rb, h = rb * gone, h * gone
    if rb < 0.08 or h < 0.2:
        return []
    foot = at.z - 1.0 + (0.2 - at.z + 1.0) * hx.clamp(t / 3) + 7.0 * hx.clamp((t - 7) / 19) ** 1.6
    return [("flame", "white", Vector((at.x, at.y, foot + h / 2)), (rb, rb, h), Quaternion())]


def lantern(stage, t):
    """C: the lantern's bars sprung out to the area's edge and up, a lid on them, the flame filling them a moment; then
    the bars break outward."""
    out, at = [], stage.lamp[BURST]
    opened, broken = hx.out_fast(t / 5), hx.clamp((t - 10) / 14)
    radius = (0.45 + (0.85 * AREA - 0.45) * opened) * (1 + 0.5 * broken)
    top = at.z + 0.9 + (9.5 - at.z - 0.9) * opened + 1.5 * broken
    bottom = max(0.2, (at.z - 0.9) * (1 - opened))
    width = 0.55 * (1 - broken)
    if width > 0.04:
        for i in range(BARS):
            angle = stage.bar0 + i * 2 * math.pi / BARS + 0.012 * t
            centre = Vector((at.x + radius * math.cos(angle), at.y + radius * math.sin(angle), (top + bottom) / 2))
            out.append(("box", "white", centre, (width, width, top - bottom), Quaternion(UP, angle)))
    if t <= 14:
        lid = 2.6 * opened * (1 - hx.clamp((t - 8) / 6))
        if lid > 0.1:
            r = radius * 1.08
            out.append(("lid", "white", Vector((at.x, at.y, top + lid / 2)), (r, r, lid), Quaternion(UP, stage.bar0)))
    if 2 <= t <= 12:
        s = math.sin(math.pi * (t - 2) / 10)
        rf, hf = radius * 0.55 * s, 7.5 * s
        if rf > 0.08:
            out.append(("flame", "mid", Vector((at.x, at.y, 0.2 + hf / 2)), (rf, rf, hf), Quaternion()))
    return out


VARIANTS = {"A": ("the bloom", bloom), "B": ("the flame let out", let_out), "C": ("the lantern of light", lantern)}


def layout(stage, variant, f):
    out = kick(stage, f) + trail(stage, f)
    t = f - BURST
    if t == 0:
        out.append(("ball", "white", stage.lamp[BURST], (1.7, 1.7, 1.7), Quaternion()))
    elif t > 0:
        out += VARIANTS[variant][1](stage, t)
    return out


# --- the stage -------------------------------------------------------------------------------------------------------

class Stage:
    """The shapes the block-in is drawn with, set on every frame from the variant's layout; and the stand-ins."""

    def __init__(self, scene, rig, frames):
        self.variant, self.show = "A", True
        self.materials = {shade: r6.flat_material(f"Fx.{shade}", colour) for shade, colour in SHADES.items()}
        self.pool = {}
        # where the lantern is on every frame, read once from the keyed clip
        self.lamp = []
        for f in range(frames):
            scene.frame_set(f)
            r6._refresh()
            self.lamp.append(rig.parts[pc.LAMP].matrix_world.translation.copy())
        at = self.lamp[BURST]
        print(f"the lantern: sent from {tuple(round(v, 2) for v in self.lamp[SEND])}, "
              f"bursts at {tuple(round(v, 2) for v in at)}, home at {tuple(round(v, 2) for v in self.lamp[HOME])}")
        rng = random.Random(11)
        turn = rng.uniform(0, 2 * math.pi)
        self.petals = [(turn + i * 2 * math.pi / PETALS + rng.uniform(-0.2, 0.2), rng.uniform(0.85, 1.0), rng.randint(0, 1))
                       for i in range(PETALS)]
        self.bar0 = rng.uniform(0, math.pi / 3)
        self.flame = self.make("box", "white")
        shade = r6.flat_material("Fx.Shade", (0.30, 0.28, 0.33))
        grey = r6.flat_material("Fx.Avatar", (0.42, 0.42, 0.45))
        for name, (x, y) in (("Target", TARGET), ("Other", OTHER)):
            self.figure(name, (x, y), 0.0, shade, (("Coat", (2.6, 1.4, 4.4), 2.4), ("Mask", (1.3, 1.1, 1.2), 5.2)))
        self.avatar = self.figure("Avatar", (0, 0), 0.0, grey, (("Legs", (2.0, 1.0, 2.0), 1.0), ("Body", (4.0, 1.0, 2.0), 3.0),
                                                              ("Head", (1.2, 1.2, 1.2), 4.6)))
        self.avatar_boxes = list(self.avatar.children)
        bpy.app.handlers.frame_change_pre.append(self.set)

    @staticmethod
    def figure(name, at, turn, material, parts):
        root = r6._empty(f"Fx.{name}", None, Matrix.Identity(4), 0.2)
        root.location, root.rotation_mode = (at[0], at[1], 0.0), "XYZ"
        root.rotation_euler = (0.0, 0.0, turn)
        for part, size, z in parts:
            box = bl.box(f"Fx.{name}.{part}", size, material)
            box.parent, box.location = root, (0, 0, z)
        return root

    def make(self, kind, shade):
        if kind == "box":
            obj = bl.box(f"Fx.{shade}", (1, 1, 1), self.materials[shade])
        elif kind == "flame":
            obj = bpy.data.objects.new(f"Fx.Flame.{shade}", flame_mesh())
            bpy.context.scene.collection.objects.link(obj)
            obj.data.materials.append(self.materials[shade])
        else:
            if kind == "ball":
                bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0)
            elif kind == "ring":
                bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.08, major_segments=40, minor_segments=8)
            else:  # a cone a stud tall about its middle, round for a flame, six-sided for the lid
                bpy.ops.mesh.primitive_cone_add(vertices=24 if kind == "cone" else 6, radius1=1.0, radius2=0.0, depth=1.0)
            obj = bpy.context.active_object
            obj.data.materials.append(self.materials[shade])
        obj.display.show_shadows = False
        obj.rotation_mode = "QUATERNION"
        obj.hide_render = True
        return obj

    def place_avatar(self, scene):
        """The avatar stands where the camera being drawn from puts it, facing the way the camera looks."""
        name = scene.camera.name if scene.camera else ""
        for box in self.avatar_boxes:
            box.hide_render = name not in ("fight", "fight50", "beside", "hidden")
        if name in ("fight", "fight50", "beside", "hidden"):
            look, spot = staged(name)
            self.avatar.location = (spot.x, spot.y, 0.0)
            self.avatar.rotation_euler = (0.0, 0.0, math.atan2(look.y, look.x) - math.pi / 2)

    def set(self, scene, *_):
        f = scene.frame_current
        self.place_avatar(scene)
        side = heat(f) if self.show else 0.0
        self.flame.hide_render = side <= 0.0
        if f < len(self.lamp) and side > 0.0:
            self.flame.location, self.flame.scale = self.lamp[f], (side, side, side * 1.3)
        used = {}
        for kind, shade, centre, size, turn in (layout(self, self.variant, f) if self.show else []):
            key = (kind, shade)
            pool = self.pool.setdefault(key, [])
            n = used.get(key, 0)
            if n == len(pool):
                pool.append(self.make(kind, shade))
            obj = pool[n]
            used[key] = n + 1
            obj.location, obj.scale, obj.rotation_quaternion, obj.hide_render = centre, size, turn, False
        for key, pool in self.pool.items():
            for obj in pool[used.get(key, 0):]:
                obj.hide_render = True


def key(rig):
    data = json.loads(CLIP.read_text())
    for frame in data["Frames"]:
        f = round(frame["T"] * data["Fps"])
        for part, pose in frame["Poses"].items():
            joint = rig.joints.get(part)
            if joint is not None:
                joint.matrix_basis = r6.to_blender(r6.cframe(pose))
                joint.keyframe_insert("location", frame=f)
                joint.keyframe_insert("rotation_quaternion", frame=f)
    marks = {m["Name"]: round(m["T"] * data["Fps"]) for m in data.get("Markers", [])}
    if marks != MARKS:
        raise SystemExit(f"the clip's markers are {marks}, not {MARKS}")
    return len(data["Frames"])


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def share(scene, stage, camera, wanted, path):
    """The effect's share of the player's screen: pixels that change when it's drawn, at the game's field of view."""
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = 480, 270
    scene.render.use_stamp = False
    table = {}
    for key_ in wanted:
        stage.variant, table[key_] = key_, {}
        for f in SHARE:
            pixels = []
            for show in (True, False):
                stage.show = show
                scene.frame_set(f)
                scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                image = bpy.data.images.load(str(path))
                pixels.append(np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)[:, :3])
                bpy.data.images.remove(image)
            changed = np.abs(pixels[0] - pixels[1]).max(axis=1) > 0.03
            table[key_][f] = round(float(changed.mean()), 4)
        stage.show = True
    path.unlink()
    return table


def size_of(stage, variant, f):
    """How tall and how wide the effect stands on a frame, roughly: its top, and its reach from the lantern."""
    top, reach, at = 0.0, 0.0, stage.lamp[BURST]
    for kind, _, centre, size, _ in layout(stage, variant, f):
        half = max(size) / 2 if kind in ("box", "ring") else size[2] / 2
        top = max(top, centre.z + half)
        across = max(size[0], size[1]) if kind in ("cone", "lid", "ball", "flame") else 0.0
        reach = max(reach, (centre.xy - at.xy).length + across)
    return round(top, 2), round(reach, 2)


def main():
    out = bl.out_dir()
    wanted = [a for a in sys.argv[sys.argv.index("--") + 2:] if a in VARIANTS] or list(VARIANTS)
    scene, rig, costume, undress, feet, ctl, motors = pc.build()
    frames = key(rig)
    print(f"LanternBurst: {frames} frames, the markers at {MARKS}")
    stage = Stage(scene, rig, frames)
    cameras = {}
    for name in ("fight", "fight50", "beside", "hidden"):  # behind the avatar, looking at its head (the game's camera)
        look, spot = staged(name)
        azimuth = math.degrees(math.atan2(-look.x, -look.y))
        cameras[name] = hx.camera(scene, name, azimuth, PITCH, EYE / math.cos(math.radians(PITCH)), (spot.x, spot.y, 4.5),
                                  50.0 if name == "fight50" else 70.0)
        eye = cameras[name].location
        print(f"{name}: Pip seen {math.degrees(math.atan2(-eye.x, eye.y)):.0f} degrees off his front, from "
              f"{Vector((eye.x, eye.y)).length:.1f} studs; the lantern's stop {(eye - stage.lamp[BURST]).length:.1f} from the camera")
    fight, fight50, beside, hidden = (cameras[n] for n in ("fight", "fight50", "beside", "hidden"))
    side = hx.camera(scene, "side", 90.0, 6.0, 34.0, (0.3, 7.0, 4.5), 36.0)
    bpy.data.objects["Floor"].scale *= 4  # past the camera's edges
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    for key_ in wanted:
        stage.variant = key_
        scene.render.resolution_x, scene.render.resolution_y = 480, 270
        title = f"{key_}, {VARIANTS[key_][0]}: "
        shots = [(fight, f, title + label(f) if f == SHEET[0] else label(f)) for f in SHEET]
        print(f"wrote {r6.render_shots(scene, shots, out / f'pipburst_{key_}.png', columns=4)}")
    tile = (256, 144)
    shots = [(side, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'pipburst_side.png', len(STRIP), tile)}")
    shots = [(beside, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'pipburst_beside.png', len(STRIP), tile)}")
    shots = [(hidden, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'pipburst_hidden.png', len(STRIP), tile)}")
    shots = [(fight, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'pipburst_bright.png', len(STRIP), tile)}")
    floor.diffuse_color = dusk
    shots = [(fight50, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'pipburst_64.png', len(STRIP), (75, 64))}")
    table = {
        "markers": MARKS, "area": AREA, "target": TARGET,
        "lantern": {name: [round(v, 2) for v in stage.lamp[f]] for name, f in {**MARKS, "Home": HOME}.items()},
        "share": share(scene, stage, fight, wanted, out / "share.png"),
        "size": {k: {f: size_of(stage, k, f) for f in SHARE} for k in wanted},
    }
    (out / "pipburst.json").write_text(json.dumps(table, indent=1))
    print(json.dumps(table["share"]), json.dumps(table["size"]))


if __name__ == "__main__":
    main()
