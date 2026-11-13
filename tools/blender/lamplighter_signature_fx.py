"""The Lamplighter's signature effect as a grey block-in on its delivered clip (AR7, section 6). Research's ask,
2026-11-13: the bold thing is the wrench at 106, the lantern over its hat, and the effect serves it: the light gathering
in the lantern through the hold, then the slam landing by your fighter. Built to docs/research/vfx-reference.md's rules
at rung 8: one main shape, its peak in the first quarter of its life and an eased fade, the secondary a breath later,
lower and softer.

blender.exe -b --factory-startup --python tools/blender/lamplighter_signature_fx.py -- <out_dir> [A B C]

Timing and size only: plain shapes in white and grey, no art, on B1's stage (pip_burst_fx.py, pip_burst_rework.py). The
keeper plays its delivered Signature clip (build/handoff/Lamplighter/clips/) and the effect hangs on its markers: Plant
24, Light 44, Wrench 106, Slam 118. White is the main shape, mid grey the secondary.

Shared by every variant:
- the gathering: on the Light the lantern lights round its drum, mid grey through the hold and white from the look up at
  you (96), and motes are drawn into it, closer together toward the wrench. On the Wrench it flares round, the top
  value for two frames, and stays white through the hang, round and smaller, so over the hat it stays inside the frame;
- the descent: its trail from over the hat down to your fighter, 110 to 118, one streak round at the light;
- the slam spends it: the lantern's light is out from 118, so nothing lit lies on the floor, and the light only goes up
  and out from there.
The slam, by variant, where the lantern lands by your fighter:
- A, the column: the light leaps back up out of the floor, a fat flame round your fighter, near twice the keeper's
  height in three frames; then its foot lets go of the floor and it climbs and thins. Chips of light are flung off its
  edge a breath later (a low wall read as a ring painted on the floor).
- B, the shock: a wall of light runs out over your fighter's feet from where it struck, rising off the floor as it goes
  and sinking; light chips are flung up and out a breath later.
- C, A under the seed's circle: A's slam, and through the hold AR7's seed circle stood up as a wall of light round
  where the lantern will land, waist high to your fighter, drawing in from the Light to the Wrench, where it goes white
  with the flare. A wall, never a disc. Set beside A, it asks one thing: does the circle add to the gathering's tell?

Cameras, as the game frames a keeper (Config.Combat): the avatar arrives Keeper.Arrive studs from it, turned Keeper.Turn
degrees off it so the fight sits right of the frame's middle, and the lead takes the keeper's side (Lead.Beside, 90) away
from the avatar's line of sight, the keeper facing it. The player's camera is 12.5 studs behind the avatar, pitched 14
degrees down at its head, at the game's 70 degrees (B1's). So the keeper is seen from its right, a touch from behind,
with the lead to its right on the screen, and the slam comes down across the screen on the near side. Also drawn: the
ring camera the clips were judged from (lamplighter_clips.cameras), the keeper's left flank from afar, a bright floor,
and the game's camera at the size where the keeper stands 64 px tall.
Stage directions are in the keeper's units (the game scales it by 1.5): right, forward, up from where it stands.
"""
import json
import math
import random
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import lamplighter_clips as lc  # noqa: E402
import pip_burst_fx as pf  # noqa: E402  (the shapes, smooth, toward, share)
import r6anim as r6  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (camera, render_variants, clamp, out_fast)

CLIP = r6.REPO / "build" / "handoff" / "Lamplighter" / "clips" / "Lamplighter_Signature.json"
PLANT, LIGHT, LOOK, WRENCH, HANG, SLAM = 24, 44, 96, 106, 110, 118  # the markers, the look up at you, the hang
MARKS = {"Plant": PLANT, "Light": LIGHT, "Wrench": WRENCH, "Slam": SLAM}
NAMES = {f: name for name, f in MARKS.items()}
LIFE = 26  # the slam's frames, 118 to 144: gone while the keeper holds the pole down
S = lc.SCALE  # studs a keeper's unit
ARRIVE = lc.row_number("Keeper = {", "Arrive", lc.COMBAT)  # studs from the keeper the avatar stands
TURN = lc.row_number("Keeper = {", "Turn", lc.COMBAT)  # degrees its facing turns off the keeper
BESIDE = lc.row_number("Beside = {", "Keeper", lc.COMBAT)  # degrees off the avatar's facing the lead stands round it
HEAD = 4.5  # studs up to the avatar's head, where the camera looks
BODY = (("Legs", (2.0, 1.0, 2.0), 1.0), ("Body", (4.0, 1.0, 2.0), 3.0), ("Head", (1.2, 1.2, 1.2), 4.6))  # B1's, studs
MOTE_FLIGHT, MOTE_FROM = 12, 3.4  # frames a mote takes in, and how far out past the light it sets off
CHIPS, TRAIL = 9, 5
COLUMN = (3.8, 11.2)  # A's and C's column at its peak: its radius at the belly and its height, in the keeper's units.
# From the game's camera the frame's top is about 12 up at the lead: the peak stands inside it. At 2.3 by 10 it held 2.5%
# of the screen and at 3.4 by 10.5 3.8%, under Pip's coil (4.4%): too small for the keeper's signature, rung 8 over 7
UP = Vector((0.0, 0.0, 1.0))
SHEET = (PLANT, LIGHT, 70, LOOK, 102, WRENCH, 108, HANG, 114, 116, SLAM, 119, 120, 122, 124, 127, 130, 136, 140, 146)
STRIP = (LOOK, WRENCH, 112, 116, SLAM, 119, 121, 124, 128, 134, 142)
SHARE = (WRENCH, SLAM, 119, 120, 121, 122, 124, 127, 130, 136, 144)


def grow(t, frames):
    """Out fast over `frames`, already past half on the slam's frame itself."""
    return hx.out_fast((t + 1) / (frames + 1))


def let_go(t, start):
    """From `start` to the end of the life: fast at first, so the shape is leaving while it's still bright (B1's H)."""
    return 1 - (1 - hx.clamp((t - start) / (LIFE - start))) ** 1.7


# --- the shared beats ------------------------------------------------------------------------------------------------

def halo(f):
    """The lantern's light on frame f: its radius, shade and height over its radius; None outside the hold."""
    if not LIGHT <= f < SLAM:
        return None
    if f < LOOK:
        return 1.12 + 0.2 * pf.smooth((f - LIGHT) / (LOOK - LIGHT)), "mid", 1.2
    if f < WRENCH:
        return 1.32 + 0.33 * ((f - LOOK) / (WRENCH - LOOK)) ** 2, "white", 1.2
    # round, not drum-tall: from the game's camera the wrench's lantern is at the frame's top
    return {WRENCH: 2.0, WRENCH + 1: 1.8}.get(f, 1.5), "white", 1.0


def gathering(stage, f):
    """The light in the lantern from the Light to the slam, the motes drawn into it, and its trail down."""
    out, at, light = [], stage.lamp[f], halo(f)
    if light:
        r, shade, tall = light
        out.append(("ball", shade, at, (r, r, tall * r), Quaternion()))
    for start, way in stage.motes:
        a = f - start
        if 0 <= a < MOTE_FLIGHT:
            u = a / MOTE_FLIGHT
            p = at + way * (1.0 + MOTE_FROM * (1 - u * u))  # slow to start and fast at the end, into the light's edge
            out.append(("box", "mid", p, (0.24, 0.24, 0.4 + 1.4 * u), pf.toward(way)))
    if HANG < f <= SLAM:  # the trail: one streak back along the fall, round at the light and pointed at its tail
        head, tail = stage.lamp[f], stage.lamp[max(HANG, f - TRAIL)]
        span = tail - head
        if span.length > 0.3:
            out.append(("flame", "white", head + span / 2, (1.3, 1.3, span.length + 1.0), pf.toward(span)))
    return out


def flash(stage, t):
    """The slam's punctuation where the lantern lands: two frames, the top value."""
    r = {0: 2.8, 1: 1.9}.get(t, 0.0)
    return [("ball", "white", Vector((stage.hit.x, stage.hit.y, 0.8 * r)), (r, r, r), Quaternion())] if r else []


# --- the slam, by variant --------------------------------------------------------------------------------------------

def chips(stage, t, start=3, edge=0.0, size=0.55):
    """The secondary, a breath after the peak: chips of light flung up and out from `edge` round where it struck,
    lower and softer than the main shape, and never on the floor."""
    p, out = stage.hit, []
    for angle, reach, lift, lag in stage.chips:
        a = t - start - lag
        if 0 <= a <= 18:
            d, s = edge + 5.0 * reach * hx.out_fast(a / 10), size * (1 - a / 18) ** 0.8
            centre = Vector((p.x + d * math.cos(angle), p.y + d * math.sin(angle), 0.6 + 5.5 * lift * hx.out_fast(a / 14)))
            out.append(("box", "mid", centre, (s, s, s), Quaternion(UP, angle)))
    return out


def column(stage, t):
    """A: a fat flame of light up out of the floor, round your fighter, then it lets go of it, climbs and thins.
    Chips are flung off its edge a breath later: B1's low wall read here as a ring painted on the floor."""
    p, out = stage.hit, []
    rise, gone = grow(t, 3), let_go(t, 3)
    if gone < 1:
        h = COLUMN[1] * rise * (1 - 0.4 * gone)
        rb = COLUMN[0] * (0.75 + 0.25 * rise) * (1 - 0.8 * gone)
        if rb > 0.08:
            out.append(("flame", "white", Vector((p.x, p.y, 10.0 * gone ** 1.4 + h / 2)), (rb, rb, h), Quaternion()))
    return out + flash(stage, t) + chips(stage, t, start=4, edge=0.8 * COLUMN[0], size=0.75)


def shock(stage, t):
    """B: a wall of light running out from the slam, rising off the floor as it goes and sinking; chips up and out."""
    p, out = stage.hit, []
    r = 1.2 + 6.3 * grow(t, 7)
    h = 2.6 * (1 - hx.clamp((t - 1) / 13)) ** 1.3
    if h > 0.06:
        out.append(("tube", "white", Vector((p.x, p.y, 1.3 * hx.clamp(t / 14) ** 1.2 + h / 2)), (r, r, h), Quaternion()))
    return out + flash(stage, t) + chips(stage, t)


def circle(stage, f):
    """C's tell, AR7's seed circle stood up: a wall of light round where the lantern will land, waist high to your
    fighter, from the Light, drawing in to the Wrench, where it goes white with the flare. A wall, never a disc: a light
    low by the floor reads as a pool."""
    if not LIGHT <= f < SLAM:
        return []
    tight = pf.smooth((f - LIGHT) / (WRENCH - LIGHT))
    r, h = 2.8 - 0.6 * tight, (0.8 + 0.6 * tight) * hx.clamp((f - LIGHT + 1) / 6)
    return [("tube", "white" if f >= WRENCH else "mid", Vector((stage.hit.x, stage.hit.y, h / 2)), (r, r, h), Quaternion())]


# name: (what it is, the slam, whether the circle shows through the hold). C is A's slam with the seed's circle, so the
# two set side by side answer one question: does the circle add to the tell the gathering makes?
VARIANTS = {"A": ("the column", column, False), "B": ("the shock", shock, False),
            "C": ("the column, under the seed's circle", column, True)}


def layout(stage, variant, f):
    _, slam, tell = VARIANTS[variant]
    out, t = gathering(stage, f) + (circle(stage, f) if tell else []), f - SLAM
    return out + (slam(stage, t) if 0 <= t <= LIFE + 4 else [])


def size_of(stage, variant, f):
    """How tall the effect stands on a frame, and how far it reaches from where the lantern lands, in studs."""
    top, reach, p = 0.0, 0.0, stage.hit
    for kind, _, centre, size, _ in layout(stage, variant, f):
        top = max(top, centre.z + (max(size) / 2 if kind == "box" else size[2] / 2))
        across = max(size[0], size[1]) if kind in ("ball", "flame", "tube") else max(size) / 2
        reach = max(reach, (centre.xy - p.xy).length + across)
    return round(top * S, 1), round(reach * S, 1)


# --- the stage -------------------------------------------------------------------------------------------------------

def placed():
    """Where the avatar stands in the keeper's stage and the way it looks: the game's (the module's notes)."""
    if round(BESIDE) != 90:
        raise SystemExit(f"Lead.Beside.Keeper is {BESIDE}: this stage puts the lead square to the avatar's facing")
    look, right = Vector((-1.0, 0.0)), Vector((0.0, 1.0))  # the lead, at the keeper's front, is to the right on screen
    seen = look * math.cos(math.radians(TURN)) + right * math.sin(math.radians(TURN))  # the keeper, TURN off the facing
    return -seen * (ARRIVE / S), look


def game_camera(scene, name, fov=70.0):
    spot, look = placed()
    back = pf.EYE / S
    return hx.camera(scene, name, math.degrees(math.atan2(-look.x, -look.y)), pf.PITCH,
                     back / math.cos(math.radians(pf.PITCH)), (spot.x, spot.y, HEAD / S), fov)


def headroom(stage, camera):
    """How far the top of the lantern's light stands over the frame's top edge from `camera`, in degrees, on each frame
    from the look up to the slam (below zero, inside the frame)."""
    inv, edge, over = camera.matrix_world.inverted(), math.degrees(camera.data.angle_y) / 2, {}
    for f in range(LOOK, SLAM):
        r, _, tall = halo(f)
        local = inv @ (stage.lamp[f] + Vector((0.0, 0.0, tall * r)))
        over[f] = round(math.degrees(math.atan2(local.y, -local.z)) - edge, 1)
    return over


class Stage:
    """The shapes the block-in is drawn with, set on every frame from the variant's layout; and the stand-ins."""

    def __init__(self, scene, lantern, frames):
        self.variant, self.show = "A", True
        self.materials = {shade: r6.flat_material(f"Fx.{shade}", colour) for shade, colour in pf.SHADES.items()}
        self.pool = {}
        middle = sum((Vector(c) for c in lantern.bound_box), Vector()) / 8
        self.lamp = []  # the drum's middle on every frame, read once from the keyed clip
        for f in range(frames):
            scene.frame_set(f)
            r6._refresh()
            self.lamp.append(lantern.matrix_world @ middle)
        self.hit = Vector((self.lamp[SLAM].x, self.lamp[SLAM].y, 0.0))
        rng = random.Random(29)
        self.motes, f, gap = [], float(LIGHT), 7.0
        while f < WRENCH - 2:
            way = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.2, 1.0))).normalized()
            self.motes.append((round(f), way))
            f, gap = f + gap, max(1.6, gap * 0.9)
        self.chips = [(i * 2 * math.pi / CHIPS + rng.uniform(-0.3, 0.3), rng.uniform(0.6, 1.0), rng.uniform(0.5, 1.0),
                       rng.randint(0, 2)) for i in range(CHIPS)]
        body = tuple((part, tuple(v / S for v in size), z / S) for part, size, z in BODY)
        spot, look = placed()
        self.avatar = pf.Stage.figure("Avatar", (spot.x, spot.y), math.atan2(look.y, look.x) - math.pi / 2,
                                      r6.flat_material("Fx.Avatar", (0.42, 0.42, 0.45)), body)
        self.avatar_boxes = list(self.avatar.children)
        pf.Stage.figure("Lead", (0.0, lc.REACH), 0.0, r6.flat_material("Fx.Lead", (0.30, 0.32, 0.38)), body)
        bpy.app.handlers.frame_change_pre.append(self.set)

    def make(self, kind, shade):
        if kind != "tube":
            return pf.Stage.make(self, kind, shade)
        bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=1.0, depth=1.0, end_fill_type="NOTHING")
        obj = bpy.context.active_object  # an open tube a stud tall about its middle, for the walls (B1's)
        obj.data.materials.append(self.materials[shade])
        obj.display.show_shadows, obj.rotation_mode, obj.hide_render = False, "QUATERNION", True
        return obj

    def set(self, scene, *_):
        f = scene.frame_current
        seen = scene.camera.name.startswith("game") if scene.camera else False
        for box in self.avatar_boxes:  # the avatar only where the camera is behind it
            box.hide_render = not seen
        used = {}
        for kind, shade, centre, size, turn in (layout(self, self.variant, f) if self.show and f < len(self.lamp) else []):
            pool = self.pool.setdefault((kind, shade), [])
            n = used.get((kind, shade), 0)
            if n == len(pool):
                pool.append(self.make(kind, shade))
            obj = pool[n]
            used[(kind, shade)] = n + 1
            obj.location, obj.scale, obj.rotation_quaternion, obj.hide_render = centre, size, turn, False
        for key_, pool in self.pool.items():
            for obj in pool[used.get(key_, 0):]:
                obj.hide_render = True


def key(rig):
    """The delivered clip, keyed on the rig as the game plays it."""
    data = json.loads(CLIP.read_text())
    missing = {part for frame in data["Frames"] for part in frame["Poses"]} - set(rig.joints)
    if missing:
        raise SystemExit(f"the rig has no joint for {sorted(missing)}")
    for frame in data["Frames"]:
        f = round(frame["T"] * data["Fps"])
        for part, pose in frame["Poses"].items():
            joint = rig.joints[part]
            joint.matrix_basis = r6.to_blender(r6.cframe(pose))
            joint.keyframe_insert("location", frame=f)
            joint.keyframe_insert("rotation_quaternion", frame=f)
    marks = {m["Name"]: round(m["T"] * data["Fps"]) for m in data["Markers"]}
    if marks != MARKS:
        raise SystemExit(f"the clip's markers are {marks}, not {MARKS}")
    return len(data["Frames"])


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def keeper_64(scene, camera):
    """The 16:9 tile in which the keeper, floor to hat at rest, stands 64 px tall from `camera`."""
    scene.render.resolution_x, scene.render.resolution_y = 960, 540
    scene.frame_set(0)
    low, high = (world_to_camera_view(scene, camera, Vector((0.0, 0.0, z))) for z in (0.0, lc.HAT_TOP))
    h = round(64 / abs(high.y - low.y))
    return round(h * 16 / 9), h


def bare_rows(scene, stage, camera, frames, wanted, size, path):
    """Each variant's frames from `camera` at `size`, a row each in `wanted`'s order, with no labels (at 64 px a
    label covers the picture) and a dark line between tiles."""
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.use_stamp = False
    shot, rows = path.with_name(f"{path.stem}_tile.png"), []
    for key_ in wanted:
        stage.variant, tiles = key_, []
        for f in frames:
            scene.frame_set(f)
            scene.render.filepath = str(shot)
            bpy.ops.render.render(write_still=True)
            image = bpy.data.images.load(str(shot))
            tile = np.array(image.pixels[:], dtype=np.float32).reshape(size[1], size[0], 4)
            bpy.data.images.remove(image)
            tile[:, -2:] = (0.0, 0.0, 0.0, 1.0)
            tile[:2] = (0.0, 0.0, 0.0, 1.0)  # the bottom rows: Blender images start at the bottom
            tiles.append(tile)
        rows.append(np.concatenate(tiles, axis=1))
    shot.unlink()
    sheet = np.concatenate(rows[::-1], axis=0)
    image = bpy.data.images.new(path.stem, sheet.shape[1], sheet.shape[0], alpha=True)
    image.pixels = sheet.ravel()
    image.filepath_raw, image.file_format = str(path), "PNG"
    image.save()
    return path


def main():
    sys.stdout.reconfigure(line_buffering=True)
    out = bl.out_dir()
    wanted = [a for a in sys.argv[sys.argv.index("--") + 2:] if a in VARIANTS] or list(VARIANTS)
    scene, rig, costume, *_ = lc.build(out)
    frames = key(rig)
    stage = Stage(scene, costume[lc.LAMP], frames)
    spot, _ = placed()
    lead = Vector((0.0, lc.REACH))
    print(f"Signature: {frames} frames, the markers at {MARKS}. The avatar at {tuple(round(v, 2) for v in spot)}, "
          f"the lead at {tuple(lead)}, the keeper at the middle, in its units")
    for name, f in {**MARKS, "look": LOOK, "hang": HANG}.items():
        print(f"  the lantern's middle at {name} ({f}): {tuple(round(v, 2) for v in stage.lamp[f])}")
    print(f"  it lands at {tuple(round(v, 2) for v in stage.hit.xy)}, {(stage.hit.xy - lead).length * S:.1f} studs from "
          f"the lead's middle")
    cams = lc.cameras(scene, rig)
    game = game_camera(scene, "game")
    flank = lc.stage_camera(scene, -90.0, 4.0, 30.0, (0.0, 2.0, 6.0), fov=40.0, name="flank")
    bpy.data.objects["Floor"].scale *= 4  # past the cameras' edges
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    tile64 = keeper_64(scene, game)
    print(f"  the keeper stands 64 px tall from the game's camera in a {tile64[0]} by {tile64[1]} tile")
    over = headroom(stage, game)
    cut = [f for f, v in over.items() if v > 0]
    print(f"  the light's top over the game frame's top edge: {over[LOOK]} degrees at the look, {over[WRENCH]} on the "
          f"wrench, at most {max(over.values())}; over it on {len(cut)} frames ({cut[0] if cut else '-'} to "
          f"{cut[-1] if cut else '-'})")
    for key_ in wanted:
        stage.variant = key_
        scene.render.resolution_x, scene.render.resolution_y = 480, 270
        title = f"{key_}, {VARIANTS[key_][0]}: "
        shots = [(game, f, title + label(f) if f == SHEET[0] else label(f)) for f in SHEET]
        print(f"wrote {r6.render_shots(scene, shots, out / f'signature_{key_}.png', columns=5)}")
    tile = (256, 144)
    for view, camera in (("ring", cams["ring"]), ("flank", flank)):
        shots = [(camera, f, f"{k} {f}", k) for k in wanted for f in STRIP]
        print(f"wrote {hx.render_variants(scene, stage, shots, out / f'signature_{view}.png', len(STRIP), tile)}")
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    shots = [(game, f, f"{k} {f}", k) for k in wanted for f in STRIP]
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'signature_bright.png', len(STRIP), tile)}")
    floor.diffuse_color = dusk
    print(f"wrote {bare_rows(scene, stage, game, STRIP, wanted, tile64, out / 'signature_64.png')}")
    pf.SHARE = SHARE
    table = {
        "markers": MARKS, "strip": STRIP, "tile64": tile64,
        "lantern": {name: [round(v, 2) for v in stage.lamp[f]] for name, f in {**MARKS, "look": LOOK}.items()},
        "lands": [round(v, 2) for v in stage.hit.xy], "lead": [0.0, round(lc.REACH, 2)],
        "light_over_the_top_degrees": {f: over[f] for f in range(LOOK, SLAM, 2)},
        "share": pf.share(scene, stage, game, wanted, out / "share.png"),
        "size_studs": {k: {f: size_of(stage, k, f) for f in SHARE} for k in wanted},
    }
    (out / "signature.json").write_text(json.dumps(table, indent=1))
    print(json.dumps(table["share"]), json.dumps(table["size_studs"]))


if __name__ == "__main__":
    main()
