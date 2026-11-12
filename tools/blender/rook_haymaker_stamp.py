"""Haymaker's option B as a grey block-in, in five variants B1 to B5: the ram's square driven down from above onto the target (AR1, section 8,
research's read of round 2; a tier 1 exploration, so the director picks from pictures).

blender.exe -b --factory-startup --python tools/blender/rook_haymaker_stamp.py -- <out_dir> [B1 B2 ...]

Timing and size only: plain boxes in two greys and a dark rim, no art. Rook plays his delivered Haymaker clip, and the
effect hangs on its markers: Charge 8, Strike 57, Shock 58, Step 63, Vent 70. The hit lands on Strike, so the square
lands on Strike. The art stays the one bar (Config.Effects.Haymaker): every square here is four of its strokes.

Shared by every variant, as the game has it now: the charge's square drawn tight on the ram's face through the hold,
and the punctuation, the same square thrown open round the ram on Strike and Shock. Then, by variant:
- B1, the drop: the square, flat and the target's footprint wide, appears high over the target four frames before
  Strike and falls on it, faster and faster, to stamp the floor round its feet on the Strike frame. On Shock it kicks
  open; a thinner square runs out along the floor from it; the stamp is eaten where it landed.
- B2, the weight lifted: through the hold the square forms over the target's head and rises, drawn tight, to the top
  of its drop, the way a pile driver's weight is hauled up; then it falls as B1's. The tell says where it lands.
- B3, the drop and its shaft: B1's fall, stretched along its travel while it's fast, so the square is a chute of light
  for the frames it falls; it lands flat on Strike.
- B4, the face slammed down: the square stands up facing the camera, whichever it is, so its face always shows; it
  drops onto the target stretched tall while it's fast, lands round its legs on Strike and squashes flat into the
  floor on Shock, two bars running out along the floor from its feet.
- B5, the face lifted and slammed: B4, with B2's tell: through the hold the upright square forms over the target's head,
  facing the camera, and rises, drawn tight, to the top of its drop; then B4's slam.
The stand-in Shade is pushed down the line as the game pushes it (Push 4, from the bracket's second frame), so it
slides out of the stamp toward the avatar; whether a blow from above should pin it instead is the design's call.

Cameras as pip_burst_fx.py and lyric_note_fx.py frame a fight (Config.Combat.Lead): the lead stands beyond its target
turned Frame (45) round; the camera 12.5 studs behind the avatar, at 70 degrees. "beside" is an elite's (90), "hidden"
the avatar dead on. The headings sheet turns the same staging round the target every 45 degrees, for whether a blow
from above reads from any camera. Stage directions as rook_clips.py: right, forward, up, in studs, from where he stands.
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
import rook_clips as rc  # noqa: E402
import rook_haymaker_fx as hx  # noqa: E402  (camera, render_variants, clamp, out_fast, KNUCKLES)

CLIP = Path(__file__).resolve().parents[2] / "build" / "handoff" / "Rook" / "clips" / "Rook_Haymaker.json"
MARKS = {"Charge": 8, "Strike": 57, "Shock": 58, "Step": 63, "Vent": 70}
WIND, HELD, STRIKE, SHOCK = 34, 52, 57, 58
TARGET = (0.0, 6.0)        # Definitions.Actions.RookHaymaker.Range: 6 studs root to root
PUSH, KNOCK, PUSHED = 4.0, 60, 6  # the game's push: studs, the frame it starts (the bracket's second), frames it takes
SIDE, BAR, THICK = 4.6, 0.85, 0.35  # the stamp: its side (the target's footprint and a margin), its bar, how thick
TOP, DROP = 10.0, 4        # the drop: studs over the floor it starts, and frames it falls (to land on Strike)
RISE = 36                  # B2, B5: the frame the weight starts up from the target's head
BACK, EYE, PITCH = 8.0, 12.5, 14.0
LOOKS = {"fight": (-45.0, 26.0), "beside": (0.0, 26.0), "hidden": (-45.0, 0.0)}
SHADES = {"white": (0.93, 0.93, 0.93), "mid": (0.6, 0.6, 0.6), "dark": (0.02, 0.02, 0.025)}
SHEET = (34, 46, 52, 53, 54, 55, 56, 57, 58, 59, 61, 64, 67, 70, 74, 80)
STRIP = (52, 54, 55, 56, 57, 58, 60, 64, 70)
SHARE = (53, 55, 56, 57, 58, 60, 64, 70)
HEADINGS = range(0, 360, 45)
NAMES = {f: name for name, f in MARKS.items()} | {34: "wound", 52: "held"}


def clamp(u):
    return hx.clamp(u)


def staged(name):
    """A camera's way of looking, and where the avatar stands for it: "fight" and the rest, or "h<degrees>"."""
    name = name.removesuffix("50")
    heading, turn = (float(name[1:]), 26.0) if name[1:].isdigit() else LOOKS[name]
    h, g = math.radians(heading), math.radians(heading + turn)
    return Vector((math.cos(h), math.sin(h))), Vector(TARGET) - Vector((math.cos(g), math.sin(g))) * BACK


# --- shapes -----------------------------------------------------------------------------------------------------------

def square(out, x, y, z, side, bar, tall=THICK, shade="white", rim=False):
    """Four strokes lying flat round (x, y), their bottom at z, `tall` high. On the floor, `rim` lays a dark copy a
    little wider flat under it: the art's rim, seen from above."""
    for sign in (-1, 1):
        out.append((shade, (x, y + sign * side / 2, z + tall / 2), (side + bar, bar, tall)))
        out.append((shade, (x + sign * side / 2, y, z + tall / 2), (bar, side + bar, tall)))
        if rim:
            b = bar + 0.3
            out.append(("dark", (x, y + sign * side / 2, 0.015), (side + b, b, 0.03)))
            out.append(("dark", (x + sign * side / 2, y, 0.015), (b, side + b, 0.03)))


def upright(out, x, y, z, side, bar):
    """The punctuation's square standing across the line at the ram, as the game draws it (Effects.Haymaker.Strike)."""
    for shade, grow, back in (("dark", 0.16, 0.12), ("white", 0.0, 0.0)):
        for sign in (-1, 1):
            out.append((shade, (x, y + 0.3 + back, z + sign * side / 2), (side + bar + grow, 0.1, bar + grow)))
            out.append((shade, (x + sign * side / 2, y + 0.3 + back, z), (bar + grow, 0.1, side + bar + grow)))


def height(f):
    """How high the stamp's underside is while it falls: from TOP, faster and faster, to the floor on Strike."""
    u = clamp((f - (STRIKE - DROP)) / DROP)
    return 0.04 + (TOP - 0.04) * (1 - u * u)


def landed(out, f):
    """From Strike: the stamp on the floor, kicked open on Shock and eaten where it landed; a thinner square running
    out along the floor from it."""
    t = f - STRIKE
    if t < 0:
        return
    x, y = TARGET
    eaten = clamp((t - 3) / 12)
    side = SIDE * (1.0 if t == 0 else 1.1 + 0.04 * clamp(t / 12))
    if eaten < 1:
        square(out, x, y, 0.04, side, BAR * (1 - eaten) + 0.02, THICK * (1 - 0.5 * eaten), rim=True)
    run = hx.out_fast(t / 8)
    if t <= 9:
        square(out, x, y, 0.03, SIDE * (1.1 + 1.2 * run), 0.5 * (1 - run) + 0.04, 0.12, shade="mid")


def drop(out, f):
    """B1: the stamp falls from TOP onto the target, to land on Strike."""
    if STRIKE - DROP <= f < STRIKE:
        square(out, *TARGET, height(f), SIDE, BAR)
    landed(out, f)


def lifted(out, f):
    """B2: the weight hauled up over the target's head through the hold, drawn tight, then the drop."""
    if RISE <= f < STRIKE - DROP:
        u = clamp((f - RISE) / (STRIKE - DROP - 2 - RISE))
        ease = 1 - (1 - u) ** 2
        side = SIDE * (0.65 + 0.35 * ease)
        square(out, *TARGET, 5.6 + (TOP - 5.6) * ease, side, 0.3 + (BAR - 0.3) * ease)
    drop(out, f)


def shaft(out, f):
    """B3: the drop stretched along its travel: the square a chute from where it was a frame ago down to where it is."""
    if STRIKE - DROP <= f < STRIKE:
        low, high = height(f), (TOP if f == STRIKE - DROP else height(f - 1)) + THICK
        square(out, *TARGET, low, SIDE, BAR, tall=max(THICK, 0.8 * (high - low)))
    landed(out, f)


def face(out, f, facing, lift=False):
    """B4: the square upright and turned to the camera (`facing`, the floor's way from the target to it), dropped onto
    the target stretched while it's fast, landed on Strike and squashed flat on Shock; then two bars run out along the
    floor from its feet, and it's eaten where it lies."""
    u = Vector((-facing.y, facing.x))  # across the square, as the camera sees it
    yaw = math.atan2(u.y, u.x)
    x, y = TARGET
    t = f - STRIKE
    if lift and RISE <= f < STRIKE - DROP:  # B5: hauled up over the target's head through the hold, drawn tight
        u_ = clamp((f - RISE) / (STRIKE - DROP - 2 - RISE))
        ease = 1 - (1 - u_) ** 2
        w = h = SIDE * (0.65 + 0.35 * ease)
        z, bar, eaten = 5.6 + (TOP - 5.6) * ease, 0.3 + (BAR - 0.3) * ease, 0.0
    elif -DROP <= t < 0:
        fast = clamp((t + DROP) / (DROP - 1))
        w, h, z = SIDE * (1 - 0.15 * fast), SIDE * (1 + 0.35 * fast), height(f)
        bar, eaten = BAR, 0.0
    elif t >= 0:
        squash = (0.55, 0.3, 0.26, 0.24)[min(t, 3)]
        w, h, z = SIDE * (1.3 if t == 0 else 1.55 + 0.05 * clamp((t - 1) / 10)), SIDE * squash, 0.04
        eaten = clamp((t - 3) / 12)
        bar = BAR * (1 - eaten) + 0.02
        if t <= 9:  # two bars running out along the floor from its feet, the way the camera sees across
            run = hx.out_fast(t / 8)
            for sign in (-1, 1):
                reach = w / 2 + 4.5 * run
                mid = (w / 2 + reach) / 2
                c = Vector((x, y)) + u * sign * mid
                out.append(("mid", (c.x, c.y, 0.08), (reach - w / 2 + 0.01, 0.5 * (1 - run) + 0.05, 0.16), yaw))
    else:
        return
    if eaten >= 1:
        return
    for sign in (-1, 1):  # the posts, then the two bars across
        c = Vector((x, y)) + u * sign * w / 2
        out.append(("white", (c.x, c.y, z + h / 2), (bar, 0.3, h + bar), yaw))
    for top in (0, 1):
        out.append(("white", (x, y, z + h * top), (w + bar, 0.3, bar), yaw))


VARIANTS = {"B1": ("the drop", drop), "B2": ("the weight lifted", lifted), "B3": ("the drop and its shaft", shaft),
            "B4": ("the face slammed down", None), "B5": ("the face lifted and slammed", None)}


def layout(stage, variant, f):
    out = []
    if f in (STRIKE, SHOCK):  # the punctuation, as the game has it
        side, bar = (3.0, 0.8) if f == STRIKE else (3.7, 0.7)
        upright(out, *stage.knuckles, side, bar)
    if variant in ("B4", "B5"):
        face(out, f, stage.facing, lift=variant == "B5")
    else:
        VARIANTS[variant][1](out, f)
    return [shape if len(shape) == 4 else (*shape, 0.0) for shape in out]


# --- the stage --------------------------------------------------------------------------------------------------------

class Stage:
    def __init__(self, scene, rig, knuckles):
        self.variant, self.show, self.knuckles = "B1", True, knuckles
        self.facing = Vector((0.0, -1.0))
        self.materials = {shade: r6.flat_material(f"Fx.{shade}", colour) for shade, colour in SHADES.items()}
        self.pool = {shade: [] for shade in SHADES}
        shade = r6.flat_material("Fx.Shade", (0.30, 0.28, 0.33))
        grey = r6.flat_material("Fx.Avatar", (0.42, 0.42, 0.45))
        self.target = self.figure("Target", TARGET, shade, (("Coat", (2.6, 1.4, 4.4), 2.4), ("Mask", (1.3, 1.1, 1.2), 5.2)))
        self.avatar = self.figure("Avatar", (0, 0), grey, (("Legs", (2.0, 1.0, 2.0), 1.0), ("Body", (4.0, 1.0, 2.0), 3.0),
                                                           ("Head", (1.2, 1.2, 1.2), 4.6)))
        self.avatar_boxes = list(self.avatar.children)
        self.ring = [self.box("white") for _ in range(4)]  # the charge, on the ram's face
        for bar in self.ring:
            bar.parent = rig.parts["Right Arm"]
        bpy.app.handlers.frame_change_pre.append(self.set)

    @staticmethod
    def figure(name, at, material, parts):
        root = r6._empty(f"Fx.{name}", None, Matrix.Identity(4), 0.2)
        root.location, root.rotation_mode = (at[0], at[1], 0.0), "XYZ"
        for part, size, z in parts:
            box = bl.box(f"Fx.{name}.{part}", size, material)
            box.parent, box.location = root, (0, 0, z)
        return root

    def box(self, shade):
        obj = bl.box(f"Fx.{shade}", (1, 1, 1), self.materials[shade])
        obj.display.show_shadows = False
        obj.hide_render = True
        return obj

    def place_avatar(self, scene):
        name = scene.camera.name if scene.camera else ""
        staged_here = name.removesuffix("50") in LOOKS or name[1:].isdigit()
        for box in self.avatar_boxes:
            box.hide_render = not staged_here
        if staged_here:
            look, spot = staged(name)
            self.avatar.location = (spot.x, spot.y, 0.0)
            self.avatar.rotation_euler = (0.0, 0.0, math.atan2(look.y, look.x) - math.pi / 2)

    def set(self, scene, *_):
        f = scene.frame_current
        self.place_avatar(scene)
        if scene.camera:
            eye = scene.camera.matrix_world.translation
            self.facing = (Vector((eye.x, eye.y)) - Vector(TARGET)).normalized()
        used = {shade: 0 for shade in SHADES}
        for shade, centre, size, yaw in (layout(self, self.variant, f) if self.show else []):
            if used[shade] == len(self.pool[shade]):
                self.pool[shade].append(self.box(shade))
            obj = self.pool[shade][used[shade]]
            used[shade] += 1
            obj.location, obj.scale, obj.rotation_euler, obj.hide_render = centre, size, (0.0, 0.0, yaw), False
        for shade, n in used.items():
            for obj in self.pool[shade][n:]:
                obj.hide_render = True
        # the charge: one square drawn tight onto the ram's face through the hold, cut at the strike (as the game)
        drawn = self.show and WIND - 6 <= f < STRIKE
        side = 2.9 - 1.1 * clamp((f - WIND + 6) / (HELD - WIND + 6)) ** 2 - 0.1 * clamp((f - HELD) / 4)
        for i, bar in enumerate(self.ring):
            across, sign = i < 2, 1 if i % 2 else -1
            bar.hide_render = not drawn
            bar.location = Vector(hx.KNUCKLES) + Vector((0, sign * side / 2, 0) if across else (sign * side / 2, 0, 0))
            bar.scale = (side + 0.2, 0.2, 0.2) if across else (0.2, side + 0.2, 0.2)
        # the target, pushed down the line as the game pushes it
        go = hx.out_fast((f - KNOCK) / PUSHED) if f >= KNOCK else 0.0
        self.target.location = (TARGET[0], TARGET[1] + PUSH * go, 0.0)


def key(rig):
    data = json.loads(CLIP.read_text())
    for frame in data["Frames"]:
        f = round(frame["T"] * data["Fps"])
        for part, pose in frame["Poses"].items():
            joint = rig.joints.get(part)
            if joint is not None:
                joint.matrix_basis = r6.to_blender(r6.cframe(pose))
                joint.keyframe_insert("location", frame=f)
                joint.keyframe_insert("rotation_quaternion", frame=f)
    marks = {m["Name"]: round(m["T"] * data["Fps"]) for m in data.get("Markers", [])}
    if marks != MARKS:
        raise SystemExit(f"the clip's markers are {marks}, not {MARKS}")
    return len(data["Frames"])


def label(f):
    return f"{f} {NAMES[f]}" if f in NAMES else f"{f}"


def share(scene, stage, camera, wanted, path):
    """The effect's share of the player's screen: pixels that change when it's drawn, at the game's field of view."""
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = 480, 270
    scene.render.use_stamp = False
    table = {}
    for key_ in wanted:
        stage.variant, table[key_] = key_, {}
        for f in SHARE:
            pixels = []
            for show in (True, False):
                stage.show = show
                scene.frame_set(f)
                scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                image = bpy.data.images.load(str(path))
                pixels.append(np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)[:, :3])
                bpy.data.images.remove(image)
            table[key_][f] = round(float((np.abs(pixels[0] - pixels[1]).max(axis=1) > 0.03).mean()), 4)
        stage.show = True
    path.unlink()
    return table


def small(scene, stage, camera, wanted, path, size=(75, 64), zoom=3):
    """The read at 64 px: tiles with no label over them (the square falls through the top, where a label sits), a
    variant a row in `wanted`'s order and a frame a column in STRIP's, each pixel drawn `zoom` times to be looked at."""
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.use_stamp = False
    w, h = size
    sheet = np.full((len(wanted) * (h + 2), len(STRIP) * (w + 2), 4), 1.0, dtype=np.float32)
    for r, key_ in enumerate(wanted):
        stage.variant = key_
        for c, f in enumerate(STRIP):
            scene.frame_set(f)
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)
            image = bpy.data.images.load(str(path))
            tile = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)
            bpy.data.images.remove(image)
            y0 = (len(wanted) - 1 - r) * (h + 2)
            sheet[y0:y0 + h, c * (w + 2):c * (w + 2) + w] = tile
    sheet = sheet.repeat(zoom, axis=0).repeat(zoom, axis=1)
    image = bpy.data.images.new(path.stem, sheet.shape[1], sheet.shape[0], alpha=True)
    image.pixels = sheet.ravel()
    image.filepath_raw, image.file_format = str(path), "PNG"
    image.save()
    return path


def game_camera(scene, name, fov=70.0):
    look, spot = staged(name)
    azimuth = math.degrees(math.atan2(-look.x, -look.y))
    return hx.camera(scene, name, azimuth, PITCH, EYE / math.cos(math.radians(PITCH)), (spot.x, spot.y, 4.5), fov)


def main():
    out = bl.out_dir()
    wanted = [a for a in sys.argv[sys.argv.index("--") + 2:] if a in VARIANTS] or list(VARIANTS)
    scene, rig, costume, undress, feet = rc.build()
    frames = key(rig)
    scene.frame_set(STRIKE)
    knuckles = tuple(rig.parts["Right Arm"].matrix_world @ Vector(hx.KNUCKLES))
    print(f"Haymaker: {frames} frames, the markers at {MARKS}; the knuckles at the strike "
          f"{tuple(round(v, 2) for v in knuckles)}")
    stage = Stage(scene, rig, knuckles)
    cameras = {name: game_camera(scene, name, 50.0 if name == "fight50" else 70.0)
               for name in ("fight", "fight50", "beside", "hidden")}
    for name, cam in cameras.items():
        eye = cam.location
        print(f"{name}: Rook seen {math.degrees(math.atan2(-eye.x, eye.y)):.0f} degrees off his front, from "
              f"{Vector((eye.x, eye.y)).length:.1f} studs; the target {(Vector((eye.x, eye.y)) - Vector(TARGET)).length:.1f}")
    side = hx.camera(scene, "side", 90.0, 6.0, 26.0, (0.0, 5.0, 4.0), 40.0)
    bpy.data.objects["Floor"].scale *= 4
    floor = bpy.data.objects["Floor"].data.materials[0]
    dusk = tuple(floor.diffuse_color)
    fight, fight50 = cameras["fight"], cameras["fight50"]
    for key_ in wanted:
        stage.variant = key_
        scene.render.resolution_x, scene.render.resolution_y = 480, 270
        title = f"{key_}, {VARIANTS[key_][0]}: "
        shots = [(fight, f, title + label(f) if f == SHEET[0] else label(f)) for f in SHEET]
        print(f"wrote {r6.render_shots(scene, shots, out / f'stamp_{key_}.png', columns=4)}")
    tile = (320, 180)
    for name, cam in (("side", side), ("beside", cameras["beside"]), ("hidden", cameras["hidden"])):
        shots = [(cam, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
        print(f"wrote {hx.render_variants(scene, stage, shots, out / f'stamp_{name}.png', len(STRIP), tile)}")
    shots = [(fight, f, f"{key_} {f}", key_) for key_ in wanted for f in STRIP]
    floor.diffuse_color = (0.74, 0.72, 0.68, 1)
    print(f"wrote {hx.render_variants(scene, stage, shots, out / 'stamp_bright.png', len(STRIP), tile)}")
    floor.diffuse_color = dusk
    print(f"wrote {small(scene, stage, fight50, wanted, out / 'stamp_64.png')}")
    # every heading round the target, the same staging turned: B3's and B5's drop and landing, one row a heading
    turned = {h: game_camera(scene, f"h{h}") for h in HEADINGS}
    scene.render.resolution_x, scene.render.resolution_y = 274, 154
    for key_ in [k for k in ("B3", "B5") if k in wanted]:
        stage.variant = key_
        shots = [(turned[h], f, f"{key_} {h} deg, {f}" if f == STRIP[1] else f"{f}") for h in HEADINGS for f in STRIP[1:8]]
        print(f"wrote {r6.render_shots(scene, shots, out / f'stamp_headings_{key_}.png', columns=7)}")
    table = {"markers": MARKS, "target": TARGET, "stamp": {"side": SIDE, "bar": BAR, "top": TOP, "drop": DROP},
             "share": share(scene, stage, fight, wanted, out / "share.png")}
    (out / "stamp.json").write_text(json.dumps(table, indent=1))
    print(json.dumps(table["share"]))


if __name__ == "__main__":
    main()
