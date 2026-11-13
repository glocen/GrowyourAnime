"""Rook's clips on the R6 rig, his baked model riding it (AR1, delivery 3).

blender.exe -b --factory-startup --python tools/blender/rook_clips.py -- <out_dir> [poses|export|audit] [clip ...]

- poses (the default): one sheet a clip, its key poses from the player's assumed camera and from his front.
- export: Rook_<Clip>.json for the builder (r6anim.export, with its audit), the ram's clearance from the body, one
  review pack a clip, and its arcs (one dot a frame).
- audit: the export without the review packs.

Needs rook_model.py's output (rook_model.blend and Rook.recipe.json) in MODEL. Every clip is keyed at 60 fps on its own
stretch of one timeline and starts from HUB, the stance the one-shots share. Feet are given as places on the floor:
each key solves the legs onto them, sinks a leg into the hip where the other is the longer reach (R6 has no knee),
and rests the lower sole on the floor; ground() then does the same on every frame between the keys.
Stage directions: right, forward, up, in studs, from where he stands.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_sheet as rs  # noqa: E402

FPS = 60
MODEL = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "rook" / "model"
GAME, FRONT = (152.0, 18.0), (38.0, 8.0)  # the camera's azimuth from his front and its elevation; GAME is assumed
SINK = 0.6  # studs a leg may slide up into the hip
STEP = 0.3  # studs a travelling foot lifts, at most
NOD = 28.0  # degrees the head may pitch against the torso: past 30 the chin sinks into the collar
ENEMY = (0.0, 7.0, 4.2)
PLANT = (2.45, 0.4, 0.56)  # where the ram stands on the floor while he is down
MARK = (-5.5, 3.45, 2.6)  # where the taped hand points through Haymaker's hold: 58° left of you, near his own shoulder
# line, so from the camera behind his right shoulder the arm stands clear of his body (research's fix 3). Re-aim it when
# Config holds the camera.
JAB = (-2.4, 1.9, 3.5)  # where the jab lands: 40° left of you, for the same camera (research, on the pose sheets)
KNUCKLES = (0.22, -1.7825, -0.06)  # the ram's striking face, in the right arm's frame (the recipe's point)
HAND = (0.0, -1.0, 0.0)
SHORT = {"T": "Torso", "H": "Head", "RA": "Right Arm", "LA": "Left Arm", "RL": "Right Leg", "LL": "Left Leg"}
EASE = {None: ("BEZIER", "AUTO"), "in": ("CUBIC", "EASE_IN"), "out": ("QUART", "EASE_OUT"), "snap": ("QUAD", "EASE_IN"),
        "hold": ("CONSTANT", "AUTO"), "lin": ("LINEAR", "AUTO"), "sine": ("SINE", "EASE_IN_OUT"),
        "back": ("BACK", "EASE_OUT"), "cubic": ("CUBIC", "EASE_IN_OUT")}


def W(right, forward, up=0.0) -> Vector:
    """A stage place as a Roblox world point: he faces -Z."""
    return Vector((right, up, -forward))


# --- the rig with the model on it -----------------------------------------------------------------------------------

def build():
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    recipe = json.loads((MODEL / "Rook.recipe.json").read_text())
    c = {name: rs.srgb(code)[:3] for name, code in rs.PALETTE.items()}
    rig = r6.build_rig("Rook", {"Torso": c["Oxblood"], "Head": c["Skin"], "Right Arm": c["Iron"], "Left Arm": c["Bone"],
                                "Right Leg": c["Charcoal"], "Left Leg": c["Charcoal"], "Face": c["Ink"]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    blend = MODEL / "rook_model.blend"
    if not blend.exists():
        raise SystemExit(f"No {blend}: run rook_model.py first")
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("Rook_")]
    costume = {o.name: o for o in dst.objects}
    for piece in recipe["pieces"]:
        obj = costume[piece["name"]]
        scene.collection.objects.link(obj)
        holder = rig.parts[piece["on"]]
        if "motor" in piece:  # a joint of its own on the arm, keyed and exported under the piece's name
            local = r6.to_roblox(holder.matrix_world).inverted() @ Matrix.Translation(Vector(piece["pivot"]))
            base = r6._empty(f"Rook.C0.{obj.name}", holder, local, 0.1)
            holder = rig.joints[obj.name] = rig.parts[obj.name] = r6._empty(f"Rook.J.{obj.name}", base, Matrix.Identity(4), 0.1)
            rig.bases[obj.name] = Matrix.Identity(4)
            rig.claws[piece["on"]] = obj.name
            bpy.context.view_layer.update()
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:  # Workbench draws the active image node: the colour map
            nodes = slot.material.node_tree.nodes
            nodes.active = next(n for n in nodes if n.type == "TEX_IMAGE" and "Color" in n.image.name)
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects["Rook.Face"]]

    def undress(bare: bool):
        for o in costume.values():
            o.hide_render = bare
        for o in blocks:
            o.hide_render = not bare

    undress(False)
    feet = {leg: r6._empty(f"Rook.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    for empty in feet.values():  # a holder of numbers: where the foot stands (x right, y forward) and the crouch (z)
        empty.location = (0, 0, 0)
    return scene, rig, costume, undress, feet


# --- keying ---------------------------------------------------------------------------------------------------------

HUB = {
    "T": (5, -24, 0), "feet": {"Right Leg": (0.7, -0.5), "Left Leg": (-0.55, 0.55)}, "RL": (0, 0, 0), "LL": (0, 0, 0),
    "crouch": 0.12, "look": ENEMY, "H": (0, 0, 0), "RA": (14, 0, 22), "LA": (60, 0, -2), "P": 0.0, "TP": (0, 0, 0),
}


def pose(rig, part, data):
    rig.joints[part].matrix_basis = r6.to_blender(r6.transform(rig, part, data))


def stand_legs(rig, torso, planted, crouch, loose, heights=None, sinks=None):
    """Solves the legs under a torso pose and returns (the torso with its height set, the legs' poses, the deepest
    sink). `planted` {leg: floor place} are solved onto their places; the leg that reaches lower slides up into the
    hip until both soles sit at their heights (`heights`, a lifted foot's over the floor), and the lowest corner of
    either leg rests on the floor. `loose` {leg: pose} are legs given by their angles. A leg standing alone keeps the
    sink `sinks` gives it (the one its keys solved), so nothing jumps where the other leg lands. R6's legs never turn:
    their pivot is the hip's outer edge, and a turn swings the whole leg out of the hip."""
    heights = heights or {}
    torso, legs = list(torso), {}
    sink = {leg: (sinks[leg] if sinks and len(planted) < 2 and leg in sinks else crouch) for leg in r6.LEGS}
    for _ in range(6):
        pose(rig, "Torso", torso)
        r6._refresh()
        for leg in r6.LEGS:
            if leg in planted:
                move = (0.0, sink[leg], 0.0)
                legs[leg] = (*r6.stand(rig, leg, planted[leg], (0, 0, 0), move=move), *move)
            else:
                legs[leg] = tuple(loose[leg])
            pose(rig, leg, legs[leg])
        r6._refresh()
        lows = {leg: r6.sole(rig, leg) - heights.get(leg, 0.0) for leg in planted}
        if len(lows) == 2:
            top = max(lows.values())
            for leg, low in lows.items():
                sink[leg] = min(SINK + 0.3, max(crouch, sink[leg] + top - low))
            spare = min(sink.values()) - crouch
            for leg in sink:
                sink[leg] -= spare
        corners = [r6.world_point(rig, leg, (x, y, z)).y - (heights.get(leg, 0.0) if leg in planted else 0.0)
                   for leg in r6.LEGS for x in (-0.5, 0.5) for y in (-1, 1) for z in (-0.5, 0.5)]
        torso[4] -= min(corners)
    return tuple(torso), legs, (max(sink[leg] for leg in planted) if planted else 0.0)


class Take:
    """One clip being keyed from `start`. Each key changes only what it names; the rest holds from the key before."""

    def __init__(self, rig, feet, name, start):
        self.rig, self.feet, self.name, self.start = rig, feet, name, start
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in HUB.items()}
        self.end, self.markers, self.beats, self.loop, self.warned, self.keys = 0, [], [], False, [], []

    def mark(self, frame, name):
        self.markers.append((round(frame / FPS, 4), name))

    def key(self, f, label=None, ease=None, only=None, **changes):
        """Keys the pose at clip frame `f`. `ease` shapes the move that starts here. `label` puts it on the pose sheet.
        Changes: T (pitch, turn, roll, right, _, forward), feet {leg: (right, forward), or None for a leg given by its
        angles in RL / LL}, crouch, look (a stage place) or H (angles), RA / LA (angles, or ("reach", place, hint, local
        point)), P (the piston's draw), TP (the tape's angles). `only="P"` keys the piston alone: it slams home on the
        frame after a contact, and a whole-body key there would stop the swing for a frame."""
        s, rig, frame = self.state, self.rig, self.start + f
        if "feet" in changes:
            changes["feet"] = {**s["feet"], **changes["feet"]}
        if "H" in changes and "look" not in changes:
            s["look"] = None
        s.update(changes)
        interp = EASE[ease]
        bpy.context.scene.frame_set(frame)
        if only == "P":
            r6._key_parts(rig, frame, {"Rook_Piston": (0, 0, 0, 0, s["P"], 0)}, *interp)
            return self
        torso = list(s["T"]) + [0.0] * (6 - len(s["T"]))
        torso[5] = -torso[5]  # forward, as a Roblox move
        planted = {leg: W(*at) for leg, at in s["feet"].items() if at is not None}
        loose = {leg: (*s["RL" if leg == "Right Leg" else "LL"][:3], 0.0, 0.0, 0.0) for leg in r6.LEGS if leg not in planted}
        torso, legs, sink = stand_legs(rig, torso, planted, s["crouch"], loose)
        if sink > SINK:
            self.warned.append(f"{self.name} {f}: a leg sinks {sink:.2f} into the hip")
        r6._key_parts(rig, frame, {"Torso": torso, **legs}, *interp)
        r6._refresh()
        for leg, empty in self.feet.items():  # where each foot stands and how low he sits, for the pass between keys
            at = s["feet"][leg]
            if at is not None:
                empty.location.x, empty.location.y = at
            empty.location.z = s["crouch"]
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *interp)
        self.keys.append((f, frozenset(planted)))
        rest = {}
        if s.get("look") is not None:
            pitch, turn, tilt = r6.look(rig, W(*s["look"]), s["H"])
            rest["Head"] = (max(-NOD, min(NOD, pitch)), turn, tilt)
        else:
            rest["Head"] = s["H"]
        for arm in ("RA", "LA"):
            a = s[arm]
            if a[0] == "reach":
                local = a[3] if len(a) > 3 else (KNUCKLES if arm == "RA" else HAND)
                rest[SHORT[arm]] = r6.reach(rig, SHORT[arm], local, W(*a[1]), a[2])
            else:
                rest[SHORT[arm]] = a
        rest["Rook_Piston"] = (0, 0, 0, 0, s["P"], 0)
        rest["Rook_Tape"] = s["TP"]
        r6._key_parts(rig, frame, rest, *interp)
        self.end = max(self.end, f)
        if label:
            self.beats.append((f, label))
        return self

    def planted_at(self, f):
        """The legs that stand on the floor at frame `f`: those planted at the keys on both sides of it."""
        before = max((k for k in self.keys if k[0] <= f), key=lambda k: k[0])
        after = min((k for k in self.keys if k[0] >= f), key=lambda k: k[0])
        return before[1] & after[1]


def ground(rig, feet, takes):
    """Between the keys the legs would swing from one solved pose to the next, and a planted foot would slide and dip
    through the floor. This pass solves every frame again: each planted foot on its place as that place moves, lifted
    as it travels (a step), the hips at the height the legs allow. It keys the torso and the legs on every frame."""
    scene = bpy.context.scene
    parts = ("Torso", *r6.LEGS)
    sampled = {}
    for take in takes:
        for f in range(take.end + 1):
            scene.frame_set(take.start + f)
            sampled[take.name, f] = ({part: r6.pose_of(rig, part) for part in parts},
                                     {leg: tuple(e.location) for leg, e in feet.items()})
    for part in parts:
        rig.joints[part].animation_data_clear()
        rig.last.pop(part, None)
    for take in takes:
        for f in range(take.end + 1):
            poses, places = sampled[take.name, f]
            before, after = sampled[take.name, max(f - 1, 0)][1], sampled[take.name, min(f + 1, take.end)][1]
            planted, heights = {}, {}
            for leg in take.planted_at(f):
                planted[leg] = W(places[leg][0], places[leg][1])
                speed = math.hypot(after[leg][0] - before[leg][0], after[leg][1] - before[leg][1]) / 2  # studs a frame
                heights[leg] = min(STEP, 2.5 * speed)
            loose = {leg: poses[leg] for leg in r6.LEGS if leg not in planted}
            torso, legs, _ = stand_legs(rig, poses["Torso"], planted, places["Right Leg"][2], loose, heights,
                                        {leg: poses[leg][4] for leg in planted})
            for part, data in {"Torso": torso, **legs}.items():
                joint = rig.joints[part]
                pose(rig, part, data)
                rotation, last = joint.rotation_quaternion.copy(), rig.last.get(part)
                if last is not None and last.dot(rotation) < 0:
                    rotation.negate()
                    joint.rotation_quaternion = rotation
                rig.last[part] = rotation
                joint.keyframe_insert("location", frame=take.start + f)
                joint.keyframe_insert("rotation_quaternion", frame=take.start + f)


# --- the clips ------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses. R6's hips are its chest: the torso turns only as far as
# the feet under it allow, so a big turn comes with a step.

def idle(t):
    """He waits like a door: weight sunk, the ram hanging heavy off the hip, one slow breath, eyes on you."""
    t.loop = True
    t.key(0, "the stance", ease="sine")
    t.key(64, "breath in", ease="sine", T=(3, -24, 0), crouch=0.07, RA=(11, 0, 25), LA=(63, 0, -3), TP=(4, 0, 5))
    t.key(104, ease="sine", T=(5.8, -25, 0), crouch=0.14, RA=(16, 0, 21), LA=(59, 0, -1), TP=(-4, 0, -4))
    t.key(144, ease="sine", T=(5, -24, 0), crouch=0.12, RA=(14, 0, 22), LA=(60, 0, -2), TP=(0, 0, 0))


def combo(t):
    """A jab to find you, a hook with the ram to move you, then the ram straight down, and each one costs him more."""
    t.key(0)
    t.key(5, ease="in", T=(4, -14, 0), LA=(50, 0, -6))
    t.key(12, "1: the jab", T=(9, -22, 0, 0, 0, 0.25), LA=("reach", JAB, (80, 0, -40)), RA=(4, 0, 24), TP=(-20, 0, 0))
    t.mark(12, "Hit1")
    t.key(15, T=(9, -22, 0, 0, 0, 0.25), TP=(14, 0, 0))
    t.key(26, "wound for the hook", T=(3, -50, 0, 0, 0, -0.15), LA=(64, 0, -2), RA=(-28, 0, 34), crouch=0.22, TP=(6, 0, 0))
    t.key(40, ease="in", T=(3, -55, 0, 0, 0, -0.2), RA=(-34, 0, 36), TP=(0, 0, 0))
    t.key(45, ease="lin", T=(5, -26, 0, 0, 0, 0.02), RA=(20, 0, 70), LA=(50, 0, -10), crouch=0.21, TP=(0, 0, 10),
          feet={"Right Leg": (0.74, -0.33)})  # the breakdown: round the side
    t.key(48, "2: the hook", T=(8, 14, 0, 0, 0, 0.3), RA=(74, 0, 26), LA=(30, 0, -26), crouch=0.2, TP=(0, 0, 20),
          feet={"Right Leg": (0.8, -0.05)})
    t.mark(48, "Hit2")
    t.key(54, T=(8, 20, 0, 0, 0, 0.3), RA=(78, 0, 18), TP=(0, 0, -10))
    t.key(64, T=(-4, 4, 0, 0, 0, 0.1), RA=(120, 0, 48), LA=(40, 0, -30), crouch=0.05, P=0.3)
    t.key(72, "the ram up", T=(-12, -8, 0, 0, 0, -0.1), RA=(176, 0, 26), LA=(52, 0, -34), crouch=0.0, P=0.45, TP=(10, 0, 0),
          feet={"Right Leg": (0.75, -0.35)})
    t.key(79, ease="snap", T=(-14, -10, 0, 0, 0, -0.12), RA=(182, 0, 26), P=0.5)
    t.key(86, "3: straight down", T=(30, 6, 0, 0, 0, 0.35), RA=(52, 0, 18), LA=(-20, 0, -34), crouch=0.3,
          feet={"Left Leg": (-0.55, 0.8)}, TP=(-25, 0, 0))
    t.mark(86, "Hit3")
    t.key(87, only="P", P=0.0)
    t.key(92, T=(33, 7, 0, 0, 0, 0.35), RA=(46, 0, 22), crouch=0.3, TP=(15, 0, 0))
    t.key(99, T=(30, 5, 0, 0, 0, 0.3), LA=(10, 0, -30), TP=(0, 0, 0))
    t.key(120, T=HUB["T"], RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"], feet=HUB["feet"])


def haymaker(t):
    """He draws the ram back until it fills the camera, the taped arm thrown out along his shoulders to mark you, waits
    a beat too long, and then the room moves: he steps clean through you behind the ram."""
    t.key(0)
    t.key(8, ease="cubic", T=(9, -12, 0, 0, 0, 0.12), RA=(30, 0, 20), LA=(56, 0, -36), crouch=0.2)
    t.mark(8, "Charge")
    t.key(34, "wound", ease="lin", T=(2, -36, 0, 0, 0, -0.42), RA=(-46, 0, 46), LA=("reach", MARK, (-10, 0, -76)), crouch=0.26,
          P=0.3, feet={"Right Leg": (0.6, -1.0)}, TP=(8, 0, 0))  # the hold creeps: the piston draws, the body winds on
    t.key(52, "the beat too long", ease="in", T=(-1, -46, 0, 0, 0, -0.56), RA=(-60, 0, 48), LA=("reach", MARK, (-10, 0, -76)),
          crouch=0.36, P=0.65, TP=(-6, 0, 0))
    t.key(55, ease="lin", T=(4, -20, 0, 0, 0, -0.05), RA=(20, 0, 70), LA=(12, 0, -58), crouch=0.3, TP=(0, 0, 20),
          feet={"Right Leg": (0.62, -0.5)})  # the breakdown: the ram goes round wide and rising, never under the shoulder
    t.key(57, "contact", T=(12, 12, 0, 0, 0, 0.55), RA=(86, 0, 34), LA=(-26, 0, -36), crouch=0.2,
          feet={"Right Leg": (0.65, 0.2)}, TP=(0, 0, 30))
    t.mark(57, "Strike")
    t.key(58, only="P", P=0.0)
    t.mark(58, "Shock")
    t.key(63, "through", T=(15, 46, 0, 0, 0, 0.95), RA=(88, 0, 6), LA=(-34, 0, -40), crouch=0.18, TP=(0, 0, -15),
          feet={"Right Leg": (0.6, 1.35)})
    t.mark(63, "Step")
    t.mark(70, "Vent")
    t.key(76, ease="cubic", T=(14, 40, 0, 0, 0, 0.9), RA=(82, 0, 10), TP=(0, 0, 0))
    t.key(100, T=(8, 4, 0, 0, 0, 0.3), RA=(36, 0, 22), LA=(30, 0, -10), crouch=0.16, feet={"Right Leg": (0.7, -0.2)})
    t.key(120, T=HUB["T"], RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"], feet=HUB["feet"])


def hit(t):
    """It lands on the lead shoulder and turns him, and the ram's weight swings him straight back to you. A flinch
    (docs/design.md, "States in a fight"): short, and the feet never move, so it sits over whatever he was doing."""
    t.key(0, ease="out")
    t.key(3, "struck", T=(-10, -40, 4, 0, 0, -0.2), H=(-20, 28, 8), LA=(24, 0, -44), RA=(30, 0, 40), crouch=0.06, TP=(-30, 0, 0))
    t.key(7, T=(-8, -37, 3, 0, 0, -0.16), H=(-10, 30, 4), TP=(20, 0, 0))
    t.key(18, T=HUB["T"], look=ENEMY, H=(0, 0, 0), LA=HUB["LA"], RA=HUB["RA"], crouch=HUB["crouch"], TP=(0, 0, 0))


SIT = dict(T=(20, -10, 0, 0, 0, -0.2), feet={"Right Leg": None, "Left Leg": None}, RL=(108, 0, 0), LL=(98, 0, -5), crouch=0.0,
           RA=("reach", PLANT, (40, 0, 30)), LA=(8, 0, -34), H=(26, 6, 0), TP=(0, 0, 0))  # R6 has no knee to go down on


def down(t):
    """The legs go first. He sits down hard, hangs on the ram like a post, and the head drops last."""
    t.key(0, ease="out")
    t.key(6, "the blow", T=(-14, -34, 0, 0, 0, -0.3), H=(-24, 20, 0), LA=(20, 0, -50), RA=(40, 0, 40), crouch=0.0)
    t.key(22, "the legs go", ease="in", T=(16, -20, 0, 0, 0, -0.1), H=(10, 14, 0), LA=(40, 0, -20), RA=(40, 0, 26), crouch=0.38)
    t.key(34, "down", **{**SIT, "T": (14, -10, 0, 0, 0, -0.25), "H": (4, 10, 0), "TP": (-20, 0, 0)})
    t.mark(34, "Land")
    t.key(40, T=(23, -10, 0, 0, 0, -0.2), H=(16, 8, 0), TP=(10, 0, 0))
    t.key(60, "held", ease="hold", **SIT)
    t.key(66)


def up(t):
    """He pushes off the ram, rocks his weight over his feet, and the head comes up before the body is ready."""
    t.key(0, **SIT)
    t.key(10, "the push", T=(34, -12, 0, 0, 0, -0.05), RL=(112, 0, 0), LL=(104, 0, -5), H=(4, 10, 0))
    t.key(26, "the feet under", T=(38, -20, 0, 0, 0, 0.1), feet={"Right Leg": (0.7, 0.1), "Left Leg": (-0.55, 0.8)},
          crouch=0.45, RA=(60, 0, 24), LA=(50, 0, -26), look=ENEMY, H=(0, 0, 0))
    t.key(42, "up", T=(2, -24, 0), feet=HUB["feet"], crouch=0.04, RA=(10, 0, 26), LA=(56, 0, -2))
    t.key(54, T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])


def reveal(t):
    """He comes out of the shard folded small behind the ram, his head up: he's already sizing you up from under his
    brow, the one line that reads in the dark (AR3 section 4, research's fix 6). He opens up to his full width, puts the
    ram straight up over his head, and it fires once at the sky. The kick drops him into his knees as his name slams
    down (fix 1: `Name`, the recoil's floor), and he holds it there, looking at you."""
    low = dict(T=(24, 0, 0, 0, 0, 0.1), feet={"Right Leg": (0.75, -0.2), "Left Leg": (-0.75, 0.2)},
               crouch=0.56, H=(-16, 0, 0), RA=(34, 0, 22), LA=(60, 0, -10))
    t.key(0, "folded, eyes up", **low)
    t.key(16, ease="back", **{**low, "T": (27, 0, 0, 0, 0, 0.1), "RA": (70, 0, 18), "LA": (60, 0, -16)})
    t.key(30, "opens", T=(-8, 0, 0), crouch=0.02, H=(-10, 0, 0), RA=(16, 0, 62), LA=(16, 0, -56), TP=(0, 0, -30))
    t.key(44, "the ram up", T=(-6, -10, 0), RA=(164, 0, 44), LA=(20, 0, -30), look=(1.2, 1.0, 9.0), H=(0, 0, 0),
          crouch=0.04, P=0.55, TP=(0, 0, 10), feet=HUB["feet"])
    t.key(49, ease="snap", RA=(172, 0, 30), P=0.65)
    t.key(51, "it fires", ease="out", T=(-2, -10, 0), RA=(168, 0, 20), P=0.0, crouch=0.10, TP=(-16, 0, 0))
    t.mark(51, "Knock")
    t.key(55, "the kick: his name", ease="sine", T=(5, -11, 0), RA=(165, 0, 24), look=ENEMY, crouch=0.26, TP=(-6, 0, 0))
    t.mark(55, "Name")
    t.key(64, ease="sine", T=(-5, -12, 0), RA=(176, 0, 12), crouch=0.06, TP=(8, 0, 0))
    # The hold stands the ram within 15° of straight up: a straight arm held lower than that is a pose the content check
    # blocks (handbook/platform/rules-and-moderation.md, "Salute-like poses"). The idle takes over after the card.
    t.key(96, "held for the name", T=(-6, -12, 0), RA=(177, 0, 12), crouch=0.04, TP=(0, 0, 0))


def work(t):
    """A shift at the bay: he lifts the ram, drops it on the post like a pile driver, and takes his time before the
    next one."""
    t.loop = True
    top = dict(T=(-8, -8, 0, 0, 0, -0.05), feet={"Right Leg": (0.65, -0.15), "Left Leg": (-0.65, 0.2)},
               crouch=0.02, look=(0.3, 2.4, 2.2), H=(0, 0, 0), RA=(170, 0, 28), LA=(34, 0, -22), P=0.5)
    t.key(0, "the ram up", ease="snap", **top)
    t.key(8, "the drop", T=(26, 4, 0, 0, 0, 0.2), RA=(58, 0, 18), LA=(-14, 0, -30), crouch=0.4, TP=(-22, 0, 0))
    t.mark(8, "Pump")
    t.key(9, only="P", P=0.0)
    t.key(14, T=(29, 5, 0, 0, 0, 0.2), RA=(52, 0, 20), crouch=0.44, TP=(14, 0, 0))
    t.key(40, "his time", ease="sine", T=(8, -4, 0), RA=(24, 0, 24), LA=(30, 0, -14), crouch=0.12, look=(0.2, 2.8, 2.6), TP=(0, 0, 0))
    t.key(74, ease="cubic", T=(5, -6, 0), RA=(20, 0, 26), crouch=0.08, look=(0.3, 2.4, 2.2))
    t.key(90, T=(-2, -7, 0), RA=(104, 0, 40), crouch=0.04, P=0.3)
    t.key(102, ease="sine", **{**top, "RA": (164, 0, 28), "P": 0.5})
    t.key(120, **top)


CLIPS = {"Idle": idle, "Combo": combo, "Haymaker": haymaker, "Hit": hit, "Down": down, "Up": up, "Reveal": reveal,
         "Work": work}


# --- checks and outputs ---------------------------------------------------------------------------------------------

def ram_points(costume):
    """Points of the gauntlet's shell, in the right arm piece's own frame: every third vertex below the jacket's
    shoulder that the R6 arm box doesn't hold."""
    obj = costume["Rook_RightArm"]
    pts = np.array([v.co[:] for v in obj.data.vertices])
    centre = np.array((1.5, 0.0, 3.0))
    away = np.abs(pts - centre) - np.array((0.5, 0.5, 1.0))
    return obj, pts[(away.max(axis=1) > 0.12) & (pts[:, 2] < 3.6)][::3]


def clearance(rig, costume, take):
    """How near the ram comes to the rest of the body over a clip, and to the floor: (studs, frame, part) and
    (studs, frame); negative is inside."""
    obj, pts = ram_points(costume)
    homog = np.concatenate([pts, np.ones((len(pts), 1))], axis=1)
    scene, worst, low = bpy.context.scene, (9.0, 0, ""), (9.0, 0)
    for f in range(take.end + 1):
        scene.frame_set(take.start + f)
        world = homog @ np.array(obj.matrix_world).T
        if world[:, 2].min() < low[0]:
            low = (float(world[:, 2].min()), f)
        for part in ("Torso", "Head", "Left Arm", "Right Leg", "Left Leg"):
            local = world @ np.array(rig.parts[part].matrix_world.inverted()).T
            size = r6.drawn(part)
            d = np.abs(local[:, :3]) - np.array((size[0], size[2], size[1])) / 2
            out = np.linalg.norm(np.maximum(d, 0), axis=1)
            dist = np.where(out > 0, out, d.max(axis=1)).min()
            if dist < worst[0]:
                worst = (float(dist), f, part)
    return worst, low


def cameras(scene, rig):
    return {name: r6.body_camera(scene, rig, 0, az, el, distance=13.0, name=name) for name, (az, el) in (("game", GAME), ("front", FRONT), ("side", (90.0, 6.0)))}


def pose_sheet(scene, cams, take, out):
    beats = take.beats
    shots = [(cams[view], take.start + f, f"{take.name} {f}: {label}" if view == "game" else f"{f}")
             for view in ("game", "front") for f, label in beats]
    scene.render.resolution_x, scene.render.resolution_y = 380, 420
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(beats))
    print(f"wrote {path}")


def arc_sheet(scene, rig, cams, take, out):
    """One dot a frame where the ram's face (amber) and the taped hand (bone) are through the clip, over the body at
    its middle beat: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)

    def at(rig, arm):
        return r6.to_roblox(rig.parts[arm].matrix_world)

    dots = r6.path_dots(rig, frames, [("Right Arm", KNUCKLES)], radius=0.06, name="Ram", at=at)
    dots += r6.path_dots(rig, frames, [("Left Arm", HAND)], colour=(0.92, 0.9, 0.82), radius=0.045, name="Hand", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    scene.render.resolution_x, scene.render.resolution_y = 640, 560
    path = r6.render_shots(scene, [(cams[view], beat, f"{take.name}: one dot a frame, {view}") for view in ("game", "side")],
                           out / f"arcs_{take.name}.png", columns=2)
    for dot in dots:
        bpy.data.objects.remove(dot, do_unlink=True)
    print(f"wrote {path}")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "export", "audit") else "poses"
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    scene, rig, costume, undress, feet = build()
    takes = {}
    for i, name in enumerate(CLIPS):
        if name in wanted:
            takes[name] = take = Take(rig, feet, name, 1000 * i)
            CLIPS[name](take)
            for line in take.warned:
                print("  " + line)
    ground(rig, feet, list(takes.values()))
    cams = cameras(scene, rig)
    for name, take in takes.items():
        (near, f, part), (low, at) = clearance(rig, costume, take)
        print(f"{name}: {take.end + 1} frames, {take.end / FPS:.2f} s; the ram's nearest: {near:.2f} studs at {f} ({part}); "
              f"over the floor {low:.2f} at {at}")
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        # the Name is the game's: Author.SaveBaked reads Anim_Rook<Clip> and checks the clip is named the same
        r6.export(rig, out / f"Rook_{name}.json", "Rook", f"Rook{name}", take.start, take.start + take.end,
                  markers=take.markers, source="tools/blender/rook_clips.py", extra={"Loop": take.loop})
        if mode == "audit":
            continue
        arc_sheet(scene, rig, cams, take, out)
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame: cams["game"], bare=FRONT[0], strip=strip, undress=undress,
                       notes=f"{name}: the ram's nearest {near:.2f} studs at {f} ({part})\n")


if __name__ == "__main__":
    main()
