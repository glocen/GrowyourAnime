"""Watt's clips on the R6 rig, his delivered model riding it (AR11, delivery 3).

blender.exe -b --factory-startup --python tools/blender/watt_clips.py -- <out_dir> [poses|film|export|audit] [clip ...]

- poses (the default): one sheet a clip, its key poses from its views, and watt_blocking.png, every clip's key poses
  from its first view (the player's camera for the fight), a row a clip.
- film: film_<Clip>.mp4, the clip in motion from its first view at 30 frames a second, for the timing's read.
- export: Watt_<Clip>.json for the builder (r6anim.export, with its audit) and Watt.clips.json; and for the review,
  a clip's pack (pack_<Clip>.png and .txt), its arcs (arcs_<Clip>.png: the blade's point and the butt, one dot a
  frame), the bare rig stepped through from the side and the three-quarter (bare_<Clip>.png), and once the slung
  spear from the side and the back at 64 px (slung.png), as the content check asks.
- audit: the export's audit alone.

The model is the delivered one (build/handoff/Watt: the seven meshes, the colour map, the recipe), built on R6 here
as the game builds it. The keying is rook_clips.py's: every clip at 60 fps on its own stretch of one timeline,
starting from HUB; feet given as places on the floor. Stage directions: right, forward, up, in studs; his root stands
at the stage's middle facing forward in every clip (the game moves it, never the clip).

Beside the body, the spear is keyed apart and solved on every frame once the body is keyed (Take.spear). Its joint is
on the Torso at the grip, so a clip that never keys it (the shared walk, the open reactions) leaves it slung. A clip
that does says where it is by three things:
- pinned (m 1): its butt on a floor place, the shaft through his right fist wherever the fist goes. Planted.
- free (m 0): the shaft through his right fist along a direction, the butt `s` studs from the fist. Carried.
- standing (h 0): the butt on its place and the shaft along its direction, whatever his hands do. Let go.
Either hand may hold it (Take.key's ("shaft", s, hint)): the arm is solved on every frame onto the shaft, at the
point nearest `s` studs up from the butt that the straight R6 arm can reach.

How he moves: unhurried, and the spear never moves without a reason. He stands like a man leaning on a gate.
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

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import kirra_sheet as ks  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402

FPS = rc.FPS
ROOT = Path(__file__).resolve().parents[2]
MODEL = ROOT / "build" / "handoff" / "Watt"
GAME, SIDE, FRONT, QUARTER = rc.GAME, (90.0, 6.0), rc.FRONT, (48.0, 8.0)  # azimuth from his front, elevation
BACK = (180.0, 8.0)
W = rc.W
SPEAR = "Watt_Spear"
EYES = (0.0, 12.0, 4.6)  # level, on the street ahead
NOD_DOWN = 8.0  # degrees his chin may drop against the torso: the coat's collar stands at his jaw, and past this it
# rises over his mouth (the content check's condition)
HEAD_END = 5.5  # studs up the shaft from the butt where the discs begin: past this is what must clear his head
FIST = 0.75  # studs of shaft each side of a holding hand left out of the body's clearance (it's in the fist)
STILL, HELD = 45.0, 6  # degrees a second under which an arm counts as held, and the frames it may be (Pip's)
GRAB = 5  # frames a hand takes to close on the shaft
# His body as boxes in each part's frame, for what the spear must clear: the delivered pieces' own sizes (the head with
# its hair fanned back, the torso with its collar, the legs with the coat's skirt).
BOXES = {"Head": ((0, 0.213, 0.35), (1.155, 0.84, 1.1)), "Torso": ((-0.02, 0.2, 0.05), (1.04, 1.2, 0.85)),
         "Right Arm": ((0, 0, 0), (0.552, 1.0, 0.552)), "Left Arm": ((0, 0, 0), (0.552, 1.0, 0.552)),
         "Right Leg": ((0, 0, -0.06), (0.53, 1.0, 0.59)), "Left Leg": ((0, 0, -0.06), (0.53, 1.0, 0.59))}
COLOURS = {"Coat": "#1F4954", "Skin": "#F3CFB1", "Trouser": "#B4AEA2", "Ink": "#141821"}


# --- the rig with the delivered model on it ---------------------------------------------------------------------------

def mesh_object(name, record, material):
    """A delivered mesh in Blender where it stands at rest (its points are about its centre `c`), with its UVs."""
    p, t, c = record["p"], record["t"], record["c"]
    tris = [record["f"][i:i + 9] for i in range(0, len(record["f"]), 9)]
    data = bpy.data.meshes.new(name)
    data.from_pydata([tuple(r6.point_to_blender([p[i] + c[0], p[i + 1] + c[1], p[i + 2] + c[2]])) for i in range(0, len(p), 3)],
                     [], [tuple(tri[:3]) for tri in tris])
    uv = data.uv_layers.new(name="UVMap")
    for poly, tri in zip(data.polygons, tris):
        for loop, k in zip(poly.loop_indices, tri[6:9]):
            uv.data[loop].uv = (t[2 * k], 1 - t[2 * k + 1])
    data.materials.append(material)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def colour_material():
    material = bpy.data.materials.new("Watt_Color")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = bpy.data.images.load(str(MODEL / "Watt_Color.png"))
    material.node_tree.links.new(texture.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
    nodes.active = texture  # Workbench draws the active image node
    return material


def spear_rest(recipe) -> dict:
    """The spear as it lies slung (Roblox): its butt, its line, the grip's place on it, its length, and its profile:
    the widest it is round its line at each tenth of a stud along it (the discs, the blade)."""
    at = {p["name"]: Vector(p["at"]) for p in recipe["points"]}
    along = Vector(recipe["motors"]["Spear"]["along"]).normalized()
    butt = at["Butt"]
    record = json.loads((MODEL / "Watt_Spear.json").read_text())
    p, c = record["p"], record["c"]
    profile = {}
    for i in range(0, len(p), 3):
        v = Vector((p[i] + c[0], p[i + 1] + c[1], p[i + 2] + c[2])) - butt
        t = v.dot(along)
        k = int(round(t * 10))
        profile[k] = max(profile.get(k, 0.0), (v - along * t).length)
    length = max(profile) / 10
    return {"butt": butt, "along": along, "grip": (at["Grip"] - butt).dot(along), "length": length,
            "tip": (at["Blade"] - butt).dot(along), "head": (at["SpearHead"] - butt).dot(along),
            "radius": lambda t: max([profile.get(k, 0.0) for k in range(int(t * 10) - 1, int(t * 10) + 2)] + [0.05])}


def build():
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    recipe = json.loads((MODEL / "Watt.recipe.json").read_text())
    c = {name: rs.srgb(code)[:3] for name, code in COLOURS.items()}
    rig = r6.build_rig("Watt", {"Torso": c["Coat"], "Head": c["Skin"], "Right Arm": c["Coat"], "Left Arm": c["Coat"],
                                "Right Leg": c["Trouser"], "Left Leg": c["Trouser"], "Face": c["Ink"]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    material = colour_material()
    costume, motors, extra = {}, {}, []
    for piece in recipe["pieces"]:
        obj = costume[piece["name"]] = mesh_object(piece["name"], json.loads((MODEL / piece["mesh"]).read_text()), material)
        holder = rig.parts[piece["on"]]
        if "motor" in piece:  # the spear: a joint of its own on the Torso at the grip, keyed and exported under its name
            local = r6.to_roblox(holder.matrix_world).inverted() @ Matrix.Translation(Vector(piece["pivot"]))
            motors[obj.name] = r6._empty(f"Watt.C0.{obj.name}", holder, local, 0.1)
            holder = rig.joints[obj.name] = rig.parts[obj.name] = r6._empty(f"Watt.J.{obj.name}", motors[obj.name],
                                                                             Matrix.Identity(4), 0.1)
            rig.bases[obj.name] = Matrix.Identity(4)
            extra.append((piece["on"], obj.name))
            bpy.context.view_layer.update()
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
    rig.extra_joints = lambda: list(extra)
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects["Watt.Face"]]

    def undress(bare: bool):  # the bare rig, as Roblox moderates an upload: the spear goes with the costume
        for o in costume.values():
            o.hide_render = bare
        for o in blocks:
            o.hide_render = not bare

    undress(False)
    feet = {leg: r6._empty(f"Watt.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    ctl = {name: r6._empty(f"Watt.Ctl.{name}", None, Matrix.Identity(4), 0.1)
           for name in ("lift", "sp_mode", "sp_butt", "sp_dir", "sp_slide", "grabR", "grabL")}
    for empty in (*feet.values(), *ctl.values()):
        empty.location = (0, 0, 0)
    reach = {arm: r6._rest_offset(arm, rc.HAND).length for arm in ("Right Arm", "Left Arm")}
    rest = {"spear": spear_rest(recipe), "reach": reach}
    return scene, rig, costume, undress, feet, ctl, motors, rest


# --- the spear ---------------------------------------------------------------------------------------------------------

def spear_line(v, hand) -> tuple:
    """(butt, direction) of the shaft (Roblox world) from a frame's numbers `v` and the right fist's grip point."""
    m, h = v["sp_mode"][0], v["sp_mode"][1]
    B, D, s = W(*v["sp_butt"]), W(*v["sp_dir"]), v["sp_slide"][0]
    D = D.normalized() if D.length > 1e-6 else Vector((0, 1, 0))
    up = hand - B
    up = up.normalized() if up.length > 1e-6 else D
    held = D.lerp(up, m).normalized()
    butt_held = (hand - D * s).lerp(B, m)
    return B.lerp(butt_held, h), D.lerp(held, h).normalized()


def spear_matrix(rest, butt, D, roll) -> Matrix:
    """The spear's world frame (Roblox) for its joint: turned from its slung line onto D the shortest way, then `roll`
    degrees about its own line, with the grip's place on the line."""
    s = rest["spear"]
    q = Quaternion(D, math.radians(roll)) @ s["along"].rotation_difference(D)
    return Matrix.Translation(butt + D * s["grip"]) @ q.to_matrix().to_4x4()


SWITCH = 0.75  # studs nearer `s` the shaft's other reachable point must be before a held hand jumps to it
JUMP = 0.3  # studs between the two points under which the hand just takes the one nearer `s`: too small a jump to pop


def on_shaft(rig, arm, reach, butt, D, s, length, prev=None) -> tuple:
    """The point on the shaft a straight arm's hand can be on, nearest `s` studs up from the butt (Roblox world), and
    how far off the shaft the hand must stay when no point is in reach, and which point it took (0 the lower, 1 the
    upper, None on a miss). A straight arm meets the shaft at two points: `prev`, the one the hand held last frame,
    keeps it there unless the other is SWITCH nearer `s`, or the hand would jump between them as the shaft moves."""
    S = r6._joint_frame(rig, arm).to_translation()
    o = butt - S
    b, c = D.dot(o), o.length_squared - reach * reach
    disc = b * b - c
    if disc >= 0:
        r = math.sqrt(disc)
        roots = {i: t for i, t in enumerate((-b - r, -b + r)) if 0.2 <= t <= length - 1.6}
        if roots:
            i = min(roots, key=lambda k: abs(roots[k] - s))
            if prev in roots and prev != i and abs(roots[prev] - roots[i]) > JUMP \
                    and abs(roots[prev] - s) < abs(roots[i] - s) + SWITCH:
                i = prev
            return butt + D * roots[i], 0.0, i
    t = max(0.2, min(length - 1.6, -b))
    return butt + D * t, max(0.0, (butt + D * t - S).length - reach), None


# --- keying ------------------------------------------------------------------------------------------------------------

B_LEAN = (2.3, 0.45, 0.0)  # where the spear stands as he leans on it: out by his right foot, a little ahead
HAND_LEAN = (2.25, 0.45, 2.72)  # where his right fist holds it, at his ribs
HUB = {
    "T": (3, -5, -6, 0.12, 0, 0), "feet": {"Right Leg": (0.85, 0.15), "Left Leg": (-0.8, -0.12)}, "RL": (0, 0, 0), "LL": (0, 0, 0),
    "crouch": 0.08, "look": EYES, "H": (0, 0, 0), "RA": ("reach", HAND_LEAN, (24, 0, 48)), "LA": (-4, 0, -9), "lift": 0.0,
}
SPEAR_HUB = {"m": 1.0, "h": 1.0, "roll": 0.0, "B": B_LEAN, "D": (0.0, 0.0, 1.0), "s": 2.8}


class Take(rc.Take):
    """One clip being keyed from `start`, as rook_clips.Take, with the spear's track and the hands on its shaft."""

    def __init__(self, rig, feet, ctl, name, start, rest):
        super().__init__(rig, feet, name, start)
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in HUB.items()}
        self.ctl, self.rest, self.stand_ins = ctl, rest, []
        self.sp = dict(SPEAR_HUB)
        self.grips = {"R": (0.0, 2.8), "L": (0.0, 4.0)}
        self.last_f = 0
        self.spear(0)

    def _hold(self, f, ease, values):
        frame = self.start + f
        for name, value in values.items():
            empty = self.ctl[name]
            empty.location = value
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *rc.EASE[ease])
        self.end = max(self.end, f)
        return self

    def spear(self, f, ease=None, **changes):
        """Keys the spear at clip frame `f` (SPEAR_HUB's names): m, pinned (1) or carried (0); h, in his right fist
        (1) or standing on its own (0); roll, degrees about its line; B, the butt's floor place (right, forward, up);
        D, its line, butt to blade (right, forward, up); s, studs from the butt up to the fist, carried. What isn't
        named holds. Key it before the body at the same frame."""
        p = self.sp
        p.update(changes)
        return self._hold(f, ease, {"sp_mode": (p["m"], p["h"], p["roll"]), "sp_butt": p["B"], "sp_dir": p["D"],
                                    "sp_slide": (p["s"], 0.0, 0.0)})

    def line_now(self) -> tuple:
        """The shaft (butt, direction, Roblox) as the spear's last key and the right fist stand now."""
        v = {"sp_mode": (self.sp["m"], self.sp["h"], 0.0), "sp_butt": self.sp["B"], "sp_dir": self.sp["D"],
             "sp_slide": (self.sp["s"], 0.0, 0.0)}
        return spear_line(v, r6.hand(self.rig, "Right Arm").to_translation())

    def key(self, f, label=None, ease=None, feet_ease=None, **changes):
        """Keys the body at clip frame `f`. `ease` shapes the move that starts here (`feet_ease` the feet's). `label`
        puts it on the pose sheet. Changes: T (pitch, turn, roll, right, _, forward), feet {leg: (right, forward), or
        None for a leg given by its angles in RL / LL}, crouch, lift, look (a stage place) or H (angles), RA / LA
        (angles; ("reach", place, hint) for the hand; ("shaft", s, hint) for the hand on the shaft, nearest s studs up
        from the butt, solved again on every frame)."""
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
        floats = max((r6.sole(rig, leg) for leg in planted), default=0.0)
        if floats > 0.05:
            self.warned.append(f"{self.name} {f}: a planted foot floats {floats:.2f} over the floor")
        for leg, empty in self.feet.items():
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
            out["Head"] = (max(-rc.NOD, min(NOD_DOWN, pitch)), turn, tilt)
        else:
            out["Head"] = (min(NOD_DOWN, s["H"][0]), *s["H"][1:])
        r6._key_parts(rig, frame, out, *interp)
        for arm, side in (("RA", "R"), ("LA", "L")):  # the right first: the shaft may run through its fist
            a, part = s[arm], rc.SHORT[arm]
            if a[0] == "reach":
                pose = r6.reach(rig, part, rc.HAND, W(*a[1]), a[2])
            elif a[0] == "shaft":
                r6._refresh()
                butt, D = self.line_now()
                point = on_shaft(rig, part, self.rest["reach"][part], butt, D, a[1], self.rest["spear"]["length"])[0]
                pose = r6.reach(rig, part, rc.HAND, point, a[2])
            else:
                pose = a
            r6._key_parts(rig, frame, {part: pose}, *interp)
            r6._refresh()
            was = self.grips[side]
            self.grips[side] = (1.0 if a[0] == "shaft" else 0.0, a[1] if a[0] == "shaft" else was[1])
            if self.grips[side][0] > was[0] and f - self.last_f > GRAB:  # the hand closes on it over its last frames
                self._hold(f - GRAB, None, {f"grab{side}": (0.0, self.grips[side][1], 0.0)})
            self._hold(f, ease, {f"grab{side}": (*self.grips[side], 0.0)})
        if label:
            self.beats.append((f, label))
        self.last_f = f
        return self

    def arm(self, f, ease=None, **arms):
        """A breakdown for an arm alone at clip frame `f` (RA / LA angles), between two keys, so it goes the way it's
        sent. Call it in frame order between the keys it sits between."""
        frame = self.start + f
        bpy.context.scene.frame_set(frame)
        r6._key_parts(self.rig, frame, {rc.SHORT[a]: v for a, v in arms.items()}, *rc.EASE[ease])
        return self


def stage_of(p: Vector) -> tuple:
    """A Roblox world point as a stage place (right, forward, up)."""
    return (p.x, -p.z, p.y)


# --- the props pass: the spear and the hands on it, solved on every frame ---------------------------------------------

def clear(point, part, frame) -> float:
    """How far a point is outside a body's box, in studs; negative is inside."""
    centre, half = BOXES[part]
    d = np.abs(np.array((frame.inverted() @ point)[:]) - np.array(centre)) - np.array(half)
    out = float(np.linalg.norm(np.maximum(d, 0)))
    return out if out > 0 else float(d.max())


def spear_clearance(rest, butt, D, parts, fists) -> dict:
    """Each body box's clearance from the spear (studs, its own width counted): the discs and the blade against the
    head, the whole shaft against everything, less a fist's width of shaft each side of a holding hand."""
    sp = rest["spear"]
    near = {}
    for t in np.arange(0.0, sp["length"] + 1e-6, 0.15):
        point, r = butt + D * float(t), sp["radius"](float(t))
        by_fist = any(abs(float(t) - at) < FIST for at in fists.values())
        for part, frame in parts.items():
            if part != "Head" and by_fist:
                continue
            near[part] = min(near.get(part, 9.0), clear(point, part, frame) - r)
    return near


def props(rig, ctl, motors, rest, takes) -> dict:
    """The last pass, once the body is keyed on every frame: a hand on the shaft solved onto it, and the spear's joint,
    keyed on every frame. Returns each clip's numbers."""
    scene, facts, sp = bpy.context.scene, {}, rest["spear"]
    arms = {"R": "Right Arm", "L": "Left Arm"}
    for take in takes:
        n = take.end + 1
        samples = []
        for f in range(n):
            scene.frame_set(take.start + f)
            samples.append({"v": {name: tuple(e.location) for name, e in ctl.items()},
                            "pose": {side: r6.pose_of(rig, arm)[:3] for side, arm in arms.items()}})
        held = {side: any(S["v"][f"grab{side}"][0] > 1e-3 for S in samples) for side in arms}
        out = {"head": (9.0, 0), "body": {p: (9.0, 0) for p in BOXES}, "butt_low": (9.0, 0), "tip_low": (9.0, 0),
               "miss": {side: (0.0, 0) for side in arms}, "speed": (0.0, 0), "slide": (0.0, 0), "nod": (-90.0, 0),
               "lines": []}
        last_tip, last_butt = None, None
        held_at = {side: None for side in arms}  # which of the shaft's two reachable points each hand held last frame
        for f, S in enumerate(samples):
            frame, v = take.start + f, S["v"]
            scene.frame_set(frame)
            hand = r6.hand(rig, "Right Arm").to_translation()
            if held["R"]:
                on, s = v["grabR"][0], v["grabR"][1]
                pose = S["pose"]["R"]
                if on > 1e-3:
                    standing = dict(v, sp_mode=(v["sp_mode"][0], 0.0, 0.0))
                    butt, D = spear_line(standing, hand)
                    point, miss, branch = on_shaft(rig, "Right Arm", rest["reach"]["Right Arm"], butt, D, s, sp["length"],
                                                   held_at["R"])
                    held_at["R"] = branch if on > 0.5 else None
                    solved = r6.reach(rig, "Right Arm", rc.HAND, point, pose)
                    pose = tuple(a + (b - a) * on for a, b in zip(pose, solved))
                    if on > 0.5:
                        out["miss"]["R"] = max(out["miss"]["R"], (miss, f))
                else:
                    held_at["R"] = None
                r6._key_parts(rig, frame, {"Right Arm": pose}, "LINEAR", "AUTO")
                r6._refresh()
                hand = r6.hand(rig, "Right Arm").to_translation()
            butt, D = spear_line(v, hand)
            M = spear_matrix(rest, butt, D, v["sp_mode"][2])
            c0 = r6.to_roblox(motors[SPEAR].matrix_world)
            r6.key_matrices(rig, frame, {SPEAR: r6.to_blender(c0.inverted() @ M)})
            if held["L"]:
                on, s = v["grabL"][0], v["grabL"][1]
                pose = S["pose"]["L"]
                if on > 1e-3:
                    point, miss, branch = on_shaft(rig, "Left Arm", rest["reach"]["Left Arm"], butt, D, s, sp["length"],
                                                   held_at["L"])
                    held_at["L"] = branch if on > 0.5 else None
                    solved = r6.reach(rig, "Left Arm", rc.HAND, point, pose)
                    pose = tuple(a + (b - a) * on for a, b in zip(pose, solved))
                    if on > 0.5:
                        out["miss"]["L"] = max(out["miss"]["L"], (miss, f))
                else:
                    held_at["L"] = None
                r6._key_parts(rig, frame, {"Left Arm": pose}, "LINEAR", "AUTO")
            r6._refresh()
            parts = {p: r6.to_roblox(rig.parts[p].matrix_world).copy() for p in BOXES}
            fists = {}
            if v["sp_mode"][1] > 0.5:
                fists["Right Arm"] = (hand - butt).dot(D)
            if v["grabL"][0] > 0.5:
                fists["Left Arm"] = (r6.hand(rig, "Left Arm").to_translation() - butt).dot(D)
            if v["grabR"][0] > 0.5:
                fists["Right Arm"] = (r6.hand(rig, "Right Arm").to_translation() - butt).dot(D)
            near = spear_clearance(rest, butt, D, parts, fists)
            for part, d in near.items():
                out["body"][part] = min(out["body"][part], (d, f))
            head = min(clear(butt + D * float(t), "Head", parts["Head"]) - sp["radius"](float(t))
                       for t in np.arange(HEAD_END, sp["length"] + 1e-6, 0.1))
            out["head"] = min(out["head"], (head, f))
            tip = butt + D * sp["tip"]
            out["butt_low"] = min(out["butt_low"], (butt.y, f))
            out["tip_low"] = min(out["tip_low"], (tip.y, f))
            if last_tip is not None:
                out["speed"] = max(out["speed"], ((tip - last_tip).length, f))
                for now, then in ((butt, last_butt), (tip, last_tip)):  # whichever end is in the street, along it
                    if now.y < 0.05 and then.y < 0.05:
                        out["slide"] = max(out["slide"], ((now - then).xz.length, f))
            last_tip, last_butt = tip, butt
            out["nod"] = max(out["nod"], (r6.pose_of(rig, "Head")[0], f))
            out["lines"].append((butt.copy(), D.copy()))
        facts[take.name] = out
    return facts


def blend_from_slung(rig, motors, rest, take) -> tuple:
    """The discs' and the blade's nearest to his head as the game fades this clip in over the walk, which leaves the
    spear slung: the joint's transform eased from none to the clip's first frame (CFrame:Lerp), the body as the clip
    starts. Also from the clip's last frame back to slung, as it fades out to the walk."""
    scene, sp, worst = bpy.context.scene, rest["spear"], (9.0, "")
    for f, way in ((take.start, "in"), (take.start + take.end, "out")):
        scene.frame_set(f)
        T = r6.to_roblox(rig.joints[SPEAR].matrix_basis)
        c0, head = r6.to_roblox(motors[SPEAR].matrix_world), r6.to_roblox(rig.parts["Head"].matrix_world)
        q1, p1 = T.to_quaternion(), T.to_translation()
        for w in np.linspace(0.0, 1.0, 21):
            M = c0 @ Matrix.Translation(p1 * float(w)) @ Quaternion().slerp(q1, float(w)).to_matrix().to_4x4()
            butt = M @ sp_butt_rest_local(rest)
            D = (M.to_3x3() @ sp["along"]).normalized()
            d = min(clear(butt + D * float(t), "Head", head) - sp["radius"](float(t))
                    for t in np.arange(HEAD_END, sp["length"] + 1e-6, 0.1))
            worst = min(worst, (d, f"fading {way} at {w:.2f}"))
    return worst


def sp_butt_rest_local(rest) -> Vector:
    """The butt in the spear joint's own frame: at rest that frame is the world's axes at the grip."""
    sp = rest["spear"]
    return sp["butt"] - (sp["butt"] + sp["along"] * sp["grip"])


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


# --- the clips ---------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses. His stance is the model's: square, feet wide, weight down,
# the spear planted out by his right foot and his right fist on it at his ribs, the left arm loose. The spear stays
# upright or leans away from him; it never tips in over his head, and its blade never comes down toward the street or
# a body. R6's arm is straight and a stud and a half long, so a hand holds the shaft only where it passes that close to
# the shoulder: the left joins only when the shaft comes in front of him.

def idle(t):
    """He leans on it like a gate he's minding. Weight in his right hip, toward the spear; one slow breath; once a
    loop his eyes go along the street to his left and back, unhurried. Nothing else moves: the quiet wall."""
    t.loop = True
    t.key(0, "the lean", ease="sine")
    t.key(60, ease="sine", T=(2, -5, -5, 0.12, 0, 0), crouch=0.05, RA=("reach", (2.25, 0.45, 2.8), (24, 0, 48)))
    t.key(120, "the breath out", ease="sine", T=(4, -5, -7, 0.13, 0, 0), crouch=0.1, RA=("reach", HAND_LEAN, (24, 0, 48)))
    t.key(150, ease="cubic", T=(3, -3, -6, 0.12, 0, 0))
    t.key(166, "along the street", ease="sine", look=(-9.0, 5.0, 4.4), H=(0, 0, 0), T=(3, 8, -5, 0.12, 0, 0))
    t.key(196, ease="cubic", look=(-8.6, 5.6, 4.4))
    t.key(212, ease="sine", look=EYES, T=(3, -4, -6, 0.12, 0, 0))
    t.key(240, T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], look=EYES)


SHADE = (0.0, 3.9)  # the Combo's Shade: he doesn't close in, it comes to him


def combo(t):
    """Three blows, all of the shaft, none of the blade. He pulls the spear out of the street and lays it across in
    both fists like a bar, and shoves the Shade with it: the wall. The butt end snaps round into it. Then he stands it
    up and drives it down into the street in front of him, and the street does the rest. He picks it up and stands it
    back by his foot."""
    bar = (1.0, 0.0, 0.0)
    t.key(0, "the lean", look=(0.0, 3.9, 3.2), H=(0, 0, 0))
    t.spear(2, ease="cubic")
    t.spear(9, m=0.0, D=(0.08, 0.04, 1.0), s=2.9)  # straight up out of the street, a hand's width
    t.key(9, "out of the street", T=(-2, -10, -4, 0.08, 0, 0), crouch=0.1, RA=("reach", (2.2, 0.55, 3.3), (36, 0, 50)))
    t.spear(12, D=(0.1, 0.05, 1.0), s=2.5)  # brought in front of him upright, the butt clear of his legs, unbroken
    t.key(12, T=(-3, -8, -2, 0.04, 0, 0), crouch=0.12, RA=("reach", (1.25, 1.35, 3.45), (70, 0, 30)))
    # tipped over to his right, the blade going out and down away from him, and taken at its middle in both fists, a
    # bar as long each side of him, drawn back to his chest: then shoved at it at arm's length with a step
    t.spear(15, ease="in", D=bar, s=4.8)
    t.key(15, "across, in both fists", ease="in", T=(-6, -4, 0, 0, 0, -0.12), crouch=0.16,
          RA=("reach", (0.9, 0.95, 2.75), (52, 0, 4)), LA=("shaft", 3.0, (52, 0, -4)))
    t.spear(21, ease="out")
    t.key(21, "1: the wall", ease="out", T=(12, 0, 0, 0, 0, 0.45), crouch=0.2, feet={"Left Leg": (-0.75, 0.55)},
          RA=("reach", (0.9, 2.0, 3.2), (90, 0, 2)))
    t.mark(21, "Hit1")
    t.spear(24, ease="cubic")  # the wall holds a beat on the hit, then the left lets go
    t.key(24, ease="cubic")
    # the butt drops to the street before him, the blade standing high over his right shoulder, his body wound down
    # and round to his right; then the whole spear wheels: the butt comes up into the Shade's chest as the blade
    # sweeps down past his right side behind him, his body turning up and into it. A diagonal across the player's view
    # as long as the spear, where a jab straight ahead would run along it and vanish
    t.spear(28, ease="in", D=(0.415, -0.138, 0.9), s=2.6)
    t.key(28, ease="in", T=(12, -12, 0, 0, 0, 0.25), crouch=0.3, RA=("reach", (1.0, 1.0, 2.9), (70, 0, 20)), LA=(40, 0, -26))
    t.spear(36, ease="out", D=(0.85, -0.3, -0.43), s=1.9)  # out past his side, clear of his arm
    t.key(36, "2: the butt, rising", ease="out", T=(4, 22, 0, 0, 0, 0.4), crouch=0.1, RA=("reach", (1.1, 1.3, 3.0), (64, 0, 30)),
          LA=(-40, 0, -32))
    t.mark(36, "Hit2")
    t.spear(44, ease="cubic", D=(0.5, -0.1, 0.86), s=2.2)
    t.key(44, ease="cubic", T=(2, 4, 0, 0, 0, 0.2), crouch=0.12, RA=("reach", (1.1, 1.4, 3.2), (62, 0, 26)))
    # stood up before him and lifted in both fists, the left above the right: R6's two hands meet on one shaft only
    # within about a stud of his chest, so the shaft rises there, leaning a hair away from his face
    # lifted high, his body rising and rocked back on it; then driven in one-handed at a slant ahead of him, the blade
    # leaning out over the Shade, his body lunged down over it and the left flung back
    t.spear(54, ease="in", D=(0.02, 0.06, 1.0), s=2.0, B=(0.8, 1.1, 0.0))
    t.key(54, "up, both hands", ease="in", T=(-8, -12, 0, 0, 0, -0.05), crouch=-0.04, RA=("reach", (0.22, 1.0, 3.6), (96, 0, 8)),
          LA=("shaft", 1.5, (84, 0, -10)), look=(0.0, 3.9, 4.2))
    t.spear(60, ease="hold", m=1.0)
    t.key(60, "3: into the street", ease="out", T=(22, -15, 0, 0, 0, 0.35), crouch=0.36, feet={"Right Leg": (0.9, 0.35)},
          RA=("reach", (0.86, 2.0, 2.45), (64, 0, 12)), LA=(-44, 0, -26), look=(0.0, 3.9, 4.0))
    t.mark(60, "Hit3")
    t.key(72, "held on it", ease="sine", T=(12, -15, 0, 0, 0, 0.22), crouch=0.34, LA=(-24, 0, -18))
    t.key(80, ease="cubic", T=(6, -8, 0, 0, 0, 0.1), crouch=0.14, LA=(-6, 0, -10), RA=("reach", (1.2, 1.5, 3.0), (60, 0, 20)))
    t.spear(80, ease="cubic")
    t.spear(88, ease="cubic", m=0.0, D=(0.05, -0.05, 1.0), s=2.7)  # lifted a hand's width, carried back
    t.spear(89, ease="cubic", B=B_LEAN)  # its new place, taken while it's in the air
    t.key(88, "back by his foot", ease="cubic", T=(2, -5, -2, 0, 0, 0.0), crouch=0.08, feet={"Right Leg": HUB["feet"]["Right Leg"],
          "Left Leg": HUB["feet"]["Left Leg"]}, RA=("reach", (2.25, 0.5, 3.0), (30, 0, 48)))
    t.spear(96, ease="hold", m=1.0)
    t.key(96, ease="sine", T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"], look=EYES)
    t.key(110)
    t.stand_ins.append(("shade", SHADE))


RING = ((0.0, 7.0), (-5.2, 5.0), (6.2, 2.6), (-6.4, -1.5))  # Shades round him as the ring goes out


def ground_wire(t):
    """He takes the spear up out of the street in both hands, lifts it, and drives it down in front of him. The ring
    goes out from the butt along the street, and he holds there behind the shaft, low, both fists on it, while the
    Shades stand locked: nothing moves but his breath. Then he straightens and stands it back by his foot."""
    plant = (0.15, 0.8, 0.0)  # square before him, under a stud out: where both his fists can be on it, leaning away
    t.key(0, "the lean")
    t.spear(4, ease="cubic")
    t.spear(10, ease="out", m=0.0, D=(0.08, 0.04, 1.0), s=2.9)  # up out of the street at his right
    t.key(10, ease="out", T=(-2, -8, -3, 0.05, 0, 0), crouch=0.06, RA=("reach", (2.0, 0.6, 3.3), (40, 0, 48)))
    t.spear(16, ease="in", D=(0.0, 0.05, 1.0), s=2.0)  # brought before him and lifted, both fists on it
    t.spear(17, B=plant)  # where it goes in, taken while it's in the air
    t.key(16, "up, both hands", ease="in", T=(-6, -12, 0, 0, 0, -0.05), crouch=-0.02, RA=("reach", (0.22, 1.05, 3.4), (84, 0, 8)),
          LA=("shaft", 2.6, (104, 0, -10)), look=(0.0, 8.0, 5.0), H=(0, 0, 0))
    t.key(21, ease="snap", T=(-8, -12, 0, 0, 0, -0.08), crouch=-0.04, RA=("reach", (0.22, 1.05, 3.55), (88, 0, 8)))
    t.spear(21, ease="snap")
    t.spear(25, ease="hold", m=1.0)
    t.key(25, "into the street", ease="out", T=(4, -12, 0, 0, 0, 0.03), crouch=0.46, feet={"Right Leg": (0.95, 0.3), "Left Leg": (-0.85, -0.3)},
          RA=("reach", (0.22, 1.05, 2.75), (70, 0, 8)), look=(0.0, 9.0, 2.8))
    t.mark(25, "Plant")
    t.key(34, ease="sine", T=(4, -12, 0, 0, 0, 0.04), crouch=0.42, look=(0.0, 10.0, 4.2))
    t.key(70, "held behind it", ease="sine", T=(3, -12, 0, 0, 0, 0.03), crouch=0.4)
    t.key(110, ease="sine", T=(5, -12, 0, 0, 0, 0.04), crouch=0.42)
    t.key(124, ease="cubic", T=(3, -12, 0, 0, 0, 0.03), crouch=0.38)
    t.mark(124, "Release")
    t.key(136, "he straightens", ease="cubic", T=(2, -8, 0, 0, 0, 0.0), crouch=0.12, LA=(-6, 0, -10), feet=HUB["feet"],
          RA=("reach", (1.3, 1.1, 3.0), (60, 0, 24)), look=EYES)
    t.spear(136, ease="cubic")
    t.spear(140, ease="cubic", m=0.0, D=(0.2, 0.0, 1.0), s=2.7)  # lifted out, carried round in front of his right leg
    t.key(141, ease="cubic", RA=("reach", (1.9, 1.2, 3.1), (50, 0, 36)))
    t.spear(146, ease="cubic", D=(0.02, -0.04, 1.0))
    t.spear(147, ease="cubic", B=B_LEAN)
    t.key(146, ease="cubic", T=(2, -5, -2), crouch=0.08, feet=HUB["feet"], RA=("reach", (2.25, 0.5, 3.0), (30, 0, 48)))
    t.spear(154, ease="hold", m=1.0)
    t.key(154, ease="sine", T=HUB["T"], crouch=HUB["crouch"], RA=HUB["RA"], LA=HUB["LA"])
    t.key(170)
    for at in RING:
        t.stand_ins.append(("shade", at))


def hit(t):
    """It lands on his chest and he gives it a step's worth of nothing: his shoulders rock back, his head ticks, his
    fist stays on the spear, and the spear stays where it is. A wall takes a hit."""
    t.key(0, ease="out")
    t.key(3, "struck", T=(-9, -2, -2, 0, 0, -0.15), H=(-10, 4, 0), LA=(18, 0, -22), crouch=0.12,
          RA=("reach", (2.3, 0.3, 2.82), (24, 0, 48)))
    t.key(8, ease="sine", T=(-5, -4, -3, 0, 0, -0.08), H=(-3, 2, 0), LA=(8, 0, -14))
    t.key(22, T=HUB["T"], look=EYES, H=(0, 0, 0), RA=HUB["RA"], LA=HUB["LA"], crouch=HUB["crouch"])


SIT = dict(T=(-18, -6, 4, 0.35, 0, -0.55), feet={"Right Leg": None, "Left Leg": None}, RL=(96, 0, 6), LL=(86, 0, -8),
           crouch=0.0, lift=0.0, look=(0.0, 9.0, 3.6), H=(0, 0, 0), RA=(20, 0, 30), LA=(-48, 0, -16))


def down(t):
    """It takes him off his feet. His fist comes off the shaft, and he goes down hard on his back side beside it,
    propped on his left hand, head up, still looking at what hit him. The spear stays standing in the street. It
    shivers once and is still."""
    t.key(0, ease="out")
    butt, D = t.line_now()
    lean = tuple(round(x, 4) for x in stage_of(D))
    t.spear(2, ease="cubic", h=1.0, D=lean)
    t.spear(6, h=0.0)  # let go: it stands where it stood
    t.key(5, "the blow", T=(-16, -4, 0, 0, 0, -0.35), H=(-12, 0, 0), RA=(40, 0, 40), LA=(30, 0, -20), crouch=0.15)
    t.key(14, "off his feet", ease="in", T=(-30, -6, 2, 0.15, 0, -0.5), feet={"Right Leg": None, "Left Leg": None},
          RL=(46, 0, 4), LL=(38, 0, -6), lift=0.5, RA=(52, 0, 36), LA=(-10, 0, -24))
    t.key(22, "down beside it", ease="out", **{**SIT, "T": (-26, -6, 4, 0.35, 0, -0.55), "lift": 0.05})
    t.mark(22, "Land")
    t.key(30, ease="sine", **SIT)
    t.key(68, "held", ease="hold")
    t.key(70)
    for f, lean_by in ((6, 0.0), (10, 0.05), (15, -0.035), (21, 0.018), (28, 0.0)):  # the shiver: the top sways and settles
        t.spear(f, ease="sine", D=(lean[0] + lean_by, lean[1] - lean_by * 0.5, lean[2]))
    DOWN["lean"] = lean


DOWN = {}


def up(t):
    """He reaches up for the shaft, takes it, and hauls himself up it hand over fist, the spear taking his weight and
    not giving. On his feet, he leans on it again as if nothing happened."""
    lean = DOWN.get("lean", (0.0, 0.0, 1.0))
    t.spear(0, h=0.0, D=lean)
    t.key(0, **SIT)
    t.key(12, "for the shaft", ease="cubic", T=(-10, -10, 6, 0.35, 0, -0.5), RA=("shaft", 2.0, (130, 0, 40)), H=(0, 0, 0),
          look=(2.3, 0.5, 3.6))
    t.key(26, "up it", ease="in", T=(22, -12, 2, 0.15, 0, 0.0), feet={"Right Leg": (0.85, 0.15), "Left Leg": (-0.8, -0.12)},
          crouch=0.2, RA=("shaft", 2.6, (80, 0, 46)), LA=(10, 0, -20), look=(0.0, 8.0, 3.0))
    t.key(40, "on his feet", ease="out", T=(6, -6, -3), crouch=0.12, RA=("shaft", 2.75, (30, 0, 48)), LA=(-4, 0, -10), look=EYES)
    t.spear(42, ease="sine", h=0.0)
    t.spear(46, h=1.0)
    t.key(46, ease="sine", RA=HUB["RA"])
    t.key(60, T=HUB["T"], crouch=HUB["crouch"], LA=HUB["LA"])


YOU = (-6.0, 9.0, 4.8)  # the Reveal's camera, out front and to his left


def reveal(t):
    """He comes down out of the shard with the spear upright in his fist, lands low, and rises. One beat: he lifts the
    spear a hand's width and drives it into the street by his foot. Then he leans on it, and looks at you, as if he'd
    been waiting there the whole time."""
    t.spear(0, m=0.0, h=1.0, D=(0.0, 0.02, 1.0), s=2.2)
    t.key(0, "he comes down", T=(4, -4, 0), crouch=0.0, lift=4.4, feet={"Right Leg": None, "Left Leg": None},
          RL=(18, 0, 3), LL=(-6, 0, -3), H=(14, 0, 0), RA=("reach", (2.1, 0.5, 2.9), (26, 0, 46)), LA=(20, 0, -30))
    t.key(14, "lands low", ease="in", T=(26, -4, -2), crouch=0.45, lift=0.0, feet=HUB["feet"], H=(8, 0, 0),
          RA=("reach", (2.15, 0.6, 2.5), (40, 0, 46)), LA=(24, 0, -26))
    t.mark(14, "Land")
    t.key(20, ease="out", T=(30, -4, -2), crouch=0.5)
    t.key(40, "and rises", ease="sine", T=(4, -5, -2), crouch=0.08, look=YOU, H=(0, 0, 0), LA=HUB["LA"],
          RA=("reach", (2.25, 0.5, 2.95), (26, 0, 48)))
    t.spear(40, ease="sine")
    t.spear(50, ease="snap", s=2.9)  # lifted a hand's width
    t.key(50, "lifts it", ease="snap", T=(0, -5, -2), crouch=0.02, RA=("reach", (2.25, 0.5, 3.2), (30, 0, 48)))
    t.spear(54, ease="hold", m=1.0, B=B_LEAN)
    t.key(54, "into the street", ease="out", T=(8, -5, -4), crouch=0.16, RA=("reach", HAND_LEAN, (24, 0, 48)))
    t.mark(54, "Plant")
    t.key(64, ease="sine", T=(4, -5, -3), crouch=0.1)
    t.key(90, "and at you", ease="sine", T=HUB["T"], crouch=HUB["crouch"], look=YOU, H=(0, 0, -5))
    t.mark(96, "Name")
    t.key(150, ease="sine", look=YOU, H=(0, 0, -5))


# the bay's post, ahead and to his left: his left palm rests on its cap, before his own shoulder, since an R6 arm
# reaching in past its shoulder sinks into the chest, and Work is seen from before him
POST = (-1.7, 1.75)  # his chest turns 6 degrees toward it, so it stands a little out from his shoulder's line


def work(t):
    """A shift at the bay, his way: he's the wire. The spear planted by his foot, his left palm flat on the post, his
    eyes shut, he stands and lets it run through him. Once a loop he lifts the spear a hand's width and knocks it down
    on the plate, once, and the post takes the pulse. Nothing else: a man standing in the rain on purpose."""
    t.loop = True
    palm = ("reach", (POST[0], POST[1] - 0.1, 2.95), (70, 0, -8))
    rest = dict(T=(6, 6, -2), crouch=0.1, look=(-0.4, 4.0, 2.6), H=(0, 0, 0), LA=palm, RA=("reach", HAND_LEAN, (24, 0, 48)))
    t.key(0, "the wire", ease="sine", **rest)
    t.key(60, ease="sine", T=(5, 6, -2), crouch=0.08)
    t.key(120, ease="sine", T=(7, 6, -2), crouch=0.11)
    t.key(160, ease="cubic", T=(6, 6, -2), crouch=0.1)
    t.spear(160, ease="cubic")
    t.spear(176, ease="snap", m=0.0, D=(0.0, 0.0, 1.0), s=2.9)
    t.key(176, "lifts it", ease="snap", T=(4, 5, -2), crouch=0.04, RA=("reach", (2.3, 0.45, 3.2), (30, 0, 48)))
    t.spear(180, ease="hold", m=1.0, B=B_LEAN)
    t.key(180, "and knocks", ease="out", T=(8, 6, -3), crouch=0.14, RA=("reach", HAND_LEAN, (24, 0, 48)))
    t.mark(180, "Pump")
    t.key(200, ease="sine", T=(6, 6, -2), crouch=0.1)
    t.key(240, **rest)
    t.stand_ins.append(("post", POST))


CLIPS = {"Idle": idle, "Combo": combo, "GroundWire": ground_wire, "Hit": hit,
         "Down": down, "Up": up, "Reveal": reveal, "Work": work}
# Each clip's cameras: where they look (a stage place), how far off, and the pose sheet's rows (the first is the
# blocking's). The spear stands eight studs, so every view stands further off than Pip's.
VIEWS = {"Idle": ((0.7, 0.2, 3.9), 19.0, ("game", "side", "front")),
         "Combo": ((0.4, 1.4, 3.9), 21.0, ("game", "side", "front")),
         "GroundWire": ((0.4, 1.2, 3.9), 22.0, ("game", "side", "front")),
         "Hit": ((0.7, 0.2, 3.9), 19.0, ("game", "side")),
         "Down": ((0.9, -0.4, 3.2), 19.0, ("game", "side", "front")),
         "Up": ((0.9, -0.4, 3.2), 19.0, ("game", "side", "front")),
         "Reveal": ((0.7, 0.2, 5.2), 22.0, ("front", "side", "game")),
         "Work": ((0.3, 0.8, 3.9), 19.0, ("front", "side", "game"))}  # the bay is seen from before him, as Pip's Work
VIEW_ANGLES = {"game": GAME, "side": SIDE, "front": FRONT}


# --- outputs -----------------------------------------------------------------------------------------------------------

def stand_ins(takes):
    """The grey Shades and the bay's post, each shown only over its own clip's frames."""
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
    scene.render.resolution_x, scene.render.resolution_y = 300, 400
    scene.render.stamp_font_size = 15
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(take.beats))
    print(f"wrote {path}")


def film(scene, cams, take, out):
    """The clip in motion from its first view (the player's camera for the fight), every other frame of its 60 a
    second, as film_<Clip>.mp4 at 30: the timing's read before Faber's install, where the game's own camera judges it.
    Each frame is stamped with its time, and a beat's frame with its label."""
    import frames_to_movie
    folder = out / f"film_{take.name}"
    folder.mkdir(exist_ok=True)
    for old in folder.glob("*.png"):
        old.unlink()
    scene.camera = cams[take.name, VIEWS[take.name][2][0]]
    scene.render.resolution_x, scene.render.resolution_y = 360, 480
    scene.render.use_stamp = scene.render.use_stamp_note = True
    for flag in ("date", "render_time", "camera", "lens", "scene", "filename", "frame", "time"):
        setattr(scene.render, f"use_stamp_{flag}", False)
    scene.render.stamp_font_size = 16
    beats = dict(take.beats)
    for n, f in enumerate(range(0, take.end + 1, 2)):
        scene.frame_set(take.start + f)
        label = beats.get(f, beats.get(f - 1, ""))
        scene.render.stamp_note_text = f"{take.name} {f / FPS:.2f} s  {label}"
        scene.render.filepath = str(folder / f"{n:04d}.png")
        bpy.ops.render.render(write_still=True)
    frames_to_movie.assemble(folder, out / f"film_{take.name}.mp4", 30)


def blocking_sheet(scene, cams, takes, out):
    """Every clip's key poses from its first view (the player's camera for the fight), a row a clip."""
    columns = max(len(t.beats) for t in takes)
    blank = r6.fixed_camera(scene, Vector((0, 50, 0)), Vector((0, 100, 0.01)), 38.0, "Blank")
    shots = []
    for take in takes:
        cam = cams[take.name, VIEWS[take.name][2][0]]
        row = [(cam, take.start + f, f"{take.name} {f}: {label}") for f, label in take.beats]
        shots += row + [(blank, take.start, "")] * (columns - len(row))
    scene.render.resolution_x, scene.render.resolution_y = 250, 320
    scene.render.stamp_font_size = 13
    path = r6.render_shots(scene, shots, out / "watt_blocking.png", columns=columns)
    print(f"wrote {path}")


def arc_sheet(scene, rig, cams, take, rest, out):
    """One dot a frame where the blade's point (pale pink) and the butt (amber) are through the clip, over the body at
    its middle beat, from its first two views: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)
    sp = rest["spear"]
    local_butt = sp_butt_rest_local(rest)
    local_tip = local_butt + sp["along"] * sp["tip"]

    def at(rig, joint):
        return r6.to_roblox(rig.parts[joint].matrix_world)

    dots = r6.path_dots(rig, frames, [(SPEAR, tuple(local_tip))], colour=(1.0, 0.7, 0.91), radius=0.08, name="Tip", at=at)
    dots += r6.path_dots(rig, frames, [(SPEAR, tuple(local_butt))], colour=(1.0, 0.82, 0.25), radius=0.06, name="Butt", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    scene.render.resolution_x, scene.render.resolution_y = 560, 640
    path = r6.render_shots(scene, [(cams[take.name, view], beat, f"{take.name}: one dot a frame, {view}")
                                   for view in VIEWS[take.name][2][:2]], out / f"arcs_{take.name}.png", columns=2)
    for dot in dots:
        bpy.data.objects.remove(dot, do_unlink=True)
    print(f"wrote {path}")


def bare_sheet(scene, rig, take, undress, out, tiles=20):
    """What the content check asks of every clip: stepped through on the bare rig, the costume off, from his side and
    the three-quarter."""
    step = max(1, math.ceil((take.end + 1) / tiles))
    frames = list(range(0, take.end + 1, step))
    undress(True)
    cams = [(view, r6.body_camera(scene, rig, take.start, az, el, distance=14.0, height=3.0, name=f"bare {view}"))
            for view, (az, el) in (("side", SIDE), ("quarter", QUARTER))]
    scene.render.resolution_x, scene.render.resolution_y = 190, 230
    path = r6.render_shots(scene, [(cam, take.start + f, f"{f}") for _, cam in cams for f in frames],
                           out / f"bare_{take.name}.png", columns=len(frames))
    undress(False)
    print(f"wrote {path} (every {step} frames; his side, then the three-quarter)")


def slung_sheet(scene, rig, out):
    """The spear slung, as the walk carries it (no clip keys it), from his side and his back, over dusk and over a
    bright ground, at 64 px shown four times its size: the content check's look at the discs against his hair."""
    for joint in (SPEAR,):
        rig.joints[joint].animation_data_clear()
        rig.joints[joint].matrix_basis = Matrix.Identity(4)
    for part in r6rig.PARTS:
        rig.joints[part].animation_data_clear()
        rig.joints[part].matrix_basis = Matrix.Identity(4)
    floor, shading = bpy.data.materials["Floor"], scene.display.shading
    dusk = (tuple(floor.diffuse_color), tuple(shading.background_color))
    views = [("side", 90.0), ("back right", 135.0), ("back", 180.0), ("back left", 225.0), ("left", 270.0), ("game", GAME[0])]
    cams = [r6.body_camera(scene, rig, 0, az, GAME[1], distance=14.0, height=3.4, name=f"slung {name}") for name, az in views]
    scene.render.resolution_x, scene.render.resolution_y = 64, 64
    rows = []
    for ground, sky in (dusk, ((0.86, 0.84, 0.8, 1.0), (0.78, 0.84, 0.92))):
        floor.diffuse_color, shading.background_color = ground, sky
        path = r6.render_shots(scene, [(cam, 0, "") for cam in cams], out / "slung_row.png", columns=len(cams))
        rows.append(np.repeat(np.repeat(rs.load(path), 4, axis=0), 4, axis=1))
        Path(path).unlink()
    floor.diffuse_color, shading.background_color = dusk
    sheet = np.concatenate(rows, axis=0)
    sheet[..., 3] = 1.0
    rs.save(sheet, out / "slung.png")
    print(f"wrote {out / 'slung.png'} (dusk, then a bright ground; across: {', '.join(n for n, _ in views)})")


def report(name, take, n, checks, fade) -> str:
    near = "; ".join(f"{part} {d:.2f} at {f}" for part, (d, f) in n["body"].items())
    return (f"{name}: {take.end + 1} frames, {take.end / FPS:.2f} s{' (a loop)' if take.loop else ''}\n"
            f"  the discs and the blade, nearest his head and hair (studs, past 0 is clear): {n['head'][0]:.2f} at {n['head'][1]}\n"
            f"  the same as the game fades the clip in from the walk's slung spear, or out to it: {fade[0]:.2f} ({fade[1]})\n"
            f"  the spear's nearest each part of him, less a fist's width at a holding hand: {near}\n"
            f"  the butt at its lowest over the floor: {n['butt_low'][0]:.2f} at {n['butt_low'][1]}; the blade's point: "
            f"{n['tip_low'][0]:.2f} at {n['tip_low'][1]}\n"
            f"  the butt's most slide in a frame while it's on the street: {n['slide'][0]:.3f} at {n['slide'][1]}; the point's "
            f"fastest: {n['speed'][0]:.2f} studs a frame at {n['speed'][1]}\n"
            f"  a hand that can't reach the shaft, by how far (studs): right {n['miss']['R'][0]:.2f} at {n['miss']['R'][1]}, "
            f"left {n['miss']['L'][0]:.2f} at {n['miss']['L'][1]}\n"
            f"  his chin at its lowest against the torso, of {NOD_DOWN:.0f} degrees: {n['nod'][0]:.1f} at {n['nod'][1]}\n"
            f"  a leg's widest swing: {checks['swing'][0]:.0f} degrees at {checks['swing'][1]}\n"
            f"  the longest an arm is nearly still at 20 to 70 degrees up, of {HELD} frames: right {checks['held']['Right Arm'][0]} "
            f"(to {checks['held']['Right Arm'][1]}), left {checks['held']['Left Arm'][0]} (to {checks['held']['Left Arm'][1]})\n"
            f"  each arm at its highest: right {checks['high']['Right Arm'][0]:.0f} degrees at {checks['high']['Right Arm'][1]}, "
            f"left {checks['high']['Left Arm'][0]:.0f} at {checks['high']['Left Arm'][1]}\n")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "film", "export", "audit") else "poses"
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    if "Up" in wanted and "Down" not in wanted:
        wanted.append("Down")  # Up starts where Down leaves the spear
    scene, rig, costume, undress, feet, ctl, motors, rest = build()
    sp = rest["spear"]
    print(f"the spear: {sp['length']:.2f} studs, the grip {sp['grip']:.2f} up from the butt, the middle disc {sp['head']:.2f}, "
          f"the point {sp['tip']:.2f}; the arms reach {rest['reach']['Right Arm']:.2f} from the shoulder")
    takes = {}
    for i, name in enumerate(CLIPS):
        if name in wanted:
            takes[name] = take = Take(rig, feet, ctl, name, 1000 * i, rest)
            CLIPS[name](take)
            for line in take.warned:
                print("  " + line)
    rc.ground(rig, feet, list(takes.values()))
    rc.lift(rig, ctl["lift"], list(takes.values()))
    numbers = props(rig, ctl, motors, rest, list(takes.values()))
    stand_ins(list(takes.values()))
    cams = cameras(scene, list(takes.values()))
    facts = {}
    for name, take in takes.items():
        notes = report(name, take, numbers[name], audit(rig, take), blend_from_slung(rig, motors, rest, take))
        print(notes, end="")
        facts[name] = {"File": f"Watt_{name}.json", "Frames": take.end + 1, "Seconds": round(take.end / FPS, 3), "Loop": take.loop,
                       "Markers": [[round(t * FPS), label] for t, label in take.markers]}
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        if mode == "film":
            film(scene, cams, take, out)
            continue
        heard = io.StringIO()
        with contextlib.redirect_stdout(heard):
            # the Name is the game's: Author.SaveBaked reads Anim_Watt<Clip> and checks the clip is named the same
            r6.export(rig, out / f"Watt_{name}.json", "Watt", f"Watt{name}", take.start, take.start + take.end,
                      markers=take.markers, source="tools/blender/watt_clips.py", extra={"Loop": take.loop})
        print(heard.getvalue(), end="")
        if mode == "audit":
            continue
        arc_sheet(scene, rig, cams, take, rest, out)
        bare_sheet(scene, rig, take, undress, out)
        view = cams[name, VIEWS[name][2][0]]
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame, view=view: view, bare=SIDE[0], strip=strip, undress=undress,
                       notes=notes + heard.getvalue())
        print(f"wrote {out / f'pack_{name}.png'}")
    if mode == "poses" and len(takes) > 1:
        blocking_sheet(scene, cams, list(takes.values()), out)
    if mode == "export" and len(takes) == len(CLIPS):
        slung_sheet(scene, rig, out)
    if mode != "poses" and len(takes) == len(CLIPS):
        (out / "Watt.clips.json").write_text(json.dumps({"Fps": FPS, "Clips": facts}, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out / 'Watt.clips.json'}")


if __name__ == "__main__":
    main()
