"""The Shade's clips on the R6 rig, its baked model riding it (AR2, delivery 3).

blender.exe -b --factory-startup --python tools/blender/shade_clips.py -- <out_dir> [poses|export|audit] [clip ...]

- poses (the default): one sheet a clip, its key poses from the player's camera and from its side.
- export: Shade_<Clip>.json for the builder (r6anim.export, with its audit), one review pack a clip, and the cuffs'
  arcs (one dot a frame).
- audit: the export without the review packs.

Needs shade_model.py's output (shade_model.blend, Shade.recipe.json and the maps) in MODEL. The keying is
rook_clips.py's: every clip at 60 fps on its own stretch of one timeline, starting from HUB; feet given as places on
the floor, or legs given by their angles (the walk's, the lunge's). Stage directions: right, forward, up, in studs,
from where it stands. One clip family for every Shade: a clip is shown here in the mask of the behaviour that uses it.

How it moves: nobody is in the coat. The mask leads and the coat is carried after it; the sleeves hang plumb and
arrive late; the feet never leave the floor, and nothing is ever above it.
"""
import contextlib
import io
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
import rook_clips as rc  # noqa: E402
import rook_sheet as rs  # noqa: E402
import shade_sheet as ss  # noqa: E402

FPS = rc.FPS
MODEL = Path(__file__).resolve().parents[2] / "build" / "scratch" / "modulo" / "shade" / "model"
GAME, SIDE = (24.0, 18.0), (90.0, 6.0)  # the camera's azimuth from its front and its elevation: a Shade faces the lead
ENEMY = (0.0, 7.0, 4.4)
HAND = (0.0, -1.0, 0.0)
W = rc.W
# A sleeve hanging plumb, whatever the coat does: ("hang", (out, forward), hint), the cuff's place from straight under
# its shoulder, in studs. A hair out, so the sleeve's block clears the coat's when the coat sways.
DOWN_R, DOWN_L = ("hang", (0.08, 0.0), (8, 0, 3)), ("hang", (0.08, 0.0), (8, 0, -3))


def hang(rig, arm, offset, hint):
    """Arm angles that hang the sleeve plumb under its shoulder with the torso as it stands, the cuff `offset` (out,
    forward) studs from there. r6.reach aims the line from the shoulder's pivot to the cuff, and the pivot is the arm's
    inner corner: a far place under the floor leans the sleeve in by 15 degrees, through the coat."""
    side = 1.0 if arm == "Right Arm" else -1.0
    torso = r6.to_roblox(rig.parts["Torso"].matrix_world)
    right, ahead = torso.to_3x3() @ Vector((1, 0, 0)), torso.to_3x3() @ Vector((0, 0, -1))
    right.y = ahead.y = 0.0
    cuff = (torso @ Vector((side, 0.5, 0.0)) + right.normalized() * side * (0.5 + offset[0])
            + ahead.normalized() * offset[1] + Vector((0.0, -1.5, 0.0)))
    return r6.reach(rig, arm, HAND, cuff, hint)


def shifted(rig, arm, place, hint, move):
    """A reach with the sleeve then slid off its shoulder by `move` (the coat's own right, up and back, studs): the
    sleeve keeps the reach's angles, so its cuff lands `move` from `place`. An R6 arm turns on its inner corner, so two
    sleeves brought together in front sink that corner into the coat's front. Nobody is in this coat: the sleeve
    slides clear instead, and hinges on the coat's front edge like a shutter."""
    return (*r6.reach(rig, arm, HAND, place, hint), *move)


def _flip(a):
    """An arm's or a leg's pose for the other side."""
    if a is None:
        return None
    if a[0] == "reach":
        return ("reach", (-a[1][0], a[1][1], a[1][2]), (a[2][0], -a[2][1], -a[2][2]), *((-m[0], m[1], m[2]) for m in a[3:]))
    if a[0] == "hang":
        return ("hang", a[1], (a[2][0], -a[2][1], -a[2][2]))
    return (a[0], -a[1], -a[2])


def mirrored(changes):
    """A key's changes for the clip's mirror: left for right. What a key takes from the hub stays the hub's, so the
    mirror starts and ends where every clip does."""
    other = {"RA": "LA", "LA": "RA", "RL": "LL", "LL": "RL", "Right Leg": "Left Leg", "Left Leg": "Right Leg"}
    out = {}
    for k, v in changes.items():
        if any(v is h for h in (*HUB.values(), DOWN_R, DOWN_L)):
            out[k] = v
        elif k == "T":
            v = tuple(v) + (0.0,) * (6 - len(v))
            out[k] = (v[0], -v[1], -v[2], -v[3], v[4], v[5])
        elif k == "H":
            out[k] = (v[0], -v[1], -v[2])
        elif k == "look":
            out[k] = None if v is None else (-v[0], v[1], v[2])
        elif k in ("RA", "LA", "RL", "LL"):
            out[other[k]] = _flip(v)
        elif k == "feet":
            out[k] = {other[leg]: (None if at is None else (-at[0], at[1])) for leg, at in v.items()}
        else:
            out[k] = v
    return out


# --- the rig with the model on it -----------------------------------------------------------------------------------

def build(colour="Strength"):
    scene = bl.reset_scene()
    r6.stage(scene, fps=FPS, size=(960, 540))
    scene.display.shading.color_type = "TEXTURE"
    recipe = json.loads((MODEL / "Shade.recipe.json").read_text())
    void, paper = rs.srgb(ss.PALETTE["VoidLift"])[:3], rs.srgb(ss.PALETTE["Paper"])[:3]
    rig = r6.build_rig("Shade", {"Torso": void, "Head": paper, "Right Arm": void, "Left Arm": void, "Right Leg": void,
                                 "Left Leg": void, "Face": rs.srgb(ss.PALETTE["Ink"])[:3]})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    blend = MODEL / "shade_model.blend"
    if not blend.exists():
        raise SystemExit(f"No {blend}: run shade_model.py first")
    with bpy.data.libraries.load(str(blend)) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("Shade_")]
    costume = {o.name: o for o in dst.objects}
    # Workbench draws one picture: the colour map with the glow mask laid over it in the type's colour
    # the body in its type's colour, a mask in its own warm white
    flat, glow = rs.load(MODEL / recipe["maps"]["Color"]), rs.load(MODEL / recipe["maps"]["Emissive"])[..., :1]
    previews = {}
    for name, tint in (("_preview.png", ss.TYPES[colour]), ("_preview_mask.png", recipe["emissive"]["mask_tint"])):
        lit = flat.copy()
        lit[..., :3] = (lit[..., :3] * (1 - glow) + glow * (0.25 * lit[..., :3] + 1.05 * np.array(rs.rgb(tint), dtype=np.float32))).clip(0, 1)
        rs.save(lit, MODEL / name)
        previews[name] = bpy.data.images.load(str(MODEL / name))
    worn_by = {piece["name"]: "_preview.png" for piece in recipe["pieces"]}
    masks = {}
    for piece in [*recipe["pieces"], *recipe["masks"].values()]:
        obj = costume[piece["name"]]
        scene.collection.objects.link(obj)
        holder = rig.parts[piece["on"]]
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
        for slot in obj.material_slots:
            nodes = slot.material.node_tree.nodes
            node = nodes.get("Preview") or nodes.new("ShaderNodeTexImage")
            node.name, node.image = "Preview", previews[worn_by.get(piece["name"], "_preview_mask.png")]
            nodes.active = node
    for kind, piece in recipe["masks"].items():
        masks[kind] = costume[piece["name"]]
    blocks = [rig.parts[p] for p in r6rig.PARTS] + [bpy.data.objects["Shade.Face"]]
    worn = {"kind": ss.MASKS and next(iter(ss.MASKS))}

    def undress(bare: bool):
        for o in costume.values():
            o.hide_render = bare
        for kind, o in masks.items():
            o.hide_render = bare or kind != worn["kind"]
        for o in blocks:
            o.hide_render = not bare

    def wear(kind):
        worn["kind"] = kind
        undress(False)

    undress(False)
    feet = {leg: r6._empty(f"Shade.Foot.{leg}", None, Matrix.Identity(4), 0.1) for leg in r6.LEGS}
    for empty in feet.values():  # a holder of numbers: where the foot stands (x right, y forward) and the crouch (z)
        empty.location = (0, 0, 0)
    return scene, rig, undress, wear, feet


# --- keying ---------------------------------------------------------------------------------------------------------

HUB = {
    "T": (8, -10, 0), "feet": {"Right Leg": (0.5, 0.0), "Left Leg": (-0.5, 0.06)}, "RL": (0, 0, 0), "LL": (0, 0, 0),
    "crouch": 0.0, "look": None, "H": (-7, 14, 11), "RA": DOWN_R, "LA": DOWN_L,
}


class Take(rc.Take):
    """One clip being keyed from `start`, as rook_clips.Take, for a body with no joints of its own."""

    def __init__(self, rig, feet, name, start, mirror=False):
        super().__init__(rig, feet, name, start)
        self.state = {k: (dict(v) if isinstance(v, dict) else v) for k, v in HUB.items()}
        self.mirror = mirror

    def _arm(self, arm, a):
        if a[0] == "reach" and len(a) > 3:
            return shifted(self.rig, rc.SHORT[arm], W(*a[1]), a[2], a[3])
        if a[0] == "reach":
            return r6.reach(self.rig, rc.SHORT[arm], HAND, W(*a[1]), a[2])
        if a[0] == "hang":
            return hang(self.rig, rc.SHORT[arm], a[1], a[2])
        return a

    def sleeves(self, f, **arms):
        """Keys the sleeves alone at clip frame `f` (RA, LA), with the coat where it is by then: a sleeve's own beat,
        between the coat's."""
        frame = self.start + f
        self.state.update(mirrored(arms) if self.mirror else arms)
        bpy.context.scene.frame_set(frame)
        r6._refresh()
        r6._key_parts(self.rig, frame, {rc.SHORT[arm]: self._arm(arm, self.state[arm]) for arm in ("RA", "LA")}, *rc.EASE["sine"])
        return self

    def key(self, f, label=None, ease=None, **changes):
        """Keys the pose at clip frame `f`. `ease` shapes the move that starts here. `label` puts it on the pose sheet.
        Changes: T (pitch, turn, roll, right, _, forward), feet {leg: (right, forward), or None for a leg given by its
        angles in RL / LL}, crouch, look (a stage place) or H (the mask's angles: pitch, turn, tilt), RA / LA (angles,
        or ("reach", place, hint), or ("reach", place, hint, shift): the sleeve slid off its shoulder)."""
        s, rig, frame = self.state, self.rig, self.start + f
        if self.mirror:
            changes = mirrored(changes)
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
        rest = {"Head": r6.look(rig, W(*s["look"]), s["H"]) if s.get("look") is not None else s["H"]}
        for arm in ("RA", "LA"):
            rest[rc.SHORT[arm]] = self._arm(arm, s[arm])
        r6._key_parts(rig, frame, rest, *interp)
        self.end = max(self.end, f)
        if label:
            self.beats.append((f, label))
        return self


# --- the clips ------------------------------------------------------------------------------------------------------
# Performance lines, one a clip, written before its poses.

def idle(t):
    """It hangs like a coat on a peg in a draught: the coat sways a hair, the sleeves stay plumb, and once a breath
    the mask tips the other way, quickly, as if it heard you."""
    t.loop = True
    t.key(0, "hung", ease="sine")
    t.key(50, ease="sine", T=(9.5, -8, 2), H=(-8, 12, 12))
    t.key(100, "the sway", ease="sine", T=(6.5, -12, -2), H=(-6, 16, 10))
    t.key(112, ease="cubic", H=(-6, 16, 9))
    t.key(120, "the mask tips", ease="sine", H=(-2, -6, -13))
    t.key(158, ease="sine", T=(8.5, -10, 1), H=(-3, -5, -12))
    t.key(170, ease="cubic", H=(-3, -5, -12))
    t.key(180, T=HUB["T"], H=HUB["H"])


def walk(t):
    """The mask goes first and the coat is carried after it. It doesn't step so much as get walked: stiff legs swung
    from the hip like a marionette's. The sleeves don't swing with them. They hang, dragged behind the coat, and each
    step's jolt reaches both of them together, late."""
    t.loop = True
    loose = {"Right Leg": None, "Left Leg": None}

    def drag(f, late, side):
        """A sleeve hung and dragged: behind its shoulder always, let forward a little after each step lands."""
        back = -0.38 + 0.15 * math.cos(2 * math.pi * (f - late) / 24)
        return ("hang", (0.15, back), (-6, 0, 3 * side))

    def both(f):
        return {"RA": drag(f, 5, 1), "LA": drag(f, 8, -1)}

    t.key(0, "the right leg lands", ease="sine", feet=loose, T=(17, -7, 2), RL=(30, 0, 0), LL=(-24, 0, 0), H=(-15, 6, 9), **both(0))
    t.key(12, "carried over it", ease="sine", T=(14, 0, -3), RL=(4, 0, 0), LL=(2, 0, 0), H=(-12, -2, 2), **both(12))
    t.key(24, "the left leg lands", ease="sine", T=(17, 7, -2), RL=(-24, 0, 0), LL=(30, 0, 0), H=(-15, -6, -7), **both(24))
    t.key(36, ease="sine", T=(14, 0, 3), RL=(2, 0, 0), LL=(4, 0, 0), H=(-12, 2, 0), **both(36))
    t.key(48, T=(17, -7, 2), RL=(30, 0, 0), LL=(-24, 0, 0), H=(-15, 6, 9), **both(48))
    for f in (5, 8, 17, 20, 29, 32, 41, 44):  # each sleeve's own turns, between the coat's keys
        t.sleeves(f, **both(f))
    t.mark(0, "Step")
    t.mark(24, "Step")


def attack(t):
    """It doesn't strike. It turns its back on you, the mask still watching, and lets an empty sleeve come round after
    it like a wet towel: the coat has already stopped when the cuff lands. The legs are turned with the coat: they
    swivel where they stand."""
    t.key(0)
    t.key(16, "turned away", ease="cubic", T=(3, -64, -4, 0, 0, -0.15), RA=(-26, 0, 30), LA=(22, 0, -8), look=ENEMY,
          H=(0, 0, 14), crouch=0.1, feet={"Right Leg": (0.34, -0.41), "Left Leg": (-0.34, 0.45)})
    t.key(22, ease="in", T=(1, -70, -5, 0, 0, -0.2), RA=(-34, 0, 44), feet={"Right Leg": (0.3, -0.4), "Left Leg": (-0.3, 0.44)})
    t.key(26, ease="lin", T=(11, 6, 2, 0, 0, 0.2), RA=(20, 0, 86), LA=(8, 0, -28), look=ENEMY, H=(0, 0, 4),
          feet={"Right Leg": (0.56, 0.04), "Left Leg": (-0.56, 0.0)})  # the coat goes; the sleeve is still out wide
    t.sleeves(28, RA=(54, 0, 62))  # still out wide: it comes in all at once
    t.key(30, "the cuff lands", T=(15, 32, 4, 0, 0, 0.35), RA=(80, 0, 16), LA=(-12, 0, -34), look=ENEMY, H=(0, 0, -6), crouch=0.14,
          feet={"Right Leg": (0.43, 0.26), "Left Leg": (-0.43, -0.22)})
    t.mark(30, "Hit")
    t.key(35, T=(14, 44, 4, 0, 0, 0.35), RA=(86, 0, 2))  # the coat is pulled on round by it
    t.key(44, "spent", ease="cubic", T=(13, 38, 3, 0, 0, 0.3), RA=(46, 0, 3), LA=(0, 0, -20))
    t.key(55, ease="sine", T=(10, 8, 1, 0, 0, 0.1), RA=(34, 0, 4), LA=DOWN_L, H=(-5, 8, 6), crouch=0.04,
          feet={"Right Leg": (0.5, 0.06), "Left Leg": (-0.5, 0.0)})  # the sleeve swings clear of the coat before it drops
    t.key(66, T=HUB["T"], RA=DOWN_R, LA=DOWN_L, H=HUB["H"], crouch=0.0, feet=HUB["feet"])


def guard(t):
    """It shuts. The coat sinks and leans at you, and both sleeves come up level, side by side under the mask, their
    open cuffs square at you: two shutters pulled to, with the mask's slots over the top. It holds, braced and hardly
    breathing, and then lets them fall as if they weighed nothing.

    AR52's seeds: up in 0.3 s (`Raise`), held 2.0 s, let go at `Drop`. The hold hardly moves, so the game may stretch
    or shorten it by the track's speed between the two markers."""
    shut_r = ("reach", (0.7, 2.2, 3.3), (68, 0, -28), (0.15, 0.0, -0.4))
    shut_l = ("reach", (-0.7, 2.2, 3.3), (68, 0, 28), (-0.15, 0.0, -0.4))
    t.key(0)
    t.key(7, ease="out", T=(3, -8, 0, 0, 0, -0.12), RA=(-16, 0, 12), LA=(-16, 0, -12), H=(-4, 8, 6))
    t.key(18, "shut", T=(22, 0, 0, 0, 0, 0.34), RA=shut_r, LA=shut_l, H=(-20, 0, 2), crouch=0.4)
    t.mark(18, "Raise")
    t.key(23, T=(19, 0, 0, 0, 0, 0.3), H=(-18, 0, 2), crouch=0.34)
    t.key(58, "braced", ease="sine", T=(20, 0, 0, 0, 0, 0.31), H=(-18, 0, 1), crouch=0.36)
    t.key(98, ease="sine", T=(19, 0, 0, 0, 0, 0.3), H=(-19, 0, 2), crouch=0.34)
    t.key(138, "still braced", ease="in", T=(20, 0, 0, 0, 0, 0.31), H=(-18, 0, 2), crouch=0.35)
    t.mark(138, "Drop")
    t.key(149, "let fall", T=(9, -8, 0), RA=("hang", (0.08, -0.1), (0, 0, 6)), LA=("hang", (0.08, 0.05), (0, 0, -6)), H=(-7, 12, 9), crouch=0.04)
    t.key(164, T=HUB["T"], RA=DOWN_R, LA=DOWN_L, H=HUB["H"], crouch=0.0)


def lunge(t):
    """It folds down behind its mask until the mask's point is a dart aimed at you, and stays there, dead still, long
    enough for you to know. Then the mask goes, and the coat is pulled out flat behind it, the legs trailing like
    empty trouser legs. The mask arrives first. The legs and the sleeves come in last, and for a moment it's a coat
    dropped over its own knees, the mask hanging at the floor and its back to the sky, before it's picked up again.

    AR52's seeds: the line shows at `Line` and it goes at `Lunge`, 1.0 s in; 0.25 s in the air to `Land` (the game
    carries it along the line, about 12 studs: the clip stays where it stands); then 0.8 s with its back open, from
    `Land` to `Close`."""
    loose = {"Right Leg": None, "Left Leg": None}
    t.key(0)
    t.key(16, "the line", ease="cubic", T=(40, 0, 0, 0, 0, -0.35), crouch=0.4, RA=(-52, 0, 14), LA=(-56, 0, -12),
          H=(12, 0, 0), feet={"Right Leg": (0.5, -0.45), "Left Leg": (-0.5, 0.3)})
    t.mark(16, "Line")
    t.key(50, "dead still", ease="sine", T=(41, 0, 0, 0, 0, -0.36), crouch=0.41, RA=(-54, 0, 14), LA=(-58, 0, -12), H=(12, 0, 0))
    t.key(60, "drawn back a hair", ease="in", T=(43, 0, 0, 0, 0, -0.42), crouch=0.46, RA=(-58, 0, 14), LA=(-62, 0, -12), H=(14, 0, 0))
    t.mark(60, "Lunge")
    t.key(64, "gone", ease="lin", T=(60, 0, 0, 0, 0, 0.5), feet=loose, RL=(24, 0, 5), LL=(-16, 0, -4),
          RA=(-76, 0, 5), LA=(-82, 0, -5), H=(22, 0, 0), crouch=0.0)
    t.key(69, ease="lin", T=(61, 0, 1, 0, 0, 0.5), RL=(-12, 0, 2), LL=(20, 0, -6), RA=(-80, 0, 8), LA=(-72, 0, -3), H=(21, 0, 2))
    t.key(75, T=(62, 0, 2, 0, 0, 0.5), RL=(16, 0, 6), LL=(-14, 0, -2), RA=(-84, 0, 6), LA=(-74, 0, -6), H=(20, 0, 3))
    t.mark(75, "Land")
    t.key(81, "the mask arrives", T=(30, 0, 0, 0, 0, 0.25), RL=(-34, 0, 4), LL=(-52, 0, -5), crouch=0.0,
          RA=(-30, 0, 10), LA=(-40, 0, -10), H=(-18, 0, 4))
    t.key(88, "the rest arrives", T=(28, -4, 0, 0, 0, 0.2), feet={"Right Leg": (0.5, 0.45), "Left Leg": (-0.5, -0.3)},
          RA=(58, 0, 8), LA=(64, 0, -8), H=(-14, 6, 8), crouch=0.3)
    t.key(97, "its back open", ease="sine", T=(48, -5, 2, 0, 0, 0.24), RA=("hang", (0.1, 0.25), (0, 0, 6)), LA=("hang", (0.1, 0.3), (0, 0, -6)),
          H=(26, 4, 8), crouch=0.26)
    t.key(110, ease="in", T=(50, -5, 2, 0, 0, 0.24), H=(29, 4, 9), crouch=0.28)
    t.mark(123, "Close")
    t.key(123, "picked up", ease="cubic", T=(16, -8, 0, 0, 0, 0.05), RA=("hang", (0.08, -0.1), (0, 0, 6)), LA=("hang", (0.08, 0.05), (0, 0, -6)),
          H=(-12, 12, 10), crouch=0.08, feet=HUB["feet"])
    t.key(138, T=HUB["T"], RA=DOWN_R, LA=DOWN_L, H=HUB["H"], crouch=0.0)


def knocked(t, pitch, twist, roll, forward, mask):
    """The coat's key and the mask's for a blow that twists the coat `twist` degrees from where it hangs, its left
    shoulder going back (its right in the mirror, by the same amount: the coat hangs a little turned, so a plain mirror
    of the angles would twist it less). `mask` is where the mask is by the stage's measure, not the coat's: pitch (+
    chin down), turn from where it hangs, tilt."""
    side = -1.0 if t.mirror else 1.0
    turn = HUB["T"][1] + side * twist
    face = HUB["T"][1] + HUB["H"][1] + side * mask[1]
    return {"T": (pitch, side * turn, roll, 0, 0, forward), "H": (mask[0] - pitch, side * (face - turn), mask[2])}


def struck(t, f):
    """The blow itself, the same in Hit and in Burst: the chest goes back and the struck shoulder with it, the sleeve
    on that side is left where it was, the other trails, and the mask snaps up."""
    t.key(f, "struck", **knocked(t, -27, 17 if t.mirror else 23, 3, -0.5, (-17, -5, -9)), RA=(20, 0, 22), LA=(58, 0, -28), crouch=0.2)


def hit(t):
    """The blow goes into it as into a hung sheet, off its middle. The chest is knocked away from you and one shoulder
    with it, so the coat twists on its peg, and the mask snaps up before it follows. Then the hem swings after it and
    the twist comes back past where it hung. The sleeves are left behind both times. The feet never move."""
    t.key(0, ease="out")
    struck(t, 3)
    t.key(9, "the hem swings after it", ease="sine", **knocked(t, 16, -8, -4, -0.5, (11, 4, 6)), RA=(-22, 0, 12),
          LA=(-34, 0, -12), crouch=0.14)
    t.key(15, ease="sine", **knocked(t, 3, 3, 2, -0.12, (1, -1, 12)), RA=(20, 0, 5), LA=(16, 0, -5), crouch=0.03)
    t.key(24, T=HUB["T"], RA=DOWN_R, LA=DOWN_L, H=HUB["H"], crouch=0.0)


def burst(t):
    """Whatever was holding it up lets go, and the mask goes first. In every other clip it never stops watching you;
    here it tips back until its face is to the sky and you see only its edge. The coat opens after it: the chest
    arches at you and the sleeves are drawn back behind its shoulders. Then it is light and paper: the game hides it at
    Burst. The feet stay where they stood, and nothing rises."""
    # the mask's last three numbers carry it a hand forward as it tips, so its chin swings clear of the collar's rim:
    # turned on the neck alone, the rim comes through the paper
    t.key(0, ease="out")
    struck(t, 4)
    t.key(12, ease="sine", T=(8, -6, -2, 0, 0, -0.2), RA=(-24, 0, 14), LA=(-30, 0, -12), H=(-10, 8, 4), crouch=0.1)
    t.key(20, "the mask lets go", ease="in", T=(-8, -3, 1, 0, 0, 0.1), RA=(-50, 0, 9), LA=(-56, 0, -7), H=(-44, 3, 2, 0, 0.08, -0.12), crouch=0.06)
    t.key(27, "its face to the sky", ease="out", T=(-21, -2, 0, 0, 0, 0.28), RA=(-78, 0, 8), LA=(-84, 0, -6), H=(-74, 2, 0, 0, 0.12, 0.08), crouch=0.08)
    t.mark(27, "Burst")
    t.key(34, T=(-22, -2, 0, 0, 0, 0.29), H=(-77, 2, 0, 0, 0.12, 0.08))  # a tail: a late hide shows nothing new


# name: (the clip, the mask it's shown in, mirrored). AttackLeft is Attack with the other sleeve, so a pack of Brawlers
# doesn't swing in step. HitLeft is Hit with the other shoulder knocked back, for a blow from the other side.
CLIPS = {"Idle": (idle, "Brawler", False), "Walk": (walk, "Brawler", False), "Attack": (attack, "Brawler", False),
         "AttackLeft": (attack, "Brawler", True), "Guard": (guard, "Guard", False), "Lunge": (lunge, "Dasher", False),
         "Hit": (hit, "Brawler", False), "HitLeft": (hit, "Brawler", True), "Burst": (burst, "Brawler", False)}
# A clip's Play and Stop fades, in seconds: the game's own where it has them (Shared.Config.Animations.Fades, which
# Author.SaveBaked checks these against). Guard's and Lunge's are proposed here: the game doesn't play them yet.
FADES = {"Idle": (0.2, 0.2), "Walk": (0.15, 0.15), "Attack": (0.06, 0.15), "AttackLeft": (0.06, 0.15), "Guard": (0.08, 0.15),
         "Lunge": (0.06, 0.15), "Hit": (0.03, 0.1), "HitLeft": (0.03, 0.1), "Burst": (0.03, 0.05)}


# --- outputs --------------------------------------------------------------------------------------------------------

def cameras(scene, rig):
    return {name: r6.body_camera(scene, rig, 0, az, el, distance=13.0, name=name) for name, (az, el) in (("game", GAME), ("side", SIDE))}


def pose_sheet(scene, cams, take, out):
    beats = take.beats
    shots = [(cams[view], take.start + f, f"{take.name} {f}: {label}" if view == "game" else f"{f}")
             for view in ("game", "side") for f, label in beats]
    scene.render.resolution_x, scene.render.resolution_y = 380, 420
    path = r6.render_shots(scene, shots, out / f"poses_{take.name}.png", columns=len(beats))
    print(f"wrote {path}")


def arc_sheet(scene, rig, cams, take, out):
    """One dot a frame where the right cuff (amber) and the left (pale) are through the clip, over the body at its
    middle beat: the arcs and their spacing."""
    frames = range(take.start, take.start + take.end + 1)

    def at(rig, arm):
        return r6.to_roblox(rig.parts[arm].matrix_world)

    dots = r6.path_dots(rig, frames, [("Right Arm", HAND)], radius=0.06, name="CuffR", at=at)
    dots += r6.path_dots(rig, frames, [("Left Arm", HAND)], colour=(0.92, 0.9, 0.82), radius=0.045, name="CuffL", at=at)
    beat = take.start + (take.beats[len(take.beats) // 2][0] if take.beats else 0)
    scene.render.resolution_x, scene.render.resolution_y = 640, 560
    path = r6.render_shots(scene, [(cams[view], beat, f"{take.name}: one dot a frame, {view}") for view in ("game", "side")],
                           out / f"arcs_{take.name}.png", columns=2)
    for dot in dots:
        bpy.data.objects.remove(dot, do_unlink=True)
    print(f"wrote {path}")


LOW = {"from low behind": (200.0, 2.0), "from low in front": (20.0, 2.0)}


def leg_ends(rig):
    return [r6.to_roblox(rig.parts[leg].matrix_world) @ Vector((0.0, -1.0, 0.0)) for leg in r6.LEGS]


def low_sheet(scene, rig, take, out):
    """What the content check asks of every clip: its widest leg lift, its widest stride and its last frame, from low
    behind and low in front, in the Strength red, at full size and at 64 px on the dusk floor and on a bright one. A
    leg's end must stay a dark hollow in a lit rim, and nothing may part from the coat."""
    lift, stride = {}, {}
    for f in range(take.end + 1):
        scene.frame_set(take.start + f)
        r6._refresh()
        a, b = leg_ends(rig)
        lift[f], stride[f] = max(a.y, b.y), abs(a.z - b.z)
    frames = sorted({max(lift, key=lift.get), max(stride, key=stride.get), take.beats[-1][0] if take.beats else 0, take.end})
    cams = [(label, r6.body_camera(scene, rig, take.start, az, el, distance=11.0, height=1.5, name=label)) for label, (az, el) in LOW.items()]
    shots = [(cam, take.start + f, f"{take.name} {f}, {label}") for label, cam in cams for f in frames]
    scene.render.resolution_x, scene.render.resolution_y = 360, 360
    big = rs.load(r6.render_shots(scene, shots, out / f"low_{take.name}_big.png", columns=len(shots)))
    floor, shading = bpy.data.materials["Floor"], scene.display.shading
    dusk = (tuple(floor.diffuse_color), tuple(shading.background_color))
    rows = [big]
    scene.render.resolution_x, scene.render.resolution_y = 64, 64
    for ground, sky in (dusk, ((0.86, 0.84, 0.8, 1.0), (0.78, 0.84, 0.92))):
        floor.diffuse_color, shading.background_color = ground, sky
        small = rs.load(r6.render_shots(scene, [(cam, frame, "") for cam, frame, _ in shots], out / f"low_{take.name}_64.png", columns=len(shots)))
        rows.append(np.repeat(np.repeat(small, 4, axis=0), 4, axis=1))
    floor.diffuse_color, shading.background_color = dusk
    width = max(row.shape[1] for row in rows)
    sheet = np.concatenate([np.pad(row, ((0, 0), (0, width - row.shape[1]), (0, 0))) for row in rows], axis=0)
    sheet[..., 3] = 1.0
    rs.save(sheet, out / f"low_{take.name}.png")
    for name in (f"low_{take.name}_big.png", f"low_{take.name}_64.png"):
        (out / name).unlink()
    print(f"wrote {out / f'low_{take.name}.png'} (frames {frames}; the 64 px rows are shown four times their size)")


NEAR = {"front": (24.0, 18.0), "side": (100.0, 6.0), "behind": (180.0, 18.0)}


def collar_sheet(scene, rig, take, wear, out, frames=None):
    """What the content check asks of a clip that tips the mask: its beats and its last frame close on the mask and
    the collar, in each of the four masks, from the player's side, from the side and from behind. The ties and the
    knot must stay behind the mask and out of the collar, and nothing red may show on the paper."""
    frames = frames or sorted({f for f, _ in take.beats} | {take.end})
    scene.render.resolution_x, scene.render.resolution_y = 280, 280
    for view, (az, el) in NEAR.items():
        cam = r6.body_camera(scene, rig, take.start, az, el, distance=5.6, height=4.5, name=f"near {view}")
        rows = []
        for kind in ss.MASKS:
            wear(kind)
            path = r6.render_shots(scene, [(cam, take.start + f, f"{take.name} {f}, {kind}") for f in frames],
                                   out / f"collar_{take.name}_{view}_{kind}.png", columns=len(frames))
            rows.append(rs.load(path))
            Path(path).unlink()
        rs.save(np.concatenate(rows, axis=0), out / f"collar_{take.name}_{view}.png")
        print(f"wrote {out / f'collar_{take.name}_{view}.png'} (frames {frames}; a row a mask)")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 2:]
    mode = args[0] if args and args[0] in ("poses", "export", "audit", "collar") else "poses"
    wanted = [a for a in args if a in CLIPS] or list(CLIPS)
    scene, rig, undress, wear, feet = build()
    takes = {}
    for i, (name, (clip, _, mirror)) in enumerate(CLIPS.items()):
        if name in wanted:
            takes[name] = take = Take(rig, feet, name, 1000 * i, mirror)
            clip(take)
            for line in take.warned:
                print("  " + line)
    rc.ground(rig, feet, list(takes.values()))
    cams = cameras(scene, rig)
    facts = {}
    for name, take in takes.items():
        wear(CLIPS[name][1])
        facts[name] = {"File": f"Shade_{name}.json", "Name": f"Shade{name}", "Fades": list(FADES[name]), "Frames": take.end + 1, "Seconds": round(take.end / FPS, 3), "Loop": take.loop,
                       "Markers": [[round(t * FPS), label] for t, label in take.markers], "ShownIn": CLIPS[name][1]}
        if CLIPS[name][2]:
            facts[name]["MirrorOf"] = next(n for n, c in CLIPS.items() if c[0] is CLIPS[name][0] and not c[2])
        if name == "Walk":  # the floor it covers in one loop: the builder sets the walk's speed from it, or the feet slide
            scene.frame_set(take.start)
            r6._refresh()
            a, b = leg_ends(rig)
            facts[name]["Stride"] = round(2 * abs(a.z - b.z), 2)
            facts[name]["StudsPerSecond"] = round(2 * abs(a.z - b.z) / (take.end / FPS), 2)
        print(f"{name}: {take.end + 1} frames, {take.end / FPS:.2f} s, in the {CLIPS[name][1]}'s mask")
        if mode == "poses":
            pose_sheet(scene, cams, take, out)
            continue
        if mode == "collar":
            collar_sheet(scene, rig, take, wear, out, [int(a) for a in args if a.isdigit()])
            continue
        heard = io.StringIO()  # the export audits itself aloud: the pack's notes keep what it said
        with contextlib.redirect_stdout(heard):
            # the Name is the game's: Author.SaveBaked reads Anim_Shade<Clip> and checks the clip is named the same
            r6.export(rig, out / f"Shade_{name}.json", "Shade", f"Shade{name}", take.start, take.start + take.end,
                      markers=take.markers, source="tools/blender/shade_clips.py",
                      extra={"Loop": take.loop, "FadeIn": FADES[name][0], "FadeOut": FADES[name][1]})
        print(heard.getvalue(), end="")
        if mode == "audit":
            continue
        arc_sheet(scene, rig, cams, take, out)
        low_sheet(scene, rig, take, out)
        strip = [take.start + round(i * take.end / 11) for i in range(12)]
        r6.review_pack(scene, rig, out / f"pack_{name}", [(take.start + f, f"{name} {f}: {label}") for f, label in take.beats],
                       lambda frame: cams["game"], bare=GAME[0], strip=strip, undress=undress, notes=heard.getvalue())
    if mode != "poses" and len(takes) == len(CLIPS):
        (out / "Shade.clips.json").write_text(json.dumps({"Fps": FPS, "Clips": facts}, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {out / 'Shade.clips.json'}")


if __name__ == "__main__":
    main()
