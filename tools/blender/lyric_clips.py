"""Lyric's clips on the R6 rig, her baked model riding it (AR4, delivery 3).

blender.exe -b --factory-startup --python tools/blender/lyric_clips.py -- <out_dir> [poses|export|audit] [clip ...]

- poses (the default): one sheet a clip, its key poses from the player's assumed camera and two more sides, with the
  checks' numbers printed.
- export: Lyric_<Clip>.json for the builder (r6anim.export, with its audit), one review pack a clip, the mic's and the
  speakers' arcs (one dot a frame), the bare rig stepped from the side and the three-quarter, and Held Note's note at
  64 px on eight headings.
- audit: the export without the pictures.

Needs lyric_model.py's output (lyric_model.blend, Lyric.recipe.json and the maps) in MODEL. The keying is rook_clips.py's:
every clip at 60 fps on its own stretch of one timeline, starting from HUB; feet given as places on the floor. Stage
directions: right, forward, up, in studs, from where she stands.

Her Hit, Down and Up aren't here: reactions are a rig's shared set (docs/design.md, "States in a fight"), and her
definition names the one she wears.

Three tracks a clip, keyed apart:
- the body (Take.key);
- the stand (Take.stand): where its base is. R6 has no elbow and the stand's joint is at her fist, so the pole always
  passes through her right fist and swings about it. Planted, the base rests on the floor on its edge and the pole
  slides through the fist as the fist moves; lifted, the base is wherever the keys carry it. The mic leans back toward
  her, or, as much as `aim` says, toward her mouth;
- the speakers (Take.speak): two places on the stage and their turns, since nothing holds them, each solved against the
  torso as it stands, with a slow float of their own (BOB) and the kick of each shot (Take.kick).

How she moves: she plays every street like an arena. Everything lands on the beat (120 a minute: a beat is 30 frames),
the stand is her partner and her drum, and the speakers hit on her cue, never on their own.
"""
import contextlib
import io
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import lyric_sheet as ls  # noqa: E402

FPS = rc.FPS
BEAT = 30  # frames: 120 beats a minute
MODEL = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "lyric" / "model"
GAME, SIDE, FRONT = rc.GAME, (90.0, 6.0), rc.FRONT  # the camera's azimuth from her front and its elevation
QUARTER, MET = (48.0, 8.0), (348.0, 8.0)  # MET: from the target's side, a little off her free hand (the sheet's)
W = rc.W
STAFF, SR, SL = "Lyric_Staff", "Lyric_SpeakerR", "Lyric_SpeakerL"
EYES = (0.0, 10.0, 5.2)  # where she looks: at you, the chin a hair up
NOD = (0.0, 10.0, 3.6)  # the same, nodded on the beat
UP = Vector((0.0, 1.0, 0.0))

# The stand, in its own frame (Roblox, the base's middle at the origin, upright): its joint is 2.15 up the pole, where
# her hanging fist closes on it at rest; the mic's head leans 0.55 back off the pole's line, toward whoever holds it.
GRIP = 2.15
MIC = Vector((0.0, ls.STAFF - 0.3, 0.55))
TOP = ls.STAFF
BASE = ls.BASE
HOLD = (1.3, 5.2)  # studs up the pole her fist can hold it: over the base's weight, under the mic's clip
MOUTH = (0.0, -0.22, -0.62)  # in the head's frame
B0 = (1.62, 1.1)  # the stand's base as she stands: ahead of her right foot, the pole leant in to her fist

# The speakers: each at rest where the model puts it, turned in; they float, out of step with each other.
INWARD = {SR: ls.REST["dr"][1], SL: ls.REST["dl"][1]}
HOME = {SR: (2.68, -0.5, 5.15), SL: (-2.6, -0.65, 4.8)}  # the sheet's: at her shoulders, at two heights
BOB, RISE, SWAY = 120, 0.06, 4.0
BUZZ = 6  # frames a shake of the cones takes through the note: ten a second
STILL, HELD = 45.0, 6  # degrees a second under which an arm counts as held, and the frames it may be
TAIL = 30.0  # degrees her left leg may swing before it comes out of the jacket's tail (its hem is 0.8 under the hip)

# What the stand and the speakers must clear, as boxes in each part's frame (Roblox): R6's blocks with the costume's
# thickness. The right arm holds the pole, so it isn't one.
BOXES = {"Torso": ((0.0, 0.0, 0.0), (1.04, 1.0, 0.56)), "Head": ((0.0, 0.12, 0.09), (0.9, 0.75, 0.86)),
         "Left Arm": ((0.0, 0.0, 0.0), (0.56, 1.0, 0.56)), "Right Arm": ((0.0, 0.0, 0.0), (0.56, 1.0, 0.56)),
         "Right Leg": ((0.0, 0.0, -0.07), (0.55, 1.0, 0.62)), "Left Leg": ((0.0, 0.0, -0.07), (0.55, 1.0, 0.62))}
FACE = ((0.0, 0.0, 0.0), (0.6, 0.6, 0.62))  # R6's head itself, in its frame: what the mic's head comes to and stops at
POLE_R, MIC_R, CAB = 0.07, 0.3, 0.62  # the pole's radius, the mic's head's, a speaker's cabinet's (a ball round it)
SKIN = {"Torso": "Lyric_Torso", "Head": "Lyric_Head", "Left Arm": "Lyric_LeftArm", "Right Leg": "Lyric_RightLeg",
        "Left Leg": "Lyric_LeftLeg", "Right Arm": "Lyric_RightArm"}  # the surfaces the stand is measured against (her
# right arm only while the stand is out of her hand)


class Skin:
    """The model's pieces as surfaces to measure the stand against, rather than boxes: a box round her head takes in
    the hair's whole volume. Rigid pieces, so each is built once in its own frame."""

    def __init__(self):
        self.pieces = {}
        for part, name in SKIN.items():
            obj = bpy.data.objects[name]
            mesh = obj.data
            if abs(obj.matrix_world.to_scale().length - math.sqrt(3)) > 1e-3:
                raise SystemExit(f"{name} is scaled: its surface distances would be off")
            self.pieces[part] = (obj, BVHTree.FromPolygons([v.co.copy() for v in mesh.vertices],
                                                           [tuple(p.vertices) for p in mesh.polygons]))

    def gap(self, points, part, radius) -> float:
        """How far a run of Roblox world points (a line, in order) stays off the piece's surface, less `radius`, in
        studs; any stretch that passes through the surface counts as -0.01 or less."""
        obj, tree = self.pieces[part]
        inv = obj.matrix_world.inverted()
        local = [inv @ (r6.M @ Vector(p)) for p in points]
        out = min(tree.find_nearest(q)[3] for q in local) - radius
        for a, b in zip(local, local[1:]):
            span = (b - a).length
            if span > 1e-6 and tree.ray_cast(a, (b - a) / span, span)[0] is not None:
                return min(out, -0.01)
        return out


# --- the rig with the model on it -----------------------------------------------------------------------------------

def build():
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.show_backface_culling = True  # one-sided, as Roblox draws a MeshPart: the edges rely on it
    recipe = json.loads((MODEL / "Lyric.recipe.json").read_text())
    c = {name: rs.srgb(code)[:3] for name, code in ls.PALETTE.items()}
    rig = r6.build_rig("Lyric", {"Torso": c["Limelight"], "Head": c["Skin"], "Right Arm": c["Limelight"],
                                 "Left Arm": c["Limelight"], "Right Leg": c["Backstage"], "Left Leg": c["Backstage"],
                                 "Face": c["Ink"]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    blend = MODEL / "lyric_model.blend"
    if not blend.exists():
        raise SystemExit(f"No {blend}: run lyric_model.py first")
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("Lyric_")]
    costume = {o.name: o for o in dst.objects}
    motors = {}
    for piece in recipe["pieces"]:
        obj = costume[piece["name"]]
        scene.collection.objects.link(obj)
        holder = rig.parts[piece["on"]]
        if "motor" in piece:  # a joint of its own, keyed and exported under the piece's name
            local = r6.to_roblox(holder.matrix_world).inverted() @ Matrix.Translation(Vector(piece["pivot"]))
            motors[obj.name] = r6._empty(f"Lyric.C0.{obj.name}", holder, local, 0.1)
            holder = rig.joints[obj.name] = rig.parts[obj.name] = r6._empty(f"Lyric.J.{obj.name}", motors[obj.name], Matrix.Identity(4), 0.1)
            rig.bases[obj.name] = Matrix.Identity(4)
            rig.claws[obj.name] = obj.name  # two ride the Torso: keyed by piece, so neither hides the other
            bpy.context.view_layer.update()
        if piece.get("edge") or "motor" in piece:
            obj.display.show_shadows = False  # as the recipe asks of the engine: CastShadow off
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:  # Workbench draws the active image node: the colour map
            nodes = slot.material.node_tree.nodes
            nodes.active = next(n for n in nodes if n.type == "TEX_IMAGE" and "Color" in n.image.name)
            slot.material.use_backface_culling = True
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects["Lyric.Face"]]

    def undress(bare: bool):
        for o in costume.values():
            o.hide_render = bare
        for o in blocks:
            o.hide_render = not bare

    undress(False)
    feet = {leg: r6._empty(f"Lyric.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    # holders of numbers, keyed like anything else, read back frame by frame once the body is keyed
    ctl = {name: r6._empty(f"Lyric.Ctl.{name}", None, Matrix.Identity(4), 0.1)
           for name in ("base", "stand", "sr", "srt", "sl", "slt", "float", "kick", "note", "pull", "free", "line")}
    for empty in (*feet.values(), *ctl.values()):
        empty.location = (0, 0, 0)
    return scene, rig, costume, undress, feet, ctl, motors


# --- the stand and the speakers, as places --------------------------------------------------------------------------

def world(p) -> Vector:
    """A Roblox point as a stage place (right, forward, up)."""
    return Vector((p[0], -p[2], p[1]))


def leant(lean, toward) -> Vector:
    """The pole's line leant `lean` degrees off upright toward the stage heading `toward` (0 ahead, 90 to her right)."""
    a, h = math.radians(lean), math.radians(toward)
    return Vector((math.sin(a) * math.sin(h), math.cos(a), -math.sin(a) * math.cos(h)))


def heading_of(u: Vector) -> tuple:
    """The (lean, toward) that leant() turns back into the line `u`."""
    return (round(math.degrees(math.acos(max(-1.0, min(1.0, u.y)))), 2),
            round(math.degrees(math.atan2(u.x, -u.z)) % 360.0, 2))


def fist(motors) -> Vector:
    """Where the pole passes through her right fist (the stand's joint), Roblox world, at the current frame."""
    return r6.to_roblox(motors[STAFF].matrix_world).to_translation()


def mouth(rig) -> Vector:
    return r6.to_roblox(rig.parts["Head"].matrix_world) @ Vector(MOUTH)


def footing(base: Vector, through: Vector) -> tuple:
    """The pole from the base's middle through `through`, the base's middle no lower than its tilt allows: a leant
    stand rests on its base's edge, and a base set down on the floor (or carried low) never dips through it. Returns
    (base, line)."""
    base, given = base.copy(), base.y
    for _ in range(4):
        u = (through - base).normalized()
        base.y = max(given, BASE * math.sqrt(max(0.0, 1.0 - u.y * u.y)))
    return base, (through - base).normalized()


def pole_turn(u: Vector, aim: float, spin: float, toward: Vector, base: Vector) -> Quaternion:
    """The stand's turn: upright to the line `u`, then about its own line so the mic leans toward `toward` as much as
    `aim` says (0: as the shortest turn leaves it), plus `spin` degrees."""
    q0 = UP.rotation_difference(u)
    lean = q0 @ Vector((0, 0, 1))
    want = toward - (base + q0 @ MIC)
    lean -= u * lean.dot(u)
    want -= u * want.dot(u)
    s = math.atan2(u.dot(lean.cross(want)), lean.dot(want)) if want.length > 1e-6 and lean.length > 1e-6 else 0.0
    return Quaternion(u, aim * s + math.radians(spin)) @ q0


def note_line(rig, base_at, pull, spin=0.0) -> tuple:
    """The stand for the note: planted at `base_at` (a floor place), leant so the mic's head comes to her mouth and
    `pull` past it (right, forward, up), turned to her mouth and `spin` degrees more. Returns (base, line), Roblox."""
    base, target = W(*base_at), mouth(rig) + W(*pull)
    u = (target - base).normalized()
    for _ in range(12):
        base.y = BASE * math.sqrt(max(0.0, 1.0 - u.y * u.y))
        q = pole_turn(u, 1.0, spin, mouth(rig), base)
        miss = target - (base + q @ MIC)
        u = (u + miss / MIC.length).normalized()
    return base, u


def note_base(rig, toward, pull) -> tuple:
    """Where the stand's base is planted for the note: out from her mouth toward the floor place `toward`, as far as
    puts the mic's head on her mouth and `pull` past it. A planted stand's mic is always the pole's length (|MIC|) from
    the base's middle, so only this distance lands it there. Returns a floor place (right, forward)."""
    target = mouth(rig) + W(*pull)
    h = W(*toward) - target
    h.y = 0.0
    h.normalize()
    rise_at = 0.0
    for _ in range(8):
        rise = target.y - rise_at
        b = target + h * math.sqrt(max(0.0, MIC.length_squared - rise * rise))
        b.y = rise_at
        u = (target - b).normalized()
        rise_at = BASE * math.sqrt(max(0.0, 1.0 - u.y * u.y))
    return (round(b.x, 3), round(-b.z, 3))


def on_line(rig, base: Vector, u: Vector, local) -> Vector:
    """Where on the pole's line the fist can close: the lower of the two places an arm's reach from the shoulder."""
    shoulder = r6._joint_frame(rig, "Right Arm").to_translation()
    rest = r6.cframe(r6rig.JOINTS["Right Arm"][2]).inverted() @ Vector(local)
    w = base - shoulder
    b, c = w.dot(u), w.dot(w) - rest.length_squared
    root = b * b - c
    return base + (-b - math.sqrt(root) if root > 0 else -b) * u


def speaker(name, place, turn, tilt) -> Matrix:
    """A speaker's joint frame in the world (Roblox) for its middle at a stage place, its cone turned `turn` degrees
    toward her left and tipped `tilt` down. The mesh carries its rest turn inward, which this takes back out."""
    return (Matrix.Translation(W(*place)) @ Matrix.Rotation(math.radians(turn), 4, "Y")
            @ Matrix.Rotation(math.radians(-tilt), 4, "X") @ Matrix.Rotation(math.radians(-INWARD[name]), 4, "Y"))


def facing(turn, tilt) -> Vector:
    return (Matrix.Rotation(math.radians(turn), 3, "Y") @ Matrix.Rotation(math.radians(-tilt), 3, "X")) @ Vector((0, 0, -1))


# --- keying ---------------------------------------------------------------------------------------------------------

HUB = {
    "T": (-1, 9, 0), "feet": {"Right Leg": (0.62, 0.12), "Left Leg": (-0.52, -0.1)}, "RL": (0, 0, 0), "LL": (0, 0, 0),
    "crouch": 0.03, "look": EYES, "H": (0, 0, 2), "RA": (4, 0, 7), "LA": (6, 0, -7),
}
SPEAKERS = {"R": HOME[SR], "RT": (INWARD[SR], 0.0), "L": HOME[SL], "LT": (INWARD[SL], 0.0), "F": 1.0, "Z": 0.0}


class Take(rc.Take):
    """One clip being keyed from `start`, as rook_clips.Take, with the stand's track and the speakers'."""

    def __init__(self, rig, feet, ctl, motors, name, start):
        super().__init__(rig, feet, name, start)
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in HUB.items()}
        self.ctl, self.motors, self.planted, self.line = ctl, motors, None, None
        self.props = {"B": (*B0, 0.0), "A": 0.0, "S": 0.0, **SPEAKERS, "KR": 0.0, "KL": 0.0, "N": 0.0, "P": NOTE_PULL,
                      "out": 0.0, "own": (0.0, 0.0)}
        self.stand(0)
        self.speak(0)
        self.note(0)
        self.free(0)
        self._hold(0, None, {"kick": (0, 0, 0)})

    def _hold(self, f, ease, values):
        frame = self.start + f
        for name, value in values.items():
            empty = self.ctl[name]
            empty.location = value
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *rc.EASE[ease])
        self.end = max(self.end, f)
        return self

    def stand(self, f, ease=None, at=None, held=None, aim=None, spin=None):
        """Keys the stand at clip frame `f`. `at`: its base planted at a floor place (right, forward), or a stage place
        (right, forward, up) off the floor. `held`: (lean, toward, grip), the pole leant `lean` degrees toward stage
        heading `toward` with her fist `grip` studs up it, turned into a base place from where her fist is at `f`
        (key the body at `f` first). `aim`: how much the mic turns to her mouth (0 to 1); `spin`: degrees more about the
        pole. What isn't named holds."""
        p = self.props
        if held is not None:
            bpy.context.scene.frame_set(self.start + f)
            lean, toward, grip = held
            b = fist(self.motors) - grip * leant(lean, toward)
            p["B"] = (*world(b)[:2], max(world(b)[2], 1e-3))
        elif at is not None:
            p["B"] = (at[0], at[1], at[2] if len(at) > 2 else 0.0)
        p["A"] = p["A"] if aim is None else aim
        p["S"] = p["S"] if spin is None else spin
        return self._hold(f, ease, {"base": p["B"], "stand": (p["A"], p["S"], 0.0)})

    def speak(self, f, ease=None, R=None, RT=None, L=None, LT=None, F=None, Z=None):
        """Keys the speakers at clip frame `f`: R / L each one's middle as a stage place, RT / LT (turn toward her
        left, tilt down) in degrees, F how much of their float they keep (1 at rest), Z how hard the cones shake
        (through the note). What isn't named holds."""
        p = self.props
        p.update({k: v for k, v in (("R", R), ("RT", RT), ("L", L), ("LT", LT), ("F", F), ("Z", Z)) if v is not None})
        return self._hold(f, ease, {"sr": p["R"], "srt": (*p["RT"], 0.0), "sl": p["L"], "slt": (*p["LT"], 0.0),
                                    "float": (p["F"], p["Z"], 0.0)})

    def note(self, f, ease=None, N=None, pull=None):
        """Keys how much the note has hold of her right arm at clip frame `f` (N, 0 to 1): held, the arm is solved on
        every frame so her fist is on the line from the stand's base to her mouth and `pull` past it (right, forward,
        up), and the mic's head stays there however her body moves. What isn't named holds."""
        p = self.props
        p["N"] = p["N"] if N is None else N
        p["P"] = p["P"] if pull is None else pull
        return self._hold(f, ease, {"note": (p["N"], 0.0, 0.0), "pull": p["P"]})

    def free(self, f, ease=None, F=None, line=None):
        """Keys how far the stand is out of her hand at clip frame `f` (F, 0 to 1): free, it stands on its own line
        `line` = (lean, toward), as leant() reads them, from its base, however her fist moves; held, its line runs
        through her fist. What isn't named holds."""
        p = self.props
        p["out"] = p["out"] if F is None else F
        p["own"] = p["own"] if line is None else line
        return self._hold(f, ease, {"free": (p["out"], 0.0, 0.0), "line": (*p["own"], 0.0)})

    def kick(self, f, which="RL", size=0.18, back=10):
        """A shot's kick: each speaker named in `which` ("R", "L" or both) jumps `size` studs back along its cone at
        `f` and is home `back` frames later."""
        r, l = (size if "R" in which else 0.0), (size if "L" in which else 0.0)
        self._hold(f - 1, "snap", {"kick": (0.0, 0.0, 0.0)})
        self._hold(f + 1, "out", {"kick": (r, l, 0.0)})
        return self._hold(f + back, None, {"kick": (0.0, 0.0, 0.0)})

    def key(self, f, label=None, ease=None, **changes):
        """Keys the body at clip frame `f`. `ease` shapes the move that starts here. `label` puts it on the pose sheet.
        Changes: T (pitch, turn, roll, right, _, forward), feet {leg: (right, forward)}, crouch, look (a stage place)
        or H (angles), RA / LA (angles, or ("reach", place, hint) for the hand). RA as ("note", base, pull, hint) puts
        her fist on the stand's line for the note: the base planted at `base`, the mic's head at her mouth and `pull`
        past it, and keys the stand to match."""
        s, rig, frame = self.state, self.rig, self.start + f
        if "feet" in changes:
            changes["feet"] = {**s["feet"], **changes["feet"]}
        if "H" in changes and "look" not in changes:
            s["look"] = None
        s.update(changes)
        interp = rc.EASE[ease]
        bpy.context.scene.frame_set(frame)
        torso = list(s["T"]) + [0.0] * (6 - len(s["T"]))
        torso[5] = -torso[5]  # forward, as a Roblox move
        planted = {leg: W(*at) for leg, at in s["feet"].items() if at is not None}
        loose = {leg: (*s["RL" if leg == "Right Leg" else "LL"][:3], 0.0, 0.0, 0.0) for leg in r6.LEGS if leg not in planted}
        torso, legs, sink = rc.stand_legs(rig, torso, planted, s["crouch"], loose)
        if sink > rc.SINK:
            self.warned.append(f"{self.name} {f}: a leg sinks {sink:.2f} into the hip")
        r6._key_parts(rig, frame, {"Torso": torso, **legs}, *interp)
        r6._refresh()
        for leg, empty in self.feet.items():  # where each foot stands and how low she sits, for the pass between keys
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
            rest["Head"] = (max(-rc.NOD, min(rc.NOD, pitch)), turn, tilt)
        else:
            rest["Head"] = s["H"]
        r6._key_parts(rig, frame, {"Head": rest["Head"]}, *interp)
        r6._refresh()
        note = None
        for arm in ("RA", "LA"):
            a = s[arm]
            if a[0] == "reach":
                rest[rc.SHORT[arm]] = r6.reach(rig, rc.SHORT[arm], rc.HAND, W(*a[1]), a[2])
            elif a[0] == "note":
                if self.planted is None:  # the first key of the note plants the base; the rest of it keeps it there
                    self.planted = note_base(rig, a[1], a[2])
                base, u = note_line(rig, self.planted, a[2], self.props["S"])
                self.line = heading_of(u)
                local = r6.to_roblox(rig.parts["Right Arm"].matrix_world).inverted() @ fist(self.motors)
                rest["Right Arm"] = r6.reach(rig, "Right Arm", local, on_line(rig, base, u, local), a[3])
                note = self.planted
            else:
                rest[rc.SHORT[arm]] = a
                if arm == "RA":
                    self.planted = None
        r6._key_parts(rig, frame, rest, *interp)
        if note is not None:
            self.stand(f, ease, at=note, aim=1.0)
        self.end = max(self.end, f)
        if label:
            self.beats.append((f, label))
        return self


def props(rig, ctl, motors, takes) -> dict:
    """The last pass, once the body is keyed on every frame: the stand solved through her fist and the speakers to
    their places, each keyed on every frame. Returns each clip's numbers."""
    scene, facts, skin = bpy.context.scene, {}, Skin()
    for take in takes:
        n = take.end + 1
        near = {part: (9.0, 0) for part in SKIN}
        spk = {part: (9.0, 0) for part in ("Head", "Torso", "Right Arm", "Left Arm", "Pole")}
        hold, low, mics, rings = [9.0, -9.0], (9.0, 0), [], []
        arm, noted = [], []  # the right arm as keyed, and the note's hold on it, read before anything is re-keyed
        for f in range(n):
            scene.frame_set(take.start + f)
            arm.append(r6.pose_of(rig, "Right Arm")[:3])
            noted.append(ctl["note"].location.x)
        local = r6.to_roblox(rig.parts["Right Arm"].matrix_world).inverted() @ fist(motors)
        for f in range(n):
            frame = take.start + f
            scene.frame_set(frame)
            v = {name: Vector(empty.location) for name, empty in ctl.items()}
            if max(noted) > 1e-4:  # the note's clip: the arm keyed on every frame, solved where the note holds it
                pose, w = arm[f], noted[f]
                if w > 1e-4:
                    if v["free"].x > 1e-4:  # catching it: her fist goes to the stand where it stands
                        u = leant(v["line"].x, v["line"].y)
                        base = W(*v["base"])
                        base.y = max(base.y, BASE * math.sqrt(max(0.0, 1.0 - u.y * u.y)))
                    else:
                        base, u = note_line(rig, (v["base"].x, v["base"].y), tuple(v["pull"]), v["stand"].y)
                    solved = r6.reach(rig, "Right Arm", local, on_line(rig, base, u, local), pose)
                    pose = (pose[0] + w * (solved[0] - pose[0]), pose[1], pose[2] + w * (solved[2] - pose[2]))
                r6._key_parts(rig, frame, {"Right Arm": pose}, *rc.EASE["lin"])
                r6._refresh()
            # the stand
            through = fist(motors)
            b, u = footing(W(*v["base"]), through)
            out_of_hand = v["free"].x
            if out_of_hand > 1e-4:  # on its own line, as far as it's out of her hand
                u = (u * (1.0 - out_of_hand) + leant(v["line"].x, v["line"].y) * out_of_hand).normalized()
                b.y = max(W(*v["base"]).y, BASE * math.sqrt(max(0.0, 1.0 - u.y * u.y)))
            grip = (through - b).length
            held_now = out_of_hand < 0.5
            if held_now:
                hold = [min(hold[0], grip), max(hold[1], grip)]
            q = pole_turn(u, v["stand"].x, v["stand"].y, mouth(rig), b)
            joint = Matrix.Translation(b + q @ Vector((0, GRIP, 0))) @ q.to_matrix().to_4x4()
            keyed = {STAFF: r6.to_blender(r6.to_roblox(motors[STAFF].matrix_world).inverted() @ joint)}
            mic = b + q @ MIC
            mics.append(mic)
            ends = [b + q @ Vector((0, s, 0)) for s in np.linspace(0.0, TOP, 32)]
            edge = b.y - BASE * math.sqrt(max(0.0, 1.0 - u.y * u.y))  # the base's lowest rim
            low = min(low, (min(edge, min(p.y for p in ends)), f))
            bodies = {part: r6.to_roblox(rig.parts[part].matrix_world) for part in BOXES}
            runs = ([p for p in ends if (p - b).length < grip - 0.4],  # the pole below her fist, and above it
                    [p for p in ends if (p - b).length > grip + 0.4]) if held_now else (ends,)
            for part in SKIN:
                if part == "Right Arm" and (held_now or noted[f] > 0.5):  # it holds the pole, or reaches to catch it
                    continue
                gaps = [skin.gap(run, part, POLE_R) for run in runs if len(run) > 1]
                gaps.append(skin.gap([mic], part, MIC_R))
                if part == "Head":  # and never inside her head itself (a point well inside is far from the surface)
                    gaps.append(clear(mic, "Face", bodies["Head"]) - MIC_R)
                near[part] = min(near[part], (min(gaps), f))
            # the speakers
            float_, shake = v["float"].x, v["float"].y
            pair = []
            for name, at, turned, kick, phase in ((SR, v["sr"], v["srt"], v["kick"].x, 0.0),
                                                  (SL, v["sl"], v["slt"], v["kick"].y, math.pi)):
                turn, tilt = turned.x, turned.y
                rise = math.sin(2 * math.pi * f / BOB + phase) * RISE * float_
                sway = math.sin(2 * math.pi * f / BOB + phase + 1.3) * SWAY * float_
                buzz = math.sin(2 * math.pi * f / BUZZ) * 0.025 * shake
                cone = facing(turn, tilt)
                place = world(W(*at) + Vector((0, rise, 0)) - cone * (kick + buzz))
                m = speaker(name, place, turn + sway, tilt)
                keyed[name] = r6.to_blender(r6.to_roblox(motors[name].matrix_world).inverted() @ m)
                centre = m.to_translation()
                pair.append(centre)
                for part in ("Head", "Torso", "Right Arm", "Left Arm"):
                    spk[part] = min(spk[part], (clear(centre, part, bodies[part]) - CAB, f))
                spk["Pole"] = min(spk["Pole"], (min((centre - p).length for p in ends) - CAB - POLE_R, f))
            rings.append(pair)
            r6.key_matrices(rig, frame, keyed)
        mouths = []
        for f, _ in take.beats:  # where the mic's head is from her mouth, in her head's frame: right, up, ahead
            scene.frame_set(take.start + f)
            at = r6.to_roblox(rig.parts["Head"].matrix_world).inverted() @ mics[f] - Vector(MOUTH)
            mouths.append((f, (mics[f] - mouth(rig)).length, (at.x, at.y, -at.z)))
        facts[take.name] = {"near": near, "speakers": spk, "hold": hold, "low": low, "mouth": mouths}
    return facts


def clear(point, part, frame) -> float:
    """How far a point is outside a body's box, in studs; negative is inside."""
    centre, half = FACE if part == "Face" else BOXES[part]
    d = np.abs(np.array((frame.inverted() @ point)[:]) - np.array(centre)) - np.array(half)
    out = float(np.linalg.norm(np.maximum(d, 0)))
    return out if out > 0 else float(d.max())


def audit(rig, take) -> dict:
    """What the content check asks of every clip, as numbers: each leg's widest swing (her left against the jacket's
    tail), and the longest an arm stays nearly still between 20 and 70 degrees over level (condition 9)."""
    scene = bpy.context.scene
    swing = {leg: (0.0, 0) for leg in r6.LEGS}
    held, run, last = {"Right Arm": (0, 0), "Left Arm": (0, 0)}, {"Right Arm": 0, "Left Arm": 0}, {}
    top = {"Right Arm": (-90.0, 0), "Left Arm": (-90.0, 0)}
    for f in range(take.end + 1):
        scene.frame_set(take.start + f)
        for leg in r6.LEGS:
            p = r6.pose_of(rig, leg)
            swing[leg] = max(swing[leg], (max(abs(p[0]), abs(p[2])), f))
        for arm in held:
            along = (r6.to_roblox(rig.parts[arm].matrix_world).to_3x3() @ Vector((0, -1, 0))).normalized()
            still = arm in last and math.degrees(along.angle(last[arm], 0.0)) * FPS < STILL
            last[arm] = along
            up = math.degrees(math.asin(max(-1, min(1, along.y))))
            top[arm] = max(top[arm], (up, f))
            run[arm] = run[arm] + 1 if still and 20.0 < up < 70.0 else 0
            held[arm] = max(held[arm], (run[arm], f))
    return {"swing": swing, "held": held, "top": top}


# --- the clips ------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses. R6 has no elbow and her right fist never leaves the pole, so
# the free left arm does the acting (the sheet's point 4). That arm never holds a straight raise toward the crowd, and
# there's no wink, kiss, heart, beckon or hip sway (condition 10): she keeps time with her head and her knees, never
# her hips. Her left leg swings no more than TAIL under the jacket's tail. The speakers are kit: they float, turn to
# where she sends them and kick on her shots, and that's all they do.

def idle(t):
    """Between songs, waiting for the count: weight on her back foot, the stand leant in to her fist, keeping time with
    her chin and a little give in the knees. Once a loop she glances back over her right shoulder at her monitor."""
    t.loop = True
    for beat in (0, 60, 120):
        t.key(beat, "the stance" if beat == 0 else None, ease="snap", look=EYES, crouch=0.03)
        t.key(beat + 5, "on the beat" if beat == 0 else None, ease="sine", look=NOD, crouch=0.07, T=(1, 9, 0))
        t.key(beat + 22, ease="sine", look=EYES, crouch=0.03, T=(-1, 9, 0))
    # the glance: the head round over the right shoulder, the body opening a little with it
    t.key(166, ease="cubic", T=(-1, 3, 0), H=(-6, -62, -4), crouch=0.04, LA=(2, 0, -9))
    t.key(176, "her monitor", ease="sine", T=(-2, 1, 0), H=(-8, -70, -6), crouch=0.04)
    t.key(196, ease="cubic", T=(-1, 7, 0), look=EYES, H=(0, 0, 2), LA=(6, 0, -7))
    t.key(210, ease="snap", T=(-1, 9, 0), crouch=0.03)
    t.key(215, ease="sine", look=NOD, crouch=0.07, T=(1, 9, 0))
    t.key(232, ease="sine", look=EYES, crouch=0.03, T=(-1, 9, 0))
    t.key(240, **{k: HUB[k] for k in ("T", "crouch", "RA", "LA")}, look=EYES, H=HUB["H"])
    for beat in (0, 60, 120, 210):
        t.kick(beat + 5, "RL", 0.04, 12)
    t.speak(240)


def combo(t):
    """Three on the beat: she stamps the stand's base and the right speaker fires; she cuts her free hand at you and
    the left one fires; then she hoists the whole stand and drives it down with her weight, and both fire together."""
    t.key(0)
    t.stand(0)
    t.key(7, "lifts it", ease="in", T=(-4, 9, 0), crouch=0.0, RA=(26, 0, 6), look=(0.0, 10.0, 5.6))
    t.stand(7, "in", held=(4, 200, 2.3))
    t.key(15, "1: the stamp", ease="out", T=(6, 8, 0), crouch=0.11, RA=(10, 0, 6), look=NOD)
    t.stand(15, at=(1.7, 1.35))
    t.mark(15, "Shot1")
    t.key(20, ease="cubic", T=(2, 10, 0), crouch=0.06, look=EYES)
    t.key(25, "cocks the hand", ease="in", T=(0, 16, 0), LA=(-24, 0, -42), RA=(8, 0, 6))
    t.key(30, "2: the cue", ease="out", T=(5, 2, 0, 0, 0, 0.05), LA=(64, 0, -18), crouch=0.08, look=NOD)
    t.mark(30, "Shot2")
    t.key(37, ease="sine", T=(3, 4, 0), LA=(52, 0, -16), look=EYES)
    t.key(44, ease="in", T=(-2, 8, 0), crouch=0.02, LA=(20, 0, -16), RA=(30, 0, 8))
    t.stand(44, ease="in")
    t.key(54, "hoists it", ease="in", T=(-9, 10, 0, 0, 0, -0.05), crouch=0.0, RA=(100, 0, 14), LA=(-10, 0, -30),
          look=(0.0, 10.0, 6.2))
    t.stand(54, "in", held=(12, 70, 2.7))  # clear of the ground, its base about a stud up, its top out to her right:
    # driven down, the top chops across her right side, where the game's camera sees it travel
    t.key(60, "3: drives it down", ease="out", T=(13, 8, 0, 0, 0, 0.18), crouch=0.22, RA=(18, 0, 8), LA=(30, 0, -22),
          look=NOD, feet={"Right Leg": (0.66, 0.3)})
    t.stand(60, at=(1.8, 1.75))
    t.mark(60, "Shot3")
    t.key(66, ease="sine", T=(9, 8, 0, 0, 0, 0.12), crouch=0.15, look=EYES)
    t.key(82, "settles", ease="sine", T=(2, 9, 0, 0, 0, 0.04), crouch=0.06, RA=(8, 0, 7), LA=(8, 0, -9))
    t.key(105, **{k: HUB[k] for k in ("T", "crouch", "RA", "LA", "feet")}, look=EYES)
    t.stand(86, "sine")
    t.stand(95, "sine", held=(2, 200, 2.25))  # lifted a hair and set back where it lives, never skidded
    t.stand(105, at=B0)
    # the speakers: the right one turns on the target for the first, the left for the second, both for the third
    t.speak(8, "in")
    t.speak(14, "out", R=(2.6, 0.2, 5.0), RT=(2, 6))
    t.kick(15, "R", 0.2)
    t.speak(24, "in")
    t.speak(29, "out", L=(-2.6, 0.2, 4.9), LT=(-2, 6))
    t.kick(30, "L", 0.2)
    t.speak(48, "in", R=(2.5, -0.4, 5.2), L=(-2.5, -0.4, 5.1), RT=(4, 0), LT=(-4, 0), F=0.3)
    t.speak(59, "out", R=(2.7, 0.6, 5.0), L=(-2.7, 0.6, 4.9), RT=(3, 8), LT=(-3, 8), F=0.0)
    t.kick(60, "RL", 0.3, 14)
    t.speak(78, "sine")
    t.speak(105, R=HOME[SR], L=HOME[SL], RT=(INWARD[SR], 0.0), LT=(INWARD[SL], 0.0), F=1.0)


NOTE_BASE = (3.3, 2.6)  # which way the stand's base lands for the note: ahead and to her right (note_base sets how far)
NOTE_PULL = (0.45, 0.55, 0.05)  # where the mic's head comes to from her mouth: just off her face, a little to the
# side the game's camera is on, so her face and the mic both read; the pole's top clears her jaw from here
NOTE_FEET = {"Right Leg": (0.75, 0.95), "Left Leg": (-0.55, -0.6)}


def held_note(t):
    """She draws one breath and throws the stand out ahead of her so its base lands far out to her right; then she
    lunges into it, drags the mic down to her mouth and leans her whole weight into one note, the free arm flung back,
    while the speakers she brought fly out to the cone's two edges and throw it down the street. She holds it two beats,
    pushing, and lets it go; then she walks the stand back in."""
    t.key(0)
    t.stand(0)
    t.mark(4, "Breath")
    t.key(10, "a breath", ease="cubic", T=(-7, 12, 0, 0, 0, -0.05), crouch=0.0, look=(0.5, 10.0, 6.6),
          RA=(34, 0, 26), LA=(14, 0, -30))
    t.stand(10, "cubic", held=(12, 240, 2.2))
    t.key(14, ease="out", T=(-5, 16, 0), RA=(62, 0, 34), LA=(8, 0, -34))
    t.key(20, "throws it out", ease="in", T=(-2, 18, 0), RA=(96, 0, 46), LA=(4, 0, -38))
    t.key(30, "the note", ease="out", T=(17, 14, 0, 0, 0, 0.4), feet=NOTE_FEET, crouch=0.2, look=(1.5, 10.0, 5.6),
          H=(0, 0, 4), RA=("note", NOTE_BASE, NOTE_PULL, (78, 0, 18)), LA=(-48, 0, -36))
    # the toss: she lets the stand go on her throw; it flies out and lands planted, leant in to where her mouth will
    # be, and she catches it as she lunges in
    t.stand(14, "out", held=(14, 240, 2.2))
    t.free(14, "out", F=0.0, line=(14.0, 240.0))
    t.free(16, F=1.0, line=(6.0, 240.0))  # it flies near upright, clear of her, and tips in to her once it lands
    t.free(20, "in")
    t.stand(18, "in", at=(*[(a + b) / 2 for a, b in zip(t.props["B"][:2], t.planted)], 1.1))
    t.stand(23, "in", at=t.planted, aim=1.0)
    t.free(24, line=t.line)
    t.free(27, "sine")
    t.free(30, F=0.0)
    t.mark(30, "Note")
    # the crests between, on the half-beats the speakers kick on: each a touch, a fifth of the signature (AR4, section 9)
    t.mark(45, "Crest2")
    t.mark(60, "Crest3")
    t.mark(75, "Crest4")
    t.key(44, ease="sine", T=(18, 14, 0, 0, 0, 0.44), crouch=0.22, LA=(-54, 0, -38))
    t.key(88, "pushing", ease="out", T=(19, 14, 0, 0, 0, 0.46), crouch=0.24, LA=(-58, 0, -40),
          RA=("note", NOTE_BASE, NOTE_PULL, (78, 0, 18)))
    t.stand(90, "in")  # planted until she hauls it
    t.mark(90, "Release")
    t.key(96, "lets it go", ease="sine", T=(4, 12, 0, 0, 0, 0.2), crouch=0.08, look=EYES, H=(0, 0, 2),
          RA=(100, 0, 52), LA=(10, 0, -18))
    t.stand(96, "sine", aim=0.0)  # the mic lifted off her mouth and away to her right, her hand high up the pole
    t.key(106, "hauls it in", ease="in", T=(-1, 10, 0, 0, 0, 0.1), RA=(70, 0, 40), crouch=0.04)
    t.stand(106, "in", held=(6, 60, 3.2))
    t.key(116, ease="in", T=(-2, 10, 0, 0, 0, 0.08), RA=(30, 0, 18), crouch=0.02,
          feet={"Right Leg": (0.66, 0.4), "Left Leg": (-0.52, -0.25)})
    t.stand(116, "in", held=(10, 30, 2.4))
    t.key(126, ease="sine", T=(0, 9, 0), RA=(8, 0, 8), crouch=0.04)
    t.stand(126, "sine", at=(1.68, 1.2))
    t.key(150, **{k: HUB[k] for k in ("T", "crouch", "RA", "LA", "feet")}, look=EYES)
    t.stand(150, at=B0)
    # the speakers: they draw back with her breath, then fly out to the wave's edges and shake through the hold
    t.speak(4, "in")
    t.speak(22, "in", R=(2.9, -1.0, 5.3), L=(-2.9, -1.1, 5.0), RT=(6, -4), LT=(-6, -4), F=0.2)
    t.speak(30, "out", R=(3.6, 4.2, 4.7), L=(-3.6, 4.2, 4.7), RT=(-24, 14), LT=(24, 14), F=0.0, Z=1.0)  # landed on the Note
    t.speak(88, "sine", R=(3.7, 4.4, 4.75), L=(-3.7, 4.4, 4.75), Z=1.0)
    t.speak(92, "sine", Z=0.0)
    t.speak(130, "sine", R=HOME[SR], L=HOME[SL], RT=(INWARD[SR], 0.0), LT=(INWARD[SL], 0.0), F=1.0)
    t.speak(150)
    # they kick on each crest, the half-beats from the Note to the Release (AR4, section 9): the kick snaps back on the
    # crest's own frame, and each is home before the next
    for crest, size, back in ((30, 0.35, 13), (45, 0.22, 13), (60, 0.22, 13), (75, 0.22, 13), (90, 0.3, 16)):
        t.kick(crest - 1, "RL", size, back)
    t.note(22, "sine", N=0.0)
    t.note(28, N=1.0, pull=NOTE_PULL)
    t.note(88, "sine")
    t.note(94, N=0.0)


def reveal(t):
    """The show hasn't started: head down, the speakers dark and low at her sides. They power up and rise to her
    shoulders; she counts it in with two taps of the stand's base, and on three her chin comes up to you, the stand
    upright beside her face, the free hand thrown out low at her side. Held for her name."""
    low = dict(T=(9, 9, 0), crouch=0.08, H=(24, 4, 0), RA=(4, 0, 6), LA=(4, 0, -4))
    t.key(0, "before the show", **low)
    t.stand(0, at=(1.6, 0.95))
    t.mark(18, "Power")
    t.key(24, ease="in", **{**low, "T": (8, 9, 0), "RA": (20, 0, 6), "crouch": 0.06})
    t.stand(24, "in", held=(2, 180, 2.35))
    t.key(30, "one", ease="out", **{**low, "T": (10, 9, 0), "H": (28, 4, 0), "RA": (6, 0, 6), "crouch": 0.1})
    t.stand(30, at=(1.6, 0.95))
    t.key(54, ease="in", **{**low, "T": (7, 9, 0), "RA": (20, 0, 6), "crouch": 0.05, "H": (20, 4, 0)})
    t.stand(54, "in", held=(2, 180, 2.35))
    t.key(60, "two", ease="out", **{**low, "T": (10, 9, 0), "H": (28, 4, 0), "RA": (6, 0, 6), "crouch": 0.1})
    t.stand(60, at=(1.6, 0.95))
    t.key(82, ease="in", T=(12, 12, 0), crouch=0.12, H=(26, 4, 0), LA=(18, 0, -8))
    t.key(90, "and three", ease="out", T=(-5, 16, 0), crouch=0.04, look=(0.0, 10.0, 5.6), H=(0, 0, 3),
          RA=(14, 0, 28), LA=(10, 0, -52), feet={"Right Leg": (0.72, 0.2), "Left Leg": (-0.5, -0.15)})
    t.stand(90, held=(5, 80, 2.2))  # upright beside her face, under her fist: the front camera sees both, apart
    t.mark(90, "Strike")
    t.key(100, ease="sine", T=(-3, 15, 0), LA=(8, 0, -48), crouch=0.05)
    t.key(150, "held for the name", T=(-4, 15, 0), LA=(9, 0, -50), crouch=0.04)
    t.speak(0, R=(2.95, -0.35, 2.3), L=(-2.95, -0.35, 2.2), RT=(INWARD[SR], 32), LT=(INWARD[SL], 32), F=0.0)
    t.speak(16, "back")
    t.speak(34, "sine", R=HOME[SR], L=HOME[SL], RT=(INWARD[SR], 0.0), LT=(INWARD[SL], 0.0), F=0.6)
    t.speak(84, "in")
    t.speak(91, "out", R=(2.85, -0.3, 5.45), L=(-2.8, -0.45, 5.1), F=1.0)
    t.speak(150)
    t.kick(30, "RL", 0.06, 10)
    t.kick(60, "RL", 0.06, 10)
    t.kick(90, "RL", 0.22, 14)


POST = (0.3, 3.0, 2.9)  # the bay's post, as Pip's Work has it
DIAL = (0.4, 3.2, 5.9)


def work(t):
    """A shift at the bay, played like a soundcheck: the speakers turned on the post and pumping on every beat, her
    chin keeping time, a stamp of the stand on two, and on four she looks up to read the dial."""
    t.loop = True
    top = dict(T=(1, 4, 0), feet={"Right Leg": (0.6, 0.15), "Left Leg": (-0.5, -0.12)}, crouch=0.03, look=POST,
               H=(0, 0, 0), RA=(6, 0, 7), LA=(6, 0, -8))
    t.key(0, "playing to the post", ease="snap", **top)
    t.stand(0, at=(1.55, 1.25))
    t.key(5, ease="sine", T=(3, 4, 0), crouch=0.07)
    t.key(22, "lifts it", ease="in", T=(-2, 4, 0), crouch=0.0, RA=(24, 0, 7))
    t.stand(22, "in", held=(3, 200, 2.35))
    t.key(30, "the stamp", ease="out", T=(5, 4, 0), crouch=0.1, RA=(8, 0, 7))
    t.stand(30, at=(1.55, 1.25))
    t.mark(30, "Pump")
    t.key(48, ease="sine", T=(1, 4, 0), crouch=0.03)
    t.key(60, ease="snap")
    t.key(65, ease="sine", T=(3, 4, 0), crouch=0.07)
    t.key(84, ease="cubic", T=(-1, 5, 0), crouch=0.03)
    t.key(94, "reads the dial", ease="sine", T=(-3, 5, 0), look=DIAL, H=(0, 0, 0), crouch=0.03, LA=(10, 0, -10))
    t.key(108, ease="cubic", look=POST, LA=(6, 0, -8))
    t.key(120, **top)
    t.stand(120, at=(1.55, 1.25))
    aimed = dict(R=(2.7, 1.0, 4.6), RT=(34, 12), L=(-1.9, 1.4, 4.6), LT=(-26, 10), F=0.5)
    t.speak(0, **aimed)
    t.speak(120)
    for beat in (0, 30, 60, 90):
        t.kick(beat + 1, "RL", 0.12 if beat == 30 else 0.07, 12)


CLIPS = {"Idle": idle, "Combo": combo, "HeldNote": held_note, "Reveal": reveal, "Work": work}
# The rows a clip's pose sheet shows, and the first is its pack's view. The note is as wide as its cone, so it's read
# with a wider lens, and from the target's side too; the Reveal is met from the front.
VIEWS = {"HeldNote": ("wide", "met", "wide side"), "Reveal": ("front", "side", "game"), "Work": ("front", "side", "game")}


# --- outputs --------------------------------------------------------------------------------------------------------

def cameras(scene, rig):
    cams = {name: r6.body_camera(scene, rig, 0, az, el, distance=14.0, height=3.4, name=name)
            for name, (az, el) in (("game", GAME), ("front", FRONT), ("side", SIDE))}
    for name, (az, el) in (("wide", GAME), ("wide side", SIDE), ("met", MET)):
        cams[name] = r6.body_camera(scene, rig, 0, az, el, distance=17.0, height=3.4, fov=46.0, name=name)
    return cams


def pose_sheet(scene, cams, take, out):
    views = VIEWS.get(take.name, ("game", "side", "front"))
    shots = [(cams[view], take.start + f, f"{take.name} {f}: {label}" if view == views[0] else f"{f} {view}")
             for view in views for f, label in take.beats]
    scene.render.resolution_x, scene.render.resolution_y = 330, 380
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(take.beats))
    print(f"wrote {path}")


def arc_sheet(scene, rig, cams, take, out):
    """One dot a frame where the mic's head (pink) and the speakers' cones (pale) are through the clip, over the body
    at its middle beat: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)

    def at(rig, part):
        return r6.to_roblox(rig.parts[part].matrix_world)

    recipe = json.loads((MODEL / "Lyric.recipe.json").read_text())
    pivots = {p["name"]: Vector(p["pivot"]) for p in recipe["pieces"] if "motor" in p}
    points = {p["on"]: tuple(Vector(p["at"]) - pivots[p["on"]]) for p in recipe["points"] if p["on"] in pivots}
    dots = r6.path_dots(rig, frames, [(STAFF, points[STAFF])], colour=(1.0, 0.44, 0.85), radius=0.06, name="Mic", at=at)
    for name in (SR, SL):
        dots += r6.path_dots(rig, frames, [(name, points[name])], colour=(0.92, 0.9, 0.82), radius=0.045,
                             name=f"Cone{name}", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    views = ("wide", "met") if take.name == "HeldNote" else ("game", "side")
    scene.render.resolution_x, scene.render.resolution_y = 640, 560
    path = r6.render_shots(scene, [(cams[view], beat, f"{take.name}: one dot a frame, {view}") for view in views],
                           out / f"arcs_{take.name}.png", columns=2)
    for dot in dots:
        bpy.data.objects.remove(dot, do_unlink=True)
    print(f"wrote {path}")


def bare_sheet(scene, rig, take, undress, out, tiles=20):
    """What the content check asks of every clip: stepped through on the bare rig, from the side and the three-quarter."""
    step = max(1, math.ceil((take.end + 1) / tiles))
    frames = list(range(0, take.end + 1, step))
    undress(True)
    cams = [(view, r6.body_camera(scene, rig, take.start, az, el, distance=14.0, height=3.2, name=f"bare {view}"))
            for view, (az, el) in (("side", SIDE), ("quarter", QUARTER))]
    scene.render.resolution_x, scene.render.resolution_y = 190, 230
    path = r6.render_shots(scene, [(cam, take.start + f, f"{f}") for _, cam in cams for f in frames],
                           out / f"bare_{take.name}.png", columns=len(frames))
    undress(False)
    print(f"wrote {path} (every {step} frames; the side, then the three-quarter)")


def heading_sheet(scene, rig, take, frames, out):
    """The note at 64 px from the player's camera's height on eight headings, over the dusk floor and over a bright
    one, shown four times its size: a row a frame."""
    floor, shading = bpy.data.materials["Floor"], scene.display.shading
    dusk = (tuple(floor.diffuse_color), tuple(shading.background_color))
    cams = [r6.body_camera(scene, rig, take.start, az, GAME[1], distance=17.0, height=3.4, fov=46.0, name=f"heading {az}")
            for az in range(0, 360, 45)]
    scene.render.resolution_x, scene.render.resolution_y = 64, 64
    rows = []
    for ground, sky in (dusk, ((0.86, 0.84, 0.8, 1.0), (0.78, 0.84, 0.92))):
        floor.diffuse_color, shading.background_color = ground, sky
        for f in frames:
            path = r6.render_shots(scene, [(cam, take.start + f, "") for cam in cams], out / f"headings_{take.name}_row.png", columns=len(cams))
            rows.append(np.repeat(np.repeat(rs.load(path), 4, axis=0), 4, axis=1))
            Path(path).unlink()
    floor.diffuse_color, shading.background_color = dusk
    sheet = np.concatenate(list(reversed(rows)), axis=0)
    sheet[..., 3] = 1.0
    rs.save(sheet, out / f"headings_{take.name}.png")
    print(f"wrote {out / f'headings_{take.name}.png'} (from the top: the bright ground, then dusk, each as frames "
          f"{list(reversed(frames))}; across, from her front round by 45 degrees)")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "export", "audit") else "poses"
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    scene, rig, costume, undress, feet, ctl, motors = build()
    takes = {}
    for i, name in enumerate(CLIPS):
        if name in wanted:
            takes[name] = take = Take(rig, feet, ctl, motors, name, 1000 * i)
            CLIPS[name](take)
            for line in take.warned:
                print("  " + line)
    rc.ground(rig, feet, list(takes.values()))
    numbers = props(rig, ctl, motors, list(takes.values()))
    cams = cameras(scene, rig)
    facts = {}
    for name, take in takes.items():
        n, checks = numbers[name], audit(rig, take)
        near = "; ".join(f"{part} {d:.2f} at {f}" for part, (d, f) in n["near"].items())
        spk = "; ".join(f"{part} {d:.2f} at {f}" for part, (d, f) in n["speakers"].items())
        mouths = ", ".join(f"{f}: {d:.2f}" + (" ({:+.2f} {:+.2f} {:+.2f})".format(*at) if d < 1.2 else "")
                           for f, d, at in n["mouth"])
        notes = (f"{name}: {take.end + 1} frames, {take.end / FPS:.2f} s\n"
                 f"  the stand's nearest to her, in studs (the pole and the mic's head): {near}\n"
                 f"  its base at its lowest over the floor: {n['low'][0]:.2f} at {n['low'][1]}; her fist on the pole "
                 f"from {n['hold'][0]:.2f} to {n['hold'][1]:.2f} studs up it (it holds from {HOLD[0]} to {HOLD[1]})\n"
                 f"  the mic's head from her mouth at each named pose: {mouths}\n"
                 f"  the speakers' nearest, past their cabinets: {spk}\n"
                 f"  a leg's widest swing: right {checks['swing']['Right Leg'][0]:.0f} at {checks['swing']['Right Leg'][1]}, "
                 f"left {checks['swing']['Left Leg'][0]:.0f} at {checks['swing']['Left Leg'][1]} (the tail allows {TAIL:.0f})\n"
                 f"  the longest an arm is nearly still at 20 to 70 degrees up, of {HELD} frames: right {checks['held']['Right Arm'][0]} "
                 f"(to {checks['held']['Right Arm'][1]}), left {checks['held']['Left Arm'][0]} (to {checks['held']['Left Arm'][1]}); "
                 f"each arm at its highest: right {checks['top']['Right Arm'][0]:.0f} at {checks['top']['Right Arm'][1]}, "
                 f"left {checks['top']['Left Arm'][0]:.0f} at {checks['top']['Left Arm'][1]}\n")
        print(notes, end="")
        facts[name] = {"File": f"Lyric_{name}.json", "Frames": take.end + 1, "Seconds": round(take.end / FPS, 3),
                       "Loop": take.loop, "Markers": [[round(t * FPS), label] for t, label in take.markers]}
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        heard = io.StringIO()  # the export audits itself aloud: the pack's notes keep what it said
        with contextlib.redirect_stdout(heard):
            # the Name is the game's: Author.SaveBaked reads Anim_Lyric<Clip> and checks the clip is named the same
            r6.export(rig, out / f"Lyric_{name}.json", "Lyric", f"Lyric{name}", take.start, take.start + take.end,
                      markers=take.markers, source="tools/blender/lyric_clips.py", extra={"Loop": take.loop})
        print(heard.getvalue(), end="")
        if mode == "audit":
            continue
        arc_sheet(scene, rig, cams, take, out)
        bare_sheet(scene, rig, take, undress, out)
        if name == "HeldNote":
            heading_sheet(scene, rig, take, (10, 20, 30, 60), out)
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame: cams[VIEWS.get(name, ("game",))[0]], bare=SIDE[0], strip=strip, undress=undress,
                       notes=notes + heard.getvalue())
    if mode != "poses" and len(takes) == len(CLIPS):
        (out / "Lyric.clips.json").write_text(json.dumps({"Fps": FPS, "Clips": facts}, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out / 'Lyric.clips.json'}")


if __name__ == "__main__":
    main()
