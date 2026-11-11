"""A control rig over the R6 rig (r6anim.build_rig): a clip posed by targets, where a hand, a foot or the eyes go,
instead of typed angles. Blender's own
constraints solve the limbs every frame, with no grid search, and a key on a target is a key on the path the hand or
the foot travels, so its arc and its spacing are the curve between the keys.

Controls (Roblox studs and directions, as r6anim's):
- each arm and each leg: a target. The limb's Aim, an empty at its joint's pivot (under its C0, so it rides the torso),
  points the line from the pivot to the limb's end (the fist's middle, the sole's middle) at the target (Damped Track).
  R6's end sits off the pivot's line (an arm's fist half a stud outboard of it), so the joint copies the Aim through the
  one fixed turn that puts the end on that line (Frame). A target nearer than the limb's length leaves the end at full
  length on the line through it. A straight limb's end is off its pivot's line too, so a fist aimed straight ahead of
  the shoulder's pivot angles the arm 18 degrees inward, into the chest's corner: along() gives the target that lays a
  limb straight along a direction.
- each limb's twist about that line: by default the swing, as r6anim.swing keys an arm: the limb's front and back
  faces kept square to the torso's side, so an arm's flat inner face stays along the chest's side however far it
  reaches out. (The least turn from rest sinks an arm reaching out and forward into the chest, by half a stud times
  the sine of its twist: 0.28 studs on a reach to the side and ahead at chest height.) Of the two square twists it is
  the one that keeps the limb's body on its own side of its line, an arm's outboard and a leg's under its hip; the
  other mirrors an arm into the chest. So a line that passes the torso's side axis (an arm swept from ahead to behind
  past straight out, or raised sideways over it) turns the limb over, half a turn about its line: the bake reads the
  whole clip's lines first and spreads that turn over the frames the line spends near the side axis (FADE), from the
  square twist before to the square twist after. A limb built without the swing takes the least turn, or turns its
  front toward a pole the clip keys (Locked Track).
- a limb's move: its pivot shifted a little, the shoulder's own movement (r6anim.swing's move).
- the head: a look target, its face (Roblox -Z) aimed at it from the neck.
- the torso and the root stay keyed as r6anim.key keys them (body-space poses, place_root).
Every control has a keyable weight: 0 leaves the joint on its own keys, 1 follows the control, between them a blend.

bake(rig, controls, start, end) solves every controlled joint frame by frame, keys its pose on the joint itself (linear,
its quaternion kept continuous) and removes the controls, so r6anim.export, the audit and the parity check run on the
clip as on any other.
"""

import math

import bpy
from mathutils import Matrix, Quaternion, Vector

import r6anim as r6

LIMBS = ("Right Arm", "Left Arm", "Right Leg", "Left Leg")
END = (0.0, -1.0, 0.0)  # a limb's end in its own part's frame: the fist's or the sole's middle
LIE = 0.005  # studs the lowest corner sits over the floor when bake's floor lifts the body
FADE = (0.15, 0.3)  # the square twist's share by the sine of the angle between a limb's line and the torso's side axis:
# none within about 9 degrees of it (the twist turned over from the square one before to the one after), all of it past
# about 17. Swept through at 135 degrees a second, the turn peaks at 30 degrees a frame and sinks the arm 0.037 studs;
# (0.2, 0.4) sank it 0.057, over the audit's 0.05.


class Limb:
    def __init__(self, target, pole, aim, frame, follow, twist, reach, base, front, swing):
        self.target, self.pole, self.aim, self.frame = target, pole, aim, frame
        self.follow, self.twist, self.reach = follow, twist, reach
        self.base = base  # its C0's turn (Roblox, 3x3): a move in the torso's frame, as the Aim's own
        self.front = front  # its front in the Aim's own frame (Roblox)
        self.swing = swing  # its twist is the swing, solved at the bake


class Controls:
    def __init__(self):
        self.limbs: dict[str, Limb] = {}
        self.look = None  # the head's look target
        self.looking = None  # the head's Damped Track
        self.objects = []  # every object the controls added, for bake to remove


def _empty(controls: Controls, name: str, parent=None, size=0.2):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_size = size
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.rotation_mode = "QUATERNION"
    controls.objects.append(obj)
    return obj


def _track_axis(v: Vector) -> str:
    """Blender's name for the principal axis nearest `v`, a direction in an object's own Roblox frame: Roblox (x, y, z)
    is Blender (x, -z, y), so Roblox -Y, the line down a limb, is Blender's -Z."""
    blender = Vector((v.x, -v.z, v.y))
    i = max(range(3), key=lambda k: abs(blender[k]))
    return f"TRACK_{'' if blender[i] > 0 else 'NEGATIVE_'}{'XYZ'[i]}"


def build(rig: r6.Rig, swing=LIMBS) -> Controls:
    """The controls for a rig as it stands now (the rest pose sets each limb's end against its pivot, and which way its
    front and the face look: a joint's own frame is turned by its C0, so neither is its -Z), every weight 0. The limbs
    in `swing` twist by the swing; the others take the least turn, or a pole."""
    controls = Controls()
    bpy.context.view_layer.update()
    forward = r6.to_roblox(rig.parts["Torso"].matrix_world).to_3x3() @ Vector((0, 0, -1))  # the body's front
    for part in LIMBS:
        joint = rig.joints[part]
        pivot = r6.to_roblox(joint.matrix_world)
        end = (r6.to_roblox(rig.parts[part].matrix_world) @ Vector((*END, 1))).to_3d()
        local = (pivot.inverted() @ end.to_4d()).to_3d()  # the end seen from the joint, in the joint's own frame
        turn = local.normalized().rotation_difference(Vector((0, -1, 0))).to_matrix().to_4x4()  # the end onto -Y
        front = (turn.to_3x3() @ pivot.to_3x3().inverted() @ forward).normalized()  # the body's front in the Aim's
        name = part.replace(" ", "")                                                # frame: the limb's front
        target = _empty(controls, f"Ctrl.{name}.Target")
        pole = _empty(controls, f"Ctrl.{name}.Pole", size=0.1)
        aim = _empty(controls, f"Ctrl.{name}.Aim", joint.parent)
        frame = _empty(controls, f"Ctrl.{name}.Frame", aim, 0.1)
        frame.matrix_basis = r6.to_blender(turn)  # the joint = the Aim, turned: its end on the Aim's -Y
        track = aim.constraints.new("DAMPED_TRACK")
        track.target, track.track_axis = target, "TRACK_NEGATIVE_Z"  # Blender -Z is Roblox -Y: the end's line
        twist = aim.constraints.new("LOCKED_TRACK")  # about the end's line, the limb's front toward the pole
        twist.target, twist.track_axis, twist.lock_axis, twist.influence = pole, _track_axis(front), "LOCK_Z", 0.0
        follow = joint.constraints.new("COPY_TRANSFORMS")
        follow.target, follow.influence = frame, 0.0
        controls.limbs[part] = Limb(target, pole, aim, frame, follow, twist, local.length, rig.bases[part].to_3x3(),
                                    front, part in swing)
    head = rig.joints["Head"]
    face = (r6.to_roblox(head.matrix_world).inverted() @ r6.to_roblox(rig.parts["Head"].matrix_world)).to_3x3() \
        @ Vector((0, 0, -1))  # the face (the head part's -Z) in the neck joint's frame
    controls.look = _empty(controls, "Ctrl.Look")
    controls.looking = head.constraints.new("DAMPED_TRACK")
    controls.looking.target, controls.looking.track_axis, controls.looking.influence = controls.look, _track_axis(face), 0.0
    return controls


def _key(obj, frame: int, interpolation: str, easing="AUTO"):
    obj.keyframe_insert("location", frame=frame)
    r6._set_interpolation(obj, frame, interpolation, easing)


def place(controls: Controls, frame: int, part: str, target, pole=None, weight=1.0, move=(0.0, 0.0, 0.0),
          interpolation="BEZIER"):
    """Keys a limb's control at `frame`: its end aimed at Roblox point `target`, followed by `weight` (0 its own keys,
    1 the control). `pole`, a Roblox point, turns the front of a limb built without the swing toward it; without one,
    such a limb takes the least turn from its rest. `move` shifts the limb's pivot (studs, in the torso's frame: right,
    up, back), the shoulder's own movement: forward into a reach, back as it gives to a kick, up in a shrug. A few
    tenths of a stud at most: 0.3 out already shows a gap at the shoulder from the player's camera."""
    limb = controls.limbs[part]
    if pole is not None and limb.swing:
        raise ValueError(f"{part} twists by the swing: build the controls without it in `swing` to give it a pole")
    limb.target.location = r6.point_to_blender(Vector(target))
    _key(limb.target, frame, interpolation)
    limb.aim.matrix_basis = r6.to_blender(Matrix.Translation(limb.base.inverted() @ Vector(move)))
    _key(limb.aim, frame, interpolation)
    if pole is not None:
        limb.pole.location = r6.point_to_blender(Vector(pole))
        _key(limb.pole, frame, interpolation)
    if not limb.swing:  # a swinging limb's twist is set at the bake, frame by frame
        limb.twist.influence = 1.0 if pole is not None else 0.0
        limb.twist.keyframe_insert("influence", frame=frame)
    limb.follow.influence = weight
    limb.follow.keyframe_insert("influence", frame=frame)


def look(controls: Controls, frame: int, point, weight=1.0, interpolation="BEZIER"):
    """Keys the head's look target at Roblox `point`, followed by `weight`."""
    controls.look.location = r6.point_to_blender(Vector(point))
    _key(controls.look, frame, interpolation)
    controls.looking.influence = weight
    controls.looking.keyframe_insert("influence", frame=frame)


def end_point(rig: r6.Rig, part: str) -> Vector:
    """Where a limb's end is now (Roblox world): the fist's or the sole's middle."""
    return (r6.to_roblox(rig.parts[part].matrix_world) @ Vector((*END, 1))).to_3d()


def along(rig: r6.Rig, part: str, direction) -> Vector:
    """The target (Roblox world) that lays a limb straight along `direction` (world, from its shoulder or hip toward its
    end), twisted by the swing, with the torso as the scene shows it now: the pose r6anim.swing keys for that axis. The
    end sits off the pivot's line in the part's own frame (C1: an arm's fist half a stud outboard, a leg's sole half a
    stud in), so the target is that far off the line along the direction."""
    bpy.context.view_layer.update()
    torso = r6.to_roblox(rig.parts["Torso"].matrix_world).to_3x3()
    side = torso @ Vector((1, 0, 0))
    down = Vector(direction).normalized()
    out = side - side.dot(down) * down  # the part's own X: as near the torso's as the swing keeps it
    out = out.normalized() if out.length > 1e-6 else torso @ Vector((0, 1, 0))  # straight along the side axis: up
    up = -down
    offset = Vector(END) - r6.cframe(r6.JOINTS[part][2]).to_translation()  # the end from the pivot, the part's frame
    pivot = r6.to_roblox(rig.joints[part].matrix_world).to_translation()
    return pivot + offset.x * out + offset.y * up + offset.z * out.cross(up)


def corners(part: str):
    """A part's eight corners in its own frame, as the game draws it (r6anim.drawn)."""
    w, h, d = r6.drawn(part)
    return [(x * w / 2, y * h / 2, z * d / 2) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]


def lowest(rig: r6.Rig) -> float:
    """How far the lowest corner of any part sits over the floor now (studs)."""
    return min(r6.world_point(rig, part, c).y for part in r6.PARTS for c in corners(part)) - r6._floor(rig)


def _lines(rig: r6.Rig, swinging: dict) -> dict:
    """For the frame the scene shows, each swinging limb's line (its end's direction from its pivot), the torso's side
    axis and the least turn's front (Roblox world): part -> (line, side, least)."""
    for limb in swinging.values():
        limb.twist.influence = 0.0
    bpy.context.view_layer.update()
    side = r6.to_roblox(rig.parts["Torso"].matrix_world).to_3x3() @ Vector((1, 0, 0))
    lines = {}
    for part, limb in swinging.items():
        aim = r6.to_roblox(limb.aim.matrix_world).to_3x3()
        lines[part] = (aim @ Vector((0, -1, 0)), side, aim @ limb.front)
    return lines


def _fronts(samples: list) -> list:
    """One limb's swing over a clip: its front on every frame, from its (line, side, least) on every frame. Square to
    the side axis on the limb's own side (side x line: r6anim.swing's front) wherever its line is clear of the side
    axis (FADE); where the line passes near it, the square front swings fast and turns over as the line goes by, so the
    twist there turns smoothly about the line, eased, from the square twist before to the square twist after."""
    ease = r6.EASES["smooth"]
    lines = [line for line, _, _ in samples]
    carried = [samples[0][2]]  # a front carried along the lines with no twist of its own: each twist is measured from it
    for a, b in zip(lines, lines[1:]):
        r = a.rotation_difference(b) @ carried[-1]
        carried.append((r - r.dot(b) * b).normalized())
    twists, shares = [], []
    for (line, side, _), r in zip(samples, carried):
        across = side.cross(line)
        square = across.normalized() if across.length > 1e-6 else r
        twists.append(math.atan2(line.dot(r.cross(square)), r.dot(square)))
        shares.append(ease(min(max((across.length - FADE[0]) / (FADE[1] - FADE[0]), 0.0), 1.0)))

    def wrap(a):
        return (a + math.pi) % (2.0 * math.pi) - math.pi
    clear = [i for i, share in enumerate(shares) if share > 1.0 - 1e-9]  # the frames the square twist holds fully
    held = {}
    for k, i in enumerate(clear):  # their twists, unwrapped along the clip
        held[i] = twists[i] if k == 0 else held[clear[k - 1]] + wrap(twists[i] - held[clear[k - 1]])
    fronts = []
    for i, (line, r) in enumerate(zip(lines, carried)):
        before = max((c for c in clear if c <= i), default=None)
        after = min((c for c in clear if c >= i), default=None)
        if before is None and after is None:  # never clear of the side axis: the least turn's twist, carried
            base = 0.0
        elif after is None or before is None or before == after:
            base = held[before if after is None else after]
        else:
            base = held[before] + (held[after] - held[before]) * ease((i - before) / (after - before))
        fronts.append(Quaternion(line, base + shares[i] * wrap(twists[i] - base)) @ r)
    return fronts


def _twist(controls: Controls, fronts: dict):
    """Turns each swinging limb's front toward its front for the frame the scene shows (part -> a Roblox world
    direction): its pole on that side of its pivot."""
    for part, front in fronts.items():
        limb = controls.limbs[part]
        limb.pole.location = r6.point_to_blender(r6.to_roblox(limb.aim.matrix_world).to_translation() + 2.0 * front)
        limb.twist.influence = 1.0
    if fronts:
        bpy.context.view_layer.update()


def bake(rig: r6.Rig, controls: Controls, start: int, end: int, floor=False):
    """Keys every controlled joint's solved pose on the joint, frame by frame from `start` to `end` (linear, quaternions
    continuous: r6anim.key_matrices), then removes the controls and their constraints. A first pass reads the swinging
    limbs' lines over the whole clip, for their twists (_fronts). `floor`: on any frame where a corner would go under
    the floor, the torso is lifted (its own key) until none does, the limbs solved again from there (a
    leg reaching a planted foot from a leaning body turns its sole's edge into the floor)."""
    scene = bpy.context.scene
    joints = list(controls.limbs) + ["Head"]
    swinging = {part: limb for part, limb in controls.limbs.items() if limb.swing}
    samples = {part: [] for part in swinging}
    for f in range(start, end + 1):
        scene.frame_set(f)
        for part, sample in (_lines(rig, swinging) if swinging else {}).items():
            samples[part].append(sample)
    fronts = {part: _fronts(lines) for part, lines in samples.items()}
    solved = []
    for i, f in enumerate(range(start, end + 1)):
        scene.frame_set(f)
        bpy.context.view_layer.update()
        now = {part: fronts[part][i] for part in swinging}
        _twist(controls, now)
        for _ in range(4 if floor else 0):  # the lift turns the legs a little, so it settles over a few passes
            low = lowest(rig)
            if low >= LIE - 1e-4:
                break
            x, y, z, dx, dy, dz = r6.pose_of(rig, "Torso")
            r6.key(rig, f, {"Torso": (x, y, z, dx, dy + LIE - low, dz)}, plant=False, interpolation="LINEAR")
            bpy.context.view_layer.update()
            _twist(controls, now)
        solved.append((f, {part: rig.joints[part].parent.matrix_world.inverted() @ rig.joints[part].matrix_world
                           for part in joints}))
    for part in joints:
        joint = rig.joints[part]
        for constraint in list(joint.constraints):
            joint.constraints.remove(constraint)
    for f, matrices in solved:
        r6.key_matrices(rig, f, matrices)
    for obj in controls.objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    controls.objects.clear()
