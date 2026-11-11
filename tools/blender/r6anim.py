"""R6 animation in Blender, for clip scripts (run headless:
blender.exe -b --factory-startup --python <clip script> -- <out_dir>).

An exact R6 rig, built from Roblox's own Motor6D joints (C0/C1 measured on a live character), animated with Blender's
curves, reviewed in renders from the game's player camera, and baked to one pose per frame for Studio: the JSON goes to
build/import/Anim_<Name>.txt, and tools/studio/Animations/Author.SaveBaked turns it into a KeyframeSequence.

Frames: Roblox X = Blender X, Roblox Y = Blender Z, Roblox Z = -Blender Y (blcommon); a character faces Roblox -Z, which
is Blender +Y. Each rig is a tree of objects: an Empty for the HumanoidRootPart (moved for review only: in the game
physics moves it), and per joint an Empty at its C0 (child of Part0), an animated Empty under it whose local transform
is the Motor6D's Transform, and the part's box under that at C1's inverse. What's exported is what Roblox plays.

Poses use the body-space angles of tools/studio/Animations/Author: degrees, X = pitch (forward for arms, legs, torso and
head), Y = turn (left), Z = swing (an arm or leg out: Right +, Left -), then an optional move in studs (-Z is forward).
Keyed with plant=True (the default), a pose gives the legs' pitch against the ground: R6 legs hang from the torso, so
the torso's lean is added to them and the torso shifts to keep the hips over the feet.
"""

import bisect
import json
import math
import re
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

import blcommon as bl
from r6rig import (CLAW_WRISTS, GRIP as _GRIP, GRIPS, HEAD_DRAWN, JOINTS, KNEE_C0, KNEE_C1, KNEES, LOADOUTS, MUZZLE, PARTS,  # noqa: F401
                   ROOT_HEIGHT, HELD_TIP, SIZES, STOWED, STOWS, WEAPON_AXES, WEAPONS, WELDED, WRISTS)

REPO = Path(__file__).resolve().parents[2]
GRAVITY = 145.0  # your place's workspace.Gravity (a place setting): a starting point, set your own


def knock_arc(t: float, launch: float, knockback: float) -> tuple:
    """Where Simulation/Knock carries a struck root `t` seconds after the hit, from where it stood facing -Z: up at the
    speed that reaches `launch` studs, down under GRAVITY, `knockback` studs behind it by the time it lands, and still
    from then on (Roblox studs: right, up, back). Without a launch, straight back at one speed for Config.Combat's
    Knock.Time, then stopped dead."""
    if launch <= 0:
        time = luau_table("src/shared/Config/Combat.luau", "Knock = {")["Time"]
        return 0.0, 0.0, knockback * min(max(t, 0.0) / time, 1.0)
    up = math.sqrt(2 * GRAVITY * launch)
    land = 2 * up / GRAVITY
    t = min(max(t, 0.0), land)
    return 0.0, up * t - GRAVITY * t * t / 2, knockback * t / land


# Roblox to Blender: (x, y, z) -> (x, -z, y), a rotation (blcommon's frames).
M = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
M_INV = M.inverted()

# PARTS, JOINTS (Part1: Part0, C0, C1), SIZES, ROOT_HEIGHT and the weapon welds come from r6rig.py, shared with the
# parity check (r6parity.py) so both sides pose the same rig.
LEANS = {"Torso", "Head"}  # pitch flips on these: their joint bases face the other way from a limb's
LEGS = {"Right Leg", "Left Leg"}


# --- frames ------------------------------------------------------------------------------------------------------

def cframe(c) -> Matrix:
    """A Roblox CFrame from its 12 components (x, y, z, R00 ... R22)."""
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c
    return Matrix(((r00, r01, r02, x), (r10, r11, r12, y), (r20, r21, r22, z), (0, 0, 0, 1)))


def components(m: Matrix) -> list:
    return [m[0][3], m[1][3], m[2][3], m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2]]


def to_blender(m: Matrix) -> Matrix:
    return M @ m @ M_INV


def to_roblox(m: Matrix) -> Matrix:
    return M_INV @ m @ M


def point_to_blender(p) -> Vector:
    return Vector((p[0], -p[2], p[1]))


def point_to_roblox(p) -> Vector:
    return Vector((p[0], p[2], -p[1]))


def D(right, up, forward) -> tuple:
    """A direction in the body's frame (right, up, forward), as a Roblox vector (forward is -Z). Clips are staged
    facing -Z, so the body's frame is the world's."""
    v = Vector((right, up, -forward)).normalized()
    return (v.x, v.y, v.z)


def look_at(position, target) -> Matrix:
    """A Roblox CFrame at `position` looking at `target` (both Roblox points), like CFrame.lookAt."""
    position, target = Vector(position), Vector(target)
    look = (target - position).normalized()
    right = look.cross(Vector((0, 1, 0))).normalized()
    up = right.cross(look)
    back = -look
    return Matrix(((right.x, up.x, back.x, position.x), (right.y, up.y, back.y, position.y),
                   (right.z, up.z, back.z, position.z), (0, 0, 0, 1)))


# --- the rig ---------------------------------------------------------------------------------------------------------

class Rig:
    def __init__(self, name: str):
        self.name = name
        self.root: bpy.types.Object | None = None  # the HumanoidRootPart
        self.parts: dict[str, bpy.types.Object] = {}  # part name -> its box
        self.joints: dict[str, bpy.types.Object] = {}  # part name -> the animated Empty (Motor6D Transform)
        self.bases: dict[str, Matrix] = {}  # part name -> its C0 rotation (Roblox), for body-space poses
        self.last: dict[str, Quaternion] = {}  # the last keyed rotation per joint, to keep quaternions continuous
        self.wrists: dict[str, str] = {}  # arm -> its wrist joint (r6rig.WRISTS), on a rig built with wrists
        self.claws: dict[str, str] = {}  # arm -> its claws' joint (r6rig.CLAW_WRISTS), on a rig built with claws
        self.knees: dict[str, str] = {}  # leg -> its knee's joint, the shin (r6rig.KNEES), on a rig built with knees
        self.wrists_kept: dict[str, Matrix] | None = None  # while a script keys frames in order: arm -> its wrist's
        # last rotation, so a weapon passing through the forearm's line doesn't flip the hand (aim_wrist); None: off

    def extra_joints(self) -> list:
        """(limb, joint) for every joint past R6's six that a clip animates and exports: the weapon wrists, the claws'
        wrists and the knees, on a rig built with them."""
        return [*self.wrists.items(), *self.claws.items(), *self.knees.items()]


def _empty(name, parent, local: Matrix, size=0.15):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_size = size
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.rotation_mode = "QUATERNION"
    obj.matrix_basis = to_blender(local)
    return obj


def _block(name, parent, local: Matrix, size, material):
    """A box of Roblox `size` under `parent` at Roblox `local`."""
    obj = bl.box(name, (size[0], size[2], size[1]), material)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.matrix_basis = to_blender(local)
    return obj


def flat_material(name, colour, roughness=0.6, emission=None):
    material = bpy.data.materials.new(name)
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*colour, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = 2.0
    material.diffuse_color = (*colour, 1)  # what Workbench shows
    return material


def drawn(part: str) -> tuple:
    """A part's box as the game draws it: its Size, but the head as its mesh shows it (r6rig.HEAD_DRAWN), one size in
    every clip's review. The box is built at that size, never scaled, so the part's frame stays its CFrame."""
    return HEAD_DRAWN if part == "Head" else SIZES[part]


def build_rig(name: str, palette: dict, weapons: bool = False, wrists: bool = False, claws: bool = False, knees: bool = False) -> Rig:
    """An R6 body: palette maps part names (and "Face", "Blade", "Steel") to RGB. Weapons adds Hero's blade and
    gun. Wrists adds the weapon wrist (r6rig.WRISTS): a joint per hand at the grip, between the arm and its weapon,
    animated and exported like the body's joints; at rest the weapon sits exactly where the weld puts it. Claws adds the
    Creature's claws' wrists (r6rig.CLAW_WRISTS), a joint per hand at the cuff's end, animated and exported the same way
    under the claws' MeshPart's name; they hold nothing, so the weapon tools (wield, stow) leave them alone. Knees adds a
    joint at each leg's middle (r6rig.KNEES): the leg's part keeps its frame, its box cut to the top half, with a round at
    the knee and the shin below; bend_leg keys them."""
    rig = Rig(name)
    materials = {key: flat_material(f"{name}_{key}", rgb) for key, rgb in palette.items()}
    rig.root = _empty(f"{name}.Root", None, Matrix.Identity(4), 0.4)
    rig.parts["HumanoidRootPart"] = rig.root
    for part in PARTS:  # in order: every Part0 exists before its children
        part0, c0, c1 = JOINTS[part]
        base = _empty(f"{name}.C0.{part}", rig.parts[part0], cframe(c0))
        joint = _empty(f"{name}.J.{part}", base, Matrix.Identity(4))
        rig.joints[part] = joint
        rig.bases[part] = cframe(c0).to_3x3().to_4x4()
        rig.parts[part] = _block(f"{name}.{part}", joint, cframe(c1).inverted(), drawn(part), materials.get(part))
    # the face's side: a dark band across the front of the head, so its facing reads in any render
    w, h, d = HEAD_DRAWN
    _block(f"{name}.Face", rig.parts["Head"], cframe((0, 0.08 * h, -0.47 * d, 1, 0, 0, 0, 1, 0, 0, 0, 1)),
           (0.65 * w, 0.22 * h, 0.1 * d), materials.get("Face"))
    if wrists:
        for arm, (joint, _) in WRISTS.items():
            base = _empty(f"{name}.C0.{joint}", rig.parts[arm], cframe(_GRIP), 0.1)
            rig.joints[joint] = rig.parts[joint] = _empty(f"{name}.J.{joint}", base, Matrix.Identity(4), 0.1)
            rig.bases[joint] = cframe(_GRIP).to_3x3().to_4x4()
            rig.wrists[arm] = joint
    if claws:
        for arm, (_, part1, c0) in CLAW_WRISTS.items():
            base = _empty(f"{name}.C0.{part1}", rig.parts[arm], cframe(c0), 0.1)
            rig.joints[part1] = rig.parts[part1] = _empty(f"{name}.J.{part1}", base, Matrix.Identity(4), 0.1)
            rig.bases[part1] = cframe(c0).to_3x3().to_4x4()
            rig.claws[arm] = part1
    if knees:
        for leg, shin in KNEES.items():
            material = materials.get(leg)
            rig.parts[leg].data.transform(Matrix.Translation((0, 0, 0.5)) @ Matrix.Diagonal((1, 1, 0.5, 1)))  # the box, now the thigh
            base = _empty(f"{name}.C0.{shin}", rig.parts[leg], cframe(KNEE_C0), 0.1)
            rig.joints[shin] = _empty(f"{name}.J.{shin}", base, Matrix.Identity(4), 0.1)
            rig.bases[shin] = cframe(KNEE_C0).to_3x3().to_4x4()
            rig.parts[shin] = _block(f"{name}.{shin}", rig.joints[shin], cframe(KNEE_C1).inverted(), drawn(shin), material)
            rig.knees[leg] = shin
            cap = bl.cylinder(f"{name}.{leg}.Knee", 0.49, 0.98, material=material)  # closes the bend's outer corner
            cap.parent = rig.parts[leg]
            cap.rotation_euler = (0.0, math.radians(90), 0.0)
    if weapons:
        for weapon, (part0, c0, c1, size) in WEAPONS.items():
            key = "Blade" if weapon == "HeldRightBlade" else "Steel"
            if part0 in rig.wrists:  # held through the wrist: its joint frame is the hand's grip, turned
                parent, local = rig.parts[rig.wrists[part0]], cframe(c1).inverted()
            else:
                parent, local = rig.parts[part0], cframe(c0) @ cframe(c1).inverted()
            rig.parts[weapon] = _block(f"{name}.{weapon}", parent, local, size, materials.get(key))
    return rig


# Each hand's real weapon: the .blend its script writes (your weapon script, smg.py) and the objects in it. Their origins are
# the grips (the models' Grip attachments, at the model's origin with no turn), seated in the hand like the game's welds.
WEAPON_MESHES = {"Right Arm": ("held_right.blend", ("Held_Hilt", "Held_Blade")),
                 "Left Arm": ("held_left.blend", ("Gun_Body", "Gun_Crystal"))}
# Workbench colours for their materials (review only), by a word in the material's name.
WEAPON_COLOURS = (("Inlaid", (0.075, 0.07, 0.08)), ("Steel", (0.075, 0.07, 0.08)), ("Brass", (0.62, 0.45, 0.17)),
                  ("Walnut", (0.27, 0.12, 0.05)), ("Shagreen", (0.22, 0.04, 0.05)), ("Crystal", (1.0, 0.6, 0.2)),
                  ("Garnet", (0.5, 0.03, 0.06)))


def weapon_meshes(rig: Rig, folder: Path) -> bool:
    """Hero's real blade and gun in the rig's hands, for reviews that need their silhouettes: loaded from
    the .blend files tools/blender/your weapon script and smg.py wrote to `folder`. False (nothing added) if one is missing."""
    paths = {arm: Path(folder).resolve() / blend for arm, (blend, _) in WEAPON_MESHES.items()}  # Blender reads a
    # relative path against the drive's root, not the working folder
    if not all(path.exists() for path in paths.values()):
        return False
    for arm, (_, names) in WEAPON_MESHES.items():
        with bpy.data.libraries.load(str(paths[arm])) as (_, data_to):
            data_to.objects = list(names)
        for obj in data_to.objects:
            bpy.context.scene.collection.objects.link(obj)
            wrist = rig.wrists.get(arm)  # held through the wrist joint (at the grip), or seated at the grip as welded
            obj.parent = rig.parts[wrist] if wrist else rig.parts[arm]
            obj.matrix_parent_inverse = Matrix.Identity(4)
            obj.matrix_basis = Matrix.Identity(4) if wrist else to_blender(cframe(_GRIP))
            rig.parts[obj.name] = obj
            for slot in obj.material_slots:
                for word, colour in WEAPON_COLOURS:
                    if slot.material and word in slot.material.name:
                        slot.material.diffuse_color = (*colour, 1)
                        break
    return True


def place_root(rig: Rig, frame: int, position, facing, interpolation="LINEAR"):
    """Keys the HumanoidRootPart at a Roblox `position` (feet on the floor + ROOT_HEIGHT), facing a Roblox direction.
    Review only: in the game physics moves the root (the pull and the throw are Knock pushes)."""
    position = Vector(position)
    rig.root.matrix_basis = to_blender(look_at(position, position + Vector(facing)))
    rig.root.keyframe_insert("location", frame=frame)
    rig.root.keyframe_insert("rotation_quaternion", frame=frame)
    _set_interpolation(rig.root, frame, interpolation, "AUTO")


# --- poses -----------------------------------------------------------------------------------------------------------

def transform(rig: Rig, part: str, data) -> Matrix:
    """The Motor6D Transform (Roblox) for a body-space pose `data` = (x, y, z, dx?, dy?, dz?)."""
    x, y, z = data[0], data[1], data[2]
    move = Matrix.Translation(Vector((data[3] if len(data) > 3 else 0, data[4] if len(data) > 4 else 0,
                                      data[5] if len(data) > 5 else 0)))
    pitch = -x if part in LEANS else x
    turn = (Matrix.Rotation(math.radians(pitch), 4, "X") @ Matrix.Rotation(math.radians(y), 4, "Y")
            @ Matrix.Rotation(math.radians(z), 4, "Z"))
    b = rig.bases[part]
    return b.inverted() @ (move @ turn) @ b


def pose_of(rig: Rig, part: str) -> tuple:
    """The body-space pose (x, y, z, dx, dy, dz) a joint holds at the current frame: transform's inverse."""
    b = rig.bases[part]
    m = b @ to_roblox(rig.joints[part].matrix_basis) @ b.inverted()
    x, y, z = (math.degrees(a) for a in m.to_3x3().to_euler("ZYX"))
    move = m.to_translation()
    return (-x if part in LEANS else x, y, z, move.x, move.y, move.z)


def planted(body: dict) -> dict:
    """Legs given against the ground: the torso's lean goes into their pitch, and the torso shifts so the hips stay
    over the feet."""
    out = dict(body)
    torso = list(body.get("Torso", (0, 0, 0)))
    torso += [0] * (6 - len(torso))
    lean = math.radians(torso[0])
    out["Torso"] = (torso[0], torso[1], torso[2], torso[3], torso[4] - (1 - math.cos(lean)), torso[5] - math.sin(lean))
    for leg in LEGS:
        data = list(body.get(leg, (0, 0, 0)))
        data += [0] * (6 - len(data))
        data[0] += torso[0]
        out[leg] = tuple(data)
    return out


def _set_interpolation(obj, frame, interpolation, easing):
    action = obj.animation_data.action if obj.animation_data else None
    if not action:
        return
    for curve in _curves(action):
        for point in curve.keyframe_points:
            if abs(point.co.x - frame) < 1e-3:
                point.interpolation = interpolation
                point.easing = easing
                point.handle_left_type = point.handle_right_type = "AUTO_CLAMPED"


def _curves(action):
    """Every F-curve of an action (Blender 5 keeps them in layered channelbags)."""
    if hasattr(action, "fcurves") and len(getattr(action, "fcurves", [])) > 0:
        return list(action.fcurves)
    curves = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                curves.extend(bag.fcurves)
    return curves


def _key_parts(rig: Rig, frame: int, body: dict, interpolation: str, easing: str):
    for part, data in body.items():
        if part not in rig.joints:
            continue
        joint = rig.joints[part]
        joint.matrix_basis = to_blender(transform(rig, part, data))
        rotation = joint.rotation_quaternion.copy()
        last = rig.last.get(part)
        if last is not None and last.dot(rotation) < 0:
            rotation.negate()  # the same rotation, the short way round
            joint.rotation_quaternion = rotation
        rig.last[part] = rotation
        joint.keyframe_insert("location", frame=frame)
        joint.keyframe_insert("rotation_quaternion", frame=frame)
        _set_interpolation(joint, frame, interpolation, easing)


def key(rig: Rig, frame: int, body: dict, plant=True, interpolation="BEZIER", easing="AUTO", contacts=None) -> dict:
    """Keys a pose at `frame` and returns what was keyed. `body` holds body-space poses for the parts it names.
    Interpolation and easing shape the segment that starts here ("BEZIER" smooth, "BACK" overshoots, "EXPO"/"QUART"
    snap, "SINE" breathes, "CONSTANT" holds).
    - plant: the legs stand against the ground (see planted), and the torso is raised or lowered so the lowest foot
      corner rests exactly on the floor.
    - contacts: {part: (local point, target)} puts a part's point on a Roblox world point, the part's pose in `body`
      being the hint: the torso leans and shifts toward it (lean_to, solved first), then an arm reaches (reach) or the
      head turns (gaze) from the torso as keyed, keeping the hint's roll or tilt."""
    bpy.context.scene.frame_set(frame)
    contacts = dict(contacts or {})
    if "Torso" in contacts:
        local, target = contacts.pop("Torso")
        body = {**body, "Torso": lean_to(rig, local, target, body.get("Torso", (0, 0, 0)))}
    body = planted(body) if plant else dict(body)
    trunk = {part: data for part, data in body.items() if part == "Torso" or part in LEGS}
    _key_parts(rig, frame, trunk, interpolation, easing)
    if plant and "Torso" in body:
        _refresh()
        drop = _lowest_foot(rig) - _floor(rig)
        torso = list(body["Torso"]) + [0] * (6 - len(body["Torso"]))
        torso[4] -= drop
        body["Torso"] = tuple(torso)
        _key_parts(rig, frame, {"Torso": body["Torso"]}, interpolation, easing)
    _refresh()
    for part, (local, target) in contacts.items():
        hint = body.get(part, (0, 0, 0))
        body[part] = gaze(rig, local, target, hint) if part == "Head" else reach(rig, part, local, target, hint)
    rest = {part: data for part, data in body.items() if part != "Torso" and part not in LEGS}
    _key_parts(rig, frame, rest, interpolation, easing)
    return body


def world_point(rig: Rig, part: str, local) -> Vector:
    """Where a point in a part's Roblox local frame is, in Roblox world space (at the current frame)."""
    obj = rig.parts[part]
    return point_to_roblox(obj.matrix_world @ point_to_blender(local))


def _refresh():
    bpy.context.view_layer.update()


def _floor(rig: Rig) -> float:
    root = to_roblox(rig.root.matrix_world)
    return root[1][3] - ROOT_HEIGHT


def _lowest_foot(rig: Rig) -> float:
    return min(world_point(rig, leg, (x, -1, z)).y for leg in LEGS for x in (-0.5, 0.5) for z in (-0.5, 0.5))


def _solve(fk, hint, ranges, steps=((5.0, 1.0, 0.2), (5.0, 1.0, 0.2)), pull=(0.002, 0.002)):
    """A coarse grid, then finer grids around the best, over two values: the pair whose point `fk(a, b)` lands nearest
    its target (fk returns the distance), nudged toward `hint` (by `pull` per unit) so the answer stays close to the
    pose asked for. `steps` gives each value's grid steps, coarse to fine."""
    best = None
    for level in range(3):
        values = []
        for axis in range(2):
            step = steps[axis][level]
            if level == 0:
                low, high = ranges[axis]
                values.append([low + i * step for i in range(int((high - low) / step) + 1)])
            else:
                centre, reach = best[1 + axis], steps[axis][level - 1]
                values.append([centre + i * step for i in range(-int(reach / step), int(reach / step) + 1)])
        for a in values[0]:
            for b in values[1]:
                cost = fk(a, b) + pull[0] * abs(a - hint[0]) + pull[1] * abs(b - hint[1])
                if best is None or cost < best[0]:
                    best = (cost, a, b)
    return best[1], best[2]


def lean_to(rig: Rig, local, target: Vector, hint) -> tuple:
    """The torso's lean (pitch) and sideways shift that bring a torso point (e.g. where the chin sits) to `target`,
    the rest of the pose kept as `hint` and the legs planted."""
    root = to_roblox(rig.root.matrix_world)
    _, c0, c1 = JOINTS["Torso"]
    c0m, c1_inv, point = cframe(c0), cframe(c1).inverted(), Vector((*local, 1))
    base = list(hint) + [0] * (6 - len(hint))

    def distance(pitch, shift):
        pose = planted({"Torso": (pitch, base[1], base[2], shift, base[4], base[5])})["Torso"]
        p = root @ c0m @ transform(rig, "Torso", pose) @ c1_inv @ point
        return (Vector((p.x, p.y, p.z)) - target).length

    pitch, shift = _solve(distance, (base[0], base[3]), ((-10, 60), (-1.0, 1.0)),
                          ((5.0, 1.0, 0.2), (0.1, 0.02, 0.005)), (0.002, 0.05))
    return (round(pitch, 1), base[1], base[2], round(shift, 3), base[4], base[5])


def _joint_frame(rig: Rig, part: str) -> Matrix:
    """The joint's frame (Part0 at the current pose, times C0), Roblox world space."""
    part0, c0, _ = JOINTS[part]
    return to_roblox(rig.parts[part0].matrix_world) @ cframe(c0)


def reach(rig: Rig, part: str, local, target: Vector, hint) -> tuple:
    """Arm angles (pitch, roll, swing) that put the arm's `local` point (Roblox, e.g. the hand: (0, -1, 0)) on the Roblox
    world `target`, with the torso as it stands at the current frame. `hint` (pitch, roll, swing) is the pose asked
    for: its roll is kept and the answer stays near it."""
    frame0, c1_inv, point = _joint_frame(rig, part), cframe(JOINTS[part][2]).inverted(), Vector((*local, 1))
    roll = hint[1]

    def distance(pitch, swing):
        p = frame0 @ transform(rig, part, (pitch, roll, swing)) @ c1_inv @ point
        return (Vector((p.x, p.y, p.z)) - target).length

    pitch, swing = _solve(distance, (hint[0], hint[2]), ((-90, 200), (-150, 150)))
    return (round(pitch, 1), roll, round(swing, 1))


def gaze(rig: Rig, local, target: Vector, hint) -> tuple:
    """Head angles (pitch, turn, tilt) that put the head's `local` point (e.g. the mouth) on `target`, the tilt kept: a
    contact. To look at something, use look: a point of the face aimed at a far target bows the head (the point sits
    above the neck's pivot, so it lines up with the target only once the face tips down, about 45°)."""
    frame0, c1_inv, point = _joint_frame(rig, "Head"), cframe(JOINTS["Head"][2]).inverted(), Vector((*local, 1))
    tilt = hint[2]

    def distance(pitch, turn):
        p = frame0 @ transform(rig, "Head", (pitch, turn, tilt)) @ c1_inv @ point
        return (Vector((p.x, p.y, p.z)) - target).length

    pitch, turn = _solve(distance, (hint[0], hint[1]), ((-70, 80), (-85, 85)))
    return (round(pitch, 1), round(turn, 1), tilt)


def look(rig: Rig, target: Vector, hint) -> tuple:
    """Head angles (pitch, turn, tilt) that point the face at the Roblox world `target` from the head's centre, the tilt
    kept: the eyes on something, the head level when it is level with them."""
    frame0, c1_inv = _joint_frame(rig, "Head"), cframe(JOINTS["Head"][2]).inverted()
    tilt = hint[2]

    def miss(pitch, turn):  # degrees between the face and the target
        head = frame0 @ transform(rig, "Head", (pitch, turn, tilt)) @ c1_inv
        front = head.to_3x3() @ Vector((0, 0, -1))
        return math.degrees(front.angle(Vector(target) - head.to_translation(), 0.0))

    pitch, turn = _solve(miss, (hint[0], hint[1]), ((-70, 80), (-85, 85)))
    return (round(pitch, 1), round(turn, 1), tilt)


def _rest_offset(part: str, local) -> Vector:
    """A point of a limb (its own frame) from its joint, in Part0's frame with the limb at rest."""
    _, c0, c1 = JOINTS[part]
    c0m = cframe(c0)
    return (c0m @ cframe(c1).inverted() @ Vector((*local, 1))).to_3d() - c0m.to_translation()


def aim(rig: Rig, part: str, front, axis=None, point=None, local=(0, -1, 0), keep="front") -> tuple:
    """Limb angles (pitch, turn, swing) from world directions (Roblox), with Part0 as it stands at the current frame: the
    limb's front face toward `front` (an arm's: where the blade's blade points, or the gun's top), and its length
    toward `axis` (an arm's: where the gun's barrel points, out of the fist) or, instead, its `local` point (the hand)
    onto the world `point`. A limb's front and length are square: `keep` says which of the two is kept exactly
    ("front" or "axis"); the other is squared to it."""
    part0, c0, _ = JOINTS[part]
    frame0 = to_roblox(rig.parts[part0].matrix_world)
    inverse = frame0.to_3x3().transposed()  # world to Part0's frame (a rotation)
    f = (inverse @ Vector(front)).normalized()

    def square(a, f):
        if keep == "front":
            return (a - a.dot(f) * f).normalized(), f
        return a, (f - f.dot(a) * a).normalized()

    if point is not None:
        # the limb turns about its joint, so the point lands at pivot + Q·o, Q taking the rest frame (length down,
        # front forward) to (length a, front f): Q·o = o.x (a × f) - o.y a - o.z f, solved for a by fixed point
        o = _rest_offset(part, local)
        d = inverse @ (Vector(point) - (frame0 @ cframe(c0)).to_translation())
        a = d.normalized()
        for _ in range(12):
            a = ((d - o.x * a.cross(f) + o.z * f) / -o.y).normalized()
            a, f = square(a, f)
    else:
        a, f = square((inverse @ Vector(axis)).normalized(), f)
    q = Matrix((a.cross(f), -a, -f)).transposed()  # columns: where the rest right, length and front go
    x, y, z = q.to_euler("ZYX")  # Rx·Ry·Rz, the order of transform's body-space angles
    return (round(math.degrees(x), 2), round(math.degrees(y), 2), round(math.degrees(z), 2))


def _turn(a: Vector, b: Vector, factor: float) -> Vector:
    """Unit vector `a` turned toward `b` by `factor` of the angle between them; past 1 or below 0 it carries on along
    the same great circle."""
    angle = a.angle(b, 0.0)
    if angle < 1e-7:
        return a.copy()
    axis = a.cross(b)
    if axis.length < 1e-9:
        axis = a.orthogonal()
    return (Quaternion(axis.normalized(), angle * factor) @ a).normalized()


def sphere_path(points):
    """A smooth path through directions, u from 0 to len(points) - 1: Catmull-Rom built from great-circle turns
    (Barry and Goldman's pyramid), so it bends at every point with no corner and doesn't rush between them as a path
    through blended vectors does. Held still at both ends."""
    p = [Vector(v).normalized() for v in points]
    ext = [p[0]] + p + [p[-1]]

    def at(u):
        u = min(max(u, 0.0), len(p) - 1.0)
        i = min(int(u), len(p) - 2)
        s = u - i
        p0, p1, p2, p3 = ext[i], ext[i + 1], ext[i + 2], ext[i + 3]
        a1, a2, a3 = _turn(p0, p1, s + 1), _turn(p1, p2, s), _turn(p2, p3, s - 1)
        return _turn(_turn(a1, a2, (s + 1) / 2), _turn(a2, a3, s / 2), s)

    return at


def timed_sweep(axes, fronts, t0: float, t_fast: float, t1: float, fast: int):
    """A limb swept through its key poses (`axes` and `fronts`, as for aim) timed by the angle it travels, so the
    spacing is designed, not left to the keys: still at t0, speeding up to its fastest at t_fast, where it passes key
    pose `fast` (a throw's release, a slash's contact), then easing to a stop at t1. Returns t -> (axis, front)."""
    axis_path, front_path = sphere_path(axes), sphere_path(fronts)
    n = len(axes) - 1
    us = [n * k / 400 for k in range(401)]
    arc = [0.0]
    for u0, u1 in zip(us, us[1:]):
        arc.append(arc[-1] + axis_path(u0).angle(axis_path(u1), 0.0))
    total = arc[-1]
    at_fast = arc[round(400 * fast / n)] / total  # the share of the sweep done at the fast pose
    h1, h2 = t_fast - t0, t1 - t_fast
    # the fast pose's speed (shares a second): fastest exactly there needs at least 1.5x the mean speed on each side,
    # and no backtracking at most 3x
    low, high = 1.5 * max(at_fast / h1, (1 - at_fast) / h2), 3.0 * min(at_fast / h1, (1 - at_fast) / h2)
    speed = 0.5 * (low + high) if low <= high else 0.95 * high

    def share(t):
        if t <= t_fast:
            u = min(max((t - t0) / h1, 0.0), 1.0)
            return (-2 * u ** 3 + 3 * u ** 2) * at_fast + (u ** 3 - u ** 2) * speed * h1
        u = min(max((t - t_fast) / h2, 0.0), 1.0)
        return ((2 * u ** 3 - 3 * u ** 2 + 1) * at_fast + (u ** 3 - 2 * u ** 2 + u) * speed * h2
                + (-2 * u ** 3 + 3 * u ** 2))

    def at(t):
        target = share(t) * total
        k = max(0, min(399, next((j for j, a in enumerate(arc) if a >= target), 400) - 1))
        span = arc[k + 1] - arc[k]
        u = us[k] + (us[k + 1] - us[k]) * ((target - arc[k]) / span if span > 1e-12 else 0.0)
        return axis_path(u), front_path(u)

    at.balanced = low <= high  # False: the fast pose can't be the fastest with these keys (move it or its time)
    return at


EASES = {"smooth": lambda u: u * u * (3 - 2 * u),  # starts and stops still
         "snap": lambda u: 1 - (1 - u) ** 3,  # leaves fast, settles in
         "accel": lambda u: u ** 3,  # gathers speed, arrives fast (a hit)
         "linear": lambda u: u}


def pose_path(keys):
    """A limb from pose to pose, for mechanical beats with a hold between: keys (t, axis, front, ease), each move a
    great-circle turn from the last key's pose to this one, eased as named (EASES) on the way in. Returns
    t -> (axis, front)."""
    times = [k[0] for k in keys]
    axes = [Vector(k[1]).normalized() for k in keys]
    fronts = [Vector(k[2]).normalized() for k in keys]

    def at(t):
        if t <= times[0]:
            return axes[0], fronts[0]
        if t >= times[-1]:
            return axes[-1], fronts[-1]
        i = max(j for j in range(len(times) - 1) if times[j] <= t)
        u = EASES[keys[i + 1][3]]((t - times[i]) / (times[i + 1] - times[i]))
        return _turn(axes[i], axes[i + 1], u), _turn(fronts[i], fronts[i + 1], u)

    return at


def spline(keys):
    """An open curve through (t, value) keys (values tuples): Catmull-Rom between them, still at both ends; a key
    (t, value, rates) passes at those rates a second instead, "still" for none."""
    times = [k[0] for k in keys]
    values = [k[1] for k in keys]
    n = len(keys)

    def tangent(i):
        if keys[i][2:]:
            return tuple(0.0 for _ in values[i]) if keys[i][2] == "still" else keys[i][2]
        if i == 0 or i == n - 1:
            return tuple(0.0 for _ in values[i])
        return tuple((values[i + 1][c] - values[i - 1][c]) / (times[i + 1] - times[i - 1]) for c in range(len(values[i])))

    def at(t):
        t = min(max(t, times[0]), times[-1])
        i = max(j for j in range(n - 1) if times[j] <= t)
        t0, t1 = times[i], times[i + 1]
        h = t1 - t0
        u = (t - t0) / h
        h00, h10, h01, h11 = 2 * u ** 3 - 3 * u ** 2 + 1, u ** 3 - 2 * u ** 2 + u, -2 * u ** 3 + 3 * u ** 2, u ** 3 - u ** 2
        m0, m1 = tangent(i), tangent(i + 1)
        return tuple(h00 * values[i][c] + h10 * h * m0[c] + h01 * values[i + 1][c] + h11 * h * m1[c]
                     for c in range(len(values[i])))

    return at


def keyed(times, *tracks):
    """Directions through keys, each passed at its time, still at the first and the last: each track a list of
    directions (one per time) along a smooth great-circle path (sphere_path), all timed by one curve through
    (time, index). Returns t -> one direction per track."""
    paths = [sphere_path(track) for track in tracks]
    index = spline([(t, (float(i),)) for i, t in enumerate(times)])
    return lambda t: tuple(path(index(t)[0]) for path in paths)


def move(points, t0, t1, ease="smooth"):
    """A direction along the smooth path through `points` (sphere_path) from t0 to t1, spaced by the angle it travels
    through `ease` (EASES): t -> direction."""
    path = sphere_path(points)
    n = len(points) - 1
    us = [n * k / 240 for k in range(241)]
    arc = [0.0]
    for a, b in zip(us, us[1:]):
        arc.append(arc[-1] + path(a).angle(path(b), 0.0))
    total = arc[-1]
    ease = EASES[ease]

    def at(t):
        if total < 1e-9:
            return path(0.0)
        target = ease(min(max((t - t0) / (t1 - t0), 0.0), 1.0)) * total
        k = max(0, min(239, next((j for j, a in enumerate(arc) if a >= target), 240) - 1))
        span = arc[k + 1] - arc[k]
        return path(us[k] + (us[k + 1] - us[k]) * ((target - arc[k]) / span if span > 1e-12 else 0.0))

    return at


def flowing(points, knots):
    """A direction along the smooth path through `points` (sphere_path), timed by knots (t, point, speed): at t it
    passes points[point] moving on along the path at `speed` degrees a second (None: the pace between the knots either
    side), and between knots the angle travelled is a cubic in time, so it slows and quickens smoothly and stops only at
    a knot whose speed is 0. Returns t -> direction; its `backtracks` is how far it ever runs back along the path
    (degrees): 0 unless a knot's speed is too fast for the span after it."""
    path = sphere_path(points)
    steps = 60  # samples a segment, for the angle travelled
    us = [k / steps for k in range((len(points) - 1) * steps + 1)]
    arc = [0.0]
    for a, b in zip(us, us[1:]):
        arc.append(arc[-1] + path(a).angle(path(b), 0.0))
    times = [t for t, _, _ in knots]
    angles = [arc[point * steps] for _, point, _ in knots]
    speeds = []
    for i, (_, _, speed) in enumerate(knots):
        before, after = max(i - 1, 0), min(i + 1, len(knots) - 1)
        speeds.append((angles[after] - angles[before]) / (times[after] - times[before]) if speed is None
                      else math.radians(speed))

    def travelled(t):
        t = min(max(t, times[0]), times[-1])
        i = max(j for j in range(len(times) - 1) if times[j] <= t)
        h = times[i + 1] - times[i]
        u = (t - times[i]) / h
        return ((2 * u ** 3 - 3 * u ** 2 + 1) * angles[i] + (u ** 3 - 2 * u ** 2 + u) * h * speeds[i]
                + (-2 * u ** 3 + 3 * u ** 2) * angles[i + 1] + (u ** 3 - u ** 2) * h * speeds[i + 1])

    def at(t):
        target = min(max(travelled(t), 0.0), arc[-1])
        k = max(0, min(len(arc) - 2, bisect.bisect_left(arc, target) - 1))
        span = arc[k + 1] - arc[k]
        return path(us[k] + (us[k + 1] - us[k]) * ((target - arc[k]) / span if span > 1e-12 else 0.0))

    samples = [travelled(times[0] + (times[-1] - times[0]) * k / 4000) for k in range(4001)]
    at.backtracks = math.degrees(max(0.0, max(a - b for a, b in zip(samples, samples[1:]))))
    return at


def stand(rig: Rig, part: str, target, hint, local=(0, -1, 0), move=(0, 0, 0)) -> tuple:
    """Leg angles (pitch, turn, swing) that put the leg's `local` point (the sole's middle) over the world `target`'s
    x and z, with Part0 as it stands at the current frame; the height is left to the torso (see sole). `hint` gives the
    turn, kept, and the start; `move` is the joint's own move, which the leg stands with. Newton steps on the two angles."""
    part0, c0, c1 = JOINTS[part]
    frame0 = to_roblox(rig.parts[part0].matrix_world) @ cframe(c0)
    c1_inv, point, target = cframe(c1).inverted(), Vector((*local, 1)), Vector(target)
    pitch, turn, swing = hint[0], hint[1], hint[2]

    def miss(p, s):
        q = frame0 @ transform(rig, part, (p, turn, s, *move)) @ c1_inv @ point
        return Vector((q.x - target.x, q.z - target.z))

    for _ in range(12):
        m = miss(pitch, swing)
        if m.length < 1e-5:
            break
        h = 0.01
        dp, ds = (miss(pitch + h, swing) - m) / h, (miss(pitch, swing + h) - m) / h
        det = dp.x * ds.y - ds.x * dp.y
        if abs(det) < 1e-9:
            break
        pitch -= (m.x * ds.y - ds.x * m.y) / det
        swing -= (dp.x * m.y - m.x * dp.y) / det
    return (round(pitch, 3), turn, round(swing, 3))


def two_bone(hip: Vector, foot: Vector, toward: Vector, bone=1.0) -> tuple:
    """Where a knee sits on two equal bones from `hip` to `foot`, pushed out toward `toward`: (the knee, the foot as far as
    the leg reaches, the way it was pushed, square to the leg's line)."""
    along = (foot - hip).normalized()
    reach = min((foot - hip).length, 2 * bone * 0.9995)
    side = (toward - along * toward.dot(along)).normalized()
    return hip + along * (reach / 2) + side * math.sqrt(bone * bone - (reach / 2) ** 2), hip + along * reach, side


def bend_leg(rig: Rig, frame: int, leg: str, foot, toward, turned_out=False) -> dict:
    """Keys a leg and its knee at `frame`, the torso as keyed there (refreshed): the sole over `foot` (Roblox world), its lowest
    corner at foot's height, since a leaning shin with no ankle stands on an edge, and the knee toward `toward` (world).
    R6's hip pivot sits on the leg's outer top edge, so the hip's line moves with the thigh's turn: a few rounds settle it. As a
    rule the leg swings from the torso with no turn about its own length, as any R6 leg does, and the shin folds from it in any
    direction. `turned_out` squares the leg to the knee's hinge instead, its Z on the hinge and the shin folding to its inner
    side, whatever the torso's lean: a thigh level at the side, whose box hangs under the pivot. Returns the knee's bend, the
    thigh below level, the shin's lean, in degrees, and the gap, in studs, between `foot` and what the leg reaches on the floor."""
    part0, c0, c1 = JOINTS[leg]
    torso = to_roblox(rig.parts[part0].matrix_world)
    hinge = torso @ cframe(c0)
    pivot, at = hinge.to_translation(), cframe(c1).to_translation()  # the hip's pivot in the world, and in the leg's frame
    target, toward = Vector(foot), Vector(toward)
    rest = turned = torso.to_3x3()
    hanging = rest @ Vector((0, -1, 0))
    inner = -1 if leg == "Right Leg" else 1  # the leg's X toward the body's middle, for a shin folding that way
    for _ in range(16):
        hip = pivot + turned @ (Vector((0, 1, 0)) - at)  # the middle of the leg's top face, where the thigh's bone starts
        knee, reached, side = two_bone(hip, target, toward)
        thigh, shin = (knee - hip).normalized(), (reached - knee).normalized()
        if turned_out:
            side_on = (shin - thigh * shin.dot(thigh)).normalized() * inner
            turned = Matrix((side_on, -thigh, side_on.cross(-thigh))).transposed()
        else:
            turned = hanging.rotation_difference(thigh).to_matrix() @ rest
        lower = thigh.rotation_difference(shin).to_matrix() @ turned
        low = min((reached + lower @ Vector((x, 0, z))).y for x in (-0.5, 0.5) for z in (-0.5, 0.5))
        target.y += foot[1] - low
    world = Matrix.Translation(pivot - turned @ at) @ turned.to_4x4()
    pose = (hinge.inverted() @ world @ cframe(c1)).to_3x3().to_4x4()
    key_matrices(rig, frame, {leg: to_blender(pose), rig.knees[leg]: to_blender((turned.inverted() @ lower).to_4x4())})
    return {"bend": math.degrees(thigh.angle(shin)), "thigh": math.degrees(math.asin(max(-1, min(1, -thigh.y)))),
            "shin": math.degrees(shin.angle(Vector((0, -1, 0)))), "gap": (Vector(foot) - reached).xz.length}


def sole(rig: Rig, part: str) -> float:
    """The height (Roblox world y) of a leg's lowest sole corner, at the current frame; past a knee, the shin's."""
    shin = rig.knees.get(part)
    return min(world_point(rig, shin or part, (x, -0.5 if shin else -1, z)).y for x in (-0.5, 0.5) for z in (-0.5, 0.5))


def grip(rig: Rig, arm: str) -> Matrix:
    """A hand's grip frame (Roblox, world), where a weapon's Grip sits as the game welds it (Simulation/Equipment),
    turned by the wrist on a rig that has one."""
    wrist = rig.wrists.get(arm)
    if wrist:
        return to_roblox(rig.joints[wrist].matrix_world)
    return to_roblox(rig.parts[arm].matrix_world) @ cframe(_GRIP)


def hand(rig: Rig, arm: str) -> Matrix:
    """A hand's own grip frame (Roblox, world), before any wrist: where the fist is, holding its weapon or not (a cast
    leaves from it; a stowed weapon is laid down and picked up there)."""
    return to_roblox(rig.parts[arm].matrix_world) @ cframe(_GRIP)


def _square_face(a: Vector) -> Vector:
    """The front of an arm along `a` (Part0's frame) with its front and back faces square to the torso's side."""
    side = math.hypot(a.y, a.z)
    return Vector((0, -a.z / side, a.y / side)) if side > 1e-6 else Vector((0, 0, -1))


def swing(rig: Rig, frame: int, arm: str, axis, move=None):
    """Keys an arm along `axis` (world, shoulder to fist) at `frame`, with Part0 as it stands: swung out and pitched with
    its front and back faces kept square to the torso's side, never twisted about its length (wield's arm; alone, an
    empty hand's). An R6 arm turns on its inner face, so swung inward, across the chest, the corner below its shoulder
    sinks into the chest: the torso's twist carries a hand across instead. `move` (body space, studs) shifts the
    shoulder, e.g. back as it gives to a kick."""
    part0 = JOINTS[arm][0]
    torso = to_roblox(rig.parts[part0].matrix_world).to_3x3()
    length = Vector(axis).normalized()
    face = _square_face(torso.transposed() @ length)  # in the torso's frame
    pose = aim(rig, arm, torso @ face, axis=length, keep="axis")
    key(rig, frame, {arm: pose + tuple(move) if move else pose}, plant=False, interpolation="LINEAR")
    _refresh()


def reach_axis(rig: Rig, arm: str, point) -> Vector:
    """The axis (world, shoulder to fist) of a swung arm (swing) whose hand, its grip point, lands on the Roblox world
    `point`, with Part0 as it stands; out of reach, the nearest it gets."""
    part0, c0, _ = JOINTS[arm]
    frame0 = to_roblox(rig.parts[part0].matrix_world)
    o = _rest_offset(arm, _GRIP[:3])
    d = frame0.to_3x3().transposed() @ (Vector(point) - (frame0 @ cframe(c0)).to_translation())
    a = d.normalized()
    for _ in range(40):  # aim's fixed point, the front squared each round
        f = _square_face(a)
        a = ((d - o.x * a.cross(f) + o.z * f) / -o.y).normalized()
    return frame0.to_3x3() @ a


def stow_frame(rig: Rig, arm: str) -> Matrix:
    """Where the arm's weapon rides stowed (r6rig.STOWS): its grip frame, Roblox world, on Part0 as it stands."""
    point, length, top = (Vector(v) for v in STOWS[WRISTS[arm][1]])
    along, up = (Vector(v) for v in WEAPON_AXES[arm])
    length.normalize()
    top = (top - top.dot(length) * length).normalized()
    stowed = Matrix((length, top, length.cross(top))).transposed()  # columns: the weapon's length, top, their cross
    own = Matrix((along, up, along.cross(up))).transposed()  # the same in its grip frame
    m = (stowed @ own.transposed()).to_4x4()
    m.translation = point
    return to_roblox(rig.parts[JOINTS[arm][0]].matrix_world) @ m


def stow(rig: Rig, frame: int, arm: str) -> float:
    """Keys the arm's wrist at `frame` so its weapon rides at its stow (r6rig.STOWS) on Part0 as it stands, wherever the
    hand is: the wrist's Transform carries it off the hand, as the game's Motor6D does. Key it every frame the hand is
    away (between keys a Transform is interpolated, not the weapon's place). Returns how far the weapon is off the hand
    (studs): about 0 when the hand lays it down or picks it up."""
    away = hand(rig, arm).inverted() @ stow_frame(rig, arm)
    key_matrices(rig, frame, {rig.wrists[arm]: to_blender(away)})
    _refresh()
    return away.to_translation().length


def wield(rig: Rig, frame: int, arm: str, axis, aim_at, top=None, move=None):
    """Keys an arm and its wrist holding a weapon at `frame`, with Part0 as it stands. The arm goes along `axis`
    (world, shoulder to fist) as swing keys it: never twisted about its length, since a twisted arm, or one swung along
    the shortest arc toward a diagonal, turns a corner below the shoulder into the chest. The wrist then points the
    weapon's length (r6rig.WEAPON_AXES: the blade's blade, the gun's barrel) along `aim_at` (world): the hand turns
    about the forearm, then bends, as a wrist does. Given `top` (world), the weapon then rolls about its length until
    its top faces as near that as it can (a gun's cant); `move` shifts the shoulder (swing). Needs a rig built with
    wrists. Returns the wrist's turn about the forearm and its bend, in degrees."""
    swing(rig, frame, arm, axis, move)
    return aim_wrist(rig, frame, arm, aim_at, top)


def aim_wrist(rig: Rig, frame: int, arm: str, aim_at, top=None):
    """Keys only the arm's wrist at `frame`, the arm as it stands (keyed by swing, or by the control rig's bake):
    the weapon's length along `aim_at` (world), its top toward `top`, as wield aims it. Returns the wrist's turn about
    the forearm and its bend, in degrees."""
    base = to_roblox(rig.parts[arm].matrix_world).to_3x3() @ cframe(_GRIP).to_3x3()  # the grip before the wrist
    along, up = (Vector(v) for v in WEAPON_AXES[arm])
    b = (base.transposed() @ Vector(aim_at)).normalized()
    # wrist = Rz(turn) · Rx(bend): the turn about the forearm (the grip's Z), then the bend, solved so wrist·along = b
    if along.y > 0.5:  # the length is the hand's front (+Y): b = (-sin t cos e, cos t cos e, sin e)
        bend = math.asin(max(-1.0, min(1.0, b.z)))
        turn = math.atan2(-b.x, b.y) if abs(b.z) < 0.9999 else 0.0
    else:  # the length runs down the forearm (-Z): b = (-sin t sin e, cos t sin e, -cos e)
        bend = math.acos(max(-1.0, min(1.0, -b.z)))
        turn = math.atan2(-b.x, b.y) if math.sin(bend) > 1e-4 else 0.0
    wrist = Matrix.Rotation(turn, 3, "Z") @ Matrix.Rotation(bend, 3, "X")
    kept = rig.wrists_kept.get(arm) if rig.wrists_kept is not None else None
    if kept is not None and top is None:
        over = math.pi - bend if along.y > 0.5 else -bend  # the same aim from the far side of the forearm's line
        wrist = _kept_hand(kept, wrist, Matrix.Rotation(turn + math.pi, 3, "Z") @ Matrix.Rotation(over, 3, "X"), along, b)
    if top is not None:  # roll about the weapon's own length, its top as near `top` as the length allows
        want = base.transposed() @ Vector(top)
        want = want - want.dot(b) * b
        have = wrist @ up
        if want.length > 1e-6 and have.length > 1e-6:
            angle = have.angle(want, 0.0)
            sign = 1.0 if have.cross(want).dot(b) >= 0 else -1.0
            wrist = Matrix.Rotation(sign * angle, 3, b) @ wrist
    if rig.wrists_kept is not None:
        rig.wrists_kept[arm] = wrist.copy()
    key_matrices(rig, frame, {rig.wrists[arm]: to_blender(wrist.to_4x4())})
    _refresh()
    return math.degrees(turn), math.degrees(bend)


def _kept_hand(last: Matrix, wrist: Matrix, over: Matrix, along: Vector, b: Vector) -> Matrix:
    """A wrist aiming along `b`, its roll kept: with the weapon near the forearm's line the turn that solves it is the
    weapon's roll, and it jumps as the aim goes by (half a turn at the line itself). There the hand stays as it was, moved
    along the shortest arc to the new aim; from 5 to 25 degrees off the line it eases onto the solved wrist, `wrist` or its
    twin from the line's far side `over`, whichever is nearer."""
    moved = (last @ along).rotation_difference(b).to_matrix() @ last
    near = max(wrist, over, key=lambda m: sum(m.col[i].dot(moved.col[i]) for i in range(3)))
    off = math.degrees(math.acos(min(abs(b.z), 1.0)))
    return moved.to_quaternion().slerp(near.to_quaternion(), EASES["smooth"](min(max((off - 5.0) / 20.0, 0.0), 1.0))).to_matrix()


def path_dots(rig: Rig, frames, points, colour=(1.0, 0.82, 0.25), radius=0.05, name="Path", at=None) -> list:
    """For review sheets: one small glowing sphere per frame at each weapon point of `points` ((arm, local point in
    the grip frame) pairs, e.g. ("Right Arm", HELD_TIP), ("Left Arm", MUZZLE)), where it is at that frame, so one
    render shows the whole arc and its spacing (one dot per frame).
    `at` (rig, arm) -> frame picks the frame the points are in: the grip (the weapon) unless given, e.g. `hand`.
    On a travelling loop the dots follow the body, as on a treadmill: each is carried back by how far the root has
    moved since the first frame, so the arcs show around the body. Returns the spheres: delete them once the sheet is
    rendered."""
    scene = bpy.context.scene
    material = flat_material(f"{name}Dot", colour, emission=colour)
    frames = list(frames)
    scene.frame_set(frames[0])
    home = to_roblox(rig.root.matrix_world).to_translation()
    made = []
    for f in frames:
        scene.frame_set(f)
        travel = to_roblox(rig.root.matrix_world).to_translation() - home
        for arm, local in points:
            dot = bl.sphere(f"{name}.{arm}.{f}", radius, 10, 6, material)
            dot.location = point_to_blender(((at or grip)(rig, arm) @ Vector((*local, 1))).to_3d() - travel)
            made.append(dot)
    return made


def outside(rig: Rig, part: str, point: Vector) -> float:
    """How far a world point (Roblox) is outside a body part's box as drawn (drawn: the head as the game draws it), in
    studs, at the current frame (negative: inside)."""
    local = to_roblox(rig.parts[part].matrix_world).inverted() @ point
    half = [s / 2 for s in drawn(part)]
    d = [abs(local[i]) - half[i] for i in range(3)]
    out = Vector([max(v, 0.0) for v in d]).length
    return out if out > 0 else max(d)


def mean_pose(rig: Rig, frames) -> dict:
    """Every joint's body-space pose averaged over frames: an idle as it stands, without its breath."""
    scene = bpy.context.scene
    total = {part: [0.0] * 6 for part in PARTS}
    for f in frames:
        scene.frame_set(f)
        for part in PARTS:
            for i, v in enumerate(pose_of(rig, part)):
                total[part][i] += v
    return {part: tuple(round(v / len(frames), 4) for v in values) for part, values in total.items()}


# --- staging and review --------------------------------------------------------------------------------------------

def stage(scene, fps=30, size=(960, 540)):
    """Dusk on a stone floor: a cold moon key, a warm rim and a violet fill (the game's mood), Workbench-fast."""
    scene.render.fps = fps
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "MATERIAL"
    shading.show_shadows = True
    shading.show_cavity = True
    shading.cavity_type = "BOTH"
    shading.show_object_outline = True
    shading.object_outline_color = (0.02, 0.01, 0.03)
    shading.background_type = "VIEWPORT"
    shading.background_color = (0.10, 0.07, 0.14)
    scene.display.shadow_focus = 0.6
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("Dusk")
    world.color = (0.10, 0.07, 0.14)
    scene.world = world
    floor = bl.box("Floor", (60, 60, 0.2), flat_material("Floor", (0.16, 0.14, 0.17)))
    floor.location = (0, 0, -0.1)


CAMERA_CONFIG = "src/shared/Config/Camera.luau"


def game_camera() -> dict:
    """The game camera's numbers, read from Config.Camera so the preview frames a clip as players see it: the
    distance, the focus over the root, the shoulder offset, the FOVs, and the pitch it was framed for (LockPitchBias,
    the look down its comment measures BaseFov at)."""
    numbers = {key: luau_number(CAMERA_CONFIG, key)
               for key in ("Distance", "FocusHeight", "ShoulderOffset", "BaseFov", "SprintFov")}
    numbers["Pitch"] = luau_degrees(CAMERA_CONFIG, "LockPitchBias")
    return numbers


def player_camera(scene, rig: Rig, frame: int, fov=None, yaw=0.0, pitch=None, distance=None, shoulder=None,
                  name="PlayerCamera"):
    """The game's camera (CameraController: CFrame.fromEulerAnglesYXZ(pitch, yaw), offset (ShoulderOffset, 0,
    Distance) from the focus FocusHeight over the root) behind the rig's root at `frame`, turned `yaw` degrees from
    where it faces. Every number left out is Config.Camera's (game_camera); the FOV is vertical, as Roblox's."""
    game = game_camera()
    fov = game["BaseFov"] if fov is None else fov
    pitch = game["Pitch"] if pitch is None else pitch
    distance = game["Distance"] if distance is None else distance
    shoulder = game["ShoulderOffset"] if shoulder is None else shoulder
    scene.frame_set(frame)
    root = to_roblox(rig.root.matrix_world)
    position = Vector((root[0][3], root[1][3], root[2][3]))
    look = Vector((-root[0][2], -root[1][2], -root[2][2]))
    heading = math.atan2(-look.x, -look.z) + math.radians(yaw)
    rotation = (Matrix.Rotation(heading, 4, "Y") @ Matrix.Rotation(math.radians(pitch), 4, "X"))
    focus = position + Vector((0, game["FocusHeight"], 0))
    offset = rotation @ Vector((shoulder, 0, distance, 0))
    eye = focus + Vector((offset.x, offset.y, offset.z))
    target = eye + (rotation @ Vector((0, 0, -1, 0))).to_3d()
    return fixed_camera(scene, eye, target, fov, name)


def player_view(scene, rig: Rig, frame: int, fov=40.0):
    """The game's camera (player_camera, Config.Camera's numbers) closed in on the body: the same eye, turned onto the
    body's middle with a narrow lens, so the body is seen exactly as the player sees it, larger."""
    eye = point_to_roblox(player_camera(scene, rig, frame, name=f"Eye{frame}").location)
    root = to_roblox(rig.root.matrix_world).to_translation()
    return fixed_camera(scene, eye, root + Vector((0, -0.6, 0)), fov, f"Player{frame}")


def fixed_camera(scene, eye, target, fov=50.0, name="Camera"):
    """A camera at Roblox point `eye` looking at Roblox point `target`, with a vertical FOV."""
    data = bpy.data.cameras.new(name)
    data.sensor_fit = "VERTICAL"
    data.angle_y = math.radians(fov)
    camera = bpy.data.objects.new(name, data)
    scene.collection.objects.link(camera)
    eye_b, target_b = point_to_blender(eye), point_to_blender(target)
    camera.location = eye_b
    camera.rotation_euler = (target_b - eye_b).to_track_quat("-Z", "Y").to_euler()
    return camera


def render_sheet(scene, camera, frames, path: Path, columns=6):
    """Renders `frames` from `camera` and tiles them into one contact sheet (left to right, top to bottom), each stamped
    with its time."""
    import numpy as np
    scene.camera = camera
    scene.render.use_stamp = True
    scene.render.use_stamp_date = scene.render.use_stamp_render_time = scene.render.use_stamp_camera = False
    scene.render.use_stamp_lens = scene.render.use_stamp_scene = scene.render.use_stamp_filename = False
    scene.render.use_stamp_frame = scene.render.use_stamp_time = False
    scene.render.use_stamp_note = True
    scene.render.stamp_font_size = 22
    tiles = []
    for frame in frames:
        scene.frame_set(frame)
        scene.render.stamp_note_text = f"{(frame - scene.frame_start) / scene.render.fps:.2f} s"
        tile = path.with_name(f"{path.stem}_{frame:04d}.png")
        scene.render.filepath = str(tile)
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(str(tile))
        w, h = image.size
        tiles.append(np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4))
        bpy.data.images.remove(image)
        tile.unlink()
    h, w = tiles[0].shape[:2]
    rows = math.ceil(len(tiles) / columns)
    sheet = np.zeros((rows * h, columns * w, 4), dtype=np.float32)
    for i, tile in enumerate(tiles):
        r, c = divmod(i, columns)
        y0 = (rows - 1 - r) * h  # Blender images start at the bottom row
        sheet[y0:y0 + h, c * w:(c + 1) * w] = tile
    out = bpy.data.images.new(path.stem, columns * w, rows * h, alpha=True)
    out.pixels = sheet.ravel()
    out.filepath_raw = str(path)
    out.file_format = "PNG"
    out.save()
    return path


def body_camera(scene, rig: Rig, frame: int, azimuth: float, elevation=8.0, distance=13.0, fov=38.0, height=2.6,
                name="BodyCamera"):
    """A camera around the rig's root as it stands at `frame`: `azimuth` degrees from its front (90 = its right side,
    180 = behind), `elevation` degrees up, `distance` studs from a point `height` studs over the floor."""
    scene.frame_set(frame)
    root = to_roblox(rig.root.matrix_world)
    position = Vector((root[0][3], root[1][3], root[2][3]))
    look = Vector((-root[0][2], -root[1][2], -root[2][2]))
    side = look.cross(Vector((0, 1, 0))).normalized()  # the body's right
    a, e = math.radians(azimuth), math.radians(elevation)
    focus = position + Vector((0, height - ROOT_HEIGHT, 0))
    eye = focus + (look * math.cos(a) + side * math.sin(a)) * distance * math.cos(e) + Vector((0, distance * math.sin(e), 0))
    return fixed_camera(scene, eye, focus, fov, name)


def render_shots(scene, shots, path: Path, columns=4):
    """Like render_sheet, for shots from different cameras: (camera, frame, label) each, the label stamped on its tile."""
    import numpy as np
    scene.render.use_stamp = True
    scene.render.use_stamp_date = scene.render.use_stamp_render_time = scene.render.use_stamp_camera = False
    scene.render.use_stamp_lens = scene.render.use_stamp_scene = scene.render.use_stamp_filename = False
    scene.render.use_stamp_frame = scene.render.use_stamp_time = False
    scene.render.use_stamp_note = True
    scene.render.stamp_font_size = 22
    tiles = []
    for camera, frame, label in shots:
        scene.camera = camera
        scene.frame_set(frame)
        scene.render.stamp_note_text = label
        tile = path.with_name(f"{path.stem}_{len(tiles):03d}.png")
        scene.render.filepath = str(tile)
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(str(tile))
        w, h = image.size
        tiles.append(np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4))
        bpy.data.images.remove(image)
        tile.unlink()
    h, w = tiles[0].shape[:2]
    rows = math.ceil(len(tiles) / columns)
    sheet = np.zeros((rows * h, columns * w, 4), dtype=np.float32)
    for i, tile in enumerate(tiles):
        r, c = divmod(i, columns)
        y0 = (rows - 1 - r) * h
        sheet[y0:y0 + h, c * w:(c + 1) * w] = tile
    out = bpy.data.images.new(path.stem, columns * w, rows * h, alpha=True)
    out.pixels = sheet.ravel()
    out.filepath_raw = str(path)
    out.file_format = "PNG"
    out.save()
    return path


def review_pack(scene, rig: Rig, path: Path, beats, camera, bare=None, strip=(), notes="", undress=None) -> Path:
    """One review pack a delivery, read by the maker, the content check and research alike. `path`.png holds, top to bottom: the
    key beats [(frame, label)] from `camera(frame)` in one row under 2,576 px; the same beats on the bare rig (weapons
    hidden, as Roblox moderates an upload) from the body's `bare` azimuth; the `strip` frames at 64 px, the read at play
    distance. `path`.txt holds `notes`, the checks' and the audit's numbers as text. The full sheets are opened only when
    a number flags one. `undress(True)` / `undress(False)`, if given, strips a costume to the bare rig for its row and
    puts it back (a character drawn by a costume over hidden R6 parts, as the Creature)."""
    import numpy as np
    width = min(360, 2520 // max(1, len(beats)))
    height = round(width * 7 / 6)

    def row(shots, w, h, name):
        scene.render.resolution_x, scene.render.resolution_y = w, h
        tmp = path.with_name(f"{path.name}_{name}.png")
        render_shots(scene, shots, tmp, columns=len(shots))
        image = bpy.data.images.load(str(tmp))
        pixels = np.array(image.pixels[:], dtype=np.float32).reshape(image.size[1], image.size[0], 4)
        bpy.data.images.remove(image)
        tmp.unlink()
        return pixels

    rows = [row([(camera(f), f, label) for f, label in beats], width, height, "beats")]
    if bare is not None:
        held = [obj for name, obj in rig.parts.items() if name not in PARTS + tuple(rig.knees.values())]
        for obj in held:
            obj.hide_render = True
        if undress:
            undress(True)
        rows.append(row([(body_camera(scene, rig, f, bare, name=f"PackBare{f}"), f, f"{label} | bare") for f, label in beats],
                        width, height, "bare"))
        if undress:
            undress(False)
        for obj in held:
            obj.hide_render = False
    frames = list(strip)
    if frames:
        rows.append(row([(camera(f), f, "") for f in frames], 56, 64, "strip"))
    full = max(r.shape[1] for r in rows)
    rows = [np.concatenate([r, np.zeros((r.shape[0], full - r.shape[1], 4), dtype=np.float32)], axis=1) for r in rows]
    sheet = np.concatenate(list(reversed(rows)), axis=0)  # Blender's rows run bottom to top
    image = bpy.data.images.new(path.name, sheet.shape[1], sheet.shape[0], alpha=True)
    image.pixels = sheet.ravel()
    image.filepath_raw = str(path.with_suffix(".png"))
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)
    path.with_suffix(".txt").write_text(notes, encoding="utf-8")
    return path.with_suffix(".png")


# --- what the game shows: a one-shot over a loop ---------------------------------------------------------------------

def sample(rig: Rig, frame: float) -> dict:
    """Every joint's Motor6D transform (Blender space) at a frame, sub-frames allowed."""
    whole = math.floor(frame)
    bpy.context.scene.frame_set(int(whole), subframe=frame - whole)
    return {part: rig.joints[part].matrix_basis.copy() for part in PARTS + tuple(j for _, j in rig.extra_joints())}


def mix(a: Matrix, b: Matrix, w: float) -> Matrix:
    """`w` of the way from one Transform to another, its turn along the shortest arc: for authoring (a pose between two),
    never for what the game shows when tracks fade, which `blend` stacks as Roblox does."""
    la, ra, _ = a.decompose()
    lb, rb, _ = b.decompose()
    return Matrix.Translation(la.lerp(lb, w)) @ ra.slerp(rb, w).to_matrix().to_4x4()


def blend(tracks) -> Matrix:
    """One joint as Roblox blends the tracks playing on it (measured, within 0.003°:
    tools/studio/Animations/Parity.luau): `tracks` are (Transform, weight) from the highest priority down. Each takes as
    its share as much of its weight as the tracks above it left; the turns are summed as quaternions by those shares and
    normalized, the moves summed by them. Under less than a whole weight in all, the rest pose takes the rest: the turn
    scales with the total, as a single track's does over no track at all. It equals a chain of slerps whenever every
    weight is 0 or 1, and differs inside fades."""
    left, shares = 1.0, []
    for m, w in tracks:
        share = min(max(w, 0.0), left)
        if share > 0.0:
            shares.append((m, share))
            left -= share
    if not shares:
        return Matrix.Identity(4)
    turn, move, first = Quaternion((0.0, 0.0, 0.0, 0.0)), Vector(), None
    for m, share in shares:
        loc, rot, _ = m.decompose()
        if first is None:
            first = rot
        elif first.dot(rot) < 0:
            rot = -rot  # the same turn, the short way round
        turn = turn + rot * share  # mathutils scales a quaternion's components
        move = move + loc * share
    turn.normalize()
    if left > 1e-9:
        turn = Quaternion().slerp(turn, 1.0 - left)
    return Matrix.Translation(move) @ turn.to_matrix().to_4x4()


def _tracks(rig: Rig, under) -> list:
    """What plays under the one-shots, as (pose, weight) from the highest priority down: a frame of a loop, a pose
    (part -> Transform), or a list of either with its weight (loops crossfading, the higher first)."""
    pairs = under if isinstance(under, list) else [(under, 1.0)]
    return [(pose if isinstance(pose, dict) else sample(rig, pose), w) for pose, w in pairs]


def key_matrices(rig: Rig, frame: int, matrices: dict):
    """Keys each joint's Motor6D transform (Blender space) as given, LINEAR, its quaternion kept continuous."""
    for part, m in matrices.items():
        joint = rig.joints[part]
        joint.matrix_basis = m
        rotation = joint.rotation_quaternion.copy()
        last = rig.last.get(part)
        if last is not None and last.dot(rotation) < 0:
            rotation.negate()
            joint.rotation_quaternion = rotation
        rig.last[part] = rotation
        joint.keyframe_insert("location", frame=frame)
        joint.keyframe_insert("rotation_quaternion", frame=frame)
        _set_interpolation(joint, frame, "LINEAR", "AUTO")


def blend_over(rig: Rig, start: int, base, clip_start: int, duration: float, fps: int, fade_in: float,
               fade_out: float, at=0.2, tail=0.4, speed=0.0, torso=True, weights=None) -> int:
    """Keys from `start` what the game shows when a one-shot clip (keyed from frame `clip_start`, `duration` seconds
    long) plays over a loop (base(seconds) -> the loop's frame, or what `_tracks` takes): the clip starts `at` seconds
    in, fading in and out per joint as Play(fade_in) and Stop(fade_out) do, stacked as Roblox does (`blend`). The legs
    stay the loop's (a clip exported at legs weight 0), the torso is the clip's unless `torso` is False; `weights` (part
    -> the clip's weight, as exported) overrides both. The root moves at `speed`. Returns the last frame."""
    duration = round(duration * fps) / fps  # a clip lasts whole frames, as exported (1.74 s is 1.7333)
    seconds = at + duration + fade_out + tail
    count = round(seconds * fps)
    share = weights or {part: 0.0 if part in LEGS or (part == "Torso" and not torso) else 1.0 for part in PARTS}
    share = dict(share, **{wrist: share.get(arm, 0.0) for arm, wrist in rig.extra_joints()})  # a wrist: its arm's
    frames = []
    for n in range(count + 1):
        s = n / fps
        t = min(max(s - at, 0.0), duration)
        w = min(max((s - at) / fade_in, 0.0), 1.0) * (1.0 - min(max((s - at - duration) / fade_out, 0.0), 1.0))
        clip = sample(rig, clip_start + t * fps)
        under = _tracks(rig, base(s))
        frames.append({part: blend([(clip[part], share.get(part, 0.0) * w)] + [(p[part], u) for p, u in under])
                       for part in clip})
    for n, matrices in enumerate(frames):
        key_matrices(rig, start + n, matrices)
    place_root(rig, start, (0, ROOT_HEIGHT, 0), (0, 0, -1))
    place_root(rig, start + count, (0, ROOT_HEIGHT, -speed * seconds), (0, 0, -1))
    return start + count


def blend_layers(rig: Rig, start: int, base, layers, seconds: float, fps: int, speed=0.0) -> int:
    """Keys from `start` what the game shows when one-shot clips play over a loop (base(seconds) -> the loop's frame,
    the pose itself, or loops crossfading with their weights: `_tracks`), as Roblox stacks them (`blend`): in the order
    given (later is higher priority, each a level of its own), each a track of the playing clip's pose weighted per joint
    by the clip's weight for it times its fade. A layer is a dict: "clip" (its first frame), "duration" (seconds), "at"
    (seconds it starts), "fade_in" and "fade_out" (Play's and Stop's fades; 0 cuts), "weights" (part -> weight; a wrist
    takes its arm's unless named). The root moves at `speed`. Returns the last frame."""
    count = round(seconds * fps)
    frames = []
    for n in range(count + 1):
        s = n / fps
        tracks = []  # (pose, part -> weight), from the highest priority down
        for layer in reversed(layers):
            t = s - layer["at"]
            length = round(layer["duration"] * fps) / fps  # a clip lasts whole frames, as exported
            if t < 0 or t > length + layer["fade_out"]:
                continue
            w = min(t / layer["fade_in"], 1.0) if layer["fade_in"] > 0 else 1.0
            if t > length:
                w *= 1.0 - (t - length) / layer["fade_out"] if layer["fade_out"] > 0 else 0.0
            w = min(max(w, 0.0), 1.0)  # a fade's last step can land a hair below 0
            share = dict(layer["weights"])
            share.update({wrist: share.get(wrist, share.get(arm, 0.0)) for arm, wrist in rig.extra_joints()})
            tracks.append((sample(rig, layer["clip"] + min(t, length) * fps),
                           {part: weight * w for part, weight in share.items()}))
        under = _tracks(rig, base(s))
        tracks += [(pose, {part: u for part in pose}) for pose, u in under]
        parts = under[0][0].keys()
        frames.append({part: blend([(pose[part], weights.get(part, 0.0)) for pose, weights in tracks])
                       for part in parts})
    for n, matrices in enumerate(frames):
        key_matrices(rig, start + n, matrices)
    place_root(rig, start, (0, ROOT_HEIGHT, 0), (0, 0, -1))
    place_root(rig, start + count, (0, ROOT_HEIGHT, -speed * seconds), (0, 0, -1))
    return start + count


# --- bake for Studio -------------------------------------------------------------------------------------------------

def export(rig: Rig, path: Path, character: str, name: str, start: int, end: int, markers=(), legs=1.0, source="",
           extra=None, weights=None, lift=None):
    """Bakes the rig's joints frame by frame (start to end) to JSON for Author.SaveBaked: each pose is the Motor6D
    Transform's 12 CFrame components. Markers: (seconds, name). `extra` adds fields (a loop's Loop, Priority, ...).
    `weights` (part -> weight) writes each part's pose weight, for a clip that drives only some joints (the legs'
    weight stays in `legs` too). `lift` (t -> studs the game carries the body over its standing height, a launched
    clip's arc) goes to the audit only, never into the file: Author.SaveBaked refuses fields it doesn't know."""
    scene = bpy.context.scene
    fps = scene.render.fps
    frames = []
    for frame in range(start, end + 1):
        scene.frame_set(frame)
        poses = {part: [round(v, 5) for v in components(to_roblox(rig.joints[part].matrix_basis))]
                 for part in PARTS + tuple(j for _, j in rig.extra_joints())}  # the wrists' Poses, on a rig with them
        frames.append({"T": round((frame - start) / fps, 4), "Poses": poses})
    clip = {"Name": name, "Character": character, "Source": source, "Legs": legs, "Fps": fps, "Frames": frames,
            "Markers": [{"T": t, "Name": n} for t, n in markers], **(extra or {})}
    if weights:
        clip["Weights"] = {part: weights.get(part, 1.0) for part in PARTS}
    path.write_text(json.dumps(clip, separators=(",", ":")))
    import r6parity  # every export audits itself: what reads as broken on screen, printed with the export
    r6parity.report(f"[audit] {path.name}", json.loads(path.read_text()), lift=lift)
    return path


# --- the parity check's Blender side (r6parity.py compares it with the export and with Studio) ----------------------

def _frame(obj) -> Matrix:
    """An object's world matrix as its part's frame: exact for the rig's boxes (never scaled); a box some script
    scaled for review has its scale taken out, so a dump never carries it."""
    if tuple(obj.scale) == (1.0, 1.0, 1.0):
        return obj.matrix_world
    location, rotation, _ = obj.matrix_world.decompose()
    return Matrix.Translation(location) @ rotation.to_matrix().to_4x4()


def parity_pose(rig: Rig) -> dict:
    """The rig as the scene shows it now, in the parity JSON's terms (r6parity.py's header), as Roblox's 12 CFrame
    components: each part relative to the HumanoidRootPart, each Motor6D's Transform keyed by its Part1, and the
    weapons welded to the hands, placed from their arms as Equipment's welds place them."""
    root = rig.root.matrix_world.inverted()
    parts = {part: to_roblox(root @ _frame(rig.parts[part])) for part in PARTS + tuple(rig.knees.values())}
    joints = PARTS + tuple(j for _, j in rig.extra_joints())
    transforms = {part: to_roblox(rig.joints[part].matrix_basis) for part in joints}
    weapons = {}
    for weapon in WELDED:
        arm, c0, c1, _ = WEAPONS[weapon]
        wrist = transforms.get(rig.wrists.get(arm), Matrix.Identity(4))  # turned by the wrist on a rig that has one
        weapons[weapon] = parts[arm] @ cframe(c0) @ wrist @ cframe(c1).inverted()

    def exact(m):
        return [round(v, 6) for v in components(m)]
    return {"Parts": {k: exact(v) for k, v in parts.items()},
            "Transforms": {k: exact(v) for k, v in transforms.items()},
            "Weapons": {k: exact(v) for k, v in weapons.items()}}


def parity_dump(rig: Rig, path: Path, clip: str, start: int, end: int, side="blender", legs=1.0, weights=None,
                extra=None) -> Path:
    """Writes the parity JSON of frames `start` to `end`, each timed from `start` as export() times its poses: what
    Blender shows, for `r6parity.py compare` against the export's FK and the builder's Studio dump (the R6 parity
    check). `legs` and `weights` are the export's, so the check knows which
    joints the clip drives; `extra` adds fields (a blend's recipe)."""
    scene = bpy.context.scene
    fps = scene.render.fps
    samples = []
    for frame in range(start, end + 1):
        scene.frame_set(frame)
        samples.append({"T": round((frame - start) / fps, 4), **parity_pose(rig)})
    data = {"Clip": clip, "Side": side, "Character": rig.name, "Fps": fps, "Legs": legs,
            "Weights": {part: (weights or {}).get(part, 1.0) for part in PARTS}, **(extra or {}), "Samples": samples}
    path.write_text(json.dumps(data, separators=(",", ":")))
    return path


# --- the game's numbers ----------------------------------------------------------------------------------------------

def luau_number(relative: str, name: str) -> float:
    """The first `name = number` in a repo file."""
    text = (REPO / relative).read_text(encoding="utf-8")
    return float(re.search(rf"\b{re.escape(name)}\s*=\s*(-?[\d.]+)", text).group(1))


def luau_degrees(relative: str, name: str) -> float:
    """The first `name = math.rad(degrees)` in a repo file, in degrees."""
    text = (REPO / relative).read_text(encoding="utf-8")
    return float(re.search(rf"\b{re.escape(name)}\s*=\s*math\.rad\(\s*(-?[\d.]+)\s*\)", text).group(1))


def luau_table(relative: str, anchor: str) -> dict:
    """The `name = number` fields of the Luau table that starts at the first line containing `anchor` in a repo file
    (one level of braces), so clips stay timed to the game's own definitions."""
    text = (REPO / relative).read_text(encoding="utf-8")
    start = text.index(anchor)
    depth, end = 0, start
    for i in range(text.index("{", start), len(text)):
        depth += {"{": 1, "}": -1}.get(text[i], 0)
        if depth == 0:
            end = i
            break
    return {k: float(v) for k, v in re.findall(r"(\w+)\s*=\s*(-?[\d.]+)", text[start:end])}
