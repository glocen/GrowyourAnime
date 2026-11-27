"""AR68, M: the press's own art, Rook's Haymaker, three targets for research's pick (research, 2026-11-27, 13:22: "the
press's own art for M, so the stand-in 'ART' can go"; its study of 01:41, AR62: a disc filled edge to edge with a
rendered picture of the move, dark and metallic, one hot accent; for the Haymaker, Rook's fist and forearm driving at
the camera through its ember burst).

    blender.exe -b --factory-startup --python tools/blender/press_art.py -- <out> [contact] [T1 T2 T3]

Rook as made (build/handoff/Rook/make: his pieces on his maps), posed by turning his pieces about R6's joints, the right
fist's wraps hot as Haymaker heats them (the recipe's glow, through the colour map, as Roblox draws it), lit by the
portraits' sun and fill and by the strike's own ember at the knuckles, and shot with a short lens (T3, the whole of
him in the punch, a longer one; the composition inks him as a silhouette). Each take writes
<out>/<take>.png, square, on transparency, and <out>/<take>_hot.png, the glow alone on black (the composition's bloom;
tools/ui/hud_m_press_art.py lays both in the press). `contact` shoots each take from a few places, small, as
<out>/contact/<take>_<n>.png, to choose the camera before the finish.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bl  # noqa: E402
import hud_art as ha  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402

FOLDER = ha.HANDOFF / "Rook" / "make"
RECIPE = json.loads((FOLDER / "Rook.recipe.json").read_text(encoding="utf-8"))
TINT = RECIPE["emissive"]["tint"]
EMBER = "#FF7A2E"
SHOULDER = {"R": Vector((1.0, 0.0, 3.5)), "L": Vector((-1.0, 0.0, 3.5))}
HIP = Vector((0.0, 0.0, 2.0))
UPPER = ("Rook_Torso", "Rook_RightArm", "Rook_LeftArm", "Rook_Head", "Rook_Hair")
HEAD = ("Rook_Head", "Rook_Hair")
KNUCKLES = Vector((1.5, 0.0, 2.0))       # the recipe's point, in the .blend's frame
FACE = Vector((0.0, 0.62, 4.5))          # the face's middle, on the head's front
SIZE = 768

# A take: the pose (degrees; the arms forward about X, inward about Z; the legs forward about X, right then left; the head's yaw back to the target and its nod,
# chin down; the upper body's twist, right side forward, and its lean), the glow's strength, and the camera: placed
# from the knuckles (`cam`, studs), looking at a point between the knuckles and the face (`look`, the face's share), its
# lens (mm) and its roll (degrees). `tries`: the contact's other places for the camera.
TAKES = {
    # T1, the drive: the hook at full reach on a diagonal across the disc, up to the right, from his right side ahead
    # of him; the fist at the top right where the strike lands.
    "T1": dict(arm_r=(90, 34), arm_l=(-30, -10), head=(-30, 4), twist=40, lean=-6, glow=3.0,
               cam=(1.8, 2.0, 0.0), look=0.2, lens=34, roll=-38, ember=(0.0, 0.5, 0.2), hide=HEAD, dim=0.42,
               tries=[(1.8, 2.0, 0.0), (1.4, 2.4, -0.4), (2.2, 1.4, 0.3), (1.0, 2.6, 0.2)]),
    # T2, the charge: the wrapped fist raised and igniting, from low in front; his shoulder under it, no face.
    "T2": dict(arm_r=(165, 12), arm_l=(-20, -16), head=(-8, -10), twist=14, lean=4, glow=4.0,
               cam=(-1.0, 2.8, -1.6), look=-0.25, lens=30, roll=4, ember=(0.0, 0.3, 0.6), hide=HEAD, dim=0.42,
               tries=[(-1.0, 2.8, -1.6), (-0.4, 3.0, -1.2), (-1.6, 2.4, -2.0), (0.4, 2.6, -1.4)]),
    # T3, the silhouette: the whole of him in the punch, side on, his weight thrown into it (the legs split, the body
    # leaning in, the off hand pulled back); the press draws him as one dark shape against the strike's light.
    "T3": dict(arm_r=(94, 4), arm_l=(-40, -12), head=(-6, 8), twist=34, lean=-14, legs=(-28, 26), glow=4.0,
               cam=(-8.4, 2.4, -1.2), look=0.8, aim=(0.0, 0.0, -1.3), lens=42, roll=6, ember=(0.0, 0.6, 0.0),
               dim=0.42, tries=[(-7.6, 4.7, -1.2), (-6.0, 6.5, -1.2), (-4.0, 7.8, -1.2), (-8.4, 2.4, -1.2)]),
}
LEGS = (("Rook_RightLeg", Vector((0.5, 0.0, 2.0))), ("Rook_LeftLeg", Vector((-0.5, 0.0, 2.0))))


def about(pivot, axis, deg):
    return Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-pivot)


def material(glow, hot_only=False, dim=1.0):
    """His maps as Roblox draws them: the colour, its roughness, and the wraps' glow, (mask x strength x tint) x colour.
    `hot_only`: the glow alone, everything else black."""
    m = bpy.data.materials.new("RookPressHot" if hot_only else "RookPress")
    bsdf, nodes, links = bl._principled(m)

    def tex(kind, data):
        n = nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(str(FOLDER / RECIPE["maps"][kind]), check_existing=True)
        if data:
            n.image.colorspace_settings.name = "Non-Color"
        return n.outputs["Color"]

    colour = tex("Color", False)
    if hot_only:
        bsdf.inputs["Base Color"].default_value = (0, 0, 0, 1)
        bsdf.inputs["Roughness"].default_value = 1.0
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    else:
        dimmed = nodes.new("ShaderNodeMix")
        dimmed.data_type, dimmed.blend_type = "RGBA", "MULTIPLY"
        dimmed.inputs["Factor"].default_value = 1.0
        dimmed.inputs[7].default_value = (dim, dim, dim * 1.06, 1.0)
        links.new(colour, dimmed.inputs[6])
        links.new(dimmed.outputs[2], bsdf.inputs["Base Color"])
        links.new(tex("Roughness", True), bsdf.inputs["Roughness"])
    times = nodes.new("ShaderNodeMix")
    times.data_type, times.blend_type = "RGBA", "MULTIPLY"
    times.inputs["Factor"].default_value = 1.0
    times.inputs[7].default_value = rs.srgb(TINT)
    links.new(colour, times.inputs[6])
    links.new(times.outputs[2], bsdf.inputs["Emission Color"])
    strength = nodes.new("ShaderNodeMath")
    strength.operation = "MULTIPLY"
    strength.inputs[1].default_value = glow
    links.new(tex("Emissive", True), strength.inputs[0])
    links.new(strength.outputs[0], bsdf.inputs["Emission Strength"])
    m.use_backface_culling = True
    return m


def posed(scene, t):
    """His pieces in the take's pose; returns the knuckles and the face where they now are."""
    objs = {}
    mat = material(t["glow"], dim=t.get("dim", 1.0))
    for piece in RECIPE["pieces"]:
        o = ha.delivered_piece(piece["name"], json.loads((FOLDER / piece["mesh"]).read_text(encoding="utf-8")), mat)
        scene.collection.objects.link(o)
        objs[piece["name"]] = o
    bpy.context.view_layer.update()
    moves = {name: Matrix.Identity(4) for name in objs}
    for side, name in (("R", "Rook_RightArm"), ("L", "Rook_LeftArm")):
        fwd, inward = t[f"arm_{side.lower()}"]
        sign = 1 if side == "R" else -1
        moves[name] = about(SHOULDER[side], "Z", sign * inward) @ about(SHOULDER[side], "X", fwd)
    yaw, nod = t["head"]
    for name in HEAD:
        moves[name] = about(ha.NECK, "Z", yaw) @ about(ha.NECK, "X", -nod)
    for (name, hip), deg in zip(LEGS, t.get("legs", (0, 0))):
        moves[name] = about(hip, "X", deg)
    body = about(HIP, "X", t["lean"]) @ about(HIP, "Z", t["twist"])
    for name in UPPER:
        moves[name] = body @ moves[name]
    for name, o in objs.items():
        o.matrix_world = moves[name] @ o.matrix_world
        o.hide_render = name in t.get("hide", ())
    bpy.context.view_layer.update()
    return objs, moves["Rook_RightArm"] @ KNUCKLES, moves["Rook_Head"] @ FACE, moves["Rook_RightArm"]


def lights(scene, knuckles, cam_at, ember_at=None):
    """The ember behind him, its rim toward the camera, the strike's own light at the knuckles, a low cool fill."""
    rm.eevee(scene, SIZE, SIZE)
    d = cam_at - knuckles
    rim = bpy.data.objects.new("Rim", bpy.data.lights.new("Rim", "SUN"))
    rim.data.energy, rim.data.color, rim.data.angle = 7.0, rs.srgb("#FFB070")[:3], math.radians(6)
    scene.collection.objects.link(rim)
    back = (d.normalized() + Vector((0.0, 0.0, -0.35))).normalized()
    rim.rotation_euler = back.to_track_quat("-Z", "Y").to_euler()
    fill = bpy.data.objects.new("Fill", bpy.data.lights.new("Fill", "SUN"))
    fill.data.energy, fill.data.use_shadow, fill.data.color = 0.5, False, rs.srgb("#9DB4D8")[:3]
    scene.collection.objects.link(fill)
    fill.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    ember = bpy.data.objects.new("Ember", bpy.data.lights.new("Ember", "POINT"))
    ember.data.energy, ember.data.color, ember.data.shadow_soft_size = 260.0, rs.srgb(EMBER)[:3], 0.6
    ember.location = knuckles + (Vector(ember_at) if ember_at else d.normalized() * 0.5)
    scene.collection.objects.link(ember)


def camera(scene, at, look, lens, roll):
    cam = scene.camera
    if cam is None:
        cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
        scene.collection.objects.link(cam)
        scene.camera = cam
        cam.data.sensor_width = 36
        cam.data.clip_start = 0.05
    cam.data.lens = lens
    cam.location = at
    q = (look - at).to_track_quat("-Z", "Y") @ Quaternion((0, 0, 1), math.radians(roll))
    cam.rotation_euler = q.to_euler()


def shot(scene, path):
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def take(out, key, contact=False):
    t = TAKES[key]
    scene = bl.reset_scene()
    scene.world = bpy.data.worlds.new("Press")
    objs, knuckles, face, arm = posed(scene, t)
    look = knuckles.lerp(face, t["look"]) + Vector(t.get("aim", (0.0, 0.0, 0.0)))
    at = knuckles + Vector(t["cam"])
    lights(scene, knuckles, at, t.get("ember"))
    if contact:
        folder = out / "contact"
        folder.mkdir(parents=True, exist_ok=True)
        scene.render.resolution_x = scene.render.resolution_y = 320
        for i, c in enumerate(t["tries"]):
            camera(scene, knuckles + Vector(c), look, t["lens"], t["roll"])
            shot(scene, folder / f"{key}_{i}.png")
        return
    camera(scene, at, look, t["lens"], t["roll"])
    shot(scene, out / f"{key}.png")
    # where the strike lands in the picture (from its top left, 0 to 1): the knuckles' face, its corners, the
    # forearm's middle and the face, so the composition lays the flash and the burst on them
    from bpy_extras.object_utils import world_to_camera_view

    def seen(v):
        x, y, _ = world_to_camera_view(scene, scene.camera, v)
        return [round(x, 4), round(1 - y, 4)]

    corners = [seen(arm @ Vector((cx, cy, 2.0))) for cx in (1.0, 2.0) for cy in (-0.5, 0.5)]
    (out / f"{key}.json").write_text(json.dumps(dict(knuckles=seen(knuckles), corners=corners,
                                                     forearm=seen(arm @ Vector((1.5, 0.0, 2.6))), face=seen(face))),
                                     encoding="utf-8")
    # the glow alone: every surface black, the lights and the sky off
    hot = material(t["glow"], hot_only=True)
    for o in objs.values():
        bl.assign_only(o, hot)
    for o in scene.objects:
        if o.type == "LIGHT":
            o.hide_render = True
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0
    scene.render.film_transparent = False
    shot(scene, out / f"{key}_hot.png")
    print(f"{key}: knuckles {tuple(round(v, 2) for v in knuckles)}, face {tuple(round(v, 2) for v in face)}")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    contact = "contact" in rest
    keys = [k for k in rest if k in TAKES] or list(TAKES)
    for k in keys:
        take(OUT, k, contact)
