"""The Shade's burst into light and paper as a grey block-in on its Burst clip (AR2; the block-in step for an effect).

blender.exe -b --factory-startup --python tools/blender/shade_burst_fx.py -- <out_dir> [A B C ...]

Timing and size only: plain boxes in white and grey, no art. The Shade plays its delivered Burst clip, and the game
hides its body, mask and ties at the clip's `Burst` marker (27), where the effect takes over from the collar, where the
face was (AR2, section 3). A grey stand-in for the lead stands 7 studs in front of it, between it and the player's
camera. Writes one sheet a variant from the player's camera, then the variants side by side from the side, on a bright
floor and at 64 px. Needs shade_model.py's output, as shade_clips.py does. Workbench, so no GPU turn.

Shared by every variant:
- the charge: a light swelling in the collar's opening while the mask tips back, 18 to 26;
- the punctuation: the coat lit whole for the Burst frame, a box in its outline; from the next frame it is scraps.
The release, by variant:
- A, the flame let go: the light leaps out of the collar and up, stretched along its travel while it's fast, and
  goes out high. The scraps are thrown out and tumble down, gone before the floor.
- B, the lantern bursts: the light blows out round the body as one swelling ball, and the scraps fly out of it every
  way. The nearest to the white ball the game plays now.
- C, the sky lantern: A's flame, and the scraps rise after it in a loose turning column, smaller as they climb.
  Nothing falls.
Stage directions: right, forward, up, in studs, from where the Shade stands; it faces forward, at the lead.
"""
import json
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (camera, render_variants, clamp, out_fast)
import shade_clips as sc  # noqa: E402

CLIP = Path(__file__).resolve().parents[2] / "build" / "handoff" / "Shade" / "clips" / "Shade_Burst.json"
STRUCK, LETGO, BURST = 4, 20, 27  # the clip's own frames: struck, the mask leads, and its marker
CHARGE = 18                       # the collar's light starts to swell
COLLAR = (0.0, 0.0, 1.5)          # the collar's opening on the Torso, in its own frame (studs; up is z)
COAT = ((0.0, 0.0, -0.38), (2.6, 1.4, 4.0))  # the coat's outline on the Torso: centre and size
LEAD = (0.0, 7.0)                 # where the stand-in lead stands
RISE, FLY, BACK = 7.0, 8, math.radians(8)  # the flame: how high, in how many frames for most of it, leaning away
OUT = 14                                    # the flame is out this many frames after the Burst
SCRAPS, SCRAP = 10, (1.0, 0.06, 0.75)  # the coat in ten pieces: each large enough to read at the player's distance
SHADES = {"white": (0.93, 0.93, 0.93), "mid": (0.6, 0.6, 0.6), "dark": (0.02, 0.02, 0.025)}
SHEET = (4, 18, 22, 25, 27, 28, 29, 31, 34, 38, 44, 52)
STRIP = (25, 27, 28, 29, 31, 34, 40, 48)
NAMES = {STRUCK: "struck", LETGO: "lets go", BURST: "Burst"}


def flame(origin, t):
    """The light let go, `t` frames after the Burst: a tall box whose head leads, stretched while it's fast."""
    if not 1 <= t <= OUT:
        return []

    def height(t):  # it never hangs: past its leap it still climbs
        return RISE * hx.out_fast(t / FLY) + max(0, t - FLY) * 0.2

    up = height(t)
    length = max(1.2, 1.5 * (up - height(t - 1)))
    width = 1.3 * (1 - 0.75 * hx.clamp((t - 3) / 9)) * (1 - hx.clamp((t - 9) / (OUT - 9)) ** 2)
    if width < 0.04:
        return []
    head = origin + Vector((0.0, -math.tan(BACK) * up, up))
    centre = head - Vector((0.0, -math.sin(BACK), math.cos(BACK))) * (length / 2)
    return [("white", centre, (width, width, length), (BACK, 0.0, 0.0))]


class Scrap:
    def __init__(self, rng, coat):
        (cx, cy, cz), (w, d, h) = coat
        self.start = Vector((cx + rng.uniform(-w / 2, w / 2), cy + rng.uniform(-d / 2, d / 2), cz + rng.uniform(-h / 2, h / 2)))
        self.out = Vector((self.start.x - cx, self.start.y - cy, 0.0)).normalized() if (self.start.xy - Vector((cx, cy))).length > 0.05 else Vector((1, 0, 0))
        self.spin = Vector((rng.uniform(-0.35, 0.35), rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3)))
        self.turn0 = Vector((rng.uniform(0, 3), rng.uniform(0, 3), rng.uniform(0, 3)))
        self.lift, self.lag, self.speed = rng.uniform(0.1, 0.3), rng.randint(1, 6), rng.uniform(0.8, 1.2)
        self.angle0 = math.atan2(self.start.y - cy, self.start.x - cx)
        self.radius0 = (self.start.xy - Vector((cx, cy))).length

    def thrown(self, t, fly=0.28, every_way=False):
        """A and B: thrown out, slowed by the air, pulled down; it shrinks away and is gone before the floor."""
        at = Vector(self.start)
        v = self.out * fly * self.speed + Vector((0.0, 0.0, self.lift))
        if every_way:
            v = Vector((self.out.x, self.out.y, 0.0)) * fly * 1.6 * self.speed + Vector((0.0, 0.0, self.lift + 0.15))
        for _ in range(t):
            at += v
            v = Vector((v.x * 0.9, v.y * 0.9, v.z - 0.025))
        size = 1 - hx.clamp((t - 10) / 14) ** 2
        if at.z < 0.6:
            size *= hx.clamp((at.z - 0.25) / 0.35)
        return at, size, self.turn0 + self.spin * t

    def risen(self, t, axis):
        """C: drawn after the flame, in toward its line and up, turning round it, smaller as it climbs."""
        a = t - self.lag
        if a <= 0:
            return self.start, 1.0, self.turn0
        k = hx.out_fast(a / 10) * 0.5
        radius, angle = self.radius0 * (1 - k) + 0.45, self.angle0 + 0.16 * a
        z = self.start.z + 9.0 * hx.clamp(a / 22) ** 1.7 * self.speed
        at = Vector((axis.x + radius * math.cos(angle), axis.y + radius * math.sin(angle), z))
        size = (1 - 0.5 * hx.clamp(a / 14)) * (1 - hx.clamp((a - 13) / 5) ** 2)  # gone soon after the flame
        return at, size, self.turn0 + self.spin * 0.6 * a


def layout(stage, variant, f):
    out, t = [], f - BURST
    if t < 1:
        return out
    if variant in ("A", "C"):
        out += flame(stage.collar, t)
    if variant == "B" and t <= 14:
        grow = 1.5 + 4.0 * hx.out_fast(t / 6)
        r = grow * (1 - hx.clamp((t - 7) / 7) ** 2)
        if r > 0.05:
            out.append(("ball", stage.middle, (r, r, r), (0.0, 0.0, 0.0)))
    for scrap in stage.scraps:
        if variant == "C":
            at, size, turn = scrap.risen(t, stage.collar)
        else:
            at, size, turn = scrap.thrown(t, every_way=variant == "B")
        if size > 0.04:
            out.append(("mid", at, tuple(s * size for s in SCRAP), tuple(turn)))
    return out


VARIANTS = {"A": "the flame let go", "B": "the lantern bursts", "C": "the sky lantern"}


class Stage:
    """The boxes the block-in is drawn with, set on every frame from the variant's layout."""

    def __init__(self, scene, rig):
        self.variant, self.rig = "A", rig
        self.materials = {shade: r6.flat_material(f"Fx.{shade}", colour) for shade, colour in SHADES.items()}
        self.pool = {shade: [] for shade in (*SHADES, "ball")}
        grey = r6.flat_material("Fx.Lead", (0.36, 0.36, 0.38))
        lead = r6._empty("Fx.Lead", None, Matrix.Identity(4), 0.2)
        lead.location = (LEAD[0], LEAD[1], 0.0)
        for name, size, at in (("Legs", (1.9, 0.95, 2.0), 1.0), ("Chest", (2.0, 1.0, 2.0), 3.0), ("Head", (1.2, 1.2, 1.1), 4.6),
                               ("Arms", (4.0, 0.95, 0.9), 3.5)):
            box = bl.box(f"Fx.Lead.{name}", size, grey)
            box.parent, box.location = lead, (0, 0, at)
        torso = rig.parts["Torso"]
        self.charge, self.flare = self.box("white"), self.box("white")
        for obj in (self.charge, self.flare):
            obj.parent = torso
        self.flare.location, self.flare.scale = COAT
        self.dressed = {o: o.hide_render for o in scene.objects if o.name.startswith("Shade_")}
        # where the burst starts, as the body stands on the Burst frame
        scene.frame_set(BURST)
        r6._refresh()
        world = torso.matrix_world
        self.collar = world @ Vector(COLLAR)
        self.middle = world @ Vector(COAT[0])
        coat = ((self.middle.x, self.middle.y, self.middle.z), COAT[1])
        rng = random.Random(7)
        self.scraps = [Scrap(rng, coat) for _ in range(SCRAPS)]
        print(f"the collar at the Burst: {self.collar.x:.2f} right, {self.collar.y:.2f} forward, {self.collar.z:.2f} up")
        bpy.app.handlers.frame_change_pre.append(self.set)

    def box(self, shade):
        if shade == "ball":
            bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0)
            obj = bpy.context.active_object
            obj.data.materials.append(self.materials["white"])
        else:
            obj = bl.box(f"Fx.{shade}", (1, 1, 1), self.materials[shade])
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    def set(self, scene, *_):
        f = scene.frame_current
        for o, hidden in self.dressed.items():
            o.hide_render = hidden or f >= BURST
        u = hx.clamp((f - CHARGE) / (BURST - CHARGE))
        self.charge.hide_render = not CHARGE <= f < BURST
        tall, wide = 0.2 + 1.6 * u * u, 0.5 + 0.4 * u  # light spilling up out of the collar as the mask tips off it
        self.charge.location, self.charge.scale = Vector(COLLAR) + Vector((0.0, 0.0, tall / 2)), (wide, wide, tall)
        self.flare.hide_render = f != BURST
        used = {shade: 0 for shade in self.pool}
        for shade, centre, size, turn in layout(self, self.variant, f):
            if used[shade] == len(self.pool[shade]):
                self.pool[shade].append(self.box(shade))
            obj = self.pool[shade][used[shade]]
            used[shade] += 1
            obj.location, obj.scale, obj.rotation_euler, obj.hide_render = centre, size, Euler(turn), False
        for shade, n in used.items():
            for obj in self.pool[shade][n:]:
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
    if marks.get("Burst") != BURST:
        raise SystemExit(f"the clip's Burst marker is at {marks.get('Burst')}, not {BURST}")
    return len(data["Frames"])


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def main():
    out = bl.out_dir()
    wanted = [a for a in sys.argv[sys.argv.index("--") + 2:] if a in VARIANTS] or list(VARIANTS)
    scene, rig, undress, wear, feet = sc.build()
    frames = key(rig)
    print(f"Burst: {frames} frames, the marker at {BURST}")
    stage = Stage(scene, rig)
    # the player's camera: behind the lead's right shoulder, so it sees the Shade's front and its left; and the side
    game = hx.camera(scene, "game", -24.0, 14.0, 20.0, (0.0, 1.0, 5.0), 50.0)
    side = hx.camera(scene, "side", 90.0, 6.0, 26.0, (0.0, 3.0, 5.5), 36.0)
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    for key_ in wanted:
        stage.variant = key_
        scene.render.resolution_x, scene.render.resolution_y = 400, 340
        shots = [(game, f, f"{key_}, {VARIANTS[key_]}: {label(f)}" if f == SHEET[0] else label(f)) for f in SHEET]
        print(f"wrote {r6.render_shots(scene, shots, out / f'burst_{key_}.png', columns=6)}")
    shots = [(side, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'burst_side.png', len(STRIP), (247, 170))}")
    shots = [(game, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'burst_bright.png', len(STRIP), (247, 210))}")
    floor.diffuse_color = dusk
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'burst_64.png', len(STRIP), (75, 64))}")


if __name__ == "__main__":
    main()
