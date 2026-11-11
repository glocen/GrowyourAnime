"""The fast preview: a clip in
motion as the game plays it, from the game's camera at 60 frames a second, beside the reference moment at the same rate
and from the same view, with the audit's geometry on every frame. One command, a few minutes: every clip's first step
from its blocking on, and again after each pass, before any full render (the pipeline skill, "Animations").

Run: blender.exe -b --factory-startup --python tools/blender/preview.py -- <Anim_X.txt> <out dir>
         [over idle|walk|none] [at <seconds>] [fade <in> <out>] [view game|eased|<azimuth>] [close [lens <degrees>]]
         [yaw <degrees>] [pitch <degrees>] [weapons <folder>] [size <pixels>] [then <Anim_Y.txt>]...
         [launch <up> <back>] [travel <Travel_X.json>] [ghost <seconds> <life>] [cut <seconds>]
         [eye <x> <y> <z> <at x> <at y> <at z>]
         [reference <video> <seconds> [mirror] [crop <x0> <y0> <x1> <y1>]]
- over: the loop under the clip, stacked as the game stacks them (r6anim.blend_layers: the clip's weights, the legs the
  loop's where the clip leaves them; the walk and the sprint moving at their own speed). `none` plays the clip alone. The
  idle by default.
- then: a clip the game plays as this one ends (a burst's lowering, a chained burst), from its end with its own fades
  and weights, over the one before; repeat it for more. Over `none`, the clips play over the first one's first pose.
- launch: a hit's Launch (studs up) and Knockback (studs back): the root rides the knock's arc from the clip's start, as
  the game carries a struck body (r6anim.knock_arc), and stays where it lands; a Launch of 0 is a straight push (a
  heavy hit's stagger).
- travel: the root's way through the clip, a file its script writes ({"Way": [[seconds, studs ahead], ...]}: the game
  carries the root, the clip never does), in place of the loop's speed while the clip plays; the floor gets its marks,
  so the travel reads from a camera that follows the root.
- ghost: the stand-in for a shadow left behind: the body as it stands `seconds` into the clip, frozen where it was, black,
  fading over `life` seconds from there as the spec's fade goes (held two-thirds of it, then gone fast). In Workbench,
  for a blockout's timing and read: the look itself is designed apart.
- cut: the game stops the clip at `seconds` (an input cutting its recovery), fading out from there.
- eye: a still camera at a point, looking at another (Roblox studs from where the root starts, facing -Z), in place of
  the view: the player's camera behind a thrower, for a body thrown away from it; `lens` narrows it (the game's BaseFov
  by default).
- at: when the clip starts on the loop (0.2 s, so its fade-in shows); fade: its Play and Stop fades (the export's
  FadeIn and FadeOut, else 0.1).
- view: `game`, the game's camera (Config.Camera, r6anim.player_camera; the default); `eased`, the same eased round by Config.Camera's Eased table; a number, a camera round the body at that azimuth (0 its front, 90 its right side,
  r6anim.body_camera). close: the same eye with a narrow lens on the body (r6anim.player_view); lens sets its field of
  view (40; the game's own, Config.Camera's BaseFov, keeps a raised weapon in the frame). yaw and pitch replace the
  camera's own.
- weapons: a folder holding held_right.blend and held_left.blend, for the weapons' models (else blocks). size: the view's height in
  pixels (360).
- reference: the video's moment `seconds` plays beside the clip's start, frame for frame at 60 a second. `seconds` is
  on Blender's timeline: it steps the file by frame count, up to about half a second from a survey's timestamps, so
  write a time from it as Blender's. mirror flips
  it (a left-handed thrower against ours); crop keeps that part of its frame (0 to 1, from its top left). The footage is
  internal study only: the preview stays in a gitignored folder, never committed, uploaded or published. Its frames are
  cached in build/reference/preview/ (gitignored).
Each frame is stamped with the clip's time; a frame that fails an audit check carries the check's name, in amber. Prints
the audit over the clip and over the stack (r6parity.report), and writes <out dir>/<clip>_preview.mp4 and its frames.
"""

import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import bpy
import numpy as np
from mathutils import Vector

import blcommon as bl
import frames_to_movie
import r6anim as r6
import r6parity

FPS = 60  # the game's: a preview shows every frame the player sees
CAMERA = "src/shared/Config/Camera.luau"
GREY = {part: (0.30, 0.30, 0.33) for part in r6.PARTS} | {"Face": (0.08, 0.08, 0.09)}  # a body without a palette
PALETTES = {}  # a character's name: its part colours
# Seam: your loops. name: (builder, animate), where builder(0) returns what animate(rig, *built) takes and built[0] has
# .fps, .speed, .start and .count. Empty, the clip plays alone, as `over none`.
LOOPS = {}
LEGS = ("Right Leg", "Left Leg")
FLAGGED = (1.0, 0.75, 0.1, 1.0)  # a frame's stamp when an audit check fails on it


def option(args, name, count=1, default=None):
    """The `count` values after `name` in the arguments (one: the value itself), or `default`."""
    if name not in args:
        return default
    i = args.index(name)
    return args[i + 1] if count == 1 else args[i + 1:i + 1 + count]


def key_clip(rig: r6.Rig, clip: dict, start: int) -> int:
    """Keys an export's poses onto the rig from frame `start` at 60 a second (a clip baked at 30 keys every other
    frame, the rest between them as Roblox's linear poses), the root still. Returns its last frame."""
    r6.place_root(rig, start, (0, r6.ROOT_HEIGHT, 0), (0, 0, -1))
    last = start
    for frame in clip["Frames"]:
        last = start + round(frame["T"] * FPS)
        r6.key_matrices(rig, last, {part: r6.to_blender(r6.cframe(pose)) for part, pose in frame["Poses"].items()
                                    if part in rig.joints})
    r6.place_root(rig, last, (0, r6.ROOT_HEIGHT, 0), (0, 0, -1))
    return last


def floor_marks(length=80, step=2.0):
    """Lines across the floor every `step` studs and one along it, so a body travelling under a following camera reads
    as moving (the stage's floor is flat)."""
    material = r6.flat_material("FloorMark", (0.08, 0.07, 0.09))
    for n in range(int(length / step) + 1):
        mark = bl.box(f"Mark{n}", (24.0, 0.12, 0.02), material)
        mark.location = (0.0, n * step - 20.0, 0.005)
    rail = bl.box("MarkRail", (0.12, length, 0.02), material)
    rail.location = (5.0, length / 2 - 20.0, 0.005)


def ghost_body(rig: r6.Rig, frame: int, lives: dict) -> list:
    """Frozen copies of the body's boxes and weapons as they stand at `frame`, in one black material whose alpha is keyed
    frame by frame from `lives` (frame -> alpha)."""
    material = bpy.data.materials.new("Ghost")
    material.diffuse_color = (0.015, 0.012, 0.022, 1.0)
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    copies = []
    for part in rig.parts.values():
        for obj in [part, *part.children_recursive]:
            if obj.type != "MESH" or obj.hide_render or obj.name.startswith("Ghost."):
                continue
            copy = bpy.data.objects.new(f"Ghost.{obj.name}", obj.data.copy())
            copy.matrix_world = obj.matrix_world.copy()
            copy.data.materials.clear()
            copy.data.materials.append(material)
            bpy.context.scene.collection.objects.link(copy)
            copies.append(copy)
    for f, alpha in lives.items():
        material.diffuse_color[3] = alpha
        material.keyframe_insert("diffuse_color", index=3, frame=f)
        for copy in copies:
            copy.hide_render = alpha <= 0.0
            copy.keyframe_insert("hide_render", frame=f)
    return copies


def drop(*cameras):
    for camera in cameras:
        data = camera.data
        bpy.data.objects.remove(camera, do_unlink=True)
        bpy.data.cameras.remove(data)


def view_at(scene, rig: r6.Rig, frame: int, view: str, close: bool, yaw, pitch, lens=40.0):
    """The camera for one frame: the game's, eased as named, or round the body (the module's notes). Returns it and
    the cameras made on the way, to drop after the render."""
    if view not in ("game", "eased"):
        camera = r6.body_camera(scene, rig, frame, float(view), name=f"PreviewBody{frame}")
        return camera, [camera]
    eased = {}
    if view == "eased":
        numbers = r6.luau_table(CAMERA, "Eased = {")
        eased = {"yaw": numbers["Yaw"], "fov": numbers["Fov"], "distance": numbers["Distance"]}
    if yaw is not None:
        eased["yaw"] = yaw
    if pitch is not None:
        eased["pitch"] = pitch
    camera = r6.player_camera(scene, rig, frame, name=f"PreviewEye{frame}", **eased)
    if not close:
        return camera, [camera]
    eye = r6.point_to_roblox(camera.location)
    root = r6.to_roblox(rig.root.matrix_world).to_translation()
    near = r6.fixed_camera(scene, eye, root + Vector((0, -0.6, 0)), lens, f"PreviewClose{frame}")
    return near, [camera, near]


def render_frame(scene, camera, frame: int, label: str, flagged: bool, path: Path):
    scene.camera = camera
    scene.frame_set(frame)
    scene.render.stamp_note_text = label
    scene.render.stamp_foreground = FLAGGED if flagged else (1.0, 1.0, 1.0, 1.0)
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def reference_frames(video: Path, seconds: float, times, mirror: bool, crop, folder: Path) -> dict:
    """The video's frames at `seconds` + t for each clip time t, cropped (and flipped), through a scene of its own's
    sequencer, cached as PNGs in `folder`: {t: path}. Internal study only (the module's notes)."""
    folder.mkdir(parents=True, exist_ok=True)
    movie = bpy.data.movieclips.load(str(video))
    fps = movie.fps or 30.0
    width, height = movie.size
    frames = movie.frame_duration
    bpy.data.movieclips.remove(movie)
    scene = bpy.data.scenes.new("Reference")
    strip = scene.sequence_editor_create().strips.new_movie("reference", str(video), 1, 1)
    strip.use_flip_x = mirror
    x0, y0, x1, y1 = crop
    if mirror:
        x0, x1 = 1 - x1, 1 - x0
    render = scene.render
    render.fps, render.fps_base = round(fps), round(fps) / fps
    render.use_sequencer = True
    render.resolution_x, render.resolution_y, render.resolution_percentage = width, height, 100
    render.use_border = render.use_crop_to_border = True
    render.border_min_x, render.border_max_x = x0, x1
    render.border_min_y, render.border_max_y = 1 - y1, 1 - y0  # the border counts from the bottom
    render.image_settings.file_format = "PNG"
    scene.frame_end = frames + 1
    here = bpy.context.scene  # a still render takes the frame of the scene in the context, whichever scene it renders
    paths = {}
    for t in times:
        path = folder / f"{seconds + t:09.3f}.png"
        if not path.exists():
            frame = 1 + round((seconds + t) * fps)
            scene.frame_set(frame)
            here.frame_set(frame)
            render.filepath = str(path)
            bpy.ops.render.render(write_still=True, scene=scene.name)
        paths[t] = path
    bpy.data.scenes.remove(scene)
    return paths


def pixels(path: Path) -> np.ndarray:
    image = bpy.data.images.load(str(path))
    w, h = image.size
    array = np.empty(w * h * 4, dtype=np.float32)
    image.pixels.foreach_get(array)
    bpy.data.images.remove(image)
    return array.reshape(h, w, 4)


def side_by_side(left: np.ndarray, right: np.ndarray, path: Path):
    """`left` scaled to `right`'s height (nearest pixel) beside it, saved as a PNG."""
    h = right.shape[0]
    rows = (np.arange(h) * left.shape[0] / h).astype(int)
    width = round(left.shape[1] * h / left.shape[0])
    cols = (np.arange(width) * left.shape[1] / width).astype(int)
    sheet = np.concatenate([left[rows][:, cols], right], axis=1)
    image = bpy.data.images.new(path.stem, sheet.shape[1], sheet.shape[0], alpha=True)
    image.pixels.foreach_set(sheet.ravel())
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


def main():
    began = time.perf_counter()
    args = sys.argv[sys.argv.index("--") + 1:]
    export, out = Path(args[0]).resolve(), Path(args[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    clip = json.loads(export.read_text())
    name, character = clip["Name"], clip.get("Character", "Hero")
    over = option(args, "over", default="idle")
    at = float(option(args, "at", default="0.2"))
    fades = [float(v) for v in option(args, "fade", 2, [clip.get("FadeIn", 0.1), clip.get("FadeOut", 0.1)])]
    view, close = option(args, "view", default="game"), "close" in args
    lens = float(option(args, "lens", default="40"))
    yaw, pitch = (float(v) if v is not None else None for v in (option(args, "yaw"), option(args, "pitch")))
    size = int(option(args, "size", default="360"))
    weapons = Path(option(args, "weapons")) if "weapons" in args else None
    reference = option(args, "reference", 2)
    crop = [float(v) for v in option(args, "crop", 4, [0.0, 0.0, 1.0, 1.0])]
    follow = [Path(args[i + 1]).resolve() for i, arg in enumerate(args) if arg == "then"]
    launch = [float(v) for v in option(args, "launch", 2)] if "launch" in args else None
    eye = [float(v) for v in option(args, "eye", 6)] if "eye" in args else None
    travel = json.loads(Path(option(args, "travel")).resolve().read_text())["Way"] if "travel" in args else None
    ghost = [float(v) for v in option(args, "ghost", 2)] if "ghost" in args else None
    cut = float(option(args, "cut")) if "cut" in args else None

    scene = bl.reset_scene()
    r6.stage(scene, FPS)
    bpy.data.objects["Floor"].scale = (10.0, 10.0, 1.0)  # 600 studs a side: a walk crosses the stage's 60 in 3 s
    armed = character in r6parity.LOADOUTS
    meshes = armed and weapons is not None and all((weapons / blend).exists() for blend, _ in r6.WEAPON_MESHES.values())
    rig = r6.build_rig(character, PALETTES.get(character, GREY), weapons=armed and not meshes, wrists=True)
    if meshes:
        r6.weapon_meshes(rig, weapons)

    # the loop it plays over, then the clips, then all of them stacked as the game stacks them: the clip from `at`, and
    # each clip after `then` from the end of the one before it (as GunBurstLower follows a burst), the later higher
    loop, speed, keyed = None, 0.0, 0
    if over in LOOPS:
        builder, animate = LOOPS[over]
        built = builder(0)
        loop, speed = built[0], (0.0 if over == "idle" else built[0].speed)
        scene.render.fps = loop.fps
        animate(rig, *built)
        scene.render.fps = FPS
        keyed = loop.start + loop.count
    clips = [clip] + [json.loads(path.read_text()) for path in follow]
    layers, markers, when = [], [], at
    for n, each in enumerate(clips):
        first = keyed + 30
        keyed = key_clip(rig, each, first)
        length = cut if cut and n == 0 else each["Frames"][-1]["T"]
        legs = each.get("Legs", 1.0)
        layers.append({"clip": first, "duration": length, "at": when,
                       "fade_in": fades[0] if n == 0 else each.get("FadeIn", 0.1),
                       "fade_out": fades[1] if n == 0 else each.get("FadeOut", 0.1),
                       "weights": each.get("Weights") or {part: legs if part in LEGS else 1.0 for part in r6.PARTS}})
        markers += [{"T": round(when + m["T"], 4), "Name": m["Name"]} for m in each.get("Markers", [])]
        when += length
    blended = loop is not None or bool(follow)
    if not blended:  # the clip alone, as baked
        s0, s1, lead = layers[0]["clip"], keyed, 0.0
    else:  # with no loop, the clips play over the first one's first pose, held
        held = layers[0]["clip"]
        base = (lambda s: loop.start + (s * loop.fps) % loop.count) if loop is not None else (lambda s: held)
        s0 = keyed + 30
        s1 = r6.blend_layers(rig, s0, base, layers, when + layers[-1]["fade_out"] + 0.3, FPS, speed=speed)
        lead = at

    # the audit on every frame: each clip as baked, and what the game shows (its markers, so a kick on one reads as
    # the clip's own beat)
    # with a launch, the floor drops by the knock's arc under each dump's own times (r6parity.audit's lift)
    def lift_at(offset):
        if not launch:
            return None
        return lambda t: max(0.0, r6.knock_arc(t + offset - lead, *launch)[1]) if t + offset >= lead else 0.0

    flags = {}
    for path, each, layer in zip([export] + follow, clips, layers):
        offset = layer["at"] if blended else 0.0
        r6parity.report(f"[audit] {path.name}", each, lift=lift_at(offset))
        for t, checks in _audited(each, lift_at(offset)).items():
            flags.setdefault(round(offset + t, 4), set()).update(checks)
    if blended:
        title = " then ".join(each["Name"] for each in clips) + (f" over the {over}" if loop is not None else "")
        dump = r6.parity_dump(rig, out / f"Parity_Preview_{name}.json", title, s0, s1, side="blender-blend",
                              extra={"Markers": markers})
        stacked = json.loads(dump.read_text())
        r6parity.report(f"[audit] {title}", stacked, lift=lift_at(0.0))
        for t, checks in _audited(stacked, lift_at(0.0)).items():
            flags.setdefault(round(t, 4), set()).update(checks)
    if launch:  # the root on the knock's arc from the clip's start, still where it lands (the audit is the root's own)
        for f in range(s0, s1 + 1):
            x, y, z = r6.knock_arc((f - s0) / FPS - lead, *launch)
            r6.place_root(rig, f, (x, r6.ROOT_HEIGHT + y, z), (0, 0, -1))

    if travel:  # the root on its way through the clip, at the loop's speed before and after it
        floor_marks()
        moments, studs = zip(*travel)
        final = layers[0]["duration"]
        for f in range(s0, s1 + 1):
            t = (f - s0) / FPS - lead
            ahead = speed * (min(t, 0.0) + lead) + float(np.interp(max(t, 0.0), moments, studs)) + speed * max(t - final, 0.0)
            r6.place_root(rig, f, (0, r6.ROOT_HEIGHT, -ahead), (0, 0, -1))
    if ghost:
        moment, life = ghost
        alpha = {}
        for f in range(s0, s1 + 1):
            u = ((f - s0) / FPS - lead - moment) / life
            alpha[f] = 0.0 if u < 0 or u >= 1 else (1.0 if u < 2 / 3 else 1.0 - ((u - 2 / 3) * 3) ** 2)
        ghost_body(rig, s0 + round((lead + moment) * FPS), alpha)

    # our frames, then the reference's beside them
    frames = out / f"{name}_preview"
    frames.mkdir(exist_ok=True)
    for old in frames.glob("*.png"):
        old.unlink()
    aspect = 6 / 7
    if reference:  # our view framed as the reference's crop is, so the two sit at one height and one shape
        movie = bpy.data.movieclips.load(str(Path(reference[0]).resolve()))
        aspect = (crop[2] - crop[0]) * movie.size[0] / ((crop[3] - crop[1]) * movie.size[1])
        bpy.data.movieclips.remove(movie)
    scene.render.resolution_x, scene.render.resolution_y = round(size * aspect), size
    scene.render.use_stamp = scene.render.use_stamp_note = True
    for stamp in ("date", "render_time", "camera", "lens", "scene", "filename", "frame", "time"):
        setattr(scene.render, f"use_stamp_{stamp}", False)
    scene.render.stamp_font_size = max(12, size // 24)
    times = [(f - s0) / FPS - lead for f in range(s0, s1 + 1)]
    still_lens = lens if "lens" in args else r6.game_camera()["BaseFov"]
    still = r6.fixed_camera(scene, eye[:3], eye[3:], still_lens, "PreviewStill") if eye else None
    for n, (f, t) in enumerate(zip(range(s0, s1 + 1), times)):
        failed = sorted(flags.get(round(t + lead, 4), ()))
        label = f"{name} {t:+.3f} s" + (f" | ref {float(reference[1]) + t:.3f}" if reference else "")
        label += "  " + ", ".join(failed) if failed else ""
        camera, made = (still, []) if still else view_at(scene, rig, f, view, close, yaw, pitch, lens)
        render_frame(scene, camera, f, label, bool(failed), frames / f"{n:04d}.png")
        drop(*made)
    if reference:
        video, seconds = Path(reference[0]), float(reference[1])
        cache = r6.REPO / "build" / "reference" / "preview" / (
            f"{video.stem}{'_mirror' if 'mirror' in args else ''}_{'_'.join(f'{v:g}' for v in crop)}")
        paths = reference_frames(video, seconds, times, "mirror" in args, crop, cache)
        for n, t in enumerate(times):
            ours = frames / f"{n:04d}.png"
            side_by_side(pixels(paths[t]), pixels(ours), ours)
    movie = frames_to_movie.assemble(frames, out / f"{name}_preview.mp4", FPS)
    bad = sum(1 for t in times if flags.get(round(t + lead, 4)))
    print(f"[preview] {movie}: {len(times)} frames at {FPS} fps from {'a still eye' if eye else f'the {view} camera'}"
          f"{', beside the reference' if reference else ''}; {bad} frames fail a check; "
          f"{time.perf_counter() - began:.0f} s")


def _audited(data, lift=None) -> dict:
    """Every failing check by the sample time it fails at (r6parity.audit, the floor dropped by `lift`)."""
    flags = {}
    r6parity.audit(data, frames=flags, lift=lift)
    return flags


if __name__ == "__main__":
    main()
