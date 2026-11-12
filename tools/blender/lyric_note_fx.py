"""Lyric's Held Note as a grey block-in on her delivered clip (AR4, delivery 4 for Lyric; the block-in step for an effect).

blender.exe -b --factory-startup --python tools/blender/lyric_note_fx.py -- <out_dir> [A B C ...]

Timing and size only: plain shapes in white and grey, no art. Lyric plays her delivered HeldNote clip, and the effect
hangs on its markers: Breath 4, Note 30, Release 90. The wave leaves the speakers' rings (the recipe's RingR and RingL,
read off the keyed clip every frame) and stays inside the cone the speakers mark: their two lines, met behind her,
give its apex and its width, and their tilt its fall. Its length is a stand-in, REACH studs out from her; none is in the
design yet. A grey stand-in Shade is the target, a second Shade stands deeper in the cone, and a grey stand-in for an
ally (another lead) stands in it to her left; a grey stand-in for the avatar stands where the player's camera looks past
it. Writes one sheet a variant from the player's camera, then the variants side by side from the side, from the camera
beside, from the worst case, on a bright floor and at 64 px, and the effect's share of the screen. Needs lyric_model.py's
output, as lyric_clips.py does. Workbench, so no GPU turn.

Shared by every variant (her conditions 11 to 13: light, arcs, rings and speed lines from the speakers' rings, clear of
her head; nothing from her mouth; never drops or red; the heal not hearts; the cone never lengthens):
- the charge: a light swells in each ring as the speakers draw back with her breath (22 to 30);
- the punctuation: both rings flash on the Note frame (30 and 31);
- the touches, stand-ins for the builder's shared hit and heal, to time them: a flash at a Shade's chest, a ring rising
  round the ally, on the frame a wave reaches it.
The wave, by variant:
- A, the crests: an arc across the whole cone thrown from the rings on every half-beat (30, 45, 60, 75, 90), fast,
  then slowing; it thins and goes as it reaches the cone's end. The note as a pulse on her beat.
- B, the front: one arc thrown at the Note to just past the target, then pushed on slowly through the hold, shaking
  with the speakers; on the Release it runs to the cone's end and goes. One note, one shape.
- C, the stream: the arc thrown at the Note as in A, then speed lines poured down the cone from the rings through the
  hold; on the Release they stop at the rings and the last run out.

Cameras, as pip_burst_fx.py frames a fight (Config.Combat.Lead): the lead stands beyond its target turned Frame (45)
degrees round, so the player's camera, 12.5 studs behind the avatar and looking at its head, sees past the avatar and
the target to her front-left, and the wave comes at the camera. "beside" is a lead beside an elite (90), the wave
crossing the screen; "hidden" the avatar facing its target dead on. Field of view 70, the game's, at 16:9; the 64 px
row at 50. Stage directions: right, forward, up, in studs, from where she stands; she faces forward and sings forward.
"""
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (camera, render_variants, clamp, out_fast)
import lyric_clips as lc  # noqa: E402

CLIP = Path(__file__).resolve().parents[2] / "build" / "handoff" / "Lyric" / "clips" / "Lyric_HeldNote.json"
BREATH, NOTE, RELEASE = 4, 30, 90  # the clip's markers
MARKS = {"Breath": BREATH, "Note": NOTE, "Release": RELEASE}
RINGS = {lc.SR: Vector((2.5321, -0.1362, 4.892)), lc.SL: Vector((-2.5321, -0.1362, 4.892))}  # the recipe's, at rest
AXES = {lc.SR: Vector((-math.sin(math.radians(12)), math.cos(math.radians(12)), 0.0)),  # each cone's way at rest:
        lc.SL: Vector((math.sin(math.radians(12)), math.cos(math.radians(12)), 0.0))}  # forward, turned 12 inward
REACH = 16.0               # how far out from her the wave goes: a stand-in, the builder's and research's
SPREAD = 11.0              # degrees the wave opens up and down from its middle, past the rings
TARGET = (0.3, 11.0)       # the target's middle, in the cone
OTHER = (4.0, 14.2)        # a second Shade, deeper in it
ALLY = (-3.8, 8.6)         # another lead, an ally, in it to her left
BACK, EYE, PITCH = 8.0, 12.5, 14.0  # the avatar from the target, the camera behind the avatar, and its tilt down
LOOKS = {"fight": (-45.0, 26.0), "beside": (0.0, 26.0), "hidden": (-45.0, 0.0)}  # as pip_burst_fx.py
SHADES = {"white": (0.93, 0.93, 0.93), "mid": (0.6, 0.6, 0.6), "veil": (0.93, 0.93, 0.93)}
VEIL = 0.35  # how much of the veil you see: a stand-in for light you see the fight through
BEATS = (30, 45, 60, 75, 90)  # A's crests: the half-beats of the hold, Release included
THROW = 14                 # frames a thrown arc takes to the cone's end
SHEET = (4, 22, 28, 30, 31, 33, 36, 40, 45, 50, 60, 75, 90, 93, 98, 108)
STRIP = (30, 32, 35, 40, 50, 65, 90, 94, 100)
SHARE = (30, 32, 34, 36, 40, 50, 65, 80, 92, 98)
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


# --- the cone, from the speakers --------------------------------------------------------------------------------------

class Cone:
    """The wave's room, read off the speakers in the hold: the apex where their two lines meet behind her, the half
    angle between those lines, the rings' distance from the apex (where the wave starts) and the end (REACH out from
    her), and how fast it falls (their tilt). A wave's place is a radius from the apex; its middle falls as it goes."""

    def __init__(self, ring, axis, f):
        r, l = ring[lc.SR][f], ring[lc.SL][f]
        ar, al = axis[lc.SR][f], axis[lc.SL][f]
        flat_r, flat_l = Vector((ar.x, ar.y)).normalized(), Vector((al.x, al.y)).normalized()
        # the two lines on the floor, r + s * flat_r and l + t * flat_l, met where their x and y agree
        m = Matrix(((flat_r.x, -flat_l.x), (flat_r.y, -flat_l.y)))
        s, _ = m.inverted() @ Vector((l.x - r.x, l.y - r.y))
        self.apex = Vector((r.x + s * flat_r.x, r.y + s * flat_r.y))
        self.half = math.degrees(flat_r.angle(flat_l)) / 2
        self.start = (Vector((r.x, r.y)) - self.apex).length
        self.end = REACH - self.apex.y
        self.height = (r.z + l.z) / 2
        self.fall = math.tan((math.asin(-ar.z) + math.asin(-al.z)) / 2)

    def middle(self, radius):
        return self.height - (radius - self.start) * self.fall

    def span(self, radius):
        """The wave's bottom and top at a radius: a ring's width at the rings, opening SPREAD each way, never under
        the floor."""
        half = 0.35 + (radius - self.start) * math.tan(math.radians(SPREAD))
        mid = self.middle(radius)
        return max(0.15, mid - half), mid + half

    def place(self, at):
        """A figure's radius from the apex and its angle off the cone's middle, in degrees."""
        d = Vector(at) - self.apex
        return d.length, math.degrees(math.atan2(d.x, d.y))


def arc(cone, radius, thick, fade=1.0):
    """A wave across the whole cone at `radius`: a veil the wave's height, `thick` studs deep, that you see through
    (the room it fills), and on its leading face a white ribbon at its middle (the crest, what reads); `fade` thins
    both as it goes."""
    bottom, top = cone.span(radius)
    mid = (bottom + top) / 2
    half = (top - bottom) / 2 * fade
    ribbon = 0.3 * fade + 0.1
    return [("band", "veil", radius - 0.05, max(0.04, thick), (max(0.15, mid - half), mid + half)),
            ("band", "white", radius, max(0.04, 0.35 * fade), (mid - ribbon, mid + ribbon))]


def thrown(cone, t):
    """Where an arc thrown `t` frames ago is, and how deep: fast, then slowing; it thins to nothing at the end."""
    if not 0 <= t <= THROW:
        return None
    u = t / THROW
    radius = cone.start + (cone.end - cone.start) * hx.out_fast(u)
    return radius, 0.9 * (1 - 0.6 * u) * (1 - hx.clamp((u - 0.7) / 0.3)), 1 - 0.5 * hx.clamp((u - 0.6) / 0.4)


# --- the shared beats -------------------------------------------------------------------------------------------------

def charge(stage, f):
    """A light in each ring: swelling from 22 as the speakers draw back, a flash on the Note, then gone."""
    if f < 22 or f > NOTE + 1:
        return []
    # ring-sized: from the player's camera the left speaker sits just left of her head, so a bigger flash covers it
    size = 0.25 + 0.3 * smooth((f - 22) / 8) if f < NOTE else (0.9 if f == NOTE else 0.6)
    return [("ball", "white", stage.ring[name][f] + stage.axis[name][f] * 0.15, (size,) * 3, Quaternion())
            for name in (lc.SR, lc.SL)]


def touches(stage, f, passes):
    """Stand-ins for the hit and the heal, on the frame a wave reaches each figure (`passes`: a figure's name to the
    frames it's reached)."""
    out = []
    for name, (x, y) in stage.figures.items():
        for at in passes.get(name, ()):
            t = f - at
            if name == "Ally" and 0 <= t <= 14:
                z = 0.4 + 4.6 * hx.out_fast(t / 14)
                r = 1.6 * (1 - 0.3 * t / 14)
                out.append(("ring", "mid", Vector((x, y, z)), (r, r, 1.0), Quaternion()))
            elif name != "Ally" and 0 <= t <= 3:
                s = 1.2 * (1 - t / 4)
                out.append(("ball", "white", Vector((x, y, 3.0)), (s, s, s), Quaternion()))
    return out


# --- the wave, by variant ---------------------------------------------------------------------------------------------

def crests(stage, f):
    """A: an arc on every half-beat of the hold: {frame thrown: (radius, depth, fade)}."""
    return {born: at for born in BEATS if (at := thrown(stage.cone, f - born))}


def front(stage, f):
    """B: one arc, thrown to just past the target, pushed on through the hold, shaking; let go on the Release."""
    cone, t = stage.cone, f - NOTE
    if t < 0:
        return {}
    held = stage.figures_at["Target"] + 1.2  # just past the target
    far = cone.end - 1.5
    if f <= RELEASE:
        radius = cone.start + (held - cone.start) * hx.out_fast(t / 6) + (far - held) * smooth((t - 6) / (RELEASE - NOTE - 6))
        buzz = math.sin(2 * math.pi * t / lc.BUZZ) * hx.clamp((t - 4) / 4)
        return {NOTE: (radius + 0.12 * buzz, 0.9 + 0.25 * buzz, 1.0)}
    u = (f - RELEASE) / 10
    if u > 1:
        return {}
    return {NOTE: (far + (cone.end - far) * u, 0.9 * (1 - u), 1 - 0.6 * u)}


def thrown_once(stage, f):
    """C's arc: the one thrown at the Note."""
    at = thrown(stage.cone, f - NOTE)
    return {NOTE: at} if at else {}


def lines(stage, f):
    """C's speed lines, poured down the cone from the rings through the hold."""
    out = []
    cone = stage.cone
    for born, angle, lift in stage.lines:
        t = f - born
        if t < 0:
            continue
        head = cone.start + 0.4 + 1.15 * t
        tail = max(cone.start + 0.2, head - 3.0)
        head = min(head, cone.end)
        if head - tail < 0.2:
            continue
        a = math.radians(angle)
        way = Vector((math.sin(a), math.cos(a), 0.0))

        def point(radius):
            bottom, top = cone.span(radius)
            return Vector((cone.apex.x, cone.apex.y, 0.0)) + way * radius + Vector((0, 0, bottom + (top - bottom) * lift))

        p, q = point(tail), point(head)
        w = 0.24
        out.append(("box", "white", (p + q) / 2, (w, w, (q - p).length), toward(q - p)))
    return out


# each variant: its name, its arcs, and anything else it draws
VARIANTS = {"A": ("the crests", crests, None), "B": ("the front", front, None), "C": ("the stream", thrown_once, lines)}


def wave(stage, variant, f):
    _, arcs, more = VARIANTS[variant]
    out = [shape for at in arcs(stage, f).values() for shape in arc(stage.cone, *at)]
    return out + (more(stage, f) if more else [])


def layout(stage, variant, f):
    out = charge(stage, f) + wave(stage, variant, f)
    return out + touches(stage, f, stage.passes[variant])


# --- the stage --------------------------------------------------------------------------------------------------------

class Stage:
    """The shapes the block-in is drawn with, set on every frame from the variant's layout; and the stand-ins."""

    def __init__(self, scene, rig, frames, rest):
        self.variant, self.show = "A", True
        self.materials = {shade: r6.flat_material(f"Fx.{shade}", colour) for shade, colour in SHADES.items()}
        veil = self.materials["veil"]
        veil.diffuse_color[3] = VEIL  # Workbench draws a colour with alpha see-through
        if hasattr(veil, "surface_render_method"):
            veil.surface_render_method = "BLENDED"
        self.pool = {}
        # each ring and the way its cone faces, on every frame, read once from the keyed clip
        self.ring, self.axis = {lc.SR: [], lc.SL: []}, {lc.SR: [], lc.SL: []}
        for f in range(frames):
            scene.frame_set(f)
            r6._refresh()
            for name, (local, way) in rest.items():
                m = bpy.data.objects[name].matrix_world
                self.ring[name].append(m @ local)
                self.axis[name].append((m.to_3x3() @ way).normalized())
        self.cone = Cone(self.ring, self.axis, 60)
        c = self.cone
        print(f"the cone: apex {tuple(round(v, 2) for v in c.apex)}, half angle {c.half:.1f}, from {c.start:.2f} to "
              f"{c.end:.2f} studs off the apex, the rings {c.height:.2f} up, falling {c.fall:.3f} a stud")
        for f in (NOTE, 60, RELEASE):
            print(f"  {f}: rings at {[tuple(round(v, 2) for v in self.ring[n][f]) for n in (lc.SR, lc.SL)]}")
        self.figures = {"Target": TARGET, "Other": OTHER, "Ally": ALLY}
        self.figures_at = {name: c.place(at)[0] for name, at in self.figures.items()}
        for name, at in self.figures.items():
            radius, angle = c.place(at)
            print(f"  {name}: {radius:.2f} off the apex, {angle:.1f} degrees off the middle "
                  f"({'in' if abs(angle) <= c.half and radius <= c.end else 'OUT of'} the cone)")
        rng = random.Random(7)
        self.lines = []  # C: (frame born, degrees off the middle, how high in the wave)
        for born in range(NOTE + 2, RELEASE + 1):
            for _ in range(2):
                self.lines.append((born, rng.uniform(-0.95, 0.95) * c.half, rng.uniform(0.15, 0.85)))
        self.passes = {key: self.reached(key) for key in VARIANTS}
        print(f"  reached: {json.dumps(self.passes)}")
        shade = r6.flat_material("Fx.Shade", (0.30, 0.28, 0.33))
        ally = r6.flat_material("Fx.Ally", (0.52, 0.55, 0.5))
        grey = r6.flat_material("Fx.Avatar", (0.42, 0.42, 0.45))
        for name, (x, y) in (("Target", TARGET), ("Other", OTHER)):
            self.figure(name, (x, y), 0.0, shade, (("Coat", (2.6, 1.4, 4.4), 2.4), ("Mask", (1.3, 1.1, 1.2), 5.2)))
        self.figure("Ally", ALLY, 0.0, ally, (("Legs", (2.0, 1.0, 2.0), 1.0), ("Body", (2.0, 1.0, 2.0), 3.0),
                                              ("Head", (1.2, 1.2, 1.2), 4.6)))
        self.avatar = self.figure("Avatar", (0, 0), 0.0, grey, (("Legs", (2.0, 1.0, 2.0), 1.0), ("Body", (4.0, 1.0, 2.0), 3.0),
                                                              ("Head", (1.2, 1.2, 1.2), 4.6)))
        self.avatar_boxes = list(self.avatar.children)
        bpy.app.handlers.frame_change_pre.append(self.set)

    def reached(self, variant):
        """The frames each of the variant's arcs reaches each figure: its crest at or past the figure's radius (a
        Shade's or an ally's half width, 0.7, short of its middle)."""
        out = {}
        for name, radius in self.figures_at.items():
            seen = {}
            for f in range(NOTE, RELEASE + 30):
                for born, (r, *_) in VARIANTS[variant][1](self, f).items():
                    if born not in seen and r >= radius - 0.7:
                        seen[born] = f
            out[name] = sorted(seen.values())
        return out

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
        elif kind == "band":
            obj = bpy.data.objects.new(f"Fx.Band.{shade}", bpy.data.meshes.new("Fx.Band"))
            bpy.context.scene.collection.objects.link(obj)
            obj.data.materials.append(self.materials[shade])
        else:
            if kind == "ball":
                bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0)
            else:  # a ring, lying flat
                bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.08, major_segments=40, minor_segments=8)
            obj = bpy.context.active_object
            obj.data.materials.append(self.materials[shade])
        obj.display.show_shadows = False
        obj.rotation_mode = "QUATERNION"
        obj.hide_render = True
        return obj

    def band(self, obj, radius, thick, span):
        """Remakes a band's mesh in place: a closed curved slab across the cone, `thick` deep behind `radius`."""
        cone, steps = self.cone, 28
        bottom, top = span
        verts, faces = [], []
        for i in range(steps + 1):
            a = math.radians(-cone.half + 2 * cone.half * i / steps)
            way = Vector((math.sin(a), math.cos(a)))
            for r_, z in ((radius - thick, bottom), (radius, bottom), (radius, top), (radius - thick, top)):
                p = cone.apex + way * r_
                verts.append((p.x, p.y, z))
        for i in range(steps):
            for j in range(4):
                a, b = i * 4 + j, i * 4 + (j + 1) % 4
                faces.append((a, b, b + 4, a + 4))
        faces += [(0, 1, 2, 3), (steps * 4 + 3, steps * 4 + 2, steps * 4 + 1, steps * 4)]
        mesh = obj.data
        mesh.clear_geometry()
        mesh.from_pydata(verts, [], faces)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()

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
        used = {}
        for shape in (layout(self, self.variant, f) if self.show else []):
            kind, shade = shape[0], shape[1]
            pool = self.pool.setdefault((kind, shade), [])
            n = used.get((kind, shade), 0)
            if n == len(pool):
                pool.append(self.make(kind, shade))
            obj = pool[n]
            used[(kind, shade)] = n + 1
            if kind == "band":
                self.band(obj, *shape[2:])
            else:
                obj.location, obj.scale, obj.rotation_quaternion = shape[2:]
            obj.hide_render = False
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


def main():
    out = bl.out_dir()
    wanted = [a for a in sys.argv[sys.argv.index("--") + 2:] if a in VARIANTS] or list(VARIANTS)
    scene, rig, costume, undress, feet, ctl, motors = lc.build()
    bpy.context.view_layer.update()
    rest = {}
    for name in (lc.SR, lc.SL):  # each ring and its cone's way in the speaker's own frame, from the rest pose
        m = bpy.data.objects[name].matrix_world
        rest[name] = (m.inverted() @ RINGS[name], (m.to_3x3().inverted() @ AXES[name]).normalized())
    frames = key(rig)
    print(f"HeldNote: {frames} frames, the markers at {MARKS}")
    stage = Stage(scene, rig, frames, rest)
    cameras = {}
    for name in ("fight", "fight50", "beside", "hidden"):  # behind the avatar, looking at its head (the game's camera)
        look, spot = staged(name)
        azimuth = math.degrees(math.atan2(-look.x, -look.y))
        cameras[name] = hx.camera(scene, name, azimuth, PITCH, EYE / math.cos(math.radians(PITCH)), (spot.x, spot.y, 4.5),
                                  50.0 if name == "fight50" else 70.0)
        eye = cameras[name].location
        radius, angle = stage.cone.place((eye.x, eye.y))
        print(f"{name}: Lyric seen {math.degrees(math.atan2(-eye.x, eye.y)):.0f} degrees off her front, from "
              f"{Vector((eye.x, eye.y)).length:.1f} studs; the camera {radius:.1f} off the apex, {angle:.0f} off the middle")
    fight, fight50, beside, hidden = (cameras[n] for n in ("fight", "fight50", "beside", "hidden"))
    side = hx.camera(scene, "side", 90.0, 6.0, 27.0, (0.0, 8.0, 3.0), 40.0)
    bpy.data.objects["Floor"].scale *= 4  # past the camera's edges
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    for key_ in wanted:
        stage.variant = key_
        scene.render.resolution_x, scene.render.resolution_y = 480, 270
        title = f"{key_}, {VARIANTS[key_][0]}: "
        shots = [(fight, f, title + label(f) if f == SHEET[0] else label(f)) for f in SHEET]
        print(f"wrote {r6.render_shots(scene, shots, out / f'heldnote_{key_}.png', columns=4)}")
    tile = (320, 180)
    for name, camera in (("side", side), ("beside", beside), ("hidden", hidden)):
        shots = [(camera, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
        print(f"wrote {hx.render_variants(scene, stage, shots, out / f'heldnote_{name}.png', len(STRIP), tile)}")
    shots = [(fight, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'heldnote_bright.png', len(STRIP), tile)}")
    floor.diffuse_color = dusk
    shots = [(fight50, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'heldnote_64.png', len(STRIP), (75, 64))}")
    c = stage.cone
    table = {
        "markers": MARKS, "reach": REACH, "spread": SPREAD,
        "cone": {"apex": [round(v, 2) for v in c.apex], "half": round(c.half, 1), "start": round(c.start, 2),
                 "end": round(c.end, 2), "height": round(c.height, 2), "fall": round(c.fall, 3)},
        "figures": {name: [round(v, 2) for v in c.place(at)] for name, at in stage.figures.items()},
        "reached": stage.passes,
        "share": share(scene, stage, fight, wanted, out / "share.png"),
    }
    (out / "heldnote.json").write_text(json.dumps(table, indent=1))
    print(json.dumps(table["share"]), json.dumps(table["reached"]))


if __name__ == "__main__":
    main()
