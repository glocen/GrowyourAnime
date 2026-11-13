"""The Lamplighter's model (AR7, delivery 2): Lantern Row's keeper on the Shade's R6 rig, one baked texture set, the
exports and the review sheet.

blender.exe -b --factory-startup --python tools/blender/lamplighter_model.py -- <out_dir>

How it sits on R6: the Shade's body as AR2 built it (shade_sheet.build), its own coat taken off for the keeper's, and
the sheet's pick, A the Bearer (lamplighter_sheet.py): the long festival coat, the oversleeves, the lantern-faced mask,
the sedge hat and its cords, now in rope and tied under the chin (the content check's note). A rigid mesh for each of
the six parts carries the body's own surface, so the rig's blocks are hidden; two more pieces turn on joints of their
own: the pole on the Right Arm, held under the cuff's dark hollow, and the great lantern on the pole, hung from the
hook's tip. Those two are built where the master's stance holds them (research's fix 1), so the idle keys them least.
At rest, with no clip playing and the arm hanging, that grip carries the pole from the floor behind the right heel up
and out, forward and to the right.

One 1024 px atlas: colour with the contact shading baked in, roughness, metalness (the brass), and one glow mask read
three ways, one per SurfaceAppearance. The body's lit edges take Intelligence's colour, with the light through the
Shade's sleeves and legs, by the Shade's numbers. The mask's paper and cuts take its warm white, also the Shade's. The
lantern's paper, cyan round a warm heart, glows whole through its own colours, under a white tint: cold as it stands,
hot through the signature. The coat's folds, the hat's straw, the lantern's ribs and the pole's grain are drawn into
the colour map.

Writes to <out_dir>: Lamplighter_<Piece>.json (blcommon.export_mesh_json), Lamplighter_<Map>.png,
Lamplighter.recipe.json, lamplighter_model.blend, lamplighter_model_sheet.png (with a half-size copy) and
lamplighter_atlas_check.png. It's built in the Shade's units, and the game scales it by its row's Scale, research's
1.5. The bake is Cycles, under build/locks/blender.lock; the review is Eevee.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lamplighter_sheet as ls  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_model as sm  # noqa: E402
import shade_sheet as ss  # noqa: E402

SCRATCH = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo"
LEADS = {"Pip": SCRATCH / "pip" / "model" / "pip_model.blend", "Lyric": SCRATCH / "lyric" / "model" / "lyric_model.blend",
         "Rook": SCRATCH / "rook" / "model" / "rook_model.blend"}
SHADE_BLEND = SCRATCH / "shade" / "model" / "shade_model.blend"
NAME = "Lamplighter"
SIZE, STRIP, MARGIN, SHADE = rm.SIZE, rm.STRIP, rm.MARGIN, rm.SHADE
APART = 20.0  # studs between the pieces while they bake: at rest the pole and the lantern lie long
JOINTS = {"root": "Torso", "neck": "Head", "rs": "RightArm", "ls": "LeftArm", "rh": "RightLeg", "lh": "LeftLeg",
          "pole": "Pole", "lamp": "Lantern"}
MOTORS = {"Pole": "RightArm", "Lantern": "Pole"}  # a piece on a joint of its own: the piece that joint is on
PIECES = list(JOINTS.values())
SHADE_COAT = ("Coat", "Hem", "HemHollow", "Seam", "Crest")  # the Shade's own coat, under the keeper's: taken off
SW = ls.SW
COLOURS = {
    "VoidLift": ss.PALETTE["VoidLift"], "Paper": ss.PALETTE["Paper"], "PaperShade": ss.PALETTE["PaperShade"],
    "Ink": ss.PALETTE["Ink"], "Glow": ss.TYPES[ls.TYPE],
    # the kit's indigo (#2C2A64) taken down into the dark: it and Pip's robe (#46348A) both sit in the middle band,
    # and research's fix 2 asks them apart in value. A first step (#1E1C4A) read 0.14 against Pip's 0.19 in the ring
    # at dusk, both dark: this one, near the Shade's own void, leaves the lantern the keeper's one light.
    "Coat": "#161436", "Trim": SW["red"], "Band": SW["cream"], "Straw": SW["rope"],
    "Cord": "#8A7150",  # the hat's cords: a rope a step darker than the straw, so they read as cord
    "Lacquer": SW["dark"], "Brass": SW["brass"], "Wood": SW["post"], "Tuft": SW["mustard"], "Cyan": SW["cyan"],
    "Warm": SW["warm"],
}
# surface: (roughness, metalness). The brass keeps most of its own colour: full metal goes black wherever the sky is.
SURFACES = {"VoidLift": (0.9, 0.0), "Paper": (0.82, 0.0), "PaperShade": (0.86, 0.0), "Ink": (0.55, 0.0),
            "Glow": (0.6, 0.0), "Coat": (0.88, 0.0), "Trim": (0.8, 0.0), "Band": (0.85, 0.0), "Straw": (0.92, 0.0),
            "Cord": (0.9, 0.0), "Lacquer": (0.35, 0.0), "Brass": (0.36, 0.5), "Wood": (0.45, 0.0), "Tuft": (0.85, 0.0),
            "Cyan": (0.6, 0.0), "Warm": (0.6, 0.0)}
LIT = ("Glow", "Cyan", "Warm")
LAMPLIGHT = ("Cyan", "Warm")
PAPER = sm.PAPER
GROUND = "Coat"  # the colour map's tone past the islands
UNLIT, CUT = sm.UNLIT, sm.CUT
HOT, MASK_HOT, PAPER_GLOW, MASK_TINT = sm.HOT, sm.MASK_HOT, sm.PAPER_GLOW, sm.MASK_TINT
TINT = ss.TYPES[ls.TYPE]
COLD, BURN = 1.2, 3.0  # the lantern's EmissiveStrength: as it stands, and through the signature
WITHIN = {part: sm.WITHIN[part] for part in ("RightArm", "LeftArm", "RightLeg", "LeftLeg")}  # the Shade's light
SCALE = ls.SCALE
GRIP = Vector((1.8, 0.0, 1.72))  # the pole's grip on the Right Arm, at rest: just under the cuff's dark hollow
CROOK = 1.25                     # the sheet's crook drawn wider, so the lantern hangs clear of its own pole
OPEN = (1.0, -0.45, 0.0)         # the way the crook opens in the stance: out to the keeper's right, a little back
HAT_Y = 0.04
# The master's stance (research's fix 1): leaned forward over the planted pole, turned to it and tipped onto it, the
# right sleeve down and out to it as onto a staff, the left held back, the head bowed under the brim. A try lifts the
# head. The arm held out level showed the ring's camera its sleeve's open end, a dark square beside the face.
LEAN, TURN, TIP = -9.0, -8.0, 6.0
RIGHT, LEFT = (0.5, 0.6, -0.65), (-0.12, -0.45, -1.0)
BOW, LIFT = -22.0, 4.0
SMOOTH = {"Pole": 40, "Ferrule": 40, "Hook": 40, "Cord": 65, "CordTail": 65, "CordKnot": 65, "LampCord": 65,
          "HatBinding": 65}
PIVOTS = dict(rs.PIVOTS)  # with the pole's and the lantern's joints, set by build()
FRAMES = {}               # the stance's world facts the drawing and the review need, set by build()


# --- materials ------------------------------------------------------------------------------------------------

def materials():
    """One material per surface, ready to bake, and the names the sheet's builders ask for."""
    made = {}
    for name, (rough, metal) in SURFACES.items():
        m = bpy.data.materials.new(name)
        m.diffuse_color = rs.srgb(COLOURS[name])
        m.roughness = 1.0
        if not (m.node_tree and m.node_tree.nodes.get("Principled BSDF")):
            m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = rs.srgb(UNLIT if name == "Glow" else COLOURS[name])
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        made[name] = m
    return {**made, "Void": made["VoidLift"], "Pole": made["Wood"], "Sash": made["Tuft"]}


# --- the pieces -----------------------------------------------------------------------------------------------

def hat(m):
    """A's sedge hat as the sheet drew it, finished: the low cone, dark under, a lacquer binding round the brim, its
    weave drawn into the colour map. Its cords run in rope down the mask's sides and tie under the chin."""
    z0 = 6.08
    made = [bl.place(bl.cylinder("Hat", 1.75, 0.95, 40, m["Straw"], radius_top=0.07), location=(0, HAT_Y, z0 + 0.475)),
            bl.place(bl.cylinder("HatUnder", 1.7, 0.03, 40, m["Ink"]), location=(0, HAT_Y, z0 - 0.015)),
            bl.place(bl.torus("HatBinding", 1.75, 0.045, 40, 6, m["Lacquer"]), location=(0, HAT_Y, z0 + 0.01))]
    for e in (-1, 1):
        path = bl.smooth_path([(e * 1.0, 0.0, 6.06), (e * 0.99, 0.5, 5.45), (e * 0.95, 0.8, 4.75), (e * 0.66, 0.95, 3.94),
                               (e * 0.1, 0.98, 3.78)], 14)
        made.append(bl.tube_along("Cord", [Vector(p) for p in path], [0.032] * len(path), 6, m["Cord"]))
        made.append(bl.tube_along("CordTail", [Vector((e * 0.05, 0.99, 3.74)), Vector((e * 0.11, 1.0, 3.52)),
                                               Vector((e * 0.14, 1.0, 3.34))], [0.03, 0.028, 0.026], 6, m["Cord"]))
    made.append(bl.place(bl.sphere("CordKnot", 0.085, 10, 6, m["Cord"]), location=(0, 0.98, 3.76)))
    return made


def body(lean=LEAN, turn=TURN, tip=TIP):
    """The torso's turn: leaned (about its own X), tipped (its own Y), then turned (Z)."""
    return (Quaternion((0, 0, 1), math.radians(turn)) @ Quaternion((0, 1, 0), math.radians(tip))
            @ Quaternion((1, 0, 0), math.radians(lean)))


def pose_stance(joints, head=BOW):
    """The master's stance, the idle: its weight leaned on the planted pole, the head bowed under the brim. With
    `head` LIFT, the Challenge's lifted head as a try starts."""
    b = body()
    joints["root"].rotation_quaternion = b
    rs.aim(joints["rs"], b, RIGHT)
    rs.aim(joints["ls"], b, LEFT)
    for part in ("rh", "lh"):
        rs.aim(joints[part], b, (0.0, 0.0, -1.0))
    joints["neck"].rotation_quaternion = (b.inverted() @ Quaternion((0, 0, 1), math.radians(TURN))
                                          @ Quaternion((1, 0, 0), math.radians(head)))
    rs.stand_on_floor(joints)


def carried(joints):
    """The right arm's pieces' world matrix as posed: the pole and the lantern ride it while their joints rest."""
    bpy.context.view_layer.update()
    return joints["rs"].matrix_world @ Matrix.Translation(-Vector(PIVOTS["rs"]))


def place_pole(joints, foot, axis, opening):
    """Stands the pole on `foot` along `axis`, its crook opening toward `opening`: its joint's turn and slide."""
    bpy.context.view_layer.update()
    axis = Vector(axis).normalized()
    opening = (Vector(opening) - axis * Vector(opening).dot(axis)).normalized()
    want = Matrix((opening, axis.cross(opening), axis)).transposed().to_4x4()
    want.translation = Vector(foot)
    piece = want @ FRAMES["pole_rest"].inverted()  # rest coordinates to the world
    joints["pole"].matrix_world = piece @ Matrix.Translation(Vector(PIVOTS["pole"]))
    bpy.context.view_layer.update()


def swing(joints, direction):
    """Turns the lantern on its joint, so it hangs from the hook's tip along `direction` (down is plumb)."""
    bpy.context.view_layer.update()
    lamp = joints["lamp"]
    hang = (lamp.matrix_world.to_3x3() @ FRAMES["hang_rest"]).normalized()
    turn = hang.rotation_difference(Vector(direction).normalized()).to_matrix().to_4x4()
    at = lamp.matrix_world.translation.copy()
    lamp.matrix_world = Matrix.Translation(at) @ turn @ Matrix.Translation(-at) @ lamp.matrix_world
    bpy.context.view_layer.update()


def pose_windup(joints):
    """The signature's seed, as the sheet drew it: leaned back, the pole planted ahead through the right hand and
    leaned toward the keeper, the lantern swung up behind the hook on its joint, the mask up."""
    b = body(lean=6.0, turn=-6.0, tip=0.0)
    joints["root"].rotation_quaternion = b
    rs.aim(joints["rs"], b, (0.25, 0.9, 0.15))
    rs.aim(joints["ls"], b, (0.75, 0.85, -0.35))
    for part in ("rh", "lh"):
        rs.aim(joints[part], b, (0.0, 0.0, -1.0))
    joints["neck"].rotation_quaternion = (b.inverted() @ Quaternion((0, 0, 1), math.radians(-6))
                                          @ Quaternion((1, 0, 0), math.radians(12)))
    rs.stand_on_floor(joints)
    axis = Vector((0.05, -0.45, 1.0)).normalized()
    grip = carried(joints) @ GRIP
    place_pole(joints, grip - axis * (grip.z / axis.z), axis, (0.0, 1.0, 0.0))
    swing(joints, (0.1, -2.0, 0.7))


POSES = {"stance": pose_stance, "challenge": lambda joints: pose_stance(joints, LIFT), "windup": pose_windup}


def joint(scene, joints, name, under):
    """A joint of the keeper's own at PIVOTS[name], on the joint `under`, as the Shade's are on the root."""
    j = bpy.data.objects.new(name, None)
    scene.collection.objects.link(j)
    j.rotation_mode = "QUATERNION"
    j.parent = joints[under]
    j.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[under]))
    j.location = PIVOTS[name]
    joints[name] = j
    return j


def rest(joints):
    for j in joints.values():
        j.rotation_quaternion = (1, 0, 0, 0)
    for key in ("root", "pole", "lamp"):
        joints[key].location = PIVOTS[key]
    bpy.context.view_layer.update()


def build(scene, m):
    """The keeper on its joints, at rest, under a group that places and scales it in the ring. The pole and the
    lantern are made in the world where the stance holds them, then carried back to the arm's rest."""
    four = ss.mask
    ss.mask = lambda kind, mm: ls.mask_lantern(mm)  # the keeper's own mask in place of the four, for this build only
    try:
        joints = ss.build(scene, "Keeper", m)
    finally:
        ss.mask = four
    for o in list(joints["root"].children):
        if o.type == "MESH" and rm.base(o) in SHADE_COAT:
            bpy.data.objects.remove(o, do_unlink=True)
    ls.on(joints, "root", *ls.coat(m, "A"))
    for part, e in (("rs", 1), ("ls", -1)):
        ls.on(joints, part, *ls.oversleeve(m, e))
    ls.on(joints, "neck", *hat(m))
    group = bpy.data.objects.new("Keeper", None)
    scene.collection.objects.link(group)
    joints["root"].parent = group

    pose_stance(joints)
    carry = carried(joints)
    grip = carry @ GRIP
    foot, top = Vector((grip.x, grip.y, 0.0)), Vector((grip.x, grip.y, ls.POLE_TOP))
    ls.HOOKS["model"] = tuple((a, b * CROOK) for a, b in ls.HOOKS["crook"])
    held = ls.pole(m, foot, top, OPEN, "model")
    w = Vector(OPEN).normalized()
    a, b = ls.HOOKS["model"][-1]
    tip = top + Vector((0, 0, a)) + w * b
    lamp = tip - Vector((0, 0, 0.3 + ls.HOOP + ls.LAMP[1] / 2))
    back = carry.inverted()
    for o in held:
        o.data.transform(back)
        o.data.update()
    PIVOTS["pole"], PIVOTS["lamp"] = tuple(back @ grip), tuple(back @ tip)
    stance = Matrix((w, Vector((0, 0, 1)).cross(w), Vector((0, 0, 1)))).transposed().to_4x4()
    stance.translation = foot
    FRAMES.update(carry=carry, grip=grip, foot=foot, top=top, tip=tip, lamp=lamp, pole_rest=back @ stance,
                  hang_rest=(back.to_3x3() @ Vector((0, 0, -1))).normalized())
    joint(scene, joints, "pole", "rs")
    joint(scene, joints, "lamp", "pole")
    for o in held:
        key = "pole" if rm.base(o) in ("Pole", "Ferrule", "Hook") else "lamp"
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[key]))
    rest(joints)
    return joints, group


def take_pieces(joints):
    """The build's objects by piece, standing free in the model's frame."""
    rest(joints)
    groups = {piece: [o for o in joints[key].children if o.type == "MESH"] for key, piece in JOINTS.items()}
    for objs in groups.values():
        for o in objs:
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            bl.smooth_by_angle(o, SMOOTH.get(rm.base(o), 32))
    return groups


# --- measures in the stance -----------------------------------------------------------------------------------

def world_points(objs):
    return [o.matrix_world @ v.co for o in objs for v in o.data.vertices]


def clearances(scene, joints, group):
    """In the stance: how far the pole and the lantern stand off the hat's brim, the lantern off its pole, and, from
    the ring's camera with the head lifted, the gap between the lantern and the mask in the frame's pixels."""
    from bpy_extras.object_utils import world_to_camera_view
    rest(joints)
    pose_stance(joints)
    kids = lambda key, names: [o for o in joints[key].children if o.type == "MESH" and rm.base(o) in names]  # noqa: E731
    brim = world_points(kids("neck", ("Hat", "HatBinding")))
    lamp = world_points(kids("lamp", ("LampTop", "LampHeart", "LampFoot")))
    g = FRAMES["grip"]
    facts = {"pole_brim": min(math.hypot(p.x - g.x, p.y - g.y) for p in brim) - 0.1,
             "lamp_brim": min((p - q).length for p in lamp for q in brim),
             "lamp_pole": min(math.hypot(p.x - g.x, p.y - g.y) for p in lamp) - 0.1}
    rest(joints)
    pose_stance(joints, LIFT)
    (x, y), turn = ls.RING["keeper"]
    group.location, group.rotation_euler, group.scale = (x, y, 0), (0, 0, math.radians(turn)), (SCALE,) * 3
    bpy.context.view_layer.update()
    cam = ls.perspective(scene)
    w = ls.RING["size"][0]
    face = [world_to_camera_view(scene, cam, p).x * w for p in world_points(kids("neck", ("Mask", "Rim")))]
    light = [world_to_camera_view(scene, cam, p).x * w for p in world_points(kids("lamp", ("LampTop", "LampHeart", "LampFoot")))]
    facts["ring_gap"] = max(min(face) - max(light), min(light) - max(face))
    bpy.data.objects.remove(cam, do_unlink=True)
    scene.camera = None
    group.location, group.rotation_euler, group.scale = (0, 0, 0), (0, 0, 0), (1, 1, 1)
    rest(joints)
    return facts


def stride(joints):
    """The widest swing each way at which a leg stays inside the long coat's hem, in degrees."""
    rest(joints)
    rings = [(0.6, 3.06, 2.56), (1.7, 2.62, 1.86), (2.9, 2.3, 1.34)]  # the hem's lit band is the lowest
    # the leg's surface, sampled along its length: its mesh has vertices only at its two ends
    leg = [Vector((0.5 + 0.49 * math.copysign(abs(math.cos(t)) ** (2 / ss.B), math.cos(t)),
                   0.49 * math.copysign(abs(math.sin(t)) ** (2 / ss.B), math.sin(t)), z))
           for t in np.linspace(0, 2 * math.pi, 32, endpoint=False) for z in np.linspace(0.02, 2.0, 40)]

    def inside(p):
        for (z0, w0, d0), (z1, w1, d1) in zip(rings, rings[1:]):
            if z0 <= p.z <= z1:
                t = (p.z - z0) / (z1 - z0)
                a, b = (w0 + (w1 - w0) * t) / 2, (d0 + (d1 - d0) * t) / 2
                return abs(p.x / a) ** ss.B + abs(p.y / b) ** ss.B <= 1.0
        return True

    best = 0
    for s in range(15, 41):
        ok = True
        for sign in (1, -1):
            rs.aim(joints["rh"], Quaternion(), (0.0, sign * math.tan(math.radians(s)), -1.0))
            bpy.context.view_layer.update()
            on = joints["rh"].matrix_world @ Matrix.Translation(-Vector(PIVOTS["rh"]))
            ok &= all(inside(p) for p in (on @ q for q in leg) if p.z > 0.6)
        if not ok:
            break
        best = s
    rest(joints)
    return best


# --- the bake -------------------------------------------------------------------------------------------------

def fold(a, z, folds, shift=0.0):
    """How far the folds stand out at angle `a` (degrees, front 90) and height `z`, 0 to 1: each fold (its angle, its
    width in degrees, where it starts, where it stands out fully). `shift` reads the valley a fold's width aside."""
    total = 0.0
    for i, (at, wide, top, low) in enumerate(folds):
        d = (a - at - 3.0 * np.sin(1.7 * z + i) + 180.0) % 360.0 - 180.0
        total = total + np.clip((top - z) / (top - low), 0.0, 1.0) ** 0.8 * np.exp(-((d / wide - shift) ** 2))
    return np.minimum(total, 1.0)


def cloth(a, z, folds):
    ridge = fold(a, z, folds)
    valley = np.maximum(fold(a, z, folds, 1.6), fold(a, z, folds, -1.6)) * (1 - ridge)
    return 1 + 0.26 * ridge - 0.18 * valley


# The coat's folds: long ones from under the sash to the hem, softer ones from the shoulders; the front's two bands
# cover 67 to 113 degrees. The oversleeves' are round each sleeve's own middle, its outside at 0.
FOLDS = (tuple((at, wide, 2.45, 0.9) for at, wide in ((14, 7), (40, 6), (63, 6), (117, 6), (140, 6), (166, 7), (-16, 7),
                                                       (-44, 6), (-70, 6), (-96, 7), (-121, 6), (-147, 6), (180, 8)))
         + tuple((at, wide, 3.95, 2.85) for at, wide in ((26, 9), (154, 9), (-62, 9), (-118, 9))))
SLEEVE_FOLDS = ((62, 10, 3.9, 2.6), (-72, 10, 3.7, 2.6), (4, 11, 3.4, 2.6), (152, 10, 3.6, 2.6))


def gathered(z):
    """The coat gathered by the sash: a shadow tucked under each edge, a roll of cloth beside it."""
    v = 0.0
    for edge, side in ((2.8, 1.0), (2.45, -1.0)):
        d = (z - edge) * side
        v = v - 0.16 * np.exp(-(d / 0.04) ** 2) + 0.08 * np.exp(-((d - 0.13) / 0.06) ** 2)
    return v


def straw(r, a):
    """The sedge: plaited rows round the crown, the reeds across them, the two inked rings the sheet had as wire, and
    the brim's edge a little darker."""
    rows = np.cos(2 * np.pi * r / 0.11)
    reeds = np.sin(np.radians(a) * 90 + 3.0 * np.sin(r * 7.0))
    ring = sum(np.exp(-((r - k) / 0.028) ** 2) for k in (1.25, 0.72))
    edge = np.exp(-((r - 1.72) / 0.06) ** 2)
    return (1 + 0.07 * rows * reeds + 0.03 * reeds) * (1 - 0.55 * ring) * (1 - 0.2 * edge)


def paper(a, dz, h=ls.LAMP[1]):
    """The lantern's paper: a rib at each of its eight corners and a seam where its panels meet, its light falling
    off from the heart toward the hoops, and a fibre in it."""
    corner = np.abs((a % 45.0) - 22.5)  # the corners are at 22.5 + 45k degrees
    rib = np.exp(-(corner / 2.4) ** 2)
    seam = np.exp(-((np.abs(dz) - 0.26 * h) / 0.03) ** 2)
    fall = 1 - 0.24 * np.clip(np.abs(dz) / (h / 2), 0, 1) ** 1.6
    fibre = 1 + 0.035 * np.sin(np.radians(a) * 160 + dz * 11)
    return fall * fibre * (1 - 0.45 * rib) * (1 - 0.25 * seam)


def grain(a, h):
    return 1 + 0.08 * np.sin(h * 6.0 + 2.2 * np.sin(np.radians(a) * 2 + h * 0.8)) + 0.04 * np.sin(np.radians(a) * 7 + h * 1.7)


def draw(colour, mask, piece, local, y, z):
    """The colour map's details, each texel drawn from where it is on its piece: the pole and the lantern from where
    the stance holds them."""
    value = np.ones(z.shape, dtype=np.float32)
    at = {name: piece == PIECES.index(name) for name in PIECES}
    a = np.degrees(np.arctan2(y, local))
    value = np.where(mask["Coat"] & at["Torso"], cloth(a, z, FOLDS) + gathered(z), value)
    for name, e in (("RightArm", 1.0), ("LeftArm", -1.0)):
        a = np.degrees(np.arctan2(y, (local - e * 1.8) * e))
        value = np.where(mask["Coat"] & at[name], cloth(a, z, SLEEVE_FOLDS), value)
    value = np.where(mask["Straw"] & at["Head"], straw(np.hypot(local, y - HAT_Y), np.degrees(np.arctan2(y - HAT_Y, local))), value)
    carry = np.array(FRAMES["carry"], dtype=np.float32)
    wx, wy, wz = (carry[i, 0] * local + carry[i, 1] * y + carry[i, 2] * z + carry[i, 3] for i in range(3))
    g, c = FRAMES["grip"], FRAMES["lamp"]
    value = np.where(mask["Wood"] & at["Pole"], grain(np.degrees(np.arctan2(wy - g.y, wx - g.x)), wz), value)
    value = np.where(mask["Lamp"] & at["Lantern"], paper(np.degrees(np.arctan2(wy - c.y, wx - c.x)), wz - c.z), value)
    colour[..., :3] = (colour[..., :3] * np.clip(value, 0.4, 1.3)[..., None]).clip(0, 1)


def through_paper(cloth_mask, piece, local, y, z):
    """The Shade's light through its own sleeves and legs, where they show under the keeper's dress."""
    glow = np.zeros(z.shape, dtype=np.float32)
    for name, (edge, reach, most, middle) in WITHIN.items():
        t = np.clip((z - edge) / reach, 0, 1)
        g = most * (1 - t) ** 1.7
        phase = ((z - edge) / sm.HOOP) % 1.0
        g *= 1 - 0.5 * np.clip((np.abs(phase - 0.5) - 0.41) / 0.04, 0, 1)
        a = np.arctan2(y, local - middle)
        g *= 1 + 0.16 * np.sin(a * 41 + z * 2.3) * np.sin(a * 97 - z * 1.1)
        glow = np.where(cloth_mask & (piece == PIECES.index(name)), g, glow)
    return glow.astype(np.float32)


def bake(obj, out):
    """The maps: the contact shading in the colour, the details drawn, the light through the cloth added, the strip's
    swatches painted in, and the light encoded per piece as Roblox's glow mask."""
    scene = bpy.context.scene
    world = bpy.data.worlds.new("Bake")
    scene.world = world
    world.light_settings.distance = 1.2
    masks = {"Cloth": ("VoidLift",), "Paper": PAPER, "Coat": ("Coat",), "Straw": ("Straw",), "Wood": ("Wood",),
             "Lamp": LAMPLIGHT}
    held = rm.lock("lamplighter_model.py")
    try:
        paths = bl.bake_pbr(obj, SIZE, out, NAME, samples=16, emissive=LIT, margin=MARGIN, fill=True)
        used = [slot.material for slot in obj.material_slots if slot.material]
        masks["Cover"] = [m.name for m in used]
        extra = {}
        for name in (*masks, "Probe", "Shade"):
            extra[name] = bpy.data.images.new(f"{NAME}_{name}_", SIZE, SIZE, alpha=False, float_buffer=name == "Probe")
            extra[name].colorspace_settings.name = "Non-Color"

        def onto(name):
            for m in used:
                m.node_tree.nodes.active.image = extra[name]

        for name, lit in masks.items():
            onto(name)
            with bl._Glowing(used, lit):
                bpy.ops.object.bake(type="EMIT", use_clear=True)
        onto("Probe")
        with sm._Probing(used):
            bpy.ops.object.bake(type="EMIT", use_clear=True)
        onto("Shade")
        scene.cycles.samples = 256
        bpy.ops.object.bake(type="AO", use_clear=True)
    finally:
        held.unlink(missing_ok=True)
    covered = rm.pixels(extra["Cover"])[..., 0] > 0.5
    for _ in range(2):  # 2 px in, as the kit's fill does: the mask's edge runs a pixel past the margin
        inner = covered.copy()
        inner[1:, :] &= covered[:-1, :]
        inner[:-1, :] &= covered[1:, :]
        inner[:, 1:] &= covered[:, :-1]
        inner[:, :-1] &= covered[:, 1:]
        covered = inner
    mask = {name: covered & (rm.pixels(extra[name])[..., 0] > 0.5) for name in masks if name != "Cover"}
    ao = rm.pixels(extra["Shade"])[..., :1] ** 0.85
    probe = rm.pixels(extra["Probe"])
    x, y, z = probe[..., 0] * 100 - 5, probe[..., 1] * 100 - 5, probe[..., 2] * 10 - 1
    piece = np.rint(x / APART).astype(np.int32)
    local = x - piece * APART
    images = {kind: bpy.data.images[f"{NAME}_{kind}"] for kind in paths}
    colour = rm.pixels(images["Color"])
    glow = rm.pixels(images["Emissive"])
    lit = glow[..., 0] > 0.5  # no contact shading under a light: the glow is drawn through the colour
    colour[..., :3] *= SHADE + (1 - SHADE) * np.where((covered & ~lit)[..., None], ao, 1.0)
    head = piece == PIECES.index("Head")
    colour[lit & covered & head, :3] = rs.rgb(CUT)
    colour[~covered, :3] = rs.rgb(COLOURS[GROUND])  # past the islands: one tone, never the shade's dark
    draw(colour, mask, piece, local, y, z)
    within = through_paper(mask["Cloth"], piece, local, y, z)
    sm.unviolet(colour, within)
    light = np.maximum(glow[..., 0], within)
    light = np.where(mask["Paper"] & head, np.maximum(light, PAPER_GLOW), light)
    hot = np.where(head, MASK_HOT, HOT).astype(np.float32)
    maps = {"Color": colour, "Roughness": rm.pixels(images["Roughness"]), "Metalness": rm.pixels(images["Metalness"])}
    rows = int(STRIP * 0.8 * SIZE)
    hot[:rows] = MASK_HOT  # the swatches that glow are paper, and only the mask wears paper
    spans = {}
    for i, (name, (rough, metal)) in enumerate(SURFACES.items()):
        x0, x1 = round(i * SIZE / len(SURFACES)), round((i + 1) * SIZE / len(SURFACES))
        spans[name] = (x0, x1)
        for kind, value in (("Color", rs.rgb(UNLIT if name == "Glow" else COLOURS[name])), ("Roughness", rough), ("Metalness", metal)):
            maps[kind][:rows, x0:x1, :3] = value
        light[:rows, x0:x1] = PAPER_GLOW if name in PAPER else 0.0
    code = sm.encode(light, colour, hot)
    lamp = covered & (piece == PIECES.index("Lantern"))
    code = np.where(lamp, glow[..., 0], code)  # the lantern's paper glows whole, through its own colours
    for name in LAMPLIGHT:
        x0, x1 = spans[name]
        code[:rows, x0:x1] = 1.0
    short = (light > 0) & (code >= 1) & covered & ~lamp
    print(f"glow mask: {short.sum()} texels of the body and mask stop at 1 "
          f"({100 * short.sum() / max(1, ((light > 0) & ~lamp).sum()):.1f}% of their lit)")
    glow[..., :3] = code[..., None]
    maps["Emissive"] = glow
    for kind, data in maps.items():
        images[kind].pixels.foreach_set(data.ravel())
        images[kind].save()
    paths.pop("Normal").unlink()  # flat: the low mesh is the form
    return paths


def split(obj):
    """The baked mesh cut back into its pieces, each where it stands in the model."""
    made = {}
    for index, piece in enumerate(PIECES):
        mesh = obj.data.copy()
        bm = bmesh.new()
        bm.from_mesh(mesh)
        layer = bm.faces.layers.int["piece"]
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] != index], context="FACES")
        bm.to_mesh(mesh)
        bm.free()
        mesh.transform(Matrix.Translation((-APART * index, 0, 0)))
        o = bpy.data.objects.new(f"{NAME}_{piece}", mesh)
        mesh.name = o.name
        bpy.context.scene.collection.objects.link(o)
        made[piece] = o
    bpy.data.objects.remove(obj, do_unlink=True)
    return made


def look(name, paths, tint, strength):
    """What Roblox will draw: sm.baked's surface with the metalness map on it."""
    m, light = sm.baked(name, paths)
    bsdf, nodes, links = bl._principled(m)
    node = nodes.new("ShaderNodeTexImage")
    node.image = bpy.data.images.load(str(paths["Metalness"]), check_existing=True)
    node.image.colorspace_settings.name = "Non-Color"
    links.new(node.outputs["Color"], bsdf.inputs["Metallic"])
    light(tint, strength)
    return m


# --- the hand-off -----------------------------------------------------------------------------------------------

def export(made, paths, out, density):
    """Each piece as JSON for Studio, and the recipe's facts. Points are Roblox's: studs, Y up, the model standing
    on y = 0 and facing -Z, its HumanoidRootPart at (0, 3, 0), at rest and in the Shade's units."""
    pieces, total = [], 0
    for piece, o in made.items():
        tris = bl.export_mesh_json(o, out / f"{o.name}.json")
        total += tris
        box = [v.co for v in o.data.vertices]
        size = [round(max(c[i] for c in box) - min(c[i] for c in box), 3) for i in (0, 2, 1)]
        on = rm.R6.get(MOTORS.get(piece, piece), f"{NAME}_{MOTORS.get(piece)}")
        entry = {"name": o.name, "mesh": f"{o.name}.json", "on": on,
                 "centre": json.loads((out / f"{o.name}.json").read_text())["c"], "size": size, "tris": tris}
        if piece in MOTORS:
            entry["motor"] = piece
            entry["pivot"] = rm.roblox(PIVOTS[next(k for k, p in JOINTS.items() if p == piece)])
        pieces.append(entry)
        print(f"{o.name}: {tris} tris, {size} studs")
    back = FRAMES["carry"].inverted()
    recipe = {
        "name": NAME,
        "frame": "Roblox studs: Y up, the model on y = 0 facing -Z, HumanoidRootPart at (0, 3, 0), in the Shade's units",
        "scale": SCALE,
        "scale_note": "Built at an ordinary Shade's size: the game scales the template by its row's Scale "
                      "(model:ScaleTo), research's pick 1.5 (AR7). Every number here is before the scale.",
        "rig": "R6, the Shade's. Every piece carries the body's own surface: the six rig parts are hidden "
               "(Transparency 1), and the Head's face decal is removed. The Head piece carries the mask, the hat and "
               "its cords. Two more pieces turn on Motor6Ds of their own: the pole on the Right Arm, the lantern on "
               "the pole.",
        "maps": {kind: path.name for kind, path in paths.items()},
        "texels_per_stud": round(density),
        "emissive": {
            "body": {"pieces": [f"{NAME}_{p}" for p in ("Torso", "RightArm", "LeftArm", "RightLeg", "LeftLeg")],
                     "tint": TINT, "strength": HOT},
            "head": {"pieces": [f"{NAME}_Head"], "tint": MASK_TINT, "strength": MASK_HOT},
            "lantern": {"pieces": [f"{NAME}_Lantern"], "tint": "#FFFFFF", "cold": COLD, "hot": BURN},
            "pole": {"pieces": [f"{NAME}_Pole"], "strength": 0},
            "note": "One atlas, one glow mask, four SurfaceAppearances. The body takes Intelligence's colour as "
                    "EmissiveTint at the Shade's strength; the Head takes the mask's warm white at the mask's, so its "
                    "paper glows faintly and its cuts are lit, as a Shade's. Roblox draws (mask x strength x tint + "
                    "light) x colour map, and these two are encoded for those strengths over this colour map: upload "
                    "the maps together. The lantern's paper is cyan round a warm white heart in the colour map, so "
                    "its tint is white: a cyan tint over cyan would go deeper and darker. It burns at cold as it "
                    "stands and goes to hot through the signature's wind-up; the fall puts it out last. The pole "
                    "takes no glow."},
        "pieces": pieces,
        "motors": {
            "Pole": {"note": "The pole on the Right Arm, its pivot the grip just under the cuff's dark hollow. It's "
                             "built as the master's stance holds it, the idle, so with the arm raised to the stance "
                             "it stands plumb with no key on its own joint. At rest, with no clip and the arm "
                             "hanging, it runs from the floor behind the right heel up through the grip, out forward "
                             "and to the right. The Shade's shared clips don't key it: a keeper clip, or a hold layered over "
                             "the right arm at a higher priority, carries it (delivery 3). It turns and slides along "
                             "its length through the grip, so a clip plants its foot on the ground."},
            "Lantern": {"note": "The great lantern on the pole, its pivot the hook's tip, where its cord ties on. "
                                "Clips keep it hanging plumb and swing it; the signature swings it up over the hook. "
                                "CastShadow off: it's a light. A PointLight inside it, in cyan, is the builder's "
                                "call, tuned in the engine."}},
        "points": [
            {"name": "Lantern", "on": f"{NAME}_Lantern", "at": rm.roblox(back @ FRAMES["lamp"]),
             "note": "the light's middle: the signature lights its circle from here"},
            {"name": "HookTip", "on": f"{NAME}_Pole", "at": rm.roblox(PIVOTS["lamp"]), "note": "where the cord ties on"},
            {"name": "PoleFoot", "on": f"{NAME}_Pole", "at": rm.roblox(back @ FRAMES["foot"]),
             "note": "the pole's foot: planted on the ground in the stance"},
            {"name": "Grip", "on": "Right Arm", "at": rm.roblox(PIVOTS["pole"]), "note": "the pole's pivot on the arm"},
            {"name": "Chest", "on": "Torso", "at": rm.roblox((0, 0.75, 3.1)), "note": "where a hit lands"},
            {"name": "Crest", "on": "Torso", "at": rm.roblox((0, -0.72, 3.36)), "note": "the lantern crest on its back"}],
        "tris": total,
    }
    return recipe


# --- the review -------------------------------------------------------------------------------------------------

LUMA = sm.LUMA
FRONT, BACK, SIDE, SEEN = (180, 4), (0, 4), (90, 4), ls.SEEN
LOWER = (125, -10)  # a lower camera, looking up: research's thought for "tall"


def value(rgba):
    """sRGB luma, as value_check.py reads a frame."""
    return rgba[..., :3] @ LUMA


def tones(rgba):
    out = rgba.copy()
    y = value(rgba)
    out[..., :3] = np.where(y < 0.15, 0.05, np.where(y < 0.5, 0.35, 0.95))[..., None]
    return out


def greyed(rgba):
    out = rgba.copy()
    out[..., :3] = value(rgba)[..., None]
    return out


def framing(objs, view):
    """The middle and the span an orthographic view needs to hold `objs` whole."""
    a, e = math.radians(view[0]), math.radians(view[1])
    bpy.context.view_layer.update()
    look = -Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e)))
    right = look.cross(Vector((0, 0, 1))).normalized()
    up = right.cross(look).normalized()
    pts = world_points(objs)
    u = [p.dot(right) for p in pts]
    v = [p.dot(up) for p in pts]
    mid = sum(pts, Vector()) / len(pts)
    mid = mid - right * (mid.dot(right) - (max(u) + min(u)) / 2) - up * (mid.dot(up) - (max(v) + min(v)) / 2)
    return mid, max(max(u) - min(u), max(v) - min(v))


def load_lead(scene, blend, at, turn, name):
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = list(src.objects)
    holder = bpy.data.objects.new(name, None)
    scene.collection.objects.link(holder)
    theirs = [holder]
    for o in dst.objects:
        if o is None:
            continue
        theirs.append(o)
        if o.type == "MESH":
            scene.collection.objects.link(o)
            if o.parent is None:
                o.parent = holder
    holder.location, holder.rotation_euler = (*at, 0), (0, 0, math.radians(turn))
    bpy.context.view_layer.update()
    return theirs


def remove(objs):
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)


def review(scene, joints, group, made, paths, out, facts):
    looks = {"Body": look(f"{NAME}_Body", paths, TINT, HOT), "Head": look(f"{NAME}_Mask", paths, MASK_TINT, MASK_HOT),
             "Pole": look(f"{NAME}_Wood", paths, "#FFFFFF", 0.0), "Cold": look(f"{NAME}_Cold", paths, "#FFFFFF", COLD),
             "Burn": look(f"{NAME}_Burn", paths, "#FFFFFF", BURN)}
    for piece, o in made.items():
        bl.assign_only(o, looks.get(piece, looks["Cold"] if piece == "Lantern" else looks["Body"]))
    bl.save_blend(out / f"{NAME.lower()}_model.blend")  # the pieces standing free in the model's frame, for the clips
    for piece, o in made.items():
        key = next(k for k, p in JOINTS.items() if p == piece)
        o.parent = joints[key]
        o.matrix_parent_inverse = Matrix.Translation(-Vector(PIVOTS[key]))
    made["Lantern"].visible_shadow = False  # as the recipe asks of the engine: it's a light
    keeper = list(made.values())
    shots = {}

    def take(name, pose, view, dusk=True, size=640, burn=False, at=None, across=None, scaled=1.0):
        rest(joints)
        group.scale = (scaled,) * 3
        POSES[pose](joints)
        bl.assign_only(made["Lantern"], looks["Burn" if burn else "Cold"])
        if at is None:
            at, across = framing(keeper, view)
            across *= 1.06
        rm.eevee(scene, size, size)
        sm.lighting(scene, view[0], dusk)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across)
        path.unlink()
        group.scale = (1, 1, 1)

    rest(joints)
    pose_stance(joints)
    span = max(framing(keeper, v)[1] for v in (FRONT, BACK, SIDE, SEEN)) * 1.04
    bpy.context.view_layer.update()
    for name, pose, view in (("front", "stance", FRONT), ("back", "stance", BACK), ("side", "stance", SIDE),
                             ("seen", "stance", SEEN), ("challenge", "challenge", SEEN), ("day", "challenge", SEEN),
                             ("lower", "challenge", LOWER)):
        rest(joints)
        POSES[pose](joints)
        at = framing(keeper, view)[0]
        take(name, pose, view, dusk=name != "day", at=at, across=span)
    for name, pose in (("bowed", "stance"), ("lifted", "challenge")):
        rest(joints)
        POSES[pose](joints)
        face = joints["neck"].matrix_world @ (Vector((0, 0.83, 5.3)) - Vector(PIVOTS["neck"]))
        take(f"face{name}", pose, SEEN, size=520, at=face, across=4.6)
    rest(joints)
    pose_stance(joints)
    take("lampcold", "stance", SEEN, size=420, at=FRAMES["lamp"], across=3.4)
    take("lampburn", "stance", SEEN, size=420, at=FRAMES["lamp"], across=3.4, burn=True)
    take("windup", "windup", (138, 12), size=720, burn=True)

    # at 64 px: the keeper at its scale beside an ordinary Shade, the same studs to a pixel
    small_span, small_at = 19.0, (1.6, 0.0, 6.2)
    for dusk in (True, False):
        take(f"small{'dusk' if dusk else 'day'}", "challenge", SEEN, dusk=dusk, at=small_at, across=small_span, scaled=SCALE)
    for o in keeper:
        o.hide_render = True
    shade = load_lead(scene, SHADE_BLEND, (0, 0), 0.0, "Shade")
    for o in shade:
        if o.type == "MESH" and o.name.startswith("Shade_Mask") and o.name != "Shade_MaskBrawler":
            o.hide_render = True
    shade_look = bpy.data.materials.get("Shade_Baked")
    for node in shade_look.node_tree.nodes if shade_look else ():
        if node.bl_idname == "ShaderNodeMix":
            node.inputs[7].default_value = rs.srgb(ss.TYPES["Strength"])
        if node.bl_idname == "ShaderNodeMath":
            node.inputs[1].default_value = sm.HOT
    for dusk in (True, False):
        rm.eevee(scene, 640, 640)
        sm.lighting(scene, ss.PLAYER[0], dusk)
        path = out / "_shade.png"
        shots[f"shade{'dusk' if dusk else 'day'}"] = rs.shoot(scene, path, ss.PLAYER[0], ss.PLAYER[1], small_at, small_span)
        path.unlink()
    remove(shade)
    for o in keeper:
        o.hide_render = False

    # in the ring at dusk, beside each starter, as TR2 frames the fight: the keeper's head lifted as a try starts
    ortho = scene.camera
    floor_m = bpy.data.materials.new("Paving")
    floor_m.use_nodes = True
    floor_m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = rs.srgb(ls.PAVING)
    floor_m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    grey = bpy.data.materials.new("Avatar")
    grey.use_nodes = True
    grey.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.42, 0.42, 0.44, 1)
    stage = [bl.place(bl.cylinder("Ring", 40.0, 0.2, 96, floor_m), location=(3.0, 6.0, -0.1))]
    for size, at in (((2, 1, 2), (0, 0, 3)), ((1.2, 1.2, 1.2), (0, 0, 4.6)), ((1, 1, 2), (1.5, 0, 3)), ((1, 1, 2), (-1.5, 0, 3)),
                     ((1, 1, 2), (0.5, 0, 1)), ((1, 1, 2), (-0.5, 0, 1))):
        stage.append(bl.place(bl.box("Avatar", size, grey), location=at))
    cam = ls.perspective(scene)
    bl.assign_only(made["Lantern"], looks["Cold"])
    rings = {}
    for lead, blend in LEADS.items():
        rest(joints)
        pose_stance(joints, LIFT)
        (x, y), turn = ls.RING["keeper"]
        group.location, group.rotation_euler, group.scale = (x, y, 0), (0, 0, math.radians(turn)), (SCALE,) * 3
        theirs = load_lead(scene, blend, *ls.RING["rook"], lead)
        rm.eevee(scene, *ls.RING["size"])
        sm.lighting(scene, 0.0, True)
        path = out / "_ring.png"
        shot = ls.rendered(scene, path)
        rs.workbench(scene, *ls.RING["size"], flat=True)
        scene.display.shading.color_type = "OBJECT"
        scene.display.shading.show_object_outline = False
        for o in scene.objects:
            if o.type == "MESH":
                o.color = ((1, 0, 0, 1) if o is made["Torso"] else (1, 1, 0, 1) if o in keeper
                           else (0, 0, 1, 1) if o in stage else (0, 1, 0, 1))
        ids = ls.rendered(scene, path)
        path.unlink()
        frame = rs.canvas(*ls.RING["size"], ls.DUSK)
        rs.paste(frame, shot, 0, 0)
        solid = ids[..., 3] > 0.99
        coat = solid & (ids[..., 0] > 0.5) & (ids[..., 1] < 0.5) & (ids[..., 2] < 0.5)
        theirs_px = solid & (ids[..., 0] < 0.5) & (ids[..., 1] > 0.5) & (ids[..., 2] < 0.5)
        y_ = value(frame)
        pair = solid & ~((ids[..., 0] < 0.5) & (ids[..., 1] < 0.5) & (ids[..., 2] > 0.5))  # the keeper and the lead
        ys, xs = np.nonzero(pair)
        box = (max(ys.min() - 12, 0), ys.max() + 13, max(xs.min() - 12, 0), xs.max() + 13)
        dark = lambda px: 100 * float((y_[px] < 0.15).mean())  # noqa: E731
        rings[lead] = (frame, float(np.median(y_[coat])), float(np.median(y_[theirs_px])), dark(coat), dark(theirs_px), box)
        print(f"in the ring beside {lead}: the coat's value {rings[lead][1]:.3f} ({rings[lead][3]:.0f}% dark), "
              f"{lead}'s {rings[lead][2]:.3f} ({rings[lead][4]:.0f}% dark)")
        remove(theirs)
        group.location, group.rotation_euler, group.scale = (0, 0, 0), (0, 0, 0), (1, 1, 1)
    remove(stage + [cam])
    scene.camera = ortho
    rest(joints)

    W, H = 1920, 1700
    ink, soft, pale = "#1E1B22", "#6A6670", "#B9B4C6"
    page = rs.canvas(W, H, rs.PAPER)
    text = [(30, 24, 30, "THE LAMPLIGHTER, the model on the Shade's R6", ink),
            (30, 62, 15, "AR7, delivery 2. Lit as the baked maps draw: at dusk, and by day. No bloom: the game's, if any, "
                         "is the builder's. In the Shade's units; the game scales it 1.5.", soft)]
    top, floor = 96, 450
    rs.fill(page, 20, top, 1564, 380, rs.NIGHT)
    rs.fill(page, 1584, top, 316, 380, rs.DAY)
    k = 306 / 640  # one span for every view, as wide as a column: no figure crosses into the next
    row = (("front", "front: the master's stance"), ("back", "back: the crest"), ("side", "its right: the pole's side"),
           ("seen", "the ring's camera: bowed"), ("challenge", "a try starts: the head lifts"), ("day", "the same, by day"))
    for i, (name, label) in enumerate(row):
        x = 26 + i * 312 + (6 if name == "day" else 0)
        rs.stand(page, rs.shrink(shots[name], k), x, floor, 306)
        text.append((x + 8, floor + 8, 13, label, soft if name == "day" else pale))

    y2 = 540
    text.append((30, y2 - 36, 20, "IN THE RING AT DUSK, BESIDE EACH STARTER", ink))
    text.append((520, y2 - 32, 15, "TR2's framing (zoom 10, pitch 10, FOV 70), the player's grey avatar in front; under each, the "
                                   "keeper and its starter cut close: grey, and in three bands (dark under 0.15, light from 0.5).", soft))
    for i, (lead, (frame, coat, theirs, coat_dark, theirs_dark, (y0, y1, x0, x1))) in enumerate(rings.items()):
        x = 24 + i * 628
        rs.paste(page, rs.shrink(frame, 600 / ls.RING["size"][0]), x, y2)
        cut = frame[y0:y1, x0:x1]
        f = min(296 / cut.shape[1], 166 / cut.shape[0])
        for j, img in enumerate((greyed(cut), tones(cut))):
            rs.fill(page, x + j * 304, y2 + 346, 296, 166, rs.NIGHT)
            small = rs.shrink(img, f)
            rs.paste(page, small, x + j * 304 + (296 - small.shape[1]) // 2, y2 + 346 + (166 - small.shape[0]) // 2)
        text.append((x, y2 + 520, 14, f"beside {lead}: the coat {coat:.2f}, {coat_dark:.0f}% of it dark; {lead} {theirs:.2f}, "
                                      f"{theirs_dark:.0f}% dark (medians)", soft))

    y3 = 1130
    text.append((30, y3 - 34, 20, "UP CLOSE", ink))
    x = 24
    for name, label in (("facebowed", "the face, bowed: the idle"), ("facelifted", "lifted as a try starts")):
        rs.fill(page, x, y3, 230, 230, ls.DUSK)
        rs.paste(page, rs.shrink(shots[name], 230 / 520), x, y3)
        text.append((x + 2, y3 + 236, 13, label, soft))
        x += 240
    for name, label in (("lampcold", "the lantern, cold (1.2)"), ("lampburn", "hot, the signature (3.0)")):
        rs.fill(page, x, y3, 190, 190, ls.DUSK)
        rs.paste(page, rs.shrink(shots[name], 190 / 420), x, y3)
        text.append((x + 2, y3 + 236, 13, label, soft))
        x += 200
    rs.fill(page, x, y3, 380, 230, rs.NIGHT)
    rs.stand(page, rs.shrink(shots["windup"], 0.3), x, y3 + 226, 380)
    text.append((x + 2, y3 + 236, 13, "the signature's seed: the pole and the lantern", soft))
    text.append((x + 2, y3 + 254, 13, "turned on their own joints", soft))
    x += 392
    rs.fill(page, x, y3, 220, 230, rs.NIGHT)
    rs.stand(page, rs.shrink(shots["lower"], 0.34), x, y3 + 226, 220)
    text.append((x + 2, y3 + 236, 13, "from lower, looking up", soft))
    x += 232
    # the 64 px read: the keeper whole with its pole 64 px tall, the Shade at the same studs to a pixel
    f64 = 64 / ls.figure_height(shots["smalldusk"])
    for r, (ground, which, dark) in enumerate(((ls.DUSK, "dusk", False), (rs.DAY, "day", False), (rs.PAPER, "day", True))):
        rs.fill(page, x, y3 + r * 78, 170, 76, ground)
        for c, name in enumerate((f"small{which}", f"shade{which}")):
            shot = rs.shrink(shots[name], f64)
            rs.stand(page, ss.solid(shot) if dark else shot, x + 6 + c * 80, y3 + r * 78 + 72, 80)
    text.append((x, y3 + 236, 13, "64 px, beside a Shade", soft))

    y4 = 1420
    for i, (kind, label) in enumerate((("Color", "the colour map, 1024 px"), ("Emissive", "the glow mask"), ("Metalness", "metalness"))):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        rs.paste(page, rs.shrink(atlas, 220 / SIZE), 24 + i * 232, y4)
        text.append((24 + i * 232, y4 + 226, 12, label, soft))
    for i, line in enumerate(facts):
        text.append((740 + (i // 12) * 590, y4 + (i % 12) * 21, 13, line, ink))
    rs.paste(page, rs.text_layer(W, H, text), 0, 0)
    rs.save(page, out / f"{NAME.lower()}_model_sheet.png")
    rs.save(rs.shrink(page, 0.5), out / f"{NAME.lower()}_model_sheet_small.png")
    return rings


def atlas_check(paths, out):
    """The maps as they upload, for the content check: whole, and at 64 px on a dark and a bright ground."""
    page = rs.canvas(SIZE * 2 + 60, SIZE + 260, rs.NIGHT)
    soft = "#9A9CA8"
    text = []
    for i, kind in enumerate(("Color", "Emissive")):
        atlas = rs.load(paths[kind])
        atlas[..., 3] = 1.0
        x = 20 + i * (SIZE + 20)
        rs.paste(page, atlas, x, 20)
        small = rs.shrink(atlas, 64 / SIZE)
        rs.fill(page, x + 100, SIZE + 60, 104, 104, rs.DAY)
        rs.paste(page, small, x, SIZE + 80)
        rs.paste(page, small, x + 120, SIZE + 80)
        rs.paste(page, rs.shrink(atlas, 180 / SIZE), x + 240, SIZE + 60)
        text.append((x, SIZE + 44, 13, f"{paths[kind].name}: 64 px on dark and on bright, and at 180 px", soft))
    rs.paste(page, rs.text_layer(page.shape[1], page.shape[0], text), 0, 0)
    rs.save(page, out / f"{NAME.lower()}_atlas_check.png")


def blocking(scene, joints, group, out):
    """The stance in clay, before any bake (--stance): the views and the ring's camera, to judge the pose cheaply."""
    shots = {}
    for name, pose, view in (("front", "stance", FRONT), ("side", "stance", SIDE), ("seen", "stance", SEEN),
                             ("challenge", "challenge", SEEN), ("windup", "windup", (138, 12))):
        rest(joints)
        POSES[pose](joints)
        meshes = [o for o in scene.objects if o.type == "MESH"]
        at, across = framing(meshes, view)
        rs.workbench(scene, 640, 640)
        path = out / f"_{name}.png"
        shots[name] = rs.shoot(scene, path, view[0], view[1], at, across * 1.06)
        path.unlink()
    rest(joints)
    pose_stance(joints, LIFT)
    (x, y), turn = ls.RING["keeper"]
    group.location, group.rotation_euler, group.scale = (x, y, 0), (0, 0, math.radians(turn)), (SCALE,) * 3
    ortho = scene.camera
    ls.perspective(scene)
    rs.workbench(scene, *ls.RING["size"])
    path = out / "_ring.png"
    ring = ls.rendered(scene, path)
    path.unlink()
    scene.camera = ortho
    page = rs.canvas(5 * 330 + 20, 360 + 560, rs.PAPER)
    for i, name in enumerate(shots):
        rs.stand(page, rs.shrink(shots[name], 0.5), 10 + i * 330, 340, 320)
    rs.paste(page, ring, 10, 350)
    rs.save(page, out / "lamplighter_stance.png")


def main():
    sys.stdout.reconfigure(line_buffering=True)  # the measures reach the log even if the run is stopped
    out = bl.out_dir()
    rs.OUT = ss.OUT = ls.OUT = out
    scene = bl.reset_scene()
    m = materials()
    joints, group = build(scene, m)
    near = clearances(scene, joints, group)
    widest = stride(joints)
    print(f"in the stance: the pole {near['pole_brim']:.2f} off the brim, the lantern {near['lamp_brim']:.2f} off it and "
          f"{near['lamp_pole']:.2f} off its pole; from the ring's camera the lantern {near['ring_gap']:.0f} px clear of the "
          f"mask; a stride holds to {widest} degrees")
    if "--stance" in sys.argv:
        blocking(scene, joints, group, out)
        return
    rest(joints)
    pose_stance(joints)
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ v.co for key in ("neck",) for o in joints[key].children if o.type == "MESH" for v in o.data.vertices]
    hat_top = max(p.z for p in pts)
    groups = take_pieces(joints)
    for index, piece in enumerate(PIECES):
        xs = [v.co.x for o in groups[piece] for v in o.data.vertices]
        if max(abs(min(xs)), abs(max(xs))) > APART / 2 - 0.2:
            raise SystemExit(f"{piece} reaches {min(xs):.2f} to {max(xs):.2f} in x: past its slot in the bake")
    hidden = total = 0
    for index, piece in enumerate(PIECES):
        h, t = rm.mark_faces(groups[piece], index)
        hidden, total = hidden + h, total + t
        for o in groups[piece]:
            o.data.transform(Matrix.Translation((APART * index, 0, 0)))
    whole = bl.join([o for piece in PIECES for o in groups[piece]], NAME)
    area, density = rm.unwrap(whole, SURFACES, LIT)
    print(f"faces {total}, unseen {hidden}; seen area {area:.1f} sq studs; {density:.0f} px per stud at {SIZE}")
    paths = bake(whole, out)
    made = split(whole)
    recipe = export(made, paths, out, density)
    recipe["stride"] = {"degrees": widest, "note": "each leg's widest swing, forward and back, that stays inside the long "
                                                    "coat's hem; the Shade's walk swings 30 forward"}
    (out / f"{NAME}.recipe.json").write_text(json.dumps(recipe, indent=1))
    tris = {p["name"].split("_", 1)[1]: p["tris"] for p in recipe["pieces"]}
    facts = [f"{recipe['tris']} triangles in {len(made)} pieces:",
             f"  the body {sum(tris[p] for p in ('Torso', 'RightArm', 'LeftArm', 'RightLeg', 'LeftLeg'))}, the head {tris['Head']},",
             f"  the pole {tris['Pole']}, the lantern {tris['Lantern']}",
             f"in the stance, {hat_top:.2f} studs to the hat's top, {hat_top * SCALE:.1f} at 1.5;",
             f"  the pole's top {ls.POLE_TOP:.1f}, {ls.POLE_TOP * SCALE:.1f} at 1.5",
             f"one {SIZE} px atlas, {density:.0f} px per stud",
             "maps: colour, roughness, metalness, glow mask",
             "2 joints of their own: the pole, the lantern",
             f"EmissiveStrength: the body {HOT:g}, the mask {MASK_HOT:g},",
             f"  the lantern {COLD:g} cold, {BURN:g} hot",
             f"a stride holds to {widest} degrees each way",
             f"the pole stands {near['pole_brim']:.2f} off the brim,",
             f"  the lantern {near['lamp_brim']:.2f} off it, {near['lamp_pole']:.2f} off its pole",
             f"the ring's camera: the lantern {near['ring_gap']:.0f} px clear of the mask",
             f"the coat {COLOURS['Coat']}, value {value(np.array([[rs.rgb(COLOURS['Coat'])]], dtype=np.float32))[0, 0]:.2f} "
             f"(Pip's robe {value(np.array([[rs.rgb('#46348A')]], dtype=np.float32))[0, 0]:.2f})"]
    print("; ".join(facts))
    review(scene, joints, group, made, paths, out, facts)
    atlas_check(paths, out)


if __name__ == "__main__":
    main()
