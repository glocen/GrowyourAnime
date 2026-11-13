"""The Lamplighter's clips on the Shade's R6 rig, its model riding it (AR7, delivery 3).

blender.exe -b --factory-startup --python tools/blender/lamplighter_clips.py -- <out_dir> [poses|family|export|audit] [clip ...]

- poses (the default): each clip's key poses from the fight's camera and from the side, a sheet a clip, and one blocking
  sheet of every clip's poses from the fight's camera, with the checks' numbers printed.
- family: the Shade's own clips (shade_clips.py) as the game would play them on the keeper, the pole and the lantern
  riding the right arm unkeyed: what each does to them, measured, on one sheet.
- export: Lamplighter_<Clip>.json for the builder (r6anim.export, with its audit), one review pack a clip, the arcs and
  the bare rig, and Lamplighter.clips.json. audit: the export without the pictures.

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
- the lantern: a weight on its cord, carried by the hook's tip and left to swing (swing_lantern), under the game's
  gravity, with the floor under it. A key (Take.lamp) can pull it toward a swing; a clip that isn't a loop ends with it
  hanging plumb, as the hub it fades to does, and a loop's swing is run until it repeats.

How it moves: it's the street's master, and it's in no hurry. Its weight is on the pole whenever the pole is down, and
everything it does starts from the pole: the try's stamp, the swing, the signature's plant.
"""
import contextlib
import io
import json
import math
import re
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
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
WALK_LOOP = 64  # frames of the walk's two steps: a heavy 1.9 a second, the master in no hurry (the blocking's, kept)
FERRULE = 0.12  # the pole's foot's radius
POLE_TOP = lsh.POLE_TOP  # the pole's length, foot to top
HOLD = (1.0, 6.0)  # studs up the pole from its foot that the grip can close on: over the ferrule, under the crook
LAMP_R, LAMP_DROP = lsh.LAMP[0], lsh.LAMP[1] / 2 + lsh.HOOP  # the drum's radius, and its middle to its foot
NOD = rc.NOD
GRIP = (0.3, -1.28, 0.0)  # the grip in the right arm's frame: set from the recipe as the rig is built
COMBAT = "src/shared/Config/Combat.luau"
GRAVITY = 196.2 / SCALE  # Roblox's pull (Workspace.Gravity's default), in the keeper's units: the game scales it by 1.5
LAMP_DAMP = 3.0  # how fast the lantern's swing dies, a second: a heavy drum on a stiff hook, an eighth left a swing
SUBSTEPS = 8  # the lantern's steps a frame
SETTLE = 16  # frames over which a clip that isn't a loop brings the lantern to plumb, as its hub hangs it
MAX_SWING = 100.0  # degrees off plumb the lantern is flung at most: past it a cord goes slack, which a drum on a
# fixed hoop can't show, so it's caught there and loses most of its speed


def row_number(anchor, name, path=ACTIONS) -> float:
    """The first `name = number` after `anchor` in one of the game's files: its own numbers, never typed again."""
    text = (r6.REPO / path).read_text(encoding="utf-8")
    return float(re.search(rf"\b{name}\s*=\s*(-?[\d.]+)", text[text.index(anchor):]).group(1))


SWING = r6.luau_table(ACTIONS, 'Id = "KeeperSwing"')  # Length, and its Beats: Wind, Strike, Recover, in seconds
REACH = row_number('Id = "KeeperSwing"', "Range") / SCALE  # how far off the lead stands when the keeper swings
# The keeper comes for its challenger at the Shade's walk (FightService, the Shades' step), in studs a second; the game
# plays a walk at the body's speed over the clip's (Config.Animations.Strides), so the loop is timed to play at 1 there
WALK_SPEED = row_number("Shade = {", "WalkSpeed", COMBAT)
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


def swing_lantern(tips, pulls, cord, loop) -> tuple:
    """The lantern as a weight on its cord, hung from the hook's tip and carried by it frame by frame: the game's
    gravity, a little drag, and the floor, where it stops dead. `pulls` (forward, right, pin) a frame draw it toward a
    keyed swing by `pin`. A loop is run until it repeats and its seam closed; a clip that isn't one ends hanging plumb.
    Returns each frame's cord line (Roblox, down from the tip) and whether it lay on the floor."""
    n = len(tips)
    dt = 1.0 / (FPS * SUBSTEPS)
    drag, fall = math.exp(-LAMP_DAMP * dt), Vector((0.0, -GRAVITY * dt * dt, 0.0))
    downs, rests = [None] * n, [False] * n

    limit = math.radians(MAX_SWING)

    def floor(tip, p):
        d = (p - tip).normalized()
        off = math.acos(max(-1.0, min(1.0, -d.y)))
        if off > limit:  # caught at the widest swing, in the same upright plane
            flat = Vector((d.x, 0.0, d.z)).normalized()
            d = flat * math.sin(limit) - Vector((0.0, 1.0, 0.0)) * math.cos(limit)
        d, resting = rest_on_floor(tip, d, cord)
        return tip + d * cord, resting, resting or off > limit  # the place, on the floor, stopped

    p = floor(tips[0], tips[0] + Vector((0.0, -cord, 0.0)))[0]
    prev = p.copy()
    frames = n - 1 if loop else n  # a loop's last frame is its first
    passes = max(2, math.ceil(6.0 * FPS / frames)) if loop else 1
    for _ in range(passes):
        for f in range(frames):
            tip, pull = tips[f], pulls[f]
            target, pin = hang(pull.x, pull.y), min(max(pull.z, 0.0), 1.0)
            if not loop and f > n - 1 - SETTLE:
                s = (f - (n - 1 - SETTLE)) / SETTLE
                if s * s * (3 - 2 * s) > pin:
                    target, pin = Vector((0.0, -1.0, 0.0)), s * s * (3 - 2 * s)
            if pin > 0.0:
                moving = p - prev
                p = tip + (p - tip).normalized().slerp(target, pin) * cord
                prev = p - moving * (1.0 - pin)
            p, rests[f], stopped = floor(tip, p)
            if stopped:
                prev = p.copy()
            downs[f] = (p - tip).normalized()
            if f == n - 1:
                break
            nxt = tips[(f + 1) % (n - 1) if loop else f + 1]
            for s in range(1, SUBSTEPS + 1):
                at = tip.lerp(nxt, s / SUBSTEPS)
                p, prev = p + (p - prev) * drag + fall, p
                p = at + (p - at).normalized() * cord
                p, _, stopped = floor(at, p)
                if stopped:
                    prev = p.copy()
    if loop:  # the seam: what the next pass would start from, turned back onto the first frame over the loop
        end = (p - tips[0]).normalized()
        q = end.rotation_difference(downs[0])
        for f in range(n - 1):
            downs[f] = Quaternion((1.0, 0.0, 0.0, 0.0)).slerp(q, f / (n - 1)) @ downs[f]
        downs[n - 1], rests[n - 1] = downs[0].copy(), rests[0]
    return downs, rests


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

    def lamp(self, f, ease=None, swing=(0.0, 0.0), pin=0.0):
        """Keys a pull on the lantern at clip frame `f`: toward `swing`, degrees off plumb toward the keeper's front and
        its right, by `pin` (0 leaves it to swing, 1 holds it there)."""
        self.props["lamp"] = (*swing, pin)
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
    """The last pass, once the body is keyed on every frame: the pole solved through the grip, then the lantern swung
    on its cord from the hook's tip (swing_lantern), each keyed on every frame. Returns each clip's numbers."""
    scene, facts, skin = bpy.context.scene, {}, Skin()
    for take in takes:
        n = {"foot": (9.0, 0), "grip": [9.0, -9.0], "lamp_low": (9.0, 0), "near": {part: (9.0, 0) for part in Skin.PARTS},
             "lamp_near": {part: (9.0, 0) for part in Skin.PARTS}, "plumb": (0.0, 0), "rests": [], "at": {}}
        marks = {round(s * FPS): name for s, name in take.markers}
        poles = []  # a frame's grip, the pole's foot and its line, the hook's tip, and how the pole is turned
        pulls = []
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
            poles.append((g, foot, u, placed @ rest["T0"], placed.to_3x3()))
            pulls.append(v["lamp"])
        downs, rests = swing_lantern([p[3] for p in poles], pulls, rest["cord"], take.loop)
        for f in range(take.end + 1):
            frame = take.start + f
            scene.frame_set(frame)
            g, foot, u, tip, turned = poles[f]
            down = downs[f]
            if rests[f]:
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
    t.key(176, "it sinks under the brim", ease="cubic", H=(29, 2, 7))
    t.key(188, "and catches itself", ease="out", H=(16, -1, 5))
    t.key(240, T=WAIT["T"], crouch=WAIT["crouch"], H=WAIT["H"], RA=WAIT["RA"])
    t.mark(188, "Catch")


def ready(t):
    """In the ring it watches you and nothing else. Still on the pole, squared to you, the head up: it breathes
    slower than you do."""
    t.loop = True
    t.key(0, "watching you", ease="sine")
    t.pole(0, under=True)
    t.key(90, "a breath in", ease="sine", T=(3.5, -6, -3.5, 0.05, 0, 0), crouch=0.0, RA=(46, 0, 28))
    t.key(180, T=READY["T"], crouch=READY["crouch"], RA=READY["RA"])


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
    t.lamp(56)  # the stamp jolts the lantern up on its hoop: a kick it then swings out of
    t.lamp(58, "out", (12, 4), 0.35)
    t.lamp(62)
    t.key(70, ease="sine", T=(5, -6, -4, 0.05, 0, 0), crouch=0.04)
    t.key(92, "then at your fighter", ease="sine", T=READY["T"], crouch=READY["crouch"], LA=READY["LA"], look=LEAD,
          H=READY["H"])


def walk(t):
    """It walks its street as it has every night, on its round: the pole goes ahead and is planted, and the body is
    carried up to it and past it, the lantern swinging after the hook. Its step is the long coat's: a leg swings no
    wider than the hem lets it. Two heavy steps a loop; the game plays it at the body's speed over the clip's, so its
    feet keep to the floor whatever the keeper's pace."""
    t.loop = True
    loose = {"Right Leg": None, "Left Leg": None}
    s = STRIDE
    land = dict(T=(12, -6, -3), RL=(-s, 0, 0), LL=(s, 0, 0), H=(4, 4, 4), RA=(52, 0, 26), LA=(-16, 0, -10))
    t.key(0, "the left foot and the pole land", ease="sine", feet=loose, **land)
    scene = bpy.context.scene
    scene.frame_set(t.start)
    r6._refresh()
    a, b = sc.leg_ends(t.rig)
    t.stride = 2 * abs(a.z - b.z)  # the floor a loop covers, in the keeper's units
    loop = WALK_LOOP
    q = loop // 4
    t.key(q, "carried up to it", ease="sine", T=(10, -3, -1), RL=(0, 0, 0), LL=(0, 0, 0), RA=(30, 0, 27), LA=(-8, 0, -10))
    t.key(2 * q, "the right foot lands", ease="sine", T=(12, 1, 1), RL=(s, 0, 0), LL=(-s, 0, 0), RA=(8, 0, 27),
          LA=(4, 0, -10))
    t.key(3 * q, "the pole goes ahead", ease="sine", T=(10, -3, -2), RL=(0, 0, 0), LL=(0, 0, 0), RA=(34, 0, 27),
          LA=(-6, 0, -10))
    t.key(loop, **land)
    per_frame = t.stride / loop  # a planted foot goes back by it a frame
    # The pole is planted a quarter of the loop, from a little ahead of the grip to a little behind it, then carried
    # and swung ahead on a short arc: its hook rocks a little, and the lantern swings with the step, not wild
    held = loop // 4
    t.pole(0, under=True)
    x, y = t.props["plant"][:2]
    ahead = per_frame * held / 2
    t.pole(0, at=(x, y + ahead))
    t.pole(held, "lin", at=(x, y - ahead))
    t.pole(round(loop * 0.45), "sine", line=(10, 0, 2.66))
    t.pole(round(loop * 0.75), "sine", line=(10, 180, 2.66))
    t.pole(loop, at=(x, y + ahead))
    t.mark(0, "Pole")
    t.mark(2 * q, "Step")


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
    # drawn back and swept with its head out to the right, so the head never passes over the hat
    t.key(26, "drawn back", ease="cubic", T=(-8, -20, -2, 0, 0, 0.1), crouch=0.1, RA=("grip", (2.3, 0.0, 3.0), (20, 0, 50)),
          LA=(25, 0, -25))
    t.pole(26, ease="in", butt=(2.4, -1.6, 1.6), grip=2.4)
    # the pole turns over upright at its right side: the foot passes down beside the leg, never under the body, and the
    # head up and out to the right, never over the hat with the lantern
    t.pole(33, ease="lin", line=(13.0, 90.0, 2.4))
    t.key(strike - 8, ease="in", T=(0, -14, -2), RA=("grip", (2.2, 1.0, 3.0), (40, 0, 40)))
    t.pole(strike - 8, ease="in", butt=(1.6, 3.0, 1.7), grip=2.4)
    t.key(strike, "it lands", ease="lin", T=(10, 22, 4, 0, 0, -0.15), crouch=0.16, RA=("grip", (1.2, 1.6, 3.1), (70, 0, 0)),
          LA=(-20, 0, -35))
    t.pole(strike, ease="lin", butt=(-0.6, 3.3, 1.6), grip=2.4)
    t.mark(strike, "Strike")
    t.key(recover, "spent", ease="out", T=(8, 36, 4, 0, 0, -0.1), RA=("grip", (0.9, 1.6, 3.0), (70, 0, -20)))
    t.pole(recover, ease="out", butt=(-2.0, 2.4, 1.4), grip=2.4)
    t.mark(recover, "Recover")
    # the foot comes back round in front of it, clear of the coat, before it's planted
    t.key(recover + 14, ease="sine", T=(7, 18, 2, 0, 0, -0.04), RA=("grip", (1.3, 1.4, 3.0), (60, 0, -10)))
    t.pole(recover + 14, ease="sine", butt=(0.6, 2.9, 0.8), grip=2.4)
    t.key(length, "ready", ease="sine", T=READY["T"], crouch=READY["crouch"], RA=READY["RA"], LA=READY["LA"], look=LEAD,
          H=READY["H"])
    t.pole(length, under=True, open=114)


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


# The signature's hold: the pole's lean and heading, and where its foot is planted. The lantern hangs over your
# fighter's shoulder, beside the keeper's face from the fight's camera, not in front of it.
LAMPPOST = (22.0, -38.0, (1.95, 0.95))


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
    t.key(24, "it plants the pole", ease="out", T=(16, 10, -2, 0.04, 0, 0.12), crouch=0.14,
          RA=("grip", on_pole(2.6), (50, 0, 20)))  # the chest turned into the plant, so the arm reaching it clears it
    t.pole(24, ease="out", at=foot, open=0)
    t.mark(24, "Plant")
    # The hold grows (research's read, fix 1): it leans the pole out with its head still down under the brim, then its
    # weight sinks onto the pole, the left hand comes forward for it and the head comes up to your fighter.
    t.key(44, "and leans it out over you", ease="sine", T=(3, 18, 0, 0, 0, -0.06), crouch=0.06,
          RA=("grip", on_pole(3.4), (80, 0, 10)), LA=(-25, 0, -30), H=(28, -4, 4))
    t.mark(44, "Light")
    t.key(70, "it sinks onto it", ease="sine", T=(5, 18, 0, 0.0, 0, -0.02), crouch=0.12, LA=(-14, 0, -26),
          H=(23, -2, 4))
    # up at you: over your fighter's head toward the camera behind it, so the face comes out from under the brim (your
    # fighter's own face is below the keeper's eyes: looking at it would bow the head as low as the plant did)
    t.key(96, "and looks up at you", ease="out", T=(6, 18, 0, 0.02, 0, 0.02), crouch=0.17, LA=(-4, 0, -20),
          look=(0.0, REACH, 5.0))
    t.pole(96, ease="out", at=foot)
    t.lamp(30)  # the plant flings the lantern up; it comes over your fighter by the Light and steadies through the hold
    t.lamp(44, "sine", pin=0.25)
    t.lamp(60, pin=0.1)
    t.lamp(96, pin=0.1)
    t.lamp(100)
    # The wrench, then a hang at its top (fix 2). The pole comes up beside the hat on its right, clear of the brim,
    # and the lantern swings up beside it, inside the ring's frame (over the hat it would leave it). An R6 left arm
    # can't reach a pole that far out, so the right wrenches and slams it and the left is flung out against it. The
    # slam brings the lantern down on the floor at your fighter, the hand slid up the pole for it.
    # The chest stays near square, so the raised arm is out at its side, never along its facing (r6parity's salute);
    # the slam's crouch and lean stay inside what the coat's hem covers.
    up, top, down = (0.0, toward, 3.9), (-6.0, toward, 3.9), (90.0, toward, 4.6)
    wrench, high, slam = (2.75, 0.3, 4.2), (2.75, 0.25, 4.35), (1.9, 1.4, 2.0)  # the grip at the arm's full reach
    t.key(106, "it wrenches it up", ease="sine", T=(-10, -6, 4, 0, 0, -0.05), crouch=-0.02,
          RA=("grip", wrench, (130, 0, 30)), LA=(40, 0, -60))
    t.pole(106, ease="sine", line=up)
    t.mark(106, "Wrench")
    t.key(110, "it hangs there", ease="in", T=(-12, -8, 5, 0, 0, -0.06), crouch=-0.03,
          RA=("grip", high, (134, 0, 30)), LA=(46, 0, -64))
    t.pole(110, ease="in", line=top)
    t.key(118, "the slam", ease="out", T=(20, -6, -4, 0.05, 0, 0.2), crouch=0.18, RA=("grip", slam, (70, 0, 10)),
          LA=(-30, 0, -35), look=(0.0, REACH, 0.0))
    t.pole(118, ease="out", line=down)
    t.mark(118, "Slam")
    t.key(124, "it gives", ease="sine", T=(19, -6, -3, 0.04, 0, 0.19), crouch=0.16)
    t.key(142, "it holds it down", ease="sine", T=(20, -5, -3, 0.04, 0, 0.19), crouch=0.17)
    t.pole(142, ease="sine", line=(88.0, toward, 4.6))
    t.key(160, ease="sine", T=(3, 2, 0, 0, 0, 0), crouch=0.08)  # it straightens first, its head back from the rising pole
    t.key(170, ease="sine", T=(2, 6, 5, 0, 0, 0), crouch=0.05)  # and tips its head away from it, so it never passes the head
    # the lantern comes round from the right with the pole's head, thrown out ahead of it, clear of the hat, and down
    # onto the circle
    t.lamp(112)
    t.lamp(115, "sine", (30.0, -10.0), 0.6)
    t.lamp(118, "out", (0.0, -35.0), 1.0)
    t.lamp(124)
    t.key(182, "ready", ease="sine", T=READY["T"], crouch=READY["crouch"], RA=READY["RA"], LA=READY["LA"], look=LEAD,
          H=READY["H"])
    t.pole(182, under=True, open=114)


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


def audit(rig, take) -> dict:
    """What the content check asks of every clip, as numbers: each leg's widest swing against the coat's hem, and each
    arm at its highest."""
    scene = bpy.context.scene
    swing = {leg: (0.0, 0) for leg in r6.LEGS}
    top = {"Right Arm": (-90.0, 0), "Left Arm": (-90.0, 0)}
    for f in range(take.end + 1):
        scene.frame_set(take.start + f)
        for leg in r6.LEGS:
            pose = r6.pose_of(rig, leg)
            swing[leg] = max(swing[leg], (max(abs(pose[0]), abs(pose[2])), f))
        for arm in top:
            along = (r6.to_roblox(rig.parts[arm].matrix_world).to_3x3() @ Vector((0, -1, 0))).normalized()
            top[arm] = max(top[arm], (math.degrees(math.asin(max(-1, min(1, along.y)))), f))
    return {"swing": swing, "top": top}


def arc_sheet(scene, rig, cams, take, rest, out):
    """One dot a frame where the grip (amber), the pole's foot (pale) and the lantern's middle (cyan) are through the
    clip, over the body at its middle beat: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)

    def at(rig, part):
        return r6.to_roblox(rig.parts[part].matrix_world)

    dots = r6.path_dots(rig, frames, [(POLE, (0.0, 0.0, 0.0))], radius=0.06, name="Grip", at=at)
    dots += r6.path_dots(rig, frames, [(POLE, tuple(rest["F0"] - rest["G0"]))], colour=(0.92, 0.9, 0.82), radius=0.05,
                         name="Foot", at=at)
    dots += r6.path_dots(rig, frames, [(LAMP, tuple(rest["h0"] * rest["cord"]))], colour=(0.35, 0.9, 0.95), radius=0.07,
                         name="Lamp", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    scene.render.resolution_x, scene.render.resolution_y = 640, 560
    path = r6.render_shots(scene, [(cams[view], beat, f"{take.name}: one dot a frame, {view}") for view in ("fight", "side")],
                           out / f"arcs_{take.name}.png", columns=2)
    for dot in dots:
        bpy.data.objects.remove(dot, do_unlink=True)
    print(f"wrote {path}")


def bare_sheet(scene, rig, take, undress, out, tiles=20):
    """The clip stepped through on the bare rig, the costume, the pole and the lantern off, from its left side and the
    fight's camera."""
    step = max(1, math.ceil((take.end + 1) / tiles))
    frames = list(range(0, take.end + 1, step))
    undress(True)
    cams = [stage_camera(scene, *view, 15.0, (0.0, 0.4, 3.0), name=f"bare {i}") for i, view in enumerate((SIDE, FIGHT))]
    scene.render.resolution_x, scene.render.resolution_y = 190, 230
    path = r6.render_shots(scene, [(cam, take.start + f, f"{f}") for cam in cams for f in frames],
                           out / f"bare_{take.name}.png", columns=len(frames))
    undress(False)
    print(f"wrote {path} (every {step} frames; its left side, then the fight's camera)")


def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "family", "export", "audit") else "poses"
    scene, rig, costume, undress, feet, ctl, motors, rest, grip_local = build(out)
    print(f"the grip on the right arm: {tuple(round(c, 3) for c in grip_local)}; the lead {REACH:.2f} off; KeeperSwing "
          f"{SWING['Length']} s, Strike {SWING['Strike']}, Recover {SWING['Recover']}; the lantern's cord "
          f"{rest['cord']:.2f}, a swing {2 * math.pi * math.sqrt(rest['cord'] / GRAVITY):.2f} s")
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
    facts = {}
    for name, take in takes.items():
        notes, checks = report(take, numbers[name]), audit(rig, take)
        speed = None
        if name == "Walk":
            speed = take.stride * SCALE / (take.end / FPS)
            notes += (f"  the walk covers {take.stride * SCALE:.2f} studs a loop at the game's 1.5, {speed:.2f} a second "
                      f"at rate 1: at the keeper's {WALK_SPEED:g} the game plays it at {WALK_SPEED / speed:.2f}, "
                      f"{2 * WALK_SPEED / (take.stride * SCALE):.1f} steps a second\n")
        notes += (f"  a leg's widest swing: right {checks['swing']['Right Leg'][0]:.0f} at {checks['swing']['Right Leg'][1]}, "
                  f"left {checks['swing']['Left Leg'][0]:.0f} at {checks['swing']['Left Leg'][1]} (the coat holds 27); each "
                  f"arm at its highest: right {checks['top']['Right Arm'][0]:.0f} at {checks['top']['Right Arm'][1]}, left "
                  f"{checks['top']['Left Arm'][0]:.0f} at {checks['top']['Left Arm'][1]}\n")
        print(notes, end="")
        facts[name] = {"File": f"{NAME}_{name}.json", "Frames": take.end + 1, "Seconds": round(take.end / FPS, 3),
                       "Loop": take.loop, "Markers": [[round(t * FPS), label] for t, label in take.markers]}
        if speed is not None:  # Config.Animations.Strides: its ground speed at rate 1, in the game's studs a second
            facts[name]["Stride"] = round(speed, 2)
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        heard = io.StringIO()  # the export audits itself aloud: the pack's notes keep what it said
        with contextlib.redirect_stdout(heard):
            # the Name is the game's: Author.SaveBaked reads Anim_Lamplighter<Clip> and checks the clip is named the same
            r6.export(rig, out / f"{NAME}_{name}.json", NAME, f"{NAME}{name}", take.start, take.start + take.end,
                      markers=take.markers, source="tools/blender/lamplighter_clips.py", extra={"Loop": take.loop})
        print(heard.getvalue(), end="")
        if mode == "audit":
            continue
        arc_sheet(scene, rig, cams, take, rest, out)
        bare_sheet(scene, rig, take, undress, out)
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame: cams["fight"], bare=SIDE[0], strip=strip, undress=undress,
                       notes=notes + heard.getvalue())
    if mode == "poses":
        blocking_sheet(scene, cams, list(takes.values()), out)
    elif len(takes) == len(CLIPS):
        (out / f"{NAME}.clips.json").write_text(json.dumps({"Fps": FPS, "Clips": facts}, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out / (NAME + '.clips.json')}")


if __name__ == "__main__":
    main()
