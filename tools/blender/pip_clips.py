"""Pip's clips on the R6 rig, his baked model riding it (AR4, delivery 3).

blender.exe -b --factory-startup --python tools/blender/pip_clips.py -- <out_dir> [poses|export|audit] [clip ...]

- poses (the default): one sheet a clip, its key poses from the player's assumed camera, from his side and from his
  front, with the checks' numbers printed.
- export: Pip_<Clip>.json for the builder (r6anim.export, with its audit), one review pack a clip, the lantern's and
  the cuff's arcs (one dot a frame), the bare rig stepped from the side and the three-quarter, and Lantern Burst's send
  at 64 px on eight headings.
- audit: the export without the pictures.

Keyed on AR63's C, the high collar (pip_redo_takes.py, finish_c), which has no hat: the first Pip's hat beats went to
his head and his collar (2026-11-28); his first clips are in git and in the game's published ids.

Needs the model's output (pip_model.blend, Pip.recipe.json and the maps) in MODEL. The keying is rook_clips.py's:
every clip at 60 fps on its own stretch of one timeline, starting from HUB; feet given as places on the floor. Stage
directions: right, forward, up, in studs, from where he stands.

Two tracks a clip, keyed apart:
- the body (Take.key);
- the lantern (Take.lamp): a place on the stage and its turns, since nothing holds it. Its joint is on the Torso, so
  each frame is solved against the torso as it stands by then, and it bobs by itself (BOB).

How he moves: everything he does arrives in two goes, him and then his sleeves, and the lantern has a mind of its own.
His collar stands on his torso and his head turns inside it: a nod puts his chin in it.
"""
import contextlib
import io
import json
import os
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
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import pip_sheet as ps  # noqa: E402

FPS = rc.FPS
# his model: C's finish (pip_redo_takes.py model), or another the same way jointed, as PIP_MODEL names it
MODEL = Path(os.environ.get("PIP_MODEL") or Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "pip_redo" / "handoff" / "model")
GAME, SIDE, FRONT = rc.GAME, (90.0, 6.0), rc.FRONT  # the camera's azimuth from his front and its elevation
QUARTER = (48.0, 8.0)
W = rc.W
LAMP = "Pip_Lamp"
FLIGHT = 12.0  # studs the sent lantern flies before it bursts: the clip's own distance, the builder's to scale
EYES = (0.0, FLIGHT, 5.4)  # where he looks: at you, the chin a little up, over his collar
# How far his head goes against his torso in his collar (AR63, 2026-11-28). The collar stands 0.58 studs at his back
# and his neck turns at its foot, so a chin up by u pushes the back of his head and hair out through it by
# 0.56 sin u: the clips had it to 25 degrees (the back of his head through the collar, the hair over its roll on every
# frame of Skip). CHIN: degrees up the collar takes. BOW: degrees down: past 18 his face goes through the collar's low
# front (Reveal's bow was 28). Past either, LEAN of the rest leans his body back or bows it, and the rest is let go.
# TILT: degrees his head cocks either way (the collar's sides stand 0.4).
CHIN, BOW, TILT, LEAN = 3.0, 18.0, 6.0, 0.5
STRIDE = json.loads((MODEL / "Pip.recipe.json").read_text())["stride"]["degrees"] if (MODEL / "Pip.recipe.json").exists() else 25
HEAD_POSES = Path(__file__).resolve().parent / "pip_head_poses.json"
HOME = (2.75, 0.3, 4.3)  # the lantern at rest: the recipe's pivot, as a stage place
BOB = 96  # frames the lantern takes to bob once; a loop's length is a whole number of them
RISE, SWAY = 0.07, 5.0  # studs it bobs each way, and degrees it turns as it does
STILL, HELD = 45.0, 6  # degrees a second under which an arm counts as held, and the frames it may be

# The lantern as a rod with a radius, in its own frame, and what it must clear (the content check: never onto or into
# his head or torso): boxes in each part's frame, from the recipe's sizes.
ROD, FAT = np.linspace(-0.6, 1.1, 7), 0.45   # AR63's lantern (pip_make.LAMP, 1.65): its foot to its ring, its cap's lip
BOXES = {"Torso": ((0.0, -0.376, 0.0), (1.378, 1.506, 1.077)), "Head": ((0.0, 0.0125, 0.0), (0.66, 0.64, 0.66))}


# --- the rig with the model on it -----------------------------------------------------------------------------------

def build():
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    recipe = json.loads((MODEL / "Pip.recipe.json").read_text())
    c = {name: rs.srgb(code)[:3] for name, code in ps.PALETTE.items()}
    rig = r6.build_rig("Pip", {"Torso": c["Inkwell"], "Head": c["Skin"], "Right Arm": c["Inkwell"], "Left Arm": c["Inkwell"],
                               "Right Leg": c["Slate"], "Left Leg": c["Slate"], "Face": c["Ink"]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    blend = MODEL / "pip_model.blend"
    if not blend.exists():
        raise SystemExit(f"No {blend}: run pip_model.py first")
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("Pip_")]
    costume = {o.name: o for o in dst.objects}
    motors = {}
    for piece in recipe["pieces"]:
        obj = costume[piece["name"]]
        scene.collection.objects.link(obj)
        holder = rig.parts[piece["on"]]
        if "motor" in piece:  # a joint of its own, keyed and exported under the piece's name
            local = r6.to_roblox(holder.matrix_world).inverted() @ Matrix.Translation(Vector(piece["pivot"]))
            motors[obj.name] = r6._empty(f"Pip.C0.{obj.name}", holder, local, 0.1)
            holder = rig.joints[obj.name] = rig.parts[obj.name] = r6._empty(f"Pip.J.{obj.name}", motors[obj.name], Matrix.Identity(4), 0.1)
            rig.bases[obj.name] = Matrix.Identity(4)
            rig.claws[piece["on"]] = obj.name
            obj.display.show_shadows = False  # as the recipe asks of the engine: CastShadow off on the lantern
            bpy.context.view_layer.update()
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:  # Workbench draws the active image node: the colour map
            nodes = slot.material.node_tree.nodes
            nodes.active = next(n for n in nodes if n.type == "TEX_IMAGE" and "Color" in n.image.name)
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects["Pip.Face"]]

    def undress(bare: bool):
        for o in costume.values():
            o.hide_render = bare
        for o in blocks:
            o.hide_render = not bare

    undress(False)
    feet = {leg: r6._empty(f"Pip.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    # holders of numbers, keyed like anything else, read back frame by frame once the body is keyed
    ctl = {name: r6._empty(f"Pip.Ctl.{name}", None, Matrix.Identity(4), 0.1)
           for name in ("lamp", "lampturn", "lampbob", "lift")}
    for empty in (*feet.values(), *ctl.values()):
        empty.location = (0, 0, 0)
    return scene, rig, costume, undress, feet, ctl, motors


# --- keying ---------------------------------------------------------------------------------------------------------

HUB = {
    "T": (-2, -10, 0), "feet": {"Right Leg": (0.5, -0.1), "Left Leg": (-0.5, 0.1)}, "RL": (0, 0, 0), "LL": (0, 0, 0),
    "crouch": 0.04, "look": EYES, "H": (0, 0, 0), "RA": (9, 0, 8), "LA": (17, 0, -6), "lift": 0.0,
}


class Take(rc.Take):
    """One clip being keyed from `start`, as rook_clips.Take, with the lantern's track."""

    def __init__(self, rig, feet, ctl, name, start):
        super().__init__(rig, feet, name, start)
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in HUB.items()}
        self.ctl, self.bob = ctl, BOB
        self.props = {"L": HOME, "LR": (0.0, 0.0, 0.0), "LB": 1.0}
        self.lamp(0)

    def _hold(self, f, ease, values):
        frame = self.start + f
        for name, value in values.items():
            empty = self.ctl[name]
            empty.location = value
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *rc.EASE[ease])
        self.end = max(self.end, f)
        return self

    def lamp(self, f, ease=None, L=None, LR=None, LB=None):
        """Keys the lantern at clip frame `f`: L its place on the stage (right, forward, up), LR its turns in degrees
        (tumble: end over end, the top going forward; turn: round, to his left; tilt: the top toward his left), LB how
        much of its bob it keeps (1 at rest, 0 when something has hold of it). What isn't named holds."""
        p = self.props
        p.update({k: v for k, v in (("L", L), ("LR", LR), ("LB", LB)) if v is not None})
        return self._hold(f, ease, {"lamp": p["L"], "lampturn": p["LR"], "lampbob": (p["LB"], 0, 0)})

    def key(self, f, label=None, ease=None, **changes):
        """Keys the body at clip frame `f`. `ease` shapes the move that starts here. `label` puts it on the pose sheet.
        Changes: T (pitch, turn, roll, right, _, forward), feet {leg: (right, forward), or None for a leg given by its
        angles in RL / LL}, crouch, lift (studs the body is carried over where its legs rest it: lying down), look (a
        stage place) or H (angles), RA / LA (angles, or ("reach", place, hint) for the hand)."""
        s, rig, frame = self.state, self.rig, self.start + f
        if "feet" in changes:
            changes["feet"] = {**s["feet"], **changes["feet"]}
        if "H" in changes and "look" not in changes:
            s["look"] = None
        s.update(changes)
        interp = rc.EASE[ease]
        bpy.context.scene.frame_set(frame)
        planted = {leg: W(*at) for leg, at in s["feet"].items() if at is not None}
        loose = {leg: (*s["RL" if leg == "Right Leg" else "LL"][:3], 0.0, 0.0, 0.0) for leg in r6.LEGS if leg not in planted}
        lean, base, tries = 0.0, None, 0
        while True:   # the body, then the head on it; a head past CHIN or BOW leans the body by LEAN of the rest, once
            torso = list(s["T"]) + [0.0] * (6 - len(s["T"]))
            torso[0] += lean
            torso[5] = -torso[5]  # forward, as a Roblox move
            torso, legs, sink = rc.stand_legs(rig, torso, planted, s["crouch"], loose)
            r6._key_parts(rig, frame, {"Torso": torso, **legs}, *interp)
            r6._refresh()
            swing = max(max(abs(p[0]), abs(p[2])) for p in (r6.pose_of(rig, leg) for leg in r6.LEGS))
            if base is not None and swing > max(STRIDE, base) and lean:
                # his feet stay planted, so the lean opens his hips: past the stride (Burst 61 went to 29, Reveal 20
                # to 28), half as much, and none at the fourth try
                lean, tries = (lean * 0.5 if tries < 3 else 0.0), tries + 1
                continue
            if s.get("look") is not None:
                pitch, turn, tilt = r6.look(rig, W(*s["look"]), s["H"])
            else:
                pitch, turn, tilt = s["H"]
            up, down = -pitch - CHIN, pitch - BOW
            if base is not None or max(up, down) < 0.5:
                break
            base, lean = swing, (down if down > 0 else -up) * LEAN
        if sink > rc.SINK:
            self.warned.append(f"{self.name} {f}: a leg sinks {sink:.2f} into the hip")
        for leg, empty in self.feet.items():  # where each foot stands and how low he sits, for the pass between keys
            at = s["feet"][leg]
            if at is not None:
                empty.location.x, empty.location.y = at
            empty.location.z = s["crouch"]
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *interp)
        self._hold(f, ease, {"lift": (0, 0, s["lift"])})
        self.keys.append((f, frozenset(planted)))
        rest = {"Head": (max(-CHIN, min(BOW, pitch)), turn, max(-TILT, min(TILT, tilt)))}
        for arm in ("RA", "LA"):
            a = s[arm]
            rest[rc.SHORT[arm]] = r6.reach(rig, rc.SHORT[arm], rc.HAND, W(*a[1]), a[2]) if a[0] == "reach" else a
        r6._key_parts(rig, frame, rest, *interp)
        if label:
            self.beats.append((f, label))
        return self


def clear(point, part, frame) -> float:
    """How far a point is outside a body's box, in studs; negative is inside."""
    centre, half = BOXES[part]
    d = np.abs(np.array((frame.inverted() @ point)[:]) - np.array(centre)) - np.array(half)
    out = float(np.linalg.norm(np.maximum(d, 0)))
    return out if out > 0 else float(d.max())


def props(rig, ctl, motors, takes) -> dict:
    """The last pass, once the body is keyed on every frame: the lantern's joint solved to its place on the stage with
    its bob, keyed on every frame. Returns each clip's numbers: the lantern's nearest to his body and to the floor."""
    scene, facts = bpy.context.scene, {}
    for take in takes:
        n = take.end + 1
        lamps, bodies, vals = [], [], []
        for f in range(n):
            scene.frame_set(take.start + f)
            lamps.append(r6.to_roblox(motors[LAMP].matrix_world).copy())
            bodies.append({part: r6.to_roblox(rig.parts[part].matrix_world).copy() for part in BOXES})
            vals.append({name: tuple(empty.location) for name, empty in ctl.items()})
        near, low = {part: (9.0, 0) for part in BOXES}, (9.0, 0)
        for f in range(n):
            v, frame = vals[f], take.start + f
            sway = math.sin(2 * math.pi * f / take.bob + 1.3) * SWAY * v["lampbob"][0]
            rise = math.sin(2 * math.pi * f / take.bob) * RISE * v["lampbob"][0]
            tumble, turn, tilt = v["lampturn"]
            lamp = (Matrix.Translation(W(*v["lamp"]) + Vector((0, rise, 0))) @ Matrix.Rotation(math.radians(turn + sway), 4, "Y")
                    @ Matrix.Rotation(math.radians(tilt), 4, "Z") @ Matrix.Rotation(math.radians(-tumble), 4, "X"))
            r6.key_matrices(rig, frame, {LAMP: r6.to_blender(lamps[f].inverted() @ lamp)})
            for y in ROD:
                point = lamp @ Vector((0, y, 0))
                low = min(low, (point.y - FAT, f))
                for part in BOXES:
                    near[part] = min(near[part], (clear(point, part, bodies[f][part]) - FAT, f))
        facts[take.name] = {"near": near, "low": low}
    return facts


def collar_clear(rig, costume, take, rest) -> dict:
    """His head and hair against his collar, on every frame (AR63: the collar stands on his torso and his head turns
    inside it), read in the torso's own frame at rest, where the collar was made.
    - crossing: the piece's faces that cut the collar's (through the roll or the wall, the defect);
    - past: how far any point stands out past the collar's inside below its roll's top. That's the hair through the
      roll, or a lock's point lying outside over the collar as his chin comes up, which is cloth over cloth and fine
      while nothing crosses. For information.
    Returns, a piece, ((the most faces crossing, its frame), the frames with any, (the most past, its frame))."""
    from mathutils.bvhtree import BVHTree
    import pip_redo_takes as pr
    degs = np.arange(-180.0, 180.5, 0.5)
    tops, insides = np.array([pr.collar_mouth(d) for d in degs]).T
    scene, torso, found = bpy.context.scene, rig.parts["Torso"], {}

    def faces(obj):
        co = np.empty(len(obj.data.vertices) * 3)
        obj.data.vertices.foreach_get("co", co)
        return co.reshape(-1, 3), [tuple(p.vertices) for p in obj.data.polygons]

    def placed(obj, co):
        m = np.array(rest @ torso.matrix_world.inverted() @ obj.matrix_world)
        return co @ m[:3, :3].T + m[:3, 3]

    def head_at(f):   # his head against his torso, in degrees: pitch (+ chin up), tilt, turn (+ to his left)
        scene.frame_set(take.start + f)
        e = (rest @ torso.matrix_world.inverted() @ costume["Pip_Head"].matrix_world @ head_built.inverted()).to_euler()
        return tuple(round(math.degrees(a), 1) for a in e)

    head_built = costume["Pip_Head"].matrix_basis.copy()   # where it was built: its parent's inverse cancels the head's
    scene.frame_set(take.start)
    collar = costume["Pip_Collar"]
    co, polys = faces(collar)
    wall = BVHTree.FromPolygons([tuple(p) for p in placed(collar, co)], polys)
    for name in ("Pip_Head", "Pip_Hair"):
        obj = costume[name]
        co, polys = faces(obj)
        cut, frames, past = (0, 0), 0, (-9.0, 0)
        for f in range(take.end + 1):
            scene.frame_set(take.start + f)
            p = placed(obj, co)
            n = len({a for a, _ in BVHTree.FromPolygons([tuple(q) for q in p], polys).overlap(wall)})
            cut, frames = max(cut, (n, f)), frames + (n > 0)
            deg = np.degrees(np.arctan2(p[:, 0], p[:, 1]))
            out = np.where(p[:, 2] < np.interp(deg, degs, tops), np.hypot(p[:, 0], p[:, 1]) - np.interp(deg, degs, insides), -9.0)
            past = max(past, (float(out.max()), f))
        found[name] = (cut, frames, past, head_at(cut[1]))
    poses = [head_at(f) for f in range(take.end + 1)]
    found["poses"] = poses
    found["range"] = {what: (min((p[i], f) for f, p in enumerate(poses)), max((p[i], f) for f, p in enumerate(poses)))
                      for i, what in enumerate(("pitch", "tilt", "turn"))}
    return found


def audit(rig, take) -> dict:
    """What the content check asks of every clip, as numbers: each leg's widest swing against the recipe's
    stride, and the longest an arm stays nearly still between 20 and 70 degrees over level. An R6 arm is straight, so
    an arm held up there reads as a salute: it goes up and comes away in one move, never held (HELD)."""
    scene = bpy.context.scene
    swing, held, run, last = (0.0, 0), {"Right Arm": (0, 0), "Left Arm": (0, 0)}, {"Right Arm": 0, "Left Arm": 0}, {}
    for f in range(take.end + 1):
        scene.frame_set(take.start + f)
        for leg in r6.LEGS:
            p = r6.pose_of(rig, leg)
            swing = max(swing, (max(abs(p[0]), abs(p[2])), f))
        for arm in held:
            along = (r6.to_roblox(rig.parts[arm].matrix_world).to_3x3() @ Vector((0, -1, 0))).normalized()
            still = arm in last and math.degrees(along.angle(last[arm], 0.0)) * FPS < STILL
            last[arm] = along
            run[arm] = run[arm] + 1 if still and 20.0 < math.degrees(math.asin(max(-1, min(1, along.y)))) < 70.0 else 0
            held[arm] = max(held[arm], (run[arm], f))
    return {"swing": swing, "held": held}


# --- the clips ------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses. A leg swings 25 degrees off the body and no further (the
# recipe's stride, the first Pip's), so he never sits, kneels or strides. The left arm never rolls toward the body (its roll stays at or under 0): a sleeve across the chest
# is an arm through it. The pointing sleeve is level or on its way, never held between.

def idle(t):
    """He waits like a kid in a coat that's too big: rocking a hair on his heels, the sleeves a beat behind, and now
    and then the lantern perks up and turns to him, his body leaning to it a little. His head stays level, on you,
    through the whole loop (AR27: no glance)."""
    t.loop = True
    t.key(0, "the stance", ease="sine")
    t.key(48, "breath in", ease="sine", T=(-4, -10, 0), crouch=0.0, RA=(7, 0, 10), LA=(15, 0, -8))
    t.key(96, ease="sine", T=(-1, -11, 0), crouch=0.06, RA=(11, 0, 7), LA=(19, 0, -5))
    t.key(106, ease="cubic", T=(-2, -12, 0), crouch=0.04)
    t.key(120, "the lantern looks back", ease="sine", T=(-3, -14, 0), RA=(13, 0, 12))
    t.key(144, ease="cubic", T=(-3, -13, 0))
    t.key(160, ease="sine", T=(-2, -10, 0), RA=(9, 0, 8))
    t.key(192, T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])
    t.lamp(112, ease="cubic")
    t.lamp(126, ease="sine", L=(2.7, 0.5, 4.56), LR=(0, 28, 0))  # it perks up and turns to him
    t.lamp(146, ease="cubic", L=(2.7, 0.5, 4.5), LR=(0, 24, 0))
    t.lamp(172, ease="sine", L=HOME, LR=(0, 0, 0))
    t.lamp(192)


def combo(t):
    """Two flicks off the end of his sleeve, quick as shooing a fly, and the lantern spits each time and hops back.
    For the third he sets his feet, ducks his chin into his collar and jabs the whole sleeve at you: the lantern kicks
    like a mule and goes clean over."""
    t.key(0)
    t.key(4, ease="in", T=(-4, -16, 0), RA=(-10, 0, 12))
    t.key(10, "1: a flick", T=(3, -2, 0), RA=(88, 0, 3))
    t.mark(10, "Shot1")
    t.key(14, T=(2, -4, 0), RA=(66, 0, 6))
    t.key(20, ease="in", T=(-3, -15, 0), RA=(16, 0, 14))
    t.key(26, "2: and again", T=(4, 0, 0), RA=(90, 0, 1))
    t.mark(26, "Shot2")
    t.key(30, T=(3, -2, 0), RA=(70, 0, 5))
    t.key(44, "sets his feet", ease="lin", T=(-5, -24, 0, 0, 0, -0.1), H=(8, 6, 0), crouch=0.14, RA=(-24, 0, 18), LA=(40, 0, -8),
          feet={"Right Leg": (0.55, -0.25), "Left Leg": (-0.5, 0.2)})
    t.key(57, ease="lin", T=(-7, -28, 0, 0, 0, -0.16), H=(10, 8, 0), crouch=0.2, RA=(-30, 0, 20), LA=(46, 0, -10))
    t.key(59, ease="lin", T=(0, -10, 0, 0, 0, 0.05), look=EYES, H=(0, 0, 0), RA=(36, 0, 14), crouch=0.14)
    t.key(62, "3: the jab", T=(9, 13, 0, 0, 0, 0.28), RA=(88, 0, 0), LA=(14, 0, -4), crouch=0.1)
    t.mark(62, "Shot3")
    t.key(67, "it kicks", T=(-6, 9, 0, 0, 0, -0.2), RA=(82, 0, 2), LA=(40, 0, -12), crouch=0.04)
    t.key(76, T=(-2, 3, 0, 0, 0, -0.12), RA=(54, 0, 6), LA=(28, 0, -9))
    t.key(100, T=HUB["T"], RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"], feet=HUB["feet"])
    t.lamp(9, ease="out")
    t.lamp(12, L=(2.85, -0.85, 4.6), LR=(-36, 0, 10))  # it spits, and the spit kicks it back over a stud, askew
    t.lamp(22, L=HOME, LR=(0, 0, 0))
    t.lamp(25, ease="out")
    t.lamp(28, L=(2.9, -0.95, 4.62), LR=(-42, 0, -10))
    t.lamp(38, ease="cubic", L=HOME, LR=(0, 0, 0))
    t.lamp(56, ease="in", L=(2.6, 0.75, 4.05), LR=(16, 0, 0), LB=0.3)  # it leans in beside the sleeve
    t.lamp(62, ease="out")
    t.lamp(67, ease="lin", L=(2.8, -0.9, 4.5), LR=(-170, 0, 0), LB=0.0)
    t.lamp(77, ease="out", L=(2.85, -0.7, 4.66), LR=(-330, 0, 0))
    t.lamp(93, ease="sine", L=HOME, LR=(-360, 0, 0), LB=1.0)


def burst(t):
    """He reels the lantern round on the end of his sleeve like a kite in a wind, winds up like a boy with a ball too
    heavy for him, and lets go: the sleeve goes level down its line, the lantern goes end over end, and the throw
    throws him. Back on his heels all of a piece, the free sleeve wheeling, then a step back to catch himself; he leans
    in to see whether it worked, and gives it a nod."""
    line = ("reach", (1.2, 6.0, 3.45), (90, 0, 0))  # the sleeve level, down the lantern's line

    def thrown(pitch, back=0.0):
        """Rocked `pitch` degrees back over his heels all of a piece, and `back` studs further than his heels are."""
        tipped = fall(pitch, 1.0, 14)
        return (*tipped[:5], tipped[5] - back)

    t.key(0)
    t.key(8, ease="cubic", T=(3, -5, 0), RA=(46, 0, 8), LA=(30, 0, -5))
    t.mark(8, "Heat")
    t.key(30, "wound", ease="lin", T=(-3, -28, 0, 0, 0, -0.12), crouch=0.14, RA=(-36, 0, 30), LA=(48, 0, -10),
          feet={"Right Leg": (0.62, -0.3), "Left Leg": (-0.57, 0.22)})
    t.key(45, "a ball too heavy", ease="lin", T=(-5, -33, 0, 0, 0, -0.2), crouch=0.2, RA=(-48, 0, 34), LA=(54, 0, -12))
    t.key(48, ease="lin", T=(0, -8, 0, 0, 0, 0.04), RA=(38, 0, 28), LA=(34, 0, -8), crouch=0.14)
    t.key(51, "the send", T=(7, 14, 0, 0, 0, 0.3), RA=line, LA=(20, 0, -4), crouch=0.1)
    t.mark(51, "Send")
    # The kick throws him (research's fix 1). He rocks back over his heels like a plank, toes up: a leg keeps to 25
    # degrees off the body (the stride), so the legs go with the body. Round 2 (AR4 section 8, "standing, then
    # ducking" at the player's distance): the rock has to read at 30 studs, so it ends in a step. His back foot goes a
    # stud behind him and takes him, the front one dragged after, and he stays rocked back on it through the burst,
    # tall, never sunk into his collar.
    t.key(56, "it throws him", T=thrown(-24), feet={"Right Leg": None, "Left Leg": None}, RL=(-8, 0, 0), LL=(8, 0, 0),
          H=(-12, -4, 0), RA=line, LA=(-30, 0, -34), crouch=0.0)
    # a leg goes 25 degrees off the body, so a foot behind his hips needs the lean eased: he steps out of it
    t.key(61, "a step back", T=(-12, 12, 0, 0, 0, -1.1), feet={"Right Leg": (0.65, -1.2), "Left Leg": (-0.55, -0.35)},
          crouch=0.04, H=(-10, -2, 0), RA=line, LA=(-48, 0, -40))
    t.key(65, "caught on it", ease="out", T=(-10, 12, 0, 0, 0, -1.25), feet={"Left Leg": (-0.55, -0.45)}, crouch=0.1,
          H=(-6, -2, 0), RA=(74, 0, 6), LA=(-20, 0, -30))
    t.mark(66, "Burst")
    t.key(74, ease="sine", T=(-9, 10, 0, 0, 0, -1.15), RA=(58, 0, 4), LA=(30, 0, -12), crouch=0.05)
    t.key(86, "did it work?", ease="sine", T=(-6, 8, 0, 0, 0, -1.0), H=(6, 3, 4), RA=(24, 0, 8), LA=(24, 0, -8), crouch=0.06)
    t.mark(98, "Return")
    t.key(101, ease="in", T=(-6, 4, 0, 0, 0, -0.85), H=(-6, 0, 0), RA=(14, 0, 8), LA=(19, 0, -6), feet={"Right Leg": (0.52, -0.6)})
    t.key(106, "a nod: it worked", T=(-4, 3, 0, 0, 0, -0.6), H=(16, 0, 0))
    t.key(119, T=(-3, -4, 0, 0, 0, -0.3), look=EYES, H=(0, 0, 0), feet={"Left Leg": (-0.5, 0.1)})
    t.key(132, T=HUB["T"], RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"], feet=HUB["feet"])
    t.lamp(8, ease="cubic")
    t.lamp(26, ease="cubic", L=(2.1, 1.5, 3.5), LR=(12, 0, 0), LB=0.3)  # reeled round to the sleeve's end
    t.lamp(44, ease="in", L=(3.2, -1.7, 3.0), LR=(-34, 0, 0), LB=0.0)  # dragged back after it, like a weight on a line
    t.lamp(48, ease="lin", L=(3.0, 0.3, 3.2), LR=(-10, 0, 0))
    t.lamp(51, ease="lin", L=(1.75, 2.7, 3.45), LR=(40, 0, 0))  # past the cuff, and gone
    t.lamp(66, ease="out", L=(0.3, FLIGHT, 2.9), LR=(580, 0, 0))  # a turn and a half on the way
    t.lamp(98, ease="cubic", L=(0.3, FLIGHT, 3.1), LR=(720, 0, 0))
    t.lamp(113, ease="sine", L=(2.2, 5.0, 4.9), LR=(720, 20, 0), LB=0.4)  # home the long way, in no hurry
    t.lamp(128, L=HOME, LR=(720, 0, 0), LB=1.0)
    t.lamp(132)


def hit(t):
    """It catches him in the chest and he folds round it like a dropped coat, his chin into his collar. A flinch:
    short, and the feet never move."""
    t.key(0, ease="out")
    t.key(3, "struck", T=(-10, -22, 3, 0, 0, -0.2), H=(12, -6, 0), RA=(36, 0, 10), LA=(42, 0, -6), crouch=0.1)
    t.key(8, T=(-7, -19, 2, 0, 0, -0.14), H=(-7, -8, 0), RA=(22, 0, 10), LA=(28, 0, -7))
    t.key(20, T=HUB["T"], look=EYES, H=(0, 0, 0), RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"])
    t.lamp(2, ease="out")
    t.lamp(6, L=(3.1, 0.05, 4.5), LR=(0, 0, -16), LB=0.2)  # it shies
    t.lamp(13, ease="sine", L=(2.68, 0.36, 4.24), LR=(0, 0, 5))
    t.lamp(20, L=HOME, LR=(0, 0, 0), LB=1.0)


def fall(pitch, share=0.56, turn=-3):
    """Where his chest is when he's tipped `pitch` degrees all of a piece (under 0: back over his heels): a T. At a
    `share` under 1 his feet give as he goes, so he comes down across where he stood, not past it."""
    a = math.radians(pitch)
    return (pitch, turn, 0, 0, 0, share * (math.copysign(0.6 * (1 - math.cos(a)), pitch) + 3.0 * math.sin(a)))


# Flat on his back, his head toward the player's camera: the heels and the jacket's back carry him, the sleeves lie
# out at his sides, and his head has dropped aside in his collar.
LAID = dict(T=fall(-86), feet={"Right Leg": None, "Left Leg": None}, RL=(-12, 0, 0), LL=(-10, 0, 0), crouch=0.0, lift=0.0,
            H=(8, -22, 0), RA=(0, 0, 58), LA=(0, 0, -52))
LAID_LAMP = dict(L=(2.6, -4.3, 1.9), LR=(0, 0, 26), LB=0.5)


def down(t):
    """It takes him in the chest and he goes over backwards all of a piece, like a plank, the sleeves reaching for
    something to hold. His boots bounce once, and his head drops aside. The lantern comes down to look."""
    t.key(0, ease="out")
    t.key(6, "the blow", T=(-12, -16, 0, 0, 0, -0.5), H=(14, 6, 0), RA=(52, 0, 10), LA=(58, 0, -8), crouch=0.0)
    # a plank's fall gathers speed: 1.8, 3.3, then 4.9 degrees a frame
    t.key(14, "and over", ease="lin", T=fall(-26), H=(18, 4, 0), RA=(84, 0, 12), LA=(90, 0, -10))
    t.key(22, ease="lin", T=fall(-52), feet={"Right Leg": None, "Left Leg": None}, RL=(-6, 0, 0), LL=(-4, 0, 0),
          H=(16, 4, 0), RA=(104, 0, 22), LA=(110, 0, -20), lift=0.3)
    t.key(29, "down", **{**LAID, "RL": (-8, 0, 0), "LL": (-6, 0, 0), "RA": (46, 0, 48), "LA": (52, 0, -44), "lift": 0.2,
                         "H": (10, 4, 0)})
    t.mark(29, "Land")
    t.key(34, T=fall(-85), RL=(8, 0, 0), LL=(14, 0, 0), RA=(10, 0, 56), LA=(14, 0, -50), lift=0.5)  # the boots bounce, once
    t.key(41, "his head drops aside", **LAID)
    t.key(60, "held", ease="hold")
    t.key(66)
    t.lamp(4, ease="out")
    t.lamp(9, L=(3.1, 0.0, 4.6), LR=(0, 0, -18), LB=0.2)
    t.lamp(30, ease="cubic", L=(3.2, -2.4, 3.9), LR=(0, 0, 0))
    t.lamp(56, ease="sine", **LAID_LAMP)
    t.lamp(66)


def up(t):
    """His head comes up first, his eyes over his collar. Then he stands himself up the way you'd walk a ladder
    upright, goes a little too far, and the lantern is back at his shoulder before he thinks to look for it."""
    t.key(0, **LAID)
    t.key(10, "his head first", H=(24, 0, 0), RA=(6, 0, 40), LA=(8, 0, -36))
    t.key(22, "like a ladder", ease="cubic", T=fall(-52), RL=(-6, 0, 0), LL=(-4, 0, 0), lift=0.3, H=(12, 0, 0),
          RA=(58, 0, 14), LA=(62, 0, -12))
    t.key(36, ease="cubic", T=fall(-8), feet=HUB["feet"], lift=0.0, RA=(30, 0, 10), LA=(34, 0, -8), look=EYES, H=(0, 0, 0))
    t.key(44, "up", T=(7, -8, 0, 0, 0, 0.18), crouch=0.0, RA=(4, 0, 10), LA=(12, 0, -8))
    t.key(58, T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])
    t.lamp(0, **LAID_LAMP)
    t.lamp(8, ease="cubic")
    t.lamp(19, ease="sine", L=(3.3, -2.6, 3.0), LR=(0, 0, 8))
    t.lamp(36, ease="sine", L=(2.85, 0.5, 4.6), LR=(0, 0, 0), LB=0.6)
    t.lamp(50, L=HOME, LB=1.0)
    t.lamp(58)


def reveal(t):
    """A shock of gold hair in a high red collar comes out of the shard, bowed. It stays there. Then a lantern pops
    alight beside it, the head comes up to the light, and there's a boy, squinting at you. He tries a flourish: the
    lantern loops the loop and nearly takes his head off. He ducks into his collar, and looks up at you from it as his
    name lands."""
    low = dict(T=(16, 0, 0, 0, 0, 0.05), feet={"Right Leg": (0.5, -0.05), "Left Leg": (-0.5, 0.05)}, crouch=0.55,
               H=(28, 0, 0), RA=(24, 0, 4), LA=(26, 0, -4))  # from the front: his hair, bowed in his collar
    t.key(0, "bowed in his collar", **low)
    t.key(20, ease="cubic", **{**low, "T": (18, 0, 0, 0, 0, 0.05)})
    t.mark(24, "Kindle")
    t.key(27, ease="back", T=(15, -6, 0, 0, 0, 0.05), H=(22, -30, 0), crouch=0.5)  # the light makes him look
    t.key(41, "and a boy, squinting", T=(-3, -8, 0), crouch=0.04, look=EYES, H=(0, 0, 0), RA=(10, 0, 8), LA=(18, 0, -6))
    t.key(52, ease="in", T=(-4, -20, 0), RA=(-22, 0, 16), crouch=0.1)
    t.key(58, "a flourish", T=(5, 8, 0, 0, 0, 0.1), RA=(86, 0, 0), crouch=0.06)
    t.mark(58, "Flourish")
    t.key(66, T=(-9, 6, 0, 0, 0, -0.3), H=(-10, -10, 0), RA=(60, 0, 4), LA=(44, 0, -14), crouch=0.0)
    t.key(70, "nearly", T=(-6, 2, 0, 0, 0, -0.36), H=(14, -4, 0), RA=(40, 0, 8), LA=(62, 0, -20), crouch=0.16)  # he ducks
    t.key(75, T=(-7, 0, 0, 0, 0, -0.34), H=(8, -2, 0), LA=(40, 0, -14), crouch=0.1)
    t.key(85, ease="sine", T=(-5, -6, 0, 0, 0, -0.2), look=EYES, H=(0, 0, 0), RA=(14, 0, 8), LA=(26, 0, -8), crouch=0.04)
    t.key(96, "held for the name", T=(-4, -8, 0, 0, 0, -0.15), RA=(11, 0, 8), LA=(18, 0, -6))
    t.lamp(0, L=(0.5, -2.9, 1.6), LR=(0, 0, 0), LB=0.0)  # behind him, out of sight
    t.lamp(17, ease="in")
    t.lamp(22, ease="lin", L=(2.9, -2.1, 2.7))  # round his side, not through him
    t.lamp(28, ease="back", L=(2.75, 0.4, 4.5), LB=0.6)
    t.lamp(54, ease="in", L=(2.9, 0.3, 4.3), LB=0.0)
    t.lamp(58, ease="lin", L=(2.95, 1.3, 4.5), LR=(60, 0, 0))  # round the loop: forward, over, back, under
    t.lamp(62, ease="lin", L=(2.95, 1.2, 5.9), LR=(150, 0, 0))
    t.lamp(66, ease="lin", L=(2.95, -0.3, 6.1), LR=(230, 0, 0))
    t.lamp(70, ease="lin", L=(2.95, -0.9, 4.9), LR=(310, 0, 0))
    t.lamp(76, ease="back", L=(2.8, 0.2, 4.2), LR=(360, 0, 0))
    t.lamp(88, ease="sine", L=HOME, LB=1.0)
    t.lamp(96)


def work(t):
    """A shift at the bay: he holds a sleeve over the post like warming a hand at a stove, the lantern ducks in and
    gives it a go, and while it gets its breath he drops his chin into his collar, then looks up and reads the
    dial."""
    t.loop, t.bob = True, 120
    post = (0.3, 3.0, 2.9)
    top = dict(T=(6, 18, 0), feet={"Right Leg": (0.5, 0.12), "Left Leg": (-0.48, -0.1)}, crouch=0.06, look=post, H=(0, 0, 0),
               RA=("reach", (0.9, 2.1, 3.0), (68, 0, 0)), LA=(20, 0, -6))
    t.key(0, "a sleeve over the post", ease="sine", **top)
    t.key(20, ease="in", T=(3, 13, 0), RA=("reach", (1.0, 1.9, 3.3), (74, 0, 0)))
    t.key(27, "it gives it a go", T=(10, 21, 0, 0, 0, 0.08), RA=("reach", (0.8, 2.3, 2.9), (64, 0, 0)), crouch=0.1)
    t.mark(27, "Pump")
    t.key(34, T=(8, 20, 0, 0, 0, 0.05), crouch=0.08)
    t.key(58, ease="sine", T=(4, 12, 0), RA=(30, 0, 6), LA=(34, 0, -8), crouch=0.05)
    t.key(70, ease="snap", T=(5, 12, 0), H=(20, 0, 0), LA=(28, 0, -9))  # the chin down into his collar, a breath
    t.key(76, "and looks up", T=(0, 10, 0), H=(-12, 0, 0), LA=(22, 0, -10))
    t.key(83, "and reads the dial", ease="sine", T=(1, 12, 0), look=(0.4, 3.2, 5.9), H=(0, 0, 0), LA=(26, 0, -8))
    t.key(92, ease="sine")
    t.key(98, ease="sine", T=(5, 16, 0), LA=(28, 0, -7), RA=("reach", (1.0, 1.9, 3.2), (70, 0, 0)), look=post)
    t.key(120, **top)
    rest = dict(L=(2.3, 1.7, 4.2), LR=(0, 16, 0), LB=1.0)
    t.lamp(0, **rest)
    t.lamp(18, ease="in", L=(2.55, 1.9, 4.4), LR=(-14, 16, 0), LB=0.3)  # it rears
    t.lamp(27, ease="out", L=(0.75, 2.9, 3.0), LR=(50, 30, 0), LB=0.0)  # and ducks its head at the post
    t.lamp(36, ease="sine", L=(0.9, 2.8, 3.5), LR=(20, 30, 0))
    t.lamp(64, ease="sine", L=(2.2, 1.8, 3.95), LR=(0, 16, 0), LB=0.6)  # getting its breath, a little low
    t.lamp(120, **rest)


def skip(t):
    """He hops back out of reach like a kid who's touched a stove: both feet at once, never a step, his eyes on you
    the whole way. The sleeves fling forward to keep him upright, and the lantern is left behind for a moment and bobs
    up after him. The body's
    travel is the game's (TR7, part 2): here he hops in place, and lands ready (Land)."""
    t.key(0)
    t.key(5, "gathers", ease="in", T=(5, -10, 0, 0, 0, 0.05), crouch=0.15, RA=(-6, 0, 12), LA=(-2, 0, -8))
    t.key(9, "off", ease="out", T=(-6, -10, 0, 0, 0, -0.1), crouch=0.0, lift=0.14, RA=(34, 0, 14), LA=(40, 0, -10),
          feet={"Right Leg": (0.5, 0.0), "Left Leg": (-0.5, 0.15)})
    t.key(15, "in the air", ease="in", T=(-2, -10, 0, 0, 0, -0.04), crouch=0.04, lift=0.36, RA=(52, 0, 18), LA=(58, 0, -12),
          feet={"Right Leg": (0.52, -0.3), "Left Leg": (-0.52, -0.12)})
    t.key(21, "lands", ease="out", T=(6, -10, 0, 0, 0, 0.05), crouch=0.15, lift=0.0, RA=(26, 0, 16), LA=(30, 0, -11),
          feet=HUB["feet"])
    t.mark(21, "Land")
    t.key(26, ease="sine", T=(0, -10, 0), crouch=0.07, RA=(13, 0, 10), LA=(20, 0, -7))
    t.key(32, T=HUB["T"], RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"])
    t.lamp(6, ease="in")
    t.lamp(12, ease="out", L=(2.8, 0.7, 4.22), LR=(12, 0, 0), LB=0.3)  # left behind, low, as he goes
    t.lamp(19, ease="in", L=(2.82, 0.55, 4.62), LR=(4, 0, 0))  # and bobs up after him
    t.lamp(25, ease="out", L=(2.77, 0.15, 4.2), LR=(-10, 0, 0))  # past him as he stops, and down
    t.lamp(31, ease="sine", L=HOME, LR=(0, 0, 0), LB=1.0)
    t.lamp(32)


CLIPS = {"Idle": idle, "Combo": combo, "LanternBurst": burst, "Hit": hit, "Down": down, "Up": up, "Reveal": reveal,
         "Work": work, "Skip": skip}
# The rows a clip's pose sheet shows, and the first is its pack's view. The send is read from far off too, since the
# lantern goes twelve studs; the Reveal is met from the front; laid out he's longer than the game view is tall, so the
# fall and the rise are read from the same places with a wider lens, aimed lower.
LAID_VIEWS = ("wide", "wide side", "wide front")
VIEWS = {"LanternBurst": ("game", "side", "far"), "Reveal": ("front", "side", "game"), "Down": LAID_VIEWS, "Up": LAID_VIEWS,
         "Work": ("front", "side", "game")}


# --- outputs --------------------------------------------------------------------------------------------------------

def cameras(scene, rig):
    cams = {name: r6.body_camera(scene, rig, 0, az, el, distance=14.0, height=3.4, name=name)
            for name, (az, el) in (("game", GAME), ("front", FRONT), ("side", SIDE))}
    for name, (az, el) in (("wide", GAME), ("wide side", SIDE), ("wide front", FRONT)):
        cams[name] = r6.body_camera(scene, rig, 0, az, el, distance=14.0, height=1.6, fov=48.0, name=name)
    cams["far"] = r6.fixed_camera(scene, (26.0, 5.0, -5.6), (0.0, 3.2, -5.6), 38.0, "far")  # from his right, the whole flight
    return cams


def pose_sheet(scene, cams, take, out):
    views = VIEWS.get(take.name, ("game", "side", "front"))
    shots = [(cams[view], take.start + f, f"{take.name} {f}: {label}" if view == views[0] else f"{f} {view}")
             for view in views for f, label in take.beats]
    scene.render.resolution_x, scene.render.resolution_y = 330, 380
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(take.beats))
    print(f"wrote {path}")


def arc_sheet(scene, rig, cams, take, out):
    """One dot a frame where the lantern's flame (amber) and the right cuff (pale) are through the clip, over the body
    at its middle beat: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)

    def at(rig, part):
        return r6.to_roblox(rig.parts[part].matrix_world)

    dots = r6.path_dots(rig, frames, [(LAMP, (0.0, 0.0, 0.0))], radius=0.07, name="Flame", at=at)
    dots += r6.path_dots(rig, frames, [("Right Arm", rc.HAND)], colour=(0.92, 0.9, 0.82), radius=0.045, name="Cuff", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    views = ("far", "side") if take.name == "LanternBurst" else ("game", "side")
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
    """The send at 64 px from the player's camera's height on eight headings, over the dusk floor and over a bright
    one, shown four times its size: a row a frame."""
    floor, shading = bpy.data.materials["Floor"], scene.display.shading
    dusk = (tuple(floor.diffuse_color), tuple(shading.background_color))
    cams = [r6.body_camera(scene, rig, take.start, az, GAME[1], distance=14.0, height=3.4, name=f"heading {az}")
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
          f"{list(reversed(frames))}; across, from his front round by 45 degrees)")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "export", "audit") else "poses"
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    scene, rig, costume, undress, feet, ctl, motors = build()
    rest = rig.parts["Torso"].matrix_world.copy()   # before any key: the model's own frame, where the collar was made
    recipe = json.loads((MODEL / "Pip.recipe.json").read_text())
    takes = {}
    for i, name in enumerate(CLIPS):
        if name in wanted:
            takes[name] = take = Take(rig, feet, ctl, name, 1000 * i)
            CLIPS[name](take)
            for line in take.warned:
                print("  " + line)
    rc.ground(rig, feet, list(takes.values()))
    rc.lift(rig, ctl["lift"], list(takes.values()))
    numbers = props(rig, ctl, motors, list(takes.values()))
    cams = cameras(scene, rig)
    facts, poses = {}, set()
    for name, take in takes.items():
        n, checks = numbers[name], audit(rig, take)
        near = "; ".join(f"{part} {d:.2f} at {f}" for part, (d, f) in n["near"].items())
        clear = collar_clear(rig, costume, take, rest)
        span = clear.pop("range")
        poses |= set(clear.pop("poses"))
        collar = "; ".join(f"{piece[4:].lower()} {cut} at {f} (his head's pitch, tilt, turn {pose}; {frames} frames), "
                           f"out past its inside {most:+.3f} at {g}"
                           for piece, ((cut, f), frames, (most, g), pose) in clear.items())
        collar += "\n  his head against his torso, degrees (pitch + chin up, tilt, turn + to his left): " + "; ".join(
            f"{what} {lo:+.0f} at {f} to {hi:+.0f} at {g}" for what, ((lo, f), (hi, g)) in span.items())
        notes = (f"{name}: {take.end + 1} frames, {take.end / FPS:.2f} s\n"
                 f"  the lantern's nearest, in studs: {near}; over the floor {n['low'][0]:.2f} at {n['low'][1]}\n"
                 f"  faces through the collar (0: clear): {collar}\n"
                 f"  a leg's widest swing: {checks['swing'][0]:.1f} of {recipe['stride']['degrees']} degrees, at {checks['swing'][1]}\n"
                 f"  the longest an arm is nearly still at 20 to 70 degrees up, of {HELD} frames: right {checks['held']['Right Arm'][0]} "
                 f"(to {checks['held']['Right Arm'][1]}), left {checks['held']['Left Arm'][0]} (to {checks['held']['Left Arm'][1]})\n")
        print(notes, end="")
        facts[name] = {"File": f"Pip_{name}.json", "Frames": take.end + 1, "Seconds": round(take.end / FPS, 3), "Loop": take.loop,
                       "Markers": [[round(t * FPS), label] for t, label in take.markers]}
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        heard = io.StringIO()  # the export audits itself aloud: the pack's notes keep what it said
        with contextlib.redirect_stdout(heard):
            # the Name is the game's: Author.SaveBaked reads Anim_Pip<Clip> and checks the clip is named the same
            r6.export(rig, out / f"Pip_{name}.json", "Pip", f"Pip{name}", take.start, take.start + take.end,
                      markers=take.markers, source="tools/blender/pip_clips.py", extra={"Loop": take.loop})
        print(heard.getvalue(), end="")
        if mode == "audit":
            continue
        arc_sheet(scene, rig, cams, take, out)
        bare_sheet(scene, rig, take, undress, out)
        if name == "LanternBurst":
            heading_sheet(scene, rig, take, (45, 51, 57, 63), out)
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame: cams[VIEWS.get(name, ("game",))[0]], bare=SIDE[0], strip=strip, undress=undress, notes=notes + heard.getvalue())
    if mode != "poses" and len(takes) == len(CLIPS):
        facts["LanternBurst"]["Flight"] = FLIGHT
        (out / "Pip.clips.json").write_text(json.dumps({"Fps": FPS, "Clips": facts}, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out / 'Pip.clips.json'}")
        # every head pose the clips hold against his torso: pip_redo_takes.py fits his hair inside his collar to them
        HEAD_POSES.write_text(json.dumps({"source": "tools/blender/pip_clips.py audit", "pitch tilt turn": sorted(poses)})
                              .replace("], [", "],\n  [") + "\n", encoding="utf-8")
        print(f"wrote {HEAD_POSES} ({len(poses)} poses)")


if __name__ == "__main__":
    main()
