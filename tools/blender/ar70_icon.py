"""AR70, the game page's icon: Rook mid-strike on his own Haymaker, drawn as a layer for tools/ui/ar70_icon_targets.py.

    blender.exe -b --factory-startup --python tools/blender/ar70_icon.py -- <out_dir> probe
    blender.exe -b --factory-startup --python tools/blender/ar70_icon.py -- <out_dir> shots <spec.json>

Rook is the make's (rook_make.py: take A on r6anim's rig, as its `clips` mode builds him), posed by the delivered
Haymaker clip (build/handoff/Rook/clips/Rook_Haymaker.json): nothing is posed by hand, so the icon shows his real move.
He is lit by the game's day light, the make's own (rook_model.sun_for, anime_make.fill_for), with one ember rim from
behind, the heat of the strike, and his right fist's wraps lit through their glow map (Rook_Emissive's shape), as
Haymaker heats them in the game. The camera is rig-relative (r6anim.body_camera): `azimuth` degrees from his front
(90 his right side), `elevation` up, `distance` studs from a point `height` studs over the floor, `fov` vertical.

`probe` lays a contact sheet of the strike's frames from round his front, to choose the icon's camera:
<out_dir>/probe_Haymaker.png. `shots` renders each shot the spec lists
({"heat": 2.0, "shots": [{name, frame, azimuth, elevation, distance, fov, size, height}]}) as one square RGBA picture,
the figure alone on a clear film, <out_dir>/<name>.png, with <name>.json: where his fist, elbow, head and torso fall.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
import blcommon as bl  # noqa: E402
import hard_ember as he  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_make_takes as rmt  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402

NAME, CLIP = "Rook", "Haymaker"
EMBER, EMBER_HOT = (0.91, 0.38, 0.16), (1.0, 0.69, 0.44)   # the HUD's ember (#E8622A) and its hot core (#FFB070)


def linear(c):
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def staged(out):
    """Rook as the make builds him, on the rig, with Haymaker keyed from frame 0; the rig and the clip's last frame."""
    scene = bl.reset_scene()
    r6.stage(scene, fps=60, size=(960, 540))
    rig = r6.build_rig(NAME, {part: (0.3, 0.3, 0.3) for part in (*r6rig.PARTS, "Face")})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    am.PICTURES.clear()
    am.GLOWS.clear()
    (out / "tex").mkdir(parents=True, exist_ok=True)
    made = rmt.take_a(wt.rig(scene), out / "tex")
    bpy.context.view_layer.update()
    for key, obj in made.items():
        holder = rig.parts[am.PIECE[key][1]]
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
    for o in [rig.parts[part] for part in r6rig.PARTS] + [bpy.data.objects[f"{NAME}.Face"]]:
        o.hide_render = o.hide_viewport = True
    if "Floor" in bpy.data.objects:
        bpy.data.objects["Floor"].hide_render = True
    last = he.key(rig, rmt.REPO / "build" / "handoff" / NAME / "clips" / f"{NAME}_{CLIP}.json", 0)
    return scene, rig, last


def heat(out, amount):
    """The wraps lit as Haymaker heats them: each piece's glow map drives its material's emission, in the ember."""
    for name, glow in am.GLOWS.items():
        obj = bpy.data.objects.get(name)
        if obj is None or not obj.material_slots:
            continue
        path = out / "tex" / f"{name}_glow.png"
        rs.save(np.dstack([np.repeat(np.clip(glow, 0, 1)[..., None], 3, axis=2), np.ones(glow.shape, np.float32)]), path)
        m = obj.material_slots[0].material
        bsdf, nodes, links = bl._principled(m)
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(path))
        tex.image.colorspace_settings.name = "Non-Color"
        gain = nodes.new("ShaderNodeMath")
        gain.operation = "MULTIPLY"
        gain.inputs[1].default_value = amount
        links.new(tex.outputs["Color"], gain.inputs[0])
        colour = bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")
        colour.default_value = (*linear(EMBER), 1.0)
        links.new(gain.outputs["Value"], bsdf.inputs["Emission Strength"])
        print(f"heated {name}: glow {float(glow.max()):.2f} at most, over {int((glow > 0.05).sum())} texels")


def lights(scene, azimuth, rim_turn=55.0):
    """The make's day light turned to the camera, and an ember rim from behind his striking side."""
    wt_azimuth = 180.0 - azimuth     # the make's sun counts 180 at his face; the rig's camera counts 0 there
    rm.sun_for(scene, wt_azimuth)
    am.fill_for(scene, wt_azimuth)
    rim = bpy.data.objects.get("Rim")
    if rim is None:
        rim = bpy.data.objects.new("Rim", bpy.data.lights.new("Rim", "SUN"))
        rim.data.energy, rim.data.angle = 4.5, math.radians(3)
        rim.data.color = linear(EMBER)
        scene.collection.objects.link(rim)
    # from behind the figure, off his right shoulder, a little above: the light the camera looks into
    a, e = math.radians(wt_azimuth + 180 - rim_turn), math.radians(20)
    from mathutils import Vector
    offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e)))
    rim.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()


def probe(out):
    scene, rig, last = staged(out)
    heat(out, 2.5)
    rm.eevee(scene, 260, 260)
    frames = [f for f in (45, 49, 51, 53, 55, 57, 58, 60) if f <= last]
    shots = []
    for azimuth in (-35, 0, 30, 60):
        lights(scene, azimuth)
        cam = r6.body_camera(scene, rig, frames[0], azimuth, 6.0, distance=10.0, fov=40.0, height=3.2, name=f"Az{azimuth}")
        shots += [(cam, f, f"az {azimuth} f {f}") for f in frames]
    # each tile is drawn with the last azimuth's light: good enough to choose a camera by
    print(f"wrote {r6.render_shots(scene, shots, out / f'probe_{CLIP}.png', columns=len(frames))}")


def shots(out, spec):
    """Each shot in `spec`: {name, frame, azimuth, elevation, distance, fov, size, height}, on one build of him."""
    scene, rig, last = staged(out)
    heat(out, spec.get("heat", 2.0))
    for s in spec["shots"]:
        shot(out, scene, rig, last, **s)


def shot(out, scene, rig, last, name, frame, azimuth, elevation, distance, fov, size, height=3.2, sky=0.55, sun=3.2,
         fill=1.1, rim=4.5, rim_turn=55.0):
    """`sky`, `sun`, `fill` and `rim` scale the world's light and the three lamps (the make's own are 0.55, 3.2, 1.1);
    `rim_turn` swings the ember rim round from straight behind him toward his right."""
    rm.eevee(scene, size, size)
    lights(scene, azimuth, rim_turn)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = sky
    bpy.data.objects["Sun"].data.energy = sun
    bpy.data.objects["Fill"].data.energy = fill
    bpy.data.objects["Rim"].data.energy = rim
    scene.camera = r6.body_camera(scene, rig, frame, azimuth, elevation, distance=distance, fov=fov, height=height, name=name)
    scene.frame_set(frame)
    scene.render.filepath = str(out / f"{name}.png")
    bpy.ops.render.render(write_still=True)
    (out / f"{name}.json").write_text(json.dumps(landmarks(scene, rig, size), indent=1))
    print(f"wrote {out / f'{name}.png'} at frame {frame} of {last}")


def landmarks(scene, rig, size):
    """Where his right fist's end, his head and his torso fall in the picture, in pixels from the top left, and how
    near each is (studs from the camera): for the composite to centre the strike's light on the fist."""
    from bpy_extras.object_utils import world_to_camera_view
    from mathutils import Vector
    bpy.context.view_layer.update()

    def picture(part, along=0.0):
        m = r6.to_roblox(rig.parts[part].matrix_world)
        up = Vector((m[0][1], m[1][1], m[2][1]))
        p = r6.point_to_blender(Vector((m[0][3], m[1][3], m[2][3])) + up * along)
        v = world_to_camera_view(scene, scene.camera, p)
        return [round(v.x * size, 1), round((1 - v.y) * size, 1), round(v.z, 2)]
    return {"fist": picture("Right Arm", -1.0), "elbow": picture("Right Arm", 0.5), "head": picture("Head"),
            "torso": picture("Torso"), "size": size}


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    if rest[:1] == ["probe"]:
        probe(OUT)
    elif rest[:1] == ["shots"]:
        shots(OUT, json.loads(Path(rest[1]).read_text()))
    else:
        raise SystemExit("probe | shots <spec.json>")
