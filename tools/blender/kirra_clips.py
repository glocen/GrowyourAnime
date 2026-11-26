"""Kirra's clips on the R6 rig, her model riding it (AR10, delivery 3).

blender.exe -b --factory-startup --python tools/blender/kirra_clips.py -- <out_dir> [poses|export|audit] [clip ...]

- poses (the default): one sheet a clip, its key poses from the player's camera and from her side (the Reveal and
  Work from her front too), and kirra_blocking.png, every clip's key poses from the player's camera, a row a clip.
- export: Kirra_<Clip>.json for the builder (r6anim.export, with its audit) and Kirra.clips.json; and for the review,
  a clip's pack (pack_<Clip>.png and .txt: its beats, on the bare rig, at 64 px, and its numbers), its arcs
  (arcs_<Clip>.png, one dot a frame) and the bare rig stepped through (bare_<Clip>.png).
- audit: the export's audit alone.

Needs kirra_model.py's output (kirra_model.blend and Kirra.recipe.json) in MODEL. The keying is rook_clips.py's: every
clip at 60 fps on its own stretch of one timeline, starting from HUB; feet given as places on the floor, from where
the HumanoidRootPart stands and the way it faces. Stage directions: right, forward, up, in studs.

Beside the body, three tracks a clip, keyed apart and solved on every frame once the body is keyed:
- each blade (Take.blade): how far it's in her fist (0 in its sheath, 1 in her hand) and its turn in the fist. Its
  joint is on the Torso at the grip, as Pip's lantern's is, so a clip that never keys it (the shared walk, the open
  reactions) leaves it sheathed; a clip that does lays it in her hand frame by frame, wherever the hand is.
- the tail (Take.tail): eight joints worked out from a few numbers. Free, it hangs from the knot in its S, kept level
  on her heading however she leans or twists, and a wave runs down it (ripple about the band's width, swing about its
  face, growing toward the tip). Aimed, each segment turns toward one direction, root first ('curl' holds the tip
  back), its band's width laid flat or on edge; trailed, each segment follows the path the knot has drawn. The floor
  holds it up wherever it is.
- the HumanoidRootPart (Take.place), for the review only: the game moves her (the dash, the blink); the clip keys the
  body on the root.

How she moves: small and fast, already leaving. The cloth tells you where she's been.
"""
import contextlib
import io
import json
import math
import os
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402

FPS = rc.FPS
ROOT = Path(__file__).resolve().parents[2]
# her model: the first make (kirra_model.py), or another the same way jointed, as KIRRA_MODEL names it (kirra_make.py)
MODEL = Path(os.environ.get("KIRRA_MODEL") or ROOT / "build" / "scratch" / "modulo" / "kirra" / "model")
GAME, SIDE, FRONT, QUARTER = rc.GAME, (90.0, 6.0), rc.FRONT, (48.0, 8.0)  # azimuth from the stage's front, elevation
W = rc.W
UP = Vector((0, 1, 0))
SIDES = {"R": ("Kirra_BladeR", "Right Arm"), "L": ("Kirra_BladeL", "Left Arm")}
SCARF = [f"Kirra_Scarf{k + 1}" for k in range(8)]
LINKS = len(SCARF)
EYES = (0.0, 12.0, 4.4)  # level, on what's next
SHADE = (0.0, 3.4)  # the Combo's Shade, once the dash has closed in
STEP = 35.0  # Scarf Step crosses the Shade 35 degrees right of the line from the player's camera (AR10, tier 2)
GONE = 5.0  # studs from her to the Shade along that line as she goes
FLOOR = 0.06  # the tail's line keeps this far over the floor
STEEL = np.linspace(-0.31, 1.74, 9)  # the blade's length, pommel to point, from where the fist closes
EDGE = 0.08  # the blade's half width, for its clearance
PULL = 1.3  # studs a blade slides out of its sheath along its length, at the middle of a draw, before it turns
NEAR = 1.5  # studs from its sheathed grip inside which a blade in her fist turns to lie along its sheath
BEND = math.radians(22.0)  # the most one tail link turns from the one before: the model's seam test showed no gap to 22
# degrees, and past it the link's edges notch (research's read of the blocking, the Reveal at 14 and 36)
STILL, HELD = 45.0, 6  # degrees a second under which an arm counts as held, and the frames it may be (Pip's)
# Her body as boxes in each part's frame, for what the blades and the tail must clear: R6's, the head with its hair.
BOXES = {"Torso": ((0, 0, 0), (1.0, 1.0, 0.5)), "Head": ((0, 0.05, 0.05), (0.72, 0.72, 0.72)),
         "Right Arm": ((0, 0, 0), (0.5, 1.0, 0.5)), "Left Arm": ((0, 0, 0), (0.5, 1.0, 0.5)),
         "Right Leg": ((0, 0, 0), (0.5, 1.0, 0.5)), "Left Leg": ((0, 0, 0), (0.5, 1.0, 0.5))}


# --- the rig with the model on it -----------------------------------------------------------------------------------

def build():
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    recipe = json.loads((MODEL / "Kirra.recipe.json").read_text())
    c = {name: rs.srgb(code)[:3] for name, code in ks.PALETTE.items()}
    rig = r6.build_rig("Kirra", {"Torso": c["Navy"], "Head": c["Skin"], "Right Arm": c["Navy"], "Left Arm": c["Navy"],
                                 "Right Leg": c["Navy"], "Left Leg": c["Navy"], "Face": c["Ink"]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    blend = MODEL / "kirra_model.blend"
    if not blend.exists():
        raise SystemExit(f"No {blend}: run kirra_model.py first")
    names = {piece["name"] for piece in recipe["pieces"]}
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = [n for n in src.objects if n in names]
    costume = {o.name: o for o in dst.objects}
    rest = {"torso": r6.to_roblox(rig.parts["Torso"].matrix_world).copy(), "blades": {}, "tail": tail_rest(recipe)}
    motors, extra = {}, []
    for piece in recipe["pieces"]:
        obj = costume[piece["name"]]
        scene.collection.objects.link(obj)
        on, pivot = piece.get("on"), piece.get("pivot")
        if "grip" in piece:  # a blade: its joint on the Torso at the grip, so unkeyed it stays in its sheath
            on, pivot = "Torso", piece["grip"]["at"]
            g = {k: Vector(piece["grip"][k]) for k in ("at", "length", "back")}
            rest["blades"][obj.name] = {"G": frame_of(g["at"], g["length"], g["back"]), "J": Matrix.Translation(g["at"])}
        holder = rig.parts[on]
        if pivot is not None:  # a joint of its own, keyed and exported under the piece's name
            local = r6.to_roblox(holder.matrix_world).inverted() @ Matrix.Translation(Vector(pivot))
            motors[obj.name] = r6._empty(f"Kirra.C0.{obj.name}", holder, local, 0.1)
            holder = rig.joints[obj.name] = rig.parts[obj.name] = r6._empty(f"Kirra.J.{obj.name}", motors[obj.name],
                                                                             Matrix.Identity(4), 0.1)
            rig.bases[obj.name] = Matrix.Identity(4)
            extra.append((on, obj.name))
            bpy.context.view_layer.update()
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:  # Workbench draws the active image node: the colour map
            nodes = slot.material.node_tree.nodes
            nodes.active = next(n for n in nodes if n.type == "TEX_IMAGE" and "Color" in n.image.name)
    rig.extra_joints = lambda: list(extra)  # the blades and the chain, root to tip, past R6's six
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects["Kirra.Face"]]

    def undress(bare: bool):
        for o in costume.values():
            o.hide_render = bare
        for o in blocks:
            o.hide_render = not bare

    undress(False)
    feet = {leg: r6._empty(f"Kirra.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    # holders of numbers, keyed like anything else, read back frame by frame once the body is keyed
    ctl = {name: r6._empty(f"Kirra.Ctl.{name}", None, Matrix.Identity(4), 0.1)
           for name in ("lift", "bladeR", "gripR", "bladeL", "gripL", "tailaim", "taildir", "tailwave", "tailphase",
                        "tailmode")}
    for empty in (*feet.values(), *ctl.values()):
        empty.location = (0, 0, 0)
    return scene, rig, costume, undress, feet, ctl, motors, rest, extra


def frame_of(at, length, back) -> Matrix:
    """A grip frame (Roblox): X = length x back, Y the length, Z the back (the spine), at `at`."""
    x = length.cross(back)
    return Matrix(((x.x, length.x, back.x, at.x), (x.y, length.y, back.y, at.y), (x.z, length.z, back.z, at.z), (0, 0, 0, 1)))


def tail_rest(recipe) -> dict:
    """The chain at rest, from the recipe (Roblox): each joint's pivot, the chord to the next (the last to the bone
    end), and the band's width and face there. A joint's frame is the model's axes at rest, so these are its own too."""
    chain = [next(p for p in recipe["pieces"] if p["name"] == name) for name in SCARF]
    pivots = [Vector(p["pivot"]) for p in chain]
    tip = Vector(next(p for p in recipe["points"] if p["name"] == "ScarfTip")["at"])
    ends = pivots[1:] + [tip]
    across = [Vector(p["across"]).normalized() for p in chain]
    along = [Vector(p["along"]).normalized() for p in chain]
    return {"pivots": pivots, "chords": [e - p for e, p in zip(ends, pivots)], "lengths": [(e - p).length for e, p in zip(ends, pivots)],
            "across": across, "normal": [a.cross(b).normalized() for a, b in zip(along, across)]}


# --- keying ---------------------------------------------------------------------------------------------------------

HUB = {
    "T": (12, -10, 0), "feet": {"Right Leg": (0.6, 0.45), "Left Leg": (-0.65, -0.42)}, "RL": (0, 0, 0), "LL": (0, 0, 0),
    "crouch": 0.12, "look": EYES, "H": (0, 0, 0), "RA": (16, 0, 9), "LA": (-22, 0, -7), "lift": 0.0,
}
TAIL = {"aim": 0.0, "curl": 0.0, "flat": 90.0, "dir": (-0.2, -1.0, 0.15), "ripple": 8.0, "swing": 5.0, "wave": 5.0,
        "phase": 0.0, "level": 1.0, "trail": 0.0, "fall": 0.0}
FALL = (0.0, 0.0, -1.0)  # where an aimed tail's tip falls with 'fall' (her right, forward, up): straight down


class Take(rc.Take):
    """One clip being keyed from `start`, as rook_clips.Take, with the blades' tracks, the tail's and the root's."""

    def __init__(self, rig, feet, ctl, name, start, rest):
        super().__init__(rig, feet, name, start)
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in HUB.items()}
        self.ctl, self.rest, self.fresh = ctl, rest, True
        self.root_at, self.heading = (0.0, 0.0), 0.0
        self.props = {"R": [0.0, (0.0, 0.0, 0.0)], "L": [0.0, (0.0, 0.0, 0.0)], "tail": dict(TAIL)}
        self.stand_ins = []
        self.place(0)
        self.blade(0, "R")
        self.blade(0, "L")
        self.tail(0)

    def _hold(self, f, ease, values):
        frame = self.start + f
        for name, value in values.items():
            empty = self.ctl[name]
            empty.location = value
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *rc.EASE[ease])
        self.end = max(self.end, f)
        return self

    def place(self, f, at=None, heading=None, ease="hold"):
        """Keys where the HumanoidRootPart stands (a stage place) and its heading (degrees right of the stage's front),
        for the review: the game moves her root, the clip keys the body on it."""
        if at is not None:
            self.root_at = tuple(at)
        if heading is not None:
            self.heading = heading
        h = math.radians(self.heading)
        r6.place_root(self.rig, self.start + f, W(*self.root_at) + Vector((0, r6rig.ROOT_HEIGHT, 0)), W(math.sin(h), math.cos(h)))
        r6._set_interpolation(self.rig.root, self.start + f, *rc.EASE[ease])
        return self

    def world(self, at):
        """A floor place from her root (right, forward) as a stage place."""
        h, (r, fw) = math.radians(self.heading), at
        return (self.root_at[0] + r * math.cos(h) + fw * math.sin(h), self.root_at[1] - r * math.sin(h) + fw * math.cos(h))

    def ahead(self, right, forward, up=0.0):
        """A stage place from her root, with its height."""
        return (*self.world((right, forward)), up)

    def blade(self, f, side, ease=None, w=None, grip=None):
        """Keys a blade at clip frame `f`: w, how far it's in her fist (0 in its sheath, 1 in her hand); grip, its turn
        in the fist in degrees (pitch: the point toward the elbow, under 0 on past the fist along the arm's line;
        turn: round the forearm; roll: about its own length, turning the edge). What isn't named holds."""
        p = self.props[side]
        if w is not None:
            p[0] = w
        if grip is not None:
            p[1] = tuple(grip)
        return self._hold(f, ease, {f"blade{side}": (p[0], 0, 0), f"grip{side}": p[1]})

    def tail(self, f, ease=None, **changes):
        """Keys the tail at clip frame `f` (TAIL's names): aim, how far it turns toward `dir` (her right, forward, up)
        with `curl` holding the tip back and `flat` the band's width laid flat (0) or on edge (90); ripple and swing,
        the wave's degrees at the tip, `wave` its length in segments; level, how far its root keeps her heading over
        her lean (1) or rides her chest (0); trail, how far it follows the knot's own path; fall, how far an aimed
        tail's later segments bend toward FALL (growing to the tip), so a tail lifted in a wind arcs over like cloth
        instead of standing straight. The phase (cycles) is keyed linear whatever `ease` says, so the wave runs at an
        even speed between its keys."""
        p = self.props["tail"]
        p.update(changes)
        self._hold(f, ease, {"tailaim": (p["aim"], p["curl"], p["flat"]), "taildir": p["dir"],
                             "tailwave": (p["ripple"], p["swing"], p["wave"]), "tailmode": (p["level"], p["trail"], p["fall"])})
        if "phase" in changes or f == 0:  # keyed only where it's given, so it runs on evenly between
            self._hold(f, "lin", {"tailphase": (p["phase"], 0.0, 0.0)})
        return self

    def beat(self, f, label):
        self.beats.append((f, label))
        self.end = max(self.end, f)
        return self

    def key(self, f, label=None, ease=None, feet_ease=None, **changes):
        """Keys the body at clip frame `f`. `ease` shapes the move that starts here (`feet_ease` the feet's, when they
        step at their own pace). `label` puts it on the pose sheet. Changes: T (pitch, turn, roll, right, _, forward),
        feet {leg: (right, forward) from her root, or None for a leg given by its angles in RL / LL}, crouch, lift,
        look (a stage place) or H (angles), RA / LA (angles; ("reach", place, hint) for the hand; ("grip", side, hint)
        for the hand on a sheathed blade's grip)."""
        s, rig, frame = self.state, self.rig, self.start + f
        if self.fresh:  # HUB's feet are from her root, as the clip first places it
            s["feet"] = {leg: (self.world(at) if at is not None else None) for leg, at in s["feet"].items()}
            self.fresh = False
        if "feet" in changes:
            changes["feet"] = {**s["feet"], **{leg: (self.world(at) if at is not None else None) for leg, at in changes["feet"].items()}}
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
        floats = max((r6.sole(rig, leg) for leg in planted), default=0.0)
        if floats > 0.05:  # the sink ran out: the leg that reaches less can't get down to its place
            self.warned.append(f"{self.name} {f}: a planted foot floats {floats:.2f} over the floor")
        for leg, empty in self.feet.items():  # where each foot stands and how low she sits, for the pass between keys
            at = s["feet"][leg]
            if at is not None:
                empty.location.x, empty.location.y = at
            empty.location.z = s["crouch"]
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *rc.EASE[feet_ease or ease])
        self._hold(f, ease, {"lift": (0, 0, s["lift"])})
        self.keys.append((f, frozenset(planted)))
        out = {}
        if s.get("look") is not None:
            pitch, turn, tilt = r6.look(rig, W(*s["look"]), s["H"])
            out["Head"] = (max(-rc.NOD, min(rc.NOD, pitch)), turn, tilt)
        else:
            out["Head"] = s["H"]
        for arm in ("RA", "LA"):
            a = s[arm]
            if a[0] == "reach":
                out[rc.SHORT[arm]] = r6.reach(rig, rc.SHORT[arm], rc.HAND, W(*a[1]), a[2])
            elif a[0] == "grip":
                out[rc.SHORT[arm]] = r6.reach(rig, rc.SHORT[arm], rc.HAND, sheathed_grip(rig, self.rest, a[1]), a[2])
            else:
                out[rc.SHORT[arm]] = a
        r6._key_parts(rig, frame, out, *interp)
        self.solved = out  # the angles keyed, a reach's solved: for a breakdown that steers between it and its neighbour
        if label:
            self.beats.append((f, label))
        return self


    def arm(self, f, ease=None, **arms):
        """A breakdown for an arm alone at clip frame `f` (RA / LA angles), between two keys, so it goes the way it's
        sent: a joint takes the short way round, which from low to over the shoulder is backward, through her back.
        Call it in frame order between the keys it sits between; the body's state is left as the last key set it."""
        frame = self.start + f
        bpy.context.scene.frame_set(frame)
        r6._key_parts(self.rig, frame, {rc.SHORT[a]: v for a, v in arms.items()}, *rc.EASE[ease])
        return self


def sheathed_grip(rig, rest, side) -> Vector:
    """Where a sheathed blade's grip is now (Roblox world), riding the torso as it stands."""
    torso = r6.to_roblox(rig.parts["Torso"].matrix_world)
    return (torso @ rest["torso"].inverted() @ rest["blades"][SIDES[side][0]]["G"]).to_translation()


def body(turn, lean=0.0, roll=0.0, right=0.0, up=0.0, forward=0.0) -> tuple:
    """A torso pose (T) turned first and leant in its own frame: R6's root angles are pitch, then turn, then roll in
    the root's frame, so a lean on a body turned far round would tip it sideways. Turn to her left, lean forward,
    roll her left side down (all degrees); right, up, forward in studs."""
    m = (Matrix.Rotation(math.radians(turn), 3, "Y") @ Matrix.Rotation(math.radians(-lean), 3, "X")
         @ Matrix.Rotation(math.radians(roll), 3, "Z"))
    e = m.to_euler("ZYX")
    return (-math.degrees(e.x), math.degrees(e.y), math.degrees(e.z), right, up, forward)


# --- the props: the blades and the tail, solved on every frame -------------------------------------------------------

def share(q: Quaternion, w: float) -> Quaternion:
    """`w` of the turn `q` (past 1 or under 0, it goes on the same way or back)."""
    q = q.copy()
    if q.w < 0:
        q.negate()
    axis, angle = q.to_axis_angle()
    return Quaternion(axis, angle * w)


def reference(d: Vector, flat: float, right: Vector) -> Vector:
    """The way the band's width lies across a line along `d`: flat (0) or on edge (90)."""
    h = UP.cross(d)
    if h.length < 1e-3:
        h = right.copy()
    h.normalize()
    a = math.radians(flat)
    return h * math.cos(a) + d.cross(h) * math.sin(a)


def roll_to(a: Vector, d: Vector, ref: Vector) -> float:
    """The turn about `d` (radians, within a quarter) that lays `a` along `ref` or against it: a band has no up."""
    a = a - d * a.dot(d)
    if a.length < 1e-4:
        return 0.0
    a.normalize()
    th = math.atan2(d.dot(a.cross(ref)), a.dot(ref))
    if th > math.pi / 2:
        th -= math.pi
    elif th < -math.pi / 2:
        th += math.pi
    return th


def held_down(e: Vector, start: Vector, back: Vector) -> Vector:
    """A chord `e` from `start` turned up just enough that its end stays over the floor."""
    need = FLOOR - start.y
    if e.y >= need:
        return e
    flat = Vector((e.x, 0.0, e.z))
    if flat.length < 1e-4:
        flat = back.copy()
    flat.normalize()
    y = max(-1.0, min(1.0, need / e.length))
    return (flat * math.sqrt(1 - y * y) + Vector((0, y, 0))) * e.length


def path_at(path, t, loop):
    span = len(path) - 1
    if loop:
        t %= span
    t = max(0.0, min(span, t))
    i = min(int(t), span - 1)
    return path[i].lerp(path[i + 1], t - i)


def solve_tail(rest, base, knot, v, q_root, trail_dir=None, dirs=None):
    """The chain's turns (each joint's own, root to tip) and its points, from the tail's numbers at a frame. `dirs`:
    each link's way (Roblox world), as the follow-through gives them, in place of the numbers' aim and wave."""
    tail = rest["tail"]
    aim, curl, flat = v["tailaim"]
    ripple, swing, wave = v["tailwave"]
    level, trail, fall = v["tailmode"]
    phase = v["tailphase"][0]
    right, back = q_root @ Vector((1, 0, 0)), q_root @ Vector((0, 0, 1))
    d = q_root @ W(*v["taildir"])
    d = d.normalized() if d.length > 1e-6 else back
    falls = q_root @ W(*FALL)
    parent, P = base, knot.copy()
    turns, points = [], [P.copy()]
    for k in range(LINKS):
        c = tail["chords"][k]
        dk = (d + falls * fall * k / (LINKS - 1)).normalized() if fall > 1e-3 else d
        if trail > 1e-3 and trail_dir is not None and dirs is None:
            td = trail_dir(k, P)
            if td is not None:
                dk = (d * (1 - trail) + td * trail).normalized()
        if dirs is not None:
            dk = dirs[k]
        e = held_down(dk * tail["lengths"][k], P, back)  # the aim keeps over the floor too
        dk = e.normalized()
        q_min = (parent @ c).rotation_difference(dk)
        # the first link lies as the keys say; under the follow-through each later one carries on from the last with
        # the least twist, as cloth does, so no link turns its underside up between two that show their top
        th = 0.0 if dirs is not None and k else roll_to(q_min @ (parent @ tail["across"][k]), dk, reference(dk, flat, right))
        aimed = parent.inverted() @ (Quaternion(dk, th) @ q_min @ parent)
        if dirs is not None:
            R = aimed
        else:
            w = math.copysign(abs(aim) ** (1 + curl * k / (LINKS - 1)), aim)
            g = 0.45 + 0.55 * k / (LINKS - 1)
            s = 2 * math.pi * (phase - k / max(wave, 0.5))
            R = (share(aimed, w) @ Quaternion(tail["across"][k], math.radians(ripple * g * math.sin(s)))
                 @ Quaternion(tail["normal"][k], math.radians(swing * g * math.cos(s))))
        turned = 2 * math.acos(min(1.0, abs(R.w)))
        if k and turned > BEND:  # held to the seams' bend: a tighter curve is spread, not kinked
            R = share(R, BEND / turned)
        q = parent @ R
        e = q @ c
        lifted = held_down(e, P, back)
        if lifted is not e:  # the floor stops it
            q = e.rotation_difference(lifted) @ q
            R = parent.inverted() @ q
            e = lifted
        turns.append(R)
        P = P + e
        points.append(P.copy())
        parent = q
    return turns, points


SUB = 4                 # the follow-through's steps a frame
GRAVITY = 196.2         # studs a second squared, the game's own
DRAG = 0.08             # of its speed the cloth loses each step
PULL_ROOT, PULL_TIP = 0.2, 0.006   # how much of the way to its pose a link's end moves each step, root and tip


def follow(targets, loop, lengths):
    """The cloth's points through a clip: `targets`, each frame's posed points (Roblox world, the knot first), chased
    under gravity and drag and held to the links' lengths. A loop is run twice, so its start carries its end's motion."""
    n, links = len(targets), len(lengths)
    pulls = [PULL_ROOT + (PULL_TIP - PULL_ROOT) * (k / (links - 1)) ** 0.7 for k in range(links)]
    h = 1.0 / (FPS * SUB)
    fall = Vector((0, -GRAVITY * h * h, 0))
    now = [q.copy() for q in targets[0]]
    last = [q.copy() for q in now]
    out = [None] * n
    for lap in range(2 if loop else 1):
        for f in range(n):
            a, b = targets[f - 1 if f else (n - 1 if loop and lap else 0)], targets[f]
            for s in range(1, SUB + 1):
                u = s / SUB
                goal = [p.lerp(q, u) for p, q in zip(a, b)]
                now[0] = goal[0]
                for k in range(1, links + 1):
                    speed = (now[k] - last[k]) * (1 - DRAG)
                    last[k] = now[k].copy()
                    now[k] = now[k] + speed + fall
                    now[k] = now[k] + (goal[k] - now[k]) * pulls[k - 1]
                for _ in range(3):
                    for k in range(1, links + 1):
                        d = now[k] - now[k - 1]
                        now[k] = now[k - 1] + d.normalized() * lengths[k - 1] if d.length > 1e-6 else goal[k].copy()
                        if now[k].y < FLOOR:
                            now[k].y = FLOOR
            out[f] = [q.copy() for q in now]
    return out


def clear(point, part, frame) -> float:
    """How far a point is outside a body's box, in studs; negative is inside."""
    centre, half = BOXES[part]
    d = np.abs(np.array((frame.inverted() @ point)[:]) - np.array(centre)) - np.array(half)
    out = float(np.linalg.norm(np.maximum(d, 0)))
    return out if out > 0 else float(d.max())


def props(rig, ctl, motors, rest, takes) -> dict:
    """The last pass, once the body is keyed on every frame: each blade's joint solved to its sheath or her fist, and
    the tail's eight. Both are keyed on every frame. Returns each clip's numbers."""
    scene, facts = bpy.context.scene, {}
    torso_rest = rest["torso"].inverted()
    for take in takes:
        n = take.end + 1
        samples = []
        for f in range(n):
            scene.frame_set(take.start + f)
            samples.append({"T": r6.to_roblox(rig.parts["Torso"].matrix_world).copy(),
                            "root": r6.to_roblox(rig.root.matrix_world).copy(),
                            "hands": {s: r6.hand(rig, arm).copy() for s, (_, arm) in SIDES.items()},
                            "c0": {name: r6.to_roblox(motors[name].matrix_world).copy() for name in (*(b for b, _ in SIDES.values()), SCARF[0])},
                            "parts": {p: r6.to_roblox(rig.parts[p].matrix_world).copy() for p in BOXES},
                            "v": {name: tuple(e.location) for name, e in ctl.items()}})
        path = [s["c0"][SCARF[0]].to_translation() for s in samples]
        low, bend, tail_near = (9.0, 0), (0.0, 0, 0), {p: (9.0, 0) for p in BOXES}
        blade_near = {side: {p: (9.0, 0) for p in BOXES if p != arm} for side, (_, arm) in SIDES.items()}
        sheathed = 9.0
        for f, S in enumerate(samples):
            frame, v, keys = take.start + f, S["v"], {}
            moved = S["T"] @ torso_rest
            for side, (name, arm) in SIDES.items():
                w = max(0.0, min(1.0, v[f"blade{side}"][0]))
                pitch, turn, roll = v[f"grip{side}"]
                stowed = moved @ rest["blades"][name]["G"]
                held = (S["hands"][side] @ Matrix.Rotation(math.radians(turn), 4, "Z") @ Matrix.Rotation(math.radians(pitch), 4, "X")
                        @ Matrix.Rotation(math.radians(roll), 4, "Y"))
                qs, qh = stowed.to_quaternion(), held.to_quaternion()
                if qs.dot(qh) < 0:
                    qh.negate()
                near = max(0.0, min(1.0, 1.0 - (held.to_translation() - stowed.to_translation()).length / NEAR))
                qh = qh.slerp(qs, near * near * (3 - 2 * near))  # by the sheath, the point lines up with its mouth
                q = qs.slerp(qh, w)
                out = stowed.to_3x3() @ Vector((0, -PULL * math.sin(math.pi * w), 0))  # up its line, clear of her head
                G = Matrix.Translation(stowed.to_translation().lerp(held.to_translation(), w) + out) @ q.to_matrix().to_4x4()
                J = G @ rest["blades"][name]["G"].inverted() @ rest["blades"][name]["J"]
                keys[name] = r6.to_blender(S["c0"][name].inverted() @ J)
                if w > 0.05:  # out of its sheath: the draw and the sheathing too
                    for y in STEEL:
                        point = G @ Vector((0, y, 0))
                        for part in blade_near[side]:
                            blade_near[side][part] = min(blade_near[side][part], (clear(point, part, S["parts"][part]) - EDGE, f))
                else:  # in it: what the head's box reads against a blade that's home (the box is wider than her hair)
                    sheathed = min(sheathed, min(clear(G @ Vector((0, y, 0)), "Head", S["parts"]["Head"]) - EDGE for y in STEEL))
            q_root = S["root"].to_quaternion()
            base = moved.to_quaternion().slerp(q_root, max(0.0, min(1.0, v["tailmode"][0])))
            search = {"t": float(f)}

            def trail_dir(k, P, search=search, f=f):
                L, t = rest["tail"]["lengths"][k], search["t"]
                for _ in range(1600):
                    t -= 0.25
                    if not take.loop and t < 0:
                        return None
                    q = path_at(path, t, take.loop)
                    if (q - P).length >= L:
                        search["t"] = t
                        return (q - P).normalized()
                return None

            S["tail"] = (base, q_root, solve_tail(rest, base, path[f], v, q_root, trail_dir)[1])
            S["keys"] = keys
        # the follow-through: the tail as posed is where the cloth is pulled to, and the cloth chases it, its root
        # closely, its tip late, under its own weight, so it lags the body and settles after it (research, AR60)
        chased = follow([S["tail"][2] for S in samples], take.loop, rest["tail"]["lengths"])
        for f, S in enumerate(samples):
            frame, v, keys = take.start + f, S["v"], S["keys"]
            base, q_root, _ = S["tail"]
            pts = chased[f]
            dirs = [(b - a).normalized() for a, b in zip(pts, pts[1:])]
            turns, points = solve_tail(rest, base, path[f], v, q_root, dirs=dirs)
            c0 = S["c0"][SCARF[0]].to_quaternion()
            for k, R in enumerate(turns):
                local = (c0.inverted() @ base @ R) if k == 0 else R
                keys[SCARF[k]] = r6.to_blender(local.to_matrix().to_4x4())
                if k:
                    bend = max(bend, (math.degrees(2 * math.acos(min(1.0, abs(R.w)))), f, k + 1))
            for i, P in enumerate(points):
                low = min(low, (P.y, f))
            for a, b in zip(points[1:-1], points[2:]):
                for point in (a, (a + b) / 2):
                    if (point - points[0]).length < 1.0:
                        continue
                    for part in BOXES:
                        tail_near[part] = min(tail_near[part], (clear(point, part, S["parts"][part]) - 0.05, f))
            r6.key_matrices(rig, frame, keys)
        facts[take.name] = {"low": low, "bend": bend, "tail_near": tail_near, "blade_near": blade_near, "sheathed": sheathed}
    return facts


def audit(rig, take) -> dict:
    """What the content check asks of every clip, as numbers: each leg's widest swing, the longest an arm stays nearly
    still between 20 and 70 degrees over level (a raised arm held is a salute on the bare rig), and the highest each
    arm goes."""
    scene = bpy.context.scene
    swing, held, run, last = (0.0, 0), {"Right Arm": (0, 0), "Left Arm": (0, 0)}, {"Right Arm": 0, "Left Arm": 0}, {}
    high = {"Right Arm": (-90.0, 0), "Left Arm": (-90.0, 0)}
    for f in range(take.end + 1):
        scene.frame_set(take.start + f)
        for leg in r6.LEGS:
            p = r6.pose_of(rig, leg)
            swing = max(swing, (max(abs(p[0]), abs(p[2])), f))
        for arm in held:
            along = (r6.to_roblox(rig.parts[arm].matrix_world).to_3x3() @ Vector((0, -1, 0))).normalized()
            up = math.degrees(math.asin(max(-1, min(1, along.y))))
            still = arm in last and math.degrees(along.angle(last[arm], 0.0)) * FPS < STILL
            last[arm] = along
            run[arm] = run[arm] + 1 if still and 20.0 < up < 70.0 else 0
            held[arm] = max(held[arm], (run[arm], f))
            high[arm] = max(high[arm], (up, f))
    return {"swing": swing, "held": held, "high": high}


# --- the clips ------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses. Her stance is the sheet's: weight forward on the balls of
# her feet, one foot well ahead, the left hand at the satchel, the right loose by her grip. R6's arm is straight and
# its shoulder sits a stud from the grip, so no hand can hold a sheathed grip without the arm going into her head or
# chest. A draw is the arm raised straight up and a little back (RAISED, LIFTED), never tipped in over her head, and
# the blade slides up its sheath's line into the fist, which is where that line runs; a sheathing is the same, back
# down it. A raised arm is up 74 degrees over level, out of the salute line's band, and an arm sent from low to raised
# goes up in front of her (Take.arm's breakdowns), never back through her. The left arm never rolls toward the body
# (its roll stays at or under 0). The blades come out for the Combo, Scarf Step and the Reveal's turn.
RAISED, LIFTED = (195, 0, 6), (195, 0, -6)  # the right arm and the left, raised to draw or sheathe

LEVEL = -2.0  # degrees of head tilt against her stance's turn and lean, so the idle's head reads level (AR27; idle_head.py)


def idle(t):
    """She can't stand still: up on the balls of her feet, a small bounce twice a breath, her head level and on
    what's next through the whole loop (AR27: no glance). The tail never stops: a slow wave runs down it all the
    time, and once a loop it lifts a little, a flag in her own wind."""
    t.loop = True
    t.key(0, "the stance", ease="sine", look=EYES, H=(0, 0, LEVEL))  # the head counter-tilted against her stance's lean
    t.key(30, "up on her toes", ease="sine", T=(10, -9, 0), crouch=0.04, RA=(12, 0, 10), LA=(-19, 0, -8))
    t.key(60, ease="sine", T=(13, -10, 0), crouch=0.14, RA=(18, 0, 8), LA=(-23, 0, -7))
    t.key(90, ease="sine", T=(10, -11, 0), crouch=0.05, RA=(13, 0, 11))
    t.key(120, ease="sine", T=(12, -10, 0), crouch=0.13, RA=(16, 0, 9), LA=(-22, 0, -7))
    t.key(150, ease="sine", T=(10, -9, 0), crouch=0.06, RA=(12, 0, 11))
    t.key(182, ease="sine", T=(12, -10, 0), crouch=0.13, RA=(17, 0, 9))
    t.key(212, ease="sine", T=(10, -9, 0), crouch=0.05)
    t.key(240, T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])
    t.tail(0, phase=0.0)
    t.tail(150, ease="sine")
    t.tail(166, ease="sine", ripple=11.0, swing=7.0)  # it lifts a little, a flag in her own wind
    t.tail(200, ease="sine", ripple=TAIL["ripple"], swing=TAIL["swing"])
    t.tail(240, phase=2.0)


def combo(t):
    """The dash is the first cut. She comes in low and fast with her right hand already over her shoulder on the grip,
    and the draw is the cut, down across the Shade from her right shoulder. The left blade comes out the other way, so
    she cuts the X she wears. Then both blades low behind her, and she springs up through the Shade in a rising double
    cut, puts both back over her shoulders in one move, and lands low and ready. The tail streams behind the dash,
    whips the other way with each cut, and floats down to its S as she sheathes."""
    shade = (*SHADE, 3.3)
    t.place(0, at=(0.0, -4.0), ease="out")
    t.place(9, at=(0.0, 0.0))
    for side in "RL":
        t.blade(0, side, grip=(-40, 0, 0))
    t.key(0, "the dash", T=(32, -12, 0), crouch=0.26, look=shade, H=(0, 0, 0), feet={"Right Leg": None, "Left Leg": None},
          RL=(42, 0, 2), LL=(-36, 0, -2), RA=(160, 0, 12), LA=(-46, 0, -14))
    t.mark(0, "Dash")
    t.key(5, ease="lin", T=(30, -20, 0), lift=0.22, RL=(48, 0, 2), LL=(-44, 0, -2), RA=RAISED, LA=(-54, 0, -18))
    t.key(9, "on the grip, in", ease="in", T=(26, -28, 0), crouch=0.32, lift=0.0, feet={"Right Leg": (0.75, 0.3), "Left Leg": (-0.8, -0.95)},
          LA=(-30, 0, -24))
    t.blade(9, "R", ease="out")
    t.blade(11, "R", w=1.0)
    t.key(12, "1: the draw is the cut", T=(22, 24, 0, 0, 0, 0.15), RA=(46, 0, 6), LA=(-12, 0, -30))
    t.mark(12, "Hit1")
    t.arm(14, ease="out", LA=(96, 0, -18))  # the left goes up in front of her, to its grip
    t.key(16, ease="out", T=(22, 32, 0, 0, 0, 0.12), RA=(22, 0, 10), LA=LIFTED)
    t.blade(20, "L", ease="out")
    t.key(21, "the left on its grip", ease="in", T=(22, 36, 0, 0, 0, 0.1), RA=(14, 0, 18))
    t.blade(23, "L", w=1.0)
    t.key(26, "2: the X", T=(22, -26, 0, 0, 0, 0.16), LA=(48, 0, -6), RA=(-8, 0, 30),
          feet={"Right Leg": (1.0, 0.3)})  # her right foot steps out into the twist, so the legs don't cross
    t.mark(26, "Hit2")
    t.key(31, ease="out", T=(20, -32, 0, 0, 0, 0.12), LA=(22, 0, -14), RA=(-16, 0, 32))
    t.key(44, "both low behind her", ease="in", T=(36, -4, 0, 0, 0, -0.05), crouch=0.44, RA=(-50, 0, 22), LA=(-50, 0, -22))
    t.key(56, "3: up through it", T=(-6, 0, 0, 0, 0, 0.25), crouch=0.0, lift=0.34, RA=(112, 0, 14), LA=(112, 0, -14))
    t.mark(56, "Hit3")
    t.key(61, "over the shoulders", ease="out", T=(-8, -2, 0, 0, 0, 0.2), lift=0.14, RA=RAISED, LA=LIFTED)
    for side in "RL":
        t.blade(61, side, ease="in")
        t.blade(64, side, w=0.0)
    t.mark(64, "Sheathe")
    t.arm(64, ease="in", RA=RAISED, LA=LIFTED)  # raised till the blades are home
    t.arm(66, ease="out", RA=(128, 0, 18), LA=(128, 0, -18))  # then down in front of her, off the grips
    t.key(70, ease="out", T=(20, -8, 0), crouch=0.3, lift=0.0, RA=(22, 0, 14), LA=(-14, 0, -12))
    t.key(84, "low and ready", ease="sine", T=(18, -12, 0), crouch=0.22, RA=(18, 0, 10), LA=(-22, 0, -8))
    t.key(100, T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"], feet=HUB["feet"])
    t.tail(0, aim=0.85, curl=0.6, dir=(-0.15, -1.0, 0.12), ripple=11.0, swing=6.0, wave=4.0, phase=0.0)
    t.tail(9, ease="out", aim=0.6, dir=(-0.85, -0.35, 0.45), phase=2.0)  # she stops; it doesn't, out past her left
    t.tail(13, ease="out", aim=0.55, dir=(0.55, -0.8, 0.3))  # the cut throws it to her right
    t.tail(25, ease="out")  # held there while her left arm is up for its grip and on its way down
    t.tail(31, ease="out", aim=0.55, dir=(-0.85, -0.45, 0.25))  # and the X whips it back to her left, a beat behind
    t.tail(44, ease="sine", aim=0.4, dir=(-0.3, -0.9, -0.05))
    t.tail(57, ease="out", aim=0.75, dir=(-0.2, -0.85, -0.35), phase=5.0)  # it streams down as she goes up
    t.tail(64, ease="out", aim=0.6, dir=(0.1, -0.7, 0.7))  # and flicks up behind her as she comes down, off her raised arm
    t.tail(72, ease="back")
    t.tail(92, aim=0.0, curl=1.0, ripple=TAIL["ripple"], swing=TAIL["swing"], wave=TAIL["wave"])
    t.tail(100, phase=6.0)
    t.stand_ins.append(("shade", SHADE))


def scarf_step(t):
    """She sets, low, her right hand to the grip, and blinks out. She's through the Shade before you see her move: she
    lands behind it already turned to face it, sliding on her line, the blade trailing low from the cut, the other hand
    reaching back at it, and the scarf runs from her neck in one straight line back through the Shade, toward where she
    was. A beat; then the line lets go from the tip, curls into its S past where it rests, settles, and the blade goes
    home. The blink is the game's: her root jumps in the review at Blink, the clip keys her body on it."""
    a = math.radians(STEP)
    u = (math.sin(a), math.cos(a))
    shade = (u[0] * GONE, u[1] * GONE)
    land = (u[0] * (GONE + ks.PAST), u[1] * (GONE + ks.PAST))
    at_shade = (*shade, 3.0)
    t.place(0, at=(0.0, 0.0), heading=STEP)
    t.key(0, "the stance", look=at_shade, H=(0, 0, 0))
    t.arm(4, ease="cubic", RA=(104, 0, 14))  # up in front of her to the grip
    t.key(8, "sets", ease="cubic", T=(28, -22, 0), crouch=0.34, feet={"Right Leg": (0.74, 0.2), "Left Leg": (-0.76, -0.95)},
          RA=RAISED, LA=(40, 0, -12))
    t.key(12, ease="in", T=(34, -24, 0, 0, 0, 0.12), crouch=0.4, LA=(46, 0, -10))
    t.key(13, ease="hold", T=(38, -24, 0, 0, 0, 0.3), feet={"Right Leg": None, "Left Leg": None}, RL=(34, 0, 2), LL=(-30, 0, -2))
    t.mark(13, "Blink")
    # out of the back of her fist and down, so it trails behind her clear of her legs: out of its sheath while she's
    # gone, in her hand as she lands
    t.blade(13, "R", ease="hold", grip=(-30, 180, 0))
    t.blade(14, "R", w=1.0)
    t.arm(13, ease="lin", RA=RAISED)  # the arm goes on through the blink, not in one frame on landing
    t.place(14, at=land, heading=STEP + 180.0)
    t.key(15, ease="out", T=(34, 16, -6, 0, 0, 0.3), crouch=0.44, look=at_shade, RL=(40, 0, 4), LL=(-50, 0, -4),
          RA=(-58, 0, 26), LA=(56, 0, -16))
    t.key(16, "past it, facing it", ease="out", T=(30, 14, -6, 0, 0, 0.15), crouch=0.32,
          feet={"Right Leg": (0.62, 0.6), "Left Leg": (-0.5, -1.2)}, RA=(-56, 0, 24), LA=(60, 0, -14))
    t.mark(16, "Land")
    t.mark(18, "Cut")
    t.key(24, ease="sine", T=(28, 12, -5, 0, 0, 0.1), crouch=0.36)
    t.key(40, "the line holds", ease="sine", T=(24, 10, -4, 0, 0, 0.05), crouch=0.32, RA=(-48, 0, 30), LA=(52, 0, -14))
    t.key(54, "it lets go", ease="sine", T=(20, 6, -2), crouch=0.26, RA=(-42, 0, 40), LA=(30, 0, -12))  # the arm stays back: the blade clear of her leg
    t.arm(58, ease="in", RA=(74, 0, 26))  # the blade comes up in front of her, not back through her
    t.key(62, ease="in", T=(18, 0, 0), crouch=0.22, RA=RAISED, LA=(4, 0, -12))
    t.blade(62, "R", ease="in")
    t.blade(64, "R", w=0.0)
    t.arm(64, ease="in", RA=RAISED)  # raised till it's home
    t.arm(66, ease="out", RA=(120, 0, 16))  # then off the grip, down in front
    t.key(68, "home", ease="out", T=(16, -6, 0), crouch=0.2, RA=(20, 0, 12))
    t.key(96, ease="sine", T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"], feet=HUB["feet"])
    knot_to_shade = (0.72 / (GONE + ks.PAST - GONE), 1.0, -0.12)  # from the knot at her left, through the Shade's chest
    t.tail(0, phase=0.0)
    t.tail(8, ease="sine", aim=0.45, dir=(-0.3, -1.0, 0.1), ripple=10.0, phase=1.2)  # it streams back as she sets
    t.tail(13, ease="hold", aim=0.45, curl=2.0)
    t.tail(14, ease="hold", aim=1.0, dir=knot_to_shade, flat=90.0, ripple=0.0, swing=0.0, phase=1.6)  # the line
    t.tail(44, ease="back", phase=1.6)  # it lets go from the tip, and the ease carries it past its S and back
    t.tail(70, ease="sine", aim=0.0, ripple=TAIL["ripple"], swing=TAIL["swing"])
    t.tail(90, curl=0.0)
    t.tail(96, phase=4.0)
    t.stand_ins.append(("shade", shade))


def reveal(t):
    """A blue streak comes down out of the shard before she does: she lands on it low, the scarf still streaming up
    from her drop, and rises as it floats down into its S. She reaches back, draws the right blade, turns it once in her
    fist down by her side, puts it home over her shoulder as her name lands, and looks at you."""
    you = (6.0, 8.5, 4.6)  # the reveal's camera, out front and to her right
    t.key(0, "it comes down", T=(6, 0, 0), crouch=0.0, lift=4.6, feet={"Right Leg": None, "Left Leg": None},
          RL=(28, 0, 4), LL=(-8, 0, -4), H=(26, 0, 0), RA=(30, 0, 64), LA=(30, 0, -64))
    t.key(14, "lands", ease="in", T=(38, -6, 0), crouch=0.52, lift=0.0, feet={"Right Leg": (0.62, 0.45), "Left Leg": (-0.72, -0.35)},
          H=(22, 0, 0), RA=(-38, 0, 34), LA=(28, 0, -22))
    t.mark(14, "Land")
    t.key(20, ease="out", T=(42, -6, 0), crouch=0.58, RA=(-46, 0, 38), LA=(20, 0, -24))
    t.key(36, "and rises", ease="sine", T=(12, -8, 0), crouch=0.14, look=you, H=(0, 0, 0), RA=(14, 0, 12), LA=(-20, 0, -8))
    t.key(52, ease="sine", T=(10, -10, 0), crouch=0.1, LA=(-22, 0, -7))
    t.arm(56, ease="in", RA=(104, 0, 14))  # up in front of her
    t.key(60, "reaches back", ease="in", T=(6, -16, 0), RA=RAISED)
    t.blade(60, "R", grip=(-20, 0, 0))
    t.blade(61, "R", ease="out")
    t.blade(64, "R", w=1.0)
    t.arm(63, RA=(150, 0, 30))  # out to her side as it comes down, clear of her chest
    t.key(66, ease="out", T=(8, -14, 0), RA=(50, 0, 44))
    t.key(72, "turns it once", ease="sine", T=(8, -12, 0), RA=(24, 0, 48))
    t.blade(72, "R", ease="lin")
    t.blade(86, "R", grip=(-20, 360, 0))  # once round her forearm in her fist, out at her side
    t.key(86, ease="sine", T=(8, -12, 0), RA=(28, 0, 46))
    t.arm(90, ease="in", RA=(112, 0, 28))
    t.key(94, ease="in", T=(6, -16, 0), RA=RAISED)
    t.blade(94, "R", ease="in")
    t.blade(96, "R", w=0.0)
    t.arm(96, ease="in", RA=RAISED)  # raised till it's home
    t.arm(98, ease="out", RA=(118, 0, 14))  # then off the grip, down in front
    t.key(100, "and home, for her name", ease="out", T=(10, -10, 0), crouch=0.1, RA=(16, 0, 10), H=(0, 0, -6), look=you)
    t.mark(100, "Name")
    t.key(150, T=(11, -10, 0), crouch=0.12)
    t.tail(0, aim=0.9, curl=0.8, dir=(0.1, -0.4, 1.0), ripple=12.0, swing=6.0, wave=4.0, phase=0.0)  # up and back, off her head
    t.tail(14, ease="sine", phase=1.6)
    t.tail(30, ease="sine", aim=0.7, curl=0.4, dir=(-0.4, -1.0, 0.35), fall=1.2)   # landed: its weight takes it over
    # it settles lifted behind her left shoulder, up into your view of her (hanging as it rests, it'd be hidden behind
    # her), and clear of the right shoulder her hand draws from: cloth in a wind, rising and arcing over, its tip
    # falling back (research's fix: a straight one read as a pennant or a blade)
    t.tail(62, aim=0.85, curl=0.3, dir=(-0.85, -0.35, 0.75), fall=1.8, ripple=16.0, swing=8.0, wave=3.5)
    t.tail(150, phase=4.0)


def work(t):
    """A shift at the bay as a courier works one: she runs laps of the post, slapping it with her right palm as she
    passes, and the scarf trails her round it, a blue ring wound on the post while she runs. It loops on two laps.
    The laps are the clip's (her torso goes round on the root), so the game keeps her root where it stands."""
    t.loop = True
    # short quick steps, nine a lap: a planted foot sweeps an arc round the post, which bends in toward it at both ends,
    # so a long step on so tight a circle tips the outer leg in under her (seven a lap crossed her legs)
    post, radius, lap, steps, laps = (0.3, 3.0), 2.0, 108, 9, 2
    beat, lean, roll = lap // steps, 14.0, -8.0
    half = 180.0 / steps  # at each key the new foot is half a step ahead of its hip, the other half a step behind its own
    back = math.sin(math.radians(lean))  # the lean carries her hips back of her torso's middle
    # and leaning into the turn carries her legs out from the post: in line with her lean, a foot three studs under her
    # torso's middle is this far out of it
    out = 3.0 * math.sin(math.radians(-roll))

    def at(phi, r=radius):
        return (post[0] + r * math.cos(math.radians(phi)), post[1] + r * math.sin(math.radians(phi)))

    labels = {0: "laps of the post", 3: "a slap as she passes", 5: "on round"}
    lands = {}  # each footfall: the leg, its line's radius, and its angle round the post
    for i in range(-2, laps * steps + 2):
        phi = -90.0 - 360.0 * i / steps  # her place round the post, clockwise from in front of her root
        side = "Right Leg" if i % 2 == 0 else "Left Leg"
        r = radius + out + (-0.5 if side == "Right Leg" else 0.72)  # the inner line or the outer, the outer's steps longer
        lands[i] = (side, r, phi - half + math.degrees(back / r))
    # keyed a step past each end, so the path is a smooth circle through the loop's seam and the arms swing on curves
    for i in range(-1, laps * steps + 2):
        phi = -90.0 - 360.0 * i / steps
        x, y = at(phi)
        turn = 90.0 - 360.0 * i / steps
        side, r, a = lands[i]
        other, r0, a0 = lands[i - 1]
        place, before = at(a, r), at(a0, r0)
        right_step = i % 2 == 0
        slap = i % steps == 3
        # the right arm swings a little wide: she leans into the post, so a hanging arm tips toward her right leg
        arms = dict(RA=(-34, 0, 18) if right_step else (40, 0, 14), LA=(42, 0, -8) if right_step else (-36, 0, -12))
        if slap:  # the flat of her palm on the post's cap, ahead, as she goes by: swung forward to it, not out sideways
            arms["RA"] = ("reach", (*at(phi - 24.0, 0.2), 3.0), (50, 0, 40))
        t.key(i * beat, labels.get(i % steps) if 0 <= i < steps else None, feet_ease="sine",
              T=body(turn, lean=lean, roll=roll, right=x, forward=y), crouch=0.16,
              feet={side: place, other: before}, H=(4, -12, 0), **arms)
        if slap:  # half-way poses to and from the post, so the arm swings there and back without twisting into her side
            hit = t.solved["Right Arm"]
            nxt = (40, 0, 14) if right_step else (-34, 0, 18)
            t.arm(i * beat - beat // 2, RA=tuple((p + q) / 2 for p, q in zip(nxt, hit)))
            t.arm(i * beat + beat // 2, RA=tuple((p + q) / 2 for p, q in zip(hit, nxt)))
    # the foot stepping between key i and the next goes round its own line, keyed on every frame of the step: eased
    # straight between its footfalls it would cut the chord, two steps of arc, about a stud in at the outer line and
    # through her other leg
    for i in range(-1, laps * steps + 1):
        leg, r, a0 = lands[i - 1]
        a1 = lands[i + 1][2]
        empty = t.feet[leg]
        for k in range(1, beat):
            s = (1.0 - math.cos(math.pi * k / beat)) / 2.0  # the feet's sine ease
            empty.location.x, empty.location.y = t.world(at(a0 + (a1 - a0) * s, r))
            for axis in (0, 1):
                empty.keyframe_insert("location", index=axis, frame=t.start + i * beat + k)
    t.end = laps * lap
    t.mark(3 * beat, "Pump")
    t.mark((steps + 3) * beat, "Pump")
    t.tail(0, aim=1.0, trail=1.0, level=1.0, flat=90.0, ripple=6.0, swing=3.0, wave=4.0, phase=0.0)
    t.tail(laps * lap, phase=8.0)
    t.stand_ins.append(("post", post))


# Her own reactions (AR66, research's pick of 2026-11-26, 17:32: Hit A, and the A pair), in place of the open set's,
# which leaned on Rook's ram. Each keeps the open set's length and marker: Hit 19 frames, Down 67 with Land at 34, Up
# 55, and the Up starts where the Down lies. Her blades stay sheathed; the tail is keyed with the body.
LOOSE = {"Right Leg": None, "Left Leg": None}  # off the floor: the feet go where the legs put them
def hit(t):
    """The blow lands high and she's light: her head and shoulders snap back and round, her arms fly loose, and the
    scarf goes on forward over her shoulder. Her feet never move, and she's back on it before the scarf is."""
    t.key(0, "stance", ease="out")
    t.key(3, "struck", ease="out", T=(-16, -18, 0), crouch=0.04, H=(-28, 18, 10), RA=(46, 0, 58), LA=(30, 0, -64))
    t.key(7, ease="sine", T=(-12, -15, 0), H=(-14, 16, 6), RA=(30, 0, 46), LA=(14, 0, -50))   # the legs uncrossed
    t.key(12, "back on it", ease="sine", T=(18, -6, 0), crouch=0.2, look=EYES, H=(0, 0, 0), RA=(20, 0, 14), LA=(-28, 0, -10))
    t.key(18, "settled", T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])
    t.tail(0, phase=0.0)
    t.tail(4, "sine", aim=0.55, curl=0.5, dir=(-0.5, 0.6, 0.6), ripple=14.0, swing=8.0, fall=0.4, phase=0.7)
    t.tail(18, None, aim=0.0, curl=0.0, ripple=TAIL["ripple"], swing=TAIL["swing"], fall=0.0, phase=1.5)
    t.stand_ins.append(("shade", SHADE))



LYING = dict(T=(-88, -4, 0, 0, 0, -1.6), feet=LOOSE, RL=(2, 0, 8), LL=(20, 0, -8), crouch=0.0, lift=0.12, H=(24, 16, 0),
               RA=(8, 0, 80), LA=(28, 0, -34))



def down(t):
    """The blow takes her feet. She goes over light, turns in the air and slaps the street with her arm as she comes
    down on her side, rolls flat, and the scarf comes down over her last."""
    t.key(0, ease="out")
    t.arm(2, "sine", LA=(6, 0, -34))   # her left arm flung out first, clear of her side as she turns
    t.key(5, "the blow", ease="in", T=(-22, -20, 3), crouch=0.04, H=(-30, 12, 6), RA=(50, 0, 60), LA=(36, 0, -64))
    t.key(16, "off her feet", T=(-48, -40, 18, 0, 0, -1.0), feet=LOOSE, RL=(40, 0, 6), LL=(18, 0, -6), lift=0.9, H=(-20, 14, 0),
          RA=(120, 0, 50), LA=(80, 0, -60))
    t.key(26, "turning over", ease="in", T=(-72, -56, 40, 0, 0, -1.5), RL=(30, 0, 10), LL=(18, 0, -4), lift=0.6, H=(-6, 24, 0),
          RA=(140, 0, 70), LA=(40, 0, -40))
    t.key(34, "lands", ease="out", T=(-80, -12, 16, 0, 0, -1.7), RL=(10, 0, 10), LL=(30, 0, -6), lift=0.0, H=(4, 20, 0),
          RA=(8, 0, 80), LA=(52, 0, -30))
    t.mark(34, "Land")
    t.key(40, ease="sine", T=(-82, -8, 10, 0, 0, -1.6), lift=0.12, H=(-4, 18, 0))
    t.key(52, "lying", ease="sine", **LYING)
    t.key(66, ease="hold", **LYING)
    t.tail(0, phase=0.0)
    t.tail(16, "in", aim=0.55, curl=0.6, dir=(0.0, 0.8, 0.35), ripple=12.0, fall=0.5, phase=1.0)
    t.tail(34, "out", aim=0.8, curl=1.0, flat=0.0, dir=(-0.6, -0.5, -0.4), fall=0.0, phase=1.8)
    t.tail(48, "sine", aim=1.0, ripple=2.0, swing=9.0, dir=(-0.4, -1.0, -0.3), phase=2.4)
    t.tail(66, None, ripple=0.0, swing=9.0, phase=2.6)
    t.stand_ins.append(("shade", SHADE))



def up(t):
    """She rocks back onto her shoulders with her hands flat on the street by her hips, both legs come over, and she
    kicks out of it onto her feet low and ready, already facing it."""
    t.key(0, **LYING)
    t.key(5, T=(-94, -5, 0, 0, 0, -1.5), RL=(60, 0, 6), LL=(70, 0, -6), lift=0.74, RA=(0, 0, 14), LA=(0, 0, -14))
    t.key(10, "rocked back", T=(-98, -6, 0, 0, 0, -1.4), RL=(118, 0, 4), LL=(112, 0, -4), lift=0.72, H=(20, 0, 0),
          RA=(0, 0, 10), LA=(0, 0, -10))
    t.arm(12, "sine", RA=(20, 0, 70), LA=(20, 0, -70))   # the arms sweep out along the street to her sides, then up
    t.key(16, "the kick", ease="sine", T=(-40, -10, 0, 0, 0, -1.1), RL=(30, 0, 6), LL=(20, 0, -6), lift=1.1, H=(-10, 0, 0),
          RA=(120, 0, 52), LA=(120, 0, -52))
    t.key(22, "on her feet", ease="out", T=(34, -12, 0), feet={"Right Leg": (0.7, 0.3), "Left Leg": (-0.7, -0.5)},
          crouch=0.22, lift=0.0, look=EYES, H=(0, 0, 0), RA=(60, 0, 30), LA=(30, 0, -30))
    t.key(36, ease="sine", T=(18, -10, 0), crouch=0.24, RA=(20, 0, 14), LA=(-24, 0, -10))
    t.key(54, "up", T=HUB["T"], feet=HUB["feet"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])
    t.tail(0, aim=1.0, curl=0.0, flat=0.0, dir=(-0.4, -1.0, -0.3), ripple=0.0, swing=9.0, phase=0.6)
    t.tail(10, "sine", aim=0.5, curl=0.8, dir=(0.0, -0.4, 1.0), ripple=4.0, fall=0.6, phase=0.9)
    t.tail(18, "out", aim=0.6, curl=1.2, flat=60.0, dir=(-0.3, 0.3, 1.0), ripple=12.0, fall=0.5, phase=1.3)
    t.tail(40, "back", aim=0.0, curl=0.0, flat=90.0, ripple=TAIL["ripple"], swing=TAIL["swing"], fall=0.0, phase=1.9)
    t.tail(54, None, phase=2.2)
    t.stand_ins.append(("shade", SHADE))


CLIPS = {"Idle": idle, "Combo": combo, "ScarfStep": scarf_step, "Reveal": reveal, "Work": work,
         "Hit": hit, "Down": down, "Up": up}
# Each clip's cameras: where they look (a stage place), how far off, and the pose sheet's rows (the first is the
# blocking's). The tail is ten studs, so every view stands further off than Pip's.
VIEWS = {"Idle": ((-1.6, -1.2, 3.0), 19.0, ("game", "side", "front")),
         "Combo": ((-0.6, -0.8, 3.0), 20.0, ("game", "side")),
         "ScarfStep": ((2.8, 4.0, 2.6), 30.0, ("game", "side")),
         "Reveal": ((-1.2, -0.6, 3.4), 19.0, ("front", "side", "game")),
         "Work": ((0.3, 3.0, 2.6), 19.0, ("front", "game", "side")),
         "Hit": ((-0.6, -0.3, 2.6), 17.0, ("game", "side")),
         "Down": ((-0.2, -1.2, 1.2), 19.0, ("game", "side")),
         "Up": ((-0.2, -1.2, 1.2), 19.0, ("game", "side"))}
VIEW_ANGLES = {"game": GAME, "side": SIDE, "front": FRONT}


# --- outputs --------------------------------------------------------------------------------------------------------

def stand_ins(takes):
    """The grey Shade and the bay's post, each shown only over its own clip's frames."""
    m = ks.materials()
    for take in takes:
        for kind, (x, y) in take.stand_ins:
            pieces = ks.ghost(m, Vector((x, y, 0))) if kind == "shade" else [
                ks.loft("Post", [(0.0, x, y, 0.7, 0.7), (2.8, x, y, 0.7, 0.7), (2.9, x, y, 0.5, 0.5)], m["Ghost"], n=2.0)]
            for o in pieces:
                for frame, hidden in ((take.start - 1, True), (take.start, False), (take.start + take.end + 1, True)):
                    o.hide_render = hidden
                    o.keyframe_insert("hide_render", frame=frame)


def cameras(scene, takes):
    cams = {}
    for take in takes:
        focus, distance, views = VIEWS[take.name]
        for view in views:
            az, el = (math.radians(a) for a in VIEW_ANGLES[view])
            centre = W(focus[0], focus[1], focus[2])
            way = Vector((math.sin(az), 0, -math.cos(az))) * distance * math.cos(el) + Vector((0, distance * math.sin(el), 0))
            cams[take.name, view] = r6.fixed_camera(scene, centre + way, centre, 38.0, f"{take.name} {view}")
    return cams


def pose_sheet(scene, cams, take, out):
    views = VIEWS[take.name][2]
    shots = [(cams[take.name, view], take.start + f, f"{take.name} {f}: {label}" if view == views[0] else f"{f} {view}")
             for view in views for f, label in take.beats]
    scene.render.resolution_x, scene.render.resolution_y = 330, 380
    scene.render.stamp_font_size = 16
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(take.beats))
    print(f"wrote {path}")


def blocking_sheet(scene, cams, takes, out):
    """Every clip's key poses from its first view (the player's camera for the fight), a row a clip: the blocking,
    read at once."""
    columns = max(len(t.beats) for t in takes)
    blank = r6.fixed_camera(scene, Vector((0, 50, 0)), Vector((0, 100, 0.01)), 38.0, "Blank")  # empty sky, for a short row
    shots = []
    for take in takes:
        cam = cams[take.name, VIEWS[take.name][2][0]]
        row = [(cam, take.start + f, f"{take.name} {f}: {label}") for f, label in take.beats]
        shots += row + [(blank, take.start, "")] * (columns - len(row))
    scene.render.resolution_x, scene.render.resolution_y = 280, 300
    scene.render.stamp_font_size = 14
    path = r6.render_shots(scene, shots, out / "kirra_blocking.png", columns=columns)
    print(f"wrote {path}")


def arc_sheet(scene, rig, cams, take, rest, drawn, out):
    """One dot a frame where the tail's tip (cyan) and each drawn blade's point (amber the right, pale the left) are
    through the clip, over the body at its middle beat, from its first two views: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)
    bpy.context.scene.frame_set(take.start)
    home = r6.to_roblox(rig.root.matrix_world).to_translation()

    def at(rig, joint):  # path_dots carries a dot back by the root's travel (a treadmill); the dash and the blink are seen
        travel = r6.to_roblox(rig.root.matrix_world).to_translation() - home
        return Matrix.Translation(travel) @ r6.to_roblox(rig.parts[joint].matrix_world)

    # each point in its joint's own frame, which at rest is the world's axes at the joint's pivot
    dots = r6.path_dots(rig, frames, [(SCARF[-1], tuple(rest["tail"]["chords"][-1]))], colour=(0.35, 0.9, 0.95),
                        radius=0.07, name="Tip", at=at)
    for side, colour in (("R", (1.0, 0.82, 0.25)), ("L", (0.92, 0.9, 0.82))):
        if side in drawn:
            name = SIDES[side][0]
            G, J = rest["blades"][name]["G"], rest["blades"][name]["J"]
            point = (J.inverted() @ G @ Vector((0, STEEL[-1], 0, 1))).to_3d()
            dots += r6.path_dots(rig, frames, [(name, tuple(point))], colour=colour, radius=0.05, name=f"Point{side}", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    scene.render.resolution_x, scene.render.resolution_y = 640, 560
    path = r6.render_shots(scene, [(cams[take.name, view], beat, f"{take.name}: one dot a frame, {view}")
                                   for view in VIEWS[take.name][2][:2]], out / f"arcs_{take.name}.png", columns=2)
    for dot in dots:
        bpy.data.objects.remove(dot, do_unlink=True)
    print(f"wrote {path}")


def bare_sheet(scene, rig, take, undress, out, tiles=20):
    """What the content check asks of every clip: stepped through on the bare rig, the costume off, from her side and
    the three-quarter."""
    step = max(1, math.ceil((take.end + 1) / tiles))
    frames = list(range(0, take.end + 1, step))

    def camera(frame, azimuth, elevation, name, distance=14.0):
        """Turned with her root, aimed at her torso where it is: Work's laps and the Reveal's drop stay in frame."""
        scene.frame_set(frame)
        root, torso = r6.to_roblox(rig.root.matrix_world), r6.to_roblox(rig.parts["Torso"].matrix_world)
        look = Vector((-root[0][2], 0.0, -root[2][2])).normalized()
        side = look.cross(Vector((0, 1, 0))).normalized()
        a, e = math.radians(azimuth), math.radians(elevation)
        focus = torso.to_translation() + Vector((0, 0.2, 0))
        eye = focus + (look * math.cos(a) + side * math.sin(a)) * distance * math.cos(e) + Vector((0, distance * math.sin(e), 0))
        return r6.fixed_camera(scene, eye, focus, 38.0, name)

    undress(True)
    shots = [(camera(take.start + f, az, el, f"bare {view} {f}"), take.start + f, f"{f}")
             for view, (az, el) in (("side", SIDE), ("quarter", QUARTER)) for f in frames]
    scene.render.resolution_x, scene.render.resolution_y = 190, 230
    path = r6.render_shots(scene, shots, out / f"bare_{take.name}.png", columns=len(frames))  # each from where she is
    undress(False)
    print(f"wrote {path} (every {step} frames; her side, then the three-quarter)")


def report(name, take, n, checks):
    near = lambda d: "; ".join(f"{part} {v:.2f} at {f}" for part, (v, f) in d.items())  # noqa: E731
    blades = "\n".join(f"  the {side} blade out of its sheath, nearest her body (studs): {near(n['blade_near'][side])}"
                       for side in SIDES if min(v for v, _ in n["blade_near"][side].values()) < 9.0)
    if blades:
        blades += f"\n  (a blade at home reads {n['sheathed']:.2f} against the head's box, which is wider than her hair)"
    return (f"{name}: {take.end + 1} frames, {take.end / FPS:.2f} s{' (a loop)' if take.loop else ''}\n"
            f"  the tail's line at its lowest over the floor: {n['low'][0]:.2f} at {n['low'][1]}; its widest bend at a "
            f"joint: {n['bend'][0]:.0f} degrees (joint {n['bend'][2]}, at {n['bend'][1]})\n"
            f"  the tail's nearest her body past its first stud (studs): {near(n['tail_near'])}\n"
            + (blades + "\n" if blades else "")
            + f"  a leg's widest swing: {checks['swing'][0]:.0f} degrees at {checks['swing'][1]}\n"
            f"  the longest an arm is nearly still at 20 to 70 degrees up, of {HELD} frames: right {checks['held']['Right Arm'][0]} "
            f"(to {checks['held']['Right Arm'][1]}), left {checks['held']['Left Arm'][0]} (to {checks['held']['Left Arm'][1]})\n"
            f"  each arm at its highest: right {checks['high']['Right Arm'][0]:.0f} degrees at {checks['high']['Right Arm'][1]}, "
            f"left {checks['high']['Left Arm'][0]:.0f} at {checks['high']['Left Arm'][1]}\n")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "export", "audit") else "poses"
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    scene, rig, costume, undress, feet, ctl, motors, rest, _ = build()
    takes = {}
    for i, name in enumerate(CLIPS):
        if name in wanted:
            takes[name] = take = Take(rig, feet, ctl, name, 1000 * i, rest)
            CLIPS[name](take)
            for line in take.warned:
                print("  " + line)
    keyed = list(takes.values())
    rc.ground(rig, feet, keyed)
    rc.lift(rig, ctl["lift"], keyed)
    numbers = props(rig, ctl, motors, rest, list(takes.values()))
    stand_ins(list(takes.values()))
    cams = cameras(scene, list(takes.values()))
    facts = {}
    for name, take in takes.items():
        notes = report(name, take, numbers[name], audit(rig, take))
        print(notes, end="")
        facts[name] = {"File": f"Kirra_{name}.json", "Frames": take.end + 1, "Seconds": round(take.end / FPS, 3), "Loop": take.loop,
                       "Markers": [[round(t * FPS), label] for t, label in take.markers]}
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        heard = io.StringIO()  # the export audits itself aloud: the pack's notes keep what it said
        with contextlib.redirect_stdout(heard):
            # the Name is the game's: Author.SaveBaked reads Anim_Kirra<Clip> and checks the clip is named the same
            r6.export(rig, out / f"Kirra_{name}.json", "Kirra", f"Kirra{name}", take.start, take.start + take.end,
                      markers=take.markers, source="tools/blender/kirra_clips.py", extra={"Loop": take.loop})
        print(heard.getvalue(), end="")
        if mode == "audit":
            continue
        drawn = [side for side in SIDES if min(v for v, _ in numbers[name]["blade_near"][side].values()) < 9.0]
        arc_sheet(scene, rig, cams, take, rest, drawn, out)
        bare_sheet(scene, rig, take, undress, out)
        view = cams[name, VIEWS[name][2][0]]
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame, view=view: view, bare=SIDE[0], strip=strip, undress=undress,
                       notes=notes + heard.getvalue())
        print(f"wrote {out / f'pack_{name}.png'}")
    if mode == "poses" and len(takes) > 1:
        blocking_sheet(scene, cams, list(takes.values()), out)
    if mode != "poses" and len(takes) == len(CLIPS):
        (out / "Kirra.clips.json").write_text(json.dumps({"Fps": FPS, "Clips": facts}, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out / 'Kirra.clips.json'}")


if __name__ == "__main__":
    main()
