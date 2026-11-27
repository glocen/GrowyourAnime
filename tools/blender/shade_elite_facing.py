"""AR57's polish: does an elite's second mask show its face to the player's camera? For each frame of each clip the
elite plays, the angle between the mask's face (its -Z, as the game seats it) and the way to the camera, and the share
of the clip it spends turned past the read.

  blender -b --factory-startup --python tools/blender/shade_elite_facing.py -- <abs out> measure [seats.json] [clips_dir]
  blender -b --factory-startup --python tools/blender/shade_elite_facing.py -- <abs out> shots <shots.json> [seats.json] [clips_dir]

- `measure` writes <out>/facing.json and prints a table: per kind and clip, the angle at rest (frame 0), its least and
  most, and the frames past READ (the face foreshortened under half: edge-on) and past SEEN (a sliver).
- `shots` renders the elite with its second mask from the player's camera at the frames a list names
  ([{"kind", "clip", "frame", "name"}]), lit as shade_elite_contact.py lights its sheet, into <out>/<name>.png.
- seats.json, optional: {kind: [x, y, z, rx, ry, rz]}, a seat on the arm in shade_elite.py's terms (WAYS: where the
  mask's middle goes, and its turn in degrees about X, Y, Z), in place of the recipe's for that kind.
- clips_dir, optional: a folder searched first for Shade_<clip>.json (a re-keyed clip before it's delivered).

The camera is shade_elite_contact.VIEW: the player's camera on a Shade that faces the lead (24 degrees to its left, 18
up), the distance and height scaled with the elite.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import r6anim as r6  # noqa: E402
import shade_elite as se  # noqa: E402
import shade_elite_bare as seb  # noqa: E402
import shade_elite_contact as sec  # noqa: E402

READ = 60.0    # degrees: past this the face is foreshortened under half (cos 60 = 0.5), a strip more than a face
SEEN = 75.0    # degrees: past this it's a sliver
KINDS = {"Guard": ("GuardElite", "Idle", "Walk", "Attack", "Hit", "HitLeft", "Burst"),
         "Dasher": ("LungeElite", "Fan", "Idle", "Walk", "Attack", "Hit", "HitLeft", "Burst")}   # Fan: its move (TR69 B)


def seat(kind, record, seats):
    """The recipe's seat for `kind`, or the one seats.json gives, in the recipe's terms."""
    if kind not in seats:
        return json.loads(se.RECIPE.read_text())["elite"]["masks"][kind]
    x, y, z, rx, ry, rz = seats[kind]
    se.WAYS["Try"] = ("tried", (x, y, z), (rx, ry, rz))
    pick, se.PICK = se.PICK, "Try"
    try:
        return se.placement(kind, record["c"])
    finally:
        se.PICK = pick


def staged(kind, seats, clips_dir):
    import shade_clips as sc
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene, rig, _, _, _ = sc.build("Strength")
    record = json.loads((seb.HANDOFF / f"Shade_Mask{kind}Bare.json").read_text())
    mask = seb.mesh_object(f"Second{kind}", record, bpy.data.materials.new("Paper"))
    seb.wear(rig, mask, seat(kind, record, seats))
    folders = ([Path(clips_dir)] if clips_dir else []) + [sec.HANDOFF / "clips"]
    spans = sec.key_clips(rig, KINDS[kind], folders)
    rig.root.matrix_basis = rig.root.matrix_basis @ __import__("mathutils").Matrix.Scale(se.SCALE, 4)
    return scene, rig, mask, spans


def eye(rig):
    """The player's camera, in Blender's frame, as r6.body_camera puts it for VIEW at the elite's size."""
    azimuth, elevation, distance = sec.VIEW
    root = r6.to_roblox(rig.root.matrix_world)
    position = Vector((root[0][3], root[1][3], root[2][3]))
    look = Vector((-root[0][2], -root[1][2], -root[2][2])).normalized()
    side = look.cross(Vector((0, 1, 0))).normalized()
    a, e = math.radians(azimuth), math.radians(elevation)
    focus = position + Vector((0, (2.6 - r6.ROOT_HEIGHT) * se.SCALE, 0))
    out = focus + (look * math.cos(a) + side * math.sin(a)) * distance * se.SCALE * math.cos(e) \
        + Vector((0, distance * se.SCALE * math.sin(e), 0))
    return r6.point_to_blender(out)


def angle(mask, camera):
    """Degrees between the mask's face (the part's -Z) and the way from its middle to the camera."""
    m = mask.matrix_world
    face = (m.to_3x3() @ r6.point_to_blender((0, 0, -1))).normalized()
    middle = m @ Vector((0, 0, 0))
    to_camera = (camera - middle).normalized()
    return math.degrees(math.acos(max(-1.0, min(1.0, face.dot(to_camera)))))


def measure(out, seats, clips_dir):
    table = {}
    for kind in KINDS:
        scene, rig, mask, spans = staged(kind, seats, clips_dir)
        table[kind] = {}
        for clip, (start, last) in spans.items():
            angles = []
            for f in range(last + 1):
                scene.frame_set(start + f)
                angles.append(round(angle(mask, eye(rig)), 1))
            past_read = [f for f, a in enumerate(angles) if a > READ]
            past_seen = [f for f, a in enumerate(angles) if a > SEEN]
            table[kind][clip] = dict(rest=angles[0], least=min(angles), most=max(angles), frames=last + 1,
                                     past_read=len(past_read), past_seen=len(past_seen),
                                     runs=runs(past_read), angles=angles)
    (out / "facing.json").write_text(json.dumps(table, indent=1))
    print(f"{'kind':7} {'clip':11} {'rest':>5} {'least':>5} {'most':>5}  past {READ:.0f} (frames)   past {SEEN:.0f}   runs past {READ:.0f}")
    for kind, clips in table.items():
        for clip, t in clips.items():
            print(f"{kind:7} {clip:11} {t['rest']:5.0f} {t['least']:5.0f} {t['most']:5.0f}  {t['past_read']:3d}/{t['frames']:<3d}"
                  f"         {t['past_seen']:3d}      {t['runs']}")


def runs(frames):
    """Consecutive frames as [first, last] pairs."""
    out = []
    for f in frames:
        if out and f == out[-1][1] + 1:
            out[-1][1] = f
        else:
            out.append([f, f])
    return out


def shots(out, spec, seats, clips_dir):
    by_kind = {}
    for s in spec:
        by_kind.setdefault(s["kind"], []).append(s)
    for kind, wanted in by_kind.items():
        scene, rig, mask, spans = staged(kind, seats, clips_dir)
        sec_light(scene)
        for s in wanted:
            start, _ = spans[s["clip"]]
            scene.frame_set(start + s["frame"])
            camera_at = eye(rig)
            focus = r6.point_to_blender(r6.to_roblox(rig.root.matrix_world).translation
                                        + Vector((0, (2.6 - r6.ROOT_HEIGHT) * se.SCALE, 0)))
            cam = bpy.data.objects.new(s["name"], bpy.data.cameras.new(s["name"]))
            scene.collection.objects.link(cam)
            cam.location = camera_at
            cam.rotation_euler = (focus - camera_at).to_track_quat("-Z", "Y").to_euler()
            cam.data.angle = math.radians(sec.FOV)
            scene.camera = cam
            scene.render.resolution_x = scene.render.resolution_y = s.get("size", 640)
            scene.render.film_transparent = True
            scene.render.filepath = str(out / f"{s['name']}.png")
            bpy.ops.render.render(write_still=True)
            print(f"wrote {out / (s['name'] + '.png')}  angle {angle(mask, camera_at):.0f}")


def sec_light(scene):
    """A plain sun over the camera's left shoulder and a grey world, enough to read the mask's paper."""
    scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in {e.identifier for e in
                                                                            bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items} else "BLENDER_EEVEE"
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(sec.SUN))
    scene.collection.objects.link(sun)
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.35, 0.38, 1)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    OUT = Path(argv[0])
    OUT.mkdir(parents=True, exist_ok=True)
    mode, rest = argv[1], argv[2:]
    if mode == "measure":
        seats = json.loads(Path(rest[0]).read_text()) if rest[:1] and rest[0] != "-" else {}
        measure(OUT, seats, rest[1] if len(rest) > 1 else None)
    elif mode == "shots":
        spec = json.loads(Path(rest[0]).read_text())
        seats = json.loads(Path(rest[1]).read_text()) if len(rest) > 1 and rest[1] != "-" else {}
        shots(OUT, spec, seats, rest[2] if len(rest) > 2 else None)
    else:
        raise SystemExit(__doc__)
