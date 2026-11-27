"""AR70, option (b): the game page's icon as our own make with an anime finish. Kirra, face first, drawn as a layer
for tools/ui/ar70_painted_targets.py.

    blender.exe -b --factory-startup --python tools/blender/ar70_painted.py -- <out_dir> shots <spec.json>
    blender.exe -b --factory-startup --python tools/blender/ar70_painted.py -- <out_dir> shade <spec.json>

Kirra is the make's (kirra_make.py: take A with the cut's gear, at four times the game's texels so the face holds
when it fills the frame), with a face painted for the icon in place of hers (`glare`): her cut eye narrowed, the brows
driven down, the irises lit. She is posed by hand (the icon isn't a clip), lit in two tones (a toon ramp through each
piece's own picture) and inked (a hull a hair wider than each piece, its faces turned in, drawn only from behind).
`shots` renders each shot its spec lists ({"pose": name, "name", "azimuth", "elevation", "distance", "fov", "size",
"height", "key": [x, y, z], "shade": "#hex"}) as one square RGBA picture, the figure on a clear film, <out_dir>/<name>.png,
with <name>.json: where her eyes, head, hands and hilts fall in it, for the paint. `shade` renders a Shade as the game
draws it (shade_kinds.py: its spec's "type" tint and "mask"), inked the same, in its Idle, for C's foe behind her.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import anime_make as am  # noqa: E402
from anime_make import mix, tone, INK  # noqa: E402
import blcommon as bl  # noqa: E402
import kirra_make as km  # noqa: E402
import kirra_make_takes as kt  # noqa: E402
import r6anim as r6  # noqa: E402
import r6rig  # noqa: E402
import rook_model as rm  # noqa: E402
import rook_sheet as rs  # noqa: E402
import watt_takes as wt  # noqa: E402

NAME = "Kirra"


def linear(c):
    c = rs.rgb(c) if isinstance(c, str) else c
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


# --- the icon's face ---------------------------------------------------------------------------------------------------

def glare(p, skin, iris="#5FE3FF", core="#E9FFFF", lid="#1E2440", brow="#4C5368"):
    """Her cut eye (kirra_make_takes.face_cut) pushed to a glare: the lid lower and flatter across a lit iris, a slit
    pupil and a hard light; the lash's wing longer; the brows set low and driven in toward the nose; a shade under each
    eye; the mouth a small level set, a corner lifted."""
    kt.face_skin(p, skin)
    lit = np.zeros(p.px.shape[:2], np.float32)
    ew, eh, ex, ey, tilt = 0.37, 0.15, 0.275, 0.505, 0.075
    for s in (-1, 1):
        def at(lx, ly):
            return (s * (ex + lx), ey + ly)
        upper = [at(-ew / 2, 0.06 * eh), at(-0.26 * ew, 0.36 * eh), at(0.16 * ew, 0.36 * eh + 0.5 * tilt), at(ew / 2, 0.36 * eh + tilt)]
        lower = [at(ew / 2, 0.36 * eh + tilt), at(0.32 * ew, -0.3 * eh + 0.5 * tilt), at(-0.12 * ew, -0.5 * eh), at(-ew / 2, 0.06 * eh)]
        shape = p.poly(np.vstack([am.smooth2(upper, 18), am.smooth2(lower, 18)[1:-1]]))
        p.lay(shape, "#F2F6F8")
        cx, cy = s * (ex + 0.04 * ew), ey - 0.06 * eh
        rx, ry = 0.29 * ew, 0.78 * eh
        ir = np.minimum(p.ellipse(cx, cy, rx, ry), shape)
        p.lay(ir, iris)
        lit = np.maximum(lit, ir)
        p.lay(np.minimum(p.ellipse(cx, cy - 0.15 * ry, rx * 0.62, ry * 0.55), ir), core, 0.9)           # the lit middle
        p.lay(ir * p.rise(cy + 0.1 * ry, cy + 0.8 * ry), tone(iris, 0.35), 0.9)                         # the lid's shade
        p.lay(np.clip(ir - p.ellipse(cx, cy, rx * 0.84, ry * 0.88), 0, 1), tone(iris, 0.3), 0.95)       # the ring
        p.lay(np.minimum(p.ellipse(cx, cy + 0.02 * ry, rx * 0.12, ry * 0.62), shape), "#0E1830")        # a slit pupil
        p.lay(np.minimum(p.ellipse(cx - s * 0.36 * rx, cy + 0.32 * ry, rx * 0.18, ry * 0.16, turn=45), shape), "#FFFFFF")
        p.lay(shape * p.rise(ey + 0.05 * eh, ey + 0.36 * eh + tilt), lid, 0.45)
        wing = upper + [at(ew / 2 + 0.09, 0.36 * eh + tilt + 0.065)]
        p.lay(p.stroke(wing, (0.012, 0.03, 0.05, 0.046, 0.0), n=48), INK)
        p.lay(p.stroke([at(0.16 * ew, -0.4 * eh + 0.3 * tilt), at(0.4 * ew, -0.16 * eh + 0.6 * tilt), at(ew / 2 + 0.01, 0.32 * eh + tilt)],
                       (0.0, 0.014, 0.018)), INK, 0.9)
        # the brows: low, thick at the inner end and driven down toward the nose
        p.lay(p.stroke([at(-0.52 * ew, 0.072), at(-0.05 * ew, 0.122), at(0.56 * ew, 0.176)], (0.052, 0.038, 0.008)), brow)
        # a shade under each eye: the glare's weight
        p.lay(p.stroke([at(-0.2 * ew, -0.62 * eh), at(0.2 * ew, -0.66 * eh), at(0.42 * ew, -0.5 * eh)], (0.0, 0.01, 0.0)), tone(skin, 0.62), 0.55)
    p.lay(p.ellipse(ex + 0.11, ey - 0.11, 0.011, 0.011), tone(skin, 0.42))                              # her mark
    p.lay(p.soft(p.poly([(0.004, 0.395), (0.03, 0.345), (-0.012, 0.34)]), 0.003), tone(skin, 0.72), 0.9)
    p.lay(p.stroke([(-0.046, 0.228), (-0.016, 0.236), (0.016, 0.236), (0.046, 0.228)], (0.004, 0.013, 0.013, 0.004)), tone(skin, 0.34))
    p.lay(p.stroke([(-0.016, 0.204), (0.018, 0.204)], (0.0, 0.01, 0.0)), tone(skin, 0.55), 0.4)
    LIT["Head"] = lit


LIT = {}   # a material's lit shape (its picture's own colour, never shaded), by its name: the glare's irises


FACES = {"glare": glare, "cut": kt.face_cut}


# --- the figure ----------------------------------------------------------------------------------------------------------

def staged(out, face):
    """Kirra as the make builds her, at four times the texels, each piece on its R6 part; the rig."""
    scene = bl.reset_scene()
    r6.stage(scene, fps=60, size=(960, 540))
    rig = r6.build_rig(NAME, {part: (0.3, 0.3, 0.3) for part in (*r6rig.PARTS, "Face")})
    r6.place_root(rig, 0, (0, r6rig.ROOT_HEIGHT, 0), (0, 0, -1))
    bpy.context.view_layer.update()
    am.PICTURES.clear()
    am.GLOWS.clear()
    am.PPU, am.FACE_PPU = 256, 1024
    (out / "tex").mkdir(parents=True, exist_ok=True)
    made = kt.take_a(wt.rig(scene), out / "tex", pieces=km.made_pieces(), face_draw=FACES[face])
    bpy.context.view_layer.update()
    for key, obj in made.items():
        part = am.PIECE[key][1] if key in am.PIECE else ("Head" if key in ("Tie", "Hair") else "Torso")
        holder = rig.parts[part]
        obj.parent = holder
        obj.matrix_parent_inverse = holder.matrix_world.inverted()
    for o in [rig.parts[part] for part in r6rig.PARTS] + [bpy.data.objects[f"{NAME}.Face"]]:
        o.hide_render = o.hide_viewport = True
    if "Floor" in bpy.data.objects:
        bpy.data.objects["Floor"].hide_render = True
    return scene, rig, made


POSES = {
    # the glare: square to the lens, the head down a little and turned, the right hand up at her right blade's grip
    "glare": {"Torso": (2, 40, 0), "Head": (-10, -34, -8), "Right Arm": (-6, 0, -4), "Left Arm": (6, 0, 6)},
    "glare_l": {"Torso": (2, -40, 0), "Head": (-10, 34, 8), "Right Arm": (6, 0, -6), "Left Arm": (-6, 0, 4)},
    # the reveal: square to the lens, the head down a little, looking up through the brows
    "front": {"Torso": (0, 6, 0), "Head": (-12, -6, 3), "Right Arm": (-4, 0, -3), "Left Arm": (4, 0, 3)},
}


def pose(rig, name):
    r6.key(rig, 0, dict(POSES[name]), plant=False)
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()


# --- the anime finish ---------------------------------------------------------------------------------------------------

THRESHOLD = 0.42


def toon(shade, key):
    """Every piece's material to two tones: its own picture lit, or multiplied by `shade` where the key light doesn't
    reach, the edge between them hard; no specular. The key is a sun from `key` (Blender, toward the light)."""
    for m in list(bpy.data.materials):
        if not m.use_nodes or m.name.startswith("Ink"):
            continue
        nodes, links = m.node_tree.nodes, m.node_tree.links
        tex = next((n for n in nodes if n.type == "TEX_IMAGE"), None)
        out = next((n for n in nodes if n.type == "OUTPUT_MATERIAL"), None)
        if out is None:
            continue
        bsdf = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
        diffuse = nodes.new("ShaderNodeBsdfDiffuse")
        to_rgb = nodes.new("ShaderNodeShaderToRGB")
        links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
        ramp = nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.interpolation = "CONSTANT"
        ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[0].color = 0.0, (*linear(shade), 1)
        ramp.color_ramp.elements[1].position, ramp.color_ramp.elements[1].color = THRESHOLD, (1, 1, 1, 1)
        links.new(to_rgb.outputs["Color"], ramp.inputs["Fac"])
        mul = nodes.new("ShaderNodeMix")
        mul.data_type, mul.blend_type = "RGBA", "MULTIPLY"
        mul.inputs["Factor"].default_value = 1.0
        if tex is not None:
            links.new(tex.outputs["Color"], mul.inputs[6])
        elif bsdf is not None:
            mul.inputs[6].default_value = bsdf.inputs["Base Color"].default_value
        links.new(ramp.outputs["Color"], mul.inputs[7])
        shaded = mul.outputs[2]
        if m.name in LIT and tex is not None:
            path = Path(tex.image.filepath_raw).with_name(f"{m.name}_lit.png")
            rs.save(np.dstack([np.repeat(LIT[m.name][..., None], 3, axis=2), np.ones(LIT[m.name].shape, np.float32)]), path)
            mask = nodes.new("ShaderNodeTexImage")
            mask.image = bpy.data.images.load(str(path))
            mask.image.colorspace_settings.name = "Non-Color"
            mask.interpolation = tex.interpolation
            pick = nodes.new("ShaderNodeMix")
            pick.data_type, pick.blend_type = "RGBA", "MIX"
            links.new(mask.outputs["Color"], pick.inputs["Factor"])
            links.new(shaded, pick.inputs[6])
            links.new(tex.outputs["Color"], pick.inputs[7])
            shaded = pick.outputs[2]
        emit = nodes.new("ShaderNodeEmission")
        links.new(shaded, emit.inputs["Color"])
        links.new(emit.outputs["Emission"], out.inputs["Surface"])


def ink(width):
    """A hull `width` studs outside every shown piece, its faces turned in and drawn only from behind: the ink line."""
    m = bpy.data.materials.new("Ink")
    m.use_nodes = True
    nodes = m.node_tree.nodes
    nodes.clear()
    emit = nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (*linear(INK), 1)
    out = nodes.new("ShaderNodeOutputMaterial")
    m.node_tree.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    m.use_backface_culling = True
    # the hull wraps its piece, so it must never shade it: no shadow from the ink at all
    for flag in ("use_backface_culling_shadow",):
        if hasattr(m, flag):
            setattr(m, flag, True)
    if hasattr(m, "shadow_method"):
        m.shadow_method = "NONE"
    for o in bpy.data.objects:
        if o.type != "MESH" or o.hide_render:
            continue
        slots = len(o.data.materials)
        o.data.materials.append(m)
        s = o.modifiers.new("Ink", "SOLIDIFY")
        s.thickness, s.offset, s.use_flip_normals, s.use_rim = width, 1.0, True, False
        s.material_offset = slots
        s.use_even_offset = True


def lights(scene, key):
    """One sun from `key` (Blender: the way toward the light) for the ramp; the world dark, so the ramp is the sun's."""
    for o in [o for o in bpy.data.objects if o.type == "LIGHT"]:
        bpy.data.objects.remove(o)
    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy, sun.data.angle = 4.0, math.radians(1)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (-Vector(key).normalized()).to_track_quat("-Z", "Y").to_euler()
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.0


# --- the shots -------------------------------------------------------------------------------------------------------------

def landmarks(scene, rig, made, size):
    from bpy_extras.object_utils import world_to_camera_view
    bpy.context.view_layer.update()

    def at(p):
        v = world_to_camera_view(scene, scene.camera, p)
        return [round(v.x * size, 1), round((1 - v.y) * size, 1), round(v.z, 2)]

    def part(name, local):
        m = r6.to_roblox(rig.parts[name].matrix_world)
        return at(r6.point_to_blender(m @ Vector(local)))

    def top_of(obj):
        vs = [obj.matrix_world @ v.co for v in obj.data.vertices]
        return at(max(vs, key=lambda v: v.z))

    head = r6.to_roblox(rig.parts["Head"].matrix_world)
    marks = {"head": part("Head", (0, 0, 0)), "eye_r": part("Head", (0.26, 0.0, -0.6)), "eye_l": part("Head", (-0.26, 0.0, -0.6)),
             "hand_r": part("Right Arm", (0, -1.0, 0)), "hand_l": part("Left Arm", (0, -1.0, 0)),
             "torso": part("Torso", (0, 0, 0)), "size": size}
    for k in ("BladeR", "BladeL"):
        if k in made:
            marks[f"hilt_{k[-1].lower()}"] = top_of(made[k])
    return marks


def shots(out, spec):
    scene, rig, made = staged(out, spec.get("face", "glare"))
    toon(spec.get("shade", "#7C86B8"), spec.get("key", [-0.5, -0.8, 0.6]))
    ink(spec.get("ink", 0.012))
    for s in spec["shots"]:
        pose(rig, s.get("pose", "glare"))
        lights(scene, s.get("key", spec.get("key", [-0.5, -0.8, 0.6])))
        size = s["size"]
        rm.eevee(scene, size, size)
        scene.camera = r6.body_camera(scene, rig, 0, s["azimuth"], s["elevation"], distance=s["distance"], fov=s["fov"],
                                      height=s["height"], name=s["name"])
        scene.render.filepath = str(out / f"{s['name']}.png")
        bpy.ops.render.render(write_still=True)
        (out / f"{s['name']}.json").write_text(json.dumps(landmarks(scene, rig, made, size), indent=1))
        print(f"wrote {out / (s['name'] + '.png')}")


def shade_shots(out, spec):
    """The foe behind her: a Brawler Shade as the game draws it (its own glowing surfaces, its type's tint, its mask),
    in its Idle, inked like her; each shot as `shots` renders hers."""
    import hard_cut as hc
    import shade_kinds as sk
    he, scene, rig, last, _, wear, wear_mask = sk.staged()
    wear("Normal", dict(he.SHADE, body="#" + hc.type_tints()[spec.get("type", "Red")]))
    wear_mask(spec.get("mask", "Brawler"))
    ink(spec.get("ink", 0.014))
    for s in spec["shots"]:
        scene.frame_set(s.get("frame", 11) % last)
        size = s["size"]
        rm.eevee(scene, size, size)
        scene.camera = r6.body_camera(scene, rig, s.get("frame", 11) % last, s["azimuth"], s["elevation"],
                                      distance=s["distance"], fov=s["fov"], height=s["height"], name=s["name"])
        scene.render.filepath = str(out / f"{s['name']}.png")
        bpy.ops.render.render(write_still=True)
        (out / f"{s['name']}.json").write_text(json.dumps({"size": size}))
        print(f"wrote {out / (s['name'] + '.png')}")


if __name__ == "__main__":
    OUT = rs.OUT = bl.out_dir()
    rest = sys.argv[sys.argv.index("--") + 2:]
    if rest[:1] == ["shots"]:
        shots(OUT, json.loads(Path(rest[1]).read_text()))
    elif rest[:1] == ["shade"]:
        shade_shots(OUT, json.loads(Path(rest[1]).read_text()))
    else:
        raise SystemExit("shots <spec.json>")
