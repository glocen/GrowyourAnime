"""AR62, the Arc panel's ground picture: Lantern Row and its keeper, our own render (research's audit of the screens,
class 4: a screen's picture of a place, a foe or a Voidkin is our own render of our own world or model, never a flat
drawn icon standing for it; the drawn lantern is rejected).

The delivered Lamplighter (lamplighter_clips.build: the handed-off meshes and maps on its rig, its glows as the game
sets them, hard_ember's Normal) in its Challenge clip at the stamp, stood in the street before the Keeper's Gate. The
street is the kit dressed from its plan (lantern_row_kit.plan) on the delivered maps, its glows at the day's shares
(Config.Lighting, Lantern Row's Day: Glow 0.6 of the kit's, the floors 0.35). Lit as the street's day (the same:
the sun FFDDA6 high behind the camera, the lilac fill), the Day sky's front face behind, as Roblox draws a Skybox:
the face up the street, laid by each pixel's ray. A low eye a little off his left, looking up at him, so the keeper
holds the picture's middle and the strings and stalls lead to him.

    blender -b --factory-startup --python tools/blender/arc_tile.py -- <abs out> [fast]

Writes <out>/arc_tile.png (SIZE, sRGB) for tools/ui/arc_panel.py to crop per take, and prints where the keeper's hat
and feet fall in it.
"""
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import hard_ember as he  # noqa: E402
import lamplighter_clips as lc  # noqa: E402
import lantern_row_kit as kit  # noqa: E402
import r6anim as r6  # noqa: E402
import rook_sheet as rs  # noqa: E402

look = kit.look
REPO = HERE.parents[1]
MAPS = REPO / "build" / "handoff" / "LanternRow" / "maps"
SKY = REPO / "build" / "handoff" / "LanternRow" / "sky" / "LanternRow_SkyDay_Ft.png"
CHALLENGE = he.KEEPER_CLIPS / "Lamplighter_Challenge.json"

SIZE = (1800, 1350)                     # 4:3; each take crops its own shape from it
FOV = 36.0                              # degrees, vertical
POSE = 58                               # Challenge's stamp: head up, the lantern held out on its pole
KEEPER_Y = kit.STOPS["keeper"] - 12.0   # studs up the street: before the Keeper's Gate, its great lantern behind him
EYE = Vector((-4.0, KEEPER_Y - 42.0, 3.4))   # Blender: x across, y up the street, z up
AIM = Vector((-0.4, KEEPER_Y, 8.2))
SUN, FILL, FILL_STRENGTH = "#FFDDA6", he.FILL, he.FILL_STRENGTH
DAY = dict(glow=0.6, floor=0.35, lights=0.2)   # Config.Lighting, Lantern Row's Day: Glow, Floor, Lights
HAZE = ("#EFE3D6", "#A9BCE4", 0.0022)   # the Atmosphere's Color and Decay, thin; a little paling with distance


class Bag:
    """What Stock needs of the look's Kit: a list it adds each stood piece to."""

    def __init__(self):
        self.pieces, self.lights = [], []


def roblox(v):
    """A Blender point as Roblox's (x, y up, z = -y)."""
    return (v.x, v.z, -v.y)


def keeper(out):
    scene, rig, *_ = lc.build(out)
    for o in [o for o in scene.objects if o.type in ("LIGHT", "CAMERA")]:
        bpy.data.objects.remove(o)
    if "Floor" in bpy.data.objects:
        bpy.data.objects["Floor"].hide_render = True
    last = he.key(rig, CHALLENGE)
    materials = {s.material for o in scene.objects for s in o.material_slots if s.material}
    wear = he.glows([m for m in materials if m.name in ("Lamplighter_Body", "Lamplighter_Mask")], {"Lamplighter_Body"})
    wear("Normal", he.KEEPER)
    toward = roblox(EYE)
    he.stand(rig, 0.0, -KEEPER_Y, (toward[0], toward[2]), he.KEEPER["scale"])
    scene.frame_set(min(POSE, last))
    return scene, rig


def street(scene):
    kit.PHASE["key"] = "D"
    kit.GLOWS["D"], kit.FLOOR_GLOWS["D"] = kit.GLOW * DAY["glow"], DAY["floor"]
    look.FOG.update(colour=look.srgb(HAZE[0]), density=HAZE[2], azimuth=0.0, away=look.srgb(HAZE[1]))
    bag = Bag()
    stock = kit.Stock(MAPS, scene, bag)
    places, lights = kit.plan()
    for i, (name, x, y, turn) in enumerate(places):
        if KEEPER_Y - 150 <= y <= kit.STOPS["keeper"] + 40:
            stock.stand(name, i, (x, y, 0.0), turn)
    # the gate's own real light (the plan's KeeperLamp, under its great lantern), at the day's share of the street's
    # lights: it rims the keeper's hat and shoulders, so his dark coat parts from the gate
    watts, reach = look.DIRECTIONS["M"]["string_light"][1], 40.0
    for name, x, y, z, code, kind in lights:
        if name == "KeeperLamp":
            look.light(bag, scene, name, (x, y, z), code, watts * kit.REAL_LIGHT * DAY["lights"], reach)
    under = bpy.data.materials.new("Under")
    under.use_nodes = True
    under.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = rs.srgb("#6E687C")
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, KEEPER_Y - 40, -0.3))
    plane = bpy.context.active_object
    plane.scale = (400, 400, 1)
    plane.data.materials.append(under)
    for o in bag.pieces:
        if o.name.startswith(("LanternString", "SquareStrings")):
            o.visible_shadow = False   # a string's CastShadow is off in the game
    return bag


def light(scene):
    data = bpy.data.lights.new("Sun", "SUN")
    data.energy, data.color, data.angle = he.SUN_ENERGY, rs.srgb(SUN)[:3], math.radians(3.0)
    sun = bpy.data.objects.new("Sun", data)
    sun.rotation_euler = (-r6.point_to_blender(he.SUN_TOWARD)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(sun)
    bg = scene.world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = rs.srgb(FILL)
    bg.inputs["Strength"].default_value = FILL_STRENGTH
    camera = r6.fixed_camera(scene, roblox(EYE), roblox(AIM), FOV, "Tile")
    camera.data.clip_end = 2000
    scene.camera = camera
    return camera


def render(scene, out: Path, fast):
    kit.eevee(scene, SIZE, 8 if fast else 48)
    scene.render.film_transparent = True
    r = scene.render
    r.image_settings.file_format, r.image_settings.color_depth = "OPEN_EXR", "32"
    exr = out / "arc_tile.exr"
    r.filepath = str(exr)
    bpy.ops.render.render(write_still=True)
    image = bpy.data.images.load(str(exr))
    w, h = SIZE
    px = np.empty(w * h * 4, np.float32)
    image.pixels.foreach_get(px)
    bpy.data.images.remove(image)
    exr.unlink()
    return px.reshape(h, w, 4)[::-1]   # row 0 the top, linear, premultiplied


def sky_behind(camera):
    """The Day sky's front face where each pixel's ray meets it (linear): Ft looks up the street (+Y here), its top +Z,
    its right +X, and it spans 90 degrees."""
    img = bpy.data.images.load(str(SKY))
    fw, fh = img.size
    face = np.array(img.pixels[:], np.float32).reshape(fh, fw, 4)[::-1, :, :3]
    bpy.data.images.remove(img)
    face = np.where(face <= 0.04045, face / 12.92, ((face + 0.055) / 1.055) ** 2.4)
    w, h = SIZE
    t = math.tan(math.radians(FOV) / 2)
    xs = (2 * (np.arange(w) + 0.5) / w - 1) * t * w / h
    ys = (1 - 2 * (np.arange(h) + 0.5) / h) * t
    X, Y = np.meshgrid(xs, ys)
    R = np.array(camera.matrix_world.to_3x3())
    d = np.stack([X, Y, -np.ones_like(X)], -1) @ R.T
    fwd = np.maximum(d[..., 1], 1e-3)
    u = np.clip(0.5 + 0.5 * d[..., 0] / fwd, 0, 1) * (fw - 1)
    v = np.clip(0.5 - 0.5 * d[..., 2] / fwd, 0, 1) * (fh - 1)
    u0, v0 = np.floor(u).astype(int), np.floor(v).astype(int)
    u1, v1 = np.minimum(u0 + 1, fw - 1), np.minimum(v0 + 1, fh - 1)
    a, b = (u - u0)[..., None], (v - v0)[..., None]
    return (face[v0, u0] * (1 - a) * (1 - b) + face[v0, u1] * a * (1 - b) + face[v1, u0] * (1 - a) * b
            + face[v1, u1] * a * b)


def to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def where(scene, camera, p):
    v = world_to_camera_view(scene, camera, p)
    return round(v.x * SIZE[0]), round((1 - v.y) * SIZE[1])


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    out = Path(args[0])
    out.mkdir(parents=True, exist_ok=True)
    fast = "fast" in args[1:]
    scene, rig = keeper(out)
    street(scene)
    camera = light(scene)
    fg = render(scene, out, fast)
    sky = sky_behind(camera)
    rgb = fg[..., :3] + (1 - fg[..., 3:4]) * sky
    pixels = np.concatenate([to_srgb(rgb), np.ones_like(fg[..., :1])], -1).astype(np.float32)
    rs.save(pixels, out / "arc_tile.png")
    pts = [o.matrix_world @ Vector(c) for o in scene.objects if o.name.startswith("Lamplighter_") and o.type == "MESH"
           for c in o.bound_box]
    top = max(pts, key=lambda p: p.z)
    print(f"arc tile: hat's top at {where(scene, camera, top)}, feet at "
          f"{where(scene, camera, Vector((0.0, KEEPER_Y, 0.0)))}, of {SIZE}")


if __name__ == "__main__":
    main()
