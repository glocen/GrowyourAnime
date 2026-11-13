"""The Lamplighter's clips on the Shade's R6 rig, its model riding it (AR7, delivery 3).

blender.exe -b --factory-startup --python tools/blender/lamplighter_clips.py -- <out_dir> [poses|family] [clip ...]

- poses (the default): each clip's key poses from the fight's camera and from the side, a sheet a clip, and one blocking
  sheet of every clip's poses from the fight's camera, with the checks' numbers printed.
- family: the Shade's own clips (shade_clips.py) as the game would play them on the keeper, the pole and the lantern
  riding the right arm unkeyed: what each does to them, measured, on one sheet.

Needs lamplighter_model.py's output (lamplighter_model.blend, Lamplighter.recipe.json and the maps) in MODEL. The keying
is rook_clips.py's, as the Shade's: every clip at 60 fps on its own stretch of one timeline, starting from its hub; feet
given as places on the floor, or legs by their angles (the walk's). Stage directions: right, forward, up, in studs, from
where it stands, in the Shade's units: the game scales the keeper by 1.5, so the game's distances are divided by it here.

Three tracks a clip, keyed apart:
- the body (Take.key);
- the pole (Take.pole): the R6 arm has no wrist and the pole's joint is at the grip, so its line always passes through
  the grip and turns about it. Planted, its foot is on a floor place and the pole slides through the grip as the arm
  moves; held, its line is leant off upright toward a heading with the grip a length up it. Its crook opens toward a
  heading;
- the lantern (Take.lamp): hung from the hook's tip, plumb, or swung off plumb by the keys.

How it moves: it's the street's master, and it's in no hurry. Its weight is on the pole whenever the pole is down, and
everything it does starts from the pole: the try's stamp, the swing, the signature's plant.
"""
import json
import math
import re
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lamplighter_sheet as lsh  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_clips as sc  # noqa: E402
import shade_sheet as ss  # noqa: E402

FPS = rc.FPS
NAME = "Lamplighter"
MODEL = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "lamplighter" / "model"
POLE, LAMP = f"{NAME}_Pole", f"{NAME}_Lantern"
W = rc.W
SCALE = lsh.SCALE
ACTIONS = "src/shared/Definitions/Actions.luau"
FIGHT, SIDE = (20.0, 2.0), (-85.0, 6.0)  # the fight's camera, behind the lead with the keeper turned to it, from a touch
# below the mask (TR2's framing), and its left side, clear of the lantern
STRIDE = 25.0  # degrees a leg swings each way in the keeper's walk: the recipe's stride, 27, holds the long coat's hem
FERRULE = 0.12  # the pole's foot's radius
POLE_TOP = lsh.POLE_TOP  # the pole's length, foot to top
HOLD = (1.0, 6.0)  # studs up the pole from its foot that the grip can close on: over the ferrule, under the crook
LAMP_R, LAMP_DROP = lsh.LAMP[0], lsh.LAMP[1] / 2 + lsh.HOOP  # the drum's radius, and its middle to its foot
NOD = rc.NOD
GRIP = (0.3, -1.28, 0.0)  # the grip in the right arm's frame: set from the recipe as the rig is built


def row_number(anchor, name) -> float:
    """The first `name = number` after `anchor` in Definitions/Actions: the game's own numbers, never typed again."""
    text = (r6.REPO / ACTIONS).read_text(encoding="utf-8")
    return float(re.search(rf"\b{name}\s*=\s*(-?[\d.]+)", text[text.index(anchor):]).group(1))


SWING = r6.luau_table(ACTIONS, 'Id = "KeeperSwing"')  # Length, and its Beats: Wind, Strike, Recover, in seconds
REACH = row_number('Id = "KeeperSwing"', "Range") / SCALE  # how far off the lead stands when the keeper swings
LEAD = (0.0, REACH, 3.0)  # the lead's face, a Voidkin's height over the floor, in the keeper's units
# You: the player's camera behind the lead (TR2's zoom 10 and pitch 10 from the lead's face at 4.5 studs), in the keeper's
# units. The challenge's lift looks at you, not your fighter: you're the one who asked
YOU = (0.0, REACH + 10.0 * math.cos(math.radians(10)) / SCALE, (4.5 + 10.0 * math.sin(math.radians(10))) / SCALE)


# --- the rig with the model on it -----------------------------------------------------------------------------------

def rest_frames(recipe) -> dict:
    """The pole's and the lantern's frames as they rest on the hanging arm, from the recipe's points (Roblox)."""
    points = {p["name"]: Vector(p["at"]) for p in recipe["points"]}
    pivots = {p["name"]: Vector(p["pivot"]) for p in recipe["pieces"] if "motor" in p}
    f0, g0, t0, l0 = points["PoleFoot"], pivots[POLE], pivots[LAMP], points["Lantern"]
    a0 = (g0 - f0).normalized()
    o0 = (t0 - f0) - a0 * (t0 - f0).dot(a0)
    return {"F0": f0, "G0": g0, "T0": t0, "a0": a0, "o0": o0.normalized(), "h0": (l0 - t0).normalized(),
            "cord": (l0 - t0).length, "frame": pole_frame(f0, a0, o0.normalized()), "grip0": (g0 - f0).length}


def pole_frame(foot: Vector, up: Vector, opening: Vector) -> Matrix:
    """A frame on the pole: its foot, the pole's line up it, the crook's opening across it. Laid flat along its own
    opening, the crook turns down instead."""
    x = opening - up * opening.dot(up)
    if x.length < 0.2:
        x = Vector((0, -1, 0)) - up * -up.y
    x = x.normalized()
    z = x.cross(up)
    m = Matrix((x, up, z)).transposed().to_4x4()
    m.translation = foot
    return m


def build(out):
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    recipe = json.loads((MODEL / f"{NAME}.recipe.json").read_text())
    void, paper = rs.srgb(ss.PALETTE["VoidLift"])[:3], rs.srgb(ss.PALETTE["Paper"])[:3]
    rig = r6.build_rig(NAME, {"Torso": void, "Head": paper, "Right Arm": void, "Left Arm": void, "Right Leg": void,
                              "Left Leg": void, "Face": rs.srgb(ss.PALETTE["Ink"])[:3]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    blend = MODEL / f"{NAME.lower()}_model.blend"
    if not blend.exists():
        raise SystemExit(f"No {blend}: run lamplighter_model.py first")
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith(f"{NAME}_")]
    costume = {o.name: o for o in dst.objects}
    motors = {}
    for piece in recipe["pieces"]:  # the pole before the lantern: the lantern's joint is on the pole
        obj = costume[piece["name"]]
        scene.collection.objects.link(obj)
        holder = rig.parts[piece["on"]]
        if "motor" in piece:  # a joint of its own, keyed and exported under the piece's name
            local = r6.to_roblox(holder.matrix_world).inverted() @ Matrix.Translation(Vector(piece["pivot"]))
            motors[obj.name] = r6._empty(f"{NAME}.C0.{obj.name}", holder, local, 0.1)
            holder = rig.joints[obj.name] = rig.parts[obj.name] = r6._empty(f"{NAME}.J.{obj.name}", motors[obj.name], Matrix.Identity(4), 0.1)
            rig.bases[obj.name] = Matrix.Identity(4)
            rig.claws[obj.name] = obj.name
            bpy.context.view_layer.update()
        if obj.name == LAMP:
            obj.display.show_shadows = False  # as the recipe asks of the engine: CastShadow off
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:  # Workbench draws the active image node: the colour map
            nodes = slot.material.node_tree.nodes
            nodes.active = next(n for n in nodes if n.type == "TEX_IMAGE" and "Color" in n.image.name)
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects[f"{NAME}.Face"]]

    def undress(bare: bool):
        for o in costume.values():
            o.hide_render = bare
        for o in blocks:
            o.hide_render = not bare

    undress(False)
    feet = {leg: r6._empty(f"{NAME}.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    # holders of numbers, keyed like anything else, read back frame by frame once the body is keyed
    ctl = {name: r6._empty(f"{NAME}.Ctl.{name}", None, Matrix.Identity(4), 0.1) for name in ("plant", "line", "open", "lamp")}
    for empty in (*feet.values(), *ctl.values()):
        empty.location = (0, 0, 0)
    global GRIP
    grip = next(p["at"] for p in recipe["points"] if p["name"] == "Grip")
    grip_local = GRIP = tuple(r6.to_roblox(rig.parts["Right Arm"].matrix_world).inverted() @ Vector(grip))
    return scene, rig, costume, undress, feet, ctl, motors, rest_frames(recipe), grip_local


# --- the pole and the lantern, as places ----------------------------------------------------------------------------

def leant(lean, toward) -> Vector:
    """A line leant `lean` degrees off upright toward the stage heading `toward` (0 ahead, 90 to its right), Roblox."""
    a, h = math.radians(lean), math.radians(toward)
    return Vector((math.sin(a) * math.sin(h), math.cos(a), -math.sin(a) * math.cos(h)))


def heading(toward) -> Vector:
    h = math.radians(toward)
    return Vector((math.sin(h), 0.0, -math.cos(h)))


def hang(forward, right) -> Vector:
    """The lantern's line down its cord, swung `forward` degrees toward the keeper's front and `right` to its right."""
    return Matrix.Rotation(math.radians(forward), 3, "X") @ Matrix.Rotation(math.radians(right), 3, "Z") @ Vector((0, -1, 0))


def near(angle, before) -> float:
    """`angle`, turned by whole turns to lie within half a turn of `before`: keys between them turn the short way."""
    return angle + 360.0 * round((before - angle) / 360.0)


def rest_on_floor(tip, down, cord) -> tuple:
    """A lantern whose drum would go through the floor lies on it instead: its cord swung further off plumb, the way it
    already leans (toward the keeper when it hangs plumb), until the drum's lowest edge is on the floor. Returns (the
    cord's line, resting)."""
    def bottom(d):
        s = math.sqrt(max(0.0, 1.0 - d.y * d.y))
        return (tip + d * cord).y - (LAMP_DROP * abs(d.y) + LAMP_R * s)

    if bottom(down) >= 0.0:
        return down, False
    flat = Vector((down.x, 0.0, down.z))
    flat = flat.normalized() if flat.length > 0.05 else Vector((0.0, 0.0, 1.0))
    start = math.acos(max(-1.0, min(1.0, -down.y)))
    lo, hi = start, math.radians(100.0)
    for _ in range(30):
        mid = (lo + hi) / 2
        if bottom(flat * math.sin(mid) - Vector((0, 1, 0)) * math.cos(mid)) < 0.0:
            lo = mid
        else:
            hi = mid
    return flat * math.sin(hi) - Vector((0, 1, 0)) * math.cos(hi), True


def grip_at(motors) -> Vector:
    """Where the pole passes through the right cuff (its joint), Roblox world, at the current frame."""
    return r6.to_roblox(motors[POLE].matrix_world).to_translation()


# --- keying ---------------------------------------------------------------------------------------------------------

# The master's stance at its gate, the idle (research's fix 1): leaned on the planted pole, turned and tipped onto it,
# the right sleeve down and out to it as onto a staff, the left held back, the head bowed under the brim.
WAIT = {
    "T": (9, -8, -6, 0.08, 0, 0), "feet": {"Right Leg": (0.62, 0.1), "Left Leg": (-0.6, -0.24)}, "RL": (0, 0, 0),
    "LL": (0, 0, 0), "crouch": 0.06, "look": None, "H": (22, 0, 6), "RA": (46, 0, 30), "LA": (-12, 0, -10),
}  # the model's bow: 31 degrees off upright, the torso's 9 and the head's 22
# The fight's stance, the try's idle: squared to the lead, still on the pole, the head up and watching.
READY = dict(WAIT, T=(5, -6, -4, 0.05, 0, 0), crouch=0.03, look=LEAD, H=(0, 0, 4), RA=(44, 0, 28), LA=(-8, 0, -14))
POLE_HUB = {"plant": (1.9, 1.0, 1.0), "line": (0.0, 0.0, 2.66), "open": (114.0, 0.0, 0.0), "lamp": (0.0, 0.0, 0.0)}


class Take(rc.Take):
    """One clip being keyed from `start`, as rook_clips.Take, with the pole's track and the lantern's."""

    def __init__(self, rig, feet, ctl, motors, name, start, hub=WAIT):
        super().__init__(rig, feet, name, start)
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in hub.items()}
        self.ctl, self.motors, self.props = ctl, motors, dict(POLE_HUB)
        self._hold(0, None, self.props)

    def _hold(self, f, ease, values):
        frame = self.start + f
        for name, value in values.items():
            empty = self.ctl[name]
            empty.location = value
            empty.keyframe_insert("location", frame=frame)
            r6._set_interpolation(empty, frame, *rc.EASE[ease])
        self.end = max(self.end, f)
        return self

    def pole(self, f, ease=None, at=None, under=False, line=None, butt=None, grip=None, open=None):
        """Keys the pole at clip frame `f` (key the body at `f` first). `at`: its foot planted at a floor place (right,
        forward); `under`: planted straight under the grip. Held off the floor: `line` (lean, toward, grip), leant `lean`
        degrees off upright toward stage heading `toward`, the grip `grip` studs up it; or `butt` (right, forward, up),
        its foot aimed at that stage place through the grip, `grip` studs from it. `open`: the stage heading the crook
        opens toward. What isn't named holds; a heading turns the short way from the key before."""
        p = self.props
        if under or butt is not None:
            bpy.context.scene.frame_set(self.start + f)
            bpy.context.view_layer.update()
            g = grip_at(self.motors)
            if under:
                at = (round(g.x, 3), round(-g.z, 3))
            else:
                u = (g - W(*butt)).normalized()
                line = (math.degrees(math.acos(max(-1.0, min(1.0, u.y)))), math.degrees(math.atan2(u.x, -u.z)),
                        grip if grip is not None else p["line"][2])
        if at is not None:
            p["plant"] = (at[0], at[1], 1.0)
        elif line is not None:
            p["plant"] = (*p["plant"][:2], 0.0)
        if line is not None:
            p["line"] = (line[0], near(line[1], p["line"][1]), line[2])
        if open is not None:
            p["open"] = (near(open, p["open"][0]), 0.0, 0.0)
        return self._hold(f, ease, {k: p[k] for k in ("plant", "line", "open")})

    def lamp(self, f, ease=None, swing=(0.0, 0.0)):
        """Keys the lantern's swing at clip frame `f`: degrees off plumb toward the keeper's front and its right."""
        self.props["lamp"] = (*swing, 0.0)
        return self._hold(f, ease, {"lamp": self.props["lamp"]})

    def key(self, f, label=None, ease=None, **changes):
        """Keys the body at clip frame `f`, as rook_clips.Take.key. Changes: T (pitch, turn, roll, right, _, forward),
        feet {leg: (right, forward), or None for a leg given by its angles in RL / LL}, crouch, look (a stage place) or
        H (the head's angles), RA / LA (angles, or ("reach", place, hint))."""
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
        for leg, empty in self.feet.items():  # where each foot stands and how low it sits, for the pass between keys
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
            if a[0] in ("reach", "grip"):  # the cuff's end, or the right cuff's grip, put on a stage place
                local = GRIP if a[0] == "grip" else rc.HAND
                rest[rc.SHORT[arm]] = r6.reach(rig, rc.SHORT[arm], local, W(*a[1]), a[2])
            else:
                rest[rc.SHORT[arm]] = a
        r6._key_parts(rig, frame, rest, *interp)
        self.end = max(self.end, f)
        if label:
            self.beats.append((f, label))
        return self


class Skin:
    """The model's pieces as surfaces to measure the pole and the lantern against (lyric_clips.Skin's way): rigid
    pieces, each built once in its own frame. The right arm holds the pole, so it isn't one."""
    PARTS = {"Torso": f"{NAME}_Torso", "Head": f"{NAME}_Head", "Left Arm": f"{NAME}_LeftArm",
             "Right Leg": f"{NAME}_RightLeg", "Left Leg": f"{NAME}_LeftLeg"}

    def __init__(self):
        self.pieces = {}
        for part, name in self.PARTS.items():
            obj = bpy.data.objects[name]
            mesh = obj.data
            self.pieces[part] = (obj, BVHTree.FromPolygons([v.co.copy() for v in mesh.vertices],
                                                           [tuple(p.vertices) for p in mesh.polygons]))

    def gap(self, points, part, radius) -> float:
        """How far a run of Roblox world points stays off the piece's surface, less `radius`; a stretch through the
        surface counts as -0.01 or less."""
        obj, tree = self.pieces[part]
        inv = obj.matrix_world.inverted()
        local = [inv @ (r6.M @ Vector(p)) for p in points]
        out = min(tree.find_nearest(q)[3] for q in local) - radius
        for a, b in zip(local, local[1:]):
            span = (b - a).length
            if span > 1e-6 and tree.ray_cast(a, (b - a) / span, span)[0] is not None:
                return min(out, -0.01)
        return out


def props(rig, ctl, motors, rest, takes) -> dict:
    """The last pass, once the body is keyed on every frame: the pole solved through the grip and the lantern hung
    from the hook's tip, each keyed on every frame. Returns each clip's numbers."""
    scene, facts, skin = bpy.context.scene, {}, Skin()
    for take in takes:
        n = {"foot": (9.0, 0), "grip": [9.0, -9.0], "lamp_low": (9.0, 0), "near": {part: (9.0, 0) for part in Skin.PARTS},
             "lamp_near": {part: (9.0, 0) for part in Skin.PARTS}, "plumb": (0.0, 0), "rests": [], "at": {}}
        marks = {round(s * FPS): name for s, name in take.markers}
        for f in range(take.end + 1):
            frame = take.start + f
            scene.frame_set(frame)
            v = {name: Vector(empty.location) for name, empty in ctl.items()}
            g = grip_at(motors)
            w = min(max(v["plant"].z, 0.0), 1.0)
            # planted and held blend by the pole's direction and the grip's length, never by the foot's place: a
            # foot slid between two places would swing the pole through the body
            plant = W(v["plant"].x, v["plant"].y)
            planted = (g - plant).normalized() if (g - plant).length > 1e-4 else Vector((0, 1, 0))
            held = leant(v["line"].x, v["line"].y)
            u = held.slerp(planted, w) if held.dot(planted) > -0.999 else planted
            foot = g - u * ((1 - w) * v["line"].z + w * (g - plant).length)
            given = foot.y
            for _ in range(3):  # the foot stands on its rim, never through the floor: leant, the rim's edge is on it
                u = (g - foot).normalized()
                foot.y = max(given, FERRULE * math.sqrt(max(0.0, 1.0 - u.y * u.y)))
            u = (g - foot).normalized()
            # the crook opens toward its heading and a little down: upright it's the model's, laid out it hangs low
            placed = pole_frame(foot, u, heading(v["open"].x) - Vector((0, 0.35, 0))) @ rest["frame"].inverted()
            r6.key_matrices(rig, frame, {POLE: r6.to_blender(r6.to_roblox(motors[POLE].matrix_world).inverted()
                                                             @ placed @ Matrix.Translation(rest["G0"]))})
            bpy.context.view_layer.update()
            tip = placed @ rest["T0"]
            turned = placed.to_3x3()
            down, resting = rest_on_floor(tip, hang(v["lamp"].x, v["lamp"].y), rest["cord"])
            if resting:
                n["rests"].append(f)
            lamp = (turned @ rest["h0"]).rotation_difference(down).to_matrix() @ turned
            joint = Matrix.Translation(tip) @ lamp.to_4x4()
            r6.key_matrices(rig, frame, {LAMP: r6.to_blender(r6.to_roblox(motors[LAMP].matrix_world).inverted() @ joint)})
            bpy.context.view_layer.update()
            # the numbers
            grip = (g - foot).length
            n["grip"] = [min(n["grip"][0], grip), max(n["grip"][1], grip)]
            low = foot.y - FERRULE * math.sqrt(max(0.0, 1.0 - u.y * u.y))
            top = foot + u * POLE_TOP
            n["foot"] = min(n["foot"], (min(low, top.y), f))
            middle = tip + down * rest["cord"]
            bottom = middle.y - (LAMP_DROP * abs(down.y) + LAMP_R * math.sqrt(max(0.0, 1.0 - down.y * down.y)))
            n["lamp_low"] = min(n["lamp_low"], (bottom, f))
            n["plumb"] = max(n["plumb"], (math.degrees(down.angle(Vector((0, -1, 0)))), f))
            if f in marks or f == 0:  # where the grip and the lantern are on each marker, as stage places
                n["at"][f] = (marks.get(f, "start"), (g.x, -g.z, g.y), (middle.x, -middle.z, bottom))
            ends = [foot + u * s for s in np.linspace(0.0, POLE_TOP, 24) if abs(s - grip) > 0.5]
            for part in Skin.PARTS:
                n["near"][part] = min(n["near"][part], (skin.gap(ends, part, 0.1), f))
                n["lamp_near"][part] = min(n["lamp_near"][part], (skin.gap([middle], part, LAMP_R), f))
        facts[take.name] = n
    return facts


# --- the clips ------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses.

def idle(t):
    """The master waits at the end of its street as it has every night: hung on the planted pole, the head bowed under
    the brim as if it dozed on its feet. Once a breath the shoulders rise and settle and the lantern turns a hair on its
    cord; once a loop the head sinks lower and catches itself. It has all night."""
    t.loop = True
    t.key(0, "leaning on it", ease="sine")
    t.pole(0, under=True)
    t.key(70, "a breath in", ease="sine", T=(7, -8, -5, 0.08, 0, 0), crouch=0.02, H=(20, 0, 6), RA=(48, 0, 30))
    t.key(140, ease="sine", T=(10, -8, -6.5, 0.1, 0, 0), crouch=0.08, H=(24, 0, 6), RA=WAIT["RA"])
    t.key(176, "it sinks under the brim", ease="cubic", H=(32, 2, 7))
    t.key(188, "and catches itself", ease="out", H=(16, -1, 5))
    t.key(240, T=WAIT["T"], crouch=WAIT["crouch"], H=WAIT["H"], RA=WAIT["RA"])
    t.lamp(0, "sine")
    t.lamp(120, "sine", (2.5, 1.5))
    t.lamp(240)


def ready(t):
    """In the ring it watches you and nothing else. Still on the pole, squared to you, the head up: it breathes
    slower than you do."""
    t.loop = True
    t.key(0, "watching you", ease="sine")
    t.pole(0, under=True)
    t.key(90, "a breath in", ease="sine", T=(3.5, -6, -3.5, 0.05, 0, 0), crouch=0.0, RA=(46, 0, 28))
    t.key(180, T=READY["T"], crouch=READY["crouch"], RA=READY["RA"])
    t.lamp(0, "sine")
    t.lamp(90, "sine", (1.5, -1.0))
    t.lamp(180)


def challenge(t):
    """You've asked, and it has heard. Nothing moves but the shoulders, which rise with a breath; then the head comes up
    out from under the brim, slow, until it looks at you. The pole is lifted a hand and stamped down once, the lantern
    jumping on its cord, and it stands squared to you."""
    t.key(0, "it waits")
    t.pole(0, under=True)
    t.key(18, "it hears you", ease="sine", T=(6, -8, -5, 0.08, 0, 0), crouch=0.0, H=(20, 0, 6), RA=(48, 0, 30))
    t.key(44, "it looks at you", ease="out", T=(4, -7, -4.5, 0.06, 0, 0), look=YOU, H=(0, 0, 4))
    t.mark(44, "Lift")
    t.key(52, ease="in", RA=(58, 0, 30), crouch=-0.02)
    t.pole(52, ease="in", line=(0.0, 0.0, 2.3))
    t.key(58, "the stamp", ease="out", T=(7, -6, -4, 0.05, 0, 0), crouch=0.09, RA=READY["RA"])
    t.pole(58, under=True)
    t.mark(58, "Stamp")
    t.key(70, ease="sine", T=(5, -6, -4, 0.05, 0, 0), crouch=0.04)
    t.key(92, "then at your fighter", ease="sine", T=READY["T"], crouch=READY["crouch"], LA=READY["LA"], look=LEAD,
          H=READY["H"])
    t.lamp(0)
    t.lamp(52, "out", (-6, 0))
    t.lamp(60, "sine", (10, 3))
    t.lamp(72, "sine", (-4, -1))
    t.lamp(92)


def walk(t):
    """It walks its street as it has every night, on its round: the pole goes ahead and is planted, and the body is
    carried up to it and past it, the lantern swinging after the hook. Its step is the long coat's: a leg swings no
    wider than the hem lets it."""
    t.loop = True
    loose = {"Right Leg": None, "Left Leg": None}
    s = STRIDE
    t.key(0, "the left foot and the pole land", ease="sine", feet=loose, T=(12, -6, -3), RL=(-s, 0, 0), LL=(s, 0, 0),
          H=(4, 4, 4), RA=(52, 0, 26), LA=(-16, 0, -10))
    t.key(16, "carried up to it", ease="sine", T=(10, -3, -1), RL=(0, 0, 0), LL=(0, 0, 0), RA=(30, 0, 27), LA=(-8, 0, -10))
    t.key(32, "the right foot lands", ease="sine", T=(12, 1, 1), RL=(s, 0, 0), LL=(-s, 0, 0), RA=(8, 0, 27), LA=(4, 0, -10))
    t.key(48, "the pole goes ahead", ease="sine", T=(10, -3, -2), RL=(0, 0, 0), LL=(0, 0, 0), RA=(34, 0, 27), LA=(-6, 0, -10))
    t.key(64, T=(12, -6, -3), RL=(-s, 0, 0), LL=(s, 0, 0), H=(4, 4, 4), RA=(52, 0, 26), LA=(-16, 0, -10))
    scene = bpy.context.scene
    scene.frame_set(t.start)
    r6._refresh()
    a, b = sc.leg_ends(t.rig)
    per_frame = 2 * abs(a.z - b.z) / 64  # the floor covered in a loop, a frame's worth: a planted foot goes back by it
    t.pole(0, under=True)
    x, y = t.props["plant"][:2]
    t.pole(28, "lin", at=(x, y - per_frame * 28))
    t.pole(36, "sine", line=(14, 0, 2.66))
    t.pole(54, "sine", line=(10, 180, 2.66))
    t.pole(64, at=(x, y))
    t.lamp(0, "sine", (-6, 0))
    t.lamp(32, "sine", (4, 1))
    t.lamp(64, swing=(-6, 0))
    t.stride = 2 * abs(a.z - b.z)


def swing(t):
    """It has let you come close enough. It lifts the pole and draws the foot of it back past its hip like a lance,
    leaning away from you, the lantern swung out to its right; then it sweeps the foot of the pole round and across in front of
    it at your fighter's chest, the whole length turning over in its hand and the lantern flung up behind its shoulder.
    It lets the pole come round, then plants it again and leans on it. The crook and the lantern stay high: the
    lantern's weight is the signature's."""
    length, strike, recover = (round(SWING[k] * FPS) for k in ("Length", "Strike", "Recover"))
    t.key(0, "ready")
    t.pole(0, under=True)
    t.mark(0, "Wind")
    t.key(8, ease="in", T=(3, -10, -4, 0.05, 0, 0), crouch=0.0, RA=("grip", (2.3, 0.8, 2.9), (40, 0, 30)))
    t.pole(8, ease="in", line=(6.0, 0.0, 2.4))
    t.key(26, "drawn back", ease="cubic", T=(-8, -32, -2, 0, 0, 0.1), crouch=0.1, RA=("grip", (2.2, 0.0, 3.0), (20, 0, 50)),
          LA=(25, 0, -25))
    t.pole(26, ease="cubic", butt=(1.6, -2.0, 1.2), grip=2.4)
    t.key(strike - 8, ease="in", T=(0, -14, -2), RA=("grip", (2.2, 1.0, 3.0), (40, 0, 40)))
    t.pole(strike - 8, ease="in", butt=(2.4, 3.2, 1.6), grip=2.4)
    t.key(strike, "it lands", ease="lin", T=(10, 22, 4, 0, 0, -0.15), crouch=0.16, RA=("grip", (1.2, 1.6, 3.1), (70, 0, 0)),
          LA=(-20, 0, -35))
    t.pole(strike, ease="lin", butt=(-0.6, 3.3, 1.6), grip=2.4)
    t.mark(strike, "Strike")
    t.key(recover, "spent", ease="out", T=(8, 36, 4, 0, 0, -0.1), RA=("grip", (0.5, 1.3, 3.0), (70, 0, -20)))
    t.pole(recover, ease="out", butt=(-2.0, 2.4, 1.4), grip=2.4)
    t.mark(recover, "Recover")
    t.key(length, "ready", ease="sine", T=READY["T"], crouch=READY["crouch"], RA=READY["RA"], LA=READY["LA"], look=LEAD,
          H=READY["H"])
    t.pole(length, under=True, open=114)
    t.lamp(0)
    t.lamp(26, "sine", (-15, 10))
    t.lamp(strike, "sine", (-30, 25))
    t.lamp(recover + 6, "sine", (-25, -20))
    t.lamp(length - 16, "sine", (6, 0))
    t.lamp(length)


def hit(t):
    """It barely gives. The blow rocks it back on its heels and lifts its head a little under the brim, and the pole,
    still planted, takes its weight: it leans onto it again as the lantern swings and settles. The feet never move."""
    t.key(0, ease="out")
    t.pole(0, under=True)
    t.key(4, "struck", ease="sine", T=(-3, -12, -2, 0, 0, -0.1), crouch=0.08, H=(-4, 6, 8), LA=(-30, 0, -24),
          RA=(40, 0, 32))
    t.key(12, "onto the pole", ease="sine", T=(10, -4, -7, 0.1, 0, 0.05), crouch=0.1, H=(6, 2, 4), LA=(-4, 0, -12),
          RA=READY["RA"])
    t.key(20, ease="sine", T=(6, -6, -4, 0.05, 0, 0), crouch=0.05, H=(2, 0, 4))
    t.key(30, T=READY["T"], crouch=READY["crouch"], H=READY["H"], look=LEAD, LA=READY["LA"])
    t.lamp(0)
    t.lamp(6, "sine", (-14, -4))
    t.lamp(16, "sine", (8, 2))
    t.lamp(30)


LAMPPOST = (20.0, -22.0, (1.5, 0.9))  # the signature's hold: the pole's lean and heading, and where its foot is planted


def on_pole(d):
    """The stage place `d` studs up the signature's leant pole from its planted foot."""
    lean, toward, foot = LAMPPOST
    a, h = math.radians(lean), math.radians(toward)
    return (foot[0] + d * math.sin(a) * math.sin(h), foot[1] + d * math.sin(a) * math.cos(h), d * math.cos(a))


def signature(t):
    """The block of its signature. It plants the pole out ahead of it and leans the whole length out over your fighter
    like a street lamp, one-handed, and the lantern swings up and over until it hangs above your fighter's head and
    lights the ground in a circle under it: long enough that you see it coming. Then it wrenches the pole up out of the
    ground with both hands and brings it down like a hammer, and the lantern comes down on the circle."""
    lean, toward, foot = LAMPPOST
    t.key(0, "ready")
    t.pole(0, under=True)
    t.key(12, ease="in", T=(2, -8, -4, 0.04, 0, 0), crouch=-0.02, RA=("grip", (1.8, 1.0, 3.2), (40, 0, 20)))
    t.pole(12, ease="in", line=(-6.0, 0.0, 2.4))
    t.key(24, "it plants the pole", ease="out", T=(16, -4, -2, 0.04, 0, 0.12), crouch=0.14,
          RA=("grip", on_pole(2.6), (50, 0, 10)))
    t.pole(24, ease="out", at=foot, open=0)
    t.mark(24, "Plant")
    t.key(44, "and leans it out over you", ease="cubic", T=(-2, 6, 0, 0, 0, -0.06), crouch=0.06,
          RA=("grip", on_pole(3.6), (80, 0, 10)), LA=(-25, 0, -30), look=LEAD)
    t.mark(44, "Light")
    t.key(96, "held, burning", ease="sine", T=(-4, 6, 0, 0, 0, -0.08), crouch=0.08)
    t.pole(96, ease="in", at=foot)
    t.key(106, "it wrenches it up", ease="in", T=(-10, -4, 0, 0, 0, -0.05), crouch=-0.02,
          RA=("grip", (0.9, 0.9, 4.4), (120, 0, 10)), LA=("reach", (0.7, 0.8, 3.6), (100, 0, -10)))
    t.pole(106, ease="in", line=(-6.0, toward, 3.6))
    t.key(114, "the slam", ease="out", T=(30, 0, 0, 0, 0, 0.3), crouch=0.3, RA=("grip", (0.9, 1.9, 2.3), (70, 0, 0)),
          LA=("reach", (1.1, 1.0, 2.35), (60, 0, -10)), look=(0.0, REACH, 0.0))
    t.pole(114, ease="out", line=(92.0, toward, 3.6))
    t.mark(114, "Slam")
    t.key(138, "it holds it down", ease="sine", T=(26, 0, 0, 0, 0, 0.26), crouch=0.26)
    t.pole(138, ease="sine", line=(90.0, toward, 3.6))
    t.key(178, "ready", ease="sine", T=READY["T"], crouch=READY["crouch"], RA=READY["RA"], LA=READY["LA"], look=LEAD,
          H=READY["H"])
    t.pole(178, under=True, open=114)
    t.lamp(0)
    t.lamp(24, "sine", (-15, 0))
    t.lamp(36, "sine", (20, 0))
    t.lamp(46, "sine", (-6, 0))
    t.lamp(58, "sine", (2, 0))
    t.lamp(96, "sine", (0, 0))
    t.lamp(106, "in", (10, 0))
    t.lamp(114, "out", (-35, 0))
    t.lamp(124, "sine", (-10, 0))
    t.lamp(138, "sine", (0, 0))
    t.lamp(178)


# name: (the clip, its hub)
CLIPS = {"Idle": (idle, WAIT), "Challenge": (challenge, WAIT), "Ready": (ready, READY), "Walk": (walk, READY),
         "Swing": (swing, READY), "Hit": (hit, READY), "Signature": (signature, READY)}


# --- outputs --------------------------------------------------------------------------------------------------------

def stage_camera(scene, azimuth, elevation, distance, focus, fov=40.0, name="Camera"):
    """A camera round the keeper as it stands at the stage's middle facing ahead: `azimuth` degrees from its front (90
    its right), `elevation` up, `distance` from the stage place `focus`, between the body and the lantern."""
    a, e = math.radians(azimuth), math.radians(elevation)
    at = W(*focus)
    eye = at + (Vector((0, 0, -1)) * math.cos(a) + Vector((1, 0, 0)) * math.sin(a)) * distance * math.cos(e)
    return r6.fixed_camera(scene, eye + Vector((0, distance * math.sin(e), 0)), at, fov, name)


def cameras(scene, rig):
    return {"fight": stage_camera(scene, *FIGHT, 20.0, (1.0, 1.4, 3.6), name="fight"),
            "side": stage_camera(scene, *SIDE, 21.0, (0.6, 1.4, 3.5), name="side")}


def pose_sheet(scene, cams, take, out):
    shots = [(cams[view], take.start + f, f"{take.name} {f}: {label}" if view == "fight" else f"{f} {view}")
             for view in ("fight", "side") for f, label in take.beats]
    scene.render.resolution_x, scene.render.resolution_y = 300, 360
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(take.beats))
    print(f"wrote {path}")


def blocking_sheet(scene, cams, takes, out):
    """Every clip's key poses from the fight's camera, a row a clip: the blocking, read at once."""
    columns = max(len(t.beats) for t in takes)
    shots = []
    for take in takes:
        row = [(cams["fight"], take.start + f, f"{take.name} {f}: {label}") for f, label in take.beats]
        shots += row + [(cams["fight"], take.start + take.beats[-1][0], "")] * (columns - len(row))
    scene.render.resolution_x, scene.render.resolution_y = 280, 300
    scene.render.stamp_font_size = 14
    path = r6.render_shots(scene, shots, out / "lamplighter_blocking.png", columns=columns)
    print(f"wrote {path}")


def report(take, n):
    near = "; ".join(f"{part} {d:.2f} at {f}" for part, (d, f) in n["near"].items())
    lamp = "; ".join(f"{part} {d:.2f} at {f}" for part, (d, f) in n["lamp_near"].items())
    return (f"{take.name}: {take.end + 1} frames, {take.end / FPS:.2f} s; markers "
            f"{', '.join(f'{name} {round(s * FPS)}' for s, name in take.markers) or 'none'}\n"
            f"  the pole's lowest point over the floor {n['foot'][0]:.2f} at {n['foot'][1]}; the grip from "
            f"{n['grip'][0]:.2f} to {n['grip'][1]:.2f} up it (it holds from {HOLD[0]} to {HOLD[1]})\n"
            f"  the pole's nearest to the body (past its radius): {near}\n"
            f"  the lantern's foot at its lowest {n['lamp_low'][0]:.2f} at {n['lamp_low'][1]}; its widest off plumb "
            f"{n['plumb'][0]:.0f} at {n['plumb'][1]}; its nearest to the body (past its drum): {lamp}\n"
            + (f"  the lantern rests on the floor from {n['rests'][0]} to {n['rests'][-1]} ({len(n['rests'])} frames)\n"
               if n["rests"] else "")
            + "".join(f"  {name} ({f}): the grip at ({g[0]:.2f}, {g[1]:.2f}, {g[2]:.2f}); the lantern over "
                      f"({c[0]:.2f}, {c[1]:.2f}), its foot {c[2]:.2f} up\n" for f, (name, g, c) in sorted(n["at"].items())))


def family(scene, rig, feet, ctl, motors, rest, out):
    """The Shade's own clips on the keeper, as the game plays a shared clip that doesn't key the pole: the pole and the
    lantern ride the right arm as they're built, at rest. Each is measured as the keeper's are, and shown."""
    takes = []
    for i, (name, (clip, _, mirror)) in enumerate(sc.CLIPS.items()):
        if name in ("Idle", "Walk", "Attack", "Hit", "Burst"):
            take = sc.Take(rig, feet, name, 1000 * i, mirror)
            clip(take)
            takes.append(take)
    rc.ground(rig, feet, takes)
    skin, facts = Skin(), {}
    for take in takes:
        n = {"foot": (9.0, 0), "plumb": (0.0, 0), "near": (9.0, "", 0), "legs": (0.0, 0)}
        for f in range(take.end + 1):
            frame = take.start + f
            scene.frame_set(frame)
            r6.key_matrices(rig, frame, {POLE: Matrix.Identity(4), LAMP: Matrix.Identity(4)})
            bpy.context.view_layer.update()
            placed = r6.to_roblox(motors[POLE].matrix_world) @ Matrix.Translation(-rest["G0"])
            foot, u = placed @ rest["F0"], (placed.to_3x3() @ rest["a0"]).normalized()
            low = min(foot.y - FERRULE * math.sqrt(max(0.0, 1.0 - u.y * u.y)), (foot + u * POLE_TOP).y)
            n["foot"] = min(n["foot"], (low, f))
            down = (placed.to_3x3() @ rest["h0"]).normalized()
            n["plumb"] = max(n["plumb"], (math.degrees(down.angle(Vector((0, -1, 0)))), f))
            ends = [foot + u * s for s in np.linspace(0.0, POLE_TOP, 24) if abs(s - rest["grip0"]) > 0.5]
            for part in Skin.PARTS:
                d = skin.gap(ends, part, 0.1)
                if d < n["near"][0]:
                    n["near"] = (d, part, f)
            n["legs"] = max(n["legs"], (max(abs(r6.pose_of(rig, leg)[0]) for leg in r6.LEGS), f))
        facts[take.name] = n
        print(f"the Shade's {take.name} on the keeper: the pole's lowest point {n['foot'][0]:.2f} at {n['foot'][1]}; "
              f"the lantern up to {n['plumb'][0]:.0f} degrees off plumb (at {n['plumb'][1]}); the pole's nearest to the "
              f"body {n['near'][0]:.2f} ({n['near'][1]}, at {n['near'][2]}); a leg's widest swing {n['legs'][0]:.0f} at "
              f"{n['legs'][1]} (the coat holds {STRIDE:.0f} to 27)")
    cams = cameras(scene, rig)
    shots = []
    for take in takes:
        picks = sorted({0, take.end // 2, take.end, *(f for f, _ in take.beats)})[:6]
        shots += [(cams["fight"], take.start + f, f"Shade's {take.name} {f}") for f in picks]
        shots += [(cams["fight"], take.start + take.end, "")] * (6 - len(picks))
    scene.render.resolution_x, scene.render.resolution_y = 250, 300
    scene.render.stamp_font_size = 14
    path = r6.render_shots(scene, shots, out / "lamplighter_family.png", columns=6)
    print(f"wrote {path}")
    return facts


def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "family") else "poses"
    scene, rig, costume, undress, feet, ctl, motors, rest, grip_local = build(out)
    print(f"the grip on the right arm: {tuple(round(c, 3) for c in grip_local)}; the lead {REACH:.2f} off; KeeperSwing "
          f"{SWING['Length']} s, Strike {SWING['Strike']}, Recover {SWING['Recover']}")
    if mode == "family":
        family(scene, rig, feet, ctl, motors, rest, out)
        return
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    takes = {}
    for i, (name, (clip, hub)) in enumerate(CLIPS.items()):
        if name in wanted:
            takes[name] = take = Take(rig, feet, ctl, motors, name, 1000 * i, hub)
            clip(take)
            for line in take.warned:
                print("  " + line)
    rc.ground(rig, feet, list(takes.values()))
    numbers = props(rig, ctl, motors, rest, list(takes.values()))
    cams = cameras(scene, rig)
    for name, take in takes.items():
        print(report(take, numbers[name]), end="")
        if name == "Walk":
            print(f"  the walk covers {take.stride:.2f} studs a loop, {take.stride / (take.end / FPS):.2f} a second "
                  f"({take.stride * SCALE:.2f} and {take.stride * SCALE / (take.end / FPS):.2f} at 1.5)")
        pose_sheet(scene, cams, take, out)
    blocking_sheet(scene, cams, list(takes.values()), out)


if __name__ == "__main__":
    main()
